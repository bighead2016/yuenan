%% Author: php
%% Created:
%% Description: TODO: Add description to weapon_packet
-module(weapon_packet).

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
packet_format(?MSG_ID_WEAPON_CS_WEAPON_ON) ->
	?MSG_FORMAT_WEAPON_CS_WEAPON_ON;
packet_format(?MSG_ID_WEAPON_CS_WEAPON_OFF) ->
	?MSG_FORMAT_WEAPON_CS_WEAPON_OFF;
packet_format(?MSG_ID_WEAPON_CS_REFRESH) ->
	?MSG_FORMAT_WEAPON_CS_REFRESH;
packet_format(?MSG_ID_WEAPON_CS_FREE_REFRESH) ->
	?MSG_FORMAT_WEAPON_CS_FREE_REFRESH;
packet_format(?MSG_ID_WEAPON_SC_FREE_REFRESH) ->
	?MSG_FORMAT_WEAPON_SC_FREE_REFRESH;
packet_format(?MSG_ID_WEAPON_CS_QUENCH) ->
	?MSG_FORMAT_WEAPON_CS_QUENCH;
packet_format(?MSG_ID_WEAPON_CS_CHESS_INFO) ->
	?MSG_FORMAT_WEAPON_CS_CHESS_INFO;
packet_format(?MSG_ID_WEAPON_SC_CHESS_INFO) ->
	?MSG_FORMAT_WEAPON_SC_CHESS_INFO;
packet_format(?MSG_ID_WEAPON_CS_CHESS_BUY_DICE) ->
	?MSG_FORMAT_WEAPON_CS_CHESS_BUY_DICE;
packet_format(?MSG_ID_WEAPON_CS_CHESS_DICE) ->
	?MSG_FORMAT_WEAPON_CS_CHESS_DICE;
packet_format(?MSG_ID_WEAPON_SC_CHESS_DICE) ->
	?MSG_FORMAT_WEAPON_SC_CHESS_DICE;
packet_format(?MSG_ID_WEAPON_CS_CHESS_CONTROL_DICE) ->
	?MSG_FORMAT_WEAPON_CS_CHESS_CONTROL_DICE;
packet_format(?MSG_ID_WEAPON_CS_CHESS_FIRST_POS) ->
	?MSG_FORMAT_WEAPON_CS_CHESS_FIRST_POS;
packet_format(?MSG_ID_WEAPON_CLEAR_CHESS_CD) ->
	?MSG_FORMAT_WEAPON_CLEAR_CHESS_CD;
packet_format(?MSG_ID_WEAPON_SC_CLEAR_CHESS_CD) ->
	?MSG_FORMAT_WEAPON_SC_CLEAR_CHESS_CD;
packet_format(?MSG_ID_WEAPON_SC_CHESS_REWARD) ->
	?MSG_FORMAT_WEAPON_SC_CHESS_REWARD;
packet_format(?MSG_ID_WEAPON_CS_BUY_PUT_TIMES) ->
	?MSG_FORMAT_WEAPON_CS_BUY_PUT_TIMES;
packet_format(?MSG_ID_WEAPON_SC_BUY_PUT_TIMES) ->
	?MSG_FORMAT_WEAPON_SC_BUY_PUT_TIMES;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
