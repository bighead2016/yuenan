%%%
-module(robot_boss_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include("record.robot.hrl").

%%
%% Exported Functions
%%
-export([insert_boss_player/7, enter/1, record_boss_player/2,
         clear/4, is_fighting/2, interval/1, battle_over/3,
         battle_over_robot/4, change_robot_state/3, cost_money/4, check_money/3,
         flush_offline/2, save_all/0, plus_money/4,
         get_boss_type/1]).

%%
%% API Functions
%%

insert_boss_player(BossId, UserId, IsEn, IsReborn, IsQR, BCash2Delta, CashDelta) ->
    P = record_boss_player_setting(BossId, UserId, IsEn, IsReborn, IsQR, BCash2Delta, CashDelta),
    ets:insert(?CONST_ETS_BOSS_ROBOT_SETTING, P).

record_boss_player_setting(BossId, UserId, IsEn, IsReborn, IsQR, BCash2Delta, CashDelta) ->
    #ets_boss_robot_setting{
                            key = {BossId, UserId},
                            boss_id = BossId,
                            user_id = UserId,
                            is_encourage = IsEn,
                            is_reborn = IsReborn,
                            is_quick_reborn = IsQR,
                            bcash_2 = BCash2Delta,
                            cash = CashDelta
                           }.

%% setting() ->
%%     ets:insert(?CONST_ETS_BOSS_DOLL, {1, [10002]}),
%%     insert_boss_player(10002, 1, 1, 0, 1, 20),
%%     
%%     ets:insert(?CONST_ETS_BOSS_DOLL, {3, [10002]}),
%%     insert_boss_player(10002, 3, 1, 0, 1, 20),
%%     
%%     ets:insert(?CONST_ETS_BOSS_DOLL, {4, [10002]}),
%%     insert_boss_player(10002, 4, 1, 0, 1, 20),
%%     
%%     ets:insert(?CONST_ETS_BOSS_DOLL, {5, [10002]}),
%%     insert_boss_player(10002, 5, 1, 0, 1, 20),
%%     ok.
%% 
%% go() ->
%%     BossData = boss_mod:get_boss_data(10002),
%%     enter(BossData).

%% robot_boss_api:setting().
%% robot_boss_api:go().
enter(BossId) ->
	BossId1			= boss_mod:check_boss_id(BossId),
	case ets:first(?CONST_ETS_BOSS_DOLL) of
		'$end_of_table' -> ?ok;
		Key	->
			enter_ext(Key, BossId1),
			enter(Key, BossId1)
	end.

enter(Key, BossId) ->
	case ets:next(?CONST_ETS_BOSS_DOLL, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			enter_ext(Key1, BossId),
			enter(Key1, BossId)
	end.

enter_ext(Key, BossId) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DOLL, Key) of
		{Key, BIds} ->
			case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, Key}) of
				#ets_boss_robot_setting{exsit = Exsit} when Exsit == 1 ->
					?MSG_DEBUG("3333333333333333333333333333333333", []),
					?ok;
				_ ->
					%%?MSG_DEBUG("3333333333333333333333333333333333~p", [{BossId, UserId}]),
					enter(Key, BIds, BossId)
			end;
		_ ->
			?ok
	end.

