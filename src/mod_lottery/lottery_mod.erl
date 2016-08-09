%% Author: Administrator
%% Created: 2012-8-11
%% Description: TODO: Add description to lottery_mod
-module(lottery_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
%% -export([]).
-compile(export_all).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   初始化ets 
%% @spec   initial_player_lottery/0
%% @param  无
%% @return ?ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
initial_player_lottery(UserId) ->
	ets:delete(?CONST_ETS_LOTTERY, UserId),
	WareHouse			= create(?CONST_LOTTERY_CAPACITY, []),
	#lottery{date		= 0,
			 moral		= 0,
			 warehouse	= WareHouse}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   更新玩家的lottery结构
%% @spec   update/1
%% @param  Status				玩家信息
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
update(Status) ->
	Today		= misc:date_num(),
	Lottery		= Status#player.lottery,
	NewLottery	= case Lottery#lottery.date of
					  Today ->
						  Lottery;
					  _ ->
						  Lottery#lottery{date	= Today,
										  moral	= 0}
				  end,
	Status#player{lottery = NewLottery}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝数据
%% @spec   lottery_info/1
%% @param  Status				玩家信息
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lottery_info(Status) ->
	NewStatus		= update(Status),
	UserId			= NewStatus#player.user_id,
	NewLottery		= NewStatus#player.lottery,
	WareHouse		= NewLottery#lottery.warehouse,
	WareHouseValue	= WareHouse#ctn.used,
	WareHouseMax	= ?CONST_LOTTERY_CAPACITY,
	MoralValue		= NewLottery#lottery.moral,
	MoralValueMax	= ?CONST_LOTTERY_MAXMORAL,
	MasterWork		= lottery_lookup(?CONST_LOTTERY_MASTERWORK),
	Harvest			= lottery_lookup(UserId),
	Bulletin		= MasterWork ++ Harvest,
	LotteryInfo		= [WareHouseValue, WareHouseMax, MoralValue, MoralValueMax, Bulletin],
	lottery_api:msg_sc_lottery_info(NewStatus, LotteryInfo),
	{?ok, NewStatus}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   查找告示牌数据
