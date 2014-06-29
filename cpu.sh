#!/bin/sh

# usage: ./cpu.sh 

LXC_CPU_DIR=/cgroup/cpu/cpuacct/lxc

cpu(){
  container=$1
  dir=$LXC_CPU_DIR/$container
  cpu_file=$dir/cpuacct.stat
  time_file=$dir/cpuacct.usage

  #経過時間の差分を計算
  cur_time=`cat $time_file`
  egrep [0-9]+ /tmp/$container.usage > /dev/null &2>1
  if [ $? -eq 0 ]; then
    prev_time=`cat /tmp/$container.usage`
  else
    prev_time=0
  fi 
  diff_time=`expr $cur_time - $prev_time | xargs -i echo "scale=5;{} / 1000 / 1000 / 1000" | bc`

  #CPU使用時間の差分を計算
  cur_cpu_time=`grep user $cpu_file | cut -d " " -f 2`
  egrep [0-9]+ /tmp/$container.stat >/dev/null &2>1 
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
}

all(){
for dir in `find $LXC_CPU_DIR/* -type d`; do
  container=`basename $dir`
  cpu $container
done
}

if [ $# -eq 0 ]; then
  all
  exit 0
fi

if [ $# -eq 1 ];then
  container=$1
  cpu $container
  exit 0
else
  echo usage: cpu.sh container
  exit 1
fi


