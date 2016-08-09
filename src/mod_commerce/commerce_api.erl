%% Author: Administrator
%% Created: 2013-2-20
%% Description: TODO: Add description to commerce_api2
-module(commerce_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").

%%
%% Exported Functions
%%
-export([initial_ets/0, on/1, off/1, logout/1, flush_offline/2,
		 battle_over/2, rob_cb/2, escort_start/3, escort_start_cb/2,
		 escort_over/4, escort_over_cb/2,
		 market_clear/0, caravan_clear/0, commerce_clear/0, friend_clear/0,
		 pack_sc_caravan_info/1, pack_sc_rob_info/7,
		 pack_sc_commerce_info/1,pack_sc_rob_flag/2,
		 pack_sc_market_info/3,pack_sc_rob_notice/7,
		 pack_sc_caravan_vanish/2, get_carry_times/1,
		 pack_sc_market_vanish/1, get_rob_times/1,
		 pack_sc_guild_add/1,
		 pack_sc_completion/3,
		 pack_sc_friend_info/1,
		 pack_sc_invite/1,
		 pack_sc_inform/2,
		 pack_sc_reply/3,
		 pack_sc_quality_info/4,
		 pack_sc_robbed/2,
		 pack_sc_build_market/1,
		 pack_sc_ignore_invite/1]).

%%
%% API Functions
%%
%% 将玩家的Commerce刷新到数据库中
initial_ets()	->
	case commerce_db_mod:read_market() of
		{?ok, ?null}	->	?ok;
		{?ok, MarketList} when is_list(MarketList)		->
			MarketFun	= fun(Market) when is_record(Market, commerce_market)	->
								  ets:insert(?CONST_ETS_COMMERCE_MARKET, Market)
						  end,
			lists:foreach(MarketFun, MarketList)
	end,
	case commerce_db_mod:read_caravan() of
		{?ok, ?null}	->	?ok;
		{?ok, CaravanList} when is_list(CaravanList)	->
			CaravanFun	= fun(Caravan) when is_record(Caravan, caravan)			->
								  ets:insert(?CONST_ETS_CARAVAN, Caravan)
						  end,
			lists:foreach(CaravanFun, CaravanList)
	end,
	commerce_db_mod:read_commerce().
	

logout(Player)	->
	commerce_mod:logout(Player).

%% 离线数据处理
flush_offline(Player, Data)	->
	commerce_mod:flush_offline(Player, Data).

%% 开启军团商路
on(_)	->
	?ok.

off(_)	->
	?ok.

%% 派遣剩余次数
get_carry_times(Player) ->
	commerce_mod:get_carry_times(Player).

%% 抢劫剩余次数
get_rob_times(Player) ->
	commerce_mod:get_rob_times(Player).

%% 拦截战斗结束
battle_over(Result, {UserId, CaravanId}) ->
	?MSG_WARNING("~nUserId=~p~nResult=~p~nCaravanId=~p~n", [UserId, Result, CaravanId]),
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, rob_cb, [Result, CaravanId]);
		_Other	->	%% 离线处理（忽略）
		?MSG_DEBUG("~nUserId=~p~nResult=~p~nCaravanId=~p~n", [UserId, Result, CaravanId]),
			CaravanInfo	= ets:match_object(?CONST_ETS_CARAVAN, #caravan{id = CaravanId, _ ='_'}),
			case erlang:length(CaravanInfo) =:= ?CONST_SYS_FALSE of
				?true  -> ?ok;
				?false ->
					[Caravan|_]	= CaravanInfo,
					NewCaravan	= case Caravan#caravan.battling of
									  ?CONST_COMMERCE_BATTLING	->	Caravan#caravan{battling = ?CONST_COMMERCE_IDLE};
									  ?CONST_COMMERCE_DELAY		->	Caravan
								  end,
					commerce_mod:caravan_update(NewCaravan),
					Packet1		= commerce_api:pack_sc_rob_flag(CaravanId, ?CONST_COMMERCE_IDLE),
					commerce_mod:broadcast(Packet1)
			end
	end.

rob_cb(Player, [Result, CaravanId])	->
	commerce_mod:rob_cb(Player, Result, CaravanId).

%% 开始护送
escort_start(UserId, UserName, EndTime)	->
	?MSG_WARNING("~nUserId=~p~nUserName=~p~nEndTime=~p~n", [UserId, UserName, EndTime]),
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, escort_start_cb, [UserName, EndTime]);
		_Other	->	%% 离线处理
			CommerceOffLine	= #commerce_offline{type		= ?CONST_COMMERCE_ESCORT_START,
												user_name	= UserName,
												escort_time	= EndTime},
			player_offline_api:offline(?MODULE, UserId, CommerceOffLine)
	end.

