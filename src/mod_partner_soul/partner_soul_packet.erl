%% Author: php
%% Created:
%% Description: TODO: Add description to partner_soul_packet
-module(partner_soul_packet).

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
packet_format(?MSG_ID_PARTNER_SOUL_CS_UPGRADE) ->
	?MSG_FORMAT_PARTNER_SOUL_CS_UPGRADE;
packet_format(?MSG_ID_PARTNER_SOUL_SC_UPGRADE) ->
	?MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE;
packet_format(?MSG_ID_PARTNER_SOUL_CS_UPGRADE_STAR) ->
	?MSG_FORMAT_PARTNER_SOUL_CS_UPGRADE_STAR;
packet_format(?MSG_ID_PARTNER_SOUL_SC_UPGRADE_STAR) ->
	?MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE_STAR;
packet_format(?MSG_ID_PARTNER_SOUL_CS_INHERIT) ->
	?MSG_FORMAT_PARTNER_SOUL_CS_INHERIT;
packet_format(?MSG_ID_PARTNER_SOUL_SC_INHERIT) ->
	?MSG_FORMAT_PARTNER_SOUL_SC_INHERIT;
packet_format(?MSG_ID_PARTNER_SOUL_CS_INFO) ->
	?MSG_FORMAT_PARTNER_SOUL_CS_INFO;
packet_format(?MSG_ID_PARTNER_SOUL_SC_INFO) ->
	?MSG_FORMAT_PARTNER_SOUL_SC_INFO;
packet_format(?MSG_ID_PARTNER_SOUL_CS_ATTR) ->
	?MSG_FORMAT_PARTNER_SOUL_CS_ATTR;
packet_format(?MSG_ID_PARTNER_SOUL_SC_ATTR) ->
	?MSG_FORMAT_PARTNER_SOUL_SC_ATTR;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
