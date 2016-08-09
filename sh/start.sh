#!/bin/sh
#123
PLATFORM_ID=4399
SERVER_ID=1
GAME=sanguo
currentDir=$(pwd)
baseDir=$(cd $(dirname ${0})/.. && pwd && cd ${currentDir})
AGENT=`echo ${baseDir} | awk -F"/" '{print $5}' | awk -F"_" '{print $1}'`
ip=$(ifconfig | grep "inet addr" | awk '{print $2;}' | cut -f2 -d":"| head -n 1)
COOKIE=${GAME}
NODE_NAME=${GAME}_${AGENT}_${SERVER_ID}@${ip}
DIR_CONFIG_FILE=../config/server_${SERVER_ID}.config
SMP=auto
POLL=true
ERL_PROCESSES=1024000
cd  ./../ebin
	
ARGS=
while [ $# -ne 0 ] ; do
    PARAM=$1
    shift
    case $PARAM in
	-port) PORT=$1; shift ;;
        --) break ;;
        *) ARGS="$ARGS $PARAM" ;;
    esac
done


start()
{
    echo "--------------------------------------------------------------------"
    echo ""
    echo "Server将以后台进程模式启动,"
    echo ""
    echo "--------------------------------------------------------------------"
    echo "任意键继续"
    read foo
    	started
    	if [ $? = 1 ] ; then
		erl +P ${ERL_PROCESSES} \
			+t 2048576 \
			-smp ${SMP} \
			-pa ../ebin \
			-name ${NODE_NAME} \
			-setcookie ${COOKIE} \
			-boot start_sasl \
			-config ${DIR_CONFIG_FILE} -detached \
			-s server start
		sleep 4
		local DATETIME=`date "+%Y-%m-%d %H:%M:%S"` 
		echo "=($DATETIME)===================服务器启动完毕===================="
    	fi
}
#切入后台程序
debug()
{
    echo "--------------------------------------------------------------------"
    echo ""
    echo "重要提示: 我们将试图连接一个交互式的SHELL到一个已运行中的Server结点"
    echo "如果打印了任何错误，代表连接尝试失败了."
    echo "记住:退出请按 Ctrl + c"
    echo ""
    echo "--------------------------------------------------------------------"
    echo "任意键继续"
    read foo
	erl +P $ERL_PROCESSES \
		+K $POLL \
		-smp $SMP \
		-setcookie $COOKIE \
		-name debug_$NODE_NAME \
		-remsh $NODE_NAME \
		-hidden 
}
#交互模式
live()
{
    echo "--------------------------------------------------------------------"
    echo ""
    echo "重要提示: Server将会以交互式模式启动"
    echo "所有的消息都会被直接打印在终端上."
    echo ""
    echo "如果想退出该模式请输入 q()，然后回车"
    echo ""
    echo "--------------------------------------------------------------------"
    echo "任意键继续"
    read foo
    erl +P ${ERL_PROCESSES} \
    	+t 2048576 \
    	-smp ${SMP} \
    	-pa ../ebin \
    	-name ${NODE_NAME} \
    	-setcookie ${COOKIE} \
    	-boot start_sasl \
    	-config ${DIR_CONFIG_FILE} \
    	-s server start
}
#关闭服务
stop()
{
	PID=`ps awux | grep $NODE_NAME | grep -v "grep" | awk '{print $2}'`
	if [ "$PID" != '' ] ; then
		kill -9 $PID
		local DATETIME=`date "+%Y-%m-%d %H:%M:%S"` 
		echo "=($DATETIME)===================服务器已关闭===================="
		return 0
	else 
		return 1
	fi
}
started()
{
        local DATETIME=`date "+%Y-%m-%d %H:%M:%S"`
        PID=`ps awux | grep $NODE_NAME | grep -v "grep" | awk '{print $2}'`
        if [ "$PID" != '' ] ; then
                echo "=($DATETIME)===================服务器已启动===================="
                return 0
        else
                echo "=($DATETIME)===================服务器未启动===================="
                return 1
        fi
}
help()
{
    echo "--------------------------------------------------------------------"
    echo ""
    echo "Server管理命令:"
    echo " start  以正常服务器方式启动"
    echo " debug  以交互式命令行的方式连接到已有Server结点"
    echo " live  以交互方式启动服务器"
    echo " stop  关闭服务器"
    echo " started  查询服务器是否已启动"
    echo " hot_fix  热更所有服务器"
	echo ""
	echo "命令行参数，如: ./start.sh start"
    echo ""
    echo "--------------------------------------------------------------------"
}

hot_fix()
{
    echo "--------------------------------------------------------------------"
    echo "开始热更"
    echo "所有的消息都会被直接打印在终端上."
    echo "如果想退出该模式请输入 q()，然后回车"
    echo ""
    echo "--------------------------------------------------------------------"
    echo "任意键继续"
    read foo
    erl +P ${ERL_PROCESSES} \
        +t 2048576 \
        -smp ${SMP} \
        -pa ../ebin \
        -name jj@127.0.0.1 \
        -setcookie ${COOKIE} \
        -boot start_sasl \
        -config ${DIR_CONFIG_FILE} \
        -s hot_fix_server start
}

case $ARGS in
    ' start') start;;
    ' debug') debug;;
    ' live') live;;
    ' stop') stop;;
    ' hot_fix') hot_fix;;
    ' started') started;;
    *) help;;
esac
