%% Author: zero
%% Created: 2013-1-25
%% Description: TODO: Add description to ai_data_analyzer
-module(ai_data_analyzer).

%%
%% Include files
%%
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([analyze/1]).
-define(LOG(F, D), 
            io:format("[~p]"++F++"~n", [?LINE]++D)).

%%
%% API Functions
%%
analyze(_Ver) ->
    AiIdList  = data_ai:get_ai_list(),
    AiList = [data_ai:get_base_ai(AiId)||AiId <- AiIdList],
    check_ai(AiList),
    check_next(AiList),
    ok.

check_ai([RecAi|Tail]) when is_record(RecAi, rec_ai) ->
    AiId = RecAi#rec_ai.id,
    Type = RecAi#rec_ai.type,
    TargetSide = RecAi#rec_ai.target_side,
    TargetUnit1 = RecAi#rec_ai.target_units_1,
    TargetUnit2 = RecAi#rec_ai.target_units_2,
    Value = RecAi#rec_ai.value,
    ValueType = RecAi#rec_ai.value_type,
    AttrType = RecAi#rec_ai.attr_type,
    IsStop = RecAi#rec_ai.is_stop,
    AiStart = RecAi#rec_ai.ai_start,
    check_type(AiId, Type, TargetSide, TargetUnit1, TargetUnit2, Value, ValueType, AttrType, IsStop),
    
    Trigger = RecAi#rec_ai.trigger,
    ConSide = RecAi#rec_ai.con_side,
    ConSide1 = RecAi#rec_ai.con_units_1,
    ConSide2 = RecAi#rec_ai.con_units_2,
    check_condition(AiId, Trigger, AiStart, ConSide, ConSide1, ConSide2),
    check_ai(Tail);
check_ai([]) ->
    ok.

check_type(AiId, _, _, _, _, _, _, _, _) when AiId < 1000 ->
    true;
%% ai类型--冒泡说话           1   CONST_AI_TYPE_TALK
check_type(AiId, ?CONST_AI_TYPE_TALK, Side, TargetUnit1, TargetUnit2, _, ValueType, AttrType, _) ->
    case Side of
        1 ->
            check_target(AiId, 1, TargetUnit1),
            check_type(AiId, TargetUnit2, tu2, {list, empty});
        2 ->
            check_target(AiId, 2, TargetUnit2),
            check_type(AiId, TargetUnit1, tu1, {list, empty});
        X ->
            ?LOG("!err[no this side]:ai=~p, side=~p", [AiId, X])
    end,
    check_type(AiId, ValueType, value_type, {integer, eq, 0}),
    check_type(AiId, AttrType, attr_type, {integer, eq, 0}),
    true;
%% ai类型--播放动画           2   CONST_AI_TYPE_PLAY_CARTOON
check_type(_AiId, ?CONST_AI_TYPE_PLAY_CARTOON, _, _, _, _, _, _, _) ->
    true;
%% ai类型--buff增加删除       3   CONST_AI_TYPE_BUFF
check_type(_AiId, ?CONST_AI_TYPE_BUFF, _, _, _, _, _, _, _) ->
    true;
%% ai类型--战斗初始加入     4   CONST_AI_TYPE_INIT_JOIN
check_type(AiId, ?CONST_AI_TYPE_INIT_JOIN, 1, TargetUnit1, [], 0, 0, 0, _) ->
    check_target(AiId, 1, TargetUnit1);
%% ai类型--单位加入           5   CONST_AI_TYPE_JOIN
check_type(AiId, ?CONST_AI_TYPE_JOIN, 1, TargetUnit1, [], 0, 0, 0, _) ->
    check_target(AiId, 1, TargetUnit1);
check_type(AiId, ?CONST_AI_TYPE_JOIN, 2, [], TargetUnit2, 0, 0, 0, _) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--单位离开           6   CONST_AI_TYPE_QUIT
check_type(AiId, ?CONST_AI_TYPE_QUIT, 1, TargetUnit1, [], 0, 0, 0, 1) ->
    check_target(AiId, 1, TargetUnit1);
check_type(AiId, ?CONST_AI_TYPE_QUIT, 2, [], TargetUnit2, 0, 0, 0, 1) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--设置怒气           7   CONST_AI_TYPE_SET_ANGER
check_type(AiId, ?CONST_AI_TYPE_SET_ANGER, 1, TargetUnit1, [], Value, 0, 0, 0) ->
    check_target(AiId, 1, TargetUnit1),
    check_type(AiId, Value, value, {integer, min, 0});
