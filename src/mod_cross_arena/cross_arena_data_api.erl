%% Author: Administrator
%% Created: 2013-12-17
%% Description: TODO: Add description to cross_arena_data_api
-module(cross_arena_data_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([data_operate_cast/3, data_operate_cast_cb/3,
		 data_operate_call/3, data_operate_call_cb/3]).

-export([insert_member_ets/1,
         refresh_ets_phase/0,
         refresh_daily_phase/0,
         find_real_postion/1, 
		 update_member_ets/1, 
		 update_phase_ets/1,
         delete_ets_by_id/3,
         delete_phase_info_by_id/3,
         refresh_daily_member/0,
		 update_report_ets/1,
		 update_group_report_ets/1,
		 update_robot_ets/1,
		 get_arena_info_by_id/1, 
		 get_member_by_group/2,
		 get_phase_group/1,
		 get_phase_info/1,
		 get_report/1,
		 get_group_report/2,
		 get_robot/1,
		 delete_robot_by_id/1,
		 broadcast/2,
		 broadcast_group/2,
		 broadcast_open/2,
		 broadcast_group_open/2,
		 get_next_reward_time/1,
		 check_is_over/0,
		 record_player_data1/1,
		 record_player_data2/1,
		 record_player_data3/1,
		 record_player_data/3,
		 deal_empty_group/2,
		 get_list_by_phase_group/2
		 ]).

-export([mail/3,
		 refresh_daily_db/0,
		 refresh_daily_ets/0,
		 get_achive_cb/3,
		 mail_last_award_cb/4,
		 flush_offline/2,
		 daily_reward_cb/2,
		 init_cross_arena_member/0,
		 init_cross_arena_phase/0,
		 init_cross_arena_report/0,
		 init_cross_arena_group_report/0,
		 init_cross_arena_robot/0,
		 init_clean_center_ets/0]).

-compile(export_all).
%%
%% API Functions
%%
data_operate_cast(Mod, Fun, Arg) ->
	case center_api:get_center_node() of
        ?null ->
			?MSG_ERROR("center_node is null~p", []),
            ?ok;
        CenterNode ->
            case net_adm:ping(misc:to_atom(CenterNode)) of
                pong ->
                    rpc:cast(misc:to_atom(CenterNode), ?MODULE, data_operate_cast_cb, [Mod, Fun, Arg]);
                pang ->
					?MSG_ERROR("44444:~p", [CenterNode]),
                    ?ok
            end
    end.
data_operate_cast_cb(Mod, Fun, {}) ->
	Mod:Fun();
data_operate_cast_cb(Mod, Fun, {A}) ->
	Mod:Fun(A);
data_operate_cast_cb(Mod, Fun, {A, B}) ->
	Mod:Fun(A, B);
data_operate_cast_cb(Mod, Fun, {A, B, C}) ->
	Mod:Fun(A, B, C);
data_operate_cast_cb(_Mod, _Fun, _) ->
	?ok.

data_operate_call(Mod, Fun, Arg) ->
	case center_api:get_center_node() of
        ?null ->
			?MSG_ERROR("center_node is null~p", []),
            ?ok;
        CenterNode ->
            case net_adm:ping(misc:to_atom(CenterNode)) of
                pong ->
                    rpc:call(misc:to_atom(CenterNode), ?MODULE, data_operate_call_cb, [Mod, Fun, Arg]);
                pang ->
					?MSG_DEBUG("44444:~p", [CenterNode]),
                    ?ok
            end
    end.
data_operate_call_cb(Mod, Fun, {}) ->
	Mod:Fun();
data_operate_call_cb(Mod, Fun, {A}) ->
	Mod:Fun(A);
data_operate_call_cb(Mod, Fun, {A, B}) ->
	Mod:Fun(A, B);
data_operate_call_cb(Mod, Fun, {A, B, C}) ->
	Mod:Fun(A, B, C);
data_operate_call_cb(_Mod, _Fun, _) ->
	?ok.

%% 插入一个玩家的竞技场信息
insert_member_ets(Member)->
	ets:insert_new(?CONST_ETS_CROSS_ARENA_MEMBER, Member).

%% 更新一个玩家的竞技场信息
update_member_ets(Member)-> 
	ets:insert(?CONST_ETS_CROSS_ARENA_MEMBER, Member).

%% 更新竞技场段信息
update_phase_ets(PhaseInfo)-> 
	ets:insert(?CONST_ETS_CROSS_ARENA_PHASE, PhaseInfo).

%% 更新战报信息
update_report_ets(Report)-> 
	ets:insert(?CONST_ETS_CROSS_ARENA_REPORT, Report).

%% 更新组内战报id信息
update_group_report_ets(Report)-> 
	ets:insert(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, Report).

%% 更新组内战报id信息
update_robot_ets(Robot)-> 
	ets:insert(?CONST_ETS_CROSS_ARENA_ROBOT, Robot).

%% 获取某个玩家的竞技场信息
get_arena_info_by_id(UserId)->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_MEMBER, UserId) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% get_member_by_group(Phase, Group) ->
%% 	MS = ets:fun2ms(fun(T) when T#ets_cross_arena_member.phase =:= Phase 
%% 						 andalso T#ets_cross_arena_member.group =:= Group  -> T end),
%% 	ets:select(?CONST_ETS_CROSS_ARENA_MEMBER, MS).

get_member_by_group(Phase, Group) ->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_PHASE, Phase) of
		[] ->
			[];
		[PhaseInfo] ->
			GroupList = PhaseInfo#cross_arena_phase.group_list,
			case lists:keyfind(Group, 1, GroupList) of
				{Group, UserList} ->
%% 					lists:map(fun({Item, _}) -> get_arena_info_by_id(Item) end, UserList);
					get_member_by_group_ext(Phase, Group, UserList, []);
				_ ->
					[]
			end
	end.

get_member_by_group_ext(Phase, Group, [{UserId, _}|TailList], AccList) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			AccList2 = [Member|AccList],
			get_member_by_group_ext(Phase, Group, TailList, AccList2);
		_ ->
			delete_ets_by_id(UserId, Phase, Group),
			get_member_by_group_ext(Phase, Group, TailList, AccList)
	end;
get_member_by_group_ext(_Phase, _Group, [], AccList) ->
	AccList.
			
