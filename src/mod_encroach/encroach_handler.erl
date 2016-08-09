%% Author: php
%% Created: 
%% Description: TODO: Add description to encroach_handler
-module(encroach_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 获取初始化信息
handler(?MSG_ID_ENCROACH_CS_INIT_INFO, Player, {}) ->
	encroach_mod:get_init_info(Player),
	{?ok, Player};
%% 移动
handler(?MSG_ID_ENCROACH_CS_MOVE, Player, {NextPos}) ->
	encroach_mod:moving(Player, NextPos);
%% 获取排行榜
handler(?MSG_ID_ENCROACH_CS_RANK_INFO, Player, {}) ->
	encroach_mod:get_rank_info(Player),
	{?ok, Player};
%% 重置玩法
handler(?MSG_ID_ENCROACH_CS_RESET, Player, {}) ->
	encroach_mod:reset_info(Player),
	{?ok, Player};
%% 购买移动力
handler(?MSG_ID_ENCROACH_CS_BUY_POINT, Player, {Count}) ->
	encroach_mod:buy_move_point(Player, Count),
	{?ok, Player};
%% 抽奖
handler(?MSG_ID_ENCROACH_CS_LOTTERY, Player, {}) ->
	encroach_mod:lottery(Player);
%% 发协议
handler(?MSG_ID_ENCROACH_CS_SEND, Player, {}) ->
	encroach_mod:lottery_broadcast(Player),
	{?ok, Player};
%% 查看获得物品
handler(?MSG_ID_ENCROACH_CS_AWARD_GOODS, Player, {}) ->
	encroach_mod:get_award_goods(Player),
	{?ok, Player};
%% 检测是否可移动
handler(?MSG_ID_ENCROACH_CS_CHK_CAN_MOV, Player, {NextPos}) ->
	encroach_mod:check_can_move(Player, NextPos),
	{?ok, Player};
%% 获取剩余次数
handler(?MSG_ID_ENCROACH_CS_REST_TIMES, Player, {}) ->
	encroach_mod:get_rest_times(Player),
	{?ok, Player};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
