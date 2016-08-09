%% Author: php
%% Created:
%% Description: TODO: Add description to welfare_packet
-module(welfare_packet).

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
packet_format(?MSG_ID_WELFARE_CSGIFTINFO) ->
	?MSG_FORMAT_WELFARE_CSGIFTINFO;
packet_format(?MSG_ID_WELFARE_SCGIFTINFO) ->
	?MSG_FORMAT_WELFARE_SCGIFTINFO;
packet_format(?MSG_ID_WELFARE_CSDRAW) ->
	?MSG_FORMAT_WELFARE_CSDRAW;
packet_format(?MSG_ID_WELFARE_SCDRAW) ->
	?MSG_FORMAT_WELFARE_SCDRAW;
packet_format(?MSG_ID_WELFARE_SCPULLULATION) ->
	?MSG_FORMAT_WELFARE_SCPULLULATION;
packet_format(?MSG_ID_WELFARE_CSRECEIVE) ->
	?MSG_FORMAT_WELFARE_CSRECEIVE;
packet_format(?MSG_ID_WELFARE_SCRECEIVE) ->
	?MSG_FORMAT_WELFARE_SCRECEIVE;
packet_format(?MSG_ID_WELFARE_SC_POWER) ->
	?MSG_FORMAT_WELFARE_SC_POWER;
packet_format(?MSG_ID_WELFARE_CS_LOGIN_REVIEW) ->
	?MSG_FORMAT_WELFARE_CS_LOGIN_REVIEW;
packet_format(?MSG_ID_WELFARE_SC_LOGIN_SIGN_TIMES) ->
	?MSG_FORMAT_WELFARE_SC_LOGIN_SIGN_TIMES;
packet_format(?MSG_ID_WELFARE_SC_DEPOSIT_INFO) ->
	?MSG_FORMAT_WELFARE_SC_DEPOSIT_INFO;
packet_format(?MSG_ID_WELFARE_SC_RMB) ->
	?MSG_FORMAT_WELFARE_SC_RMB;
packet_format(?MSG_ID_WELFARE_SC_END_TIME) ->
	?MSG_FORMAT_WELFARE_SC_END_TIME;
packet_format(?MSG_ID_WELFARE_CS_GET_GIFT_2) ->
	?MSG_FORMAT_WELFARE_CS_GET_GIFT_2;
packet_format(?MSG_ID_WELFARE_CS_JJ) ->
	?MSG_FORMAT_WELFARE_CS_JJ;
packet_format(?MSG_ID_WELFARE_SC_JJ_STATE) ->
	?MSG_FORMAT_WELFARE_SC_JJ_STATE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
