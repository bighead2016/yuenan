%% Author: Administrator
%% Created: 2012-8-22
%% Description: TODO: Add description to spring_api
-module(spring_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("record.map.hrl").

%%
%% Exported Functions
%%
-export([
		 init_player_spring/0,logout/1,
		 on/1, off/1,
		 flush_offline/2,
		 spring_interval/0,
		 double_cancel/1,
		 
		 ets_spring/0,
		 get_auto/1,
		 set_auto/3,
		 auto_reward_cb/2,
		 auto_start_cb/2,
		 save_all_doll/0,
		 init_ets/0,
		 
		 msg_scexp/1,msg_scps/1,
		 msg_scoff/3,
		 msg_sc_cancel_notice/2,
		 msg_scinformcancel/2,
		 msg_sc_notice/3,	
 		 msg_scdoublereceive/3,
		 msg_scdouble/3,
		 msg_scenter/1,
		 msg_scexit/1,
		 msg_sc_end_quit/1,
		 msg_sc_request/1,
		 msg_sc_sp_time/1,
		 msg_sc_auto/1
		]).

%%
%% API Functions
%%
%% 开服初始化温泉替身数据
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_SPRING_DOLL),
	FieldList = [user_id, record],
	case mysql_api:select(FieldList, game_spring_doll) of
		{?ok, DollList} ->
			F = fun([_UserId, BinRecord]) ->
						Rec	= mysql_api:decode(BinRecord),
						ets_api:insert(?CONST_ETS_SPRING_DOLL, Rec)
				end,
			[F(E) || E <- DollList];
		{?error, _ErrorCode} ->
			?ok
	end,
	?ok.

%% 关服替身持久化操作
save_all_doll() ->
	try
		Sql = <<"delete from `game_spring_doll`">>,
		mysql_api:select(Sql),
		DollList = ets_api:list(?CONST_ETS_SPRING_DOLL),
		[spring_mod:save_doll_data(SpringDoll) || SpringDoll <- DollList]
	catch
		E:R ->
			?MSG_ERROR("Error:~w, Reason:~w, Stack:~w", [E, R, erlang:get_stacktrace()])
	end.

get_auto(UserId) ->
	case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
		Tuple when is_record(Tuple, spring_doll) -> 
			Tuple#spring_doll.spring_ids;
		_ -> []
	end.

