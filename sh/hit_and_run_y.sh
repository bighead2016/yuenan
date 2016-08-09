erlc -I include/ src/misc/y.erl
erl +P 102400 -smp disable -s y start_link
