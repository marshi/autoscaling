#!/bin/sh

# usage: cpu.sh [-d] [container]
#
# cpu使用率を出力.
#

LXC_CPU_DIR=/cgroup/cpu/cpuacct/lxc
USAGE="usage: cpu.sh [-d] [container]"

cpu(){
  container=$1
  dir=$LXC_CPU_DIR/$container
  cpu_file=$dir/cpuacct.stat
  time_file=$dir/cpuacct.usage
  if [ ! -e $cpu_file -o ! -e $time_file ]; then
    return 1
  fi

  #経過時間の差分を計算
  cur_time=`cat $time_file` 
  egrep [0-9]+ /tmp/$container.usage > /dev/null 
  if [ $? -eq 0 ]; then
    prev_time=`cat /tmp/$container.usage` > /dev/null 
  else
    prev_time=0
  fi 
  diff_time=`expr $cur_time - $prev_time | xargs -i echo "scale=5;{} / 1000 / 1000 / 1000" | bc`

  #CPU使用時間の差分を計算
  user_cpu=`grep user $cpu_file`
  cur_cpu_time=`echo $user_cpu | cut -d " " -f 2`
  egrep [0-9]+ /tmp/$container.stat > /dev/null 
  if [ $? -eq 0 ]; then
    prev_cpu_time=`cat /tmp/$container.stat` > /dev/null
  else
    prev_cpu_time=0
  fi 
  diff_cpu_time=`expr $cur_cpu_time - $prev_cpu_time | xargs -i echo "scale=5; {} / 100" | bc`
  if [ -n "$DEBUG_FLG" ]; then
    echo $container
  fi
  res_cpu=`echo "scale=5; $diff_cpu_time / $diff_time * 100" | bc`
  echo $res_cpu
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

while getopts d opt
do
  case ${opt} in
    d)
      DEBUG_FLG=1
      ;;
    \?)
      echo $USAGE
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ $# -eq 0 ]; then
  all
  exit 0
fi

if [ $# -eq 1 ];then
  container=$1
  cpu $container
  if [ $? -eq 1 ]; then
    exit 1;
  fi
  exit 0
else
  echo $USAGE 
  exit 1
fi


