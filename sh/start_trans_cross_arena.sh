#!/bin/bash

## 更新数据脚本

COOKIE=sanguo
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
PLATFORM_ID=`echo ${baseDir} | awk -F"/" '{print $4}' | awk -F"_" '{print $1}'`
IP=127.0.0.1
CONFIG=../config/server_center
MOD=trans_cross_arena
FUNC=change_player_data
NODE_NAME=${COOKIE}_${PLATFORM_ID}_center@${IP}

erl +P 1024000 +t 100000 -smp auto -d -pa ../ebin -name test11_${PLATFORM_ID}_center@127.0.0.1 -setcookie sanguo -config ${CONFIG} -s ${MOD} ${FUNC} -noshell