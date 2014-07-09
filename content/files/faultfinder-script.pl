#!/usr/bin/perl -w 

use strict;
use DBD::mysql;
use Graph::Directed;
use GraphViz;
use Getopt::Std;

our $network;
our $metric;
our $timestamp;
our $threshold;

our @endpoints = ();
our $db_handle;
our $graph;
our @componenterrorcount = ();
our @componentsuccesscount = ();
our $maxcomponenterror = 0;
our $maxcomponentsuccess = 0;
our @nodefailurecount = ();
our @nodesuccesscount = ();
our $maxnodeerror = 0;
our $maxnodesuccess = 0;


sub loadGraph {
	our $graph;
	my $statement =  $db_handle->prepare("SELECT id,end1,end2 FROM Link")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my ($id,$end1,$end2);
	$statement->bind_columns( \$id, \$end1, \$end2);
	while ($statement->fetch()) {
		$graph->add_edge($end1,$end2);
		$graph->add_edge($end2,$end1);
	}
	
}

sub drawGraph {
	our $graph;
	my $g = GraphViz->new(directed => 1, layout => 'neato', overlap => 'false');
	foreach ($graph->vertices()) {
		$g->add_node($_, label => getNodeLabel($_), shape => getNodeShape($_), 
				style => 'filled', fillcolor => getColorFromFailRate(getNodeFailRate($_)));
	}
	my @edges = $graph->edges();
	foreach (@edges) {
		my @es = $_;
		$g->add_edge($es[0][0] => $es[0][1], 
			color => getColorFromFailRate(getSegmentFailRate($es[0][0],$es[0][1])));
	}

	open(FILEOUT, "> ./".$network."_".$timestamp."_".$threshold.".png");
	binmode(FILEOUT);
	print FILEOUT $g->as_png;
	close(FILEOUT);
}

sub getEndpoints {
	our @endpoints;
	my $statement =  $db_handle->prepare("SELECT id FROM Host WHERE inNetwork=1")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my $endpoint;
	$statement->bind_columns( \$endpoint );
	while($statement->fetch()) {
		push(@endpoints, $endpoint);
	}
}

sub getNodeLabel {
	my $node = shift;
	my $statement =  $db_handle->prepare("SELECT description FROM Host WHERE id=$node")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my $description;
	$statement->bind_columns( \$description );
	$statement->fetch();
	if (!defined($description)){
		$description = $node;
	}
	return $description;
}

sub getNodeShape {
        my $node = shift;
	my $statement =  $db_handle->prepare("SELECT inNetwork FROM Host WHERE id=$node")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my $is;
	$statement->bind_columns( \$is );
	$statement->fetch();
	if ($is){
		return 'ellipse';
	} else {
		return 'box';
	}
}


sub storePathComponent {
	our $db_handle;
	my $end1 = shift;
	my $end2 = shift;
	my $linkid = shift;
	
	my $statement =  $db_handle->prepare("SELECT COUNT(*) FROM pathcomponent WHERE end1=$end1 AND end2=$end2 AND link=$linkid")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my $count;
	$statement->bind_columns( \$count );
	$statement->fetch();
	if ($count eq 0) {
		$statement =  $db_handle->prepare("INSERT INTO pathcomponent VALUES($end1,$end2,$linkid)")
			or die("Couldn't prepare query: $DBI::errstr\n");
		$statement->execute()
			or die("Couldn't execute statement: $DBI::errstr\n");
	}
}

sub traverse {
	my $start = shift;
	my $end = shift;
	our $graph;

	my @path = $graph->SP_Dijkstra($start, $end);
	foreach my $component (@path) {
		storePathComponent($start,$end,$component);
	}
}

sub getSharedPaths {

}

sub getEndpointsThroughPath {

}

