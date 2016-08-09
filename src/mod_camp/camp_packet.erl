%% Author: php
%% Created:
%% Description: TODO: Add description to camp_packet
-module(camp_packet).

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
packet_format(?MSG_ID_CAMP_CS_INFO) ->
	?MSG_FORMAT_CAMP_CS_INFO;
packet_format(?MSG_ID_CAMP_CS_UPGRADE) ->
	?MSG_FORMAT_CAMP_CS_UPGRADE;
packet_format(?MSG_ID_CAMP_CS_REMOVE_POS) ->
	?MSG_FORMAT_CAMP_CS_REMOVE_POS;
packet_format(?MSG_ID_CAMP_CS_EXCHANGE_POS) ->
	?MSG_FORMAT_CAMP_CS_EXCHANGE_POS;
packet_format(?MSG_ID_CAMP_CS_SET_POS) ->
	?MSG_FORMAT_CAMP_CS_SET_POS;
packet_format(?MSG_ID_CAMP_CS_START_CAMP) ->
	?MSG_FORMAT_CAMP_CS_START_CAMP;
packet_format(?MSG_ID_CAMP_CS_POS_INFO) ->
	?MSG_FORMAT_CAMP_CS_POS_INFO;
packet_format(?MSG_ID_CAMP_SC_USE) ->
	?MSG_FORMAT_CAMP_SC_USE;
packet_format(?MSG_ID_CAMP_SC_INFO) ->
	?MSG_FORMAT_CAMP_SC_INFO;
packet_format(?MSG_ID_CAMP_SC_NEW) ->
	?MSG_FORMAT_CAMP_SC_NEW;
packet_format(?MSG_ID_CAMP_SC_POS_UPDATE) ->
	?MSG_FORMAT_CAMP_SC_POS_UPDATE;
packet_format(?MSG_ID_CAMP_SC_POS_REMOVE) ->
	?MSG_FORMAT_CAMP_SC_POS_REMOVE;
packet_format(?MSG_ID_CAMP_CS_POS_NULL) ->
	?MSG_FORMAT_CAMP_CS_POS_NULL;
packet_format(?MSG_ID_CAMP_SC_POS_NULL) ->
	?MSG_FORMAT_CAMP_SC_POS_NULL;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
