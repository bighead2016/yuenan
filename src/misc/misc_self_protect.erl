%%% 系统自我保护机制
%%% 1.table self protect

-module(misc_self_protect).

-include("const.common.hrl").

-export([upgrate_db/0, clear_db/0, trans_data/0, upgrate_db_center/0]).

-define(PATH_SQL_BASE, "../sql_data/server/base.sql").
-define(PATH_SQL_DATA, "../sql_data/server/alter/").

-define(PATH_SQL_BASE_C, "../sql_data/center/c_base.sql").
-define(PATH_SQL_DATA_C, "../sql_data/center/alter/").

-define(PATH_ALTER, "/").
-define(SQL_CONFIG, <<"CREATE TABLE `config_version` (",
                        "`table` char(255) NOT NULL COMMENT '表名', ",
                        "`time` int(11) NOT NULL COMMENT '时间', ", 
                        "PRIMARY KEY  (`table`)",
                      ") ENGINE=InnoDB DEFAULT CHARSET=utf8;">>).

%% 数据库表升级
upgrate_db() ->
    DirList = ls_dir(?PATH_SQL_DATA),
    SqlList = ls_sql(?PATH_SQL_DATA, ?PATH_ALTER, DirList, [?PATH_SQL_BASE]),
    try
        ?MSG_SYS("sql files:~n~p", [SqlList]),
        SqlList3 = read_sql(SqlList, []),
        c:cd("../ebin"),
        misc_sys:init(),
        mysql_api:start(),
        SqlConfig = <<"select * from `config_version`;">>,
        ConfigList2 = 
            case mysql_api:select(SqlConfig) of
                {ok, ConfigList} ->
                    ConfigList;
                _ ->
                    mysql_api:select(?SQL_CONFIG),
                    []
            end,
        execute_sql(ConfigList2, SqlList3),
        misc_killer:do_kill()
    catch
        Type:Why ->
            ?MSG_SYS("~p|~p~n~p", [Type, Why, erlang:get_stacktrace()])
    end,
    erlang:halt().

%% 中心数据库表升级
upgrate_db_center() ->
    DirList = ls_dir(?PATH_SQL_DATA_C),
    SqlList = ls_sql(?PATH_SQL_DATA_C, ?PATH_ALTER, DirList, [?PATH_SQL_BASE_C]),
    try
        ?MSG_SYS("sql files:~n~p", [SqlList]),
        SqlList3 = read_sql(SqlList, []),
        c:cd("../ebin"),
        misc_sys:init(),
        mysql_api:start(),
        SqlConfig = <<"select * from `config_version`;">>,
        ConfigList2 = 
            case mysql_api:select(SqlConfig) of
                {ok, ConfigList} ->
                    ConfigList;
                _ ->
                    mysql_api:select(?SQL_CONFIG),
                    []
            end,
        execute_sql(ConfigList2, SqlList3)
    catch
        Type:Why ->
            ?MSG_SYS("~p|~p~n~p", [Type, Why, erlang:get_stacktrace()])
    end,
    erlang:halt().

%% 读取所有sql
read_sql([SqlFile|Tail], OldList) ->
    case file:read_file(SqlFile) of
        {ok, SqlInner} ->
            SqlInner2 = remove_escape(SqlInner, <<>>),
            SqlList = re:split(SqlInner2, ";"),
            read_sql(Tail, OldList++[{SqlFile, SqlList}]);
        {error, Reason} ->
            ?MSG_SYS("err:~p", [Reason]),
            []
    end;
read_sql([], L) ->
    L.

%% 子文件
ls_sql(UpDir, SecDir, [SubDir|Tail], OldList) ->
    T = UpDir++SubDir++SecDir,
    L = filelib:wildcard("*.sql", T),
    L2 = [T++Data||Data<-L],
    ls_sql(UpDir, SecDir, Tail, OldList++L2);
ls_sql(_, _, [], L) ->
    L.

%% 子目录
ls_dir(Dir) ->
    case file:list_dir(Dir) of
        {ok, DirList} ->
            lists:sort(DirList);
        _ ->
            []
    end.

%% 去掉不应该存在的字符
remove_escape(<<13:8, Tail/binary>>, OldAcc) ->
    remove_escape(Tail, <<OldAcc/binary, " ">>);
