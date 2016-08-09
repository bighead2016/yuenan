%% Author: yskj
%% Created: 2012-7-16
%% Description: TODO: Add description to home_handler
-module(chat_handler).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 聊天
handler(?MSG_ID_CHAT_CS_CHAT, Player, {Channel, Content, {_Len, GoodsList}}) ->
	Player2 = chat_mod:chat(Player, Channel, Content, GoodsList),
	{?ok, Player2};
%% 私聊发送
handler(?MSG_ID_CHAT_CS_PRIVATE, Player, {UserId, Content}) ->
	chat_mod:chat_private(Player, UserId, Content), 
	?ok;
%% 请求对方信息
handler(?MSG_ID_CHAT_CS_REQUEST_DATA, Player, {UserId, Type}) ->
	chat_mod:chat_user_data(Player,UserId, Type),
	?ok;
handler(_MsgId, _Player, _Datas) -> ?undefined.




%%
%% Local Functions
%%



