%% author: xjg
%% create: 2014-1-9
%% desc:   encroach_mod
%%


-module(encroach_mod).

%% ====================================================================
%% API functions
%% ====================================================================
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.goods.data.hrl").

-export([
		 gm_set_point/2,
		 gm_rest/1,
		 get_init_info/1,
		 get_rank_info/1,
		 reset_info/1,
		 buy_move_point/2,
		 lottery/1,
		 lottery_broadcast/1,
		 get_award_goods/1,
		 check_can_move/2,
		 get_rest_times/1,
		 
		 moving/2,
		 battle_over/4,
		 refresh/1,
		 login/1,
		 logout/1,
		 rest_rank_data/0,
		 save_rank_data/0,
		 init_rank_data/0
		]).

%% gm设置移动力
gm_set_point(Player, Value) ->
	case get_encroach_info(Player#player.user_id) of
		?null ->
			?ok;
		EncroInfo ->
			update_encroach(EncroInfo#ets_encroach_info{m_force = Value})
	end.

%% gm重置
gm_rest(Player) ->
	case get_encroach_info(Player#player.user_id) of
		?null ->
			?ok;
		EncroInfo ->
			update_encroach(EncroInfo#ets_encroach_info{times = 1, update_time = misc:seconds()})
	end.

%% 获取初始化信息
get_init_info(#player{user_id = UserId}) ->
	EncroInfo =
		case get_encroach_info(UserId) of
			?null ->
				init_info(UserId);
			Tuple when erlang:is_record(Tuple, ets_encroach_info) ->
				Tuple
		end,
	#ets_encroach_info{info_list = InfoList, m_force = MForce, pos = CurPos, exp = Exp, times = Times, total_m_force = Total} = EncroInfo,
	Packet = encroach_api:msg_sc_init_info(InfoList, MForce, CurPos, Exp,
										   erlang:max(?CONST_ENCROACH_TIMES - Times + 1, 0), erlang:max(Total - ?CONST_ENCROACH_MOVING_FORCE, 0)),
	Packet2 = encroach_api:msg_sc_lottery_times(?CONST_SYS_FALSE),
	misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>).

%% 获取排行榜信息
get_rank_info(#player{user_id = UserId}) ->
	List = get_rank_info(),
	F = fun(#encroach_rank{user_id = Id, rank = Rank, user_name = Name, lv = Lv, exp = Exp}, Acc) ->
				[{Id, Rank, Name, Lv, Exp} | Acc]
		end,
	RankList = lists:reverse(lists:foldl(F, [], List)),
	Packet = encroach_api:msg_sc_rank_info(RankList),
	misc_packet:send(UserId, Packet).

%% 重置玩家信息
reset_info(#player{user_id = UserId} = Player) ->
	try
		Result =
			case check_can_reset(UserId) of
				?true ->
					do_over(Player),
					reset(UserId),
					get_init_info(Player),
					?CONST_SYS_TRUE;
				Tips ->
					TipPacket = message_api:msg_notice(Tips),
					misc_packet:send(UserId, TipPacket),
					?CONST_SYS_FALSE
			end,
		Packet = encroach_api:msg_sc_reset(Result),
		misc_packet:send(UserId, Packet)
	catch
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

%% 购买移动力
buy_move_point(Player, Count) ->
	UserId = Player#player.user_id,
	Result = buy_move_force(UserId, Count),
	Packet = encroach_api:msg_sc_buy_point(Result),
	misc_packet:send(Player#player.user_id, Packet).
buy_move_force(UserId, Count) when Count =< ?CONST_SYS_FALSE ->
	TipPacket = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(UserId, TipPacket),
	?CONST_SYS_FALSE;
buy_move_force(UserId, Count) when erlang:is_integer(Count)->
	EncroInfo = get_encroach_info(UserId),
	#ets_encroach_info{m_force = MForce, total_m_force = TotalMForce, times = Times} = EncroInfo,
	case Times > ?CONST_ENCROACH_TIMES of
		?true ->
			TipPacket = message_api:msg_notice(?TIP_ENCROACH_NO_TIMES),
			misc_packet:send(UserId, TipPacket),
			?CONST_SYS_FALSE;
		?false ->
			CanBuyCount = erlang:max(0, ?CONST_ENCROACH_MOVING_FORCE + ?CONST_ENCROACH_CAN_BUY_M_FORCE - TotalMForce),
			BuyCount = erlang:min(CanBuyCount, Count),
			case BuyCount =:= ?CONST_SYS_FALSE of
				?true ->
					TipPacket = message_api:msg_notice(?TIP_ENCROACH_NO_BUY_TIMES),
					misc_packet:send(UserId, TipPacket),
					?CONST_SYS_FALSE;
				?false ->
					Cost = BuyCount * ?CONST_ENCROACH_BUY_M_FORCE_COST,
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_ENCROACH_COST) of
						{?error, ErrorCode} ->
							?MSG_ERROR("buy move force cost error:~p", [ErrorCode]),
							?CONST_SYS_FALSE;
						?ok ->
							NewEncroInfo = EncroInfo#ets_encroach_info{
																	   m_force = MForce + BuyCount,
																	   total_m_force = TotalMForce + BuyCount
																	  },
							update_encroach(NewEncroInfo),
							Packet = encroach_api:msg_sc_rest_point(MForce + BuyCount, erlang:max(0, TotalMForce + BuyCount - ?CONST_ENCROACH_MOVING_FORCE)),
							misc_packet:send(UserId, Packet),
							?CONST_SYS_TRUE
					end
			end
	end.

%% 完成大将事件有机会抽奖
lottery(#player{user_id = UserId, info = Info} = Player) ->
	Lottery	= data_encroach:get_encroach_lottery(),
	#rec_encroach_lottery{idx = Idx, goods_id = GoodsId, num = Num} = rand(Lottery),
	GoodsList = goods_api:make(GoodsId, Num),
	case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_ENCROACH_REWARD, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag} ->
			{Prop, Equip} = detach_goods(GoodsList),
			LotteryPacket1 = 
				case Prop =/= [] of
					?true ->
						message_api:msg_notice(?TIP_ENCROACH_GENERAL_LOTTERY, [{UserId, Info#info.user_name}], Prop, []);
					?false ->
						<<>>
				end,
			LotteryPacket2 =
				case Equip =/= [] of
					?true ->
						message_api:msg_notice(?TIP_ENCROACH_GENERAL_LOTTERY2, [{UserId, Info#info.user_name}], Equip, []);
					?false ->
						<<>>
				end,
			LotteryPacket = <<LotteryPacket1/binary, LotteryPacket2/binary>>,
			EncroInfo = get_encroach_info(UserId),
			Reward = lists:append(EncroInfo#ets_encroach_info.reward, [{GoodsId, Num}]),
			update_encroach(EncroInfo#ets_encroach_info{reward = Reward, lottery_idx = Idx, lottery_packet = LotteryPacket}),
			Packet = encroach_api:msg_sc_target(Idx),
			Packet2 = encroach_api:msg_sc_lottery_times(?CONST_SYS_FALSE),
			misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>),
			{?ok, Player2};
		{?error, ErrorCode}	->
			?MSG_ERROR("add goods error:~p", [ErrorCode]),
			{?ok, Player}
	end.

%% 抽奖广播
lottery_broadcast(#player{user_id = UserId}) ->
	#ets_encroach_info{lottery_idx = LotteryIdx, lottery_packet = LotteryPacket} = get_encroach_info(UserId),
	misc_app:broadcast_world(LotteryPacket),
	Packet = encroach_api:msg_sc_reply(LotteryIdx),
	misc_packet:send(UserId, Packet).

%% 获得物品信息
get_award_goods(#player{user_id = UserId}) ->
	List =
		case get_encroach_info(UserId) of
			?null ->
				[];
			#ets_encroach_info{reward = Reward} ->
				Reward
		end,
	F = fun({GoodsId, Num}, Acc) -> [{GoodsId, Num, is_equip(GoodsId)} | Acc] end,
	List1 = lists:foldl(F, [], List),
	Packet = encroach_api:msg_sc_award_goods(List1),
	misc_packet:send(UserId, Packet).

%% 判断是否是装备
is_equip(GoodsId) ->
	Goods = data_goods:get_goods(GoodsId),
	case Goods#goods.type of
		?CONST_GOODS_TYPE_EQUIP ->
			?CONST_SYS_TRUE;
		_ ->
			?CONST_SYS_FALSE
	end.

%% 初始化玩家信息
init_info(UserId) ->
	RndList = rand_list(),
	EncroachInfo = #ets_encroach_info{
									  user_id		= UserId,
									  pos			= 1,
									  info_list		= RndList,
									  m_force		= ?CONST_ENCROACH_MOVING_FORCE,
									  total_m_force = ?CONST_ENCROACH_MOVING_FORCE,
									  exp			= 0,	
									  reward		= [],
									  times			= 1,
									  update_time	= misc:seconds(),
									  lottery_idx	= 0,
									  lottery_packet= <<>>
									 },
	ets_api:insert(?CONST_ETS_ENCROACH_INFO, EncroachInfo),
	EncroachInfo.

%% 检查是否可以移动
check_can_move(#player{user_id = UserId} = Player, NextPos) ->
	Result =
		case get_encroach_info(UserId) of
			?null ->
				?CONST_SYS_FALSE;
			EncroInfo ->
				case catch check_can_move(Player, EncroInfo, NextPos) of
					{?error, ErrorCode} ->
						TipPacket = message_api:msg_notice(ErrorCode),
						misc_packet:send(UserId, TipPacket),
						?CONST_SYS_FALSE;
					?ok ->
						?CONST_SYS_TRUE
				end
		end,
	Packet = encroach_api:msg_sc_chk_can_mov(Result),
	misc_packet:send(UserId, Packet).

%% 获取剩余次数
get_rest_times(#player{user_id = UserId}) ->
	RestTimes =
		case get_encroach_info(UserId) of
			?null ->
				?CONST_ENCROACH_TIMES;
			EncroInfo ->
				Times = EncroInfo#ets_encroach_info.times,
				erlang:max(?CONST_ENCROACH_TIMES - Times + 1, 0)
		end,
	Packet = encroach_api:msg_sc_rest_times(RestTimes),
	misc_packet:send(UserId, Packet).
			
%% 移动一格
moving(#player{user_id = UserId} = Player, NextPos) ->
	try
		EncroInfo = get_encroach_info(UserId),
		?ok = check_can_move(Player, EncroInfo, NextPos),
		InfoList = EncroInfo#ets_encroach_info.info_list,
		{EventType, State} = get_event_type(InfoList, NextPos),
		{?ok, Player2} =
			case EventType of
				?CONST_ENCROACH_EVENT_INIT ->
					init_event(Player, EncroInfo, NextPos, State);
				?CONST_ENCROACH_EVENT_ARMORY->
					armory_event(Player, EncroInfo, NextPos, State);
				?CONST_ENCROACH_EVENT_GRANARY ->
					granary_event(Player, EncroInfo, NextPos, State);
				?CONST_ENCROACH_EVENT_VETERAN ->
					veteran_event(Player, EncroInfo, NextPos, State);
				?CONST_ENCROACH_EVENT_GENERAL ->
					general_event(Player, EncroInfo, NextPos, State);
				?CONST_ENCROACH_EVENT_CAPITAL ->
					capital_event(Player, EncroInfo, NextPos, State);
				_ ->
					throw({?error, error_event})
			end,
		Packet = encroach_api:msg_sc_move(EventType),
		misc_packet:send(UserId, Packet),
		{?ok, Player2}
	catch
		throw:{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, TipPacket),
			{?ok, Player};
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 检查是否能移动
check_can_move(Player, #ets_encroach_info{pos = Pos, m_force = MForce, times = Times}, NextPos) ->
	case Times > ?CONST_ENCROACH_TIMES of
		?false ->
			?ok;
		?true ->
			throw({?error, ?TIP_ENCROACH_NO_TIMES})
	end,
	case MForce > ?CONST_SYS_FALSE of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_ENCROACH_NOT_ENOUGH_M_FORCE})
	end,
	case lists:member(NextPos, get_next_pos(Pos)) of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_ENCROACH_INVALID_POS})
	end,
	case ctn_bag2_api:is_full(Player#player.bag) of
		?false ->
			?ok;
		?true ->
			throw({?error, ?TIP_ENCROACH_BAG_IS_FULL})
	end.

%% 根据下一格的位置获取事件类型
get_event_type(InfoList, NextPos) ->
	case lists:keyfind(NextPos, 1, InfoList) of
		?false ->
			{?CONST_ENCROACH_EVENT_ERROR, ?CONST_ENCROACH_STATE_CLOSE};
		{NextPos, EventType, State} ->
			{EventType, State}
	end.

%% 返回初始位置
init_event(Player, EncroInfo, NextPos, State) ->
	{NewPlayer, NewEncroInfo} =
		case State of
			?CONST_ENCROACH_STATE_CLOSE ->
				#ets_encroach_info{info_list = InfoList, m_force = MForce} = EncroInfo,
				InfoList = EncroInfo#ets_encroach_info.info_list,
				InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, ?CONST_ENCROACH_EVENT_ARMORY, ?CONST_ENCROACH_STATE_PASS}),
				EncroInfo2 = EncroInfo#ets_encroach_info{
														 pos = NextPos,
														 info_list = InfoList2,
														 m_force = MForce - ?CONST_ENCROACH_MOVE_CONSUME
														 },
				{Player, EncroInfo2};
			_ ->
				{Player, EncroInfo#ets_encroach_info{
													 pos = NextPos,
													 m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
													}
				}
	end,
	update_encroach(NewEncroInfo),
	send_rest_force(Player, NewEncroInfo),
	{?ok, NewPlayer}.

%% 军械库事件 
armory_event(Player, EncroInfo, NextPos, State) ->
	{NewPlayer, NewEncroInfo} =
		case State of
			?CONST_ENCROACH_STATE_CLOSE ->
				Lv = Player#player.info#info.lv,
				EncroachData = get_encroach_data(Lv),
				#rec_encroach{armory_exp = ArmoryExp} = EncroachData,
				{?ok, Player2} = player_api:exp(Player, ArmoryExp),
				TipPacket = message_api:msg_notice(?TIP_ENCROACH_ARMORY_EXP, [], [], 
												   [{?TIP_SYS_COMM, misc:to_list(ArmoryExp)}]),
				misc_packet:send(Player#player.user_id, TipPacket),
				#ets_encroach_info{info_list = InfoList, m_force = MForce, exp = Exp} = EncroInfo,
				InfoList = EncroInfo#ets_encroach_info.info_list,
				InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, ?CONST_ENCROACH_EVENT_ARMORY, ?CONST_ENCROACH_STATE_PASS}),
				EncroInfo2 = EncroInfo#ets_encroach_info{
														 pos = NextPos,
														 info_list = InfoList2,
														 m_force = MForce - ?CONST_ENCROACH_MOVE_CONSUME,
														 exp = Exp + ArmoryExp
														 },
				send_event_reward(Player, ArmoryExp, []),
				{Player2, EncroInfo2};
			_ ->
				{Player, EncroInfo#ets_encroach_info{
													 pos = NextPos,
													 m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
													}
				}
	end,
	update_encroach(NewEncroInfo),
	send_rest_force(Player, NewEncroInfo),
	{?ok, NewPlayer}.

%% 粮仓事件
granary_event(Player, EncroInfo, NextPos, State) ->
	{NewPlayer, NewEncroInfo} =
		case State of
			?CONST_ENCROACH_STATE_CLOSE ->
				Lv = Player#player.info#info.lv,
				EncroachData = get_encroach_data(Lv),
				#rec_encroach{granary_exp = GranaryExp, drop_id = DropId} = EncroachData,
				{?ok, Player2} = player_api:exp(Player, GranaryExp),
				{?ok, Player3, GoodsList} = reward_goods(Player2, DropId),
				List = [{G#goods.goods_id, G#goods.count} || G <- GoodsList],
				TipPacket =
					case List =:= [] of
						?true ->
							message_api:msg_notice(?TIP_ENCROACH_GRANARY_EXP, [], [], 
												   [{?TIP_SYS_COMM, misc:to_list(GranaryExp)}]);
						?false ->
							{Prop, Equip} = detach_goods(GoodsList),
							TipPacket1 =
								case Prop =/= [] of
									?true ->
										message_api:msg_notice(?TIP_ENCROACH_GRANARY_EXP_GOODS, [], Prop,
															   [{?TIP_SYS_COMM, misc:to_list(GranaryExp)}]);
									?false ->
										<<>>
								end,
							TipPacket2 =
								case Equip =/= [] of
									?true ->
										message_api:msg_notice(?TIP_ENCROACH_GRANARY_EXP_GOODS2, [], Equip,
															   [{?TIP_SYS_COMM, misc:to_list(GranaryExp)}]);
									?false ->
										<<>>
								end,
							<<TipPacket1/binary, TipPacket2/binary>>
					end,
				misc_packet:send(Player#player.user_id, TipPacket),
				#ets_encroach_info{info_list = InfoList, m_force = MForce, reward = Reward, exp = Exp} = EncroInfo,
				InfoList = EncroInfo#ets_encroach_info.info_list,
				InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, ?CONST_ENCROACH_EVENT_GRANARY, ?CONST_ENCROACH_STATE_PASS}),
				EncroInfo2 = EncroInfo#ets_encroach_info{
														 pos = NextPos,
														 info_list = InfoList2,
														 m_force = MForce - ?CONST_ENCROACH_MOVE_CONSUME,
														 reward = lists:append(Reward, List),
														 exp = Exp + GranaryExp
														},
				send_event_reward(Player, GranaryExp, List),
				{Player3, EncroInfo2};
			_ ->
				{Player, EncroInfo#ets_encroach_info{
													 pos = NextPos,
													 m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
													}
				}
		end,
	update_encroach(NewEncroInfo),
	send_rest_force(Player, NewEncroInfo),
	{?ok, NewPlayer}.

%% 精兵事件
veteran_event(Player, EncroInfo, NextPos, State) ->
	{NewPlayer, NewEncroInfo} =
		case State of
			?CONST_ENCROACH_STATE_PASS ->
				{Player, EncroInfo#ets_encroach_info{
											pos = NextPos,
											m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
										   }};
			_ ->
				Lv = Player#player.info#info.lv,
				MapId = Player#player.maps#map_data.cur#map_info.map_id,
				#rec_encroach{veteran = VeteranMonId} = get_encroach_data(Lv),
				Param = #param{battle_type = ?CONST_BATTLE_ENCROACH_VETERAN, map_id = MapId},
				{?ok, Player2} = 
					case battle_api:start(Player, VeteranMonId, Param) of
						{?ok, TmpPlayer} ->
							{?ok, TmpPlayer};
						{?error, ErrorCode} ->
							throw({?error, ErrorCode})
					end,
				{Player2, EncroInfo#ets_encroach_info{next_pos = NextPos}}
		end,
	update_encroach(NewEncroInfo),
	send_rest_force(NewPlayer, NewEncroInfo),
	{?ok, NewPlayer}.

%% 大将事件
general_event(Player, EncroInfo, NextPos, State) ->
	{NewPlayer, NewEncroInfo} =
		case State of
			?CONST_ENCROACH_STATE_PASS ->
				{Player, EncroInfo#ets_encroach_info{
											pos = NextPos,
											m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
										   }};
			_ ->
				Lv = Player#player.info#info.lv,
				MapId = Player#player.maps#map_data.cur#map_info.map_id,
				#rec_encroach{general = GeneralMonId} = get_encroach_data(Lv),
				Param = #param{battle_type = ?CONST_BATTLE_ENCROACH_GENERAL, map_id = MapId},
				{?ok, Player2} = 
					case battle_api:start(Player, GeneralMonId, Param) of
						{?ok, TmpPlayer} ->
							{?ok, TmpPlayer};
						{?error, ErrorCode} ->
							throw({?error, ErrorCode})
					end,
				{Player2, EncroInfo#ets_encroach_info{next_pos = NextPos}}
		end,
	update_encroach(NewEncroInfo),
	send_rest_force(NewPlayer, NewEncroInfo),
	{?ok, NewPlayer}.

%% 都城事件
capital_event(Player, EncroInfo, NextPos, _State) ->
	Lv = Player#player.info#info.lv,
	EncroachData = get_encroach_data(Lv),
	#rec_encroach{capital_exp = CapitalExp} = EncroachData,
	{?ok, Player2} = player_api:exp(Player, CapitalExp),
	TipPacket = message_api:msg_notice(?TIP_ENCROACH_CAPITAL_EXP, [], [], 
									   [{?TIP_SYS_COMM, misc:to_list(CapitalExp)}]),
	misc_packet:send(Player#player.user_id, TipPacket),
	#ets_encroach_info{info_list = InfoList, m_force = MForce, exp = Exp} = EncroInfo,
	InfoList = EncroInfo#ets_encroach_info.info_list,
	InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, ?CONST_ENCROACH_EVENT_CAPITAL, ?CONST_ENCROACH_STATE_PASS}),
	EncroInfo2 = EncroInfo#ets_encroach_info{
											 pos = NextPos,
											 info_list = InfoList2,
											 m_force = MForce - ?CONST_ENCROACH_MOVE_CONSUME,
											 exp = Exp + CapitalExp
											},
	update_encroach(EncroInfo2),
	do_over(Player2),
	reset(Player2#player.user_id),
	get_init_info(Player),
	{?ok, Player2}.

%% 物品奖励
reward_goods(Player, GoodsDrop) when is_record(Player, player) andalso is_integer(GoodsDrop)	->
	GoodsList = goods_api:goods_drop(GoodsDrop),
	reward_goods(Player, GoodsList);
reward_goods(Player, GoodsList) when is_record(Player, player) andalso is_list(GoodsList)	->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_ENCROACH_REWARD, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag} ->
			{?ok, Player2, GoodsList};
		{?error, _ErrorCode}	->
			{?ok, Player, []}
	end;
reward_goods(Player, _)	->	{?ok, Player, []}.

%% 分离装备与非装备
detach_goods(GoodsList) ->
	detach_goods(GoodsList, {[], []}).

detach_goods([#goods{type = Type} = Goods|GoodsList], {Prop, Equip}) ->
	case Type of
		?CONST_GOODS_TYPE_EQUIP ->
			detach_goods(GoodsList, {Prop, [Goods|Equip]});
		_ ->
			detach_goods(GoodsList, {[Goods|Prop], Equip})
	end;
detach_goods([], Acc) ->
	Acc.

%% 战斗结束
battle_over(LeftId, _RightId, WinSide, BattleType) ->
	try
		EventType =
			case BattleType of
				?CONST_BATTLE_ENCROACH_VETERAN ->
					?CONST_ENCROACH_EVENT_VETERAN;
				?CONST_BATTLE_ENCROACH_GENERAL ->
					?CONST_ENCROACH_EVENT_GENERAL
			end,
		case get_encroach_info(LeftId) of
			?null ->
				?ok;
			EncroInfo ->
				#ets_encroach_info{next_pos = NextPos, info_list = InfoList} = EncroInfo,
				NewEncroInfo =
					case WinSide of
						?CONST_BATTLE_RESULT_LEFT ->%% 赢了移动一格并且扣除一点移动力
							InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, EventType, ?CONST_ENCROACH_STATE_PASS}),
							EncroInfo#ets_encroach_info{
														pos = NextPos,
														info_list = InfoList2,
														m_force = EncroInfo#ets_encroach_info.m_force - ?CONST_ENCROACH_MOVE_CONSUME
													   };
						_ ->						%% 输了不移动，不扣除移动力，但地图状态会变成开启
							InfoList2 = lists:keystore(NextPos, 1, InfoList, {NextPos, EventType, ?CONST_ENCROACH_STATE_OPEN}),
							EncroInfo#ets_encroach_info{info_list = InfoList2}
					end,
				Tips =
					case {EventType, WinSide} of
						{?CONST_ENCROACH_EVENT_VETERAN, ?CONST_BATTLE_RESULT_LEFT} ->
							?TIP_ENCROACH_VETERAN_SUCCESS;
						{?CONST_ENCROACH_EVENT_VETERAN, _} ->
							?TIP_ENCROACH_VETERAN_FAIL;
						{?CONST_ENCROACH_EVENT_GENERAL,  ?CONST_BATTLE_RESULT_LEFT} ->
							?TIP_ENCROACH_GENERAL_SUCCESS;
						_ ->
							?TIP_ENCROACH_GENERAL_FAIL
					end,
				TipPacket = message_api:msg_notice(Tips),
				misc_packet:send(LeftId, TipPacket),
				case EventType =:= ?CONST_ENCROACH_EVENT_GENERAL of
					?true ->
						check_general(NewEncroInfo);
					?false ->
						?ignore
				end,
				update_encroach(NewEncroInfo),
				send_rest_force(LeftId, NewEncroInfo)
		end
	catch 
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

%% 检查是否已经完成大将事件
check_general(#ets_encroach_info{user_id = UserId, info_list = InfoList}) ->
	Result = [Pos || {Pos, EventType, State} <- InfoList, EventType =:= ?CONST_ENCROACH_EVENT_GENERAL, State =:= ?CONST_ENCROACH_STATE_PASS],
	case erlang:length(Result) of
		?CONST_ENCROACH_COUNT_GRANARY ->
			%% 完成发协议抽奖
			Packet = encroach_api:msg_sc_lottery_times(?CONST_ENCROACH_LOTTERY_TIMES),
			misc_packet:send(UserId, Packet),
			?ok;
		_ ->
			?ok
	end.

rand(List) ->
	Sum		= lists:sum([R#rec_encroach_lottery.rate || R <- List]),
	?RANDOM_SEED,
	Rand	= misc:rand(1, Sum),
	rand(List, Rand).

rand([#rec_encroach_lottery{rate = R} = Tuple| _List], Rand) when R >= Rand -> Tuple;
rand([#rec_encroach_lottery{rate = R}|List], Rand) ->
	rand(List, Rand - R).
	

%% 游戏结束，结算
do_over(Player) ->
	UserId = Player#player.user_id,
	do_rank(Player),
	#ets_encroach_info{info_list = List, exp = Exp, reward = Reward} = get_encroach_info(UserId),
	F = fun({GoodsId, Num}, Acc) -> [{GoodsId, Num, is_equip(GoodsId)} | Acc] end,
	RewardList = lists:foldl(F, [], Reward),
	F2 = fun({_Pos, ?CONST_ENCROACH_EVENT_ARMORY,  ?CONST_ENCROACH_STATE_PASS}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
				{Acc1 + 1, Acc2, Acc3, Acc4, Acc5};
		   ({_Pos, ?CONST_ENCROACH_EVENT_GRANARY, ?CONST_ENCROACH_STATE_PASS}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
				{Acc1, Acc2 + 1, Acc3, Acc4, Acc5};
		   ({_Pos, ?CONST_ENCROACH_EVENT_CAPITAL, ?CONST_ENCROACH_STATE_PASS}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
				{Acc1, Acc2, Acc3 + 1, Acc4, Acc5};
		   ({_Pos, ?CONST_ENCROACH_EVENT_GENERAL, ?CONST_ENCROACH_STATE_PASS}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
				{Acc1, Acc2, Acc3, Acc4 + 1, Acc5};
		   ({_Pos, ?CONST_ENCROACH_EVENT_VETERAN, ?CONST_ENCROACH_STATE_PASS}, {Acc1, Acc2, Acc3, Acc4, Acc5}) ->
				{Acc1, Acc2, Acc3, Acc4, Acc5 + 1};
		   (_, Acc) ->
				Acc
		end,
	{A1, A2, A3, A4, A5} = lists:foldl(F2, {0,0,0,0,0}, List),
	List2 = [{?CONST_ENCROACH_EVENT_ARMORY,  A1, ?CONST_ENCROACH_COUNT_ARMORY},
			 {?CONST_ENCROACH_EVENT_GRANARY, A2, ?CONST_ENCROACH_COUNT_GRANARY},
			 {?CONST_ENCROACH_EVENT_CAPITAL, A3, ?CONST_ENCROACH_COUNT_CAPITAL},
			 {?CONST_ENCROACH_EVENT_GENERAL, A4, ?CONST_ENCROACH_COUNT_GENERAL},
			 {?CONST_ENCROACH_EVENT_VETERAN, A5, ?CONST_ENCROACH_COUNT_VETERAN}],
	Sum = A1 + A2 + A3 + A4 + A5 + 1,
	IsPerfect =
		case Sum >= erlang:length(List) of
			?true ->
				?CONST_SYS_TRUE;
			?false ->
				?CONST_SYS_FALSE
		end,
	Packet = encroach_api:msg_sc_settlement(List2, RewardList, Exp, IsPerfect),
	misc_packet:send(UserId, Packet),
	?ok.

%% 刷新次数
refresh(Player) ->
	refresh(Player, zero).

refresh(#player{user_id = UserId}, Type) ->
	case get_encroach_info(UserId) of
		?null ->
			case Type of
				zero ->
					Packet = encroach_api:msg_sc_rest_times(?CONST_ENCROACH_TIMES),
					misc_packet:send(UserId, Packet);
				_ ->
					?ok
			end;
		EncroInfo ->
			UpdateTime = EncroInfo#ets_encroach_info.update_time,
			Now = misc:seconds(),
			case Type of
				zero ->
					NewEncroInfo = EncroInfo#ets_encroach_info{times = 1, update_time = Now},
					Times = NewEncroInfo#ets_encroach_info.times,
					RestTimes = erlang:max(?CONST_ENCROACH_TIMES - Times + 1, 0),
					Packet = encroach_api:msg_sc_rest_times(RestTimes),
					misc_packet:send(UserId, Packet),
					update_encroach(NewEncroInfo);
				login ->
					case misc:is_same_date(UpdateTime, Now) of
						?false ->
							NewEncroInfo = EncroInfo#ets_encroach_info{times = 1, update_time = Now},
							update_encroach(NewEncroInfo);
						?true ->
							?ok
					end
			end
	end.

%% 检查是否可以重置
check_can_reset(UserId) ->
	case get_encroach_info(UserId) of
		?null ->
			?TIP_ENCROACH_NO_START;
		#ets_encroach_info{times = Times, info_list = InfoList} ->
			case Times > ?CONST_ENCROACH_TIMES of
				?true ->
					?TIP_ENCROACH_NO_TIMES;
				?false ->
					Len = length([State || {_, _, State} <- InfoList, State =/= ?CONST_ENCROACH_STATE_CLOSE ]),
					case Len > 2 of
						?true ->
							?true;
						?false ->
							?TIP_ENCROACH_NO_START
					end
			end
	end.

%% 重置玩家数据
reset(UserId) ->
	#ets_encroach_info{times = Times} = get_encroach_info(UserId),
	EncroInfo = init_info(UserId),
	NewEncroInfo = EncroInfo#ets_encroach_info{times = Times + 1, update_time = misc:seconds()},
	update_encroach(NewEncroInfo),
	NewEncroInfo.

%% 上线
login(#player{user_id = UserId} = Player) ->
	Sql = erlang:list_to_binary(io_lib:format("select `record` from `game_encroach_info` where `user_id` = ~p", [UserId])),
	case mysql_api:select(Sql) of
		{?ok, []} -> 
			?MSG_ERROR("encroach no player data", []),
			?ok;
		{?ok, [[BinRecord]]} ->
			Record = mysql_api:decode(BinRecord),
			update_encroach(Record);
		{?error, ErrorCode} ->
			?MSG_ERROR("ErrorCode:~p", [ErrorCode])
	end,
	refresh(Player, login).

%% 下线
logout(#player{user_id = UserId}) ->
	case get_encroach_info(UserId) of
		?null ->
			?ok;
		EncroInfo ->
			Sql = erlang:list_to_binary(io_lib:format("replace into `game_encroach_info`(`user_id`, `record`) values(~p,~s)",
													  [UserId, mysql_api:encode(EncroInfo)])),
			mysql_api:execute(Sql),
			delete_encroach(UserId)
	end.

%% 排行榜
do_rank(#player{user_id = UserId, info = Info}) ->
	UserName	= Info#info.user_name,
	Lv			= Info#info.lv,
	EncroInfo	= get_encroach_info(UserId),
	Rank		= #encroach_rank{
								 user_id		= UserId,
								 user_name		= UserName,
								 lv				= Lv,
								 exp			= EncroInfo#ets_encroach_info.exp,
								 update_time	= misc:seconds()
								},
	List = lists:keystore(UserId, #encroach_rank.user_id, get_rank_info(), Rank),
	F = fun(#encroach_rank{exp = Exp1, update_time = UpdateTime1}, #encroach_rank{exp = Exp2, update_time = UpdateTime2}) ->
				if
					Exp1 > Exp2 	-> ?true;
					Exp1 =:= Exp2	-> UpdateTime1 < UpdateTime2;
					?true 			-> ?false
				end
		end,
	Data = lists:sublist(lists:sort(F, List), ?CONST_ENCROACH_RANK_COUNT),
	F2 = fun(Tuple, {Acc1, Acc2}) ->
				 {Acc1 + 1, [Tuple#encroach_rank{rank = Acc1}|Acc2]}
		 end,
	{_A1, Data2} = lists:foldl(F2, {1, []}, Data),
	NewEncroRank = #ets_encroach_rank{
									  rank_id 		= 1,
									  data			= lists:reverse(Data2),
									  update_time	= misc:seconds()
									  },
	ets_api:insert(?CONST_ETS_ENCROACH_RANK, NewEncroRank).

%% 获取排行榜数据
get_rank_info() ->
	case ets_api:lookup(?CONST_ETS_ENCROACH_RANK, 1) of
		?null ->
			[];
		#ets_encroach_rank{data = Data, update_time = UpdateTime} ->
			case misc:is_same_date(UpdateTime, misc:seconds()) of
				?true ->
					Data;
				?false ->
					ets_api:delete(?CONST_ETS_ENCROACH_RANK, 1),
					[]
			end
	end.

%% 零点重置排行榜数据
rest_rank_data() ->
	ets:delete_all_objects(?CONST_ETS_ENCROACH_RANK).

%% 保存排行榜数据
save_rank_data() ->
	case ets_api:lookup(?CONST_ETS_ENCROACH_RANK, 1) of
		?null ->
			?ok;
		#ets_encroach_rank{rank_id = RankId, data = Data, update_time = UpdateTime} ->
			Sql = <<"replace into `game_encroach_rank`(`rank_id`, `data`, `update_time`)value('", (misc:to_binary(RankId))/binary,"',",
							(mysql_api:encode(Data))/binary, ",'",(misc:to_binary(UpdateTime))/binary,"');">>,
			mysql_api:execute(Sql)
	end.

%% 加载排行榜数据
init_rank_data() ->
	Sql = <<"select `rank_id`, `data`, `update_time` from `game_encroach_rank` where `rank_id` = 1">>,
	case mysql_api:select(Sql) of
		{?ok, []} ->
			?ok;
		{?ok, [[RankId, BinData, UpdateTime]]} ->
			Data = mysql_api:decode(BinData),
			ets_api:insert(?CONST_ETS_ENCROACH_RANK, #ets_encroach_rank{rank_id = RankId, data = Data, update_time = UpdateTime});
		{?error, ErrorCode} ->
			?MSG_ERROR("ErrorCode:~p", [ErrorCode])
	end.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 发送剩余移动力
send_rest_force(#player{user_id = UserId}, EncroInfo) ->
	send_rest_force(UserId, EncroInfo);
send_rest_force(UserId, #ets_encroach_info{total_m_force = Total, m_force = M}) when erlang:is_integer(UserId) ->
	Packet = encroach_api:msg_sc_rest_point(M, erlang:max(0, Total - ?CONST_ENCROACH_MOVING_FORCE)),
	misc_packet:send(UserId, Packet).

%% 发送触发事件奖励
send_event_reward(#player{user_id = UserId}, Exp, List) ->
	PacketAward = encroach_api:msg_sc_event_reward(Exp, List),
	misc_packet:send(UserId, PacketAward).

%% 获取配置数据
get_encroach_data(Lv) ->
	data_encroach:get_encroach_data(Lv).

%% 获取下一步可移动位置列表
get_next_pos(Pos) ->
	case data_encroach:get_encroach_pos(Pos) of
		#rec_encroach_pos{next_pos = NextPos} ->
			NextPos;
		_ ->
			[]
	end.

get_encroach_info(UserId) ->
	ets_api:lookup(?CONST_ETS_ENCROACH_INFO, UserId).

update_encroach(EncroInfo) ->
	ets_api:insert(?CONST_ETS_ENCROACH_INFO, EncroInfo).

delete_encroach(UserId) ->
	ets_api:delete(?CONST_ETS_ENCROACH_INFO, UserId).

%% 生成随机序列
rand_list() ->
	List = lists:seq(2, 24),
	?RANDOM_SEED,
	PosList = rand_list(List, []) ++ [25],
	TypeList = make_type_list([
							   {?CONST_ENCROACH_EVENT_ARMORY , ?CONST_ENCROACH_COUNT_ARMORY},
							   {?CONST_ENCROACH_EVENT_GRANARY, ?CONST_ENCROACH_COUNT_GRANARY},
							   {?CONST_ENCROACH_EVENT_VETERAN, ?CONST_ENCROACH_COUNT_VETERAN},
							   {?CONST_ENCROACH_EVENT_GENERAL, ?CONST_ENCROACH_COUNT_GENERAL},
							   {?CONST_ENCROACH_EVENT_CAPITAL, ?CONST_ENCROACH_COUNT_CAPITAL}
							  ], []),
	StateList = lists:duplicate(23, ?CONST_ENCROACH_STATE_CLOSE) ++ [?CONST_ENCROACH_STATE_OPEN],
	lists:sort([{1,?CONST_ENCROACH_EVENT_INIT,?CONST_ENCROACH_STATE_PASS}] ++ lists:zip3(PosList, TypeList, StateList)).

rand_list([], Acc) -> Acc;
rand_list(List, Acc) ->
	Len = erlang:length(List),
	N = misc:rand(1, Len),
	Elem = lists:nth(N, List),
	rand_list(lists:delete(Elem, List), [Elem | Acc]).
	
make_type_list([], Acc) -> lists:reverse(lists:flatten(Acc));
make_type_list([{Elem, N} | List], Acc) ->
	make_type_list(List, [lists:duplicate(N, Elem) | Acc]).
