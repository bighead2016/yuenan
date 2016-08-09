cd ../
erlc -I include/hrl -Iinclude/ src/misc/misc_sys.erl
erlc -I include/hrl -Iinclude/ src/misc/misc.erl
copy /y misc_sys.beam ebin
copy /y misc.beam ebin
del /q misc.beam misc_sys.beam
cd  ebin
erl -s misc_sys generate_introduction -noshell -noinput
pause