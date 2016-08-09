%% Author: Administrator
%% Created: 2012-7-27
%% Description: TODO: Add description to pratice_api
-module(practice_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([
		 login/1, logout/1, login_packet/2,
		 refresh/1,
		 flush_exp/0,cancel/1,initial_ets/0,
		 check_doll_info/1,
		 save_all_doll/0,
		 init_ets/0,
		 load_doll/0,
		 clear_robot/0,
		 add_tomorrow_time/0,
		 get_sum_time/1,
		 add_guide/1,
		 
		 msg_single/2,
		 msg_double_receive/2,
		 msg_double/3,
		 msg_reward/2,
		 msg_options_data/1,
		 msg_cancel_data/1,
		 msg_sc_leave_exp/4,
		 msg_sc_offline_set_res/1,
		 msg_sc_offline_set_rep/1,
		 msg_sc_valid_time/2,
		 msg_sc_offline_clean/0,
		 msg_sc_time/1,
		 msg_sc_finish_time/1
		 ]).


%%
%% API Functions
%%
%% 零点刷新修炼活跃度
add_guide(Player) ->
	practice_mod:add_guide(Player).
		
%% 获取已修炼时长
get_sum_time(UserId) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_USER, UserId) of
		?null ->
			0;
		Tuple ->
			Tuple#practice_user.sum_time
	end.

%% 零点增加第二天时间
add_tomorrow_time() ->
	practice_mod:add_tomorrow_time().

%% 定时清理机器人
clear_robot() ->
	practice_mod:clear_robot().

%% 开服初始化温泉替身数据
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_PRACTICE_DOLL),
	FieldList = [user_id, record],
	_IdList =
		case mysql_api:select(FieldList, game_practice_doll) of
			{?ok, DollList} ->
				F = fun([UserId, BinRecord]) ->
							Rec	= mysql_api:decode(BinRecord),
							ets_api:insert(?CONST_ETS_PRACTICE_DOLL, Rec),
							UserId
					end,
				[F(E) || E <- DollList];
			{?error, _ErrorCode} ->
				[]
		end,
	?ok.

%% 加载机器人数值
load_doll() ->
	List = ets_api:list(?CONST_ETS_PRACTICE_DOLL),
	load_doll(List).

load_doll([]) ->
	?ok;