%% 获取竞技场最大段(PhaseInfo结构#ets_arena_phase{phase_id, group_list = [{group_id, [{userid1, rank1},{userid2, rank2}...]}]})
%% 返回 {PhaseId, GroupId, Rank, PhaseInfo}
get_phase_group(UserId)->
	case ets:info(?CONST_ETS_CROSS_ARENA_PHASE, size) of
		 0 ->
			 PhaseInfo = #cross_arena_phase{phase = 1, group_list = [{1, [{UserId, 1}]}]},
			 {1, 1, 1, PhaseInfo};
		_Num ->
			List = ets:select(?CONST_ETS_CROSS_ARENA_PHASE, ets:fun2ms(fun(Member) -> Member#cross_arena_phase.phase end)),
			case List of
				[] ->
					PhaseInfo = #cross_arena_phase{phase = 1, group_list = [{1, [{UserId, 1}]}]},
					{1, 1, 1, PhaseInfo};
				_Other ->
					Phase 		= lists:max(List),
					PhaseInfo	= get_phase_info(Phase),
					GroupList 	= PhaseInfo#cross_arena_phase.group_list,
					{MaxGroupId, _MaxUserList} = lists:max(GroupList),
%% 					LenUser		= length(UserList),
					case get_empty_group(GroupList) of 
						{GroupId, UserList} -> %% 人员未满 排名 +1
							Rank	   = length(UserList) + 1,
							NewGroup   = {GroupId, UserList ++ [{UserId, Rank}]},
							GroupList2 = lists:keyreplace(GroupId, 1, GroupList, NewGroup),
							PhaseInfo2 = PhaseInfo#cross_arena_phase{group_list = GroupList2},
							{Phase, GroupId, Rank, PhaseInfo2};
						_ -> %% 人员满了
							GroupNum = cross_arena_api:get_phase_by_group(Phase),
							case MaxGroupId < GroupNum of
								?true -> %% 组未满 同一段新建组
									NewGroup   = {MaxGroupId + 1, [{UserId, 1}]},
									GroupList2 = GroupList ++ [NewGroup],
									PhaseInfo2 = PhaseInfo#cross_arena_phase{group_list = GroupList2},
									{Phase, MaxGroupId + 1, 1, PhaseInfo2};
								?false -> %% 组满 新建段
									PhaseInfo2 = #cross_arena_phase{phase = Phase + 1, group_list = [{1, [{UserId, 1}]}]},
									{Phase + 1, 1, 1, PhaseInfo2}
							end
					end
			end
	end.

get_empty_group([{Group, UserList} | TailList]) ->
	case length(UserList) < ?CONST_CROSS_ARENA_GROUP_COUNT of
		?true ->
			{Group, UserList};
		?false ->
			get_empty_group(TailList)
	end;
get_empty_group([]) -> ?ok.
	
%% get_phase_group(UserId)->
%% 	case ets:info(?CONST_ETS_CROSS_ARENA_PHASE, size) of
%% 		 0 ->
%% 			 init_phase(7, 1);
%% 		_Num ->
%% 			?ok
%% 	end,
%% 	List = ets:select(?CONST_ETS_CROSS_ARENA_PHASE, ets:fun2ms(fun(Member) -> Member#cross_arena_phase.phase end)),
%% 	Phase 		= lists:max(List),
%% 	PhaseInfo	= get_phase_info(Phase),
%% 	GroupList 	= PhaseInfo#cross_arena_phase.group_list,
%% 	{GroupId, UserList} = lists:max(GroupList),
%% 	LenUser		= length(UserList),
%% 	case LenUser < 10 of 
%% 		?true -> %% 人员未满 排名 +1
%% 			Rank	   = length(UserList) + 1,
%% 			NewGroup   = {GroupId, UserList ++ [{UserId, Rank}]},
%% 			GroupList2 = lists:keyreplace(GroupId, 1, GroupList, NewGroup),
%% 			PhaseInfo2 = PhaseInfo#cross_arena_phase{group_list = GroupList2},
%% 			{Phase, GroupId, Rank, PhaseInfo2};
%% 		?false -> %% 人员满了
%% 			GroupNum = cross_arena_api:get_phase_by_group(Phase),
%% 			case GroupId < GroupNum of
%% 				?true -> %% 组未满 同一段新建组
%% 					NewGroup   = {GroupId + 1, [{UserId, 1}]},
%% 					GroupList2 = GroupList ++ [NewGroup],
%% 					PhaseInfo2 = PhaseInfo#cross_arena_phase{group_list = GroupList2},
%% 					{Phase, GroupId + 1, 1, PhaseInfo2};
%% 				?false -> %% 组满 新建段
%% 					PhaseInfo2 = #cross_arena_phase{phase = Phase + 1, group_list = [{1, [{UserId, 1}]}]},
%% 					{Phase + 1, 1, 1, PhaseInfo2}
%% 			end
%% 	end.
%% init_phase(InitNum, Num) when Num >= 1 andalso Num =< InitNum ->
%% 	PhaseInfo = #cross_arena_phase{phase = Num, group_list = [{1, []}]},
%% 	update_phase_ets(PhaseInfo),
%% 	init_phase(InitNum, Num + 1);
%% init_phase(_InitNum, _Num) -> ?ok.
%% 按段取得
get_phase_info(Phase) ->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_PHASE, Phase) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% 获取战报
get_report(ReportId) ->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_REPORT, ReportId) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% 获取战报
get_group_report(Phase, GroupId) ->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, {Phase, GroupId}) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% 获取战报
get_robot(UserId) ->
	case ets:lookup(?CONST_ETS_CROSS_ARENA_ROBOT, UserId) of
		[] ->
			[];
		[Value] ->
			Value
	end.

%% 广播给组内所有人
broadcast(UserId, Packet) when is_integer(UserId) ->
	Member		= get_arena_info_by_id(UserId),
	broadcast(Member, Packet);
broadcast(Member, Packet) when is_record(Member, ets_cross_arena_member) ->
	Phase		= Member#ets_cross_arena_member.phase,
	Group		= Member#ets_cross_arena_member.group,
	GroupList	= get_member_by_group(Phase, Group),
	broadcast_group(GroupList, Packet).
broadcast_group([Member|MemberList], Packet) ->
	UserId		= Member#ets_cross_arena_member.player_id,
	ServId		= Member#ets_cross_arena_member.sn,
	case center_api:get_serv_info(ServId) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			rpc:cast(misc:to_atom(Node), misc_packet, send, [UserId, Packet]);
		_ ->
			?ok
	end,
	broadcast_group(MemberList, Packet);
broadcast_group([], _Packet) -> ?ok.

%% 广播给组内所有人
broadcast_open(UserId, Packet) when is_integer(UserId) ->
	Member		= get_arena_info_by_id(UserId),
	broadcast_open(Member, Packet);
broadcast_open(Member, Packet) when is_record(Member, ets_cross_arena_member) ->
	Phase		= Member#ets_cross_arena_member.phase,
	Group		= Member#ets_cross_arena_member.group,
	GroupList	= get_member_by_group(Phase, Group),
	broadcast_group_open(GroupList, Packet).
broadcast_group_open([Member|MemberList], Packet) ->
	UserId		= Member#ets_cross_arena_member.player_id,
	ServId		= Member#ets_cross_arena_member.sn,
	OpenFlag	= Member#ets_cross_arena_member.open_flag,
	case center_api:get_serv_info(ServId) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			case OpenFlag of
				1 ->
					rpc:cast(misc:to_atom(Node), misc_packet, send, [UserId, Packet]);
				_ ->
					?ok
			end;
		_ ->
			?ok
	end,
	broadcast_group_open(MemberList, Packet);
broadcast_group_open([], _Packet) -> ?ok.

%% 邮件给组内所有人
mail(Phase, Group, Packet) ->
	GroupList	= get_member_by_group(Phase, Group),
	mail_group(GroupList, Packet).
mail_group([Member|MemberList], Packet) ->
	UserName	= Member#ets_cross_arena_member.player_name,
	ServId		= Member#ets_cross_arena_member.sn,
	case center_api:get_serv_info(ServId) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			rpc:cast(misc:to_atom(Node), mail_api, send_system_mail_to_one2, [UserName, <<>>, <<>>, ?CONST_MAIL_CROSS_ARENA_GROUP, [], 
													  [], 0, 0, 0, ?CONST_COST_CROSS_ARENA_DAY]);
		_ ->
			?ok
	end,
	mail_group(MemberList, Packet);
mail_group([], _Packet) -> ?ok.

%% 每日零点更新ets清空积分 排名(每日前两名晋级 后两名降级)
refresh_daily_ets() ->
    try
		refresh_daily_reward(),
    	refresh_ets_phase(),
		refresh_ets_report(),
		?ok
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.

%% 刷ets_cross_arena_member
refresh_daily_reward() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_MEMBER) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_MEMBER, size),
			refresh_daily_reward(Key, [], 1, TotalSize),
            ?ok
	end.

refresh_daily_reward(Key, DelList, NowCount, TotalSize) ->
	NewDelList	= refresh_daily_reward_ext(Key, DelList),
	case ets:next(?CONST_ETS_CROSS_ARENA_MEMBER, Key) of
		'$end_of_table' ->
			lists:foreach(fun({UserId, Phase, Group}) -> delete_ets_by_id(UserId, Phase, Group) end, DelList),
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
			refresh_daily_reward(Key2, NewDelList, NewNowCount, TotalSize)
	end.

