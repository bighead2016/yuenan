%% Author: php
%% Created: 
%% Description: TODO: Add description to gun_cash_handler
-module(gun_cash_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 领取滚服礼券
handler(?MSG_ID_GUN_CASH_GET_GUN_CASH, Player, {}) ->
    gun_award_api:get_gun_award(Player),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
