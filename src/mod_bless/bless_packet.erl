%% Author: php
%% Created:
%% Description: TODO: Add description to bless_packet
-module(bless_packet).

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
packet_format(?MSG_ID_BLESS_CS_BLESS) ->
	?MSG_FORMAT_BLESS_CS_BLESS;
packet_format(?MSG_ID_BLESS_SC_BLESS) ->
	?MSG_FORMAT_BLESS_SC_BLESS;
packet_format(?MSG_ID_BLESS_CS_GET_EXP) ->
	?MSG_FORMAT_BLESS_CS_GET_EXP;
packet_format(?MSG_ID_BLESS_CS_BATTLE_DATA) ->
	?MSG_FORMAT_BLESS_CS_BATTLE_DATA;
packet_format(?MSG_ID_BLESS_SC_BATTLE_DATA) ->
	?MSG_FORMAT_BLESS_SC_BATTLE_DATA;
packet_format(?MSG_ID_BLESS_BATTLE_INFO) ->
	?MSG_FORMAT_BLESS_BATTLE_INFO;
packet_format(?MSG_ID_BLESS_SC_BLESS_DATA) ->
	?MSG_FORMAT_BLESS_SC_BLESS_DATA;
packet_format(?MSG_ID_BLESS_CS_ONE_KEY) ->
	?MSG_FORMAT_BLESS_CS_ONE_KEY;
packet_format(?MSG_ID_BLESS_CS_READ) ->
	?MSG_FORMAT_BLESS_CS_READ;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
