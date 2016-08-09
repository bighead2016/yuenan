%% Author: php
%% Created:
%% Description: TODO: Add description to skill_packet
-module(skill_packet).

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
packet_format(?MSG_ID_SKILL_CS_SKILL_INFO) ->
	?MSG_FORMAT_SKILL_CS_SKILL_INFO;
packet_format(?MSG_ID_SKILL_CS_UPGRADE_SKILL) ->
	?MSG_FORMAT_SKILL_CS_UPGRADE_SKILL;
packet_format(?MSG_ID_SKILL_CS_ENABLE_SKILL) ->
	?MSG_FORMAT_SKILL_CS_ENABLE_SKILL;
packet_format(?MSG_ID_SKILL_CS_DISABLE_SKILL) ->
	?MSG_FORMAT_SKILL_CS_DISABLE_SKILL;
packet_format(?MSG_ID_SKILL_CS_EXCHANGE_SKILL_BAR) ->
	?MSG_FORMAT_SKILL_CS_EXCHANGE_SKILL_BAR;
packet_format(?MSG_ID_SKILL_CS_RESET_SKILL_POINT) ->
	?MSG_FORMAT_SKILL_CS_RESET_SKILL_POINT;
packet_format(?MSG_ID_SKILL_SC_SKILL_INFO) ->
	?MSG_FORMAT_SKILL_SC_SKILL_INFO;
packet_format(?MSG_ID_SKILL_SC_UPDRADE_SUCCESS) ->
	?MSG_FORMAT_SKILL_SC_UPDRADE_SUCCESS;
packet_format(?MSG_ID_SKILL_SC_SKILL_BAR_INFO) ->
	?MSG_FORMAT_SKILL_SC_SKILL_BAR_INFO;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
