-record(rec_achieve_ext, {
	id, 	%<<"目標ID">>, 
	times, 	%<<"完成次數">>, 
	type, 	%<<"類型">>, 
	sup_type, 	%<<"父類型">>, 
	condition, 	%<<"成長數據">>, 
	is_when, 	%<<"是否匹配">>, 
	goods, 	%<<"物品ID">>, 
	is_new, 	%<<"是否新服">>, 
	activity_start, 	%<<"活動生效時間">>, 
	activity_end, 	%<<"活動失效時間">>, 
	is_reset 	%<<"是否每天重置">> 
}).

