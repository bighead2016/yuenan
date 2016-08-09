%% Author: zero
%% Created: 2012-9-25
%% Description: 扫荡
-module(copy_single_raid_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([flush_offline/2, start_raid/3, update_raid/0, update_raid_round_cb/2, 
         update_raid_wave_cb/2, stop_raid/1, quick/2, get_end_time/1,
         update_raid_wave_offline/2, update_raid_round_offline/2,
         push_packet/2, change_online/1, change_offline/1]).

%%
%% API Functions
%%

%% 每波怪扫荡
start_raid(Player, CopyId, TotalRound) ->
    case check_raid(Player, CopyId, TotalRound) of
        {MonsterTuple, WaveRewardTuple, RoundReward, MapId, WaveSize} ->
            TotalTime  = calc_total_time(WaveSize, TotalRound), % 总共要花秒数
            Now        = misc:seconds(), 
            NextSkip   = calc_next_wave_time(Now),              % 下波或者下轮的时间点
            EndTime    = calc_end_time(Now, TotalTime),         % 结束时间点
            
            UserId     = Player#player.user_id,
            MonsGroup  = get_mons_group(MonsterTuple, ?CONST_COPY_SINGLE_PROCESS_WAVE_1),
			RaidPlayer = record_raid_player(
						   UserId,		CopyId,   MapId,      MonsterTuple, 
						   MonsGroup,  	NextSkip, TotalRound, TotalRound, 
						   ?CONST_COPY_SINGLE_PROCESS_WAVE_1, 
						   WaveSize,    EndTime,  0,          0, 
						   WaveRewardTuple, RoundReward
										   ),
            insert_raid(RaidPlayer),
            PacketTotalTime = copy_single_api:msg_sc_raid_info(TotalTime, CopyId, TotalRound), % 扫荡初始信息
            
            % 成就 
            achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_CLEARANCE, 0, 1),
            
			{?ok, TotalTime, PacketTotalTime};
		{?error, ErrorCode2, PacketError2} ->
			{?error, ErrorCode2, PacketError2}
    end.

calc_total_time(Wave, Round)  -> calc_round_time(Wave) * Round.
calc_end_time(Now, TotalTime) -> Now + TotalTime.
calc_round_time(Wave)         -> ?CONST_COPY_SINGLE_TIME_A_WAVE * Wave.
calc_next_wave_time(Time)     -> Time + ?CONST_COPY_SINGLE_TIME_A_WAVE.

%%-----------------------------------进入在线普通扫荡检查---------------------------------------------
%% 检查进入扫荡
check_raid(Player, CopyId, Round) ->
    try
        ?ok = check_sp(Player, Round),
        ?ok = check_bag_full(Player),
        {MonsTuple, OldRewardTuple, RoundReward, MapId, Size} = check_mons(CopyId, Player),
        {MonsTuple, OldRewardTuple, RoundReward, MapId, Size}
    catch
        throw:{?error, ?TIP_COMMON_SP_NOT_ENOUGH = ErrorCode} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            {?error, ErrorCode, PacketError};
        throw:{?error, ErrorCode} ->
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError}
    end.
        
%% 体力够?
check_sp(Player, Round) ->
    Info   = Player#player.info,
    Sp     = Info#info.sp,
    SpNeed = ?CONST_COPY_SINGLE_SP_A_WAVE * Round,
    if
        Sp >= SpNeed ->
            ?ok;
        ?true ->
            throw({?error, ?TIP_COMMON_SP_NOT_ENOUGH})
    end.

%% 背包满了?
check_bag_full(Player) ->
    case ctn_bag2_api:is_full(Player#player.bag) of
        ?true ->
            throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH});
        ?false ->
            ?ok
    end.

%% 读取怪物
check_mons(CopyId, Player) ->
    case get_mons(CopyId, Player) of
        {MonsTuple, OldRewardTuple, RoundReward, MapId, Size} ->
            {MonsTuple, OldRewardTuple, RoundReward, MapId, Size};
        ?null ->
            throw({?error, ?TIP_COPY_SINGLE_NOT_EXIST})
    end.
%%-----------------------------------------------------------------------------------------------

%% 封装扫荡信息
record_raid_player(UserId, CopyId, MapId, MonsTuple, MonsGroup, NextSkip, TotalRound, 
                   Round, Wave, WaveSize, EndTime, SpUsed, CashUsed, WaveReward, RoundReward) ->
    #raid_player{
                 user_id      = UserId,      copy_id     = CopyId,     map_id      = MapId, 
                 cash_used    = CashUsed,    end_time    = EndTime,    mons_group  = MonsGroup,
                 mons_tuple   = MonsTuple,   next_skip   = NextSkip,   round       = Round, 
                 round_reward = RoundReward, sp_used     = SpUsed,     total_round = TotalRound,
                 wave         = Wave,        wave_reward = WaveReward, wave_size   = WaveSize,
                 is_even_wave = ?false,      is_online   = ?CONST_SYS_TRUE
                }.

%% 读取怪物组信息
get_mons_group(RaidPlayer, Idx) when is_record(RaidPlayer, raid_player) ->
    MonsterTuple = RaidPlayer#raid_player.mons_tuple,
    get_mons_group(MonsterTuple, Idx);
get_mons_group(MonsterTuple, Idx) ->
    Size = erlang:size(MonsterTuple),
    if
        Idx =< Size ->
            erlang:element(Idx, MonsterTuple);
        ?true ->
            []
    end.

