%% Author: php
%% Created:
%% Description: TODO: Add description to active_packet
-module(active_packet).

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
packet_format(?MSG_ID_ACTIVE_BEGIN) ->
	?MSG_FORMAT_ACTIVE_BEGIN;
packet_format(?MSG_ID_ACTIVE_END) ->
	?MSG_FORMAT_ACTIVE_END;
packet_format(?MSG_ID_ACTIVE_PREPARE) ->
	?MSG_FORMAT_ACTIVE_PREPARE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
