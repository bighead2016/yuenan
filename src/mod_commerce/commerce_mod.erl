%% Author: Administrator
%% Created: 2013-2-20
%% Description: TODO: Add description to commerce_mod2
-module(commerce_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").

%%
%% Exported Functions
%%
-export([enter/1, exit/1, logout/1, flush_offline/2,flag_invite/2,
		 carry/1, escort_start_cb/3, escort_over_cb/4, speed_up/1,
		 rob/2, rob_cb/3, cd_rob_time/1, buy_rob_times/1,get_carry_times/1,
		 quality_info/1, refresh/1, one_key_refresh/1, get_rob_times/1,
		 build_market/1,broadcast/1,caravan_update/1,
		 friend_info/1, invite/3, reply/3, carry_over/2,
		 market_clear/0, caravan_clear/0, commerce_clear/0, friend_clear/0, refresh_commerce_times/0]).
-export([get_base_data/1, cal_carry_income/3, cal_escort_income/3, cal_rob_income/4]).
-export([add_carry_times/2, add_escort_times/2, add_rob_times/2]).

%%
%% API Functions
%%
%% 进入商路场景
enter(Player)	->
	UserId	= Player#player.user_id,
	Account	= Player#player.account,
	Info	= Player#player.info,
	Lv		= Info#info.lv,
	Now		= misc:seconds(),
	OnLine	= #commerce_online{user_id = UserId, lv = Lv}, 
	ets:insert(?CONST_ETS_COMMERCE_ONLINE, OnLine),
	caravan_info(Player),																	%% 商路商队信息
	commerce_info(Player),                                                       			%% 商路玩家信息
	rob_info(Player),																		%% 商路战报信息
	market_info(Player),																	%% 商路市场信息
	guile_add_lv(Player),																	%% 商路军团增益等级
	?ok.
%% 	case active_api:is_opened(?CONST_ACTIVE_COMMERCE) of 
%% 		?CONST_SYS_TRUE -> 
%% 			admin_log_api:log_campaign(UserId, Account, Lv, ?CONST_ACTIVE_COMMERCE, Now);          	%% 玩法活动参与日志接口
%% 		_ -> ?ok 
%% 	end.		 

%% 商路军团增益等级
guile_add_lv(Player) ->
	Lv		= guild_api:get_skill_lv(Player, ?CONST_GUILD_SKILL_TYPE_BUSINESS),
	Packet	= commerce_api:pack_sc_guild_add(Lv),
	misc_packet:send(Player#player.net_pid, Packet).

%% 商路商队信息
caravan_info(Player)	->
	UserId	= Player#player.user_id,
	Info	= Player#player.info,
	Lv		= Info#info.lv,
	EtsList	= ets_api:list(?CONST_ETS_CARAVAN),
	Fun		= fun(Caravan) when is_record(Caravan, caravan)	->
					  caravan_info(UserId, Lv, Caravan)
			  end,
	lists:foreach(Fun, EtsList).

caravan_info(UserId, Lv, Caravan)	->
	Now			= misc:seconds(),
	CaravanId	= Caravan#caravan.id,
	Quality		= Caravan#caravan.quality,
	OtherId		= Caravan#caravan.user_id,
	OtherName	= Caravan#caravan.user_name,
	OtherPro	= Caravan#caravan.pro,
	OtherSex	= Caravan#caravan.sex,
	OtherLv		= Caravan#caravan.lv,
	GuildName	= Caravan#caravan.guild_name,
	FriendId	= Caravan#caravan.friend_id,
	FriendName	= Caravan#caravan.friend_name,
	Power		= partner_api:caculate_camp_power(OtherId),
	RemainTime	= case Caravan#caravan.end_time - Now >0 of
					  ?true -> Caravan#caravan.end_time - Now;
					  ?false -> ?CONST_SYS_FALSE
				  end,
	RobbedTimes = erlang:length(Caravan#caravan.robber),
	IsRobber	= lists:member(UserId, Caravan#caravan.robber),
	RobFlag		= Caravan#caravan.battling,
	Market		= Caravan#caravan.market,
%% 	Guild		= Caravan#caravan.guild,
	Factor		= Caravan#caravan.factor,
	{Gold, Exp}	= cal_rob_income(Market, Factor, Lv, OtherLv),
%% 	Experience  = cal_rob_experience(Guild, Market, Factor, Lv),
%% 	Experience1 = Exp + Experience,
	MsgCaravan	= [CaravanId, Quality, OtherId, OtherName, OtherPro, OtherSex, OtherLv,
				   GuildName, FriendId, FriendName, RemainTime, RobbedTimes, IsRobber,
				   Gold, Exp, Power, RobFlag],
	Packet		= commerce_api:pack_sc_caravan_info(MsgCaravan),
	misc_packet:send(UserId, Packet).

%% 商路玩家信息
commerce_info(Player)	->
	UserId		= Player#player.user_id,
	Commerce	= commerce_lookup(UserId),
	Packet		= commerce_api:pack_sc_commerce_info(Commerce),
	misc_packet:send(Player#player.net_pid, Packet).

rob_info(Player) ->
	RobInfo		= get_rob_info(),
	RobList		= RobInfo#commerce_rob_info.rob_list,
	Packet		= rob_info_cb(RobList, <<>>),
	misc_packet:send(Player#player.net_pid, Packet).
rob_info_cb([{UserId, UserName, UserId1, UserName1, Type, Gold, Exp}|RestList], Acc) ->
	Packet		= commerce_api:pack_sc_rob_info(UserId, UserName, UserId1, UserName1, Type, Gold, Exp),
	NewAcc		= <<Packet/binary, Acc/binary>>,
	rob_info_cb(RestList, NewAcc);
rob_info_cb([], Acc) ->
	Acc.

%% 商路市场信息
market_info(Player) ->
	case market_lookup() of
		Market when is_record(Market, commerce_market)	->
			BuilderId	= Market#commerce_market.user_id,
			BuilderName	= Market#commerce_market.user_name,
			TimeStamp	= Market#commerce_market.end_time,
			Packet		= commerce_api:pack_sc_market_info(BuilderId, BuilderName, TimeStamp),
			misc_packet:send(Player#player.net_pid, Packet);
		_Market	->	?true
	end.
%%-----------------------------------------------------------------------------------------------------------------------------
%% 离开商路场景
exit(Player)	->
	UserId			= Player#player.user_id,
	ets:delete(?CONST_ETS_COMMERCE_ONLINE, UserId).

logout(Player)	->
	UserId		= Player#player.user_id,
	Commerce	= commerce_lookup(UserId),
	commerce_db_mod:write_commerce(Commerce).
			
flush_offline(Player, _Data = #commerce_offline{type	   = ?CONST_COMMERCE_CARRY,
												gold	   = Gold})	->
	UserId		= Player#player.user_id,
	GuildBuff	= guild_api:get_commerce_add(Player),
	NewGold		= misc:ceil(Gold * (GuildBuff + 1)),
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, NewGold, ?CONST_COST_COMMERCE_FLUSH_OFFLINE),
%% 	NewPlayer	= player_api:plus_experience(Player, Experience),
	{?ok, Player};
flush_offline(Player, _Data = #commerce_offline{type		= ?CONST_COMMERCE_ESCORT_START,
											   user_name	= UserName,
											   escort_time	= EscortTime})	->
	commerce_api:escort_start_cb(Player, [UserName, EscortTime]);
flush_offline(Player, _Data = #commerce_offline{type		= ?CONST_COMMERCE_ESCORT_OVER,
											   user_name	= UserName,
											   gold			= Gold})	->
	commerce_api:escort_over_cb(Player, [UserName, Gold, ?CONST_SYS_FALSE]);
flush_offline(Player, _Data = #commerce_offline{type		= ?CONST_COMMERCE_ROB,
											   gold			= Gold})	->
	UserId		= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_COMMERCE_FLUSH_OFFLINE),
	{?ok, layer};
flush_offline(Player, _Data)	->	{?ok, Player}.

%%------------------------------------------------------------------------------------------------------------------------------------
%% 运送
carry(Player)	->
	Now				= misc:seconds(),
	UserId			= Player#player.user_id,
	Commerce		= commerce_lookup(UserId),
	?MSG_DEBUG("Commerce=~p~n", [Commerce]),
	TimesFlag		= Commerce#commerce.carry > ?CONST_SYS_FALSE,
	CarryFlag		= Commerce#commerce.carry_time < Now,
	Quality			= Commerce#commerce.quality,
	RecCaravan		= data_commerce:get_caravan_info(Quality),
	
	Caravan			= record_caravan(Player, Commerce, RecCaravan),
	EndTime			= Now + RecCaravan#rec_caravan.duration,
	FriendId		= Caravan#caravan.friend_id,
	EscortFlag		= case FriendId =:= ?CONST_SYS_FALSE of
						  ?true  -> ?true;
						  ?false ->
							  case commerce_lookup(FriendId) of
								  CommerceInfo when is_record(CommerceInfo, commerce) ->
									  EscortTimes	  = CommerceInfo#commerce.escort,
									  case EscortTimes - 1 < ?CONST_SYS_FALSE of
										  ?false ->
											  NewCommerce1		= CommerceInfo#commerce{escort		= EscortTimes - 1,
																						escort_time	= EndTime},
											  commerce_update(NewCommerce1),
											  ?true;
										  _ -> ?false
									  end;
								  _ -> 
									  ?false
							  end
					  end,
	case {TimesFlag, CarryFlag, EscortFlag} of
		{?true, ?true, ?true}	->
			case commerce_db_mod:create_caravan(Caravan) of
				{?ok, Id}	->
					NewCaravan	= Caravan#caravan{id = Id},
					caravan_update(NewCaravan),
					ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, #commerce_friend{user_id = UserId, _ = '_'}), %%把所有邀请的记录删除
					refresh_commerce(Commerce, NewCaravan),
					broadcast(NewCaravan),
					broadcast_world(NewCaravan),
					yunying_activity_mod:activity_unlimitted_award(Player, Caravan#caravan.quality,13),                    %活动运送获得奖励
					if Quality >= 3 ->
						   spirit_festival_activity_api:receive_redbag(UserId, 16, 1);
					   true ->
						   skip
					end,
					carry_ext(Player);
				{?error, ErrorCode}	->
					TipsPacket	= message_api:msg_notice(ErrorCode),
					misc_packet:send(UserId, TipsPacket),
					{?ok, Player}
			end;
		{?false, _, _}	->	%% 次数不够
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRY_NO_TIMES),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player};
		{_, ?false, _}	->	%% 在运送中
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRYING),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player};
		{_, _, ?false} ->   %% 护送次数不足
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ESCORT_NO_TIMES),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player}
	end.
