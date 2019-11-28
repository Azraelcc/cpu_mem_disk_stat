#!/usr/bin/env bash

prefix=${1}
interval=${2}

script_dir=`readlink -f ${0}`
base_dir=${script_dir%/*}
cpu_mem_disk_stat=${base_dir}/cpu_mem_disk_stat.pl
plot_cpu_mem_disk=${base_dir}/plot_cpu_mem_disk.R

perl ${cpu_mem_disk_stat} -interval=${interval} -psfile=${prefix}.cpu_memory.log -iofile=${prefix}.disk_io.log -storagefile=${prefix}.storage.log -cpu=${prefix}.cpu.dat -mem=${prefix}.mem.dat -io=${prefix}.io.dat -storage=${prefix}.storage.dat

Rscript ${plot_cpu_mem_disk} ${prefix}
