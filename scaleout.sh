#!/bin/sh
PID=/home/share/mukai_masaki/scaleup.pid
INSTANCE=0
ID=zabbix-httpd
CPU=0.5
IP=10.34.48.194

#whoami >> /home/share/mukai_masaki/a.txt
if [ -f $PID ]; then
  INSTANCES=`http GET http://localhost:8080/v2/apps | jq '.apps[]' | jq "select(.id == \"${ID}\") .instances"`
  INSTANCES=`expr $INSTANCES + 1`
#  echo $INSTANCES >> /home/share/mukai_masaki/a.txt
  http --verbose --ignore-stdin PUT http://$IP:8080/v2/apps/${ID} instances=$INSTANCES # 2>> /home/share/mukai_masaki/a.txt
else
  sudo curl -X POST -H "Accept: application/json" -H "Content-Type: application/json" $IP:8080/v2/apps -d "{\"id\": \"${ID}\", \"cmd\": \"marshi/zabbix-httpd\", \"instances\": 1, \"mem\": 128, \"ports\":[22, 80, 10050], \"cpus\": ${CPU}, \"executor\": \"/var/lib/mesos/executors/docker\"}"
  echo $$ > $PID
fi
