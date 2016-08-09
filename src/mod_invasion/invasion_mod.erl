%% Author: Administrator
%% Created: 2012-10-31
%% Description: 异民族逻辑函数
-module(invasion_mod).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.battle.hrl").
%% 
%% Exported Functions
%%
-export([copy_info/1, refresh_cb/2, start_battle/2,
		 check_team_play/3, hall_info/1, check_reborn/2,
		 init/10, start/2, off/0, beat_heart/0, invasion_robot/0, guard/1, 
		 mon_battle_start/3, battle_over/8, attack/1,
		 check_reborn/1, reborn/1, check_play_again/2,
		 quit/1, logout/1, evaluation/1, turn_card/1, 
		 reward_cb/2, robot_exec/1, do_start_battle_ext/8]).
%%
%% API Functions
%%
%% 副本信息
copy_info(Player) ->
	Lv				= (Player#player.info)#info.lv,
	NewInvasion		= refresh(Lv, Player#player.invasion),
	Times			= NewInvasion#invasion.times,
	{Player#player{invasion = NewInvasion}, invasion_api:msg_sc_copy_info(misc:uint(Times))}.

%% 刷新异民族数据
refresh(Lv, Invasion) when is_integer(Lv) andalso is_record(Invasion, invasion) ->
	Today	= misc:date_num(),
	case Invasion#invasion.date of
		Today	->	
			refresh(Invasion);
		_Other	->
			Lv2     = misc:min(Lv, ?CONST_SYS_PLAYER_LV_MAX),
			Data	= data_invasion:init_copy_list(Lv2),
			Invasion#invasion{data	= Data}
	end;
refresh([Data | DataList], Acc)	->
	case Data of
		{invasion_data, _Id, _Count, _Amount}	->
			NewAcc	= Acc ++ [Data],
			refresh(DataList, NewAcc);
		{invasion_data, Id, Count}				->
			case data_invasion:get_invasion_info(Id) of
				?null	->	
					refresh(DataList, Acc);
				RecInvasion when is_record(RecInvasion, rec_invasion)	->
					Amount	= RecInvasion#rec_invasion.amount,
					NewAcc	= Acc ++ [{invasion_data, Id, Count, Amount}],
					refresh(DataList, NewAcc)
			end
	end;
refresh([], Acc)	->	Acc.

refresh(Invasion) when is_record(Invasion, invasion)	->
	Data1 = Invasion#invasion.data,
	Data =
	case Data1 == null of
		true ->
			data_invasion:init_copy_list(80);
		false ->
			Invasion#invasion.data
	end,
	NewData	= refresh(Data, []),
	Invasion#invasion{data	= NewData}.

%% 刷新回调
refresh_cb(Player, Copy) when is_record(Player, player) andalso is_integer(Copy) ->
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	Invasion	= Player#player.invasion,
	OldTimes	= Invasion#invasion.times,
	ReInvasion	= refresh(Lv, Invasion),
	Data		= ReInvasion#invasion.data,
	NewData		= case lists:keyfind(Copy, #invasion_data.copy, Data) of
					  Tuple when is_record(Tuple, invasion_data) -> Data;% 20130419 修改需求，异民族取消次数限制
%% 						  Times		= Tuple#invasion_data.times,
%% 						  NewTuple	= Tuple#invasion_data{times = Times - 1},
%% 						  lists:keyreplace(Copy, #invasion_data.copy, Data, NewTuple);
					  _Other ->	Data
				  end,
	NewInvasion	= ReInvasion#invasion{times = OldTimes - 1, data = NewData},
	if NewInvasion#invasion.times =:= 0 ->
		   spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 2);
	   true ->
		   skip
	end,
	schedule_api:add_resource_times(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_INVISION),
	Packet		= invasion_api:msg_sc_copy_info(OldTimes - 1),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player#player{invasion = NewInvasion}}.

%% check_copy_state(Player, [InvasionInfo | InvasionInfoList])
%%   when is_record(InvasionInfo, invasion_info)	->
%% 	case InvasionInfo#invasion_info.activity of
%% 		?true	->	
%% 			?CONST_INVASION_TO_CITY;
%% 		?false	->	
%% 			check_copy_state(Player, InvasionInfoList)
%% 	end;
%% check_copy_state(Player, _InvasionInfoList)	->
%% 	Info		= Player#player.info,
%% 	MapId		= Info#info.map_id,
%% 	Copy		= data_invasion:map2copy(MapId),
%% 	Invasion	= Player#player.invasion,
%% 	Data		= Invasion#invasion.data,
%% 	case lists:keyfind(Copy, #invasion_data.copy, Data) of
%% 		Tuple when is_record(Tuple, invasion_data)
%% 		  andalso Tuple#invasion_data.times > 0	->
%% 			?CONST_INVASION_TO_TAEM;
%% 		_Other									->	
%% 			?CONST_INVASION_TO_HALL
%% 	end.

%% 检查是否可以异民族组队
check_team_play(Player, Copy, Type) ->
	Invasion	= Player#player.invasion,
	Data		= Invasion#invasion.data,
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	UserTuple	= lists:keyfind(Copy, #invasion_data.copy, Data),
	case check_team_play_lv(Copy, Lv) of
		?ok ->
			check_team_play_ext(Invasion#invasion.times, UserTuple, Type);
		{?error, Error} ->
			{?error, Error}
	end.

check_team_play_lv(Copy, Lv) ->
	InvasionLv   = copy_to_lv(Copy, Lv),
	case InvasionLv =< Lv of
		?true ->
			?ok;
		?false ->
			{?error, ?TIP_INVASION_LEVEL_NOT_ENOUGH}
	end.

copy_to_lv(Copy, Lv) ->
	case data_invasion:get_invasion_info(Copy) of
		RecInvasion when is_record(RecInvasion, rec_invasion) ->
			RecInvasion#rec_invasion.lv;
		_ ->
			Lv
	end.
	
%% 检查次数 
%% check_team_play_ext(_Times, #invasion_data{copy = Copy,  amount = Amount}, ?CONST_TEAM_CHECK_INVITE) ->
%% 	{?ok, Copy, Amount};
%% check_team_play_ext(_Times, #invasion_data{copy = Copy,  amount = Amount}, ?CONST_TEAM_CHECK_REPLY_JOIN) ->
%% 	{?ok, Copy, Amount};
check_team_play_ext(Times, #invasion_data{copy = Copy,  amount = Amount}, _Type)
  when Times > 0 ->
	{?ok, Copy, Amount};
check_team_play_ext(Times, #invasion_data{copy = _Copy,  amount = _Amount}, _Type)
  when Times =< 0 ->
	{?error, ?TIP_INVASION_USE_UP}; % 20130419 修改需求，异民族取消次数限制
check_team_play_ext(_Times, _UserTuple, _Type) ->
    ?MSG_ERROR("1", []),
	{?error, ?TIP_INVASION_NO_COPY}.

%% 检查是否可以再次进入当前副本
check_play_again(Player, CopyId) ->
	Invasion	= Player#player.invasion,
	Data		= Invasion#invasion.data,
	Times		= Invasion#invasion.times,
	RealCopyId	= attack_to_guard(CopyId),
	case lists:keyfind(RealCopyId, #invasion_data.copy, Data) of
		InvasionData when is_record(InvasionData, invasion_data) ->
			if
				Times > 0 -> ?ok; % 仍有剩余次数，可以在此进入
%% 				InvasionData#invasion_data.times =:= 0 -> ?ok; % 20130419 修改需求，异民族取消次数限制
				?true -> {?error, ?TIP_INVASION_USE_UP} % 次数用完，明天再来
			end;
		_Other -> {?error, ?TIP_COMMON_BAD_ARG} % 很遗憾，找不到该副本信息
	end.

%% 攻关守关副本转换
attack_to_guard(CopyId) ->
	case data_invasion:attack_to_guard(CopyId) of
		NewCopyId when is_integer(NewCopyId) ->
			NewCopyId;
		_ ->
			CopyId
	end.

%% 异民族大厅信息
hall_info(Player)	->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_INVASION) of
		{?true, Player2}	->
			case team_api:enter_hall(Player2) of
				{?ok, PacketTeam}	->
					{Player3, PacketCopyInfo}	= invasion_mod:copy_info(Player2),
					misc_packet:send(Player2#player.net_pid, <<PacketCopyInfo/binary, PacketTeam/binary>>),
					{?ok, Player3};
				{?error, ErrorCode}	->
					TipsPacket	= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player2#player.net_pid, TipsPacket),
					{?ok, Player2}
			end;
		{?false, _Player, Tips}	->
			TipsPacket	= message_api:msg_notice(Tips),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

%% 初始化异民族数据
init(TeamId, TeamType, MapPid, MapId, Copy)	->
	RecInvasion	= data_invasion:get_invasion_info(Copy),
	BeginTime	= misc:seconds(),
	EndTime		= BeginTime + RecInvasion#rec_invasion.duration,
	HurtLeft	= 0,
	HurtRight	= 0,
	Progress	= ?CONST_INVASION_GUARD_START + 1,
	Start		= case lists:keyfind(Progress, 1, RecInvasion#rec_invasion.start_cd) of
					  {Progress, StartCd}	->	misc:seconds() + StartCd;
					  ?false				->	misc:seconds()
				  end,
	init(TeamId, TeamType, MapPid, MapId, Copy, BeginTime, EndTime, HurtLeft, HurtRight, Start).

init(TeamId, TeamType, MapPid, MapId, Prior, BeginTime, EndTime, HurtLeft, HurtRight, Start)
  when  is_integer(MapId) andalso is_integer(BeginTime) andalso is_integer(EndTime)
		andalso is_integer(HurtLeft) andalso is_integer(HurtRight)	->
	Copy		= data_invasion:map2copy(MapId),
	RecInvasion	= data_invasion:get_invasion_info(Copy),
	Mode		= RecInvasion#rec_invasion.mode, 
	StartPacket	= case Mode of
					  ?CONST_INVASION_GUARD		->	
						  invasion_api:pack_sc_start_guard();
					  ?CONST_INVASION_ATTACK	->	
						  set_team_param(TeamType, TeamId, Copy),
						  invasion_api:pack_sc_start_attack(Copy)
				  end,
	team_api:broadcast_team(TeamType, TeamId, StartPacket),%% 更改广播方式(由于是异步切地图，有可能玩家还没切入地图)
%% 	map_api:broadcast(MapPid, StartPacket),
	Wave		= RecInvasion#rec_invasion.wave,
	RobotList	= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_INVASION, TeamId),
	#invasion_info{team_id		= TeamId,
				   team_type	= TeamType,
				   map_pid		= MapPid,
				   map_id		= MapId,
				   prior		= Prior,
				   copy			= Copy,
				   mode			= Mode,
				   wave			= Wave,
				   progress		= ?CONST_INVASION_GUARD_START,
				   begin_time	= BeginTime,
				   end_time		= EndTime,
				   hurt_left	= HurtLeft,
				   hurt_right	= HurtRight,
				   reborn		= [],
				   hurt			= ?null,
				   npc			= ?null,
				   start		= Start,
				   mons			= [],
				   state		= ?CONST_INVASION_IN_PROGRESS,
				   team_robot	= RobotList }.

init_invasion_attack(Invasion, Copy, Packet) ->
	RecInvasion			= data_invasion:get_invasion_info(Copy),
	Mode				= RecInvasion#rec_invasion.mode, 
	MapPid				= Invasion#invasion_info.map_pid,
%% 	StartPacket	= case Mode of
%% 					  ?CONST_INVASION_GUARD		->	
%% 						  invasion_api:pack_sc_start_guard();
%% 					  ?CONST_INVASION_ATTACK	->	
%% 						  set_team_param(TeamType, TeamId, Copy),
%% 						  invasion_api:pack_sc_start_attack(Copy)
%% 				  end,
%% 	map_api:broadcast(MapPid, StartPacket),
	[{NextWave, StartCd} | _] = RecInvasion#rec_invasion.start_cd,
	Wave		= RecInvasion#rec_invasion.wave,
	Now			= misc:seconds(),
	Start		= Now + StartCd,
	TimePacket	= invasion_api:pack_sc_start_monster(Mode, Start, NextWave),
	map_api:broadcast(MapPid, <<Packet/binary, TimePacket/binary>>),
	Invasion#invasion_info{
						   copy			= Copy,
				   		   mode			= Mode,
						   wave			= Wave,
						   progress		= ?CONST_INVASION_GUARD_START,
						   reborn		= [],
						   hurt			= ?null,
						   npc			= ?null,
						   start		= Start,
						   mons			= [],
						   state		= ?CONST_INVASION_PHASE}.

%% 初始化伤害排行
init_hurt_rank(InvasionInfo) when is_record(InvasionInfo, invasion_info)	->
	Hurt	= InvasionInfo#invasion_info.hurt,
	case Hurt =:= ?null of
		?true	->
			UserIdList	= get(user_id_list),
			HurtList	= init_hurt_rank(UserIdList, []),
			case length(HurtList) > 3 of
				?true ->
					?MSG_ERROR("HurtRankList=:~p,UserIdList=:~p", [HurtList,UserIdList]);
				?false ->
					?ok
			end,
			InvasionInfo#invasion_info{hurt	= HurtList};
		?false	->	InvasionInfo
	end.
init_hurt_rank([{_, UserId} | UserIdList], Acc)	->
    case battle_cross_api:get_player_fields(UserId, [#player.info]) of
		{?ok, [#info{user_name = UserName}]} ->
			init_hurt_rank(UserIdList, [{UserId, UserName, 0} | Acc]);
		{?ok, _Other, _OnLine}	->
			init_hurt_rank(UserIdList, Acc)
	end;
init_hurt_rank([], Acc)	->
	Packet	= invasion_api:pack_sc_hurt_rank(Acc),
	map_api:broadcast(self(), Packet),
	Acc.

%% 更新伤害排行
update_hurt_rank(?CONST_INVASION_GUARD, UserId, HurtLeft, HurtList)	->
	case lists:keyfind(UserId, 1, HurtList) of
		{UserId, UserName, Hurt}	->
			Tuple		= {UserId, UserName, Hurt + HurtLeft},
			NewHurtList0	= lists:keyreplace(UserId, 1, HurtList, Tuple),
			Fun = fun({_, _, Hurt1}, {_, _, Hurt2}) ->
						  Hurt1 > Hurt2
				  end,
			NewHurtList = lists:sort(Fun, NewHurtList0),
			Packet		= invasion_api:pack_sc_hurt_rank(NewHurtList),
			map_api:broadcast(self(), Packet),
			NewHurtList;
		_Other	->	HurtList
	end;
update_hurt_rank(?CONST_INVASION_ATTACK, _UserId, _HurtLeft, HurtList)	->
	HurtList.

%% 初始化守关NPC（城门）
init_guard_npc(InvasionInfo) when is_record(InvasionInfo, invasion_info) ->
	Npc	= InvasionInfo#invasion_info.npc,
	case Npc =:= ?null of
		?true	->
			MapPid		= InvasionInfo#invasion_info.map_pid,
			Start		= InvasionInfo#invasion_info.start,
			Progress	= InvasionInfo#invasion_info.progress,
			Mode		= InvasionInfo#invasion_info.mode,
			StartPacket	= invasion_api:pack_sc_start_monster(Mode, Start, Progress),
			map_api:broadcast(MapPid, StartPacket),
			Copy		= InvasionInfo#invasion_info.copy,
			RecInvasion	= data_invasion:get_invasion_info(Copy),
			NpcId		= RecInvasion#rec_invasion.target_id,
			{
			 ?ok, NpcInfo
			}			= monster_api:make(NpcId),
			Id			= NpcInfo#monster.id,
			MaxHp		= RecInvasion#rec_invasion.target_hp,
			CurHp		= RecInvasion#rec_invasion.target_hp,
			DeltaHp		= RecInvasion#rec_invasion.delta_hp,
			X			= RecInvasion#rec_invasion.npc_x,
			Y			= RecInvasion#rec_invasion.npc_y,
			NpcPacket	= invasion_api:pack_sc_monster_info(?false, Mode, NpcId, Id, X, Y),
			map_api:broadcast(MapPid, NpcPacket),
			NewNpc		= #invasion_npc{id		= Id,		npc_id		= NpcId,	max_hp	= MaxHp,
										cur_hp	= CurHp,	delta_hp	= DeltaHp,	x		= X,
										y		= Y},
			HpPacket	= invasion_api:pack_sc_mon_hp(Id, CurHp, MaxHp, ?false),
			map_api:broadcast(MapPid, HpPacket),
			InvasionInfo#invasion_info{npc	= NewNpc};
		?false	->	
			InvasionInfo
	end.

%% 初始化守关怪物
init_guard_mon(InvasionInfo)  when is_record(InvasionInfo, invasion_info)	->
	Mode		= InvasionInfo#invasion_info.mode,
	Start		= case Mode of
					  ?CONST_INVASION_GUARD		->	InvasionInfo#invasion_info.start;
					  ?CONST_INVASION_ATTACK	->	InvasionInfo#invasion_info.start
				  end,
	Progress	= InvasionInfo#invasion_info.progress,
	Copy		= InvasionInfo#invasion_info.copy,
	RecInvasion	= data_invasion:get_invasion_info(Copy),
	Mons		= InvasionInfo#invasion_info.mons,
	{
	 NewStart, NewProgress, AddMons
	}			= init_guard_mon(Mode, Start, Progress, RecInvasion),
	InvasionInfo#invasion_info{progress	= NewProgress,
							   start	= NewStart,
							   mons		= Mons ++ AddMons}.
init_guard_mon(Mode, Start, Progress, RecInvasion)
  when is_integer(Mode) andalso
	   is_integer(Start) andalso
	   is_integer(Progress) andalso
	   is_record(RecInvasion, rec_invasion) ->
	TimeFlag	= case Mode of
					  ?CONST_INVASION_GUARD		->	misc:seconds() >= Start;
					  ?CONST_INVASION_ATTACK	->	?true
				  end,
	ProFlag		= Progress < RecInvasion#rec_invasion.wave,
	case {TimeFlag, ProFlag} of
		{?true, ?true}	->
			CurProgress	= Progress + 1,
			NxtProgress	= CurProgress + 1,
			Mons		= init_guard_mon(Mode, CurProgress, RecInvasion, []),
			Fun			= fun(Mon)	->
								  MonId		= Mon#invasion_mon.mon_id,
								  Id		= Mon#invasion_mon.id,
								  X			= Mon#invasion_mon.next_x,
								  Y			= Mon#invasion_mon.next_y,
								  
%% 								  TipPacket = message_api:msg_notice(?TIP_INVASION_REFRESH, [{?TIP_SYS_MONSTER, misc:to_list(MonId)}]),
%% 								  map_api:broadcast(self(), TipPacket),
													
								  MonPacket	= invasion_api:pack_sc_monster_info(?true, Mode, MonId, Id, X, Y),
								  map_api:broadcast(self(), MonPacket)
						  end,
			lists:foreach(Fun, Mons),
			NextStart =
				case Mode of
					?CONST_INVASION_GUARD ->
						case lists:keyfind(NxtProgress, 1, RecInvasion#rec_invasion.start_cd) of
							{NxtProgress, StartCd}	->
								TempStart   = misc:seconds() + StartCd,
								TimePacket	= invasion_api:pack_sc_start_monster(Mode, TempStart, CurProgress),
								map_api:broadcast(self(), TimePacket),
								TempStart;
							 ?false					-> 
								 TempStart  = misc:seconds(),
								 TimePacket	= invasion_api:pack_sc_start_monster(Mode, TempStart, CurProgress),
								 map_api:broadcast(self(), TimePacket),
								 TempStart
						end;
					?CONST_INVASION_ATTACK ->
						Start
				end,
			{NextStart, CurProgress, Mons};
		{_, ?true}	->
			{Start, Progress, []};
		{_, ?false} ->
%% 			?MSG_ERROR("init_guard_mon TimeFlag=:~p, Start=:~p, Now=:~p, ProFlag=：~p, Progress:=~p, Wave:=~p", 
%% 					   [TimeFlag, Start, misc:seconds(), ProFlag, Progress, RecInvasion#rec_invasion.wave]),
			{Start, Progress, []}
	end;
init_guard_mon(Mode, Progress, RecInvasion, Acc)
  when is_integer(Mode) andalso is_integer(Progress) andalso is_record(RecInvasion, rec_invasion) andalso is_list(Acc)	->
	MonList	= RecInvasion#rec_invasion.monster,
	Born	= RecInvasion#rec_invasion.born,
	Turn	= RecInvasion#rec_invasion.turn,
	Walk	= RecInvasion#rec_invasion.walk,
	Halt	= RecInvasion#rec_invasion.halt,
	init_guard_mon(Mode, Progress, MonList, Born, Turn, Walk, Halt, Acc).
init_guard_mon(Mode, Progress, MonList, Born, Turn, Walk, Halt, Acc)
  when is_integer(Mode) andalso is_integer(Progress) andalso is_list(Born) andalso is_list(Turn) andalso is_list(Acc)	->
	case lists:keyfind(Progress, 1, MonList) of
		Mon when is_tuple(Mon)	->
			{
			 _Progress, MonId, Path
			}			= Mon,
			{_, X, Y}	= lists:keyfind(Path, 1, Born),
			{
			 _, TurnX, TurnY
			}			= lists:keyfind(Path, 1, Turn),
			{
			 _Progress, Speed, Space
			}			= lists:keyfind(Progress, 1, Walk),
			{
			 ?ok, Monster
			}			= monster_api:make(MonId),
			{
			 Units, _Horse, _HorseSkill, _HorseAttr
			}			= init_right_units(Mode, MonId),
			UnitsHp		= battle_api:get_units_hp(misc:to_list(Units#units.units)),
			NewTurnX	= case Mode of
							  ?CONST_INVASION_GUARD		->	TurnX;
							  ?CONST_INVASION_ATTACK	->	X
						  end,
			NewTurnY	= case Mode of
							  ?CONST_INVASION_GUARD		->	TurnY;
							  ?CONST_INVASION_ATTACK	->	Y
						  end,
			InvasionMon	= #invasion_mon{id			= Monster#monster.id,
										mon_id		= MonId,
										max_hp		= mon_hp(Units),
										cur_hp		= mon_hp(Units),
										target_x	= TurnX,
										target_y	= TurnY,
										turn_x		= NewTurnX,
										turn_y		= NewTurnY,
										cur_x		= X,
										cur_y		= Y,
										next_x		= X,
										next_y		= Y,
										part_x		= X,
										part_y		= Y,
										speed		= Speed,
										space		= Space,
										time		= Halt,
										battling	= ?CONST_SYS_FALSE,
										units_hp	= UnitsHp},
			DelMonList	= lists:delete(Mon, MonList),
			init_guard_mon(Mode, Progress, DelMonList, Born, Turn, Walk, Halt, Acc ++ [InvasionMon]);
		?false	->
			Acc
	end.

init_right_units(Mode, MonId) ->
	Param	= case Mode of
				  ?CONST_INVASION_GUARD		->	#param{battle_type = ?CONST_BATTLE_INVASION_GUARD};
				  ?CONST_INVASION_ATTACK	->	#param{battle_type = ?CONST_BATTLE_INVASION_ATTACK}
			  end,
	{?ok, RecordRight, RightCamp, _RightCampAttr}	= battle_mod:init_camp_right(MonId, Param, ?CONST_BATTLE_UNITS_SIDE_RIGHT),
	battle_mod:init_units({?CONST_BATTLE_UNITS_SIDE_RIGHT, MonId}, RecordRight, RightCamp, Param).

mon_hp(Units)	->
	UnitList	= misc:to_list(Units#units.units),
	mon_hp(UnitList, 0).
mon_hp([Unit | UnitList], Hp) when is_record(Unit, unit)	->
	NewHp		= Unit#unit.hp + Hp,
	mon_hp(UnitList, NewHp);
mon_hp([_Unit | UnitList], Hp)	->
	mon_hp(UnitList, Hp);
mon_hp([], Hp)	->
	Hp.

%% %% 
start(Player, Copy) ->
	case check_start(Player, Copy) of
		{?ok, TeamType, Invasion, Team} ->
			do_start(Player, Copy, TeamType, Invasion, Team);
        {?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
            {?ok, Player};
		{?error, ErrorCode} ->
			Packet	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player};
		{?error, ErrorCode, UserList} ->
			Packet	= message_api:msg_notice(ErrorCode, UserList, [], []),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

%% 检查异民族开始条件
check_start(Player, Copy) ->
	TeamId		= Player#player.team_id,
	try
%% 		?ok 			= check_play_open(),
		{?ok, Invasion} = check_copy_invasion_ok(Copy),
		{?ok, TeamType}	= check_team_type(Player),
		?ok 			= check_team_play_start(TeamType, TeamId),
		{?ok, Team} 	= check_team_ok(TeamType, TeamId),
		{?ok, TeamType, Invasion, Team}
	catch
		throw:Return ->
			Return;
		Type:Error ->
			?MSG_DEBUG("Type:~p Error:~p", [Type, Error]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查玩法开启
%% check_play_open() ->
%% 	case invasion_api:is_opened() of
%% 		?true ->
%% 			?ok;
%% 		?false ->
%% 			throw({?error, ?TIP_INVASION_NO_ACCESS})
%% 	end.



%% 检查副本数据
check_copy_invasion_ok(Copy) ->
	case data_invasion:get_invasion_info(Copy) of
		Invasion when is_record(Invasion, rec_invasion) ->
			{?ok, Invasion};
		Other ->
            ?MSG_ERROR("cc[~p|~p]", [Copy, Other]),
			throw({?error, ?TIP_INVASION_NO_COPY})
	end.

%% 检查队伍类型
check_team_type(Player) ->
	case team_api:team_type(Player) of
		0 ->
			throw({?error, ?TIP_TEAM_NOT_TEAM_PLAY});
		TeamType ->
			{?ok, TeamType}
	end.

%% 检查组队开始
check_team_play_start(TeamType, TeamId) ->
	case team_api:play_start(TeamType, TeamId) of
		?ok ->
			?ok;
		{?error, ErrorCode} ->
			throw({?error, ErrorCode});
		{?error, ErrorCode, UserList} ->
			throw({?error, ErrorCode, UserList})
	end.

%% 检查队伍状态
check_team_ok(TeamType, TeamId) ->
	{_EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt} = team_api:team_ets(TeamType),
	case ets_api:lookup(EtsTeamInfo, TeamId) of
		Team when is_record(Team, team) ->
			{?ok, Team};
		_Other ->
			throw({?error, ?TIP_TEAM_NO_THIS_TEAM})
	end.

%% 开始玩法
do_start(Player, Copy, TeamType, Invasion, Team) ->
	TeamId		= Player#player.team_id,
	MapId		= Invasion#rec_invasion.map_id,
%% 	RobotList	= team_api:get_robot_list(TeamType, TeamId),
%% 	enter_map_robot(RobotList, MapId, ?CONST_MAP_PTYPE_INV_ROBOT),
	
	Player2		= map_api:enter_map(Player, MapId),
	team_api:set_team_state(TeamType, TeamId, ?CONST_TEAM_STATE_START),
	MapPid		= Player2#player.map_pid,
	Fun			= fun(UserId) ->	
						  case check_is_robot(UserId, TeamId) of
							  ?true -> %% 机器人
								  ?ok;
							  ?false -> %% 非机器人
								 invasion_api:refresh(UserId, Copy) 
						  end
				  end,
	lists:foreach(Fun, team_api:get_team_uids(Team)),
	EtsInvasion	= init(TeamId, TeamType, MapPid, MapId, Copy),
	update_team_invasion(EtsInvasion),
%% 	admin_log_api:log_campaign(Player2#player.user_id, Player2#player.account, Info#info.lv, ?CONST_ACTIVE_INVASION, misc:seconds()),
	{?ok, Player2}.


%% 关闭异民族
off()			->
	InfoList	= ets:tab2list(?CONST_ETS_INVASION),
	Fun			= fun(Info) when is_record(Info, invasion_info)	->
						  MapPid	= Info#invasion_info.map_pid,
						  TeamId	= Info#invasion_info.team_id,
						  map_api:invasion_close(MapPid, TeamId)
				  end,
	lists:foreach(Fun, InfoList),
	team_api:player_over_clean(?CONST_TEAM_TYPE_INVASION).

%% 怪物心跳
beat_heart()	->
	InfoList	= ets:tab2list(?CONST_ETS_INVASION),
	Fun			= fun(Info) when is_record(Info, invasion_info)	->
						  MapPid	= Info#invasion_info.map_pid,
						  map_api:invasion_progress(MapPid)
				  end,
	lists:foreach(Fun, InfoList).

%% 机器人
invasion_robot() ->
	InfoList	= ets:tab2list(?CONST_ETS_INVASION),
	Fun			= fun(Info) when is_record(Info, invasion_info)	->
						  MapPid	= Info#invasion_info.map_pid,
						  TeamId	= Info#invasion_info.team_id,
						  map_api:invasion_robot(MapPid, TeamId)
				  end,
	lists:foreach(Fun, InfoList).

%% 守关
guard(InvasionInfo = #invasion_info{state = ?CONST_INVASION_IN_PROGRESS})
  when is_record(InvasionInfo, invasion_info)	->
	RankInvasionInfo	= init_hurt_rank(InvasionInfo),
	NpcInvasionInfo		= init_guard_npc(RankInvasionInfo),
	RefreshInvasionInfo	= guard_refresh(NpcInvasionInfo),
	mon_info(RefreshInvasionInfo),
	NewInvasionInfo		= progress(RefreshInvasionInfo),
	update_team_invasion(NewInvasionInfo);
guard(InvasionInfo)
  when is_record(InvasionInfo, invasion_info)	->
	InvasionInfo.

mon_info(InvasionInfo) when is_record(InvasionInfo, invasion_info) ->
	MapPid	= InvasionInfo#invasion_info.map_pid,
	Mons	= InvasionInfo#invasion_info.mons,
	Fun		= fun(Mon) ->
					  Id	= Mon#invasion_mon.id,
					  MaxHp	= Mon#invasion_mon.max_hp,
					  CurHp	= Mon#invasion_mon.cur_hp,
					  HpPacket	= invasion_api:pack_sc_mon_hp(Id, CurHp, MaxHp, ?true),
					  map_api:broadcast(MapPid, HpPacket)
			  end,
	lists:foreach(Fun, Mons).

mon_move(MapPid, Mon) when is_pid(MapPid) andalso is_record(Mon, invasion_mon)	->
	Id		= Mon#invasion_mon.id,
	CurX	= Mon#invasion_mon.cur_x,
	CurY	= Mon#invasion_mon.cur_y,
	PartX	= Mon#invasion_mon.part_x,
	PartY	= Mon#invasion_mon.part_y,
	Speed	= Mon#invasion_mon.speed,
	Packet	= map_api:msg_sc_monster_move(Id, CurX, CurY, PartX, PartY, Speed),
	map_api:broadcast(MapPid, Packet).

%% 怪物心跳逻辑函数
progress(InvasionInfo = #invasion_info{mode = ?CONST_INVASION_GUARD})
  when is_record(InvasionInfo, invasion_info)	->
	Now			= misc:seconds(),
	TeamId		= InvasionInfo#invasion_info.team_id,
	TeamType	= InvasionInfo#invasion_info.team_type,
	MapPid		= InvasionInfo#invasion_info.map_pid,
	Progress	= InvasionInfo#invasion_info.progress,
	EndTime		= InvasionInfo#invasion_info.end_time,
	Copy		= InvasionInfo#invasion_info.copy,
	Wave		= InvasionInfo#invasion_info.wave,
	RecInvasion	= data_invasion:get_invasion_info(Copy),
	NextCopy	= RecInvasion#rec_invasion.next,
	Npc			= InvasionInfo#invasion_info.npc,
	CurNpcHp	= Npc#invasion_npc.cur_hp,
	Mons		= InvasionInfo#invasion_info.mons,
	if
		CurNpcHp =< 0	->	%% 城门没血
			Packet	= invasion_api:pack_sc_defendend(?false, ?true),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
%% 			team_api:player_over_clean(TeamType),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_LOSE},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
		EndTime =< Now	->	%% 副本时间结束
			Packet	= invasion_api:pack_sc_defendend(?false, ?true),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
%% 			team_api:player_over_clean(TeamType),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_LOSE},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
		Progress =:= Wave andalso length(Mons) =:= 0 andalso NextCopy =/= 0	-> %% 本关结束 有下一关
			Packet	= invasion_api:pack_sc_defendend(?true, ?false),
			init_invasion_attack(InvasionInfo, NextCopy, Packet);
		Progress =:= Wave andalso length(Mons) =:= 0 andalso NextCopy =:= 0	-> %% 本关结束 无下一关
			Packet	= invasion_api:pack_sc_defendend(?true, ?true),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
%% 			team_api:player_over_clean(TeamType),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_WIN},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
		?true	->
			init_guard_mon(InvasionInfo)
	end;
progress(InvasionInfo = #invasion_info{mode = ?CONST_INVASION_ATTACK})
  when is_record(InvasionInfo, invasion_info)	->
	Now			= misc:seconds(),
	TeamId		= InvasionInfo#invasion_info.team_id,
	TeamType	= InvasionInfo#invasion_info.team_type,
	MapPid		= InvasionInfo#invasion_info.map_pid,
	Wave		= InvasionInfo#invasion_info.wave,
	Progress	= InvasionInfo#invasion_info.progress,
	EndTime		= InvasionInfo#invasion_info.end_time,
	Mons		= InvasionInfo#invasion_info.mons,
	Start		= InvasionInfo#invasion_info.start,
	if
		EndTime =< Now	->		%% 副本时间结束
			Packet	= invasion_api:pack_sc_attack(?false),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_LOSE},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
		Progress =:= Wave - 1 andalso length(Mons) =/= 0 andalso Start < Now	-> %% 倒数第二波
			Packet	= invasion_api:pack_sc_attack(?false),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_LOSE},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
%% 			init_guard_mon(InvasionInfo);
		Progress =:= Wave andalso length(Mons) =:= 0						->	   %% 最后一波
			Packet	= invasion_api:pack_sc_attack(?true),
			map_api:broadcast(MapPid, Packet),
			team_api:play_over(TeamType, TeamId),
			NewInvasionInfo = InvasionInfo#invasion_info{state = ?CONST_INVASION_WIN},
			invasion_evaluation(NewInvasionInfo),
			NewInvasionInfo;
		Progress =:= Wave - 1 andalso length(Mons) =:= 0 andalso Start >= Now	->
			init_guard_mon(InvasionInfo);
		Progress < Wave - 1	->
			init_guard_mon(InvasionInfo);
		?true	->
%% 			?MSG_ERROR("progress invasion=:~p~n, Now=:~p~n", [InvasionInfo, Now]),
			InvasionInfo
	end.

%% 守关刷新
guard_refresh(InvasionInfo) ->
	MapPid		= InvasionInfo#invasion_info.map_pid,
	Mode		= InvasionInfo#invasion_info.mode,
	Npc			= InvasionInfo#invasion_info.npc,
	CopyId		= InvasionInfo#invasion_info.copy,
	RecInvasion	= data_invasion:get_invasion_info(CopyId),
	Enlarge		= RecInvasion#rec_invasion.enlarge_hp,
	NpcId		= Npc#invasion_npc.id,
	NpcMaxHp	= Npc#invasion_npc.max_hp,
	NpcCurHp	= Npc#invasion_npc.cur_hp,
	NpcDeltaHp	= Npc#invasion_npc.delta_hp,
	NpcX		= Npc#invasion_npc.x,
	NpcY		= Npc#invasion_npc.y,
	Mons		= InvasionInfo#invasion_info.mons,
	{NewNpcHp, NewMons}	= guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, Mons, []),
	NewNpc		= Npc#invasion_npc{cur_hp = NewNpcHp},
	InvasionInfo#invasion_info{npc	= NewNpc,	mons	= NewMons}.
guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, [Mon | MonList], Acc)	->
	TargetX		= Mon#invasion_mon.target_x,
	TurnX		= Mon#invasion_mon.turn_x,
	X			= Mon#invasion_mon.next_x,
	Duration	= Mon#invasion_mon.duration,
	if
		Mon#invasion_mon.battling =:= ?CONST_SYS_TRUE	->	%战斗中，怪物位置不变
			NewAcc		= Acc ++ [Mon],
			guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, MonList, NewAcc);
		NpcX >= X		->									%怪物碰撞城门
			NewNpcHp	= collision(MapPid, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, Mon, Enlarge),
			guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NewNpcHp, NpcDeltaHp, NpcX, NpcY, Enlarge, MonList, Acc);
		Duration > 0	->									%停留时间未完，更新后端的位置part_	
			NewAcc		= Acc ++ [minus(Mon)],
			guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, MonList, NewAcc);
		TargetX >= X andalso TargetX =:= TurnX	->			%转折点，通知前端下一步
			NewMon		= Mon#invasion_mon{target_x = NpcX, target_y = NpcY},
			NewAcc		= Acc ++ [next(MapPid, Mode, NewMon)],
			guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, MonList, NewAcc);
		?true			->									%通知前端下一步
			NewAcc		= Acc ++ [next(MapPid, Mode, Mon)],
			guard_refresh(MapPid, Mode, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, NpcX, NpcY, Enlarge, MonList, NewAcc)
	end;
guard_refresh(_MapPid, _Mode, _NpcId, _NpcMaxHp, NpcCurHp, _NpcDeltaHp, _NpcX, _NpcY, _Enlarge, [], Acc) ->
	{NpcCurHp, Acc}.

minus(Mon) when is_record(Mon, invasion_mon)	->
	CurX	= Mon#invasion_mon.cur_x,
	CurY	= Mon#invasion_mon.cur_y,
	NextX	= Mon#invasion_mon.next_x,
	NextY	= Mon#invasion_mon.next_y,
	PartX	= Mon#invasion_mon.part_x,
	PartY	= Mon#invasion_mon.part_y,
	Speed	= Mon#invasion_mon.speed,
	SignX	= if
				  CurX =:= PartX	->	0;
				  ?true				->	(CurX - PartX) / erlang:abs(CurX - PartX)
			  end,
	DeltaX	= misc:min(erlang:abs(NextX - PartX), Speed),
	SignY	= if
				  CurY =:= PartY	->	0;
				  ?true				->	(CurY - PartY) / erlang:abs(CurY - PartY)
			  end,
	DeltaY	= if
				  CurX =:= PartX	->	erlang:abs(NextY - PartY);
				  ?true				->
					  misc:min(misc:ceil(erlang:abs(DeltaX / (CurX - PartX) * (CurY - PartY))), erlang:abs(NextY - PartY))
			  end,
	NewNextX	= if
					  CurX	> PartX	->
						  misc:max(misc:ceil(NextX - SignX * DeltaX), PartX);
					  CurX	< PartX	->
						  misc:min(misc:ceil(NextX - SignX * DeltaX), PartX);
					  ?true				->
						  NextX
				  end,
	NewNextY	= if
					  CurY > PartY	->
						  misc:max(misc:ceil(NextY - SignY * DeltaY), PartY);
					  CurY < PartY	->
						  misc:min(misc:ceil(NextY - SignY * DeltaY), PartY);
					  ?true				->
						  NextY
				  end,
%% 	?MSG_WARNING("~nPartX=~p~nPartY=~p~nNewNextX=~p~nNewNextY=~p~n", [PartX, PartY, NewNextX, NewNextY]),
	NewDuration	= Mon#invasion_mon.duration - 1,
%% 	?MSG_WARNING("~nTargetX=~p~nTargetY=~p~nCurX=~p~nCurY=~p~nNextX=~p~nNextY=~p~nDeltaX=~p~nDeltaY=~p~nNewNextX=~p~nSignY=~p~nNewNextY=~p~nPartX=~p~nPartY=~p~nDuration=~p~n",
%% 				 [TargetX, TargetY, CurX, CurY, NextX, NextY, DeltaX, DeltaY, NewNextX, SignY, NewNextY, PartX, PartY, NewDuration]),
	Mon#invasion_mon{next_x		= NewNextX,
					 next_y		= NewNextY,
					 duration	= NewDuration}.

%% 怪物碰撞城门
collision(MapPid, NpcId, NpcMaxHp, NpcCurHp, NpcDeltaHp, Mon, Enlarge) ->
	UniqueId	= Mon#invasion_mon.id,
	MonId		= Mon#invasion_mon.mon_id,
	Multiple	= enlarge_npc_delta_hp(MonId, Enlarge, NpcDeltaHp),
	NewNpcCurHp	= misc:max((NpcCurHp - Multiple), 0), 
	NpcPacket	= invasion_api:pack_sc_mon_hp(NpcId, NewNpcCurHp, NpcMaxHp, ?false),
	map_api:broadcast(MapPid, NpcPacket),
	MonPacket	= map_api:msg_map_sc_monster_remove(UniqueId),
	map_api:broadcast(MapPid, MonPacket),
	MonColPacket= invasion_api:msg_mon_collison(Mon#invasion_mon.id, Mon#invasion_mon.mon_id),
	map_api:broadcast(MapPid, MonColPacket),
	
%% 	TipPacket	= message_api:msg_notice(?TIP_INVASION_COLLISION, 
%% 										 [{?TIP_SYS_MONSTER, misc:to_list(Mon#invasion_mon.mon_id)}, {100, misc:to_list(?CONST_INVASION_NPC_HP_DELTA)}]),
%% 	TipPacket2	=
%% 		case (NewNpcCurHp > 0) of
%% 			?true ->
%% 				if 
%% 					(NpcCurHp * 100 div NpcMaxHp) =:= 0 -> 
%% 						message_api:msg_notice(?TIP_INVASION_DURATION, [{100, misc:to_list(NewNpcCurHp)}]);
%% 					(NpcCurHp * 100 div NpcMaxHp) < 10 -> 
%% 						message_api:msg_notice(?TIP_INVASION_DURATION, [{100, misc:to_list(NewNpcCurHp)}]);
%% 					(NpcCurHp * 100 div NpcMaxHp) < 50 ->
%% 						message_api:msg_notice(?TIP_INVASION_DURATION, [{100, misc:to_list(NewNpcCurHp)}]);
%% 					?true ->
%% 						<<>>
%% 				end;
%% 			?false ->
%% 				<<>>
%% 		end,
%% 	map_api:broadcast(MapPid, TipPacket2),
	
	NewNpcCurHp.

enlarge_npc_delta_hp(MonId, Enlarge, NpcDeltaHp) ->
	case lists:keyfind(MonId, 1, [Enlarge]) of
		?false ->
			NpcDeltaHp;
		{_MonId, Multiple} ->
			?MSG_ERROR("Check invasion boss ~p", [Multiple]),
			misc:to_integer(Multiple)
	end.

next(MapPid, Mode, Mon)	->
	TargetX		= Mon#invasion_mon.target_x,
	TargetY		= Mon#invasion_mon.target_y,
	CurX		= Mon#invasion_mon.cur_x,
	CurY		= Mon#invasion_mon.cur_y,
	PartX		= Mon#invasion_mon.part_x,
	PartY		= Mon#invasion_mon.part_y,
	Speed		= Mon#invasion_mon.speed,
	Space		= Mon#invasion_mon.space,
	Time		= Mon#invasion_mon.time,
	{
	 StepX, NewSpace
	}			= case Mode of
					  ?CONST_INVASION_GUARD		->	guard_space(Space);
					  ?CONST_INVASION_ATTACK	->	attack_space(Space)
				  end,
	{
	 Duration, NewTime
	}			= case Mode of
					  ?CONST_INVASION_GUARD		->	guard_time(Time);
					  ?CONST_INVASION_ATTACK	->	attack_time(Time)
				  end,
	SignX		= if
					  CurX =:= TargetX	->	0;
					  ?true				->	(CurX - TargetX) / erlang:abs(CurX - TargetX)
				  end,
	DeltaX		= misc:min(erlang:abs(PartX - TargetX), StepX),
	SignY		= if
					  CurY =:= TargetY	->	0;
					  ?true				->	(CurY - TargetY) / erlang:abs(CurY - TargetY)
				  end,
	DeltaY		= if
					  CurX =:= TargetX	->	erlang:abs(PartY - TargetY);
					  ?true				->
						  misc:min(misc:ceil(erlang:abs(DeltaX / (CurX - TargetX) * (CurY - TargetY))), erlang:abs(PartY - TargetY))
				  end,
	NewPartX	= if
					  PartX	> TargetX	->
						  misc:max(misc:ceil(PartX - SignX * DeltaX), TargetX);
					  PartX	< TargetX	->
						  misc:min(misc:ceil(PartX - SignX * DeltaX), TargetX);
					  ?true				->
						  PartX
				  end,
	NewPartY	= if
					  PartY > TargetY	->
						  misc:max(misc:ceil(PartY - SignY * DeltaY), TargetY);
					  PartY < TargetY	->
						  misc:min(misc:ceil(PartY - SignY * DeltaY), TargetY);
					  ?true				->
						  PartY
				  end,
	NewDuration	= Duration + misc:ceil(DeltaX / Speed),
%% 	?MSG_WARNING("~nTargetX=~p~nTargetY=~p~nCurX=~p~nCurY=~p~nNextX=~p~nNextY=~p~nPartX=~p~nPartY=~p~nDeltaX=~p~nDeltaY=~p~nNewPartX=~p~nSignY=~p~nNewPartY=~p~nDuration=~p~n",
%% 				 [TargetX, TargetY, CurX, CurY, NextX, NextY, PartX, PartY, DeltaX, DeltaY, NewPartX, SignY, NewPartY, NewDuration]),
	NewMon		= Mon#invasion_mon{cur_x	= PartX,		cur_y	= PartY,
								   part_x	= NewPartX,		part_y	= NewPartY,
								   duration	= NewDuration,	space	= NewSpace,
								   time		= NewTime},
%% 	?MSG_WARNING("~nId=~p~nTargetX=~p~nTargetY=~p~nNewCurX=~p~nNewCurY=~p~nNewPartX=~p~nNewPartY=~p~nSpeed=~p~n",
%% 				 [Id, TargetX, TargetY, NewCurX, NewCurY, NewPartX, NewPartY, Speed]),
	mon_move(MapPid, NewMon),
	minus(NewMon).

guard_space(Space) when is_list(Space)	->
	Length		= length(Space),
	Random		= misc:rand(1, Length),
	Elem		= lists:nth(Random, Space),
	NewSpace	= lists:delete(Elem, Space),
	{Elem, NewSpace}.

guard_time(Halt) when is_list(Halt)	->
	Length	= length(Halt),
	Random	= misc:rand(1, Length),
	case lists:nth(Random, Halt) of
		{Time, Times} when Times > 0	->
			Tuple	= {Time, Times - 1},
			NewHalt	= lists:keyreplace(Time, 1, Halt, Tuple),
			{Time, NewHalt};
		Elem	->
			NewHalt	= lists:delete(Elem, Halt),
			guard_time(NewHalt)
	end.

attack_space(Space) when is_list(Space)	->
	Length	= length(Space),
	Random	= misc:rand(1, Length),
	Elem	= lists:nth(Random, Space),
	{Elem, Space}.

attack_time(Halt) when is_list(Halt)	->
	Length	= length(Halt),
	Random	= misc:rand(1, Length),
	case lists:nth(Random, Halt) of
		{Time, _Times}	->
			{Time, Halt};
		_Other	->
			guard_time(Halt)
	end.

%% 开始战斗
start_battle(Player, UniqueId) when is_integer(UniqueId)	->
	case Player#player.team_id of
        {TeamId, NodeId} ->
            Node = cross_api:get_node(NodeId),
            InvasionInfo = rpc:call(Node, ets, lookup, [?CONST_ETS_INVASION, TeamId]);
        TeamId ->
            InvasionInfo = ets:lookup(?CONST_ETS_INVASION, TeamId)
    end,
	case InvasionInfo of
		[Tuple | _] when is_record(Tuple, invasion_info) 
		  					andalso Tuple#invasion_info.state =:= ?CONST_INVASION_IN_PROGRESS ->
			BattleType	= case Tuple#invasion_info.mode of
							  ?CONST_INVASION_GUARD		->	?CONST_BATTLE_INVASION_GUARD;
							  ?CONST_INVASION_ATTACK	->	?CONST_BATTLE_INVASION_ATTACK
						  end,
			Mons		= Tuple#invasion_info.mons,
			Mon			= lists:keyfind(UniqueId, #invasion_mon.id, Mons),
			Robot		= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_INVASION, TeamId),
			start_battle(Player, BattleType, Mon, Robot);
		_Other	->
			start_battle(Player, ?ignore, ?ignore, [])
	end.
start_battle(Player, ?CONST_BATTLE_INVASION_GUARD, Mon, Robot)
  when is_record(Mon, invasion_mon) andalso Mon#invasion_mon.battling =:= ?CONST_SYS_FALSE	->
	start_battle_ext(Player, ?CONST_BATTLE_INVASION_GUARD, Mon, Robot);
start_battle(Player, ?CONST_BATTLE_INVASION_ATTACK, Mon, Robot)
  when is_record(Mon, invasion_mon)			->
	UserId	= Player#player.user_id,
	case team_api:get_team_uids(Player) of
		[UserId | _UserIdList]	->	%% 队长
			start_battle_ext(Player, ?CONST_BATTLE_INVASION_ATTACK, Mon, Robot);
		[_UserId | _UserIdList]	->	%% 队员
			start_battle(Player, ?ignore, ?ignore, Robot)
	end;
start_battle(Player, _BattleType, _Mon, _Robot)		->
	Packet	= invasion_api:pack_sc_battle(?CONST_SYS_FALSE),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player}.

start_battle_ext(Player, BattleType, Mon, Robot)	->
	MapPid		= Player#player.map_pid,
	MapId		= map_api:get_cur_map_id(Player),
	UniqueId	= Mon#invasion_mon.id,
	MonId		= Mon#invasion_mon.mon_id,
	UnitsHp		= Mon#invasion_mon.units_hp,
    case Player#player.team_id of
        {TeamId, _NodeId} ->
            ok;
        TeamId ->
            ok
    end,
	Param		= #param{battle_type	= BattleType,
						 ad1			= UniqueId,
						 ad2			= UnitsHp,
						 ad3			= MapPid,
						 ad4			= TeamId,
						 map_id			= MapId,
						 robot			= Robot},
%% 	{?ok, Player2}	= add_guide_times(Player),
    case Player#player.team_id of
        {TeamId1, NodeId} ->
            Node = cross_api:get_node(NodeId),
            {ok, Player2, _} = player_api:get_player_first(Player#player.user_id),
            case rpc:call(Node, ?MODULE, do_start_battle_ext, [Player2#player{map_pid = MapPid, battle_pid = Player#player.battle_pid, user_state = Player#player.user_state},
                                                                              MonId, Param, TeamId1, UniqueId, MapPid, BattleType, Robot]) of
                {ok, Player3} ->
                    Player4 = Player#player{
                                            practice_state = Player3#player.practice_state,
                                            user_state = Player3#player.user_state,
                                            battle_type = Player3#player.battle_type,
                                            is_skiped = Player3#player.is_skiped,
                                            can_skip = Player3#player.can_skip,
                                            info = Player3#player.info,
                                            battle_pid = Player3#player.battle_pid, 
                                            play_state = Player3#player.play_state},
                    {ok, Player4};
                O ->
                   O
            end;
        TeamId1 ->
            do_start_battle_ext(Player, MonId, Param, TeamId1, UniqueId, MapPid, BattleType, Robot)
    end.

    

do_start_battle_ext(Player, MonId, Param, TeamId, UniqueId, MapPid, BattleType, Robot) ->
	case battle_api:start(Player, MonId, Param) of
		{?ok, NewPlayer}	->
			mon_battle_start(BattleType, MapPid, TeamId, UniqueId, Player#player.user_id),
			{?ok, NewPlayer};
		{?error, _ErrorCode}	->
			start_battle(Player, ?ignore, ?ignore, Robot)
	end.
mon_battle_start(?CONST_BATTLE_INVASION_GUARD, MapPid, TeamId, UniqueId, UserId)		->
	map_api:invasion_mon_battle_start(MapPid, TeamId, UniqueId, UserId);
mon_battle_start(?CONST_BATTLE_INVASION_ATTACK, _MapPid, _TeamId, _UniqueId, _UserId)	->
	?ignore.

mon_battle_start(TeamId, UniqueId, UserId)	->
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info)	->
			Mons	= Tuple#invasion_info.mons,
			case lists:keyfind(UniqueId, #invasion_mon.id, Mons) of
				Mon when is_record(Mon, invasion_mon)	->
					NewMon		= Mon#invasion_mon{user_id	= UserId,
												   battling	= ?CONST_SYS_TRUE},
					NewMons		= lists:keyreplace(UniqueId, #invasion_mon.id, Mons, NewMon),
					NewTuple	= Tuple#invasion_info{mons	= NewMons},
					MonList		= lists:map(fun(TmpMon) -> {TmpMon#invasion_mon.mon_id} end, NewMons),
					Packet		= invasion_api:msg_mon_start_battle(MonList),
					map_api:broadcast(Tuple#invasion_info.map_pid, Packet),
					ets:insert(?CONST_ETS_INVASION, NewTuple);
				?false	->	?false
			end;
		_Other	->	?false
	end.

%% 战斗结束处理
battle_over(?CONST_BATTLE_RESULT_LEFT, UserId, ?CONST_BATTLE_INVASION_GUARD,
			UniqueId, TeamId, _RightUnits, HurtLeft, HurtRight)	->
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info) ->
			MapPid		= Tuple#invasion_info.map_pid,
			Packet		= map_api:msg_map_sc_monster_remove(UniqueId),
			map_api:broadcast(MapPid, Packet),
			OldHurtLeft	= Tuple#invasion_info.hurt_left,
			OldHurtRight	= Tuple#invasion_info.hurt_right,
			MapId		= Tuple#invasion_info.map_id,
			Copy		= data_invasion:map2copy(MapId),
			RecInvasion	= data_invasion:get_invasion_info(Copy),
			Mode		= RecInvasion#rec_invasion.mode,
			HurtList	= Tuple#invasion_info.hurt,
			NewHurtList	= update_hurt_rank(Mode, UserId, HurtLeft, HurtList),
			Mons		= Tuple#invasion_info.mons,
			NewMons		= lists:keydelete(UniqueId, #invasion_mon.id, Mons),
			NewTuple	= Tuple#invasion_info{hurt_left		= OldHurtLeft + HurtLeft,
											  hurt_right	= OldHurtRight + HurtRight,
											  hurt			= NewHurtList,
											  mons			= NewMons},
			
			NewTuple2	= change_mon_start_time(NewTuple),
			NewTuple3	= change_robot_state(NewTuple2, UserId, ?CONST_PLAYER_STATE_NORMAL),
			broadcast_state(NewTuple3, UserId, ?CONST_BATTLE_RESULT_LEFT),
			ets:insert(?CONST_ETS_INVASION, NewTuple3);
		_Other	->	?false
	end;
battle_over(Result, UserId, ?CONST_BATTLE_INVASION_GUARD,
			UniqueId, TeamId, RightUnits, HurtLeft, HurtRight)
  when Result =:= ?CONST_BATTLE_RESULT_RIGHT orelse Result =:= ?CONST_BATTLE_RESULT_DRAW	->
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info)	->
%% 			MapData	= data_map:get_map(Tuple#invasion_info.map_id),
%% 			map_api:teleport(UserId, {MapData#rec_map.x, MapData#rec_map.y}),
			MapPid	= Tuple#invasion_info.map_pid,
			Mons	= Tuple#invasion_info.mons,
			case lists:keyfind(UniqueId, #invasion_mon.id, Mons) of
				Mon when is_record(Mon, invasion_mon)	->
					mon_move(MapPid, Mon),
					CurHp			= misc:uint(Mon#invasion_mon.cur_hp - HurtLeft),
					NewMon			= Mon#invasion_mon{cur_hp	= CurHp,
													   battling	= ?CONST_SYS_FALSE,
													   units_hp	= RightUnits},
					NewMons			= lists:keyreplace(UniqueId, #invasion_mon.id, Mons, NewMon),
					Reborn			= Tuple#invasion_info.reborn,
					RebortTime		= misc:seconds() + ?CONST_INVASION_REBORN_DURATION,
					UserTuple		= {UserId, RebortTime},
					
					TeamRobot		= Tuple#invasion_info.team_robot,
					case lists:member(UserId, TeamRobot) of
						?true ->
							?ok;
						?false ->
							RebornPacket	= invasion_api:pack_sc_reborn(RebortTime),
                            case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                                [] ->
							        misc_packet:send(UserId, RebornPacket);
                                [#cross_in{node = Node}] ->
                                    rpc:cast(Node, misc_packet, send, [UserId, RebornPacket])
                            end
					end,
					NewReborn		= case lists:keyfind(UserId, 1, Reborn) of
										  {UserId, _Time}	->
											  lists:keyreplace(UserId, 1, Reborn, UserTuple);
										  ?false			-> [UserTuple | Reborn]
									  end,
					Mode			= Tuple#invasion_info.mode,
					HurtList		= Tuple#invasion_info.hurt,
					NewHurtList		= update_hurt_rank(Mode, UserId, HurtLeft, HurtList),
					OldHurtLeft		= Tuple#invasion_info.hurt_left,
					OldHurtRight	= Tuple#invasion_info.hurt_right,
					NewTuple		= Tuple#invasion_info{hurt_left		= OldHurtLeft + HurtLeft,
														  hurt_right	= OldHurtRight + HurtRight,
														  reborn		= NewReborn,
														  hurt			= NewHurtList,
														  mons			= NewMons},
					NewTuple2	= change_robot_state(NewTuple, UserId, ?CONST_PLAYER_STATE_DEATH),
					broadcast_state(NewTuple2, UserId, Result),
					ets:insert(?CONST_ETS_INVASION, NewTuple2);
				_Other	->	?false
			end;
		_Other	->	?false
	end;
battle_over(?CONST_BATTLE_RESULT_LEFT, _UserId, ?CONST_BATTLE_INVASION_ATTACK,
			UniqueId, TeamId, _RightUnits, HurtLeft, HurtRight)	->
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info) ->
			MapPid		= Tuple#invasion_info.map_pid,
			Packet		= map_api:msg_map_sc_monster_remove(UniqueId),
			map_api:broadcast(MapPid, Packet),
			OldHurtLeft	= Tuple#invasion_info.hurt_left,
			OldHurtRight	= Tuple#invasion_info.hurt_right,
			Mons		= Tuple#invasion_info.mons,
			NewMons		= lists:keydelete(UniqueId, #invasion_mon.id, Mons),
			NewTuple	= Tuple#invasion_info{hurt_left		= OldHurtLeft + HurtLeft,
											  hurt_right	= OldHurtRight + HurtRight,
											  mons			= NewMons},
			ets:insert(?CONST_ETS_INVASION, NewTuple);
		_Other	->	?false
	end;
battle_over(Result, _UserId, ?CONST_BATTLE_INVASION_ATTACK,
			UniqueId, TeamId, RightUnits, HurtLeft, HurtRight)
  when Result =:= ?CONST_BATTLE_RESULT_RIGHT orelse Result =:= ?CONST_BATTLE_RESULT_DRAW	->
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info)	->
			MapPid	= Tuple#invasion_info.map_pid,
			Mons	= Tuple#invasion_info.mons,
			case lists:keyfind(UniqueId, #invasion_mon.id, Mons) of
				Mon when is_record(Mon, invasion_mon)	->
					mon_move(MapPid, Mon),
					CurHp	= misc:uint(Mon#invasion_mon.cur_hp - HurtLeft),
					NewMon	= Mon#invasion_mon{cur_hp	= CurHp,
											   battling	= ?CONST_SYS_FALSE,
											   units_hp	= RightUnits},
					NewMons	= lists:keyreplace(UniqueId, #invasion_mon.id, Mons, NewMon),
					OldHurtLeft	= Tuple#invasion_info.hurt_left,
					OldHurtRight	= Tuple#invasion_info.hurt_right,
					NewTuple	= Tuple#invasion_info{hurt_left		= OldHurtLeft + HurtLeft,
													  hurt_right	= OldHurtRight + HurtRight,
													  mons			= NewMons},
					ets:insert(?CONST_ETS_INVASION, NewTuple);
				_Other	->	?false
			end;
		_Other	->	?false
	end.

%% 攻关
attack(InvasionInfo = #invasion_info{state = ?CONST_INVASION_IN_PROGRESS})
  when is_record(InvasionInfo, invasion_info)	->
	RefreshInvasionInfo	= attack_refresh(InvasionInfo),
	mon_info(RefreshInvasionInfo),
	NewInvasionInfo		= progress(RefreshInvasionInfo),
	ets:insert(?CONST_ETS_INVASION, NewInvasionInfo);
attack(InvasionInfo = #invasion_info{state = ?CONST_INVASION_PHASE})
  when is_record(InvasionInfo, invasion_info)	->
	Now			= misc:seconds(),
	Start		= InvasionInfo#invasion_info.start,
	MapPid		= InvasionInfo#invasion_info.map_pid,
	TeamType	= InvasionInfo#invasion_info.team_type,
	TeamId		= InvasionInfo#invasion_info.team_id,
	NewInvasionInfo =
		if  Start < Now	-> 
			   %% 第一波时间
			   Packet	= invasion_api:pack_sc_attack(?false),
			   map_api:broadcast(MapPid, Packet),
			   team_api:play_over(TeamType, TeamId),
			   InvasionInfo2 = InvasionInfo#invasion_info{state = ?CONST_INVASION_LOSE},
			   invasion_evaluation(InvasionInfo2),
			   InvasionInfo2;
		   ?true ->
			   InvasionInfo
		end,
	ets:insert(?CONST_ETS_INVASION, NewInvasionInfo);
attack(InvasionInfo) ->
	InvasionInfo.

%% 攻关刷新
attack_refresh(InvasionInfo) when is_record(InvasionInfo, invasion_info)	->
	MapPid	= InvasionInfo#invasion_info.map_pid,
	Mode	= InvasionInfo#invasion_info.mode,
	Mons	= InvasionInfo#invasion_info.mons,
	NewMons	= attack_refresh(MapPid, Mode, Mons, []),
	InvasionInfo#invasion_info{mons	= NewMons}.
attack_refresh(MapPid, Mode, [Mon | MonList], Acc) when is_record(Mon, invasion_mon)	->
	TargetX	= Mon#invasion_mon.target_x,
	TargetY	= Mon#invasion_mon.target_y,
	TurnX	= Mon#invasion_mon.turn_x,
	TurnY	= Mon#invasion_mon.turn_y,
	NextX	= Mon#invasion_mon.next_x,
	if
		Mon#invasion_mon.battling =:= ?CONST_SYS_TRUE	->
			NewAcc		= Acc ++ [Mon],
			attack_refresh(MapPid, Mode, MonList, NewAcc);
		Mon#invasion_mon.duration > 0					->
			NewAcc		= Acc ++ [minus(Mon)],
			attack_refresh(MapPid, Mode, MonList, NewAcc);
		TargetX =:= NextX andalso TargetX < TurnX		->
%% 			?MSG_WARNING("~nTargetX=~p~nTargetY=~p~nTurnX=~p~nTurnY=~p~nCurX=~p~nCurY=~p~nNextX=~p~nNextY=~p~nPartX=~p~nPartY=~p~n",
%% 						 [TargetX, TargetY, TurnX, TurnY, CurX, CurY, NextX, NextY, PartX, PartY]),
			NewMon		= Mon#invasion_mon{target_x	= TurnX,	target_y	= TurnY,
										   turn_x	= TargetX,	turn_y		= TargetY,
										   cur_x	= TargetX,	cur_y		= TargetY,
										   next_x	= TargetX,	next_y		= TargetY,
										   part_x	= TargetX,	part_y		= TargetY},
			NewAcc		= Acc ++ [next(MapPid, Mode, NewMon)],
			attack_refresh(MapPid, Mode, MonList, NewAcc);
		TargetX =:= NextX andalso TargetX > TurnX		->
%% 			?MSG_WARNING("~nTargetX=~p~nTargetY=~p~nTurnX=~p~nTurnY=~p~nCurX=~p~nCurY=~p~nNextX=~p~nNextY=~p~nPartX=~p~nPartY=~p~n",
%% 						 [TargetX, TargetY, TurnX, TurnY, CurX, CurY, NextX, NextY, PartX, PartY]),
			NewMon		= Mon#invasion_mon{target_x	= TurnX,	target_y	= TurnY,
										   turn_x	= TargetX,	turn_y		= TargetY,
										   cur_x	= TargetX,	cur_y		= TargetY,
										   next_x	= TargetX,	next_y		= TargetY,
										   part_x	= TargetX,	part_y		= TargetY},
			NewAcc		= Acc ++ [next(MapPid, Mode, NewMon)],
			attack_refresh(MapPid, Mode, MonList, NewAcc);
		?true									->
			NewAcc		= Acc ++ [next(MapPid, Mode, Mon)],
			attack_refresh(MapPid, Mode, MonList, NewAcc)
	end;
attack_refresh(MapPid, Mode, [_Mon | MonList], Acc)	->
	attack_refresh(MapPid, Mode, MonList, Acc);
attack_refresh(_MapPid, _Mode, [], Acc)	->
	Acc.

%%检查重生
check_reborn(Player) when is_record(Player, player) ->
	UserId	= Player#player.user_id,
	case Player#player.team_id of
        {TeamId, NodeId} ->
            Node = cross_api:get_node(NodeId),
            rpc:cast(Node, ?MODULE, check_reborn, [UserId, TeamId]);
        TeamId ->
            check_reborn(UserId, TeamId)
    end.

check_reborn(UserId, TeamId) ->
    InvaInfo = ets:lookup(?CONST_ETS_INVASION, TeamId),
    case InvaInfo of
        [Tuple | _] when is_record(Tuple, invasion_info) ->
            Now     = misc:seconds(),
            Reborn  = Tuple#invasion_info.reborn,
            case lists:keyfind(UserId, 1, Reborn) of
                {UserId, Time} when Now + 10 < Time ->
                    ?MSG_WARNING("~nUserId=~p~nTime=~p,    Now ~p~n", [UserId, Time, Now]),
                    RebornPacket    = invasion_api:pack_sc_reborn(Time),
                    ?MSG_WARNING("~nUserId=~p~n", [UserId]),
                    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                        [] ->
                            misc_packet:send(UserId, RebornPacket);
                        [#cross_in{node = Node}] ->
                            rpc:cast(Node, misc_packet, send, [UserId, RebornPacket])
                    end,
                    
                    ?false;
                _Other  ->  
                    ?true
            end;
        _   -> ?true
    end.

%% 重生
reborn(Player) when is_record(Player, player) ->
	UserId	= Player#player.user_id,
	TeamId	= Player#player.team_id,
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info) ->
			Reborn		= Tuple#invasion_info.reborn,
			RebortTime	= misc:seconds(),
			RebornTuple	= {UserId, RebortTime},
			NewReborn	= case lists:keyfind(UserId, 1, Reborn) of
							  {UserId, _Time}	->
								  lists:keyreplace(UserId, 1, Reborn, RebornTuple);
							  ?false			->	[RebornTuple | Reborn]
						  end,
			NewTuple	= Tuple#invasion_info{reborn	= NewReborn},
			ets:insert(?CONST_ETS_INVASION, NewTuple);
		_Other	->	?false
	end,
	RebornPacket	= invasion_api:pack_sc_reborn(0),
	misc_packet:send(UserId, RebornPacket),
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL) of
		{?false, NewPlayer}	->	{?ok, NewPlayer};
		{?true, NewPlayer}	->	{?ok, NewPlayer}
	end.

%% 退出异民族玩法
quit(Player)	->
	case player_state_api:is_fighting(Player) of
		?true ->
			{?ok, Player};
		_Other	->
			TeamPlayer 	= case team_api:play_quit(Player) of
							  {?ok, QuitPlayer}		->	QuitPlayer;
							  {?error, _ErrorCode}	->	%% 如果已经没有队伍则补发一条18540 退出至大厅
								  Packet18540	= team_api:msg_sc_quit_play_to(?CONST_TEAM_TYPE_INVASION, ?CONST_TEAM_QUIT_TO_HALL),
								  misc_packet:send(Player#player.user_id, Packet18540),
%% 								  ?MSG_ERROR("invasion quit UserId=:~p, ErrorCode=:~p", [Player#player.user_id, ErrorCode]),
						  		  Player
						  end,
			{_Flag, TeamPlayer2} = player_state_api:try_set_state(TeamPlayer, ?CONST_PLAYER_STATE_NORMAL),
			NewPlayer	= map_api:return_last_city(TeamPlayer2),
			{?ok, NewPlayer}
	end.

%% 翻牌
turn_card(Player) ->
	Invasion 		= Player#player.invasion,
	Times			= Invasion#invasion.times,
	case Times >= 0 andalso Player#player.team_id /= 0 of
		?true ->
			turn_card_ext(Player);
		?false ->
			TipsPacket	= message_api:msg_notice(?TIP_INVASION_USE_UP),
			misc_packet:send(Player#player.user_id, TipsPacket),
			{?ok, Player}
	end.
turn_card_ext(Player)	->
	TeamId	= Player#player.team_id,
	case get_team_invasion(TeamId) of
		Tuple when is_record(Tuple, invasion_info)	->
			MapId	= Tuple#invasion_info.map_id,
			Copy	= data_invasion:map2copy(MapId),
			Result	= state2result(Tuple),
			case data_invasion:get_invasion_gift({Copy, Result}) of
				RecInvasionGift when is_record(RecInvasionGift, rec_invasion_gift)	->
					case reward_goods(Player, RecInvasionGift#rec_invasion_gift.goods) of
						{?ok, NewPlayer, GoodsList}	->% 元宝翻拍
							admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_INVASION_CARD, GoodsList, misc:seconds()),
							Packet		= invasion_api:pack_sc_turn_cark(?true, GoodsList),
							TipPacket	= invasion_api:msg_notice_goods(Player, Copy, GoodsList),
							misc_packet:send(NewPlayer#player.net_pid, Packet),
							misc_app:broadcast_world(TipPacket),
							{?ok, NewPlayer};
						_Other1	-> {?ok, Player}
					end;
				?null -> {?ok, Player}
			end;
		_Other -> {?ok, Player}
	end.

state2result(InvasionInfo) when is_record(InvasionInfo, invasion_info)	->
	case InvasionInfo#invasion_info.state of
		?CONST_INVASION_WIN			->	?CONST_SYS_TRUE;
		?CONST_INVASION_IN_PROGRESS	->	?CONST_SYS_FALSE;
		?CONST_INVASION_PHASE		->	?CONST_SYS_FALSE;
		?CONST_INVASION_LOSE		->	?CONST_SYS_FALSE
	end;
state2result(_)						->	?CONST_SYS_FALSE.

%% 奖励
process_reward(UserList, InvasionInfo) 	->
	process_send(UserList, ?MODULE, reward_cb, {InvasionInfo}).

process_send(UserList, M, F, A) ->
	Fun = fun(UserId1) when UserId1 > 0 ->
                  case ets:lookup(?CONST_ETS_CROSS_IN, UserId1) of
                      [] ->
				          player_api:process_send(UserId1, M, F, A);
                      [#cross_in{node = Node}] ->
                          rpc:cast(Node, player_api, process_send, [UserId1, M, F, A])
                  end;
			 (X) -> ?MSG_DEBUG("X=~p", [X])
		  end,
	[Fun(UserId) || UserId <- UserList].

reward_cb(Player, {InvasionInfo}) ->
	Invasion	= Player#player.invasion,
	Times		= Invasion#invasion.times,
	UserId		= Player#player.user_id,
	RobotList	= InvasionInfo#invasion_info.team_robot,
	case Times >= 0 of
		?true ->
			case lists:member(UserId, RobotList) of
				?true ->
					{?ok, Player};
				?false ->
					reward_cb_ext(Player, {InvasionInfo})
			end;
		?false ->
			TipsPacket	= message_api:msg_notice(?TIP_INVASION_USE_UP),
			misc_packet:send(Player#player.user_id, TipsPacket),
			{?ok, Player}
	end.
reward_cb_ext(Player, {InvasionInfo}) ->
	{
	 Evaluation, HurtLeft, HurtRight, Duration
	}		= evaluation(InvasionInfo),
	Prior	= InvasionInfo#invasion_info.prior,
	Copy	= InvasionInfo#invasion_info.copy,
	MapId	= InvasionInfo#invasion_info.map_id,
	CopyId	= data_invasion:map2copy(MapId),
	Result	= state2result(InvasionInfo),
	Invasion	= Player#player.invasion,
	{?ok, Player3, RewardExp, RewardGold, RewardGoodsList} =
		case lists:keyfind(Prior, #invasion_data.copy, Invasion#invasion.data) of
			Tuple when is_record(Tuple, invasion_data) ->
				case data_invasion:get_invasion_gift({Copy, Result}) of
					RecInvasionGift when is_record(RecInvasionGift, rec_invasion_gift)	->
						case reward(Player, RecInvasionGift) of
							{?ok, Player2, Experience, Gold, GoodsList}	->% 通关奖励|假翻牌
								admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_INVASION_REWARD, GoodsList, misc:seconds()),
								TipPacket	= invasion_api:msg_notice_goods(Player, CopyId, GoodsList),
								misc_app:broadcast_world(TipPacket),
								{?ok,Player7}= task_api:update_succ_count(Player2,?CONST_MODULE_YIMINZU),  %%每日任务——异民族
								{?ok, Player7, Experience, Gold, GoodsList};
							_Other	->	{?ok, Player, 0, 0, []}
						end;
					_Other	->	{?ok, Player, 0, 0, []}
				end;
			_Other	->	{?ok, Player, 0, 0, []}
		end,
	{?ok, Player4} = achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_INVASION, Copy, Result),
	Player5	= task_api:finish_invasion(Player4, Copy),
	{?ok, Player6}  = new_serv_api:finish_achieve(Player5, ?CONST_NEW_SERV_INVASION, 0, 1),
	Packet	= invasion_api:pack_sc_evaluation(Evaluation, HurtLeft, HurtRight, Duration, RewardExp, RewardGold, RewardGoodsList),			
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player6}.
	
reward(Player, RecInvasionGift)
  when is_record(Player, player) andalso is_record(RecInvasionGift, rec_invasion_gift)	->
	case reward_goods(Player, RecInvasionGift#rec_invasion_gift.goods) of
		{?error, ErrorCode}	->
			{?error, ErrorCode};
		{?ok, Player2, GoodsList}	->
			Gold	= RecInvasionGift#rec_invasion_gift.gold,
			case reward_gold(Player2#player.user_id, Gold) of
				?ok ->
					Meritorious	= RecInvasionGift#rec_invasion_gift.meritorious,
					%% 去掉异名族中历练奖励
					%% Experience	= RecInvasionGift#rec_invasion_gift.experience,
					Experience	= Meritorious,
					{?ok, Player3} = reward_meritorious(Player2, Meritorious),
					%% {?ok, Player4} = reward_experience(Player3, Experience),
					{?ok, Player3, Experience, Gold, GoodsList};
				{?error, ErrorCode}	->
					?MSG_ERROR("ErrorCode=~p", [ErrorCode]),
					{?error, ErrorCode}
			end
	end;
reward(_, _)	->	?ok.

reward_goods(Player, GoodsDrop) when is_record(Player, player) andalso is_integer(GoodsDrop)	->
	GoodsList	= goods_api:goods_drop(GoodsDrop),
	reward_goods(Player, GoodsList);
reward_goods(Player, GoodsList) when is_record(Player, player) andalso is_list(GoodsList)	->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_INVASION_REWARD, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag}	->
			{?ok, Player2, GoodsList};
		{?error, _ErrorCode}	->
			{?ok, Player, []}
	end;
reward_goods(Player, _)	->	{?ok, Player, []}.

%% 游戏币奖励
reward_gold(_UserId, 0) -> ?ok;
reward_gold(UserId, Gold) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_INVASION_REWARD) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 军功奖励
reward_meritorious(Player, 0) -> {?ok, Player};
reward_meritorious(Player, Meritorious) -> player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_INVASION_REWARD).

%% 培养值奖励
reward_experience(Player, 0) -> {?ok, Player};
reward_experience(Player, Experience) -> 
	Player2 = player_api:plus_experience(Player, Experience),
	{?ok, Player2}.

%% add_activity_times(Player) ->
%% 	{H, _M, _S}	= misc:time(),
%% 	case H < ?CONST_SCHEDULE_TIME_BOUNDARY of
%% 		?true	->	{?ok, Player};
%% 		?false	->	{?ok, Player}
%% 	end.

%% add_guide_times(Player) ->
%% 	schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_INVASION).

%% bless(Player, Copy, Result) when Result =:= ?CONST_SYS_TRUE	->
%% 	bless_api:send_be_blessed(Player, ?CONST_RELATIONSHIP_BLESS_TYPE_INVASION, Copy),
%% 	{?ok, Player};
%% bless(Player, _Copy, _Result)	->
%% 	{?ok, Player}.

%%
%% Local Functions
%%
logout(Player)	->
	TeamId	= Player#player.team_id,
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _TupleList] when is_record(Tuple, invasion_info)	->
			Mons		= Tuple#invasion_info.mons,
			NewMons		= logout(Player#player.user_id, Mons, []),
			?MSG_WARNING("~nMons=~p~nNewMons=~p~n", [Mons, NewMons]),
			NewTuple	= Tuple#invasion_info{mons	= NewMons},
			ets:insert(?CONST_ETS_INVASION, NewTuple);
		_Other	->	?false
	end.
logout(UserId, [Mon	= #invasion_mon{user_id		= UserId,
									battling	= ?CONST_SYS_TRUE} | MonList], Acc)	->
	NewMon	= Mon#invasion_mon{user_id	= 0,	battling	= ?CONST_SYS_FALSE},
	NewAcc	= Acc ++ [NewMon],
	logout(UserId, MonList, NewAcc);
logout(UserId, [Mon | MonList], Acc)	->
	NewAcc	= Acc ++ [Mon],
	logout(UserId, MonList, NewAcc);
logout(_UserId, [], Acc)	->	Acc.

%% 异民族评价
%% [10000*（通关时间/玩家通关时间）+10000*（玩家总输出/怪物总输出）]/2
%% 
%% SSS：10000*120%
%% SS：10000*（110%~120%）
%% S：10000*（100%~110%）
%% A：10000*（90%~100%）
%% B：10000*（80%~90%）
invasion_evaluation(InvasionInfo) when is_record(InvasionInfo, invasion_info)	->
	TeamId		= InvasionInfo#invasion_info.team_id,
	UserIdList	= get_team_user_list(TeamId),
    case ets:lookup(?CONST_ETS_TEAM_INFO_INVASION, TeamId) of
        [] ->
            ok;
        [#team{leader_uid = LeaderId, cross_list = CrossList, team_pid = TeamPid}] ->
            case lists:keymember(LeaderId, #team_player.uid, CrossList) of
                true ->
                    team_serv:destroy_cast(TeamPid);
                _ ->
                    ok
            end
    end,
	process_reward(UserIdList, InvasionInfo);
invasion_evaluation(InvasionInfo) ->
	?MSG_ERROR("invasion_evaluation=:~p", [InvasionInfo]),
	<<>>.

get_team_user_list(TeamId) -> 
	case team_api:get_team(?CONST_ETS_TEAM_INFO_INVASION, TeamId) of
		{?ok, Team} when is_record(Team, team)->
			team_api:get_team_uids(Team);
	  	_ ->
		    []
    end.
invasion_achievement([], _Copy, _Result) -> ?ok;
invasion_achievement([UserId|UserIdList], Copy, Result) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_INVASION, Copy, Result),
	invasion_achievement(UserIdList, Copy, Result).
%% evaluation(Player) when is_record(Player, player)	->
%% 	TeamId	= Player#player.team_id,
%% 	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
%% 		[InvasionInfo | _] when is_record(InvasionInfo, invasion_info)	->
%% 			?MSG_WARNING("~nInvasionInfo=~p~n", [InvasionInfo]),
%% 			{
%% 			 Evaluation, HurtLeft, HurtRight, Duration
%% 			}		= evaluation(InvasionInfo),
%% 			Prior	= InvasionInfo#invasion_info.prior,
%% 			Copy	= InvasionInfo#invasion_info.copy,
%% 			Result	= state2result(InvasionInfo),
%% 			{
%% 			 ?ok, RewardPlayer, Exp, Gold, GoodsList
%% 			}		= reward(Player, Prior, Copy, Result),
%% 			Packet	= invasion_api:pack_sc_evaluation(Evaluation, HurtLeft, HurtRight, Duration, Exp, Gold, GoodsList),
%% 			?MSG_WARNING("~nEvaluation=~p~nHurtLeft=~p~nHurtRight=~p~nDuration=~p~nExp=~p~nGold=~p~nGoodsList=~p~n",
%% 						 [Evaluation, HurtLeft, HurtRight, Duration, Exp, Gold, GoodsList]),
%% 			misc_packet:send(RewardPlayer#player.net_pid, Packet),
%% 			{
%% 			 ?ok, WelfarePlayer
%% 			}		= welfare_api:add_pullulation(RewardPlayer, ?CONST_WELFARE_INVASION, Copy, Result),
%% 			{
%% 			 ?ok, BlessPlayer
%% 			}		= bless(WelfarePlayer, Copy, Result),
%% 			achievement_api:add_achievement(BlessPlayer, ?CONST_ACHIEVEMENT_INVASION, Copy, Result);
%% 		_Other	->	
%% 			{?ok, Player}
%% 	end;
evaluation(InvasionInfo) when is_record(InvasionInfo, invasion_info)
  andalso InvasionInfo#invasion_info.state =:= ?CONST_INVASION_WIN	->
	BeginTime	= InvasionInfo#invasion_info.begin_time,
	EndTime		= InvasionInfo#invasion_info.end_time,
	HurtLeft	= InvasionInfo#invasion_info.hurt_left,
	HurtRight	= InvasionInfo#invasion_info.hurt_right,
	TotDuration	= EndTime - BeginTime,
	Duration	= misc:seconds() - BeginTime,
	Evaluation	= evaluation(TotDuration, Duration, HurtLeft, HurtRight),
	{Evaluation, HurtLeft, HurtRight, Duration};
evaluation(InvasionInfo) when is_record(InvasionInfo, invasion_info)
  andalso (InvasionInfo#invasion_info.state =:= ?CONST_INVASION_IN_PROGRESS
	orelse InvasionInfo#invasion_info.state =:= ?CONST_INVASION_PHASE
	orelse InvasionInfo#invasion_info.state =:= ?CONST_INVASION_LOSE)	->
	BeginTime	= InvasionInfo#invasion_info.begin_time,
	HurtLeft	= InvasionInfo#invasion_info.hurt_left,
	HurtRight	= InvasionInfo#invasion_info.hurt_right,
	Duration	= misc:seconds() - BeginTime,
	{?CONST_INVASION_EVALUATION_0, HurtLeft, HurtRight, Duration}.
evaluation(TotDuration, Duration, HurtLeft, HurtRight)	->
	NewDuration		= case Duration	 =< 0 of
						  ?true	->	1;	?false	->	Duration
					  end,
	NewHurtRight	= case HurtRight =< 0 of
						  ?true	->	1;	?false	->	HurtRight
					  end,
	Factor	= (TotDuration / NewDuration * ?CONST_SYS_NUMBER_TEN_THOUSAND + HurtLeft / NewHurtRight * ?CONST_SYS_NUMBER_TEN_THOUSAND) / 2,
	if
		Factor	=<	?CONST_INVASION_DIVIDE_B * ?CONST_SYS_NUMBER_HUNDRED	->
			?CONST_INVASION_EVALUATION_B;
		Factor	=<	?CONST_INVASION_DIVIDE_A * ?CONST_SYS_NUMBER_HUNDRED	->
			?CONST_INVASION_EVALUATION_A;
		Factor	=<	?CONST_INVASION_DIVIDE_S * ?CONST_SYS_NUMBER_HUNDRED	->
			?CONST_INVASION_EVALUATION_S;
		Factor	=<	?CONST_INVASION_DIVIDE_SS * ?CONST_SYS_NUMBER_HUNDRED	->
			?CONST_INVASION_EVALUATION_SS;
		?true	->	?CONST_INVASION_EVALUATION_SSS
	end.

%% 更新异民族ETS
update_team_invasion(EtsInvasion) ->
	ets:insert(?CONST_ETS_INVASION, EtsInvasion).

%% 获取invasion信息
get_team_invasion(TeamId) ->
    case TeamId of
        {TeamId1, ServId} ->
            Node = cross_api:get_node(ServId),
            InvasionList = rpc:call(Node, ets, lookup, [?CONST_ETS_INVASION, TeamId1]);
        _ ->
            InvasionList = ets:lookup(?CONST_ETS_INVASION, TeamId)
    end,
	case InvasionList of
		[Invasion|_] ->
			Invasion;
		_Other ->
			?null
	end.

%% 设置组队param
set_team_param(TeamType, TeamId, _Copy) ->
	case team_api:get_team_param(TeamType, TeamId) of
		{?ok, TeamParam} ->
			team_api:set_team_param(TeamType, TeamId, TeamParam);
		{?error, _ErrorCode} ->
			?ok
	end.

%% 更改出怪时间
change_mon_start_time(#invasion_info{mode = ?CONST_INVASION_GUARD, mons = []} = InvasionInfo) ->
	Start		= InvasionInfo#invasion_info.start,
	Progress	= InvasionInfo#invasion_info.progress,
	MapPid		= InvasionInfo#invasion_info.map_pid,
	Now			= misc:seconds(),
	NewStart	=
		case Start - Now > ?CONST_INVASION_TIME_MON_CHANGE of
			?true ->
				Now + ?CONST_INVASION_TIME_MON_CHANGE;
			?false ->
				Start
		end,
	Packet		= invasion_api:pack_sc_start_monster(?CONST_INVASION_GUARD, NewStart, Progress),
	map_api:broadcast(MapPid, Packet),
	InvasionInfo#invasion_info{start = NewStart};
change_mon_start_time(InvasionInfo) -> InvasionInfo.

%% 更改机器人复活时间
change_robot_state(InvasionInfo, UserId, RobotState) ->
	Now			= misc:seconds(),
	TimeStamp	= Now + 15,%?CONST_INVASION_REBORN_DURATION,
	Robot		= InvasionInfo#invasion_info.robot,
	Robot2		= 
		case lists:keyfind(UserId, 1, Robot) of
			{_UserId, _RobotState, _TimeStamp} ->
				lists:keyreplace(UserId, 1, Robot, {UserId, RobotState, TimeStamp});
			_ ->
				[{UserId, RobotState, TimeStamp}|Robot]
		end,
	InvasionInfo#invasion_info{robot = Robot2}.

%% 机器人
robot_exec(TeamId) ->
	RobotList	= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_INVASION, TeamId),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info) 
		  andalso Tuple#invasion_info.mode =:= ?CONST_INVASION_GUARD ->
			robot_exec_list(RobotList, Tuple);
		_Other	->	
			?ok
	end.
robot_exec_list([UserId|List], InvasionInfo) ->
	case get_mon_pos(InvasionInfo) of
		Mon when is_record(Mon, invasion_mon) ->
			InvasionInfo2	= robot_exec_list(UserId, InvasionInfo, Mon),
			robot_exec_list(List, InvasionInfo2);
		_ ->
			robot_exec_list(List, InvasionInfo)
	end;
robot_exec_list([], _InvasionInfo) -> ?ok.

robot_exec_list(UserId, InvasionInfo, Mon) ->
	MapPid	= InvasionInfo#invasion_info.map_pid,
	case player_api:get_player_first(UserId) of
		{?ok, ?null, _IsOnline} ->
			?ok;
		{?ok, Player2, _IsOnline} ->
			Robot	= InvasionInfo#invasion_info.robot,
			TeamId	= InvasionInfo#invasion_info.team_id,
			X = Mon#invasion_mon.cur_x,
			Y = Mon#invasion_mon.cur_y,
			UniqueId = Mon#invasion_mon.id,
			Info	= Player2#player.info,
			Info2	= Info#info{is_auto = ?CONST_SYS_TRUE},
			Player3	= Player2#player{info = Info2, map_pid = MapPid, team_id = TeamId},
			Now		= misc:seconds(),
			case lists:keyfind(UserId, 1, Robot) of
				{UserId, UserState, TimeStamp} when Now =< TimeStamp orelse UserState =:= ?CONST_PLAYER_STATE_FIGHTING ->
					InvasionInfo;
				_Other ->
					Player4	= Player3#player{user_state = ?CONST_PLAYER_STATE_FIGHTING, 
											 practice_state = 0},
					map_api:change_user_state(Player4, ?CONST_MAP_PTYPE_INV_ROBOT),
					map_api:move_robot(Player3, UserId, X, Y, ?CONST_MAP_PTYPE_INV_ROBOT),
					start_battle(Player3, UniqueId),
					NewMon	= Mon#invasion_mon{battling	= ?CONST_SYS_TRUE},
					Mons	= InvasionInfo#invasion_info.mons,
					NewMons	= lists:keyreplace(UniqueId, #invasion_mon.id, Mons, NewMon),
					InvasionInfo2	= InvasionInfo#invasion_info{mons = NewMons},
					InvasionInfo3   = change_robot_state(InvasionInfo2, UserId, ?CONST_PLAYER_STATE_FIGHTING),
					ets:insert(?CONST_ETS_INVASION, InvasionInfo3),
					InvasionInfo3
			end
	end.

%% 搜索怪物
get_mon_pos(InvasionInfo) ->
	try
		Mons	= InvasionInfo#invasion_info.mons,
		Npc		= InvasionInfo#invasion_info.npc,
		NpcX	= Npc#invasion_npc.x,
		MonsList	= [X || X <- Mons, X#invasion_mon.battling =:= ?CONST_SYS_FALSE, X#invasion_mon.cur_x < NpcX + 1300],
		Fun = fun(Elem1,Elem2)->
					  Elem1#invasion_mon.cur_x < Elem2#invasion_mon.cur_x
			  end,
		NewList = lists:sort(Fun, MonsList),
		case length(NewList) > 0 of
			?true ->
				[Mon|_]		= NewList,
				Mon;
			?false ->
				[]
		end
	catch
		Type:Error ->
			?MSG_ERROR("Type:~p Error:~p", [Type, Error]),
			[]
	end.
			
%% 检查是否机器人
check_is_robot(UserId, TeamId) ->
	List	= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_INVASION, TeamId),
	lists:member(UserId, List).
	
%% 机器人战斗结束瞬移 状态广播
broadcast_state(InvasionInfo, UserId,  Result) ->
	TeamId	= InvasionInfo#invasion_info.team_id,
	case check_is_robot(UserId, TeamId) of
		?true ->
			case player_api:get_player_first(UserId) of
				{?ok, ?null, _IsOnline} ->
					?ok;
				{?ok, Player2, _IsOnline} ->
					MapPid	= InvasionInfo#invasion_info.map_pid,
					UserState	= 
						case Result of
							?CONST_BATTLE_RESULT_LEFT ->
								?CONST_PLAYER_STATE_NORMAL;
							_ ->
								?CONST_PLAYER_STATE_DEATH
						end,
					Player3	= Player2#player{map_pid = MapPid,
											 team_id = TeamId,
											 user_state = UserState, 
											 practice_state = 0},
					map_api:change_user_state(Player3, ?CONST_MAP_PTYPE_INV_ROBOT),
					invasion_teleport(Player3, InvasionInfo)
			end;
		?false ->
			case Result of
				?CONST_BATTLE_RESULT_LEFT ->
					?ok;
				_ ->
					invasion_teleport(UserId, InvasionInfo)
			end
	end.

%% 瞬移
%% invasion_teleport(_Player3, _InvasionInfo, ?CONST_BATTLE_RESULT_LEFT) ->
%% 	?ok;
invasion_teleport(Player3, InvasionInfo) ->
	MapData	= data_map:get_map(InvasionInfo#invasion_info.map_id),
	map_api:teleport(Player3, MapData#rec_map.x, MapData#rec_map.y, ?CONST_SYS_TRUE).

