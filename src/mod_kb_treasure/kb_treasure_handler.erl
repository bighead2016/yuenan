%% Author: php
%% Created: 
%% Description: TODO: Add description to kb_treasure_handler
-module(kb_treasure_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 转盘抽奖
handler(?MSG_ID_KB_TREASURE_CS_TURN, Player, {Level,Type}) ->
	{?ok, Player2} = kb_treasure_mod:turn(Player, Level, Type),
	{?ok, Player2};
%% 发协议
handler(?MSG_ID_KB_TREASURE_CS_SEND, Player, {}) ->
	Packet = Player#player.offline_packet,
    misc_packet:send(Player#player.user_id, Packet),
    BP = Player#player.broadcast_packet,
    misc_app:broadcast_world_2(BP),
    {?ok, Player#player{offline_packet = <<>>, broadcast_packet = <<>>}};
%% 获取组别
handler(?MSG_ID_KB_TREASURE_CS_GET_GROUP, Player, {Level}) ->
	ConfigId = kb_treasure_mod:get_config_id(),
	Packet = kb_treasure_api:msg_sc_group_result(Level, ConfigId),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
