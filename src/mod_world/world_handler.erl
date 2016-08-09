%% Author: php
%% Created: 
%% Description: TODO: Add description to world_handler
-module(world_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求进入乱天下
handler(?MSG_ID_WORLD_CS_ENTER, Player, {}) ->
	world_api:enter(Player);
%% 请求退出乱天下
handler(?MSG_ID_WORLD_CS_EXIT, Player, {}) ->
	world_api:quit(Player);
%% 请求自动复活
handler(?MSG_ID_WORLD_CS_AUTO_REVIVE, Player, {}) ->
	world_api:auto_revive(Player);
%% 请求开始战斗
handler(?MSG_ID_WORLD_CS_BATTLE_START, Player, {Step,Id}) ->
	case world_api:battle_start(Player, Step, Id) of
		{?ok, Player2}       -> {?ok, Player2};
		{?error, _ErrorCode} -> ?error
	end;
%% 请求领取犒赏三军BUFF
handler(?MSG_ID_WORLD_CS_GET_BUFF, _Player, {}) ->
%% 	world_api:get_buff(Player),
	?ok;
%% 发起邀请
handler(?MSG_ID_WORLD_CS_INVITE, Player, {UserId}) ->
	case world_api:invite(Player, UserId) of
		?ok                 -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 回复邀请
handler(?MSG_ID_WORLD_CS_REPLY, Player, {GuildId,InviterUid,GuildPos,Decide}) ->
	case world_api:reply(Player, GuildId, GuildPos, InviterUid, Decide) of
		{?ok, Player2}      -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 乱天下替身
handler(?MSG_ID_WORLD_CS_DOLL, Player, {Type,State}) ->
	robot_world_api:set_world_doll(Player, Type, State),
	{?ok, Player};

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
