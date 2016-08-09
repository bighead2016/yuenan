%% 每日任务  由于每日任务只有三种状态，未完成，完成未提交，已提交
%% @doc @todo Add description to task_everyday_mod.


-module(task_everyday_mod).

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
%% -export([]).
-export([init_everyday_task/0, confirm_everyday/5, 
         add_task/2, is_accepted/2,
         remove_task/2, reward/2]).

init_everyday_task() ->
	[].

%%根据前置主线任务id和等级来判断
confirm_everyday(Player, Lv, EverydayList, MainTask, Today) ->
	AllIdList = data_task:get_everyday_id_list(),
	AllTaskList = [task_mod:read(TaskId)||TaskId<-AllIdList],
	Id = 
        case MainTask of
            #mini_task{state = ?CONST_TASK_STATE_SUBMIT} -> 
                RecTask = task_api:read(MainTask#mini_task.id),
                RecTask#task.id;
            #mini_task{} -> 
                RecTask = task_api:read(MainTask#mini_task.id),
                RecTask#task.id - 1;
            _ ->
                0
        end,
	%% 获取玩家可以接的所有的任务
	AcceptTaskList = 
		lists:foldl(fun(Task,Acc)->
							if is_record(Task,task) ->
								   #task{prev=PrevId,lv_min=LvMin,lv_max=LvMax} = Task,
								   case PrevId =< Id andalso LvMin =< Lv andalso  Lv =< LvMax of
									   true ->
                                           MiniTask = task_api:task_to_mini(Task),
										   [MiniTask|Acc];
									   false ->
										   Acc
								   end;
							   true ->
								   Acc
							end
					end, [], AllTaskList),
	%% 判断现在每日列表中的任务是否在可接的任务列表中
	NewEverydayList = 
		lists:foldl(fun(MiniTask,Acc)->
							case lists:keytake(MiniTask#mini_task.id,#mini_task.id,AcceptTaskList) of
								false ->
									Acc -- [MiniTask];
								{value,_,_} ->
									Acc
							end
					end,EverydayList, EverydayList),
	
	NewEverydayList1 = 
		lists:foldl(fun(MiniTask,Acc) ->
							case lists:keytake(MiniTask#mini_task.id,#mini_task.id,Acc) of
								false ->
									[MiniTask|Acc];
								{value,MiniTask1,OtherList} ->
									case MiniTask1#mini_task.date =/= Today of
										true ->
											MiniTask2 = MiniTask1#mini_task{state= ?CONST_TASK_STATE_UNFINISHED},
                                            MiniTask2_2 = clear_target(MiniTask2),
											MiniTask3 = task_mod:set_task_date_time(MiniTask2_2),
											[MiniTask3|OtherList];
										false ->
											Acc
									end
							end
					end, NewEverydayList, AcceptTaskList),
	TaskList = [MiniTask||MiniTask<-NewEverydayList1,MiniTask#mini_task.state == ?CONST_TASK_STATE_UNFINISHED 
                                                                        orelse MiniTask#mini_task.state == ?CONST_TASK_STATE_FINISHED],
	UnfinishedTaskList   = task_mod:check_and_set_task_state(Player, TaskList, ?CONST_TASK_POS_CONFIRM),
	Count = erlang:length(UnfinishedTaskList),
    UnfinishedTaskPacket = task_api:msg_task_info(UnfinishedTaskList),
	{NewEverydayList1, UnfinishedTaskPacket, 0, Count}.
	
	
%%任务完成以后	
remove_task(Player, MiniTask) ->
    TaskData    = Player#player.task,
    EveryDayTaskList  = TaskData#task_data.everyday_task,
	case lists:keytake(MiniTask#mini_task.id, #mini_task.id, EveryDayTaskList) of
		false ->
			?MSG_ERROR("not find task id:~p,everyday_task:~p",[MiniTask#mini_task.id,EveryDayTaskList]),
			{Player, <<>>};
		{value,MiniTask1,OtherList} ->
			NewEveryDayTaskList = [MiniTask1#mini_task{state= ?CONST_TASK_STATE_SUBMIT}|OtherList],
			TaskData2   = TaskData#task_data{everyday_task = NewEveryDayTaskList},
			Player2     = Player#player{task = TaskData2},
			Packet      = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
			{Player2, Packet}
	end.

clear_target(#mini_task{id = TaskId} = MiniTask) ->
    case task_api:read(TaskId) of
        #task{target = Target} ->
            MiniTask#mini_task{target = Target};
        _ ->
            ?null
    end.


%% 增加任务
add_task(Player, Task) ->
	TaskId        = Task#task.id,
    TaskState     = Task#task.state,
	
	TaskData      = Player#player.task,
    MainTask      = TaskData#task_data.main,
    Branch        = TaskData#task_data.branch,
    FinishedList  = Branch#branch_task.finished,
	% 1
    IsFitPrev     = is_finish_prev(FinishedList, MainTask),
	EveryDayList = TaskData#task_data.everyday_task,
	{NewEveryDayTask, NewTaskPacket} =
		case ?true =:= IsFitPrev andalso ?CONST_TASK_STATE_UNFINISHED =:= TaskState of
			true ->
				Task2 = 
					case task_mod:check_task_complete(Player, Task#task.target) of
						?true ->
							Task#task{state = ?CONST_TASK_STATE_FINISHED};
						?false ->
							Task
					end,
                MiniTask = task_api:task_to_mini(Task2),
				EveryDayList2 = misc:smart_insert_ignore(TaskId, MiniTask, #mini_task.id, EveryDayList),
				TaskPacket      = task_api:msg_task_info(MiniTask),
				{EveryDayList2, TaskPacket};
			false ->
				{EveryDayList, <<>>}
		end,
	TaskData2   = TaskData#task_data{everyday_task = NewEveryDayTask},
    Player2     = Player#player{task = TaskData2},
    {Player2, NewTaskPacket}.



%% %% 接任务的条件:
%% %% 1.等级
%% %% 2.时间段
%% %% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
%% check_acceptable(Player, TaskId) when is_number(TaskId) ->
%%     TaskData   = Player#player.task,
%%     DailyCycle = TaskData#task_data.daily_cycle,
%%     TaskCur    = DailyCycle#task_cycle.current,
%%     if
%%         TaskCur#task.id =:= TaskId ->
%%             Count = DailyCycle#task_cycle.times,
%%             Task2 = TaskCur#task{count = Count},
%%             check_acceptable(Player, Task2);
%%         ?true ->
%%             {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
%%     end;
%% check_acceptable(Player, Task) ->
%%     try
%%         Info    = Player#player.info,
%%         Lv      = Info#info.lv,
%%         ?ok     = task_mod:false_throw(task_mod, is_lv_min_max, Task, Lv),  
%%         ?ok     = task_mod:false_throw(task_mod, is_fit_time, Task),  
%%         ?ok     = task_mod:false_throw(task_mod, is_acceptable_state, Task),
%%         ?ok     = task_mod:false_throw(task_mod, is_times_over, Task),
%%         {?ok, Task}
%%     catch
%%         throw:{?error, ErrorCode} ->
%%             {{?error, ErrorCode}, ?null};
%%         _:_ ->
%%             {{?error, ?TIP_COMMON_BAD_ARG}, ?null}
%%     end.


reward(Player, Task) ->
	% 1
	case task_mod:reward_goods(Player, Task#task.goods, Task#task.is_temp) of
		{?error, ErrorCode} -> {?error, ErrorCode};
		{?ok, Player2, GoodsList, PacketBag} ->
			% 2
			case reward_special(Player2, Task, ?CONST_COST_TASK_REWARD_EVERYDAY) of
				{?ok, Player3} -> {?ok, Player3, GoodsList, PacketBag};
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.

reward_special(Player, Task, Point) -> 
    case task_mod:reward_gold_bind(Player#player.user_id, Task#task.gold_bind, Point) of
        ?ok ->
            {?ok, Player2} = task_mod:reward_exp(Player, Task#task.exp, Point),
            {?ok, Player3} = task_mod:reward_experience(Player2, Task#task.experience, Point), 
            task_mod:reward_meritorious(Player3, Task#task.meritorious, Point);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

	
is_accepted(TaskData, TaskId) ->
	EveryDayTask = TaskData#task_data.everyday_task,
	case lists:keyfind(TaskId, #mini_task.id, EveryDayTask) of
		MiniTask when is_record(MiniTask, mini_task) ->
			case MiniTask#mini_task.state == ?CONST_TASK_STATE_FINISHED of
				?true ->
					{?CONST_SYS_TRUE, MiniTask};
				?false ->
					{?CONST_SYS_FALSE, ?null}
			end;
		?false ->
			{?CONST_SYS_FALSE, ?null}
	end.

%% ====================================================================
%% Internal functions
%% ====================================================================

is_finish_prev(FinishedList, #mini_task{} = MainTask) ->
    RecTask = task_api:read(MainTask#mini_task.id),
    MainIdx = 
        case RecTask of
            #task{idx = MainIdxT} ->
                MainIdxT;
            ?null ->
                999999;
            _ ->
                0
        end,
    PrevId        = RecTask#task.prev,
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
    end;
is_finish_prev(FinishedList, _MainTask) ->
    RecTask = ?null,
    {MainIdx, PrevId} = 
        case RecTask of
            #task{idx = MainIdxT, prev = Prev} ->
                {MainIdxT, Prev};
            ?null ->
                {999999, 0};
            _ ->
                {0, 0}
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
