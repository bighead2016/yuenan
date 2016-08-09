%% Author: php
%% Created: 
%% Description: TODO: Add description to welfare_handler
-module(welfare_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").

-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 请求礼包信息
handler(?MSG_ID_WELFARE_CSGIFTINFO, Player, {Type})		->
	welfare_mod:welfare_info(Player, Type);

%% 领取礼包
handler(?MSG_ID_WELFARE_CSDRAW, Player, {Param, State})	->
	NewPlayer	= welfare_mod:refresh(Player),
	{?ok, DrawPlayer}	= welfare_mod:draw(NewPlayer, Param, State),
	{?ok, DrawPlayer};

%% 领取奖励
handler(?MSG_ID_WELFARE_CSRECEIVE, Player, {TargetId})	->
	welfare_mod:pullulation(Player, TargetId);

%% 连续登陆补签
handler(?MSG_ID_WELFARE_CS_LOGIN_REVIEW, Player, {GiftId}) ->
	{?ok, Player2} = welfare_mod:continue_login_review(Player, GiftId),
	{?ok, Player2};

%% 领取礼包
handler(?MSG_ID_WELFARE_CS_GET_GIFT_2, Player, {GiftId}) ->
    Player2 = welfare_deposit_api:get_gift(Player, GiftId),
    {?ok, Player2};

%% 请求基金活动
handler(?MSG_ID_WELFARE_CS_JJ, Player, {Type}) ->
    welfare_fund_api:buy_fund(Player, Type);

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
