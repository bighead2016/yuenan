%% Author: php
%% Created:
%% Description: TODO: Add description to mixed_serv_packet
-module(mixed_serv_packet).

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
packet_format(?MSG_ID_MIXED_SERV_REQUEST_RANK) ->
	?MSG_FORMAT_MIXED_SERV_REQUEST_RANK;
packet_format(?MSG_ID_MIXED_SERV_RANK_LIST) ->
	?MSG_FORMAT_MIXED_SERV_RANK_LIST;
packet_format(?MSG_ID_MIXED_SERV_SEE_GIFT) ->
	?MSG_FORMAT_MIXED_SERV_SEE_GIFT;
packet_format(?MSG_ID_MIXED_SERV_A_GIFT) ->
	?MSG_FORMAT_MIXED_SERV_A_GIFT;
packet_format(?MSG_ID_MIXED_SERV_WANT_GIFT) ->
	?MSG_FORMAT_MIXED_SERV_WANT_GIFT;
packet_format(?MSG_ID_MIXED_SERV_SC_WANT_GIFT) ->
	?MSG_FORMAT_MIXED_SERV_SC_WANT_GIFT;
packet_format(?MSG_ID_MIXED_SERV_CS_JOINSER_TIME) ->
	?MSG_FORMAT_MIXED_SERV_CS_JOINSER_TIME;
packet_format(?MSG_ID_MIXED_SERV_SC_JOINSER_TIME) ->
	?MSG_FORMAT_MIXED_SERV_SC_JOINSER_TIME;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
