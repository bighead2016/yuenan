%% 任务处理模块
-module(task_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.task.hrl").

%%
%% Exported Functions
%%

-export([accept/2, submit/3, level_up/1, level_up/2, auto_finish/2, abandon/2, update_note/3, check_task_complete/2]).
-export([is_lv_min_max/2, is_fit_time/1, is_acceptable_state/1, is_times_over/1,
         is_in_guild/1, is_fit_rate/2]).
-export([read/1, read_line/1, read_task_main_list/1, read_lv_daily_lib/1, get_main_task/2, read_lv_guild_lib/1, read_lib/1]).
-export([set_task_date_time/1, check_and_set_task_state/3, increase_task_count/1,
         next_task/3, false_throw/3, false_throw/4, get_next_lib_task/1, task_switch_src/0]).
-export([
         reward_gold_bind/3, reward_exp/3, reward_attr_rate/2, reward_experience/3, 
         reward_goods/3, reward_meritorious/3, reward_partner/3, reward_sp/3
        ]).

%%
%% API Functions
%%
%%----------------------------读取数据-------------------------------------------
%% 读取任务静态数据
%% #task{}/null
read(TakdId) ->
    data_task:get_task(TakdId).

%% 读取任务链
read_line(TaskId) ->
    data_task:get_task_line(TaskId).

%% 读取等级主线任务列表
read_task_main_list(Lv) ->
    data_task:get_task_id_list_main(Lv).

read_lib(LibId) ->
    data_task:get_task_lib(LibId).

read_lv_guild_lib(Lv) ->
    data_task:get_lv_guild_lib(Lv).

read_lv_daily_lib(Lv) ->
    data_task:get_lv_daily_lib(Lv).

get_main_task(Pro, Idx) ->
	data_task:get_main_task({Pro, Idx}).

get_next_lib_task(TaskLibId) ->
    TaskIdList = read_lib(TaskLibId),
    misc_random:random_one(TaskIdList#rec_task_lib.tasks).

%%-----------------------------------接任务------------------------------------------------
%% 接任务
accept(Player, TaskId) ->
    % 1
    {Result, MiniTask} = check_acceptable(Player, TaskId),
    % 2
    {_Result2, Player2, Packet} = do_accept(Player, MiniTask, Result),
    UserId = Player2#player.user_id,
    misc_packet:send(UserId, Packet),
    {?ok, Player2}.

%% 任务可接?
check_acceptable(Player, TaskId) ->
	case read(TaskId) of
		Task when is_record(Task, task) ->
			Type   = Task#task.type,
			{Result, MiniTask} = task_switch:check_acceptable_s(Type, Player, TaskId),
            Task3  = 
                case check_task_complete(Player, TaskId, ?CONST_SYS_FALSE) of
                    {?true, _} ->
                        try
                            if
                                Task#task.target =/= [] andalso (Task#task.target)#task_target.target_type =:= ?CONST_TASK_TARGET_POWER ->
									PowerTotal = partner_api:caculate_camp_power(Player),
									TaskTarget = MiniTask#mini_task.target,
									MaxPowerTotal = max(PowerTotal, TaskTarget#task_target.ad1),
									MiniTask#mini_task{state = ?CONST_TASK_STATE_FINISHED,target =TaskTarget#task_target{ad1=MaxPowerTotal}};
								?true ->
									MiniTask#mini_task{state = ?CONST_TASK_STATE_FINISHED}
							end
                        catch
                            X:Y ->
                                ?MSG_ERROR("[~p|~p|~p|~p~n~p]", [TaskId, MiniTask, X, Y, erlang:get_stacktrace()]),
                                MiniTask
                        end;
                    _ ->
                        MiniTask
                end,
            {Result, Task3};
        ?null ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, 0}
    end.

do_accept(Player, MiniTask, ?ok) ->
    Task = task_api:read(MiniTask#mini_task.id),
    Type    = Task#task.type,
    {Player2, MiniTask2, Packet}	= task_switch:do_accept_s(Type, Player, MiniTask),
    {Player3, Packet2}			= do_accept_extra(Player2, MiniTask2, Packet),
    {?ok, Player3, Packet2};
do_accept(Player, _Task, {?error, ErrorCode}) ->
    ErrorPacket = message_api:msg_notice(ErrorCode),
    {?error, Player, ErrorPacket}.

do_accept_extra(Player, MiniTask, TaskPacket) -> 
    % 1
    admin_log_api:log_task(Player, MiniTask#mini_task.id, ?CONST_TASK_POS_ACCEPT),
    % 2
    RecTask = task_api:read(MiniTask#mini_task.id),
    OpenMapId = RecTask#task.open_map_id,
    {Player2, MapPacket} = map_api:open_map(Player, OpenMapId),
    % 4
    CopyId         = RecTask#task.copy_id,
    {Player3, CopyPacket} = copy_single_api:accept_task(Player2, CopyId),
    % 5
    SysId           = RecTask#task.open_sys,
    {?ok, Player4}  = player_sys_api:open_sys(Player3, SysId),
    % 6
    MsgPacket      = message_api:msg_notice(?TIP_TASK_ACCEPT_OK), % 接任务成功
    PacketTotal    = <<TaskPacket/binary, MapPacket/binary, CopyPacket/binary, MsgPacket/binary>>,
    {Player4, PacketTotal}.

%%-----------------------------------提交任务---------------------------------------------
submit(Player, TaskId, IsQuick) ->
    % 1 
    {Result, MiniTask} = check_task_complete(Player, TaskId, IsQuick),
    % 2
    case do_submit(Player, MiniTask, Result, IsQuick) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, ErrorCode} ->
            UserId = Player#player.user_id,
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?ok, Player}
    end.
do_submit(Player, MiniTask, ?true, IsQuick) ->
    UserId      = Player#player.user_id,
    RecTask     = task_api:read(MiniTask#mini_task.id),
    Type        = RecTask#task.type,
    case task_switch:reward_s(Type, Player, RecTask) of
        {?ok, Player2, _GoodsList, PacketBag} ->
            {Player3, Packet} = task_switch:remove_task_s(Type, Player2, MiniTask),
            Info     = Player#player.info,
            Lv       = Info#info.lv,
            Pro      = Info#info.pro,
            TaskList = get_next_task(RecTask, Lv, Pro, []),
            {Player4_2, Packet2}  = next_task(Player3, TaskList, <<>>),
            misc_packet:send(UserId, <<PacketBag/binary, Packet/binary, Packet2/binary>>),
            {Player5, Packet3}  = do_submit_extra(Player4_2, RecTask, IsQuick),
            misc_packet:send(UserId, Packet3),
            {?ok, Player5};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
do_submit(_Player, _Task, ?false, _IsQuick) ->
    {?error, ?TIP_TASK_NOT_FINISH};
do_submit(_Player, _Task, {?error, ErrorCode}, _IsQuick) ->
    {?error, ErrorCode}.

next_task(Player, [Task|Tail], OldPacket) ->
    {Player2, Packet} = task_switch:add_task_s(Task#task.type, Player, Task),
    Packet2 = <<OldPacket/binary, Packet/binary>>,
    next_task(Player2, Tail, Packet2);
next_task(Player, [], Packet) ->
    {Player, Packet}.
    
do_submit_extra(Player, Task, IsQuick) ->
    % 1
    admin_log_api:log_task(Player, Task#task.id, ?CONST_TASK_POS_FINISH),
    % 2    
    SysId			= Task#task.open_sys_2,
    {?ok, Player2}	= player_sys_api:open_sys(Player, SysId),
    % 3
%%     Pullulation		= Task#task.pullulation,
%%     {?ok, Player3, PacketPullulation} = welfare_api:add_pullulation(Player2, Pullulation),
%% 	Player3			= Player2, %% 屏蔽功成名就 
    % 4
    CopySingleId	= Task#task.copy_id,
    Player4			= copy_single_api:flag_copy_single(Player2, CopySingleId),
    % 5
    CopySingleIdAfter = Task#task.copy_id_finished,
    {Player5, PacketCopy} = copy_single_api:insert_new(Player4, CopySingleIdAfter), 
    {Player5_2, PacketCopy_2} = copy_single_newbie_api:handle_b_version(Player5, PacketCopy),
    
    % 6
    PullulationPower= Task#task.pullulation_power,
    {?ok, Player6}	= welfare_api:add_pullulation_power(Player5_2, PullulationPower),
    % 7
	TaskId		   	= Task#task.id,
	{?ok, Player7} 	= welfare_api:add_pullulation(Player6, ?CONST_WELFARE_SINGLE_COPY, TaskId, 1),
	% 8
	{?ok, Player8} 	= submit_task_goods(Player7, Task#task.target, IsQuick),
	% 9
	Player9		   	= mcopy_api:update_mcopy(Player8),
	% 10
	Player10 	   	= invasion_api:update_invasion(Player9),
	% 11
    MsgPacket   	= message_api:msg_notice(?TIP_TASK_FINISHED),
    {Player10, <<PacketCopy_2/binary, MsgPacket/binary>>}.


%%-----------------------------------提交任务物品---------------------------------------------
submit_task_goods(Player, _Target, ?CONST_SYS_TRUE) ->
	{?ok, Player};
submit_task_goods(Player, [#task_target{target_type = ?CONST_TASK_TARGET_CTN_GOODS} = Target|TargetList], ?CONST_SYS_FALSE) ->
	Ctn = case Target#task_target.as1 of
              ?CONST_GOODS_CTN_BAG -> Player#player.bag;
              ?CONST_GOODS_CTN_DEPOT -> Player#player.depot;
              _ -> Player#player.bag
          end,
	GoodsId	= Target#task_target.as2,
    Count = Target#task_target.as3,
	{?ok, Player3} =
	    case ctn_bag2_api:get_by_id(Player#player.user_id, Ctn, GoodsId, Count) of
			{?ok, Container, _GoodsList, PacketGoods} ->
				Player2		= 
					case Target#task_target.as1 of
						?CONST_GOODS_CTN_BAG -> 
							Player#player{bag = Container};
	              		?CONST_GOODS_CTN_DEPOT ->
							Player#player{depot = Container};
						_ ->
							Player
					end,
				misc_packet:send(Player#player.user_id, PacketGoods),
                admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_TASK_SUBMIT_COST, GoodsId, Count, misc:seconds()),
				{?ok, Player2};
			{?error, _ErrorCode} -> {?ok, Player}
		end,
	submit_task_goods(Player3, TargetList, ?CONST_SYS_FALSE);
submit_task_goods(Player, [_Target|TargetList], ?CONST_SYS_FALSE) ->
	submit_task_goods(Player, TargetList, ?CONST_SYS_FALSE);
submit_task_goods(Player, [], ?CONST_SYS_FALSE) ->
	{?ok, Player}.

%%-----------------------------------check---------------------------------------------
%% 等级满足?
%% ?const_sys_true/?const_sys_false
is_lv_min_max(Task, Lv) 
  when    Task#task.lv_min =< Lv 
  andalso Lv               =< Task#task.lv_max 
  ->
    ?ok;
is_lv_min_max(_Task, _Lv) ->
    {?error, ?TIP_COMMON_LEVEL_NOT_ENOUGH}.

%% 任务时间限制检查
%% ?const_sys_true/?const_sys_false
is_fit_time(Task) ->
    TaskTime     = Task#task.time,
    Week         = misc:week(),
    TodaySeconds = calendar:time_to_seconds(misc:time()),
    check_time(TaskTime, Week, TodaySeconds).
check_time({_, 0, 0}, _Week, _TodayTime) -> ?CONST_SYS_TRUE;
check_time({WeekList, StartTime, EndTime}, Week, TodaySeconds) 
  when    StartTime    =< TodaySeconds 
  andalso TodaySeconds =< EndTime ->
    case lists:member(Week, WeekList) of
        ?true  -> ?ok;
        ?false -> {?error, ?TIP_TASK_TIME_IS_OVER}
    end;
check_time(0, _Week, _TodaySeconds) -> ?ok;
check_time(_, _Week, _TodaySeconds) -> ?ok.

%% 任务状态
is_acceptable_state(#mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE}) ->
    ?ok;
is_acceptable_state(_) ->
    {?error, ?TIP_TASK_NOT_ACCEPT}.

%% 检查并修改任务状态
%% #task{}
check_and_set_task_state(_Player, MiniTask = #mini_task{state = ?CONST_TASK_STATE_ACCEPTABLE}, ?CONST_TASK_POS_CONFIRM) -> MiniTask;
check_and_set_task_state(Player, MiniTask, _Pos) when is_record(MiniTask, mini_task) ->
    case check_task_complete(Player, MiniTask#mini_task.target) of
        ?true -> set_task_state(MiniTask, ?CONST_TASK_STATE_FINISHED);
        ?false -> set_task_state(MiniTask, ?CONST_TASK_STATE_UNFINISHED)
    end;
check_and_set_task_state(Player, TaskList, Pos) when is_list(TaskList) ->
	check_and_set_task_state(Player, TaskList, Pos, []);
check_and_set_task_state(_Player, Any, _Pos) -> Any.

check_and_set_task_state(Player, [Task|TaskList], Pos, Acc) ->
	Task2	= check_and_set_task_state(Player, Task, Pos),
	check_and_set_task_state(Player, TaskList, Pos, [Task2|Acc]);
check_and_set_task_state(_Player, [], _Pos, Acc) -> Acc.


%% 任务是否已接
is_accepted(TaskData, TaskId, Type) ->
    task_switch:is_accepted_s(Type, TaskData, TaskId).

check_accepted(TaskData, TaskId) ->
	case read(TaskId) of
        #task{type = Type} ->
            case task_switch:is_accepted_s(Type, TaskData, TaskId) of
                {?CONST_SYS_TRUE, _Task} -> ?true;
                {?CONST_SYS_FALSE, _} -> ?false
            end;
        ?null -> ?false
    end.

%% 次数是否用完
is_times_over(Task) when Task#task.count < Task#task.cycle -> ?ok;
is_times_over(_) -> {?error, ?TIP_TASK_TIMES_OVER}.

%% 军团中?
is_in_guild(0) -> {?error, ?TIP_GUILD_NOT_JION};
is_in_guild(_) -> ?ok.

%% 
is_fit_rate(Task, AttrRate) when Task#task.require_attr_rate =< AttrRate -> ?ok;
is_fit_rate(_, _) -> {?error, ?TIP_COMMON_ATTR_RATE_NOT_ENOUGH}.

%%--------------------------------------检查是否完成任务----------------------------------------------
%% 完成了?
%% {?error, ?TIP_TASK_NOT_ACCEPT}/{?true,  Task}/{?false, Task}
check_task_complete(Player, TaskId, IsQuick) when is_number(TaskId) ->
    case read(TaskId) of
        Task when is_record(Task, task) ->
            TaskData 	= Player#player.task,
            Type		= Task#task.type,
            case is_accepted(TaskData, TaskId, Type) of
                {?CONST_SYS_TRUE, Task2} ->
                    check_task_complete(Player, Task2, IsQuick);
                {?CONST_SYS_FALSE, _} ->
                    {{?error, ?TIP_TASK_NOT_ACCEPT}, ?null}
            end;
        ?null ->
            {{?error, ?TIP_TASK_NOT_EXSIT}, ?null}
    end;
check_task_complete(Player, MiniTask, ?CONST_SYS_FALSE) when is_record(MiniTask, mini_task) ->
    case check_task_complete(Player, MiniTask#mini_task.target) of
        ?true  -> {?true, MiniTask};
        ?false ->  {?false, MiniTask}
    end;
check_task_complete(_Player, MiniTask, ?CONST_SYS_TRUE) ->
    {?true, MiniTask}.

check_task_complete(Player, [Target|TargetList]) ->
    case check_complete(Player, Target) of
        ?true -> check_task_complete(Player, TargetList);
        ?false -> ?false
    end;
check_task_complete(_Player, []) ->
    ?true.

check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_TALK ->% 任务目标--对话类 
    ?true;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_QUESTION ->% 任务目标--问答题 
    ?true;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL ->% 任务目标--击杀怪物 
    (Target#task_target.ad1 >= Target#task_target.as3);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GATHER ->% 任务目标--采集
    Bag		= Player#player.bag,
    Count	= ctn_api:get_count(Bag, Target#task_target.as3),
    (Count >= Target#task_target.as4);
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COLLECT ->% 任务目标--收集类 
    (Target#task_target.target_type =:= ?CONST_TASK_TARGET_COLLECT andalso
     Target#task_target.ad1 >= Target#task_target.as4);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_CTN_GOODS ->% 任务目标--检查容器内物品 
    Ctn = case Target#task_target.as1 of
              ?CONST_GOODS_CTN_BAG -> Player#player.bag;
              ?CONST_GOODS_CTN_DEPOT -> Player#player.depot;
              ?CONST_GOODS_CTN_BAG_TEMP -> Player#player.temp_bag
          end,
    Count = ctn_api:get_count(Ctn, Target#task_target.as2),
    (Count >= Target#task_target.as3);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_LV ->% 任务目标--升级 
    Lv  = (Player#player.info)#info.lv,
    (Lv >= Target#task_target.as1);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SKILL ->% 任务目标--技能 
    SkillData = Player#player.skill,
    SkillList = SkillData#skill_data.skill,
    SkillId   = Target#task_target.as1,
    NewCount  = 
        case lists:keyfind(SkillId, 1, SkillList) of
            {SkillId, Lv, _} -> 
                Lv;
            ?false ->
                0
        end,
    TargetLv = Target#task_target.as2,
    TargetLv =< NewCount;
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COPY ->% 任务目标--副本
    CopyData = Player#player.copy,
    TargetCopyId = Target#task_target.as1,
    NoteType  = Target#task_target.as2,
    IsHistory = Target#task_target.as3,
    case IsHistory of
        ?CONST_SYS_FALSE ->
            check_copy_complete(CopyData, TargetCopyId, Target);
        ?CONST_SYS_TRUE ->
            TaskData = Player#player.task,
            TaskNote = TaskData#task_data.note,
            case TaskNote of
                ?null ->
                    check_copy_complete(CopyData, TargetCopyId, Target);
                _ ->
                    case lists:keyfind(NoteType, #task_note.id, TaskNote) of
                        #task_note{value = NoteList} ->
                            lists:member(TargetCopyId, NoteList);
                        _ ->
                            check_copy_complete(CopyData, TargetCopyId, Target)
                    end
            end
    end;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL_NPC ->% 任务目标--杀npc
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_ACTIVE ->% 任务目标--活动
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD ->% 任务目标--加入军团 
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_DONATE ->% 任务目标--增加军贡
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD_SKILL ->% 任务目标--拥有军团技能
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUIDE ->% 任务目标--引导任务
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POWER ->% 任务目标--达成战力
	PowerTotal = partner_api:caculate_camp_power(Player),
    (Target#task_target.ad1 >= Target#task_target.as1) orelse (PowerTotal >= Target#task_target.as1);
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SINGLE_ARENA ->% 任务目标--一骑讨
    Target#task_target.ad1 >= Target#task_target.as1;
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_FURNACE ->% 任务目标--打造
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POSITION ->% 任务目标--官衔升级
    (Target#task_target.ad1 =:= ?CONST_SYS_TRUE) orelse (player_position_api:current_position(Player) >= Target#task_target.as1);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_STREN ->% 任务目标--装备强化
    (Target#task_target.ad1 =:= ?CONST_SYS_TRUE) orelse (ctn_equip_api:get_max_lv(Player) >= Target#task_target.as1);
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_TRAIN ->% 任务目标--培养
    (Target#task_target.ad1 =:= ?CONST_SYS_TRUE) orelse (partner_api:get_train_max_level(Player) >= Target#task_target.as1);
check_complete(_Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SUCC_N_COUNT ->% 任务目标--胜利n次
    Target#task_target.ad1 >= Target#task_target.as2;
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_CAMP ->% 任务目标--阵法
    (Target#task_target.ad1 =:= ?CONST_SYS_TRUE) orelse (camp_api:get_max_lv(Player) >= Target#task_target.as1).

check_copy_complete(CopyData, TargetCopyId, #task_target{as2 = ?CONST_TASK_NOTE_ELITE_COPY} = Target) ->
    (not copy_single_api:is_first(CopyData, TargetCopyId)) andalso Target#task_target.ad1 =:= ?CONST_SYS_TRUE;
check_copy_complete(_CopyData, _TargetCopyId, Target) ->
    Target#task_target.ad1 =:= ?CONST_SYS_TRUE.

%%-----------------------------------------------------------------------------------
%% 初始化任务日期时间
set_task_date_time(MiniTask) ->
    MiniTask#mini_task{date = misc:date_num(), time = misc:seconds()}.

%% get_task_state(Task) -> Task#task.state.
set_task_state(#mini_task{} = Task, State) -> Task#mini_task{state = State};
set_task_state(#task{} = Task, State)      -> Task#task{state = State}.

%% 递增任务次数
increase_task_count(#mini_task{count = Count} = MiniTask) when Count >= 0 ->
    MiniTask#mini_task{count = Count + 1};
increase_task_count(MiniTask) -> % 任务异常了
    MiniTask#mini_task{count = 0}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 物品奖励
reward_goods(Player, List, IsTemp) ->
    reward_goods(Player, List, [], <<>>, IsTemp).
reward_goods(Player, [{horse, Pro, GoodsId, Bind, SkillId}|List], Acc, AccPacket, IsTemp) ->
    case reward_goods_horse2(Player, Pro, GoodsId, Bind, SkillId, IsTemp) of
        {?ok, Player2, GoodsList, PacketBag} ->
            reward_goods(Player2, List, (GoodsList ++ Acc), <<AccPacket/binary, PacketBag/binary>>, IsTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
reward_goods(Player, [{Pro, Sex, GoodsId, Bind, Count}|List], Acc, AccPacket, IsTemp) ->
    case reward_goods2(Player, Pro, Sex, GoodsId, Bind, Count, IsTemp) of
        {?ok, Player2, GoodsList, PacketBag} ->
            reward_goods(Player2, List, (GoodsList ++ Acc), <<AccPacket/binary, PacketBag/binary>>, IsTemp);
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
reward_goods(Player, [], Acc, AccPacket, _IsTemp) ->
    {?ok, Player, Acc, AccPacket}.

reward_goods_horse2(Player, Pro, GoodsId, Bind, SkillId, IsTemp) ->
    Info   = Player#player.info,
    if
        (Pro =:= ?CONST_SYS_PRO_NULL) orelse
        (Pro =:= Info#info.pro) ->
            reward_goods_horse(Player, GoodsId, Bind, SkillId, IsTemp);
        ?true ->
            {?ok, Player, [], <<>>}
    end.

reward_goods_horse(Player, GoodsId, Bind, SkillId, ?CONST_SYS_FALSE) ->
    case goods_api:make(GoodsId, Bind, 1) of
        [Horse|_] ->
            Ext    = Horse#goods.exts,
            Ext2   = Ext#g_equip{skill_id = SkillId},
            Horse2 = Horse#goods{exts = Ext2},
            GoodsList = [Horse2],
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end;
reward_goods_horse(Player, GoodsId, Bind, SkillId, ?CONST_SYS_TRUE) ->
    case goods_api:make(GoodsId, Bind, 1) of
        [Horse|_] ->
            Ext    = Horse#goods.exts,
            Ext2   = Ext#g_equip{skill_id = SkillId},
            Horse2 = Horse#goods{exts = Ext2},
            GoodsList = [Horse2],
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 1, 0, 0, 1, []) of
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag};
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end.

reward_goods2(Player, Pro, Sex, GoodsId, Bind, Count, IsTemp) ->
    Info   = Player#player.info,
    if
        (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
        (Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)       orelse
        (Pro =:= Info#info.pro       andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
        (Pro =:= Info#info.pro       andalso Sex =:= Info#info.sex) ->
            reward_goods3(Player, GoodsId, Bind, Count, IsTemp);
        ?true ->
            {?ok, Player, [], <<>>}
    end.

reward_goods3(Player, GoodsId, Bind, Count, ?CONST_SYS_TRUE) ->
    case goods_api:make(GoodsId, Bind, Count) of
        GoodsList when is_list(GoodsList) ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 1, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end;
reward_goods3(Player, GoodsId, Bind, Count, ?CONST_SYS_FALSE) ->
    case goods_api:make(GoodsId, Bind, Count) of
        GoodsList when is_list(GoodsList) ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_TASK_REWARD, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, PacketBag} ->
                    {?ok, Player2, GoodsList, PacketBag};
                {?error, ErrorCodeBag} ->
                    {?error, ErrorCodeBag}
            end;
        {?error, ErrorCodeGoods} ->
            {?error, ErrorCodeGoods}
    end.

%% 绑定金币奖励
reward_gold_bind(_UserId, 0, _Point) -> ?ok;
reward_gold_bind(UserId, GoldBind, Point) ->
    case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind, Point) of
        ?ok -> ?ok;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

%% 经验奖励
reward_exp(Player, 0, _Point) -> {?ok, Player};
reward_exp(Player, Exp, _Point) -> player_api:exp(Player, Exp).

%% 历练奖励
reward_experience(Player, 0, _Point) -> {?ok, Player};
reward_experience(Player, Experience, _Point) -> 
    Player2 = player_api:plus_experience(Player, Experience),
    {?ok, Player2}.


%% 体力奖励
reward_sp(Player, 0, _Point) -> {?ok, Player};
reward_sp(Player, Sp, Point)  -> player_api:plus_sp(Player, Sp, Point).

%% 功勋奖励
reward_meritorious(Player, 0, _Point) -> {?ok, Player};
reward_meritorious(Player, Meritorious, Point) -> player_api:plus_meritorious(Player, Meritorious, Point).

%% 武将投放
reward_partner(Player, PartnerList, PartnerLookForList) 
  when is_list(PartnerList) andalso is_list(PartnerLookForList) ->
    Player2 = partner_api:give_partner_list(Player, PartnerList, ?CONST_PARTNER_TEAM_IN),
	Player3	= partner_mod:add_look_new_list(Player2, PartnerLookForList),
    {?ok, Player3};
reward_partner(Player, _, _) -> {?ok, Player}.

%% 奖励角色属性系数
reward_attr_rate(Player, AttrRate) when 0 =/= AttrRate ->
    Info        = Player#player.info,
    if
        AttrRate > Info#info.attr_rate ->
            Info2   = Info#info{attr_rate = AttrRate},
            Player2 = Player#player{info = Info2},
            Player3 = player_attr_api:refresh_attr_lv(Player2),
			PacketRate = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_GROW_RATE, AttrRate),
            misc_packet:send(Player#player.user_id, PacketRate),
            {?ok, Player3};
        ?true -> {?ok, Player}
    end;
reward_attr_rate(Player, _) -> {?ok, Player}.

%%---------------------------------下一个任务-------------------------------------------------
get_next_task(Task, Lv, Pro, List) when is_record(Task, task) ->
    TaskNext	= Task#task.next,
    get_next_task(TaskNext, Lv, Pro, List);
get_next_task(TaskId, Lv, _Pro, List) when is_number(TaskId) ->
    case read(TaskId) of
        TaskNext when is_record(TaskNext, task) andalso TaskNext#task.lv_min =< Lv ->
			State	= next_task_state(TaskNext),
            Task	= set_task_state(TaskNext, State),
            [Task|List];
        TaskNext when is_record(TaskNext, task) andalso TaskNext#task.lv_min > Lv ->
            Task = set_task_state(TaskNext, ?CONST_TASK_STATE_NOT_ACCEPTABLE),
            [Task|List];
        ?null ->
%%             ?MSG_ERROR("!no task:TaskNext=~w", [TaskId]),
            List
    end;
get_next_task({random, TaskLibId}, Lv, Pro, List) ->
    TaskId	= get_next_lib_task(TaskLibId),
    get_next_task(TaskId, Lv, Pro, List);
get_next_task(TaskTuple, Lv, Pro, List) when is_tuple(TaskTuple) ->
    TaskId	= erlang:element(Pro, TaskTuple),
    get_next_task(TaskId, Lv, Pro, List);
get_next_task([TaskId|Tail], Lv, Pro, List) ->
    List2	= get_next_task(TaskId, Lv, Pro, List),
    get_next_task(Tail, Lv, Pro, List2);
get_next_task([], _Lv, _Pro, List) ->
    List.

next_task_state(#task{state = ?CONST_TASK_STATE_HIDE}) 				-> ?CONST_TASK_STATE_ACCEPTABLE;
next_task_state(#task{state = ?CONST_TASK_STATE_ACCEPTABLE}) 		-> ?CONST_TASK_STATE_ACCEPTABLE;
next_task_state(#task{state = ?CONST_TASK_STATE_UNFINISHED}) 		-> ?CONST_TASK_STATE_UNFINISHED;
next_task_state(BadData) -> ?MSG_ERROR("FUCK  BadData:~p", [BadData]), ?CONST_TASK_STATE_ACCEPTABLE.

%%----------------------------------------------------------------------------------
false_throw(Mod, Fun, Arg1) ->
    case Mod:Fun(Arg1) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.
false_throw(Mod, Fun, Arg1, Arg2) ->
    case Mod:Fun(Arg1, Arg2) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 升级处理
level_up(Player) ->
    TaskData 	= Player#player.task,
    Info 		= Player#player.info,
    Lv			= Info#info.lv,
    
    MainTask2 	= task_main_mod:do_level_up(Player),
    
    GuildCycle	= TaskData#task_data.guild_cycle,
    {GuildCycle2, GuildPacket} = 
        case task_mod:read_lv_guild_lib(Lv) of
            ?null ->
                {GuildCycle, <<>>};
            RecLib1 ->
                task_cycle_mod:change_lib(GuildCycle, RecLib1)
        end,
%% 	GuildCycle	= TaskData#task_data.guild_cycle,
%% 	{GuildCycle2, GuildPacket} = {GuildCycle, <<>>},
    
    DailyCycle = TaskData#task_data.daily_cycle,
    {DailyCycle2, DailyPacket} = 
        case task_mod:read_lv_daily_lib(Lv) of
            ?null -> {DailyCycle, <<>>};
            RecLib2 -> task_cycle_mod:change_lib(DailyCycle, RecLib2)
        end,
%%     DailyCycle	= TaskData#task_data.daily_cycle,
%%     {DailyCycle2, DailyPacket} = {DailyCycle, <<>>},
	
    {PositionTask2, PositionPacket} = task_position_mod:do_level_up(Player),
    
    TaskData2	= record_task_data(TaskData, MainTask2, GuildCycle2, DailyCycle2, PositionTask2), 
    UserId		= Player#player.user_id,
    misc_packet:send(UserId, <<GuildPacket/binary, DailyPacket/binary, PositionPacket/binary>>),    
    Player#player{task = TaskData2}.

level_up(Player, Lv) ->
    TaskData	= Player#player.task,
    MainTask2	= task_main_mod:do_level_up(Player),
    
    GuildCycle	= TaskData#task_data.guild_cycle,
    {GuildCycle2, GuildPacket} =
        case task_mod:read_lv_guild_lib(Lv) of
            ?null -> {GuildCycle, <<>>};
            RecLib1 -> task_cycle_mod:change_lib(GuildCycle, RecLib1)
        end,
%% 	GuildCycle	= TaskData#task_data.guild_cycle,
%% 	{GuildCycle2, GuildPacket} = {GuildCycle, <<>>},
	
    DailyCycle	= TaskData#task_data.daily_cycle,
    {DailyCycle2, DailyPacket} =
        case task_mod:read_lv_daily_lib(Lv) of
            ?null -> {DailyCycle, <<>>};
            RecLib2 -> task_cycle_mod:change_lib(DailyCycle, RecLib2)
        end,
%%     DailyCycle	= TaskData#task_data.daily_cycle,
%%     {DailyCycle2, DailyPacket} = {DailyCycle, <<>>},
	
    {PositionTask2, PositionPacket} = task_position_mod:do_level_up(Player),
    
    TaskData2	= record_task_data(TaskData, MainTask2, GuildCycle2, DailyCycle2, PositionTask2), 
    UserId		= Player#player.user_id,
    misc_packet:send(UserId, <<GuildPacket/binary, DailyPacket/binary, PositionPacket/binary>>),  
    Player#player{task = TaskData2}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动完成任务
auto_finish(Player, TaskId) ->
    UserId 			= Player#player.user_id,
    IsOk   			= player_vip_api:can_quick_finish_task(player_api:get_vip_lv(Player)),
    {
	 IsSpEnough, CostSp
	} 				= check_auto_sp(Player, TaskId),
	IsAccepted		= check_accepted(Player#player.task, TaskId),
    IsMoneyEnough 	= 
		case player_money_api:check_money(UserId, ?CONST_SYS_CASH, ?CONST_TASK_CASH_AUTO_FINISH) of
			{?ok, _Money, ?true} -> ?true;
			_ -> ?false
		end,
    if
        ?CONST_SYS_FALSE =:= IsOk -> {?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH};
        ?false =:= IsSpEnough -> {?error, ?TIP_PLAYER_NOT_ENOUGH_SP};
		?false =:= IsAccepted -> {?error, ?TIP_TASK_NOT_ACCEPT};
        ?false =:= IsMoneyEnough -> {?error, ?TIP_COMMON_CASH_NOT_ENOUGH};
        ?true ->
%% 			{IsComplete, _}	= check_task_complete(Player, TaskId, ?CONST_SYS_FALSE),
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_TASK_CASH_AUTO_FINISH, ?CONST_COST_TASK_AUTO_FINISH) of
                ?ok ->
                    case player_api:minus_sp(Player, CostSp, ?CONST_COST_TASK_AUTO_FINISH) of % CostSp 有可能是等于0，然后返回也是正常的
                        {?ok, Player2} -> submit(Player2, TaskId, ?CONST_SYS_TRUE);
                        {?error, ErrorCode} -> {?error, ErrorCode}
                    end;
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

check_auto_sp(Player, TaskId) ->
    case read(TaskId) of
        #task{target = TargetList} ->
			case check_auto_sp2(TargetList, 0) of
				0 -> {?true, 0};
				SpCost ->
					Sp		= (Player#player.info)#info.sp,
					case check_task_complete(Player, TaskId, ?CONST_SYS_FALSE) of
						{?false, _} -> {Sp >= SpCost, SpCost};
						{?true, _} -> {?true, 0};
						{{?error, Tips}, ?null} -> 
							TipPacket = message_api:msg_notice(Tips),
							misc_packet:send(Player#player.user_id, TipPacket),
							{?false, SpCost}
					end
			end;
        _ -> {?true, 0}
    end.

check_auto_sp2([#task_target{target_type = TargetType}|TargetList], AccSp) ->
	Sp		= check_auto_sp(TargetType),
	AccSp2	= if AccSp > 0 -> AccSp; ?true -> Sp end,
	check_auto_sp2(TargetList, AccSp2);
check_auto_sp2([], AccSp) -> AccSp.

check_auto_sp(?CONST_TASK_TARGET_KILL) -> ?CONST_COPY_SINGLE_SP_A_WAVE;% 任务目标--击杀怪物 
check_auto_sp(?CONST_TASK_TARGET_COPY) -> ?CONST_COPY_SINGLE_SP_A_WAVE;% 任务目标--副本 
check_auto_sp(_) -> 0.

%% 放弃任务
abandon(Player, TaskId) ->
	TaskData	= Player#player.task,
	Branch      = TaskData#task_data.branch,
    List        = Branch#branch_task.unfinished,
	Task 		= lists:keyfind(TaskId, #task.id, List),
	case Task#task.abandon of
		?CONST_SYS_TRUE ->
			admin_log_api:log_task(Player, TaskId, ?CONST_TASK_POS_ABANDON),
			List2       = lists:keydelete(TaskId, #task.id, List),
            Branch2     = Branch#branch_task{unfinished = List2},
			TaskData2	= TaskData#task_data{branch = Branch2},
			{?ok, Player#player{task = TaskData2}};
		?CONST_SYS_FALSE ->
			{?ok, Player}
	end.

%%-----------------------行为反记录----------------------------------------------
update_note(Player, Type, Value) ->
    TaskData = Player#player.task,
    NoteList = TaskData#task_data.note,
    NewNoteList = 
        case lists:keytake(Type, #task_note.id, NoteList) of
            {value, #task_note{value = Note} = TaskNote, NoteList2} ->
                Note2 = 
                    case lists:member(Value, Note) of
                        ?true ->
                            Note;
                        ?false ->
                            [Value|Note]
                    end,
                TaskNote2 = TaskNote#task_note{value = Note2},
                [TaskNote2|NoteList2];
            ?false ->
                [#task_note{id = Type, value = [Value]}|NoteList]
        end,
    TaskData2 = TaskData#task_data{note = NewNoteList},
    Player#player{task = TaskData2}.

%%
%% Local Functions
%%
%% 加载任务类型选择器
task_switch_src() ->
    List =   [
              #task_type{type = ?CONST_TASK_TYPE_MAIN,     mod = task_main_mod    },
              #task_type{type = ?CONST_TASK_TYPE_BRANCH,   mod = task_branch_mod  },
              #task_type{type = ?CONST_TASK_TYPE_EVERYDAY, mod = task_daily_mod   },
              #task_type{type = ?CONST_TASK_TYPE_GUILD,    mod = task_guild_mod   },
              #task_type{type = ?CONST_TASK_TYPE_POSITION, mod = task_position_mod},
			  #task_type{type = ?CONST_TASK_TYPE_EVERYDAY1,mod = task_everyday_mod}
             ],
    FList =  [
              #task_func{export    = "do_accept_s/3", 
                         func_s    = "do_accept_s", 
                         func      = "do_accept", 
                         begin_str = "do_accept_s(Type, Player, Task)", 
                         end_str   = "{Player, T, <<>>}"},
              #task_func{export    = "is_accepted_s/3", 
                         func_s    = "is_accepted_s", 
                         func      = "is_accepted", 
                         begin_str = "is_accepted_s(Type, Player, TaskId)", 
                         end_str   = lists:concat(["{", ?CONST_SYS_FALSE, ", null}"])},
              #task_func{export    = "check_acceptable_s/3", 
                         func_s    = "check_acceptable_s", 
                         func      = "check_acceptable", 
                         begin_str = "check_acceptable_s(Type, Player, TaskId)",
                         end_str   = lists:concat(["{{error, ", ?TIP_TASK_NOT_EXSIT, "}, null}"])},
              #task_func{export    = "reward_s/3", 
                         func_s    = "reward_s", 
                         func      = "reward", 
                         begin_str = "reward_s(Type, Player, Task)",
                         end_str   = lists:concat(["{error, ", ?TIP_TASK_NOT_EXSIT, "}"])},
              #task_func{export    = "remove_task_s/3", 
                         func_s    = "remove_task_s", 
                         func      = "remove_task", 
                         begin_str = "remove_task_s(Type, Player, Task)",
                         end_str   = "{Player, <<>>}"},
              #task_func{export    = "add_task_s/3",
                         func_s    = "add_task_s", 
                         func      = "add_task", 
                         begin_str = "add_task_s(Type, Player, Task)",
                         end_str   = "{Player, <<>>}"}
             ],
    ModName 	= "task_switch",
    ExportList	= export_list(FList, ""),
    Head		= lists:append(["% 
     -module(", ModName, "). 
     -export([", ExportList, "]). 
    "]),
    Src 		= link(FList, List, Head),
    {Mod,Code}	= dynamic_compile:from_string(Src),
    code:load_binary(Mod, lists:append([ModName, ".erl"]), Code).

export_list([#task_func{export = Exp}], OldList) ->
    lists:append([OldList, Exp]);
export_list([#task_func{export = Exp}|Tail], OldList) ->
    List = lists:append([OldList, Exp, ", "]),
    export_list(Tail, List);
export_list([], List) ->
    List.

link([TaskFunc|Tail], TypeList, OldList) ->
    BeginStr = lists:append(["% ", TaskFunc#task_func.begin_str, " \n"]),
    FuncS    = TaskFunc#task_func.func_s,
    Func     = TaskFunc#task_func.func,
    List4   = link_inner(TypeList, {FuncS, Func, BeginStr}),        
    List4_2 = lists:append([OldList, List4, TaskFunc#task_func.func_s, "(_, Player, T) -> ", TaskFunc#task_func.end_str, ". \n"]),
    link(Tail, TypeList, List4_2);
link([], _List, List) ->
    List.

link_inner([#task_type{type = Type, mod = Mod}|Tail], {FuncST, FuncT, OldList}) ->
    L  = lists:concat([OldList, FuncST, "(", Type,", Player, T) -> ", Mod,":", FuncT,"(Player, T); \n"]),
    link_inner(Tail, {FuncST, FuncT, L});
link_inner([], {_FuncST, _FuncT, List}) -> 
    List.

record_task_data(TaskData, Main, GuildCycle, DailyCycle, Position) ->
    TaskData#task_data{
                           main          = Main, 
                           guild_cycle   = GuildCycle, 
                           daily_cycle   = DailyCycle, 
                           position_task = Position
                      }.

%% 
%% task_mod_test_() ->
%%     [
%%      ?_assert(accept(#player{}, 10001) == null),
%%      ?_assert(read(1) == null),
%%      ?_assertException(error, function_clause, read(-1)), 
%%      ?_assert(read(alsdkjf) == null)
%%     ].
%%     