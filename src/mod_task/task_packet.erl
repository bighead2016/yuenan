%% Author: php
%% Created:
%% Description: TODO: Add description to task_packet
-module(task_packet).

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
packet_format(?MSG_ID_TASK_CS_INFO) ->
	?MSG_FORMAT_TASK_CS_INFO;
packet_format(?MSG_ID_TASK_SC_INFO) ->
	?MSG_FORMAT_TASK_SC_INFO;
packet_format(?MSG_ID_TASK_CS_ACCEPT) ->
	?MSG_FORMAT_TASK_CS_ACCEPT;
packet_format(?MSG_ID_TASK_SC_NOT_ACCEPTABLE_MAIN) ->
	?MSG_FORMAT_TASK_SC_NOT_ACCEPTABLE_MAIN;
packet_format(?MSG_ID_TASK_CS_SUBMIT) ->
	?MSG_FORMAT_TASK_CS_SUBMIT;
packet_format(?MSG_ID_TASK_CS_ABANDON) ->
	?MSG_FORMAT_TASK_CS_ABANDON;
packet_format(?MSG_ID_TASK_CS_AUTO_FINISH) ->
	?MSG_FORMAT_TASK_CS_AUTO_FINISH;
packet_format(?MSG_ID_TASK_SC_REMOVE) ->
	?MSG_FORMAT_TASK_SC_REMOVE;
packet_format(?MSG_ID_TASK_SC_DAILY_COUNT) ->
	?MSG_FORMAT_TASK_SC_DAILY_COUNT;
packet_format(?MSG_ID_TASK_SC_GUILD_COUNT) ->
	?MSG_FORMAT_TASK_SC_GUILD_COUNT;
packet_format(?MSG_ID_TASK_CS_TEST_KILL) ->
	?MSG_FORMAT_TASK_CS_TEST_KILL;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
