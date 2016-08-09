-record(rec_furnace_stone, {
	id, 	%<<"寶石ID">>, 
	next_id, 	%<<"合成寶石id">>, 
	lv, 	%<<"寶石等級">>, 
	info, 	%<<"寶石描述">>, 
	type, 	%<<"增加屬性類型類型">>, 
	value, 	%<<"增加屬性值">>, 
	subtype, 	%<<"限制的裝備子類型">>, 
	cost_gold, 	%<<"合成花費銅錢">>, 
	cross_item, 	%<<"合成花費物品">>, 
	change_cost, 	%<<"轉換花費銅錢">>, 
	change_list, 	%<<"可轉換寶石id列表">>, 
	stone_price 	%<<"寶石價格">> 
}).