%% @spec   lottery_lookup/1
%% @param  UserId				玩家ID
%% @return Data					玩家告示牌数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lottery_lookup(UserId) ->
	case ets:lookup(?CONST_ETS_LOTTERY, UserId) of
		[] ->
			[];
		[Value | _] ->
			Value#bulletin.data
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝宝箱信息
%% @spec   warehouse_info/1
%% @param  Status				玩家信息
%% @return BinCtnInfo			淘宝宝箱数据
%% @return BinGoodsInfo			淘宝道具数据
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
warehouse_info(Status) ->
	UserId				= Status#player.user_id,
	Lottery				= Status#player.lottery,
	WareHouse			= Lottery#lottery.warehouse,
	{?ok, NewWareHouse}	= refresh(WareHouse),
	BinCtnInfo			= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, NewWareHouse#ctn.usable),
	GoodsList			= misc:to_list(NewWareHouse#ctn.goods),
	BinGoodsInfo		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	NewLottery			= Lottery#lottery{warehouse = NewWareHouse},
	NewStatus			= Status#player{lottery = NewLottery},
	{?ok, BinCtnInfo, BinGoodsInfo, NewStatus}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝道具信息
%% @spec   goods_info/1
%% @param  Status				玩家信息
%% @return BinCtnInfo			淘宝宝箱数据
%% @return BinGoodsInfo			淘宝道具数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
goods_info(Status) ->
	UserId			= Status#player.user_id,
	Lottery			= Status#player.lottery,
	WareHouse		= Lottery#lottery.warehouse,
	BinCtnInfo		= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, WareHouse#ctn.usable),
	GoodsList		= misc:to_list(WareHouse#ctn.goods),
	BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
	{?ok, BinCtnInfo, BinGoodsInfo}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝
%% @spec   draw_lottery/3
%% @param  Status				玩家信息
%% @param  LotteryId			淘宝宝箱ID
%% @param  LotteryMode			淘宝抽奖方式
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
draw_lottery(Status, LotteryId, LotteryMode) ->
	UserId					= Status#player.user_id,
	VipLevel				= player_api:get_vip_lv(Status),
	Lottery					= Status#player.lottery,
	WareHouse				= Lottery#lottery.warehouse,
	MoralValue				= Lottery#lottery.moral,
	RecLottery				= data_lottery:get_lottery_init(LotteryId),
	{Times, Deduction, Space}	= lottery_deduction(LotteryMode, RecLottery#rec_lottery.information),
	{?ok, Money}				= player_money_api:read_money(UserId),
	{MoneyFlag, DeductMode}		= lottery_category(LotteryId, Deduction, Money),
	{?ok, WareHouseValue}		= empty_count(WareHouse),
	VipFlag						= VipLevel >= LotteryMode,
	WareHouseFlag				= WareHouseValue >= Space,
	?MSG_DEBUG("~nVipFlag=~p~nMoneyFlag=~p~nWareHouseFlag=~p~n", [VipFlag, MoneyFlag, WareHouseFlag]),
	case {VipFlag, MoneyFlag, WareHouseFlag} of
		{?true, ?true, ?true} ->
			GoodsTuple			= lottery_goods(Status, RecLottery, LotteryMode, Times, []),
			case update_warehouse(UserId, WareHouse, GoodsTuple) of
				{?ok, NewWareHouse} ->					
					case LotteryMode of
						?CONST_LOTTERY_OPENSINGLE ->
							?ok;
						_ ->
							TimesStr	= misc:to_list(Times),
							TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_SUCCESS,  [{0, TimesStr}]),
							misc_packet:send(UserId, TipsPacket)
					end,
					case player_money_api:minus_money(UserId, DeductMode, Deduction, ?CONST_COST_LOTTERY_DRAW) of %TODO FUNID
						?ok ->
							NewLottery	= Lottery#lottery{moral		= moral(MoralValue, Times),
														  warehouse	= NewWareHouse},
							NewStatus	= Status#player{lottery		= NewLottery},
							goods_info(NewStatus),
							{?ok, NewStatus};
						{?error, _ErrorCode} ->
							{?ok, Status}
					end;
				{?error, _ErrorCode} ->
					{?ok, Status}
			end;
		{?false, _, _} ->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Status};
		{_, ?false, _} ->
			TipsPacket	= case LotteryId of
							  ?CONST_LOTTERY_OPENSINGLE ->
								  message_api:msg_notice(?TIP_COMMON_GOLD_NOT_ENOUGH);
							  _ ->
								  message_api:msg_notice(?TIP_COMMON_CASH_NOT_ENOUGH)
						  end,
			misc_packet:send(UserId, TipsPacket),
			{?ok, Status};
		{_, _, ?false} ->
			TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_WAREHOUSE_INSUFFICIENCY),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Status}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝抽奖信息
%% @spec   lottery_deduction/2
%% @param  LotteryMode			玩家信息
%% @param  ExpenseTuple			淘宝宝箱ID
%% @param  Times				淘宝抽奖次数
%% @return Deduction			淘宝抽奖消费
%% @return Space				淘宝抽奖占用宝箱空间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lottery_deduction(LotteryMode, ExpenseTuple) ->
	case lists:keysearch(LotteryMode, 1, ExpenseTuple) of
		{value, {_, Times, Deduction, Space}} ->
			{Times, Deduction, Space};
		?false ->
			{0, 0, 0}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝抽奖信息
