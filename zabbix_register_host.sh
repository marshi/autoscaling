#!/bin/sh

# ./send_zabbix_cpu.sh
#
# zabbixサーバから起動IPに属するホスト一覧を取得し、そのホスト上で起動しているdockerのcpu使用率をsend_zabbix APIを使ってzabbixサーバに送る.
#

SERVER_IP=${ZABBIX_SERVER_IP}
if [ -z ${SERVER_IP} ]; then
  echo "please set ZABBIX_SERVER_IP"
  exit 1
fi


IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2|grep -v ^$`

TOKEN=`curl -s -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php  | jq ".result"`

JSON="{
  \"id\":1,
  \"jsonrpc\": \"2.0\",
  \"auth\": ${TOKEN},
  \"method\": \"host.create\",
  \"params\":{
    \"host\": \"`hostname`\",
    \"interfaces\": [
      {
        \"type\": 1,
        \"main\": 1,
        \"useip\": 1,
        \"ip\": \"${IP}\",
        \"dns\": \"\",
        \"port\": \"10050\"
      }
    ],
    \"groups\": [
      {
        \"groupid\": \"9\"
      }
    ],
    \"templates\": [
      {\"templateid\": \"10343\"}
    ]
  }
}"

echo $JSON

RESULT=`curl -s -X GET -H "Content-Type:application/json-rpc" -d "${JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php` # |  jq ".result[].host"`
echo $RESULT

