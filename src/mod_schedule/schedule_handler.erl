%% Author: php
%% Created: 
%% Description: TODO: Add description to schedule_handler
-module(schedule_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 签到信息
handler(?MSG_ID_SCHEDULE_CSSIGNINFO, Player, {}) ->
	Player1	= schedule_mod:sign_info(Player),
	schedule_mod:sign_gift_info(Player1),
	{?ok, Player1};

%% 每日签到
handler(?MSG_ID_SCHEDULE_CSSIGN, Player, {}) ->
	{?ok, Player1}	= schedule_mod:sign(Player),
	Player2			= schedule_mod:sort(Player1),
	Player3			= schedule_mod:sign_info(Player2),
	Player4			= schedule_mod:draw_sign_gift(Player3),
	schedule_mod:sign_gift_info(Player4),
	{?ok, Player4};

%% 每日补签
handler(?MSG_ID_SCHEDULE_CSREVIEW, Player, {})	->
	Player1	= schedule_mod:review(Player),
	Player2	= schedule_mod:sort(Player1),
	Player3	= schedule_mod:sign_info(Player2),
	Player4	= schedule_mod:draw_sign_gift(Player3),
	schedule_mod:sign_gift_info(Player4),
	{?ok, Player4};

%% 领取签到礼品
handler(?MSG_ID_SCHEDULE_CSDRAWSIGNGIFT, _Player, {_GiftId}) ->
	?ok;
%% 	schedule_mod:draw_sign_gift(Player, GiftId);

%% 日常活动信息
handler(?MSG_ID_SCHEDULE_CSACTIVITYINFO, Player, {}) ->
%% 	NewPlayer	= schedule_mod:activity_info(Player),
	schedule_mod:auto_info(Player);
%% 自动完成活动（替身娃娃）
handler(?MSG_ID_SCHEDULE_CSAUTO, Player, {ActivityId, State}) ->
	schedule_api:auto(Player, ActivityId, State);
 
%% 日常引导信息
handler(?MSG_ID_SCHEDULE_CSGUIDEINFO, Player, {}) ->
	Player1	= schedule_mod:guide_info(Player),
	schedule_mod:liveness(Player1),
	schedule_mod:liveness_gift_info(Player1),
	{?ok, Player1};

%% 领取活跃度礼品
handler(?MSG_ID_SCHEDULE_CSDRAWLIVENESSGIFT, Player, {GiftId}) ->
	schedule_mod:draw_liveness_gift(Player, GiftId);

%% 登录信息
handler(?MSG_ID_SCHEDULE_CSLOGIN, _Player, {}) ->
%% 	schedule_mod:login(Player),
	?ok;

%% 每日军情玩法次数
handler(?MSG_ID_SCHEDULE_CS_PLAY_TIMES, Player, {}) ->
	CalcList			= data_schedule:get_activity_play_list(),
	Packet				= schedule_api:times_packet(Player, CalcList, <<>>),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 请求资源找回
handler(?MSG_ID_SCHEDULE_CS_RESOURCE_LOOKFOR, Player, {}) ->
	schedule_mod:get_resource_lookfor(Player),
	{?ok, Player};

%% 请求单个找回
handler(?MSG_ID_SCHEDULE_CS_SINGLE_RESOURCE, Player, {Type,Id}) ->
	schedule_mod:get_single_resource(Player, Type, Id);

%% 一键找回
handler(?MSG_ID_SCHEDULE_CS_ALL_RESOURCE, Player, {Type}) ->
	schedule_mod:get_all_resource(Player, Type);

%% 战力信息
handler(?MSG_ID_SCHEDULE_CS_POWER_INFO, Player, {}) ->
    UserId = Player#player.user_id,
    Packet = schedule_power_api:packet_all(Player),
    misc_packet:send(UserId, Packet),
    ?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
