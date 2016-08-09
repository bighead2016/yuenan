%% Author: php
%% Created: 2012-08-13 16
%% Description: TODO: Add description to lottery_handler
-module(lottery_handler).

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
%% 打开淘宝界面
handler(?MSG_ID_LOTTERY_CSINTERFACE, Player, {}) ->
	lottery_mod:lottery_info(Player);

%% 抽奖
handler(?MSG_ID_LOTTERY_CSDRAW, Player, {LotteryId, LotteryMode}) ->
	lottery_mod:draw_lottery(Player, LotteryId, LotteryMode);

%% 累计奖励
handler(?MSG_ID_LOTTERY_CSACCUMULATOR, Player, {{CategoryLen, Category}}) ->
	lottery_mod:accumulate_award(Player, CategoryLen, Category);

%% 仓库道具直接取出到背包
handler(?MSG_ID_LOTTERY_CSFETCH, Player, {FetchMode, Index}) ->
	lottery_mod:fetch_goods(Player, FetchMode, Index);

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
