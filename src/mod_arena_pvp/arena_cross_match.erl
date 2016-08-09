%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2013-9-28
%%% -------------------------------------------------------------------
-module(arena_cross_match).

-behaviour(gen_server).
-compile(export_all).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/const.protocol.hrl").
-include("record.battle.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([app_match/2, start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

-define(CONST_CROSS_ARENA_TIME3, 60).
-define(CONST_CROSS_ARENA_TIME1, 10).
-define(CONST_CROSS_ARENA_TIME2, 30).


%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).

test1() ->
    Now = misc:seconds(),
    UserId1 = 9,
    UserId2 = 10,
    {ok, Data1} = battle_cross_api:record_battle(UserId1),
    {ok, Data2} = battle_cross_api:record_battle(UserId2),
    Match1 = #arena_pvp_cross_match{leader_id = UserId1, level = 10, start_time = Now, streak_win = 10, battle_data = Data1},
    Match2 = #arena_pvp_cross_match{leader_id = UserId2, level = 11, start_time = Now, streak_win = 11, battle_data = Data2},
    app_match(Match1,1),
    app_match(Match2,1).

app_match(Match, BattleData) ->
    {_, _, _, _, TeamId, _} = BattleData,
    Master = cross_api:get_arena_master(),
    MemberIdList = team_api:get_team_id_list(?CONST_TEAM_TYPE_ARENA, TeamId),
    case check_open(MemberIdList) of
        false ->
            ok;
        _ ->
            Cross_in = #cross_in{player_data = BattleData,
                                  node = node(),
                                  member_id_list = MemberIdList,
                                  user_id = Match#arena_pvp_cross_match.leader_id, 
                                  team_id = TeamId},
            Fun = 
                fun(MemId) ->
                        case MemId == Match#arena_pvp_cross_match.leader_id of
                            true ->
                                Cross_in2 = Cross_in;
                            _ ->
                                Cross_in2 = Cross_in#cross_in{user_id = MemId, player_data = null}
                        end,
                        rpc:call(Master, ets, insert, [?CONST_ETS_CROSS_IN, Cross_in2])
                end,
            lists:foreach(Fun, MemberIdList),
            rpc:cast(Master, ets, insert, [?CONST_ETS_CROSS_ARENA_MATCH, Match])
            
    end.


check_open(MemberIdList) ->
     (not arena_pvp_api:check_play_over()) andalso check_count(MemberIdList).

