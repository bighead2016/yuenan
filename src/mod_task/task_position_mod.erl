%%% 官衔任务处理
-module(task_position_mod).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.player.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([init_position_task/0, confirm_position/4, add_task/2, check_acceptable/2,
         do_accept/2, get_unfinished_count/1, is_accepted/2, remove_task/2, reward/2,
         upgrade_position/3, do_level_up/1]).

%% 初始化官衔任务
init_position_task() ->
    0.

%% 官衔任务
confirm_position(PositionTask, _, _, _) when is_record(PositionTask, mini_task) ->
    CurrentTask = PositionTask,
    Packet      = task_api:msg_task_info(CurrentTask),
    {Count1, Count2} = get_unfinished_count(PositionTask),
    {CurrentTask, Packet, Count1, Count2};
%% confirm_position(_, 10000, Lv, Pos) ->
%%     NewTask = 
%%         case data_task:get_task(10337) of
%%             #task{} = Task ->
%%                 if
%%                     Lv >= Task#task.lv_min andalso Pos >= 7 ->
%%                         Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
%%                     ?true ->
%%                         0
%%                 end;
%%             _ ->
%%                 0
%%         end,
%%     Packet      = task_api:msg_task_info(NewTask),
%%     {Count1, Count2} = get_unfinished_count(NewTask),
%%     {NewTask, Packet, Count1, Count2};
%% confirm_position(_, 13000, Lv, Pos) ->
%%     NewTask = 
%%         case data_task:get_task(10341) of
%%             #task{} = Task ->
%%                 if
%%                     Lv >= Task#task.lv_min andalso Pos >= 12 ->
%%                         Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
%%                     ?true ->
%%                         case data_task:get_task(10338) of
%%                             #task{} = Task2 ->
%%                                 Task2#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE};
%%                             _ ->
%%                                 0
%%                         end
%%                 end;
%%             _ ->
%%                 0
%%         end,
%%     Packet      = task_api:msg_task_info(NewTask),
%%     {Count1, Count2} = get_unfinished_count(NewTask),
%%     {NewTask, Packet, Count1, Count2};
%% confirm_position(_, 15000, Lv, Pos) ->
%%     NewTask = 
%%         case data_task:get_task(10346) of
%%             #task{} = Task ->
%%                 if
%%                     Lv >= Task#task.lv_min andalso Pos >= 24 ->
%%                         Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
%%                     ?true ->
%%                         case data_task:get_task(10342) of
%%                             #task{} = Task2 ->
%%                                 Task2#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE};
%%                             _ ->
%%                                 0
%%                         end
%%                 end;
%%             _ ->
%%                 0
%%         end,
%%     Packet      = task_api:msg_task_info(NewTask),
%%     {Count1, Count2} = get_unfinished_count(NewTask),
%%     {NewTask, Packet, Count1, Count2};
confirm_position(PositionTask, _, _, _) ->
    Packet      = task_api:msg_task_info(PositionTask),
    {Count1, Count2} = get_unfinished_count(PositionTask),
    {PositionTask, Packet, Count1, Count2}.

%%-----------------------------------------------------------------------------------
%% 接任务的条件:
%% 1.等级
%% 2.时间段
%% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
check_acceptable(Player, TaskId) when is_number(TaskId) ->
    TaskData = Player#player.task,
    PositionTask = TaskData#task_data.position_task,
    case is_record(PositionTask, mini_task) of
        ?true ->
            if
                PositionTask#mini_task.id =:= TaskId ->
                    check_acceptable(Player, PositionTask);
                ?true ->
                    {{?error, ?TIP_TASK_NOT_ACCEPT}, ?null}
            end;
        _ ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
    end;
