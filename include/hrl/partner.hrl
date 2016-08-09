-record(rec_partner, {
	partner_id, 	%<<"武將id">>, 
	partner_name, 	%<<"武將名字">>, 
	type, 	%<<"類型（1劇情，2破陣，3尋訪，4商店）">>, 
	pro, 	%<<"職業">>, 
	sex, 	%<<"性別">>, 
	active_skill, 	%<<"技能">>, 
	genius_skill, 	%<<"被動技能">>, 
	normal_skill, 	%<<"普攻技能id">>, 
	gold, 	%<<"銅錢">>, 
	color, 	%<<"品質">>, 
	rate, 	%<<"成長係數">>, 
	need_goods, 	%<<"培養忠誠度所需道具">>, 
	player_lv, 	%<<"開放等級">>, 
	partner_bag, 	%<<"武將包id">>, 
	call_on_goods, 	%<<"拜見獲得兵書">>, 
	call_on_see, 	%<<"拜見獲得閱歷">>, 
	look_attr 	%<<"尋訪啟動屬性">> 
}).

