%% 上下线时，任务的特殊处理
-module(task_login_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.task.hrl").

%%
%% Exported Functions
%%
-export([create/1, login/1, logout/1, zip/1, unzip/1, get_real_target/5, zip/2, unzip/2]).

%%
%% API Functions
%%

%%-------------------------------------初始化任务数据------------------------------------------------
%% 创建角色初始化任务数据
create(TaskId) ->
    MainTask        = task_main_mod:init_main_task(TaskId),
    BranchTask      = task_branch_mod:init_branch_task(), 
    PositionTask    = task_position_mod:init_position_task(),
    GuildCycleTask  = task_guild_mod:init_guild_cycle_task(),
    DailyCycleTask  = task_daily_mod:init_daily_cycle_task(),
    EveryDayTask    = task_everyday_mod:init_everyday_task(),
    record_task_data(MainTask, BranchTask, PositionTask, GuildCycleTask, DailyCycleTask,EveryDayTask).

%% 封装任务结构
record_task_data(MainTask, BranchTask, PositionTask, GuildCycleTask, DailyCycleTask, EveryDayTask) ->
	Idx		= if is_record(MainTask, mini_task) -> 
                     Task = task_api:read(MainTask#mini_task.id),
                     Task#task.idx; 
                 ?true -> 1 
              end,
    #task_data{
               main = MainTask, main_idx = Idx, branch = BranchTask, position_task = PositionTask,
               guild_cycle = GuildCycleTask, daily_cycle = DailyCycleTask,everyday_task = EveryDayTask,
               note = [] 
              }.

%%-----------------------------------登录---------------------------------------------------------
%% 角色登录返回任务数据
%% 1.确保主线任务
%% 2.确保支线任务
%% 3.确保军团任务
%% 4.确保日常任务
%% 5.确保官衔任务
%% 6.把该发的任务发给前端
login(Player) when is_record(Player#player.task, task_data) ->
    % 1
    TaskData    = Player#player.task,
    Info        = Player#player.info,
	Pro			= Info#info.pro,
    Lv          = Info#info.lv,
    AttrRate    = Info#info.attr_rate,
    PositionData = Player#player.position,
    PositionId   = PositionData#position_data.position,
    
    MainTask    = TaskData#task_data.main,
	MainIdx		= TaskData#task_data.main_idx,
    {ConfirmedMainTask, MainTaskPacket, Count1_1, Count2_1}
                = task_main_mod:confirm_main(MainTask, MainIdx, Pro, Lv),
    
    % 2
    BranchTask  = TaskData#task_data.branch,
    {ConfirmedBranchTask, BranchTaskPacket, Count1_2, Count2_2}
                = task_branch_mod:confirm_branch(Player, BranchTask),  

    % 3
    GuildCycleTask = TaskData#task_data.guild_cycle,
    Guild			= Player#player.guild,
    GuildId     = Guild#guild.guild_id,
    Today       = misc:date_num(),
    {GuildCycleTask2, GuildCyclePacket, Count1_3, Count2_3}
                = task_guild_mod:confirm_guild_cycle(Player, GuildCycleTask, GuildId, MainTask, Today),
    
    % 4
    DailyCycleTask = TaskData#task_data.daily_cycle,
    {DailyCycleTask2, DailyCyclePacket, Count1_4, Count2_4}
                = task_daily_mod:confirm_daily_cycle(Player, DailyCycleTask, MainTask, Today),
	
    % 5
    PositionTask = TaskData#task_data.position_task,
    {PositionTask2, PositionPacket, Count1_5, Count2_5}
                = task_position_mod:confirm_position(PositionTask, AttrRate, Lv, PositionId),

    % 6
	EveryDayTask = TaskData#task_data.everyday_task,
	{EveryDayTask2, EveryDayPacket, Count1_6, Count2_6}
				= task_everyday_mod:confirm_everyday(Player, Lv, EveryDayTask, MainTask, Today),
	% 7
    TaskPacketTotal = <<MainTaskPacket/binary, BranchTaskPacket/binary, 
                        GuildCyclePacket/binary, DailyCyclePacket/binary,
                        PositionPacket/binary, EveryDayPacket/binary>>,
    Count1 = Count1_1 + Count1_2 + Count1_3 + Count1_4 + Count1_5+ Count1_6,
    Count2 = Count2_1 + Count2_2 + Count2_3 + Count2_4 + Count2_5+ Count2_6,
    TaskData2 = update_task_data(ConfirmedMainTask, MainIdx, ConfirmedBranchTask, GuildCycleTask2, DailyCycleTask2, PositionTask2, EveryDayTask2, Count1, Count2, TaskData#task_data.note),
    Player2 = Player#player{task = TaskData2},  
    
    {?ok, Player2, TaskPacketTotal};
login(Player) ->
    {?ok, Player, <<>>}.

update_task_data(ConfirmedMainTask, MainIdx, ConfirmedBranchTask, GuildCycleTask2, DailyCycleTask2, PositionTask2, EveryDayTask2, Count1, Count2, Note) ->
    #task_data{
                 main               = ConfirmedMainTask, 
				 main_idx           = MainIdx,
                 branch             = ConfirmedBranchTask,
                 position_task      = PositionTask2,     
                 guild_cycle        = GuildCycleTask2,    
                 daily_cycle        = DailyCycleTask2,
				 everyday_task		= EveryDayTask2,  
                 acceptable_count   = Count1,
                 unfinished_count   = Count2,
                 note               = Note
              }.

%%------------------------------------------------------------------------------------------
%% 去掉静态数据
zip(TaskData) when is_record(TaskData, task_data) ->
    try
        MainLine      	= TaskData#task_data.main,
        [NewMainLine]	= zip([MainLine], []),
        
        Branch      	= TaskData#task_data.branch,
        List        	= Branch#branch_task.unfinished,
        List1        	= Branch#branch_task.acceptable,
        List2        	= Branch#branch_task.unacceptable,
        NewTaskList 	= zip(List, []),
        NewTaskList1 	= zip(List1, []),
        NewTaskList2 	= zip(List2, []),
        Branch2     	= Branch#branch_task{unfinished = NewTaskList, acceptable = NewTaskList1, unacceptable = NewTaskList2},
        
        DailyCycle  	= TaskData#task_data.daily_cycle,
        DailyCur    	= DailyCycle#task_cycle.current,
        [DailyCur2] 	= zip([DailyCur], []),
        DailyCycle2 	= DailyCycle#task_cycle{current = DailyCur2},
        
        GuildCycle  	= TaskData#task_data.guild_cycle,
        GuildCur    	= GuildCycle#task_cycle.current,
        [GuildCur2] 	= zip([GuildCur], []),
        GuildCycle2 	= GuildCycle#task_cycle{current = GuildCur2},
        
        PositionTask	= TaskData#task_data.position_task,
        [PositionTaskCur2] = zip([PositionTask], []),
        PositionTask2 	= PositionTaskCur2,
        
		EveryDayTask	= TaskData#task_data.everyday_task,
		EveryDayTask2	= zip(EveryDayTask, []),
        TaskData#task_data{main 			= NewMainLine,
						   branch			= Branch2,
						   daily_cycle 		= DailyCycle2, 
						   guild_cycle		= GuildCycle2, 
						   position_task 	= PositionTask2,
						   everyday_task	= EveryDayTask2}
    catch
        throw:{?error,ErrorCode} ->
            ?MSG_ERROR("e=~p", [ErrorCode]),
            TaskData;
        X:Y ->
            ?MSG_ERROR("e=~p, ~p, ~p", [X, Y, erlang:get_stacktrace()]),
            TaskData
    end;
zip([]) ->
    #task_data{}.

zip([#mini_task{id=Id, target=TargetList, state=State, count=Count, date=Date, time=Time}|Tail], ResultList) ->
    NewResultList = [{Id, TargetList, State, Count, Date, Time}|ResultList],
    zip(Tail, NewResultList);
zip([0], ResultList) -> [0|ResultList];
zip([?null], ResultList) -> [?null|ResultList];
zip([], ResultList) -> ResultList;
zip(?null, ResultList) -> [?null|ResultList].

%% 数据恢复
unzip(TaskData = #task_data{main 	= MainLine,
							branch	= Branch}) ->
    [NewMainLine] = unzip([MainLine], []),
    
    List        = Branch#branch_task.unfinished,
    List1       = Branch#branch_task.acceptable,
    List2       = Branch#branch_task.unacceptable,
    NewTaskList  = unzip(List, []),
    NewTaskList1 = unzip(List1, []),
    NewTaskList2 = unzip(List2, []),
    Branch2     = Branch#branch_task{unfinished = NewTaskList, acceptable = NewTaskList1, unacceptable = NewTaskList2},
    
	DailyCycle2 = 
		case TaskData#task_data.daily_cycle of
			DailyCycle when is_record(DailyCycle, task_cycle) ->
				DailyCur    = DailyCycle#task_cycle.current,
				[DailyCur2] = unzip([DailyCur], []),
				DailyCycle#task_cycle{current = DailyCur2};
			_ -> task_daily_mod:init_daily_cycle_task()
		end,
	GuildCycle2 = 
		case TaskData#task_data.guild_cycle of
			GuildCycle when is_record(GuildCycle, task_cycle) ->
				GuildCur    = GuildCycle#task_cycle.current,
				[GuildCur2] = unzip([GuildCur], []),
				GuildCycle#task_cycle{current = GuildCur2};
			_ -> task_guild_mod:init_guild_cycle_task()
		end,
	
    PositionTask = 
	   case TaskData#task_data.position_task of
           [[T]] ->
               [T];
           T2 ->
               T2
       end,
    [PositionTaskCur2] = unzip([PositionTask], []),
    PositionTask2 = PositionTaskCur2,
	
	EveryDayTask2 =
		case TaskData#task_data.everyday_task of
			EveryDayTask when is_list(EveryDayTask) ->
				unzip(EveryDayTask, []);
			_ ->
				task_everyday_mod:init_everyday_task()
		end,
			
    TaskData#task_data{main = NewMainLine,
					   branch = Branch2,
					   daily_cycle = DailyCycle2, 
					   guild_cycle = GuildCycle2, 
					   position_task = PositionTask2,
					   everyday_task = EveryDayTask2}.

unzip([{Id, TargetList, State, Count, Date, Time}|Tail], ResultList) ->
    NewResultList = 
        case data_task:get_task(Id) of
            RecTask when is_record(RecTask, task) ->
                MiniTask = task_api:task_to_mini(RecTask),
                NewTargetList = get_real_target(TargetList, MiniTask#mini_task.target, [], ?false, TargetList),
                MiniTask2 = MiniTask#mini_task{id=Id, target=NewTargetList, state=State, count=Count, date=Date, time=Time},
                [MiniTask2|ResultList];
            _ ->
                ResultList
        end,
    unzip(Tail, NewResultList);
unzip([MiniTask|Tail], ResultList) when is_record(MiniTask, mini_task) ->
    [MiniTask2] = zip([MiniTask], []),
    [MiniTask3] = unzip([MiniTask2], []),
	unzip(Tail, [MiniTask3|ResultList]);
unzip([0], ResultList) -> [0|ResultList];
unzip([?null], ResultList) -> [?null|ResultList];
unzip([], ResultList) -> ResultList;
unzip(?null, ResultList) -> [?null|ResultList];
unzip([[{Id, TargetList, State, Count, Date, Time}]], ResultList) ->
    case data_task:get_task(Id) of
        #task{type = ?CONST_TASK_TYPE_POSITION} = RecTask ->
            MiniTask = task_api:task_to_mini(RecTask),
            NewTargetList = get_real_target(TargetList, RecTask#task.target, [], ?false, TargetList),
            MiniTask2 = MiniTask#mini_task{id=Id, target=NewTargetList, state=State, count=Count, date=Date, time=Time},
            [MiniTask2|ResultList];
        _ ->
            ResultList
    end;
unzip([[0]], ResultList) ->
	[0|ResultList];
unzip([[?null]], ResultList) ->
	[?null|ResultList];
unzip(Data, ResultList) ->
	?MSG_ERROR("Data:~p~n", [Data]), [Data|ResultList].

%% 注意：只要有一个不匹配就全部清了，以新的为准
get_real_target([TargetL = #task_target{
										idx = IdxL,
										target_type = TargetTypeL,
										as1 = AsL1,
										as2 = AsL2,
										as3 = AsL3,
										as4 = AsL4,
										as5 = AsL5
									   }|TailL], 
				[#task_target{
							  idx = IdxL,
							  target_type = TargetTypeL,
							  as1 = AsL1,
							  as2 = AsL2,
							  as3 = AsL3,
							  as4 = AsL4,
							  as5 = AsL5
							 }|TailR], ResultList, X, List) ->
    NewResultList = [TargetL|ResultList],
    get_real_target(TailL, TailR, NewResultList, X, List);
get_real_target([], [], ResultList, _, _List) ->
    ResultList;
get_real_target(_, TargetRList, _, ?false, List) ->
    TargetRList2 = lists:reverse(TargetRList),
    get_real_target(List, TargetRList2, [], ?true, List);
get_real_target(_, TargetRList, _, ?true, _) ->
    TargetRList.

%%----------------------------退出时特殊处理--------------------------------------------
%% 玩家退出
logout(Player) ->
    TaskData      	= Player#player.task,
    MainLine      	= TaskData#task_data.main,
    [NewMainLine] 	= update_task(Player, [MainLine], []),
    
    Branch			= TaskData#task_data.branch,
    List        	= Branch#branch_task.unfinished,
    NewTaskList 	= update_task(Player, List, []),
    Branch2     	= Branch#branch_task{unfinished = NewTaskList},
    
    DailyCycle  	= TaskData#task_data.daily_cycle,
    DailyCur    	= DailyCycle#task_cycle.current,
    [DailyCur2] 	= update_task(Player, [DailyCur], []),
    DailyCycle2 	= DailyCycle#task_cycle{current = DailyCur2},
    
    GuildCycle  	= TaskData#task_data.guild_cycle,
    GuildCur    	= GuildCycle#task_cycle.current,
    [GuildCur2] 	= update_task(Player, [GuildCur], []),
    GuildCycle2 	= GuildCycle#task_cycle{current = GuildCur2},
    
    PositionTask  	= TaskData#task_data.position_task,
    [PositionTaskCur2] = update_task(Player, [PositionTask], []),
    PositionTask2 	= PositionTaskCur2,
    
	EveryDayTask	= TaskData#task_data.everyday_task,
	EveryDayTask2	= update_task(Player, EveryDayTask, []),
	
    TaskData2 		= TaskData#task_data{main 			= NewMainLine,
										 branch 		= Branch2,
										 daily_cycle	= DailyCycle2, 
										 guild_cycle	= GuildCycle2, 
										 position_task	= PositionTask2,
										 everyday_task	= EveryDayTask2},
    Player#player{task = TaskData2}.

