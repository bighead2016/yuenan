%% Author: Administrator
%% Created: 2014-2-25
%% Description: TODO: Add description to partner_soul_handler
-module(partner_soul_handler).

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
%% 将魂升级
handler(?MSG_ID_PARTNER_SOUL_CS_UPGRADE, Player, {PartnerId}) ->
	partner_soul_mod:upgrade_partner_soul(Player, PartnerId);

%% 将魂星级升级
handler(?MSG_ID_PARTNER_SOUL_CS_UPGRADE_STAR, Player, {PartnerId}) ->
	partner_soul_mod:upgrade_partner_soul_star(Player, PartnerId);

%% 将魂继承
handler(?MSG_ID_PARTNER_SOUL_CS_INHERIT, Player, {ToPartner,FromPartner}) ->
	partner_soul_mod:inherit_partner_soul(Player, ToPartner, FromPartner);

%% 请求将魂信息
handler(?MSG_ID_PARTNER_SOUL_CS_INFO, Player, {PartnerId}) ->
	partner_soul_mod:get_partner_soul_info(Player, PartnerId),
	{?ok, Player};

%% 将魂属性
handler(?MSG_ID_PARTNER_SOUL_CS_ATTR, Player, {UserId,PartnerId}) ->
	partner_soul_mod:get_partner_soul_attr(Player, UserId, PartnerId),
	{?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.


%%
%% Local Functions
%%