check_type(AiId, ?CONST_AI_TYPE_SET_ANGER, 2, [], TargetUnit2, Value, 0, 0, 0) ->
    check_target(AiId, 2, TargetUnit2),
    check_type(AiId, Value, value, {integer, min, 0});
%% ai类型--设置生命值      8   CONST_AI_TYPE_SET_HP
check_type(AiId, ?CONST_AI_TYPE_SET_HP, 1, TargetUnit1, [], Value, ValueType, AttrType, _) ->
    check_target(AiId, 1, TargetUnit1),
    check_type(AiId, Value, value, {integer, min, 0}),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
check_type(AiId, ?CONST_AI_TYPE_SET_HP, 2, [], TargetUnit2, Value, ValueType, AttrType, _) ->
    check_target(AiId, 2, TargetUnit2),
    check_type(AiId, Value, value, {integer, min, 0}),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
%% ai类型--增加战斗属性     9   CONST_AI_TYPE_PLUS_ATTR
check_type(AiId, ?CONST_AI_TYPE_PLUS_ATTR, 1, TargetUnit1, [], Value, ValueType, AttrType, _) ->
    check_target(AiId, 1, TargetUnit1),
    check_type(AiId, Value, value, {integer, min, 0}),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
check_type(AiId, ?CONST_AI_TYPE_PLUS_ATTR, 2, [], TargetUnit2, Value, ValueType, AttrType, _) ->
    check_target(AiId, 2, TargetUnit2),
    check_type(AiId, Value, value, {integer, min, 0}),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
%% ai类型--设置出手(不攻击)  10  CONST_AI_TYPE_SET_NO_ATTACK
check_type(AiId, ?CONST_AI_TYPE_SET_NO_ATTACK, 1, TargetUnit1, [], 0, 0, 0, 0) ->
    check_target(AiId, 1, TargetUnit1);
check_type(AiId, ?CONST_AI_TYPE_SET_NO_ATTACK, 2, [], TargetUnit2, 0, 0, 0, 0) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--己方全死副本通关   11  CONST_AI_TYPE_FINISH_COPY
check_type(_AiId, ?CONST_AI_TYPE_FINISH_COPY, 0, [], [], 0, 0, 0, 0) ->
    true;
%% ai类型--设置出手顺序     12  CONST_AI_TYPE_SET_SEQ
check_type(AiId, ?CONST_AI_TYPE_SET_SEQ, 1, TargetUnit1, [], 0, 0, 0, 0) ->
    check_target(AiId, 1, TargetUnit1);
check_type(AiId, ?CONST_AI_TYPE_SET_SEQ, 2, [], TargetUnit2, 0, 0, 0, 0) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--降低战斗属性     13  CONST_AI_TYPE_MINUS_ATTR
check_type(AiId, ?CONST_AI_TYPE_MINUS_ATTR, 1, TargetUnit1, [], Value, ValueType, AttrType, _) ->
    check_target(AiId, 1, TargetUnit1),
    check_rate(AiId, Value),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
check_type(AiId, ?CONST_AI_TYPE_MINUS_ATTR, 2, [], TargetUnit2, Value, ValueType, AttrType, _) ->
    check_target(AiId, 2, TargetUnit2),
    check_rate(AiId, Value),
    check_rate(AiId, ValueType),
    check_rate(AiId, AttrType);
%% ai类型--车轮战            14  CONST_AI_TYPE_ROUND_BATTLE
check_type(AiId, ?CONST_AI_TYPE_ROUND_BATTLE, 2, [], TargetUnit2, 0, 0, 0, _) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--禁止闪避           15  CONST_AI_TYPE_FORBID_DODGE
check_type(_AiId, ?CONST_AI_TYPE_FORBID_DODGE, 0, [], [], 0, 0, 0, 0) ->
    true;
%% ai类型--禁止格挡           16  CONST_AI_TYPE_FORBID_PARRY
check_type(_AiId, ?CONST_AI_TYPE_FORBID_PARRY, 0, [], [], 0, 0, 0, 0) ->
    true;
%% ai类型--按职业加入      17  CONST_AI_TYPE_JOIN_BY_PRO
check_type(AiId, ?CONST_AI_TYPE_JOIN_BY_PRO, 1, TargetUnit1, [], 0, 0, 0, 0) ->
    check_target(AiId, 1, TargetUnit1);
%% ai类型--按职业加入      18  CONST_AI_TYPE_SET_TARGET
check_type(_AiId, ?CONST_AI_TYPE_SET_TARGET, 1, _, [], _, 0, 0, 0) ->
    true;
