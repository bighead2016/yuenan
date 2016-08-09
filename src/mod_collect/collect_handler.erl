%% Author: php
%% Created: 
%% Description: TODO: Add description to collect_handler
-module(collect_handler).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.protocol.hrl").
-include("../include/const.define.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 开始采集
handler(?MSG_ID_COLLECT_CS_START_COLLECT, Player, {Lv, Type, Times}) ->
	{?ok , Player3} =
		case collect_api:start_collect(Player, Lv, Type, Times) of
			{?ok, Player2} ->
				Res = 0,
				Packet = misc_packet:pack(?MSG_ID_COLLECT_SC_START, ?MSG_FORMAT_COLLECT_SC_START, [Res]),
				misc_packet:send(Player#player.user_id, Packet),
				{?ok, Player2};
			{?error, _ErrorCode2, PacketError2} ->
				misc_packet:send(Player#player.user_id, PacketError2),
				{?ok, Player}
		end,
	{?ok, Player3};
%% 结束采集
handler(?MSG_ID_COLLECT_CS_END_COLLECT, Player, {}) ->
	collect_api:end_collect(Player#player.user_id),
	?ok;

%% 进入采集地图
handler(?MSG_ID_COLLECT_CS_ENTER_MAP, Player, {MapId}) ->
	{?ok, Player2} = collect_api:enter(Player, MapId),
	{?ok, Player2};

%% 退出采集地图
handler(?MSG_ID_COLLECT_CS_EXIT_MAP, Player, {}) ->
	{?ok, Player2} = collect_api:exit(Player),
	{?ok, Player2};

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