%% 市场加成
market_bonus()	->
	Now	= misc:seconds(),
	case market_lookup() of
		Market when is_record(Market, commerce_market)
		  andalso Market#commerce_market.start_time	=< Now
		  andalso Market#commerce_market.end_time	>= Now	->
			?CONST_COMMERCE_MARKET_BONUS;
		_Market	-> ?CONST_COMMERCE_NO_BONUS
	end.
%% 军团加成
%% guild_bonus(Player) when is_record(Player, player)	->
%% 	case active_api:is_opened(?CONST_ACTIVE_COMMERCE) of
%% 		?CONST_SYS_TRUE		->
%% 			Guild	= Player#player.guild,
%% 			case Guild#guild.guild_id of
%% 				?CONST_SYS_FALSE ->	?CONST_COMMERCE_NO_BONUS;
%% 				_	->	?CONST_COMMERCE_GUILD_BONUS
%% 			end;
%% 		?CONST_SYS_FALSE	->	?CONST_COMMERCE_NO_BONUS
%% 	end;
%% guild_bonus(_Player)	->	?CONST_COMMERCE_NO_BONUS.

record_caravan(Player, Commerce, RecCaravan)	->
	Now			= misc:seconds(),
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Guild		= Player#player.guild,
	Friend		= friend_lookup(UserId),
	Quality		= Commerce#commerce.quality,
	RecCaravan	= data_commerce:get_caravan_info(Quality),
	EndTime		= Now + RecCaravan#rec_caravan.duration,
	MarketBonus	= market_bonus(),						%% 市场加成
%% 	GuildBonus	= guild_bonus(Player),				    %% 军团加成
	Caravan		= #caravan{quality		= Quality,
						   name			= RecCaravan#rec_caravan.name,
						   user_id		= UserId,
						   user_name	= Info#info.user_name,
						   pro			= Info#info.pro,
						   sex			= Info#info.sex,
						   lv			= Info#info.lv,
						   guild_id		= Guild#guild.guild_id,
						   guild_name	= Guild#guild.guild_name,
						   start_time	= Now,
						   end_time		= EndTime,
						   battling		= ?CONST_COMMERCE_IDLE,
						   failure		= ?CONST_SYS_FALSE,
						   robber		= [],
						   market		= MarketBonus,
%% 						   guild		= GuildBonus,
						   factor		= RecCaravan#rec_caravan.factor},
	record_caravan(Caravan, Friend).

record_caravan(Caravan	= #caravan{user_name	= UserName,
								   end_time		= EndTime},
			   _Friend	= #commerce_friend{friend_id	= FriendId,
										   friend_name	= FriendName})	->
	commerce_api:escort_start(FriendId, UserName, EndTime),
	Caravan#caravan{friend_id	= FriendId,	friend_name	= FriendName};
record_caravan(Caravan, _Friend)	->	Caravan.
%% 跑商每日活动及成长礼包
carry_ext(Player)	->
	{?ok, Player2}	= schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_COMMERCE_CARRY),
	{?ok, Player3}	= welfare_api:add_pullulation(Player2, ?CONST_WELFARE_COMMERCE, 0, 1),
	schedule_api:add_resource_times(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_COMMERCE),
	achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_CARRY, 0, 1).

escort_start_cb(Player, UserName, _EndTime)	->
	UserId		= Player#player.user_id,
	TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ESCORT_START, [{?TIP_SYS_COMM, UserName}]),
	misc_packet:send(UserId, TipsPacket),
	{?ok, NewPlayer} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_ESCORT, 0, 1),
	schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_COMMERCE_ESCORT).

