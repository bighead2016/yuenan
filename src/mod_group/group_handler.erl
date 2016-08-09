%% Author: php
%% Created: 2012-09-14 09
%% Description: TODO: Add description to group_handler
-module(group_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 查询团队信息
handler(?MSG_ID_GROUP_CS_LIST_GROUP, Player, {GroupId}) ->
	Packet		= group_mod:search_member_info(Player, GroupId),
    misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};

%% 创建团队
handler(?MSG_ID_GROUP_CS_CREATE, Player, {Restrict}) ->
	Player2 	= group_mod:create_group(Player, Restrict),
	{?ok, Player2};

%% 离开团队
handler(?MSG_ID_GROUP_CS_QUIT, Player, {}) ->
	case group_mod:quit_group(Player) of
        {?ok, Player2} ->
            schedule_power_api:do_change_group(Player2),
            {?ok, Player2};
        {?error, _ErrorCode} ->
            {?ok, Player}
    end;

%% 转换队长
handler(?MSG_ID_GROUP_CS_NEW_LEADER, Player, {NewLeaderId}) ->
	group_mod:change_leader(Player, NewLeaderId),
	{?ok, Player};

%% 申请加入团队
handler(?MSG_ID_GROUP_CS_REQ2JOIN, Player, {GroupId}) ->
	group_mod:apply_join_group(Player, GroupId, ?CONST_SYS_FALSE),
	{?ok, Player};

%% 回复申请加入团队
handler(?MSG_ID_GROUP_CS_RSP2JOIN, Player, {Result,UserId}) ->
	case group_mod:reply_join_group(Player, Result, UserId) of
        {?ok, Player2} ->
            schedule_power_api:do_change_group(Player2),
            {?ok, Player2};
        {?error, _ErrorCode} ->
            {?ok, Player}
    end;

%% 踢出团队
handler(?MSG_ID_GROUP_CS_KICKOUT, Player, {UserId}) ->
	case group_mod:kick_out_group(Player, UserId) of
        {?ok, Player2} ->
            schedule_power_api:do_change_group(Player2),
            {?ok, Player2};
        {?error, _ErrorCode} ->
            {?ok, Player}
    end;

%% 取消申请加入
handler(?MSG_ID_GROUP_CS_CANCEL2JOIN, Player, {GroupId}) ->
	group_mod:cancel_apply_join(Player, GroupId),
	{?ok, Player};

%% 自动加入
handler(?MSG_ID_GROUP_CS_AUTOJOIN, Player, {}) ->
	group_mod:auto_join_group(Player),
	{?ok, Player};

%% 申请成为待组玩家
handler(?MSG_ID_GROUP_CS_REQ2WAITING, Player, {}) ->
	group_mod:apply_waiting_group(Player),
	{?ok, Player};

%% 待组玩家状态取消
handler(?MSG_ID_GROUP_CS_CANCEL2WAIT, Player, {}) ->
	group_mod:cancel_apply_waiting(Player),
	{?ok, Player};

%% 邀请玩家
handler(?MSG_ID_GROUP_CS_INVITE, Player, {Type, UserId}) ->
	case group_mod:invite_group(Player, Type, UserId) of
		{?ok, NewPlayer} ->
			{?ok, NewPlayer};
		{?error, _} ->
			{?ok, Player}
	end;

%% 邀请玩家回复
handler(?MSG_ID_GROUP_CS_RSP2INVITE, Player, {GroupId, UserId, Result}) ->
	case group_mod:reply_invite_group(Player, GroupId, UserId, Result) of
        {?ok, Player2} ->
            schedule_power_api:do_change_group(Player2),
            {?ok, Player2};
        {?error, _ErrorCode} ->
            {?ok, Player}
    end;

%% 获取待组玩家列表
handler(?MSG_ID_GROUP_CS_LIST_WAIT, Player, {Type}) ->
	group_mod:get_waiting_group(Player, Type),
	{?ok, Player};

%% 推荐队伍列表
handler(?MSG_ID_GROUP_CS_RECOMMEND, Player, {}) ->
	group_mod:get_recommand_list(Player),
	{?ok, Player};

%% 请求属性加成
handler(?MSG_ID_GROUP_CS_TEMP_BUFFER, Player, {1, GroupId}) ->
    UserId 		= Player#player.user_id,
    Info   		= Player#player.info,
    {_, Packet} = group_mod:calc_buff_group2me(Info, GroupId),
    misc_packet:send(UserId, Packet),
    schedule_power_api:do_change_group(Player),
    {?ok, Player};
handler(?MSG_ID_GROUP_CS_TEMP_BUFFER, Player, {2, UserIdW}) -> % UserIdW这个玩家对我的队伍的加成
    UserId 		= Player#player.user_id,
    Info   		= Player#player.info,
    {_, Packet} = group_mod:calc_buff_me2group(UserId, Info, UserIdW),
    misc_packet:send(UserId, Packet),
    {?ok, Player};

%% 请求成员战力
handler(?MSG_ID_GROUP_CS_MEMBER_POWER, Player, {UserId}) ->
	group_mod:get_member_power(Player, UserId),
	{?ok, Player};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
%%
%% Local Functions
%%
