#!/bin/bash
echo "=============server"
ps -ef|grep beam|grep -v 'xllogger_1@127.0.0.1'|grep -v 'stop'|grep -v 'center'|grep -v grep|awk '{print $27"\t"$2}'|sort|grep -v sasl
echo "=============center"
ps -ef|grep beam|grep center|grep -v grep|awk '{print $21"\t"$2}'
echo "=============logger"
ps -ef|grep beam|grep 'xllogger_1@127.0.0.1'|grep -v grep|awk '{print $24"\t"$2}'
echo "=============stop"
ps -ef|grep beam|grep 'stop'|grep -v grep|awk '{print $28"\t"$2}'
