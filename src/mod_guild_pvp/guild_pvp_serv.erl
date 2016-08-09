%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2013-8-29
%%% -------------------------------------------------------------------
-module(guild_pvp_serv).

-behaviour(gen_server). 
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
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

-define(CONST_GUILD_PVP_COUNT, 3).

-export([
        add_boss_level/1, % 增加boss等级1级
        add_guild_enter_count/1, % 增加阵营人数1人
        add_pvp_score/4, % 增加阵营和军团积分
        app_guild_pvp/3, % 申请活动
        broad_boss_killed/0, % 广播boss被杀了
        car_att/2, % 战车出击
        code_change/3, 
        fix_wall/2, % 修复城墙
        flush_offline/2, % 离线操作刷新
        get_boss_id/0, % 得到bossid
        get_car_id/0, %得到战车id
        get_def_list/0, %拿到防守军团列表
        get_monster_level/1, % 得到怪物等级
        get_next_time/0, %得到下次interval 休眠时间
        get_wall_id/0, % 拿到城墙id
        get_wall_level/0, % 拿到城墙等级
        handle_call/3, 
        handle_cast/2,
        handle_info/2,
        save_map_info/0,
        init/1,
        init_boss_level/0, % 初始化boss等级
        init_monster_info/0, % 初始化怪物信息
        off/1, % 活动结束
        on/1,   % 活动开启
        refresh_monster_cast/4, % 刷新boss血量
        start/1, % 活动开始
        start_link/2,
        sub_guild_enter_count/1, % 减少军团和阵营人数
        update_guild_player_rank/4, % 更新排行榜
        terminate/2, 
        get_guild_player_rank/0,
        tuple_mul/3, 
        init_app/0,
        do_interval_time/0,
        update_guild_app_info_cb/2 
]).

-record(state, {start_time = 0,
                end_time = 0,
                open_time = 0,
                max_def_count = 0,
                max_att_count = 0,
                fix_count = 0,
                fire_cout = 0,
                encourage_count = 0,
                active_begin_time = 0,
                car_killed_time = 0,
                wall_killed_time = 0,
                boss_killed_time = 0,
                state = ?CONST_GUILD_PVP_STATE_OFF}).

%% ====================================================================
%% External functions
%% ====================================================================


add_pvp_score(UserId, UserName, GuildId, Score) ->
    gen_server:cast(?MODULE, {add_pvp_score, UserId, UserName, GuildId, Score}).

%% 军团增加一个出场人数
add_guild_enter_count(GuildId) ->
    gen_server:cast(?MODULE, {add_guild_enter_count, GuildId}).

%% 军团增加一个出场人数
sub_guild_enter_count(GuildId) ->
    gen_server:cast(?MODULE, {sub_guild_enter_count, GuildId}).



broad_boss_killed() ->
    gen_server:cast(?MODULE, broad_boss_killed).

start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).

fix_wall(Player, CampId) ->
    gen_server:cast(?MODULE, {fix_wall, Player, CampId}).

car_att(Player, CampId) ->
    gen_server:cast(?MODULE, {car_att, Player, CampId}).


refresh_monster_cast(MonsterId, Hurt, HurtTuple, UserId) ->
    gen_server:cast(?MODULE, {refresh_monster_cast, MonsterId, Hurt, HurtTuple, UserId}).

    
app_guild_pvp(UserId, Guild, CampId) ->
    gen_server:cast(?MODULE, {app_guild_pvp, UserId, Guild, CampId}).

start([]) ->
    gen_server:cast(?MODULE, start).

on([]) ->
    ok;

on([1]) ->
    gen_server:cast(?MODULE, on).

