%% Author: Administrator
%% Created: 2012-7-27
%% Description: TODO: Add description to pratice_mod
-module(practice_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("const.protocol.hrl").
-include("../../include/record.map.hrl").

%%
%% Exported Functions
%%
-export([
		 logout/1,
		 
		 single_request/1,
		 double_request/2,
		 double_reply/3,
		 double_state_cb/2,	 
		 cancel/1,
		 cancel_cb/2,
		 auto_options/2,
		 auto_data/1,
		 
		 send_exp/1,
		 send_exp_cb/2,
		 
		 clear_cd/2,
		 
		 double_broadcast/1,
		 insert_practice_user/1,
		 ets_practice_user/1,
		 
		 get_online_exp/1,
		 get_max_time/2,
		 
		 set_offline_robot/3,
		 update_practice_doll/2,
		 set_doll_award/1,
		 doll_reward_cb/2,
		 
		 query_offline_set/1,
		 cancel_offline_set/1,
		 save_doll_data/1,
		 doll_cancel_double/1,
		 add_tomorrow_time/0,
		 clear_robot/0,
		 get_valid_time/2,
		 is_doll/1,
		 
		 add_guide/1
		 ]).

%%
%% API Functions
%%
%% 零点刷新修炼活跃度
add_guide(Player) ->
	PracticeState = Player#player.practice_state,
	case PracticeState =:= ?CONST_PLAYER_STATE_SINGLE_PRACTISE orelse PracticeState =:= ?CONST_PLAYER_STATE_DOUBLE_PRACTISE of
		?true ->
			schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE);
		?false ->
			{?ok, Player}
	end.

%% 关服保存
save_doll_data(PracticeDoll) ->
    case mysql_api:select(<<"replace into `game_practice_doll`(`user_id`,`record`)value('", (misc:to_binary(PracticeDoll#practice_doll.user_id))/binary, 
							"',", (mysql_api:encode(PracticeDoll))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 单修
%% practice_mod:single_request(Player).
%% arg : Player
%% return : {?ok,Player} | {?error, ErrorCode}
single_request(Player = #player{user_id = UserId,net_pid = Pid,user_state = UserState}) ->
	try
		?ok						= check_single_state(UserState),				%% 检查状态
		{?ok,PracticeUser,Time} = check_player(Player),
		
		{?ok,Player2} 			= set_single_state(Player),						%% 设置单修状态	
		Practice				= init_practice(UserId,?CONST_PLAYER_STATE_SINGLE_PRACTISE),	
		Packet 					= practice_api:msg_single(?CONST_SYS_TRUE,Time),
		
		PracticeUser2			= PracticeUser#practice_user{mem_id 	= 0, 
															 start_time = misc:seconds()},
		insert_practice_user(PracticeUser2),
		insert_practice(Practice),
		
		misc_packet:send(Pid, Packet),
		{?ok, Player3} = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_PRACTICE, 0, 1), %% 成就
		schedule_api:add_guide_times(Player3, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE)
	catch
		throw:Return ->
			?MSG_ERROR("ERROR Return:~w", [Return]),
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

check_player(#player{user_id = UserId,info = Info,sys_rank = Sys,play_state = PlayState} = Player) ->
	?ok				= check_sys(Sys),					%% 检查等级
	?ok 			= check_map(map_api:get_cur_map_id(Player)),		%% 检查场景
	?ok				= check_raiding(UserId),
 	?ok				= check_player_state(PlayState),	%% 检查玩法状态
	PracticeUser	= ets_practice_user(UserId), 		%% 设置practice
	VipLv			= player_api:get_vip_lv(Info),
	TimeMax			= get_max_time(Info#info.lv,VipLv),	
	{?ok,Time}		= check_practice_time(PracticeUser#practice_user.sum_time,TimeMax), 
	{?ok,PracticeUser,Time}.

check_raiding(UserId) ->
	case player_state_api:is_raiding(UserId) of
		?false -> ?ok;
		_ ->
			throw({?error,?TIP_PRACTICE_ERROR})
	end.

check_practice_time(Time,TimeMax) when Time >= TimeMax ->
	throw({?error,?TIP_PRACTICE_TIME_FULL});
check_practice_time(Time,TimeMax) -> 
	{?ok,TimeMax - Time}.

check_m_practice_time(Time,TimeMax) when Time >= TimeMax ->
	throw({?error,?TIP_PRACTICE_MEM_TIME_FULL});
check_m_practice_time(Time,TimeMax) -> 
	{?ok,TimeMax - Time}.

%% 检查场景
check_map(MapId) ->
	case get_map_flag(MapId) of
		?CONST_SYS_FALSE ->%% 当前场景不能打坐
			throw({?error,?TIP_PRACTICE_MAP_ERROR});
		_ -> ?ok
	end.

%% 检查系统是否开放
check_sys(?null) ->
	throw({?error,?TIP_COMMON_LEVEL_NOT_ENOUGH});
check_sys(Sys) -> 
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_PRACTICE) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_COMMON_LEVEL_NOT_ENOUGH})
    end.
	

%% 检查邀请人系统是否开放
check_m_sys(?null) ->
	throw({?error,?TIP_PRACTICE_MEM_DOUBLE_ERROR});
check_m_sys(Sys) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_PRACTICE) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_PRACTICE_MEM_DOUBLE_ERROR})
    end.
	

%% 检查单修状态
check_single_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) ->%% 已经单修
	throw({?error,?TIP_PRACTICE_NOW});
check_single_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) ->%% 已经双修
	throw({?error,?TIP_PRACTICE_DOUBLE_NOW});
check_single_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_single_state(_) ->%% 不可打坐状态
	throw({?error,?TIP_PRACTICE_ERROR}).

%% 检查玩法状态
check_player_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_player_state(?CONST_PLAYER_PLAY_CITY) -> ?ok;
check_player_state(_) ->
	throw({?error,?TIP_PRACTICE_ERROR}).

%% 检查对方的状态
check_member_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_member_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_member_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) -> 
	throw({?error,?TIP_PRACTICE_MEM_DOUBLE_NOW});
check_member_state(_) -> 
	throw({?error,?TIP_PRACTICE_MEM_DOUBLE_ERROR}).

%% 检查对方的玩法状态
check_member_play_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_member_play_state(?CONST_PLAYER_PLAY_CITY) -> ?ok;
check_member_play_state(_) ->
	throw({?error,?TIP_PRACTICE_MEM_DOUBLE_ERROR}).

