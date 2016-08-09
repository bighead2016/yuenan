%% Author: PXR
%% Created: 2013-8-30
%% Description: TODO: Add description to guild_pvp_mod
-module(guild_pvp_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/record.map.hrl").

-define(CONST_GUILD_PVP_ATT_COUNT, 6). %% 攻防队伍上限
-define(CONST_GUILD_PVP_DEF_COUNT, 2). %% shou防队伍上限
%%
%% Exported Functions
%%
-export([
        add_att_wall_cd/0, % 增加进攻城墙cd
        add_boss_hurt/2,   % 增加对boss的伤害几率
        add_copper/2,      % 加铜币
        add_exploit/2,     % 加功勋
        add_exploit_cb/2,  % 加功勋回调
        add_fix_wall_cd/0, % 加修墙cd
        add_meritorious/2, % 加军团贡献
        add_meritorious_cb/2, % 加军团战贡献回调
        add_player_guild_pvp_copper/2, % 增加玩家铜钱几率
        battle_over/2,  % 战斗回调
        boss_state_packet/0, % boss状态广播包
        broad/1, % 玩法广播
        broad_camp/2, % 阵营广播
        broad_cd/0, % 广播技能cd
        broad_map/2, % 地图广播
        broad_master/1, % 广播各个军团战的军团长，副军团长
        broad_monster_info/0, % 广播怪物信息
        broad_rank/0, % 广播排行榜
        broad_self_state/1, % 广播自己的状态，包括血量和状态
        check_is_first/0, % 检查是否是第一次军团战
        check_open/0, % 检查军团战是否开启
        check_start/0, % 检查军团战战时否开始
        check_wall_live/0, % 检查城墙是否活着
        choose_guild/0, %12点报名截止，选出最终参加军团战军团
        enter_guild_pvp/2, % 进入军团战玩法
        get_and_clear_boss_hurt/1, % 获得并且清除玩家对boss的伤害值，每场战斗结束的时候掉
        get_and_boss_hurt/1,
        get_att_guild_list/0, % 拿到进攻军团的列表
        get_att_sorted_list/0, % 拿到进攻军团排序后的列表，按积分排序
        get_car_att_cd/0, % 得到战车出击技能的cd
        get_car_att_cost/0, % 得到战车出击技能的话费
        get_def_guild_list/0, % 得到所有防守军团的列表，不包括城主
        get_def_sorted_list/0, % 得到所有防守军团排序后的列表，包括城主
        get_encourage/1, % 得到当前的鼓舞值
        get_end_time/0, % 得到获得结束的时间戳
        get_enter_cd/1, % 拿到玩家进入玩法的cd时间
        get_fix_wall_cd/0, % 拿到修理城墙技能的cd
        get_fix_wall_cost/0, % 拿到修理城墙技能的话费
        get_guild_member/1, % 拿到军团成员列表
        get_hp_value/1, % 转换hptuiple为hp正式值
        get_safe_map_id/0, % 拿到安全区地图的id
        get_scores_by_kill_boss/1, % 拿到击杀boss获得的积分
        get_skill_cd/1, %得到技能cd
        get_tower_owner_id/0, %得到城主军团id
        get_tower_owner_name/0, % 得到城主军团名字
        guild_db_add_app_guild/1, % 向数据库插入申请军团信息 
        guild_db_delete_app/0, % 删除数据库中申请军团的信息
        guild_db_get_app/0, % 取得数据库中申请的军团信息
        guild_db_update_app_guild/2, % 更新数据库中申请军团的信息
        init_guild_pvp_from_db/0, % 从数据库中初始化申请军团列表
        monster_info_packet/0, % 怪物信息广播包
        save_guild_pvp_guild_to_db/0, % 报错军团列表到数据库中
        send_mail1/2, % 发送报名成功/失败军团邮件
        send_msg_announment/2, % 发送公告的协议
        broad_wall/1, %广播给观察墙的人
        check_can_app/0, % 检查是否可以报名
        get_choosed_count/0 %被选中的守城军团数
]).


%%
%% API Functions
%%

send_msg_announment(Name, Type) ->
    Packet = guild_pvp_api:msg_announment(Type, Name),
    broad(Packet).

add_player_guild_pvp_copper(UserId, AddCopper) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [UserRec] ->
            OldCopper = UserRec#guild_pvp_player.copper,
            NewCopper = OldCopper + AddCopper,
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, {#guild_pvp_player.copper, NewCopper})
    end.



broad_cd() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT) of
        [] ->
            ok;
        [AttCampRec] ->
            Now = misc:seconds(),
            NextAttCd = max(Now, AttCampRec#guild_pvp_camp.next_fire_time),
            case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF) of
                [] ->
                    ok;
                [DefCampRec] ->
                    NextFixCd = max(Now, DefCampRec#guild_pvp_camp.next_fix_time),
                    Packet = guild_pvp_api:msg_skill_cd(NextAttCd, NextFixCd),
                    broad_master(Packet)
            end
    end.

check_car_live() ->
    case ets:tab2list(?CONST_ETS_GUILD_PVP_MONSTER) of
        [] ->
            false;
        MonsterList ->
            Pred =
                fun(Monster) ->
                        case Monster#guild_pvp_monster.monster_type of
                            ?CONST_GUILD_PVP_BOSS_TYPE_CAR ->
                                Monster#guild_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD;
                            _ ->
                                true
                        end
                end,
            lists:all(Pred, MonsterList)
    end.

check_wall_live() ->
    case ets:tab2list(?CONST_ETS_GUILD_PVP_MONSTER) of
        [] ->
            false;
        MonsterList ->
            Pred =
                fun(Monster) ->
                        case Monster#guild_pvp_monster.monster_type of
                            ?CONST_GUILD_PVP_BOSS_TYPE_WALL ->
                                Monster#guild_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD;
                            _ ->
                                true
                        end
                end,
            lists:all(Pred, MonsterList)
    end.

get_skill_cd(UserId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT) of
        [] ->
            ok;
        [AttCampRec] ->
            Now = misc:seconds(),
            NextAttCd = max(Now, AttCampRec#guild_pvp_camp.next_fire_time),
            case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF) of
                [] ->
                    ok;
                [DefCampRec] ->
                    NextFixCd = max(Now, DefCampRec#guild_pvp_camp.next_fix_time),
                    Packet = guild_pvp_api:msg_skill_cd(NextAttCd, NextFixCd),
                    misc_packet:send(UserId, Packet)
            end
    end.

add_att_wall_cd() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT) of
        [] ->
            ok;
        [_CampRec] ->
            Now = misc:seconds(),
            NextCd = Now + ?CONST_GUILD_PVP_ATT_WALL_CD,
            ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT, 
                               {#guild_pvp_camp.next_fire_time, NextCd}),
            broad_cd()
    end.

add_fix_wall_cd() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF) of
        [] ->
            ok;
        [_CampRec] ->
            Now = misc:seconds(),
            NextCd = Now + ?CONST_GUILD_PVP_FIX_WALL_CD,
            ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF, 
                               {#guild_pvp_camp.next_fix_time, NextCd}),
            broad_cd()
    end.


monster_info_packet() ->
    MonsterList = ets:tab2list(?CONST_ETS_GUILD_PVP_MONSTER),
    FiterFun =
        fun(Monster1) -> 
                Monster1#guild_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD orelse Monster1#guild_pvp_monster.monster_type == ?CONST_GUILD_PVP_BOSS_TYPE_WALL
        end,
    MonsterList1 = lists:filter(FiterFun, MonsterList),
    FmFun =
        fun(Monster) ->
                CampId = Monster#guild_pvp_monster.camp_id,
                MonsterType = Monster#guild_pvp_monster.monster_type,
                MonsterId = Monster#guild_pvp_monster.monster_id,
                MonsterConfig = data_monster:get_monster(MonsterId),
                MonsterX = MonsterConfig#monster.x,
                MonsterY = MonsterConfig#monster.y,
                HpNow = 
                    case Monster#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD of
                        true ->
                            0;
                        _ ->
                            Monster#guild_pvp_monster.hp
                    end,
                HpMax = Monster#guild_pvp_monster.hp_max,
                IsBattle = Monster#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_BATTLE,
                {MonsterId,MonsterX,MonsterY,MonsterX,MonsterY, 0,IsBattle,CampId,HpNow,HpMax,MonsterType}
        end,
    FmMonsterList = lists:map(FmFun, MonsterList1),
    guild_pvp_api:msg_monster_info(FmMonsterList).

broad_monster_info() ->
    Packet = monster_info_packet(),
    broad_map(Packet).

broad_rank() ->
    AttPer = get_encourage(?CONST_GUILD_PVP_CAMP_ATT),
    DefPer = get_encourage(?CONST_GUILD_PVP_CAMP_DEF),
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    TotalPlayerCount = ets:info(?CONST_ETS_GUILD_PVP_PLAYER, size),
    DefFun = 
        fun(Player) ->
                Player#guild_pvp_player.camp_id == ?CONST_GUILD_PVP_CAMP_DEF
        end,
    DefList = lists:filter(DefFun, PlayerList),
    DefCount = length(DefList),
    AttCount = TotalPlayerCount - DefCount,
    AttGuildList = get_att_guild_list(),
    SortFun = 
        fun(#guild_pvp_guild{score = Score1}, #guild_pvp_guild{score = Score2}) ->
                Score1 > Score2
        end,
    SortedAttList = lists:sort(SortFun, AttGuildList),
    Top3Att = lists:sublist(SortedAttList, 3),
    FormatFun =
        fun(TopGuild) ->
                {TopGuild#guild_pvp_guild.name, TopGuild#guild_pvp_guild.score, TopGuild#guild_pvp_guild.guild_id}
        end,
    Top3FormatAtt = lists:map(FormatFun, Top3Att),
    SelfGuildList = guild_pvp_serv:get_guild_player_rank(),
    broad(PlayerList, AttPer, DefPer, AttCount, DefCount, Top3FormatAtt, SelfGuildList).

broad([], _AttPer, _DefPer, _AttCount, _DefCount, _Top2Att, _SelfGuildList) ->ok;
broad([Player|RestPlayerList], AttPer, DefPer, AttCount, DefCount, Top3FormatAtt, SelfGuildList) ->
    case Player#guild_pvp_player.exist of
        false ->
            ok;
        _ ->
            UserId = Player#guild_pvp_player.user_id,
            GuildId = Player#guild_pvp_player.gulid_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
                [] ->
                    ok;
                [GuildRec] ->
                    SelfGuildScore = GuildRec#guild_pvp_guild.score,
                    IsWallDead = not check_wall_live(),
                    IsCarDead = not check_car_live(),
                    SelfGuildScoreList = 
                        case lists:keyfind(GuildId, 1, SelfGuildList) of
                            false ->
                                [];
                            {_, GList} ->
                              GList
                        end,
                    Packet = guild_pvp_api:msg_broad_rank(AttPer, DefPer, AttCount, DefCount, SelfGuildScore, Top3FormatAtt, IsWallDead, IsCarDead, SelfGuildScoreList),
                    misc_packet:send(UserId, Packet)
            end
            
    end,
    broad(RestPlayerList, AttPer, DefPer, AttCount, DefCount, Top3FormatAtt, SelfGuildList).

get_and_clear_boss_hurt(UserId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            0;
        [PlayerRec] ->
             ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, {#guild_pvp_player.hurt, 0}),
             PlayerRec#guild_pvp_player.hurt
    end.

get_and_boss_hurt(UserId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            0;
        [PlayerRec] ->
             PlayerRec#guild_pvp_player.hurt
    end.

add_boss_hurt(UserId, Hurt) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            NewHurt = PlayerRec#guild_pvp_player.hurt + Hurt,
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, {#guild_pvp_player.hurt, NewHurt})
    end.

get_scores_by_kill_boss(MonsterId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId) of
        [] ->
            {0,0};
        [MonsterRec] ->
            case MonsterRec#guild_pvp_monster.monster_type of
                ?CONST_GUILD_PVP_BOSS_TYPE_BOSS ->
                    {1000000, 0};
                ?CONST_GUILD_PVP_BOSS_TYPE_CAR ->
                    {0, 1000};
                ?CONST_GUILD_PVP_BOSS_TYPE_WALL ->
                    {500000, 0}
            end
    end.
                

%% 取得城主id
get_tower_owner_name() ->
    DefList = get_def_sorted_list(),
    Fun =
        fun(Guild) ->
                Guild#guild_pvp_guild.is_leader
        end,
    case lists:filter(Fun, DefList) of
        [] ->
           "无军团占领";
        [LeaderRec] ->
            ?MSG_ERROR("LeaderRec is ~w", [LeaderRec]),
            LeaderRec#guild_pvp_guild.name
    end.

%% 取得城主id
get_tower_owner_id() ->
    DefList = get_all_def_guild_list(),
    Fun =
        fun(Guild) ->
                Guild#guild_pvp_guild.is_leader
        end,
    case lists:filter(Fun, DefList) of
        [] ->
           0;
        [LeaderRec] ->
            LeaderRec#guild_pvp_guild.guild_id
    end.

add_copper(UserId, Value) ->
    player_money_api:plus_money(UserId, 
        ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_GUILD_PVP_CAMP_AWARD).

add_exploit(UserId, Value) ->
    player_api:process_send(UserId, ?MODULE, add_exploit_cb, Value).

add_exploit_cb(Player, Value) ->
    guild_api:plus_exploit(Player, Value, ?CONST_COST_GUILD_PVP_CAMP_AWARD).

add_meritorious(UserId, Value) ->
    player_api:process_send(UserId, ?MODULE, add_meritorious_cb, Value).

add_meritorious_cb(Player, Value) ->
    player_api:plus_meritorious(Player, Value, ?CONST_COST_GUILD_PVP_CAMP_AWARD).

get_hp_value(HpList) ->
    get_hp_value(HpList, {1,1}).
get_hp_value([], {Now, Max}) ->
    {Now, Max};
get_hp_value([{_, N, M}|Rest], {Now, Max}) ->
    get_hp_value(Rest, {Now + N, Max + M}).

broad_self_state(UserId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [Rec] ->
            {HpMax, HpNow} = get_hp_value(Rec#guild_pvp_player.hp),
            Campid = Rec#guild_pvp_player.camp_id,
            State = Rec#guild_pvp_player.state,
            SteakKill = Rec#guild_pvp_player.steak_kill,
            IsLeader = Rec#guild_pvp_player.position == ?CONST_GUILD_POSITION_CHIEF,
            GuildId = Rec#guild_pvp_player.gulid_id,
            Power = Rec#guild_pvp_player.power,
            List = [{HpMax,HpNow,State,Campid,SteakKill,IsLeader,GuildId, UserId, Rec#guild_pvp_player.position, Power}],
            Packet = guild_pvp_api:msg_sc_state_change(List),
            broad(Packet)
    end.

get_battle_map() ->
    41004.

broad_map(Packet) ->
    broad_map(Packet, get_battle_map()).

broad_map(Packet, MapId) ->
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    broad_map(PlayerList, Packet, MapId).
broad_map([], _ ,_) ->ok;
broad_map([PlayerRec|Rest], Packet, MapId) ->
    case PlayerRec#guild_pvp_player.map_id == MapId andalso PlayerRec#guild_pvp_player.exist == true of
         true ->
            misc_packet:send(PlayerRec#guild_pvp_player.user_id, Packet);
        _ ->
            ok
    end,
    broad_map(Rest, Packet, MapId).

broad_master(Packet) ->
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    broad_master(PlayerList, Packet).
broad_master([], _) ->ok;
broad_master([Player|RestPlayer], Packet) ->
    case Player#guild_pvp_player.exist == true 
        andalso Player#guild_pvp_player.position =< ?CONST_GUILD_POSITION_VICE_CHIEF of
        true ->
            misc_packet:send(Player#guild_pvp_player.user_id, Packet);
        _ ->
            ok
    end,
    broad_master(RestPlayer, Packet).

broad_wall(Packet) ->
    WatchList = ets:tab2list(?CONST_ETS_GUILD_PVP_WATER),
    Fun =
        fun(WatchRec) ->
                UserId = WatchRec#guild_pvp_watch.player_id,
                misc_packet:send(UserId, Packet)
        end,
    lists:foreach(Fun, WatchList).

broad_camp(CampId, Packet) ->
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    broad_camp(CampId, Packet, PlayerList).
broad_camp(_CampId, _Packet, []) ->ok;
broad_camp(CampId, Packet, [Player|PlayerList]) ->
    case Player#guild_pvp_player.camp_id of
        CampId ->
            misc_packet:send(Player#guild_pvp_player.user_id, Packet);
        _ ->
            ok
    end,
    broad_camp(CampId, Packet, PlayerList).

broad(Packet) ->
    PlayerList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    broad(PlayerList, Packet).
broad([], _) ->ok;
broad([PlayerRec|Rest], Packet) ->
    case PlayerRec#guild_pvp_player.exist of
        true ->
            misc_packet:send(PlayerRec#guild_pvp_player.user_id, Packet);
        _ ->
            ok
    end,
    broad(Rest, Packet).

battle_over(Result, Param) ->
    _Now = misc:seconds(),
    #param{ 
            ad1 = Hp1, 
            ad2 = Hp2, 
            ad3 = Type,
            ad4 = {UserId1, UserId2}} = Param,
    
    Fun = 
        fun({{Type, Id}, MaxHp, Hp}) ->
                NewHp = max(Hp, 1),
                {{Type, Id}, MaxHp, NewHp}
        end,
    NewHp1 = lists:map(Fun, Hp1),
    case Type of
        ?CONST_BATTLE_GUILD_PVP ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId2) of
                [] ->
                    ok;
                [_WallRec] ->
                    WallPacket = guild_pvp_api:msg_sc_att_wall_info(UserId2, "UserName", 1, 1, true),
                    broad_wall(WallPacket)
            end,
            case Result of
                ?CONST_BATTLE_RESULT_LEFT ->
                    battle_over_pvp_win(UserId1, Hp1),
                    battle_over_pvp_lose(UserId2, Hp2);
                _ ->
                    battle_over_pvp_win(UserId2, Hp2),
                    battle_over_pvp_lose(UserId1, Hp1)
            end;
        _ ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId1) of
                [] ->
                    ok;
                [_WallRec] ->
                    WallPacket = guild_pvp_api:msg_sc_att_wall_info(UserId1, "UserName", 1, 1, true),
                    broad_wall(WallPacket)
            end,
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId1) of
                [] ->
                    ok;
                [UserRec1] ->
                    OldScore = UserRec1#guild_pvp_player.scores,
                    Hurt = get_and_clear_boss_hurt(UserId1),
                    ScoreAdd = round((Hurt div 10000) + 1),
                    NewScore = OldScore + ScoreAdd,
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId1, {#guild_pvp_player.scores, NewScore}),
                    guild_pvp_serv:add_pvp_score(UserRec1#guild_pvp_player.user_id, UserRec1#guild_pvp_player.name, UserRec1#guild_pvp_player.gulid_id, ScoreAdd)
            end,
            
            case Result of
                ?CONST_BATTLE_RESULT_LEFT ->
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId1, 
                                       [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL},
                                        {#guild_pvp_player.hp, NewHp1}]);
                _ ->
                    ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId1,
                                       [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD},
                                        {#guild_pvp_player.hp, []}
                                        ]),
                    ets:delete(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId1)
            end,
            broad_self_state(UserId1)
    end.
    
     
battle_over_pvp_win(UserId, Hp) ->
    ?MSG_DEBUG("Guild pvp  ~w is --winner ", [UserId]),
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->ok;
        [GuildPlayerRec] ->
            Fun = 
                fun({{Type, Id}, MaxHp, Hp}) ->
                        NewHp = max(Hp, 1),
                        {{Type, Id}, MaxHp, NewHp}
                end,
            NewHpList = lists:map(Fun, Hp),
            NewKillStreak = GuildPlayerRec#guild_pvp_player.steak_kill + 1,
            NewScores = GuildPlayerRec#guild_pvp_player.scores + 10,
            UpdateParam = [ {#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL},                           
                            {#guild_pvp_player.hp, NewHpList},
                            {#guild_pvp_player.steak_kill, NewKillStreak},
							{#guild_pvp_player.scores, NewScores}
                            ],
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, UpdateParam),
			
			GuildId = GuildPlayerRec#guild_pvp_player.gulid_id,
			guild_pvp_serv:add_pvp_score(GuildPlayerRec#guild_pvp_player.user_id, GuildPlayerRec#guild_pvp_player.name, GuildId, 10),
			broad_self_state(UserId)

    end.

battle_over_pvp_lose(UserId, _Hp) ->
	?MSG_DEBUG("Guild pvp  ~w is --loser ", [UserId]),
    ets:delete(?CONST_ETS_GUILD_PVP_WATER, UserId),
	case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
		[] ->ok;
		[GuildPlayerRec] ->
			NewScores = GuildPlayerRec#guild_pvp_player.scores + 1,
			UpdateParam = [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD}, 
						   {#guild_pvp_player.hp, []},
						   {#guild_pvp_player.steak_kill, 0},
						   {#guild_pvp_player.scores, NewScores}],
			ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, UpdateParam),
			
			GuildId = GuildPlayerRec#guild_pvp_player.gulid_id,
			guild_pvp_serv:add_pvp_score(GuildPlayerRec#guild_pvp_player.user_id, GuildPlayerRec#guild_pvp_player.name, GuildId, 1),
			
			broad_self_state(UserId)
	end.

enter_guild_pvp(Player, Guild) ->
    UserId = Player#player.user_id,
    GuildId = Guild#guild.guild_id,
    EndTimeStamp = get_end_time(),
    case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_GUILD_PVP) of
        {?true, Player2} ->
            case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
                [] ->
                    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
                        [] ->
                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ENTER_403);
                        [GulidPvpRec] ->
                            CampId = GulidPvpRec#guild_pvp_guild.camp_id,
                            GuldPvpPlayer = 
                                #guild_pvp_player{user_id = UserId,
                                      exist = true,
                                      name = player_api:get_name(UserId),
                                      lv = player_api:get_level(UserId),
                                      gulid_id = GuildId,
                                      camp_id = CampId,
                                      power = partner_api:caculate_camp_power(Player2),
                                      position = Guild#guild.guild_pos,
                                      guild_name = Guild#guild.guild_name},
                            ets:insert(?CONST_ETS_GUILD_PVP_PLAYER, GuldPvpPlayer),
                            guild_pvp_serv:add_guild_enter_count(GuildId),
                            Packet = guild_pvp_api:msg_enter_success(CampId, EndTimeStamp, 0),
                            misc_packet:send(UserId, Packet),
                            enter_map(Player2, CampId)
                    end;
                [Rec] ->
                    case get_enter_cd(Rec) of
                        0 ->
                            CampId = Rec#guild_pvp_player.camp_id,
                            Packet = guild_pvp_api:msg_enter_success(CampId, EndTimeStamp, Rec#guild_pvp_player.bring_time),
                            misc_packet:send(UserId, Packet),
                            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, 
                                              [{#guild_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL},
                                               {#guild_pvp_player.exist, true}]),
                            guild_pvp_serv:add_guild_enter_count(GuildId),
                            enter_map(Player2, CampId);
                        _CdLeft ->
                            misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_ENTER_CD)
                    end
            end;
        {?false, Player2, Tips} ->
            misc_packet:send_tips(UserId, Tips),
            {ok, Player2}
    end.
                    
get_choosed_count() ->
    DefList = get_def_guild_list(),
    Fun =
        fun(Guild) ->
                Guild#guild_pvp_guild.choosed_def
        end,
    ChoosedDefList = lists:filter(Fun, DefList),
    length(ChoosedDefList).

choose_guild() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    AttFilter = 
        fun(Guild) ->
                Guild#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_ATT
        end,
    FiltedAttList = lists:filter(AttFilter, GuildList),
    AttSort = 
        fun(#guild_pvp_guild{power = Power1}, #guild_pvp_guild{power = Power2}) ->
                Power1 > Power2
        end,
    SortedAttList = lists:sort(AttSort, FiltedAttList),
    AttList = lists:sublist(SortedAttList, ?CONST_GUILD_PVP_ATT_COUNT),
    RestAttList = SortedAttList -- AttList,
    FormatFun = 
        fun(#guild_pvp_guild{guild_id = GuildId}) ->
                GuildId
        end,
    AttIdList = lists:map(FormatFun, AttList),
    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT, {#guild_pvp_camp.guild_id_list, AttIdList}),

    CampDef = ets_api:lookup(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF),
    LeaderId = CampDef#guild_pvp_camp.leader_guild_id,
    LeaderRec = ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, LeaderId),
    send_mail(LeaderRec, AttList, RestAttList),

    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_GUILD),
    NewGuildList = AttList ++ LeaderRec,
    ets:insert(?CONST_ETS_GUILD_PVP_GUILD, NewGuildList),
    ok.
                
send_mail(DefList, AttList, RestAttList) ->
    send_mail1(DefList, ?CONST_MAIL_DEF_GUILD_APP_SUCCESS),
    send_mail1(AttList, ?CONST_MAIL_ATTR_GUILD_APP_SUCCESS),
    send_mail1(RestAttList, ?CONST_MAIL_APP_FAILED).

       
send_mail1(GuildList, MailId) ->
    Fun = 
        fun(Guild) ->
                GuildId = Guild#guild_pvp_guild.guild_id,
                GuildMember = get_guild_member(GuildId),
                NameFun = 
                    fun(UserId) ->
                            player_api:get_name(UserId)
                    end,
                NameList = lists:map(NameFun, GuildMember),
                mail_api:send_system_mai_to_some(NameList, <<>>, <<>>, MailId, [],[], 0, 0, 0, 0)
        end,
    lists:foreach(Fun, GuildList).

check_open() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state) of
        [] ->
            false;
        [Rec] ->
            case Rec#guild_pvp_state.state of
                ?CONST_GUILD_PVP_STATE_OFF ->
                    false;
                ?CONST_GUILD_PVP_STATE_READY ->
                    false;
                _ ->
                    true
            end
    end.

check_can_app() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state) of
        [] ->
            true;
        [Rec] ->
            case Rec#guild_pvp_state.state of
                ?CONST_GUILD_PVP_STATE_OFF ->
                    W = misc:week(),
                    case W /= 3 andalso W /=7 of
                        true ->
                            true;
                        false ->
                            {H,_M,_S} = time(),
                            case  H >= 12 andalso H < 20 of
                                true ->
                                    false;
                                _ ->
                                    true
                            end
                    end;
                ?CONST_GUILD_PVP_STATE_READY ->
                    false;
                _ ->
                    false
            end
    end.

check_start() ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state) of
        [] ->
            false;
        [Rec] ->
            case Rec#guild_pvp_state.state of
                ?CONST_GUILD_PVP_STATE_START ->
                    true;
                _ ->
                    false
            end
    end.

%%
%% Local Functions
%%

get_enter_cd(Rec) ->
    EnterCd = Rec#guild_pvp_player.enter_cd,
    Now = misc:seconds(),
    max(0, EnterCd - Now).

enter_map(Player, CampId) ->
    MapId = get_safe_map_id(CampId),
    Player1 = map_api:enter_map(Player, MapId),
    {ok, Player1}.

get_safe_map_id(CampId) ->
    case CampId of
        ?CONST_GUILD_PVP_CAMP_ATT ->
            41005;
        _ ->
            41006
    end.

get_safe_map_id() ->
    [41005,41006].

get_encourage(CampId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
        [] ->
            0;
        [CampRec] ->
            10 * CampRec#guild_pvp_camp.encourage_times
    end.

get_def_guild_list() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    FilterFun =  
        fun(Guild) -> 
                Guild#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_DEF andalso
                Guild#guild_pvp_guild.is_leader == false
        end,
    lists:filter(FilterFun, GuildList). 

get_all_def_guild_list() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    FilterFun =  
        fun(Guild) -> 
                Guild#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_DEF 
        end,
    lists:filter(FilterFun, GuildList). 


get_def_sorted_list() ->
    DefList = get_all_def_guild_list(),
    SortFun =
        fun(#guild_pvp_guild{score = Score1}, #guild_pvp_guild{score = Score2}) ->
                Score1 > Score2
        end,
    lists:sort(SortFun, DefList).

get_att_sorted_list() ->
    AttList = get_att_guild_list(),
    SortFun =
        fun(#guild_pvp_guild{score = Score1}, #guild_pvp_guild{score = Score2}) ->
                Score1 > Score2
        end,
    lists:sort(SortFun, AttList).

get_att_guild_list() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    FilterFun = 
        fun(Guild) ->
                Guild#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_ATT
        end,
    lists:filter(FilterFun, GuildList).

save_guild_pvp_guild_to_db() ->
    GuildList = ets:tab2file(?CONST_ETS_GUILD_PVP_GUILD),
    save_guild_pvp_guild_to_db(GuildList).

save_guild_pvp_guild_to_db([]) ->
    ok;
save_guild_pvp_guild_to_db([Guild|RestGuildList]) ->
    CampId = Guild#guild_pvp_guild.camp_id,
    ChooseDef = Guild#guild_pvp_guild.choosed_def,
    GuildId = Guild#guild_pvp_guild.guild_id,
    IsLeader = Guild#guild_pvp_guild.is_leader,
    mysql_api:insert(game_guild_pvp_guild, [camp_id, choose_def, guild_id, is_leader], 
        [CampId, ChooseDef, GuildId, IsLeader]),
    save_guild_pvp_guild_to_db(RestGuildList).

init_guild_pvp_from_db() ->
    case mysql_api:select_execute(<<"select `camp_id`, `choose_def`, `guild_id`, `is_leader` from `game_guild_pvp_guild`; ">>) of
        {ok, Datas} ->
            init_guild_pvp_from_db(Datas);
        _ ->
            ok
    end.

init_guild_pvp_from_db([]) ->
    ok;
init_guild_pvp_from_db([{[CampId], [ChooseDef], [GuildId], [IsLeader]}|Rest]) ->
    GuildName = guild_api:get_guild_name(GuildId),
    ets:insert(?CONST_ETS_GUILD_PVP_GUILD, #guild_pvp_guild{camp_id = CampId,
															name =  GuildName,
                                                            choosed_def = ChooseDef, 
                                                            is_leader = IsLeader, 
                                                            guild_id = GuildId}),
    init_guild_pvp_from_db(Rest).

get_guild_member(GuildId) ->
    case guild_api:ets_guild_data(GuildId) of
        ?null ->[];
        #guild_data{member_list = MemberList} ->
            MemberList
    end.


get_car_att_cost() ->
    SkillRec = data_guild_pvp:get_guild_pvp_skill(?CONST_GUILD_PVP_SKILL_CAR_ATT),
    SkillRec#rec_guild_pvp_skill.cost.

get_car_att_cd() ->
    SkillRec = data_guild_pvp:get_guild_pvp_skill(?CONST_GUILD_PVP_SKILL_CAR_ATT),
    SkillRec#rec_guild_pvp_skill.cd.

get_fix_wall_cost() ->
    SkillRec = data_guild_pvp:get_guild_pvp_skill(?CONST_GUILD_PVP_SKILL_FIX_WALL),
    SkillRec#rec_guild_pvp_skill.cost.

get_fix_wall_cd() ->
    SkillRec = data_guild_pvp:get_guild_pvp_skill(?CONST_GUILD_PVP_SKILL_FIX_WALL),
    SkillRec#rec_guild_pvp_skill.cd.


boss_state_packet() ->
    CarId = guild_pvp_serv:get_car_id(),
    WallId = guild_pvp_serv:get_wall_id(),
    IsCarDead = 
        case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, CarId) of
            [] ->
                true;
            [CarRec] ->
                CarRec#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
        end,
    IsWallDead = 
        case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, WallId) of
            [] ->
                true;
            [WallRec] ->
                WallRec#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
        end,
    guild_pvp_api:msg_boss_state(IsWallDead, IsCarDead).

guild_db_add_app_guild(Guild) ->
    GuildId = Guild#guild_pvp_guild.guild_id,
    IsLeader = 
        case Guild#guild_pvp_guild.is_leader of
            true -> 1;
            _ ->0
        end,
    CampId = Guild#guild_pvp_guild.camp_id,
    Power = Guild#guild_pvp_guild.power,
    ChooseDef = 
        case Guild#guild_pvp_guild.choosed_def of
            true ->1;
            _ ->0
        end,
    mysql_api:insert(game_guild_pvp_app, [guild_id, is_leader, camp_id, power, choosed_def], [GuildId, IsLeader, CampId, Power, ChooseDef]).

guild_db_update_app_guild(Keys, WhereList) ->
    mysql_api:update(game_guild_pvp_app, Keys, WhereList).

guild_db_delete_app() ->
    mysql_api:delete("TRUNCATE game_guild_pvp_app;").

guild_db_get_app() ->
    mysql_api:select("select * from game_guild_pvp_app;").

%% 检查是否是第一次军团战，不是第一次军团战 这个排名不可能为空，至少有一个城主军团
check_is_first() ->
    ets:info(?CONST_ETS_GUILD_PVP_RANK, size) == 0.
    

get_end_time() ->
    case ets:tab2list(?CONST_ETS_GUILD_PVP_STATE) of
        [] ->
            0;
        [State] ->
            State#guild_pvp_state.off_time
    end.