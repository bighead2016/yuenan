%% author: xjg
%% create: 2014-1-15
%% desc: shop_secret
%%


-module(shop_secret).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.goods.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 init_active/0,
		 get_init_info/1,
		 buy/4,
		 refresh/1,
		 login/1,
		 logout/1,
		 save_active_data/0,
		 init_active_data/0,
		 zero_refresh/1,
		 add_score/2
		 ]).

%% gm增加积分
add_score(UserId, Value) ->
	case get_secret_info(UserId) of
		?null ->
			?ok;
		SecretInfo ->
			update_secret_info(SecretInfo#ets_secret_info{score = SecretInfo#ets_secret_info.score + Value})
	end.

%% 零点刷新
zero_refresh(#player{user_id = UserId}) ->
	zero_refresh(UserId);
zero_refresh(UserId) ->
	case get_secret_info(UserId) of
		?null ->
			?ok;
		SecretInfo ->
			case misc:is_same_date(SecretInfo#ets_secret_info.update_time, misc:seconds()) of
				?true ->
					?ok;
				?false ->
					NewSecretInfo = SecretInfo#ets_secret_info{
															   refresh = ?CONST_SYS_FALSE,
															   free = ?CONST_SYS_FALSE,
															   buy_times = ?CONST_SHOP_SECRET_BUY_TIMES
															  },
					update_secret_info(NewSecretInfo),
					init_secret_info(UserId)
			end
	end.

%% 上线
login(#player{user_id = UserId}) ->
	Sql = erlang:list_to_binary(io_lib:format("select `record` from `game_shop_secret_info` where `user_id` = ~p", [UserId])),
	case mysql_api:select(Sql) of
		{?ok, []} -> 
			%?MSG_ERROR("shop secret no player data", []),
			?ok;
		{?ok, [[BinRecord]]} ->
			Record = mysql_api:decode(BinRecord),
			insert_secret_info(Record);
		{?error, ErrorCode} ->
			?MSG_ERROR("ErrorCode:~p", [ErrorCode])
	end,
	zero_refresh(UserId).

%% 下线
logout(#player{user_id = UserId}) ->
	case get_secret_info(UserId) of
		?null ->
			?ok;
		SecretInfo ->
			Sql = erlang:list_to_binary(io_lib:format("replace into `game_shop_secret_info`(`user_id`, `record`) values(~p,~s)",
													  [UserId, mysql_api:encode(SecretInfo)])),
			mysql_api:execute(Sql),
			delete_secret_info(UserId)
	end.

%% 保存活动数据
save_active_data() ->
	case ets_api:lookup(?CONST_ETS_SECRET, 1) of
		?null ->
			?ok;
		EtsSecret ->
			Sql = erlang:list_to_binary(io_lib:format("replace into `game_shop_secret`(`id`, `record`) values(~p,~s)", [1, mysql_api:encode(EtsSecret)])),
			mysql_api:execute(Sql)
	end.

%% 加载活动数据
init_active_data() ->
	Sql = <<"select `record` from `game_shop_secret` where `id` = 1">>,
	case mysql_api:select(Sql) of
		{?ok, []} ->
			?ok;
		{?ok, [[BinRecord]]} ->
			Record = mysql_api:decode(BinRecord),
			ets_api:insert(?CONST_ETS_SECRET, Record);
		{?error, ErrorCode} ->
			?MSG_ERROR("errror:~p", [ErrorCode])
	end.

%% 初始化活动
init_active() ->
	{StartTime, EndTime} = data_welfare:get_deposit_active_time(21),
	LogData =
		case ets_api:lookup(?CONST_ETS_SECRET, 1) of
			?null ->
				[];
			#ets_secret{log_data = LogData2} ->
				LogData2
		end,
	EtsSecret= #ets_secret{
						   id = 1,
						   log_data = LogData,
						   start_time = StartTime,
						   end_time = EndTime
						  },
	ets_api:insert(?CONST_ETS_SECRET, EtsSecret),
	?ok.

%% 获取商店初始化信息
get_init_info(#player{user_id = UserId}) ->
	try
		?ok = check_info(),
		init_info(UserId),
		send_log_info(UserId)
	catch
		throw:{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, TipPacket),
			?MSG_ERROR("shop secret get init info error:~p", [ErrorCode]);
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

%% 获取道具信息
get_data_info(Id, Data) ->
	case lists:keyfind(Id, 1, Data) of
			?false ->
				throw({?error, ?TIP_SHOP_NOT_EXISTS});
			{Id, Tuple, BuyState} ->
				case BuyState of
					?CONST_SHOP_SECRET_UNABLE ->
						throw({?error, ?TIP_SHOP_UNABLE_BUY});
					?CONST_SHOP_SECRET_ABLE ->
						Tuple
				end
	end.

%% 检查购买是否是宝石
check_stone(UserId, GoodsId, Count) ->
	case data_goods:get_goods(GoodsId) of
		#goods{type = GoodsType} ->
			case GoodsType =:= ?CONST_GOODS_EQUIP_STONE of
				?true ->
					StoneLevel = furnace_soul_api:get_stone_lv(GoodsId),
					yunying_activity_mod:add_activity_stone_value(UserId, StoneLevel, Count, 1);%% 购买宝石送积分
				?false ->
					?ok
			end;
		_ ->
			?ok
	end.

%% 检查是否满足积分兑换条件
check_buy_conditon(UserScore, NeedScore, NeedGold) ->
	case UserScore >= NeedScore of
		?false ->
			throw({?error, ?TIP_SHOP_SCORE_NOT_ENOUGH});
		?true ->
			NeedGold =:= ?CONST_SYS_FALSE
	end.

%% 元宝购买道具
buy(#player{user_id = UserId} = Player, Id, ?CONST_SHOP_SECRET_BTYPE_GOLD, _Num) ->
	try
		?ok = check_info(),
		?ok = check_bag_full(Player),
		SecretInfo = get_secret_info(UserId),
		#ets_secret_info{data = Data, buy_times = BuyTimes} = SecretInfo,
		?ok = check_buy_times(BuyTimes),
		Tuple = get_data_info(Id, Data),
		#rec_shop_secret{goods_id = GoodsId, count = Count, bind = Bind, sell = Sell, log = Log, rare = Rare} = Tuple,
		case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Sell, ?CONST_COST_SECRET_BUY_GOODS) of
			{?error, ErrorCode} ->
				?MSG_ERROR("shop secret buy goods error:~p", [ErrorCode]),
				throw({?error, ?CONST_SYS_CASH, ErrorCode});
			?ok ->
				NewData = lists:keyreplace(Id, 1, Data, {Id, Tuple, ?CONST_SHOP_SECRET_UNABLE}),
				NewSecretInfo = SecretInfo#ets_secret_info{data = NewData, buy_times = BuyTimes - 1},
				update_secret_info(NewSecretInfo),
				log_buy_goods(Player, Sell, GoodsId, Log),
				check_stone(UserId, GoodsId, Count),
				admin_log_api:log_shop_secret(Player, GoodsId, Count, ?CONST_SYS_CASH, Sell, 0, misc:seconds()),
				add_goods(Player, GoodsId, Bind, Count, ?CONST_COST_SECRET_BUY_GOODS, Rare)
		end
	catch
		throw:{?error, ?CONST_SYS_CASH, _ErrorCode3} ->
			{?ok, Player};
		throw:{?error, ErrorCode2} ->
			?MSG_ERROR("shop secret buy goods error:~p", [ErrorCode2]),
			Packet2 = shop_api:msg_sc_buy_goods(?CONST_SYS_FALSE),
			TipPacket = message_api:msg_notice(ErrorCode2),
			misc_packet:send(UserId, <<Packet2/binary, TipPacket/binary>>),
			{?ok, Player};
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()]),
			{?ok, Player}
	end;

%% 积分兑换道具
buy(#player{user_id = UserId} = Player, Id, ?CONST_SHOP_SECRET_BTYPE_SCORE, _Num) ->
	try
		Num = 1,
		?ok = check_info(),
		?ok = check_bag_full(Player),
		SecretInfo = get_secret_info(UserId),
		UserScore = SecretInfo#ets_secret_info.score,
		ScoreInfo = data_shop:get_shop_score(Id),
		#rec_shop_score{goods_id = GoodsId, bind = Bind, score = Score, gold = Gold, rare = Rare} = ScoreInfo,
		{NeedScore, NeedGold} = {Score * Num, Gold * Num},
		case check_buy_conditon(UserScore, NeedScore, NeedGold) of
			?true ->
				?ok;
			?false ->
				case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, NeedGold, ?CONST_COST_SECRET_BUY_GOODS) of
					{?error, ErrorCode} ->
						?MSG_ERROR("shop secret buy goods score error:~p", [ErrorCode]),
						throw({?error, ?CONST_SYS_CASH, ErrorCode});
					?ok ->
						?ok
				end
		end,
		update_secret_info(SecretInfo#ets_secret_info{score = UserScore - NeedScore}),
		admin_log_api:log_shop_secret(Player, GoodsId, Num, ?CONST_SYS_CASH, NeedGold, NeedScore, misc:seconds()),
		add_goods(Player, GoodsId, Bind, Num, ?CONST_COST_SECRET_BG_SCORE, Rare)
	catch
		throw:{?error, ?CONST_SYS_CASH, _ErrorCode4} ->
			{?ok, Player};
		throw:{?error, ErrorCode3} ->
			?MSG_ERROR("shop secret buy goods score error:~p", [ErrorCode3]),
			Packet2 = shop_api:msg_sc_buy_goods(?CONST_SYS_FALSE),
			TipPacket = message_api:msg_notice(ErrorCode3),
			misc_packet:send(UserId, <<Packet2/binary, TipPacket/binary>>),
			{?ok, Player};
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 增加物品
add_goods(#player{user_id = UserId, info = Info} = Player, GoodsId, Bind, Num, Type, Rare) ->
	GoodsList = goods_api:make(GoodsId, Bind, Num),
	case ctn_bag_api:put(Player, GoodsList, Type, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag} ->
			Packet = shop_api:msg_sc_buy_goods(?CONST_SYS_TRUE),
			misc_packet:send(UserId, Packet),
			case Rare =:= ?CONST_SYS_TRUE of
				?true ->
					BroadPacket	= message_api:msg_notice(?TIP_SHOP_BUY_RARE_GOODS, [{UserId, Info#info.user_name}], GoodsList, []),
					misc_app:broadcast_world_2(BroadPacket);
				?false ->
					?ok
			end,
			init_info(UserId),
			{?ok, Player2};
		{?error, ErrorCode}	->
			?MSG_ERROR("add goods error:~p", [ErrorCode]),
			throw({?error, ErrorCode})
	end.

%% 刷新道具表
refresh(#player{user_id = UserId}) ->
	try
		?ok = check_info(),
		SecretInfo = get_secret_info(UserId),
		#ets_secret_info{free = Free, refresh = Refresh, score = Score} = SecretInfo,
		{NewFree, NewRefresh} =
			case check_refresh(SecretInfo) of
				{?error, ErrorCode} ->
					throw({?error, ErrorCode});
				{?ok, free} ->
					{Free + 1, Refresh};
				{?ok, refresh} ->
					{Free, Refresh + 1}
			end,
		case Refresh =/= NewRefresh of
			?false ->
				?ok;
			?true ->
				case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_SHOP_SECRET_REFRESH_COST, ?CONST_COST_SECRET_REFRESH) of
					{?error, ErrorCode2} ->
						?MSG_ERROR("shop secret refresh error:~p", [ErrorCode2]),
						throw({?error, ?CONST_SYS_CASH, ErrorCode2});
					?ok ->
						?ok
				end
		end,
		SecretInfo2 = init_secret_info(UserId),
		NewSecretInfo = SecretInfo2#ets_secret_info{free = NewFree, refresh = NewRefresh, score = Score + ?CONST_SHOP_SECRET_CHANGE},
		ets_api:insert(?CONST_ETS_SECRET_INFO, NewSecretInfo),
		Packet = shop_api:msg_sc_secret_refresh(?CONST_SYS_TRUE),
		misc_packet:send(UserId, Packet),
		init_info(UserId)
	catch
		throw:{?error, ?CONST_SYS_CASH, _ErrorCode4} ->
			?ok;
		throw:{?error, ErrorCode3} ->
			?MSG_ERROR("shop secret refresh error:~p", [ErrorCode3]),
			Packet2 = shop_api:msg_sc_secret_refresh(?CONST_SYS_TRUE),
			TipPacket = message_api:msg_notice(ErrorCode3),
			misc_packet:send(UserId, <<Packet2/binary, TipPacket/binary>>);
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()])
	end.

%% 检查刷新次数
check_refresh(#ets_secret_info{free = Free}) ->
	case Free >= ?CONST_SHOP_SECRET_FREE of
		?false ->
			{?ok, free};
		?true ->
			{?ok, refresh}
	end.

%% 检查信息
check_info() ->
	case ets_api:lookup(?CONST_ETS_SECRET, 1) of
		?null ->
			throw({?error, ?TIP_SHOP_NOT_OPEN});
		#ets_secret{start_time = StartTime, end_time = EndTime} ->
			Now = misc:seconds(),
			case Now >= StartTime andalso Now =< EndTime of
				?true ->
					?ok;
				?false ->
					throw({?error, ?TIP_SHOP_IS_OVER})
			end
	end.

%% 检查背包是否已满
check_bag_full(Player) ->
	case ctn_bag2_api:is_full(Player#player.bag) of
		?false ->
			?ok;
		?true ->
			throw({?error, ?TIP_SHOP_BAG_IS_FULL})
	end.

%% 检查是否还有购买次数
check_buy_times(BuyTimes) ->
	case BuyTimes > ?CONST_SYS_FALSE of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_SHOP_NO_TIMES})
	end.

%% 记录购买物品
log_buy_goods(_Player, _Sell, _GoodsId, ?CONST_SYS_FALSE) ->
	?ok;
log_buy_goods(#player{user_id = UserId, info = Info}, Sell, GoodsId, ?CONST_SYS_TRUE) ->
	case ets_api:lookup(?CONST_ETS_SECRET, 1) of
		?null ->
			?ok;
		#ets_secret{log_data = LogData} = Secret ->
			UserName = Info#info.user_name,
			NewLogData = lists:sublist([{UserId, UserName, Sell, GoodsId}|LogData], ?CONST_SHOP_SECRET_LOG_COUNT),
			ets_api:insert(?CONST_ETS_SECRET, Secret#ets_secret{log_data = NewLogData}),
			send_log_info(UserId, NewLogData)
	end.

%% 发送记录信息
send_log_info(UserId) ->
	LogData =
		case ets_api:lookup(?CONST_ETS_SECRET, 1) of
			?null ->
				[];
			#ets_secret{log_data = LogData2} ->
				LogData2
		end,
	send_log_info(UserId, LogData).
	
send_log_info(UserId, LogData) ->
	LogList = [{UserName, Sell, GId} || {_UserId, UserName, Sell, GId} <- LogData],
	Packet = shop_api:msg_sc_log_info(LogList),
	misc_packet:send(UserId, Packet).

%% 初始化信息
init_info(UserId) ->
	SecretInfo =
		case get_secret_info(UserId) of
			?null ->
				init_secret_info(UserId);
			Tuple ->
				Tuple
		end,
	#ets_secret_info{free = Free, buy_times = BuyTimes, score = Score, data = Data} = SecretInfo,
	#ets_secret{end_time = EndTime} = ets_api:lookup(?CONST_ETS_SECRET, 1),
	RestTime = erlang:max(EndTime - misc:seconds(), 0),
	F = fun({Id, #rec_shop_secret{goods_id = GoodsId, count = Count, price = Price, sell = Sell}, State}) ->
				{Id, GoodsId, Count, Price, Sell, State}
		end,
	DataList = [F(E) || E <- Data],
	Packet = shop_api:msg_sc_secret_init(RestTime,
										 erlang:max(BuyTimes, 0),
										 ?CONST_SHOP_SECRET_BUY_TIMES,
										 Score,
										 erlang:max(?CONST_SHOP_SECRET_FREE - Free, 0),
										 DataList
										),
	misc_packet:send(UserId, Packet).

%% ====================================================================
%% Internal functions
%% ====================================================================
%% get_rare_list() ->
%% 	List = data_shop:get_shop_score(),
%% 	F = fun(#rec_shop_score{goods_id = GoodsId, rare = ?CONST_SYS_TRUE}, Acc) ->
%% 				[GoodsId | Acc];
%% 		   (_, Acc) ->
%% 				Acc
%% 		end,
%% 	lists:foldl(F, [], List).

%% 初始化个人信息
init_secret_info(UserId) ->
	List 		= data_shop:get_shop_secret(),
	RandList	= rand_list(List),
	IdList		= lists:seq(1, ?CONST_SHOP_SECRET_COUNT),
	Data		= lists:zip3(IdList, RandList, lists:duplicate(?CONST_SHOP_SECRET_COUNT, ?CONST_SHOP_SECRET_ABLE)),
	SecretInfo	=
		case get_secret_info(UserId) of
			?null ->
				#ets_secret_info{
								 user_id = UserId,
								 data = Data,
								 buy_times = ?CONST_SHOP_SECRET_BUY_TIMES
								};
			Tuple when is_record(Tuple, ets_secret_info) ->
				Tuple#ets_secret_info{data = Data}
		end,
	update_secret_info(SecretInfo),
	SecretInfo.

rand_list(List) ->
	Sum = lists:sum([Tuple#rec_shop_secret.rate || Tuple <- List]),
	rand_list(List, Sum, ?CONST_SHOP_SECRET_COUNT, []).

rand_list(_List, _Sum, ?CONST_SYS_FALSE, Acc) -> Acc;
rand_list(List, Sum, Count, Acc) ->
	Rand = misc:rand(1, Sum),
	Data = get_data(List, Rand),
	rand_list(List, Sum, Count - 1, [Data | Acc]).

get_data([#rec_shop_secret{rate = Rate} = Tuple | _List], Rand) when Rate >= Rand ->
	Tuple;
get_data([#rec_shop_secret{rate = Rate} | List], Rand) ->
	get_data(List, Rand - Rate).

get_secret_info(UserId) ->
	ets_api:lookup(?CONST_ETS_SECRET_INFO, UserId).

update_secret_info(SecretInfo) ->
	SecretInfo2 = SecretInfo#ets_secret_info{update_time = misc:seconds()},
	ets_api:insert(?CONST_ETS_SECRET_INFO, SecretInfo2).

insert_secret_info(SecretInfo) ->
	ets_api:insert(?CONST_ETS_SECRET_INFO, SecretInfo).

delete_secret_info(UserId) ->
	ets_api:delete(?CONST_ETS_SECRET_INFO, UserId).