sub processPerformance {
	our $graph;
	our @componenterrorcount;
	our @componentsuccesscount;
	our $maxcomponentsuccess;
	our $maxcomponenterror;

	our @nodefailurecount = ();
	our @nodesuccesscount = ();
	our $maxnodeerror = 0;
	our $maxnodesuccess = 0;

	our $threshold;

	my $statement =  $db_handle->prepare("SELECT end1,end2,performance FROM performance WHERE timeperiod=$timestamp")
		or die("Couldn't prepare query: $DBI::errstr\n");
	$statement->execute()
		or die("Couldn't execute statement: $DBI::errstr\n");
	my ($end1,$end2,$performance);
	$statement->bind_columns(  \$end1, \$end2, \$performance );
	while ($statement->fetch()) {
		if (!($end1 eq $end2)) {
			my @path = $graph->SP_Dijkstra($end1, $end2);
			my $last = $end1;
		#	print "path: ";
		#	if ($performance < $threshold) {
		#		print "(--POOR)";
		#	} else {
		#		print "(++good)";
		#	}
		#	print getNodeLabel($last)."->";
			foreach my $component (@path) {
				if ($last != $component) {
		#			print getNodeLabel($component)."->";
					if ($performance < $threshold) {
						if (defined( $componenterrorcount[$last][$component] )) {
							$componenterrorcount[$last][$component] = $componenterrorcount[$last][$component] + 1;
						} else {
							$componenterrorcount[$last][$component] = 1;
						}
						if ($componenterrorcount[$last][$component] > $maxcomponenterror) {
							$maxcomponenterror = $componenterrorcount[$last][$component];
						}
						if (defined($nodefailurecount[$last])) {
							$nodefailurecount[$last] = $nodefailurecount[$last] + 1;
						} else {
							$nodefailurecount[$last] = 1;
						}
						if ($nodefailurecount[$last] > $maxnodeerror) {
							$maxnodeerror = $nodefailurecount[$last];
						}
					} else {
						if (defined( $componentsuccesscount[$last][$component] )) {
							$componentsuccesscount[$last][$component] = $componentsuccesscount[$last][$component] + 1;
						} else {
							$componentsuccesscount[$last][$component] = 1;
						}
						if ($componentsuccesscount[$last][$component] > $maxcomponentsuccess) {
							$maxcomponentsuccess = $componentsuccesscount[$last][$component];
						}
						if (defined($nodesuccesscount[$last])) {
							$nodesuccesscount[$last] = $nodesuccesscount[$last] + 1;
						} else {
							$nodesuccesscount[$last] = 1;
						}
						if ($nodesuccesscount[$last] > $maxnodesuccess) {
							$maxnodesuccess = $nodesuccesscount[$last];
						}

					}
					$last = $component;
				}
			}
		#	print"\n";
		}
	}
}

sub getColorFromFailRate {
	my $rate = shift;

#return ((($rate/100)*.5)+.3).",1,1";

	if ($rate >= 20) {
		return 'red';
	} elsif ($rate >= 10 ) {
		return 'orange';
	} elsif ($rate  >= 5) {
		return 'yellow';
	} else {
		return 'green';
	}
}

sub getSegmentFailRate {
	my $end1 = shift;
	my $end2 = shift;
	our @componenterrorcount;
	our @componentsuccesscount;
	our $maxcomponenterror;

	if (!(defined($componenterrorcount[$end1][$end2]))) {
		return 0;
	}

	if (!(defined($componentsuccesscount[$end1][$end2]))) {
		return 100;
	}

#	my $ecost = $componenterrorcount[$end1][$end2];
#	if (defined($ecost)) {
#		$ecost = $ecost/$maxcomponenterror;
#	} else {
#		$ecost = 0;
#	}
#	my $scost = $componentsuccesscount[$end1][$end2];
#	if (defined($scost)) {
#		$scost = $scost/$maxcomponentsuccess;
#	} else {
#		$scost = 1;
#	}
#
#	my $totalcost = (1 + $ecost - $scost) / 2;
#	if ($ecost == 0) {
#		$totalcost = 0;
#	}

	my $totalcost = $componenterrorcount[$end1][$end2] / ($componenterrorcount[$end1][$end2] + $componentsuccesscount[$end1][$end2]);
	return 100 * $totalcost;
}

