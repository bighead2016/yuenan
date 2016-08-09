-record(rec_welfare, {
	id, 	%<<"福利ID">>, 
	next, 	%<<"後續福利ID">>, 
	name, 	%<<"福利名稱">>, 
	cd, 	%<<"冷卻時間">>, 
	reset, 	%<<"重置條件">>, 
	type, 	%<<"福利類型">>, 
	requirement, 	%<<"福利類型要求條件">>, 
	is_when, 	%<<"匹配條件">>, 
	activity_start, 	%<<"活動生效時間">>, 
	activity_end, 	%<<"活動失效時間">>, 
	exp, 	%<<"經驗">>, 
	meritorious, 	%<<"功勳">>, 
	gold, 	%<<"遊戲幣">>, 
	cash_bind, 	%<<"邦定元寶">>, 
	goods, 	%<<"物品">>, 
	experience, 	%<<"歷練">>, 
	sp 	%<<"體力">> 
}).

