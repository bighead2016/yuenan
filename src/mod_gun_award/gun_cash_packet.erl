%% Author: php
%% Created:
%% Description: TODO: Add description to gun_cash_packet
-module(gun_cash_packet).

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
packet_format(?MSG_ID_GUN_CASH_INFO) ->
	?MSG_FORMAT_GUN_CASH_INFO;
packet_format(?MSG_ID_GUN_CASH_GET_GUN_CASH) ->
	?MSG_FORMAT_GUN_CASH_GET_GUN_CASH;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
