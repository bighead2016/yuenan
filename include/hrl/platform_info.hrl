-record(rec_platform_info, {
	platform_id, 	%<<"平台id">>, 
	platform, 	%<<"后端用名">>, 
	platform_2, 	%<<"平台简称">>, 
	fcm_site, 	%<<"防沉迷提交站点">>, 
	login_check, 	%<<"登陆检查方式">>, 
	login_key, 	%<<"登陆key">>,
	app_id,
	app_key, 
	center_node, 	%<<"中心服">>, 
	same_account, 	%<<"同帐号不同服同时在线">>, 
	ver 	%<<"数据版本">> 
}).

