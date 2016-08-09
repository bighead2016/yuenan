%% Author: Administrator
%% Created: 2012-11-6
%% Description: TODO: Add description to market_db_mod
-module(market_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.goods.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([insert_market_sale/16, insert_marekt_buy_info/18, update_buyer_info/6, update_buyer_info1/4, update_buyer_info2/3,
		 update_search_goods/3, update_search_goods1/3]).

%%
%% API Functions
%%
%% 把竞拍信息添加到数据库和ets中
insert_market_sale(SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime) ->
	case goods_api:zip_goods(Goods) of
		?null -> {?error, ?TIP_COMMON_BAD_ARG}; % 参数错误
		ZipedGoods ->
			case mysql_api:insert(game_market_sale,
								  [{seller_id, SellerId}, 
								   {seller_name, SellerName}, 
								   {buyer_id, BuyerId}, 
								   {buyer_name, BuyerName},
								   {goods, misc:encode(ZipedGoods)}, 
								   {goods_name, GoodsName}, 
								   {category,	Category},
								   {goods_type, GoodsType},	
								   {goods_sub_type, GoodsSubType},
								   {goods_level, GoodsLevel}, 
								   {goods_color, GoodsColor},	
								   {goods_pro, GoodsPro},
								   {goods_attr_type, AttrType},
								   {current_price, CurrentPrice}, 
								   {fixed_price, FixedPrice}, 
								   {end_time, EndTime}
								  ]) of
				{?ok, _, SaleId} ->
					SaleInfo = market_api:record_market_sale(SaleId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, 
															 GoodsSubType,GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, EndTime),
					market_api:ets_insert_sale(SaleInfo),
					{?ok, SaleInfo};
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end
	end.


%% 把购买信息添加到数据库和ets中
insert_marekt_buy_info(SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, GoodsSubType,
						GoodsLevel, GoodsColor, GoodsPro, AttrType, CurrentPrice, FixedPrice, BidPrice, EndTime, SaleId) ->
	case goods_api:zip_goods(Goods) of
		?null -> {?error, ?TIP_COMMON_BAD_ARG}; % 参数错误
		ZipedGoods ->
			case mysql_api:insert(game_market_buy,
								  [{seller_id, SellerId}, 
								   {seller_name, SellerName}, 
								   {buyer_id, BuyerId}, 
								   {buyer_name, BuyerName},
								   {goods, misc:encode(ZipedGoods)},	
								   {goods_name, GoodsName},
								   {category, Category},
								   {goods_type, GoodsType}, 
								   {goods_sub_type, GoodsSubType},
								   {goods_level, GoodsLevel}, 
								   {goods_color, GoodsColor}, 
								   {goods_pro, GoodsPro}, 
								   {goods_attr_type, AttrType},
								   {current_price, CurrentPrice},
								   {fixed_price, FixedPrice}, 
								   {bid_price, BidPrice}, 
								   {end_time, EndTime}, 
								   {sale_id, SaleId}
								  ]) of
				{?ok, _, BuyId} ->
					BuyInfo = market_api:record_market_buy(BuyId, SellerId, SellerName, BuyerId, BuyerName, Goods, GoodsName, Category, GoodsType, 
														   GoodsSubType, GoodsLevel, GoodsColor, GoodsPro, AttrType,CurrentPrice, FixedPrice, 
														   BidPrice, EndTime, SaleId),
					market_api:ets_insert_buy(BuyInfo),
					{?ok, BuyInfo};
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end
	end.

%% 在浏览界面竞拍更新浏览界面信息
update_buyer_info(Id, BuyerId, BuyerName, NewCurrentPrice, NewEndTime, Player) -> %% 更新浏览界面显示
	case mysql_api:update(game_market_sale, 
						  					[{buyer_id, BuyerId},
											 {buyer_name, BuyerName},
											 {current_price, NewCurrentPrice}, 
											 {end_time, NewEndTime}
											],[{sale_id, Id}]) of
		{?ok, _} ->
			ets:update_element(?CONST_ETS_MARKET_SALE, Id, 
							   				[{#market_sale.buyer_id, BuyerId},
											 {#market_sale.buyer_name, BuyerName},
											 {#market_sale.current_price, NewCurrentPrice}, 
											 {#market_sale.end_time, NewEndTime}
											]),
			?ok;
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			TipPacket	=	message_api:msg_notice(?TIP_COMMON_ERROR_DB),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

update_buyer_info1(BuyId, NewCurrentPrice, NewEndTime, Player) ->         %%更新竞拍界面显示的竞拍者信息
	case mysql_api:update(game_market_buy, 
						  				[{current_price, NewCurrentPrice}, 
						   				 {end_time, NewEndTime}, 
						   				 {bid_price, NewCurrentPrice}
						  				], [{buy_id, BuyId}]) of
		{?ok, _} ->
			ets:update_element(?CONST_ETS_MARKET_BUY, BuyId, 
							   						[{#market_buy.current_price, NewCurrentPrice}, 
													 {#market_buy.end_time, NewEndTime},
													 {#market_buy.bid_price, NewCurrentPrice}
													]),
			?ok;
		{?error, ErrorCode} ->
			?MSG_ERROR("Error:~p",[ErrorCode]),
			TipPacket2	=	message_api:msg_notice(?TIP_COMMON_ERROR_DB),
			misc_packet:send(Player#player.net_pid, TipPacket2)
	end.

update_buyer_info2(BuyId, NewCurrentPrice, NewEndTime) ->
	case mysql_api:update(game_market_buy, 
						  				[{current_price, NewCurrentPrice}, 
						   				 {end_time, NewEndTime}
						  				],[{buy_id, BuyId}]) of
		{?ok, _} ->
			ets:update_element(?CONST_ETS_MARKET_BUY, BuyId, 
							   			[{#market_buy.current_price, NewCurrentPrice}, 
										 {#market_buy.end_time, NewEndTime}
										]),
			?ok;
		{?error, ErrorReason} ->
			?MSG_ERROR("Error:~p",[ErrorReason]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

update_search_goods(GoodsId, GoodsName, SearchTimes) ->
	mysql_api:insert(game_market_search, [
											{goods_id, GoodsId}, 
											{goods_name, GoodsName}, 
											{search_times, SearchTimes}
										 ]).

update_search_goods1(GoodsId, _GoodsName, SearchTimes) ->
	mysql_api:update(game_market_search, [
											{search_times, SearchTimes}
										 ], [{goods_id, GoodsId}]).
