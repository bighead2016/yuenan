%% Author: php
%% Created:
%% Description: TODO: Add description to ability_packet
-module(ability_packet).

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
packet_format(?MSG_ID_ABILITY_CS_INFO) ->
	?MSG_FORMAT_ABILITY_CS_INFO;
packet_format(?MSG_ID_ABILITY_CS_UPGRADE) ->
	?MSG_FORMAT_ABILITY_CS_UPGRADE;
packet_format(?MSG_ID_ABILITY_CS_CLEAR_CD) ->
	?MSG_FORMAT_ABILITY_CS_CLEAR_CD;
packet_format(?MSG_ID_ABILITY_CS_EXT_INFO) ->
	?MSG_FORMAT_ABILITY_CS_EXT_INFO;
packet_format(?MSG_ID_ABILITY_CS_EXT_REFRESH) ->
	?MSG_FORMAT_ABILITY_CS_EXT_REFRESH;
packet_format(?MSG_ID_ABILITY_SC_CD) ->
	?MSG_FORMAT_ABILITY_SC_CD;
packet_format(?MSG_ID_ABILITY_SC_INFO) ->
	?MSG_FORMAT_ABILITY_SC_INFO;
packet_format(?MSG_ID_ABILITY_SC_EXT_INFO) ->
	?MSG_FORMAT_ABILITY_SC_EXT_INFO;
packet_format(?MSG_ID_ABILITY_MONEY_LEVEL_UP) ->
	?MSG_FORMAT_ABILITY_MONEY_LEVEL_UP;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
