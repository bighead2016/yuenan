
cd ../data/zh_CN
erlc -I../../include ../../src/mod_data_trans/xlsx2yrl_mochi.erl
erlc -I../../include ../../src/mod_data_trans/xlsx_tools.erl
erlc -I../../include ../../src/mod_data_trans/yrl_tools.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_m_serv.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_w_serv.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_app.erl
erlc -I../../include ../../src/mod_data_trans/mochiweb_html.erl

erl +P 1024000 -smp auto -name tools@127.0.0.1 -s data_trans_app start

cd ../../data/zh_TW
erlc -I../../include ../../src/mod_data_trans/xlsx2yrl_mochi.erl
erlc -I../../include ../../src/mod_data_trans/xlsx_tools.erl
erlc -I../../include ../../src/mod_data_trans/yrl_tools.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_m_serv.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_w_serv.erl
erlc -I../../include ../../src/mod_data_trans/data_trans_app.erl
erlc -I../../include ../../src/mod_data_trans/mochiweb_html.erl

erl +P 1024000 -smp auto -name tools@127.0.0.1 -s data_trans_app start
echo "ok"

