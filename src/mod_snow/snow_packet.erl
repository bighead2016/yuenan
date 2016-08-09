%% Author: php
%% Created:
%% Description: TODO: Add description to snow_packet
-module(snow_packet).

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
packet_format(?MSG_ID_SNOW_CS_GET_INFO) ->
	?MSG_FORMAT_SNOW_CS_GET_INFO;
packet_format(?MSG_ID_SNOW_SC_GET_INFO) ->
	?MSG_FORMAT_SNOW_SC_GET_INFO;
packet_format(?MSG_ID_SNOW_CS_CLICK) ->
	?MSG_FORMAT_SNOW_CS_CLICK;
packet_format(?MSG_ID_SNOW_SC_AWARD) ->
	?MSG_FORMAT_SNOW_SC_AWARD;
packet_format(?MSG_ID_SNOW_CS_CLICK_ONEKEY) ->
	?MSG_FORMAT_SNOW_CS_CLICK_ONEKEY;
packet_format(?MSG_ID_SNOW_CS_STORE_AWARD) ->
	?MSG_FORMAT_SNOW_CS_STORE_AWARD;
packet_format(?MSG_ID_SNOW_SC_STORE_AWARD) ->
	?MSG_FORMAT_SNOW_SC_STORE_AWARD;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
