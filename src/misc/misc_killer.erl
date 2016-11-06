%%% 清人工程 

-module(misc_killer).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.data.hrl").

-define(SQL_DEL_USER,   <<"delete from `game_user` where `cash_sum` <= '0' and `lv` <= '30' and unix_timestamp() - `logout_time_last` > '86400'*'20'; ">>).
-define(SQL_DEL_PLAYER, <<"delete `a` from `game_player` as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`);">>).
-define(SQL_GUILD_DATA_INFO, <<"select `guild_id`, `chief_id`,`member_list`,`pos_list` from `game_guild`;">>).
-define(SQL_GUILD_MEMBER,    <<"delete `a` from game_guild_member as a where not exists (select * from game_user as b where b.user_id = a.user_id )",
                               " or not exists (select * from game_guild as c where c.guild_id = a.guild_id);">>).
-define(SQL_DEL_RELA, <<"delete `a` from `game_relation` as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`);">>).
-define(SQL_DEL_BLESS_USER, <<"delete `a` from game_bless_user as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_PRAC, <<"delete `a` from game_practice as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_TOWER_P, <<"delete `a` from game_tower_player as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`player_id`); ">>).
-define(SQL_DEL_COMM, <<"delete `a` from game_commerce as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_ARENA_M, <<"delete `a` from game_arena_member as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`player_id`); ">>).
-define(SQL_DEL_ARENA_R, <<"delete `a` from game_arena_reward as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`player_id`); ">>).
-define(SQL_DEL_HORSE, <<"delete `a` from game_horse as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_OFFLINE, <<"delete `a` from game_offline as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_OFF_ERR, <<"delete `a` from game_offline_err as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_GROUP_APP, <<"delete `a` from game_group_apply as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_HOME, <<"delete `a` from game_home as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_MAIL, <<"delete `a` from game_mail as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`recv_uid`); ">>).
-define(SQL_DEL_PLAYER_RANK, <<"delete `a` from game_player_rank as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_RANK_EQUIP, <<"delete `a` from game_rank_equip as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_RANK_P, <<"delete `a` from game_rank_partner as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_ARENA_PVP, <<"delete `a` from game_arena_pvp as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_ACTIV_STONE, <<"delete `a` from game_activity_stone_compose as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_SNOW, <<"delete `a` from game_snow_info as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_CARD, <<"delete `a` from game_card_exchange_partner as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_PARTY_D, <<"delete `a` from game_party_doll as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_PRAC_D, <<"delete `a` from game_practice_doll as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_RANK_HORSE, <<"delete `a` from game_rank_horse as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_RES_LOOKFOR, <<"delete `a` from game_resource_lookfor as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_SPRING_D, <<"delete `a` from game_spring_doll as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_WORLD_D, <<"delete `a` from game_world_doll as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_GUILD_TIME, <<"delete `a` from game_guild_time as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_MARKET_SALE, <<"delete `a` from game_market_sale as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`seller_id`); ">>).
-define(SQL_DEL_ACTIVE_WEL, <<"delete `a` from game_active_welfare as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_ARCHERY_INFO, <<"delete `a` from game_archery_info as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`user_id`); ">>).
-define(SQL_DEL_TEAM_INVITE_OFFLINE, <<"delete `a` from game_team_invite_offline as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`userId`); ">>).
-define(SQL_DEL_SHOP_SECRET_INFO, <<"delete `a` from game_shop_secret_info as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`userId`); ">>).
-define(SQL_DEL_TEACH, <<"delete `a` from game_teach as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`userId`); ">>).
-define(SQL_DEL_ENCROACH_INFO, <<"delete `a` from game_encroach_info as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`userId`); ">>).
-define(SQL_DEL_MIXED_SERV_ACTIVITY, <<"delete `a` from game_mixed_serv_activity as `a` where not exists (select `b`.`user_id` from `game_user` as `b` where `b`.`user_id` = `a`.`userId`); ">>).

%%
%% Exported Functions
%%
-export([do_kill/0]).

%%
%% API Functions
%%

