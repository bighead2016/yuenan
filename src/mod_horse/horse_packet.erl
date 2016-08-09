%% Author: php
%% Created:
%% Description: TODO: Add description to horse_packet
-module(horse_packet).

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
packet_format(?MSG_ID_HORSE_CS_DEVELOP) ->
	?MSG_FORMAT_HORSE_CS_DEVELOP;
packet_format(?MSG_ID_HORSE_SC_DEVELOP) ->
	?MSG_FORMAT_HORSE_SC_DEVELOP;
packet_format(?MSG_ID_HORSE_SC_DEL_DEVELOP) ->
	?MSG_FORMAT_HORSE_SC_DEL_DEVELOP;
packet_format(?MSG_ID_HORSE_CS_TAKE_OUT) ->
	?MSG_FORMAT_HORSE_CS_TAKE_OUT;
packet_format(?MSG_ID_HORSE_CS_FEEDHORSE) ->
	?MSG_FORMAT_HORSE_CS_FEEDHORSE;
packet_format(?MSG_ID_HORSE_CS_NORMALDEVE) ->
	?MSG_FORMAT_HORSE_CS_NORMALDEVE;
packet_format(?MSG_ID_HORSE_CS_HORSESKILL) ->
	?MSG_FORMAT_HORSE_CS_HORSESKILL;
packet_format(?MSG_ID_HORSE_SC_HORSESKILL) ->
	?MSG_FORMAT_HORSE_SC_HORSESKILL;
packet_format(?MSG_ID_HORSE_SC_SKILL_HAVE) ->
	?MSG_FORMAT_HORSE_SC_SKILL_HAVE;
packet_format(?MSG_ID_HORSE_CS_USER_EXP_CARD) ->
	?MSG_FORMAT_HORSE_CS_USER_EXP_CARD;
packet_format(?MSG_ID_HORSE_CS_CLEAR_CD) ->
	?MSG_FORMAT_HORSE_CS_CLEAR_CD;
packet_format(?MSG_ID_HORSE_CS_ONE_KEY) ->
	?MSG_FORMAT_HORSE_CS_ONE_KEY;
packet_format(?MSG_ID_HORSE_SC_CRIT) ->
	?MSG_FORMAT_HORSE_SC_CRIT;
packet_format(?MSG_ID_HORSE_STREN_COUNT) ->
	?MSG_FORMAT_HORSE_STREN_COUNT;
packet_format(?MSG_ID_HORSE_CS_REFRESH) ->
	?MSG_FORMAT_HORSE_CS_REFRESH;
packet_format(?MSG_ID_HORSE_CS_REPLACESKIN) ->
	?MSG_FORMAT_HORSE_CS_REPLACESKIN;
packet_format(?MSG_ID_HORSE_SC_USESKIN) ->
	?MSG_FORMAT_HORSE_SC_USESKIN;
packet_format(?MSG_ID_HORSE_CS_LVUPSKILL) ->
	?MSG_FORMAT_HORSE_CS_LVUPSKILL;
packet_format(?MSG_ID_HORSE_CS_TIME_OVER) ->
	?MSG_FORMAT_HORSE_CS_TIME_OVER;
packet_format(?MSG_ID_HORSE_SC_DEL_SKIN) ->
	?MSG_FORMAT_HORSE_SC_DEL_SKIN;
packet_format(?MSG_ID_HORSE_CS_HORSE_ATTR_NOT_SAVE) ->
	?MSG_FORMAT_HORSE_CS_HORSE_ATTR_NOT_SAVE;
packet_format(?MSG_ID_HORSE_ATTR_NOT_SAVE) ->
	?MSG_FORMAT_HORSE_ATTR_NOT_SAVE;
packet_format(?MSG_ID_HORSE_CS_SAVE_ATTR_HORSE) ->
	?MSG_FORMAT_HORSE_CS_SAVE_ATTR_HORSE;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
