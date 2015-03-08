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

TOKEN=`curl -s -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`  

APPID=`flynn apps | grep example | awk '{print $1'}`

#特定IPのホスト一覧取得
NODE_NUM=`sudo flynn -a $APPID ps | grep web | wc -l `
echo $NODE_NUM
zabbix_sender -z ${SERVER_IP} -p 10051 -s "flynn_global_host" -k "flynn_node_num" -o "${NODE_NUM}" 

