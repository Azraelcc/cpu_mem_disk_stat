#!/usr/bin/env bash

prefix=${1}
interval=${2}

cpu_mem_disk_stat=cpu_mem_disk_stat.pl
plot_cpu_mem_disk=plot_cpu_mem_disk.R

perl ${cpu_mem_disk_stat} -interval=${interval} -psfile=${prefix}.cpu_memory.log -iofile=${prefix}.disk_io.log -storagefile=${prefix}.storage.log -cpu=${prefix}.cpu.dat -mem=${prefix}.mem.dat -io=${prefix}.io.dat -storage=${prefix}.storage.dat

Rscript ${plot_cpu_mem_disk} ${prefix}
