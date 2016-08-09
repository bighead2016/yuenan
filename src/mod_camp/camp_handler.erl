%% Author: php
%% Created: 2012-08-24 15
%% Description: TODO: Add description to camp_handler
-module(camp_handler).

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
%% 请求阵法信息
handler(?MSG_ID_CAMP_CS_INFO, Player, {}) ->
    UserId = Player#player.user_id,
	Packet = camp_api:camp_info(Player),
    misc_packet:send(UserId, Packet),
	?ok;

%% 升级阵法
handler(?MSG_ID_CAMP_CS_UPGRADE, Player, {CampId}) ->
	case camp_api:upgrade(Player, CampId) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;

%% 阵型站位移除
handler(?MSG_ID_CAMP_CS_REMOVE_POS, Player, {CampId,CampIdx}) ->
    case camp_api:remove(Player, CampId, CampIdx) of
        {?ok, Player2} -> {?ok, Player2};
        {?error, _ErrorCode} ->
            ?error
    end;

%% 阵型站位交换
handler(?MSG_ID_CAMP_CS_EXCHANGE_POS, Player, {CampId,IdxFrom,IdxTo}) ->
	case camp_api:exchange_pos(Player, CampId, IdxFrom, IdxTo) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;

%% 设置阵型站位
handler(?MSG_ID_CAMP_CS_SET_POS, Player, {CampId,CampIdx,Type,Id}) ->
	case camp_api:set_pos(Player, CampId, CampIdx, Type, Id, ?CONST_CAMP_SET_POS_TYPE_1) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;

%% 启用阵型
handler(?MSG_ID_CAMP_CS_START_CAMP, Player, {CampId}) ->
	case camp_api:start_camp(Player, CampId) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;

%% 请求阵型站位数据
handler(?MSG_ID_CAMP_CS_POS_INFO, Player, {CampId}) ->
	case camp_mod:get_pos(Player, CampId) of
        ?ok ->
        	{?ok, Player};
        {?error, _ErrorCode} ->
            ?error
    end;

%% 请求阵法是否有空位
handler(?MSG_ID_CAMP_CS_POS_NULL, Player, {}) ->
	Flag	= camp_api:curcamp_have_empty(Player),
	Packet  = camp_api:msg_camp_sc_pos_null(Flag),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
