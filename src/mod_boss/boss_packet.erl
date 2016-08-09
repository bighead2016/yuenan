%% Author: php
%% Created:
%% Description: TODO: Add description to boss_packet
-module(boss_packet).

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
packet_format(?MSG_ID_BOSS_CS_ENTER) ->
	?MSG_FORMAT_BOSS_CS_ENTER;
packet_format(?MSG_ID_BOSS_CS_AUTO) ->
	?MSG_FORMAT_BOSS_CS_AUTO;
packet_format(?MSG_ID_BOSS_CS_ENCOURAGE) ->
	?MSG_FORMAT_BOSS_CS_ENCOURAGE;
packet_format(?MSG_ID_BOSS_CS_REBORN) ->
	?MSG_FORMAT_BOSS_CS_REBORN;
packet_format(?MSG_ID_BOSS_CS_BATTLE) ->
	?MSG_FORMAT_BOSS_CS_BATTLE;
packet_format(?MSG_ID_BOSS_CS_REVIVE) ->
	?MSG_FORMAT_BOSS_CS_REVIVE;
packet_format(?MSG_ID_BOSS_CS_AUTO_REVIVE) ->
	?MSG_FORMAT_BOSS_CS_AUTO_REVIVE;
packet_format(?MSG_ID_BOSS_CS_QUIT) ->
	?MSG_FORMAT_BOSS_CS_QUIT;
packet_format(?MSG_ID_BOSS_CS_HIRE_DOLL) ->
	?MSG_FORMAT_BOSS_CS_HIRE_DOLL;
packet_format(?MSG_ID_BOSS_CS_DOLL_CASH) ->
	?MSG_FORMAT_BOSS_CS_DOLL_CASH;
packet_format(?MSG_ID_BOSS_CS_CHECK_STATE) ->
	?MSG_FORMAT_BOSS_CS_CHECK_STATE;
packet_format(?MSG_ID_BOSS_SC_ENTER) ->
	?MSG_FORMAT_BOSS_SC_ENTER;
packet_format(?MSG_ID_BOSS_SC_STATE) ->
	?MSG_FORMAT_BOSS_SC_STATE;
packet_format(?MSG_ID_BOSS_SC_MONSTER_INFO) ->
	?MSG_FORMAT_BOSS_SC_MONSTER_INFO;
packet_format(?MSG_ID_BOSS_SC_QUIT_OK) ->
	?MSG_FORMAT_BOSS_SC_QUIT_OK;
packet_format(?MSG_ID_BOSS_SC_AUTO) ->
	?MSG_FORMAT_BOSS_SC_AUTO;
packet_format(?MSG_ID_BOSS_SC_ENCOURAGE) ->
	?MSG_FORMAT_BOSS_SC_ENCOURAGE;
packet_format(?MSG_ID_BOSS_SC_REBORN) ->
	?MSG_FORMAT_BOSS_SC_REBORN;
packet_format(?MSG_ID_BOSS_SC_REVIVE) ->
	?MSG_FORMAT_BOSS_SC_REVIVE;
packet_format(?MSG_ID_BOSS_SC_HURT) ->
	?MSG_FORMAT_BOSS_SC_HURT;
packet_format(?MSG_ID_BOSS_SC_REWARD) ->
	?MSG_FORMAT_BOSS_SC_REWARD;
packet_format(?MSG_ID_BOSS_SC_EXIT_CD) ->
	?MSG_FORMAT_BOSS_SC_EXIT_CD;
packet_format(?MSG_ID_BOSS_CS_DOLL_FLAG) ->
	?MSG_FORMAT_BOSS_CS_DOLL_FLAG;
packet_format(?MSG_ID_BOSS_SC_OPEN_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_OPEN_NOTICE;
packet_format(?MSG_ID_BOSS_SC_START_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_START_NOTICE;
packet_format(?MSG_ID_BOSS_SC_END_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_END_NOTICE;
packet_format(?MSG_ID_BOSS_SC_MONSTER_HP_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_MONSTER_HP_NOTICE;
packet_format(?MSG_ID_BOSS_SC_REMOVE_MONSTER_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_REMOVE_MONSTER_NOTICE;
packet_format(?MSG_ID_BOSS_SC_UPDATE_MONSTER_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_UPDATE_MONSTER_NOTICE;
packet_format(?MSG_ID_BOSS_SC_RANK_NOTICE) ->
	?MSG_FORMAT_BOSS_SC_RANK_NOTICE;
packet_format(?MSG_ID_BOSS_SC_AUTO_REWARD) ->
	?MSG_FORMAT_BOSS_SC_AUTO_REWARD;
packet_format(?MSG_ID_BOSS_SC_DOLL_CASH) ->
	?MSG_FORMAT_BOSS_SC_DOLL_CASH;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
