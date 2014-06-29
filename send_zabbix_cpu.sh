#!/bin/sh

# ./send_zabbix_cpu.sh
#
# zabbixサーバから起動IPに属するホスト一覧を取得し、そのホスト上で起動しているdockerのcpu使用率をsend_zabbix APIを使ってzabbixサーバに送る.
#

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
for host in $HOSTS; do
  host=`echo $host | sed 's/\"//g'`
  cpu=`sh cpu.sh $host`
  echo zabbix_sender -z ${SERVER_IP} -p 10051 -s "${host}" -k "docker_cpu" -o "${cpu}"
  zabbix_sender -z ${SERVER_IP} -p 10051 -s "${host}" -k "docker_cpu" -o "${cpu}"
done
