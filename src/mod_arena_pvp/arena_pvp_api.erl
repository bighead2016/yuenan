%% Author: Administrator
%% Created: 2012-12-20
%% Description: TODO: Add description to arena_pvp_api
-module(arena_pvp_api).

%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([
		 check_team_play/2, check_play_over/0,
		 clear/0,clear_handle/0,
		 clear_arena_m_day/1,
		 week_reward/0,week_reward_handle/0,
		 initial_ets/0,
		 flush_offline/2,
		 on/1,off/1,
		 battle_over/5,match_battle/0, 
		 
		 check_play_again/1,
		 get_reward/2,
		 get_surplus_count/1,
		 send_reward_list/2,
         
         ets_arena_pvp_m/1,
         insert_arena_pvp_m/1,
		
		 score_data_msg/1,
		 msg_sc_enter/1,msg_sc_data/10,msg_sc_auto/2,
		 msg_sc_tiger/1,msg_sc_week_reward/4,
		 msg_sc_reward/6,
		 msg_end_times_notice/1,
		 msg_sc_rank_data/1]).

%% team-param-team_param
%%
%% API Functions
%%

%% 初始化ets
initial_ets() ->
	arena_pvp_db_mod:select_data().

%% 战斗结束奖励信息
%% arena_pvp_api:get_reward(UserId,Flag).
get_reward(UserId,Flag) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
	       arena_pvp_mod:get_reward(UserId, Flag);
        [UserRec] ->
            Node = UserRec#cross_in.node,
            rpc:call(Node, arena_pvp_mod, get_reward, [UserId, Flag])
    end.

%% 检查是否继续玩法
%% {?error,?TIP_ARENA_PVP_TIMES_FULL} | ?ok
check_play_again(Player) ->
	case arena_pvp_mod:ets_arena_pvp_m(Player#player.user_id) of
		?null -> ?ok;
		#arena_pvp_m{count = Count} when Count < ?CONST_ARENA_PVP_COUNT ->
			?ok;
		_ ->
			{?error,?TIP_ARENA_PVP_TIMES_FULL}
	end.

%% 剩余次数 arena_pvp_api:get_surplus_count(Player).
get_surplus_count(#player{sys_rank = Sys,user_id = UserId}) ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_MULTIARENA) of
        true ->
        	case arena_pvp_mod:ets_arena_pvp_m(UserId) of
        		#arena_pvp_m{count = Count,time = Time} ->
        			case misc:is_same_date(Time, misc:seconds()) of
        				?true ->
        					?CONST_ARENA_PVP_COUNT - Count;
        				_ -> ?CONST_ARENA_PVP_COUNT
        			end;		 
        		_ -> 
        			?CONST_ARENA_PVP_COUNT
        	end;
        false ->
            0
    end.


%% arena_pvp_api:clear().
%% 每日清除
clear() ->
	arena_pvp_serv:clear_cast().

clear_handle() ->	
	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_M),
	F			= fun(ArenaM) ->
					  ArenaM2 		= clear_arena_m_day(ArenaM),
					  arena_pvp_mod:insert_arena_pvp_m(ArenaM2),
					  arena_pvp_db_mod:replace(ArenaM2)
			  	  end,
	lists:foreach(F, List).

%% 每日清除
clear_arena_m_day(ArenaM) ->
	ArenaM#arena_pvp_m{
                             gold_today        = 0,
							 auto_ready			= ?CONST_SYS_FALSE,
							 auto_start			= ?CONST_SYS_FALSE,
							 score_current		= 0,	%% 当场积分
							 score_today		= 0,	%% 当天积分
							 hufu_current		= 0,	%% 当场虎符
							 hufu_today			= 0,	%% 当天虎符
							 count				= 0,	%% 当场参加次数
							 win				= 0,	%% 当前连胜次数
							 win_max			= 0,	%% 最高连胜纪录
							 win_sum			= 0		%%   胜利次数
					   }.

%% 每场清除
clear_arena_m(ArenaM) ->
	ArenaM#arena_pvp_m{
							 auto_ready			= ?CONST_SYS_FALSE,
							 auto_start			= ?CONST_SYS_FALSE,
							 score_current		= 0,	%% 当场积分
							 hufu_current		= 0,	%% 当场虎符
							 win				= 0,	%% 当前连胜次数
							 win_max			= 0, 	%% 最高连胜纪录
							 win_sum			= 0		%%   胜利次数
					   }.
	
	
%% arena_pvp_api:week_reward().
%% 每周清除
week_reward() ->
	arena_pvp_serv:week_reward_cast().

