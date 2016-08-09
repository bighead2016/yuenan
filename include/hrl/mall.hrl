-record(rec_mall, {
	type, 	%<<"類型（參考常量）">>, 
	goods_id, 	%<<"物品id">>, 
	bind, 	%<<"是否綁定">>, 
	cost_type, 	%<<"貨幣類型(參考常量)">>, 
	c_price, 	%<<"現在價格">>, 
	lv_request, 	%<<"等級要求(vip商城為vip等級要求)">>, 
	num, 	%<<"數量上限">>, 
	odds 	%<<"(限時折扣:幾率)">> 
}).

