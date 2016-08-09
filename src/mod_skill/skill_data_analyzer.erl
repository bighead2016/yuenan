%%% 技能数据分析

-module(skill_data_analyzer).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").

%%
%% Exported Functions
%%
-export([analyze/1]).

%%
%% API Functions
%%
analyze(_Ver) ->
    SkillIdList = data_skill:get_all(),
    analyze_effect(SkillIdList),
    analyze_pre(SkillIdList),
    ok.

%%
%% Local Functions
%%
analyze_effect([SkillId|Tail]) ->
    Skill = data_skill:get_skill(SkillId),
    EffectList = Skill#skill.effect,
    check_effect(EffectList),
	check_normal_skill(Skill),
    analyze_effect(Tail);
analyze_effect([]) ->
    ok.

check_effect(Effect) when is_record(Effect, effect) ->
    TargetTypeList = get_target_type_list(),
    GTypeList = get_genius_type_list(),
    TargetList = get_target_list(Effect#effect.effect_id, TargetTypeList, GTypeList),
    misc:check_type([Effect], TargetList);
check_effect(X) ->
    io:format("!err:x=~p", [X]),
    ok.

check_normal_skill(#skill{type = ?CONST_SKILL_TYPE_NORMAL,
						  cd = 1, anger = 0}) ->
	ok;
check_normal_skill(#skill{skill_id = SkillId, cd = CD, anger = Anger,
						  type = ?CONST_SKILL_TYPE_NORMAL}) ->
	io:format("!err:SkillId=~p ~p ~p~n", [SkillId, CD, Anger]);
check_normal_skill(_) ->
	ok.

get_target_type_list() ->
[
 ?CONST_BATTLE_TARGET_TYPE_DEFAULT         ,   % 目标类型--默认已有目标 
 ?CONST_BATTLE_TARGET_TYPE_SELF            ,   % 目标类型--自己 
 ?CONST_BATTLE_TARGET_TYPE_SINGLE          ,   % 目标类型--单体 
 ?CONST_BATTLE_TARGET_TYPE_NEIGHBOUR       ,   % 目标类型--攻击目标相邻目标 
 ?CONST_BATTLE_TARGET_TYPE_MIN_HP          ,   % 目标类型--血量最少 
 5,
 ?CONST_BATTLE_TARGET_TYPE_MIN_HP_2        ,   % 目标类型--血量最少2人 
 ?CONST_BATTLE_TARGET_TYPE_MIN_HP_3        ,   % 目标类型--血量最少3人 
 ?CONST_BATTLE_TARGET_TYPE_MIN_HP_4        ,   % 目标类型--血量最少4人 
 ?CONST_BATTLE_TARGET_TYPE_MIN_HP_5        ,   % 目标类型--血量最少5人 
 ?CONST_BATTLE_TARGET_TYPE_ALL             ,   % 目标类型--全体 
 ?CONST_BATTLE_TARGET_TYPE_ALL_MAGIC       ,   % 目标类型--全体法系职业 
 ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_1    ,   % 目标类型--敌方随机1人 
 ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_2    ,   % 目标类型--敌方随机2人 
 ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_3    ,   % 目标类型--敌方随机3人 
 ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_4    ,   % 目标类型--敌方随机4人 
 ?CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_5    ,   % 目标类型--敌方随机5人 
 ?CONST_BATTLE_TARGET_TYPE_ROW             ,   % 目标类型--攻击目标所在列 
 ?CONST_BATTLE_TARGET_TYPE_COLUMN          ,   % 目标类型--攻击目标所在行（最前排） 
 ?CONST_BATTLE_TARGET_TYPE_COLUMN_LAST     ,   % 目标类型--最后一行 
 ?CONST_BATTLE_TARGET_TYPE_COLUMN_MAGIC    ,   % 目标类型--最后一行的所有法系职业 
 ?CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_1 ,   % 目标类型--最后一行的随机1人 
 ?CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_3     % 目标类型--最后两行的随机3人
].

