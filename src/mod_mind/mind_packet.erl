%% Author: php
%% Created:
%% Description: TODO: Add description to mind_packet
-module(mind_packet).

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
packet_format(?MSG_ID_MIND_LIST) ->
	?MSG_FORMAT_MIND_LIST;
packet_format(?MSG_ID_MIND_LIST_RETURN) ->
	?MSG_FORMAT_MIND_LIST_RETURN;
packet_format(?MSG_ID_MIND_READ_LIST) ->
	?MSG_FORMAT_MIND_READ_LIST;
packet_format(?MSG_ID_MIND_READ_LIST_RETURN) ->
	?MSG_FORMAT_MIND_READ_LIST_RETURN;
packet_format(?MSG_ID_MIND_UPGRADE) ->
	?MSG_FORMAT_MIND_UPGRADE;
packet_format(?MSG_ID_MIND_UPGRADE_RETURN) ->
	?MSG_FORMAT_MIND_UPGRADE_RETURN;
packet_format(?MSG_ID_MIND_ABSORB) ->
	?MSG_FORMAT_MIND_ABSORB;
packet_format(?MSG_ID_MIND_ABSORB_RETURN) ->
	?MSG_FORMAT_MIND_ABSORB_RETURN;
packet_format(?MSG_ID_MIND_ONE_KEY_ABSORB) ->
	?MSG_FORMAT_MIND_ONE_KEY_ABSORB;
packet_format(?MSG_ID_MIND_ONE_KEY_ABSORB_RETURN) ->
	?MSG_FORMAT_MIND_ONE_KEY_ABSORB_RETURN;
packet_format(?MSG_ID_MIND_READ_SECRET) ->
	?MSG_FORMAT_MIND_READ_SECRET;
packet_format(?MSG_ID_MIND_READ_SECRET_RETURN) ->
	?MSG_FORMAT_MIND_READ_SECRET_RETURN;
packet_format(?MSG_ID_MIND_ONE_KEY_READ) ->
	?MSG_FORMAT_MIND_ONE_KEY_READ;
packet_format(?MSG_ID_MIND_ONE_KEY_READ_RETURN) ->
	?MSG_FORMAT_MIND_ONE_KEY_READ_RETURN;
packet_format(?MSG_ID_MIND_EXTERN_BAG) ->
	?MSG_FORMAT_MIND_EXTERN_BAG;
packet_format(?MSG_ID_MIND_EXTERN_BAG_RETURN) ->
	?MSG_FORMAT_MIND_EXTERN_BAG_RETURN;
packet_format(?MSG_ID_MIND_TEMP_BAG_LIST) ->
	?MSG_FORMAT_MIND_TEMP_BAG_LIST;
packet_format(?MSG_ID_MIND_TEMP_BAG_LIST_RETURN) ->
	?MSG_FORMAT_MIND_TEMP_BAG_LIST_RETURN;
packet_format(?MSG_ID_MIND_PICK) ->
	?MSG_FORMAT_MIND_PICK;
packet_format(?MSG_ID_MIND_PICK_RESULT) ->
	?MSG_FORMAT_MIND_PICK_RESULT;
packet_format(?MSG_ID_MIND_ONE_KEY_PICK) ->
	?MSG_FORMAT_MIND_ONE_KEY_PICK;
packet_format(?MSG_ID_MIND_ONE_KEY_PICK_RESULT) ->
	?MSG_FORMAT_MIND_ONE_KEY_PICK_RESULT;
packet_format(?MSG_ID_MIND_EXCHANGE) ->
	?MSG_FORMAT_MIND_EXCHANGE;
packet_format(?MSG_ID_MIND_EXCHANGE_RESULT) ->
	?MSG_FORMAT_MIND_EXCHANGE_RESULT;
packet_format(?MSG_ID_MIND_GET_MIND_BY_POS) ->
	?MSG_FORMAT_MIND_GET_MIND_BY_POS;
packet_format(?MSG_ID_MIND_GET_MIND_BY_POS_RETURN) ->
	?MSG_FORMAT_MIND_GET_MIND_BY_POS_RETURN;
packet_format(?MSG_ID_MIND_CHANGE_BAG_STATUS) ->
	?MSG_FORMAT_MIND_CHANGE_BAG_STATUS;
packet_format(?MSG_ID_MIND_GET_SPIRIT) ->
	?MSG_FORMAT_MIND_GET_SPIRIT;
packet_format(?MSG_ID_MIND_UPDATE_SPIRIT) ->
	?MSG_FORMAT_MIND_UPDATE_SPIRIT;
packet_format(?MSG_ID_MIND_UPDATE_FREE_TIMES) ->
	?MSG_FORMAT_MIND_UPDATE_FREE_TIMES;
packet_format(?MSG_ID_MIND_CS_GET_SCORE) ->
	?MSG_FORMAT_MIND_CS_GET_SCORE;
packet_format(?MSG_ID_MIND_SC_UPDATE_SCORE) ->
	?MSG_FORMAT_MIND_SC_UPDATE_SCORE;
packet_format(?MSG_ID_MIND_CS_EXCHANGE_SCORE) ->
	?MSG_FORMAT_MIND_CS_EXCHANGE_SCORE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
