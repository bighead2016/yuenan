%% Author: php
%% Created:
%% Description: TODO: Add description to card21_packet
-module(card21_packet).

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
packet_format(?MSG_ID_CARD21_INIT_GAME) ->
	?MSG_FORMAT_CARD21_INIT_GAME;
packet_format(?MSG_ID_CARD21_SC_INIT_GAME) ->
	?MSG_FORMAT_CARD21_SC_INIT_GAME;
packet_format(?MSG_ID_CARD21_HIT) ->
	?MSG_FORMAT_CARD21_HIT;
packet_format(?MSG_ID_CARD21_STAND) ->
	?MSG_FORMAT_CARD21_STAND;
packet_format(?MSG_ID_CARD21_REQUEST_CHIP_TOTAL) ->
	?MSG_FORMAT_CARD21_REQUEST_CHIP_TOTAL;
packet_format(?MSG_ID_CARD21_SC_TOTAL_CHIP) ->
	?MSG_FORMAT_CARD21_SC_TOTAL_CHIP;
packet_format(?MSG_ID_CARD21_BUY_CHIP) ->
	?MSG_FORMAT_CARD21_BUY_CHIP;
packet_format(?MSG_ID_CARD21_SELL_CHIP) ->
	?MSG_FORMAT_CARD21_SELL_CHIP;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
