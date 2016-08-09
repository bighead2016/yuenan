%% Author: php
%% Created:
%% Description: TODO: Add description to hundred_serv_packet
-module(hundred_serv_packet).

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
packet_format(?MSG_ID_HUNDRED_SERV_REQUEST_RANK) ->
	?MSG_FORMAT_HUNDRED_SERV_REQUEST_RANK;
packet_format(?MSG_ID_HUNDRED_SERV_REPLY_RANK) ->
	?MSG_FORMAT_HUNDRED_SERV_REPLY_RANK;
packet_format(?MSG_ID_HUNDRED_SERV_INFORM_OPEN) ->
	?MSG_FORMAT_HUNDRED_SERV_INFORM_OPEN;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
