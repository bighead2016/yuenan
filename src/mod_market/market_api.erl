-module(market_api).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([initial_ets/0, ets_insert_sale/1, ets_insert_buy/1, ets_lookup_market/2, ets_delete_market/2, ets_insert_market/2]).
-export([msg_market_sale_list/1, msg_market_sale_info/1, msg_market_buy_info/1, msg_sale_info/3,
		 msg_buy_info/3, msg_sc_hot_search/1, msg_sc_sale_state/1, msg_sc_get_back/1, msg_sc_buy_state/1]).
-export([record_market_buy/1, record_market_sale/17, record_market_sale/1, record_market_buy/19]).
%%
%% API Functions
%%

%% 初始化ets 
initial_ets() -> 
	case initial_ets_market_sale() of
		?ok -> ?ok;
		{?error, ErrorCode} -> 
			?MSG_DEBUG("ErrorCode=~p", [ErrorCode])
	end,
	case initial_ets_market_buy() of
		?ok ->?ok;
		{?error, ErrorReason} -> 
			?MSG_DEBUG("ErrorCode=~p", [ErrorReason])
	end,
	case initial_ets_market_search() of
		?ok -> ?ok;
		{?error, Error} ->
			?MSG_DEBUG("~nError=~p", [Error])
	end,
	?ok.

%% 初始化竞拍ets_market_sale 
initial_ets_market_sale() ->
	ets:delete_all_objects(?CONST_ETS_MARKET_SALE),
	FieldList = [sale_id, seller_id, seller_name, buyer_id, buyer_name, goods, goods_name, category, goods_type, 
				 goods_sub_type, goods_level, goods_color, goods_pro, goods_attr_type, current_price, fixed_price, end_time],
	case mysql_api:select(FieldList, game_market_sale) of
		{?ok, MarketSaleList} ->
			F = fun([SaleId, SellerId, SellerName, BuyerId, BuyerName, GoodsTmpe, GoodsName, Category, GoodsType, 
					 GoodsSubType, GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime],
					Acc) ->
						GoodsTmpe1 		= misc:decode(GoodsTmpe),
						case goods_api:unzip_goods(GoodsTmpe1) of
							Goods when is_record(Goods, goods) ->
								[record_market_sale([SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, 
													GoodsSubType, GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime])|Acc];
							MiniGoods when is_record(MiniGoods, mini_goods) ->
								Goods1 = goods_api:mini_to_goods(MiniGoods),
								[record_market_sale([SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods1, GoodsName, Category, GoodsType, 
													GoodsSubType, GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime])|Acc];
							_ -> Acc
						end
				end,
			MarketSaleInfoList = lists:foldl(F, [], MarketSaleList),
			ets_insert_list(?CONST_ETS_MARKET_SALE, MarketSaleInfoList);
		{?error, _ErrorCode} ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 初始化购买ets_market_buy 
initial_ets_market_buy() ->
	ets:delete_all_objects(?CONST_ETS_MARKET_BUY),
	FieldList = [buy_id, seller_id, seller_name, buyer_id, buyer_name, goods, goods_name, category, goods_type, goods_sub_type,
				 goods_level, goods_color, goods_pro, goods_attr_type, current_price, fixed_price, bid_price, end_time, sale_id],
	case mysql_api:select(FieldList, game_market_buy) of
		{?ok, MarketBuyList} ->
			F = fun([BuyId, SellerId, SellerName, BuyerId, BuyerName, GoodsTmpe, GoodsName, Category, GoodsType, GoodsSubType,
					 GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId],
					Acc) ->
						GoodsTmpe1 		= misc:decode(GoodsTmpe), 
						case goods_api:unzip_goods(GoodsTmpe1) of
							Goods when is_record(Goods, goods) ->
								[record_market_buy([BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, 
													GoodsSubType, GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice,
													EndTime, SaleId])|Acc];
							_ -> Acc
						end
				end,
			MarketBuyInfoList = lists:foldl(F, [], MarketBuyList),
			ets_insert_list(?CONST_ETS_MARKET_BUY, MarketBuyInfoList);
		{?error, _ErrorCode} ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 初始化热门搜索ets_market_search
