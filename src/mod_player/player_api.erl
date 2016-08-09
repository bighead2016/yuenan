%% 玩家属性变化等接口
-module(player_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([process_send/4, process_call/4, progress_receive/3, force2offline/2]).			% 系统接口
-export([insert_player_offline/1, delete_player_offline/1, lookup_player_offline/1, handle_zero_oclock1/0]).	% 离线ETS角色数据操作接口
-export([
		 get_player_first/1,
		 get_player_field/2,
		 get_player_fields/2,
         lookup_account_2/2,
		 insert_name/1, insert_name/2,
		 insert_account/1, insert_account/2,
		 insert_ip/1, delete_ip/1,
         get_skill_point/1,
         delete_player_online/1,
         get_is_can_get_test_server_award/1,
         get_test_server_award/1,
         immigrant/2,
         immigrant/3,
         lookup_account_user_id/1,
         check_account_player/2,
         insert_account_2/1,
         get_test_server_info/1,
         insert_account_2/3,
         insert_account_user_id/2
		]).            % 获取玩家数据接口

-export([hp/2, exp/2, vip/2, check_plus_exp/2, % 属性接口
		 plus_honour/2, minus_honour/2,
		 plus_sp/3, minus_sp/3, plus_sp/2, sp_cb/2, minus_sp/2, sp_offline/1,
		 plus_meritorious/3, minus_meritorious/3, plus_meritorious/2, minus_meritorious/2,
		 plus_exploit/3, minus_exploit/3,
		 plus_skill_point/2, minus_skill_point/2, level_up_plus_skill_point/1,
%% 		 plus_anger/2, minus_anger/2,
		 plus_buy_point/2,minus_buy_point/2,
		 plus_experience/2, minus_experience/2, plus_experience_cb/2, add_experience/2,
         plus_cultivation/2, minus_cultivation/2,
		 plus_see/2, minus_see/2]).
-export([login/1, login_packet/2, logout/1, initial_ets/0, do_when_update_net/1,
		 handle_five_minutes/0,
		 handle_zero_oclock/0, handle_zero_oclock_cb/2, refresh_cb/2, clear_player_off_zero/0, is_level_35/1]). % 登陆相关
-export([check_online/1, check_sp/2, check_name/1, get_name/1, get_level/1]).                  % 校验
-export([tick/1, upgrate_to_gm/1, downgrate_to_normal/1, is_gm/1]).            % gm
-export([buy_sp/1, read_player_level/2, get_sp_max/2, 
         calc_sp_cash/1, get_user_info_by_id/1, 
		 player_online_data/1,
		 get_user_id/1, get_user_id_by_name/1, get_user_id_by_account/1,
		 get_player_pid/1, get_vip_lv/1, insert_gm_msg/3]).
%% -export([get_trained_rand/4, trained_cost/5, player_trained/2,         % 培养
%% 		 player_trained_save/1, player_trained_cancel/1, get_max_train/2]).            
-export([msg_player_login_ok/3, msg_player_login_error/1,              % 协议
		 msg_player_create_ok/0, msg_player_create_error/1,
		 msg_sc_reconnect_success/1,
		 msg_sc_reconnect_fail/0,
		 msg_player_data_info/3, msg_attr_change/3,
		 msg_player_sc_update_money/1,
         msg_sc_test_server/0,
		 
		 msg_player_attr_update/3,
		 msg_player_attr_update_str/2,
		 msg_player_sc_vip_info/2,
		 msg_player_sc_upgrade/1,
		 msg_player_sc_position_info/1,
		 msg_sc_hide_skin_info/2,
		 msg_sc_fcm_notice/3,
		 msg_sc_get_gift_info/1,
		 msg_sc_fcm_submit_info/1,
		 msg_sc_fcm_offline_notice/0,
		 msg_player_sc_tsp/1,
		 msg_player_repeat_login/0,
		 msg_attr/1,
         
         msg_sc_buy_sp_info/2,
         msg_sc_buff_delete/2,
         msg_sc_buff_info/1, 
         msg_sc_buff_insert/4,
         msg_sc_open_sys_notice/1,
         msg_sc_open_sys_info/1,
		 msg_sc_gift_vip_info/1,
		 msg_player_sc_vip_daily_info/1,
		 msg_player_sc_open_culti/1,
		 msg_sc_illegal_notice/0,
         msg_sc_not_enough_sp/0,
         msg_sc_culti_now/1,
         msg_is_ok/1,
         msg_sc_change_name_flags/2,
         msg_sc_newbie_step/1,
		 msg_sc_arena_rank/2,
         msg_sc_world_lv/1
		]).

-export([user_ban/2, user_unban/1, user_chat_ban/2, user_chat_unban/1, 
		 all_user_online/0, user_state_db/2,
		 ban_user_list/0, player_lv/1, total_online/0, first_consume/2,
		 get_reg_time/1]).   % 统计相关
-export([clear_log_ndays_ago/2, change_username/2, change_username/3, delete_name/1, change_pro/2]). % 杂项


%%
%% API Functions
%%

%% 加减Hp
%% return: Player
hp(Player, DeltaHp)  ->
	HpCur  = get_hp(Player),
	HpMax  = get_hp_max(Player),
	UserId = get_user_id(Player),
    case set_up_value(UserId, HpCur, DeltaHp, 1, HpMax, ?CONST_PLAYER_ATTR_HP) of
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, ErrorCode};
        NewHp ->
            Player2 = set_hp(Player, NewHp),
            {?ok, Player2}
    end.

%% 体验服信息
get_test_server_info(Player) ->
    UserId = Player#player.user_id,
    Money  = ets_api:lookup(?CONST_ETS_PLAYER_MONEY, UserId),
    CashSum  = Money#money.cash_sum,
    GiveCash = round(CashSum * 1.2),

    StartSecond = 
        case config:read_deep([server, release, start_time]) of
            ?null -> 0;
            StartTime -> misc:date_time_to_stamp(StartTime)
        end,
    NextSecond = 
        case config:read_deep([server, release, next_start_time]) of
            ?null -> 0;
            NextTime -> misc:date_time_to_stamp(NextTime)
        end,
    EndSecond = 
        case config:read_deep([server, release, close_time]) of
            ?null -> 0;
            EndTime -> misc:date_time_to_stamp(EndTime)
        end,
    if
        0 =< StartSecond ->
            Packet      = msg_sc_test_server_info(StartSecond, EndSecond, NextSecond, CashSum, GiveCash),
            misc_packet:send(UserId, Packet);
        ?true ->
            ?ok
    end.

%%===========================sp======================================================
%% 加减Sp
%% return: {?ok, Player}
%% player_api:process_send(2568, player_api, plus_sp, 200).
plus_sp(Player, DeltaSp) ->
%% 	?MSG_ERROR("Stack:~p", [erlang:get_stacktrace()]),
	plus_sp(Player, DeltaSp, 0).
plus_sp(Player, DeltaSp, Point) ->
	SpCur  = get_sp(Player),
	SpMax  = ?CONST_PLAYER_SP_MAX_LIMIT, %get_sp_max(Player),
	UserId = get_user_id(Player),
    case set_up_value(UserId, SpCur, DeltaSp, 1, SpMax, ?CONST_PLAYER_ATTR_SP) of
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, Packet),
            {?ok, Player};
        NewSp ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, NewSp - SpCur, NewSp, ?CONST_PLAYER_ATTR_SP),
			Player2	= set_sp(Player, NewSp),
			{?ok, Player2}
    end.

check_sp(Player, Sp) -> % 检查sp ?true/?false
    SpPlayer	= (Player#player.info)#info.sp,
    if
        SpPlayer >= Sp -> ?true;
        ?true -> ?false
    end.
minus_sp(Player, Sp) ->
	minus_sp(Player, Sp, 0).
minus_sp(Player = #player{user_id = UserId, info = Info = #info{sp = SpOld}}, Sp, Point) when Sp > 0 ->
    if
        SpOld >= Sp ->
            SpNew		= misc:floor(SpOld - Sp),
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Sp, SpNew, ?CONST_PLAYER_ATTR_SP),
			Player2		= Player#player{info = Info#info{sp = SpNew}},
            PacketSp	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_SP, SpNew),
            misc_packet:send(UserId, PacketSp),
            {?ok, Player2};
        ?true ->
            {?error, ?TIP_PLAYER_NOT_ENOUGH_SP}
    end;
minus_sp(Player, _Sp, _Point) -> 
    {?ok, Player}.

%%====================================exp=============================================
%% 加减经验Exp
%% {?ok, Player}
%% player_api:process_send(75, player_api, exp, 100000).
exp(Player, Exp) when Exp > 0 ->
	{
	 Player2,
	 ExpAcc
	} 			= player_mod:level_up(Player, Exp, 0),
    ExpCur      = (Player2#player.info)#info.exp,
    {PlayerNew, PacketTotal} = 
        if
            ExpAcc > 0 ->
				Info		= Player2#player.info,
				Info2		= Info#info{exp_time = misc:seconds()},
    	       	Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXP, ExpCur),
    	       	Packet2		= message_api:msg_reward_add_exp(Exp),
    	       {Player2#player{info = Info2}, <<Packet/binary,Packet2/binary>>};
            ?true ->
            	P = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_EXP),
                {Player, P}
        end,
    misc_packet:send(Player#player.user_id, PacketTotal),
	{?ok, PlayerNew};
exp(Player, _Exp) -> {?ok, Player}.

%%====================================vip=============================================
%% 设置vip
%% {?ok, Player}
%% player_api:vip(Player, Vip).
%% player_api:process_send(400008, player_api, vip, 7).
vip(Player, Vip)  ->
	VipCur  = get_vip_lv(Player),
	UserId  = get_user_id(Player),
	NewVip  = set_to_value(UserId, VipCur, Vip, ?CONST_SYS_MIN_VIP_LV, ?CONST_SYS_MAX_VIP_LV, ?CONST_PLAYER_ATTR_VIP_LV),
	Player2 = set_vip_lv(Player, NewVip),
	Player3	= welfare_api:vip(Player2),
	Player4 = furnace_stren_api:vip(Player3),
	resource_api:vip(Player4),
    bless_api:send_vip_blessed(Player4, VipCur+1, NewVip),
	map_api:change_vip(Player4),
    weapon_api:vip(Player4),
	single_arena_api:vip(Player4),
	
    % 加体力
    Player5 = update_vip_sp(Player4, VipCur, NewVip),
	Lv		= (Player#player.info)#info.lv,
	{?ok, Player6} = 
		case Vip > 0 of
			?true ->
				new_serv_api:finish_achieve(Player5, ?CONST_NEW_SERV_VIP_LEVEL_UP, Lv, 1);
			?false ->
				{?ok, Player5}
		end,
	{?ok, Player6}.

update_vip_sp(Player, OldVip, NewVip) ->
    OldSpLimit = player_vip_api:get_sp_limit(OldVip),
    NewSpLimit = player_vip_api:get_sp_limit(NewVip),
    {?ok, Player2} = plus_sp(Player, NewSpLimit - OldSpLimit),
    Packet = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_SP_LIMIT, NewSpLimit),
    misc_packet:send(Player2#player.user_id, Packet),
    Player2.

%%====================================honour=============================================
%% 加荣誉(原：成就点)
%% Player
plus_honour(Player, Honour) ->
	HonourCur = get_honour(Player),
	UserId    = get_user_id(Player),
    case set_up_value(UserId, HonourCur, Honour, 0, ?CONST_SYS_MAX_HONOUR, ?CONST_PLAYER_ATTR_HONOUR) of
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, ErrorCode};
        NewHonour ->
            Player2 = set_honour(Player, NewHonour),
            {?ok, Player2}
    end.

%% 减荣誉(原：成就点)
%% {?error, ErrorCode}/{?ok, Player}
minus_honour(Player, Honour) ->
	HonourCur = get_honour(Player),
	UserId    = get_user_id(Player),
	case set_up_value(UserId, HonourCur, -Honour, 0, ?CONST_SYS_MAX_HONOUR, ?CONST_PLAYER_ATTR_HONOUR) of
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, Packet),
			{?error, ErrorCode};
		NewHonour ->
			Player2 = set_honour(Player, NewHonour),
			{?ok, Player2}
	end.
%%====================================功勋=============================================
%% 加功勋(原：阅历/历练)
plus_meritorious(Player, Meritorious) ->
%% 	?MSG_ERROR("Stack:~p", [erlang:get_stacktrace()]),
	plus_meritorious(Player, Meritorious, 0).
plus_meritorious(Player, Meritorious, Point)
  when Meritorious > 0 andalso Meritorious =< ?CONST_SYS_MAX_MERITORIOUS ->
	Info 	 		= Player#player.info,
	MeritoriousOld	= Info#info.meritorious,
	MeritorioustOld	= Info#info.meritorioust,
	MeritoriousNew	= misc:floor(MeritoriousOld + Meritorious),
	MeritorioustNew	= misc:floor(MeritorioustOld + Meritorious),
	if
		MeritoriousNew < ?CONST_SYS_MAX_MERITORIOUS andalso MeritorioustNew < ?CONST_SYS_MAX_MERITORIOUS ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Meritorious, MeritoriousNew, ?CONST_PLAYER_ATTR_MERITORIOUS),
			Packet     		= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MERITORIOUS, MeritoriousNew),
			Packet_2   		= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_TOTAL_MERITORIOUS, MeritorioustNew),
			Packet2			= message_api:msg_reward_add_meritorious(Meritorious),
			Packet3			= msg_player_sc_position_info(MeritorioustNew),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary, Packet3/binary, Packet_2/binary>>),
			Player2			= Player#player{info = Info#info{meritorious  = MeritoriousNew, meritorioust = MeritorioustNew}},
			{?ok, Player2};
%% 			player_position_api:upgrade(Player2);
		MeritoriousNew =:= ?CONST_SYS_MAX_MERITORIOUS orelse MeritorioustNew =:= ?CONST_SYS_MAX_MERITORIOUS ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Meritorious, MeritoriousNew, ?CONST_PLAYER_ATTR_MERITORIOUS),
			Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MERITORIOUS, MeritoriousNew),
            Packet_2        = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_TOTAL_MERITORIOUS, MeritorioustNew),
			Packet2         = message_api:msg_reward_add_meritorious(Meritorious),
			Packet3			= msg_player_sc_position_info(MeritorioustNew),
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_MERITORIOUS),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary, Packet3/binary, PacketErr/binary, Packet_2/binary>>),
			Player2         = Player#player{info = Info#info{meritorious  = MeritoriousNew, meritorioust = MeritorioustNew}},
			{?ok, Player2};
%% 			player_position_api:upgrade(Player2);
		MeritoriousOld < ?CONST_SYS_MAX_MERITORIOUS andalso MeritorioustOld < ?CONST_SYS_MAX_MERITORIOUS ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Meritorious, MeritoriousNew, ?CONST_PLAYER_ATTR_MERITORIOUS),
			Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_MERITORIOUS, ?CONST_SYS_MAX_MERITORIOUS),
            Packet_2        = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_TOTAL_MERITORIOUS, MeritorioustNew),
			Packet2         = message_api:msg_reward_add_meritorious(Meritorious),
			Packet3			= msg_player_sc_position_info(MeritorioustNew),
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_MERITORIOUS),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary, Packet3/binary, PacketErr/binary, Packet_2/binary>>),
			Player2         = Player#player{info = Info#info{meritorious  = MeritoriousNew, meritorioust = MeritorioustNew}},
			{?ok, Player2};
%% 			player_position_api:upgrade(Player2);
		?true ->
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_MERITORIOUS),
			misc_packet:send(Player#player.user_id, PacketErr),
			{?ok, Player}
	end;
plus_meritorious(Player, Meritorious, _Point) when Meritorious > 0 -> 
    UserId = Player#player.user_id,
    Packet = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_MERITORIOUS),
    misc_packet:send(UserId, Packet),
    {?ok, Player};