%% ai类型--按职业加入      18  CONST_AI_TYPE_SET_TARGET
check_type(AiId, ?CONST_AI_TYPE_SET_TARGET, 2, [], TargetUnit2, _, 0, 0, 0) ->
    check_target(AiId, 2, TargetUnit2);
%% ai类型--按职业加入      19  CONST_AI_TYPE_INIT_ROUND
check_type(_AiId, ?CONST_AI_TYPE_INIT_ROUND, 0, [], [], _, 0, 0, 0) ->
    true;
%% ai类型--属性上升      20  CONST_AI_TYPE_PLUS_ATTR_SERV
check_type(AiId, ?CONST_AI_TYPE_PLUS_ATTR_SERV, _, _, _, Value, ValueType, AttrType, _) ->
    check_type(AiId, Value, "value", integer),
    check_type(AiId, ValueType, "value_type", integer),
    check_type(AiId, AttrType, "attr_type", integer),
    true;
%% ai类型--学习技能      23  CONST_AI_SKILL_STUDY
check_type(AiId, ?CONST_AI_SKILL_STUDY, _, _, _, Value, _, _, _) ->
    check_type(AiId, Value, "value", list),
    true;
check_type(AiId, Type, TargetSide, TargetUnit1, TargetUnit2, Value, ValueType, AttrType, IsStop) ->
    ?LOG("-----------------------------------~nai_id=~p~ntype=~p~ntarget_side=~p~nu1=~p~nu2=~p~nv=~p~nvt=~p~nat=~p~nstop=~p~n-----------------------------------", 
              [AiId, Type, TargetSide, TargetUnit1, TargetUnit2, Value, ValueType, AttrType, IsStop]),
    false.

check_target(AiId, Side, [0|Tail]) -> check_target(AiId, Side, Tail);
check_target(AiId, Side, [1|Tail]) -> check_target(AiId, Side, Tail);
check_target(AiId, Side, [MonId|Tail]) when is_number(MonId) ->
    case data_monster:get_monster(MonId) of
        null ->
            ?LOG("a=~p, mo=~p", [AiId, MonId]),
            false;
        _ ->
            check_target(AiId, Side, Tail)
    end;
check_target(AiId, Side, [{MonId, Idx}|Tail]) ->
    check_type(AiId, Idx, "target idx", {integer, min, 0}),
    case data_monster:get_monster(MonId) of
        null ->
            ?LOG("!err:a=~p, m=~p", [AiId, MonId]),
            false;
        _ ->
            check_target(AiId, Side, Tail)
    end;
check_target(AiId, Side, [{Pro, MonId, Idx}|Tail]) ->
    check_type(AiId, Pro, "target pro", {integer, min, 0}),
    check_type(AiId, Idx, "target idx", {integer, min, 0}),
    case data_monster:get_monster(MonId) of
        null ->
            ?LOG("!err:a=~p, m=~p", [AiId, MonId]),
            false;
        _ ->
            check_target(AiId, Side, Tail)
    end;
check_target(_AiId, _Side, []) ->
    true.

check_rate(_AiId, Rate) when 0 =< Rate andalso Rate =< 100000 -> true;
check_rate(AiId, Rate) ->
    ?LOG("!err:a=~p, rate=~p", [AiId, Rate]),
    true.