escort_over_cb(Player, UserName, Gold, Experience)	->
	UserId		= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_COMMERCE_ESCORT_OVER),
	NewPlayer	= player_api:plus_experience(Player, Experience),
	TipsPacket	= case Experience =:= ?CONST_SYS_FALSE of
					  ?true ->
						  message_api:msg_notice(?TIP_COMMERCE_ESCORT_OVER, [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_COMM, misc:to_list(Gold)}]);
					  ?false ->
						  message_api:msg_notice(?TIP_COMMERCE_ESCORT_OVER1, [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_COMM, misc:to_list(Gold)},
																			  {?TIP_SYS_COMM, misc:to_list(Experience)}])
				  end,
	misc_packet:send(Player#player.net_pid, TipsPacket),
	{?ok, NewPlayer}.
%%---------------------------------------------------------------------------------------------------------------------------
%% 拦截
rob(Player, CaravanId)	->
	Now			= misc:seconds(),
	UserId		= Player#player.user_id,
	MapId		= map_api:get_cur_map_id(Player),
	CaravanInfo	= ets:match_object(?CONST_ETS_CARAVAN, #caravan{id = CaravanId, _ ='_'}),
	Commerce	= commerce_lookup(UserId),
	RobFlag		= Commerce#commerce.rob > 0 orelse Commerce#commerce.vip_rob > 0,
	RobTimeFlag	= Now > Commerce#commerce.rob_time,
	case erlang:length(CaravanInfo) =:= ?CONST_SYS_FALSE of
		?true ->                                        						     %% 商队已不存在
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ROB_FAIL),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		?false ->
			[Caravan|_]	= CaravanInfo,
			RobbedFlag	= erlang:length(Caravan#caravan.robber) < ?CONST_COMMERCE_ROBBED_MAXIMUM,
			RobberFlag	= lists:member(UserId, Caravan#caravan.robber),
			BattleFlag	= Caravan#caravan.battling,
			MyselfFlag	= Caravan#caravan.user_id =/= UserId,
			FriendFlag	= Caravan#caravan.friend_id =/= UserId,
			case {RobFlag, RobTimeFlag, RobbedFlag, RobberFlag, BattleFlag, MyselfFlag, FriendFlag} of
				{?true, ?true, ?true, ?false, ?CONST_COMMERCE_IDLE, ?true, ?true}	-> %% 可以拦截
					DefenderId		= case Caravan#caravan.friend_id of
										  ?CONST_SYS_FALSE	->	Caravan#caravan.user_id;
										  _	->	Caravan#caravan.friend_id
									  end,
					case battle_api:start(Player, DefenderId, #param{battle_type	= ?CONST_BATTLE_COMMERCE,
																	 ad1			= CaravanId,
																	 map_id		    = MapId}) of
						{?ok, Player1}			->
							{?ok, Player2}	= achievement_api:add_achievement(Player1, ?CONST_ACHIEVEMENT_ROB, 0, 1),         %% 拦截成就
							{?ok, Player3}	= schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_COMMERCE_ROB),      %% 每日活动
							ets:update_element(?CONST_ETS_CARAVAN, Caravan#caravan.user_id,
											   [{#caravan.battling, ?CONST_COMMERCE_BATTLING}]),
							Packet1	= commerce_api:pack_sc_rob_flag(CaravanId, ?CONST_COMMERCE_BATTLING),
							broadcast(Packet1),
							{?ok, Player3};
						{?error, _ErrorCode}	->	
							{?ok, Player}
					end;
				{?false, _, _, _, _, _, _}	->  %% 拦截次数已用完
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ROB_OVER),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, ?false, _, _, _, _, _}	->  %% 拦截cd
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ROB_CD_TIME),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, ?false, _, _, _, _}	->  %% 已经被截镖了2次
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ROBBED_OVER),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, _, ?true, _, _, _}	->  %%  已经截过此镖
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_HAVE_ROBBED),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, _, _, ?CONST_COMMERCE_BATTLING, _, _}	->  %% 正在被别人截镖中
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRY_BATTLING),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, _, _, _, ?false, _}	->  %% 不能拦截自己镖银
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_MYSELF),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, _, _, _, _, ?false}	->  %% 不能拦截自己护送的商队
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_FRIEND),
					misc_packet:send(Player#player.net_pid, TipsPacket),
					{?ok, Player};
				{_, _, _, _, _, _, _} ->
					{?ok, Player}
			end
	end.
	
rob_cb(Player, Result, CaravanId) when is_integer(CaravanId)	->
	CaravanInfo	= ets:match_object(?CONST_ETS_CARAVAN, #caravan{id = CaravanId, _ ='_'}),
	case erlang:length(CaravanInfo) =:= ?CONST_SYS_FALSE of
		?true -> {?ok, Player};
		?false ->
			[Caravan]	= CaravanInfo,
			NewCaravan	= case Caravan#caravan.battling of
							  ?CONST_COMMERCE_BATTLING	->	Caravan#caravan{battling = ?CONST_COMMERCE_IDLE};
							  ?CONST_COMMERCE_DELAY		->	Caravan
						  end,
			caravan_update(NewCaravan),
			rob_over_cb(Player, Result, NewCaravan)
	end.

rob_over_cb(Player, ?CONST_BATTLE_RESULT_LEFT, Caravan) when is_record(Caravan, caravan) -> %%拦截胜利
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	CaravanId	= Caravan#caravan.id,
	refresh_commerce(UserId),
	refresh_caravan(Caravan, UserId, UserName),

	Lv			= Info#info.lv,
	UserId1		= Caravan#caravan.user_id,
	UserName1	= Caravan#caravan.user_name,
	OtherLv		= Caravan#caravan.lv,
	Quality		= Caravan#caravan.quality,	
	Market		= Caravan#caravan.market,
%% 	Guild		= Caravan#caravan.guild,
	Factor		= Caravan#caravan.factor,
	{Gold, Exp}	= cal_rob_income(Market, Factor, Lv, OtherLv),						%% 拦截奖励--铜钱／历练
%% 	Experience  = cal_rob_experience(Guild, Market, Factor, Lv),
%% 	Experience1	= Exp + Experience,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_COMMERCE_ROB),
	NewPlayer	= player_api:plus_experience(Player, Exp),
	rob_delay(Caravan),
	RobInfo		= get_rob_info(),
	RobList		= RobInfo#commerce_rob_info.rob_list, 
	RobList1	= case erlang:length(RobList) < 4 of
					  ?true ->
						  [{UserId, UserName, UserId1, UserName1, Quality, Gold, Exp}|RobList];
					  ?false ->
						  List1		= [{UserId, UserName, UserId1, UserName1, Quality, Gold, Exp}|RobList],
						  get_rob_list(List1, ?CONST_SYS_FALSE, [])
				  end,
	NewRobInfo	= RobInfo#commerce_rob_info{id = ?CONST_SYS_TRUE, rob_list = RobList1},
	ets_api:insert(?CONST_ETS_COMMERCE_ROB_INFO, NewRobInfo),
	TipPacket1	= commerce_api:pack_sc_rob_notice(UserId, UserName, UserId1, UserName1, ?CONST_SYS_TRUE, Gold, Exp),
	misc_packet:send(Player#player.net_pid, TipPacket1),
	TipPacket2	= commerce_api:pack_sc_rob_notice(UserId, UserName, UserId1, UserName1, ?CONST_SYS_TRUE, Gold, Exp),
	misc_packet:send(UserId1, TipPacket2),
	Packet		= commerce_api:pack_sc_rob_info(UserId, UserName, UserId1, UserName1, Quality, Gold, Exp),
	Packet1		= commerce_api:pack_sc_rob_flag(CaravanId, ?CONST_COMMERCE_IDLE),
	Packet2		= <<Packet/binary, Packet1/binary>>,
	broadcast(Packet2),
	{?ok, NewPlayer};
rob_over_cb(Player, ?CONST_BATTLE_RESULT_RIGHT, Caravan) when is_record(Caravan, caravan)	-> %%拦截失败
	Info			= Player#player.info,
	UserId			= Player#player.user_id,
	UserName		= Info#info.user_name,
	CaravanId		= Caravan#caravan.id,
	RobbedId		= Caravan#caravan.user_id,
	RobbedName		= Caravan#caravan.user_name,

	TipPacket1		= commerce_api:pack_sc_rob_notice(UserId, UserName, RobbedId, RobbedName, ?CONST_SYS_FALSE, 0, 0),
	misc_packet:send(Player#player.net_pid, TipPacket1),

	Packet1			= commerce_api:pack_sc_rob_flag(CaravanId, ?CONST_COMMERCE_IDLE),
	broadcast(Packet1),

	TipPacket2		= commerce_api:pack_sc_rob_notice(UserId, UserName, RobbedId, RobbedName, ?CONST_SYS_FALSE, 0, 0),
	misc_packet:send(RobbedId, TipPacket2),
	rob_delay(Caravan),
	{?ok, Player};
rob_over_cb(Player, ?CONST_BATTLE_RESULT_DRAW, Caravan) when is_record(Caravan, caravan) ->  %% 平局
	Info			= Player#player.info,
	UserId			= Player#player.user_id,
	UserName		= Info#info.user_name,
	CaravanId		= Caravan#caravan.id,
	UserId1			= Caravan#caravan.user_id,
	UserName1		= Caravan#caravan.user_name,
	TipPacket1		= commerce_api:pack_sc_rob_notice(UserId, UserName, UserId1, UserName1, ?CONST_SYS_FALSE, 0, 0),
	misc_packet:send(Player#player.net_pid, TipPacket1),
	
	TipPacket2		= commerce_api:pack_sc_rob_notice(UserId, UserName, UserId1, UserName1, ?CONST_SYS_FALSE, 0, 0),
	misc_packet:send(UserId1, TipPacket2),
	
	Packet1			= commerce_api:pack_sc_rob_flag(CaravanId, ?CONST_COMMERCE_IDLE),
	broadcast(Packet1),
	rob_delay(Caravan),
	{?ok, Player}.

refresh_caravan(Caravan, RobberId, _RobberName) ->
	Robber			= Caravan#caravan.robber,
	NewRobber		= [RobberId | Robber],
	NewCaravan		= Caravan#caravan{robber = NewRobber},
	CaravanId		= NewCaravan#caravan.id,
	RobbedTimes		= erlang:length(NewCaravan#caravan.robber),
	RobbedPacket	= commerce_api:pack_sc_robbed(CaravanId, RobbedTimes),
	broadcast(RobbedPacket),
	caravan_update(NewCaravan).

rob_delay(Caravan = #caravan{battling = ?CONST_COMMERCE_DELAY})	->
	ets:match_delete(?CONST_ETS_CARAVAN, Caravan),
	commerce_db_mod:delete_caravan(Caravan#caravan.id);
rob_delay(_Caravan)	->	 ?ok.

%%------------------------------------------------------------------------------------------------------------------------------
%%　清除拦截cd
cd_rob_time(Player) ->
	UserId			= Player#player.user_id,
	Commerce		= commerce_lookup(UserId),
	RecCommerceCost	= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_ROB_CD),
	CDCost			= RecCommerceCost#rec_commerce_cost.cost,	
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CDCost, ?CONST_COST_COMMERCE_ROB_CD) of
		?ok ->
			NewCommerce	= Commerce#commerce{rob_time = ?CONST_SYS_FALSE},
			commerce_update(NewCommerce);
		{?error, _ErrorCode}	->	?true
	end.
%%---------------------------------------------------------------------------------------------------------------------------------
%% 购买拦截次数
buy_rob_times(Player) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	Commerce		= commerce_lookup(UserId),
	VipRobTimes		= Commerce#commerce.vip_rob,
	VipRobMax		= player_vip_api:can_commerce_buy_rob_times(VipLv),
	VipRobFlag		= VipRobTimes < VipRobMax,
	RecCommerce		= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_BUY_ROB_TIMES),
	RecCommerceCost	= RecCommerce#rec_commerce_cost.cost,
	RobCost			= RecCommerceCost * (VipRobTimes + 1),
	case VipRobFlag of
		?true->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, RobCost, ?CONST_COST_COMMERCE_ROB_TIMES) of
				?ok	->
					VipRob		= Commerce#commerce.vip_rob,
					NewVipRob	= VipRob + 1,
					NewCommerce	= Commerce#commerce{vip_rob	= NewVipRob},
					commerce_update(NewCommerce);
				{?error, _ErrorCode}	->	?true
			end;
		?false	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_NO_ROB_TIMES),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 刷新商队品质
refresh(Player) ->
	UserId		= Player#player.user_id,
	Market		= market_bonus(),
%% 	Guild		= guild_bonus(Player),
	Commerce	= commerce_lookup(UserId),
	Quality		= Commerce#commerce.quality,
	CarryFlag	= Commerce#commerce.carry > ?CONST_SYS_FALSE,
	FreeRefresh	= Commerce#commerce.freerefresh,
	Refresh		= Commerce#commerce.refresh,
	RecCommerce	= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_SINGLE_REFRESH),
	CashCost	= RecCommerce#rec_commerce_cost.cost,

	?MSG_DEBUG("~nCarryFlag=~p~nQuality=~p~n", [CarryFlag, Quality]),
	case {CarryFlag, Quality} of
		{_, ?CONST_COMMERCE_RED_CARAVAN}	->       %% 已经刷新到最新品质
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_HIGHEST_QUALITY),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{?true, _Quality}	->
			case FreeRefresh > ?CONST_SYS_FALSE of
				?true	->                           %% 还有免费刷新次数
					NewFreeRefresh		= FreeRefresh - 1,
					{NewQuality, Gold, 	Experience}	= refresh(Player, Market, Quality),
					NewCommerce			= Commerce#commerce{freerefresh	= NewFreeRefresh, quality = NewQuality},
					refresh1(UserId, Quality, NewCommerce, Gold, Experience);
				?false	->                           %% 没有免费刷新次数
					case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, CashCost, ?CONST_COST_COMMERCE_REFRESH) of
						?ok ->
							NewRefresh			= Refresh + 1,
							{NewQuality, Gold, Experience}	= refresh(Player, Market, Quality),
							NewCommerce			= Commerce#commerce{refresh	= NewRefresh, quality = NewQuality},
							refresh1(UserId, Quality, NewCommerce, Gold, Experience);
						{?error, _ErrorCode}	->	?true
					end
			end;
		{?false, _Quality}	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRY_NO_TIMES),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 刷新获得新的品质及奖励
