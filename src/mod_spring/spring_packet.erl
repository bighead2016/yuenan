%% Author: php
%% Created:
%% Description: TODO: Add description to spring_packet
-module(spring_packet).

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
packet_format(?MSG_ID_SPRING_CSENTER) ->
	?MSG_FORMAT_SPRING_CSENTER;
packet_format(?MSG_ID_SPRING_SCENTER) ->
	?MSG_FORMAT_SPRING_SCENTER;
packet_format(?MSG_ID_SPRING_CSEXIT) ->
	?MSG_FORMAT_SPRING_CSEXIT;
packet_format(?MSG_ID_SPRING_SCEXIT) ->
	?MSG_FORMAT_SPRING_SCEXIT;
packet_format(?MSG_ID_SPRING_SCEXP) ->
	?MSG_FORMAT_SPRING_SCEXP;
packet_format(?MSG_ID_SPRING_SCPS) ->
	?MSG_FORMAT_SPRING_SCPS;
packet_format(?MSG_ID_SPRING_SCOFF) ->
	?MSG_FORMAT_SPRING_SCOFF;
packet_format(?MSG_ID_SPRING_CS_GET_SP) ->
	?MSG_FORMAT_SPRING_CS_GET_SP;
packet_format(?MSG_ID_SPRING_SC_SP_TIME) ->
	?MSG_FORMAT_SPRING_SC_SP_TIME;
packet_format(?MSG_ID_SPRING_SC_REQUEST) ->
	?MSG_FORMAT_SPRING_SC_REQUEST;
packet_format(?MSG_ID_SPRING_CSDOUBLEREQUEST) ->
	?MSG_FORMAT_SPRING_CSDOUBLEREQUEST;
packet_format(?MSG_ID_SPRING_SCDOUBLERECEIVE) ->
	?MSG_FORMAT_SPRING_SCDOUBLERECEIVE;
packet_format(?MSG_ID_SPRING_CSDOUBLEREPLY) ->
	?MSG_FORMAT_SPRING_CSDOUBLEREPLY;
packet_format(?MSG_ID_SPRING_SCDOUBLE) ->
	?MSG_FORMAT_SPRING_SCDOUBLE;
packet_format(?MSG_ID_SPRING_CSCANCEL) ->
	?MSG_FORMAT_SPRING_CSCANCEL;
packet_format(?MSG_ID_SPRING_SCINFORMCANCEL) ->
	?MSG_FORMAT_SPRING_SCINFORMCANCEL;
packet_format(?MSG_ID_SPRING_CS_NOTICE_REQ) ->
	?MSG_FORMAT_SPRING_CS_NOTICE_REQ;
packet_format(?MSG_ID_SPRING_SC_NOTICE) ->
	?MSG_FORMAT_SPRING_SC_NOTICE;
packet_format(?MSG_ID_SPRING_SC_CANCEL_NOTICE) ->
	?MSG_FORMAT_SPRING_SC_CANCEL_NOTICE;
packet_format(?MSG_ID_SPRING_SC_END_QUIT) ->
	?MSG_FORMAT_SPRING_SC_END_QUIT;
packet_format(?MSG_ID_SPRING_CS_END_QUIT) ->
	?MSG_FORMAT_SPRING_CS_END_QUIT;
packet_format(?MSG_ID_SPRING_CS_AUTO) ->
	?MSG_FORMAT_SPRING_CS_AUTO;
packet_format(?MSG_ID_SPRING_SC_AUTO) ->
	?MSG_FORMAT_SPRING_SC_AUTO;
packet_format(?MSG_ID_SPRING_SC_AUTO_REWARD) ->
	?MSG_FORMAT_SPRING_SC_AUTO_REWARD;
packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
