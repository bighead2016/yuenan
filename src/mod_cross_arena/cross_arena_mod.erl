%% Author: Administrator
%% Created: 2013-12-16
%% Description: TODO: Add description to cross_arena_mod
-module(cross_arena_mod).

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
-export([enter/2, start_battle/4, deal_with_rank/4, get_phase/1,
		 change_ui_state/2, god_phase_info/1, achieve_info/1, 
		 get_achieve_reward/2, buy/3, change_ui_state_init/2,
		 cross_player_info/4, cross_partner_info/5, cross_partner/4,
		 get_myself_info/1, get_deffender_list/1, get_cross_player/1,
		 get_day_reward/1, reward_meritorious/2, reward_gold/2, rank_sort/1
		 ]).

-export([update_member_ets/1, insert_member_ets/1, get_arena_info_by_id/1, 
		 get_phase_info/1, get_phase_group/1, 
		 get_report/1, get_group_report/2, get_robot/1, delete_robot_by_id/1,
		 init_clean_center_ets/0,
		 get_next_reward_time/1,
		 update_phase_ets/1, update_report_ets/1, 
		 update_group_report_ets/1, update_robot_ets/1, update_player_data/2]).

-export([update_partner/3, update_power/2, get_report_by_id/1, refresh_achieve/1]).

