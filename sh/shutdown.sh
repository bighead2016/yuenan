#!/bin/sh
#
# The MySQL import command-line tool.
#
# Copyright (C) Cai Wenjian <caiwenjian@yahoo.com.cn>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/bin:/usr/local/mysql/bin:${PATH}"

# global settings
prog="shutdown"
version="1.0"
currentDir=$(pwd)
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
confDir="${baseDir}/config"
ebinDir="${baseDir}/ebin"
shDir="${baseDir}/sh"
sqlDir="${baseDir}/sql_data"
tmpDir="/tmp" && mkdir -p ${tmpDir}
tmpFile="${tmpDir}/.tmpfile"
serv_name=`echo ${baseDir} | awk -F"/" '{print $4}'`
serv_id=`echo ${serv_name} | sed 's/_s/_/'`
ip=$(ifconfig | grep "inet addr" | awk '{print $2;}' | cut -f2 -d":"| head -n 1)
NodeName=sanguo_${serv_id}@${ip}
# local settings
subject="威武三国"

# include core functions
source ${shDir}/functions

# local functions
usage() {
  echo "使用方法："
  echo "  ${prog} [options]"
  echo ""
  echo "可用选项："
  echo "  -s, --sid sid               指定服务标识符"
  echo "  --help                      显示帮助信息"
  echo "  --version                   显示版本信息"
  echo ""
}

version() {
  echo "${prog} ${version}"
  echo "Copyright (C) Cai Wenjian <caiwenjian@yahoo.com.cn>"
  echo "License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>."
  echo "This is free software, you are free to change and redistribute it."
  echo "There is NO WARRANTY, to the extent permitted by law."
  echo ""
  echo "Written by Cai Wenjian."
  echo ""
}

is_process_alive() {
  local totalArgs="${#}"
  (( ${totalArgs} != 1 )) && throw -m "您必须指定服务标识符。服务标识符必须是非负整数，且大于等于0" -f "${FUNCNAME}"

  local flag=$(ps -ef | grep -v "grep" | grep "${nodeName}")
  isset "${flag}" && return 0 || return 1
}

stop() {
  cd ${shDir}

  # pre-check
  is_process_alive "${sid}" || return 0

  erl +P 1024000 \
      +t 10485760 \
      -smp auto \
      -d \
      -pa ../ebin \
      -name stop_${serv_id}@${ip} \
      -setcookie ${cookie} \
      -noshell \
      -noinput \
      -config ${configFile} \
      -s server stop_i ${nodeName}

  # waiting 5 secs
  sleep 5
  
  is_process_alive "${sid}" && do_kill "${sid}"
  is_process_alive "${sid}" && throw -m "关闭服务器失败" -f "${FUNCNAME}"
}

do_kill() {
  local flag=$(ps -ef | grep -v "grep" | grep "${NodeName}"|awk '{print $2}')
}

initialize() {
  # tmpFile
  isset "${tmpFile}" && rm -rf ${tmpFile}

  # sid
  isset "${sid}" || throw -m "您必须指定服务标识符。服务标识符必须是非负整数，且大于等于0" -f "${FUNCNAME}"
  is_integer "${sid}" && (( ${sid} >= 0 )) || throw -m "服务标识符必须是非负整数，且大于等于0" -f "${FUNCNAME}"

  # set variables
  name="sanguo"
  platform=`echo ${baseDir} | awk -F"/" '{print $4}' | awk -F"_" '{print $1}'`
  cookie="${name}"
  nodeName="${name}_${platform}_${sid}@${ip}"
  configFile="${confDir}/server_${sid}.config"
  is_file "${configFile}" || throw -m "文件'${configFile}'不存在" -f "${FUNCNAME}"
}

main() {
  # initialize
  log "信息：执行关闭程序..."
  initialize

  log "信息：处理'${subject}' - ${sid}服..."
  stop
  
  # log event
  log "信息：关闭程序执行成功!"
}

# get opts
opts=$(getopt -q -o s: -l sid:,help,version -- "${@}")
(( ${?} != 0 )) && usage && exit 1
eval set -- "${opts}"
while true
do
  [[ -z "${1}" ]] && break
  case "${1}" in
    -s|--sid) sid="${2}"; shift 2;;
    --help) usage; exit 0;;
    --version) version; exit 0;;
    --) shift;;
    *) usage && exit 1;;
  esac
done

main

