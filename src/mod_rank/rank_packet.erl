%% Author: php
%% Created:
%% Description: TODO: Add description to rank_packet
-module(rank_packet).

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
packet_format(?MSG_ID_RANK_CS_PLAYER) ->
	?MSG_FORMAT_RANK_CS_PLAYER;
packet_format(?MSG_ID_RANK_SC_PLAYER) ->
	?MSG_FORMAT_RANK_SC_PLAYER;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