off([]) ->
    gen_server:cast(?MODULE, off).

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
    process_flag(trap_exit, ?true),
    init_state(),
    init_rank(),
    init_boss_level(),
    init_interval_time(),
    init_app(),
    init_camp_info(),
    save_map_info(),
    {ok, #state{}}.

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

handle_cast({add_pvp_score, UserId, UserName, GuildId, Score}, State) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
        [] ->
            ok;
        [GuildRec] ->
            CampId = GuildRec#guild_pvp_guild.camp_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
                [] ->
                    ok;
                [CampRec] ->
                    update_guild_player_rank(UserId, UserName, GuildId, Score),
                    OldGuildScore = GuildRec#guild_pvp_guild.score,
                    OldCampScore = CampRec#guild_pvp_camp.score,
                    ets:update_element(?CONST_ETS_GUILD_PVP_GUILD, GuildId, {#guild_pvp_guild.score, OldGuildScore + Score}),
                    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, CampId, {#guild_pvp_camp.score, OldCampScore + Score})
            end
    end,
    {noreply, State};

handle_cast(broad_boss_killed, State) ->
    broad_boss_killed2(),
    save_state(State),
    {noreply, State#state{state = ?CONST_GUILD_PVP_STATE_OFF}};

handle_cast({add_guild_enter_count, GuildId}, State) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
        [] ->
            NewState = State;
        [GuildRec] ->
            OldCount = GuildRec#guild_pvp_guild.enter_counter,
            UpdateParam = [{#guild_pvp_guild.enter_counter, OldCount + 1}],
            case OldCount == 0 of
                true ->
                    UpdateParam1 = [{#guild_pvp_guild.first_enter_time, misc:seconds()}|UpdateParam];
                false ->
                    UpdateParam1 = UpdateParam
            end,
            ets:update_element(?CONST_ETS_GUILD_PVP_GUILD, GuildId, UpdateParam1),
            CampId = GuildRec#guild_pvp_guild.camp_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
                [] ->
                    NewState = State;
                [CampRec] ->
                    NewCampCount = CampRec#guild_pvp_camp.count + 1,
                    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, CampId, {#guild_pvp_camp.count, NewCampCount}),
                    NewState = 
                        case CampId of
                            ?CONST_GUILD_PVP_CAMP_ATT ->
                                case State#state.max_att_count < NewCampCount of
                                    true ->
                                        State#state{max_att_count = NewCampCount};
                                    false ->
                                        State
                                end;
                            _ ->
                                case State#state.max_def_count < NewCampCount of
                                    true ->
                                        State#state{max_def_count = NewCampCount};
                                    _ ->
                                        State
                                end
                        end
            end
    end,
    {noreply, NewState};

handle_cast({sub_guild_enter_count, GuildId}, State) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
        [] ->
            ok;
        [GuildRec] ->
            OldCount = GuildRec#guild_pvp_guild.enter_counter,
            NewGuildCount = max(0, OldCount - 1),
            ets:update_element(?CONST_ETS_GUILD_PVP_GUILD, GuildId, {#guild_pvp_guild.enter_counter, NewGuildCount}),
            CampId = GuildRec#guild_pvp_guild.camp_id,
            case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
                [] ->
                    ok;
                [CampRec] ->
                    NewCampCount = max(0, CampRec#guild_pvp_camp.count - 1),
                    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, CampId, {#guild_pvp_camp.count, NewCampCount})
            end
    end,
    {noreply, State};

handle_cast({fix_wall, {UserId, UserName}, CampId}, State) ->
    Now = misc:seconds(),
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
        [] ->
            NewState = State;
        [CampRec] ->
            NextFireTime = CampRec#guild_pvp_camp.next_fix_time,
            case NextFireTime < Now of
                false ->
                    NewState = State,
                    ?MSG_DEBUG("in cd ", []);
                _ ->
                    WallId = get_wall_id(),
                    BossId = get_boss_id(),
                    WallRec = ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, WallId),
                    BossRec = ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, BossId),
                    {MonsterId, MonsterRec, MonsterName} =
                    case is_record(WallRec, guild_pvp_monster) of
                        false ->
                            {BossId, BossRec, "大将军"};
                        true ->
                            case WallRec#guild_pvp_monster.state of
                                ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
                                    {BossId, BossRec, "大将军"};
                                _ ->
                                    {WallId, WallRec, "城门"}
                            end
                    end,
                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 
                                              1000, ?CONST_COST_GUILD_PVP_FIX_WALL) of
                        ?ok ->
                            HpTupleBoss = MonsterRec#guild_pvp_monster.hp_tuple_boss,
                            HpMax = MonsterRec#guild_pvp_monster.hp_max,
                            NewTupleBoss = tuple_mul(HpTupleBoss, (100 + 10)/ 100, HpMax),
                            NewHp = get_new_hp(NewTupleBoss),
                            ?MSG_DEBUG("new Hp is ~w, NewTupleBoss is ~w", [NewHp, NewTupleBoss]),
                            ets:update_element(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId, 
                                [{#guild_pvp_monster.hp, NewHp}, {#guild_pvp_monster.hp_tuple_boss, NewTupleBoss}]),
                            guild_pvp_mod:add_fix_wall_cd(),
                            PacketTips   = message_api:msg_notice(?TIP_GUILD_PVP_FIX_WALL, [{UserId,UserName}],[],[{?TIP_SYS_COMM, misc:to_list(MonsterName)}]),
                            guild_pvp_mod:broad(PacketTips),
                            guild_pvp_mod:broad_monster_info(),
                            guild_pvp_mod:send_msg_announment("UserName", 5),
                            NewState = State#state{fix_count = State#state.fix_count + 1};
                        {?error, _ErrorCode} ->
                            NewState = State
                    end
            end
    end,
    {noreply, NewState};

handle_cast({car_att, {UserId,Name}, CampId}, State) ->
    Now = misc:seconds(),
    case ets:lookup(?CONST_ETS_GUILD_PVP_CAMP, CampId) of
        [] ->
            NewState = State,
            err;
        [CampRec] ->
            NextFireTime = CampRec#guild_pvp_camp.next_fire_time,
            case NextFireTime < Now of
                false ->
                    NewState = State,
                    ?MSG_DEBUG("in cd ", []);
                _ ->
                    WallId = get_wall_id(),
                    BossId = get_boss_id(),
                    WallRec = ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, WallId),
                    {MonsterId,MonsterRec,MonsterName} = 
                    case is_record(WallRec, guild_pvp_monster) of
                        false ->
                            {BossId, ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, BossId), "大将军"};
                        _ ->
                            case WallRec#guild_pvp_monster.state of
                                ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
                                    {BossId, ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, BossId), "大将军"};
                                _ ->
                                    {WallId, WallRec, "城墙"}
                            end
                    end,

                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 
                                              100, ?CONST_COST_GUILD_PVP_CAR_ATT) of
                        ?ok ->
                            HpTupleBoss = MonsterRec#guild_pvp_monster.hp_tuple_boss,
                            NewTupleBoss = tuple_mul(HpTupleBoss, (100 - 2)/ 100),
                            NewHp = get_new_hp(NewTupleBoss),
                            ?MSG_DEBUG("new Hp is ~w, NewTupleBoss is ~w", [NewHp, NewTupleBoss]),
                            ets:update_element(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId, 
                                [{#guild_pvp_monster.hp, NewHp}, {#guild_pvp_monster.hp_tuple_boss, NewTupleBoss}]),
                            guild_pvp_mod:add_att_wall_cd(),
                            guild_pvp_mod:broad_monster_info(),
                            Packet   = message_api:msg_notice(?TIP_GUILD_PVP_CAR_ATT, [{UserId,Name}],[],[{?TIP_SYS_COMM, misc:to_list(MonsterName)}]),
                            NewState = State#state{fire_cout = State#state.fire_cout + 1},
                            guild_pvp_mod:send_msg_announment("UserName", 4),
                            guild_pvp_mod:broad(Packet);
                        {?error, _ErrorCode} ->
                            NewState = State
                    end
            end
    end,
    {noreply, NewState};


            
handle_cast({refresh_monster_cast, MonsterId, Hurt, HurtTuple, UserId}, State) ->
    BossMonster = ets_api:lookup(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId),
    BossMonster2 = BossMonster#guild_pvp_monster{hp_tuple_boss = 
                  boss_mod:set_hp_tuple(BossMonster#guild_pvp_monster.hp_tuple_boss, HurtTuple)},
    case boss_mod:set_hp(BossMonster2#guild_pvp_monster.hp, Hurt) of
        0 ->
            ?MSG_DEBUG("boss ~w is killed", [MonsterId]),
            broad_boss_killed(UserId, MonsterId),
            NewState = 
                case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId) of
                    [] ->
                        State;
                    [MonsterRec] ->
                        Now = misc:seconds(),
                        case MonsterRec#guild_pvp_monster.monster_type of
                            ?CONST_GUILD_PVP_BOSS_TYPE_CAR ->
                                State#state{car_killed_time = Now};
                            ?CONST_GUILD_PVP_BOSS_TYPE_WALL ->
                                State#state{wall_killed_time = Now};
                            ?CONST_GUILD_PVP_BOSS_TYPE_BOSS ->
                                State#state{boss_killed_time = Now}
                        end
                end,
            ets:update_element(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId, 
                               {#guild_pvp_monster.state, ?CONST_CAMP_PVP_MONSTER_STATE_DEAD});
        Hp ->
            NewState = State,
            ?MSG_DEBUG("new Hp is ~w", [Hp]),
            BossMonster3 = BossMonster2#guild_pvp_monster{hp = Hp},
            ets:insert(?CONST_ETS_GUILD_PVP_MONSTER, BossMonster3)
    end,
    guild_pvp_mod:add_boss_hurt(UserId, Hurt),
    {noreply, NewState};

handle_cast({app_guild_pvp, UserId, Guild, CampId}, State) ->
    GuildId = Guild#guild.guild_id,
    Name = Guild#guild.guild_name,
    case CampId of
        ?CONST_GUILD_PVP_CAMP_ATT ->
            TipsPacket = message_api:msg_notice(?TIP_GUILD_PVP_APP_SUCCESS,
                                 [{?TIP_SYS_COMM, misc:to_list("攻城")}]);
        _ ->
            TipsPacket = message_api:msg_notice(?TIP_GUILD_PVP_APP_SUCCESS,
                                 [{?TIP_SYS_COMM, misc:to_list("守城")}])
    end,
    case ets:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId) of
        [] ->
            case guild_pvp_mod:get_choosed_count() < 2 orelse  CampId == ?CONST_GUILD_PVP_CAMP_ATT of
                true ->
                    misc_packet:send(UserId, TipsPacket),
                    GuildPvp = #guild_pvp_guild{camp_id = CampId,
                                            is_leader = false,
                                            choosed_def = false,
                                            guild_id = GuildId,
                                            name = Name,
                                            power = get_guild_power(GuildId)},
                    guild_pvp_mod:guild_db_add_app_guild(GuildPvp),
                    ets:insert(?CONST_ETS_GUILD_PVP_GUILD, GuildPvp);
                false ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_DEF_FULL)
            end;
        [Rec] ->
            case Rec#guild_pvp_guild.is_leader of
                true ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_MASTER_CAN_NOT_APP),
                    ?MSG_ERROR("master can not choose", []);
                false ->
                    misc_packet:send_tips(UserId, ?TIP_GUILD_PVP_APPED)
            end
    end,
    update_guild_app_info(UserId),
    guild_pvp_api:get_guild_app_list(UserId, false),
    {noreply, State};
            

handle_cast(on,  State) ->
    ?MSG_ERROR("active start at ~p", [time()]),
    map_api:kick_all(guild_pvp_api:get_guild_pvp_map_id()),
    crond_api:interval_add(guild_pvp_interval, 1, guild_pvp_api, interval, []),
    clear_camp_info(),
    broad_active_on(),
    init_player_info(),
    init_monster_info(),
    OpenTime = misc:seconds(),
    StartTime = misc:seconds() + 15*60,
    EndTime = StartTime + 30 * 60,
    ets:insert(?CONST_ETS_GUILD_PVP_STATE, 
               #guild_pvp_state{state = ?CONST_GUILD_PVP_STATE_ON, on_time = OpenTime, off_time = EndTime, start_time = StartTime}),
    NewState = 
        State#state{start_time = StartTime, end_time = EndTime, open_time = OpenTime,
                    state = ?CONST_GUILD_PVP_STATE_ON},
    {noreply, NewState};

handle_cast(start, #state{state = ?CONST_GUILD_PVP_STATE_ON} = State) ->
    broad_active_start(),
    init_camp_cd(),
    ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_START}),
    NewState = State#state{state = ?CONST_GUILD_PVP_STATE_START},
    {noreply, NewState};

handle_cast(off, State) ->
    crond_api:interval_del(guild_pvp_interval),
    broad_active_end(),
    ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_OFF}),
    NewState = State#state{state = ?CONST_GUILD_PVP_STATE_OFF},
    catch save_state(NewState),
    {noreply, NewState};



handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------


handle_info(check_interval_time, State) ->
    check_interval_time(),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
    ?MSG_ERROR("guild_pvp_server terminate, reason ~w", [Reason]),
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

clear_camp_info() ->
    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT, [{#guild_pvp_camp.count, 0},
                                                                               {#guild_pvp_camp.score, 0},
                                                                               {#guild_pvp_camp.encourage_times, 0}]),
    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF, [{#guild_pvp_camp.count, 0},
                                                                               {#guild_pvp_camp.score, 0},
                                                                               {#guild_pvp_camp.encourage_times, 0}]).

init_app() ->
    {ok, AppList} = guild_pvp_mod:guild_db_get_app(),
    Fun =
        fun([GuildId, IsLeader, CampId, Power, ChooseDef]) ->
                Name = guild_api:get_guild_name(GuildId),
                Guild = #guild_pvp_guild{guild_id = GuildId,
                                         name = Name,
                                         camp_id = CampId,
                                         choosed_def = (ChooseDef == 1),
                                         enter_counter = 0,
                                         power = Power,
                                         is_leader = (IsLeader == 1)
                                         },
                ets:insert(?CONST_ETS_GUILD_PVP_GUILD, Guild)
        end,
    lists:foreach(Fun, AppList).
                

init_player_info() ->
    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_PLAYER).

init_monster_info() ->
    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_MONSTER),
    BossId = get_boss_id(),
    WallId = get_wall_id(),
    CarId = get_car_id(),
    ?MSG_ERROR("BossId is ~w, Wallid is ~w, CarId is ~w", [BossId, WallId, CarId]),
    {?ok, BossIdHpMax, BossHpTuple} = camp_pvp_mod:get_monster_group_hp(BossId),
    {?ok, WallIdHpMax, WallHpTuple} = camp_pvp_mod:get_monster_group_hp(WallId),
    {?ok, CarIdHpMax, CarHpTuple} = camp_pvp_mod:get_monster_group_hp(CarId),
    ets:insert(?CONST_ETS_GUILD_PVP_MONSTER, 
               #guild_pvp_monster{monster_id = BossId, 
                                  monster_type = ?CONST_GUILD_PVP_BOSS_TYPE_BOSS,
                                  state = ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL,
                                  hp_max = BossIdHpMax,
                                  hp = BossIdHpMax,
                                  camp_id = ?CONST_GUILD_PVP_CAMP_DEF,
                                  hp_tuple_boss = BossHpTuple
                                   }),
    ets:insert(?CONST_ETS_GUILD_PVP_MONSTER, 
               #guild_pvp_monster{monster_id = WallId, 
                                  hp_max = WallIdHpMax,
                                  hp = WallIdHpMax,
                                  monster_type = ?CONST_GUILD_PVP_BOSS_TYPE_WALL,
                                  state = ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL,
                                  camp_id = ?CONST_GUILD_PVP_CAMP_DEF,
                                  hp_tuple_boss = WallHpTuple
                                   }), 
    ets:insert(?CONST_ETS_GUILD_PVP_MONSTER, 
               #guild_pvp_monster{monster_id = CarId,
                                  hp_max = CarIdHpMax,
                                  hp = CarIdHpMax,
                                  monster_type =  ?CONST_GUILD_PVP_BOSS_TYPE_CAR,
                                  state = ?CONST_CAMP_PVP_MONSTER_STATE_NORMOL,
                                  camp_id = ?CONST_GUILD_PVP_CAMP_ATT,
                                  hp_tuple_boss = CarHpTuple
                                   }).

broad_active_on() ->
    ok.

save_state(State) ->
    Now = misc:seconds(),
    StartTime = State#state.start_time,
    LastTime = 
        case Now - StartTime < 0 of
            true ->
                 Now - StartTime  + 600;
            false ->
                Now - StartTime
        end,
    mysql_api:insert(game_guild_pvp_log,
                      [active_end_time, 
                       max_def_count, 
                       max_att_count, 
                       fix_count, 
                       fire_count, 
                       encourage_count, 
                       active_begin_time, 
                       car_killed_time, 
                       wall_killed_time, 
                       boss_killed_time, 
                       active_last_time],
                      [Now,
                       State#state.max_def_count,
                       State#state.max_def_count,
                       State#state.fix_count,
                       State#state.fire_cout,
                       State#state.encourage_count,
                       StartTime,
                       State#state.car_killed_time,
                       State#state.wall_killed_time,
                       State#state.boss_killed_time,
                       LastTime]).

broad_active_start() ->
    Packet   = message_api:msg_notice(?TIP_GUILD_PVP_START),
    guild_pvp_mod:broad(Packet).

broad_boss_killed2() ->
    crond_api:interval_del(guild_pvp_interval),
    ets:update_element(?CONST_ETS_GUILD_PVP_STATE, guild_pvp_state, 
                       {#guild_pvp_state.state, ?CONST_GUILD_PVP_STATE_OFF}),
    active_api:close(?CONST_ACTIVE_GUILD_PVP),
    case guild_pvp_mod:get_att_sorted_list() of
        [] ->
            ok; %%不可能 
        AttList ->
            NewLeader = hd(AttList),
            ets:delete_all_objects(?CONST_ETS_GUILD_PVP_RANK),
            save_rank(AttList),
            NewLeaderName = NewLeader#guild_pvp_guild.name,
            TipsWinPacket = message_api:msg_notice(?TIP_GUILD_PVP_ATT_WIN,
                                 [{?TIP_SYS_COMM, misc:to_list(NewLeaderName)}]),
            WinCampId = ?CONST_GUILD_PVP_CAMP_ATT,
            guild_pvp_mod:broad_camp(WinCampId, TipsWinPacket),
            TipsLosePacket = message_api:msg_notice(?TIP_GUILD_PVP_BOSS_KILLED_DEF),
            guild_pvp_mod:broad_camp(?CONST_GUILD_PVP_CAMP_DEF, TipsLosePacket),
            update_guild_order(),
            broad_end(WinCampId, NewLeaderName),
            %% 设置新的城主帮派
            check_is_send_100_award(NewLeader#guild_pvp_guild.guild_id),
            ets:delete_all_objects(?CONST_ETS_GUILD_PVP_GUILD),
            guild_pvp_mod:guild_db_delete_app(),
            NewLeader2 = NewLeader#guild_pvp_guild{is_leader = true,
                                                   enter_counter = 0, 
                                                   score = 0, 
                                                   camp_id = ?CONST_GUILD_PVP_CAMP_DEF},
            ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF, 
                   {#guild_pvp_camp.leader_guild_id, NewLeader#guild_pvp_guild.guild_id}),
            guild_pvp_mod:guild_db_add_app_guild(NewLeader2),
            ets:insert(?CONST_ETS_GUILD_PVP_GUILD, NewLeader2),
            save_map_info()
    end.
            
check_is_send_100_award(GuildId) ->
    case config:read_deep([server, base, platform_id]) of
        ?CONST_SYS_PLATFORM_4399 ->
            case cross_api:get_self_index() of
                100 ->
                    case guild_pvp_mod:get_def_sorted_list() of
                        [] ->
                            catch hundred_serv_api:send_guild_gift(GuildId);
                        _ ->
                            ok
                    end;
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

init_camp_cd() ->
    Now = misc:seconds(),
    NextFireTime = Now + 60,
    NextFixTime = Now + 5*60,
    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_ATT, {#guild_pvp_camp.next_fire_time, NextFireTime}),
    ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF, {#guild_pvp_camp.next_fix_time, NextFixTime}).

broad_active_end() ->
    BossId = get_boss_id(),
    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_PLAYER_RANK),
    case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, BossId) of
        [] -> ok;
        [BossRec] ->
            case BossRec#guild_pvp_monster.state of
                ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
                    ok; %% 死亡在战斗结束逻辑触发，这里不做重复处理
                _ ->
                    %% 更新胜方排行榜
                    case guild_pvp_mod:get_def_sorted_list() of
                        [] ->
                            case guild_pvp_mod:get_att_sorted_list() of
                                [] ->
                                    ?MSG_ERROR("no def members !!!", []),
                                    NewLeaderName = "",
                                    NewLeader = nul,
                                    WinCampId = ?CONST_GUILD_PVP_CAMP_ATT,
                                    ok;
                                AttList ->
                                    NewLeader = hd(AttList),
                                    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_RANK),
                                    save_rank(AttList), %% 存胜利方排行榜
                                    NewLeaderName = NewLeader#guild_pvp_guild.name,
                                    WinCampId = ?CONST_GUILD_PVP_CAMP_ATT,
                                    TipsPacket = message_api:msg_notice(?TIP_GUILD_PVP_ATT_WIN,
                                                 [{?TIP_SYS_COMM, misc:to_list(NewLeaderName)}]),
                                    guild_pvp_mod:broad(TipsPacket)
                            end;
                        DefList ->
                            NewLeader = hd(DefList),
                            ets:delete_all_objects(?CONST_ETS_GUILD_PVP_RANK),
                            save_rank(DefList), %% 存胜利方排行榜
                            NewLeaderName = NewLeader#guild_pvp_guild.name,
                            WinCampId = ?CONST_GUILD_PVP_CAMP_DEF,
                            TipsPacket = message_api:msg_notice(?TIP_GUILD_PVP_DEF_WIN,
                                                 [{?TIP_SYS_COMM, misc:to_list(NewLeaderName)}]),
                            guild_pvp_mod:broad(TipsPacket)
                    end,
                    %% 广播获得结束
                    update_guild_order(),
                    broad_end(WinCampId, NewLeaderName),

                    case ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD) of
                        [] ->
                            ets:delete_all_objects(?CONST_ETS_GUILD_PVP_GUILD),
                            guild_pvp_mod:guild_db_delete_app(),
                            PacketTips = message_api:msg_notice(?TIP_GUILD_PVP_NO_WINER),
                            misc_app:broadcast_world_2(PacketTips),
                            ok;
                        _ ->
                            %% 设置新守城帮派
                            NewLeader2 = NewLeader#guild_pvp_guild{is_leader = true,  
                                                                   enter_counter = 0,
                                                                   score = 0, 
                                                                   camp_id = ?CONST_GUILD_PVP_CAMP_DEF},
                            check_is_send_100_award(NewLeader#guild_pvp_guild.guild_id),
                            ets:delete_all_objects(?CONST_ETS_GUILD_PVP_GUILD),
                            guild_pvp_mod:guild_db_delete_app(),
                            guild_pvp_mod:guild_db_add_app_guild(NewLeader2),
                            ets:update_element(?CONST_ETS_GUILD_PVP_CAMP, ?CONST_GUILD_PVP_CAMP_DEF,
                                               {#guild_pvp_camp.leader_guild_id, NewLeader#guild_pvp_guild.guild_id}),
                            ets:insert(?CONST_ETS_GUILD_PVP_GUILD, NewLeader2),
                            save_map_info()
                    end
            end
    end.

update_guild_order() ->
    DefList = guild_pvp_mod:get_def_sorted_list(),
    AttList = guild_pvp_mod:get_att_sorted_list(),
    update_guild_order(DefList, 1),
    update_guild_order(AttList, 1).
update_guild_order([], _Nth) ->ok;
update_guild_order([Guild|RestGuildList], Nth) ->
    ets:update_element(?CONST_ETS_GUILD_PVP_GUILD, Guild#guild_pvp_guild.guild_id, {#guild_pvp_guild.rank, Nth}),
    update_guild_order(RestGuildList, Nth + 1).

broad_end(WinCampId, NewLeaderName) ->
    UserList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER),
    broad_end(UserList, WinCampId, NewLeaderName).

broad_end([], _ ,_ ) ->ok;
broad_end([Player|RestList], WinCampId, NewLeaderName) ->
    UserId = Player#guild_pvp_player.user_id,
    IsWin = Player#guild_pvp_player.camp_id == WinCampId,
    GuildId = Player#guild_pvp_player.gulid_id,
    GuildRec = ets_api:lookup(?CONST_ETS_GUILD_PVP_GUILD, GuildId),
    Score = GuildRec#guild_pvp_guild.score,
    Rank = GuildRec#guild_pvp_guild.rank,
    AwardRec = data_guild_pvp:get_guild_pvp_award(1),
    {Copper, Exploit, Meritorious} = 
        case GuildRec#guild_pvp_guild.camp_id of
            WinCampId ->
                case GuildRec#guild_pvp_guild.name == NewLeaderName of
                    true ->
                        case Player#guild_pvp_player.position of
                            ?CONST_GUILD_POSITION_CHIEF ->
                                 {Mc, Me, MM} = AwardRec#rec_guild_pvp_award.win_master;
                            ?CONST_GUILD_POSITION_VICE_CHIEF ->
                                {Mc, Me, MM} = AwardRec#rec_guild_pvp_award.win_master2;
                            _ ->
                                {Mc, MM, Me} = {0, 0, 0}
                        end;
                    _ ->
                        {Mc, MM, Me} = {0, 0, 0}
                end,
                {C,E, M} = AwardRec#rec_guild_pvp_award.win_camp,
                {C + Mc, E + Me, MM + M};
            _ ->
                AwardRec#rec_guild_pvp_award.lose_camp
        end,
    case player_api:check_online(UserId) of
        true ->
            guild_pvp_mod:add_copper(UserId, Copper),
            guild_pvp_mod:add_exploit(UserId, Exploit),
            guild_pvp_mod:add_meritorious(UserId, Meritorious);
        false ->
            player_offline_api:offline(?MODULE, UserId, {Copper, Exploit, Meritorious})
    end,
    BattleCopper = Player#guild_pvp_player.copper,
    IsAtt = (GuildRec#guild_pvp_guild.camp_id == ?CONST_GUILD_PVP_CAMP_ATT),
    Packet = guild_pvp_api:msg_broad_end(IsWin, NewLeaderName, Score, Rank, Copper, Exploit, Meritorious, BattleCopper, IsAtt),
    ActiveEndPacket = active_api:msg_end(?CONST_ACTIVE_GUILD_PVP, ?TIP_GUILD_PVP_END),
    misc_packet:send(Player#guild_pvp_player.user_id, <<Packet/binary, ActiveEndPacket/binary>>),
   
    broad_end(RestList, WinCampId, NewLeaderName).


flush_offline(Player, {Copper, Exploit, Meritorious}) ->
    UserId = Player#player.user_id,
    guild_pvp_mod:add_copper(UserId, Copper),
    guild_pvp_mod:add_exploit(UserId, Exploit),
    guild_pvp_mod:add_meritorious(UserId, Meritorious).

save_rank([]) ->ok;
save_rank([#guild_pvp_guild{camp_id = CampId, guild_id = GuildId, score = Score, name = Name}|RestList]) ->
     {ok, LeaderId} = guild_api:get_guild_chief_id(GuildId),
     LeaderName = player_api:get_name(LeaderId),
     mysql_api:insert(game_guild_pvp, [guild_id, guild_score, camp_id], [GuildId, Score, CampId]),
     ets:insert(?CONST_ETS_GUILD_PVP_RANK, #guild_pvp_rank{guild_id = GuildId,
                                                           guild_score = Score,
                                                           guild_name = Name,
                                                           guild_master_name = LeaderName,
                                                           camp_id = CampId
                                                           }),
     save_rank(RestList).


get_guild_power(GuildId) ->
    GuildMembers = guild_api:get_guild_members(GuildId),
    get_guild_power(GuildMembers, 0).

get_guild_power([], Power) ->
    Power;
get_guild_power([{_Uid, _UserName, Power1}|Rest], Power) ->
    get_guild_power(Rest, Power1 + Power).

update_guild_app_info(UserId) ->
    player_api:process_send(UserId, ?MODULE, update_guild_app_info_cb, []).

update_guild_app_info_cb(Player, _) ->
    guild_pvp_api:get_guild_pvp_app_info(Player),
    {ok, Player}.
    
get_def_list() ->
    GulidList = ets:tab2list(?CONST_ETS_GUILD_PVP_GUILD),
    FilterFun =
        fun(Guild) ->
            Guild#guild_pvp_guild.choosed_def
        end,
    lists:filter(FilterFun, GulidList).

get_wall_id() ->
    BossLevel = get_wall_level(),
    MonsterRec = data_guild_pvp:get_guild_pvp_boss({?CONST_GUILD_PVP_BOSS_TYPE_WALL, BossLevel}),
    MonsterRec#rec_guild_pvp_boss.monsters.

get_boss_id() ->
    BossLevel = get_boss_level(),
    BossRec = data_guild_pvp:get_guild_pvp_boss({?CONST_GUILD_PVP_BOSS_TYPE_BOSS, BossLevel}),
    BossRec#rec_guild_pvp_boss.monsters.

get_car_id() ->
    CarLevel = get_car_level(),
    BossRec = data_guild_pvp:get_guild_pvp_boss({?CONST_GUILD_PVP_BOSS_TYPE_CAR, CarLevel}),
    BossRec#rec_guild_pvp_boss.monsters.

tuple_mul(Tuple, Mul, MaxHp) ->
    List = tuple_to_list(Tuple),
    Fun = 
        fun(N) ->
                case N of
                    0 ->0;
                    _ ->
                     min(MaxHp, round(N * Mul) + 1)
                end
        end,
    NewList = lists:map(Fun, List),
    list_to_tuple(NewList).

tuple_mul(Tuple, Mul) ->
    List = tuple_to_list(Tuple),
    Fun = 
        fun(N) ->
                case N of
                    0 ->0;
                    _ ->
                     round(N * Mul) + 1
                end
        end,
    NewList = lists:map(Fun, List),
    list_to_tuple(NewList).

get_new_hp(HpTupleBoss) ->
     lists:sum(tuple_to_list(HpTupleBoss)).


is_car_live() ->
    CarId = get_car_id(),
    case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, CarId) of
        [] ->
            false;
        [Rec] ->
            Rec#guild_pvp_monster.state /= ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
    end.

init_camp_info() ->
    Now = misc:seconds(),
    NextFireTime = Now + 1,
    NextFixTime = Now + 1,
    AttCamp = #guild_pvp_camp{
                              next_fire_time = NextFireTime,
                              next_fix_time = NextFixTime,
                              camp_id = ?CONST_GUILD_PVP_CAMP_ATT
                              },
    DefCamp = #guild_pvp_camp{
                              next_fire_time = NextFireTime,
                              next_fix_time = NextFixTime,
                              leader_guild_id = guild_pvp_mod:get_tower_owner_id(),
                              camp_id = ?CONST_GUILD_PVP_CAMP_DEF
                              },
    ets:insert(?CONST_ETS_GUILD_PVP_CAMP, [AttCamp, DefCamp]).
    

insert_rank_info([]) ->ok;
insert_rank_info([[GuildId, GuildScore, CampId]|Rest]) ->
    GuildName = guild_api:get_guild_name(GuildId),
    {ok, GuildLeadId} = guild_api:get_guild_chief_id(GuildId),
    LeaderName = player_api:get_name(GuildLeadId),
    ets:insert(?CONST_ETS_GUILD_PVP_RANK, #guild_pvp_rank{guild_id = GuildId,
                                                          guild_master_name = LeaderName,
                                                          guild_name = GuildName,
                                                          camp_id = CampId,
                                                          guild_score = GuildScore}),
    insert_rank_info(Rest).


                        

init_state() ->
    ets:insert(?CONST_ETS_GUILD_PVP_STATE, #guild_pvp_state{state = ?CONST_GUILD_PVP_STATE_OFF}).

init_rank() ->
    case ets:info(?CONST_ETS_GUILD_PVP_RANK, size) of
        0 ->
            case mysql_api:select_execute(<<"select `guild_id`, `guild_score`, `camp_id`  from `game_guild_pvp`; ">>) of
                {ok, Datas} ->
                    insert_rank_info(Datas);
                _ ->
                    ok
            end;
        _ ->
            ok
    end.

init_boss_level() ->
     case mysql_api:select_execute(<<"select `boss_type`, `boss_level` from `game_guild_pvp_boss_level`">>) of
        {ok, Datas} when Datas /= [] ->
            init_boss_level(Datas);
         _ ->
             mysql_api:insert(game_guild_pvp_boss_level, [boss_type, boss_level], [?CONST_GUILD_PVP_BOSS_TYPE_WALL, 1]),
             mysql_api:insert(game_guild_pvp_boss_level, [boss_type, boss_level], [?CONST_GUILD_PVP_BOSS_TYPE_BOSS, 1]),
             mysql_api:insert(game_guild_pvp_boss_level, [boss_type, boss_level], [?CONST_GUILD_PVP_BOSS_TYPE_CAR, 1]),
             put({boss_level, ?CONST_GUILD_PVP_BOSS_TYPE_WALL}, 1),
             put({boss_level, ?CONST_GUILD_PVP_BOSS_TYPE_BOSS}, 1),
             put({boss_level, ?CONST_GUILD_PVP_BOSS_TYPE_CAR}, 1)
     end.

init_boss_level([]) ->
    ok;
init_boss_level([[Type, Level]|Rest]) ->
     put({boss_level, Type}, Level),
     init_boss_level(Rest).

get_monster_level(Type) ->
    case Type of
        ?CONST_GUILD_PVP_BOSS_TYPE_BOSS ->
            get_boss_level();
        ?CONST_GUILD_PVP_BOSS_TYPE_CAR ->
            get_car_level();
        _ ->
            get_wall_level()
    end.

get_dict_level(Type) ->
    Pid = erlang:whereis(guild_pvp_serv),
    {dictionary,Dic} = process_info(Pid,dictionary),
    case lists:keyfind({boss_level, Type}, 1,    Dic) of
        {{boss_level, Type},Level} ->
            Level;
        _ ->
            1
    end.

get_wall_level() ->
    get_dict_level(?CONST_GUILD_PVP_BOSS_TYPE_WALL).

get_car_level() ->
    get_dict_level(?CONST_GUILD_PVP_BOSS_TYPE_CAR).

get_boss_level() ->
    get_dict_level(?CONST_GUILD_PVP_BOSS_TYPE_BOSS).

add_boss_level(Type) ->
    Level = get({boss_level, Type}),
    NewLevel = Level + 1,
    case NewLevel > 100 of
        true ->
            ok;
        _ ->
            mysql_api:update(<<"update game_guild_pvp_boss_level set boss_level = '", 
                                   (misc:to_binary(NewLevel))/binary, "' where boss_type = '",
                                   (misc:to_binary(Type))/binary, "'; ">>),
            put({boss_level, Type}, NewLevel)
    end.

get_next_time() ->
    {_H ,M, S} = time(),
    60 * (60 - M) - S.


init_interval_time() -> 
    NextTime = get_next_time() + 1,
    ?MSG_ERROR("next time is ~w", [NextTime]),
    erlang:send_after(1000 * NextTime, ?MODULE, check_interval_time).

check_interval_time() ->
    erlang:send_after(60 * 60 * 1000, ?MODULE, check_interval_time),
    do_check_map_info(),
    do_interval_time().

do_interval_time() ->
    Date = date(),
    Week = calendar:day_of_the_week(Date),
    case Week /= 3 andalso Week /= 7 of
        true ->
            ok;
        false ->
            Time = time(),
            {H, _M, _S} = Time,
            if 
                H < 12 andalso H >= 5 ->
                    HDif = 12 -H,
                    TipsPacket = message_api:msg_notice(?TIP_GUILD_PVP_APP_END_LEFT,
                                         [{?TIP_SYS_COMM, misc:to_list(HDif)}]),
                    misc_app:broadcast_world_2(TipsPacket);
                H == 12 ->
                    guild_pvp_api:app_end([]),
                    Packet = message_api:msg_notice(?TIP_GUILD_PVP_APP_END),
                    misc_app:broadcast_world_2(Packet);
                true ->
                    ok
            end
    end.
                    
    
add_score_for_kill_boss(UserId, ScoreAdd) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [#guild_pvp_player{gulid_id = GuildId, scores = ScoreOld, name = Name}] ->
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, {#guild_pvp_player.scores, ScoreOld + ScoreAdd}),
            guild_pvp_serv:add_pvp_score(UserId, Name, GuildId, ScoreAdd)
    end.

broad_boss_killed(UserId, MonsterId) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, MonsterId) of
        [] ->
            ok;
        [BossRec] ->
            add_score_for_kill_boss(UserId, 100),
            AwardRec = data_guild_pvp:get_guild_pvp_award(1),
            UserRec = ets_api:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId),
            UserName = UserRec#guild_pvp_player.name,
            add_boss_level(BossRec#guild_pvp_monster.monster_type),
            guild_pvp_mod:send_msg_announment(UserName, BossRec#guild_pvp_monster.monster_type),
            case BossRec#guild_pvp_monster.monster_type of
                ?CONST_GUILD_PVP_BOSS_TYPE_BOSS ->
                    Gold = AwardRec#rec_guild_pvp_award.kill_boss,
                    PacketTips   = message_api:msg_notice(?TIP_GUILD_PVP_KILL_BOSS, [{UserId,UserName}],[],[{?TIP_SYS_COMM, misc:to_list(100)}]),
                    guild_pvp_mod:add_copper(UserId, Gold),
                    guild_pvp_mod:add_player_guild_pvp_copper(UserId, Gold),
                    broad_boss_killed();
                ?CONST_GUILD_PVP_BOSS_TYPE_WALL ->
                    Gold = AwardRec#rec_guild_pvp_award.kill_wall,
                    PacketTips   = message_api:msg_notice(?TIP_GUILD_PVP_KILL_WALL, [{UserId,UserName}],[],[{?TIP_SYS_COMM, misc:to_list(100)}]),
                    guild_pvp_mod:add_copper(UserId, Gold),
                    guild_pvp_mod:add_player_guild_pvp_copper(UserId, Gold),
                    CarId = get_wall_id(),
                    IsCarDead = 
                        case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, CarId) of
                            [] ->
                                true;
                            [CarRec] ->
                                CarRec#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
                        end,
                    Packet = guild_pvp_api:msg_boss_state(true, IsCarDead),
                    guild_pvp_mod:broad(Packet);
                _ ->
                    Exp = AwardRec#rec_guild_pvp_award.kill_car,
                    PacketTips   = message_api:msg_notice(?TIP_GUILD_PVP_KILL_CAR, [{UserId,UserName}],[],[{?TIP_SYS_COMM, misc:to_list(100)}]),
                    guild_pvp_mod:add_meritorious(UserId, Exp),
                    WallId = get_car_id(),
                    IsWallDead = 
                        case ets:lookup(?CONST_ETS_GUILD_PVP_MONSTER, WallId) of
                            [] ->
                                true;
                            [CarRec] ->
                                CarRec#guild_pvp_monster.state == ?CONST_CAMP_PVP_MONSTER_STATE_DEAD
                        end,
                    Packet = guild_pvp_api:msg_boss_state(IsWallDead, true),
                    guild_pvp_mod:broad(Packet)
            end,
            PacketDead = guild_pvp_api:msg_monster_dead(MonsterId),
            guild_pvp_mod:broad(<<PacketTips/binary, PacketDead/binary>>)
    end.

do_check_map_info() ->
    {H, M, S} = time(),
    case H + M + S == 0 of
        true ->
            save_map_info();
        _ ->
            ok
    end.


save_map_info() ->
    ets:delete_all_objects(?CONST_ETS_GUILD_PVP_MAP_INFO),
    LeaderId = guild_pvp_mod:get_tower_owner_id(),
    case LeaderId == 0 of
        true ->
            ok;
        false ->
            Name = guild_pvp_mod:get_tower_owner_name(),
            MemberIdList = guild_pvp_mod:get_guild_member(LeaderId),
            ShowList = get_show_list(MemberIdList),
            save_map_info(ShowList, Name, LeaderId)
    end.

get_show_list(MemberIdList) ->
    SortFun =
        fun(Id1, Id2) ->
            {ok, [Guild1]} = player_api:get_player_fields(Id1,[#player.guild]),
            {ok, [Guild2]} = player_api:get_player_fields(Id2,[#player.guild]),
            if
                Guild1#guild.guild_pos == 0 ->
                    false;
                Guild2#guild.guild_pos == 0 ->
                    true;
                Guild1#guild.guild_pos < Guild2#guild.guild_pos ->
                    true;
                true ->
                    false
            end
        end,
    SortedIdList = lists:sort(SortFun, MemberIdList),
    lists:sublist(SortedIdList, 3).

save_map_info([], _Name, _LeaderId) ->
    ok;
save_map_info([Id|RestIdList], GuildName, LeaderId) ->
    {ok, [Info, Guild]} = player_api:get_player_fields(Id,[#player.info, #player.guild]),
    Name = Info#info.user_name,
    Career = Info#info.pro,
    Sex = Info#info.sex,
    Rank = Guild#guild.guild_pos,
    Title = Info#info.current_title,
    Rec= #guild_pvp_map_info{chenghao = Title,
                             sex = Sex,
                             career = Career,
                             user_name = Name,
                             guild_id = LeaderId,
                             guild_name = GuildName,
                             rank = Rank,
                             user_id = Id},
    ets:insert(?CONST_ETS_GUILD_PVP_MAP_INFO, Rec),
    save_map_info(RestIdList, GuildName, LeaderId).
    

update_guild_player_rank(UserId, UserName, GuildId, Score) ->
    case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER_RANK, GuildId) of
        [] ->
            RankRec = #guild_pvp_score_rank{guild_id = GuildId, score_list = [{UserId, UserName, Score}]},
            ets:insert(?CONST_ETS_GUILD_PVP_PLAYER_RANK, RankRec);
        [RankRec] ->
            OldScoreList = RankRec#guild_pvp_score_rank.score_list,
            case lists:keyfind(UserId, 1, OldScoreList) of
                false ->
                    NewScoreList = [{UserId, UserName, Score}|OldScoreList];
                {UserId, _UserName, OldScore} ->
                    NewScoreList = lists:keyreplace(UserId, 1, OldScoreList, {UserId, UserName, OldScore + Score})
            end,
            ets:update_element(?CONST_ETS_GUILD_PVP_PLAYER_RANK, GuildId, {#guild_pvp_score_rank.score_list, NewScoreList})
    end.

get_guild_player_rank() ->
    GuildList = ets:tab2list(?CONST_ETS_GUILD_PVP_PLAYER_RANK),
    SortFun =
                fun({_, _, Score1}, {_, _, Score2}) ->
                     Score1 > Score2
                end,
    FormatFun1 =
        fun({_, UserName, Score}) ->
                {Score, UserName}
        end,
    FormatFun =
        fun(GuildRec) ->
                List = GuildRec#guild_pvp_score_rank.score_list,
                SortedList = lists:sort(SortFun, List),
                SubList = lists:sublist(SortedList, 5),
                {GuildRec#guild_pvp_score_rank.guild_id, lists:map(FormatFun1, SubList)}
        end,
     lists:map(FormatFun, GuildList).           
