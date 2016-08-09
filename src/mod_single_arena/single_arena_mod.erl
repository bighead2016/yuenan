%% Author: Administrator
%% Created: 2012-9-13
%% Description: 个人竞技场模块
-module(single_arena_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
%%协议相关
-export([clean_cd/1, buy_challenge_times/1, win_streak_award/2, change_ui_state/7,
		 battle_over/4, deal_with_rank/4, start_battle/2, get_rank_reward/1, get_front_n_member/2,
		 get_report_by_id/1, send_auto_rank/1, auto_rank/1, top_rank/1, top_streak/1]).
%%各种获取信息
-export([
		 get_myself_info/1, get_streak_win_reward_info/1,get_user_arena_rank/1,
		 get_arena_report/1, get_rank_reward_data/2,
		 get_report_binary/1, get_member_binary/1, get_arena_info_by_id/1,
		 get_deffender_list/1, get_next_reward_time/1, select_some_users/1,
		 challenge_list_to_front/1, get_arena_count/0, get_member_by_rank/1,
		 get_front_member/1, get_rank_id/1, get_rank_show_id/1, get_need_ceil/1, 
		 get_challenge_reward/2
		]).
-export([
		 update_arena_cd/1, check_cool_down/1, champion_report_to_front/1, get_player_trend/1,
		 treat_non_reward_list/2, remain_times/2, get_user_equip_mode/1, get_rank_reward_db/1,
		 get_reward_goods/1, insert_member_ets/1]).

%%
%% API Functions
%%
%%获取个人的竞技场信息  涉及到隔日更新
get_myself_info(UserId) ->
	Member = get_arena_info_by_id(UserId), %% 获取某个玩家的竞技场信息
	get_myself_info2(Member). 

get_myself_info2([]) ->
	[?CONST_SINGLE_ARENA_ERROR, #ets_arena_member{}];
get_myself_info2(Member) ->
	Now = misc:seconds(),
	case misc:is_same_date(Member#ets_arena_member.clean_times_time, Now) of % 是否同一天
		?true->
			[?CONST_SINGLE_ARENA_OK, Member];
		%%旧日期数据，更新
		?false->
			Member2 = Member#ets_arena_member{times 				= 0,
											  daily_max_win 		= 0, 
%% 											  max_win		 		= 0, 
											  winning_streak 		= 0,
											  streak_wining_reward 	= [],
											  daily_buy_time 		= 0,
											  clean_times_time 		= Now},
			update_member_ets(Member2),
			%%冷却时间返回给前端的是相对
			Value2 = misc:uint(Member2#ets_arena_member.cd - Now),
			[?CONST_SINGLE_ARENA_OK, Member2#ets_arena_member{cd = Value2}]
	end.

%%清除CD
clean_cd(Player = #player{info = Info}) ->
	CanClean 	= player_vip_api:can_single_arena_clear_cd(player_api:get_vip_lv(Info)), 	%% 竞技场挑战冷却时间清除
	Member 		= get_arena_info_by_id(Player#player.user_id),				%% 获取某个玩家的竞技场信息
	clean_cd2(Member, CanClean, Player).

clean_cd2(_, 0, Player) ->
	Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_VIP_NOT_ENOUGH),
	misc_packet:send(Player#player.net_pid, Packet),
	{?CONST_SINGLE_ARENA_ERROR, Player};
clean_cd2([], _CanClean, Player)  ->
	{?CONST_SINGLE_ARENA_ERROR, Player};
clean_cd2(Member, _CanClean, Player = #player{user_id = UserId}) ->
	Now = misc:seconds(),
	Cd = Member#ets_arena_member.cd,
	case Cd =< Now of
		?true ->
			{?CONST_SINGLE_ARENA_ERROR, Player};
		?false ->
			Cash = misc:ceil( (Cd-Now)/60 ),	%% 计算清除费用
			case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash * ?CONST_SINGLE_ARENA_CASH_PER_MIN, ?CONST_COST_SINGLE_ARENA_CLEAR_CD) of
				?ok ->
					NewMember = Member#ets_arena_member{cd = misc:seconds()},
					update_member_ets(NewMember),
					{?CONST_SINGLE_ARENA_OK, Player};
				_ ->
					{?CONST_SINGLE_ARENA_CASH_ERROR, Player}
			end
	end.
	
%%购买挑战次数
buy_challenge_times(Player = #player{user_id = UserId}) ->
	Vip = player_api:get_vip_lv(Player),
	case buy_challenge_times_check(UserId, Vip) of %% 购买挑战次数检查
		{?ok, Cost, Member} ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_SINGLE_ARENA_BUY_TIMES) of %% 扣取元宝
				?ok ->
					NewBuyTimes = handle_challenge_times(Member),
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_BUY_TIMES_OK),
					misc_packet:send(UserId, Packet),
					{?CONST_SINGLE_ARENA_OK, NewBuyTimes};
				_ ->
					{?CONST_SINGLE_ARENA_ERROR, 0}
			end;
		{?error, Reason} ->
			case Reason of
				?TIP_SINGLE_ARENA_TIMES_NOT_USE ->
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_TIMES_NOT_USE),
					misc_packet:send(UserId, Packet);
				?TIP_COMMON_VIPLEVEL_NOT_ENOUGH ->
					Packet = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
					misc_packet:send(UserId, Packet);
				?TIP_SINGLE_ARENA_BUY_TIMES_OVER ->
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_BUY_TIMES_OVER),
					misc_packet:send(UserId, Packet);
				_Other ->
					skip
			end,
			{?CONST_SINGLE_ARENA_ERROR, 0}
	end.

%% 购买挑战次数检查
buy_challenge_times_check(UserId, Vip) ->
	MaxTime = player_vip_api:get_single_arena_buyable_times(Vip),
	case get_arena_info_by_id(UserId) of
		[] ->
			{?error, 0};
		Member ->
			#ets_arena_member{times = TodayTimes, daily_buy_time = TodayBuyTimes} = Member,
			Cost = TodayBuyTimes * 2 + 2,
			if
				TodayTimes < ?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES + TodayBuyTimes ->		%仍有免费挑战次数，不需要购买
					{?error, ?TIP_SINGLE_ARENA_TIMES_NOT_USE};
				MaxTime =:= 0 ->															%目前VIP等级不可购买
					{?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH};
				TodayBuyTimes > MaxTime ->													%当日购买次数用尽
					{?error, ?TIP_SINGLE_ARENA_BUY_TIMES_OVER};
				?true ->
					{?ok, Cost, Member}
			end
	end.

%% 处理购买次数
handle_challenge_times(Member) ->
	NewBuyTimes = Member#ets_arena_member.daily_buy_time + 1,
	NewMember = Member#ets_arena_member{daily_buy_time = NewBuyTimes},
	update_member_ets(NewMember),
	NewBuyTimes.

%% 领取连胜奖励
win_streak_award(Player = #player{user_id = UserId, info = Info}, WinStreak) ->
	RecMember 	= get_arena_info_by_id(UserId),	%% 获取某个玩家的竞技场信息
	RewardList 	= RecMember#ets_arena_member.streak_wining_reward,
	case check_win_streak_award(Player, WinStreak) of	%% 检查领取连胜奖励
		?true ->
			Lv = Info#info.lv,
			[Meritorious, Experience, GoodsId, Bind, GoodsNum] = get_streak_win_reward_real(Lv, WinStreak), %% 获取特定次数的连胜奖励
			case give_win_streak_goods(Player, [{GoodsId, Bind, GoodsNum}]) of %% 发放连胜奖励道具
				{?ok, Player2} ->
					RewardList2 	= [WinStreak|RewardList],
					RecMember2 		= RecMember#ets_arena_member{streak_wining_reward = RewardList2},
					update_member_ets(RecMember2),
					{?ok, Player3}	= player_api:plus_meritorious(Player2, Meritorious, ?CONST_COST_SINGLE_ARENA_WIN),
					Player4 		= player_api:plus_experience(Player3, Experience),
                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_SINGLE_ARENA_WIN, GoodsId, GoodsNum, misc:seconds()),
					{?CONST_SINGLE_ARENA_OK, RewardList2, Player4};
				{?error, _} ->
					{?CONST_SINGLE_ARENA_ERROR, RewardList, Player}
			end;
		?false ->				%%已经领取过该连胜奖励
			{?CONST_SINGLE_ARENA_ERROR, RewardList, Player}
	end.

%% 检查领取连胜奖励
check_win_streak_award(#player{user_id = UserId, net_pid = NetPid}, WinStreak) ->
	RecMember = get_arena_info_by_id(UserId),
	RewardList = RecMember#ets_arena_member.streak_wining_reward,
	if
		RecMember#ets_arena_member.daily_max_win >= WinStreak ->
			case lists:member(WinStreak, RewardList) of
				?true ->
					?false;
				?false ->
					?true
			end;
		?true ->
			Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_STREAK_NOT_ENOUGH),
			misc_packet:send(NetPid, Packet),
			?false
	end.

%% 发放连胜奖励道具
give_win_streak_goods(Player = #player{net_pid = NetPid, bag = Bag}, GoodsList) ->
	NeedCeil = get_need_ceil(GoodsList),
	{?ok, EmptyCeil} = ctn_bag2_api:empty_count(Bag),
	case EmptyCeil < NeedCeil of
		?true ->					%%背包空间不足
			if
				NeedCeil > 0 ->
					TipPacket = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
					misc_packet:send(NetPid, TipPacket),
					{?error, Player};
				?true ->			%%此次连胜，没有道具奖励
					{?ok, Player}
			end;
		?false ->					
			Fun = fun({GoodsId, Bind, GoodsNum}, {PlayerT, TempPacket}) ->
						  case add_goods2bag(PlayerT, GoodsId, Bind, GoodsNum) of
							  {?ok, PlayerT2, Packet} ->
								  {PlayerT2, <<TempPacket/binary, Packet/binary>>};
							  {?error, _} ->
								  {PlayerT, TempPacket}
						  end
				  end,
			{NewPlayer, NewPacket} = lists:foldl(Fun, {Player, <<>>}, GoodsList),
			misc_packet:send(NetPid, NewPacket),
			{?ok, NewPlayer}
	end.

%% 处理没有奖励的连胜次数
treat_non_reward_list(List1, List2) ->
	treat_non_reward_list(List1, List2, []).
treat_non_reward_list([], _List, Acc) ->
	lists:reverse(Acc);
treat_non_reward_list([Streak|T], List, Acc) ->
	case lists:member(Streak, List) of
		?true ->
			treat_non_reward_list(T, List, Acc);
		?false ->
			treat_non_reward_list(T, List, [Streak|Acc])
	end.
		
%% 获取可以挑战的玩家列表
get_deffender_list(PlayerId)->
	case get_arena_info_by_id(PlayerId) of
		[]->
			[?CONST_SINGLE_ARENA_ERROR, []];
		Member->
			Rank = Member#ets_arena_member.rank,
			ResultList = 
				case Rank =< ?CONST_SINGLE_ARENA_CHALLENGE_NUM of
					?true->						%% 前五名同学，特殊处理
						List  = get_front_member(?CONST_SINGLE_ARENA_CHALLENGE_NUM + 1),
						[ MemberTemp || MemberTemp <- List,MemberTemp#ets_arena_member.rank =/= Rank ];
					?false->					%% 选取几位可以挑战的同学      等待策划的规则	TODO  
						select_some_users(Rank)
				end,
			[?CONST_SINGLE_ARENA_OK, ResultList]
	end.

%% 挑选几个挑战的玩家
%% select_some_users(MyRank) ->
%% 	Pattern		= ets:fun2ms(fun(X) when MyRank > X#ets_arena_member.rank  andalso (MyRank - X#ets_arena_member.rank) =< ?CONST_SINGLE_ARENA_CHALLENGE_NUM -> X end),
%% 	MemberList	= ets:select(?CONST_ETS_ARENA_MEMBER, Pattern),
%% 	Fun = fun(Member1, Member2) ->
%% 				  Member1#ets_arena_member.rank < Member2#ets_arena_member.rank
%% 		  end,
%% 	lists:sort(Fun, MemberList).

select_some_users(Rank) ->
	RankList = select_some_users(Rank, 0, []),
	MemberList = lists:map(fun(X) -> get_member_by_rank(X) end, RankList),
	Fun = fun(Member1, Member2) ->
				  Member1#ets_arena_member.rank < Member2#ets_arena_member.rank
		  end,
	lists:sort(Fun, MemberList).	

select_some_users(_Rank, ?CONST_SINGLE_ARENA_CHALLENGE_NUM, Acc) ->
	Acc;
select_some_users(Rank, Num, Acc) ->
	RankId		= get_rank_show_id(Rank),
	RecInterval	= data_single_arena:get_base_single_arena_rank_show(RankId),
	Interval    = RecInterval#rec_arena_rank_show.interval_num,
	case select_up_user(Rank, Interval) of
		?null ->
			Acc;
		Rank2 when Acc =/= [] ->
			case lists:any(fun(X) -> X =:= Rank2 end, Acc) of
				?true ->	%已经选过的，跳过
					select_some_users(Rank - Interval, Num, Acc);
				?false ->
					select_some_users(Rank - Interval, Num + 1, [Rank2|Acc])
			end;
		Rank2 ->
			select_some_users(Rank - Interval, Num + 1, [Rank2|Acc])
	end.

select_up_user(Rank, Interval) when Rank - Interval > 0 ->
	case get_member_by_rank(Rank - Interval) of
		Member when is_record(Member, ets_arena_member) ->
			Member#ets_arena_member.rank;
		_Other ->
			select_up_user(Rank - Interval, Interval)
	end;
select_up_user(_Rank, _Interval) ->
	?null.


%%获取排名前N的玩家(其实可以将前N名玩家缓存起来,这样就不用每次请求都找N个,但是要每次更新和同步数据)
get_front_member(N)->
	get_front_member_help(N+1,[],1).

get_front_member_help(N,Result,N)->
	Result;
get_front_member_help(N,Result,NowCount)->
	case get_member_by_rank(NowCount) of
		[]->
			get_front_member_help(N,Result,NowCount + 1);
		Member->
			NewResult = Result ++ [Member],
			get_front_member_help(N,NewResult,NowCount + 1)
	end.

%%获取排名为N的玩家
get_member_by_rank(Rank)->
	MS = ets:fun2ms(fun(T) when T#ets_arena_member.rank =:= Rank -> T end),
	case ets:select(?CONST_ETS_ARENA_MEMBER, MS) of
		[]->
			[];
		[Value | _]->
			Value
	end.

get_front_n_member(Pos, N) ->
    get_front_n_member(Pos - 1, N, []).
get_front_n_member(_Pos, 0, Result) ->
    Result;
get_front_n_member(0, _N, Result) ->
    Result;
get_front_n_member(Pos, N, Result) ->
    case get_member_by_rank(Pos) of
        [] ->
            Result;
        Member ->
            get_front_n_member(Pos - 1, N - 1, Result ++ [Member])
    end.

%%战斗开始前   当日挑战次数+1    CD时间更改
before_start_battle(Player) ->
	UserId		= Player#player.user_id,
	Member 		= get_arena_info_by_id(UserId),
	VipLv		= player_api:get_vip_lv(Player),
	Cd			= 
		case player_vip_api:is_no_arena_cd(VipLv) of
			?CONST_SYS_TRUE ->
				misc:seconds();
			_ ->
				misc:seconds() + ?CONST_SINGLE_ARENA_CD
		end,
	NewMember 	= Member#ets_arena_member{cd = Cd, times = Member#ets_arena_member.times + 1},
	RemainTimes	= remain_times(NewMember#ets_arena_member.daily_buy_time, NewMember#ets_arena_member.times),
	Packet		= schedule_api:packet_sc_play_times(?CONST_SCHEDULE_PLAY_SINGLE_ARENA, RemainTimes),
	misc_packet:send(UserId, Packet),
	update_member_ets(NewMember).

%%检查挑战的条件        检查是否可挑战（TODO）
check_start_battle(UserId, EnemyId) ->
	try
%% 		?ok = check_node(),					%% 防止多个服务端程序进行竞技场挑战
		?ok = check_open_arena(UserId),		%% 开放系统
		?ok = check_cool_down(UserId),		%% 冷却
		?ok = check_remain_times(UserId),	%% 检查剩余次数
		?ok = check_battle_user(UserId, EnemyId),	%% 检查挑战双方
		?ok
	catch
		throw:Return ->
			Return;
		_:_ ->
			{?error, 110}
	end.

%% 检查开放系统
check_open_arena(UserId) ->
	case get_arena_info_by_id(UserId) of %% 获取某个玩家的竞技场信息
		[] ->
			throw({?error, ?TIP_SINGLE_ARENA_NOT_OPEN});
		_ ->
			?ok
	end.
%% 检查冷却
check_cool_down(UserId) ->
	RecMember =  get_arena_info_by_id(UserId),
	Now		  =  misc:seconds(),
	if
		Now < RecMember#ets_arena_member.cd ->
			throw({?error, ?TIP_SINGLE_ARENA_CD});
		?true ->
			?ok
	end.
%% 检查剩余次数
check_remain_times(UserId) ->
	RecMember =  get_arena_info_by_id(UserId),
	if
		RecMember#ets_arena_member.times >= (?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES + RecMember#ets_arena_member.daily_buy_time) ->
			throw({?error, ?TIP_SINGLE_ARENA_NO_TIMES});
		?true ->
			?ok
	end.
%% 检查挑战双方
check_battle_user(UserId, EnemyId) ->
	RecMember 	=  get_arena_info_by_id(UserId),
	RecMember2 	=  get_arena_info_by_id(EnemyId),
	if
		RecMember2#ets_arena_member.rank - RecMember#ets_arena_member.rank > 5 ->			%%挑战列表已经更新
			throw({?error, ?TIP_SINGLE_ARENA_LIST_CHANGE});
		?true ->
			?ok
	end.

%%发起挑战 各种检查 是否开启竞技场 是否在冷却时间 挑战次数是否有剩余
start_battle(Player = #player{user_id = UserId, net_pid = NetPid}, EnemyId) ->
	case check_start_battle(UserId, EnemyId) of	%%检查挑战的条件        检查是否可挑战（TODO）
		?ok ->
%% 			case player_state_api:try_set_state_play(Player3, ?CONST_PLAYER_PLAY_SINGLE_ARENA) of %% 检查玩法
%% 				{?true, Player4} ->
					case battle_api:start(Player, EnemyId, #param{battle_type = ?CONST_BATTLE_SINGLE_ARENA}) of %% 开始战斗
						{?error, _ErrorCode} -> %% 错误
%% 							Packet = message_api:msg_notice(ErrorCode),
%% 							misc_packet:send(UserId, Packet),
							{?ok, Player};
						{?ok, Player2} -> %% 结果返回
							before_start_battle(Player), 	%%战斗开始前   当日挑战次数+1    CD时间更改
							{?ok, Player3}	= schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_SINGLE_ARENA),   %% 目标
							{?ok, Player3}
					end;	
%% 				{?false, _Player} -> %% 错误
%% 					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_PLAY_FAIL),
%% 					misc_packet:send(NetPid, Packet),
%% 					{?ok, Player3}
%% 			end;
		{?error, Return} ->		%%战斗发起失败
			case Return of
				?TIP_SINGLE_ARENA_NOT_OPEN ->
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_NOT_OPEN),
					misc_packet:send(NetPid, Packet);
				?TIP_SINGLE_ARENA_CD ->
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_CD),
					misc_packet:send(NetPid, Packet);
				?TIP_SINGLE_ARENA_NO_TIMES ->
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_NO_TIMES),
					misc_packet:send(NetPid, Packet);
				?TIP_SINGLE_ARENA_LIST_CHANGE ->
					challenge_list_to_front(UserId),
					Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_LIST_CHANGE),
					misc_packet:send(NetPid, Packet);
				_Other ->
					Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
					misc_packet:send(NetPid, Packet)
			end
	end.

%%  战斗模块通知竞技场结束
battle_over(UserId, Result, EnemyId, BinReport) ->
	single_arena_serv:deal_with_rank_cast(UserId, EnemyId, Result, BinReport).

%% 处理排名
deal_with_rank(UserId, EnemyId, Result, BinReport) ->
	MemberUser = get_arena_info_by_id(UserId),
	MemberEnemy = get_arena_info_by_id(EnemyId),
	
	AtkReport = #ets_arena_report{player_id = UserId, deffender_id = EnemyId, result = Result, 
								  	time = misc:seconds(), type = ?CONST_SINGLE_ARENA_ATTACK, bin_report = BinReport},
	Result2	  = reverse_result(Result),
	DefReport = #ets_arena_report{player_id = EnemyId, deffender_id = UserId, result = Result2, 
								  	time = misc:seconds(), type = ?CONST_SINGLE_ARENA_DEF, bin_report = BinReport},
	{AtkReport2, DefReport2} = 
		deal_with_rank2(MemberUser, MemberEnemy, AtkReport, DefReport, Result),
	
	%% 挑战方成就刷新
	single_arena_api:arena_achievement(UserId),
	%% 被挑战方成就刷新
	single_arena_api:arena_achievement(EnemyId),
%% 	update_arena_cd(UserId),
	challenge_list_to_front(UserId),
	challenge_list_to_front(EnemyId),			%%索性一起更新
	top_three_to_front(UserId, AtkReport2#ets_arena_report.rank, DefReport2#ets_arena_report.rank),
	battle_info_to_front(UserId, EnemyId, ?CONST_SINGLE_ARENA_ATTACK, Result, BinReport),
	battle_report_to_front(UserId, MemberEnemy#ets_arena_member.rank, AtkReport2),
    
    % XXX        
    update_daily_rank_process(UserId),
    update_daily_rank_process(EnemyId),
	?ok.

%%更新战报
battle_report_to_front(UserId, DefOldRank, AtkReport) ->
	UserName = player_api:get_name(UserId),
	Tuple = get_report_binary(AtkReport),
	{ReportId, _, _, DefId, DefName, _, Rank, _} = Tuple,
	Packet = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_PER_REPORT, 
							  	?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_PER_REPORT, tuple_to_list(Tuple)),
	misc_packet:send(UserId, Packet),
	if 
		Rank =:= 1 andalso DefOldRank =:= 1 ->	%将榜首挑落马下
			ChampionPacket =
				single_arena_api:msg_sc_champion_report(ReportId, 
														UserId, 
														UserName, 
														DefId, 
														DefName,
														(misc:seconds() - AtkReport#ets_arena_report.time)),
			misc_app:broadcast_world_2(ChampionPacket),
			update_champion_report(ReportId, UserId, UserName, DefId, DefName, 
								   AtkReport#ets_arena_report.time, AtkReport#ets_arena_report.bin_report);
		?true ->
			?ok
	end.

%%更新三雄
top_three_to_front(UserId, AtkRank, DefRank) when AtkRank =< 3 orelse DefRank =< 3 ->
	RankList	= single_arena_api:get_single_arena_top_rank_ets(?CONST_SINGLE_ARENA_TOP_RANK),
	RankData 	= single_arena_api:pack_rank_list(RankList),
	Packet 		= misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_RANK, ?MSG_FORMAT_SINGLE_ARENA_SC_RANK, {RankData}),
	misc_packet:send(UserId, Packet),
	?ok;
top_three_to_front(_UserId, _AtkRank, _DefRand) ->
	?ok.

%% 相反的战斗结果
reverse_result(?CONST_BATTLE_RESULT_LEFT) ->
	?CONST_SINGLE_ARENA_LOSE;
reverse_result(?CONST_BATTLE_RESULT_RIGHT) ->
	?CONST_SINGLE_ARENA_WIN;
reverse_result(_) ->
	?CONST_SINGLE_ARENA_LOSE.

%% 挑战胜利
deal_with_rank2(MemberUser, MemberEnemy, AtkReport, DefReport, ?CONST_SINGLE_ARENA_WIN)
  when is_record(MemberUser, ets_arena_member) andalso is_record(MemberEnemy, ets_arena_member) ->
	OldUserRank = MemberUser#ets_arena_member.rank,
	OldEnemyRank = MemberEnemy#ets_arena_member.rank,
	NewUserTimes = MemberUser#ets_arena_member.times,
	NewWinningStreak = MemberUser#ets_arena_member.winning_streak + 1,
	%% 挑战胜利系统公告
	single_arena_win_brocast(NewWinningStreak, OldUserRank, OldEnemyRank, 
							 MemberUser#ets_arena_member.player_id,
							 MemberUser#ets_arena_member.player_name, 
							 MemberEnemy#ets_arena_member.player_id,
							 MemberEnemy#ets_arena_member.player_name),
	home_api:add_source_list(MemberUser#ets_arena_member.player_id, MemberEnemy#ets_arena_member.player_id),
	if
		OldUserRank < OldEnemyRank ->			%%挑战低排名玩家(更新挑战方连胜次数  当日挑战次数)
			
			NewMemberUser = MemberUser#ets_arena_member{winning_streak = NewWinningStreak, times = NewUserTimes},
			NewMemberUser2 = update_daily_max_win(NewMemberUser, NewWinningStreak),
			
			
			bless_api:send_be_blessed(MemberUser#ets_arena_member.player_id, ?CONST_RELATIONSHIP_BTYPE_ARENA, NewWinningStreak),
			update_member_ets(NewMemberUser2),
			
			AtkReport2 = AtkReport#ets_arena_report{rank = OldUserRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKSTAY},
			AtkUniqueId = single_arena_api:insert_report(AtkReport2),
			DefReport2 = DefReport#ets_arena_report{rank = OldEnemyRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKSTAY},
			DefUniqueId = single_arena_api:insert_report(DefReport2),
            admin_log_api:log_single_arena(MemberUser#ets_arena_member.player_id,
                                           OldUserRank, OldUserRank, 
                                           NewWinningStreak, 
                                           MemberEnemy#ets_arena_member.player_id,
                                           ?CONST_SYS_TRUE,
                                           NewUserTimes),
            admin_log_api:log_single_arena(MemberEnemy#ets_arena_member.player_id,
                                           OldEnemyRank, OldEnemyRank, 
                                           MemberEnemy#ets_arena_member.winning_streak, 
                                           MemberUser#ets_arena_member.player_id,
                                           ?CONST_SYS_FALSE,
                                           MemberEnemy#ets_arena_member.times),
			%% 挑战方成就刷新
%% 			single_arena_api:arena_achievement(NewMemberUser2#ets_arena_member.player_id),
			%% 被挑战方成就刷新
%% 			single_arena_api:arena_achievement(MemberEnemy#ets_arena_member.player_id),
			{AtkReport2#ets_arena_report{id = AtkUniqueId}, DefReport2#ets_arena_report{id = DefUniqueId}};
		?true ->								%%挑战高排名玩家(交换名次 更新挑战方连胜次数  当日挑战次数)
			NewMemberUser = MemberUser#ets_arena_member{rank = OldEnemyRank, winning_streak = NewWinningStreak, times = NewUserTimes},
			NewMemberEnemy = MemberEnemy#ets_arena_member{rank = OldUserRank},
			NewMemberUser2 = update_daily_max_win(NewMemberUser, NewWinningStreak),
			
            admin_log_api:log_single_arena(MemberUser#ets_arena_member.player_id,
                                           OldUserRank, OldEnemyRank, 
                                           NewWinningStreak, 
                                           MemberEnemy#ets_arena_member.player_id,
                                           ?CONST_SYS_TRUE,
                                           NewUserTimes),
            admin_log_api:log_single_arena(MemberEnemy#ets_arena_member.player_id,
                                           OldEnemyRank, OldUserRank, 
                                           MemberEnemy#ets_arena_member.winning_streak, 
                                           MemberUser#ets_arena_member.player_id,
                                           ?CONST_SYS_FALSE,
                                           MemberEnemy#ets_arena_member.times),
			bless_api:send_be_blessed(MemberUser#ets_arena_member.player_id, ?CONST_RELATIONSHIP_BTYPE_ARENA, NewWinningStreak),
			update_member_ets(NewMemberUser2),
			
			AtkReport2 = AtkReport#ets_arena_report{rank = OldEnemyRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKUP},
			AtkUniqueId = single_arena_api:insert_report(AtkReport2),
			DefReport2 = DefReport#ets_arena_report{rank = OldUserRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKDOWN},
			DefUniqueId = single_arena_api:insert_report(DefReport2),
			update_member_ets(NewMemberEnemy),			%%被挑战方，不影响连胜次数
			%% 挑战方成就刷新
%% 			single_arena_api:arena_achievement(NewMemberUser2#ets_arena_member.player_id),
			%% 被挑战方成就刷新
%% 			single_arena_api:arena_achievement(NewMemberEnemy#ets_arena_member.player_id),
			{AtkReport2#ets_arena_report{id = AtkUniqueId}, DefReport2#ets_arena_report{id = DefUniqueId}}
	end;
%% 挑战失败
deal_with_rank2(MemberUser, MemberEnemy, AtkReport, DefReport, ?CONST_SINGLE_ARENA_LOSE)
  when is_record(MemberUser, ets_arena_member) andalso is_record(MemberEnemy, ets_arena_member) ->
	OldUserRank = MemberUser#ets_arena_member.rank,
	OldEnemyRank = MemberEnemy#ets_arena_member.rank,
	OldUserTimes = MemberUser#ets_arena_member.times,
	NewMemberUser = MemberUser#ets_arena_member{winning_streak = 0, times = OldUserTimes},
	
	AtkReport2 = AtkReport#ets_arena_report{rank = OldUserRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKSTAY},
	AtkUniqueId = single_arena_api:insert_report(AtkReport2),
	DefReport2 = DefReport#ets_arena_report{rank = OldEnemyRank, rank_change_type = ?CONST_SINGLE_ARENA_RANKSTAY},
	DefUniqueId = single_arena_api:insert_report(DefReport2),
	update_member_ets(NewMemberUser),
    admin_log_api:log_single_arena(MemberUser#ets_arena_member.player_id,
                                           OldUserRank, OldUserRank, 
                                           0, 
                                           MemberEnemy#ets_arena_member.player_id,
                                           ?CONST_SYS_TRUE,
                                           OldUserTimes),
            admin_log_api:log_single_arena(MemberEnemy#ets_arena_member.player_id,
                                           OldEnemyRank, OldEnemyRank, 
                                           MemberEnemy#ets_arena_member.winning_streak, 
                                           MemberUser#ets_arena_member.player_id,
                                           ?CONST_SYS_FALSE,
                                           MemberEnemy#ets_arena_member.times),
	{AtkReport2#ets_arena_report{id = AtkUniqueId}, DefReport2#ets_arena_report{id = DefUniqueId}};
deal_with_rank2(_MemberUser, _MemberEnemy, AtkReport, DefReport, _Result) ->
	{AtkReport, DefReport}.

%% 刷新每日进度
update_daily_rank_process(UserId) ->
    MemberUser = get_arena_info_by_id(UserId),
    if
        MemberUser#ets_arena_member.daily_target =:= 0 ->
            Target = single_arena_api:calc_target(MemberUser#ets_arena_member.rank),
            if
                Target =/= 0 ->
                    ets_api:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.target_state, ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE},
                                                                             {#ets_arena_member.daily_target, Target}]),
                    Packet = single_arena_api:msg_sc_target(MemberUser#ets_arena_member.daily_target, ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE),
                    misc_packet:send(UserId, Packet);
                ?true ->
                    ?ok
            end;
        MemberUser#ets_arena_member.rank =< MemberUser#ets_arena_member.daily_target 
          andalso MemberUser#ets_arena_member.target_state =:= ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE ->
            ets_api:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.target_state, ?CONST_SINGLE_ARENA_STATE_CAN_GET}]),
            Packet = single_arena_api:msg_sc_target(MemberUser#ets_arena_member.daily_target, ?CONST_SINGLE_ARENA_STATE_CAN_GET),
            misc_packet:send(UserId, Packet);
        ?true ->
            ?ok
    end.

%% 挑战胜利系统公告
%% 胜利广播
single_arena_win_brocast(WinningStreak, OldRank, NewRank, UserId, UserName, EnemyId, EnemyName) ->
	SteakPacket =
		if
			WinningStreak =:= 10 -> 
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_10,  [{?TIP_SYS_COMM,UserName}]);
			WinningStreak =:= 15 -> 
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_15, [{?TIP_SYS_COMM,UserName}]);
			WinningStreak =:= 20 ->
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_20,  [{?TIP_SYS_COMM,UserName}]);
			WinningStreak =:= 25 ->
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_25,  [{?TIP_SYS_COMM,UserName}]);
			WinningStreak =:= 30 ->
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_30,  [{?TIP_SYS_COMM,UserName}]);
			WinningStreak > 30 ->
				message_api:msg_notice(?TIP_SINGLE_ARENA_WIN_STREAK_OVER_30,  [{?TIP_SYS_COMM,UserName}, {?TIP_SYS_COMM, misc:to_list(WinningStreak)}]);
			?true -> <<>>
		end,
	WinPacket	=
		if	NewRank =< 10 andalso OldRank > NewRank -> %% 十名以内并且名次上升的才广播
				message_api:msg_notice(?TIP_SINGLE_ARENA_BATTLE_WIN,  [{UserId, UserName}, 
																	   {EnemyId, EnemyName}],
									   								  [],
																	  [{?TIP_SYS_COMM, misc:to_list(NewRank)}]);
			?true ->
				<<>>
		end,
	misc_app:broadcast_world(<<SteakPacket/binary, WinPacket/binary>>).
		

%% 自动晋级
auto_rank(UserId) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_arena_member) ->
			do_auto_rank(Member);
		_Other ->
			?ok
	end.

do_auto_rank(Member) when Member#ets_arena_member.rank > 1 ->
	case get_member_by_rank(Member#ets_arena_member.rank - 1) of
		UpMember when is_record(UpMember, ets_arena_member) ->
			OldRank = Member#ets_arena_member.rank,
			NewRank = UpMember#ets_arena_member.rank,
			case (UpMember#ets_arena_member.player_lv >= ?CONST_SINGLE_ARENA_AUTO_RANK_LV) of
				?true ->
					?ok;
				?false ->
					update_member_ets(Member#ets_arena_member{rank = NewRank}),
					update_member_ets(UpMember#ets_arena_member{rank = OldRank}),
					do_auto_rank(Member#ets_arena_member{rank = NewRank})
			end;
		_Other ->
			?ok
	end;
do_auto_rank(_Member) ->
	?ok.
	

%% 更新每日最大连胜次数 历史最大连胜
update_daily_max_win(Member, WinStreak) ->
	DailyMaxWin = Member#ets_arena_member.daily_max_win,
	Member2 = 
		if
			WinStreak > DailyMaxWin ->
				Member#ets_arena_member{daily_max_win = WinStreak};
			?true ->
				Member
		end,
	MaxWin = Member2#ets_arena_member.max_win,
	if
		WinStreak > MaxWin ->
			Member2#ets_arena_member{max_win = WinStreak};
		?true ->
			Member2
	end.

%%推送挑战列表更新给前端          被挑战者也会收到该更新协议 （排名下降的时候）
challenge_list_to_front(UserId) ->
	[_, DefList] = get_deffender_list(UserId),
	
	Fun = fun(Member) ->
				  #ets_arena_member{player_id 	= PlayerId,
									player_lv 	= PlayerLv,
									rank	  	= Rank,
									player_name	= Name,
									player_career = Career,
									player_sex	= Sex} = Member,
				  [EquipFashion, EquipArmor, EquipWeapon, GuildName, HorseId, Power] = get_user_equip_mode(PlayerId),
				  ?MSG_DEBUG("UserId ~p, EquipArmor ~p, EquipWeapon ~p, GuildName ~p", [UserId, EquipArmor, EquipWeapon, GuildName]),
				  [_Point, Meritorious, _Experience] = get_challenge_reward(PlayerLv, ?CONST_SINGLE_ARENA_WIN),
				  [Meritorious2, GoodsNum, _Bind, GoodsId, _Score] = get_rank_reward_data(Rank, PlayerLv),
				  {
				   PlayerId,
				   PlayerLv,
				   Rank,
				   misc:to_list(Name),
				   Career,
				   Sex,
				   Meritorious,
				   Meritorious2,
				   GoodsNum, 
				   GoodsId,
				   EquipArmor,
				   EquipWeapon,
				   misc:to_list(GuildName),
				   HorseId,
				   Power, 
				   EquipFashion
				   }
		  end,
	Datas = lists:map(Fun, DefList),
	
	Packet = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, {Datas}),
	misc_packet:send(UserId, Packet).

%% 更新战斗信息
battle_info_to_front(UserId, EnemyId, Type, Result, _BinReport) ->
	RecMember 	= get_arena_info_by_id(UserId),
	RecMember2 	= get_arena_info_by_id(EnemyId),
	#ets_arena_member{rank = Rank, winning_streak = WinStreak, 
					  	daily_max_win = DailyMaxWin, max_win = MaxWin, times = Times} = RecMember,
	Cd 			= misc:uint(RecMember#ets_arena_member.cd - misc:seconds()),
	RemainTimes	= remain_times(RecMember#ets_arena_member.daily_buy_time, Times),
	{_IsReward, RewardTime}	= get_next_reward_time(UserId),							  %TODO 领取排名奖励时间
	_EnemyName 	= misc:to_list(RecMember2#ets_arena_member.player_name),  %TODO
	_Trend	  	= battle_trend(Type, Result),							  %TODO
	[Meritorious, GoodsNum, _Bind, GoodsId, _] = get_rank_reward_data(Rank, RecMember#ets_arena_member.player_lv),
%% 	Datas		  = {Type, Cd, EnemyId, EnemyName, Result, WinStreak, MaxWin, 
%% 					 					RemainTimes, Rank, Trend, BinReport, RewardTime, Meritorious, GoodsNum, GoodsId},
	Datas		  = {Cd, WinStreak, DailyMaxWin, MaxWin, RemainTimes, Rank, RewardTime, Meritorious, GoodsNum, GoodsId}, %TODO
	Packet		  = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_REPORT, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_REPORT, Datas),
	misc_packet:send(UserId, Packet).

%% 更新一个玩家的竞技场信息
update_member_ets(Member)->
	ets:insert(?CONST_ETS_ARENA_MEMBER, Member).

%% 插入一个玩家的竞技场信息
insert_member_ets(Member)->
	ets:insert_new(?CONST_ETS_ARENA_MEMBER, Member).

%% 更新CD
update_arena_cd(UserId) ->
	Now = misc:seconds(),
	ets:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.cd, Now + ?CONST_SINGLE_ARENA_CD}]).

%% 获取竞技场人数(插入新的排名使用)
get_arena_count()->
	case ets:info(?CONST_ETS_ARENA_MEMBER, size) of
		0 -> 
			0;
		_Num ->
			RankList = ets:select(?CONST_ETS_ARENA_MEMBER, ets:fun2ms(fun(Member) -> Member#ets_arena_member.rank end)),
			case RankList of
				[] ->
					0;
				_Other ->
					lists:max(RankList)
			end
	end.

%% 获取某个玩家的竞技场信息
get_arena_info_by_id(UserId)->
	case ets:lookup(?CONST_ETS_ARENA_MEMBER, UserId) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% 获取玩家竞技场排名
get_user_arena_rank(UserId) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_arena_member) ->
			Member#ets_arena_member.rank;
		_Other ->
			0
	end.

%% 领取排名奖励，从数据库中数据判断
get_rank_reward(Player) ->
	ArenaReward = get_rank_reward_db(Player#player.user_id),	%% 数据库查找
	
	Time = ArenaReward#ets_arena_reward.get_date - ArenaReward#ets_arena_reward.settlement_date,
	Rank = ArenaReward#ets_arena_reward.rank,
	case (Time > 0) of
		?true ->
			Packet = message_api:msg_notice(?TIP_SINGLE_ARENA_RANK_REWARD_FAIL),
			misc_packet:send(Player#player.user_id, Packet),
			{0, Player};
		?false ->
			mysql_api:update(game_arena_reward, 
							 [{get_date, misc:seconds()}, {goods, ""},{meritorious,0},{score, 0}],
							 [{player_id, Player#player.user_id}]),	%% 更新数据库
			{?ok, Player2} = player_api:plus_meritorious(Player, ArenaReward#ets_arena_reward.meritorious, ?CONST_COST_SINGLE_ARENA_DAILY),
			[GoodsNum, Bind, GoodsId] = get_reward_goods(ArenaReward#ets_arena_reward.goods),
            Score = 
                case data_single_arena:get_score_score(Rank) of
                    ?null -> 0;
                    #rec_single_arena_score{score = ScoreT} -> ScoreT
                end,
            Member = single_arena_api:get_myself_info(Player#player.user_id),
            NewScore = Member#ets_arena_member.score+Score,
            ets:update_element(?CONST_ETS_ARENA_MEMBER, Player#player.user_id, [{#ets_arena_member.score,       NewScore}]),
            P = single_arena_api:msg_sc_score_update(NewScore),
            misc_packet:send(Player#player.user_id, P),
			case add_goods2bag(Player2, GoodsId, Bind, GoodsNum) of % 发放道具礼包到背包
				{?ok, Player3, Packet} ->
					misc_packet:send(Player3#player.user_id, Packet),
					{Rank, Player3};
				{?error, _Bag} -> %% 有可能不是道具是功勋
					{Rank, Player2}
			end
	end.

get_reward_goods(undefined) ->
	[0, 0, 0];
get_reward_goods(<<>>) ->
	[0, 0, 0];
get_reward_goods(Goods) ->
    try
	    binary_to_term(Goods)
    catch
        _:_ ->
            [0, 0, 0]
    end.

%% 数据库查找
get_rank_reward_db(UserId) ->
	case mysql_api:select_execute(<<"SELECT * FROM `game_arena_reward` WHERE `player_id` = '",
								   (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, [List]} ->
%% 			?MSG_DEBUG("List ~p", [List]),
			list_to_tuple([ets_arena_reward|List]);
		_Other ->
			#ets_arena_reward{player_id = UserId}
	end.
		

%% 领取排名奖励 
%% get_rank_reward(Player) ->
%% 	Rank = get_user_arena_rank(Player#player.user_id),
%% 	Lv = (Player#player.info)#info.lv,
%%   	[Meritorious, GoodsNum, Bind, GoodsId] = get_rank_reward_data(Rank, Lv),
%% 	{?ok, Player2} = player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_ARENA_PVP_REWARD_RANK),
%% 	case add_goods2bag(Player#player.user_id, Player#player.bag, GoodsId, Bind, GoodsNum) of
%% 		{?ok, NewBag, _Packet} ->
%% 			{?CONST_SINGLE_ARENA_OK, Player2#player{bag = NewBag}};
%% 		{?error, _Bag} ->
%% 			{?CONST_SINGLE_ARENA_ERROR, Player2}
%% 	end.

%% 获取排名奖励
get_rank_reward_data(0, _Lv) ->
	[0, 0, 0, 0, 1];
get_rank_reward_data(Rank, Lv) ->
	RankId = get_rank_id(Rank),
	RecReward = data_single_arena:get_base_single_arena_reward({Lv, 2}),
	AwardList = RecReward#rec_arena_reward.award_list,
    Score = 
        case data_single_arena:get_score_score(Rank) of
            ?null -> 0;
            #rec_single_arena_score{score = ScoreT} -> ScoreT
        end,
	case lists:keyfind(RankId, 1, AwardList) of
		?false ->
			[0,0,0,0,1];
		{_RankId, _Meritorious, _Experience, GoodsId, Bind, GoodsNum} ->
			Meritorious = get_rank_meritorious(Rank),
			[
             Meritorious,
			 GoodsNum,
			 Bind,
			 GoodsId,
             Score
            ]
	end.

%% 获取排名区间ID
get_rank_id(Rank) ->
	get_rank_id(Rank, 1, 0).
get_rank_id(_Rank, RankId, RankId) ->
	RankId;
get_rank_id(Rank, RankId, Acc) ->
	RecInterval = data_single_arena:get_base_single_arena_rank_interval(RankId),
	if
		RecInterval#rec_arena_rank_interval.begin_num =< Rank andalso RecInterval#rec_arena_rank_interval.end_num >= Rank ->
			get_rank_id(Rank, RankId, RankId);
		?true ->
			get_rank_id(Rank, RankId+1, Acc)
	end.

%% 获取排名显示区间ID
get_rank_show_id(Rank) ->
	get_rank_show_id(Rank, 1, 0).
get_rank_show_id(_Rank, RankId, RankId) ->
	RankId;
get_rank_show_id(Rank, RankId, Acc) ->
	RecInterval = data_single_arena:get_base_single_arena_rank_show(RankId),
	if
		RecInterval#rec_arena_rank_show.begin_num =< Rank andalso RecInterval#rec_arena_rank_show.end_num >= Rank ->
			get_rank_show_id(Rank, RankId, RankId);
		?true ->
			get_rank_show_id(Rank, RankId + 1, Acc)
	end.

%% 获取排名功勋奖励
get_rank_meritorious(Rank) when Rank < 0 ->		%我让你非法
	0;
get_rank_meritorious(Rank) when Rank =< 3 ->
	2800 + (3 - Rank) * 100;
get_rank_meritorious(Rank) when Rank =< 10 ->
	2450 + (10 - Rank) * 50;
get_rank_meritorious(Rank) when Rank =< 50 ->
	1850 + (50 - Rank) * 15;
get_rank_meritorious(Rank) when Rank =< 100 ->
	1450 + (100 - Rank) * 8;
get_rank_meritorious(Rank) when Rank =< 200 ->
	1050 + (200 - Rank) * 4;
get_rank_meritorious(Rank) when Rank =< 500 ->
	750 + (500 - Rank);
get_rank_meritorious(_Rank) ->
	750.

%% 获取连胜列表
get_streak_win_reward_info(PlayerId) ->
	List = get_can_reward_steak_list(),
	get_streak_win_reward_info(PlayerId, List, []).

get_streak_win_reward_info(_PlayerId, [], Acc) -> 
	Acc;
get_streak_win_reward_info(PlayerId, [Streak|T], Acc) ->
	StreakNum = 
		case get_arena_info_by_id(PlayerId) of
			[] ->
				0;
			Member ->
				case lists:member(Streak, Member#ets_arena_member.streak_wining_reward) of
					?true ->							%%已经领取
						0;
					?false ->							%%未领取
						Streak
				end
		end,
	get_streak_win_reward_info(PlayerId, T, [StreakNum|Acc]).

%% 获取可以领取奖励的连胜次数
get_can_reward_steak_list() ->
	RecStreakReward = data_single_arena:get_base_single_arena_reward({1, ?CONST_SINGLE_ARENA_STREAK_AWARD}),		%只是查找可以领取奖励的连胜次数，跟等级无关
	AwardList = RecStreakReward#rec_arena_reward.award_list,
	lists:map(fun({Streak, _, _, _, _, _}) -> Streak end, AwardList).

%% 获取特定次数的连胜奖励
get_streak_win_reward_real(Lv, Streak) ->
	RecStreakReward = data_single_arena:get_base_single_arena_reward({Lv, ?CONST_SINGLE_ARENA_STREAK_AWARD}),
	AwardList = RecStreakReward#rec_arena_reward.award_list,
	case lists:keyfind(Streak, 1, AwardList) of
		?false ->
			[];
		{_Streak, Meritorious, Experience, GoodsId, Bind, GoodsNum} ->
			[Meritorious,
			 Experience,
			 GoodsId,
			 Bind,
			 GoodsNum]
	end.

get_challenge_reward(Lv, Result) ->
	RecReward = data_single_arena:get_base_single_arena_reward({Lv, ?CONST_SINGLE_ARENA_CHALLENGE_AWARD}),
	RewardList = RecReward#rec_arena_reward.award_list,
	case lists:keyfind(Result, 1, RewardList) of
		?false -> [?CONST_COST_SINGLE_ARENA_BATTLE, 0, 0];
		{_Result, Meritorious, Experience, _GoodsId, _Bind, _GoodsNum} ->
			[?CONST_COST_SINGLE_ARENA_BATTLE, Meritorious, Experience]
	end.

%% 获取玩家战报
get_arena_report(PlayerId)->
	case get_arena_info_by_id(PlayerId) of
		[]->
			[0,[]];
		_Member->
			List = get_top_five_report(PlayerId),
			[1,List]
	end.

%% 获取玩家的最近五个战报
get_top_five_report(PlayerId)->
	AtkList = single_arena_api:get_player_attack_report(PlayerId),
	DefList = single_arena_api:get_player_def_report(PlayerId),
	Fun = fun(Elem1,Elem2)->
				  Elem1#ets_arena_report.time > Elem2#ets_arena_report.time
		  end,
	List1 = lists:sort(Fun, AtkList ++ DefList),
	lists:sublist(List1, 5).

%% 获取玩家排名趋势
get_player_trend(PlayerId) ->
	case get_top_five_report(PlayerId) of
		[] ->
			?CONST_SINGLE_ARENA_RANKSTAY;
		[Report|_] ->
			Type		= Report#ets_arena_report.type,
			Result		= Report#ets_arena_report.result,
%% 			?MSG_DEBUG("Type ~p, Result ~p", [Type, Result]),
			battle_trend(Type, Result)
	end.


%% 自动晋级
send_auto_rank(Player) ->
	single_arena_serv:auto_rank_cast(Player#player.user_id).

%% 排名前Num的玩家列表
top_rank(Num) ->
	MS = ets:fun2ms(fun(T) when T#ets_arena_member.rank =< Num -> T end),
	List = ets:select(?CONST_ETS_ARENA_MEMBER, MS),
	Fun = fun(A, B) ->
				  A#ets_arena_member.rank < B#ets_arena_member.rank
		  end,
	PackList = lists:sort(Fun, List),
	
	Fun2 = fun(Member) ->
				   Trend = get_player_trend(Member#ets_arena_member.player_id),
%% 				   UserPower	= partner_api:caculate_camp_power(Member#ets_arena_member.player_id),
				   {Member#ets_arena_member.player_id,
					Member#ets_arena_member.rank,
					Member#ets_arena_member.player_name,
					Member#ets_arena_member.player_sex,
					Member#ets_arena_member.player_lv,
%% 					UserPower,
					Member#ets_arena_member.fight_force,
					Trend}
		   end,
	PackList2 = lists:map(Fun2, PackList),
%% 	?MSG_DEBUG("PackList2   ~p", [PackList2]),
	single_arena_api:msg_sc_top_rank(PackList2).

%% 连胜前Num的玩家列表(目前这个做法，性能消耗非常大)
top_streak(Num) ->
	List = ets:tab2list(?CONST_ETS_ARENA_MEMBER),
	Fun = fun(Member1, Member2) ->
				  Member1#ets_arena_member.max_win > Member2#ets_arena_member.max_win
		  end,
	List2 = lists:sort(Fun, List),
	top_streak2(Num, List2, 1, []).

top_streak2(_Num, [], _Nth, Acc) ->
	single_arena_api:msg_sc_top_streak(lists:reverse(Acc));
top_streak2(Num, _List, Nth, Acc) when Nth >= Num ->
	single_arena_api:msg_sc_top_streak(lists:reverse(Acc));
top_streak2(Num, [Member|T], Nth, Acc) ->
%% 	UserPower = partner_api:caculate_camp_power(Member#ets_arena_member.player_id),
	Tuple = 
		{Member#ets_arena_member.player_id,
		 Member#ets_arena_member.rank,
		 Member#ets_arena_member.player_name,
		 Member#ets_arena_member.player_lv,
		 Member#ets_arena_member.fight_force,
%% 		 UserPower,
		 Member#ets_arena_member.max_win},
	top_streak2(Num, T, Nth+1, [Tuple|Acc]).

%%
%% Local Functions
%%

%%发放道具礼包到背包
add_goods2bag(Player, GoodsId, _Bind, Count) when GoodsId =< 0 orelse Count =< 0 ->
	{?error, Player};
add_goods2bag(Player, GoodsId, Bind, Count) when GoodsId > 0 andalso Count > 0 ->
	GoodsList = goods_api:make(GoodsId, Bind, Count),
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SINGLE_ARENA_DAILY, 1, 1, 1, 0, 0, 1, []) of
		{?ok, Player2, _, Packet} ->
			{?ok, Player2, Packet};
		{?error, _ErrorCode} ->
			{?error, Player}
	end.

%%获取物品所需背包格子
get_need_ceil(GoodsList) ->
	[{GoodsId, _Bind, GoodsNum}] = GoodsList,
	RecGoods = data_goods:get_goods(GoodsId),
	if
		is_record(RecGoods, goods) =:= ?true ->
			Stack = RecGoods#goods.stack,
			case Stack of
				1 ->
					GoodsNum;
				_ ->
					misc:ceil(GoodsNum / Stack)
			end;
		?true ->
			0
	end.

remain_times(BuyTimes, UseTimes) when ?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES + BuyTimes > UseTimes ->
	(?CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES + BuyTimes - UseTimes);
remain_times(_, _) ->
	0.

%% 获取趋势
battle_trend(Type, Result) ->
	case Type of
		1 ->						%%对方排名靠前(挑战)
			if
				Result =:= 1 ->		%%胜利 排名上升
					?CONST_SINGLE_ARENA_RANKUP;
				?true ->			%%失败 排名不变
					?CONST_SINGLE_ARENA_RANKSTAY
			end;
		2 ->						%%对方排名靠后(被挑战)
			if
				Result	=:= 1 -> 	%%胜利 排名不变
					?CONST_SINGLE_ARENA_RANKSTAY;
				?true ->			%%失败 排名下降
					?CONST_SINGLE_ARENA_RANKDOWN
			end
	end.

%% 打开竞技场界面
change_ui_state(PlayerId, NickName, Sex, Career, Lv, Sn, Type) ->
	Member = get_arena_info_by_id(PlayerId),
	change_ui_state(Member, PlayerId, NickName, Sex, Career, Lv, Sn, Type), %% 更新人物信息
	?CONST_SINGLE_ARENA_OK.

%% 首次进入竞技场
change_ui_state([], PlayerId, NickName, Sex, Career, Lv, _Sn, Type) ->
	Member = #ets_arena_member
				 {rank 			= get_arena_count() + 1,
				  player_id 	= PlayerId,
				  player_name 	= NickName,
				  player_sex 	= Sex,
				  player_career = Career,
				  player_lv 	= Lv,
				  times 		= 0,
				  clean_times_time = misc:seconds()},
	insert_member_ets(Member#ets_arena_member{on_line_flag = 1,open_flag = Type});
%% 	single_arena_api:arena_achievement(Member#ets_arena_member.player_id);
%% 非首次
change_ui_state(Member, _PlayerId, _NickName, _Sex, _Career, _Lv, _Sn, Type) ->
	update_member_ets(Member#ets_arena_member{on_line_flag = 1,open_flag = Type}).

%% 根据战报ID 获取二进制战报
get_report_by_id(ReportId) ->
	case ets_api:lookup(?CONST_ETS_ARENA_REPORT, ReportId) of
		?null ->
			<<>>;
		#ets_arena_report{bin_report = Report} ->
			Report
	end.

%% 获取战报		打包数据给前端
get_report_binary(Report)->
	#ets_arena_report{
					  id = ReportId,
					  type = Type,
					  time = Time,
					  deffender_id = DefId,
					  deffender_name = _DefName,
					  rank_change_type = RankType,
					  rank = Rank,
					  result = Result} = Report,
	DefName = player_api:get_name(DefId),
	{ReportId, Type, misc:uint(misc:seconds() - Time), DefId, DefName, RankType, Rank, Result}.

%% 获取挑战者	打包数据给前端
get_member_binary(Member)->
	#ets_arena_member{player_id = PlayerId,
					  player_lv = Lv,
					  rank = Rank,
					  player_sex = Sex,
					  player_career = Pro,
					  player_name = TmpName
					  } = Member,
	Name = misc:to_list(TmpName),
	[_Point, Meritorious, _Experience] = get_challenge_reward(Lv, ?CONST_SINGLE_ARENA_WIN),
	[EquipFashion, EquipArmor, EquipWeapon, GuildName, HorseId, Power] = get_user_equip_mode(PlayerId),
	%%排名奖励
	[Meritorious2, GoodsNum, _Bind, GoodsId, _] = get_rank_reward_data(Member#ets_arena_member.rank, Lv),
	{PlayerId, Lv, Rank, Name, Pro, Sex, Meritorious, 
	 	Meritorious2, GoodsNum, GoodsId, EquipArmor, EquipWeapon, misc:to_list(GuildName), HorseId, Power, EquipFashion}.

%% 获取下次领取奖励时间（每天08:00pm）
get_next_reward_time(UserId) ->
	case get_rank_reward_db(UserId) of
		RankReward when is_record(RankReward, ets_arena_reward) ->
			[GoodsNum, _Bind, GoodsId] = get_reward_goods(RankReward#ets_arena_reward.goods),
			if	
				GoodsNum > 0 andalso GoodsId > 0 ->
					{?CONST_SYS_TRUE, get_next_reward_time()};
				RankReward#ets_arena_reward.meritorious > 0 ->
					{?CONST_SYS_TRUE, get_next_reward_time()};
				?true ->
					{?CONST_SYS_FALSE, get_next_reward_time()}
			end;
		_Other ->
			{0, get_next_reward_time()}
	end.

get_next_reward_time() ->
	{Hour, Min, Second} = misc:time(),
	case (Hour >= ?CONST_SINGLE_ARENA_RANK_REWARD_TIME) of
		?true ->
			TodaySeconds = ?CONST_SYS_ONE_DAY_SECONDS - calendar:time_to_seconds({Hour, Min, Second}),
			NextSeconds = calendar:time_to_seconds({?CONST_SINGLE_ARENA_RANK_REWARD_TIME, 0, 0}),
			TodaySeconds + NextSeconds;
		?false ->
			calendar:time_to_seconds({?CONST_SINGLE_ARENA_RANK_REWARD_TIME, 0, 0}) - calendar:time_to_seconds({Hour, Min, Second})
	end.

%% 获取玩家的护甲/武器
get_user_equip_mode(UserId) ->
	case player_api:get_player_fields(UserId, [#player.guild, #player.equip, #player.style]) of
		{?ok, [Guild, Equip, StyleData]} ->
			HorseId		= get_horse_id(UserId, Equip),
			Power		= partner_api:caculate_camp_power(UserId),
			SkinFashion	= goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION),
			SkinArmor	= goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_ARMOR),
			SkinWeapon	= goods_style_api:get_cur_style(StyleData, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
			[SkinFashion, SkinArmor, SkinWeapon, guild_api:get_guild_name(Guild), HorseId, Power];
		Other ->
			?MSG_DEBUG("ni mei a @@@@@@@@@  ~p, Other ~p", [UserId, Other]),
			[0, 0, 0, <<"null">>, 0, 0]
	end.

get_horse_id(UserId, Equip) ->
	case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, Equip) of
		?false -> 0;
		{{_UserId, _CtnType}, Ctn} ->
            G = erlang:element(?CONST_GOODS_EQUIP_HORSE, Ctn#ctn.goods),
            get_horse_id2(G)
	end.

get_horse_id2(#mini_goods{goods_id = Id}) -> Id;
get_horse_id2(_) -> 0.

%% 更新冠军战报数据库
update_champion_report(ReportId, UserId, UserName, DefId, DefName, Time, BinReport) ->
	case mysql_api:select_execute(<<"select count(*) from game_arena_champion_report">>) of
		{?ok, [[Num]]} ->
			if
				Num >= 3 ->
					mysql_api:execute(<<"DELETE FROM `game_arena_champion_report` order by `report_id` LIMIT 1;">>);
				?true ->
					?ok
			end,
            mysql_api:insert(<<"insert into `game_arena_champion_report`(`report_id`,`user_id`,`user_name`,`opp_id`,`opp_name`,`time`,`bin_report`)",
                               "values ('", (misc:to_binary(ReportId))/binary, "', '",
                                            (misc:to_binary(UserId))/binary, "', '",
                                            (misc:to_binary(UserName))/binary, "', '",
                                            (misc:to_binary(DefId))/binary, "', '",
                                            (misc:to_binary(DefName))/binary, "', '",
                                            (misc:to_binary(Time))/binary, "', ",
                                            (mysql_api:encode(BinReport))/binary, ")">>);
		_Other ->
			?ok
	end.
%% 进入竞技场，推送所有冠军战报
champion_report_to_front(UserId) ->
	case mysql_api:select([report_id, user_id, user_name, opp_id, opp_name, time], game_arena_champion_report) of
		{?ok, []} ->
			?ok;
		{?ok, List} when is_list(List) ->
			Fun = fun([_ReportId, _UserId, _UserName, _OppId, _OppName, Time], [_ReportId2, _UserId2, _UserName2, _OppId2, _OppName2, Time2]) ->
						  Time > Time2
				  end,
			List2 = lists:sort(Fun, List),
			List3 = lists:reverse(List2),
			Packet = champion_report_to_front2(List3, <<>>),
			misc_packet:send(UserId, Packet),
			?ok;
		_Other ->
			?ok
	end.

champion_report_to_front2([], Acc) ->
	Acc;
champion_report_to_front2([[ReportId, UserId, UserName, OppId, OppName, Time]|T], Acc) ->
	Packet = single_arena_api:msg_sc_champion_report(ReportId, UserId, UserName, OppId, OppName, misc:seconds()-Time),
	champion_report_to_front2(T, <<Acc/binary, Packet/binary>>).
	