#!/bin/sh

# ./send_zabbix_cpu.sh
#
# 現在稼働中のノード数をzabbixに送る.
#

SERVER_IP=${ZABBIX_SERVER_IP}
if [ -z ${SERVER_IP} ]; then
  echo "please set ZABBIX_SERVER_IP"
  exit 1
fi


IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2`
ID=zabbix-httpd

TOKEN=`curl -s -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`  

#特定IPのホスト一覧取得
NODE_NUM=`http GET http://${SERVER_IP}:8080/v2/apps | jq '.apps[]' | jq "select(.id == \"${ID}\") .instances"`
echo $NODE_NUM
zabbix_sender -z ${SERVER_IP} -p 10051 -s "Zabbix server" -k "docker_node_num" -o "${NODE_NUM}" 
