-record(rec_mcopy, {
	id, 	%<<"副本id">>, 
	name, 	%<<"副本名">>, 
	map, 	%<<"地圖">>, 
	monster_1, 	%<<"怪物1">>, 
	monster_2, 	%<<"怪物2">>, 
	monster_3, 	%<<"怪物3">>, 
	q_id, 	%<<"奇遇id">>, 
	is_tick, 	%<<"是否有機關">>, 
	skip_1, 	%<<"跳轉點1">>, 
	skip_2, 	%<<"跳轉點2">>, 
	goods, 	%<<"副本獎勵道具">>, 
	exp, 	%<<"副本經驗">>, 
	gold_bind, 	%<<"副本綁定銅錢">>, 
	meritorious, 	%<<"副本功勳">>, 
	condition, 	%<<"奇遇跳轉點[{wave,Type,id}]">>, 
	serial_id, 	%<<"所屬副本系列id">>, 
	flag1 	%<<"扣次數標誌">> 
}).

