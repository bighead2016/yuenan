%% Author: php
%% Created: 2012-08-23 14
%% Description: TODO: Add description to ability_handler
-module(ability_handler).

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
%% 获取内功信息
handler(?MSG_ID_ABILITY_CS_INFO, Player, {}) ->
	ability_mod:ability_info(Player),
	?ok;
%% 升级内功
handler(?MSG_ID_ABILITY_CS_UPGRADE, Player, {AbilityId}) ->
	case ability_mod:upgrade(Player, AbilityId) of
		{?ok, Player2} ->  {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 清除CD
%% handler(?MSG_ID_ABILITY_CS_CLEAR_CD, Player, {}) ->	
%% 	{?ok, Player};
%% 请求八门信息
handler(?MSG_ID_ABILITY_CS_EXT_INFO, Player, {AbilityId, Step}) ->
	ability_mod:ability_ext_info(Player, AbilityId, Step),
	?ok;
%% 八门转动
handler(?MSG_ID_ABILITY_CS_EXT_REFRESH, Player, {AbilityId, Step}) ->
	case ability_mod:refresh_ability_ext(Player, AbilityId, Step) of
		{?ok, Player2} ->  {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 升阶请求
handler(?MSG_ID_ABILITY_MONEY_LEVEL_UP, Player, {AbilityId}) ->
	case ability_mod:money_upgrade(Player ,AbilityId) of
		{?ok,Player2} -> {?ok,Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
