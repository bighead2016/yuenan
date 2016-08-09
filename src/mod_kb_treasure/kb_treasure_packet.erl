%% Author: php
%% Created:
%% Description: TODO: Add description to kb_treasure_packet
-module(kb_treasure_packet).

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
packet_format(?MSG_ID_KB_TREASURE_CS_TURN) ->
	?MSG_FORMAT_KB_TREASURE_CS_TURN;
packet_format(?MSG_ID_KB_TREASURE_SC_TARGET) ->
	?MSG_FORMAT_KB_TREASURE_SC_TARGET;
packet_format(?MSG_ID_KB_TREASURE_CS_SEND) ->
	?MSG_FORMAT_KB_TREASURE_CS_SEND;
packet_format(?MSG_ID_KB_TREASURE_SC_REPLY) ->
	?MSG_FORMAT_KB_TREASURE_SC_REPLY;
packet_format(?MSG_ID_KB_TREASURE_CS_GET_GROUP) ->
	?MSG_FORMAT_KB_TREASURE_CS_GET_GROUP;
packet_format(?MSG_ID_KB_TREASURE_SC_GROUP_RESULT) ->
	?MSG_FORMAT_KB_TREASURE_SC_GROUP_RESULT;
packet_format(?MSG_ID_KB_TREASURE_SC_TOTAL) ->
	?MSG_FORMAT_KB_TREASURE_SC_TOTAL;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
