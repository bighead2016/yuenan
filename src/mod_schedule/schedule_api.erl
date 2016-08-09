%% Author: Administrator
%% Created: 2012-10-21
%% Description: TODO: Add description to schedule_api
-module(schedule_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([init_player_schedule/0, 
		 init_ets/0,
		 add_resource_times/2,
		 flush_offline/2,
		 login/1,
		 login_packet/2, 
		 logout/1,
		 refresh1/0,
		 refresh/1, times_packet/3, add_guide_times/2,
		 add_guide_times_cb/2, set_active_auto/3, is_reg_date/2,
		 calc_play_times/2, 
         auto/3,
		 msg_sc_play_times/3, 
		 msg_sc_calc_play_times/2,
		 msg_sc_sign_info/5,
		 msg_sc_liveness/2,
		 msg_sc_draw_liveness_gift/2,
		 msg_goods_reward/1,
		 msg_sc_review_flag/2,
         msg_sc_power/3,
		 packet_sc_auto/2,
		 packet_sc_sign_gift/2,
		 packet_sc_activity_info/3,
		 packet_sc_guide_info/3,
		 packet_sc_liveness_gift/2,
		 packet_sc_login/1,
		 packet_sc_play_times/2,
		 msg_sc_resource_lookfor/1,
		 msg_sc_single_resource/2,
		 msg_sc_all_resource/1]).

%%
%% API Functions
%%
init_player_schedule() ->
	#schedule{}.

%% 初始化找回资源ets
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_RESOURCE_LOOKFOR),
	FieldList = [user_id, yesterday, today],
	case mysql_api:select(FieldList, game_resource_lookfor) of
		{?ok, ResourceList} ->
			F = fun([UserId, BinYesterday, BinToday]) ->
						Yesterday		= misc:decode(BinYesterday),
						Today			= misc:decode(BinToday),
						record_resource_lookfor(UserId, Yesterday, Today) 
				end,
			ResourceInfoList = [F(ResourceTemp) || ResourceTemp <- ResourceList],
			ets_insert_list(ResourceInfoList);
		{?error, _ErrorCode} ->
			?ok
	end.

%% 插入到ets
ets_insert_list([Resource|RestList]) ->
	ets_api:insert(?CONST_ETS_RESOURCE_LOOKFOR, Resource),
	ets_insert_list(RestList);
ets_insert_list([]) ->
	?ok.

record_resource_lookfor(UserId, Yesterday, Today) ->
	#resource_lookfor{
					  user_id 	                           = UserId,		        %% 玩家id
					  yesterday							   = Yesterday,				%% 昨日资源
					  today								   = Today					%% 今日资源
					  }.

%% 增加资源次数
add_resource_times(UserId, Id) ->
    catch gun_award_api:check_active(UserId, Id),
	schedule_mod:add_times(UserId, Id).

login(Player) ->
	refresh(Player).

login_packet(Player, Packet)	->
	schedule_mod:refresh_resource_info1(Player),
	{Player2, AddPacket}	= schedule_mod:login(Player),
    {Player3, PowerPacket}  = schedule_power_api:login(Player2),
	{Player3, <<Packet/binary, AddPacket/binary, PowerPacket/binary>>}.

