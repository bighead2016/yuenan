%%% 日常任务


-module(task_daily_mod).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.player.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([init_daily_cycle_task/0, confirm_daily_cycle/4, 
         add_task/2, check_acceptable/2, do_accept/2, is_accepted/2,
         remove_task/2, reward/2]).

%% 初始化日常环任务
init_daily_cycle_task() ->
    task_cycle_mod:init_task_cycle().

%% 日常环
confirm_daily_cycle(_Player, CycleTask, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =/= Today andalso
	   CycleTask#task_cycle.lib_id =/= 0 ->
       Cur = CycleTask#task_cycle.current,
    case Cur of
        #mini_task{id = TaskId} ->
            case task_api:read(TaskId) of
                #task{type = ?CONST_TASK_TYPE_EVERYDAY} ->
                    CycleTask2      	= task_cycle_mod:reset_day(CycleTask, Today),
                    Packet          	= task_api:msg_task_info(CycleTask2#task_cycle.current),
                    PacketDailyCount   	= task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
                    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
                    {CycleTask2, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2};
                #task{} ->
                    CycleTask_2         = recover_task_daily_cycle_from_guild(CycleTask, MainTask),
                    CycleTask2          = task_cycle_mod:reset_day(CycleTask_2, Today),
                    Packet              = task_api:msg_task_info(CycleTask2#task_cycle.current),
                    PacketDailyCount    = task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
                    {Count1, Count2}    = task_cycle_mod:get_unfinished_count(CycleTask2),
                    {CycleTask2, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2}
            end;
        _ ->
            CycleTask2          = task_cycle_mod:reset_day(CycleTask, Today),
            Packet              = task_api:msg_task_info(CycleTask2#task_cycle.current),
            PacketDailyCount    = task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
            {Count1, Count2}    = task_cycle_mod:get_unfinished_count(CycleTask2),
            {CycleTask2, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2}
    end;
confirm_daily_cycle(_Player, CycleTask, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =/= Today andalso
	   CycleTask#task_cycle.lib_id =:= 0 ->
	CycleTask2			= recover_task_daily_cycle(CycleTask, MainTask),
    CycleTask3      	= task_cycle_mod:reset_day(CycleTask2, Today),
    Packet          	= task_api:msg_task_info(CycleTask3#task_cycle.current),
    PacketDailyCount   	= task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
	{Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask3),
	{CycleTask3, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2};
confirm_daily_cycle(Player, CycleTask, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =:= Today andalso
	   CycleTask#task_cycle.lib_id =/= 0 ->
    Cur = CycleTask#task_cycle.current,
    case task_api:mini_to_task(Cur) of
        #task{type = ?CONST_TASK_TYPE_EVERYDAY} ->
            CurrentTask         = task_mod:check_and_set_task_state(Player, CycleTask#task_cycle.current, ?CONST_TASK_POS_CONFIRM),
            Packet              = task_api:msg_task_info(CurrentTask),
            {Count1, Count2}    = task_cycle_mod:get_unfinished_count(CycleTask),
            PacketDailyCount    = task_api:msg_sc_daily_count(CycleTask#task_cycle.times),
            {CycleTask#task_cycle{current = CurrentTask}, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2};
        Task when is_record(Task, task) ->
            CycleTask_2         = recover_task_daily_cycle_from_guild(CycleTask, MainTask),
            CurrentTask         = task_mod:check_and_set_task_state(Player, CycleTask_2#task_cycle.current, ?CONST_TASK_POS_CONFIRM),
            Packet              = task_api:msg_task_info(CurrentTask),
            {Count1, Count2}    = task_cycle_mod:get_unfinished_count(CycleTask),
            PacketDailyCount    = task_api:msg_sc_daily_count(CycleTask#task_cycle.times),
            {CycleTask_2#task_cycle{current = CurrentTask}, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2};
        _ ->
            CurrentTask         = task_mod:check_and_set_task_state(Player, CycleTask#task_cycle.current, ?CONST_TASK_POS_CONFIRM),
            Packet              = task_api:msg_task_info(CurrentTask),
            {Count1, Count2}    = task_cycle_mod:get_unfinished_count(CycleTask),
            PacketDailyCount    = task_api:msg_sc_daily_count(CycleTask#task_cycle.times),
            {CycleTask#task_cycle{current = CurrentTask}, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2}
    end;
confirm_daily_cycle(_Player, CycleTask, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =:= Today andalso
	   CycleTask#task_cycle.lib_id =:= 0 ->
	CycleTask2			= recover_task_daily_cycle(CycleTask, MainTask),
    CurrentTask			= CycleTask2#task_cycle.current,
    Packet				= task_api:msg_task_info(CurrentTask),
    PacketDailyCount   	= task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
    {CycleTask2, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2};
confirm_daily_cycle(_Player, _CycleTask, MainTask, _Today) ->
	CycleTask			= init_daily_cycle_task(), 
	CycleTask2			= recover_task_daily_cycle(CycleTask, MainTask),
	CurrentTask			= CycleTask2#task_cycle.current,
    Packet				= task_api:msg_task_info(CurrentTask),
    PacketDailyCount   	= task_api:msg_sc_daily_count(CycleTask2#task_cycle.times),
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
    {CycleTask2, <<Packet/binary, PacketDailyCount/binary>>, Count1, Count2}.

%% 恢复日常任务
recover_task_daily_cycle(CycleTask, MainTask) ->
	case CycleTask#task_cycle.lib_id of
		0 ->
			Idx = 
                case MainTask of
                    #mini_task{state = ?CONST_TASK_STATE_SUBMIT} -> 
                        RecTask = task_api:read(MainTask#mini_task.id),
                        RecTask#task.idx;
                    #mini_task{} -> 
                        RecTask = task_api:read(MainTask#mini_task.id),
                        RecTask#task.idx - 1;
                    _ ->
                        0
                end,
			case data_task:get_daily_lib(Idx) of
				?null -> CycleTask;
				LibId ->
					RecLib		= task_mod:read_lib(LibId),
					Lib   		= RecLib#rec_task_lib.tasks,
					Sp    		= RecLib#rec_task_lib.sp,
                    GoodsList   = RecLib#rec_task_lib.goods,
					TaskId		= misc_random:random_one(Lib),
					Task		= data_task:get_task(TaskId),
					Task2      	= Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = CycleTask#task_cycle.times},
                    MiniTask    = task_api:task_to_mini(Task2), 
					CycleTask#task_cycle{current = MiniTask, lib_id = LibId, lib = Lib, special_reward = Sp, goods = GoodsList}
			end;
		_ -> CycleTask
	end.
recover_task_daily_cycle_from_guild(CycleTask, MainTask) ->
    Idx = 
        case MainTask of
            #mini_task{state = ?CONST_TASK_STATE_SUBMIT} -> 
                RecTask = task_api:read(MainTask#task.id),
                RecTask#task.idx;
            #mini_task{} -> 
                RecTask = task_api:read(MainTask#task.id),
                RecTask#task.idx - 1;
            _ ->
                0
        end,
    case data_task:get_daily_lib(Idx) of
        ?null -> CycleTask;
        LibId ->
            RecLib      = task_mod:read_lib(LibId),
            Lib         = RecLib#rec_task_lib.tasks,
            Sp          = RecLib#rec_task_lib.sp,
            GoodsList   = RecLib#rec_task_lib.goods,
            TaskId      = misc_random:random_one(Lib),
            Task        = data_task:get_task(TaskId),
            Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = CycleTask#task_cycle.times},
            MiniTask    = task_api:task_to_mini(Task2), 
            CycleTask#task_cycle{current = MiniTask, lib_id = LibId, lib = Lib, special_reward = Sp, goods = GoodsList}
    end.
%%-----------------------------------------------------------------------------------
%% 接任务的条件:
%% 1.等级
%% 2.时间段
%% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
check_acceptable(Player, TaskId) when is_number(TaskId) ->
    TaskData   = Player#player.task,
    DailyCycle = TaskData#task_data.daily_cycle,
    TaskCur    = DailyCycle#task_cycle.current,
    if
        TaskCur#mini_task.id =:= TaskId ->
            Count = DailyCycle#task_cycle.times,
            MiniTask = TaskCur#mini_task{count = Count},
            check_acceptable(Player, MiniTask);
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
    DailyCycle  = TaskData#task_data.daily_cycle,
    DailyCycle2 = DailyCycle#task_cycle{current = MiniTask4, times = MiniTask4#mini_task.count},
    TaskData2   = TaskData#task_data{daily_cycle = DailyCycle2},
    Packet      = task_api:msg_task_info(MiniTask4),
    PacketDaily	= task_api:msg_sc_daily_count(DailyCycle2#task_cycle.times),
    Player2     = Player#player{task = TaskData2},
    {Player2, MiniTask4, <<Packet/binary, PacketDaily/binary>>}.

%%--------------------------------------------------------------------------------------------
is_accepted(TaskData, TaskId) when 0 =/= TaskId ->
    DailyCycle = TaskData#task_data.daily_cycle,
    CurTask = DailyCycle#task_cycle.current,
    if
        CurTask#mini_task.id =:= TaskId ->
            {?CONST_SYS_TRUE, CurTask};
        ?true ->
            {?CONST_SYS_FALSE, ?null}
    end;
is_accepted(_TaskData, _) ->
    {?CONST_SYS_FALSE, ?null}.

%%--------------------------------------------------------------------------------------------
reward(Player, Task) ->
    % 1
    case task_mod:reward_goods(Player, Task#task.goods, Task#task.is_temp) of
        {?error, ErrorCode} -> {?error, ErrorCode};
        {?ok, Player2, GoodsList, PacketBag} ->
            % 2
            case reward_special(Player2, ?CONST_COST_TASK_REWARD_DAILY) of
                {?ok, Player3} -> {?ok, Player3, GoodsList, PacketBag};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

reward_special(Player, Point) -> % 日常任务
    {?ok, Player2} = task_mod:reward_exp(Player, ?FUNC_EVERYDAY_EXP((Player#player.info)#info.lv), Point),
    TaskData	= Player#player.task,
    DailyCycle	= TaskData#task_data.daily_cycle,
    task_cycle_mod:reward_cycle_end(Player2, DailyCycle, Point).

remove_task(Player, MiniTask) ->
    TaskData    = Player#player.task,
    DailyCycle  = TaskData#task_data.daily_cycle,
    DailyCycle2 = DailyCycle#task_cycle{current = ?null},
    TaskData2   = TaskData#task_data{daily_cycle = DailyCycle2},
    Player2     = Player#player{task = TaskData2},
    Packet      = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
    {Player2, Packet}.

%% add_task(Player, Task) ->
%%     TaskData    = Player#player.task,
%%     DailyCycle  = TaskData#task_data.daily_cycle,
%%     Count       = DailyCycle#task_cycle.times,
%%     if
%%         Count < Task#task.cycle ->
%%             Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = DailyCycle#task_cycle.times},
%%             DailyCycle2 = DailyCycle#task_cycle{current = Task2},
%%             TaskData2   = TaskData#task_data{daily_cycle = DailyCycle2},
%%             Packet      = task_api:msg_task_info(Task2),
%%             Player2     = Player#player{task = TaskData2},
%%             {Player2, Packet};
%%         ?true ->
%%             {Player, <<>>}
%%     end.

%% 228899
add_task(Player, Task = #task{next = {random, LibId}}) ->
	TaskData    = Player#player.task,
    DailyCycle  = TaskData#task_data.daily_cycle,
	if
		DailyCycle#task_cycle.lib_id =:= LibId ->
			Count       = DailyCycle#task_cycle.times,
			if
				Count < Task#task.cycle ->
					Task2        = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = DailyCycle#task_cycle.times},
                    RemovePacket = 
                        case DailyCycle#task_cycle.current of
                            #mini_task{id = OldTaskId} ->
                                task_api:msg_task_remove(OldTaskId, ?CONST_TASK_REMOVE_REASON_DOWN);
                            _ ->
                                <<>>
                        end,
                    MiniTask    = task_api:task_to_mini(Task2),
					DailyCycle2 = DailyCycle#task_cycle{current = MiniTask},
					TaskData2   = TaskData#task_data{daily_cycle = DailyCycle2},
					Player2     = Player#player{task = TaskData2},
					Packet      = task_api:msg_task_info(MiniTask),
					{Player2, <<RemovePacket/binary, Packet/binary>>};
				?true ->
					{?ok, Player2}	= add_achievement(Player, ?true),
					{Player2, <<>>}
			end;
		DailyCycle#task_cycle.lib_id < LibId ->
			RecLib		= task_mod:read_lib(LibId),
			Lib   		= RecLib#rec_task_lib.tasks,
			Sp    		= RecLib#rec_task_lib.sp,
            GoodsList   = RecLib#rec_task_lib.goods,
			Count       = DailyCycle#task_cycle.times,
			{
			 DailyCycle2, DailyPacket, Flag
			} 			=
				if
					Count < Task#task.cycle ->
						case DailyCycle#task_cycle.current of
							TaskOld when is_record(TaskOld, mini_task) andalso
										 (TaskOld#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED orelse
										  TaskOld#mini_task.state =:= ?CONST_TASK_STATE_FINISHED) ->
								{DailyCycle#task_cycle{lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, <<>>, ?false};
							TaskOld when is_record(TaskOld, mini_task) ->
								PacketRemove	= task_api:msg_task_remove(TaskOld#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
								Task2       	= Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = DailyCycle#task_cycle.times},
                                MiniTask        = task_api:task_to_mini(Task2),
								PacketNew		= task_api:msg_task_info(MiniTask),
								{DailyCycle#task_cycle{current = MiniTask, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, 
                                                      <<PacketRemove/binary, PacketNew/binary>>, ?false};
							?null ->
								Task2       	= Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = DailyCycle#task_cycle.times},
                                MiniTask        = task_api:task_to_mini(Task2),
								PacketNew		= task_api:msg_task_info(MiniTask),
								{DailyCycle#task_cycle{current = MiniTask, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew, ?false};
							0 ->
								Task2       	= Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = DailyCycle#task_cycle.times},
                                MiniTask        = task_api:task_to_mini(Task2),
								PacketNew		= task_api:msg_task_info(Task2),
								{DailyCycle#task_cycle{current = MiniTask, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew, ?false}
						end;
					?true ->
						{DailyCycle, <<>>, ?true}
				end,
			TaskData2   = TaskData#task_data{daily_cycle = DailyCycle2},
			Player2     = Player#player{task = TaskData2},
			{?ok, Player3}	= add_achievement(Player2, Flag),
			{Player3, DailyPacket};
		DailyCycle#task_cycle.lib_id > LibId ->
			TaskId			= task_mod:get_next_lib_task(DailyCycle#task_cycle.lib_id),
            Task2			= task_api:read(TaskId),
			add_task(Player, Task2)
	end.
%% ====================================================================
%% Internal functions
%% ====================================================================
add_achievement(Player, ?false) -> {?ok, Player};
add_achievement(Player, ?true) ->
	achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_DAILY_TASK_COMPLETION, 0, 1).