%% 刷新奖励(如果没领取则发邮件)
refresh_daily_reward_ext(Key, DelList) ->
	try
		case ets_api:lookup(?CONST_ETS_CROSS_ARENA_MEMBER, Key) of
			Member when is_record(Member, ets_cross_arena_member) ->
				Phase			= Member#ets_cross_arena_member.phase,
				Group			= Member#ets_cross_arena_member.group,
				Rank			= Member#ets_cross_arena_member.rank,
				UpdateTime		= Member#ets_cross_arena_member.update_time,
				Now				= misc:seconds(),
				PhaseList			= ets_api:list(?CONST_ETS_CROSS_ARENA_PHASE),
				MaxPhase			= length(PhaseList),
				case Now - UpdateTime > 72 * 3600 andalso MaxPhase =:= Phase andalso Phase > ?CONST_CROSS_ARENA_PHASE_SIX of
					?true -> %% 最后一段三天不玩的删除
						[{Key, Phase, Group}|DelList];
					?false ->
						LastWinTimes	= Member#ets_cross_arena_member.last_win_times,
						WinTimes		= Member#ets_cross_arena_member.win_times,
						ServId			= Member#ets_cross_arena_member.sn,
						case center_api:get_serv_info(ServId) of
							{Node, ?CONST_CENTER_STATE_NORMAL} ->
								get_achive(Key, Phase, Rank, Node),
								case LastWinTimes > 0 of
									?true ->
										mail_last_award(Key, Phase, LastWinTimes, Node);
									?false ->
										?ok
								end;
							_ ->
								?ok
						end,
						%% 发完奖励刷新每日的数据
						Member2			= Member#ets_cross_arena_member{last_win_times 	= WinTimes, 
																		last_phase		= Phase,
																		last_group		= Group,
																		last_rank		= Rank,
																		times			= ?CONST_CROSS_ARENA_ATTACK_TIMES,
																		win_times 		= 0, 
																		fail_times 		= 0, 
																		score			= 0,
																		fight_list 		= []},
						AchieveData 	= cross_arena_mod:refresh_achieve(Member2),
						Member3			= Member2#ets_cross_arena_member{achieve = AchieveData},
						update_member_ets(Member3),
						DelList
				end;
			_ ->
				DelList
		end
	catch
		Error:Reason ->
			?MSG_ERROR("Error ~p, Reason ~p, Strace ~p", [Error, Reason, erlang:get_stacktrace()])
	end.

%% 删除竞技数据接口
delete_ets_by_id(UserId, Phase, Group) ->
	PhaseInfo			= get_phase_info(Phase),
	GroupList			= PhaseInfo#cross_arena_phase.group_list,
	{Group, UserList} 	= lists:keyfind(Group, 1, GroupList),
	UserList2			= lists:keydelete(UserId, 1, UserList),
	GroupList2			= lists:keyreplace(Group, 1, GroupList, {Group, UserList2}),
	PhaseInfo2			= PhaseInfo#cross_arena_phase{group_list = GroupList2},
	update_phase_ets(PhaseInfo2),
	delete_member(UserId),
	delete_robot_by_id(UserId).

%% 删除竞技数据接口
delete_phase_info_by_id(UserId, Phase, Group) ->
    PhaseInfo           = get_phase_info(Phase),
    GroupList           = PhaseInfo#cross_arena_phase.group_list,
    {Group, UserList}   = lists:keyfind(Group, 1, GroupList),
    UserList2           = lists:keydelete(UserId, 1, UserList),
    GroupList2          = lists:keyreplace(Group, 1, GroupList, {Group, UserList2}),
    PhaseInfo2          = PhaseInfo#cross_arena_phase{group_list = GroupList2},
    update_phase_ets(PhaseInfo2).

delete_member(UserId) ->
	try
        ets_api:delete(?CONST_ETS_CROSS_ARENA_MEMBER, UserId),
        mysql_api:delete(<<"DELETE FROM `game_cross_arena_member` WHERE `player_id` = '",
                           (misc:to_binary(UserId))/binary, "';">>),
        ?ok
    catch
        throw:Return -> Return;
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

delete_phase(Phase) ->
	try
        ets_api:delete(?CONST_ETS_CROSS_ARENA_PHASE, Phase),
        mysql_api:delete(<<"DELETE FROM `game_cross_arena_phase` WHERE `phase` = '",
                           (misc:to_binary(Phase))/binary, "';">>),
        ?ok
    catch
        throw:Return -> Return;
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

delete_robot_by_id(UserId) ->
	try
        ets_api:delete(?CONST_ETS_CROSS_ARENA_ROBOT, UserId),
        mysql_api:delete(<<"DELETE FROM `game_cross_arena_robot` WHERE `player_id` = '",
                           (misc:to_binary(UserId))/binary, "';">>),
        ?ok
    catch
        throw:Return -> Return;
        Error:Reason ->
            ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

get_achive(UserId, Phase, Rank, Node) ->
	rpc:cast(misc:to_atom(Node), ?MODULE, get_achive_cb, [UserId, Phase, Rank]).

get_achive_cb(UserId, Phase, Rank) ->
	%% 称号
	case Phase =:= 1 andalso Rank =:= 1 of
		?true ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_CROSS_ARENA, Rank, 1);
		?false ->
			?ok
	end.
		
mail_last_award(UserId, Phase, LastWinTimes, Node) ->
	case data_cross_arena:get_cross_arena_reward({1, Phase, LastWinTimes}) of
		RecReward when is_record(RecReward, rec_cross_arena_reward) ->
%% 			?MSG_DEBUG("mail_last_award_0000000000000000000000000000000000000000000000000000000000:~p", [UserId]),
			rpc:cast(misc:to_atom(Node), ?MODULE, mail_last_award_cb, [UserId, Phase, LastWinTimes, RecReward]);
		_ ->
%% 			?MSG_DEBUG("mail_last_award_1111111111111111111111111111111111111111111111111111111111:~p", [UserId]),
			?ok
	end.