do_kill() ->
    kill_lazier(),
    kill_lazier_player(),
    kill_guild_member(),
    kill_rela(),
    kill_team_invite_offline(),
    kill_other(),
    ok.

%% 清无效玩家
kill_lazier() ->
    mysql_api:delete(?SQL_DEL_USER).

%%
kill_lazier_player() ->
    mysql_api:delete(?SQL_DEL_PLAYER).

%%
kill_guild_member() ->
    game_guild_data().

%%
kill_rela() ->
    game_rela().

%%
kill_team_invite_offline() ->
    mysql_api:delete(?SQL_DEL_TEAM_INVITE_OFFLINE),
    game_team_invite_offline().

kill_other() ->
    catch mysql_api:delete(?SQL_DEL_BLESS_USER),
    catch mysql_api:delete(?SQL_DEL_PRAC),
    catch mysql_api:delete(?SQL_DEL_TOWER_P),
    catch mysql_api:delete(?SQL_DEL_COMM),
    catch mysql_api:delete(?SQL_DEL_ARENA_M),
    catch mysql_api:delete(?SQL_DEL_ARENA_R),
    catch mysql_api:delete(?SQL_DEL_HORSE),
    catch mysql_api:delete(?SQL_DEL_OFFLINE),
    catch mysql_api:delete(?SQL_DEL_OFF_ERR),
    catch mysql_api:delete(?SQL_DEL_GROUP_APP),
    catch mysql_api:delete(?SQL_DEL_HOME),
    catch mysql_api:delete(?SQL_DEL_MAIL),
    catch mysql_api:delete(?SQL_DEL_PLAYER_RANK),
    catch mysql_api:delete(?SQL_DEL_RANK_EQUIP),
    catch mysql_api:delete(?SQL_DEL_RANK_P),
    catch mysql_api:delete(?SQL_DEL_ARENA_PVP),
    catch mysql_api:delete(?SQL_DEL_ACTIV_STONE),
    catch mysql_api:delete(?SQL_DEL_SNOW),
    catch mysql_api:delete(?SQL_DEL_CARD),
    catch mysql_api:delete(?SQL_DEL_PARTY_D),
    catch mysql_api:delete(?SQL_DEL_RANK_HORSE),
    catch mysql_api:delete(?SQL_DEL_RES_LOOKFOR),
    catch mysql_api:delete(?SQL_DEL_SPRING_D),
    catch mysql_api:delete(?SQL_DEL_WORLD_D),
    catch mysql_api:delete(?SQL_DEL_GUILD_TIME),
    catch mysql_api:delete(?SQL_DEL_MARKET_SALE),
    catch mysql_api:delete(?SQL_DEL_ACTIVE_WEL),
    catch mysql_api:delete(?SQL_DEL_ARCHERY_INFO),
    catch mysql_api:delete(?SQL_DEL_SHOP_SECRET_INFO),
    catch mysql_api:delete(?SQL_DEL_TEACH),
    catch mysql_api:delete(?SQL_DEL_ENCROACH_INFO),
    catch mysql_api:delete(?SQL_DEL_MIXED_SERV_ACTIVITY),
    
    update_game_arena_member(),
    ok.

%%
%% Local Functions
%%
%%-----------------------------------------------
game_guild_data() ->
    case mysql_api:select(?SQL_GUILD_DATA_INFO) of
        {?ok, []} -> ?ok;
        {?ok, DataList} ->
            game_guild_data2(DataList);
        _ -> ?ok
    end,
    mysql_api:delete(?SQL_GUILD_MEMBER).