%% 0点刷新
refresh(Player) ->
	try
		{Player2, Packet}	= schedule_mod:login(Player),
		misc_packet:send(Player#player.user_id, Packet),
		{?ok, Player3} = practice_api:add_guide(Player2),
		{?ok, Player3}
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.
%% 0点刷新
refresh1() ->
	try
		schedule_mod:refresh_resource_info()
	catch
		Type:Error ->
			?MSG_ERROR("Type:~p Error:~p Stack:~p", [Type, Error, erlang:get_stacktrace()])
	end.

%% 离线捞数据
flush_offline(Player, #schedule_activity{id = GuideId, type = ?CONST_SCHEDULE_GUIDE, times = Times})->
	add_guide_times(Player, GuideId, Times);
flush_offline(Player, Data) ->
	?MSG_ERROR("schedule flush_offline data=:~p", [Data]),
	{?ok, Player}.

%% 玩法统计次数打包
times_packet(Player, [Type|TypeList], Packet) ->
	Packet1		= calc_play_times(Player, Type),
	Packet2		= <<Packet/binary, Packet1/binary>>,
	times_packet(Player, TypeList, Packet2);
times_packet(_Player, [], Packet) -> Packet.

%% 增加日常引导次数
add_guide_times(UserId, GuideId) when is_integer(UserId) ->
	add_guide_times(UserId, GuideId, 1);
add_guide_times(Player, GuideId) when is_record(Player, player) ->
	add_guide_times(Player, GuideId, 1).

add_guide_times(UserId, GuideId, Times) when is_integer(UserId)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, add_guide_times_cb, [GuideId, Times]);
		_Other	->
			GuideOffLine	= #schedule_activity{type	= ?CONST_SCHEDULE_GUIDE,
												 id		= GuideId,
												 times	= Times},
			player_offline_api:offline(?MODULE, UserId, GuideOffLine)
	end;
add_guide_times(Player, GuideId, Times) when is_record(Player, player) ->
	schedule_mod:add_guide_times(Player, GuideId, Times).

add_guide_times_cb(Player, [GuideId, Times])	->
	add_guide_times(Player, GuideId, Times).

%% 设置自动参加活动的标志
set_active_auto(Player, ActivityId, State) ->
	Schedule	= Player#player.schedule,
	Activity	= Schedule#schedule.activity,
	NewActivity	= case lists:keyfind(ActivityId, #schedule_activity.id, Activity) of
					  Tuple when is_record(Tuple, schedule_activity)	->
						  NewTuple	= Tuple#schedule_activity{auto	= State},
						  lists:keyreplace(ActivityId, #schedule_activity.id, Activity, NewTuple);
					  _Other	->
						  NewTuple	= #schedule_activity{type	= ?CONST_SCHEDULE_ACTIVITY,
														 id		= ActivityId,
														 date	= misc:date_num(),
														 times	= 0,
														 auto	= State},
						  [NewTuple | Activity]
				  end,
	Schedule2	= Schedule#schedule{activity	= NewActivity},
	NewPlayer	= Player#player{schedule	= Schedule2},
	{?ok, NewPlayer}.

%% 判断是否创建当天
is_reg_date(UserId, Seconds) ->
	case player_api:get_reg_time(UserId) of
		{?ok, RegTime} ->
			misc:is_same_date(Seconds, RegTime);
		_Other ->
			?false
	end.

logout(Player) ->
	schedule_mod:logout(Player).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 统计玩法次数 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 普通副本
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_SINGLE_COPY) ->
	Sp    		= (Player#player.info)#info.sp,
	Times 		= Sp div ?CONST_PLAYER_SP_PER_TIME,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_SINGLE_COPY, Times);
% 日常任务
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_CYCLE_TASK) ->
	Times		= task_api:get_task_daily_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_CYCLE_TASK, Times);
% 商路派遣
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_COMMERCE_CARRY) ->
	Times 	    = commerce_api:get_carry_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_COMMERCE_CARRY, Times);
% 一骑讨
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_SINGLE_ARENA) ->
	Times	= single_arena_api:get_single_arena_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_SINGLE_ARENA, Times);
% 封邑侍女互动
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_HOME) ->
	Times		= home_api:get_girl_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_HOME, Times);
% 收夺
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_RESOURCE_RUNE) ->
	VipLv		= player_api:get_vip_lv(Player),
	MaxCnt		= player_vip_api:get_grab_times(VipLv),
	RuneCnt		= (Player#player.resource)#resource.rune_cnt,
	Times		= MaxCnt - RuneCnt,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_RESOURCE_RUNE, Times);
% 军团商路
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_GUILD_COMMERCE) ->
	Times 	    = commerce_api:get_carry_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_GUILD_COMMERCE, Times);
