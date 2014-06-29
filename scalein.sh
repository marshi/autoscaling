#!/bin/sh
INSTANCE=0
ID=zabbix-httpd
CPU=0.5
IP=10.34.48.194

INSTANCES=`http GET http://${IP}:8080/v2/apps | jq '.apps[]' | jq "select(.id == \"${ID}\") .instances"`
echo $INSTANCES
if [ -z $INSTANCES ]; then
  echo instance = $INSTANCES
  exit 1
fi
if [ $INSTANCES -le 0 ]; then
  exit 1
fi
INSTANCES=`expr $INSTANCES - 1`
echo $INSTANCES 
http --verbose --ignore-stdin PUT http://$IP:8080/v2/apps/${ID} instances=$INSTANCES