plus_meritorious(Player, _Meritorious, _Point) -> {?ok, Player}.

%% 减功勋(原：阅历/历练)
minus_meritorious(Player, Meritorious) ->
	?MSG_ERROR("Stack:~p", [erlang:get_stacktrace()]),
	minus_meritorious(Player, Meritorious, 0).
minus_meritorious(Player, Meritorious, Point) ->
	MeritoriousCur	= get_meritorious(Player),
	UserId    		= get_user_id(Player),
	case set_up_value(UserId, MeritoriousCur, - Meritorious, 0, ?CONST_SYS_MAX_MERITORIOUS, ?CONST_PLAYER_ATTR_MERITORIOUS) of
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, Packet),
			{?error, ErrorCode};
		NewMeritorious ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_MINUS_CURRENCY, Point, NewMeritorious - Meritorious, NewMeritorious, ?CONST_PLAYER_ATTR_MERITORIOUS),
			Player2 = set_meritorious(Player, NewMeritorious),
			{?ok, Player2}
	end.

%% plus_meritorious_cb(Player, [MeritoriousAdd, Point]) ->
%%     Info    = Player#player.info,
%%     case Info of
%%         Info when is_record(Info, info) ->
%% 			plus_meritorious(Player, MeritoriousAdd, Point);
%%         _ -> {?ok, Player}
%%     end.
%%====================================军团贡献度=============================================
%% 加军团贡献度
plus_exploit(Player, Exploit, Point) when Exploit > 0 ->
	Info 	 	= Player#player.info,
	ExploitOld	= Info#info.exploit,
	ExploitNew	= misc:floor(ExploitOld + Exploit),
	if
		ExploitNew < ?CONST_SYS_MAX_EXPLOIT ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Exploit, ExploitNew, ?CONST_PLAYER_ATTR_EXPLOIT),
			Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXPLOIT, ExploitNew),
			Packet2         = message_api:msg_reward_add_exploit(Exploit),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
			
			Player2     = Player#player{info = Info#info{exploit = ExploitNew}},
			if
				ExploitNew >= 50000 ->
					achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_CONTRIBUTION, 0, 1);%% 成就
				?true -> {?ok, Player2}
			end;
		ExploitNew =:= ?CONST_SYS_MAX_EXPLOIT ->
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Exploit, ExploitNew, ?CONST_PLAYER_ATTR_EXPLOIT),
			Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXPLOIT, ExploitNew),
			Packet2         = message_api:msg_reward_add_exploit(Exploit),
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_EXPLOIT),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary, PacketErr/binary>>),
			
			Player2     = Player#player{info = Info#info{exploit = ExploitNew}},
			if
				ExploitNew >= 50000 ->
					achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_CONTRIBUTION, 0, 1);%% 成就
				?true -> {?ok, Player2}
			end;
		ExploitOld < ?CONST_SYS_MAX_EXPLOIT ->
			ExploitNew2     = ?CONST_SYS_MAX_EXPLOIT,
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_PLUS_CURRENCY, Point, ?CONST_SYS_MAX_EXPLOIT - ExploitOld, ExploitNew2, ?CONST_PLAYER_ATTR_EXPLOIT),
			Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXPLOIT, ExploitNew2),
			Packet2         = message_api:msg_reward_add_exploit(Exploit),
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_EXPLOIT),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary, PacketErr/binary>>),
			
			Player2         = Player#player{info = Info#info{exploit = ExploitNew2}},
			achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_CONTRIBUTION, 0, 1);%% 成就
		?true ->
			PacketErr       = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_EXPLOIT),
			misc_packet:send(Player#player.user_id, PacketErr),
			{?ok, Player}
	end;
plus_exploit(Player, _Exploit, _Point) -> {?ok, Player}.
%% 减军团贡献度
minus_exploit(Player, Exploit, Point) when Exploit > 0 ->
	Info 	 	= Player#player.info,
	ExploitOld	= Info#info.exploit,
	if
		ExploitOld >= Exploit ->
			ExploitNew	= misc:floor(ExploitOld - Exploit),
			admin_log_api:log_currency(Player, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Exploit, ExploitNew, ?CONST_PLAYER_ATTR_EXPLOIT),
			Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXPLOIT, ExploitNew),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player#player{info = Info#info{exploit = ExploitNew}}};
		?true ->
			{?error, ?TIP_GUILD_NO_EXPLOIT}
	end;
minus_exploit(_Player, _Exploit, _Point) -> {?error, ?TIP_GUILD_NO_EXPLOIT}.

%%====================================技能点=============================================
%% 角色升级加技能点
level_up_plus_skill_point(Player) ->
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Lv              = Info#info.lv,
    PlayerLevel     = data_player:get_player_level({Pro, Lv}),
	plus_skill_point(Player, PlayerLevel#player_level.skill_point).

%% 加武魂(原：技能点
plus_skill_point(Player, 0) -> Player;
plus_skill_point(Player, SkillPoint) ->
	SkillPointCur = get_skill_point(Player),
	UserId        = get_user_id(Player),
	case set_up_value(UserId, SkillPointCur, SkillPoint, 0, ?CONST_SYS_MAX_SKILL_POINT, ?CONST_PLAYER_ATTR_SKILL_POINT) of
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, Packet),
			Player;
		NewSkillPoint ->
			set_skill_point(Player, NewSkillPoint)
	end.

%% 减武魂(原：技能点
minus_skill_point(Player, SkillPoint) ->
	SkillPointCur = get_skill_point(Player),
	UserId        = get_user_id(Player),
	case set_up_value(UserId, SkillPointCur, -SkillPoint, 0, ?CONST_SYS_MAX_SKILL_POINT, ?CONST_PLAYER_ATTR_SKILL_POINT) of
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, Packet),
			{?error, ErrorCode};
		NewSkillPoint ->
			Player2 = set_skill_point(Player, NewSkillPoint),
            {?ok, Player2}
	end.

%%====================================怒气=============================================
%% %% 加怒气
%% plus_anger(Player, Anger) when Anger > 0 ->
%% 	Info 	 	= Player#player.info,
%% 	AngerOld	= Info#info.anger,
%% 	AngerNew	= misc:floor(AngerOld + Anger),
%% 	Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_ANGER, AngerNew),
%% 	misc_packet:send(Player#player.user_id, Packet),
%% 	Player#player{info = Info#info{anger = AngerNew}};
%% plus_anger(Player, _) -> Player.
%% %% 减怒气
%% minus_anger(Player, Anger) when Anger > 0 ->
%% 	Info 	 	= Player#player.info,
%% 	AngerOld	= Info#info.anger,
%% 	if
%% 		AngerOld >= Anger ->
%% 			AngerNew	= misc:floor(AngerOld - Anger),
%% 			Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_ANGER, AngerNew),
%% 			misc_packet:send(Player#player.user_id, Packet),
%% 			{?ok, Player#player{info = Info#info{anger = AngerNew}}};
%% 		?true ->
%% 			{?error, ?TIP_COMMON_ANGER_NOT_ENOUGHT}
%% 	end;
%% minus_anger(_Player, _) -> {?error, ?TIP_COMMON_ANGER_NOT_ENOUGHT}.

%%====================================修为=============================================
%% 加修为
plus_cultivation(Player, Point) when Point > 0 ->
    Info            = Player#player.info,
    PointOld        = Info#info.cultivation,
    PointNew        = misc:floor(PointOld + Point),
    Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CULTIVATION, PointNew),
    misc_packet:send(Player#player.user_id, Packet),
    Player#player{info = Info#info{cultivation = PointNew}};
plus_cultivation(Player, _) -> 
    Info            = Player#player.info,
    PointOld        = Info#info.cultivation,
    Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CULTIVATION, PointOld),
    Packet2         = msg_sc_culti_now(PointOld),
    misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
    Player.
%% 减修为
minus_cultivation(Player, Point) when Point > 0 ->
    Info            = Player#player.info,
    PointOld        = Info#info.cultivation,
    if
        PointOld >= Point ->
            PointNew   = misc:floor(PointOld - Point),
            Packet          = msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CULTIVATION, PointNew),
            Packet2         = msg_sc_culti_now(PointNew),
            misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
            {?ok, Player#player{info = Info#info{cultivation = PointNew}}};
        ?true ->
            {?error, ?TIP_COMMON_CULTIVATION_NOT_ENOUGH}
    end;
minus_cultivation(_Player, _) -> {?error, ?TIP_COMMON_BAD_ARG}.

%%====================================购买积分=============================================
%% 加购买积分 backup
plus_buy_point(Player, Point) when Point > 0 ->
	Info 	 	= Player#player.info,
	PointOld	= Info#info.buy_point,
	PointNew	= misc:floor(PointOld + Point),
 	Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_BUY_POINT, PointNew),
 	misc_packet:send(Player#player.user_id, Packet),
	Player#player{info = Info#info{buy_point = PointNew}};
plus_buy_point(Player, _) -> Player.
%% 减购买积分
minus_buy_point(Player, Point) when Point > 0 ->
	Info 	 	= Player#player.info,
	PointOld	= Info#info.buy_point,
	if
		PointOld >= Point ->
			PointNew	= misc:floor(PointOld - Point),
			Packet     	= msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_BUY_POINT, PointNew),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player#player{info = Info#info{buy_point = PointNew}}};
		?true ->
			{?error, ?TIP_COMMON_BUY_POINT_NOT_ENOUGH}
	end;
minus_buy_point(_Player, _) -> {?error, ?TIP_COMMON_BUY_POINT_NOT_ENOUGH}.

%%====================================历练=============================================
%% 增加历练(返回{ok, Player})
add_experience(Player, Value) ->
	Player2 = plus_experience(Player, Value),
	{?ok, Player2}.

%% 增加历练

plus_experience(Player, _Value) ->
    Player.
%%     Info          = Player#player.info,
%%     ExperienceOld = Info#info.experience,
%%     UserId        = get_user_id(Player),
%%     case set_up_value(UserId, ExperienceOld, Value, 0, ?CONST_SYS_MAX_EXPERIENCE, ?CONST_PLAYER_EXPERIENCE) of
%%         {?error, ErrorCode} ->
%%             Packet = message_api:msg_notice(ErrorCode),
%%             misc_packet:send(UserId, Packet),
%%             Player;
%%         ExperienceNew ->
%%             Player#player{info = Info#info{experience = ExperienceNew}}
%%     end.

%% 减历练
minus_experience(Player, _Value) ->
    Player.
%%     ExperienceOld   = get_experience(Player),
%%     UserId          = get_user_id(Player),
%%     case set_up_value(UserId, ExperienceOld, -Value, 0, ?CONST_SYS_MAX_EXPERIENCE, ?CONST_PLAYER_EXPERIENCE) of
%%         {?error, ErrorCode} ->
%%             Packet = message_api:msg_notice(ErrorCode),
%%             misc_packet:send(UserId, Packet),
%%             {?error, ErrorCode};
%%         ExperienceNew ->
%%             Player2 = set_experience(Player, ExperienceNew),
%%             {?ok, Player2}
%%     end.

