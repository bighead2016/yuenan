%% 红包活动，同心节活动，猜灯谜活动的api
-module(spirit_festival_activity_api).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").

-export([receive_redbag/3, query_redbag_num/1, get_redbag/1, open_redbag/3, 
		 start_riddle/1, answer_riddle/4, query_riddle_award_info/1]).

-define(DIC_USERS_RIDDLE, dic_users_riddle).

-define(REDBAG_ID, 1050405085).
-define(TXJ_ID, 1050405086).
%% ====================================================================
%% API functions
%% ====================================================================
%% 春节活动得红包
receive_redbag(UserId, Type, Num) ->
	case yunying_activity_mod:check_activity_open(Type) of
		{true, NewStart, NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
				{_, _, Data, Time_S, Time_E} ->
					Now = misc:seconds(),
					if Now >= Time_S andalso Now =< Time_E ->
						   ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},
												  [{2, []}, {3, Data + Num},{4,NewStart},{5,NewEnd}]),
						   Packet = msg_sc_redbag_num(Data + Num),
						   misc_packet:send(UserId, <<Packet/binary>>);
					   true ->
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},
												   [{2, []}, {3, Num}, {4, NewStart}, {5, NewEnd}]),
							Packet = msg_sc_redbag_num(Num),
						    misc_packet:send(UserId, <<Packet/binary>>)
					end;
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId,Type}, [], Num, NewStart, NewEnd}),
					Packet = msg_sc_redbag_num(Num),
					misc_packet:send(UserId, <<Packet/binary>>)
			end;
		_ ->
			skip
	end.

%% 查询未领红包数量
query_redbag_num(UserId) ->
	Num = get_redbag_num(UserId),
	Packet = msg_sc_redbag_num(Num),
	misc_packet:send(UserId, <<Packet/binary>>).

%% 领取红包
get_redbag(Player) ->
	case get_redbag_num(Player#player.user_id) of
		Num when Num > 0 ->
			case ctn_bag2_api:is_full(Player#player.bag) of
				true ->
					misc_packet:send_tips(Player#player.user_id, ?TIP_COMMON_BAG_NOT_ENOUGH);
				false ->		
					GoodsList = goods_api:make(?REDBAG_ID, ?CONST_GOODS_BIND, Num),
            		case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MALL_GET, 1, 1, 0, 0, 0, 1, []) of
						{?ok, Player2, _, Packet} ->
%% 							ets_api:delete(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_RED_BAG}),
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_RED_BAG}, [{3, 0}]),
							Packet1 = msg_sc_redbag_num(0),
							Packet2 = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_GET_REDBAG, 
													   ?MSG_FORMAT_YUNYING_ACTIVITY_SC_GET_REDBAG, []),
							misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, Packet2/binary>>),
							{?ok, Player2};
						{?error, _ErrorCode} ->
							skip,
							?ok
					end
			end;
		_ ->
			MsgPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_NO_REDAB),
            misc_packet:send(Player#player.user_id, MsgPacket),
			?ok
	end.

%% 开红包
open_redbag(Player, ActivityId, Type) ->
	case yunying_activity_mod:check_activity_open(ActivityId) of
		{true, NewStart, NewEnd} ->
			Now = misc:seconds(),
			if NewStart =< Now andalso Now =< NewEnd ->
				   case ActivityId of
					   ?CONST_YUNYING_ACTIVITY_RED_BAG ->
						   open_redbag1(Player, ActivityId, Type);
					   ?CONST_YUNYING_ACTIVITY_TXJ ->
						   %% 与开红包的区别在于，同心结个数不够可用元宝开
						   open_txj(Player, ActivityId, Type);
					   _ ->
						   ?ok
				   end;
			   true ->
				   ?ok
			end;
		_ ->
			?ok
	end.

%% 开始答题
start_riddle(Pid) ->
	Length = data_yunying_activity:get_riddle_length(),
	Ran = misc_random:random(1, Length),
	Riddle = data_yunying_activity:get_riddle(Ran),
	update_user_riddle_id(Riddle#rec_riddle.id),
	Packet = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_INFO, 
							  ?MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_INFO, 
							  [Riddle#rec_riddle.id]),
	misc_packet:send(Pid, Packet).

%% 回答问题
answer_riddle(UserId, UserName, Id, Ans) ->
	case yunying_activity_mod:check_activity_open(?CONST_YUNYING_ACTIVITY_RIDDLE) of
		{true, NewStart, NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_RIDDLE}) of
				{_, InfoList, Data, Time_S, Time_E} ->
					Now = misc:seconds(),
					if Now >= Time_S andalso Now =< Time_E ->
						   case check_answer(Id, Ans) of
							   ?true ->
								   player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, 
															   10000 , ?CONST_COST_ANSWER_RIDDLE),
								   NewInfoList = send_riddle_award(UserId, UserName, InfoList, Data + 1),
								   ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_RIDDLE},
														  [{2, NewInfoList}, {3, Data + 1},{4,NewStart},{5,NewEnd}]),
								   Packet1 = msg_sc_anser_riddle_result(?true),
								   Packet2 = msg_sc_riddle_award_info(NewInfoList, Data + 1),
								   MsgPacket = message_api:msg_notice(?TIP_MAIL_GET_GOLD,
																	  [{?TIP_SYS_COMM, misc:to_list(10000)}]),
								   misc_packet:send(UserId, <<Packet1/binary, Packet2/binary, MsgPacket/binary>>);
							   ?false ->
								   player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, 
															   2000 , ?CONST_COST_ANSWER_RIDDLE),
								   MsgPacket = message_api:msg_notice(?TIP_MAIL_GET_GOLD,
																	  [{?TIP_SYS_COMM, misc:to_list(2000)}]),
								   Packet = msg_sc_anser_riddle_result(?false),
								   misc_packet:send(UserId, <<Packet/binary, MsgPacket/binary>>);
							   timeout ->
								   player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, 
															   2000 , ?CONST_COST_ANSWER_RIDDLE),
								   MsgPacket = message_api:msg_notice(?TIP_MAIL_GET_GOLD,
																	  [{?TIP_SYS_COMM, misc:to_list(2000)}]),
           						   misc_packet:send(UserId, MsgPacket);
							   nomatch ->
								   skip
						   end;
					   true ->
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_RIDDLE},
												   [{2, [?false, ?false, ?false, ?false]}, {3, 0}, {4, NewStart}, {5, NewEnd}])
					end;
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId, ?CONST_YUNYING_ACTIVITY_RIDDLE}, 
															   [?false, ?false, ?false, ?false], 0, NewStart, NewEnd})
			end;
		_ ->
			skip
	end.

