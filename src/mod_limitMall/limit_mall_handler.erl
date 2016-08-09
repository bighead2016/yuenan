%% Author: php
%% Created: 
%% Description: TODO: Add description to limit_mall_handler
-module(limit_mall_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求商城界面
handler(?MSG_ID_LIMIT_MALL_REQUEST_MALL, Player, {}) ->
	act_limitMall_mod:get_mall_list(Player#player.user_id),
	{?ok, Player};
%% 购买
handler(?MSG_ID_LIMIT_MALL_BUY, Player, {Goodid,Num}) ->
	act_limitMall_mod:buy(Player, Goodid, Num);
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
