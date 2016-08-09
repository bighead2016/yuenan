%% Author: Administrator
%% Created: 
%% Description: TODO: Add description to cross_arena_handler
-module(cross_arena_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
-include("../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 打开跨服竞技场界面
handler(?MSG_ID_CROSS_ARENA_CS_ENTER, Player, {Type}) ->
	cross_arena_mod:enter(Player, Type);
%% 发起战斗
handler(?MSG_ID_CROSS_ARENA_CS_START_BATTLE, Player, {Platform,Sn,EnemyId}) ->
	?MSG_DEBUG("1111111111111111111111111111111111111:~p",[{Platform, Sn, EnemyId}]),
	UserId	= Player#player.user_id,
	case cross_arena_mod:get_arena_info_by_id(UserId) of
		[] ->
			?MSG_DEBUG("2222222222222222:~p",[{Platform, Sn, EnemyId}]),
			cross_arena_robot_api:start_battle(Player, EnemyId);
		_ ->
			?MSG_DEBUG("3333333333333333:~p",[{Platform, Sn, EnemyId}]),
			cross_arena_mod:start_battle(Player, Platform, Sn, EnemyId)
	end;
%% 天神榜信息
handler(?MSG_ID_CROSS_ARENA_CS_TOP_PHASE_INFO, Player, {}) ->
	cross_arena_mod:god_phase_info(Player),
	{?ok, Player};
%% 领取排名奖励
handler(?MSG_ID_CROSS_ARENA_CS_RANK_AWARD, Player, {}) ->
	UserId	= Player#player.user_id,
	case cross_arena_mod:get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			cross_arena_mod:get_day_reward(Player);
		_ ->
			{?ok, Player}
	end;

%% 打开成就界面
handler(?MSG_ID_CROSS_ARENA_CS_ACHIEVE, Player, {}) ->
	UserId	= Player#player.user_id,
	case cross_arena_mod:get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			cross_arena_mod:achieve_info(Player),
			{?ok, Player};
		_ ->
			{?ok, Player}
	end;
%% 领取成就奖励
handler(?MSG_ID_CROSS_ARENA_CS_ACHIEVE_REWARD, Player, {Phase}) ->
	cross_arena_mod:get_achieve_reward(Player, Phase);

%% 天神商店购买
handler(?MSG_ID_CROSS_ARENA_CROSS_ARENA_CS_BUY, Player, {Id,Count}) ->
	cross_arena_mod:buy(Player, Id, Count);

%% 查看人物详细
handler(?MSG_ID_CROSS_ARENA_CS_CROSS_PLAYER_INFO, Player, {Platform,Sn,UserId}) ->
	cross_arena_mod:cross_player_info(Player, Platform, Sn, UserId),
	{?ok, Player};

%% 查看武将信息
handler(?MSG_ID_CROSS_ARENA_PARTNER_INFO, Player, {Platform,Sn,UserId,PartnerId}) ->
	cross_arena_mod:cross_partner_info(Player, Platform, Sn, UserId, PartnerId),
	{?ok, Player};

%% 获取武将列表
handler(?MSG_ID_CROSS_ARENA_CROSS_ARENA_PARTNER, Player, {Platform,Sn,UserId}) ->
	cross_arena_mod:cross_partner(Player, Platform, Sn, UserId),
	{?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
