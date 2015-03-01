#!/bin/sh

DIR=`dirname ${0}`

if [ ! $# -eq 1 ]; then
  echo error. please specify appid
  exit 1
fi

APPID=$1
WEB_NUM=`sudo flynn -a $APPID scale | awk -F "=" '{print $2}'`
if [ $WEB_NUM -eq 0 ]; then
  echo web is only one node.
  exit 0;
fi
WEB_NUM=`expr $WEB_NUM - 1`

echo $WEB_NUM

CLUSTER=`sudo flynn -a $APPID scale web=$WEB_NUM | egrep "down|crashed" | awk '{print $4}' | awk -F "-" '{print $2}'`

echo $CLUSTER

sh $DIR/zabbix_delete_host.sh $CLUSTER

