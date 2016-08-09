#!/bin/sh
#统计在线人数 记录到mysql:   techcenter_online 依赖于绑定端口统计
#    */5 * * * *  sh /app/wwsg_server/sh/log_online.sh > /tmp/test.txt 2>&1

DB=wwsg_s0
USER=wwsg
PASSWD=wwsgs2a0n1g2o
TABLE=techcenter_online
PORT=6443
TIME=`date +%s`
NUM=`netstat -anlp|grep tcp|grep ${PORT}|grep ESTABLISHED|awk '{print $5}'|awk -F: '{print $1}'|wc -l`

#mysql -u$USER -p$PASSWD -D$DB -e "INSERT INTO log_scene_online VALUES($TIME,$NUM);" 
/usr/local/bin/mysql -u$USER -p$PASSWD -D$DB -e "INSERT INTO ${TABLE} VALUES($TIME,$NUM);" 
