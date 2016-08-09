%%% 任务对外接口
%%% 任务模块代码分布规则如下：
%%% 1.task_mod负责处理所有的琐碎逻辑，所有task_*都可以直接调用这个模块处理一些不想在其他模块处理的事
%%% 2.task_login_mod处理和人物login/logout等相关的操作
%%% 3.task_main_mod/task_branch_mod/task_position_mod/task_guild_mod/task_daily_mod等分别是处理各种
%%%   任务类型的任务。这些模块要实现task_mod中定义的一些接口。
-module(task_api).

%%
%% Include files
%%
-include("const.common.hrl").            % 
-include("const.define.hrl").            %
-include("const.protocol.hrl").          % 
-include("const.tip.hrl").               % 

-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").        % #rec_task{}
-include("record.task.hrl").

%%
%% Exported Functions
%%
-export([read/1, mini_to_task/1]).         % 读取静态数据
-export([zip/1, unzip/1, login/1, task_to_mini/1, get_prev_id/1]). % 与数据库交互前后的数据压缩与还原
-export([get_main_task_id/1, get_task_daily_times/1, get_task_guild_times/1]).	% 日常任务、军团任务剩余次数
-export([update_battle/5, update_copy/3, do_update_battle/2, update_gather/3,
		 update_active/2, upgrade_position/3, update_guild/1, update_donate/1,
         update_guild_skill/1, update_guide/2, update_power/2, update_guide_sysid/2,
         update_single_arena/1, update_furnace/2, update_position/2,
         update_furnace_stren/2, update_train/2, update_camp/2,update_succ_count/2]). %  更新
-export([create/1, login_packet/2, level_up/1, logout/1, refresh/1,          % 人物动作影响
         accept/2, add_acceptable/2, level_up/2, get_last_accept_task/1]).
-export([shadow_guild_task/1, unshadow_guild_task/1]). % 军团影响
-export([msg_task_info/1, msg_task_remove/2, msg_sc_not_acceptable_main/1,
		 msg_sc_daily_count/1, msg_sc_guild_count/1]). % 打包
-export([finish_elite_copy/2, finish_invasion/2, finish_mcopy/2, finish_tower/2]). % 行为反记录

%%
%% API Functions
%% 

%%----------------------------读取静态数据-------------------------------------------
%% desc: 读取任务静态数据
%% in:   task_id::integer()
%% out:  #task{}/null
read(TaskId) ->
    task_mod:read(TaskId).