game_guild_data2([]) -> ?ok;
game_guild_data2([[GuildId, ChiefId, MemberList,PosList] | List]) ->
    Sql = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(ChiefId))/binary, "';">>,
    case mysql_api:select(Sql) of 
        {?ok, [[_]]} ->
            MemberList2     = misc:decode(MemberList),      %% 军团成员列表                
            PosList2        = misc:decode(PosList),         %% 军团职位列表[{Pos,[]},...]
            MemberList3     = check_guild_member(MemberList2,[]),
            PosList3        = check_guild_pos(PosList2,MemberList3,[]),
            SqlUpdateGuild = <<"update `game_guild` set `num` = '", (misc:to_binary(length(MemberList3)))/binary, 
                               "', `member_list` = '", (misc:encode(MemberList3))/binary, 
                               "', `pos_list` = '", (misc:encode(PosList3))/binary, 
                               "' where `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>,
            mysql_api:select(SqlUpdateGuild),
            ?MSG_SYS("guild_id: ~p ok", [GuildId]);
        _ ->
            SqlDelGuild = <<"delete from `game_guild` where `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>,
            mysql_api:delete(SqlDelGuild),
            ?MSG_SYS("guild_id: ~p delete", [GuildId])
    end,
    game_guild_data2(List).

check_guild_member([],List) -> List;
check_guild_member([UserId|L],List) ->
    Sql = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
    List2 = 
        case mysql_api:select(Sql) of 
            {?ok, [[_]]} ->
                [UserId|List];
            _ ->
                SqlDelGuildMember = <<"delete from `game_guild_member` where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
                mysql_api:select(SqlDelGuildMember),
                List 
        end,
    check_guild_member(L,List2).

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

%%-----------------------------------------------------------------------------------
game_rela() ->
    mysql_api:delete(?SQL_DEL_RELA),
    Sql = <<"select `user_id`,`friend_list`,`best_list`,`black_list` from `game_relation`;">>,
    case mysql_api:select(Sql) of
        {?ok, []} -> ?ok;
        {?ok, [[]]} -> ?ok;
        {?ok, DataList} ->
            game_relation(DataList);
        _ -> ?ok
    end.