%% 读取扫荡的怪物信息
%% {MonsTuple, OldRewardTuple, RoundReward, MapId, Size}/?null
get_mons(CopyId, Player) when is_number(CopyId), is_record(Player, player) ->
    CopyData      = Player#player.copy,
    IsFinished    = copy_single_api:is_finish_task(CopyData, CopyId),
    RecCopySingle = copy_single_api:read(CopyId),
    case get_mons(RecCopySingle, IsFinished) of
        {MonsTuple, OldRewardTuple, Size} when MonsTuple =/= ?null ->
            RoundReward   = read_round_reward(RecCopySingle, Player),
            MapId         = get_map_id(RecCopySingle),
            {MonsTuple, OldRewardTuple, RoundReward, MapId, Size};
        {?null, ?null, 0} ->
            ?null
    end;
get_mons(?null, _) -> {?null, ?null, 0};
get_mons(RecCopySingle, ?CONST_SYS_FALSE) ->
    MonsterTuple = RecCopySingle#rec_copy_single.monster,
    Size         = erlang:size(MonsterTuple),
    NewMonTuple  = erlang:make_tuple(Size, 0),
    get_mon_tuple(MonsterTuple, 1, Size, NewMonTuple, NewMonTuple);
get_mons(RecCopySingle, ?CONST_SYS_TRUE) ->
    MonsterTuple = RecCopySingle#rec_copy_single.monster2,
    Size         = erlang:size(MonsterTuple),
    NewMonTuple  = erlang:make_tuple(Size, 0),
    get_mon_tuple(MonsterTuple, 1, Size, NewMonTuple, NewMonTuple).

%% 读取怪物信息
get_mon_tuple(MonsterTuple, Nth, Size, OldMonTuple, OldRewardTuple) when Nth =< Size ->
    {MonId, _Ai} = erlang:element(Nth, MonsterTuple),
    case monster_api:monster(MonId) of
        Monster when is_record(Monster, monster) ->
            List           = get_mon_list(Monster),
            NewMonTuple    = erlang:setelement(Nth, OldMonTuple, List), 
            Reward         = get_mon_reward(Monster),
            NewRewardTuple = erlang:setelement(Nth, OldRewardTuple, Reward),
            get_mon_tuple(MonsterTuple, Nth + 1, Size, NewMonTuple, NewRewardTuple);
        ?null ->
            NewMonTuple    = erlang:setelement(Nth, OldMonTuple, []), 
            Reward         = get_default_reward(),
            NewRewardTuple = erlang:setelement(Nth, OldRewardTuple, Reward),
            get_mon_tuple(MonsterTuple, Nth + 1, Size, NewMonTuple, NewRewardTuple)
    end;
get_mon_tuple(_MonsterTuple, _Nth, Size, OldMonTuple, OldRewardTuple) ->
    {OldMonTuple, OldRewardTuple, Size}.

