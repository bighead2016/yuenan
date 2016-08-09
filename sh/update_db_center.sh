#!/bin/bash
export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/mysql/bin:${PATH}"
## 更新数据脚本

SID=$1
SHELL_NAME=update_db_tool
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
PLATFORM_ID=`echo ${baseDir} | awk -F"/" '{print $4}' | awk -F"_" '{print $1}'`
IP=127.0.0.1
NODE_NAME=${SHELL_NAME}_${PLATFORM_ID}_${SID}@${IP}
CONFIG=../config/server_${SID}
MOD=misc_self_protect
FUNC=upgrate_db_center

erl +P 1024000 +t 100000 -smp auto -d -pa ../ebin -name ${NODE_NAME} -setcookie check_db -config ${CONFIG} -s ${MOD} ${FUNC} -noshell

