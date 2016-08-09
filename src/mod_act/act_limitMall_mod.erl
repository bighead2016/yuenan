%% @author sitting
%% @doc @todo Add description to act_limitMall_mod.


-module(act_limitMall_mod).
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
-define(TEMID, 3).
%% ====================================================================
%% API functions
%% ====================================================================
-export([init/1, join/2, over/1, login/1, logout/1, login_packet/2, offline/2, refresh/2, refresh/1]).
-export([
		 get_mall_list/1
		, buy/3
		, buy/2
		]).



%% ====================================================================
%% Internal functions
%% ====================================================================

get_mall_list(UserId) ->
	Reply =
		case act_db_mod:sel_ets_act_temp(?TEMID) of
			#ets_act_tmp{act_id = ActId} ->
				case act_db_mod:sel_ets_time(ActId) of
					#ets_act_info{is_open = 1} ->
						Goods = data_act:get_limit_mall(ActId),
						Packet = misc_packet:pack(?MSG_ID_LIMIT_MALL_MALL_GOODS, ?MSG_FORMAT_LIMIT_MALL_MALL_GOODS, [Goods]),
						Packet2 =
						case act_db_mod:sel_ets_act_user({UserId, ActId}) of
									?null ->
										act_db_mod:ins_ets_act_user(#ets_act_user{key={UserId, ActId}, user_id=UserId, act_id=ActId, data=gb_trees:empty()}),
										<<>>;
									Data->
										Trees = Data#ets_act_user.data,
										List = gb_trees:to_list(Trees),
										Fun =
											fun({Goodid,AlreadyBuy},Acc)->
												PacketTemp = misc_packet:pack(?MSG_ID_LIMIT_MALL_RECEIPT, ?MSG_FORMAT_LIMIT_MALL_RECEIPT, [Goodid, AlreadyBuy]),
												<<PacketTemp/binary, Acc/binary>>
											end,
										lists:foldl(Fun, <<>>, List)
								end,
						misc_packet:send(UserId, <<Packet/binary,Packet2/binary>>), 
						?true;
					_ ->
						?false
				end;
			_ ->
				?false
		end,
	case Reply of
		?true ->
			?ok;
		_ ->
			PacketTip = message_api:msg_notice(?TIP_LIMIT_MALL_MALL_CLOSE),
			misc_packet:send(UserId, PacketTip)
	end.

buy(Player, {Goodid, Num}) ->
	buy(Player, Goodid, Num).
buy(UserId, Goodid, Num) when is_integer(UserId)->
	player_api:process_send(UserId,act_limitMall_mod,buy,{Goodid, Num});
buy(Player, Goodid, Num) ->
	UserId = Player#player.user_id,
	case act_db_mod:sel_ets_act_temp(?TEMID) of
		#ets_act_tmp{act_id = ActId} ->
			case act_db_mod:sel_ets_time(ActId) of
				#ets_act_info{is_open = 1} ->
					Goods = data_act:get_limit_mall(ActId),
					case lists:keyfind(Goodid, 1, Goods) of
						?false ->
							PacketTip = message_api:msg_notice(?TIP_LIMIT_MALL_NO_GOODS),
							misc_packet:send(UserId, PacketTip),
							{?ok, Player};
						{Goodid, _, Price, Limit} ->
							{PlayerAlreadyBuy, Tree} =
								case act_db_mod:sel_ets_act_user({UserId, ActId}) of
									?null ->
										act_db_mod:ins_ets_act_user(#ets_act_user{key={UserId, ActId}, user_id=UserId, act_id=ActId, data=gb_trees:empty()}),
										{0, gb_trees:empty()};
									Data->
										Trees = Data#ets_act_user.data,
										case gb_trees:lookup(Goodid, Trees) of
											none ->
												{0, Trees};
											{value, Buy} ->
												{Buy, Trees}
										end
								end,
							PlayerCanBuy = misc:min(Limit - PlayerAlreadyBuy, Num),
							if PlayerCanBuy > 0 ->
								   GoodsGet = goods_api:make(Goodid, ?CONST_GOODS_BIND, PlayerCanBuy),
								   {NewPlayer,NewData} =
									   case ctn_bag_api:put(Player, GoodsGet, ?CONST_COST_LIMIT_MALL, 1, 1, 1, 0, 1, 1, []) of
										   {?ok, Player2, _Changelist, _Packet}->
											   case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, PlayerCanBuy * Price, ?CONST_COST_LIMIT_MALL) of
												   {?error, _} ->
													   {Player, Tree};
												   _ ->
													   PacketTip2 = message_api:msg_notice(?TIP_LIMIT_MALL_BUY_OK),
													   Packet2 = misc_packet:pack(?MSG_ID_LIMIT_MALL_RECEIPT, ?MSG_FORMAT_LIMIT_MALL_RECEIPT, [Goodid, PlayerCanBuy]),
													   misc_packet:send(UserId, <<PacketTip2/binary, Packet2/binary>>),
													   case gb_trees:is_defined(Goodid, Tree) of
														   ?true ->
															   {Player2, gb_trees:update(Goodid, PlayerAlreadyBuy + PlayerCanBuy, Tree)};
														   _ ->
															   {Player2, gb_trees:insert(Goodid, PlayerCanBuy, Tree)}
													   end
											   end;
										   _ ->
											   {Player, Tree}
									   end,
								   act_db_mod:up_ets_act_user({UserId, ActId}, {#ets_act_user.data, NewData}),
								   {?ok, NewPlayer};
							   ?true ->
								   PacketTip3 = message_api:msg_notice(?TIP_LIMIT_MALL_BUY_FAIL),
								   misc_packet:send(UserId, PacketTip3),
								   {?ok, Player}
							end   
					end;
				_ ->
					PacketTip3 = message_api:msg_notice(?TIP_LIMIT_MALL_MALL_CLOSE),
					misc_packet:send(UserId, PacketTip3),
					{?ok, Player}
			end;
		_ ->
			PacketTip5 = message_api:msg_notice(?TIP_LIMIT_MALL_BAG_FULL),
			misc_packet:send(UserId, PacketTip5),
			{?ok, Player}
	end.



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
%% 	Data =
%% 		case act_db_mod:sel_ets_act_temp(?TEMID) of
%% 			#ets_act_tmp{act_id = ActId} ->
%% 				case act_db_mod:sel_ets_time(ActId) of
%% 					#ets_act_info{is_open = 1, stop_time = EndTime} ->
%% 						[?true, EndTime];
%% 					_ ->
%% 						[?false, ?CONST_SYS_FALSE]
%% 				end;
%% 			_ ->
%% 				[?false, ?CONST_SYS_FALSE]
%% 		end,
%% 	Packet = misc_packet:send(?MSG_ID_LIMIT_MALL_OPEN_DOOR, ?MSG_FORMAT_LIMIT_MALL_OPEN_DOOR, Data),
	{OldPlayer, <<>>}.

init(_ActId) ->
	?ok.

join(_, [UserId, Cash, Point, ActInfo]) ->
	?MSG_ERROR("join:~p|~p|~p|~p...", [UserId, Cash, Point, ActInfo]),
	?ok.

over(ACTID) ->
	ets:select_delete(?CONST_ETS_ACT_USER, [{#ets_act_user{act_id=ACTID, data='_', key='_', user_id='_'},[],[true]}]),
	Sql = <<"DELETE FROM `game_act_user`where `act_id`=",
			(misc:to_binary(ACTID))/binary, " ;">>,
	mysql_api:execute(Sql),
	?ok.

offline(Player, _Data) ->
	{?ok, Player}.


refresh(UserId, ACTID)->
	Key = {UserId, ACTID},
	act_db_mod:del_ets_act_user(Key),
	Sql = <<"DELETE FROM `game_act_user`where `user_id`=",(misc:to_binary(UserId))/binary," AND `act_id`=",
			(misc:to_binary(ACTID))/binary, " ;">>,
	mysql_api:execute(Sql),
	?ok.

refresh(ACTID)->
	ets:select_delete(?CONST_ETS_ACT_USER, [{#ets_act_user{act_id=ACTID, data='_', key='_', user_id='_'},[],[true]}]),
	Sql = <<"DELETE FROM `game_act_user`where `act_id`=",
			(misc:to_binary(ACTID))/binary, " ;">>,
	mysql_api:execute(Sql),
	?ok.