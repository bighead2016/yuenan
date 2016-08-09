-record(rec_snow_goods_list, {
	level, 	%<<"層數">>, 
	goods_list, 	%<<"[{goods_info,位置，概率，道具ID，是否綁定,數量}">>, 
	goods_list2, 	%<<"[{道具ID，是否綁定,數量}]">>, 
	need_count, 	%<<"需要的禮燈數">>, 
	time_start, 	%<<"生效時間">>, 
	time_end 	%<<"失效時間">> 
}).