%% 读取怪物id列表
get_mon_list(Monster) ->
    Camp     = Monster#monster.camp,
    Position = Camp#camp.position,
    List     = erlang:tuple_to_list(Position),
    F = fun(X, OldList) when is_number(X) ->
                OldList;
           (#camp_pos{id = M}, OldList) ->
                [{M}|OldList]
        end,
    lists:foldl(F, [], List).

%% 读取怪物奖励
get_mon_reward(Monster) ->
    Exp         = Monster#monster.hook_exp*2,
    Meritorious = Monster#monster.meritorious,
    Gold        = Monster#monster.gold,
    DropId      = Monster#monster.drop_id,
    {Exp, Meritorious, Gold, DropId}.

%% 默认怪物奖励
get_default_reward() ->
    erlang:make_tuple(4, 0).

%% 读取地图id
get_map_id(RecCopySingle) when is_record(RecCopySingle, rec_copy_single) ->
    RecCopySingle#rec_copy_single.map;
get_map_id(?null) -> 0.

%% 每波奖励
%% [{Exp, Meritorious, Gold, GoodsDropId}|...]
get_wave_reward(RaidPlayer, Idx) when is_record(RaidPlayer, raid_player) ->
    WaveReward = RaidPlayer#raid_player.wave_reward,
    get_wave_reward(WaveReward, Idx);
get_wave_reward(RewardTuple, Idx) ->
    case erlang:size(RewardTuple) of
        Size when Idx =< Size ->
            erlang:element(Idx, RewardTuple);
        _ -> % 这按道理来说不应该出现的
            get_default_reward()
    end.

%% 每轮奖励
%% {AwardGoodsList, AwardExp, AwardGold, GoodsDropId}
read_round_reward(?null, _Player) -> get_default_reward();
read_round_reward(RecCopySingle, Player) when is_record(Player, player) ->
    AwardGoods = RecCopySingle#rec_copy_single.award,
    AwardExp   = RecCopySingle#rec_copy_single.exp,
    Rate       = guild_api:get_exp_add(Player),
    Info       = Player#player.info,
    RankRate   = rank_api:get_rank_rate(Info#info.lv),
    AwardExp2  = round(AwardExp * Rate + AwardExp * RankRate),
    AwardGold  = RecCopySingle#rec_copy_single.gold,
    {AwardExp2, 0, AwardGold, AwardGoods}.
    
%% 更新扫荡信息
%% 时间过了，就调一下奖励
update_raid() ->
	?RANDOM_SEED,
    RaidList = ets_api:list(?CONST_ETS_RAID_PLAYER),
    Now = misc:seconds(),
    F = fun(RaidPlayer = #raid_player{next_skip = NextSkip, round = Round, wave = Wave, wave_size = Size}) 
             when 0 < Round andalso NextSkip =< Now andalso Wave < Size ->
                UserId     = RaidPlayer#raid_player.user_id,
                CopyId     = RaidPlayer#raid_player.copy_id,
                WaveReward = get_wave_reward(RaidPlayer, Wave),  
                do_update(UserId, ?MODULE, update_raid_wave_cb, [CopyId, WaveReward, Wave, RaidPlayer]),
                NewNextSkip   = NextSkip + ?CONST_COPY_SINGLE_TIME_A_WAVE,
                NewRaidPlayer = RaidPlayer#raid_player{next_skip = NewNextSkip, wave = Wave + 1},
                insert_raid(NewRaidPlayer);
           (RaidPlayer = #raid_player{next_skip = NextSkip, round = Round, wave = Size, wave_size = Size}) 
             when 0 < Round andalso NextSkip =< Now -> % 回复到第一波
                UserId      = RaidPlayer#raid_player.user_id,
                CopyId      = RaidPlayer#raid_player.copy_id,
                WaveReward  = get_wave_reward(RaidPlayer, Size),                      
                RoundReward = RaidPlayer#raid_player.round_reward, 
                do_update(UserId, ?MODULE, update_raid_round_cb, [CopyId, WaveReward, RoundReward, Size, RaidPlayer]),
                NewNextSkip   = NextSkip + ?CONST_COPY_SINGLE_TIME_A_WAVE,
                NewRaidPlayer = RaidPlayer#raid_player{next_skip = NewNextSkip, round = Round - 1, wave = 1},
                insert_raid(NewRaidPlayer);
           (#raid_player{next_skip = NextSkip, round = Round}) 
             when 0 < Round andalso NextSkip > Now ->
                ?ignore;
           (#raid_player{user_id = UserId, round = 0}) ->
                delete_raid(UserId)
        end,
    lists:foreach(F, RaidList).

%% 更新回调
do_update(UserId, Module, update_raid_wave_cb, Arg) ->
    case player_api:process_send(UserId, Module, update_raid_wave_cb, Arg) of
        ?true -> ?ok; % 在线
        ?false -> player_offline_api:offline(Module, UserId, {update_raid_wave_offline, Arg}) % 离线
    end;
do_update(UserId, Module, update_raid_round_cb, Arg) ->
    case player_api:process_send(UserId, Module, update_raid_round_cb, Arg) of
        ?true -> ?ok; % 在线
        ?false -> player_offline_api:offline(Module, UserId, {update_raid_round_offline, Arg}) % 离线
    end.

change_offline(UserId) ->
    case select_raid(UserId) of
        ?null ->
            ?ok;
        RaidPlayer ->
            insert_raid(RaidPlayer#raid_player{is_online = ?CONST_SYS_FALSE})
    end.

change_online(UserId) ->
    case select_raid(UserId) of
        ?null ->
            ?ok;
        RaidPlayer ->
            insert_raid(RaidPlayer#raid_player{is_online = ?CONST_SYS_TRUE})
    end.

%% 再上线时的进度显示
get_end_time(UserId) ->
    RaidPlayer = select_raid(UserId),
    if
        RaidPlayer =:= ?null ->
            <<>>;
        ?true ->
            Now = misc:seconds(),
            EndTime = RaidPlayer#raid_player.end_time,
            CopyId  = RaidPlayer#raid_player.copy_id,
            Round   = RaidPlayer#raid_player.round,
            Wave    = RaidPlayer#raid_player.wave,
            DeltaTime = EndTime - Now,
            if
                0 =/= Round andalso 0 =/= Wave andalso 0 < DeltaTime ->
                    copy_single_api:msg_sc_raid_info(DeltaTime, CopyId, Round);
                ?true ->
                    change_online(UserId),
                    delete_raid(UserId),
                    copy_single_api:msg_sc_raid_info(0, CopyId, 0)
            end
    end.

%%-------------------------------刚上线时处理----------------------------------------------------
%% 压新的包到offline包中
push_packet(Player, Packet) ->
    OfflinePacket = Player#player.offline_packet,
    Packet2 = <<OfflinePacket/binary, Packet/binary>>,
    Player#player{offline_packet = Packet2}.

%% 每波处理
update_raid_wave_offline(Player, [CopyId, WaveReward, 1, RaidPlayer]) -> % 第一波要扣体力
    UserId = Player#player.user_id,
    case player_api:minus_sp(Player, ?CONST_COPY_SINGLE_SP_A_WAVE, ?CONST_COST_COPY_SP) of
        {?ok, Player2} ->
            {Player3, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
                = get_wave_reward(Player2, WaveReward, 1, CopyId),
            {Player4, PacketTask} = update_battle_task(Player3, CopyId, 1, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
													   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
            Player5 = push_packet(Player4, PacketTask),
            {?ok, Player5};
        {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            PlayerPushed = push_packet(Player, PacketError),
            delete_raid(UserId),
            {?ok, PlayerPushed};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            PlayerPushed = push_packet(Player, Packet),
            delete_raid(UserId),
            {?ok, PlayerPushed}
    end;
update_raid_wave_offline(Player, [CopyId, WaveReward, Wave, RaidPlayer]) -> % 
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_wave_reward(Player, WaveReward, Wave, CopyId),
    {Player3, PacketTask} = update_battle_task(Player2, CopyId, Wave, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
											   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
    Player4 = push_packet(Player3, PacketTask),
    {?ok, Player4}.

%% 每轮扫荡
update_raid_round_offline(Player, [CopyId, WaveReward, RoundReward, 1, RaidPlayer]) ->
    % 每轮最后一波
    {Player3, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_wave_reward(Player, WaveReward, 1, CopyId),

    % 每轮奖励
    {Player4, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
        = get_round_reward(Player3, RoundReward, CopyId),
    PacketRound = send_award(?CONST_SYS_FALSE, GoodsListDisplay2, ExpDisplay2, BGoldDisplay2, 
							 MeritoriousDisplay2, RaidPlayer, ?CONST_SYS_TRUE, []),
    
    % 更新任务
    {Player5, PacketTask} = update_battle_task(Player4, CopyId, 1, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
											   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
    {?ok, Player6} = task_api:update_copy(Player5, CopyId),
    Player7 = push_packet(Player6, <<PacketTask/binary, PacketRound/binary>>),
    {?ok, Player7};
update_raid_round_offline(Player, [CopyId, WaveReward, RoundReward, Wave, RaidPlayer]) ->
    % 每轮最后一波
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_wave_reward(Player, WaveReward, Wave, CopyId),
    
    % 每轮奖励
    {Player3, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
        = get_round_reward(Player2, RoundReward, CopyId),
    PacketRound = send_award(?CONST_SYS_FALSE, GoodsListDisplay2, ExpDisplay2, BGoldDisplay2, 
							 MeritoriousDisplay2, RaidPlayer, ?CONST_SYS_TRUE, []),
    
    % 更新任务     
    {Player4, PacketTask} = update_battle_task(Player3, CopyId, Wave, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
											   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
    {?ok, Player5} = task_api:update_copy(Player4, CopyId, 0),
    Player6 = push_packet(Player5, <<PacketTask/binary, PacketRound/binary>>),
    {?ok, Player6}.

%%--------------------------------在线时的处理---------------------------------------------------
%% 每波处理
update_raid_wave_cb(Player, [CopyId, WaveReward, 1, RaidPlayer]) -> % 第一波要扣体力
    UserId = Player#player.user_id,
    case player_api:minus_sp(Player, ?CONST_COPY_SINGLE_SP_A_WAVE, ?CONST_COST_COPY_SP) of
        {?ok, Player2} ->
            {Player3, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
                = get_wave_reward(Player2, WaveReward, 1, CopyId),
            {Player4, PacketTask} = update_battle_task(Player3, CopyId, 1, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
													   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
            misc_packet:send(Player#player.net_pid, PacketTask),
            {?ok, Player4};
        {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            misc_packet:send(UserId, PacketError),
            stop_raid(UserId),
            {?ok, Player};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, Packet),
            stop_raid(UserId),
            {?ok, Player}
    end;
update_raid_wave_cb(Player, [CopyId, WaveReward, Wave, RaidPlayer]) -> % 
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_wave_reward(Player, WaveReward, Wave, CopyId),
    {Player3, PacketTask} = update_battle_task(Player2, CopyId, Wave, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
											   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
    misc_packet:send(Player#player.net_pid, PacketTask),
    {?ok, Player3}.

%% 每轮扫荡
update_raid_round_cb(Player, [CopyId, WaveReward, RoundReward, 1, RaidPlayer]) ->
    UserId = Player#player.user_id,
    if
        1 =:= RaidPlayer#raid_player.wave_size -> % 只有一轮的也要扣
            case player_api:minus_sp(Player, ?CONST_COPY_SINGLE_SP_A_WAVE, ?CONST_COST_COPY_SP) of
                {?ok, Player2} ->
                    % 每轮最后一波
                    {Player3, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
                        = get_wave_reward(Player2, WaveReward, 1, CopyId),
                
                    % 每轮奖励
                    {Player4, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
                        = get_round_reward(Player3, RoundReward, CopyId),
                    PacketRound = send_award(?CONST_SYS_TRUE, GoodsListDisplay2, ExpDisplay2, BGoldDisplay2, 
											 MeritoriousDisplay2, RaidPlayer, ?CONST_SYS_TRUE, []),
                    
                    % 更新任务
                    {Player5, PacketTask} = update_battle_task(Player4, CopyId, 1, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
															   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
                    {?ok, Player6} = task_api:update_copy(Player5, CopyId, 0),
                    
                    misc_packet:send(UserId, <<PacketTask/binary, PacketRound/binary>>),
					
					% 增加活跃度
					{?ok, Player7} = schedule_api:add_guide_times(Player6, ?CONST_SCHEDULE_GUIDE_SINGLE_COPY),
                    {?ok, Player7};
                {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
                    UserId = Player#player.user_id,
                    PacketError = player_api:msg_sc_not_enough_sp(),
                    misc_packet:send(UserId, PacketError),
                    stop_raid(UserId),
                    {?ok, Player};
                {?error, ErrorCode} ->
                    Packet = message_api:msg_notice(ErrorCode),
                    misc_packet:send(UserId, Packet),
                    stop_raid(UserId),
                    {?ok, Player}
            end;
        ?true ->
            % 每轮最后一波
            {Player3, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
                = get_wave_reward(Player, WaveReward, 1, CopyId),
        
            % 每轮奖励
            {Player4, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
                = get_round_reward(Player3, RoundReward, CopyId),
			PacketRound = send_award(?CONST_SYS_TRUE, GoodsListDisplay2, ExpDisplay2, BGoldDisplay2, 
									 MeritoriousDisplay2, RaidPlayer, ?CONST_SYS_TRUE, []),
            
            % 更新任务
            {Player5, PacketTask} = update_battle_task(Player4, CopyId, 1, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
													   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
            {?ok, Player6} = task_api:update_copy(Player5, CopyId, 0),
            
            misc_packet:send(UserId, <<PacketTask/binary, PacketRound/binary>>),
			
			% 增加活跃度
			{?ok, Player7} = schedule_api:add_guide_times(Player6, ?CONST_SCHEDULE_GUIDE_SINGLE_COPY),
            {?ok, Player7}
    end;
update_raid_round_cb(Player, [CopyId, WaveReward, RoundReward, Wave, RaidPlayer]) ->
    UserId = Player#player.user_id,
    % 每轮最后一波
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_wave_reward(Player, WaveReward, Wave, CopyId),
    
    % 每轮奖励
    {Player3, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
        = get_round_reward(Player2, RoundReward, CopyId),
	PacketRound = send_award(?CONST_SYS_TRUE, GoodsListDisplay2, ExpDisplay2, BGoldDisplay2, 
							 MeritoriousDisplay2, RaidPlayer, ?CONST_SYS_TRUE, []),
    
    % 更新任务     
    {Player4, PacketTask} = update_battle_task(Player3, CopyId, Wave, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
											   MeritoriousDisplay, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
    {?ok, Player5} = task_api:update_copy(Player4, CopyId, 0),
    
    misc_packet:send(UserId, <<PacketTask/binary, PacketRound/binary>>),
	
	% 增加活跃度
	{?ok, Player6} = schedule_api:add_guide_times(Player5, ?CONST_SCHEDULE_GUIDE_SINGLE_COPY),
    {?ok, Player6}.

%% 读取每波怪奖励
get_wave_reward(Player, WaveReward, _Wave, CopyId) ->
    {ExpWave, MeritoriousWave, BGoldWave, GoodsDropIdWave} = WaveReward,
    UserId = Player#player.user_id,
    
    % 经验
    {?ok, Player2} = player_api:exp(Player, ExpWave),
    
    % 军功
    {?ok, Player3} = player_api:plus_meritorious(Player2, MeritoriousWave, ?CONST_COST_COPY_RAID_AWARD),
    
    % 铜钱
    award_gold_bind(UserId, BGoldWave),

    % 道具
    GoodsListWave   = goods_drop_api:goods_drop(GoodsDropIdWave),
    Player4 = award_goods(Player3, GoodsListWave, CopyId),
    {Player4, ExpWave, BGoldWave, MeritoriousWave, GoodsListWave}.

%% 读取每轮怪奖励
get_round_reward(Player, RoundReward, CopyId) ->
    {ExpRound, MeritoriousRound, BGoldRound, GoodsDropIdRound} = RoundReward, 
    UserId = Player#player.user_id,
    
    % 经验
    {?ok, Player2} = player_api:exp(Player, ExpRound),
    
    % 铜钱
    award_gold_bind(UserId, BGoldRound),
    
    % 军功
    {?ok, Player3} = player_api:plus_meritorious(Player2, MeritoriousRound, ?CONST_COST_COPY_RAID_AWARD),

    % 道具
    GoodsListRound   = goods_drop_api:goods_drop(GoodsDropIdRound),
    Player4 = award_goods(Player3, GoodsListRound, CopyId),
    {Player4, ExpRound, BGoldRound, MeritoriousRound, GoodsListRound}.

%% 前端显示
%% ?ok
send_award(Flag, GoodsListDisplay, ExpDisplay, BGoldDisplay, MeritoriousDisplay, RaidPlayer, IsPass, MonsterList) ->
    F = fun(#mini_goods{goods_id = GoodsId, count = Count}, OldList) ->
                case lists:keytake(GoodsId, 1, OldList) of
                    {value, {GoodsId, CountOld}, OldList2} ->
                        [{GoodsId, Count+CountOld}|OldList2];
                    _ ->
                        [{GoodsId, Count}|OldList]
                end;
           (#goods{goods_id = GoodsId, count = Count}, OldList) ->
                case lists:keytake(GoodsId, 1, OldList) of
                    {value, {GoodsId, CountOld}, OldList2} ->
                        [{GoodsId, Count+CountOld}|OldList2];
                    _ ->
                        [{GoodsId, Count}|OldList]
                end
        end,
    GoodsList = lists:foldl(F, [], GoodsListDisplay),
    CopyId = RaidPlayer#raid_player.copy_id,
    Round = RaidPlayer#raid_player.round,
    Wave = RaidPlayer#raid_player.wave,
    Round2 = RaidPlayer#raid_player.total_round - Round + 1,
    copy_single_api:msg_sc_raid_a_wave(Flag, GoodsList, ExpDisplay, BGoldDisplay, 
									   MeritoriousDisplay, CopyId, 
									   Round2, Wave, IsPass, MonsterList).

%% 更新任务 -- 扫荡杀怪
%% {Player, Packet}
update_battle_task(Player, _CopyId, Wave, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
				   MeritoriousDisplay, RaidPlayer, IsPass, Flag) ->
    case get_mons_group(RaidPlayer, Wave) of
        [] ->
			Packet = send_award(Flag, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
								MeritoriousDisplay, RaidPlayer, IsPass, []),
			{Player, Packet};
		MonsGroup ->
			MapId = RaidPlayer#raid_player.map_id,
			MonsterList = sum_up(MonsGroup, []),
			Packet = send_award(Flag, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
								MeritoriousDisplay, RaidPlayer, IsPass, MonsterList),
			{?ok, Player2} = task_api:update_battle(Player, MapId, MonsGroup, ?CONST_BATTLE_RESULT_LEFT, []),
			{Player2, Packet}
    end.

%% update_battle_task(Player, RaidPlayer, Wave, MonsterList) ->
%%     case get_mons_group(RaidPlayer, Wave) of
%%         [] -> {Player, []};
%%         MonsterList2 ->
%%             MapId = RaidPlayer#raid_player.map_id,
%%             MonsterList3 = sum_up(MonsterList2, MonsterList),
%%             {?ok, Player2} = task_api:update_battle(Player, MapId, MonsterList2, ?CONST_BATTLE_RESULT_LEFT, []),
%%             {Player2, MonsterList3}
%%     end.

sum_up([{MonsterId}|Tail], SumList) ->
    NewSumList = 
        case lists:keytake(MonsterId, 1, SumList) of
            {value, {_MonsterId, Count}, TupleList2} ->
                NewTuple = {MonsterId, Count + 1},
                [NewTuple|TupleList2];
            ?false ->
                [{MonsterId, 1}|SumList]
        end,
    sum_up(Tail, NewSumList);
sum_up([], SumList) ->
    SumList.

%% 奖励绑定铜钱
award_gold_bind(UserId, GoldBind) when GoldBind > 0 ->
    player_money_api:plus_money(UserId, 
                                ?CONST_SYS_GOLD_BIND, GoldBind, 
                                ?CONST_COST_COPY_RAID_AWARD); 
award_gold_bind(_UserId, _GoldBind) ->
    ?ok.

%% 奖励道具
award_goods(Player, GoodsListTotal, CopyId) ->
    UserId = Player#player.user_id,
    case ctn_bag_api:put(Player, GoodsListTotal, ?CONST_COST_COPY_RAID_AWARD, 1, 1, 1, 1, 1, 1, [CopyId]) of
        {?ok, Player2, _, _PacketBag} ->
            NewBag = Player2#player.bag,
            {?ok, Count1} = ctn_bag2_api:empty_count(NewBag),    
            if
                Count1 =< 0 -> % 背包满了
                    stop_raid(UserId);
                ?true ->
                    ?ok
            end,
            Player2;
        {?error, _ErrorCode} ->
            stop_raid(UserId),
            Player
    end.
    
%% 再上线时处理
flush_offline(Player, {Func, Arg}) ->
    Bag = Player#player.bag,
    {?ok, Player2} = 
        case ctn_bag2_api:empty_count(Bag) of
            {?ok, 0} -> {?ok, Player};
            _ -> ?MODULE:Func(Player, Arg)
        end,
    {?ok, Player2};
flush_offline(Player, Data) ->
	?MSG_ERROR("Data=~p~n", [Data]),
	{?ok, Player}.

%% 停止扫荡
stop_raid(UserId) ->
    delete_raid(UserId),
    Packet = copy_single_api:msg_sc_raid_info(0, 0, 0),
    misc_packet:send(UserId, Packet).

%%--------------------------------加速---------------------------------------------------
%% 快速完成
quick(Player, ?CONST_COPY_SINGLE_QUICK_30) -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_30);
quick(Player, ?CONST_COPY_SINGLE_QUICK_60) -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_60);
quick(Player, ?CONST_COPY_SINGLE_QUICK_0)  -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_0).

%% 加速Time秒
quick_2(#player{user_id = UserId} = Player, 0) ->
    case select_raid(UserId) of
        #raid_player{end_time = EndTime} ->
            quick_2(Player, EndTime - misc:seconds());
        ?null ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end;
quick_2(#player{user_id = UserId} = Player, Time) ->
    try
        RaidPlayer	= select_raid(UserId),
        ?ok 		= check_quick(Player, RaidPlayer, Time),
        delete_raid(UserId),
        {RaidPlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player2} = next(RaidPlayer, Time, UserId, <<>>, 0, 0, 0, Player),
        SpUsed = RaidPlayer2#raid_player.sp_used,
        {?ok, Player3}	= cost_sp(Player2, SpUsed),
		EndTime			= RaidPlayer#raid_player.end_time,
		EndTime2		= RaidPlayer2#raid_player.end_time,
		RealTime		= EndTime - EndTime2,
        CashUsed 		= calc_quick_cost(Player3, RealTime),
%%      CashUsed = RaidPlayer2#raid_player.cash_used, % XXX
        player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, CashUsed, ?CONST_COST_COPY_RAID_QUICK),	
		
        {?ok, Player5} = player_api:exp(Player3, Exp2),
        {?ok, Player6} = player_api:plus_meritorious(Player5, Meritorious2, ?CONST_COST_COPY_RAID_QUICK),
        
        player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind2, ?CONST_COST_COPY_RAID_QUICK),
        
        CopyId = RaidPlayer2#raid_player.copy_id,
        PacketExt = 
            if
                RaidPlayer2#raid_player.round =< 0 -> % 已经全部扫荡完
                    copy_single_api:msg_sc_raid_info(0, CopyId, 0);
                ?true ->
                    Bag2 = Player6#player.bag,
                    {?ok, BagCount} = ctn_bag2_api:empty_count(Bag2),
                    if
                        BagCount =< 0 -> % 背包空间不足
                            PacketBagErr = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                            PacketRaidInfo = copy_single_api:msg_sc_raid_info(0, CopyId, 0),
                            <<PacketBagErr/binary, PacketRaidInfo/binary>>;
                        ?true ->
                            RaidPlayer3 = RaidPlayer2#raid_player{sp_used = 0, cash_used = 0},
                            insert_raid(RaidPlayer3),
                            
                            Now2 = misc:seconds(),
                            EndTimeNow = RaidPlayer2#raid_player.end_time,
                            Time2 = EndTimeNow - Now2,
                            CopyId = RaidPlayer2#raid_player.copy_id,
                            Times = RaidPlayer2#raid_player.round,
                            copy_single_api:msg_sc_raid_info(Time2, CopyId, Times)
                    end
            end,
        misc_packet:send(UserId, <<PacketBag/binary, PacketExt/binary>>),
        {?ok, Player6}
    catch
        throw:Msg ->
            Msg;
        T:R ->
            ?MSG_ERROR("Type = ~p, Why = ~p, Stacktrace = ~p", [T, R, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end.

cost_sp(Player, SpUsed) ->
    case player_api:minus_sp(Player, SpUsed, ?CONST_COST_COPY_SP) of
        {?ok, Player2} ->
            {?ok, Player2};
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 下一个进度
next(RaidPlayer, Time, UserId, PacketBag, Exp, GoldBind, Meritorious, Player) 
  when Time > 0 andalso RaidPlayer#raid_player.wave < RaidPlayer#raid_player.wave_size
       andalso RaidPlayer#raid_player.round > 0 -> % 没过轮
    WaveReward = RaidPlayer#raid_player.wave_reward,
    Wave = RaidPlayer#raid_player.wave,
    {ExpWave, MeritoriousWave, BGoldWave, GoodsDropIdWave} = erlang:element(Wave, WaveReward),
    
    Exp2 = Exp + ExpWave,
    GoldBind2 = GoldBind + BGoldWave,
    Meritorious2 = Meritorious + MeritoriousWave,
    GoodsList = goods_drop_api:goods_drop(GoodsDropIdWave),
    
    CopyId = RaidPlayer#raid_player.copy_id,
    CashUsed = RaidPlayer#raid_player.cash_used,
    SpUsed = RaidPlayer#raid_player.sp_used,
    Time2 = Time - ?CONST_COPY_SINGLE_TIME_A_WAVE,
    EndTime = RaidPlayer#raid_player.end_time,
    IsEvenWave = RaidPlayer#raid_player.is_even_wave,
    IsEvenWave2 = not IsEvenWave,
    SpUsed2     = SpUsed   + ?CONST_COPY_SINGLE_SP_A_WAVE,
    EndTime2    = erlang:max(0, EndTime  - ?CONST_COPY_SINGLE_TIME_A_WAVE),
    CashUsed2   = CashUsed + 3,
    
    RaidPlayer2 =
        if
            ?CONST_COPY_SINGLE_PROCESS_WAVE_1 =:= Wave -> % 第1波要扣体力
                if
                    ?true =:= IsEvenWave -> % 偶数波要扣元宝
                        update_raid_player(Wave+1, CashUsed2, SpUsed2, EndTime2, IsEvenWave2, RaidPlayer);
                    ?true ->
                        update_raid_player(Wave+1, CashUsed, SpUsed2, EndTime2, IsEvenWave2, RaidPlayer)
                end;
            ?true ->
                if
                    ?true =:= IsEvenWave -> % 偶数波要扣元宝
                        update_raid_player(Wave+1, CashUsed2, SpUsed, EndTime2, IsEvenWave2, RaidPlayer);
                    ?true ->
                        update_raid_player(Wave+1, CashUsed, SpUsed, EndTime2, IsEvenWave2, RaidPlayer)
                end
        end,
    % 更新任务
    {Player2, PacketTask} = update_battle_task(Player, CopyId, Wave, GoodsList, ExpWave, BGoldWave, MeritoriousWave, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
        
    case ctn_bag_api:put(Player2, GoodsList, ?CONST_COST_COPY_RAID_AWARD, 1, 1, 1, 1, 0, 1, [CopyId]) of
        {?ok, Player3, _, Packet} ->
            Bag2 = Player3#player.bag,
            {?ok, EmptyCount} = ctn_bag2_api:empty_count(Bag2),
            if
                EmptyCount =< 0 -> % 总空位不足
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketTask/binary>>,
                    {RaidPlayer2, Exp2, GoldBind2, Meritorious2, PacketBag2, Player3};
                ?true ->
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketTask/binary>>,
                    next(RaidPlayer2, Time2, UserId, PacketBag2, Exp2, GoldBind2, Meritorious2, Player3)
            end;
        {?error, _ErrorCode} ->
            {RaidPlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player2}
    end;    
next(RaidPlayer, Time, UserId, PacketBag, Exp, GoldBind, Meritorious, Player) when Time > 0
   andalso RaidPlayer#raid_player.round > 0 -> % 下一轮
    WaveReward  = RaidPlayer#raid_player.wave_reward,
    RoundReward = RaidPlayer#raid_player.round_reward,
    Wave        = RaidPlayer#raid_player.wave,
    Round       = RaidPlayer#raid_player.round,
    {ExpWave,  MeritoriousWave,  BGoldWave,  GoodsDropIdWave}  = erlang:element(Wave, WaveReward),
    {ExpRound, MeritoriousRound, BGoldRound, GoodsDropIdRound} = RoundReward,
    
    ExpAdd = ExpWave + ExpRound,
    BGoldAdd = BGoldWave + BGoldRound,
    MeritoriousAdd = MeritoriousWave + MeritoriousRound,
    
    Exp2           = Exp + ExpAdd,
    GoldBind2      = GoldBind + BGoldAdd,
    Meritorious2   = Meritorious + MeritoriousAdd,
    GoodsListWave  = goods_drop_api:goods_drop(GoodsDropIdWave),
    GoodsListRound = goods_drop_api:goods_drop(GoodsDropIdRound),
    GoodsList      = GoodsListWave ++ GoodsListRound,
    
    CopyId      = RaidPlayer#raid_player.copy_id,
    CashUsed    = RaidPlayer#raid_player.cash_used,
    Time2       = Time - ?CONST_COPY_SINGLE_TIME_A_WAVE,
    EndTime     = RaidPlayer#raid_player.end_time,
    IsEvenWave  = RaidPlayer#raid_player.is_even_wave,
    IsEvenWave2 = not IsEvenWave,
    EndTime2    = erlang:max(0, EndTime  - ?CONST_COPY_SINGLE_TIME_A_WAVE),
    CashUsed2   = CashUsed + 3,
    Round2      = Round -1,
    SpUsed      = RaidPlayer#raid_player.sp_used,
    SpUsed2     = SpUsed   + ?CONST_COPY_SINGLE_SP_A_WAVE,
    
    RaidPlayer2 =
        if
            ?CONST_COPY_SINGLE_PROCESS_WAVE_1 =:= Wave -> % 第1波要扣体力
                if
                    ?true =:= IsEvenWave -> % 偶数波要扣元宝
                        update_raid_player_round(Round2, CashUsed2, SpUsed2, EndTime2, IsEvenWave2, RaidPlayer);
                    ?true ->
                        update_raid_player_round(Round2, CashUsed, SpUsed2, EndTime2, IsEvenWave2, RaidPlayer)
                end;
            ?true ->
                if
                    ?true =:= IsEvenWave -> % 偶数波要扣元宝
                        update_raid_player_round(Round2, CashUsed2, SpUsed, EndTime2, IsEvenWave2, RaidPlayer);
                    ?true ->
                        update_raid_player_round(Round2, CashUsed, SpUsed, EndTime2, IsEvenWave2, RaidPlayer)
                end
        end,
    % 更新任务
    {Player2, PacketTask} = update_battle_task(Player, CopyId, Wave, GoodsListWave, ExpWave, BGoldWave, MeritoriousWave, RaidPlayer, ?CONST_SYS_FALSE, ?CONST_SYS_TRUE),
	PacketRound = send_award(?CONST_SYS_TRUE, GoodsListRound, ExpRound, BGoldRound, MeritoriousRound, RaidPlayer, ?CONST_SYS_TRUE, []),
    {?ok, Player3} = task_api:update_copy(Player2, CopyId, 0),
    % 增加活跃度
	{?ok, Player4} = schedule_api:add_guide_times(Player3, ?CONST_SCHEDULE_GUIDE_SINGLE_COPY),
	
    case ctn_bag_api:put(Player4, GoodsList, ?CONST_COST_COPY_RAID_AWARD, 1, 1, 1, 1, 0, 1, [CopyId]) of
        {?ok, Player5, _, Packet} ->
            Bag2 = Player5#player.bag,
            {?ok, EmptyCount} = ctn_bag2_api:empty_count(Bag2),
            if
                EmptyCount =< 0 -> % 总空位不足
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketTask/binary, PacketRound/binary>>,
                    {RaidPlayer2, Exp2, GoldBind2, Meritorious2, PacketBag2, Player5};
                ?true ->
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketTask/binary, PacketRound/binary>>,
                    next(RaidPlayer2, Time2, UserId, PacketBag2, Exp2, GoldBind2, Meritorious2, Player5)
            end;
        {?error, _ErrorCode} ->
            {RaidPlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player4}
    end;    
next(RaidPlayer, _Time, _UserId, PacketBag, Exp, GoldBind, Meritorious, Player) when RaidPlayer#raid_player.round =< 0 ->
    {RaidPlayer, Exp, GoldBind, Meritorious, PacketBag, Player};
next(RaidPlayer, _Time, _UserId, PacketBag, Exp, GoldBind, Meritorious, Player) ->
    {RaidPlayer, Exp, GoldBind, Meritorious, PacketBag, Player}.

update_raid_player(Wave, CashUsed, SpUsed, EndTime, IsEvenWave, RaidPlayer) ->
    RaidPlayer#raid_player{
                             wave      = Wave, cash_used = CashUsed,  
                             sp_used   = SpUsed,   
                             end_time  = EndTime,  is_even_wave = IsEvenWave
                          }.
update_raid_player_round(Round, CashUsed, SpUsed, EndTime, IsEvenWave, RaidPlayer) ->
    RaidPlayer#raid_player{
                             wave      = 1,        round        = Round,
                             cash_used = CashUsed, sp_used      = SpUsed,
                             end_time  = EndTime,  is_even_wave = IsEvenWave
                          }.

check_quick(_Player, ?null, _Seconds) ->
    throw({?error, ?TIP_COMMON_BAD_ARG});
check_quick(#player{user_id = UserId, info = Info} = Player, #raid_player{wave_size = Wave, end_time = EndTime}, Seconds) ->
    Sp       = calc_sp_cost(Seconds, Wave),
    Seconds2 = erlang:max(0, EndTime - misc:seconds()),
    Sp2      = calc_sp_cost(Seconds2, Wave),
    Sp3      = misc:min(Sp, Sp2),
    GoldBind = calc_quick_cost(Player, erlang:min(Seconds2, Seconds)),
    IsFitGoldBind = 
        case player_money_api:check_money(UserId, ?CONST_SYS_BCASH_FIRST, GoldBind) of
            {?error, _} ->
                ?false;
            {?ok, _, ?false} ->
                ?false;
            {?ok, _, ?true} ->
                ?true
        end,
    
    if
        Info#info.sp < Sp3 ->
            throw({?error, ?TIP_COMMON_SP_NOT_ENOUGH});
        ?false =:= IsFitGoldBind ->
            throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH});
        ?true ->
            ?ok
    end.
   
%% 消耗
%% 3元宝/5min
calc_quick_cost(Player, Seconds) when 0 < Seconds ->
	VipLv		= player_api:get_vip_lv(Player),
	case player_vip_api:can_raid_4_free(VipLv) of
		?CONST_SYS_FALSE ->
			Min = Seconds / 60,
			3 * misc:ceil(Min / 5);
		_ -> ?CONST_SYS_FALSE
	end;
calc_quick_cost(_, _) ->
    0.

%% 计算体力消耗
calc_sp_cost(Seconds, Size) when 0 < Seconds ->
    misc:floor(Seconds / (?CONST_COPY_SINGLE_TIME_A_WAVE * Size)) * ?CONST_COPY_SINGLE_SP_A_WAVE;
calc_sp_cost(_Seconds, _) ->
    0.

%%
%% Local Functions
%%
insert_raid(RaidPlayer) when is_record(RaidPlayer, raid_player) ->
    ets_api:insert(?CONST_ETS_RAID_PLAYER, RaidPlayer).

delete_raid(UserId) ->
    case ets_api:lookup(?CONST_ETS_RAID_PLAYER, UserId) of
        ?null ->
            ?ok;
        RaidPlayer ->
            if
                ?CONST_SYS_TRUE =:= RaidPlayer#raid_player.is_online -> 
                    ets_api:delete(?CONST_ETS_RAID_PLAYER, UserId);
                ?true ->
                    ?ok
            end
    end.

select_raid(UserId) ->
    ets_api:lookup(?CONST_ETS_RAID_PLAYER, UserId).
