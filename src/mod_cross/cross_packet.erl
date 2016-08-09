%% Author: php
%% Created:
%% Description: TODO: Add description to cross_packet
-module(cross_packet).

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
packet_format(?MSG_ID_CROSS_CROSS_JUMP) ->
	?MSG_FORMAT_CROSS_CROSS_JUMP;
packet_format(?MSG_ID_CROSS_JUMP_SUCCESS) ->
	?MSG_FORMAT_CROSS_JUMP_SUCCESS;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
