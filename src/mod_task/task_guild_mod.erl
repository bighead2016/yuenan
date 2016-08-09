%% @author np
%% @doc @todo Add description to task_guild_mod.


-module(task_guild_mod).


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
-export([init_guild_cycle_task/0, confirm_guild_cycle/5, add_task/2, check_acceptable/2,
         do_accept/2, is_accepted/2, remove_task/2, reward/2,
         shadow_guild_task/1, unshadow_guild_task/1]).

%% 初始化军团环任务
init_guild_cycle_task() ->
    task_cycle_mod:init_task_cycle().

%% %% 军团环
%% confirm_guild_cycle(GuildCycleTask, 0, Today) when GuildCycleTask#task_cycle.date =/= Today ->
%%     GuildCycleTask2  = task_cycle_mod:reset_day(GuildCycleTask, Today),
%%     {Count1, Count2} = task_cycle_mod:get_unfinished_count(GuildCycleTask2),
%%     {GuildCycleTask2, <<>>, Count1, Count2};
%% confirm_guild_cycle(GuildCycleTask, _, Today) when GuildCycleTask#task_cycle.date =/= Today ->
%%     GuildCycleTask2 = task_cycle_mod:reset_day(GuildCycleTask, Today),
%%     CurrentTask     = GuildCycleTask2#task_cycle.current,
%%     Packet          = task_api:msg_task_info(CurrentTask),
%%     {Count1, Count2} = task_cycle_mod:get_unfinished_count(GuildCycleTask2),
%%     {GuildCycleTask2, Packet, Count1, Count2};
%% confirm_guild_cycle(GuildCycleTask, 0, _Today) -> % 当天
%%     {Count1, Count2} = task_cycle_mod:get_unfinished_count(GuildCycleTask),
%%     {GuildCycleTask, <<>>, Count1, Count2};
%% confirm_guild_cycle(GuildCycleTask, _, _Today) -> % 当天
%%     CurrentTask    = GuildCycleTask#task_cycle.current,
%%     Packet         = task_api:msg_task_info(CurrentTask),
%%     {Count1, Count2} = task_cycle_mod:get_unfinished_count(GuildCycleTask),
%%     {GuildCycleTask, Packet, Count1, Count2}.
%% 日常环
confirm_guild_cycle(_Player, CycleTask, GuildId, _MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =/= Today andalso
	   CycleTask#task_cycle.lib_id =/= 0 ->
    CycleTask2      	= task_cycle_mod:reset_day(CycleTask, Today),
    Packet          	= case GuildId of
							  0 -> <<>>;
							  _ ->
								  Packet20010	= task_api:msg_task_info(CycleTask2#task_cycle.current),
								  Packet20070	= task_api:msg_sc_guild_count(CycleTask2#task_cycle.times),
								  <<Packet20010/binary, Packet20070/binary>>
						  end,
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
    {CycleTask2, Packet, Count1, Count2};
confirm_guild_cycle(_Player, CycleTask, GuildId, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =/= Today andalso
	   CycleTask#task_cycle.lib_id =:= 0 ->
	CycleTask2			= recover_task_guild_cycle(CycleTask, MainTask),
    CycleTask3      	= task_cycle_mod:reset_day(CycleTask2, Today),
	Packet          	= case GuildId of
							  0 -> <<>>;
							  _ ->
								  Packet20010	= task_api:msg_task_info(CycleTask3#task_cycle.current),
								  Packet20070	= task_api:msg_sc_guild_count(CycleTask3#task_cycle.times),
								  <<Packet20010/binary, Packet20070/binary>>
						  end,
	{Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask3),
	{CycleTask3, Packet, Count1, Count2};
confirm_guild_cycle(Player, CycleTask, GuildId, _MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =:= Today andalso
	   CycleTask#task_cycle.lib_id =/= 0 ->
	CurrentTask			= task_mod:check_and_set_task_state(Player, CycleTask#task_cycle.current, ?CONST_TASK_POS_CONFIRM),
	Packet          	= case GuildId of
							  0 -> <<>>;
							  _ ->
								  Packet20010	= task_api:msg_task_info(CurrentTask),
								  Packet20070	= task_api:msg_sc_guild_count(CycleTask#task_cycle.times),
								  <<Packet20010/binary, Packet20070/binary>>
						  end,
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask),
    {CycleTask#task_cycle{current = CurrentTask}, Packet, Count1, Count2};
confirm_guild_cycle(_Player, CycleTask, GuildId, MainTask, Today)
  when is_record(CycleTask, task_cycle) andalso
	   CycleTask#task_cycle.date =:= Today andalso
	   CycleTask#task_cycle.lib_id =:= 0 ->
	CycleTask2			= recover_task_guild_cycle(CycleTask, MainTask),
	Packet          	= case GuildId of
							  0 -> <<>>;
							  _ ->
								  Packet20010	= task_api:msg_task_info(CycleTask2#task_cycle.current),
								  Packet20070	= task_api:msg_sc_guild_count(CycleTask2#task_cycle.times),
								  <<Packet20010/binary, Packet20070/binary>>
						  end,
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
    {CycleTask2, Packet, Count1, Count2};
confirm_guild_cycle(_Player, _CycleTask, GuildId, MainTask, _Today) ->
	CycleTask			= init_guild_cycle_task(),
	CycleTask2			= recover_task_guild_cycle(CycleTask, MainTask),
	Packet          	= case GuildId of
							  0 -> <<>>;
							  _ ->
								  Packet20010	= task_api:msg_task_info(CycleTask2#task_cycle.current),
								  Packet20070	= task_api:msg_sc_guild_count(CycleTask2#task_cycle.times),
								  <<Packet20010/binary, Packet20070/binary>>
						  end,
    {Count1, Count2}	= task_cycle_mod:get_unfinished_count(CycleTask2),
    {CycleTask2, Packet, Count1, Count2}.

%% 恢复日常任务
recover_task_guild_cycle(CycleTask, MainTask) ->
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
			case data_task:get_guild_lib(Idx) of
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
%%-----------------------------------------------------------------------------------
%% 接任务的条件:
%% 1.等级
%% 2.时间段
%% 3.前置任务不用考虑 -- 因为当前任务就是由前置而得到的
check_acceptable(Player, TaskId) when is_number(TaskId) ->
    TaskData   = Player#player.task,
    GuildCycle = TaskData#task_data.guild_cycle,
    TaskCur    = GuildCycle#task_cycle.current,
    if
        TaskCur#mini_task.id =:= TaskId ->
            Count = GuildCycle#task_cycle.times,
            TaskCur2 = TaskCur#mini_task{count = Count},
            check_acceptable(Player, TaskCur2);
        ?true ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
    end;
check_acceptable(Player, MiniTask) ->
    try
        Info    = Player#player.info,
        Lv      = Info#info.lv,
        Guild   = Player#player.guild,
        GuildId = Guild#guild.guild_id,
        Task    = task_api:read(MiniTask#mini_task.id),
        ?ok     = task_mod:false_throw(task_mod, is_in_guild, GuildId),
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
    GuildCycle  = TaskData#task_data.guild_cycle,
    GuildCycle2 = GuildCycle#task_cycle{current = MiniTask4, times = MiniTask4#mini_task.count},
    TaskData2   = TaskData#task_data{guild_cycle = GuildCycle2},
    Packet      = task_api:msg_task_info(MiniTask4),
    PacketDaily	= task_api:msg_sc_guild_count(GuildCycle2#task_cycle.times),
    Player2     = Player#player{task = TaskData2},
    {Player2, MiniTask4, <<Packet/binary, PacketDaily/binary>>}.

%%--------------------------------------------------------------------------------------------
is_accepted(TaskData, TaskId) when 0 =/= TaskId ->
    GuildCycle = TaskData#task_data.guild_cycle,
    CurTask = GuildCycle#task_cycle.current,
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
        {?error, ErrorCode} ->
            {?error, ErrorCode};
        {?ok, Player2, GoodsList, PacketBag} ->
            % 2
            case reward_special(Player2, ?CONST_COST_TASK_REWARD_GUILD) of
                {?ok, Player3} -> {?ok, Player3, GoodsList, PacketBag};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

reward_special(Player, Point) ->
    UserId   = Player#player.user_id,
    Info     = Player#player.info,
    Lv       = Info#info.lv,
	
	%% 军团战中占领城池的军团任务奖励提升100%：铜钱
	Guild    = Player#player.guild,
	GuildId  = Guild#guild.guild_id, 
	OccupyGuildId = guild_pvp_mod:get_tower_owner_id(),
	GoldBind = 
		if  GuildId =:= OccupyGuildId  ->
				?FUNC_GUILD_BGOLD(Lv) * 2;
			true ->
				?FUNC_GUILD_BGOLD(Lv)
		end,
	
    case task_mod:reward_gold_bind(UserId, GoldBind, Point) of
        ?ok ->
            Rate = guild_api:get_task_add(Player),
			%% 军团战中占领城池的军团任务奖励提升100%：经验、军贡
			{Exp, Exploit} = 
				if  GuildId =:= OccupyGuildId  ->
						{?FUNC_GUILD_EXP(Lv) * 2, 
						 round(?FUNC_GUILD_EXPLOIT(Lv) * (1 + Rate)) * 2
						 };
					true ->
						{?FUNC_GUILD_EXP(Lv),
						 round(?FUNC_GUILD_EXPLOIT(Lv) * (1 + Rate))
						 }
				end,
			
			{?ok, Player2}  = task_mod:reward_exp(Player, Exp, Point),
            {?ok, Player3}  = guild_api:plus_exploit(Player2, Exploit, Point), 
            GuildCycle     	= (Player3#player.task)#task_data.guild_cycle,
            {?ok, Player4} 	= task_cycle_mod:reward_cycle_end(Player3, GuildCycle, Point), 
            schedule_api:add_guide_times(Player4, ?CONST_SCHEDULE_GUIDE_GUILD_TASK);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

remove_task(Player, MiniTask) ->
    TaskData    = Player#player.task,
    GuildCycle  = TaskData#task_data.guild_cycle,
    GuildCycle2 = GuildCycle#task_cycle{current = ?null},
    TaskData2   = TaskData#task_data{guild_cycle = GuildCycle2},
    Player2     = Player#player{task = TaskData2},
    Packet      = task_api:msg_task_remove(MiniTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
    {Player2, Packet}.

%% add_task(Player, Task) ->
%%     TaskData    = Player#player.task,
%%     GuildCycle  = TaskData#task_data.guild_cycle,
%%     Count       = GuildCycle#task_cycle.times,
%%     if
%%         Count < Task#task.cycle ->
%%             Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = GuildCycle#task_cycle.times},
%%             GuildCycle2 = GuildCycle#task_cycle{current = Task2},
%%             TaskData2   = TaskData#task_data{guild_cycle = GuildCycle2},
%%             
%%             Guild       = Player#player.guild,
%%             GuildId     = Guild#guild.guild_id,
%%             Packet      = smart_packet(Task2, GuildId),
%%             Player2     = Player#player{task = TaskData2},
%%             {Player2, Packet};
%%         ?true ->
%%             {Player, <<>>}
%%     end.

add_task(Player, Task = #task{next = {random, LibId}}) ->
	TaskData    = Player#player.task,
	GuildCycle  = TaskData#task_data.guild_cycle,
	GuildId     = (Player#player.guild)#guild.guild_id,
	if
		GuildCycle#task_cycle.lib_id =:= LibId ->
			Count       = GuildCycle#task_cycle.times,
			if
				Count < Task#task.cycle ->
					Task2       = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = GuildCycle#task_cycle.times},
                    RemovePacket =
                        case GuildCycle#task_cycle.current of
                            #mini_task{id = OldTaskId} ->
                                task_api:msg_task_remove(OldTaskId, ?CONST_TASK_REMOVE_REASON_DOWN);
                            _ ->
                                <<>>
                        end,
                    MiniTask    = task_api:task_to_mini(Task2),
					GuildCycle2 = GuildCycle#task_cycle{current = MiniTask},
					TaskData2   = TaskData#task_data{guild_cycle = GuildCycle2},
					Player2     = Player#player{task = TaskData2},
					Packet      = smart_packet(MiniTask, GuildId),
					{Player2, <<RemovePacket/binary, Packet/binary>>};
				?true -> {Player, <<>>}
			end;
		GuildCycle#task_cycle.lib_id < LibId ->
			RecLib		= task_mod:read_lib(LibId),
			Lib   		= RecLib#rec_task_lib.tasks,
			Sp    		= RecLib#rec_task_lib.sp,
            GoodsList   = RecLib#rec_task_lib.goods,
			Count       = GuildCycle#task_cycle.times,
			{GuildCycle2, GuildPacket} =
				if
					Count < Task#task.cycle ->
						case GuildCycle#task_cycle.current of
							TaskOld when is_record(TaskOld, mini_task) andalso
											 (TaskOld#mini_task.state =:= ?CONST_TASK_STATE_UNFINISHED orelse
											  TaskOld#mini_task.state =:= ?CONST_TASK_STATE_FINISHED) ->
								{GuildCycle#task_cycle{lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, <<>>};
							TaskOld when is_record(TaskOld, mini_task) ->
								PacketRemove	= task_api:msg_task_remove(TaskOld#mini_task.id, ?CONST_TASK_REMOVE_REASON_DOWN),
								Task2       	= Task#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = GuildCycle#task_cycle.times},
								PacketNew		= smart_packet(Task2, GuildId),
								{GuildCycle#task_cycle{current = Task2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, 
                                                      <<PacketRemove/binary, PacketNew/binary>>};
							?null ->
								Task2       	= Task#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = GuildCycle#task_cycle.times},
								PacketNew		= smart_packet(Task2, GuildId),
								{GuildCycle#task_cycle{current = Task2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew};
							0 ->
								Task2       	= Task#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE, count = GuildCycle#task_cycle.times},
								PacketNew		= smart_packet(Task2, GuildId),
								{GuildCycle#task_cycle{current = Task2, lib_id = RecLib#rec_task_lib.id, lib = Lib, special_reward = Sp, goods = GoodsList}, PacketNew}
						end;
					?true -> {GuildCycle, <<>>}
				end,
			TaskData2   = TaskData#task_data{guild_cycle = GuildCycle2},
			Player2     = Player#player{task = TaskData2},
			{Player2, GuildPacket};
		GuildCycle#task_cycle.lib_id > LibId ->
			TaskId		= task_mod:get_next_lib_task(GuildCycle#task_cycle.lib_id),
			Task2		= task_api:read(TaskId),
			add_task(Player, Task2)
	end.

shadow_guild_task(TaskData) when is_record((TaskData#task_data.guild_cycle)#task_cycle.current, mini_task) ->
    % 1
    GuildCycle = TaskData#task_data.guild_cycle,
    CurTask    = GuildCycle#task_cycle.current,
    Count      = GuildCycle#task_cycle.times,
    State      = CurTask#mini_task.state,
    Task       = task_api:read(CurTask#mini_task.id),
    Cycle      = Task#task.cycle,
    if
        State =:= ?CONST_TASK_STATE_ACCEPTABLE andalso Cycle > Count ->
            Packet = task_api:msg_task_remove(CurTask#mini_task.id, ?CONST_TASK_REMOVE_REASON_ABANDON),
            Packet;
        ?true ->
            <<>>
    end;
shadow_guild_task(_TaskData) ->
    <<>>.

unshadow_guild_task(TaskData) when is_record((TaskData#task_data.guild_cycle)#task_cycle.current, mini_task) ->
    % 1
    GuildCycle = TaskData#task_data.guild_cycle,
    CurTask    = GuildCycle#task_cycle.current,
    Count      = GuildCycle#task_cycle.times,
    State      = CurTask#mini_task.state,
    Task       = task_api:read(CurTask#mini_task.id),
    Cycle      = Task#task.cycle,
    if
        (State =:= ?CONST_TASK_STATE_ACCEPTABLE orelse State =:= ?CONST_TASK_STATE_UNFINISHED orelse State =:= ?CONST_TASK_STATE_FINISHED) 
		  andalso Cycle > Count ->
            Packet = task_api:msg_task_info(CurTask),
			Packet20070	= task_api:msg_sc_guild_count(GuildCycle#task_cycle.times),
            <<Packet/binary, Packet20070/binary>>;
        ?true ->
            <<>>
    end;
unshadow_guild_task(_TaskData) ->
    <<>>.

%% ====================================================================
%% Internal functions
%% ====================================================================
smart_packet(_Task, 0) ->
    <<>>;
smart_packet(MiniTask, _) ->
    task_api:msg_task_info(MiniTask).