update_task(Player, [MiniTask|Tail], TaskList) when is_record(MiniTask, mini_task) ->
    case MiniTask#mini_task.state of
        ?CONST_TASK_STATE_UNFINISHED ->
            {NewTargetList, State} = update_target(Player, MiniTask#mini_task.target, [], 0, 0),
            NewMiniTask	= MiniTask#mini_task{target = NewTargetList, state = State},
            update_task(Player, Tail, [NewMiniTask|TaskList]);
        ?CONST_TASK_STATE_FINISHED  ->
            {NewTargetList, State} = update_target(Player, MiniTask#mini_task.target, [], 0, 0),
            NewMiniTask = MiniTask#mini_task{target = NewTargetList, state = State},
            update_task(Player, Tail, [NewMiniTask|TaskList]);
        _ -> update_task(Player, Tail, [MiniTask|TaskList])
    end;
update_task(_Player, [], TaskList) ->
    TaskList;
update_task(Player, [Task|Tail], TaskList) ->
    update_task(Player, Tail, [Task|TaskList]).

%% 注意!
%% 只有杀怪/采集/收集等任务可以叠加，其他任务不能叠加
update_target(_Player, [#task_target{target_type = ?CONST_TASK_TARGET_TALK}|_Tail], TargetList, _TargetCount, _FinishedCount) ->
    {TargetList, ?CONST_TASK_STATE_UNFINISHED};
update_target(Player = #player{bag = Bag}, 
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_CTN_GOODS, as2 = TargetId, as3 = Count}|Tail], 
              TargetList, TargetCount, FinishedCount) ->
    CountHave = ctn_bag2_api:get_goods_count(Bag, TargetId),
    NewTarget = Target#task_target{ad1 = CountHave},
    NewFinishedCount = 
        if
            Count =< CountHave ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [NewTarget|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player = #player{bag = Bag}, 
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_GATHER, as3 = TargetId, as4 = Count}|Tail], 
              TargetList, TargetCount, FinishedCount) ->
    CountHave = ctn_bag2_api:get_goods_count(Bag, TargetId),
    NewTarget = Target#task_target{ad1 = CountHave},
    NewFinishedCount = 
        if
            Count =< CountHave ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [NewTarget|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player = #player{info = #info{lv = Lv}},
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_LV, as1 = TargetLv}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewTarget = Target#task_target{ad1 = Lv},
    NewFinishedCount = 
        if
            TargetLv =< Lv ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [NewTarget|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player = #player{skill = SkillData},
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_SKILL, as1 = SkillId, as2 = TargetLv}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    SkillList = SkillData#skill_data.skill,
    NewCount = 
        case lists:keyfind(SkillId, 1, SkillList) of
            {_SkillId, Lv, _} -> 
                Lv;
            ?false ->
                0
        end,
    NewTarget = Target#task_target{ad1 = NewCount},
    NewFinishedCount = 
        if
            TargetLv =< NewCount ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [NewTarget|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player, [Target = #task_target{target_type = ?CONST_TASK_TARGET_KILL, as3 = Count, ad1 = CurrentCount}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =< CurrentCount ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player, [Target = #task_target{target_type = ?CONST_TASK_TARGET_KILL_NPC, ad1 = CurrentCount}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            CurrentCount =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player, 
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_COPY, as1 = TargetCopyId, as2 = NoteType, as3 = IsHistory}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    CopyData     = Player#player.copy,
    IsPassed     = not copy_single_api:is_first(CopyData, TargetCopyId),
    {NewFinishedCount, Ad1} =
        if
            ?CONST_SYS_FALSE =:= IsHistory andalso ?CONST_SYS_TRUE =:= Target#task_target.ad1 andalso ?true =:= IsPassed -> 
                {FinishedCount + 1, ?CONST_SYS_TRUE};
            ?CONST_SYS_TRUE =:= IsHistory ->
                TaskData = Player#player.task,
                TaskNote = TaskData#task_data.note,
                case TaskNote of
                    ?null ->
                        {FinishedCount, ?CONST_SYS_FALSE};
                    _ ->
                        case lists:keyfind(NoteType, #task_note.id, TaskNote) of
                            #task_note{value = NoteList} ->
                                case lists:member(TargetCopyId, NoteList) of
                                    ?true ->
                                        {FinishedCount + 1, ?CONST_SYS_TRUE};
                                    ?false ->
                                        {FinishedCount, ?CONST_SYS_FALSE}
                                end;
                            _ ->
                                {FinishedCount, ?CONST_SYS_FALSE}
                        end
                end;
            ?true ->
                {FinishedCount, ?CONST_SYS_FALSE}
        end,
    NewTargetList = [Target#task_target{ad1 = Ad1}|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player, 
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_COLLECT, as4 = Count, ad1 = CurrentCount}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =< CurrentCount ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_ACTIVE, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_GUILD, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_GUILD_SKILL, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_DONATE, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_GUIDE, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_POWER, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count >= Target#task_target.as1 ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_SINGLE_ARENA, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count >= Target#task_target.as1 ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_FURNACE, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_POSITION, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    Position = player_position_api:current_position(Player),
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE orelse (Position >= Target#task_target.as1) ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_STREN, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_TRAIN, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player,
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_CAMP, ad1 = Count}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =:= ?CONST_SYS_TRUE ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(Player, 
              [Target = #task_target{target_type = ?CONST_TASK_TARGET_SUCC_N_COUNT, as2 = Count, ad1 = CurrentCount}|Tail],
              TargetList, TargetCount, FinishedCount) ->
    NewFinishedCount = 
        if
            Count =< CurrentCount ->
                FinishedCount + 1;
            ?true ->
                FinishedCount
        end,
    NewTargetList = [Target|TargetList],
    update_target(Player, Tail, NewTargetList, TargetCount + 1, NewFinishedCount);
update_target(_Player, [], TargetList, FinishedCount, FinishedCount) when FinishedCount =/= 0 ->
    {TargetList, ?CONST_TASK_STATE_FINISHED};
update_target(_Player, [], TargetList, _TargetCount, _FinishedCount) ->
    {TargetList, ?CONST_TASK_STATE_UNFINISHED}.





