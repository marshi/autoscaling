#!/bin/sh

# usage: ./cpu.sh 

LXC_CPU_DIR=/cgroup/cpu/cpuacct/lxc

for dir in `find $LXC_CPU_DIR/* -type d`; do
  container=`basename $dir`
  cpu_file=$dir/cpuacct.stat
  time_file=$dir/cpuacct.usage

  #経過時間の差分を計算
  cur_time=`cat $time_file`
  egrep [0-9]+ /tmp/$container.usage $2>1 > /dev/null
  if [ $? -eq 0 ]; then
    prev_time=`cat /tmp/$container.usage`
  else
    prev_time=0
  fi 
  diff_time=`expr $cur_time - $prev_time | xargs -i echo "scale=5;{} / 1000 / 1000 / 1000" | bc`

  #CPU使用時間の差分を計算
  cur_cpu_time=`grep user $cpu_file | cut -d " " -f 2`
  egrep [0-9]+ /tmp/$container.stat $2>1 > /dev/null
  if [ $? -eq 0 ]; then
    prev_cpu_time=`cat /tmp/$container.stat`
  else
    prev_cpu_time=0
  fi 
  diff_cpu_time=`expr $cur_cpu_time - $prev_cpu_time | xargs -i echo "scale=5; {} / 100" | bc`
  echo $container
  echo "scale=5; $diff_cpu_time / $diff_time * 100" | bc
  
  #現在経過時間の格納
  echo $cur_time > /tmp/$container.usage
  echo $cur_cpu_time > /tmp/$container.stat
done
