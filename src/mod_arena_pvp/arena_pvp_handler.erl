%% Author: Administrator
%% Created: 2012-12-20
%% Description: TODO: Add description to arena_pvp_handle
-module(arena_pvp_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 进入玩法
handler(?MSG_ID_ARENA_PVP_ENTER, Player, {}) ->
	arena_pvp_mod:enter(Player);
%% 请求战群雄信息
handler(?MSG_ID_ARENA_PVP_CS_ENTER_DATA, Player, {}) ->
	arena_pvp_mod:enter_data(Player),
	{?ok, Player};
%% 队长开始
handler(?MSG_ID_ARENA_PVP_START, Player, {}) ->
	arena_pvp_mod:start(Player);
%% 请求更新虎符值
handler(?MSG_ID_ARENA_PVP_CS_TIGER, Player, {}) ->
	arena_pvp_mod:hufu_data(Player);
%% 兑换物品
handler(?MSG_ID_ARENA_PVP_EXCHANGE, Player, {Id,Num}) ->
	arena_pvp_mod:exchange(Player,Id,Num);
%% 取消开始
handler(?MSG_ID_ARENA_PVP_CANCEL, Player, {}) ->
%% 	arena_pvp_mod:cancel(Player, 1), 
	{?ok, Player};
%% 请求结束奖励
handler(?MSG_ID_ARENA_PVP_CS_REWARD, Player, {}) ->
 	arena_pvp_mod:active_end_reward(Player#player.user_id),
	{?ok, Player};
%% 是否自动准备
handler(?MSG_ID_ARENA_PVP_CS_AUTO, Player, {Type,Flag}) ->
	arena_pvp_mod:set_auto(Player#player.user_id,Type,Flag),
	{?ok, Player};
%% 请求自动信息
handler(?MSG_ID_ARENA_PVP_CS_AUTO_DATA, Player, {}) ->
	arena_pvp_mod:auto_data(Player#player.user_id),
	{?ok, Player};
%% 请求排名数据
handler(?MSG_ID_ARENA_PVP_CS_RANK_DATA, Player, {}) ->
%% 	List 	= arena_pvp_api:rank_list(),
%% 	Packet	= arena_pvp_api:msg_sc_rank_data(List),
%% 	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%

