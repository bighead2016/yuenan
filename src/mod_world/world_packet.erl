%% Author: php
%% Created:
%% Description: TODO: Add description to world_packet
-module(world_packet).

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
packet_format(?MSG_ID_WORLD_CS_ENTER) ->
	?MSG_FORMAT_WORLD_CS_ENTER;
packet_format(?MSG_ID_WORLD_CS_EXIT) ->
	?MSG_FORMAT_WORLD_CS_EXIT;
packet_format(?MSG_ID_WORLD_CS_AUTO_REVIVE) ->
	?MSG_FORMAT_WORLD_CS_AUTO_REVIVE;
packet_format(?MSG_ID_WORLD_CS_BATTLE_START) ->
	?MSG_FORMAT_WORLD_CS_BATTLE_START;
packet_format(?MSG_ID_WORLD_CS_GET_BUFF) ->
	?MSG_FORMAT_WORLD_CS_GET_BUFF;
packet_format(?MSG_ID_WORLD_CS_INVITE) ->
	?MSG_FORMAT_WORLD_CS_INVITE;
packet_format(?MSG_ID_WORLD_CS_REPLY) ->
	?MSG_FORMAT_WORLD_CS_REPLY;
packet_format(?MSG_ID_WORLD_CS_DOLL) ->
	?MSG_FORMAT_WORLD_CS_DOLL;
packet_format(?MSG_ID_WORLD_SC_DOLL) ->
	?MSG_FORMAT_WORLD_SC_DOLL;
packet_format(?MSG_ID_WORLD_SC_ENTER) ->
	?MSG_FORMAT_WORLD_SC_ENTER;
packet_format(?MSG_ID_WORLD_SC_UPDATE_MONSTER) ->
	?MSG_FORMAT_WORLD_SC_UPDATE_MONSTER;
packet_format(?MSG_ID_WORLD_SC_REMOVE_MONSTER) ->
	?MSG_FORMAT_WORLD_SC_REMOVE_MONSTER;
packet_format(?MSG_ID_WORLD_SC_EXIT_CD) ->
	?MSG_FORMAT_WORLD_SC_EXIT_CD;
packet_format(?MSG_ID_WORLD_SC_UPDATE_HURT) ->
	?MSG_FORMAT_WORLD_SC_UPDATE_HURT;
packet_format(?MSG_ID_WORLD_SC_RANK_GUILD) ->
	?MSG_FORMAT_WORLD_SC_RANK_GUILD;
packet_format(?MSG_ID_WORLD_SC_RANK_PLAYER) ->
	?MSG_FORMAT_WORLD_SC_RANK_PLAYER;
packet_format(?MSG_ID_WORLD_SC_START) ->
	?MSG_FORMAT_WORLD_SC_START;
packet_format(?MSG_ID_WORLD_SC_END) ->
	?MSG_FORMAT_WORLD_SC_END;
packet_format(?MSG_ID_WORLD_SC_BUFF_NOTICE) ->
	?MSG_FORMAT_WORLD_SC_BUFF_NOTICE;
packet_format(?MSG_ID_WORLD_SC_BUFF_INFO) ->
	?MSG_FORMAT_WORLD_SC_BUFF_INFO;
packet_format(?MSG_ID_WORLD_SC_INVITE_NOTICE) ->
	?MSG_FORMAT_WORLD_SC_INVITE_NOTICE;
packet_format(?MSG_ID_WORLD_SC_NEXT_MONSTER_NOTICE) ->
	?MSG_FORMAT_WORLD_SC_NEXT_MONSTER_NOTICE;
packet_format(?MSG_ID_WORLD_SC_LEADER_NOTICE) ->
	?MSG_FORMAT_WORLD_SC_LEADER_NOTICE;
packet_format(?MSG_ID_WORLD_REWARD_INFO) ->
	?MSG_FORMAT_WORLD_REWARD_INFO;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
