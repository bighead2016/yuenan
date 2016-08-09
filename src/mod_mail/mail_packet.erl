%% Author: php
%% Created:
%% Description: TODO: Add description to mail_packet
-module(mail_packet).

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
packet_format(?MSG_ID_MAIL_CS_LIST_REQUEST) ->
	?MSG_FORMAT_MAIL_CS_LIST_REQUEST;
packet_format(?MSG_ID_MAIL_SC_LIST_INFO) ->
	?MSG_FORMAT_MAIL_SC_LIST_INFO;
packet_format(?MSG_ID_MAIL_CS_READ) ->
	?MSG_FORMAT_MAIL_CS_READ;
packet_format(?MSG_ID_MAIL_CS_DELETE) ->
	?MSG_FORMAT_MAIL_CS_DELETE;
packet_format(?MSG_ID_MAIL_SC_DELETE) ->
	?MSG_FORMAT_MAIL_SC_DELETE;
packet_format(?MSG_ID_MAIL_CS_SAVE) ->
	?MSG_FORMAT_MAIL_CS_SAVE;
packet_format(?MSG_ID_MAIL_SC_SAVE) ->
	?MSG_FORMAT_MAIL_SC_SAVE;
packet_format(?MSG_ID_MAIL_CS_GET_ATTACH) ->
	?MSG_FORMAT_MAIL_CS_GET_ATTACH;
packet_format(?MSG_ID_MAIL_SC_GET_ATTACH) ->
	?MSG_FORMAT_MAIL_SC_GET_ATTACH;
packet_format(?MSG_ID_MAIL_CS_GET_ALL) ->
	?MSG_FORMAT_MAIL_CS_GET_ALL;
packet_format(?MSG_ID_MAIL_CS_SEND) ->
	?MSG_FORMAT_MAIL_CS_SEND;
packet_format(?MSG_ID_MAIL_SC_SEND_RESULT) ->
	?MSG_FORMAT_MAIL_SC_SEND_RESULT;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
