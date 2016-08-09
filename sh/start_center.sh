#!/bin/bash
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/mysql/bin:${PATH}"
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
serv_name=`echo ${baseDir} | awk -F"/" '{print $5}'`
ip=$(ifconfig | grep "inet addr" | awk '{print $2;}' | cut -f2 -d":"| head -n 1)
PLATFORM_ID=`echo ${serv_name} | awk -F"_" '{print $1}'`

GAME=sanguo
COOKIE=${GAME}
NODE_NAME=${COOKIE}_${PLATFORM_ID}_center
DIR_CONFIG_FILE=../config/server_center

erl -pa ./../ebin -name ${NODE_NAME}@${ip} -hidden -detached -setcookie sanguo -kernel inet_dist_listen_min 10000 -kernel inet_dist_listen_max 12000 -config $DIR_CONFIG_FILE -s center_app start   
