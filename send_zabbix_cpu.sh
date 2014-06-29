#!/bin/sh

SERVER_IP=10.34.48.194
IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2`

TOKEN=`curl -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`  

#特定IPのホスト一覧取得
JSON="{
  \"auth\": ${TOKEN} ,
  \"method\": \"host.get\",
  \"id\": 1,
  \"params\":{
    \"output\": [\"host\"],
    \"selectInterfaces\":\"extend\",
    \"filter\": {
      \"ip\":\"${IP}\"
    }
  },
  \"jsonrpc\": \"2.0\"
}"

HOSTS=`curl -X GET -H "Content-Type:application/json-rpc" -d "${JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php |  jq ".result[].host"`
echo $HOSTS
