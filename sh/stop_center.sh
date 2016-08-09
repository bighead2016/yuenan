#!/bin/bash
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/mysql/bin:${PATH}"
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
serv_name=`echo ${baseDir} | awk -F"/" '{print $5}'`
ip=$(ifconfig | grep "inet addr" | awk '{print $2;}' | cut -f2 -d":"| head -n 1)
PLATFORM_ID=`echo ${serv_name} | awk -F"_" '{print $1}'`
SHELL_NAME=stop_center
GAME=sanguo
COOKIE=${GAME}
NODE_NAME=${SHELL_NAME}_${COOKIE}_${PLATFORM_ID}_center
CENTER_NODE=${COOKIE}_${PLATFORM_ID}_center
DIR_CONFIG_FILE=../config/server_center

cd  ./../ebin
erl -pa . -name ${NODE_NAME}@${ip} -setcookie $COOKIE  -config $DIR_CONFIG_FILE -s  center_api stop_center ${CENTER_NODE}@${ip} -noshell