% 战群雄
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_AREA_PVP) ->
	Times		= arena_pvp_api:get_surplus_count(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_AREA_PVP, Times);
% 巡城
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_RESOURCE_PRAY) ->
	Resource	= Player#player.resource,
	PrayCnt		= Resource#resource.pray_cnt,
	Times		= ?CONST_RESOURCE_PRAY_TIMES - PrayCnt,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_RESOURCE_PRAY, Times);

% 团队战场
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_MCOPY) ->
	Times		= mcopy_api:get_multi_copy_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_MCOPY, Times);
% 军团贡献
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_GUILD_DONATE) ->
	Num 		= guild_api:get_surplus_donate_gold(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_GUILD_DONATE, Num);
% 军团任务
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_GUILD_TASK) ->
	Times		= task_api:get_task_guild_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_GUILD_TASK, Times);
% 异民族
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_INVASION) ->
	Invasion	= Player#player.invasion,
	Times		= Invasion#invasion.times,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_INVASION, Times);
% 破阵
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_TOWER) ->
	Times		= tower_api:get_tower_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_TOWER, Times);
% 招贤馆
calc_play_times(_Player, ?CONST_SCHEDULE_PLAY_PARTNER_LOOKFOR) ->
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_PARTNER_LOOKFOR, 0);
% 精英战场
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_ELIT_COPY) ->
	Times		= copy_single_api:get_elite_copy_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_ELIT_COPY, Times);
% 购买体力
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_BUY_SP) ->
	VipLv		= player_api:get_vip_lv(Player),
	SpBuyMax 	= player_vip_api:get_sp_max(VipLv), 
	BuyTimes	= (Player#player.info)#info.sp_buy_times,
	Times		= SpBuyMax - BuyTimes,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_BUY_SP, Times);
% 副将
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_PARTNER_ASSIST) ->
	Lv			= (Player#player.info)#info.lv,
	Pro			= (Player#player.info)#info.pro,
	PlayerLevel	= data_player:get_player_level({Pro, Lv}),
	Num			= PlayerLevel#player_level.assister_max,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_PARTNER_ASSIST, Num);
% 掠阵
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_GROUP) ->
	Num 		= group_api:get_group_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_GROUP, Num);
% 祈天
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_MIND) ->
	PlayerMind 	= Player#player.mind,
	Minds 		= PlayerMind#mind_data.minds,
	FreeTimes	= Minds#mind_info.daily_free_times,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_MIND, FreeTimes);
% 培养
calc_play_times(_Player, ?CONST_SCHEDULE_PLAY_TRAIN) ->
%% 	AttrRate = (Player#player.info)#info.attr_rate,
%% 	Lv = (Player#player.info)#info.lv,
%% 	TrainMax = player_api:get_max_train(AttrRate, Lv),
	Freetrain	= 0,%partner_api:get_free_train_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_TRAIN, Freetrain);
% 修为
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_CULTIVATE) ->
	CurPoint	= (Player#player.info)#info.cultivation,
	CurPhase	= player_cultivation_api:get_cur_phase(CurPoint),
	NextNeedPoint	= 
		case data_player:generate_cultivation_phase_point(CurPhase + 1) of
			Value when is_integer(Value) ->
				Value;
			_Other ->
				100
		end,
	PointNeed	= NextNeedPoint - CurPoint,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_CULTIVATE, PointNeed);
% 商路拦截
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_COMMERCE_ROB) ->
	Times		= commerce_api:get_rob_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_COMMERCE_ROB, Times);
% 荆楚沼泽
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_COLLECT) ->
	Sp    		= (Player#player.info)#info.sp,
	Times 		= Sp div ?CONST_PLAYER_SP_PER_TIME,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_COLLECT, Times);
