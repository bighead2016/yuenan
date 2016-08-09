#!/bin/sh
# 日志分割   ERLANG的日志是单个文件 需要本脚本进行分割，CRONTAB每天凌晨处理
# 59 23 * * *  /app/wwsg_server/sh/player_split.sh > /app/wwsg_server/sh/sh.log 2>&1

SERVID=0
ROOT=/app/wwsg_server/logs/player
DATE=`date +%Y%02m%02d`
DATE2=`date +%Y-%-02m-%-02d`
FILE=log_player_${DATE2}.log

PLAYER=1	#人物
BAG=2		#背包仓库
BATTLE=3	#战斗
PARTNER=4	#武将
MAP=5		#地图
ACHIEV=6	#成就
HOME=7		#家园
CHAT=8		#聊天
MAIL=9		#邮件
CHESS=10	#双陆
ABILITY=11	#内功阵法
FURNACE=12	#作坊
COPY=13		#副本
FRIEND=14	#好友
GUILD=15	#军团
PRACTISE=16	#修炼
MARKET=17	#拍卖/市场
MALL=18		#商场			*
GROUP=19	#常规组队
TASK=20		#任务			*
RESOURCE=21	#资源
ARENA=22	#个人竞技场
MIND=24		#祁天
PATROL=25   #巡城
SKILL=26	#技能
HORSE=27	#坐骑
SPRING=28	#温泉
TOWER=29	#闯塔/破阵
COMM=30		#商路
WELFARE=33	#福利
BOSS=35		#boss
INVASION=36	#异民族
SCHE=37		#课程表
SIEGE=39	#怪物攻城
MCOPY=41    #多人副本
STREN=42	#强化
RANK=45		#排行榜
DEPOSIT=91	#充值			*
CASH=92		#元宝			*
GOLD=93		#铜钱			*
GM=94		#GM
CAMPAIGN=95	#活动
QUIT=96		#退出时任务、场景
BATTLESKILL=100 	#战斗技能统计
BATTLEPARTNER=101  #战斗武将统计
BATTLECAMP=102		#出战阵型统计
BATTLESTAT=103		#战斗统计
BUFF=104			#BUFF
CAMPBATTLE=105		#阵营战
RECONNECT=124		#闪断重连
LOGINCHECK=125      #登陆校验
LOGIN=126	#玩家登录		*
LOGOUT=127	#玩家登出	
LVUP=128	#玩家升级
GOODS=129	#道具流水		*
ROLECREATE=130	#创建角色		*
TRAIN=131 #培养		
SOUL=132	#刻印
ROBOT=133   #机器人扣费
MARKETGET=140 #市集下架

cd $ROOT
mkdir -p web4399
mkdir -p web4399/${DATE}

sleep 120

while read LINE
do
	ID=`echo $LINE|awk -F ',' '{print $1}'`
	case $ID in
	$PLAYER)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_playerlog_daily.txt"
		;;
	$BAG)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_baglog_daily.txt"
		;;
	$BATTLE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_battlelog_daily.txt"
		;;
	$PARTNER)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_partnerlog_daily.txt"
		;;
	$MAP)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_maplog_daily.txt"
		;;
	$ACHIEV)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_achievlog_daily.txt"
		;;
	$HOME)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_homelog_daily.txt"
		;;
	$CHAT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}' >> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_chatlog_daily.txt"
		;;
	$MAIL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}' >> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_maillog_daily.txt"
		;;
	$CHESS)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}' >> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_chesslog_daily.txt"
		;;
	$ABILITY)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_abilitylog_daily.txt"
		;;
	$FURNACE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_furnacelog_daily.txt"
		;;
	$COPY)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_copylog_daily.txt"
		;;
	$FRIEND)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_friendlog_daily.txt"
		;;
	$GUILD)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_guildlog_daily.txt"
		;;
	$PRACTISE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_practiselog_daily.txt"
		;;
	$MARKET)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_marketlog_daily.txt"
		;;
	$MALL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_malllog_daily.txt"
		;;
	$GROUP)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_grouplog_daily.txt"
		;;
	$TASK)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}' >> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_tasklog_daily.txt"
		;;
	$RESOURCE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_resourcelog_daily.txt"
		;;
	$ARENA)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_arenalog_daily.txt"
		;;
	$MIND)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_mindlog_daily.txt"
		;;
	$PATROL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_patrollog_daily.txt"
		;;	
	$SKILL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_skilllog_daily.txt"
		;;
	$HORSE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_horselog_daily.txt"
		;;
	$SPRING)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_springlog_daily.txt"
		;;
	$TOWER)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_towerlog_daily.txt"
		;;
	$COMM)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_commlog_daily.txt"
		;;
	$WELFARE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_welfarelog_daily.txt"
		;;
	$BOSS)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_bosslog_daily.txt"
		;;
	$INVASION)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_invasionlog_daily.txt"
		;;
	$SCHE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_schelog_daily.txt"
		;;
	$SIEGE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_siegelog_daily.txt"
		;;
	$MCOPY)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_mcopylog_daily.txt"
		;;	
	$RANK)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_ranklog_daily.txt"
		;;
	$DEPOSIT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_depositlog_daily.txt"
		;;
	$CASH)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_coinslog_daily.txt"
		;;
	$GM)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_gmlog_daily.txt"
		;;
	$CAMPAIGN)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_campaignlog_daily.txt"
		;;	
	$QUIT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_quitlog_daily.txt"
		;;	
	$BATTLESKILL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_battlelog_daily.txt"
		;;
	$BATTLEPARTNER)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_battlelog_daily.txt"
		;;
	$BATTLECAMP)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_battlelog_daily.txt"
		;;
	$BATTLESTAT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_battlelog_daily.txt"
		;;
	$CAMPBATTLE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_campbattlelog_daily.txt"
		;;
	$RECONNECT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_reconnectlog_daily.txt"
		;;
	$LOGINCHECK)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_loginchecklog_daily.txt"
		;;	
	$LOGIN)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_loginlog_daily.txt"
		;;
	$LOGOUT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_logoutlog_daily.txt"
		;;
	$LVUP)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_lvuplog_daily.txt"
		;;
	$GOODS)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_goodslog_daily.txt"
		;;	
	$ROLECREATE)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_rolecreate_daily.txt"
		;;
	$TRAINS)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_trainlog_daily.txt"
		;;	
	$SOUL)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_trainlog_daily.txt"
		;;	
	$ROBOT)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_robotlog_daily.txt"
		;;
	$MARKETGET)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_marketlog_daily.txt"
		;;
	*)
		echo $LINE | awk '{sub(/[^,]*,/,"");print}'>> "web4399/${DATE}/web4399_s${SERVID}_${DATE}_soullog_daily.txt"
		;;
	esac
done < $FILE
