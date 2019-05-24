#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;

my $interval;
my $ps_file;

GetOptions (
    "interval=i"    => \$interval,
    "psfile=s"      => \$ps_file,
);

if (!defined $interval || !defined $ps_file) {
    print STDERR "Usage:   perl ps_io_sample.pl -interval=<> -psfile=<>\n";
    print STDERR "Example: perl ps_io_sample.pl -interval=10 -psfile=ps.log\n";
    exit(1);
}

open PS_OUT, ">" . $ps_file or die "Can't open $ps_file";

while(1) {
    print PS_OUT `ps ux`;
    sleep($interval);
}