%% 查询累计答题奖励信息
query_riddle_award_info(UserId) ->
	case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_RIDDLE}) of
		{_, InfoList, Data, _Time_S, _Time_E} ->
			Packet = msg_sc_riddle_award_info(InfoList, Data);
		_ ->
			Packet = msg_sc_riddle_award_info([?false, ?false, ?false, ?false], 0)
	end,
	misc_packet:send(UserId, Packet).

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 获取未领红包数量
get_redbag_num(UserId) ->
	case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_RED_BAG}) of
		{_, [], Data, _Time_S, _Time_E} ->
			Data;
		_ ->
			0
	end.

%% 开红包
open_redbag1(Player, ActivityId, Type) ->
	GoodsId = ?REDBAG_ID,
	{Count, GoodsList} = ctn_mod:get_goods_count_and_list(Player#player.bag, GoodsId),
	NeedNum = 
		case Type of
			0 -> 1;
			1 -> 20
		end,
	if Count >= NeedNum ->
		   case goods_mod:use_box_in_batch(Player#player.user_id, 
										   Player#player.bag,
										   (Player#player.info)#info.lv,
										   GoodsList,
										   NeedNum,
										   [],
										   []) of
			   {?ok, Bag, DirtyList, DropList} ->
				   do_after_open(Player, ActivityId, Bag, DirtyList, DropList);
			   {?error, ErrorCode, Bag, DirtyList, DropList} ->
				   PacketMsg = message_api:msg_notice(ErrorCode),
				   misc_packet:send(Player#player.net_pid, PacketMsg),
				   if DropList =/= [] ->
						  do_after_open(Player, ActivityId, Bag, DirtyList, DropList);
					  true ->
						  ?ok
					end
		   end;
	   true ->
		   MsgPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_REDBAG_NOT_ENOUGH),
           misc_packet:send(Player#player.user_id, MsgPacket),
		   ?ok
	end.

%% 开同心结
open_txj(Player, ActivityId, Type) ->
	GoodsId = ?TXJ_ID,
	{Count, GoodsList} = ctn_mod:get_goods_count_and_list(Player#player.bag, GoodsId),
	NeedNum = 
		case Type of
			0 -> 1;
			1 -> 20
		end,
	UseNum = lists:min([Count, NeedNum]),
	BuyNum = NeedNum - UseNum,
	{?ok, #money{cash = Cash, cash_bind_2 = BCash2}} = player_money_api:read_money(Player#player.user_id),
	%% 同心结数量可能不够，可能需部分使用元宝
	if (Cash + BCash2 - 10 * BuyNum) >= 0 andalso UseNum > 0 ->
		   case goods_mod:use_box_in_batch(Player#player.user_id, 
										   Player#player.bag,
										   (Player#player.info)#info.lv,
										   GoodsList,
										   UseNum,
										   [],
										   []) of
			   {?ok, Bag, DirtyList, DropList} ->
				   case open_txj_by_cash(Player#player.user_id, Bag, BuyNum, DirtyList, DropList) of
					   {?ok, Bag2, DirtyList2, DropList2} ->
						   ?ok = player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, 
															  10 * BuyNum, ?CONST_COST_OPEN_TXJ),
						   do_after_open(Player, ActivityId, Bag2, DirtyList2, DropList2);
					   {?error, ErrorCode, RemNum, Bag2, DirtyList2, DropList2} ->
						   ?ok = player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, 
															  10 * (BuyNum - RemNum), ?CONST_COST_OPEN_TXJ),
						   PacketMsg = message_api:msg_notice(ErrorCode),
						   misc_packet:send(Player#player.net_pid, PacketMsg),
						   do_after_open(Player, ActivityId, Bag2, DirtyList2, DropList2)
					end;
			   {?error, ErrorCode, Bag, DirtyList, DropList} ->
				   PacketMsg = message_api:msg_notice(ErrorCode),
				   misc_packet:send(Player#player.net_pid, PacketMsg),
				   if DropList =/= [] ->
						  do_after_open(Player, ActivityId, Bag, DirtyList, DropList);
					  true ->
						  ?ok
					end
		   end;
	   %% 完全使用元宝
	   (Cash + BCash2 - 10 * BuyNum) >= 0 ->
		   case open_txj_by_cash(Player#player.user_id, Player#player.bag, BuyNum, [], []) of
			   {?ok, Bag, DirtyList, DropList} ->
				   ?ok = player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, 
													  10 * BuyNum, ?CONST_COST_OPEN_TXJ),
				   do_after_open(Player, ActivityId, Bag, DirtyList, DropList);
			   {?error, ErrorCode, RemNum, Bag, DirtyList, DropList} ->
				   ?ok = player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, 
													  10 * (BuyNum - RemNum), ?CONST_COST_OPEN_TXJ),
				   PacketMsg = message_api:msg_notice(ErrorCode),
				   misc_packet:send(Player#player.net_pid, <<PacketMsg/binary>>),
				   if DropList =/= [] ->
						   ?ok = player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, 
															  10 * (BuyNum - RemNum), ?CONST_COST_OPEN_TXJ),
						   do_after_open(Player, ActivityId, Bag, DirtyList, DropList);
					  true ->
						  ?ok
					end
			end;
	   true ->
		   Packet = message_api:msg_sc_window(?CONST_SYS_CASH),
           misc_packet:send(Player#player.user_id, Packet),
		   ?ok
    end.

%% 用元宝开同心结	
open_txj_by_cash(_UserId, Bag, 0, DirtyList, DropList) ->
	{?ok, Bag, DirtyList, DropList};
open_txj_by_cash(UserId, Bag, BuyNum, DirtyList, DropList) ->
	NewDropList = goods_api:goods_drop(6210),
	case ctn_bag2_api:is_full(Bag) of
		true ->
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH, BuyNum, Bag, DirtyList, DropList};
		false ->
			case ctn_bag2_api:set_stack_list_dirty(UserId, Bag, NewDropList, ?CONST_COST_GOODS_USED, DirtyList) of
		        {?ok, Bag2, DirtyList2} ->
		            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_GOODS_BOX_GET, NewDropList, misc:seconds()),
					open_txj_by_cash(UserId, Bag2, BuyNum - 1, DirtyList2, NewDropList ++ DropList);
		        {?error, ErrorCode} ->
		            {?error, ErrorCode, BuyNum, Bag, DirtyList, DropList}
		    end
	end.

%% 开启红包后更新背包等处理
do_after_open(Player, ActivityId, Bag, DirtyList, DropList) ->
	open_redbag_broadcast(ActivityId, Player, DropList),
	Player2 = ctn_bag2_api:set_bag(Player, Bag),
	{Player3, StylePacket} = goods_style_api:add_style_list(Player2, DropList),
	{Player4, SkillPacket} = horse_skill_api:upgrade_skill_base(Player3, DropList),
	OPPacket = msg_sc_redbag_output(ActivityId, DropList),
	PacketBag = goods_mod:pack_dirty(Player4, DirtyList),
	misc_packet:send(Player4#player.net_pid, <<PacketBag/binary, StylePacket/binary, SkillPacket/binary, OPPacket/binary>>),
	{?ok, Player4}.

%% 开红包公告
open_redbag_broadcast(ActivityId, Player, DropList) ->
	open_redbag_broadcast(ActivityId, Player, DropList, []).
open_redbag_broadcast(_ActivityId, _Player, [], _Acc) ->
	?ok;
open_redbag_broadcast(ActivityId, Player, [Goods|Rem], Acc) ->
	case lists:member(Goods#goods.goods_id, Acc) of
		false ->
			if Goods#goods.color >= ?CONST_SYS_COLOR_ORANGE andalso
				Goods#goods.sub_type =:= ?CONST_GOODS_EQUIP_FUSION ->
				   case ActivityId of
					   ?CONST_YUNYING_ACTIVITY_RED_BAG -> 
						   Tips = ?TIP_YUNYING_ACTIVITY_REDBAG_GG2;
					   ?CONST_YUNYING_ACTIVITY_TXJ -> 
						   Tips = ?TIP_YUNYING_ACTIVITY_TXJ_GG2
				   end;
			   Goods#goods.color >= ?CONST_SYS_COLOR_ORANGE ->
			   	   case ActivityId of
					   ?CONST_YUNYING_ACTIVITY_RED_BAG -> 
						   Tips = ?TIP_YUNYING_ACTIVITY_REDBAG_GG1;
					   ?CONST_YUNYING_ACTIVITY_TXJ -> 
						   Tips = ?TIP_YUNYING_ACTIVITY_TXJ_GG1
				   end;
			   ?true ->
				   Tips = []
			end,
			if Tips =/= [] ->
				   BroadPacket = message_api:msg_notice(Tips, [{Player#player.user_id, Player#player.info#info.user_name}], [Goods],
														[{?TIP_SYS_OPEN_PANEL, misc:to_list(Tips)}]),
				   misc_app:broadcast_world_2(BroadPacket);
			   ?true ->
				   skip
			end,
			open_redbag_broadcast(ActivityId, Player, Rem, [Goods#goods.goods_id|Acc]);
		true ->
			open_redbag_broadcast(ActivityId, Player, Rem, Acc)
	end.
			
%% 检验答案
check_answer(Id, Ans) ->
	case get_user_riddle_id() of
		Id ->
			Riddle = data_yunying_activity:get_riddle(Id),
			if Ans =:= Riddle#rec_riddle.answer ->
				   Flag = ?true;
			   Ans =:= 0 ->
				   Flag = timeout;
			   true ->
				   Flag = ?false
			end;
		_ ->
			Flag = nomatch
	end,
	update_user_riddle_id(0),
	Flag.

%% 累计答题奖励
send_riddle_award(UserId, UserName, OldList, Num) ->
	[A, B, C, D] = OldList, 
	{GoodsId, NewList} = 
		case Num of
			5  -> {1050405081, [?true, B, C, D]};
			10 -> {1050405082, [A, ?true, C, D]};
			15 -> {1050405083, [A, B, ?true, D]};
			20 -> {1050405084, [A, B, C, ?true]};
			_  -> {0, OldList}
		end,
	if GoodsId =/= 0 ->
			MailGoods = goods_api:make(GoodsId, ?CONST_GOODS_BIND, 1),
			Content = [{[{misc:to_list(Num)}]}],
			mail_api:send_interest_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_RIDDLE_AWARD, Content, 
												MailGoods, 0, 0, 0, 0),
			Packet = msg_sc_riddle_award_info(NewList, Num),
			misc_packet:send(UserId, Packet);
	   true ->
		   skip
	end,
	NewList.
	
%% ====================================================================
%% Dict
%% ====================================================================
%% 获取riddle id
get_user_riddle_id() ->
	case get(?DIC_USERS_RIDDLE) of
		undefined ->
			0;
		Id when is_integer(Id) ->
			Id;
		_ ->
			0
	end.
%%
update_user_riddle_id(NewId) ->
	put(?DIC_USERS_RIDDLE, NewId).

%% ====================================================================
%% Packet
%% ====================================================================
%% 未领红包数量
msg_sc_redbag_num(Num) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_REDBAB_NUM,
					 ?MSG_FORMAT_YUNYING_ACTIVITY_SC_REDBAB_NUM, 
					 [Num]).

%% 红包产出信息
msg_sc_redbag_output(ActivityId, DropList) ->
	OPList = [{Goods#goods.goods_id, Goods#goods.count}|| Goods <- DropList],
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_REDBAG_OUTPUT, 
					 ?MSG_FORMAT_YUNYING_ACTIVITY_SC_REDBAG_OUTPUT, 
					 [ActivityId, OPList]).
%% 回答是否正确
msg_sc_anser_riddle_result(Flag)->
   misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_ANSWER,
					?MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_ANSWER, 
					[Flag]).

%% 累计答题奖励信息
msg_sc_riddle_award_info([A, B, C, D], Num) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_AWARD_INFO, 
					 ?MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_AWARD_INFO, 
					 [A, B, C, D, Num]).
