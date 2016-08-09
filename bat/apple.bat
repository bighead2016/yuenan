erlc -I../include ../src/misc/misc.erl
erlc -I../include ../src/data/data_skill.erl
erlc -I../include ../src/data/data_buff.erl
erlc -I../include ../src/misc/apple.erl

rem erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../logs/player/20130725/log_player_2013-07-25_022.txt" > 1.log
erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s apple read_debug -battle_file "../sh/x.log" -ttt goo > 1.log
del *.beam *.dump
pause