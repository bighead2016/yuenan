%%% 日志格式化工厂
-module(logger_fmt_factory).

%%
%% Include files
%%
-include("const.common.hrl").

%%
%% Exported Functions
%%
-export([format/1]).

%%
%% API Functions
%%


format([Type|ValueList]) ->
    try
        TabName = admin_log_api:get_tab_name(Type),
        record_insert_sql(TabName, ValueList)
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end;
format([]) ->
   ok.

%%
%% Local Functions
%%

%%---
record_insert_sql(TabName, Data) ->
    Sql1 = lists:concat(["INSERT INTO `", TabName, "` values( "]),
    Sql = record_insert_sql_2(Data, ""),
    Sql2 = lists:concat([Sql1, Sql, ");"]),
%%     ?MSG_ERROR("~p", [Sql2]),
    case mysql_api:select(misc:to_binary(Sql2)) of
        {?ok, _} ->
            ?ok;
        {?ok, _, _} ->
            ?ok;
        R ->
            ?MSG_ERROR("x[~p|~p]", [Sql2, R])
    end.

record_insert_sql_2([Value], OldSql) ->
    Sql = lists:concat([OldSql, "'", misc:to_list(Value), "'"]),
    record_insert_sql_2([], Sql);
record_insert_sql_2([Value|Tail], OldSql) ->
    Sql = lists:concat([OldSql, "'", misc:to_list(Value), "',"]),
    record_insert_sql_2(Tail, Sql);
record_insert_sql_2([], Sql) ->
    Sql.    
