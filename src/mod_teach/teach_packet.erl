%% Author: php
%% Created:
%% Description: TODO: Add description to teach_packet
-module(teach_packet).

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
packet_format(?MSG_ID_TEACH_CS_PROCESS) ->
	?MSG_FORMAT_TEACH_CS_PROCESS;
packet_format(?MSG_ID_TEACH_SC_PROCESS) ->
	?MSG_FORMAT_TEACH_SC_PROCESS;
packet_format(?MSG_ID_TEACH_CS_BATTLE) ->
	?MSG_FORMAT_TEACH_CS_BATTLE;
packet_format(?MSG_ID_TEACH_CS_ANSWER) ->
	?MSG_FORMAT_TEACH_CS_ANSWER;
packet_format(?MSG_ID_TEACH_SC_ANSWER) ->
	?MSG_FORMAT_TEACH_SC_ANSWER;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
