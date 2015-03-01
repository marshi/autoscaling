#!/bin/sh

DIR=`dirname ${0}`

if [ ! $# -eq 1 ]; then
  echo error. please specify appid
  exit 1
fi

APPID=$1
WEB_NUM=`flynn -a $APPID scale | awk -F "=" '{print $2}'`
if [ $WEB_NUM -le 1 ]; then
  echo web is small node already.
  exit 0;
fi
echo $WEB_NUM
WEB_NUM=`expr $WEB_NUM - 1`
echo $WEB_NUM

CLUSTER=`flynn -a $APPID scale web=$WEB_NUM | egrep "down|crashed" | awk '{print $4}' | awk -F "-" '{print $2}'`

echo $CLUSTER

echo "sh $DIR/zabbix_delete_host.sh $CLUSTER"
sh $DIR/zabbix_delete_host.sh $CLUSTER

