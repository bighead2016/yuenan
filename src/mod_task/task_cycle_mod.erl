%% @author np
%% @doc @todo Add description to task_cycle_mod.


-module(task_cycle_mod).

-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([init_task_cycle/0, reset_day/2, get_unfinished_count/1, change_lib/2,
         reward_cycle_end/3]).

%% 初始化环任务
init_task_cycle() ->
    #task_cycle{current = 0, lib = [], lib_id = 0, special_reward = 0, times = 0, goods = []}.

%% 重置日期
reset_day(TaskCycle, Today) when TaskCycle#task_cycle.date =/= Today ->
	case TaskCycle#task_cycle.current of
        ?null ->
            TaskLibId  = TaskCycle#task_cycle.lib_id,
            NextTaskId = task_mod:get_next_lib_task(TaskLibId),
            NextTask   = task_mod:read(NextTaskId),
            NextTask2  = NextTask#task{count = 1, state = ?CONST_TASK_STATE_UNFINISHED},
            MiniTask   = task_api:task_to_mini(NextTask2),
            TaskCycle#task_cycle{times = 1, date = Today, current = MiniTask};
        TaskCur when is_record(TaskCur, mini_task) andalso TaskCycle#task_cycle.date =/= 0 ->
			NewTaskCur = TaskCur#mini_task{count = 1, state = ?CONST_TASK_STATE_UNFINISHED},
            TaskCycle#task_cycle{times = 1, date = Today, current = NewTaskCur};
		_ ->
			TaskCycle#task_cycle{times = 0, date = Today}
    end;
%%     case TaskCycle#task_cycle.current of
%%         ?null ->
%%             TaskLibId  = TaskCycle#task_cycle.lib_id,
%%             NextTaskId = task_mod:get_next_lib_task(TaskLibId),
%%             NextTask   = task_mod:read(NextTaskId),
%%             NextTask2  = NextTask#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
%%             MiniTask   = task_api:task_to_mini(NextTask2),
%%             TaskCycle#task_cycle{times = 0, date = Today, current = MiniTask};
%%         TaskCur when is_record(TaskCur, mini_task) ->
%% 			NewTaskCur = TaskCur#mini_task{count = 0},
%%             TaskCycle#task_cycle{times = 0, date = Today, current = NewTaskCur};
%% 		_ ->
%% 			TaskCycle#task_cycle{times = 0, date = Today}
%%     end;
reset_day(TaskCycle, _) ->
    TaskCycle.

get_unfinished_count(TaskCycle) ->
    CurrentTask = TaskCycle#task_cycle.current,
    if
        0 =/= CurrentTask andalso ?CONST_TASK_STATE_ACCEPTABLE =:= CurrentTask#mini_task.state ->
            {1, 0};
        0 =/= CurrentTask andalso ?CONST_TASK_STATE_UNFINISHED =:= CurrentTask#mini_task.state ->
            {0, 1};
        ?true ->
            {0, 0}
    end.

%% 修改lib
change_lib(TaskCycle, RecLib) when TaskCycle#task_cycle.lib_id =/= RecLib#rec_task_lib.id andalso RecLib#rec_task_lib.id =/= 0 ->
    Lib   = RecLib#rec_task_lib.tasks,
    Sp    = RecLib#rec_task_lib.sp,
    GoodsList = RecLib#rec_task_lib.goods,
    case TaskCycle#task_cycle.current of
        Task when is_record(Task, mini_task) andalso
				  (Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED orelse
				   Task#mini_task.state =:= ?CONST_TASK_STATE_FINISHED) ->
            {TaskCycle#task_cycle{lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, <<>>};
        Task when is_record(Task, mini_task) ->
            PacketRemove	= task_api:msg_task_remove(Task#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
            TaskId			= task_mod:get_next_lib_task(RecLib#rec_task_lib.id),
            Task2			= task_api:read(TaskId),
            Task2_2         = Task2#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            MiniTask2       = task_api:task_to_mini(Task2_2),
            PacketNew		= task_api:msg_task_info(MiniTask2),
            {TaskCycle#task_cycle{current = MiniTask2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, 
                                 <<PacketRemove/binary, PacketNew/binary>>};
        ?null ->
            TaskId          = task_mod:get_next_lib_task(RecLib#rec_task_lib.id),
            Task            = task_api:read(TaskId),
            Task_2          = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            MiniTask_2      = task_api:task_to_mini(Task_2),
            {MiniTask2, PacketNew} = 
                case Task#task.type of
                    ?CONST_TASK_TYPE_EVERYDAY when TaskCycle#task_cycle.times < 10 ->
                        Packet = task_api:msg_task_info(MiniTask_2),
                        {MiniTask_2, Packet};
                    ?CONST_TASK_TYPE_GUILD when TaskCycle#task_cycle.times < 5 ->
                        Packet = task_api:msg_task_info(MiniTask_2),
                        {MiniTask_2, Packet};
                    _ ->
                        {?null, <<>>}
                end,
            {TaskCycle#task_cycle{current = MiniTask2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew};
        0 ->
            TaskId			= task_mod:get_next_lib_task(RecLib#rec_task_lib.id),
            Task			= task_api:read(TaskId),
            MiniTask2       = task_api:task_to_mini(Task),
            PacketNew		= task_api:msg_task_info(MiniTask2),
            {TaskCycle#task_cycle{current = MiniTask2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew}
    end;
change_lib(TaskCycle, _) ->
    {TaskCycle, <<>>}.
    
%% lib_2_list([Id|Tail], List) ->
%%     Task  = task_mod:read(Id),
%%     List2 = add_lib(Task, List),
%%     lib_2_list(Tail, List2);
%% lib_2_list([], List) ->
%%     List;
%% lib_2_list(?null, List) ->
%%     List.
%%     
%% add_lib(Task, List) when is_record(Task, task) ->
%%     ?MSG_DEBUG("t=~p", [Task]),
%%     [Task|List];
%% add_lib(_, List) ->
%%     ?MSG_DEBUG("1", []),
%%     List.

reward_cycle_end(Player, TaskCycle, Point) ->
    CurCount 	= TaskCycle#task_cycle.times,
    CurMiniTask = TaskCycle#task_cycle.current,
    RecTask     = task_api:read(CurMiniTask#mini_task.id),
    LimitCount 	= RecTask#task.cycle, 
	
	%% 军团战中占领城池的军团任务奖励提升100%：体力提升
	Guild    = Player#player.guild,
	GuildId  = Guild#guild.guild_id, 
	OccupyGuildId = guild_pvp_mod:get_tower_owner_id(),
	Sp  = 
		if  GuildId =:= OccupyGuildId  ->
				TaskCycle#task_cycle.special_reward * 2;
			true ->
				TaskCycle#task_cycle.special_reward
		end,
	
	?MSG_DEBUG("CurCount:~p  LimitCount:~p", [CurCount, LimitCount]),
    if
        LimitCount =:= CurCount -> 
            {?ok, Player2} = task_mod:reward_sp(Player, Sp, Point),
            case task_mod:reward_goods(Player2, TaskCycle#task_cycle.goods, ?CONST_SYS_TRUE) of
                {?ok, Player3, _, AccPacket} ->
                    misc_packet:send(Player#player.user_id, AccPacket),
                    {?ok, Player3};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        ?true -> {?ok, Player}
    end.