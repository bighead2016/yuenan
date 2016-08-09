-record(rec_achievement, {
	id, 	%<<"成就ID">>, 
	times, 	%<<"完成次數">>, 
	title_id, 	%<<"稱號ID">>, 
	points, 	%<<"可獲成就點">>, 
	type, 	%<<"類型">>, 
	condition, 	%<<"成就資料">>, 
	is_when, 	%<<"是否匹配">>, 
	accumulative 	%<<"是否累計">> 
}).

