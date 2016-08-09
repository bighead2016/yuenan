%%% 跑龙套的机器人处理
-module(single_arena_robot_api).

%%
%% Include files
%%
-include("const.define.hrl").
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").
-include("record.data.hrl").
-include("record.map.hrl").

%%
%% Exported Functions
%%
-export([get_deffender_list/0, change_ui_state/3, get_arena_report/0, 
         get_streak_win_reward_info/0, get_myself_info/3, get_myself_info/7,
         start_battle/2, challenge_list_to_front/1, battle_over/1, deal_with_rank/1,
         msg_sc_enter_arena/6]).

%%
%% API Functions
%%
%% 读取能打的那几个人
get_deffender_list() ->
    get_deffender(data_single_arena:get_robot_list(), []).

get_deffender([{MonId, Sex}|Tail], List) ->
    RobotT = 
        case data_monster:get_monster(MonId) of
            #monster{lv = Lv, pro = Pro, name = Name, power = Power} ->
                record_arena_member(MonId, Lv, Pro, to_list(Name), Sex, Power, 0);
            _ ->
                record_arena_member(10001, 2, ?CONST_SYS_PRO_FJ, to_list(<<"robot1">>), ?CONST_SYS_SEX_MALE, 1, 0)
        end,
    get_deffender(Tail, [RobotT|List]);
get_deffender([], List) -> List.

%% 首次进入竞技场
change_ui_state(UserId, Info, Type) ->
    {RankNew, IsNew} = 
        case single_arena_mod:get_arena_info_by_id(UserId) of
            [] ->
                Rank = single_arena_mod:get_arena_count() + 1,
                {Rank, ?CONST_SYS_TRUE};
            #ets_arena_member{rank = Rank} ->
                UserName = Info#info.user_name,
                Sex      = Info#info.sex,
                Pro      = Info#info.pro,
                Lv       = Info#info.lv,
                single_arena_mod:change_ui_state(UserId, UserName, Sex, Pro, Lv, 0, Type), %% 更新人物信息
                {Rank, ?CONST_SYS_FALSE}
        end,
    {?CONST_SINGLE_ARENA_OK, RankNew, IsNew}.

get_arena_report() ->
    [].

get_streak_win_reward_info() ->
    [].

get_myself_info(UserId, Info, Rank) ->
    record_arena_member(UserId, Info#info.lv, Info#info.pro, 
                        Info#info.user_name,  Info#info.sex,
                        Info#info.power, Rank).
get_myself_info(UserId, Lv, Pro, UserName, Sex, Power, Rank) ->
    record_arena_member(UserId, Lv, Pro, UserName, Sex, Power, Rank).

msg_sc_enter_arena(_Type, Result, Member, _StreakAwardList, DefList, _ReportList) ->
    Rank            = Member#ets_arena_member.rank,
    Streak          = Member#ets_arena_member.winning_streak,
    TodayTimes      = 15,
    TempTime        = Member#ets_arena_member.cd - misc:seconds(),
    Cd              = misc:max(TempTime, 0),
    
    DailyMaxWin     = Member#ets_arena_member.daily_max_win,
    MaxWin          = Member#ets_arena_member.max_win,
    DailyBuyTime    = Member#ets_arena_member.daily_buy_time,
    
    %% 未领取连胜的物品
    Data1 = [],
    %% 可挑战角色列表
    F = fun(M, {OldList, Rk, Rk2}) ->
                PlayerId = M#ets_arena_member.player_id, 
                Lv       = M#ets_arena_member.player_lv, 
                Pro      = M#ets_arena_member.player_career,
                Name     = M#ets_arena_member.player_name,
                Sex      = M#ets_arena_member.player_sex,
                Power    = M#ets_arena_member.fight_force,
                Rk2_2    = Rk2 + 1, 
                R        = 
                    if
                        Rk =:= Rk2_2 ->
                            Rk2_2 + 1;
                        Rk2_2 =< 0 andalso 1 =/= Rk ->
                            1;
                        Rk2_2 =< 0 ->
                            2;
                        ?true ->
                            Rk2_2
                    end,
                %%排名奖励
                L = {PlayerId, Lv, R, misc:to_list(Name), Pro, Sex, 0, 
                        0, 0, 0, 0, 0, misc:to_list(<<"[]">>), 0, Power, 0},
                {[L|OldList], Rk, R}
        end,
    {Data2, _, _} = lists:foldl(F, {[], Rank, Rank-4}, DefList),
    %% 个人战报信息
    Data3 = [],
    Data  = 
        [Result, Rank, Streak, TodayTimes, Cd, 0, 23*3600, 0, 0, 0, 0, MaxWin, DailyMaxWin, DailyBuyTime, Data1, Data2, Data3],
    misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_ENTER, ?MSG_FORMAT_SINGLE_ARENA_SC_ENTER, Data).