check_acceptable(Player, MiniTask) ->
    try
        Info     = Player#player.info,
        Lv       = Info#info.lv,
        AttrRate = Info#info.attr_rate,
        Task     = task_api:read(MiniTask#mini_task.id),
        ?ok      = task_mod:false_throw(task_mod, is_fit_rate, Task, AttrRate),
        ?ok      = task_mod:false_throw(task_mod, is_lv_min_max, Task, Lv),  
        ?ok      = task_mod:false_throw(task_mod, is_fit_time, Task),  
        ?ok      = task_mod:false_throw(task_mod, is_acceptable_state, MiniTask),
        ?ok      = task_mod:false_throw(task_mod, is_times_over, Task),
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
    TaskData2   = TaskData#task_data{position_task = MiniTask4},
    Packet      = task_api:msg_task_info(MiniTask4),
    Player2     = Player#player{task = TaskData2},
    {Player2, MiniTask4, Packet}.

%%--------------------------------------------------------------------------------------------
is_accepted(TaskData, TaskId) when 0 =/= TaskId andalso is_record(TaskData#task_data.position_task, mini_task) ->
    PositionTask = TaskData#task_data.position_task,
    if
        PositionTask#mini_task.id =:= TaskId ->
            {?CONST_SYS_TRUE, PositionTask};
        ?true ->
            {?CONST_SYS_FALSE, ?null}
    end;
is_accepted(_TaskData, _TaskId) ->
    {?CONST_SYS_FALSE, ?null}.
    
%%--------------------------------------------------------------------------------------------
reward(Player, Task) ->
    % 1
    case task_mod:reward_goods(Player, Task#task.goods, Task#task.is_temp) of
        {?error, ErrorCode} -> {?error, ErrorCode};
        {?ok, Player2, GoodsList, PacketBag} ->
            % 2
            case reward_special(Player2, Task, ?CONST_COST_TASK_REWARD_POSITION) of
                {?ok, Player3} -> {?ok, Player3, GoodsList, PacketBag};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

reward_special(Player, Task, Point) ->
    case task_mod:reward_gold_bind(Player#player.user_id, Task#task.gold_bind, Point) of
        ?ok ->
            {?ok, Player2}  = task_mod:reward_attr_rate(Player, Task#task.attr_rate),
            {?ok, Player3}  = task_mod:reward_exp(Player2, Task#task.exp, Point),
            {?ok, Player4}  = task_mod:reward_experience(Player3, Task#task.experience, Point),
            task_mod:reward_meritorious(Player4, Task#task.meritorious, Point);
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

remove_task(Player, MiniTask) ->
    TaskData    = Player#player.task,
    TaskData2   = TaskData#task_data{position_task = ?null},
    Player2     = Player#player{task = TaskData2},
    Packet      = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
    {Player2, Packet}.

add_task(Player, Task) ->
    TaskData    = Player#player.task,
    Info = Player#player.info,
    Lv = Info#info.lv,
    AttrRate = Info#info.attr_rate,
    PositionData = Player#player.position,
    PositionId = PositionData#position_data.position,
    if
        Task#task.require_attr_rate =< AttrRate andalso Task#task.position_id =< PositionId 
          andalso Task#task.lv_min =< Lv andalso Lv =< Task#task.lv_max ->
            Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            MiniTask    = task_api:task_to_mini(Task2),
            TaskData2   = TaskData#task_data{position_task = MiniTask},
            Packet      = task_api:msg_task_info(MiniTask),
            Player2     = Player#player{task = TaskData2},
            {Player2, Packet};
        ?true ->
            Task2       = Task#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE},
            MiniTask    = task_api:task_to_mini(Task2),
            TaskData2   = TaskData#task_data{position_task = MiniTask},
            Player2     = Player#player{task = TaskData2},
            {Player2, <<>>}
    end.

%%-------------------------------------------------------官衔任务------------------------------
%% 官衔升级刷新任务
%% 1.存在任务
%% 2.向前端发送任务 - 因为之前隐藏了，所以现在要提醒下前端
upgrade_position(Player, [TaskId|Tail], PositionIdNext) ->
    Player2 = upgrade_position(Player, TaskId, PositionIdNext),
    upgrade_position(Player2, Tail, PositionIdNext);
upgrade_position(Player, [], _PositionIdNext) ->
    Player;
upgrade_position(Player, TaskId, PositionIdNext) when 0 =/= TaskId ->
    % 1
    TaskData    = Player#player.task,
    Info        = Player#player.info,
    AttrRate    = Info#info.attr_rate,
    Lv          = Info#info.lv,
    Task        = task_mod:read(TaskId),
    TaskData    = Player#player.task,
    PositionTask = TaskData#task_data.position_task,
    Task3       = 
        if
            (?null =:= PositionTask orelse 0 =:= PositionTask) 
              andalso Task#task.require_attr_rate =< AttrRate 
              andalso Task#task.position_id =< PositionIdNext
              andalso 0 =:= Task#task.prev
              andalso Task#task.lv_min =< Lv ->
                Task2  = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
                MiniTask = task_api:task_to_mini(Task2),
                Packet = task_api:msg_task_info(MiniTask),
                UserId = Player#player.user_id,
                misc_packet:send(UserId, Packet),
                MiniTask;
            Task#task.require_attr_rate =< AttrRate 
              andalso TaskId =:= PositionTask#mini_task.id
              andalso Task#task.position_id =< PositionIdNext
              andalso Task#task.lv_min =< Lv ->
                Task2  = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
                MiniTask = task_api:task_to_mini(Task2),
                Packet = task_api:msg_task_info(MiniTask),
                UserId = Player#player.user_id,
                misc_packet:send(UserId, Packet),
                MiniTask;
            Task#task.require_attr_rate =< AttrRate 
              andalso (0 =:= PositionTask orelse TaskId =:= PositionTask#mini_task.id)
              andalso Task#task.position_id =< PositionIdNext
              andalso Lv < Task#task.lv_min ->
                Task2  = Task#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE},
                task_api:task_to_mini(Task2);
            ?true ->
                PositionTask
        end,
    TaskData2 = TaskData#task_data{position_task = Task3},
    Player#player{task = TaskData2}.

%% 人物等级时处理
do_level_up(Player) ->
    % 1
    TaskData    = Player#player.task,
    Info        = Player#player.info,
    AttrRate    = Info#info.attr_rate,
    Lv          = Info#info.lv,
    PositionTask = TaskData#task_data.position_task,
    Task         = 
        case PositionTask of
            #mini_task{} ->
                task_api:read(PositionTask#mini_task.id);
            _ ->
                PositionTask
        end,
    PositionData = Player#player.position,
    PositionId   = PositionData#position_data.position,
    if
        Task#task.require_attr_rate =< AttrRate 
          andalso ?CONST_TASK_STATE_NOT_ACCEPTABLE =:= PositionTask#mini_task.state 
          andalso Task#task.position_id =< PositionId
          andalso Task#task.lv_min =< Lv ->
            PositionTask2  = PositionTask#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            Packet = task_api:msg_task_info(PositionTask2),
            {PositionTask2, Packet};
        ?true ->
            {PositionTask, <<>>}
    end.

%% ====================================================================
%% Internal functions
%% ====================================================================
get_unfinished_count(PositionTask) ->
    CurrentTask = PositionTask,
    if
        0 =/= CurrentTask andalso ?CONST_TASK_STATE_ACCEPTABLE =:= CurrentTask#mini_task.state ->
            {1, 0};
        0 =/= CurrentTask andalso ?CONST_TASK_STATE_UNFINISHED =:= CurrentTask#mini_task.state ->
            {0, 1};
        ?true ->
            {0, 0}
    end.

