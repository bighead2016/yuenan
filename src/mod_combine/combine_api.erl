%%% 合并
%%% 1.自检
%%% 2.创建全表
%%% 3.单表数据转移
-module(combine_api).

-include("const.common.hrl").

-export([main/0, init/0]).
-export([update_game_boss/1, update_game_guild_data/1, update_game_player/1,
         update_game_group/1, update_game_relation/1, update_game_arena_member/1]).

-define(ETS_USER,       ets_user).
-define(ETS_DB,         ets_db).
-define(ETS_NAME,       ets_name).
-define(ETS_CHANGE_NAME, ets_change_name).
-define(ETS_GUILD_ID,    ets_guild_id).
-define(ETS_DB_SID,    ets_db_sid).
-define(DIC_LAST_GUILD_ID,    dic_last_guild_id).
-define(WHERE_EFFECT,   " not (`cash_sum` <= '0' and `lv` <= '30' and unix_timestamp() - `logout_time_last` > '86400'*'20') ").
-define(WHERE_NULL,     " 1=2 ").
-define(FIELD_ALL,      ["*"]).
-define(INSERT_LIST, [
                    {game_player,       "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_bless_user,   "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_practice,     "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_tower_player, "`player_id` in ",  [<<"id">>], 2, 1},
                    {game_commerce,     "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_arena_member, "`player_id` in ",  ?FIELD_ALL, 2, 0},
                    {game_arena_reward, "`player_id` in ",  ?FIELD_ALL, 2, 0},
                    {game_horse,        "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_relation,     "`user_id` in ",    ?FIELD_ALL, 2, 0},
                    {game_offline,      "`user_id` in ",    [<<"id">>], 2, 1},
                    {game_offline_err,  "`user_id` in ",    [<<"id">>], 2, 1},
                    {game_group_apply,  "`user_id` in",     [<<"id">>], 2, 1},
                    {game_home,         "`user_id` in ",    [<<"id">>], 2, 1},
                    {game_mail,         "`recv_uid` in",    [<<"mail_id">>], 2, 1},
                    {game_player_rank,  "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_rank_equip,   "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_rank_partner, "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_arena_pvp,    "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_guild_member, "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_activity_stone_compose, "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_snow_info,    "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_card_exchange_partner, "`user_id` in", ?FIELD_ALL, 2, 0},
                    {game_party_doll,   "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_practice_doll, "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_rank_horse,    "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_resource_lookfor, "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_spring_doll,   "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_world_doll,    "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_guild_time,    "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_market_sale,   "`seller_id` in",   [<<"sale_id">>], 2, 1},
                    {game_active_welfare,"`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_archery_info,  "`user_id` in",     ?FIELD_ALL, 2, 0},
                    {game_encroach_info,  "`user_id` in",    ?FIELD_ALL, 2, 0},
                    {game_teach,          "`user_id` in",    ?FIELD_ALL, 2, 0},
                    {game_shop_secret_info,  "`user_id` in",    ?FIELD_ALL, 2, 0},
                    {game_mixed_serv_activity, "`userid` in",    ?FIELD_ALL, 2, 0},
					
                    {game_guild_pvp_boss_level,      "",    ?FIELD_ALL, 0, 1},
                    {game_market_search,    "",             [<<"id">>], 0, 1},
                    {game_commerce_market,  "",             [<<"id">>], 0, 1},
                    {game_market_buy,       "",             [<<"id">>], 0, 1},
%%                     {game_guild,            "",             [<<"guild_id">>], 0, 1},
                    {game_resource_pool,    "",             ?FIELD_ALL, 0, 0},
                    {game_activity_record,  "",             ?FIELD_ALL, 0, 0},
                    {game_tower_pass,       ?WHERE_NULL,    [<<"id">>], 0, 1},
                    {game_cash_old,         "",             ?FIELD_ALL, 0, 0},
                    {game_rank_guild,       ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_arena_champion_report, ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {game_caravan,          ?WHERE_NULL,    [<<"id">>], 0, 1},
                    {game_arena_report,     ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_cluster_node_config, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_change_name,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_config,           "",    ?FIELD_ALL, 0, 0},
                    {game_camp_data,        ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_copy_single_report, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_copy_single_report_idx, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_group,            ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_group_apply,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_guild_pvp,        ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_guild_pvp_log,    ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_hero_rank,        ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_honor_title,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_horse,            ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_old_server_user,  ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_rank_data,        ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_resource_pool,    ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_tower_report,     ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_tower_report_idx, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_guild_apply,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {game_team_invite_offline, ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {game_encroach_rank,    ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {game_shop_secret,      ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {game_guild_rank,       ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {techcenter_campaign_time, ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {techcenter_click_link, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_cost,       ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_daily_currency, ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {techcenter_gm,         ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_goods,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_item,       ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_link,       ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_log_cash,   ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_log_in_out, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_map,        ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_map_online, ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_online,     ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_open_sys,   ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_partner,    ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_pre_role,   ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_sys_name,   ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_task,       ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    {techcenter_task_open_sys, ?WHERE_NULL, ?FIELD_ALL, 0, 0},
                    {db_table_version,      ?WHERE_NULL,    ?FIELD_ALL, 0, 0},
                    
                    {log_deposit,           ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
                    {log_level_user_num,    ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
                    {log_lost_user,         ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
                    {log_review_user,       ?WHERE_NULL,            ?FIELD_ALL, 0, 1},
                    {log_create_user_stat,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_ability_camp,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_bless,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_boss,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_camp_battle,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_campaign,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_chess,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_currency,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_furnace,  ?WHERE_NULL,            ?FIELD_ALL, 0, 1},
					{log_data_goods,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_guild,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_guild_operate,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_link,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_login,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_login_check,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_logout,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_lv_up,  ?WHERE_NULL,            ?FIELD_ALL, 0, 1},
					{log_data_mail,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_mall,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_market,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_mcopy,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_mind,  ?WHERE_NULL,            ?FIELD_ALL, 0, 1},
					{log_data_partner,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_patrol,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_rank,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_recharge,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_reconnect,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_robot,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_shop_secret,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_sig_arena,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_single_arena,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_skill,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_stren,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_task,  ?WHERE_NULL,            ?FIELD_ALL, 0, 1},
					{log_data_tower,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_transpoint,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_user,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_user_create,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_data_world,  ?WHERE_NULL,             ?FIELD_ALL, 0, 1},
					{log_deposit,  "",             ?FIELD_ALL, 0, 1},
					{log_level_user_num,  "",             ?FIELD_ALL, 0, 1},
					{log_lost_user,  "",             ?FIELD_ALL, 0, 1},
					{log_recharge,  "",             ?FIELD_ALL, 0, 1},
					{log_review_user,  "",             ?FIELD_ALL, 0, 1},
                    {game_code,             ?WHERE_NULL,    ?FIELD_ALL, 0, 0}
                  ]).
-define(UPDATE_LIST, 
        [
            {game_boss,         ?MODULE, update_game_boss,         ?null},
            {game_guild_data,   ?MODULE, update_game_guild_data,   ?null},
            {game_group,        ?MODULE, update_game_group,        ?null},
            {game_relation,     ?MODULE, update_game_relation,     ?null},
            {game_arena_member, ?MODULE, update_game_arena_member, ?null}
        ]).

%%---------------------------------------------------------
main() ->
    try
        % 1.init db connection
    	{SrcDbList, TargetDb, SourceDb} = init(),
        % 2.create all tables from source
        ResultList  = show_all_tables(SourceDb),
        create_tables(ResultList, TargetDb),
        % 3.检查每个库的结构是否一致，有可能会改动原先的库，以使之与目标库一致 
        fix_tables(TargetDb, SrcDbList),
        % 4.插入数据
        insert_data_inner_1(TargetDb, SrcDbList),
        insert_data_inner_2(TargetDb, SrcDbList, ?INSERT_LIST),
        insert_data_table_3(TargetDb, SrcDbList),
        % 5.更新数据
        update_data(TargetDb, ?UPDATE_LIST)
    catch
        X:Y ->
            ?MSG_SYS("~p~n~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
    do_end().
%%---------------------------------------------------------

init() ->
    combine_mod:init_ets([{?ETS_USER, 1}, {?ETS_DB, 1}, {?ETS_NAME, 1}, 
                          {?ETS_CHANGE_NAME, 1}, {?ETS_GUILD_ID, 1},
                          {?ETS_DB_SID, 1}]),
    case combine_mod:load_config() of
        {SrcDbList, TargetDb, SourceDbName} ->
            {SrcDbList, TargetDb, SourceDbName};
        Reason ->
            do_end(Reason)
    end.

do_end() ->
    List = ets:tab2list(?ETS_DB),
    List2 = [Table||{Table, State}<-List, State =:= 0],
    if
        [] =:= List2 ->
            ?MSG_SYS("all table changed.", []);
        ?true ->
            ?MSG_SYS("~nno change table:~n~p~ndone.", [List2])
    end,
    do_end(normal).
do_end(Reason) ->
    ?MSG_SYS("stop[~p].", [Reason]),
    erlang:halt().

%%-----------插入数据---------------------------------
%% , [{game_user,         ?WHERE_EFFECT,      ?FIELD_ALL, 1, 0},]
insert_data_inner_1(TargetDb, SrcDbList) ->
    insert_data_inner_1(TargetDb, SrcDbList, [{game_user, ?WHERE_EFFECT, ?FIELD_ALL, 1, 0}]),
    % 更新重名玩家信息
    insert_user_data(TargetDb),
    insert_game_guild(TargetDb, SrcDbList),
    insert_game_guild_pvp_app(TargetDb, SrcDbList),
    ok.

%% [{Table, Where, Fields, Func, IsOn}|Tail] 
insert_game_guild(TargetDb, [Db|Tail]) ->
    insert_game_guild_single(TargetDb, Db),
    insert_game_guild(TargetDb, Tail);
insert_game_guild(_TargetDb, []) ->
    ok.

insert_game_guild_pvp_app(TargetDb, [Db|_]) ->
    [{_, ResultList}] = combine_db_mod:execute({select, Db, 'game_guild_pvp_app', "", ?FIELD_ALL}, [Db]),
    ?MSG_SYS("ok|--tab[~p|~p->~p]", ['game_guild_pvp_app', Db, TargetDb]),
    Len = erlang:length(ResultList),
    insert_game_guild_pvp_app_single(Db, TargetDb, ResultList, Len, 0),
    update_table_state('game_guild_pvp_app'),
    ok;
insert_game_guild_pvp_app(_TargetDb, _) ->
    ok.

insert_game_guild_pvp_app_single(Db, TargetDb, [[OldGuildId|GuildInfo]|Tail], Len, Count) ->
    {_, NewGuildId} = ets_api:lookup(?ETS_GUILD_ID, {Db, OldGuildId}),
    {Fields2, Values} = mysql_single_api:make_some_sql([NewGuildId|GuildInfo], TargetDb, 'game_guild_pvp_app', ""),
    combine_db_mod:execute({insert, 'game_guild_pvp_app', Fields2, Values}, [TargetDb]),
    combine_db_mod:execute({update_db, 'game_guild_pvp_app', Count}, [TargetDb]),
    insert_game_guild_pvp_app_single(Db, TargetDb, Tail, Len, Count);
insert_game_guild_pvp_app_single(_, _, _, _, _) ->
    ok.
    

%% [{Table, Where, Fields, Func, IsOn}|Tail] 
insert_data_inner_1(TargetDb, [Db|Tail], TableList) ->
    insert_data_table(TargetDb, Db, TableList),
    insert_data_inner_1(TargetDb, Tail, TableList);
insert_data_inner_1(_TargetDb, [], _TableList) ->
    ok.

%% [{Table, Where, Fields, Func, IsOn}|Tail] 
insert_data_inner_2(TargetDb, [Db|Tail], TableList) ->
    insert_data_table(TargetDb, Db, TableList),
    update_game_player(TargetDb),
    insert_data_inner_2(TargetDb, Tail, TableList);
insert_data_inner_2(_TargetDb, [], _TableList) ->
    ok.

insert_user_data(TargetDb) ->
    NameList = get_not_uniq_name(),
    insert_user_data(TargetDb, NameList).
insert_user_data(TargetDb, [{Name, Count, ServList}|Tail]) ->
    Sql = <<"insert into `db_name_info` values ('", (misc:to_binary(Name))/binary, 
            "', '", (misc:to_binary(Count))/binary, 
            "', '", (misc:encode(ServList))/binary, "');">>,
    combine_db_mod:execute({execute, Sql}, [TargetDb]),
    %
    insert_change_name(TargetDb, ServList, Name),
    insert_user_data(TargetDb, Tail);
insert_user_data(_TargetDb, []) ->
    ok.

insert_change_name(TargetDb, [{UserId, ServId}|Tail], Name) ->
    combine_db_mod:execute({insert, 'game_change_name', <<"`user_id`">>, 
                            <<" '", (misc:to_binary(UserId))/binary, "' ">>}, 
                           [TargetDb]),
    combine_mod:insert_ets_change_name(UserId, ServId, Name),
    insert_change_name(TargetDb, Tail, Name);
insert_change_name(_TargetDb, [], _Name) ->
    ok.

get_not_uniq_name() ->
    NameList = ets:tab2list(?ETS_NAME),
    NameList2 = [{N, C, L}||{N, C, L}<-NameList, C > 1],
    NameList2.

insert_game_guild_single(TargetDb, Db) ->
    [{_, ResultList}] = combine_db_mod:execute({select, Db, 'game_guild', "", ?FIELD_ALL}, [Db]),
    ?MSG_SYS("ok|--tab[~p|~p->~p]", ['game_guild', Db, TargetDb]),
    Len = erlang:length(ResultList),
    insert_game_guild_single(Db, TargetDb, ResultList, Len, 0),
    update_table_state('game_guild'),
    ok.
insert_game_guild_single(Db, TargetDb, [[OldGuildId|GuildTail]|Tail], Len, Count) ->
    NewGuildId = get_next_guild_id(),
    ets:insert(?ETS_GUILD_ID, {{Db, OldGuildId}, NewGuildId}),
    {Fields2, Values} = mysql_single_api:make_some_sql([NewGuildId|GuildTail], TargetDb, 'game_guild', ""),
    combine_db_mod:execute({insert, 'game_guild', Fields2, Values}, [TargetDb]),
    combine_db_mod:execute({update_db, 'game_guild', Count}, [TargetDb]),
    insert_game_guild_single(Db, TargetDb, Tail, Len, Count);
insert_game_guild_single(_Db, _TargetDb, [], _, _) ->
    ok.

get_next_guild_id() ->
    case erlang:get(?DIC_LAST_GUILD_ID) of
        undefined ->
            erlang:put(?DIC_LAST_GUILD_ID, 1),
            1;
        X ->
            X2 = X+1,
            erlang:put(?DIC_LAST_GUILD_ID, X2),
            X2
    end.

insert_data_table(TargetDb, Db, [{Table, Where, Fields, Func, IsOn}|Tail]) ->
    NewWhere = 
        case Func of
            2 ->
                UserIdList = get_user_list(Db),
                if
                    [] =/= UserIdList ->
                        L = change_to_id_list(UserIdList, <<"">>),
                        <<(misc:to_binary(Where))/binary, L/binary>>;
                    ?true ->
                        <<" 1=2 ">>
                end;
            _ ->
                Where
        end,
    NewLen = 
        case IsOn of
            0 ->
                [{_, ResultList}] = combine_db_mod:execute({select, Db, Table, NewWhere, Fields}, [Db]),
                ?MSG_SYS("ok|--tab[~p|~p->~p]", [Table, Db, TargetDb]),
                Len = erlang:length(ResultList),
                insert_data_table_2(Db, ResultList, TargetDb, Table, Fields, Func, Len, 0),
                Len;
            1 ->
                Fields_2 = mysql_single_api:get_fields(Db, Table, Fields),
                combine_db_mod:execute({insert_all_where, Table, Db, Table, Fields_2, NewWhere}, [TargetDb]),
                ?MSG_SYS("ok|--tab[~p|~p->~p]", [Table, Db, TargetDb]),
                0
        end,
    update_table_state(Table),
    combine_db_mod:execute({update_db, Table, NewLen}, [TargetDb]),
    insert_data_table(TargetDb, Db, Tail);
insert_data_table(_TargetDb, _Db, []) ->
    ok.

insert_data_table_2(SourceDb, [ResultList|Tail], TargetDb, Table, Fields, Func, Len, Count) ->
    {Fields2, Values} = mysql_single_api:make_some_sql(ResultList, TargetDb, Table, Fields),
    if
        Fields2 =/= <<>> andalso Values =/= <<>> ->
            combine_db_mod:execute({insert, Table, Fields2, Values}, [TargetDb]),
            insert_data_table_ext(SourceDb, ResultList, Func),
            ?MSG_SYS_ROLL("ok|~p/~p", [Count, Len]);
        true ->
            ?MSG_SYS("[~n~p~n~p~n~p~n~p~n]", [Fields, Fields2, ResultList, Values]),
            ok
    end,
    insert_data_table_2(SourceDb, Tail, TargetDb, Table, Fields, Func, Len, Count+1);
insert_data_table_2(_SourceDb, [], _, _Table, _, _, Len, Count) ->
    ?MSG_SYS("ok|~p/~p", [Count, Len]),
    ok.

insert_data_table_ext(_, _, 0) ->
    ok;
insert_data_table_ext(SourceDb, [UserId, UserName, ServId|_], 1) ->
    case ets:lookup(?ETS_USER, 0) of
        [] ->
            ets:insert(?ETS_USER, {0, [UserId]});
        [{_, List}] ->
            ets:insert(?ETS_USER, {0, [UserId|List]})
    end,
    case ets:lookup(?ETS_USER, SourceDb) of
        [] ->
            ets:insert(?ETS_USER, {SourceDb, [UserId]});
        [{_, List2}] ->
            ets:insert(?ETS_USER, {SourceDb, [UserId|List2]})
    end,
    case ets:lookup(?ETS_NAME, UserName) of
        [] ->
            ets:insert(?ETS_NAME, {UserName, 1, [{UserId, ServId}]});
        [{_, OldCount, OldList}|_] ->
            ets:insert(?ETS_NAME, {UserName, OldCount+1, [{UserId, ServId}|OldList]})
    end,
    case ets:lookup(?ETS_DB_SID, ServId) of
        [] ->
            ets:insert(?ETS_DB_SID, {ServId, SourceDb});
        [{_, _}|_] ->
            ok
    end;
insert_data_table_ext(_, _Value, _) ->
    ok.

%%------------------------------------------------------------------------------
%% 默认处理剩下的表
insert_data_table_3(TargetDb, SrcDbList) ->
    TabList = ets:tab2list(?ETS_DB),
    TabList2 = [Tab||{Tab, State}<-TabList, State =:= 0],
    TabList3 = lists:reverse(TabList2),
    insert_data_ext(TargetDb, SrcDbList, TabList3).
insert_data_ext(TargetDb, SrcDbList, [Tab|Tail]) ->
    insert_data_ext_2(TargetDb, SrcDbList, Tab, 0, 0),
    insert_data_ext(TargetDb, SrcDbList, Tail);
insert_data_ext(_TargetDb, _, []) ->
    ok.

insert_data_ext_2(TargetDb, [Db|Tail], Table, Len, Count) ->
    [{_, ResultList}] = combine_db_mod:execute({select, Db, Table, "", "*"}, [Db]),
    LenRes = erlang:length(ResultList),
    ?MSG_SYS("ok|--tab[~p|~p->~p]", [Table, Db, TargetDb]),
    insert_data_ext_3(ResultList, TargetDb, Db, Table, LenRes, 0),
    insert_data_ext_2(TargetDb, Tail, Table, Len, Count+1);
insert_data_ext_2(_TargetDb, [], _Table, _Len, _Count) ->
    ok.

insert_data_ext_3([ResultList|Tail], TargetDb, Db, Table, Len, Count) ->
    {Fields2, Values} = mysql_single_api:make_some_sql(ResultList, Db, Table, ?FIELD_ALL),
    combine_db_mod:execute({insert, Table, Fields2, Values}, [TargetDb]),
    ?MSG_SYS_ROLL("ok|~p/~p", [Count, Len]),
    insert_data_ext_3(Tail, TargetDb, Db, Table, Len, Count+1);
insert_data_ext_3([], TargetDb, _Db, Table, Len, Count) ->
    ?MSG_SYS("ok|~p/~p", [Count, Len]),
    combine_db_mod:execute({update_db, Table, Len}, [TargetDb]),
    update_table_state(Table),
    ok.

%%------------------------------------------------------------------------------
%% 读取玩家id列表
get_user_list(Db) ->
    case ets:lookup(?ETS_USER, Db) of
        [] ->
            [];
        [{_, List}] ->
            List
    end.

update_table_state(Table) ->
    ets:update_element(?ETS_DB, Table, [{2, 1}]).

%% 转换id列表成binary字段
change_to_id_list([UserId], OldList) ->
    NewList = <<OldList/binary, " '", (misc:to_binary(UserId))/binary, "' ">>,
    change_to_id_list([], NewList);
change_to_id_list([UserId|Tail], OldList) ->
    NewList = <<OldList/binary, " '", (misc:to_binary(UserId))/binary, "', ">>,
    change_to_id_list(Tail, NewList);
change_to_id_list([], List) ->
    <<"(", List/binary, ")">>.

%%-----------查看库中所有表创建信息---------------------------------
show_all_tables(Source) ->
    ResultList  = show_tables([Source], []),
    ResultList2 = lists:reverse(ResultList),
    ResultList2.

show_tables([DbId|Tail], OldList) ->
    [{_, TableList}] = combine_db_mod:execute('show_all_tables', [DbId]),
    ResultList = show_create_table(TableList, DbId, []),
    List2 = [{DbId, ResultList}|OldList],
    show_tables(Tail, List2);
show_tables([], List) ->
    List.

show_create_table([[TableName]|Tail], DbId, OldList) ->
    [{_, [[_, ResultList]]}] = combine_db_mod:execute({'show_create_table', TableName}, [DbId]),
    RList = [{TableName, ResultList}|OldList],
    show_create_table(Tail, DbId, RList);
show_create_table([], _, List) ->
    List.

%%------------------创建表------------------------------------------------
create_tables([{_, TableList}|Tail], Target) ->
    combine_db_mod:execute({drop_table, 'db_table_state'}, [Target]),
    combine_db_mod:execute('create_tab_db', [Target]),
    ?MSG_SYS("ok|recreate table [db_table_state]", []),
    create_tables_2(TableList, Target),
    create_tables(Tail, Target);
create_tables([], Target) ->
    combine_db_mod:execute({drop_table, 'game_change_name'}, [Target]),
    combine_db_mod:execute({create_table, 'game_change_name'}, [Target]),
    combine_db_mod:execute({drop_table, 'game_change_name_guild'}, [Target]),
    combine_db_mod:execute({create_table, 'game_change_name_guild'}, [Target]),
    combine_db_mod:execute({drop_table, 'db_name_info'}, [Target]),
    combine_db_mod:execute({create_table, 'db_name_info'}, [Target]),
    ok.

create_tables_2([{TableName, TableSql}|Tail], Target) ->
    combine_db_mod:execute({drop_table, TableName},  [Target]),
    combine_db_mod:execute({create_table, TableSql}, [Target]),
    TableNameAtom = misc:to_atom(TableName),
    ?MSG_SYS("ok|create table [~p]", [TableNameAtom]),
    combine_db_mod:execute({insert, TableName}, [Target]),
    ets:insert(?ETS_DB, {TableNameAtom, 0}),
    create_tables_2(Tail, Target);
create_tables_2([], _) ->
    ok.

%%----------------修正表结构------------------------------------------------
fix_tables(TargetDb, SrcDbList) ->
    [{_, TableList}] = combine_db_mod:execute('show_all_tables', [TargetDb]),
    fix_tables(TargetDb, SrcDbList, TableList).
fix_tables(Targetdb, SrcDbList, [[Table]|Tail]) ->
    fix_table(Table, Targetdb, SrcDbList),
    fix_tables(Targetdb, SrcDbList, Tail);
fix_tables(_, _, []) ->
    ok.

fix_table(Table, TargetDb, [SrcDb|Tail]) ->
    TgtStructList = mysql_single_api:desc(TargetDb, Table),
    SrcStructList = mysql_single_api:desc(SrcDb, Table),
    case fix_struct(TgtStructList, SrcStructList, TgtStructList) of
        {SrcField, LastField} ->
            [{_, Desc}] = combine_db_mod:execute({show_column, TargetDb, Table, SrcField}, [TargetDb]),
            ?MSG_SYS("~p|~p", [SrcField, Desc]),
            Desc2 = make_desc(Desc),
            combine_db_mod:execute({alter_table, Table, SrcField, Desc2, LastField}, [SrcDb]),
            ?MSG_SYS("ok|fixed[~p]:~p|~p|~s", [Table, SrcField, LastField, Desc2]),
            fix_table(Table, TargetDb, [SrcDb|Tail]);
        ok ->
            ?MSG_SYS("ok|no need fix[~p]", [Table]),
            fix_table(Table, TargetDb, Tail)
    end;
fix_table(_, _, []) ->
    ok.

fix_struct([[TgtField|_]|TgtTail], [[TgtField|_]|SrcTail], TgtStructList) ->
    fix_struct(TgtTail, SrcTail, TgtStructList);
fix_struct([[TgtField|_]|_TgtTail], [[_SrcField|_]|_SrcTail], TgtStructList) ->
    LastField = find_last_field(TgtField, TgtStructList, 0),
    {TgtField, LastField};
fix_struct([], [], _) ->
    ok;
fix_struct(X, Y, _) ->
    ?MSG_SYS("f[~p|~p]", [X, Y]),
    ok.

find_last_field(Field, [[Field|_]|_SrcTail], LastField) ->
    LastField;
find_last_field(Field, [[SrcField|_]|SrcTail], _) ->
    find_last_field(Field, SrcTail, SrcField);
find_last_field(_, [], _LastField) ->
    null.

make_desc([[Field,Type,IsNull,Def,Comment]]) ->
    NullBin = 
        if
            <<"NO">> =:= IsNull ->
                <<"`", Field/binary, "` ", Type/binary, " not null ">>;
            true ->
                <<"`", Field/binary, "` ", Type/binary, " ">>
        end,
    if
        undefined =:= Def ->
            <<NullBin/binary, " comment '", Comment/binary, "' ">>;
        true ->
            <<NullBin/binary, " default '", Def/binary, "' comment '", Comment/binary, "' ">>
    end.
    

%%----------------更新数据------------------------------------------------
update_data(TargetDb, [{Table, Mod, Func, ?null}|Tail]) ->
    ?MSG_SYS("--trans[~p]", [Table]),
    Mod:Func(TargetDb),
    update_data(TargetDb, Tail);
update_data(TargetDb, [{Table, Mod, Func, Args}|Tail]) ->
    ?MSG_SYS("--trans[~p]", [Table]),
    Mod:Func(TargetDb, Args),
    update_data(TargetDb, Tail);
update_data(_TargetDb, []) ->
    ok.

%% 更新game_boss
update_game_boss(TargetDb) ->
    combine_db_mod:execute({create_table, game_boss_tmp}, [TargetDb]),
    combine_db_mod:execute({insert_all, game_boss_tmp, TargetDb, game_boss, <<" `lv` ">>}, [TargetDb]),
    combine_db_mod:execute({truncate_table, game_boss}, [TargetDb]),
    combine_db_mod:execute(update_game_boss_max, [TargetDb]),
    combine_db_mod:execute({drop_table, game_boss_tmp}, [TargetDb]),
    ok.

%% game_guild_data
update_game_guild_data(TargetDb) ->
    combine_mod:game_guild_data(TargetDb).

%%
update_game_player(TargetDb) ->
    [{_, [[Total]]}]  = combine_db_mod:execute({select_count, game_player}, [TargetDb]),
    [{_, RecordList}] = combine_db_mod:execute({select, TargetDb, game_player, "", <<" `user_id`, `info`, `guild` ">>}, [TargetDb]),
    combine_mod:trans_module(TargetDb, 'game_player', Total, RecordList, fun combine_mod:game_player/2).

%%
update_game_group(TargetDb) ->
    [{_, [[Total]]}]  = combine_db_mod:execute({select_count, game_group}, [TargetDb]),
    [{_, RecordList}] = combine_db_mod:execute({select, TargetDb, game_group, "", <<" `id`,`member_list` ">>}, [TargetDb]),
    combine_mod:trans_module(TargetDb, 'game_group', Total, RecordList, fun combine_mod:game_group/2).

%%
update_game_relation(TargetDb) ->
    [{_, [[Total]]}]  = combine_db_mod:execute({select_count, game_relation}, [TargetDb]),
    [{_, RecordList}] = combine_db_mod:execute({select, TargetDb, game_relation, "", 
                                                <<" `user_id`,`friend_list`,`best_list`,`black_list` ">>}, 
                                               [TargetDb]),
    combine_mod:trans_module(TargetDb, 'game_relation', Total, RecordList, fun combine_mod:game_relation/2).

%%
update_game_arena_member(TargetDb) ->
    combine_db_mod:execute({create_table, game_arena_member_tmp}, [TargetDb]),
    Fields = mysql_single_api:get_fields(TargetDb, game_arena_member, [<<"id">>, <<"rank">>]),
    combine_db_mod:execute({insert_all, game_arena_member_tmp, TargetDb, game_arena_member, Fields, <<" order by `fight_force` desc ">>}, [TargetDb]),
    
    combine_db_mod:execute({truncate_table, game_arena_member}, [TargetDb]),
    Fields2 = mysql_single_api:get_fields(TargetDb, game_arena_member, [<<"id">>]),
    combine_db_mod:execute({insert_all, game_arena_member, TargetDb, game_arena_member_tmp, Fields2}, [TargetDb]),
    combine_db_mod:execute({drop_table, game_arena_member_tmp}, [TargetDb]),
    ok.