%% @spec   lottery_category/2
%% @param  LotteryMode			玩家信息
%% @param  ExpenseTuple			淘宝宝箱ID
%% @param  Times				淘宝抽奖次数
%% @return Deduction			淘宝抽奖消费
%% @return Space				淘宝抽奖占用宝箱空间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lottery_category(LotteryId, Deduction, Money) ->
	case LotteryId of
		?CONST_LOTTERY_FIRSTCLASS ->
			Own			= Money#money.gold + Money#money.gold_bind,
			case Own >= Deduction of
				?true ->
					{?true, ?CONST_SYS_GOLD_BIND};
				?false ->
					{?false, ?CONST_SYS_GOLD_BIND}
			end;
		?CONST_LOTTERY_SECONDCLASS ->
			Own			= Money#money.cash + Money#money.cash_bind,
			case Own >= Deduction of
				?true ->
					{?true, ?CONST_SYS_BCASH_FIRST};
				?false ->
					{?false, ?CONST_SYS_BCASH_FIRST}
			end;
		?CONST_LOTTERY_THIRDCLASS ->
			Own			= Money#money.cash + Money#money.cash_bind,
			case Own >= Deduction of
				?true ->
					{?true, ?CONST_SYS_BCASH_FIRST};
				?false ->
					{?false, ?CONST_SYS_BCASH_FIRST}
			end
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝道具信息
%% @spec   lottery_goods/5
%% @param  Status				玩家信息
%% @param  RecLottery			淘宝基础数据
%% @param  Mode					淘宝抽奖方式
%% @param  Times				淘宝抽奖次数
%% @param  Acc					淘宝抽奖道具
%% @return Acc					淘宝抽奖道具
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lottery_goods(_Status, RecLottery, _Mode, Times, Acc) when is_record(RecLottery, rec_lottery) andalso Times =< 0 ->
	[] ++ Acc;
