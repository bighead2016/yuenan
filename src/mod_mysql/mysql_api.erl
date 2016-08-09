%% Author  : cobain
%% Created: 2012-12-09
%% Description: TODO: Add description to mysql_api
-module(mysql_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("drive.mysql.hrl").

%%
%% Exported Functions
%%
-export([start/0, stop/0]).
-export([encode/1, decode/1]).
-export([
		 insert/1, insert/2, insert/3, insert/4, insert_execute/1,
		 update/1, update/3, update/4, update/5, update_execute/1,
		 select/3, select/2, select/1, select_execute/1,
		 delete/1, delete/2, list_to_string/1,
		 transaction/1, execute/1,  fetch_cast/1, fetch/1, select/5,
		 stat_db_access/2, rename/2, execute_sql/1, mysql_halt/1
		]).
%%
%% API Functions
%%
get_cur_config() ->
    case config:read_deep([server, base, debug]) of
        ?CONST_SYS_TRUE ->
            MysqlId = config:read_deep([server, debug, mysql]),
            DbList = config:read_deep([server, debug, db_list]),
            lists:keyfind(MysqlId, 1, DbList);
        _ ->
            Host     = config:read_deep([server, release, db_host]),
            UserName = config:read_deep([server, release, db_username]),
            Password = config:read_deep([server, release, db_password]),
            DatabasePre = config:read_deep([server, release, db_database]),
            Port     = config:read_deep([server, release, db_port]),
            Charset  = config:read_deep([server, release, db_charset]),
            {a, Host, UserName, Password, DatabasePre, Port, Charset}
    end.

%% mysql_api:start().
start() ->
    case get_cur_config() of
        ?false ->
            ?false;
        {_, Host, UserName, Password, DatabasePre, Port, Charset} ->
            ?MSG_SYS("sql:~p,~p,~p,~p,~p,~p", [Host, UserName, Password, DatabasePre, Port, Charset]),
        	Database 	= misc:to_list(DatabasePre),
            mysql_serv:start_link(?DB_POOL, Host, Port, UserName, Password, Database,  fun(_, _, _, _) -> ok end, Charset),
            do_start(?DBCONNECT_COUNT, ?DB_POOL, Host, Port, UserName, Password, Database, Charset, true),
        	?ok
    end.

do_start(N, Db, Host, Port, UserName, Password, Database, Charset, X) when N > 0 ->
    try
        mysql_serv:connect(Db, Host, Port, UserName, Password, Database, Charset, X)
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
    do_start(N-1, Db, Host, Port, UserName, Password, Database, Charset, X);
do_start(_, _, _, _, _, _, _, _, _) -> 
    ok.

stop() ->
    gen_server:cast(mysql, stop).

%% 插入数据表
insert(Server, TableName, FieldList, ValueList) ->
  stat_db_access(TableName, insert),
  Sql = mysql_mod:make_insert_sql(TableName, FieldList, ValueList),
  execute({Sql, Server}).
insert(TableName, FieldList, ValueList) ->
  stat_db_access(TableName, insert), 
  Sql = mysql_mod:make_insert_sql(TableName, FieldList, ValueList),
  execute(Sql).

insert_execute(Sql) ->
    execute(Sql).
insert(Sql) ->
    execute(Sql).
insert(TableName, FieldValueList) ->
  stat_db_access(TableName, insert),
  Sql = mysql_mod:make_insert_sql(TableName, FieldValueList),
  execute(Sql).

%% 修改数据表(update方式)
update_execute(Sql) ->
    execute2(Sql).

update(Sql) ->
    execute2(Sql).
update(TableName, Field, Data, Key, Value) ->
	stat_db_access(TableName, update),
    FieldsSql2 = list_to_string(Field),
	Sql = mysql_mod:make_update_sql(TableName, FieldsSql2, Data, Key, Value),
	execute2(Sql).
update(TableName, FieldValueList, WhereList) ->
	stat_db_access(TableName, update),
	Sql = mysql_mod:make_update_sql(TableName, FieldValueList, WhereList),
	execute2(Sql).

update(Server, TableName, FieldValueList, WhereList) ->
	stat_db_access(TableName, update),
	Sql = mysql_mod:make_update_sql(TableName, FieldValueList, WhereList),
	execute2({Sql, Server}).

select_execute(Sql) ->
    mysql_mod:get_all(Sql).

select(Sql) ->
    mysql_mod:get_all(Sql).

select(FieldsSql, TableName) ->
    select(FieldsSql, TableName, []).

%% mysql_api:select([user_id], game_user, [{lv, 2}]).
select(FieldsSql, TableName, WhereList) ->
    stat_db_access(TableName, select),
    FieldsSql2 = list_to_string(FieldsSql),
    Sql = mysql_mod:make_select_sql(TableName, FieldsSql2, WhereList),
    mysql_mod:get_all(Sql).

select(FieldsSql, TableName, WhereList, OrderList, LimitNum) ->
    stat_db_access(TableName, select),
    FieldsSql2 = list_to_string(FieldsSql),
    Sql = mysql_mod:make_select_sql(TableName, FieldsSql2, WhereList, OrderList, LimitNum),
    mysql_mod:get_all(Sql).

%% 删除数据
delete(Sql) ->
    execute(Sql).
delete(TableName, WhereList) ->
	stat_db_access(TableName, delete),	
    Sql = lists:concat(["DELETE FROM `", TableName, "` WHERE ", WhereList]),
	execute(Sql).

execute(Sql) when is_binary(Sql) ->
    Sql2 = binary_to_list(Sql),
    execute(Sql2);
execute(Sql) ->
    case mysql_mod:execute(Sql) of
        {?ok, Data2} ->
            if
                Data2#mysql_result.affectedrows > 0 ->
                    {?ok,   Data2#mysql_result.affectedrows, Data2#mysql_result.lastinsertid};
                ?true ->
                    {?error,Data2#mysql_result.error}
            end;
        {?error,Data2}->
            {?error,Data2#mysql_result.error}
    end.

execute2(Sql) when is_binary(Sql) ->
    Sql2 = binary_to_list(Sql),
    execute2(Sql2);
execute2(Sql) ->
    case mysql_mod:execute(Sql) of
        {?ok, Data2} ->
            if
                Data2#mysql_result.affectedrows > 0 ->
                    {?ok,   Data2#mysql_result.lastinsertid};
                ?true ->
                    {?error,Data2#mysql_result.error}
            end;
        {?error,Data2}->
            {?error,Data2#mysql_result.error}
    end.

fetch_cast(Sql) ->
    execute(Sql).
fetch(Sql) ->
    execute(Sql).

execute_sql(Sql) when is_binary(Sql) ->
	execute_sql(binary_to_list(Sql));
execute_sql(Sql) ->
	mysql_mod:execute(Sql).


%% 事务处理
transaction(Fun) ->
	mysql_mod:transaction(Fun).

encode(Data) ->
	Bin1	= term_to_binary(Data),
	Bin0	= zlib:compress(Bin1),
	iolist_to_binary("0x"++misc:bin_to_hex(Bin0)).

decode(Bin) ->
	Bin0 	= zlib:uncompress(Bin),
	binary_to_term(Bin0).

%% 改表名
rename(TnameFrom, TnameTo) ->
    TnameFrom2 = misc:to_list(TnameFrom),
    TnameTo2   = misc:to_list(TnameTo),
    case mysql_mod:execute("rename table "++TnameFrom2++" to "++TnameTo2++";") of
        {?ok, _} -> ?ok;
        _ -> {?error, ?TIP_COMMON_ERROR_DB}
    end.

mysql_halt([Sql, Reason]) ->
    mysql_mod:mysql_halt([Sql, Reason]).
  
%% --------------------------------------------------------------------------
%%统计数据表操作次数和频率
stat_db_access(TableName, Operation) ->
	try
		Key = lists:concat([TableName, "/", Operation]),
		[NowBeginTime, NowCount] = 
			case ets:match(?ETS_STAT_MYSQL,{Key, TableName, Operation , '$4', '$5'}) of
				[[OldBeginTime, OldCount]] ->
					[OldBeginTime, OldCount+1];
				_ -> [misc:seconds(),1]
			end,	
		ets:insert(?ETS_STAT_MYSQL, {Key, TableName, Operation, NowBeginTime, NowCount}),
		ok
	catch
		_:_ -> no_stat
	end.

%%将列表转换为string [a,b,c] -> "a,b,c"
list_to_string(List) when is_list(List) ->
    F = fun(E) ->
                "`" ++misc:to_list(E)++"`,"
        end,
    L1 = [F(E)||E <- List],
    L2 = lists:concat(L1),
    string:substr(L2,1,length(L2)-1);
list_to_string(List) ->
    List.

%% init() ->
%% 	init_index(user_goods,id),
%% 	init_index(user,uid),
%% 	init_index(mail,mail_id),
%% 	init_index(dungeon_auto_id),
%% 	init_index(market,mid),
%% 	init_index(team),
%% 	init_index(teach,tid),
%% 	ok.
%% 
%% init_index(Name) ->
%% 	ets:insert(?ETS_INDEX, {Name,1}).
%% 
%% init_index(Name,ID) ->
%% 	MaxID = mysql_api:select(Name,io_lib:format("max(~p)", [ID]),[]),
%% 	MID = ?IF(is_integer(MaxID),MaxID,0),
%% 	ets:insert(?ETS_INDEX, {Name,MID}).
%% 
%% get_id(Name) ->
%% 	ets:update_counter(?ETS_INDEX, Name, 1).