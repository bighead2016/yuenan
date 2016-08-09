%% Author: php
%% Created: 2012-08-07 16
%% Description: TODO: Add description to resource_handler
-module(resource_handler).

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
%% 招财神符信息
handler(?MSG_ID_RESOURCE_CSRUNEINFO, Player, {}) ->
	resource_mod:rune_info(Player);

%% 使用招财神符
handler(?MSG_ID_RESOURCE_CSUSERUNE, Player, {RuneCount}) ->
	resource_mod:use_rune(Player, RuneCount);

%% 提升品质
handler(?MSG_ID_RESOURCE_CSRUNEUPGRADE, Player, {ChestId}) ->
	resource_mod:upgrade_rune_chest(Player, ChestId);

%% 开启招财宝箱
handler(?MSG_ID_RESOURCE_CSOPENRUNECHEST, Player, {ChestId}) ->
	resource_mod:open_rune_chest(Player, ChestId);

%% 拜将信息
handler(?MSG_ID_RESOURCE_CSPRAYINFO, Player, {}) ->
	resource_mod:pray_info(Player);

%% 拜将
handler(?MSG_ID_RESOURCE_CSUSEPRAY, Player, {PrayType}) ->
	resource_mod:use_pray(Player, PrayType);

%% 抽奖
handler(?MSG_ID_RESOURCE_CS_1, Player, {Idx}) ->
	case Idx of
		1 -> %铜钱
			resource_mod:do_lottery(Player, Idx);
		2 -> %礼券
			resource_mod:do_gift_lottery(Player, Idx);
		3 -> %经验
			resource_mod:do_exp_lottery(Player,Idx);
		_ ->
			?ok
	end;

%% 请求奖池数据
handler(?MSG_ID_RESOURCE_CS_REQ_POOL, Player, {Type}) ->
    resource_mod:pool_info(Player,Type),
    ?ok;

%% 清除cd
handler(?MSG_ID_RESOURCE_CS_CLEAR_CD, Player, {}) ->
    resource_mod:clear_cd(Player);

%%请求大奖数据
handler(?MSG_ID_RESOURCE_CS_BIG_AWARD, Player, {}) ->
	resource_mod:get_big_award_info(Player);

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