lottery_goods(Status, RecLottery, Mode, Times, Acc) when is_record(RecLottery, rec_lottery) andalso Times > 0 ->
	UserId		= Status#player.user_id,
	Info		= Status#player.info,
	UserName	= Info#info.user_name,
	SeriesList	= RecLottery#rec_lottery.formula,
	SeriesSum	= RecLottery#rec_lottery.sum,
	Tuple		= RecLottery#rec_lottery.data,
	Category	= misc_random:odds_one(SeriesList, SeriesSum),
	case lists:keyfind(Category, #lottery_data.id, Tuple) of
		?false ->
			case Mode of
				?CONST_LOTTERY_FIRSTCLASS ->
					lottery_api:msg_sc_draw_lottery(Status, ?false, []);
				_ ->
					?ok
			end,
			[];
		Data ->
			{GoodsId, BindState, Count, IsShow}	= misc_random:odds_one(Data#lottery_data.data, Data#lottery_data.sum),
			update_bulletin(UserId, UserName, GoodsId, IsShow),
			GoodsTuple 	= [{GoodsId, BindState, Count}],
			case Mode of
				?CONST_LOTTERY_OPENSINGLE ->
					lottery_api:msg_sc_draw_lottery(Status, ?true, [{Category, GoodsId, Count}]);
				_ ->
					?ok
			end,
			lottery_goods(Status, RecLottery, Mode, Times - 1, GoodsTuple ++ Acc)
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝道具信息
%% @spec   update_warehouse/3
%% @param  UserId				玩家ID
%% @param  WareHouse			淘宝仓库
%% @param  GoodsTuple			淘宝道具列表
%% @return NewWareHouse			淘宝仓库
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
update_warehouse(UserId, WareHouse, GoodsTuple) ->
	NewGoodsTuple	= make_goods(GoodsTuple),
	case set_stack_list(UserId, WareHouse, NewGoodsTuple) of
		{?ok, NewWareHouse, GoodsPacket} ->
			WareHousePacket	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, NewWareHouse#ctn.usable),
			Packet			= <<WareHousePacket/binary, GoodsPacket/binary>>,
			misc_packet:send(UserId, Packet),
			{?ok, NewWareHouse};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝道具列表
%% @spec   make_goods/1
%% @param  GoodsTuple			淘宝道具列表
%% @return GoodsTuple			淘宝道具列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
make_goods([]) ->
	[];
make_goods([Head | Tail]) ->
	{GoodsId, BindState, Count}	= Head,
	Goods				= goods_api:make(GoodsId, BindState, Count),
	Goods ++ make_goods(Tail).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝累积奖励
%% @spec   accumulate_award/3
%% @param  Status				玩家信息
%% @param  CategoryLen			奖励道具个数
%% @param  Category				奖励道具总类
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
accumulate_award(Status, CategoryLen, Category) ->
	UserId					= Status#player.user_id,
	Lottery					= Status#player.lottery,
	WareHouse				= Lottery#lottery.warehouse,
	MoralValue				= Lottery#lottery.moral,
	MoralFlag				= MoralValue >= ?CONST_LOTTERY_BASEMORAL,
	{?ok, WareHouseValue}	= empty_count(WareHouse),
	WareHouseFlag			= WareHouseValue >= CategoryLen,
	?MSG_PRINT("~nMoralFlag=~p~nWareHouseFlag=~p~n", [MoralFlag, WareHouseFlag]),
	case {MoralFlag, WareHouseFlag} of
		{?true, ?true} ->
			GoodsTuple		= accumulator_goods(Status, Category, []),
			Fun				= fun(Goods, Acc) ->
									  {GoodsId, Count}	= Goods,
									  [{0, misc:to_list(GoodsId)}, {0, misc:to_list(Count)}] ++ Acc
							  end,
			TipsGoodsTuple	= lists:foldr(Fun, [], GoodsTuple),
			TipsPacket		= message_api:msg_notice(?TIP_LOTTERY_HARVEST_INFO, TipsGoodsTuple),
			case update_warehouse(UserId, WareHouse, GoodsTuple) of
				{?ok, NewWareHouse} ->
					NewLottery		= Lottery#lottery{moral		= MoralValue - ?CONST_LOTTERY_BASEMORAL,
													  warehouse	= NewWareHouse},
					NewStatus		= Status#player{lottery		= NewLottery},
					goods_info(NewStatus),
					{?ok, NewStatus};
				{?error, _ErrorCode} ->
					TipsPacket		= message_api:msg_notice(?TIP_LOTTERY_WAREHOUSE_INSUFFICIENCY),
					misc_packet:send(Status#player.net_pid, TipsPacket),
					{?ok, Status}
			end;
		{?false, _} ->
			TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_MORAL_INSUFFICIENCY),
			misc_packet:send(Status#player.net_pid, TipsPacket),
			{?ok, Status};
		{_, ?false} ->
			TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_WAREHOUSE_INSUFFICIENCY),
			misc_packet:send(Status#player.net_pid, TipsPacket),
			{?ok, Status}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   淘宝累积奖励
%% @spec   accumulate_award/3
%% @param  Status				玩家信息
%% @param  Category				奖励道具总类列表
%% @param  Acc					奖励道具列表
%% @return Acc					奖励道具列表
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
accumulator_goods(_Status, [], Acc) ->
	[] ++ Acc;
accumulator_goods(Status, [{Head} | Tail], Acc) ->
	UserId			= Status#player.user_id,
	Info			= Status#player.info,
	UserName		= Info#info.user_name,
	Accumulator		= data_lottery:get_accumulator_init(Head),
	Formula			= Accumulator#rec_accumulator.formula,
	ExpectSum		= Accumulator#rec_accumulator.sum,
	{GoodsId, BindState, Count, IsShow}	= misc_random:odds_one(Formula, ExpectSum),
	update_bulletin(UserId, UserName, GoodsId, IsShow),
	GoodsTuple 	= [{GoodsId, BindState, Count}],
	accumulator_goods(Status, Tail, GoodsTuple ++ Acc).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   更新淘宝ETS
%% @spec   update_bulletin/4
%% @param  UserId				玩家ID
%% @param  UserName				玩家名称
%% @param  GoodsId				道具ID
%% @param  IsShow				是否展示
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
update_bulletin(UserId, UserName, GoodsId, IsShow) ->
	case IsShow =:= ?CONST_LOTTERY_SHOW of
		?true ->
			MasterWork	= {?CONST_LOTTERY_MASTERWORK, UserId, UserName, GoodsId},
			set_ets_lottery(?CONST_LOTTERY_DEFAULTUSERID, MasterWork);
		?false ->
			?false
	end,
	Harvest				= {?CONST_LOTTERY_HARVEST, UserId, UserName, GoodsId},
	set_ets_lottery(UserId, Harvest).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   更新淘宝ETS
%% @spec   fetch_goods/3
%% @param  Status				玩家信息
%% @param  FetchMode			拾取道具方式
%% @param  Index				道具索引
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fetch_goods(Status, FetchMode, Index) ->
	case FetchMode of
		?CONST_LOTTERY_FETCHSINGLE ->
			single(Status, Index);
		?CONST_LOTTERY_FETCHALL ->
			all(Status);
		_ ->
			{?ok, Status}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   拾取单个道具
%% @spec   single/2
%% @param  Status				玩家信息
%% @param  Index				道具索引
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
single(Status, Index) ->
	UserId			= Status#player.user_id,
	Lottery			= Status#player.lottery,
	ContainerFrom	= Lottery#lottery.warehouse,
	ContainerTo		= Status#player.bag,
	CtnTypeTo		= ?CONST_GOODS_CTN_BAG,
	IdxFrom			= Index,
	case outer_exchange(UserId, ContainerFrom, IdxFrom, CtnTypeTo, ContainerTo) of
		{?error, _ErrorCode} ->
			{?ok, Status};
		{?ok, NewContainerFrom, NewContainerTo, Packet} ->
			misc_packet:send(UserId, Packet),
			TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_TRANSFERENCE_SUCCESS),
			misc_packet:send(UserId, TipsPacket),
			NewLottery	= Lottery#lottery{warehouse	= NewContainerFrom},
			NewStatus	= Status#player{bag			= NewContainerTo,
										lottery		= NewLottery},
			{?ok, NewStatus}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   一键拾取