%% desc: 读取前置任务id
%% in:   #mini_task{}/any
%% out:  integer()
get_prev_id(#mini_task{id = Id}) ->
    Task = task_api:read(Id),
    Task#task.prev;
get_prev_id(_) ->
    data_task:get_last_id_list().

%%------------------------与数据库交互前后的数据压缩与还原----------------------------
%% 基于以下2点才这样做的：
%%     1.静态数据在下线后发生变化，所以上线后对现有数据要进行一轮转换或者筛选；
%%     2.减少需要保存的数据量。
%%       和其他zip/unzip函数一样，实现时并没有真的对数据进行了传统意义上的压缩，
%%       所以并不会过多地消耗cpu资源，仅仅只是对静态数据进行了一些
%%       筛选工作，属于容错与优化的处理。
zip(TaskData) ->
    task_login_mod:zip(TaskData).

unzip(TaskData) ->
    task_login_mod:unzip(TaskData).

%% task -> mini_task
task_to_mini(#task{id = TaskId, target = Target, state = State, count = Count, date = Date, time = Time}) ->
    #mini_task{
               id = TaskId,
               count = Count,
               date = Date,
               state = State,
               target = Target,
               time = Time
              };
task_to_mini(#mini_task{} = MiniTask) -> 
    MiniTask;
task_to_mini(?null) ->
    ?null.

%% mini_task -> task
mini_to_task(#mini_task{id = TaskId, target = Target, state = State, count = Count, date = Date, time = Time}) ->
    Task = read(TaskId),
    Task#task{
               id = TaskId,
               count = Count,
               date = Date,
               state = State,
               target = Target,
               time = Time
              };
mini_to_task(#task{} = Task) ->
    Task;
mini_to_task(?null) ->
    ?null.

%%----------------------------------------------------------------------------------
%% 创建任务
create(TaskId) ->
	task_login_mod:create(TaskId).

%% 登陆时打包
login_packet(Player, Packet) ->
    {?ok, Player2, Packet2} = task_login_mod:login(Player),
    {Player2, <<Packet/binary, Packet2/binary>>}.

%% 0点刷新
refresh(Player) ->
	try
	    {?ok, Player2, Packet} = task_login_mod:login(Player),
	    misc_packet:send(Player#player.net_pid, Packet),
	    {?ok, Player2}
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 退出处理
logout(Player) ->
    Player2 = task_login_mod:logout(Player),
    Player2.

%% 升级
level_up(Player) ->
    task_mod:level_up(Player).

level_up(Player, Lv) ->
    task_mod:level_up(Player, Lv).

get_main_task_id(Player) ->
    Info		= Player#player.info,
    TaskData	= Player#player.task,
    case TaskData#task_data.main of
		#mini_task{id = TaskId} -> TaskId;
		_ -> get_main_task_id(TaskData#task_data.main_idx, Info#info.pro, Info#info.lv)
	end.

get_main_task_id(Idx, Pro, Lv) when 0 < Lv andalso Lv =< ?CONST_SYS_PLAYER_LV_MAX ->
	case get_main_task_id(Idx, Pro) of
		Task = #task{lv_min = LvMin} ->
			if
				LvMin =< ?CONST_SYS_PLAYER_LV_MAX ->
					if
						LvMin =< Lv -> Task#task.id;
						?true -> Task#task.id
%% 						LvMin =< Lv -> Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE};
%% 						?true -> Task#task{state = ?CONST_TASK_STATE_NOT_ACCEPTABLE}
					end;
				?true -> ?null
			end;
		_ -> ?null
	end;
get_main_task_id(_Idx,_Pro, _) -> ?null.

get_main_task_id(Idx, Pro) ->
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

%% 获取日常任务剩余次数
get_task_daily_times(Player) ->
	TaskData   = Player#player.task,
    DailyCycle = TaskData#task_data.daily_cycle,
    ?CONST_TASK_COUNT_DAILY - DailyCycle#task_cycle.times.

%% 获取军团任务剩余次数
get_task_guild_times(Player) ->
	case (Player#player.guild)#guild.guild_id of
		0 -> 0;
		_ ->
			TaskData   = Player#player.task,
			GuildCycle = TaskData#task_data.guild_cycle,
			?CONST_TASK_COUNT_GUILD - GuildCycle#task_cycle.times
	end.

%% 增加可接任务
add_acceptable(Player, Task) ->
    Type     = Task#task.type,
    Module   = task_mod:get_module(Type),
    {Player2, _Packet} = Module:add_task(Player, Task),
    Player2.

%% 接任务
accept(Player, TaskId) ->
    task_mod:accept(Player, TaskId).

%% 隐藏掉军团任务
shadow_guild_task(TaskData) when is_record(TaskData, task_data) ->
    task_guild_mod:shadow_guild_task(TaskData).

%% 显示隐藏掉军团任务
unshadow_guild_task(TaskData) when is_record(TaskData, task_data) ->
    task_guild_mod:unshadow_guild_task(TaskData).

login(Player) ->
    TaskData = Player#player.task,
    DailyCycle = TaskData#task_data.daily_cycle,
    Task = DailyCycle#task_cycle.current,
    NewTask = 
        case Task of
            #mini_task{target = TargetList, id = Id, state = State} ->
                case data_task:get_task(Id) of
                    RecTask when is_record(RecTask, task) ->
                        NewTargetList = task_login_mod:get_real_target(TargetList, RecTask#task.target, [], ?false, TargetList),
                        if
                            NewTargetList =:= TargetList ->
                                Task;
                            ?CONST_TASK_STATE_FINISHED =:= State ->
                                Task;
                            ?true ->
                                Task#mini_task{target = NewTargetList, state = State}
                        end;
                    _ ->
                        Task
                end;
            _ ->
                Task
        end,
    DailyCycle2 = DailyCycle#task_cycle{current = NewTask},
    TaskData2 = TaskData#task_data{daily_cycle = DailyCycle2},
    
    GuildCycle = TaskData2#task_data.guild_cycle,
    GuildTask  = GuildCycle#task_cycle.current,
    NewGuildTask = 
        case GuildTask of
            #mini_task{target = GuildTargetList, id = GId, state = GuildTaskState} ->
                case data_task:get_task(GId) of
                    RecGuildTask when is_record(RecGuildTask, task) ->
                        NewGuildTargetList = task_login_mod:get_real_target(GuildTargetList, RecGuildTask#task.target, [], ?false, GuildTargetList),
                        if
                            NewGuildTargetList =:= GuildTargetList ->
                                GuildTask;
                            ?CONST_TASK_STATE_FINISHED =:= GuildTaskState ->
                                GuildTask;
                            ?true ->
                                GuildTask#mini_task{target = NewGuildTargetList, state = GuildTaskState}
                        end;
                    _ ->
                        GuildTask
                end;
            _ ->
                GuildTask
        end,
    GuildCycle2 = GuildCycle#task_cycle{current = NewGuildTask},
    TaskData3 = TaskData2#task_data{guild_cycle= GuildCycle2},
    Player#player{task = TaskData3}.

%% 完成多人副本
finish_mcopy(Player, CopyId) ->
    Player2 = task_mod:update_note(Player, ?CONST_TASK_NOTE_MCOPY, CopyId),
    {_, Player3} = update_copy(Player2, CopyId, ?CONST_TASK_NOTE_MCOPY),
    Player3.

%% 异民族
finish_invasion(Player, CopyId) ->
    Player2 = task_mod:update_note(Player, ?CONST_TASK_NOTE_INVASION, CopyId),
    {_, Player3} = update_copy(Player2, CopyId, ?CONST_TASK_NOTE_INVASION),
    Player3.

%% 破阵
finish_tower(Player, CampId) ->
    Player2 = task_mod:update_note(Player, ?CONST_TASK_NOTE_TOWER, CampId),
    {_, Player3} = update_copy(Player2, CampId, ?CONST_TASK_NOTE_TOWER),
%%     ?MSG_ERROR("~p", [Player3#player.task#task_data.note]),
    Player3.

%% 精英副本
finish_elite_copy(Player, CopyId) ->
    task_mod:update_note(Player, ?CONST_TASK_NOTE_ELITE_COPY, CopyId).
    
%%-----------------------------------------任务内容更新接口--------------------------------------------------
%% [回调 - update_battle]更新战斗任务数据 -- player_serv
do_update_battle(Player, {MapId, MonsterIdList, BattleParam}) ->
	{?ok, Player2, _Flag, _GoodsList} = task_target_mod:update_battle(Player, MapId, MonsterIdList, BattleParam),
    {?ok, Player2}.

%% [调 - do_update_battle]更新战斗任务数据 -- battle_serv
update_battle(Player, MapId, MonsterIdList, ?CONST_BATTLE_RESULT_LEFT, BattleParam)
  when is_record(Player, player) ->
    {?ok, Player2, _Flag, _GoodsList} = task_target_mod:update_battle(Player, MapId, MonsterIdList, BattleParam),
    {?ok, Player2};
update_battle(UserIds, MapId, MonsterIdList, ?CONST_BATTLE_RESULT_LEFT, BattleParam)
  when is_list(UserIds) ->
	[begin player_api:process_send(UserId, ?MODULE, do_update_battle, {MapId, MonsterIdList, BattleParam}) end|| UserId <- UserIds];
update_battle(_UserIds, _MapId, _MonsterIdList, _, _) -> ?ok.

%% 更新玩家单人副本数据
%% {?ok, Player2}
update_copy(Player, CopyId, 0) ->
    Player2 = copy_single_api:pass_copy(Player, CopyId),
	task_target_mod:update_copy(Player2, CopyId, 0);
update_copy(Player, CopyId, ?CONST_TASK_NOTE_ELITE_COPY) ->
    Player2 = copy_single_api:pass_copy(Player, CopyId),
	task_target_mod:update_copy(Player2, CopyId, ?CONST_TASK_NOTE_ELITE_COPY);
update_copy(Player, CopyId, NoteType) ->
	task_target_mod:update_copy(Player, CopyId, NoteType).

%% 更新采集任务数据
update_gather(Player, MapId, GatherId) ->
    task_target_mod:update_gather(Player, MapId, GatherId).

%% 更新活动任务数据
update_active(Player, {Type, Id}) ->
    task_target_mod:update_active(Player, Type, Id).

%% 升级官衔投放任务
upgrade_position(Player, TaskId, PositionIdNext) ->
	task_position_mod:upgrade_position(Player, TaskId, PositionIdNext).

%% 更新加入军团任务
update_guild(Player) ->
    Player2 = task_target_mod:update_guild(Player),
    Player3 = task_branch_mod:add_sp_guild(Player2),
    Player3.

%% 军团贡献任务
update_donate(Player) ->
    task_target_mod:update_donate(Player).

%% 军团技能任务 
update_guild_skill(Player) ->
    task_target_mod:update_guild_skill(Player).

%% 读取最后一个至少是已接的任务id
get_last_accept_task(Player) ->
    TaskData = Player#player.task,
    TaskMain = TaskData#task_data.main,
    case TaskMain of
        MiniTask when is_record(MiniTask, mini_task) ->
            {MiniTask#mini_task.id, MiniTask#mini_task.state};
        _ ->
            {?null, 0}
    end.

%% 完成引导任务
update_guide(Player, GuideId) ->
    SysId = data_guide:get_sys_id(GuideId),
    task_target_mod:update_guide(Player, SysId).

update_guide_sysid(Player, SysId) ->
    task_target_mod:update_guide_2(Player, SysId).

%% 更新战力任务
update_power(Player, Power) ->
    task_target_mod:update_power(Player, Power).

%% 增加一骑讨次数任务
update_single_arena(Player) ->
    task_target_mod:update_single_arena(Player).

%% 锻造任务
update_furnace(Player, Color) ->
    task_target_mod:update_furnace(Player, Color).

%% 官衔升级任务
update_position(Player, Position) ->
    task_target_mod:update_position(Player, Position).

%% 强化任务
update_furnace_stren(Player, StrLv) ->
    task_target_mod:update_furnace_stren(Player, StrLv).

%% 培养等级任务
update_train(Player, TrainLv) ->
    task_target_mod:update_train(Player, TrainLv).

%% 阵法升级任务
update_camp(Player, CampLv) ->
    task_target_mod:update_camp(Player, CampLv).

%% 每日任务
update_succ_count(Player, ModuleId) ->
	task_target_mod:update_succ_count(Player, ModuleId).

%%-----------------------------协议-------------------------------------------------------
%% 20010 返回任务信息  
msg_task_info(MiniTask) when is_record(MiniTask, mini_task)->
    case task_api:read(MiniTask#mini_task.id) of
        #task{lv_min = LvMin} when LvMin > ?CONST_SYS_PLAYER_LV_MAX ->
            <<>>;
        #task{} ->
			case MiniTask#mini_task.state of
				?CONST_TASK_STATE_ACCEPTABLE ->
					packet_task_info(MiniTask);
				?CONST_TASK_STATE_UNFINISHED ->
					packet_task_info(MiniTask);
				?CONST_TASK_STATE_FINISHED ->
					packet_task_info(MiniTask);
				?CONST_TASK_STATE_NOT_ACCEPTABLE -> % 主线暂不可接
					msg_sc_not_acceptable_main(MiniTask#mini_task.id);
				_ -> <<>> 
        	end;
        _ ->
            <<>>
    end;
msg_task_info(TaskList) when is_list(TaskList) ->
    F = fun(Task, OldPacket) ->
                Packet = msg_task_info(Task),
                <<Packet/binary, OldPacket/binary>>
        end,
    lists:foldl(F, <<>>, TaskList);
msg_task_info(_Task) -> <<>>.

packet_task_info(MiniTask) when is_record(MiniTask, mini_task) ->
    TaskBase    = [
                   MiniTask#mini_task.id,
                   MiniTask#mini_task.state,
                   MiniTask#mini_task.count,
                   MiniTask#mini_task.time
                  ],
    TaskTarget  = [{
                    Target#task_target.idx,
                    Target#task_target.ad1,
                    Target#task_target.ad2,
                    Target#task_target.ad3,
                    Target#task_target.ad4,
                    Target#task_target.ad5
                    } || Target <- MiniTask#mini_task.target],
    Datas       = TaskBase ++ [TaskTarget],
    misc_packet:pack(?MSG_ID_TASK_SC_INFO, ?MSG_FORMAT_TASK_SC_INFO, Datas);
packet_task_info(Task) ->
    ?MSG_ERROR("Task=~p", [Task]),
    <<>>.

%% 20012 未可接主线任务
msg_sc_not_acceptable_main(TaskId) ->
    misc_packet:pack(?MSG_ID_TASK_SC_NOT_ACCEPTABLE_MAIN, ?MSG_FORMAT_TASK_SC_NOT_ACCEPTABLE_MAIN, [TaskId]).

%% 20050 移除任务  
msg_task_remove(TaskId, Reason) ->
    misc_packet:pack(?MSG_ID_TASK_SC_REMOVE, ?MSG_FORMAT_TASK_SC_REMOVE, [TaskId, Reason]).

%% 20060 日常任务次数
msg_sc_daily_count(Count) ->
	misc_packet:pack(?MSG_ID_TASK_SC_DAILY_COUNT, ?MSG_FORMAT_TASK_SC_DAILY_COUNT, [Count]).

%% 20070 军团任务次数
msg_sc_guild_count(Count) ->
	misc_packet:pack(?MSG_ID_TASK_SC_GUILD_COUNT, ?MSG_FORMAT_TASK_SC_GUILD_COUNT, [Count]).