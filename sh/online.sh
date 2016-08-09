#!/bin/sh
loop=360000
servid=1
until [ $loop -eq 0 ] 
do
	pid=`ps -ef|grep beam|grep -v grep|grep server_$servid|awk '{print $2}'`
	now=`date|awk '{print $4}'`
	online=`netstat -anlp|grep tcp|grep 6443|grep ESTABLISHED|awk '{print $5}'|awk -F: '{print $1}'|wc -l`
	cpu=`top -b -p $pid -n 1|grep beam|grep $pid|awk '{print $9}'`
	cpu2=`uptime | awk '{print $NF}'`
	mem=`top -b -p $pid -n 1|grep beam|grep $pid|awk '{print $10}'`
	echo $now "------pid" $pid "------online num" $online "-----cpu" $cpu2 "-----memory" $mem
	echo $now "------pid" $pid "------online num" $online "-----cpu" $cpu2 "-----memory" $mem >> online.log
	loop=`expr $loop - 1`
	sleep 1
done