%% @spec   all/1
%% @param  Status				玩家信息
%% @return NewStatus			玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
all(Status) ->
	UserId			= Status#player.user_id,
	Lottery			= Status#player.lottery,
	ContainerFrom	= Lottery#lottery.warehouse,
	ContainerTo		= Status#player.bag,
	CtnTypeTo		= ?CONST_GOODS_CTN_BAG,
	IdxFrom			= 1,
	UsedFrom		= ContainerFrom#ctn.used,
	{?ok, UsableTo}	= ctn_bag2_api:empty_count(ContainerTo),
	case UsedFrom > 0 andalso UsableTo > 0 of
		?false ->
			{?ok, Status};
		?true ->
			Packet		= <<>>,
			{?ok, NewContainerFrom, NewContainerTo, NewPacket}	= 
				outer_exchange(UserId, ContainerFrom, IdxFrom, UsedFrom, CtnTypeTo, ContainerTo, UsableTo, Packet),
			misc_packet:send(UserId, NewPacket),
			NewLottery	= Lottery#lottery{warehouse	= NewContainerFrom},
			NewStatus	= Status#player{bag			= NewContainerTo,
										lottery			= NewLottery},
			{?ok, NewStatus}
	end.

%%
%% Local Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   新建一个容器
%% @name   create/2
%% @dep    ctn_mod:init(Max, Usable).
%% @param  Usable       容器最大容量
%% @param  GoodsList    初始物品列表
%% @return #ctn{} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
create(Usable, GoodsList) when is_number(Usable), is_list(GoodsList), erlang:length(GoodsList) =< Usable ->
    case ctn_mod:init(?CONST_LOTTERY_CAPACITY, Usable) of 
        {?ok, Container} ->
            {?ok, NewContainer, _ChangeList}	= set_list(0, Container, GoodsList),
            NewContainer;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器空格
%% @name   set_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_list(UserId, Container, GoodsList) ->
	case ctn_mod:set_list(Container, GoodsList) of
		{?ok, NewContainer, ChangeList} ->
			Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, NewContainer, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   放置物品列表到容器堆叠放置