%收夺免费次数
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_FREE_RUNE) ->
	Resource	= Player#player.resource,
	RuneCnt		= Resource#resource.rune_cnt,
	Times	=
		case RuneCnt > ?CONST_SYS_FALSE of
			?true ->
				?CONST_SYS_FALSE;
			?false ->
				?CONST_SYS_TRUE
		end,
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_FREE_RUNE, Times);
%英雄战场重置次数
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_ELITE_COPY_RESET) ->
	Times		= copy_single_api:get_elite_reset_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_ELITE_COPY_RESET, Times);
%破阵元宝置次数
calc_play_times(Player, ?CONST_SCHEDULE_PLAY_TOWER_CASH_RESET) ->
	Times		= tower_mod:get_tower_vip_times(Player),
	packet_sc_play_times(?CONST_SCHEDULE_PLAY_TOWER_CASH_RESET, Times);
% 如果进这里那是表配错了
calc_play_times(_Player, _Type) ->
%% 	?MSG_ERROR("schedule calc play times:~p", [Type]),
	<<>>.

auto(Player, ?CONST_ACTIVE_WORLD, _State) -> {?ok, Player};
auto(Player, ActivityId, State) ->
    schedule_mod:auto(Player, ActivityId, State).

%% 玩法次数更改时重新计算推送协议
msg_sc_calc_play_times(Player, Type) ->
	Packet		= calc_play_times(Player, Type),
	misc_packet:send(Player#player.user_id, Packet).

%% 玩法次数更改时直接推送
msg_sc_play_times(UserId, Type, Times) ->
	Packet		= packet_sc_play_times(Type, Times),
	misc_packet:send(UserId, Packet).

msg_sc_sign_info(UserId, SignList, AccumTimes, ContTimes, CanRefitSignTimes) ->
%% 	?MSG_DEBUG("~nUserId=~p~nSignList=~p~nAccumTimes=~p~nContTimes=~p~n", [UserId, SignList, AccumTimes, ContTimes]),
	Packet	= misc_packet:pack(?MSG_ID_SCHEDULE_SCSIGNINFO,
							   ?MSG_FORMAT_SCHEDULE_SCSIGNINFO,
							   [SignList, AccumTimes, ContTimes, CanRefitSignTimes]),
	misc_packet:send(UserId, Packet).

msg_sc_liveness(UserId, Liveness) ->
%% 	?MSG_DEBUG("~nUserId=~p~nLiveness=~p~n", [UserId, Liveness]),
	Packet	= misc_packet:pack(?MSG_ID_SCHEDULE_SCLIVENESS,
							   ?MSG_FORMAT_SCHEDULE_SCLIVENESS,
							   [Liveness]),
	misc_packet:send(UserId, Packet).


msg_sc_draw_liveness_gift(UserId, GiftId)	->
%% 	?MSG_DEBUG("~nUserId=~p~nGiftId=~p~n", [UserId, GiftId]),
	Packet	= misc_packet:pack(?MSG_ID_SCHEDULE_SCDRAWLIVENESSGIFT,
							   ?MSG_FORMAT_SCHEDULE_SCDRAWLIVENESSGIFT,
							   [GiftId]),
	misc_packet:send(UserId, Packet).

%% 获得物品提示
msg_goods_reward(GoodsList) ->
	?MSG_DEBUG("msg_goods_reward:~p",[GoodsList]),
	GoodsInfoList	= ctn_bag2_api:cal_same_goods_num(GoodsList, []),
	F	= fun({GoodsId, _GoodsName, GoodsNum}) ->
				  {GoodsId, GoodsNum}
		  end,
	NewAcc  = [F(GoodsInfo )|| GoodsInfo <- GoodsInfoList],
	get_msg_goods_notice(NewAcc, <<>>).

get_msg_goods_notice([{GoodsId, GoodsNum} |GoodsInfo], Acc) ->
	 TipPacket		= message_api:msg_notice(?TIP_SCHEDULE_GOODS_REWARD, [{?TIP_SYS_NOT_EQUIP, misc:to_list(GoodsId)}, 
																	 {?TIP_SYS_COMM, misc:to_list(GoodsNum)}]), 
	 NewAcc			= <<Acc/binary, TipPacket/binary>>,
	get_msg_goods_notice(GoodsInfo, NewAcc);
get_msg_goods_notice([], Acc) ->
	Acc.


msg_sc_review_flag(UserId, Flag) ->
	Packet	= misc_packet:pack(?MSG_ID_SCHEDULE_SC_REVIEW_FLAG,
							   ?MSG_FORMAT_SCHEDULE_SC_REVIEW_FLAG,
							   [Flag]),
	misc_packet:send(UserId, Packet).

packet_sc_auto(Activity, State) ->
%% 	?MSG_DEBUG("~nRes=~p~n", [{Activity, State}]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCAUTO,
				     ?MSG_FORMAT_SCHEDULE_SCAUTO,
				     [Activity, State]).


packet_sc_sign_gift(GiftId, State) ->
%% 	?MSG_DEBUG("~nUserId=~p~nGiftId=~p~nState=~p~n", [UserId, GiftId, State]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCSIGNGIFT,
				     ?MSG_FORMAT_SCHEDULE_SCSIGNGIFT,
				     [GiftId, State]).

packet_sc_activity_info(Id, Times, Auto) ->
%% 	?MSG_DEBUG("~nUserId=~p~nId=~p~nTimes=~p~nAuto=~p~n", [UserId, Id, Times, Auto]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCACTIVITYINFO,
					 ?MSG_FORMAT_SCHEDULE_SCACTIVITYINFO,
					 [Id, Times, Auto]).

packet_sc_guide_info(Date, Id, Times) ->
%% 	?MSG_DEBUG("~nUserId=~p~nDate=~p~nId=~p~nTimes=~p~n", [UserId, Date, Id, Times]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCGUIDEINFO,
					 ?MSG_FORMAT_SCHEDULE_SCGUIDEINFO,
					 [Date, Id, Times]).

packet_sc_liveness_gift(GiftId, State) ->
%% 	?MSG_DEBUG("~nUserId=~p~nGiftId=~p~nState=~p~n", [UserId, GiftId, State]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCLIVENESSGIFT,
					 ?MSG_FORMAT_SCHEDULE_SCLIVENESSGIFT,
					 [GiftId, State]).

packet_sc_login(State) ->
%% 	?MSG_DEBUG("~nState=~p~n", [State]),
	misc_packet:pack(?MSG_ID_SCHEDULE_SCLOGIN,
					 ?MSG_FORMAT_SCHEDULE_SCLOGIN,
					 [State]).

packet_sc_play_times(Type, Times) ->
	misc_packet:pack(?MSG_ID_SCHEDULE_SC_PLAY_TIMES,
					 ?MSG_FORMAT_SCHEDULE_SC_PLAY_TIMES,
					 [Type, Times]).
%% 请求资源找回返回
msg_sc_resource_lookfor(List) ->
	misc_packet:pack(?MSG_ID_SCHEDULE_SC_RESOURCE_LOOKFOR, ?MSG_FORMAT_SCHEDULE_SC_RESOURCE_LOOKFOR, [List]).

%% 请求单个找回返回
msg_sc_single_resource(Id, Result) ->
	misc_packet:pack(?MSG_ID_SCHEDULE_SC_SINGLE_RESOURCE, ?MSG_FORMAT_SCHEDULE_SC_SINGLE_RESOURCE, [Id, Result]).

%% 请求全部找回返回
msg_sc_all_resource(Result) ->
	misc_packet:pack(?MSG_ID_SCHEDULE_SC_ALL_RESOURCE, ?MSG_FORMAT_SCHEDULE_SC_ALL_RESOURCE, [Result]).

%% 战力信息
%%[Type,PartnerId,NewValue]
msg_sc_power(Type,PartnerId,NewValue) ->
    misc_packet:pack(?MSG_ID_SCHEDULE_SC_POWER, ?MSG_FORMAT_SCHEDULE_SC_POWER, [Type,PartnerId,NewValue]).

%%
%% Local Functions
%%