game_relation([[UserId, FriendList, BestList, BlackList]|Tail]) ->
    Fun2 = fun(Rela, FriendList2) ->
                   SqlRela = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                   case mysql_api:select(SqlRela) of 
                       {?ok, [?undefined]} -> FriendList2;
                       {?ok, _} -> [Rela|FriendList2]
                   end
           end,
    NewFriendList = lists:foldl(Fun2, [], misc:decode(FriendList)),
    
    Fun3 = fun(Rela, BestList2) ->
                   SqlSelectUserId = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                   case mysql_api:select(SqlSelectUserId) of 
                       {?ok, [?undefined]} -> BestList2;
                       {?ok, _} -> [Rela|BestList2]
                   end
           end,
    NewBestList = lists:foldl(Fun3, [], misc:decode(BestList)),
    
    Fun4 = fun(Rela, BlackList2) ->
                   SqlSelectMember = <<"select `user_id` from `game_user` where `user_id` = '", (misc:to_binary(Rela#relation.mem_id))/binary, "';">>,
                   case mysql_api:select(SqlSelectMember) of 
                       {?ok, [?undefined]} -> BlackList2;
                       {?ok, _} -> [Rela|BlackList2]
                   end
           end,
    NewBlackList = lists:foldl(Fun4, [], misc:decode(BlackList)),
    
    SqlUpdate = <<"update `game_relation` set `friend_list`= '", (misc:encode(NewFriendList))/binary, 
                  "', `best_list`= '", (misc:encode(NewBestList))/binary,
                  "', `black_list`= '", (misc:encode(NewBlackList))/binary,
                  "' where `user_id`='", (misc:to_binary(UserId))/binary, "';">>,
    mysql_api:select(SqlUpdate),
    game_relation(Tail);
game_relation([]) ->
    ?ok.
    

%%--------------------------------------------------------------------------------
update_game_arena_member() ->
    SqlCreateArenaM = 
        <<"CREATE TABLE if not exists `game_arena_member_tmp` ( ",
          " `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '', ",
          " `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '', ",
          " `player_sex` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
          " `player_lv` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `player_career` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
          " `rank` bigint(20) NOT NULL  AUTO_INCREMENT  COMMENT '' , ",
          " `times` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `winning_streak` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `cd` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `fight_force` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `open_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
          " `daily_buy_time` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `clean_times_time` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '', ",
          " `sn` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `streak_wining_reward` varchar(200) NOT NULL DEFAULT '[]' COMMENT '', ",
          " `daily_max_win` int(11) NOT NULL DEFAULT '0' COMMENT '', ",
          " `max_win` int(11) NOT NULL COMMENT '', ",
          " `meritorious` int(11) NOT NULL, ",
          " `score` int(11) NOT NULL COMMENT '', ",
          " `daily_target` int(11) NOT NULL COMMENT '', ",
          " `target_state` int(4) NOT NULL COMMENT '', ",
          " PRIMARY KEY (`rank`), ",
          " KEY `rank` (`rank`) USING HASH ",
          " ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='';">>,
    
    mysql_api:select(SqlCreateArenaM),
    
    SqlInsert = 
        <<"insert into `game_arena_member_tmp`(`player_id`,`player_name`,`player_sex`,`player_lv`,`player_career`,`times`,`winning_streak`,`cd`,`fight_force`,`open_flag`,",
          "`daily_buy_time`,`clean_times_time`,`on_line_flag`,`sn`,`streak_wining_reward`,`daily_max_win`,`max_win`,`meritorious`,`score`,`daily_target`,`target_state`) ",
          "(select `player_id`,`player_name`,`player_sex`,`player_lv`,`player_career`,`times`,`winning_streak`,`cd`,`fight_force`,`open_flag`,`daily_buy_time`,`clean_times_time`,",
          "`on_line_flag`,`sn`,`streak_wining_reward`,`daily_max_win`,`max_win`,`meritorious`,`score`,`daily_target`,`target_state` from `game_arena_member` order by `fight_force` desc);">>,
    mysql_api:select(SqlInsert),
    
    SqlTrunc = 
        <<"truncate table game_arena_member;">>,
    mysql_api:select(SqlTrunc),
    
    SqlInsertRet = 
        <<"insert into `game_arena_member` select * from `game_arena_member_tmp`;">>,
    mysql_api:select(SqlInsertRet),
    
    SqlDropTab = 
        <<"drop table `game_arena_member_tmp`;">>,
    mysql_api:select(SqlDropTab),
    
    ok.

%%--------------------------------------------------------------------------------
game_team_invite_offline() ->
    Sql = <<"select `userId`, `team_to`, `team_from` from game_team_invite_offline;">>,
    List2 = 
        case mysql_api:select(Sql) of
            {ok, List} ->
                List;
            _ ->
                []
        end,
    game_team_invite_offline(List2),
    ok.

game_team_invite_offline([[UserId, TeamTo, TeamFrom]|Tail]) ->
    TeamToD =
        try
            misc:decode(TeamTo)
        catch
            _:_ ->
                []
        end,
    TeamFromD =
        try
            misc:decode(TeamFrom)
        catch
            _:_ ->
                []
        end,
    TeamTo2 = game_team_invite_offline_2(TeamToD),
    TeamFrom2 = game_team_invite_offline_2(TeamFromD),
    Sql = <<" update game_team_invite_offline set `team_to` = '", (misc:encode(TeamTo2))/binary, "', `team_from` = '", 
            (misc:encode(TeamFrom2))/binary, "' where userId = '", (misc:to_binary(UserId))/binary, "';">>,
    mysql_api:select(Sql),
    game_team_invite_offline(Tail);
game_team_invite_offline([]) ->
    ok.

is_exist(UserId) ->
    Sql = <<"select `user_id` from game_user where `user_id` = '", (misc:to_binary(UserId))/binary, "';">>,
    case mysql_api:select(Sql) of
        {ok, _} -> true;
        {ok, _, _} -> true;
        _ -> false
    end.

game_team_invite_offline_2(List) ->
    game_team_invite_offline_2(List, []).
game_team_invite_offline_2([UserId|Tail], OldList) ->
    case is_exist(UserId) of
        true ->
            game_team_invite_offline_2(Tail, [UserId|OldList]);
        false ->
            game_team_invite_offline_2(Tail, OldList)
    end;
game_team_invite_offline_2([], List) ->
    List;
game_team_invite_offline_2(_, List) ->
    List.
    





