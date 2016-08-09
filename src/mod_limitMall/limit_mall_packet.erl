%% Author: php
%% Created:
%% Description: TODO: Add description to limit_mall_packet
-module(limit_mall_packet).

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
packet_format(?MSG_ID_LIMIT_MALL_REQUEST_MALL) ->
	?MSG_FORMAT_LIMIT_MALL_REQUEST_MALL;
packet_format(?MSG_ID_LIMIT_MALL_MALL_GOODS) ->
	?MSG_FORMAT_LIMIT_MALL_MALL_GOODS;
packet_format(?MSG_ID_LIMIT_MALL_OPEN_DOOR) ->
	?MSG_FORMAT_LIMIT_MALL_OPEN_DOOR;
packet_format(?MSG_ID_LIMIT_MALL_BUY) ->
	?MSG_FORMAT_LIMIT_MALL_BUY;
packet_format(?MSG_ID_LIMIT_MALL_RECEIPT) ->
	?MSG_FORMAT_LIMIT_MALL_RECEIPT;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
