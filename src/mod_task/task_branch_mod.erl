%%% 支线任务
%%% 1.只能做一次
-module(task_branch_mod).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").

-export([init_branch_task/0, confirm_branch/2, add_task/2, check_acceptable/2, 
         do_accept/2, is_accepted/2, remove_task/2, reward/2, add_sp_guild/1]).

%% ====================================================================
%% API functions
%% ====================================================================

%% 初始化支线任务
init_branch_task() ->
    #branch_task{acceptable = [], finished = [], unfinished = []}.

%% 确保支线任务正确
confirm_branch(Player, BranchTask) when is_record(BranchTask, branch_task) ->
    AcceptableTaskList   = BranchTask#branch_task.acceptable,
    Count1               = erlang:length(AcceptableTaskList),
    AcceptableTaskPacket = task_api:msg_task_info(AcceptableTaskList),
    
    UnfinishedTaskList   = task_mod:check_and_set_task_state(Player, BranchTask#branch_task.unfinished, ?CONST_TASK_POS_CONFIRM),
    Count2               = erlang:length(UnfinishedTaskList),
    UnfinishedTaskPacket = task_api:msg_task_info(UnfinishedTaskList),
    
    TotalPacket = <<AcceptableTaskPacket/binary, UnfinishedTaskPacket/binary>>,
    BranchTask2 = BranchTask#branch_task{acceptable = AcceptableTaskList, unfinished = UnfinishedTaskList},
    {BranchTask2, TotalPacket, Count1, Count2};
confirm_branch(Player, _) ->
    BranchTask = init_branch_task(),
    confirm_branch(Player, BranchTask).

%%-----------------------------------------------------------------------------------
%% 接任务的条件:
%% 1.等级
%% 2.时间段
%% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
check_acceptable(Player, TaskId) when is_number(TaskId) ->
    TaskData = Player#player.task,
    Branch   = TaskData#task_data.branch,
    List     = Branch#branch_task.acceptable,
    case lists:keyfind(TaskId, #mini_task.id, List) of
        MiniTask when is_record(MiniTask, mini_task) ->
            check_acceptable(Player, MiniTask);
        ?false ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
    end;
check_acceptable(Player, MiniTask) ->
    try
        Info    = Player#player.info,
        Lv      = Info#info.lv,
        Task    = task_api:read(MiniTask#mini_task.id),
        ?ok     = task_mod:false_throw(task_mod, is_lv_min_max, Task, Lv),  
        ?ok     = task_mod:false_throw(task_mod, is_fit_time, Task),  
        ?ok     = task_mod:false_throw(task_mod, is_acceptable_state, MiniTask),
        ?ok     = task_mod:false_throw(task_mod, is_times_over, Task),
        {?ok, MiniTask}
    catch
        throw:{?error, ErrorCode} ->
            {{?error, ErrorCode}, ?null};
        _:_ ->
            {{?error, ?TIP_COMMON_BAD_ARG}, ?null}
    end.

%%--------------------------------------接主线任务---------------------------------------------
%% 1.一接上手时，是否已经完成，假如是完成了，改任务状态
%% 2.修改任务日期
%% 3.增加任务完成次数
%% 4.打包
do_accept(Player, MiniTask) ->
    % 1
    MiniTask2   = task_mod:check_and_set_task_state(Player, MiniTask, ?CONST_TASK_POS_ACCEPT),
    % 2
    MiniTask3   = task_mod:set_task_date_time(MiniTask2),
    % 3
    MiniTask4   = task_mod:increase_task_count(MiniTask3),
    
    % 4
    TaskData    = Player#player.task,
    Branch      = TaskData#task_data.branch,
    Acceptable  = Branch#branch_task.acceptable,
    Acceptable2 = lists:keydelete(MiniTask4#mini_task.id, #mini_task.id, Acceptable),
    Unfinished  = Branch#branch_task.unfinished,
    Unfinished2 = [MiniTask4|Unfinished],
    Branch2     = Branch#branch_task{acceptable = Acceptable2, unfinished = Unfinished2},
    TaskData2   = TaskData#task_data{branch = Branch2},
    Packet      = task_api:msg_task_info(MiniTask4),
    Player2     = Player#player{task = TaskData2},
    {Player2, MiniTask4, Packet}.

%%--------------------------------------------------------------------------------------------
is_accepted(TaskData, TaskId) ->
    Branch = TaskData#task_data.branch,
    Unfinished = Branch#branch_task.unfinished,
    case lists:keyfind(TaskId, #task.id, Unfinished) of
        #mini_task{} = MiniTask ->
            {?CONST_SYS_TRUE, MiniTask};
        ?false ->
            {?CONST_SYS_FALSE, ?null}
    end.

%%--------------------------------------------------------------------------------------------
reward(Player, Task) ->
    % 1
    case task_mod:reward_goods(Player, Task#task.goods, Task#task.is_temp) of
        {?error, ErrorCode} -> {?error, ErrorCode};
        {?ok, Player2, GoodsList, PacketBag} ->
            % 2
            case reward_special(Player2, Task, ?CONST_COST_TASK_REWARD_BRANCH) of
                {?ok, Player3} -> {?ok, Player3, GoodsList, PacketBag};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

reward_special(Player, Task, Point) -> % 主线任务
    UserId         = Player#player.user_id,
    GoldBind       = Task#task.gold_bind,
    case task_mod:reward_gold_bind(UserId, GoldBind, Point) of
        ?ok ->
             %% 经验翻倍 2015-11-1
            Info     = Player#player.info,
            Lv       = Info#info.lv,

            Rate = 
            if 
                Lv =< 75 -> 2;
                % Lv =< 50 -> 2;
                true -> 1
            end, 


            {?ok, Player2} = task_mod:reward_exp(Player, Task#task.exp*Rate, Point),
            {?ok, Player3} = task_mod:reward_experience(Player2, Task#task.experience, Point),
            task_mod:reward_meritorious(Player3, Task#task.meritorious, Point);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

remove_task(Player, MiniTask) ->
    TaskData  = Player#player.task,
    Branch    = TaskData#task_data.branch,
    List1     = Branch#branch_task.unfinished,
    List2     = Branch#branch_task.finished,
    List1_2   = lists:keydelete(MiniTask#mini_task.id, #mini_task.id, List1),
    List2_2   = [MiniTask#mini_task.id|List2],
    Branch2   = Branch#branch_task{unfinished = List1_2, finished = List2_2},
    TaskData2 = TaskData#task_data{branch = Branch2},
    Player2   = Player#player{task = TaskData2},
    Packet    = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
    {Player2, Packet}.

%% 支线任务在投放时要判定两个前置任务的完成情况
%% 1. task.prev
%% 2. task_line.prev_id
%% 只要有一个不满足，就否定
add_task(Player, #task{} = Task) ->
    TaskId        = Task#task.id,
    TaskState     = Task#task.state,
    PrevId        = Task#task.prev,
    
    TaskData      = Player#player.task,
    MainTask      = task_api:mini_to_task(TaskData#task_data.main),
    Branch        = TaskData#task_data.branch,
    FinishedList  = Branch#branch_task.finished,
    % 1
    IsFitPrev     = is_finish_prev(PrevId, FinishedList, MainTask),
    % 2
    IsFitLinePrev = 
        case task_mod:read_line(TaskId) of
            #rec_task_line{prev_id = LinePrevId} ->
                is_finish_prev(LinePrevId, FinishedList);
            _ ->
                ?true
        end,
    % 3
    {NewBranch, NewTaskPacket} = 
        if
            ?true =:= IsFitPrev andalso ?true =:= IsFitLinePrev andalso ?CONST_TASK_STATE_ACCEPTABLE =:= TaskState ->
                AcceptableList  = Branch#branch_task.acceptable,
                MiniTask        = task_api:task_to_mini(Task),
                AcceptableList2 = misc:smart_insert_ignore(TaskId, MiniTask, #mini_task.id, AcceptableList),
                Branch2         = Branch#branch_task{acceptable = AcceptableList2},
                TaskPacket      = task_api:msg_task_info(MiniTask),
                {Branch2, TaskPacket};
            ?true =:= IsFitPrev andalso ?true =:= IsFitLinePrev andalso ?CONST_TASK_STATE_UNFINISHED =:= TaskState ->
                UnFinishedList  = Branch#branch_task.unfinished,
                Task2 = 
                    case task_mod:check_task_complete(Player, Task#task.target) of
                        ?true ->
                            Task#task{state = ?CONST_TASK_STATE_FINISHED};
                        ?false ->
                            Task
                    end,
                MiniTask        = task_api:task_to_mini(Task2),
                UnFinishedList2 = misc:smart_insert_ignore(TaskId, MiniTask, #mini_task.id, UnFinishedList),
                Branch2         = Branch#branch_task{unfinished = UnFinishedList2},
                TaskPacket      = task_api:msg_task_info(MiniTask),
                {Branch2, TaskPacket};
            ?true ->
                {Branch, <<>>}
        end,
    TaskData2   = TaskData#task_data{branch = NewBranch},
    Player2     = Player#player{task = TaskData2},
    {Player2, NewTaskPacket};
add_task(Player, _) ->
    {Player, <<>>}.


%% add_task(Player, Task) ->
%%     Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
%%     TaskData    = Player#player.task,
%%     Branch      = TaskData#task_data.branch,
%%     List1       = Branch#branch_task.acceptable,
%%     List1_3     =
%%         case lists:keytake(Task#task.id, #task.id, List1) of
%%             {value, _, List1_2} -> [Task|List1_2];
%%             ?false -> [Task|List1]
%%         end,
%%     Branch2     = Branch#branch_task{acceptable = List1_3},
%%     TaskData2   = TaskData#task_data{branch = Branch2},
%%     Packet      = task_api:msg_task_info(Task2),
%%     Player2     = Player#player{task = TaskData2},
%%     {Player2, Packet}.

%% 进来的任务可能是可接，或者是未完成状态，
%% 新需求要判定他的前置任务，为了兼容新系列型的支线任务
%% 那些系列型的支线会被移到不可接任务列表中
%% add_task(Player, Task = #task{state = ?CONST_TASK_STATE_ACCEPTABLE, prev = PrevId}) ->
%%     TaskData     = Player#player.task,
%%     Branch       = TaskData#task_data.branch,
%%     FinishedList = Branch#branch_task.finished,
%%     IsFitPrev    = is_finish_prev(PrevId, FinishedList),
%%     {Branch2, Packet2} = 
%%         if
%%             ?true =:= IsFitPrev ->
%%                 List1       = Branch#branch_task.acceptable,
%%                 List1_3     =
%%                     case lists:keytake(Task#task.id, #task.id, List1) of
%%                         {value, _, List1_2} -> [Task|List1_2];
%%                         ?false -> [Task|List1]
%%                     end,
%%                 Branch_2 = Branch#branch_task{acceptable = List1_3},
%%                 Packet   = task_api:msg_task_info(Task),
%%                 {Branch_2, Packet};
%%             ?true ->
%%                 UnacceptableTask  = Branch#branch_task.unacceptable,
%%                 UnacceptableTask3 =
%%                     case lists:keytake(Task#task.id, #task.id, UnacceptableTask) of
%%                         {value, _, UnacceptableTask2} -> [Task|UnacceptableTask2];
%%                         ?false -> [Task|UnacceptableTask]
%%                     end,
%%                 Branch_2 = Branch#branch_task{unacceptable = UnacceptableTask3},
%%                 {Branch_2, <<>>}
%%         end,
%%     TaskData2   = TaskData#task_data{branch = Branch2},
%%     Player2     = Player#player{task = TaskData2},
%%     {Player2, Packet2};
%% add_task(Player, Task = #task{state = ?CONST_TASK_STATE_UNFINISHED, prev = PrevId}) ->
%%     TaskData    = Player#player.task,
%%     Branch      = TaskData#task_data.branch,
%%     FinishedList = Branch#branch_task.finished,
%%     IsFitPrev    = is_finish_prev(PrevId, FinishedList),
%%     {Branch2, Packet2} = 
%%         if
%%             ?true =:= IsFitPrev ->
%%                 List1       = Branch#branch_task.unfinished,
%%                 List1_3     =
%%                     case lists:keytake(Task#task.id, #task.id, List1) of
%%                         {value, _, List1_2} -> [Task|List1_2];
%%                         ?false -> [Task|List1]
%%                     end,
%%                 Branch_2 = Branch#branch_task{unfinished = List1_3},
%%                 Packet   = task_api:msg_task_info(Task),
%%                 {Branch_2, Packet};
%%             ?true ->
%%                 UnacceptableTask  = Branch#branch_task.unacceptable,
%%                 UnacceptableTask3 =
%%                     case lists:keytake(Task#task.id, #task.id, UnacceptableTask) of
%%                         {value, _, UnacceptableTask2} -> [Task|UnacceptableTask2];
%%                         ?false -> [Task|UnacceptableTask]
%%                     end,
%%                 Branch_2 = Branch#branch_task{unacceptable = UnacceptableTask3},
%%                 {Branch_2, <<>>}
%%         end,
%%     TaskData2   = TaskData#task_data{branch = Branch2},
%%     Player2     = Player#player{task = TaskData2},
%%     {Player2, Packet2};
%% add_task(Player, #task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE}) ->
%%     {Player, <<>>}.

add_sp_guild(Player) ->
    TaskList = [data_task:get_task(TaskId)||TaskId <- ?CONST_TASK_SP_TASK_LIST],
    TaskData = Player#player.task,
    BranchList = TaskData#task_data.branch,
    Fun = fun(Task, {OldBranchList, OldPacket}) ->
                  case lists:keyfind(Task#task.id, #task.id, OldBranchList#branch_task.unfinished) of
                      ?false ->
                          case lists:member(Task#task.id, OldBranchList#branch_task.finished) of
                              ?false ->
                                  NewTask = Task#task{state = ?CONST_TASK_STATE_UNFINISHED},
                                  MiniTask = task_api:task_to_mini(NewTask),
                                  TaskPacket = task_api:msg_task_info(MiniTask),
                                  NewPacket = <<OldPacket/binary, TaskPacket/binary>>,
                                  NewUnfinishedList = [MiniTask|OldBranchList#branch_task.unfinished],
                                  NewBranchList = OldBranchList#branch_task{unfinished = NewUnfinishedList},
                                  {NewBranchList, NewPacket};
                              _ ->
                                  {OldBranchList, OldPacket}
                          end;
                      _ ->
                          {OldBranchList, OldPacket}
                  end
          end,
    {BranchList2, Packet2} = lists:foldl(Fun, {BranchList, <<>>}, TaskList),
    TaskData2 = TaskData#task_data{branch = BranchList2},
    Player2 = Player#player{task = TaskData2},
    misc_packet:send(Player2#player.net_pid, Packet2),
    Player2.

%% ====================================================================
%% Internal functions
%% ====================================================================
is_finish_prev(PrevId, FinishedList) ->
    case data_task:get_task(PrevId) of
        #task{type = ?CONST_TASK_TYPE_BRANCH} ->
                case lists:member(PrevId, FinishedList) of
                    ?true ->
                        ?true;
                    ?false ->
                        ?false
                end;
        _ ->
            ?true
    end.
is_finish_prev(PrevId, FinishedList, MainTask) ->
    MainIdx = 
        case MainTask of
            #task{idx = MainIdxT} ->
                MainIdxT;
            ?null ->
                999999;
            _ ->
                0
        end,
    case data_task:get_task(PrevId) of
        #task{type = ?CONST_TASK_TYPE_MAIN, idx = Idx} ->
                if
                    Idx < MainIdx ->
                        ?true;
                    ?true ->
                        ?false
                end;
        #task{type = ?CONST_TASK_TYPE_BRANCH} ->
                case lists:member(PrevId, FinishedList) of
                    ?true ->
                        ?true;
                    ?false ->
                        ?false
                end;
        _ ->
            ?true
    end.
%% 
%% change_acc(Branch) ->
%%     Unacc = Branch#branch_task.unacceptable,
%%     Acc   = Branch#branch_task.acceptable,
%%     FinishedList = Branch#branch_task.finished,
%%     {AcceptableList, UnacceptableList}  = change_acc_2(Unacc, {Acc, []}, FinishedList),
%%     Branch#branch_task{acceptable = AcceptableList, unacceptable = UnacceptableList}.
%% 
%% change_acc_2([0|Tail], {AcceptableList, OldList}, FinishedList) ->
%%     change_acc_2(Tail, {[0|AcceptableList], OldList}, FinishedList);
%% change_acc_2([#task{id = TaskId, prev = PrevId} = Task|Tail], {AcceptableList, OldList}, FinishedList) ->
%%     IsFitPrev = is_finish_prev(PrevId, FinishedList),
%%     {AccTaskList, UnaccTaskList} = 
%%         if
%%             ?true =:= IsFitPrev ->
%%                 case lists:keytake(TaskId, #task.id, AcceptableList) of
%%                     ?false ->
%%                         {[Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE}|AcceptableList], OldList};
%%                     {value, _Tuple, AcceptableListT} ->
%%                         {[Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE}|AcceptableListT], OldList}
%%                 end;
%%             ?true ->
%%                 {AcceptableList, [Task|OldList]}
%%         end,
%%     change_acc_2(Tail, {AccTaskList, UnaccTaskList}, FinishedList);
%% change_acc_2([], {AcceptableList, OldList}, _) -> {AcceptableList, OldList}.
