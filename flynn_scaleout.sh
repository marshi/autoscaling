#!/bin/sh

DIR=`dirname ${0}`

if [ ! $# -eq 1 ]; then
  echo error. please specify appid
  exit 1
fi

APPID=$1
WEB_NUM=`flynn -a $APPID scale | awk -F "=" '{print $2}'`
WEB_NUM=`expr $WEB_NUM + 1`

echo $WEB_NUM

CLUSTER=`flynn -a $APPID scale web=$WEB_NUM | grep up | awk '{print $4}' | awk -F "-" '{print $2}'`

echo $CLUSTER

sh $DIR/zabbix_register_host.sh -h $CLUSTER

