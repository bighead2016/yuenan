%% Author: php
%% Created:
%% Description: TODO: Add description to cross_arena_packet
-module(cross_arena_packet).

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
packet_format(?MSG_ID_CROSS_ARENA_CS_ENTER) ->
	?MSG_FORMAT_CROSS_ARENA_CS_ENTER;
packet_format(?MSG_ID_CROSS_ARENA_SC_ENTER) ->
	?MSG_FORMAT_CROSS_ARENA_SC_ENTER;
packet_format(?MSG_ID_CROSS_ARENA_CS_START_BATTLE) ->
	?MSG_FORMAT_CROSS_ARENA_CS_START_BATTLE;
packet_format(?MSG_ID_CROSS_ARENA_REFRESH_GROUP_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_REFRESH_GROUP_INFO;
packet_format(?MSG_ID_CROSS_ARENA_REFRESH_MEMBER_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_REFRESH_MEMBER_INFO;
packet_format(?MSG_ID_CROSS_ARENA_CS_TOP_PHASE_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_CS_TOP_PHASE_INFO;
packet_format(?MSG_ID_CROSS_ARENA_SC_TOP_PHASE_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_SC_TOP_PHASE_INFO;
packet_format(?MSG_ID_CROSS_ARENA_CS_RANK_AWARD) ->
	?MSG_FORMAT_CROSS_ARENA_CS_RANK_AWARD;
packet_format(?MSG_ID_CROSS_ARENA_SC_RANK_AWARD) ->
	?MSG_FORMAT_CROSS_ARENA_SC_RANK_AWARD;
packet_format(?MSG_ID_CROSS_ARENA_CS_ACHIEVE) ->
	?MSG_FORMAT_CROSS_ARENA_CS_ACHIEVE;
packet_format(?MSG_ID_CROSS_ARENA_SC_ACHIEVE) ->
	?MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE;
packet_format(?MSG_ID_CROSS_ARENA_CS_ACHIEVE_REWARD) ->
	?MSG_FORMAT_CROSS_ARENA_CS_ACHIEVE_REWARD;
packet_format(?MSG_ID_CROSS_ARENA_SC_ACHIEVE_REWARD) ->
	?MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE_REWARD;
packet_format(?MSG_ID_CROSS_ARENA_CROSS_ARENA_CS_BUY) ->
	?MSG_FORMAT_CROSS_ARENA_CROSS_ARENA_CS_BUY;
packet_format(?MSG_ID_CROSS_ARENA_SC_REFRESH_REPORT) ->
	?MSG_FORMAT_CROSS_ARENA_SC_REFRESH_REPORT;
packet_format(?MSG_ID_CROSS_ARENA_CS_CROSS_PLAYER_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_CS_CROSS_PLAYER_INFO;
packet_format(?MSG_ID_CROSS_ARENA_PARTNER_INFO) ->
	?MSG_FORMAT_CROSS_ARENA_PARTNER_INFO;
packet_format(?MSG_ID_CROSS_ARENA_CROSS_ARENA_PARTNER) ->
	?MSG_FORMAT_CROSS_ARENA_CROSS_ARENA_PARTNER;
packet_format(?MSG_ID_CROSS_ARENA_PARTNER_GROUP) ->
	?MSG_FORMAT_CROSS_ARENA_PARTNER_GROUP;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
