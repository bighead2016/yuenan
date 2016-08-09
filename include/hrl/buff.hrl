-record(rec_buff, {
	buff_type, 	%<<"類型">>, 
	is_active, 	%<<"作用類型">>, 
	priority, 	%<<"優先順序">>, 
	relation, 	%<<"同類型BUFF關係">>, 
	oppose_buff_type, 	%<<"對立BUFF類型列表">>, 
	limit, 	%<<"疊加上限">>, 
	name, 	%<<"名稱">>, 
	desc 	%<<"描述">> 
}).

