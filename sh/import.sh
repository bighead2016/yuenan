#!/bin/sh
#
# The MySQL import command-line tool.
#
# Copyright (C) Cai Wenjian <caiwenjian@yahoo.com.cn>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/mysql/bin:${PATH}"

# global settings
prog="import"
version="1.0"
currentDir=$(pwd)
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
confDir="${baseDir}/config"
ebinDir="${baseDir}/ebin"
shDir="${baseDir}/sh"
sqlDir="${baseDir}/sql_data"
tmpDir="/tmp" && mkdir -p ${tmpDir}
tmpFile="${tmpDir}/.tmpfile"

# local settings
# misc
subject="威武三国"
tasks="导入游戏数据库 导入游戏数据库更改 导入游戏数据库配置"

# database
_dbName="wwsg"
_dbHost="localhost"
_dbPort=""
_dbUser="wwsg"
_dbPassword="123456"
_dbCfg=""

# include core functions
source ${shDir}/functions

# local functions
usage() {
  echo "使用方法："
  echo "  ${prog} [options]"
  echo ""
  echo "可用选项："
  echo "  -s, --sid sid               指定服务标识符"
  echo "  --all-files                 包含指定目录下的所有文件"
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

db_exists() {
  # you must pre-define the following variables: dbCfg, dbHost, dbPort, dbUser and dbPassword
  local totalArgs="${#}"
  (( ${totalArgs} != 1 )) && throw -m "Expected 1 argument be defined" -f "${FUNCNAME}"

  # get all databases
  local dbs=$(mysql ${dbCfg} ${dbHost} ${dbPort} ${dbUser} ${dbPassword} -e "show databases" 2>${tmpFile})
  local errMsg=$(cat ${tmpFile} | sed -n '$p')
  isset "${errMsg}" && throw -m "${errMsg}" -f "${FUNCNAME}"

  # check database
  dbs=$(echo "${dbs}" | sed '1d' | awk '{printf "%s,",$1}' | sed -r -e 's/,+/,/g' -e 's/^,|,$//g' -e 's/,/ /g')
  for db in ${dbs}
  do
    [[ "${db}" == "${1}" ]] && return 0
  done

  return 1
}

db_create() {
  # you must pre-define the following variables: dbCfg, dbHost, dbPort, dbUser and dbPassword
  local totalArgs="${#}"
  (( ${totalArgs} != 1 )) && throw -m "Expected 1 argument be defined" -f "${FUNCNAME}"

  # check database
  mysqladmin ${dbCfg} ${dbHost} ${dbPort} ${dbUser} ${dbPassword} create ${1} > /dev/null 2>${tmpFile}
  local errMsg=$(cat ${tmpFile} | sed -n '$p')
  isset "${errMsg}" && throw -m "${errMsg}" -f "${FUNCNAME}"
}

db_import() {
  # you must pre-define the following variables: dbName, dbCfg, dbHost, dbPort, dbUser and dbPassword
  local totalArgs="${#}"
  (( ${totalArgs} != 1 )) && throw -m "Expected 1 argument be defined" -f "${FUNCNAME}"

  if [[ -f "${1}" ]]; then
    echo "  + 导入MySQL脚本文件'${1}'..."
    is_sql_valid "${1}" || throw -m "MySQL脚本文件'${1}'包含非法语句" -f "${FUNCNAME}"
    mysql ${dbCfg} ${dbHost} ${dbPort} ${dbUser} ${dbPassword} ${dbName} < ${1} 2>${tmpFile}
    local errMsg=$(cat ${tmpFile} | sed -n '$p')
    isset "${errMsg}" && throw -m "${errMsg}" -f "${FUNCNAME}" || return 0
  elif [[ -d "${1}" ]]; then
    local files=$(find "${1}" -name "*.sql" | sort -n | awk '{printf "%s ", $1}')
    isset "${files}" || return 0

    if [[ -z "${allFilesFlag}" ]]; then
      echo "请从以下列表中，选择您要导入的文件："
      select file in "所有文件" ${files}
      do
        case "${file}" in
          "所有文件") 
               # all files
               for file in ${files}
               do
                 db_import "${file}"
               done

               break;;
          *) 
              # one file
              if [[ -f "${file}" ]]; then
                db_import "${file}"
                while true
                do
                  printf "是否继续？[yes/no] "
                  read answer
                  [[ "${answer}" == "yes" || "${answer}" == "no" ]] && break
                  continue
                done
              
                [[ "${answer}" == "yes" ]] && continue || break
              else
                continue
              fi
        esac
      done
    else
      # all files
      for file in ${files}
      do
        db_import "${file}"
      done
    fi
  fi
}

