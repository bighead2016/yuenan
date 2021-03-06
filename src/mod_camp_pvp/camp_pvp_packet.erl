%% Author: php
%% Created:
%% Description: TODO: Add description to camp_pvp_packet
-module(camp_pvp_packet).

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
packet_format(?MSG_ID_CAMP_PVP_CS_ENTER) ->
	?MSG_FORMAT_CAMP_PVP_CS_ENTER;
packet_format(?MSG_ID_CAMP_PVP_CS_DIG_RECOURCE) ->
	?MSG_FORMAT_CAMP_PVP_CS_DIG_RECOURCE;
packet_format(?MSG_ID_CAMP_PVP_CS_SUBMIT_RECOURCE) ->
	?MSG_FORMAT_CAMP_PVP_CS_SUBMIT_RECOURCE;
packet_format(?MSG_ID_CAMP_PVP_CS_BATTLE) ->
	?MSG_FORMAT_CAMP_PVP_CS_BATTLE;
packet_format(?MSG_ID_CAMP_PVP_CS_EXIT) ->
	?MSG_FORMAT_CAMP_PVP_CS_EXIT;
packet_format(?MSG_ID_CAMP_PVP_CS_CAMP_INFO) ->
	?MSG_FORMAT_CAMP_PVP_CS_CAMP_INFO;
packet_format(?MSG_ID_CAMP_PVP_CS_CHANGE_STATE) ->
	?MSG_FORMAT_CAMP_PVP_CS_CHANGE_STATE;
packet_format(?MSG_ID_CAMP_PVP_GIVE_UP_MINING) ->
	?MSG_FORMAT_CAMP_PVP_GIVE_UP_MINING;
packet_format(?MSG_ID_CAMP_PVP_BATTLE_OVER_JUMP) ->
	?MSG_FORMAT_CAMP_PVP_BATTLE_OVER_JUMP;
packet_format(?MSG_ID_CAMP_PVP_MAP_INIT_FINISH) ->
	?MSG_FORMAT_CAMP_PVP_MAP_INIT_FINISH;
packet_format(?MSG_ID_CAMP_PVP_ENCOURAGE) ->
	?MSG_FORMAT_CAMP_PVP_ENCOURAGE;
packet_format(?MSG_ID_CAMP_PVP_CS_ATT_CAR) ->
	?MSG_FORMAT_CAMP_PVP_CS_ATT_CAR;
packet_format(?MSG_ID_CAMP_PVP_GIVE_UP_ATT_CAR) ->
	?MSG_FORMAT_CAMP_PVP_GIVE_UP_ATT_CAR;
packet_format(?MSG_ID_CAMP_PVP_BUY_ITEM) ->
	?MSG_FORMAT_CAMP_PVP_BUY_ITEM;
packet_format(?MSG_ID_CAMP_PVP_REQUEST_SCORE) ->
	?MSG_FORMAT_CAMP_PVP_REQUEST_SCORE;
packet_format(?MSG_ID_CAMP_PVP_CREATE_TEAM) ->
	?MSG_FORMAT_CAMP_PVP_CREATE_TEAM;
packet_format(?MSG_ID_CAMP_PVP_LEAVE_TEAM) ->
	?MSG_FORMAT_CAMP_PVP_LEAVE_TEAM;
packet_format(?MSG_ID_CAMP_PVP_INVITE) ->
	?MSG_FORMAT_CAMP_PVP_INVITE;
packet_format(?MSG_ID_CAMP_PVP_KICK) ->
	?MSG_FORMAT_CAMP_PVP_KICK;
packet_format(?MSG_ID_CAMP_PVP_OPEN_CASH) ->
	?MSG_FORMAT_CAMP_PVP_OPEN_CASH;
packet_format(?MSG_ID_CAMP_PVP_OPEN_CASH_FINISH) ->
	?MSG_FORMAT_CAMP_PVP_OPEN_CASH_FINISH;
packet_format(?MSG_ID_CAMP_PVP_SC_ENTER) ->
	?MSG_FORMAT_CAMP_PVP_SC_ENTER;
packet_format(?MSG_ID_CAMP_PVP_SC_RANK) ->
	?MSG_FORMAT_CAMP_PVP_SC_RANK;
packet_format(?MSG_ID_CAMP_PVP_SC_DIG_SUCCESS) ->
	?MSG_FORMAT_CAMP_PVP_SC_DIG_SUCCESS;
packet_format(?MSG_ID_CAMP_PVP_SC_START) ->
	?MSG_FORMAT_CAMP_PVP_SC_START;