load_doll([#practice_doll{user_id = UserId}|T]) ->
	try
		{ok, [Maps]} = player_api:get_player_fields(UserId, [#player.maps]),
		robot_api:doll_enter_practice(#player{user_id = UserId, maps = Maps}),
		load_doll(T)
	catch
		E:R ->
			?MSG_ERROR("Error:~w, Reason:~w, Stack:~w", [E, R, erlang:get_stacktrace()])
	end.

%% 关服替身持久化操作
save_all_doll() ->
	try
		Sql = <<"delete from `game_practice_doll`">>,
		mysql_api:select(Sql),
		DollList = ets_api:list(?CONST_ETS_PRACTICE_DOLL),
		[practice_mod:save_doll_data(PracticeDoll) || PracticeDoll <- DollList]
	catch
		E:R ->
			?MSG_ERROR("Error:~w, Reason:~w, Stack:~w", [E, R, erlang:get_stacktrace()])
	end.

%% 检查玩家离线替身信息
check_doll_info(#player{user_id = UserId} = Player) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_DOLL, UserId) of
		?null ->
			?ok;
		PracticeDoll ->
			case PracticeDoll#practice_doll.is_set of				
				1 ->
					robot_api:doll_enter_practice(Player),
					practice_mod:update_practice_doll(Player, logout),
					?null;
				_ ->
					?ok
			end
	end.

%% practice_api:flush_exp(). 
%% 定时刷新经验
flush_exp() ->
	List 	= get_ets_list(),
	flush_exp(List).

flush_exp([]) -> ?ok;
flush_exp([Data|DataList]) ->
	case player_api:check_online(Data#practice.user_id) of
		?true ->
			practice_mod:send_exp(Data);
		_ -> ?ok
	end,
	flush_exp(DataList).

%% 取得修炼列表
get_ets_list() ->
	Time 	= misc:seconds(),
	MS 		= ets:fun2ms(fun(P = #practice{exp_time = ExpTime,state = State} ) 
				when (ExpTime =< Time - ?CONST_PRACTICE_ONLINE_TIME andalso State =:= ?CONST_PLAYER_STATE_SINGLE_PRACTISE) 
					orelse (ExpTime =< Time - ?CONST_PRACTICE_ONLINE_TIME/2 andalso State =:= ?CONST_PLAYER_STATE_DOUBLE_PRACTISE) ->
				  		P
		  			 	end),
	ets_api:select(?CONST_ETS_PRACTICE,MS).

%% 初始化ets
initial_ets() ->
	practice_db_mod:select_data().	
	
%% practice_api:cancel(Player). 
%% 取消修炼
cancel(Player = #player{sys_rank = Sys}) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_PRACTICE) of
        true ->
	       practice_mod:cancel(Player);
        false ->
            ?ok
    end.

%% 登陆计算离线经验
login(Player) ->
	case ets_api:lookup(?CONST_ETS_PRACTICE_USER, Player#player.user_id) of
		?null ->
			?ok;
		PracticeUser ->%% 默认自动同意双休
			practice_mod:insert_practice_user(PracticeUser#practice_user{auto = 1})
	end,
	Player.

%% 记录离线时间 practice_api:logout(Player).
logout(Player) when is_record(Player,player) ->
	practice_mod:logout(Player),
	Player;
logout(Player) ->
	Player.

login_packet(Player, OldPacket) ->
	Player2 = practice_mod:update_practice_doll(Player, login),
	practice_mod:set_doll_award(Player2),
	PracticeUser 	= practice_mod:ets_practice_user(Player2#player.user_id),
	Packet16104		= msg_options_data(PracticeUser#practice_user.auto),
 	Packet16300		= msg_sc_finish_time(PracticeUser#practice_user.sum_time),
	{Player2, <<OldPacket/binary,Packet16104/binary,Packet16300/binary>>}. 

refresh(Player) ->
	Packet16300		= msg_sc_finish_time(0),
	misc_packet:send(Player#player.net_pid, Packet16300),
	{?ok,Player}.

%% 单修成功
msg_single(Res,Time) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SINGLE, ?MSG_FORMAT_PRACTICE_SINGLE, [Res,Time]).
%% 双修邀请
msg_double_receive(UserId,Name) ->
	misc_packet:pack(?MSG_ID_PRACTICE_DOUBLE_RECEIVE, ?MSG_FORMAT_PRACTICE_DOUBLE_RECEIVE, [UserId,Name]).
%% 双修成功
msg_double(UserId,Flag,Time) ->
	misc_packet:pack(?MSG_ID_PRACTICE_DOUBLE, ?MSG_FORMAT_PRACTICE_DOUBLE, [UserId,Flag,Time]).
%% 修炼奖励
msg_reward(Type,Exp) ->
	misc_packet:pack(?MSG_ID_PRACTICE_REWARD, ?MSG_FORMAT_PRACTICE_REWARD, [Type,Exp]).
%% 双修设定
msg_options_data(Automatic) ->
	misc_packet:pack(?MSG_ID_PRACTICE_OPTIONS_DATA, ?MSG_FORMAT_PRACTICE_OPTIONS_DATA, [Automatic]).
%% 取消打坐
msg_cancel_data(Type) ->
	misc_packet:pack(?MSG_ID_PRACTICE_CANCEL_DATA, ?MSG_FORMAT_PRACTICE_CANCEL_DATA, [Type]).
%% 请求离线经验
%%[Exp]
%% 请求离线经验
%%[Time,Exp,VipTime,VipExp]
msg_sc_leave_exp(Time,Exp,VipTime,VipExp) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_LEAVE_EXP, ?MSG_FORMAT_PRACTICE_SC_LEAVE_EXP, [Time,Exp,VipTime,VipExp]).
%% 离线修炼设置结果
%%[Result]
msg_sc_offline_set_res(Result) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_OFFLINE_SET_RES, ?MSG_FORMAT_PRACTICE_SC_OFFLINE_SET_RES, [Result]).
%% 查询离线修炼设置结果
%%[Result]
msg_sc_offline_set_rep(Result) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_OFFLINE_SET_REP, ?MSG_FORMAT_PRACTICE_SC_OFFLINE_SET_REP, [Result]).
%% 回复可修炼时间
%%[Type,ValidTime]
msg_sc_valid_time(Type,ValidTime) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_VALID_TIME, ?MSG_FORMAT_PRACTICE_SC_VALID_TIME, [Type,ValidTime]).
%% 清除离线设置
%%[]
msg_sc_offline_clean() ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_OFFLINE_CLEAN, ?MSG_FORMAT_PRACTICE_SC_OFFLINE_CLEAN, []).
%% 剩余修炼时间
%%[Time]
msg_sc_time(Time) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_TIME, ?MSG_FORMAT_PRACTICE_SC_TIME, [Time]).
%% 修炼时长
%%[Time]
msg_sc_finish_time(Time) ->
	misc_packet:pack(?MSG_ID_PRACTICE_SC_FINISH_TIME, ?MSG_FORMAT_PRACTICE_SC_FINISH_TIME, [Time]).
%%
%% Local Functions
%%