%% -compile(export_all).
%%
%% API Functions
%%
%% 进入竞技场
enter(Player = #player{user_id = UserId, info = Info, serv_id = ServId}, Type) ->
	try
		case Type of
			1 ->
				#info{user_name = UserName, sex = Sex, pro = Pro, lv = Lv} = Info,
				Power		= partner_api:caculate_camp_power(UserId),
				OutPartner	= partner_api:get_out_partner(Player),
				OutIdList	= [X#partner.partner_id||X <- OutPartner],
				case get_arena_info_by_id(UserId) of
					CrossMember when is_record(CrossMember, ets_cross_arena_member) ->
						Result 					= change_ui_state(UserId, {UserName, Sex, Pro, Lv, ServId, Power, OutIdList, Type}), %% 打开竞技场界面
						[_, Member] 			= get_myself_info(UserId), 				%% 获取个人的竞技场信息  涉及到隔日更新
						[_, DefList] 			= get_deffender_list(UserId), 				%% 获取可以挑战的玩家列表
						Phase					= Member#ets_cross_arena_member.phase,
						Group					= Member#ets_cross_arena_member.group,
						[_, ReportList] 		= get_report_list(Phase, Group), 				%% 获取玩家战报
						Packet1					= cross_arena_api:msg_enter_arena(Result, Member, ReportList),
						Packet2					= cross_arena_api:msg_group_info(1, Phase, Group, DefList),
						AchieveData2 			= refresh_achieve(Member),
						Packet3					= cross_arena_api:msg_achieve_info(AchieveData2),
						misc_packet:send(UserId, <<Packet1/binary, Packet2/binary, Packet3/binary>>),
						Info2					= Info#info{cross_arena_flag = 1},
						Player2					= Player#player{info = Info2},
						Member2					= Member#ets_cross_arena_member{achieve = AchieveData2},
						update_player_data(Player2, Member2), %% 更新跨服玩家数据
						{?ok, Player2};
					_ ->
						{Result, Rank, IsNew} 	= cross_arena_robot_api:change_ui_state(UserId, Info),      %% 打开竞技场界面
						Packet = 
							if
				                ?CONST_SYS_TRUE =:= IsNew ->
									Member      = cross_arena_robot_api:get_myself_info(UserId, Info, OutIdList, Rank),    %% 获取个人的竞技场信息  涉及到隔日更新   
									DefList     = cross_arena_robot_api:get_deffender_list(),             %% 获取可以挑战的玩家列表 
									cross_arena_robot_api:msg_sc_enter_arena(Result, Member, DefList, []); %%进入竞技场的协议
								?true ->
									[_, Member] 		= get_myself_info(UserId), 				%% 获取个人的竞技场信息  涉及到隔日更新
									[_, DefList] 		= get_deffender_list(UserId), 				%% 获取可以挑战的玩家列表
									Phase				= Member#ets_cross_arena_member.phase,
									Group				= Member#ets_cross_arena_member.group,
									[_, ReportList] 	= get_report_list(Phase, Group), 				%% 获取玩家战报
									P1					= cross_arena_api:msg_enter_arena(Result, Member, ReportList),
									P2					= cross_arena_api:msg_group_info(1, Phase, Group, DefList),
									<<P1/binary, P2/binary>>
							end,
						misc_packet:send(UserId, Packet),
						{?ok, Player}
				end;
			2 ->
				case get_arena_info_by_id(UserId) of
					Member when is_record(Member, ets_cross_arena_member) ->
						Member2					= Member#ets_cross_arena_member{open_flag = Type},
						update_member_ets(Member2);
					_ ->
						?ok
				end,
				{?ok, Player}
		end
	catch
        X:Y ->
            ?MSG_ERROR("enter cross arena ~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.
			

%% 打开竞技场界面
change_ui_state(PlayerId, {NickName, Sex, Career, Lv, Sn, Power, PartnerList, Type}) ->
	Member = get_arena_info_by_id(PlayerId),
	change_ui_state(Member, PlayerId, {NickName, Sex, Career, Lv, Sn,  Power, PartnerList, Type}), %% 更新人物信息
	?CONST_CROSS_ARENA_OK.

%% 首次进入竞技场
change_ui_state([], PlayerId, {NickName, Sex, Career, Lv, Sn, Power, PartnerList, Type}) ->
	{PhaseId, GroupId, Rank, PhaseInfo}	= get_phase_group(PlayerId),
	update_phase_ets(PhaseInfo),
	Platform	= config:read(server_info, #rec_server_info.platform),
%% 	{Node, _} 	= center_api:get_serv_info(Sn),
	{Y, M, D}   = misc:date_tuple(),
	UpdateTime	= misc:date_time_to_stamp({Y, M, D, 0, 0, 0}),
	Member = #ets_cross_arena_member
				  {player_id 	= PlayerId,
				   player_name 	= NickName,
				   player_sex 	= Sex,
				   player_career = Career,
				   player_lv 	= Lv,
				   platform		= Platform,
				   sn 			= Sn,
%% 				   node			= Node,
				   phase		= PhaseId,
				   group		= GroupId,
				   rank 		= Rank,
				   times 		= ?CONST_CROSS_ARENA_ATTACK_TIMES,
				   fight_force	= Power,
				   partner_list	= PartnerList,
				   update_time	= UpdateTime},
	AchieveData2 	= refresh_achieve(Member),
	Member2	= Member#ets_cross_arena_member{on_line_flag = 1,open_flag = Type, achieve = AchieveData2},
	insert_member_ets(Member2);
%% 非首次
change_ui_state(Member, _PlayerId, {_NickName, _Sex, _Career, _Lv, Sn, Power, PartnerList, Type}) ->
%% 	Platform	= config:read(server_info, #rec_server_info.platform),
%% 	Node 		= node(),
	
	Member2	= Member#ets_cross_arena_member{sn = Sn, 
											on_line_flag = 1,
											open_flag = Type, 
											fight_force = Power, 
											partner_list = PartnerList},
	update_member_ets(Member2).

%% 脚本初始数据时调用
change_ui_state_init(Player, {NickName, Sex, Career, Lv, Sn, Power, PartnerList, Type}) ->
	PlayerId	= Player#player.user_id,
	case get_arena_info_by_id(PlayerId) of
		[] ->
			{PhaseId, GroupId, Rank, PhaseInfo}	= get_phase_group(PlayerId),
			update_phase_ets(PhaseInfo),
			Platform	= config:read(server_info, #rec_server_info.platform),
%% 			{Y, M, D}   = misc:date_tuple(),
%% 			UpdateTime	= misc:date_time_to_stamp({Y, M, D, 0, 0, 0}),
			Member = #ets_cross_arena_member
						  {player_id 	= PlayerId,
						   player_name 	= NickName,
						   player_sex 	= Sex,
						   player_career = Career,
						   player_lv 	= Lv,
						   platform		= Platform,
						   sn 			= Sn,
						   phase		= PhaseId,
						   group		= GroupId,
						   rank 		= Rank,
						   times 		= ?CONST_CROSS_ARENA_ATTACK_TIMES,
						   fight_force	= Power,
						   partner_list	= PartnerList},
			AchieveData2 	= refresh_achieve(Member),
			Member2	= Member#ets_cross_arena_member{on_line_flag = 1,open_flag = Type, achieve = AchieveData2},
			update_player_data(Player, Member2); %% 更新跨服玩家数据
		_ ->
			?ok
	end.

%% 更新跨服玩家数据player
update_player_data(Player, Member) when Member#ets_cross_arena_member.phase < ?CONST_CROSS_ARENA_PHASE_SEVEN ->
	Now			= misc:seconds(),
 	UpdateTime	=  Member#ets_cross_arena_member.update_time,
	case Now - UpdateTime > 7200 of
		?true ->
			PlayerData	= cross_arena_api:player_cross_data(Player),
			PlayerData1	= cross_arena_data_api:record_player_data1(PlayerData),
			PlayerData2	= cross_arena_data_api:record_player_data2(PlayerData),
			PlayerData3	= cross_arena_data_api:record_player_data3(PlayerData),
			Member2		= Member#ets_cross_arena_member{player_data 	= PlayerData1, 
														player_data2	= PlayerData2,
														player_data3	= PlayerData3,
														update_time = Now},
			update_member_ets(Member2);
		?false ->
			?ok
	end;
update_player_data(_Player, _Member) ->
	?ok.
	
%%获取个人的竞技场信息  涉及到隔日更新
get_myself_info(UserId) ->
	Member = get_arena_info_by_id(UserId), %% 获取某个玩家的竞技场信息
	get_myself_info2(Member). 

get_myself_info2([]) ->
	[?CONST_CROSS_ARENA_ERROR, #ets_cross_arena_member{}];
get_myself_info2(Member) ->
	[?CONST_CROSS_ARENA_OK, Member].

%% 插入一个玩家的竞技场信息
insert_member_ets(Member)->
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, insert_member_ets, {Member}).

%% 更新一个玩家的竞技场信息
update_member_ets(Member)-> 
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, update_member_ets, {Member}).

%% 更新一个段位的竞技场信息
update_phase_ets(PhaseInfo)-> 
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, update_phase_ets, {PhaseInfo}).

%% 更新一个战报信息
update_report_ets(Report)-> 
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, update_report_ets, {Report}).

%% 更新组内战报信息
update_group_report_ets(GroupReport)-> 
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, update_group_report_ets, {GroupReport}).

