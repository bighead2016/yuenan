%% Author: php
%% Created:
%% Description: TODO: Add description to goods_packet
-module(goods_packet).

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
packet_format(?MSG_ID_GOODS_CS_CTN_INFO) ->
	?MSG_FORMAT_GOODS_CS_CTN_INFO;
packet_format(?MSG_ID_GOODS_SC_CTN_INFO) ->
	?MSG_FORMAT_GOODS_SC_CTN_INFO;
packet_format(?MSG_ID_GOODS_SC_GOODS_INFO) ->
	?MSG_FORMAT_GOODS_SC_GOODS_INFO;
packet_format(?MSG_ID_GOODS_SC_GOODS_EQUIP_INFO) ->
	?MSG_FORMAT_GOODS_SC_GOODS_EQUIP_INFO;
packet_format(?MSG_ID_GOODS_SC_GOODS_REMOVE) ->
	?MSG_FORMAT_GOODS_SC_GOODS_REMOVE;
packet_format(?MSG_ID_GOODS_CS_REFRESH) ->
	?MSG_FORMAT_GOODS_CS_REFRESH;
packet_format(?MSG_ID_GOODS_CS_REMOVE) ->
	?MSG_FORMAT_GOODS_CS_REMOVE;
packet_format(?MSG_ID_GOODS_CS_DRAG) ->
	?MSG_FORMAT_GOODS_CS_DRAG;
packet_format(?MSG_ID_GOODS_CS_SPLIT) ->
	?MSG_FORMAT_GOODS_CS_SPLIT;
packet_format(?MSG_ID_GOODS_CS_ENLARGE_CTN) ->
	?MSG_FORMAT_GOODS_CS_ENLARGE_CTN;
packet_format(?MSG_ID_GOODS_SC_ENLARGE_CTN) ->
	?MSG_FORMAT_GOODS_SC_ENLARGE_CTN;
packet_format(?MSG_ID_GOODS_CS_USE) ->
	?MSG_FORMAT_GOODS_CS_USE;
packet_format(?MSG_ID_GOODS_CS_EQUIP_ON) ->
	?MSG_FORMAT_GOODS_CS_EQUIP_ON;
packet_format(?MSG_ID_GOODS_CS_EQUIP_OFF) ->
	?MSG_FORMAT_GOODS_CS_EQUIP_OFF;
packet_format(?MSG_ID_GOODS_SC_OPEN_REMOTE) ->
	?MSG_FORMAT_GOODS_SC_OPEN_REMOTE;
packet_format(?MSG_ID_GOODS_CS_OVER_TIME) ->
	?MSG_FORMAT_GOODS_CS_OVER_TIME;
packet_format(?MSG_ID_GOODS_CS_HIDE_EQUIP) ->
	?MSG_FORMAT_GOODS_CS_HIDE_EQUIP;
packet_format(?MSG_ID_TENCENT_DEPOSIT) ->
	?MSG_FORMAT_TENCENT_DEPOSIT;
packet_format(?MSG_ID_TENCENT_DEPOSIT_RETURN) ->
	?MSG_FORMAT_TENCENT_DEPOSIT_RETURN;
packet_format(?MSG_ID_TENCENT_INFO_REQUEST) ->
	?MSG_FORMAT_TENCENT_INFO_REQUEST;
packet_format(?MSG_ID_TENCENT_PACK_GET) ->
	?MSG_FORMAT_TENCENT_PACK_GET;
packet_format(?MSG_ID_TENCENT_ERR_RETURN) ->
	?MSG_FORMAT_TENCENT_ERR_RETURN;
packet_format(?MSG_ID_PLATFROM_INFO_RETURN) ->
	?MSG_FORMAT_PLATFROM_INFO_RETURN;

packet_format(?MSG_ID_TENCENT_INVITE) ->
	?MSG_FORMAT_TENCENT_INVITE;
packet_format(?MSG_ID_TENCENT_INVITE_INFO) ->
	?MSG_FORMAT_TENCENT_INVITE_INFO;
packet_format(?MSG_ID_TENCENT_INVITE_AWARD) ->
	?MSG_FORMAT_TENCENT_INVITE_AWARD;

packet_format(?MSG_ID_ROBOT_LVUP_REQUEST) ->
	?MSG_FORMAT_ROBOT_LVUP_REQUEST;

packet_format(MsgId) ->
	?MSG_ERROR("~p~n", [MsgId]).
%%
%% Local Functions
%%
