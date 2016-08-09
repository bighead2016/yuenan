-record(rec_table_diff, {
	table_name, 	%<<"表名">>, 
	from_main_ver, 	%<<"從主版本號">>, 
	from_sub_ver, 	%<<"從副版本號">>, 
	from_third_ver, 	%<<"從次版本號">>, 
	to_main_ver, 	%<<"到主版本號">>, 
	to_sub_ver, 	%<<"到副版本號">>, 
	to_third_ver, 	%<<"到次版本號">>, 
	trans_type, 	%<<"轉換類型">>, 
	trans_mod, 	%<<"轉換模組">>, 
	trans_func, 	%<<"轉換函數">>, 
	trans_arg 	%<<"轉換入參">> 
}).

