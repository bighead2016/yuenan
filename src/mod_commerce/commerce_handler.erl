%% Author: php
%% Created: 
%% Description: TODO: Add description to commerce_handler
-module(commerce_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 进入商路场景
handler(?MSG_ID_COMMERCE_CSENTERSCENE, Player, {}) ->
	commerce_mod:enter(Player),
	?ok;

%% 离开商路场景
handler(?MSG_ID_COMMERCE_CSEXITSCENE, Player, {}) ->
	commerce_mod:exit(Player),
	?ok;

%% 拦截
handler(?MSG_ID_COMMERCE_CSROB, Player, {CaravanId}) ->
	?MSG_DEBUG("~nCaravanId=~p~n", [CaravanId]),
	commerce_mod:rob(Player, CaravanId);

%% 清除拦截冷却时间
handler(?MSG_ID_COMMERCE_CSCDROBTIME, Player, {}) ->
	commerce_mod:cd_rob_time(Player),
	?ok;

%% 购买拦截次数
handler(?MSG_ID_COMMERCE_CSROBTIMES, Player, {}) ->
%% 	commerce_mod:buy_rob_times(Player),
	?ok;

%% 邀请好友
handler(?MSG_ID_COMMERCE_CSINVITE, Player, {FriendId, FriendName}) ->
	?MSG_DEBUG("~nFriendId=~p~nFriendName=~p~n", [FriendId, FriendName]),
	commerce_mod:invite(Player, FriendId, FriendName),
	?ok;

%% 好友答复
handler(?MSG_ID_COMMERCE_CSREPLY, Player, {FriendId, Reply}) ->
	?MSG_DEBUG("~nFriendId=~p~nReply=~p~n", [FriendId, Reply]),
	commerce_mod:reply(Player, FriendId, Reply),
	?ok;

%% 请求商队品质和好友信息
handler(?MSG_ID_COMMERCE_CSQUALITYREQUEST, Player, {}) ->
	commerce_mod:friend_info(Player),
	commerce_mod:quality_info(Player),
	?ok;

%% 刷新商队品质
handler(?MSG_ID_COMMERCE_CSREFRESH, Player, {}) ->
	commerce_mod:refresh(Player),
	?ok;

%% 一键刷新
handler(?MSG_ID_COMMERCE_CSONEKEYREFRESH, Player, {}) ->
	commerce_mod:one_key_refresh(Player),
	?ok;

%% 开始运送
handler(?MSG_ID_COMMERCE_CSCARRY, Player, {}) ->
	commerce_mod:carry(Player);

%% 加速运送
handler(?MSG_ID_COMMERCE_CSSPEEDUP, Player, {}) ->
	{?ok, NewPlayer}	= commerce_mod:speed_up(Player),
	{?ok, NewPlayer};

%% 建造市场
handler(?MSG_ID_COMMERCE_CSBUILDMARKET, Player, {}) ->
	commerce_mod:build_market(Player);

%% 标记忽略邀请
handler(?MSG_ID_COMMERCE_CS_IGNORE_INVITE, Player, {Type}) ->
	commerce_mod:flag_invite(Player, Type),
	?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
