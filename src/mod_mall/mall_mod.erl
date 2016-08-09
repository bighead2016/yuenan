%% Author: Administrator
%% Created: 2012-8-1
%% Description: TODO: Add description to mall_mod
-module(mall_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%% 
-export([
 		 buy/5,
		 buy_sale/5,
		 discount_data/0,
		 ride_up/5,
		 insert_mall/1
		]).

%%
%% API Functions
			
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 限时折扣物品
discount_data() -> 
	case ets_mall(?CONST_MALL_DISCOUNT) of
		?null ->
			{?error,?TIP_MALL_NO_DISCOUNT};
		{_,Time,List} ->
			List2 	= discount_data(List),
			{?ok,Time,List2}  
	end.

discount_data(List) ->
	[{D#rec_mall.goods_id,D#rec_mall.num} || D <- List,is_record(D,rec_mall)].
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 购买折扣物品
buy_sale(Player = #player{user_id = UserId, net_pid = Pid},Id,GoodsId,Num, IsBind2First) ->
	try		
		?ok					= check_buy_num(Num),		
		{?ok,RecMallSale} 	= rec_mall_sale(Id),
		?ok					= check_sale_time(RecMallSale),
		{?ok,Bind,CostType,Cost,NumMax} = get_sale_goods(RecMallSale,GoodsId),
		{?ok, IsBind}       = check_money(UserId,CostType, Cost, IsBind2First),
		
		EndTime 			= RecMallSale#rec_mall_sale.end_time,
		MallData			= ets_mall_sale(UserId),
		{?ok,MallData2}		= check_sale_num(MallData,Id,GoodsId,Num,NumMax,EndTime),
		
        IsBind2             = (?CONST_GOODS_BIND =:= Bind) orelse (?CONST_GOODS_BIND =:= IsBind),
		{?ok, Player2, Packet} = check_bag(Player, GoodsId, IsBind2, Num),
		{?ok,Player3} 		= check_minus_money(Player2,CostType, Cost, IsBind2First),
%%         Player4             = furnace_fusion_api:add_style_default(Player3, GoodsId),
		Packet2 			= message_api:msg_notice(?TIP_MALL_SUCCESS),
		Now					= misc:seconds(),
		MallData3			= clean_mall_sale(Now,MallData2,[]),
		
		misc_packet:send(Pid, <<Packet/binary,Packet2/binary>>),
		insert_mall_sale({UserId,MallData3}),
		admin_log_api:log_mall(Player3, GoodsId, Num, CostType, Cost, Now),
%%         admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_MALL_GET, GoodsId, Num, Now),
		welfare_api:add_pullulation(Player3, ?CONST_WELFARE_MALL, 0, 1)
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.	

%% 检查折扣时间
check_sale_time(RecMallSale) ->
	StartTime 	= RecMallSale#rec_mall_sale.start_time,
	EndTime 	= RecMallSale#rec_mall_sale.end_time,
	Time		= misc:seconds(),
	if
		StartTime < Time andalso Time < EndTime -> 
			?ok;
		?true ->
			throw({?error,?TIP_COMMON_BAD_ARG})
	end.

%% 取得折扣物品信息
get_sale_goods(RecMallSale,GoodsId) ->
	GoodsList 	= RecMallSale#rec_mall_sale.goods, 
	case lists:keyfind(GoodsId, 1, GoodsList) of
		?false ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		{_,Bind,CostType,_,Price,Num} ->
			{?ok,Bind,CostType,Price,Num}
	end.

%%　检查购买折扣物品数量
%% check_sale_num(_MallData,_Id,_GoodsId,Num,NumMax,_) when Num > NumMax ->
%% 	throw({?error,?TIP_COMMON_BAD_ARG});
check_sale_num(MallData,Id,GoodsId,Num,_NumMax,EndTime) ->
	Key	= {Id,GoodsId},
	case lists:keytake(Key, #mall_sale.key, MallData) of
		?false ->
			MallSale 	= init_mall_sale(Key,Num,EndTime),
			MallData2 	= [MallSale | MallData],
			{?ok,MallData2};
%% 		{value,#mall_sale{num = N},_} when N + Num > NumMax ->
%% 			throw({?error,?TIP_MALL_DICOUNT_COUNT}); 
		{value,MallSale,MallData2} ->
			Num2		= MallSale#mall_sale.num + Num,
			MallSale2	= MallSale#mall_sale{num = Num2}, 
			MallData3	= [MallSale2 | MallData2],
			{?ok,MallData3}
	end.

clean_mall_sale(_Now,[],List) ->
	List;
clean_mall_sale(Now,[MallSale|L],List) ->
	if
		Now > MallSale#mall_sale.end_time ->
			clean_mall_sale(Now,L,List); 
		?true ->
			clean_mall_sale(Now,L,[MallSale|List])
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 购买
buy(Player = #player{user_id = UserId, net_pid = Pid},Type,GoodsId,Num, IsBind2First)
  when Type =:= ?CONST_MALL_DISCOUNT -> % 限时抢购
	try
		?ok					= check_buy_num(Num),	
		{?ok,EndTime,MallList,MallD2}	= check_buy_discount(Type,UserId,GoodsId,Num),
		{?ok,Bind,CostType,Price,_} = get_mall_data2(Type,GoodsId),
		Cost 				= Price * Num,
		{?ok, IsBind}		= check_money(UserId,CostType, Cost, IsBind2First),
        IsBind2             = (?CONST_GOODS_BIND =:= Bind) orelse (?CONST_GOODS_BIND =:= IsBind),
		{?ok, Player2, Packet} = check_bag(Player,GoodsId,IsBind2,Num),
		{?ok,Player3} 		= check_minus_money(Player2,CostType, Cost, IsBind2First),
%%         Player4             = furnace_fusion_api:add_style_default(Player3, GoodsId),
		Packet2 			= message_api:msg_notice(?TIP_MALL_SUCCESS),
		Mall 				= {Type,EndTime,MallList},
		RealMallList		= discount_data(MallList),
		Packet3 			= mall_api:msg_data_recv(EndTime, RealMallList),
		
		misc_packet:send(Pid, <<Packet/binary,Packet2/binary,Packet3/binary>>),
 		insert_mall(Mall), 
		insert_mall_discount(MallD2), 
        Now                 = misc:seconds(),
		admin_log_api:log_mall(Player3, GoodsId, Num, CostType, Cost, Now),
		welfare_api:add_pullulation(Player3, ?CONST_WELFARE_MALL, 0, 1)
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{?ok,Player};
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_MALL_TYPE}
	end;

%%限时购买
buy(Player = #player{user_id = UserId,info = Info, net_pid = Pid},Type,GoodsId,Num, IsBind2First)
  when Type =:= ?CONST_MALL_SELL_IN_TIME-> % 限时购买
	try
		yunying_activity_api:check_activity_start(?CONST_MALL_SELL_IN_TIME),
		?ok					= check_buy_num(Num),
		VipLv 				= player_api:get_vip_lv(Info),
		{?ok,Bind,CostType,Price,LvRequest} = get_mall_data2(Type,GoodsId),		
		Cost 				= Price * Num,
        {?ok, IsBind}       = check_money(UserId,CostType, Cost, IsBind2First),
        IsBind2             = (?CONST_GOODS_BIND =:= Bind) orelse (?CONST_GOODS_BIND =:= IsBind),
		?ok					= check_vip_lv(VipLv,LvRequest,Type),
		{?ok, Player2, Packet} = check_bag(Player,GoodsId,IsBind2,Num),
		{?ok, Player3}      = check_minus_money(Player2,CostType, Cost, IsBind2First),
		Packet2 			= message_api:msg_notice(?TIP_MALL_SUCCESS),	
		misc_packet:send(Pid, <<Packet/binary,Packet2/binary>>),
		admin_log_api:log_mall(Player, GoodsId, Num, CostType, Cost, misc:seconds()),
		welfare_api:add_pullulation(Player3, ?CONST_WELFARE_MALL, 0, 1)
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{?ok,Player};
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_MALL_TYPE}
	end;

buy(Player = #player{user_id = UserId,info = Info,bag = Bag,net_pid = Pid},Type,GoodsId,Num, IsBind2First) -> 
	try
		?ok					= check_buy_num(Num),
		VipLv 				= player_api:get_vip_lv(Info),
		
		{?ok,Bind,CostType,Price,LvRequest} = get_mall_data2(Type,GoodsId),		
		Cost 				= Price * Num,
        {?ok, IsBind}       = check_money(UserId,CostType, Cost, IsBind2First),
        IsBind2             = (?CONST_GOODS_BIND =:= Bind) orelse (?CONST_GOODS_BIND =:= IsBind),
		?ok					= check_vip_lv(VipLv,LvRequest,Type),
		{?ok, Player2, Packet} = check_bag(Player,GoodsId,IsBind2,Num),
		{?ok, Player3}      = check_minus_money(Player2,CostType, Cost, IsBind2First),
%%         Player3             = furnace_fusion_api:add_style_default(Player2_2, GoodsId),
		Packet2 			= message_api:msg_notice(?TIP_MALL_SUCCESS),	
		misc_packet:send(Pid, <<Packet/binary,Packet2/binary>>),
		admin_log_api:log_mall(Player, GoodsId, Num, CostType, Cost, misc:seconds()),
		welfare_api:add_pullulation(Player3, ?CONST_WELFARE_MALL, 0, 1)
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{?ok,Player};
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_MALL_TYPE}
	end.

check_buy_discount(Type,UserId,GoodsId,Num) ->
	{_,EndTime,List} 	= ets_mall(Type),
	MallD				= ets_mall_discount(UserId,GoodsId),
	{?ok,MallD2}		= check_discount_num(MallD,Num),
	?ok					= check_discount_time(EndTime),  
	{?ok,MallList} 		= check_discount_goods(List,GoodsId,Num),
	{?ok,EndTime,MallList,MallD2}.

check_discount_num(_,Num) when Num > 1 ->
	throw({?error,?TIP_MALL_DICOUNT_COUNT});
check_discount_num(MallD,Num) ->
	MNum	= MallD#mall_discount.num,
	if
		MNum + Num > 1 ->
			throw({?error,?TIP_MALL_DICOUNT_COUNT});
		?true -> 
			MallD2	= MallD#mall_discount{num = MNum + Num},
			{?ok,MallD2}
	end.			 

%% 检查购买数量
check_buy_num(0) ->
	throw({?error, ?TIP_MALL_ZERO});
check_buy_num(_) -> ?ok.

%% 检查VIP等级
check_vip_lv(VipLv,LvRequest,?CONST_MALL_VIP) when VipLv < LvRequest ->
	throw({?error, ?TIP_MALL_VIP});
check_vip_lv(_,_,_) -> ?ok.

%% 背包检查
check_bag(Player, GoodsId, Bind, Num) ->
    Bag = Player#player.bag,
	case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
		?false ->		
			GoodsList = goods_api:make(GoodsId, Bind, Num),
			case data_goods:get_goods(GoodsId) of
				#goods{type = Type} ->
					if Type =:= ?CONST_GOODS_EQUIP_STONE ->
						   StoneLevel = furnace_soul_api:get_stone_lv(GoodsId),
						   yunying_activity_mod:add_activity_stone_value(Player#player.user_id, StoneLevel, Num, 1);    %% 购买宝石送积分
					?true ->
						skip
					end;
				_ ->
					skip
			end,
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MALL_GET, 1, 1, 0, 0, 0, 1, []) of
				{?ok, Player2, _, Packet} ->
					{?ok, Player2, Packet};
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end;
		_ -> throw({?error, ?TIP_MALL_BAG})
	end.

%% 扣取金币
check_money(UserId,CostType, Value) ->
	case player_money_api:check_money(UserId, CostType, Value) of
		{?error,ErrorCode} ->
			throw({?error, ErrorCode});
		_ -> ?ok
	end.

check_money(UserId,CostType, Value, ?CONST_SYS_TRUE) ->
    case player_money_api:read_money(UserId) of
        {?ok, #money{cash_bind_2 = CashBind2}} when CashBind2 > 0 ->
        	case player_money_api:check_money(UserId, CostType, Value) of
        		{?error,ErrorCode} ->
        			throw({?error, ErrorCode});
        		{?ok, _, _} when ?CONST_SYS_CASH =:= CostType -> 
                    {?ok, ?CONST_GOODS_BIND};
        		{?ok, _, _} -> 
                    {?ok, ?CONST_GOODS_UNBIND}
        	end;
        {?ok, _} ->
        	case player_money_api:check_money(UserId, CostType, Value) of
        		{?error,ErrorCode} ->
        			throw({?error, ErrorCode});
        		{?ok, _, _} -> 
                    {?ok, ?CONST_GOODS_UNBIND}
        	end;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end;
check_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_SYS_FALSE) ->
	case player_money_api:check_money(UserId, ?CONST_SYS_CASH_ONLY, Value) of
		{?error,ErrorCode} ->
			throw({?error, ErrorCode});
		{?ok, _, _} -> 
            {?ok, ?CONST_GOODS_UNBIND}
	end;
check_money(UserId,CostType, Value, ?CONST_SYS_FALSE) ->
	case player_money_api:check_money(UserId, CostType, Value) of
		{?error,ErrorCode} ->
			throw({?error, ErrorCode});
		{?ok, _, _} -> 
            {?ok, ?CONST_GOODS_UNBIND}
	end.
		
check_minus_money(Player,CostType, Value, _IsBind2First) when CostType =:= ?CONST_MALL_BUY_POINT-> %% 扣取充值积分
	check_minus_buy_point(Player,Value);
check_minus_money(Player,?CONST_SYS_CASH, Value, ?CONST_SYS_TRUE) ->
	UserId 	= Player#player.user_id,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_MALL_COST) of
		?ok ->
			{?ok,Player};
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
	end;
check_minus_money(Player,?CONST_SYS_CASH, Value, ?CONST_SYS_FALSE) -> 
	UserId 	= Player#player.user_id,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, Value, ?CONST_COST_MALL_COST) of
		?ok ->
			{?ok,Player};
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
	end;
check_minus_money(Player,CostType, Value, _IsBind2First) -> %% 扣取金币
    ?MSG_ERROR("~p", [CostType]),
	UserId 	= Player#player.user_id,
	case player_money_api:minus_money(UserId, CostType, Value, ?CONST_COST_MALL_COST) of
		?ok ->	
			{?ok,Player};
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
	end.

%% 检查购买积分
check_minus_buy_point(Player,Value) ->
	case player_api:minus_buy_point(Player,Value) of
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		{?ok,Player2} ->
			{?ok,Player2}
	end.

%% 物品信息	
get_mall_data2(Type,GoodsId) ->
	case data_mall:get_mall({Type,GoodsId}) of
		?null ->
			throw({?error, ?TIP_MALL_GOODS_ERROR});
		#rec_mall{bind = Bind,  cost_type = CostType,c_price = Price, lv_request = LvRequest} ->
			{?ok,Bind,CostType,Price,LvRequest}
	end.

get_mall_data(Type,GoodsId) ->
	case data_mall:get_mall({Type,GoodsId}) of
		?null ->
			throw({?error, ?TIP_MALL_GOODS_ERROR});
		RecMall ->
			{?ok,RecMall}
	end.

%% 时间检查
check_discount_time(Time) ->
	T = misc:seconds(),
	if
		T >= Time -> %% 时间结束
			throw({?error, ?TIP_MALL_TIME_OVER});
		?true -> ?ok
	end.
%% 物品剩余数量检查
check_discount_goods(List,GoodsId,Num) ->
	case lists:keyfind(GoodsId, #rec_mall.goods_id, List) of
		Data = #rec_mall{num = Count} when Count >= Num ->
			Data2 	= Data#rec_mall{num = Count - Num},
			List2	= lists:keyreplace(GoodsId, #rec_mall.goods_id, List, Data2),
			{?ok,List2};
		_ ->
			throw({?error, ?TIP_MALL_GOODS_ENOUGH})	
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ride_up(Player = #player{user_id = UserId},CtnType,Grid,Type,GoodsId) ->
	try
		{?ok,EquipInfo} 		= horse_api:get_horse(Player,CtnType,UserId,Grid),			%% 坐骑信息
 		?ok						= check_horse_color(EquipInfo#goods.color),
 		Lv						= EquipInfo#goods.lv,
		{?ok,RecMall}			= get_mall_data(Type,GoodsId),
		{?ok,RecRide}			= get_mall_ride(RecMall#rec_mall.odds),
 		?ok 					= check_mall_up_lv(Lv,RecRide#rec_mall_ride.next_lv),
 		Goods					= goods_api:make(GoodsId, 1),
 		
		{?ok, Player2, Packet} 	= horse_api:mall_lv_up(Player, CtnType, UserId, Grid, Goods),
		Cost					= get_ride_cost(RecRide,Lv),
 		{?ok,Player3}			= check_minus_money(Player2,RecRide#rec_mall_ride.cost_type, Cost, 0),
 		Player4 				= player_attr_api:refresh_attr_equip(Player3), 		
 		misc_packet:send(Player#player.net_pid, Packet),
		{?ok,Player4}
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} -> {?ok,Player};
		throw:Return ->Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	

check_horse_color(?CONST_SYS_COLOR_RED) -> ?ok;
check_horse_color(_) ->
	throw({?error,?TIP_MALL_RIDE_COLOR}).

check_mall_up_lv(Lv,NewLv) when Lv < NewLv ->
	?ok;
check_mall_up_lv(_,_) ->
	throw({?error,?TIP_MALL_RIDE_LV}).

get_mall_ride(Id) ->
	case data_mall:get_mall_ride(Id) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		RecRide ->
			{?ok,RecRide}
	end.

get_ride_cost(RecRide,20) ->
	RecRide#rec_mall_ride.cost1;
get_ride_cost(RecRide,40) ->
	RecRide#rec_mall_ride.cost2;
get_ride_cost(RecRide,60) ->
	RecRide#rec_mall_ride.cost3;
get_ride_cost(RecRide,80) ->
	RecRide#rec_mall_ride.cost4;
get_ride_cost(_,_) ->
	throw({?error,?TIP_COMMON_BAD_ARG}).
	
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ets_mall_discount(UserId,GoodsId) -> 
	case ets_api:lookup(?CONST_ETS_MALL_DISCOUNT, {UserId,GoodsId}) of
		?null ->
			init_mall_discount(UserId,GoodsId,0);
		MallD ->
			MallD 
	end.
	
insert_mall_discount(MallD) -> 
	ets_api:insert(?CONST_ETS_MALL_DISCOUNT, MallD).

ets_mall(Type) ->
	ets_api:lookup(?CONST_ETS_MALL, Type).

insert_mall(Data) ->
	ets_api:insert(?CONST_ETS_MALL, Data).

ets_mall_sale(UserId) ->
	case ets_api:lookup(?CONST_ETS_MALL_SALE, UserId) of
		?null ->
			[];
		{_,MallData} ->
			MallData
	end.

insert_mall_sale(Data) ->
	ets_api:insert(?CONST_ETS_MALL_SALE, Data).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rec_mall_sale(Id) ->
	case data_mall:get_mall_sale(Id) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		RecMallSale ->
			{?ok,RecMallSale}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_mall_sale(Key,Num,EndTime) ->
	#mall_sale{key 		= Key, 
			   num 		= Num, 
			   end_time = EndTime 
			  }.

init_mall_discount(UserId,GoodsId,Num) ->
	#mall_discount{
				   key	= {UserId,GoodsId},
				   num 	= Num
				  }.
	

%%
%% Local Functions
%%

