-record(rec_mall_sale, {
	id, 	%<<"類型（參考常量）">>, 
	start_time, 	%<<"開始時間">>, 
	end_time, 	%<<"結束時間">>, 
	goods 	%<<"出售物品{物品id,是否綁定,消費類型,原價,現價,限購數量}">> 
}).

