%% Author: php
%% Created: 
%% Description: TODO: Add description to bless_handler
-module(bless_handler).

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
%% 给好友发送祝福
handler(?MSG_ID_BLESS_CS_BLESS, Player, {BlessId,MemId}) ->
	case bless_mod:bless(Player, BlessId, MemId) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_ -> ?ok
	end;

%% 领取经验
handler(?MSG_ID_BLESS_CS_GET_EXP, Player, {}) ->
	case bless_mod:get_bottle_exp(Player) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		{?ok, Player2} ->  {?ok, Player2}
	end;

%% 请求祝福瓶信息
handler(?MSG_ID_BLESS_CS_BATTLE_DATA, Player, {}) ->
	{?ok,Exp,Count} = bless_mod:bottle_data(Player#player.user_id),
	Packet14816		= bless_api:msg_sc_battle_data(Exp,Count),
	misc_packet:send(Player#player.net_pid, Packet14816),
	?ok;
%% 一键祝福
handler(?MSG_ID_BLESS_CS_ONE_KEY, Player, {}) ->
	case bless_mod:onkey_bless(Player) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_ -> ?ok
	end;
%% 读取祝福
handler(?MSG_ID_BLESS_CS_READ, Player, {}) ->
	case bless_mod:read_bless(Player) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_ -> ?ok
	end;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
