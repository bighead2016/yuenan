set PLATFORM_ID=4399
set SERVER_ID=1
set GAME=sanguo
set COOKIE=%GAME%_%SERVER_ID%
set NODE_NAME=%COOKIE%@127.0.0.1
set DIR_CONFIG_FILE=../config/server_%SERVER_ID%
set SMP=auto
set ERL_PROCESSES=1024000
pause
cd  ./../ebin
erl +P %ERL_PROCESSES% +t 2048576 -smp %SMP% -pa ebin -name %NODE_NAME% -setcookie %COOKIE%  -config %DIR_CONFIG_FILE% -s trans_name start
pause
exit