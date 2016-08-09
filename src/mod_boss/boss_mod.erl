%% Author: cobain
%% Created: 2013-1-8
%% Description: TODO: Add description to boss_mod
-module(boss_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.robot.hrl").
-include("../../include/record.battle.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([do_boss_start/1, do_boss_end/2, do_boss_close/1, do_refresh_monster/7, do_reward_first/4,
		 boss_level_up/2, boss_rank/1, set_hp_tuple/2, set_hp/2, do_reward_last/5]).
-export([
		 check_boss_open/1, check_boss_start/1,
		 check_doll/3, check_cd_exit/2, check_player_state/1, check_cd_death/2, check_vip/1, check_encourage_max/2,
		 check_reborn_times/2, check_money/4 %, do_confirm_first/2
		]).
-export([get_boss_data/1, set_boss_data/1,
		 get_boss_player/1, set_boss_player/1,
		 get_boss_monster/1, get_boss_monster/2,
		 record_boss_player/5, record_boss_monster/2,
		 check_boss_id/1]).

-export([enter_boss_map/7, init_monster_by_room/3, do_start_battle/5]).
-export([create_map/4, init_boss_data_state/0]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 跨服进入世界boss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enter_boss_map(UserId, Room, Node, ServIndex, LvPhase, _BossPlayer, BossId) ->
	ets:insert(?CONST_ETS_BOSS_CROSS_IN, #ets_boss_cross_in{node = Node, user_id = UserId, serv_index = ServIndex, 
															lv_phase = LvPhase, room_id = Room}),                        %%记录跨到本服的玩家
	?MSG_DEBUG("~n 33333333333333333333333333333~p", [{Room}]),
	case get_boss_data(Room) of						   %% 这个房间有boss数据 
		BossData when is_record(BossData, boss_data) ->
			?MSG_DEBUG("~n 33333333333333333333333333333~p", [BossData#boss_data.id]),
			MapId				= BossData#boss_data.map_id,
%% 			BossPlayer1			= BossPlayer#boss_player{room_id = Room, map_id = MapId, serv_id = ServIndex},
%% 			set_boss_player(BossPlayer1),
			{MapId, BossData};
		_ ->										   %% 新房间 无boss数据 初始化
			?MSG_DEBUG("~n 33333333333333333333333333333", []),
			case boss_serv:get_boss_cross_map_id(UserId, Room, LvPhase, BossId) of
				{MapId1, BossData1} ->
					BossId1				= BossData1#boss_data.id,	
					?MSG_DEBUG("~n444444444444444444444444444444444444444444444444444~p", [BossId1]),
%% 					BossPlayer1			= BossPlayer#boss_player{boss_id = BossId1, room_id = Room, map_id = MapId1, 
%% 																 serv_id = ServIndex},
%% 					set_boss_player(BossPlayer1),
					{MapId1, BossData1};
				_ ->
					throw({?error, ?TIP_COMMON_BAD_ARG})
			end
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 跨服根据房间初始化boss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_monster_by_room(Room, LvPhase, BossId) ->
	BossId1			= check_boss_id(BossId),
	Node			= node(),
	?MSG_DEBUG("~n 111111111111111111 ~p", [{BossId, BossId1, LvPhase}]),
	case data_boss:get_boss_data({BossId1, LvPhase}) of                                                         
		BossData when is_record(BossData, boss_data) ->
			MapId				= BossData#boss_data.map_id,
			Param				= #map_param{ad1 = MapId},
			{?ok, _Pid} 		= create_map(MapId, Room, ?CONST_MAP_TYPE_BOSS, Param),							%% 初始化地图
			BossConfig			= data_boss:get_boss_config(),
			BossData2			= init_boss_monster(BossData, BossConfig#rec_boss_config.broadcast_tag),
			TimeStart			= get_boss_start_time(),														% 开始时间戳
			TimeEnd 			= get_boss_end_time(),															% 结束时间戳
			State				= init_boss_data_state(),														% 状态
			NewBossData			= BossData2#boss_data{room = Room, time_start = TimeStart, time_end = TimeEnd, 
													  state = State, node = Node, id = BossId1, 
													  key = {BossId1, LvPhase}},
			set_boss_data(NewBossData),
			{MapId, NewBossData};
		A -> 
			?MSG_DEBUG("~n44444444444444 =~p", [A]),
			?ok
	end.

%% 初始化boss状态
init_boss_data_state() ->
	TimeStart		  = get_boss_start_time(),
	Time			  = misc:seconds(),
	if
		Time >= TimeStart -> ?CONST_BOSS_STATE_START;
		?true -> ?CONST_BOSS_STATE_OPEN
	end.

%% 获取boss开始时间
get_boss_start_time() ->
	case get_boss_data(0) of
		#boss_data{time_start = TimeStart} -> TimeStart;
		_ -> misc:seconds()
	end.

%% 获取boss结束时间
get_boss_end_time() ->
	BossConfig			= data_boss:get_boss_config(),
	case get_boss_data(0) of
		#boss_data{time_end = TimeEnd} -> TimeEnd;
		_ -> misc:seconds() + BossConfig#rec_boss_config.time_end
	end.

%% 获取boss的id(以防万一)
check_boss_id(0) ->
	{Hour, _Min, _Sec}		= misc:time(),
	Week					= misc:get_date(),
	case Hour < 12 of		%% 上午
		?true  ->  ?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS;
		?false -> 
			if
				Week == 1 orelse Week == 3 orelse Week == 5 -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2;
				Week == 2 orelse Week == 4 orelse Week == 6 -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3;
				?true -> ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS
			end
	end;
check_boss_id(BossId) -> BossId.

%% 获取世界BOSS的怪物
init_boss_monster(BossData, BroadcastTag) ->
	BossMonsters	= init_boss_monster(BossData#boss_data.monsters, BroadcastTag, []),
	BossHp			= init_boss_hp(BossMonsters, 0),
	BossData#boss_data{
					   monsters 	= BossMonsters,
					   boss_hp		= BossHp
					  }.
init_boss_monster([MonsterId|MonstersIds], BroadcastTag, Acc) ->
	BossManster		= record_boss_monster(BroadcastTag, MonsterId),
	init_boss_monster(MonstersIds, BroadcastTag, [BossManster|Acc]);
init_boss_monster([], _BroadcastTag, Acc) ->
	lists:reverse(Acc).

init_boss_hp([BossMonster|BossMonsters], Hp)
  when is_record(BossMonster, boss_monster) ->
	init_boss_hp(BossMonsters, BossMonster#boss_monster.hp_max + Hp);
init_boss_hp([BossMonster|BossMonsters], Hp) ->
	?MSG_ERROR("ERROR BossMonster:~p Is Not Exist", [BossMonster]),
	init_boss_hp(BossMonsters, Hp);
init_boss_hp([], Hp) -> Hp.

%% 跨服初始化boss时同时初始化地图
create_map(MapId, RoomId, ?CONST_MAP_TYPE_BOSS, Param) ->
	?MSG_DEBUG("~n 4444444444444444444=~p", [{MapId, RoomId}]),
	{?ok, MapPid} = map_sup:start_child_map_serv(MapId, ?CONST_MAP_TYPE_BOSS, Param),
    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
	Room 		  = #ets_boss_cross_room{room = RoomId, map_pid = MapPid, map_id = MapId},
    ets:insert(?CONST_ETS_BOSS_CROSS_ROOM, Room),
    {?ok, MapPid}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 跨服战斗
do_start_battle(Player, BossData, Param, MasterNode, RoomId) ->
	case get_boss_monster(BossData) of
		BossMonster  when is_record(BossMonster, boss_monster) ->
			case battle_api:start(Player, BossMonster#boss_monster.monster_id,
								  Param#param{battle_type = ?CONST_BATTLE_BOSS,
											  ad1 = BossMonster#boss_monster.monster_id,
											  ad3 = BossMonster#boss_monster.hp_tuple
											 }) of
				{?ok, Player2} ->
					?MSG_DEBUG("~ntttttttttttttttttttttttttttttttttttt~p", [RoomId]),
					boss_serv:reward_first_cast(MasterNode, RoomId, Player2, BossMonster#boss_monster.monster_id),
					%% 							boss_api:reward_first(Player2, BossData, BossMonster, 0),
					{?ok, Player2};
				X ->
					?MSG_DEBUG("~ntttttttttttttttttttttttttttttttttttt~p", [X]),
					{?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 刷新boss
do_refresh_monster(BossData, UserId, BossPlayer, UserName, MonsterId, Hurt, HurtTuple) when is_record(BossData, boss_data)->
	NewBossData		= BossData#boss_data{state = 2},
	case NewBossData#boss_data.state of
		?CONST_BOSS_STATE_OPEN -> {?error, ?TIP_BOSS_NOT_OPEN};% 世界BOSS尚未开启
		?CONST_BOSS_STATE_START ->
			case get_boss_monster(BossData) of
				BossMonster
				  when BossMonster#boss_monster.monster_id =:= MonsterId ->
					do_refresh_monster2(BossData, UserId, BossPlayer, UserName, MonsterId, Hurt, HurtTuple);
				_ -> {?error, 110}% 该怪物已死
			end;
		?CONST_BOSS_STATE_END -> {?error, ?TIP_BOSS_CLOSE};% 世界BOSS已结束
		?CONST_BOSS_STATE_CLOSE -> {?error, ?TIP_BOSS_CLOSE};% 世界BOSS已结束
		5 -> {?error, ?TIP_BOSS_CLOSE}% 世界BOSS已结束
	end.

do_refresh_monster2(BossData, UserId, UserName, BossPlayer, MonsterId, Hurt, HurtTuple) ->
	Pro				= BossPlayer#boss_player.pro,
	Sex				= BossPlayer#boss_player.sex,
	MaterNode		= BossPlayer#boss_player.master_node,
	RoomId			= BossPlayer#boss_player.room_id,
	BossMonsters	= BossData#boss_data.monsters,
	BossMonster		= get_boss_monster(BossData),
	BossMonster2	= BossMonster#boss_monster{hp_tuple = set_hp_tuple(BossMonster#boss_monster.hp_tuple, HurtTuple)},
	case set_hp(BossMonster2#boss_monster.hp, Hurt) of
		0 ->
			BossMonster3		= BossMonster2#boss_monster{hp = 0},
			?MSG_DEBUG("~n3333333333333333333333~p", [{Hurt, BossMonster2}]),
			BossMonster4		= boss_hp_notice(UserId, UserName, Pro, Sex, RoomId, BossMonster3, MaterNode, RoomId),
			PacketRemove		= boss_api:msg_sc_remove_monster_notice(BossMonster4#boss_monster.monster_id),
			[_|BossMonsters2]	= BossMonsters,
			BossData2			= BossData#boss_data{monsters = BossMonsters2},
			{BossData3, PacketMonster1}=
				case BossData2#boss_data.monsters of
					[] ->
						PacketMonster	= <<>>,
						BossData2Temp	= BossData2#boss_data{state = ?CONST_BOSS_STATE_END, end_type = ?CONST_BOSS_END_TYPE_DEATH},
						{BossData2Temp, PacketMonster};
					[BossMonsterNew|_] ->
						PacketMonster	= boss_api:msg_sc_monster_info(BossMonsterNew#boss_monster.monster_id,
																	   BossMonsterNew#boss_monster.hp,
																	   BossMonsterNew#boss_monster.hp_max),
						{BossData2, PacketMonster}
				end,
			boss_api:unbroadcast_room(MaterNode, RoomId, <<PacketRemove/binary, PacketMonster1/binary>>),
			
			%% 				boss_api:reward_last(MaterNode, RoomId, UserId, MonsterId, BossData#boss_data.reward_kill),
			boss_serv:reward_last_cast(MaterNode, RoomId, UserId, MonsterId, BossData3);
		Hp ->
			?MSG_DEBUG("~n3333333333333333333333~p", [{Hurt, Hp, BossMonster2}]),
			BossMonster3		= BossMonster2#boss_monster{hp = Hp},
			BossMonster4		= boss_hp_notice(UserId, UserName, Pro, Sex, RoomId, BossMonster3, MaterNode, RoomId),
			BossMonsters2		= lists:keyreplace(BossMonster4#boss_monster.monster_id,
												   #boss_monster.monster_id,
												   BossMonsters,
												   BossMonster4),
			BossData4			= BossData#boss_data{monsters = BossMonsters2},
			rpc:cast(MaterNode, ?MODULE, set_boss_data, [BossData4])
	end,
	?ok.

boss_hp_notice(UserId, UserName, Pro, Sex, RoomId, BossMonster, MasterNode, RoomId) ->
	{
	 Tags2, PacketBoss, PacketWorld
	}	= boss_hp_notice(BossMonster#boss_monster.broadcast_tag, UserId, UserName, Pro, Sex,
						 BossMonster#boss_monster.monster_id, BossMonster#boss_monster.hp, [], <<>>, <<>>),
	boss_api:unbroadcast_room(MasterNode, RoomId, <<PacketBoss/binary, PacketWorld/binary>>),
%% 	boss_api:broadcast_room(RoomId, PacketWorld),
%% 	misc_app:broadcast_world(PacketWorld),
	BossMonster#boss_monster{broadcast_tag = Tags2}.

boss_hp_notice([{HpTag, Tag, TipId}|Tags], UserId, UserName, Pro, Sex, MonsterId, Hp, AccTag, AccPacketBoss, AccPacketWorld)
  when HpTag >= Hp ->
	PacketBoss		= boss_api:msg_sc_monster_hp_notice(UserId, UserName, Pro, Sex, MonsterId, Tag),
	PacketWorld		= boss_api:msg_sc_boss_hp_notice(TipId, [{UserId, UserName}], [{?TIP_SYS_MONSTER, misc:to_list(MonsterId)}]),
	boss_hp_notice(Tags, UserId, UserName, Pro, Sex, MonsterId, Hp, AccTag,
				   <<AccPacketBoss/binary, PacketBoss/binary>>,
				   <<AccPacketWorld/binary, PacketWorld/binary>>);
boss_hp_notice([{HpTag, Tag, TipId}|Tags], UserId, UserName, Pro, Sex, MonsterId, Hp, AccTag, AccPacketBoss, AccPacketWorld) ->
	boss_hp_notice(Tags, UserId, UserName, Pro, Sex, MonsterId, Hp, [{HpTag, Tag, TipId}|AccTag], AccPacketBoss, AccPacketWorld);
boss_hp_notice([], _UserId, _UserName, _Pro, _Sex, _MonsterId, _Hp, AccTag, AccPacketBoss, AccPacketWorld) ->
	{lists:reverse(AccTag), AccPacketBoss, AccPacketWorld}.

set_hp(0, _Hurt) -> 0;
set_hp(Hp, 0) -> Hp;
set_hp(Hp, Hurt) -> misc:betweet(Hp - Hurt, 0, Hp).

set_hp_tuple({Hp1, Hp2, Hp3, Hp4, Hp5, Hp6, Hp7, Hp8, Hp9},
			 {Hurt1, Hurt2, Hurt3, Hurt4, Hurt5, Hurt6, Hurt7, Hurt8, Hurt9}) ->
	{
	 set_hp(Hp1, Hurt1), set_hp(Hp2, Hurt2), set_hp(Hp3, Hurt3),
	 set_hp(Hp4, Hurt4), set_hp(Hp5, Hurt5), set_hp(Hp6, Hurt6),
	 set_hp(Hp7, Hurt7), set_hp(Hp8, Hurt8), set_hp(Hp9, Hurt9)
	}.

%% 
do_boss_start(BossData) when is_record(BossData, boss_data) ->
	BossData2	= BossData#boss_data{state = ?CONST_BOSS_STATE_START},
	set_boss_data(BossData2),
	?ok;
do_boss_start(_) -> {?error, ?TIP_BOSS_NOT_OPEN}.          % 世界BOSS尚未开启
%% 	case get_boss_data(BossId) of
%% 		BossData when is_record(BossData, boss_data) ->
%% 			BossData2	= BossData#boss_data{state = ?CONST_BOSS_STATE_START},
%% 			set_boss_data(BossData2),
%% 			?ok;
%% 		_ -> {?error, ?TIP_BOSS_NOT_OPEN}% 世界BOSS尚未开启
%% 	end.
%% 
do_boss_end(BossData, EndType) when is_record(BossData, boss_data) ->
	BossData2	= BossData#boss_data{state 		= ?CONST_BOSS_STATE_END,
									 end_type 	= EndType},
	set_boss_data(BossData2),
	?ok;
do_boss_end(_, _) ->{?error, ?TIP_BOSS_NOT_OPEN}.       % 世界BOSS尚未开启
%% 	case get_boss_data(RoomId) of
%% 		BossData when is_record(BossData, boss_data) ->
%% 			BossData2	= BossData#boss_data{state 		= ?CONST_BOSS_STATE_END,
%% 											 end_type 	= EndType},
%% 			set_boss_data(BossData2),
%% 			?ok;
%% 		_ -> {?error, ?TIP_BOSS_NOT_OPEN}% 世界BOSS尚未开启
%% 	end.

%% 
do_boss_close(BossData) when is_record(BossData, boss_data) ->
	BossData2	= BossData#boss_data{state = ?CONST_BOSS_STATE_CLOSE},
	set_boss_data(BossData2),
%% 	rpc:cast(MasterNode, ?MODULE, set_boss_data, BossData2),
	?ok;
do_boss_close(_) -> {?error, ?TIP_BOSS_NOT_OPEN}.               % 世界BOSS尚未开启

%% boss_level_up(BossId) ->
%% 	case ets_api:lookup(?CONST_ETS_BOSS, BossId) of
%% 		{BossId, Lv} ->
%% 			case data_boss:get_boss_data({BossId, Lv + 1}) of
%% 				BossData when is_record(BossData, boss_data) ->
%% 					boss_level_up(BossId, BossData#boss_data.lv);
%% 				_ -> ?ok
%% 			end;
%% 		_ -> ?ok
%% 	end.
%% boss_level_up(BossId, Lv) ->
%% 	SQL	= <<"UPDATE `game_boss` SET `lv` = ", (misc:to_binary(Lv))/binary, " WHERE `boss_id` = ", (misc:to_binary(BossId))/binary, ";">>,
%% 	mysql_api:fetch_cast(SQL),
%% 	ets_api:insert(?CONST_ETS_BOSS, {BossId, Lv}).

boss_level_up(BossId, Lv) ->
	BossLv	= Lv + 1,
	case data_boss:get_boss_data({BossId, BossLv}) of
		BossData when is_record(BossData, boss_data) ->
			mysql_api:fetch_cast(<<"UPDATE `game_boss` SET `lv` = ", (misc:to_binary(BossLv))/binary, ";">>),
			ets_api:insert(?CONST_ETS_BOSS, {boss_lv, BossLv}),
			?ok;
		_ -> ?ok
	end.

do_reward_first(MasterNode, RoomId, Player, MonsterId) ->
	?MSG_DEBUG("~nssssssssssssssssssssssssss ~p", [{ RoomId, MonsterId}]),
	UserId						= Player#player.user_id,
	case rpc:call(MasterNode, ?MODULE, get_boss_data, [RoomId]) of
			BossData when is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> {?error, ?TIP_BOSS_NOT_OPEN};% 世界BOSS尚未开启
				?CONST_BOSS_STATE_START ->
					case boss_mod:get_boss_monster(BossData) of
						BossMonster
						  when BossMonster#boss_monster.monster_id =:= MonsterId andalso
							   BossMonster#boss_monster.first == 0 ->
							BossMonster2	= BossMonster#boss_monster{first = UserId},
							BossMonsters	= BossData#boss_data.monsters,
							BossMonsters2	= lists:keyreplace(MonsterId, #boss_monster.monster_id, BossMonsters, BossMonster2),
							BossData2		= BossData#boss_data{monsters = BossMonsters2, kill_user = 0},
							rpc:cast(MasterNode, ?MODULE, set_boss_data, [BossData2]),
							?MSG_DEBUG("~nssssssssssssssssssssssssss ~p", [{RoomId, MonsterId}]),
							IsRobot			= is_robot(UserId),
							boss_api:reward_first(MasterNode, Player, BossData2, BossMonster, IsRobot);
						_ -> {?error, 110}% 该怪物已死
					end;
				?CONST_BOSS_STATE_END -> {?error, ?TIP_BOSS_CLOSE};% 世界BOSS已结束
				?CONST_BOSS_STATE_CLOSE -> {?error, ?TIP_BOSS_CLOSE};% 世界BOSS已结束
				5 -> {?error, ?TIP_BOSS_CLOSE}% 世界BOSS已结束
			end;
		_ -> {?error, ?TIP_BOSS_NOT_OPEN}% 世界BOSS尚未开启
	end.

do_reward_last(MasterNode, RoomId, UserId, MonsterId, BossData) ->
	case node() of
		MasterNode ->
			case BossData#boss_data.kill_user of
				0 ->
					BossData2		= BossData#boss_data{kill_user = UserId},
					set_boss_data(BossData2),
					boss_api:reward_last(MasterNode, RoomId, UserId, MonsterId, BossData#boss_data.reward_kill);
				_ ->
					set_boss_data(BossData)
			end;
		_ ->
			case BossData#boss_data.kill_user of
				0 ->
					BossData2		= BossData#boss_data{kill_user = UserId},
					rpc:cast(MasterNode, ?MODULE, set_boss_data, [BossData2]),
					boss_api:reward_last(MasterNode, RoomId, UserId, MonsterId, BossData2#boss_data.reward_kill);
				_ ->
					rpc:cast(MasterNode, ?MODULE, set_boss_data, [BossData])
			end
	end.
					
is_robot(UserId) ->
	case get_boss_player(UserId) of
		#boss_player{robot = Robot} -> Robot;
		_ -> ?false
	end.
	
%% 	Node		= cross_api:get_master_node(),
%% 	Lv							= (Player#player.info)#info.lv,
%% 	case rpc:call(MasterNode, ?MODULE, get_boss_data, [RoomId]) of
		%% 	case get_boss_data(BossId) of
%% 		BossData when is_record(BossData, boss_data) ->
%% 			case BossData#boss_data.state of
%% 				?CONST_BOSS_STATE_OPEN -> {?error, ?TIP_BOSS_NOT_OPEN};% 世界BOSS尚未开启
%% 				?CONST_BOSS_STATE_START ->
%% 					case boss_mod:get_boss_monster(BossData) of
%% 						BossMonster
%% 						  when BossMonster#boss_monster.monster_id =:= MonsterId andalso
%% 							   BossMonster#boss_monster.first == 0 ->
%% 							BossMonster2	= BossMonster#boss_monster{first = UserId},
%% 							BossMonsters	= BossData#boss_data.monsters,
%% 							BossMonsters2	= lists:keyreplace(MonsterId, #boss_monster.monster_id, BossMonsters, BossMonster2),
%% 							BossData2		= BossData#boss_data{monsters = BossMonsters2},
%% 							rpc:cast(MasterNode, ?MODULE, set_boss_data, [BossData2]),
%% 							set_boss_data(BossData2),
%% 							?MSG_DEBUG("~nssssssssssssssssssssssssss ~p", [{ RoomId, MonsterId}]),
%% 							boss_api:reward_first(Player, BossData2, BossMonster, ?CONST_SYS_FALSE);
%% 						_ -> {?error, 110}% 该怪物已死
%% 					end;
%% 				?CONST_BOSS_STATE_END -> {?error, ?TIP_BOSS_CLOSE};% 世界BOSS已结束
%% 				?CONST_BOSS_STATE_CLOSE -> {?error, ?TIP_BOSS_CLOSE}% 世界BOSS已结束
%% 			end;
%% 		_ -> {?error, ?TIP_BOSS_NOT_OPEN}% 世界BOSS尚未开启
%% 	end.

%% do_confirm_first(UserId, BossId) ->
%%     case get_boss_data(BossId) of
%%         BossData when is_record(BossData, boss_data) ->
%%             case boss_mod:get_boss_monster(BossData) of
%%                 ?null -> {?error, ?TIP_COMMON_NO_THIS_MON};
%%                 BossMonster when BossMonster#boss_monster.first =:= 0 ->
%%                      Gold        = BossData#boss_data.reward_valiant,
%%                      UserName    = player_api:get_name(UserId),
%%                      Packet      = boss_api:msg_sc_first([{UserId, UserName}],
%%                                                          [{?TIP_SYS_MONSTER, misc:to_list(BossMonster#boss_monster.monster_id)},
%%                                                           {?TIP_SYS_COMM, misc:to_list(Gold)}]),
%%                      misc_app:broadcast_world(Packet),
%%                      BossId2 = robot_boss_api:get_boss_type(BossId),
%%                      case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}) of
%%                          #ets_boss_robot_setting{bgold = OldBGold} ->
%%                              ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId2, UserId}, [{#ets_boss_robot_setting.bgold, OldBGold+Gold}]),
%%                              ok;
%%                          _ ->
%%                              player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_BOSS_REWARD_FIRST),
%%                              do_reward_first(BossData#boss_data.id, UserId, BossMonster#boss_monster.monster_id)
%%                     end;
%%                 _ ->
%%                     ok
%%             end;
%%         _ -> ok
%%     end.

%% 检查世界BOSS是否已开启
check_boss_open(BossId) ->
	case get_boss_data(BossId) of
		BossData when is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> BossData;
				?CONST_BOSS_STATE_START -> BossData;
				?CONST_BOSS_STATE_END -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				?CONST_BOSS_STATE_CLOSE -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				5 -> throw({?error, ?TIP_BOSS_CLOSE})% 世界BOSS已结束
			end;
		_ -> throw({?error, ?TIP_BOSS_NOT_OPEN})% 世界BOSS尚未开启
	end.

%% 检查世界BOSS是否已开始
check_boss_start(BossId) ->
	case get_boss_data(BossId) of
		BossData when is_record(BossData, boss_data) ->
			case BossData#boss_data.state of
				?CONST_BOSS_STATE_OPEN -> throw({?error, ?TIP_BOSS_NOT_OPEN});% 世界BOSS尚未开启
				?CONST_BOSS_STATE_START -> BossData;
				?CONST_BOSS_STATE_END -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				?CONST_BOSS_STATE_CLOSE -> throw({?error, ?TIP_BOSS_CLOSE});% 世界BOSS已结束
				5 -> throw({?error, ?TIP_BOSS_CLOSE})% 世界BOSS已结束
			end;
		_ -> throw({?error, ?TIP_BOSS_NOT_OPEN})% 世界BOSS尚未开启
	end.

%% 检查世界BOSS替身娃娃
check_doll(_UserId, _BossId, ?CONST_SYS_TRUE) -> ?ok;
check_doll(UserId, BossId, _) ->
	case ets_api:lookup(?CONST_ETS_BOSS_DOLL, UserId) of
		?null -> ?ok;
		{UserId, BossIds} ->
			case lists:member(BossId, BossIds) of
				?true -> throw({?error, ?TIP_BOSS_DOLL});% 已购买替身娃娃，不能进入
				?false -> ?ok
			end
	end.

%% 检查退出CD
check_cd_exit(Time, TimeStamp) ->
	if
		Time >= TimeStamp -> ?ok;
		?true -> throw({?error, ?TIP_BOSS_CD_EXIT})% 退出世界BOSS时间限制
	end.

%% 检查玩家状态
check_player_state(Player) ->
	case player_state_api:is_fighting(Player) of
		?true ->
			throw({?error, ?TIP_COMMON_STATE_FIGHTING});
		_ -> ?ok
	end.

%% 检查死亡CD
check_cd_death(Time, #boss_player{cd_death = TimeStamp, reborn = Reborn}) ->
	if
		Time >= TimeStamp -> ?ok;
		?true ->
			case Reborn of
				?CONST_SYS_TRUE -> ?ok;
				?CONST_SYS_FALSE -> throw({?error, ?TIP_BOSS_CD_DEATH})
			end
	end.
check_vip(?CONST_SYS_TRUE) -> ?ok;
check_vip(_) -> throw({?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}). % VIP等级不足

check_encourage_max(EncourageMax, Encourage) ->
	if
		EncourageMax > Encourage -> ?ok;
		?true -> throw({?error, ?TIP_BOSS_ENCOURAGE_MAX})% 鼓舞达到上限
	end.

check_reborn_times(RebornMax, RebornTimes) ->
	if
		RebornMax > RebornTimes -> ?ok;
		?true -> throw({?error, ?TIP_BOSS_REBORN_TIMES_MAX})% 浴火重生次数达到上限
	end.

check_money(_UserId, 0, _IsRobot, _BossId) -> ?ok;
check_money(UserId, Value, ?true, BossId) ->
    case robot_boss_api:check_money(UserId, Value, BossId) of
        ?ok ->
            ?ok;
        _ ->
            throw({?error, ?TIP_BOSS_CASH_NOT_ENOUGH, Value})% 元宝不足
    end;
check_money(UserId, Value, ?false, _BossId) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_CASH, Value) of
        {?ok, _, ?true} ->
            ?ok;
        _ ->
            throw({?error, ?TIP_BOSS_CASH_NOT_ENOUGH, Value})% 元宝不足
    end.

boss_rank(RoomId) ->
	MS		= ets:fun2ms(fun(#boss_player{user_name = UserName, hurt = Hurt, room_id = RoomId1}) 
							  when RoomId == RoomId1  -> {UserName, Hurt} end),
	L		= sort(ets_api:select(?CONST_ETS_BOSS_PLAYER, MS)),
	Top10	= if length(L) >= 10 -> {Top, _} = lists:split(10, L), Top; ?true -> L end,
	{Top10, L}.

%% 快速排序
sort([{UserName, Hurt}|L]) ->
	sort([{GTUserName, GTHurt} || {GTUserName, GTHurt} <- L, GTHurt >= Hurt])
		++ [{UserName, Hurt}] ++
	sort([{LTUserName, LTHurt} || {LTUserName, LTHurt} <- L, LTHurt <  Hurt]);
sort([]) -> [].


get_boss_data(RoomId) ->
	ets_api:lookup(?CONST_ETS_BOSS_DATA, RoomId).
set_boss_data(BossData) ->
	ets_api:insert(?CONST_ETS_BOSS_DATA, BossData).
%% 	Node			= node(),
%% 	MasterNode		= cross_api:get_master_node(),
%% 	case Node of
%% 		MasterNode ->
%% 			ets_api:insert(?CONST_ETS_BOSS_DATA, BossData);
%% 		_ ->
%% 			ets_api:insert(?CONST_ETS_BOSS_DATA, BossData),
%% 			rpc:cast(MasterNode, ets_api, insert, [?CONST_ETS_BOSS_DATA, BossData])
%% 	end.

get_boss_player(UserId) ->
	ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId).
set_boss_player(BossPlayer) ->
	Node					= node(),
	MasterNode				= BossPlayer#boss_player.master_node,
	case Node of
		MasterNode ->
			ets_api:insert(?CONST_ETS_BOSS_PLAYER, BossPlayer);
		_ ->
			ets_api:insert(?CONST_ETS_BOSS_PLAYER, BossPlayer),
			rpc:cast(MasterNode, ets_api, insert, [?CONST_ETS_BOSS_PLAYER, BossPlayer])
	end.

get_boss_monster(BossData) ->
	case BossData#boss_data.monsters of
		[BossMonster|_] when is_record(BossMonster, boss_monster) ->
			BossMonster;
		_ -> ?null
	end.

get_boss_monster(BossData, MonsterId) ->
	case lists:keyfind(MonsterId, #boss_monster.monster_id, BossData#boss_data.monsters) of
		BossMonster when is_record(BossMonster, boss_monster) -> BossMonster;
		_ -> ?null
	end.

%% 获取怪物组生命总和
get_monster_group_hp(MonsterId) ->
	case monster_api:monster(MonsterId) of
		Monster when is_record(Monster, monster) ->
			Camp		= Monster#monster.camp,
			HpTupleTemp	= erlang:make_tuple(tuple_size(Camp#camp.position), 0, []),
			HpTuple		= get_monster_group_hp(misc:to_list(Camp#camp.position), HpTupleTemp),
			HpMax		= lists:sum(misc:to_list(HpTuple)),
			{?ok, HpMax, HpTuple};
		?null -> {?error, ?TIP_COMMON_NO_THIS_MON}
	end.

get_monster_group_hp([#camp_pos{idx = Idx, type = ?CONST_SYS_MONSTER, id = MonsterId}|Position], HpTuple) ->
	case monster_api:monster(MonsterId) of
		Monster when is_record(Monster, monster) ->
			HpTuple2	= setelement(Idx, HpTuple, Monster#monster.hp),
			get_monster_group_hp(Position, HpTuple2);
		_ -> {?error, ?TIP_COMMON_NO_THIS_MON}
	end;
get_monster_group_hp([_|Position], HpTuple) ->
	get_monster_group_hp(Position, HpTuple);
get_monster_group_hp([], HpTuple) -> HpTuple.
%%
%% Local Functions
%%
%% 世界BOSS玩家信息
%% record_boss_player(Player, BossId) ->
%% 	Info		= Player#player.info,
%% 	#boss_player{
%% 				 boss_id		= BossId,						% BOSSID
%% 				 user_id		= Player#player.user_id,		% 玩家id
%% 				 user_name 		= Info#info.user_name,			% 玩家名称
%% 				 pro			= Info#info.pro,				% 职业
%% 				 sex			= Info#info.sex,				% 性别
%% 				 lv				= Info#info.lv,					% 玩家等级
%% 				 vip			= player_api:get_vip_lv(Info),	% VIP等级
%% 				 encourage		= 0,							% 鼓舞
%% 				 reborn			= ?CONST_SYS_FALSE,				% 浴火重生(0:否|1:是)
%% 				 reborn_times	= 0,							% 浴火重生次数
%% 				 hurt			= 0,							% 伤害
%% 				 hurt_tmp		= 0,							% 伤害(临时)单场战斗累计伤害
%% 				 auto			= ?CONST_SYS_FALSE,				% 自动战斗(0:否|1:是)
%% 				 cd_death		= 0,							% 死亡复活CD
%% 				 cd_exit		= 0, 							% 退出CD
%% 				 exist			= ?CONST_SYS_TRUE				% 存在(0:是|1:否)
%% 				}.

%% 跨服世界BOSS玩家信息
record_boss_player(Player, Room, BossId, IsRobot, MasterNode) ->
	Info		= Player#player.info,
	Node		= node(),
	#boss_player{
				 user_id		= Player#player.user_id,		% 玩家id
				 boss_id		= BossId,						% boss_id
				 user_name 		= Info#info.user_name,			% 玩家名称
				 pro			= Info#info.pro,				% 职业
				 sex			= Info#info.sex,				% 性别
				 lv				= Info#info.lv,					% 玩家等级
				 vip			= player_api:get_vip_lv(Info),	% VIP等级
				 encourage		= 0,							% 鼓舞
				 reborn			= ?CONST_SYS_FALSE,				% 浴火重生(0:否|1:是)
				 reborn_times	= 0,							% 浴火重生次数
				 hurt			= 0,							% 伤害
				 hurt_tmp		= 0,							% 伤害(临时)单场战斗累计伤害
				 auto			= ?CONST_SYS_FALSE,				% 自动战斗(0:否|1:是)
				 cd_death		= 0,							% 死亡复活CD
				 cd_exit		= 0, 							% 退出CD
				 exist			= ?CONST_SYS_TRUE,				% 存在(0:是|1:否)
				 room_id		= Room,							% 所在房间
				 node			= Node,							% 所在节点
				 master_node    = MasterNode,                   % 跨服所在节点
				 robot			= IsRobot						% 机器人标志
				}.

record_boss_monster(BroadcastTag, MonsterId) ->
	{?ok, HpMax, HpTuple}	= get_monster_group_hp(MonsterId),
	Fun		= fun(Tag, AccTags) ->
					  [{HpMax * Tag div ?CONST_SYS_NUMBER_TEN_THOUSAND,
						Tag div ?CONST_SYS_NUMBER_HUNDRED,
						get_monster_tip(Tag)}|AccTags]
			  end,
	Tags	= lists:foldl(Fun, [], BroadcastTag),
	#boss_monster{
				  monster_id				= MonsterId,	% 怪物ID
				  hp						= HpMax,		% 怪物当前总生命
				  hp_max 					= HpMax,		% 怪物总生命上限
				  broadcast_tag				= Tags,			% 公告标记(0、正常1、70%以下、2、50%以下3、30%以下4、10%以下)
				  hp_tuple					= HpTuple,		% 怪物组血量
				  first						= 0 			% 第一个动手的UserId
				 }.

get_monster_tip(1000) -> ?TIP_BOSS_BLOOD_PHASE1;
get_monster_tip(3000) -> ?TIP_BOSS_BLOOD_PHASE2;
get_monster_tip(5000) -> ?TIP_BOSS_BLOOD_PHASE3;
get_monster_tip(7000) -> ?TIP_BOSS_BLOOD_PHASE4;
get_monster_tip(Tag) ->
	?MSG_ERROR("ERROR get_monster_tip(Tag:~p)", [Tag]).