is_sql_valid() {
  local totalArgs="${#}"
  (( ${totalArgs} != 1 )) && throw -m "Expected 1 argument be defined" -f "${FUNCNAME}"

  is_file "${1}" || throw -m "The file '${1}' does not exist" -f "${FUNCNAME}"

  local value=$(grep -E -i "(drop\s+database|create\s+database|use\s+)" "${1}")
  isset "${value}" && return 1 || return 0
}

import_db() {
  # you must pre-define the following variables: dbName, dbCfg, dbHost, dbPort, dbUser and dbPassword
  # log event
  echo "导入游戏数据库..."

  # create database
  db_exists "${dbName}" && throw -m "导入游戏数据库失败，游戏数据库'${dbName}'已存在" -f "${FUNCNAME}" || db_create "${dbName}"

  # import
  local file="${sqlDir}/sg_server.sql"
  db_import "${file}"

  import_db_alter
  import_db_cfg
}

import_db_alter() {
  # you must pre-define the following variables: dbName, dbCfg, dbHost, dbPort, dbUser and dbPassword
  # log event
  echo "导入游戏数据库更改..."

  # check database
  db_exists "${dbName}" || throw -m "导入游戏数据库更改失败，游戏数据库'${dbName}'不存在" -f "${FUNCNAME}"

  # set variables
  local file="${sqlDir}/alter"
  db_import "${file}"
}

import_db_cfg() {
  # you must pre-define the following variables: dbName, dbCfg, dbHost, dbPort, dbUser and dbPassword
  # log event
  echo "导入游戏数据库配置..."

  # check database
  db_exists "${dbName}" || throw -m "导入游戏数据库更改失败，游戏数据库'${dbName}'不存在" -f "${FUNCNAME}" 

  # import cfg
  local file="${sqlDir}/techcenter_dict.sql"
  db_import "${file}"
}

initialize() {
  # tmpFile
  isset "${tmpFile}" && rm -rf ${tmpFile}

  # sid
  isset "${sid}" || throw -m "您必须指定服务标识符。服务标识符必须是非负整数，且大于等于0" -f "${FUNCNAME}"
  #is_integer "${sid}" && (( ${sid} >= 0 )) || throw -m "服务标识符必须是非负整数，且大于等于0" -f "${FUNCNAME}"

  # dbName
  isset "${_dbName}" || throw -m "您必须指定数据库基名称。数据库基名称将作为数据库名称的前缀" -f "${FUNCNAME}"
  is_integer "${sid}" && dbName="${_dbName}_s${sid}" || dbName="${_dbName}_${sid}"

  # dbHost, dbPort, dbUser, dbPassword and dbCfg
  isset "${_dbHost}" && dbHost="--host=${_dbHost}"
  isset "${_dbPort}" && dbPort="--port=${_dbPort}"
  isset "${_dbUser}" && dbUser="--user=${_dbUser}"
  isset "${_dbPassword}" && dbPassword="--password=${_dbPassword}"
  isset "${_dbCfg}" && dbCfg="--defaults-file=${_dbCfg}"
}

main() {
  # initialize
  log "信息：执行导入程序..."
  initialize

  # do it
  log "信息：处理'${subject}' - ${sid}服，游戏数据库'${dbName}'..."
  echo "请从以下列表中，选择您要执行的任务："
  select task in ${tasks}
  do
    case "${task}" in
      "导入游戏数据库") import_db "${dbName}"; break;;
      "导入游戏数据库更改") import_db_alter "${dbName}"; break;;
      "导入游戏数据库配置") import_db_cfg "${dbName}"; break;;
      *) continue;;
    esac
  done

  log "信息：导入程序执行成功!"
}

# get opts
opts=$(getopt -q -o s: -l sid:,all-files,help,version -- "${@}")
(( ${?} != 0 )) && usage && exit 1
eval set -- "${opts}"
while true
do
  [[ -z "${1}" ]] && break
  case "${1}" in
    -s|--sid) sid="${2}"; shift 2;;
    --all-files) allFilesFlag="yes"; shift;;
    --help) usage; exit 0;;
    --version) version; exit 0;;
    --) shift;;
    *) usage && exit 1;;
  esac
done

main

