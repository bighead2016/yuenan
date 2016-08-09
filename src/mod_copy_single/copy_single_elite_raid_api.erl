%% 精英副本扫荡
-module(copy_single_elite_raid_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.map.hrl").
-include("record.player.hrl").
-include("record.copy_single.hrl").


%%
%% Exported Functions
%%
-export([get_info/2, start_raid/2, update_raid_elite_cb/2, flush_offline/2, quick/2,
         update_raid/0, update_raid_elite_offline/2, get_end_time/1, stop_raid/1,
         change_offline/1, change_online/1]).

%%
%% API Functions
%%
%% 读取精英副本扫荡信息
%% {?ok, Packet}/{?error, ErrorCode, PacketError}
get_info(Player, SerialId) ->
    case check_raid(Player, SerialId) of
        {?ok, List} ->
            TotalTime = calc_raid_time(List),
            Packet    = copy_single_api:msg_sc_elite_info(TotalTime, List, ?CONST_SYS_FALSE, SerialId),
            {?ok, Packet};
        {?error, ErrorCode} ->
            Packet      = copy_single_api:msg_sc_elite_info(0, [], ?CONST_SYS_FALSE, 0),
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, <<Packet/binary, PacketError/binary>>}
    end.

%% 每波怪扫荡
%% {?ok, PacketStart}/{?error, ErrorCode, PacketError}
start_raid(Player, SerialId) ->
    case check_raid(Player, SerialId) of
        {?ok, List} ->
            {?ok, PacketStart} = do_raid(Player, List, SerialId),
            {?ok, PacketStart};
        {?error, ErrorCode} ->
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError}
    end.

check_raid(Player, SerialId) ->
    try
        case player_api:is_gm(Player) of
            ?true ->
                List = get_raid_list(Player, SerialId, ?true),
                {?ok, List};
            _ ->
                Bag = ctn_bag2_api:get_bag(Player),
                ?ok = is_bag_full(Bag),
                List = get_raid_list(Player, SerialId, ?false),
                {?ok, List}
        end
    catch
        throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        _:_ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.
    
is_bag_full(Bag) ->
    case ctn_bag2_api:is_full(Bag) of
        ?false ->
            ?ok;
        ?true ->
            throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
    end.

get_raid_list(Player, SerialId, IsGM) ->
    case data_copy_single:get_serial_list(SerialId) of
        List when is_list(List) andalso [] =/= List ->
            CopyData = Player#player.copy,
            F = fun(CopyId, OldList) ->
                    case copy_single_api:is_first(CopyData, CopyId) of
                        ?true ->
                            OldList;
                        ?false when ?true =:= IsGM -> % gm无限次
                            [CopyId|OldList];
                        ?false ->
                            case check_enter_copy_count(CopyId, 1, CopyData) of
                                ?true ->
                                    [CopyId|OldList];
                                ?false ->
                                    OldList
                            end
                    end
                end,
            List2 = lists:foldl(F, [], List),
            if
                [] =/= List2 ->
                    List2;
                ?true ->
                    throw({?error, ?TIP_COPY_SINGLE_NO_CAN_RAID})
            end;
        ?null ->
            throw({?error, ?TIP_COPY_SINGLE_NO_CAN_RAID})
    end.

%% {?ok, PacketStart}
do_raid(Player, List, SerialId) ->
    F = fun(CopyId, OldRaidList) ->
            case get_mons(CopyId, Player) of
                {MonsList, RewardMonster, RewardPass, MapId} when is_list(MonsList) ->
                    RaidElite = record_raid_elite(CopyId, MapId, MonsList, RewardMonster, RewardPass),
                    [RaidElite|OldRaidList];
                _ ->
                    OldRaidList
            end
        end,
    RaidList = lists:foldl(F, [], List),
    TotalRound = erlang:length(RaidList),
    Now = misc:seconds(),
    NextSkip = Now + ?CONST_ELITECOPY_WAVE_TIME,