%% 机器人进入
enter(UserId, BIds, BossId) ->
	Node			= node(),
	ServIndex 		= cross_api:get_self_index(),
	try
		?true							= lists:member(BossId, BIds),                                    
		{?ok, Player, _}				= player_api:get_player_first(UserId),
		Lv								= (Player#player.info)#info.lv,
		{MasterNode, RoomId, LvPhase}	= cross_api:get_boss_master(UserId, Lv, ?true),								%% 根据人物等级分房间
		BossPlayer						= boss_mod:record_boss_player(Player, RoomId, BossId, ?true, MasterNode),
		catch yunying_activity_mod:update_shuangdan_activity_info(UserId,1002,1),         						%双旦活动妖魔破替身参加检测
	%%         player_money_api:handle_minus(UserId, ?CONST_COST_BOSS_ROBOT, 30),
		{MapId, _BossData}	= case Node of
								  MasterNode -> boss_mod:enter_boss_map(UserId, RoomId, Node, ServIndex, LvPhase, BossPlayer, BossId);
								  _ -> rpc:call(MasterNode,  boss_mod, enter_boss_map, [UserId, RoomId, Node, ServIndex, LvPhase, BossPlayer, BossId])
							  end,
		NewBossPlayer		= BossPlayer#boss_player{room_id = RoomId, map_id = MapId, serv_id = ServIndex, master_node = MasterNode},
		ets_api:insert(?CONST_ETS_BOSS_PLAYER, NewBossPlayer),
		?MSG_DEBUG("44444444444444444444444~p", [{MapId}]),
		{?ok, MapPid}		= map_api:enter_map_robot(Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL, practice_state = 0}, MapId, ?CONST_MAP_PTYPE_BOSS_ROBOT),
		Type 				= get_boss_type(BossId),
		?MSG_DEBUG("44444444444444444444444~p", [MapPid]),
		
		{BCash, Cash}		= handler_doll_cost(Type, UserId),
		ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {Type, UserId}, 
                                       [
                                        {#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_INIT},
										{#ets_boss_robot_setting.cash, Cash},
										{#ets_boss_robot_setting.bcash_2, BCash},
                                        {#ets_boss_robot_setting.map_pid, MapPid},
										{#ets_boss_robot_setting.exsit, 1}
                                       ]),
		enter_ext(Player)
	catch
		_:_ -> ?ok
	end.

%% 增加活跃度和资源找回次数
enter_ext(Player) ->
	UserId			= Player#player.user_id,
	schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_BOSS),
	case player_api:check_online(UserId) of
		?true  -> ?ok;
		?false ->
			schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_BOSS)
	end.

handler_doll_cost(Type, UserId) ->
	case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {Type, UserId}) of
		#ets_boss_robot_setting{cash = Cash, bcash_2 = BCash} ->
			BossConfig = data_boss:get_boss_config(),
			DollCost = BossConfig#rec_boss_config.doll_cash,
			
			BCash2	= BCash - DollCost,
			if
				BCash2 >= 0 -> {BCash2, Cash};
				?true -> {0, Cash + BCash2}
			end;
		_ ->
			{0, 0}
	end.


clear(BossId, UserId, Idx, {RankBGold, RankMeri, _}) ->
    BossId2 = get_boss_type(BossId), 
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{map_pid = MapPid, cash = Cash, cash_used = CashUsed, bgold = BGoldRobot, bcash_2 = BCash2, bcash_2_used = BCash2Used} ->
            case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
                #boss_player{hurt_reward = {BGold, Meri, _}} ->
                    TotalMeri  = Meri+RankMeri,
                    TotalBGold = BGold+RankBGold+BGoldRobot,
					
                    FinalCash = misc:max(Cash-CashUsed, 0),
                    FinalBCash2 = misc:max(BCash2-BCash2Used, 0),
					
                    TotalUsed = BCash2Used+CashUsed,
%%                     map_api:exit_map(#player{user_id = UserId, map_pid = MapPid}),
                    case player_api:check_online(UserId) of
                        ?true ->
                            player_money_api:plus_money(UserId, ?CONST_SYS_CASH, FinalCash, ?CONST_COST_BOSS_ROBOT_RETURN),
                            player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, FinalBCash2, ?CONST_COST_BOSS_ROBOT_RETURN),
                            player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, BGold+RankBGold, ?CONST_COST_BOSS_REWARD_HURT),
                            player_api:process_send(UserId, player_api, plus_meritorious, TotalMeri),
                            ReceiveName = player_api:get_name(UserId),
                            Content1 = make_mail_mark(Idx), 
                            Content2 = make_mail_mark(TotalMeri), 
                            Content3 = make_mail_mark(TotalBGold), 
                            if
                                0 >= Cash + BCash2 - 30 ->
                                    mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD, 
                                                                      Content1++Content2++Content3, 
                                                                      [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD);
                                ?true ->
                                    Content4 = make_mail_mark(TotalUsed),
                                    Content5 = make_mail_mark(FinalCash+FinalBCash2),
                                    mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD_2, 
                                                                      Content1++Content2++Content3++Content4++Content5, 
                                                                      [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD)
                            end,
                            ?ok;
                        _ ->
                            player_offline_api:offline(?MODULE, UserId, {TotalBGold, TotalMeri, BCash2Used, CashUsed, FinalBCash2, FinalCash, Cash, BCash2, Idx})
                    end,
                    map_api:exit_map(#player{map_pid = MapPid, user_id = UserId}, ?CONST_MAP_PTYPE_BOSS_ROBOT),
                    ets:delete(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}),
                    ?CONST_SYS_TRUE;
                _ ->
                    ?CONST_SYS_FALSE
            end;
        _ ->
            ?CONST_SYS_FALSE
    end.

