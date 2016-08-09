%% Author: Administrator
%% Created: 2013-4-8
%% Description: TODO: Add description to bless_api
-module(bless_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([
		 initial_ets/0,
		 login/1,logout/1,
		 send_be_blessed/3,
		 send_vip_blessed/3,
		 login_packet/2
		 ]).

-export([
		 msg_sc_bless/2,
		 msg_battle_info/3,
		 msg_sc_battle_data/2,
		 msg_sc_bless_data/11
		 ]).

%%
%% API Functions
%%

% 初始化祝福数据
initial_ets() ->      
	bless_db_mod:select_data().

login_packet(Player = #player{sys_rank = Sys,user_id = UserId}, OldPacket) -> 
	case Sys >= data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP) of
        true ->
        	{?ok,BlessUser} = bless_mod:ets_bless_user(UserId),
			case BlessUser#bless_user.flag of
				?CONST_SYS_FALSE ->
					Packet14818		= msg_battle_info(?CONST_SYS_FALSE,BlessUser#bless_user.exp,BlessUser#bless_user.count),
					{Player,<<OldPacket/binary,Packet14818/binary>>};
				_ ->
                    Packet14818     = msg_battle_info(?CONST_SYS_TRUE,0,0),
					{Player,<<OldPacket/binary,Packet14818/binary>>}
			end;
        false ->
            {Player,OldPacket}
    end.
	

send_vip_blessed(Player, Vip1, Vip2) when Vip1 =< Vip2 ->
    send_be_blessed(Player, ?CONST_RELATIONSHIP_BTYPE_VIPLV, Vip1),
    send_vip_blessed(Player, Vip1+1, Vip2);
send_vip_blessed(_Player, _Vip1, _Vip2) ->
    ?ok.

send_be_blessed(UserId, Type, Value) when is_number(UserId) ->
    case player_api:get_player_fields(UserId, [#player.info,#player.sys_rank]) of
        {?ok, [Info,Sys]} ->
            bless_mod:broadcast_bless(UserId,Info,Sys, Type, Value);
        _ ->
            ?ok
    end;
send_be_blessed(#player{user_id = UserId,info = Info,sys_rank = Sys}, Type, Value)->
	bless_mod:broadcast_bless(UserId,Info,Sys, Type, Value);
send_be_blessed(_, _, _) -> ?ok.

login(Player) ->
	Player.

logout(Player = #player{sys_rank = Sys,user_id = UserId}) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP) of
        true ->
        	{?ok,BlessInfo} = bless_mod:ets_bless_info(UserId),
        	BlessInfo2		= BlessInfo#bless_info{send_list = [],
        									  	   recv_list = []},
        	bless_mod:insert_bless_info(BlessInfo2),
        	Player;
        false ->
            Player
    end.
%% 经验瓶信息
%%[Flag,Exp,Count]
msg_battle_info(Flag,Exp,Count) ->
	misc_packet:pack(?MSG_ID_BLESS_BATTLE_INFO, ?MSG_FORMAT_BLESS_BATTLE_INFO, [Flag,Exp,Count]).
%% 祝福/被祝福获得经验  
%%[Type,Exp]
msg_sc_bless(Type,Exp) ->
	misc_packet:pack(?MSG_ID_BLESS_SC_BLESS, ?MSG_FORMAT_BLESS_SC_BLESS, [Type,Exp]).
%% 经验瓶信息
%%[Exp,Count]
msg_sc_battle_data(Exp,Count) ->
	misc_packet:pack(?MSG_ID_BLESS_SC_BATTLE_DATA, ?MSG_FORMAT_BLESS_SC_BATTLE_DATA, [Exp,Count]).
%% 祝福信息
%%[Type,UserId,UserName,Pro,Sex,Lv,BlessType,BlessId,Value,Time]
msg_sc_bless_data(Type,UserId,UserName,Pro,Sex,Lv,BlessType,BlessId,Value2,Time,Exp) ->
	Value = misc:to_binary(Value2),
	misc_packet:pack(?MSG_ID_BLESS_SC_BLESS_DATA, ?MSG_FORMAT_BLESS_SC_BLESS_DATA, [Type,UserId,UserName,Pro,Sex,Lv,
																					BlessType,BlessId,Value,Time,Exp]).

