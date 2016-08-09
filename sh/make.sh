#!/bin/sh
cd ../
rm ebin/*.beam -rf
erlc src/misc/mmake.erl
begin=`date|awk '{print $4}'`
erl -eval "mmake:all(32)"
end=`date|awk '{print $4}'`
echo "begin" $begin "end" "$end"
rm *.beam -rf