check_count([]) -> true;
check_count([UserId|List]) ->
    case ets:lookup(?CONST_ETS_ARENA_PVP_M, UserId) of
        [] -> check_count(List);
        [#arena_pvp_m{count = Count}] -> 
            case Count >= ?CONST_ARENA_PVP_COUNT of
                true ->false;
                _ ->
                    check_count(List)
            end
    end.
    


%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------

init([]) ->
    process_flag(trap_exit, ?true),
    init_loop(),
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(loop, State) ->
    check_timeout(),
    erlang:send_after(1000, ?MODULE, loop),
    {noreply, State};

handle_info({update_timout, IdList, TeamId}, State) ->
    arena_pvp_mod:start_update(IdList),
    arena_pvp_mod:team_player_over(IdList, TeamId),
    {?ok,Flag1,_Flag2}   = arena_pvp_mod:get_over_flag(?CONST_BATTLE_RESULT_LEFT),
    arena_pvp_mod:over_update_ets(IdList,Flag1),
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
    ?MSG_ERROR("arena cross server terminate, Reason is ~w", [Reason]),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
check_timeout() ->
    MatchList = ets:tab2list(?CONST_ETS_CROSS_ARENA_MATCH),
    check_time(MatchList, MatchList).
                
check_time([], _) ->
    ok;
check_time([Match|RestMatchList], MatchList) ->
    Now = misc:seconds(),
    StartTime = Match#arena_pvp_cross_match.start_time,
    LeaderId = Match#arena_pvp_cross_match.leader_id,
    case ets:lookup(?CONST_ETS_CROSS_ARENA_MATCH, LeaderId) of
        [] ->
            ok;
        _ ->
            Timeout3 = StartTime + ?CONST_CROSS_ARENA_TIME3,
            Timeout2 = StartTime + ?CONST_CROSS_ARENA_TIME2,
            Timeout1 = StartTime + ?CONST_CROSS_ARENA_TIME1,
            if
                Now >= Timeout3 ->
                    %% 没有匹配到合适的队伍，从匹配列表中删除
                    ets:delete(?CONST_ETS_CROSS_ARENA_MATCH, LeaderId),
                    ets:update_element(?CONST_ETS_CROSS_IN, LeaderId, {#cross_in.player_data, null}),
                    CrossIn = ets_api:lookup(?CONST_ETS_CROSS_IN, LeaderId),
                    IdList = CrossIn#cross_in.member_id_list,
                    TeamId = CrossIn#cross_in.team_id,
                    arena_pvp_mod:cross_timeout(IdList, TeamId),
                    send_match_timeout;
                Now == Timeout2 orelse Now == Timeout1 orelse Now == StartTime + 1 ->
                    %% 匹配条件放宽松，搜索是否有可以匹配的队伍
                    search(Match, MatchList);
                true ->
                    %% 跳过
                    ok
            end
    end,
    check_time(RestMatchList, MatchList).


%% 匹配是否有合适的队伍
search(_, []) ->
    ok;
search(Match1, [Match|RestMatch]) ->
    case Match1#arena_pvp_cross_match.leader_id == Match#arena_pvp_cross_match.leader_id of
        true ->
            search(Match1, RestMatch);
        false ->
            case is_match(Match1, Match) of
                true ->
                    matched(Match1, Match),
                    ets:delete(?CONST_ETS_CROSS_ARENA_MATCH, Match1#arena_pvp_cross_match.leader_id),
                    ets:delete(?CONST_ETS_CROSS_ARENA_MATCH, Match#arena_pvp_cross_match.leader_id);
                false ->
                    search(Match1, RestMatch)
            end
    end.

matched(Match1, Match2) ->
    LeaderId1 = Match1#arena_pvp_cross_match.leader_id,
    LeaderId2 = Match2#arena_pvp_cross_match.leader_id,
    CrossRec1 = ets_api:lookup(?CONST_ETS_CROSS_IN, LeaderId1),
    ets:update_element(?CONST_ETS_CROSS_IN, LeaderId1, {#cross_in.player_data, null}),
    CrossRec2 = ets_api:lookup(?CONST_ETS_CROSS_IN, LeaderId2),
    ets:update_element(?CONST_ETS_CROSS_IN, LeaderId2, {#cross_in.player_data, null}),
    BattleData1 = CrossRec1#cross_in.player_data,
    BattleData2 = CrossRec2#cross_in.player_data,
    case arena_pvp_api:check_play_over() of
        true ->ok;
        _ ->
            case battle_cross_api:start(BattleData1, BattleData2, #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA}) of
                ?ok ->
                    %% rpc 回本节点设置
                    start_notify(CrossRec1,CrossRec2);
                _ ->
                    ok
            end
    end.

send_timeout(UserId) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            ok;
        [Rec] ->
            start_notify(Rec)
    end.

start_notify(CrossRec1,CrossRec2) ->
    start_notify(CrossRec1),
    start_notify(CrossRec2).
start_notify(CrossRec) ->
    TeamId = CrossRec#cross_in.team_id,
    Node = CrossRec#cross_in.node,
    rpc:cast(Node, arena_pvp_mod, cross_battle_start, [TeamId]).
        

is_match(Match1, Match2) ->
    case is_match_a2b(Match1, Match2) andalso is_match_a2b(Match2, Match1) of
        true ->
            Id1 = Match1#arena_pvp_cross_match.leader_id,
            Id2 = Match2#arena_pvp_cross_match.leader_id,
            case ets:lookup(?CONST_ETS_CROSS_ARENA_MATCH, Id1) of
                [] ->
                    false;
                [_] ->
                    case ets:lookup(?CONST_ETS_CROSS_ARENA_MATCH, Id2) of
                        [] ->
                            false;
                        _ ->
                            true
                    end
            end;
        _ ->
            false
    end.


is_match_a2b(MatchA, MatchB) ->
    Now = misc:seconds(),
    StartTime = MatchA#arena_pvp_cross_match.start_time,
    Level = MatchA#arena_pvp_cross_match.level,
    Streak = MatchA#arena_pvp_cross_match.streak_win,
    MatchLast = Now - StartTime,
    if
        MatchLast >= ?CONST_CROSS_ARENA_TIME2 ->
            LevelDif = 10,
            StreakDif = 1000;
        MatchLast >= ?CONST_CROSS_ARENA_TIME1 ->
            LevelDif = 5,
            StreakDif = 1000;
        true ->
            LevelDif = 5,
            StreakDif = 5
    end,
    LevelMax = Level + LevelDif,
    LevelMin = Level - LevelDif,
    StreakMax = Streak + StreakDif,
    StreakMin = Streak - StreakDif,
    Level2 = MatchB#arena_pvp_cross_match.level,
    Streak2 = MatchB#arena_pvp_cross_match.streak_win,
    Level2 >= LevelMin andalso Level2 =< LevelMax andalso Streak2 >= StreakMin andalso Streak2 =< StreakMax.
    
init_loop() ->
    erlang:send_after(200, ?MODULE, loop).