start_battle(Player, EnemyId) ->
    {?ok, NewPlayer} = 
        case battle_api:start(Player, EnemyId, #param{battle_type = ?CONST_BATTLE_SINGLE_ROBOT}) of %% 开始战斗
            {?error, _ErrorCode} -> %% 错误
                {?ok, Player};
            {?ok, Player2} -> %% 结果返回
                {?ok, Player2}
        end,
    GuideList  = NewPlayer#player.guide,
    GuideList2 = guide_api:finish_module(GuideList, ?CONST_MODULE_SINGLEARENA),
    NewPlayer2 = NewPlayer#player{guide = GuideList2},
    {?ok, NewPlayer2}.

%%推送挑战列表更新给前端          被挑战者也会收到该更新协议 （排名下降的时候）
challenge_list_to_front(UserId) ->
    DefList = get_deffender_list(),
    
    Fun = fun(Member) ->
                  #ets_arena_member{player_id   = PlayerId,
                                    player_lv   = PlayerLv,
                                    rank        = Rank,
                                    player_name = Name,
                                    player_career = Career,
                                    player_sex  = Sex,
                                    fight_force = Power
                                   } = Member,
                  {
                   PlayerId,
                   PlayerLv,
                   Rank,
                   misc:to_list(Name),
                   Career,
                   Sex,
                   0,
                   0,
                   0, 
                   0,
                   0,
                   0,
                   misc:to_list(<<"">>),
                   0,
                   Power, 
                   0
                   }
          end,
    Datas = lists:map(Fun, DefList),
    
    Packet = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, {Datas}),
    misc_packet:send(UserId, Packet).

%%  战斗模块通知竞技场结束
battle_over(UserId) ->
    single_arena_serv:deal_with_rank_robot_cast(UserId),
    {?ok, Info} = player_api:get_player_field(UserId, #player.info),
    Rank = single_arena_mod:get_arena_count() + 1,
    NextRank    = single_arena_api:calc_target(Rank),
    Member = #ets_arena_member
                 {rank          = Rank,
                  player_id     = UserId,
                  player_name   = Info#info.user_name,
                  player_sex    = Info#info.sex,
                  player_career = Info#info.pro,
                  player_lv     = Info#info.lv,
                  times         = 0,
                  clean_times_time = misc:seconds(),
                  daily_target  = NextRank,
                  target_state  = ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE
                  },
    single_arena_mod:insert_member_ets(Member#ets_arena_member{on_line_flag = 1,open_flag = ?CONST_SINGLE_ARENA_STATE_ON}),
    [_, Member2]             = single_arena_mod:get_myself_info(UserId),                 %% 获取个人的竞技场信息  涉及到隔日更新
    StreakAwardList         = single_arena_mod:get_streak_win_reward_info(UserId),      %% 获取连胜列表
    [_, DefList]            = single_arena_mod:get_deffender_list(UserId),              %% 获取可以挑战的玩家列表
    Packet      = single_arena_api:msg_sc_enter_arena(?CONST_SINGLE_ARENA_STATE_ON, ?CONST_SINGLE_ARENA_OK, Member2, StreakAwardList, DefList, []), %%进入竞技场的协议
    Packet2     = single_arena_api:msg_sc_target(Member#ets_arena_member.daily_target, ?CONST_SINGLE_ARENA_STATE_NOT_ARRIVE),
    misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>).

%% 处理排名
deal_with_rank(UserId) ->
    challenge_list_to_front(UserId),
    battle_info_to_front(UserId),
    ?ok.

%% 更新战斗信息
battle_info_to_front(UserId) ->
    Datas         = {0, 0, 0, 0, 15, 99, 23*3600, 0, 0, 0}, 
    Packet        = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_REFRESH_REPORT, ?MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_REPORT, Datas),
    misc_packet:send(UserId, Packet).

%%
%% Local Functions
%%

record_arena_member(UserId, Lv, Pro, UserName, Sex, Power, Rank) ->
    #ets_arena_member{
                      cd = 0,
                      clean_times_time = 0,
                      daily_buy_time = 0,
                      daily_max_win = 0,
                      fight_force = Power,
                      max_win = 0,
                      meritorious = 0,
                      on_line_flag = 1,
                      open_flag = 1,
                      player_career = Pro,
                      player_id = UserId,
                      player_lv = Lv,
                      player_name = UserName,
                      player_sex = Sex,
                      rank = Rank,
                      sn = 0,
                      streak_wining_reward = 0,
                      times = 99,
                      winning_streak = 0,
                      score = 0
                     }.

to_list(X) ->
    binary_to_list(unicode:characters_to_binary(X)).
