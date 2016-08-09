cd ../ebin
rm -rf *.beam
cd ../sh
./autoconfigure.sh
cd ../..
erl -make
echo "done.-,-"
