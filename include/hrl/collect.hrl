-record(rec_collect, {
	id, 	%<<"採集品id">>, 
	type, 	%<<"類型">>, 
	name, 	%<<"名字">>, 
	map_id, 	%<<"所在場景">>, 
	x, 	%<<"座標X">>, 
	y, 	%<<"座標Y">>, 
	goods_id, 	%<<"對應物品id">>, 
	lv, 	%<<"採集等級">>, 
	collect_type, 	%<<"採集類型">>, 
	sp, 	%<<"消耗體力">>, 
	time, 	%<<"採集時間">>, 
	normal_goods, 	%<<"普通物品掉落">>, 
	adv_rate, 	%<<"奇遇幾率">>, 
	adv_goods 	%<<"奇遇物品掉落">> 
}).

