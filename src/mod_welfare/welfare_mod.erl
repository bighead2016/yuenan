%% Author: Administrator
%% Created: 2012-12-5
%% Description: TODO: Add description to welfare2_mod
-module(welfare_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("const.cost.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([init_player_welfare/1, deposit/3, vip/1,
		 draw/3, refresh_zero/1,
		 refresh/1, login_packet/1, welfare_info/2, welfare_packet/3,
		 offline/3, novice/1, level_up/1, refight_battlefield/1, media/1,
		 continue_login/1,
		 reset_welfare_data/2,
		 filter/2,
		 add_pullulation/3, 
		 add_pullulation/4, 
		 pullulation/2, 
		 add_first_login/1, 
		 continue_login_review/2,
		 reward_goods/2,
		 reward_cash_bind/4,
		 reward_cash/4]).
%%
%% API Functions
%%
init_player_welfare(UserId) ->
	Login	= misc:seconds(),
%% 	Data	= init_welfare_data(?CONST_WELFARE_CONTINUOUS)
%% 		   ++ init_welfare_data(?CONST_WELFARE_LEVELUP),
%% 		   ++ init_welfare_data(?CONST_WELFARE_LOGIN),
	Data	= init_welfare_data(?CONST_WELFARE_LEVELUP),
    Deposit = welfare_deposit_api:init(),
	#welfare{
             user_id		= UserId,
			 first_login	= Login,
			 login			= Login,
			 online			= 0,
			 data			= Data,
             deposit        = Deposit
            }.

%% 连续在线礼包
%% 连续登陆礼包
%% 成长礼包
init_welfare_data(Type)	->
	RecWelfare	= data_welfare:get_welfare_init(Type),
	case check_welfare_gift(RecWelfare#rec_welfare.id) of
		?true	->
			Tuple	= #welfare_data{type	= Type,
									first	= RecWelfare#rec_welfare.cd,
									id		= RecWelfare#rec_welfare.id,
									state	= ?CONST_WELFARE_UNFIT},
			[Tuple];
		?false	->	[]
	end.

%% 每日0点更新(不更新登陆时间)
refresh_zero(Player) when is_record(Player, player)		->
	Welfare		= Player#player.welfare,
	NewWelfare	= refresh_welfare(Welfare),
	Player#player{welfare	= NewWelfare};
