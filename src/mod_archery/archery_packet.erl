%% Author: php
%% Created:
%% Description: TODO: Add description to archery_packet
-module(archery_packet).

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
packet_format(?MSG_ID_ARCHERY_GET_SRCEEN) ->
	?MSG_FORMAT_ARCHERY_GET_SRCEEN;
packet_format(?MSG_ID_ARCHERY_SRCEEN_INFO) ->
	?MSG_FORMAT_ARCHERY_SRCEEN_INFO;
packet_format(?MSG_ID_ARCHERY_ASK_TOP_LIST) ->
	?MSG_FORMAT_ARCHERY_ASK_TOP_LIST;
packet_format(?MSG_ID_ARCHERY_GET_TOP_LIST) ->
	?MSG_FORMAT_ARCHERY_GET_TOP_LIST;
packet_format(?MSG_ID_ARCHERY_CONFIG) ->
	?MSG_FORMAT_ARCHERY_CONFIG;
packet_format(?MSG_ID_ARCHERY_SHOOT) ->
	?MSG_FORMAT_ARCHERY_SHOOT;
packet_format(?MSG_ID_ARCHERY_RESULT_SHOOT) ->
	?MSG_FORMAT_ARCHERY_RESULT_SHOOT;
packet_format(?MSG_ID_ARCHERY_ADD_ARROW) ->
	?MSG_FORMAT_ARCHERY_ADD_ARROW;
packet_format(?MSG_ID_ARCHERY_GET_ADD_ARROW) ->
	?MSG_FORMAT_ARCHERY_GET_ADD_ARROW;
packet_format(?MSG_ID_ARCHERY_GET_REWORD) ->
	?MSG_FORMAT_ARCHERY_GET_REWORD;
packet_format(?MSG_ID_ARCHERY_SC_REWORD) ->
	?MSG_FORMAT_ARCHERY_SC_REWORD;
packet_format(?MSG_ID_ARCHERY_REFRESH_COURT) ->
	?MSG_FORMAT_ARCHERY_REFRESH_COURT;
packet_format(?MSG_ID_ARCHERY_BCAST_TOP_10) ->
	?MSG_FORMAT_ARCHERY_BCAST_TOP_10;
packet_format(?MSG_ID_ARCHERY_ADD_REWARD) ->
	?MSG_FORMAT_ARCHERY_ADD_REWARD;
packet_format(?MSG_ID_ARCHERY_ASK_ARROW) ->
	?MSG_FORMAT_ARCHERY_ASK_ARROW;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