%% @name   set_stack_list/2
%% @param  Container 容器
%% @param  GoodsList 物品列表
%% @return {ok, NewContainer, Packet} | {?error, ErrorCode}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_stack_list(UserId, Container, GoodsList) ->
	case ctn_mod:set_stack_list(Container, GoodsList) of
		{?ok, NewContainer, ChangeList} ->
			Packet		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, ChangeList, ?CONST_SYS_TRUE),
			{?ok, NewContainer, Packet};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器满了?
%% @name   is_full/1
%% @dep    ctn_mod:is_full(Container).
%% @param  Container 源容器
%%                   #ctn
%% @return false/true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
is_full(Container) ->
    ctn_mod:is_full(Container).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获得容器剩余容量
%% @name   empty_count/1
%% @dep    ctn_mod:empty_count(Container).
%% @param  Container 源容器
%%                   #ctn
%% @return 容器剩余容量
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
empty_count(Container) ->
	ctn_mod:empty_count(Container).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   容器间交换
%% @name   outer_exchange/4
%% @param  Container 源容器
%% @param  IdxFrom   源位置
%% @param  IdxTo     目标位置
%% @return {?ok, NewContainerFrom, NewContainerTo, Packet}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
outer_exchange(UserId, ContainerFrom, IdxFrom, CtnTypeTo, ContainerTo) ->
	case ctn_mod:empty_search(ContainerTo) of
		{?ok, ?null} ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
			misc_packet:send(UserId, TipsPacket),
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
		{?ok, IdxTo} ->
			{?ok, NewContainerFrom, ChangeListFrom, RemoveListFrom, NewContainerTo, ChangeListTo, RemoveListTo} = 
				ctn_mod:outer_exchange(ContainerFrom, IdxFrom, ContainerTo, IdxTo),
			BinGoodsInfoFrom	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, 0, ChangeListFrom, ?CONST_SYS_FALSE),
			BinRemoveFrom		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_LOTTERY_DEPOT, UserId, RemoveListFrom),
			BinGoodsInfoTo		= goods_api:msg_goods_list_info(CtnTypeTo, UserId, 0, ChangeListTo, ?CONST_SYS_FALSE),
			BinRemoveTo			= goods_api:msg_goods_list_remove(CtnTypeTo, UserId, RemoveListTo),
			Packet				= <<BinGoodsInfoFrom/binary, BinRemoveFrom/binary, BinGoodsInfoTo/binary, BinRemoveTo/binary>>,
			{?ok, NewContainerFrom, NewContainerTo, Packet}
	end.

outer_exchange(UserId, ContainerFrom, IdxFrom, UsedFrom, CtnTypeTo, ContainerTo, UsableTo, Packet) when UsedFrom > 0 andalso UsableTo > 0 ->
	case outer_exchange(UserId, ContainerFrom, IdxFrom, CtnTypeTo, ContainerTo) of
		{?error, ErrorCode} ->
			{?error, ErrorCode};
		{?ok, NewContainerFrom, NewContainerTo, ChangePacket} ->
			NewIdxFrom			= IdxFrom + 1,
			NewUsedFrom			= NewContainerFrom#ctn.used,
			{?ok, NewUsableTo}	= ctn_bag2_api:empty_count(NewContainerTo),
			NewPacket			= <<Packet/binary, ChangePacket/binary>>,
			outer_exchange(UserId, NewContainerFrom, NewIdxFrom, NewUsedFrom, CtnTypeTo, NewContainerTo, NewUsableTo, NewPacket)
	end;
outer_exchange(UserId, ContainerFrom, _IdxFrom, UsedFrom, _CtnTypeTo, ContainerTo, UsableTo, Packet) when UsedFrom =< 0 orelse UsableTo =< 0 ->
	case UsableTo =< 0 of
		?true ->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
			misc_packet:send(UserId, TipsPacket);
		?false ->
			TipsPacket	= message_api:msg_notice(?TIP_LOTTERY_TRANSFERENCE_SUCCESS),
			misc_packet:send(UserId, TipsPacket)
	end,
	{?ok, ContainerFrom, ContainerTo, Packet}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   整理容器
