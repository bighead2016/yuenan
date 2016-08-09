%% Author: php
%% Created:
%% Description: TODO: Add description to achievement_packet
-module(achievement_packet).

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
packet_format(?MSG_ID_ACHIEVEMENT_CSARRIVALDATA) ->
	?MSG_FORMAT_ACHIEVEMENT_CSARRIVALDATA;
packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVALDATA) ->
	?MSG_FORMAT_ACHIEVEMENT_SCARRIVALDATA;
packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVAL) ->
	?MSG_FORMAT_ACHIEVEMENT_SCARRIVAL;
packet_format(?MSG_ID_ACHIEVEMENT_CSARRIVALGIFT) ->
	?MSG_FORMAT_ACHIEVEMENT_CSARRIVALGIFT;
packet_format(?MSG_ID_ACHIEVEMENT_SCARRIVALGIFT) ->
	?MSG_FORMAT_ACHIEVEMENT_SCARRIVALGIFT;
packet_format(?MSG_ID_ACHIEVEMENT_CSTITLECHANGE) ->
	?MSG_FORMAT_ACHIEVEMENT_CSTITLECHANGE;
packet_format(?MSG_ID_ACHIEVEMENT_SCTITLECHANGE) ->
	?MSG_FORMAT_ACHIEVEMENT_SCTITLECHANGE;
packet_format(?MSG_ID_ACHIEVEMENT_CS_TITLE_LIST) ->
	?MSG_FORMAT_ACHIEVEMENT_CS_TITLE_LIST;
packet_format(?MSG_ID_ACHIEVEMENT_SC_TITLE_LIST) ->
	?MSG_FORMAT_ACHIEVEMENT_SC_TITLE_LIST;
packet_format(?MSG_ID_ACHIEVEMENT_SC_TITLE_CHANGE) ->
	?MSG_FORMAT_ACHIEVEMENT_SC_TITLE_CHANGE;
packet_format(?MSG_ID_ACHIEVEMENT_CS_INVALIDATE) ->
	?MSG_FORMAT_ACHIEVEMENT_CS_INVALIDATE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