%% 更新机器人挑战信息
update_robot_ets(Robot)-> 
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, update_robot_ets, {Robot}).

%% 获取某个玩家的竞技场信息
get_arena_info_by_id(UserId)->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_arena_info_by_id, {UserId}).

get_phase_group(UserId) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_phase_group, {UserId}).

get_member_by_group(Phase, Group) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_member_by_group, {Phase, Group}).

get_phase_info(Phase) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_phase_info, {Phase}).

get_node(ServId) ->
	cross_arena_data_api:data_operate_call(center_api, get_node, {ServId}).


get_report(ReportId) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_report, {ReportId}).

get_group_report(Phase, GroupId) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_group_report, {Phase, GroupId}).

get_robot(UserId) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_robot, {UserId}).

delete_robot_by_id(UserId) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, delete_robot_by_id, {UserId}).

init_clean_center_ets() ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, init_clean_center_ets, {}).

get_next_reward_time(Member) ->
	cross_arena_data_api:data_operate_call(cross_arena_data_api, get_next_reward_time, {Member}).



%% 获取可以挑战的玩家列表
get_deffender_list(PlayerId)->
	case get_arena_info_by_id(PlayerId) of
		[]->
			[?CONST_CROSS_ARENA_ERROR, []];
		Member->
			Phase 	= Member#ets_cross_arena_member.phase,
			Group	= Member#ets_cross_arena_member.group,
			ResultList = get_member_by_group(Phase, Group),
			[?CONST_CROSS_ARENA_OK, ResultList]
	end.

%% 获取本组前五个战报列表
get_report_list(Phase, GroupId)->
	case get_group_report(Phase, GroupId) of
		[]->
			[0,[]];
		GroupReport ->
			IdList = GroupReport#cross_arena_group_report.report_list,
			TopFiveList = lists:sublist(IdList, 5),
			ReportList	= lists:map(fun(Item) -> get_report(Item) end, TopFiveList),
			[1,ReportList]
	end.

%%发起挑战 各种检查 是否开启竞技场 是否在冷却时间 挑战次数是否有剩余
start_battle(Player = #player{user_id = UserId, net_pid = NetPid}, Platform, Sn, EnemyId) ->
	MemberInfo 	= get_arena_info_by_id(UserId),
	case check_start_battle(MemberInfo, UserId, EnemyId, Platform, Sn) of	%%检查挑战的条件        检查是否可挑战（TODO）
		{?ok, CrossData} ->
			case battle_api:start(Player, EnemyId, #param{battle_type = ?CONST_BATTLE_CROSS_ARENA, cross_node = CrossData}) of %% 开始战斗
				{?error, ?TIP_COMMON_NO_THIS_PLAYER} ->
					Packet = message_api:msg_notice(?TIP_CROSS_ARENA_SKIP_WIN),
					misc_packet:send(NetPid, Packet),
					cross_arena_api:battle_over(UserId, ?CONST_BATTLE_RESULT_LEFT, EnemyId, <<>>);
				{?error, _ErrorCode} -> %% 错误
					{?ok, Player};
				{?ok, Player2} -> %% 结果返回
					{?ok, Player2}
			end;
		{?error, Return} ->		%%战斗发起失败
			Packet = message_api:msg_notice(Return),
			misc_packet:send(NetPid, Packet),
			{?ok, Player}
	end.

%%检查挑战的条件        检查是否可挑战（TODO）
check_start_battle(MemberInfo, UserId, EnemyId, _Platform, Sn) ->
	try
%% 		MemberInfo =  get_arena_info_by_id(UserId),
		?ok	= check_is_over(),
		?ok = check_remain_times(MemberInfo),	%% 检查剩余次数
		?ok = check_fight_list(MemberInfo, EnemyId),
		?ok	= check_is_self(UserId, EnemyId),
		{?ok, CrossData} = check_cross_data(Sn, EnemyId),
		{?ok, CrossData}
	catch
		throw:Return ->
			Return;
		_X:_Y ->
%% 			?MSG_ERROR("check_start_battle X =~p, Y=~p, Error=~p", [X, Y, erlang:get_stacktrace()]),
			{?error, 110}
	end.

%% 检查是否结束
check_is_over() ->
	case cross_arena_data_api:data_operate_call(cross_arena_data_api, check_is_over, {}) of
		?true ->
			throw({?error, ?TIP_CROSS_ARENA_ALREADY_OVER});
		?false ->
			?ok
	end.

%% 检查剩余次数
check_remain_times(MemberInfo) ->
	if
		MemberInfo =:= [] ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		MemberInfo#ets_cross_arena_member.times =< 0 ->
			throw({?error, ?TIP_SINGLE_ARENA_NO_TIMES});
		?true ->
			?ok
	end.

%% 检查是否已挑战过
check_fight_list(MemberInfo, EnemyId) ->
	FightList	= MemberInfo#ets_cross_arena_member.fight_list,
	case lists:member(EnemyId, FightList) of
		?true ->
			throw({?error, ?TIP_CROSS_ARENA_ALREADY_FIGHT});
		?false ->
			?ok
	end.

%% 检查是否挑战自己
check_is_self(UserId, EnemyId) ->
	case UserId =:= EnemyId of
		?true ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		?false ->
			?ok
	end.

%% 检查是否是自己
check_same_phase(MemberInfo, EnemyId) ->
	EnemyMember	= get_arena_info_by_id(EnemyId),
	Phase1		= MemberInfo#ets_cross_arena_member.phase,
	Phase2		= EnemyMember#ets_cross_arena_member.phase,
	case  Phase1 =:= Phase2 of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_CROSS_ARENA_NOT_SAME_PHASE})
	end.

