%% Author: Administrator
%% Created: 2013-4-15
%% Description: TODO: Add description to party_mod
-module(party_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([
		 battle_start/2,
		 battle_over/3,
		 refresh_monster/3,
		 enter/1,quit/1,
		 open_box/2,
		 
		 init/1,set_hp_tuple/2,
		 get_party_active/0,set_party_active/1,
		 get_party_player/1,
		
		 auto_reward/2,
		 set_active_auto/1, auto_party/3,
		 auto_send_reward/2,
		 request_get_sp/1,
		 set_auto_pk/2,
		 request_pk/2,
		 reply_pk/3
		 ]).

-export([
		 play_start_handle/1,play_end_handle/1,  
		 add_exp_handle/1,add_sp_handle/1,
		 add_exp_cb/2,add_sp_cb/2,
		 refresh_monster_handle/6,
		 refresh_monster_hp_handle/1,
		 set_auto_player_cb/2,
		 auto_reward_cb/2,
		 battle_over_cb/2,
		 present_reward_handle/2,
		 present_box_reward_cd/2,
		 present_monster_reward_cd/2,
		 battle_reward_cd/2,
		 pk_start_cb/2
		 ]).

-export([
		 save_activity_data/1,
		 save_doll_data/1,
		 set_doll/3,
		 set_doll/4,
		 auto_start/1,
		 set_doll_data/1,
		 auto_end/1,
		 flush_offline/2,
		 doll_reward_cb/2,
		 is_doll/1,
		 pack_set_doll_data/1,
		 get_doll_list/0,
		 quit_guild/1
		 ]).

%%
%% API Functions
%%

%%
%% Local Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 机器人   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 关服保存军团宴会活动数据
save_activity_data(PartyActive) ->
	case mysql_api:select(<<"replace into `game_activity_record`(`activity_id`,`record`)value('", (misc:to_binary(PartyActive#party_active.id))/binary, 
							"',", (mysql_api:encode(PartyActive))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 关服保存军团宴会替身数据
save_doll_data(PartyDoll) ->
    case mysql_api:select(<<"replace into `game_party_doll`(`user_id`,`record`)value('", (misc:to_binary(PartyDoll#party_doll.user_id))/binary, 
							"',", (mysql_api:encode(PartyDoll))/binary, ");">>) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%% 设置替身
set_doll(#player{user_id = UserId, info = Info} = Player, Type, 1) ->
	try
		ActId			= get_activity_id(get_active_flag()),
		UserName 		= (Player#player.info)#info.user_name,
		?ok				= check_party_is_not_open(),
		{?ok, GuildId}	= check_guild(Player),
		?ok				= check_guild_lv(GuildId),
		{?ok, _Player2}	= check_player_play(Player),
		?CONST_SYS_TRUE = robot_api:is_open_robot(party),
		Date 			= get_date_by_type(Type),
		?ok				= check_party_is_over(Date),
		case player_money_api:minus_money_sp(UserId, ?CONST_SYS_CASH, ?CONST_GUILD_PARTY_AUTO_COST, ?CONST_COST_PARTY_AUTO) of
			{?error, ErrorCode} ->
				?MSG_ERROR("set party doll error:~w", [ErrorCode]),
				throw({?error, ?TIP_GUILD_PARTY_DOLL_FAIL});
			{_CashBindValue, CashBind2Value, CashValue} ->
				{PartyIds, Bcash2, Cash2} =
					case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
						?null ->
							{[{Date, ActId}], CashBind2Value, CashValue};
						#party_doll{party_ids = Ids, bcash = Bcash, cash = Cash} ->
							case lists:keyfind(Date, 1, Ids) of
								?false ->
									{[{Date, ActId}|Ids], Bcash + CashBind2Value, Cash + CashValue};
								{Date, ActId} ->
									{Ids, Bcash, Cash}
							end
					end,
				Lv = Info#info.lv,
				VipLv = (Info#info.vip)#vip.lv,
				NewPartyDoll = #party_doll{
										   user_id	= UserId,
										   lv		= Lv,
										   vip_lv	= VipLv,
										   user_name= UserName,
										   party_ids= PartyIds,
										   guild_id	= GuildId,
										   bcash	= Bcash2,
										   cash		= Cash2
										  },
				ets_api:insert(?CONST_ETS_PARTY_DOLL, NewPartyDoll),
				throw({?error, ?TIP_GUILD_PARTY_DOLL_SUCCESS})
		end
	catch
		throw:{?error, TipCode} ->
			TipPacket = message_api:msg_notice(TipCode),
			misc_packet:send(UserId, TipPacket);
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stackstrace:~w", [E, R, erlang:get_stacktrace()])
	end;
%% 取消替身
set_doll(Player, Type, 0) ->
	set_doll(Player, Type, 0, normal).

set_doll(#player{user_id = UserId} = Player, Type, 0, Opt) ->
	try
		ActId = get_activity_id(get_active_flag()),
		case Opt of
			quit_guild ->
				?ok;
			_ ->
				?ok	= check_party_is_not_open()
		end,
		case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
			?null ->
				?ok;
			#party_doll{party_ids = Ids, bcash = Bcash, cash = Cash} ->
				Date = get_date_by_type(Type),
				case lists:member({Date, ActId}, Ids)of
					?false ->
						?ok;
					?true ->
						{Bcash2, Cash2, Bcash3, Cash3} = 
							if
								Bcash >= ?CONST_SPRING_AUTO_COST ->
									{Bcash - ?CONST_SPRING_AUTO_COST, Cash, ?CONST_SPRING_AUTO_COST, 0};
								Bcash > 0 ->
									Rest = ?CONST_SPRING_AUTO_COST - Bcash,
									{0, Cash - Rest, Bcash, Rest};
								Cash >= ?CONST_SPRING_AUTO_COST ->
									{Bcash, Cash - ?CONST_SPRING_AUTO_COST, 0, ?CONST_SPRING_AUTO_COST};
								?true ->
									{Bcash, Cash, Bcash, Cash}
							end,
						update_party_doll(UserId, lists:delete({Date, ActId}, Ids), Bcash2, Cash2),
						case Opt of
							quit_guild ->
								{Opt, {Bcash3, Cash3}};
							_ ->
								handler_result(Player, [Opt, {Bcash3, Cash3}]),
								{Opt, 0}
						end
				end
		end
	catch
		throw:{?error, TipCode} ->
			TipPacket = message_api:msg_notice(TipCode),
			misc_packet:send(UserId, TipPacket);
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stackstrace:~w", [E, R, erlang:get_stacktrace()])
	end.

%% 处理结果
handler_result(#player{user_id = UserId, info = Info}, [Opt, {Bcash, Cash}]) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_PARTY_AUTO) of
		{?error, ErrorCode} ->
			?MSG_ERROR("cancel party doll plus money error:~w", [ErrorCode]),
			throw({?error, ?TIP_GUILD_PARTY_DOLL_FAIL});
		?ok ->
			case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, Bcash, ?CONST_COST_PARTY_AUTO) of
				{?error, ErrorCode} ->
					?MSG_ERROR("cancel party doll plus money error:~w", [ErrorCode]),
					throw({?error, ?TIP_GUILD_PARTY_DOLL_FAIL});
				?ok ->
					case Opt of
						quit_guild ->
							mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PARTY_DOLL_TIPS,
															  [{[{misc:to_list(Cash)}]}], [], 0, 0, 0, ?CONST_COST_PARTY_LEAVE_GUILD);
						_ ->
							?ok
					end,
					Packet = message_api:msg_notice(?TIP_GUILD_PARTY_DOLL_CANCEL, [], [], 
													[{?TIP_SYS_COMM,misc:to_list(Cash)}]),
					misc_packet:send(UserId, Packet)
			end
	end.

%% 根据类型获取日期
get_date_by_type(Type) ->
	{NowDate, _}	= misc:date_time(),
	{NextDate, _}	= misc:seconds_to_localtime(misc:get_next_day_seconds(misc:seconds())),
	case Type of
		?CONST_GUILD_PARTY_DOLL_TODAY ->
			NowDate;
		?CONST_GUILD_PARTY_DOLL_TOMORROW ->
			NextDate
	end.

%% 根据日期获取类型
get_type_by_date(UserId, Date, ActId, Ids) ->
	{NowDate, _}	= misc:date_time(),
	{NextDate, _}	= misc:seconds_to_localtime(misc:get_next_day_seconds(misc:seconds())),
	case Date of
		NowDate ->
			?CONST_GUILD_PARTY_DOLL_TODAY;
		NextDate ->
			?CONST_GUILD_PARTY_DOLL_TOMORROW;
		_ ->
			update_party_doll(UserId, lists:delete({Date, ActId}, Ids)),
			?MSG_ERROR("get type by date error UserId:~w", [UserId]),
			2		%% 错误，当天活动没进行导致
	end.

%% 替身自动参加活动
auto_start(Flag) ->
	List = get_doll_list(),
	[player_api:process_send(UserId, ?MODULE, set_auto_player_cb, [Flag]) || #party_doll{user_id = UserId} <- List].

%% 设置机器人数据
set_doll_data(#player{user_id = UserId, guild = Guild} = Player) ->
	GuildId = Guild#guild.guild_id,
	PartyPlayer		= init_party_player(Player),
	PartyData		= init_party_data(GuildId),
	PartyPlayer2	= PartyPlayer#party_player{enter_time = misc:seconds(), guild_id = GuildId, exist = ?CONST_SYS_TRUE},
	MemberList		= add_enter_list(PartyData#party_data.member_list, UserId),
	PartyData2		= PartyData#party_data{member_list = MemberList},
	set_party_player(PartyPlayer2),
	set_party_data(PartyData2).

%% 活动结束，替身结算
auto_end(Flag) ->
	List = get_doll_list(),
	doll_auto_reward(List, misc:seconds(), Flag),
	F = fun(#party_doll{user_id = UserId, map_pid = MapPid}) ->
				map_api:exit_map(#player{user_id = UserId, map_pid = MapPid}, ?CONST_MAP_PTYPE_PARTY_ROBOT),
				ets_api:delete(?CONST_ETS_MAP_PLAYER, {?CONST_MAP_PTYPE_PARTY_ROBOT, UserId})
		end,
	[F(Rec) || Rec <- List].

%% 自动参加奖励
doll_auto_reward([], _, _Flag) -> ?ok;
doll_auto_reward([#party_doll{user_id = UserId, lv = Lv, vip_lv = VipLv, party_ids = PartyIds}|List], Time, Flag) ->
	clean_party_doll(UserId, Flag),		%% 清除活动id
	case get_party_player(UserId) of
		?null ->
			doll_auto_reward(List, Time, Flag);
		_PartyPlayer ->
        	{?ok, Exp, Sp} = get_rec_doll_award(Lv, VipLv),
			case player_api:check_online(UserId) of
				?true ->
					player_api:process_send(UserId, ?MODULE, doll_reward_cb, [Flag, PartyIds, Exp, Sp]);
				_ ->
					player_offline_api:offline(?MODULE, UserId, {Time, Flag, Exp, Sp})
			end,
			doll_auto_reward(List, Time, Flag)
	end.

%% 玩家上线时操作，需要立即操作的逻辑不能放这里
flush_offline(Player, Arg) when is_list(Arg) ->
	try
		handler_result(Player, Arg)
	catch
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stacktrace:~p", [E, R, erlang:get_stacktrace()])
	end;
flush_offline(Player, {Time, Flag, Exp, Sp}) ->
	{?ok, Player2} = doll_send_reward(Player, Flag, Exp, Sp),
	{?ok, Player3} = 
		case misc:is_same_date(misc:seconds(), Time) of
			?true ->
				add_guide_times(Player2);		%% 目标
			?false ->
				{?ok, Player2}
		end,
	achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_GUILD_PARTY, 0, 1).

%% 替身参加发送奖励
doll_reward_cb(Player, [Flag, PartyIds, Exp, Sp]) ->
	case lists:member(get_now_key(), PartyIds) of
		?false ->
			{?ok, Player};
		?true ->
			doll_send_reward(Player, Flag, Exp, Sp)
	end.

%% 替身参加发送奖励
doll_send_reward(Player = #player{info = Info}, _Flag, Exp, Sp) ->
	try
		{?ok, Player2} 	= player_api:exp(Player, Exp),
		{?ok, Player3} 	= player_api:plus_sp(Player2, Sp, ?CONST_COST_PARTY_AUTO_SP),
		mail_api:send_system_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_PARTY_DOLL,
										  [{[{misc:to_list(Exp)}]}, {[{misc:to_list(Sp)}]}], [], 0, 0, 0, ?CONST_COST_PARTY_AUTO_SP),
		{?ok ,Player4}	= schedule_api:add_guide_times(Player3, ?CONST_SCHEDULE_GUIDE_GUILD_PARTY),
		achievement_api:add_achievement(Player4, ?CONST_ACHIEVEMENT_GUILD_PARTY, 0, 1)
	catch
		_:_ ->
			{?ok,Player}
	end.

%% 清理数据
clean_party_doll(UserId, _Flag) ->
	case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
		?null ->
			?ok;
		#party_doll{party_ids = Ids} ->
			update_party_doll(UserId, lists:delete(get_now_key(), Ids))
	end.

%% 更新替身数据
update_party_doll(UserId, PartyIds) ->
	case PartyIds of
		[] ->
			ets_api:delete(?CONST_ETS_PARTY_DOLL, UserId);
		_ ->
			ets_api:update_element(?CONST_ETS_PARTY_DOLL, UserId, [{#party_doll.party_ids, PartyIds}])
	end.
update_party_doll(UserId, PartyIds, Bcash, Cash) ->
	case PartyIds of
		[] ->
			ets_api:delete(?CONST_ETS_PARTY_DOLL, UserId);
		_ ->
			ets_api:update_element(?CONST_ETS_PARTY_DOLL, UserId, [
																   {#party_doll.party_ids, PartyIds},
																   {#party_doll.bcash, Bcash},
																   {#party_doll.cash, Cash}
																  ])
	end.
%% 判定是否是替身（当天）
is_doll(UserId) ->
	case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
		?null ->
			?false;
		#party_doll{party_ids = Ids} ->
			lists:member(get_now_key(), Ids)
	end.					

%% 打包替身回包数据
pack_set_doll_data(UserId) ->
	Default = [{?CONST_GUILD_PARTY_DOLL_TODAY, 0}, {?CONST_GUILD_PARTY_DOLL_TOMORROW, 0}],
	List =
		case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
			?null ->
				Default;
			#party_doll{party_ids = Ids} ->
				F = fun({Date, ActId}, Acc) ->
							Type = get_type_by_date(UserId, Date, ActId, Ids),
							lists:keyreplace(Type, 1, Acc, {Type, 1})
					end,
				lists:foldl(F, Default, Ids)
		end,
	party_api:msg_sc_doll(List).

%% 获取活动标识
get_active_flag() ->
	case get_party_active() of
		?null ->
			1;
		PartyActive ->
			PartyActive#party_active.flag
	end.

%% 获取活动id
get_activity_id(Flag) ->
	case Flag of
		1 ->
			?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY;
		_ ->
			?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY
	end.

%% 获取活动信息key（当天）
get_now_key() ->
	ActId = get_activity_id(get_active_flag()),
	{NowDate, _} = misc:date_time(),
	{NowDate, ActId}.

%% 获取有效的替身列表
get_doll_list() ->
	Pred = fun(#party_doll{party_ids = Ids}) -> lists:member(get_now_key(), Ids) end,
	lists:filter(Pred, ets_api:list(?CONST_ETS_PARTY_DOLL)).

%% 退出军团
quit_guild(#player{user_id = UserId} = Player) ->
	TypeList =
		case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
			?null ->
				[];
			#party_doll{party_ids = Ids} ->
				case lists:member(get_now_key(), Ids) of
					?true ->
						case catch check_party_open() of
							{?ok, _PartyActive} ->
								[?CONST_GUILD_PARTY_DOLL_TOMORROW];
							_ ->
								[?CONST_GUILD_PARTY_DOLL_TODAY, ?CONST_GUILD_PARTY_DOLL_TOMORROW]
						end;
					?false ->
						[?CONST_GUILD_PARTY_DOLL_TOMORROW]
				end
		end,
	F = fun(Type, {Acc1, Acc2}) ->
				case set_doll(Player, Type, 0, quit_guild) of
					{quit_guild, {Bcash, Cash}} ->
						{Acc1 + Bcash, Acc2 + Cash};
					_ ->
						{Acc1, Acc2}
				end
		end,
	{Result1, Result2} = lists:foldl(F, {0,0}, TypeList),
	case Result1 =/= 0 orelse Result2 =/= 0 of
		?true ->
			case player_api:check_online(UserId) of
				?true ->
					handler_result(Player, [quit_guild, {Result1, Result2}]);
				?false ->
					player_offline_api:offline(?MODULE, UserId, [quit_guild, {Result1, Result2}])
			end;
		?false ->
			?ok
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 战斗开始
battle_start(Player = #player{user_state = ?CONST_PLAYER_STATE_FIGHTING},_Id) ->
	{?ok, Player};
battle_start(Player,Id)  ->
	case check_battle_start(Player,Id) of 
		{?ok, PartyData,PartyMonster} ->
			case battle_api:start(Player, PartyMonster#party_monster.monster_id,
								  #param{battle_type	= ?CONST_BATTLE_PARTY,
										 ad1			= 0,
										 ad2 			= PartyMonster#party_monster.id,		%% 怪物唯一id
										 ad3 			= PartyMonster#party_monster.hp_tuple 	%% 血量组
										}) of
				{?ok, Player2} ->
					set_party_data(PartyData),
					{?ok, Player2};
				{?error, ErrorCode} -> 
					{?error, ErrorCode}
			end;
		{?error, ?TIP_PARTY_IN_BATTLE} -> 
			{?ok, Player};
		{?error, ErrorCode} -> 
			{?error, ErrorCode}
	end.

%% 检查战斗开始
check_battle_start(Player, Id) ->
	try
		UserId				= Player#player.user_id,
		Time				= misc:seconds(),
		?ok					= check_party_start(Time),	
		{?ok, PartyPlayer}	= check_party_player(UserId),
		PartyData			= get_party_data(PartyPlayer#party_player.guild_id),	
		{?ok, PartyMonster}	= check_party_monster(PartyData, Id),
		BattleList			= PartyMonster#party_monster.battle_list,
		{?ok,BattleList2}	= check_monster_battle_count(UserId,BattleList),
		PartyMonster2		= PartyMonster#party_monster{battle_list = BattleList2},
		PartyData2			= set_party_monster(PartyData,PartyMonster2),
		{?ok,PartyData2,PartyMonster2}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Stacktrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 检查怪物挑战人数
check_monster_battle_count(UserId,List) -> 
	case lists:member(UserId, List) of
		?false when length(List) < 5 -> 
			{?ok,[UserId | List]};
		?false -> 
			throw({?error,?TIP_PARTY_MONSTER_BATTLE_FULL});   
		_ ->
			throw({?error,?TIP_PARTY_IN_BATTLE}) 
	end.
			

%% 检查怪物
check_party_monster(PartyData, Id) ->
	case get_party_monster(PartyData, Id) of
		{?ok,PartyMonster} ->
			{?ok,PartyMonster};
		{?error,_ErrorCode} ->
			throw({?error, ?TIP_PARTY_MONSTER_DEAD})% 怪物已经死亡
	end.

%% 检查宴会是否开始
check_party_start(Time) ->
	case get_party_active() of
		#party_active{start_time = StartTime, end_time = EndTime} ->
			if
				Time > StartTime andalso Time < EndTime -> ?ok;
				?true ->
				throw({?error,?TIP_PARTY_OVER})			%% 活动已经结束
			end;
		_ -> throw({?error,?TIP_PARTY_OVER})			%% 活动已经结束
	end.

%% 检查宴会玩家
check_party_player(UserId) ->
	PartyPlayer = get_party_player(UserId),
	if
		PartyPlayer#party_player.exist =:= ?CONST_SYS_TRUE ->
			{?ok,PartyPlayer};
		?true ->
			throw({?error,?TIP_PARTY_NOT_JION}) %% 不在宴会
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 战斗结束
battle_over(UserId, _Result, #param{battle_type	= ?CONST_BATTLE_PARTY,ad2 = Id}) ->
	player_api:process_send(UserId, ?MODULE, battle_over_cb, [Id]).

battle_over_cb(Player, [Id]) ->
	case check_battle_over(Player#player.user_id,Id) of
		{?ok,PartyData,_PartyMonster} ->
			set_party_data(PartyData);
		_ -> ?ok
	end,
	{_Flag, Player2}= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
	{?ok, Player2}.

%% 击杀消息提示
get_monster_tip(Name,MonsterId,GoodsList) ->
	case get_goods_by_type(GoodsList) of
		{?ok,[],[]} -> 
			message_api:msg_notice(?TIP_PARTY_MONSTER_REWARD3, [], [], [{?TIP_SYS_COMM,Name},{?TIP_SYS_MONSTER,misc:to_list(MonsterId)}]);
		{?ok,EquipL,[]} ->
			message_api:msg_notice(?TIP_PARTY_MONSTER_REWARD2, [], EquipL, [{?TIP_SYS_COMM,Name},{?TIP_SYS_MONSTER,misc:to_list(MonsterId)}]);
		{?ok,[],GoodsL} ->
			message_api:msg_notice(?TIP_PARTY_MONSTER_REWARD1, [], GoodsL, [{?TIP_SYS_COMM,Name},{?TIP_SYS_MONSTER,misc:to_list(MonsterId)}]);
		{?ok,EquipL,GoodsL} ->
			TipPacket1 = message_api:msg_notice(?TIP_PARTY_MONSTER_REWARD2, [], EquipL, [{?TIP_SYS_COMM,Name},{?TIP_SYS_MONSTER,misc:to_list(MonsterId)}]),
			TipPacket2 = message_api:msg_notice(?TIP_PARTY_MONSTER_REWARD1, [], GoodsL, [{?TIP_SYS_COMM,Name},{?TIP_SYS_MONSTER,misc:to_list(MonsterId)}]),
			<<TipPacket1/binary,TipPacket2/binary>>;
		_ -> <<>>
	end.
	
%% 检查
check_battle_over(UserId,Id) ->
	try
		Time				= misc:seconds(),
		?ok					= check_party_start(Time),
		{?ok, PartyPlayer}	= check_party_player(UserId),
		PartyData			= get_party_data(PartyPlayer#party_player.guild_id),	
		{?ok, PartyMonster}	= check_party_monster(PartyData, Id),
		BattleList			= PartyMonster#party_monster.battle_list,
		BattleList2			= lists:delete(UserId, BattleList),
		PartyMonster2		= PartyMonster#party_monster{battle_list = BattleList2},
		PartyData2			= set_party_monster(PartyData,PartyMonster2),
		{?ok,PartyData2,PartyMonster2}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Stacktrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 取得怪物
get_party_monster(PartyData, Id) ->
	MonsterList = PartyData#party_data.monster_list,
	case lists:keyfind(Id, #party_monster.id, MonsterList) of
		PartyMonster = #party_monster{death = ?CONST_SYS_FALSE} ->
			{?ok,PartyMonster};
		_ ->
			{?error,?TIP_PARTY_MONSTER_DEAD} %% 怪物已死亡
	end.

%% 设置怪物
set_party_monster(PartyData,PartyMonster) ->
	MonsterList = PartyData#party_data.monster_list,
	case lists:keytake(PartyMonster#party_monster.id, #party_monster.id, MonsterList) of
		{value, _, MonsterList2} ->
			PartyData#party_data{monster_list = [PartyMonster|MonsterList2]};
		_ ->
			PartyData
	end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 宴会定时经验
add_exp_handle(PartyData) ->
	MemberList	= PartyData#party_data.member_list,
	add_exp(MemberList).

add_exp([]) -> ?ok; 
add_exp([UserId|MemberList]) ->
	player_api:process_send(UserId, ?MODULE, add_exp_cb, []),
	add_exp(MemberList).
	
add_exp_cb(Player = #player{info = Info,net_pid = Pid},[]) ->
    CurMapId = map_api:get_cur_map_id(Player),
    if
      ?CONST_GUILD_PARTY_MAP =:= CurMapId ->
        	PartyPlayer		= init_party_player(Player),
        	VipLv			= player_api:get_vip_lv(Info),
        	{?ok,Exp}		= get_rec_exp(Info#info.lv,VipLv),
        	ExpSum			= PartyPlayer#party_player.exp,
        	ExpSum2			= ExpSum + Exp,
        	PartyPlayer2	= PartyPlayer#party_player{exp = ExpSum2},
         	Packet45510		= party_api:msg_sc_reward(1,ExpSum2),
        	{?ok,Player2}	= player_api:exp(Player, Exp),
        	set_party_player(PartyPlayer2),
         	misc_packet:send(Pid, Packet45510),
           {?ok,Player2};
      ?true ->
          {?ok, Player}
    end;
add_exp_cb(Player,[]) ->
 	{?ok,Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 宴会定时体力
add_sp_handle(PartyData) ->
	MemberList	= PartyData#party_data.member_list,
	add_sp(MemberList).

add_sp([]) -> ?ok; 
add_sp([UserId|MemberList]) ->
	player_api:process_send(UserId, ?MODULE, add_sp_cb, []),
	add_sp(MemberList).

add_sp_cb(Player = #player{net_pid = Pid},[]) ->
	CurMapId = map_api:get_cur_map_id(Player),
	if
		?CONST_GUILD_PARTY_MAP =:= CurMapId ->
			PartyPlayer		= init_party_player(Player),
			SpSum			= PartyPlayer#party_player.sp,
			if
				SpSum < 20 ->
					AddSp			= 10,
					SpSum2			= SpSum + AddSp,
					Packet			= party_api:msg_sc_reward(2,SpSum2),
					PartyPlayer2	= PartyPlayer#party_player{sp = SpSum2},
					{?ok,Player2}	= player_api:plus_sp(Player, AddSp, ?CONST_COST_PARTY_HOOK),
					set_party_player(PartyPlayer2),
					misc_packet:send(Pid, Packet),
					{?ok, Player2};
				?true ->
					{?ok, Player}
			end;		  
		?true ->
			{?ok, Player}
	end;
add_sp_cb(Player,[]) ->
	{?ok,Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_rec_exp(Lv,VipLv) ->
	case data_party:get_party_reward(Lv) of
		?null ->
			{?ok,0};
		#rec_party_reward{exp = Exp} ->
			Add 	= player_vip_api:get_party_increace(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
			Exp2	= misc:floor(Exp * (1+Add)),
			{?ok,Exp2}
	end.

get_rec_pos() ->
	case data_party:get_party_pos() of
		?null ->
			{?ok,[]};
		Data ->
			{?ok,Data}
	end.

get_rec_party(Lv) ->
	case data_party:get_party(Lv) of
		?null ->
			{?error,?TIP_COMMON_BAD_ARG}; %% 参数错误
		Data ->
			{?ok,Data}
	end.

get_rec_box(Type) ->
	case data_party:get_party_box(Type) of
		?null -> throw({?error,?TIP_COMMON_BAD_ARG}); %% 参数错误
		#rec_party_box{goods = Goods} ->
			{?ok,Goods}
	end.

get_rec_doll_award(Lv, VipLv) ->
	case data_party:get_party_reward(Lv) of
		?null ->
			{?ok, 0, 0};
		#rec_party_reward{auto_exp = Exp, auto_sp = Sp} ->
			Add 	= player_vip_api:get_party_increace(VipLv) / ?CONST_SYS_NUMBER_HUNDRED,
			Exp2	= misc:floor(Exp * (1 + Add)),
			{?ok, Exp2, Sp}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法开始
play_start_handle(PartyData) ->
	{?ok,PosList}	= get_rec_pos(),
	{?ok,Data}		= get_rec_party(PartyData#party_data.guild_lv),	
	MemberList		= PartyData#party_data.member_list,
	PartyActive		= get_party_active(),
	case misc_random:random(0, ?CONST_SYS_NUMBER_HUNDRED) of 
		Num when Num rem 2 =:= 0 ->
			Play			= 1,
			BoxList			= Data#rec_party.box,
			Count			= length(BoxList),
			PosList2		= misc_random:random_list_norepeat(PosList,Count),
			NBoxList		= init_box_list(BoxList,PosList2,1,[]),
			PartyData2		= PartyData#party_data{box_list = NBoxList,play_type = Play,
												   monster_list = [],name_list = []},
			
			Packet45506		= get_play_time(PartyActive,Play),
			PBoxList		= get_box_list(NBoxList),

			Packet45520		= party_api:msg_sc_box_data(PBoxList),
			Packet45508		= party_api:msg_sc_play_start(Play),
			Packet			= <<Packet45506/binary,Packet45508/binary,Packet45520/binary>>,
			party_api:broadcast(MemberList,Packet);
		_ ->
			Play			= 2,
			MonList			= Data#rec_party.monster, 
			Count			= length(MonList),
			PosList2		= misc_random:random_list_norepeat(PosList,Count),
			NMonList		= init_monster_list(MonList,PosList2,1,[]),
			PartyData2		= PartyData#party_data{monster_list = NMonList,play_type = Play,
												   box_list = [],name_list = []},
			
			Packet45506		= get_play_time(PartyActive,Play),
			Packet45508		= party_api:msg_sc_play_start(Play),
			Packet45524		= party_api:monster_msg(NMonList),
			Packet			= <<Packet45506/binary,Packet45508/binary,Packet45524/binary>>,
			party_api:broadcast(MemberList,Packet)
	end,
	set_party_data(PartyData2),
	?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	
%% 初始化箱子信息
init_box_list([],_,_,BoxList) ->
	BoxList;
init_box_list([Type|List],[{X,Y}|PosList2],Num,BoxList) ->
	Box 	= record_party_box(Num,Type,X,Y),
	init_box_list(List,PosList2,Num+1,[Box|BoxList]).

%% 初始化怪物信息
init_monster_list([],_,_,MonsterList) ->
	MonsterList;
init_monster_list([MonsterId|List],[{X,Y}|PosList2],Num,MonsterList) ->
	Monster = record_world_monster(MonsterId,Num,X,Y),
	init_monster_list(List,PosList2,Num+1,[Monster|MonsterList]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	
%% 刷新怪物
refresh_monster(UserId, Id, HurtTuple) ->
	case check_refresh_monster(UserId,Id) of
		{?ok, #party_data{pid = Pid}, #party_player{user_name = Name}, PartyMonster} ->
			case HurtTuple of
				{0,0,0,0,0,0,0,0,0} -> PartyMonster#party_monster.hp_tuple;
				_ ->
					Hurt	= lists:sum(misc:to_list(HurtTuple)),
					party_serv:refresh_monster_cast(Pid, UserId, Name,Id, Hurt, HurtTuple),
					set_hp_tuple(PartyMonster#party_monster.hp_tuple, HurtTuple)
			end;
		{?error, _ErrorCode} -> erlang:make_tuple(9, 0, [])
	end.

%% 检查怪物
check_refresh_monster(UserId, Id) ->
	try
		Time				= misc:seconds(),
		?ok					= check_party_start(Time),
		{?ok, PartyPlayer}	= check_party_player(UserId),
		PartyData			= get_party_data(PartyPlayer#party_player.guild_id),
		{?ok, PartyMonster}	= check_party_monster(PartyData, Id),
		{?ok, PartyData, PartyPlayer, PartyMonster}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 刷新怪物血量--回调
refresh_monster_handle(_GuildId, UserId,  Name, Id, Hurt, HurtTuple) ->
	case check_refresh_monster(UserId,Id) of
		{?ok, PartyData, _PartyPlayer,PartyMonster} ->
			refresh_monster_handle2(PartyData, PartyMonster, UserId,  Name, Hurt, HurtTuple);
		_ -> ?ok
	end.

refresh_monster_handle2(PartyData, PartyMonster, UserId,  UserName, Hurt, HurtTuple) ->
	PartyMonster2	= PartyMonster#party_monster{hp_tuple = set_hp_tuple(PartyMonster#party_monster.hp_tuple, HurtTuple)},
	case set_hp(PartyMonster2#party_monster.hp, Hurt) of
		0 ->% 怪物死亡
			MonsterList		= PartyData#party_data.monster_list,
			Id				= PartyMonster2#party_monster.id,
			MonsterId		= PartyMonster2#party_monster.monster_id,
			NameList		= PartyData#party_data.name_list,
			
			MonsterList2	= lists:keydelete(Id, #party_monster.id, MonsterList),
			NameList2		= add_name_list(UserName,NameList),
			PartyData2		= PartyData#party_data{monster_list = MonsterList2,
												   name_list	= NameList2},
			
			MemberList		= PartyData#party_data.member_list,
			Packet45526		= party_api:msg_sc_remove_monster(Id),
			{?ok,Exp,Gold,GoodsList} 	= get_monster_reward(MonsterId),
			player_api:process_send(UserId, ?MODULE, battle_reward_cd, [Exp,Gold,GoodsList]),
			TipPacket		= get_monster_tip(UserName,MonsterId,GoodsList),
			party_api:broadcast(MemberList, <<Packet45526/binary,TipPacket/binary>>),
			present_reward_handle(PartyData2,2);		
		Hp ->% 怪物未死亡
			PartyMonster3	= PartyMonster2#party_monster{hp = Hp},
			PartyData2		= set_party_monster(PartyData,PartyMonster3)
	end,
	set_party_data(PartyData2),
	?ok.

%% 发送击杀怪物奖励
battle_reward_cd(Player,[Exp,Gold,GoodsList]) ->
	UserId			= Player#player.user_id,
	PartyPlayer		= get_party_player(UserId),
	GoldSum			= PartyPlayer#party_player.gold + Gold,
	VipLv			= player_api:get_vip_lv(Player#player.info),
	Add 			= player_vip_api:get_party_increace(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
	Exp2			= misc:floor(Exp * (1+Add)),
	ExpSum			= PartyPlayer#party_player.exp + Exp2,
 	PartyPlayer2	= PartyPlayer#party_player{exp 	= ExpSum,gold	= GoldSum},
	
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_PARTY_REWARD),   
    {Player3, Packet2} =
        case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_PARTY_REWARD, 1, 1, 1, 0, 0, 1, []) of
    		{?ok, Player2, _, Packet} -> 
                {Player2, Packet};
    		{?error, _ErrorCode} -> 
    			{Player, <<>>}
    	end, 
	{?ok, Player4} = player_api:exp(Player3, Exp2),  
	set_party_player(PartyPlayer2),
	misc_packet:send(Player4#player.net_pid, Packet2),
	{?ok, Player4}.
	
	

%% 取得击杀怪物奖励
get_monster_reward(MonsterId) ->
	Monster 		= monster_api:monster(MonsterId),
	Exp 			= Monster#monster.exp,
	Gold			= Monster#monster.gold,
	GoodsList		= goods_api:goods_drop(Monster#monster.drop_id),
	{?ok,Exp,Gold,GoodsList}.
	
%% 击杀玩家列表
add_name_list(UserName,List) ->
	case lists:member(UserName, List) of
		?false ->
			[UserName|List];
		_ -> List
	end.
									   
%% 刷新怪物血量-定时刷新
refresh_monster_hp_handle(#party_data{play_type = 1,monster_list = MonsterList,member_list = MemberList}) ->
	Packet	= party_api:monster_msg(MonsterList),
	party_api:broadcast(MemberList, Packet);
refresh_monster_hp_handle(_) -> ?ok.	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法结束-移除信息
play_end_handle(PartyData) ->
	MemberList		= PartyData#party_data.member_list,
	PartyActive		= get_party_active(),
	case PartyData#party_data.play_type of
		1 ->
			BoxList			= PartyData#party_data.box_list,
			BoxList2		= [Id || #party_box{id = Id} <- BoxList],
			Packet45522		= remove_all_box(BoxList2,<<>>),
			
			Packet45506		= get_play_time(PartyActive,0),
			PartyData2		= PartyData#party_data{play_type = 0,box_list = []},
			
			Packet			= <<Packet45506/binary,Packet45522/binary>>,
			party_api:broadcast(MemberList,Packet),
			set_party_data(PartyData2);
		2 ->
			MonsterList		= PartyData#party_data.monster_list,
			MonsterList2	= [Id|| #party_monster{id = Id} <- MonsterList],
			Packet45526		= remove_all_monster(MonsterList2,<<>>),
			
			Packet45506		= get_play_time(PartyActive,0),
			PakcetTip		= case MonsterList2 of
								  [] -> <<>>; 
								  _ -> 
									  GuildName	= PartyData#party_data.guild_name,
									  message_api:msg_notice(?TIP_PARTY_MONSTER_EXIST,[{?TIP_SYS_COMM,GuildName}])
							   end,								
			PartyData2		= PartyData#party_data{play_type = 0,monster_list = []},
			Packet			= <<Packet45506/binary,Packet45526/binary,PakcetTip/binary>>,
			party_api:broadcast(MemberList,Packet),
			set_party_data(PartyData2);
		_ -> ?ok
	end,
	?ok.

%% 移除箱子
remove_all_box([],BinMsg) ->
	BinMsg;
remove_all_box([Id|List],BinMsg) ->
	Bin 	= party_api:msg_sc_remove_box(Id),
	remove_all_box(List,<<BinMsg/binary,Bin/binary>>).

%% 移除怪物
remove_all_monster([],BinMsg) ->
	BinMsg;
remove_all_monster([Id|List],BinMsg) ->
	Bin		= party_api:msg_sc_remove_monster(Id),
	remove_all_monster(List,<<BinMsg/binary,Bin/binary>>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_party_active() ->
	ets_api:lookup(?CONST_ETS_PARTY_ACTIVE, ?CONST_ACTIVE_TYPE_PARTY).

set_party_active(PartyActive) ->
	ets_api:insert(?CONST_ETS_PARTY_ACTIVE, PartyActive).

get_party_data(GuildId) ->
	ets_api:lookup(?CONST_ETS_PARTY_DATA, GuildId).

set_party_data(PartyData) ->
	ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData).

get_party_player(UserId) ->
	ets_api:lookup(?CONST_ETS_PARTY_PLAYER, UserId).

set_party_player(PartyPlayer) ->
	ets_api:insert(?CONST_ETS_PARTY_PLAYER, PartyPlayer).

set_party_auto(PartyAuto) ->
	ets_api:insert(?CONST_ETS_PARTY_AUTO,PartyAuto).

get_party_auto(UserId) ->
	ets_api:lookup(?CONST_ETS_PARTY_AUTO, UserId).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 进入宴会Player#player.account
enter(Player = #player{user_id = UserId,account = Account,net_pid = Pid,info = Info}) ->
	case check_enter_party(Player) of
		{?ok,Player2,PartyActive,PartyData,PartyPlayer,GuildId} ->
			
			PartyPlayer2	= PartyPlayer#party_player{enter_time = misc:seconds(),
													   guild_id = GuildId,
													   exist = ?CONST_SYS_TRUE 	
													   },
			
			MemberList		= add_enter_list(PartyData#party_data.member_list,UserId),
			PartyData2		= PartyData#party_data{member_list = MemberList},
			Player3			= map_api:enter_map(Player2, PartyActive#party_active.map_id),
			
			{?ok,Player4} 	= add_guide_times(Player3), 	%% 目标	
			{?ok,Player5} 	= add_achievement(Player4), 	%% 成就		
			{?ok,Time1,Time2}= get_enter_time(PartyActive),
			schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_PARTY),
			Packet45506		= get_play_time(PartyActive,PartyData#party_data.play_type),	
			Packet45504		= party_api:msg_sc_time(Time1,Time2),
			Packet45512		= party_api:msg_sc_sp_time(PartyPlayer#party_player.sp_time),
			PacketExp		= party_api:msg_sc_reward(1,PartyPlayer#party_player.exp),
			PacketSp		= party_api:msg_sc_reward(2,PartyPlayer#party_player.sp),
			PacketPk		= party_api:msg_sc_auto_pk(PartyPlayer#party_player.auto_pk),
			PacketPlay		= get_enter_play(PartyData),
			Packet			= <<Packet45504/binary,Packet45506/binary,Packet45512/binary,
								PacketExp/binary,PacketSp/binary,PacketPlay/binary,PacketPk/binary>>,
			
			set_party_player(PartyPlayer2),
			set_party_data(PartyData2),
			misc_packet:send(Pid, Packet),
			case PartyActive#party_active.flag of 
				1 ->
					admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_TYPE_PARTY, misc:seconds());
				_ ->
					admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_TYPE_PARTY2, misc:seconds())
			end,
			{?ok,Player5};
		{?error,ErrorCode} ->
			Packet 			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Pid, Packet),
			{?ok, Player}
	end.

%% 取得进入时间
get_enter_time(#party_active{start_time = StartTime,end_time = EndTime,state = State}) ->
	Time = misc:seconds(),
	case State of
		?CONST_ACTIVE_STATE_PRE_3 -> 
			{?ok,get_minus_time(StartTime,Time),get_minus_time(EndTime,Time)};
		_ -> 
			{?ok,0,get_minus_time(EndTime,Time)}
	end.

%% 取得时间差
get_minus_time(Time1, Time2) ->
	if
		Time1 > Time2 -> Time1 - Time2;
		?true -> 0
	end.

%% 取得玩法时间
get_play_time(#party_active{end_time = EndTime, play_state = PlayState,
							play1_start_time	= PlayStartTime1,play1_end_time	= PlayEndTime1,	
							play2_start_time	= PlayStartTime2,play2_end_time	= PlayEndTime2},Type) -> 
	Time = misc:seconds(),
	if
		Time >= EndTime ->
			party_api:msg_sc_play_time(0,0);
		
		Time < PlayStartTime1 andalso PlayState =:= 0 ->
			party_api:msg_sc_play_time(0,get_minus_time(PlayStartTime1, Time));
		Time >= PlayStartTime1 andalso Time < PlayEndTime1 andalso PlayState =:= 1 ->
			Packet1 = party_api:msg_sc_play_time(Type,get_minus_time(PlayEndTime1, Time)),
			Packet2 = party_api:msg_sc_play_time(0,get_minus_time(PlayStartTime2, Time)),
			<<Packet1/binary,Packet2/binary>>;

		Time >= PlayEndTime1 andalso Time < PlayStartTime2 andalso PlayState =:= 0 ->
			party_api:msg_sc_play_time(0,get_minus_time(PlayStartTime2, Time));
		Time >= PlayStartTime2 andalso Time < PlayEndTime2 andalso PlayState =:= 2 ->
			Packet1 = party_api:msg_sc_play_time(0,0),
			Packet2 = party_api:msg_sc_play_time(Type,get_minus_time(PlayEndTime2, Time)),
			<<Packet1/binary,Packet2/binary>>;
		?true ->
			party_api:msg_sc_play_time(0,0)		
	end;
get_play_time(_,_) ->
	party_api:msg_sc_play_time(0,0).

%% 取得玩法信息
get_enter_play(PartyData) ->
	case PartyData#party_data.play_type of
		1 -> 
			BoxList			= get_box_list(PartyData#party_data.box_list),
			Packet45520		= party_api:msg_sc_box_data(BoxList),
			Packet45520;
		2 -> 
			Packet45524		= party_api:monster_msg(PartyData#party_data.monster_list),
			Packet45524;
		_ -> <<>>
	end.

%% 宴会玩家列表
add_enter_list(MemberList,UserId) ->
	case lists:member(UserId, MemberList) of
		?false -> [UserId|MemberList];
		_ -> MemberList
	end.		

%% 取得箱子列表
get_box_list(List) ->
	[ {Id,Type,X,Y} || #party_box{id = Id, type = Type, x = X, y = Y} <- List].

%% 检查进入宴会
check_enter_party(Player) ->
	try
		{?ok,GuildId}		= check_guild(Player),
		?ok					= check_guild_lv(GuildId),
		?ok					= check_enter_auto(Player#player.user_id),
		{?ok,Player2}		= check_player_play(Player),
		{?ok,PartyActive}	= check_party_open(),
		PartyPlayer			= init_party_player(Player),
		PartyData			= init_party_data(GuildId),
		
		{?ok,Player2,PartyActive,PartyData,PartyPlayer,GuildId}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 检查军团等级
check_guild_lv(GuildId) ->
	case guild_api:get_guild_lv(GuildId) of
		{?ok,Lv} when Lv >= 2 ->
			?ok;
		_ ->
			throw({?error,?TIP_PARTY_LV})
	end.

%% 检查玩家玩法状态
check_player_play(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_PARTY) of						  
		{?true,Player2} ->
			{?ok,Player2};
		{_,_,ErrorCode} ->
			throw({?error,ErrorCode})
	end.

%% 检查宴会是否已经开过
check_party_is_over(Date) ->
	case get_party_active() of
		PartyActive when is_record(PartyActive,party_active) ->
			EndTime = PartyActive#party_active.end_time,
			NowTime = misc:seconds(),
			{EndDate, _} = misc:seconds_to_localtime(EndTime),
			case Date =:= EndDate of
				?true ->
					case NowTime >= EndTime of
						?true ->
							throw({?error, ?TIP_GUILD_PARTY_IS_OVER});
						?false ->
							?ok
					end;
				?false ->
					?ok
			end;
		?null ->
			?ok
	end.

%% 检查宴会是否开放
check_party_open() ->
	case get_party_active() of
		#party_active{start_time = StartTime, end_time = EndTime} = PartyActive->
			NowTime = misc:seconds(),
			case NowTime >= StartTime andalso NowTime =< EndTime of
				?true ->
					{?ok, PartyActive};
				?false ->
					throw({?error, ?TIP_PARTY_NOT_START})
			end;
		_ ->
			throw({?error, ?TIP_PARTY_NOT_START}) %% 宴会还没开始
	end.

%% 检查宴会活动是否已经开始
check_party_is_not_open() ->
	case catch check_party_open() of
		{?ok, _PartyActive} ->
			throw({?error, ?TIP_GUILD_PARTY_IS_OPEN});
		_ ->
			?ok			%% 宴会还没开始
	end.

%% 检查军团
check_guild(#player{guild = Guild}) ->
	GuildId = Guild#guild.guild_id,
	if
		GuildId =/= 0 ->
			{?ok,GuildId};
		?true ->
			throw({?error,?TIP_PARTY_NO_GUILD}) % 角色未加入军团
	end.

%% 检查是否自动参加
check_enter_auto(UserId) ->
	case get_party_auto(UserId) of
		?null ->
			case ets_api:lookup(?CONST_ETS_PARTY_DOLL, UserId) of
				?null ->
					?ok;
				#party_doll{party_ids = Ids}->
					case lists:member(get_now_key(), Ids) of
						?false ->
							?ok;
						_ ->
							throw({?error,?TIP_GUILD_PARTY_DOLL_STATE})
					end
			end;
		_ ->
			throw({?error,?TIP_PARTY_AUTO}) %% 已经自动参加
	end.

%% 增加引导
add_guide_times(Player) when is_record(Player,player) ->
	schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_GUILD_PARTY).

%% 成就
add_achievement(Player) when is_record(Player,player) ->
	achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_GUILD_PARTY, 0, 1).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 退出宴会
quit(Player = #player{user_id = UserId}) ->
    CurMapId = map_api:get_cur_map_id(Player),
    if
        ?CONST_GUILD_PARTY_MAP =:= CurMapId ->
            Player2 = 
                case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
                    {?true, Player2T} ->
                        case get_party_player(UserId) of
                            PartyPlayer = #party_player{time = Time, enter_time = EnterTime,
                                                        guild_id = GuildId,sp_time = SpTime} ->	
                                Now				= misc:seconds(),
                                AddTime			= get_enter_time(Now,EnterTime),
                                Time2			= Time + AddTime,
                                SpTime2			= SpTime + AddTime,
                                PartyPlayer2	= PartyPlayer#party_player{time = Time2, exist = ?CONST_SYS_FALSE,sp_time = SpTime2},
                                PartyData		= get_party_data(GuildId),
                                MemberList		= lists:delete(UserId, PartyData#party_data.member_list),
                                
                                PlayType		= PartyData#party_data.play_type,
                                MonsterList		= PartyData#party_data.monster_list,
                                MonsterList2	= quit_monster_list(UserId,MonsterList,PlayType),
                                PartyData2		= PartyData#party_data{member_list 	= MemberList,
                                                                       monster_list = MonsterList2},
                                set_party_player(PartyPlayer2),
                                set_party_data(PartyData2),
                                Player2T;
                            _ -> 
                                Player2T
                        end;
                    {?false, Player2T, _} -> Player2T
                end,
            Player3			= case player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_NORMAL) of
                                  {_,PlayerT} ->
                                      PlayerT;
                                  _ ->
                                      Player2
                              end,
            Player4			= map_api:return_last_city(Player3),
            {?ok,Player4};
        ?true ->
            {?ok, Player}
    end;
quit(Player) ->
	{?ok,Player}.

%% 击杀怪物列表中退出
quit_monster_list(UserId,MList,2) ->
	[quit_monster_list2(UserId,PMonster) || PMonster <- MList];
quit_monster_list(_UserId,_List,_) ->
	[].

quit_monster_list2(UserId,PMonster) ->
	List 		= PMonster#party_monster.battle_list,
	List2 		= lists:delete(UserId, List),
	PMonster#party_monster{battle_list = List2}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 打开箱子-领取奖励
open_box(Player = #player{net_pid = Pid},Id) ->
	case check_open_box(Player,Id) of
		{?ok, Player2, PartyData, Packet, TipPacket} ->
			set_party_data(PartyData),
			misc_packet:send(Pid, Packet),
			PartyPid		= PartyData#party_data.pid,
			MemberList		= PartyData#party_data.member_list,
			Packet45522		= party_api:msg_sc_remove_box(Id),
			party_serv:broadcast_cast(PartyPid,MemberList,<<Packet45522/binary,TipPacket/binary>>),
			party_serv:present_reward_cast(PartyPid, PartyData, 1),
			{?ok, Player2};
		{?error,ErrorCode} ->
			Packet 			= message_api:msg_notice(ErrorCode),
			misc_packet:send(Pid, Packet),	
			{?ok,Player}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 检查宝箱是否打开
check_open_box(Player = #player{info = Info}, Id) ->
	try
		Time				= misc:seconds(),
		UserName			= Info#info.user_name,
		?ok					= check_party_start(Time),
		{?ok, PartyPlayer}	= check_party_player(Player#player.user_id),
		PartyData			= get_party_data(PartyPlayer#party_player.guild_id),
		BoxList				= PartyData#party_data.box_list,	
		
		{?ok,Box,BoxList2}	= check_box_id(PartyData,BoxList,Id),		
		NameList			= PartyData#party_data.name_list,
		NameList2			= add_name_list(UserName,NameList),
		PartyData2			= PartyData#party_data{box_list 	= BoxList2,
												   name_list	= NameList2},
		{?ok,Goods}			= get_rec_box(Box#party_box.type),
		GoodsList			= check_box_goods(Goods),
		{?ok, Player2, Packet} = set_stack_list(Player, GoodsList),
		TipPacket			= get_box_tip(UserName,GoodsList),
		{?ok,Player2,PartyData2,Packet,TipPacket}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Stacktrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 取得消息提示
get_box_tip(Name,GoodsList) -> 
	case get_goods_by_type(GoodsList) of
		{?ok,[],[]} -> 
			message_api:msg_notice(?TIP_PARTY_BOX_REWARD3, [], [], [{?TIP_SYS_COMM,Name}]);
		{?ok,EquipL,[]} ->
			message_api:msg_notice(?TIP_PARTY_BOX_REWARD2, [], EquipL, [{?TIP_SYS_COMM,Name}]);
		{?ok,[],GoodsL} ->
			message_api:msg_notice(?TIP_PARTY_BOX_REWARD1, [], GoodsL, [{?TIP_SYS_COMM,Name}]);
		{?ok,EquipL,GoodsL} ->
			TipPacket1 = message_api:msg_notice(?TIP_PARTY_BOX_REWARD2, [], EquipL, [{?TIP_SYS_COMM,Name}]),
			TipPacket2 = message_api:msg_notice(?TIP_PARTY_BOX_REWARD1, [], GoodsL, [{?TIP_SYS_COMM,Name}]),
			<<TipPacket1/binary,TipPacket2/binary>>;
		_ -> <<>>
	end.
		
%% 取得物品列表
get_goods_by_type(GoodsList) ->
	get_goods_by_type2(GoodsList,[],[]).

get_goods_by_type2([],EquipL,GoodsL) ->
	{?ok,EquipL,GoodsL};
get_goods_by_type2([Goods|GoodsList],EquipL,GoodsL) ->
	case Goods#goods.type of
		?CONST_GOODS_TYPE_EQUIP ->
			get_goods_by_type2(GoodsList,[Goods|EquipL],GoodsL);
		_ ->
			get_goods_by_type2(GoodsList,EquipL,[Goods|GoodsL])
	end.	  

%% 检查箱子
check_box_id(PartyData,BoxList,Id) ->
	case lists:keytake(Id, #party_box.id, BoxList) of
		?false ->
			Packet		= party_api:msg_sc_remove_box(Id),
			party_serv:broadcast_cast(PartyData#party_data.pid,PartyData#party_data.member_list,Packet),
			throw({?error,?TIP_PARTY_NO_BOX});	%% 宝箱已经不存在
		{value,Box,BoxList2} ->
			{?ok,Box,BoxList2}
	end.

%% 设置背包
check_box_goods(List) ->
	F = fun({GoodsId,Bind,Num},GList) ->
				GList2 	= goods_api:make(GoodsId, Bind, Num),
				GList ++ GList2
		end,
	lists:foldl(F, [], List).

set_stack_list(Player, GoodsList) ->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_PARTY_REWARD, 1, 1, 0, 0, 0, 1, []) of
		{?ok, Player2, _, Packet} ->
			{?ok, Player2, Packet};
		{?error, ErrorCode} -> 
			throw({?error, ErrorCode})
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 箱子全部打开-发放奖励
present_reward_handle(#party_data{box_list = [],name_list = NameList,member_list = List} ,1) ->
	NameList2		= [{?TIP_SYS_COMM,Name} || Name <- NameList],
	TipPacket 		= message_api:msg_notice(?TIP_PARTY_BOX_FINISH,NameList2),
	F	= fun(UserId) ->
				  player_api:process_send(UserId, ?MODULE, present_box_reward_cd, [TipPacket])
		  end,
	lists:foreach(F, List);
%% 怪物全部被击杀-发放奖励
present_reward_handle(#party_data{monster_list = [],name_list = NameList,member_list = List},2) ->
	NameList2		= [{?TIP_SYS_COMM,Name} || Name <- NameList],
	TipPacket 		= message_api:msg_notice(?TIP_PARTY_MONSTER_FINISH,NameList2),
	F	= fun(UserId) ->
				  player_api:process_send(UserId, ?MODULE, present_monster_reward_cd, [TipPacket])
		  end,
	lists:foreach(F, List);
present_reward_handle(_,_) -> ?ok.
	
%% 箱子全部打开-发放奖励
present_box_reward_cd(Player = #player{user_id = UserId,info = Info,net_pid = Pid},[TipPacket]) ->
	{?ok,Exp}		= get_present_box_reward(Info#info.lv),
	VipLv			= player_api:get_vip_lv(Player#player.info),
	Add 			= player_vip_api:get_party_increace(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
	Exp2			= misc:floor(Exp * (1+Add)),

	PartyPlayer		= get_party_player(UserId),
	ExpSum			= PartyPlayer#party_player.exp,
	ExpSum2			= ExpSum + Exp2,
	PartyPlayer2	= PartyPlayer#party_player{exp = ExpSum2},
	PacketExp		= party_api:msg_sc_reward(1,ExpSum2),
	
	set_party_player(PartyPlayer2),
	misc_packet:send(Pid, <<TipPacket/binary,PacketExp/binary>>),
	player_api:exp(Player, Exp2).

%% 怪物全部被击杀-发放奖励
present_monster_reward_cd(Player = #player{user_id = UserId,info = Info,net_pid = Pid},[TipPacket]) ->
	{?ok,Exp}		= get_present_monster_reward(Info#info.lv),
	VipLv			= player_api:get_vip_lv(Player#player.info),
	Add 			= player_vip_api:get_party_increace(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
	Exp2			= misc:floor(Exp * (1+Add)),

	PartyPlayer		= get_party_player(UserId),
	ExpSum			= PartyPlayer#party_player.exp,
	ExpSum2			= ExpSum + Exp2,
	PartyPlayer2	= PartyPlayer#party_player{exp = ExpSum2},
	PacketExp		= party_api:msg_sc_reward(1,ExpSum2),
	
	set_party_player(PartyPlayer2),
	misc_packet:send(Pid, <<TipPacket/binary,PacketExp/binary>>),
	player_api:exp(Player, Exp2).

		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 请求获取体力
request_get_sp(Player = #player{net_pid = Pid}) ->
	case check_get_sp(Player) of
		{?ok,PartyPlayer = #party_player{sp_time = SpTime, enter_time = EnterTime,
								   time = TimeSum, sp = Sp} } when Sp < ?CONST_GUILD_PARTY_SP_LIMIT ->
			Now				= misc:seconds(),	
			AddTime			= get_enter_time(Now,EnterTime),
			SpTime2			= SpTime + AddTime,
			if
				SpTime2 >= ?CONST_GUILD_PARTY_SP_INTERVAL->
					TimeSum2		= TimeSum + AddTime,  
					Sp2				= Sp + ?CONST_GUILD_PARTY_SP,
					PartyPlayer2	= PartyPlayer#party_player{sp_time = 0,enter_time = Now,
														 	   time = TimeSum2,sp = Sp2},
					Packet45512		= party_api:msg_sc_sp_time(0),
					PacketSp		= party_api:msg_sc_reward(2,Sp2),
					
					set_party_player(PartyPlayer2),
					misc_packet:send(Pid, <<Packet45512/binary,PacketSp/binary>>),
					player_api:plus_sp(Player, ?CONST_SPRING_SP, ?CONST_COST_PARTY_HOOK);
				?true ->							
					Packet45512		= party_api:msg_sc_sp_time(SpTime2),
					misc_packet:send(Pid, Packet45512),
					{?ok,Player}
			end;
		_ ->
			Packet45512		= party_api:msg_sc_sp_time(0),
			misc_packet:send(Pid, Packet45512),
			{?ok,Player}
	end.
		
%% 检查获得体力
check_get_sp(Player) ->
	try
		{?ok,_PartyActive}	= check_party_open(),
		PartyPlayer			= init_party_player(Player),
		{?ok,PartyPlayer}
	catch
		throw:{?error,ErrorCode} -> 
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Stacktrace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 取得进入时间
get_enter_time(Now,Time) ->
	if
		Now > Time ->
			Now - Time;
		?true ->
			0
	end.
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_party_player(Player) ->
	PartyPlayer = 
		case get_party_player(Player#player.user_id) of
			?null -> record_party_player(Player);
			PartyPlayerT -> PartyPlayerT
		end,
	PartyPlayer.

init_party_data(GuildId) ->
	case get_party_data(GuildId) of
		?null -> 
			case party_sup:start_child_party_serv(GuildId) of
				{?ok,_} ->
					get_party_data(GuildId);
				{?error,ErrorCode} ->
					{?error,ErrorCode}
			end;
		PartyData ->
			PartyData
	end.				  

init(GuildId) ->
	GuildName 		= guild_api:get_guild_name(GuildId),
	{?ok,GuildLv}	= guild_api:get_guild_lv(GuildId),
	PartyData		= record_party_data(GuildId,GuildName,GuildLv),
	case get_party_active() of
		#party_active{play_state = Type} when Type =/= 0 ->
			play_start_handle(PartyData);	%% 玩法重新刷新玩法
		_ ->
			set_party_data(PartyData)
	end,
	?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 活动开始-设置自动参加
set_active_auto(Flag) ->
	GuildList 		= ets_api:list(?CONST_ETS_GUILD_DATA),
	F = fun(GuildData) ->
				MemberList	= GuildData#guild_data.member_list,
				set_auto_player(MemberList,Flag)
		end,
	lists:foreach(F,GuildList).


%% 获得自动参加列表		
set_auto_player([],_Flag) -> ?ok;
set_auto_player([UserId|MemberList],Flag) ->
	set_auto_player2(UserId,Flag),
	set_auto_player(MemberList,Flag).

set_auto_player2(UserId,Flag) ->
	case guild_api:ets_guild_member(UserId) of
		#guild_member{party_flag1 = ?CONST_SYS_TRUE} ->
			check_auto_money(UserId,Flag);
		_ -> ?ok
	end.

set_auto_player_cb(Player, [_Flag]) ->
	{?ok, Player1} 	= add_guide_times(Player), 		%% 目标	
	{?ok, Player2} 	= add_achievement(Player1), 	%% 成就	
	{?ok, Player2}.

%% 获得扣取元宝列表
check_auto_money(UserId,Flag) -> 
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_GUILD_PARTY_AUTO_COST, ?CONST_COST_PARTY_AUTO) of
		?ok -> 
			player_api:process_send(UserId,?MODULE,set_auto_player_cb,[Flag]),
			ets_api:update_element(?CONST_ETS_GUILD_MEMBER, UserId, [{#guild_member.party_flag1,0},
																	 {#guild_member.party_flag2,0}]),
			set_party_auto({UserId,?CONST_SYS_TRUE});
		_ ->
			Packet = message_api:msg_notice(?TIP_PARTY_AUTO_FAIL),	%% 自动参加宴会失败
			misc_packet:send(UserId, Packet)
	end.

%% 自动参加
auto_party(#player{user_id = UserId,info = Info,guild = Guild},ActiveId,Flag) ->
	?ok					= check_guild_id(Guild#guild.guild_id),
	?ok					= check_guild_lv(Guild#guild.guild_id),
	?ok					= check_vip_flag(player_api:get_vip_lv(Info)),
	?ok					= check_auto_start(),
	{?ok,GuildMember} 	= guild_api:get_guild_member(UserId),
	set_auto_member(GuildMember,ActiveId,Flag),
	?ok.

check_auto_start() ->
	case get_party_active() of
		PartyActive when is_record(PartyActive,party_active) -> 
 			throw({?error,?TIP_PARTY_AUTO_START});
		_ -> ?ok
	end.

%% 检查军团id
check_guild_id(0) ->
	throw({?error,?TIP_GUILD_NOT_JION});
check_guild_id(_) -> ?ok.

%% 设置自动参加
set_auto_member(GuildMember,?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,Flag) ->
	Flag2 			= get_flag(Flag),
	GuildMember2	= GuildMember#guild_member{party_flag1 = Flag2},
	guild_mod:update_member(GuildMember2,[]);							
set_auto_member(GuildMember,?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY,Flag) ->
	Flag2 			= get_flag(Flag),
	GuildMember2	= GuildMember#guild_member{party_flag2 = Flag2},
	guild_mod:update_member(GuildMember2,[]).

get_flag(?true) -> ?CONST_SYS_TRUE;
get_flag(_) -> ?CONST_SYS_FALSE.

check_vip_flag(Vip) -> 
	case player_vip_api:can_guild_party_auto_join(Vip) of
		?CONST_SYS_TRUE -> ?ok;
		_ -> throw({?error,?TIP_GUILD_VIP})
	end.

%% 自动参加奖励
auto_reward([],_) -> ?ok;
auto_reward([{UserId,_}|List],Flag) ->
	case player_api:check_online(UserId) of
		?true ->
			player_api:process_send(UserId, ?MODULE, auto_reward_cb, [Flag]);
		_ ->
			player_offline_api:offline(party_api,UserId,Flag)
	end,
	auto_reward(List,Flag).

%% 自动参加发送奖励
auto_reward_cb(Player,[Flag]) ->
	auto_send_reward(Player,Flag).

%% 自动参加发送奖励
auto_send_reward(Player = #player{info = Info,net_pid = Pid},_Flag) when is_record(Player,player) ->
	try
		
		{?ok,Exp,Sp} 	= get_party_auto_reward(Info#info.lv),
		VipLv			= player_api:get_vip_lv(Info),
		Add 			= player_vip_api:get_party_increace(VipLv)/?CONST_SYS_NUMBER_HUNDRED,
		Exp2			= misc:floor(Exp * (1+Add)),
		{?ok,Player2} 	= player_api:exp(Player, Exp2),
		{?ok,Player3} 	= player_api:plus_sp(Player2, Sp, ?CONST_COST_PARTY_HOOK),
		{?ok,Player4}	= task_api:update_active(Player3, {?CONST_ACTIVE_TYPE_PARTY, 1}),
		Packet 			= party_api:msg_sc_auto_reward(Exp2,Sp),
%% 		Packet 			= message_api:msg_notice(?TIP_PARTY_AUTO_SUCCESS,[{?TIP_SYS_COMM,misc:to_list(Exp)},
%% 																		  {?TIP_SYS_COMM,misc:to_list(Sp)}]),  
		misc_packet:send(Pid, Packet),
		{?ok,Player4}
	catch
		throw:{?error,?TIP_GUILD_AUTO_PARTY_FAIL} ->
			TipPacket 	= message_api:msg_notice(?TIP_GUILD_AUTO_PARTY_FAIL), 
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok,Player};
		_:_ ->
			{?ok,Player}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_party_auto_reward(Lv) ->
	case data_party:get_party_reward(Lv) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_party_reward{auto_exp = Exp, auto_sp = Sp} ->
			{?ok,Exp,Sp}
	end.

get_present_box_reward(Lv) ->
	case data_party:get_party_reward(Lv) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_party_reward{box_exp = Exp} ->
			{?ok,Exp}
	end.

get_present_monster_reward(Lv) ->
	case data_party:get_party_reward(Lv) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_party_reward{monster_exp = Exp} ->
			{?ok,Exp}
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
record_party_data(GuildId,GuildName,GuildLv) ->
	#party_data{
				guild_id 		= GuildId,
				guild_name		= GuildName,
				guild_lv		= GuildLv,
				pid				= self()
				}.

record_party_player(#player{user_id = UserId,info = Info,guild = Guild}) ->
	#party_player{
				  user_id 		= UserId,
				  user_name		= Info#info.user_name,
				  guild_id		= Guild#guild.guild_id				
				  }.

record_party_box(Id,Type,X,Y) ->
	#party_box{
			   id				= Id,
			   type				= Type,
			   x				= X,
			   y				= Y
			   }.

record_world_monster(MonsterId,Id,X,Y) ->
	{?ok, HpMax, HpTuple}	= get_monster_group_hp(MonsterId),
	#party_monster{
				   id			= Id,
				   monster_id	= MonsterId,	% 怪物ID
				   x			= X,
				   y			= Y,
				   hp			= HpMax,		% 怪物当前总生命
				   hp_max 		= HpMax,		% 怪物总生命上限
				   hp_tuple		= HpTuple 		% 怪物组血量 
				  }.

%% 获取怪物组生命总和
get_monster_group_hp(MonsterId) ->
	Monster		= data_monster:get_monster(MonsterId),
	Camp		= Monster#monster.camp,
	HpTupleTemp	= erlang:make_tuple(tuple_size(Camp#camp.position), 0, []),
	HpTuple		= get_monster_group_hp(misc:to_list(Camp#camp.position), HpTupleTemp),
	HpMax		= lists:sum(misc:to_list(HpTuple)),
	{?ok, HpMax, HpTuple}.

get_monster_group_hp([#camp_pos{idx = Idx, id = MonsterId}|Position], HpTuple) ->
	Monster		= data_monster:get_monster(MonsterId),
	HpTuple2	= setelement(Idx, HpTuple, Monster#monster.hp),
	get_monster_group_hp(Position, HpTuple2);
get_monster_group_hp([_|Position], HpTuple) ->
	get_monster_group_hp(Position, HpTuple);
get_monster_group_hp([], HpTuple) -> HpTuple.

set_hp(0, _Hurt) -> 0;
set_hp(Hp, 0) -> Hp;
set_hp(Hp, Hurt) -> misc:betweet(Hp - Hurt, 0, Hp).

set_hp_tuple({Hp1, Hp2, Hp3, Hp4, Hp5, Hp6, Hp7, Hp8, Hp9},
			 {Hurt1, Hurt2, Hurt3, Hurt4, Hurt5, Hurt6, Hurt7, Hurt8, Hurt9}) ->
	{
	 set_hp(Hp1, Hurt1), set_hp(Hp2, Hurt2), set_hp(Hp3, Hurt3),
	 set_hp(Hp4, Hurt4), set_hp(Hp5, Hurt5), set_hp(Hp6, Hurt6),
	 set_hp(Hp7, Hurt7), set_hp(Hp8, Hurt8), set_hp(Hp9, Hurt9)
	}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_auto_pk(UserId,Flag) -> 
	case get_party_player(UserId) of
		PartyPlayer when is_record(PartyPlayer, party_player) ->
			PartyPlayer2 	= PartyPlayer#party_player{auto_pk = Flag},
			Packet		 	= party_api:msg_sc_auto_pk(Flag),
			set_party_player(PartyPlayer2),
			misc_packet:send(UserId, Packet);
		_ ->
			?ok
	end.		

request_pk(Player,MemId) ->
	try
		?ok					= check_user_play_state(Player#player.play_state),
		?ok					= check_user_pk_state(Player#player.user_state),
		{?ok,TUserState,TPlayState,TGuildId}		= get_mem_player(MemId),
		?ok					= check_mem_pk_state(TUserState),
 		?ok					= check_mem_play_state(TPlayState),
		Guild				= Player#player.guild,
		?ok					= check_map_pid(Guild#guild.guild_id,TGuildId),
		Info				= Player#player.info,
		UserName			= Info#info.user_name,
		Packet				= party_api:msg_sc_apply_pk(Player#player.user_id,UserName),
		Packet2				= message_api:msg_notice(?TIP_PARTY_REQUEST_PK),
		case is_doll(MemId) of
			?true ->
				?ok;
			?false ->
				misc_packet:send(MemId, Packet)
		end,
		misc_packet:send(Player#player.net_pid, Packet2)
	catch
		throw:{?error,ErrorCode} ->
			TipPacket 	= message_api:msg_notice(ErrorCode), 
			misc_packet:send(Player#player.net_pid, TipPacket);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Stacktrace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.	

check_user_pk_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_user_pk_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_user_pk_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) -> ?ok;
check_user_pk_state(_) ->
	throw({?error,?TIP_PARTY_USER_NOT_PK}).

check_mem_pk_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_mem_pk_state(?CONST_PLAYER_STATE_SINGLE_PRACTISE) -> ?ok;
check_mem_pk_state(?CONST_PLAYER_STATE_DOUBLE_PRACTISE) -> ?ok;
check_mem_pk_state(_) ->
	throw({?error,?TIP_PARTY_MEM_NOT_PK}). 

check_user_play_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_user_play_state(_) ->
	throw({?error,?TIP_PARTY_USER_NOT_IN}).

check_mem_play_state(?CONST_PLAYER_PLAY_PARTY) -> ?ok;
check_mem_play_state(_) ->
	throw({?error,?TIP_PARTY_MEM_NOT_IN}).

check_map_pid(GuildId,GuildId) -> ?ok;
check_map_pid(_,_) ->
	throw({?error,?TIP_PARTY_MEM_NOT_IN}).
	

reply_pk(Player,_MemId,?CONST_SYS_FALSE) ->
	{?ok,Player};
reply_pk(Player,MemId,_) ->
	try
		?ok					= check_user_play_state(Player#player.play_state),
		?ok					= check_user_pk_state(Player#player.user_state),
		{?ok,TUserState,TPlayState,TGuildId}		= get_mem_player(MemId),
		?ok					= check_mem_pk_state(TUserState), 
 		?ok					= check_mem_play_state(TPlayState),
		Guild				= Player#player.guild,
		?ok					= check_map_pid(Guild#guild.guild_id,TGuildId),
		pk_battle_start(Player,MemId)
	catch
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Stacktrace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

pk_battle_start(Player,Id)  ->
	case battle_api:start(Player, Id, #param{battle_type	= ?CONST_BATTLE_PARTY_PK}) of
		{?ok, Player2} ->
			player_api:process_send(Id, ?MODULE, pk_start_cb, []),
			{?ok, Player2};
		{?error, ErrorCode} -> 
			{?error, ErrorCode}
	end.

pk_start_cb(Player,[]) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_FIGHTING) of
		 {?true, NewPlayer} ->
			 {?ok,NewPlayer};
		_ ->
			Player2 	= Player#player{user_state = ?CONST_PLAYER_STATE_FIGHTING},
			map_api:change_user_state(Player2),
			{?ok,Player2}
	end.
		
	
get_mem_player(MemId) ->
	case is_doll(MemId) of
		?true ->
			case player_api:get_player_fields(MemId, [#player.guild]) of
				{?ok, [#guild{guild_id = GuildId}]} ->
					{?ok,?CONST_PLAYER_STATE_NORMAL,?CONST_PLAYER_PLAY_PARTY,GuildId};
				_ ->
					throw({?error,?TIP_COMMON_OFF_LINE})
			end;
		?false ->
			case player_api:check_online(MemId) of
				?true -> 
					case player_api:get_player_fields(MemId, [#player.user_state,#player.play_state,#player.guild]) of
						{?ok, [UserState,PlayState,#guild{guild_id = GuildId}]} ->
							{?ok,UserState,PlayState,GuildId};
						_ ->
							throw({?error,?TIP_COMMON_OFF_LINE})
					end;
				?false -> 
					throw({?error,?TIP_COMMON_OFF_LINE})
			end
	end.
