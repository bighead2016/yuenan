%% Author: php
%% Created: 
%% Description: TODO: Add description to boss_handler
-module(boss_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.robot.hrl").
-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%

%% 请求进入世界BOSS
handler(?MSG_ID_BOSS_CS_ENTER, Player, {BossId}) ->
%% 	boss_api:enter(Player, BossId, ?CONST_SYS_FALSE);
	boss_api:enter(Player, BossId, ?false);
%% 自动
handler(?MSG_ID_BOSS_CS_AUTO, Player, {Auto}) ->
	boss_api:auto(Player, Auto),
	?ok;
%% 鼓舞
handler(?MSG_ID_BOSS_CS_ENCOURAGE, Player, {}) ->
	boss_api:encourage(Player, ?false),
	?ok;
%% 浴火重生
handler(?MSG_ID_BOSS_CS_REBORN, Player, {}) ->
	case boss_api:reborn(Player, ?false) of
		{?ok, Player2} -> {?ok, Player2};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			?error;
		{?error, ErrorCode, Value} ->
			Packet = message_api:msg_notice(ErrorCode, [{?TIP_SYS_COMM, misc:to_list(Value)}]),
			misc_packet:send(Player#player.net_pid, Packet),
			?error
	end;
%% 战斗开始
handler(?MSG_ID_BOSS_CS_BATTLE, Player, {Auto}) ->
	case boss_api:start_battle(Player, ?CONST_SYS_FALSE, Auto, ?false) of
		  {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 	case boss_api:battle_start(Player, ?true, Auto, ?CONST_SYS_FALSE) of
%% 		{?ok, Player2} -> {?ok, Player2};
%% 		{?error, ?TIP_BATTLE_OFF} -> ?error;
%% 		{?error, ErrorCode} -> {?error, ErrorCode}
%% 	end;
%% 复活
handler(?MSG_ID_BOSS_CS_REVIVE, Player, {}) ->
	boss_api:revive(Player, ?false);
%% 自动复活
handler(?MSG_ID_BOSS_CS_AUTO_REVIVE, Player, {}) ->
	boss_api:auto_revive(Player);
%% 退出世界BOSS
handler(?MSG_ID_BOSS_CS_QUIT, Player, {}) ->
	boss_api:quit(Player);
%% 世界BOSS雇佣替身娃娃
handler(?MSG_ID_BOSS_CS_HIRE_DOLL, Player, {BossId,IsEn,IsReborn,IsQuickReborn,Cash}) ->
    boss_api:hire_doll(Player, BossId, IsEn, IsReborn, IsQuickReborn, Cash);

%% 查询替身元宝数
handler(?MSG_ID_BOSS_CS_DOLL_CASH, Player, {BossId}) ->-
    case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, Player#player.user_id}) of
        #ets_boss_robot_setting{cash = Cash, bcash_2 = BCash2} ->
            Packet = boss_api:msg_sc_doll_cash(BossId, Cash+BCash2),
            misc_packet:send(Player#player.user_id, Packet),
            ?ok;
        _ ->
        	Packet = boss_api:msg_sc_doll_cash(BossId, 0),
            misc_packet:send(Player#player.user_id, Packet),
            ?ok
    end,
    ?ok;

%% 查询状态
handler(?MSG_ID_BOSS_CS_CHECK_STATE, Player, {_}) ->
    UserId				= Player#player.user_id,
	Lv					= (Player#player.info)#info.lv,
	Lv1					= case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
							  BossPlayer when is_record(BossPlayer, boss_player) ->
								  BossPlayer#boss_player.lv;
							  _ -> Lv
						  end,
	{Node, Room, _Lv}	= cross_api:get_boss_master(UserId, Lv1, ?false),
	case rpc:call(Node, boss_mod, get_boss_data, [Room]) of
		BossData when is_record(BossData, boss_data) ->
			BossState = BossData#boss_data.state,
			IsStart   = 
				if
					BossState =:= ?CONST_BOSS_STATE_START ->
						?CONST_SYS_TRUE;
					?true ->
						?CONST_SYS_FALSE
				end,
			?MSG_ERROR("nimeiaaaaaaaaaaaaaaaaaaaaaa->[~p|~p]", [IsStart, BossState]),
			Packet  = boss_api:msg_sc_state(IsStart),
			misc_packet:send(UserId, Packet);
		_ ->
			?MSG_ERROR("nimeiaaaaaaaaaaaaaaaaaaaaaa->no boss data", []),
			Packet  = boss_api:msg_sc_state(?CONST_SYS_FALSE),
			misc_packet:send(UserId, Packet)
	end,
	?ok;
%%     case boss_api:get_open_boss() of
%%         BossData when is_record(BossData, boss_data) ->
%%             BossState = BossData#boss_data.state,
%%             IsStart   = 
%%                 if
%%                     BossState =:= ?CONST_BOSS_STATE_START ->
%%                         ?CONST_SYS_TRUE;
%%                     ?true ->
%%                         ?CONST_SYS_FALSE
%%                 end,
%% 			?MSG_ERROR("nimeiaaaaaaaaaaaaaaaaaaaaaa->[~p|~p]", [IsStart, BossState]),
%%             Packet  = boss_api:msg_sc_state(IsStart),
%%             misc_packet:send(UserId, Packet);
%%         _ ->
%% 			?MSG_ERROR("nimeiaaaaaaaaaaaaaaaaaaaaaa->no boss data", []),
%%             Packet  = boss_api:msg_sc_state(?CONST_SYS_FALSE),
%%             misc_packet:send(UserId, Packet)
%%     end,
%%     ?ok;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
