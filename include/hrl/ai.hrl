-record(rec_ai, {
	id, 	%<<"id">>, 
	next_ai, 	%<<"聯動AI">>, 
	type, 	%<<"ai類型">>, 
	trigger, 	%<<"觸發類型">>, 
	ai_start, 	%<<"觸發條件">>, 
	ai_end, 	%<<"結束條件">>, 
	con_side, 	%<<"條件單位邊">>, 
	con_units_1, 	%<<"條件單位1(左邊)">>, 
	con_units_2, 	%<<"條件單位2(右邊)">>, 
	target_side, 	%<<"變化目標邊">>, 
	target_units_1, 	%<<"變化單位1(左邊)">>, 
	target_units_2, 	%<<"變化單位2(右邊)">>, 
	def_side, 	%<<"攻擊目標邊">>, 
	def_units_1, 	%<<"攻擊目標(左邊)">>, 
	def_units_2, 	%<<"攻擊目標(右邊)">>, 
	value, 	%<<"值">>, 
	value_type, 	%<<"變化數值型別">>, 
	attr_type, 	%<<"變化屬性">>, 
	occasion, 	%<<"聯動時機">>, 
	is_stop 	%<<"是否暫停戰鬥">> 
}).

