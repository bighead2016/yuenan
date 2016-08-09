erlc -I../include ../src/misc/misc.erl
erlc -I../include ../src/data/data_goods.erl
erlc -I../include ../src/data/data_mind.erl
erlc -I../include ../src/data/data_partner.erl
erlc -I../include ../src/misc/banana.erl

rem erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../logs/player/20130725/log_player_2013-07-25_022.txt" > 1.log
erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../sh/x.log" -ttt goods > a1.log
erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../sh/x.log" -ttt mind > a2.log
erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../sh/x.log" -ttt cost > a3.log
erl +P 1024000 -smp disable -name tools@127.0.0.1 -noshell -s banana read_debug -dbg_file "../sh/x.log" -ttt partner > a4.log
del *.beam *.dump
pause