get_genius_type_list() ->
[
%%     ?CONST_SKILL_GENIUS_TRIGGER_NULL        ,% 天赋技能触发点--空 
    ?CONST_SKILL_GENIUS_TRIGGER_DEFAULT        ,% 天赋技能触发点--默认(战斗初始化触发) 
    ?CONST_SKILL_GENIUS_TRIGGER_BOUT           ,% 天赋技能触发点--回合(回合刷新触发) 
    ?CONST_SKILL_GENIUS_TRIGGER_MINUS_ANGER    ,% 天赋技能触发点--消耗怒气(技能消耗怒气触发) 
    ?CONST_SKILL_GENIUS_TRIGGER_CURE           ,% 天赋技能触发点--治疗 
    ?CONST_SKILL_GENIUS_TRIGGER_BE_CURE        ,% 天赋技能触发点--受治疗
    ?CONST_SKILL_GENIUS_TRIGGER_CHANGE         ,% 天赋技能触发点--改变(生命、怒气、BUFF) 
    ?CONST_SKILL_GENIUS_TRIGGER_ATK_ATTR       ,% 天赋技能触发点--攻击(修正属性) 
    ?CONST_SKILL_GENIUS_TRIGGER_ATK_HURT       ,% 天赋技能触发点--攻击(修正伤害) 
    ?CONST_SKILL_GENIUS_TRIGGER_DEF_ATTR       ,% 天赋技能触发点--防守(修正属性) 
    ?CONST_SKILL_GENIUS_TRIGGER_DEF_HURT       ,% 天赋技能触发点--防守(修正伤害) 
    ?CONST_SKILL_GENIUS_TRIGGER_ATK            ,% 天赋技能触发点--攻击 
    ?CONST_SKILL_GENIUS_TRIGGER_DEF            ,% 天赋技能触发点--防守 
	?CONST_SKILL_GENIUS_TRIGGER_ATK_TARGET		% 天赋技能触发点--攻击(修正目标) 
].

