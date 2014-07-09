#!/usr/bin/perl -w
# generate_config.pl
#
# 2004.10.07 Chris Kelly, The Fulcrum Group
# 	ckelly AT afulcrum DOT com
#

############################################################################
# BUGS/ISSUES TO FIX
# -dns connectivity check only checks for an open socket, should use dns 
#	zone transfter question and response to TCP 53
############################################################################

############################################################################
# This is a tool for managing bind configurations, informing bind of 
# what services are up and running and not presenting records for 
# services that are down. It works by testing the services, regenerating 
# the bind config file for a given zone, and sending bind a HUP (causing 
# it to reload configuration files);
#
# Usage:
# run "./generate_config.pl example.com" from the command line
#
# this assumes that you have the following files:
#
# configuration file. holds all the values to use at the top of the zone 
# file. The SOA should be the hostname of this machine.  example.com.conf:
#    	#config paramaters for example.com
#	SOA = ns1.example.com
#	CONTACT = root@example.com
#	TTL = 0
#	REFRESH = 28800
#	RETRY = 14400
#	EXPIRE = 3600000
#
# hosts file. holds the ip address, name, and all the servers that are running.
#   only one of the servers should be the default, which *.example.com and
#   example.com will point to. Servers should be in decending order of priority.
# example.com.hosts:
#	#ipaddress      name            dns     mail    mailpri www     default
#	#----------------------------------------------------------------------
#	10.0.1.5	server1          y       y       10      y       y
#	192.168.2.7	server2          y       n       0	y       n
#
# Once this script is run twice, the following files will be generated:
# example.com.zone -  the zone file that bind should be able to use
# example.com.zone.previous - the previous zone file, so that if something bad 
#	happens there is a config to revert to
#
# The Following DNS records will be created. A records for each server with CNAME
# records for all of the services it provides, mail#.DOMAINNAME, etc to it. An
# A record will be created for www which points to every IP address that provides
# the www service. NS and MX records will be created as appropriate, and regardless
# of the status of the services, the SOA from the config file will always have 
# an NS entry that points to ns1.DOMAINNAME
#
############################################################################

############################################################################
# Configuration Options
#
# true if you want output, false for "silent" operation

my $VERBOSE = 1;

# how many seconds to try and connect to services

my $TIMEOUT = 3;

# where all files are stored

my $ZONEDIR = "/var/named/";
my $CONFDIR = "/var/named";
my $BACKUPDIR = "/var/named";
my $PIDFILE = "/var/run/named/named.pid";
my $SENDMAIL = "/usr/sbin/sendmail -t";

my $ADMINEMAIL = "root\@localhost";

# how to report problems
my $LOGERRORS = 1;
my $LOGUPDATES = 1;
my $EMAILERRORS = 1;
my $EMAILUPDATES = 1;

############################################################################

use strict;
use IO::Socket;
use Sys::Syslog;

# read in the configuration information
my $domain = shift or die("FAILURE: Requires input of a domainname to run \n");

# read in the hosts file
open(HOSTS,"$CONFDIR/$domain.hosts") or die("FAILURE: Can't open hosts file $CONFDIR/$domain.hosts for reading \n");
my @data = <HOSTS>;
close(HOSTS);

my %CONFIG;

# read in the configuration information
open(CONF,"$CONFDIR/$domain.conf") or die("FAILURE: Can't open config file $CONFDIR/$domain.conf for reading \n");
while (<CONF>) {
    chomp;                  # no newline
    s/#.*//;                # no comments
    s/^\s+//;               # no leading white
    s/\s+$//;               # no trailing white
    next unless length;     # anything left?
    my ($var, $value) = split(/\s*=\s*/, $_, 2);
    $CONFIG{$var} = $value;
} 
close(CONF);

my $dnscount = 1; 	#counter for dns servers
my $mailcount = 1; 	#counter for the mail servers
my $webcount = 1;	#counter for the web servers
my $hasdefault = 0;

my (@nameservers,@cnamerecords,@arecords,@mailservers,@wwwips);

if ($VERBOSE) {
	print "STATUS: reading configuration files and testing services for $domain.\n";
}

push(@nameservers,"NS          $CONFIG{SOA}.");

