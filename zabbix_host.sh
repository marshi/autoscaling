#!/bin/sh
#
# need to NOPASSWD setting
# need to nonpassword
#

ZABBIX_PORT=10050
HTTPD_PORT=80
SERVER_IP="10.34.48.194"
IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2`
TEMPLATE_ID=10113
GROUP_ID=8
HAPROXY_CONF=/etc/haproxy/haproxy.cfg
SSH="ssh 10.34.48.194 "

zabbix_docker() {
  while read EVENT; do
    START_EVENT=`echo $EVENT | grep --line-buffered start`
    IS_START_EVENT=$?
    STOP_EVENT=`echo $EVENT | grep --line-buffered stop`
    IS_STOP_EVENT=$?
    if [ $IS_START_EVENT == 0 ]; then
        CONTAINER=`echo $START_EVENT | awk -F '[ :]' '{print $7}{fflush()}'`
        start_event
    elif [ $IS_STOP_EVENT == 0 ]; then
        CONTAINER=`echo $STOP_EVENT | awk -F '[ :]' '{print $7}{fflush()}'`
        stop_event
    fi
  done
}

start_event() {
    PORT=`docker port $CONTAINER $ZABBIX_PORT | awk -F : '{print $2}{fflush()}'`
    echo docker port $CONTAINER $ZABBIX_PORT | awk -F : '{print $2}{fflush()}'
    echo port $PORT
    TOKEN=`curl -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`
    GET_JSON="{
             \"jsonrpc\": \"2.0\", 
             \"method\": \"host.create\", 
             \"params\": {
                 \"host\": \"${CONTAINER}\", 
                 \"interfaces\": [
                     {
                         \"type\": 1, 
                         \"main\": 1, 
                         \"useip\": 1, 
                         \"ip\": \"${IP}\", 
                         \"dns\": \"\", 
                         \"port\": \"${PORT}\"
                     } 
                 ], 
                 \"groups\": [
                     {\"groupid\": \"${GROUP_ID}\"} 
                 ], 
                 \"templates\": [
                     {\"templateid\": \"${TEMPLATE_ID}\"} 
                 ], \"inventory\": {
                         \"macaddress_a\": \"01234\", 
                         \"macaddress_b\": \"56768\"
                     } 
             }, 
             \"auth\": ${TOKEN}, 
             \"id\": 1
             }"
    curl -X GET -H "Content-Type:application/json-rpc" -d "${GET_JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php
    echo container=$CONTAINER port=$PORT server=$SERVER_IP template=$TEMPLATE_ID group=$GROUP_ID
    L_HTTPD_PORT=` docker port $CONTAINER $HTTPD_PORT | awk -F : '{print $2}{fflush()}'`
    JSON="{\"jsonrpc\": \"2.0\", \"method\": \"host.get\", \"params\": {\"output\": [\"hostid\"], \"filter\": {\"groupids\": ${GROUP_ID}}, \"auth\": ${TOKEN}, \"id\": 1}"
    echo $JSON

    #haproxyに追加
    $SSH echo "    server ${CONTAINER} ${IP}:${L_HTTPD_PORT} check" >> $HAPROXY_CONF
    $SSH /etc/init.d/haproxy reload
}

stop_event() {
    $SSH echo $CONTAINER
    $SSH grep $CONTAINER $HAPROXY_CONF
    #haproxyから削除
    $SSH sed -i -e "/${CONTAINER}/d" $HAPROXY_CONF  
    
    #zabbix監視対象から削除
    TOKEN=`curl -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`
    GET_JSON="{\"jsonrpc\": \"2.0\", 
           \"method\": \"host.get\", 
           \"params\": {
               \"filter\": {
                   \"host\": [\"$CONTAINER\"]
               }
           }, \"auth\": ${TOKEN}, \"id\": 1}"
    HOSTID=`curl -X GET -H "Content-Type:application/json-rpc" -d "${GET_JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq '.result[].hostid'`
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
    echo deleted hostid $HOSTID
}

echo start

docker events | zabbix_docker