escort_start_cb(Player, [UserName, EndTime]) ->
	?MSG_WARNING("~nUserId=~p~nUserName=~p~nEndTime=~p~n", [Player#player.user_id, UserName, EndTime]),
	commerce_mod:escort_start_cb(Player, UserName, EndTime).

%% 护送结束
escort_over(UserId, UserName, Gold, Experience)	->
	?MSG_WARNING("~nUserId=~p~nUserName=~p~nGold=~p~n", [UserId, UserName, Gold]),
	case player_api:get_player_pid(UserId) of
		PlayerPid when is_pid(PlayerPid)	->
			player_api:process_send(PlayerPid, ?MODULE, escort_over_cb, [UserName, Gold, Experience]);
		_Other	->
			CommerceOffLine	= #commerce_offline{type		= ?CONST_COMMERCE_ESCORT_OVER,
												user_name	= UserName,
												gold		= Gold},
			player_offline_api:offline(?MODULE, UserId, CommerceOffLine)
	end.

escort_over_cb(Player, [UserName, Gold, Experience]) ->
	?MSG_WARNING("~nUserId=~p~nUserName=~p~nGold=~p~n", [Player#player.user_id, UserName, Gold]),
	commerce_mod:escort_over_cb(Player, UserName, Gold, Experience).

%% 信息定时清除
market_clear()		->
	commerce_mod:market_clear().

caravan_clear()		->
	commerce_mod:caravan_clear().

commerce_clear()	->
	commerce_mod:commerce_clear().

friend_clear()		->
	try
		commerce_mod:refresh_commerce_times(),
		commerce_mod:friend_clear()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

%%
%% Local Functions
%%
%% 商路战报信息(30502)
pack_sc_rob_info(UserId, UserName, UserId1, UserName1, Type, Gold, Experience) ->
	RobInfo			= [UserId, UserName, UserId1, UserName1, Type, Gold, Experience],
	misc_packet:pack(?MSG_ID_COMMERCE_SC_ROB_INFO, ?MSG_FORMAT_COMMERCE_SC_ROB_INFO, RobInfo).
%% 商路交战标志(39504)
pack_sc_rob_flag(CaravanId, RobFlag) ->
	misc_packet:pack(?MSG_ID_COMMERCE_ROB_FLAG, ?MSG_FORMAT_COMMERCE_ROB_FLAG, [CaravanId, RobFlag]).
%% 返回军团增益等级
pack_sc_guild_add(Lv) ->
	misc_packet:pack(?MSG_ID_COMMERCE_SC_GUILD_ADD, ?MSG_FORMAT_COMMERCE_SC_GUILD_ADD, [Lv]).
%% 商路信息(30512)
pack_sc_caravan_info(CaravanInfo)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCCARAVANINFO, ?MSG_FORMAT_COMMERCE_SCCARAVANINFO, CaravanInfo).
%% 商路玩家信息(30516)
pack_sc_commerce_info(Commerce)	->
	Now				= misc:seconds(),
	CarryTime		= case Commerce#commerce.carry_time > Now of
						  ?true		->	Commerce#commerce.carry_time - Now;
						  ?false	->	?CONST_SYS_FALSE
					  end,
	RobTime			= case Commerce#commerce.rob_time > Now of
						  ?true		->	Commerce#commerce.rob_time - Now;
						  ?false	->	?CONST_SYS_FALSE
					  end,
	RobTimes		= Commerce#commerce.rob + Commerce#commerce.vip_rob,
	RobTimes1		= case RobTimes < ?CONST_SYS_FALSE of
						  ?true  -> ?CONST_SYS_FALSE;
						  ?false -> RobTimes
					  end,
	CarryTimes		= case Commerce#commerce.carry < ?CONST_SYS_FALSE of
						  ?true  -> ?CONST_SYS_FALSE;
						  ?false -> Commerce#commerce.carry
					  end,
	
	EscortTime		= case Commerce#commerce.escort < ?CONST_SYS_FALSE of
						  ?true  -> ?CONST_SYS_FALSE;
						  ?false -> Commerce#commerce.escort
					  end,
	CommerceInfo	= [CarryTimes, EscortTime, RobTimes1, CarryTime, RobTime],
	misc_packet:pack(?MSG_ID_COMMERCE_SCPLAYERINFO, ?MSG_FORMAT_COMMERCE_SCPLAYERINFO, CommerceInfo).
%% 商路市场信息(30594)
pack_sc_market_info(UserId, UserName, TimeStamp)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCMARKETINFO, ?MSG_FORMAT_COMMERCE_SCMARKETINFO,[UserId, UserName, TimeStamp]).
%% 加速跑商(30518)
pack_sc_caravan_vanish(CaravanId, SpeedUp)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCCARAVANVANISH,?MSG_FORMAT_COMMERCE_SCCARAVANVANISH, [CaravanId, SpeedUp]).
%% 拦截返回(30522)
pack_sc_rob_notice(UserId, UserName, UserId1, UserName1, Result, Gold, Experience) ->
	Data		= [UserId, UserName, UserId1, UserName1, Result, Gold, Experience],
	misc_packet:pack(?MSG_ID_COMMERCE_SCROB, ?MSG_FORMAT_COMMERCE_SCROB, Data).
