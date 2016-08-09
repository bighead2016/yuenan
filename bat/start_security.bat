set PLATFORM_ID=4399
set SERVER_ID=1
set GAME=sanguo
set COOKIE=%GAME%_security_%SERVER_ID%
set NODE_NAME=%COOKIE%@127.0.0.1
set SMP=auto
set ERL_PROCESSES=1024000

cd  ./../ebin
werl +P %ERL_PROCESSES% +t 100000 -smp %SMP% -d -pa ../ebin -name %NODE_NAME% -setcookie %COOKIE% -boot start_sasl -s security start