%% Author: Administrator
%% Created: 2012-8-22
%% Description: TODO: Add description to spring_mod
-module(spring_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.tip.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([
		 enter/1, quit/1,
		 quit_reward/1,acitve_end_quit/1,
		 exp/1, exp_cb/2,
 		 double_request/3,
		 double_reply/4,reply_cd/2,
		 double_notice/3,
  		 double_cancel/1,cancel_cb/2,
		 request_get_sp/1 ,
		 set_auto/2,
		 add_guide_times/1, 
		 add_achievement/2,
		 save_doll_data/1
		]).

%%
%% API Functions
%%
%% 关服保存
save_doll_data(SpringDoll) ->
    case mysql_api:select(<<"replace into `game_spring_doll`(`user_id`,`record`)value('", (misc:to_binary(SpringDoll#spring_doll.user_id))/binary, 
							"',", (mysql_api:encode(SpringDoll))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 进入玩法
enter(Player = #player{user_id = UserId,account = Account,info = Info,sys_rank = Sys,net_pid = Pid}) -> 
	try
		{?ok,Flag}			= get_activity_flag(),					%% 活动标识
		?ok					= check_open_sys(Sys), 					%% 系统是否开放
		?ok					= check_enter_map(map_api:get_cur_map_id(Player)), 	%% 检查地图
		{?ok,Player2}		= set_enter_state(Player),				%% 设置玩家状态
		?ok					= check_enter_auto(UserId, Flag), 
		{?ok,Time}			= get_end_time(),						%% 取得结束时间
		
		{?ok,Spring}		= get_spring_data(UserId),
 		PacketTime			= spring_api:msg_scenter(Time), 	 
		PacketExp 			= spring_api:msg_scexp(Spring#spring_info.exp),
		PacketSp			= spring_api:msg_scps(Spring#spring_info.sp),
		PacketAuto			= spring_api:msg_sc_auto(Spring#spring_info.auto),
		Pakcet28316			= spring_api:msg_sc_sp_time(Spring#spring_info.sp_time),
		Spring2				= Spring#spring_info{enter_time = misc:seconds(),
												 state = ?CONST_PLAYER_STATE_NORMAL},
		
		NewPlayer 			= map_api:enter_map(Player2, ?CONST_SPRING_MAP_ID),	%% 拉进场景
 		{?ok, NewPlayer2}	= add_guide_times(NewPlayer),			%% 目标
		{?ok, NewPlayer3}	= add_achievement(NewPlayer2,Flag),		%% 成就
        catch yunying_activity_mod:update_shuangdan_activity_info(UserId,1001,1),         %双旦活动骊山汤检测
		schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_SPRING),
		insert_spring_info(Spring2),
		Packet				= <<PacketTime/binary,PacketExp/binary,PacketSp/binary,PacketAuto/binary,Pakcet28316/binary>>,
 		misc_packet:send(Pid, Packet),
		case Flag of
			1 ->
				admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_SPRING, misc:seconds());
			_ ->
				admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_SPRING2, misc:seconds())
		end,
		{?ok,NewPlayer3}
	catch
		throw:{?error,ErrorCode} -> 
			error_msg(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查自动参加
check_enter_auto(UserId, Flag) ->
	Type		= 
		case Flag of
			1 ->
				?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING;
			_ ->
				?CONST_SCHEDULE_ACTIVITY_LATE_SPRING
		end,
	case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
		?null -> ?ok;
		Tuple when is_record(Tuple, spring_doll) ->
			case lists:member(Type, Tuple#spring_doll.spring_ids) of
				?false ->
					?ok;
				?true ->
					throw({?error,?TIP_SPRING_AUTO_STATE})
			end
	end.
	

%% 检查地图
check_enter_map(?CONST_SPRING_MAP_ID) ->
	throw({?error,?TIP_SPRING_JION_NOW});
check_enter_map(_) -> ?ok.

%% 检查开发系统
check_open_sys(Sys)  -> 
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_SPRING) of
        true ->
            ?ok;
        false ->
        	throw({?error,?TIP_SPRING_SYS_OPEN})
    end.
	
%% 取得结束时间
get_end_time() ->
	Time = misc:seconds(),
	case spring_api:ets_spring() of
		#spring_active{end_time = EndTime} when EndTime > Time ->
			{?ok, EndTime - Time};
		_ ->
			{?ok,0}
	end.

%% 取得#spring{}
get_player_spring(Spring) when is_record(Spring,spring) ->
	{?ok,Spring};
get_player_spring(_) ->
	{?ok,#spring{}}.

%% 取得活动标识
get_activity_flag() ->
	case spring_api:ets_spring() of
		#spring_active{flag = Flag} ->
			{?ok, Flag};
		_ ->
			throw({?error,?TIP_SPRING_OFF})
	end.

%% 检查活动是否开放
check_active_open() ->
	case spring_api:ets_spring() of
		?null -> 
			throw({?error,?TIP_SPRING_OFF});
		_ -> ?ok
	end.

%% 目标 
add_guide_times(Player)	->
	schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_SPRING).

%% 成就
add_achievement(Player,Flag) ->
	{?ok, PlayerSpring} = get_player_spring(Player#player.spring),
	Time				= misc:seconds(),
	PlayerSpring2		= PlayerSpring#spring{time = Time, flag = Flag},
	IsToday 			= misc:is_same_date(PlayerSpring#spring.time, Time),
	Player2 			= Player#player{spring = PlayerSpring2},
	if
		IsToday =:= ?true andalso PlayerSpring#spring.flag =:= Flag ->		
			{?ok,Player2};
		?true ->
			achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_SPRING, 0, 1)
	end.

%% 设置进入的玩法状态
set_enter_state(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_SPRING) of
		{?true, Player2} ->
			{?ok,Player2};
		{_,_,ErrorCode} ->
			throw({?error,ErrorCode})
	end.

%% 取得ets数据 #spring_info{}
get_spring_data(UserId) ->
	case ets_spring_info(UserId) of
		?null ->
			Spring 	= init_spring(UserId);
		Spring -> ?ok
	end,
	{?ok,Spring}.

ets_spring_info(UserId) ->
	ets_api:lookup(?CONST_ETS_SPRING_INFO, UserId).

insert_spring_info(SpringInfo) ->
	ets:insert(?CONST_ETS_SPRING_INFO, SpringInfo).

%% 自动退出或离线
quit(Player = #player{user_id = UserId,info = Info,net_pid = Pid,map_pid = MapPid}) ->
    MapId = map_api:get_cur_map_id(Player),
  if
      MapId =:= ?CONST_SPRING_MAP_ID -> 
    	case ets_spring_info(UserId) of
    		?null -> ?ok;
    		Spring = #spring_info{mem_id = MemId,enter_time = EnterTime,time = Time,sp_time = SpTime} ->		
    			quit_notice_mem(UserId,Info#info.user_name,MapPid,MemId),
    			Now				= misc:seconds(),
    			AddTime			= get_enter_time(Now,EnterTime),
    			Spring2			= Spring#spring_info{enter_time = Now,
    												 time 		= Time + AddTime,
    											     sp_time 	= SpTime + AddTime,
    												 state 		= 0,
    												 mem_id 	= 0},
    			insert_spring_info(Spring2)
    	end,
    	Player2 = map_api:return_last_city(Player),
    	Packet28306		= spring_api:msg_scexit(UserId),
    	misc_packet:send(Pid, Packet28306),
    	set_quit_state(Player2);
    ?true ->
        {?ok,Player}
    end;
quit(Player) ->
	{?ok,Player}.

quit_notice_mem(_,_,_,0) -> ?ok;
quit_notice_mem(UserId,UserName,MapPid,MemId) ->
	case ets_spring_info(MemId) of
		?null -> ?ok;
		SpringM ->
			SpringM2= SpringM#spring_info{state = ?CONST_PLAYER_STATE_NORMAL,mem_id = 0},
			Packet2	= spring_api:msg_scinformcancel(UserId, ?true),
			misc_packet:send(MemId, Packet2),
			insert_spring_info(SpringM2),
            case is_doll(MemId) of
                ?false ->
                    player_api:process_send(MemId, ?MODULE, cancel_cb, [UserName]);
                ?true ->
                    robot_api:double_cancel(MapPid, MemId, UserId),
                    ok
            end,
			Packet	= spring_api:msg_sc_cancel_notice(UserId,MemId),
			map_api:broadcast(MapPid, Packet)
	end.

%% 活动结束退出
acitve_end_quit(Player = #player{user_id = UserId, net_pid = Pid}) ->
  MapId = map_api:get_cur_map_id(Player),
  if
    MapId =:= ?CONST_SPRING_MAP_ID -> 
    	Player2			= map_api:return_last_city(Player),
    	Packet28306		= spring_api:msg_scexit(UserId),
    	{?ok,Player3}	= set_quit_state(Player2),
    	{?ok,Player4}	= task_api:update_active(Player3, {?CONST_ACTIVE_SPRING, 0}),
    	misc_packet:send(Pid, Packet28306),
    	{?ok, Player4};
    ?true ->
        {?ok, Player}
    end;
acitve_end_quit(Player) ->
	{?ok,Player}.
 	

%% 结束奖励
quit_reward(#spring_info{user_id = UserId, time = Time, enter_time = ETime,exp = Exp,sp = Sp,state = State}) ->
	case is_doll(UserId) of
		?true ->
			?ignore;
		?false ->
			case State of
				0 ->
					TimeSum 		= Time;
				_ ->	
					Now				= misc:seconds(),		
					Time2			= get_enter_time(Now,ETime),
					TimeSum			= Time + Time2
			end,
			Packet			= spring_api:msg_scoff(Exp,Sp,TimeSum),
			Packet2			= spring_api:msg_sc_end_quit(?CONST_SYS_TRUE),
			misc_packet:send(UserId, <<Packet/binary,Packet2/binary>>),
			ets_api:delete(?CONST_ETS_SPRING_INFO,UserId)
	end.

%% 取得温泉时长
get_enter_time(Now,Time) ->
	if
		Now > Time ->
			Now - Time;
		?true ->
			0
	end.
			
%% 设置退出玩法状态
set_quit_state(Player) ->	
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, Player2} ->	
			{?ok,Player2};
		{?false, Player2, _} ->	
			{?ok,Player2}
	end.

%% 获取经验
exp(Spring)	->
	player_api:process_send(Spring#spring_info.user_id, ?MODULE, exp_cb, [Spring]).

exp_cb(Player, [Spring])	->
	case player_state_api:is_doing(Player, ?CONST_PLAYER_PLAY_SPRING) of
		?true ->
			Info				= Player#player.info,
			Lv					= Info#info.lv,
			VipLv				= player_api:get_vip_lv(Info),
 			Exp					= trunc(get_exp(Spring#spring_info.state, Lv, VipLv)*2),
 			EtsExp				= Spring#spring_info.exp,
			NewEtsExp			= EtsExp + Exp,
			Spring2				= Spring#spring_info{exp = NewEtsExp},
			
			Packet 				= spring_api:msg_scexp(NewEtsExp),
			insert_spring_info(Spring2),
			misc_packet:send(Player#player.net_pid, Packet),
			player_api:exp(Player, Exp);
		_ ->
			{?ok, Player}
	end.

%% 取得增加经验
get_exp(0, _Lv, _VipLv)	-> 0;
get_exp(State, Lv, VipLv)	->
	Ratio	= player_vip_api:get_spring_add(VipLv),
	Exp		= case data_spring:get_spring_init(Lv) of
				  RecSpring when is_record(RecSpring, rec_spring) andalso State =:= ?CONST_PLAYER_STATE_NORMAL	->
							  RecSpring#rec_spring.single_exp;
				  RecSpring when is_record(RecSpring, rec_spring) andalso State =:= ?CONST_PLAYER_STATE_SPRING_1->
							  RecSpring#rec_spring.double_exp;
				  _Other	->	0
			  end,
	round(Exp * (1 + Ratio / ?CONST_SYS_NUMBER_HUNDRED) * active_rate_api:get_rate(?CONST_ACTIVE_SPRING)).

%% 检查邀请的玩家id
check_request_id(UserId,UserId) -> 
	throw({?error,?TIP_SPRING_MEMBER_NOT_SELF});
check_request_id(_,_) -> ?ok.

%% 检查玩家状态
check_user_play_state(?CONST_PLAYER_PLAY_SPRING) -> ?ok;
check_user_play_state(_) ->
	throw({?error,?TIP_SPRING_PLAYER_OFF}).

%% check_user_state(?CONST_PLAYER_STATE_SPRING_1) -> 
%% 	throw({?error,?TIP_SPRING_PLAYER_IN_DOUBLE});
%% check_user_state(_) -> ?ok.

%% 检查对方状态
check_mem_play_state(?CONST_PLAYER_PLAY_SPRING) -> ?ok;
check_mem_play_state(_) ->
	throw({?error,?TIP_SPRING_MEMBER_OFF}).

is_doll(UserId) ->
	case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
		?null ->
			?false;
		SpringDoll ->
			case ets_api:lookup(?CONST_ETS_SPRING, ?CONST_ACTIVE_SPRING) of
				?null ->
					?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING;
				SpringActive ->
					Type =
						case SpringActive#spring_active.flag of
							1 ->
								?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING;
							_ ->
								?CONST_SCHEDULE_ACTIVITY_LATE_SPRING
						end,				
					lists:member(Type, SpringDoll#spring_doll.spring_ids)
			end
	end.

%% check_mem_state(?CONST_PLAYER_STATE_SPRING_1) ->
%% 	throw({?error,?TIP_SPRING_MEMBER_IN_DOUBLE});
%% check_mem_state(_) -> ?ok.

%% 取得PlayerFirst
get_mem_player(MemId) ->
	case player_api:check_online(MemId) of
		?true -> 
			case is_doll(MemId) of
				?true ->
					{?ok, ?CONST_PLAYER_STATE_NORMAL, ?CONST_PLAYER_PLAY_SPRING};
				?false ->
					case player_api:get_player_fields(MemId, [#player.user_state,#player.play_state]) of
						{?ok, [UserState,PlayState]} ->
							{?ok,UserState,PlayState};
						_ ->
							throw({?error,?TIP_COMMON_OFF_LINE})
					end
			end;
		?false ->
            case is_doll(MemId) of
                ?true -> % 机器人
                    {?ok, ?CONST_PLAYER_STATE_NORMAL, ?CONST_PLAYER_PLAY_SPRING};
                ?false ->
        			throw({?error,?TIP_COMMON_OFF_LINE})
            end
	end.	

%% 检查温泉中的状态
check_user_spring_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_user_spring_state(_) -> 
	throw({?error,?TIP_SPRING_PLAYER_IN_DOUBLE}).

%% 检查对方温泉中的状态
check_mem_spring_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_mem_spring_state(_) -> 
	throw({?error,?TIP_SPRING_MEMBER_IN_DOUBLE}).
	
%% 双修请求
double_request(Player, MateId, Type) when is_record(Player,player) ->
	try
		UserId				= Player#player.user_id,
		Info				= Player#player.info,
		?ok					= check_active_open(),				%% 活动是否开放
		?ok					= check_request_id(UserId,MateId),	%% 检查玩家id

		{?ok,Spring}		= get_spring_data(UserId),
		{?ok,SpringM}		= get_spring_data(MateId),
		?ok					= check_user_play_state(Player#player.play_state),
%% 		?ok					= check_playing_state(Player#player.playing_state),

		{?ok,_TUserState,TPlayState}		= get_mem_player(MateId),

		?ok					= check_mem_play_state(TPlayState),
%%  		?ok					= check_mem_playing_state(TUserState),
		?ok					= check_user_spring_state(Spring#spring_info.state),
		?ok					= check_mem_spring_state(SpringM#spring_info.state),

        case is_doll(MateId) of
            ?false ->
        		Packet28322			= spring_api:msg_scdoublereceive(UserId,Info#info.user_name,Type),
        		Packet28320			= spring_api:msg_sc_request(Type),
        		misc_packet:send(MateId, Packet28322),
        		misc_packet:send(Player#player.net_pid, Packet28320),
                {?ok,Player};
            ?true ->
                spring_handler:handler(?MSG_ID_SPRING_CSDOUBLEREPLY, Player, {MateId, Type, ?true})
        end
	catch
		throw:{?error,ErrorCode} ->
			error_msg(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.	
		
%%  双修回复
double_reply(Player = #player{info = Info}, MateId, _Type, ?false) ->
	PacketTip	= message_api:msg_notice(?TIP_SPRING_REJECT,[{?TIP_SYS_COMM,Info#info.user_name}]),
	misc_packet:send(MateId, PacketTip),
	{?ok,Player};
double_reply(Player, MateId, Type, _Reply) when is_record(Player,player) ->
	try
		UserId				= Player#player.user_id,
		?ok					= check_active_open(),
		?ok					= check_request_id(UserId,MateId),
		{?ok,Spring}		= get_spring_data(UserId),
		{?ok,SpringM}		= get_spring_data(MateId),
		
		?ok					= check_user_play_state(Player#player.play_state),
%% 		?ok					= check_user_state(Player#player.user_state),
		
		{?ok,_TUserState,TPlayState}		= get_mem_player(MateId),
		?ok					= check_mem_play_state(TPlayState),
%% 		?ok					= check_mem_state(TUserState),
		?ok					= check_user_spring_state(Spring#spring_info.state),
		?ok					= check_mem_spring_state(SpringM#spring_info.state),
		
		Spring2				= Spring#spring_info{state = ?CONST_PLAYER_STATE_SPRING_1,mem_id = MateId},
		SpringM2			= SpringM#spring_info{state = ?CONST_PLAYER_STATE_SPRING_1,mem_id = UserId},
		Packet1				= spring_api:msg_scdouble(UserId,Type,?true),
		Packet2				= spring_api:msg_scdouble(MateId,Type,?false),
		insert_spring_info(Spring2),
		insert_spring_info(SpringM2),
		misc_packet:send(MateId, Packet1),
		misc_packet:send(Player#player.net_pid, Packet2),
		case is_doll(MateId) of
			?true ->
				?ok;
			?false ->
				player_api:process_send(MateId, ?MODULE, reply_cd, [])
		end,
		set_double_state(Player)
	catch
		throw:{?error,ErrorCode} -> 
			error_msg(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.	

%% 设置双修状态
set_double_state(Player) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_SPRING_1) of
		{?true, Player2} ->
			{?ok,Player2};
		_ ->
			{?ok,Player}
	end.

reply_cd(Player,[]) ->
	set_double_state(Player).
	

%% 取消双修
double_cancel(Player = #player{user_id = UserId,info = Info}) ->
	case ets_spring_info(UserId) of
		?null -> ?ok;
		Spring ->
			MemId			= Spring#spring_info.mem_id,		
			Spring2 		= Spring#spring_info{state = ?CONST_PLAYER_STATE_NORMAL,mem_id = 0},
			insert_spring_info(Spring2),
			case ets_spring_info(MemId) of
				?null -> ?ok;
				SpringM ->
					SpringM2 		= SpringM#spring_info{state = ?CONST_PLAYER_STATE_NORMAL,mem_id = 0},
					Packet2			= spring_api:msg_scinformcancel(UserId, ?true),
					misc_packet:send(MemId, Packet2),
					insert_spring_info(SpringM2),
                    case is_doll(MemId) of
                        ?false ->
					        player_api:process_send(MemId, ?MODULE, cancel_cb, [Info#info.user_name]);
                        ?true ->
                            robot_api:double_cancel(Player#player.map_pid, MemId, UserId),
                            ?ok
                    end,
					Packet			= spring_api:msg_sc_cancel_notice(UserId,MemId),
					map_api:broadcast(Player#player.map_pid, Packet)
			end
	end,
	set_cancel_state(Player).

%% 取消
cancel_cb(Player,[Name]) ->
	PacketTip 	= message_api:msg_notice(?TIP_SPRING_CANCEL,[{?TIP_SYS_COMM,Name}]),
	misc_packet:send(Player#player.user_id, PacketTip),
	set_cancel_state(Player).

%% 设置取消状态
set_cancel_state(Player) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL) of
		{?true, Player2} ->
			{?ok,Player2};
		_ ->
			{?ok,Player}
	end.
	
%% 双修广播
double_notice(#player{user_id = UserId}, UserId, _Type) -> ?ok;
double_notice(Player = #player{user_id = UserId,map_pid = MPid}, MateId, Type)	->
	{?ok,Spring} 	= get_spring_data(UserId),
	{?ok,SpringM} 	= get_spring_data(MateId),
	if
		Spring#spring_info.mem_id =:= MateId andalso SpringM#spring_info.mem_id =:= UserId ->
			Packet	= spring_api:msg_sc_notice(UserId,MateId,Type),	
			set_map_state(Player,?CONST_PLAYER_STATE_SPRING_1,MateId),
			map_api:broadcast(MPid, Packet);
		?true	-> ?ok
	end.

%% 获取体力
request_get_sp(Player = #player{user_id = UserId,net_pid = Pid}) ->
	case check_get_sp(UserId) of
		{?ok,Spring = #spring_info{sp_time = SpTime, enter_time = EnterTime,time = TimeSum, sp = Sp}}
		  when Sp < ?CONST_SPRING_SP_LIMIT ->
			Now				= misc:seconds(),	
			AddTime			= get_enter_time(Now,EnterTime),
			SpTime2			= SpTime + AddTime,
			if
				SpTime2 >= ?CONST_SPRING_SP_INTERVAL ->
					TimeSum2		= TimeSum + AddTime,  
                    Sp2             = Sp + round(active_rate_api:get_rate(?CONST_ACTIVE_SPRING) * ?CONST_SPRING_SP),
					Spring2 		= Spring#spring_info{sp_time = 0,enter_time = Now,
														 time = TimeSum2,sp = Sp2},
					Pakcet28316		= spring_api:msg_sc_sp_time(0),
					PacketSp		= spring_api:msg_scps(Sp2),
					
					insert_spring_info(Spring2),
					misc_packet:send(Pid, <<Pakcet28316/binary,PacketSp/binary>>),
					player_api:plus_sp(Player, ?CONST_SPRING_SP, ?CONST_COST_SPRING_REWARD_SP);
				?true ->							
					Pakcet28316		= spring_api:msg_sc_sp_time(SpTime2),
					misc_packet:send(Pid, Pakcet28316),
					{?ok,Player}
			end;
		_ ->
			Pakcet28316		= spring_api:msg_sc_sp_time(0),
			misc_packet:send(Pid, Pakcet28316),
			{?ok,Player}
	end.
		
%% 检查获得体力
check_get_sp(UserId) ->
	try
		?ok					= check_active_open(),
		{?ok,Spring}		= get_spring_data(UserId),
		{?ok,Spring}
	catch
		throw:{?error,ErrorCode} -> 
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.	

%% 设置场景状态
set_map_state(Player,State,MateId) -> 
	map_api:change_double(Player,State, MateId).

%% 错误消息
error_msg(Player,ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.

%% 设置自动双修
set_auto(UserId,Flag) ->
	{?ok,Spring} 	= get_spring_data(UserId),
	if
		Spring#spring_info.auto =:= Flag -> ?ok;
		?true ->
			Spring2	= Spring#spring_info{auto = Flag},
			insert_spring_info(Spring2)
	end. 
		
%% 初始化 #spring_info{}
init_spring(UserId) ->
	#spring_info{
				user_id			= UserId		% 玩家ID
				}.
%%
%% Local Functions
%%

