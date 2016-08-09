%% Author: php
%% Created: 2012-08-02 16
%% Description: TODO: Add description to market_handler
-module(market_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%

%% 查询所有竞拍信息/查询玩家竞拍信息/热门搜索
handler(?MSG_ID_MARKET_CS_MARKET_SEARCH, Player, {SearchType, GoodsName, Category, GoodsType, GoodsSubType, 
												  LvDownLimit, LvUpLimit, Pro, Color, Page, AttrType}) ->
	market_mod:get_market_info(SearchType, GoodsName, Category, GoodsType, GoodsSubType, LvDownLimit, LvUpLimit, Pro, Color, Page, AttrType,
							   Player),
	?ok;

%% 寄售物品
handler(?MSG_ID_MARKET_CS_SEAL_GOODS, Player, {GoodsId, Grid, GoodsNum, InitPrice, FixedPrice}) ->
	{?ok, NewPlayer}	=	market_mod:sale_goods(GoodsId, Grid, GoodsNum, InitPrice, FixedPrice, Player),
	{?ok, NewPlayer};

%% 竞拍物品
handler(?MSG_ID_MARKET_CS_BUY_GOODS, Player, {Type, Id, GoodsId}) ->
	market_mod:buy_goods(Type, Id, GoodsId, Player),
	?ok;

%% 取回过期物品
handler(?MSG_ID_MARKET_CS_FETCH_GOODS, Player, {Type, Id, GoodsId}) ->
	NewPlayer 			= 	market_mod:get_out_date_goods(Type, Id, GoodsId, Player),
	{?ok, NewPlayer};

%% 查看寄售物品
handler(?MSG_ID_MARKET_CS_SEAL_INFO, Player, {}) ->
	market_mod:get_market_sale_info(Player),
	?ok;

%% 查看热门搜索物品
handler(?MSG_ID_MARKET_CS_HOT_SEARCH, Player, {}) ->
	market_mod:get_hot_search(Player),
	?ok;

%% 热门搜索物品
handler(?MSG_ID_MARKET_CS_SEARCH_HOT_GOODS, Player, {GoodsName,Page}) ->
	market_mod:get_market_hot_goods(Player, Page, GoodsName),
	?ok;
%%
%% 协议匹配错误
handler(_MsgId, _Player, _Datas) -> ?undefined.
