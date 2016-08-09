
%%% 单人副本接口
-module(copy_single_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").      % 协议
-include("const.tip.hrl").           % 提示语
-include("const.cost.hrl").           

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.map.hrl").
-include("record.battle.hrl").
-include("record.copy_single.hrl").

%%
%% Exported Functions
%%
-export([enter_copy/2, exit_copy/1, again/1, battle_over/2, do_battle_over/2,   % 流程
         flag_copy_single/2, start_battle/5, get_eq/4, refresh/1]).
-export([read/1, copy_info/1, read_award/2, get_vip_reward/1, get_mons/2,
         read_cur_mon_map_id/1, read_cur_copy/1, read_copy_list/1, get_top_elite/1]).                             % 信息
-export([temp_add/2, accept_task/2, is_finish_task/2, is_first/2, reset_serial_times/2, 
         reset_copy_times/2, insert_new/2, add_task_copy/2]).             % 功能函数
-export([login/1, login/2, logout/1, login_packet/2]).      % 人物动作影响
-export([msg_sc_copy_all_info/3, msg_sc_copy_end/10,                                % 封包
         msg_sc_raid_info/3, msg_sc_raid_a_wave/10, msg_sc_empty/1,
         msg_sc_reset_list/1,
         msg_sc_elite_info/4, msg_sc_elite_result/6, msg_sc_equip/1,
         msg_sc_start_elite/2, msg_sc_battle_ok/1, msg_sc_monster_info/2, msg_sc_monster_info/5,
		 msg_sc_auto_turncard/2, msg_sc_auto_turncard_reward/3]).

-export([read_copy/1, init/1, unflag_shadowed/2, unshadowed/3, get_all_passed/1, get_all_reset/1,
         flit_shadowed/2, pass_copy/2, update_copy_data_when_finished/2,
		 get_elite_copy_times/1, get_elite_reset_times/1, 
		 auto_turn_card/3, auto_turn_card_reward/2, update_mon_plot/3,
		 insert_auto_turn_card/2, get_auto_turn_card/2, is_over/1,
         init_copy_data_when_enter/3, update_copy_data/2, update_copy_cur/4, next_map_step/1,
         get_mon_list/2, get_mon_plot_by_wave/4, set_copy_cur/2]).

%%
%% API Functions
%%

init(CopySingle) when is_list(CopySingle) ->
    CopyData	= #copy_data{
							 copy_bag		= copy_bag_api:init(),
							 serial_bag	    = serial_bag_api:init(),
							 copy_cur		= ?null
							},
	init_ext(CopyData, CopySingle);
init(CopyData) when is_record(CopyData, copy_data) ->
	CopyData#copy_data{date = misc:date_num()}.

%% 创角色初始化操作(默认配置中的前三个副本完成状态)
init_ext(CopyData, [CopyId|CopySingleList]) ->
	CopyBag		= CopyData#copy_data.copy_bag,
	SerialBag	= CopyData#copy_data.serial_bag,
	CopyData2	=
		case copy_bag_api:is_exist(CopyId, CopyBag) of
			?false ->
				CopyOne		= init_ext_copy_one(CopyId),
				CopyBag2	= copy_bag_api:push(CopyOne, CopyBag),
				CopyData#copy_data{copy_bag = CopyBag2};
			_ -> CopyData
		end,
	CopyData3	=
		case read_copy(CopyId) of
			#rec_copy_single{serial_id = Sid} ->
				case serial_bag_api:is_exist(Sid, SerialBag) of
					?false ->
						SerialOne	= #serial_one{id = Sid, is_passed = ?CONST_SYS_FALSE, reseted_times = 0},
						SerialBag2	= serial_bag_api:push(SerialOne, SerialBag),
						CopyData2#copy_data{serial_bag = SerialBag2};
					_ -> CopyData2
				end;
			_ -> CopyData2
		end,
	init_ext(CopyData3, CopySingleList);
init_ext(CopyData, []) -> CopyData.

init_ext_copy_one(CopyId) ->
	Flags = #copy_flags{is_passed = ?CONST_SYS_FALSE,
						is_tasked = ?CONST_SYS_FALSE,
						is_shadowed = ?CONST_SYS_FALSE,
						is_2 = ?CONST_SYS_FALSE},
    #copy_one{id = CopyId, daily_times = 1, flags = Flags}.


read_copy(CopyId) ->
    data_copy_single:get_copy_single(CopyId).

%% 登陆时打包
login_packet(Player, Packet) ->
    UserId = Player#player.user_id,
    {?ok, Packet2} = copy_info(Player),
    Packet3 = copy_single_raid_api:get_end_time(UserId),
    Packet4 = copy_single_elite_raid_api:get_end_time(UserId),
    {Player, <<Packet/binary, Packet2/binary, Packet3/binary, Packet4/binary>>}.