%% 设置单修状态
set_single_state(Player) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_SINGLE_PRACTISE) of
		{?true,Player2} -> 
			{?ok,Player2};
		_ ->
			throw({?error,?TIP_PRACTICE_ERROR})
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 双修请求
%% practice_mod:double_request(Player,MemId).
%% arg : Player,MemId
%% return : {?ok,Player} | {?error, ErrorCode}
double_request(Player = #player{user_id = UserId,info = Info,user_state = UserState, maps = Maps},MemId) ->
	try
		?ok				= check_request_member(UserId,MemId),				%% 检查邀请人
		?ok				= check_double_state(UserState),
		{?ok,_,_} 		= check_player(Player),
		{?ok,_,_} 		= check_mem_player(MemId, map_api:get_cur_map_id(Player)),
		MapId = (Maps#map_data.cur)#map_info.map_id,
		case MapId =/= ?CONST_GUILD_PARTY_MAP of	%% 判定是否在军团宴会场景
			?true ->
				case is_doll(MemId) of
					?true ->
						practice_doll_double(MemId, UserId, Player, MapId);
					?false ->
						send_request(UserId,MemId,Info#info.user_name)
				end;
			?false ->
				case party_mod:is_doll(MemId) of
					?true ->
						TipPacket	= message_api:msg_notice(?TIP_PRACTICE_REQUEST),					
						misc_packet:send(UserId, TipPacket),
						?ok;
					?false ->
						send_request(UserId,MemId,Info#info.user_name) 						%% 发送请求
				end
		end
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

check_mem_player(MemId,MapId) ->
	{?ok,TInfo,TSys,TUserState,TPlayState, TMapData} 	= get_member_player(MemId, MapId),		%% 获取对方的player	
	?ok				= check_m_sys(TSys),									%% 检查对方等级
	?ok				= check_same_map((TMapData#map_data.cur)#map_info.map_id, MapId),				%% 检查是否同一场景
	?ok				= check_member_raiding(MemId),
	?ok				= check_member_state(TUserState),						%% 检查对方的状态
	?ok				= check_member_play_state(TPlayState),					%% 检查对方玩法状态
	PracticeUser	= ets_practice_user(MemId), 									%% 设置practice
	VipLv			= player_api:get_vip_lv(TInfo),
	TimeMax			= get_max_time(TInfo#info.lv,VipLv),		
	{?ok,Time}		= check_m_practice_time(PracticeUser#practice_user.sum_time,TimeMax), 
	{?ok,PracticeUser,Time}.

check_member_raiding(MemId) ->
	case player_state_api:is_raiding(MemId) of
		?false -> ?ok;
		_ ->
			throw({?error,?TIP_PRACTICE_MEM_DOUBLE_ERROR})
	end.
		
%% 检查邀请方
check_request_member(UserId,UserId) ->	
	throw({?error,?TIP_PRACTICE_YOURSELF});
check_request_member(_,_) -> ?ok.

%% 检查双修状态
check_double_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) ->
	throw({?error,?TIP_PRACTICE_DOUBLE_NOW});
check_double_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_double_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_double_state(_) -> 
	throw({?error,?TIP_PRACTICE_ERROR}).

%% 获取对方的Player
get_member_player(MemId, MapId) ->
	case MapId =:= ?CONST_GUILD_PARTY_MAP of
		?true ->
			case party_mod:is_doll(MemId) of
				?true ->	%% 军团宴会替身
					case player_api:get_player_fields(MemId, [#player.info,#player.sys_rank,#player.maps]) of
						{?ok, [Info,Sys,MapData]} ->
							Cur = MapData#map_data.cur,
							NewCur = Cur#map_info{map_id = ?CONST_GUILD_PARTY_MAP},
							MapData1 = MapData#map_data{cur = NewCur},
							{?ok,Info,Sys,?CONST_PLAYER_STATE_NORMAL,?CONST_PLAYER_PLAY_CITY,MapData1};
						_ ->
							throw({?error,?TIP_PRACTICE_DATA_ERROR})
					end;
				?false ->
					case player_api:check_online(MemId) of
						?true -> 
							case player_api:get_player_fields(MemId, [#player.info,#player.sys_rank,
																	  #player.user_state,#player.play_state, #player.maps]) of
								{?ok, [Info,Sys,UserState,PlayState, MapData]} ->
									{?ok,Info,Sys,UserState,PlayState, MapData};
								_ ->
									throw({?error,?TIP_PRACTICE_DATA_ERROR})
							end;
						?false ->
							throw({?error,?TIP_PRACTICE_DATA_ERROR})
					end
			end;
		?false ->
			case is_doll(MemId) of
				?true ->
					case player_api:get_player_fields(MemId, [#player.info,#player.sys_rank,#player.play_state, #player.maps]) of
						{?ok, [Info,Sys,PlayState,MapData]} ->
							{UserState, MapData1} =
								case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, MemId) of
									?null ->
										{?CONST_PRACTICE_SINGLE, MapData};
									PracticeDoll ->
										Cur = MapData#map_data.cur,
										NewCur = Cur#map_info{map_id = PracticeDoll#practice_doll.map_id},
										{PracticeDoll#practice_doll.practice_state, MapData#map_data{cur = NewCur}}
								end,
							{?ok,Info,Sys,UserState,PlayState,MapData1};
						_ ->
							throw({?error,?TIP_PRACTICE_DATA_ERROR})
					end;
				?false ->
					case player_api:check_online(MemId) of
						?true -> 
							case player_api:get_player_fields(MemId, [#player.info,#player.sys_rank,
																	  #player.user_state,#player.play_state, #player.maps]) of
								{?ok, [Info,Sys,UserState,PlayState, MapData]} ->
									{?ok,Info,Sys,UserState,PlayState, MapData};
								_ ->
									throw({?error,?TIP_PRACTICE_DATA_ERROR})
							end;
						?false ->
							throw({?error,?TIP_PRACTICE_DATA_ERROR})
					end
			end
	end.

%% 检查是否同一场景
check_same_map(MapId,MapId) -> ?ok;
check_same_map(_MapId1,_MapId2) ->
	throw({?error,?TIP_PRACTICE_MAP}).

%% 发送双修邀请
send_request(UserId,MemId,Name) ->
	TipPacket	= message_api:msg_notice(?TIP_PRACTICE_REQUEST),
	Packet 		= practice_api:msg_double_receive(UserId,Name),						
	misc_packet:send(MemId, Packet),
	misc_packet:send(UserId, TipPacket).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 双修回复	
%% practice_mod:double_reply(Player,MemId).
%% arg : Player,MemId
%% return : ?ok | {?error, ErrorCode}
double_reply(Player = #player{info = Info},MemId,?CONST_SYS_FALSE) -> %% 拒绝
	Name		= Info#info.user_name,
	Packet		= message_api:msg_notice(?TIP_PRACTICE_REJECT,[{?TIP_SYS_COMM,Name}]), 
	misc_packet:send(MemId, Packet),
	{?ok, Player};
double_reply(Player = #player{user_id = UserId,info = _Info,user_state = UserState,maps = Maps},MemId,_Type) ->
	try
		?ok						= check_request_member(UserId,MemId),				%% 检查邀请人
		?ok						= check_double_state(UserState),
		{?ok,PracticeUser,Time} = check_player(Player),
		{?ok,PracticeMem,TimeM} = check_mem_player(MemId, map_api:get_cur_map_id(Player)),
		double_practice(PracticeUser,MemId,Time,Maps,?CONST_SYS_TRUE),
		double_practice(PracticeMem,UserId,TimeM,Maps,?CONST_SYS_FALSE),
		player_api:process_send(MemId, ?MODULE, double_state_cb, []),
		Player2 			= Player#player{user_state = ?CONST_PLAYER_STATE_DOUBLE_PRACTISE}, 
		case is_doll(UserId) of
			?true ->
				map_api:change_user_state(Player2#player{practice_state = ?CONST_PLAYER_STATE_DOUBLE_PRACTISE}, ?CONST_MAP_PTYPE_PRACTICE_ROBOT),
				?ok 	= achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_DOUBLE_PRACTICE, 0, 1),
				schedule_api:add_guide_times(UserId, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE),
				ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.practice_state, ?CONST_PLAYER_STATE_DOUBLE_PRACTISE}]),
				practice_handler:handler(?MSG_ID_PRACTICE_CS_DOUBLE_STATE, Player2, {}),
				{?ok, Player2};
			?false ->
				{?ok, PlayerNew} 	= achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_DOUBLE_PRACTICE, 0, 1),
				schedule_api:add_guide_times(PlayerNew, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE)
		end
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%% 设置双修
double_practice(PracticeUser,MemId,Time,_Maps,Flag) -> 
	UserId			= PracticeUser#practice_user.user_id,
	PracticeUser2	= PracticeUser#practice_user{mem_id 	= MemId, 
												 start_time = misc:seconds()},
	Practice		= init_practice(UserId,?CONST_PLAYER_STATE_DOUBLE_PRACTISE),
	insert_practice_user(PracticeUser2),
	insert_practice(Practice),
	Time2			= Time div 2,
	Packet 			= practice_api:msg_double(MemId,Flag,Time2),
	Packet2 		= message_api:msg_notice(?TIP_PRACTICE_DOUBLE_SUCCESS),
	misc_packet:send(UserId, <<Packet/binary,Packet2/binary>>).

double_state_cb(Player,[]) ->
  	Player2 		= Player#player{user_state = ?CONST_PLAYER_STATE_DOUBLE_PRACTISE},
	{?ok, PlayerNew} 	= achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_DOUBLE_PRACTICE, 0, 1),
	schedule_api:add_guide_times(PlayerNew, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE).

%% 替身双休
practice_doll_double(UserId, MemId, Player2, MapId) ->
	TipPacket	= message_api:msg_notice(?TIP_PRACTICE_REQUEST),
	misc_packet:send(MemId, TipPacket),
	{?ok,TInfo,TSys,TUserState,TPlayState,TMapData} 	= get_member_player(UserId, MapId),		%% 获取替身的player
	Player = #player{user_id = UserId, user_state = TUserState, info = TInfo, sys_rank = TSys, play_state = TPlayState, maps = TMapData},
	practice_handler:handler(?MSG_ID_PRACTICE_DOUBLE_REPLY, Player, {?CONST_SYS_TRUE, MemId}),
	practice_handler:handler(?MSG_ID_PRACTICE_CS_DOUBLE_STATE, Player2#player{user_state = ?CONST_PRACTICE_DOUBLE}, {}),
	?ok.

%% 查看场景能否打坐
get_map_flag(MapId) ->
	case map_api:read_map_info(MapId) of
		?null -> 
			?CONST_SYS_FALSE;
		#rec_map{flag_train = Flag} ->
			Flag
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% vip设定
auto_options(UserId, Auto) ->
	PracticeUser 	= ets_practice_user(UserId),
	PracticeUser2	= PracticeUser#practice_user{auto = Auto},
	insert_practice_user(PracticeUser2).

auto_data(UserId) ->
	PracticeUser 	= ets_practice_user(UserId),
	PracticeUser#practice_user.auto.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 取消打坐
%% practice_mod:cancel(UserId).
%% arg : UserId
%% return : 
cancel(#player{user_id = UserId, info = Info,net_pid = Pid}) ->
	PracticeUser 	= ets_practice_user(UserId),
	PracticeUser2 	= PracticeUser#practice_user{mem_id = 0},
	MemId			= PracticeUser#practice_user.mem_id,
	insert_practice_user(PracticeUser2),
	delete_practice(UserId),
	%% 设置双修的对象
	PracticeMem		= ets_practice_user(MemId),			
	PracticeMem2	= PracticeMem#practice_user{mem_id = 0},
	insert_practice_user(PracticeMem2),
	if
		MemId =/= 0 -> %% 取消双修通知对方
			case is_doll(MemId) of
				?true ->
					robot_api:doll_cancel_double(MemId);
				?false ->
					?ignore
			end,
			player_api:process_send(MemId, ?MODULE, cancel_cb, [Info#info.user_name]),
			TipPacket	= message_api:msg_notice(?TIP_PRACTICE_DOUBLE_CANCEL),	
			misc_packet:send(Pid, TipPacket);
		?true -> ?ok
	end.

cancel_cb(Player = #player{user_id = UserId,net_pid = Pid,info = Info}, [Name]) ->  
	PracticeUser 	= ets_practice_user(UserId),
	VipLv			= player_api:get_vip_lv(Info),
	TimeMax			= get_max_time(Info#info.lv,VipLv),		
	Time			= TimeMax - PracticeUser#practice_user.sum_time, 
	PracticeUser2	= PracticeUser#practice_user{mem_id = 0},
	Practice		= ets_practice(UserId),
	Practice2		= Practice#practice{state = ?CONST_PLAYER_STATE_SINGLE_PRACTISE},
	
	Packet2 		= message_api:msg_notice(?TIP_PRACTICE_DOUBLE_CANCEL_NAME,[{?TIP_SYS_COMM, Name}]),	
	Packet3 		= practice_api:msg_single(?CONST_SYS_TRUE,Time),
	Player2			= Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL},	%% 普通状态	
	{_,Player3} 	= player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_SINGLE_PRACTISE), %% 单修状态
	insert_practice_user(PracticeUser2),
	insert_practice(Practice2),
	misc_packet:send(Pid, <<Packet2/binary,Packet3/binary>>),
 	achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_PRACTICE, 0, 1).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
send_exp(Practice) -> 
	player_api:process_send(Practice#practice.user_id, ?MODULE, send_exp_cb, [Practice]).

send_exp_cb(Player = #player{sys_rank = Sys}, P)  ->
    case Sys < data_guide:get_task_rank(?CONST_MODULE_PRACTICE) of
        true ->
	       {?ok,Player};	
        false ->
            send_exp_cb1(Player, P)
    end.

send_exp_cb1(Player = #player{user_id = UserId,info = Info,net_pid = Pid}, [Practice]) ->
	PracticeUser	= ets_practice_user(UserId),
	VipLv			= player_api:get_vip_lv(Info),
	TimeMax			= get_max_time(Info#info.lv,VipLv),		
	SumTime			= PracticeUser#practice_user.sum_time,
	SumTime2		= erlang:min(TimeMax, SumTime + ?CONST_PRACTICE_ONLINE_TIME), 
	Now 			= misc:seconds(),
	State   		= Practice#practice.state,
	Exp 			= get_online_exp(Info#info.lv),
	%% 在军团战地图中打坐经验提升100%
	Exp2 = get_extra_exp(Player, Exp),
	
	Packet16008  	= practice_api:msg_reward(State,Exp2),	
	Packet16300		= practice_api:msg_sc_finish_time(SumTime2),
	Practice2 		= Practice#practice{exp_time = Now},
	PracticeUser2	= PracticeUser#practice_user{sum_time = SumTime2},
	{?ok,Player2} 	= player_api:exp(Player, Exp2),
	
%% 	%% 在军团战地图中打坐经验提升100%
%% 	GuildPvpMap = guild_pvp_api:get_guild_pvp_map_id(),
%% 	if
%% 		Info#info.map_id =:= GuildPvpMap ->
%% 			gen_server:cast(guild_pvp_serv, {add_guild_pvp_exp, Player, Exp});
%% 		true ->
%% 			next
%% 	end,
	{?ok,Player3} 	= welfare_api:add_pullulation(Player2, ?CONST_WELFARE_PRACTICE, 0, 1),
	insert_practice(Practice2),
	insert_practice_user(PracticeUser2),
	misc_packet:send(Pid, <<Packet16008/binary,Packet16300/binary>>),		
 	if
		TimeMax - SumTime2 =< 0 ->
			{_,Player4} 	= player_state_api:try_set_state(Player3, ?CONST_PLAYER_STATE_NORMAL),
			{?ok,Player4};
		?true -> 
			{?ok,Player3}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 双修状态广播
double_broadcast(Player = #player{user_id = UserId,user_state = ?CONST_PLAYER_STATE_DOUBLE_PRACTISE}) ->
	PracticeUser 	= ets_practice_user(UserId),	
	MemId			= PracticeUser#practice_user.mem_id,
	IsDollUser		= is_doll(UserId),
	IsDollOther		= is_doll(MemId),
	F = fun({Id, Type}) ->
				ets_api:update_element(?CONST_ETS_MAP_PLAYER, {Type, Id}, [{#map_player.practice_state, ?CONST_PLAYER_STATE_DOUBLE_PRACTISE}])
		end,
	List =
		if 
			IsDollUser =:= ?true ->
				map_api:change_double(Player, ?CONST_PLAYER_STATE_DOUBLE_PRACTISE, MemId, ?CONST_MAP_PTYPE_PRACTICE_ROBOT, ?CONST_MAP_PTYPE_HUMAN),
				[{UserId, ?CONST_MAP_PTYPE_PRACTICE_ROBOT}, {MemId, ?CONST_MAP_PTYPE_HUMAN}];
			IsDollOther =:= ?true ->
				map_api:change_double(Player, ?CONST_PLAYER_STATE_DOUBLE_PRACTISE, MemId, ?CONST_MAP_PTYPE_HUMAN, ?CONST_MAP_PTYPE_PRACTICE_ROBOT),
				[{UserId, ?CONST_MAP_PTYPE_HUMAN}, {MemId, ?CONST_MAP_PTYPE_PRACTICE_ROBOT}];
			?true ->
				map_api:change_double(Player,?CONST_PLAYER_STATE_DOUBLE_PRACTISE, MemId),
				[{UserId, ?CONST_MAP_PTYPE_HUMAN}, {MemId, ?CONST_MAP_PTYPE_HUMAN}]
		end,
	[F(E) || E <- List],
	Packet 			= map_api:msg_sc_change_double(UserId, MemId),
    map_api:broadcast(Player, Packet),
	{?ok,Player};
double_broadcast(Player) -> {?ok,Player}.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 在线修炼经验 player_vip_api:get_online_practice_add(0).
get_online_exp(Lv) ->
	case data_practice:get_practice(Lv) of
		Practice when is_record(Practice,rec_practice) ->
			Practice#rec_practice.exp;
		_ -> 0
	end.

get_max_time(Lv,Vip) ->
	get_rec_time(Lv) + get_vip_time(Vip).

get_vip_time(Vip) ->
 	player_vip_api:get_online_practice_time(Vip) * 3600.

get_rec_time(Lv) ->
 	case data_practice:get_practice(Lv) of
		Practice when is_record(Practice,rec_practice) ->
			Practice#rec_practice.time;
		_ -> 0
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 退出游戏
logout(#player{user_id = UserId,info = Info, sys_rank = Sys}) -> 
    case Sys < data_guide:get_task_rank(?CONST_MODULE_PRACTICE) of
        true ->
            ?ok;
        false ->
        	PracticeUser 	= ets_practice_user(UserId),
        	PracticeUser2 	= PracticeUser#practice_user{mem_id = 0},	
        	MemId			= PracticeUser#practice_user.mem_id,	
        	insert_practice_user(PracticeUser2),
        	practice_db_mod:replace_data(PracticeUser2),
        	delete_practice(UserId),
			if
				MemId =/= 0 -> %% 取消双修通知对方
					case is_doll(MemId) of
						?false ->
							player_api:process_send(MemId, ?MODULE, cancel_cb, [Info#info.user_name]);
						?true ->
							robot_api:doll_cancel_double(MemId)
					end;
        		?true -> ?ok
        	end
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear_cd(Player = #player{user_id = UserId,info = Info,net_pid = Pid,user_state = UserState},Type) ->
	try
		PracticeUser 	= ets_practice_user(UserId),
		Practice		= ets_practice(UserId),
		VipLv			= player_api:get_vip_lv(Info),
		TimeMax			= get_max_time(Info#info.lv,VipLv),		
		SumTime			= PracticeUser#practice_user.sum_time,
		{?ok,Time,SumTime2}		= check_clear_time(SumTime,TimeMax,UserState,Type),
		Count			= misc:ceil(Time/?CONST_PRACTICE_ONLINE_TIME),
		Money			= Count * ?CONST_PRACTICE_CLEAR_MONEY,
		Exp 			= Count * get_online_exp(Info#info.lv),
		%% 在军团战地图中打坐经验提升100%
		Exp2 = get_extra_exp(Player, Exp),
		?ok				= check_minus_money(UserId,Money),
		LTime			= TimeMax - SumTime2,
		PracticeUser2	= PracticeUser#practice_user{sum_time = SumTime2},
		{?ok,Player2}	= player_api:exp(Player, Exp2),
		
		insert_practice_user(PracticeUser2),
		if
			LTime > 0 ->
				Packet16008  	= practice_api:msg_reward(Practice#practice.state,Exp),
				Packet16202		= practice_api:msg_sc_time(LTime),
				Packet16300		= practice_api:msg_sc_finish_time(SumTime2),
				misc_packet:send(Pid, <<Packet16008/binary,Packet16202/binary,Packet16300/binary>>),
				{?ok,Player2};
			?true ->
				Packet16300		= practice_api:msg_sc_finish_time(SumTime2),
				{_,Player3} 	= player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_NORMAL),
				misc_packet:send(Pid,Packet16300),
				{?ok,Player3}
		end
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	


check_clear_time(SumTime,TimeMax,_,_) when SumTime >= TimeMax ->		
	throw({?error,?TIP_PRACTICE_TIME_FULL}); 
check_clear_time(SumTime,TimeMax,_,1) ->
	{?ok,TimeMax - SumTime,TimeMax};
check_clear_time(SumTime,TimeMax,?CONST_PLAYER_STATE_DOUBLE_PRACTISE,2) ->
	Time = 7200,
	if
		TimeMax >= Time + SumTime ->
			{?ok,Time,SumTime + Time};
		?true ->
			{?ok,TimeMax-SumTime,TimeMax}
	end;
check_clear_time(SumTime,TimeMax,_,2) ->
	Time = 3600,
	if
		TimeMax >= Time + SumTime ->
			{?ok,Time,SumTime + Time};
		?true ->
			{?ok,TimeMax-SumTime,TimeMax}
	end.

check_minus_money(UserId,Money) ->
	case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Money, ?CONST_COST_PRACTICE_CLEAR_CD) of
		{?error,_ErrorCode} ->
			throw({?error,?TIP_COMMON_CASH_NOT_ENOUGH});
		_ -> ?ok
	end.		 
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ets_practice_user(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_USER, UserId) of
	  	?null ->
			init_practice_user(UserId);
	  	PracticeUser ->
		  	update_practice_user(PracticeUser) 
	end.

update_practice_user(PracticeUser) ->
	Time 	= PracticeUser#practice_user.start_time, 
	Now		= misc:seconds(),
	case misc:is_same_date(Time, Now) of
		?true ->
			PracticeUser;
		_ ->
			PracticeUser#practice_user{sum_time = 0,start_time = Now}
	end.

insert_practice_user(PracticeUser) ->
	ets_api:insert(?CONST_ETS_PRACTICE_USER, PracticeUser).

ets_practice(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE, UserId) of
	  	?null ->
			init_practice(UserId,0);
	  	Practice ->	
		  	Practice
	end.

insert_practice(Practice) ->
	ets_api:insert(?CONST_ETS_PRACTICE, Practice).

delete_practice(UserId) ->
	ets_api:delete(?CONST_ETS_PRACTICE,UserId).

%% 在军团战地图中打坐经验提升100%
get_extra_exp(Player, Exp) ->
	GuildPvpMap = guild_pvp_api:get_guild_pvp_map_id(),
	Guild = Player#player.guild,
	GuildId = Guild#guild.guild_id,
	ToweGuildId = guild_pvp_mod:get_tower_owner_id(), 
    MapId = map_api:get_cur_map_id(Player),
	if 
        MapId =:= GuildPvpMap 
		  andalso  GuildId =:=  ToweGuildId ->
		   Exp * 2;
	   true ->
		   Exp
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_practice_user(UserId) ->
	#practice_user{
				  	user_id 			= UserId	% 玩家
				  }.

init_practice(UserId,State) ->
	#practice{
			  user_id	= UserId,
			  state		= State,
			  exp_time	= misc:seconds()
			  }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 设置离线机器人
set_offline_robot(Player, Type, TotalHour) ->
	try
		UserId			= Player#player.user_id,
		?ok				= check_condition(Player),
		{?ok, TimeMax, RestTime} = get_time_info(Player),
		ValidTime		= get_rest_valid_time(UserId, Type, TimeMax, RestTime),
		TotalTime		= get_total_time(TotalHour, ValidTime),
		CheckCash		= misc:ceil(TotalTime / ?CONST_PRACTICE_ONLINE_TIME * 2 * ?CONST_PRACTICE_AUTO_CASH),
		case player_money_api:check_money(UserId, ?CONST_SYS_CASH, CheckCash) of
			{?error, ErrorCode} ->
				throw({?error, ErrorCode});
			{?ok, _Money, ?false} ->
				throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH});
			{?ok, _Money, ?true} ->
				PraticeDoll = make_practice_doll_record(UserId, Type, TotalTime, RestTime, 1),
				ets_api:insert(?CONST_ETS_PRACTICE_DOLL, PraticeDoll),
				?ok
		end
	catch
		throw:Return -> 
			Return;
		E:R ->
			?MSG_ERROR("Error type:~p, Reason: ~p, Strace:~p~n ", [E, R, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%% 检查修炼条件
check_condition(#player{user_id = UserId, sys_rank = Sys, play_state = PlayState}) ->
	?CONST_SYS_TRUE = robot_api:is_open_robot(practice),%% 检查离线替身开放
	?ok				= check_sys(Sys),					%% 检查等级
	?ok				= check_raiding(UserId),
	?ok				= check_player_state(PlayState).	%% 检查玩法状态

%% 获取修炼时间信息
get_time_info(#player{user_id = UserId, info = Info}) ->
	SumTime			= get_practic_sum_time(UserId),
	VipLv			= player_api:get_vip_lv(Info),
	TimeMax			= get_max_time(Info#info.lv, VipLv),	
	{?ok, RestTime}	= 
		case catch check_practice_time(SumTime, TimeMax) of
			{?error, ?TIP_PRACTICE_TIME_FULL} ->
				{?ok, 0};
			Other ->
				Other
		end,
	{?ok, TimeMax, RestTime}.

%% 获取修炼剩余有效时间
get_rest_valid_time(UserId, Type, TimeMax, RestTime) ->
	TodayRestTime = misc:get_next_midnight_second(),
	TomorrowTime =
		case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
			?null ->
				0;
			#practice_doll{date_uts = DateUTs} ->
				{_, NextMid} 	= misc:get_midnight_seconds(misc:seconds()),
				{NextDate, _}	= misc:seconds_to_localtime(NextMid),
				AddTime = get_add_time(DateUTs, NextDate),
				AddTime
		end,
	case Type of
		?CONST_PRACTICE_TODAY ->
			erlang:min(RestTime, TodayRestTime);
		?CONST_PRACTICE_TOMORROW ->
			erlang:max(0, TimeMax - TomorrowTime);
		?CONST_PRACTICE_TODAY_TOMORROW ->
			erlang:min(RestTime, TodayRestTime) + erlang:max(0, TimeMax - TomorrowTime)
	end.

%% 获取未修炼的总时长
get_total_time(TotalHour, ValidTime) ->
	case TotalHour * 3600 > ValidTime of
		?true ->
			ValidTime;
		?false ->
			TotalHour * 3600
	end.

%% 获取已修炼的总时长
get_practic_sum_time(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_USER, UserId) of
		?null ->
			0;
	  	PracticeUser ->
			PracticeUser#practice_user.sum_time
	end.

make_practice_doll_record(UserId, Type, TotalTime, RestTime, IsSet) ->
	PracticeDoll 	= get_practice_doll(UserId),
	{NowDate, NowTime} = get_now_day_and_sec_time(),
	{_, NextMid} 	= misc:get_midnight_seconds(NowTime),
	{NextDate, _}	= misc:seconds_to_localtime(NextMid),
	PracticeDoll#practice_doll{
							   user_id = UserId,
							   type = Type,
							   total_time = TotalTime,
							   rest_time = RestTime,
							   set_time = NowTime,
							   set_date = NowDate,
							   set_next_date = NextDate,
							   is_set = IsSet
							  }.

get_practice_doll(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
		?null ->
			#practice_doll{};
		PracticeDoll ->
			PracticeDoll
	end.

%% 更新离线修炼替身信息(下线)
update_practice_doll(Player, logout) ->
	UserId = Player#player.user_id,
	try
		case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
			?null ->
				?ignore;
			PracticeDoll ->
				#practice_doll{type = Type, total_time = OldTotalTime} = PracticeDoll,
				{?ok, TimeMax, RestTime} =  get_time_info(Player),
				TodayRestTime = misc:get_next_midnight_second(),
				ValidRestTime = get_rest_valid_time(UserId, Type, TimeMax, RestTime),
				TotalTime = erlang:min(OldTotalTime, ValidRestTime),
				NewPracticeDoll = PracticeDoll#practice_doll{
															 logout_time = misc:seconds(),
															 total_time = TotalTime,
															 rest_time = erlang:min(RestTime, TodayRestTime)
															},
				ets_api:insert(?CONST_ETS_PRACTICE_DOLL, NewPracticeDoll),
				?ok
		end
	catch
		E:R ->
			?MSG_ERROR("Error type:~p, Reason: ~p, Strace:~p~n ", [E, R, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end;

%% 更新离线修炼替身信息(上线)
update_practice_doll(Player, login) ->
	try
		UserId = Player#player.user_id,
		%% 清除机器人
		robot_api:doll_quit_practice(Player),
		case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
			?null ->
				Player;
			PracticeDoll ->
				case PracticeDoll#practice_doll.is_set of
					1 ->
						ValidTime	= get_offline_valid_time(PracticeDoll),
						ValidTimes	= get_offline_use_time(ValidTime, PracticeDoll),
						ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.valid_times, ValidTimes}]),
						case ValidTimes =/= 0 of
							?true ->
								{?ok, Player2} = schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE),
								Player2;
							?false ->
								Player
						end;
					_ ->
						Player
				end
		end
	catch
		throw:Return ->
			?MSG_ERROR("throw error:~p", [Return]),
			Player;
		E:R ->
			?MSG_ERROR("Error type:~p, Reason: ~p, Strace:~p~n ", [E, R, erlang:get_stacktrace()]),
			%{?error,?TIP_COMMON_BAD_ARG},
			Player
	end.

%% 获取离线修炼有效时长
get_offline_valid_time(#practice_doll{logout_time = LogoutTime, total_time = TotalTime}) ->
	OfflineTime = misc:seconds() - LogoutTime,
	ValidTime = erlang:max(0, erlang:min(OfflineTime, TotalTime)),
	ValidTime div ?CONST_PRACTICE_ONLINE_TIME * ?CONST_PRACTICE_ONLINE_TIME.

%% 获取当前是日期和时间描述
get_now_day_and_sec_time() ->
	NowTime			= misc:seconds(),
	{NowDate, _}	= misc:date_time(),
	{NowDate, NowTime}.

%% 获取离线用了的有效时间
get_offline_use_time(ValidTime, PracticeDoll) ->
	#practice_doll{type = Type, rest_time = RestTime} = PracticeDoll,
	{SetDayUT, SetNextDayUT} =
		case Type of
			?CONST_PRACTICE_TODAY ->
				{ValidTime, 0};
			?CONST_PRACTICE_TOMORROW ->
				{0, ValidTime};
			?CONST_PRACTICE_TODAY_TOMORROW ->
				Temp = erlang:min(RestTime, ValidTime),
				{Temp, erlang:max(0, ValidTime - Temp)}
		end,
	F = fun(T) ->
				T div ?CONST_PRACTICE_ONLINE_TIME * ?CONST_PRACTICE_ONLINE_TIME
		end,
	[F(Time) || Time <- [SetDayUT, SetNextDayUT]].

%% 更新玩家新的修炼总时长
update_practice_user_sumtime(UserId, DateUTs, TimeMax) ->
	PracticeUser = ets_practice_user(UserId),
	{NowDate, _} = misc:date_time(),
	AddTime = get_add_time(DateUTs, NowDate),
	SumTime = erlang:min(TimeMax, PracticeUser#practice_user.sum_time + AddTime),
	insert_practice_user(PracticeUser#practice_user{sum_time = SumTime}).

%% 设置离线替身奖励
set_doll_award(#player{user_id = UserId, info = Info} = Player) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
		?null ->
			?ignore;
		#practice_doll{valid_times = [0,0], date_uts = DateUTs, is_set = IsSet} ->
			ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.is_set, 0}]),
			clean_parctice_doll(UserId, DateUTs),
			case IsSet of
				1 ->
					mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PRACTICE_DOLL_TIME_TOO_SHORT,
													  [], [], 0, 0, 0, ?CONST_COST_PRACTICE_DOLL_EXP),
					?ignore;
				_ ->
					?ignore
			end;
		#practice_doll{valid_times = ValidTimes, date_uts = DateUTs, set_date = SetDate, set_next_date = SetNextDate} ->
			ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.valid_times, [0,0]}, {#practice_doll.is_set, 0}]),
			Money = player_money_api:lookup_money(UserId),
			case  Money#money.cash =< 0 of
				?true ->
					mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PRACTICE_DOLL_CASH_NOT_ENOUGH,
													  [], [], 0, 0, 0, ?CONST_COST_PRACTICE_DOLL_EXP);
				?false ->
					{?ok, TimeMax, _CurRestTime} = get_time_info(Player),
					{NowDate, _} = misc:date_time(),
					player_api:process_send(UserId, ?MODULE, doll_reward_cb, [ValidTimes, DateUTs, TimeMax, SetDate, SetNextDate, NowDate])
			end
	end.

%% 离线修炼奖励
doll_reward_cb(#player{user_id = UserId, info = Info, net_pid = NetPid} = Player, [ValidTimes, DateUTs, TimeMax, SetDate, SetNextDate, NowDate]) ->	
	ValidTime = lists:sum(ValidTimes),
	ReduceCash = misc:ceil(ValidTime div ?CONST_PRACTICE_ONLINE_TIME * 2 * ?CONST_PRACTICE_AUTO_CASH),
	{Result, CheckCash, NewValidTimes} =
		case player_money_api:check_money(UserId, ?CONST_SYS_CASH, ReduceCash) of
			{?error, ErrorCode} ->
				?MSG_ERROR("offline practice doll cash error:~w", [ErrorCode]),
				{?error, 0, [0, 0]};
			{?ok, Money, ?false} ->
				NowCash = Money#money.cash,
				ValidTimes1 = get_new_valid_time(NowCash, ValidTimes),
				{?ok, NowCash, ValidTimes1};
			{?ok, _Money, ?true} ->
				{?ok, ReduceCash, ValidTimes}
		end,
	Player2 =
		case Result of
			?error ->
				Player;
			?ok ->
				case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CheckCash, ?CONST_COST_PRACTICE_AUTO_CASH) of
					{?error, ErrorCode1} ->
						?MSG_ERROR("practice doll minus cash error:~w", [ErrorCode1]),
						Player;
					?ok ->
						ValidTime1 = lists:sum(NewValidTimes),
						PerExp = get_online_exp(Info#info.lv),
						Exp = trunc(ValidTime1 div ?CONST_PRACTICE_ONLINE_TIME * PerExp),
						NewDateUTs = update_date_uts(DateUTs, SetDate, SetNextDate, NewValidTimes),
						NewDateUTs1 = lists:keydelete(NowDate, 1, NewDateUTs),
						ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.date_uts, NewDateUTs1}]),
						update_practice_user_sumtime(UserId, NewDateUTs, TimeMax),
						SumTime =
							case ets_api:lookup(?CONST_ETS_PRACTICE_USER, UserId) of
								?null ->
									0;
								Tuple ->
									Tuple#practice_user.sum_time
							end,
						Packet16300	= practice_api:msg_sc_finish_time(SumTime),
						misc_packet:send(NetPid, Packet16300),
						{?ok, Player1} 	= player_api:exp(Player, Exp),
						mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PRACTICE_DOLL_SEND,
														  [{[{misc:to_list(ValidTime1 div ?CONST_PRACTICE_ONLINE_TIME * 2)}]}, {[{misc:to_list(CheckCash)}]}, {[{misc:to_list(Exp)}]}],
														  [], 0, 0, 0, ?CONST_COST_PRACTICE_DOLL_EXP),
						Player1
				end
		end,
	{?ok, Player2}.

%% 清理无效替身数据
clean_parctice_doll(UserId, DateUTs) ->
	{NowDate, NowTime} 	= get_now_day_and_sec_time(),
	{TodayMid, NextMid} = misc:get_midnight_seconds(NowTime),
	{LastDate, _}		= misc:seconds_to_localtime(TodayMid - 10),
	{NextDate, _}		= misc:seconds_to_localtime(NextMid),
	case lists:filter(fun({D, _}) -> D =:= LastDate orelse D =:= NowDate orelse D =:= NextDate end, DateUTs) of
		[] ->
			ets_api:delete(?CONST_ETS_PRACTICE_DOLL, UserId);
		_ ->
			?ignore
	end.

%% 获取新的有效时间
get_new_valid_time(NowCash, ValidTimes) ->
	RealUseTime = trunc(NowCash / ?CONST_PRACTICE_AUTO_CASH * ?CONST_PRACTICE_ONLINE_TIME / 2),
	F = fun(Time, {Acc1, Acc2}) ->
				case Acc1 - Time > 0 of
					?true ->
						{Acc1 - Time, [Time|Acc2]};
					?false ->
						{0, [Acc1|Acc2]}
				end
		end,
	{_A1, A2} = lists:foldl(F, {RealUseTime, []}, ValidTimes),
	lists:reverse(A2).

%% 更新有效时间列表
update_date_uts(DateUTs, SetDate, SetNextDate, [SetDayUT, SetNextDayUT]) ->
	F = fun({Date, UT}, Acc) ->
				case UT =/= 0 of
					?true ->
						case lists:keyfind(Date, 1, Acc) of
							?false ->
								[{Date, UT}|Acc];
							{Date, OldTime} ->
								lists:keystore(Date, 1, Acc, {Date, OldTime + UT})
						end;
					?false ->
						Acc
				end
		end,
	lists:foldl(F, DateUTs, [{SetDate, SetDayUT}, {SetNextDate, SetNextDayUT}]).

%% 获取增加的时间
get_add_time(DateUTs, CompareDate) ->
	case [UseTime || {Date, UseTime} <- DateUTs, Date =:= CompareDate] of
		[] ->
			0;
		List when erlang:is_list(List) ->
			hd(List);
		_ ->
			0
	end.

%% 查询离线修炼设置
query_offline_set(#player{user_id = UserId}) ->
	Result =
		case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
			?null ->
				0;
			PracticeDoll ->
				PracticeDoll#practice_doll.is_set
		end,
	Packet = practice_api:msg_sc_offline_set_rep(Result),
	misc_packet:send(UserId, Packet),
	?ok.

%% 取消离线修炼设置
cancel_offline_set(#player{user_id = UserId}) ->
	Tip =
		case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
			?null ->
				?TIP_PRACTICE_AUTO_PLEASE_SET;
			_PracticeDoll ->
				ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.is_set, 0}]),
				?TIP_PRACTICE_AUTO_CANCEL_SUCCESS
		end,
	TipPacket = message_api:msg_notice(Tip), 
	misc_packet:send(UserId, TipPacket),
	?ok.

%% 判定是否是替身
is_doll(UserId) ->
	case player_api:check_online(UserId) of
		?true ->
			?false;
		?false ->
			?null =/= ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId)
	end.

%% 替身取消双修状态
doll_cancel_double(Player) ->
	UserId = Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_PRACTICE_USER, UserId) of
		?null ->
			?ignore;
		PracticeUser ->
			MemId = PracticeUser#practice_user.mem_id,
			case is_doll(MemId) of
				?false ->
					?ignore;
				?true ->
					robot_api:doll_cancel_double(MemId)
			end
	end.

%% 增加第二天时间
add_tomorrow_time() ->
	List = ets_api:list(?CONST_ETS_PRACTICE_DOLL),
	add_tomorrow_time(List).

add_tomorrow_time([]) -> ?ok;
add_tomorrow_time([#practice_doll{user_id = UserId, date_uts = DateUTs, is_set = IsSet} | Tail]) ->
	{NowDate, _}	= misc:date_time(),
	AddTime = get_add_time(DateUTs, NowDate),
	PracticeUser = ets_practice_user(UserId),
	Info =
		case player_api:get_player_fields(UserId, [#player.info]) of
			{?ok, [Info1]} ->
				Info1;
			{?error, Error} ->
				?MSG_ERROR("not find info error:~p", [Error]),
				#info{}
		end,
	VipLv			= player_api:get_vip_lv(Info),
	TimeMax			= get_max_time(Info#info.lv, VipLv),
	SumTime 		= erlang:min(TimeMax, PracticeUser#practice_user.sum_time + AddTime),
	insert_practice_user(PracticeUser#practice_user{sum_time = SumTime, start_time = misc:seconds()}),
	case {DateUTs, IsSet} of
		{[], 0} ->
			ets_api:delete(?CONST_ETS_PRACTICE_DOLL, UserId);
		{_, 1} ->
			case player_api:check_online(UserId) of
				?true ->
					case DateUTs of
						[] ->
							ets_api:delete(?CONST_ETS_PRACTICE_DOLL, UserId);
						_ ->
							ets_api:update_element(?CONST_ETS_PRACTICE_DOLL, UserId, [{#practice_doll.is_set, 0}])
					end,
					Packet = practice_api:msg_sc_offline_clean(),
					misc_packet:send(UserId, Packet),
					mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PRACTICE_DOLL_MID_REFRESH,
													  [], [], 0, 0, 0, ?CONST_COST_PRACTICE_DOLL_EXP);
				?false ->
					?ok
			end;
		_ ->
			?ok
	end,
	add_tomorrow_time(Tail).
		
	
%% 清理机器人
clear_robot() ->
	List = ets_api:list(?CONST_ETS_PRACTICE_DOLL),
	clear_robot(List).

clear_robot([]) -> ?ok;
clear_robot([#practice_doll{user_id = UserId, logout_time = LogoutTime, total_time = TotalTime} | Tail]) ->
	NowTime = misc:seconds(),
	case NowTime - LogoutTime > TotalTime of
		?true ->
			PracticeUser = ets_practice_user(UserId),
			MemId = PracticeUser#practice_user.mem_id,
			case MemId =/= 0 of
				?true ->
					case player_api:get_player_fields(MemId, [#player.info]) of
						{?ok, [Info]} ->
							Player = #player{user_id = UserId, info = Info},
							cancel(Player);
						{?error, ErrorCode} ->
							?MSG_ERROR("get player info error:~w", [ErrorCode])
					end;
				?false ->
					?ignore
			end,
			robot_api:doll_quit_practice(#player{user_id = UserId});
		?false ->
			?ignore
	end,
	clear_robot(Tail).

%% 获取可修炼时间
get_valid_time(Player, Type) ->
	try
		UserId = Player#player.user_id,
		{?ok, TimeMax, RestTime} = get_time_info(Player),
		get_rest_valid_time(UserId, Type, TimeMax, RestTime)
	catch
		E:R ->
			?MSG_ERROR("Error type:~p, Reason: ~p, Strace:~p~n ", [E, R, erlang:get_stacktrace()]),
			0
	end.
