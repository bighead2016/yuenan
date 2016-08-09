%% Author: PXR
%% Created: 2013-8-29
%% Description: TODO: Add description to guild_pvp_api
-module(guild_pvp_api).

%%
%% Include files
%%
-include("../include/record.guild.hrl"). 
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").

-define(CONST_GUILD_PVP_ENTER_CD, 60).


%%
%% Exported Functions
%%
-export([interval/0, on/1, off/1, enter_guild_pvp/1, app_guild_pvp/2, start_battle/3, get_camp_born_point/1, buy_item/6]).

-export([check_and_set_def_player_state_cb/2, battle_over/2, refresh_monster/3, encourage/2, get_guild_app_list/2]).

-export([car_att/1, fix_wall/1, bring_back/2, init_map_ok/2, exit_guild_pvp/1, change_state/1, login_packet/2]).


-export([get_enter_info/1, water_door/1, give_up_watch/1, broad_att_wall_info_packet/0, player_logout/1, cs_get_guild_member_list/1]).

-export([app_end_30/1, app_end/1, get_guild_pvp_app_info/1, get_guild_app_list/1, get_tower_info/1, get_guild_pvp_map_id/0]).

-export([att_wall/1, broad_att_wall_info/0, msg_enter_success/3, msg_time_syc/1, msg_msg_id_guild_pvp_enter_cd/1, is_can_guild_operation/1]).

-export([give_up_att_wall/1, msg_announment/2, msg_bring_back_result/1, msg_sc_att_wall_info/5, send_guild_map_msg/1]).

% msg
-export([msg_broad_rank/9, msg_sc_encourage/1, msg_sc_state_change/1, msg_monster_hp/4, msg_monster_dead/1, msg_broad_end/9, msg_monster_info/1]).

-export([msg_app_info/8, msg_app_list/4, msg_sc_enter_info/2, msg_sc_tower_owner_info/2, msg_sc_att_wall_list/3, msg_boss_state/2, msg_map_info/1]).

-export([msg_skill_cd/2, msg_guild_item_not_enough/1, msg_sc_guild_member_list/1]).
%%
%% API Functions
%%

is_can_guild_operation(Player) ->
    UserId = Player#player.user_id,
    Guild = Player#player.guild,
    GuildId = Guild#guild.guild_id,
    Result =
        case guild_pvp_mod:check_start() of
            true ->
                case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
                    [] ->
                        true;
                    _ ->
                        false
                end;
            false ->
                true
        end,
    case Result of
        false ->
            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_GUILD_PVP_OPERATION_ERROR);
        _ ->
            ok
    end,
    Result.
     
cs_get_guild_member_list(Player) ->
    Guild = Player#player.guild,
    GuildId = Guild#guild.guild_id,
    MemberList = guild_api:get_guild_members(GuildId),
    FormatFun = 
        fun({Uid, UserName, _Power1}) ->
            {Uid, UserName}
        end,
    FormatList = lists:map(FormatFun, MemberList),
    Packet = msg_sc_guild_member_list(FormatList),
    misc_packet:send(Player#player.user_id, Packet).

give_up_att_wall(Player) ->
    UserId = Player#player.user_id,
    case guild_pvp_mod:check_open() of
        false ->
            ok;
        _ ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [] ->
                    ok;
                [Rec] ->
                    ets:delete(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId),
                    Packet = msg_sc_att_wall_info(UserId, Rec#guild_pvp_player.name, Rec#guild_pvp_player.lv, 1, true),
                    guild_pvp_mod:broad_wall(Packet),
                    case Rec#guild_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_DEAD andalso Rec#guild_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE of
                        true ->
                            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId,
                                {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL});
                        _ ->
                            ok
                    end
            end
    end.

att_wall(Player) ->
    UserId = Player#player.user_id,
    case guild_pvp_mod:check_open() of
        false ->
            ?MSG_ERROR("active end", []);
        _ ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [#guild_pvp_player{name = Name, lv = Level, state = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}] ->
                    Now = misc:seconds(),
                    AttRec = 
                        #guild_pvp_att_wall{user_id = UserId, 
                                            name = Name, 
                                            level = Level,
                                            start_time = Now,
                                            state = ?CONST_CAMP_PVP_PLAYER_STATE_WORKING},
                    ets:insert(?CONST_ETS_GUILD_PVP_ATT_WALL, AttRec),
                    Packet = msg_sc_att_wall_info(UserId, Name, Level, ?CONST_CAMP_PVP_PLAYER_STATE_WORKING, false),
                    guild_pvp_mod:broad_wall(Packet),
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                        {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_WORKING}),
					guild_pvp_mod:broad_self_state(UserId);
                _ ->
                    ok
            end
    end.

