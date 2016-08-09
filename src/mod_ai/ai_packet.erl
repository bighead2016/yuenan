%% Author: php
%% Created:
%% Description: TODO: Add description to ai_packet
-module(ai_packet).

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
packet_format(?MSG_ID_AI_CS_END) ->
	?MSG_FORMAT_AI_CS_END;
packet_format(?MSG_ID_AI_SC_START) ->
	?MSG_FORMAT_AI_SC_START;
packet_format(?MSG_ID_AI_SC_UNIT_JOIN) ->
	?MSG_FORMAT_AI_SC_UNIT_JOIN;
packet_format(?MSG_ID_AI_SC_UNIT_QUIT) ->
	?MSG_FORMAT_AI_SC_UNIT_QUIT;
packet_format(?MSG_ID_AI_SC_BATTLE_ROUND) ->
	?MSG_FORMAT_AI_SC_BATTLE_ROUND;
packet_format(?MSG_ID_AI_SC_HP_ANGER_CHANGE) ->
	?MSG_FORMAT_AI_SC_HP_ANGER_CHANGE;
packet_format(?MSG_ID_AI_SC_ATTR_CHANGE) ->
	?MSG_FORMAT_AI_SC_ATTR_CHANGE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
