set PLATFORM_ID=4399
set SERVER_ID=1
set GAME=sanguo
set COOKIE=%GAME%
set NODE_NAME=%COOKIE%@127.0.0.1
set DIR_CONFIG_FILE=../config/server_%SERVER_ID%
set SMP=auto
set ERL_PROCESSES=1024000

cd  ./../ebin
erl +P %ERL_PROCESSES% +t 2048576 -smp %SMP% -d -pa ../ebin -name test@127.0.0.1 -setcookie %COOKIE% -boot start_sasl -noshell -noinput -config %DIR_CONFIG_FILE% -s server stop_i sanguo_4399_1@127.0.0.1
pause
exit