%% 市场消失通知(30596)
pack_sc_market_vanish(UserId)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCMARKETVANISH,?MSG_FORMAT_COMMERCE_SCMARKETVANISH, [UserId]).
%% 完成运送(30566)
pack_sc_completion(CaravanId, Gold, Experience)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCCARRYCOMPLETION,?MSG_FORMAT_COMMERCE_SCCARRYCOMPLETION, [CaravanId, Gold, Experience]).
%% 好友处理(30542)
pack_sc_friend_info(FriendInfo)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCFRIENDINFO,?MSG_FORMAT_COMMERCE_SCFRIENDINFO, FriendInfo).
%% 发送邀请(30532)
pack_sc_invite(Result)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCINVITEBACK,?MSG_FORMAT_COMMERCE_SCINVITEBACK, [Result]).
%% 通知好友(30538)
pack_sc_inform(FriendId, FriendName)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCINFORMFRIEND,?MSG_FORMAT_COMMERCE_SCINFORMFRIEND, [FriendId, FriendName]).
%% 好友邀请回复(30536)
pack_sc_reply(FriendId, FriendName, Reply)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCINVITATIONREPLY,?MSG_FORMAT_COMMERCE_SCINVITATIONREPLY,	[FriendId, FriendName, Reply]).
%%商队品质(30552)
pack_sc_quality_info(Quality, Gold, FreeRefresh, Experience)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCQUALITY,?MSG_FORMAT_COMMERCE_SCQUALITY,	[Quality, Gold, FreeRefresh, Experience]).
%% 拦截(30514)
pack_sc_robbed(CaravanId, RobbedTimes)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCCARAVANROBBED,?MSG_FORMAT_COMMERCE_SCCARAVANROBBED, [CaravanId, RobbedTimes]).
%% 建造市场返回(30592)
pack_sc_build_market(UserId)	->
	misc_packet:pack(?MSG_ID_COMMERCE_SCBUILDMARKET,?MSG_FORMAT_COMMERCE_SCBUILDMARKET, [UserId]).
%% 标记邀请返回
pack_sc_ignore_invite(Type) ->
	misc_packet:pack(?MSG_ID_COMMERCE_SC_IGNORE_INVITE, ?MSG_FORMAT_COMMERCE_SC_IGNORE_INVITE, [Type]).