refresh_zero(Welfare) when is_record(Welfare, welfare)	->
	Login		= misc:seconds(),
	LastLogin	= Welfare#welfare.login,
	OffWelfare	= Welfare,%%offline(Welfare, Login, LastLogin), 离线礼包屏蔽
	NewWelfare	= case misc:is_same_date(LastLogin, Login) of
					  ?true		->
						  OffWelfare;
					  ?false	->
						  WelfareData	= reset_welfare_data(?CONST_WELFARE_VIP_DAILY, OffWelfare#welfare.data),
						  OffWelfare#welfare{fill_sign_times = 0, data	= WelfareData}
				  end,
	refresh_welfare(NewWelfare).

%% 更新时间和刷新每日领取的礼包
refresh(Player) when is_record(Player, player)		->
	Welfare		= Player#player.welfare,
	NewWelfare	= refresh_welfare(Welfare),
	Player#player{welfare	= NewWelfare};
refresh(Welfare) when is_record(Welfare, welfare)	->
	Login		= misc:seconds(),
	LastLogin	= Welfare#welfare.login,
	OffWelfare	= Welfare,%%offline(Welfare, Login, LastLogin), 离线礼包屏蔽
	NewWelfare	= case misc:is_same_date(LastLogin, Login) of
					  ?true		->
						  OffWelfare#welfare{login	= Login};
					  ?false	->
						  WelfareData	= reset_welfare_data(?CONST_WELFARE_VIP_DAILY, OffWelfare#welfare.data),
						  OffWelfare#welfare{fill_sign_times = 0, login	= Login,	data	= WelfareData}
				  end,
	refresh_welfare(NewWelfare).

%% 刷新礼包
refresh_welfare(Welfare) when is_record(Welfare, welfare)	->
	NewWelfare  = check_login_welfare(Welfare),
	NewWelfare2	= continue_login(NewWelfare),
	continue_online(NewWelfare2).

%% 连续登陆奖励对老号登陆时做处理
check_login_welfare(Welfare) ->
	WelfareData = Welfare#welfare.data,
	GiftIdList	= data_welfare:get_type_list_param(?CONST_WELFARE_LOGIN),
	NewWelfareData = 
		case lists:keyfind(?CONST_WELFARE_LOGIN_LAST_ID, #welfare_data.id, WelfareData) of
			Tuple when Tuple#welfare_data.state =:= ?CONST_WELFARE_RECEIVED ->
				clear_continue_login(WelfareData, GiftIdList);
			_ ->
				WelfareData
		end,
	Welfare#welfare{data = NewWelfareData}.

login_packet(Welfare)	->
	TypeList	= data_welfare:get_type_list(),
	Packet		= login_packet(Welfare, TypeList, <<>>),
	Pullulation	= Welfare#welfare.pullulation,
	PullList	= [{Id, Flag, Received} || #pullulation{id = Id, flag	= Flag, received = Received} <- Pullulation, Flag =:= ?true],
	AddPacket	= welfare_api:pack_sc_pullulation(PullList),
	PowerPacket	= welfare_api:pullulation_power_info(Welfare),
	LoginSignTimesPacket	= welfare_api:pack_sc_sign_times(Welfare#welfare.fill_sign_times),
	<<Packet/binary, AddPacket/binary, PowerPacket/binary, LoginSignTimesPacket/binary>>.
login_packet(Welfare, [Type | TypeList], Packet)	->
	NewPacket	= login_packet(Welfare, Type, Packet),
	login_packet(Welfare, TypeList, NewPacket);
login_packet(_Welfare, [], Packet)	->
	Packet;
login_packet(Welfare, Type, Packet)
  when Type =:= ?CONST_WELFARE_LOGIN	->
	AllPacket		= welfare_packet(Welfare, Type, <<>>),
	<<Packet/binary, AllPacket/binary>>;
login_packet(Welfare, Type, Packet)
  when Type =:= ?CONST_WELFARE_CONTINUOUS
orelse Type =:= ?CONST_WELFARE_LEVELUP	->
	UnFitPacket		= welfare_packet(Welfare, Type, ?CONST_WELFARE_UNFIT, <<>>),
	UnClaimedPacket	= welfare_packet(Welfare, Type, ?CONST_WELFARE_UNCLAIMED, <<>>),
	<<Packet/binary, UnFitPacket/binary, UnClaimedPacket/binary>>;
login_packet(Welfare, Type, Packet)		->
	UnClaimedPacket	= welfare_packet(Welfare, Type, ?CONST_WELFARE_UNCLAIMED, <<>>),
	<<Packet/binary, UnClaimedPacket/binary>>.

welfare_packet(Welfare, Type, Packet)	->
	FilterList	= filter(Welfare#welfare.data, Type),
	welfare_packet(Welfare, Type, FilterList, Packet).
welfare_packet(Welfare, Type, State, Packet) when is_integer(State)	->
	FilterList	= filter(Welfare#welfare.data, Type, State),
	welfare_packet(Welfare, Type, FilterList, Packet);
welfare_packet(Welfare, Type, FilterList, Packet) when is_list(FilterList)	->
	Login		= Welfare#welfare.login,
	OnLine		= Welfare#welfare.online,
	FoldlFun	= fun(Data, Acc)	->
						  Tuple	= convert(Login, OnLine, Data),
						  [Tuple | Acc]
				  end,
	GiftList	= lists:foldl(FoldlFun, [], FilterList),
	AddPacket	= if
					  length(GiftList) > 0	->
						  welfare_api:pack_sc_gift_info(Type, GiftList);
					  ?true	->	<<>>
				  end,
	<<Packet/binary, AddPacket/binary>>.

filter(WelfareData, Type)	->
	Fun	= fun(Data)	->
				  Data#welfare_data.type =:= Type
		  end,
	lists:filter(Fun, WelfareData).

filter(WelfareData, Type, State)	->
	Fun	= fun(Data)	->
				  Data#welfare_data.type =:= Type andalso Data#welfare_data.state =:= State
		  end,
	lists:filter(Fun, WelfareData).

convert(Login, OnLine, WelfareData)
  when is_record(WelfareData, welfare_data) andalso
	WelfareData#welfare_data.type	=:= ?CONST_WELFARE_CONTINUOUS andalso
	WelfareData#welfare_data.state	=:= ?CONST_WELFARE_UNFIT	->
	Now			= misc:seconds(),
	Id			= WelfareData#welfare_data.id,
	State		= WelfareData#welfare_data.state,
	Cd			= WelfareData#welfare_data.first,
	RemainTime	= misc:max(Cd - OnLine - Now + Login, 0),
	{Id, State, RemainTime};
convert(_Login, _OnLine, WelfareData)
  when is_record(WelfareData, welfare_data) andalso
	WelfareData#welfare_data.type	=:= ?CONST_WELFARE_OFFLINE	->
	Id			= WelfareData#welfare_data.id,
	State		= WelfareData#welfare_data.state,
	RemainTime	= WelfareData#welfare_data.first,
	{Id, State, RemainTime};
convert(_Login, _OnLine, WelfareData)	->
	Id			= WelfareData#welfare_data.id,
	State		= WelfareData#welfare_data.state,
	RemainTime	= 0,
	{Id, State, RemainTime}.

welfare_info(Player, Type) when is_record(Player, player) andalso is_integer(Type)	->
	Welfare		= Player#player.welfare,
	NewWelfare	= refresh_welfare(Welfare),
	Packet		= welfare_packet(NewWelfare, Type, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player#player{welfare = NewWelfare}}.

%% 连续在线礼包
continue_online(Welfare) ->
	WelfareData	= Welfare#welfare.data,
	FilterList	= filter(WelfareData, ?CONST_WELFARE_CONTINUOUS, ?CONST_WELFARE_UNFIT),
	case FilterList of
		[]		->	Welfare;
		[Tuple | _] when is_record(Tuple, welfare_data)	->
			Login			= Welfare#welfare.login,
			OnLine			= Welfare#welfare.online,
			SecondDiff		= misc:seconds() - Login + OnLine,
			MinuteDiff		= SecondDiff div ?CONST_WELFARE_MINUTE2SECOND,
			GiftId			= Tuple#welfare_data.id,
			NewWelfareData	= refresh_welfare_data(GiftId, MinuteDiff, WelfareData),
			Welfare#welfare{data = NewWelfareData}
	end.

%% 升级增加连续登陆礼包第一天奖励
add_first_login(Player) ->
	Lv = (Player#player.info)#info.lv,
	Now				= misc:seconds(),
	Welfare			= Player#player.welfare,
	WelfareData		= Welfare#welfare.data,
	if Lv =:= ?CONST_WELFARE_CONTINUE_LV ->
		   RecWelfare	= data_welfare:get_welfare_init(?CONST_WELFARE_CONTINUOUS),
		   Id			= RecWelfare#rec_welfare.id,
		   Cd			= RecWelfare#rec_welfare.cd,
		   NewWelfareData	=
			   case lists:keyfind(Id, #welfare_data.id, WelfareData) of
				   OldTuple when is_record(OldTuple, welfare_data) ->
					   NewTuple 	= OldTuple#welfare_data{second	= Now, state	= ?CONST_WELFARE_UNCLAIMED},
					   lists:keyreplace(?CONST_WELFARE_LOGIN_FIRST_ID, #welfare_data.id, WelfareData, NewTuple);
				   _ ->
					   NewTuple		= #welfare_data{type	= ?CONST_WELFARE_CONTINUOUS,
													first	= RecWelfare#rec_welfare.cd,
													id		= Id,
													state	= ?CONST_WELFARE_UNCLAIMED},
					   [NewTuple|WelfareData]
			   end,
		   NewWelfare		= Welfare#welfare{data = NewWelfareData},
		   Login			= Welfare#welfare.login,
		   OnLine			= Welfare#welfare.online,
		   RemainTime		= Cd - OnLine - Now + Login,
		   GiftList		= [{NewTuple#welfare_data.id, NewTuple#welfare_data.state, RemainTime}],
		   Packet			= welfare_api:pack_sc_gift_info(?CONST_WELFARE_CONTINUOUS, GiftList),
		   misc_packet:send(Player#player.user_id, Packet),
		   Player#player{welfare = NewWelfare};
	   Lv =:= ?CONST_WELFARE_LOGIN_FIRST_LV ->
		   NewWelfareData	=
			   case lists:keyfind(?CONST_WELFARE_LOGIN_FIRST_ID, #welfare_data.id, WelfareData) of
				   OldTuple when is_record(OldTuple, welfare_data) ->
					   NewTuple 	= OldTuple#welfare_data{second	= Now, state	= ?CONST_WELFARE_UNCLAIMED},
					   lists:keyreplace(?CONST_WELFARE_LOGIN_FIRST_ID, #welfare_data.id, WelfareData, NewTuple);
				   _ ->
					   NewTuple		= #welfare_data{type	= ?CONST_WELFARE_LOGIN,
													second	= Now,
													id		= ?CONST_WELFARE_LOGIN_FIRST_ID,
													state	= ?CONST_WELFARE_UNCLAIMED},
					   [NewTuple|WelfareData]
			   end,
		   NewWelfare		= Welfare#welfare{data = NewWelfareData},
		   GiftList		= [{NewTuple#welfare_data.id, NewTuple#welfare_data.state, NewTuple#welfare_data.second}],
		   Packet			= welfare_api:pack_sc_gift_info(?CONST_WELFARE_LOGIN, GiftList),
		   misc_packet:send(Player#player.user_id, Packet),
		   Player#player{welfare = NewWelfare};
	   ?true ->
		   Player
	end.

%% 增加连续登陆礼包最后的奖励
add_last_login(Player) ->
	Welfare			= Player#player.welfare,
	WelfareData		= Welfare#welfare.data,
	NewWelfareData	=
		case lists:keyfind(?CONST_WELFARE_LOGIN_LAST_ID, #welfare_data.id, WelfareData) of
			OldTuple when is_record(OldTuple, welfare_data) ->
				NewTuple 	= OldTuple#welfare_data{state	= ?CONST_WELFARE_UNCLAIMED},
				lists:keyreplace(?CONST_WELFARE_LOGIN_LAST_ID, #welfare_data.id, WelfareData, NewTuple);
			_ ->
				NewTuple		= #welfare_data{type	= ?CONST_WELFARE_LOGIN,
												id		= ?CONST_WELFARE_LOGIN_LAST_ID,
												state	= ?CONST_WELFARE_UNCLAIMED},
				[NewTuple|WelfareData]
		end,
	NewWelfare		= Welfare#welfare{data = NewWelfareData},
	GiftList		= [{NewTuple#welfare_data.id, NewTuple#welfare_data.state, NewTuple#welfare_data.second}],
	Packet			= welfare_api:pack_sc_gift_info(?CONST_WELFARE_LOGIN, GiftList),
	misc_packet:send(Player#player.user_id, Packet),
	Player#player{welfare = NewWelfare}.

%% 获取连续登陆首次奖励的日期
diff_days(Welfare, Seconds) ->
	WelfareData		= Welfare#welfare.data,
	RecWelfare		= data_welfare:get_welfare_init(?CONST_WELFARE_LOGIN),
	Id				= RecWelfare#rec_welfare.id,
	case lists:keyfind(Id, #welfare_data.id, WelfareData) of
		Tuple when is_record(Tuple, welfare_data) ->
			misc:get_diff_days(Tuple#welfare_data.second, Seconds);
		_ ->
			0
	end.

%% 测试用
%% continue_login(Welfare) ->
%% 	Data = [#welfare_data{type = 3,first = 0,second = 1366881795,
%%                                id = 10013,state = 2},
%%                  #welfare_data{type = 10,first = 0,second = 0,id = 10051,
%%                                state = 0},
%%                  #welfare_data{type = 1,first = 60,second = 0,id = 10001,
%%                                state = 1},
%%                  #welfare_data{type = 10,first = 0,second = 0,id = 10050,
%%                                state = 1}],
%% 	NewWelfare = Welfare#welfare{data = Data, fill_sign_times = 0}.
%% 连续登陆礼包
continue_login(Welfare) ->
	Now			= misc:seconds(),
	Diff 		= diff_days(Welfare, Now),
	FilterList  = filter(Welfare#welfare.data, ?CONST_WELFARE_LOGIN),
	GiftList	= data_welfare:get_type_list_param(?CONST_WELFARE_LOGIN),
	GiftLength		= length(GiftList),
	if length(FilterList) =:= 0 ->
		   Welfare;
	   ?true ->
			case Diff > 0  of
				?true ->
					case  Diff < GiftLength of
						?true ->
							add_continue_login(?CONST_WELFARE_LOGIN_FIRST_ID, Diff, Welfare, ?CONST_WELFARE_UNCLAIMED);
						?false ->
							add_continue_login(?CONST_WELFARE_LOGIN_FIRST_ID, GiftLength - 2, Welfare, ?CONST_WELFARE_UNFIT)
					end;
				?false ->
					Welfare
			end
	end.

%% 增加连续登陆礼包
add_continue_login(GiftId, 1, Welfare, State) -> 
	add_continue_login_ext(GiftId + 1, Welfare, State);
add_continue_login(GiftId, Diff, Welfare, State) ->
%% 	Seconds		= misc:seconds(),
	NewGiftId	= GiftId + 1,
	NewDiff		= Diff - 1,
	NewWelfare	= add_continue_login_ext(NewGiftId, Welfare, ?CONST_WELFARE_UNFIT),
	add_continue_login(NewGiftId, NewDiff, NewWelfare, State).


add_continue_login_ext(GiftId, Welfare, State) ->
	WelfareData	= Welfare#welfare.data,
	GiftList	= data_welfare:get_type_list_param(?CONST_WELFARE_LOGIN),
	NewWelfareData =
		case lists:member(GiftId, GiftList) of
			?true ->
				case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
					Tuple when is_record(Tuple, welfare_data)  ->
						WelfareData;
					_Other ->
						if GiftId =:= ?CONST_WELFARE_LOGIN_LAST_ID  ->
							   WelfareData;
						   true ->
							   NewTuple		= #welfare_data{type = ?CONST_WELFARE_LOGIN, id	= GiftId,  state = State},
							   [NewTuple|WelfareData]
						end						
				end;
			?false ->
				WelfareData
		end,
	Welfare#welfare{data = NewWelfareData}.

%% 连续登陆补签
continue_login_review(Player, GiftId) ->
	Welfare 	= Player#player.welfare,
	case Welfare#welfare.fill_sign_times =:= 0 of
		?true ->
			continue_login_review_ext(Player, GiftId);
		?false ->
			Packet = message_api:msg_notice(?TIP_WELFARE_LOGIN_SIGN_IS_MAX),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player}
	end.

continue_login_review_ext(Player, GiftId) ->
	case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, ?CONST_WELFARE_LOGIN_REVIEW_COST, ?CONST_COST_WELFARE_REVIEW) of
		?ok -> 
			Welfare	   = Player#player.welfare,
			WelfareData	= Welfare#welfare.data,
			GiftIdList	= data_welfare:get_type_list_param(?CONST_WELFARE_LOGIN),
			NewWelfareData =
				case lists:member(GiftId, GiftIdList) of
					?true ->
						case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
							Tuple when is_record(Tuple, welfare_data)  ->
								NewTuple		= Tuple#welfare_data{state = ?CONST_WELFARE_UNCLAIMED},
								GiftList		= [{NewTuple#welfare_data.id, NewTuple#welfare_data.state, NewTuple#welfare_data.second}],
								Packet			= welfare_api:pack_sc_gift_info(?CONST_WELFARE_LOGIN, GiftList),
								misc_packet:send(Player#player.user_id, Packet),
								lists:keyreplace(GiftId, #welfare_data.id, WelfareData, NewTuple);
							_Other ->
								WelfareData
						end;
					?false ->
						WelfareData
				end,
			NewFillSignTimes = Welfare#welfare.fill_sign_times + 1,
			NewWelfare	= Welfare#welfare{data = NewWelfareData, fill_sign_times = NewFillSignTimes},
			Packet2			= welfare_api:pack_sc_sign_times(NewFillSignTimes),
			misc_packet:send(Player#player.user_id, Packet2),
			NewPlayer  = Player#player{welfare = NewWelfare},
			{?ok, NewPlayer};
		_Other ->
			{?ok, Player}
	end.
	
%% 离线奖励礼包（登录时通过邮件领取）
offline(Welfare, Login, LastLogin)	->
	WelfareData	= Welfare#welfare.data,
	SecondDiff	= Login - LastLogin,
	MinuteDiff	= SecondDiff div ?CONST_WELFARE_MINUTE2SECOND,
	HourDiff	= MinuteDiff div ?CONST_WELFARE_HOUR2MINUTE,
	DayDiff		= HourDiff div ?CONST_WELFARE_DAY2HOUR,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_OFFLINE, DayDiff, WelfareData),
	Welfare#welfare{data = NewWelfareData}.

deposit(Player, CurSum, AccSum)	->
	Player1	= first_deposit(Player, CurSum, AccSum),
	Player2	= single_deposit(Player1, CurSum),
	accum_deposit(Player2, AccSum).

%% 首冲礼包
first_deposit(Player, CurSum, AccSum)
  when is_record(Player, player) andalso CurSum > 0 andalso CurSum =:= AccSum	->
	UserId		= Player#player.user_id,
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(UserId, ?CONST_WELFARE_FIRST_DEPOSIT, WelfareData),
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Packet		= welfare_packet(NewWelfare, ?CONST_WELFARE_FIRST_DEPOSIT, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	Player#player{welfare = NewWelfare};
first_deposit(Player, _CurSum, _AccSum)	->	Player.

%% 单笔充值礼包
single_deposit(Player, CurSum)
  when is_record(Player, player) andalso CurSum > 0	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_SINGLE_DEPOSIT, CurSum, WelfareData),
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Packet		= welfare_packet(NewWelfare, ?CONST_WELFARE_SINGLE_DEPOSIT, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	Player#player{welfare = NewWelfare};
single_deposit(Player, _CurSum)	->	Player.

%% 累计充值礼包
accum_deposit(Player, AccSum)
  when is_record(Player, player) andalso AccSum > 0	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_ACCUM_DEPOSIT, AccSum, WelfareData),
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Packet		= welfare_packet(NewWelfare, ?CONST_WELFARE_ACCUM_DEPOSIT, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	Player#player{welfare = NewWelfare};
accum_deposit(Player, _AccSum)	->	Player.

vip(Player) when is_record(Player, player)	->
	Welfare		= Player#player.welfare,
	Welfare1	= vip_level(Player, Welfare),
	LevelPacket	= welfare_packet(Welfare1, ?CONST_WELFARE_VIP_LEVEL, <<>>),
	Welfare2	= vip_daily(Player, Welfare1),
	DailyPacket	= welfare_packet(Welfare2, ?CONST_WELFARE_VIP_DAILY, <<>>),
	misc_packet:send(Player#player.net_pid, <<LevelPacket/binary, DailyPacket/binary>>),
	Player#player{welfare = Welfare2}.

%% 每日VIP福利礼包
vip_daily(Player, Welfare)	->
	Info		= Player#player.info,
	VipLevel	= player_api:get_vip_lv(Info),
	WelfareData	= Welfare#welfare.data,
	case lists:keyfind(?CONST_WELFARE_VIP_DAILY, #welfare_data.type, WelfareData) of
		Tuple when is_record(Tuple, welfare_data)	->
			case data_welfare:get_welfare({?CONST_WELFARE_VIP_DAILY, VipLevel}) of
				?null	->	Welfare;
				GiftId	->
					NewTuple		= Tuple#welfare_data{id	= GiftId},
					NewWelfareData	= lists:keyreplace(?CONST_WELFARE_VIP_DAILY, #welfare_data.type, WelfareData, NewTuple),
					Welfare#welfare{data = NewWelfareData}
			end;
		_Other	->
			case data_welfare:get_welfare({?CONST_WELFARE_VIP_DAILY, VipLevel}) of
				?null	->	Welfare;
				GiftId	->
					NewWelfareData	= add_welfare_data(?CONST_WELFARE_VIP_DAILY, GiftId, WelfareData),
					Welfare#welfare{data = NewWelfareData}
			end
	end.

%% VIP等级礼包
vip_level(Player, Welfare)	->
	Info			= Player#player.info,
	VipLevel		= player_api:get_vip_lv(Info),
	WelfareData		= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_VIP_LEVEL, VipLevel, WelfareData),
	Welfare#welfare{data = NewWelfareData}.

%% 累计在线可以连续领取
%% 离线奖励按最大离线时间领取
%% 每天签到
%% 累计签到可以连续领取
%% 单笔充值按区间领取
%% 累计充值向上兼任（每个礼包只能领取一次）
draw(Player, Type, ?true) when is_record(Player, player)	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	FilterList	= filter(WelfareData, Type, ?CONST_WELFARE_UNCLAIMED),
	{
	 ?ok, NewPlayer, _NewGoodsList, NewWelfareData, GiftIdList
	}			= draw(Player, FilterList, [], WelfareData, []),
	NewWelfare	= draw(Welfare, Type, NewWelfareData),
	Packet		= welfare_api:pack_sc_draw(Type, GiftIdList),
	misc_packet:send(NewPlayer#player.net_pid, Packet),
	{?ok, NewPlayer#player{welfare = NewWelfare}};
draw(Player, GiftId, ?false) when is_record(Player, player)	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
		Tuple when is_record(Tuple, welfare_data)
					   andalso Tuple#welfare_data.state =:= ?CONST_WELFARE_UNCLAIMED	->
			%% case check_front_gift_draw(GiftId, WelfareData, Tuple#welfare_data.type) of
			%% ?true ->
			{
			 ?ok, NewPlayer, _NewGoodsList, NewWelfareData, GiftIdList
			}			= draw(Player, [Tuple], [], WelfareData, []),
			NewWelfare	= draw(Welfare, Tuple#welfare_data.type, NewWelfareData),
			NewPlayer2  = NewPlayer#player{welfare = NewWelfare},
			NewPlayer3  = 
				case GiftId + 1 of
					?CONST_WELFARE_LOGIN_LAST_ID ->
						add_last_login(NewPlayer2);
					_ ->
						NewPlayer2
				end,
			NewPlayer4  = check_is_final_draw(NewPlayer3, GiftId),
			NewPlayer5  = check_is_final_draw2(NewPlayer4, GiftId),
			Packet		= welfare_api:pack_sc_draw(Tuple#welfare_data.type, GiftIdList),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, NewPlayer5};
		%% 				?false ->
		%% 					TipsPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
		%% 					misc_packet:send(Player#player.user_id, TipsPacket),
		%% 					{?ok, Player}
		%% 			end;
		_Other	->	{?ok, Player}
	end;
draw(Welfare, Type, NewWelfareData) when is_record(Welfare, welfare)	->
	if
		Type =:= ?CONST_WELFARE_CONTINUOUS	->
			Login	= Welfare#welfare.login,
			Welfare#welfare{online	= misc:seconds() - Login,
							data	= NewWelfareData};
		?true	->
			Welfare#welfare{data	= NewWelfareData}
	end.

draw(Player, [Tuple | TupleList], GoodsList, WelfareData, GiftIdList) ->
	GiftId	= Tuple#welfare_data.id,
	case data_welfare:get_welfare_info(GiftId) of
		RecWelfare when is_record(RecWelfare, rec_welfare)	->
			case reward(Player, RecWelfare) of
				{?error, _ErrorCode}			->
					{?ok, Player, GoodsList, WelfareData, GiftIdList};
				{?ok, NewPlayer, NewGoodsList}	->
					NewWelfareData	= next(Tuple, RecWelfare, WelfareData),
					NewGiftIdList	= [{GiftId} | GiftIdList],
					draw(NewPlayer, TupleList, NewGoodsList ++ GoodsList, NewWelfareData, NewGiftIdList)
			end;
		_Other	->	{?ok, Player, GoodsList, WelfareData, GiftIdList}
	end;
draw(Player, [], GoodsList, WelfareData, GiftIdList)	->
	{?ok, Player, GoodsList, WelfareData, GiftIdList}.

check_is_final_draw2(Player, GiftId) ->
	Welfare		= Player#player.welfare,
	WelfareData = Welfare#welfare.data,
	GiftIdList	= data_welfare:get_type_list_param(?CONST_WELFARE_REFIGHT_BATTLEFIELD),
	case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
		Tuple when is_record(Tuple, welfare_data)  ->
			IsTrue = check_front_gift_draw(?CONST_WELFARE_REFIGHT_BATTLEFIELD_LAST_ID + 1, WelfareData, ?CONST_WELFARE_REFIGHT_BATTLEFIELD),
			case IsTrue =:= ?true of
				?true ->
					NewWelfareData = clear_continue_login(WelfareData, GiftIdList),
                    NewWelfare  = Welfare#welfare{data = NewWelfareData},
                    Player2 = update_data(Player),
                    Player2#player{welfare = NewWelfare};
				?false ->
					Player
			end;
		_ ->
			Player
	end.

check_is_final_draw(Player, GiftId) ->
	Welfare		= Player#player.welfare,
	WelfareData = Welfare#welfare.data,
	GiftIdList	= data_welfare:get_type_list_param(?CONST_WELFARE_LOGIN),
	NewWelfareData	=
		case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
			Tuple when is_record(Tuple, welfare_data)  ->
				case Tuple#welfare_data.state =:= ?CONST_WELFARE_RECEIVED 
										andalso GiftId =:= ?CONST_WELFARE_LOGIN_LAST_ID of
					?true ->
						clear_continue_login(WelfareData, GiftIdList);
					?false ->
						WelfareData
				end;
			_ ->
				WelfareData
		end,
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Player#player{welfare = NewWelfare}.

clear_continue_login(WelfareData, []) -> WelfareData;
clear_continue_login(WelfareData, [GiftId|GiftIdList]) ->
	NewWelfareData = lists:keydelete(GiftId, #welfare_data.id, WelfareData),
	clear_continue_login(NewWelfareData, GiftIdList).

update_data(Player) ->
	Info = Player#player.info,
    Player#player{info = Info#info{is_draw = 2}}.

%% 检查上一个奖励是否领取
check_front_gift_draw(?CONST_WELFARE_REFIGHT_BATTLEFIELD_FIRST_ID, _WelfareData, ?CONST_WELFARE_REFIGHT_BATTLEFIELD) ->
	?true;
check_front_gift_draw(CurGiftId, WelfareData, ?CONST_WELFARE_REFIGHT_BATTLEFIELD) ->
	FrontGiftId		= CurGiftId - 1,
	case lists:keyfind(FrontGiftId, #welfare_data.id, WelfareData) of
		Tuple when is_record(Tuple, welfare_data)
		  andalso Tuple#welfare_data.state =:= ?CONST_WELFARE_RECEIVED ->
			check_front_gift_draw(FrontGiftId, WelfareData, ?CONST_WELFARE_REFIGHT_BATTLEFIELD);
		_Other ->
			?false
	end;
check_front_gift_draw(_CurGiftId, _WelfareData, _Type) ->
	?true.

next(Tuple, RecWelfare, WelfareData)
  when is_record(Tuple, welfare_data)
  andalso Tuple#welfare_data.type =:= ?CONST_WELFARE_CONTINUOUS	->
	GiftId			= Tuple#welfare_data.id,
	NewTuple		= Tuple#welfare_data{state	= ?CONST_WELFARE_RECEIVED},
	NewWelfareData	= lists:keyreplace(GiftId, #welfare_data.id, WelfareData, NewTuple),
	next(Tuple#welfare_data.type, RecWelfare, NewWelfareData);
next(Tuple, _RecWelfare, WelfareData)
  when is_record(Tuple, welfare_data)	->
	GiftId		= Tuple#welfare_data.id,
	NewTuple	= Tuple#welfare_data{state	= ?CONST_WELFARE_RECEIVED},
	lists:keyreplace(GiftId, #welfare_data.id, WelfareData, NewTuple);
next(Type, RecWelfare, WelfareData)
  when (Type =:= ?CONST_WELFARE_CONTINUOUS
		orelse Type =:= ?CONST_WELFARE_LOGIN
		orelse Type =:= ?CONST_WELFARE_LEVELUP)
  andalso is_record(RecWelfare, rec_welfare)	->
	add(Type, RecWelfare#rec_welfare.next, WelfareData);
next(Type, GiftId, WelfareData)
  when (Type =:= ?CONST_WELFARE_LOGIN orelse Type =:= ?CONST_WELFARE_LEVELUP) andalso is_integer(GiftId)	->
	case data_welfare:get_welfare_info(GiftId) of
		RecWelfare when is_record(RecWelfare, rec_welfare)	->
			next(Type, RecWelfare, WelfareData);
		_Other	->	WelfareData
	end;
%% next(GiftId, GiftId, WelfareData)	->
%% 	case data_welfare:get_welfare_info(GiftId) of
%% 		RecWelfare when is_record(RecWelfare, rec_welfare)	->
%% 			Type	= RecWelfare#rec_welfare.type,
%% 			next(Type, RecWelfare, WelfareData);
%% 		_Other	->	WelfareData
%% 	end;
next(_Type, _GiftId, WelfareData)	->
	WelfareData.

add(Type, GiftId, WelfareData)
  when Type =:= ?CONST_WELFARE_CONTINUOUS
	   orelse Type =:= ?CONST_WELFARE_LOGIN
	   orelse Type =:= ?CONST_WELFARE_LEVELUP	->
	EnableFlag	= check_welfare_gift(GiftId),
	RecWelfare	= data_welfare:get_welfare_info(GiftId),
	case {RecWelfare, EnableFlag} of
		{RecWelfare, ?true} when is_record(RecWelfare, rec_welfare)	->
			NewTuple	= #welfare_data{type	= RecWelfare#rec_welfare.type,
										first	= RecWelfare#rec_welfare.cd,
										id		= GiftId,
										state	= ?CONST_WELFARE_UNFIT},
			[NewTuple|WelfareData];
		{?null, _}	->	WelfareData;
		{_, ?false}	->	WelfareData
	end;
add(_Type, GiftId, WelfareData)	->
	EnableFlag	= check_welfare_gift(GiftId),
	RecWelfare	= data_welfare:get_welfare_info(GiftId),
	case {RecWelfare, EnableFlag} of
		{RecWelfare, ?true} when is_record(RecWelfare, rec_welfare)	->
			NewTuple	= #welfare_data{type	= RecWelfare#rec_welfare.type,
										first	= RecWelfare#rec_welfare.cd,
										id		= GiftId,
										state	= ?CONST_WELFARE_UNCLAIMED},
			[NewTuple|WelfareData];
		{?null, _}	->	WelfareData;
		{_, ?false}	->	WelfareData
	end.
add(Type, GiftId, Condition, WelfareData)	->
	EnableFlag	= check_welfare_gift(GiftId),
	RecWelfare	= data_welfare:get_welfare_info(GiftId),
	case {RecWelfare, EnableFlag} of
		{RecWelfare, ?true} when is_record(RecWelfare, rec_welfare)	->
			NewTuple	= #welfare_data{type	= Type,
										first	= Condition,
										id		= GiftId,
										state	= ?CONST_WELFARE_UNCLAIMED},
			[NewTuple|WelfareData];
		{?null, _}	->	WelfareData;
		{_, ?false}	->	WelfareData
	end.

reward(Player, RecWelfare) when is_record(RecWelfare, rec_welfare)	->
	case reward_goods(Player, RecWelfare#rec_welfare.goods) of
		{?error, ErrorCode}	->
			{?error, ErrorCode};
		{?ok, Player2, GoodsList}	->
			Info			= Player#player.info,
			UserName		= Info#info.user_name,
			ActivityName	= RecWelfare#rec_welfare.name,
			BindCash		= RecWelfare#rec_welfare.cash_bind,
			FunCash =	fun reward_cash_bind/4,
			% case RecWelfare#rec_welfare.id >= 10013 andalso RecWelfare#rec_welfare.id =< 10018 of
			% 	true ->
			% 		fun reward_cash/4;
			% 	false ->
			% 		fun reward_cash_bind/4
			% end,
			case FunCash(Player2#player.user_id, UserName, ActivityName, BindCash) of
				?ok	->
					case reward_gold(Player2#player.user_id, RecWelfare#rec_welfare.gold) of
						?ok ->
							{?ok, Player3}	= reward_exp(Player2, RecWelfare#rec_welfare.exp),
							{?ok, Player4}	= reward_meritorious(Player3, RecWelfare#rec_welfare.meritorious),
							{?ok, Player5}	= reward_experience(Player4, RecWelfare#rec_welfare.experience),
							{?ok, Player6}	= reward_sp(Player5, RecWelfare#rec_welfare.sp),
							{?ok, Player6, GoodsList};
						{?error, ErrorCode} ->
							{?error, ErrorCode}
					end;
				{?error, ErrorCode}	->
					?MSG_WARNING("ErrorCode=~p", [ErrorCode]),
					{?error, ErrorCode}
			end
	end;
reward(Player, RecPullulation) when is_record(RecPullulation, rec_pullulation)	->
	case reward_goods(Player, RecPullulation#rec_pullulation.goods) of
		{?error, ErrorCode}	->
			?MSG_WARNING("ErrorCode=~p", [ErrorCode]),
			{?error, ErrorCode};
		{?ok, Player2, GoodsList}	->
			Info			= Player#player.info,
			UserName		= Info#info.user_name,
			ActivityName	= <<"Quà trưởng thành">>,
			BindCash		= RecPullulation#rec_pullulation.cash_bind,
			case reward_cash_bind(Player2#player.user_id, UserName, ActivityName, BindCash) of
				?ok	->
					case reward_gold(Player2#player.user_id, RecPullulation#rec_pullulation.gold) of
						?ok	->
							{?ok, Player3}	= reward_exp(Player2, RecPullulation#rec_pullulation.exp),
							{?ok, Player4}	= reward_meritorious(Player3, RecPullulation#rec_pullulation.meritorious),
							{?ok, Player5}	= reward_experience(Player4, RecPullulation#rec_pullulation.experience),
							{?ok, Player6}	= reward_sp(Player5, RecPullulation#rec_pullulation.sp),
							{?ok, Player6, GoodsList};
						{?error, ErrorCode}	->
							{?error, ErrorCode}
					end;
				{?error, ErrorCode}	->
					?MSG_WARNING("ErrorCode=~p", [ErrorCode]),
					{?error, ErrorCode}
			end
	end.

%% 物品奖励
reward_goods(Player, List)	->
	case reward_goods(Player, List, []) of
		{?ok, GoodsList} ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_WELFARE_REWARD_GOLD, 1, 1, 0, 0, 1, 1, []) of
				{?error, ErrorCodeBag}	->
					{?error, ErrorCodeBag};
				{?ok, Player2, _, _PacketBag}	->
					{?ok, Player2, GoodsList}
			end;
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.

reward_goods(Player, [{Pro, Sex, GoodsId, BindState, Count} | List], Acc)	->
	case reward_goods(Player, Pro, Sex, GoodsId, BindState, Count) of
		{?ok, GoodsList}	-> reward_goods(Player, List, (GoodsList ++ Acc));
		{?error, ErrorCode}	-> {?error, ErrorCode}
	end;
reward_goods(_Player, [], Acc)	-> {?ok, Acc}.

reward_goods(Player, Pro, Sex, GoodsId, BindState, Count)	->
	UserId	= Player#player.user_id,
	Info	= Player#player.info,
	if
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)   	  orelse
		(Pro =:= Info#info.pro 	 	 andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= Info#info.pro    	 andalso Sex =:= Info#info.sex)	->
			case goods_api:make(GoodsId, BindState, Count) of
				GoodsList when is_list(GoodsList) ->
					{?ok, GoodsList};
				{?error, ErrorCodeGoods}	->
					PacketGoods2Err = message_api:msg_notice(ErrorCodeGoods),
					misc_packet:send(UserId, PacketGoods2Err),
					{?error, ErrorCodeGoods}
			end;
		?true	->
			{?ok, []}
	end.


%% 游戏币奖励
reward_gold(_UserId, 0)		->	?ok;
reward_gold(UserId, Gold)	->
	case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_WELFARE_REWARD_GOLD) of
		?ok	->
			?ok;
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.

%% 绑定元宝奖励
reward_cash_bind(_UserId, _UserName, _ActivityName, 0)		->	?ok;
reward_cash_bind(UserId, UserName, ActivityName, CashBind)	->
	case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, CashBind, ?CONST_COST_WELFARE_REWARD_CASH) of
		?ok	->
			broadcast(UserName, ActivityName, CashBind);
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.


reward_cash(UserId, UserName, ActivityName, Cash)	->
	case  player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_WELFARE_REWARD_CASH) of
		?ok	->
			% broadcast(UserName, ActivityName, Cash);
			?ok;
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.


%% 军功奖励
reward_meritorious(Player, 0)			->	{?ok, Player};
reward_meritorious(Player, Meritorious)	->	player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_WELFARE_REWARD_MERITORIOUS).

%% 经验奖励
reward_exp(Player, 0)	->	{?ok, Player};
reward_exp(Player, Exp)	->	player_api:exp(Player, Exp).

%% 培养值奖励
reward_experience(Player, 0)			->	{?ok, Player};
reward_experience(Player, Experience)	-> 
	Player2	= player_api:plus_experience(Player, Experience),
	{?ok, Player2}.

%% 体力奖励
reward_sp(Player, 0)	->	{?ok, Player};
reward_sp(Player, Sp)	->	player_api:plus_sp(Player, Sp, ?CONST_COST_WELFARE_REWARD_SP).

%% 更新VIP每日福利礼包
reset_welfare_data(Type, WelfareData) when Type =:= ?CONST_WELFARE_VIP_DAILY	->
	case lists:keyfind(Type, #welfare_data.type, WelfareData) of
		Tuple when is_record(Tuple, welfare_data)	->
			case Tuple#welfare_data.state of
				?CONST_WELFARE_UNFIT		->
					WelfareData;
				?CONST_WELFARE_UNCLAIMED	->
					WelfareData;
				_Other						->
					NewTuple	= Tuple#welfare_data{state = ?CONST_WELFARE_UNCLAIMED},
					lists:keyreplace(Type, #welfare_data.type, WelfareData, NewTuple)
			end;
		_Other	->	WelfareData
	end;
reset_welfare_data(_Type, WelfareData)	->
	WelfareData.

refresh_welfare_data(Type, WelfareData) when is_integer(Type)	->
	case data_welfare:get_welfare({Type}) of
		?null	->	WelfareData;
		GiftId	->
			case check_welfare_gift(GiftId) of
				?true	->	add_welfare_data(Type, GiftId, WelfareData);
				?false	->	WelfareData
			end
	end.
refresh_welfare_data(Type, Condition, WelfareData)
  when Type =:= ?CONST_WELFARE_ACCUM_DEPOSIT
		   orelse Type =:= ?CONST_WELFARE_VIP_LEVEL
		   orelse Type =:= ?CONST_WELFARE_REFIGHT_BATTLEFIELD ->
	%%?MSG_DEBUG("22222222222 Type:~p, data:~p 2222222222222222", [Type, data_welfare:get_welfare({Type, Condition})]),
	case data_welfare:get_welfare({Type, Condition}) of
		?null		->	WelfareData;
		GiftIdList	->	add_welfare_data(Type, GiftIdList, WelfareData)
	end;
refresh_welfare_data(Type, Condition, WelfareData)
  when Type =:= ?CONST_WELFARE_OFFLINE		->
	case data_welfare:get_welfare({Type, Condition}) of
		?null	->	WelfareData;
		GiftId	->
			case check_welfare_gift(GiftId) of
				?true	->	add_welfare_data(Type, GiftId, Condition, WelfareData);
				?false	->	WelfareData
			end
	end;
refresh_welfare_data(Type, Condition, WelfareData)	->
	case data_welfare:get_welfare({Type, Condition}) of
		?null	->	WelfareData;
		GiftId	->
			case check_welfare_gift(GiftId) of
				?true	->	add_welfare_data(Type, GiftId, WelfareData);
				?false	->	WelfareData
			end
	end.

add_welfare_data(Type, [GiftId | GiftIdList], WelfareData)	->
	NewWelfareData	= add_welfare_data(Type, GiftId, WelfareData),
	add_welfare_data(Type, GiftIdList, NewWelfareData);
add_welfare_data(_, [], WelfareData)	->	WelfareData;
add_welfare_data(Type, GiftId, WelfareData) when is_integer(GiftId)	->
	case check_welfare_gift(GiftId) of
		?true	->
			case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
				?false	->	add(Type, GiftId, WelfareData);
				Tuple when is_record(Tuple, welfare_data)
				  andalso Tuple#welfare_data.state =:= ?CONST_WELFARE_UNFIT	->
					NewTuple		= Tuple#welfare_data{state	= ?CONST_WELFARE_UNCLAIMED},
					NewWelfareData	= lists:keyreplace(GiftId, #welfare_data.id, WelfareData, NewTuple),
					next(Type, GiftId, NewWelfareData);
				_Other	->	WelfareData
			end;
		?false	->	WelfareData
	end.
add_welfare_data(Type, GiftId, Condition, WelfareData)	->
	case check_welfare_gift(GiftId) of
		?true	->
			case lists:keyfind(GiftId, #welfare_data.id, WelfareData) of
				?false	->	add(Type, GiftId, Condition, WelfareData);
				Tuple when is_record(Tuple, welfare_data)	->
					NewTuple	= Tuple#welfare_data{first	= Condition,
													 state	= ?CONST_WELFARE_UNCLAIMED},
					lists:keyreplace(GiftId, #welfare_data.id, WelfareData, NewTuple)
			end;
		?false	->	WelfareData
	end.

check_welfare_gift(GiftId) ->
	case data_welfare:get_welfare_info(GiftId) of
		?null		->	?false;
		RecWelfare	->
			Now			= misc:seconds(),
			StartList	= RecWelfare#rec_welfare.activity_start,
			EndList		= RecWelfare#rec_welfare.activity_end,
			interval(Now, StartList, EndList)
	end.

interval(Now, [Start | StartList], [End | EndList]) ->
	StartSeconds	= misc:date_time_to_stamp(Start),
	EndSeconds		= misc:date_time_to_stamp(End),
	case StartSeconds =< Now andalso Now =< EndSeconds of
		?true	->	?true;
		?false	->	interval(Now, StartList, EndList)
	end;
interval(_Now, [], [_])	->	?false;
interval(_Now, [_], [])	->	?false;
interval(_Now, [], [])	->	?false.

%%
%% Local Functions
%%

%% 新手礼包
novice(Player)	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_NOVICE, WelfareData),
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Player#player{welfare = NewWelfare}.

%% 成长礼包
level_up(Player)	->
	Welfare			= Player#player.welfare,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	WelfareData		= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_LEVELUP, Lv, WelfareData),
	NewWelfare		= Welfare#welfare{data = NewWelfareData},
	Packet			= welfare_packet(NewWelfare, ?CONST_WELFARE_LEVELUP, ?CONST_WELFARE_UNCLAIMED, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	Player#player{welfare = NewWelfare}.

%% 再战沙场礼包
refight_battlefield(Player)	->
	Welfare			= Player#player.welfare,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	WelfareData		= Welfare#welfare.data,
%%	?MSG_DEBUG("@@@@@@@@ lv:~p @@@@@@@@", [Lv]),
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_REFIGHT_BATTLEFIELD, Lv, WelfareData),
	NewWelfare		= Welfare#welfare{data = NewWelfareData},
	Packet			= welfare_packet(NewWelfare, ?CONST_WELFARE_REFIGHT_BATTLEFIELD, ?CONST_WELFARE_UNCLAIMED, <<>>),
	misc_packet:send(Player#player.net_pid, Packet),
	Player#player{welfare = NewWelfare}.

%% 媒体礼包
media(Player)	->
	Welfare		= Player#player.welfare,
	WelfareData	= Welfare#welfare.data,
	NewWelfareData	= refresh_welfare_data(?CONST_WELFARE_NOVICE, WelfareData),
	NewWelfare	= Welfare#welfare{data = NewWelfareData},
	Player#player{welfare = NewWelfare}.

add_pullulation(Player, [Pullulation | PullulationList], Packet)	->
	{
	 ?ok, NewPlayer, NewPacket
	}		= add_pullulation(Player, Pullulation, Packet),
	add_pullulation(NewPlayer, PullulationList, NewPacket);
add_pullulation(Player, [], Packet)	->	{?ok, Player, Packet};
add_pullulation(Player, Pullulation, Packet) when is_integer(Pullulation)	->
	Now			= misc:seconds(),
	Tuple		= #pullulation{id	= Pullulation,	flag	= ?true,	time	= Now},
	Flag		= Tuple#pullulation.flag,
	Received	= Tuple#pullulation.received,
	AddPacket	= welfare_api:pack_sc_pullulation([{Pullulation, Flag, Received}]),
	NewPlayer	= add_pullulation(Player, Tuple),
	NewPacket	= <<Packet/binary, AddPacket/binary>>,
	{?ok, NewPlayer, NewPacket}.

add_pullulation(Player, Type, MatchData, Times) when is_integer(Type)	->
	case data_welfare:get_pullulation_list({Type}) of
		?null	->
			{?ok, Player};
		IdList	->
			add_pullulation(Player, IdList, MatchData, Times)
	end;
add_pullulation(Player, [Id | IdList], MatchData, Times)	->
	Welfare		= Player#player.welfare,
	Pullulation	= Welfare#welfare.pullulation,
	NewPlayer	=
		case lists:keyfind(Id, #pullulation.id, Pullulation) of
			Tuple when is_record(Tuple, pullulation)
			  andalso Tuple#pullulation.flag =:= ?true
			  andalso Tuple#pullulation.received =:= ?CONST_WELFARE_UNFIT	->
				case MatchData of
					0	->
						case data_welfare:get_pullulation_info(Id) of
							RecPullulation when is_record(RecPullulation, rec_pullulation)	->
								DelPullulation	= lists:delete(Tuple, Pullulation),
								DelWelfare		= Welfare#welfare{pullulation	= DelPullulation},
								DelPlayer		= Player#player{welfare			= DelWelfare},
								set_pullulation(DelPlayer, Tuple, RecPullulation, Times);
							_Other	->
								Player
						end;
					_MatchData	->
						case data_welfare:get_pullulation_info({Id, MatchData}) of
							RecPullulation when is_record(RecPullulation, rec_pullulation)	->
								DelPullulation	= lists:delete(Tuple, Pullulation),
								DelWelfare		= Welfare#welfare{pullulation	= DelPullulation},
								DelPlayer		= Player#player{welfare			= DelWelfare},
								set_pullulation(DelPlayer, Tuple, RecPullulation, Times);
							_Other	->
								Player
						end
				end;
			_Other	->
				Player
		end,
	add_pullulation(NewPlayer, IdList, MatchData, Times);
add_pullulation(Player, [], _, _)	->
	{?ok, Player}.

add_pullulation(Player, Tuple) when is_record(Tuple, pullulation)	->
	Welfare			= Player#player.welfare,
	Pullulation		= Welfare#welfare.pullulation,
	Id				= Tuple#pullulation.id,
	NewPullulation	= case lists:keyfind(Id, #pullulation.id, Pullulation) of
						  ?false	->	[Tuple | Pullulation];
						  OldTuple when is_record(OldTuple, pullulation)	->
							  Pullulation
					  end,
	NewWelfare		= Welfare#welfare{pullulation	= NewPullulation},
	Player#player{welfare	= NewWelfare}.

set_pullulation(Player, Tuple, RecPullulation, Times) ->
	Now			= misc:seconds(),
	DoneTimes	= Tuple#pullulation.times + Times,
	NeedTimes	= RecPullulation#rec_pullulation.times,
	case DoneTimes >= NeedTimes of
		?true	->
			NewTuple	= Tuple#pullulation{times		= DoneTimes,	time	= Now,
											received	= ?CONST_WELFARE_UNCLAIMED},
			Id			= NewTuple#pullulation.id,
			Flag		= NewTuple#pullulation.flag,
			Received	= NewTuple#pullulation.received,
			Packet		= welfare_api:pack_sc_pullulation([{Id, Flag, Received}]),
			misc_packet:send(Player#player.net_pid, Packet),
			
			add_pullulation(Player, NewTuple);
		?false	->
			NewTuple	= Tuple#pullulation{times	= DoneTimes,	time	= Now},
			add_pullulation(Player, NewTuple)
	end.

%% 领取功成名就奖励
pullulation(Player, Id)	->
	Welfare		= Player#player.welfare,
	Pullulation	= Welfare#welfare.pullulation,
	case lists:keyfind(Id, #pullulation.id, Pullulation) of
		Tuple when is_record(Tuple, pullulation)
		  andalso Tuple#pullulation.flag =:= ?true
		  andalso Tuple#pullulation.received =:= ?CONST_WELFARE_UNFIT		->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_UNFIT),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Tuple when is_record(Tuple, pullulation)
		  andalso Tuple#pullulation.flag =:= ?true
		  andalso Tuple#pullulation.received =:= ?CONST_WELFARE_UNCLAIMED	->
			case data_welfare:get_pullulation_goods(Id) of
				RecPullulation when is_record(RecPullulation, rec_pullulation)	->
					case reward(Player, RecPullulation) of
						{?error, _ErrorCode}			->
							?MSG_WARNING("~n_ErrorCode=~p~n", [_ErrorCode]),
							{?ok, Player};
						{?ok, NewPlayer, _NewGoodsList}	->
							Packet			= welfare_api:pack_sc_receive(Id),
							misc_packet:send(NewPlayer#player.net_pid, Packet),
							NewTuple		= Tuple#pullulation{received	= ?CONST_WELFARE_RECEIVED},
							NewPullulation	= lists:keyreplace(Id, #pullulation.id, Pullulation, NewTuple),
							NewWelfare		= Welfare#welfare{pullulation	= NewPullulation},
							{?ok, NewPlayer#player{welfare	= NewWelfare}}
					end;
				_Other	->
					{?ok, Player}
			end;
		Tuple when is_record(Tuple, pullulation)
		  andalso Tuple#pullulation.flag =:= ?true
		  andalso Tuple#pullulation.received =:= ?CONST_WELFARE_RECEIVED	->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_RECEIVED),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Tuple when is_record(Tuple, pullulation)
		  andalso Tuple#pullulation.flag =:= ?false		->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_NOT_EXIST),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		_Other	->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.
	
broadcast(_UserName, <<"连续在线礼包">>, _)->
    ?ok;
broadcast(_UserName, <<"連續線上禮包">>, _)->
	?ok;
broadcast(_UserName, <<"Quà online liên tục">>, _)->
    ?ok;
broadcast(_UserName, _ActivityName, 0)		->
	?ok;
broadcast(UserName, ActivityName, BindCash)	->
	Current	= misc:seconds(),
    Service = new_serv_api:get_serv_start_time(),
	case misc:get_diff_days(Current, Service) < ?CONST_SYS_NUMBER_SEVEN of
		?true	->
			Packet	= message_api:msg_notice(?TIP_WELFARE_BROADCAST, [{100, UserName}, {100, ActivityName}, {100, misc:to_list(BindCash)}]),
			misc_app:broadcast_world(Packet),
			?ok;
		?false	->
			?ok
	end.