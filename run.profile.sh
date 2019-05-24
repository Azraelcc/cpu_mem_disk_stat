#!/usr/bin/env bash

prefix=01.WGS.MegaBOLT
runScript=run.sh

interval=1
cpuLogFile=${PWD}/${prefix}.cpu_memory.log
ioLogFile=${PWD}/${prefix}.disk_io.log
storageLogFile=${PWD}/${prefix}.storage.log
inDisk=nvme0n1
tmpDisk=sdb
outDisk=nvme0n1
runlog=${PWD}/${prefix}.out

cpu_mem_sample=cpu_mem_sample.pl
storage_sample=storage_sample.pl
plot_cpu_mem_disk=cpu_mem_disk_stat.sh

# drop memory cache
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
echo Drop memory cache.

free -mh

# kill running cpu_mem_sample.pl & io_sample.sh
ps_sample_pid=`ps uxfe | grep cpu_mem_sample.pl | grep -v grep | awk '{print $2}'`
if [ ${ps_sample_pid} ];then
    kill ${ps_sample_pid}
    sleep 1s
fi
io_sample_pid=`ps uxfe | grep iostat | grep -v grep | awk '{print $2}'`
if [ ${io_sample_pid} ];then
    kill ${io_sample_pid}
    sleep 1s
fi
sd_sample_pid=`ps uxfe | grep storage_sample.pl | grep -v grep | awk '{print $2}'`
if [ ${sd_sample_pid} ];then
    kill ${sd_sample_pid}
    sleep 1s
fi

perl ${cpu_mem_sample} -interval=${interval} -psfile=${cpuLogFile} 1>/dev/null 2>&1 &
iostat -k -d ${inDisk} ${outDisk} ${tmpDisk} ${interval} 1>${ioLogFile} 2>/dev/null &
perl ${storage_sample} -interval=${interval} -storagefile=${storageLogFile} 1>/dev/null 2>&1 &

echo Sampling start.

ps_sample_pid=`ps uxfe | grep cpu_mem_sample.pl | grep -v grep | awk '{print $2}'`
io_sample_pid=`ps uxfe | grep iostat | grep -v grep | awk '{print $2}'`
sd_sample_pid=`ps uxfe | grep storage_sample.pl | grep -v grep | awk '{print $2}'`

echo Run start.
date
start=`date +%s`

sh ${runScript} 1>${runlog} 2>&1

end=`date +%s`
dif=$[end - start]
echo total run time: $dif s
date
echo Run finish.

sleep 10s

if [ ${ps_sample_pid} ];then
    if ps -p ${ps_sample_pid} >/dev/null
    then
        echo "cpu_mem_sample.pl is running, then kill"
        kill ${ps_sample_pid}
    fi
    if ! ps -p ${ps_sample_pid} >/dev/null
    then
        echo "cpu_mem_sample.pl is killed"
    fi
fi

if [ ${io_sample_pid} ];then
    if ps -p ${io_sample_pid} >/dev/null
    then
        echo "iostat is running, then kill"
        kill ${io_sample_pid}
    fi
    if ! ps -p ${io_sample_pid} >/dev/null
    then
        echo "iostat is killed"
    fi
fi

if [ ${sd_sample_pid} ];then
    if ps -p ${sd_sample_pid} >/dev/null
    then
        echo "storage_sample.pl is running, then kill"
        kill ${sd_sample_pid}
    fi
    if ! ps -p ${sd_sample_pid} >/dev/null
    then
        echo "storage_sample.pl is killed"
    fi
fi

echo Sampling finish.

echo Plot Profiling start.

sh ${plot_cpu_mem_disk} ${PWD}/${prefix} ${interval}

echo Plot Profiling finish.