refresh(Player, Market, Quality) when is_record(Player, player)	->        
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	RecCaravan		= data_commerce:get_caravan_info(Quality),
	{List, Sum}		= RecCaravan#rec_caravan.refresh,
	NewQuality		= misc_random:odds_one(List, Sum),
	NewRecCaravan	= data_commerce:get_caravan_info(NewQuality),
	Factor			= NewRecCaravan#rec_caravan.factor,
	Gold			= cal_carry_income(Market, Factor, Lv),
%% 	Experience		= cal_carry_experience(Guild, Market, Factor, Lv),
	GuildBuff		= guild_api:get_commerce_add(Player),
	RealGold		= misc:ceil(Gold * (GuildBuff + 1)),
	{NewQuality, RealGold, ?CONST_SYS_FALSE}.

%% 记录刷新结果
refresh1(UserId, Quality, Commerce, Gold, Experience) when is_integer(UserId)	->            
	NewQuality	= Commerce#commerce.quality,
	FreeRefresh	= Commerce#commerce.freerefresh,
	ets:insert(?CONST_ETS_COMMERCE, Commerce),
	TipsPacket	= case Quality =:= NewQuality of
					  ?true ->	                                                  %% 刷新失败
						  message_api:msg_notice(?TIP_COMMERCE_REFRESH_FAIL);     
					  ?false ->													  %% 刷新成功
						  message_api:msg_notice(?TIP_COMMERCE_REFRESH_SUCCESS) 
				  end,
	Packet		= commerce_api:pack_sc_quality_info(NewQuality, Gold, FreeRefresh, Experience),
	misc_packet:send(UserId, <<Packet/binary, TipsPacket/binary>>).
%%-------------------------------------------------------------------------------------------------------------------------
%% 一键刷新
one_key_refresh(Player) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	VipLv		= player_api:get_vip_lv(Info),
	VipFlag		= player_vip_api:can_commerce_2_red(VipLv),
	Lv			= Info#info.lv,
	Market		= market_bonus(),
%% 	Guild		= guild_bonus(Player),
	Commerce	= commerce_lookup(UserId),
	Quality		= Commerce#commerce.quality,
	CarryFlag	= Commerce#commerce.carry > ?CONST_SYS_FALSE,
	RecCommerceCost	= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_ONE_KEY_REFRESH),
	CashCost	= RecCommerceCost#rec_commerce_cost.cost,

	case {VipFlag, CarryFlag, Quality} of
		{_, _, ?CONST_COMMERCE_RED_CARAVAN}		->
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_HIGHEST_QUALITY),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{?CONST_SYS_TRUE, ?true, _Quality}	->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CashCost, ?CONST_COST_COMMERCE_ONE_REFRESH) of
				?ok ->
					NewQuality	= ?CONST_COMMERCE_RED_CARAVAN,                    %%商队品质最高级
					RecCaravan	= data_commerce:get_caravan_info(NewQuality),
					Factor		= RecCaravan#rec_caravan.factor,
					Gold		= cal_carry_income(Market, Factor, Lv),
%% 					Experience	= cal_carry_experience(Guild, Market, Factor, Lv),
					GuildBuff	= guild_api:get_commerce_add(Player),
					RealGold	= misc:ceil(Gold * (GuildBuff + 1)),
					NewCommerce	= Commerce#commerce{refresh	= 0, quality = NewQuality},
					refresh1(UserId, Quality, NewCommerce, RealGold, ?CONST_SYS_FALSE);
				{?error, _ErrorCode}	->	?true
			end;
		{?CONST_SYS_FALSE, _, _Quality}	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{_, ?false, _Quality}	->
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRY_NO_TIMES),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.
%%-------------------------------------------------------------------------------------------------------------------------------------
%% 加速运送
speed_up(Player) ->
	Now		= misc:seconds(),
	UserId	= Player#player.user_id,
	Info	= Player#player.info,
	VipLv	= player_api:get_vip_lv(Info),
	VipFlag	= player_vip_api:can_commerce_run(VipLv),
	RecCommerceCost	= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_ONE_KEY_CARRY),
	{
	 Caravan, CarryFlag, CashCost
	}		= case caravan_lookup(UserId) of
				  Data when is_record(Data, caravan) andalso Data#caravan.end_time > Now	->
					  Cost	= RecCommerceCost#rec_commerce_cost.cost,
					  {Data, ?true, Cost};
				  Data	->	
					  {Data, ?false, ?CONST_SYS_FALSE}
			  end,
	case {VipFlag, CarryFlag} of
		{?CONST_SYS_TRUE, ?true}	->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CashCost, ?CONST_COST_COMMERCE_SPEED_UP) of
				?ok						->
					case Caravan#caravan.battling of
						?CONST_COMMERCE_BATTLING ->
							NewCaravan	= Caravan#caravan{end_time	= Now,	battling = ?CONST_COMMERCE_DELAY},
							caravan_update(NewCaravan);
						_ ->
							ets_api:delete(?CONST_ETS_CARAVAN, UserId),
							commerce_db_mod:delete_caravan(Caravan#caravan.id)
					end,
					carry_over(Player, [Caravan, ?true]);
				{?error, _ErrorCode}	->  {?ok, Player}
			end;
		{?CONST_SYS_FALSE, _}	->               %% VIP等级不足
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, ?false}	->							 %% 跑商已经结束 
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRY_OVER),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

%%　跑商结束处理
carry_over(Player, [Caravan, IsSpeedUp])	->
	Now			= misc:seconds(),
	UserId		= Caravan#caravan.user_id,
	UserName	= Caravan#caravan.user_name,
	Lv			= Caravan#caravan.lv,
	Market		= Caravan#caravan.market,
%% 	Guild		= Caravan#caravan.guild,
	Factor		= Caravan#caravan.factor,
	Gold		= cal_carry_income(Market, Factor, Lv) ,
%% 	Experience	= cal_carry_experience(Guild, Market, Factor, Lv),

	%% 处理护镖好友
	case IsSpeedUp of
		?true ->
			FriendId	= Caravan#caravan.friend_id,
			case FriendId =:= ?CONST_SYS_FALSE of
				?true  -> ?ok;
				?false ->
					FriendGold	= cal_escort_income(Market, Factor, Lv),
%% 					Experience1 = cal_escort_experience(Guild, Market, Factor, Lv),
					commerce_api:escort_over(FriendId, UserName, FriendGold, ?CONST_SYS_FALSE)
			end;
		?false -> ?ok
	end,

%% 	?MSG_DEBUG("~nCaravan=~p~n", [Caravan]),
	Commerce	= commerce_lookup(UserId),
	NewCommerce	= Commerce#commerce{carry_time	= Now},
	commerce_update(NewCommerce),
	GuildBuff   = guild_api:get_commerce_add(Player),
	NewGold	    = misc:ceil(Gold * (GuildBuff + 1)),
	Player2		= case player_api:check_online(UserId) of
					  ?true ->
						  player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, NewGold, ?CONST_COST_COMMERCE_CARRY_OVER),
