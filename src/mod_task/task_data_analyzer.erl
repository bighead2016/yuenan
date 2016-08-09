%%% 任务数据分析器
%%% 1.主要输出剩下的永远不会被调用的任务
%%% 2.假如有死循环的话，在分析时，直接会死循环 -- 极端明显。。。
%%% 3.假如是读取不到对应任务的话，直接假匹配错误 -- 直接点好。。。
%%% 以上3个点是任务最主要的问题所在，剩下的还有错误就除了运行时的，就是其他方面的，定位比较好
%%%-----------------------------------------------------------------------

-module(task_data_analyzer).
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.map.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([analyze/1]).
%% task_data_analyzer:analyze().
analyze(_Ver) ->
    case analyze_task_record() of
        ok ->
            ProList 		= get_pro_list(),
            [_|MainList]   	= data_task:get_main_task_id_list(),
            BranchList 		= data_task:get_branch_id_list(),
            PositionList 	= [], %data_task:get_position_id_list(),
            DailyCycle		= data_task:get_daily_lib_id_list(),
            GuildCycle 		= data_task:get_guild_lib_id_list(),
			EveryDayList	= data_task:get_everyday_id_list(),
            % 1
            analyze(ProList, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList),
            % 2
            [analyze_one(Pro, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList)||Pro<-ProList],
            % 3
            analyze_reward(),
            ok;
        error ->
            ok
    end.

analyze([Pro|Tail], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList) ->
    PlayerInit = data_player:get_player_init({Pro, 1}),
    InitTaskId = PlayerInit#rec_player_init.task,
    Task       = data_task:get_task(InitTaskId),
    {MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2} = 
        next(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, Pro),
    analyze(Tail, MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2);
analyze([], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList) ->
    io:format("Main=~p, ~nBranch=~p, ~nPosition=~p, ~nDaily=~p, ~nGuild=~p, ~nEveryDayList=~p~n", [MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList]),
    ok.

next(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, Pro) when is_record(Task, task) ->
    NextTask = 
        case Task#task.next of
            NextId when is_number(NextId) ->
                data_task:get_task(NextId);
            NextTuple when is_tuple(NextTuple) ->
                NextId = erlang:element(Pro, NextTuple),
                data_task:get_task(NextId);
            NextList when is_list(NextList) ->
                NextList
        end,
    {MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2, _ResultList2, NextMainTask} = 
        get_next_list(NextTask, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, [], Pro, 0),
    next(NextMainTask, MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2, Pro);
next(_, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, _Pro) ->
    {MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList}.

get_next_list([Task|Tail], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NextMainTask) when is_record(Task, task) -> % 任务列表,这种情况有可能是各种类型的任务
    {NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, NewNextMainTask} = 
        get_next_list_inner(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NextMainTask),
    get_next_list(Tail, NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, Pro, NewNextMainTask);
get_next_list(?null, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, _Pro, NewNextMainTask) -> % 临时加的
	{MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NewNextMainTask};
%%     get_next_list(Tail, MainList, BranchList, PositionList, DailyCycle, GuildCycle, ResultList, Pro, NewNextMainTask);
get_next_list([TaskId|Tail], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NextMainTask) when is_number(TaskId) ->
    Task = data_task:get_task(TaskId),
    {NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, NewNextMainTask} = 
        get_next_list_inner(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NextMainTask),
    get_next_list(Tail, NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, Pro, NewNextMainTask);
get_next_list([TaskTuple|Tail], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NextMainTask) when is_tuple(TaskTuple) ->
    TaskId = erlang:element(Pro, TaskTuple),
    Task = data_task:get_task(TaskId),
    {NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, NewNextMainTask} = 
        get_next_list_inner(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NextMainTask),
    get_next_list(Tail, NewMainList, NewBranchList, NewPositionList, NewDailyCycle, NewGuildCycle, NewEveryDayList, NewResultList, Pro, NewNextMainTask);
get_next_list([], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, _Pro, NewNextMainTask) ->
    {MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NewNextMainTask};
get_next_list(TaskId, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NewNextMainTask) when is_number(TaskId) -> % 单一任务
    Task = data_task:get_task(TaskId),
    get_next_list([Task], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NewNextMainTask);
get_next_list(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NewNextMainTask) when is_record(Task, task) -> % 单一任务
    get_next_list([Task], MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, Pro, NewNextMainTask).