remove_escape(<<10:8, Tail/binary>>, OldAcc) ->
    remove_escape(Tail, <<OldAcc/binary, " ">>);
remove_escape(<<X:8, Tail/binary>>, OldAcc) ->
    remove_escape(Tail, <<OldAcc/binary, X>>);
remove_escape(<<>>, Acc) ->
    Acc.

execute_sql(ConfigList, [{SqlFile, Sql}|Tail]) ->
    ?MSG_SYS_ROLL("[ing][~p]...", [SqlFile]),
    case is_mem(ConfigList, SqlFile) of
        true ->
            ?MSG_SYS("[loaded][~p]...", [SqlFile]),
            ok;
        false ->
            case execute_sql_2(Sql, true) of
                true ->
                    SqlInsert = <<"insert into `config_version` values ('", 
                                       (misc:to_binary(SqlFile))/binary, "', '", 
                                       (misc:to_binary((misc:seconds())))/binary, "');">>,
                    mysql_api:insert(SqlInsert),
                    ?MSG_SYS("[done][~p]...", [SqlFile]),
                    ok;
                false ->
                    ?MSG_SYS("[err][~p]...", [SqlFile]),
                    ok
            end,
            if
                ?PATH_SQL_BASE =:= SqlFile ->
                    Sid = config:read_deep([server, base, sid]),
                    Trunc = erlang:trunc((Sid - 1) * 100000 + 1),
                    SqlAdd = <<"alter table `game_user` auto_increment=", (misc:to_binary(Trunc))/binary, ";">>,
                    mysql_api:insert(SqlAdd),
                    ?MSG_SYS("[ing][~p] changed game_user auto_increment...", [SqlFile]),
                    ok;
                true ->
                    ok
            end
    end,
    execute_sql(ConfigList, Tail);
execute_sql(_, []) ->
    ok.

is_mem([[Tab, _Sec]|Tail], SqlFile) ->
    SqlFile2 = misc:to_list(SqlFile),
    case misc:to_list(Tab) of
        SqlFile2 ->
            true;
        _ ->
            is_mem(Tail, SqlFile)
    end;
is_mem([], _) ->
    false.

execute_sql_2([<<>>|Tail], Res) ->
    execute_sql_2(Tail, Res);
execute_sql_2([Sql|Tail], Res) ->
    case is_empty(Sql) of
        true ->
            execute_sql_2(Tail, Res);
        false ->
            case mysql_api:select(Sql) of
                {ok, _, _} ->
                    execute_sql_2(Tail, Res);
                {error, X} ->
                    ?MSG_SYS("false:~p", [X]),
                    false
            end
    end;
execute_sql_2([], Res) ->
    Res.

%% 空串?
is_empty(<<32:8, Tail/binary>>) ->
    is_empty(Tail);
is_empty(<<>>) ->
    true;
is_empty(<<_X:8, _Tail/binary>>) ->
    false.

%%================================================================================
%% 清库
clear_db() ->
    try
        c:cd("../ebin"),
        misc_sys:init(),
        mysql_api:start(),
        SqlShowTab = <<"show tables;">>,
        case mysql_api:select(SqlShowTab) of
            {ok, TabList} ->
                clear_db_2(TabList);
            {error, Reason} ->
                ?MSG_SYS("err:~p", [Reason]),
                []
        end
    catch
        Type:Why ->
            ?MSG_SYS("~p|~p~n~p", [Type, Why, erlang:get_stacktrace()])
    end,
    erlang:halt().

clear_db_2([[<<"config_version">>]|Tail]) ->
    clear_db_2(Tail);
clear_db_2([[<<"config_trans_version">>]|Tail]) ->
    clear_db_2(Tail);
clear_db_2([[<<"game_config">>]|Tail]) ->
    clear_db_2(Tail);
