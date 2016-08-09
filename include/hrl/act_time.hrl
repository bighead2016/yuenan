-record(rec_act_time, {
	id, 	%<<"活動id">>, 
	template, 	%<<"活動範本id">>, 
	config_id, 	%<<"獎勵id">>, 
	time_type, 	%<<"時間類型">>, 
	time_start, 	%<<"生效時間">>, 
	time_end, 	%<<"失效時間">>, 
	time_last_from, 	%<<"生成從天數">>, 
	time_last_to, 	%<<"生成到天數">>, 
	reset_daily, 	%<<"每天重置">>, 
	clear_over, 	%<<"過期清數據">>, 
	plat, 	%<<"平臺限制">>, 
	is_open 	%<<"開啟">> 
}).

