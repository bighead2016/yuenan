%% Author: php
%% Created:
%% Description: TODO: Add description to market_packet
-module(market_packet).

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
packet_format(?MSG_ID_MARKET_CS_MARKET_SEARCH) ->
	?MSG_FORMAT_MARKET_CS_MARKET_SEARCH;
packet_format(?MSG_ID_MARKET_SC_SEARCH_INFO) ->
	?MSG_FORMAT_MARKET_SC_SEARCH_INFO;
packet_format(?MSG_ID_MARKET_CS_SEAL_GOODS) ->
	?MSG_FORMAT_MARKET_CS_SEAL_GOODS;
packet_format(?MSG_ID_MARKET_SC_SEAL_RESULT) ->
	?MSG_FORMAT_MARKET_SC_SEAL_RESULT;
packet_format(?MSG_ID_MARKET_CS_BUY_GOODS) ->
	?MSG_FORMAT_MARKET_CS_BUY_GOODS;
packet_format(?MSG_ID_MARKET_SC_BUY_RESULT) ->
	?MSG_FORMAT_MARKET_SC_BUY_RESULT;
packet_format(?MSG_ID_MARKET_CS_FETCH_GOODS) ->
	?MSG_FORMAT_MARKET_CS_FETCH_GOODS;
packet_format(?MSG_ID_MARKET_SC_FETCH_RESULT) ->
	?MSG_FORMAT_MARKET_SC_FETCH_RESULT;
packet_format(?MSG_ID_MARKET_CS_SEAL_INFO) ->
	?MSG_FORMAT_MARKET_CS_SEAL_INFO;
packet_format(?MSG_ID_MARKET_SC_SEAL_INFO) ->
	?MSG_FORMAT_MARKET_SC_SEAL_INFO;
packet_format(?MSG_ID_MARKET_CS_HOT_SEARCH) ->
	?MSG_FORMAT_MARKET_CS_HOT_SEARCH;
packet_format(?MSG_ID_MARKET_SC_HOT_SEARCH) ->
	?MSG_FORMAT_MARKET_SC_HOT_SEARCH;
packet_format(?MSG_ID_MARKET_CS_SEARCH_HOT_GOODS) ->
	?MSG_FORMAT_MARKET_CS_SEARCH_HOT_GOODS;
packet_format(?MSG_ID_MARKET_SC_BUY_SUCCESS) ->
	?MSG_FORMAT_MARKET_SC_BUY_SUCCESS;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
