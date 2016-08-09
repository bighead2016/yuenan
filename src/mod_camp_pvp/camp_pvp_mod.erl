%% Author: PXR
%% Created: 2013-7-8
%% Description: TODO: Add description to camp_mod
-module(camp_pvp_mod).

%%
%% Include files
%%

-include("../../include/const.cost.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include_lib("stdlib/include/ms_transform.hrl").


%% 
%% Exported Functions
%%
-export([do_camp_start/0,  check_camp_start/0]).


-export([mining/2,               %采矿
         get_hp_exp/1, 
         select_id_list/0,
         pvp_cash/2,
         cross_call/5,
         flush_offline/2,         
         add_meritorious/2,
         insert_db/2,
         update_battle/2,
         update_battle_data/1,
         add_meritorious_cb/2,
         submit_resource/1,
         get_active_rate/0,
         enter_camp_map/7,
         cross_tips/2,
         cross_add_title/2,
         enter_camp_map/2,
         enter_camp_map/3,
         get_top10_counter/0,
         broad/2, 
         cross_cast/5,
         broad/1,
         get_camp_pvp_map_id/0,
         broad_map/3,
         broad_map/2,
         send_meritorious_cross/2,
         add_camp_score/2,
         add_camp_score_cb/2,
         get_safe_map/1, 
         get_kill_award/5,
         get_monster_hp/1,
         get_award_per/2,
         stop_steak_kill_award/1,
         battle_over/2,
         monster_killed/1,
         get_camp_id_map_id/3,
         get_scores_by_kill_boss/0,
         get_player_work_state/1,
         broad_end/0,
         check_camp_open/0,
         reset_monster_state/1,
         reset_player_state/1,
         get_second/1,
         get_camp_name/1,
         check_camp/2,
         check_camp_monster/2,
         get_win_add_hp_param/0,
         get_monster_group_hp/1,
         get_dead_cd/0,
         send_score/1,
         pvp_battle_over_lose/3,
         pvp_battle_over_win/5,
         get_monsters_info/0,
         battle_over_lose_cb/2,
         add_pvp_copper/5,
         broad_monster_info/0,
         monster_package/3,
         get_battle_type_by_id/3,
         add_resource_copper/2,
         get_ecourage_per/1,
         get_player_name/1,
         get_player_state_info/2,
         add_score/2,
         get_and_clear_boss_hurt/1,
         add_boss_hurt/2,
         broad_monster_hp/1,
         init_and_broad_self_info/2,
         broad_state_change_to_battle/3,
         cross_cast/4,
         cross_send/2,
         get_init_buff/1]).
%%
%% API Functions
%%

send_score(Player) ->
    Info = Player#player.info,
    Score = Info#info.camp_score,
    Packet = camp_pvp_api:msg_response_score(Score),
    misc_packet:send(Player#player.user_id, Packet).

add_camp_score(UserId, Value) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            ok;
        [Cross] ->
            Node = Cross#cross_in.node,
            rpc:cast(Node, player_api, process_send, [UserId, ?MODULE, add_camp_score_cb, Value])
    end.

add_camp_score_cb(Player, Value) ->
    Info = Player#player.info,
    OldScore = Info#info.camp_score,
    NewInfo = Info#info{camp_score = OldScore + Value},
    Player1 = Player#player{info = NewInfo},
    {ok, Player1}.
    
init_and_broad_self_info(PlayerRec, MapId) ->
    UserId = PlayerRec#camp_pvp_player.user_id,
    RoomId= PlayerRec#camp_pvp_player.room_id,
    %% 拿到地图其他人的状态信息
    PlayerList = get_player_state_info(MapId, RoomId),
    PacketPlayer = camp_pvp_api:msg_player_state_list(PlayerList), 
    cross_send(UserId, PacketPlayer),
    
    %% 广播自己的状态信息
    StatePacket = camp_pvp_api:msg_player_state(UserId, PlayerRec#camp_pvp_player.state),
    broad_map(StatePacket, MapId, RoomId),
    
    %% 拿到地图其他人的血量信息
    send_player_hp_2_client(UserId, MapId, RoomId),
    case get_camp_pvp_map_id() of
        MapId ->
            %% 交战区才需要广播自己的血量，以及拿到怪物的状态和血量
            broad_self_hp(UserId, MapId),
            send_monster_hp_2_client(UserId, RoomId),
            Dict = get_monsters_info(),
            {ok, MonsterPacket} = dict:find(PlayerRec#camp_pvp_player.room_id, Dict),
            cross_send(UserId, MonsterPacket);
        _ ->
            ok
    end.

broad_state_change_to_battle(UserId1, UserId2, ?CONST_CAMP_PVP_BATTLE_TYPE_PVP) ->
    CampPlayer = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1),
    StateList = [{UserId1, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}, {UserId2, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}],
    Packet = camp_pvp_api:msg_player_state_list(StateList),
    broad_map(Packet, CampPlayer#camp_pvp_player.room_id);
broad_state_change_to_battle(UserId, _, _) ->
     CampPlayer = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId),
     Packet = camp_pvp_api:msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE),
     broad_map(Packet, CampPlayer#camp_pvp_player.room_id).

send_player_hp_2_client(UserId, MapId, RoomId) ->
    Players = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),

    PlayerList = get_map_player_hp_list(MapId, Players, RoomId),
    Packet = camp_pvp_api:msg_hp_change(PlayerList),
    camp_pvp_mod:cross_send(UserId, Packet).

send_monster_hp_2_client(UserId, RoomId) ->
    Monsters = ets:tab2list(?CONST_ETS_CAMP_PVP_MONSTER),
    MonsterList = broad_Monster_hp(Monsters, [], RoomId),
    Packet = camp_pvp_api:msg_hp_change(MonsterList),
    camp_pvp_mod:cross_send(UserId, Packet).

broad_monster_hp(MonsterId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        [] ->
            ok;
        [MonsterRec] ->
            RoomId = MonsterId div ?CONST_SYS_NUM_MILLION,
            List = broad_Monster_hp([MonsterRec], [], RoomId),
            ?MSG_DEBUG("broad monster is ~w, ~w", [MonsterRec#camp_pvp_monster.hp, MonsterRec#camp_pvp_monster.hp_max]),
            Packet = camp_pvp_api:msg_hp_change(List),
            broad_map(Packet,  RoomId)
    end.

broad_self_hp(UserId) ->
    broad_self_hp(UserId, get_camp_pvp_map_id()).
broad_self_hp(UserId, MapId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            PlayerList = get_map_player_hp_list(MapId, [PlayerRec], PlayerRec#camp_pvp_player.room_id),
            Packet = camp_pvp_api:msg_hp_change(PlayerList),
            broad_map(Packet, MapId, PlayerRec#camp_pvp_player.room_id)
    end.


broad_Monster_hp([], List, _RoomId) -> List;
broad_Monster_hp([Monster|RestList], List, RoomId) ->
    case Monster#camp_pvp_monster.state of
        ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
            broad_Monster_hp(RestList, List, RoomId);
        _ ->
            MonsterRoom = Monster#camp_pvp_monster.monster_id div ?CONST_SYS_NUM_MILLION,
            MonsterId = Monster#camp_pvp_monster.monster_id rem ?CONST_SYS_NUM_MILLION,
            case MonsterRoom == RoomId of
                false ->
                    broad_Monster_hp(RestList, List, RoomId);
                _ ->
                    HpMax = Monster#camp_pvp_monster.hp_max,
                    Hp = Monster#camp_pvp_monster.hp,
                    Entry = {1, MonsterId, Hp, HpMax, Monster#camp_pvp_monster.camp rem 10, 0, 0, 0, 0},
                    broad_Monster_hp(RestList, [Entry|List], RoomId)
            end
    end.

get_map_player_hp_list(MapId, PlayerRecList, RoomId) ->
    get_map_player_hp_list(MapId, PlayerRecList, [], RoomId).
get_map_player_hp_list(_MapId, [], List, _RoomId) -> List;
get_map_player_hp_list(MapId, [Player|RestList], List, RoomId) ->
    case Player#camp_pvp_player.exist == true andalso
                                    Player#camp_pvp_player.room_id == RoomId andalso
                                      Player#camp_pvp_player.map_id == MapId of
        true ->
            {Hp, HpMax} = Player#camp_pvp_player.hp_expression,
            Entry = {2, Player#camp_pvp_player.user_id, Hp, HpMax, 
                     Player#camp_pvp_player.camp_id rem ?CONST_SYS_NUM_MILLION, 
                     Player#camp_pvp_player.power,
                     Player#camp_pvp_player.lv,
                     Player#camp_pvp_player.kill_streak,
                     Player#camp_pvp_player.serv_id},
            get_map_player_hp_list(MapId, RestList, [Entry|List], RoomId);
        false ->
            get_map_player_hp_list(MapId, RestList, List, RoomId)
    end.
            
        
get_and_clear_boss_hurt(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            0;
        [PlayerRec] ->
             ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.hurt, 0}),
             PlayerRec#camp_pvp_player.hurt
    end.

add_boss_hurt(UserId, Hurt) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            NewHurt = PlayerRec#camp_pvp_player.hurt + Hurt,
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.hurt, NewHurt})
    end.

get_player_name(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            "";
        [PlayerRec] ->
             PlayerRec#camp_pvp_player.user_name
     end.

add_score(UserId, Score) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            CampId = PlayerRec#camp_pvp_player.camp_id,
            OldScore = PlayerRec#camp_pvp_player.scores,
            NewScore = OldScore + Score,
            ?MSG_DEBUG("oldscore is ~w, scoreadd is ~w", [OldScore, NewScore]),
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                               [{#camp_pvp_player.scores, NewScore},
                                {#camp_pvp_player.scores_update_time, misc:seconds()}]),
            camp_pvp_serv:submit_recource(CampId, 0, Score)
    end.

get_battle_type_by_id(Type, UserId1, MonsterId1) ->
    case Type of
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
            {MonsterId1, ?CONST_CAMP_PVP_BATTLE_TYPE_PVP};
        _ ->
            PlayerRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1),
            RoomId = PlayerRec#camp_pvp_player.room_id,
            MonsterId = camp_pvp_serv:get_monster_id(RoomId, MonsterId1),
            MonsterRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId),
            case MonsterRec#camp_pvp_monster.harm == 0 of
                true ->
                    {MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVB};
                false ->
                    {MonsterId, ?CONST_CAMP_PVP_BATTLE_TYPE_PVM}
            end
    end.
                
            

%% 广播怪物血量
broad_monster_info() ->
    Dict = camp_pvp_mod:get_monsters_info(),
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    broad_monster_info(PlayerList, Dict).
broad_monster_info([], _Dict) ->ok;
broad_monster_info([Player|PlayerList], Dict) ->
    PvpMap = get_camp_pvp_map_id(),
    case Player#camp_pvp_player.map_id of
        PvpMap ->
            case Player#camp_pvp_player.exist of
                true ->
                    {ok, Packet} = dict:find(Player#camp_pvp_player.room_id, Dict),
                    cross_send(Player#camp_pvp_player.user_id, Packet);
                false ->
                    ok
            end;
        _ ->
            ok
    end,
    broad_monster_info(PlayerList, Dict).



add_resource_copper(UserId, Type) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [PlayerRec] ->
            Level = PlayerRec#camp_pvp_player.lv,
            Rate = get_active_rate(),
            Copper = 
                case Type of
                    ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                         Score = ?CONST_CAMP_PVP_RESOURCE_SCORE_HIGH,
                        round(Rate * ?FUN_CAMP_PVP_HIGH_RESOURCE(Level));
                    _ ->
                        Score = ?CONST_CAMP_PVP_RESOURCE_SCORE_LOW,
                        round(Rate * ?FUN_CAMP_PVP_LOW_RESOURCE(Level))
                        
                end,
            OldCopper = PlayerRec#camp_pvp_player.silier,
            NewCopper = OldCopper + Copper,
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                               {#camp_pvp_player.silier, NewCopper}),
            cross_cast(UserId, player_money_api, plus_money, [UserId, ?CONST_SYS_GOLD_BIND, 
                                        Copper, ?CONST_COST_CAMP_PVP_COPPER]),
            PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_SUBMIT_SOURCE_SUCCESS,
                 [{?TIP_SYS_COMM, misc:to_list(Copper)}, {?TIP_SYS_COMM, misc:to_list(Score)}]),
            cross_send(UserId, PacketTips)
    end.




add_meritorious(UserId, Value) ->
    player_api:process_send(UserId, ?MODULE, add_meritorious_cb, Value).

add_meritorious_cb(Player, Value) ->
    player_api:plus_meritorious(Player, Value, ?CONST_COST_CAMP_PVP_AWARD).

%% 根据pvp战斗结果给玩家增加铜钱
add_pvp_copper(UserId, Level, IsWin, Per, ACopper) ->
    Rate = get_active_rate(),
    case IsWin of
        true ->
            Copper = round(Rate * Per * ?FUN_CAMP_PVP_WIN(Level));
        false ->
            Copper = round(Rate * Per * ?FUN_CAMP_PVP_LOST(Level))
    end,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [PlayerRec] ->
            OldCopper = PlayerRec#camp_pvp_player.silier,
            NewCopper = OldCopper + Copper + ACopper,
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                               {#camp_pvp_player.silier, NewCopper})
    end,
    cross_cast(UserId, player_money_api, plus_money, [UserId, ?CONST_SYS_GOLD_BIND, Copper + ACopper, ?CONST_COST_CAMP_PVP_AWARD]).
  
    
    
    

pvp_battle_over_lose(UserId, _HpList, Per)  ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [CampPlayerRec] ->
            Now = misc:seconds(),
            Dead_cd = camp_pvp_mod:get_dead_cd(),
            ?MSG_DEBUG("~w dead and he will revive after ~w", [UserId, Dead_cd]),
            OldKilled = CampPlayerRec#camp_pvp_player.killed_amount,
            UpdateParam = [{#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD}, 
                        {#camp_pvp_player.hp, []},
                        {#camp_pvp_player.hp_expression, {0,0}},
                        {#camp_pvp_player.state_end_time, Dead_cd + Now},
                        {#camp_pvp_player.recource_type, ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL},
                        {#camp_pvp_player.kill_streak, 0},
                        {#camp_pvp_player.killed_amount, OldKilled + 1}],
            UpdateParam1 = 
                case CampPlayerRec#camp_pvp_player.recource_type of
                    ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL ->
                        UpdateParam;
                    _ ->
                        [{#camp_pvp_player.collect_streak, 0}|UpdateParam]
                end,
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, UpdateParam1),
            add_pvp_copper(UserId, CampPlayerRec#camp_pvp_player.lv, false, Per, 0),
            StatePacket = camp_pvp_api:msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD),
            cross_send(UserId, StatePacket)
    end.


battle_over_lose_cb(Player, MapId) ->
    Player2 = map_api:enter_map(Player, MapId),
    {?ok, Player2}.
    


pvp_battle_over_win(UserId, HpList, Per, {AScore, ACopper}, Jiangyin)  ->
    ?MSG_DEBUG("~w is --winner ", [UserId]),
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [CampPlayerRec] ->
            Fun = 
                fun({{Type, Id}, MaxHp, Hp}) ->
                        NewHp = max(Hp, 1),
                        {{Type, Id}, MaxHp, NewHp}
                end,
            NewHpList = lists:map(Fun, HpList),
            Hp_exp = get_hp_exp(NewHpList, {0,0}),
            OldMaxKillStreak = CampPlayerRec#camp_pvp_player.kill_streak_max,
            OldJiangYin = CampPlayerRec#camp_pvp_player.jiangyin,
            NewKill = CampPlayerRec#camp_pvp_player.kill_amount + 1,
            NewKillStreak = CampPlayerRec#camp_pvp_player.kill_streak + 1,
            MaxKillStreak = 
                max(OldMaxKillStreak, NewKillStreak),
            ScoresOld = CampPlayerRec#camp_pvp_player.scores,
            Name = CampPlayerRec#camp_pvp_player.user_name,
            CampId = CampPlayerRec#camp_pvp_player.camp_id,
            ScoresAdd = camp_pvp_mod:get_kill_award(UserId, Name, CampId, NewKillStreak, Per),
            NewState = camp_pvp_mod:get_player_work_state(UserId),
            UpdateParam1 = [{#camp_pvp_player.hp_expression, Hp_exp},
                           {#camp_pvp_player.state, NewState},
                           {#camp_pvp_player.kill_streak_max, MaxKillStreak},
                            {#camp_pvp_player.hp, NewHpList},
                            {#camp_pvp_player.kill_streak, NewKillStreak},
                            {#camp_pvp_player.scores, ScoresOld + ScoresAdd + AScore},
                            {#camp_pvp_player.scores_update_time, misc:seconds()},
                            {#camp_pvp_player.jiangyin, Jiangyin + OldJiangYin},
                            {#camp_pvp_player.kill_amount, NewKill}],
            add_camp_score(UserId, Jiangyin),
            UpdateParam = 
                case MaxKillStreak > OldMaxKillStreak of
                    true ->
                        [{#camp_pvp_player.kill_streak_max_time, misc:seconds()}|UpdateParam1];
                    false ->
                        UpdateParam1
                end,
            camp_pvp_serv:submit_recource(CampId, 0, ScoresAdd + AScore),
            add_pvp_copper(UserId, CampPlayerRec#camp_pvp_player.lv, true, Per, ACopper),
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, UpdateParam),
            broad_self_hp(UserId),
            StatePacket = camp_pvp_api:msg_player_state(UserId, NewState),
            NowCash = CampPlayerRec#camp_pvp_player.battle_cash_count,
            case NowCash >=2 of
                true ->
                    ok;
                _ ->
                    Rand = misc:rand(1, 100),
                    case Rand >= 90 of
                        true ->
                            RandCash = misc:rand(5, 15),
                            PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_PVP_WIN_CASH, 
                                [{UserId,Name}],[],
                                [{?TIP_SYS_COMM, misc:to_list(RandCash)}]),
                           ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER,
                                               UserId, 
                                              {#camp_pvp_player.battle_cash_count, NowCash + 1}),
                           broad(PacketTips, CampPlayerRec#camp_pvp_player.room_id),
                            cross_cast(UserId, ?MODULE, pvp_cash, [UserId, RandCash]);
                        _ ->
                            ok
                    end
            end,
            broad_map(StatePacket, CampPlayerRec#camp_pvp_player.room_id)
    end.

pvp_cash(UserId, Cash) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, Cash, ?CONST_COST_CAMP_PVP_AWARD).

get_hp_exp(HpList) ->
    get_hp_exp(HpList, {0,0}).
get_hp_exp([], HpExp) -> HpExp;
get_hp_exp([HpTuple|RestList], {HpNow,HpMax}) ->
    {_, Max, Now} = HpTuple,
    NewHpExp = {HpNow + Now, HpMax + Max},
     get_hp_exp(RestList, NewHpExp).

monster_package(MonsterId, WalkPoint, MonsterY) ->
    Monster = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId),
    MonsterConfigId = MonsterId rem ?CONST_SYS_NUM_MILLION,
    MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterConfigId),
    Speed = MonsterConfig#rec_camp_pvp_monster.speed,
    Hp = Monster#camp_pvp_monster.hp,
    HpMax = Monster#camp_pvp_monster.hp_max,
    CampId = MonsterConfig#rec_camp_pvp_monster.camp rem 10,
    IsBattle = false,
    [MonsterX|WalkPoint1] = WalkPoint,
    [TargetX|_WalkPoint2] = WalkPoint1,
    MonsterInfo = [{MonsterConfigId,MonsterX,MonsterY,TargetX,MonsterY,Speed,IsBattle,CampId, Hp, HpMax}],
    {WalkPoint1, camp_pvp_api:msg_sc_monster_info(MonsterInfo)}.

get_player_state_info(MapId, RoomId) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    get_player_state_info(MapId, PlayerList, [], RoomId).
get_player_state_info(_MapId, [], InfoList, _RoomId) ->InfoList;
get_player_state_info(MapId, [PlayerInfo|RestPlayerList], InfoList, RoomId) ->
    case PlayerInfo#camp_pvp_player.map_id == MapId andalso 
          PlayerInfo#camp_pvp_player.room_id == RoomId andalso
          PlayerInfo#camp_pvp_player.exist == true of
         true ->
            Info = {PlayerInfo#camp_pvp_player.user_id, PlayerInfo#camp_pvp_player.state},
            get_player_state_info(MapId, RestPlayerList, [Info|InfoList], RoomId);
        _ ->
            get_player_state_info(MapId, RestPlayerList, InfoList, RoomId)
    end.
    

get_monsters_info() ->
    Dict = dict:new(),
    MonsterList = ets:tab2list(?CONST_ETS_CAMP_PVP_MONSTER),
    Dict2 = get_monster_info(MonsterList, Dict),
    Fun = 
        fun(_Key, MonsterList) ->
            camp_pvp_api:msg_sc_monster_info(MonsterList)
        end,
    dict:map(Fun, Dict2).
    

get_monster_info([], Dict) ->
    Dict;
get_monster_info([Monster|RestMonsterList], Dict) ->
    case Monster#camp_pvp_monster.state of
        ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
            case Monster#camp_pvp_monster.harm == 0 of
                false -> %%  冲锋怪死了就不发了
                    Hp = -1;
                true -> %% 定点炮台血设为0
                     Hp = 0
            end;
        _ ->
            Hp = Monster#camp_pvp_monster.hp
    end,
    if 
        Hp < 0 ->
             get_monster_info(RestMonsterList, Dict);
        true ->
            
            MonsterId2 = Monster#camp_pvp_monster.monster_id,
            RoomId = MonsterId2 div ?CONST_SYS_NUM_MILLION,
            MonsterId = MonsterId2 rem ?CONST_SYS_NUM_MILLION,
            MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId),
            TargetPoint = MonsterConfig#rec_camp_pvp_monster.target_point,
            {TargetX, TargetY} = TargetPoint,
            
            HpMax = Monster#camp_pvp_monster.hp_max,
            CampId = MonsterConfig#rec_camp_pvp_monster.camp rem 4,
            Speed = MonsterConfig#rec_camp_pvp_monster.speed,
            IsBattle = Monster#camp_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_BATTLE,
            case Monster#camp_pvp_monster.harm == 0 of
                true ->
                    MonsterInfo = {MonsterId,TargetX,TargetY,TargetX,TargetY,Speed,IsBattle,CampId, Hp, HpMax},
                            Dict1 = dict:append(RoomId, MonsterInfo, Dict),
                    get_monster_info(RestMonsterList, Dict1);
                false ->
                    case Monster#camp_pvp_monster.walkPoint of
                        [] ->
                            get_monster_info(RestMonsterList, Dict);
                        Path ->
                            [NowX|_] = Path,
                            MonsterInfo = {MonsterId,NowX,TargetY,NowX,TargetY,Speed,IsBattle,CampId, Hp, HpMax},
                            case dict:is_key(RoomId, Dict) of
                                false ->
                                    Dict1 = dict:store(RoomId, MonsterInfo, Dict);
                                _ ->
                                    Dict1 = dict:append(RoomId, MonsterInfo, Dict)
                            end,
                             get_monster_info(RestMonsterList, Dict1)
                    end
            end
    end.


%% 获取怪物组生命总和
get_monster_group_hp(MonsterId) ->
    case monster_api:monster(MonsterId) of
        Monster when is_record(Monster, monster) ->
            Camp        = Monster#monster.camp,
            HpTupleTemp = erlang:make_tuple(tuple_size(Camp#camp.position), 0, []),
            HpTuple     = get_monster_group_hp(misc:to_list(Camp#camp.position), HpTupleTemp),
            HpMax       = lists:sum(misc:to_list(HpTuple)),
            {?ok, HpMax, HpTuple};
        ?null -> {?error, ?TIP_COMMON_NO_THIS_MON}
    end.

get_monster_group_hp([#camp_pos{idx = Idx, type = ?CONST_SYS_MONSTER, id = MonsterId}|Position], HpTuple) ->
    case monster_api:monster(MonsterId) of
        Monster when is_record(Monster, monster) ->
            HpTuple2    = setelement(Idx, HpTuple, Monster#monster.hp),
            get_monster_group_hp(Position, HpTuple2);
        _ -> {?error, ?TIP_COMMON_NO_THIS_MON}
    end;
get_monster_group_hp([_|Position], HpTuple) ->
    get_monster_group_hp(Position, HpTuple);
get_monster_group_hp([], HpTuple) -> HpTuple.


get_second({H, I, S}) ->
    {Y, M, D} = date(),
    misc:date_time_to_stamp({Y, M, D, H, I, S}).

monster_killed(MonsterId) ->
    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
    Packet = camp_pvp_msg:msg_monster_killed(MonsterId),
    broad(Packet, MonsterId div ?CONST_SYS_NUM_MILLION).

broad(Packet, RoomId) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    Fun =
        fun(Player) ->
                case Player#camp_pvp_player.exist of
                    true ->
                        case Player#camp_pvp_player.room_id of
                            RoomId ->
                                UserId = Player#camp_pvp_player.user_id,
                                cross_send(UserId, Packet);
                            _ ->
                                ok
                        end;
                    false ->
                        ok
                end
        end,
    lists:foreach(Fun, PlayerList).

broad(Packet) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    Fun =
        fun(Player) ->
                case Player#camp_pvp_player.exist of
                    true ->
                        cross_send(Player#camp_pvp_player.user_id, Packet);
                    false ->
                        ok
                end
        end,
    lists:foreach(Fun, PlayerList).



cross_send(UserId, Packet) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            misc_packet:send(UserId, Packet);
        [#cross_in{node = Node}] ->
            rpc:cast(Node, misc_packet, send, [UserId, Packet])
    end.

cross_tips(UserId, Tips) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            misc_packet:send_tips(UserId, Tips);
        [#cross_in{node = Node}] ->
            rpc:cast(Node, misc_packet, send_tips, [UserId, Tips])
    end.

broad_map(Packet, MapId, RoomId) ->
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    Fun =
        fun(Player) ->
                case Player#camp_pvp_player.exist of
                    true ->
                        case Player#camp_pvp_player.map_id of
                            MapId ->
                                case Player#camp_pvp_player.room_id of
                                    RoomId ->
                                        UserId = Player#camp_pvp_player.user_id,
                                        cross_send(UserId, Packet);
                                    _ ->
                                        ok
                                end;
                            _ ->
                                ok
                        end;
                    _ ->
                        ok
                end
        end,
    lists:foreach(Fun, PlayerList).

broad_map(Packet, RoomId) ->
    broad_map(Packet, get_camp_pvp_map_id(), RoomId).

cross_cast(UserId, Module, Function, Args) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            ok;
        [Rec] ->
            Node = Rec#cross_in.node,
            rpc:cast(Node, Module, Function, Args)
    end.

cross_cast(UserId, Lv, Module, Function, Args) ->
    {Master, _Room} = cross_api:get_camp_master(UserId, Lv),
    rpc:cast(Master, Module, Function, Args).

cross_call(UserId, Lv, Module, Function ,Args) ->
    case  cross_api:get_camp_master(UserId, Lv) of
        {Master, _Room} when Master =/= 0 ->
            rpc:call(Master, Module, Function, Args);
        _ ->
            ok
    end.

get_buff_list(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
        [] ->
            [];
        [TeamIndex] ->
            LeaderId = TeamIndex#camp_team_index.leader_id,
            case ets:lookup(?CONST_ETS_CAMP_TEAM_LIST, LeaderId) of
                [] ->
                    [];
                [Team] ->
                    MemList = Team#camp_team_list.id_list,
                    get_buff_list(MemList, UserId, [])
            end
    end.

get_buff_list([], _UserId, BuffList) ->
    BuffList;
get_buff_list([#camp_team_member{user_id = UserId}|Rest], UserId, BuffList) ->
    get_buff_list(Rest, UserId, BuffList);
get_buff_list([Member|Rest], UserId, BuffList) ->
    Type = Member#camp_team_member.attr_type,
    Value = Member#camp_team_member.attr_value,
    get_buff_list(Rest, UserId, [{Type, Value}|BuffList]).

merge_buff([{Type, Value1}, {Type, Value2}]) ->
    [{Type,Value1 + Value2}];
merge_buff(BuffList) ->
    BuffList.

get_camp_player(Player, Room) ->
    Guild = Player#player.guild,
    GuildName = Guild#guild.guild_name,
    Info = Player#player.info,
    Pro = Info#info.pro,
    BuffList = get_buff_list(Player#player.user_id),
    BuffPacket = group_api:msg_sc_buffer(Player#player.user_id, merge_buff(BuffList)),
    misc_packet:send(Player#player.user_id, BuffPacket),
    ?MSG_DEBUG("GuildName is ~w", [GuildName]),
    #camp_pvp_player{
                     guild_name = GuildName,
                     pro = Pro,
                     buff_list = BuffList,
                     room_id = Room,
                     power = partner_api:caculate_camp_power(Player),
                     user_name = player_api:get_name(Player#player.user_id),
                     lv = player_api:get_level(Player#player.user_id),
                     exist = ?true,
                     user_id = Player#player.user_id,
                     state = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL
                     }.

enter_camp_map(_Node, MemList, _Room) when is_list(MemList) ->
    Fun =
        fun(UserId) ->
            Pid = player_api:get_player_pid(UserId), 
            player_api:process_send(Pid, camp_pvp_api, camp_info_4_client, [])
        end,
    lists:foreach(Fun, MemList).



get_camp_id(UserId) ->
    Rec = ets_api:lookup(?CONST_ETS_CROSS_OUT, UserId),
    Rec#cross_out.camp_id.

update_battle_data(UserId) ->
    case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
        [] ->
            ok;
        [#cross_out{node = Node}] ->
            timer:apply_after(1500, ?MODULE,update_battle, [UserId, Node])
    end.

update_battle(UserId, Node) ->
    {ok, Data} = battle_cross_api:record_battle(?CONST_BATTLE_CAMP_PVP, UserId, 1),
    rpc:cast(Node, ets, update_element, [?CONST_ETS_CROSS_IN, UserId, {#cross_in.player_data, Data}]).

enter_camp_map(Player, Room) when is_tuple(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    case check_camp_open() of
        true ->
             case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAYER_CAMP_PVP) of
                 {?true, Player2} ->
                     CampPlayer = get_camp_player(Player, Room),
                     {ok, Data} = battle_cross_api:record_battle(?CONST_BATTLE_CAMP_PVP, UserId, 1),
                     Node = node(),
                     Serv_indx = cross_api:get_self_index(),
                     CampId1 = get_camp_id(UserId),
                     case cross_call(UserId, Lv, ?MODULE, enter_camp_map, [Player#player.user_id, Room, CampPlayer, Data, Node, Serv_indx, CampId1]) of
                         {CampId, MapId} when CampId =/= 0 orelse MapId =/= 0 ->  
                             NewPlayer = map_api:enter_map(Player2, MapId),
                             Packet = camp_pvp_api:msg_sc_enter(CampId rem ?CONST_SYS_NUM_MILLION),
                             admin_log_api:log_campaign(Player#player.user_id, Player#player.account, (Player#player.info)#info.lv, ?CONST_ACTIVE_CAMP_PVP, misc:seconds()),
                             misc_packet:send(Player#player.user_id, Packet);
						 {badrpc, _Reason} ->
							 NewPlayer	= Player,
							 player_state_api:try_set_state_play(Player,  ?CONST_PLAYER_STATE_NORMAL);
                         _ ->
                             NewPlayer = Player,
                             player_state_api:try_set_state_play(Player,  ?CONST_PLAYER_STATE_NORMAL)
                     end;
                {?false, Player2, Tips} ->
                    NewPlayer = Player2,
                    Packet   = message_api:msg_notice(Tips),
                    misc_packet:send(Player#player.user_id, Packet)
             end;
        _ ->
            NewPlayer = Player,
            ?MSG_DEBUG("camp pvp not start, ~w wait enter", [Player#player.user_id]),
            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_NOT_START)
    end,
    {ok, NewPlayer}.

add_camp(CampId, Power) ->
    CampRecord = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId),
    CampCount = CampRecord#camp_pvp_camp.count,
    CampSteak = CampRecord#camp_pvp_camp.streak_count,
    OldCombat = CampRecord#camp_pvp_camp.combat,
    ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, CampId, 
                       [{#camp_pvp_camp.count, CampCount + 1},
                        {#camp_pvp_camp.streak_count, CampSteak + 1},
                        {#camp_pvp_camp.combat, OldCombat + Power}]),
    OffSetCampId = camp_pvp_serv:get_offset_camp(CampId),
    ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, OffSetCampId, {#camp_pvp_camp.streak_count, 0}).

enter_camp_map(UserId, Room, CampPlayer, Data, Node, Serv_indx, CampId1) ->
    ets:insert(?CONST_ETS_CROSS_IN, #cross_in{node = Node, player_data = Data, user_id = UserId, serv_index = Serv_indx}),
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            case camp_pvp_serv:get_camp_id_map_id(UserId, Room, CampId1) of
                {CampId, MapId} ->
                    NewPlayer = CampPlayer#camp_pvp_player{camp_id = CampId, room_id = Room, serv_id = Serv_indx},
                    ets:insert(?CONST_ETS_CAMP_PVP_PLAYER, NewPlayer),
                    ets:insert(?CONST_ETS_CAMP_PVP_PK_CD, #camp_pvp_pk_cd{user_id = UserId}),
                    AddPer = camp_pvp_mod:get_ecourage_per(0),
                    EnPacket = camp_pvp_api:msg_ecourage_success(AddPer),
                    cross_send(UserId, EnPacket),
                    {CampId, MapId};
                _ ->
                    cross_send(UserId, ?TIP_CAMP_PVP_FULL)
            end;
        [PlayerRec] ->
            case get_enter_cd(PlayerRec) of
                0 ->
                    CampId = PlayerRec#camp_pvp_player.camp_id,
                    MapId = get_safe_map(CampId),
                    camp_pvp_serv:add_camp(CampId, PlayerRec#camp_pvp_player.power),
                    check_and_set_state(PlayerRec, UserId),
                    {CampId, MapId};
                S ->
                    Packet  = message_api:msg_notice(?TIP_CAMP_PVP_ENTER_CD,
                                                 [{?TIP_SYS_COMM, misc:to_list(S)}]),
                    cross_send(UserId, Packet)
             end
    end.

get_enter_cd(PlayerRec) ->
    EndTime = PlayerRec#camp_pvp_player.enter_cd,
    Now = misc:seconds(),
    max(EndTime - Now, 0).

check_and_set_state(PlayerRec, UserId) ->
    ?MSG_DEBUG("player ~w's state is ~w", [UserId, PlayerRec#camp_pvp_player.state]),
    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId,
        [{#camp_pvp_player.exist , ?true}, 
         {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]).

reset_monster_state(UserId) ->
    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, UserId,
                        [{#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL}]).

reset_player_state(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            case PlayerRec#camp_pvp_player.recource_type of
                ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL ->
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId,
                          {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL});
                ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                          {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH});
                _ ->
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                          {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW})
            end
    end.
            

check_camp(UserId1, UserId2) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1) of
        [] ->
            ?MSG_DEBUG("user ~w not in camp pvp", [UserId1]),
            ?false;
        [User1Rec] ->
            case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId2) of
                [] -> 
                    ?MSG_DEBUG("user ~w not in camp pvp", [UserId2]),
                    ?false;
                [User2Rec] ->
                    ?MSG_DEBUG("user ~w's camp is ~w, user ~w's camp is ~w",
                                [UserId1, User1Rec#camp_pvp_player.camp_id,
                                 UserId2, User2Rec#camp_pvp_player.camp_id]),
                    User1Rec#camp_pvp_player.camp_id /= User2Rec#camp_pvp_player.camp_id
            end
    end.

check_camp_monster(UserId1, MonsterId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1) of
        [] ->
            ?MSG_DEBUG("user ~w not in camp pvp", [UserId1]),
            ?false;
        [User1Rec] ->
            case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
                [] -> 
                    ?MSG_DEBUG("user ~w not in camp pvp", [MonsterId]),
                    ?false;
                [MonsterRec] ->
                    User1Rec#camp_pvp_player.camp_id /= MonsterRec#camp_pvp_monster.camp
            end
    end.

do_moning(UseId, RoomId, CampConfig, Type) ->
    WorkingEndTime = misc:seconds() + CampConfig#rec_camp_pvp_resource.time,
    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UseId, 
                       [{#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_WORKING},
                        {#camp_pvp_player.state_end_time, WorkingEndTime},
                        {#camp_pvp_player.recource_type, Type}]),
    StatePacket = camp_pvp_api:msg_player_state(UseId, ?CONST_CAMP_PVP_PLAYER_STATE_WORKING),
    broad_map(StatePacket, RoomId),
    Packet = camp_pvp_api:msg_sc_dig_success(CampConfig#rec_camp_pvp_resource.time,
                                             CampConfig#rec_camp_pvp_resource.speed),
    cross_send(UseId, Packet).




mining(UseId, Type) when is_integer(UseId)->
    CampPlayer = get_camp_play(UseId),
    CampConfig = data_camp_pvp:get_camp_pvp_recource(Type),
    case CampPlayer#camp_pvp_player.state of
        ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL ->
            do_moning(UseId, CampPlayer#camp_pvp_player.room_id, CampConfig, Type);
        ?CONST_CAMP_PVP_PLAYER_STATE_DEAD ->
            ?MSG_DEBUG("player ~w state is ~w", [UseId, CampPlayer#camp_pvp_player.state]),
            case CampPlayer#camp_pvp_player.state_end_time =< misc:seconds() of
                true ->
                    do_moning(UseId, CampPlayer#camp_pvp_player.room_id, CampConfig, Type);
                _ ->
                    cross_tips(UseId, ?TIP_CAMP_PVP_NOT_IN_WORKING_STATE)
            end;
        _ ->
            ?MSG_DEBUG("player ~w state is ~w", [UseId, CampPlayer#camp_pvp_player.state]),
            cross_tips(UseId, ?TIP_CAMP_PVP_NOT_IN_WORKING_STATE)
    end;

mining(Player, Type)  ->
    UseId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    cross_cast(UseId, Lv, ?MODULE, mining, [UseId, Type]).
        
submit_resource(UseId) ->
    ?MSG_DEBUG("player ~w submit resource", [UseId]),
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UseId) of
        [] ->ok;
        [CampPlayer] ->
            ?MSG_DEBUG("player ~w submit resource", [CampPlayer]),
            case CampPlayer#camp_pvp_player.state  == ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH orelse  
                 CampPlayer#camp_pvp_player.state  == ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW of
                true ->
                    RecourceType = CampPlayer#camp_pvp_player.recource_type,
                    StatePacket = camp_pvp_api:msg_player_state(UseId, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL),
                    broad_map(StatePacket, CampPlayer#camp_pvp_player.room_id),
                    case RecourceType of
                        0 ->
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UseId, 
                                    {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL});
                        _ ->
                            add_resource_copper(UseId, RecourceType),
                            RecourceConfig = data_camp_pvp:get_camp_pvp_recource(RecourceType),
                            RecourceAdd = RecourceConfig#rec_camp_pvp_resource.lv,
                            CollectSteak = CampPlayer#camp_pvp_player.collect_streak + 1,
                            CampId = CampPlayer#camp_pvp_player.camp_id,
                            Name = CampPlayer#camp_pvp_player.user_name,
                            ScoreDiff = ?CONST_CAMP_PVP_RESOURCE_SCORE_HIGH - ?CONST_CAMP_PVP_RESOURCE_SCORE_LOW,
                            ScoreAdd = 
                                case RecourceType of
                                    ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                                        get_collect_award(UseId, Name, CampId, CollectSteak) + ScoreDiff;
                                    _ ->
                                        get_collect_award(UseId, Name, CampId, CollectSteak)
                                end,
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UseId, [
                                    {#camp_pvp_player.collect_streak, CollectSteak},
                                    {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL},
                                    {#camp_pvp_player.recource_type, 0},
                                    {#camp_pvp_player.scores_update_time, misc:seconds()},
                                    {#camp_pvp_player.scores, CampPlayer#camp_pvp_player.scores + ScoreAdd}]),
                            camp_pvp_serv:submit_recource(CampId, RecourceAdd, ScoreAdd),
                            NowCash = CampPlayer#camp_pvp_player.battle_cash_count,
                            case NowCash >=2 of
                                true ->
                                    ok;
                                _ ->
                                    Rand = misc:rand(1, 100),
                                    case Rand >= 95 of
                                        true ->
                                             RandCash = misc:rand(5, 20),
                                            PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_RESOURCE_CASH, 
                                                [{UseId,Name}],[],
                                                [{?TIP_SYS_COMM, misc:to_list(RandCash)}]),
                                          ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER,
                                                               UseId, 
                                                              {#camp_pvp_player.battle_cash_count, NowCash + 1}),
                                           broad(PacketTips, CampPlayer#camp_pvp_player.room_id),
                                            cross_cast(UseId, ?MODULE, pvp_cash, [UseId, RandCash]);
                                        _ ->
                                            ok
                                    end
                            end
                    end;
                false ->
                    ?MSG_DEBUG("submit rescource failed", [])
            end
    end.

do_camp_start() ->
    init_camp_pvp().

check_camp_open() ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
        [] ->
            false;
        [Camp_data] ->
            Camp_data#camp_pvp_data.state == ?CONST_CAMP_PVP_OPEN orelse 
                                        Camp_data#camp_pvp_data.state == ?CONST_CAMP_PVP_START
     end.

update_pk_cd(WinId, LoseId) ->
    CDEnd = misc:seconds() + ?CONST_CAMP_PVP_PK_CD_SECOND,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PK_CD, WinId) of
        [] ->
            ok;
        [CdRec] ->
            CdDict = CdRec#camp_pvp_pk_cd.cd_dict,
            NewCdRec = dict:store(LoseId, CDEnd, CdDict),
            ?MSG_DEBUG("udpate ~w and ~w pk cd", [WinId, LoseId]),
            ets:update_element(?CONST_ETS_CAMP_PVP_PK_CD, WinId, {#camp_pvp_pk_cd.cd_dict, NewCdRec})
    end.

get_award_per(Player1Rec, Player2Rec) ->
    Level_dif = Player1Rec#camp_pvp_player.lv - Player2Rec#camp_pvp_player.lv,
    {Per, Jiangyin} = 
        if
            abs(Level_dif) > 20 -> {0.1, 0};
            abs(Level_dif) > 10 -> {0.5, 0};
            abs(Level_dif) > 5 -> {1, 1};
            true -> {1, 2}
        end,
    case Level_dif > 0 of
        true ->
            {Per, 1, Jiangyin};
        false ->
            {1, Per, -Jiangyin}
    end.

stop_steak_kill_award(UserRec) ->
    Rate = get_active_rate(),
    SteakKill = UserRec#camp_pvp_player.kill_streak,
    SteakKill1 =
        case SteakKill >= 5 andalso SteakKill < 10 of
            true -> 5;
            _ ->
                (SteakKill div 10) * 10
        end,
    case data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_BREAK_WIN, SteakKill1}) of
        null ->
            {0, 0};
        Award ->
            {Award#rec_camp_pvp_award.score, round(Rate * Award#rec_camp_pvp_award.siler)}
    end.

battle_over(Result, Param) ->
    Now = misc:seconds(),
    #param{ 
            ad1 = Hp1, 
            ad2 = Hp2, 
            ad3 = Type,
            ad4 = {UserId1, UserId2}} = Param,
    ?MSG_DEBUG("Hp1 is ~w, Hp2 is ~w", [Hp1, Hp2]),
    Fun = 
        fun({{Type, Id}, MaxHp, Hp}) ->
                NewHp = max(Hp, 1),
                {{Type, Id}, MaxHp, NewHp}
        end,
    NewHp1 = lists:map(Fun, Hp1),
    Player1Rec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1),
    case Type of
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVP -> 
            Player2Rec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId2),
            {Per1, Per2, Jiangyin} = get_award_per(Player1Rec, Player2Rec),
            ?MSG_DEBUG("receive battle info ~w", [{UserId1, UserId2}]),
            update_pk_cd(UserId1, UserId2),
            update_pk_cd(UserId2, UserId1),
            case Result of
                ?CONST_BATTLE_RESULT_LEFT ->
                    Jiangyin1 = 
                        case Jiangyin > 0 of
                            true ->
                                Jiangyin;
                            false ->
                                2
                        end,
                    SSKA = stop_steak_kill_award(Player2Rec), 
                    ?MSG_ERROR("SSKA11111111111111111111 is ~w", [SSKA]),
                    camp_pvp_mod:pvp_battle_over_win(UserId1, Hp1, Per1, SSKA, 0),
                    camp_pvp_mod:pvp_battle_over_lose(UserId2, Hp2, Per2);
                _ ->
                    Jiangyin1 = 
                        case Jiangyin > 0 of
                            true ->
                                2;
                            false ->
                                -Jiangyin
                        end,
                    SSKA = stop_steak_kill_award(Player1Rec), 
                    camp_pvp_mod:pvp_battle_over_lose(UserId1, Hp1, Per1),
                    camp_pvp_mod:pvp_battle_over_win(UserId2, Hp2, Per2, SSKA, 0)
            end;
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVM ->
            NewHp = camp_pvp_mod:get_monster_hp(Hp2),
            WorkState = camp_pvp_mod:get_player_work_state(UserId1),
            case Result of
                ?CONST_BATTLE_RESULT_LEFT ->
                    camp_pvp_monster:monster_killed(UserId2),
                    UserName1 = camp_pvp_mod:get_player_name(UserId1),
                    PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_KILL_MONSTER, [{UserId1,UserName1}],[],[]),
                    camp_pvp_mod:broad(PacketTips, Player1Rec#camp_pvp_player.room_id),
                    HpExp = camp_pvp_mod:get_hp_exp(Hp1),
                    UpdateParamUser =
                         [
                          {#camp_pvp_player.hp_expression, HpExp},
                          {#camp_pvp_player.state, WorkState},
                         {#camp_pvp_player.hp, NewHp1}],
                    StatePacket = camp_pvp_api:msg_player_state(UserId1, WorkState),
                    broad_map(StatePacket, Player1Rec#camp_pvp_player.room_id),
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, UpdateParamUser),
                    broad_self_hp(UserId1);
                ?CONST_BATTLE_RESULT_RIGHT ->
                    camp_pvp_monster:battle_over(UserId2, Hp2, NewHp),
                    Dead_cd = camp_pvp_mod:get_dead_cd(),
                    UpdateParamUser1 = 
                        [{#camp_pvp_player.hp_expression, {0, 0}},
                         {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD},
                         {#camp_pvp_player.recource_type, ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL},
                         {#camp_pvp_player.state_end_time, Dead_cd + Now},
                         {#camp_pvp_player.hp, []}],
                    UpdateParamUser = 
                        case Player1Rec#camp_pvp_player.recource_type of
                            ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL ->
                                UpdateParamUser1;
                            _ ->
                                [{#camp_pvp_player.collect_streak, 0}|UpdateParamUser1]
                        end,
                    StatePacket = camp_pvp_api:msg_player_state(UserId1, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD),
                    camp_pvp_mod:broad(StatePacket, Player1Rec#camp_pvp_player.room_id),
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, UpdateParamUser)
            end;
            
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
            WorkState = camp_pvp_mod:get_player_work_state(UserId1),
            HpExp = camp_pvp_mod:get_hp_exp(Hp1),
            case Result of
                ?CONST_BATTLE_RESULT_LEFT ->
                    UpdateParam =
                        [
                         {#camp_pvp_player.hp_expression, HpExp},
                         {#camp_pvp_player.state, WorkState},
                         {#camp_pvp_player.hp, NewHp1}],
                    StatePacket = camp_pvp_api:msg_player_state(UserId1, WorkState),
                    broad_map(StatePacket, Player1Rec#camp_pvp_player.room_id),
                    camp_pvp_api:broad_rank(5),
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, UpdateParam),
                    broad_self_hp(UserId1);
                ?CONST_BATTLE_RESULT_RIGHT ->
                    camp_pvp_mod:broad_monster_hp(UserId2),
                    camp_pvp_serv:hurt_boss(UserId2, Hp2),
                     Dead_cd = camp_pvp_mod:get_dead_cd(),
                    UpdateParam1 =
                        [
                         {#camp_pvp_player.hp_expression, {0, 0}},
                         {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD},
                         {#camp_pvp_player.recource_type, ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL},
                         {#camp_pvp_player.state_end_time, Dead_cd + Now},
                         {#camp_pvp_player.hp, []}],
                    UpdateParam = 
                        case Player1Rec#camp_pvp_player.recource_type of
                            ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL ->
                                UpdateParam1;
                            _ ->
                                [{#camp_pvp_player.collect_streak, 0}|UpdateParam1]
                        end,
                    StatePacket = camp_pvp_api:msg_player_state(UserId1, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD),
                    camp_pvp_mod:broad(StatePacket, Player1Rec#camp_pvp_player.room_id),
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, UpdateParam)
            end
    end.
           

check_camp_start() ->
    Camp_data = ets_api:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data),
    Camp_data#camp_pvp_data.state == ?CONST_CAMP_PVP_START.

broad_end() ->
    OldAchieveList = select_id_list(),
    mysql_api:execute_sql("TRUNCATE game_camp_data;"),
    DeleteFun = 
        fun([Id]) ->
                achievement_api:add_achievement(Id, ?CONST_ACHIEVEMENT_PVP_CAMP_RANK, 999, 1)
        end,
    lists:foreach(DeleteFun, OldAchieveList),
    PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
    Fun =
        fun(Room) ->
            RoomId = Room#camp_room.room_id,
            Camp1 = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, camp_pvp_serv:get_monster_id(RoomId, ?CONST_CAMP_PVP_CAMP_1)),
            Camp2 = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, camp_pvp_serv:get_monster_id(RoomId, ?CONST_CAMP_PVP_CAMP_2)),
            if 
                Camp1#camp_pvp_camp.scores > Camp2#camp_pvp_camp.scores ->
                    WinCamp = ?CONST_CAMP_PVP_CAMP_1;
                Camp1#camp_pvp_camp.scores < Camp2#camp_pvp_camp.scores ->
                    WinCamp = ?CONST_CAMP_PVP_CAMP_2;
                true ->
                    WinCamp = all
            end,
        
            FilterFun = 
                fun(Player) ->
                        Player#camp_pvp_player.room_id == RoomId
                end,
            RoomList = lists:filter(FilterFun, PlayerList),
            SortFun = 
                fun(#camp_pvp_player{scores = Score1}, #camp_pvp_player{scores = Score2}) ->
                        Score1 >= Score2
                end,
            SortedList = lists:sort(SortFun, RoomList),
            Top5 = lists:sublist(SortedList, 3),
            FormatFun = 
                fun(#camp_pvp_player{user_name = Name, camp_id = CampId, lv = Level, guild_name = GuildName, pro = Career}) ->
                        {Name, CampId rem ?CONST_SYS_NUM_MILLION, Level,Career, GuildName}
                end,
            FormatTop = lists:map(FormatFun, Top5),
            broad_end(SortedList, 1, WinCamp, FormatTop)
        end,
    lists:foreach(Fun, ets:tab2list(?CONST_ETS_CAMP_PVP_ROOM)).
    


select_id_list() ->
    case mysql_api:select_execute(<<"select `userid` from `game_camp_data`; ">>) of
        {ok, Data} ->
            Data;
        _ ->
            []
    end.

insert_db(UserId, Nth) ->
    mysql_api:insert(game_camp_data, [userid, nth], [UserId, Nth]).

cross_add_title(UserId, Nth) ->
    camp_pvp_serv:cross_add_title(UserId, Nth).

broad_end([], _Nth, _WinCamp, _Top5) ->
    ok;
broad_end([Player|PlayerList], Nth, WinCamp, Top5) ->
    Rate = get_active_rate(),
    IsTop5 = Nth =< 5,
    case Nth =< 3 of
        true ->
            cross_cast(Player#camp_pvp_player.user_id, ?MODULE, cross_add_title, [Player#camp_pvp_player.user_id, Nth]);
        _ ->
            ok
    end,
    RankJingYinList = [100, 50, 30, 20, 10],
    JiangYinRank = 
        case Nth =< 5 of
            true ->
                lists:nth(Nth, RankJingYinList);
            _ ->
                0
        end,
    Scores = Player#camp_pvp_player.scores,
    CampId = Player#camp_pvp_player.camp_id rem ?CONST_SYS_NUM_MILLION,
    Level = Player#camp_pvp_player.lv,
    GuildName = Player#camp_pvp_player.guild_name,
    Career = Player#camp_pvp_player.pro,
    IsCampSuccess = 
        case  WinCamp of
            all ->
                true;
            CampId ->
                true;
            _ ->
                false
        end,
    {_CampSilier, CampExploit, JiangyinWin} = 
        case IsCampSuccess of
            true ->
                CampAward = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_CAMP_WIN, 1}),
                {round(Rate * CampAward#rec_camp_pvp_award.siler), round(Rate * CampAward#rec_camp_pvp_award.exp), 10};
            false ->
                CampAward = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_CAMP_WIN, 0}),
                {round(Rate * CampAward#rec_camp_pvp_award.siler), round(Rate * CampAward#rec_camp_pvp_award.exp), 5}
        end,
    
    {_RankSilier,ExpRank} = 
        case data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_RANK, Nth}) of
            null ->
                {0,0};
            RankAward ->
                {round(Rate * RankAward#rec_camp_pvp_award.siler), round(Rate*RankAward#rec_camp_pvp_award.exp)}
        end,
    UserId = Player#camp_pvp_player.user_id,
    cross_cast(UserId, ?MODULE, send_meritorious_cross, [UserId, ExpRank + CampExploit]),
    {Gold,_AddExploit} = 
        {Player#camp_pvp_player.silier, Player#camp_pvp_player.exploit},
    admin_log_api:log_camp_battle(Player#camp_pvp_player.user_id, Nth, Scores, Gold, CampExploit, ExpRank),
    Jiangyin = JiangYinRank + JiangyinWin,
    add_camp_score(UserId, Jiangyin),
    Packet = camp_pvp_api:msg_sc_end(Top5,CampExploit,IsCampSuccess,IsTop5,ExpRank,Nth,Scores,Gold,ExpRank,Career,Level,CampId,GuildName, Jiangyin),
    cross_send(Player#camp_pvp_player.user_id, Packet),
    broad_end(PlayerList, Nth + 1, WinCamp, Top5).

send_meritorious_cross(UserId, Count) ->
    case player_api:check_online(UserId) of
        true ->
            camp_pvp_mod:add_meritorious(UserId,Count);
        false ->
            player_offline_api:offline(?MODULE, UserId, Count)
    end.

flush_offline(Player, Value) ->
    player_api:plus_meritorious(Player, Value, ?CONST_COST_CAMP_PVP_AWARD).
%%
%% Local Functions
%%



init_camp_pvp() ->
    Camp_data = #camp_pvp_data{start_time = misc:seconds(), state = ?CONST_CAMP_PVP_START},
    ets:insert(?CONST_ETS_CAMP_PVP_DATA, Camp_data),
    Camp1 = #camp_pvp_camp{camp_id = ?CONST_CAMP_PVP_CAMP_1},
    Camp2 = #camp_pvp_camp{camp_id = ?CONST_CAMP_PVP_CAMP_2},
    ets:insert(?CONST_ETS_CAMP_PVP_CAMP, Camp1),
    ets:insert(?CONST_ETS_CAMP_PVP_CAMP, Camp2).

get_camp_play(UserId) ->
    ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId).


get_top10_counter() ->
    case get(next_top10_camp) of
        ?CONST_CAMP_PVP_CAMP_2 ->
            put(next_top10_camp, ?CONST_CAMP_PVP_CAMP_1),
            ?CONST_CAMP_PVP_CAMP_2;
        _ ->
            put(next_top10_camp, ?CONST_CAMP_PVP_CAMP_2),
            ?CONST_CAMP_PVP_CAMP_1
    end.



%% 根据报名战斗力分配阵营
get_camp_id_map_id(_UserId, Room, CampId) ->
    Camp1Id = camp_pvp_serv:get_monster_id(Room, ?CONST_CAMP_PVP_CAMP_1),
    Camp2Id = camp_pvp_serv:get_monster_id(Room, ?CONST_CAMP_PVP_CAMP_2),
    Camp1Config = data_camp_pvp:get_camp_pvp_config(?CONST_CAMP_PVP_CAMP_1),
    Camp2Config = data_camp_pvp:get_camp_pvp_config(?CONST_CAMP_PVP_CAMP_2),
    Camp3Config = data_camp_pvp:get_camp_pvp_config(3),
    case camp_pvp_api:get_camp_id_random(CampId) of
        ?CONST_CAMP_PVP_CAMP_1 ->
            add_camp(Camp2Id, 0),
            {Camp2Id, Camp1Config#rec_camp_pvp_config.map_id};
        ?CONST_CAMP_PVP_CAMP_2 ->
            add_camp(Camp2Id, 0),
            {Camp2Id, Camp2Config#rec_camp_pvp_config.map_id};
        _ ->
            add_camp(Camp1Id, 0),
            {Camp1Id, Camp3Config#rec_camp_pvp_config.map_id}
    end.

get_safe_map(CampId) ->
    CampConfig = data_camp_pvp:get_camp_pvp_config(CampId rem ?CONST_SYS_NUM_MILLION),
    CampConfig#rec_camp_pvp_config.map_id.

get_kill_award(UserId, Name, CampId, SteakWin, Per) ->
    WinRec = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_WIN, 1}),
    PlayRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId),
   case data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_WIN, SteakWin}) of
       null ->
           round(Per * WinRec#rec_camp_pvp_award.score);
       SteakRec ->
           case SteakWin == 1 of
               true ->
                   round(Per * WinRec#rec_camp_pvp_award.score);
               false ->
                   CampName = get_camp_name(CampId rem ?CONST_SYS_NUM_MILLION),
                    PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_PVP_WIN_STREAK, 
                        [{UserId,Name}],[],
                        [{?TIP_SYS_COMM, misc:to_list(SteakWin)}, 
                         {?TIP_SYS_COMM, misc:to_list(CampName)},
                         {?TIP_SYS_COMM, misc:to_list(SteakRec#rec_camp_pvp_award.score)}]),
                   broad(PacketTips, PlayRec#camp_pvp_player.room_id),
                   round(Per * WinRec#rec_camp_pvp_award.score) + SteakRec#rec_camp_pvp_award.score
           end
   end.

get_collect_award(UserId, Name, CampId, SteakCollect) ->
    CollectRec = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_RESOURCE, 1}),
    PlayRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId),
   case data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_RESOURCE, SteakCollect}) of
       null ->
           CollectRec#rec_camp_pvp_award.score;
       SteakRec ->
           case SteakCollect == 1 of
               true ->
                   CollectRec#rec_camp_pvp_award.score;
               false ->
                    CampName = get_camp_name(CampId rem ?CONST_SYS_NUM_MILLION),
                    PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_RECOURCE_STREAK, 
                        [{UserId,Name}],[],
                        [{?TIP_SYS_COMM, misc:to_list(CampName)},
                         {?TIP_SYS_COMM, misc:to_list(SteakRec#rec_camp_pvp_award.score)}]),
                   broad(PacketTips, PlayRec#camp_pvp_player.room_id),
                    CollectRec#rec_camp_pvp_award.score + SteakRec#rec_camp_pvp_award.score
           end
   end.
       

get_monster_hp(MonsterId) when is_integer(MonsterId)->
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        [] ->
            0;
        [MonsterRec] ->
            HpTule=MonsterRec#camp_pvp_monster.hp_tuple,
            case HpTule of
                [] ->
                    MonsterRec#camp_pvp_monster.hp_max;
                _ ->
                    get_monster_hp(HpTule, 0)
            end
    end;

get_monster_hp(HpTule) ->
    get_monster_hp(HpTule, 0).
get_monster_hp([], HpTotal) ->HpTotal;
get_monster_hp([{{_, _}, _HpTop, Hp}|RestHp], HpTotal) ->
    get_monster_hp(RestHp, HpTotal + Hp).
    

get_scores_by_kill_boss() ->
    AwardConfig = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_KILL_BOSS, 1}),
    AwardConfig#rec_camp_pvp_award.score.

get_player_work_state(UserId) ->
    CampPlayerRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId),
    case CampPlayerRec#camp_pvp_player.recource_type of
        ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL ->
            ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL;
        ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
            ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH;
        _ ->
            ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW
    end.

get_win_add_hp_param() ->
    DataConfig = data_camp_pvp:get_camp_pvp_data(1),
    DataConfig#rec_camp_pvp_data.win_hp_add.

get_dead_cd() ->
    DataConfig = data_camp_pvp:get_camp_pvp_data(1),
    DataConfig#rec_camp_pvp_data.dead_time.

get_init_buff(CampId) ->
    CampConfig = data_camp_pvp:get_camp_pvp_config(CampId),
    CampConfig#rec_camp_pvp_config.buff_list.
            
get_camp_name(CampId) ->
    CampId1 = CampId rem 10,
    CampId2 = camp_pvp_api:get_camp_id_random(CampId1),
    case CampId2 of
        1 ->
            "吴";
        2 ->
            "蜀";
        _ ->
            "魏"
    end.

get_camp_pvp_map_id() ->
    41003.


get_ecourage_per(Times) ->
    Times * 20.

get_active_rate() ->
    active_rate_api:get_rate(?CONST_ACTIVE_CAMP_PVP).
