%%% 主线处理
%%% 1.任务必然是从第一个任务开始做到最后一个，中间不能断
%%% 2.等级不足时，任务状态会变为"不可接"；当等级够了以后，会变为"可接"
%%% 3.最后一个任务会设为0

-module(task_main_mod).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.player.hrl").

-export([init_main_task/1, confirm_main/4, check_acceptable/2, do_accept/2, is_accepted/2,
         reward/2, remove_task/2, add_task/2, do_level_up/1]).

%% ====================================================================
%% API functions
%% ====================================================================

%%-----------------------------------------------------------------------------------
%% 初始化主线任务
init_main_task(TaskId) ->
    Task = task_mod:read(TaskId),
    task_api:task_to_mini(Task).

%%-----------------------------------------------------------------------------------
%% 确保是个任务
%% {Task, Packet, Count, Count2}/{0, <<>>, 0, 0}
confirm_main(MiniTask, _Idx, _Pro, Lv) 
  when is_record(MiniTask, mini_task) ->
    case task_api:mini_to_task(MiniTask) of
        #task{type = ?CONST_TASK_TYPE_MAIN, 
              state = ?CONST_TASK_STATE_NOT_ACCEPTABLE,
              lv_min = LvMin} when LvMin =< Lv -> % 等级又够了
            MiniTask2 = MiniTask#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            Packet	= task_api:msg_task_info(MiniTask2),
            {MiniTask2, Packet, 1, 0};
        #task{type = ?CONST_TASK_TYPE_MAIN, 
              state = ?CONST_TASK_STATE_NOT_ACCEPTABLE} -> % 等级还是不够
	        Packet	= task_api:msg_task_info(MiniTask),
            {MiniTask, Packet, 1, 0};
        #task{type = ?CONST_TASK_TYPE_MAIN, 
              state = ?CONST_TASK_STATE_ACCEPTABLE} ->
            Packet = task_api:msg_task_info(MiniTask),
            {MiniTask, Packet, 1, 0};
        #task{type = ?CONST_TASK_TYPE_MAIN, 
              state = ?CONST_TASK_STATE_UNFINISHED} ->
            Packet = task_api:msg_task_info(MiniTask),
            {MiniTask, Packet, 0, 1};
        #task{type = ?CONST_TASK_TYPE_MAIN, 
              state = ?CONST_TASK_STATE_FINISHED} ->
            Packet = task_api:msg_task_info(MiniTask),
            {MiniTask, Packet, 0, 1};
        #task{idx = Idx, pro = Pro} ->
            Task   = recover_task_main(Idx, Pro, Lv),
            MiniTask2 = task_api:task_to_mini(Task),
            Packet = task_api:msg_task_info(MiniTask2),
            {MiniTask2, Packet, 1, 0}
    end;
confirm_main(Task, Idx, Pro, Lv) ->
    Task   = recover_task_main(Idx, Pro, Lv),
    MiniTask = task_api:task_to_mini(Task),
    Packet = task_api:msg_task_info(MiniTask),
    {MiniTask, Packet, 1, 0}.

recover_task_main(Idx, Pro, Lv) when 0 < Lv andalso Lv =< ?CONST_SYS_PLAYER_LV_MAX ->
	case recover_select_task_main(Idx, Pro) of
		Task = #task{lv_min = LvMin} ->
			if
				LvMin =< ?CONST_SYS_PLAYER_LV_MAX ->
					if
						LvMin =< Lv -> Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
						?true -> Task#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE}
					end;
				?true -> ?null
			end;
		_ -> ?null
	end;
recover_task_main(_Idx,_Pro, _) -> ?null.

recover_select_task_main(Idx, Pro) ->
	case task_mod:get_main_task(Pro, Idx) of
		?null -> ?null;
		Next -> select_task_main(Next, Pro)
	end.

select_task_main(TaskId, _Pro) when is_number(TaskId) ->
    case task_mod:read(TaskId) of
        TaskNext = #task{type = ?CONST_TASK_TYPE_MAIN} -> TaskNext;
        _ -> ?null
    end;
select_task_main({random, TaskLibId}, Pro) ->
    TaskId	= task_mod:get_next_lib_task(TaskLibId),
    select_task_main(TaskId, Pro);
select_task_main(TaskTuple, Pro) when is_tuple(TaskTuple) ->
    TaskId	= erlang:element(Pro, TaskTuple),
    select_task_main(TaskId, Pro);
select_task_main([TaskId|TaskIdList], Pro) ->
    case select_task_main(TaskId, Pro) of
		?null -> select_task_main(TaskIdList, Pro);
		TaskNext -> TaskNext
	end;
select_task_main([], _Pro) -> ?null.

