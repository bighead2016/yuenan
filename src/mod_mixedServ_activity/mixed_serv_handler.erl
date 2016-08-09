%% Author: php
%% Created: 
%% Description: TODO: Add description to mixed_serv_handler
-module(mixed_serv_handler).

%%
%% Include files
%%
-include_lib("../include/const.common.hrl").
-include_lib("../include/const.protocol.hrl").
-include_lib("../../include/const.define.hrl").
-include_lib("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%config:read_deep([]).
%% API Functions
%%
%% 请求合服排行榜
handler(?MSG_ID_MIXED_SERV_REQUEST_RANK, Player, {Type}) ->
	catch mixed_serv:get_rank(Player, Type),
	{?ok, Player};
%% 请求合服时间
handler(?MSG_ID_MIXED_SERV_CS_JOINSER_TIME, Player, {}) ->
	{Begin,_End} = mixed_serv_time:get_activity(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	Packet = misc_packet:pack(?MSG_ID_MIXED_SERV_SC_JOINSER_TIME, ?MSG_FORMAT_MIXED_SERV_SC_JOINSER_TIME, [Begin]),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};
%% 请求合服礼包状态
handler(?MSG_ID_MIXED_SERV_SEE_GIFT, Player, {}) ->
	mixed_serv_api:get_login_gift_info(Player),
	{?ok, Player};
%% 请求领取合服礼包
handler(?MSG_ID_MIXED_SERV_WANT_GIFT, Player, {}) ->
	mixed_serv_api:get_login_gift(Player);
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
