%% Author: Administrator
%% Created: 2012-10-21
%% Description: TODO: Add description to schedule_mod
-module(schedule_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
-include("record.robot.hrl").

%%
%% Exported Functions
%%
-export([login/1, sign_info/1, sign/1, review/1, sort/1, sign_gift_info/1,
		 draw_sign_gift/1, draw_liveness_gift/2,  auto_info/1, auto/3,
		 guide_info/1, liveness/1, liveness_gift_info/1, 
		 add_guide_times/3, get_single_resource/3, get_all_resource/2,
		 get_resource_lookfor/1, add_times/2, refresh_resource_info/0,
		 logout/1, refresh_resource_info1/1]).
%%
%% API Functions
%%
login(Player)	->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_SCHEDULE) of
		?true	->
			Today		= misc:date_num(),
			Schedule	= Player#player.schedule,
			Sign		= Schedule#schedule.sign,
			State		= lists:member(Today, Sign),
			Packet1		= schedule_api:packet_sc_login(State),
			{?ok, Player2} = refresh(Player),
			CalcList	= data_schedule:get_activity_play_list(),
			Packet2		= schedule_api:times_packet(Player2, CalcList, <<>>),
			{Player2, <<Packet1/binary, Packet2/binary>>};
		?false	->	{Player, <<>>}
	end.

refresh(Player)	->
	Schedule		= Player#player.schedule,
	Today			= misc:date_num(),
	Monday			= monday(),
	{_, Month, _}	= misc:date_tuple(),
	DaySchedule		=
		case Schedule#schedule.date of
			0		-> %% 第一次开启每日军情模块
				Schedule#schedule{date			= Today};
			Today	->	%% 是同一天
				Schedule;
			_Today->  %% 第二天刷新
				Schedule#schedule{
								  date			= Today,
								  liveness		= 0,
								  guide			= [],
								  liveness_gift	= [],
								  refit_times		= 0
								 }
		end,
	WeekSchedule	= 
		case Schedule#schedule.date >= Monday of
			?false	->
				SignGift	= DaySchedule#schedule.sign_gift,
				SignGift1	= refresh_sign_gift(?CONST_SCHEDULE_CONTINUOUS, SignGift, []),
				DaySchedule#schedule{cont_times	= 0,
									 sign_gift	= SignGift1};
			?true		->	DaySchedule
		end,
	NewSchedule		=
		case WeekSchedule#schedule.month of
			Month	->
				FirstOfMonth= first_of_month(),
				MinDay		= misc:min(Monday, FirstOfMonth),
				SignList	= WeekSchedule#schedule.sign,
				NewSignList	= refresh_sign(MinDay, SignList, []),
				WeekSchedule#schedule{sign = NewSignList};
			_Month	->
				SignList	= WeekSchedule#schedule.sign,
				NewSignList	= refresh_sign(Monday, SignList, []),
				SignGift2	= WeekSchedule#schedule.sign_gift,
				SignGift3	= refresh_sign_gift(?CONST_SCHEDULE_ACCUMULATIVE, SignGift2, []),
				WeekSchedule#schedule{
									  month			= Month,
									  accum_times	= 0,
									  sign			= NewSignList,
									  sign_gift		= SignGift3
									  %refit_times	= 0
									 }
		end,
	Player2 = Player#player{schedule = NewSchedule},
	{?ok, Player2}.
		

refresh_sign(Monday, [Sign | SignList], Acc) when Sign >= Monday	->
	NewAcc	= [Sign | Acc],
	refresh_sign(Monday, SignList, NewAcc);
refresh_sign(Monday, [Sign | SignList], Acc) when Sign < Monday		->
	refresh_sign(Monday, SignList, Acc);
refresh_sign(_Monday, [], Acc)	->
	lists:sort(Acc).

refresh_sign_gift(?CONST_SCHEDULE_CONTINUOUS, [Gift | GiftList], Acc)	->
	GiftId		= Gift#schedule_gift.id,
	GiftIdList	= data_schedule:get_gift_list(?CONST_SCHEDULE_CONTINUOUS),
	case lists:member(GiftId, GiftIdList) of
		?true	->	refresh_sign_gift(?CONST_SCHEDULE_CONTINUOUS, GiftList, Acc);
		?false	->	refresh_sign_gift(?CONST_SCHEDULE_CONTINUOUS, GiftList, [Gift | Acc])
	end;
refresh_sign_gift(?CONST_SCHEDULE_CONTINUOUS, [], Acc)					->
	Acc;
refresh_sign_gift(?CONST_SCHEDULE_ACCUMULATIVE, [Gift | GiftList], Acc)	->
	GiftId		= Gift#schedule_gift.id,
	GiftIdList	= data_schedule:get_gift_list(?CONST_SCHEDULE_ACCUMULATIVE),
	case lists:member(GiftId, GiftIdList) of
		?true	->	refresh_sign_gift(?CONST_SCHEDULE_ACCUMULATIVE, GiftList, Acc);
		?false	->	refresh_sign_gift(?CONST_SCHEDULE_ACCUMULATIVE, GiftList, [Gift | Acc])
	end;
refresh_sign_gift(?CONST_SCHEDULE_ACCUMULATIVE, [], Acc)				->
	Acc.

monday()	->
	{SecStart, _}	= misc:get_this_week_duringtime(),
	{{Y, M, D}, _}	= misc:seconds_to_localtime(SecStart),
	Y * 10000 + M * 100 + D.

first_of_month()	->
	{Y, M, _D}	= misc:date_tuple(),
	Y * 10000 + M * 100 + 1.