make_mail_mark(Value) ->
    [{[{misc:to_list(Value)}]}].

flush_offline(Player, {BGold, Meri, BCash2Used, CashUsed, BCash2Remind, CashRemind, Cash, BCash2, Idx}) ->
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH, CashRemind, ?CONST_COST_BOSS_ROBOT_RETURN),
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH_BIND_2, BCash2Remind, ?CONST_COST_BOSS_ROBOT_RETURN),
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, BGold, ?CONST_COST_BOSS_REWARD_HURT),
    {?ok, Player2} = player_api:plus_meritorious(Player, Meri),
    ReceiveName = player_api:get_name(Player#player.user_id),
    Content1 = make_mail_mark(Idx), 
    Content2 = make_mail_mark(Meri), 
    Content3 = make_mail_mark(BGold), 
    if
        0 >= Cash + BCash2 - 30 ->
            mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD, 
                                              Content1++Content2++Content3, 
                                              [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD);
        ?true ->
            Content4 = make_mail_mark(CashUsed+BCash2Used-30), 
            Content5 = make_mail_mark(CashRemind+BCash2Remind),
            mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD_2, 
                                              Content1++Content2++Content3++Content4++Content5, 
                                              [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD)
    end,
    {?ok, Player2};
flush_offline(Player, {BGold, Meri, CashUsed, CashRemind, Cash, Idx}) ->
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH, CashRemind, ?CONST_COST_BOSS_ROBOT_RETURN),
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, BGold, ?CONST_COST_BOSS_REWARD_HURT),
    {?ok, Player2} = player_api:plus_meritorious(Player, Meri),
    ReceiveName = player_api:get_name(Player#player.user_id),
    Content1 = make_mail_mark(Idx), 
    Content2 = make_mail_mark(Meri), 
    Content3 = make_mail_mark(BGold), 
    if
        0 >= Cash ->
            mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD, 
                                              Content1++Content2++Content3, 
                                              [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD);
        ?true ->
            Content4 = make_mail_mark(CashUsed), 
            Content5 = make_mail_mark(CashRemind),
            mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD_2, 
                                              Content1++Content2++Content3++Content4++Content5, 
                                              [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD)
    end,
    {?ok, Player2};
flush_offline(Player, {Cash}) ->
    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_ROBOT_RETURN),
    {?ok, Player}.

record_boss_player(BossId, UserId) ->
    case player_api:get_player_fields(UserId, [#player.info]) of
        {?ok, [Info]} ->
            record_boss_player(BossId, UserId, Info);
        _ ->
            ?ok
    end.
record_boss_player(BossId, UserId, Info) ->
    VipData = Info#info.vip,
    #boss_player{boss_id = BossId, user_id = UserId, vip = VipData#vip.lv, 
                 user_name = Info#info.user_name, 
                 pro = Info#info.pro, sex = Info#info.sex, lv = Info#info.lv,
                 encourage = 0, reborn = ?CONST_SYS_FALSE, reborn_times = 0,
                 hurt = 0, hurt_tmp = 0, auto = ?CONST_SYS_TRUE, cd_death = 0,                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          
                 cd_exit = 0, exist = ?CONST_SYS_TRUE, achievement = ?CONST_SYS_FALSE,
                 hurt_reward = {0, 0, 0}}.

%% 心跳处理 -- 简单状态机
interval(BossId) ->
    BossId2 = get_boss_type(BossId),
	case ets:first(?CONST_ETS_BOSS_ROBOT_SETTING) of
		'$end_of_table' -> ?ok;
		Key	->
			interval_ext(Key, BossId2),
			interval_next(Key, BossId2)
	end.

interval_next(Key, BossId) ->
	case ets:next(?CONST_ETS_BOSS_ROBOT_SETTING, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			interval_ext(Key1, BossId),
			interval_next(Key1, BossId)
	end.

interval_ext(Key, BossId) ->
	case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, Key) of
		BossSetting when is_record(BossSetting, ets_boss_robot_setting) ->
			interval(BossSetting, BossId);
		_ ->
			?ok
	end.

interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_INIT, user_id = UserId, boss_id = BossId} = Setting, BossId) ->
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    Player = 
        case player_api:get_player_fields(UserId, [#player.info]) of
            {?ok, [Info]} ->
                #player{user_id = UserId, info = Info};
            _ ->
                ?null
        end,
    try
        case encourage(Setting, Player) of
            ?ok ->
                ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, 
                                   [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_ENC}]);
            _ ->
                ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.delay, 30},
                                                                                 {#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_INIT_AFTER}])
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end;
interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_ENC, user_id = UserId, boss_id = BossId} = Setting, BossId) ->
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    Player = 
        case player_api:get_player_fields(UserId, [#player.info]) of
            {?ok, [Info]} ->
                #player{user_id = UserId, info = Info};
            _ ->
                ?null
        end,
    try
        case encourage(Setting, Player) of
            ?ok ->
                ?ok;
            _ ->
                ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.delay, 30},
                                                                                 {#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_INIT_AFTER}])
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end;
interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_INIT_AFTER, user_id = UserId, delay = Delay, boss_id = BossId} = Setting, BossId) ->
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    Player = 
        case player_api:get_player_fields(UserId, [#player.info]) of
            {?ok, [Info]} ->
                #player{user_id = UserId, info = Info};
            _ ->
                ?null
        end,
    if
        Delay =< 0 ->
            case reborn(Setting, Player) of
                ?ok ->
                    ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_NORMAL}]),
                    ?ok;
                _ ->
                    ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_NORMAL}]),
                    ?ok
            end;
        ?true ->
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.delay, Delay-1}])
    end;
