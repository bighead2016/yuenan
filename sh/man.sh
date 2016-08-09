#!/bin/bash
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/mysql/bin:${PATH}"
ip=$(ifconfig | grep "inet addr" | awk '{print $2;}' | cut -f2 -d":"| head -n 1)
GAME=sanguo
COOKIE=${GAME}
NODE_NAME=sanguo_manage_xxx
DIR_CONFIG_FILE=../config/server_manage

erl -pa ./../ebin +P 1024000 +t 100000 -hidden -smp auto -name ${NODE_NAME}@${ip} -detached -setcookie sanguo -kernel inet_dist_listen_min 10000 -kernel inet_dist_listen_max 20000 -config $DIR_CONFIG_FILE -s manage_app start   
