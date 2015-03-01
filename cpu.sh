#!/bin/sh

# usage: cpu.sh [-d] [-c \"docker or libvirt\"] [container] 
# cpu使用率を出力.
#

USAGE="usage: cpu.sh [-d] [-c \"docker or libvirt\"] [container] "
CONTAINER_TYPE="docker"
LXC_CPU_DIR=/cgroup/cpu/cpuacct/lxc
DEBUG_FLG=0

cpu(){
  container=${1}
  dir=$LXC_CPU_DIR/$container
  if [ $DEBUG_FLG -eq 1 -a ! -d $dir ]; then
    echo "container not found; check option -c(CONTAINER TYPE. docker or libvirt)"
    exit 1;
  fi
  cpu_file=$dir/cpuacct.usage
  if [ ! -e $cpu_file ]; then
    return 1
  fi

  #CPU使用時間時間の差分を計算
  cur_cpu_time=`cat $cpu_file` 
  egrep [0-9]+ /tmp/$container.usage > /dev/null 
  if [ $? -eq 0 ]; then
    prev_cpu_time=`cat /tmp/$container.usage` > /dev/null 
  else
    prev_cpu_time=0
  fi 
  diff_cpu_time=`expr $cur_cpu_time - $prev_cpu_time | xargs -i echo "scale=5; {} / 1000 / 1000 / 100" | bc`

  #経過時間の差分を計算
  cur_time=`date +%s`
  egrep [0-9]+ /tmp/$container.time > /dev/null 
  if [ $? -eq 0 ]; then
    prev_time=`cat /tmp/$container.time` > /dev/null
  else
    prev_time=0
  fi 
  diff_time=`expr $cur_time - $prev_time`
  if [ $DEBUG_FLG -eq 1 ]; then
    echo $container
  fi
  
  if [ `echo "$diff_cpu_time == 0" | bc` -eq 1 ]; then
    res_cpu=0
  else
    res_cpu=`echo "scale=5; $diff_cpu_time / $diff_time * 100" | bc`
  fi
  echo $res_cpu
  #現在経過時間の格納
  echo $cur_time > /tmp/$container.time
  echo $cur_cpu_time > /tmp/$container.usage
}

all(){
if [ ! -d $LXC_CPU_DIR ]; then
  echo $USAGE
  exit 1;  
fi
for dir in `find $LXC_CPU_DIR/* -type d`; do
  container=`basename $dir`
  cpu $container
done
}

while getopts dc: opt
do
  case ${opt} in
    d)
      DEBUG_FLG=1
      ;;
    c)
      CONTAINER_TYPE=$OPTARG
      ;;
    \?)
      echo $USAGE
      exit 1
      ;;
  esac
done

shift $((OPTIND - 1))

if [ ${CONTAINER_TYPE}x = "libvirt"x ]; then
  LXC_CPU_DIR=/sys/fs/cgroup/cpuacct/machine
fi

if [ $# -eq 0 ]; then
  all
  exit 0
fi

if [ $# -eq 1 ];then
  container=$1
  if [ $CONTAINER_TYPE = "libvirt" ]; then
    container=${container}.libvirt-lxc
  fi
  cpu $container
  if [ $? -eq 1 ]; then
    exit 1;
  fi
  exit 0
else
  echo $USAGE 
  exit 1
fi