%% 						  Player1	= player_api:plus_experience(Player, Experience),
						  ComPacket = commerce_api:pack_sc_completion(Caravan#caravan.id, NewGold, ?CONST_SYS_FALSE),
						  TipsPacket= message_api:msg_notice(?TIP_COMMERCE_CARRY_INCOME, [{?TIP_SYS_COMM, misc:to_list(NewGold)}]),
						  misc_packet:send(UserId, <<ComPacket/binary, TipsPacket/binary>>),
						  Player;
					  ?false -> 
						  CommerceOffLine	= #commerce_offline{type = ?CONST_COMMERCE_CARRY, gold = Gold},
						  player_offline_api:offline(?MODULE, UserId, CommerceOffLine),
						  Player
				  end,
	BroadPacket	= commerce_api:pack_sc_caravan_vanish(Caravan#caravan.id, IsSpeedUp),
	broadcast(BroadPacket),
	{?ok, Player2}.
%%------------------------------------------------------------------------------------------------------------------------------------
%% 建造市场
build_market(Player)	->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	VipFlag			= player_vip_api:can_commerce_build_market(VipLv),
	MarketFlag		= case market_lookup() of
						  Market when is_record(Market, commerce_market)	->	?true;
						  _Market											->	?false
					  end,
	RecCommerceCost	= data_commerce:get_commerce_cost(?CONST_COMMERCE_KEY_BUILD_MARKET),
	?MSG_WARNING("~nRecCommerceCost=~p~n", [RecCommerceCost]),
	CashCost		= RecCommerceCost#rec_commerce_cost.cost,

	case {VipFlag, MarketFlag} of
		{?CONST_SYS_TRUE, ?false}	->    %% VIP 且此时没有市场存在
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, CashCost, ?CONST_COST_COMMERCE_BUILD_MARKE) of
				?ok	->
					BuildMarket	= record_market(Player, RecCommerceCost),
					case commerce_db_mod:create_market(BuildMarket) of
						{?ok, Id}	->
							NewBuildMarket	= BuildMarket#commerce_market{id = Id},
							ets:insert(?CONST_ETS_COMMERCE_MARKET, NewBuildMarket),
							MarketPacket	= commerce_api:pack_sc_build_market(UserId),
							Meritorious		= RecCommerceCost#rec_commerce_cost.meritorious,
							Mer				= misc:to_list(Meritorious),
							TipsPacket		= message_api:msg_notice(?TIP_COMMERCE_BUILD_MARKET_SUCCESS, [{?TIP_SYS_COMM, Mer}]),
							misc_packet:send(Player#player.net_pid, <<MarketPacket/binary, TipsPacket/binary>>),
							broadcast(NewBuildMarket),
							broadcast_world(NewBuildMarket),
							player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_COMMERCE_BUILD_MARKE);
						{?error, ErrorCode}	->
							TipsPacket		= message_api:msg_notice(ErrorCode),
							misc_packet:send(UserId, TipsPacket),
							{?ok, Player}
					end;
				{?error, _ErrorCode}	->	{?ok, Player}
			end;                             
		{?CONST_SYS_FALSE, _}	->             %% VIP等级不够
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{_, ?true}	->                         %% 市场已存在
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_MARKET_EXIST),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

record_market(Player, RecCommerceCost)	->
	Now			= misc:seconds(),
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	EndTime		= Now + RecCommerceCost#rec_commerce_cost.duration,
	#commerce_market{
					 user_id	= UserId,
					 user_name	= UserName,
					 start_time	= Now,
					 end_time	= EndTime
					}.