%% 检查跨服数据
check_cross_data(Sn, EnemyId) ->
	EnemyMemberInfo =  get_arena_info_by_id(EnemyId),
	case center_api:get_serv_info(Sn) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			{?ok, Node};
		_ ->
			PlayerData	= EnemyMemberInfo#ets_cross_arena_member.player_data,
			case is_record(PlayerData, player) of
				?true ->
					?MSG_DEBUG("check_cross_data111111111111111111:~p",[PlayerData]),
					{?ok, ?CONST_SYS_TRUE};
				?false ->
					?MSG_DEBUG("check_cross_data2222222222222222222:~p",[PlayerData]),
					throw({?error, ?TIP_CROSS_ARENA_REFRESHING})
			end
	end.

%% 处理排名
deal_with_rank(UserId, EnemyId, Result, BinReport) ->
	MemberUser  = get_arena_info_by_id(UserId),
	MemberEnemy = get_arena_info_by_id(EnemyId),
	
	AttackName	= MemberUser#ets_cross_arena_member.player_name,
	DefName		= MemberEnemy#ets_cross_arena_member.player_name,
	Phase		= MemberUser#ets_cross_arena_member.phase,
	GroupId		= MemberUser#ets_cross_arena_member.group,
	deal_with_rank2(MemberUser, MemberEnemy, Result),
	Now			= misc:seconds(),
	ReportId 	= lists:concat([misc:to_list(UserId), "_", misc:to_list(Now)]),
	Report		= insert_report(ReportId, Result, Now, UserId, AttackName, EnemyId, DefName,  BinReport),
	insert_group_report(Phase, GroupId, ReportId),
	battle_report_to_front(UserId, Report),
	?ok.
%% 
%% %% 相反的战斗结果
%% reverse_result(?CONST_BATTLE_RESULT_LEFT) ->
%% 	?CONST_CROSS_ARENA_LOSE;
%% reverse_result(?CONST_BATTLE_RESULT_RIGHT) ->
%% 	?CONST_CROSS_ARENA_WIN;
%% reverse_result(_) ->
%% 	?CONST_CROSS_ARENA_LOSE.

