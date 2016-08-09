%% Author: Administrator
%% Created: 2012-7-27
%% Description: TODO: Add description to pratice_handle
-module(practice_handler).
%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
-include("record.data.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 修炼请求 
handler(?MSG_ID_PRACTICE_SINGLE_REQUEST, Player, {}) ->
	case practice_mod:single_request(Player) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		{?ok, Player2}     -> {?ok, Player2}
	end;

%% 双修请求
handler(?MSG_ID_PRACTICE_DOUBLE_REQUEST, Player, {MemId}) ->
	case practice_mod:double_request(Player,MemId) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_                  -> ?ok
	end;
	
%% 双修邀请回复
handler(?MSG_ID_PRACTICE_DOUBLE_REPLY, Player, {Type,MemId}) ->
	case practice_mod:double_reply(Player,MemId,Type) of
		{?ok, Player2}     -> {?ok, Player2};
		{?error,ErrorCode} -> {?error,ErrorCode}
	end;
	
%% 取消修炼
handler(?MSG_ID_PRACTICE_CANCEL, Player, {}) ->
	{_,Player2} 	= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
	practice_mod:doll_cancel_double(Player),
	{?ok,Player2};

%% vip双修设定
handler(?MSG_ID_PRACTICE_VIP_OPTIONS, Player, {Automatic}) ->
	practice_mod:auto_options(Player#player.user_id, Automatic),
	?ok;

%% 双修设定
handler(?MSG_ID_PRACTICE_OPTIONS, _Player, {}) ->
	?ok;

%% 请求离线经验
handler(?MSG_ID_PRACTICE_CS_LEAVE_EXP, _Player, {}) ->
	?ok;

%% 请求转成双修状态
handler(?MSG_ID_PRACTICE_CS_DOUBLE_STATE, Player, {}) ->
	practice_mod:double_broadcast(Player);

%% 请求设置离线机器人
handler(?MSG_ID_PRACTICE_CS_OFFLINE_SET, Player, {Type, TotalTime}) ->
	UserId = Player#player.user_id,
	case practice_mod:set_offline_robot(Player, Type, TotalTime) of
		{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			TipPacket = message_api:msg_notice(?TIP_COMMON_CASH_NOT_ENOUGH), 
			misc_packet:send(UserId, TipPacket);
		{?error, _ErrorCode} ->
			TipPacket = message_api:msg_notice(?TIP_PRACTICE_AUTO_FAIL), 
			misc_packet:send(UserId, TipPacket);
		?ok ->
			Packet = practice_api:msg_sc_offline_set_res(1),
			misc_packet:send(UserId, Packet),
			TipPacket = message_api:msg_notice(?TIP_PRACTICE_AUTO_SUCCESS), 
			misc_packet:send(UserId, TipPacket)
	end,
	?ok;

%% 查询离线修炼设置
handler(?MSG_ID_PRACTICE_CS_QUERY_OFFLINE_SET, Player, {}) ->
	practice_mod:query_offline_set(Player);

%% 取消离线修炼设置
handler(?MSG_ID_PRACTICE_CS_CANCEL_OFFLINE_SET, Player, {}) ->
	practice_mod:cancel_offline_set(Player);

%% 获取可修炼时间
handler(?MSG_ID_PRACTICE_CS_GET_VALID_TIME, Player, {Type}) ->
	ValidTime = practice_mod:get_valid_time(Player, Type),
	Packet = practice_api:msg_sc_valid_time(Type, ValidTime),
	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 清除CD
handler(?MSG_ID_PRACTICE_CS_CLEAR_CD, Player, {Type}) ->
	case practice_mod:clear_cd(Player, Type) of  
		{?ok, Player2} -> {?ok,Player2};
		{?error,?TIP_COMMON_CASH_NOT_ENOUGH} -> ?error;
		{?error,ErrorCode} -> {?error,ErrorCode}
	end;

handler(_MsgId, _Player, _Datas) -> ?undefined.



%%
%% Local Functions
%%

