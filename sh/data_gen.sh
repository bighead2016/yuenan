erlc -I ../include/hrl -I ../include  ../src/misc/data_machine.erl

erl +P 102400 -smp auto -s data_machine main -noinput -noshell

rm -rf *.beam
rm -rf erl_crash.dump

