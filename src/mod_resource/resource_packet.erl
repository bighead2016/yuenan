%% Author: php
%% Created:
%% Description: TODO: Add description to resource_packet
-module(resource_packet).

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
packet_format(?MSG_ID_RESOURCE_CSRUNEINFO) ->
	?MSG_FORMAT_RESOURCE_CSRUNEINFO;
packet_format(?MSG_ID_RESOURCE_SCRUNEINFO) ->
	?MSG_FORMAT_RESOURCE_SCRUNEINFO;
packet_format(?MSG_ID_RESOURCE_CSUSERUNE) ->
	?MSG_FORMAT_RESOURCE_CSUSERUNE;
packet_format(?MSG_ID_RESOURCE_SCRUNECHESTINFO) ->
	?MSG_FORMAT_RESOURCE_SCRUNECHESTINFO;
packet_format(?MSG_ID_RESOURCE_CSRUNEUPGRADE) ->
	?MSG_FORMAT_RESOURCE_CSRUNEUPGRADE;
packet_format(?MSG_ID_RESOURCE_CSOPENRUNECHEST) ->
	?MSG_FORMAT_RESOURCE_CSOPENRUNECHEST;
packet_format(?MSG_ID_RESOURCE_CSPRAYINFO) ->
	?MSG_FORMAT_RESOURCE_CSPRAYINFO;
packet_format(?MSG_ID_RESOURCE_SCPRAYINFO) ->
	?MSG_FORMAT_RESOURCE_SCPRAYINFO;
packet_format(?MSG_ID_RESOURCE_CSUSEPRAY) ->
	?MSG_FORMAT_RESOURCE_CSUSEPRAY;
packet_format(?MSG_ID_RESOURCE_SC_POOL) ->
	?MSG_FORMAT_RESOURCE_SC_POOL;
packet_format(?MSG_ID_RESOURCE_CS_1) ->
	?MSG_FORMAT_RESOURCE_CS_1;
packet_format(?MSG_ID_RESOURCE_SC_COUNT) ->
	?MSG_FORMAT_RESOURCE_SC_COUNT;
packet_format(?MSG_ID_RESOURCE_CS_REQ_POOL) ->
	?MSG_FORMAT_RESOURCE_CS_REQ_POOL;
packet_format(?MSG_ID_RESOURCE_SC_CD) ->
	?MSG_FORMAT_RESOURCE_SC_CD;
packet_format(?MSG_ID_RESOURCE_CS_CLEAR_CD) ->
	?MSG_FORMAT_RESOURCE_CS_CLEAR_CD;
packet_format(?MSG_ID_RESOURCE_SC_WINNING) ->
	?MSG_FORMAT_RESOURCE_SC_WINNING;
packet_format(?MSG_ID_RESOURCE_CS_BIG_AWARD) ->
	?MSG_FORMAT_RESOURCE_CS_BIG_AWARD;
packet_format(?MSG_ID_RESOURCE_SC_BIG_AWARD) ->
	?MSG_FORMAT_RESOURCE_SC_BIG_AWARD;
packet_format(?MSG_ID_RESOURCE_SC_AWARD) ->
	?MSG_FORMAT_RESOURCE_SC_AWARD;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