clear_db_2([[<<"game_user">> = Tab]|Tail]) ->
    Sql = <<"truncate `", (misc:to_binary(Tab))/binary, "`;">>,
    ?MSG_SYS_ROLL("[ing]clear [~p]... ", [Tab]),
    case mysql_api:select(Sql) of
        {ok, _, _} ->
            ?MSG_SYS("[done]clear [~p]... ", [Tab]),
            Sid = config:read_deep([server, base, sid]),
            Trunc = erlang:trunc((Sid - 1) * 100000 + 1),
            SqlAdd = <<"alter table `game_user` auto_increment=", (misc:to_binary(Trunc))/binary, ";">>,
            mysql_api:insert(SqlAdd),
            ?MSG_SYS("[ing] changed game_user auto_increment...", []),
            clear_db_2(Tail);
        {error, Reason} ->
            ?MSG_SYS("[err]clear [~p][~p]... ", [Tab, Reason]),
            ok
    end;
clear_db_2([[Tab]|Tail]) ->
    Sql = <<"truncate `", (misc:to_binary(Tab))/binary, "`;">>,
    ?MSG_SYS_ROLL("[ing]clear [~p]... ", [Tab]),
    case mysql_api:select(Sql) of
        {ok, _, _} ->
            ?MSG_SYS("[done]clear [~p]... ", [Tab]),
            clear_db_2(Tail);
        {error, Reason} ->
            ?MSG_SYS("[err]clear [~p][~p]... ", [Tab, Reason]),
            ok
    end;
clear_db_2([]) ->
    ok.

%%================================================================================
%% 数据转换
trans_data() ->
    try
        c:cd("../ebin"),
        misc_sys:init(),
        mysql_api:start(),
        Sql = <<"select `version` from `game_config`;">>,
        case mysql_api:select(Sql) of
            {ok, [[Ver]]} ->
                case file:consult("../run/trans.config") of
                    {ok, TermList} ->
                        Ver2 = misc:to_float(Ver),
                        case lists:keytake(ver, 1, TermList) of
                            {value, {_, NewVer}, TermList2} ->
                                TermList3 = lists:keysort(1, TermList2),
                                trans_data(TermList3, Ver2, NewVer),
                                ok;
                            false ->
                                ok
                        end;
                    {error, Reason} ->
                        ?MSG_SYS("err:~p", [Reason]),
                        ok
                end;
            {ok, []} ->
                ?MSG_SYS("err:no info", []),
                [];
            {error, Reason} ->
                ?MSG_SYS("err:~p", [Reason]),
                []
        end
    catch
        Type:Why ->
            ?MSG_SYS("~p|~p~n~p", [Type, Why, erlang:get_stacktrace()])
    end,
    erlang:halt().

trans_data([{Ver, TransList}|Tail], OldVer, NewVer) when Ver =< NewVer andalso OldVer < Ver ->
    Sql = <<"select `trans` from `config_trans_version` where `ver`='", (misc:to_binary(Ver))/binary, "';">>,
    case mysql_api:select(Sql) of
        {ok, TL} ->
            ?MSG_SYS("~p|~p", [Ver, TL]),
            trans_data_2(TransList, Ver, TL);
        {error, Reason} ->
            ?MSG_SYS("!err:~p", [Reason]),
            ok
    end,
    trans_data(Tail, OldVer, NewVer);
trans_data([_|Tail], OldVer, NewVer) ->
    trans_data(Tail, OldVer, NewVer);
trans_data([], _, NewVer) ->
    mysql_api:update(<<"update `game_config` set `version` = '", (misc:to_binary(NewVer))/binary, "';">>),
    ok.

trans_data_2([{Ver, M, F, A}|Tail], Ver2, TL) ->
    case is_member(TL, Ver) of
        true ->
            ok;
        false ->
            erlang:apply(M, F, A),
            mysql_api:update(<<"insert `config_trans_version`(`ver`,`trans`) values ('", 
                               (misc:to_binary(Ver2))/binary, "','", (misc:to_binary(Ver))/binary, "');">>)
    end,
    trans_data_2(Tail, Ver2, TL);
trans_data_2([], _, _) ->
    ok.

is_member([[Tid]|Tail], Ver) ->
    ?MSG_SYS("~p|~p", [Tid, Ver]),
    Tid2 = misc:to_list(Tid),
    case misc:to_list(Ver) of
        Tid2 ->
            true;
        _ ->
            is_member(Tail, Ver)
    end;
is_member([], _) ->
    false.

%%---查cpu/mem,到了阀值就kill,并写日志
get_cpu_top() ->
    ok.