initial_ets_market_search() ->
	ets:delete_all_objects(?CONST_ETS_MARKET_SEARCH),
	FieldList	= [id, goods_id, goods_name, search_times],
 	case mysql_api:select(FieldList, game_market_search) of
		{?ok, SearchList} ->
			F	= fun([_Id, GoodsId, GoodsName, SearchTimes]) ->
						  record_market_search([GoodsId, GoodsName, SearchTimes])
				  end,
			SearchInfoList	= [F(SearchTemp) || SearchTemp <- SearchList],
			ets_insert_list(?CONST_ETS_MARKET_SEARCH, SearchInfoList);
		{?error, ErrorCode} ->
			?MSG_DEBUG("~nErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%% 浏览查询返回
msg_market_sale_info(MarketSaleInfo) when is_record(MarketSaleInfo, market_sale) ->	
	Goods			= MarketSaleInfo#market_sale.goods,
	Data1 = {
			MarketSaleInfo#market_sale.sale_id,                             %% 寄售自增ID
      		MarketSaleInfo#market_sale.seller_name, 					    %% 寄售者昵称	
			MarketSaleInfo#market_sale.buyer_name,  					    %% 购买者昵称
			MarketSaleInfo#market_sale.current_price,					    %% 出售价格：元宝价格	
			MarketSaleInfo#market_sale.fixed_price, 					    %% 出售价格：一口价格	
			MarketSaleInfo#market_sale.end_time,	                        %% 物品截至时间
			MarketSaleInfo#market_sale.goods_level,  					    %% 物品等级限制	
			MarketSaleInfo#market_sale.goods_color  					    %% 物品颜色	          
			},
	Data2 = get_goods_tips(Goods),											%% 物品装备协议组
	Data  = misc:to_list(Data1) ++ Data2,
	misc:to_tuple(Data).

%% 竞拍查询返回
msg_market_buy_info(MarketBuyInfo) when is_record(MarketBuyInfo, market_buy) ->
	SaleId			= MarketBuyInfo#market_buy.sale_id,
	BuyerName		= case ets_api:lookup(?CONST_ETS_MARKET_SALE, SaleId) of
						  SaleInfo when is_record(SaleInfo, market_sale) ->
							  SaleInfo#market_sale.buyer_name;
						  _ ->
							  MarketBuyInfo#market_buy.buyer_name
					  end,
	Goods			= MarketBuyInfo#market_buy.goods,
	Data1 = {
			 MarketBuyInfo#market_buy.buy_id,                           %% 购买自增ID	
			 MarketBuyInfo#market_buy.seller_name, 					    %% 寄售者昵称	
			 BuyerName,												    %% 购买者昵称
			 MarketBuyInfo#market_buy.current_price,					%% 出售价格：元宝价格	
			 MarketBuyInfo#market_buy.fixed_price, 					    %% 出售价格：一口价格	
			 MarketBuyInfo#market_buy.end_time,							%% 物品截至时间
			 MarketBuyInfo#market_buy.goods_level,  					%% 物品等级限制	
			 MarketBuyInfo#market_buy.goods_color  						%% 物品颜色	  	
			},
	Data2 = get_goods_tips(Goods),										%% 物品装备协议组
	Data  = misc:to_list(Data1) ++ Data2,
	misc:to_tuple(Data).

msg_sale_info(TotalListNum, MarketInfoList, Page) ->
	F = fun(MarketSaleInfo) ->
				msg_market_sale_info(MarketSaleInfo)
		end,
	List = [F(MarketSaleInfo) ||MarketSaleInfo <- MarketInfoList],
	_Packet = misc_packet:pack(?MSG_ID_MARKET_SC_SEARCH_INFO, ?MSG_FORMAT_MARKET_SC_SEARCH_INFO, [TotalListNum, List, Page]).

msg_buy_info(TotalListNum, MarketInfoList, Page) ->
	F = fun(MarketBuyInfo) ->
				msg_market_buy_info(MarketBuyInfo)
		end,
	List = [F(MarketBuyInfo) ||MarketBuyInfo <- MarketInfoList],
	_Packet = misc_packet:pack(?MSG_ID_MARKET_SC_SEARCH_INFO, ?MSG_FORMAT_MARKET_SC_SEARCH_INFO, [TotalListNum, List, Page]).

%% 寄售查询列表返回
msg_market_sale_list(MarketSaleInfoList) ->
	msg_market_sale_list(MarketSaleInfoList, <<>>).

msg_market_sale_list([MarketSaleInfo|MarketSaleInfoList], Acc) ->
	Packet = msg_market_sale(MarketSaleInfo),
	msg_market_sale_list(MarketSaleInfoList, <<Acc/binary, Packet/binary>>);
msg_market_sale_list([], Acc) ->
	Acc.

%% 寄售查询返回
msg_market_sale(MarketSaleInfo) when is_record(MarketSaleInfo, market_sale) ->
	Goods			= MarketSaleInfo#market_sale.goods,
	Data1 =[
		    MarketSaleInfo#market_sale.sale_id,                             %% 寄售自增ID
      		MarketSaleInfo#market_sale.seller_name, 					    %% 寄售者昵称	
			MarketSaleInfo#market_sale.buyer_name,  					    %% 购买者昵称
			MarketSaleInfo#market_sale.current_price,					    %% 出售价格：当前价格	
			MarketSaleInfo#market_sale.fixed_price, 					    %% 出售价格：一口价格	
			MarketSaleInfo#market_sale.end_time,	                        %% 物品截至时间	
			MarketSaleInfo#market_sale.goods_level,  					    %% 物品等级限制	
			MarketSaleInfo#market_sale.goods_color,  					    %% 物品颜色	
			MarketSaleInfo#market_sale.goods_pro  						    %% 职业限制 
		],
	Data2 = get_goods_tips(Goods),											%% 物品装备协议组
	Data  = Data1 ++ Data2,
	?MSG_DEBUG("Data=~p", [Data]),
	_Packet = misc_packet:pack(?MSG_ID_MARKET_SC_SEAL_INFO, ?MSG_FORMAT_MARKET_SC_SEAL_INFO, Data).

%% 寄售物品返回(17004)
msg_sc_sale_state(Result) ->
	misc_packet:pack(?MSG_ID_MARKET_SC_SEAL_RESULT, ?MSG_FORMAT_MARKET_SC_SEAL_RESULT, [Result]).

%% 竞拍状态(17006)
msg_sc_buy_state(Result) ->
	misc_packet:pack(?MSG_ID_MARKET_SC_BUY_RESULT, ?MSG_FORMAT_MARKET_SC_BUY_RESULT, [Result]).

%%取回物品状态(17008)
msg_sc_get_back(Result) ->
	misc_packet:pack(?MSG_ID_MARKET_SC_FETCH_RESULT, ?MSG_FORMAT_MARKET_SC_FETCH_RESULT, [Result]).

%% 热门搜索查询(17012)
msg_sc_hot_search(List) ->
	?MSG_DEBUG("List=~p", [List]),
	F = fun(SearchInfo) when is_record(SearchInfo, market_search) ->
				{SearchInfo#market_search.goods_name}
		end,
	Data = [F(SearchInfo) ||SearchInfo <- List],
	misc_packet:pack(?MSG_ID_MARKET_SC_HOT_SEARCH, ?MSG_FORMAT_MARKET_SC_HOT_SEARCH, [Data]).

%% 获取装备物品的tips
get_goods_tips(Goods) ->
	GoodsType		= Goods#goods.type,
	case GoodsType of
		?CONST_GOODS_TYPE_EQUIP ->
			Data	= goods_api:msg_group_goods_equip(?CONST_GOODS_CTN_BAG, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, Goods),
			misc:to_list(Data);
		?CONST_GOODS_TYPE_WEAPON ->
			Data	= goods_api:msg_group_goods_weapon(?CONST_GOODS_CTN_BAG, 0, 0, Goods),
			misc:to_list(Data);
		_ ->
			[?CONST_GOODS_CTN_BAG, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, Goods#goods.idx, Goods#goods.goods_id, Goods#goods.count, 
			 Goods#goods.bind, Goods#goods.start_time, Goods#goods.end_time, Goods#goods.time_temp, ?CONST_SYS_FALSE,?CONST_SYS_FALSE,
			 ?CONST_SYS_FALSE, [], [], [], []] 
	end.

%% ets相关操作
ets_lookup_market(Tab, Id) ->
	ets_api:lookup(Tab, Id).

ets_insert_market(Tab, MarketInfo) ->
	ets_api:insert(Tab, MarketInfo).

ets_delete_market(Tab, Id) ->
	ets_api:delete(Tab, Id).

ets_insert(Tab, MarketInfo) ->
	ets:insert(Tab, MarketInfo).

ets_insert_sale(SaleInfo) ->
	ets_api:insert(?CONST_ETS_MARKET_SALE, SaleInfo).

ets_insert_buy(BuyInfo) ->
	ets_api:insert(?CONST_ETS_MARKET_BUY, BuyInfo).

ets_insert_list(Tab, [MarketInfo|MarketInfoList]) ->
	ets_insert(Tab, MarketInfo),
	ets_insert_list(Tab, MarketInfoList);
ets_insert_list(_Tab, []) ->           
	?ok.

%%
%% Local Functions
%%
%% 寄售记录数据转换
record_market_sale([SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime]) ->
	record_market_sale(SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime);
record_market_sale({SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime}) ->
	record_market_sale(SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime).

record_market_sale(SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime) ->
	#market_sale{
				 sale_id  							= SaleId,                           %% 自增寄售ID	
      			 seller_id 							= SellerId,                         %% 寄售者ID	
      			 seller_name 					 	= SellerName,                       %% 寄售者昵称	
				 buyer_id  						    = BuyerId,                          %% 购买者id	
				 buyer_name  						= BuyerName,                        %% 购买者昵称	
				 goods       						= Goods,                            %% 物品列表	
				 goods_name  						= GoodsName,                        %% 物品名称	
				 category							= Category,							%% 搜索类型
				 goods_type  						= GoodsType,                        %% 物品类型	
				 goods_sub_type  					= GoodsSubType,                     %% 物品子类型	
				 goods_level  						= GoodsLevel,                       %% 物品等级限制	
				 goods_color  						= GoodsColor,                       %% 物品颜色	
				 goods_pro  						= GoodsPro,                         %% 职业限制
				 goods_attr_type					= AttrType,							%% 宝石属性	
				 current_price 						= CurrentPrice,                     %% 出售价格：当前拍卖价格	
				 fixed_price 						= FixedPrice,                       %% 出售价格：一口价格	
				 end_time 							= EndTime                           %% 寄售物品的过期时间
				 }.


%% 寄售记录数据转换
record_market_buy([BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId]) ->
	record_market_buy(BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId);
record_market_buy({BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId}) ->
	record_market_buy(BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId).

record_market_buy(BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId) ->
	#market_buy{
				 buy_id  							= BuyId,                            %% 自增购买ID	
      			 seller_id 							= SellerId,                         %% 寄售者ID	
      			 seller_name 					 	= SellerName,                       %% 寄售者昵称	
				 buyer_id  						    = BuyerId,                          %% 购买者id	
				 buyer_name  						= BuyerName,                        %% 购买者昵称	
				 goods       						= Goods,                            %% 物品列表	
				 goods_name  						= GoodsName,                        %% 物品名称
				 category							= Category,							%% 搜索类型	
				 goods_type  						= GoodsType,                        %% 物品类型	
				 goods_sub_type  					= GoodsSubType,                     %% 物品子类型	
				 goods_level  						= GoodsLevel,                       %% 物品等级限制	
				 goods_color  						= GoodsColor,                       %% 物品颜色	
				 goods_pro  						= GoodsPro,                         %% 职业限制
				 goods_attr_type					= AttrType,							%% 宝石属性类型
				 current_price 						= CurrentPrice,                     %% 出售价格：当前拍卖价格
				 fixed_price 						= FixedPrice,                       %% 出售价格：一口价格	
				 bid_price							= BidPrice,							%% 玩家竞拍价格
				 end_time 							= EndTime,                          %% 寄售物品的过期时间
				 sale_id							= SaleId							%% 寄售记录ID
				 }.

%% 热门搜索数据转换
 record_market_search([GoodsId, GoodsName, SearchTimes]) ->
	record_market_search(GoodsId, GoodsName, SearchTimes);
record_market_search({GoodsId, GoodsName, SearchTimes}) ->
	record_market_search(GoodsId, GoodsName, SearchTimes).

record_market_search(GoodsId, GoodsName, SearchTimes) ->
	#market_search{
				   goods_id							  = GoodsId,						 %% 物品id
				   goods_name						  = GoodsName,						 %% 物品名称
				   search_times						  = SearchTimes						 %% 搜索次数 	
				 }.