flit_shadowed([#copy_one{flags = #copy_flags{is_shadowed = ?CONST_SYS_TRUE}}|Tail], OldCopyList) ->
    flit_shadowed(Tail, OldCopyList);
flit_shadowed([#copy_one{id = CopyId, daily_times = Times}|Tail], OldCopyList) ->
    CopyList = misc:smart_insert_replace(CopyId, {CopyId, Times}, 1, OldCopyList),
    flit_shadowed(Tail, CopyList);
flit_shadowed([], CopyList) ->
    CopyList.

get_all_passed(CopyBag) ->
    [{Id, Is2}||#copy_one{id = Id, flags = #copy_flags{is_passed = ?CONST_SYS_TRUE, is_2 = Is2}} <- CopyBag].

get_all_reset(SerialBag) ->
    [{Id}||#serial_one{id = Id, reseted_times = Times} <- SerialBag, 0 < Times].

%% %% 上线时，统一副本整体情况
copy_info(Player) ->
    CopyData    = Player#player.copy,
    
    CopyBag     = CopyData#copy_data.copy_bag,
    PassedList  = get_all_passed(CopyBag),
    
    CopyList    = flit_shadowed(CopyBag, []),
    
    SerialBag   = CopyData#copy_data.serial_bag,
    ResetList   = get_all_reset(SerialBag),
    Packet      = msg_sc_copy_all_info(PassedList, CopyList, ResetList),
    {?ok, Packet}.

%% 下线
logout(Player) ->
    UserId = Player#player.user_id,
    copy_single_raid_api:change_offline(UserId),
    copy_single_elite_raid_api:change_offline(UserId),
    CopyData  = Player#player.copy,
    Info = Player#player.info,
    if
        0 =:= Info#info.is_newbie ->
            CopyData2 = clear_cur_change_date(CopyData),
            update_copy_data(Player, CopyData2);
        10 =:= Info#info.is_newbie ->
            CopyData2 = clear_cur_change_date(CopyData),
            update_copy_data(Player, CopyData2);
        3 =:= Info#info.is_newbie ->
            Player#player{info = Info#info{is_newbie = 4}};
        ?true ->
            Player
    end.

%% 1.初始化进度数据
%% 2.更新日期
clear_cur_change_date(CopyData) ->
%%     Date = misc:date_num(),
    CopyData#copy_data{ 
%%                        date = Date,
                       copy_cur = #copy_cur{}
                      }.

%% 读取信息
read(CopyId) when is_number(CopyId) ->
    data_copy_single:get_copy_single(CopyId);
read(CopyId) ->
	?MSG_ERROR("read111111111:~p",[CopyId]),
    ?null.
%% 读取当前怪物id
read_cur_mon_map_id(Player) when is_record(Player, player) ->
    CopyData = Player#player.copy,
    read_cur_mon_map_id(CopyData);
read_cur_mon_map_id(CopyData) when is_record(CopyData, copy_data) ->
    CopyCur = CopyData#copy_data.copy_cur,
    {{CopyCur#copy_cur.monster_id, CopyCur#copy_cur.ai_id}, CopyCur#copy_cur.map_id}.

%% 读取当前副本
read_cur_copy(Player) when is_record(Player, player) ->
    CopyData = Player#player.copy,
    CopyData#copy_data.copy_cur.

%% 读取最高的精英副本id - 排行榜要
get_top_elite(Player) ->
    CopyData   = Player#player.copy,
	{CopyData#copy_data.top_id,CopyData#copy_data.top_time}.
%%     CopyBag    = CopyData#copy_data.copy_bag,

%%     get_top_elite(CopyBag, 0).
%% get_top_elite([#copy_one{id = CopyId, flags = #copy_flags{is_passed = ?CONST_SYS_TRUE}}|Tail], MaxCopyId) ->
%%     NewMaxCopyId = 
%%         case read(CopyId) of
%%             Copy when Copy#rec_copy_single.type =:= ?CONST_ELITECOPY_ELITE 
%%                                            andalso MaxCopyId < CopyId ->
%%                 Copy#rec_copy_single.id;
%%             _ ->
%%                 MaxCopyId
%%         end,
%%     get_top_elite(Tail, NewMaxCopyId);
%% get_top_elite([_|Tail], MaxCopyId) ->
%%     get_top_elite(Tail, MaxCopyId);
%% get_top_elite([], MaxCopyId) ->
%%     MaxCopyId.

%%-----------------------------------基本流程-------------------------------------
%% 进入副本
%% 1.检查/玩家状态更新
%% 2.退出之前的地图
%% 3.更新玩家的副本信息
%% 4.剧情判定/并打包怪物信息
%% 5.排行榜信息插入
enter_copy(Player, CopyId) ->
    Info     = Player#player.info,
    CopyData = Player#player.copy,
    case player_state_api:is_doing(Player, ?CONST_PLAYER_PLAY_SINGLE_COPY) of
        ?true ->
            PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_ALREADY_IN),
            {?error, ?TIP_COPY_SINGLE_ALREADY_IN, PacketErr};
        _ ->
            case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_SINGLE_COPY) of
                {?true, Player2} ->
                    case check_enter_copy(Player2, CopyId) of
                        {?ok, RecCopySingle, Player3} ->
                            % 1
                            NewCopyData   = init_copy_data_when_enter(Info, CopyData, RecCopySingle),
                            % 2
                            PlayerExit    = map_api:enter_null_map(Player3),
                            % 3
                            PlayerExit2   = update_copy_data(PlayerExit, NewCopyData),
                            % 4
                            PacketMonster = msg_sc_monster_info(NewCopyData, 0),
                            % 5                           
                            {PlayerExit2, PacketMonster};
%%                         {?error, _} when Player2#player.state =:= ?CONST_SYS_USER_STATE_GM -> % gm身份特殊处理
%%                             RecCopySingle = read(CopyId),
%%                             % 1
%%                             NewCopyData   = init_copy_data_when_enter(Info, CopyData, RecCopySingle),
%%                             % 2
%%                             PlayerExit    = exit_last_map(Player2),
%%                             % 3
%%                             PlayerExit2   = update_copy_data(PlayerExit, NewCopyData),
%%                             % 4
%%                             PacketMonster = msg_sc_monster_info(NewCopyData),
%%                             % 5
%%                             {PlayerExit2, PacketMonster};
                        {?error, ?TIP_COMMON_SP_NOT_ENOUGH = ErrorCode} ->
                            PacketError = player_api:msg_sc_not_enough_sp(),
                            {?error, ErrorCode, PacketError};
                        {?error, ErrorCode} ->
                            PacketErr = message_api:msg_notice(ErrorCode),
                            {?error, ErrorCode, PacketErr}
                    end;
                {?false, Player, Tips} ->
                    PacketErr = message_api:msg_notice(Tips),
                    {?error, ?TIP_PLAYER_PLAY_STATE_CONFLICT, PacketErr}
            end
    end.

%% 进入检测
%% {?ok, RecCopySingle, Player2}/{?error, ErrorCode}
check_enter_copy(Player, CopyId) when is_number(CopyId) ->
    RecCopySingle = read(CopyId), % 在后面检查
    check_enter_copy(Player, RecCopySingle);
check_enter_copy(Player, RecCopySingle) when is_record(RecCopySingle, rec_copy_single) ->
    CopyData = Player#player.copy,
    Info     = Player#player.info,
    Lv       = Info#info.lv,
    Sp       = Info#info.sp,
    #rec_copy_single{
                    id = CopyId,        daily_count = DailyCount, start_time = StartTime,
                    end_time = EndTime, lv_min = LvMin,           prev = Prev, 
                    need_sp = NeedSp,   type = Type
                    } 
        = RecCopySingle,
    try
        ?ok = check_enter_copy_count(CopyId, DailyCount, CopyData),
        ?ok = check_enter_copy_time(StartTime, EndTime),
        ?ok = check_enter_copy_lv(LvMin, Lv),
        ?ok = check_enter_copy_sp(NeedSp, Sp, Type),
        ?ok = check_enter_copy_prev(Prev, CopyData),
        {?ok, RecCopySingle, Player}
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end;
check_enter_copy(_Player, _) ->
    {?error, ?TIP_COPY_SINGLE_NOT_EXIST}.

%% 读取对应怪物列表
get_mon_list(CopyData, RecCopySingle) ->
    CopyId     = RecCopySingle#rec_copy_single.id,
    IsFinished = is_finish_task(CopyData, CopyId),
    get_mons(RecCopySingle, IsFinished).

%% 读取对应的怪物信息 XXX 通关后换怪
%% get_mons(RecCopySingle, _) ->
%%     Mons = {{10001, []}},%RecCopySingle#rec_copy_single.monster2,
%%     PlotTuple = erlang:make_tuple(4, 0),
%%     StandardTime = RecCopySingle#rec_copy_single.standard_time_2,
%%     {Mons, PlotTuple, StandardTime}.
get_mons(RecCopySingle, ?CONST_SYS_FALSE) ->
    case ?CONST_COPY_SINGLE_IS_CLOSE_PLOT of % 剧情开关
        ?CONST_SYS_FALSE ->
            Mons = RecCopySingle#rec_copy_single.monster,
            PlotTuple = RecCopySingle#rec_copy_single.plot,
            StandardTime = RecCopySingle#rec_copy_single.standard_time,
            {Mons, PlotTuple, StandardTime};
        ?CONST_SYS_TRUE ->
            Mons = RecCopySingle#rec_copy_single.monster2,
            PlotTuple = erlang:make_tuple(4, 0),
            StandardTime = RecCopySingle#rec_copy_single.standard_time_2,
            {Mons, PlotTuple, StandardTime}
    end;
get_mons(RecCopySingle, ?CONST_SYS_TRUE) ->
    case ?CONST_COPY_SINGLE_IS_REOPEN_PLOT of % 剧情开关
        ?CONST_SYS_TRUE ->
            Mons = RecCopySingle#rec_copy_single.monster,
            PlotTuple = RecCopySingle#rec_copy_single.plot,
            StandardTime = RecCopySingle#rec_copy_single.standard_time,
            {Mons, PlotTuple, StandardTime};
        ?CONST_SYS_FALSE ->
            Mons = RecCopySingle#rec_copy_single.monster2,
            PlotTuple = erlang:make_tuple(4, 0),
            StandardTime = RecCopySingle#rec_copy_single.standard_time_2,
            {Mons, PlotTuple, StandardTime}
    end.
    
%% 检查副本进入次数
check_enter_copy_count(CopyId, DailyCount, CopyData) ->
    CopyBag = CopyData#copy_data.copy_bag,
    case copy_bag_api:search(CopyId, CopyBag) of
        #copy_one{daily_times = CurTimes} when CurTimes < DailyCount ->
            ?ok;
		CopyOne when is_record(CopyOne, copy_one) ->
			throw({?error, ?TIP_COPY_SINGLE_TIME_IS_OVER});
        _ ->
            throw({?error, ?TIP_COPY_SINGLE_NOT_OPEN})
    end.
            
%% 检查副本进入等级
check_enter_copy_lv(LvMin, Lv) when Lv >= LvMin -> ?ok;
check_enter_copy_lv(_LvMin, _Lv) -> throw({?error, ?TIP_COMMON_LEVEL_NOT_ENOUGH}).
%% 检查副本进入体力
check_enter_copy_sp(NeedSp, Sp, _Type) when Sp >= NeedSp  -> ?ok;
check_enter_copy_sp(_NeedSp, _Sp, ?CONST_ELITECOPY_ELITE) -> ?ok;
check_enter_copy_sp(_NeedSp, _Sp, _Type) -> throw({?error, ?TIP_COMMON_SP_NOT_ENOUGH}).
%% 检查副本进入时间
check_enter_copy_time(0, 0) ->
    ?ok;
check_enter_copy_time(StartTime, EndTime) ->
    Now = misc:seconds(),
    if StartTime =< Now andalso Now =< EndTime -> ?ok;
       ?true -> throw({?error, ?TIP_COMMON_TIME_NOT_FIT})
    end.
%% 检查副本进入前置副本
check_enter_copy_prev(0, _CopyData) ->
    ?ok;
check_enter_copy_prev(Prev, CopyData) ->
    case is_first(CopyData, Prev) of
        ?false -> ?ok;
        ?true -> throw({?error, ?TIP_COPY_SINGLE_PREV_FIRST})
    end.

%% 在进入副本前，初始化副本信息
init_copy_data_when_enter(Info, CopyData, RecCopySingle) ->
    CopyCur      = record_copy_cur(Info, CopyData, RecCopySingle, ?CONST_SYS_FALSE, 
                                   ?CONST_COPY_SINGLE_PROCESS_WAVE_1, 0, 0),
    CopyData#copy_data{copy_cur = CopyCur}.

%% 封装当前副本信息
record_copy_cur(Info, CopyData, RecCopySingle, IsCostSp, MapStep, TotalHurtL, TotalHurtR) ->
    {MonTuple, PlotTuple, StandardTime}       = get_mon_list(CopyData, RecCopySingle),
    {{MonsterId, Ai}, PlotId}   = get_mon_plot_by_wave(Info, MonTuple, PlotTuple, MapStep),
    CopySingleId = RecCopySingle#rec_copy_single.id,
    TimeBegin    = misc:seconds(),
    TotalWaves   = erlang:size(MonTuple),
    Reward       = record_copy_reward(RecCopySingle),
    Type         = RecCopySingle#rec_copy_single.type,
    NeedSp       = RecCopySingle#rec_copy_single.need_sp,
    MapId        = RecCopySingle#rec_copy_single.map,
    SerialId     = RecCopySingle#rec_copy_single.serial_id,
    TimesLimit   = RecCopySingle#rec_copy_single.daily_count,
    #copy_cur{
              copy_id       = CopySingleId,
              begin_time    = TimeBegin,
              is_cost_sp    = IsCostSp, 
              mon_tuple     = MonTuple, 
              map_step      = MapStep,
              map_id        = MapId,
              monster_id    = MonsterId, 
              ai_id         = Ai,
              rewards       = Reward,
              plot_id       = PlotId,
              standard_time = StandardTime, 
              total_hurt_l  = TotalHurtL,
              total_hurt_r  = TotalHurtR, 
              total_waves   = TotalWaves, 
              type          = Type,
              need_sp       = NeedSp,
              serial_id     = SerialId,
              plot_tuple    = PlotTuple,
              times_limit   = TimesLimit
             }.

%% 读取对应波的怪物与剧情id
get_mon_plot_by_wave(Info, MonTuple, PlotTuple, Idx) ->
    try
        {MonId, Ai} = erlang:element(Idx, MonTuple),
        PlotId  = erlang:element(Idx, PlotTuple),
        PlotId2 = get_plot(Info, PlotId),
        {{MonId, Ai}, PlotId2}
    catch
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            {{0, 0}, 0} 
    end.

%% 封装奖励
record_copy_reward(RecCopySingle) ->
    Exp = RecCopySingle#rec_copy_single.exp,
    Gold = RecCopySingle#rec_copy_single.gold,
    GoodsDropId = RecCopySingle#rec_copy_single.award,
    #copy_reward{exp = Exp, gold = Gold, goods_drop_id = GoodsDropId}.

%% 更新玩家的单人副本数据
update_copy_data(Player, CopyData) ->
    Player#player{copy = CopyData}.
%%-----------------------------------退出副本---------------------------------------------

%% 退出副本
%% 1.修改玩家的状态/玩法状态
%% 2.排行榜计算
%% 3.退回至进入前的地图
exit_copy(Player) ->
    UserId   = Player#player.user_id,
    CopyData = Player#player.copy,
    CopyCur  = CopyData#copy_data.copy_cur,
    CopyId   = CopyCur#copy_cur.copy_id,
    if
        0 =:= CopyId ->
            PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_NOT_IN_COPY),
            misc_packet:send(UserId, PacketErr),
            {?ok, Player};
        ?true ->
            case player_state_api:get_state(Player) of
                {?CONST_PLAYER_STATE_NORMAL, _, ?CONST_PLAYER_PLAY_SINGLE_COPY} -> % 要退出的话，只能在副本的正常状态才行
                    NewCopyData = clear_copy_cur(CopyData),
                    Player2     = map_api:return_last_city(Player),
                    Player3     = update_copy_data(Player2, NewCopyData),
                    case player_state_api:try_set_state_play(Player3, ?CONST_PLAYER_PLAY_CITY) of
                        {?true, NewPlayer} ->
                            {?ok, NewPlayer};
                        {?false, _, _} ->
                            {?ok, Player3}
                    end;
                _ ->
                    PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_STATE),
                    misc_packet:send(UserId, PacketErr),
                    {?ok, Player}
            end
    end.

%% 读取默认地图id
get_default_map_id(Pro, Sex) ->
    case data_player:get_player_init({Pro, Sex}) of
        #rec_player_init{map = MapId} ->
            MapId;
        ?null ->
            PlayerInint = data_player:get_player_init({1,1}),
            PlayerInint#rec_player_init.map
    end.

%% 副本结束了?
is_over(CopyCur) when is_record(CopyCur, copy_cur) ->
    NowMapStep   =  CopyCur#copy_cur.map_step,
    TotalMapStep =  CopyCur#copy_cur.total_waves,
    TotalMapStep < NowMapStep;
is_over(CopyData) when is_record(CopyData, copy_data) ->
    CopyCur      =  CopyData#copy_data.copy_cur,
    is_over(CopyCur).

is_over_inner(CopyCur) ->
    IsFinished = is_over(CopyCur),

    if
        ?true =/= IsFinished ->
            throw({?error, ?TIP_COPY_SINGLE_PROCESS_NOT_ARRIVED});
        ?true ->
            ?ok
    end.

%% 清空当前副本信息
clear_copy_cur(CopyData) ->
    CopyCur = #copy_cur{begin_time = 0, copy_id = 0, is_cost_sp = ?CONST_SYS_FALSE,
                        map_step   = ?CONST_COPY_SINGLE_PROCESS_PRE_WAVE_1, 
                        mon_tuple  = ?null, monster_id  = 0, 
                        plot_tuple = ?null, plot_id     = 0,
                        rewards    = ?null, type        = 0,
                        standard_time = 0, total_hurt_l = 0, 
                        total_hurt_r  = 0, total_waves  = 0,
                        need_sp    = 0},
    CopyData#copy_data{copy_cur = CopyCur}.

%% 再次挑战
again(Player) ->
    CopyData = Player#player.copy,
    CopyCur  = CopyData#copy_data.copy_cur,
    CopyId = CopyCur#copy_cur.copy_id,
    if
        0 =:= CopyId ->
            UserId    = Player#player.user_id,
            PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_ALREADY_EXIT),
            misc_packet:send(UserId, PacketErr),
            {?error, ?TIP_COPY_SINGLE_ALREADY_EXIT};
        ?true ->
            case check_enter_copy(Player, CopyId) of
                {?ok, RecCopySingle, Player2} ->
%%                        Date     = misc:date_num(),
                       Info     = Player#player.info,
                       CopyCur2 = record_copy_cur(Info, CopyData, RecCopySingle, 
                                                 ?CONST_SYS_FALSE, ?CONST_COPY_SINGLE_PROCESS_WAVE_1, 0, 0),
                       NewCopyData   = CopyData#copy_data{copy_cur = CopyCur2},
                       NewPlayer     = update_copy_data(Player2, NewCopyData),
                       PacketMonster = msg_sc_monster_info(NewCopyData, 0), % 再次挑战表明必然已经过了一次
                       {?ok, NewPlayer, PacketMonster};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end
    end.

%%-----------------------------数据清除，再次更新--------------------------------------------
%% 角色登录副本重置
login(Player) ->
    CopyData  = Player#player.copy,
    Today     = misc:date_num(),
    if CopyData#copy_data.date =:= Today ->
           login_same_day(Player);
       ?true ->
           login(Player, Today)
    end.
login(Player, Today) ->
    try
        CopyData     = Player#player.copy,
        CopyBag      = CopyData#copy_data.copy_bag,
        NewCopyBag   = repair_copy_bag(CopyBag, CopyBag, ?CONST_SYS_TRUE, []),
        
        SerialBag    = CopyData#copy_data.serial_bag,
        NewSerialBag = clear_reset(SerialBag, []),
        
        CopyData2    = CopyData#copy_data{date = Today, copy_bag = NewCopyBag, serial_bag = NewSerialBag},
        UserId       = Player#player.user_id,
        copy_single_elite_raid_api:change_online(UserId),
        copy_single_raid_api:change_online(UserId),
        update_copy_data(Player, CopyData2)
    catch
        Type:Error ->
            ?MSG_ERROR("~ncopy=[~p]~nError:~p~nReason:~w~nStrace:~p~n", [Player#player.copy, Type, Error, erlang:get_stacktrace()]),
            Player
    end.

clear_reset([#serial_one{reseted_times = 0} = SerialOne|Tail], OldSerialBag) ->
    NewSerialBag = serial_bag_api:push(SerialOne, OldSerialBag),
    clear_reset(Tail, NewSerialBag);
clear_reset([SerialOne|Tail], OldSerialBag) ->
    SerialOne2 = SerialOne#serial_one{reseted_times = 0},
    NewSerialBag = serial_bag_api:push(SerialOne2, OldSerialBag),
    clear_reset(Tail, NewSerialBag);
clear_reset([], SerialBag) ->
    SerialBag.

login_same_day(Player) ->
    CopyData     = Player#player.copy,
    CopyBag      = CopyData#copy_data.copy_bag,
    NewCopyBag   = repair_copy_bag(CopyBag, CopyBag, ?CONST_SYS_FALSE, []),
    
    CopyData2    = CopyData#copy_data{copy_bag = NewCopyBag},
    UserId       = Player#player.user_id,
    copy_single_elite_raid_api:change_online(UserId),
    copy_single_raid_api:change_online(UserId),
    update_copy_data(Player, CopyData2).

%% 0点刷新
refresh(Player) ->
	try
	    Today = misc:date_num(),
		CopyData     = Player#player.copy,
		CopyDate	 = CopyData#copy_data.date,
		if Today =/= CopyDate ->
			   refresh(Player, Today);
		   ?true ->
			   {?ok, Player}
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

refresh(Player, Today) ->
    CopyData     = Player#player.copy,
    CopyBag      = CopyData#copy_data.copy_bag,
    NewCopyBag   = repair_copy_bag(CopyBag, CopyBag, ?CONST_SYS_TRUE, []),
    
    SerialBag    = CopyData#copy_data.serial_bag,
    NewSerialBag = clear_reset(SerialBag, []),
    
    CopyData2    = CopyData#copy_data{date = Today, copy_bag = NewCopyBag, serial_bag = NewSerialBag},
    UserId       = Player#player.user_id,
    copy_single_elite_raid_api:change_online(UserId),
    copy_single_raid_api:change_online(UserId),
    Player2      = update_copy_data(Player, CopyData2),
	msg_sc_notice_elite_reset(Player#player.user_id),
    {?ok, Player2}.

%% 读取该等级的副本列表
read_copy_list(Lv) ->
    case data_copy_single:get_copy_list(Lv) of
        List when is_list(List) ->
            List;
        _ ->
            []
    end.

%% is_prev_ok(_CopyBag, 0)     -> ?true;
%% is_prev_ok(CopyBag, CopyId) -> not is_first(CopyBag, CopyId).

%% is_task_ok(_CopyOne, ?CONST_SYS_FALSE) -> ?true;
%% is_task_ok(CopyOne, ?CONST_SYS_TRUE)   ->
%%     CopyFlags = CopyOne#copy_one.flags,
%%     IsTasked  = CopyFlags#copy_flags.is_tasked,
%%     ?CONST_SYS_TRUE =:= IsTasked.

insert_copy_one(CopyOne, ?CONST_SYS_TRUE, OldCopyBag) ->
    CopyOne2 = CopyOne#copy_one{daily_times = 0},
    copy_bag_api:push(CopyOne2, OldCopyBag);
insert_copy_one(CopyOne, ?CONST_SYS_FALSE, OldCopyBag) ->
    copy_bag_api:push(CopyOne, OldCopyBag).

%% 修复副本背包
repair_copy_bag([CopyOne|Tail], CopyBag, Is0, OldCopyBag) ->
    CopyId = CopyOne#copy_one.id,
    NewCopyBag = 
        case read_copy(CopyId) of
            RecCopySingle when is_record(RecCopySingle, rec_copy_single) ->
%%                     Prev        = RecCopySingle#rec_copy_single.prev,
%%                     IsPrevOk    = is_prev_ok(CopyBag, Prev),
%%                     TaskFlag    = RecCopySingle#rec_copy_single.flag_task,
%%                     IsTaskOk    = is_task_ok(CopyOne, TaskFlag),
%%                     if
%%                         IsPrevOk ->
                            insert_copy_one(CopyOne, Is0, OldCopyBag);
%%                         ?true ->
%%                             OldCopyBag
%%                     end;
            _ ->
                OldCopyBag
        end,
    repair_copy_bag(Tail, CopyBag, Is0, NewCopyBag);
repair_copy_bag([], _, _, CopyBag) -> CopyBag.

%% 接受任务副本刷新
accept_task(Player, 0) -> {Player, <<>>};
accept_task(Player, CopyId) ->
    CopyData    = Player#player.copy,
    CopyBag     = CopyData#copy_data.copy_bag,
    SerialBag   = CopyData#copy_data.serial_bag,
    {CopyBag2, SerialBag2, Packet} = add_new_copy(CopyBag, SerialBag, CopyId),
    CopyData2   = CopyData#copy_data{copy_bag = CopyBag2, serial_bag = SerialBag2},
    Player2     = Player#player{copy = CopyData2},
    {Player2, Packet}.

%% 增加可打副本
add_new_copy(CopyBag, SerialBag, CopyId) ->
    {Cb, P} = 
        case copy_bag_api:is_exist(CopyId, CopyBag) of
            ?false ->
                Packet   = msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE),
                CopyBag2 = copy_bag_api:push(CopyId, CopyBag),
                {CopyBag2, Packet};
            _ ->
                {CopyBag, <<>>}
        end,
    SerialBagT =
		case read_copy(CopyId) of
			#rec_copy_single{serial_id = Sid} ->
				case serial_bag_api:is_exist(Sid, SerialBag) of
					?false ->
						SerialOne = #serial_one{id = Sid, is_passed = ?CONST_SYS_FALSE, reseted_times = 0},
						serial_bag_api:push(SerialOne, SerialBag);
					_ -> SerialBag
				end;
			_ -> SerialBag
		end,
	{Cb, SerialBagT, P}.
    
    
%% 增加已完成副本
flag_passed(CopyId, CopyBag) ->
    case copy_bag_api:search(CopyId, CopyBag) of
        CopyOne when is_record(CopyOne, copy_one) ->
            Flags = CopyOne#copy_one.flags,
            Flags2 = Flags#copy_flags{is_passed = ?CONST_SYS_TRUE},
            CopyOne2 = CopyOne#copy_one{flags = Flags2},
            copy_bag_api:push(CopyOne2, CopyBag);
        _ ->
            CopyBag
    end.
    
%% 增加任务副本
add_task_copy(TaskCopy, CopySingleId) ->
    case lists:member(CopySingleId, TaskCopy) of
        ?true ->
            TaskCopy;
        ?false ->
            [CopySingleId|TaskCopy]
    end.

%% 扣体力
cost_sp(Player) ->
    CopyData = Player#player.copy,
    CopyCur  = CopyData#copy_data.copy_cur,
    CopyId   = CopyCur#copy_cur.copy_id,
    Type     = CopyCur#copy_cur.type,
    IsCostSp = CopyCur#copy_cur.is_cost_sp,
    if
        ?CONST_SYS_FALSE =:= IsCostSp andalso ?CONST_ELITECOPY_ELITE =/= Type ->
            % 扣体力
            NeedSp = CopyCur#copy_cur.need_sp, 
            PlayerMinusSp = 
                case player_api:minus_sp(Player, NeedSp, ?CONST_COST_COPY_SP) of
                    {?ok, Player2} -> Player2;
                    {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
                        UserId = Player#player.user_id,
                        PacketError = player_api:msg_sc_not_enough_sp(),
                        misc_packet:send(UserId, PacketError),
                        Player;
                    {?error, ErrorCode} ->
                        UserId = Player#player.user_id,
                        PacketErr = message_api:msg_notice(ErrorCode),
                        misc_packet:send(UserId, PacketErr),
                        Player
                end,
            PlayerMinusSp2 = update_cost_sp(PlayerMinusSp, ?CONST_SYS_TRUE),
            {CopyId, PlayerMinusSp2};
        ?true ->
            {CopyId, Player}
    end.

%% 更新体力状态
update_cost_sp(Player, IsCostSp) ->
    CopyData  = Player#player.copy,
    CopyCur   = CopyData#copy_data.copy_cur,
    CopyCur2  = CopyCur#copy_cur{is_cost_sp = IsCostSp},
    CopyData2 = CopyData#copy_data{copy_cur = CopyCur2},
    Player#player{copy = CopyData2}.

next_map_step(?CONST_COPY_SINGLE_PROCESS_PRE_WAVE_1) -> ?CONST_COPY_SINGLE_PROCESS_WAVE_1;
next_map_step(?CONST_COPY_SINGLE_PROCESS_WAVE_1)     -> ?CONST_COPY_SINGLE_PROCESS_WAVE_2;
next_map_step(?CONST_COPY_SINGLE_PROCESS_WAVE_2)     -> ?CONST_COPY_SINGLE_PROCESS_WAVE_3;
next_map_step(?CONST_COPY_SINGLE_PROCESS_WAVE_3)     -> ?CONST_COPY_SINGLE_PROCESS_AFTER_WAVE_3.

%%--------------------------------战斗------------------------------------
%% 开始战斗
%% {?ok, Player2}/{?error, PacketTip}
start_battle(Player, MonsterId, HelpPartner, Idx, Anger) ->
	case copy_single_api:read_cur_mon_map_id(Player) of
		{{CopyMonsterId, Ai}, MapId} when 0 =/= CopyMonsterId andalso CopyMonsterId =:= MonsterId ->
			CopyCur 		= read_cur_copy(Player),
			CopyType		= CopyCur#copy_cur.type,
			AiPartner		= case HelpPartner of
								  0 ->
									  [];
								  _ ->
									 [{HelpPartner, Idx}]
							  end,
			BattleParam  	= #param{battle_type = ?CONST_BATTLE_SINGLE_COPY, 
									 map_id = MapId, 
                                     ai_list = Ai, 
									 ai_partner = AiPartner,
									 init_anger = Anger,
									 ad1 = CopyCur#copy_cur.copy_id, 
									 ad2 = CopyType},
			case battle_api:start(Player, MonsterId, BattleParam) of
				{?ok, Player2} -> 
					case CopyType =:= ?CONST_ELITECOPY_GENERAL of      %% 普通副本
						?true ->	{?ok, Player2};
						?false ->	{?ok, Player2}
					end;
				{?error, _ErrorCode} ->
					PacketErr = <<>>, % message_api:msg_notice(ErrorCode),
					{?error, PacketErr}
			end;
		{{0, _}, _} ->
            PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_NOT_IN_COPY),
            {?error, PacketErr};
        X ->
            PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_NOT_CUR_MON),
            ?MSG_ERROR("x=~p", [{X, MonsterId}]),
            {?error, PacketErr}
    end.

%% 战斗结束
battle_over(Result, {UserId, HurtL, HurtR, Report, CopyId, CopyType}) ->
    case player_api:get_player_pid(UserId) of
        Pid when is_pid(Pid) ->
            player_api:process_send(Pid, copy_single_api, do_battle_over, {Result, HurtL, HurtR, CopyId, CopyType, Report});
        _ ->
            ?ok
    end.

do_battle_over(#player{info = #info{is_newbie = NewBieFlag} = Info} = Player, 
               {?CONST_BATTLE_RESULT_LEFT, HurtL, HurtR, CopyId, CopyType, Report}) when NewBieFlag =:= 0 orelse NewBieFlag =:= 10 -> % 赢了
    {TopEliteCopyId, _} = get_top_elite(Player),
    if
        TopEliteCopyId < CopyId andalso 2 =:= CopyType -> % 赢了
            copy_single_report_api:insert_report(Player#player.user_id, Info, CopyId, Report);
        ?true ->
            ?ok
    end,
    
    UserId   = Player#player.user_id,
    Info     = Player#player.info,
    {CopyId, Player2} = cost_sp(Player),
    CopyData = Player2#player.copy,
    
    CopyCur      = CopyData#copy_data.copy_cur,
    MapStep      = CopyCur#copy_cur.map_step,
    MapStep2     = next_map_step(MapStep),
    CopyCur2     = CopyCur#copy_cur{map_step = MapStep2},
    CopyData2    = CopyData#copy_data{copy_cur = CopyCur2},
    Type         = CopyCur2#copy_cur.type,
    TimeBegin    = CopyCur2#copy_cur.begin_time,
    TimeStandard = CopyCur2#copy_cur.standard_time,
    
    {Packet, NewPlayer} = 
        case is_over(CopyCur2) of
            ?false ->
                {CopyData3, PacketMonster} = update_copy_cur(Info, CopyData2, HurtL, HurtR),
                Player3 = update_copy_data(Player2, CopyData3),
                {PacketMonster, Player3};
            ?true -> % 副本结束
                TimeNow = misc:seconds(),

                {AwardGoodsList, AwardExp1, AwardGold, PlotId} = read_award(Info, CopyCur2),

                Lv   = Info#info.lv,

                AwardExp = 
                if Lv >= 40 ->
                        trunc(AwardExp1*1.5);
                    true ->
                        AwardExp1
                end,

                Player3 = reward_exp(Player2, AwardExp), % 包括军团增幅

                player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, AwardGold, ?CONST_COST_COPY_BATTLE_OVER),
                
                CopyBag = CopyData2#copy_data.copy_bag,
                {IsFirst, Player5, CopyData4} = 
                    case is_first(CopyBag, CopyId) of
                        ?false ->
                            CopyData2_1 = Player3#player.copy, 
                            {?CONST_SYS_FALSE, Player3, CopyData2_1};
                        ?true ->
                            bless_api:send_be_blessed(Player3, ?CONST_RELATIONSHIP_BLESS_TYPE_SINGLE_COPY, CopyId),
                            CopyBag2	= flag_passed(CopyId, CopyBag),	
                            CopyData_2	= if Type =:= 2 andalso CopyId > CopyData2#copy_data.top_id -> 
												  CopyData2#copy_data{copy_bag = CopyBag2,top_id = CopyId, top_time = TimeNow};
											  ?true -> CopyData2#copy_data{copy_bag = CopyBag2}
                    					  end,
                            CopyData2_1 = unshadowed(UserId, CopyData_2, CopyId),
                            Player4		= update_copy_data(Player3, CopyData2_1),
                            {?CONST_SYS_TRUE, Player4, CopyData2_1}
                    end,
%%                 {CopyData4, Times} = temp_add(CopyData3, CopyId),
                
                {Player6, PacketBag} = 
                    case ctn_bag_api:put(Player5, AwardGoodsList, ?CONST_COST_COPY_BATTLE_OVER, 1, 1, 1, 0, 0, 1, [CopyId]) of
                        {?ok, Player5_2, _, PacketBagChanged} ->
                            {Player5_2, PacketBagChanged};
                        {?error, _ErrorCode} ->
                            {Player5, <<>>}
                    end,
                
                % 副本经过的时间
                TimePass     = TimeNow - TimeBegin,
                % 获取评价
                Eq           = get_eq(TimePass, TimeStandard, HurtL, HurtR),
                
                AwardExp2 = calc_x(Player2, AwardExp), % 补算，其实上面已经加了
                PacketEnd    = msg_sc_copy_end(CopyId, IsFirst, AwardGoodsList, Eq, AwardExp2, AwardGold, PlotId, HurtL, HurtR, TimePass),
%%                 PacketUpdate = 
%%                     if
%%                         Times < CopyCur2#copy_cur.times_limit ->
%%                             msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE);
%%                         ?true andalso ?CONST_SYS_USER_STATE_GM =:= Player6#player.state ->
%%                             msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE);
%%                         ?true ->
%%                             msg_sc_update_copy(CopyId, ?CONST_SYS_FALSE)
%%                     end,
                NewCopyData  = update_copy_data_when_finished(CopyData4, MapStep2), 
                
                {?ok, Player9, NewCopyData3} = 
                    case is_finished_serial(NewCopyData, CopyCur2) of
                        {?CONST_SYS_TRUE, SNo, SerialId} ->
                            NewCopyData2   = add_finish_serial(NewCopyData, SerialId),
                            {?ok, Player7} = achievement_api:add_achievement(Player6, ?CONST_ACHIEVEMENT_COPY_CLEARANCE, SNo, 1),
                            {?ok, Player7, NewCopyData2};
                        _ ->
                            {?ok, Player6, NewCopyData}
                    end,
                
                {?ok, Player10}    = 
                    case Type of
                        1 ->
                            schedule_api:add_guide_times(Player9, ?CONST_SCHEDULE_GUIDE_SINGLE_COPY);
                        2 ->
                            catch gun_award_api:check_active(UserId, ?CONST_SCHEDULE_RESOURCE_HERO),
                            schedule_api:add_guide_times(Player9, ?CONST_SCHEDULE_GUIDE_ELITE_COPY)
                            
                    end,
                Player11 = update_copy_data(Player10, NewCopyData3),
                {?ok, Player12} = task_api:update_copy(Player11, CopyId, 0),
                {?ok, Player13} = welfare_api:add_pullulation(Player12, ?CONST_WELFARE_ELITE_COPY, CopyId, 1),
                Player14 = 
                    case data_copy_single:get_copy_single(CopyId) of
                        #rec_copy_single{type = 2} ->
                            task_api:finish_elite_copy(Player13, CopyId);
                        _ ->
                            resource_api:finish_single_copy(UserId, Info#info.user_name, Info#info.lv),
                            Player13
                    end,
                {<<PacketEnd/binary, PacketBag/binary>>, Player14}
        end,
    misc_packet:send(UserId, Packet),
    {?ok, NewPlayer};
do_battle_over(Player, {?CONST_BATTLE_RESULT_LEFT, _HurtL, _HurtR, _, _, _}) -> % 赢了
    CopyData     = Player#player.copy,
    CopyCur      = CopyData#copy_data.copy_cur,
    CopyId       = CopyCur#copy_cur.copy_id,
    NowMapStep   =  CopyCur#copy_cur.map_step,
    TotalMapStep =  CopyCur#copy_cur.total_waves,
    if
        TotalMapStep - 1 < NowMapStep ->
            {_, _, _, PlotId} = copy_single_api:read_award(Player#player.info, CopyCur),
            PacketEnd    = copy_single_api:msg_sc_copy_end(CopyId, 1, [], 1, 0, 0, PlotId, 0, 0, 0),
            misc_packet:send(Player#player.user_id, PacketEnd);
        ?true ->
            ok
    end,    
    {?ok, Player};
do_battle_over(Player, {?CONST_BATTLE_RESULT_RIGHT, _HurtL, _HurtR, _, _, _}) -> % 输了
    {_CopyId, Player2} = cost_sp(Player),
    {?ok, Player2};
do_battle_over(Player, {?CONST_BATTLE_RESULT_DRAW, _HurtL, _HurtR, _, _, _}) -> % 平了
    {_CopyId, Player2} = cost_sp(Player),
    {?ok, Player2}.

calc_x(Player, Exp) ->
    Rate = guild_api:get_exp_add(Player),
    Info = Player#player.info,
    Lv   = Info#info.lv,
    RankRate = rank_api:get_rank_rate(Lv),
    round(Exp * Rate + Exp * RankRate).

%%--------------------------------------屏蔽不发给前端的东西----------------------------------------------
unshadowed(UserId, CopyData, CopyId) ->
    CopyBag   = CopyData#copy_data.copy_bag,
    SerialBag = CopyData#copy_data.serial_bag,
    case read(CopyId) of
        #rec_copy_single{next = Next, serial_id = Sid} ->
            SerialOne = #serial_one{id = Sid, is_passed = ?CONST_SYS_FALSE, reseted_times = 0},
            SerialBag2 = serial_bag_api:push(SerialOne, SerialBag),
            {CopyBag2, Packet} = unflag_shadowed(Next, CopyBag),
            misc_packet:send(UserId, Packet),
            CopyData#copy_data{copy_bag = CopyBag2, serial_bag = SerialBag2};
        _ -> 
            CopyData
    end.

unflag_shadowed(CopyId, CopyBag) ->
    case copy_bag_api:pull(CopyId, CopyBag) of
        {?null, _} ->
            {CopyBag, <<>>};
        {CopyOne, CopyBag2} ->
            CopyFlags  = CopyOne#copy_one.flags,
            if
                ?CONST_SYS_TRUE =:= CopyFlags#copy_flags.is_shadowed ->
                    Packet     = msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE),
                    CopyFlags2 = CopyFlags#copy_flags{is_shadowed = ?CONST_SYS_FALSE},
                    CopyOne2   = CopyOne#copy_one{flags = CopyFlags2},
                    CopyBag3   = copy_bag_api:push(CopyOne2, CopyBag2),
                    {CopyBag3, Packet};
                ?true ->
                    CopyFlags2 = CopyFlags#copy_flags{is_shadowed = ?CONST_SYS_FALSE},
                    CopyOne2   = CopyOne#copy_one{flags = CopyFlags2},
                    CopyBag3   = copy_bag_api:push(CopyOne2, CopyBag2),
                    {CopyBag3, <<>>}
            end
    end.

%% 更新当前副本信息
update_copy_cur(Info, CopyData, HurtL, HurtR) ->
    CopyCur   = CopyData#copy_data.copy_cur,
    MonTuple  = CopyCur#copy_cur.mon_tuple,
    PlotTuple = CopyCur#copy_cur.plot_tuple,
    MapStep   = CopyCur#copy_cur.map_step,
    CopyId    = CopyCur#copy_cur.copy_id,
    {{MonsterId, Ai}, PlotId} = get_mon_plot_by_wave(Info, MonTuple, PlotTuple, MapStep),
    CopyCur2  = update_mon_plot(CopyCur, MonsterId, PlotId),
    PacketMonster       = msg_sc_monster_info(CopyId, MonsterId, MapStep, PlotId, 0),
    TotalHurtL = CopyCur2#copy_cur.total_hurt_l,
    TotalHurtR = CopyCur2#copy_cur.total_hurt_r,
    CopyCur3   = CopyCur2#copy_cur{
                                     total_hurt_l = TotalHurtL + HurtL,
                                     total_hurt_r = TotalHurtR + HurtR,
                                     monster_id   = MonsterId,
                                     ai_id        = Ai
                                  },
    CopyData2  = set_copy_cur(CopyData, CopyCur3),
    {CopyData2, PacketMonster}.

set_copy_cur(CopyData, CopyCur) ->
    CopyData#copy_data{copy_cur = CopyCur}.
get_copy_cur(CopyData) ->
    CopyData#copy_data.copy_cur.

%% 副本完成时更新副本信息
update_copy_data_when_finished(CopyData, MapStep) ->
    CopyCur  = get_copy_cur(CopyData),
    CopyCur2 = CopyCur#copy_cur{map_step = MapStep, monster_id = 0},
    CopyData#copy_data{copy_cur = CopyCur2}.

%% 奖励经验
reward_exp(Player, Exp) ->
    Rate = guild_api:get_exp_add(Player),
    Info = Player#player.info,
    Lv   = Info#info.lv,
    RankRate = rank_api:get_rank_rate(Lv),
    Exp2 = round(Exp * Rate + Exp * RankRate), 
    {?ok, Player2} = player_api:exp(Player, Exp2),
    Player2.

%% 更新当前副本的剧情id
update_mon_plot(CopyCur, MonsterId, PlotId) ->
    CopyCur#copy_cur{monster_id = MonsterId, plot_id = PlotId}.

%% 增加完成系列id列表
add_finish_serial(CopyData, SerialId) ->
    SerialBag = CopyData#copy_data.serial_bag,
    case serial_bag_api:search(SerialId, SerialBag) of
        ?false ->
            SerialOne  = #serial_one{id = SerialId, is_passed = ?CONST_SYS_TRUE, reseted_times = 0},
            SerialBag2 = serial_bag_api:push(SerialOne, SerialBag),
            CopyData#copy_data{serial_bag = SerialBag2};
        _ ->
            CopyData
    end.

%% 读取整个系列列表
read_serial_list(SerialId) ->
    case data_copy_single:get_serial_list(SerialId) of
        ?null ->
            [];
        List ->
            List
    end.

%% 完成了整个系列?
is_finished_serial(CopyData, CopyCur) when is_record(CopyCur, copy_cur) ->
    SerialId   = CopyCur#copy_cur.serial_id,
    Serial     = read_serial_list(SerialId),
    CopyBag    = CopyData#copy_data.copy_bag,
    IsFinished = is_finished_serial(CopyBag, Serial),
    {IsFinished, SerialId, SerialId};
is_finished_serial(CopyData, CopyId) when is_number(CopyId) ->
    RecCopySingle = read(CopyId),
    SerialId      = RecCopySingle#rec_copy_single.serial_id,
    Serial        = read_serial_list(SerialId),
    CopyBag       = CopyData#copy_data.copy_bag, 
    IsFinished    = is_finished_serial(CopyBag, Serial),
    {IsFinished, SerialId, SerialId};
is_finished_serial(CopyBag, [CopyId|Tail]) ->
    case is_first(CopyBag, CopyId) of
        ?false ->
            is_finished_serial(CopyBag, Tail);
        ?true ->
            ?CONST_SYS_FALSE
    end;
is_finished_serial(_, []) ->
    ?CONST_SYS_TRUE;
is_finished_serial(_, _) -> % 异常了
    ?CONST_SYS_FALSE.

%% 第1次完成?
is_first(CopyData, CopyId) when is_record(CopyData, copy_data) ->
    CopyBag = CopyData#copy_data.copy_bag,
    is_first(CopyBag, CopyId);
is_first(CopyBag, CopyId) ->
    case copy_bag_api:search(CopyId, CopyBag) of
        #copy_one{flags = #copy_flags{is_passed = ?CONST_SYS_TRUE}} -> ?false;
        _ -> ?true
    end.

%% 完成了任务?
is_finish_task(CopyData, CopyId) when is_record(CopyData, copy_data) ->
    CopyBag = CopyData#copy_data.copy_bag,
    is_finish_task(CopyBag, CopyId);
is_finish_task(CopyBag, CopyId) ->
    case copy_bag_api:search(CopyId, CopyBag) of
        #copy_one{flags = #copy_flags{is_tasked = IsTasked}} = CopyOne ->
            IsTasked;
        _ ->
            ?CONST_SYS_FALSE
    end.

%% temp对应的副本记录加1
temp_add(CopyData, CopyId) ->
    CopyBag = CopyData#copy_data.copy_bag,
    case copy_bag_api:pull(CopyId, CopyBag) of
        {?null, _} ->
            CopyFlags = copy_bag_api:record_copy_flags(?CONST_SYS_TRUE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
            CopyOne   = #copy_one{id = CopyId, daily_times = 1, flags = CopyFlags},
            CopyBag2  = copy_bag_api:push(CopyOne, CopyBag),
            CopyData2 = CopyData#copy_data{copy_bag = CopyBag2},
            {CopyData2, 1};
        {CopyOne, CopyBag2} ->
            Times     = CopyOne#copy_one.daily_times,
            NewTimes  = Times + 1,
            CopyOne2  = CopyOne#copy_one{daily_times = NewTimes},
            CopyBag3  = copy_bag_api:push(CopyOne2, CopyBag2),
            CopyData2 = CopyData#copy_data{copy_bag = CopyBag3},
            {CopyData2, NewTimes}
    end.

%% 将任务位置1
flag_copy_single(Player, 0) -> Player;
flag_copy_single(Player, CopyId) ->
    UserId   = Player#player.user_id,
    CopyData = Player#player.copy,
    CopyBag  = CopyData#copy_data.copy_bag,
    NewCopyBag = 
        case copy_bag_api:search(CopyId, CopyBag) of
            #copy_one{flags = #copy_flags{is_tasked = ?CONST_SYS_TRUE}} ->
                CopyBag;
            #copy_one{flags = #copy_flags{is_tasked = ?CONST_SYS_FALSE}} = CopyOne ->
                CopyFlags  = CopyOne#copy_one.flags,
                CopyFlags2 = CopyFlags#copy_flags{is_tasked = ?CONST_SYS_TRUE, is_2 = ?CONST_SYS_TRUE},
                CopyOne2   = CopyOne#copy_one{flags = CopyFlags2},
                Packet     = msg_sc_proccess_update(CopyId, ?CONST_SYS_TRUE),
                misc_packet:send(UserId, Packet),
                copy_bag_api:push(CopyOne2, CopyBag);
            ?false ->
                CopyBag
        end,
    CopyData2 = CopyData#copy_data{copy_bag = NewCopyBag},
    Player#player{copy = CopyData2}.

reset_serial_times([CopyId|Tail], OldCopyData, OldIsReseted, OldPacket) ->
    {CopyData3, IsReseted2, Packets} = 
        case is_first(OldCopyData, CopyId) of
            ?true ->
                {OldCopyData, OldIsReseted, <<>>};
            ?false ->
                case reset_copy_times(OldCopyData, CopyId) of
                    {CopyData2, ?CONST_SYS_TRUE} ->
                        PacketCopyList = msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE),
                        {CopyData2, ?CONST_SYS_TRUE, PacketCopyList};
                    {CopyData2, ?CONST_SYS_FALSE} ->
                        {CopyData2, OldIsReseted, <<>>}
                end
        end,
    reset_serial_times(Tail, CopyData3, IsReseted2, <<OldPacket/binary, Packets/binary>>);
reset_serial_times([], OldCopyData, OldIsReseted, OldPacket) ->
    {OldCopyData, OldIsReseted, OldPacket}.

update_reset_list(SerialBag, SerialId) ->
    case serial_bag_api:search(SerialId, SerialBag) of
        #serial_one{reseted_times = Times} = SerialOne ->
            SerialOne2 = SerialOne#serial_one{reseted_times = Times + 1},
            serial_bag_api:push(SerialOne2, SerialBag);
        ?false ->
            SerialBag
    end.

reset_serial_times(Player, SerialId) ->
    UserId = Player#player.user_id,
    CopyData = Player#player.copy,
    case check_reset(Player, SerialId) of
        ?ok ->
            CopyIdList = read_serial_list(SerialId),
            {CopyData3, IsOk, CopyPacket} = reset_serial_times(CopyIdList, CopyData, ?CONST_SYS_FALSE, <<>>),
            if
%%                 Player#player.state =:= ?CONST_SYS_USER_STATE_GM -> % gm就是nb
%%                     SerialBag    = CopyData3#copy_data.serial_bag,
%%                     SerialBag2   = update_reset_list(SerialBag, SerialId),
%%                     CopyData4    = CopyData3#copy_data{serial_bag = SerialBag2},
%%                     Player2      = update_copy_data(Player, CopyData4),
%% 					ResetList	 = get_max_reset_serial(Player, SerialBag2),
%%                     PacketOk     = msg_sc_reset_list(ResetList),
%%                     misc_packet:send(UserId, <<PacketOk/binary, CopyPacket/binary>>),
%%                     Player2;
                ?CONST_SYS_TRUE =:= IsOk ->
                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 50, ?CONST_COST_COPY_RESET_TIMES) of
                        ?ok ->
                            SerialBag    = CopyData3#copy_data.serial_bag,
                            SerialBag2   = update_reset_list(SerialBag, SerialId),
                            CopyData4    = CopyData3#copy_data{serial_bag = SerialBag2},
                            Player2      = update_copy_data(Player, CopyData4),
							ResetList	 = get_max_reset_serial(Player, SerialBag2),
                            PacketOk     = msg_sc_reset_list(ResetList),
                            misc_packet:send(UserId, <<PacketOk/binary, CopyPacket/binary>>),
                            Player2;
                        _X ->
                            Player
                    end;
                ?true ->
                    PacketErr = message_api:msg_notice(?TIP_COPY_SINGLE_NO_RESET),
                    misc_packet:send(UserId, <<PacketErr/binary, CopyPacket/binary>>),
                    Player
            end;
        {?error, ErrorCode} ->
            PacketErr2 = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, PacketErr2),
            Player
    end.

%% 获取已经不能重置的精英副本系列
get_max_reset_serial(Player, SerialBag) ->
	Info        = Player#player.info,
	VipLv		= player_api:get_vip_lv(Info),
	MaxTimes	= player_vip_api:get_elite_copy_reset_times(VipLv),
	[{Serial#serial_one.id}|| Serial <- SerialBag, Serial#serial_one.reseted_times =:= MaxTimes].

%% 重置副本次数
reset_copy_times(CopyData, CopyId) ->
    CopyBag = CopyData#copy_data.copy_bag,
    {NewCopyBag, IsReseted} = 
        case copy_bag_api:search(CopyId, CopyBag) of
            CopyOne when is_record(CopyOne, copy_one) ->
                CopyOne2 = CopyOne#copy_one{daily_times = 0},
                CopyBag2 = copy_bag_api:push(CopyOne2, CopyBag),
                {CopyBag2, ?CONST_SYS_TRUE};
            ?false ->
                {CopyBag, ?CONST_SYS_FALSE}
        end,
    CopyData2 = CopyData#copy_data{copy_bag = NewCopyBag},
    {CopyData2, IsReseted}.

check_reset(Player, SerialId) ->
    Info        = Player#player.info,
    VipLv       = player_api:get_vip_lv(Info),
    Times       = player_vip_api:get_elite_copy_reset_times(VipLv),
    CopyData    = Player#player.copy,
    SerialBag   = CopyData#copy_data.serial_bag,
    case serial_bag_api:search(SerialId, SerialBag) of
        #serial_one{reseted_times = STimes} when STimes < Times ->
            ?ok;
        ?false ->
            {?error, ?TIP_COPY_SINGLE_RESETED};
        #serial_one{} when Player#player.state =:= ?CONST_SYS_USER_STATE_GM ->
            ?ok;
        _ ->
            {?error, ?TIP_COPY_SINGLE_RESETED}
    end.

%% 完成任务投放副本id
%% 1.要开启的副本的前置副本已经通关?
%% 2.没通关的就先屏蔽了
insert_new(Player, 0) ->
    {Player, <<>>};
insert_new(Player, CopySingleId) ->
    CopyData      = Player#player.copy,
    RecCopySingle = read(CopySingleId),
    Prev          = RecCopySingle#rec_copy_single.prev,
    case is_first(CopyData, Prev) of
        ?true when 0 =/= Prev ->
            CopyData2 = insert_shadow(CopyData, CopySingleId),
            Player2   = update_copy_data(Player, CopyData2),
            {Player2, <<>>};
        ?true ->
            CopyBag   = CopyData#copy_data.copy_bag,
            SerialBag = CopyData#copy_data.serial_bag,
            {CopyBag2, SerialBag2, PacketMsg} = add_new_copy(CopyBag, SerialBag, CopySingleId),
            CopyData2 = CopyData#copy_data{copy_bag = CopyBag2, serial_bag = SerialBag2},
            Player2   = update_copy_data(Player, CopyData2),
            {Player2, PacketMsg};
        ?false -> % 通关了
            CopyBag   = CopyData#copy_data.copy_bag,
            SerialBag = CopyData#copy_data.serial_bag,
            {CopyBag2, SerialBag2, PacketMsg} = add_new_copy(CopyBag, SerialBag, CopySingleId),
            CopyData2 = CopyData#copy_data{copy_bag = CopyBag2, serial_bag = SerialBag2},
            Player2   = update_copy_data(Player, CopyData2),
            {Player2, PacketMsg}
    end.

%% 插入屏蔽列表
insert_shadow(CopyData, CopyId) ->
    CopyBag  = CopyData#copy_data.copy_bag,
    CopyBag2 = 
        case copy_bag_api:search(CopyId, CopyBag) of
            #copy_one{flags = #copy_flags{is_shadowed = ?CONST_SYS_TRUE}} ->
                CopyBag;
            #copy_one{flags = #copy_flags{is_shadowed = ?CONST_SYS_FALSE}} = CopyOne ->
                Flags  = CopyOne#copy_one.flags,
                Flags2 = Flags#copy_flags{is_shadowed = ?CONST_SYS_TRUE},
                CopyOne2 = CopyOne#copy_one{flags = Flags2},
                copy_bag_api:push(CopyOne2, CopyBag);
            ?false ->
                Flags   = #copy_flags{is_shadowed = ?CONST_SYS_TRUE},
                CopyOne = #copy_one{id = CopyId, daily_times = 0, flags = Flags}, 
                copy_bag_api:push(CopyOne, CopyBag)
        end,
    CopyData#copy_data{copy_bag = CopyBag2}.

%%------------------------------------评价-------------------------------------------------
%% [10000*（通关时间/玩家通关时间）+10000*（玩家总输出/怪物总输出）]/2
%% 
%% SSS：10000*120%
%% SS：10000*（105%~120%）
%% S：10000*（90%~105%）
%% A：10000*（75%~90%）
%% B：10000*（60%~75%）
get_eq(TimePass, TimeStandard, HurtL, HurtR) -> % 获取评价
    TimeRate = TimeStandard / (TimePass+1),
    HurtRate = HurtL / (HurtR+1),
    Eq1      = (10000 * TimeRate) + (10000 * HurtRate),
    Eq1Half  = Eq1 / 2,
    get_eq2(Eq1Half).

%% b=1, a=2, s=3, ss=4, sss=5
get_eq2(Eq) when Eq  < ?CONST_COPY_SINGLE_EQ_B_LOW * ?CONST_SYS_NUMBER_HUNDRED ->
    ?CONST_COPY_SINGLE_EQ_B;
get_eq2(Eq) when Eq =< ?CONST_COPY_SINGLE_EQ_A_LOW * ?CONST_SYS_NUMBER_HUNDRED ->
    ?CONST_COPY_SINGLE_EQ_B;
get_eq2(Eq) when Eq =< ?CONST_COPY_SINGLE_EQ_S_LOW * ?CONST_SYS_NUMBER_HUNDRED ->
    ?CONST_COPY_SINGLE_EQ_A;
get_eq2(Eq) when Eq =< ?CONST_COPY_SINGLE_EQ_SS_LOW * ?CONST_SYS_NUMBER_HUNDRED ->
    ?CONST_COPY_SINGLE_EQ_S;
get_eq2(Eq) when Eq =< ?CONST_COPY_SINGLE_EQ_SSS_LOW * ?CONST_SYS_NUMBER_HUNDRED ->
    ?CONST_COPY_SINGLE_EQ_SS;
get_eq2(_Eq) ->
    ?CONST_COPY_SINGLE_EQ_SSS.

%%--------------------------------奖励---------------------------------------------------

%% 读取奖励
%% {AwardGoodsList, AwardExp, AwardGold, PlotId}
read_award(Info, CopyCur) when is_record(CopyCur, copy_cur) ->
    Rewards     = CopyCur#copy_cur.rewards,
    GoodsDropId = Rewards#copy_reward.goods_drop_id,
    GoodsList   = goods_drop_api:goods_drop(GoodsDropId),
    AwardExp    = round(Rewards#copy_reward.exp), % xxx
    AwardGold   = Rewards#copy_reward.gold,
    PlotTuple   = CopyCur#copy_cur.plot_tuple,
    PlotId      = get_plot(Info, ?CONST_COPY_SINGLE_PROCESS_AFTER_WAVE_3, PlotTuple),
    {GoodsList, AwardExp, AwardGold, PlotId}.
    
%% 读取剧情id
get_plot(Info, Idx, PlotTuple) when is_number(Idx) ->
    PlotIdT1 = erlang:element(Idx, PlotTuple),
    get_plot(Info, PlotIdT1).

get_plot(Info, PlotTuple) when is_tuple(PlotTuple) andalso is_record(Info, info) ->
    Pro = Info#info.pro,
    erlang:element(Pro, PlotTuple);
get_plot(_Info, PlotId) ->
    PlotId.

%% 获取vip奖励
%% 1.vip/元宝
%% 先要判定玩家的副本进度
get_vip_reward(Player) ->
    UserId = Player#player.user_id,
    try
        Vip		= player_api:get_vip_lv(Player#player.info),
        {NewPlayer, TotalPacket} = 
            case player_vip_api:is_elite_reward(Vip) of
                ?CONST_SYS_TRUE ->
                    CopyData  = Player#player.copy,
                    CopyCur   = CopyData#copy_data.copy_cur,
                    ?ok       = is_over_inner(CopyCur),
                    ?ok       = cost_money(UserId, ?CONST_SYS_CASH, ?CONST_COPY_SINGLE_ELITE_MONEY, 0, 0),
                    reward_goods(Player, CopyCur);
                ?CONST_SYS_FALSE ->
                    PacketErr = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
                    {Player, PacketErr}
            end,
        misc_packet:send(UserId, TotalPacket),
        NewPlayer
    catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			Player;
        throw:{?error, ErrorCode2} ->
            PacketErr2 = message_api:msg_notice(ErrorCode2),
            misc_packet:send(UserId, PacketErr2),
            Player;
		Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
			Player
    end.
        
%% 扣钱
cost_money(UserId, Type, Value, _Module, _Fun) ->
    case player_money_api:minus_money(UserId, Type, Value, ?CONST_COST_COPY_GET_VIP_REWARD) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 奖励道具
%% {Player, PacketErr}
reward_goods(Player, CopyCur) ->
    Reward      = CopyCur#copy_cur.rewards,
    GoodsDropId = Reward#copy_reward.goods_drop_id,
    [Goods|_]   = goods_drop_api:goods_drop(GoodsDropId),
    case ctn_bag_api:put(Player, [Goods], ?CONST_COST_COPY_ELITE_AWARD, 1, 1, 1, 0, 0, 1, [CopyCur#copy_cur.copy_id]) of
        {?ok, Player2, _, PacketBag} ->
            PacketGoods = msg_sc_vip_reward(Goods#goods.goods_id, Goods#goods.count),
            Packet = <<PacketGoods/binary, PacketBag/binary>>,
            {Player2, Packet};
        {?error, ErrorCode} ->
            PacketErr = message_api:msg_notice(ErrorCode),
            {Player, PacketErr}
    end.

%% 通关副本刷新副本图的亮/暗
pass_copy(Player, CopyId) ->
    CopyData = Player#player.copy,
    CopyBag  = CopyData#copy_data.copy_bag,
    NewCopyBag = 
        case copy_bag_api:search(CopyId, CopyBag) of
            #copy_one{daily_times = Times} = CopyOne ->
                NewTimes = Times + 1,
                {CopyOneT, PT} = 
                    case read_copy(CopyId) of
                        #rec_copy_single{daily_count = CountLimit} ->
                            P = 
                                if
                                    NewTimes < CountLimit ->
                                        msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE);
                                    ?true andalso ?CONST_SYS_USER_STATE_GM =:= Player#player.state ->
                                        msg_sc_update_copy(CopyId, ?CONST_SYS_TRUE);
                                    ?true ->
                                        msg_sc_update_copy(CopyId, ?CONST_SYS_FALSE)
                                end,
                            CopyOne2 = CopyOne#copy_one{daily_times = NewTimes},
                            {CopyOne2, P};
                        _ ->
                            {CopyOne, <<>>}
                    end,
                UserId = Player#player.user_id,
                misc_packet:send(UserId, PT),
                copy_bag_api:push(CopyOneT, CopyBag);
            ?false ->
                CopyBag
        end,
    NewCopyData = CopyData#copy_data{copy_bag = NewCopyBag},
    Player#player{copy = NewCopyData}.

%% 精英战场可挑战场数
get_elite_copy_times(Player) ->
	CopyData  = Player#player.copy,
	CopyBag	  = CopyData#copy_data.copy_bag,
	RemainEliteList = [X || X <- CopyBag, X#copy_one.daily_times =:= 0, 
							(X#copy_one.flags)#copy_flags.is_shadowed =/= 1, 
							X#copy_one.id >= 20000],
	length(RemainEliteList).

%% 剩余重置精英战场次数
get_elite_reset_times(Player) ->
	Copy		= Player#player.copy,
	SerialBag   = Copy#copy_data.serial_bag,
	ResetList	= get_max_reset_serial(Player, SerialBag),
	ResetLength = length(ResetList),
	case ResetLength > 0 of
		?true ->
			?CONST_SYS_FALSE;
		?false ->
			?CONST_SYS_TRUE
	end.
%% 	CopyData  = Player#player.copy,
%% 	CopyBag	  = CopyData#copy_data.copy_bag,
%% 	RemainEliteList = [X || X <- CopyBag, X#copy_one.daily_times =:= 0, 
%% 							(X#copy_one.flags)#copy_flags.is_shadowed =/= 1, 
%% 							X#copy_one.id >= 20000],
%% 	length(RemainEliteList).

%% 自动翻牌
auto_turn_card(Player, Type, Flag) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	VipLv		= (Info#info.vip)#vip.lv,
	%%vip判断
	Times	= 
		case Type of
			?CONST_ELITECOPY_AUTO_TURNCARD_ELITECOPY ->
				player_vip_api:is_elite_reward(VipLv);
			?CONST_ELITECOPY_AUTO_TURNCARD_TOWER ->
				player_vip_api:get_tower_but_ext_times(VipLv)
		end,
	case Times of
		?CONST_SYS_TRUE ->
			case Flag of
				?true ->
					insert_auto_turn_card(UserId, Type);
				?false ->
					ets_api:delete(?CONST_ETS_AUTO_TURN_CARD, {UserId, Type})
			end,
			Packet	= msg_sc_auto_turncard(Type, Flag),
			misc_packet:send(UserId, Packet);
		?CONST_SYS_FALSE ->
                PacketErr = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
				misc_packet:send(UserId, PacketErr)
	end.

%% 获取vip奖励
%% 1.vip/元宝
auto_turn_card_reward(Player, RaidElite) ->
    UserId 		= Player#player.user_id,
	{_ExpRound, _MeritoriousRound, _BGoldRound, GoodsDropId} = RaidElite#raid_elite.reward_pass, 
	Type		= ?CONST_ELITECOPY_AUTO_TURNCARD_ELITECOPY,
    try
		Flag	= get_auto_turn_card(Player#player.user_id, Type),
        case Flag of
            ?true ->
                ?ok         		= cost_money(UserId, ?CONST_SYS_CASH, ?CONST_COPY_SINGLE_ELITE_MONEY, 0, 0),
				[Goods|_]   		= goods_drop_api:goods_drop(GoodsDropId),
				Fun	= fun(Item) ->
							  {Item#goods.goods_id, Item#goods.count}
					  end,
				RewardGoods			= lists:map(Fun, [Goods]),
                DailyTimes          = 
                    case lists:keyfind(RaidElite#raid_elite.copy_id, #copy_one.id, (Player#player.copy)#copy_data.copy_bag) of
                        #copy_one{daily_times = DailyTimesT} ->
                            DailyTimesT;
                        _ ->
                            0
                    end,
			    {Player2, Packet2}   = 
                    case ctn_bag_api:put(Player, [Goods], ?CONST_COST_COPY_VIP_CARD_GET, 1, 1, 1, 0, 0, 1, [RaidElite#raid_elite.copy_id, DailyTimes, 0, 0, 0, 0]) of
				        {?ok, Player_2, _, PacketBag} ->
				            PacketGoods = msg_sc_vip_reward(Goods#goods.goods_id, Goods#goods.count),
				            Packet = <<PacketGoods/binary, PacketBag/binary>>,
							Packet1				= msg_sc_auto_turncard_reward(Type, RewardGoods, 0),
				            {Player_2, <<Packet/binary, Packet1/binary>>};
				        {?error, ErrorCode} ->
				            PacketErr = message_api:msg_notice(ErrorCode),
				            {Player, PacketErr}
				    end,
				{Player2, Packet2};
            ?false ->
                {Player, <<>>}
        end
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{Player, <<>>};
        throw:{?error, ErrorCode2} ->
            PacketErr2 = message_api:msg_notice(ErrorCode2),
            {Player, PacketErr2};
		Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
			{Player, <<>>}
    end.

%% 扫荡自动翻牌
insert_auto_turn_card(UserId, Type) ->
	ets_api:insert(?CONST_ETS_AUTO_TURN_CARD, {{UserId, Type}}).

%% 查询自动翻牌
get_auto_turn_card(UserId, Type) ->
	case ets_api:lookup(?CONST_ETS_AUTO_TURN_CARD, {UserId, Type}) of
		?null -> ?false;
		{{UserId, Type}} -> ?true
	end.

%% 
%%-------------------------------------协议---------------------------------------------
%% 怪物信息
%%[CopyId,MonsterId,Wave, PlotId]
msg_sc_monster_info(CopyData, IsNewbie) ->
    CopyCur   = CopyData#copy_data.copy_cur,
    CopyId    = CopyCur#copy_cur.copy_id,
    MonsterId = CopyCur#copy_cur.monster_id,
    Wave      = CopyCur#copy_cur.map_step,
    PlotId    = CopyCur#copy_cur.plot_id,
    msg_sc_monster_info(CopyId, MonsterId, Wave, PlotId, IsNewbie).
msg_sc_monster_info(CopyId,MonsterId,Wave, PlotId, IsNewbie) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_MONSTER_INFO, ?MSG_FORMAT_COPY_SINGLE_SC_MONSTER_INFO, [CopyId,MonsterId,Wave, PlotId, IsNewbie]).

%% 发起战斗成功
%%[Result]
msg_sc_battle_ok(Result) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_BATTLE_OK, ?MSG_FORMAT_COPY_SINGLE_SC_BATTLE_OK, [Result]).
%% 
%% %% 副本信息
%% %%[{CopyId,State},{CopyId,Times,IsTaken}]
%% msg_sc_copy_info(List1,List2) ->
%%     List22 = [{CopyId, Times, 0}||{CopyId, Times} <- List2],
%%     misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_COPY_INFO, ?MSG_FORMAT_COPY_SINGLE_SC_COPY_INFO, [List1,List22]).

%% 副本整体信息 - 替13008
%%[{CopyId,FlagMon},{CopyId,IsLight},{SerialId}]
msg_sc_copy_all_info(List1,List2,List3) ->
    List1_2 = [{CopyId, FlagMon+1}||{CopyId, FlagMon}<-List1],
    F = fun({CopyId, Times}, OldList) ->
                RecCopySingle = read(CopyId),
                if
                    Times < RecCopySingle#rec_copy_single.daily_count ->
                        [{CopyId, ?CONST_SYS_TRUE}|OldList];
                    ?true ->
                        [{CopyId, ?CONST_SYS_FALSE}|OldList]
                end
        end,
    List2_2 = lists:foldl(F, [], List2),
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_COPY_ALL_INFO, ?MSG_FORMAT_COPY_SINGLE_SC_COPY_ALL_INFO, [List1_2,List2_2,List3]).

%% 副本信息更新
%%[CopyId,IsLight]
msg_sc_update_copy(CopyId,IsLight) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_UPDATE_COPY, ?MSG_FORMAT_COPY_SINGLE_SC_UPDATE_COPY, [CopyId,IsLight]).

%% 副本开启状态改变
%%[CopyId,FlagMon]
%% FlagMon -> IsTask + 1,
%% FlagMon:1第1组怪；2第2组怪
%% IsTask:0未通关；1通关
msg_sc_proccess_update(CopyId,FlagMon) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_PROCCESS_UPDATE, ?MSG_FORMAT_COPY_SINGLE_SC_PROCCESS_UPDATE, [CopyId,FlagMon+1]).

%% 副本已完成
%%[CopyId,Flag,{GoodsId,Num},Evaluate,Exp,Gold,PlotId]
msg_sc_copy_end(CopyId,Flag,GoodsList,Evaluate,Exp,Gold,PlotId, HurtL, HurtR, TimePass) ->
    F = fun(#goods{goods_id = GoodsId, count = Count}, ListOld) ->
                [{GoodsId, Count}|ListOld]
        end,
    NewList = lists:foldl(F, [], GoodsList),
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_COPY_END, 
                     ?MSG_FORMAT_COPY_SINGLE_SC_COPY_END, 
                     [CopyId,Flag,NewList,Evaluate,Exp, Gold, PlotId, HurtL, HurtR, TimePass]).

%% 扫荡信息
%%[Time,CopyId, Times]
msg_sc_raid_info(Time,CopyId, Times) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_RAID_INFO, ?MSG_FORMAT_COPY_SINGLE_SC_RAID_INFO, [Time,CopyId, Times]).

%% 每波扫荡结果
%%[{GoodsName,Count},Exp,Gold,Meritorious,CopyId,Round,Wave,IsPass,{MonId,KillCount}]
msg_sc_raid_a_wave(Flag,List1,Exp,Gold,Meritorious,CopyId,Round,Wave,IsPass,List2) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_RAID_A_WAVE, ?MSG_FORMAT_COPY_SINGLE_SC_RAID_A_WAVE, [List1,Exp,Gold,Meritorious,CopyId,Round,Wave,IsPass,List2,Flag]).

%% 回复背包空位数
%%[Result]
msg_sc_empty(Result) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_EMPTY, ?MSG_FORMAT_COPY_SINGLE_SC_EMPTY, [Result]).

%% vip副本翻牌奖励
%%[GoodsId,GoodsCount]
msg_sc_vip_reward(GoodsId,GoodsCount) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_VIP_REWARD, ?MSG_FORMAT_COPY_SINGLE_SC_VIP_REWARD, [GoodsId,GoodsCount]).

%% 副本系列重置信息
%%[{SerialId}]
msg_sc_reset_list(List1) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_RESET_LIST, ?MSG_FORMAT_COPY_SINGLE_SC_RESET_LIST, [List1]).

%% 0点精英副本重置通知
msg_sc_notice_elite_reset(UserId) ->
    Packet = misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_NOTICE_ELITE_RESET, ?MSG_FORMAT_COPY_SINGLE_SC_NOTICE_ELITE_RESET, [0]),
	misc_packet:send(UserId, Packet).

%% 返回精英副本扫荡信息
%%[Time,{CopyId}]
msg_sc_elite_info(Time,List1, Is2, SerialId) ->
    List2 = [{CopyId}||CopyId <- List1],
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_ELITE_INFO, ?MSG_FORMAT_COPY_SINGLE_SC_ELITE_INFO, [Time,List2,Is2,SerialId]).

%% 精英副本扫荡结果
%%[{GoodsId,Count},Exp,Gold,Meritorious,CopyId,{MonId,KillCount}]
msg_sc_elite_result(List1,Exp,Gold,Meritorious,CopyId,List2) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_ELITE_RESULT, ?MSG_FORMAT_COPY_SINGLE_SC_ELITE_RESULT, [List1,Exp,Gold,Meritorious,CopyId,List2]).

%% 返回精英副本扫荡开始信息
%%[SerialId,Time]
msg_sc_start_elite(SerialId,Time) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_START_ELITE, ?MSG_FORMAT_COPY_SINGLE_SC_START_ELITE, [SerialId,Time]).

%% 元宝自动翻牌
msg_sc_auto_turncard(Type, Flag) ->
	misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_AUTOCARD, ?MSG_FORMAT_COPY_SINGLE_SC_AUTOCARD, [Type, Flag]).

%% 元宝自动翻牌奖励
msg_sc_auto_turncard_reward(Type, GoodList, PassId) ->
	misc_packet:pack(?MSG_ID_COPY_SINGLE_AUTO_TURNCARD_REWARD, ?MSG_FORMAT_COPY_SINGLE_AUTO_TURNCARD_REWARD, [Type, GoodList, PassId]).

%% 副本战报信息
%%[CopyId,{UserId,UserName,ReportId}]
msg_sc_report_list(CopyId,List1) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_REPORT_LIST, ?MSG_FORMAT_COPY_SINGLE_SC_REPORT_LIST, [CopyId,List1]).
%% 装备
%%[GoodsId]
msg_sc_equip(GoodsId) ->
    misc_packet:pack(?MSG_ID_COPY_SINGLE_SC_EQUIP, ?MSG_FORMAT_COPY_SINGLE_SC_EQUIP, [GoodsId]).