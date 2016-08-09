%% Author: php
%% Created: 
%% Description: TODO: Add description to guide_handler
-module(guide_handler).

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
%% 模块信息
handler(?MSG_ID_GUIDE_CSINFO, Player, {}) ->
    UserId = Player#player.user_id,
    GuideList = Player#player.guide,
    Packet = guide_api:msg_scinfo(GuideList),
    misc_packet:send(UserId, Packet),
	{?ok, Player};

%% 模块更新
handler(?MSG_ID_GUIDE_CSUPDATE, Player, {Module}) ->
    GuideList = Player#player.guide,
    NewGuideList = guide_api:finish_module(GuideList, Module),
    NewPlayer = Player#player{guide = NewGuideList},
%% 	partner_api:msg_free_train_by_module(NewPlayer, Module),
    {?ok, NewPlayer2} = task_api:update_guide(NewPlayer, Module),
	{?ok, NewPlayer2};

%% 请求拿钱
handler(?MSG_ID_GUIDE_CS_1ST, Player, {Module}) ->
    NewPlayer		= guide_api:flag_got(Player, Module),
    {?ok, NewPlayer};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
