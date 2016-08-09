%% Author: php
%% Created: 2012-09-13 20
%% Description: 个人竞技场协议处理
-module(single_arena_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 打开/关闭竞技场界面
handler(?MSG_ID_SINGLE_ARENA_CS_ENTER, Player = #player{user_id = UserId, net_pid = NetPid, info = Info, serv_id = ServId}, {Type}) ->
    case Type of
        1 ->
            case guide_api:is_finish_guide(Player, ?CONST_MODULE_SINGLEARENA) of
                ?true ->
        			#info{user_name = UserName, sex = Sex, pro = Pro, lv = Lv} = Info,
        			Result 					= single_arena_mod:change_ui_state(UserId, UserName, Sex, Pro, Lv, ServId, Type), %% 打开竞技场界面
        			[_, Member] 			= single_arena_mod:get_myself_info(UserId), 				%% 获取个人的竞技场信息  涉及到隔日更新
        			StreakAwardList 		= single_arena_mod:get_streak_win_reward_info(UserId), 		%% 获取连胜列表
        			[_, DefList] 			= single_arena_mod:get_deffender_list(UserId), 				%% 获取可以挑战的玩家列表
        			[_, ReportList] 		= single_arena_mod:get_arena_report(UserId), 				%% 获取玩家战报
        			Packet 		= single_arena_api:msg_sc_enter_arena(Type, Result, Member, StreakAwardList, DefList, ReportList), %%进入竞技场的协议
                    TargetPacket = single_arena_api:get_target(Member),
        			misc_packet:send(NetPid, <<Packet/binary, TargetPacket/binary>>),
        			?ok;
                ?false -> % 以下一切都是假的
                    {Result, Rank, IsNew} = single_arena_robot_api:change_ui_state(UserId, Info, Type),      %% 打开竞技场界面
                    Packet = 
                        if
                            ?CONST_SYS_TRUE =:= IsNew ->
                                Member      = single_arena_robot_api:get_myself_info(UserId, Info, Rank),    %% 获取个人的竞技场信息  涉及到隔日更新        
                                StreakAwardList = single_arena_robot_api:get_streak_win_reward_info(), %% 获取连胜列表
                                DefList     = single_arena_robot_api:get_deffender_list(),             %% 获取可以挑战的玩家列表       
                                ReportList  = single_arena_robot_api:get_arena_report(),
                                single_arena_robot_api:msg_sc_enter_arena(Type, Result, Member, StreakAwardList, DefList, ReportList); %%进入竞技场的协议
                            ?true -> % 老数据要跳过引导
                                [_, Member]             = single_arena_mod:get_myself_info(UserId),                 %% 获取个人的竞技场信息  涉及到隔日更新
                                StreakAwardList         = single_arena_mod:get_streak_win_reward_info(UserId),      %% 获取连胜列表
                                [_, DefList]            = single_arena_mod:get_deffender_list(UserId),              %% 获取可以挑战的玩家列表
                                [_, ReportList]         = single_arena_mod:get_arena_report(UserId),                %% 获取玩家战报
                                P = single_arena_api:msg_sc_enter_arena(Type, Result, Member, StreakAwardList, DefList, ReportList), %%进入竞技场的协议
                                TargetPacket = single_arena_api:get_target(Member),
                                <<P/binary, TargetPacket/binary>>
                        end,
                    misc_packet:send(NetPid, Packet),
                    ?ok
            end;
        2 ->
            ?ok
    end;

%% 清除cd
handler(?MSG_ID_SINGLE_ARENA_CS_CLEAR_CD, Player = #player{net_pid = NetPid}, {}) ->
	{Result, NewPlayer} = single_arena_mod:clean_cd(Player),		%%清除CD
	Packet 				= single_arena_api:msg_sc_clear_cd(Result),
	misc_packet:send(NetPid, Packet),
	{?ok, NewPlayer};

%% 发起战斗
handler(?MSG_ID_SINGLE_ARENA_CS_START_BATTLE, Player, {EnemyId}) ->
    case guide_api:is_finish_guide(Player, ?CONST_MODULE_SINGLEARENA) of
        ?true ->
        	case single_arena_mod:start_battle(Player, EnemyId) of
        		{?ok, Player2} ->
        			{_, Player3} = welfare_api:add_pullulation(Player2, ?CONST_WELFARE_SINGLE_ARENA, 0, 1),	%% 福利
                    {?ok, Player4} = task_api:update_single_arena(Player3),
        			{?ok, Player4};
        		_Other ->
        			?ok
        	end;
        ?false ->
            case single_arena_robot_api:start_battle(Player, EnemyId) of
                {?ok, Player2} ->
                    % 引导
                    GuideList = Player2#player.guide,
                    case data_guide:get_guide(?CONST_MODULE_SINGLEARENA) of
                        ?null ->
                            {?ok, Player2};
                        [Guide|_] ->
                            NewGuideList = guide_api:finish_module(GuideList, Guide),
                            NewPlayer = Player2#player{guide = NewGuideList},
                            {?ok, NewPlayer2} = task_api:update_guide_sysid(NewPlayer, ?CONST_MODULE_SINGLEARENA),
%%                             partner_api:msg_free_train_by_module(NewPlayer2, Guide),
                            {?ok, NewPlayer2}
                    end;
                _Other ->
                    ?ok
            end
    end;

%% 领取连胜奖励
handler(?MSG_ID_SINGLE_ARENA_CS_WIN_STREAK_AWARD, Player = #player{net_pid = NetPid}, {WinStreak}) ->
	{Result, RewardList, NewPlayer} = single_arena_mod:win_streak_award(Player, WinStreak),	%% 领取连胜奖励
	NonRewardList 					= single_arena_mod:treat_non_reward_list(?CONST_SINGLE_ARENA_STREAK_WIN_AWARD_LIST, RewardList),%% 处理没有奖励的连胜次数
	Packet 							= single_arena_api:msg_sc_win_streak_award(Result, NonRewardList), %% 领取连胜奖励返回
	misc_packet:send(NetPid, Packet),
	{?ok, NewPlayer};

%% 竞技场排行榜
handler(?MSG_ID_SINGLE_ARENA_CS_RANK, #player{net_pid = NetPid}, {}) ->
	RankList	= single_arena_api:get_single_arena_top_rank_ets(?CONST_SINGLE_ARENA_TOP_RANK),	%%获取竞技场排名前XX(ets)
	RankData 	= single_arena_api:pack_rank_list(RankList),	%%打包竞技场排行榜信息给前端
	Packet 		= misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_RANK, ?MSG_FORMAT_SINGLE_ARENA_SC_RANK, {RankData}),
	misc_packet:send(NetPid, Packet),
	?ok;

%% 购买战斗次数
handler(?MSG_ID_SINGLE_ARENA_CS_BUY_CHALLENGE_TIME, Player = #player{net_pid = NetPid}, {}) ->
	{Result, TodayTimes} = single_arena_mod:buy_challenge_times(Player),	%%购买挑战次数
	Packet 				 = single_arena_api:msg_sc_buy_challenge_time(Result, TodayTimes), %% 购买战斗次数返回
	misc_packet:send(NetPid, Packet),
	?ok;

%% 领取排行奖励(不一定在这里领取/每一周期的排行完成，奖励存放到mysql.arena_reward)
handler(?MSG_ID_SINGLE_ARENA_CS_RANK_AWARD, Player, {}) ->
	{Result, NewPlayer} = single_arena_mod:get_rank_reward(Player),		%% 领取排名奖励，从数据库中数据判断
	Packet 				= single_arena_api:msg_sc_rank_award(Result),	%% 领取排名奖励返回
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, NewPlayer};

%% 请求战报
handler(?MSG_ID_SINGLE_ARENA_CS_GET_REPORT, Player, {ReportId}) ->
	BinReport = single_arena_mod:get_report_by_id(ReportId),
	misc_packet:send(Player#player.net_pid, BinReport),
	?ok;

%% 登录推送挑战次数/CD请求
handler(?MSG_ID_SINGLE_ARENA_CS_LOGIN_DATA, #player{user_id = UserId}, {}) ->
	Packet = single_arena_api:times_cd_to_front(UserId),
	misc_packet:send(UserId, Packet),
	?ok;

%% 请求冠军战报
handler(?MSG_ID_SINGLE_ARENA_CS_CHAMPION_REPORT, #player{user_id = UserId}, {}) ->
	single_arena_api:champion_report_to_front(UserId),
	?ok;

%% 竞技场英雄榜
handler(?MSG_ID_SINGLE_ARENA_CS_TOP_RANK, Player, {Num}) ->
	Packet = single_arena_mod:top_rank(Num),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;

%% 竞技场连胜榜
handler(?MSG_ID_SINGLE_ARENA_CS_TOP_STREAK, Player, {Num}) ->
	Packet = single_arena_mod:top_streak(Num),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;

%% 积分兑换
handler(?MSG_ID_SINGLE_ARENA_CS_EXCHANGE, Player, {Id, Count}) ->
    single_arena_shop_api:exchange(Player, Id, Count);

%% 领目标奖励
handler(?MSG_ID_SINGLE_ARENA_CS_GET_TARGET_REWARD, Player, {}) ->
    single_arena_api:get_daily_award(Player);

handler(_MsgId,_Player,_Datas) -> ?undefined.

%%
%% Local Functions
%%