week_reward_handle() ->	
	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_M),
	week_arena(List,[]),						%% 积分列表
	?ok.
	
%% week_reward_handle() ->	
%% 	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_M),
%% 	SortList	= week_arena(List,[]),			%% 积分列表
%% 	SortList2	= lists:sort(SortList),			%% 列表排序
%% 	SortList3	= lists:reverse(SortList2),		%% 列表倒序
%% 	SortList4	= get_sort_list(SortList3),		%% 取出奖励列表
%% 	send_reward_list(SortList4,1).				%% 发送奖励

week_arena([],SortList) ->
	SortList;
week_arena([#arena_pvp_m{score_week = 0}|List],SortList) ->
	week_arena(List,SortList);
week_arena([ArenaM = #arena_pvp_m{lv = Lv,user_id = UserId,score_week = Score}|List],SortList) ->
	ArenaM2 	= ArenaM#arena_pvp_m{score_week = 0},	%% 清除周积分
	arena_pvp_mod:insert_arena_pvp_m(ArenaM2),
	arena_pvp_db_mod:replace(ArenaM2),
	week_arena(List,[{Score,Lv,1/UserId,UserId}|SortList]).

%% 发送奖励
send_reward_list([],_) -> ?ok;
send_reward_list([Head|List],Rank) ->
	{_Score,_,_,UserId} 	= Head,
	UserName			= player_api:get_name(UserId),
	GoodsList 			= get_reward(Rank), 
	{?ok,Top,Main}		= get_mail_explain(?CONST_RANK_ARENA,Rank),
	case mail_api:send_system_mail_to_one2(UserName, Top, Main, 0, [], GoodsList, 0, 0, 0, 
										   ?CONST_COST_ARENA_PVP_WEEK_GOODS) of
		{?error,ErrorCode} ->
			?MSG_ERROR("arena_pvp rank send mail error ~p",[ErrorCode]);
		_ ->  
			?MSG_ERROR("arena_pvp send mail success name:~ts goods:~p",[misc:to_list(UserName),GoodsList]),
			?ok
	end,
	send_reward_list(List,Rank+1).

get_mail_explain(Type,Rank) ->
	case data_rank:rank_explain({Type,Rank}) of
		#rec_rank_explain{top = Top,main = Main} ->
			{?ok,Top,Main};
		_ ->
			{?ok,<<"">>,<<"">>}
	end.

%% 发送奖励
get_reward(Rank) ->
	case data_arena_pvp:get_reward(Rank) of
		?null ->[];
		Data ->
			GoodsList	= Data#rec_arena_pvp_reward.goods_list,		
			get_goods_list(GoodsList)
	end.

get_goods_list(Data) ->
	F = fun({GoodsId, Bind, GoodsNum},Arg) ->
			case goods_api:make(GoodsId, Bind, GoodsNum) of
				{?error,_} ->
					?MSG_ERROR("rank reward ~p",[GoodsId]),
					Arg;
				Goods ->
					Goods ++ Arg
			end
		end,
	lists:foldl(F, [], Data).
		
get_sort_list(List) when length(List) =< 10 ->
	List;
get_sort_list(List) ->
	{List2,_}	= lists:split(10,List),
	List2.

%% 上线领取奖励
flush_offline(Player, _Rank) ->
	{?ok,Player}.	

%% 战斗结束
battle_over(LeftId, Res, RightId,LeftList,RightList) ->
	arena_pvp_mod:battle_over(LeftId, Res, RightId,LeftList,RightList).

%% 匹配战斗
match_battle() ->
	arena_pvp_serv:match_battle_cast().

%% 
%% 开始广播
%% arena_pvp_api:on(1).
on(_) ->
	crond_api:interval_del(arena_pvp_battle),
	crond_api:interval_add(arena_pvp_battle, ?CONST_ARENA_PVP_BATTLE_TIME, arena_pvp_api, match_battle, []), 
	
	Active	= #arena_pvp_active{id 			= ?CONST_ACTIVE_ARENA_PVP,
								end_time 	= misc:seconds() + 1800
							   },
	ets_api:insert(?CONST_ETS_ARENA_PVP, Active),
	
	List 	= ets_api:list(?CONST_ETS_ARENA_PVP_M),
	F		= fun (ArenaM) ->
					   ArenaM2 = clear_arena_m(ArenaM),
					   arena_pvp_mod:insert_arena_pvp_m(ArenaM2)
			  end,
	lists:foreach(F, List).
		
%% 结束广播
%% arena_pvp_api:off(1).
off(_) ->
	crond_api:interval_del(arena_pvp_battle),
	team_api:player_over_clean(?CONST_TEAM_TYPE_ARENA),
	active_off_handle(),
	ets_api:delete(?CONST_ETS_ARENA_PVP,?CONST_ACTIVE_ARENA_PVP),
	?ok.

%% 活动中刷新排名
%% rank_interval() -> 
%% 	ets:delete_all_objects(?CONST_ETS_ARENA_PVP_RANK),
%% 	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_M),
%% 	SortList	= [{Score,Lv,1/UserId,UserId} || #arena_pvp_m{lv = Lv,score_week = Score,user_id = UserId} <- List,Score > 0],
%% 	SortList2	= lists:sort(SortList),			%% 列表排序
%% 	SortList3	= lists:reverse(SortList2),		%% 列表倒序
%% 	SortList4	= get_sort_list(SortList3),		%% 取出奖励列表
%% 	rank_interval(SortList4,1).
%%  
%% rank_interval([],_) -> ?ok;
%% rank_interval([{Score,_,_,UserId}|List],Rank) ->
%% 	UserName	= player_api:get_name(UserId),
%% 	ArenaR 		= #arena_pvp_rank{rank 		= Rank, 
%% 								  user_id 	= UserId, 
%% 								  user_name = UserName,
%% 								  score		= Score},
%% 	ets_api:insert(?CONST_ETS_ARENA_PVP_RANK, ArenaR),
%% 	rank_interval(List,Rank+1).

%% rank_list() ->
%% 	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_RANK),
%% 	[{Rank,UserId,UserName,Score} || #arena_pvp_rank{rank = Rank,user_id =UserId,
%% 													 user_name = UserName,score = Score} <- List].

