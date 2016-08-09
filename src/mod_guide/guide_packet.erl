%% Author: php
%% Created:
%% Description: TODO: Add description to guide_packet
-module(guide_packet).

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
packet_format(?MSG_ID_GUIDE_CSINFO) ->
	?MSG_FORMAT_GUIDE_CSINFO;
packet_format(?MSG_ID_GUIDE_SCINFO) ->
	?MSG_FORMAT_GUIDE_SCINFO;
packet_format(?MSG_ID_GUIDE_CSUPDATE) ->
	?MSG_FORMAT_GUIDE_CSUPDATE;
packet_format(?MSG_ID_GUIDE_CS_1ST) ->
	?MSG_FORMAT_GUIDE_CS_1ST;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