mail_last_award_cb(UserId, Phase, LastWinTimes, RecReward) ->
	case player_api:get_player_fields(UserId, [#player.info]) of
		{?ok, [Info]} ->
			ReceiveName = Info#info.user_name,
			Coin		= RecReward#rec_cross_arena_reward.coin,
			Meritorious = RecReward#rec_cross_arena_reward.meritorious,
			RewardMeri	= Meritorious,
			RewardCoin  = Coin,
			case player_api:check_online(UserId) of
				?true -> %% 在线则主动发送上上次的功勋和铜钱
					player_api:process_send(UserId, ?MODULE, daily_reward_cb, {RewardMeri, RewardCoin});
				?false -> %% 不在线把功勋存起来 等玩家登陆时发
					player_offline_api:offline(?MODULE, UserId, {RewardMeri, RewardCoin})
			end,
%% 			GoodsList	= get_reward_goods(RecReward#rec_cross_arena_reward.goods, []),
%% 			GoodsIdList	= mail_api:get_goods_id(GoodsList, []),
			PhaseList	= [{misc:to_list(Phase)}],
			WinTimesList	= [{misc:to_list(LastWinTimes)}],
			MeriList	= [{misc:to_list(RewardMeri)}],
			Content		= [{WinTimesList}] ++ [{MeriList}],
			MailId		= get_mail_id(Phase),
			mail_api:send_system_mail_to_one2(ReceiveName, <<>>, <<>>, MailId, Content, 
											  [], 0, 0, 0, ?CONST_COST_CROSS_ARENA_DAY);
		{?error, _ErrorCode} ->
			?ok
	end.

%% 根据段获取邮件id
get_mail_id(Phase) ->
	if Phase =:= 1 ->
		   2300;
	   Phase =:= 2 ->
		   2301;
	   Phase =:= 3 ->
		   2302;
	   Phase =:= 4 ->
		   2303;
	   Phase =:= 5 ->
		   2304;
	   Phase =:= 6 ->
		   2305;
	   ?true ->
		   2306
	end.
		

%% 上线捞取奖励
flush_offline(Player, {RewardMeri, RewardCoin}) ->
	daily_reward_cb(Player, {RewardMeri, RewardCoin});
flush_offline(Player, Data) ->
	?MSG_ERROR("UserId =:~p~n, Data =:~p~n", [Player#player.user_id, Data]),
	{?ok, Player}.

daily_reward_cb(Player, {RewardMeri, RewardCoin}) ->
	cross_arena_mod:reward_gold(Player#player.user_id, RewardCoin),
	cross_arena_mod:reward_meritorious(Player, RewardMeri).
	

get_reward_goods([{GoodsId, Bind, Count} | List], Acc) ->
	GoodsList 	= goods_api:make(GoodsId, Bind, Count),
	NewAcc		= Acc ++ GoodsList,
	get_reward_goods(List, NewAcc);
get_reward_goods([], Acc) -> Acc.
	
refresh_ets_phase() ->
	PhaseList	= ets_api:list(?CONST_ETS_CROSS_ARENA_PHASE),
	PhaseList2	= lists:sort(fun(Item1, Item2) -> 
									 Item1#cross_arena_phase.phase =< Item2#cross_arena_phase.phase 
							 end, PhaseList),
	MaxPhase	= length(PhaseList),
	case MaxPhase > 1 of
		?true ->
			refresh_ets_phase_ext(PhaseList2, [], MaxPhase);
		?false ->
			?ok
	end,
	%% 检测最后一段是否空 空则删除
	update_max_phase(MaxPhase),
	?ok.

%% 检测最后一段是否空 空则删除
update_max_phase(Phase) ->
	PhaseInfo 	= get_phase_info(Phase),
	GroupList	= PhaseInfo#cross_arena_phase.group_list,
	MemberList	= get_member_by_group(Phase, 1),
	case length(GroupList) =:= 1 andalso length(MemberList) =:= 0 of
		?true ->
			delete_phase(Phase);
		?false ->
			?ok
	end.
%% 
refresh_ets_phase_ext([#cross_arena_phase{phase = Phase} = PhaseInfo|PhaseList], DownInList, MaxPhase)  ->
	%% 入参 DownInList 为上段降级至本段的
	DownNum	= 
		case Phase - 1 < ?CONST_CROSS_ARENA_PHASE_SIX of
			?true ->
				?CONST_CROSS_ARENA_GROUP_DOWN_COUNT1;
			?false ->
				?CONST_CROSS_ARENA_GROUP_DOWN_COUNT2
		end,
	{PhaseInfo2, _UpList}		= get_up_down_list(PhaseInfo, 1, DownNum, 0), %% 本段晋级的
	NextPhase					= Phase + 1,
	UpInList				= 
		case get_phase_info(NextPhase) of
			NextPhaseInfo when is_record(NextPhaseInfo, cross_arena_phase) ->
%% 				?MSG_DEBUG("get_phase_info:~p",[NextPhaseInfo]),
				{_, TempUpInList} = get_up_down_list(NextPhaseInfo, 1, DownNum, 0), %% 下段晋级本段的
				TempUpInList;
			_ ->
				[]
		end,
	DownCount	= length(UpInList),
	{PhaseInfo3, DownList}		= get_up_down_list(PhaseInfo2, 0, DownNum, DownCount), %% 本段降级的
%% 	?MSG_DEBUG("refresh_ets_phase_ext000000000000000000000000000000000000:~p",[{PhaseInfo, PhaseInfo2, PhaseInfo3}]),
%% 	?MSG_DEBUG("refresh_ets_phase_ext111111111111111111111111111111111111:~p",[{Phase,UpList,DownList, UpInList, DownInList}]),
	update_phase(PhaseInfo3, UpInList, DownInList),
	broadcast_group_info(PhaseInfo3),
	refresh_ets_phase_ext(PhaseList, DownList, MaxPhase);
refresh_ets_phase_ext([], _, _MaxPhase) -> ?ok.

%% 获取晋级或者降级列表(段信息, 类型 1为上升 0为下降)
get_up_down_list(PhaseInfo, 1, _DownNum, _DownCount) 
  when PhaseInfo#cross_arena_phase.phase =:= 1 -> %% 天神一段不能往上晋级
	{PhaseInfo, []};
get_up_down_list(PhaseInfo, Type, DownNum, DownCount) ->
	GroupList	= PhaseInfo#cross_arena_phase.group_list,
%% 	DownRank	= 10 - DownNum,
	Fun	= fun({GroupId, UserList}, {List, Acc}) ->
				  Count	= length(Acc),
				  FrontList	= 
					  case Type of
						  ?CONST_SYS_TRUE -> %% 晋级列表取前两位
							  [{UserId, Rank}|| {UserId, Rank} <- UserList, Rank =< ?CONST_CROSS_ARENA_GROUP_UP_COUNT];
						  _ -> %% 获得降级列表
							  DownRank	= 
								  if DownCount - Count >= 4 ->
										 ?CONST_CROSS_ARENA_GROUP_COUNT - DownNum;
									 DownCount - Count > 0 andalso DownCount - Count < 4 ->
										 ?CONST_CROSS_ARENA_GROUP_COUNT - (DownCount - Count);
									 ?true ->
										 ?CONST_CROSS_ARENA_GROUP_COUNT
								  end,
							  [{UserId, Rank}|| {UserId, Rank} <- UserList, Rank > DownRank]
					  end,
				  Acc2			= misc:list_merge(FrontList, Acc),
				  UserList2		= lists:foldl(fun({Item1, _}, Acc1) -> 
													  lists:keydelete(Item1, 1, Acc1) 
											  end, UserList, FrontList),
				  List2			= lists:keyreplace(GroupId, 1, List, {GroupId, UserList2}),
				  {List2, Acc2}
		  end,
	{GroupList2, UpList}		= lists:foldl(Fun, {GroupList, []}, GroupList),
	PhaseInfo2	= PhaseInfo#cross_arena_phase{group_list = GroupList2},
%% 	update_phase_ets(PhaseInfo2),
	{PhaseInfo2, UpList}.
	
%% 更新段信息ets表
update_phase(#cross_arena_phase{phase = Phase} = PhaseInfo, UpInList, DownInList) when Phase < ?CONST_CROSS_ARENA_PHASE_SIX ->
	%% 6段以下重新分组
	ChangeList	= misc:list_merge(UpInList, DownInList),
	GroupList2	= reset_group(PhaseInfo, ChangeList),
%% 	?MSG_DEBUG("update_phase111111111111111111111111:~p",[{Phase,UpInList, DownInList}]),
	PhaseInfo2  = PhaseInfo#cross_arena_phase{group_list = GroupList2},
	update_phase_ets(PhaseInfo2);
update_phase(#cross_arena_phase{phase = Phase} = PhaseInfo, UpInList, DownInList) ->
	%% 6段以上不重新分组
	ChangeList	= misc:list_merge(UpInList, DownInList),
	GroupList	= PhaseInfo#cross_arena_phase.group_list,
	GroupList2	= insert_group(Phase, GroupList, ChangeList),
	PhaseInfo2  = PhaseInfo#cross_arena_phase{group_list = GroupList2},
	update_phase_ets(PhaseInfo2).

%% 刷新ets_cross_member表
update_member(Phase, Group, [{UserId, Rank} | UserList]) ->
	catch update_member(UserId, Phase, Group, Rank),
	update_member(Phase, Group, UserList);
update_member(_Phase, _Group, []) -> ?ok.

update_member(UserId, Phase, Group, Rank) ->
	Member		= get_arena_info_by_id(UserId),
	LastPhase	= Member#ets_cross_arena_member.last_phase,
	LastGroup	= Member#ets_cross_arena_member.last_group,
	LastRank	= Member#ets_cross_arena_member.last_rank,
	Member2		= Member#ets_cross_arena_member{phase 		= Phase, 
												group 		= Group, 
												rank 		= Rank,
												last_phase	= LastPhase,
												last_group	= LastGroup,
												last_rank	= LastRank},
	update_member_ets(Member2).

%% 插入组
insert_group(Phase, GroupList, [{UserId, _Rank} | UserList]) ->
	GroupList2 	= insert_group_ext(Phase, UserId, GroupList, GroupList),
	insert_group(Phase, GroupList2, UserList);
insert_group(_Phase, GroupList,  []) -> GroupList.
	

insert_group_ext(Phase, UserId, [{GroupId, UserList}|TailList], GroupList) ->
	case length(UserList) < ?CONST_CROSS_ARENA_GROUP_COUNT of
		?true ->
%% 			RankList	= [X || {_, X} <- UserList],
			IdList		= [X || {X, _} <- UserList],
			IdList2		= [UserId|IdList],
			IdList3 	= rank_sort(IdList2),
			UserList2 	= misc:get_list_index(IdList3),
%% 			Rank		= length(UserList) + 1,
%% 			UserList2 	= UserList ++ [{UserId, Rank}],
			GroupList2	= lists:keyreplace(GroupId, 1, GroupList, {GroupId, UserList2}),
			%% 刷新ets_cross_member 表
%% 			update_member(UserId, Phase, GroupId, Rank),
			update_member(Phase, GroupId, UserList2),
			GroupList2;
		?false ->
			insert_group_ext(Phase, UserId, TailList, GroupList)
	end;
insert_group_ext(_Phase, _UserId, [], GroupList) -> GroupList.
	
%% 在空排位中随机一个
%% get_empty_rank(RankList) ->
%% 	Num		= misc_random:random(1, 10),
%% 	case lists:member(Num, RankList) of
%% 		?true ->
%% 			get_empty_rank(RankList);
%% 		?false ->
%% 			Num
%% 	end.

%% 重新分组
reset_group(PhaseInfo, ChangeList) ->
	GroupList	= PhaseInfo#cross_arena_phase.group_list,
	Phase		= PhaseInfo#cross_arena_phase.phase,
	Fun	= fun({_GroupId, UserList}, Acc) ->
				  misc:list_merge(Acc, UserList)
		  end,
	List1		= lists:foldl(Fun, [], GroupList),
	List2		= misc:list_merge(List1, ChangeList),
	List3		= [X || {X, _Rank} <- List2],
%% 	?MSG_DEBUG("reset_group0000000000000000000000000:~p",[{Phase, GroupList,List1,List2,List2}]),
	reset_group(Phase, List3, 1, []).

reset_group(Phase, IdList, GroupId, Acc) when length(IdList) > ?CONST_CROSS_ARENA_GROUP_COUNT ->
	OneList		= misc_random:random_list_norepeat(IdList, ?CONST_CROSS_ARENA_GROUP_COUNT),
	NewIdList	= lists:foldl(fun(Item, ItemAcc) -> 
								  lists:delete(Item, ItemAcc)
						  end, IdList, OneList),
	OneList2 	= misc:get_list_index(OneList),
	OneGroup	= {GroupId, OneList2},
	%% 刷新ets_cross_member 表
	update_member(Phase, GroupId, OneList2),
%% 	?MSG_DEBUG("reset_group11111111111111111111111111:~p",[OneList2]),
	NewAcc		= [OneGroup|Acc],
	reset_group(Phase, NewIdList, GroupId + 1, NewAcc);
reset_group(Phase, IdList, GroupId, Acc) ->
	IdList2 	= rank_sort(IdList),
	OneList 	= misc:get_list_index(IdList2),
%% 	?MSG_DEBUG("reset_group22222222222222222222222222:~p",[OneList]),
	%% 刷新ets_cross_member 表
	update_member(Phase, GroupId, OneList),
	OneGroup	= {GroupId, OneList},
	[OneGroup|Acc].
	
%% 根据积分 战力排名
rank_sort(List) ->
	Fun			= fun(Item1, Item2) ->
						Member1		= get_arena_info_by_id(Item1),
						Member2		= get_arena_info_by_id(Item2),
						if 
							Member1#ets_cross_arena_member.score > Member2#ets_cross_arena_member.score ->
								?true;
							Member1#ets_cross_arena_member.score =:= Member2#ets_cross_arena_member.score
							  andalso Member1#ets_cross_arena_member.fight_force >= Member2#ets_cross_arena_member.fight_force ->
								?true;
							?true ->
								?false
						end
				  end,
	lists:sort(Fun, List).

%% 每日更新战报
refresh_ets_report() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_GROUP_REPORT),
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_REPORT),
	mysql_api:execute(<<"TRUNCATE TABLE `game_cross_arena_group_report`;">>),
	mysql_api:execute(<<"TRUNCATE TABLE `game_cross_arena_report`;">>).

%% 0点更新时把组内信息广播给打开界面的人
broadcast_group_info(PhaseInfo) ->
	Phase		= PhaseInfo#cross_arena_phase.phase,
	GroupList 	= PhaseInfo#cross_arena_phase.group_list,
	List		= [{Phase, GroupId} || {GroupId, _} <- GroupList],
	broadcast_group_info_ext(List).
broadcast_group_info_ext([{Phase, Group}|TailList]) ->
	GroupList	= get_member_by_group(Phase, Group),
	broadcast_group_info_ext2(GroupList),
	broadcast_group_info_ext(TailList);
broadcast_group_info_ext([]) -> ?ok.
	
broadcast_group_info_ext2([Member|MemberList]) ->
	UserId		= Member#ets_cross_arena_member.player_id,
	ServId		= Member#ets_cross_arena_member.sn,
	Phase		= Member#ets_cross_arena_member.phase,
	Group		= Member#ets_cross_arena_member.group,
	case center_api:get_serv_info(ServId) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			OpenFlag		= Member#ets_cross_arena_member.open_flag,
			[_, DefList] 	= cross_arena_mod:get_deffender_list(UserId),
			Packet1			= cross_arena_api:msg_enter_arena(0, Member, []),
			Packet2			= cross_arena_api:msg_group_info(1, Phase, Group, DefList),
			Packet3		= <<Packet1/binary, Packet2/binary>>,
			case OpenFlag of
				1 ->
					rpc:cast(misc:to_atom(Node), misc_packet, send, [UserId, Packet3]);
				_ ->
					?ok
			end;
		_ ->
			?ok
	end,
	broadcast_group_info_ext2(MemberList);
broadcast_group_info_ext2([]) -> ?ok.	
	
	
%% 回写ETS数据到数据库
refresh_daily_db() ->
    try
    	refresh_daily_member(),
		refresh_daily_phase(),
		refresh_daily_report(),
		refresh_daily_group_report(),
		refresh_daily_robot()
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.

%% 刷ets_cross_arena_member
refresh_daily_member() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_MEMBER) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_MEMBER, size),
			refresh_daily_member(Key, 1, TotalSize),
            ?ok
	end.

refresh_daily_member(Key, NowCount, TotalSize) ->
	case ets:next(?CONST_ETS_CROSS_ARENA_MEMBER, Key) of
		'$end_of_table' ->
            refresh_arena_member_db(Key, NowCount, TotalSize),
			?ok;
		Key2 ->
            refresh_arena_member_db(Key, NowCount, TotalSize),
            NewNowCount = NowCount + 1,
			refresh_daily_member(Key2, NewNowCount, TotalSize)
	end.

refresh_arena_member_db(Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_CROSS_ARENA_MEMBER, Key) of
		Member when is_record(Member, ets_cross_arena_member) ->
			case check_old_member(Member) of
				?false -> %% 无效的删除
                    case find_real_postion(Key) of
                        false ->
                            delete_member(Key);
                        {NPhase, NGroup, NRank} ->
                            NewMember = Member#ets_cross_arena_member{phase = NPhase, group = NGroup, rank = NRank},
                            update_member_ets(NewMember),
                            ?MSG_ERROR("real postion is ~w", [{NPhase, NGroup, NRank}])
                    end;
				?true ->
					
					try
						EncodePartner   = misc:encode(Member#ets_cross_arena_member.partner_list),
						EncodeAchieve	= misc:encode(Member#ets_cross_arena_member.achieve),
						EncodeFightList	= misc:encode(Member#ets_cross_arena_member.fight_list),
						EncodePlayerData	= 
							case is_record(Member#ets_cross_arena_member.player_data, player) of
								?true ->
									mysql_api:encode(Member#ets_cross_arena_member.player_data);
								?false ->
									mysql_api:encode(?undefined)
							end,
						EncodePlayerData2	= 
							case is_record(Member#ets_cross_arena_member.player_data2, player) of
								?true ->
									mysql_api:encode(Member#ets_cross_arena_member.player_data2);
								?false ->
									mysql_api:encode(?undefined)
							end,
						EncodePlayerData3	=
							case is_record(Member#ets_cross_arena_member.player_data3, player) of
								?true ->
									mysql_api:encode(Member#ets_cross_arena_member.player_data3);
								?false ->
									mysql_api:encode(?undefined)
							end,
						Result = mysql_api:insert_execute(<<"INSERT INTO `game_cross_arena_member` ",
															"(`player_id`, `player_name`, `player_sex`, `player_lv`, `player_career`,",
															" `last_rank`, `last_phase`,  `last_group`, `rank`, `phase`, `group`, ",
															" `times`, `last_win_times`, `win_times`, `fail_times`, `fight_force`, `partner_list`,"
															" `open_flag`, `on_line_flag`, `plat_form`, `sn`, `node`, `achieve`, `score`, ",
															" `fight_list`, `player_data`, `player_data2`,  `player_data3`, `update_time`)",
															" VALUES (",
															" '", (misc:to_binary(Member#ets_cross_arena_member.player_id))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.player_name))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.player_sex))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.player_lv))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.player_career))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.last_rank))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.last_phase))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.last_group))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.rank))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.phase))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.group))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.times))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.last_win_times))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.win_times))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.fail_times))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.fight_force))/binary, "',",
															" '", (misc:to_binary(EncodePartner))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.open_flag))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.on_line_flag))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.platform))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.sn))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.node))/binary, "',",
															" '", (misc:to_binary(EncodeAchieve))/binary, "',",
															" '", (misc:to_binary(Member#ets_cross_arena_member.score))/binary, "',",
															" '", (misc:to_binary(EncodeFightList))/binary, "',",
															" ", EncodePlayerData/binary, ",",
															" ", EncodePlayerData2/binary, ",",
															" ", EncodePlayerData3/binary, ",",
															" '", (misc:to_binary(Member#ets_cross_arena_member.update_time))/binary, "') ",
															" ON DUPLICATE KEY UPDATE `player_id` = '", (misc:to_binary(Member#ets_cross_arena_member.player_id))/binary, "',",
															" `player_name` = '", (misc:to_binary(Member#ets_cross_arena_member.player_name))/binary, "',",
															" `player_sex` = '", (misc:to_binary(Member#ets_cross_arena_member.player_sex))/binary, "',",
															" `player_lv` = '", (misc:to_binary(Member#ets_cross_arena_member.player_lv))/binary, "',",
															" `player_career` = '", (misc:to_binary(Member#ets_cross_arena_member.player_career))/binary, "',",
															" `last_rank` = '", (misc:to_binary(Member#ets_cross_arena_member.last_rank))/binary, "',",
															" `last_phase` = '", (misc:to_binary(Member#ets_cross_arena_member.last_phase))/binary, "',",
															" `last_group` = '", (misc:to_binary(Member#ets_cross_arena_member.last_group))/binary, "',",
															" `rank` = '", (misc:to_binary(Member#ets_cross_arena_member.rank))/binary, "',",
															" `phase` = '", (misc:to_binary(Member#ets_cross_arena_member.phase))/binary, "',",
															" `group` = '", (misc:to_binary(Member#ets_cross_arena_member.group))/binary, "',",
															" `times` = '", (misc:to_binary(Member#ets_cross_arena_member.times))/binary, "',",
															" `last_win_times` = '", (misc:to_binary(Member#ets_cross_arena_member.last_win_times))/binary, "',",
															" `win_times` = '", (misc:to_binary(Member#ets_cross_arena_member.win_times))/binary, "',",
															" `fight_force` = '", (misc:to_binary(Member#ets_cross_arena_member.fight_force))/binary, "',",
															" `partner_list` = '", (EncodePartner)/binary, "',",
															" `on_line_flag` = '", (misc:to_binary(Member#ets_cross_arena_member.on_line_flag))/binary, "',",
															" `open_flag` = '", (misc:to_binary(Member#ets_cross_arena_member.open_flag))/binary, "',",
															" `plat_form` = '", (misc:to_binary(Member#ets_cross_arena_member.platform))/binary, "',",
															" `sn` = '", (misc:to_binary(Member#ets_cross_arena_member.sn))/binary, "',",
															" `node` = '", (misc:to_binary(Member#ets_cross_arena_member.node))/binary, "',",
															" `achieve` = '", (misc:to_binary(EncodeAchieve))/binary, "',",
															" `score` = '", (misc:to_binary(Member#ets_cross_arena_member.score))/binary, "',",
															" `fight_list` = '", (misc:to_binary(EncodeFightList))/binary, "',",
															" `player_data` = ", EncodePlayerData/binary, ",",
															" `player_data2` = ", EncodePlayerData2/binary, ",",
															" `player_data3` = ", EncodePlayerData3/binary, ",",
															" `update_time` = '", (misc:to_binary(Member#ets_cross_arena_member.update_time))/binary, "';">>),
						if
							{?error, []} =/= Result ->
								?ok;
							?true ->
								?ok
						end
					catch
						X:Y ->
							?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
							?ok
					end
			end;
		X ->
            ?MSG_ERROR("1[~p]", [X]),
			?ok
	end.


find_real_postion1(_UserId, []) ->
    false;
find_real_postion1(UserId, [Phase|RestList]) ->
    GroupList = Phase#cross_arena_phase.group_list,
    Fun1 =
        fun({_GroupId, UserList}) ->
                case lists:keyfind(UserId, 1, UserList) of
                    false ->
                        false;
                    _ ->
                        true
                end
        end,
    case lists:filter(Fun1, GroupList) of
        [{GroupId, RealList}|_] ->
            {_, Rank}= lists:keyfind(UserId, 1, RealList),
            {Phase#cross_arena_phase.phase, GroupId, Rank};
        _ ->
            find_real_postion1(UserId, RestList)
    end.

find_real_postion(UserId) ->
    PhaseList = ets:tab2list(?CONST_ETS_CROSS_ARENA_PHASE),
    find_real_postion1(UserId, PhaseList).

                
                

%% 检查旧的member数据是否需要有效
check_old_member(Member) ->
	UserId	= Member#ets_cross_arena_member.player_id,
	Phase	= Member#ets_cross_arena_member.phase,
	Group	= Member#ets_cross_arena_member.group,
	case ets:lookup(?CONST_ETS_CROSS_ARENA_PHASE, Phase) of
		[] ->
			?false;
		[PhaseInfo] ->
			GroupList = PhaseInfo#cross_arena_phase.group_list,
			case lists:keyfind(Group, 1, GroupList) of
				{Group, UserList} ->
					case lists:keyfind(UserId, 1, UserList) of
						{_UserId, _Rank} ->
							?true;
						_ ->
							?false
					end;
				_ ->
					?false
			end
	end.

%% 刷cross_arena_phase
refresh_daily_phase() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_PHASE) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_PHASE, size),
			refresh_daily_phase(Key, 1, TotalSize),
            ?ok
	end.

refresh_daily_phase(Key, NowCount, TotalSize) ->
	refresh_daily_phase_db(Key, NowCount, TotalSize),
	case ets:next(?CONST_ETS_CROSS_ARENA_PHASE, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
			refresh_daily_phase(Key2, NewNowCount, TotalSize)
	end.

refresh_daily_phase_db(Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_CROSS_ARENA_PHASE, Key) of
		PhaseInfo when is_record(PhaseInfo, cross_arena_phase) ->
            try
				EncodeGroupList   = misc:encode(PhaseInfo#cross_arena_phase.group_list),
    			Result = mysql_api:insert_execute(<<"INSERT INTO `game_cross_arena_phase` ",
    									   "(`phase`, `group_list`)",
    									   " VALUES (",
    									   " '", (misc:to_binary(PhaseInfo#cross_arena_phase.phase))/binary, "',",
										   " '", (misc:to_binary(EncodeGroupList))/binary, "') ",
    									   " ON DUPLICATE KEY UPDATE `phase` = '", (misc:to_binary(PhaseInfo#cross_arena_phase.phase))/binary, "',",
    									   " `group_list` = '", (misc:to_binary(EncodeGroupList))/binary, "';">>),
    			if
                    {?error, []} =/= Result ->
                        ?ok;
                    ?true ->
                        ?ok
                end
            catch
                X:Y ->
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
                    ?ok
            end;
		X ->
            ?MSG_ERROR("1[~p]", [X]),
			?ok
	end.

%% 刷cross_arena_report
refresh_daily_report() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_REPORT) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_REPORT, size),
			refresh_daily_report(Key, 1, TotalSize),
            ?ok
	end.

refresh_daily_report(Key, NowCount, TotalSize) ->
	refresh_daily_report_db(Key, NowCount, TotalSize),
	case ets:next(?CONST_ETS_CROSS_ARENA_REPORT, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
			refresh_daily_report(Key2, NewNowCount, TotalSize)
	end.

refresh_daily_report_db(Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_CROSS_ARENA_REPORT, Key) of
		Report when is_record(Report, cross_arena_report) ->
            try
				EncodeReport   = misc:encode(Report#cross_arena_report.bin_report),
    			Result = mysql_api:insert_execute(<<"INSERT INTO `game_cross_arena_report` ",
    									   "(`id`, `result`, `time`, `attack_id`, `attack_name`, `deffender_id`, `deffender_name`, `bin_report`)",
    									   " VALUES (",
    									   " '", (misc:to_binary(Report#cross_arena_report.id))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.result))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.time))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.attack_id))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.attack_name))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.deffender_id))/binary, "',",
										   " '", (misc:to_binary(Report#cross_arena_report.deffender_name))/binary, "',",
										   " '", (misc:to_binary(EncodeReport))/binary, "') ",
    									   " ON DUPLICATE KEY UPDATE `id` = '", (misc:to_binary(Report#cross_arena_report.id))/binary, "',",
										   " `result` = '", (misc:to_binary(Report#cross_arena_report.result))/binary, "',",
										   " `time` = '", (misc:to_binary(Report#cross_arena_report.time))/binary, "',",
										   " `attack_id` = '", (misc:to_binary(Report#cross_arena_report.attack_id))/binary, "',",
										   " `attack_name` = '", (misc:to_binary(Report#cross_arena_report.attack_name))/binary, "',",
										   " `deffender_id` = '", (misc:to_binary(Report#cross_arena_report.deffender_id))/binary, "',",
										   " `deffender_name` = '", (misc:to_binary(Report#cross_arena_report.deffender_name))/binary, "',",
    									   " `bin_report` = '", (misc:to_binary(EncodeReport))/binary, "';">>),
    			if
                    {?error, []} =/= Result ->
                        ?ok;
                    ?true ->
                        ?ok
                end
            catch
                X:Y ->
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
                    ?ok
            end;
		X ->
            ?MSG_ERROR("1[~p]", [X]),
			?ok
	end.


%% 刷cross_arena_group_report
refresh_daily_group_report() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_GROUP_REPORT) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, size),
			refresh_daily_group_report(Key, 1, TotalSize),
            ?ok
	end.

refresh_daily_group_report(Key, NowCount, TotalSize) ->
	refresh_daily_group_report_db(Key, NowCount, TotalSize),
	case ets:next(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
			refresh_daily_group_report(Key2, NewNowCount, TotalSize)
	end.

refresh_daily_group_report_db(Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, Key) of
		GroupReport when is_record(GroupReport, cross_arena_group_report) ->
            try
				EncodeReportList   = misc:encode(GroupReport#cross_arena_group_report.report_list),
    			Result = mysql_api:insert_execute(<<"INSERT INTO `game_cross_arena_group_report` ",
    									   "(`phase_group`, `report_list`)",
    									   " VALUES (",
    									   " '", (misc:to_binary(GroupReport#cross_arena_group_report.phase_group))/binary, "',",
										   " '", (misc:to_binary(EncodeReportList))/binary, "') ",
    									   " ON DUPLICATE KEY UPDATE `phase_group` = '", (misc:to_binary(GroupReport#cross_arena_group_report.phase_group))/binary, "',",
    									   " `report_list` = '", (misc:to_binary(EncodeReportList))/binary, "';">>),
    			if
                    {?error, []} =/= Result ->
                        ?ok;
                    ?true ->
                        ?ok
                end
            catch
                X:Y ->
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
                    ?ok
            end;
		X ->
			?ok
	end.

%% 刷cross_arena_robot
refresh_daily_robot() ->
	case ets:first(?CONST_ETS_CROSS_ARENA_ROBOT) of
		'$end_of_table' ->
			?ok;
		Key ->
            TotalSize = ets:info(?CONST_ETS_CROSS_ARENA_ROBOT, size),
			refresh_daily_robot(Key, 1, TotalSize),
            ?ok
	end.

refresh_daily_robot(Key, NowCount, TotalSize) ->
	refresh_daily_robot_db(Key, NowCount, TotalSize),
	case ets:next(?CONST_ETS_CROSS_ARENA_ROBOT, Key) of
		'$end_of_table' ->
			?ok;
		Key2 ->
            NewNowCount = NowCount + 1,
			refresh_daily_robot(Key2, NewNowCount, TotalSize)
	end.

refresh_daily_robot_db(Key, _NowCount, _TotalSize) ->
	case ets_api:lookup(?CONST_ETS_CROSS_ARENA_ROBOT, Key) of
		Robot when is_record(Robot, cross_arena_robot_member) ->
            try
				EncodeFightList   = misc:encode(Robot#cross_arena_robot_member.fight_list),
    			Result = mysql_api:insert_execute(<<"INSERT INTO `game_cross_arena_robot` ",
    									   "(`player_id`, `fight_list`)",
    									   " VALUES (",
    									   " '", (misc:to_binary(Robot#cross_arena_robot_member.player_id))/binary, "',",
										   " '", (misc:to_binary(EncodeFightList))/binary, "') ",
    									   " ON DUPLICATE KEY UPDATE `player_id` = '", (misc:to_binary(Robot#cross_arena_robot_member.player_id))/binary, "',",
    									   " `fight_list` = '", (misc:to_binary(EncodeFightList))/binary, "';">>),
    			if
                    {?error, []} =/= Result ->
                        ?ok;
                    ?true ->
                        ?ok
                end
            catch
                X:Y ->
                    ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
                    ?ok
            end;
		X ->
            ?MSG_ERROR("1[~p]", [X]),
			?ok
	end.

init_cross_arena_member()->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_MEMBER),
	F = fun(Member)->
				MemberInfo 		= list_to_tuple([ets_cross_arena_member | Member]),
				DecodePartner 	= misc:decode(MemberInfo#ets_cross_arena_member.partner_list),
				DecodeAchieve 	= misc:decode(MemberInfo#ets_cross_arena_member.achieve),
				DecodeFightList = misc:decode(MemberInfo#ets_cross_arena_member.fight_list),
				
				DecodePlayerData = mysql_api:decode(MemberInfo#ets_cross_arena_member.player_data),
				DecodePlayerData2 = mysql_api:decode(MemberInfo#ets_cross_arena_member.player_data2),
				DecodePlayerData3 = mysql_api:decode(MemberInfo#ets_cross_arena_member.player_data3),
				PartnerList		= misc:to_list(DecodePartner),
				Achieve			= misc:to_list(DecodeAchieve),
				FightList		= misc:to_list(DecodeFightList),
				MemberInfo2		= MemberInfo#ets_cross_arena_member{partner_list = PartnerList, 
																	achieve = Achieve,
																	fight_list = FightList,
																	player_data = DecodePlayerData,
																	player_data2 = DecodePlayerData2,
																	player_data3 = DecodePlayerData3},
				ets:insert(?CONST_ETS_CROSS_ARENA_MEMBER, MemberInfo2)
		end,
	{?ok, MemberList} = mysql_api:select("select * from game_cross_arena_member"),
	lists:foreach(F, MemberList),
	?ok.

init_cross_arena_phase() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_PHASE),
	F = fun(TuplePhase)->
				PhaseInfo 		= list_to_tuple([cross_arena_phase | TuplePhase]),
				DecodeGroupList = misc:decode(PhaseInfo#cross_arena_phase.group_list),
				GroupList		= misc:to_list(DecodeGroupList),
				PhaseInfo2		= PhaseInfo#cross_arena_phase{
															  group_list = GroupList
															},
				ets:insert(?CONST_ETS_CROSS_ARENA_PHASE, PhaseInfo2)
		end,
	{?ok, PhaseList} = mysql_api:select("select * from game_cross_arena_phase"),
	lists:foreach(F, PhaseList),
	?ok.

init_cross_arena_report() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_REPORT),
	F = fun(TupleReport)->
				Report	 		= list_to_tuple([cross_arena_report | TupleReport]),
				DecodeBinReport = misc:decode(Report#cross_arena_report.bin_report),
				BinReport		= misc:to_list(DecodeBinReport),
				Report2			= Report#cross_arena_report{
															  bin_report = BinReport
															},
				ets:insert(?CONST_ETS_CROSS_ARENA_REPORT, Report2)
		end,
	{?ok, ReportList} = mysql_api:select("select * from game_cross_arena_report"),
	lists:foreach(F, ReportList),
	?ok.

init_cross_arena_group_report() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_GROUP_REPORT),
	F = fun(TupleGroupReport)->
				GroupReport		= list_to_tuple([cross_arena_group_report | TupleGroupReport]),
				DecodeReportList = misc:decode(GroupReport#cross_arena_group_report.report_list),
				ReportList		= misc:to_list(DecodeReportList),
				GroupReport2		= GroupReport#cross_arena_group_report{
															  report_list = ReportList
															},
				ets:insert(?CONST_ETS_CROSS_ARENA_GROUP_REPORT, GroupReport2)
		end,
	{?ok, GroupReportList} = mysql_api:select("select * from game_cross_arena_group_report"),
	lists:foreach(F, GroupReportList),
	?ok.

init_cross_arena_robot() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_ROBOT),
	F = fun(TupleRobot)->
				Robot		= list_to_tuple([cross_arena_robot_member | TupleRobot]),
				DecodeFightList = misc:decode(Robot#cross_arena_robot_member.fight_list),
				FightList		= misc:to_list(DecodeFightList),
				RobotMember		= Robot#cross_arena_robot_member{
															  fight_list = FightList
															},
				ets:insert(?CONST_ETS_CROSS_ARENA_ROBOT, RobotMember)
		end,
	{?ok, GroupReportList} = mysql_api:select("select * from game_cross_arena_robot"),
	lists:foreach(F, GroupReportList),
	?ok.

%% 第一次初始化数据
init_clean_center_ets() ->
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_MEMBER),
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_PHASE),
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_REPORT),
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_GROUP_REPORT),
	ets:delete_all_objects(?CONST_ETS_CROSS_ARENA_ROBOT),
	?ok.

%% 获取下次领取奖励时间（每天0:00pm）
get_next_reward_time(Member) ->
	LastWinTimes	= Member#ets_cross_arena_member.last_win_times,
	if	
		LastWinTimes > 0 ->
			{?CONST_SYS_TRUE, get_next_reward_time()};
		?true ->
			{?CONST_SYS_FALSE, get_next_reward_time()}
	end.

get_next_reward_time() ->
	{Hour, Min, Second} = misc:time(),
	case (Hour >= 24) of
		?true ->
			TodaySeconds = ?CONST_SYS_ONE_DAY_SECONDS - calendar:time_to_seconds({Hour, Min, Second}),
			NextSeconds = calendar:time_to_seconds({23, 59, 59}),
			TodaySeconds + NextSeconds;
		?false ->
			calendar:time_to_seconds({23, 59, 59}) - calendar:time_to_seconds({Hour, Min, Second})
	end.

%% 检查是否结束
check_is_over() ->
	{Hour, Min, Second} = misc:time(),
	Seconds		= calendar:time_to_seconds({Hour, Min, Second}),
	MaxSeconds	= calendar:time_to_seconds({23, 59, 59}),
	MinSeconds 	= calendar:time_to_seconds({23, 40, 0}),
	if
		Seconds >= MinSeconds andalso Seconds =< MaxSeconds  ->
			?true;
		?true ->
			?false
	end.

%% 拆分playerdata
record_player_data1(#player{user_id      = UserId,
						   serv_id		= ServId,
						   user_state   = UserState,
						   play_state   = PlayState,
						   team_id		= TeamId,
						   info         = Info,
						   attr_sum     = AttrSum,
						   buff         = Buff,
						   attr         = Attr,
						   equip        = Equip
                           }) ->
    #player{user_id			= UserId,
			serv_id			= ServId,
			user_state		= UserState,
			play_state		= PlayState,
			team_id			= TeamId,
			info			= Info,
			attr_sum		= AttrSum,
			buff            = Buff,     
			attr            = Attr,
			equip           = Equip
		   };
record_player_data1(X) -> ?MSG_ERROR("bad data1=~p", [X]).

record_player_data2(#player{
						   skill        = Skill,   
						   camp         = Camp,
						   position     = Position,
						   partner      = Partner,
						   guild        = Guild,
						   mind         = Mind
                           }) ->
    #player{
			skill           = Skill,   
			camp            = Camp,
			position        = Position,    
			partner         = Partner,
			guild           = Guild,
			mind            = Mind
		   };
record_player_data2(X) -> ?MSG_ERROR("bad data2=~p", [X]).

record_player_data3(#player{
						   train		= Train,
						   sys_rank     = Sys,
                           style        = Style,
                           maps         = MapData,
                           horse        = HorseData,
						   lookfor		= LookforData,
						   weapon		= WeaponData
                           }) ->
    #player{
			train			= Train,
			sys_rank		= Sys,
            style           = Style,
            maps            = MapData,
            horse           = HorseData,
			lookfor			= LookforData,
			weapon			= WeaponData
		   };
record_player_data3(X) -> ?MSG_ERROR("bad data3=~p", [X]).

%% 组装player_data
get_player_data(UserId) ->
	Member 		= get_arena_info_by_id(UserId),
	PlayerData1	= Member#ets_cross_arena_member.player_data,
	PlayerData2	= Member#ets_cross_arena_member.player_data2,
	PlayerData3	= Member#ets_cross_arena_member.player_data3,
	record_player_data(PlayerData1, PlayerData2, PlayerData3).

record_player_data(#player{user_id      = UserId,
						   serv_id		= ServId,
						   user_state   = UserState,
						   play_state   = PlayState,
						   team_id		= TeamId,
						   info         = Info,
						   attr_sum     = AttrSum,
						   buff         = Buff,
						   attr         = Attr,
						   equip        = Equip}, 
				   #player{
						   skill        = Skill,   
						   camp         = Camp,
						   position     = Position,
						   partner      = Partner,
						   guild        = Guild,
						   mind         = Mind
                           }, 
				  #player{
							train			= Train,
							sys_rank		= Sys,
				            style           = Style,
				            maps            = MapData,
				            horse           = HorseData,
							lookfor			= LookforData,
							weapon			= WeaponData
						   }) ->
	#player{user_id			= UserId,
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
			train			= Train,
			sys_rank		= Sys,
            style           = Style,
            maps            = MapData,
            horse           = HorseData,
			lookfor			= LookforData,
			weapon			= WeaponData
		   };
record_player_data(X1, X2, X3) -> ?MSG_ERROR("bad data1=~p, data2 =~p, data3 = ~p", [X1, X2, X3]).
	

%% 处理出现空组问题(热处理问题时调用)
deal_empty_group(Phase, [GroupId|TailList]) ->
	List				= get_list_by_phase_group(Phase, GroupId),
	PhaseInfo			= get_phase_info(Phase),
	GroupList			= PhaseInfo#cross_arena_phase.group_list,
	GroupList2			= lists:keyreplace(GroupId, 1, GroupList, {GroupId, List}),
	PhaseInfo2			= PhaseInfo#cross_arena_phase{group_list = GroupList2},
	update_phase_ets(PhaseInfo2),
	deal_empty_group(Phase, TailList);
deal_empty_group(_Phase, []) -> ?ok.	

%% 热处理问题时调用
get_list_by_phase_group(Phase, GroupId) ->
	MS = ets:fun2ms(fun(T) when T#ets_cross_arena_member.phase =:= Phase andalso T#ets_cross_arena_member.group =:= GroupId -> {T#ets_cross_arena_member.player_id, T#ets_cross_arena_member.rank} end),
	ets:select(?CONST_ETS_CROSS_ARENA_MEMBER, MS).
 %%
%% Local Functions
%%

