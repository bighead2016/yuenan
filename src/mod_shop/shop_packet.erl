%% Author: php
%% Created:
%% Description: TODO: Add description to shop_packet
-module(shop_packet).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([packet_format/1]).
%%
%% API Functions
%%
%% *必须实现方法
%% 消息号与消息格式一一对应
packet_format(?MSG_ID_SHOP_CS_SELL) ->
	?MSG_FORMAT_SHOP_CS_SELL;
packet_format(?MSG_ID_SHOP_SC_GOODS) ->
	?MSG_FORMAT_SHOP_SC_GOODS;
packet_format(?MSG_ID_SHOP_CS_LIST_REPURCHASE) ->
	?MSG_FORMAT_SHOP_CS_LIST_REPURCHASE;
packet_format(?MSG_ID_SHOP_CS_PURCHASE) ->
	?MSG_FORMAT_SHOP_CS_PURCHASE;
packet_format(?MSG_ID_SHOP_CS_REPURCHASE) ->
	?MSG_FORMAT_SHOP_CS_REPURCHASE;
packet_format(?MSG_ID_SHOP_SC_DEL_GOODS) ->
	?MSG_FORMAT_SHOP_SC_DEL_GOODS;
packet_format(?MSG_ID_SHOP_CS_SELL_LIST) ->
	?MSG_FORMAT_SHOP_CS_SELL_LIST;
packet_format(?MSG_ID_SHOP_CS_SECRET_INIT) ->
	?MSG_FORMAT_SHOP_CS_SECRET_INIT;
packet_format(?MSG_ID_SHOP_SC_SECRET_INIT) ->
	?MSG_FORMAT_SHOP_SC_SECRET_INIT;
packet_format(?MSG_ID_SHOP_CS_SECRET_REFRESH) ->
	?MSG_FORMAT_SHOP_CS_SECRET_REFRESH;
packet_format(?MSG_ID_SHOP_SC_SECRET_REFRESH) ->
	?MSG_FORMAT_SHOP_SC_SECRET_REFRESH;
packet_format(?MSG_ID_SHOP_CS_BUY_GOODS) ->
	?MSG_FORMAT_SHOP_CS_BUY_GOODS;
packet_format(?MSG_ID_SHOP_SC_BUY_GOODS) ->
	?MSG_FORMAT_SHOP_SC_BUY_GOODS;
packet_format(?MSG_ID_SHOP_SC_LOG_INFO) ->
	?MSG_FORMAT_SHOP_SC_LOG_INFO;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
