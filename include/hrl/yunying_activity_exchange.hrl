-record(rec_yunying_activity_exchange, {
	id, 	%<<"兌換按鈕的id">>, 
	type, 	%<<"類型">>, 
	need_goods, 	%<<"需要的物品[{goodsid,num}]">>, 
	exchange_goods 	%<<"兌換獲得的物品[{goodsid,bind,num}]">> 
}).

