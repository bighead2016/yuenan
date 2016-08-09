%% Author: php
%% Created: 2012-08-02 16
%% Description: TODO: Add description to sys_packet
-module(sys_packet).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([packet_format/1]).
%%
%% API Functions
%%
%% *必须实现方法
%% 消息号与消息格式一一对应
packet_format(?MSG_ID_SYS_GROUP_ATTR) ->
	?MSG_FORMAT_SYS_GROUP_ATTR;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
