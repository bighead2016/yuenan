%%%--------------------------------------
%%% @Module  : mysql_mod
%%% @Author  : cobain
%%% @Created : 2012.12.09
%%% @Description: MYSQL数据库操作 
%%%--------------------------------------
-module(mysql_mod).
%% -include("../../include/const.common.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/drive.mysql.hrl").
-export([execute/1, execute/2, execute/3, 
         get_all/1, get_all/2, get_all/3,
         get_order_sql/1,
         get_sql_val/1, get_where_sql/1,
         make_conn_sql/3, make_delete_sql/2, make_insert_sql/2,
         make_insert_sql/3, make_replace_sql/2,make_select_sql/3,
         make_select_sql/5, make_update_sql/3, make_update_sql/5,
         mysql_halt/1, select_limit/3, select_limit/4, select_limit/5,
         transaction/1]).

%% 执行一个SQL查询,返回影响的行数
execute(Sql) ->
	case erlang:is_tuple(Sql) of
		false ->
			case mysql_serv:fetch(?DB_POOL, Sql) of
				{updated, Data} -> {ok, Data};
				{error, #mysql_result{error = Reason}} -> 
                    mysql_halt([Sql, Reason])
			end;
		_ ->
			{NewSql, Server} = Sql,
			case mysql_serv:fetch(Server, ?DB_POOL, NewSql, undefined) of
				{updated, Data} -> {ok, Data};
				{error, #mysql_result{error = Reason}} -> 
                    mysql_halt([NewSql, Reason])
			end
	end.

execute(Sql, Args) ->
	execute(mysql_dispatcher, Sql, Args).

execute(_Server, Sql, Args) when is_atom(Sql) ->
	case mysql_serv:execute(?DB_POOL, Sql, Args) of
		{updated, Data} -> {ok, Data};
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end;
execute(Server, Sql, Args) ->
	mysql_serv:prepare(Server, s, Sql),
	case mysql_serv:execute(?DB_POOL, s, Args) of
		{updated, Data} -> {ok, Data};
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end.

%% 事务处理
transaction(F) ->
	case mysql_serv:transaction(?DB_POOL, F) of
		{atomic, R} -> R;
		{updated, Data} -> {ok, Data};
		{error, #mysql_result{error = Reason}} -> mysql_halt([Reason]);
		{aborted, {Reason, _}} -> mysql_halt([Reason]);
		Error -> mysql_halt([Error])
	end.

%% 执行分页查询返回结果中的所有行
select_limit(Sql, Offset, Num) ->
	S = list_to_binary([Sql, <<" LIMIT ">>, integer_to_list(Offset), <<", ">>, integer_to_list(Num)]),
	case mysql_serv:fetch(?DB_POOL, S) of
		{data, #mysql_result{rows = R}} -> R;
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end.

select_limit(Sql, Args, Offset, Num) ->
	select_limit(mysql_dispatcher, Sql, Args, Offset, Num).

select_limit(Server, Sql, Args, Offset, Num) ->
	S = list_to_binary([Sql, <<" LIMIT ">>, list_to_binary(integer_to_list(Offset)), <<", ">>, list_to_binary(integer_to_list(Num))]),
	mysql_serv:prepare(Server, s, S),
	case mysql_serv:execute(?DB_POOL, s, Args) of
		{data, #mysql_result{rows = R}} -> R;
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end.

%% 取出查询结果中的所有行
get_all(Sql) ->
	case erlang:is_tuple(Sql) of
		false ->
			case mysql_serv:fetch(?DB_POOL, Sql) of
                {updated, #mysql_result{rows = R, lastinsertid = Id}} -> {ok, R, Id};
				{data, #mysql_result{rows = R}} -> {ok, R};
				{error, #mysql_result{error = Reason}} -> 
					io:format("~nReason:~s~n", [Reason]),
                    mysql_halt([Sql, Reason]),
                    {error, ?TIP_COMMON_ERROR_DB}
			end;
		_ ->
			{NewSql, Server} = Sql,
			case mysql_serv:fetch(Server, ?DB_POOL, NewSql, undefined) of
                {updated, #mysql_result{rows = R, lastinsertid = Id}} -> {ok, R, Id};
				{data, #mysql_result{rows = R}} -> {ok, R};
				{error, #mysql_result{error = Reason}} -> 
%% 					io:format("~nReason:~s~n", [Reason]),
                    mysql_halt([Sql, Reason]),
                    {error, ?TIP_COMMON_ERROR_DB}
			end
	end.


get_all(Sql, Args) ->
	get_all(mysql_dispatcher, Sql, Args).

get_all(_Server, Sql, Args) when is_atom(Sql) ->
	case mysql_serv:execute(?DB_POOL, Sql, Args) of
		{data, #mysql_result{rows = R}} -> R;
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end;
get_all(Server, Sql, Args) ->
	mysql_serv:prepare(Server, s, Sql),
	case mysql_serv:execute(?DB_POOL, s, Args) of
		{data, #mysql_result{rows = R}} -> R;
		{error, #mysql_result{error = Reason}} -> mysql_halt([Sql, Reason])
	end.

%% @doc 显示人可以看得懂的错误信息
mysql_halt([Sql, Reason]) ->
	catch erlang:error({db_error, [Sql, Reason]}).

%%组合mysql insert语句
%% 使用方式mysql_mod:make_insert_sql(test,["row","r"],["测试",123]) 相当 INSERT INTO `test` (row,r) values('测试','123')
%%Table:表名
%%Field：字段
%%Data:数据
make_insert_sql(TableName, FieldList, ValueList) -> 
	L = make_conn_sql(FieldList, ValueList, []),
	lists:concat(["INSERT INTO `", TableName, "` SET ", L]).

%%组合mysql update语句
%% 使用方式mysql_mod:make_update_sql(test,["row","r"],["测试",123],"id",1) 相当 UPDATE `test` SET row='测试', r = '123' WHERE id = '1'
%%Table:表名
%%Field：字段
%%Data:数据
%%Key:键
%%Data:值
make_update_sql(TableName, Field, Data, Key, Value) ->
	L = make_conn_sql(Field, Data, []),
	lists:concat(["UPDATE `", TableName, "` SET ",L," WHERE ",Key,"= '",misc:to_list(Value),"'"]).

make_conn_sql([], _, L ) ->
	L ;
make_conn_sql(_, [], L ) ->
	L ;
make_conn_sql([F | T1], [D | T2], []) ->
	L  = ["`",misc:to_list(F), "`='",get_sql_val(D),"'"],
	make_conn_sql(T1, T2, L);
make_conn_sql([F | T1], [D | T2], L) ->
	L1  = L ++ [",`", misc:to_list(F),"`='",get_sql_val(D),"'"],
	make_conn_sql(T1, T2, L1).

get_sql_val(Val) ->
	case is_binary(Val) orelse is_list(Val) of 
		true -> re:replace(misc:to_list(Val),"'","''''",[global,{return,list}]);
		_-> misc:to_list(Val)
	end.

make_insert_sql(TableName, FieldValueList) ->
	Fun		= fun(Field_value, Sum) ->	
					  Expr = case Field_value of
								 {Field, Val} -> 
									 case is_binary(Val) orelse is_list(Val) of 
										 true -> io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
										 _-> io_lib:format("`~s`='~p'",[Field, Val])
									 end
							 end,
					  S1 = if Sum == length(FieldValueList) -> io_lib:format("~s ",[Expr]);
							  true -> io_lib:format("~s,",[Expr])
						   end,
					  {S1, Sum+1}
			  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, FieldValueList),
	lists:concat(["INSERT INTO `", TableName, "` SET ", lists:flatten(Vsql)]).

make_replace_sql(TableName, FieldValueList) ->
	%%  mysql_mod:make_replace_sql(player, 
	%%                         [{status, 0}, {online_flag,1}, {hp,50}, {mp,30}]).
	Fun		= fun(Field_value, Sum) ->
					  Expr = case Field_value of
								 {Field, Val} -> 
									 case is_binary(Val) orelse is_list(Val) of 
										 true ->    
											 io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
										 _->
											 io_lib:format("`~s`=~p",[Field, Val])
									 end
							 end,
					  S1 = if Sum == length(FieldValueList) -> io_lib:format("~s ",[Expr]); true -> io_lib:format("~s,",[Expr]) end,
					  {S1, Sum+1}
			  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, FieldValueList),
	lists:concat(["REPLACE INTO `", TableName, "` SET ", lists:flatten(Vsql)]).

make_update_sql(TableName, FieldValueList, WhereList) ->
	%%  mysql_mod:make_update_sql(player, 
	%%                         [{status, 0}, {online_flag,1}, {hp,50, add}, {mp,30,sub}],
	%%                         [{id, 11}]).
	Fun		= fun(Field_value, Sum) ->	
					  Expr = case Field_value of
								 {Field, Val, add} -> io_lib:format("`~s`=`~s`+~p", [Field, Field, Val]);
								 {Field, Val, sub} -> io_lib:format("`~s`=`~s`-~p", [Field, Field, Val]);						 
								 {Field, Val} -> 
									 case is_binary(Val) orelse is_list(Val) of 
										 true -> io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]);
										 _-> io_lib:format("`~s`='~p'",[Field, Val])
									 end
							 end,
					  S1 = if Sum == length(FieldValueList) -> io_lib:format("~s ",[Expr]); true -> io_lib:format("~s,",[Expr]) end,
					  {S1, Sum+1}
			  end,
	{Vsql, _Count1} = lists:mapfoldl(Fun, 1, FieldValueList),
	{Wsql, Count2} = get_where_sql(WhereList),
	WhereSql = if Count2 > 1 -> lists:concat(["WHERE ", lists:flatten(Wsql)]); true -> "" end,
	lists:concat(["UPDATE `", TableName, "` SET ", lists:flatten(Vsql), WhereSql, ""]).

make_delete_sql(TableName, WhereList) ->
	%% mysql_mod:make_delete_sql(player, [{id, "=", 11, "AND"},{status, 0}]).
	{Wsql, Count2} 	= get_where_sql(WhereList),
	WhereSql 		= if Count2 > 1 -> lists:concat(["WHERE ", lists:flatten(Wsql)]); true -> "" end,
	lists:concat(["DELETE FROM `", TableName, "` ", WhereSql, ""]).

make_select_sql(TableName, Fields_sql, WhereList) ->
	make_select_sql(TableName, Fields_sql, WhereList, [], []).

%% mysql_mod:make_select_sql(player, "*", [{status, 1}], [{id,desc},{status}],[]).
%% mysql_mod:make_select_sql(player, "id, status", [{id, 11}], [{id,desc},{status}],[]).
make_select_sql(TableName, Fields_sql, WhereList, Order_List, Limit_num) ->
	{Wsql, Count1} = get_where_sql(WhereList),
	WhereSql = 
		if Count1 > 1 -> lists:concat(["WHERE ", lists:flatten(Wsql)]);
		   true -> ""
		end,
	{Osql, Count2} = get_order_sql(Order_List),
	OrderSql = 
		if Count2 > 1 -> lists:concat(["ORDER BY ", lists:flatten(Osql)]);
		   true -> ""
		end,
	LimitSql =
		case Limit_num of
			[] -> "";
			[Num] -> lists:concat(["LIMIT ", Num]);
            Num ->
                lists:concat(["LIMIT ", Num])
		end,
	lists:concat(["SELECT ", Fields_sql," FROM `", TableName, "` ", WhereSql, OrderSql, LimitSql]).

get_order_sql(Order_List) ->
	%%  排序用列表方式：[{id, desc},{status}]
	Fun		= fun(FieldOrder, Sum) ->	
					  Expr = 
						  case FieldOrder of   
							  {Field, Order} ->
								  io_lib:format("~p ~p",[Field, Order]);
							  {Field} ->
								  io_lib:format("~p",[Field]);
							  _-> ""
						  end,
					  S1 = if Sum == length(Order_List) -> io_lib:format("~s ",[Expr]);
							  true ->	io_lib:format("~s,",[Expr])
						   end,
					  {S1, Sum+1}
			  end,
	lists:mapfoldl(Fun, 1, Order_List).

get_where_sql(WhereList) ->
	%%  条件用列表方式：[{},{},{}]
	%%  每一个条件形式(一共三种)：
	%%		1、{idA, "<>", 10, "or"}   	<===> {字段名, 操作符, 值，下一个条件的连接符}
	%% 	    2、{idB, ">", 20}   			<===> {idB, ">", 20，"AND"}
	%% 	    3、{idB, 20}   				<===> {idB, "=", 20，"AND"}	
	Fun		= fun(FieldOperatorVal, Sum) ->	
					  [Expr, OrAnd1] = 
						  case FieldOperatorVal of   
							  {Field, Operator, Val, OrAnd} ->
								  case is_binary(Val) orelse is_list(Val) of 
									  true -> [io_lib:format("`~s`~s'~s'",[Field, Operator, re:replace(Val,"'","''",[global,{return,binary}])]), OrAnd];
									  _-> [io_lib:format("`~s`~s'~p'",[Field, Operator, Val]), OrAnd]
								  end;
							  {Field, Operator, Val} ->
								  case is_binary(Val) orelse is_list(Val) of 
									  true -> [io_lib:format("`~s`~s'~s'",[Field, Operator, re:replace(Val,"'","''",[global,{return,binary}])]), "AND"];
									  _-> [io_lib:format("`~s`~s'~p'",[Field, Operator, Val]),"AND"]
								  end;
							  {Field, Val} ->  
								  case is_binary(Val) orelse is_list(Val) of 
									  true -> [io_lib:format("`~s`='~s'",[Field, re:replace(Val,"'","''",[global,{return,binary}])]), "AND"];
									  _-> [io_lib:format("`~s`='~p'",[Field, Val]), "AND"]
								  end;
							  _-> ""
						  end,
					  S1 = if Sum == length(WhereList) -> io_lib:format("~s ",[Expr]);
							  true ->	io_lib:format("~s ~s ",[Expr, OrAnd1])
						   end,
					  {S1, Sum+1}
			  end,
	lists:mapfoldl(Fun, 1, WhereList).

