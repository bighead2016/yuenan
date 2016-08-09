%% Author: php
%% Created: 
%% Description: TODO: Add description to hundred_serv_handler
-module(hundred_serv_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include_lib("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求充值排行榜
handler(?MSG_ID_HUNDRED_SERV_REQUEST_RANK, Player, {}) ->
	hundred_serv_api:get_recharge_rank(Player#player.user_id),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