%%     NextSkip = Now + 1,
    Time = calc_raid_time(TotalRound),
    EndTime = Now + Time,
    UserId = Player#player.user_id,
    RaidElitePlayer = record_raid_elite_player(UserId, SerialId, RaidList, TotalRound, TotalRound, NextSkip, EndTime, List),
    insert_elite_raid(RaidElitePlayer),
    % 成就 
    achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_CLEARANCE, 0, 1),
    
    PacketStart = copy_single_api:msg_sc_start_elite(SerialId, Time),
    {?ok, PacketStart}.

%% 扫荡时间
calc_raid_time(List) when is_list(List) -> 
    Len = erlang:length(List),
    calc_raid_time(Len);
calc_raid_time(Round) -> Round * ?CONST_ELITECOPY_WAVE_TIME.

record_raid_elite(CopyId, MapId, MonsList, RewardMonster, RewardPass) ->
    #raid_elite{
                copy_id     = CopyId,   map_id         = MapId,
                mons_list   = MonsList, reward_monster = RewardMonster,
                reward_pass = RewardPass
               }.

record_raid_elite_player(UserId, SerialId, CopyList, Round, TotalRound, NextSkip, EndTime, CopyIdList) ->
    #raid_elite_player{
                       copy_list = CopyList, round       = Round, 
                       serial_id = SerialId, total_round = TotalRound,
                       next_skip = NextSkip, user_id     = UserId,
                       end_time  = EndTime,  is_even_wave = ?true,
                       cash_used = 0,        total_copy_list = CopyIdList,
                       is_online = ?CONST_SYS_TRUE
                      }.

%% 检查副本进入次数
check_enter_copy_count(CopyId, DailyCount, CopyData) ->
    CopyBag = CopyData#copy_data.copy_bag,
    case copy_bag_api:search(CopyId, CopyBag) of
        #copy_one{daily_times = Times} when Times < DailyCount ->
            ?true;
        _ ->
            ?false
    end.

%% 读取扫荡的怪物信息
%% {MonsList, Reward, RoundReward, MapId}/{?null, get_default_reward(), _, _}
get_mons(CopyId, Player) when is_number(CopyId), is_record(Player, player) ->
    CopyData      = Player#player.copy,
    IsFinished    = copy_single_api:is_finish_task(CopyData, CopyId),
    RecCopySingle = copy_single_api:read(CopyId),
    {MonsList, Reward} = get_mons(Player, RecCopySingle, IsFinished),
    RoundReward   = get_round_base_reward(Player, RecCopySingle),
    MapId         = get_map_id(RecCopySingle),
    {MonsList, Reward, RoundReward, MapId};
get_mons(?null, _) -> {?null, get_default_reward()}.

get_mons(Player, RecCopySingle, ?CONST_SYS_FALSE) ->
    MonsterTuple = RecCopySingle#rec_copy_single.monster,
    get_mon_tuple(Player, MonsterTuple);
get_mons(Player, RecCopySingle, ?CONST_SYS_TRUE) ->
    MonsterTuple = RecCopySingle#rec_copy_single.monster2,
    get_mon_tuple(Player, MonsterTuple).

