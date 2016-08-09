%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2013-7-8
%%% -------------------------------------------------------------------
-module(camp_pvp_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.battle.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([d_event/2,
         hurt_boss/2,
         init_room/1,
         init_monster_by_room/1,
         refresh_room_box/1,
         exit_camp/2,
         get_room_msg/1,
         start_link/2,
         refresh_box_list/1,
         get_monster_id_by_user/2,
         get_monster_id/2,
         get_camp_id_map_id/3,
         get_box/2,
         clear_player_state/1,
         att_car/2,
         get_offset_camp/1,
         start_battle/3,
         cross_add_title/2,
         get_and_clear_boss_hurt/1,
         attack_boss/2,            % 攻击boss
         add_camp/2,               % 增加阵营人数
         open/0, end1/0,          % 活动开始，结束
         reset_counter/0,
         submit_recource/3,        % 增加阵营的 资源和积分
         refresh_monster_cast/4]). % 每回合刷新boss血量
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


%% ====================================================================
%% External functions
%% ====================================================================

get_box(UserId, BoxId) ->
    gen_server:cast(?MODULE, {get_box, UserId, BoxId}).

cross_add_title(UserId, Nth) ->
    gen_server:cast(?MODULE, {cross_add_title, UserId, Nth}).

start_battle(UserId1, UserId2, Type) ->
    gen_server:cast(?MODULE, {start_battle, UserId1, UserId2, Type}).

init_room(RoomId) ->
    gen_server:call(?MODULE, {init_room, RoomId}).

att_car(UserId, MonsterId) ->
    gen_server:cast(?MODULE, {att_car, UserId, MonsterId}).

get_camp_id_map_id(User_id, Room, CampId) ->
    gen_server:call(?MODULE, {get_camp_id_map_id, User_id, Room, CampId}).

get_and_clear_boss_hurt(UserId) ->
    gen_server:call(?MODULE, {get_and_clear_boss_hurt, UserId}).

exit_camp(CampId, Power) ->
    gen_server:cast(?MODULE, {exit_camp,CampId, Power}).

hurt_boss(BossId, NewBossHp) ->
    gen_server:cast(?MODULE, {hurt_boss, BossId, NewBossHp}).

open() ->
    gen_server:cast(?MODULE, open).

end1() ->
    gen_server:cast(?MODULE, end1).

reset_counter() ->
    gen_server:cast(?MODULE, reset_counter).

refresh_monster_cast(MonsterId, Hurt, HurtTuple, UserId) ->
    gen_server:cast(?MODULE, {refresh_monster_cast, MonsterId, Hurt, HurtTuple, UserId}).

add_camp(CampId, Power) ->
    gen_server:cast(?MODULE, {add_camp, CampId, Power}).

submit_recource(Camp, Recource, ScoreAdd) ->
    gen_server:cast(?MODULE, {submit_recource, Camp, Recource, ScoreAdd}).

attack_boss(UserId, BossId) when is_integer(UserId) ->
    gen_server:cast(?MODULE, {attack_boss, UserId, BossId});

attack_boss(Monster, BossId) ->
    gen_server:cast(?MODULE, {attack_boss, Monster, BossId}).

start_link(_, _) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    Seconds = get_next_reset_seconds(), 
    timer:apply_after(Seconds*1000, ?MODULE,reset_counter, []),
    {ok, []}.


get_next_reset_seconds() ->
    {H,M,S} = erlang:time(),
    case {H,M,S} >= {18,55,0} of
        true ->
            calendar:time_to_seconds({24,0,0}) - calendar:time_to_seconds({H,M,S}) +  calendar:time_to_seconds({18,55,0});
        false ->
            calendar:time_to_seconds({18,55,0}) - calendar:time_to_seconds({H,M,S})
    end.


%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_call({get_and_clear_boss_hurt, UserId}, _from, State) ->
    Hurt = camp_pvp_mod:get_and_clear_boss_hurt(UserId),
    {reply, Hurt, State};

handle_call({get_camp_id_map_id, User_id, Room, CampId}, _from, State) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, Room) of
        [] ->
            init_monster_by_room(Room);
        _ ->
            ok
    end,
    Reply = camp_pvp_mod:get_camp_id_map_id(User_id, Room, CampId),
    {reply, Reply, State};

