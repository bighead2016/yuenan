%% Author: Administrator
%% Created: 2012-12-5
%% Description: TODO: Add description to welfare2_api
-module(welfare_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").

%%
%% Exported Functions
%%
-export([init_player_welfare/1, flush_offline/2,
		 login_packet/2, logout/1, login_init/1, 
		 refresh/1,
		 add_pullulation/2, add_pullulation/4, add_pullulation_cb/2,
		 add_pullulation_power/2, pullulation_power_info/1,
		 deposit/4, deposit_cb/2, vip/1, level_up/1,
		 novice/1, novice_cb/2,
		 media/1, media_cb/2,
		 pack_sc_gift_info/2,
		 pack_sc_draw/2,
		 pack_sc_pullulation/1,
		 pack_sc_receive/1,
		 pack_sc_pullulation_power/1,
		 pack_sc_sign_times/1, 
         msg_sc_deposit_info/3, 
         msg_sc_rmb/3,
         msg_sc_end_time/1,
         msg_sc_jj_state/2]).

%%
%% API Functions
%%
%% 玩家登陆初始化
%% 再战沙场礼包
login_init(Player) ->
	case player_api:is_level_35(Player) of
		?CONST_SYS_TRUE -> 
			Welfare	= Player#player.welfare,
			WelfareData = Welfare#welfare.data,
			GiftList	= data_welfare:get_type_list_param(?CONST_WELFARE_REFIGHT_BATTLEFIELD),
			NewWelfareData = init_refight_battlefield(WelfareData, GiftList),
			NewWelfare = Welfare#welfare{data = NewWelfareData},
			Player#player{welfare = NewWelfare};
		_ ->
			Player
	end.

%% 再战沙场礼包
init_refight_battlefield(WelfareData, [GiftId | GiftList]) ->
	NewWelfareData = 
		if GiftId =:= ?CONST_WELFARE_REFIGHT_BATTLEFIELD_FIRST_ID ->
			   #welfare_data{type = ?CONST_WELFARE_REFIGHT_BATTLEFIELD, id	= GiftId,  state = ?CONST_WELFARE_UNCLAIMED};
		   ?true ->
			   #welfare_data{type = ?CONST_WELFARE_REFIGHT_BATTLEFIELD, id	= GiftId,  state = ?CONST_WELFARE_UNFIT}
		end,
	NewWelfareData2 = 
		case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
			?false	->	[NewWelfareData | WelfareData];
			_Tuple 	->
				WelfareData
		end,
	init_refight_battlefield(NewWelfareData2, GiftList);
init_refight_battlefield(WelfareData, []) ->
	WelfareData.
	
init_player_welfare(UserId) ->
	welfare_mod:init_player_welfare(UserId).

flush_offline(Player, Data) when is_record(Data, welfare_offline) ->
	Vip		= Data#welfare_offline.vip,
	CurSum	= Data#welfare_offline.cur_sum,
	AccSum	= Data#welfare_offline.acc_sum,
	deposit_cb(Player, [Vip, CurSum, AccSum]);
flush_offline(Player, #pullulation_offLine{matchdata = MatchData, times = Times, type = Type})->
	add_pullulation(Player, Type, MatchData, Times);
flush_offline(Player, Data) ->
	?MSG_ERROR("welfare flush_offline data=:~p", [Data]),
	{?ok, Player}.
%% 登录
%% 签到礼包
%% 连续登陆礼包
%% 每日VIP福利礼包
login_packet(Player, Packet)	->
	Welfare		= Player#player.welfare,
	NewWelfare	= welfare_mod:refresh(Welfare),
	NewPlayer	= Player#player{welfare = NewWelfare},
	AddPacket	= welfare_mod:login_packet(NewWelfare),
    DepositPacket = welfare_deposit_api:login_packet(Player),
	{NewPlayer, <<Packet/binary, AddPacket/binary, DepositPacket/binary>>}.

logout(Player)	->
	Now			= misc:seconds(),
	Welfare		= Player#player.welfare,
	Login		= Welfare#welfare.login,
	OnLine		= Welfare#welfare.online,
	NewWelfare	= Welfare#welfare{online = OnLine + Now - Login},
	Player#player{welfare = NewWelfare}.

%% 0点刷新福利数据(连续登陆每日补签次数)
refresh(Player) ->
	try
		Welfare		= Player#player.welfare,
		NewWelfare	= welfare_mod:refresh_zero(Welfare),
        {Player2, PacketD} = welfare_fund_api:refresh_zero(Player),
		NewPlayer	= Player2#player{welfare = NewWelfare},
		Packet	= welfare_mod:login_packet(NewWelfare),
		misc_packet:send(Player#player.user_id, <<Packet/binary, PacketD/binary>>),
		{?ok, NewPlayer}
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

add_pullulation(Player, [])	->	{?ok, Player, <<>>};
add_pullulation(Player, PullulationList)	->
	welfare_mod:add_pullulation(Player, PullulationList, <<>>).

%% add_pullulation(UserId, Type, MatchData, Times) when is_integer(UserId)	->
%% 	case player_api:get_player_pid(UserId) of
%% 		Pid when is_pid(Pid)	->
%% 			player_api:process_send(Pid, ?MODULE, add_pullulation_cb, [Type, MatchData, Times]);
%% 		_Other	->
%% 			PullulationOffLine	= #pullulation_offLine{type			= Type,
%% 													   matchdata	= MatchData,
%% 													   times		= Times},
%% 			player_offline_api:offline(?MODULE, UserId, PullulationOffLine)
%% 	end;
%% add_pullulation(Player, Type, MatchData, Times) when is_record(Player, player)	->
%% 	welfare_mod:add_pullulation(Player, Type, MatchData, Times).

add_pullulation(UserId, Type, MatchData, Times) when is_integer(UserId)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, add_pullulation_cb, [Type, MatchData, Times]);
		_Other	->
			PullulationOffLine	= #pullulation_offLine{type			= Type,
													   matchdata	= MatchData,
													   times		= Times},
			player_offline_api:offline(?MODULE, UserId, PullulationOffLine)
	end;