%% 读取怪物信息
get_mon_tuple(Player, {{MonId, _}}) ->
    case monster_api:monster(MonId) of
        Monster when is_record(Monster, monster) ->
            List           = get_mon_list(Monster),
            Reward         = get_mon_reward(Player, Monster),
            {List, Reward};
        ?null ->
            Reward         = get_default_reward(),
            {?null, Reward}
    end.

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
get_mon_reward(Player, Monster) ->
    Exp         = Monster#monster.hook_exp*2,
    Rate       = guild_api:get_exp_add(Player),
    Info       = Player#player.info,
    RankRate   = rank_api:get_rank_rate(Info#info.lv),
    AwardExp2  = round(Exp * Rate + Exp * RankRate),
    Meritorious = Monster#monster.meritorious,
    Gold        = Monster#monster.gold,
    DropId      = Monster#monster.drop_id,
    {AwardExp2, Meritorious, Gold, DropId}.

%% 默认怪物奖励
get_default_reward() ->
    erlang:make_tuple(4, 0).

%% 读取地图id
get_map_id(RecCopySingle) when is_record(RecCopySingle, rec_copy_single) ->
    RecCopySingle#rec_copy_single.map;
get_map_id(?null) -> 0.

%% 每轮奖励
%% {AwardExp, AwardMeritorious, AwardGold, GoodsDropId}
get_round_base_reward(_, ?null) -> get_default_reward();
get_round_base_reward(Player, RecCopySingle) ->
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
    RaidList = ets_api:list(?CONST_ETS_RAID_ELITE_PLAYER),
    Now = misc:seconds(),
    F = fun(RaidElitePlayer = #raid_elite_player{next_skip = NextSkip, round = Round}) 
             when 0 < Round andalso NextSkip =< Now ->
                UserId     = RaidElitePlayer#raid_elite_player.user_id,
                [RaidElite|NewCopyList] = RaidElitePlayer#raid_elite_player.copy_list,
                do_update(UserId, ?MODULE, update_raid_elite_cb, [RaidElite]),
                NewNextSkip   = NextSkip + ?CONST_ELITECOPY_WAVE_TIME,
                NewRaidElitePlayer = RaidElitePlayer#raid_elite_player{next_skip = NewNextSkip, round = Round - 1, copy_list = NewCopyList},
                insert_elite_raid(NewRaidElitePlayer);
           (#raid_elite_player{next_skip = NextSkip, round = Round}) 
             when 0 < Round andalso NextSkip > Now ->
                ?ignore;
           (#raid_elite_player{user_id = UserId, round = 0}) ->
                delete_elite_raid(UserId)
        end,
    lists:foreach(F, RaidList).

%% 更新回调
do_update(UserId, Module, Func, Arg) ->
    case player_api:process_send(UserId, Module, Func, Arg) of
        ?true -> ?ok; % 在线
        ?false -> player_offline_api:offline(Module, UserId, {update_raid_elite_offline, Arg}) % 离线
    end.

%% 再上线时处理
flush_offline(Player, {Func, Arg}) ->
    Bag = Player#player.bag,
    {?ok, Player2} = 
        case ctn_bag2_api:empty_count(Bag) of
            {?ok, 0} ->
                {?ok, Player};
            _ ->
                ?MODULE:Func(Player, Arg)
        end,
    {?ok, Player2}.

change_offline(UserId) ->
    case select_elite_raid(UserId) of
        ?null ->
            ?ok;
        RaidElitePlayer ->
            insert_elite_raid(RaidElitePlayer#raid_elite_player{is_online = ?CONST_SYS_FALSE})
    end.

change_online(UserId) ->
    case select_elite_raid(UserId) of
        ?null ->
            ?ok;
        RaidElitePlayer ->
            insert_elite_raid(RaidElitePlayer#raid_elite_player{is_online = ?CONST_SYS_TRUE})
    end.

%% 上线时扫荡时间
get_end_time(UserId) ->
    RaidElitePlayer = select_elite_raid(UserId),
    if
        RaidElitePlayer =:= ?null ->
            <<>>;
        ?true ->
            SerialId = RaidElitePlayer#raid_elite_player.serial_id,
            CopyIdList = RaidElitePlayer#raid_elite_player.total_copy_list,
            CopyList = RaidElitePlayer#raid_elite_player.copy_list,
            if
                [] =:= CopyList ->
                    change_online(UserId),
                    delete_elite_raid(UserId),
                    copy_single_api:msg_sc_elite_info(0, CopyIdList, ?CONST_SYS_TRUE, SerialId);
                ?true ->
                    Now = misc:seconds(),
                    EndTime = RaidElitePlayer#raid_elite_player.end_time,
                    TimeDelta = EndTime - Now,
                    copy_single_api:msg_sc_elite_info(TimeDelta, CopyIdList, ?CONST_SYS_TRUE, SerialId)
            end
    end.

update_raid_elite_offline(Player, [RaidElite]) -> %
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_raid_reward(Player, RaidElite),
    {Player3, Packet} = update_battle_task(Player2, RaidElite#raid_elite.copy_id, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
                          MeritoriousDisplay, RaidElite),
    {?ok, Player4} = task_api:update_copy(Player3, RaidElite#raid_elite.copy_id, ?CONST_TASK_NOTE_ELITE_COPY),
    OfflinePacket = Player4#player.offline_packet,
    OfflinePacket2 = <<OfflinePacket/binary, Packet/binary>>,
    Player5 = Player4#player{offline_packet = OfflinePacket2},
    {?ok, Player5}.

%% 
update_raid_elite_cb(Player, [RaidElite]) -> %
    {Player2, ExpDisplay, BGoldDisplay, MeritoriousDisplay, GoodsListDisplay}    
        = get_raid_reward(Player, RaidElite),
	
    {Player3, Packet} = update_battle_task(Player2, RaidElite#raid_elite.copy_id, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
                          MeritoriousDisplay, RaidElite),
    {?ok, Player4} = task_api:update_copy(Player3, RaidElite#raid_elite.copy_id, ?CONST_TASK_NOTE_ELITE_COPY),
	
	%% 元宝自动翻牌处理
	{Player6, AutoPacket}	= copy_single_api:auto_turn_card_reward(Player4, RaidElite),
	
	NetPid = Player#player.net_pid,
    misc_packet:send(NetPid, <<Packet/binary, AutoPacket/binary>>),
    {?ok, Player6}.

get_raid_reward(Player, RaidElite) ->
    {Player4, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}    
                = get_round_reward(Player, RaidElite),
    {Player4, ExpDisplay2, BGoldDisplay2, MeritoriousDisplay2, GoodsListDisplay2}.

%% 读取每轮怪奖励
get_round_reward(Player, RaidElite) ->
    {ExpMonster, MeritoriousMonster, BGoldMonster, GoodsDropIdMonster} = RaidElite#raid_elite.reward_monster, 
    {ExpRound, MeritoriousRound, BGoldRound, GoodsDropIdRound} = RaidElite#raid_elite.reward_pass, 
    UserId = Player#player.user_id,
    
    % 经验
    ExpTotal = ExpRound + ExpMonster,
    {?ok, Player2} = player_api:exp(Player, ExpTotal),
    
    % 铜钱
    BGoldTotal = BGoldRound + BGoldMonster,
    award_gold_bind(UserId, BGoldTotal),
    
    % 军功
    MeritoriousTotal = MeritoriousRound + MeritoriousMonster,
    {?ok, Player3}	 = player_api:plus_meritorious(Player2, MeritoriousTotal, ?CONST_COST_COPY_ELITE_AWARD),

    % 道具
    GoodsListRound   = goods_drop_api:goods_drop(GoodsDropIdRound),
    GoodsListMonster = goods_drop_api:goods_drop(GoodsDropIdMonster),
    GoodsListTotal   = GoodsListRound ++ GoodsListMonster,
    Player4 = award_goods(Player3, GoodsListTotal, RaidElite#raid_elite.copy_id),
    {Player4, ExpTotal, BGoldTotal, MeritoriousTotal, GoodsListTotal}.

%% 前端显示
%% Packet
send_award(GoodsListDisplay, ExpDisplay, BGoldDisplay, MeritoriousDisplay, CopyId, MonsterList) ->
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
    copy_single_api:msg_sc_elite_result(GoodsList, ExpDisplay, BGoldDisplay, 
                                                MeritoriousDisplay, CopyId, 
                                                MonsterList).

%% 更新任务 -- 扫荡杀怪
%% #player{}
update_battle_task(Player, CopyId, GoodsListDisplay, ExpDisplay, BGoldDisplay, 
            MeritoriousDisplay, RaidElite) ->
    MonsList = RaidElite#raid_elite.mons_list,
    MapId = RaidElite#raid_elite.map_id,
    MonsterList = sum_up(MonsList, []),
    Packet = send_award(GoodsListDisplay, ExpDisplay, BGoldDisplay, 
                       MeritoriousDisplay, CopyId, MonsterList),
    {?ok, Player2} = task_api:update_battle(Player, MapId, MonsList, ?CONST_BATTLE_RESULT_LEFT, []),
    {Player2, Packet}.

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
                                ?CONST_SYS_GOLD_BIND, GoldBind,?CONST_COST_COPY_ELITE_AWARD); 
award_gold_bind(_UserId, _GoldBind) ->
    ?ok.

%% 奖励道具
award_goods(Player, GoodsListTotal, CopyId) ->
    case ctn_bag_api:put(Player, GoodsListTotal, ?CONST_COST_COPY_ELITE_AWARD, 1, 1, 0, 0, 1, 1, [CopyId]) of
        {?ok, Player2, _, _PacketBag} ->
            Player2;
        {?error, _ErrorCode} ->
            stop_raid(Player#player.user_id),
            Player
    end.
    
%% 停止扫荡
stop_raid(UserId) ->
    delete_elite_raid(UserId),
    Packet = copy_single_api:msg_sc_raid_info(0, 0, 0),
    misc_packet:send(UserId, Packet).

%% 快速完成
quick(Player, ?CONST_COPY_SINGLE_QUICK_30) -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_30);
quick(Player, ?CONST_COPY_SINGLE_QUICK_60) -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_60);
quick(Player, ?CONST_COPY_SINGLE_QUICK_0)  -> quick_2(Player, ?CONST_COPY_SINGLE_QUICK_TIME_0).

%% 加速Time秒
quick_2(Player, 0) ->
	try
	    UserId = Player#player.user_id,
	    Now = misc:seconds(),
	    RaidElitePlayer = select_elite_raid(UserId),
	    EndTime = RaidElitePlayer#raid_elite_player.end_time,
	    Time = EndTime - Now,
	    quick_2(Player, Time)
	catch
        throw:Msg -> Msg;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end;
	 
quick_2(Player, Time) ->
	VipLv			= player_api:get_vip_lv(Player),
    UserId 			= Player#player.user_id,
    RaidElitePlayer = select_elite_raid(UserId),
    ?ok 			= check_quick(Player, RaidElitePlayer, Time),
    delete_elite_raid(UserId),
    {RaidElitePlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player2} 
        			= next(RaidElitePlayer, Time, UserId, <<>>, 0, 0, 0, Player),
    CashUsed 		= case player_vip_api:can_raid_4_free(VipLv) of
						?CONST_SYS_FALSE ->
							RaidElitePlayer2#raid_elite_player.cash_used;
						_ -> ?CONST_SYS_FALSE
					  end,
    player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, CashUsed, ?CONST_COST_COPY_ELITE_QUICK),
    {?ok, Player3}	= player_api:exp(Player2, Exp2),
    {?ok, Player4}	= player_api:plus_meritorious(Player3, Meritorious2, ?CONST_COST_COPY_ELITE_QUICK),
	% 增加活跃度
	{?ok, Player5} = schedule_api:add_guide_times(Player4, ?CONST_SCHEDULE_GUIDE_ELITE_COPY),
    catch gun_award_api:check_active(UserId, ?CONST_SCHEDULE_RESOURCE_HERO),
    player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind2, ?CONST_COST_COPY_ELITE_QUICK),
    
    PacketExt		= 
        if
            RaidElitePlayer2#raid_elite_player.round =< 0 -> % 已经全部扫荡完
                SerialId = RaidElitePlayer2#raid_elite_player.serial_id,
                copy_single_api:msg_sc_start_elite(SerialId, 0);
            ?true -> 
                SerialId = RaidElitePlayer2#raid_elite_player.serial_id,
                {?ok, BagCount} = ctn_bag2_api:empty_count(Player5#player.bag),
                if
                    BagCount =< 0 -> % 背包空间不足
                        PacketBagErr = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                        PacketRaidInfo = copy_single_api:msg_sc_start_elite(SerialId, 0),
                        <<PacketBagErr/binary, PacketRaidInfo/binary>>;
                    ?true -> % 正常继续
                        RaidElitePlayer3 = RaidElitePlayer2#raid_elite_player{cash_used = 0},
                        insert_elite_raid(RaidElitePlayer3),
                        Now2 = misc:seconds(),
                        EndTimeNow = RaidElitePlayer2#raid_elite_player.end_time,
                        Time2 = EndTimeNow - Now2,
                        copy_single_api:msg_sc_start_elite(SerialId, Time2)
                end
        end,
    misc_packet:send(UserId, <<PacketBag/binary, PacketExt/binary>>),
    {?ok, Player5}.
    

%% 下一个进度
next(RaidElitePlayer, Time, UserId, PacketBag, Exp, GoldBind, Meritorious, Player) when Time > 0
   andalso RaidElitePlayer#raid_elite_player.round > 0 -> % 下一轮
    [RaidElite|Tail] = RaidElitePlayer#raid_elite_player.copy_list,
    {ExpMonster, MeritoriousMonster, BGoldMonster, GoodsDropIdMonster} = RaidElite#raid_elite.reward_monster, 
    {ExpRound, MeritoriousRound, BGoldRound, GoodsDropIdRound} = RaidElite#raid_elite.reward_pass, 
    
    ExpAdd         = ExpMonster + ExpRound,
    BGoldAdd       = BGoldMonster + BGoldRound,
    MeritoriousAdd = MeritoriousMonster + MeritoriousRound,
    
    Exp2           = Exp + ExpAdd,
    GoldBind2      = GoldBind + BGoldAdd,
    Meritorious2   = Meritorious + MeritoriousAdd,
    GoodsListMonster  = goods_drop_api:goods_drop(GoodsDropIdMonster),
    GoodsListRound = goods_drop_api:goods_drop(GoodsDropIdRound),
    GoodsList      = GoodsListMonster ++ GoodsListRound,
    
    CopyId      = RaidElite#raid_elite.copy_id,
    Time2       = Time - ?CONST_ELITECOPY_WAVE_TIME,
    IsEvenWave  = RaidElitePlayer#raid_elite_player.is_even_wave,
    IsEvenWave2 = not IsEvenWave,
    EndTime     = RaidElitePlayer#raid_elite_player.end_time,
    EndTime2    = EndTime - ?CONST_ELITECOPY_WAVE_TIME,
    CashUsed    = RaidElitePlayer#raid_elite_player.cash_used,
    CashUsed2   = CashUsed + 3,
    Round       = RaidElitePlayer#raid_elite_player.round,
    Round2      = Round - 1,
    
    {?ok, EmptyCount} = ctn_bag2_api:empty_count(Player#player.bag),
    Len = erlang:length(GoodsList),
    
    % 更新任务
    {Player2, MonsterList} = update_battle_task(Player, RaidElitePlayer),
    {?ok, Player3} = task_api:update_copy(Player2, CopyId, ?CONST_TASK_NOTE_ELITE_COPY),
   
    RaidElitePlayer2 = 
        if
            ?true =:= IsEvenWave -> % 偶数波要扣元宝
                update_elite_player_round(Round2, CashUsed2, EndTime2, IsEvenWave2, Tail, RaidElitePlayer);
            ?true ->
                update_elite_player_round(Round2, CashUsed, EndTime2, IsEvenWave2, Tail, RaidElitePlayer)
        end,
    if
        EmptyCount < Len -> % 总空位不足
            case ctn_bag_api:put(Player3, GoodsList, ?CONST_COST_COPY_ELITE_RAID_GET, 1, 1, 1, 0, 0, 1, [CopyId]) of
                {?ok, Player3_2, GoodsListAdd2, Packet} ->
                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_COPY_ELITE_RAID_GET, GoodsList, misc:seconds(),
                                            CopyId, 0, 0, 0, 0, 0),
                    PacketMsg  = send_award(GoodsListAdd2, ExpAdd, BGoldAdd, MeritoriousAdd, CopyId, MonsterList),
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketMsg/binary>>,
                    {RaidElitePlayer2, Exp2, GoldBind2, Meritorious2, PacketBag2, Player3_2};
                {?error, _ErrorCode} ->
                    {RaidElitePlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player3}
            end;
        ?true ->
            case ctn_bag_api:put(Player3, GoodsList, ?CONST_COST_COPY_RAID_AWARD, 1, 1, 1, 0, 0, 1, []) of
                {?ok, Player4, _, Packet} ->
					%% 元宝自动翻牌处理
					{Player5, AutoPacket}	= copy_single_api:auto_turn_card_reward(Player4, RaidElite),
                    PacketMsg  = send_award(GoodsList, ExpAdd, BGoldAdd, MeritoriousAdd, CopyId, MonsterList),
                    PacketBag2 = <<PacketBag/binary, Packet/binary, PacketMsg/binary, AutoPacket/binary>>,
                    next(RaidElitePlayer2, Time2, UserId, PacketBag2, Exp2, GoldBind2, Meritorious2, Player5);
                {?error, _ErrorCode} ->
                    {RaidElitePlayer2, Exp2, GoldBind2, Meritorious2, PacketBag, Player3}
            end
    end;
next(RaidPlayer, _Time, _UserId, PacketBag, Exp, GoldBind, Meritorious, Player) when RaidPlayer#raid_player.round =< 0 ->
    {RaidPlayer, Exp, GoldBind, Meritorious, PacketBag, Player};
next(RaidPlayer, _Time, _UserId, PacketBag, Exp, GoldBind, Meritorious, Player) ->
    {RaidPlayer, Exp, GoldBind, Meritorious, PacketBag, Player}.

update_elite_player_round(Round, CashUsed, EndTime, IsEvenWave, CopyList, RaidElitePlayer) ->
    RaidElitePlayer#raid_elite_player{
                                        cash_used = CashUsed,
                                        copy_list = CopyList,
                                        end_time  = EndTime,
                                        is_even_wave = IsEvenWave,
                                        round = Round
                                     }.

update_battle_task(Player, #raid_elite_player{copy_list = []}) ->
    {Player, []};
update_battle_task(Player, RaidPlayer) ->
    [#raid_elite{map_id = MapId, mons_list = MonList}|_Tail] = RaidPlayer#raid_elite_player.copy_list, 
    MonsterList3 = sum_up(MonList, []),
    {?ok, Player2} = task_api:update_battle(Player, MapId, MonList, ?CONST_BATTLE_RESULT_LEFT, []),
    {Player2, MonsterList3}.

check_quick(_Player, ?null, _Seconds) ->
    throw({?error, ?TIP_COMMON_BAD_ARG});
check_quick(Player, RaidElitePlayer, Seconds) ->
    Now      = misc:seconds(),
    Seconds2 = RaidElitePlayer#raid_elite_player.end_time - Now,
    UserId   = Player#player.user_id,
    GoldBind = calc_quick_cost(Seconds),
    GoldBind2 = calc_quick_cost(Seconds2),
    GoldBind3 = misc:min(GoldBind, GoldBind2),
	VipLv	  = player_api:get_vip_lv(Player),
	VipFlag	  = player_vip_api:can_raid_4_free(VipLv),
    IsFitGoldBind = 
        case player_money_api:check_money(UserId, ?CONST_SYS_BCASH_FIRST, GoldBind3) of
            {?error, _} ->
                ?false;
            {?ok, _, ?false} ->
                ?false;
            {?ok, _, ?true} ->
                ?true
        end,
    
    if
        {IsFitGoldBind, VipFlag} =:= {?false, ?CONST_SYS_FALSE} ->
            throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH});
        ?true ->
            ?ok
    end.
   
%% 消耗
%% 3元宝/5min
calc_quick_cost(Seconds) when 0 < Seconds ->
    Min = Seconds / 60,
    3 * misc:ceil(Min / 5);
calc_quick_cost(_) ->
    0.

%%
%% Local Functions
%%
insert_elite_raid(RaidElitePlayer) when is_record(RaidElitePlayer, raid_elite_player) ->
    ets_api:insert(?CONST_ETS_RAID_ELITE_PLAYER, RaidElitePlayer).

delete_elite_raid(UserId) ->
    case ets_api:lookup(?CONST_ETS_RAID_ELITE_PLAYER, UserId) of
        ?null ->
            ?ok;
        _ ->
            ets_api:delete(?CONST_ETS_RAID_ELITE_PLAYER, UserId)
    end.

select_elite_raid(UserId) ->
    ets_api:lookup(?CONST_ETS_RAID_ELITE_PLAYER, UserId).