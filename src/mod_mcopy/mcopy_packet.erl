%% Author: php
%% Created:
%% Description: TODO: Add description to mcopy_packet
-module(mcopy_packet).

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
packet_format(?MSG_ID_MCOPY_CS_ENTER) ->
	?MSG_FORMAT_MCOPY_CS_ENTER;
packet_format(?MSG_ID_MCOPY_ENCOUNTER) ->
	?MSG_FORMAT_MCOPY_ENCOUNTER;
packet_format(?MSG_ID_MCOPY_POINT) ->
	?MSG_FORMAT_MCOPY_POINT;
packet_format(?MSG_ID_MCOPY_MONSTER) ->
	?MSG_FORMAT_MCOPY_MONSTER;
packet_format(?MSG_ID_MCOPY_CS_LIST_COPY) ->
	?MSG_FORMAT_MCOPY_CS_LIST_COPY;
packet_format(?MSG_ID_MCOPY_SC_LIST_COPY) ->
	?MSG_FORMAT_MCOPY_SC_LIST_COPY;
packet_format(?MSG_ID_MCOPY_SC_BAR) ->
	?MSG_FORMAT_MCOPY_SC_BAR;
packet_format(?MSG_ID_MCOPY_SC_ENTER) ->
	?MSG_FORMAT_MCOPY_SC_ENTER;
packet_format(?MSG_ID_MCOPY_SC_LEFT_TIMES) ->
	?MSG_FORMAT_MCOPY_SC_LEFT_TIMES;
packet_format(?MSG_ID_MCOPY_CS_BATTLE) ->
	?MSG_FORMAT_MCOPY_CS_BATTLE;
packet_format(?MSG_ID_MCOPY_CS_NORMAL_BATTLE) ->
	?MSG_FORMAT_MCOPY_CS_NORMAL_BATTLE;
packet_format(?MSG_ID_MCOPY_CS_GET_AWARD) ->
	?MSG_FORMAT_MCOPY_CS_GET_AWARD;
packet_format(?MSG_ID_MCOPY_SC_AWARD) ->
	?MSG_FORMAT_MCOPY_SC_AWARD;
packet_format(?MSG_ID_MCOPY_CS_BUY_TIMES) ->
	?MSG_FORMAT_MCOPY_CS_BUY_TIMES;
packet_format(?MSG_ID_MCOPY_CS_EXIT) ->
	?MSG_FORMAT_MCOPY_CS_EXIT;
packet_format(?MSG_ID_MCOPY_SC_EXIT) ->
	?MSG_FORMAT_MCOPY_SC_EXIT;
packet_format(?MSG_ID_MCOPY_CS_ENTER_SKIP) ->
	?MSG_FORMAT_MCOPY_CS_ENTER_SKIP;
packet_format(?MSG_ID_MCOPY_SC_END) ->
	?MSG_FORMAT_MCOPY_SC_END;
packet_format(?MSG_ID_MCOPY_SC_BUFF) ->
	?MSG_FORMAT_MCOPY_SC_BUFF;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
