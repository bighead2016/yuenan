set PLATFORM_ID=4399
set SERVER_ID=16
set GAME=sanguo
set COOKIE=%GAME%
set NODE_NAME=%GAME%_%PLATFORM_ID%_%SERVER_ID%@127.0.0.1
set DIR_CONFIG_FILE=../config/server_2
set SMP=auto
set ERL_PROCESSES=1024000

cd  ./../ebin
erl +P %ERL_PROCESSES% +t 100000 -smp %SMP% -d -pa ebin -name %NODE_NAME% -setcookie %COOKIE%  -config %DIR_CONFIG_FILE% -s server start
pause