update_ets_spring_doll(UserId, SpringIds) ->
	case SpringIds of
        [] ->
            ets_api:delete(?CONST_ETS_SPRING_DOLL, UserId);
        _ ->
	        ets_api:update_element(?CONST_ETS_SPRING_DOLL, UserId, {#spring_doll.spring_ids, SpringIds})
    end.

%% 勾选替身参加
set_auto(Player, Type, ?true) ->
	UserId		= Player#player.user_id,
	?ok			= check_vip_flag(player_api:get_vip_lv(Player#player.info)),
	?ok			= check_active_open(),
	?CONST_SYS_TRUE = robot_api:is_open_robot(spring),
	case player_money_api:minus_money_sp(UserId, ?CONST_SYS_CASH, ?CONST_SPRING_AUTO_COST, ?CONST_COST_SPRING_AUTO_CASH) of
		{?error, ErrorCode} ->
			case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
				?null -> 
					?ignore;
				Tuple ->
					SpringIds = lists:delete(Type, Tuple#spring_doll.spring_ids),	%% 清理无效数据
					update_ets_spring_doll(UserId, SpringIds),
					TipPacket = message_api:msg_notice(?TIP_SPRING_AUTO_FAIL), 
					misc_packet:send(UserId, TipPacket)
			end,
			{?error, ErrorCode};
		{_CashBindValue, CashBind2Value, CashValue} ->
			SpingIds = 
				case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
					?null -> [Type];
					Tuple when is_record(Tuple, spring_doll) ->
						case lists:member(Type, Tuple#spring_doll.spring_ids) of
							?true -> Tuple#spring_doll.spring_ids;
							?false -> [Type|Tuple#spring_doll.spring_ids]
						end
				end,
			SpringDoll  = #spring_doll{
									   user_id 	= Player#player.user_id,
									   time		= misc:seconds(),
									   spring_ids = SpingIds,
									   bcash	= CashBind2Value,
									   cash		= CashValue
									  },
			ets_api:insert(?CONST_ETS_SPRING_DOLL, SpringDoll),
			TipPacket = message_api:msg_notice(?TIP_SPRING_AUTO_SET_SUCCESS), 
			misc_packet:send(UserId, TipPacket),
			?ok
	end;
%% 取消替身参加
set_auto(Player, Type, ?false) ->
	UserId		= Player#player.user_id,
	?ok			= check_active_open(),
	case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
		?null -> ?ok;
		#spring_doll{bcash = Bcash, cash = Cash, spring_ids = Ids} ->
			case lists:member(Type, Ids) of
				?false -> ?ok;
				?true ->
					SpringIds	= lists:delete(Type, Ids),
					update_ets_spring_doll(UserId, SpringIds),
					case player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_SPRING_AUTO_CASH) of
						{?error, _ErrorCode} ->
							TipPacket = message_api:msg_notice(?TIP_SPRING_AUTO_FAIL), 
							misc_packet:send(UserId, TipPacket);
						?ok ->
							case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, Bcash, ?CONST_COST_SPRING_AUTO_CASH) of
								{?error, _ErrorCode} ->
									TipPacket = message_api:msg_notice(?TIP_SPRING_AUTO_FAIL), 
									misc_packet:send(UserId, TipPacket);
								?ok ->
									TipPacket = message_api:msg_notice(?TIP_SPRING_AUTO_SUCCESS, [], [], 
																	   [{?TIP_SYS_COMM,misc:to_list(?CONST_SPRING_AUTO_COST)}]),
									misc_packet:send(UserId, TipPacket)
							end
					end,
					?ok
			end
	end.

%% 自动参加温泉
auto_start(Flag) ->
	List = ets_api:list(?CONST_ETS_SPRING_DOLL),
	Type = 
		case Flag of
			1 ->
				?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING;
			_ ->
				?CONST_SCHEDULE_ACTIVITY_LATE_SPRING
		end,
	F = fun(#spring_doll{user_id = UserId}) ->
				case ets_api:lookup(?CONST_ETS_SPRING_DOLL, UserId) of
					Tuple when is_record(Tuple, spring_doll) ->
						case lists:member(Type, Tuple#spring_doll.spring_ids) of
							?true -> 
								player_api:process_send(UserId, ?MODULE, auto_start_cb, []),
								?ok;
							?false ->
								?ok
						end;
					_ ->
						?ok
				end
		end,
	lists:foreach(F, List).

auto_start_cb(Player,[]) ->
	{?ok, NewPlayer2}	= spring_mod:add_guide_times(Player),		%% 目标
	achievement_api:add_achievement(NewPlayer2, ?CONST_ACHIEVEMENT_SPRING, 0, 1).

auto_end(Flag) ->
	List 		= ets_api:list(?CONST_ETS_SPRING_DOLL),
	Time		= misc:seconds(),
	auto_reward(List,Time,Flag),
	F = fun(#spring_doll{user_id = UserId, map_pid = MapPid}) ->
				map_api:exit_map(#player{user_id = UserId, map_pid = MapPid}, ?CONST_MAP_PTYPE_ROBOT),
				ets_api:delete(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_ROBOT, UserId})
		end,
	[F(Rec) || Rec <- List].

%% 自动参加奖励
auto_reward([],_, _Flag) -> ?ok;
auto_reward([#spring_doll{user_id = UserId, spring_ids = SpringIds}|List],Time, Flag) ->
	clear_spring_doll(UserId, Flag),		%% 清除活动id
	case player_api:check_online(UserId) of
		?true ->
			player_api:process_send(UserId, ?MODULE, auto_reward_cb, [Flag, SpringIds]);
		_ ->
			player_offline_api:offline(?MODULE,UserId, {Time, Flag})
	end,
	auto_reward(List,Time, Flag).

%% 玩家上线时操作，需要立即操作的逻辑不能放这里
flush_offline(Player, {Time, Flag}) ->
	Now 			= misc:seconds(),
	{?ok, Player2}	= auto_send_reward(Player, Flag),
	{?ok, Player3}	= case misc:is_same_date(Now, Time) of
						  ?true ->
							  spring_mod:add_guide_times(Player2);		%% 目标
						  _ -> {?ok, Player2}
					  end,
	achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_SPRING, 0, 1).

%% 自动参加发送奖励
auto_reward_cb(Player,[Flag, SpringIds]) ->
	Type		=
		case Flag of
			1 ->
				?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING;
			_ ->
				?CONST_SCHEDULE_ACTIVITY_LATE_SPRING
		end,
	case lists:member(Type, SpringIds) of
		?true ->
			auto_send_reward(Player, Flag);
		?false ->
			{?ok,Player}
	end.

%% 自动参加发送奖励
auto_send_reward(Player = #player{info = Info}, _Flag) ->
	try
		{?ok,Exp,Sp} 	= get_spring_auto_reward(Info#info.lv),
		VipLv			= player_api:get_vip_lv(Info),
		Add 			= player_vip_api:get_spring_add(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
		Exp2			= misc:floor(Exp * (1+Add)*2),
		{?ok,Player2} 	= player_api:exp(Player, Exp2),
		{?ok,Player3} 	= player_api:plus_sp(Player2, Sp, ?CONST_COST_SPRING_AUTO_SP),
		mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_SPRING_DOLL_SEND,
										  [{[{misc:to_list(Exp2)}]}, {[{misc:to_list(Sp)}]}], [], 0, 0, 0, ?CONST_COST_SPRING_AUTO_SP),
		{?ok,Player4}	= task_api:update_active(Player3, {?CONST_ACTIVE_SPRING, 0}),
		%Packet			= msg_scoff(Exp2, Sp, 3600),
		%misc_packet:send(Pid, Packet),
		{?ok,Player5}	= schedule_api:add_guide_times(Player4, ?CONST_SCHEDULE_GUIDE_SPRING),
		achievement_api:add_achievement(Player5, ?CONST_ACHIEVEMENT_SPRING, 0, 1)
	catch
		_:_ ->
			{?ok,Player}
	end.

clear_spring_doll(UserId, Flag) ->
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
			SpringIds	= lists:delete(Type, Tuple#spring_doll.spring_ids),
			update_ets_spring_doll(UserId, SpringIds)
	end.

get_spring_auto_reward(Lv) ->
	case data_spring:get_spring_init(Lv) of
		?null -> {?ok,0,0};
		#rec_spring{auto_exp = Exp, auto_sp = Sp} -> 
			{?ok,Exp,Sp}
	end.
%% 检查vip等级
check_vip_flag(VipLv) ->
	case player_vip_api:get_spring_auto_flag(VipLv) of
		?CONST_SYS_TRUE -> ?ok;
		_ ->
			throw({?error,?TIP_SPRING_AUTO_VIP}) %% VIP等级不足
	end.

%% 检查活动是否开放
check_active_open() ->
	case spring_api:ets_spring() of
		?null -> ?ok;		
		_ -> throw({?error,?TIP_SPRING_AUTO_OPEN}) %% 活动已经开启
	end.


%% 初始化#spring{}
init_player_spring() ->
	#spring{}.
  
%% 退出游戏
logout(Player) ->
	spring_mod:quit(Player).


%% 温泉活动开始：通知前端
on([Flag])	->
 	ets:delete_all_objects(?CONST_ETS_SPRING_INFO),
	ets:delete_all_objects(?CONST_ETS_SPRING),
	
	crond_api:interval_del(spring_interval),
	crond_api:interval_add(spring_interval, 1, spring_api, spring_interval, []),

	StartTime	= misc:seconds(),
	EndTime     = StartTime + 3600,			%% 设置结束时间
	SpringA 	= #spring_active{id 		= ?CONST_ACTIVE_SPRING,
								 state		= ?CONST_ACTIVE_STATE_ON,
								 exp_time	= StartTime,
								 sp_time	= StartTime,
							 	 flag		= Flag,
							 	 start_time	= StartTime,
							 	 end_time	= EndTime
								},
	insert_spring(SpringA),
	auto_start(Flag),
    robot_api:doll_enter_spring(),
	?ok;
on(_)	->
	?ok.

ets_spring() ->
	ets_api:lookup(?CONST_ETS_SPRING, ?CONST_ACTIVE_SPRING).

insert_spring(Spring) ->
	ets_api:insert(?CONST_ETS_SPRING,Spring).

%% 定时器
spring_interval() ->
	case ets_spring() of
		?null ->
			crond_api:interval_del(spring_interval);
		SpringA ->
			spring_interval(SpringA)
	end.

spring_interval(SpringA = #spring_active{state = ?CONST_ACTIVE_STATE_ON,end_time = EndTime,
									     exp_time = ExpTime,sp_time = _SpTime}) ->
	 
	Time 		= misc:seconds(), 
	if 
		Time >= EndTime -> %% 活动结束
			SpringA2 = SpringA#spring_active{state = ?CONST_ACTIVE_STATE_OFF},
			insert_spring(SpringA2),	
			crond_api:interval_del(spring_interval),
			clear();
		Time >= ExpTime -> %% 定时获得经验
			SpringA2 = SpringA#spring_active{exp_time = Time + ?CONST_SPRING_EXP_INTERVAL},
			insert_spring(SpringA2),
			add_exp();
		?true -> 
			?ok
	end;
spring_interval(_) ->
	crond_api:interval_del(spring_interval).

%% 温泉活动结束：通知前端
off([Flag])	->
	crond_api:interval_del(spring_interval),
	clear(),
	auto_end(Flag),
	?ok.

%% 温泉活动结束：清理
clear() ->
	List 	= ets_api:list(?CONST_ETS_SPRING_INFO),
	F	 	= fun(Spring) ->
					  spring_mod:quit_reward(Spring)
			  end,
	lists:foreach(F,List), 
	ets:delete_all_objects(?CONST_ETS_SPRING_INFO),
	ets:delete_all_objects(?CONST_ETS_SPRING),
	?ok.

%% 定时增加经验
add_exp() -> 
	MS 		= ets:fun2ms(fun(T) when T#spring_info.state =/= 0  ->
				  			T
		  			 	 end),
	List 	= ets_api:select(?CONST_ETS_SPRING_INFO,MS),
	F		= fun(Spring) ->
					  spring_mod:exp(Spring)
			  end,  
	lists:foreach(F, List).

%% 取消双修
double_cancel(Player) ->
	spring_mod:double_cancel(Player).

%% 进入温泉
%%[TimeStamp]
msg_scenter(TimeStamp) ->
	misc_packet:pack(?MSG_ID_SPRING_SCENTER, ?MSG_FORMAT_SPRING_SCENTER, [TimeStamp]).
%% 离开温泉
%%[UserId]
msg_scexit(UserId) ->
	misc_packet:pack(?MSG_ID_SPRING_SCEXIT, ?MSG_FORMAT_SPRING_SCEXIT, [UserId]).
%% 经验
%%[Exp]
msg_scexp(Exp) ->
	misc_packet:pack(?MSG_ID_SPRING_SCEXP, ?MSG_FORMAT_SPRING_SCEXP, [Exp]).
%% 体力
%%[PS]
msg_scps(PS) ->
	misc_packet:pack(?MSG_ID_SPRING_SCPS, ?MSG_FORMAT_SPRING_SCPS, [PS]).
%% 温泉活动结束
%%[Exp,PS,Duration]
msg_scoff(Exp,PS,Duration) -> 
	misc_packet:pack(?MSG_ID_SPRING_SCOFF, ?MSG_FORMAT_SPRING_SCOFF, [Exp,PS,Duration]).
%% 双修邀请
%%[MateId,MateName,Type]
msg_scdoublereceive(MateId,MateName,Type) ->
	misc_packet:pack(?MSG_ID_SPRING_SCDOUBLERECEIVE, ?MSG_FORMAT_SPRING_SCDOUBLERECEIVE, [MateId,MateName,Type]).
%% 双修成功
%%[MateId,Type,Flag]
msg_scdouble(MateId,Type,Flag) ->
	misc_packet:pack(?MSG_ID_SPRING_SCDOUBLE, ?MSG_FORMAT_SPRING_SCDOUBLE, [MateId,Type,Flag]).
%% 通知对方取消双修
%%[MateId,Flag]
msg_scinformcancel(MateId,Flag) ->
	misc_packet:pack(?MSG_ID_SPRING_SCINFORMCANCEL, ?MSG_FORMAT_SPRING_SCINFORMCANCEL, [MateId,Flag]).
%% 双修整屏通知
%%[UserId,MateId,Type]
msg_sc_notice(UserId,MateId,Type) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_NOTICE, ?MSG_FORMAT_SPRING_SC_NOTICE, [UserId,MateId,Type]).
%% 取消双修广播
%%[UserId,MateId]
msg_sc_cancel_notice(UserId,MateId) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_CANCEL_NOTICE, ?MSG_FORMAT_SPRING_SC_CANCEL_NOTICE, [UserId,MateId]).
%% 温泉结束退出
%%[Res]
msg_sc_end_quit(Res) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_END_QUIT, ?MSG_FORMAT_SPRING_SC_END_QUIT, [Res]).
%% 成功邀请
%%[Type]
msg_sc_request(Type) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_REQUEST, ?MSG_FORMAT_SPRING_SC_REQUEST, [Type]).

%% 体力累计时间
%%[Time]
msg_sc_sp_time(Time) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_SP_TIME, ?MSG_FORMAT_SPRING_SC_SP_TIME, [Time]).

%% 设置自动双修
%%[Flag]
msg_sc_auto(Flag) ->
	misc_packet:pack(?MSG_ID_SPRING_SC_AUTO, ?MSG_FORMAT_SPRING_SC_AUTO, [Flag]).

%% 自动参加奖励
%%[Exp,Sp]
%%msg_sc_auto_reward(Exp,Sp) ->
%%	misc_packet:pack(?MSG_ID_SPRING_SC_AUTO_REWARD, ?MSG_FORMAT_SPRING_SC_AUTO_REWARD, [Exp,Sp]).
%% Local Functions
%%

