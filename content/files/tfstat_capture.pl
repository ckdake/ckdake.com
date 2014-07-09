#!/usr/bin/perl -w 

#we should use native pcap filters instead of the hash matching here, but eh...

use strict;
use Net::Pcap;
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::TCP;
use NetPacket::UDP;
use sigtrap 'handler' => \&cleanAndExit, 'INT', 'ABRT', 'QUIT', 'TERM';
use Socket;
use threads;
use threads::shared;
use Sys::Hostname;
use XML::Simple;
use Digest::MD5 qw(md5);
use LWP::Simple qw(get);

our $collector;
our %table :shared;
our %config :shared;
our %rules;
our $pcapobject;

my $FLOWEXPIRETIME = 20 * 60; 
my $GARBAGERUNTIME = 30;
my $MAXTHREADS = 20;

my $ISDONE :shared;
$ISDONE = 0;

sub cleanAndExit {
	our $pcapobject;
	Net::Pcap::close($pcapobject);
	$ISDONE = 1;
	lock(%table);
	for my $key ( keys %table ) {
		my @entry = $table{$key};
		waitThreads();
		threads->create("dispatch_report", ($entry[0][0],$entry[0][1],$entry[0][2],$entry[0][3],$entry[0][4],$entry[0][5],$entry[0][6],$entry[0][7],$entry[0][8]));
		delete $table{$key};
	}


	my @threads = threads->list();
	while(@threads gt 1) {
		sleep(1);
		@threads = threads->list();
	}

	exit(1);
}

sub waitThreads {
	my @threads = threads->list();
	while(@threads >= $MAXTHREADS) {
		print("DEBUG: too many threads running (".@threads."). Waiting on a free slot.\n");
		sleep(1);
		@threads = threads->list();
	}
}

sub garbageCollection {
	threads->self->detach();
	while(!$ISDONE) {
		sleep($GARBAGERUNTIME);
		print("GARBAGE: running garbage collection on " . keys(%table) . " records at ".time()."\n");
		lock(%table);
		my %table2 :shared;
		for my $key ( keys %table ) {
			my @entry = $table{$key};
			if ($entry[0][8] < (time() - $FLOWEXPIRETIME)) {
				print("DEBUG: garbage collection noticed that a flow has expired!\n");
				waitThreads();
				threads->create("dispatch_report", ($entry[0][0],$entry[0][1],$entry[0][2],$entry[0][3],$entry[0][4],$entry[0][5],$entry[0][6],$entry[0][7],$entry[0][8]));
				delete $table{$key};
			} else {
				# we're doing this to save memory. Perl won't free up the space used by the addressed hash table
				# (even though it frees the actual data arrays stored in it) so we create a new hash table each 
				# time garbage collection is run.
				my @tentry :shared;
				@tentry = ($entry[0][0],$entry[0][1],$entry[0][2],$entry[0][3],$entry[0][4],$entry[0][5],$entry[0][6],$entry[0][7],$entry[0][8]);
				$table2{$key} = \@tentry;
			}
		}
		%table = %table2;
	}
}

sub dispatch_report {
	my ($src_ip, $dst_ip, $src_port, $dst_port, $ip_proto, $num_packets, $num_bytes, $starttime, $endtime) = @_;
	
	our %config;

	my $data = "$src_ip-$dst_ip-$src_port-$dst_port-$ip_proto-$num_packets-$num_bytes-$starttime-$endtime";
	print("REPORTING: flow:$data\n");
	get("http://$config{'collectionurl'}?i=$config{'identifier'}\&p=$config{'collectionpassword'}\&d=$data\n");
	threads->self->detach();
}

sub process_packet {
	our %table;
	my $now = time();
	my ($src_ip, $dst_ip, $src_port, $dst_port, $ip_proto, $num_bytes) = @_;
	my $hash = packet_hash($src_ip, $dst_ip, $src_port, $dst_port, $ip_proto);
	if (exists $table{$hash}) {
		lock(%table);
		if (exists($table{$hash})) {
			# @entry is  srcip,destip,srcport,destport,ipproto,numpackets,numbytes,starttime,endtime
			my @entry = $table{$hash};
			my $endtime = $now;
			if ($entry[0][8] < ($now - $FLOWEXPIRETIME)) {
				print("DEBUG: an incoming packet was for a flow that has already expired. flushing flow\n");
				waitThreads();
				threads->create("dispatch_report", ($entry[0][0],$entry[0][1],$entry[0][2],$entry[0][3],$entry[0][4],$entry[0][5],$entry[0][6],$entry[0][7],$entry[0][8]));
				$entry[0][5] = 1;
				$entry[0][6] = $num_bytes;
				$entry[0][7] = $now;
				$entry[0][8] = $now;
			} else {
				$entry[0][5] += 1;
				$entry[0][6] += $num_bytes;
				$entry[0][8] = $endtime;
			}
		} else {
			my @tentry :shared;
			@tentry = ($src_ip, $dst_ip, $src_port, $dst_port, $ip_proto, 1, $num_bytes, $now, $now);
			$table{$hash} = \@tentry;
		}
	} else {
		my @tentry :shared;
		@tentry = ($src_ip, $dst_ip, $src_port, $dst_port, $ip_proto, 1, $num_bytes, $now, $now);
		$table{$hash} = \@tentry;
	}
}

