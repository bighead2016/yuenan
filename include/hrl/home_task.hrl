-record(rec_home_task, {
	task_id, 	%<<"任務id">>, 
	refresh_probablity, 	%<<"刷新概率">>, 
	times, 	%<<"完成次數">>, 
	refresh_cd, 	%<<"刷新間隔時間(分鐘)">>, 
	color_cd, 	%<<"每個品質對應cd(分鐘)">>, 
	lv 	%<<"任務等級限制">> 
}).

