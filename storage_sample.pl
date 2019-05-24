#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;

my $interval;
my $storage_file;

GetOptions (
    "interval=i"        => \$interval,
    "storagefile=s"     => \$storage_file,
);

if (!defined $interval || !defined $storage_file) {
    print STDERR "Usage:   perl ps_io_sample.pl -interval=<> -storagefile=<>\n";
    print STDERR "Example: perl ps_io_sample.pl -interval=10 -storagefile=storage.log\n";
    exit(1);
}

open SD_OUT, ">" . $storage_file or die "Can't open $storage_file";

while(1) {
    print SD_OUT `/usr/bin/du -sb /mnt/ssd/MegaBOLT/tmpDir /mnt/ssd/MegaBOLT/QCtmpDir | sed 's/\\\/mnt\\\/ssd\\\/MegaBOLT\\\///'`;
    sleep($interval);
}