sub got_packet {
	my ($user_data, $header, $packet) = @_;
	our %rules;
	my $ether_data = NetPacket::Ethernet::strip($packet);
	my $ip = NetPacket::IP->decode($ether_data);
	my $srcport = 0;
	my $destport = 0;
	if ($ip->{'proto'} == 6) {
		my $tcp = NetPacket::TCP->decode($ip->{'data'});
		$srcport = $tcp->{'src_port'};
		$destport = $tcp->{'dest_port'};
	} elsif ($ip->{'proto'} == 17) {
		my $udp = NetPacket::UDP->decode($ip->{'data'});
		$srcport = $udp->{'src_port'};
		$destport = $udp->{'dest_port'};
	}

	my($remoteip,$remoteport,$hash);

	print("PACKET:");
	if (mask($ip->{'src_ip'},num2ip($config{'netmask'})) eq num2ip($config{'address'})) {
		print("incoming:");
		$remoteip=$ip->{'dest_ip'};
		$remoteport=$destport;
		$hash = rule_hash($ip->{'dest_ip'},$destport,$ip->{'proto'});
	} elsif (mask($ip->{'dest_ip'},num2ip($config{'netmask'})) eq num2ip($config{'address'})) {
		print("outgoing:");
		$remoteip=$ip->{'src_ip'};
		$remoteport=$srcport;
		$hash = rule_hash($ip->{'src_ip'},$srcport,$ip->{'proto'});
	} else {
		# what are these packets we are sending/receiving that aren't from or for us?
		$hash = rule_hash($ip->{'dest_ip'},$destport,$ip->{'proto'});
	}

	if (!exists($rules{$hash})) {
		process_packet( $ip->{'src_ip'}, $ip->{'dest_ip'}, $srcport, $destport, $ip->{'proto'}, $ip->{'len'});
		print("processing:");
	} else {
		print("ignoring:");
	}
	print $ip->{'src_ip'}, ":", $srcport," ->(".$ip->{'len'}."bytes,ipproto:".$ip->{'proto'}.")-> ",$ip->{'dest_ip'}, ":", $destport, "\n";
}

sub packet_hash {
	my ($src_ip, $dst_ip, $src_port, $dst_port, $ipproto) = @_;
	return(md5($src_ip.$dst_ip.$src_port.$dst_port.$ipproto));
}

sub rule_hash {
	my ($rip,$rport,$proto) = @_;
	return md5($rip.$rport.$proto);
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


sub read_config {
	my $xml = new XML::Simple (KeyAttr=>[]);
	my $confdata = $xml->XMLin("./tfstat_capture.cfg");
	our $config;

	if (!$confdata) {
		die("Error reading config file");
	}

	foreach my $entry (@{$confdata->{'option'}}) {
		if (!($entry->{'name'} eq "rule")) {
			$config{"$entry->{'name'}"} = $entry->{'value'};
		} else {
			my $hash = rule_hash($entry->{'remote_ip'},$entry->{'remote_port'},$entry->{'ipproto'});
			print("CONFIG: Not logging traffic to $entry->{'remote_ip'}:$entry->{'remote_port'} on IP protocol $entry->{'ipproto'}\n");
			$rules{$hash} = 1;
		}
	}
}

sub init {
	my $err;
	our $config;
	our $collector;

	read_config();

	unless (defined $config{"netdevice"}) {
		$config{"netdevice"} = Net::Pcap::lookupdev(\$err);
		if (defined $err) {
			die 'Unable to determine network device for monitoring - ', $err;
		}
	}

	my ($address, $netmask);
	if (Net::Pcap::lookupnet($config{"netdevice"}, \$address, \$netmask, \$err)) {
		die 'Unable to look up device information for ', $config{"netdevice"}, ' - ', $err;
	}
	$config{"address"} = $address;
	$config{"netmask"} = $netmask;

	our $pcapobject = Net::Pcap::open_live($config{"netdevice"}, 1500, 0, 0, \$err);
	unless (defined $pcapobject) {
		die 'Unable to create packet capture on device ', $config{"netdevice"}, ' - ', $err;
	}

	print("Starting Flow Collection...\n");
	$collector = threads->create("garbageCollection");
	Net::Pcap::loop($pcapobject, -1, \&got_packet, '') ||
		die 'Unable to perform packet capture';

	# we should never reach this, but just in case.
	cleanAndExit();
}

init();
