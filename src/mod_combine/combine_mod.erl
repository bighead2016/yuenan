%%% 合并处理工具

-module(combine_mod).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").

-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").

-define(CONFIG_FILE,    "combine.config").
-define(ETS_CHANGE_NAME, ets_change_name).
-define(ETS_GUILD_ID,    ets_guild_id).
-define(ETS_DB_SID,    ets_db_sid).
-define(SQL_GUILD_DATA_INFO, <<"select `guild_id`,`guild_name`,`chief_id`,`member_list`,`pos_list` from `game_guild`;">>).
-define(SQL_GUILD_MEMBER,    <<"select `user_id`,`guild_id` from `game_guild_member`;">>).
-define(UPDATE_NAME_LIST, [
                           {game_arena_member,  "player_name"},
                           {game_arena_pvp,     "user_name"},
                           {game_caravan,       "user_name"},
                           {game_caravan,       "friend_name"},
                           {game_group,         "name"},
                           {game_guild,         "chief_name"},
                           {game_guild,         "create_name"},
                           {game_guild_apply,   "user_name"},
                           {game_guild_member,  "user_name"},
                           {game_mail,          "send_name"},
                           {game_mail,          "recv_name"},
                           {game_market_buy,    "seller_name"},
                           {game_market_buy,    "buyer_name"},
                           {game_market_sale,   "seller_name"},
                           {game_market_sale,   "buyer_name"},
                           {game_player_rank,   "user_name"},
                           {game_rank_data,     "user_name"},
                           {game_rank_data,     "other_name"},
                           {game_rank_equip,    "user_name"},
                           {game_rank_partner,  "user_name"},
                           {game_tower_pass,    "first_name"}
                          ]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([load_config/0, init_ets/1, trans_module/5, insert_ets_change_name/3,
         insert_ets_guild_id/3]).
-export([game_guild_data/1, game_player/2, game_group/2, game_relation/2]).

%%--------------------------------------------------------
load_config() ->
    try
        FileName         = ?DIR_CONFIG_ROOT ++ ?CONFIG_FILE,
        Datas            = misc_app:load_file(FileName),
        % source
        SourceList       = read_field(Datas, source, list),
        SourceDbList     = connect_db(SourceList),
        SourceDbList2    = lists:reverse(SourceDbList),
        [SourceDbName|_] = SourceDbList2,
        % target
        TargetList       = read_field(Datas, target, list),
        TargetDb         = load_config(TargetList, SourceDbName),
        {SourceDbList2, TargetDb, SourceDbName}
    catch
        X:Y ->
            ?MSG_SYS("err|~p~n~p~n~p", [X, Y, erlang:get_stacktrace()]),
            ?error
    end.

load_config(ConfigMysql, SourceDb) ->
    Host        = read_field(ConfigMysql, host,     list),
    Port        = read_field(ConfigMysql, port,     integer),
    UserName    = read_field(ConfigMysql, username, list),
    Password    = read_field(ConfigMysql, password, list),
    Target      = read_field(ConfigMysql, database, atom),
    Charset     = read_field(ConfigMysql, charset,  atom),
    combine_db_mod:execute({'drop_db',   Target}, [SourceDb]),
    ?MSG_SYS("ok|drop database [~p]", [Target]),
    combine_db_mod:execute({'create_db', Target}, [SourceDb]),
    ?MSG_SYS("ok|create database [~p]", [Target]),
    mysql_single_api:start(Host, Port, UserName, Password, Target, Charset),
    ?MSG_SYS("ok|connect database [~p]", [Target]),
    Target.

%% 连接数据库
connect_db(Config) ->
    connect_db(Config, []).
connect_db([ConfigMysql|Tail], Config) ->
    Host        = read_field(ConfigMysql, host,     list),
    Port        = read_field(ConfigMysql, port,     integer),
    UserName    = read_field(ConfigMysql, username, list),
    Password    = read_field(ConfigMysql, password, list),
    Database    = read_field(ConfigMysql, database, atom),
    Charset     = read_field(ConfigMysql, charset,  atom),
    mysql_single_api:start(Host, Port, UserName, Password, Database, Charset),
    ?MSG_SYS("ok|connect database [~p]", [Database]),
    connect_db(Tail, [Database|Config]);
connect_db([], Config) ->
    Config.

read_field(Config, Field, Format) ->
    case lists:keyfind(Field, 1, Config) of
        {_, Value} ->
            FormattedValue = change_format(Value, Format),
            FormattedValue;
        _ ->
            throw({?error, "field missing"})
    end.

%%--------------------tools--------------------------------
change_format(Value, 'atom') ->
    case is_atom(Value) of
        ?true ->
            Value;
        ?false ->
            misc:to_atom(Value)
    end;
change_format(Value, 'list') ->
    case is_list(Value) of
        ?true ->
            Value;
        ?false ->
            misc:to_list(Value)
    end;
change_format(Value, 'integer') ->
    case is_integer(Value) of
        ?true ->
            Value;
        ?false ->
            misc:to_integer(Value)
    end;
change_format(Value, 'binary') ->
    case is_binary(Value) of
        ?true ->
            Value;
        ?false ->
            misc:to_binary(Value)
    end;
change_format(Value, _) ->
    Value.
%%------------------------------------------
%% 初始化表
init_ets([{Ets, Pos}|Tail]) ->
    ets:new(Ets, [set,public,named_table,{keypos,Pos}]),
    init_ets(Tail);
init_ets([]) ->
    ok.

insert_ets_change_name(UserId, ServId, Name) ->
    ets:insert(?ETS_CHANGE_NAME, {UserId, ServId, Name}).

insert_ets_guild_id(DBId, ServId, GuildId) ->
    ets:insert(?ETS_GUILD_ID, {{DBId, ServId}, GuildId}).

%%-----------------------------------------------
game_guild_data(TargetDb) ->
    case mysql_single_api:select(?SQL_GUILD_DATA_INFO, TargetDb) of
       {?ok, []} -> ?ok;
       {?ok, DataList} ->
           game_guild_data2(DataList, TargetDb);
       _ -> ?ok
    end,
    case mysql_single_api:select(?SQL_GUILD_MEMBER, TargetDb) of
       {?ok, []} -> ?ok;
       {?ok, MemberList} ->
           game_guild_member(MemberList, TargetDb);
       _ -> ?ok
    end.

game_guild_data2([], _TargetDb) -> ?ok;
game_guild_data2([[GuildId, GuildName, ChiefId, MemberList,PosList] | List], TargetDb) ->
    Sql = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(ChiefId))/binary, "';">>,
    case mysql_single_api:select(Sql, TargetDb) of 
        {?ok, [[_]]} ->
            MemberList2     = misc:decode(MemberList),      %% 军团成员列表                
            PosList2        = misc:decode(PosList),         %% 军团职位列表[{Pos,[]},...]
            check_guild_name(GuildName, TargetDb),
            MemberList3     = check_guild_member(MemberList2,[], TargetDb),
            PosList3        = check_guild_pos(PosList2,MemberList3,[]),
            SqlUpdateGuild = <<"update `game_guild` set `num` = '", (misc:to_binary(length(MemberList3)))/binary, 
                               "', `member_list` = '", (misc:encode(MemberList3))/binary, 
                               "', `pos_list` = '", (misc:encode(PosList3))/binary, 
                               "' where `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>,
            mysql_single_api:select(SqlUpdateGuild, TargetDb),
            ?MSG_SYS("guild_id: ~p ok", [GuildId]);
        _ ->
            SqlDelGuild = <<"delete from `game_guild` where `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>,
            mysql_single_api:select(SqlDelGuild, TargetDb),
            ?MSG_SYS("guild_id: ~p delete", [GuildId])
    end,
    game_guild_data2(List, TargetDb).

