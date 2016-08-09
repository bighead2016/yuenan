%% Author: zero
%% Created: 2012-10-19
%% Description: 异民族API
-module(invasion_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([init/0, init/1, login/1,refresh_zero/1, 
		 update_invasion/1, flush_offline/2, on/1, off/1, close/1, 
		 check_team_play/3, check_play_again/2, check_play_over/0, 
		 switch/1,refresh/2, refresh_cb/2, beat_heart/0, progress/0, 
		 start_battle/2, mon_battle_start/3,battle_over/9,
		 check_reborn/1, reborn/1,logout/1, ready/0, 
		 invasion_doll/2, reward_doll_cb/2, get_auto/1,
		 invasion_robot/0, robot_exec/1]).

-export([msg_sc_copy_info/1,
		 pack_sc_start_guard/0,
		 pack_sc_start_attack/1,
		 pack_sc_end/1,
		 pack_sc_defendend/2,
		 pack_sc_mon_hp/4,
		 pack_sc_reborn/1,
		 pack_sc_start_monster/3,
		 pack_sc_attack/1,
		 pack_sc_monster_info/6,
		 pack_sc_hurt_rank/1,
		 pack_sc_evaluation/7,
		 pack_sc_turn_cark/2,
		 pack_sc_battle/1,
		 msg_mon_collison/2,
		 msg_mon_start_battle/1,
		 msg_notice_goods/3]).
%%
%% API Functions
%%
%% 初始化玩家异民族数据
init() ->
%% 	Data	= data_invasion:init_copy_list(1),
	#invasion{
%% 			  date	= misc:date_num(),
			  data	= []}.

init(Invasion) ->
	Invasion#invasion{
					  date = misc:date_num(),
					  times = ?CONST_INVASION_DAILY_TIMES
					 }.

refresh_zero(Player) ->
	Player2 = login(Player),
	{?ok, Player2}.

