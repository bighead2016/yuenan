%% Author: php
%% Created:
%% Description: TODO: Add description to relation_packet
-module(relation_packet).

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
packet_format(?MSG_ID_RELATION_CS_LIST) ->
	?MSG_FORMAT_RELATION_CS_LIST;
packet_format(?MSG_ID_RELATION_SC_LIST) ->
	?MSG_FORMAT_RELATION_SC_LIST;
packet_format(?MSG_ID_RELATION_INFO_GROUP) ->
	?MSG_FORMAT_RELATION_INFO_GROUP;
packet_format(?MSG_ID_RELATION_CS_ADD) ->
	?MSG_FORMAT_RELATION_CS_ADD;
packet_format(?MSG_ID_RELATION_SC_ADD) ->
	?MSG_FORMAT_RELATION_SC_ADD;
packet_format(?MSG_ID_RELATION_ADD_NOTICE) ->
	?MSG_FORMAT_RELATION_ADD_NOTICE;
packet_format(?MSG_ID_RELATION_CS_CHANGE) ->
	?MSG_FORMAT_RELATION_CS_CHANGE;
packet_format(?MSG_ID_RELATION_SC_CHANGE) ->
	?MSG_FORMAT_RELATION_SC_CHANGE;
packet_format(?MSG_ID_RELATION_CS_DELETE) ->
	?MSG_FORMAT_RELATION_CS_DELETE;
packet_format(?MSG_ID_RELATION_SC_DELETE) ->
	?MSG_FORMAT_RELATION_SC_DELETE;
packet_format(?MSG_ID_RELATION_SC_ON_OFF) ->
	?MSG_FORMAT_RELATION_SC_ON_OFF;
packet_format(?MSG_ID_RELATION_CS_RECOMMEND) ->
	?MSG_FORMAT_RELATION_CS_RECOMMEND;
packet_format(?MSG_ID_RELATION_SC_RECOMMEND) ->
	?MSG_FORMAT_RELATION_SC_RECOMMEND;
packet_format(?MSG_ID_RELATION_CS_ONE_KEY) ->
	?MSG_FORMAT_RELATION_CS_ONE_KEY;
packet_format(?MSG_ID_RELATION_CS_COUNT) ->
	?MSG_FORMAT_RELATION_CS_COUNT;
packet_format(?MSG_ID_RELATION_SC_COUNT) ->
	?MSG_FORMAT_RELATION_SC_COUNT;
packet_format(?MSG_ID_RELATION_CS_ONE_KEY_DEL) ->
	?MSG_FORMAT_RELATION_CS_ONE_KEY_DEL;
packet_format(?MSG_ID_RELATION_SC_ONE_KEY_DEL) ->
	?MSG_FORMAT_RELATION_SC_ONE_KEY_DEL;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