%% 屏蔽该接口
add_pullulation(Player, _Type, _MatchData, _Times) when is_record(Player, player)	->
	{?ok, Player}.

add_pullulation_cb(Player, [Type, MatchData, Times])	->
	add_pullulation(Player, Type, MatchData, Times).

%% 威武之路对外接口
add_pullulation_power(Player, []) -> {?ok, Player};
add_pullulation_power(Player, [Id|IdList]) ->
	case data_welfare:get_pullulation_power_info(Id) of
		PowerInfo when is_record(PowerInfo, rec_pullulation_power) ->
			Welfare			= Player#player.welfare,
			PullPower		= Welfare#welfare.pullulation_power,
			NewPullPower	= 
				case lists:keyfind(Id, #pullulation_power.id, PullPower) of
					?false	->	
						Now				= misc:seconds(),
						Tuple			= #pullulation_power{id = Id, flag = ?true, time = Now, received = ?CONST_WELFARE_UNCLAIMED},
						AddPacket		= welfare_api:pack_sc_pullulation_power(Id),
						misc_packet:send(Player#player.user_id, AddPacket),
						[Tuple];
				    _Other -> 
						PullPower
			    end,
			NewWelfare		= Welfare#welfare{pullulation_power	= NewPullPower},
			NewPlayer		= Player#player{welfare	= NewWelfare},
			add_pullulation_power(NewPlayer, IdList);
		_ ->
			?MSG_ERROR("add_pullulation_power id=~p", [Id]),
			add_pullulation_power(Player, IdList)
	end.

%% 威武之路信息
pullulation_power_info(Welfare) ->
	PowerList		= Welfare#welfare.pullulation_power,
	PowerList2		= [X || X <- PowerList,X#pullulation_power.id < 20000], %% 暂时过滤
	Fun				= fun(Item1, Item2) ->
							  Item1#pullulation_power.id > Item2#pullulation_power.id
					  end,
	RealPowerList	= lists:sort(Fun, PowerList2),
	pullulation_power_info_ext(RealPowerList).
pullulation_power_info_ext([])	-> welfare_api:pack_sc_pullulation_power(0);
pullulation_power_info_ext(PullPowerList)	->
	[PullPower|_]		= PullPowerList,
	Id					= PullPower#pullulation_power.id,
	welfare_api:pack_sc_pullulation_power(Id).

%% UserId	玩家ID
%% Vip		玩家VIP等级
%% CurSum	本次充值金额
%% AccSum	累计充值金额
deposit(UserId, Vip, CurSum, AccSum)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, deposit_cb, [Vip, CurSum, AccSum]);
		_Other	->
			WelfareOffLine	= #welfare_offline{vip		= Vip,
											   cur_sum	= CurSum,
											   acc_sum	= AccSum},
			player_offline_api:offline(?MODULE, UserId, WelfareOffLine)
	end.

deposit_cb(Player, [Vip, CurSum, AccSum])	->
	NewPlayer	= welfare_mod:deposit(Player, CurSum, AccSum),
	player_api:vip(NewPlayer, Vip).

vip(Player) ->
	welfare_mod:vip(Player).

%% 新手礼包
novice(UserId) when is_integer(UserId)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, novice_cb, []);
		_Other	->
			?ok