%% 挑战胜利
deal_with_rank2(MemberUser, MemberEnemy, ?CONST_CROSS_ARENA_WIN)
  when is_record(MemberUser, ets_cross_arena_member) andalso is_record(MemberEnemy, ets_cross_arena_member) ->
	AttackId		= MemberUser#ets_cross_arena_member.player_id,
	Phase			= MemberUser#ets_cross_arena_member.phase,
	Group			= MemberUser#ets_cross_arena_member.group,
	
	NewUserTimes 	= MemberUser#ets_cross_arena_member.times - 1,
	NewScore		= MemberUser#ets_cross_arena_member.score + ?CONST_CROSS_ARENA_WIN_SCORE,
	NewWinTimes		= MemberUser#ets_cross_arena_member.win_times + 1,
	NewFightList	= [{MemberEnemy#ets_cross_arena_member.player_id, ?CONST_CROSS_ARENA_WIN}|MemberUser#ets_cross_arena_member.fight_list],
	NewMemberUser 	= MemberUser#ets_cross_arena_member{times = NewUserTimes, 
														score = NewScore, 
														win_times = NewWinTimes,
														fight_list = NewFightList},
	update_member_ets(NewMemberUser),
	update_group_rank(AttackId, Phase, Group), %% 交换位置广播给前端
	NewMemberUser2	= get_arena_info_by_id(AttackId),
	battle_info_to_front(NewMemberUser2);
			
%% 挑战失败
deal_with_rank2(MemberUser, MemberEnemy, ?CONST_CROSS_ARENA_LOSE)
  when is_record(MemberUser, ets_cross_arena_member) andalso is_record(MemberEnemy, ets_cross_arena_member) ->
	AttackId		= MemberUser#ets_cross_arena_member.player_id,
	Phase			= MemberUser#ets_cross_arena_member.phase,
	Group			= MemberUser#ets_cross_arena_member.group,
	
	NewUserTimes 	= MemberUser#ets_cross_arena_member.times - 1,
	NewScore		= MemberUser#ets_cross_arena_member.score + ?CONST_CROSS_ARENA_FAIL_SCORE,
	NewFailTimes	= MemberUser#ets_cross_arena_member.fail_times + 1,
	NewFightList	= [{MemberEnemy#ets_cross_arena_member.player_id, ?CONST_CROSS_ARENA_LOSE}|MemberUser#ets_cross_arena_member.fight_list],
	NewMemberUser = MemberUser#ets_cross_arena_member{times = NewUserTimes, 
													  score = NewScore, 
													  fail_times = NewFailTimes,
													  fight_list = NewFightList},
	update_member_ets(NewMemberUser),
	update_group_rank(AttackId, Phase, Group), %% 交换位置广播给前端
	NewMemberUser2	= get_arena_info_by_id(AttackId),
	battle_info_to_front(NewMemberUser2);
deal_with_rank2(_MemberUser, _MemberEnemy, _Result) ->
	?ok.

%% 存储战报
insert_report(ReportId,  Result, Time, AttackId, AttackName, DefId, DefName, BinReport) ->
	CrossReport	 	= #cross_arena_report{id				= ReportId,
										  result			= Result,
										  time				= Time,
										  attack_id 		= AttackId,
										  attack_name 		= AttackName,
										  deffender_id		= DefId,
										  deffender_name	= DefName,
										  bin_report		= BinReport},
	update_report_ets(CrossReport),
	CrossReport.

%% 存储战报
insert_group_report(Phase, GroupId, ReportId) ->
	NewGroupReport	=
		case get_group_report(Phase, GroupId) of
			GroupReport when is_record(GroupReport, cross_arena_group_report) ->
				OldReportList	= GroupReport#cross_arena_group_report.report_list,
				GroupReport#cross_arena_group_report{phase_group	= {Phase, GroupId},
										  			 report_list	= [ReportId|OldReportList]};
			_ ->
				#cross_arena_group_report{phase_group		= {Phase, GroupId},
										  report_list	= [ReportId]}
		end,
	update_group_report_ets(NewGroupReport).

%%更新战报
battle_report_to_front(UserId, Report) ->
	Packet	= cross_arena_api:msg_refresh_report(Report),
	misc_packet:send(UserId, Packet),
%% 	cross_arena_api:broadcast_open(MemberUser, Packet),
	?ok.



%% 更新组内成员排名
update_group_rank(AttackId, Phase, Group) ->
	PhaseInfo	= get_phase_info(Phase),
	GroupList	= PhaseInfo#cross_arena_phase.group_list,
	{_, UserList}	= lists:keyfind(Group, 1, GroupList),
	List1		= [X||{X, _} <- UserList],
	List2		= rank_sort(List1),
	UserList2   = misc:get_list_index(List2),
	GroupList2  = lists:keyreplace(Group, 1, GroupList, {Group, UserList2}),
	PhaseInfo2	= PhaseInfo#cross_arena_phase{group_list = GroupList2},
	update_phase_ets(PhaseInfo2),
	update_group_rank_ext(UserList2),
	Packet		= cross_arena_api:msg_refresh_group_info(UserList2),
	misc_packet:send(AttackId, Packet).
%% 	%% 广播给组内所有打开界面的人（不广播）
%% 	cross_arena_api:broadcast_open(AttackId, Packet).

update_group_rank_ext([{UserId, Rank}|UserList]) ->
	Member		= get_arena_info_by_id(UserId),
	Member2		= Member#ets_cross_arena_member{rank = Rank},
	update_member_ets(Member2),
	update_group_rank_ext(UserList);
update_group_rank_ext([_|UserList]) ->
	update_group_rank_ext(UserList);
update_group_rank_ext([]) -> ?ok.
	
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

%% 更新个人信息
battle_info_to_front(MemberUser) ->
	UserId			= MemberUser#ets_cross_arena_member.player_id,
	RemainTimes		= MemberUser#ets_cross_arena_member.times,
	Rank			= MemberUser#ets_cross_arena_member.rank,
	Score			= MemberUser#ets_cross_arena_member.score,
	WinTimes		= MemberUser#ets_cross_arena_member.win_times,
	FailTimes		= MemberUser#ets_cross_arena_member.fail_times,
	FightList		= MemberUser#ets_cross_arena_member.fight_list,
	Packet			= cross_arena_api:msg_refresh_member_info(RemainTimes, Rank, Score, WinTimes, FailTimes, FightList),
	misc_packet:send(UserId, Packet).

	
	
%% 获取排名段位
get_phase(Rank) ->
	get_phase(Rank, 1, 0).
get_phase(_Rank, Phase, Phase) ->
	Phase;
get_phase(Rank, Phase, Acc) ->
	RecInterval = data_cross_arena:get_base_cross_arena_interval(Phase),
	if
		RecInterval#rec_cross_arena_interval.num1 =< Rank andalso RecInterval#rec_cross_arena_interval.num2 >= Rank ->
			get_phase(Rank, Phase, Phase);
		?true ->
			get_phase(Rank, Phase+1, Acc)
	end.