foreach my $inputline (@data) {
	if ((!($inputline =~ /(#)/)) && 
			($inputline =~ /((?:\d{1,3}\.){3}\d{1,3})[\s]+([\w]+)[\s]+([y|n])[\s]+([y|n])[\s]+([0-9]{1,2})[\s]+([y|n])[\s]+([y|n])/)) {
		#we always leave the primary A record in, even if the server is down
		push(@arecords,"$2			IN	A	$1");

		my $cname = $2;
		my $ipaddress = $1;

		if ($VERBOSE) {
			print "STATUS: Checking connectivity of $cname.$domain ($1)\n";
		}

		#if this server is running a name server
		if ($3 eq "y") {
			my $servername = "ns$dnscount";		
			
			my $sock = new IO::Socket::INET(PeerAddr => "$1",
							PeerPort => "53",
							Proto => "tcp",
							Timeout => $TIMEOUT);
		        if ($sock) {
                                $sock->connect("DNS");
                                #$sock->send(length($header.$question).$header.$question);
				
                                if (1) {
                                        if ($VERBOSE) {
                                                print "	DNS SUCCESS: $servername.$domain is accepting connections\n";
                                        }

					#dont add the SOA twice, we added it earlier
					if (!($servername.$domain eq $CONFIG{SOA})) {
		                                push(@nameservers,"NS   	$servername.$domain.");
					}
        		                push(@cnamerecords,"$servername			IN      CNAME   $cname");
					$dnscount++;
                                } elsif ($VERBOSE) {
                                        print "	DNS FAILURE: invalid status recieved from $servername.$domain\n";
                                }
				$sock->close();
                        } elsif ($VERBOSE) {
                                print "	DNS FAILURE: connection to $servername.$domain failed\n";
                        }			
		}

		#if this server is running a mail server
		if ($4 eq "y") {
			my $servername = "mail$mailcount";
			my $mxpri = $5;

			#verify that is is accepting smtp connections by checking
			#for a 220 message when we connect
			my $sock = IO::Socket::INET->new(PeerAddr => "$1",
							PeerPort => 'smtp(25)',
							Proto => 'tcp',
							Timeout => $TIMEOUT);
			if ($sock) {		
				$sock->connect("SMTP");
				my $inBuf = '';
				$inBuf = <$sock>;
				$sock->close();
				if ($inBuf =~ /220/) {
					if ($VERBOSE) {
						print "	SMTP SUCCESS: message from $servername.$domain: $inBuf";
					}
					$mailcount++;
					push(@mailservers,"MX	$mxpri $servername.$domain.");
					push(@cnamerecords,"$servername			IN	CNAME	$cname");
				} elsif ($VERBOSE) {
					print " SMTP FAILURE: invalid status recieved from $servername.$domain\n";
				}
			} elsif ($VERBOSE) {
				print "	SMTP FAILURE: connection to $servername.$domain failed\n";
			}
		}
		
		#if this server is running a web server
		if ($6 eq "y") {
			my $servername = "www$webcount";

			#verify that is is returning web pages
			#check for the serverup.html page containing "server is up"
                        my $sock = IO::Socket::INET->new(PeerAddr => "$1",
                                                        PeerPort => '80',
                                                        Proto => 'tcp',
                                                        Timeout => $TIMEOUT);
                        if ($sock) {
				$sock->autoflush(1);
                                $sock->connect("HTTP");
                                my $inBuf = '';
				my $success = 0;
				$sock->send("GET /serverup.html HTTP/1.0\n\n");
				while ($inBuf = <$sock>) {
	                                if ($inBuf =~ /server is up/) {
        	                                if ($VERBOSE) {
                	                                print "	HTTP SUCCESS: $servername.$domain said: $inBuf";
                        	                }
						$success = 1;
						$webcount++;
						push(@wwwips,"$ipaddress");
                                	        push(@cnamerecords,"$servername			IN      CNAME   $cname");
					}
				} 
				$sock->close();
		                if (!$success && $VERBOSE) {
                                        print "	HTTP FAILURE: invalid status recieved from $servername.$domain\n";
                                }
                        } elsif ($VERBOSE) {
                                print "	HTTP FAILURE: connection to $servername.$domain failed\n";
                        }
		}		

		#if this should be the default server and we dont have a default yet
		if (!$hasdefault && ($7 eq "y")) {
			$hasdefault = 1;
			push(@cnamerecords,"*			IN	CNAME	$cname");
		} elsif ($7 eq "y") {
			die("FAILURE: error! cannot have more than one default server");
		}
	} elsif (!($inputline =~ /^[#.*|\s+&]/)) {
		print "STATUS: Ignoring invalid input line in config: $inputline";
	}
}

#check changes against the previous zone file, if same we are done
my $change = 0; #if there is a change in status since the previous run, this will be 1

if (open(PFILE,"$ZONEDIR/$domain.zone")) {
	my $line = <PFILE>;
	while (!($line eq "") && !($line =~ /CNAME/)) {
		$line = <PFILE>;
	}
	foreach my $record (@cnamerecords) {
		if (!($line eq "")) {
			$line =~ s/\n//;
			if (!($line eq $record)) {
				$change = 1;
				last;
			}
		}
		$line = <PFILE>;
	}
	
	#if there are more CNAME records when we are done something must not be right
	if (($line) && ($line =~ /CNAME/)) {
		print "STATUS: More CNAME records in old zone file than current one \n";
		$change = 1;
	}
	close(PFILE);	
} else {
	if ($VERBOSE) {
		print "STATUS: I was unable to open the previous status file, assuming this is the first run.\n";
	}
	$change = 1
}


#if there is a change:
if ($change) {
	if ($VERBOSE) {
		print "STATUS: Server status has changed since last check! Generating new zone file and restarting bind!\n";
	}
	
	#get the serial number of the old config file and increment
	my ($day, $month, $year) = ( localtime(time) )[3..5];
	if ($year < 1000) {
		$year += 1900;
	}
	$month++;
	$year = $year % 100;
	my $date = sprintf "%02d%02d%02d", $year, $month, $day;

	my $serial = $date."00";

	if (open(CFILE,"$ZONEDIR/$domain.zone")) {
		while (my $line = <CFILE>) {
			if ($line =~ /([\s]+)([0-9]+)([\s|;]+)(serial)/i) { 
				my $old_serial = $2;
							                                
				if ($old_serial =~ /$date/) {
					#if correct date/time, increment by 1
					$serial = $old_serial + 1;
				}
			}
		}
		close(CFILE);
	}

	$CONFIG{SERIAL} = $serial;

	#generate a new config file (with the new serial number) (keeping the old one as domain.zone.previous
	rename("$domain.zone","$domain.zone.previous");
	open(OUTF,">$ZONEDIR/$domain.zone") or die("FAILURE: Couldn't open config file for writing");
	flock(OUTF,2);

	if ($CONFIG{SERIAL} eq "") {
		$CONFIG{SERIAL} = 0;
	}

	#fill out the config options from the configuration file.
	print OUTF "\$TTL ",$CONFIG{"TTL"}," \n";
	print OUTF "@	IN	SOA	$CONFIG{SOA}	$CONFIG{CONTACT} (\n";
	print OUTF "				$CONFIG{SERIAL} ; serial \n";
	print OUTF "				$CONFIG{REFRESH} ; refresh \n";
	print OUTF "				$CONFIG{RETRY} ; retry \n";
	print OUTF "				$CONFIG{EXPIRE} ; expire \n";
	print OUTF "				$CONFIG{TTL} ; ttl \n";
	print OUTF "				) \n\n";

	#write the nameservers and mail servers
	foreach my $nameserver (@nameservers) {
		print OUTF "			$nameserver\n";
	}
	print OUTF "\n";
	foreach my $mailserver (@mailservers) {
		print OUTF "			$mailserver\n";
	}
	print OUTF "\n\$ORIGIN $domain.\n\n";

	#write out the default www server for load balancing

	foreach my $wwwip (@wwwips) {
		print OUTF "www			IN	A	$wwwip\n";
	}

	#write all of the A and CNAME records
	foreach my $record (@arecords) {
		print OUTF "$record\n";
	}
	foreach my $record (@cnamerecords) {
		print OUTF "$record\n";
	}
	close(OUTF);

#send bind a HUP

	open(PID,"$PIDFILE") or die("FAILURE: Can't open $PIDFILE for reading \n");
	my $pid = <PID>;
	$pid =~ s/[\n^\r]//g;
	close(PID);
	if ($VERBOSE) {
		print "STATUS: restarting BIND ($pid) \n";
	}
	my $retcode = system("kill -HUP $pid");
	if ($retcode != 0) {
		if ($VERBOSE) {
			print "STATUS: bind did not restart properly!\n";
		}
		if ($LOGERRORS) {
			syslog('daemon.alert',"bind did not restart properly (code $retcode) after config file regen for domain: $domain");
		}
		if ($EMAILERRORS) {
			open MAIL,"|$SENDMAIL";
print MAIL <<THE_EMAIL;
From: bind\@$domain
To: $ADMINEMAIL
Subject: BIND failure Alert

Bind did not restart properly (code $retcode) after config file regen for domain: $domain.
!
THE_EMAIL
			close MAIL;
		}
	} else {
		if ($VERBOSE) {
			print "STATUS: bind successfully restarted.\n";
		}
		if ($LOGUPDATES) {
			syslog('info',"bind was restarted to update zone information for domain: $domain");
		}
		if ($EMAILUPDATES) {
                        open MAIL,"|$SENDMAIL";
print MAIL <<THE_EMAIL;
From: bind\@$domain
To: $ADMINEMAIL
Subject: BIND restart

Bind was restarted to update zone information for domain: $domain.

THE_EMAIL
                        close MAIL;
		}
	}
} else { #end if ($change);
	if ($VERBOSE) {
		print "STATUS: no change in available services since last run.\n";
	}
}



