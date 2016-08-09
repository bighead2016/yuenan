%% Author: php
%% Created: 
%% Description: TODO: Add description to party_handler
-module(party_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 进入军团宴会
handler(?MSG_ID_PARTY_CS_ENTER, Player, {}) ->
	party_mod:enter(Player);

%% 退出宴会
handler(?MSG_ID_PARTY_CS_QUIT, Player, {}) ->
	party_mod:quit(Player);

%% 打开宝箱
handler(?MSG_ID_PARTY_CS_OPEN_BOX, Player, {Id}) ->
	party_mod:open_box(Player,Id);

%% 击杀怪物
handler(?MSG_ID_PARTY_CS_BATTLE_START, Player, {Id}) ->
	case party_mod:battle_start(Player, Id) of
		{?ok, Player2}      -> {?ok,Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 请求获得体力
handler(?MSG_ID_PARTY_CS_GET_SP, Player, {}) ->
	party_mod:request_get_sp(Player);

%% 设置自动pk
handler(?MSG_ID_PARTY_CS_AUTO_PK, Player, {Flag}) ->
	party_mod:set_auto_pk(Player#player.user_id,Flag),
	?ok;
%% 发起pk邀请
handler(?MSG_ID_PARTY_CS_APPLY_PK, Player, {UserId}) ->
	party_mod:request_pk(Player,UserId),
	?ok;
%% 回复pk邀请
handler(?MSG_ID_PARTY_CS_REPLY_PK, Player, {Flag,MemId}) ->
	case party_mod:reply_pk(Player,MemId,Flag) of
		{?ok, Player2}      -> {?ok,Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 宴会替身
handler(?MSG_ID_PARTY_CS_DOLL, #player{user_id = UserId} = Player, {Type, State}) ->
	party_mod:set_doll(Player, Type, State),
	Packet = party_mod:pack_set_doll_data(UserId),
	misc_packet:send(UserId, Packet),
	?ok;
handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
