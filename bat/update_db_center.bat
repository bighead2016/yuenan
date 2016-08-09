@echo off
erl +P 1024000 +t 100000 -smp auto -d -pa ../ebin -name update_db_center@127.0.0.1 -setcookie update_db -config ../config/server_center -s misc_self_protect upgrate_db_center -noshell
pause
