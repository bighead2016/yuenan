%% Author: php
%% Created: 
%% Description: TODO: Add description to gamble_handler
-module(gamble_handler).

%%
%% Include files
%%
-include_lib("../include/const.common.hrl").
-include_lib("../include/const.protocol.hrl").
-include_lib("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3
		, test_handler/3
		, test_handler2/2]).
%%
%% API Functions
%%
%% 请求房间信息
handler(?MSG_ID_GAMBLE_REQUEST_ROOMS, Player, {}) ->
	gamble_api:reply_rooms_info(Player),
	{?ok, Player};
%% 请求创建房间
handler(?MSG_ID_GAMBLE_BOOK_NEW_ROOM, Player, {Chip}) ->
	gamble_api:book_new_room(Player#player.user_id, gamble_api:getLocalSid(), Chip, ?false),
	{?ok, Player};
%% 请求加入房间
handler(?MSG_ID_GAMBLE_JOIN_ROOM, Player, {RoomId,RoomSid}) ->
	Info = Player#player.info,
	gamble_api:join_new_room(Player#player.user_id, RoomId, RoomSid, Info#info.user_name, Info#info.pro, Info#info.sex),
	{?ok, Player};
%% 请求离开房间
handler(?MSG_ID_GAMBLE_REQUEST_LEAVE, Player, {RoomId,RoomSid}) ->
	gamble_api:request_leave(Player#player.user_id, RoomId, RoomSid),
	{?ok, Player};
%% 请求准备|取消
handler(?MSG_ID_GAMBLE_REQUEST_READY, Player, {Ready, RoomId, RoomSid}) ->
	gamble_api:request_ready(Player#player.user_id, RoomId, RoomSid, Ready),
	{?ok, Player};
%% 请求出牌1
handler(?MSG_ID_GAMBLE_PLAY_CARD, Player, {RoomId, RoomSid}) ->
	gamble_api:play_card1(Player#player.user_id, RoomId, RoomSid),
	{?ok, Player};
%% 请求出牌2
handler(?MSG_ID_GAMBLE_PLAY_CARD2, Player, {Card, RoomId, RoomSid}) ->
	gamble_api:play_card2(Player#player.user_id, RoomId, RoomSid, Card),
	{?ok, Player};
%% 玩家放弃
handler(?MSG_ID_GAMBLE_PLAYER_GIVE_UP, Player, {RoomId, RoomSid}) ->
	gamble_api:player_give_up(Player#player.user_id, RoomId, RoomSid),
	{?ok, Player};
%% 查看自己筹码
handler(?MSG_ID_GAMBLE_REQUEST_CHIP, Player, {}) ->
	gamble_api:request_chip(Player),
	{?ok, Player};
%% 兑换筹码
handler(?MSG_ID_GAMBLE_EXCHANGE_CHIP, Player, {Chips}) ->
	gamble_api:exchange_chip(Player, Chips),
	{?ok, Player};
%% 再来一局
handler(?MSG_ID_GAMBLE_PLAY_AGAIN, Player, {Again, RoomId, RoomSid}) ->
	gamble_api:play_again(Player#player.user_id, Again, RoomId, RoomSid),
	{?ok, Player};
%% 元宝兑换筹码
handler(?MSG_ID_GAMBLE_EXCHANGE_GOLD, Player, {Num}) ->
	gamble_api:exchange4chip(Player#player.user_id, Num),
	{?ok, Player};
%% 是否需要返回游戏
handler(?MSG_ID_GAMBLE_NEED_COMEBACK, Player, {Yes}) ->
	gamble_api:player_come_back(Player#player.user_id, Yes),
	{?ok, Player};
%% 跨服匹配
handler(?MSG_ID_GAMBLE_CROSS_SERV, Player, {C10, C20, C50, C100}) ->
	gamble_api:try_to_match_cross(Player#player.user_id, {form_chip(C100, 100), form_chip(C50, 50), form_chip(C20, 20), form_chip(C10, 10)}),
	{?ok, Player};
%% 邀请
handler(?MSG_ID_GAMBLE_INVITE, Player, {RoomId, RoomSid}) ->
	Info = Player#player.info, 
	gamble_api:invite(Player#player.user_id, Info#info.user_name, RoomId, RoomSid),
	{?ok, Player};
%% 打开界面
handler(?MSG_ID_GAMBLE_OPEN_WINDOW, Player, {}) ->
	_ = gen_server:cast(gamble_serv, {add_looker, Player#player.user_id}),
	{?ok, Player};
%% 关闭界面
handler(?MSG_ID_GAMBLE_CLOSE_WINDOW, Player, {}) ->
	_ = gen_server:cast(gamble_serv, {sub_looker, Player#player.user_id}),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
form_chip(Yes, Chip) ->
	case Yes of
		?true ->
			Chip;
		_ ->
			0
	end.
%% ========================================================================
%% @doc test
%% ========================================================================
test_handler(UserId, MsgId, Datas) ->
	player_api:process_send(UserId, ?MODULE, test_handler2, {MsgId, Datas}).
test_handler2(Player, {MsgId, Datas}) ->
	case catch handler(MsgId, Player, Datas) of
		{?ok,_} -> 
			?ok;
		A ->
			?MSG_DEBUG("reply_rooms_info:~n~p~nstack:~p~n", [A, erlang:get_stacktrace()])
	end,
	{?ok, Player}.