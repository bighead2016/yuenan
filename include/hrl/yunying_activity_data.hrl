-record(rec_yunying_activity_data, {
	type, 	%<<"運營活動類型">>, 
	award_list, 	%<<"[{目標ID,達成條件，[{物品id,是否綁定，數量}...]}...]">>, 
	time_start, 	%<<"開啟時間">>, 
	time_end, 	%<<"結束時間">>, 
	new_serv = 8, 	%<<"開服n天內不開啟">> 
	time_type = 1,		% 开启时间类型（0,正常，1,开服n天
	new_serv_end = 20 %<<"開服n天后结束">> 
}).

