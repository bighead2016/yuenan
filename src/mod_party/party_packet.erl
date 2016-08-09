%% Author: php
%% Created:
%% Description: TODO: Add description to party_packet
-module(party_packet).

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
packet_format(?MSG_ID_PARTY_CS_ENTER) ->
	?MSG_FORMAT_PARTY_CS_ENTER;
packet_format(?MSG_ID_PARTY_CS_QUIT) ->
	?MSG_FORMAT_PARTY_CS_QUIT;
packet_format(?MSG_ID_PARTY_SC_TIME) ->
	?MSG_FORMAT_PARTY_SC_TIME;
packet_format(?MSG_ID_PARTY_SC_PLAY_TIME) ->
	?MSG_FORMAT_PARTY_SC_PLAY_TIME;
packet_format(?MSG_ID_PARTY_SC_PLAY_START) ->
	?MSG_FORMAT_PARTY_SC_PLAY_START;
packet_format(?MSG_ID_PARTY_SC_REWARD) ->
	?MSG_FORMAT_PARTY_SC_REWARD;
packet_format(?MSG_ID_PARTY_CS_GET_SP) ->
	?MSG_FORMAT_PARTY_CS_GET_SP;
packet_format(?MSG_ID_PARTY_SC_SP_TIME) ->
	?MSG_FORMAT_PARTY_SC_SP_TIME;
packet_format(?MSG_ID_PARTY_SC_BOX_DATA) ->
	?MSG_FORMAT_PARTY_SC_BOX_DATA;
packet_format(?MSG_ID_PARTY_CS_OPEN_BOX) ->
	?MSG_FORMAT_PARTY_CS_OPEN_BOX;
packet_format(?MSG_ID_PARTY_SC_REMOVE_BOX) ->
	?MSG_FORMAT_PARTY_SC_REMOVE_BOX;
packet_format(?MSG_ID_PARTY_SC_MONSTER_DATA) ->
	?MSG_FORMAT_PARTY_SC_MONSTER_DATA;
packet_format(?MSG_ID_PARTY_CS_BATTLE_START) ->
	?MSG_FORMAT_PARTY_CS_BATTLE_START;
packet_format(?MSG_ID_PARTY_SC_REMOVE_MONSTER) ->
	?MSG_FORMAT_PARTY_SC_REMOVE_MONSTER;
packet_format(?MSG_ID_PARTY_SC_END_REWARD) ->
	?MSG_FORMAT_PARTY_SC_END_REWARD;
packet_format(?MSG_ID_PARTY_SC_NOTICE) ->
	?MSG_FORMAT_PARTY_SC_NOTICE;
packet_format(?MSG_ID_PARTY_SC_AUTO_REWARD) ->
	?MSG_FORMAT_PARTY_SC_AUTO_REWARD;
packet_format(?MSG_ID_PARTY_CS_AUTO_PK) ->
	?MSG_FORMAT_PARTY_CS_AUTO_PK;
packet_format(?MSG_ID_PARTY_SC_AUTO_PK) ->
	?MSG_FORMAT_PARTY_SC_AUTO_PK;
packet_format(?MSG_ID_PARTY_CS_APPLY_PK) ->
	?MSG_FORMAT_PARTY_CS_APPLY_PK;
packet_format(?MSG_ID_PARTY_SC_APPLY_PK) ->
	?MSG_FORMAT_PARTY_SC_APPLY_PK;
packet_format(?MSG_ID_PARTY_CS_REPLY_PK) ->
	?MSG_FORMAT_PARTY_CS_REPLY_PK;
packet_format(?MSG_ID_PARTY_CS_DOLL) ->
	?MSG_FORMAT_PARTY_CS_DOLL;
packet_format(?MSG_ID_PARTY_SC_DOLL) ->
	?MSG_FORMAT_PARTY_SC_DOLL;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
