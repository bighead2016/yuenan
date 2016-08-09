rem 生成新的Emakefile
erlc -I include/hrl -I include/  -o ebin src/misc/misc_sys.erl
cd ebin
erl -s misc_sys autoconfigure -noshell -noinput
pause