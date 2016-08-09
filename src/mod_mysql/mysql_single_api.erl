%% @author np
%% @doc @todo Add description to mysql_single_api.

-module(mysql_single_api).

-include("../../include/const.common.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/drive.mysql.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([start/6, select/2, make_sql/3, make_some_sql/4, get_fields/3, desc/2]).

start(Host, Port, UserName, Password, DatabasePre, Charset) ->
    Database    = misc:to_list(DatabasePre),
    Database2   = misc:to_atom(Database),
    mysql_serv:start_link(Database2, Host, Port, UserName, Password, Database,  fun(_, _, _, _) -> ok end, Charset),
    mysql_serv:connect(Database2, Host, Port, UserName, Password, Database, Charset, true),
    ok.

select(Sql, DbId) ->
    case mysql_serv:fetch(DbId, Sql) of
        {updated, #mysql_result{rows = R, lastinsertid = Id}} -> {ok, R, Id};
        {data, #mysql_result{rows = R}} -> {ok, R};
        {error, #mysql_result{error = Reason}} -> 
            ?MSG_SYS("~nsql:~s~nReason:~s", [Sql, Reason]),
            mysql_api:mysql_halt([Sql, Reason]),
            {error, ?TIP_COMMON_ERROR_DB}
    end.

make_sql(Values, TargetDb, Table) ->
    Desc = desc(TargetDb, Table),
    Sql = make_sql_2(Values, Desc, <<"">>),
%%     ?MSG_SYS("~s", [Sql]),
    Sql.

desc(TargetDb, Table) ->
    [{_, ResultList}] = combine_db_mod:execute({desc, Table},  [TargetDb]),
    ResultList.

make_sql_2([Value], [Desc], OldSql) ->
    Type = lists:nth(2, Desc),
    Sql  = make_sql_3(Value, Type, <<" ">>, OldSql),
    Sql;
make_sql_2([Value|VTail], [Desc|DTail], OldSql) ->
    Type = lists:nth(2, Desc),
%%     ?MSG_SYS("[~p|~p]", [Value, Type]),
    Sql  = make_sql_3(Value, Type, <<", ">>, OldSql),
    make_sql_2(VTail, DTail, Sql);
make_sql_2(_, _, Sql) ->
    Sql.

make_sql_3(Value, <<"longblob">>, X, OldSql) ->
    {V, BorderL, BorderR, IsX} = 
        try
            {mysql_api:encode(mysql_api:decode(Value)), <<" ">>, <<" ">>, 1}
        catch 
            _:_ ->
                if
                    Value =/= <<>> ->
                        {Value, <<" '">>, <<"' ">>, 2};
                    true ->
                        {<<"">>, <<" '">>, <<"' ">>, 1}
                end
        end,
    {V2, BorderL2, BorderR2} = 
        if
            2 =:= IsX ->
                try
                    {misc:encode(misc:decode(V)), <<" '">>, <<"' ">>}
                catch _:_ ->
                    {erlang:term_to_binary(erlang:binary_to_term(V)), <<" '">>, <<"' ">>}
                end;
            true ->
                {V, BorderL, BorderR}
        end,
    <<OldSql/binary, BorderL2/binary, V2/binary, BorderR2/binary, X/binary>>;
make_sql_3(Value, <<"blob">>, X, OldSql) ->
    {V, BorderL, BorderR, IsX} = 
        try
            {mysql_api:encode(mysql_api:decode(Value)), <<" ">>, <<" ">>, 1}
        catch 
            _:_ ->
                if
                    Value =/= <<>> ->
                        {Value, <<" '">>, <<"' ">>, 2};
                    true ->
                        {<<"">>, <<" '">>, <<"' ">>, 1}
                end
        end,
    {V2, BorderL2, BorderR2} = 
        if
            2 =:= IsX ->
                try
                    {misc:encode(misc:decode(V)), <<" '">>, <<"' ">>}
                catch _:_ ->
                    {erlang:term_to_binary(erlang:binary_to_term(V)), <<" '">>, <<"' ">>}
                end;
            true ->
                {V, BorderL, BorderR}
        end,
    <<OldSql/binary, BorderL2/binary, V2/binary, BorderR2/binary, X/binary>>;
make_sql_3(Value, <<"int", _/binary>>, X, OldSql) ->
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>;
make_sql_3(Value, <<"char", _/binary>>, X, OldSql) ->
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>;
make_sql_3(Value, <<"tinyint", _/binary>>, X, OldSql) ->
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>;
make_sql_3(Value, <<"bigint", _/binary>>, X, OldSql) ->
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>;
make_sql_3(Value, <<"smallint", _/binary>>, X, OldSql) ->
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>;
make_sql_3(Value, XXX, X, OldSql) ->
    ?MSG_SYS("x[~p]", [XXX]),
    <<OldSql/binary, " '", (misc:to_binary(Value))/binary, "' ", X/binary>>.

%% -----------------------------------------------------------------------------
get_fields(Db, Table, FF) ->
    Desc = desc(Db, Table),
    Fields = get_fields_2(Desc, <<"">>, FF),
    Fields.

get_fields_2([Desc], OldFields, FF) ->
    Field= lists:nth(1, Desc),
    case lists:member(Field, FF) of
        true ->
            OldFields;
        false ->
            <<OldFields/binary, " `", (misc:to_binary(Field))/binary, "` ">>
    end;
get_fields_2([Desc|DTail], OldFields, FF) ->
    Field    = lists:nth(1, Desc),
    NewField = 
        case lists:member(Field, FF) of
            true ->
                OldFields;
            false ->
                <<OldFields/binary, " `", (misc:to_binary(Field))/binary, "`, ">>
        end,
    get_fields_2(DTail, NewField, FF);
get_fields_2(_, F, _) ->
    F.
    
%% -----------------------------------------------------------------------------
make_some_sql(Values, TargetDb, Table, FF) ->
    Desc = desc(TargetDb, Table),
    {Field, Sql} = make_sql_some_2(Values, Desc, <<"">>, <<"">>, FF),
    {Field, Sql}.

make_sql_some_2([Value], [Desc], OldFields, OldSql, FF) ->
    Field= lists:nth(1, Desc),
    Type = lists:nth(2, Desc),
    case lists:member(Field, FF) of
        true ->
            {OldFields, OldSql};
        false ->
            {NewField, Sql}  = make_sql_some_3(Field, Value, Type, <<" ">>, OldFields, OldSql),
            {NewField, Sql}
    end;
make_sql_some_2([Value|VTail], [Desc|DTail], OldFields, OldSql, FF) ->
    Field= lists:nth(1, Desc),
    Type = lists:nth(2, Desc),
%%     ?MSG_SYS("[~p|~p]", [Value, Type]),
    {NewField, Sql} = 
        case lists:member(Field, FF) of
            true ->
                {OldFields, OldSql};
            false ->
                make_sql_some_3(Field, Value, Type, <<", ">>, OldFields, OldSql)
        end,
    make_sql_some_2(VTail, DTail, NewField, Sql, FF);
make_sql_some_2(_, _, F, Sql, _) ->
    {F, Sql}.

make_sql_some_3(Field, Value, <<"longblob">>, X, OldField, OldSql) ->
    {V, BorderL, BorderR, IsX} = 
        try
            {mysql_api:encode(mysql_api:decode(Value)), <<" ">>, <<" ">>, 1}
        catch 
            _:_ ->
                if
                    Value =/= <<>> ->
                        {Value, <<" '">>, <<"' ">>, 2};
                    true ->
                        {<<"">>, <<" '">>, <<"' ">>, 1}
                end
        end,
    {V2, BorderL2, BorderR2} = 
        if
            2 =:= IsX ->
                try
                    {misc:encode(misc:decode(V)), <<" '">>, <<"' ">>}
                catch _:_ ->
                    {erlang:term_to_binary(erlang:binary_to_term(V)), <<" '">>, <<"' ">>}
                end;
            true ->
                {V, BorderL, BorderR}
        end,
%%     ?MSG_SYS("[~p|~p|~p]", [BorderL, BorderR, V]),
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary, BorderL2/binary, (misc:to_binary(V2))/binary, BorderR2/binary, X/binary>>
    };
make_sql_some_3(Field, Value, <<"blob">>, X, OldField, OldSql) ->
    {V, BorderL, BorderR, IsX} = 
        try
            {mysql_api:encode(mysql_api:decode(Value)), <<" ">>, <<" ">>, 1}
        catch 
            _:_ ->
                if
                    Value =/= <<>> ->
                        {Value, <<" '">>, <<"' ">>, 2};
                    true ->
                        {<<"">>, <<" '">>, <<"' ">>, 1}
                end
        end,
    {V2, BorderL2, BorderR2} = 
        if
            2 =:= IsX ->
                try
                    {misc:encode(misc:decode(V)), <<" '">>, <<"' ">>}
                catch _:_ ->
                    {erlang:term_to_binary(erlang:binary_to_term(V)), <<" '">>, <<"' ">>}
                end;
            true ->
                {V, BorderL, BorderR}
        end,
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   BorderL2/binary, (misc:to_binary(V2))/binary, BorderR2/binary, X/binary>>
    };
make_sql_some_3(Field, Value, <<"int", _/binary>>, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    };
make_sql_some_3(Field, Value, <<"char", _/binary>>, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    };
make_sql_some_3(Field, Value, <<"tinyint", _/binary>>, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    };
make_sql_some_3(Field, Value, <<"bigint", _/binary>>, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    };
make_sql_some_3(Field, Value, <<"smallint", _/binary>>, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    };
make_sql_some_3(Field, Value, _, X, OldField, OldSql) ->
    {
     <<OldField/binary, " `", (misc:to_binary(Field))/binary, "` ", X/binary>>,
     <<OldSql/binary,   " '", (misc:to_binary(Value))/binary, "' ", X/binary>>
    }.

%% ====================================================================
%% Internal functions
%% ====================================================================


