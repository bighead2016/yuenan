%% just for gm test
-module(task_gm_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.task.hrl").
-include("record.copy_single.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([get_target_task/2]).

%%
%% API Functions
%%

%% 接目标任务
get_target_task(#mini_task{} = MiniTask, Player) ->
    try
        RecTask = task_api:read(MiniTask#mini_task.id),
        if
            ?CONST_TASK_TYPE_MAIN =:= RecTask#task.type ->
                Player2 = clear_task_data(Player),
                shoot(MiniTask, Player2);
            ?true ->
                Player
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            Player
    end;
get_target_task(TaskId, Player) when is_number(TaskId) ->
    Task = task_api:read(TaskId),
    MiniTask = task_api:task_to_mini(Task),
    get_target_task(MiniTask, Player);
get_target_task(_Task, Player) ->
    Player.

%% 一切都是基于下面几个假设：
%%      1.由于该任务是主线任务，所以从第一个主线任务开始，
%%          在有限次循环后，必然可以遇到目标主作任务
%%      2.任何主线任务条件都必然可以通过某些api得到满足
%%      3.主线任务的生命周期内，影响到的其他系统都是可以通过模拟，达到还原效果
shoot(MiniTask, Player) ->
    TaskData = Player#player.task,
    TaskMain = TaskData#task_data.main,
    shoot(MiniTask, TaskMain, Player).

shoot(MiniTask, TaskMain, Player) when MiniTask#mini_task.id =/= TaskMain#mini_task.id ->
    Player2 = supply_task(Player, TaskMain#mini_task.target, []),
    {?ok, Player3} = task_mod:submit(Player2, TaskMain#mini_task.id, ?CONST_SYS_FALSE),
    IsFull = ctn_bag2_api:is_full(Player3#player.bag),
    if
        ?true =:= IsFull ->
%%             ?MSG_ERROR("used=~p~n~p", [(Player3#player.bag)#ctn.used, Player3#player.bag]),
            Player3;
        ?true ->
%%             ?MSG_ERROR("used=~p~n~p", [(Player3#player.bag)#ctn.used, Player3#player.bag]),
            TaskData = Player3#player.task,
            TaskMain2 = TaskData#task_data.main,
            Player4 = check_lv_min(TaskMain, TaskMain2, Player3),
            {?ok, Player5} = task_api:accept(Player4, TaskMain2#mini_task.id),
            
            % 防死锁
            case check_dead_lock(Player5#player.task, Player3#player.task) of
                ?ok ->
        %%             misc:sleep(?CONST_TIME_SECOND_MSEC),
                    shoot(MiniTask, TaskMain2, Player5);
                ?error -> % 要是遇到这种情况只好进行止损了，待后面再查问题
                    Player3 
            end
    end;
shoot(_Task, _Task2, Player) ->
    Player.

%% ?ok/?error
check_dead_lock(TaskData1, TaskData2) ->
    Task1 = TaskData1#task_data.main,
    Task2 = TaskData2#task_data.main,
    if
        Task1 =:= Task2 -> % 死锁
            ?MSG_ERROR("~p|~p", [Task1#mini_task.id, Task2#mini_task.id]), 
            ?error; 
        ?true ->
            ?ok
    end.

check_lv_min(MiniTaskPre, MiniTask, Player) when is_record(MiniTask, mini_task) ->
    Task = task_api:read(MiniTask#mini_task.id),
    TaskPre = task_api:read(MiniTaskPre#mini_task.id),
    LvMinPre = TaskPre#task.lv_min,
    LvMin = Task#task.lv_min,
    Info = Player#player.info,
    Lv = Info#info.lv,
    if
        Lv < LvMin ->
            gm_mod:set_level(Player, LvMin);
        LvMinPre < LvMin ->
            task_api:level_up(Player, LvMin);
        ?true ->
            Player
    end;
check_lv_min(_TaskPre, _Task, Player) ->
    Player.

%% 清任务包
%% 1.清掉全部任务，包括各种线
clear_task_data(Player) ->
    UserId      = Player#player.user_id,
    CopyData    = copy_single_api:init([]),
    CopyData2	= copy_single_api:init(CopyData),
    CopyBag     = CopyData#copy_data.copy_bag,
    PassedList  = copy_single_api:get_all_passed(CopyBag),
    CopyList    = copy_single_api:flit_shadowed(CopyBag, []),
    SerialBag   = CopyData#copy_data.serial_bag,
    ResetList   = copy_single_api:get_all_reset(SerialBag),
    
    PacketCopy = copy_single_api:msg_sc_copy_all_info(PassedList, CopyList, ResetList),
    PacketTask = remove_all_task(Player#player.task),
    misc_packet:send(UserId, <<PacketCopy/binary, PacketTask/binary>>),
    
    Info       = Player#player.info,
    Pro        = Info#info.pro,
    Sex        = Info#info.sex,
    PlayerInit = data_player:get_player_init({Pro, Sex}),
    TaskData   = task_api:create(PlayerInit#rec_player_init.task),
    MapList    = PlayerInit#rec_player_init.maps,
    Y          = PlayerInit#rec_player_init.x,
    X          = PlayerInit#rec_player_init.y,
    MapId      = PlayerInit#rec_player_init.map,
    MapData    = map_api:create(MapList, MapId, X, Y),
    Sys        = PlayerInit#rec_player_init.sys,
    Guide      = guide_api:init_player_guide(PlayerInit#rec_player_init.guide),
    
    Player#player{copy = CopyData2, task = TaskData, maps = MapData, sys_rank = Sys, guide = Guide}.

remove_all_task(TaskData) ->
    TaskMain   = TaskData#task_data.main,
    PacketMain = task_api:msg_task_remove(TaskMain#mini_task.id, ?CONST_TASK_REMOVE_REASON_ABANDON),
    
    Branch  = TaskData#task_data.branch,
    List    = Branch#branch_task.acceptable,
    List2   = Branch#branch_task.unfinished,
    
    TaskPosition = TaskData#task_data.position_task,
    
    GuildCycle = TaskData#task_data.guild_cycle,
    CurGTask   = GuildCycle#task_cycle.current,
    
    DailyCycle = TaskData#task_data.daily_cycle,
    CurDTask   = DailyCycle#task_cycle.current,
    F = fun(Task, OldPacket) when is_record(Task, mini_task) ->
            Packet = task_api:msg_task_remove(Task#mini_task.id, ?CONST_TASK_REMOVE_REASON_ABANDON),
            <<OldPacket/binary, Packet/binary>>;
           (_, OldPacket) ->
                OldPacket
        end,
    PacketList = lists:foldl(F, <<>>, [List++List2++[TaskPosition]++[CurGTask]++[CurDTask]]),
    
    <<PacketMain/binary, PacketList/binary>>.

%% 补全任务需要
supply_task(Player, [Target|Tail], ResultList) ->
    {Player2, Target2} = check_complete(Player, Target),
    supply_task(Player2, Tail, [Target2|ResultList]);
supply_task(Player, [], ResultList) ->
    TaskData  = Player#player.task,
    TaskMain  = TaskData#task_data.main,
    TaskMain2 = TaskMain#mini_task{target = ResultList},
    TaskData2 = TaskData#task_data{main = TaskMain2},
    Player#player{task = TaskData2}.

check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_TALK ->% 任务目标--对话类 
    {Player, Target};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_QUESTION ->% 任务目标--问答题 
    {Player, Target};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL ->% 任务目标--击杀怪物
    As3 = Target#task_target.as3,
    {Player, Target#task_target{ad1 = As3}};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GATHER ->% 任务目标--采集
    GoodsId = Target#task_target.as3,
    Count = Target#task_target.as4,
    GoodsList = goods_api:make(GoodsId, Count),
    {?ok, Player2, _, _} = ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 1, 1, 1, 1, []), % 有可能会背包满，希望不会有这种问题。。。
    {Player2, Target};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COLLECT ->% 任务目标--收集类
    As4 = Target#task_target.as4,
    {Player, Target#task_target{ad1 = As4}};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_CTN_GOODS ->% 任务目标--检查容器内物品
    UserId = Player#player.user_id,
    case Target#task_target.as1 of
        ?CONST_GOODS_CTN_BAG -> 
              GoodsId = Target#task_target.as2,
              Count = Target#task_target.as3,
              GoodsList = goods_api:make(GoodsId, Count),
              case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 1, 1, 0, 0, 1, 1, []) of
                  {?ok, Player2, _, _} ->
                      {Player2, Target};
                  _ ->
                      {Player, Target}
              end;
         ?CONST_GOODS_CTN_DEPOT -> 
              Depot = Player#player.depot,
              GoodsId = Target#task_target.as2,
              Count = Target#task_target.as3,
              GoodsList = goods_api:make(GoodsId, Count),
              {?ok, Depot2, Packet} = ctn_depot_api:set_stack_list(UserId, Depot, GoodsList),
              misc_packet:send(UserId, Packet),
              {Player#player{depot = Depot2}, Target}
     end;
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_LV ->% 任务目标--升级 
    TargetLv = Target#task_target.as1,
    Info = Player#player.info,
    Lv = Info#info.lv,
    Player2 = 
        if
            Lv >= TargetLv ->
                Player;
            ?true ->
                gm_mod:set_level(Player, TargetLv)
        end,
    {Player2, Target};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SKILL ->% 任务目标--技能 
    {Player, Target}; % 不考虑
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_COPY ->% 任务目标--副本
    % 通关对应副本
    CopyId = Target#task_target.as1,
    Player2 = copy_single_gm_api:quick(Player, CopyId),
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player2, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_KILL_NPC ->% 任务目标--杀npc
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD ->% 任务目标--加入军团 
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_DONATE ->% 任务目标--增加军贡
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUILD_SKILL ->% 任务目标--拥有军团技能
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_GUIDE ->% 任务目标--拥有军团技能
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POWER ->% 任务目标--达成战力
    Target2 = Target#task_target{ad1 = Target#task_target.as1},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_SINGLE_ARENA ->% 任务目标--一骑讨
    Target2 = Target#task_target{ad1 = Target#task_target.as1},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_FURNACE ->% 任务目标--打造紫装
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_POSITION ->% 任务目标--官衔升级
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_STREN ->% 任务目标--装备强化
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_TRAIN ->% 任务目标--培养
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target)
  when Target#task_target.target_type =:= ?CONST_TASK_TARGET_CAMP ->% 任务目标--阵法
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2};
check_complete(Player, Target) ->% 任务目标--杀npc
    Target2 = Target#task_target{ad1 = ?CONST_SYS_TRUE},
    {Player, Target2}.



%%
%% Local Functions
%%

