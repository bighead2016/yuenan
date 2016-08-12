%% Author: Administrator
%% Created: 2012-8-1
%% Description: TODO: Add description to market_mod
-module(market_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([get_market_info/12, get_market_sale_info/1, sale_goods/6, get_out_date_goods/4, buy_goods/4,
		 check_buy_sale_goods/0, get_hot_search/1, get_market_hot_goods/3
		 ]).

-define(TAX_RATE, 0.9).


%%
%% API Functions
%%----------------------------------------------------------------------------------------------
%% @desc     查询所有竞拍信息/查询玩家竞拍信息/热门搜索
%% @spec     get_market_info/10
%% @param    SearchType:搜索类型  GoodsName:物品名称  GoodsType:物品类型 GoodsSubType:物品子类型
%% @param    LvDownLimit:等级下限 LvUpLimit:等级上限 Pro:职业限定 Color:物品颜色限定 page:跳转页数
%% @return   NewMarketsaleList:竞拍信息列表|NewMarketBuyList购买信息列表
%%----------------------------------------------------------------------------------------------
get_market_info(SearchType, GoodsName, Category, GoodsType, GoodsSubType, LvDownLimit, LvUpLimit, Pro, Color, Page, AttrType, Player) ->
	case SearchType of
		?CONST_MARKET_SEARCH_ALL_SALE_INFO -> 
			get_market_sale_info(GoodsName, Category, GoodsType, GoodsSubType, LvDownLimit, LvUpLimit, Pro, Color, Page, AttrType, Player);
		?CONST_MARKET_SEARCH_BUY_INFO -> 
			get_market_buy_info(GoodsName, Category, GoodsType, GoodsSubType, LvDownLimit, LvUpLimit, Pro, Color, Page, Player)
	end.

%% 查询所有竞拍查询
get_market_sale_info(<<>>, _, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, 99, 99, Page, _, Player) ->
	EtsSize 		= ets:info(?CONST_ETS_MARKET_SALE, size),
	MaxPage 		= misc:ceil(EtsSize/?CONST_MARKET_INFO_MAX),
	SaleList  		= ets_api:list(?CONST_ETS_MARKET_SALE),
	MarketSaleList	= filter_overdure_goods(SaleList, []),
	{MarketInfoNum, NewMarketInfoList} = divide_page_info(Page, MaxPage, MarketSaleList),
	update_hot_search(NewMarketInfoList),
	Packet 			= market_api:msg_sale_info(MarketInfoNum, NewMarketInfoList, Page),
	misc_packet:send(Player#player.net_pid, Packet);
get_market_sale_info(GoodsName, Category, GoodsType, GoodsSubType, LvDownLimit, LvUpLimit, Pro, Color, Page, AttrType, Player) ->
	GoodsNameList 	= 	misc:to_list(GoodsName),
	GoodsNameLen 	= 	erlang:length(GoodsNameList),
	
	{NewCategory, NewColor, NewPro, NewGoodsType, NewGoodsSubType} = filter_conditon(Category, GoodsType, GoodsSubType, Pro, Color),
	Pattern 		= #market_sale{category = NewCategory, goods_type = NewGoodsType, goods_sub_type = NewGoodsSubType, 
								   goods_color = NewColor, _ = '_'},
	SaleList 		= ets:match_object(?CONST_ETS_MARKET_SALE, Pattern),
	MarketSaleList	= filter_overdure_goods(SaleList, []),
	MarketSaleList1	= filter_by_pro(MarketSaleList, NewPro, []),
	
	MarketTempList1	= filter_by_goods_type(MarketSaleList1, Category, GoodsType, GoodsSubType, []),
	MarketSaleList2 = filter_by_attr_type(MarketTempList1, AttrType, []),
	MarketSaleInfoList =  case GoodsNameLen > ?CONST_SYS_FALSE of
							  ?true ->
								  F = fun(SaleInfo, MarketSaleInfo) when is_record(SaleInfo, market_sale)->
											  GoodsNameInfo = misc:to_list(SaleInfo#market_sale.goods_name),
											  case string:str(GoodsNameInfo, GoodsNameList) of
												  ?CONST_SYS_FALSE -> MarketSaleInfo;
												  _ -> [SaleInfo|MarketSaleInfo]
											  end;
										 (_, MarketSaleInfo) -> MarketSaleInfo
									  end,
								  lists:foldl(F, [], MarketSaleList2);
							  ?false -> MarketSaleList2
						  end,
	NewMarketSaleList	= if 
							  LvDownLimit =:= ?CONST_SYS_FALSE andalso LvUpLimit =:= ?CONST_SYS_FALSE ->
								  MarketSaleInfoList;
							  ?true ->
								  F1 = fun(SaleInfo, MarketSaleInfo) when is_record(SaleInfo, market_sale)->
											   if SaleInfo#market_sale.goods_level =< LvUpLimit andalso
												  SaleInfo#market_sale.goods_level >= LvDownLimit  
													-> [SaleInfo | MarketSaleInfo];
												  ?true -> MarketSaleInfo
											   end;
										  (_, MarketSaleInfo) -> MarketSaleInfo
									   end,
								  lists:foldl(F1, [], MarketSaleInfoList)
						  end,
	SaleInfoListNum = erlang:length(NewMarketSaleList),
	SaleInfoSize 	= misc:ceil(SaleInfoListNum/?CONST_MARKET_INFO_MAX),
	{SaleInfoListNum, NewMarketSaleInfoList} = divide_page_info(Page, SaleInfoSize, NewMarketSaleList),
	update_hot_search(NewMarketSaleInfoList),
	Packet 		    = market_api:msg_sale_info(SaleInfoListNum, NewMarketSaleInfoList, Page),
	misc_packet:send(Player#player.net_pid, Packet).

%% 查询玩家竞拍信息
get_market_buy_info(_, _, _, _, _, _, _, _, Page, Player) ->
	UserId			 = Player#player.user_id,
	UserName		 = (Player#player.info)#info.user_name,
	NowTime			 = misc:seconds(),
	MatchSpec 		 = ets:fun2ms(fun(BuyInfo) when (BuyInfo#market_buy.buyer_id == UserId) andalso
													(BuyInfo#market_buy.buyer_name == UserName) andalso
													(BuyInfo#market_buy.end_time > NowTime) -> BuyInfo 
								  end),
	BuyList 	 	 = ets:select(?CONST_ETS_MARKET_BUY, MatchSpec),
	BuyList1	     = filter_overdure_goods1(BuyList, []),	
	Num = erlang:length(BuyList1),
	MaxPage 		 = misc:ceil(Num/?CONST_MARKET_INFO_MAX),
	{Num, NewBuyList}= divide_page_info(Page, MaxPage, BuyList1),
	Packet  		 = market_api:msg_buy_info(Num, NewBuyList, Page),
	misc_packet:send(Player#player.net_pid, Packet).

%% 按物品名称搜索
get_market_hot_goods(Player, Page, GoodsName) ->
	GoodsNameList 	= misc:to_list(GoodsName),
	GoodsNameLen	= erlang:length(GoodsNameList),
	MarketSaleList  = ets_api:list(?CONST_ETS_MARKET_SALE),
	MarketSaleNum	= erlang:length(MarketSaleList),
	MaxPage 		= misc:ceil(MarketSaleNum/?CONST_MARKET_INFO_MAX),
	HotGoodsList	=  
		case GoodsNameLen > ?CONST_SYS_FALSE of
			?true ->
				F = fun(SaleInfo, MarketSaleInfo) when is_record(SaleInfo, market_sale)->
							GoodsNameInfo = misc:to_list(SaleInfo#market_sale.goods_name),
							case string:str(GoodsNameInfo, GoodsNameList) of
								?CONST_SYS_FALSE -> MarketSaleInfo;
								_ -> [SaleInfo|MarketSaleInfo]
							end;
					   (_, MarketSaleInfo) -> MarketSaleInfo
					end,
				lists:foldl(F, [], MarketSaleList);
			?false -> MarketSaleList
		end,
	List			 = filter_overdure_goods(HotGoodsList, []), 
	{Num, NewHotList}= divide_page_info(Page, MaxPage, List),
	Packet 			 = market_api:msg_sale_info(Num, NewHotList, Page),
	misc_packet:send(Player#player.net_pid, Packet).


%% 条件过滤
filter_conditon(Category, GoodsType, GoodsSubType, Pro, Color) ->
	NewCategory	   = if
						 Category =:= ?CONST_SYS_FALSE -> '_';
						 ?true -> Category
					 end,
	NewColor       = if 
						 Color =:= 99 ->  '_';
						 ?true -> Color
					 end,
	NewPro          = if 
						  Pro =:= 99 ->  99;
						  ?true -> Pro
					  end,
	NewGoodsType    = if 
						  GoodsType =:= ?CONST_SYS_FALSE ->  '_';
						  ?true -> GoodsType
					  end,
	NewGoodsSubType = if 
						  GoodsSubType =:= ?CONST_SYS_FALSE -> '_';
						  ?true -> GoodsSubType
					  end,
	{NewCategory, NewColor, NewPro, NewGoodsType, NewGoodsSubType}.

%% 分页
divide_page_info(Page, MaxPage, MarketInfoList) ->
	MarketInfoNum     = erlang:length(MarketInfoList),
	StartPos	      = if 
							Page =:= ?CONST_SYS_FALSE orelse Page > MaxPage -> 1;
							?true ->  (Page - 1) * ?CONST_MARKET_INFO_MAX + 1
						end,
	NewMarketInfoList = case MarketInfoNum > ?CONST_MARKET_INFO_MAX of
							?true ->
								lists:sublist(MarketInfoList, StartPos, ?CONST_MARKET_INFO_MAX);
							?false ->
								MarketInfoList
						end,
	{MarketInfoNum, NewMarketInfoList}.

%% 过滤过期物品
filter_overdure_goods([MarketInfo|RestList], Acc) ->
	EndTime		= MarketInfo#market_sale.end_time,
	Now			= misc:seconds(),
	NewAcc		= case EndTime > Now of
					  ?true -> [MarketInfo|Acc];
					  ?false -> Acc
				  end,
	filter_overdure_goods(RestList, NewAcc);
filter_overdure_goods([], Acc) ->
	Acc.

filter_overdure_goods1([MarketInfo|RestList], Acc) ->
	EndTime		= MarketInfo#market_buy.end_time,
	Now			= misc:seconds(),
	NewAcc		= case EndTime > Now of
					  ?true -> [MarketInfo|Acc];
					  ?false -> Acc
				  end,
	filter_overdure_goods1(RestList, NewAcc);
filter_overdure_goods1([], Acc) ->
	Acc.


%% 根据职业过滤
filter_by_pro([MarketSale|MarketSaleList], Pro, Acc)  ->
	case Pro =:= 99 of
		?true  -> [MarketSale|MarketSaleList];
		?false ->
			Pro1		= MarketSale#market_sale.goods_pro,
			case {Pro1 =:= Pro, Pro1 =:= ?CONST_SYS_FALSE} of
				{?false, ?false} ->
					filter_by_pro(MarketSaleList, Pro, Acc);
				{_, _} ->
					NewAcc = [MarketSale|Acc],
					filter_by_pro(MarketSaleList, Pro, NewAcc)
			end
	end;
filter_by_pro([], _, Acc) ->
	Acc.

%% 根据物品类型过滤
filter_by_goods_type([MarketSale|MarketSaleList], 10, 3, 0, Acc) ->
	GoodsSubType		= MarketSale#market_sale.goods_sub_type,
	case GoodsSubType =/= 6 of
		?true -> 
			NewAcc		= [MarketSale|Acc],
			filter_by_goods_type(MarketSaleList, 10, 3, 0, NewAcc);
		?false ->
			filter_by_goods_type(MarketSaleList, 10, 3, 0, Acc)
	end;
filter_by_goods_type([], _, _, _, Acc) -> Acc;
filter_by_goods_type(List, _, _, _, _) -> List.
	
%% 按宝石属性类型过滤
filter_by_attr_type(MarketSaleList, 0, _) -> MarketSaleList;
filter_by_attr_type([MarketSale|Tail], Type, Acc) ->
	AttrType			= MarketSale#market_sale.goods_attr_type,
	case AttrType =:= Type of
		?true -> 
			NewAcc		= [MarketSale|Acc],
			filter_by_attr_type(Tail, Type, NewAcc);
		?false ->
			filter_by_attr_type(Tail, Type, Acc)
	end;
filter_by_attr_type([], _, Acc) -> Acc.
%%----------------------------------------------------------------------------------
%% @desc     获取寄售信息
%% @spec     get_market_sale_info/1
%% @param    
%% @return   ?true | []
%%----------------------------------------------------------------------------------
%% 获取寄售信息
get_market_sale_info(Player) ->
	Now				= misc:seconds(),
	UserId		    = Player#player.user_id,
	UserName	    = (Player#player.info)#info.user_name,
	Pattern 		= #market_sale{seller_id = UserId, seller_name = UserName, _ = '_'},
	SaleInfoList 	= ets:match_object(?CONST_ETS_MARKET_SALE, Pattern),
	F		= fun(SaleInfo, Acc) when  SaleInfo#market_sale.end_time =< Now  andalso 
									   SaleInfo#market_sale.buyer_id =/= ?CONST_SYS_FALSE -> [SaleInfo|Acc];
				 (_, Acc) -> Acc
			  end,
	List	= lists:foldl(F, [], SaleInfoList),
	MarketSaleInfoList = SaleInfoList -- List,                                %% 去除已有买家的过期物品显示
	case is_list(MarketSaleInfoList) of
		?true ->	 
			Packet = market_api:msg_market_sale_list(MarketSaleInfoList),
			misc_packet:send(Player#player.net_pid, Packet);
		?false ->    
			[]
	end.
	
%%----------------------------------------------------------------------------------
%% @desc     寄售物品
%% @spec     sale_goods/1
%% @param    GoodsId:物品Id Grid:背包指定格子 InitPrice:初始价格 FixedPrice:一口价格
%% @return   {?ok, SaleInfo}|{?error, ErrorCode}
%%----------------------------------------------------------------------------------	
sale_goods(GoodsId, Grid, GoodsNum, Price, FixPrice, Player) ->
	InitPrice				= misc:ceil(Price),
	FixedPrice				= misc:ceil(FixPrice),
	UserId					= Player#player.user_id,
	UserName				= (Player#player.info)#info.user_name,
	PlayerBag				= Player#player.bag,
	try
		{?ok, GoodsTemp}	= read_goods_info(PlayerBag, Grid),
		GoodsState			= GoodsTemp#goods.bind,
		GoodsName 			= GoodsTemp#goods.name,
		GoodsLevel 			= GoodsTemp#goods.lv,
		GoodsPro 			= GoodsTemp#goods.pro,
		GoodsColor 			= GoodsTemp#goods.color,
		GoodsType 			= GoodsTemp#goods.type,
		GoodsSubType 		= GoodsTemp#goods.sub_type,
		Category			= get_goods_type(GoodsType, GoodsSubType),
		AttrType			= get_stone_type(GoodsType, GoodsTemp),
		Goods				= GoodsTemp#goods{count = GoodsNum},
		NowTime 			= misc:seconds(),
		EndTime 			= NowTime + ?CONST_SYS_ONE_DAY_SECONDS,
		StoneFlag			= furnace_soul_api:check_is_inset_stone(GoodsTemp),
		{?ok, CostGold}		= check_sale_goods(GoodsState, GoodsNum, InitPrice, FixedPrice, StoneFlag, Player),
		case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, CostGold, ?CONST_COST_MARKET_SALE) of
			?ok ->
				case sale_goods_from_bag(Grid, GoodsNum, Player) of
					{?error, ErrorCode} ->
						Packet		= market_api:msg_sc_sale_state(ErrorCode),
						misc_packet:send(Player#player.net_pid, Packet),
						player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, CostGold, ?CONST_COST_MARKET_RETURN),
						{?ok, Player};
					{?ok, NewPlayer, Packet} ->
						Result 		= 
							market_db_mod:insert_market_sale(UserId, UserName, 0, <<>>, Goods, GoodsName, Category, GoodsType, GoodsSubType, 
									 GoodsLevel, GoodsColor, GoodsPro, AttrType, InitPrice, FixedPrice, EndTime),
						case Result of
							{?ok, Data} ->
								MarketId	= Data#market_sale.sale_id,
								admin_log_api:log_market(Player, 0, MarketId, GoodsId, GoodsNum, Price, FixPrice, UserId),
								Packet1		= market_api:msg_sc_sale_state(?CONST_SYS_TRUE),
								misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
							{?error, ErrorCode} ->
								player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, CostGold, ?CONST_COST_MARKET_RETURN),
								Packet		= market_api:msg_sc_sale_state(ErrorCode),
								misc_packet:send(Player#player.net_pid, Packet)
						end,
						{?ok, NewPlayer}
				end;
			{?error, ErrorCode} ->  %%寄售铜钱不足
				?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
				{?ok, Player}
		end
	catch
		throw:{?error, ErrorReason} ->
			TipPacket 	= message_api:msg_notice(ErrorReason),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 读取物品信息
read_goods_info(PlayerBag, Grid) ->
	case ctn_bag2_api:read(PlayerBag, Grid) of
		{?ok, ?null} ->
			throw({?error, ?TIP_COMMON_SYS_ERROR});
		{?ok, GoodsTemp} ->
			{?ok, GoodsTemp}
	end.

%% 扣除背包里的物品
sale_goods_from_bag(Grid, GoodsNum,	Player) ->
	UserId			= Player#player.user_id,
	PlayerBag		= Player#player.bag, 
	case ctn_bag2_api:get_by_idx(UserId, PlayerBag, Grid, GoodsNum) of
		{?ok, Container, GoodsList, Packet } ->
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_MARKET_SALE, GoodsList, misc:seconds()),
			NewPlayer 		= Player#player{bag = Container},
			{?ok, NewPlayer, Packet};
		{?error, ErrorCode} ->
			?MSG_DEBUG("ErrorCode=~p~n", [ErrorCode]),
			{?error, ErrorCode} 
	end.
					
	
% 检查寄售物品
check_sale_goods(GoodsState, GoodsNum, InitPrice, FixedPrice, StoneFlag, Player) ->
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
 	CostGold 		= ?CONST_MARKET_KEEP_COST,             %% 保管费用固定1w铜钱
	Pattern 		= #market_sale{seller_id	= UserId, seller_name = UserName, _ = '_'},
	SaleGoodsList 	= ets:match_object(?CONST_ETS_MARKET_SALE, Pattern),
	SaleGoodsTotal 	= erlang:length(SaleGoodsList) +1,
	if 
		GoodsState  =:=     ?CONST_SYS_TRUE ->                                 %% 绑定物品不能寄售
			throw({?error, ?TIP_MARKET_NOT_ALLOW_SELL});
		InitPrice	=:=		?CONST_SYS_FALSE -> 								%% 初始价格不能为0
			throw({?error, ?CONST_MARKET_PRICE_ERROR});
		SaleGoodsTotal > ?CONST_MARKET_SELL_MAX ->   	      	 				%% 寄售达到上限
			throw({?error, ?TIP_MARKET_SALE_ACHEIEVE_MAX});
		(FixedPrice =/= ?CONST_SYS_FALSE) andalso (FixedPrice < InitPrice) ->  %% 一口价不能低于起始价
			throw({?error, ?TIP_MARKET_SALE_ACHEIEVE_MAX});
		InitPrice   > 		?CONST_MARKET_SET_PRICE_MAX ->					    %% 起始价超过最大限定
			throw({?error, ?TIP_MARKET_SET_PRICE_MAX});
		FixedPrice 	>		?CONST_MARKET_SET_PRICE_MAX ->      				%% 一口价超过最大限定
			throw({?error, ?TIP_MARKET_SET_PRICE_MAX});
		GoodsNum	=:= ?CONST_SYS_FALSE ->                     				%% 寄售物品数量不能为０
			throw({?error, ?TIP_MARKET_NUM_ERROR});
		StoneFlag   =:= ?true ->												%% 不能寄售带宝石物品
			throw({?error, ?TIP_MARKET_HAS_STONE});
		?true -> 
			{?ok, CostGold}
	end.

%% 寄售的物品按类型分类
get_goods_type(GoodsType, GoodsSubType) ->
		if
			GoodsType	=:= 1 ->         														  %% 装备
				1;
			GoodsType	=:= 9 andalso (GoodsSubType =:= 18 orelse GoodsSubType =:= 15) ->         %% 锻造材料和图纸
				2;
			GoodsType	=:= 9 andalso (GoodsSubType =:= 6 orelse GoodsSubType =:= 23 orelse GoodsSubType =:= 99)  -> %% 消耗品
				3;
			GoodsType	=:= 12 andalso GoodsSubType =:= 22 ->                                     %% 宝石
				4;
			?true ->                     %% 其它（蛋／技能书／礼包／珍藏品）
				10
		end.

%% 获取寄售物品的附魂信息
get_stone_type(12, Goods) ->
	GoodsId			= Goods#goods.goods_id,
	furnace_soul_api:get_stone_type(GoodsId);
get_stone_type(_, _Goods) ->
	0.
	
%%------------------------------------------------------------------------------------
%% @desc     取回过期物品
%% @spec     get_out_date_goods/4
%% @param    GoodsId:物品Id Id:寄售记录Id Type:一键领取/单个领取
%% @return   {?error, ErrorCode}
%%------------------------------------------------------------------------------------
get_out_date_goods(Type, Id, GoodsId, Player) ->
	case check_get_out_date_goods(Type, Id, GoodsId, Player) of
		{?ok, SaleInfoList} -> 
			case Type of
				?CONST_MARKET_ALL_FETCH_ONE_TIME ->               	 	%% 一键领取（列表）
					get_goods_all(SaleInfoList, Player);
				_ ->                                               		%% 单个领取
					get_goods_one_by_one(Id, GoodsId, Player)
			end;					
		{?error, ErrorCode} -> 
			Packet 		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			Player
	end.

%% 检查取回过期物品
check_get_out_date_goods(Type, Id, _GoodsId, Player) ->
%% 	NowTime 		= misc:seconds(),
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	case Type of
		?CONST_MARKET_ALL_FETCH_ONE_TIME ->  %% 一键领取
			MatchSpec 		= ets:fun2ms(fun(SaleInfo) when    (SaleInfo#market_sale.seller_id =:= UserId) 
											  		   andalso (SaleInfo#market_sale.seller_name =:= UserName) 
											  		   andalso (SaleInfo#market_sale.buyer_id =:= ?CONST_SYS_FALSE)
%% 											           andalso (SaleInfo#market_sale.end_time =< NowTime) 
										-> SaleInfo  end),
			SaleInfoList 	= ets_api:select(?CONST_ETS_MARKET_SALE, MatchSpec),
			{?ok, SaleInfoList};
		_ ->								 %% 单个领取
			SaleInfo 		= ets_api:lookup(?CONST_ETS_MARKET_SALE, Id),
			if
				is_record(SaleInfo, market_sale) 	=:= ?false 	->     			  %% 物品不存在
					{?error, ?TIP_COMMON_GOOD_NOT_EXIST};             
				SaleInfo#market_sale.buyer_id       =/= ?CONST_SYS_FALSE ->		  %% 物品已经有人竞拍
					{?error, ?TIP_MARKET_HAS_BUYER};
%% 				SaleInfo#market_sale.end_time 		> NowTime 	->     			  %% 没到期
%% 					{?error, ?TIP_MARKET_GOODS_NOT_OVERDURE};		
				SaleInfo#market_sale.seller_id 		=/= UserId ->                 %% 不是本人的物品
					{?error, ?CONST_MARKET_GOODS_NOT_MY};  
				?true ->
					{?ok, SaleInfo}
			end
	end.

get_goods_all(SaleInfoList, Player) ->
	SaleInfoListNum 	= erlang:length(SaleInfoList),
	if 
		SaleInfoListNum =:= 0 -> 
			Packet	 	= message_api:msg_notice(?TIP_MARKET_NOT_OVERDURE_GOODS),       %% 无过期物品
			misc_packet:send(Player#player.net_pid, Packet),
			Player;
		?true ->
			refresh_get_goods(SaleInfoList, 0, Player)
	end.

%% 一键领回过期物品
refresh_get_goods([SaleInfo|SaleInfoList], _AccResult, Player) ->
	UserId			= Player#player.user_id,
	Id				= SaleInfo#market_sale.sale_id,
	Goods			= SaleInfo#market_sale.goods,
	GoodsId			= Goods#goods.goods_id,
	GoodsList		= [Goods],
	Result =
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MARKET_RETURN, 1, 1, 0, 0, 0, 1, []) of
		{?ok, NewPlayer, _, Packet0}->
			misc_packet:send(Player#player.net_pid, Packet0),
			WhereList		= "sale_id = " ++ misc:to_list(Id) ++ " and seller_id = " ++ misc:to_list(UserId),
			case mysql_api:delete(game_market_sale, WhereList) of
				{?ok, _, _} ->
					market_api:ets_delete_market(?CONST_ETS_MARKET_SALE, Id),
					admin_log_api:log_market_get(UserId, Id, GoodsId),
					{?ok, NewPlayer};
				{?error, _ErrorCode} ->
%% 					TipPacket		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
%% 					misc_packet:send(Player#player.net_pid, TipPacket),
					{?TIP_COMMON_ERROR_DB, Player}
			end;
		{?error, ErrorCode2} ->
			{ErrorCode2, Player}
	end,
	case Result of
		{?ok, NewPlayer1} ->
			refresh_get_goods(SaleInfoList, ?ok, NewPlayer1);
		{ErrorCode1, NewPlayer2} ->
			refresh_get_goods([], ErrorCode1, NewPlayer2)
	end;
refresh_get_goods([], AccResult, NewPlayer) ->
	case AccResult of
		?ok ->
			Packet		= market_api:msg_sc_get_back(?CONST_SYS_TRUE),
			TipPacket	= message_api:msg_notice(?TIP_MARKET_GET_SUCCESS),
			misc_packet:send(NewPlayer#player.net_pid, <<Packet/binary, TipPacket/binary>>);
		ErrorCode ->
			?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
%% 			Packet		= market_api:msg_sc_get_back(?CONST_SYS_FALSE),
			Packet		= message_api:msg_notice(ErrorCode),
			misc_packet:send(NewPlayer#player.net_pid, Packet)
	end,
	NewPlayer.
	
%% 领回指定寄售id物品
get_goods_one_by_one(Id, GoodsId, Player) ->
	UserId				= Player#player.user_id,
	SaleInfo			= ets_api:lookup(?CONST_ETS_MARKET_SALE, Id),
	GoodsList			= [SaleInfo#market_sale.goods],
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MARKET_RETURN, 1, 1, 0, 0, 0, 1, []) of
		{?ok, Player2, _, Packet0}->
			WhereList	= "sale_id="++misc:to_list(Id)++" and seller_id="++misc:to_list(UserId),
			case mysql_api:delete(game_market_sale, WhereList) of
				{?ok, _, _} ->
					market_api:ets_delete_market(?CONST_ETS_MARKET_SALE, Id),
					Packet			= market_api:msg_sc_get_back(?CONST_SYS_TRUE),
					TipPacket		= message_api:msg_notice(?TIP_MARKET_GET_SUCCESS),
					misc_packet:send(Player#player.net_pid, <<Packet0/binary, Packet/binary, TipPacket/binary>>),
					admin_log_api:log_market_get(UserId, Id, GoodsId),
					Player2;
				{?error, ErrorCode} ->
					?MSG_ERROR("Error:~p",[ErrorCode]),
%% 					Packet			= market_api:msg_sc_get_back(ErrorCode),
					Packet			= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
					misc_packet:send(Player#player.net_pid, <<Packet0/binary, Packet/binary>>),
					Player
			end;
		{?error, ErrorCode2} ->
%% 			Packet			= market_api:msg_sc_get_back(ErrorCode2),
			Packet			= message_api:msg_notice(ErrorCode2),
			misc_packet:send(Player#player.net_pid, Packet),
			Player
	end.

%%----------------------------------------------------------------------------------------
%% @desc     竞购物品
%% @spec     buy_goods/4
%% @param    GoodsId:物品Id Id:寄售记录Id Type:一口价购买/普通竞价购买
%% @return   {?error, ErrorCode}
%%----------------------------------------------------------------------------------------
buy_goods(Type, Id, GoodsId, Player) when is_number(Id) andalso Id > 0->
	if
		Type =:= ?CONST_MARKET_ONE_FIXED_PRICE orelse 
		Type =:= ?CONST_MARKET_ONE_COM_PRICE ->  
			buy_goods_first(Type, Id, GoodsId, Player);
		Type =:= ?CONST_MARKET_TWO_FIXED_PRICE orelse 
		Type =:= ?CONST_MARKET_TWO_COM_PRICE ->  
			buy_goods_second(Type, Id, GoodsId, Player);
		?true ->
			Packet	= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, Packet)
	end;
buy_goods(_Type, _Id, _GoodsId, Player) ->              %% 参数错误
	TipPacket	= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket).

%% 在浏览界面竞拍物品
buy_goods_first(Type, Id, GoodsId, Player) ->
	case check_buy_goods_first(Type, Id, GoodsId, Player) of
		{?ok, SaleInfo} ->
			case Type of 
				?CONST_MARKET_ONE_FIXED_PRICE ->         %% 一口价竞拍
					buy_goods_fixed_price_first(Id, GoodsId, SaleInfo, Player);  
				?CONST_MARKET_ONE_COM_PRICE ->		     %% 普通竞拍
					buy_goods_common_price_first(Id, GoodsId, SaleInfo, Player) 
			end;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%% 在竞拍界面竞拍物品
buy_goods_second(Type, Id, GoodsId, Player) ->
	BuyInfo 		= market_api:ets_lookup_market(?CONST_ETS_MARKET_BUY, Id),
	case is_record(BuyInfo, market_buy) of
		?true ->
			case Type of
				?CONST_MARKET_TWO_FIXED_PRICE ->			 %% 一口价竞拍
					buy_goods_fixed_price_second(Id, BuyInfo, GoodsId, Player);
				?CONST_MARKET_TWO_COM_PRICE ->			 	 %% 普通竞拍
					buy_goods_common_price_second(BuyInfo, Player)
			end;
		?false ->                 %% 此时物品可能已被拍卖走
			Packet  = message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%% 在浏览界面一口价竞拍
buy_goods_fixed_price_first(Id, _GoodsId, SaleInfo, Player) when is_record(SaleInfo, market_sale)->
	UserId			= Player#player.user_id,
	BuyerId			= SaleInfo#market_sale.buyer_id,
	BuyerName		= SaleInfo#market_sale.buyer_name,
	SellerId		= SaleInfo#market_sale.seller_id,
	SellerName		= SaleInfo#market_sale.seller_name,
	PlayerName 		= (Player#player.info)#info.user_name,
	Goods 			= SaleInfo#market_sale.goods,
	GoodsId			= Goods#goods.goods_id,
	GoodsCount		= Goods#goods.count,
	FixedPrice 		= SaleInfo#market_sale.fixed_price,
	Pattern			= #market_buy{buyer_id = BuyerId, buyer_name = BuyerName, sale_id = Id, _ = '_'},
	BuyInfoList		= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	case FixedPrice =:=	?CONST_SYS_FALSE of
		?true ->
			Packet 		=	message_api:msg_notice(?TIP_MARKET_NOT_ALLOW_BUY),
			misc_packet:send(Player#player.net_pid, Packet);
		?false -> 
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, FixedPrice, ?CONST_COST_MARKET_ONCE) of
				?ok ->
					if BuyerId	=:=	UserId andalso BuyerName =:= PlayerName -> 
						   [BuyInfo1]  = BuyInfoList,
							BidPrice1  = BuyInfo1#market_buy.bid_price,
						   add_money(BuyerId, BidPrice1);
					   ?true ->             %%不是最后竞拍者 补偿上个竞拍玩家元宝
						   case erlang:length(BuyInfoList) =:= ?CONST_SYS_FALSE of 
							   ?true ->  ?ok;
							   ?false ->
								   [BuyInfo] = BuyInfoList,
								   BidPrice  = BuyInfo#market_buy.bid_price,
								   add_money(BuyerId, BidPrice)
						   end
					end,
					Result = delete_sale_info(Id),
					case Result of
						?ok ->
							delete_buy_info_list(Id),
							GoodsIdList = [{misc:to_list(GoodsId)}],
							CostList1	= [{misc:to_list(FixedPrice)}],
							Content1	= [{GoodsIdList}] ++ [{[{PlayerName}]}]++[{CostList1}],
							mail_api:send_system_mail_to_one(SellerName, <<>>, <<>>,?CONST_MAIL_MARKET_SALE, Content1, [], 0, 
													FixedPrice*?TAX_RATE, 0, ?CONST_COST_MARKET_ADD),
							achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_AUCTION, 0, 1),
							CostList	= [{misc:to_list(FixedPrice)}],
							Content		= [{CostList}] ++ [{[{SellerName}]}] ++ [{GoodsIdList}],
							mail_api:send_system_mail_to_one(PlayerName, <<>>, <<>>, ?CONST_MAIL_MARKET_BUY, Content, Goods, 
															 0, 0, 0, ?CONST_COST_GET_GOODS),
							Packet		= market_api:msg_sc_buy_state(?CONST_SYS_TRUE),
							TipPacket	= message_api:msg_notice(?TIP_MARKET_FIXED_BUY),
                            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_MARKET_ADD, Goods, misc:seconds()),
							admin_log_api:log_market(UserId, 1, Id, GoodsId, GoodsCount, 0, FixedPrice, SellerId),
							misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);	
						_  ->
							player_money_api:plus_money(UserId, ?CONST_SYS_CASH, FixedPrice, ?CONST_COST_MARKET_ONCE_REWARD),
							Packet		=	message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
							misc_packet:send(Player#player.net_pid, Packet)	
					end;
				{?error, ErrorCode} ->
					?MSG_DEBUG("ErrorCode=~p~n", [ErrorCode])
			end
	end.

%% 在竞拍界面一口价竞拍
buy_goods_fixed_price_second(Id, BuyInfo, _GoodsId, Player) when is_record(BuyInfo, market_buy) ->
	UserId			= Player#player.user_id,
	PlayerName 		= (Player#player.info)#info.user_name,
	SellerId		= BuyInfo#market_buy.seller_id,	
	SellerName		= BuyInfo#market_buy.seller_name,
	Goods 			= BuyInfo#market_buy.goods,
	GoodsId			= Goods#goods.goods_id,
	GoodsCount		= Goods#goods.count,
	FixedPrice		= BuyInfo#market_buy.fixed_price,
	SaleId			= BuyInfo#market_buy.sale_id,
	SaleInfo		= ets_api:lookup(?CONST_ETS_MARKET_SALE, SaleId),
	BuyerId			= SaleInfo#market_sale.buyer_id,
	BuyerName		= SaleInfo#market_sale.buyer_name,
	Pattern			= #market_buy{buyer_id = BuyerId, buyer_name = BuyerName, sale_id = SaleId, _ = '_'},
	BuyInfoList		= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	?MSG_DEBUG("BuyInfo=~p", [BuyInfoList]),
	case FixedPrice =:= ?CONST_SYS_FALSE of
		?true  ->
			Packet 	= message_api:msg_notice(?TIP_MARKET_NOT_ALLOW_BUY),
			misc_packet:send(Player#player.net_pid, Packet);
		?false ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, FixedPrice, ?CONST_COST_MARKET_ONCE_2) of
				?ok ->
					if BuyerId	=:=	UserId andalso BuyerName =:= PlayerName -> 
						    [BuyInfo2] = BuyInfoList,
							BidPrice2  = BuyInfo2#market_buy.bid_price,
						   add_money(BuyerId, BidPrice2);
					   ?true ->             %%不是最后竞拍者 补偿上个竞拍玩家元宝
						   case erlang:length(BuyInfoList) =:= 0 of
							   ?true  -> ?ok;
							   ?false ->
								   [BuyInfo1] = BuyInfoList,
								   BidPrice   = BuyInfo1#market_buy.bid_price,
								   add_money(BuyerId, BidPrice)
						   end
					end,
					case delete_info(Id, SaleId) of
						?ok ->
							GoodsIdList = [{misc:to_list(GoodsId)}],
							CostList1	= [{misc:to_list(FixedPrice)}],
							Content1	= [{GoodsIdList}] ++ [{[{PlayerName}]}] ++ [{CostList1}],
							mail_api:send_system_mail_to_one(SellerName, <<>>, <<>>, ?CONST_MAIL_MARKET_SALE, Content1, 
															[], 0, FixedPrice*?TAX_RATE, 0, ?CONST_COST_MARKET_ADD),
							delete_buy_info_list(SaleId),
							achievement_api:add_achievement(Player#player.user_id, ?CONST_ACHIEVEMENT_AUCTION, 0, 1),
							CostList	= [{misc:to_list(FixedPrice)}],
							Content		= [{CostList}] ++ [{[{SellerName}]}]++ [{GoodsIdList}],
							mail_api:send_system_mail_to_one(PlayerName, <<>>, <<>>, ?CONST_MAIL_MARKET_BUY, Content, 
															 Goods, 0, 0, 0, ?CONST_COST_GET_GOODS),
							TipPacket	= message_api:msg_notice(?TIP_MARKET_FIXED_BUY),
							Packet		= market_api:msg_sc_buy_state(?CONST_SYS_TRUE),
							admin_log_api:log_market(UserId, 1, Id, GoodsId, GoodsCount, 0, FixedPrice, SellerId),
							misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
						{?error, ErrorCode} ->
							?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
							Packet		=	message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, Packet)
					end;
				{?error, ErrorCode} ->
					?MSG_DEBUG("ErrorCode~p~n", [ErrorCode])
			end
	end.

%% 在浏览界面普通竞拍
buy_goods_common_price_first(Id, GoodsId, SaleInfo, Player)  when is_record(SaleInfo, market_sale) ->
	UserId				= Player#player.user_id,
	UserName			= (Player#player.info)#info.user_name,
	CurrentPrice 		= SaleInfo#market_sale.current_price,
	NewCurrentPrice		= misc:ceil(CurrentPrice * 1.05),
	BuyerId				= SaleInfo#market_sale.buyer_id,
	BuyerName			= SaleInfo#market_sale.buyer_name,
	Pattern				= #market_buy{buyer_id = BuyerId, buyer_name = BuyerName, sale_id = Id, _ ='_'},
	BuyInfoList			= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	?MSG_DEBUG("BuyInfo=~p", [BuyInfoList]),
	if
		BuyerId	=:=	UserId andalso BuyerName =:= UserName ->    %%是最后竞拍者 无需再次竞拍
			Packet	= message_api:msg_notice(?TIP_MARKET_NOT_BUY_AGAIN),
			misc_packet:send(Player#player.net_pid, Packet);
		?true ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, NewCurrentPrice, ?CONST_COST_MARKET_NORMAL_SALE) of
				?ok ->
					case erlang:length(BuyInfoList) =:= ?CONST_SYS_FALSE of
						?true -> ?ok;
						?false ->
							[BuyInfo] 	= BuyInfoList,
							 BidPrice  	= BuyInfo#market_buy.bid_price,
							add_money(BuyerId, BidPrice)
					end,
					buy_sale_goods(Id, GoodsId, SaleInfo, Player),
					Packet		= market_api:msg_sc_buy_state(?CONST_SYS_TRUE),
					TipPacket	= message_api:msg_notice(?TIP_MARKET_BUY_SUCCESS),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end
	end.

%% 在竞拍界面普通竞拍
buy_goods_common_price_second(BuyInfo, Player) when is_record(BuyInfo, market_buy) ->
	UserId				= Player#player.user_id,
	UserName			= (Player#player.info)#info.user_name,
	SaleId				= BuyInfo#market_buy.sale_id,
	SaleInfo			= market_api:ets_lookup_market(?CONST_ETS_MARKET_SALE, SaleId),
	CurrentPrice		= SaleInfo#market_sale.current_price,
	NewCurrentPrice		= misc:ceil(CurrentPrice * 1.05),
	BuyerId				= SaleInfo#market_sale.buyer_id,
	BuyerName			= SaleInfo#market_sale.buyer_name,
	Pattern				= #market_buy{buyer_id = BuyerId, buyer_name = BuyerName, sale_id = SaleId, _ ='_'},
	BuyInfoList			= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	?MSG_DEBUG("BuyInfo=~p", [BuyInfoList]),
	if
		BuyerId	=:=	UserId andalso BuyerName =:= UserName -> %%是最后竞拍者 无需再次竞拍
			Packet	= message_api:msg_notice(?TIP_MARKET_NOT_BUY_AGAIN),
			misc_packet:send(Player#player.net_pid, Packet);
		?true ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, NewCurrentPrice, ?CONST_COST_MARKET_NORMAL_SALE_2) of
				?ok ->
					case erlang:length(BuyInfoList) =:= ?CONST_SYS_FALSE of
						?true  -> ?ok;
						?false ->
							[BuyInfo1] 	= BuyInfoList,
							 BidPrice   = BuyInfo1#market_buy.bid_price,
							add_money(BuyerId, BidPrice)
					end,
					buy_sale_goods(BuyInfo, SaleInfo, Player),
					Packet		= market_api:msg_sc_buy_state(?CONST_SYS_TRUE),
					TipPacket	= message_api:msg_notice(?TIP_MARKET_BUY_SUCCESS),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
				{?error, ErrorCode} ->
					Packet		= market_api:msg_sc_buy_state(ErrorCode),
					misc_packet:send(Player#player.net_pid, Packet)
			end
	end.

%% 检查竞拍
check_buy_goods_first(_Type, Id, _GoodsId, Player) ->
	SaleInfo 		= market_api:ets_lookup_market(?CONST_ETS_MARKET_SALE, Id),
	NowTime 		= misc:seconds(),
	if
		is_record(SaleInfo, market_sale) ->
			if
				SaleInfo#market_sale.seller_id 		=:= Player#player.user_id ->    %% 不能购买自己寄售的物品
					{?error, ?TIP_MARKET_NOT_BUY_SELF_GOOS};
				SaleInfo#market_sale.end_time 		< 	NowTime 			  ->    %% 已过期不能购买
					{?error, ?TIP_MARKET_GOODS_OVERDURE};
				?true ->
					{?ok, SaleInfo}
			end;
		?true ->
			{?error, ?TIP_COMMON_GOOD_NOT_EXIST}
	end.	

%% 在浏览界面竞拍添加购买记录
buy_sale_goods(Id, _GoodsId, SaleInfo, Player) ->
	Goods			= SaleInfo#market_sale.goods,
	GoodsName 		= Goods#goods.name,
	GoodsLevel 		= Goods#goods.lv,
	GoodsPro 		= Goods#goods.pro,
	GoodsColor 		= Goods#goods.color,
	Category		= SaleInfo#market_sale.category,
	AttrType		= SaleInfo#market_sale.goods_attr_type,
	GoodsType 		= Goods#goods.type,
	GoodsSubType 	= Goods#goods.sub_type,
	SaleId			= SaleInfo#market_sale.sale_id,
	SellerId 		= SaleInfo#market_sale.seller_id,
	SellerName 		= SaleInfo#market_sale.seller_name,
	BuyerId 		= Player#player.user_id,
	BuyerName 		= (Player#player.info)#info.user_name,
	CurrentPrice 	= SaleInfo#market_sale.current_price,
	NewCurrentPrice = misc:ceil(CurrentPrice * 1.05) ,
	FixedPrice 		= SaleInfo#market_sale.fixed_price,
	NowTime			= misc:seconds(),
	EndTime 		= SaleInfo#market_sale.end_time,
	LeftTime		= misc:ceil((EndTime - NowTime)  div ?CONST_SYS_NUMBER_SIXTY),
	NewEndTime		= if
						  LeftTime  < 30 -> EndTime + 2 * ?CONST_SYS_NUMBER_SIXTY;
						  ?true -> EndTime
					  end,
	market_db_mod:update_buyer_info(Id, BuyerId, BuyerName, NewCurrentPrice, NewEndTime, Player),
	Pattern			= #market_buy{sale_id = SaleId, buyer_id = BuyerId, buyer_name = BuyerName, _ = '_'},
	BuyInfoList		= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	BuyInfoNum	    = erlang:length(BuyInfoList),
	case BuyInfoNum =:= ?CONST_SYS_FALSE of
		?true ->
			BidPrice 	= NewCurrentPrice,
			case market_db_mod:insert_marekt_buy_info(SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
										GoodsLevel, GoodsColor, GoodsPro, AttrType, NewCurrentPrice, FixedPrice, BidPrice, NewEndTime, SaleId) of
				{?ok, _BuyInfo} -> ?ok;
				{?error, _ErrorCode} ->
					?MSG_DEBUG("_ErrorCode=~p", [_ErrorCode]),
					TipPacket1		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
					misc_packet:send(Player#player.net_pid, TipPacket1)
			end;
		?false ->   
			[BuyInfo|_]	= BuyInfoList,
			BuyId		= BuyInfo#market_buy.buy_id,
			market_db_mod:update_buyer_info1(BuyId, NewCurrentPrice, NewEndTime, Player)
	end,
	Pattern1			= #market_buy{sale_id = SaleId,  _ = '_'},
	BuyInfoList1		= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern1),
	F = fun(BuyInfo) when is_record(BuyInfo, market_buy) andalso BuyInfo#market_buy.buyer_id =/= BuyerId->
				BuyId1	=	BuyInfo#market_buy.buy_id,
				market_db_mod:update_buyer_info2(BuyId1, NewCurrentPrice, NewEndTime);
		   (X) ->
				?MSG_DEBUG("X =~p", [X]),
				?ok
		end,
	lists:foreach(F, BuyInfoList1).
%%在竞拍界面添加购买记录
buy_sale_goods(BuyInfo, SaleInfo, Player) ->
	SaleId			= SaleInfo#market_sale.sale_id,
	BuyId			= BuyInfo#market_buy.buy_id,
	SaleId			= SaleInfo#market_sale.sale_id,
	BuyerId 		= Player#player.user_id,
	BuyerName 		= (Player#player.info)#info.user_name,
	CurrentPrice 	= SaleInfo#market_sale.current_price,
	NewCurrentPrice = misc:ceil(CurrentPrice * 1.05) ,
	NowTime			= misc:seconds(),
	EndTime 		= SaleInfo#market_sale.end_time,
	LeftTime		= misc:ceil((EndTime - NowTime)  div ?CONST_SYS_NUMBER_SIXTY),
	NewEndTime		= if
						  LeftTime < 30 -> EndTime + 2 * ?CONST_SYS_NUMBER_SIXTY;
						  ?true -> EndTime
					  end,
	market_db_mod:update_buyer_info(SaleId, BuyerId, BuyerName, NewCurrentPrice, NewEndTime, Player),
	market_db_mod:update_buyer_info1(BuyId, NewCurrentPrice, NewEndTime, Player),
	Pattern			= #market_buy{sale_id = SaleId,  _ = '_'},
	BuyInfoList		= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	F = fun(BuyInfo1) when is_record(BuyInfo1, market_buy) andalso BuyInfo1#market_buy.buyer_id =/= BuyerId ->
				BuyId1	=	BuyInfo1#market_buy.buy_id,
				market_db_mod:update_buyer_info2(BuyId1, NewCurrentPrice, NewEndTime);
		   (X) ->
				?MSG_DEBUG("X=p", [X]),
				?ok
		end,
	lists:foreach(F, BuyInfoList).

%% 购买成功后删除与此有关寄售记录
delete_info(Id, SaleId) ->
	try
		?ok		= delete_sale_info(SaleId),
		?ok		= delete_buy_info(Id)
	catch
		throw:_ ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.
		
delete_sale_info(Id) ->
	?MSG_DEBUG("Id=~p", [Id]),
	case mysql_api:delete(game_market_sale, "sale_id=" ++ misc:to_list(Id)) of
		{?ok, _, _} ->
			market_api:ets_delete_market(?CONST_ETS_MARKET_SALE, Id),
			?ok;
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_ERROR_DB})
	end.

delete_buy_info(Id) ->
	case mysql_api:delete(game_market_buy, "buy_id=" ++ misc:to_list(Id)) of
		{?ok, _, _} ->
			market_api:ets_delete_market(?CONST_ETS_MARKET_BUY, Id),
			?ok;
		{?error, ErrorCode} ->
			?MSG_ERROR("Error:~p", [ErrorCode]),
			throw({?error, ?TIP_COMMON_ERROR_DB})
	end.

delete_buy_info_list(SaleId) ->
	Pattern		= #market_buy{sale_id = SaleId, _='_'},
	BuyInfoList = ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
	F = fun(BuyInfo) ->
				Id = BuyInfo#market_buy.buy_id,
				case mysql_api:delete(game_market_buy, "buy_id=" ++ misc:to_list(Id)) of
					{?ok, _, _} ->
						market_api:ets_delete_market(?CONST_ETS_MARKET_BUY, Id),
						?ok;
					{?error, ErrorCode} ->
						?MSG_ERROR("Error:~p", [ErrorCode]),
						{?error, ?TIP_COMMON_ERROR_DB}
				end
		end,
	lists:foreach(F, BuyInfoList).

%%  定时调用,条件满足,则把物品通过邮件发给购买者
check_buy_sale_goods() ->
	NowTime 		= misc:seconds(),
	MatchSpec 		= ets:fun2ms(fun(SaleInfo) when SaleInfo#market_sale.end_time =< NowTime  andalso
							SaleInfo#market_sale.buyer_id =/= ?CONST_SYS_FALSE  -> SaleInfo end),
	SaleInfoList 	= ets:select(?CONST_ETS_MARKET_SALE, MatchSpec),
	F = fun(SaleInfo) when is_record(SaleInfo, market_sale)->
				SellerId	= SaleInfo#market_sale.seller_id,
				SellerName	= SaleInfo#market_sale.seller_name,
				SaleId 		= SaleInfo#market_sale.sale_id,
				BuyerId		= SaleInfo#market_sale.buyer_id,
				BuyerName	= SaleInfo#market_sale.buyer_name,
				Goods	 	= SaleInfo#market_sale.goods,
				GoodsId		= Goods#goods.goods_id,
				GoodsCount	= Goods#goods.count,
				CurrentPrice= SaleInfo#market_sale.current_price,
				Pattern		= #market_buy{buyer_id = BuyerId, buyer_name = BuyerName, sale_id = SaleId, _ ='_'},
				BuyInfoList	= ets:match_object(?CONST_ETS_MARKET_BUY, Pattern),
				GoodsIdList = [{misc:to_list(GoodsId)}],
				if 
					erlang:length(BuyInfoList) =:= ?CONST_SYS_FALSE -> ?ok;
					?true ->
                        admin_log_api:log_goods(BuyerId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_MARKET_ADD, Goods, misc:seconds()),
						[BuyInfo1] 	= BuyInfoList,
						BidPrice    = BuyInfo1#market_buy.bid_price,
						CostList1	= [{misc:to_list(BidPrice)}],
						Content1	= [{GoodsIdList}] ++ [{[{BuyerName}]}]++ [{CostList1}],
						mail_api:send_system_mail_to_one(SellerName, <<>>, <<>>, ?CONST_MAIL_MARKET_SALE, Content1,
														 [], 0, BidPrice*?TAX_RATE, 0, ?CONST_COST_MARKET_ADD)
				end,
				delete_sale_info(SaleId),          
				delete_buy_info_list(SaleId),
				achievement_api:add_achievement(BuyerId, ?CONST_ACHIEVEMENT_AUCTION, 0, 1),
				CostList	= [{misc:to_list(CurrentPrice)}],
				Content		= [{CostList}] ++  [{[{SellerName}]}] ++ [{GoodsIdList}],
				admin_log_api:log_market(BuyerId, 1, SaleId, GoodsId, GoodsCount, CurrentPrice, 0, SellerId),
				mail_api:send_system_mail_to_one(BuyerName, <<>>, <<>>, ?CONST_MAIL_MARKET_BUY, Content, 
												 Goods, 0, 0, 0, ?CONST_COST_GET_GOODS);
		   (X) ->
				?MSG_DEBUG("X=~p", [X]),
				?ok
		end,
	lists:foreach(F, SaleInfoList).

%% 给寄售者卖出物品后加元宝
add_money(UserId, Value) ->
	?MSG_DEBUG("UserId=~p, Value=~p", [UserId, Value]),
	player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_MARKET_ADD).


%% 更新热门搜索数据
update_hot_search([])->
	?ok;
update_hot_search([SaleInfo|SaleInfoList]) ->
	Goods			= SaleInfo#market_sale.goods,
	GoodsId			= Goods#goods.goods_id,
	GoodsName		= Goods#goods.name,
	case ets_api:lookup(?CONST_ETS_MARKET_SEARCH, GoodsId) of
		?null ->
			SearchGoods		= #market_search{goods_id = GoodsId, goods_name = GoodsName, search_times = 1},
			ets_api:insert(?CONST_ETS_MARKET_SEARCH, SearchGoods),
			market_db_mod:update_search_goods(GoodsId, GoodsName, 1);
		SearchInfo ->
			SearchTimes		= SearchInfo#market_search.search_times + 1,
			NewSearchInfo	= SearchInfo#market_search{search_times = SearchTimes},
			ets_api:insert(?CONST_ETS_MARKET_SEARCH, NewSearchInfo),
			?MSG_DEBUG("GoodsId=~p, GoodsName=~p, SearchTimes=~p", [GoodsId, GoodsName, SearchTimes]),
			market_db_mod:update_search_goods1(GoodsId, GoodsName, SearchTimes)
	end,
	update_hot_search(SaleInfoList).
		
%% 请求热门搜索数据
get_hot_search(Player) ->
	SearchList		= ets_api:list(?CONST_ETS_MARKET_SEARCH),
	NewSearchList	= filter_hot_search_goods(SearchList, []),
	Num1			= erlang:length(SearchList),
	Num2			= erlang:length(NewSearchList),
	case {Num1 =:= ?CONST_SYS_FALSE, Num2 =:= ?CONST_SYS_FALSE} of
		{?true, ?true}->        %% 无热门搜索物品
			?ok;
		{?false, ?true} ->      %% 随机推送的物品
			List	= get_hot_search_goods(SearchList, []),
			Packet	= market_api:msg_sc_hot_search(List),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->                    %% 统计出来的热门物品
			List	= get_hot_search_goods(NewSearchList, []),
			Packet	= market_api:msg_sc_hot_search(List),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

filter_hot_search_goods([SearchInfo|SearchList], Acc) when is_record(SearchInfo, market_search)->
	SearchTimes		= SearchInfo#market_search.search_times,
	NewAcc			= case SearchTimes > 20 of
						  ?true ->
							  [SearchInfo|Acc];
						  ?false ->
							  Acc
					  end,
	filter_hot_search_goods(SearchList, NewAcc);
filter_hot_search_goods([], Acc) ->
	Acc.

get_hot_search_goods([SearchInfo|SearchList], Acc) when is_record(SearchInfo, market_search) ->
	NewAcc			= case erlang:length(Acc) > 10 of
						  ?true ->
							  Acc;
						  ?false ->
							  [SearchInfo|Acc]
					  end,
	get_hot_search_goods(SearchList, NewAcc);
get_hot_search_goods([], Acc) ->
	Acc.