get_next_list_inner(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NextMainTask) ->
    try
        TaskId = Task#task.id,
        case Task#task.type of
            ?CONST_TASK_TYPE_MAIN -> % 主线任务的话，直接从主线那删除掉就好了
                MainList2 = lists:delete(TaskId, MainList),
                ResultList2 = [Task|ResultList],
                {MainList2, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList2, Task};
            ?CONST_TASK_TYPE_BRANCH -> % 支线也是, 无后续任务
                BranchList2 = lists:delete(TaskId, BranchList),
                {MainList, BranchList2, PositionList, DailyCycle, GuildCycle, EveryDayList, ResultList, NextMainTask};
            ?CONST_TASK_TYPE_POSITION ->
                PositionList2 = lists:delete(TaskId, PositionList),
                ResultList2 = [Task|ResultList],
                {MainList, BranchList, PositionList2, DailyCycle, GuildCycle, EveryDayList, ResultList2, NextMainTask};
            ?CONST_TASK_TYPE_EVERYDAY ->
                {random, TaskLibId} = Task#task.next, 
                RecTaskLib = data_task:get_task_lib(TaskLibId),
                (?CONST_TASK_TYPE_EVERYDAY = RecTaskLib#rec_task_lib.type), 
                (1 = Task#task.ignore),
                TaskList = RecTaskLib#rec_task_lib.tasks,
                F = fun(Tid, List) ->
                            lists:delete(Tid, List)
                    end,
                DailyCycle2 = lists:foldl(F, DailyCycle, TaskList),
                {MainList, BranchList, PositionList, DailyCycle2, GuildCycle, EveryDayList, ResultList, NextMainTask};
            ?CONST_TASK_TYPE_GUILD ->
                {random, TaskLibId} = Task#task.next, 
                RecTaskLib = data_task:get_task_lib(TaskLibId),
                (?CONST_TASK_TYPE_GUILD = RecTaskLib#rec_task_lib.type), 
                (1 = Task#task.ignore),
                TaskList = RecTaskLib#rec_task_lib.tasks,
                F = fun(Tid, List) ->
                            lists:delete(Tid, List)
                    end,
                GuildCycle2 = lists:foldl(F, GuildCycle, TaskList),
                {MainList, BranchList, PositionList, DailyCycle, GuildCycle2, EveryDayList, ResultList, NextMainTask};
			?CONST_TASK_TYPE_EVERYDAY1 ->
				EveryDayList2 = lists:delete(TaskId, EveryDayList),
                {MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList2, ResultList, NextMainTask}
        end
    catch
        X:Y ->
            io:format("x=~p~ny=~p~ne=~p~ntask=~p", [X, Y, erlang:get_stacktrace(), Task])
    end.

%%------------------------------------------------------------------------------------
analyze_one(Pro, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList) ->
    PlayerInit = data_player:get_player_init({Pro, 1}),
    InitTaskId = PlayerInit#rec_player_init.task,
    Task       = data_task:get_task(InitTaskId),
    {MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2} = 
        next(Task, MainList, BranchList, PositionList, DailyCycle, GuildCycle, EveryDayList, Pro),
    io:format("----------~p------------------~nm=~p, ~nb=~p, ~np=~p, ~nd=~p, ~nd=~p, ~ng=~p~n", 
              [Pro, MainList2, BranchList2, PositionList2, DailyCycle2, GuildCycle2, EveryDayList2]).

%%------------------------------------------------------------------------------------
analyze_reward() ->
    TaskList = data_task:get_all(),
    [analyze_reward(Task)||Task<-TaskList],
    ok.
    
analyze_reward(TaskId) when is_number(TaskId) ->
    Task = data_task:get_task(TaskId),
    % 1
    GoodsTupleList = Task#task.goods,
    check_goods(GoodsTupleList, Task),
    % 2
    PartnerIdList = Task#task.partner ++ Task#task.partner_look_for,
    check_partner(PartnerIdList, Task),
    % 3
    CopyId = Task#task.copy_id,
    check_copy(CopyId, Task),
    % 4
    Target = Task#task.target,
    check_target(Target, Task),
    ok.

%%-------------------------------------------------------------------------------------------
analyze_task_record() ->
    TaskList = data_task:get_all(),
    try
        [analyze_task_record(TaskId)||TaskId<-TaskList],
        ok
    catch
        throw:{error, X} ->
            io:format(X),
            error
    end.

analyze_task_record(TaskId) ->
    case data_task:get_task(TaskId) of
        #task{next = TaskList} when is_list(TaskList) ->
            [begin
                 case data_task:get_task(NextId) of
                    #task{} ->
                        ok;
                    X ->
                        throw({error, io_lib:format("!err:task_id=[~p]'s next[~p] is not a task,it's [~p]~n", [TaskId, NextId, X])})
                end
             end||NextId<-TaskList];
        #task{next = 0} -> ok;
        #task{next = {random, _}} -> ok;
        #task{next = {N1, N2, N3}} ->
            case data_task:get_task(N1) of
                #task{} ->
                    ok;
                X1 ->
                    throw({error, io_lib:format("!err:task_id=[~p]'s next[~p] is not a task,it's [~p]~n", [TaskId, N1, X1])})
            end,
            case data_task:get_task(N2) of
                #task{} ->
                    ok;
                X2 ->
                    throw({error, io_lib:format("!err:task_id=[~p]'s next[~p] is not a task,it's [~p]~n", [TaskId, N2, X2])})
            end,
            case data_task:get_task(N3) of
                #task{} ->
                    ok;
                X3 ->
                    throw({error, io_lib:format("!err:task_id=[~p]'s next[~p] is not a task,it's [~p]~n", [TaskId, N3, X3])})
            end;
        #task{next = NextId} ->
            case data_task:get_task(NextId) of
                #task{} ->
                    ok;
                X ->
                    throw({error, io_lib:format("!err:task_id=[~p]'s next[~p] is not a task,it's [~p]~n", [TaskId, NextId, X])})
            end;
        X ->
            throw({error, io_lib:format("!err:task_id=[~p] is not a task,it's [~p]~n", [TaskId, X])})
    end.
    
    
    
%% ====================================================================
%% Internal functions
%% ====================================================================
get_pro_list() -> lists:seq(1, 3).

check_goods(0, _Task) ->
    ok;
check_goods([{_, _, GoodsId, _, _}|Tail], Task) ->
    case is_record(data_goods:get_goods(GoodsId), goods) of
        true ->
            ok;
        false ->
            io:format("!err:task=~p reward goods=~p is not exist~n", [Task, GoodsId])
    end,
    check_goods(Tail, Task);
check_goods([], _) ->
    ok.

check_partner([0|Tail], Task) ->
    check_partner(Tail, Task);
check_partner([PartnerId|Tail], Task) ->
    case is_record(data_partner:get_base_partner(PartnerId), partner) of
        true ->
            ok;
        false ->
            io:format("!err:task=~p reward partner=~p is not exist~n", [Task, PartnerId])
    end,
    check_partner(Tail, Task);
check_partner([], _) ->
    ok.

check_copy(0, _Task) ->
    ok;
check_copy(CopyId, Task) ->
    case is_record(data_copy_single:get_copy_single(CopyId), rec_copy_single) of
        true ->
            ok;
        false ->
            io:format("!err:task=~p, reward copy_id=~p is not exit~n", [Task, CopyId])
    end.

check_target([#task_target{target_type = ?CONST_TASK_TARGET_KILL, as1 = MapId, as2 = MonId, as5 = CopyId}|Tail], Task) ->
    case data_copy_single:get_copy_single(CopyId) of
        #rec_copy_single{monster = MonTuple1, monster2 = MonTuple2, map = MapId2} ->
            check_mons(MonTuple1, Task#task.id, 1),
            check_mons(MonTuple2, Task#task.id, 2),
            if
                MapId =:= MapId2 ->
                    ok;
                true ->
                    io:format("!err:task=~p map is not fit[~p->~p]~n", [Task#task.id, MapId, MapId2])
            end;
        null ->
            check_mons_camp(MonId, Task#task.id, 1)
    end,
    check_target(Tail, Task);
check_target([_|Tail], Task) ->
    check_target(Tail, Task);
check_target([], _Task) ->
	ok.

check_mons({{MonId, _}}, TaskId, N) ->
    case data_monster:get_monster(MonId) of
        #monster{camp = #camp{position = Camp}} ->
            MonList = misc:to_list(Camp),
            check_mons_list(MonList, TaskId, N),
            ok;
        _ ->
            ok
    end;
check_mons({{MonId, _}, {MonId2, _}}, TaskId, N) ->
    check_mons_camp(MonId, TaskId, N),
    check_mons_camp(MonId2, TaskId, N);
check_mons({{MonId, _}, {MonId2, _}, {MonId3, _}}, TaskId, N) ->
    check_mons_camp(MonId, TaskId, N),
    check_mons_camp(MonId2, TaskId, N),
    check_mons_camp(MonId3, TaskId, N);
check_mons(_, _, _) ->
    ok.

check_mons_camp(0, _TaskId, _N) -> ok;
check_mons_camp(#camp_pos{id = MonId}, TaskId, N) ->
    check_mons_camp(MonId, TaskId, N);
check_mons_camp(MonId, TaskId, N) ->
    case data_monster:get_monster(MonId) of
        #monster{camp = #camp{position = Camp}} ->
            MonList = misc:to_list(Camp),
            check_mons_list(MonList, TaskId, N);
        _ ->
            ok
    end.

check_mons_list([#camp_pos{id = MonId}|Tail], TaskId, N) ->
    case check_mon(MonId) of
        ok ->
            ok;
        false ->
            io:format("!err:[~p]task[~p] [~p]wave monster[~p] is not exist~n", [?LINE, TaskId, N, MonId])
    end,
    check_mons_list(Tail, TaskId, N);
check_mons_list([0|Tail], TaskId, N) ->
    check_mons_list(Tail, TaskId, N);
check_mons_list([], _, _) ->
    ok.

check_mon(0) -> ok;
check_mon(MonId) ->
    case data_monster:get_monster(MonId) of
        #monster{} ->
            ok;
        _ ->
            false
    end.
        
            
    
    
    
    
    
    