packet_format(?MSG_ID_CAMP_PVP_SC_END) ->
	?MSG_FORMAT_CAMP_PVP_SC_END;
packet_format(?MSG_ID_CAMP_PVP_ADD_MONSTER) ->
	?MSG_FORMAT_CAMP_PVP_ADD_MONSTER;
packet_format(?MSG_ID_CAMP_PVP_MONSTER_MOVE) ->
	?MSG_FORMAT_CAMP_PVP_MONSTER_MOVE;
packet_format(?MSG_ID_CAMP_PVP_MONSTER_STOP) ->
	?MSG_FORMAT_CAMP_PVP_MONSTER_STOP;
packet_format(?MSG_ID_CAMP_PVP_MONSTER_KILLED) ->
	?MSG_FORMAT_CAMP_PVP_MONSTER_KILLED;
packet_format(?MSG_ID_CAMP_PVP_MONSTER_ATTACK) ->
	?MSG_FORMAT_CAMP_PVP_MONSTER_ATTACK;
packet_format(?MSG_ID_CAMP_PVP_SC_CAMP_INFO) ->
	?MSG_FORMAT_CAMP_PVP_SC_CAMP_INFO;
packet_format(?MSG_ID_CAMP_PVP_SC_MONSTER_INFO) ->
	?MSG_FORMAT_CAMP_PVP_SC_MONSTER_INFO;
packet_format(?MSG_ID_CAMP_PVP_PLAYER_STATE) ->
	?MSG_FORMAT_CAMP_PVP_PLAYER_STATE;
packet_format(?MSG_ID_CAMP_PVP_PLAYER_STATE_LIST) ->
	?MSG_FORMAT_CAMP_PVP_PLAYER_STATE_LIST;
packet_format(?MSG_ID_CAMP_PVP_BUFF_MISS) ->
	?MSG_FORMAT_CAMP_PVP_BUFF_MISS;
packet_format(?MSG_ID_CAMP_PVP_HURT_ALL_BOSS) ->
	?MSG_FORMAT_CAMP_PVP_HURT_ALL_BOSS;
packet_format(?MSG_ID_CAMP_PVP_HP_CHANGE) ->
	?MSG_FORMAT_CAMP_PVP_HP_CHANGE;
packet_format(?MSG_ID_CAMP_PVP_IS_BATTLE_START) ->
	?MSG_FORMAT_CAMP_PVP_IS_BATTLE_START;
packet_format(?MSG_ID_CAMP_PVP_ENTER_CD) ->
	?MSG_FORMAT_CAMP_PVP_ENTER_CD;
packet_format(?MSG_ID_CAMP_PVP_CALL_MONSTER) ->
	?MSG_FORMAT_CAMP_PVP_CALL_MONSTER;
packet_format(?MSG_ID_CAMP_PVP_ECOURAGE_SUCCESS) ->
	?MSG_FORMAT_CAMP_PVP_ECOURAGE_SUCCESS;
packet_format(?MSG_ID_CAMP_PVP_ATT_CAR_SUCCESS) ->
	?MSG_FORMAT_CAMP_PVP_ATT_CAR_SUCCESS;
packet_format(?MSG_ID_CAMP_PVP_RESPONSE_SCORE) ->
	?MSG_FORMAT_CAMP_PVP_RESPONSE_SCORE;
packet_format(?MSG_ID_CAMP_PVP_BROAD_TEAM_INFO) ->
	?MSG_FORMAT_CAMP_PVP_BROAD_TEAM_INFO;
packet_format(?MSG_ID_CAMP_PVP_TEAM_OVER) ->
	?MSG_FORMAT_CAMP_PVP_TEAM_OVER;
packet_format(?MSG_ID_CAMP_PVP_CASH_ACTIVE_START) ->
	?MSG_FORMAT_CAMP_PVP_CASH_ACTIVE_START;
packet_format(?MSG_ID_CAMP_PVP_REFRESH_CASH) ->
	?MSG_FORMAT_CAMP_PVP_REFRESH_CASH;
packet_format(?MSG_ID_CAMP_PVP_OPEN_CASH_RESULT) ->
	?MSG_FORMAT_CAMP_PVP_OPEN_CASH_RESULT;
packet_format(?MSG_ID_CAMP_PVP_REMOVE_CASH_BOX) ->
	?MSG_FORMAT_CAMP_PVP_REMOVE_CASH_BOX;
packet_format(?MSG_ID_CAMP_PVP_BOX_LEFT) ->
	?MSG_FORMAT_CAMP_PVP_BOX_LEFT;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
