%% Author: php
%% Created: 
%% Description: TODO: Add description to mcopy_handler
-module(mcopy_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([handler/3, start_battle/3]).
%%
%% API Functions
%%
%% 进入副本

start_battle(Player, TeamId, MonsterId) ->
    RobotList   = team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
    case battle_api:start(Player, MonsterId, #param{battle_type = ?CONST_BATTLE_TRIBE_COPY, ad5 = TeamId, robot = RobotList}) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, _ErrorCode} ->
            ?error
    end.
handler(?MSG_ID_MCOPY_CS_ENTER, Player, {}) ->
    mcopy_mod:enter(Player);

%% 遇到奇遇_发起战斗
handler(?MSG_ID_MCOPY_CS_BATTLE, Player, {QId}) ->
	mcopy_api:start_q(Player, QId),
    ?ok;

%% 发起战斗
handler(?MSG_ID_MCOPY_CS_NORMAL_BATTLE, Player, {MonsterId}) ->
	case map_api:start_mcopy_battle(Player) of
		MapData	when is_record(MapData, mcopy_map_data) ->
			MonsterList 	= MapData#mcopy_map_data.mon_list,
			?MSG_DEBUG("~n555555555555555555555555555555555555555555555555555~p", [{MonsterId, MonsterList}]),
			case lists:member(MonsterId, MonsterList) of
				?true ->
					case Player#player.team_id of
						{TeamId, NodeId} ->
							Node = cross_api:get_node(NodeId),
							{ok, Player2, _} = player_api:get_player_first(Player#player.user_id),
							case rpc:call(Node, ?MODULE, start_battle, [Player2#player{map_pid = Player#player.map_pid, user_state = Player#player.user_state},
																					  TeamId, MonsterId]) of
								{ok, Player3} ->
									Player4 = Player#player{
															practice_state = Player3#player.practice_state,
															user_state = Player3#player.user_state,
															battle_type = Player3#player.battle_type,
															is_skiped = Player3#player.is_skiped,
															can_skip = Player3#player.can_skip,
															info = Player3#player.info,
															battle_pid = Player3#player.battle_pid, 
															play_state = Player3#player.play_state},
									{ok, Player4};
								O ->
									O
							end;
						TeamId ->
							start_battle(Player, TeamId, MonsterId)
					end;
				?false -> {?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end;

%% 领取奖励(VIP)
handler(?MSG_ID_MCOPY_CS_GET_AWARD, Player, {}) ->
	VipLv		= player_api:get_vip_lv(Player#player.info),
	case player_vip_api:can_mcopy_get_again(VipLv) of
		?CONST_SYS_TRUE ->
			mcopy_mod:get_award_again(Player);
		_ -> 
            {?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}
	end;

%% 请求副本列表
handler(?MSG_ID_MCOPY_CS_LIST_COPY, Player, {}) ->
    {Player2, PacketTotal} = 
        case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_MULTI_COPY) of
            {?true, NewPlayer} ->
                case team_api:enter_hall(NewPlayer) of
                    {?ok, PacketHall} ->
                        {?ok, _List, Packet} = mcopy_api:list_mcopy(Player),
                        {NewPlayer, <<PacketHall/binary, Packet/binary>>};
                    {?error, ErrorCode} ->
                        PacketErr = message_api:msg_notice(ErrorCode),
                        {NewPlayer, PacketErr}
                end;
            {?false, _Player, Tips} ->
%%                 ErrorCode = ?TIP_COMMON_PLAY_STATE_OTHER,
                PacketErr = message_api:msg_notice(Tips),
                {Player, PacketErr}
        end,
    misc_packet:send(Player#player.net_pid, PacketTotal),
    {?ok, Player2};

%% 退出副本
handler(?MSG_ID_MCOPY_CS_EXIT, Player, {_Type}) ->
    case mcopy_mod:exit(Player) of
		{?error, ErrorCode} -> {?error, ErrorCode};
		Player2 -> {?ok, Player2}
	end;

%% 跳转点进入副本
handler(?MSG_ID_MCOPY_CS_ENTER_SKIP, Player, {CopyId}) ->
	mcopy_mod:enter_by_skip(Player, CopyId);

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
