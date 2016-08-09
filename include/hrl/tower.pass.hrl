-record(rec_tower_pass, {
	pass_id, 	%<<"關卡id">>, 
	camp, 	%<<"所在大陣">>, 
	type, 	%<<"關卡類型">>, 
	lv, 	%<<"最低等級限制">>, 
	map, 	%<<"地圖">>, 
	monster_id, 	%<<"怪物id">>, 
	pre_pass, 	%<<"前置關卡">>, 
	rear_pass, 	%<<"後置關卡">>, 
	buff, 	%<<"屬性加成">>, 
	exp, 	%<<"經驗">>, 
	gold, 	%<<"銅錢">>, 
	award, 	%<<"掉落">>, 
	camp_reward, 	%<<"完成破陣獎勵">>, 
	partner_id, 	%<<"武將id">>, 
	pass_time, 	%<<"掃蕩通關時間(分鐘)">>, 
	standard_time 	%<<"標準通關時間(秒)">> 
}).