%% CONST_SKILL_EFFECT_ID_1      技能效果ID--对目标[arg1]常规攻击(连续技)
get_target_list(?CONST_SKILL_EFFECT_ID_1, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}}, % 目标
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_2      技能效果ID--对目标[arg1]常规攻击[arg2]连击
get_target_list(?CONST_SKILL_EFFECT_ID_2, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_3      技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
get_target_list(?CONST_SKILL_EFFECT_ID_3, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 去掉[arg2]个DEBUFF
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_4      技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合    
get_target_list(?CONST_SKILL_EFFECT_ID_4, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 0, 10000}, % [arg2]几率
       {integer, 0, 100}, % 眩晕[arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_5, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 0, 10000}, % [arg2]几率
	   {integer, min, 0}, % [arg3]%万分比
       {integer, 0, 100}, % [arg4]回合 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
	   {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_11     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
get_target_list(?CONST_SKILL_EFFECT_ID_11, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % [arg2]%万分比
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_12     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_12, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % [arg2]%万分比
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_13     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_13, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % [arg2]%万分比
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_14, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
	   {integer, min, 0}, % [arg2]%
       {integer, 1, 5}, % 连击数 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % [arg2]%万分比
       {integer, 0, 100}, % [arg3]回合
       {integer, eq, 0}, {integer, eq, 0},
	   {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_15, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % [arg2]%万分比
	   {integer, min, 0}, % 增加[arg2]%
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, 0, 100}, % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
	   {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
get_target_list(?CONST_SKILL_EFFECT_ID_20, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 降低[arg5]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_21     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
get_target_list(?CONST_SKILL_EFFECT_ID_21, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_22     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_22, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_23     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_23, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_24     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_24, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_25     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_25, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_26     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_26, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_27     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_27, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_28     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_28, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_29     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_29, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_30     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_30, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_31     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_31, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_32     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_32, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_33     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_33, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_34     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_34, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_35     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
get_target_list(?CONST_SKILL_EFFECT_ID_35, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]回合后必然暴击
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_36     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_36, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标 [arg4]
       {integer, min, 0}, % 增加[arg5]%
       {integer, 0, 100}, % [arg6]回合
       {integer, 0, 100}, % [arg7]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_37, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % 增加[arg5]%
       {integer, min, 0}, % 增加[arg6]%
       {integer, 0, 100}, % [arg7]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_38, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, min, 0}, % 增加[arg5]%
       {integer, min, 0}, % 增加[arg6]%
       {integer, 0, 100}, % [arg7]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_51     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
get_target_list(?CONST_SKILL_EFFECT_ID_51, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_52     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
get_target_list(?CONST_SKILL_EFFECT_ID_52, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_53     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
get_target_list(?CONST_SKILL_EFFECT_ID_53, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_54     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_54, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_61     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_61, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_62     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_62, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_63     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_63, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_64     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_64, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0}, % [arg5]
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_65     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_65, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_66     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_66, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_67     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_67, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_81     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
get_target_list(?CONST_SKILL_EFFECT_ID_81, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_82     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_82, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_83     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_83, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_84     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_84, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_85, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_86, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合  
get_target_list(?CONST_SKILL_EFFECT_ID_87, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0},  % 降低[arg5]%
       {integer, 0, 100},  % [arg6]回合
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_91     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_91, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_92     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_92, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_93     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_93, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_94     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_94, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_95     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_95, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_96     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_96, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_97, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标
       {integer, 1, 5}, % 连击数 
       {integer, 0, 10000}, % 有[arg3]几率
       {integer, min, 0},  % 降低[arg4]%
       {integer, 0, 100},  % [arg5]回合
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_101    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
get_target_list(?CONST_SKILL_EFFECT_ID_101, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_102    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
get_target_list(?CONST_SKILL_EFFECT_ID_102, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_103    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合 
get_target_list(?CONST_SKILL_EFFECT_ID_103, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, min, 0}, %  [arg4]几率
       {integer, 0, 100}, % [arg5]回合 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_104    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合  
get_target_list(?CONST_SKILL_EFFECT_ID_104, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_105, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
get_target_list(?CONST_SKILL_EFFECT_ID_106, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_107, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数
	   {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_108, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
	   {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
	   {integer, min, 0}, % 增加[arg6]%
       {integer, 0, 100}, % [arg7]回合 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_109, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
	   {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
	   {integer, min, 0}, % 增加[arg6]%
       {integer, 0, 100}, % [arg7]回合 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_111    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
get_target_list(?CONST_SKILL_EFFECT_ID_111, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, 0, 100}, % [arg3]回合 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 1, 5}, % 连击数 [arg5]
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
get_target_list(?CONST_SKILL_EFFECT_ID_112, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, 0, 100}, % [arg3]回合 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 1, 5}, % 连击数 [arg5]
	   {integer, min, 0}, %  [arg6]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg7]
       {integer, 0, 100}, % [arg8]回合 
	   {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_113, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % 连击数 [arg2]
       {integer, min, 0}, %  [arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0}, % 增加[arg5]%
	   {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0},
       {integer, eq, 0},
	   {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_121    技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
get_target_list(?CONST_SKILL_EFFECT_ID_121, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, 0, 100}, % [arg3]回合 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 1, 5}, % 连击数 [arg5]
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_131    技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
get_target_list(?CONST_SKILL_EFFECT_ID_131, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, min, 0}, % [arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, 0, 100}, % [arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_132    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_132, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, min, 0}, % [arg3]几率
       {integer, min, 0}, % [arg4]几率
       {integer, min, 0}, % [arg5]%
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_133    技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_133, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, 0, 100}, % [arg3]回合 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0}, % [arg5]几率
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
get_target_list(?CONST_SKILL_EFFECT_ID_134, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, min, 0}, % 增加[arg2]%
       {integer, min, 0}, % 
       {integer, min, 0}, % [arg4]几率
       {integer, min, 0}, % [arg5]%
       {integer, 0, 100}, % [arg6]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_151    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
get_target_list(?CONST_SKILL_EFFECT_ID_151, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % [arg2]连击
       {integer, 0, 10000}, % [arg3]几率
       {integer, min, 0}, % [arg4]%
       {integer, 0, 100}, % [arg5]回合 
       {integer, min, 0}, % [arg6]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg7]
       {integer, min, 0}, % [arg8]%
       {integer, 0, 100}, % [arg9]回合 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_152    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
get_target_list(?CONST_SKILL_EFFECT_ID_152, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % [arg2]连击
       {integer, 0, 10000}, % [arg3]几率
       {integer, min, 0}, % [arg4]%
       {integer, 0, 100}, % [arg5]回合 
       {integer, min, 0}, % [arg6]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg7]
       {integer, min, 0}, % [arg8]%
       {integer, 0, 100}, % [arg9]回合 
       {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_153    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
get_target_list(?CONST_SKILL_EFFECT_ID_153, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % [arg2]连击
       {integer, 0, 10000}, % [arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0}, % [arg5]%
       {integer, 0, 100}, % [arg6]回合 
       {integer, min, 0}, % [arg7]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg8]
       {integer, min, 0}, % [arg9]%
       {integer, 0, 100}  % [arg10]回合 
   ];
%% CONST_SKILL_EFFECT_ID_154    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合
get_target_list(?CONST_SKILL_EFFECT_ID_154, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % [arg2]连击
       {integer, 0, 10000}, % [arg3]几率
       {integer, 0, 100}, % [arg4]回合 
       {integer, min, 0}, % [arg5]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg6]
       {integer, min, 0}, % [arg7]%
       {integer, 0, 100}, % [arg8]回合 
       {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
get_target_list(?CONST_SKILL_EFFECT_ID_155, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg1]
       {integer, 1, 5}, % [arg2]连击
       {integer, 0, 10000}, % [arg3]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg4]
       {integer, min, 0}, % [arg5]%
       {integer, min, 0}, % [arg6]%
       {integer, min, 0}, % [arg7]%
       {integer, 0, 100}, % [arg8]回合 
       {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_156, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000},  % [arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % [arg3]连击
       {integer, 0, 10000},  % [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
       {integer, min, 0}, % [arg6]%
       {integer, 0, 100}, % [arg7]回合 
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
get_target_list(?CONST_SKILL_EFFECT_ID_157, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % 增加[arg1]%
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, 1, 5}, % 连击数 
       {integer, min, 0}, %  [arg4]几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg5]
       {integer, min, 0}, % 增加[arg6]%
       {integer, 0, 100}, % [arg7]回合 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
get_target_list(?CONST_SKILL_EFFECT_ID_158, TargetTypeList, _GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%防御力
       {integer, min, 0}, % 增加[arg2]%暴击
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg3]
       {integer, 1, 5}, % 连击数 
       {integer, eq, 0}, % 
       {integer, eq, 0}, %
       {integer, eq, 0}, % 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}
   ];

%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff
get_target_list(?CONST_SKILL_EFFECT_ID_159, TargetTypeList, _GTypeList) ->
	[
		atom, integer,
		{tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},	%% 目标[arg1]
		{integer, 1, 5},			%% [arg2]连击
		{integer, 0, 10000}, 		%% [arg3]几率
		{tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  %% 目标[arg4]
		{integer, 0,10} 			%% [arg2]个BUFF
	];

%% CONST_SKILL_GENIUS_EFFECT_ID_301 天赋技能效果ID--默认，[arg1]回合内必然暴击
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_301, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 100}, % [arg1]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_351 天赋技能效果ID--回合，有[arg1]%几率解除[arg2]个DEBUFF
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_351, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, 0,10}, %   [arg2]个DEBUFF
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_401 天赋技能效果ID--技能消耗怒气，降低[arg1]%技能怒气消耗
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_401, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_451 天赋技能效果ID--治疗，有[arg1]%几率解除[arg2]个DEBUFF
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_451, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, 0,10}, %   [arg2]个DEBUFF
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_452 天赋技能效果ID--治疗，有[arg1]%几率增加[arg2]%攻击力[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_452, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, % [arg2]%
       {integer, 0, 100}, % [arg3]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_501 天赋技能效果ID--受治疗，有[arg1]%几率增加[arg2]%治疗效果
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_501, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, % [arg2]%
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_551 天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_551, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_601 天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_601, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_602 天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_602, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_603 HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_603, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0},    % [arg1]%
       {integer, 0, 10000},  % [arg2]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg3]
       {integer, min, 0},    % [arg4]%
       {integer, 0, 10000},  % [arg5]回合 
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_651 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_651, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_652 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合。
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_652, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]BUFF
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_653 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_653, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_654 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_654, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_655 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_655, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0}, % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_701 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%防御力--攻击(修正属性)
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_701, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_702 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%法术防御力--攻击(修正属性)
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_702, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_703 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%生命上限[arg3]回合 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_703, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_704 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%速度[arg3]回合 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_704, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_705 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%命中[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_705, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_706 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率降低[arg2]%治疗效果[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_706, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_707 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率解除[arg2]个BUFF
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_707, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, 0, 100},  % [arg2]个BUFF
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_708 天赋技能效果ID--攻击(技能攻击)，有[arg1]%几率降低目标[arg2]%怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_708, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_709 天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%命中[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_709, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_710 天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%速度[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_710, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg3]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_711 天赋技能效果ID--攻击(死亡)，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_711, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, min, 0},  % [arg3]%
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_712 天赋技能效果ID--攻击(死亡)，有[arg1]%几率增加[arg2]点怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_712, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]点怒气
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_713 天赋技能效果ID--攻击(普通攻击并暴击)，有[arg1]%几率增加免疫DEBUFF[arg2]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_713, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, 0, 100},  % [arg2]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_714 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率对目标[arg2]降低[arg3]%命中[arg4]回合 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_714, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, min, 0},  % [arg3]%
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_751 天赋技能效果ID--防守，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_751, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_752 天赋技能效果ID--防守，有[arg1]%几率降低攻击者[arg2]%速度[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_752, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg2]%
       {integer, 0, 100},  % [arg2]回合
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_753 天赋技能效果ID--防守，伤害高于生命上限[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力[arg4]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_753, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, min, 0},  % [arg1]%
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg3]%
       {integer, 0, 100},  % [arg4]回合
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_754 天赋技能效果ID--防守(受暴击)，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_754, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg1]%
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0},
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_755 天赋技能效果ID--防守(受暴击)，有[arg1]%几率增加[arg2]%闪避[arg3]回合
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_755, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg2]%几率
       {integer, min, 0},  % [arg1]%
       {integer, 0, 100},  % [arg3]回合
       {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_756 天赋技能效果ID--防守(死亡)，有[arg1]%几率复活，恢复[arg2]%生命
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_756, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},  % [arg1]%
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_757 天赋技能效果ID--防守，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_757, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},  % 目标[arg2]
       {integer, min, 0}, {integer, 0, 100},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_758 天赋技能效果ID--防守，有[arg1]%几率反击一次 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_758, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_759 天赋技能效果ID--防守，当发生格挡时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]%怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_759, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_760 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_760, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_761 天赋技能效果ID--防守发生暴击时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_761, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_762 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_762, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_763 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_763, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_764 天赋技能效果ID--攻击被闪避时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_764, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_765 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%术攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_765, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_766 天赋技能效果ID--被治疗时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_766, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_767 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%双防持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_767, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_768 天赋技能效果ID--攻击时，有[arg1]%机率多攻击[arg2]个目标，并有[arg3]%机率增加[arg4]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_768, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, min, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_769 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_769, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_770 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_770, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_771 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%气血上限持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_771, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_772 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%法术防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_772, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, min, 0}, {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_773 天赋技能效果ID--攻击时，有[arg1]%机率解除目标[arg2]的[arg3]个[arg4]buff，并有[arg5]%机率增加[arg6]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_773, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},
       {integer, min, 0}, 
       {integer, min, 0}, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_774 天赋技能效果ID--攻击时，有[arg1]%机率封印目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_774, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, 
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_775 天赋技能效果ID--攻击时，有[arg1]%机率沉默目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_775, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0},
       {integer, 0, 10000}, % [arg1]%几率
       {integer, min, 0}, 
       {integer, min, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_776 天赋技能效果ID--死亡时，有[arg1]%机率提升目标[arg2][arg3]%双攻持续[arg4]回合，并有[arg5]%机率增加[arg6]怒气
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_776, TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000}, % [arg1]%几率
       {tuple, {{integer, 1, 2}, {integer, in, TargetTypeList}}},
       {integer, min, 0},
       {integer, min, 0}, 
       {integer, min, 0},
       {integer, min, 0},
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
%% CONST_SKILL_GENIUS_EFFECT_ID_801 天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位 
get_target_list(?CONST_SKILL_GENIUS_EFFECT_ID_801, _TargetTypeList, GTypeList) ->
   [
       atom, integer, 
       {integer, 0, 10000},
       {integer, 1,  3},
       {integer, 1,  5}, {integer, eq, 0},
       {integer, eq, 0}, {integer, eq, 0}, {integer, eq, 0}, 
       {integer, eq, 0}, {integer, eq, 0}, 
       {integer, in, GTypeList} % 天赋
   ];
