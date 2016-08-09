%% Author: php
%% Created:
%% Description: TODO: Add description to arena_pvp_packet
-module(arena_pvp_packet).

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
packet_format(?MSG_ID_ARENA_PVP_ENTER) ->
	?MSG_FORMAT_ARENA_PVP_ENTER;
packet_format(?MSG_ID_ARENA_PVP_SC_ENTER) ->
	?MSG_FORMAT_ARENA_PVP_SC_ENTER;
packet_format(?MSG_ID_ARENA_PVP_CS_ENTER_DATA) ->
	?MSG_FORMAT_ARENA_PVP_CS_ENTER_DATA;
packet_format(?MSG_ID_ARENA_PVP_START) ->
	?MSG_FORMAT_ARENA_PVP_START;
packet_format(?MSG_ID_ARENA_PVP_CS_TIGER) ->
	?MSG_FORMAT_ARENA_PVP_CS_TIGER;
packet_format(?MSG_ID_ARENA_PVP_SC_TIGER) ->
	?MSG_FORMAT_ARENA_PVP_SC_TIGER;
packet_format(?MSG_ID_ARENA_PVP_EXCHANGE) ->
	?MSG_FORMAT_ARENA_PVP_EXCHANGE;
packet_format(?MSG_ID_ARENA_PVP_CANCEL) ->
	?MSG_FORMAT_ARENA_PVP_CANCEL;
packet_format(?MSG_ID_ARENA_PVP_CS_REWARD) ->
	?MSG_FORMAT_ARENA_PVP_CS_REWARD;
packet_format(?MSG_ID_ARENA_PVP_SC_REWARD) ->
	?MSG_FORMAT_ARENA_PVP_SC_REWARD;
packet_format(?MSG_ID_ARENA_PVP_SC_DATA) ->
	?MSG_FORMAT_ARENA_PVP_SC_DATA;
packet_format(?MSG_ID_ARENA_PVP_CS_AUTO) ->
	?MSG_FORMAT_ARENA_PVP_CS_AUTO;
packet_format(?MSG_ID_ARENA_PVP_SC_AUTO) ->
	?MSG_FORMAT_ARENA_PVP_SC_AUTO;
packet_format(?MSG_ID_ARENA_PVP_CS_AUTO_DATA) ->
	?MSG_FORMAT_ARENA_PVP_CS_AUTO_DATA;
packet_format(?MSG_ID_ARENA_PVP_SC_WEEK_REWARD) ->
	?MSG_FORMAT_ARENA_PVP_SC_WEEK_REWARD;
packet_format(?MSG_ID_ARENA_PVP_END_TIMES_NOTICE) ->
	?MSG_FORMAT_ARENA_PVP_END_TIMES_NOTICE;
packet_format(?MSG_ID_ARENA_PVP_CS_RANK_DATA) ->
	?MSG_FORMAT_ARENA_PVP_CS_RANK_DATA;
packet_format(?MSG_ID_ARENA_PVP_SC_RANK_DATA) ->
	?MSG_FORMAT_ARENA_PVP_SC_RANK_DATA;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