sub getNodeFailRate {
	my $node = shift;
	our @nodefailurecount;
	our @nodesuccesscount;
	our $maxnodeerror;
	our $maxnodesuccess;

	if (!defined($nodefailurecount[$node])) {
		return 0;
	}

	if (!defined($nodesuccesscount[$node])) {
		return 100;
	}

#	my $ecost = $nodefailurecount[$node];
#	if (defined($ecost)) {
#		$ecost = $ecost/$maxnodeerror;
#	} else {
#		$ecost = 0;
#	}
#	my $scost = $nodesuccesscount[$node];
#	if (defined($scost)) {
#		$scost = $scost/$maxnodesuccess;
#	} else {
#		$scost = 1;
#	}
#
#	my $totalcost = (1 + $ecost - $scost) / 2;
#	if ($ecost == 0) {
#		$totalcost = 0;
#	}

	my $totalcost = $nodefailurecount[$node]/($nodefailurecount[$node] + $nodesuccesscount[$node]);
	
	return 100 * $totalcost;
}


sub printNodeFailRates() {
	our @nodefailurecount;
	for my $i ( 0 .. $#nodefailurecount) {
		print "fail rate of ".getNodeLabel($i)." is:		".getNodeFailRate($i)."\n";
	}
}

sub printComponentFailRates() {
#	our @componenterrorcount;
#	for my $i ( 0 .. $#componenterrorcount ) {
#		my $row = $componenterrorcount[$i];
#		for my $j ( 0 .. $#{$row} ) {
#			if (defined( $row->[$j] )) {
#				print "fail rate of segment $i $j is $row->[$j]/$maxcomponenterror\n";
#			}
#		}
#	}

#	our @componentsuccesscount;
#	for my $i ( 0 .. $#componentsuccesscount ) {
#		my $row = $componentsuccesscount[$i];
#		for my $j ( 0 .. $#{$row} ) {
#			if (defined( $row->[$j] )) {
#				print "success rate of segment $i $j is $row->[$j]/$maxcomponentsuccess\n";
#			}
#		}
#	}

	my %scores;
	my @edges = $graph->edges();
	foreach (@edges) {
		my @es = $_;
		my $cost = getSegmentFailRate($es[0][0],$es[0][1]);
		$scores{getNodeLabel($es[0][0])."->".getNodeLabel($es[0][1])} = $cost;
	}
	my @sorted = sort{ $scores{$a} cmp  $scores{$b} } keys %scores;
	foreach (@sorted) {
		print "$_ is $scores{$_}\n";
	}

}	

sub usage {
	print STDERR << "EOF";

This script is under development and may not work as advertised.

Version 0.1-2006-11-13

usage: $0 -n network -m metric -t timestamp -v 1

-n	: network to run analysis on 
-m 	: metric to use as the path performance criteria
-t 	: timestamp to look at
-v	: success threshold 

example: $0 -n faultlocation -m performance -t 1 -v 1

output: graph_1_1.png - graph of network with composite performance overlay with 
	anything less than 1 being a failure.

EOF
	exit;
}

sub init {
	my %opts;
	getopt('nmtv', \%opts);
	if (defined($opts{'n'})) {
		$network = $opts{'n'};
	} else {
		usage();
	}
	if (defined($opts{'m'})) {
		$metric = $opts{'m'};
	} else {
		usage();
	}
	if (defined($opts{'t'})) {
		$timestamp = $opts{'t'};
	} else {
		usage();
	}
	if (defined($opts{'v'})) {
		$threshold = $opts{'v'};
	} else {
		usage();
	}

	our @endpoints;
	#our $db_handle = DBI->connect("dbi:mysql:database=$network;user=root;host=beaker.rnoc.gatech.edu")
	our $db_handle = DBI->connect("dbi:mysql:database=$network;user=root;host=localhost")
	                or die("Couldn't connect to database: $DBI::errstr\n");
	our $graph = Graph::Directed->new;

	loadGraph();	
	getEndpoints();
	processPerformance();
	drawGraph();
	#printNodeFailRates();
	#printComponentFailRates();
}
	
init();