interval(Robot = #ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_NORMAL, user_id = UserId, map_pid = MapPid, boss_id = BossId}, BossId) ->        %% 正常状态
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    run_to_boss_site(MapPid, UserId),
	ets_api:insert(?CONST_ETS_BOSS_ROBOT_SETTING, Robot#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_MOVING, delay = 5}); 
interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_MOVING, user_id = UserId, map_pid = MapPid, delay = Delay, boss_id = BossId}, BossId) ->    %% 移动状态
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    Player = 
        case player_api:get_player_fields(UserId, [#player.info]) of
            {?ok, [Info]} ->
                #player{user_id = UserId, info = Info, user_state = ?CONST_PLAYER_STATE_NORMAL};
            _ ->
                ?null
        end,
    if
        Delay =< 0 ->
            try
                ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_FIGHTING}]),
                boss_api:start_battle(Player, ?CONST_SYS_TRUE, ?CONST_SYS_TRUE, ?true),
                map_api:change_user_state(#player{user_state = ?CONST_PLAYER_STATE_FIGHTING, map_pid = MapPid, user_id = UserId}, ?CONST_MAP_PTYPE_BOSS_ROBOT)
            catch
                X:Y ->
					ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId},
									   [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_MOVING}, {#ets_boss_robot_setting.delay, 5}]),
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
            end;
        ?true ->
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.delay, Delay-1}])
    end;
interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_DEATH, user_id = UserId, map_pid = MapPid, boss_id = BossId} = Setting, BossId) ->            %% 死亡状态
	?MSG_DEBUG("~n 555555555555555555555555555555", []),
    % 死亡->浴火->快速->等待->正常
    Now = misc:seconds(),
    case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
        #boss_player{cd_death = DeathSec} when DeathSec =< Now ->
			?MSG_DEBUG("~n 555555555555555555555555555555", []),
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_NORMAL}]),
            map_api:change_user_state(#player{user_state = ?CONST_PLAYER_STATE_NORMAL, map_pid = MapPid, user_id = UserId}, ?CONST_MAP_PTYPE_BOSS_ROBOT);
        #boss_player{cd_death = _DeathSec} ->
			?MSG_DEBUG("~n 555555555555555555555555555555", []),
            Player = 
                case player_api:get_player_fields(UserId, [#player.info]) of
                    {?ok, [Info]} ->
                        #player{user_id = UserId, info = Info};
                    _ ->
                        ?null
                end,
            case reborn(Setting, Player) of
                ?ok ->
					?MSG_DEBUG("~n 555555555555555555555555555555", []),
                    ?ok;
                _ ->
                    case quick_reborn(Setting, Player) of
                        ?ok ->
							?MSG_DEBUG("~n 555555555555555555555555555555", []),
                            ?ok;
                        _ ->
							?MSG_DEBUG("~n 555555555555555555555555555555", []),
                            ?ok
                    end
            end;
        _ ->
			?MSG_DEBUG("~n 555555555555555555555555555555", []),
            ?ok
    end;
interval(#ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_FIGHTING} = _Setting, _BossId) ->                                  %% 在战斗中
	?ok;
interval(_Setting, _BossId) ->
    ?ok.

%% 战斗中?
is_fighting(UserId, BossId) ->
    BossId2 = get_boss_type(BossId),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{state = ?CONST_BOSS_ROBOT_STATE_FIGHTING} ->
            ?true;
        _ ->
            ?false
    end.

%% 战斗结束后状态变化
battle_over(UserId, Result, RobotList) ->
    boss_api:battle_over_cb(#player{user_id = UserId}, [Result, RobotList]).

battle_over_robot(UserId, X, Y, BossId) ->
    BossId2 = get_boss_type(BossId),
%%     BossId2 = get_boss_type(10002),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{map_pid = MapPid} ->
            return_init_point(MapPid, UserId, X, Y),
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, [{#ets_boss_robot_setting.state, ?CONST_BOSS_ROBOT_STATE_DEATH}]),
            map_api:change_user_state(#player{user_state = ?CONST_PLAYER_STATE_DEATH, map_pid = MapPid, user_id = UserId}, ?CONST_MAP_PTYPE_BOSS_ROBOT);
        _ ->
            ?ok
    end.

save_all() ->
    L = ets:tab2list(?CONST_ETS_BOSS_ROBOT_SETTING),
    save_all(L),
    ok.

save_all([#ets_boss_robot_setting{cash = Cash, cash_used = CashUsed, 
                                  bcash_2 = BCash2, bcash_2_used = BCsah2Used, 
                                  user_id = UserId}|Tail]) ->
    Cash2 = 
        if
            CashUsed + BCsah2Used =< 0 ->
                Cash+BCash2;
            ?true ->
                Cash
        end,
    ReceiveName = player_api:get_name(UserId),
    mail_api:send_system_mail_to_one2(ReceiveName, <<"">>, <<"">>, ?CONST_MAIL_BOSS_ROBOT_REWARD_STO, 
                                              [], [], 0, 0, 0, ?CONST_COST_BOSS_ROBOT_REWARD),
    case player_api:check_online(UserId) of
        ?true ->
            player_money_api:plus_money(UserId, ?CONST_SYS_CASH, misc:max(Cash2-CashUsed, 0), ?CONST_COST_BOSS_ROBOT_RETURN),
            player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, misc:max(BCash2-BCsah2Used, 0), ?CONST_COST_BOSS_ROBOT_RETURN);
        _ ->
            player_offline_api:offline(?MODULE, UserId, {misc:max(Cash2-CashUsed, 0)})
    end,
    save_all(Tail);
save_all([]) ->
    ok.



%%
%% Local Functions
%% 鼓舞
encourage(_, ?null) ->
    {?error, ?TIP_COMMON_SYS_ERROR};
encourage(#ets_boss_robot_setting{key = Key, is_encourage = ?CONST_SYS_TRUE, cash = Cash, bcash_2 = BCash2, bcash_2_used = BCash2Used,
                                  cash_used = CashUsed, encounrage_state = Count}, Player) when Count < 10 ->
    try
        if
            Cash - CashUsed > 0 orelse BCash2 - BCash2Used > 0 ->
                boss_api:encourage(Player, ?true),
                ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, Key, [{#ets_boss_robot_setting.encounrage_state, Count + 1}]),
                ?ok;
            ?true ->
                ?false
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            ?error
    end;
encourage(_, _) ->
    ?false.

%% 浴火
reborn(_, ?null) ->
    {?error, ?TIP_COMMON_SYS_ERROR};
reborn(#ets_boss_robot_setting{is_reborn = ?CONST_SYS_TRUE, cash = Cash, bcash_2 = BCash2, bcash_2_used = BCash2Used,
                                  cash_used = CashUsed}, Player) ->
    if
        Cash - CashUsed > 0 orelse BCash2 - BCash2Used > 0 ->
            boss_api:reborn(Player, ?true);
        ?true ->
            ?false
    end;
reborn(_, _) ->
    ?false.

%% 加速复活
quick_reborn(_, ?null) ->
    {?error, ?TIP_COMMON_SYS_ERROR};
quick_reborn(#ets_boss_robot_setting{is_quick_reborn = ?CONST_SYS_TRUE, cash = Cash, bcash_2 = BCash2, bcash_2_used = BCash2Used,
                                  cash_used = CashUsed}, Player) ->
    if
        Cash - CashUsed > 0 orelse BCash2 - BCash2Used > 0 ->
            boss_api:revive(Player, ?true);
        ?true ->
            ?false
    end,
    ?ok;
quick_reborn(_, _) ->
    ?false.

change_robot_state(UserId, State, BossId) ->
    BossId2 = get_boss_type(BossId),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{map_pid = MapPid} ->
            RobotState = get_robot_state(State),
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, [{#ets_boss_robot_setting.state, RobotState}]),
            map_api:change_user_state(#player{user_state = State, map_pid = MapPid, user_id = UserId}, ?CONST_MAP_PTYPE_BOSS_ROBOT);
        _ ->
            ?ok
    end.

get_robot_state(?CONST_PLAYER_STATE_DEATH)    -> ?CONST_BOSS_ROBOT_STATE_DEATH;
get_robot_state(?CONST_PLAYER_STATE_FIGHTING) -> ?CONST_BOSS_ROBOT_STATE_FIGHTING;
get_robot_state(?CONST_PLAYER_STATE_NORMAL)   -> ?CONST_BOSS_ROBOT_STATE_NORMAL.

%% 走到boss前
run_to_boss_site(MapPid, UserId) ->
    X = 2000,
    Y = 600,
    Rx = 200,
    Ry = 50,
    X2 = misc_random:random(X-Rx, X+Rx),
    Y2 = misc_random:random(Y-Ry, Y+Ry),
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} when is_record(Player, player) ->
%% 			Player1			= Player#player{map_pid = MapPid},
    		map_api:move_robot(Player#player{user_id = UserId, map_pid = MapPid}, UserId, X2, Y2, ?CONST_MAP_PTYPE_BOSS_ROBOT);
		_ ->
			?ok
	end.

%% 回出生点
return_init_point(MapPid, UserId, X, Y) ->
    Rx = 100,
    Ry = 50,
    X2 = misc_random:random(X-Rx, X+Rx),
    Y2 = misc_random:random(Y-Ry, Y+Ry),
    map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, X2, Y2, ?CONST_SYS_TRUE).

%% 加钱
plus_money(UserId, Money, Point, BossId) ->
    BossId2 = get_boss_type(BossId),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{cash = Cash, cash_used = CashUsed} ->
            admin_log_api:log_robot(UserId, BossId2, Money, Point, Cash - CashUsed + Money),
            ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, 
                               [{#ets_boss_robot_setting.cash_used, misc:max(CashUsed - Money, Cash)}]);
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

%% 按顺序扣delta,v1->v2
%% {V1_remine, V2_remine, V1_delta, V2_delta}/error
cost_first(Delta, V1, V2) when V1 >= Delta -> 
    {V1 - Delta, V2, Delta, 0};
cost_first(Delta, V1, V2) when V1 + V2 >= Delta -> 
    {0, V1 + V2 - Delta, V1, Delta - V1};
cost_first(Delta, V1, V2) when V1 + V2 < Delta -> 
    ?error.

%% 扣钱
cost_money(UserId, Money, Point, BossId) ->
    BossId2 = get_boss_type(BossId),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{cash = Cash, cash_used = CashUsed, bcash_2 = BCash2, bcash_2_used = BCash2Used} ->
            case cost_first(Money, BCash2-BCash2Used, Cash-CashUsed) of
                {BCash2Remine, CashRemine, BCash2Delta, CashDelta} when CashRemine >= 0 orelse BCash2Remine >=0 ->
                    admin_log_api:log_robot(UserId, BossId2, BCash2Delta, Point, BCash2Remine, ?CONST_SYS_CASH_BIND_2),
                    admin_log_api:log_robot(UserId, BossId2, CashDelta, Point, CashRemine, ?CONST_SYS_CASH),
                    ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, 
                                       [{#ets_boss_robot_setting.cash_used, CashUsed+CashDelta},
                                        {#ets_boss_robot_setting.bcash_2_used, BCash2Used+BCash2Delta}]),
                    player_money_api:handle_minus(UserId, Point, Money),
                    ?ok;
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

%% 扣钱
check_money(UserId, Money, BossId) ->
    BossId2 = get_boss_type(BossId),
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
        #ets_boss_robot_setting{cash = Cash, cash_used = CashUsed, bcash_2 = BCash2, bcash_2_used = BCash2Used} ->
            case cost_first(Money, BCash2-BCash2Used, Cash-CashUsed) of
                {BCash2Remine, CashRemine, _BCashDelta, _CashDelta} when CashRemine + BCash2Remine >=0 ->
                    ?ok;
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.
    
get_boss_type(?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS) -> ?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS;
get_boss_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS) -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS;
get_boss_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2) -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS;
get_boss_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3) -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS.


    