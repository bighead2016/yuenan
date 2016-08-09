%%% 更新战斗任务
%%% 这部分可以写得更加简洁点的，有空的话可以改写下
-module(task_target_mod).

-include("const.common.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include("record.task.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([update_battle/4, update_active/3, update_copy/3, update_gather/3, update_guild/1,
         update_donate/1, update_guild_skill/1, update_guide/2, update_guide_2/2,
         update_power/2,  update_single_arena/1, update_furnace/2, update_position/2,
         update_furnace_stren/2, update_train/2, update_camp/2, update_guide_branch/2,
		 update_succ_count/2]).

%% 战斗更新任务
update_battle(Player, MapId, MonsterIdList, BattleParam) ->
	try
		TaskData    = Player#player.task,
		TaskMain    = TaskData#task_data.main,
		{FlagMain, [TaskMain2], GoodsListMain}
					= update_battle2([TaskMain], MapId, MonsterIdList, ?false, [], []),
		
		TaskBranch  = TaskData#task_data.branch,
		List1       = TaskBranch#branch_task.unfinished,
		{FlagBranch, List1_2, GoodsListBranch}
					= update_battle2(List1, MapId, MonsterIdList, ?false, [], []),
		TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
		
		GuildCycle  = TaskData#task_data.guild_cycle,
		GuildTask   = GuildCycle#task_cycle.current,
		{FlagGuild, [GuildTask2], GoodsListGuild}
					= update_battle2([GuildTask], MapId, MonsterIdList, ?false, [], []),
		GuildCycle2 = GuildCycle#task_cycle{current = GuildTask2},
		
		DailyCycle  = TaskData#task_data.daily_cycle,
		DailyTask   = DailyCycle#task_cycle.current,
		{FlagDaily, [DailyTask2], GoodsListDaily}
					= update_battle2([DailyTask], MapId, MonsterIdList, ?false, [], []),
		DailyCycle2 = DailyCycle#task_cycle{current = DailyTask2},
		
		PositionTask = TaskData#task_data.position_task,
		{FlagPosition, [PositionTask2], GoodsListPosition}
					= update_battle2([PositionTask], MapId, MonsterIdList, ?false, [], []),
		
		TaskData2   = TaskData#task_data{main = TaskMain2, branch = TaskBranch2, 
										 guild_cycle = GuildCycle2, daily_cycle = DailyCycle2,
										 position_task = PositionTask2},
		Player2     = Player#player{task = TaskData2},
		Flag        = if FlagMain orelse FlagBranch orelse FlagGuild orelse FlagDaily orelse FlagPosition -> ?true; ?true -> ?false end,
		GoodsList   = GoodsListMain ++ GoodsListBranch ++ GoodsListGuild ++ GoodsListDaily ++ GoodsListPosition,
		{?ok, Player2, Flag, GoodsList}
	catch
		Error:Reason ->
			?MSG_ERROR("~nMapId:~p~nMonsterIdList:~w~nBattleParam:~p~n", [MapId, MonsterIdList, BattleParam]),
			?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?ok, Player, ?false, []}
	end.