%%------------------------------------------------------------------------------------------------------------------------------
%% 请求好友信息
friend_info(Player)	->
	UserId			= Player#player.user_id,
	RelationList	= relation_api:list_bilateral_friend(UserId),
	Fun		= fun(FriendId) ->
					  case player_api:check_online(FriendId) of
						  ?true ->
                              SysRank = data_guide:get_task_rank(?CONST_MODULE_COMMERCE),
							  case player_api:get_player_fields(FriendId, [#player.info, #player.sys_rank]) of
								  {?ok, [#info{user_name = FriendName, lv = FriendLv}, Sys]}
									when Sys >= SysRank ->
									  Commerce		= commerce_lookup(FriendId),
									  Escort		= Commerce#commerce.escort,
									  FriendList	= [FriendId, FriendName, FriendLv, Escort],
									  ?MSG_DEBUG("~nFriendList=~p~n", [FriendList]),
									  Packet		= commerce_api:pack_sc_friend_info(FriendList),
									  misc_packet:send(UserId, Packet);
								  _Other ->	?ignore
							  end;
						  ?false -> ?ignore
					  end
			  end,
	lists:foreach(Fun, RelationList).

%% 请求刷新品质
quality_info(Player) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	Market		= market_bonus(),
%% 	Guild		= guild_bonus(Player),
	Commerce	= commerce_lookup(UserId),
	VisiteFlag	= Commerce#commerce.flag_invite,
	Quality		= Commerce#commerce.quality,
	RecCaravan	= data_commerce:get_caravan_info(Quality),
	Factor		= RecCaravan#rec_caravan.factor,
	Gold		= cal_carry_income(Market, Factor, Lv),
%% 	Experience	= cal_carry_experience(Guild, Market, Factor, Lv),
	GuildBuff	= guild_api:get_commerce_add(Player),
	RealGold	= misc:ceil(Gold * (GuildBuff + 1)),
	?MSG_DEBUG("Gold=~p, RealGold=~p, GuildBuff=~p Factor=~p", [Gold, RealGold, GuildBuff, Factor]),
	FreeRefresh	= Commerce#commerce.freerefresh,
	Packet		= commerce_api:pack_sc_quality_info(Quality, RealGold, FreeRefresh, ?CONST_SYS_FALSE),
	Packet1		= commerce_api:pack_sc_ignore_invite(VisiteFlag),
	misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>).
%%--------------------------------------------------------------------------------------------------------------------------------
%% 邀请好友护送
invite(Player, FriendId, FriendName) ->
	Now				= misc:seconds(),
	Commerce		= commerce_lookup(Player#player.user_id),
	CarryFlag		= Commerce#commerce.carry_time < Now,

	OnLineFlag		= player_api:check_online(FriendId),
	FriendCommerce	= commerce_lookup(FriendId),
	EscortFlag		= FriendCommerce#commerce.escort > ?CONST_SYS_FALSE,
	IsFilter		= FriendCommerce#commerce.flag_invite =:= ?CONST_SYS_FALSE,			%% 好友是否标记了忽略所有邀请
	InviteFlag		= check_agree_escort(FriendId),
	InEscortFlag	= check_in_escort(FriendId),
	case {OnLineFlag, EscortFlag, InviteFlag, InEscortFlag, IsFilter, CarryFlag} of
		{?true, ?true, ?true, ?true, ?true, ?true}	->
			UserId			= Player#player.user_id,
			Info			= Player#player.info,
			UserName		= Info#info.user_name,
			CommerceFriend	= record_friend(Player, FriendId, FriendName),
			ets:insert(?CONST_ETS_COMMERCE_FRIEND, CommerceFriend),
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_TRUE),
			misc_packet:send(Player#player.net_pid, InvitePacket),
			InformPacket	= commerce_api:pack_sc_inform(UserId, UserName),
			misc_packet:send(FriendId, InformPacket);
		{?false, _, _, _, _, _}	->	%% 对方不在线
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_FALSE),
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_OFF_LINE),
			misc_packet:send(Player#player.net_pid, <<InvitePacket/binary, TipsPacket/binary>>);
		{_, ?false, _, _, _, _}	->	%% 对方护送次数已满
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_FALSE),
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ESCORT_NO_TIMES),
			misc_packet:send(Player#player.net_pid, <<InvitePacket/binary, TipsPacket/binary>>);
		{_, _, ?false, _, _, _}	->	%% 对方已经答应护送别人
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_FALSE),
			TipsPacket		= message_api:msg_notice(?TIP_COMMERCE_ESCORTING),
			misc_packet:send(Player#player.net_pid, <<InvitePacket/binary, TipsPacket/binary>>);
		{_, _, _, ?false, _, _}	->	%% 对方正在护送
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_FALSE),
			TipsPacket		= message_api:msg_notice(?TIP_COMMERCE_ESCORTING),
			misc_packet:send(Player#player.net_pid, <<InvitePacket/binary, TipsPacket/binary>>);
		{_, _, _, _, ?false, _}    ->   %% 对方忽略了所有邀请
			TipsPacket		= message_api:msg_notice(?TIP_COMMERCE_IGNORE_INVITE),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{_, _, _, _, _, ?false}	->	%% 在运送中
			InvitePacket	= commerce_api:pack_sc_invite(?CONST_SYS_FALSE),
			TipsPacket	    = message_api:msg_notice(?TIP_COMMERCE_CARRYING),
			misc_packet:send(Player#player.net_pid, <<InvitePacket/binary, TipsPacket/binary>>)
	end.

%% 检查是否是同意状态
check_agree_escort(FriendId)	->
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_FRIEND),
	FilFun	= fun(Friend)	->
					  FriendFlag	= Friend#commerce_friend.friend_id =:= FriendId,
					  StateFlag		= Friend#commerce_friend.state =:= ?CONST_COMMERCE_FRIEND_ACCEPT,
					  FriendFlag andalso StateFlag
			  end,
	case lists:filter(FilFun, EtsList) of
		[]						->	?true;
		[Friend | _FriendList]	->	Now > Friend#commerce_friend.escort_time
	end.
%% 检查是否正在护送
check_in_escort(FriendId)	->
	EtsList	= ets_api:list(?CONST_ETS_CARAVAN),
	FilFun	= fun(Caravan)	->	
					  Caravan#caravan.friend_id =:= FriendId	
			  end,
	case lists:filter(FilFun, EtsList) of
		[]	->	?true;
		_	->	?false
	end.

record_friend(Player, FriendId, FriendName)	->
	Now			= misc:seconds(),
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	ExpiredTime	= Now + ?CONST_COMMERCE_INVITE_TIME,
	#commerce_friend{user_id		= UserId,
					 user_name		= UserName,
					 friend_id		= FriendId,
					 friend_name	= FriendName,
					 state			= ?CONST_COMMERCE_FRIEND_INVITING,
					 invite_time	= ExpiredTime}.
%%--------------------------------------------------------------------------------------------------------------------------------------
%% 邀请好友回复
reply(Player, FriendId, Reply) ->
	UserId		= Player#player.user_id,
	OnLineFlag	= player_api:check_online(FriendId),
	Commerce	= commerce_lookup(UserId),
	TimesFlag	= Commerce#commerce.escort > ?CONST_SYS_FALSE ,
	CarryFlag	= case caravan_lookup(FriendId) of
					  Caravan when is_record(Caravan, caravan)	->	?false;
					  _Caravan									->	?true
				  end,
	Now			= misc:seconds(),
	case {OnLineFlag, TimesFlag, CarryFlag} of
		{?true, ?true, ?true} ->
			EtsList		= ets_api:list(?CONST_ETS_COMMERCE_FRIEND),
			FilFun		= fun(Friend)	->
								  UserFlag		= Friend#commerce_friend.user_id =:= FriendId,
								  FriendFlag	= Friend#commerce_friend.friend_id =:= UserId,
								  InviteFlag	= Friend#commerce_friend.state =:= ?CONST_COMMERCE_FRIEND_INVITING,
								  InviteTime	= Friend#commerce_friend.invite_time > Now,
								  UserFlag andalso FriendFlag andalso InviteFlag andalso InviteTime
						  end,
			FriendList	= lists:filter(FilFun, EtsList),
			case FriendList of 
				[]	->                                              %% 已经超时
					FriendRecord = #commerce_friend{user_id = FriendId, friend_id = UserId, state = ?CONST_COMMERCE_FRIEND_INVITING, _ = '_'},
					ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, FriendRecord),
					TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_INVITE_OVERDURE),
					misc_packet:send(Player#player.net_pid, TipsPacket);
				[Friend | _FriendList]	->
					?MSG_DEBUG("Friend=~p", [Friend]),
					case Reply of
						?CONST_COMMERCE_REPLY_ACCEPT	->	%% 同意
					
							ExpiredTime	= Now + ?CONST_COMMERCE_CARRY_TIME,                   %% 30秒邀请
							NewFriend	= Friend#commerce_friend{state = ?CONST_COMMERCE_FRIEND_ACCEPT, escort_time = ExpiredTime},
							ets:insert(?CONST_ETS_COMMERCE_FRIEND, NewFriend),
							Packet		= commerce_api:pack_sc_reply(NewFriend#commerce_friend.friend_id,
																	 NewFriend#commerce_friend.friend_name,
																	 ?CONST_COMMERCE_REPLY_ACCEPT),
							misc_packet:send(NewFriend#commerce_friend.user_id, Packet);
						?CONST_COMMERCE_REPLY_REJECT	->	%% 拒绝
							ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, Friend),
							Packet		= commerce_api:pack_sc_reply(Friend#commerce_friend.friend_id,
																	 Friend#commerce_friend.friend_name,
																	 ?CONST_COMMERCE_REPLY_REJECT),
							misc_packet:send(Friend#commerce_friend.user_id, Packet);
						_Other	->
							TipsPacket	= message_api:msg_notice(?TIP_COMMON_OFF_LINE),
							misc_packet:send(Player#player.net_pid, TipsPacket)
					end
			end;
		{?false, _, _}	->	%% 对方不在线
			TipsPacket	= message_api:msg_notice(?TIP_COMMON_OFF_LINE),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{_, ?false, _}	->	%% 玩家护送次数已用完
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_ESCORT_NOT_TIMES),
			misc_packet:send(Player#player.net_pid, TipsPacket);
		{_, _, ?false}	->	%% 玩家已经开始了运送商品
			TipsPacket	= message_api:msg_notice(?TIP_COMMERCE_CARRYING),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end,
	%% 通知好友
	?ok.

%% 标记忽略所有邀请
flag_invite(Player, Type) ->			 %% Type = 1标记忽略邀请  0 取消标记忽略邀请
	UserId		= Player#player.user_id,
	Commerce	= commerce_lookup(UserId),
	NewCommerce	= Commerce#commerce{flag_invite = Type},
	ets_api:insert(?CONST_ETS_COMMERCE, NewCommerce).
%%
%% Local Functions
%%
market_lookup()	->
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_MARKET),
	Fun		= fun(Data)	->	
					  Data#commerce_market.end_time > Now	
			  end,
	case lists:filter(Fun, EtsList) of
		[]						->	?null;
		[Market | _MarketList]	->	Market
	end.

market_clear()	->
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_MARKET),
	FilFun	= fun(Data)	->	
					  Data#commerce_market.end_time < Now	
			  end,
	FilList	= lists:filter(FilFun, EtsList),
	ProFun	= fun(Market)	->
					  ets:match_delete(?CONST_ETS_COMMERCE_MARKET, Market),
					  commerce_db_mod:delete_market(Market#commerce_market.id),
					  UserId	= Market#commerce_market.user_id,
					  Packet	= commerce_api:pack_sc_market_vanish(UserId),
					  broadcast(Packet)
			  end,
	lists:foreach(ProFun, FilList).

caravan_lookup(UserId)	->                        %% 商路记录查询
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_CARAVAN),
	FilFun	= fun(Data)	->
					  Data#caravan.user_id =:= UserId andalso Data#caravan.end_time > Now
			  end,
	case lists:filter(FilFun, EtsList) of
		[]							->	?null;
		[Caravan | _CaravanList]	->	Caravan
	end.

caravan_update(Caravan) when is_record(Caravan, caravan)	->
	ets:insert(?CONST_ETS_CARAVAN, Caravan).

caravan_clear() ->
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_CARAVAN),
	Fun		= fun(Caravan)	->
					  case {Caravan#caravan.end_time > Now, Caravan#caravan.battling} of
						  {?false, ?CONST_COMMERCE_IDLE}	->  %% 空闲
							  UserId		= Caravan#caravan.user_id,
							  UserName		= Caravan#caravan.user_name,
							  Lv			= Caravan#caravan.lv,
							  Market		= Caravan#caravan.market,
%% 							  Guild			= Caravan#caravan.guild,
							  Factor		= Caravan#caravan.factor,
							  
							  %% 处理护镖好友
							  FriendId		= Caravan#caravan.friend_id,
							  commerce_db_mod:delete_caravan(Caravan#caravan.id),
							  case ets_api:delete(?CONST_ETS_CARAVAN, UserId) of
								  ?true ->
									  case FriendId =:= ?CONST_SYS_FALSE of
										  ?true  -> ?ok;
										  ?false ->
											  FriendGold	= cal_escort_income(Market, Factor, Lv),
%% 											  Experience1   = cal_escort_experience(Guild, Market, Factor, Lv),
											  commerce_api:escort_over(FriendId, UserName, FriendGold, ?CONST_SYS_FALSE)
									  end,
									  case player_api:process_send(UserId, ?MODULE, carry_over, [Caravan, ?false]) of
										  ?true  -> ?true;
										  ?false ->
											  Gold			= cal_carry_income(Market, Factor, Lv) ,
%% 											  Experience	= cal_carry_experience(Guild, Market, Factor, Lv),
											  CommerceOffLine= #commerce_offline{type = ?CONST_COMMERCE_CARRY, gold = Gold},
											  player_offline_api:offline(?MODULE, UserId, CommerceOffLine),
											  BroadPacket	= commerce_api:pack_sc_caravan_vanish(Caravan#caravan.id, ?false),
											  broadcast(BroadPacket),
											  ?true
									  end;
								  _ -> ?true
								end;
						  {?false, ?CONST_COMMERCE_DELAY}	->  
							  ?true;
						  {?true, _}						->	%% 正在运送
							  ?true;
						  {_, ?CONST_COMMERCE_BATTLING}		->	%% 正在战斗
							  ?true
					  end
			  end,
	lists:foreach(Fun, EtsList).

commerce_lookup(UserId)	->                             %% 商路玩家查询
	Today	= misc:date_num(),
	case ets:lookup(?CONST_ETS_COMMERCE, UserId) of
		[]	->
			case commerce_db_mod:read_commerce(UserId) of
				{?ok, ?null}	->
					Commerce	= record_commerce(UserId, Today),
					ets:insert(?CONST_ETS_COMMERCE, Commerce),
					commerce_db_mod:create_commerce(Commerce),
					Commerce;
				{?ok, Data}		->
					refresh_commerce(Data, Today)
			end;
		[Data | _DataList]	->
			refresh_commerce(Data, Today)
	end.

record_commerce(UserId, Today)	->
	#commerce{
			  user_id		= UserId,
			  date			= Today,
			  carry			= ?CONST_COMMERCE_CARRY_MAXIMUM,
			  escort		= ?CONST_COMMERCE_ESCORT_MAXIMUM,
			  rob			= ?CONST_COMMERCE_ROB_MAXIMUM,
			  freerefresh	= ?CONST_COMMERCE_FREEREFRESH_MAXIMUM,
			  quality		= ?CONST_COMMERCE_GREEN_CARAVAN
			 }.

refresh_commerce(UserId) ->
	Now			= misc:seconds(),
	Commerce	= commerce_lookup(UserId),
	NewCommerce	= case Commerce#commerce.rob > ?CONST_SYS_FALSE of
					  ?true		->
						  Rob		= Commerce#commerce.rob,
						  NewRob	= Rob - 1,
						  Commerce#commerce{rob 		= NewRob,
											rob_time	= Now + ?CONST_COMMERCE_ROB_CD_TIME};
					  ?false	->
						  VipRob	= Commerce#commerce.vip_rob,
						  NewVipRob	= VipRob - 1,
						  Commerce#commerce{vip_rob		= NewVipRob,
											rob_time	= Now + ?CONST_COMMERCE_ROB_CD_TIME}
				  end,
	commerce_update(NewCommerce).