login(Player) ->
	try
		Invasion	= Player#player.invasion,
		Date		= Invasion#invasion.date,
		Today		= misc:date_num(),
		if	Today =/= Date ->
				NewInvasion 	= Invasion#invasion{date = Today, times = ?CONST_INVASION_DAILY_TIMES},
				NewPlayer 		= Player#player{invasion = NewInvasion},
				Packet			= msg_sc_copy_info(NewInvasion#invasion.times),
				misc_packet:send(NewPlayer#player.user_id, Packet),
				NewPlayer;
			?true ->
				Player
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.
update_invasion(Player) ->
	Invasion	= Player#player.invasion,
    RankId = Player#player.sys_rank,
    SysId = data_guide:get_sys_id_by_rank_id(RankId),
	case data_invasion:get_copy_list(SysId) of
		?null -> Player;
		InvasionData ->
			InvasionList	=
				case lists:keyfind(InvasionData#invasion_data.copy, #invasion_data.copy, Invasion#invasion.data) of
					?false -> [InvasionData|Invasion#invasion.data];
					_Other -> Invasion#invasion.data
				end,
			NewInvasion = Invasion#invasion{data = InvasionList},
			Player#player{invasion = NewInvasion}
	end.
			
%% 离线数据处理
flush_offline(Player, Data) when is_record(Data, invasion_offline) ->
	case Data#invasion_offline.type of
		?CONST_INVASION_REWARD	->
			{?ok, Player};
		?CONST_INVASION_TIMES	->
			Copy	= Data#invasion_offline.copy,
			refresh_cb(Player, [Copy])
	end;
flush_offline(Player, {Gold, Meritorious, Experience, DropId, RandTimes}) ->
	reward_doll_cb(Player, {Gold, Meritorious, Experience, DropId, RandTimes});
flush_offline(Player, Data) ->
	?MSG_ERROR("invasion flush_offline:~p", [Data]),
	{?ok, Player}.

%% 异民族活动开始：通知前端
on(_)	->
	init_doll(),
	?MSG_WARNING("~nInvasion Activity Begin!~n", []),
	?ok.

%% 异民族活动结束：通知前端
off(_)	->
	invasion_mod:off(),
	reward_doll(),
	?MSG_WARNING("~nInvasion Activity End!~n", []),
	?ok.

%% X分钟准备广播
ready() -> 
	{_Hour, Min, _Seconds} = misc:time(),
	RemainMinutes = misc:ceil(30 - Min),
	Packet = message_api:msg_notice(?TIP_INVASION_TEN_MINS_BROADCAST, [{100, misc:to_list(RemainMinutes)}]),
	misc_app:broadcast_world_2(Packet).

close(TeamId)	->
	Now	= misc:seconds(),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Info | _] when is_record(Info, invasion_info)	->
			ets:update_element(?CONST_ETS_INVASION, TeamId, [{#invasion_info.end_time, Now},
															 {#invasion_info.activity, ?true}]);
		_Other	->	?true
	end.

%% 检查是否可以异民族组队
check_team_play(Player, Copy, Type)	->
	invasion_mod:check_team_play(Player, Copy, Type).

%% 检查是否可以再次进入当前副本
check_play_again(Player, Copy)	->
	invasion_mod:check_play_again(Player, Copy).

%% 检查多人副本活动是否结束(多人组队模块调用)
check_play_over() ->
	?false.
%% 	case is_opened() of
%% 		?true	->	?false;
%% 		?false	->	?true
%% 	end.

refresh(UserId, Copy) when is_integer(UserId) andalso is_integer(Copy)	->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid)	->
			player_api:process_send(Pid, ?MODULE, refresh_cb, [Copy]);
		_Other	->
            case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                [] ->
        			InvasionOffLine	= #invasion_offline{type	= ?CONST_INVASION_TIMES,
        												copy	= Copy},
        			player_offline_api:offline(?MODULE, UserId, InvasionOffLine);
                [#cross_in{node = Node}] ->
                    rpc:cast(Node, player_api, process_send, [UserId, ?MODULE, refresh_cb, [Copy]])
            end
	end.

refresh_cb(Player, [Copy]) when is_record(Player, player) andalso is_integer(Copy) ->
	invasion_mod:refresh_cb(Player, Copy).

%% 怪物心跳(crontab触发)
beat_heart()	->
	invasion_mod:beat_heart().

%% 异民族机器人
invasion_robot() ->
	invasion_mod:invasion_robot().

robot_exec(TeamId) ->
	invasion_mod:robot_exec(TeamId).

%% 守关
guard(InvasionInfo)		->
	invasion_mod:guard(InvasionInfo).

%% 攻关
attack(InvasionInfo)	->
	invasion_mod:attack(InvasionInfo).

start_battle(Player, UniqueId)		->
    invasion_mod:start_battle(Player, UniqueId).

mon_battle_start(TeamId, UniqueId, UserId)	->
	invasion_mod:mon_battle_start(TeamId, UniqueId, UserId).

battle_over(Result, UserId, BattleType, UniqueId, MapPid, TeamId, RightUnits, HurtLeft, HurtRight)	->
	map_api:invasion_battle_over(Result, UserId, BattleType, UniqueId, MapPid, TeamId, RightUnits, HurtLeft, HurtRight).

%% 复活时间到点?
check_reborn(Player) when is_record(Player, player) ->
    invasion_mod:check_reborn(Player);
check_reborn(_)	->	?false.

%% 复活时间到点?
reborn(Player) when is_record(Player, player)	->
    invasion_mod:reborn(Player);
reborn(_)	->	?ok.

logout(Player)	->
	invasion_mod:logout(Player),
	{?ok, Player}.
%% 	invasion_mod:evaluation(Player).

%% 进入异民族地图，相关初始化及广播
switch(MapId) when is_integer(MapId)	->
	UserIdList	= get_user_list(),
	TeamId		= team_api:get_team_id(UserIdList),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Tuple | _] when is_record(Tuple, invasion_info) andalso Tuple#invasion_info.map_id =/= MapId	->
			TeamType	= Tuple#invasion_info.team_type,
			MapPid		= self(),
			Prior		= Tuple#invasion_info.prior,
			BeginTime	= Tuple#invasion_info.begin_time,
			EndTime		= Tuple#invasion_info.end_time,
			HurtLeft	= Tuple#invasion_info.hurt_left,
			HurtRight	= Tuple#invasion_info.hurt_right,
			Start		= Tuple#invasion_info.start,
			?MSG_DEBUG("~nPrior=~p~nBeginTime=~p~nEndTime=~p~nHurtLeft=~p~nHurtRight=~p~n",
						 [Prior, BeginTime, EndTime, HurtLeft, HurtRight]),
			NewTuple	= invasion_mod:init(TeamId, TeamType, MapPid, MapId, Prior, BeginTime, EndTime, HurtLeft, HurtRight, Start),
			ets:insert(?CONST_ETS_INVASION, NewTuple);
		_Other	->
%% 			?MSG_ERROR("invasion switch ets_invasion UserIdList=:~p,TeamId=:~p,MapId=:~p", [UserIdList, TeamId, MapId]),
			?false
	end;
switch(MapId)	->
	?MSG_ERROR("invasion switch map=:~p", [MapId]),
	?false.

%% 怪物心跳对应的处理函数
progress()	->
	UserIdList	= get_user_list(),
	TeamId		= team_api:get_team_id(UserIdList),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Info | _] when is_record(Info, invasion_info)	->
			case Info#invasion_info.mode of
				?CONST_INVASION_GUARD	->	guard(Info);
				?CONST_INVASION_ATTACK	->	attack(Info)
			end;
		_Other	->
			ets:match_delete(?CONST_ETS_INVASION, #invasion_info{map_pid = self(), _ = '_'})
	end.

%% 判断异民族是否开始
%% is_opened() ->
%% %% 	Invasion1	= active_api:is_opened(?CONST_ACTIVE_INVASION),
%% 	Invasion2	= active_api:is_opened(?CONST_ACTIVE_INVASION2),
%% 	Invasion2 =:= ?CONST_SYS_TRUE.


%% 初始化替身参加
init_doll() ->
	Cash		= ?CONST_INVASION_DOLL_COST,
	DollList	= ets_api:list(?CONST_ETS_INVASION_DOLL),
	[init_doll(Cash, UserId) || {UserId, _Lv} <- DollList].
init_doll(Cash, UserId) ->
	try
		case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_INVASION_DOLL_CASH) of
			?ok -> ?ok;
			{?error, _ErrorCode} ->
				ets_api:delete(?CONST_ETS_INVASION_DOLL, UserId),
				Packet		= message_api:msg_notice(?TIP_INVASION_DOLL_FAIL), 
				misc_packet:send(UserId, Packet),
				?ok
		end
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 自动参战(替身参加)
invasion_doll(Player, ?true) ->
	UserId		= Player#player.user_id,
	Lv			= (Player#player.info)#info.lv,
	case check_invasion_doll(Player) of
		?ok ->
			ets_api:insert(?CONST_ETS_INVASION_DOLL, {UserId, Lv}),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
invasion_doll(Player, ?false) ->
	UserId		= Player#player.user_id,
	case check_invasion_doll(Player) of
		?ok ->
			ets_api:delete(?CONST_ETS_INVASION_DOLL, UserId),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

check_invasion_doll(Player) ->
	Vip				= (Player#player.info)#info.vip,
	try
		?ok  		= check_vip_flag(Vip#vip.lv),
		case player_sys_api:is_open_sys(Player, ?CONST_MODULE_YIMINZU) of
			?true	->
				?ok = check_doll_invasion_state();
			?false	->	
				{?error, ?TIP_INVASION_NOT_OPEN}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 替身参加奖励
reward_doll() ->
	DollList	= ets_api:list(?CONST_ETS_INVASION_DOLL),
	[reward_doll(UserId, Lv) || {UserId, Lv} <- DollList],
	ets:delete_all_objects(?CONST_ETS_INVASION_DOLL).

reward_doll(UserId, Lv) ->
	try
		RecDollReward	= data_invasion:get_invasion_doll_reward(Lv),
		Gold			= RecDollReward#rec_invasion_doll.gold,
		Meritorious		= RecDollReward#rec_invasion_doll.meritorious,
		Experience		= RecDollReward#rec_invasion_doll.experience,
		DropId			= RecDollReward#rec_invasion_doll.drop_id,
		RandTimes		= RecDollReward#rec_invasion_doll.rand_times,
		Reward			= {Gold, Meritorious, Experience, DropId, RandTimes},
		case player_api:check_online(UserId) of
			?true -> player_api:process_send(UserId, ?MODULE, reward_doll_cb, Reward);
			?false -> player_offline_api:offline(?MODULE, UserId, Reward)
		end
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?error, ?TIP_COMMON_SYS_ERROR}
	end. 
reward_doll_cb(Player, {Gold, Meritorious, Experience, DropId, RandTimes}) ->
	UserId			= Player#player.user_id,
	GoodsList		= reward_doll_goods(DropId, RandTimes, []),
	{?ok, Player2}  =
        case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_INVASION_REWARD, 1, 1, 1, 0, 1, 1, []) of
			{?ok, Player_2, _, _PacketBag}	->
				{?ok, Player_2};
			{?error, _ErrorCode}	->
				{?ok, Player}
		end,
	Fun				= fun(Item) ->
							  {Item#goods.goods_id, Item#goods.count}
					  end,
	RealList		= lists:map(Fun, GoodsList),
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_INVASION_DOLL_GOLD),
	Player3			= player_api:plus_experience(Player2, Experience),
	{?ok, Player4}	= player_api:plus_meritorious(Player3, Meritorious, ?CONST_COST_INVASION_DOLL_MERITORIOUS),
	{?ok, Player5}  = schedule_api:add_guide_times(Player4, ?CONST_SCHEDULE_GUIDE_INVASION),
	Packet			= pack_sc_doll_reward(Gold, Experience, Meritorious, RealList),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player5}.

reward_doll_goods(_GropId, 0, Acc) -> Acc;
reward_doll_goods(GropId, RandTimes, Acc) ->
	GoodsList		= goods_api:goods_drop(GropId),
	NewAcc			= Acc ++ GoodsList,
	reward_doll_goods(GropId, RandTimes - 1, NewAcc).

%% 检查活动是否开启
check_doll_invasion_state() ->
%% 	Flag1		= active_api:is_opened(?CONST_ACTIVE_INVASION),
	Flag2		= active_api:is_opened(?CONST_ACTIVE_INVASION2),
	case Flag2 =:= ?CONST_SYS_TRUE of
		?true ->
			throw({?error, ?TIP_INVASION_DOLL_BAN});% 异民族已经开启，无法更改自动参战状态！
		?false -> 
			?ok
	end.

%% 检查vip等级
check_vip_flag(VipLv) ->
	case player_vip_api:get_invasion_auto_flag(VipLv) of
		?CONST_SYS_TRUE -> ?ok;
		_ ->
			throw({?error,?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}) %% VIP等级不足
	end.

%% 获取异民族自动参加信息
get_auto(UserId) ->
	case ets_api:lookup(?CONST_ETS_INVASION_DOLL, UserId) of
		?null -> [];
		_ -> [?CONST_SCHEDULE_ACTIVITY_EARLY_INVASION]
	end.

%% 获取地图中玩家列表
get_user_list() ->
	List  = get(user_id_list),
	[Y || {X, Y} <- List, X =:= ?CONST_MAP_PTYPE_HUMAN orelse is_atom(X)].

%% 提示获得橙色以上物品
msg_notice_goods(Player, Id, GoodsList) ->
	UserId	  = Player#player.user_id,
	UserName  = (Player#player.info)#info.user_name,
	Goods 	  = [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	case Goods of
		[] -> <<>>;
		_  ->
			List	  = [{?TIP_SYS_INVASION, misc:to_list(Id)}],
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_INVASION_NOTICE_GOODS_EQUIP, [{UserId, UserName}],
																[GoodsInfo], List),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_INVASION_NOTICE_GOODS, [{UserId, UserName}],[GoodsInfo],
																  List),
								<<Packet/binary, Acc/binary>>
						end
				end,
			lists:foldl(F, <<>>, Goods)
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 协议相关
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msg_sc_copy_info(Times) ->
	misc_packet:pack(?MSG_ID_INVASION_SCHALLINFO, ?MSG_FORMAT_INVASION_SCHALLINFO, [Times]).

pack_sc_start_guard()	->
	misc_packet:pack(?MSG_ID_INVASION_SC_START_GUARD, ?MSG_FORMAT_INVASION_SC_START_GUARD, [1]).

pack_sc_start_attack(CopyId)	->
	misc_packet:pack(?MSG_ID_INVASION_SCATTACK, ?MSG_FORMAT_INVASION_SCATTACK, [CopyId]).

pack_sc_end(Mode) ->
	misc_packet:pack(?MSG_ID_INVASION_SC_END, ?MSG_FORMAT_INVASION_SC_END, [Mode]).

pack_sc_defendend(Result, Completion) ->
	misc_packet:pack(?MSG_ID_INVASION_SCDEFENDEND, ?MSG_FORMAT_INVASION_SCDEFENDEND, [Result, Completion]).

pack_sc_mon_hp(UniqueId, CurHp, MaxHp, Monster) ->
	misc_packet:pack(?MSG_ID_INVASION_SCMONHP, ?MSG_FORMAT_INVASION_SCMONHP, [UniqueId, CurHp, MaxHp, Monster]).

pack_sc_reborn(Time) ->
	misc_packet:pack(?MSG_ID_INVASION_SC_REBORN, ?MSG_FORMAT_INVASION_SC_REBORN, [Time]).

pack_sc_start_monster(Mode, EndTime, Wave) ->
	misc_packet:pack(?MSG_ID_INVASION_SC_START_MONSTER, ?MSG_FORMAT_INVASION_SC_START_MONSTER, [Mode, EndTime, Wave]).

pack_sc_attack(Result) ->
	misc_packet:pack(?MSG_ID_INVASION_SCATTACKOVER, ?MSG_FORMAT_INVASION_SCATTACKOVER, [Result]).

pack_sc_monster_info(Flag, Mode, MonsterId, UniqueId, X, Y)	->
	misc_packet:pack(?MSG_ID_INVASION_SCMONSTERINFO, ?MSG_FORMAT_INVASION_SCMONSTERINFO, [Flag, Mode, MonsterId, UniqueId, X, Y]).

pack_sc_hurt_rank(HurtRankList)	->
	case length(HurtRankList) > 3 of
		?true ->
			?MSG_ERROR("pack_sc_hurt_rank length error:~p", [HurtRankList]);
		?false ->
			misc_packet:pack(?MSG_ID_INVASION_HURT_RANK, ?MSG_FORMAT_INVASION_HURT_RANK, [HurtRankList])
	end.

pack_sc_evaluation(Evaluation, HurtLeft, HurtRight, Duration, Exp, Gold, GoodsList)	->
	Goods	= pack_sc_evaluation_goods(GoodsList, []),
	misc_packet:pack(?MSG_ID_INVASION_SCEVALUATION, ?MSG_FORMAT_INVASION_SCEVALUATION,
					 [Evaluation, HurtLeft, HurtRight, Duration, Exp, Gold, Goods]).
pack_sc_evaluation_goods([Goods | GoodsList], Acc) when is_record(Goods, goods) ->
	pack_sc_evaluation_goods(GoodsList, [{Goods#goods.goods_id, Goods#goods.count} | Acc]);
pack_sc_evaluation_goods([_Goods | GoodsList], Acc) ->
	pack_sc_evaluation_goods(GoodsList, Acc);
pack_sc_evaluation_goods([], Acc) when is_list(Acc) ->	Acc.

pack_sc_turn_cark(VIP, GoodsList)	->
	Goods	= pack_sc_turn_cark_goods(GoodsList, []),
	misc_packet:pack(?MSG_ID_INVASION_SCTURNCARD, ?MSG_FORMAT_INVASION_SCTURNCARD, [VIP, Goods]).

pack_sc_turn_cark_goods([Goods | GoodsList], Acc) when is_record(Goods, goods) ->
	pack_sc_turn_cark_goods(GoodsList, [{Goods#goods.goods_id, Goods#goods.count} | Acc]);
pack_sc_turn_cark_goods([_Goods | GoodsList], Acc) ->
	pack_sc_turn_cark_goods(GoodsList, Acc);
pack_sc_turn_cark_goods([], Acc) when is_list(Acc) ->	Acc.

pack_sc_battle(Result)	->
	misc_packet:pack(?MSG_ID_INVASION_SCBATTLE, ?MSG_FORMAT_INVASION_SCBATTLE, [Result]).

%% 替身奖励
pack_sc_doll_reward(Gold, Experience, Meritorious, GoodsList) ->
	misc_packet:pack(?MSG_ID_INVASION_DOLL_REWARD, ?MSG_FORMAT_INVASION_DOLL_REWARD, [Gold, Experience, Meritorious, GoodsList]).

%% 怪物碰撞城门
%%[MonId]
msg_mon_collison(Id, MonId) ->
	misc_packet:pack(?MSG_ID_INVASION_MON_COLLISON, ?MSG_FORMAT_INVASION_MON_COLLISON, [Id, MonId]).

%% 怪物发起战斗
%%[{MonId}]
msg_mon_start_battle(List1) ->
	misc_packet:pack(?MSG_ID_INVASION_MON_START_BATTLE, ?MSG_FORMAT_INVASION_MON_START_BATTLE, [List1]).


%%
%% Local Functions
%%

