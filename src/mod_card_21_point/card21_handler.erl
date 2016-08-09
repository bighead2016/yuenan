%% Author: php
%% Created: 
%% Description: TODO: Add description to card21_handler
-module(card21_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求初始化一局
handler(?MSG_ID_CARD21_INIT_GAME, Player, {Chip}) ->
    card_21_point_api:init_game(Player#player.user_id, Chip),
	{?ok, Player};
%% 翻牌
handler(?MSG_ID_CARD21_HIT, Player, {}) ->
    card_21_point_api:hit(Player#player.user_id),
	{?ok, Player};
%% 停牌
handler(?MSG_ID_CARD21_STAND, Player, {}) ->
    card_21_point_api:stand(Player#player.user_id),
	{?ok, Player};
%% 请求当前筹码数
handler(?MSG_ID_CARD21_REQUEST_CHIP_TOTAL, Player, {}) ->
    card_21_point_api:request_chip(Player#player.user_id),
	{?ok, Player};
%% 请求买筹码
handler(?MSG_ID_CARD21_BUY_CHIP, Player, {Count}) ->
    card_21_point_api:buy_chip(Player#player.user_id, Count),
	{?ok, Player};
%% 请求卖筹码
handler(?MSG_ID_CARD21_SELL_CHIP, Player, {Count}) ->
    card_21_point_api:sell_chip(Player#player.user_id, Count),
	{?ok, Player};
%% 中途退出
handler(?MSG_ID_CARD21_QUIT, Player, {}) ->
    card_21_point_api:quit(Player#player.user_id),
    {?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
