set PLATFORM_ID=4399
set GAME=sanguo
set COOKIE=%GAME%
set NODE_NAME=sanguo_manage_xxx@sanguo.hyy.com
set DIR_CONFIG_FILE=../config/server_manage
set SMP=auto
set ERL_PROCESSES=1024000

dir ..\ebin |find "sanguo_manage.app"
IF %ERRORLEVEL% neq 0 (copy ..\app\sanguo_manage.app ..\ebin && echo 1) else (echo 0)
erl -d -pa ../ebin +P %ERL_PROCESSES% +t 100000 -smp %SMP% -d -pa ebin -name %NODE_NAME% -setcookie %COOKIE% -config %DIR_CONFIG_FILE% -s manage_app start
pause