do_level_up(Player) ->
    Info     = Player#player.info,
    Lv       = Info#info.lv,
    TaskData = Player#player.task,
    MainTask = TaskData#task_data.main,
    case MainTask of
        _ when is_record(MainTask, mini_task) ->
            State    = MainTask#mini_task.state,
            RecTask  = task_api:read(MainTask#mini_task.id),
            if
                RecTask#task.lv_min =< Lv andalso ?CONST_TASK_STATE_NOT_ACCEPTABLE =:= State ->
                    MainTask2 = MainTask#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE},
                    Packet = task_api:msg_task_info(MainTask2),
                    UserId = Player#player.user_id,
                    misc_packet:send(UserId, Packet),
                    MainTask2;
                ?true ->
                    MainTask
            end;
        _ ->
            MainTask
    end.

%%-----------------------------------------------------------------------------------
%% 接任务的条件:
%% 1.等级
%% 2.时间段
%% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
check_acceptable(Player, TaskId) when is_number(TaskId) ->
    TaskData = Player#player.task,
    MainTask = TaskData#task_data.main,
    if
        MainTask#mini_task.id =:= TaskId ->
            check_acceptable(Player, MainTask);
        ?true ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
    end;
check_acceptable(Player, MiniTask) ->
    try
        Info    = Player#player.info,
        Lv      = Info#info.lv,
        Task    = task_api:read(MiniTask#mini_task.id),
        ?ok     = task_mod:false_throw(task_mod, is_lv_min_max, Task, Lv),
        ?ok     = task_mod:false_throw(task_mod, is_fit_time, Task),
%%         ?ok     = task_mod:false_throw(task_mod, is_acceptable_state, MiniTask),
        {?ok, MiniTask}
    catch
        throw:{?error, ErrorCode} ->
            {{?error, ErrorCode}, ?null};
        Type:Error ->
			?MSG_ERROR("~nType:~p~nError:~p~nStrace:~p~n", [Type, Error, erlang:get_stacktrace()]),
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
    RecTask     = task_api:read(MiniTask4#mini_task.id),
    TaskData2   = TaskData#task_data{main = MiniTask4, main_idx = RecTask#task.idx},
    Packet      = task_api:msg_task_info(MiniTask4),
    Player2     = Player#player{task = TaskData2},
    {Player2, MiniTask4, Packet}.

%%--------------------------------------------------------------------------------------------
is_accepted(TaskData, TaskId) when (TaskData#task_data.main)#mini_task.id =:= TaskId ->
    TaskMain = TaskData#task_data.main,
    {?CONST_SYS_TRUE, TaskMain};
is_accepted(_TaskData, _TaskId) ->
    {?CONST_SYS_FALSE, ?null}.

%%--------------------------------------------------------------------------------------------
reward(Player, Task) ->
    % 1
    case task_mod:reward_goods(Player, Task#task.goods, Task#task.is_temp) of
        {?error, ErrorCode} -> {?error, ErrorCode};
        {?ok, Player2, GoodsList, PacketBag} ->
            % 2
            case reward_special(Player2, Task, ?CONST_COST_TASK_REWARD_MAIN) of
                {?ok, Player3} ->
                    {?ok, Player3, GoodsList, PacketBag};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end
    end.

reward_special(Player, Task, Point) -> % 主线任务
    case task_mod:reward_gold_bind(Player#player.user_id, Task#task.gold_bind, Point) of
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
            {?ok, Player4} = task_mod:reward_partner(Player3, Task#task.partner, Task#task.need_show), 
            task_mod:reward_meritorious(Player4, Task#task.meritorious, Point);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

remove_task(Player, MiniTask) ->
    TaskData = Player#player.task,
    MainTask = TaskData#task_data.main,
    TaskId   = MainTask#mini_task.id,
    if
        TaskId =:= MiniTask#mini_task.id ->
            TaskData  = Player#player.task,
            TaskData2 = TaskData#task_data{main = ?null},
            Packet    = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
            Player2   = Player#player{task = TaskData2},
            {Player2, Packet};
        ?true ->
            {Player, <<>>}
    end.

add_task(Player, 0) ->
    TaskData    = Player#player.task,
    TaskData2   = TaskData#task_data{main = 0},
    Player2     = Player#player{task = TaskData2},
    {Player2, <<>>};
add_task(Player, Task) ->
    LvMin 		= Task#task.lv_min,
    Info 		= Player#player.info,
    Lv 			= Info#info.lv,
    Task2   = 
        if
            LvMin =< Lv -> Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
            ?true -> Task#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE}
        end,
    TaskData    = Player#player.task,
    MiniTask    = task_api:task_to_mini(Task2),
    TaskData2   = TaskData#task_data{main = MiniTask},
    Packet      = task_api:msg_task_info(MiniTask),
    Player2     = Player#player{task = TaskData2},
    {Player2, Packet}.
