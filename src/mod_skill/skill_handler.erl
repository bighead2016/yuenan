%% Author: php
%% Created: 2012-08-17 15
%% Description: TODO: Add description to skill_handler
-module(skill_handler).

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
%% 请求技能信息
handler(?MSG_ID_SKILL_CS_SKILL_INFO, Player, {}) ->
	Packet		     = skill_mod:skill_info(Player),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;
%% 升级技能
handler(?MSG_ID_SKILL_CS_UPGRADE_SKILL, Player, {SkillId}) ->
	{?ok, NewPlayer} = skill_mod:upgrade_skill(Player, SkillId),
	{?ok, NewPlayer};
%% 启用技能
handler(?MSG_ID_SKILL_CS_ENABLE_SKILL, Player, {SkillId,Idx}) ->
	{?ok, NewPlayer} = skill_mod:enable_skill(Player, SkillId, Idx),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	{?ok, NewPlayer};
%% 停用技能
handler(?MSG_ID_SKILL_CS_DISABLE_SKILL, Player, {Idx}) ->
	{?ok, NewPlayer} = skill_mod:disable_skill(Player, Idx),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	{?ok, NewPlayer};
%% 交换技能栏位置
handler(?MSG_ID_SKILL_CS_EXCHANGE_SKILL_BAR, Player, {IdxFrom,IdxTo}) ->
	{?ok, NewPlayer} = skill_mod:exchange_skill_bar(Player, IdxFrom, IdxTo),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	{?ok, NewPlayer};
%% 技能洗点
handler(?MSG_ID_SKILL_CS_RESET_SKILL_POINT, Player, {}) ->
	{?ok, NewPlayer} = skill_mod:reset_skill_point(Player),
	{?ok, NewPlayer};
handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	?error.
%%
%% Local Functions
%%
