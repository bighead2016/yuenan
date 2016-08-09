%% Author: php
%% Created:
%% Description: TODO: Add description to chat_packet
-module(chat_packet).

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
packet_format(?MSG_ID_CHAT_CS_CHAT) ->
	?MSG_FORMAT_CHAT_CS_CHAT;
packet_format(?MSG_ID_CHAT_SC_CHAT) ->
	?MSG_FORMAT_CHAT_SC_CHAT;
packet_format(?MSG_ID_CHAT_SC_SYS) ->
	?MSG_FORMAT_CHAT_SC_SYS;
packet_format(?MSG_ID_CHAT_CS_PRIVATE) ->
	?MSG_FORMAT_CHAT_CS_PRIVATE;
packet_format(?MSG_ID_CHAT_SC_PRIVATE) ->
	?MSG_FORMAT_CHAT_SC_PRIVATE;
packet_format(?MSG_ID_CHAT_SC_BLACK) ->
	?MSG_FORMAT_CHAT_SC_BLACK;
packet_format(?MSG_ID_CHAT_CS_REQUEST_DATA) ->
	?MSG_FORMAT_CHAT_CS_REQUEST_DATA;
packet_format(?MSG_ID_CHAT_SC_USER_DATA) ->
	?MSG_FORMAT_CHAT_SC_USER_DATA;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
