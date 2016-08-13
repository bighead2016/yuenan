%% Author: Administrator
%% Created: 2012-10-17
%% Description: TODO: Add description to boss_api
-module(boss_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
-include("record.map.hrl").
-include("record.battle.hrl").
-include("record.robot.hrl").

-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([
		 on/1, off/1,boss_interval/0,
		 boss_interval/1, get_open_boss/0,
		 logout/1, get_boss_doll_info/1, boss_doll/3, quit/1, auto/2, 
         encourage/2, reborn/2, login_packet/2,
		 refresh_monster/3,
		 battle_over/3, battle_over_cb/2, revive/2, auto_revive/1, hire_doll/6, 
		 get_active_type/1
		]).
-export([
		 reward_doll/2, reward_doll_cb/2, reward_cross_doll_ext/3, notice_active_end/3,
		 reward_last/5, reward_rank/3, reward_rank_cb/2, get_reward_hurt/2, flush_offline/2 
		]).
-export([
		 msg_sc_enter/3, msg_sc_monster_info/3, msg_sc_quit_ok/0, msg_sc_state/1,
		 msg_sc_auto/1, msg_sc_encourage/1, msg_sc_reborn/1, msg_sc_revive/0, msg_sc_reward/8, msg_cs_doll_flag/2,
		 msg_sc_open_notice/0, msg_sc_start_notice/0, msg_sc_end_notice/1, msg_sc_monster_hp_notice/6,
		 msg_sc_remove_monster_notice/1, msg_sc_update_monster_notice/2, msg_sc_rank_notice/2,
		 msg_sc_first/2, msg_sc_kill/2, msg_sc_boss_hp_notice/3,msg_sc_auto_reward/3,
         msg_sc_doll_cash/2
		]).

-export([cross_call/5, cross_cast/5, get_room_pid/4, reward_first/5, broadcast_room/2, broadcast_room/3,
		 reward_rank3/6, unbroadcast_room/2, unbroadcast_room/3]).
-export([enter/3, start_battle/4, check_boss_end/1]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% boss战开始
%% boss_api:on([10010]).
on([BossId]) ->
	?MSG_DEBUG("~n boss_api:on.....................~p", [BossId]),
	try 
		Type		= get_active_type(BossId),
		case active_api:is_opened(Type) of
			?CONST_SYS_TRUE -> 
				?MSG_DEBUG("~n boss_api:on.....................~p", [{BossId, Type}]),
				?ok;
			_ -> 
				?MSG_DEBUG("~n boss_api:on.....................~p", [{BossId}]),
				init_boss(BossId)
		end
	catch Error:Reason -> ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()])
	end.

%% 初始化世界BOSS--活动开始时调用
init_boss(BossId) ->
	try
		?MSG_DEBUG("~n boss_api:on.....................~p", [BossId]),
		clean_boss_ets(),
		crond_api:interval_del(boss_interval),
		crond_api:interval_del(robot_boss_interval),
		?ok					= boss_cross_counter_serv:reset_call(),
		BossConfig			= data_boss:get_boss_config(),
		TimeStart			= misc:seconds() + BossConfig#rec_boss_config.time_start,					% 正式开始时间戳
		TimeEnd 			= TimeStart + BossConfig#rec_boss_config.time_end,							% 结束时间戳
		BossData			= #boss_data{room = 0, time_start = TimeStart, time_end = TimeEnd,
										 state = ?CONST_BOSS_STATE_OPEN, id = BossId, node = 0},
		ets_api:insert(?CONST_ETS_BOSS_DATA, BossData),
		crond_api:interval_add(boss_interval, 1, boss_api, boss_interval, []),
		?ok
	catch
		Any -> 		
		?MSG_ERROR("ERROR Any = ~p", [{Any}]), 
		?ok
	end.

clean_boss_ets() ->
	ets:delete_all_objects(?CONST_ETS_BOSS_CROSS_ROOM),
	ets:delete_all_objects(?CONST_ETS_BOSS_DATA),
	ets:delete_all_objects(?CONST_ETS_BOSS_PLAYER).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
boss_interval() ->
	case ets:first(?CONST_ETS_BOSS_DATA) of
		'$end_of_table' -> ?ok;
		Key	->
			boss_interval_ext(Key),
			boss_interval_next(Key)
	end.

boss_interval_next(Key) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DATA, Key) of
		?null -> ?ok;
		_ ->
			case ets:next(?CONST_ETS_BOSS_DATA, Key) of
				'$end_of_table' -> ?ok;
				Key1 ->
					boss_interval_ext(Key1),
					boss_interval_next(Key1)
			end
	end.

boss_interval_ext(Key) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DATA, Key) of
		BossData when is_record(BossData, boss_data) ->
%% 			BossId			= boss_mod:check_boss_id(BossData#boss_data.id),
%% 			robot_boss_api:enter(BossId),
			boss_interval(BossData);
		_ -> ?ok
	end.

boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_OPEN, id = BossId, room = RoomId,
									node = MasterNode}) ->
	Time		= misc:seconds(),
%% 	robot_boss_api:enter(BossId),
	if
		Time >= BossData#boss_data.time_start ->
			case boss_serv:boss_start_call(BossData) of
				?ok ->
%%					?MSG_DEBUG("~n111111111111111111111111111111111111~p", [BossId]),
%% 					misc_app:broadcast_world_2(msg_sc_start_notice()),
					broadcast_room(MasterNode, RoomId, msg_sc_start_notice()),
					robot_boss_api:enter(BossId),
                    robot_boss_serv:robot_start_cast(BossId);
				_ ->
					?ok
			end;
		?true -> ?ok
	end;
boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_START, room = RoomId}) when RoomId =/= 0 ->
%%	?MSG_DEBUG("~n23243423333333333243243222222222222222=~p", [RoomId]),
	Time			= misc:seconds(),
	PacketHp		= msg_sc_update_monster_notice(Time, BossData),
	PacketRank		= msg_sc_rank_notice(RoomId, Time),
	Packet			= <<PacketHp/binary, PacketRank/binary>>,
	broadcast_room(RoomId, Packet),
	?ok;
boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_START, id = _BossId}) ->             
%%	?MSG_DEBUG("~n 55555555555555555555555~p", [BossId]),
	Time		= misc:seconds(),
	try
		if
			Time >= BossData#boss_data.time_end ->
			case boss_serv:boss_close_call(BossData) of
				?ok -> ?ok;
				_ -> ?ok
			end;
			?true -> ?ok
		end
	catch Error:Reason ->
		?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
		?ok
	end;
%% 	robot_boss_api:enter(BossId),
%% 	robot_boss_api:interval(BossId),
boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_END}) ->
	try
		case boss_serv:boss_close_call(BossData) of
			?ok -> ?ok;
			_ -> ?ok
		end
	catch Error:Reason ->
		?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
		?ok
	end;
boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_CLOSE, end_type = ?CONST_BOSS_END_TYPE_DEATH, room = RoomId}) 
  when RoomId =/= 0->
	try
		FinalRank	= final_rank(RoomId),
%% 		%% 发放排名奖励
		reward_rank(BossData, ?CONST_BOSS_END_TYPE_DEATH, FinalRank),
		?MSG_DEBUG("~n111111111111111111111111111111111111", []),
%% 		%% 发放替身奖励
		reward_doll(BossData, RoomId),
