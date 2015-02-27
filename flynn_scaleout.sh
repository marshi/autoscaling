#!/bin/sh

WEB_NUM=`sudo flynn scale | awk -F "=" '{print $2}'`
WEB_NUM=`expr $WEB_NUM + 1`

CLUSTER=`sudo flynn scale web=$WEB_NUM | grep up | awk '{print $4}' | awk -F "-" '{print $2}'`

sh zabbix_register_host.sh -h $CLUSTER

