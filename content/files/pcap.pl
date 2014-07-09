#!/usr/bin/perl -w

use strict;
use Net::Pcap;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;
use sigtrap 'handler' => \&cleanAndExit, 'INT', 'ABRT', 'QUIT', 'TERM';

our %table;
our $pcapobject;
our $address;
our $netmask;

sub cleanAndExit {
	our $pcapobject;
	Net::Pcap::close($pcapobject);
	save_table();
	exit(1);
}

sub process_packet {
        our %table;
	my ($remote_ip, $local_port, $remote_port, $num_packets, $num_bytes) = @_;
	my @value = ($num_packets, $num_bytes);
	if (exists $table{ $remote_ip }{ $local_port }{ $remote_port }) {
		my @old_value = $table{ $remote_ip }{ $local_port }{ $remote_port};
		$old_value[0][1] += $num_bytes;
		$old_value[0][0] += $num_packets;
	} else {
		$table{ $remote_ip }{ $local_port }{ $remote_port} = \@value;
	}
}

sub print_table {
	our %table;
	my $packets = \%table;
	for my $remote_ip (keys %$packets) {
		print "IP Address: " . $remote_ip . "\n";
		for my $local_port (keys %{$packets->{ $remote_ip }}) {
			print "  Local Port: " . $local_port . "\n";
			for my $remote_port (keys %{$packets->{ $remote_ip }->{ $local_port }}) {
				my @value =  $packets->{ $remote_ip }->{ $local_port }->{ $remote_port };
				print "    Remote Port: " . $remote_port . "\n";
				print "       Num Packets: " . $value[0][1] . "\n";
				print "       Num Bytes: " . $value[0][0] . "\n";
			}
		}
		print "\n";
	}
}

sub save_table {
	open (OUTFILE, ">>pcap_7260_" . time() . ".csv") or die "Can't open OutFile";
	our %table;
	my $packets = \%table;
	for my $remote_ip (keys %$packets) {
		for my $local_port (keys %{$packets->{ $remote_ip }}) {
			for my $remote_port (keys %{$packets->{ $remote_ip }->{ $local_port }}) {
				my @value =  $packets->{ $remote_ip }->{ $local_port }->{ $remote_port };
				print OUTFILE $remote_ip . ",";
				print OUTFILE $local_port . ",";
				print OUTFILE $remote_port . ",";
				print OUTFILE $value[0][1] . ",";
				print OUTFILE $value[0][0] . "\n";
			}
		}
	}
	close OUTFILE;
}

sub got_packet {
	my ($user_data, $header, $packet) = @_;
	my $ether_data = NetPacket::Ethernet::strip($packet);
	my $ip = NetPacket::IP->decode($ether_data);
	if ($ip->{'proto'} == 6) {
		my $tcp = NetPacket::TCP->decode($ip->{'data'});

		my ($target_ip,$target_port,$host_port);;

		if(mask($ip->{'src_ip'},num2ip($netmask)) eq num2ip($address)) {
			#this is from me (mostly)
			print("FROM ME:");
			$target_ip = $ip->{'dest_ip'};
			$target_port = $tcp->{'dest_port'};
			$host_port = $tcp->{'src_port'};
		} elsif (mask($ip->{'dest_ip'},num2ip($netmask)) eq num2ip($address)) {
			#this if for me (mostly)
			print("FOR ME:");
			$target_ip = $ip->{'src_ip'};
			$target_port = $tcp->{'src_port'};
			$host_port = $tcp->{'dest_port'};
		} else {
			return;
		}

		process_packet( $target_ip, $target_port, $host_port, 1, $ip->{'len'});

		print $ip->{'src_ip'}, ":", $tcp->{'src_port'}, 
			" ->(1packet,".$ip->{'len'}."bytes)-> ",
			$ip->{'dest_ip'}, ":", $tcp->{'dest_port'}, "\n";
	}
}

sub ip2num { 
	return(unpack("N",pack("C4",split(/\./,$_[0]))));
}

sub num2ip {
	return(join(".",unpack("C4",pack("N",$_[0]))));
}

sub mask {
	my ($ipaddr, $mask) = @_;
	return num2ip(ip2num($ipaddr) & ip2num($mask));
}

sub init {
	my $err;

	my $dev = $ARGV[0];
	unless (defined $dev) {
		$dev = Net::Pcap::lookupdev(\$err);
		if (defined $err) {
			die 'Unable to determine network device for monitoring - ', $err;
		}
	}

	our ($address, $netmask);
	if (Net::Pcap::lookupnet($dev, \$address, \$netmask, \$err)) {
		die 'Unable to look up device information for ', $dev, ' - ', $err;
	}

	our $pcapobject = Net::Pcap::open_live($dev, 1500, 0, 0, \$err);
	unless (defined $pcapobject) {
		die 'Unable to create packet capture on device ', $dev, ' - ', $err;
	}


	#this is how we can use filters to match on incoming/outgoing/etc. 
	#my $filter;
	#Net::Pcap::compile($object, \$filter,  '(dst 127.0.0.1) && (tcp[13] & 2 != 0)', 0, $netmask) && 
	#	die 'Unable to compile packet capture filter';
	#Net::Pcap::setfilter($object, $filter) &&
	#	die 'Unable to set packet capture filter';

	Net::Pcap::loop($pcapobject, -1, \&got_packet, '') ||
		die 'Unable to perform packet capture';

	Net::Pcap::close($pcapobject);
	save_table();
}

init();