give_up_watch(Player) ->
    ets:delete(?CONST_ETS_GUILD_PVP_WATER, Player#player.user_id).

water_door(Player) ->
    Packet = broad_att_wall_info_packet(),
    misc_packet:send(Player#player.user_id, Packet),
    ets:insert(?CONST_ETS_GUILD_PVP_WATER, #guild_pvp_watch{player_id = Player#player.user_id}).

broad_att_wall_info_packet() ->
    List = ets:tab2list(?CONST_ETS_GUILD_PVP_ATT_WALL),
    Format = 
        fun(PlayerRec) ->
                UserId = PlayerRec#guild_pvp_att_wall.user_id,
                Name = PlayerRec#guild_pvp_att_wall.name,
                Level = PlayerRec#guild_pvp_att_wall.level,
                State = PlayerRec#guild_pvp_att_wall.state,
                {UserId, Name, Level, State}
        end,
    FormatList = lists:map(Format, List),
    msg_sc_att_wall_list(FormatList, false, false).
                
broad_att_wall_info() ->
    WatchList = ets:tab2list(?CONST_ETS_GUILD_PVP_WATER),
    Packet = broad_att_wall_info_packet(),
    Fun =
        fun(WatchRec) ->
                UserId = WatchRec#guild_pvp_watch.player_id,
                misc_packet:send(UserId, Packet)
        end,
    lists:foreach(Fun, WatchList).

get_tower_info(Player) ->
    UserId = Player#player.user_id,
    IsInBattle =  guild_pvp_mod:check_open(),
    OwnerName = guild_pvp_mod:get_tower_owner_name(),
    Packet = msg_sc_tower_owner_info(OwnerName, IsInBattle),
    misc_packet:send(UserId, Packet).

%% 获取军团战地图ID
get_guild_pvp_map_id() ->
    41007.

%% 点击活动图标弹出的
get_enter_info(Player) ->
    UserId = Player#player.user_id, 
    case guild_pvp_mod:get_tower_owner_id() of
        0 ->
            enter_guild_pvp(Player);
        _ ->
            {AttGuildList, DefGuildList} = get_guild_enter_list(),
            Packet = msg_sc_enter_info(AttGuildList, DefGuildList),
            misc_packet:send(UserId, Packet)
    end.
        

get_camp_born_point(CampId) ->
    case CampId of
        ?CONST_GUILD_PVP_CAMP_ATT ->
            List = [{1245,400},{1050,660},{870,930},{870,1200}];
        _ ->
            List = [{4860,420},{5490,720},{5880,960},{6060,1230}]
    end,
    Length = length(List),
    Random = misc:rand(1, Length),
    lists:nth(Random, List).

get_guild_enter_list() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    FilterFun = 
        fun(Guild) ->
                Guild#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_ATT
        end,
    AttList = lists:filter(FilterFun, GuildList),
    DefList = GuildList -- AttList,
    SortFun = 
        fun(#guild_pvp_guild{first_enter_time = F1}, #guild_pvp_guild{first_enter_time = F2}) ->
                F1 < F2
        end,
    SortAtt = lists:sort(SortFun, AttList),
    SortDef = lists:sort(SortFun, DefList),
    FormatFun = 
        fun(Guild) ->
                GuildId = Guild#guild_pvp_guild.guild_id,
                GuildEnter = Guild#guild_pvp_guild.power,
                GuildName = Guild#guild_pvp_guild.name,
                {GuildId, GuildName, GuildEnter}
        end,
    FAtt = lists:map(FormatFun, SortAtt),
    FDef = lists:map(FormatFun, SortDef),
    {FAtt, FDef}.
                

get_guild_app_list(Player) ->
    UserId = Player#player.user_id,
    Guild = Player#player.guild,
    GuildId = Guild#guild.guild_id,
    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
        [] ->
            get_guild_app_list(UserId, false);
        [GuildRec] ->
            case GuildRec#guild_pvp_guild.is_leader of
                true ->
                    get_guild_app_list(UserId, true);
                false ->
                    get_guild_app_list(UserId, false)
            end
    end.

def_choosed(DefList) ->
    Fun =
        fun(Guild) ->
                Guild#guild_pvp_guild.choosed_def
        end,
    DefChoosed = lists:map(Fun, DefList),
    length(DefChoosed).

get_guild_app_list(UserId, IsLeader) ->
    DefList = guild_pvp_mod:get_def_guild_list(),
    DefChoosedCount = def_choosed(DefList),
    AttList = guild_pvp_mod:get_att_guild_list(),
    AttFormatFun = 
        fun(Guild) ->
                GuildId = Guild#guild_pvp_guild.guild_id,
                {ok, GuildLeaderName} = guild_api:get_guild_chief_name(GuildId),
                GuildName = Guild#guild_pvp_guild.name,
                Power = Guild#guild_pvp_guild.power,
                {GuildId, GuildName, Power, GuildLeaderName}
        end,
    DefFormatFun = 
        fun(Guild) ->
                GuildId = Guild#guild_pvp_guild.guild_id,
                GuildName = Guild#guild_pvp_guild.name,
                Power = Guild#guild_pvp_guild.power,
                IsChoose = Guild#guild_pvp_guild.choosed_def,
                {IsChoose, GuildId, GuildName, Power}
        end,

    DefFormatList = lists:map(DefFormatFun, DefList),
    AttFormatList = lists:map(AttFormatFun, AttList),
    Packet = msg_app_list(IsLeader, DefChoosedCount, DefFormatList, AttFormatList),
    misc_packet:send(UserId, Packet).

get_guild_pvp_app_info(Player) ->
    UserId = Player#player.user_id,
    Guild = Player#player.guild,
    MyGuildId = Guild#guild.guild_id,
    RankList = ets:tab2list(?CONST_ETS_GUILD_PVP_RANK),
    SortFun =
        fun(#guild_pvp_rank{guild_score = Score1}, #guild_pvp_rank{guild_score = Score2}) ->
                Score1 > Score2
        end,
    SortedList = lists:sort(SortFun, RankList),
    FormatFun = 
        fun(GuildRank) ->
                GuildId = GuildRank#guild_pvp_rank.guild_id,
                GuildName = GuildRank#guild_pvp_rank.guild_name,
                GuildMaster = GuildRank#guild_pvp_rank.guild_master_name,
                Score = GuildRank#guild_pvp_rank.guild_score,
                {GuildName, GuildMaster, Score, GuildId}
        end,
    Rank = lists:map(FormatFun, SortedList),
    DefChoosedCout = guild_pvp_mod:get_choosed_count(),
    IsDefFull = (DefChoosedCout >= 2),
    DefCount = length(guild_pvp_mod:get_def_guild_list()),
    AttCount = length(guild_pvp_mod:get_att_guild_list()),
    case RankList of
        [] ->
            LastWinCamp = 0,
            LeaderName = "无",
            IsTowerOwner = false,
            CampId = 
                case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, MyGuildId) of
                    [] ->
                        0;
                    [GuildRec] ->
                        GuildRec#guild_pvp_guild.camp_id
                end,
            Packet = msg_app_info(LastWinCamp, LeaderName, AttCount, DefCount, CampId, IsTowerOwner, IsDefFull, Rank);
        _ ->
            Leader = hd(SortedList),
            LastWinCamp = Leader#guild_pvp_rank.camp_id,
            LeaderName = guild_pvp_mod:get_tower_owner_name(),
            {CampId, IsTowerOwner} = 
                case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, MyGuildId) of
                    [] ->
                        {0, false};
                    [GuildRec] ->
                        {GuildRec#guild_pvp_guild.camp_id, guild_pvp_mod:get_tower_owner_id() == MyGuildId}
                end,
            Packet = msg_app_info(LastWinCamp, LeaderName, AttCount, DefCount, CampId, IsTowerOwner, IsDefFull, Rank)
    end,
    misc_packet:send(UserId, Packet).
    


app_end_30([]) ->
    ok.

app_end([]) ->
    ?MSG_DEBUG("active application end !!!!!!!!!!!!!!", []),
    ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_READY}),
    guild_pvp_mod:choose_guild(),
    ok.
  
change_state(Player) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [Rec] ->
            case Rec#guild_pvp_player.state of
                ?CONST_CAMP_PVP_PLAYER_STATE_DEAD ->
                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL,
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                       {#guild_pvp_player.state, NewState}),
                    guild_pvp_mod:broad_self_state(UserId);
                ?CONST_CAMP_PVP_PLAYER_STATE_WORKING ->
                    DefId = guild_pvp_serv:get_wall_id(),
                    start_battle(Player, DefId, ?CONST_BATTLE_GUILD_PVE);
                _ ->
                    ok
            end
    end.

exit_guild_pvp(Player) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            Player2 = map_api:return_last_city(Player),
            {ok, Player2};
        [Rec] ->
            Now = misc:seconds(),
            EnterCd = Now + ?CONST_GUILD_PVP_ENTER_CD,
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                               [{#guild_pvp_player.exist , false},
                                {#guild_pvp_player.enter_cd , EnterCd}]),
            case guild_pvp_mod:check_open() of
                false ->
                    ok;
                _ ->
                    guild_pvp_serv:sub_guild_enter_count(Rec#guild_pvp_player.gulid_id)
            end,
            ets:delete(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId),
            ets:delete(?CONST_ETS_GUILD_PVP_WATER, UserId),
            Player2 = map_api:return_last_city(Player),
            {ok, Player2}
    end,
    Player4 = 
        case player_state_api:try_set_state_play(Player2, ?CONST_PLAYER_PLAY_CITY) of
            {?true, Player3} ->
                Player3;
            {?false, Player3, _Tips} ->
                Player3
        end,
    {ok, Player4}.

init_map_ok(Player, MapId) ->
    case MapId == ?CONST_GUILD_PVP_NORMAL_MAP_ID of
        true ->
            guild_pvp_api:send_guild_map_msg(Player#player.user_id);
        false ->
            UserId = Player#player.user_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [] ->
                    ok;
                [UserRec] ->
                    case UserRec#guild_pvp_player.position =< ?CONST_GUILD_POSITION_VICE_CHIEF of
                        true ->
                            guild_pvp_mod:get_skill_cd(UserId);
                        false ->
                            ok
                    end,
                    Packet = guild_pvp_mod:boss_state_packet(),
                    misc_packet:send(UserId, Packet),
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, {#guild_pvp_player.map_id, MapId}),
                    guild_pvp_mod:broad_self_state(UserId),
                    get_other_state(UserId, MapId),
                    FreeList = guild_pvp_mod:get_safe_map_id(),
                    
                    case lists:member(MapId, FreeList) of
                        true ->
                            get_encourage_info(UserRec),
                            ok;
                        _ ->
                            MonsterPacket = guild_pvp_mod:monster_info_packet(),
                            misc_packet:send(UserId, MonsterPacket)
                    end
            end
    end.

get_other_state(UserId, MapId) ->
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    Fun =
        fun(Player) ->
                Player#guild_pvp_player.map_id == MapId
        end,
    FilterList = lists:filter(Fun, PlayerList),
    FormatFun =
        fun(Rec) ->
            UserId1 = Rec#guild_pvp_player.user_id,
            {HpMax,HpNow} = guild_pvp_mod:get_hp_value(Rec#guild_pvp_player.hp),
            Campid = Rec#guild_pvp_player.camp_id,
            State = Rec#guild_pvp_player.state,
            SteakKill = Rec#guild_pvp_player.steak_kill,
            IsLeader = Rec#guild_pvp_player.position == ?CONST_GUILD_POSITION_CHIEF,
            GuildId = Rec#guild_pvp_player.gulid_id, 
            Power = Rec#guild_pvp_player.power,
            {HpMax,HpNow,State,Campid,SteakKill,IsLeader,GuildId,UserId1, Rec#guild_pvp_player.position, Power}
        end,
    FormatList = lists:map(FormatFun, FilterList),
    Packet = msg_sc_state_change(FormatList),
    misc_packet:send(UserId, Packet).
                

bring_back(Player, IsUseMoney) ->
    UserId = Player#player.user_id,
    case IsUseMoney of
        true ->
            case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 20, ?CONST_COST_GUILD_PVP_BUY) of
                ?ok ->
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                       [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]),
                    SuccessPacket = msg_bring_back_result(true),
                    misc_packet:send(UserId, SuccessPacket),
                    guild_pvp_mod:broad_self_state(UserId);
                _ ->
                    ok
            end;
        _ ->
            case goods_api:use_goods_by_id(Player, ?CONST_GUILD_PVP_BRING_ITEM, 1) of
                {?ok, Player2, _GList, UsePacket} ->
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                       [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]),
                    SuccessPacket = msg_bring_back_result(true),
                    misc_packet:send(UserId, <<SuccessPacket/binary,UsePacket/binary>>),
                    guild_pvp_mod:broad_self_state(UserId),
                    {ok, Player2};
                _ ->
                    Guild = Player#player.guild,
                    GuildId = Guild#guild.guild_id,
                    case guild_ctn_mod:get_item(GuildId, ?CONST_GUILD_PVP_BRING_ITEM) of
                        true ->
                            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                               [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]),
                            SuccessPacket = msg_bring_back_result(true),
                            misc_packet:send(UserId, SuccessPacket),
                            guild_pvp_mod:broad_self_state(UserId);
                        false ->
                            NotEnoughPacket = msg_guild_item_not_enough(?CONST_GUILD_PVP_BRING_ITEM),
                            misc_packet:send(UserId, NotEnoughPacket)
                    end
            end
    end.
                
                
            


fix_wall(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Name = Info#info.user_name,
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            err;
        [Rec] ->
            case Rec#guild_pvp_player.position =< ?CONST_GUILD_POSITION_VICE_CHIEF of
                false ->
                    ?MSG_ERROR("403 ~w", [UserId]);
                _ ->
                    guild_pvp_serv:fix_wall({UserId, Name}, Rec#guild_pvp_player.camp_id)
            end
    end.     

car_att(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Name = Info#info.user_name,
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ?MSG_DEBUG("~w not in game", [UserId]);
        [Rec] ->
            case Rec#guild_pvp_player.position =< ?CONST_GUILD_POSITION_VICE_CHIEF of
                false ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_SKILL_403);
                _ ->
                    guild_pvp_serv:car_att({UserId, Name}, Rec#guild_pvp_player.camp_id)
            end
    end.

encourage(Player, IsUseMoney) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ?MSG_ERROR("~w not in active but encourage", [UserId]),
            ok;
        [GuildPlayer] ->
            case GuildPlayer#guild_pvp_player.encourage_times >= ?CONST_GUILD_PVP_ENCOURAGE_MAX of
                true ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ENCOURAGE_MAX);
                _ ->
                    case IsUseMoney of
                        true ->
                            case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 20, ?CONST_COST_CAMP_PVP_ENCOURAGE) of
                                ?ok ->
                                    encourage(GuildPlayer);
                                _ ->
                                    ok
                            end;
                        _ ->
                            case goods_api:use_goods_by_id(Player, ?CONST_GUILD_PVP_ATTR_ITEM, 1) of
                                {?ok, Player2, _GList, UsePacket} ->
                                    misc_packet:send(UserId, UsePacket),
                                    encourage(GuildPlayer),
                                    {ok, Player2};
                                _ ->
                                    Guild = Player#player.guild,
                                    GuildId = Guild#guild.guild_id,
                                    case guild_ctn_mod:get_item(GuildId, ?CONST_GUILD_PVP_ATTR_ITEM) of
                                        true ->
                                            encourage(GuildPlayer);
                                        false ->
                                            NotEnoughPacket = msg_guild_item_not_enough(?CONST_GUILD_PVP_ATTR_ITEM),
                                            misc_packet:send(UserId, NotEnoughPacket)
                                    end
                            end
                    end
            end
    end.


encourage(GuildPlayer) -> 
    EncourageTime = GuildPlayer#guild_pvp_player.encourage_times,
    UserId = GuildPlayer#guild_pvp_player.user_id,
    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId,
                        {#guild_pvp_player.encourage_times, EncourageTime + 1}),
    Per = (EncourageTime + 1),
    PacketNotice    = message_api:msg_notice(?TIP_BOSS_ENCOURAGE_SUCCESS,
                                         [{?TIP_SYS_COMM, misc:to_list(Per)}]),
    Packet = guild_pvp_api:msg_sc_encourage(Per),
    misc_packet:send(UserId, <<Packet/binary, PacketNotice/binary>>).
   
get_encourage_info(#guild_pvp_player{encourage_times = Times, user_id = UserId}) ->
    Packet = guild_pvp_api:msg_sc_encourage(Times),
    misc_packet:send(UserId, Packet).
        

%% boss每回合刷新血量
refresh_monster(UserId, MonsterId, HurtTuple) ->
    ?MSG_DEBUG("~w try to refresh boss hp, hurttuple is ~w", [UserId, HurtTuple]),
    case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId) of 
        [#guild_pvp_monster{state = ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}] ->
            erlang:make_tuple(9, 0, []);
        [#guild_pvp_monster{hp_tuple_boss = HpTuple}]->
            ?MSG_DEBUG("new HpTuple is ~w ", [HpTuple]),
            case HurtTuple of
                {0,0,0,0,0,0,0,0,0} -> HpTuple;
                _ ->
                    case guild_pvp_mod:check_open() of
                        false ->
                            ?MSG_ERROR("guild pvp end set boss hp 0", []),
                            erlang:make_tuple(9, 0, []);
                        true ->
                            Hurt        = lists:sum(misc:to_list(HurtTuple)),
                            guild_pvp_serv:refresh_monster_cast(MonsterId, Hurt, HurtTuple, UserId),
                            T = boss_mod:set_hp_tuple(HpTuple, HurtTuple), %% 这里可能不准了 lz
                            T
                    end
            end;
        O -> 
            ?MSG_ERROR("errr!!!ddddddddddd~w", [O]),erlang:make_tuple(9, 0, [])
    end.


battle_over(Result, Param) ->
    case guild_pvp_mod:check_open() of
        true ->
            guild_pvp_mod:battle_over(Result, Param);
        false ->
            ok
    end.

start_battle(Player, DefId, Type) ->
    case guild_pvp_mod:check_open() of
        false ->
            ?MSG_ERROR("active not start!", []);
        _ ->
            AttId = Player#player.user_id,
            case check_battle_state(AttId, DefId, Type) of
                {AttHp, DefHp, AttBuf, DefBuf} ->
                    Param = #param{ad1 = AttHp, ad2 = DefHp, battle_type = Type,ad5 = DefHp, ad4 = {AttId, DefId}, attr = {AttBuf, DefBuf}},
                    case battle_api:start(Player, DefId, Param) of
                        {?ok, Player2} ->
                            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, 
                                               Player#player.user_id, 
                                               {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}),
                            case Type of
                                ?CONST_BATTLE_GUILD_PVP ->
                                    case ets:lookup(?CONST_ETS_GUILD_PVP_ATT_WALL, DefId) of
                                        [] ->
                                            ok;
                                        [_WallRec] ->
                                            WallPacket = msg_sc_att_wall_info(DefId, "", 1, 1, true),
                                            guild_pvp_mod:broad_wall(WallPacket),
                                            ets:delete(?CONST_ETS_GUILD_PVP_ATT_WALL, DefId)
                                    end,
                                    ets:delete(?CONST_ETS_GUILD_PVP_WATER, AttId),
                                    ets:delete(?CONST_ETS_GUILD_PVP_WATER, DefId),
                                    guild_pvp_mod:broad_self_state(Player#player.user_id),
                                    guild_pvp_mod:broad_self_state(DefId);
                                _ ->
                                    case ets:lookup(?CONST_ETS_GUILD_PVP_ATT_WALL, AttId) of
                                        [] ->
                                            ok;
                                        [WallRec] ->
                                            ets:update_element(?CONST_ETS_GUILD_PVP_ATT_WALL, AttId,
                                                                {#guild_pvp_att_wall.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}),
                                            WallPacket = msg_sc_att_wall_info(AttId, WallRec#guild_pvp_att_wall.name,
                                                                           WallRec#guild_pvp_att_wall.level,
                                                                           ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE, 
                                                                          false),
                                            guild_pvp_mod:broad_wall(WallPacket)
                                    end,
                                    guild_pvp_mod:broad_self_state(Player#player.user_id)
                            end,
                            {?ok, Player2};
                        _ ->
                            case Type of
                                ?CONST_BATTLE_GUILD_PVP ->
                                    revert_state(DefId);
                                _ ->
                                    ok
                            end
                    end;
                O ->
                    ?MSG_DEBUG("can not start battle : ~w", [O])
            end
    end.

buy_item(Player, ItemId, Count, IsBuySelf, IdBuyFor, IsBuyForGuild) ->
    UserId = Player#player.user_id,
    Cost = 20,
    CostTotal = Cost * Count,
    Guild = Player#player.guild,
    GuildName = Guild#guild.guild_name,
    Info = Player#player.info,
    Name = Info#info.user_name,
    GuildId = Guild#guild.guild_id,
    case IsBuySelf of
        true ->
            case ctn_bag2_api:is_full(Player#player.bag) of
                true ->
                    misc_packet:send_tips(Player#player.user_id, ?TIP_COMMON_BAG_NOT_ENOUGH);
                false ->
                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CostTotal, ?CONST_COST_GUILD_PVP_BUY) of
                        ?ok ->
                            Goods = goods_api:make(ItemId, ?CONST_GOODS_BIND, Count),
                            ?MSG_ERROR("Goods is ~w", [ItemId]),
                            case ctn_bag_api:put(Player, Goods, ?CONST_COST_GUILD_PVP_BUY, 1, 1, 1, 1, 1, 1, []) of
                                {?ok, Player2, _Changelist, _Packet} ->
                                    misc_packet:send_tips(UserId, ?TIP_MALL_SUCCESS),
                                    {ok, Player2};
                                {?error, ErrorCode} ->
                                    misc_packet:send_tips(UserId, ErrorCode)
                            end;
                        {?error, _ErrorCode} ->
                            ok
                    end
            end;
        _ ->
            case IsBuyForGuild of
                false ->
                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CostTotal, ?CONST_COST_GUILD_PVP_BUY) of
                        ?ok ->
                            ToName = player_api:get_name(IdBuyFor),
                            Goods = goods_api:make(ItemId, ?CONST_GOODS_BIND, Count),
                            Tips1 = message_api:msg_notice(?TIP_GUILD_PVP_ADD_PVP_SCORE_BY_BUY, [{?TIP_SYS_COMM, misc:to_list(CostTotal)}]),
                            misc_packet:send(UserId, Tips1),
                            PacketTips   = message_api:msg_notice(?TIP_GUILD_PVP_PVP_GIVE_ITEM, 
                                                                  [{UserId,Name}, {IdBuyFor,ToName}],
                                                                  Goods,
                                                                  [{?TIP_SYS_COMM, misc:to_list(GuildName)}, {?TIP_SYS_COMM, misc:to_list(Count)}]),
                            misc_app:broadcast_world_2(PacketTips),
                            guild_api:add_guild_pvp_score(UserId, CostTotal),
                            mail_api:send_system_mail_to_one(ToName, <<>>, <<>>, ?CONST_MAIL_BUY_GUILD_ITEMS, [{[{misc:to_list(Name)}]},{[{misc:to_list(ItemId)}]}], Goods, 0, 0, 0, ?CONST_COST_GUILD_PVP_BUY);
                        {?error, _ErrorCode} ->
                            ok
                    end;
                _ ->
                    case catch guild_api:get_guild_data(Guild#guild.guild_id) of
                        {?ok,GuildData} ->
                            GuildCtn = GuildData#guild_data.ctn,
                            case ctn_bag2_api:is_full(GuildCtn) of
                                false ->
                                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CostTotal, ?CONST_COST_GUILD_PVP_BUY) of
                                        ?ok ->
                                            Tips1 = message_api:msg_notice(?TIP_GUILD_PVP_ADD_PVP_SCORE_BY_BUY, [{?TIP_SYS_COMM, misc:to_list(CostTotal)}]),
                                            misc_packet:send(UserId, Tips1),
                                            Goods = goods_api:make(ItemId, ?CONST_GOODS_BIND, Count),
                                            guild_api:add_guild_pvp_score(UserId, CostTotal),
                                            mail_api:send_sys_mail_to_guild(GuildId, ?CONST_MAIL_GUILD_GIVE_GOODS, [], [{[{misc:to_list(Name)}]},{[{misc:to_list(ItemId)}]}], ?CONST_COST_GUILD_PVP_BUY),
                                            guild_ctn_mod:set_list(GuildId, Goods);
                                        {?error, _ErrorCode} ->
                                            ok
                                    end;
                                _ ->
                                    misc_packet:send_tips(UserId, ?TIP_COMMON_BAG_NOT_ENOUGH)
                            end;
                        _ ->
                            ok
                    end
            end
    end.

check_battle_state(AttId, DefId, ?CONST_BATTLE_GUILD_PVE) ->
    case check_in_active_pve(AttId, DefId) of
        false -> 
            ?MSG_ERROR("attid ~w or deffid ~w not in data list !", [AttId, DefId]);
        {UserRec, MonsterRec} ->
            case check_att_order(MonsterRec) of
                false ->
                    ?MSG_ERROR("wall is live can not att boss", []);
                _ ->
                    case UserRec#guild_pvp_player.state  == ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL orelse 
                         UserRec#guild_pvp_player.state  == ?CONST_CAMP_PVP_PLAYER_STATE_WORKING of
                        true ->
                            case MonsterRec#guild_pvp_monster.state of
                                ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL ->
                                    AttBuff = get_buff_list(UserRec#guild_pvp_player.encourage_times),
                                    {UserRec#guild_pvp_player.hp, MonsterRec#guild_pvp_monster.hp_tuple_boss, AttBuff, []};
                                _ ->
                                    ?MSG_ERROR("monster ~w haved dead", [DefId])
                            end;
                        _ ->
                            ?MSG_ERROR("player state not ok, state is ~w", [UserRec#guild_pvp_player.state])
                    end
            end
    end;

check_battle_state(AttId, DefId, ?CONST_BATTLE_GUILD_PVP) ->
    case check_in_active_pvp(AttId, DefId) of
        false ->
            ?MSG_ERROR("attid ~w or deffid ~w not in data list ~", [AttId, DefId]);
        {AttRec, DefRec} ->
            case AttRec#guild_pvp_player.state of
                ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL ->
                    case check_and_set_def_player_state(DefId) of
                        false ->
                            misc_packet:send_tips(AttId, ?TIP_CAMP_PVP_USER_BATTLING);
                        _ ->
                            AttBuff = get_buff_list(AttRec#guild_pvp_player.encourage_times),
                            DeffBuff = get_buff_list(AttRec#guild_pvp_player.encourage_times),
                            {AttRec#guild_pvp_player.hp, DefRec#guild_pvp_player.hp, AttBuff, DeffBuff}
                    end;
                _ ->
                    ?MSG_DEBUG("add state is ~w, self state not ok, so do not need send tip", 
                               [AttRec#guild_pvp_player.state])
            end
    end.

get_buff_list(Encourage) ->
    {Power, _, _, _}    = rank_api:get_max_power(),
    AttrPlus            = round(Encourage*Power / 100),
    case AttrPlus of
          0 -> [];
          _ -> [{?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_FORCE_ATTACK, AttrPlus},
                {?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, AttrPlus}]
    end.

check_att_order(MonsterRec) ->
    case MonsterRec#guild_pvp_monster.monster_type of
        ?CONST_GUILD_PVP_BOSS_TYPE_BOSS ->
            guild_pvp_mod:check_wall_live() /= true;
        _ ->
            true
    end.

login_packet(Player, AccPacket) ->
    case guild_pvp_mod:check_open() of
        true ->
            UserId = Player#player.user_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [] -> {Player, AccPacket};
                [Guildlayer] ->
                    Cd = Guildlayer#guild_pvp_player.enter_cd,
                    Packet  = msg_msg_id_guild_pvp_enter_cd(Cd),
                    {Player, <<AccPacket/binary, Packet/binary>>}
            end;
        _ -> {Player, AccPacket}
    end.

check_in_active_pvp(AttId, DefId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, AttId) of
        [] ->
            false;
        [AttRec] ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, DefId) of
                [] ->
                    false;
                [DefRec] ->
                    {AttRec, DefRec}
            end
    end.

check_and_set_def_player_state(DefId) ->
     case player_api:get_player_pid(DefId) of
         null ->
             false;
         PlayerPid ->
             player_serv:process_call(PlayerPid, ?MODULE, check_and_set_def_player_state_cb, DefId)
     end.
                                        
check_and_set_def_player_state_cb(Player, DefId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, DefId) of
        [] ->
            Result = false;
        [DefRec] ->
            Result =
                case DefRec#guild_pvp_player.state of
                    ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL ->
                        true;
                    ?CONST_CAMP_PVP_PLAYER_STATE_WORKING ->
                        true;
                    _ ->
                        false
                end,
            case Result of
                true ->
                    ?MSG_ERROR("update ~w's state to battle", [DefId]),
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, DefId, 
                                       {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE});
                false ->
                    ok
            end,
            Result
    end,
    {?ok, Result, Player}.

 check_in_active_pve(AttId, DefId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, AttId) of
        [] ->
            false;
        [UserRec] ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, DefId) of
                [] ->
                    false;
                [MonsterRec] ->
                    {UserRec, MonsterRec}
            end
    end.
                

revert_state(DefId) ->
    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, DefId, 
                       {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}).


%% 玩家下线
player_logout(UserId) ->
    case guild_pvp_mod:check_open() of
        false ->
            ok;
        _ ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [] ->ok;
                [UserRec] ->
                    case UserRec#guild_pvp_player.exist of
                        false ->
                            ok;
                        true ->
                            EnterCd = misc:seconds() + ?CONST_GUILD_PVP_ENTER_CD,
                            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                               [{#guild_pvp_player.exist, false}, 
                                                {#guild_pvp_player.enter_cd, EnterCd},
                                                {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]),
                            ets:delete(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId),
                            ets:delete(?CONST_ETS_GUILD_PVP_WATER, UserId),
                            Packet = msg_sc_att_wall_info(UserId, "", 1, 1, true),
                            guild_pvp_mod:broad_wall(Packet),
                            guild_pvp_serv:sub_guild_enter_count(UserRec#guild_pvp_player.gulid_id)
                    end
            end
    end.

enter_guild_pvp(Player) ->
    UserId = Player#player.user_id,
    case guild_pvp_mod:check_open() of
        true ->
            case Player#player.guild of
                ?null ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ENTER_403);
                Guild ->
                    case Guild#guild.guild_id == 0 of
                        true ->
                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ENTER_403);
                        false ->
                            guild_pvp_mod:enter_guild_pvp(Player, Guild)
                    end
            end;
        _ ->
            misc_packet:send_tips(UserId, ?TIP_COMMON_ACTIVITY_NOT_IN_TIME)
    end.



app_guild_pvp(Player, CampId) ->
    UserId = Player#player.user_id,
    case guild_pvp_mod:check_can_app() of
        false ->
            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ACTIVE_START);
        _ ->
            case Player#player.guild of
                ?null ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_APP_403);
                Guild ->
                    case Guild#guild.guild_id == 0 of
                        true ->
                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_APP_403);
                        _ ->
                            case Guild#guild.guild_pos =< ?CONST_GUILD_POSITION_VICE_CHIEF of
                                false ->
                                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_APP_403);
                                _ ->
                                    {ok, Level} = guild_api:get_guild_lv(Guild#guild.guild_id),
                                    case Level < 2 of
                                        true ->
                                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_LV_NOT_ENOUGH);
                                        _ ->
                                            case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, Guild#guild.guild_id) of
                                                [#guild_pvp_guild{is_leader = IsLeader}] ->
                                                    case IsLeader of
                                                        true ->
                                                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_MASTER_CAN_NOT_APP);
                                                        false ->
                                                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_APPED)
                                                    end;
                                                _ ->
                                                    guild_pvp_serv:app_guild_pvp(UserId, Guild, CampId)
                                            end
                                    end
                            end
                    end
            end
    end.      



interval() ->
    Now = misc:seconds(),
    [State|_] = ets:tab2list(?CONST_ETS_GUILD_PVP_STATE),
    interval(Now, State).

interval(Now, #guild_pvp_state{state = ?CONST_GUILD_PVP_STATE_ON, start_time = StartTime}) when StartTime < Now ->
    guild_pvp_serv:start([]);

interval(Now, #guild_pvp_state{state = ?CONST_GUILD_PVP_STATE_START}) ->
    interval(Now);

interval(_, _) ->
    ok.
    

interval(Now) ->
    case Now rem 5 == 0 of
        true ->
            guild_pvp_mod:broad_monster_info(),
            guild_pvp_mod:broad_rank();
        _ ->
            ok
    end.

on(Param) ->
    guild_pvp_serv:on(Param).

off(Param) ->
    guild_pvp_serv:off(Param).

send_guild_map_msg(UserId) ->
    MemberList = ets:tab2list(?CONST_ETS_GUILD_PVP_MAP_INFO),
    FormatFun =
        fun(Member) ->
                Name = Member#guild_pvp_map_info.user_name,
                Sex = Member#guild_pvp_map_info.sex,
                Rank = Member#guild_pvp_map_info.rank,
                Career = Member#guild_pvp_map_info.career,
                Title = Member#guild_pvp_map_info.chenghao,
                UserId1 = Member#guild_pvp_map_info.user_id,
                GuildName = Member#guild_pvp_map_info.guild_name,
                {UserId1,Sex,Career,Rank,Title,Name,GuildName}
        end,
    FormatList = lists:map(FormatFun, MemberList),
    Packet = msg_map_info(FormatList),
    misc_packet:send(UserId, Packet).

%% packet msg

%% 交战区怪物信息
%%[{MonsterId,MonsterX,MonsterY,TargetX,TargetY,Speed,IsBattle,CampId,HpNow,HpMax,Type}]
msg_monster_info(List1) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_MONSTER_INFO, ?MSG_FORMAT_GUILD_PVP_MONSTER_INFO, [List1]).
%% 广播排行榜
%%[AddPer,DefPer,AddCount,DefCount,SelfGuildScore,{GuildName,GuildScore},IsWallDead,IsCarDead,{ScoreRankScore,ScoreRankUserName}]
msg_broad_rank(AddPer,DefPer,AddCount,DefCount,SelfGuildScore,List1,IsWallDead,IsCarDead,List2) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_BROAD_RANK, ?MSG_FORMAT_GUILD_PVP_BROAD_RANK, [AddPer,DefPer,AddCount,DefCount,SelfGuildScore,List1,IsWallDead,IsCarDead,List2]).
%% 鼓舞成功
%%[Per]
msg_sc_encourage(Per) ->
    {Power, Pro, Sex, UserName}    = rank_api:get_max_power(),
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_ENCOURAGE, ?MSG_FORMAT_GUILD_PVP_SC_ENCOURAGE, [Per, Power, UserName, Pro, Sex]).
%% 状态变化广播
%%[{HpMax,HpNow,State,Campid,SteakKill,IsLeader,GuildId,UserId}]
msg_sc_state_change(List1) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_STATE_CHANGE, ?MSG_FORMAT_GUILD_PVP_SC_STATE_CHANGE, [List1]).
%% 怪物血量变化
%% 怪物血量变化
%%[Cc,HpMax,HpNow,MonsterId]
msg_monster_hp(Cc,HpMax,HpNow,MonsterId) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_MONSTER_HP, ?MSG_FORMAT_GUILD_PVP_MONSTER_HP, [Cc,HpMax,HpNow,MonsterId]).
%% 怪物死亡
%%[MonsterId]
msg_monster_dead(MonsterId) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_MONSTER_DEAD, ?MSG_FORMAT_GUILD_PVP_MONSTER_DEAD, [MonsterId]).

%% 广播结束包
%%[IsWin,LeaderName,Score,Rank,Copper,Jungong,Exp,BattleCopper]
msg_broad_end(IsWin,LeaderName,Score,Rank,Copper,Jungong,Exp,BattleCopper, IsAtt) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_BROAD_END, ?MSG_FORMAT_GUILD_PVP_BROAD_END, [IsWin,LeaderName,Score,Rank,Copper,Jungong,Exp,BattleCopper, IsAtt]).

%% 报名面板信息
%%[LastWinCamp,TowerOwner,AttCount,DefCount,SelfCamp,IsTowerOwner,IsDefFull,{GuildName,GuildLeaderName,Score,GuildId}]
msg_app_info(LastWinCamp,TowerOwner,AttCount,DefCount,SelfCamp,IsTowerOwner,IsDefFull,List1) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_APP_INFO, ?MSG_FORMAT_GUILD_PVP_APP_INFO, [LastWinCamp,TowerOwner,AttCount,DefCount,SelfCamp,IsTowerOwner,IsDefFull,List1]).

%% 申请列表
%%[{DefGuildId,DefGuildName,DefGuildPower},{AttGuildId,AttGuildName,AttGuildPower}]
%% 申请列表
%%[IsLeaderGuild,RestMemberCount,{DefGuildId,DefGuildName,DefGuildPower},{AttGuildId,AttGuildName,AttGuildPower}]
msg_app_list(IsLeaderGuild,RestMemberCount,List1,List2) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_APP_LIST, ?MSG_FORMAT_GUILD_PVP_APP_LIST, [IsLeaderGuild,RestMemberCount,List1,List2]).

%% 进入战场界面返回
%%[{GuildId,GuildName,入场人数},{DefGuildId,DefGuildName,DefGuildEnter}]
msg_sc_enter_info(List1,List2) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_ENTER_INFO, ?MSG_FORMAT_GUILD_PVP_SC_ENTER_INFO, [List1,List2]).

%% 军团城主信息返回
%%[OwnerName,IsInBattle]
msg_sc_tower_owner_info(OwnerName,IsInBattle) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_TOWER_OWNER_INFO, ?MSG_FORMAT_GUILD_PVP_SC_TOWER_OWNER_INFO, [OwnerName,IsInBattle]).

%% 广播采集城墙信息
%%[{UserId,Name,Level,State},IsWallDead,IsCarDead]
msg_sc_att_wall_list(List1,IsWallDead,IsCarDead) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_ATT_WALL_LIST, ?MSG_FORMAT_GUILD_PVP_SC_ATT_WALL_LIST, [List1,IsWallDead,IsCarDead]).

%% boss状态
%%[IsWallDead,IsCarDead]
msg_boss_state(IsWallDead,IsCarDead) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_BOSS_STATE, ?MSG_FORMAT_GUILD_PVP_BOSS_STATE, [IsWallDead,IsCarDead]).

%% 进入军团战成功
%%[CampId,EndTimestamp,BringBackTimes]
msg_enter_success(CampId,EndTimestamp,BringBackTimes) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_ENTER_SUCCESS, ?MSG_FORMAT_GUILD_PVP_ENTER_SUCCESS, [CampId,EndTimestamp,BringBackTimes]).

%% 时间同步
%%[EndTimestamp]
msg_time_syc(EndTimestamp) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_TIME_SYC, ?MSG_FORMAT_GUILD_PVP_TIME_SYC, [EndTimestamp]).

%% 冷却时间
%%[Time]
msg_msg_id_guild_pvp_enter_cd(Time) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_MSG_ID_GUILD_PVP_ENTER_CD, ?MSG_FORMAT_GUILD_PVP_MSG_ID_GUILD_PVP_ENTER_CD, [Time]).

%% 技能冷却时间
%%[AttWallCd,FixWallCd]
msg_skill_cd(AttWallCd,FixWallCd) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SKILL_CD, ?MSG_FORMAT_GUILD_PVP_SKILL_CD, [AttWallCd,FixWallCd]).

