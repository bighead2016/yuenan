%% Author: php
%% Created:
%% Description: TODO: Add description to lottery_packet
-module(lottery_packet).

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
packet_format(?MSG_ID_LOTTERY_CSINTERFACE) ->
	?MSG_FORMAT_LOTTERY_CSINTERFACE;
packet_format(?MSG_ID_LOTTERY_SCINTERFACE) ->
	?MSG_FORMAT_LOTTERY_SCINTERFACE;
packet_format(?MSG_ID_LOTTERY_CSDRAW) ->
	?MSG_FORMAT_LOTTERY_CSDRAW;
packet_format(?MSG_ID_LOTTERY_SCDRAW) ->
	?MSG_FORMAT_LOTTERY_SCDRAW;
packet_format(?MSG_ID_LOTTERY_CSACCUMULATOR) ->
	?MSG_FORMAT_LOTTERY_CSACCUMULATOR;
packet_format(?MSG_ID_LOTTERY_CSFETCH) ->
	?MSG_FORMAT_LOTTERY_CSFETCH;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
