%% Author: php
%% Created:
%% Description: TODO: Add description to mall_packet
-module(mall_packet).

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
packet_format(?MSG_ID_MALL_DATA_REQUEST) ->
	?MSG_FORMAT_MALL_DATA_REQUEST;
packet_format(?MSG_ID_MALL_DATA_RECV) ->
	?MSG_FORMAT_MALL_DATA_RECV;
packet_format(?MSG_ID_MALL_BUY) ->
	?MSG_FORMAT_MALL_BUY;
packet_format(?MSG_ID_MALL_CS_BUY_SALE) ->
	?MSG_FORMAT_MALL_CS_BUY_SALE;
packet_format(?MSG_ID_MALL_CS_RIDE_UP) ->
	?MSG_FORMAT_MALL_CS_RIDE_UP;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
