#!C:\perl\bin\perl -w

use strict;

my $spamdir    = "C:\\cygwin\\home\\is_spam\\.maildir";
my $hamdir     = "C:\\cygwin\\home\\not_spam\\.maildir";
my $storedir      = "C:\\cygwin\\home\\system\\mail";

chdir($spamdir);
foreach my $file (<*>) {
    if (-f $file) {
        system("headermangle.pl < $file > $storedir\\spam\\$file"
    }
}

chdir($hamdir);
foreach my $file (<*>) {
    if (-f $file) {
        system("headermangle.pl < $file > $storedir\\ham\\$file"
    }
}

system("sa-learn --spam $storedir\\spam");
system("sa-learn --ham $storedir\\ham");