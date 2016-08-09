-record(rec_horse_lv, {
	lv, 	%<<"等級">>, 
	exp, 	%<<"升級經驗">>, 
	add_attr, 	%<<"增加屬性清單{屬性類型,屬性值}">>, 
	inherit_cost_type, 	%<<"繼承花費類型">>, 
	inherit_cost_value, 	%<<"繼承費用">>, 
	cash_cost, 	%<<"元寶花費">>, 
	cash_rate, 	%<<"出現暴擊的當前經驗比例">>, 
	cash_big_crit, 	%<<"大暴擊幾率">>, 
	cash_small_crit, 	%<<"小暴擊幾率">>, 
	cash_small_crit_exp, 	%<<"小暴擊經驗">>, 
	cash_exp, 	%<<"元寶經驗">>, 
	gold_cost, 	%<<"銅幣花費">>, 
	gold_small_crit, 	%<<"小暴擊幾率">>, 
	gold_small_crit_exp, 	%<<"小暴擊經驗">>, 
	gold_exp, 	%<<"銅幣經驗">>, 
	one_key_cost 	%<<"一鍵升級花費">> 
}).

