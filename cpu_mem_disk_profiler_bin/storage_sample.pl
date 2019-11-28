#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;

my $interval;
my $storage_file;
my @directories = ();
my @dirNames = ();

GetOptions (
    "interval=i"        => \$interval,
    "storagefile=s"     => \$storage_file,
    "directory=s"       => \@directories,
    "name=s"            => \@dirNames,
);

if (!defined $interval || !defined $storage_file || @directories <= 0) {
    print STDERR "Usage:   perl ps_io_sample.pl -interval=<> -storagefile=<> -directory=<> -name=<>\n";
    print STDERR "Example: perl ps_io_sample.pl -interval=10 -storagefile=storage.log -directory=/tmp -name=TMP\n";
    exit(1);
}

if (@dirNames > 0) {
    if (@directories != @dirNames) {
        print STDERR "name should be corresponded to directory.\n";
        exit(1)
    }
}

open SD_OUT, ">" . $storage_file or die "Can't open $storage_file";

while(1) {
    for (my $i = 0; $i < @directories; $i++) {
        if (@dirNames > 0) {
            my $dir = $directories[$i];
            $dir =~ s#/#\\\/#g;
            # print "/usr/bin/du -sb $directories[$i] | sed 's/$dir/$dirNames[$i]/g'";
            print SD_OUT `/usr/bin/du -sb $directories[$i] | sed 's/$dir/$dirNames[$i]/g'`;
        } else {
            print SD_OUT `/usr/bin/du -sb $directories[$i]`;
        }
    }
    sleep($interval);
}