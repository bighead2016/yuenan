%% Author: Administrator
%% Created: 2012-12-20
%% Description: TODO: Add description to arena_pvp_mod
-module(arena_pvp_mod).

%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.cost.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([enter/1,start/1,
		 enter_data/1,
		 hufu_data/1,get_lv_data/0,
		 match_battle_handle/0,
		 battle_start_cb/2,play_quit_cb/2,
		 exchange/3,battle_over/5,
		 cancel/2,get_reward/2,
		 active_end_reward/1,
		 set_auto/3,auto_data/1,
		 start_update_cb/2,
         start_update_cb2/1,
         start_update/1,
         get_over_flag/1,
         cross_battle_start/1,
         cross_timeout/2,
         over_update_ets/2,
         exchange_partner/2,
         over_update_ets_local/2,
         get_match_lv_win/1,
		 
         team_player_over/2,
		 ets_arena_pvp_m/1,
		 insert_arena_pvp_m/1,
		 init_arena_pvp_m/3,
		 init_arena_m/12
		 ]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%　进入玩法
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
enter(Player = #player{user_id = UserId, account = Account, info = Info,sys_rank = Sys}) -> 
	try
		ActiveState			= active_api:is_opened(?CONST_ACTIVE_ARENA_PVP),	%% 取得活动开启表示
		?ok					= check_enter_state(ActiveState),					%% 检查活动是否开启
		EndTime				= get_end_time(),
		?ok					= check_user_state(Player#player.user_state),		%% 检查玩家状态
		?ok					= check_end_time(EndTime),
 		
 		?ok					= check_enter_sys(Sys),								%% 检查系统
		{?ok,ArenaM}		= arena_pvp_m(Player),
		PacketData			= arena_pvp_api:score_data_msg(ArenaM),
%% 		PacketTime			= arena_pvp_api:msg_sc_enter(EndTime),
		{?ok,Player2}		= check_play_state(Player),							%% 检查玩法状态
		{?ok, PacketTeam}	= team_enter_hanll(Player2),						%% 组队大厅信息
 		misc_packet:send(Player#player.net_pid, <<PacketTeam/binary,PacketData/binary>>),
		insert_arena_pvp_m(ArenaM),
		admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_ARENA_PVP, misc:seconds()),
		achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_MULTIPLAYER_ARENA, 0, 1)
	catch
		throw:{?error,ErrorCode} ->
			error_message(Player, ErrorCode);
		_:_ ->
			error_message(Player, ?TIP_ARENA_PVP_NOT_OPEN)
	end.

enter_data(Player = #player{user_id = UserId,account = Account,info = Info}) ->
	try
		ActiveState			= active_api:is_opened(?CONST_ACTIVE_ARENA_PVP),	%% 取得活动开启表示
		?ok					= check_enter_state(ActiveState),					%% 检查活动是否开启
		EndTime				= get_end_time(),
		?ok					= check_end_time(EndTime),
		{?ok,ArenaM}		= arena_pvp_m(Player),
		PacketData			= arena_pvp_api:score_data_msg(ArenaM),
		PacketTime			= arena_pvp_api:msg_sc_enter(EndTime),
		
 		misc_packet:send(Player#player.net_pid, <<PacketTime/binary,PacketData/binary>>),
		insert_arena_pvp_m(ArenaM),
		admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_ARENA_PVP, misc:seconds())
	catch
		throw:{?error,ErrorCode} ->
			error_message(Player, ErrorCode);
		_:_ ->
			error_message(Player, ?TIP_ARENA_PVP_NOT_OPEN)
	end.

check_end_time(0) ->
	throw({?error,?TIP_ARENA_PVP_NOT_OPEN});
check_end_time(_) -> ?ok.

%% 组队大厅信息
team_enter_hanll(Player) ->
	case team_api:enter_hall(Player) of
		{?ok, Packet} ->
			{?ok, Packet};
		{?error,ErrorCode} ->
			throw({?error,ErrorCode})
	end.

%% 错误消息
error_message(Player, ErrorCode) ->
	Packet = message_api:msg_notice(ErrorCode),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.
error_message(Player, ErrorCode, Name) ->
	Packet = message_api:msg_notice(ErrorCode,[{?TIP_SYS_COMM,Name}]),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.
error_message(Player, ErrorCode, _,UserList) ->
	Packet = message_api:msg_notice(ErrorCode, UserList, [], []), 
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.

%% 检查玩家状态
check_user_state(?CONST_PLAYER_STATE_NORMAL) -> ?ok;
check_user_state(_) ->
	throw({?error,?TIP_ARENA_PVP_NOT_JOIN}).

%% 检查玩法状态
check_play_state(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_MULTI_ARENA) of
		{?true, NewPlayer} -> {?ok,NewPlayer};
		{_,_,ErrorCode} ->
			throw({?error,ErrorCode})
	end.

%% 检查活动状态
check_enter_state(?CONST_SYS_TRUE) -> ?ok;
check_enter_state(_) ->
	throw({?error,?TIP_ARENA_PVP_NOT_OPEN}). %% 还没开启

%% 取得结束时间
get_end_time() ->
	Now = misc:seconds(),
	case ets_api:lookup(?CONST_ETS_ARENA_PVP, ?CONST_ACTIVE_ARENA_PVP) of  
		#arena_pvp_active{end_time = Time} when Time > Now ->
			Time - Now;
		_ -> 
			0
	end.

%% 检查进入的等级
check_enter_sys(Sys) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_MULTIARENA) of
        true ->
            ?ok;
        false ->
            throw({?error,?TIP_ARENA_PVP_SYS})
    end.

%% arena_pvp_m
arena_pvp_m(#player{user_id = UserId,info = Info, position = Position}) ->
	PositionId			= Position#position_data.position,
	case ets_arena_pvp_m(UserId) of
		?null ->
			init_arena_pvp_m(UserId,Info, PositionId);
		ArenaM  ->
			init_arena_pvp_m2(ArenaM,Info#info.lv)
	end.
	
%% 取得arena_pvp_m
get_arena_pvp_m(UserId) ->	
	case ets_arena_pvp_m(UserId) of
		?null ->
			throw({?error,?TIP_ARENA_PVP_TEAM_DATA});
		ArenaM ->
			{?ok,ArenaM}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 队长开始
start(Player) when is_record(Player,player) ->
	try
		ActiveState		= active_api:is_opened(?CONST_ACTIVE_ARENA_PVP),			%% 取得活动开启表示
		?ok				= check_enter_state(ActiveState),							%% 检查活动是否开启
		?ok				= check_leader(Player#player.leader,Player#player.user_id),	%% 检查是否为队长
		TeamId			= Player#player.team_id,
		UidList			= team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA,TeamId),
		?ok				= set_start_team(Player#player.user_id,TeamId),				%% 设置队伍开始
        add_match(Player#player.user_id, Player#player.team_id),
		add_resource_times(UidList),	
		{?ok,Player}
	catch
		throw:{?error, ErrorCode} ->
			error_message(Player, ErrorCode);
		throw:{?error, ErrorCode, Name} ->
			error_message(Player, ErrorCode,Name);
		throw:{?error, ErrorCode, Id, UserList} ->
			error_message(Player, ErrorCode,Id,UserList);
		_:_ ->
			error_message(Player, ?TIP_ARENA_PVP_NO_TEAM)
	end. 

add_match(_, _) when ?IS_CROSS_OPEN == false ->
    ok;

add_match(UserId, TeamId) ->
    Now = misc:seconds(),
    case get_match_lv_win(TeamId) of
        {0, 0} ->ok;
        {Lv, Win}  ->
            {ok, Data1} = battle_cross_api:record_battle(?CONST_BATTLE_TRIBE_ARENA, UserId, TeamId),
            Match = #arena_pvp_cross_match{leader_id = UserId, level = Lv, start_time = Now, streak_win = Win},
            arena_cross_match:app_match(Match,  Data1)
    end.

add_resource_times([]) -> ?ok;
add_resource_times([UserId|Tail]) ->
	schedule_api:add_resource_times(UserId, 3),
	add_resource_times(Tail).

get_match_lv_win(TeamId) ->
    IdList = team_api:get_team_id_list(?CONST_TEAM_TYPE_ARENA, TeamId),
    get_match_lv_win(IdList, 0, 0).

get_match_lv_win([], MaxLv, MaxWin) ->
    {MaxLv, MaxWin};
get_match_lv_win([UserId|RestId], MaxLv, MaxWin) ->
    case ets_arena_pvp_m(UserId) of
        ?null ->
            get_match_lv_win(RestId, MaxLv, MaxWin);
        #arena_pvp_m{lv = Lv, win = Win}  ->
            get_match_lv_win(RestId, max(MaxLv, Lv), max(MaxWin, Win))
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% arena_pvp_mod:match_battle_handle().
%% 匹配战斗
match_battle_handle() ->
	List	= team_api:get_arena_team(),
	F		= fun({TeamId,UserId,Lv},L) ->
					ArenaT = init_arena_pvp_t(TeamId,UserId,Lv), 
					[ArenaT|L]
			  end,
	List2	= lists:foldl(F, [], List), 
	match_battle(List2).

match_battle([]) -> ?ok; 		%% 无队伍匹配
match_battle([_ArenaT|[]]) -> 	%% 剩下一个队伍
	?ok; 
match_battle([ArenaT|List]) ->
	{?ok,Lv1,Lv2} 	= get_lv_data(),		 		%% 随即取出等级范围值	
	LvMinus			= ArenaT#arena_pvp_t.lv - Lv1,	%% 平均等级下限
	LvAdd			= ArenaT#arena_pvp_t.lv + Lv2,	%% 平均等级上限
	
	{?ok,TList} 	= get_battle_list(List,LvMinus,LvAdd,[]),
	{?ok,List2}		= match_battle2(ArenaT,TList,List),
	match_battle(List2).

match_battle2(_ArenaT,[],[]) -> 					%% 无队伍匹配	
	{?ok,[]};
match_battle2(ArenaT,[],List) -> 					%% 所有队伍中匹配一个队伍
	ArenaT2			= misc_random:random_one(List),
	List2			= lists:delete(ArenaT2, List),
	battle_start(ArenaT,ArenaT2),
	{?ok,List2};
match_battle2(ArenaT,TList,List) -> 				%% 等级范围内匹配一个队伍
	ArenaT2			= misc_random:random_one(TList),
	List2			= lists:delete(ArenaT2, List),
 	battle_start(ArenaT,ArenaT2),
	{?ok,List2}.

%% 战斗开始
battle_start(ArenaT1,ArenaT1) -> ?ok;
battle_start(ArenaT1,ArenaT2) -> 
	try
		?ok				= check_battle_time(),
		TeamId			= ArenaT1#arena_pvp_t.team_id,
		BTeamId			= ArenaT2#arena_pvp_t.team_id,
		{?ok,Team1} 	= get_team(TeamId),		
		{?ok,Team2} 	= get_team(BTeamId), 
		LeaderId 		= Team1#team.leader_uid,
 		BUserId			= Team2#team.leader_uid,
		
		LeftList		= team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA, TeamId),
		RightList		= team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA, BTeamId),
		team_api:set_team_state(?CONST_TEAM_TYPE_ARENA, TeamId, ?CONST_TEAM_STATE_OTHER),
		team_api:set_team_state(?CONST_TEAM_TYPE_ARENA, BTeamId, ?CONST_TEAM_STATE_OTHER),
		start_update(LeftList),
		start_update(RightList),
		player_api:process_send(LeaderId, ?MODULE, battle_start_cb, [BUserId,TeamId,BTeamId,LeftList,RightList])
	catch 
		_:_ -> ?ok
	end.

cross_battle_start(TeamId) ->
    LeftList = team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA, TeamId),
    start_update(LeftList),
    team_api:set_team_state(?CONST_TEAM_TYPE_ARENA, TeamId, ?CONST_TEAM_STATE_OTHER).
    

start_update([]) -> ?ok;
start_update([UserId|List]) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
	       player_api:process_send(UserId, ?MODULE, start_update_cb, []);
        [CrossRec] ->
            Node = CrossRec#cross_in.node,
            rpc:call(Node, ?MODULE, start_update_cb2, [UserId])
    end,
	start_update(List).

start_update_cb(Player = #player{user_id = UserId},[]) ->
	case ets_arena_pvp_m(UserId) of
		?null -> ?ok;
		#arena_pvp_m{count = Count}  ->
			ets_api:update_element(?CONST_ETS_ARENA_PVP_M, UserId, [{#arena_pvp_m.count,Count+1}])
	end,
	{?ok,Player}.

start_update_cb2(UserId) ->
    case ets_arena_pvp_m(UserId) of
        ?null -> ?ok;
        #arena_pvp_m{count = Count}  ->
            ets_api:update_element(?CONST_ETS_ARENA_PVP_M, UserId, [{#arena_pvp_m.count,Count+1}])
    end.
					  
battle_start_cb(Player,[BUserId,TeamId,BTeamId,LeftList,RightList]) ->
	battle_start(Player,BUserId,TeamId,BTeamId,LeftList,RightList).

battle_start(Player = #player{team_id = TeamId},BUserId,TeamId,BTeamId,LeftList,RightList) ->
	Param	= #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA,ad1 = TeamId, ad2 = BTeamId,
					 ad3 = LeftList, ad4 = RightList},
	case battle_api:start(Player, BUserId, Param) of
		{?ok, NewPlayer} ->
			{?ok, NewPlayer};
		{?error, _ErrorCode} ->
			{?ok, Player}
	end;
battle_start(Player,_,_,_,_,_) ->
	{?ok, Player}.

%% 检查战斗时间
check_battle_time() ->
	case get_end_time() of
		Time when Time >= 10 -> ?ok; %% 提前10秒就不在匹配队伍
		_ -> 
			throw({?error,?TIP_ARENA_PVP_NOT_OPEN}) %% 活动就要结束
	end.

%% 取得队伍信息
get_team(TeamId) ->
	case team_api:get_team(?CONST_ETS_TEAM_INFO_ARENA, TeamId) of
		{?error,ErrorCode} ->
			throw({?error, ErrorCode});
		{?ok, Team} ->
			{?ok, Team}
	end.

%% 设置开始的队伍信息
set_start_team(_UserId,TeamId) ->
	UidList		= team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA,TeamId),
	?ok			= check_count(UidList),
	?ok			= team_play_start(TeamId),
	?ok.

%% 队伍玩法开始
team_play_start(TeamId) ->
	case team_api:play_start(?CONST_TEAM_TYPE_ARENA,TeamId) of
		?ok -> ?ok;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		{?error, ErrorCode, UserList} ->
			throw({?error, ErrorCode, TeamId, UserList})
	end.

%% 检查次数-队伍
check_count([]) -> ?ok;
check_count([UserId|List]) ->
	case ets_arena_pvp_m(UserId) of
		?null -> ?ok;
		#arena_pvp_m{count = Count} -> 
			UserName	= player_api:get_name(UserId),
			check_count(UserId, UserName, Count)
	end,
	check_count(List).

%% 检查次数-个人
check_count(_UserId, Name, Count) when Count >= ?CONST_ARENA_PVP_COUNT ->
	throw({?error,?TIP_ARENA_PVP_MEM_TIMES, Name});
check_count(_, _, _) -> ?ok.

%% 取得等级范围的队伍列表
get_battle_list([],_LvMinus,_LvAdd,TList) ->
	{?ok,TList};
get_battle_list([ArenaT|ArenaTList],LvMinus,LvAdd,LvList) ->
	if
		ArenaT#arena_pvp_t.lv >= LvMinus andalso ArenaT#arena_pvp_t.lv =< LvAdd  ->
			get_battle_list(ArenaTList,LvMinus,LvAdd,[ArenaT|LvList]);
		?true ->
			get_battle_list(ArenaTList,LvMinus,LvAdd,LvList)
	end.

%% arena_pvp_mod:get_lv_data().
get_lv_data() ->
	Tuple 		= data_arena_pvp:get_odds(),
	[{Lv1,Lv2}] = misc_random:odds_list_norepeat(Tuple, 1),
	{?ok,Lv1,Lv2}.		
	
%% 检查是否队长
check_leader(LeaderId,LeaderId) -> ?ok;
check_leader(_LeaderId,_LeaderId) ->
	throw({?error,?TIP_ARENA_PVP_NOT_LEADER}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
%% 战斗结束
battle_over(LeftId, Res, RightId,LeftList,RightList) ->
    team_player_over(LeftList, LeftId),
    team_player_over(RightList, RightId),
	
	{?ok,Flag1,Flag2} 	= get_over_flag(Res),
	over_update_ets(LeftList,Flag1),				%% 更新ets
	over_update_ets(RightList,Flag2),
	?ok.

cross_timeout(IdList, TeamId) ->
    Fun =
        fun(Id) ->
                Rec = ets_api:lookup(?CONST_ETS_CROSS_IN, Id),
                Node = Rec#cross_in.node,
                rpc:cast(Node, player_api, process_send, [Id, ?MODULE, cancel, {IdList, TeamId}])
        end,
    lists:foreach(Fun, IdList).


team_player_over(IdList, TeamId) ->
    case ?IS_CROSS_OPEN == false of
        true ->
            team_api:play_over(?CONST_TEAM_TYPE_ARENA, TeamId);
        false ->
            case IdList == [] of
                true ->
                    ok;
                _ ->
                    Id = hd(IdList),
                    case ets:lookup(?CONST_ETS_CROSS_IN, Id) of
                        [] ->
                            team_api:play_over(?CONST_TEAM_TYPE_ARENA, TeamId);
                        [Rec] ->
                            Node = Rec#cross_in.node,
                            rpc:call(Node, team_api, play_over, [?CONST_TEAM_TYPE_ARENA, TeamId])
                    end
            end
    end.
%% 战斗结果
get_over_flag(?CONST_BATTLE_RESULT_LEFT) ->
	{?ok,?CONST_BATTLE_RESULT_LEFT,?CONST_BATTLE_RESULT_RIGHT};
get_over_flag(?CONST_BATTLE_RESULT_RIGHT) ->
	{?ok,?CONST_BATTLE_RESULT_RIGHT,?CONST_BATTLE_RESULT_LEFT};
get_over_flag(_) ->
	{?ok,?CONST_BATTLE_RESULT_DRAW,?CONST_BATTLE_RESULT_DRAW}.
	
%% 胜利广播
win_brocast(WinTimes,Name) ->
	if
		WinTimes =:= 5 -> 
			Packet = message_api:msg_notice(?TIP_ARENA_PVP_WIN_TIMES_FIVE,  [{?TIP_SYS_COMM,Name}]),
			misc_app:broadcast_world(Packet);
		WinTimes =:= 10 -> 
			Packet = message_api:msg_notice(?TIP_ARENA_PVP_WIN_TIMES_EIGHT, [{?TIP_SYS_COMM,Name}]),
			misc_app:broadcast_world(Packet);
		WinTimes =:= 15 ->
			Packet = message_api:msg_notice(?TIP_ARENA_PVP_WIN_TIMES_TEN,  [{?TIP_SYS_COMM,Name}]),
			misc_app:broadcast_world(Packet);
		?true -> ?ok
	end.

%% 获得20连胜
arena_pvp_achivement(UserId, WinTimes) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_ARENA_PVP_WIN, WinTimes, 1).


%% 更新ets
over_update_ets([],_) -> ?ok;
over_update_ets([UserId|List],Flag) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            over_update_ets_local(UserId, Flag);
        [Rec] ->
            Node = Rec#cross_in.node,
            rpc:cast(Node, ?MODULE, over_update_ets_local, [UserId, Flag])
    end,
	over_update_ets(List,Flag).


over_update_ets_local(UserId, Flag) ->
    case ets_arena_pvp_m(UserId) of
        ?null -> ?ok;
        ArenaM = #arena_pvp_m{score_current = ScoreC,score_today = ScoreT,hufu_current = HufuC,
                              hufu_today = HufuT,count = Count,score_week = WScore,hufu = Hufu,
                              lv = Lv,win = Win,auto_ready = AutoR, position = PositionId,
                              win_max = WinMax,win_sum = WinSum, gold_today = GoldToday} ->
            Name                    = player_api:get_name(UserId),
			NewPositionId			= case player_api:get_player_field(UserId, #player.position) of
										  {?ok, #position_data{position = Id}} -> Id;
										  _ -> PositionId
									  end,
            {?ok,BindGold,AddHufu}  = get_hufu(Lv,Flag),            %% 增加虎符
            Win2                    = get_win_times(Win,Flag),      %% 连胜次数
            {?ok,RScore,TScore}     = get_score(Win2,Flag),         %% 胜利积分、连胜积分
            AddScore                = RScore+TScore,                %% 增加积分
            WinSum2                 = get_win_sum(WinSum,Flag),     %% 总胜利次数
            WinMax2                 = get_win_max(WinMax,Win2),     %% 最高胜利次数
%%          Count2                  = Count + 1,                    %% 挑战次数
            WScore2                 = WScore + AddScore,            %% 总积分
            ArenaM2 = ArenaM#arena_pvp_m{position		= NewPositionId,
										 win            = Win2, 
%%                                       count          = Count2,
                                         score_current  = ScoreC + AddScore,    %% 积分
                                         score_today    = ScoreT + AddScore,    %% 积分
                                         score_week     = WScore2,              %% 周积分  
                                         
                                         hufu           = Hufu + AddHufu,       %% 虎符
                                         hufu_current   = HufuC + AddHufu,
                                         hufu_today     = HufuT + AddHufu,
                                         
                                         win_max        = WinMax2,
                                         win_sum        = WinSum2,
                                         gold_today     = GoldToday + BindGold
                                         },     
            win_brocast(Win2,Name),
            arena_pvp_achivement(UserId, Win2),
            insert_arena_pvp_m(ArenaM2),
            arena_pvp_db_mod:replace(ArenaM2),
            player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, BindGold, ?CONST_COST_ARENA_PVP_BATTLE),
            player_api:process_send(UserId, ?MODULE, play_quit_cb, [AddScore,AddHufu,AutoR,Count]),
            schedule_api:add_guide_times(UserId, ?CONST_SCHEDULE_ACTIVITY_LATE_MULTI_ARENA),
			catch yunying_activity_mod:update_shuangdan_activity_info(UserId,1003,1),         %双旦活动战群雄检测
			if Win2 =:= 10 ->
				   spirit_festival_activity_api:receive_redbag(UserId, 16, 8);
			   true ->
				   skip
			end,
            welfare_api:add_pullulation(UserId, ?CONST_WELFARE_MULTI_ARENA, 0, 1),
            case Flag of
                ?CONST_BATTLE_RESULT_LEFT ->
                    achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_MULTIPLAYER_ARENA_STREAKWIN, 0, 1);
                _ -> ?ok
            end      
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 战斗结束奖励
get_reward(UserId,Flag) ->
	case ets_arena_pvp_m(UserId) of
		?null -> {?ok,0,0,0,0,0};
		#arena_pvp_m{lv = Lv,win = Win,count = Count} ->
			LCount						= get_lcount(Count),
			{?ok,BindGold,AddHufu} 		= get_hufu(Lv,Flag),
			Win2						= get_win_times(Win,Flag),
			{?ok,RScore,TScore}			= get_score(Win2,Flag),
			{?ok,AddHufu,RScore,TScore,BindGold,LCount}
	end.

get_lcount(Count) ->
	LCount = ?CONST_ARENA_PVP_COUNT - Count,
	if
		LCount >= 0 ->
			LCount;
		?true -> 0
	end.
	
%% 更新队伍-玩家玩法状态
play_quit_cb(Player = #player{net_pid = Pid,user_id = UserId},[AddScore,AddHufu,AutoR,Count]) ->
	EndTime			= get_end_time(),
	PacketAdd 		= message_api:msg_reward_add_arena_score(AddScore),
	PacketHufu 		= message_api:msg_reward_add_hufu(AddHufu),
	
	ArenaM			= ets_arena_pvp_m( UserId),
 	PacketData		= arena_pvp_api:score_data_msg(ArenaM),
	PacketTime		= arena_pvp_api:msg_sc_enter(EndTime),
	
	Packet			= <<PacketAdd/binary,PacketHufu/binary,PacketData/binary,PacketTime/binary>>,
	if
		Count >= ?CONST_ARENA_PVP_COUNT ->
			{?ok,NewPlayer} 	= team_play_quit(Player);
		AutoR =:= ?CONST_SYS_TRUE ->
			{?ok,Player2}		= team_play_quit(Player),
 			{?ok,NewPlayer} 	= team_api:set_member_state(Player2, ?CONST_TEAM_PLAYER_STATE_READY);
		?true ->
			{?ok,NewPlayer} 	= team_play_quit(Player)
	end,

	misc_packet:send(Pid, Packet),
	{?ok,NewPlayer}.

%% 退出玩法
team_play_quit(Player) ->	
	case team_api:play_quit(Player) of
		{?error,_ErrorCode} ->
			{?ok,Player};
		{?ok,Player2} ->
			{?ok,Player2}
	end.

%% 胜利总次数
get_win_sum(Sum,?CONST_BATTLE_RESULT_LEFT) ->
	Sum + 1;
get_win_sum(Sum,_) ->
	Sum.

%% 最高胜利次数
get_win_max(WinMax,Win) when Win > WinMax ->
	Win;
get_win_max(WinMax,_Win) ->
	WinMax.

%% 连胜次数
get_win_times(Win,?CONST_BATTLE_RESULT_LEFT) -> Win +1;
get_win_times(_Win,_) -> 0.

%% 获取虎符
get_hufu(Lv,?CONST_BATTLE_RESULT_LEFT) ->
	case data_arena_pvp:get_card(Lv) of
		?null -> 
			{?ok,0,?CONST_ARENA_PVP_WIN_HUFU};
		#rec_arena_pvp_card{win = Win} ->
			{?ok,Win,?CONST_ARENA_PVP_WIN_HUFU}
	end;
get_hufu(Lv,?CONST_BATTLE_RESULT_RIGHT) ->
	case data_arena_pvp:get_card(Lv) of
		?null -> 
			{?ok,0,?CONST_ARENA_PVP_LOST_HUFU};
		#rec_arena_pvp_card{lost = Lost} ->
			{?ok,Lost,?CONST_ARENA_PVP_LOST_HUFU}
	end;
get_hufu(Lv,_) ->
	case data_arena_pvp:get_card(Lv) of
		?null -> 
			{?ok,0,?CONST_ARENA_PVP_DRAW_HUFU};
		#rec_arena_pvp_card{draw = Draw} ->
			{?ok,Draw,?CONST_ARENA_PVP_DRAW_HUFU}
	end.

%% 获取积分
get_score(Times,?CONST_BATTLE_RESULT_LEFT) ->
	case data_arena_pvp:get_score(Times) of
		?null -> {?ok,?CONST_ARENA_PVP_WIN_SOCRE,0};
		#rec_arena_pvp_score{score = Score} ->
			{?ok,?CONST_ARENA_PVP_WIN_SOCRE , Score}
	end;
get_score(_,?CONST_BATTLE_RESULT_RIGHT) ->
	{?ok,?CONST_ARENA_PVP_LOST_SCORE,0};
get_score(_,_) ->
	{?ok,?CONST_ARENA_PVP_DRAW_SCORE,0}.

%% 取得消耗值
get_exchange_cost(Id) ->
	case data_arena_pvp:get_shop(Id) of
		?null ->
			throw({?error,?TIP_ARENA_PVP_SHOP_DATA});
		#rec_arena_pvp_shop{goods_id = GoodsId, cost =Cost,bind = Bind, partner_id = PartnerId} ->
			{?ok,GoodsId,Cost,Bind,PartnerId}
	end.

%% 检查背包
check_set_bag(Player,GoodsList) ->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_ARENA_PVP_BATTLE, 1, 1, 0, 0, 0, 1, []) of
		{?error, _ErrorCode}->  		% 背包异常
			throw({?error,?TIP_COMMON_CTN_NOT_ENOUGH});
		{?ok, Player2, _, PacketBag} -> % 成功
			{?ok, Player2, PacketBag}
	end.

%% 检查虎符
check_hufu(ArenaM = #arena_pvp_m{hufu = Hufu},Cost) when Hufu >= Cost ->
	Hufu2 	= Hufu - Cost,
	ArenaM2	= ArenaM#arena_pvp_m{hufu = Hufu2},
	{?ok,Hufu2,ArenaM2};
check_hufu(_,_) ->
	throw({?error,?TIP_ARENA_PVP_HUFU}).

%% 虎符数据
hufu_data(Player) when is_record(Player,player) ->
	Value	= case ets_arena_pvp_m(Player#player.user_id) of
				  ?null -> 0;
				  ArenaM -> ArenaM#arena_pvp_m.hufu
			  end,
	Packet	= arena_pvp_api:msg_sc_tiger(Value),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok,Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ets_arena_pvp_m(UserId) ->
	ets_api:lookup(?CONST_ETS_ARENA_PVP_M, UserId).

insert_arena_pvp_m(ArenaM) ->
	ets_api:insert(?CONST_ETS_ARENA_PVP_M, ArenaM).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 虎符兑换
exchange(Player,_Id,0) -> {?ok,Player};
exchange(Player,Id,Num) when is_record(Player,player) ->
	try 
		{?ok,GoodsId,Cost,Bind,ParnterId}			= get_exchange_cost(Id),				%% 兑换物品花费
		Cost2					= get_cost(ParnterId, Cost, Num),
		GoodsList				= make_exchange_goods(GoodsId, Bind, Num),
		Player2					= exchange_partner(Player, ParnterId),
		{?ok,ArenaM}			= get_arena_pvp_m(Player#player.user_id),	%% ets数据
		{?ok,Hufu2,ArenaM2}		= check_hufu(ArenaM,Cost2),					%% 检查虎符
		{?ok, Player3, PacketBag} 	= check_set_bag(Player2,GoodsList),			%% 检查背包
		Packet					= arena_pvp_api:msg_sc_tiger(Hufu2),
		TipPacket				= message_api:msg_notice(?TIP_ARENA_PVP_EXCHANGE_SUCCESS), 
		misc_packet:send(Player#player.net_pid, <<PacketBag/binary,Packet/binary,TipPacket/binary>>),
		insert_arena_pvp_m(ArenaM2),
		arena_pvp_db_mod:replace(ArenaM2),
		{?ok, Player3}
	catch
		throw:{?error,?TIP_COMMON_CTN_NOT_ENOUGH} -> %% 背包异常
			{?ok,Player};
		throw:{?error,ErrorCode} ->
			error_message(Player, ErrorCode);
		_:_ ->
			error_message(Player, ?TIP_ARENA_PVP_NOT_OPEN)
	end.

%% 计算消耗值
get_cost(0, Cost, Num) -> Cost * Num;
get_cost(_PartnerId, Cost, _Num) -> Cost.
%% 获取兑换物品
make_exchange_goods(0,_Bind,_Num) -> [];
make_exchange_goods(GoodsId,Bind,Num) ->
	goods_api:make(GoodsId,Bind,Num).

%% 兑换武将
exchange_partner(Player, 0) -> Player;
exchange_partner(Player, PartnerId) ->
	TeamInList 		= partner_api:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	case lists:keyfind(PartnerId, #partner.partner_id, TeamInList) of
		?false ->
			partner_api:give_partner_list(Player, [PartnerId], ?CONST_PARTNER_TEAM_IN);
		_ ->
			throw({?error,?TIP_ARENA_PVP_PARTNER_IS_EXCHANGED})
	end.

%% 队长取消开始
cancel(Player = #player{user_id = UserId,leader = UserId,team_id = TeamId, info = Info}, {IdList, TeamId}) ->
    Lv = Info#info.lv,
	UidList		= team_api:get_team_uids(?CONST_TEAM_TYPE_ARENA,TeamId),
	UidList2	= lists:delete(UserId, UidList),
	case active_api:is_opened(?CONST_ACTIVE_ARENA_PVP) of
		?CONST_SYS_TRUE ->
%% 			team_api:set_team_state(?CONST_TEAM_TYPE_ARENA,TeamId,?CONST_TEAM_STATE_WAIT),
%%  			team_api:set_member_state(Player, ?CONST_TEAM_PLAYER_STATE_READY),
            {?ok,BindGold,AddHufu}  = get_hufu(Lv, ?CONST_BATTLE_RESULT_LEFT), 
            PacketAward = message_api:msg_notice(?TIP_ARENA_PVP_CROSS_MATCH_FAIL_AWARD, 
                                                 [{?TIP_SYS_COMM, misc:to_list(BindGold)}, 
                                                  {?TIP_SYS_COMM, misc:to_list(AddHufu)}]),
			Packet 	= message_api:msg_notice(?TIP_ARENA_PVP_MATCH_FAIL),
			misc_packet:send(UserId, <<Packet/binary, PacketAward/binary>>),
			cancel2(UidList2),
            update_count(IdList),
            team_api:play_over(?CONST_TEAM_TYPE_ARENA, TeamId),
            {?ok,Flag1,_Flag2}   = arena_pvp_mod:get_over_flag(?CONST_BATTLE_RESULT_LEFT),
            arena_pvp_mod:over_update_ets(IdList,Flag1);
		_ -> ?ok
	end,
    {ok, Player};
cancel(Player, _) -> {ok, Player}.

update_count([]) ->ok;
update_count([Id|RestId]) ->
    case ets:lookup(?CONST_ETS_ARENA_PVP_M, Id) of
        [] ->
            ok;
        [Rec] ->
            OldCount = Rec#arena_pvp_m.count,
            ets_api:update_element(?CONST_ETS_ARENA_PVP_M, Id, [{#arena_pvp_m.count,OldCount+1}])
    end,
    update_count(RestId).

%% 队员根据是否自动参加
cancel2([]) -> ?ok;
cancel2([UserId|L]) ->
	{?ok,ArenaM}	= get_arena_pvp_m(UserId),	%% ets数据
%% 	case ArenaM#arena_pvp_m.auto_ready of
%% 		?CONST_SYS_TRUE ->
%%  			team_api:set_member_state(UserId, ?CONST_TEAM_PLAYER_STATE_READY);
%% 		_ -> 
%% 			team_api:set_member_state(UserId, ?CONST_TEAM_PLAYER_STATE_WAIT)
%% 	end,
    {?ok,BindGold,AddHufu}  = get_hufu(ArenaM#arena_pvp_m.lv, ?CONST_BATTLE_RESULT_LEFT), 
    PacketAward = message_api:msg_notice(?TIP_ARENA_PVP_CROSS_MATCH_FAIL_AWARD, 
                                         [{?TIP_SYS_COMM, misc:to_list(BindGold)}, 
                                          {?TIP_SYS_COMM, misc:to_list(AddHufu)}]),
    Packet  = message_api:msg_notice(?TIP_ARENA_PVP_MATCH_FAIL),
    misc_packet:send(UserId, <<Packet/binary, PacketAward/binary>>),
	cancel2(L).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 活动结束奖励 [Win,WinMax,Score,Hufu,ScoreSum,Rank]
active_end_reward(UserId) ->
	case ets_api:lookup(?CONST_ETS_ARENA_PVP, ?CONST_ACTIVE_ARENA_PVP) of 
		?null ->
			case ets_arena_pvp_m(UserId) of
				#arena_pvp_m{score_current = Score,win_sum = WinSum,win_max = WinMax,
							 score_week = ScoreW,hufu_current = Hufu,rank = Rank} ->
					Packet	= arena_pvp_api:msg_sc_reward(WinSum,WinMax,Score,Hufu,ScoreW,Rank),
					misc_packet:send(UserId, Packet);
				_ -> ?ok
			end;	
		ArenaActive when is_record(ArenaActive,arena_pvp_active) ->
			Now 	= misc:seconds(),
			EndTime	= ArenaActive#arena_pvp_active.end_time,
			if
				EndTime >= Now ->
					Time = EndTime - Now;
				?true ->
					Time = 10
			end,
			Packet	= arena_pvp_api:msg_sc_enter(Time),
			misc_packet:send(UserId, Packet)
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 设置自动参加
set_auto(UserId,Type,Flag) ->
	case ets_arena_pvp_m(UserId) of
		ArenaM = #arena_pvp_m{auto_ready = AutoReady} when Type =:= 1 ->
			ArenaM2 = ArenaM#arena_pvp_m{auto_start = Flag},
			Packet	= arena_pvp_api:msg_sc_auto(Flag,AutoReady),
			insert_arena_pvp_m(ArenaM2),
			misc_packet:send(UserId, Packet);
		ArenaM = #arena_pvp_m{auto_start = AutoStart} when Type =:= 2 ->
			ArenaM2 = ArenaM#arena_pvp_m{auto_ready = Flag},
			Packet	= arena_pvp_api:msg_sc_auto(AutoStart,Flag),
			insert_arena_pvp_m(ArenaM2),
			misc_packet:send(UserId, Packet);
		_ -> ?ok 
	end.

%% 自动信息
auto_data(UserId) ->
	case ets_arena_pvp_m(UserId) of
		#arena_pvp_m{auto_start = Flag1 ,auto_ready = Flag2} ->
			Packet	= arena_pvp_api:msg_sc_auto(Flag1,Flag2),
			misc_packet:send(UserId, Packet);
		_ -> ?ok 
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% init_arena_pvp_t 初始化（用于战斗匹配）
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_arena_pvp_t(TeamId,LeaderId,Lv) ->
	#arena_pvp_t			{
							 team_id			= TeamId, 
							 leader_id			= LeaderId,
							 lv					= Lv
				 			}.
	
%% init_arena_pvp_m
init_arena_pvp_m(UserId,Info, Position) ->
	ArenaM	= #arena_pvp_m	{
							 user_id			= UserId,				%% 玩家id
							 user_name			= Info#info.user_name,	%% 玩家名称
							 pro				= Info#info.pro,		%% 职业
							 sex				= Info#info.sex,		%% 性别
							 lv					= Info#info.lv,			%% 等级
							 position			= Position,				%% 官衔
							 time				= misc:seconds()		%% 参加时间
							},
	{?ok,ArenaM}.

init_arena_pvp_m2(ArenaM,Lv) ->
	Time 	= misc:seconds(), 
	Flag	= misc:is_same_date(ArenaM#arena_pvp_m.time, Time),
	if
		Flag =:= ?false -> 
			ArenaM2 = arena_pvp_api:clear_arena_m_day(ArenaM),
			ArenaM3	= ArenaM2#arena_pvp_m{lv = Lv,time = Time},
			{?ok,ArenaM3};
		?true -> %% 次数已满		
			ArenaM2	= ArenaM#arena_pvp_m{time = Time,lv = Lv},
			{?ok,ArenaM2}
	end.

init_arena_m(UserId,UserName,Pro,Sex,Lv,Win,Hufu,_Score, ScoreWeek,Count,Time,PositionId) ->
	#arena_pvp_m			{
							 user_id			= UserId,	%% 玩家id
							 user_name			= UserName,	%% 玩家名称
							 pro				= Pro,		%% 职业
							 sex				= Sex,		%% 性别
							 lv					= Lv,		%% 等级
							 position			= PositionId,%% 官衔
							 hufu				= Hufu,		%% 虎符数量
%% 							 score				= Score,	%% 当场积分
							 score_week			= ScoreWeek,%% 周积分	
							 count				= Count,	%% 当场参加次数
							 win				= Win,		%% 连续胜利次数
							 time				= Time		%% 参加时间
							}.	


%%
%% Local Functions
%%