%% @name   refresh/1
%% @dep    .
%% @param  Container 源容器
%%                   #ctn
%% @return {?ok, NewContainer}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh(Container) ->
    {?ok, GoodsTuple}			= move(Container#ctn.goods, 1, 1, Container#ctn.usable),
    {?ok, Container#ctn{goods	= GoodsTuple}}.

move(Tuple, Src, Dst, Max) when Src > Max orelse Dst > Max ->
	{?ok, Tuple};
move(Tuple, Src, Dst, Max) when Src >= Dst ->
	NewSrc				= Src + 1,
	move(Tuple, Src, NewSrc, Max);
move(Tuple, Src, Dst, Max) ->
	case erlang:element(Src, Tuple) =:= 0 of
		?true ->
			case erlang:element(Dst, Tuple) =/= 0 of
				?true ->
					NewSrc				= Src + 1,
					NewDst				= Dst + 1,
					{?ok, NewTuple}		= exchange(Tuple, Src, Dst),
					move(NewTuple, NewSrc, NewDst, Max);
				?false ->
					NewDst				= Dst + 1,
					move(Tuple, Src, NewDst, Max)
			end;
		?false ->
			NewSrc						= Src + 1,
			move(Tuple, NewSrc, Dst, Max)
	end.

exchange(Tuple, Src, Dst) ->
	SrcElem				= erlang:element(Src, Tuple),
	DstElem				= erlang:element(Dst, Tuple),
	SrcTuple			= erlang:setelement(Dst, Tuple, SrcElem),
	DstTuple			= erlang:setelement(Src, SrcTuple, DstElem),
	{?ok, DstTuple}.

tuple(List, Max) ->
    GoodsTuple			= erlang:make_tuple(Max, 0, []),
    tuple(List, 1, GoodsTuple).

tuple([], _Index, GoodsTuple) ->
    GoodsTuple;
tuple([Goods|List], Index, GoodsTuple) ->
    NewGoodsTuple		= setelement(Index, GoodsTuple, Goods#goods{idx = Index}),
    tuple(List, Index + 1, NewGoodsTuple).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   整理容器
%% @name   set_ets_lottery/2
%% @dep    
%% @param  UserId				玩家ID
%% @param  Bulletin				告示牌数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_ets_lottery(UserId, Bulletin) ->
	case ets:lookup(?CONST_ETS_LOTTERY, UserId) of
		[] ->
			AddValue			= [Bulletin],
			NewData				= #bulletin{user_id		= UserId,
											data		= AddValue},
			ets:insert(?CONST_ETS_LOTTERY, NewData);
		[Data | _] ->
			Value				= Data#bulletin.data,
			ValueLen			= length(Value),
			case ValueLen >= ?CONST_LOTTERY_BASESHOW of
				?true ->
					Tail		= lists:nthtail(?CONST_LOTTERY_BASESHOW, Value),
					DelValue	= delete_tail(Value, Tail),
					AddValue	= [Bulletin | DelValue],
					NewData		= Data#bulletin{data = AddValue},
					ets:insert(?CONST_ETS_LOTTERY, NewData);
				?false ->
					AddValue	= [Bulletin | Value],
					NewData		= Data#bulletin{data = AddValue},
					ets:insert(?CONST_ETS_LOTTERY, NewData)
			end
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   删除尾部数据
%% @name   delete_tail/2
%% @dep    
%% @param  Data					告示牌数据
%% @param  Tail					待删除数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
delete_tail(Data, []) ->
	Data;
delete_tail(Data, [Head | Tail]) ->
	NewData			= lists:delete(Head, Data),
	delete_tail(NewData, Tail).

moral(Moral, Addition) ->
	case Moral + Addition =< ?CONST_LOTTERY_MAXMORAL of
		?true ->
			Moral + Addition;
		?false ->
			?CONST_LOTTERY_MAXMORAL
	end.