check_guild_member([],List, _TargetDb) -> List;
check_guild_member([UserId|L],List, TargetDb) ->
    Sql = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
    List2 = 
        case mysql_single_api:select(Sql, TargetDb) of 
            {?ok, [[_]]} ->
                [UserId|List];
            _ ->
                SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                mysql_single_api:select(SqlDelGuildMember, TargetDb),
                List 
        end,
    check_guild_member(L,List2, TargetDb).

check_guild_pos([],_MemberList,PosList) -> PosList;
check_guild_pos([{Pos,CList}|L],MemberList,PosList) ->
    CList2      = check_guild_pos2(CList,MemberList,[]),
    PosList2    = [{Pos,CList2}|PosList],
    check_guild_pos(L,MemberList,PosList2).

check_guild_pos2([],_MemberList,CList) -> CList;
check_guild_pos2([UserId|L],MemberList,CList) ->
    case lists:member(UserId, MemberList) of
        ?true ->
            check_guild_pos2(L,MemberList,[UserId|CList]);
        _ ->
            check_guild_pos2(L,MemberList,CList)
    end.

check_guild_name(GuildName, TargetDb) ->
    Sql = <<"select `guild_id`, `guild_name`, `chief_id` from `game_guild` where `guild_name` = '", (misc:to_binary(GuildName))/binary, "';">>,
    case mysql_single_api:select(Sql, TargetDb) of
        {?ok, []} -> 
            ?ok;
        {?ok, [[_,_,_]]} -> 
            ?ok;
        {?ok, DataList} ->
            check_guild_name2(DataList, TargetDb);
        _ -> 
            ?ok
     end.