%% 军团战滑动公告
%%[Type,Name]
msg_announment(Type,Name) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_ANNOUNMENT, ?MSG_FORMAT_GUILD_PVP_ANNOUNMENT, [Type,Name]).
%%

%% 浴火重生是否成功
%%[IsSuccess]
msg_bring_back_result(IsSuccess) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_BRING_BACK_RESULT, ?MSG_FORMAT_GUILD_PVP_BRING_BACK_RESULT, [IsSuccess]).

%% 单挑墙状态信息
%%[UserId,UserName,Level,State,IsDelete]
msg_sc_att_wall_info(UserId,UserName,Level,State,IsDelete) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_ATT_WALL_INFO, ?MSG_FORMAT_GUILD_PVP_SC_ATT_WALL_INFO, [UserId,UserName,Level,State,IsDelete]).

%% 主程地图信息
%%[{UserId,Sex,Career,Rank,Chenghao,UserName,GuildName}]
msg_map_info(List1) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_MAP_INFO, ?MSG_FORMAT_GUILD_PVP_MAP_INFO, [List1]).

%% 物品不足
%%[ItemId]
msg_guild_item_not_enough(ItemId) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_GUILD_ITEM_NOT_ENOUGH, ?MSG_FORMAT_GUILD_PVP_GUILD_ITEM_NOT_ENOUGH, [ItemId]).


%% 军团成员列表
%%[{UserId,UserName}]
msg_sc_guild_member_list(List1) ->
    misc_packet:pack(?MSG_ID_GUILD_PVP_SC_GUILD_MEMBER_LIST, ?MSG_FORMAT_GUILD_PVP_SC_GUILD_MEMBER_LIST, [List1]).

%% Local Functions
%%

