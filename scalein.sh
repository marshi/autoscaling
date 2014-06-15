#!/bin/sh
PID=/home/share/mukai_masaki/scaleup.pid
INSTANCE=0
ID=zabbix-httpd
CPU=0.5
IP=10.34.48.194

whoami >> /home/share/mukai_masaki/a.txt
INSTANCES=`http GET http://localhost:8080/v2/apps | jq '.apps[]' | jq "select(.id == \"${ID}\") .instances"`
echo $INSTANCES
if [ $INSTANCES -le 0 ]; then
  return
fi
INSTANCES=`expr $INSTANCES - 1`
echo $INSTANCES >> /home/share/mukai_masaki/a.txt
http --verbose --ignore-stdin PUT http://$IP:8080/v2/apps/${ID} instances=$INSTANCES 2>> /home/share/mukai_masaki/a.txt