%% 天神榜信息
god_phase_info(Player) ->
	UserId		= Player#player.user_id,
	Phase 		= 1,
	Group		= 1,
	GodList 	= get_member_by_group(Phase, Group),
	Packet		= cross_arena_api:msg_group_info(2, Phase, Group, GodList),
	misc_packet:send(UserId, Packet).

%% 领取每日排名奖励
get_day_reward(Player) ->
	UserId			= Player#player.user_id,
	Member			= get_arena_info_by_id(UserId),
	Phase			= Member#ets_cross_arena_member.phase,
	LastWinTimes	= Member#ets_cross_arena_member.last_win_times,
	?MSG_DEBUG("get_day_reward111111:~p",[{Phase, LastWinTimes}]),
	case data_cross_arena:get_cross_arena_reward({1, Phase, LastWinTimes}) of
		RecReward when is_record(RecReward, rec_cross_arena_reward) ->
			Member2	= Member#ets_cross_arena_member{last_win_times = 0},
			update_member_ets(Member2),
			day_reward(Player, RecReward);
		_ ->
			{?ok, Player}
	end.

day_reward(Player, RecReward)
  when is_record(Player, player) andalso is_record(RecReward, rec_cross_arena_reward)	->
	case reward_goods(Player, RecReward#rec_cross_arena_reward.goods, ?CONST_COST_CROSS_ARENA_DAY) of
		{?error, ErrorCode}	->
			{?error, ErrorCode};
		{?ok, Player2, _GoodsList}	->
%% 			Lv			= (Player#player.info)#info.lv,
%% 			Rate		= RecReward#rec_cross_arena_reward.rate,
			Coin		= RecReward#rec_cross_arena_reward.coin,
			Meritorious = RecReward#rec_cross_arena_reward.meritorious,
			RewardCoin  = Coin, %misc:floor(Lv * Rate * Coin),
			RewardMeri	= Meritorious, %misc:floor(Lv * Rate * Meritorious),
			case reward_gold(Player#player.user_id, RewardCoin) of
				?ok ->
					{?ok, Player3} = reward_meritorious(Player2, RewardMeri),
					Packet			= cross_arena_api:msg_day_reward(1),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player3};
				{?error, ErrorCode}	->
					?MSG_ERROR("ErrorCode=~p", [ErrorCode]),
					{?ok, Player}
			end
	end.
%% day_reward(Player, _)	->	{?ok, Player}.

%% 成就界面信息
achieve_info(Player) ->
	UserId			= Player#player.user_id,
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			AchieveData2 	= refresh_achieve(Member),
			Packet			= cross_arena_api:msg_achieve_info(AchieveData2),
			misc_packet:send(UserId, Packet),
			Member2			= Member#ets_cross_arena_member{achieve = AchieveData2},
			cross_arena_mod:update_member_ets(Member2);
		_ ->
			?ok
	end.

refresh_achieve(Member) when is_record(Member, ets_cross_arena_member) ->
	AchieveData 	= Member#ets_cross_arena_member.achieve,
	Phase			= Member#ets_cross_arena_member.phase,
	AchieveList		= 
		case data_cross_arena:get_cross_arena_achieve_list(Phase) of
			?null ->
				[];
			List ->
				List
		end,
	add_achieve(AchieveList, AchieveData);
refresh_achieve(_Member) ->
	[].

add_achieve([AchieveId|TailList], AchieveData) ->
	NewAchieveData	=
		case lists:keyfind(AchieveId, #cross_arena_achieve.id, AchieveData) of
			Tuple when is_record(Tuple, cross_arena_achieve) ->
				AchieveData;
			_ ->
				NewTuple	 = #cross_arena_achieve{id = AchieveId, flag = 1},
				[NewTuple|AchieveData]
		end,
	add_achieve(TailList, NewAchieveData);
add_achieve([], AchieveData) -> AchieveData.
	
%% 领取成就奖励
get_achieve_reward(Player, AchieveId) ->
	UserId			= Player#player.user_id,
	Member			= get_arena_info_by_id(UserId),
	AchieveData		= Member#ets_cross_arena_member.achieve,
	case lists:keyfind(AchieveId, #cross_arena_achieve.id, AchieveData) of
		Tuple when is_record(Tuple, cross_arena_achieve) 
		  andalso Tuple#cross_arena_achieve.flag =/= 2 ->
			case data_cross_arena:get_cross_arena_achieve(AchieveId) of
				RecAchieve when is_record(RecAchieve, rec_cross_arena_achieve) ->
					RewardGoods	= RecAchieve#rec_cross_arena_achieve.goods,
					case reward_goods(Player, RewardGoods, ?CONST_COST_CROSS_ARENA_ACHIEVE) of
						{?error, _ErrorCode}		->	{?ok, Player};
						{?ok, Player2, _GoodsList}	->
							Tuple2		 	= Tuple#cross_arena_achieve{flag = 2},
							AchieveData2 	= lists:keyreplace(AchieveId, #cross_arena_achieve.id, AchieveData, Tuple2),
							Member2			= Member#ets_cross_arena_member{achieve = AchieveData2},
							cross_arena_mod:update_member_ets(Member2),
							Packet1		 	= cross_arena_api:msg_achieve_reward(AchieveId),
							Packet2			= message_api:msg_notice(?TIP_CROSS_ARENA_REWARD_SUCCESS),
							Packet			= <<Packet1/binary, Packet2/binary>>,
							misc_packet:send(UserId, Packet),
							{?ok, Player2}
					end;
				_ ->
					{?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end.
	
%% 军功奖励
reward_meritorious(Player, 0) -> {?ok, Player};
reward_meritorious(Player, Meritorious) -> player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_CROSS_ARENA_DAY).

%% 游戏币奖励
reward_gold(_UserId, 0) -> ?ok;
reward_gold(UserId, Gold) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_CROSS_ARENA_DAY) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 物品奖励
reward_goods(Player, List, Type)	->
	reward_goods(Player, List, [], Type).
reward_goods(Player, [{GoodsId, BindState, Count} | List], Acc, Type)	->
	case reward_goods(Player, GoodsId, BindState, Count, Type) of
		{?ok, Player2, GoodsList}	->	reward_goods(Player2, List, (GoodsList ++ Acc), Type);
		{?error, ErrorCode}	->	{?error, ErrorCode}
	end;
reward_goods(Player, [], Acc, _Type)	->	{?ok, Player, Acc}.

reward_goods(Player, GoodsId, BindState, Count, Type)	->
	UserId	= Player#player.user_id,
	case goods_api:make(GoodsId, BindState, Count) of
		GoodsList when is_list(GoodsList)	->
            case ctn_bag_api:put(Player, GoodsList, Type, 1, 1, 0, 0, 1, 1, []) of
				{?error, ErrorCodeBag}	->
					{?error, ErrorCodeBag};
				{?ok, Player2, _, _} ->
					{?ok, Player2, GoodsList}
			end;
		{?error, ErrorCodeGoods}	->
			PacketGoods2Err = message_api:msg_notice(ErrorCodeGoods),
			misc_packet:send(UserId, PacketGoods2Err),
			{?error, ErrorCodeGoods}
	end.

%% 天神商店购买
buy(Player, Id, Count) ->
    case data_cross_arena:get_score_shop(Id) of
        #rec_cross_arena_shop{cost = Cost, goods_id = 0, partner_id = PartnerId} ->
            Cost2 = round(Cost * Count),
			case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, Cost2, ?CONST_COST_CROSS_ARENA_SHOP) of
				?ok ->
            		Player2 = partner_api:give_partner_list(Player, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                    {?ok, Player2};
				_Other ->
					{?ok, Player}
            end;
        #rec_cross_arena_shop{cost = Cost, goods_id = GoodsId} ->
			Cost2 = round(Cost * Count),
            case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, Cost2, ?CONST_COST_CROSS_ARENA_SHOP) of
				?ok ->
                    case goods_api:make(GoodsId, ?CONST_SYS_TRUE, Count) of
                        {?error, ErrorCode} ->
                            {?error, ErrorCode};
                        GoodsList ->
                            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_CROSS_ARENA_SHOP, 1, 1, 1, 0, 0, 1, []) of
                                {?ok, Player2, _, GoodsPacket} ->
                                    misc_packet:send(Player#player.user_id, GoodsPacket),
                                    {?ok, Player2};
                                {?error, ErrorCode} ->
                                    {?error, ErrorCode}
                            end
                    end;
                _Other ->
                    {?ok, Player}
            end;
        _ ->
            {?error, ?TIP_SINGLE_ARENA_GOODS_NOT_EXISTS}
    end.

%% 刷新武将
update_partner(UserId, PartnerList, Power) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			Member2		= Member#ets_cross_arena_member{fight_force = Power, partner_list = PartnerList},
			update_member_ets(Member2);
		_ ->
			?ok
	end.

%% 刷新战力
update_power(UserId, Power) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			Member2		= Member#ets_cross_arena_member{fight_force = Power},
			update_member_ets(Member2);
		_ ->
			?ok
	end.
	
%% 根据战报ID 获取二进制战报
get_report_by_id(ReportId) ->
	case get_report(ReportId) of
		#cross_arena_report{bin_report = Report} ->
			Report;
		_ ->
			<<>>
	end.

%% 查看人物详细
cross_player_info(Player, _Platform, Sn, UserId) ->
	MemberInfo =  get_arena_info_by_id(UserId),
	CrossData = 
		case center_api:get_serv_info(Sn) of
			{Node, ?CONST_CENTER_STATE_NORMAL} ->
				case rpc:call(misc:to_atom(Node), player_api, get_player_first, [UserId]) of
					{?ok, PlayerFirst, _} ->
%% 						?MSG_DEBUG("cross_player_info111111111111111:~p",[PlayerFirst#player.weapon]),
						PlayerFirst;
					_ ->
						?null
				end;
			_ ->
				MemberInfo#ets_cross_arena_member.player_data
		end,
	Packet	=
		case is_record(CrossData, player) of
			?true ->
				?MSG_DEBUG("cross_player_info22222222222222222222222:~p",[CrossData#player.user_id]),
				P1 = player_api:msg_player_data_info(CrossData, #money{user_id = UserId}, 2),
				P1;
			?false ->
				?MSG_DEBUG("cross_player_info33333333333333333333333:~p",[UserId]),
				<<>>
		end,
	misc_packet:send(Player#player.net_pid, Packet).


cross_partner_info(Player, _Platform, Sn, UserId, PartnerId) ->
	MemberInfo =  get_arena_info_by_id(UserId),
	CrossData = 
		case center_api:get_serv_info(Sn) of
			{Node, ?CONST_CENTER_STATE_NORMAL} ->
				case rpc:call(misc:to_atom(Node), player_api, get_player_first, [UserId]) of
					{?ok, PlayerFirst, _} ->
%% 						?MSG_DEBUG("cross_player_info111111111111111:~p",[PlayerFirst#player.partner]),
						PlayerFirst;
					_ ->
						?null
				end;
			_ ->
				MemberInfo#ets_cross_arena_member.player_data
		end,
	Type	= 
		case PartnerId =:= 0 of
			?true ->
				?CONST_GOODS_CTN_EQUIP_PLAYER;
			?false ->
				?CONST_GOODS_CTN_EQUIP_PARTNER
		end,
	Packet	=
		case is_record(CrossData, player) of
			?true ->
				?MSG_DEBUG("cross_partner_info22222222222222222222222:~p",[CrossData#player.user_id]),
				P1 = partner_api:msg_partner_mind_info(CrossData, UserId, PartnerId),
				P2 = partner_attr(CrossData, PartnerId),
				P3 = ctn_equip_api:ctn_info(CrossData, UserId, PartnerId, Type),
				<<P1/binary, P2/binary, P3/binary>>;
			?false ->
				?MSG_DEBUG("cross_partner_info33333333333333333333333:~p",[CrossData#player.user_id]),
				<<>>
		end,
	misc_packet:send(Player#player.net_pid, Packet).
	
cross_partner(Player, _Platform, Sn, UserId) ->
	MemberInfo =  get_arena_info_by_id(UserId),
	CrossData = 
		case center_api:get_serv_info(Sn) of
			{Node, ?CONST_CENTER_STATE_NORMAL} ->
				case rpc:call(misc:to_atom(Node), player_api, get_player_first, [UserId]) of
					{?ok, PlayerFirst, _} ->
						PlayerFirst;
					_ ->
						?null
				end;
			_ ->
				MemberInfo#ets_cross_arena_member.player_data
		end,
	Packet	=
		case is_record(CrossData, player) of
			?true ->
				?MSG_DEBUG("cross_player_info22222222222222222222222:~p",[CrossData#player.user_id]),
				P1 = partner_api:msg_partner_mind_info(CrossData, UserId, 0),
				P2 = partner_attr(CrossData, 0),
				PartnerList = partner_mod:get_partner_by_team(CrossData#player.partner, ?CONST_PARTNER_TEAM_IN),
				P3 = partner_api:msg_partner_info_list(UserId, CrossData#player.equip, 0, PartnerList),
				P4 = ctn_equip_api:ctn_info(CrossData, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PLAYER),
				<<P1/binary, P2/binary, P3/binary, P4/binary>>;
			?false ->
				?MSG_DEBUG("cross_player_info33333333333333333333333:~p",[CrossData#player.user_id]),
				<<>>
		end,
	misc_packet:send(Player#player.net_pid, Packet).

%% 武将属性查看
partner_attr(Player, 0) ->
	?MSG_DEBUG("partner_attr111111111111111111111111:~p",[Player#player.weapon]),
	LookforAttr		= partner_api:refresh_attr_lookfor(Player),
	AssembleAttr 	= partner_api:refresh_attr_assemble(Player),
	AssAttr			= player_attr_api:attr_plus(LookforAttr, AssembleAttr),
	Info			= Player#player.info,
	Pro            	= Info#info.pro,
	Weapon         	= Player#player.weapon,
	WeaponAttr     	= weapon_api:refresh_attr(Weapon, Pro),
	partner_api:msg_partner_attr(Player#player.user_id, 0, Pro, Weapon, AssAttr, WeaponAttr);
partner_attr(Player, PartnerId) ->
	?MSG_DEBUG("partner_attr22222222222222222222222:~p",[Player#player.weapon]),
	case partner_mod:get_partner_by_id(Player, PartnerId) of
		{?ok, Partner} ->
			LookforAttr		= partner_api:refresh_attr_lookfor(Player),
			AssembleAttr 	= partner_api:refresh_attr_assemble(Player),
			AssAttr			= player_attr_api:attr_plus(LookforAttr, AssembleAttr),
			Pro            	= Partner#partner.pro,
			Weapon         	= Player#player.weapon,
			WeaponAttr     	= weapon_api:refresh_attr(Weapon, Pro),
			partner_api:msg_partner_attr(Player#player.user_id, PartnerId, Pro, Weapon, AssAttr, WeaponAttr);
		_ ->
			<<>>
	end.

%% 获取member表中的player信息
get_cross_player(UserId) ->
	case get_arena_info_by_id(UserId) of
		Member when is_record(Member, ets_cross_arena_member) ->
			Member#ets_cross_arena_member.player_data;
		_ ->
			?null
	end.
%%
%% Local Functions
%%