check_type(AiId, Value1, Tag, Format) ->
    case misc:is_type(Value1, Format) of
        true ->
            true;
        false ->
            ?LOG("!err[not fit format]:ai=~p, v[~p]=~p, f=~p", [AiId, Tag, Value1, Format])
    end.

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 触发方式--联动触发           0   CONST_AI_START_LINKAGE
check_condition(AiId, 0, {?CONST_AI_START_LINKAGE, N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, N, "n", {integer, eq, 0}),
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--第几回合           1   CONST_AI_START_NTH
check_condition(AiId, ?CONST_AI_TRIGGER_BOUT_FRONT, {?CONST_AI_START_NTH, _N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
check_condition(AiId, ?CONST_AI_TRIGGER_BOUT_BACK, {?CONST_AI_START_NTH, _N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--每几回合           2   CONST_AI_START_PER
check_condition(AiId, ?CONST_AI_TRIGGER_BOUT_FRONT, {?CONST_AI_START_PER, _N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--第几回合后每回合   3   CONST_AI_START_NTHTAIL
check_condition(AiId, ?CONST_AI_TRIGGER_BOUT_FRONT, {?CONST_AI_START_NTHTAIL, _N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--hp达到%      4   CONST_AI_START_ATTR_HP
check_condition(AiId, ?CONST_AI_TRIGGER_CHANGE, {?CONST_AI_START_ATTR_HP, _N}, Side, TargetUnitL, TargetUnitR) ->
    case Side of
        1 ->
            check_target(AiId, 1, TargetUnitL),
            check_type(AiId, TargetUnitR, "tur", {list, empty});
        2 ->
            check_type(AiId, TargetUnitL, "tul", {list, empty}),
            check_target(AiId, 2, TargetUnitR);
        X ->
            ?LOG("!err[no this side]:ai=~p, side=~p", [AiId, X])
    end;
%% 触发方式--怒气改变后达到%   5   CONST_AI_START_ATTR_ANGER
check_condition(AiId, ?CONST_AI_TRIGGER_CHANGE, {?CONST_AI_START_ATTR_ANGER, _N}, Side, TargetUnitL, TargetUnitR) ->
    case Side of
        1 ->
            check_target(AiId, 1, TargetUnitL),
            check_type(AiId, TargetUnitR, "tur", {list, empty});
        2 ->
            check_type(AiId, TargetUnitL, "tul", {list, empty}),
            check_target(AiId, 2, TargetUnitR);
        X ->
            ?LOG("!err[no this side]:ai=~p, side=~p", [AiId, X])
    end;
%% 触发方式--死亡         6   CONST_AI_START_DIE
check_condition(AiId, ?CONST_AI_TRIGGER_CHANGE, {?CONST_AI_START_DIE, N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, N, "n", {integer, min, 0}),
    check_type(AiId, Side, "side", {integer, 1, 2}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--战斗初始化      7   CONST_AI_START_INIT_BATTLE
check_condition(AiId, ?CONST_AI_TRIGGER_INIT, {?CONST_AI_START_INIT_BATTLE, N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, N, "n", {integer, eq, 0}),
    check_type(AiId, Side, "side", {integer, eq, 0}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
%% 触发方式--出手触发           8   CONST_AI_START_ATTACK
check_condition(AiId, ?CONST_AI_TRIGGER_CHANGE, {?CONST_AI_START_ATTACK, _N}, Side, TargetUnitL, TargetUnitR) ->
    case Side of
        1 ->
            check_target(AiId, 1, TargetUnitL),
            check_type(AiId, TargetUnitR, "tur", {list, empty});
        2 ->
            check_type(AiId, TargetUnitL, "tul", {list, empty}),
            check_target(AiId, 2, TargetUnitR);
        X ->
            ?LOG("!err[no this side]:ai=~p, side=~p", [AiId, X])
    end;
%% %% 触发方式--人数变化           9   CONST_AI_START_UNITS_CHANGE
check_condition(AiId, ?CONST_AI_TRIGGER_COPY_OVER, {?CONST_AI_START_UNITS_CHANGE, _N}, _, TargetUnitL, TargetUnitR) ->
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
check_condition(AiId, ?CONST_AI_TRIGGER_CHANGE, {?CONST_AI_START_UNITS_CHANGE, _N}, Side, TargetUnitL, TargetUnitR) ->
    check_type(AiId, Side, "side", {integer, 1, 2}),
    check_type(AiId, TargetUnitL, "tul", {list, empty}),
    check_type(AiId, TargetUnitR, "tur", {list, empty}),
    true;
check_condition(AiId, Trigger, AiStart, ConSide, ConSide1, ConSide2) ->
    ?LOG("--------------------------------------------~nid=~p~nt=~p~nstart=~p~nconside=~p~ncs1=~p~ncs2=~p~n--------------------------------------------------", 
         [AiId, Trigger, AiStart, ConSide, ConSide1, ConSide2]),
    false.
    
%%-----------------------------------------------------------------------
check_next([RecAi|Tail]) when is_record(RecAi, rec_ai) ->
    Next  = RecAi#rec_ai.next_ai,
    check_next(Next, RecAi#rec_ai.id, RecAi#rec_ai.id),
    check_next(Tail);
check_next([]) ->
    true.

check_next(AiId, OldAiId, InitId) when AiId =/= OldAiId andalso 0 =/= AiId ->
    case data_ai:get_base_ai(AiId) of
        RecAi when is_record(RecAi, rec_ai) ->
            Next  = RecAi#rec_ai.next_ai,
            check_next(Next, AiId, InitId);
        0 ->
            true;
        X ->
            ?LOG("x=~p, ai=~p, init=~p", [X, AiId, InitId]),
            false
    end;
check_next(AiId, _OldAiId, InitId) when 0 =/= AiId ->
    ?LOG("!err:~p->...->~p is cyclying.", [InitId, AiId]),
    false;
check_next(0, _, _) ->
    true.
        
    
    
    