%%% 神刀点将
-module(act_card_ex_mod).
-behaviour(act_card_ex_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.act.hrl").
-include("const.tip.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").
-define(TEMID, 2).
%%
%% Exported Functions
%%
-export([init/1, join/2, over/1, login/1, logout/1, login_packet/2, offline/2, refresh/2]).
-export([
		 card_lottery_request_info/1
		 , card_lottery/3
		 , partner_exchange/3
		 , point_exchange/3
		 , get_partner_exchange_info/1
		 , freetimes/1
		]).
%%
%% API Functions
%%

login(OldPlayer) ->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			act_db_mod:ins_ets_user({OldPlayer#player.user_id, ActId}),
			OldPlayer;
		_ ->
			OldPlayer
	end.

logout(OldPlayer)->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			Key = {OldPlayer#player.user_id, ActId},
			act_db_mod:ins_db_user(Key),
			ets:delete(?CONST_ETS_ACT_USER, Key),
			OldPlayer;
		_ ->
			OldPlayer
	end.

login_packet(OldPlayer, _ActId) ->
	{OldPlayer, <<>>}.

init(ActId) ->
	case mysql_api:select(["user_id", "data"], "game_act_user", [ {"act_id", ActId}]) of
		{ok, Rows} ->
			Fun = fun([UserId, Bin]) ->
						  UserData = mysql_api:decode(Bin),
						  act_db_mod:ins_ets_act_user(#ets_act_user{key = {UserId, ActId}, user_id = UserId, act_id =ActId, data = UserData})
				  end,
			lists:foreach(Fun, Rows);
		_ ->
			?ok
	end,
	ok.

join(_, [UserId, Cash, Point, ActInfo]) ->
	?MSG_ERROR("join:~p|~p|~p|~p...", [UserId, Cash, Point, ActInfo]),
	ok.

over(_Id) ->
	ok.

offline(Player, _Data) ->
	{?ok, Player}.


%% 神刀0时更新
refresh(UserId, ACTID)->
	Key = {UserId, ACTID},
	case act_bhv:is_open(?TEMID) of
		?true->
			case act_db_mod:sel_ets_act_user(Key) of
				?null ->
					case mysql_api:select(["data"], "game_act_user", [{"user_id", UserId}, {"act_id", ACTID}]) of
						{ok, [[Bin]]} ->
							UserData = mysql_api:decode(Bin),
							Data2 = UserData#act_card_ex{free = ?CONST_YUNYING_ACTIVITY_GOD_CARDS},
							Sql = <<"insert into `game_act_user` (`user_id`,`act_id`,`data`) values (",(misc:to_binary(UserId))/binary,",",
									(misc:to_binary(ACTID))/binary, " ,  "
									,(mysql_api:encode(Data2#ets_act_user.data))/binary," ) ON DUPLICATE KEY UPDATE data= ",(mysql_api:encode(Data2#ets_act_user.data))/binary," ;">>,
							mysql_api:execute(Sql);
						_ ->
							?ok
					end;
				Data->
					Data2 = Data#ets_act_user.data,
					Data3 = Data#ets_act_user{data= Data2#act_card_ex{free = ?CONST_YUNYING_ACTIVITY_GOD_CARDS} },
					act_db_mod:up_ets_act_user(Key, {#ets_act_user.data, Data3})
			end,
			?ok;
		_ ->
			?ok
	end.


%% 获取武将兑换或点数兑换的界面信息
get_partner_exchange_info(Player) ->
	UserId = Player#player.user_id,
	%% 检查活动开启、数据有效、获得牌信息和点数
	{CardInfo,Point} = get_card_and_point(UserId),
	InfoPacket = yunying_activity_api:msg_sc_partner_exchange_info(CardInfo,Point),
	misc_packet:send(UserId, InfoPacket),
	?ok.


%%打开抽卡界面信息
card_lottery_request_info(Player)->
	try
		case act_db_mod:sel_ets_act_temp(?TEMID) of
			#ets_act_tmp{act_id = ActId} ->
				UserId = Player#player.user_id,
				Key = {UserId, ActId},
				Reply = 
					case act_bhv:is_open(?TEMID) of
						?true->
							case act_db_mod:sel_ets_act_user(Key) of
								?null ->
									ets:insert(?CONST_ETS_ACT_USER, #ets_act_user{key = Key, user_id = UserId, act_id =ActId, data = #act_card_ex{free = ?CONST_YUNYING_ACTIVITY_GOD_CARDS} }),
									[ ];
								Data->
									Data2 = Data#ets_act_user.data,
									Data2#act_card_ex.last_lottery
							end;
						_ -> %不在活动范围内
							[ ]
					end,
				Packet = yunying_activity_api:msg_sc_last_card_lottery_info(Reply),
				misc_packet:send(UserId,Packet);
			_ ->
				ok
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%免费白银抽奖次数
freetimes(Player)->
	try
		case act_db_mod:sel_ets_act_temp(?TEMID) of
			#ets_act_tmp{act_id = ActId} ->
				UserId = Player#player.user_id,
				Key = {UserId, ActId},
				Freetimes = 
					case act_bhv:is_open(?TEMID) of
						?true->
							case act_db_mod:sel_ets_act_user(Key) of
								?null ->
									0;
								Data->
									Data2 = Data#ets_act_user.data,
									Data2#act_card_ex.free
							end;
						_ -> %不在活动范围内
							0
					end,
				Packet = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_FREE_EXCHANGE, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_FREE_EXCHANGE, [Freetimes]),
				misc_packet:send(UserId,Packet);
			_ ->
				ok
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%抽卡 ,道具1093000016
card_lottery(Player,Type,Count)->
	try
		case act_db_mod:sel_ets_act_temp(?TEMID) of
			#ets_act_tmp{act_id = ActId} ->
				case lists:member(Count, [1,10]) of
					true ->
						next;
					false ->
						throw(badarg)
				end,
				UserId =Player#player.user_id,
				Key = {UserId, ActId},
				case act_bhv:is_open(?TEMID) of
					?true->
						AwardData = data_yunying_activity:get_card_lottery_data(Type),
						Free = 
							case act_bhv:is_open(?TEMID) of
								?true->
									case act_db_mod:sel_ets_act_user(Key) of
										?null ->
											0;
										Data->
											Data2 = Data#ets_act_user.data,
											Data2#act_card_ex.free
									end;
								_ -> %不在活动范围内
									0
							end,
						{NewFree, NewCost} = 
							if Type =:= 1 andalso Count =:= 10 ->
								   {0, AwardData#rec_yunying_activity_card_lottery.cost10 - Free * AwardData#rec_yunying_activity_card_lottery.cost1};
							   Type =:=1 andalso Free > 0->
								   {Free - 1, 0};
							   Count =:= 10 ->
								   {Free, AwardData#rec_yunying_activity_card_lottery.cost10};
							   Count =:= 1 ->
								   {Free, AwardData#rec_yunying_activity_card_lottery.cost1}
							end,
						card_lottery2(Player, AwardData,[ ],Count,NewCost,erlang:trunc(NewFree));
					_ ->
						Packet = message_api:msg_notice(?TIP_COMMON_ACTIVITY_NOT_IN_TIME),
						misc_packet:send(UserId, Packet),
						{?ok,Player}
				end;
			_ ->
				ok
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
			?error
	end.

card_lottery2(Player,_AwardData,CardList,0,Cost,NewFree)->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			UserId = Player#player.user_id,
			Key = {UserId, ActId},
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_CARD_EXCHANGE_PARTNER) of %% 扣取
				?ok -> 
					Cards = 
						case act_db_mod:sel_ets_act_user(Key) of
							?null ->
								#act_card_ex{};
							Data->
								Data#ets_act_user.data
						end,
					NewCards = card_merge(Cards#act_card_ex.cards, CardList),
					act_db_mod:up_ets_act_user(Key, {#ets_act_user.data, Cards#act_card_ex{cards = NewCards, free = NewFree}}),
					Packet1 = yunying_activity_api:msg_sc_card_lottery_result(CardList),
					Packet2 = yunying_activity_api:msg_sc_last_card_lottery_info(CardList),
					Packet3 = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_FREE_EXCHANGE,?MSG_FORMAT_YUNYING_ACTIVITY_SC_FREE_EXCHANGE,[NewFree]),
					misc_packet:send(UserId, <<Packet1/binary,Packet2/binary,Packet3/binary>>),
					{?ok,Player};
				{?error,_Error}->
					{?ok,Player}
			end;
		_ ->
			ok
	end;

card_lottery2(Player, AwardData,CardList,Count,Cost,NewFree)->
	WeightList =[W||{_,W}<-AwardData#rec_yunying_activity_card_lottery.card_list],
	Sum = lists:foldl(fun(W,Acc)->Acc+W end, 0, WeightList),
	Rand = random:uniform(Sum),
	Nth = selected_by_weight(WeightList,Rand,1),
	{CardId,_} = lists:nth(Nth, AwardData#rec_yunying_activity_card_lottery.card_list),
	NewCardList =
		case lists:keytake(CardId,1,CardList) of
			{value,{CardId,Num},CardList2}->
				[{CardId,Num+1}|CardList2];
			false->
				[{CardId,1}|CardList]
		end,
	card_lottery2(Player,AwardData,NewCardList,Count -1,Cost,NewFree).

selected_by_weight([H|_],Rand,N)when H >= Rand ->
	N;
selected_by_weight([H|T],Rand,N)->
	selected_by_weight(T,Rand-H,N+1);
selected_by_weight(_,_,_)->
	throw(badarg).

%%将已有的卡片和新抽到的卡片列表合并[{1,6}...]
card_merge(Card1,Card2)->
	lists:foldl(fun({CardId,Num},Acc)->
						case lists:keytake(CardId,1,Acc) of
							{value,{CardId,Count},Rest}->
								[{CardId,Count+Num}|Rest];
							false ->
								[{CardId,Num}|Acc]
						end
				end,Card1,Card2).		

%% 检查活动开启、数据有效、获得牌信息和点数
get_card_and_point(UserId) ->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			case act_bhv:is_open(?TEMID) of
				?true->
					Key = {UserId, ActId},
					case act_db_mod:sel_ets_act_user(Key) of
						?null ->
							ets:insert(?CONST_ETS_ACT_USER, #ets_act_user{key = Key, user_id = UserId, act_id = ActId, data = #act_card_ex{free=?CONST_YUNYING_ACTIVITY_GOD_CARDS} }),
							{[], 0};
						Data->
							Data2 = Data#ets_act_user.data,
							{Data2#act_card_ex.cards, Data2#act_card_ex.points}
					end;
				?false ->
					{[], 0}
			end;
		_ ->
			{[], 0}
	end.

%%检查牌数是否充足
check_card_num(CardInfo,NeedList) ->
	lists:foreach(fun({Card,Num}) ->
						  case lists:keyfind(Card,1,CardInfo) of
							  false ->
								  throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH});
							  {_,CurNum} ->
								  case Num =< CurNum of
									  true ->
										  ?ok;
									  false ->
										  throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH})
								  end
						  end
				  end, NeedList).


%% 抽奖收集卡牌换武将——武将兑换
partner_exchange(Player,Type,Id) ->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			case act_db_mod:sel_ets_time(ActId) of
				#ets_act_info{is_open = 1, config_id=ConfigId} ->
					UserId = Player#player.user_id,
					%% 检查活动开启、数据有效、获得牌信息和点数
					{CardInfo,Point} = get_card_and_point(UserId),
					Key = {UserId, ActId},
					Cards = 
						case act_db_mod:sel_ets_act_user(Key) of
							?null ->
								#act_card_ex{};
							Data->
								Data#ets_act_user.data
						end,
					case data_yunying_activity:get_partner_exchange({ConfigId,Type,Id}) of
						null ->
							throw({?error,?TIP_COMMON_BAD_ARG});
						#rec_yunying_activity_partner_exchange{need_goods=NeedList,exchange_goods=ExcGoods} ->
							if Type == 1 -> %%兑换武将
								   {PartnerID,_,_} = ExcGoods,
								   %%检查是否已招募武将
								   ?ok = check_partner_in_team(Player,PartnerID),
								   %%检查牌数是否充足
								   ?ok = check_card_num(CardInfo,NeedList),
								   %%检查玩家携带武将上限
								   ?ok = check_partner_max(Player),
								   NewCardInfo = 
									   lists:foldl(fun({Card,Num},Acc)->
														   case lists:keytake(Card, 1, Acc) of
															   false ->
																   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH});
															   {value,{Card,CurNum},OtherCardInfo} ->
																   case Num =< CurNum of
																	   true ->
																		   lists:append([{Card,CurNum-Num}],OtherCardInfo);
																	   false ->
																		   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH})
																   end
														   end
												   end, CardInfo, NeedList),
								   Player2	= partner_mod:update_looked_list(Player, PartnerID),						%% 存进lookfor结构中
								   Player3	= partner_mod:add_assemble(Player2, PartnerID),
								   BasePartner = partner_api:get_base_partner(Player3, PartnerID),
								   Player4 = partner_mod:recruit_partner_ext(Player3, BasePartner),
								   act_db_mod:up_ets_act_user(Key, {#ets_act_user.data, Cards#act_card_ex{cards = NewCardInfo}}),
								   TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_PARTNER_SUCC,[{?TIP_SYS_COMM, BasePartner#partner.partner_name}]),
								   InfoPacket = yunying_activity_api:msg_sc_partner_exchange_info(NewCardInfo,Point),
								   misc_packet:send(UserId, <<TipPacket/binary,InfoPacket/binary>>),
								   BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_PARTNER_RECRUIT, [{Player#player.user_id, (Player#player.info)#info.user_name}], [], [{?TIP_SYS_PARTNER, misc:to_list(PartnerID)}, 
																																													{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_PARTNER_RECRUIT)}]),	%全服广播
								   misc_app:broadcast_world_2(BroadPacket),
								   {?ok,Player4};
							   Type == 2  -> %%  兑换物品
								   {GoodsId,Bind,Count} = ExcGoods,
								   NewCardInfo = 
									   lists:foldl(fun({Card,Num},Acc)->
														   case lists:keytake(Card, 1, Acc) of
															   false ->
																   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH});
															   {value,{Card,CurNum},OtherCardInfo} ->
																   case Num =< CurNum of
																	   true ->
																		   lists:append([{Card,CurNum-Num}],OtherCardInfo);
																	   false ->
																		   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH})
																   end
														   end
												   end, CardInfo, NeedList),
								   Bag = Player#player.bag,
								   case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
									   ?false ->		
										   GoodsList = goods_api:make(GoodsId, Bind, Count),
										   case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SNOW_GET_AWARD, 1, 1, 0, 0, 0, 1, []) of
											   {?ok, Player2, _, Packet} ->
												   act_db_mod:up_ets_act_user({UserId, ActId}, {#ets_act_user.data, Cards#act_card_ex{cards = NewCardInfo}}),
												   TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_EXCHANGE_SUCC),
												   InfoPacket = yunying_activity_api:msg_sc_partner_exchange_info(NewCardInfo,Point),
												   misc_packet:send(UserId, <<Packet/binary,TipPacket/binary,InfoPacket/binary>>),
												   {?ok, Player2};
											   {?error, ErrorCode1} ->
												   throw({?error, ErrorCode1})
										   end;
									   _ -> throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
								   end;
							   true ->
								   throw({?error,?TIP_COMMON_BAD_ARG})
							end
					end;
				_ ->
					ok
			end;
		_ ->
			ok
	end.

%% 抽奖收集卡牌换武将——点数兑换
point_exchange(Player,Type,{_,ExcList}) ->
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			case ExcList =:=[ ] of
				true ->
					throw({?error,?TIP_YUNYING_ACTIVITY_EXCHANGE_WRONG_NUM});
				false ->
					next
			end,
			UserId = Player#player.user_id,
			Key = {UserId, ActId},
			Cards = 
				case act_db_mod:sel_ets_act_user(Key) of
					?null ->
						#act_card_ex{};
					Data->
						Data#ets_act_user.data
				end,
			%% 检查活动开启、数据有效、获得牌信息和点数
			{CardInfo,Point} = get_card_and_point(UserId),
			if Type == 3  -> %% 牌兑换点数
				   {NewCardInfo, ChangedPoint} = 
					   lists:foldl(fun({Card,Num},{CardInfo1,Point1}) ->
										   case lists:keytake(Card, 1, CardInfo1) of
											   false ->
												   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH});
											   {value,{Card,CurNum},OtherCardInfo} ->
												   case Num =< CurNum of
													   true ->
														   case data_yunying_activity:get_partner_exchange({?CONST_SYS_FALSE, Type,Card}) of
															   null ->
																   throw({?error,?TIP_COMMON_BAD_ARG});
															   #rec_yunying_activity_partner_exchange{exchange_goods=ExcPoint} when is_integer(ExcPoint) ->
																   {lists:append([{Card,CurNum-Num}],OtherCardInfo),Point1+Num*ExcPoint};
															   _ ->
																   throw({?error,?TIP_COMMON_SYS_ERROR})
														   end;
													   false ->
														   throw({?error,?TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH})
												   end
										   end
								   end,{CardInfo,Point},ExcList),
				   act_db_mod:up_ets_act_user({UserId, ActId}, {#ets_act_user.data, Cards#act_card_ex{cards = NewCardInfo, points = ChangedPoint }}),
				   TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_EXCHANGE_POINT_SUCC,[{?TIP_SYS_COMM, misc:to_list(ChangedPoint-Point)}]),
				   InfoPacket = yunying_activity_api:msg_sc_partner_exchange_info(NewCardInfo,ChangedPoint),
				   misc_packet:send(UserId, <<TipPacket/binary,InfoPacket/binary>>),
				   ?ok;
			   Type == 4  -> %% 点数兑换牌
				   {NewCardInfo, ChangedPoint} = 
					   lists:foldl(fun({Card,Num},{CardInfo1,Point1}) ->
										   case data_yunying_activity:get_partner_exchange({?CONST_SYS_FALSE, Type,Card}) of
											   null ->
												   throw({?error,?TIP_COMMON_BAD_ARG});
											   #rec_yunying_activity_partner_exchange{need_goods=NeedPoint} when is_integer(NeedPoint) ->
												   case Point1 -Num*NeedPoint >= 0 of
													   true ->
														   case lists:keytake(Card, 1, CardInfo1) of
															   false ->
																   {lists:append([{Card,Num}],CardInfo1),Point1 -Num*NeedPoint};
															   {value,{Card,CurNum},OtherCardInfo} ->
																   {lists:append([{Card,CurNum+Num}],OtherCardInfo),Point1-Num*NeedPoint}
														   end;
													   false ->
														   throw({?error,?TIP_YUNYING_ACTIVITY_POINT_NOT_ENOUGH})
												   end;
											   _ ->
												   throw({?error,?TIP_COMMON_SYS_ERROR})
										   end
								   end,{CardInfo,Point},ExcList),
				   %% 修改ets,增加tips
				   act_db_mod:up_ets_act_user({UserId, ActId}, {#ets_act_user.data, Cards#act_card_ex{cards = NewCardInfo, points = ChangedPoint }}),
				   TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_POINT_EXCHANGE_SUCC,[{?TIP_SYS_COMM, misc:to_list(Point-ChangedPoint)}]),
				   InfoPacket = yunying_activity_api:msg_sc_partner_exchange_info(NewCardInfo,ChangedPoint),
				   misc_packet:send(UserId, <<TipPacket/binary,InfoPacket/binary>>),
				   ?ok;
			   true ->
				   throw({?error,?TIP_COMMON_BAD_ARG})
			end;
		_ ->
			ok
	end.

%%检查是否已招募武将
check_partner_in_team(Player,PartnerID) ->
	TeamPartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	IsInTeam = lists:keyfind(PartnerID, #partner.partner_id, TeamPartnerList),
	case IsInTeam of 
		false ->
			?ok;
		_ ->
			throw({?error, ?TIP_YUNYING_ACTIVITY_PARTNER_ALREADY})
	end.

%%检查玩家携带武将上限
check_partner_max(Player) ->
	TeamPartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	TeamNum = length(TeamPartnerList),
	BasePlayer = data_player:get_player_level({(Player#player.info)#info.pro, (Player#player.info)#info.lv}),
	TeamMax = BasePlayer#player_level.partner_max,
	case TeamNum >= TeamMax of
		true ->
			throw({?error,?TIP_YUNYING_ACTIVITY_PARTNER_FULL});
		false ->
			?ok
	end.
