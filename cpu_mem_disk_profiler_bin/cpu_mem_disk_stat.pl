#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Getopt::Long;

my $interval;
my ($ps_file, $io_file, $sd_file);
my ($cpu_out, $mem_out, $io_out, $sd_out);

GetOptions (
    "interval=i"    => \$interval,
    "psfile=s"      => \$ps_file,
    "iofile=s"      => \$io_file,
    "storagefile=s" => \$sd_file,
    "cpu=s"         => \$cpu_out,
    "mem=s"         => \$mem_out,
    "io=s"          => \$io_out,
    "storage=s"     => \$sd_out,
);

if (!defined $interval || !defined $ps_file || !defined $io_file || !defined $sd_file ||
    !defined $cpu_out || !defined $mem_out || !defined $io_out || !defined $sd_out) {
    print STDERR "Usage:   perl cpu_mem_disk_stat.pl -interval=<> -psfile=<> -iofile=<> -storagefile=<> -cpu=<> -mem=<> -io=<> -storage=<>\n";
    print STDERR "Example: perl cpu_mem_disk_stat.pl -interval=10 -psfile=ps.log -iofile=io.log -storagefile=storage.log -cpu=cpu.out -mem=mem.out -io=io.out -storage=storage.out\n";
    exit(1);
}

# CPU & MEM stat
open STAT_IN, $ps_file or die "Can't open $ps_file";
open MEM_OUT, ">$mem_out" or die "Can't open $mem_out";
open CPU_OUT, ">$cpu_out" or die "Can't open $cpu_out";

print CPU_OUT "Time\twa\tsy\tus\n";
print MEM_OUT "Time\tshared\tcache\tused\n";

my ($cpu_num, $mem_num) = (0, 0);
my ($cpu_max, $cpu_avg, $mem_max, $mem_avg) = (0, 0, 0, 0);

while (<STAT_IN>) {
    chomp;
    my @line = split;
    if ($line[0] eq "%Cpu(s):") { # CPU
        my ($us, $sy, $wa);
        my $time = $cpu_num * $interval;
        $us = $line[1];
        $sy = $line[3];
        $wa = $line[9];
        my $total = $us + $sy + $wa;
        $cpu_avg += $total;
        if ($total > $cpu_max) {
            $cpu_max = $total;
        }
        print CPU_OUT "$time\t$wa\t$sy\t$us\n";
        $cpu_num++;
    } elsif ($line[0] eq "Mem:") { # MEM
        my ($used, $cache, $shared);
        my $time = $mem_num * $interval;
        $used = $line[2];
        $cache = $line[5];
        $shared = $line[4];
        my $total = $used + $shared;
        $mem_avg += $total;
        if ($total > $mem_max) {
            $mem_max = $total;
        }
        print MEM_OUT "$time\t$shared\t$cache\t$used\n";
        $mem_num++;
    }
}

close STAT_IN;
close MEM_OUT;
close CPU_OUT;

$cpu_avg /= $cpu_num;
$mem_avg /= $mem_num;

print "CPU max: $cpu_max %, CPU avg: $cpu_avg %, MEM max: $mem_max GB, MEM avg: $mem_avg GB\n";

# IO stat
open IO_IN, $io_file or die "Can't open $io_file";

my @diskList;
my @IOstat;
my @line;
my $num = 0;

while (<IO_IN>) {
    chomp;
    next if (/^#/ || /^Linux/ || length($_) == 0);
    @line = split;
    if ($line[0] eq "Device:") {
        $num++;
    } else {
        if (! grep {$_ eq $line[0]} @diskList) {
            push @diskList, $line[0];
        }
        $IOstat[$num]{$line[0]}{'read'} = $line[2];
        $IOstat[$num]{$line[0]}{'write'} = $line[3];
    }
}
close IO_IN;

print "@diskList\n";

# for (my $i = 0; $i < @diskList; $i++) {
#     open IO_OUT, ">$diskList[$i].$io_out" or die "Can't open $diskList[$i].$io_out";
#     for (my $j = 1; $j <= $num; $j++) {
#         my $time = ($j - 1) * $interval;
#         print IO_OUT "$time\t$IOstat[$j]{$diskList[$i]}{'read'}\t$IOstat[$j]{$diskList[$i]}{'write'}\n";
#     }
#     close IO_OUT;
# }
open IO_OUT, ">$io_out" or die "Can't open $io_out";

print IO_OUT "Time";
for (my $i = 0; $i < @diskList; $i++) {
    print IO_OUT "\t$diskList[$i]_read\t$diskList[$i]_write";
}
print IO_OUT "\n";
for (my $i = 1; $i <= $num; $i++) {
    my $time = ($i - 1) * $interval;
    print IO_OUT "$time";
    for (my $j = 0; $j < @diskList; $j++) {
        $IOstat[$i]{$diskList[$j]}{'read'} /= 1024;     # MB
        $IOstat[$i]{$diskList[$j]}{'write'} /= 1024;    # MB
        print IO_OUT "\t$IOstat[$i]{$diskList[$j]}{'read'}\t$IOstat[$i]{$diskList[$j]}{'write'}";
    }
    print IO_OUT "\n";
}
close IO_OUT;

# storage stat
open SD_IN, $sd_file or die "Can't open $sd_file";

my @dirList = ();
my @SDstat;
my $first;
my $lineNum = 0;
$num = 0;

while (<SD_IN>) {
    chomp;
    @line = split;
    if (@dirList == 0) {
        $first = $line[1]
    }
    if ($line[1] eq $first) {
        $num++;
    }
    if (! grep {$_ eq $line[1]} @dirList) {
        push @dirList, $line[1];
    }
    $lineNum++;
    $SDstat[$num]{$line[1]} = $line[0];
}
close SD_IN;

$num = int($lineNum / @dirList);

open SD_OUT, ">$sd_out" or die "Can't open $sd_out";

my $dirs = join "\t", @dirList;

print SD_OUT "Time\t$dirs\tTotal\n";
for (my $i = 1; $i <= $num; $i++) {
    my $time = ($i - 1) * $interval;
    my $total = 0;
    print SD_OUT "$time";
    for (my $j = 0; $j < @dirList; $j++) {
        $SDstat[$i]{$dirList[$j]} = $SDstat[$i]{$dirList[$j]} / 1024 / 1024 / 1024;         # GB
        $total += $SDstat[$i]{$dirList[$j]};
        print SD_OUT "\t$SDstat[$i]{$dirList[$j]}";
    }
    print SD_OUT "\t$total\n";
}
