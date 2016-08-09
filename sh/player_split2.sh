#!/bin/sh
#
# The split command-line tool.
#
# Copyright (C) Cai Wenjian <caiwenjian@yahoo.com.cn>
#
# For the full copyright and license information, please view the LICENSE
# file that was distributed with this source code.

export PATH="/bin:/usr/bin:/sbin:/usr/sbin:/usr/local/mysql/bin:${PATH}"
# global settings
prog="split"
version="1.0"
currentDir=$(pwd)
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
confDir="${baseDir}/config"
ebinDir="${baseDir}/ebin"
logsDir="${baseDir}/logs"
shDir="${baseDir}/sh"
sqlDir="${baseDir}/sql_data"
tmpDir="/tmp" && mkdir -p ${tmpDir}
tmpFile="${tmpDir}/.tmpfile"

# others
generate_id() {
   _hours=$(date +%H)
   _minutes=$(date +%M)
   _secs=$(date +%S)
   _totalSecs=$(expr ${_hours} \* 3600 + ${_minutes} \* 60 + ${_secs})

   id=$(expr ${_totalSecs} / 1800 - 1)
   date1=$(date +%Y%m%d)
   date2=$(date +%Y-%m-%d)
   if (( ${id} < 0 )); then
     _timestamp=$(date "+%s")
     _timestamp=$(expr ${_timestamp} - 86400)

     id="47"
     date1=$(date -d "@${_timestamp}" +%Y%m%d)
     date2=$(date -d "@${_timestamp}" +%Y-%m-%d)
   fi

   id=$(printf "%03d" ${id})
}

# local settings
generate_id
originalDir="${logsDir}/player/${date1}"
originalFile="${originalDir}/log_player_${date2}_${id}.log"
targetDir="${logsDir}/player/web4399/${date1}" && mkdir -p "${targetDir}"
appConfig="
    PLAYER         1       playerlog_daily          人物
    BAG            2       baglog_daily             背包仓库
    BATTLE         3       battlelog_daily          战斗
    PARTNER        4       partnerlog_daily         武将
    MAP            5       maplog_daily             地图
    ACHIEV         6       achievlog_daily          成就
    HOME           7       homelog_daily            家园
    CHAT           8       chatlog_daily            聊天
    MAIL           9       maillog_daily            邮件
	CHESS		   10      chesslog_daily			双陆
    ABILITY        11      abilitylog_daily         内功阵法
    FURNACE        12      furnacelog_daily         作坊
    COPY           13      copylog_daily            副本
    FRIEND         14      friendlog_daily          好友
    GUILD          15      guildlog_daily           军团
    PRACTISE       16      practiselog_daily        修炼
    MARKET         17      marketlog_daily          拍卖/市场
    MALL           18      malllog_daily            商场
    GROUP          19      grouplog_daily           常规组队
    TASK           20      tasklog_daily            任务
    RESOURCE       21      resourcelog_daily        资源
    ARENA          22      arenalog_daily           个人竞技场
    MIND           24      mindlog_daily            祁天
	PATROL		   25      patrollog_daily			巡城	
    SKILL          26      skilllog_daily           技能
    HORSE          27      horselog_daily           坐骑
    SPRING         28      springlog_daily          温泉
    TOWER          29      towerlog_daily           闯塔/破阵
    COMM           30      commlog_daily            商路
    WELFARE        33      welfarelog_daily         福利
    BOSS           35      bosslog_daily            boss
    INVASION       36      invasionlog_daily        异民族
    SCHE           37      schelog_daily            课程表
    SIEGE          39      siegelog_daily           怪物攻城
	MCOPY		   41      mcopylog_daily			多人副本
    STRLEN         42      stren_daily              强化
	RANK		   45      ranklog_daily			排行榜
    DEPOSIT        91      depositlog_daily         充值
    CASH           92      coinslog_daily           元宝
    GOLD           93      coinslog_daily           铜钱
    GM             94      gmlog_daily              GM
    CAMPAIGN       95      campaignlog_daily        活动
    QUIT           96      quitlog_daily            退出时任务、场景
	BATTLESKILL   100 	   battlelog_daily			战斗技能统计
	BATTLEPARTNER 101      battlelog_daily			战斗武将统计
    BATTLECAMP    102	   battlelog_daily			出战阵型统计
	BATTLESTAT    103	   battlelog_daily          战斗统计
    BUFF           104     battlelog_daily          BUFF
	CAMPBATTLE	   105	   campbattlelog_daily	    阵营战
	RECONNECT	   124	   reconnectlog_daily		闪断重连
	LOGINCHECK	   125     loginchecklog_daily      登陆检测
    LOGIN          126     loginlog_daily           玩家登录
    LOGOUT         127     logoutlog_daily          玩家登出
    LVUP           128     lvuplog_daily            玩家升级
    GOODS          129     goodslog_daily           道具流水
    ROLECREATE     130     rolecreate_daily         创建角色
    TRAIN          131     trainlog_daily           培养
	SOUL           132	   soullog_daily            刻印
	ROBOT	   	   133     roubotlog_daily			机器人扣费
	MARKETGET	   140     marketlog_daily			市集下架
    OTHERS         .*      otherlog_daily           其它
"

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

initialize() {
  # tmpFile
  rm -rf ${tmpFile}

  # sid
  [[ -z "${sid}" ]] && echo -e "ERROR:\n    Expected argument '-s, --sid sid' be defined\n" && exit 1
}

main() {
  initialize

  # do it
  echo "${appConfig}" | while read line
  do
    [[ -z "${line}" ]] && continue

    tid=$(echo "${line}" | awk '{print $2}')
    suffix=$(echo "${line}" | awk '{print $3}')
    _targetFile="${targetDir}/web4399_s${sid}_${date1}_${suffix}_${id}"
    targetFile="${_targetFile}.txt"
    
    grep -E "^${tid}," ${originalFile} >> ${_targetFile}

    # delete the first column
    cut -d "," -f "2-" ${_targetFile} >> ${targetFile}
    [[ -f "${_targetFile}" ]] && rm -f ${_targetFile}
  done
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

