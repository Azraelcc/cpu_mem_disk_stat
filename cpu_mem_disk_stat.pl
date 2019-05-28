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
open PS_IN, $ps_file or die "Can't open $ps_file";
open MEM_OUT, ">$mem_out" or die "Can't open $mem_out";
open CPU_OUT, ">$cpu_out" or die "Can't open $cpu_out";

my @MEM;
my @CPU;
my $num = 0;
my @line;

while (<PS_IN>) {
    chomp;
    next if (/^#/);
    @line = split;
    if ($line[0] eq "USER") {
        $num++;
        $MEM[$num] = 0;
        $CPU[$num] = 0;
    }
    else {
        $MEM[$num] += $line[5];
        $CPU[$num] += $line[2];
    }
}

my ($mem_max, $mem_avg, $cpu_max, $cpu_avg) = (0, 0, 0, 0);

print MEM_OUT "Time\tMemory\n";
print CPU_OUT "Time\tCPU\n";

for (my $i = 1; $i <= $num; $i++) {
    my $time = ($i - 1) * $interval;
    $MEM[$i] = $MEM[$i] / 1024 /1024;   # GB
    $CPU[$i] = $CPU[$i] / 100;          # CPU

    $mem_avg += $MEM[$i];
    if ($MEM[$i] > $mem_max) {
        $mem_max = $MEM[$i];
    }
    $cpu_avg += $CPU[$i];
    if ($CPU[$i] > $cpu_max) {
        $cpu_max = $CPU[$i];
    }

    print MEM_OUT "$time\t$MEM[$i]\n";
    print CPU_OUT "$time\t$CPU[$i]\n";
}

close PS_IN;
close MEM_OUT;
close CPU_OUT;

$mem_avg /= $num;
$cpu_avg /= $num;
print "MEM max: $mem_max GB, MEM avg: $mem_avg GB, CPU max: $cpu_max, CPU avg: $cpu_avg\n";

# IO stat
open IO_IN, $io_file or die "Can't open $io_file";

my @diskList;
my @IOstat;
$num = 0;

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

#open MEM_OUT, ">$mem_out" or die "Can't open $mem_out";