%% 活动结束-排名
active_off_handle() ->
	List 		= ets_api:list(?CONST_ETS_ARENA_PVP_M),
	SortList	= rank_list(List,[]),
	SortList2	= lists:sort(SortList),			%% 列表排序
	SortList3	= lists:reverse(SortList2),		%% 列表倒序
	
	F			= fun({_Score,_,_,ArenaM},Rank) ->
					  	  ets_api:update_element(?CONST_ETS_ARENA_PVP_M, ArenaM#arena_pvp_m.user_id, 
												 [{#arena_pvp_m.rank, Rank}]),
					      Rank + 1
			  	  end,
	lists:foldl(F,1, SortList3).

rank_list([],SortList) ->
	SortList;
rank_list([H|L],SortList) when is_record(H,arena_pvp_m) ->
	SortList2 = [{H#arena_pvp_m.score_week,H#arena_pvp_m.lv,1/H#arena_pvp_m.user_id ,H}|SortList],
	rank_list(L,SortList2);
rank_list([_|L],SortList) ->
	rank_list(L,SortList).

%% 检查组队 arena_pvp_api:check_team_play
check_team_play(Player,?CONST_TEAM_CHECK_INVITE) -> 
    case Player#player.sys_rank < data_guide:get_task_rank(?CONST_MODULE_MULTIARENA) of
        true ->
            {?error,?TIP_ARENA_PVP_M_SYS};
        false ->
        	Flag	= active_api:is_opened(?CONST_ACTIVE_ARENA_PVP),
        	case arena_pvp_mod:ets_arena_pvp_m(Player#player.user_id) of
        		?null ->
					Position		= Player#player.position,
					PositionId		= Position#position_data.position,
        			{?ok,ArenaM}	= arena_pvp_mod:init_arena_pvp_m(Player#player.user_id,Player#player.info, PositionId);
        		ArenaM  -> ?ok
        	end,			   
        	Time 	= misc:seconds(), 
        	TimeFlag= misc:is_same_date(ArenaM#arena_pvp_m.time, Time),
        	if
        		TimeFlag =:= ?false -> 
        			ArenaM2 = clear_arena_m_day(ArenaM),
        			ArenaM3	= ArenaM2#arena_pvp_m{time = Time},	
        			Count 	= 0,
        			arena_pvp_mod:insert_arena_pvp_m(ArenaM3);
        		?true -> %% 次数已满		
        			Count 	= ArenaM#arena_pvp_m.count
        	end,
        	if
        		Flag =:= ?CONST_SYS_FALSE ->
        			{?error,?TIP_ARENA_PVP_ACTIVE_OVER};
        		Count >= ?CONST_ARENA_PVP_COUNT -> 
        			{?error,?TIP_ARENA_PVP_M_COUNT};
        		?true ->
        			?ok
        	end
    end;
check_team_play(Player = #player{user_id = UserId},_Type) ->
    case Player#player.sys_rank < data_guide:get_task_rank(?CONST_MODULE_MULTIARENA) of
        true ->
            {?error,?TIP_ARENA_PVP_SYS};
        false ->
        	case active_api:is_opened(?CONST_ACTIVE_ARENA_PVP) of
        		?CONST_SYS_TRUE ->
        			case arena_pvp_mod:ets_arena_pvp_m(UserId) of
        				?null -> ?ok;
        				#arena_pvp_m{count = Count} when Count >= ?CONST_ARENA_PVP_COUNT ->
        					{?error,?TIP_ARENA_PVP_TIMES_FULL};
        				_ -> ?ok
        			end;
        		_ ->
        			{?error,?TIP_ARENA_PVP_ACTIVE_OVER} 
        	end
    end.

%% 检查活动是否结束(多人组队模块调用)
check_play_over() ->
	case active_api:is_opened(?CONST_ACTIVE_ARENA_PVP) of
		?CONST_SYS_TRUE -> ?false;
		_ -> ?true
	end.

score_data_msg(ArenaM) ->
	Count		= ?CONST_ARENA_PVP_COUNT - ArenaM#arena_pvp_m.count,
	Score		= ArenaM#arena_pvp_m.score_week,
	ScoreToday	= ArenaM#arena_pvp_m.score_today,
	Hufu		= ArenaM#arena_pvp_m.hufu,
	HufuToday	= ArenaM#arena_pvp_m.hufu_today,
	Win			= ArenaM#arena_pvp_m.win,
	Winscore	= get_win_score(Win+1),
    ScoreTotal = ArenaM#arena_pvp_m.score_current,
    Gold = ArenaM#arena_pvp_m.gold_today,
    Rank = ArenaM#arena_pvp_m.rank,
	msg_sc_data(Count,Score,ScoreToday,Hufu,HufuToday,Win,Winscore, ScoreTotal, Gold, Rank).

%% 取得连胜积分
get_win_score(Times) ->
	case data_arena_pvp:get_score(Times) of
		?null -> 0;
		#rec_arena_pvp_score{score = Score} -> Score
	end.

ets_arena_pvp_m(UserId) ->
    arena_pvp_mod:ets_arena_pvp_m(UserId).

insert_arena_pvp_m(ArenaM) ->
    arena_pvp_mod:insert_arena_pvp_m(ArenaM).

%% 进入玩法返回
%%[Time]
msg_sc_enter(Time) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_ENTER, ?MSG_FORMAT_ARENA_PVP_SC_ENTER, [Time]).
%% 更新虎符值
%%[Value]
msg_sc_tiger(Value) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_TIGER, ?MSG_FORMAT_ARENA_PVP_SC_TIGER, [Value]).
%% 每周奖励
%%[BindCash,BindGold,Meritorioust,{GoodsId,Bind,Num}]
msg_sc_week_reward(BindCash,BindGold,Meritorious,List1) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_WEEK_REWARD, ?MSG_FORMAT_ARENA_PVP_SC_WEEK_REWARD, [BindCash,BindGold,Meritorious,List1]).
%% 结束奖励
%%[Win,WinMax,Score,Hufu,ScoreSum,Rank]
msg_sc_reward(Win,WinMax,Score,Hufu,ScoreSum,Rank) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_REWARD, ?MSG_FORMAT_ARENA_PVP_SC_REWARD, [Win,WinMax,Score,Hufu,ScoreSum,Rank]).
%% 群雄数据
%%[Count,Score,ScoreToday,Hufu,HufuToday,Win,Winscore,Score2,Gold,Rank]
msg_sc_data(Count,Score,ScoreToday,Hufu,HufuToday,Win,Winscore,Score2,Gold,Rank) ->
    misc_packet:pack(?MSG_ID_ARENA_PVP_SC_DATA, ?MSG_FORMAT_ARENA_PVP_SC_DATA, [Count,Score,ScoreToday,Hufu,HufuToday,Win,Winscore,Score2,Gold,Rank]).
%% 是否自动准备 
%%[Flag]
msg_sc_auto(Flag,Flag2) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_AUTO, ?MSG_FORMAT_ARENA_PVP_SC_AUTO, [Flag,Flag2]).
%% 结束次数不足提示
%%[Flag]
msg_end_times_notice(Flag) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_END_TIMES_NOTICE, ?MSG_FORMAT_ARENA_PVP_END_TIMES_NOTICE, [Flag]).
%% 排名数据
%%[{Rank,UserId,UserName}]
msg_sc_rank_data(List1) ->
	misc_packet:pack(?MSG_ID_ARENA_PVP_SC_RANK_DATA, ?MSG_FORMAT_ARENA_PVP_SC_RANK_DATA, [List1]).
%%
%% Local Functions
%%
