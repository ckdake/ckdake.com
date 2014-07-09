#!/usr/bin/perl -w 

# This is supposed to extract the header bits we don't want and toss them, and save the relevant ones for some future purpose.

use strict;
local ($/); #sets the record separator built-in variable to null rather than '\n';

my $debug = '0';
my ($subject, $from, $replyto, $to, $date) = "";

my $message = <>; # now we slurp the entire file into the scalar $message

# then we look to see if it's been forwarded or not,
# next rip out all the X- whatnot headers,
# then pull out the From: and Reply to: if they're there
# Last just spew the mail out after the original message delimiter


$message =~ /----- Original Message -----.*\n|Begin forwarded .*\n/;

if ($') { my $newmessage = $'; 			# grab everything after the "Original..."
		$newmessage =~ s/X-.*\n//g; 	# rip out all the previous X-header crap
		 # get other relevant headers in here. 
		 # Do we need to account for ">" in some forwarded messages, 
		 # is ">" ever in front of the headers we want? (probably not?)

		getbasicheaders ();

		print "$newmessage";
		if ($debug) {   print "\n(New message)\n";
				print "It was sent to $to, on $date,\nallegedly from $from,\nabout \"$subject\"\n";
		}
} else { $message =~ s/X-.*\n//g;
		
		getbasicheaders ();
		print "$message";
		if ($debug) {	print "\n(Original message)\n";
		}
}	

sub getbasicheaders {
		if ($message =~ /Subject: (.*)/ ) { $subject = $1; }
		if ($message =~ /From: (.*)/ ) { $from = $1; }
		if ($message =~ /Reply to: (.*)/ ) { $replyto = $1; }
		if ($message =~ /To: (.*)/ ) { $to = $1; }
		if ($message =~ /Sent: (.*)/ ) { $date = $1; }
}
