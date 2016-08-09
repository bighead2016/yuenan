%% Author: php
%% Created: 
%% Description: TODO: Add description to weapon_handler
-module(weapon_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 装备神兵碎片
handler(?MSG_ID_WEAPON_CS_WEAPON_ON, Player, {Pro, Idx}) ->
	case weapon_mod:weapon_on(Player, Pro, Idx) of
		{?ok, Player2} ->
			{?ok, Player2};
		{?error, _ErrorCode} ->
			?ok
	end;
%% 卸下神兵碎片
handler(?MSG_ID_WEAPON_CS_WEAPON_OFF, Player, {Pro, Idx}) ->
	case weapon_mod:weapon_off(Player, Pro, Idx) of
		{?ok, Player2} ->
			{?ok, Player2};
		{?error, _ErrorCode} ->
			?ok
	end;
%% 神兵洗炼
handler(?MSG_ID_WEAPON_CS_REFRESH, Player, {CtnType, Pro, Index,{_Length, List}}) ->
	case weapon_mod:attr_refresh(Player, CtnType, Pro, Index, List) of
		{?ok, Player2}     -> {?ok, Player2};
		{?error,ErrorCode} -> {?error,ErrorCode}
	end;
%% 神兵淬火
handler(?MSG_ID_WEAPON_CS_QUENCH, Player, {CtnType,Pro,Index,AttrType}) ->
	case weapon_mod:weapon_quench(Player, CtnType, Pro, Index, AttrType) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 神兵免费次数
handler(?MSG_ID_WEAPON_CS_FREE_REFRESH, _Player, {}) ->
%% 	Weapon	= Player#player.weapon,
%% 	Times	= Weapon#weapon_data.refresh_times,
%% 	Packet	= weapon_api:msg_free_refresh_times(Times),
%% 	misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 双陆信息
handler(?MSG_ID_WEAPON_CS_CHESS_INFO, Player, {}) ->
	weapon_mod:chess_info(Player);

%% 购买骰子
handler(?MSG_ID_WEAPON_CS_CHESS_BUY_DICE, Player, {Type,Num}) ->
	case weapon_mod:buy_dice(Player, Type, Num) of
		{?ok, Player2}     -> {?ok, Player2};
		{?error,ErrorCode} -> {?error,ErrorCode}
	end;

%% 扔掷骰子
handler(?MSG_ID_WEAPON_CS_CHESS_DICE, Player, {Type}) ->
	case weapon_mod:dice(Player, Type) of
		{?ok, Player2}      -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 遥控骰子
handler(?MSG_ID_WEAPON_CS_CHESS_CONTROL_DICE, Player, {Type,Num1,Num2}) ->
	case weapon_mod:control_dice(Player, Type, Num1, Num2) of
		{?ok, Player2}      -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 路过第一个位置
handler(?MSG_ID_WEAPON_CS_CHESS_FIRST_POS, Player, {}) ->
	case weapon_mod:reward_first_pos(Player) of
		{?ok, Player2}      -> {?ok, Player2};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 清除cd
handler(?MSG_ID_WEAPON_CLEAR_CHESS_CD, Player, {}) ->
	weapon_mod:clear_chess_cd(Player);

%% 购买双陆次数
handler(?MSG_ID_WEAPON_CS_BUY_PUT_TIMES, Player, {}) ->
	weapon_mod:buy_put_times(Player);

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
