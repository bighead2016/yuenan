@echo off
erl +P 1024000 +t 100000 -smp auto -d -pa ../ebin -name update_db_tool@127.0.0.1 -setcookie update_db_tool -config ../config/server_1 -s misc_self_protect upgrate_db -noshell
pause
