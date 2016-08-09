%% Author: php
%% Created: 2012-09-13 09
%% Description: TODO: Add description to copy_handler
-module(copy_single_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%

%% 进入副本
handler(?MSG_ID_COPY_SINGLE_CS_ENTER_COPY, Player, {CopyId}) ->
    UserId = Player#player.user_id,
    case copy_single_api:enter_copy(Player, CopyId) of
        {NewPlayer, Packet} when is_record(NewPlayer, player) ->
            misc_packet:send(UserId, Packet),
        	{?ok, NewPlayer};
        {?error, ?TIP_COPY_SINGLE_ALREADY_IN, _PacketErr} ->
            ?ok;
        {?error, _ErrorCode, PacketErr} ->
            misc_packet:send(UserId, PacketErr),
            ?error
    end;

%% 离开副本
handler(?MSG_ID_COPY_SINGLE_CS_EXIT_COPY, Player = #player{net_pid = NetPid}, {}) ->
    case copy_single_api:exit_copy(Player) of
        {?ok, NewPlayer} ->
            {?ok, NewPlayer};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(NetPid, Packet),
            ?error
    end;

%% 请求副本信息
handler(?MSG_ID_COPY_SINGLE_CS_COPY_INFO, Player = #player{net_pid = NetPid}, {}) ->
    UserId = Player#player.user_id,
    {?ok, Packet} = copy_single_api:copy_info(Player),
    Packet2 = copy_single_raid_api:get_end_time(UserId),
    misc_packet:send(NetPid, <<Packet/binary, Packet2/binary>>),
	?ok;

%% 再次挑战副本
handler(?MSG_ID_COPY_SINGLE_CS_AGAIN, Player = #player{net_pid = NetPid}, {}) ->
    case copy_single_api:again(Player) of
        {?ok, NewPlayer, Packet} ->
            misc_packet:send(NetPid, Packet),
            {?ok, NewPlayer};
        {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            misc_packet:send(NetPid, PacketError),
            ?error;
        {?error, ErrorCode} ->
            PacketError = message_api:msg_notice(ErrorCode),
            misc_packet:send(NetPid, PacketError),
            ?error
    end;

%% 副本扫荡请求
handler(?MSG_ID_COPY_SINGLE_CS_RAID, Player, {CopyId, Times}) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_SINGLE_COPY) of
		{?true, _NewPlayer} ->
			{_,Player2} = player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
			case copy_single_raid_api:start_raid(Player2, CopyId, Times) of
		        {?ok, _TotalTime, PacketTotalTime} ->
		            misc_packet:send(Player2#player.user_id, PacketTotalTime),
					{?ok, Player2};
		        {?error, _ErrorCode, PacketError} ->
		            misc_packet:send(Player#player.user_id, PacketError),
					{?ok, Player2}
		    end;
		{?false, Player, Tips} ->
			TipPacket 		= message_api:msg_notice(Tips),
			misc_packet:send(Player#player.net_pid, TipPacket),
			?error
	end;
	
    
%% 请求停止扫荡
handler(?MSG_ID_COPY_SINGLE_CS_STOP, Player, {?CONST_SYS_TRUE}) ->
    UserId   = Player#player.user_id,
    copy_single_elite_raid_api:stop_raid(UserId),
    ?ok;
handler(?MSG_ID_COPY_SINGLE_CS_STOP, Player, {?CONST_SYS_FALSE}) ->
    UserId   = Player#player.user_id,
    copy_single_raid_api:stop_raid(UserId),
    ?ok;

%% 快速扫荡
handler(?MSG_ID_COPY_SINGLE_CS_QUICK, Player, {Type, ?CONST_SYS_TRUE}) ->
	VipLv			= 	player_api:get_vip_lv(Player),
	CanQuickRaid	=   player_vip_api:can_quick_raid(VipLv),
	case CanQuickRaid of
		?CONST_SYS_TRUE ->
		    case copy_single_elite_raid_api:quick(Player, Type) of
		        {?ok, Player2} ->
		            {?ok, Player2};
                {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
                    UserId = Player#player.user_id,
                    PacketError = player_api:msg_sc_not_enough_sp(),
                    misc_packet:send(UserId, PacketError),
                    ?error;
		        {?error, ErrorCode} ->
		            UserId = Player#player.user_id,
		            PacketErr = message_api:msg_notice(ErrorCode),
		            misc_packet:send(UserId, PacketErr),
		            ?error
		    end;
		_ ->
			MsgPacket = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.user_id, MsgPacket),
			?error
	end;
handler(?MSG_ID_COPY_SINGLE_CS_QUICK, Player, {Type, ?CONST_SYS_FALSE}) ->
	VipLv			= player_api:get_vip_lv(Player),
	CanQuickRaid	= player_vip_api:can_quick_raid(VipLv),
	case CanQuickRaid of
		?CONST_SYS_TRUE ->
		    case copy_single_raid_api:quick(Player, Type) of
		        {?ok, Player2} ->
		            {?ok, Player2};
		        {?error, ErrorCode} ->
		            UserId = Player#player.user_id,
		            PacketErr = message_api:msg_notice(ErrorCode),
		            misc_packet:send(UserId, PacketErr),
		            ?error
		    end;
		_ ->
			MsgPacket = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.user_id, MsgPacket),
			?error
	end;

%% 发起战斗
handler(?MSG_ID_COPY_SINGLE_CS_BATTLE, Player, {MonsterId,HelpPartner,Idx,Anger}) ->
    UserId = Player#player.user_id,
    case copy_single_api:start_battle(Player, MonsterId, HelpPartner, Idx, Anger) of
        {?ok, Player2} ->
            Packet = copy_single_api:msg_sc_battle_ok(?CONST_SYS_TRUE),
            misc_packet:send(UserId, Packet),
            {?ok, Player2};
        {?error, PacketErr} ->
            misc_packet:send(UserId, PacketErr),
            ?error
    end;

%% 请求vip副本翻牌
handler(?MSG_ID_COPY_SINGLE_CS_VIP_REQ, Player, {}) ->
    Player2 = copy_single_api:get_vip_reward(Player),
    {?ok, Player2};

%% 请求背包是否有5个空位
handler(?MSG_ID_COPY_SINGLE_IS_EMPTY_5, Player, {}) ->
    Bag = Player#player.bag,
    {?ok, Empty} = ctn_bag2_api:empty_count(Bag),
    Packet = 
        if
            Empty < ?CONST_COPY_SINGLE_BAG_MIN -> 
                copy_single_api:msg_sc_empty(?CONST_SYS_FALSE);
            ?true ->
                copy_single_api:msg_sc_empty(?CONST_SYS_TRUE)
        end,
    UserId = Player#player.user_id,
    misc_packet:send(UserId, Packet),
    ?ok;

%% 重置精英副本次数
handler(?MSG_ID_COPY_SINGLE_CS_RESET_ELITE, Player, {SerialId}) ->
    Player2 = 
		case player_state_api:is_raiding(Player#player.user_id) of
			?true ->
				Packet = message_api:msg_notice(?TIP_COMMON_NOT_4_RAIDING),
				misc_packet:send(Player#player.user_id, Packet);
			?false ->
				copy_single_api:reset_serial_times(Player, SerialId)
		end,
    {?ok, Player2};

%% 请求精英副本扫荡信息
handler(?MSG_ID_COPY_SINGLE_CS_ELITE_INFO, Player, {SerialId}) ->
    UserId 		= player_api:get_user_id(Player),
	InfoPacket		=
    case copy_single_elite_raid_api:get_info(Player, SerialId) of
        {?ok, Packet} ->
            Packet;
        {?error, _ErrorCode, PacketError} ->
            PacketError
    end,
	Type    	= ?CONST_ELITECOPY_AUTO_TURNCARD_ELITECOPY,
	Flag		= copy_single_api:get_auto_turn_card(UserId, Type),
	AutoPacket	= copy_single_api:msg_sc_auto_turncard(Type, Flag),
	misc_packet:send(UserId, <<InfoPacket/binary, AutoPacket/binary>>),
    ?ok;

%% 开始精英副本扫荡
handler(?MSG_ID_COPY_SINGLE_CS_START_ELITE, Player, {SerialId}) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_SINGLE_COPY) of
		{?true, _NewPlayer} ->
			{_,Player2} = player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
			UserId = player_api:get_user_id(Player2),
		    case copy_single_elite_raid_api:start_raid(Player2, SerialId) of
		        {?ok, PacketStart} ->
		            misc_packet:send(UserId, PacketStart),
					% 增加活跃度
					{?ok, Player3} = schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_ELITE_COPY),
					{?ok, Player3};
		        {?error, _ErrorCode, PacketError} ->
		            misc_packet:send(UserId, PacketError),
					{?ok, Player2}
		    end;
		{?false, Player, Tips} ->
			TipPacket 		= message_api:msg_notice(Tips),
			misc_packet:send(Player#player.net_pid, TipPacket),
			?error
	end;

%% 请求扫荡自动翻牌
handler(?MSG_ID_COPY_SINGLE_CS_AUTO_TURNCARD, Player, {Type, Flag}) ->
	copy_single_api:auto_turn_card(Player, Type, Flag),
	?ok;

%% 请求副本战报信息
handler(?MSG_ID_COPY_SINGLE_CS_REPORT_LIST, Player, {CopyId}) ->
    UserId = Player#player.user_id,
    Packet = copy_single_report_api:list_all(CopyId),
    misc_packet:send(UserId, Packet),
    ?ok;

%% 步骤完成
handler(?MSG_ID_COPY_SINGLE_CS_STEP_OK, Player, {Step, IsLvup}) ->
    Info = Player#player.info,
    OldStep = Info#info.is_newbie,
    if
        OldStep =< Step andalso 0 =< OldStep ->
            if
                1 =:= IsLvup ->
                    copy_single_newbie_api:lvup(Player, Step);
                ?true ->
                    copy_single_newbie_api:update_step(Player, Step)
            end;
        ?true ->
            ok
    end;

handler(_MsgId, _Player, _Datas) -> ?undefined.
%%
%% Local Functions
%%