update_battle2([#mini_task{state = ?CONST_TASK_STATE_UNFINISHED} = MiniTask|TaskList], MapId, MonsterIdList, Flag, AccTaskList, AccGoodsList) ->
    {Flag2, AccGoodsList2, Task2}   = update_battle3(MiniTask, MapId, Flag, AccGoodsList, MonsterIdList),
    update_battle2(TaskList, MapId, MonsterIdList, Flag2, [Task2|AccTaskList], AccGoodsList2);
update_battle2([Task|TaskList], MapId, MonsterIdList, Flag, AccTaskList, AccGoodsList) ->
%%  {Flag2, AccGoodsList2, Task2}   = update_battle3(Task, MapId, Flag, AccGoodsList, MonsterIdList),
    update_battle2(TaskList, MapId, MonsterIdList, Flag, [Task|AccTaskList], AccGoodsList);
update_battle2([], _MapId, _MonsterIdList, Flag, AccTaskList, AccGoodsList) ->
    {Flag, AccTaskList, AccGoodsList};
update_battle2(X, _MapId, _MonsterIdList, Flag, AccTaskList, AccGoodsList) ->
    {Flag, [X|AccTaskList], AccGoodsList}.

update_battle3(MiniTask, MapId, Flag, AccGoodsList, MonsterIdList) ->
    {Flag2, AccGoodsList2, TargetList} = update_battle4(MiniTask#mini_task.target, MapId, MonsterIdList, Flag, AccGoodsList, []),
    {Flag2, AccGoodsList2, MiniTask#mini_task{target = TargetList}}.

update_battle4([Target|TargetList], MapId, MonsterIdList, Flag, AccGoodsList, AccTargetList)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL andalso
       (Target#task_target.as1 =:= MapId orelse MapId =:= 0) ->
    F = fun({MonsterId}, {_AccFlag, AccTarget})
             when AccTarget#task_target.as2 =:= MonsterId andalso
                  AccTarget#task_target.as3 > AccTarget#task_target.ad1 ->
                Count   = AccTarget#task_target.ad1 + 1,
                {?true, AccTarget#task_target{ad1 = Count}};
           ({_MonsterId}, {AccFlag, AccTarget}) -> 
                {AccFlag, AccTarget}
        end,
    {Flag2, Target2}    = lists:foldl(F, {Flag, Target}, MonsterIdList),
    update_battle4(TargetList, MapId, MonsterIdList, Flag2, AccGoodsList, [Target2|AccTargetList]);
update_battle4([Target|TargetList], MapId, MonsterIdList, Flag, AccGoodsList, AccTargetList)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL_NPC ->
    F = fun({MonsterId}, {_AccFlag, AccTarget})
             when AccTarget#task_target.as1 =:= MonsterId ->
                {?true, AccTarget#task_target{ad1 = ?CONST_SYS_TRUE}};
           ({_MonsterId}, {AccFlag, AccTarget}) ->
                {AccFlag, AccTarget}
        end,
    {Flag2, Target2}    = lists:foldl(F, {Flag, Target}, MonsterIdList),
    update_battle4(TargetList, MapId, MonsterIdList, Flag2, AccGoodsList, [Target2|AccTargetList]);
update_battle4([Target|TargetList], MapId, MonsterIdList, Flag, AccGoodsList, AccTargetList)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COLLECT andalso
       (Target#task_target.as1 =:= MapId orelse MapId =:= 0) ->
    F = fun({MonsterId}, {AccFlag, AccGoodsListTemp, AccTarget})
             when AccTarget#task_target.as2 =:= MonsterId andalso
                  AccTarget#task_target.as4 > AccTarget#task_target.ad1 ->
                case misc_random:odds(AccTarget#task_target.as5, 100) of
                    ?true ->
                        Goods   = goods_api:make(AccTarget#task_target.as3, ?CONST_GOODS_BIND, 1),
                        AccGoodsListTemp2   = [Goods|AccGoodsListTemp],
                        Count   = AccTarget#task_target.ad1 + 1,
                        {?true, AccGoodsListTemp2, AccTarget#task_target{ad1 = Count}};
                    ?false -> 
                        {AccFlag, AccGoodsListTemp, AccTarget}
                end;
           ({_MonsterId}, {AccFlag, AccGoodsListTemp, AccTarget}) -> 
                {AccFlag, AccGoodsListTemp, AccTarget}
        end,
    {Flag2, AccGoodsList2, Target2} = lists:foldl(F, {Flag, AccGoodsList, Target}, MonsterIdList),
    update_battle4(TargetList, MapId, MonsterIdList, Flag2, AccGoodsList2, [Target2|AccTargetList]);
update_battle4([Target|TargetList], MapId, MonsterIdList, Flag, AccGoodsList, AccTargetList) ->
    update_battle4(TargetList, MapId, MonsterIdList, Flag, AccGoodsList, [Target|AccTargetList]);
update_battle4([], _MapId, _MonsterIdList, Flag, AccGoodsList, AccTargetList) ->
    {Flag, AccGoodsList, AccTargetList}.

%% 采集更新任务
update_gather(Player, MapId, GatherId) ->
    UserId = Player#player.user_id,
    
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_gather2([TaskMain], MapId, GatherId, []),
    
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_gather2(List1, MapId, GatherId, []),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    
    GuildCycle   = TaskData#task_data.guild_cycle,
    GuildTask    = GuildCycle#task_cycle.current,
    [GuildTask2] = update_gather2([GuildTask], MapId, GatherId, []),
    GuildCycle2  = GuildCycle#task_cycle{current = GuildTask2},
    
    DailyCycle   = TaskData#task_data.daily_cycle,
    DailyTask    = DailyCycle#task_cycle.current,
    [DailyTask2] = update_gather2([DailyTask], MapId, GatherId, []),
    DailyTask2  = DailyCycle#task_cycle{current = DailyTask2},
    
    PositionTask = TaskData#task_data.position_task,
    [PositionTask2] = update_gather2([PositionTask], MapId, GatherId, []),
    
    TaskData2   = TaskData#task_data{main = TaskMain2, branch = TaskBranch2, 
                                     guild_cycle = GuildCycle2, daily_cycle = DailyTask2,
                                     position_task = PositionTask2},
    Player2     = Player#player{task = TaskData2},
    
    NewPlayer = 
        case data_collect:get_gather(GatherId) of
            RecGather when is_record(RecGather, gather) ->
                GoodsId = RecGather#gather.goods_id,
                GoodsList = goods_api:make(GoodsId, ?CONST_GOODS_BIND, 1),
                case ctn_bag_api:put(Player2, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 0, 0, 0, 1, []) of
                    {?ok, Player3, _, PacketBagChanged} ->
                        PacketOk = message_api:msg_notice(?TIP_MAP_GATHER_OK),
                        misc_packet:send(UserId, <<PacketBagChanged/binary, PacketOk/binary>>),
                        Player3;
                    {?error, ErrorCode} ->
                        PacketErr = message_api:msg_notice(ErrorCode),
                        misc_packet:send(UserId, PacketErr),
                        Player2
                end;
            RecGather when is_record(RecGather, rec_collect) ->
                Packet = message_api:msg_notice(?TIP_MAP_NOT_NEARBY),
                misc_packet:send(UserId, Packet),
                Player2;
            _ ->
                Packet = message_api:msg_notice(?TIP_MAP_NO_GATHER),
                misc_packet:send(UserId, Packet),
                Player2
        end,
    
    {?ok, NewPlayer}.
update_gather2([Task|TaskList], MapId, GatherId, Acc) ->
    Task2   = update_gather3(Task, MapId, GatherId),
    update_gather2(TaskList, MapId, GatherId, [Task2|Acc]);
update_gather2([], _MapId, _GatherId, Acc) -> Acc;
update_gather2(X, _MapId, _GatherId, Acc) -> [X|Acc].

update_gather3(Task, MapId, GatherId) ->
    Target  = update_gather4(Task#mini_task.target, MapId, GatherId, []),
    Task#mini_task{target = Target}.

update_gather4([Target|TargetList], MapId, GatherId, Acc)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GATHER andalso
       (Target#task_target.as1 =:= MapId orelse MapId =:= 0) andalso
       Target#task_target.as2 =:= GatherId andalso
       Target#task_target.as3 < Target#task_target.ad1 ->
    Target2 = Target#task_target{ad1 = Target#task_target.ad1 + 1},
    update_gather4(TargetList, MapId, GatherId, [Target2|Acc]);
update_gather4([Target|TargetList], MapId, GatherId, Acc) ->
    update_gather4(TargetList, MapId, GatherId, [Target|Acc]);
update_gather4([], _MapId, _GatherId, Acc) -> Acc.

%% 完成副本更新任务
update_copy(Player, CopyId, NoteType) ->
    TaskData    = Player#player.task,
    TaskMain3   = 
        case TaskData#task_data.main of
            ?null ->
                ?null;
            0 ->
                0;
            TaskMain when is_record(TaskMain, mini_task) ->
                [TaskMain2] = update_copy2([TaskMain], CopyId, [], NoteType),
                TaskMain2
        end,
    
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_copy2(List1, CopyId, [], NoteType),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    
    GuildCycle   = TaskData#task_data.guild_cycle,
    GuildTask    = GuildCycle#task_cycle.current,
    GuildCycle2  = 
        case GuildTask of
            GuildTask when is_record(GuildTask, mini_task) ->
                [GuildTask2] = update_copy2([GuildTask], CopyId, [], NoteType),
                GuildCycle#task_cycle{current = GuildTask2};
            _ ->
                GuildCycle
        end,
    
    DailyCycle   = TaskData#task_data.daily_cycle,
    DailyTask    = DailyCycle#task_cycle.current,
    DailyCycle2  = 
        case DailyTask of
            DailyTask when is_record(DailyTask, mini_task) ->
                [DailyTask2] = update_copy2([DailyTask], CopyId, [], NoteType),
                DailyCycle#task_cycle{current = DailyTask2};
            _ ->
                DailyCycle
        end,
    
    PositionTask  = TaskData#task_data.position_task,
    PositionTask2 = 
        case PositionTask of
            PositionTask when is_record(PositionTask, mini_task) ->
                [TPositionTask2] = update_copy2([PositionTask], CopyId, [], NoteType),
                TPositionTask2;
            _ ->
                PositionTask
        end,
    
    TaskData2   = TaskData#task_data{main = TaskMain3, branch = TaskBranch2, 
                                     guild_cycle = GuildCycle2, daily_cycle = DailyCycle2,
                                     position_task = PositionTask2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_copy2([Task|TaskList], CopyId, Acc, NoteType) ->
    Task2   = update_copy3(Task, CopyId, NoteType),
    update_copy2(TaskList, CopyId, [Task2|Acc], NoteType);
update_copy2([], _CopyId, Acc, _NoteType) -> Acc.

update_copy3(Task, CopyId, NoteType) ->
    Target  = update_copy4(Task#mini_task.target, CopyId, [], NoteType),
    Task#mini_task{target = Target}.

update_copy4([Target|TargetList], CopyId, Acc, NoteType)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COPY 
    andalso Target#task_target.as2 =:= NoteType 
    andalso Target#task_target.as1 =:= CopyId ->
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    update_copy4(TargetList, CopyId, [Target2|Acc], NoteType);
update_copy4([Target|TargetList], CopyId, Acc, NoteType) ->
    update_copy4(TargetList, CopyId, [Target|Acc], NoteType);
update_copy4([], _CopyId, Acc, _NoteType) -> 
    Acc.

%% 完成副本更新任务
update_active(Player, ActiveType, _Id) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_active2(List1, ActiveType, [], ?CONST_SYS_FALSE, UserId),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_active2([Task|TaskList], ActiveType, Acc, IsFinished, UserId) ->
    {Task2, IsFinished2}   = update_active3(Task, ActiveType, IsFinished),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_active2(TaskList, ActiveType, [Task3|Acc], ?CONST_SYS_FALSE, UserId);
update_active2([], _ActiveType, Acc, _IsFinished, _UserId) -> Acc.

update_active3(Task, ActiveType, IsFinished) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_active4(Task#mini_task.target, ActiveType, [], IsFinished),
    {Task#mini_task{target = Target}, IsFinished2};
update_active3(Task, _ActiveType, IsFinished) ->
    {Task, IsFinished}.

update_active4([Target|TargetList], ActiveType, Acc, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_ACTIVE andalso
       Target#task_target.as1 =:= ActiveType ->
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    update_active4(TargetList, ActiveType, [Target2|Acc], ?CONST_SYS_TRUE);
update_active4([Target|TargetList], ActiveType, Acc, IsFinished) ->
    update_active4(TargetList, ActiveType, [Target|Acc], IsFinished);
update_active4([], _ActiveType, Acc, IsFinished) -> {Acc, IsFinished}.

%% 加入或创建军团完成任务
update_guild(Player) ->
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
	{
	 TaskList, Packet
	} 			= update_guild2(TaskBranch#branch_task.unfinished, [], <<>>),
    TaskBranch2 = TaskBranch#branch_task{unfinished = TaskList},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
	misc_packet:send(Player#player.net_pid, Packet),
    Player2.

update_guild2([Task|TaskList], AccTask, AccPacket) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
	{Target, IsFinished}	= update_guild3(Task#mini_task.target, [], ?CONST_SYS_FALSE),
	Task2					= Task#mini_task{target = Target},
	case IsFinished of
		?CONST_SYS_TRUE ->
			Task3	= Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
			Packet	= task_api:msg_task_info(Task3),
			update_guild2(TaskList, [Task3|AccTask], <<AccPacket/binary, Packet/binary>>);
		?CONST_SYS_FALSE ->
			update_guild2(TaskList, [Task2|AccTask], AccPacket)
	end;
update_guild2([Task|TaskList], AccTask, AccPacket) ->
	update_guild2(TaskList, [Task|AccTask], AccPacket);
update_guild2([], AccTask, AccPacket) ->
	{AccTask, AccPacket}.

update_guild3([Target|TargetList], AccTarget, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD ->
	Target2 	= Target#task_target{ad1 = ?CONST_SYS_TRUE},
	update_guild3(TargetList, [Target2|AccTarget], ?CONST_SYS_TRUE);
update_guild3([Target|TargetList], AccTarget, IsFinished) ->
    update_guild3(TargetList, [Target|AccTarget], IsFinished);
update_guild3([], AccTarget, IsFinished) -> {AccTarget, IsFinished}.

%% 军团贡献任务
update_donate(Player) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_donate2(List1, [], ?CONST_SYS_FALSE, UserId),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_donate2([Task|TaskList], Acc, IsFinished, UserId) ->
    {Task2, IsFinished2}   = update_donate3(Task, IsFinished),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_donate2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId);
update_donate2([], Acc, _IsFinished, _UserId) -> Acc.

update_donate3(Task, IsFinished) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_donate4(Task#mini_task.target, [], IsFinished),
    {Task#mini_task{target = Target}, IsFinished2};
update_donate3(Task, IsFinished) ->
    {Task, IsFinished}.

update_donate4([Target|TargetList], Acc, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_DONATE ->
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    update_donate4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE);
update_donate4([Target|TargetList], Acc, IsFinished) ->
    update_donate4(TargetList, [Target|Acc], IsFinished);
update_donate4([], Acc, IsFinished) -> {Acc, IsFinished}.

%% 拥有军团技能
update_guild_skill(Player) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_guild_skill2(List1, [], ?CONST_SYS_FALSE, UserId),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_guild_skill2([Task|TaskList], Acc, IsFinished, UserId) ->
    {Task2, IsFinished2}   = update_guild_skill3(Task, IsFinished),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_guild_skill2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId);
update_guild_skill2([], Acc, _IsFinished, _UserId) -> Acc.

update_guild_skill3(Task, IsFinished) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_guild_skill4(Task#mini_task.target, [], IsFinished),
    {Task#mini_task{target = Target}, IsFinished2};
update_guild_skill3(Task, IsFinished) ->
    {Task, IsFinished}.

update_guild_skill4([Target|TargetList], Acc, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD_SKILL ->
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    update_guild_skill4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE);
update_guild_skill4([Target|TargetList], Acc, IsFinished) ->
    update_guild_skill4(TargetList, [Target|Acc], IsFinished);
update_guild_skill4([], Acc, IsFinished) -> {Acc, IsFinished}.

%% 拥有军团技能
update_guide_2(Player, ?CONST_MODULE_SINGLEARENA = GuideId) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    TaskMain2   = update_guide2(TaskMain, GuideId, ?CONST_SYS_FALSE, UserId),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.
update_guide(Player, ?CONST_MODULE_SINGLEARENA) ->
    {?ok, Player};
update_guide(Player, GuideId) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    TaskMain2   = update_guide2(TaskMain, GuideId, ?CONST_SYS_FALSE, UserId),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_guide2(Task, GuideId, IsFinished, UserId) ->
    {Task2, IsFinished2}   = update_guide3(Task, GuideId, IsFinished),
    if
        IsFinished2 =:= ?CONST_SYS_TRUE ->
            Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
            Packet = task_api:msg_task_info(Task2T),
            misc_packet:send(UserId, Packet),
            Task2T;
        ?true ->
            Task2
    end.

%%支线引导任务
update_guide_branch(Player, GuideId) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    TaskBranch2   = update_guide_branch2(List1, [], GuideId, ?CONST_SYS_FALSE, UserId),
	TaskBranch3 = TaskBranch#branch_task{unfinished = TaskBranch2},
    TaskData2   = TaskData#task_data{branch = TaskBranch3},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.
update_guide_branch2([Task|TaskList], Acc, GuideId, IsFinished, UserId) ->
	{Task2, IsFinished2}   = update_guide3(Task, GuideId, IsFinished),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_guide_branch2(TaskList, [Task3|Acc], GuideId, ?CONST_SYS_FALSE, UserId);
update_guide_branch2([], Acc, _, _IsFinished, _UserId) -> Acc.	

update_guide3(Task, GuideId, IsFinished) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_guide4(Task#mini_task.target, [], GuideId, IsFinished),
    {Task#mini_task{target = Target}, IsFinished2};
update_guide3(Task, _GuideId, IsFinished) ->
    {Task, IsFinished}.

update_guide4([Target|TargetList], Acc, GuideId, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUIDE 
                          andalso GuideId =:= Target#task_target.as1 ->
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    update_guide4(TargetList, [Target2|Acc], GuideId, ?CONST_SYS_TRUE);
update_guide4([Target|TargetList], Acc, GuideId, IsFinished) ->
    update_guide4(TargetList, [Target|Acc], GuideId, IsFinished);
update_guide4([], Acc, _GuideId, IsFinished) -> {Acc, IsFinished}.

%% 更新战力任务
update_power(Player, Power) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_power2(List1, [], ?CONST_SYS_FALSE, UserId, Power),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_power2([Task|TaskList], Acc, IsFinished, UserId, Power) ->
    {Task2, IsFinished2}   = update_power3(Task, IsFinished, Power),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_power2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, Power);
update_power2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_power3(Task, IsFinished, Power) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_power4(Task#mini_task.target, [], IsFinished, Power),
    {Task#mini_task{target = Target}, IsFinished2};
update_power3(Task, IsFinished, _Power) ->
    {Task, IsFinished}.

update_power4([Target|TargetList], Acc, _IsFinished, Power)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POWER ->
    if(Power >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = Target#task_target.as1},
        update_power4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, Power);
    ?true ->
        update_power4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, Power)
    end;
update_power4([Target|TargetList], Acc, IsFinished, Power) ->
    update_power4(TargetList, [Target|Acc], IsFinished, Power);
update_power4([], Acc, IsFinished, _Power) -> {Acc, IsFinished}.

%% 任务目标--一骑讨
update_single_arena(Player) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskBranch  = TaskData#task_data.branch,
    List1       = TaskBranch#branch_task.unfinished,
    List1_2     = update_single_arena2(List1, [], ?CONST_SYS_FALSE, UserId),
    TaskBranch2 = TaskBranch#branch_task{unfinished = List1_2},
    TaskData2   = TaskData#task_data{branch = TaskBranch2},
    Player2     = Player#player{task = TaskData2},
    {?ok, Player2}.

update_single_arena2([Task|TaskList], Acc, IsFinished, UserId) ->
    {Task2, IsFinished2}   = update_single_arena3(Task, IsFinished),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_single_arena2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId);
update_single_arena2([], Acc, _IsFinished, _UserId) -> Acc.

update_single_arena3(Task, IsFinished) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_single_arena4(Task#mini_task.target, [], IsFinished),
    {Task#mini_task{target = Target}, IsFinished2};
update_single_arena3(Task, IsFinished) ->
    {Task, IsFinished}.

update_single_arena4([Target|TargetList], Acc, _IsFinished)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SINGLE_ARENA ->
    Ad2 = Target#task_target.ad1+1,
    if(Ad2 >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = Target#task_target.as1},
        update_single_arena4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE);
    ?true ->
        Target2 = Target#task_target{ad1 = Ad2},
        update_single_arena4(TargetList, [Target2|Acc], ?CONST_SYS_FALSE)
    end;
update_single_arena4([Target|TargetList], Acc, IsFinished) ->
    update_single_arena4(TargetList, [Target|Acc], IsFinished);
update_single_arena4([], Acc, IsFinished) -> {Acc, IsFinished}.

%% 锻造任务
update_furnace(Player, Color) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_furnace2([TaskMain], [], ?CONST_SYS_FALSE, UserId, Color),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
%%     Packet      = task_api:msg_task_info(TaskMain2),
%%     misc_packet:send(UserId, Packet),
    {?ok, Player2}.

update_furnace2([Task|TaskList], Acc, IsFinished, UserId, Color) ->
    {Task2, IsFinished2}   = update_furnace3(Task, IsFinished, Color),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_furnace2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, Color);
update_furnace2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_furnace3(Task, IsFinished, Color) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_furnace4(Task#mini_task.target, [], IsFinished, Color),
    {Task#mini_task{target = Target}, IsFinished2};
update_furnace3(Task, IsFinished, _Color) ->
    {Task, IsFinished}.

update_furnace4([Target|TargetList], Acc, _IsFinished, Color)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_FURNACE ->
    if(Color >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
        update_furnace4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, Color);
    ?true ->
        update_furnace4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, Color)
    end;
update_furnace4([Target|TargetList], Acc, IsFinished, Color) ->
    update_furnace4(TargetList, [Target|Acc], IsFinished, Color);
update_furnace4([], Acc, IsFinished, _Color) -> {Acc, IsFinished}.

%% 官衔升级任务
update_position(Player, PositionLv) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_position2([TaskMain], [], ?CONST_SYS_FALSE, UserId, PositionLv),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
%%     Packet      = task_api:msg_task_info(TaskMain2),
%%     misc_packet:send(UserId, Packet),
    {?ok, Player2}.

update_position2([Task|TaskList], Acc, IsFinished, UserId, PositionLv) ->
    {Task2, IsFinished2}   = update_position3(Task, IsFinished, PositionLv),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_position2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, PositionLv);
update_position2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_position3(Task, IsFinished, PositionLv) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_position4(Task#mini_task.target, [], IsFinished, PositionLv),
    {Task#mini_task{target = Target}, IsFinished2};
update_position3(Task, IsFinished, _PositionLv) ->
    {Task, IsFinished}.

update_position4([Target|TargetList], Acc, _IsFinished, PositionLv)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POSITION ->
    if(PositionLv >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
        update_position4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, PositionLv);
    ?true ->
        update_position4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, PositionLv)
    end;
update_position4([Target|TargetList], Acc, IsFinished, PositionLv) ->
    update_position4(TargetList, [Target|Acc], IsFinished, PositionLv);
update_position4([], Acc, IsFinished, _PositionLv) -> {Acc, IsFinished}.

%% 强化等级任务
update_furnace_stren(Player, StrLv) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_furnace_stren2([TaskMain], [], ?CONST_SYS_FALSE, UserId, StrLv),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
%%     Packet      = task_api:msg_task_info(TaskMain2),
%%     misc_packet:send(UserId, Packet),
    {?ok, Player2}.

update_furnace_stren2([Task|TaskList], Acc, IsFinished, UserId, StrLv) ->
    {Task2, IsFinished2}   = update_furnace_stren3(Task, IsFinished, StrLv),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_furnace_stren2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, StrLv);
update_furnace_stren2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_furnace_stren3(Task, IsFinished, StrLv) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_furnace_stren4(Task#mini_task.target, [], IsFinished, StrLv),
    {Task#mini_task{target = Target}, IsFinished2};
update_furnace_stren3(Task, IsFinished, _StrLv) ->
    {Task, IsFinished}.

update_furnace_stren4([Target|TargetList], Acc, _IsFinished, StrLv)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_STREN ->
    if(StrLv >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
        update_furnace_stren4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, StrLv);
    ?true ->
        update_furnace_stren4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, StrLv)
    end;
update_furnace_stren4([Target|TargetList], Acc, IsFinished, StrLv) ->
    update_furnace_stren4(TargetList, [Target|Acc], IsFinished, StrLv);
update_furnace_stren4([], Acc, IsFinished, _StrLv) -> {Acc, IsFinished}.

%% 培养等级任务
update_train(Player, TrainLv) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_train2([TaskMain], [], ?CONST_SYS_FALSE, UserId, TrainLv),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
%%     Packet      = task_api:msg_task_info(TaskMain2),
%%     misc_packet:send(UserId, Packet),
    {?ok, Player2}.

update_train2([Task|TaskList], Acc, IsFinished, UserId, TrainLv) ->
    {Task2, IsFinished2}   = update_train3(Task, IsFinished, TrainLv),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_train2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, TrainLv);
update_train2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_train3(Task, IsFinished, TrainLv) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_train4(Task#mini_task.target, [], IsFinished, TrainLv),
    {Task#mini_task{target = Target}, IsFinished2};
update_train3(Task, IsFinished, _TrainLv) ->
    {Task, IsFinished}.

update_train4([Target|TargetList], Acc, _IsFinished, TrainLv)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_TRAIN ->
    if(TrainLv >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
        update_train4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, TrainLv);
    ?true ->
        update_train4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, TrainLv)
    end;
update_train4([Target|TargetList], Acc, IsFinished, TrainLv) ->
    update_train4(TargetList, [Target|Acc], IsFinished, TrainLv);
update_train4([], Acc, IsFinished, _TrainLv) -> {Acc, IsFinished}.

%% 阵法等级任务
update_camp(Player, CampLv) ->
    UserId      = Player#player.user_id,
    TaskData    = Player#player.task,
    TaskMain    = TaskData#task_data.main,
    [TaskMain2] = update_camp2([TaskMain], [], ?CONST_SYS_FALSE, UserId, CampLv),
    TaskData2   = TaskData#task_data{main = TaskMain2},
    Player2     = Player#player{task = TaskData2},
%%     Packet      = task_api:msg_task_info(TaskMain2),
%%     misc_packet:send(UserId, Packet),
    {?ok, Player2}.

update_camp2([Task|TaskList], Acc, IsFinished, UserId, CampLv) ->
    {Task2, IsFinished2}   = update_camp3(Task, IsFinished, CampLv),
    Task3 = 
        if
            IsFinished2 =:= ?CONST_SYS_TRUE ->
                Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
                Packet = task_api:msg_task_info(Task2T),
                misc_packet:send(UserId, Packet),
                Task2T;
            ?true ->
                Task2
        end,
    update_camp2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, CampLv);
update_camp2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_camp3(Task, IsFinished, CampLv) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
    {Target, IsFinished2}  = update_camp4(Task#mini_task.target, [], IsFinished, CampLv),
    {Task#mini_task{target = Target}, IsFinished2};
update_camp3(Task, IsFinished, _CampLv) ->
    {Task, IsFinished}.

update_camp4([Target|TargetList], Acc, _IsFinished, CampLv)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_CAMP ->
    if(CampLv >= Target#task_target.as1) ->
        Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
        update_camp4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, CampLv);
    ?true ->
        update_camp4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, CampLv)
    end;
update_camp4([Target|TargetList], Acc, IsFinished, CampLv) ->
    update_camp4(TargetList, [Target|Acc], IsFinished, CampLv);
update_camp4([], Acc, IsFinished, _CampLv) -> {Acc, IsFinished}.


update_succ_count(Player, ModuleId) ->
	UserId      	= Player#player.user_id,
    TaskData    	= Player#player.task,
	EverydayList	= TaskData#task_data.everyday_task,
	EverydayList2   = update_succ_count2(EverydayList, [], ?CONST_SYS_FALSE, UserId, ModuleId),
    TaskData2  		= TaskData#task_data{everyday_task = EverydayList2},
    Player2     	= Player#player{task = TaskData2},
    {?ok, Player2}.

update_succ_count2([Task|TaskList], Acc, IsFinished, UserId, ModuleId) ->
	{Task2, IsFinished2}   = update_succ_count3(Task, IsFinished, ModuleId),
	Task3 = 
		if
			IsFinished2 =:= ?CONST_SYS_TRUE ->
				Task2T = Task2#mini_task{state = ?CONST_TASK_STATE_FINISHED},
				Packet = task_api:msg_task_info(Task2T),
				misc_packet:send(UserId, Packet),
				Task2T;
			?true ->
				Task2
		end,
	update_succ_count2(TaskList, [Task3|Acc], ?CONST_SYS_FALSE, UserId, ModuleId);
update_succ_count2([], Acc, _IsFinished, _UserId, _) -> Acc.

update_succ_count3(Task, IsFinished, ModuleId) when Task#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED ->
	{Target, IsFinished2}  = update_succ_count4(Task#mini_task.target, [], IsFinished, ModuleId),
	{Task#mini_task{target = Target}, IsFinished2};
update_succ_count3(Task, IsFinished, _ModuleId) ->
	{Task, IsFinished}.

update_succ_count4([Target|TargetList], Acc, _IsFinished, ModuleId)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SUCC_N_COUNT ->
	if(ModuleId == Target#task_target.as1) ->
		  Ad1 = Target#task_target.ad1+1,
		  if(Ad1 >= Target#task_target.as2) ->
				Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
				update_succ_count4(TargetList, [Target2|Acc], ?CONST_SYS_TRUE, ModuleId);
			?true ->
				update_succ_count4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, ModuleId)
		  end;
	  ?true ->
		  update_succ_count4(TargetList, [Target|Acc], ?CONST_SYS_FALSE, ModuleId)
	end;
update_succ_count4([], Acc, IsFinished, _ModuleId) -> {Acc, IsFinished}.
%% ====================================================================
%% Internal functions
%% ====================================================================


