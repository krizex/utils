#!/bin/bash

trap "stop_tracing" SIGINT SIGQUIT SIGTERM

tracing_dir=/sys/kernel/debug/tracing
cat_pid=
is_stopping=false

function do_stop()
{
    # turn off trace
    # killall xentrace
    echo 0 > ${tracing_dir}/events/kmem/enable
    echo 0 > ${tracing_dir}/events/net/enable
    echo 0 > ${tracing_dir}/tracing_on
    kill $cat_pid
    is_stopping=true
}

function stop_tracing ()
{
    echo "Caught signal, killing subprocess..."
    do_stop 
    sleep 1
}

function start_trace ()
{
    duration=$1
    interval=$2
    size_limit=$3
    logdir="mem_debug_$(date +%Y%m%d%H%M%S)"

    if [ $duration -lt $interval ]; then
        echo "duration should be greater than $interval"
        exit 1
    fi

    mount -t debugfs none /sys/kernel/debug

    # enable trace
    echo 1 > /proc/sys/kernel/ftrace_enabled 

    # turn off trace
    echo 0 > ${tracing_dir}/tracing_on 
    # clear trace buff
    echo > ${tracing_dir}/trace
    echo nop > ${tracing_dir}/current_tracer 
    echo 1 > ${tracing_dir}/events/kmem/enable
    echo 1 > ${tracing_dir}/events/net/enable
    echo "x86-tsc" > ${tracing_dir}/trace_clock

    mkdir -p ${logdir}
    pushd ${logdir} > /dev/null

    # turn on trace
    echo 1 > ${tracing_dir}/tracing_on

    # /usr/sbin/xentrace -D -x -e 0x0010f000 trace_file.bin &
    cat ${tracing_dir}/trace_pipe | gzip > ftrace.gz &
    worker_pid=$!
    parent_pid=`ps -o ppid --no-headers $worker_pid`
    cat_pid=`pgrep -P $parent_pid cat`
    dur=0
    while [ $dur -lt $duration ] && [ "$is_stopping" = false ]; do
      size=$(stat --printf="%s" ftrace.gz)
      if [ $((size_limit * 1000000)) -lt $size ]; then
        echo "Reached size limitation."
        break
      fi

      ts=`date +%Y%m%d%H%M%S`
      /usr/bin/pidstat -r -p ALL > pidstat_$ts.log
      /usr/bin/free -k  > free_$ts.log
      /usr/bin/slabtop -o > slabtop_$ts.log
      cat /proc/meminfo > meminfo_$ts.log
      /usr/sbin/xentop -b -i 1 > xentop_$ts.log
      cat /proc/pagetypeinfo > proc-pagetypeinfo_$ts.log
      cat /proc/buddyinfo > proc-buddyinfo_$ts.log
      cat /proc/iomem > proc-iomem_$ts.log
      cat /proc/vmallocinfo > proc-vmallocinfo_$ts.log
      cat /proc/modules > proc-modules_$ts.log

      sleep $interval
      dur=$((interval + dur))
    done

    mkdir -p sys-module/
    cp -r /sys/module/* sys-module/

    if [ "$is_stopping" = false ] ; then
      do_stop 
    fi

    popd > /dev/null
    tar cjf $logdir.tar.bz2 $logdir/*
    rm -rf $logdir
    echo "Done."
}

if [ $# != 3 ]; then
    echo "$0 <duration in secs> <interval in secs> <size in MB>"
    exit 1
fi

start_trace $*