check_guild_name2([], _TargetDb) -> ?ok;
check_guild_name2([[GuildId,GuildName,ChiefId] | DataList], TargetDb) ->
    Sql = <<"select `serv_id` from `game_user` where `user_id` = '", (misc:to_binary(ChiefId))/binary, "';">>,
    case mysql_single_api:select(Sql, TargetDb) of 
        {?ok, [[ServId]]} ->
            GuildName2  = <<GuildName/binary,"_",(misc:to_binary(ServId))/binary>>,
            SqlGameGuildId = <<"update `game_guild` set `guild_name` = '", (misc:to_binary(GuildName2))/binary, 
                               "' where `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>,
            mysql_single_api:select(SqlGameGuildId, TargetDb),
            SqlGameGuildChange = <<"insert into `game_change_name_guild`(`guild_id`, `is_changed`) values('",
                               (misc:to_binary(GuildId))/binary, "', '0'); ">>,
            mysql_single_api:select(SqlGameGuildChange, TargetDb);
        _ -> 
            ?ok                 
     end,
    check_guild_name2(DataList, TargetDb).

%% 更新game_guild_member
game_guild_member([], _TargetDb) -> ?ok;
game_guild_member([[UserId,GuildId]|List], TargetDb) ->
    SqlSelectUserId = <<"select `serv_id` from `game_user` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
    case mysql_single_api:select(SqlSelectUserId, TargetDb) of 
        {?ok, [[Sid]]} ->
            case ets:lookup(?ETS_DB_SID, Sid) of
                [] ->
                    SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                    mysql_single_api:select(SqlDelGuildMember, TargetDb),
                    ?MSG_SYS("guild_member: ~p ~p delete", [UserId,GuildId]);
                [{_, DbId}] ->
                    case ets:lookup(?ETS_GUILD_ID, {DbId, GuildId}) of
                        [{_, NewGuildId}] ->
                            SqlSelectGuildId = <<"select `guild_id` from `game_guild` where `guild_id` = '", (misc:to_binary(NewGuildId))/binary, "';">>,
                            case mysql_single_api:select(SqlSelectGuildId, TargetDb) of 
                                {?ok, [[_]]} -> 
                                    SqlUpdateGuildId = <<"update `game_guild_member` set `guild_id` = '", (misc:to_binary(NewGuildId))/binary, 
                                                         "' where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                                    mysql_single_api:select(SqlUpdateGuildId, TargetDb),
                                    ?MSG_SYS("guild_member: ~p ~p ok", [UserId,NewGuildId]);
                                _ -> 
                                    SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                                    mysql_single_api:select(SqlDelGuildMember, TargetDb),
                                    ?MSG_SYS("guild_member: ~p ~p delete", [UserId,NewGuildId])
                            end;
                        _ ->
                            SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                            mysql_single_api:select(SqlDelGuildMember, TargetDb),
                            ?MSG_SYS("guild_member: ~p ~p delete", [UserId,GuildId])
                    end
            end;
        _ -> 
            SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
            mysql_single_api:select(SqlDelGuildMember, TargetDb),
            ?MSG_SYS("guild_member: ~p ~p delete", [UserId,GuildId])
    end,
    game_guild_member(List, TargetDb).
