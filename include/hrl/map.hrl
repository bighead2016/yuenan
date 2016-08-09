-record(rec_map, {
	map_id, 	%<<"地圖ID">>, 
	name, 	%<<"地圖名稱">>, 
	type, 	%<<"地圖類型">>, 
	weight, 	%<<"地圖寬度">>, 
	height, 	%<<"地圖高度">>, 
	x, 	%<<"地圖x座標">>, 
	y, 	%<<"地圖y座標">>, 
	r_x, 	%<<"x軸隨機半徑">>, 
	r_y, 	%<<"y軸隨機半徑">>, 
	lv, 	%<<"地圖等級">>, 
	flag_pk, 	%<<"PK">>, 
	flag_ride, 	%<<"坐騎">>, 
	flag_train, 	%<<"修煉">>, 
	flag_team, 	%<<"隊伍操作">>, 
	flag_goods, 	%<<"使用物品">>, 
	doors, 	%<<"傳送門列表">>, 
	npcs, 	%<<"列表NPC">>, 
	monsters, 	%<<"怪物列表">>, 
	gathers 	%<<"採集列表">> 
}).

