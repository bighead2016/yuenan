set PLATFORM_ID=4399
set GAME=sanguo
set COOKIE=%GAME%
set NODE_NAME=%GAME%_4399_center@127.0.0.1
set DIR_CONFIG_FILE=../config/server_center
set SMP=auto
set ERL_PROCESSES=1024000

cd  ./../ebin
werl +P %ERL_PROCESSES% +t 100000 -smp %SMP% -d -pa ebin -name %NODE_NAME% -setcookie %COOKIE% -config %DIR_CONFIG_FILE% -s center_app start
pause