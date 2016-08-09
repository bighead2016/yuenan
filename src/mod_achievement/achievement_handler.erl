%% Author: php
%% Created: 2012-07-25 10
%% Description: TODO: Add description to achievement_handler
-module(achievement_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 获取成就数据
handler(?MSG_ID_ACHIEVEMENT_CSARRIVALDATA, Player, {}) ->
	achievement_mod:achievement_info(Player),
	?ok;

%% 兑换成就礼品
handler(?MSG_ID_ACHIEVEMENT_CSARRIVALGIFT, Player, {ArrivalGiftId}) ->
	achievement_mod:get_achievement_gift(Player, ArrivalGiftId);

%% 更改称号
handler(?MSG_ID_ACHIEVEMENT_CSTITLECHANGE, Player, {TitleId}) ->
	achievement_mod:change_title(Player, TitleId);

%% 已有称号列表
handler(?MSG_ID_ACHIEVEMENT_CS_TITLE_LIST, Player, {}) ->
	achievement_mod:title_list(Player);

%% 称号失效
handler(?MSG_ID_ACHIEVEMENT_CS_INVALIDATE, Player, {_TitleId}) ->
	achievement_api:refresh_title(Player);

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