%%====================================阅历=============================================
%% 增加阅历(返回{ok, Player})
plus_see(Player, Value) ->
    Info          = Player#player.info,
    SeeOld 		  = Info#info.see,
    UserId        = get_user_id(Player),
    case set_up_value(UserId, SeeOld, Value, 0, ?CONST_SYS_MAX_SEE, ?CONST_PLAYER_SEE) of
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?ok, Player};
        SeeNew ->
            {?ok, Player#player{info = Info#info{see = SeeNew}}}
    end.

%% 减阅历
minus_see(Player, Value) ->
    SeeOld   = get_see(Player),
    UserId          = get_user_id(Player),
    case set_up_value(UserId, SeeOld, -Value, 0, ?CONST_SYS_MAX_SEE, ?CONST_PLAYER_SEE) of
        {?error, ErrorCode} ->
%%             Packet = message_api:msg_notice(ErrorCode),
%%             misc_packet:send(UserId, Packet),
            {?error, ErrorCode};
        SeeNew ->
            Player2 = set_see(Player, SeeNew),
            {?ok, Player2}
    end.

%%===================================属性变化处理函数====================================================
%% player的整数化规则
integerized(Value) when is_number(Value) andalso 0 < Value ->
	misc:round(Value);
integerized(Value) when is_number(Value) ->
	Value;
integerized(_Value) ->
	0.

%% 设置属性值，变动后向前端发消息
set_up_value(_UserId, OldValue, 0, _Min, _Max, _Type) -> OldValue;
set_up_value(_UserId, Max, DeltaValue, _Min, Max, Type) when 0 < DeltaValue -> % 原先已经是最大值了，还要加正值
	ErrorCode 		= get_max_msg(Type),
	{?error, ErrorCode};
set_up_value(UserId, OldValue, DeltaValue, Min, Max, Type) when 0 < DeltaValue ->
	Value2          = integerized(OldValue + DeltaValue),
	{NewValue, Msg} = between(Value2, Min, Max, Type),
	send_changed(UserId, Type, OldValue, NewValue, Msg),
	NewValue;
set_up_value(UserId, OldValue, DeltaValue, Min, Max, Type) when -DeltaValue =< OldValue andalso DeltaValue < 0 ->
	Value2          = integerized(OldValue + DeltaValue),
    {NewValue, Msg} = between(Value2, Min, Max, Type),
    send_changed(UserId, Type, OldValue, NewValue, Msg),
    NewValue;
set_up_value(_, _, _, _, _, Type) ->
	ErrorCode 		= get_not_enough_err(Type),
	{?error, ErrorCode}.

%% 属性点不足的提示
get_not_enough_err(?CONST_PLAYER_ATTR_HP)          -> ?TIP_COMMON_BAD_ARG;
get_not_enough_err(?CONST_PLAYER_ATTR_SP)          -> ?TIP_COMMON_SP_NOT_ENOUGH;
get_not_enough_err(?CONST_PLAYER_ATTR_HONOUR)      -> ?TIP_COMMON_HONOUR_NOT_ENOUGH;
get_not_enough_err(?CONST_PLAYER_ATTR_MERITORIOUS) -> ?TIP_COMMON_MERITORIOUS_NOT_ENOUGH;
get_not_enough_err(?CONST_PLAYER_ATTR_SKILL_POINT) -> ?TIP_SKILL_POINT_NOT_ENOUGH;
get_not_enough_err(?CONST_PLAYER_EXPERIENCE)       -> ?TIP_COMMON_EXPERIENCE_NOT_ENOUGH;
get_not_enough_err(?CONST_PLAYER_ATTR_EXPLOIT)     -> ?TIP_GUILD_NO_EXPLOIT;
get_not_enough_err(_) -> ?TIP_COMMON_BAD_ARG.

%% 属性点太多的提示
get_max_msg(?CONST_PLAYER_ATTR_HONOUR)      -> ?TIP_COMMON_BAD_ARG;
get_max_msg(?CONST_PLAYER_ATTR_SP)          -> ?TIP_COMMON_SP_IS_ENOUGH;
get_max_msg(?CONST_PLAYER_ATTR_MERITORIOUS) -> ?TIP_COMMON_TOO_MUCH_MERITORIOUS;
get_max_msg(?CONST_PLAYER_ATTR_SKILL_POINT) -> ?TIP_COMMON_TOO_MUCH_SKILL_POINT;
get_max_msg(?CONST_PLAYER_EXPERIENCE)       -> ?TIP_COMMON_TOO_MUCH_EXPERIENCE;
get_max_msg(?CONST_PLAYER_ATTR_EXPLOIT)     -> ?TIP_COMMON_TOO_MUCH_EXPLOIT;
get_max_msg(_) -> ?TIP_COMMON_BAD_ARG. 

%% 属性点太少的提示
get_min_msg(?CONST_PLAYER_ATTR_HP)          -> ?TIP_COMMON_BAD_ARG;
get_min_msg(?CONST_PLAYER_ATTR_SP)          -> ?TIP_COMMON_SP_NOT_ENOUGH;
get_min_msg(?CONST_PLAYER_ATTR_HONOUR)      -> ?TIP_COMMON_HONOUR_NOT_ENOUGH;
get_min_msg(?CONST_PLAYER_ATTR_MERITORIOUS) -> ?TIP_COMMON_MERITORIOUS_NOT_ENOUGH;
get_min_msg(?CONST_PLAYER_ATTR_SKILL_POINT) -> ?TIP_SKILL_POINT_NOT_ENOUGH;
get_min_msg(?CONST_PLAYER_EXPERIENCE)       -> ?TIP_COMMON_EXPERIENCE_NOT_ENOUGH;
get_min_msg(?CONST_PLAYER_ATTR_EXPLOIT)     -> ?TIP_GUILD_NO_EXPLOIT;
get_min_msg(_) -> ?TIP_COMMON_BAD_ARG.

%% 只要值不符合要求就会被和谐，然后通报撒花
between(Value, Min, _Max, Type) when Value < Min -> 
	MsgMin = get_min_msg(Type),
	{Min, MsgMin};
between(Value, _Min, Max, Type) when Max < Value ->
	MsgMax = get_max_msg(Type),
	{Max, MsgMax};
between(Value, _, _, _) -> {Value, 0}.

%% 设置属性值，变动后向前端发消息
set_to_value(UserId, OldValue, TargetValue, Min, Max, Type) ->
	Value2   = integerized(TargetValue),
	{NewValue, Msg} = between(Value2, Min, Max, Type),
	send_changed(UserId, Type, OldValue, NewValue, Msg),
	NewValue.

%% 有改变就发消息
send_changed(_UserId, _Type, OldValue, OldValue, 0) -> ?ok;
send_changed(UserId, _Type, OldValue, OldValue, Msg) -> 
	PacketErr = send_err_msg(Msg),
	misc_packet:send(UserId, PacketErr);
send_changed(UserId, Type, OldValue, NewValue, Msg) when OldValue < NewValue ->
	Packet    = msg_player_attr_update(?CONST_SYS_PLAYER, Type, NewValue),
	ExtPacket = pack_when_changed(Type, NewValue - OldValue),
	PacketErr = send_err_msg(Msg),
	Packet2   = <<Packet/binary, ExtPacket/binary, PacketErr/binary>>,
	misc_packet:send(UserId, Packet2);
send_changed(UserId, Type, _OldValue, NewValue, Msg) ->
	Packet    = msg_player_attr_update(?CONST_SYS_PLAYER, Type, NewValue),
	PacketErr = send_err_msg(Msg),
	Packet2   = <<Packet/binary, PacketErr/binary>>,
	misc_packet:send(UserId, Packet2).

send_err_msg(0)   -> <<>>;
send_err_msg(Msg) -> message_api:msg_notice(Msg).

%% 属性修改成功后的额外包
pack_when_changed(?CONST_PLAYER_ATTR_HP,     _Value) -> <<>>;
pack_when_changed(?CONST_PLAYER_ATTR_SP,     Value)  -> message_api:msg_reward_add_sp(Value);
pack_when_changed(?CONST_PLAYER_ATTR_VIP_LV, _Value) -> <<>>;
pack_when_changed(?CONST_PLAYER_ATTR_HONOUR, Value)  -> message_api:msg_reward_add_honour(Value);
pack_when_changed(?CONST_PLAYER_EXPERIENCE, _Value)   -> 
	message_api:msg_reward_add_experience(0);
pack_when_changed(_, _) -> <<>>.

%%====================================玩家进程辅助=============================================
%% 获取角色UserId的进程Id
%% 返回值：PlayerPid | ?null
get_player_pid(UserId) ->
	PlayerName	= misc_app:player_name(UserId),
	case misc:where_is({local, PlayerName}) of
		Pid when is_pid(Pid) -> Pid;
		?undefined -> ?null
    end.

%% 检查角色是否在线
%% 返回值：?true | ?false
check_online(UserId)  when is_number(UserId) ->
    case get_player_pid(UserId) of
        Pid when is_pid(Pid) -> ?true;
        ?null -> ?false
    end;
check_online(_Null) ->
    ?false.

%% 给在线玩家发信息,发送成功后在player_serv中区进行匹配处理
%% 返回：?true | ?false
process_send(PlayerPid, Mod, Fun, Arg) when is_pid(PlayerPid) ->
	player_serv:process_send(PlayerPid, Mod, Fun, Arg);
process_send(UserId, Mod, Fun, Arg) when is_number(UserId) ->
    case get_player_pid(UserId) of
        ?null -> ?false;
        PlayerPid -> process_send(PlayerPid, Mod, Fun, Arg)
    end;
process_send(_Id, _Mod, _Fun, _Arg) ->
    ?false.

%% 给在线玩家发信息  并返回数据
process_call(PlayerPid, Mod, Fun, Arg) when is_pid(PlayerPid) ->
    Self    = self(),
    case Self of
        PlayerPid ->
            ?MSG_ERROR("ERROR*****************************************", []),
            erlang:exit('send to yourself');
        _ -> ?ok
    end,
	player_serv:process_call(PlayerPid, Mod, Fun, Arg);
process_call(UserId, Mod, Fun, Arg) when is_number(UserId) ->
    case get_player_pid(UserId) of
        ?null -> ?false;
        PlayerPid -> process_call(PlayerPid, Mod, Fun, Arg)
    end;
process_call(_Id, _Mod, _Fun, _Arg) ->
    ?false.

%% 返回数据
progress_receive(From, Ref, Data)->
    misc:send_to_pid(From, {Ref, Data}).

get_player_first(UserId) when is_number(UserId) ->
    case ets_api:lookup(?CONST_ETS_PLAYER_ONLINE, UserId) of
        Player when is_record(Player, player) ->% 玩家在线
            {?ok, Player#player{user_id = UserId}, ?CONST_PLAYER_ONLINE};
        ?null ->% 玩家不在线
            case player_api:lookup_player_offline(UserId) of
                Player when is_record(Player, player) ->
                    ets_api:update_element(?CONST_ETS_PLAYER_OFFLINE, UserId, [{#player.access_time, misc:seconds()}]),
                    {?ok, Player, ?CONST_PLAYER_OFFLINE};
                ?null ->
                    case player_mod:read_player(UserId) of
                        {?ok, ?null} -> {?ok, ?null, ?CONST_PLAYER_OFFLINE};
                        {?ok, Player} ->
							player_api:insert_player_offline(Player#player{access_time = misc:seconds()}),
                            {?ok, Player, ?CONST_PLAYER_OFFLINE}
                    end
            end
    end;
get_player_first(UserId) ->
	?MSG_ERROR("Error UserId:~p, Stack:~p", [UserId, erlang:get_stacktrace()]),
    {?ok, ?null, ?CONST_PLAYER_OFFLINE}.

%% player_api:get_player_fields(200013, [2, 46, 60]).
get_player_fields(UserId, PosList) when is_list(PosList) ->
	get_player_fields(UserId, PosList, []);
get_player_fields(UserId, PosList) ->
	?MSG_ERROR("Error UserId:~p PosList:~p Stack:~p", [UserId, PosList, erlang:get_stacktrace()]),
	{?error, ?TIP_COMMON_BAD_ARG}.

get_test_server_award(Player) ->
    UserId = Player#player.user_id,
    case config:read_deep([server, release, is_test_server]) of
         true ->
            Info = Player#player.info,
            LastTime = Info#info.test_server_time,
            Now         = misc:seconds(),
            case misc:is_same_date(LastTime, Now) of
                true ->
                    ok;
                _ ->
                    case config:read_deep([server, release, close_time]) of
                        ?null ->
                            ?ok;
                        EndTime ->
                            StartTime   = new_serv_api:get_serv_start_time(),
                            DiffDay     = misc:get_diff_days(StartTime, Now),
                            Award = lists:nth(DiffDay + 1, ?CONST_PLAYER_TEST_AWARD),
                            player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Award, ?CONST_COST_TEST_SERVER_DAY_AWARD),
                            NewInfo = Info#info{test_server_time = Now},
                            EndSecond = misc:date_time_to_stamp(EndTime),
                            {{_,_,ED},_} = misc:seconds_to_localtime(EndSecond - 5),
                            {{_, _, ND}, _} = misc:date_time(),
                            AwardNext = 
                                case length(?CONST_PLAYER_TEST_AWARD) < DiffDay + 2  of
                                    true ->
                                        0;
                                    _ ->
                                        case ND == ED of
                                            true ->
                                                0;
                                            _ ->
                                                lists:nth(DiffDay + 2, ?CONST_PLAYER_TEST_AWARD)
                                        end
                                end,
                            Packet = msg_is_can_get_test_award(false, AwardNext),
                            misc_packet:send(UserId, Packet),
                            misc_packet:send_tips(UserId, ?TIP_GOODS_GET_OK),
                            {ok, Player#player{info = NewInfo}}
                    end
            end;
        _ ->
            ?ok
    end.

get_is_can_get_test_server_award(Player) ->
    case config:read_deep([server, release, is_test_server]) of
         true ->
            Info = Player#player.info,
            LastTime = Info#info.test_server_time,
            Now         = misc:seconds(),
            AwardList = ?CONST_PLAYER_TEST_AWARD,
            StartTime   = new_serv_api:get_serv_start_time(),
            DiffDay     = misc:get_diff_days(StartTime, Now),
            EndTime = config:read_deep([server, release, close_time]),
            EndSecond = misc:date_time_to_stamp(EndTime),
            {{_,_,ED},_} = misc:seconds_to_localtime(EndSecond - 5),
            {{_, _, ND}, _} = misc:date_time(),
            case misc:is_same_date(LastTime, Now) of
                true ->
                    Award = 
                        case length(AwardList) < DiffDay + 2  of
                            true ->
                                0;
                            _ ->
                                case ND == ED of
                                    true ->
                                        0;
                                    _ ->
                                        lists:nth(DiffDay + 2, AwardList)
                                end
                        end,
                    Packet = msg_is_can_get_test_award(false, Award);
                _ ->
                    Award = 
                        case length(AwardList) < DiffDay + 1  of
                            true ->
                                0;
                            _ ->
                                lists:nth(DiffDay + 1, AwardList)
                        end,
                    Packet = msg_is_can_get_test_award(true, Award)
            end;
        _ ->
            Packet = msg_is_can_get_test_award(false, 0)
    end,
     misc_packet:send(Player#player.user_id, Packet).

get_player_fields(UserId, [Pos|PosList], Acc) ->
	case get_player_field(UserId, Pos) of
		{?ok, Data} -> get_player_fields(UserId, PosList, [Data|Acc]);
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
get_player_fields(_UserId, [], Acc) -> {?ok, lists:reverse(Acc)}.

%% player_api:get_player_field(104317, 71).
get_player_field(UserId, Pos)
  when is_number(UserId) andalso Pos > 1 andalso Pos =< size(#player{})->
	case get_player_field(?CONST_ETS_PLAYER_ONLINE, UserId, Pos) of
		?null ->
			case get_player_field(?CONST_ETS_PLAYER_OFFLINE, UserId, Pos) of
				?null ->
					case player_mod:read_player(UserId) of
                        {?ok, ?null} -> {?error, ?TIP_COMMON_NO_THIS_PLAYER};% 玩家不存在
                        {?ok, Player} ->
							Player2		= Player#player{access_time = misc:seconds()},
							player_api:insert_player_offline(Player2),
                            {?ok, element(Pos, Player2)}
                    end;
				Data -> {?ok, Data}
			end;
		Data -> {?ok, Data}
	end;
get_player_field(UserId, Pos) ->
	?MSG_ERROR("Error UserId:~p Pos:~p Stack:~p", [UserId, Pos, erlang:get_stacktrace()]),
    {?error, ?TIP_COMMON_BAD_ARG}.

get_player_field(Ets, UserId, Pos) ->
	try ets_api:lookup_element(Ets, UserId, Pos)
	catch _Type:_Error -> ?null
	end.
%% %% 获取人物信息
%% get_player_info(PlayerId) ->
%% 	{IsOnline, PlayerInfo} =
%% 		case check_online(PlayerId) of
%% 			?true ->
%% 				{1, #player{}};
%% 			?false ->
%% 				{0, #player{}}
%% 		end,
%% 	{IsOnline, PlayerInfo}.

%% 自己向自己发消息强制下线
force2offline(UserId, Msg) ->
    player_serv:force2offline(UserId, Msg).

%%====================================培养=============================================
%% %%角色培养
%% player_trained(Player,Type)->
%% 	{OldTrainedForce, OldTrainedFate, OldTrainedMagic, _, _, _} = Player#player.train,
%% 	AttrRate 		= (Player#player.info)#info.attr_rate,
%% 	Lv 				= (Player#player.info)#info.lv,
%% 	TrainMax 		= get_max_train(AttrRate, Lv),
%% 	Flag1			= OldTrainedForce =:= TrainMax,
%% 	Flag2			= OldTrainedFate =:= TrainMax,
%% 	Flag3			= OldTrainedMagic =:= TrainMax,
%% 	MinTrain1		= misc:min(OldTrainedForce, OldTrainedFate),
%% 	MinTrain2		= misc:min(MinTrain1, OldTrainedMagic),
%% 	case {Flag1, Flag2, Flag3} of
%% 		{?true, ?true, ?true} ->
%% 			?ok;
%% 		_Other ->
%% 			case player_api:trained_cost(Player, TrainMax, MinTrain2, AttrRate, Type) of
%% 				 {?ok, Status} -> %% 培养成功
%% 					 TrainedForceTemp = get_trained_rand(OldTrainedForce, Lv, AttrRate, Type),
%% 					 TrainedFateTemp  = get_trained_rand(OldTrainedFate,  Lv, AttrRate, Type),
%% 					 TrainedMagicTemp = get_trained_rand(OldTrainedMagic, Lv, AttrRate, Type),
%% 					 NewPlayer = Status#player{
%% 											   train = {OldTrainedForce, OldTrainedFate, OldTrainedMagic,
%% 														TrainedForceTemp, TrainedFateTemp, TrainedMagicTemp}
%% 											  },
%% 					 %% 获取活跃度
%% 					 {?ok, NewPlayer1}	= schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_FIGURE_TRAIN),
%% 					 %% 成长礼包
%% %% 					 {?ok, NewPlayer2}  = welfare_api:add_pullulation(NewPlayer1, ?CONST_WELFARE_TRAIN, 0, 1),
%% 					 %% 新服成就
%% 					 TrainValue			= misc:max(TrainedForceTemp, TrainedFateTemp),
%% 					 TrainValue2		= misc:max(TrainValue, TrainedMagicTemp),
%% 					 {?ok, NewPlayer2}	= new_serv_api:finish_achieve(NewPlayer1, ?CONST_NEW_SERV_TRAIN, TrainValue2, 1),
%% 					 %% 成就系统
%% 					 {?ok, NewPlayer3}  = achievement_api:add_achievement(NewPlayer2, ?CONST_ACHIEVEMENT_FORCETRAIN, TrainValue2, 1),
%% 					 
%% 					 admin_log_api:log_player(NewPlayer3, ?CONST_LOG_POS_USER_TRAIN, ?CONST_PLAYER_ATTR_FORCE, TrainedForceTemp, Type),
%% 					 admin_log_api:log_player(NewPlayer3, ?CONST_LOG_POS_USER_TRAIN, ?CONST_PLAYER_ATTR_FATE, TrainedFateTemp, Type),
%% 					 admin_log_api:log_player(NewPlayer3, ?CONST_LOG_POS_USER_TRAIN, ?CONST_PLAYER_ATTR_MAGIC, TrainedMagicTemp, Type),
%% 					 {?ok, NewPlayer3, Type,TrainedForceTemp,TrainedFateTemp,TrainedMagicTemp, 0, TrainMax};
%% 				 _ ->  %% 培养失败
%% 					?ok
%% 			end
%% 	end.
%% 
%% %% 获取玩家培养上限
%% get_max_train(AttrRate, Lv) ->
%% 	20 + Lv*8*AttrRate div ?CONST_SYS_NUMBER_TEN_THOUSAND. %% 培养上限
%% 
%% %%保存角色培养
%% player_trained_save(Player)->
%% 	case Player#player.train of
%% 		{OldTrainedForce, OldTrainedFate, OldTrainedMagic, NewTrainedForce, NewTrainedFate, NewTrainedMagic} ->
%% 			NewPlayer = Player#player{
%% 										  train = {NewTrainedForce, NewTrainedFate, NewTrainedMagic,
%% 												   NewTrainedForce, NewTrainedFate, NewTrainedMagic}
%% 									 },
%% 			NewPlayer1 = player_attr_api:refresh_attr_train(NewPlayer),
%% 			admin_log_api:log_transpoint(Player, OldTrainedForce, NewTrainedForce, OldTrainedFate, NewTrainedFate, OldTrainedMagic, NewTrainedMagic, 0),
%%             schedule_power_api:packet_send(packet_base, NewPlayer1), % 战力-培养
%% 			[NewTrainedForce, NewTrainedFate, NewTrainedMagic, 0, NewPlayer1];
%% 		_Other ->
%% 			[0, 0, 0, 0, Player]
%% 	end.
%% 
%% %% 取消培养
%% player_trained_cancel(Player) ->
%% 	case Player#player.train of
%% 		{OldTrainedForce, OldTrainedFate, OldTrainedMagic, _, _, _} ->
%% 			NewPlayer = Player#player{
%% 										  train = {OldTrainedForce, OldTrainedFate, OldTrainedMagic,
%% 												   OldTrainedForce, OldTrainedFate, OldTrainedMagic}
%% 									 },
%% 			{?ok, NewPlayer};
%% 		_Other ->
%% 			{?ok, Player}
%% 	end.
%% %% -------------------------------------------------------
%% %% @desc	获取根据当前培养属性、角色等级、培养类型得到培养属性。
%% %% @parm    CurTra 		当前培养值
%% %% @parm    Lv			角色等级
%% %% @parm	Type		培养类型
%% %% @return  			培养结果
%% %% -------------------------------------------------------
%% get_trained_rand(CurTra, Lv, AttrRate, Type) ->
%% 	TrainRate =  (AttrRate * 6) div ?CONST_SYS_NUMBER_TEN_THOUSAND,
%% 	CurValue = (CurTra * 10000) div  AttrRate,
%%     TrainedLower = 
%%     	case Type of
%%     		?CONST_PLAYER_TRAIN_TYPE_0 ->
%%     			%% 普通培养
%%     			Compare = Lv div 2,
%%     			if CurValue * 2 < Lv ->
%%     				   CurTra;
%%     			   ?true ->
%%     				   Compare
%%     			end;
%%     			%% TrainedLower = misc:ceil(CurTra*0.0625);
%%     		?CONST_PLAYER_TRAIN_TYPE_1 ->
%%     			%% 加强培养
%%     			if CurValue  < Lv ->
%%     				   CurTra;
%%     			   ?true ->
%%     				   Lv
%%     			end;
%%     			%% TrainedLower = misc:ceil(CurTra*0.125);
%%     		?CONST_PLAYER_TRAIN_TYPE_2 ->
%%     			%% 白金培养
%%     			Compare = Lv * 2,
%%     			if CurValue  < 2 * Lv ->
%%     				   CurTra;
%%     			   ?true ->
%%     				   Compare
%%     			end;
%%     			%% TrainedLower = misc:ceil(CurTra*0.25);
%%     		?CONST_PLAYER_TRAIN_TYPE_3 ->
%%     			%% 钻石培养
%%     			CurTra;
%%     		?CONST_PLAYER_TRAIN_TYPE_4 ->
%%     			%% 至尊培养
%%     			CurTra + TrainRate;
%% 			?CONST_PLAYER_TRAIN_TYPE_5 ->
%% 				%% 一键培养
%% 				CurTra + TrainRate
%%     	end,
%% 	TrainMax = 20 + Lv*8*AttrRate div ?CONST_SYS_NUMBER_TEN_THOUSAND,
%% 	case Type of
%% 		?CONST_PLAYER_TRAIN_TYPE_4 ->
%% 			Result = CurTra+TrainRate,
%% 			if Result > TrainMax ->
%% 				   TrainMax;
%% 			   ?true ->
%% 				   Result
%% 			end;
%% 		?CONST_PLAYER_TRAIN_TYPE_5 ->
%% 			TrainMax;
%% 		_ ->
%%             NewTrainedLower = 
%%     			if TrainedLower =:= 0 ->
%%     				   1;
%%     			   ?true ->
%%     				   TrainedLower
%%     			end,
%% 			Limit = CurTra+TrainRate+1-NewTrainedLower,
%% 			Lower = 1,
%% 			
%% 			%% 计算基数。得到结果有可能是类似55.0，所以要取整。
%% 			%% Limit是概率区间上限，Lower是概率区间下限
%% 			Base = trunc((Lower+Limit)*((Limit-Lower+1)/2)),
%% 			%% 得到随机结果
%% 			get_trained_rand2(Lower, Limit, Base, TrainMax, CurTra, TrainRate, Type)
%% 	end.
%% 
%% get_trained_rand2(Lower, Limit, Base, TrainMax, CurTra, TrainRate, Type) ->
%% 	%% 随机出数值
%% 	RandResult = misc_random:random(1, Base),
%% 	%% 找到随机结果所对应的培养结果，如果结果超过TrainMax，则重新随机
%% 	TrainedResult = get_trained_rand3(RandResult, 1, 1, CurTra, TrainRate),
%% 	%% 获取培养保底值
%% 	ProtectFlag	  = get_train_protect(Type, TrainMax, CurTra),
%% 	if TrainedResult > TrainMax ->
%% 		   get_trained_rand2(Lower, Limit, Base, TrainMax, CurTra, TrainRate, Type);
%% 	   TrainedResult < 1 orelse TrainedResult > CurTra+TrainRate   ->
%% 		   ?MSG_DEBUG("Trained logic error, TrainedResult=~w, Lower=~w, Limit=~w, Base=~w, TrainMax=~w,
%% 					   RandResult=~w, CurTra=~w, TrainRate=~w~n", 
%% 					  [TrainedResult,Lower,Limit,Base,TrainMax,RandResult,CurTra, TrainRate]),
%% 		   CurTra;
%% 	   ProtectFlag andalso TrainedResult < CurTra -> %% 增加培养保底规则
%% 		   AddRand = misc:rand(1, 5),
%% 		   CurTra + AddRand;
%% 	   CurTra - TrainedResult > 15 -> %% 单项最大降低15点
%% 		   MinusRand = misc:rand(0, 15),
%% 		   CurTra - MinusRand; 
%% 	   ?true ->
%% 		   TrainedResult
%% 	end.
%% 
%% %% 循环找到随机结果所在区间
%% get_trained_rand3(RandResult, Up, Order, CurTra, TrainRate) ->
%% 	if RandResult =< Up ->
%% 		   CurTra+TrainRate-Order;
%% 	   ?true ->
%% 		   NewOrder = Order+1,
%% 		   NewUp = Up+NewOrder,
%% 		   get_trained_rand3(RandResult, NewUp, NewOrder, CurTra, TrainRate)
%% 	end.
%% 
%% %% 获取培养保底临界值
%% get_train_protect(TrainType, TrainMax, CurTra) when TrainType < ?CONST_PLAYER_TRAIN_TYPE_4 ->
%% 	ProtectPer	= data_player:get_player_train_protect(TrainType),
%% 	Value		= misc:floor(TrainMax * ProtectPer div ?CONST_SYS_NUMBER_HUNDRED),
%% 	Value > CurTra;	
%% get_train_protect(_TrainType, _TrainMax, _CurTra) -> ?false.
%% 		
%% %%检查和扣除培养费用
%% trained_cost(Player, TrainMax, MinCurTrain, GrowRate, Type)-> 
%% 	VipLv 		= player_api:get_vip_lv(Player),
%% 	{RealType, Flag} =
%% 		case Type =:= ?CONST_PLAYER_TRAIN_TYPE_5 of
%% 			?true ->
%% 				FastTrain	= player_vip_api:get_fast_train(VipLv),
%% 				TempFlag	= FastTrain =:= ?CONST_SYS_TRUE,
%% 				{?CONST_PLAYER_TRAIN_TYPE_4, TempFlag};
%% 			?false ->
%% 				TrainType 	= player_vip_api:get_train_max_lv(VipLv),
%% 				TempFlag	= Type =< TrainType,
%% 				{Type, TempFlag}
%% 		end,
%% 	CostValue 	= data_player:get_player_train_cost(RealType),
%% 	
%% 	case Flag of
%% 		?true ->
%% 			case Type of 
%% 				?CONST_PLAYER_TRAIN_TYPE_0 ->        %%普通培养
%% 		%% 			Cost = 5000, %% 等级^2*10+87
%% 		%% 			player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, Cost, 0);
%% 					Cost = 100 * (Player#player.info)#info.lv,
%% 					minus_experience(Player, Cost);
%% 				?CONST_PLAYER_TRAIN_TYPE_1 ->        %%进阶培养
%% 					PartnerData		  = Player#player.partner,
%% 					FreeTrainTimes 	  = PartnerData#partner_data.follow_partner, %% follow_partner字段为免费培养次数
%% 					{RealCostValue, Player2} =
%% 						case FreeTrainTimes > 0 of
%% 							?true ->
%% 								NewFreeTrain	= FreeTrainTimes - 1,
%% 								FreeTrainPacket	= partner_api:msg_free_train(NewFreeTrain),
%% 								misc_packet:send(Player#player.user_id, FreeTrainPacket),
%% 								PartnerData2	= PartnerData#partner_data{follow_partner = NewFreeTrain},
%% 								{0, Player#player{partner = PartnerData2}};
%% 							?false ->
%% 								{CostValue, Player}
%% 						end,
%% 					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, RealCostValue, ?CONST_COST_TRAIN_STREN) of
%% 						?ok ->
%% 							{?ok, Player2};
%% 						Other ->
%% 							Other
%% 					end;
%% 				?CONST_PLAYER_TRAIN_TYPE_2 ->
%% 					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, CostValue, ?CONST_COST_TRAIN_STREN_2) of
%% 						?ok ->
%% 							{?ok, Player};
%% 						Other ->
%% 							Other
%% 					end;
%% 				?CONST_PLAYER_TRAIN_TYPE_3 ->
%% 					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, CostValue, ?CONST_COST_TRAIN_STREN_3) of
%% 						?ok ->
%% 							{?ok, Player};
%% 						Other ->
%% 							Other
%% 					end;
%% 				?CONST_PLAYER_TRAIN_TYPE_4 ->
%% 					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, CostValue, ?CONST_COST_TRAIN_STREN_4) of
%% 						?ok ->
%% 							{?ok, Player};
%% 						Other ->
%% 							Other
%% 					end;
%% 				?CONST_PLAYER_TRAIN_TYPE_5 ->
%% 					RealCost	 = calc_fast_train_cost(TrainMax, MinCurTrain, GrowRate, CostValue),
%% 					case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, RealCost, ?CONST_COST_TRAIN_STREN_4) of
%% 						?ok ->
%% 							{?ok, Player};
%% 						Other ->
%% 							Other
%% 					end
%% 			end;
%% 		?false ->
%% 			Packet = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
%% 			misc_packet:send(Player#player.user_id, Packet)
%% 	end.
%% 
%% calc_fast_train_cost(TrainMax, MinCurTrain, GrowRate, CostValue) ->
%% 	TrainRate 		=  (GrowRate * 6) div ?CONST_SYS_NUMBER_TEN_THOUSAND,
%% 	Times			=  misc:ceil((TrainMax - MinCurTrain) / TrainRate),
%% 	misc:floor(Times * CostValue).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%% 获取玩家信息(测试用)
get_user_info_by_id(Id) ->
	case get_player_pid(Id) of
		[] -> [];
		Pid ->
             case catch gen:call(Pid, '$gen_call', 'PLAYER', 2000) of
             	{'EXIT',_Reason} ->
              		[];
             	{ok, Player} ->
               		Player
             end
	end.    
    
%% 更新玩家
%% 1.更新玩家到ets
%% 2.刷新物品buff
refresh_cb(Player, _) ->
    % 1
    PlayerOnLine = player_online_data(Player),
    ets_api:insert(?CONST_ETS_PLAYER_ONLINE, PlayerOnLine),
    % 2
    BuffList 	= Player#player.buff,
    {NewBuffList, PacketDel} = player_mod:refresh_buff(BuffList, [], misc:seconds(), <<>>),
	Player2     = Player#player{buff = NewBuffList},
    if
        BuffList =:= NewBuffList -> 
            {?ok, Player2};
        ?true ->
			misc_packet:send(Player#player.user_id, PacketDel),
            Player3 = player_attr_api:refresh_buff(Player2),
            {?ok, Player3}
    end.

plus_experience_cb(Player, [ExperienceAdd]) ->
    Info    = Player#player.info,
    case Info of
        Info when is_record(Info, info) ->
			NewPlayer		 = plus_experience(Player, ExperienceAdd),
			{?ok, NewPlayer};
        _ -> {?ok, Player}
    end.

%% sp定时更新
%% 这个体力只能到200，多了不给
sp_cb(Player, [SpAdd]) ->
    Info = Player#player.info,
    case Info of
        #info{sp = Sp, vip = Vip} ->
            VipLv = Vip#vip.lv,
            SpLimit = player_vip_api:get_sp_limit(VipLv),
            if
                Sp < SpLimit ->
                    Packet	= message_api:msg_notice(?TIP_COMMON_SP, [{?TIP_SYS_COMM, misc:to_list(SpAdd)}]),
                    misc_packet:send(Player#player.user_id, Packet),
                    plus_sp(Player, SpAdd, ?CONST_COST_PLAYER_ONLINE_SP);
                ?true -> {?ok, Player}
            end;
        _ -> {?ok, Player}
    end.

%% 获取离线的体力奖励
%% NewPlayer
%% 这也是只能加到200
sp_offline(#player{info = Info} = Player) when is_record(Info, info) ->
    Info  = Player#player.info,
    Off   = Info#info.time_last_off,
    Off2  = Off div ?CONST_PLAYER_SP_INTERVAL,
    Now   = misc:seconds(),
    Now2  = Now div ?CONST_PLAYER_SP_INTERVAL,
    VipData = Info#info.vip,
    VipLv = VipData#vip.lv,
    SpLimit = player_vip_api:get_sp_limit(VipLv),
    case Now2 - Off2 of
        Count when 0 < Count andalso Info#info.sp < SpLimit ->
            Sp		= Count * ?CONST_PLAYER_SP_PER_TIME,  %
            SpDelta = Sp + Info#info.sp,
			if
				SpDelta =< SpLimit -> plus_sp(Player, Sp, ?CONST_COST_PLAYER_OFFLINE_SP);
				?true -> plus_sp(Player, SpLimit - Info#info.sp, ?CONST_COST_PLAYER_OFFLINE_SP)
			end;
        _ -> {?ok, Player}
    end;
sp_offline(Player) ->
	{?ok, Player}.

%% 刷新登陆奖励标志
refresh_player_info(Player) ->
	clear_sp_buy_times(Player).

%% 登录
login(Player) ->
    Player2 = Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL},
%%     {?ok, NewPlayer} = sp_offline(Player2), %% 离线体力在处理完扫荡后再加 否则有上限限制
	{?ok, NewPlayer} = refresh_player_info(Player2),
    NewPlayer.

%%=====================================改名==============================================
change_username(Player, NewUserName) ->
    UserId = Player#player.user_id,
    case player_combine_api:is_changed(UserId) of
        ?CONST_SYS_TRUE ->
            MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_ED),
            misc_packet:send(UserId, MsgPacket),
            {?ok, Player};
        ?CONST_SYS_FALSE ->
            NewBag = Player#player.bag,
            
            case check_name(NewUserName) of
                ?ok ->
                    Info = Player#player.info,
					OldUserName = Info#info.user_name,
                    Player2 = Player#player{info = Info#info{user_name = NewUserName}, bag = NewBag},
                    {NewPlayer, NewPacket} = player_mod:run_change_name_ets(Player2, <<>>, OldUserName),
                    player_mod:run_change_name_db(OldUserName, NewUserName, UserId),
                    player_combine_api:change(UserId),
        
                    OkPacket = player_api:msg_is_ok(?CONST_SYS_TRUE),
                    MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_OK),
                    Packet2 = player_api:msg_player_attr_update_str(?CONST_PLAYER_ATTR_NAME, NewUserName),
                    ChangenamePacket = player_combine_api:login_packet(NewPlayer),
                    misc_packet:send(UserId, <<NewPacket/binary, Packet2/binary, ChangenamePacket/binary, OkPacket/binary, MsgPacket/binary>>),
                    map_api:change_name(NewPlayer),
                    {?ok, NewPlayer};
                {?error, _ErrorCode} ->
                    PacketErr = message_api:msg_notice(?TIP_COMMON_USERNAME_EXIST),
                    misc_packet:send(UserId, PacketErr),
                    {?ok, Player}
            end;
        _ ->
            MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_ERR),
            misc_packet:send(UserId, MsgPacket),
            {?ok, Player}
    end.
%%=====================================改名卡==============================================
change_username(#player{user_id = UserId, bag = Bag} = Player, NewUserName, ?CONST_PLAYER_CHANGE_NAME_GOODS) ->
	try
		?ok = check_condition(Player, NewUserName),
		case ctn_bag2_api:get_by_id(UserId, Bag, ?CONST_PLAYER_EXCH_NAME_GOODS, 1) of
			{?ok, NewBag, _GoodsList, Packet} ->
				Info = Player#player.info,
				OldUserName = Info#info.user_name,
				Player2 = Player#player{info = Info#info{user_name = NewUserName}, bag = NewBag},
				{NewPlayer, _NewPacket} = player_mod:run_change_name_ets(Player2, <<>>, OldUserName),
				player_mod:run_change_name_db(OldUserName, NewUserName, UserId),
				OkPacket = player_api:msg_is_ok(?CONST_SYS_TRUE),
				MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_OK),
				Packet2 = player_api:msg_player_attr_update_str(?CONST_PLAYER_ATTR_NAME, NewUserName),
				misc_packet:send(UserId, <<Packet/binary, Packet2/binary, OkPacket/binary, MsgPacket/binary>>),
				map_api:change_name(NewPlayer),
				Friend = relation_api:list_friend(UserId),
				F = fun(MemId) ->
							case get_player_field(MemId, #player.info) of
								{?error, ErrorCode} ->
									?MSG_ERROR("get mem name fail ErrorCode:~p", [ErrorCode]),
									?ok;
								{?ok, MemInfo} ->
									MemName = MemInfo#info.user_name,
									mail_api:send_system_mail_to_one2(MemName, <<>>, <<>>, ?CONST_MAIL_FRIEND_CHANGE_NAME,
																	  [{[{misc:to_list(OldUserName)}]}, {[{misc:to_list(NewUserName)}]}], [], 0, 0, 0, 0)
							end
					end,
				[F(E) || E <- Friend],
				case goods_api:goods(?CONST_PLAYER_EXCH_NAME_GOODS) of
					?null ->
						?MSG_ERROR("get goods info error goods_id:~p", [?CONST_PLAYER_EXCH_NAME_GOODS]),
						?ok;
					Goods ->
						mail_api:send_system_mail_to_one2(NewUserName, <<>>, <<>>, ?CONST_MAIL_CHANGE_NAME_SUCCESS,
														  [{[{misc:to_list(Goods#goods.goods_id)}]}], [], 0, 0, 0, 0)
				end,
				{?ok, NewPlayer};
			{?error, ErrorCode} ->
				throw({?error, ErrorCode})
		end
	catch
		throw:{?error, ErrorCode2} ->
			TipPacket = message_api:msg_notice(ErrorCode2),
			misc_packet:send(UserId, TipPacket),
			{?ok, Player};
		ErrType:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p~n ", [ErrType, Reason, erlang:get_stacktrace()])
	end.

%% 检查改名条件
check_condition(#player{bag = Bag}, NewUserName) ->
	case ctn_bag2_api:get_goods_count(Bag, ?CONST_PLAYER_EXCH_NAME_GOODS) >= 1 of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_PLAYER_GOODS_NOT_ENOUGH})
	end,
	case check_name(NewUserName) of
		?ok ->
			?ok;
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_USERNAME_EXIST})
	end.

%%=====================================统计==============================================
%% 每日全服货币总量统计
server_money_static() ->
	try player_mod:server_money_static()
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  ?ok
	end.

%% 在线玩家列表
all_user_online() ->
	ets_api:select(?CONST_ETS_PLAYER_ONLINE, ets:fun2ms(fun(X) -> (X#player.info)#info.user_name end)).

%% 全服在线玩家数量
total_online() ->
	ets:info(?CONST_ETS_PLAYER_ONLINE, size).

%% 封号玩家列表
ban_user_list() ->
	player_db_mod:ban_user_list().

%% 获取玩家等级
player_lv(UserId) when is_number(UserId) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{lv = Lv}} -> Lv;
		_ -> 0
	end;
player_lv(Player) when is_record(Player, player) ->
	(Player#player.info)#info.lv;
player_lv(_) -> 0.

%% 计算体力花费元宝
calc_sp_cash(BoughtTimes) ->
    BoughtTimes * ?CONST_PLAYER_SP_UP_CASH_PER_BUY + ?CONST_PLAYER_SP_INIT_CASH_BUY.

%% 购买体力
buy_sp(Player) ->
    UserId = Player#player.user_id,
    try
        ?ok   		= check_plus_sp(Player, ?CONST_PLAYER_SP_PER_BUY),
        Info  		= Player#player.info,
        SpBuy 		= Info#info.sp_buy_times,
        VipLv		= player_api:get_vip_lv(Info),
        SpBuyMax 	= player_vip_api:get_sp_max(VipLv),   % ?CONST_PLAYER_SP_MAX_LIMIT, %
        Player3  	=
            if
                SpBuy < SpBuyMax -> % 还有购买次数
                    Value = calc_sp_cash(SpBuy),
                    ?ok   = cost_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_PLAYER_BUY_SP),
                    {?ok, Player2} = plus_sp(Player, ?CONST_PLAYER_SP_PER_BUY, ?CONST_COST_PLAYER_BUY_SP),
                    Info2 = Player2#player.info,
                    Info3 = Info2#info{sp_buy_times = SpBuy + 1},
                    BoughtTimes2 = Info3#info.sp_buy_times,
                    NextCash     = calc_sp_cash(BoughtTimes2),
                    % packet
                    Packet       = msg_sc_buy_sp_info(BoughtTimes2, NextCash),
                    PacketOk     = message_api:msg_notice(?TIP_COMMON_BUY_SP_SUCCESS),
                    misc_packet:send(UserId, <<Packet/binary, PacketOk/binary>>),
                    set_info(Player2, Info3);
                ?true -> %  购买次数已满
                    PacketSp = message_api:msg_notice(?TIP_COMMON_BUY_SP_TIMES_OVER),
                    misc_packet:send(UserId, PacketSp),
                    Player
            end,
        {?ok, Player3}
    catch
        throw:{?error, ErrorCode} when ?TIP_COMMON_GOLD_NOT_ENOUGH =:= ErrorCode orelse
                                       ?TIP_COMMON_CASH_NOT_ENOUGH =:= ErrorCode -> % 扣钱的时候发了
            {?error, ErrorCode};
        throw:{?error, ErrorCode} ->
            PacketErr = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, PacketErr),
            {?error, ErrorCode};
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            PacketErr = message_api:msg_notice(?TIP_COMMON_BUY_SP_ERROR),
            misc_packet:send(UserId, PacketErr),
            {?error, ?TIP_COMMON_BUY_SP_ERROR} 
    end.

check_plus_sp(Player, _Sp) ->
    Info     = Player#player.info,
    SpPlayer = Info#info.sp,
    SpMax    = ?CONST_PLAYER_SP_MAX_LIMIT, 
    if
        SpPlayer < SpMax  ->
            ?ok;
        ?true ->
            throw({?error, ?TIP_COMMON_SP_IS_ENOUGH})
    end.

cost_money(UserId, Type, Value, Point) ->
    case player_money_api:minus_money(UserId, Type, Value, Point) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 转职
change_pro(Player, Pro) ->
    Info = Player#player.info,
    OldPro = Info#info.pro,
    Lv = Info#info.lv,
    if
        OldPro =:= Pro ->
            TipPacket = message_api:msg_notice(?TIP_PLAYER_SAME_PRO),
            misc_packet:send(Player#player.user_id, TipPacket),
            Player;
        Lv < 30 ->
            TipPacket = message_api:msg_notice(?TIP_COMMON_LEVEL_NOT_ENOUGH),
            misc_packet:send(Player#player.user_id, TipPacket),
            Player;
        ?true ->
            case ctn_equip_api:is_non_equip(Player) of
                0 ->
                    case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, ?CONST_GOODS_CHANGE_PRO, 1) of
                        {?ok, Bag2, _, Packet} ->
                            % 技能点
                            CostSkillPoint       = skill_api:calc_skill_point(Player),
                            OldSkillPoint        = Info#info.skill_point,
                            Info2 = Info#info{pro = Pro, skill_point = CostSkillPoint+OldSkillPoint},
                            
                            Sex = Info2#info.sex,
                            InitSkillList = player_default_api:get_default_skill(Pro, Sex), 
                            SkillData2 = skill_api:create(InitSkillList),
                            TipPacket = message_api:msg_notice(?TIP_PLAYER_CHANGE_PRO_OK),
                            misc_packet:send(Player#player.user_id, <<TipPacket/binary, Packet/binary>>),
                            
                            % 竞技场
                            single_arena_api:update_pro(Player#player.user_id, Pro),
                            
                            Self = self(),
                            tick(Self),
                            Player#player{bag = Bag2, skill = SkillData2, info = Info2};
                        _ ->
                            Player
                    end;
                1 ->
                    TipPacket2 = message_api:msg_notice(?TIP_COMMON_HAS_EQUIP),
                    misc_packet:send(Player#player.user_id, TipPacket2),
                    Player;
                2 ->
                    TipPacket2 = message_api:msg_notice(?TIP_COMMON_HAS_HORSE),
                    misc_packet:send(Player#player.user_id, TipPacket2),
                    Player;
                3 ->
                    TipPacket2 = message_api:msg_notice(?TIP_COMMON_HAS_FASHION),
                    misc_packet:send(Player#player.user_id, TipPacket2),
                    Player
            end
    end.

%%===============================gm==================================================
%% t人
tick(UserId) when is_number(UserId) ->
    Name = misc_app:player_name(UserId),
    player_serv:user_logout(Name);
tick(Pid) when is_pid(Pid) ->
    player_serv:user_logout(Pid);
tick([UserId|Tail]) ->
    tick(UserId),
    tick(Tail);
tick([]) ->
    ?ok.

%% 提权成为gm
upgrate_to_gm(Player) ->
	?MSG_ERROR("bad state_convert operate:=~p", [Player#player.state]),
    Player#player{state = ?CONST_SYS_USER_STATE_GM}.
%% 降权成为普通玩家
downgrate_to_normal(Player) ->
    Player#player{state = ?CONST_SYS_USER_STATE_NORMAL}.

%% gm?
is_gm(Player) when is_record(Player, player) ->
    ?CONST_SYS_USER_STATE_GM =:= Player#player.state.

%%=================================================================================
login_packet(Player, AccPacket) ->
    try
        UserId 		= Player#player.user_id,
        Info 		= Player#player.info,
    	
    	% [1998]时间同步协议
    	Packet1 	= player_api:msg_player_sc_tsp(misc:seconds()),
        % [1012]角色数据
    	player_money_api:update_element_money(UserId, [{#money.first_consume, Info#info.first_consume}]),
    	{?ok, Money}= player_money_api:read_money(UserId),
        Packet2 	= player_api:msg_player_data_info(Player, Money, 1),
        % [1130]返回BUFF列表信息
        Packet3  	= msg_sc_buff_info(Player#player.buff),
        % [1410]返回开启模块列表
        Packet4 	= player_api:msg_sc_open_sys_info(Player#player.sys_rank),
        %
        BoughtTimes = Info#info.sp_buy_times,
        NextCash 	= player_api:calc_sp_cash(BoughtTimes),
        Packet5 	= player_api:msg_sc_buy_sp_info(BoughtTimes, NextCash),
    	%
    	Packet6 	= furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, Player#player.furnace),
    	% [1312]隐藏时装皮肤状态
        IsHideFashion = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
    	Packet7		= msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_FASHION, IsHideFashion),
    	% [1312]隐藏坐骑皮肤状态
        IsHideHorse = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
    	Packet8		= msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_HORSE, IsHideHorse),
		% [1312]隐藏vip等级
		IsHideVip	= goods_style_api:is_hide(Player, ?CONST_GOODS_ATTR_VIP),
		Packet9		= msg_sc_hide_skin_info(?CONST_PLAYER_HIDE_SKIN_TYPE_VIP, IsHideVip),
    	% [1226]已领取礼包信息
    	Packet10	= msg_sc_get_gift_info(Info#info.gifts),
        % 合服
        Packet11    = player_combine_api:login_packet(Player),
    	% [1227]旧服玩家礼包（再战沙场）
    	IsLevel35 	= is_level_35(Player), 
    	Packet12    = msg_sc_old_server_user(IsLevel35),
        % 世界等级加成
        Rate        = rank_api:get_rank_rate(Info#info.lv),
        RatePacket  = msg_sc_world_lv(round((Rate - 1) * 100)),
        % 体验服
        TestPacket  = get_is_test_server(),
        get_is_can_get_test_server_award(Player),
        % a/b
        NewBieTypePacket = 
            case Info#info.is_newbie of
                10 ->
                    msg_sc_ab(1);
                0 ->
                    msg_sc_ab(1);
                _ ->
                    msg_sc_ab(0)
            end,
         player_vip_api:refresh_vip(UserId),
        {Player, <<AccPacket/binary, Packet1/binary, NewBieTypePacket/binary, Packet2/binary, Packet3/binary, Packet4/binary,
                   Packet5/binary, Packet6/binary, Packet7/binary, Packet8/binary, Packet9/binary,
                   Packet10/binary, Packet11/binary, Packet12/binary, RatePacket/binary, TestPacket/binary>>}
   catch
      X:Y ->
        ?MSG_ERROR("~p~n~p~n~p", [X, Y, erlang:get_stacktrace()]),
        {Player, <<>>}
   end.

get_is_test_server() ->
    case config:read_deep([server, release, is_test_server]) of
        ?true ->
            msg_sc_test_server();
        _ ->
            <<>>
    end.

%% 老玩家是否在旧服达到35，满足再战沙场礼包的条件
is_level_35(#player{info = Info}) ->
    case Info#info.is_draw of
        0 -> ?CONST_SYS_FALSE;
        1 -> ?CONST_SYS_TRUE;
        2 -> ?CONST_SYS_FALSE
    end.

%% 当玩家顶号登陆时要做的处理
do_when_update_net(Player0) ->
	try
		{?ok, Player} =team_api:logout(Player0),
		practice_api:cancel(Player),
		map_api:logout(Player),
        camp_pvp_api:player_logout(Player#player.user_id),
		{?ok, Player2}	= battle_api:offline(Player),
		Player3 		= copy_single_api:login(Player2),
		Player4 		= map_api:login_init(Player3),
		{?ok, Player5} 	= party_api:logout(Player4),
		{?ok, Player6}  = spring_api:logout(Player5),
		{?ok, Player7}  = world_api:logout(Player6),
		{?ok, Player8}  = boss_api:logout(Player7),
        {?ok, Player8#player{practice_state = ?CONST_PLAYER_STATE_NORMAL, can_gm = 0}}
	catch Type:Error ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~n", [Type, Error, erlang:get_stacktrace()]),
              {?ok, Player0}
	end.

%% 玩家下线数据转移
logout(Player) ->
    delete_player_online(Player#player.user_id),
    insert_player_offline(Player),
	delete_ip(Player#player.ip).

%% 删除在线玩家数据
delete_player_online(UserId) ->
    ets_api:delete(?CONST_ETS_PLAYER_ONLINE, UserId).
%%==================================================================================
%% 每五分钟处理
handle_five_minutes() ->
	admin_api:interval_chat_clc(),			% 聊天监控心跳
	admin_api:stat_online(),				% 统计在线人数
	map_api:stat_map_player(),				% 统计地图人数
	?ok.
%%==================================================================================
%% 零点处理
handle_zero_oclock() ->
    case config:read_deep([server, base, debug]) of
        ?CONST_SYS_TRUE ->
            erlang:spawn(fun handle_zero_oclock1/0);
        ?CONST_SYS_FALSE ->
            ?RANDOM_SEED,
            RandTime = erlang:trunc(misc:rand(1000, 120000)),
            ?MSG_ERROR("RandTime is ~w", [RandTime]),
            timer:apply_after(RandTime, erlang, spawn, [fun handle_zero_oclock1/0])
    end.

handle_zero_oclock1() ->
    ?MSG_ERROR("zero !!!", []),
    ?RANDOM_SEED,
    clear_log_ndays_ago(3, ["player", "error", "chat"]),       % 清除N天前的日志
    home_api:clean_home_times(),            % 家园
	mail_api:clean_overdure_mail(),			% 邮件
    single_arena_api:refresh_oclock(), 		% 个人竞技场
    guild_api:clear(),                      % 军团
	commerce_api:friend_clear(),            % 商路
	tower_api:clean_tower_times(),			% 破阵
	robot_world_api:refresh(),              % 乱天下替身
	schedule_api:refresh1(),                % 资源回收
    player_sup:refresh_oclock(),            % 玩家
    logger_serv:gc(),                       % 日志
    clear_player_off_zero(),                % 刷新off的玩家时间
    archery_api:send_reward(),              % 辕门射戟发送奖励
	% yunying_activity_api:card_game_fresh(),  %神刀活动更新
    act_bhv:refresh(),
	
    erlang:garbage_collect(),
  	rank_api:new_serv_reward(),			% 排行榜-发放新服奖励
    server_money_static(),            		% 全服货币总量统计
    ?ok.

%% 删除n天前的日志
clear_log_ndays_ago(N, [Type|Tail]) ->
    try
        SecondsBefore = misc:seconds()-N*86400,
        if(SecondsBefore < 0) -> 
              throw({?error, ?TIP_COMMON_BAD_ARG});
          ?true -> 
              DateBefore = misc:seconds_to_date_num(SecondsBefore),
              DateList = misc:to_list(DateBefore),
              LogPath = ?DIR_LOGS_ROOT++Type++"/"++DateList,
              case file:list_dir(LogPath) of
                  {?ok, List} ->
                      lists:foreach(fun(Filename) -> 
                                            ?MSG_DEBUG("=[~p]", [LogPath++"/"++Filename]),
                                            X = file:delete(LogPath++"/"++Filename),
                                            ?MSG_DEBUG("x[~p]", [X])
                                end, List),
                      file:del_dir(LogPath);
                  {?error, ERR} ->
                      throw({?error, ERR})
              end
        end,
        clear_log_ndays_ago(N, Tail)
    catch
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p", [Error, Reason, erlang:get_stacktrace()]),
            clear_log_ndays_ago(N, Tail)
    end;
clear_log_ndays_ago(_N, []) -> ?ok.

%% 0点人物各系统回调
%% player_api:process_send(15782, player_api, handle_zero_oclock_cb, []).
handle_zero_oclock_cb(Player, _) ->
    get_is_can_get_test_server_award(Player),
    {?ok, Player1} = mind_api:clear_mind_by_day(Player, []),   	% 心法更新
    {?ok, Player2} = player_vip_api:zero_oclock_refresh(Player1, ?CONST_SYS_TRUE),% VIP更新
    {?ok, Player3} = mcopy_api:refresh(Player2),           	   	% 多人副本0点更新
    {?ok, Player4} = partner_api:refresh_looknum(Player3, []), 	% 武将寻访次数0点更新
    {?ok, Player5} = clear_sp_buy_times(Player4),              	% 购买体力次数
    {?ok, Player6} = task_api:refresh(Player5),                	% 刷新任务 
    {?ok, Player7} = copy_single_api:refresh(Player6),         	% 副本更新
	{?ok, Player8} = welfare_api:refresh(Player7),			   	% 刷新福利(连续登陆补签次数)
	{?ok, Player9} = resource_api:refresh(Player8),			   	% 刷新资源系统(巡城次数)
	{?ok, Player10} = schedule_api:refresh(Player9),
	{?ok, Player11} = practice_api:refresh(Player10),		   % 修炼 
  	{?ok, Player12} = new_serv_api:refresh(Player11),		   % 新服活动
	{?ok, Player13} = invasion_api:refresh_zero(Player12),	   % 异民族(进入次数)
    {?ok, Player14} = welfare_deposit_api:refresh(Player13),   % 充值礼包
	{?ok, Player15} = weapon_api:refresh(Player14),   		   % 神兵免费洗练次数
	{?ok, Player16} = horse_api:refresh(Player15),             % 坐骑
    gun_award_api:zero_refresh(Player),
	?ok = yunying_activity_mod:refresh(Player16),                % 运营活动0点刷新
%%  yunying_activity_mod:shuangdan_refresh_zero(Player16),       %双旦活动零点刷新
%% 	yunying_activity_mod:bless_refresh(Player16),                %财神祝福0点刷新
%% 	yunying_activity_mod:stone_compose_mail(Player16),			 % 宝石合成过期礼包发送
	msg_zero_oclock(Player16),
	encroach_api:zero_refresh(Player16),						% 攻城略地
	shop_secret:zero_refresh(Player16),							% 云游商人
    archery_api:clear_acc(Player16),                                   %辕门射击累积奖励发送
	hundred_serv_api:zero_flush(Player16),              %百服活动刷新
	catch act_bhv:zero(Player16) ,                %活动时间
	
    erlang:garbage_collect(),
    {?ok, Player16}.

%%  0点发送协议
msg_zero_oclock(Player) ->
	Packet 			= single_arena_api:times_cd_to_front(Player#player.user_id),
	misc_packet:send(Player#player.user_id, Packet).

clear_sp_buy_times(Player) ->
	try
	    Info = Player#player.info,
		Date  		 = Info#info.date,
		Today		 = misc:date_num(),
		case Date =/= Today of
			?true ->
			    Info2 = Info#info{date = Today, sp_buy_times = 0, gift_cash = ?false},
				BoughtTimes  = Info2#info.sp_buy_times,
			    NextCash     = calc_sp_cash(BoughtTimes),
			    SpPacket     = msg_sc_buy_sp_info(BoughtTimes, NextCash),
				misc_packet:send(Player#player.net_pid, SpPacket),
			    {?ok, Player#player{info = Info2}};
			?false ->
				{?ok, Player}
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.


%% 插入玩家离线数据
insert_player_offline(PlayerOrPlayerList) ->
    ets_api:insert(?CONST_ETS_PLAYER_OFFLINE, PlayerOrPlayerList).
%% 删除玩家离线数据
delete_player_offline(UserId) ->
    ets_api:delete(?CONST_ETS_PLAYER_OFFLINE, UserId).
%% 查询玩家离线数据
lookup_player_offline(UserId) ->
	ets_api:lookup(?CONST_ETS_PLAYER_OFFLINE, UserId).

%% 清除太久没上线的人的数据
clear_player_off_zero() ->
	try
        ets:delete_all_objects(?CONST_ETS_PLAYER_OFFLINE),
        
        ?RANDOM_SEED,
        RandTime = misc:rand(1000, 120000),
        ?MSG_ERROR("RandTime is ~w", [RandTime]),
        misc:sleep(RandTime),
        erlang:garbage_collect()
    
%% 		TimeLast = misc:seconds() + ?CONST_SYS_ONE_DAY_SECONDS,
%% 		List     = ets_api:list(?CONST_ETS_PLAYER_OFFLINE),
%% 		F = fun(#player{user_id = UserId, access_time = AccessTime})
%% 				 when TimeLast =< AccessTime ->
%% 					delete_player_offline(UserId);
%% 			   (_) -> ?ok
%% 			end,
%% 		lists:foreach(F, List)
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

%% 玩家名-ID
insert_name(NameIdList) ->
    ets_api:insert(?CONST_ETS_PLAYER_NAME, NameIdList).
insert_name(Name, Id) ->
    ets_api:insert(?CONST_ETS_PLAYER_NAME, {Name, Id}).
lookup_name(UserName) ->
    ets_api:lookup(?CONST_ETS_PLAYER_NAME, UserName).
%% 检查重名
check_name(UserName) ->
    case lookup_name(UserName) of
        ?null -> ?ok;
        _ -> {?error, ?CONST_PLAYER_CREATE_REPEAT_NAME}
    end.
%% 删除名
delete_name(Name) ->
    ets_api:delete(?CONST_ETS_PLAYER_NAME, Name).

%% 平台账号-ID
insert_account(AccountIdList) ->
    ets_api:insert(?CONST_ETS_PLAYER_ACCOUNT, AccountIdList).
insert_account(Account, Id) ->
    ets_api:insert(?CONST_ETS_PLAYER_ACCOUNT, {Account, Id}).
lookup_account(Account) ->
    ets_api:lookup(?CONST_ETS_PLAYER_ACCOUNT, Account).

insert_account_2([X|Tail]) ->
    ets_api:insert(?CONST_ETS_PLAYER_ACCOUNT_2, X),
    insert_account_2(Tail);
insert_account_2([]) ->
    ?true.
insert_account_2(Account, ServId, UserId) ->
    ets_api:insert(?CONST_ETS_PLAYER_ACCOUNT_2, {{misc:to_binary(Account), ServId}, UserId}).
lookup_account_2(Account, ServId) ->
    ets_api:lookup(?CONST_ETS_PLAYER_ACCOUNT_2, {Account, ServId}).

%% 平台账号-ID
insert_account_user_id([{Account, UserIdList}|Tail]) ->
    ets_api:insert(?CONST_ETS_ACCOUNT_USER_ID, {Account, UserIdList}),
    insert_account_user_id(Tail);
insert_account_user_id([]) ->
    ?true.
lookup_account_user_id(Account) ->
    ets_api:lookup(?CONST_ETS_ACCOUNT_USER_ID, Account).
insert_account_user_id(Account, UserId) ->
    case lookup_account_user_id(Account) of
        {_, UserIdList} ->
            ets_api:insert(?CONST_ETS_ACCOUNT_USER_ID, {Account, [UserId|UserIdList]});
        _ ->
            ets_api:insert(?CONST_ETS_ACCOUNT_USER_ID, {Account, [UserId]})
    end.

%% 角色IP
insert_ip(Ip) ->
    ets_api:insert(?CONST_ETS_PLAYER_IP, {Ip}).
delete_ip(Ip) ->
    ets_api:delete(?CONST_ETS_PLAYER_IP, Ip).

%% 检查账号角色
check_account_player(Account, ServId) ->
    case lookup_account_2(Account, ServId) of
        ?null -> ?CONST_SYS_FALSE;
        _ -> ?CONST_SYS_TRUE
    end.

%% %% 检查账号角色
%% check_account_player(Account) ->
%%     case lookup_account(Account) of
%%         ?null -> ?CONST_SYS_FALSE;
%%         _ -> ?CONST_SYS_TRUE
%%     end.

%% 获取玩家名字
get_level(UserId) when is_number(UserId) ->
    case get_player_field(UserId, #player.info) of
        {?ok, #info{lv = Level}} -> Level;
        _Other -> <<"null">>
    end.

%% 获取玩家名字
get_name(UserId) when is_number(UserId) ->
	case get_player_field(UserId, #player.info) of
		{?ok, #info{user_name = UserName}} -> UserName;
		_Other -> <<"null">>
	end;
get_name(Player) when is_record(Player, player) ->
	(Player#player.info)#info.user_name;
get_name(_) -> <<"null">>.
%% 初始化玩家相关的ets
initial_ets() ->
	?ok		= initial_ets_name_id(),
	?ok		= initial_ets_account_id(),
	?ok		= initial_ets_account_id_2(),
	?ok		= initial_ets_player_offline(),
%% 	?ok		= player_gift_api:initial_ets_player_code(),
    ?ok     = initial_ets_account_user_id(),
	?ok.
initial_ets_name_id() ->
	NameIdList	= player_db_mod:get_user_name_id_list(),% 读取所有的玩家名
	?true		= insert_name(NameIdList),
	?ok.
initial_ets_account_id() ->
	AccountIdList	= player_db_mod:get_account_id_list(),% 读取所有的平台账号
	?true			= insert_account(AccountIdList),
	?ok.
initial_ets_account_id_2() ->
	AccountIdList	= player_db_mod:get_account_id_list_2(),% 读取所有的平台账号
	?true			= insert_account_2(AccountIdList),
	?ok.

initial_ets_player_offline() ->
	case player_db_mod:get_active_user_id() of
		{?ok, UserIdList} ->
			lists:foreach(fun([UserId]) -> get_player_first(UserId) end, UserIdList),
			?ok;
		{?error, Error} -> {?error, Error}
	end.

initial_ets_account_user_id() ->
    AccountUserIdList   = player_db_mod:get_account_user_id_list(),% 读取所有的平台账号
    ?true               = insert_account_user_id(AccountUserIdList),
    ?ok.

%%=====================================g && s==============================================
%% 读取info
get_info(Player) ->
	Player#player.info.
set_info(Player, Info) ->
    Player#player{info = Info}.

%% 读取当前生命值
get_hp(Player) when is_record(Player, player) ->
	Info = get_info(Player),
	Info#info.hp.

%% 读取当前生命值
get_sp(Player) when is_record(Player, player) ->
	Info = get_info(Player),
	Info#info.sp.

%% 读取attr
get_attr(Player) when is_record(Player, player) ->
	Player#player.attr.

%% 读取attr 2nd
get_attr_2nd(Player) when is_record(Player, player) ->
	Attr = get_attr(Player),
	Attr#attr.attr_second;
get_attr_2nd(Attr) when is_record(Attr, attr) ->
	Attr#attr.attr_second.

%% 读取生命最大值
get_hp_max(Player) when is_record(Player, player) ->
	Attr2nd = get_attr_2nd(Player),
	Attr2nd#attr_second.hp_max;
get_hp_max(Attr) when is_record(Attr, attr) ->
	Attr#attr.attr_second.

set_hp(Player, Hp) when is_record(Player, player) ->
    Info = get_info(Player),
    Player#player{info = Info#info{hp = Hp}};
set_hp(Info, Hp) when is_record(Info, info) ->
	Info#info{hp = Hp}.

set_sp(Player, Sp) when is_record(Player, player) ->
    Info = get_info(Player),
    Player#player{info = Info#info{sp = Sp}};
set_sp(Info, Sp) when is_record(Info, info) ->
	Info#info{sp = Sp}.

get_user_id(Player) when is_record(Player, player) ->
	Player#player.user_id;
%% 通过角色名获取角色UserId
%% 返回值：{?ok, UserId} | {?error, ErrorCode}
get_user_id(UserName) ->
    get_user_id_by_name(UserName).

%% 通过角色名获取角色UserId
%% 返回值：{?ok, UserId} | {?error, ErrorCode}
get_user_id_by_name(UserName) ->
    case lookup_name(UserName) of
        ?null -> {?error, ?TIP_COMMON_NO_THIS_PLAYER};
        {_, UserId} -> {?ok, UserId}
    end.

%% 通过平台账号名获取角色UserId
%% 返回值：{?ok, UserId} | {?error, ErrorCode}
get_user_id_by_account(Account) ->
    case lookup_account(Account) of
        ?null -> {?error, ?TIP_COMMON_NO_THIS_PLAYER};
        {_, UserId} -> {?ok, UserId}
    end.

%% 
%% get_lv(Player) ->
%% 	Info = get_info(Player),
%% 	Info#info.lv.
%% 
%% get_pro(Player) ->
%% 	Info = get_info(Player),
%% 	Info#info.pro.
%% 
%% get_sp_max(Player) ->
%% 	Lv = get_lv(Player),
%% 	Pro = get_pro(Player),
%% 	get_sp_max(Lv, Pro).
%% 读取当前等级的体力上限
get_sp_max(Lv, Pro) ->
    RecPlayerLevel = read_player_level(Lv, Pro),
    RecPlayerLevel#player_level.sp_max.

get_vip_lv(Player) when is_record(Player, player) ->
	get_vip_lv(get_info(Player));
get_vip_lv(Info) when is_record(Info, info) ->
	(Info#info.vip)#vip.lv.
set_vip_lv(Player, VipLv) ->
	Info	= get_info(Player),
	Vip		= Info#info.vip,
	Player#player{info = Info#info{vip = Vip#vip{lv = VipLv}}}.

get_honour(Player) when is_record(Player, player) ->
	Info = get_info(Player),
	Info#info.honour.
set_honour(Player, Hhonour) ->
	Info = get_info(Player),
	Player#player{info = Info#info{honour = Hhonour}}.

get_meritorious(Player) when is_record(Player, player) ->
	Info = get_info(Player),
	Info#info.meritorious.
set_meritorious(Player, Meritorious) ->
	Info = get_info(Player),
	Player#player{info = Info#info{meritorious = Meritorious}}.

get_skill_point(Player) when is_record(Player, player) ->
	Info = get_info(Player),
	Info#info.skill_point.
set_skill_point(Player, SkillPoint) ->
	Info = get_info(Player),
	Player#player{info = Info#info{skill_point = SkillPoint}}.

%% get_experience(Player) when is_record(Player, player) ->
%%     Info = get_info(Player),
%%     get_experience(Info);
%% get_experience(Info) when is_record(Info, info) ->
%%     Info#info.experience.
%% 
%% set_experience(Info, Experience) when is_record(Info, info) ->
%%     Info#info{experience = Experience};
%% set_experience(Player, Experience) when is_record(Player, player) ->
%%     Info  = get_info(Player),
%%     Info2 = set_experience(Info, Experience),
%%     set_info(Player, Info2).

get_see(Player) when is_record(Player, player) ->
    Info = get_info(Player),
    get_see(Info);
get_see(Info) when is_record(Info, info) ->
    Info#info.see.

set_see(Info, Experience) when is_record(Info, info) ->
    Info#info{see = Experience};
set_see(Player, Experience) when is_record(Player, player) ->
    Info  = get_info(Player),
    Info2 = set_see(Info, Experience),
    set_info(Player, Info2).
    
%% 读取player_level
read_player_level(Lv, Pro) ->
    data_player:get_player_level({Pro, Lv}).
%%=====================================封装==============================================
%% 获取first
player_online_data(#player{user_id      = UserId,
                           account      = Account,
						   serv_id		= ServId,
						   user_state   = UserState,
						   play_state   = PlayState,
						   team_id		= TeamId,
						   info         = Info,
						   attr_sum     = AttrSum,
						   buff         = Buff,
						   attr         = Attr,
						   equip        = Equip,
						   skill        = Skill,   
						   camp         = Camp,
						   position     = Position,
						   partner      = Partner,
						   guild        = Guild,
						   mind         = Mind,
						   partner_soul = PartnerSoul,
						   train		= Train,
						   sys_rank     = Sys,
                           style        = Style,
                           maps         = MapData,
                           horse        = HorseData,
						   lookfor		= LookforData,
						   weapon		= WeaponData
                           }) ->
    #player{user_id			= UserId,
            account         = Account,
			serv_id			= ServId,
			user_state		= UserState,
			play_state		= PlayState,
			team_id			= TeamId,
			info			= Info,
			attr_sum		= AttrSum,
			buff            = Buff,     
			attr            = Attr,
			equip           = Equip,
			skill           = Skill,   
			camp            = Camp,
			position        = Position,    
			partner         = Partner,
			guild           = Guild,
			mind            = Mind,
			partner_soul	= PartnerSoul,
			train			= Train,
			sys_rank		= Sys,
            style           = Style,
            maps            = MapData,
            horse           = HorseData,
			lookfor			= LookforData,
			weapon			= WeaponData};
player_online_data(X) -> ?MSG_ERROR("bad arg=~p", [X]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家回馈
insert_gm_msg(Player, Type, Content) ->
    UserId  = Player#player.user_id,
    Guild   = Player#player.guild,
    GuildId = Guild#guild.guild_id,
    case player_db_mod:insert_gm_msg(UserId, GuildId, Type, Content) of
        ?ok ->
            msg_sc_gm_return(?CONST_SYS_TRUE);
        _ ->
            msg_sc_gm_return(?CONST_SYS_FALSE)
    end.

immigrant(Player, ToServerId) when is_record(Player, player)->
    Account = Player#player.account,
    Info = Player#player.info,
    Name = Info#info.user_name,
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_PLAYER_MONEY, UserId) of
        [] ->
            ok;
        [Money] ->
            Cash = Money#money.cash_sum,
            case ets:lookup(?CONST_ETS_NODES_CONFIG, ToServerId) of
                [] ->
                    misc_packet:send_tips(UserId, ?TIP_COMMON_IMMIGRANT_NOT_EXIT);
                [NodeRec] ->
                    NodeName = NodeRec#cross_node_config.node_name,
                    Node = list_to_atom(NodeName),
                    case rpc:call(Node, ?MODULE, immigrant, [Account, ToServerId, Cash]) of
                        true ->
                            misc_packet:send_tips(UserId, ?TIP_COMMON_IMMIGRANT_SUCCESS),
                            Packet = msg_move_server_success(),
                            misc_packet:send(UserId, Packet),
                            admin_mod:do_forbid_login2(Name, "1", 1);
                        _ ->
                            misc_packet:send_tips(UserId, ?TIP_COMMON_MOVE_SERVER_FAILED)
                    end
            end
    end.

immigrant(Account,ServId, Cash) ->
    case ets:lookup(?CONST_ETS_PLAYER_ACCOUNT_2, {Account, ServId}) of
        [{_, UserId}] ->
            case check_online(UserId) of
                false ->false;
                _ ->
                    case player_money_api:deposit_2(UserId, Account, UserId, 0, Cash, misc:seconds(), ?CONST_DEPOSIT_USER_CHANGE_SERVER, ?CONST_COST_PLAYER_CHANGE_SERVER) of
                        ?ok -> 
                            true;
                        {?error, ErrorCode} ->
                            Packet = message_api:msg_notice(ErrorCode),
                            misc_packet:send(UserId, Packet),
                            false
                    end
            end;
        _ ->
            false
    end.



%% 获取玩家创建角色时间
get_reg_time(UserId) ->
	case mysql_api:select_execute(<<"SELECT `reg_time`",
									"FROM `game_user` WHERE ",
									 "`user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, [[RegTime]]} ->
			{?ok, RegTime};
		Error ->
		?MSG_ERROR("Error:~p",[Error]),
		{?error, ?TIP_COMMON_ERROR_DB}
	end.
%%==============================外网接口====================================================

%% 封号
user_ban(Player, 0) ->	%永久
	Info = 	Player#player.info,
	user_state_db(Player#player.user_id, ?CONST_SYS_USER_STATE_FORBID),
	{?ok, Player#player{state = 0, info = Info#info{ban_over = misc:seconds() + ?CONST_CHAT_FOREVER}}};
user_ban(Player, Duration) ->
	Info = 	Player#player.info,
	user_state_db(Player#player.user_id, ?CONST_SYS_USER_STATE_FORBID),
	{?ok, Player#player{state = 0, info = Info#info{ban_over = misc:seconds() + Duration}}}.

%% 解封
user_unban(Player) ->
	{?ok, Player#player{state = 1}}.

%% 更改玩家帐号状态
user_state_db(UserId, Type) ->
	case Type of
		?CONST_SYS_USER_STATE_FORBID ->
			player_db_mod:ban_user(UserId);
		?CONST_SYS_USER_STATE_NORMAL ->
			player_db_mod:unban_user(UserId)
	end.

%% 禁言
user_chat_ban(Player, 0) ->
	Info = Player#player.info,
	{?ok, Player#player{info = Info#info{chat_status = 1, shutup_over = misc:seconds() + ?CONST_CHAT_FOREVER}}};
user_chat_ban(Player, Duration) ->
	Info = Player#player.info,
	{?ok, Player#player{info = Info#info{chat_status = 1, shutup_over = misc:seconds() + Duration}}}.
%% 解除禁言
user_chat_unban(Player) ->
	Info = Player#player.info,
	{?ok, Player#player{info = Info#info{chat_status = 0}}}.
%%==============================tools====================================================
check_plus_exp(Info, Exp) ->
    Exp2 = Info#info.exp + Exp,
    MaxExp = data_player:get_player_max_exp(),
    if
        Exp2 =< MaxExp ->
            ?CONST_SYS_TRUE;
        ?true ->
            ?CONST_SYS_FALSE
    end.

%%==============================protocol====================================================
%% 1002 玩家登陆成功 
msg_player_login_ok(Flag, AppCipher, ResourceKey) ->
	misc_packet:pack(?MSG_ID_PLAYER_LOGIN_OK, ?MSG_FORMAT_PLAYER_LOGIN_OK, [Flag, AppCipher, ResourceKey]).
%% 1004 玩家登陆失败  
msg_player_login_error(Reason) ->
	misc_packet:pack(?MSG_ID_PLAYER_LOGIN_ERROR, ?MSG_FORMAT_PLAYER_LOGIN_ERROR, [Reason]).
%% 1006 玩家创建角色成功  
msg_player_create_ok() ->
	misc_packet:pack(?MSG_ID_PLAYER_CREAT_OK, ?MSG_FORMAT_PLAYER_CREAT_OK, []).
%% 1008 玩家创建角色失败  
msg_player_create_error(Reason) ->
	misc_packet:pack(?MSG_ID_PLAYER_CREAT_ERROR, ?MSG_FORMAT_PLAYER_CREAT_ERROR, [Reason]).

%% 闪断重连成功
msg_sc_reconnect_success(AppCipher) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_RECONNECT_SUCCESS, ?MSG_FORMAT_PLAYER_SC_RECONNECT_SUCCESS, [AppCipher]).

%% 闪断重连失败
msg_sc_reconnect_fail() ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_RECONNECT_FAIL, ?MSG_FORMAT_PLAYER_SC_RECONNECT_FAIL, []).

%% 1012 角色数据
msg_player_data_info(Player, Money, Type) ->
	Info			= Player#player.info,
	Guild			= Player#player.guild,
    Soul = Player#player.partner_soul,
    StarLv = Soul#partner_soul.star_lv,
    PositionId      = 
        case player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION) of
            ?true ->
            	PositionData	= Player#player.position,
            	PositionData#position_data.position;
            ?false ->
                0
        end,
	AttrDatas		= msg_attr(Player#player.attr),
	{OldTrainedForce, OldTrainedFate, OldTrainedMagic, 
	 NewTrainedForce, NewTrainedFate, NewTrainedMagic} = {Player#player.train,0,0,0,0,0},
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
    SkinStep    = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_STEP),
    SkinRide    = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_HORSE),
    CurMapInfo  = map_api:get_cur_map_info(Player),
	AttrBase	= [
				   Player#player.user_id,     
				   Player#player.serv_id,     
				   Player#player.state,       
				   player_api:get_vip_lv(Info),
				   
				   Info#info.user_name,     
				   Info#info.pro,
				   Info#info.sex,
				   CurMapInfo#map_info.map_id,     
				   CurMapInfo#map_info.x,
				   CurMapInfo#map_info.y,
				   Info#info.country,
				   Guild#guild.guild_id, 
				   Guild#guild.guild_name,
				   Guild#guild.guild_pos,
				   Info#info.lv,
				   
				   Info#info.exp,             
				   Info#info.expn,            
				   Info#info.hp,              
				   Info#info.sp,              
				   Info#info.sp_temp,
				   
				   Info#info.honour,
				   Info#info.meritorious,
				   Info#info.exploit,
				   Info#info.skill_point,
				   Info#info.power,
				   Info#info.anger,
				   PositionId,

				   SkinFashion, 
				   SkinWeapon,
				   SkinArmor,
				   SkinRide,
				   
				   Money#money.cash,
				   Money#money.cash_bind,
				   Money#money.cash_sum,
				   Money#money.gold_bind
				  ],
	AssistTuple = Info#info.assist_partner,
	FunAssist   = fun(Item) ->
						  {
						   Item
						  }
				  end,
	AssistList  = lists:map(FunAssist, misc:to_list(AssistTuple)),
	FurnaceList	= ctn_equip_api:get_part_list(Player#player.user_id),
	UserSpirit	= mind_api:get_user_mind_sum(Player, ?CONST_MIND_TYPE_PLAYER, Player#player.user_id),
	GrowRate	= Info#info.attr_rate,
    SpLimit     = player_vip_api:get_sp_limit(get_vip_lv(Info)),
	Partner		= Player#player.partner,
	FollowId	= Partner#partner_data.follow_id,
	VipHide		= goods_style_api:get_cur_style(Player, ?CONST_GOODS_ATTR_VIP),
	AttrTrain = 
		[
		 UserSpirit,
	   	 OldTrainedForce,
	     OldTrainedFate,
	     OldTrainedMagic,
		 NewTrainedForce,
		 NewTrainedFate,
		 NewTrainedMagic,
		 Info#info.current_title,
		 Info#info.experience,
         Info#info.cultivation,    % 修为
		 AssistList,
		 FurnaceList,
		 GrowRate,
         SpLimit,
         SkinWeapon,
         SkinFashion,
         SkinStep,
         Info#info.meritorioust,
		 FollowId,
         Money#money.cash_bind_2,
		 Type,
		 VipHide,
         StarLv
		],
	TempDatas		= misc:list_merge(AttrDatas, lists:reverse(AttrBase)),
	Datas			= misc:list_merge(AttrTrain, lists:reverse(TempDatas)),
	misc_packet:pack(?MSG_ID_PLAYER_DATA_INFO, ?MSG_FORMAT_PLAYER_DATA_INFO, Datas).

%% a/b
%%[Type]
msg_sc_ab(Type) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_AB, ?MSG_FORMAT_PLAYER_SC_AB, [Type]).

%% 1020 玩家单个属性更新
msg_player_attr_update(Type, TypeId, Value)->
	case Type =:= 1 of
		?true ->
%% 			?MSG_ERROR("Packet to update attr TypeId ~p, Value ~p", [TypeId, Value]),
			misc_packet:pack(?MSG_ID_PLAYER_ATTR_UPDATE, ?MSG_FORMAT_PLAYER_ATTR_UPDATE, [TypeId, Value]);
		?false ->
			misc_packet:pack(?MSG_ID_PARTNER_SC_ATTR_UPDATE, ?MSG_FORMAT_PARTNER_SC_ATTR_UPDATE, [Type,TypeId,Value])
	end.

%% 1022 	玩家单个属性更新(字符串)
msg_player_attr_update_str(TypeId, Value)->
	misc_packet:pack(?MSG_ID_PLAYER_ATTR_UPDATE_STR, ?MSG_FORMAT_PLAYER_ATTR_UPDATE_STR, [TypeId, Value]).

%% 1024 	更新货币 
msg_player_sc_update_money(DataList) ->
	msg_player_update_money(DataList, <<>>).
msg_player_update_money([{Type, Value}|DataList], Acc) when is_number(Type) ->
	Packet	= misc_packet:pack(?MSG_ID_PLAYER_SC_UPDATE_MONEY, ?MSG_FORMAT_PLAYER_SC_UPDATE_MONEY, [Type, Value]),
	msg_player_update_money(DataList, <<Acc/binary, Packet/binary>>);
msg_player_update_money([_Data|DataList], Acc) ->
	msg_player_update_money(DataList, Acc);
msg_player_update_money([], Acc) -> Acc.

%% 更新VIP信息
%%[VipLv,CashSum,{Vip}]
msg_player_sc_vip_info(CashSum, Vip) ->
	Datas	= [{VipLv} || VipLv <- Vip#vip.gift],
	misc_packet:pack(?MSG_ID_PLAYER_SC_VIP_INFO, ?MSG_FORMAT_PLAYER_SC_VIP_INFO, [Vip#vip.lv,CashSum,Datas]).

%% 官衔升级
msg_player_sc_upgrade(PositionId) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_UPGRADE, ?MSG_FORMAT_PLAYER_SC_UPGRADE, [PositionId]).

%% 官衔信息 
msg_player_sc_position_info(TotalMeritorious) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_POSITION_INFO, ?MSG_FORMAT_PLAYER_SC_POSITION_INFO, [TotalMeritorious]).

%% 购买体力信息
%%[BoughtTimes,NextCash]
msg_sc_buy_sp_info(BoughtTimes,NextCash) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_BUY_SP_INFO, ?MSG_FORMAT_PLAYER_SC_BUY_SP_INFO, [BoughtTimes,NextCash]).

%% 返回BUFF列表信息
%%[{BuffId,BuffType,BuffValue,Time}]
msg_sc_buff_info(BuffList) ->
    F = fun(#buff{buff_id = BuffId, buff_type = BuffType, buff_value = BuffValue, expend_value = Time}, OldList) ->
                [{BuffId, BuffType, BuffValue, Time}|OldList]
        end,
    List    	= lists:foldl(F, [], BuffList),
    misc_packet:pack(?MSG_ID_PLAYER_SC_BUFF_INFO, ?MSG_FORMAT_PLAYER_SC_BUFF_INFO, [List]).

%% 插入BUFF通知
%%[BuffId,BuffType,BuffValue,Time]
msg_sc_buff_insert(BuffId,BuffType,BuffValue,Time) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_BUFF_INSERT, ?MSG_FORMAT_PLAYER_SC_BUFF_INSERT, [BuffId,BuffType,BuffValue,Time]).

%% 移除BUFF通知
%%[BuffId, BuffType]
msg_sc_buff_delete(BuffId, BuffType) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_BUFF_DELETE, ?MSG_FORMAT_PLAYER_SC_BUFF_DELETE, [BuffId, BuffType]).


%% 已领取礼包信息
msg_sc_get_gift_info(Gifts) ->
	Datas	= [{GiftsType} || GiftsType <- Gifts],
	misc_packet:pack(?MSG_ID_PLAYER_SC_GET_GIFT_INFO, ?MSG_FORMAT_PLAYER_SC_GET_GIFT_INFO, [Datas]).

%% 旧服玩家礼包（再战沙场）
%%[Flag]
msg_sc_old_server_user(Flag) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_OLD_SERVER_USER, ?MSG_FORMAT_PLAYER_SC_OLD_SERVER_USER, [Flag]).

%% 返回隐藏皮肤状态
msg_sc_hide_skin_info(Type,State) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_HIDE_SKIN_INFO, ?MSG_FORMAT_PLAYER_SC_HIDE_SKIN_INFO, [Type,State]).

%% 防沉迷通知
msg_sc_fcm_notice(FcmState,Time,IsShow) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_FCM_NOTICE, ?MSG_FORMAT_PLAYER_SC_FCM_NOTICE, [FcmState,Time,IsShow]).
%% 提交防沉迷返回信息
msg_sc_fcm_submit_info(Result) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_FCM_SUBMIT_INFO, ?MSG_FORMAT_PLAYER_SC_FCM_SUBMIT_INFO, [Result]).
%% 防沉迷离线通知
msg_sc_fcm_offline_notice() ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_FCM_OFFLINE_NOTICE, ?MSG_FORMAT_PLAYER_SC_FCM_OFFLINE_NOTICE, []).
%% 当前修为值
msg_sc_culti_now(Culti) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_CULTI_NOW, ?MSG_FORMAT_PLAYER_SC_CULTI_NOW, [Culti]).

%% 是体验服
%%[]
msg_sc_test_server() ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_TEST_SERVER, ?MSG_FORMAT_PLAYER_SC_TEST_SERVER, []).

%% 时间同步协议
msg_player_sc_tsp(Time) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_TSP, ?MSG_FORMAT_PLAYER_SC_TSP, [Time]).

%% 2000 重复登录通知 
msg_player_repeat_login() ->
	misc_packet:pack(?MSG_ID_PLAYER_REPEAT_LOGIN, ?MSG_FORMAT_PLAYER_REPEAT_LOGIN, []).

%% 属性列表
msg_attr(Attr) ->
	AttrSecond	= Attr#attr.attr_second,
	AttrElite	= Attr#attr.attr_elite,
	[% 一级属性(3/3)
	 Attr#attr.force,
	 Attr#attr.fate,
	 Attr#attr.magic,
	 % 二级属性(6/6)
	 AttrSecond#attr_second.hp_max,
	 AttrSecond#attr_second.speed,
	 AttrSecond#attr_second.force_attack,
	 AttrSecond#attr_second.magic_attack,
	 AttrSecond#attr_second.force_def,
	 AttrSecond#attr_second.magic_def,
	 
	 % 精英属性(14/28)
	 AttrElite#attr_elite.hit		 ,
	 AttrElite#attr_elite.dodge		 ,
	 AttrElite#attr_elite.crit		 ,
	 AttrElite#attr_elite.parry		 ,
	 AttrElite#attr_elite.resist	 ,  
	 AttrElite#attr_elite.crit_h	 ,
	 AttrElite#attr_elite.r_crit	 ,
	 AttrElite#attr_elite.parry_r_h  ,  
	 AttrElite#attr_elite.r_parry	 ,
	 AttrElite#attr_elite.resist_h	 ,
	 AttrElite#attr_elite.r_resist	 ,
	 AttrElite#attr_elite.r_crit_h	 ,
	 AttrElite#attr_elite.i_parry_h	 ,
	 AttrElite#attr_elite.r_resist_h 
	].

msg_attr_change(Type,AttrOld,AttrNew) ->
	Force 		= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_FORCE, 	AttrOld#attr.force, AttrNew#attr.force),
	Fate		= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_FATE,	AttrOld#attr.fate,	AttrNew#attr.fate),
	Magic 		= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_MAGIC, 	AttrOld#attr.magic, AttrNew#attr.magic),
	AttrSecond	= msg_attr_second_change(Type,AttrOld#attr.attr_second, AttrNew#attr.attr_second),
	AttrElite	= msg_attr_elite_change(Type,AttrOld#attr.attr_elite, AttrNew#attr.attr_elite),
	<<Force/binary, Fate/binary, Magic/binary, AttrSecond/binary, AttrElite/binary>>.

msg_attr_second_change(Type,AttrSecondOld, AttrSecondNew) ->
	HpMax		= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_HP_MAX, 	  AttrSecondOld#attr_second.hp_max,  	  AttrSecondNew#attr_second.hp_max),
	Speed		= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_SPEED, 		  AttrSecondOld#attr_second.speed, 		  AttrSecondNew#attr_second.speed),
	ForceAttack	= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_FORCE_ATTACK, AttrSecondOld#attr_second.force_attack, AttrSecondNew#attr_second.force_attack),
	MagicAttack	= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, AttrSecondOld#attr_second.magic_attack, AttrSecondNew#attr_second.magic_attack),
	ForceDef	= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_FORCE_DEF,    AttrSecondOld#attr_second.force_def, 	  AttrSecondNew#attr_second.force_def),
	MagicDef	= ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_MAGIC_DEF,    AttrSecondOld#attr_second.magic_def, 	  AttrSecondNew#attr_second.magic_def),
	<<HpMax/binary, Speed/binary, ForceAttack/binary, MagicAttack/binary, ForceDef/binary, MagicDef/binary>>.

msg_attr_elite_change(Type,AttrEliteOld, AttrEliteNew) ->
	Hit                   = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_HIT,        AttrEliteOld#attr_elite.hit        , AttrEliteNew#attr_elite.hit	   ),
	Dodge                 = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_DODGE,      AttrEliteOld#attr_elite.dodge      , AttrEliteNew#attr_elite.dodge     ),    
	Crit                  = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_CRIT,       AttrEliteOld#attr_elite.crit       , AttrEliteNew#attr_elite.crit	   ),
	Parry                 = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_PARRY,      AttrEliteOld#attr_elite.parry      , AttrEliteNew#attr_elite.parry	   ),    
	Resist			      = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_RESIST,     AttrEliteOld#attr_elite.resist	   , AttrEliteNew#attr_elite.resist	   ),
	CritHurt		      = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_CRIT_H,     AttrEliteOld#attr_elite.crit_h	   , AttrEliteNew#attr_elite.crit_h	   ),    
	ReduceCrit	          = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_R_CRIT,     AttrEliteOld#attr_elite.r_crit	   , AttrEliteNew#attr_elite.r_crit	   ),
	ParryReduceHurt       = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_PARRY_R_H,  AttrEliteOld#attr_elite.parry_r_h  , AttrEliteNew#attr_elite.parry_r_h ),
	ReduceParry	          = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_R_PARRY,    AttrEliteOld#attr_elite.r_parry    , AttrEliteNew#attr_elite.r_parry   ),
	ResistHurt	          = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_RESIST_H, 	AttrEliteOld#attr_elite.resist_h   , AttrEliteNew#attr_elite.resist_h  ),
	ReduceResist	      = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_R_RESIST,   AttrEliteOld#attr_elite.r_resist   , AttrEliteNew#attr_elite.r_resist  ),    
	ReduceCritHurt        = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_R_CRIT_H,   AttrEliteOld#attr_elite.r_crit_h   , AttrEliteNew#attr_elite.r_crit_h  ),
	IgnoreParryReduceHurt = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_I_PARRY_H,  AttrEliteOld#attr_elite.i_parry_h  , AttrEliteNew#attr_elite.i_parry_h ), 
	ReduceResistHurt      = ?MSG_ATTR_CHANGE(Type, ?CONST_PLAYER_ATTR_E_R_RESIST_H, AttrEliteOld#attr_elite.r_resist_h , AttrEliteNew#attr_elite.r_resist_h), 
	<<Hit/binary,          Dodge/binary,          Crit/binary,                  Parry/binary,       Resist/binary,
	  CritHurt/binary,     ReduceCrit/binary,     ParryReduceHurt/binary,       ReduceParry/binary, ResistHurt/binary,
	  ReduceResist/binary, ReduceCritHurt/binary, IgnoreParryReduceHurt/binary, ReduceResistHurt/binary>>.

%% 返回开启模块列表
%%[SysId]
msg_sc_open_sys_info(SysId) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_OPEN_SYS_INFO, ?MSG_FORMAT_PLAYER_SC_OPEN_SYS_INFO, [SysId]).

%% 开启模块通知
%%[SysId]
msg_sc_open_sys_notice(SysId) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_OPEN_SYS_NOTICE, ?MSG_FORMAT_PLAYER_SC_OPEN_SYS_NOTICE, [SysId]).

%% 记录首次消费
first_consume(Player, []) ->
	{?ok, Player#player{info = (Player#player.info)#info{first_consume = ?CONST_SYS_TRUE}}}.

%% VIP礼包信息
%%[{Vip}]
msg_sc_gift_vip_info(Vip) ->
	Datas	= [{VipLv} || VipLv <- Vip#vip.gift],
	misc_packet:pack(?MSG_ID_PLAYER_SC_GIFT_VIP_INFO, ?MSG_FORMAT_PLAYER_SC_GIFT_VIP_INFO, [Datas]).

%% VIP日常奖励信息
%%[Flag]
msg_player_sc_vip_daily_info(Vip) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_VIP_DAILY_INFO, ?MSG_FORMAT_PLAYER_SC_VIP_DAILY_INFO, [Vip#vip.daily]).

%% 打开祭星系统
%%[Flag]
msg_player_sc_open_culti(Flag) ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_OPEN_CULTI, ?MSG_FORMAT_PLAYER_SC_OPEN_CULTI, [Flag]).

%%[IsCan,Count]
msg_is_can_get_test_award(IsCan,Count) ->
    misc_packet:pack(?MSG_ID_PLAYER_IS_CAN_GET_TEST_AWARD, ?MSG_FORMAT_PLAYER_IS_CAN_GET_TEST_AWARD, [IsCan,Count]).

%% gm返回
%%[Result]
msg_sc_gm_return(Result) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_GM_RETURN, ?MSG_FORMAT_PLAYER_SC_GM_RETURN, [Result]).

%% 使用外挂掉线通知
msg_sc_illegal_notice() ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_ILLEGAL_NOTICE, ?MSG_FORMAT_PLAYER_SC_ILLEGAL_NOTICE, []).

%% 体力不足，前端要作提示，所以另外加了一个消息
msg_sc_not_enough_sp() ->
	misc_packet:pack(?MSG_ID_PLAYER_SC_NOT_ENOUGH_SP, ?MSG_FORMAT_PLAYER_SC_NOT_ENOUGH_SP, []).
    
%% 改名结果
%%[IsOk]
msg_is_ok(IsOk) ->
    misc_packet:pack(?MSG_ID_PLAYER_IS_OK, ?MSG_FORMAT_PLAYER_IS_OK, [IsOk]).

%% 改名标志
%%[IsName,IsGuildName]
msg_sc_change_name_flags(IsName,IsGuildName) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_CHANGE_NAME_FLAGS, ?MSG_FORMAT_PLAYER_SC_CHANGE_NAME_FLAGS, [IsName,IsGuildName]).

%% 新手流程进度
%%[Step]
msg_sc_newbie_step(Step) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_NEWBIE_STEP, ?MSG_FORMAT_PLAYER_SC_NEWBIE_STEP, [Step]).

% 一骑讨排名
msg_sc_arena_rank(UserId, Rank) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_ARENA_RANK, ?MSG_FORMAT_PLAYER_SC_ARENA_RANK, [UserId, Rank]).

msg_move_server_success() ->
    misc_packet:pack(?MSG_ID_PLAYER_MOVE_SERVER_SUCCESS, ?MSG_FORMAT_PLAYER_MOVE_SERVER_SUCCESS, []).
%% 返回体验服数据
%%[TestServerStart,TestServerEnd,NormalServerStart,SumCash,GiveCash]
msg_sc_test_server_info(TestServerStart,TestServerEnd,NormalServerStart,SumCash,GiveCash) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_TEST_SERVER_INFO, ?MSG_FORMAT_PLAYER_SC_TEST_SERVER_INFO, [TestServerStart,TestServerEnd,NormalServerStart,SumCash,GiveCash]).
%% 世界等级
%%[Rate]
msg_sc_world_lv(Rate) ->
    misc_packet:pack(?MSG_ID_PLAYER_SC_WORLD_LV, ?MSG_FORMAT_PLAYER_SC_WORLD_LV, [Rate]).