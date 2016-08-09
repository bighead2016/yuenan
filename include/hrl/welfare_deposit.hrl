  -record(rec_welfare_deposit, {
	id, 	%<<"id">>, 
	type, 	%<<"類型">>, 
	is_in, 	%<<"充值標誌">>, 
	group_id, 	%<<"活動id">>, 
	money_from, 	%<<"從x元寶">>, 
	money_to, 	%<<"到y元寶">>, 
	goods, 	%<<"物品">>, 
	partner_list, 	%<<"武將列表">>, 
	cash, 	%<<"元寶">>, 
	cash_bind, 	%<<"綁定元寶">>, 
	gold 	%<<"銅幣">> 
}).