refresh_commerce(Commerce, Today) when is_integer(Today)	->
	case Commerce#commerce.date of
		Today	->
			ets:insert(?CONST_ETS_COMMERCE, Commerce),
			Commerce;
		_Date	->
			UserId		= Commerce#commerce.user_id,
			NewCommerce	= record_commerce(UserId, Today),
			ets:insert(?CONST_ETS_COMMERCE, NewCommerce),
			NewCommerce
	end;
refresh_commerce(Commerce, Caravan) when is_record(Caravan, caravan)	->
	Carry		= Commerce#commerce.carry,
	EndTime		= Caravan#caravan.end_time,
	NewCommerce	= Commerce#commerce{carry		= Carry - 1,
									refresh		= ?CONST_SYS_FALSE,
									quality		= ?CONST_COMMERCE_GREEN_CARAVAN,
									carry_time	= EndTime},
	commerce_update(NewCommerce).

commerce_update(Commerce)	->
	ets:insert(?CONST_ETS_COMMERCE, Commerce),
	Packet	= commerce_api:pack_sc_commerce_info(Commerce),
	misc_packet:send(Commerce#commerce.user_id, Packet).

commerce_clear()	->
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE),
	Fun		= fun(Commerce)	->
					  case {Commerce#commerce.rob_time > Now, Commerce#commerce.rob_time =:= ?CONST_SYS_FALSE} of
						  {?false, ?false}	->
							  NewCommerce	= Commerce#commerce{rob_time = ?CONST_SYS_FALSE},
							  commerce_update(NewCommerce);
						  {?true, _}	->	%% 拦截时间尚未过时
							  ?true;
						  {_, ?true}	->	%% 没有拦截，不需要发送
						 	  ?true
					  end
			  end,
	lists:foreach(Fun, EtsList).

friend_lookup(UserId)	->                           %% 商路好友查询
	Now		= misc:seconds(),
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_FRIEND),
	FilFun	= fun(Friend)	->
					  UserFlag	= Friend#commerce_friend.user_id =:= UserId,
					  StateFlag	= Friend#commerce_friend.state =:= ?CONST_COMMERCE_FRIEND_ACCEPT,
					  TimeFlag	= Friend#commerce_friend.escort_time > Now,
					  UserFlag andalso StateFlag andalso TimeFlag
			  end,
	case lists:filter(FilFun, EtsList) of
		[]						->	?null;
		[Friend | _FriendList]	->	Friend
	end.

friend_clear()	->
    case ets:first(?CONST_ETS_COMMERCE_FRIEND) of
        '$end_of_table' ->
            ok;
        Key ->
            friend_clear_2(Key)
    end.

friend_clear_2(Key) ->
    case ets_api:lookup(?CONST_ETS_COMMERCE_FRIEND, Key) of
        #commerce_friend{user_id        = _UserId,
                                       friend_id    = _FriendId,
                                       friend_name  = _FriendName,
                                       state        = ?CONST_COMMERCE_FRIEND_INVITING,
                                       invite_time  = InviteTime} = Friend ->
        	Now	= misc:seconds(),
        	case InviteTime > Now of
        		?false	->
        			ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, Friend);
        		?true	->	?true
        	end;
        #commerce_friend{user_id		= _UserId,
									   friend_id	= _FriendId,
									   friend_name	= _FriendName,
									   state		= ?CONST_COMMERCE_FRIEND_ACCEPT,
									   escort_time	= EscortTime} = Friend	->
        	Now	= misc:seconds(),
        	case EscortTime > Now of
        		?false	->
        			ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, Friend);
        		?true	->	?true
        	end;
        ?null ->
            ok;
        Friend ->
        	ets:match_delete(?CONST_ETS_COMMERCE_FRIEND, Friend)
    end,
    case ets:next(?CONST_ETS_COMMERCE_FRIEND, Key) of
        '$end_of_table' ->
            ok;
        Key2 ->
            friend_clear_2(Key2)
    end.

%%零点更新商路次数
refresh_commerce_times() ->
    case ets:first(?CONST_ETS_COMMERCE) of
        '$end_of_table' ->
            ok;
        Key ->
            refresh_commerce_times_2(Key)
    end.

refresh_commerce_times_2(Key) ->
    case ets_api:lookup(?CONST_ETS_COMMERCE, Key) of
        #commerce{date = OldDate} = Commerce ->
            Today       = misc:date_num(),
            case OldDate =:= Today of
                ?true  -> ?ok;
                ?false -> 
                    NewCommerce = Commerce#commerce{
                                                    date        = Today,
                                                    carry       = ?CONST_COMMERCE_CARRY_MAXIMUM,
                                                    escort      = ?CONST_COMMERCE_ESCORT_MAXIMUM,
                                                    rob         = ?CONST_COMMERCE_ROB_MAXIMUM,
                                                    freerefresh = ?CONST_COMMERCE_FREEREFRESH_MAXIMUM,
                                                    quality     = ?CONST_COMMERCE_GREEN_CARAVAN},
                    ets:insert(?CONST_ETS_COMMERCE, NewCommerce)
            end,
            case ets:next(?CONST_ETS_COMMERCE, Key) of
                '$end_of_table' ->
                    ok;
                Key2 ->
                    refresh_commerce_times_2(Key2)
            end;
        ?null ->
            ok
    end.

broadcast(Caravan) when is_record(Caravan, caravan)	->
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_ONLINE),
	Fun		= fun(OnLine)	->
					  UserId	= OnLine#commerce_online.user_id,
					  Lv		= OnLine#commerce_online.lv,
					  caravan_info(UserId, Lv, Caravan)
			  end,
	lists:foreach(Fun, EtsList);
broadcast(_Market	= #commerce_market{user_id		= UserId,
									   user_name	= UserName,
									   end_time		= EndTime})	->
	MarketPacket	= commerce_api:pack_sc_market_info(UserId, UserName, EndTime),
	broadcast(MarketPacket);
broadcast(Packet)	->
	EtsList	= ets_api:list(?CONST_ETS_COMMERCE_ONLINE),
	Fun		= fun(OnLine)	->	
					  UserId		= OnLine#commerce_online.user_id,
					  misc_packet:send(UserId, Packet)	
			  end,
	lists:foreach(Fun, EtsList).