%% 			WelfareOffLine	= #welfare_offline{},
%% 			player_offline_api:offline(?MODULE, UserId, WelfareOffLine)
	end.

novice_cb(Player, []) when is_record(Player, player)	->
	?MSG_WARNING("~nUserId=~p~n", [Player#player.user_id]),
	{?ok, Player}.

%% 媒体礼包
media(UserId) when is_integer(UserId)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, media_cb, []);
		_Other	->
			?ok
%% 			WelfareOffLine	= #welfare_offline{},
%% 			player_offline_api:offline(?MODULE, UserId, WelfareOffLine)
	end.

media_cb(Player, []) when is_record(Player, player) ->
	{?ok, Player}.

level_up(Player) ->
%%	?MSG_DEBUG("******** level up ************", []),
	Player2 = welfare_mod:add_first_login(Player),
	Player3 = welfare_mod:level_up(Player2),
	welfare_mod:refight_battlefield(Player3).

pack_sc_gift_info(_Type, [])	-> <<>>;
pack_sc_gift_info(Type, GiftList)	->
	misc_packet:pack(?MSG_ID_WELFARE_SCGIFTINFO,
					 ?MSG_FORMAT_WELFARE_SCGIFTINFO,
					 [Type, GiftList]).

pack_sc_draw(Type, GiftList)	->
	misc_packet:pack(?MSG_ID_WELFARE_SCDRAW,
					 ?MSG_FORMAT_WELFARE_SCDRAW,
					 [Type, GiftList]).

pack_sc_pullulation([])	-> <<>>;
pack_sc_pullulation(Pullulation)	->
	misc_packet:pack(?MSG_ID_WELFARE_SCPULLULATION,
					 ?MSG_FORMAT_WELFARE_SCPULLULATION,
					 [Pullulation]).

pack_sc_receive(Id)	->
	misc_packet:pack(?MSG_ID_WELFARE_SCRECEIVE,
					 ?MSG_FORMAT_WELFARE_SCRECEIVE,
					 [Id]).

pack_sc_pullulation_power(Id)	->
	misc_packet:pack(?MSG_ID_WELFARE_SC_POWER,
					 ?MSG_FORMAT_WELFARE_SC_POWER,
					 [Id]).

pack_sc_sign_times(Times)	->
	misc_packet:pack(?MSG_ID_WELFARE_SC_LOGIN_SIGN_TIMES,
					 ?MSG_FORMAT_WELFARE_SC_LOGIN_SIGN_TIMES,
					 [Times]).

%% 充值礼包
%%[ActiveId,GiftId,State]
msg_sc_deposit_info(ActiveId,GiftId,State) ->
    misc_packet:pack(?MSG_ID_WELFARE_SC_DEPOSIT_INFO, ?MSG_FORMAT_WELFARE_SC_DEPOSIT_INFO, [ActiveId,GiftId,State]).
%% 充值信息
%%[ActiveId,Out,In]
msg_sc_rmb(ActiveId,Out,In) ->
    misc_packet:pack(?MSG_ID_WELFARE_SC_RMB, ?MSG_FORMAT_WELFARE_SC_RMB, [ActiveId,Out,In]).
%% 活动结束时间
%%[Sec]
msg_sc_end_time(Sec) ->
    misc_packet:pack(?MSG_ID_WELFARE_SC_END_TIME, ?MSG_FORMAT_WELFARE_SC_END_TIME, [Sec]).
%% 基金状态
%%[Type,State]
msg_sc_jj_state(Type,State) ->
    misc_packet:pack(?MSG_ID_WELFARE_SC_JJ_STATE, ?MSG_FORMAT_WELFARE_SC_JJ_STATE, [Type,State]).

%%
%% Local Functions
%%

