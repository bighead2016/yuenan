%% Author: php
%% Created:
%% Description: TODO: Add description to message_packet
-module(message_packet).

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
packet_format(?MSG_ID_MESSAGE_SC_WINDOW) ->
	?MSG_FORMAT_MESSAGE_SC_WINDOW;
packet_format(?MSG_ID_MESSAGE_SC_NOTICE) ->
	?MSG_FORMAT_MESSAGE_SC_NOTICE;
packet_format(?MSG_ID_MESSAGE_SC_SYSTEM) ->
	?MSG_FORMAT_MESSAGE_SC_SYSTEM;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
