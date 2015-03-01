#!/bin/sh

ZABBIX_SERVER_IP=10.34.48.194
SERVER_IP=${ZABBIX_SERVER_IP}
if [ -z ${SERVER_IP} ]; then
  echo "please set ZABBIX_SERVER_IP"
  exit 1
fi

HOSTNAME=`hostname`
while getopts h: opt; do
  case $opt in
    h) 
      HOSTNAME=$OPTARG
      ;;
   esac
done

shift $((OPTIND - 1))

IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2|grep -v ^$`

TOKEN=`curl -s -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php  | jq ".result"`

JSON="{
  \"id\":1,
  \"jsonrpc\": \"2.0\",
  \"auth\": ${TOKEN},
  \"method\": \"host.create\",
  \"params\":{
    \"host\": \"${HOSTNAME}\",
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

RESULT=`curl -s -X GET -H "Content-Type:application/json-rpc" -d "${JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php` #| jq ".result[].host"`
echo $RESULT