sign_info(#player{user_id = UserId, info = Info, schedule = Schedule} = Player)	->
	{?ok, Player2} 	= refresh(Player),
	SignList	= [{Date} || Date <- Schedule#schedule.sign],
	#schedule{accum_times = AccumTimes, cont_times = ContTimes} = Schedule,
	VipLv = Info#info.vip#vip.lv,
	CanRefitSignTimes = 
		case can_refit(Info, Schedule) of
			?true ->
				ConfigTimes = player_vip_api:get_refit_sign_times(VipLv),
				Times = Schedule#schedule.refit_times,
				erlang:max(0, ConfigTimes - Times);
			?false ->
				0
		end,
	schedule_api:msg_sc_sign_info(UserId, SignList, AccumTimes, ContTimes, CanRefitSignTimes),
	%% 注册当天不允许补签
	case schedule_api:is_reg_date(UserId, misc:seconds()) of
		?true ->
			schedule_api:msg_sc_review_flag(UserId, ?true);
		?false ->
			?ok
	end,
	Player2.

%% 签到
sign(Player) ->
	Today		= misc:date_num(),
	Schedule	= Player#player.schedule,
	case lists:member(Today, Schedule#schedule.sign) of
		?false	->
			SignList = [Today | Schedule#schedule.sign],
			NewSchedule	= Schedule#schedule{sign	= SignList},
			NewPlayer	= Player#player{schedule	= NewSchedule},
			TipPacket = message_api:msg_notice(?TIP_SCHEDULE_SIGN_SUCCESS),
		    misc_packet:send(Player#player.user_id, TipPacket),
			schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_DAILY_LOGIN);
		?true	->
			{?ok, Player}
	end.

%% 补签
review(#player{user_id = UserId, info = Info, schedule = Schedule} = Player) ->
	{_Y, _M, Date}	= misc:date_tuple(),
	Flag			= schedule_api:is_reg_date(UserId, misc:seconds()),
	if
		Date =:= ?CONST_SCHEDULE_ONE	->	%% 每月一号
			Player;
		Flag =:= ?true ->
			Player;
		?true	->
			case can_refit(Info, Schedule) of
				?true ->
					CanRefitList= get_can_refit_list(Schedule),
					FirstNotSign= hd(CanRefitList),
					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST,
													  ?CONST_SCHEDULE_REVIEW_SUM, ?CONST_COST_SCHEDULE_REVIEW) of
						?ok	->
							SignList = [FirstNotSign | Schedule#schedule.sign],
							RefitTimes = Schedule#schedule.refit_times + 1,
							NewSchedule	= Schedule#schedule{sign = SignList, refit_times = RefitTimes},
							TipPacket = message_api:msg_notice(?TIP_SCHEDULE_SIGN_SUCCESS),
							misc_packet:send(Player#player.user_id, TipPacket),
							Player#player{schedule	= NewSchedule};
						{?error, _ErrorCode} ->
							Player
					end;
				?false ->
					Player
			end
	end.

%% 判断是否能补签
can_refit(Info, Schedule) ->
	VipLv = Info#info.vip#vip.lv,
	ConfigTimes = player_vip_api:get_refit_sign_times(VipLv),
	Times = Schedule#schedule.refit_times,
	CanSign = get_can_refit_list(Schedule),
	Len = erlang:length(CanSign),
	case Len > 0 of
		?true ->
			ConfigTimes > Times;
		?false ->
			?false
	end.

%% 获取能补签的天数列表
get_can_refit_list(Schedule) ->
	Sign = Schedule#schedule.sign,
	DateNum = misc:date_num(),
	MonStart = DateNum div 100 * 100 + 1,
	NowList = lists:seq(MonStart, DateNum - 1),
	NowList -- Sign.

sort(Player)	->
	Schedule		= Player#player.schedule,
	SignList		= Schedule#schedule.sign,
	NewSignList		= lists:sort(SignList),
	FirstOfMonth	= first_of_month(),
	AccumList		= accumulative(FirstOfMonth, NewSignList, []),
	AccumTimes		= length(AccumList),
%% 	Monday			= monday(),
	{WeekStartS, WeekEndS} = misc:get_this_week_duringtime(),
	ContTimes	= continuous(WeekStartS, WeekEndS, NewSignList),
	SignGift		= Schedule#schedule.sign_gift,
	ContSignGift	= refresh_gift_info(?CONST_SCHEDULE_CONTINUOUS, ContTimes, SignGift),
	AccumSignGift	= refresh_gift_info(?CONST_SCHEDULE_ACCUMULATIVE, AccumTimes, ContSignGift),
	NewSchedule		= Schedule#schedule{sign		= NewSignList,
										accum_times	= AccumTimes,
										cont_times	= ContTimes,
										sign_gift	= AccumSignGift},
	Player#player{schedule	= NewSchedule}.

refresh_gift_info(Type, Condition, GiftList)	->
%% 	?MSG_WARNING("~nType=~p~nCondition=~p~nGiftList=~p~n",[Type, Condition, GiftList]),
	case data_schedule:get_gift({Type, Condition}) of
		?null	->	GiftList;
		GiftId	->
			case lists:keyfind(GiftId, #schedule_gift.id, GiftList) of
				?false	->
					Gift	= #schedule_gift{id		= GiftId,
											 state	= ?false},
					[Gift | GiftList];
				_Other	->	GiftList
			end
	end.

accumulative(FirstOfMonth, [Src | SrcList], Acc) when Src >= FirstOfMonth	->
	accumulative(FirstOfMonth, SrcList, [Src | Acc]);
accumulative(FirstOfMonth, [Src | SrcList], Acc) when Src < FirstOfMonth	->
	accumulative(FirstOfMonth, SrcList, Acc);
accumulative(_FirstOfMonth, [], Acc)	->	Acc.

%% 获取连续登陆次数
continuous(WeekStartS, WeekEndS, SignList) ->
	NewSignList = real_continuous(WeekStartS, WeekEndS, SignList, []),
	continuous(NewSignList, 0, 0, 0).

real_continuous(WeekStartS, WeekEndS, [Sign | SignList], Acc) ->
	Seconds = date_to_seconds(Sign),
	if Seconds >= WeekStartS andalso Seconds < WeekEndS ->
		   real_continuous(WeekStartS, WeekEndS, SignList, [Sign|Acc]);
	   ?true ->
		   real_continuous(WeekStartS, WeekEndS, SignList, Acc)
	end;
real_continuous(_WeekStartS, _WeekEndS, [], Acc) -> lists:reverse(Acc).

continuous([Src| SrcList], 0, Con, MaxCon)  -> %% 第一天连续积累数加1
	continuous(SrcList, Src, Con + 1, MaxCon);
continuous([Src| SrcList], FrontSrc, Con, MaxCon) ->
	FrontSrcSeconds = date_to_seconds(FrontSrc),
	SrcSeconds = date_to_seconds(Src),
	case FrontSrcSeconds + 24 * 3600 =:= SrcSeconds of %%判断是否连续天
		?true ->
			continuous(SrcList, Src, Con + 1, MaxCon);
		?false ->
			NewMaxCon = misc:max(Con, MaxCon),
			continuous(SrcList, Src, 1, NewMaxCon)
	end;
continuous([], _FrontSrc, Con, MaxCon) -> misc:max(Con, MaxCon).

date_to_seconds(Date) ->
	Y = Date div 10000,
	M = (Date - 10000 * Y) div 100,
	D = (Date - 10000 * Y - 100 * M),
	misc:date_time_to_stamp({Y, M, D, 0, 0, 0}).

sign_gift_info(Player)	->
	UserId		= Player#player.user_id,
	Schedule	= Player#player.schedule,
	SignGift	= Schedule#schedule.sign_gift,
	Fun			= fun(List, AccPacket)	->
						  GiftId	= List#schedule_gift.id,
						  State		= List#schedule_gift.state,
						  Packet	= schedule_api:packet_sc_sign_gift(GiftId, State),
						  <<AccPacket/binary, Packet/binary>>
				  end,
	FinalPacket = lists:foldl(Fun, <<>>, SignGift),
	misc_packet:send(UserId, FinalPacket).

draw_sign_gift(Player)	->
	Schedule	= Player#player.schedule,
	SignGift	= Schedule#schedule.sign_gift,
	draw_sign_gift(Player, SignGift).
draw_sign_gift(Player, [_SignGift = #schedule_gift{state = ?true} | SignGiftList])	->
	draw_sign_gift(Player, SignGiftList);
draw_sign_gift(Player, [SignGift = #schedule_gift{state = ?false} | SignGiftList])	->
	NewPlayer	= draw_sign_gift(Player, SignGift),
	draw_sign_gift(NewPlayer, SignGiftList);
draw_sign_gift(Player, [])	->	Player;
draw_sign_gift(Player, SignGift) when is_record(SignGift, schedule_gift)	->
	Id				= SignGift#schedule_gift.id,
	RecScheduleGift	= data_schedule:get_gift_info(Id),
	case reward(Player, RecScheduleGift) of
		{?ok, NewPlayer, GoodsList}	->
			NewSignGift		= SignGift#schedule_gift{state = ?true},
			Schedule		= NewPlayer#player.schedule,
			SignGiftList	= Schedule#schedule.sign_gift,
			NewSignGiftList	= lists:keyreplace(Id, #schedule_gift.id, SignGiftList, NewSignGift),
			NewSchedule		= Schedule#schedule{sign_gift = NewSignGiftList},
			TipPacket		= schedule_api:msg_goods_reward(GoodsList),
			misc_packet:send(Player#player.user_id, TipPacket),
			NewPlayer#player{schedule = NewSchedule};
		{?error, _ErrorCode}			->
			Player
	end.

draw_liveness_gift(Player, GiftId)	->
	Schedule		= Player#player.schedule,
	LiveNessGift	= Schedule#schedule.liveness_gift,
	case draw_gift(Player, GiftId, LiveNessGift) of
		{?error, not_exist}	->
			{?ok, Player};
		{?error, received}	->
			{?ok, Player};
		{?error, _ErrorCode}	->
			{?ok, Player};
		{?ok, NewPlayer, NewGiftList} ->
			NewSchedule	= Schedule#schedule{liveness_gift = NewGiftList},
			{?ok, NewPlayer#player{schedule	= NewSchedule}}
	end.

draw_gift(Player, GiftId, GiftList) ->
	case lists:keyfind(GiftId, #schedule_gift.id, GiftList) of
		Tuple when is_record(Tuple, schedule_gift)	->
			case Tuple#schedule_gift.state of
				?true	->
					{?error, received};	%% 已经领取
				?false	->
					RecScheduleGift	= data_schedule:get_gift_info(GiftId),
					case reward(Player, RecScheduleGift) of
						{?error, ErrorCode}	->
							{?error, ErrorCode};
						{?ok, NewPlayer, GoodsList}	->
							schedule_api:msg_sc_draw_liveness_gift(NewPlayer#player.user_id, GiftId),
							GiftId		= Tuple#schedule_gift.id,
							NewTuple	= Tuple#schedule_gift{state	= ?true},
							NewGiftList	= lists:keyreplace(GiftId, #schedule_gift.id, GiftList, NewTuple),
							TipPacket		= schedule_api:msg_goods_reward(GoodsList),
							misc_packet:send(Player#player.user_id, TipPacket),
							{?ok, NewPlayer, NewGiftList}
					end
			end;
		_Other	->
			{?error, not_exist}
	end.

reward(Player, RecScheduleGift)	->
	case reward_goods(Player, RecScheduleGift#rec_schedule_gift.type, RecScheduleGift#rec_schedule_gift.goods) of
		{?error, ErrorCode} ->
			{?error, ErrorCode};
		{?ok, Player2, GoodsList} ->
			FunCash = fun reward_cash_bind/2,
			% case lists:member(RecScheduleGift#rec_schedule_gift.id,[10011,10010,10009,10008]) of
			% 	true ->
			% 		fun reward_cash/2;
			% 	false ->
			% 		fun reward_cash_bind/2
			% end,
			case FunCash(Player2#player.user_id, RecScheduleGift#rec_schedule_gift.cash_bind) of
				?ok ->
					case reward_gold(Player2#player.user_id, RecScheduleGift#rec_schedule_gift.gold) of
						?ok ->
							{?ok, Player3} = reward_exp(Player2, RecScheduleGift#rec_schedule_gift.exp),
							{?ok, Player4} = reward_meritorious(Player3, RecScheduleGift#rec_schedule_gift.meritorious),
							{?ok, Player5} = reward_experience(Player4, RecScheduleGift#rec_schedule_gift.experience),
							{?ok, Player5, GoodsList};
						{?error, ErrorCode} ->
							?MSG_ERROR("ErrorCode=~p", [ErrorCode]),
							{?error, ErrorCode}
					end;
				{?error, ErrorCode} ->
					?MSG_ERROR("ErrorCode=~p", [ErrorCode]),
					{?error, ErrorCode}
			end
	end.

%% 物品奖励
reward_goods(Player, Type, List)	->
	reward_goods(Player, Type, List, []).
reward_goods(Player, Type, [{Pro, Sex, GoodsId, BindState, Count} | List], Acc)
  when Type =:= ?CONST_SCHEDULE_CONTINUOUS orelse Type =:= ?CONST_SCHEDULE_ACCUMULATIVE	->
%% 	?MSG_WARNING("~nPro=~p~nSex=~p~nGoodsId=~p~nBindState=~p~nCount=~p~n", [Pro, Sex, GoodsId, BindState, Count]),
	case reward_goods(Player, Pro, Sex, GoodsId, BindState, Count) of
		{?ok, Player2, GoodsList}	->	reward_goods(Player2, Type, List, (GoodsList ++ Acc));
		{?error, _ErrorCode}		->	mail(Player, [{Pro, Sex, GoodsId, BindState, Count} | List])
	end;
reward_goods(Player, Type, [{Pro, Sex, GoodsId, BindState, Count} | List], Acc)
  when Type =:= ?CONST_SCHEDULE_LIVENESS	->
	case reward_goods(Player, Pro, Sex, GoodsId, BindState, Count) of
		{?ok, Player2, GoodsList}	->	reward_goods(Player2, Type, List, (GoodsList ++ Acc));
		{?error, ErrorCode}			->	{?error, ErrorCode}
	end;
reward_goods(Player, _Type, [], Acc)	->	{?ok, Player, Acc}.

reward_goods(Player, Pro, Sex, GoodsId, BindState, Count) ->
	UserId = Player#player.user_id,
	Info = Player#player.info,
	if
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)   	  orelse
		(Pro =:= Info#info.pro 	 	 andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= Info#info.pro    	 andalso Sex =:= Info#info.sex) ->
			case goods_api:make(GoodsId, BindState, Count) of
				GoodsList when is_list(GoodsList) ->
                    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SCHEDULE_REWARD_GOLD, 1, 1, 1, 0, 1, 1, []) of
						{?error, ErrorCodeBag} ->
							{?error, ErrorCodeBag};
						{?ok, Player2, _, _PacketBag} ->
							{?ok, Player2, GoodsList}
					end;
				{?error, ErrorCodeGoods} ->
					PacketGoods2Err = message_api:msg_notice(ErrorCodeGoods),
					misc_packet:send(UserId, PacketGoods2Err),
					{?error, ErrorCodeGoods}
			end;
		?true	->
			{?ok, Player, []}
	end.

%% 游戏币奖励
reward_gold(_UserId, 0) -> ?ok;
reward_gold(UserId, Gold) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_SCHEDULE_REWARD_GOLD) of
		?ok ->
			?ok;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%% 绑定元宝奖励
reward_cash_bind(_UserId, 0) -> ?ok;
reward_cash_bind(UserId, CashBind) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, CashBind, ?CONST_COST_SCHEDULE_REWARD) of
		?ok ->
			?ok;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

reward_cash(_UserId, 0) -> ?ok;
reward_cash(UserId, CashBind) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_CASH, CashBind, ?CONST_COST_SCHEDULE_REWARD) of
		?ok ->
			?ok;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.



%% 军功奖励
reward_meritorious(Player, 0) -> {?ok, Player};
reward_meritorious(Player, Meritorious) -> player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_SCHEDULE_REWARD).

%% 经验奖励
reward_exp(Player, 0) -> {?ok, Player};
reward_exp(Player, Exp) -> player_api:exp(Player, Exp).

%% 培养值奖励
reward_experience(Player, 0) -> {?ok, Player};
reward_experience(Player, Experience) -> 
	Player2 = player_api:plus_experience(Player, Experience),
	{?ok, Player2}.

mail(Player, [{Pro, Sex, GoodsId, BindState, Count} | List])	->
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
%% 	Title		= "签到礼包奖励",
%% 	Content		= "",
	Goods		= mail(Player, [{Pro, Sex, GoodsId, BindState, Count} | List], []),
%% 	?MSG_WARNING("~nUserName=~p~nTitle=~p~nContent=~p~nGoods=~p~n", [UserName, Title, Content, Goods]),
	GoodsIdList = mail_api:get_goods_id(Goods, []),
	Content		= [{GoodsIdList}],
	mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_SIGN_SEND, Content,
									  Goods, 0, 0, 0, ?CONST_COST_SCHEDULE_REWARD),
	{?ok, Player, Goods}.
mail(Player, [{Pro, Sex, GoodsId, BindState, Count} | List], Acc)	->
	Info	= Player#player.info,
	NewAcc	= if
				  (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
				  (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)   	orelse
				  (Pro =:= Info#info.pro 	   andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
				  (Pro =:= Info#info.pro       andalso Sex =:= Info#info.sex)	->
					  goods_api:make(GoodsId, BindState, Count);
				  ?true	->
					  []
			  end,
	mail(Player, List, NewAcc ++ Acc);
mail(_Player, [], Acc)	->	Acc.

%% activity_info(Player) ->
%% 	UserId		= Player#player.user_id,
%% 	Schedule	= Player#player.schedule,
%% 	{?ok, Player2}		= refresh(Player),
%% 	Activity	= Schedule#schedule.activity,
%% 	Fun			= fun(List, AccPacket) ->
%% 						  ActvityId	= List#schedule_activity.id,
%% 						  Times		= List#schedule_activity.times,
%% 						  Auto		= List#schedule_activity.auto,
%% 						  Packet    = schedule_api:packet_sc_activity_info(ActvityId, Times, Auto),
%% 						  <<AccPacket/binary, Packet/binary>>
%% 				  end,
%% 	lists:foreach(Fun, Activity),
%% 	FinalPacket = lists:foldl(Fun, <<>>, Activity),
%% 	misc_packet:send(UserId, FinalPacket),
%% 	Player2.

%% 自动参加活动信息
auto_info(Player) ->
	UserId		= Player#player.user_id,
	{?ok, Player2}		= refresh(Player),
	AutoList1	= party_api:get_auto_list(UserId),
	AutoList2 	= boss_api:get_boss_doll_info(UserId),
	AutoList3 	= spring_api:get_auto(UserId),
	AutoList4	= invasion_api:get_auto(UserId),
	AutoList	= AutoList1 ++ AutoList2 ++ AutoList3 ++ AutoList4,
	Fun			= fun(Id, AccPacket) when Id =/= ?CONST_ACTIVE_WORLD ->
						  Packet = schedule_api:packet_sc_auto(Id, ?true),
						  <<AccPacket/binary, Packet/binary>>
				  end,
	FinalPacket	= lists:foldl(Fun, <<>>, AutoList),
	Packet1		= robot_world_api:auto_info(UserId),
	Packet2		= party_mod:pack_set_doll_data(UserId),
	misc_packet:send(UserId, <<FinalPacket/binary, Packet1/binary, Packet2/binary>>),
	{?ok, Player2}.

auto(Player, ActivityId, {State, _IsEn, _IsReborn, _IsQuickReborn, _Cash} = StateInfo)	->
	case exec_auto(Player, ActivityId, StateInfo) of
		?ok ->
			Packet = schedule_api:packet_sc_auto(ActivityId, State),
			misc_packet:send(Player#player.user_id, Packet),
			schedule_api:set_active_auto(Player, ActivityId, State);
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player}
	end;
auto(Player, ActivityId, State)	->
	case exec_auto(Player, ActivityId, State) of
		?ok ->
			Packet = schedule_api:packet_sc_auto(ActivityId, State),
			misc_packet:send(Player#player.user_id, Packet),
			schedule_api:set_active_auto(Player, ActivityId, State);
		{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{?ok, Player};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player}
	end.

check_boss_doll(Player, Type, ?false = State) ->
	case boss_api:boss_doll(Player, Type, State) of
		?ok ->
            Type2 = robot_boss_api:get_boss_type(Type),
            case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {Type2, Player#player.user_id}) of
                #ets_boss_robot_setting{cash = Cash, bcash_2 = BCash2} ->
                    ets:delete(?CONST_ETS_BOSS_ROBOT_SETTING, {Type2, Player#player.user_id}),
                    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH, Cash, ?CONST_COST_BOSS_ROBOT_RETURN),
                    player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH_BIND_2, BCash2, ?CONST_COST_BOSS_ROBOT_RETURN),
                    TipsPacket = message_api:msg_notice(?TIP_BOSS_RETURN_OK, [{?TIP_SYS_COMM, misc:to_list(Cash+BCash2)}]),
                    misc_packet:send(Player#player.user_id, TipsPacket),
                    ok;
                _ ->
                    ok
            end,
            ?ok;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode})
	end;
check_boss_doll(Player, Type, {?true = State, IsEn, IsReborn, IsQuickReborn, Cash}) ->
	case boss_api:boss_doll(Player, Type, State) of
		?ok -> 
            Type2 = robot_boss_api:get_boss_type(Type),
            BossConfig = data_boss:get_boss_config(),
            case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {Type2, Player#player.user_id}) of
                #ets_boss_robot_setting{} ->
                    ok;
                _ ->
                    case player_money_api:minus_money_sp(Player#player.user_id, ?CONST_SYS_CASH, Cash+BossConfig#rec_boss_config.doll_cash, ?CONST_COST_BOSS_ROBOT) of
                        {_BCashDelta, BCash2Delta, CashDelta} ->
                            robot_boss_api:insert_boss_player(Type2, Player#player.user_id, IsEn, IsReborn, IsQuickReborn, BCash2Delta, CashDelta),
                            Packet = message_api:msg_notice(?TIP_BOSS_HIRE_OK),
                            misc_packet:send(Player#player.user_id, Packet),
                            ?ok;
                        _ ->
                            throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
                    end
            end;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode})
	end;
check_boss_doll(Player, Type, State) ->
	case boss_api:boss_doll(Player, Type, State) of
		?ok -> 
            ?ok;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode})
	end.

%% check_invasion_doll(Player, State) ->
%% 	case invasion_api:invasion_doll(Player, State) of
%% 		?ok -> ?ok;
%% 		{?error,ErrorCode} ->
%% 			throw({?error,ErrorCode})
%% 	end.

%% 活动自动参战
exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS, State) -> %% 妖魔破上午
	try
		?ok = check_boss_doll(Player,?CONST_SCHEDULE_ACTIVITY_EARLY_BOSS,State),
		?ok
	catch
		throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            {?error, ErrorCode}
    end;
exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS, State) -> %% 妖魔破下午
	try
		?ok = check_boss_doll(Player,?CONST_SCHEDULE_ACTIVITY_LATE_BOSS,State),
		?ok = check_boss_doll(Player,?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2,State),
		?ok = check_boss_doll(Player,?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3,State),
		?ok
	catch
		throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            {?error, ErrorCode}
    end;
exec_auto(_Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY, _State) -> %% 军团宴会1
	try
%% 		?ok = party_api:automatic_party(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY, State),
%%  		?ok = party_api:automatic_party(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY, State)
		?ok
	catch
		throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            {?error, ErrorCode}
    end;
exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING, State) -> %% 温泉1
	try
		spring_api:set_auto(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_SPRING, State)
	catch
		throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            {?error, ErrorCode}
    end;
exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_SPRING, State) -> %% 温泉2
	try
		spring_api:set_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_SPRING, State)
	catch
		throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            {?error, ErrorCode}
    end;
%% 
%% exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_INVASION, State) -> %% 异民族 
%% 	try
%% 		?MSG_DEBUG("exec_auto_invasion:~p",[State]),
%% 		?ok = check_invasion_doll(Player, State)
%% 	catch
%% 		throw:{?error, ErrorCode} ->
%%             {?error, ErrorCode};
%%         _:_ ->
%%             ErrorCode = ?TIP_COMMON_BAD_ARG,
%%             {?error, ErrorCode}
%%     end;
%% exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS, State) -> %% 妖魔破2
%% 	boss_api:boss_doll(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS, State);

exec_auto(_Player, ?CONST_SCHEDULE_ACTIVITY_FACTION, _State) -> %% 大演武
	?ok;

%% exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY, State) ->	%% 军团宴会2
%% 	party_api:automatic_party(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY, State);

%% exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2, State) -> %% 妖魔破3
%% 	boss_api:boss_doll(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2, State);
%% 
%% exec_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3, State) -> %% 妖魔破4
%% 	boss_api:boss_doll(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3, State);

exec_auto(_Player, _ActivityId, _State) ->
	?ok.

guide_info(Player) ->
	UserId		= Player#player.user_id,
	Schedule	= Player#player.schedule,
	{?ok, Player2} 	= refresh(Player),
	Guide		= Schedule#schedule.guide,
	Fun			= fun(Data, AccPacket) ->
						  Date		= Data#schedule_activity.date,
						  GuideId	= Data#schedule_activity.id,
						  Times		= Data#schedule_activity.times,
						  Packet    = schedule_api:packet_sc_guide_info(Date, GuideId, Times),
						  <<AccPacket/binary, Packet/binary>>
				  end,
	FinalPacket		= lists:foldl(Fun, <<>>, Guide),
	misc_packet:send(UserId, FinalPacket),
	Player2.

liveness(Player) ->
	UserId		= Player#player.user_id,
	Schedule	= Player#player.schedule,
	Liveness	= Schedule#schedule.liveness,
	schedule_api:msg_sc_liveness(UserId, Liveness).

liveness_gift_info(Player) ->
	UserId			= Player#player.user_id,
	Schedule		= Player#player.schedule,
	LivenessGift	= Schedule#schedule.liveness_gift,
	Fun				= fun(List, AccPacket) ->
							  GiftId	= List#schedule_gift.id,
							  State		= List#schedule_gift.state,
							  Packet	= schedule_api:packet_sc_liveness_gift(GiftId, State),
							  <<AccPacket/binary, Packet/binary>>
					  end,
	FinalPacket		= lists:foldl(Fun, <<>>, LivenessGift),
	misc_packet:send(UserId, FinalPacket).


add_guide_times(Player, GuideId, Times) when is_integer(GuideId) ->
	case data_schedule:get_guide_info(GuideId) of
		RecGuide when is_record(RecGuide, rec_guide)	->
			add_guide_times(Player, RecGuide, Times);
		_Other	->	{?ok, Player}
	end;
add_guide_times(Player, RecGuide, Times) when is_record(RecGuide, rec_guide) ->
	Schedule	= Player#player.schedule,
	Guide		= Schedule#schedule.guide,
	GuideId		= RecGuide#rec_guide.id,
	case lists:keyfind(GuideId, #schedule_activity.id, Guide) of
		Tuple when is_record(Tuple, schedule_activity)	->
			replace_guide_times(Player, Tuple, RecGuide, Times);
		_Other	->
			insert_guide_times(Player, RecGuide, Times)
	end;
add_guide_times(Player, _, _)	->	{?ok, Player}.

insert_guide_times(Player, RecGuide, Times)
  when is_record(RecGuide, rec_guide) andalso Times >= 0	->
	Schedule	= Player#player.schedule,
	Guide		= Schedule#schedule.guide,
	GuideId		= RecGuide#rec_guide.id,
	Today		= misc:date_num(),
	NewTuple	= #schedule_activity{type	= ?CONST_SCHEDULE_GUIDE,
									 id		= GuideId,
									 date	= Today,
									 times	= Times},
	NewGuide	= [NewTuple | Guide],
	OldLiveness	= Schedule#schedule.liveness,
	AddLiveness	= case Times >= RecGuide#rec_guide.times of
					  ?true		->	RecGuide#rec_guide.liveness;
					  ?false	->	0
				  end,
	NewLiveness	= OldLiveness + AddLiveness,
	schedule_api:msg_sc_liveness(Player#player.user_id, NewLiveness),
	LivenessGift	= refresh_gift_info(?CONST_SCHEDULE_LIVENESS, NewLiveness, Schedule#schedule.liveness_gift),
	NewSchedule	= Schedule#schedule{liveness		= NewLiveness,
									guide			= NewGuide,
									liveness_gift	= LivenessGift},
%% 	?MSG_WARNING("~nNewTuple=~p~nOldLiveness=~p~nNewLiveness=~p~nNewSchedule=~p~n",
%% 				 [NewTuple, OldLiveness, NewLiveness, NewSchedule]),
	Packet		= schedule_api:packet_sc_guide_info(Today, GuideId, Times),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player#player{schedule	= NewSchedule}};
insert_guide_times(Player, _RecGuide, _Times)	->
	{?ok, Player}.

replace_guide_times(Player, Tuple, RecGuide, Times)
  when is_record(Tuple, schedule_activity) andalso is_record(RecGuide, rec_guide) andalso Times >= 0	->
	Schedule	= Player#player.schedule,
	Guide		= Schedule#schedule.guide,
	GuideId		= RecGuide#rec_guide.id,
	case Tuple#schedule_activity.times >= RecGuide#rec_guide.times of
				?true	->	{?ok, Player};
				?false	->
					case Tuple#schedule_activity.times + Times >= RecGuide#rec_guide.times of
						?true	->
							NewTuple	= Tuple#schedule_activity{times	= RecGuide#rec_guide.times},
							NewGuide	= lists:keyreplace(GuideId, #schedule_activity.id, Guide, NewTuple),
							OldLiveness	= Schedule#schedule.liveness,
							AddLiveness	= RecGuide#rec_guide.liveness,
							NewLiveness	= OldLiveness + AddLiveness,
							schedule_api:msg_sc_liveness(Player#player.user_id, NewLiveness),
							LivenessGift	= refresh_gift_info(?CONST_SCHEDULE_LIVENESS, NewLiveness, Schedule#schedule.liveness_gift),
							NewSchedule	= Schedule#schedule{liveness		= NewLiveness,
															guide			= NewGuide,
															liveness_gift	= LivenessGift},
							Packet		= schedule_api:packet_sc_guide_info(NewTuple#schedule_activity.date, GuideId, NewTuple#schedule_activity.times),
							misc_packet:send(Player#player.user_id, Packet),
							{?ok, Player#player{schedule	= NewSchedule}};
						?false	->
							NewTimes	= Tuple#schedule_activity.times + Times,
							NewTuple	= Tuple#schedule_activity{times	= NewTimes},
							NewGuide	= lists:keyreplace(GuideId, #schedule_activity.id, Guide, NewTuple),
							NewSchedule	= Schedule#schedule{guide			= NewGuide},
							Packet		= schedule_api:packet_sc_guide_info(NewTuple#schedule_activity.date, GuideId, NewTimes),
							misc_packet:send(Player#player.user_id, Packet),
							{?ok, Player#player{schedule	= NewSchedule}}
					end
			end;
replace_guide_times(Player, _Tuple, _RecGuide, _Times)	->
	{?ok, Player}.

%% ------------------------------------------------------------------------------------------------
%% 修改各行为信息
%% ------------------------------------------------------------------------------------------------
add_times(UserId, Id) ->
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, UserId) of
		?null -> ?true;
		Resource ->
			Today			= Resource#resource_lookfor.today,
			List			= Today#resource_info.list,
			case lists:keyfind(Id, 1, List) of
				{Id, Num, Flag} ->
					NewList			= case Num - 1 =< 0 of
										  ?true  -> lists:keyreplace(Id, 1, List, {Id, 0, Flag});
										  ?false -> lists:keyreplace(Id, 1, List, {Id, Num - 1, Flag})
									  end,
					NewToday		= Today#resource_info{list = NewList},
					NewResource		= Resource#resource_lookfor{today = NewToday},
					ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource);
				_ -> ?true
			end
	end.

%% ------------------------------------------------------------------------------------------------
%% 请求资源找回信息
%% ------------------------------------------------------------------------------------------------
get_resource_lookfor(Player) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	Vip				= (Player#player.info)#info.vip,
	VipLv			= Vip#vip.lv,
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, UserId) of
		?null -> 
			Packet				= schedule_api:msg_sc_resource_lookfor([]),
			misc_packet:send(Player#player.net_pid, Packet);
		Resource ->
			Yesterday			= Resource#resource_lookfor.yesterday,
			List				= Yesterday#resource_info.list,
			F	= fun({Id, Num, Flag}, Acc) ->
						  MaxTime		= practice_mod:get_max_time(Lv, VipLv),
						  LeftNum		= case Id =/= 10 of
											  ?true  -> Num;
											  ?false -> misc:ceil((MaxTime - Num)/60)
										  end,
						  LeftNum1		= case LeftNum > 0 of
											  ?true  -> LeftNum;
											  ?false -> 0
										  end,
						  [{Id, LeftNum1, Flag}|Acc];
					 (_, Acc) ->
						  Acc
				  end,
			NewList				= lists:foldl(F, [], List),
			Packet				= schedule_api:msg_sc_resource_lookfor(NewList),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%% ------------------------------------------------------------------------------------------------
%% 对单个类型找回资源
%% ------------------------------------------------------------------------------------------------
get_single_resource(Player, 0, Id) ->   %% 用铜钱找回
	UserId			= Player#player.user_id, 
	Lv				= (Player#player.info)#info.lv,
	try
		Resource		= get_ets_resource(UserId),
		Yesterday		= Resource#resource_lookfor.yesterday,
		List			= Yesterday#resource_info.list,
		Data			= get_base_date(Id),
		case check_resource_open(Player, Data, Id) of
			?ok	-> ?ok;
			{?error, ErrorReason} -> throw({?error, ErrorReason})
		end,
		?ok				= check_resource_flag(List, Id),
%% 		?ok             = check_resource_num(List, Id, Data, Player),
		Num				= cal_left_times(List, Id, Player),
		?ok				= check_gold_enough(UserId, Id, Data, Num),
		Reward			= misc:ceil(cal_reward(Id, Num, Lv)/2),
		NewList			= lists:keyreplace(Id, 1, List, {Id, Num, 1}),
		NewYesday		= Yesterday#resource_info{list = NewList},
		NewResource		= Resource#resource_lookfor{yesterday = NewYesday},
		ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource),
		Packet			= schedule_api:msg_sc_single_resource(Id, 1),
		case Data#rec_resource_back.type of
			0 -> %% 铜钱
				player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Reward, ?CONST_COST_RESOURCE_LOOKFOR),
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_GOLD, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				{?ok, Player};
			1 -> %% 经验
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_EXP, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				player_api:exp(Player, Reward);
			2 -> %%功勋
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_MER, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				player_api:plus_meritorious(Player, Reward, 0)
		end
	catch
		throw:{?error, ErrorCode} ->
            PacketErr			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?ok, Player};
        Other:Reason->
            ?MSG_DEBUG("~n Other=~p, Reason=~p~n", [Other, Reason]),
			{?ok, Player}
    end;
get_single_resource(Player, 1, Id) ->   %% 用元宝找回
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	try
		Resource		= get_ets_resource(UserId),
		Yesterday		= Resource#resource_lookfor.yesterday,
		List			= Yesterday#resource_info.list,
		Data			= get_base_date(Id),
		?ok				= check_resource_flag(List, Id),
		case check_resource_open(Player, Data, Id) of
			?ok	-> ?ok;
			{?error, ErrorReason} -> throw({?error, ErrorReason})
		end,
%% 		?ok             = check_resource_num(List, Id, Data, Player),
		Num				= cal_left_times(List, Id, Player),
		?ok				= check_cash_enough(UserId, Id, Data, Num),
		Reward			= cal_reward(Id, Num, Lv),
		NewList			= lists:keyreplace(Id, 1, List, {Id, Num, 1}),
		NewYesday		= Yesterday#resource_info{list = NewList},
		NewResource		= Resource#resource_lookfor{yesterday = NewYesday},
		ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource),
		Packet			= schedule_api:msg_sc_single_resource(Id, 1),
		case Data#rec_resource_back.type of
			0 -> %% 铜钱
				player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Reward, ?CONST_COST_RESOURCE_LOOKFOR),
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_GOLD, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				{?ok, Player};
			1 -> %% 经验
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_EXP, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				player_api:exp(Player, Reward);
			2 -> %%功勋
				TipPacket			= message_api:msg_notice(?TIP_SCHEDULE_RESOURCE_MER, [{?TIP_SYS_COMM, misc:to_list(Reward)}]),
				misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
				player_api:plus_meritorious(Player, Reward, 0)
		end
	catch
		throw:{?error, ErrorCode} ->
			 PacketErr			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?ok, Player};
		Other:Reason->
            ?MSG_DEBUG("~n Other=~p, Reason=~p~n", [Other, Reason]),
			{?ok, Player}
	end.

%% 检查是否已经找回
check_resource_flag(List, Id) ->
	case lists:keyfind(Id, 1, List) of
		{Id, _Num, Flag} when Flag =:= 0 -> ?ok;
		?false -> throw({?error, ?TIP_SCHEDULE_RESOUCE_ALL_GET});
		_ -> throw({?error, ?TIP_SCHEDULE_RESOURCE_HAS_GET})
	end.

%% 检查是否开启模块
check_resource_open(Player, Data, 4) ->							%% 单独检测宴会
	Guild				= Player#player.guild,
	GuildId				= Guild#guild.guild_id,
	{?ok, GuildLv}	    = guild_api:get_guild_lv(GuildId),
	?MSG_DEBUG("~n GuildLv=~p", [GuildLv]),
	SysId				= Player#player.sys_rank,
	OpenId				= Data#rec_resource_back.module,
	case SysId >= OpenId of
		?true  -> 
			case GuildLv >= 2 of
				?true  -> ?ok;
				?false -> {?error, ?TIP_COMMON_NOT_OPENED_HANDLER}
			end;
		?false -> 
			{?error, ?TIP_COMMON_NOT_OPENED_HANDLER}
			
	end;
check_resource_open(Player, Data, 6) ->							%% 单独检测乱天下
	Guild				= Player#player.guild,
	GuildId				= Guild#guild.guild_id,
	{?ok, GuildLv}	    = guild_api:get_guild_lv(GuildId),
	SysId				= Player#player.sys_rank,
	OpenId				= Data#rec_resource_back.module,
	case SysId >= OpenId of
		?true  -> 
			case GuildLv >= 1 of
				?true  -> ?ok;
				?false -> {?error, ?TIP_COMMON_NOT_OPENED_HANDLER}
			end;
		?false -> 
			{?error, ?TIP_COMMON_NOT_OPENED_HANDLER}
	end;
check_resource_open(Player, Data, _Id) ->
	SysId				= Player#player.sys_rank,
	OpenId				= Data#rec_resource_back.module,
	case SysId >= OpenId of
		?true  -> ?ok;
		?false -> {?error, ?TIP_COMMON_NOT_OPENED_HANDLER}
	end.

%% 检查是否有找回次数
%% check_resource_num(List, 10, _Data, Player) ->
%% 	Lv					= (Player#player.info)#info.lv,
%% 	Vip					= (Player#player.info)#info.vip,
%% 	VipLv				= Vip#vip.lv,
%% 	MaxTime				= practice_mod:get_max_time(Lv, VipLv),
%% 	case lists:keyfind(10, 1, List) of
%% 		{10, Num, _Flag} when Num < MaxTime -> ?ok;
%% 		_ -> throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
%% 	end;
%% check_resource_num(List, Id, Data, _Player) ->
%% 	MaxTimes			= Data#rec_resource_back.max_times,
%% 	case lists:keyfind(Id, 1, List) of
%% 		{Id, Num, _Flag} when Num < MaxTimes -> ?ok;
%% 		_ -> throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
%% 	end.


%% 获取剩余找回次数
cal_left_times(List, 10, Player) ->                         %% 修行单独计算
	Lv					= (Player#player.info)#info.lv,
	Vip					= (Player#player.info)#info.vip,
	VipLv				= Vip#vip.lv,
	case lists:keyfind(10, 1, List) of
		{10, Num, _Flag} -> 
			MaxTime				= practice_mod:get_max_time(Lv, VipLv),
			Left				= misc:ceil((MaxTime - Num)/60),
			case  Left > 0 of
				?true  -> Left;                           %% 剩余分钟数
				?false -> throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
			end;
		_ -> throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
	end;
cal_left_times(List, Id,  _Player) ->
	case lists:keyfind(Id, 1, List) of
		{Id, Num, _Flag} -> 
			case Num > 0 of
				?true  -> Num;
				?false ->throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
			end;
		_ -> throw({?error, ?TIP_SCHEDULE_RESOURCE_NO_TIMES})
	end.

%% 计算获得的资源
cal_reward(_Id, 0, _Lv) -> 0;
cal_reward(1, Num, Lv) -> misc:ceil(Num * 16000 *(0.8 + 0.2 * Lv));
cal_reward(2, Num, Lv) -> misc:ceil(Num * 5000 *(0.4 + 0.6 * Lv));
cal_reward(3, Num, Lv) -> misc:ceil(Num * 1000 *(0.8 + 0.2 * Lv));
cal_reward(4, Num, Lv) -> misc:ceil(Num * 2000 *(0.4 + 0.6 * Lv));
cal_reward(5, Num, _Lv) -> misc:ceil(Num * 500);
cal_reward(6, Num, Lv) -> misc:ceil(Num * 16000 *(0.8 + 0.2 * Lv));
cal_reward(7, Num, Lv) -> misc:ceil(Num * 750 *(0.4 + 0.6 * Lv));
cal_reward(8, Num, _Lv) -> misc:ceil(Num * 250);
cal_reward(9, Num, Lv) -> misc:ceil(Num * 8000 * (0.8 + 0.2 * Lv));
cal_reward(10, Num, Lv) -> misc:ceil((Num /2 ) * practice_mod:get_online_exp(Lv));
cal_reward(_, _Num, _Lv) -> throw({?error, ?TIP_COMMON_BAD_ARG}).


%%检查获取单个铜钱是否足够
check_gold_enough(UserId, 10, Data, Num) ->
	Gold		= Data#rec_resource_back.cost_gold,
	Value		= misc:ceil(Num/2) * Gold,
	case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_RESOURCE_GOLD) of
		?ok -> ?ok;
		{?error, ErrorCode} -> throw({?error, ErrorCode})
	end;
check_gold_enough(UserId, _Id, Data, Num) ->
	Gold		= Data#rec_resource_back.cost_gold,
	Value		= Num * Gold,
	case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_RESOURCE_GOLD) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%%检查获取单个元宝是否足够
check_cash_enough(UserId, 10, Data, Num) ->
	Cash		= Data#rec_resource_back.cost_cash,
	Value		= misc:ceil(Num/2) * Cash,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_RESOURCE_CASH) of
		?ok -> ?ok;
		{?error, ErrorCode} -> throw({?error, ErrorCode})
	end;
check_cash_enough(UserId, _Id, Data, Num) ->
	Cash		= Data#rec_resource_back.cost_cash,
	Value		= Num * Cash,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_RESOURCE_CASH) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
%% ------------------------------------------------------------------------------------------------
%% 对所有类型找回资源
%% ------------------------------------------------------------------------------------------------
get_all_resource(Player, 0) ->			  %% 一键找回
	UserId			= Player#player.user_id,
	try
		Resource		= get_ets_resource(UserId),
		Yesterday		= Resource#resource_lookfor.yesterday,
		YesdayList		= Yesterday#resource_info.list,
		List			= get_resource_list_flag(YesdayList, []),
		List1			= get_resource_open_list(Player, List, []),
		List2			= get_resource_list(List1, Player, []),
		?ok				= check_resource_num1(List2),
		?ok				= check_gold_enough1(UserId, Player, List2),
		{Gold1, Exp1, Mer1}= get_all_reward(List2, Player, 0, 0, 0),
		Gold			= misc:ceil(Gold1/2),
		Exp				= misc:ceil(Exp1/2),
		Mer				= misc:ceil(Mer1/2),
		change_ets_resource(Resource),
		player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_RESOURCE_LOOKFOR),
		{?ok, Player1}  = player_api:exp(Player, Exp),
		{?ok, NewPlayer}= player_api:plus_meritorious(Player1, Mer, 0),
		Packet			= schedule_api:msg_sc_all_resource(1),
		TipPacket		= message_api:msg_notice(?TIP_SCHEDULE_RESOUCE_ALL_REWARD, [{?TIP_SYS_COMM, misc:to_list(Gold)},
												{?TIP_SYS_COMM, misc:to_list(Exp)}, {?TIP_SYS_COMM, misc:to_list(Mer)}]),
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, NewPlayer}
	catch
		throw:{?error, ErrorCode} ->
			PecketErr			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PecketErr),
			{?ok, Player};
		Other:Reason->
            ?MSG_DEBUG("~n Other=~p, Reason=~p~n", [Other, Reason]),
			{?ok, Player}
	end;
get_all_resource(Player, 1) ->			  %% 至尊找回
	UserId			= Player#player.user_id,
	try
		Resource 		= get_ets_resource(UserId),
		Yesterday		= Resource#resource_lookfor.yesterday,
		YesdayList		= Yesterday#resource_info.list,
		List			= get_resource_list_flag(YesdayList, []),
		List1			= get_resource_open_list(Player, List, []),
		List2			= get_resource_list(List1, Player, []),
		?ok				= check_resource_num1(List2),
		?ok				= check_cash_enough1(UserId, Player, List2),
		{Gold, Exp, Mer}= get_all_reward(List2, Player, 0, 0, 0),
		change_ets_resource(Resource),
		player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_RESOURCE_LOOKFOR),
		{?ok, Player1}  = player_api:exp(Player, Exp),
		{?ok, NewPlayer}= player_api:plus_meritorious(Player1, Mer, 0),
		Packet			= schedule_api:msg_sc_all_resource(1),
		TipPacket		= message_api:msg_notice(?TIP_SCHEDULE_RESOUCE_ALL_REWARD, [{?TIP_SYS_COMM, misc:to_list(Gold)},
												{?TIP_SYS_COMM, misc:to_list(Exp)}, {?TIP_SYS_COMM, misc:to_list(Mer)}]),
		misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
		{?ok, NewPlayer}
	catch
		throw:{?error, ErrorCode} ->
			PecketErr			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PecketErr),
			{?ok, Player};
		Other:Reason->
            ?MSG_DEBUG("~n Other=~p, Reason=~p~n", [Other, Reason]),
			{?ok, Player}
	end.

%% 获取开放的资源列表
get_resource_open_list(_Player, [], Acc) -> Acc;
get_resource_open_list(Player, [{Id, Num, Flag}|Tail], Acc) ->
	case data_schedule:get_back_resource(Id) of
		 Data when is_record(Data, rec_resource_back) ->
			 case check_resource_open(Player, Data, Id) of
				 ?ok ->
					 ?MSG_DEBUG("~n Id=~p", [Id]),
					 NewAcc			= [{Id, Num, Flag}|Acc],	
					get_resource_open_list(Player, Tail, NewAcc);
				 _ ->
					get_resource_open_list(Player, Tail, Acc)
			 end;
		_ ->
			get_resource_open_list(Player, Tail, Acc)
	end.

%% 获取能领取的id列表
get_resource_list([], _Player, Acc) -> Acc;
get_resource_list([{Id, Num, Flag}|Tail], Player, Acc) when Id =/= 10 ->
%% 	MaxTimes		= case data_schedule:get_back_resource(Id) of
%% 							Data when is_record(Data, rec_resource_back) ->
%% 								Data#rec_resource_back.max_times;
%% 							_ -> 0
%% 					  end,
	case Num > 0 of
		?true  ->
			NewAcc			= [{Id, Num, Flag}|Acc],
			get_resource_list(Tail, Player, NewAcc);
		?false ->
			get_resource_list(Tail, Player, Acc)
	end;
get_resource_list([{Id, Num, Flag}|Tail], Player, Acc) ->
	Lv					= (Player#player.info)#info.lv,
	Vip					= (Player#player.info)#info.vip,
	VipLv				= Vip#vip.lv,
	MaxTime				= practice_mod:get_max_time(Lv, VipLv),
	case MaxTime > Num of
		?true ->
			NewAcc			= [{Id, Num, Flag}|Acc],
			get_resource_list(Tail, Player, NewAcc);
		?false ->
			get_resource_list(Tail, Player, Acc)
	end.
	
get_resource_list_flag([], Acc) -> Acc;
get_resource_list_flag([{Id, Num, Flag}|Tail], Acc) when Flag =:= 0 ->
	NewAcc			= [{Id, Num, Flag}|Acc],
	get_resource_list_flag(Tail, NewAcc);
get_resource_list_flag([{_Id, _Num, _Flag}|Tail], Acc) ->
	get_resource_list_flag(Tail, Acc).

%% 检查能获取的数量
check_resource_num1(List) when length(List) > 0 -> ?ok;
check_resource_num1(_) -> throw({?error, ?TIP_SCHEDULE_RESOUCE_ALL_GET}).

%% 检查获取所有铜钱是否足够     
check_gold_enough1(UserId, Player, List) ->
	?MSG_DEBUG("~n List=~p", [List]),
	F = fun({Id, Num, _Flag}, Acc) ->
				Value		= cal_cost_gold(Id, Player, Num),
				Value + Acc;
		   (_, Acc) -> 
				Acc
		end,
	Value	= lists:foldl(F, 0, List),
	case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_RESOURCE_GOLD) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 检查获取所有元宝是否足够         
check_cash_enough1(UserId, Player, List) ->
	F = fun({Id, Num, _Flag}, Acc) ->
				Value		= cal_cost_cash(Id, Player, Num),
				Value + Acc;
		   (_, Acc) -> Acc
		end,
	Value	= lists:foldl(F, 0, List),
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_RESOURCE_CASH) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 计算消耗的铜钱
cal_cost_gold(10, Player, Num) ->
	Lv					= (Player#player.info)#info.lv,
	Vip					= (Player#player.info)#info.vip,
	VipLv				= Vip#vip.lv,
	Data				= data_schedule:get_back_resource(10),
	Gold				= Data#rec_resource_back.cost_gold,
	MaxTime				= practice_mod:get_max_time(Lv, VipLv),
	LeftTime			= misc:ceil((MaxTime - Num)/60),
	misc:ceil(LeftTime/2) * Gold;
cal_cost_gold(Id, _Player, Num) ->
	case data_schedule:get_back_resource(Id) of
		Data when is_record(Data, rec_resource_back) ->
			Gold			= Data#rec_resource_back.cost_gold,
			Num * Gold;
		_ -> 0
	end.
	

%% 计算消耗的元宝
cal_cost_cash(10, Player, Num) ->
	Lv					= (Player#player.info)#info.lv,
	Vip					= (Player#player.info)#info.vip,
	VipLv				= Vip#vip.lv,
	Data				= data_schedule:get_back_resource(10),
	Cash				= Data#rec_resource_back.cost_cash,
	MaxTime				= practice_mod:get_max_time(Lv, VipLv),
	LeftTime			= misc:ceil((MaxTime - Num)/60),
	misc:ceil(LeftTime/2) * Cash;
cal_cost_cash(Id, _Player, Num) ->
	case data_schedule:get_back_resource(Id) of
		Data when is_record(Data, rec_resource_back) ->
			Cash			= Data#rec_resource_back.cost_cash,
			Num * Cash;
		_ -> 0
	end.

get_all_reward([], _Player, Acc0, Acc1, Acc2) -> {Acc0, Acc1, Acc2};
get_all_reward([{Id, Num, _Flag}|Tail], Player, Acc0, Acc1, Acc2) ->
	Lv			= (Player#player.info)#info.lv,
	Vip			= (Player#player.info)#info.vip,
	VipLv		= Vip#vip.lv,
	case data_schedule:get_back_resource(Id) of
		Data when is_record(Data, rec_resource_back) ->
			Type			= Data#rec_resource_back.type,
			MaxTime			= practice_mod:get_max_time(Lv, VipLv),
			LefeTimes		= case Id =/= 10 of
								  ?true  -> Num;
								  ?false -> misc:ceil((MaxTime - Num)/60)
							  end,
			Value			= cal_reward(Id, LefeTimes, Lv),
			case Type of
				0 ->  %% 铜钱
					NewAcc0			= Acc0 + Value,
					get_all_reward(Tail, Player, NewAcc0, Acc1, Acc2);
				1 ->  %% 经验
					NewAcc1			= Acc1 + Value,
					get_all_reward(Tail, Player, Acc0, NewAcc1, Acc2);
				2 ->
					NewAcc2			= Acc2 + Value,
					get_all_reward(Tail, Player, Acc0, Acc1, NewAcc2)
			end;
		_ ->
			get_all_reward(Tail, Player, Acc0, Acc1, Acc2)
	end.

%% 获取完所有资源更改ets数据
change_ets_resource(Resource) ->
	Yesterday			= Resource#resource_lookfor.yesterday,
	List				= Yesterday#resource_info.list,
	NewList				= change_ets_resource1(List, List),
	NewYesday			= Yesterday#resource_info{list = NewList},
	NewResource			= Resource#resource_lookfor{yesterday = NewYesday},
	ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource).

change_ets_resource1([], List) -> List;
change_ets_resource1([{Id, Num, _Flag}|Tail], List) ->
	NewList		= lists:keyreplace(Id, 1, List, {Id, Num, 1}),
	change_ets_resource1(Tail, NewList).
	
%% ------------------------------------------------------------------------------------------------
%% 零点
%% ------------------------------------------------------------------------------------------------
refresh_resource_info() ->
	case ets:first(?CONST_ETS_RESOURCE_LOOKFOR) of
		'$end_of_table' -> ?ok;
		Key	->
			refresh_resource_info_ext(Key),
			refresh_resource_info(Key)
	end.

refresh_resource_info(Key) ->
	case ets:next(?CONST_ETS_RESOURCE_LOOKFOR, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			refresh_resource_info_ext(Key1),
			refresh_resource_info(Key1)
	end.

refresh_resource_info_ext(Key) ->
	Date			= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, Key) of
		Resource when is_record(Resource, resource_lookfor) ->
			UserId		= Resource#resource_lookfor.user_id,
			Today		= Resource#resource_lookfor.today,
			TodayList	= Today#resource_info.list,
			Date1		= Today#resource_info.date,
			PracticeTime= practice_api:get_sum_time(UserId),
			TodayList2	= lists:keyreplace(10, 1, TodayList, {10, PracticeTime, 0}),
%% 			Yesterday	= #resource_info{date = Date1, list = TodayList2},
			List		= init_resource_list(1, []),
			
			Time		= misc:date_to_seconds(Date),
			RealSeconds	= Time - 24 * 3600,
			RealDate	= misc:seconds_to_date_num(RealSeconds),
			
			case Date =:= Date1 of
				?true  -> ?ok;
				?false -> 
					Yesterday	= case RealDate of
									  Date1 -> #resource_info{date = Date1, list = TodayList2};
									  _ -> #resource_info{date = RealDate, list = List}
								  end,
					NewResource = Resource#resource_lookfor{yesterday = Yesterday, today = #resource_info{date = Date, list = List}},
					ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource)
			end;
%% 			NewResource = Resource#resource_lookfor{yesterday = Yesterday, today = #resource_info{date = Date, list = List}},
%% 			ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource);
		_  -> ?ok
	end.


%% 上线更新
refresh_resource_info1(Player) ->
	UserId			= Player#player.user_id,
	Date			= misc:date_num(),
	List            = init_resource_list(1, []),
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, UserId) of
		?null -> 
			Yesterday			= misc:encode(#resource_info{}),
			Today				= misc:encode(#resource_info{date = Date, list = List}),
			Resource			= #resource_lookfor{user_id = UserId, today = #resource_info{date = Date, list = List},
													yesterday = #resource_info{}},
			case mysql_api:insert_execute(<<"INSERT INTO `game_resource_lookfor`",
											"(`user_id`, `yesterday`, `today`)",
											"VALUES (",
											" '", (misc:to_binary(UserId))/binary, "',",
											" '", (misc:to_binary(Yesterday))/binary, "',",
											" '", (misc:to_binary(Today))/binary, "');">>) of
				{?ok, _Affect, _Id} ->
					ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, Resource);
				X -> 
					?MSG_ERROR("X=~p", [X]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		Resource ->
			Today		= Resource#resource_lookfor.today,
			TodayList	= Today#resource_info.list,
			DateNum		= Today#resource_info.date,
			Time		= misc:date_to_seconds(Date),
			RealSeconds	= Time - 24 * 3600,
			RealDate	= misc:seconds_to_date_num(RealSeconds),
			case Date =:= DateNum of
				?true  -> ?ok;
				?false -> 
					Yesterday	= case RealDate of
									  DateNum -> #resource_info{date = DateNum, list = TodayList};
									  _ -> #resource_info{date = RealDate, list = List}
								  end,
					NewResource = Resource#resource_lookfor{yesterday = Yesterday, today = #resource_info{date = Date, list = List}},
					ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, NewResource)
			end
	end.

logout(Player) ->
	UserId			= Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, UserId) of
		?null -> ?ok;
		Resource ->
			Yesterday		= Resource#resource_lookfor.yesterday,
			PracticeTime	= practice_api:get_sum_time(UserId),
			Today			= Resource#resource_lookfor.today,
			TodayList		= Today#resource_info.list,
			Today2			= case lists:keyfind(10, 1, TodayList) of
								  {10, _Time, _} ->
									  List = lists:keyreplace(10, 1, TodayList, {10, PracticeTime, 0}),
									  Today#resource_info{list = List};
								  _ ->
									  Today
							  end,
			ets_api:update_element(?CONST_ETS_RESOURCE_LOOKFOR, UserId, [{#resource_lookfor.today, Today2}]),
			mysql_api:update(game_resource_lookfor, [{yesterday, misc:encode(Yesterday)}, {today, misc:encode(Today2)}], 
							 [{user_id, UserId}])
	end.


%% 初始化找回资源列表
init_resource_list(Id, Acc) when Id < 11 ->
	MaxNum			= case data_schedule:get_back_resource(Id) of
						  Data when is_record(Data, rec_resource_back) ->
							  Data#rec_resource_back.max_times;
						  _ -> 0
					  end,
	NewAcc			= [{Id, MaxNum, 0}|Acc],
	init_resource_list(Id + 1, NewAcc);
init_resource_list(_, Acc) -> Acc.
	
%%　获得找回资源的基础数据
get_base_date(Id) ->
	case data_schedule:get_back_resource(Id) of
		Data when is_record(Data, rec_resource_back) -> 
			Data;
		_ -> throw({?error, ?TIP_COMMON_BAD_ARG})
	end.

%% 获得ets的资源数据
get_ets_resource(UserId) ->
	case ets_api:lookup(?CONST_ETS_RESOURCE_LOOKFOR, UserId) of
		?null -> throw({?error, ?TIP_COMMON_SYS_ERROR});
		Resource -> Resource
	end.