broadcast_world(_Caravan = #caravan{quality		= ?CONST_COMMERCE_RED_CARAVAN,
									user_id		= UserId,
									user_name	= UserName,
								    friend_id	= FriendId,
								    id          = CaravanId})	->
	Power	= partner_api:caculate_camp_power(UserId),
	Packet	= message_api:msg_notice(?TIP_COMMERCE_CARRY_BROADCAST, [{UserId, UserName}], [], 
									 [{?TIP_SYS_COMMERCE1, misc:to_list(?CONST_COMMERCE_RED_CARAVAN)},
									  {?TIP_SYS_COMMERCE, misc:to_list(CaravanId)}, 
									  {?TIP_SYS_COMMERCE, misc:to_list(UserId)},
									  {?TIP_SYS_COMMERCE, misc:to_list(FriendId)}, {?TIP_SYS_COMMERCE, misc:to_list(Power)}]),
	misc_app:broadcast_world(Packet);
broadcast_world(_Market	= #commerce_market{user_name	= UserName})	->
	TipsPacket		= message_api:msg_notice(?TIP_COMMERCE_MARKET_BROADCAST, [{?TIP_SYS_COMM, UserName}], [], []),
	misc_app:broadcast_world(TipsPacket);
broadcast_world(_)	->	?true.

%% ---------------------------------------------------------------------------------------------------------------------------
%%　获取抢劫记录信息
get_rob_info() ->
	case ets_api:lookup(?CONST_ETS_COMMERCE_ROB_INFO, ?CONST_SYS_TRUE) of
		?null -> #commerce_rob_info{id = ?CONST_SYS_TRUE, rob_list = []};
		Value -> Value
	end.

get_rob_list([RobInfo|RestList], Acc, List) ->
	List2		= case Acc < 4 of
					  ?true -> [RobInfo|List];
					  ?false -> List
				  end,
	get_rob_list(RestList, Acc + 1, List2);
get_rob_list(_, _, List) ->
	List.
%% ----------------------------------------------------------------------------------------------------------------------------
%% 派遣剩余次数
get_carry_times(Player) ->
	UserId			= Player#player.user_id,
	case commerce_lookup(UserId) of
		Commerce when is_record(Commerce, commerce) ->
			Commerce#commerce.carry;
		_ -> ?CONST_SYS_FALSE
	end.
		
%% 抢劫剩余次数
get_rob_times(Player) ->
	UserId			= Player#player.user_id,
	case commerce_lookup(UserId) of
		Commerce when is_record(Commerce, commerce) ->
			Commerce#commerce.rob + Commerce#commerce.vip_rob;
		_ -> ?CONST_SYS_FALSE
	end.
%%------------------------------------------------------------------------------------------------------------------------------
%% 计算运镖收入
cal_carry_income(Buff, Factor, Lv) ->
	case get_base_data(Lv) of
		Data when is_record(Data, rec_commerce) ->
			CarryGold		= Data#rec_commerce.carry_gold,
			?MSG_DEBUG("Lv=~p Buff=~p, CarryGold=~p, Factor=~p", [Lv, Buff, CarryGold, Factor]),
			misc:ceil(Buff * CarryGold * Factor / ?CONST_SYS_NUMBER_HUNDRED);
		_ -> ?CONST_SYS_FALSE
	end.
%%------------------------------------------------------------------------------------------------------------------------------
%% 计算护送收入
cal_escort_income(Buff, Factor, Lv) ->
	case get_base_data(Lv) of
		Data when is_record(Data, rec_commerce) ->
			EscortGold		= Data#rec_commerce.escort_gold,
			misc:ceil(Buff * EscortGold * Factor / ?CONST_SYS_NUMBER_HUNDRED);
		_ -> ?CONST_SYS_FALSE
	end.
%%------------------------------------------------------------------------------------------------------------------------------
%% 计算抢镖收入
cal_rob_income(Buff, Factor, Lv, OtherLv) when Lv =< OtherLv->        %% 劫镖者等级小于或等于运镖者等级
	case get_base_data(Lv) of
		Data when is_record(Data, rec_commerce) ->
			RobGold		= Data#rec_commerce.rob_gold,
			RobExp		= Data#rec_commerce.rob_experience,
			FactorMax	= misc:max(0.3, 1),
			RobGold1	= misc:ceil(Buff * RobGold * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			RobExp1		= misc:ceil(Buff * RobExp * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			{RobGold1, RobExp1};
		_ -> {?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
	end;
cal_rob_income(Buff, Factor, Lv, OtherLv) when (Lv > OtherLv andalso Lv - OtherLv < ?CONST_COMMERCE_LV_DIFF) ->
	case get_base_data(Lv) of                                         %% 劫镖者等级大于运镖者等级（不超过14级）
		Data when is_record(Data, rec_commerce) ->
			RobGold		= Data#rec_commerce.rob_gold,
			RobExp		= Data#rec_commerce.rob_experience,
			LvDiff		= Lv - OtherLv,
			FactorMax	= misc:max(0.3, 1 - LvDiff * 0.05),
			RobGold1	= misc:ceil(Buff * RobGold * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			RobExp1		= misc:ceil(Buff * RobExp * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			{RobGold1, RobExp1};
		_ -> {?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
	end;
cal_rob_income(Buff, Factor, Lv, _OtherLv) ->                       %%　劫镖者等级大于运镖者等级（超过14级）
	case get_base_data(Lv) of
		Data when is_record(Data, rec_commerce) ->
			RobGold		= Data#rec_commerce.rob_gold,
			RobExp		= Data#rec_commerce.rob_experience,
			LvDiff		= ?CONST_COMMERCE_LV_DIFF,
			FactorMax	= misc:max(0.3, 1 - LvDiff * 0.05),
			RobGold1	= misc:ceil(Buff * RobGold * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			RobExp1		= misc:ceil(Buff * RobExp * Factor * FactorMax / ?CONST_SYS_NUMBER_HUNDRED),
			{RobGold1, RobExp1};
		_ -> {?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
	end.
%% ---------------------------------------------------------------------------------------------------------------------------------------
%% 活动期间运送获得历练
%% cal_carry_experience(?CONST_SYS_TRUE, _, _, _) -> ?CONST_SYS_FALSE;
%% cal_carry_experience(_, Market, Factor, Lv) ->
%% 	case get_base_data(Lv) of
%% 		Data when is_record(Data, rec_commerce) ->
%% 			CarryExper	= Data#rec_commerce.carry_experience,
%% 			misc:ceil(Market * Factor * CarryExper / ?CONST_SYS_NUMBER_HUNDRED);
%% 		_ -> ?CONST_SYS_FALSE
%% 	end.
%% 
%% %% 活动期间护送获得历练
%% cal_escort_experience(?CONST_SYS_TRUE, _, _, _) -> ?CONST_SYS_FALSE;
%% cal_escort_experience(_, Market, Factor, Lv) ->
%% 	case get_base_data(Lv) of
%% 		Data when is_record(Data, rec_commerce) ->
%% 			CarryExper	= Data#rec_commerce.escort_experience,
%% 			misc:ceil(Market * Factor * CarryExper / ?CONST_SYS_NUMBER_HUNDRED);
%% 		_ -> ?CONST_SYS_FALSE
%% 	end.
%% 
%% %% 活动期间抢劫获得历练
%% cal_rob_experience(?CONST_SYS_TRUE, _, _, _) -> ?CONST_SYS_FALSE;
%% cal_rob_experience(_, Market, Factor, Lv) ->
%% 	case get_base_data(Lv) of
%% 		Data when is_record(Data, rec_commerce) ->
%% 			CarryExper	= Data#rec_commerce.rob_experience,
%% 			misc:ceil(Market * Factor * CarryExper / ?CONST_SYS_NUMBER_HUNDRED);
%% 		_ -> ?CONST_SYS_FALSE
%% 	end.
%%------------------------------------------------------------------------------------------------------------------------------
%% 获取基础数据
get_base_data(Lv) ->
	data_commerce:get_commerce_base(Lv).
%%------------------------------------------------------------------------------------------------------------------------------
%% GM
add_carry_times(Player, Times) ->
	UserId			= Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_COMMERCE, UserId) of
		Commerce when is_record(Commerce, commerce) ->
			Num				= Commerce#commerce.carry + Times,
			NewCommerce		= Commerce#commerce{carry = Num},
			ets:insert(?CONST_ETS_COMMERCE, NewCommerce),
			{?ok, Player};
		_ -> {?ok, Player}
	end.

add_rob_times(Player, Times) ->
	UserId			= Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_COMMERCE, UserId) of
		Commerce when is_record(Commerce, commerce) ->
			Num				= Commerce#commerce.rob + Times,
			NewCommerce		= Commerce#commerce{rob = Num},
			ets:insert(?CONST_ETS_COMMERCE, NewCommerce),
			{?ok, Player};
		_ -> {?ok, Player}
	end.

add_escort_times(Player, Times) ->
	UserId			= Player#player.user_id,
	case ets_api:lookup(?CONST_ETS_COMMERCE, UserId) of
		Commerce when is_record(Commerce, commerce) ->
			Num				= Commerce#commerce.escort + Times,
			NewCommerce		= Commerce#commerce{escort = Num},
			ets:insert(?CONST_ETS_COMMERCE, NewCommerce),
			{?ok, Player};
		_ -> {?ok, Player}
	end.