handle_call({init_room, RoomId}, _from, State) ->
    init_monster_by_room(RoomId),
    Reply = ok,
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({get_box, UserId, BoxId}, State) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            OpenTime = PlayerRec#camp_pvp_player.cash_count,
            case OpenTime >= 3 of
                true ->
                    Packet = message_api:msg_notice(?TIP_CAMP_PVP_BOX_FULL),
                    misc_packet:send_cross(UserId, Packet);     
                false ->
                    Room = PlayerRec#camp_pvp_player.room_id,
                    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, Room) of
                        [] ->
                            ok;
                        [#camp_room{box_list = BoxList}] ->
                            case lists:keyfind(BoxId, #camp_pvp_cash_list.id, BoxList) of
                                false ->
                                    ok;
                                #camp_pvp_cash_list{is_open = true} ->
                                    Packet = message_api:msg_notice(?TIP_CAMP_PVP_BOX_OPENED),
                                    misc_packet:send_cross(UserId, Packet);
                                Box ->
                                    NewBox = Box#camp_pvp_cash_list{is_open = true},
                                    NewList = lists:keyreplace(BoxId, #camp_pvp_cash_list.id, BoxList, NewBox),
                                    ets:update_element(?CONST_ETS_CAMP_PVP_ROOM, Room, {#camp_room.box_list, NewList}),
                                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.cash_count, OpenTime + 1}),
                                    Packet = camp_pvp_api:msg_remove_cash_box(BoxId),
                                    PacketBoxLeft = camp_pvp_api:msg_box_left(2 - OpenTime),
                                    misc_packet:send_cross(UserId, PacketBoxLeft),
                                    camp_pvp_mod:broad(Packet, Room),
                                    camp_pvp_api:send_award_cross(UserId, Box#camp_pvp_cash_list.type)
                            end
                    end
            end
    end,
    {noreply, State};

                        

handle_cast({cross_add_title, UserId, Nth}, State) ->
    camp_pvp_mod:insert_db(UserId, Nth),
    achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_PVP_CAMP_RANK, Nth, 1),
    {noreply, State};

handle_cast({start_battle, UserId1, UserId21, Type1}, State) ->
    {UserId2, Type} = camp_pvp_mod:get_battle_type_by_id(Type1, UserId1, UserId21),
    case Type of
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
            case check_pvp_start(UserId1, UserId2) of
                {?ok, Buff1, Hp1, Buff2, Hp2, Ad5} ->
                    Param = 
                         #param{battle_type = ?CONST_BATTLE_CAMP_PVP, 
                                attr = {Buff1, Buff2}, 
                                ad1 = Hp1, 
                                ad2 = Hp2, 
                                ad3 = Type,
                                ad4 = {UserId1, UserId2},
                                ad5 = Ad5},
                    {Data1, Data2} = get_battle_data(UserId1, UserId2),
                    case battle_cross_api:start(Data1, Data2, Param) of
                        ?ok ->
                            camp_pvp_mod:broad_state_change_to_battle(UserId1, UserId2, Type),
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}),
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId2, {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE});
                        _ ->
                            ok
                    end;
                in_pk_cd ->
                    ok;
                _ ->
                    camp_pvp_mod:cross_tips(UserId1, ?TIP_CAMP_PVP_MONSTER_BATTLE)
            end;
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
            case check_pve_start(UserId1, UserId2) of
                {?ok, _Buff1, _Hp1, _Buff2, _Hp2, _Ad5} ->
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId1, 
                        [{#camp_pvp_player.att_car_id, UserId2},
                        {#camp_pvp_player.state_end_time, misc:seconds() + 10},
                        {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_ATT_CAR}]),
                    Packet = camp_pvp_api:msg_att_car_success(),
                    camp_pvp_mod:cross_send(UserId1, Packet);
                _ ->
                    camp_pvp_mod:cross_tips(UserId1, ?TIP_CAMP_PVP_MONSTER_DEAD)
            end;
        _ ->
            ok
    end,
    {noreply, State};
 

handle_cast({att_car, UserId, MonsterId}, State) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        [] ->
            ok;
        [MonsterRec] ->
            case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
                [] ->
                    ok;
                [PlayerRec] ->
                    case MonsterRec#camp_pvp_monster.state of
                        ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
                            camp_pvp_mod:cross_tips(UserId, ?TIP_CAMP_PVP_CARR_DEAD);
                        _ ->
                            Rate = camp_pvp_mod:get_active_rate(),
                            OldHp = MonsterRec#camp_pvp_monster.hp,
                            NewHp = max(OldHp - 4, 0),
                            Level = PlayerRec#camp_pvp_player.lv,
                            CopperAdd = round(Rate * 1000*(0.8+0.2*Level)),
                            ScoreAdd = 10,
                            submit_recource(PlayerRec#camp_pvp_player.camp_id, 0, ScoreAdd),
                            camp_pvp_mod:cross_cast(UserId, player_money_api, plus_money, [UserId, 
                                ?CONST_SYS_GOLD_BIND, CopperAdd, ?CONST_COST_CAMP_PVE_COPPER]),
                            TipsPacket = message_api:msg_notice(?TIP_CAMP_PVP_ATT_CAR_SUCCESS,
                                 [{?TIP_SYS_COMM, misc:to_list(ScoreAdd)}, {?TIP_SYS_COMM, misc:to_list(CopperAdd)}]),
                            camp_pvp_mod:cross_send(UserId, TipsPacket),
                            OldCopper = PlayerRec#camp_pvp_player.silier,
                            OldScore = PlayerRec#camp_pvp_player.scores,
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                                               [{#camp_pvp_player.silier, OldCopper + CopperAdd},
                                                {#camp_pvp_player.scores, OldScore + ScoreAdd}]),
                            NowCash = PlayerRec#camp_pvp_player.battle_cash_count,
                            case NowCash >=2 of
                                true ->
                                    ok;
                                _ ->
                                    Rand = misc:rand(1, 100),
                                    case Rand >= 98 of
                                        true ->
                                            RandCash = misc:rand(1, 10),
                                            PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_PVE_WIN_CASH, 
                                                [{UserId,PlayerRec#camp_pvp_player.user_name}],[],
                                                [{?TIP_SYS_COMM, misc:to_list(RandCash)}]),
                                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER,
                                                               UserId, 
                                                              {#camp_pvp_player.battle_cash_count, NowCash + 1}),
                                            camp_pvp_mod:broad(PacketTips, PlayerRec#camp_pvp_player.room_id),
                                            camp_pvp_mod:cross_cast(UserId, camp_pvp_mod, pvp_cash, [UserId, RandCash]);
                                        _ ->
                                            ok
                                    end
                            end,
                            case NewHp == 0 of
                                true ->
                                    boss_dead(UserId, MonsterId);
                                false ->
                                    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.hp, NewHp}),
                                    camp_pvp_mod:broad_monster_hp(MonsterId)
                            end
                    end
            end
    end,
    {noreply, State};
            


handle_cast({exit_camp, CampId, Power}, State) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId) of
        [] ->
            ok;
        [CampRec] ->
            OldCount = CampRec#camp_pvp_camp.count,
            OldPower = CampRec#camp_pvp_camp.combat,
            ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, CampId, 
                               [{#camp_pvp_camp.count, OldCount - 1}, {#camp_pvp_camp.combat, OldPower- Power}])
    end,
    {noreply, State};

handle_cast({hurt_boss, BossId, NewBossHp}, State) ->
    case camp_pvp_mod:check_camp_start() of
        true ->
            ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, BossId, [{#camp_pvp_monster.hp_tuple, NewBossHp}]),
            camp_pvp_mod:broad_monster_hp(BossId);
        false ->
            ok
    end,
    {noreply, State};

handle_cast({refresh_monster_cast, MonsterId, Hurt, HurtTuple, UserId}, State) ->
    case camp_pvp_mod:check_camp_start() of
        true ->
            BossMonster = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId),
            BossMonster2 = BossMonster#camp_pvp_monster{hp_tuple_boss = 
                          boss_mod:set_hp_tuple(BossMonster#camp_pvp_monster.hp_tuple_boss, HurtTuple)},
            case boss_mod:set_hp(BossMonster2#camp_pvp_monster.hp, Hurt) of
                0 ->
                    ?MSG_DEBUG("boss ~w is killed", [MonsterId]),
                    Score = camp_pvp_mod:get_scores_by_kill_boss(),
                    camp_pvp_mod:add_score(UserId, Score),
                    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, 
                                       {#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
                    CampId = BossMonster#camp_pvp_monster.camp,
                    OffSetId = get_offset_camp(CampId),
                    MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId),
                    MonsterBuffList = MonsterConfig#rec_camp_pvp_monster.buff_list,
                    [{AddType, BuffId, Value}|_] = MonsterBuffList,
                    CampRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, OffSetId),
                    OldCampBuff = CampRec#camp_pvp_camp.buff,
                    NewCampBuff = OldCampBuff ++ MonsterBuffList,
                    ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, OffSetId, {#camp_pvp_camp.buff, NewCampBuff}),
                    PacketTips   = camp_pvp_api:msg_buff_miss(MonsterId, CampId, BuffId, AddType, Value),
                    camp_pvp_mod:broad(PacketTips, MonsterId div ?CONST_SYS_NUM_MILLION),
                    ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.killed_user_id, UserId}),
                    Packet = camp_pvp_msg:msg_monster_killed(MonsterId),
                    camp_pvp_mod:broad_map(Packet, MonsterId div ?CONST_SYS_NUM_MILLION);
                Hp ->
                    ?MSG_DEBUG("new Hp is ~w", [Hp]),
                    BossMonster3 = BossMonster2#camp_pvp_monster{hp = Hp},
                    ets:insert(?CONST_ETS_CAMP_PVP_MONSTER, BossMonster3)
            end;
        false ->
            ok
    end,
    camp_pvp_mod:add_boss_hurt(UserId, Hurt),
    {noreply, State};

handle_cast({attack_boss, Monster, BossId}, State) ->
    try 
        true = camp_pvp_mod:check_camp_start(),
        MonsterId = Monster#camp_pvp_monster.monster_id,
        Boss    = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, BossId),
        MCamp = Monster#camp_pvp_monster.camp,
        BCamp = Boss#camp_pvp_monster.camp,
        Harm = Monster#camp_pvp_monster.harm,
        ?MSG_DEBUG("harm is ~w", [Harm]),
        case BCamp == MCamp of
            true ->
                ?MSG_ERROR("monster ~w attack self camp boss ~w", [MonsterId, BossId]);
            false ->
                HpOld = Boss#camp_pvp_monster.hp,
                case HpOld =< 0 of
                    true ->
                        ?MSG_ERROR("boss ~w haved dead", [BossId]);
                    false ->
                        Mname = camp_pvp_mod:get_camp_name(MCamp),
                        Bname = camp_pvp_mod:get_camp_name(BCamp),
                        PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_HURT_BOSS,
                             [{?TIP_SYS_COMM, misc:to_list(Mname)}, {?TIP_SYS_COMM, misc:to_list(Bname)}]),
                        camp_pvp_mod:broad(PacketTips, BossId div ?CONST_SYS_NUM_MILLION),
                        HpOld = Boss#camp_pvp_monster.hp,
                        NewHp = max(1, HpOld - Harm),
                        ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, BossId, 
                            [{#camp_pvp_monster.hp, NewHp}])
                end
        end
    catch
        _Error:Reason ->
              ?MSG_ERROR("attack boss err, Reason ~w", [{_Error,Reason}])
    end,
    {noreply, State};

handle_cast({add_camp, CampId, Power} ,State) ->
    CampRecord = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId),
    CampCount = CampRecord#camp_pvp_camp.count,
    CampSteak = CampRecord#camp_pvp_camp.streak_count,
    OldCombat = CampRecord#camp_pvp_camp.combat,
    ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, CampId, 
                       [{#camp_pvp_camp.count, CampCount + 1},
                        {#camp_pvp_camp.streak_count, CampSteak + 1},
                        {#camp_pvp_camp.combat, OldCombat + Power}]),
    OffSetCampId = get_offset_camp(CampId),
    ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, OffSetCampId, {#camp_pvp_camp.streak_count, 0}),
    {noreply, State};

%% 1 检查更新活动数据，2 初始化阵营数据
handle_cast(open,  State) ->
    ?MSG_DEBUG("try to start camp pvp", []),
    case ets:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
        [#camp_pvp_data{state = ?CONST_CAMP_PVP_START}] ->
            ok;
        [#camp_pvp_data{state = ?CONST_CAMP_PVP_OPEN}] ->
            ok;
        _ ->
            crond_api:interval_add(camp_pvp_interval, 1, camp_pvp_api, camp_pvp_interval, []),
            StartTime = misc:seconds() + 60,
            EndTime =  StartTime + active_api:get_active_last(camp_pvp),
            ?MSG_DEBUG("starttime is ~w, endtime is ~w", [StartTime, EndTime]),
            ets:insert(?CONST_ETS_CAMP_PVP_DATA,  #camp_pvp_data{state = ?CONST_CAMP_PVP_OPEN, 
                                                                 start_time = StartTime,
                                                                 end_time = EndTime,
                                                                 combat_top10 = []}),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_ROOM),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_MONSTER)
    end,
    {noreply, State};

%% 1 跟新状态， 2 发奖， 3 删除所有玩家信息， 4 活动心跳
handle_cast(end1,  State) ->
    ?MSG_DEBUG("camp pvp end", []),
    case ets:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
        [#camp_pvp_data{state = ?CONST_CAMP_PVP_START}] ->
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.state, ?CONST_CAMP_PVP_END}),
            delete_camp_team(),
            camp_pvp_mod:broad_end(),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_PLAYER),
            camp_pvp_monster:camp_pvp_end(),
            crond_api:interval_del(camp_pvp_interval),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_ROOM),
            ets:delete_all_objects(?CONST_ETS_CROSS_OUT),
            camp_pvp_counter_serv:reset_cast(),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_TEAM_CROSS),
            erlang:send_after(1000*1000, self(), clear_cross_cache),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_CAMP);
        _ ->
            ok
    end,
    {noreply, State};

handle_cast(reset_counter,State) ->
    ?MSG_ERROR("reset camp counter,~p",[erlang:time()]),
    camp_pvp_counter_serv:reset_cast(),
    Seconds = get_next_reset_seconds(), 
    timer:apply_after(Seconds*1000, ?MODULE,reset_counter, []),
    {noreply, State};

handle_cast({submit_recource, Camp, Recource, Score},  State) ->
    ?MSG_DEBUG("camp ~w submit recouce ~w, score ~w", [Camp, Recource, Score]),
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, Camp) of
        CampRec when is_record(CampRec, camp_pvp_camp) ->
            ResourceTotal = CampRec#camp_pvp_camp.resource + Recource,
            ScoreTotal = CampRec#camp_pvp_camp.scores + Score,
            ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, Camp,
                               [{#camp_pvp_camp.scores, ScoreTotal},
                                {#camp_pvp_camp.resource, ResourceTotal}]),
            check_recource_event(ResourceTotal, Recource, Camp); 
        _ ->
            skip
    end,
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(clear_cross_cache, State) ->
    ?MSG_ERROR("clear cache !!!!!!!", []),
    ets:delete_all_objects(?CONST_ETS_CROSS_OUT),
    camp_pvp_counter_serv:reset_cast(),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?MSG_ERROR("camp_pvp_server terminate ~w,~w",[Reason, State]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

refresh_room_box(Count) ->
    Fun =
        fun(#camp_room{room_id = RoomId}) ->
                List = refresh_box_list(Count),
                Msg = box_msg(List, true),
                camp_pvp_mod:broad_map(Msg, 41003, RoomId),
                ets:update_element(?CONST_ETS_CAMP_PVP_ROOM, RoomId, {#camp_room.box_list, List})
        end,
    RoomList = ets:tab2list(?CONST_ETS_CAMP_PVP_ROOM),
    lists:foreach(Fun, RoomList).

get_room_msg(RoomId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, RoomId) of
        [] ->
            <<>>;
        [#camp_room{box_list = BoxList}] ->
            case BoxList == [] of
                true ->
                    <<>>;
                _ ->
                    box_msg(BoxList, false)
            end
    end.

box_msg(List, IsNew) ->
    Filter = 
        fun(#camp_pvp_cash_list{is_open = IsOpen}) ->
                not IsOpen
        end,
    List1 = lists:filter(Filter, List),
    Fun = 
        fun(#camp_pvp_cash_list{id = Id, type = Type, x = X, y = Y}) ->
                {Type, X, Y, Id}
        end,
    List2 = lists:map(Fun, List1),
    camp_pvp_api:msg_refresh_cash(List2, IsNew).

refresh_box_list(Count) ->
    Fun =
        fun(Id) ->
                Rand = misc:rand(1, 100),
                Type = 
                    if
                        Rand > 40 ->
                            ?CONST_CAMP_PVP_CASH_TYPE_IRON;
                        Rand > 20 ->
                            ?CONST_CAMP_PVP_CASH_TYPE_COPPER;
                        Rand > 5 ->
                            ?CONST_CAMP_PVP_CASH_TYPE_SILVER;
                        true ->
                            ?CONST_CAMP_PVP_CASH_TYPE_GOLD
                    end,
                X = misc:rand(500, 4000),
                Y = misc:rand(500, 2200),
                #camp_pvp_cash_list{id = Id, type = Type, x = X, y = Y}
        end,
    lists:map(Fun, lists:seq(1, Count)).

delete_camp_team() ->
    TeamOverPacket = camp_pvp_api:msg_team_over(),
    IndexList =ets:tab2list(?CONST_ETS_CAMP_TEAM_INDEX),
        Fun = 
            fun(TeamIndex) ->
                  UserId = TeamIndex#camp_team_index.user_id,
                  clear_player_state(UserId),
                  misc_packet:send(UserId, TeamOverPacket)
            end,
    lists:foreach(Fun, IndexList),
    ets:delete_all_objects(?CONST_ETS_CAMP_TEAM_INDEX),
    ets:delete_all_objects(?CONST_ETS_CAMP_TEAM_LIST).

clear_player_state(UserId) ->
    PlayerPid = player_api:get_player_pid(UserId),
    player_api:process_send(PlayerPid, player_state_api, try_set_state_play, ?CONST_PLAYER_PLAY_CITY).

init_monster_by_room(RoomId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, RoomId) of
        [] ->
            Fun =
                fun(CampId) ->
                    CampConfig = data_camp_pvp:get_camp_pvp_config(CampId),
                    BossIdList = CampConfig#rec_camp_pvp_config.boss_id,
                    ets:insert(?CONST_ETS_CAMP_PVP_CAMP, 
                               #camp_pvp_camp{
                                              camp_id = get_monster_id(RoomId, CampId),
                                              boss = BossIdList
                                             }),
                    init_boss(BossIdList, RoomId)
                end,
            lists:foreach(Fun, [?CONST_CAMP_PVP_CAMP_1, ?CONST_CAMP_PVP_CAMP_2]),
            Pid1 = init_map(41001, ?CONST_MAP_TYPE_FACTION),
            Week = calendar:day_of_the_week(date()),
            Pid2 = 
                case Week rem 2 of
                    0 ->
                        init_map(41000, ?CONST_MAP_TYPE_FACTION);
                    _ ->
                        init_map(41002, ?CONST_MAP_TYPE_FACTION)
                end,
            Pid3 = init_map(41003, ?CONST_MAP_TYPE_CAMP_PVP),
            Room = #camp_room{room_id = RoomId, map_pid1 = Pid1, map_pid2 = Pid2, map_pid3 = Pid3},
            ets:insert(?CONST_ETS_CAMP_PVP_ROOM, Room);
        _ ->
            ok
    end.

init_map(MapId, MapType) ->
    Param = #map_param{ad1 = MapId},
    {ok, Pid} = camp_pvp_api:create_map(MapId, MapType, Param),
    Pid.

    
d_event(CampId, EventId) ->
    EventConfig = data_camp_pvp:get_camp_pvp_event(EventId),
    do_event(CampId, EventConfig, 100).

check_recource_event(RecourceTotal, AddRecource, CampId) ->
    CampCfg = data_camp_pvp:get_camp_pvp_config(CampId rem ?CONST_SYS_NUM_MILLION),
    Event = CampCfg#rec_camp_pvp_config.event,
    case check_event(Event, RecourceTotal, AddRecource) of
        false ->
            ?MSG_DEBUG("nothing to do", []),
            ok;
        {EventId, Value} ->
            ?MSG_DEBUG("do event ~w", [EventId]),
            EventConfig = data_camp_pvp:get_camp_pvp_event(EventId),
            do_event(CampId, EventConfig, Value)
    end.

boss_dead(UserId, MonsterId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        [] ->
            ok;
        [BossMonster] ->
            ?MSG_DEBUG("boss ~w is killed", [MonsterId]),
            ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, 
                               {#camp_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}),
            CampId = BossMonster#camp_pvp_monster.camp,
            OffSetId = get_offset_camp(CampId),
            MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId rem ?CONST_SYS_NUM_MILLION),
            MonsterBuffList = MonsterConfig#rec_camp_pvp_monster.buff_list,
            [{AddType, BuffId, Value}|_] = MonsterBuffList,
            CampRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, OffSetId),
            OldCampBuff = CampRec#camp_pvp_camp.buff,
            NewCampBuff = OldCampBuff ++ MonsterBuffList,
            ets:update_element(?CONST_ETS_CAMP_PVP_CAMP, OffSetId, {#camp_pvp_camp.buff, NewCampBuff}),
            PacketTips   = camp_pvp_api:msg_buff_miss(MonsterId rem ?CONST_SYS_NUM_MILLION, CampId, BuffId, AddType, Value),
            camp_pvp_mod:broad(PacketTips, MonsterId div ?CONST_SYS_NUM_MILLION),
            ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId, {#camp_pvp_monster.killed_user_id, UserId}),
            Packet = camp_pvp_msg:msg_monster_killed(MonsterId rem ?CONST_SYS_NUM_MILLION),
            camp_pvp_mod:broad_map(Packet, MonsterId div ?CONST_SYS_NUM_MILLION)
    end.

%% 给buff npc减血
do_event(CampIdOffSet, #rec_camp_pvp_event{event_type = EventType, hp_percent = Per}, _Value) 
                                when EventType == ?CONST_CAMP_PVP_EVENT_HP ->
    CampId = get_offset_camp(CampIdOffSet),
    CampRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId),
    RoomId = CampId div ?CONST_SYS_NUM_MILLION,
    BossList = CampRec#camp_pvp_camp.boss,
    Fun =
        fun(BossId1) ->
            BossId = get_monster_id(RoomId, BossId1),
            BossRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, BossId),
            OldHp = BossRec#camp_pvp_monster.hp,
            Per1 = (100 - Per)/ 100,
            NewHp = round(Per1 * OldHp + 1),
            ets:update_element(?CONST_ETS_CAMP_PVP_MONSTER, BossId, 
                [{#camp_pvp_monster.hp, NewHp}]),
            camp_pvp_mod:broad_monster_hp(BossId)
        end,
    FilerFun =
        fun(BossId1, Acc) ->
            BossId = get_monster_id(RoomId, BossId1),
            BossRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_MONSTER, BossId),
            case BossRec#camp_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD of
                true ->
                    Acc;
                false ->
                    [{BossId1}|Acc]
            end
        end,
    lists:foreach(Fun, BossList),
    MonsterHurtList = lists:foldl(FilerFun, [], BossList),
    ?MSG_DEBUG("hurt monster list is ~w", [MonsterHurtList]),
    PacketBossHurt = camp_pvp_api:msg_hurt_all_boss(CampId, MonsterHurtList),
    camp_pvp_mod:broad_map(PacketBossHurt, RoomId),
    Name = camp_pvp_mod:get_camp_name(CampIdOffSet),
    PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_KILL_BOSS, [{?TIP_SYS_COMM, misc:to_list(Name)}]),
    camp_pvp_mod:broad(PacketTips, RoomId);


%% 召唤冲锋死士
do_event(CampId, #rec_camp_pvp_event{event_type = EventType, monster_id = MonsterList}, _Value) 
                                when EventType == ?CONST_CAMP_PVP_EVENT_MONSTER ->ok.
%%     ?MSG_DEBUG("monster id list is ~w", [MonsterList]),
%%     RoomId = CampId div ?CONST_SYS_NUM_MILLION,
%%     Fun = 
%%         fun(MonsterId) ->
%%                 MonsterConfig = data_camp_pvp:get_camp_pvp_monster(MonsterId),
%%                 {BornX,BornY} =  MonsterConfig#rec_camp_pvp_monster.born_point,
%%                 {TargetX,_} =  MonsterConfig#rec_camp_pvp_monster.target_point,
%%                  WalkPoint = camp_pvp_monster:get_walk_point(BornX, TargetX),
%%                 {?ok, HpMax, _HpTuple} = camp_pvp_mod:get_monster_group_hp(MonsterId),
%%                 MonsterId1 = get_monster_id(RoomId, MonsterId),
%%                 MonsterCamp = #camp_pvp_monster{
%%                                                 walkPoint = WalkPoint,
%%                                                 born_point_y = BornY,
%%                                                 hp = HpMax,
%%                                                 hp_max = HpMax,
%%                                                 monster_id = MonsterId1, 
%%                                                 camp = CampId, 
%%                                                 harm = MonsterConfig#rec_camp_pvp_monster.harm
%%                                                 },
%%                 PName = camp_pvp_sup:start_child_monster(MonsterCamp),
%%                 ets:insert(?CONST_ETS_CAMP_PVP_MONSTER, MonsterCamp#camp_pvp_monster{monster_pid = PName}),
%%                 camp_pvp_mod:broad_monster_hp(MonsterId),
%%                 MonsterId1 = get_monster_id(RoomId, MonsterId),
%%                 {_WalkPoint1, Packet} = camp_pvp_mod:monster_package(MonsterId1, WalkPoint, BornY),
%%                 camp_pvp_mod:broad_map(Packet, RoomId)
%%         end,
%%     CampName = camp_pvp_mod:get_camp_name(CampId),
%%     PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_CALL_MONSTER,  [{?TIP_SYS_COMM, misc:to_list(CampName)}]),
%%     camp_pvp_mod:broad(PacketTips, RoomId),
%%     lists:foreach(Fun, MonsterList),
%%     Packet = camp_pvp_api:msg_call_monster(),
%%     camp_pvp_mod:broad(Packet, RoomId),
%%     camp_pvp_mod:broad_monster_info().

check_event([], _RecourceTotal, _AddRecource) ->
    false;
check_event([Event|RestEvent], RecourceTotal, AddRecource) ->
    ?MSG_DEBUG("check event ~w", [Event]),
    {Value, EventId} = Event,
    case Value =< RecourceTotal andalso Value > RecourceTotal - AddRecource of
        true ->
            {EventId, Value};
        false ->
            check_event(RestEvent, RecourceTotal, AddRecource) 
    end.

get_battle_data(UserId1, UserId2) ->
    Cross1 = ets_api:lookup(?CONST_ETS_CROSS_IN, UserId1),
    Cross2 = ets_api:lookup(?CONST_ETS_CROSS_IN, UserId2),
    {Cross1#cross_in.player_data, Cross2#cross_in.player_data}.


get_monster_id_by_user(UserId, MonsterId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            0;
        [Player] ->
            RoomNo = Player#camp_pvp_player.room_id,
            get_monster_id(RoomNo, MonsterId)
    end.

get_monster_id(RoomNo, MonsterId) ->
    RoomNo * ?CONST_SYS_NUM_MILLION + MonsterId.



init_boss([], _RoomNo) ->
    ok;
init_boss([BossId|RestBossIdList], RoomNo) ->
    MonsterBoss = data_camp_pvp:get_camp_pvp_monster(BossId),
    {?ok, _HpMax, HpTuple} = camp_pvp_mod:get_monster_group_hp(BossId),
    CampMonster = #camp_pvp_monster{
                                    hp_tuple_boss = HpTuple,
                                    hp_max = 100,
                                    hp_tuple = [],
                                    hp = 100,
                                    monster_id = get_monster_id(RoomNo, BossId),
                                    camp = get_monster_id(RoomNo, MonsterBoss#rec_camp_pvp_monster.camp)
                                    },
    ets:insert(?CONST_ETS_CAMP_PVP_MONSTER, CampMonster),
    init_boss(RestBossIdList, RoomNo).

get_offset_camp(CampId) ->
    Room = CampId div ?CONST_SYS_NUM_MILLION,
    CampId1 = 
        case CampId rem 10 of
            ?CONST_CAMP_PVP_CAMP_1 ->
                ?CONST_CAMP_PVP_CAMP_2;
            _ ->
                ?CONST_CAMP_PVP_CAMP_1
        end,
    get_monster_id(Room, CampId1).




get_param(CampPlayer) ->
    Hp = CampPlayer#camp_pvp_player.hp,
    CampId = CampPlayer#camp_pvp_player.camp_id,
    Buff = 
        case ets:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId) of
            [] ->
                [];
            [CampRec] ->
                CampRec#camp_pvp_camp.buff
        end,
    EncourageTime = CampPlayer#camp_pvp_player.encourage_times,
    PerAdd = camp_pvp_mod:get_ecourage_per(EncourageTime),
    case PerAdd of
        0 ->
            Buff1=Buff ++ CampPlayer#camp_pvp_player.buff_list;
        _ ->
            AddBuff = [{3, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, PerAdd*100}, 
                       {3, ?CONST_PLAYER_ATTR_FORCE_ATTACK, PerAdd*100}],
            Buff1 = Buff ++ AddBuff ++ CampPlayer#camp_pvp_player.buff_list
    end,
    {Buff1, Hp}.

get_check_state_pve(UserId1, UserId2) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1) of
        [] ->
            false;
        [Rec1] ->
            case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, UserId2) of
                [] ->
                    false;
                [Rec2] ->
                    case Rec1#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_DEAD andalso
                         Rec1#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE of
                        true ->
                            case Rec2#camp_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD  of
                                true ->
                                    {get_param(Rec1), camp_pvp_api:get_boss_state(UserId2)};
                                false ->
                                    false
                            end;
                        _ ->
                            false
                    end;
                _ ->
                    false
            end
    end.

get_check_state(UserId1, UserId2) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1) of
        [] ->
            false;
        [Rec1] ->
            case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId2) of
                [] ->
                    false;
                [Rec2] ->
                    case Rec2#camp_pvp_player.camp_id == Rec1#camp_pvp_player.camp_id of
                        true ->
                            false;
                        _ ->
                            case Rec1#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_DEAD andalso
                                 Rec1#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE of
                                true ->
                                    case Rec2#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_DEAD andalso 
                                         Rec2#camp_pvp_player.state /= ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE of
                                        true ->
                                            {get_param(Rec1), get_param(Rec2)};
                                        false ->
                                            false
                                    end;
                                _ ->
                                    false
                            end
                    end;
                _ ->
                    false
            end
    end.

check_pvp_start(UserId1, UserId2) ->
    case camp_pvp_api:get_pk_cd_left(UserId1, UserId2) of
        0 ->
            case get_check_state(UserId1, UserId2) of
                false ->
                    false;
                {{Buff1, Hp1}, {Buff2, Hp2}} ->
                    {?ok, Buff1, Hp1, Buff2, Hp2, 0}
            end;
        CdLeft ->
            PacketCd  = message_api:msg_notice(?TIP_CAMP_PVP_PK_CD,
                                         [{?TIP_SYS_COMM, misc:to_list(CdLeft)}]),
            misc_packet:send(UserId1, PacketCd),
            in_pk_cd
    end.


check_pve_start(UserId1, UserId2) ->
    case get_check_state_pve(UserId1, UserId2) of
        false ->
            false;
        {{Buff1, Hp1}, {?ok, Buff2, Hp2, Ad2}} ->
            {?ok, Buff1, Hp1, Buff2, Hp2, Ad2}
    end.
               