%%--------------------------------------------------------------------------------
game_player(TargetDb, [UserId, InfoBin, GuildBin]) ->
    case ets:lookup(?ETS_CHANGE_NAME, UserId) of
        [{_, ServId, Name}] ->
            InfoBinD = mysql_api:decode(InfoBin),
            GuildBinD = mysql_api:decode(GuildBin),
            GuildBinD2 = 
                case ets:lookup(?ETS_GUILD_ID, GuildBinD#guild.guild_id) of
                    [{_, NewGuildId}] ->
                        GuildBinD#guild{guild_id = NewGuildId};
                    [] ->
                        GuildBinD
                end,
            OldName  = InfoBinD#info.user_name,
            if
                OldName =:= Name ->
                    NewName  = misc:to_binary(lists:concat([misc:to_list(OldName), "_", ServId])),
                    InfoBinE = mysql_api:encode(InfoBinD#info{user_name = NewName}),
                    GuildBinE = mysql_api:encode(GuildBinD2),
                    Where = <<" `user_id` = '", (misc:to_binary(UserId))/binary, "'">>,
                    combine_db_mod:execute({update_bin, game_player, <<"info">>,      InfoBinE,  Where}, [TargetDb]),
                    combine_db_mod:execute({update_bin, game_player, <<"guild">>,     GuildBinE, Where}, [TargetDb]),
                    combine_db_mod:execute({update,     game_user,   <<"user_name">>, NewName,   Where}, [TargetDb]),
                    update_name(TargetDb, OldName, NewName);
                ?true ->
                    ?ok
            end;
        [] ->
            ?ok
    end.
     
%%--------------------------------------------------------------------------------
game_group(TargetDb, [Id, MemberList]) ->
    Fun2 = fun({MemberId}, {AccMember, AccPro}) ->
                 SqlSelectMember = <<"select `pro` from `game_user` where `user_id` = '", (misc:to_binary(MemberId))/binary, "';">>,
                 case mysql_single_api:select(SqlSelectMember, TargetDb) of 
                     {?ok, [?undefined]} -> {AccMember, AccPro};
                     {?ok, [Pro]} -> {[{MemberId}|AccMember], [{Pro}|AccPro]};
                     {?ok, []} -> {AccMember, AccPro}
                 end
           end,
    {NewMemberList, NewProList} = lists:foldl(Fun2, {[], []}, misc:decode(MemberList)),
    Len = erlang:length(NewMemberList),
    SqlUpdate = <<"update `game_group` set `online_num`= 0, `in_group_num`='",(misc:to_binary(Len))/binary, 
                             "', `member_list`='", (misc:encode(NewMemberList))/binary, 
                             "', `online_member_list`='", (misc:encode([]))/binary,
                             "', `pro_list`='", (misc:encode(NewProList))/binary, 
                             "' where `id`='", (misc:to_binary(Id))/binary, "';">>,
    mysql_single_api:select(SqlUpdate, TargetDb).

%%--------------------------------------------------------------------------------
game_relation(TargetDb, [UserId, FriendList, BestList, BlackList]) ->
    Fun2 = fun(Rela, FriendList2) ->
                 SqlRela = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                 case mysql_single_api:select(SqlRela, TargetDb) of 
                     {?ok, [?undefined]} -> FriendList2;
                     {?ok, _} -> [Rela|FriendList2]
                 end
           end,
    NewFriendList = lists:foldl(Fun2, [], misc:decode(FriendList)),
    
    Fun3 = fun(Rela, BestList2) ->
                 SqlSelectUserId = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                 case mysql_single_api:select(SqlSelectUserId, TargetDb) of 
                     {?ok, [?undefined]} -> BestList2;
                     {?ok, _} -> [Rela|BestList2]
                 end
           end,
    NewBestList = lists:foldl(Fun3, [], misc:decode(BestList)),
    
    Fun4 = fun(Rela, BlackList2) ->
                 SqlSelectMember = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                 case mysql_single_api:select(SqlSelectMember, TargetDb) of 
                     {?ok, [?undefined]} -> BlackList2;
                     {?ok, _} -> [Rela|BlackList2]
                 end
           end,
    NewBlackList = lists:foldl(Fun4, [], misc:decode(BlackList)),
    
    SqlUpdate = <<"update `game_relation` set `friend_list`= '", (misc:encode(NewFriendList))/binary, 
                             "', `best_list`= '", (misc:encode(NewBestList))/binary,
                             "', `black_list`= '", (misc:encode(NewBlackList))/binary,
                             "' where `user_id`='", (misc:to_binary(UserId))/binary, "';">>,
    mysql_single_api:select(SqlUpdate, TargetDb).
    
%%--------------------------------------------------------------------------------
trans_module(TargetDb, Table, TotalCount, RecordList, Handler) ->
    if(TotalCount > 0) ->
        OkCount = 
            case RecordList of
                ?undefined -> 0;
                []         -> 0;
                _          ->
                    Fun = fun(Record, OldCount) ->
                                try
                                    Handler(TargetDb, Record),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, RecordList),
                    NewCount
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("done|~p/~p", [OkCount, TotalCount]);
        ?true ->
            ?MSG_SYS("err|table[~p] only finished ~p/~p", [Table, OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("err|table[~p] count == 0", [Table])
    end.
%%--------------------------------------------------------------------------------
%% 改名
update_name(TargetDb, OldName, NewName) ->
    update_name(TargetDb, OldName, NewName, ?UPDATE_NAME_LIST).
update_name(TargetDb, OldName, NewName, [{Table, Field}|Tail]) ->
    combine_db_mod:execute({update_name, Table, Field, OldName, NewName}, [TargetDb]),
    update_name(TargetDb, OldName, NewName, Tail);
update_name(_, _, _, []) ->
    ok.


