%% Author: Administrator
%% Created: 2013-12-12
%% Description: TODO: Add description to robot_world_api
-module(robot_world_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.map.hrl").
-include("record.robot.hrl").
%%
%% Exported Functions
%%
-export([enter/1, exit/0, move/0, battle_over/3, send_reward/5, leave_guild/1]).
-export([set_world_doll/3, init_robot_enter_world/0, update_robot_state/2, auto_info/1]).
-export([get_world_robot_list/0, refresh_monster_cb/2, init_ets_world_robot/0, logout/1]).
-export([refresh/0, login/1]).

%%
%% API Functions
%%
init_robot_enter_world() ->
	Time			= misc:seconds(),
	case world_api:get_world_base() of
		#world_base{time_start = StartTime} when StartTime + 1 =:= Time -> 
			RobotList			= get_world_robot_list(),
%% 			RobotList			= [19],
			F		= fun(UserId) ->
							  case player_api:get_player_first(UserId) of
								  {?ok, Player, _} ->
%% 									  robot_world_api:set_world_doll(Player, 1),
									  robot_world_api:enter(Player);
								  _ -> ?ok
							  end
					  end,
			lists:foreach(F, RobotList);
		_ -> ?ok
	end.


enter(Player) ->
	UserId				= Player#player.user_id,
	case check_robot_enter_world(Player) of
		{?ok, WorldBase, WorldData, WorldPlayer} ->
			admin_log_api:log_campaign(Player#player.user_id, Player#player.account, (Player#player.info)#info.lv, ?CONST_ACTIVE_WORLD, misc:seconds()),
			?true		= world_api:set_world_player(WorldPlayer),
			
			MapId		= WorldBase#world_base.map_id,
			GuildId		= WorldData#world_data.guild_id,
			
			map_api:enter_map_robot(Player#player.user_id, WorldBase#world_base.map_id, WorldData#world_data.guild_id, ?CONST_MAP_PTYPE_WORLD_ROBOT),
			?MSG_DEBUG("2222222222222222222222222 GuildId=~p", [WorldData#world_data.guild_id]),
			{_, MapPid} = map_api:get_map_pid(?CONST_MAP_TYPE_WORLD, MapId, #map_param{ad1=MapId, ad2 = GuildId}),
			Packet45140	= world_api:msg_sc_update_hurt(WorldPlayer#world_player.hurt),
			Packet45342	= world_api:msg_sc_buff_info(WorldData),
			Packet		= <<Packet45140/binary, Packet45342/binary>>,
			misc_packet:send(Player#player.net_pid, Packet),
			
			schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_WORLD),
			schedule_api:add_guide_times(UserId, ?CONST_SCHEDULE_GUIDE_WORLD),
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_GUILD_SIEGE, 0, 1),
            player_money_api:handle_minus(UserId, ?CONST_COST_WORLD_SET_ROBOT, ?CONST_WORLD_AUTO_COST),
			
			case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
				?null -> ?ok;
				Robot ->
					RobotDate		= Robot#ets_world_robot{map_pid = MapPid},
					ets_api:insert(?CONST_ETS_WORLD_ROBOT, RobotDate)
			end,
			move_to_moster(MapPid, UserId),
			{?ok, Player};
		{?error, _ErrorCode} ->
			{?ok, Player}
	end.
	
check_robot_enter_world(Player) ->
	try
		{?ok, WorldBase}= world_api:check_world_open(),
		{?ok, GuildId}	= world_api:check_guild(Player),
		WorldPlayer		= world_api:init_world_player(Player, GuildId),
		case world_api:get_pid(GuildId) of
			{?ok, _Pid} ->
				WorldData	= world_api:get_world_data(GuildId),
				{?ok, WorldBase, WorldData, WorldPlayer};
			{?error, ErrorCode} ->
				{?error, ErrorCode}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 定时移动战斗
move() ->
	try
		?ok						= world_api:check_world_start(misc:seconds()),
		RobotList			= get_world_robot_list(),
%% 		RobotList				= [19],
		F		= fun(UserId) ->
						  case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
							  ?null -> ?ok;
							  Robot ->
								  State			= Robot#ets_world_robot.state,
								  DeathTime		= Robot#ets_world_robot.death_time,
								  move_ext(UserId, State, DeathTime, Robot)
								 
						  end
				  end,
		lists:foreach(F, RobotList)
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.


move_ext(UserId, 2, DeathTime, Robot) ->
	Time		= misc:seconds(),
	case DeathTime + ?CONST_WORLD_CD_REBORN > Time of
		?true  -> 
			WorldBase			= world_api:get_world_base(),
			MapPid				= Robot#ets_world_robot.map_pid,
			map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, {WorldBase#world_base.x, WorldBase#world_base.y}, 1);
%% 			map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, WorldBase#world_base.x, WorldBase#world_base.y);
		?false -> move_ext(UserId, 0, DeathTime, Robot)
	end;
move_ext(UserId, 0, _DeathTime, Robot) -> 
	MapPid		= Robot#ets_world_robot.map_pid,
	case MapPid == 0 of
		?true  -> ?ok;
		?false ->
			move_to_moster(MapPid, UserId),
			start_battle(UserId)
	end;
move_ext(_UserId, 1, _DeathTime, _Robot) ->  ?ok.
%% 	WorldBase			= world_api:get_world_base(),
%% 	MapPid				= Robot#ets_world_robot.map_pid,
%% 	map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, WorldBase#world_base.x, WorldBase#world_base.y).


%% 直接移动到怪物处
move_to_moster(MapPid, UserId) ->
    X 	= 830,
    Y 	= 600,
    Rx 	= 200,
    Ry 	= 50,
    X2 = misc_random:random(X-Rx, X+Rx),
    Y2 = misc_random:random(Y-Ry, Y+Ry),
%%     map_api:move_robot(#player{user_id = UserId, map_pid = MapPid}, UserId, X2, Y2, ?CONST_MAP_PTYPE_WORLD_ROBOT).
	map_api:change_user_state(#player{user_id = UserId, user_state = ?CONST_PLAYER_STATE_NORMAL, 
									 practice_state = 0, map_pid = MapPid}, ?CONST_MAP_PTYPE_WORLD_ROBOT),
    map_api:move_robot(#player{user_id = UserId, map_pid = MapPid}, UserId, X2, Y2, ?CONST_MAP_PTYPE_WORLD_ROBOT).

%% 活动结束
exit() ->
	RobotList			= get_world_robot_list(),
%% 	RobotList			= [19],
	F = fun(UserId) ->
				case ets_api:lookup(ets_world_robot, UserId) of
					?null 	  -> ?ok;
					RobotData ->
						MapPid 		= RobotData#ets_world_robot.map_pid,
		 				map_api:exit_map(#player{user_id = UserId, map_pid = MapPid})
				end
		end,
	lists:foreach(F, RobotList).

%% 开始战斗
start_battle(UserId) ->
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} when is_record(Player, player) ->
			WorldBase			= world_api:get_world_base(),
			X					= WorldBase#world_base.x,
			Y					= WorldBase#world_base.y,
			?MSG_DEBUG("333333333333333333333333333333333333333333333333", []),
			case check_battle_start(Player) of
				{?ok, WorldData, _WorldPlayer, WorldMonster} ->
					?MSG_DEBUG("333333333333333333333333333333333333333333333333", []),
					Buff		= case WorldData#world_data.buff of [#world_buff{buff = BuffTemp}|_] -> BuffTemp; _ -> [] end,
					Param		= #param{battle_type	= ?CONST_BATTLE_WORLD,
										 attr 			= Buff,
										 ad1			= WorldData#world_data.step,
										 ad2 			= WorldMonster#world_monster.id,
										 ad3 			= WorldMonster#world_monster.hp_tuple,
										 ad4 			= 1,
										 robot			= [UserId]},
					case battle_api:start(Player, WorldMonster#world_monster.monster_id, Param) of
						{?ok, Player2} ->
							case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
								?null -> {?ok, Player2};
								Robot -> 
									MapPid		= Robot#ets_world_robot.map_pid,
									map_api:change_user_state(#player{user_id = UserId, user_state = ?CONST_PLAYER_STATE_FIGHTING, 
																	  practice_state = 0, map_pid = MapPid}, ?CONST_MAP_PTYPE_WORLD_ROBOT),
									?MSG_DEBUG("333333333333333333333333333333333333333333333333", []),
									update_robot_state(UserId, 1),
									{?ok, Player2}
							end;
						{?error, _ErrorCode} -> 
							case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
								?null -> {?ok, Player};
								Robot -> 
									MapPid		= Robot#ets_world_robot.map_pid,
									map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, {X, Y}, 1),
									{?ok, Player}
							end
					end;
				{?error, _ErrorCode} -> 
					case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
						?null -> {?ok, Player};
						Robot -> 
							MapPid		= Robot#ets_world_robot.map_pid,
							map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, {X, Y}, 1),
							{?ok, Player}
					end
			end;
		_ -> ?ok
	end.

check_battle_start(Player) ->
	Seconds			= misc:seconds(),
	try
		?ok					= world_api:check_world_start(Seconds),
		{?ok, WorldPlayer}	= world_api:check_world_player(Player#player.user_id),
		?ok					= world_api:check_cd_death(Seconds, WorldPlayer#world_player.cd_death),
		case world_api:get_world_data(WorldPlayer#world_player.belong) of
			WorldData when is_record(WorldData, world_data) ->
				?MSG_DEBUG("4444444444444444444444444444444444444444", []),
				{?ok, WorldMonster}	= get_battle_moster(WorldData),
				?MSG_DEBUG("5555555555555555555555555555555555555555", []),
				{?ok, WorldData, WorldPlayer, WorldMonster};
			_ -> 
				{?error, ?TIP_COMMON_SYS_ERROR}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

get_battle_moster(WorldData) ->
	WorldMonsters	= WorldData#world_data.monsters,
	MosterList		= WorldMonsters#world_monsters.monsters,
	get_battle_monster(MosterList, WorldData).

get_battle_monster([], _WorldData) -> throw({?error, ?TIP_WORLD_MONSTER_DEATH});
get_battle_monster([Monster|Tail], WorldData) ->
	?MSG_DEBUG("Monster=~p", [Monster]),
	Id				= Monster#world_monster.id,
	Step			= WorldData#world_data.step,
	?MSG_DEBUG("6666666666666666666666666666666", []),
	case world_api:get_world_monster(WorldData, Step, Id) of
		{?ok, WorldMonster} ->
			if
				WorldMonster#world_monster.death =:= ?false ->
					{?ok, WorldMonster};
				?true ->
					get_battle_monster(Tail, WorldData)
			end;
		_ -> 
			get_battle_monster(Tail, WorldData)
	end.
	
	
update_robot_state(UserId, 2) ->
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		?null -> ?ok;
		Robot ->
			Now				= misc:seconds(),
			NewRobot		= Robot#ets_world_robot{state = 2, death_time = Now},
			ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot)
	end;
update_robot_state(UserId, State) ->
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		?null -> ?ok;
		Robot ->
			NewRobot		= Robot#ets_world_robot{state = State},
			ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot)
	end.


battle_over(Player, _WorldPlayer, Result) ->
	UserId		= Player#player.user_id,
	WorldBase	= world_api:get_world_base(),
	State		= case Result of
					  ?CONST_BATTLE_RESULT_LEFT ->
						  case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
							  ?null -> ?ok;
							  Robot ->
								  MapPid	= Robot#ets_world_robot.map_pid,
								  map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, {WorldBase#world_base.x, WorldBase#world_base.y}, 1)
						  end,
						  0;
					  ?CONST_BATTLE_RESULT_RIGHT ->
%% 						  Datas	=[{#world_player.cd_death, Time + ?CONST_WORLD_CD_REBORN}],
%% 						  ets_api:update_element(?CONST_ETS_WORLD_PLAYER, UserId, Datas),
						  update_robot_state(UserId, 2),
						   case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
							  ?null -> ?ok;
							  Robot ->
								  MapPid	= Robot#ets_world_robot.map_pid,
								  map_api:teleport(#player{user_id = UserId, map_pid = MapPid}, {WorldBase#world_base.x, WorldBase#world_base.y}, 1),
								  map_api:change_user_state(#player{user_id = UserId, user_state = ?CONST_PLAYER_STATE_DEATH, 
																	 practice_state = 0, map_pid = MapPid}, ?CONST_MAP_PTYPE_WORLD_ROBOT)
						  end,
						 
						  2
				  end,
	update_robot_state(UserId, State),
	{?ok, Player}.

%%--------------------------------------------------------------------------------------------------------
%% 结束奖励
%%--------------------------------------------------------------------------------------------------------
send_reward(UserId, Gold, Exploit, Hurt, KillCount) ->
	admin_log_api:log_world(UserId, Hurt, KillCount, Exploit, Gold, 1),
	UserName			= player_api:get_name(UserId),
	Content1			= [{[{misc:to_list(Exploit)}]}] ++ [{[{misc:to_list(Gold)}]}],
	mail_api:send_system_mail_to_one(UserName, "", "", 1954, Content1, [], 0, 0, 0, 0),
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		Robot when is_record(Robot, ets_world_robot) ->
			NewRobot	= Robot#ets_world_robot{death_time = 0, state = 0, map_pid = 0, auto1 = 0},
			ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot);
		_ -> ?ok
	end.

%% 刷新伤害
refresh_monster_cb(UserId, {Step, Id, HurtTuple}) ->
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} when is_record(Player, player) ->
			world_api:refresh_monster_cb(Player, {Step, Id, HurtTuple});
		_ -> ?ok
	end.
%%--------------------------------------------------------------------------------------------------------
%% 设置自动进入
%%--------------------------------------------------------------------------------------------------------
set_world_doll(Player, Type, 0) ->                               %% 取消替身参战   
	UserId			= Player#player.user_id,
	VipLv			= player_api:get_vip_lv(Player),
	try
		 ?ok				= check_vip(VipLv),
		 {?ok, _GuildId}	= world_api:check_guild(Player),
		 ?MSG_DEBUG("1111111111111111111111111111111", []),
		 Robot				= get_ets_world_doll(UserId),
		 ?MSG_DEBUG("1111111111111111111111111111111", []),
		 ?ok				= check_cancel_doll(Type, Robot),
%% 		 Value				= ?CONST_WORLD_AUTO_COST,
		 {?ok, Robot1}		= cancel_add_money(UserId, Robot, Type),
%% 		 player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_CANCEL_ROBOT),
		 NewRobot			= case Type of
								  0 -> Robot1#ets_world_robot{user_id = UserId, auto1 = 0};
								  1 -> Robot1#ets_world_robot{user_id = UserId, auto2 = 0}
							  end,
		 ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),      
		 update_world_doll(NewRobot),
		 List			= [{0, NewRobot#ets_world_robot.auto1}, {1, NewRobot#ets_world_robot.auto2}],
		 Packet			= world_api:msg_sc_world_robot([List]),
		 TipPacket		= message_api:msg_notice(?TIP_WORLD_CANCEL_SUCCESS, [{?TIP_SYS_COMM, misc:to_list(?CONST_WORLD_AUTO_COST)}]),
		 misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>)
	catch
		throw:{?error, ErrorCode} ->
			ErrPacket			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, ErrPacket),
			{?error, ErrorCode};
		Other:Reason ->
			?MSG_ERROR("Other:~p Reason:~p, Strace:~p~n", [Other, Reason, erlang:get_stacktrace()])
	end;  
set_world_doll(Player, Type, 1) ->                               %% 勾选替身参战           
	UserId			= Player#player.user_id,
	VipLv			= player_api:get_vip_lv(Player),
	try
		 ?ok				= check_vip(VipLv),
		 {?ok, _GuildId}	= world_api:check_guild(Player),
		  ?MSG_DEBUG("1111111111111111111111111111111", []),
		 Robot				= get_ets_world_doll(UserId),
		 ?ok				= check_world_active_open(Type),
		 {?ok, NewRobot}		= check_money(UserId, Robot, Type),
%% 		 NewRobot			= case Type of
%% 								  0 -> Robot1#ets_world_robot{user_id = UserId, auto1 = 1};
%% 								  1 -> Robot1#ets_world_robot{user_id = UserId, auto2 = 1}
%% 							  end,
		 ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),                                     
		 update_world_doll(NewRobot),
		 List			= [{0, NewRobot#ets_world_robot.auto1}, {1, NewRobot#ets_world_robot.auto2}],
		 Packet			= world_api:msg_sc_world_robot([List]),
		 TipPacket		= message_api:msg_notice(?TIP_WORLD_SET_SUCCESS, [{?TIP_SYS_COMM, misc:to_list(?CONST_WORLD_AUTO_COST)}]),
		 misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>)
	catch
		throw:{?error, ErrorCode} ->
			ErrPacket			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, ErrPacket),
			{?error, ErrorCode};
		Other:Reason ->
			?MSG_ERROR("Other:~p Reason:~p, Strace:~p~n", [Other, Reason, erlang:get_stacktrace()])
	end.

%% 检查vip等级
check_vip(VipLv) ->
	VipLv1		= player_vip_api:get_world_auto_flag(VipLv),
	if
		VipLv >= VipLv1 -> ?ok;
		?true -> throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH})
	end.

%% 获取ets数据
get_ets_world_doll(UserId) ->
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		Robot when is_record(Robot, ets_world_robot) -> Robot;
		_ -> throw({?error, ?TIP_COMMON_BAD_ARG})
	end.

%% 检查活动时间
check_world_active_open(0) -> 
	{Hour, Min, _Sec}= misc:time(),
	ActiveDate		= data_active:get_active(world),
	[Hour1]			= ActiveDate#rec_active.hour_b,
	[Min1]			= ActiveDate#rec_active.min_b,
	case Hour < Hour1 of
		?true  -> ?ok;
		?false ->
			case Min < Min1 of
				?true  -> ?ok;
				?false -> 
					case active_api:is_opened(?CONST_ACTIVE_WORLD) of
						?CONST_SYS_TRUE  -> throw({?error, ?TIP_WORLD_ACTIVE_OPEN});
						?CONST_SYS_FALSE -> throw({?error, ?TIP_WORLD_NOT_CANCEL1})
					end
			end
	end;
check_world_active_open(1) -> ?ok.
	
%% 检查取消
check_cancel_doll(0, Robot) ->
	State			= Robot#ets_world_robot.auto1,
	{Hour, Min, _Sec}= misc:time(),
	ActiveDate		= data_active:get_active(world),
	[Hour1]			= ActiveDate#rec_active.hour_b,
	[Min1]			= ActiveDate#rec_active.min_b,
	case State of
		1 ->
			case Hour < Hour1 of
				?true  -> ?ok;
				?false ->
					case Min < Min1 of
						?true  -> ?ok;
						?false -> throw({?error, ?TIP_WORLD_NOT_CANCEL1})
					end
			end;
		0 -> 
			throw({?error, ?TIP_WORLD_NOT_CANCEL})
	end;
check_cancel_doll(1, Robot) ->
	State			= Robot#ets_world_robot.auto2,
	case State of
		1 -> ?ok;
		0 -> throw({?error, ?TIP_WORLD_NOT_CANCEL})
	end.

%% 替身扣钱
check_money(UserId, Robot, 0) -> 
	Value				= ?CONST_WORLD_AUTO_COST,
	case player_money_api:minus_money_sp(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_SET_ROBOT) of
		{_Value, CashBind, Cash} -> 
			NewRobot		= Robot#ets_world_robot{user_id=UserId, cash_bind1 = CashBind, cash1 = Cash, auto1 = 1},
%% 			ets_api:insert(?CONST_ETS_WORLD_ROBOT, Robot#ets_world_robot{cash_bind = CashBind, cash = Cash}),
			{?ok, NewRobot};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
check_money(UserId, Robot, 1) -> 
	Value				= ?CONST_WORLD_AUTO_COST,
	case player_money_api:minus_money_sp(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_SET_ROBOT) of
		{_Value, CashBind, Cash} -> 
			NewRobot		= Robot#ets_world_robot{user_id=UserId, cash_bind2 = CashBind, cash2 = Cash, auto2 = 1},
%% 			ets_api:insert(?CONST_ETS_WORLD_ROBOT, Robot#ets_world_robot{cash_bind = CashBind, cash = Cash}),
			{?ok, NewRobot};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 取消返还处理
cancel_add_money(UserId, Robot, 0) ->
	CashBind		= Robot#ets_world_robot.cash_bind1,
	Cash			= Robot#ets_world_robot.cash1,
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_WORLD_CANCEL_ROBOT),
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, CashBind, ?CONST_COST_WORLD_CANCEL_ROBOT),
	{?ok, Robot#ets_world_robot{cash1 = 0, cash_bind1 = 0, auto1 = 0}};
cancel_add_money(UserId, Robot, 1) ->
	CashBind		= Robot#ets_world_robot.cash_bind2,
	Cash			= Robot#ets_world_robot.cash2,
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_WORLD_CANCEL_ROBOT),
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, CashBind, ?CONST_COST_WORLD_CANCEL_ROBOT),
	{?ok, Robot#ets_world_robot{cash2 = 0, cash_bind2 = 0, auto2 = 0}}.




%%　下线处理
logout(Player) ->
	UserId			= Player#player.user_id,
	Date			= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		Robot when is_record(Robot, ets_world_robot) ->
			mysql_api:fetch_cast(<<"REPLACE INTO `game_world_doll` ",
								   "( `user_id` ,`today` , `date`, `tomorrow`, `cash_today`, `bcash_2_today`, `cash_tomorrow`, `bcash_2_tomorrow`)",
								   " VALUES ('", 	(misc:to_binary(UserId))/binary,"','",  			% UserId
								   (misc:to_binary(Robot#ets_world_robot.auto1))/binary,"','",  		% today
								   (misc:to_binary(Date))/binary,"','",  								% date
								   (misc:to_binary(Robot#ets_world_robot.auto2))/binary,"','",  		
								   (misc:to_binary(Robot#ets_world_robot.cash1))/binary,"','",  								
								   (misc:to_binary(Robot#ets_world_robot.cash_bind1))/binary,"','",  								
								   (misc:to_binary(Robot#ets_world_robot.cash2))/binary,"','",  								
								   (misc:to_binary(Robot#ets_world_robot.cash_bind2))/binary, 				        						
								   "'); " >>);
		_ -> ?ok
	end.

%% 零点处理
refresh() ->
	case ets:first(?CONST_ETS_WORLD_ROBOT) of
		'$end_of_table' -> ?ok;
		Key	->
			refresh_ext(Key),
			refresh(Key)
	end.

refresh(Key) ->
	case ets:next(?CONST_ETS_WORLD_ROBOT, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			refresh_ext(Key1),
			refresh(Key1)
	end.

refresh_ext(Key) ->
	Date		= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, Key) of
		Robot when is_record(Robot, ets_world_robot) ->
			Torommow		= Robot#ets_world_robot.auto2,
			NewRobot		= Robot#ets_world_robot{auto1 = Torommow, auto2 = 0, date = Date},
			ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot);
		_ -> ?ok
	end.

%% 上线处理
login(Player) ->
	UserId			= Player#player.user_id,
	NowDate			= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		Robot when is_record(Robot, ets_world_robot) ->
			OldDate		= Robot#ets_world_robot.date,
			case OldDate of
				NowDate -> Player;
				_ -> 
					Time			= misc:date_to_seconds(NowDate),
					RealSeconds		= Time - 2 * 24 * 3600,
					RealDate		= misc:seconds_to_date_num(RealSeconds),
					Torommow		= Robot#ets_world_robot.auto2,
					NewRobot		= case RealDate of
										  OldDate ->Robot#ets_world_robot{auto1 = 0, auto2 = 0, date = NowDate};
										  _ ->Robot#ets_world_robot{auto1 = Torommow, auto2 = 0, date = NowDate}
									  end,
					ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
					Player
			end;
		_ -> Player
	end.

%%--------------------------------------------------------------------------------------------------------
%% 退出/离开军团处理
%%--------------------------------------------------------------------------------------------------------
leave_guild(UserId) ->
	case active_api:is_opened(?CONST_ACTIVE_WORLD) of
		?CONST_SYS_TRUE  ->
			ReceiveName			= player_api:get_name(UserId),
			case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
				Robot when is_record(Robot, ets_world_robot) ->
					Auto2		= Robot#ets_world_robot.auto2,
					Value		= Auto2 * ?CONST_WORLD_AUTO_COST,
					case Auto2	of
						0 -> ?ok;
						_ ->
							{?ok, Robot1}	= cancel_add_money(UserId, Robot, 1),
							NewRobot		= Robot1#ets_world_robot{auto1 = 0, auto2 = 0, cash1 = 0, cash2 = 0,
																	 cash_bind1 = 0, cash_bind2 = 0},
							Content1		= [{[{misc:to_list(Value)}]}],
							mail_api:send_system_mail_to_one(ReceiveName, "", "", 1955, Content1, [], 0, 0, 0, 0),
							ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
							delete_robot(UserId)
					end;
%% 					case Value of
%% 						0 -> ?ok;
%% 						_ ->
%% 							player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_LEAVE_GUILD),
%% 							Content1	= [{[{misc:to_list(Value)}]}],
%% 							mail_api:send_system_mail_to_one(ReceiveName, "", "", 1955, Content1, [], 0, 0, 0, 0)
%% 					end,
%% 					NewRobot	= Robot#ets_world_robot{auto1 = 0, auto2 = 0},
%% 					ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
%% 					delete_robot(UserId);
				_ -> ?ok
			end;
		?CONST_SYS_FALSE ->
			ReceiveName			= player_api:get_name(UserId),
			case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
				Robot when is_record(Robot, ets_world_robot) ->
					Auto1		= Robot#ets_world_robot.auto1,
					Auto2		= Robot#ets_world_robot.auto2,
					Value		= (Auto1+Auto2)*?CONST_WORLD_AUTO_COST,
					case Auto1 of
						0 -> ?ok;
						_ -> cancel_add_money(UserId, Robot, 0)
					end,
					case Auto2 of
						0 -> ?ok;
						_ -> cancel_add_money(UserId, Robot, 1)
					end,
%% 					player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_LEAVE_GUILD),
					case Value of
						0 -> ?ok;
						_ ->
							Content1	= [{[{misc:to_list(Value)}]}],
							mail_api:send_system_mail_to_one(ReceiveName, "", "", 1955, Content1, [], 0, 0, 0, 0)
					end,
					NewRobot	= Robot#ets_world_robot{auto1 = 0, auto2 = 0, cash1 = 0, cash2 =0, cash_bind1 = 0, cash_bind2 = 0},
					ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
					delete_robot(UserId);
%% 							NewRobot		= Robot1#ets_world_robot{auto1 = 0, auto2 = 0},
%% 							Content1		= [{[{misc:to_list(Value)}]}],
%% 							mail_api:send_system_mail_to_one(ReceiveName, "", "", 1955, Content1, [], 0, 0, 0, 0),
%% 							ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
%% 							delete_robot(UserId)
%% 							
%% 					case Value of
%% 						0 -> ?ok;
%% 						_ ->
%% 							player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_WORLD_LEAVE_GUILD),
%% 							Content1	= [{[{misc:to_list(Value)}]}],
%% 							mail_api:send_system_mail_to_one(ReceiveName, "", "", 1955, Content1, [], 0, 0, 0, 0)
%% 					end,
%% 					NewRobot	= Robot#ets_world_robot{auto1 = 0, auto2 = 0},
%% 					ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
%% 					delete_robot(UserId);
				_ -> ?ok
			end
	end.

%%
%% Local Functions
%%
%% 初始化替身ets
init_ets_world_robot() ->
	NowDate			= misc:date_num(),
	ets:delete_all_objects(?CONST_ETS_WORLD_ROBOT),
	FieldList = [user_id, today, tomorrow, date, cash_today, bcash_2_today, cash_tomorrow, bcash_2_tomorrow],
	case mysql_api:select(FieldList, game_world_doll) of
		{?ok, RobotList} ->
			F = fun([UserId, Today, Tomorrow, OldDate, Cash1, Bcash1, Cash2, Bcash2], Acc) ->
						case NowDate of
							OldDate -> 
								[#ets_world_robot{user_id = UserId, auto1 = Today, auto2 = Tomorrow, date = NowDate, 
												  cash1 = Cash1, cash_bind1 = Bcash1, cash2 = Cash2, cash_bind2 = Bcash2}|Acc];
							_ -> 
								[#ets_world_robot{user_id = UserId, auto1 = Tomorrow, auto2 = 0, date = NowDate,
												  cash1 = Cash1, cash_bind1 = Bcash1, cash2 = Cash2, cash_bind2 = Bcash2}|Acc]
						end
				end,
			List = lists:foldl(F, [], RobotList),
			ets_insert_list(?CONST_ETS_WORLD_ROBOT, List);
		{?error, _ErrorCode} ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

ets_insert_list(Tab, [WorldRobot|Tail]) ->
	ets_api:insert(Tab, WorldRobot),
	ets_insert_list(Tab, Tail);
ets_insert_list(_Tab, []) ->           
	?ok.

%% 获取机器人列表
get_world_robot_list() -> 
	List			= ets_api:list(?CONST_ETS_WORLD_ROBOT),
	get_world_robot_list1(List, []).

get_world_robot_list1([], Acc) -> Acc;
get_world_robot_list1([Robot|Tail], Acc) ->
	case Robot#ets_world_robot.auto1 of
		1 -> 
			NewAcc			= [Robot#ets_world_robot.user_id|Acc],
			get_world_robot_list1(Tail, NewAcc);
		0 ->
			get_world_robot_list1(Tail, Acc)
	end.
%% 替身勾选信息
auto_info(UserId) ->
	case ets_api:lookup(?CONST_ETS_WORLD_ROBOT, UserId) of
		Robot when is_record(Robot, ets_world_robot) ->
			List			= [{0, Robot#ets_world_robot.auto1}, {1, Robot#ets_world_robot.auto2}],
			world_api:msg_sc_world_robot([List]);
		_ ->
			NewRobot		= #ets_world_robot{user_id = UserId, auto1 = 0, auto2 = 0, date = misc:date_num(), state = 0},
			ets_api:insert(?CONST_ETS_WORLD_ROBOT, NewRobot),
			world_api:msg_sc_world_robot([[]])
	end.
%% 更新数据库
update_world_doll(NewRobot) ->
		UserId				= NewRobot#ets_world_robot.user_id,
		Today				= NewRobot#ets_world_robot.auto1,
		Tomorrow			= NewRobot#ets_world_robot.auto2,
		Date				= misc:date_num(),
		Cash1				= NewRobot#ets_world_robot.cash1,
		BindCash1			= NewRobot#ets_world_robot.cash_bind1,
		Cash2				= NewRobot#ets_world_robot.cash2,
		BindCash2			= NewRobot#ets_world_robot.cash_bind2,
		mysql_api:update(game_world_doll, 
						  				[
										 {today,			Today},
										 {tomorrow,         Tomorrow},
										 {date,				Date},
										 {cash_today,       Cash1},
										 {bcash_2_today,    BindCash1},
										 {cash_tomorrow,    Cash2},
										 {bcash_2_tomorrow, BindCash2}
						   				 ],
						  				[{user_id, UserId}]).

%% 删除数据库和ets数据
delete_robot(UserId) ->
	mysql_api:delete(game_world_doll, "user_id="++misc:to_list(UserId)).
%% 
%% test(UserId) ->
%% 	Player	= player_api:get_user_info_by_id(UserId),
%% 	?MSG_DEBUG("~p", [Player#player.map_pid]),
%% 	map_api:change_user_state(Player, ?CONST_MAP_PTYPE_WORLD_ROBOT),
%% 	map_api:move_robot(Player, 19, 1977, 623, ?CONST_MAP_PTYPE_WORLD_ROBOT).
