%% Author: php
%% Created:
%% Description: TODO: Add description to collect_packet
-module(collect_packet).

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
packet_format(?MSG_ID_COLLECT_CS_START_COLLECT) ->
	?MSG_FORMAT_COLLECT_CS_START_COLLECT;
packet_format(?MSG_ID_COLLECT_SC_START) ->
	?MSG_FORMAT_COLLECT_SC_START;
packet_format(?MSG_ID_COLLECT_SC_COLLECT_INFO) ->
	?MSG_FORMAT_COLLECT_SC_COLLECT_INFO;
packet_format(?MSG_ID_COLLECT_CS_END_COLLECT) ->
	?MSG_FORMAT_COLLECT_CS_END_COLLECT;
packet_format(?MSG_ID_COLLECT_CS_ENTER_MAP) ->
	?MSG_FORMAT_COLLECT_CS_ENTER_MAP;
packet_format(?MSG_ID_COLLECT_CS_EXIT_MAP) ->
	?MSG_FORMAT_COLLECT_CS_EXIT_MAP;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