get_target_list(Id, _TargetTypeList, _GTypeList) ->
    io:format("!err:id=~p not exit", [Id]),
    ok.

%%-----------------------------------------------------------------------------------------------
%% 假如没有死循环就是对的
analyze_pre([SkillId|Tail]) ->
    Skill = data_skill:get_skill(SkillId),
    PrevList = Skill#skill.prev_skill,
    check_prev({Skill#skill.skill_id, Skill#skill.lv}, PrevList, []),
    analyze_pre(Tail);
analyze_pre([]) ->
    ok.

check_prev(Tag, [{SkillId, Lv}|Tail], OldStack) ->
    Skill = data_skill:get_skill({SkillId, Lv}),
    case lists:member({SkillId, Lv}, OldStack) of
        true ->
            io:format("!err:~p, deadlock=~p~n", [Tag, {SkillId, Lv}]);
        false ->
			if
				is_record(Skill,skill) -> ok;
				true ->
					io:format("!err:~p, deadlock=~p~n", [Tag, {SkillId, Lv}])
			end,
            check_prev(Tag, Skill#skill.prev_skill, [{SkillId, Lv}|OldStack])
    end,
    check_prev(Tag, Tail, [{SkillId, Lv}|OldStack]);
check_prev(Tag, [X|Tail], OldStack) ->
    io:format("!err:~p, prev[~p] is unknown~n", [Tag, X]),
    check_prev(Tag, Tail, OldStack);
check_prev(_, [], _) ->
    ok.




