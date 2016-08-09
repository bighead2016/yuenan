%%% 直接跳过战斗
-module(battle_skip_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.battle.hrl").
-include("record.copy_single.hrl").

%%
%% Exported Functions
%%
-export([login_packet/2, skip_battle/1, packet_over_bout/1, chk_can_skip/1, handle_skip/2]).

%%
%% API Functions
%%

%% 登录包
login_packet(Player, OldPacket) ->
    Info = Player#player.info,
    FreeSkipTimes = Info#info.free_skip_times,
    Packet = battle_api:msg_sc_skip_info(FreeSkipTimes, ?CONST_SYS_TRUE),
    {Player, <<OldPacket/binary, Packet/binary>>}.

%% 修改跳过战斗状态
skip_battle(Player) ->
    BattlePid = Player#player.battle_pid,
    UserId = Player#player.user_id,
    Info = Player#player.info,
    FreeSkipTimes = Info#info.free_skip_times,
    VipData = Info#info.vip,
    VipLv = VipData#vip.lv,
    IsFree = player_vip_api:is_free_skip(VipLv),
    CanSkip = Player#player.can_skip,
    IsSkiped = Player#player.is_skiped,
    IsOpenSys = player_sys_api:is_open_sys(UserId, ?CONST_MODULE_ZIDONGZHANDOU),
    IsInTeam = Player#player.team_id,
    IsCopyOk = 
        case Player#player.battle_type of
            ?CONST_BATTLE_SINGLE_COPY ->
                CopyData = Player#player.copy,
                CopyCur = CopyData#copy_data.copy_cur,
                CopyType = CopyCur#copy_cur.type,
                if
                    CopyType =:= 1 ->
                        copy_single_api:is_finish_task(CopyData, CopyCur#copy_cur.copy_id);
                    ?true ->
                        ?CONST_SYS_TRUE
                end;
            _ ->
                ?CONST_SYS_TRUE
        end,
    
    if
        ?false =:= IsOpenSys ->
            {?error, ?TIP_COMMON_NOT_OPENED_HANDLER};
        ?CONST_SYS_FALSE =:= CanSkip ->
            {?error, ?TIP_BATTLE_CANNOT_SKIP};
        ?CONST_SYS_TRUE =:= IsSkiped ->
            {?error, ?TIP_BATTLE_SKIPPED};
        ?CONST_SYS_FALSE =:= IsCopyOk ->
            {?error, ?TIP_BATTLE_CANNOT_SKIP};
        0 =/= IsInTeam ->
            {?error, ?TIP_BATTLE_CANNOT_SKIP};
        ?CONST_SYS_TRUE =/= IsFree andalso FreeSkipTimes =< 0 ->
            case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_BATTLE_SKIP_COST, ?CONST_COST_BATTLE_SKIP) of
                ?ok ->
                    battle_api:auto_battle(Player, ?CONST_SYS_TRUE),
                    battle_serv:skip_battle_cast(BattlePid, UserId),
                    {?ok, Player#player{is_skiped = ?CONST_SYS_TRUE}};
                {?error, _ErrorCode} ->
%%                     {?error, ErrorCode}
                    {?ok, Player}
            end;
        ?true ->
            battle_api:auto_battle(Player, ?CONST_SYS_TRUE),
            battle_serv:skip_battle_cast(BattlePid, UserId),
            {NewInfo, NewPacket} = 
                if
                    ?CONST_SYS_TRUE =/= IsFree andalso FreeSkipTimes > 0 ->
                        Info2 = Info#info{free_skip_times = FreeSkipTimes - 1},
                        Packet = battle_api:msg_sc_skip_info(FreeSkipTimes-1, ?CONST_SYS_TRUE),
                        {Info2, Packet};
                    ?true ->
                        {Info, <<>>}
                end,
            misc_packet:send(UserId, NewPacket),
            {?ok, Player#player{is_skiped = ?CONST_SYS_TRUE, info = NewInfo}}
    end.

packet_over_bout(#battle{} = Battle) ->
    % 跳过时发刷新包
    case Battle#battle.skip of
        ?false ->
            <<>>;
        ?true ->
            BattleType  = Battle#battle.type,
            Bout        = Battle#battle.bout,
            EnlargeRate = Battle#battle.enlarge_rate,
            UnitsLeft   = Battle#battle.units_left,
            UnitsRight  = Battle#battle.units_right,
            {_, DataL}  = refresh_unit_list(BattleType, Bout, EnlargeRate, ?CONST_BATTLE_UNITS_SIDE_LEFT, misc:to_list(UnitsLeft#units.units), [], []),
            {_, DataR}  = refresh_unit_list(BattleType, Bout, EnlargeRate, ?CONST_BATTLE_UNITS_SIDE_RIGHT, misc:to_list(UnitsRight#units.units), [], DataL),
            PacketRefresh = battle_api:msg_battle_refresh_bout(Battle#battle.id, Battle#battle.bout, DataR, ?CONST_SYS_TRUE),
            PacketRefresh
    end.

chk_can_skip(Type) ->
    CanSkipList = [?CONST_BATTLE_TOWER, ?CONST_BATTLE_SINGLE_COPY, ?CONST_BATTLE_COMMERCE, 
				   ?CONST_BATTLE_SINGLE_ARENA, ?CONST_BATTLE_HOME, ?CONST_BATTLE_CROSS_ARENA,
                   ?CONST_BATTLE_ENCROACH_GENERAL, ?CONST_BATTLE_ENCROACH_VETERAN],
    lists:member(Type, CanSkipList).

handle_skip(Player, Param) ->
    try
        UserId = Player#player.user_id,
        Info = Player#player.info,
        FreeSkipTimes = Info#info.free_skip_times,
        CanSkip = chk_can_skip(Param#param.battle_type),
        IsOpenSys = player_sys_api:is_open_sys(UserId, ?CONST_MODULE_SKIP_BATTLE),
        IsCopyOk = 
            case Param#param.battle_type of
                ?CONST_BATTLE_SINGLE_COPY ->
                    CopyData = Player#player.copy,
                    CopyCur  = CopyData#copy_data.copy_cur,
                    CopyType = CopyCur#copy_cur.type,
                    if
                        CopyType =:= 1 ->
                            copy_single_api:is_finish_task(CopyData, CopyCur#copy_cur.copy_id);
                        ?true ->
                            ?CONST_SYS_TRUE
                    end;
                _ ->
                    ?CONST_SYS_TRUE
            end,
        if
            (?CONST_SYS_FALSE =:= IsCopyOk andalso ?true =:= CanSkip) orelse ?false =:= CanSkip ->
                Packet = battle_api:msg_sc_skip_info(FreeSkipTimes, ?CONST_SYS_FALSE),
                misc_packet:send(UserId, Packet),
                Player#player{can_skip = ?CONST_SYS_FALSE, is_skiped = ?CONST_SYS_FALSE, battle_type = Param#param.battle_type};
            ?true ->
                if
                    ?true =:= IsOpenSys ->
                        IsShow = 
                            if
                                CanSkip =:= ?true -> 1;
                                ?true -> 0
                            end,
                        Packet = battle_api:msg_sc_skip_info(FreeSkipTimes, IsShow),
                        misc_packet:send(UserId, Packet),
                        Player#player{can_skip = ?CONST_SYS_TRUE, is_skiped = ?CONST_SYS_FALSE, battle_type = Param#param.battle_type};
                    ?true ->
                        Packet = battle_api:msg_sc_skip_info(FreeSkipTimes, ?CONST_SYS_FALSE),
                        misc_packet:send(UserId, Packet),
                        Player#player{can_skip = ?CONST_SYS_FALSE, is_skiped = ?CONST_SYS_FALSE, battle_type = Param#param.battle_type}
                end
        end
    catch
        _:_ ->
            Player#player{can_skip = ?CONST_SYS_FALSE, is_skiped = ?CONST_SYS_FALSE, battle_type = Param#param.battle_type}
    end.

%%
%% Local Functions
%%
refresh_unit_list(BattleType, Bout, EnlargeRate, Side, [Unit|UnitList], Acc, AccDatas) ->
    case refresh_unit(BattleType, Bout, EnlargeRate, Side, Unit) of
        {Unit2, Data} ->
            refresh_unit_list(BattleType, Bout, EnlargeRate, Side, UnitList, [Unit2|Acc], [Data|AccDatas]);
        _ -> refresh_unit_list(BattleType, Bout, EnlargeRate, Side, UnitList, [Unit|Acc], AccDatas)
    end;
refresh_unit_list(_BattleType, _Bout, _EnlargeRate, _Side, [], Acc, AccDatas) ->
    UnitsTuple  = misc:to_tuple(lists:reverse(Acc)),
    {UnitsTuple, AccDatas}.

refresh_unit(_BattleType, _Bout, _EnlargeRate, Side, Unit)
  when is_record(Unit, unit) andalso Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
    Attr        = Unit#unit.attr,
    HpMax       = (Attr#attr.attr_second)#attr_second.hp_max,
    Hp          = Unit#unit.hp,
    Data        = {Side, Unit#unit.idx, 0, Hp, HpMax, Unit#unit.anger, []},
    {Unit, Data};
refresh_unit(_BattleType, _Bout, _EnlargeRate, Side, Unit)
  when is_record(Unit, unit) ->
    Attr        = Unit#unit.attr,
    HpMax       = (Attr#attr.attr_second)#attr_second.hp_max,
    Data        = {Side, Unit#unit.idx, 0, 0, HpMax, 0, []},
    {Unit, Data};
refresh_unit(_BattleType, _Bout, _EnlargeRate, _Side, Unit) -> Unit.


