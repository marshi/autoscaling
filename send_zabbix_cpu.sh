#!/bin/sh

# ./send_zabbix_cpu.sh -k zabbix_item_key
#
# zabbixサーバから起動IPに属するホスト一覧を取得し、そのホスト上で起動しているdockerのcpu使用率をsend_zabbix APIを使ってzabbixサーバに送る.
#

usage() {
  echo "usage: ex. send_zabbix_cpu.sh -k docker_cpu [-c \"libvirt\" or \"docker\"]" 
}

CONTAINER_TYPE="docker"
while getopts c:k: OPT; do
  case $OPT in
    k) 
      KEY=$OPTARG
      ;;
    c)
      if [ $OPTARG = "libvirt" ]; then
        CONTAINER_TYPE="libvirt"
      fi
      ;;
    \?)
      usage
      exit 1;
      ;;
  esac
done

shift $((OPTIND - 1))

if [ x$KEY = x ]; then
  usage
  exit 1;
fi

if [ ! $# -eq 0 ]; then
  usage
  exit 1;
fi

SERVER_IP=${ZABBIX_SERVER_IP}
if [ -z ${SERVER_IP} ]; then
  echo "please set ZABBIX_SERVER_IP"
  exit 1
fi

IP=`ifconfig eth0|grep inet|awk '{print $2}'|cut -d: -f2`

TOKEN=`curl -s -X GET -H "Content-Type:application/json-rpc" -d '{"auth":null,"method":"user.login","id":1,"params":{"user":"admin","password":"zabbix"},"jsonrpc":"2.0"}' http://${SERVER_IP}/zabbix/api_jsonrpc.php | jq ".result"`  

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

HOSTS=`curl -s -X GET -H "Content-Type:application/json-rpc" -d "${JSON}" http://${SERVER_IP}/zabbix/api_jsonrpc.php |  jq ".result[].host"`
for host in $HOSTS; do
  host=`echo $host | sed 's/\"//g'`
  cpu=`sh cpu.sh -c $CONTAINER_TYPE $host`
  if [ ! $? -eq 0 ]; then
    continue
  fi
  echo $cpu
  zabbix_sender -z ${SERVER_IP} -p 10051 -s "${host}" -k $KEY -o "${cpu}" > /dev/null
done
