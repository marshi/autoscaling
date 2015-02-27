#!/bin/sh

USAGE="sh zabbix_delete_host {containerId}"

if [ ! $* -eq 1 ]; then
  echo $USAGE
  exit 1;
fi

CONTAINER=$1

TOKEN=`curl -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`
GET_JSON="{\"jsonrpc\": \"2.0\", 
       \"method\": \"host.get\", 
       \"params\": {
           \"filter\": {
               \"host\": [\"$CONTAINER\"]
           }
       }, \"auth\": ${TOKEN}, \"id\": 1}"
HOSTID=`curl -X GET -H "Content-Type:application/json-rpc" -d "${GET_JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq '.result[].hostid'
DELETE_JSON="{
       \"jsonrpc\": \"2.0\",
       \"method\": \"host.delete\",
       \"params\": [
           $HOSTID
       ],
       \"auth\": $TOKEN,
       \"id\": 1
       }"

curl -X GET -H "Content-Type:application/json-rpc" -d "${DELETE_JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php