%% 		%% 全服广播世界BOSS活动结束通知(隐藏活动图标)
		notice_active_end(BossData#boss_data.id, RoomId, ?CONST_BOSS_END_TYPE_DEATH),
%% 		%% 全服广播世界BOSS活动结束战报通知(聊天框战报)
		broadcast_boss_close(BossData, ?CONST_BOSS_END_TYPE_DEATH, FinalRank),
		ets_api:insert(?CONST_ETS_BOSS_DATA, BossData#boss_data{state = 5}),
		?MSG_ERROR("~nBOSS OVER BossId:~p...~n", [BossData#boss_data.id])
	catch Error:Reason ->
		?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
		?ok
	end;
boss_interval(BossData = #boss_data{state = ?CONST_BOSS_STATE_CLOSE, end_type = ?CONST_BOSS_END_TYPE_TIMEOUT, room = RoomId}) 
  when RoomId =/= 0->
	?MSG_ERROR("~nBOSS OVER RoomId:~p...~n", [RoomId]),
	try
		FinalRank	= final_rank(RoomId),
		
%% 		%% 发放排名奖励
		reward_rank(BossData, ?CONST_BOSS_END_TYPE_TIMEOUT, FinalRank),
		?MSG_DEBUG("~n12222222222222222222222222222222222222", []),
%% 		%% 发放替身奖励
		reward_doll(BossData, RoomId),
%% 		%% 全服广播世界BOSS活动结束通知(隐藏活动图标)
		notice_active_end(BossData#boss_data.id, RoomId, ?CONST_BOSS_END_TYPE_TIMEOUT),
%% 		%% 全服广播世界BOSS活动结束战报通知(聊天框战报)
		broadcast_boss_close(BossData, ?CONST_BOSS_END_TYPE_TIMEOUT, FinalRank),
%% 		case EndType of
%% 			?CONST_BOSS_END_TYPE_DEATH  -> ?ok;
%% 			?CONST_BOSS_END_TYPE_TIMEOUT ->
				ets_api:delete(?CONST_ETS_BOSS_DATA, RoomId),
%% 		end,
%% 		clean_boss_player(RoomId),
		?MSG_ERROR("~nBOSS OVER BossId:~p...~n", [BossData#boss_data.id])
	catch Error:Reason ->
		?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
		?ok
	end;
boss_interval(#boss_data{time_end = TimeEnd}) -> 
	Time				= misc:seconds(),
	BossConfig			= data_boss:get_boss_config(),
	Time1				= TimeEnd + BossConfig#rec_boss_config.time_start,
	if
		Time >= Time1 ->
			crond_api:interval_del(boss_interval),
			crond_api:interval_del(robot_boss_interval),
			clean_boss_ets(),
			ets:delete_all_objects(?CONST_ETS_BOSS_PLAYER),
			boss_cross_counter_serv:reset_cast();
		?true -> ?ok
	end.
	
%% 清除玩家数据
%% clean_boss_player(RoomId) ->
%% 	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
%% 								  BossPlayer#boss_player.room_id == RoomId ->
%% 									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
%% 							 end),
%% 	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
%% 	clean_boss_player_ext(UserIdList).
%% 
%% clean_boss_player_ext([]) -> ?ok;
%% clean_boss_player_ext([{UserId, Node}|Tail]) ->
%% 	ets_api:delete(?CONST_ETS_BOSS_PLAYER, UserId),
%% 	rpc:cast(Node, ets_api, delete, [?CONST_ETS_BOSS_PLAYER, UserId]),
%% 	clean_boss_player_ext(Tail).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% boss战结束 boss_api:off([0]).
off([BossId]) ->
%%	?MSG_ERROR("~nBOSS boss_api:off([~p])...~n", [BossId]),
	List			= ets_api:list(?CONST_ETS_BOSS_DATA),
	F = fun(_BossData =#boss_data{end_type = ?CONST_BOSS_END_TYPE_DEATH}) -> ?ok;
		   (BossData) ->
				case boss_serv:boss_end_call(BossData, ?CONST_BOSS_END_TYPE_TIMEOUT) of
					?ok -> ?ok;
					_ -> ?MSG_ERROR("~nERROR ---------- BOSS OFF BossId:~p...~n", [BossId]), ?ok
				end
		end,
	lists:foreach(F, List).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh_monster(UserId, MonsterId, HurtTuple) ->
	case check_boss_refresh(UserId) of
		{?ok, BossData, BossPlayer} ->
			case lists:keyfind(MonsterId, #boss_monster.monster_id, BossData#boss_data.monsters) of
				#boss_monster{hp_tuple = HpTuple} ->
					case HurtTuple of
						{0,0,0,0,0,0,0,0,0} -> HpTuple;
						_ ->
							Hurt		= lists:sum(misc:to_list(HurtTuple)),
							HurtTotal	= BossPlayer#boss_player.hurt + Hurt,
							HurtTmp		= BossPlayer#boss_player.hurt_tmp + Hurt,
							BossPlayer1 = BossPlayer#boss_player{hurt = HurtTotal, hurt_tmp = HurtTmp},
							boss_mod:set_boss_player(BossPlayer1),
%% 							Datas		= [{#boss_player.hurt, HurtTotal}, {#boss_player.hurt_tmp, HurtTmp}],
%% 							ets_api:update_element(?CONST_ETS_BOSS_PLAYER, UserId, Datas),
%% 							Node		= cross_api:get_master_node(),
%% 							rpc:cast(Node, ets_api, update_element, [?CONST_ETS_BOSS_PLAYER, UserId, Datas]),
							boss_serv:refresh_monster_cast(BossData, UserId, BossPlayer#boss_player.user_name, BossPlayer,
														   MonsterId, Hurt, HurtTuple),
							boss_mod:set_hp_tuple(HpTuple, HurtTuple)
					end;
				_ -> erlang:make_tuple(9, 0, [])
			end;
		{?error, _ErrorCode} -> erlang:make_tuple(9, 0, [])
	end.
check_boss_refresh(UserId) ->
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
%% 				BossData		= boss_mod:check_boss_start(BossPlayer#boss_player.boss_id),
				Room					= BossPlayer#boss_player.room_id,
				MasterNode				= BossPlayer#boss_player.master_node,
				BossData				= check_boss_start(MasterNode, Room),
				{?ok, BossData, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

check_boss_start(MasterNode, Room) ->
	BossData	= case node() of
					  MasterNode ->
						  boss_mod:get_boss_data(Room);
					  _ ->
						  rpc:call(MasterNode, boss_mod, get_boss_data, [Room])
				  end,
	if 
		is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> throw({?error, ?TIP_BOSS_NOT_OPEN});% 世界BOSS尚未开启
				?CONST_BOSS_STATE_START -> BossData;
				?CONST_BOSS_STATE_END -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				?CONST_BOSS_STATE_CLOSE -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				5 -> throw({?error, ?TIP_BOSS_CLOSE})% 世界BOSS已结束
			end;
		?true -> throw({?error, ?TIP_BOSS_NOT_OPEN})% 世界BOSS尚未开启
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% check_boss_over(UserId, MonsterId) ->
%% 	case check_boss_over(UserId) of
%% 		{?ok, BossData, _BossPlayer} ->
%% 			case lists:keymember(MonsterId, #boss_monster.monster_id, BossData#boss_data.monsters) of
%% 				?true -> ?false;% 未结束
%% 				?false -> ?true% 结束--胜利
%% 			end;
%% 		{?error, _ErrorCode} -> ?true% 结束--胜利
%% 	end.
%% check_boss_over(UserId) ->
%% 	try
%% 		case boss_mod:get_boss_player(UserId) of
%% 			BossPlayer when is_record(BossPlayer, boss_player) ->
%% 				BossData	= boss_mod:check_boss_start(BossPlayer#boss_player.boss_id),
%% 				{?ok, BossData, BossPlayer};
%% 			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
%% 		end
%% 	catch
%% 		throw:Return -> Return;
%% 		Error:Reason ->
%% 			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
%% 			{?error, ?TIP_COMMON_SYS_ERROR}
%% 	end.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 离线退出
logout(Player) ->
	case boss_mod:get_boss_player(Player#player.user_id) of
		BossPlayer when is_record(BossPlayer, boss_player) andalso
						BossPlayer#boss_player.exist =:= ?CONST_SYS_TRUE ->
			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
				{?true, Player2} ->
					Time		= misc:seconds() + ?CONST_BOSS_CD_EXIT,
					BossPlayer2	= BossPlayer#boss_player{cd_exit = Time, exist = ?CONST_SYS_FALSE},
					boss_mod:set_boss_player(BossPlayer2),
                    Player3     = map_api:return_last_city(Player2),
					{?ok, Player3};
				{?false, Player2, _} -> {?ok, Player2}
			end;
		_ -> {?ok, Player}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动参战(雇佣替身娃娃)
boss_doll(Player, BossId, ?true) ->
	UserId		= Player#player.user_id,
	case check_boss_doll(Player, BossId) of
		?ok ->
			BossIds2	=
				case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
					?null -> [BossId];
					{UserId, BossIds} ->
						case lists:member(BossId, BossIds) of
							?true -> BossIds;
							?false -> [BossId|BossIds]
						end
				end,
			ets_api:insert(?CONST_ETS_BOSS_DOLL, {UserId, BossIds2}),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
boss_doll(Player, BossId, ?false) ->
	UserId		= Player#player.user_id,
	case check_boss_doll(Player, BossId) of
		?ok ->
			case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
				?null -> ?ok;
				{UserId, BossIds} ->
					BossIds2	= lists:delete(BossId, BossIds),
					ets_api:insert(?CONST_ETS_BOSS_DOLL, {UserId, BossIds2}),
					?ok
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

check_boss_doll(Player, BossId) ->
	try
		Flag		= player_vip_api:can_boss_use_scapegoat(player_api:get_vip_lv(Player)),
		?ok			= boss_mod:check_vip(Flag),
		?ok			= check_doll_boss_state(BossId),
		?ok
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
check_doll_boss_state(_BossId) ->
	case boss_mod:get_boss_data(0) of
		BossData when is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> throw({?error, ?TIP_BOSS_DOLL_BAN});% 妖魔破已经开启，无法更改自动参战状态！
				?CONST_BOSS_STATE_START -> throw({?error, ?TIP_BOSS_DOLL_BAN});
				?CONST_BOSS_STATE_END -> ?ok;
				?CONST_BOSS_STATE_CLOSE -> ?ok;
				5 -> ?ok
			end;
		?null -> ?ok
	end.

%% 获取世界BOSS自动参战信息
get_boss_doll_info(UserId) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
		?null -> [];
		{UserId, BossIds} -> BossIds
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 跨服进入
enter(Player, BossId, IsRobot) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	Account			= Player#player.account,
	try
		BossId1						= boss_mod:check_boss_id(BossId),
		{?ok, BossPlayer}			= check_can_enter(Player, BossId1, IsRobot),
%% 		?ok							= check_can_enter(UserId),
%% 		{MasterNode, Room, LvPhase}	= cross_api:get_boss_master(UserId, Lv, IsRobot),				%% 根据人物等级分房间
		MasterNode					= BossPlayer#boss_player.master_node,
		Room						= BossPlayer#boss_player.room_id,
		LvPhase						= boss_cross_counter_serv:get_lv_phase(Lv),
%% 		{?ok, BossPlayer}			= check_enter_boss(Player, BossId1, Room),						%% 初始化人物数据
		Node 						= node(),
       	ServIndex 					= cross_api:get_self_index(),
		?MSG_DEBUG("~n 22222222222222=~p", [{MasterNode, Node, ServIndex}]),
		case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_BOSS) of
			{?true, Player2} ->
				{MapId, BossData}	= case Node of
										  MasterNode -> boss_mod:enter_boss_map(UserId, Room, Node, ServIndex, LvPhase, BossPlayer, BossId1);
										  _ -> rpc:call(MasterNode,  boss_mod, enter_boss_map, [UserId, Room, Node, ServIndex, LvPhase, BossPlayer, BossId1])
									  end,
				BossPlayer1			= BossPlayer#boss_player{room_id = Room, map_id = MapId, serv_id = ServIndex},
				boss_mod:set_boss_player(BossPlayer1),
				?MSG_DEBUG("555555555555555555555555555555~p", [BossData]),
%% 				NewBossPlayer		= BossPlayer#boss_player{room_id = Room, map_id = MapId, serv_id = ServIndex, boss_id = BossId1},
%% 				ets_api:insert(?CONST_ETS_BOSS_PLAYER, NewBossPlayer),
				PacketEnter			= msg_sc_enter(BossId1, BossData, BossPlayer1),
				PacketMonster		= case boss_mod:get_boss_monster(BossData) of
									  BossMonster when is_record(BossMonster, boss_monster) ->
										  msg_sc_monster_info(BossMonster#boss_monster.monster_id,
															  BossMonster#boss_monster.hp,
															  BossMonster#boss_monster.hp_max);
									  _ -> <<>>
								  end,
				misc_packet:send(Player#player.net_pid, <<PacketEnter/binary, PacketMonster/binary>>),
				?MSG_DEBUG("~n3333333333333333333333333 MapId=~p", [{MapId, Player2#player.state, Player2#player.play_state, BossData#boss_data.id}]),
				Player3				= map_api:enter_map(Player2#player{user_state = ?CONST_PLAYER_STATE_NORMAL, practice_state = 0}, MapId),
				catch yunying_activity_mod:update_shuangdan_activity_info(UserId,1002,1),         %双旦活动妖魔破检测
				schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_BOSS),
				admin_log_api:log_campaign(UserId, Account, Lv, get_active_type(BossId1), misc:seconds()),
				{?ok, Player3};
			{?false, Player, Tips} ->
				?MSG_DEBUG("~n 33333333333333", []),
				Packet = message_api:msg_notice(Tips),
				misc_packet:send(Player#player.net_pid, Packet),
				{?ok, Player}
		end
	catch
		throw:{?error, ErrorCode} ->
			TipPacket			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		X:Y ->
			?MSG_DEBUG("~n, X=~p, Y=~p", [X, Y]),
			{?ok, Player}
	end.

check_can_enter(Player, BossId, IsRobot) ->
	UserId			= Player#player.user_id,
	Time			= misc:seconds(),
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	try
		case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
			#boss_player{room_id = RoomId, master_node = OldMasterNode} =  BossPlayer ->
				case node() of
					OldMasterNode ->
%%						?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$~p", [{RoomId, OldMasterNode}]),
						case ets_api:lookup(?CONST_ETS_BOSS_DATA, RoomId) of
							#boss_data{state = State} when  State == ?CONST_BOSS_STATE_END orelse 
														    State == ?CONST_BOSS_STATE_CLOSE orelse
															State == 5	-> 
								throw({?error, ?TIP_BOSS_CLOSE});
							#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
															   State == ?CONST_BOSS_STATE_START ->
								?ok			= check_doll(UserId, BossId),
								?ok			= boss_mod:check_cd_exit(Time, BossPlayer#boss_player.cd_exit),
								{?ok, BossPlayer#boss_player{exist = ?CONST_SYS_TRUE}};
							_ ->
								?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", [{RoomId, OldMasterNode}]),
								throw({?error, ?TIP_BOSS_CLOSE})
%% 								{MasterNode, Room, _LvPhase}	= cross_api:get_boss_master(UserId, Lv, IsRobot),				%% 根据人物等级分房间
%% 								check_enter_boss(Player, BossId, Room, MasterNode)
						end;
					_ ->
						case rpc:call(OldMasterNode, ets_api, lookup, [?CONST_ETS_BOSS_DATA, RoomId]) of
							#boss_data{state = State} when  State == ?CONST_BOSS_STATE_END orelse 
																State == ?CONST_BOSS_STATE_CLOSE orelse
																State == 5 -> 
								throw({?error, ?TIP_BOSS_CLOSE});
							#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
															   State == ?CONST_BOSS_STATE_START ->
								?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$=~p", [{RoomId, OldMasterNode}]),
								?ok			= check_doll(UserId, BossId),
								?ok			= boss_mod:check_cd_exit(Time, BossPlayer#boss_player.cd_exit),
								{?ok, BossPlayer#boss_player{exist = ?CONST_SYS_TRUE}};
							_ ->
								?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$=~p", [{RoomId, OldMasterNode}]),
								throw({?error, ?TIP_BOSS_CLOSE})
%% 								{MasterNode, Room, _LvPhase}	= cross_api:get_boss_master(UserId, Lv, IsRobot),				
%% 								check_enter_boss(Player, BossId, Room, MasterNode)
						end
				end;
			_ ->
				?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$", []),
				{MasterNode, Room, _LvPhase}	= cross_api:get_boss_master(UserId, Lv, IsRobot),				
				check_enter_boss(Player, BossId, Room, MasterNode)
		end
	catch
		throw:Return -> 
			?MSG_DEBUG("~n  4444444444 Return =~p", [Return]),
			throw(Return);
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

							
check_enter_boss(Player, BossId, Room, MasterNode) ->
	Time			= misc:seconds(),
	UserId			= Player#player.user_id,
	try
		?ok			= check_boss_open(),
		BossPlayer	= init_boss_player(Player, Room, BossId, MasterNode),
		?ok			= check_doll(UserId, BossId),
		?ok			= boss_mod:check_cd_exit(Time, BossPlayer#boss_player.cd_exit),
		{?ok, BossPlayer}
	catch
		throw:Return -> 
			?MSG_DEBUG("~n  4444444444 Return =~p", [Return]),
			throw(Return);
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%% 判断世界boss是否开启
check_boss_open() ->
	case boss_mod:get_boss_data(0) of
		#boss_data{state = State} 
		  when State =:= ?CONST_BOSS_STATE_OPEN orelse
			   State =:= ?CONST_BOSS_STATE_START 
			   -> ?ok;
		_ -> throw({?error, ?TIP_BOSS_NOT_OPEN})		% 世界BOSS尚未开启
	end.

%% 取得世界boss玩家数据
init_boss_player(Player, Room, BossId, MasterNode) ->
	BossPlayer	=
		case boss_mod:get_boss_player(Player#player.user_id) of
			?null -> boss_mod:record_boss_player(Player, Room, BossId, ?false, MasterNode);
			BossPlayerTemp -> BossPlayerTemp
		end,
	BossPlayer#boss_player{exist = ?CONST_SYS_TRUE}.	

%% 检查世界BOSS替身娃娃
check_doll(UserId, BossId) ->
?MSG_DEBUG("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$~p", [{BossId, UserId}]),
	case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
		?null -> ?ok;
		{UserId, BossIds} ->
			case lists:member(BossId, BossIds) of
				?true -> throw({?error, ?TIP_BOSS_DOLL});% 已购买替身娃娃，不能进入
				?false -> ?ok
			end
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
quit(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, Player2} ->
			case boss_mod:get_boss_player(Player2#player.user_id) of
				?null ->
					Player3 = map_api:return_last_city(Player2),
					{?ok, Player3};
				BossPlayerTemp ->
					Time		= misc:seconds() + ?CONST_BOSS_CD_EXIT,
					BossPlayer	= BossPlayerTemp#boss_player{cd_exit = Time, exist = ?CONST_SYS_FALSE},
					boss_mod:set_boss_player(BossPlayer),
					Player3     = map_api:return_last_city(Player2),
					Packet35212	= msg_sc_quit_ok(),
					?MSG_DEBUG("44444444444444444444444444444444444444444444~p", [{BossPlayerTemp#boss_player.room_id}]),
					MasterNode	= BossPlayerTemp#boss_player.master_node,
					RoomId		= BossPlayerTemp#boss_player.room_id,
					Packet35280	= msg_sc_exit_cd(MasterNode, RoomId, Time),
					misc_packet:send(Player#player.net_pid, <<Packet35212/binary, Packet35280/binary>>),
					{?ok, Player3}
			end;
		{?false, Player2, _} ->
			Player3 = map_api:return_last_city(Player2),
			{?ok, Player3}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hire_doll(Player, BossId, IsEn, IsReborn, IsQuickReborn, Cash) ->
    VipLv = player_api:get_vip_lv(Player),
    case player_vip_api:can_boss_use_scapegoat(VipLv) of
        ?CONST_SYS_TRUE ->
            schedule_api:auto(Player, BossId, {?true, IsEn, IsReborn, IsQuickReborn, Cash}),
            ?ok;
        _ ->
            {?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
auto(Player, Auto) ->
	case check_auto(Player) of
		{?ok, BossPlayer} ->
			BossPlayer2	= BossPlayer#boss_player{auto = Auto},
			boss_mod:set_boss_player(BossPlayer2),
			%% 发送数据通知客户端...
			Packet		= msg_sc_auto(Auto),
			misc_packet:send(Player#player.net_pid, Packet),
			?ok;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			?ok
	end.

check_auto(Player) ->
	UserId		= Player#player.user_id,
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
%% 				BossData	= boss_mod:check_boss_open(BossPlayer#boss_player.boss_id),
				Flag		= player_vip_api:can_boss_auto_fight(player_api:get_vip_lv(Player)),
				?ok			= boss_mod:check_vip(Flag),
				{?ok, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
encourage(Player, IsRobot) ->
	UserId			= Player#player.user_id,
	case check_encourage(Player, IsRobot) of
		{?ok, BossConfig, BossPlayer} ->
			Cash	= BossConfig#rec_boss_config.encourage_cash,
            case cost_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_ENCOURAGE, IsRobot, BossPlayer#boss_player.boss_id) of
%% 			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_ENCOURAGE) of
				?ok ->
					Encourage2		= BossPlayer#boss_player.encourage + 1,
					BossPlayer2		= BossPlayer#boss_player{encourage = Encourage2},
                    {Power, _, _, _}   = rank_api:get_max_power(),
                    if
                        ?CONST_SYS_TRUE =/= IsRobot ->
        					Packet25230		= msg_sc_encourage(round(Encourage2*Power/100)),
        					PacketNotice	= message_api:msg_notice(?TIP_BOSS_ENCOURAGE_SUCCESS,
        															 [{?TIP_SYS_COMM, misc:to_list(Encourage2)}]),
        					boss_mod:set_boss_player(BossPlayer2),
        					misc_packet:send(Player#player.net_pid, <<Packet25230/binary, PacketNotice/binary>>);
                        ?true ->
                            ?ok
                    end,
					?ok;
				{?error, ErrorCode} ->
					Packet = message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, Packet),
					?ok
			end;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			?ok;
		{?error, ErrorCode, Value} ->
			Packet = message_api:msg_notice(ErrorCode, [{?TIP_SYS_COMM, misc:to_list(Value)}]),
			misc_packet:send(Player#player.net_pid, Packet),
			?ok
	end.

cost_money(UserId, MoneyType, Value, Point, ?false, _) ->
    player_money_api:minus_money(UserId, MoneyType, Value, Point);
cost_money(UserId, _MoneyType, Value, Point, ?true, BossId) -> % 机器人用到
    robot_boss_api:cost_money(UserId, Value, Point, BossId).

check_encourage(Player, IsRobot) ->
	UserId		= Player#player.user_id,
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
				BossConfig	= data_boss:get_boss_config(),
%% 				BossData	= boss_mod:check_boss_open(BossPlayer#boss_player.boss_id),
				Flag		= player_vip_api:can_boss_encourage(player_api:get_vip_lv(Player)),
%% 				?ok			= boss_mod:check_doll(UserId, BossData#boss_data.id, IsRobot),
				?ok			= boss_mod:check_vip(Flag),
				?ok			= boss_mod:check_encourage_max(10, BossPlayer#boss_player.encourage),
				?ok			= boss_mod:check_money(UserId, BossConfig#rec_boss_config.encourage_cash, IsRobot, BossPlayer#boss_player.boss_id),
				{?ok, BossConfig, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
login_packet(Player, AccPacket) -> 
	UserId		= Player#player.user_id,
	case boss_mod:get_boss_player(UserId) of
		?null -> {Player, AccPacket};
		BossPlayer ->
			?MSG_DEBUG("5555555555555555555555555555", []),
			MasterNode				 = BossPlayer#boss_player.master_node,
			RoomId					 = BossPlayer#boss_player.room_id,
			case node() of
				MasterNode ->
					case ets_api:lookup(?CONST_ETS_BOSS_DATA, RoomId) of
						#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
													   State == ?CONST_BOSS_STATE_START ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							Packet	= msg_sc_exit_cd(MasterNode, RoomId, BossPlayer#boss_player.cd_exit),
							{Player, <<AccPacket/binary, Packet/binary>>};
						_ ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							{Player, AccPacket}
					end;
				_ ->
					case rpc:call(MasterNode, ets_api, lookup, [?CONST_ETS_BOSS_DATA, RoomId]) of
						#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
													   State == ?CONST_BOSS_STATE_START ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							Packet	= msg_sc_exit_cd(MasterNode, RoomId, BossPlayer#boss_player.cd_exit),
							{Player, <<AccPacket/binary, Packet/binary>>};
						_ ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							{Player, AccPacket}
					end
			end
	end.

check_boss_end(Player) ->
	UserId		= Player#player.user_id,
	case boss_mod:get_boss_player(UserId) of
		?null -> ?false;
		BossPlayer ->
			?MSG_DEBUG("5555555555555555555555555555", []),
			MasterNode			= BossPlayer#boss_player.master_node,
			RoomId				= BossPlayer#boss_player.room_id,
			case node() of
				MasterNode ->
					case ets_api:lookup(?CONST_ETS_BOSS_DATA, RoomId) of
						#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
													   State == ?CONST_BOSS_STATE_START ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							?false;
						_ ->
							?true
					end;
				_ ->
					case rpc:call(MasterNode, ets_api, lookup, [?CONST_ETS_BOSS_DATA, RoomId]) of
						#boss_data{state = State} when State == ?CONST_BOSS_STATE_OPEN orelse
													   State == ?CONST_BOSS_STATE_START ->
							?MSG_DEBUG("5555555555555555555555555555", []),
							?false;
						_ ->
							?true
					end
			end
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reborn(Player, IsRobot) ->
	UserId			= Player#player.user_id,
	case check_reborn(Player, IsRobot) of
		{?ok, _BossConfig, BossPlayer, Cash} ->
			?MSG_DEBUG("444444444444444444444444", []),
%% 			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_REBORN) of
            case cost_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_REBORN, IsRobot, BossPlayer#boss_player.boss_id) of
				?ok ->
                    {_, Player2}    = 
                        if
                            ?false == IsRobot ->
    					        player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL);
                            ?true ->
                                robot_boss_api:change_robot_state(UserId, ?CONST_PLAYER_STATE_FIGHTING, BossPlayer#boss_player.boss_id),
                                {?ok, Player}
                        end,
%% 					case boss_api:battle_start(Player2, ?false, ?false, IsRobot) of
					case start_battle(Player2, ?CONST_SYS_TRUE, ?false, IsRobot) of
						{?ok, Player3} ->
							?MSG_DEBUG("444444444444444444444444", []),
							BossPlayer2	= BossPlayer#boss_player{reborn 		= ?CONST_SYS_TRUE,
																 reborn_times	= 0,% BossPlayer#boss_player.reborn_times + 1,
																 cd_death		= 0},
							boss_mod:set_boss_player(BossPlayer2),
							%% 发送数据通知客户端...
                            if
                                ?CONST_SYS_TRUE =/= IsRobot ->
                                    Packet      = msg_sc_reborn(BossPlayer2#boss_player.reborn_times),
                                    misc_packet:send(UserId, Packet);
                                ?true ->
                                    ?ok
                            end,
							{?ok, Player3};
						{?error, ErrorCode} ->
							?MSG_DEBUG("5555555555555555555555555555555555=~p", [ErrorCode]),
                            if
                                ?false =/= IsRobot ->
                                    robot_boss_api:plus_money(UserId, Cash, ?CONST_COST_BOSS_BAD_REBORN, BossPlayer#boss_player.boss_id);
                                ?true ->
                                    player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_BAD_REBORN)
                            end,
%% 							player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_BAD_REBORN),
							{?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ?TIP_BOSS_IN_BATTLE} -> 
			?MSG_DEBUG("444444444444444444444444", []),
			{?ok, Player};
		{?error, ErrorCode} ->
			?MSG_DEBUG("444444444444444444444444", []),
			{?error, ErrorCode};
		{?error, ErrorCode, Value} ->
			?MSG_DEBUG("444444444444444444444444", []),
			{?error, ErrorCode, Value}
	end.

check_reborn(Player, IsRobot) ->
	UserId		= Player#player.user_id,
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
                case is_fighting(Player, IsRobot, BossPlayer#boss_player.boss_id) of
                    ?true -> 
                        {?error, ?TIP_BOSS_IN_BATTLE};
                     _ ->
						 ?MSG_DEBUG("444444444444444444444444", []),
        				BossConfig	= data_boss:get_boss_config(),
%%         				BossData	= boss_mod:check_boss_start(BossPlayer#boss_player.boss_id),
        				Cash		= BossConfig#rec_boss_config.reborn_cash,
        				Flag		= player_vip_api:can_boss_reborn(player_api:get_vip_lv(Player)),
%%         				?ok			= boss_mod:check_doll(UserId, BossData#boss_data.id, IsRobot),
        				?ok			= boss_mod:check_vip(Flag),
        %% 						?ok			= boss_mod:check_reborn_times(RebornMax, BossPlayer#boss_player.reborn_times),
        				?ok			= boss_mod:check_money(UserId, Cash, IsRobot, BossPlayer#boss_player.boss_id),
        				{?ok, BossConfig, BossPlayer, Cash}
                end;
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

is_fighting(Player, ?false, _BossId) -> player_state_api:is_fighting(Player);
is_fighting(Player, ?true, BossId)   -> robot_boss_api:is_fighting(Player#player.user_id, BossId).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% battle_start(Player, IsRobot) ->
%% 	battle_start(Player, ?true, ?false, IsRobot).
%% battle_start(Player, Flag, Auto, IsRobot) ->
%% 	case check_battle_start(Player, Flag, IsRobot) of
%% 		{?ok, BossData, BossPlayer} ->
%% 			Encourage	= BossPlayer#boss_player.encourage,
%% 			Reborn		= case BossPlayer#boss_player.reborn of
%% 							  ?CONST_SYS_FALSE -> 0;
%% 							  ?CONST_SYS_TRUE ->
%% 								  BossConfig	= data_boss:get_boss_config(),
%% 								  BossConfig#rec_boss_config.reborn_plus
%% 						  end,
%%             {Power, _, _, _}   = rank_api:get_max_power(),
%% 			AttrPlus	= round(Encourage*Power / 100),
%% 			Attr		= case AttrPlus of
%% 							  0 -> [];
%% 							  _ -> [{?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_FORCE_ATTACK, AttrPlus},
%% 									{?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, AttrPlus},
%%                                     {?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_FORCE_ATTACK, Reborn},
%%                                     {?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, Reborn}]
%% 						  end,
%% 			BossMonster	= boss_mod:get_boss_monster(BossData),
%%             RobotList = 
%%                 if
%%                     ?CONST_SYS_TRUE =:= IsRobot -> [Player#player.user_id];
%%                     ?true -> []
%%                 end,
%% 			case battle_api:start(Player, BossMonster#boss_monster.monster_id,
%% 								  #param{battle_type = ?CONST_BATTLE_BOSS, attr = Attr,
%% 										 ad1 = BossMonster#boss_monster.monster_id,
%% 										 ad2 = Auto,
%% 										 ad3 = BossMonster#boss_monster.hp_tuple,
%%                                          robot = RobotList}) of
%% 				{?ok, Player2} ->
%% 					reward_first(Player2, BossData, BossMonster, IsRobot),
%% 					if
%%                         ?CONST_SYS_TRUE =:= IsRobot -> battle_ext(Player2#player.user_id, BossPlayer);
%%                         ?true -> 
%%                             battle_ext(Player2, BossPlayer)
%%                     end;
%% 				{?error, ErrorCode} -> 
%%                     {?error, ErrorCode}
%% 			end;
%% 		{?ok, Player} -> {?ok, Player};
%% 		{?error, ErrorCode} -> {?error, ErrorCode}
%% 	end.

%% check_battle_start(Player, Flag, IsRobot) ->
%% 	UserId		= Player#player.user_id,
%% 	try
%% 		case boss_mod:get_boss_player(UserId) of
%% 			BossPlayer when is_record(BossPlayer, boss_player) ->
%% 				BossData	= boss_mod:check_boss_start(BossPlayer#boss_player.boss_id),
%% 				?ok			= boss_mod:check_player_state(Player),
%% 				?ok			= boss_mod:check_doll(UserId, BossData#boss_data.id, IsRobot),
%% 				?ok			= case Flag of
%% 								  ?true -> boss_mod:check_cd_death(misc:seconds(), BossPlayer);
%% 								  _ -> ?ok
%% 							  end,
%% 				{?ok, BossData, BossPlayer};
%% 			_ -> 
%%                 {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
%% 		end
%% 	catch
%% 		throw:{?error, ?TIP_COMMON_STATE_FIGHTING} -> 
%%             {?ok, Player};
%% 		throw:Return -> 
%%             Return;
%% 		Error:Reason ->
%% 			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
%% 			{?error, ?TIP_COMMON_SYS_ERROR}
%% 	end.

%% Player有可能是UserId/#player{}
battle_ext(Player, BossPlayer = #boss_player{boss_id = BossId, achievement = ?CONST_SYS_FALSE})	->
    Ach = get_ach(BossId),
    NewBossPlayer   = BossPlayer#boss_player{achievement = ?CONST_SYS_TRUE},
    boss_mod:set_boss_player(NewBossPlayer),
    case achievement_api:add_achievement(Player, Ach, 0, 1) of
        {?ok, Player1} ->
            {?ok, Player2} = schedule_api:add_guide_times(Player1, ?CONST_SCHEDULE_GUIDE_BOSS),
            {?ok, Player2};
        _ ->
            schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_BOSS),
            {?ok, Player}
    end;
%% battle_ext(Player, BossPlayer = #boss_player{boss_id = ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS, achievement = ?CONST_SYS_FALSE})	->
%% 	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_KILL_BOSS2, 0, 1),
%% 	{?ok, Player2}	= schedule_api:add_guide_times(Player1, ?CONST_SCHEDULE_GUIDE_BOSS),
%% 	NewBossPlayer	= BossPlayer#boss_player{achievement = ?CONST_SYS_TRUE},
%% 	boss_mod:set_boss_player(NewBossPlayer),
%% 	{?ok, Player2};
%% battle_ext(Player, BossPlayer = #boss_player{boss_id = ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2, achievement = ?CONST_SYS_FALSE})	->
%% 	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_KILL_BOSS2, 0, 1),
%% 	{?ok, Player2}	= schedule_api:add_guide_times(Player1, ?CONST_SCHEDULE_GUIDE_BOSS),
%% 	NewBossPlayer	= BossPlayer#boss_player{achievement = ?CONST_SYS_TRUE},
%% 	boss_mod:set_boss_player(NewBossPlayer),
%% 	{?ok, Player2};
%% battle_ext(Player, BossPlayer = #boss_player{boss_id = ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3, achievement = ?CONST_SYS_FALSE})	->
%% 	{?ok, Player1}	= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_KILL_BOSS2, 0, 1),
%% 	{?ok, Player2}	= schedule_api:add_guide_times(Player1, ?CONST_SCHEDULE_GUIDE_BOSS),
%% 	NewBossPlayer	= BossPlayer#boss_player{achievement = ?CONST_SYS_TRUE},
%% 	boss_mod:set_boss_player(NewBossPlayer),
%% 	{?ok, Player2};

battle_ext(Player, _BossPlayer)	->
	case schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_BOSS) of
        {?ok, Player2} ->
	        {?ok, Player2};
        _ ->
            {?ok, Player}
    end.

get_ach(?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS)  -> ?CONST_ACHIEVEMENT_KILL_BOSS1;
get_ach(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS)   -> ?CONST_ACHIEVEMENT_KILL_BOSS2;
get_ach(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2) -> ?CONST_ACHIEVEMENT_KILL_BOSS2;
get_ach(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3) -> ?CONST_ACHIEVEMENT_KILL_BOSS2.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 跨服boss战斗   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
start_battle(Player, RebornFlag, Auto, IsRobot) ->
	UserId			= Player#player.user_id,
	try
		?ok					= boss_mod:check_player_state(Player),
		{?ok, BossPlayer}	= get_boss_player(UserId),
		NewBossPlayer		= BossPlayer#boss_player{reborn = RebornFlag},
		?ok					= case IsRobot of
								  ?false -> boss_mod:check_cd_death(misc:seconds(), NewBossPlayer);
								  _ -> ?ok
							  end,
		MasterNode			= NewBossPlayer#boss_player.master_node,
		RoomId				= NewBossPlayer#boss_player.room_id,
		BossData     		= check_boss_start(MasterNode, RoomId),
		Encourage			= NewBossPlayer#boss_player.encourage,
		Reborn				= case NewBossPlayer#boss_player.reborn of
								  ?CONST_SYS_FALSE -> 0;
								  ?CONST_SYS_TRUE ->
									  BossConfig	= data_boss:get_boss_config(),
									  BossConfig#rec_boss_config.reborn_plus
							  end,
		{Power, _, _, _}   	= rank_api:get_max_power(),
		AttrPlus			= round(Encourage*Power / 100),
		Attr				= case AttrPlus of
								  0 -> [];
								  _ -> [{?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_FORCE_ATTACK, AttrPlus},
										{?CONST_SYS_CALC_TYPE_PLUS, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, AttrPlus},
										{?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_FORCE_ATTACK, Reborn},
										{?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, Reborn}]
							  end,
		RobotList = 
		 			if
		 				?false =:= IsRobot -> [];
		 				?true -> [UserId]
		 			end,
		Param	  = #param{battle_type = ?CONST_BATTLE_BOSS, attr = Attr,
						   ad2 = Auto,
						   robot = RobotList},
		?MSG_DEBUG("666666666666666666666666", []),
		case boss_mod:do_start_battle(Player, BossData, Param, MasterNode, RoomId) of
			{?ok, Player1} -> 
				if
					IsRobot =:= ?true  -> battle_ext(Player1#player.user_id, NewBossPlayer);
					?true -> 
						battle_ext(Player1, NewBossPlayer)
				end;
			_ -> 
				?MSG_DEBUG("666666666666666666666666", []),
				{?ok, Player}
		end
	catch
		throw:{?error, ?TIP_COMMON_STATE_FIGHTING} -> 
            {?ok, Player};
		throw:{?error, ErrorCode} ->
			?MSG_DEBUG("~n 111111111111111111~p", [ErrorCode]),
			ErrPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, ErrPacket),
			{?error, ErrorCode};
		Other:Reason ->
			?MSG_DEBUG("~n Other=~p, Reason=~p", [Other, Reason]),
			{?error, Reason}
	end.

get_boss_player(UserId) ->
	case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
		BossPlayer when is_record(BossPlayer, boss_player) -> {?ok, BossPlayer};
		_ -> throw({?error, ?TIP_BOSS_PLAYER_ABSENT})					% 玩家未在世界BOSS中
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
battle_over(UserId, Result, #param{battle_type = ?CONST_BATTLE_BOSS, robot = RobotList}) ->
	player_api:process_send(UserId, ?MODULE, battle_over_cb, [Result, RobotList]);
battle_over(_UserId, _Result, _BattleParam) -> ?ok.

battle_over_cb(Player, [Result, RobotList]) ->
	UserId		= Player#player.user_id,
	case check_battle_over(UserId) of
%% 		{?ok, #boss_data{map_id = MapId}, BossPlayer} ->
		{?ok, BossPlayer} ->
            State   = 
    			case Result of
    				?CONST_BATTLE_RESULT_LEFT ->
    					?CONST_PLAYER_STATE_NORMAL;
    				?CONST_BATTLE_RESULT_RIGHT ->
    					Datas	= [{#boss_player.cd_death, misc:seconds() + ?CONST_BOSS_CD_REBORN}],
    					ets_api:update_element(?CONST_ETS_BOSS_PLAYER, UserId, Datas),
    					?CONST_PLAYER_STATE_DEATH
    			end,
			Packet			= msg_sc_hurt(BossPlayer#boss_player.hurt),
			misc_packet:send(Player#player.net_pid, Packet),
			MapId			= BossPlayer#boss_player.map_id,
			MapData 		= data_map:get_map(MapId),
            if
                [] =:= RobotList ->
			        {?ok, Player2}	= map_api:teleport(Player, MapData#rec_map.x, MapData#rec_map.y),
			        {_Flag, Player3}= player_state_api:try_set_state(Player2, State),
			        {?ok, Player3};
                ?true ->
                    try
                        robot_boss_api:battle_over_robot(UserId, MapData#rec_map.x, MapData#rec_map.y, BossPlayer#boss_player.boss_id)
                    catch
                        X:Y ->
                            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
                    end,
                    {?ok, Player}
            end;
		{?error, _ErrorCode} ->
			{_Flag, Player2}= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
			{?ok, Player2}
	end.

check_battle_over(UserId) ->
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
				?MSG_DEBUG("55555555555555555555555", []),
%% 				BossData	= boss_mod:check_boss_start(BossPlayer#boss_player.boss_id),
				?MSG_DEBUG("55555555555555555555555", []),
				{?ok, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
revive(Player, IsRobot) ->
	UserId		= Player#player.user_id,
	case check_revive(Player, IsRobot) of
		{?ok, BossConfig, BossPlayer} ->
			Cash	= BossConfig#rec_boss_config.revive_cash,
            case cost_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_BOSS_REVIVE, IsRobot, BossPlayer#boss_player.boss_id) of
%% 			case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash, ?CONST_COST_BOSS_REVIVE) of
				?ok ->
					boss_mod:set_boss_player(BossPlayer#boss_player{cd_death = 0}),
					misc_packet:send(UserId, msg_sc_revive()),
					{_, Player2}	= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
					{?ok, Player2};
				{?error, ErrorCode} ->
					Packet = message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, Player}
			end;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player};
		{?error, ErrorCode, Value} ->
			Packet = message_api:msg_notice(ErrorCode, [{?TIP_SYS_COMM, misc:to_list(Value)}]),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

check_revive(Player, IsRobot) ->
	UserId		= Player#player.user_id,
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
				BossConfig	= data_boss:get_boss_config(),
%% 				BossData	= boss_mod:check_boss_open(BossPlayer#boss_player.boss_id),
				?ok			= check_revive_money(UserId, BossConfig#rec_boss_config.revive_cash, IsRobot, BossPlayer#boss_player.boss_id),
				{?ok, BossConfig, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

check_revive_money(UserId, Value, ?true, BossId) ->
    case robot_boss_api:check_money(UserId, Value, BossId) of
        ?ok ->
            ?ok;
        _ ->
            throw({?error, ?TIP_BOSS_CASH_NOT_ENOUGH, Value})% 元宝不足
    end;
check_revive_money(UserId, Value, _, _) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_BCASH_FIRST, Value) of
        {?ok, _Money, ?true} -> ?ok;
        _ -> throw({?error, ?TIP_BOSS_CASH_NOT_ENOUGH, Value})% 元宝不足
    end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
auto_revive(Player) ->
	UserId		= Player#player.user_id,
	case check_auto_revive(Player) of
		{?ok, BossPlayer} ->
			boss_mod:set_boss_player(BossPlayer#boss_player{cd_death = 0}),
			misc_packet:send(UserId, msg_sc_revive()),
			{_, Player2}	= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
			{?ok, Player2};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

check_auto_revive(Player) ->
	UserId		= Player#player.user_id,
	try
		case boss_mod:get_boss_player(UserId) of
			BossPlayer when is_record(BossPlayer, boss_player) ->
%% 				BossData	= boss_mod:check_boss_open(BossPlayer#boss_player.boss_id),
				?ok			= boss_mod:check_cd_death(misc:seconds(), BossPlayer),
				{?ok, BossPlayer};
			_ -> {?error, ?TIP_BOSS_PLAYER_ABSENT}% 玩家未在世界BOSS中
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reward_doll(BossData, RoomId) ->
	Reward		= {0,		% 替身奖励(金币)
				   0,		% 替身奖励(功勋)
				   0},		% 替身奖励(历练)

	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
								  BossPlayer#boss_player.room_id == RoomId andalso 
								  BossPlayer#boss_player.robot == ?true ->
									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
							 end),
	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
	reward_cross_doll(UserIdList, BossData#boss_data.id, Reward).


reward_cross_doll([], _BossId, _Reward) -> ?ok;
reward_cross_doll([{UserId, Node}|UserIdList], BossId, Reward) ->
	case node() of
		Node ->
			case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
				?null -> ?ok;
				{UserId, BossIds} ->
					reward_doll(BossId, Reward, UserId, BossIds),
					reward_cross_doll(UserIdList, BossId, Reward)
			end;
		_ ->
			rpc:cast(Node, ?MODULE, reward_cross_doll_ext, [UserId, BossId, Reward]),
			reward_cross_doll(UserIdList, BossId, Reward)
	end.

reward_cross_doll_ext(UserId, BossId, Reward) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
		?null -> ?ok;
		{UserId, BossIds} ->
			reward_doll(BossId, Reward, UserId, BossIds)
	end.

reward_doll(BossId, Reward, UserId, BossIds) ->
	try
		case lists:member(BossId, BossIds) of
			?true ->
				BossIds2	= delete_ets_doll(BossId, BossIds),
%%                 robot_boss_api:clear(UserId),
				ets_api:insert(?CONST_ETS_BOSS_DOLL, {UserId, BossIds2}),
				case player_api:check_online(UserId) of
					?true -> player_api:process_send(UserId, ?MODULE, reward_doll_cb, Reward);
					?false -> player_offline_api:offline(?MODULE, UserId, Reward)
				end;
			?false -> 
				?ok
		end
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?error, ?TIP_COMMON_SYS_ERROR}
	end. 

delete_ets_doll(BossId, BossIds) ->
	IdList = case BossId of
				 ?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS ->
					 [?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS];
				 _ ->
					 [?CONST_SCHEDULE_ACTIVITY_LATE_BOSS,
					  ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2,
					  ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3]
			 end,
	delete_ets_doll_ext(IdList, BossIds).
delete_ets_doll_ext([BossId|IdList], BossIds) ->
	NewBossIds 		= lists:delete(BossId, BossIds),
	delete_ets_doll_ext(IdList, NewBossIds);
delete_ets_doll_ext([], BossIds) -> BossIds.

reward_doll_cb(Player, {Gold, Meritorious, Experience}) ->
	UserId			= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_REWARD_RANK),
	Player2			= player_api:plus_experience(Player, Experience),
	{?ok, Player3}	= player_api:plus_meritorious(Player2, Meritorious, ?CONST_COST_BOSS_REWARD_MERITORIOUS),
%% 	Packet			= msg_sc_auto_reward(Gold,Experience,Meritorious),
%% 	misc_packet:send(UserId, Packet),
	admin_log_api:log_boss(Player,  1, 0, 0, Gold, Meritorious, Experience, 0, 0, 0),
	BossPlayer = boss_mod:get_boss_player(UserId),
	battle_ext(Player3,BossPlayer).

reward_first(MasterNode, Player, BossData, BossMonster, ?false) ->
	case BossMonster#boss_monster.first of
		0 ->
			?MSG_DEBUG("~n 2333333333333333333333333", []),
			RoomId		= BossData#boss_data.room,
			Gold		= BossData#boss_data.reward_valiant,
			UserId		= Player#player.user_id,
			UserName	= (Player#player.info)#info.user_name,
			Packet		= boss_api:msg_sc_first([{UserId, UserName}],
												[{?TIP_SYS_MONSTER, misc:to_list(BossMonster#boss_monster.monster_id)},
												 {?TIP_SYS_COMM, misc:to_list(Gold)}]),
%% 			misc_app:broadcast_world(Packet),
			?MSG_DEBUG("~n 2333333333333333333333333=~p", [RoomId]),
			broadcast_room(MasterNode, RoomId, Packet),
			player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_REWARD_FIRST),
%% 			boss_serv:reward_first_cast(RoomId, UserId, BossMonster#boss_monster.monster_id),
			?ok;
		_ -> 
			?MSG_DEBUG("~n 2333333333333333333333333=~p", [BossMonster#boss_monster.first]),
			?ok
	end;
reward_first(MasterNode, Player, BossData, BossMonster, ?true) ->
	case BossMonster#boss_monster.first of
		0 ->
			RoomId		= BossData#boss_data.room,
			Gold		= BossData#boss_data.reward_valiant,
            UserId      = Player#player.user_id,
			UserName	= (Player#player.info)#info.user_name,
			Packet		= boss_api:msg_sc_first([{UserId, UserName}],
												[{?TIP_SYS_MONSTER, misc:to_list(BossMonster#boss_monster.monster_id)},
												 {?TIP_SYS_COMM, misc:to_list(Gold)}]),
%% 			misc_app:broadcast_world(Packet),
			broadcast_room(MasterNode, RoomId, Packet),
			player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_REWARD_FIRST),
%% 			boss_serv:reward_first_cast(BossData#boss_data.id, UserId, BossMonster#boss_monster.monster_id),
            BossId2 	= robot_boss_api:get_boss_type(BossData#boss_data.id),
            ets_api:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, [{#ets_boss_robot_setting.bgold, Gold}]),
			?ok;
		_ -> ?ok
	end.

reward_last(MaterNode, RoomId, UserId, MonsterId, Gold) ->
	case boss_mod:get_boss_player(UserId) of
		BossPlayer when is_record(BossPlayer, boss_player) ->
			UserName	= BossPlayer#boss_player.user_name,
			Packet		= boss_api:msg_sc_kill([{UserId, UserName}],
											   [{?TIP_SYS_MONSTER, misc:to_list(MonsterId)},
												{?TIP_SYS_COMM, misc:to_list(Gold)}]),
%% 			misc_app:broadcast_world(Packet),
			broadcast_room(MaterNode, RoomId, Packet),
            BossId2 	= robot_boss_api:get_boss_type(BossPlayer#boss_player.boss_id),
            case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
                #ets_boss_robot_setting{bgold = BGoldRobot} ->
                    ets_api:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, [{#ets_boss_robot_setting.bgold, BGoldRobot+Gold}]);
                _ ->
                    ?ok
            end;
		_ -> ?ok
	end,
	%%player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, 10000, ?CONST_COST_BOSS_REWARD_LAST),
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_REWARD_LAST).

get_reward_hurt(UserId, _IsRobot) ->
	?MSG_DEBUG("ggggggggggggggggggggggggggggggggggggggggggggggg", []),
	case boss_mod:get_boss_player(UserId) of
		BossPlayer when is_record(BossPlayer, boss_player) ->
			?MSG_DEBUG("ggggggggggggggggggggggggggggggggggggggggggggggg~p", [BossPlayer#boss_player.boss_id]),
			MasterNode	= BossPlayer#boss_player.master_node,
			case rpc:call(MasterNode, boss_mod, get_boss_data, [BossPlayer#boss_player.room_id]) of
%% 			case boss_mod:get_boss_data(BossPlayer#boss_player.room_id) of
				BossData when is_record(BossData, boss_data) ->
					?MSG_DEBUG("ggggggggggggggggggggggggggggggggggggggggggggggg", []),
					F			= fun(A, B) -> case B of 0 -> 0; _ -> A div B end end,
					Hurt		= BossPlayer#boss_player.hurt_tmp,
					%%                     HurtTotal   = BossPlayer#boss_player.hurt,
					Gold		= F(Hurt, BossData#boss_data.reward_damage_gold),
					%% 去掉妖魔破历练的奖励
					%% Experience	= F(Hurt, BossData#boss_data.reward_damage_experience),
					Experience	= 0,
					Meritorious	= F(Hurt, BossData#boss_data.reward_damage_meritorious),
					
%%                     {Gold, Experience} = c(HurtTotal, Hurt),
                    %  加倍
                    Rate         = active_rate_api:get_rate(get_active_type(BossPlayer#boss_player.boss_id)),
                    Gold2        = round(Gold*Rate),
                    Experience2  = round(Experience*Rate),
                    Meritorious2 = round(Meritorious*Rate),
                    {OldGold, OldMeritorious, OldExperience} = BossPlayer#boss_player.hurt_reward,
					ets_api:update_element(?CONST_ETS_BOSS_PLAYER, UserId, 
                                           [{#boss_player.hurt_tmp, 0},
                                            {#boss_player.hurt_reward, {Gold2+OldGold, Meritorious2+OldMeritorious, Experience2+OldExperience}}]),
					{Gold2, Experience2, Meritorious2};
				_ -> 
					?MSG_DEBUG("ggggggggggggggggggggggggggggggggggggggggggggggg", []),
					{0, 0, 0}
			end;
		_ -> 
			?MSG_DEBUG("ggggggggggggggggggggggggggggggggggggggggggggggg", []),
			{0, 0, 0}
	end.


% XXX 伤害换奖励

% 最后1击 1W绑钻

% 排名是
% 1.1W
% 2.9000
% 3.8000
% 4.7000
% 5.6000
% 4.5000
% 3.4000
% 2.3000
% 1.2000

% 参与奖1000
get_rank_bind_cash(Rank) -> 0.

% get_rank_bind_cash(Rank) ->
% 	case Rank of
% 		1 -> 100;
% 		2 -> 90;
% 		3 -> 80;P
% 		4 -> 70;
% 		5 -> 60;
% 		6 -> 50;
% 		7 -> 40;
% 		8 -> 30;
% 		9 -> 20;
% 		_ -> 10
% 	end.



reward_rank(BossData, EndType, FinalRank) ->
%% 	PacketEnd		= msg_sc_end_notice(EndType),
	reward_rank2(FinalRank, BossData, <<>>).
reward_rank2([{UserId, _UserName, Idx, Hurt, Exist, Node}|FinalRank], BossData, PacketEnd) ->
	case node() of
		Node ->
			reward_rank3(UserId, Idx, Hurt, Exist, BossData, PacketEnd);
		_ ->
			rpc:cast(Node, ?MODULE, reward_rank3, [UserId, Idx, Hurt, Exist, BossData, PacketEnd])
	end,
	reward_rank2(FinalRank, BossData, PacketEnd);
reward_rank2([], _BossData, _PacketEnd) ->
	?ok.
% XXX 伤害换奖励
reward_rank3(UserId, Idx, Hurt, Exist, BossData, PacketEnd) ->
	RewardConfig	= data_boss:get_boss_reward_config(Idx),
	OnLine			= player_api:check_online(UserId),
%% 	F				= fun(A, B) -> case B of 0 -> 0; _ -> A div B end end,
%%     {Gold, Experience} = calc_hurt_reward(Hurt),
%% %% 	Gold			= F(Hurt, BossData#boss_data.reward_damage_gold),
%% %% 	Experience		= F(Hurt, BossData#boss_data.reward_damage_experience),
%% 	Meritorious		= F(Hurt, BossData#boss_data.reward_damage_meritorious),
%% %% 	HurtReward		= {Gold, Experience, Meritorious},
	RGold			= ?FUNC_BOSS_REWARD_RANK_GOLD(RewardConfig#rec_boss_reward_config.ratio_init,
												   RewardConfig#rec_boss_reward_config.ratio_plus,
												   RewardConfig#rec_boss_reward_config.ratio_gold,
												   BossData#boss_data.lv,
												   Idx,
												   RewardConfig#rec_boss_reward_config.head),
	RMeritorious   = ?FUNC_BOSS_REWARD_RANK_MERITORIOUS(RewardConfig#rec_boss_reward_config.ratio_init,
														  RewardConfig#rec_boss_reward_config.ratio_plus,
														  RewardConfig#rec_boss_reward_config.ratio_meritorious,
														  Idx,
														  RewardConfig#rec_boss_reward_config.head),
	%%  去掉妖魔破中历练奖励
	%% 	RExperience	   = ?FUNC_BOSS_REWARD_RANK_EXPERIENCE(RewardConfig#rec_boss_reward_config.ratio_init,
	%% 														 RewardConfig#rec_boss_reward_config.ratio_plus,
	%% 														 RewardConfig#rec_boss_reward_config.ratio_experience,
	%% 														 Idx,
	%% 														 RewardConfig#rec_boss_reward_config.head),
	RExperience	   = 0,
	
%% 	RankReward		= {RGold, RExperience, RMeritorious},
	reward_rank_ext(UserId, Idx, BossData#boss_data.id),
	ActiveType		= get_active_type(BossData#boss_data.id),
    Rate            = active_rate_api:get_rate(ActiveType),

    BindCash = get_rank_bind_cash(Idx),

    HurtReward2     =  case boss_mod:get_boss_player(UserId) of
                            BossPlayer when is_record(BossPlayer, boss_player) ->
                                BossPlayer#boss_player.hurt_reward;
                            _ ->
                                {0,0,0}
                        end,
    RankReward2     = {round(RGold * Rate), round(RMeritorious * Rate), round(RExperience * Rate)},

    RankReward3     =  {round(RGold * Rate), round(RMeritorious * Rate), round(RExperience * Rate),BindCash},
        
    % XXX
    IsRobot = robot_boss_api:clear(BossData#boss_data.id, UserId, Idx, RankReward2),
    
	reward_rank4(OnLine, UserId, ActiveType, Idx, Hurt, Exist, HurtReward2, RankReward3, PacketEnd, IsRobot).

reward_rank4(?true, UserId, ActiveType, Idx, Hurt, Exist, HurtReward, RankReward, PacketEnd, IsRobot) ->% 发放排名奖励(在线)
	player_api:process_send(UserId, ?MODULE, reward_rank_cb, {ActiveType, Idx, Hurt, Exist, HurtReward, RankReward, PacketEnd, IsRobot});
reward_rank4(?false, UserId, _ActiveType, Idx, Hurt, _Exist, HurtReward, RankReward, _PacketEnd, IsRobot) ->% 发放排名奖励(离线)
	player_offline_api:offline(?MODULE, UserId, {Idx, Hurt, HurtReward, RankReward, IsRobot}).

%% {Idx, Hurt, {HGold, HMeritorious, HExperience}, {RGold, RMeritorious, RExperience}}
reward_rank_cb(Player, {ActiveType, Idx, Hurt, Exist, {HGold, HMeritorious, HExperience}, {RGold, RMeritorious, RExperience,BindCash}, PacketEnd, ?CONST_SYS_FALSE}) ->
	?MSG_DEBUG("~n 555555555555555555555555555555~p", [{Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience}]),
	UserId			= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, RGold, ?CONST_COST_BOSS_REWARD_RANK),
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, BindCash, ?CONST_COST_BOSS_REWARD_RANK),
	Player2			= player_api:plus_experience(Player, RExperience),
	{?ok, Player3}	= player_api:plus_meritorious(Player2, RMeritorious, ?CONST_COST_BOSS_REWARD_MERITORIOUS),
	PacketBossEnd	= case Exist of ?CONST_SYS_TRUE -> PacketEnd; ?CONST_SYS_FALSE -> <<>> end,
	PacketReward	= msg_sc_reward(Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience),
	Packet			= <<PacketBossEnd/binary, PacketReward/binary>>,
	misc_packet:send(UserId, Packet),
    admin_log_api:log_boss(Player,  2, Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience),
    {?ok, Player4} = task_api:update_active(Player3, {ActiveType, 0}),
    {?ok, Player4};
reward_rank_cb(Player, {ActiveType, Idx, Hurt, _Exist, {HGold, HMeritorious, HExperience}, {RGold, RMeritorious, RExperience,BindCash}, _PacketEnd, _}) ->
    admin_log_api:log_boss(Player,  2, Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience),
    {?ok, Player2} = task_api:update_active(Player, {ActiveType, 0}),
    {?ok, Player2}.

final_rank(RoomId) ->
	MS		= ets:fun2ms(fun(#boss_player{user_id = UserId, user_name = UserName, hurt = Hurt, exist = Exist, room_id = RoomId1,
										  node = Node, robot = Robot}) when RoomId == RoomId1 ->
								 {UserId, UserName, Hurt, Exist, Node}
						 end),
	List	= sort(ets_api:select(?CONST_ETS_BOSS_PLAYER, MS)),
	?MSG_DEBUG("~naaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa~p", [List]),
	final_rank(List, 1, []).
final_rank([{UserId, UserName, Hurt, Exist, Node}|List], AccIdx, AccFinalRank) ->
	final_rank(List, AccIdx + 1, [{UserId, UserName, AccIdx, Hurt, Exist, Node}|AccFinalRank]);
final_rank([], _AccIdx, AccFinalRank) ->
	lists:reverse(AccFinalRank).

%% 快速排序
sort([{UserId, UserName, Hurt, Exist, Node}|L]) ->
	sort([{GTUserId, GTUserName, GTHurt, GTExist, GTNode} || {GTUserId, GTUserName, GTHurt, GTExist, GTNode} <- L, GTHurt >= Hurt])
		++ [{UserId, UserName, Hurt, Exist, Node}] ++
	sort([{LTUserId, LTUserName, LTHurt, LTExist, LTNode} || {LTUserId, LTUserName, LTHurt, LTExist, LTNode} <- L, LTHurt <  Hurt]);
sort([]) -> [].

flush_offline(Player, {Idx, Hurt, {HGold, HMeritorious, HExperience}, {RGold, RMeritorious, RExperience,BindCash}}) ->
	UserId			= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, RGold, ?CONST_COST_BOSS_FLUSH_OFFLINE),
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, BindCash, ?CONST_COST_BOSS_FLUSH_OFFLINE),
	Player2			= player_api:plus_experience(Player, RExperience),
	{?ok, Player3}	= player_api:plus_meritorious(Player2, RMeritorious, ?CONST_COST_BOSS_REWARD_MERITORIOUS),
	admin_log_api:log_boss(Player3,  4, Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience),
	PacketReward	= msg_sc_reward(Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience),
	misc_packet:send(UserId, PacketReward),
	{?ok, Player3};
flush_offline(Player, {Gold, Meritorious, Experience}) ->
	UserId			= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_FLUSH_OFFLINE),
	Player2			= player_api:plus_experience(Player, Experience),
	{?ok, Player3}	= player_api:plus_meritorious(Player2, Meritorious, ?CONST_COST_BOSS_REWARD_MERITORIOUS),
	admin_log_api:log_boss(Player3,  3, 0, 0, Gold, Meritorious, Experience, 0, 0, 0),
    if
        0 =/= Gold andalso 0 =/= Meritorious ->
        	PacketReward	= msg_sc_auto_reward(Gold,Experience,Meritorious),
        	misc_packet:send(Player#player.net_pid, PacketReward);
        ?true ->
            ?ok
    end,
	BossPlayer		=  boss_mod:get_boss_player(UserId),
	battle_ext(Player3,BossPlayer);
flush_offline(Player, Arg) ->
	?MSG_ERROR("flush_offline(Player, Arg) Arg:~p", [Arg]),
	{?ok, Player}.

reward_rank_ext(UserId, Rank, ?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS)	->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_KILL_BOSS2_ARRAY, Rank, 1);
reward_rank_ext(UserId, Rank, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS)	->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_KILL_BOSS2_ARRAY, Rank, 1);
reward_rank_ext(UserId, Rank, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2)	->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_KILL_BOSS2_ARRAY, Rank, 1);
reward_rank_ext(UserId, Rank, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3)	->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_KILL_BOSS2_ARRAY, Rank, 1);
reward_rank_ext(_UserId, _Rank, _ActivityId)	->	
    ?false.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 分段函数
%% %% X 包括Y的总伤害
%% %% Y 是当前单次攻击的伤害
%% c(X, Y) when X >= Y ->
%%     {Step, Delta} = c_2(X-Y),
%%     UpList = c_3(Y, Step, Delta),
%%     c_4(UpList, {0, 0});
%% c(_, _) -> {0,0}.
%% 
%% c_4([{Step, X}|Tail], {SumGold, SumExperience}) ->
%%     {GoldRate, ExperienceRate} = get_step_rate(Step),
%%     SumGold2 = SumGold + round(X / GoldRate),
%%     SumExperience2 = SumExperience + round(X / ExperienceRate),
%%     c_4(Tail, {SumGold2, SumExperience2});
%% c_4([], Sum) ->
%%     Sum.
%% 
%% get_step_rate(1) -> {10, 100};
%% get_step_rate(2) -> {20, 200};
%% get_step_rate(3) -> {30, 300};
%% get_step_rate(4) -> {40, 400};
%% get_step_rate(5) -> {50, 500}.
%% 
%% c_3(_, 0, 0) ->
%%     [{0,0}];
%% c_3(Y, Step, Delta) when Y =< Delta ->
%%     [{Step, Y}];
%% c_3(Y, Step, Delta) ->
%%     List = c_3_2(Y - Delta, Step+1),
%%     [{Step, Delta}|List].
%% 
%% %% 1000,0000 = 2kw - 1kw
%% %% 3000,0000 = 5kw - 2kw
%% %% 5000,0000 = 10kw - 5kw
%% c_3_2(X, 2) when 0 < X andalso X =< 10000000 ->
%%     [{2, X}];
%% c_3_2(X, 2) when 10000000 < X andalso X =< 40000000 ->
%%     [{2, 10000000},{3, X - 10000000}];
%% c_3_2(X, 2) when 40000000 < X andalso X =< 90000000 ->
%%     [{2, 10000000},{3, 30000000},{4, X - 40000000}];
%% c_3_2(X, 2) when 90000000 < X ->
%%     [{2, 10000000},{3, 30000000},{4, 50000000},{5, X - 90000000}];
%% c_3_2(X, 3) when 0 < X andalso X =< 30000000 ->
%%     [{3, X}];
%% c_3_2(X, 3) when 30000000 < X andalso X =< 80000000 ->
%%     [{3, 30000000},{4, X - 30000000}];
%% c_3_2(X, 3) when 80000000 < X ->
%%     [{3, 30000000},{4, 50000000},{5, X - 80000000}];
%% c_3_2(X, 4) when 0 < X andalso X =< 50000000 ->
%%     [{4, X}];
%% c_3_2(X, 4) when 50000000 < X ->
%%     [{4, 50000000},{5, X - 50000000}].
%% 
%% %% {阶, 离下一阶的伤害差值}
%% c_2(X) when X < 0 ->
%%     {0, 0};
%% c_2(X) when 0 =< X andalso X =< ?CONST_BOSS_HURT_1 ->
%%     {1, ?CONST_BOSS_HURT_1 - X};
%% c_2(X) when ?CONST_BOSS_HURT_1 < X andalso X =< ?CONST_BOSS_HURT_2 ->
%%     {2, ?CONST_BOSS_HURT_2 - X};
%% c_2(X) when ?CONST_BOSS_HURT_2 < X andalso X =< ?CONST_BOSS_HURT_3 ->
%%     {3, ?CONST_BOSS_HURT_3 - X};
%% c_2(X) when ?CONST_BOSS_HURT_3 < X andalso X =< ?CONST_BOSS_HURT_4 ->
%%     {4, ?CONST_BOSS_HURT_4 - X};
%% c_2(X) when ?CONST_BOSS_HURT_4 < X ->
%%     {5, X - ?CONST_BOSS_HURT_4}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 跨服调用
cross_call(UserId, Lv, Module, Function ,Args) ->
    case  cross_api:get_boss_master(UserId, Lv, ?false) of
        {Master, _Room, _LvPhase} ->
            rpc:call(Master, Module, Function, Args);
        _ ->
			?MSG_DEBUG("~n 2222222222222222222=~p", [{Module, Function, Args}]),
            ?ok
    end.

cross_cast(UserId, Lv, Module, Function, Args) ->
    {Master, _Room, _LvPhase} = cross_api:get_boss_master(UserId, Lv, ?false),
    rpc:cast(Master, Module, Function, Args).

%% 获取房间所在的地图pid
get_room_pid(UserId, MapId, Room, Param) ->
	?MSG_DEBUG("~n 111111111111111", []),
	case ets_api:lookup(?CONST_ETS_BOSS_CROSS_ROOM, Room) of
		#ets_boss_cross_room{map_pid = Pid} -> 
			case is_process_alive(Pid) of
				?true ->
					?MSG_DEBUG("~n 33333333333333333333=~p", [{UserId, MapId, Param}]),
					Pid;
				?false ->
					{?ok, MapPid} 		= boss_mod:create_map(MapId, Room, ?CONST_MAP_TYPE_BOSS, Param),	%% 初始化地图
					MapPid
			end;
		_ -> 
			?false
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 广播包括机器人
broadcast_room(0, _RoomId, _Packet) -> ?ok;
broadcast_room(MasterNode, RoomId, Packet) ->
	case node() of
		MasterNode -> broadcast_room(RoomId, Packet);
		_ -> rpc:cast(MasterNode, ?MODULE, broadcast_room, [RoomId, Packet])
	end.

broadcast_room(RoomId, Packet) ->
	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
								  BossPlayer#boss_player.room_id == RoomId andalso 
								  BossPlayer#boss_player.exist == ?CONST_SYS_TRUE ->
									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
							 end),
	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
%%	?MSG_DEBUG("~nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb~p", [UserIdList]),
	broadcast_room1(UserIdList, Packet).

broadcast_room_ext(RoomId, Packet) ->
	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
								  BossPlayer#boss_player.room_id == RoomId ->
									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
							 end),
	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
	?MSG_DEBUG("~nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb~p", [UserIdList]),
	broadcast_room1(UserIdList, Packet).

%% 广播不包括机器人
unbroadcast_room(MasterNode, RoomId, Packet) ->
	case node() of
		MasterNode -> unbroadcast_room(RoomId, Packet);
		_ -> rpc:cast(MasterNode, ?MODULE, unbroadcast_room, [RoomId, Packet])
	end.
unbroadcast_room(RoomId, Packet) ->
	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
								  BossPlayer#boss_player.room_id == RoomId andalso 
								  BossPlayer#boss_player.robot == ?false andalso 
								  BossPlayer#boss_player.exist == ?CONST_SYS_TRUE ->
									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
							 end),
	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
	?MSG_DEBUG("~nbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb~p", [UserIdList]),
	broadcast_room1(UserIdList, Packet).

		
broadcast_room1([{UserId, Node}|UserIdList], Packet) ->
	LocalNode			= node(),
	case Node of
		LocalNode ->
			misc_packet:send(UserId, Packet);
		_ ->
			?MSG_DEBUG("6666666666666666666666666666666", []),
			rpc:cast(Node, misc_packet, send, [UserId, Packet])
	end,
	broadcast_room1(UserIdList, Packet);
broadcast_room1([], _Packet) -> ?ok.

get_open_boss() ->
	BossIds	= data_boss:get_boss_id(),
	get_open_boss(BossIds).
get_open_boss([BossId|BossIds]) ->
	case boss_mod:get_boss_data(BossId) of
		BossData when is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> BossData;
				?CONST_BOSS_STATE_START -> BossData;
				?CONST_BOSS_STATE_END -> get_open_boss(BossIds);
				?CONST_BOSS_STATE_CLOSE -> get_open_boss(BossIds)
			end;
		?null -> get_open_boss(BossIds)
	end;
get_open_boss([]) -> ?null.

%% broadcast(RoomId, Packet) ->
%% 	Node			= node(),
%% 	MasterNode		= cross_api:get_master_node(),
%% 	case Node of
%% 		MasterNode -> boss_player_ids(RoomId, Packet);
%% 		_ -> rpc:cast(MasterNode, ?MODULE, boss_player_ids, [RoomId, Packet])
%% 	end.
%% 	broadcast_exist1(UserIdList, Packet).

%% broadcast1([UserId|UserIdList], Packet) ->
%% 	misc_packet:send(UserId, Packet),
%% 	broadcast1(UserIdList, Packet);
%% broadcast1([], _Packet) -> ?ok.

%% broadcast_exist(RoomId, Packet) ->
%% 	Node			= node(),
%% 	MasterNode		= cross_api:get_master_node(),
%% 	case Node of
%% 		MasterNode -> boss_player_exist_ids(RoomId, Packet);
%% 		_ -> rpc:cast(MasterNode, ?MODULE, boss_player_exist_ids, [RoomId, Packet])
%% 	end.
%% 	?MSG_DEBUG("~n 5555555555555555 UserIdList=~p", [UserIdList]),
%% 	broadcast_exist1(UserIdList, Packet).

%% broadcast_exist1([{UserId, Node}|UserIdList], Packet) ->
%% 	LocalNode			= node(),
%% 	case Node of
%% 		LocalNode ->
%% 			misc_packet:send(UserId, Packet);
%% 		_ ->
%% 			?MSG_DEBUG("6666666666666666666666666666666", []),
%% 			rpc:cast(Node, misc_packet, send, [UserId, Packet])
%% 	end,
%% 	broadcast_exist1(UserIdList, Packet);
%% broadcast_exist1([], _Packet) -> ?ok.

%% boss_player_ids(RoomId, Packet) ->
%% 	MatchSpec	= ets:fun2ms(fun(#boss_player{user_id = UserId, room_id = RoomId}) -> UserId end),
%% 	MatchSpec	= ets:fun2ms(fun(BossPlayer) when
%% 								  BossPlayer#boss_player.room_id == RoomId ->
%% 									 {BossPlayer#boss_player.user_id, BossPlayer#boss_player.node}
%% 							 end),
%% 	UserIdList	= ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec),
%% 	broadcast_exist1(UserIdList, Packet).

%% boss_player_exist_ids(RoomId, Packet) ->
%% 	MatchSpec	= ets:fun2ms(fun(#boss_player{user_id = UserId, exist = Exist} = B) when Exist =:= ?CONST_SYS_TRUE -> B end),
%% 	MatchSpec	= ets:fun2ms(fun(CrossIn) when
%% 								  CrossIn#ets_boss_cross_in.room_id == RoomId ->
%% 									 {CrossIn#ets_boss_cross_in.user_id, CrossIn#ets_boss_cross_in.node}
%% 							 end),
%% 	UserIdList = ets_api:select(?CONST_ETS_BOSS_CROSS_IN, MatchSpec),
%% 	?MSG_DEBUG("4444444444444444444444=~p", [UserIdList]),
%% 	broadcast_exist1(UserIdList, Packet).
%% 	L = ets_api:select(?CONST_ETS_BOSS_PLAYER, MatchSpec).
%%     boss_player_exist_ids2(L, []).

%% boss_player_exist_ids2([#boss_player{user_id = UserId, boss_id = BossId}|Tail], OldList) ->
%%     BossId2 = robot_boss_api:get_boss_type(BossId),
%%     BossId2 = 10002,
%%     L = 
%%         case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
%%             #ets_boss_robot_setting{} ->
%%                 OldList;
%%             _ ->
%%                 [UserId|OldList]
%%         end,
%%     boss_player_exist_ids2(Tail, L);
%% boss_player_exist_ids2([], L) ->
%%     L.

get_active_type(?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS)  -> ?CONST_ACTIVE_BOSS1;% 世界BOSSID--酸与 
get_active_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS)   -> ?CONST_ACTIVE_BOSS2;% 世界BOSSID--张角
get_active_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2) -> ?CONST_ACTIVE_BOSS3;% 世界BOSSID--张梁 
get_active_type(?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3) -> ?CONST_ACTIVE_BOSS4;% 世界BOSSID--张宝 
get_active_type(_) -> 0. 

%% boss_api:notice_active_end(10010).
notice_active_end(BossId, RoomId, EndType) ->
	ActiveType	= get_active_type(BossId),
	case active_api:read_by_type(ActiveType) of
		Active when is_record(Active, rec_active) ->
			active_end(Active#rec_active.type,
					   ?CONST_ACTIVE_STATE_OFF,
					   Active#rec_active.module_e,
					   Active#rec_active.func_e,
					   Active#rec_active.args_e,
					   Active#rec_active.msg_e,
					   Active#rec_active.rela, 
					   RoomId, EndType),
			?MSG_ERROR("active_api:active_end(Type, StandardState, Module, Func, Args, MsgId, Rela, RoomId, EndType):~p",
					   [{Active#rec_active.type,
						 ?CONST_ACTIVE_STATE_OFF,
						 Active#rec_active.module_e,
						 Active#rec_active.func_e,
						 Active#rec_active.args_e,
						 Active#rec_active.msg_e,
						 Active#rec_active.rela,
						 RoomId, EndType}]),
			?ok;
		?null -> ?ok
	end.

active_end(Type, StandardState, Module, Func, Args, MsgId, Rela, RoomId, EndType) ->
	case EndType of
		?CONST_BOSS_END_TYPE_DEATH ->
			Packet 				= active_api:msg_end(Type, MsgId), 				
			broadcast_room_ext(RoomId, Packet);
		_ ->
			case ets_api:lookup(?CONST_ETS_ACTIVE, Type) of
				#ets_active{type = Type, state = StandardState} -> 
					Packet = active_api:msg_end(Type, MsgId), 												% 但是发就只发当前的
					broadcast_room_ext(RoomId, Packet),
					?ok;
				_ ->
					active_api:close([Type|Rela]), 															% 要关调所有相关的
					Packet = active_api:msg_end(Type, MsgId), 												% 但是发就只发当前的
					broadcast_room_ext(RoomId, Packet),
					try
						Module:Func(Args),
						?ok
					catch
						_:_ ->
							?ok
					end
			end
	end.

broadcast_boss_close(BossData, EndType, Rank) ->
	RoomId		= BossData#boss_data.room,
	PacketOver	= msg_sc_boss_over(BossData, EndType, Rank),
	PacketEnd	= msg_sc_end_notice(EndType),
	?MSG_DEBUG("ccccccccccccccccccccccc~p", [EndType]),
	broadcast_room(RoomId, <<PacketOver/binary, PacketEnd/binary>>).
%% 	misc_app:broadcast_world(<<PacketOver/binary, PacketEnd/binary>>).

%% BOSS活动结束战报通知
msg_sc_boss_over(BossData, ?CONST_BOSS_END_TYPE_DEATH, Rank) ->
	msg_sc_boss_over_win(BossData, Rank);
msg_sc_boss_over(BossData, ?CONST_BOSS_END_TYPE_TIMEOUT, _Rank) ->
	msg_sc_boss_over_fail(BossData);
msg_sc_boss_over(_BossData, _, _Rnak) ->
	<<>>.

msg_sc_boss_over_win(BossData, Rank) ->
	case boss_mod:get_boss_monster(BossData) of
		BossMonster when is_record(BossMonster, boss_monster) ->
			FinalRank	= lists:sublist(Rank, 3),
			Fun			= fun({UserId, UserName, _, _, _}, AccUserList) ->
								  [{UserId, UserName}|AccUserList]
						  end,
			UserList	= lists:foldl(Fun, [], FinalRank),
			?MSG_DEBUG("~nddddddddddddddddddddddddddddd~p", [UserList]),
			message_api:msg_notice(?TIP_BOSS_OVER_WIN, lists:reverse(UserList), [], [{?TIP_SYS_MONSTER, misc:to_list(BossMonster#boss_monster.monster_id)}]);
		_ -> 
			?MSG_DEBUG("~nddddddddddddddddddddddddddddd~p", [BossData]),
			<<>>
	end.
msg_sc_boss_over_fail(BossData) ->
	case boss_mod:get_boss_monster(BossData) of
		BossMonster when is_record(BossMonster, boss_monster) ->
			message_api:msg_notice(?TIP_BOSS_OVER_FAIL, [], [], [{?TIP_SYS_MONSTER, misc:to_list(BossMonster#boss_monster.monster_id)}]);
		_ -> <<>>
	end.

%% BOSS活动英勇奖通知
msg_sc_first(UserList, ReserveList) ->
	message_api:msg_notice(?TIP_BOSS_FIRST, UserList, [], ReserveList).
%% BOSS活动击杀奖通知
msg_sc_kill(UserList, ReserveList) ->
	message_api:msg_notice(?TIP_BOSS_KILL, UserList, [], ReserveList).
%% BOSS活动击杀奖通知
msg_sc_boss_hp_notice(TipId, UserList, ReserveList) ->
	message_api:msg_notice(TipId, UserList, [], ReserveList).

%% 进入世界BOSS
%%[TimeStart,TimeEnd,Auto,Encourage,RebornTimes,RebornMax,Hurt,Hp,HpMax,Pro,Sex,Name]
msg_sc_enter(BossId, BossData, BossPlayer) ->
	BossMonster	= boss_mod:get_boss_monster(BossData),
	Type	= get_active_type(BossId),
	IsStart = active_api:is_opened(Type),
    {Power, Pro, Sex, Name} = rank_api:get_max_power(),
	Datas	= [
			   BossData#boss_data.id,
			   BossData#boss_data.lv,
			   BossData#boss_data.boss_hp,
			   BossData#boss_data.time_start,
			   BossData#boss_data.time_end,
			   BossPlayer#boss_player.auto,
			   round(BossPlayer#boss_player.encourage*Power/100),
			   BossPlayer#boss_player.reborn_times,
			   10,
			   BossPlayer#boss_player.hurt,
			   BossMonster#boss_monster.monster_id,
			   BossMonster#boss_monster.hp,
			   BossMonster#boss_monster.hp_max,
			   IsStart,
			   Power,
               Pro,
               Sex,
               Name
			  ],
	?MSG_ERROR("enter boss ............[~p|~p|~p|~p]~p~p", [IsStart, Type, BossId, BossPlayer#boss_player.user_id, misc:seconds(), BossData#boss_data.time_end]),
	misc_packet:pack(?MSG_ID_BOSS_SC_ENTER, ?MSG_FORMAT_BOSS_SC_ENTER, Datas).
%% 状态信息
%%[State]
msg_sc_state(State) ->
    misc_packet:pack(?MSG_ID_BOSS_SC_STATE, ?MSG_FORMAT_BOSS_SC_STATE, [State]).
%% 怪物信息
msg_sc_monster_info(MonsterId, Hp, MpMax) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_MONSTER_INFO, ?MSG_FORMAT_BOSS_SC_MONSTER_INFO, [MonsterId, Hp, MpMax]).
%% 退出世界BOSS成功
%% boss_api:msg_sc_quit_ok().
msg_sc_quit_ok() ->
	misc_packet:pack(?MSG_ID_BOSS_SC_QUIT_OK, ?MSG_FORMAT_BOSS_SC_QUIT_OK, []).
%% 自动返回
msg_sc_auto(Auto) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_AUTO, ?MSG_FORMAT_BOSS_SC_AUTO, [Auto]).
%% 鼓舞
msg_sc_encourage(Encourage) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_ENCOURAGE, ?MSG_FORMAT_BOSS_SC_ENCOURAGE, [Encourage]).
%% 浴火重生
msg_sc_reborn(RebornTimes) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_REBORN, ?MSG_FORMAT_BOSS_SC_REBORN, [RebornTimes]).
%% 复活
msg_sc_revive() ->
	misc_packet:pack(?MSG_ID_BOSS_SC_REVIVE, ?MSG_FORMAT_BOSS_SC_REVIVE, []).
%% 个人伤害更新
msg_sc_hurt(Hurt) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_HURT, ?MSG_FORMAT_BOSS_SC_HURT, [Hurt]).
%% 排名奖励
msg_sc_reward(Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_REWARD, ?MSG_FORMAT_BOSS_SC_REWARD,
					 [Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience]).
%% 世界BOSS冷却时间
msg_sc_exit_cd(MasterNode, RoomId, Time) ->
	case node() of
		MasterNode ->
			case boss_mod:get_boss_data(RoomId) of
				#boss_data{state = State}
				  when State =:= ?CONST_BOSS_STATE_OPEN orelse State =:= ?CONST_BOSS_STATE_START->
					misc_packet:pack(?MSG_ID_BOSS_SC_EXIT_CD, ?MSG_FORMAT_BOSS_SC_EXIT_CD, [Time]);
				_ -> <<>>
			end;
		_ ->
			case rpc:call(MasterNode, boss_mod, get_boss_data, [RoomId]) of
				#boss_data{state = State}
				  when State =:= ?CONST_BOSS_STATE_OPEN orelse State =:= ?CONST_BOSS_STATE_START->
					misc_packet:pack(?MSG_ID_BOSS_SC_EXIT_CD, ?MSG_FORMAT_BOSS_SC_EXIT_CD, [Time]);
				_ -> <<>>
			end
	end.
%% 世界BOSS替身状态
msg_cs_doll_flag(BossId,Flag) ->
	misc_packet:pack(?MSG_ID_BOSS_CS_DOLL_FLAG, ?MSG_FORMAT_BOSS_CS_DOLL_FLAG, [BossId,Flag]).
%% 世界BOSS开启通知(广播)
msg_sc_open_notice() ->
	misc_packet:pack(?MSG_ID_BOSS_SC_OPEN_NOTICE, ?MSG_FORMAT_BOSS_SC_OPEN_NOTICE, []).
%% 世界BOSS开始通知(广播)
msg_sc_start_notice() ->
	misc_packet:pack(?MSG_ID_BOSS_SC_START_NOTICE, ?MSG_FORMAT_BOSS_SC_START_NOTICE, []).
%% 世界BOSS结束通知(广播)
msg_sc_end_notice(EndType) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_END_NOTICE, ?MSG_FORMAT_BOSS_SC_END_NOTICE, [EndType]).
%% 世界BOSS怪物血量通知(广播)
msg_sc_monster_hp_notice(UserId,UserName,Pro,Sex,MonsterId,Tag) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_MONSTER_HP_NOTICE, ?MSG_FORMAT_BOSS_SC_MONSTER_HP_NOTICE, [UserId,UserName,Pro,Sex,MonsterId,Tag]).
%% 移除怪物通知(广播)
msg_sc_remove_monster_notice(MonsterId) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_REMOVE_MONSTER_NOTICE, ?MSG_FORMAT_BOSS_SC_REMOVE_MONSTER_NOTICE, [MonsterId]).
%% 更新怪物通知(广播)
msg_sc_update_monster_notice(Time, BossData) ->
	if
		Time rem ?CONST_BOSS_INTERVAL_HP =:= 0 ->
			case boss_mod:get_boss_monster(BossData) of
				BossMonster when is_record(BossMonster, boss_monster) ->
					misc_packet:pack(?MSG_ID_BOSS_SC_UPDATE_MONSTER_NOTICE,
									 ?MSG_FORMAT_BOSS_SC_UPDATE_MONSTER_NOTICE,
									 [BossMonster#boss_monster.monster_id, BossMonster#boss_monster.hp]);
				_ -> <<>>
			end;
		?true -> <<>>
	end.
%% 排行数据通知(广播)
msg_sc_rank_notice(RoomId, Time) ->
%%	?MSG_DEBUG("!!!!!!!!!!!!!!!!!!!!!!~p", [{RoomId, Time}]),
	if
		Time rem ?CONST_BOSS_INTERVAL_RANK =:= 0 ->
%%			?MSG_DEBUG("!!!!!!!!!!!!!!!!!!!!!!~p", [{RoomId, Time}]),
			{Top, _List}	= boss_mod:boss_rank(RoomId),
%%			?MSG_DEBUG("!!!!!!!!!!!!!!!!!!!!!!~p", [Top]),
			misc_packet:pack(?MSG_ID_BOSS_SC_RANK_NOTICE, ?MSG_FORMAT_BOSS_SC_RANK_NOTICE, [Top]);
		?true -> <<>>
	end.
%% 替身奖励 
%%[Gold,Exp,Meritorious]
msg_sc_auto_reward(Gold,Exp,Meritorious) ->
	misc_packet:pack(?MSG_ID_BOSS_SC_AUTO_REWARD, ?MSG_FORMAT_BOSS_SC_AUTO_REWARD, [Gold,Exp,Meritorious]).
	
%% 替身元宝数
%%[BossId,Cash]
msg_sc_doll_cash(BossId,Cash) ->
    misc_packet:pack(?MSG_ID_BOSS_SC_DOLL_CASH, ?MSG_FORMAT_BOSS_SC_DOLL_CASH, [BossId,Cash]).