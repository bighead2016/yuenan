%% Author: cobain
%% Created: 2012-10-17
%% Description: TODO: Add description to battle_skill_front
-module(battle_skill_front).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/record.battle.hrl").
%%
%% Exported Functions
%%
-export([exec_skill_front/6]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_1		技能效果ID--对目标[arg1]常规攻击(连续技)
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
%% CONST_SKILL_EFFECT_ID_97		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
%% CONST_SKILL_EFFECT_ID_155	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_1		技能效果ID--对目标[arg1]常规攻击(连续技)
exec_skill_front(?CONST_SKILL_EFFECT_ID_1, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_2, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
exec_skill_front(?CONST_SKILL_EFFECT_ID_3, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_4, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_5, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_11, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_12, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_13, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_14, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_15, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
exec_skill_front(?CONST_SKILL_EFFECT_ID_20, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
exec_skill_front(?CONST_SKILL_EFFECT_ID_21, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_22, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_23, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_24, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_25, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_26, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_27, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_28, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_29, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_30, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_31, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_32, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_33, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_34, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
exec_skill_front(?CONST_SKILL_EFFECT_ID_35, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_36, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_37, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_38, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_51, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_52, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_53, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_54, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_61, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_62, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_63, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_64, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_65, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_66, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_67, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
exec_skill_front(?CONST_SKILL_EFFECT_ID_81, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_82, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_83, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_84, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_85, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_86, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_87, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_91, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_92, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_93, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_94, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_95, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_96, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_97		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_97, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_101, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_102, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_103, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_104, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_105, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_106, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_107, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_108, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_109, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_111, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_111, Skill, Effect, ?CONST_BATTLE_STEP_FRONT),
			Fun	= fun(DefUnit, AccBattle) ->
						  %% 加BUFF
						  {
						   AccBattle2, DefUnit2, BuffDelete, BuffInsert
						  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
						  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
						  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
						  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
						  FlagCrit		    = battle_mod_misc:crit_flag(?null),
						  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_FRONT, 0, AttrChangeList, BuffChangeList),
						  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
						  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
						  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3)
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_112, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_112, Skill, Effect, ?CONST_BATTLE_STEP_FRONT),
			Fun	= fun(DefUnit, AccBattle) ->
						  %% 加BUFF
						  {
						   AccBattle2, DefUnit2, BuffDelete, BuffInsert
						  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
						  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
						  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
						  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
						  FlagCrit		    = battle_mod_misc:crit_flag(?null),
						  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_FRONT, 0, AttrChangeList, BuffChangeList),
						  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
						  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
						  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3)
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_121, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_121, Skill, Effect, ?CONST_BATTLE_STEP_FRONT),
			Fun	= fun(DefUnit, AccBattle) ->
						  %% 加BUFF
						  {
						   AccBattle2, DefUnit2, BuffDelete, BuffInsert
						  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
						  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
						  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
						  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
						  FlagCrit		    = battle_mod_misc:crit_flag(?null),
						  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_FRONT, 0, AttrChangeList, BuffChangeList),
						  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
						  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
						  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3)
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_113, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
    Battle;
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_131, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_132, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_133, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_134, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
    Battle;
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_151, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_152, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_153, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
exec_skill_front(?CONST_SKILL_EFFECT_ID_154, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_155	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_155, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_156, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
exec_skill_front(?CONST_SKILL_EFFECT_ID_157, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}   = Effect#effect.arg5,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        {DefSide, DefList} ->
            BuffList    = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_157, Skill, Effect, ?CONST_BATTLE_STEP_BACK), % 这里是特殊处理
            Fun = fun(DefUnit, AccBattle) ->
                          case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                              ?true ->
                                  %% 加BUFF
                                  {
                                   AccBattle2, DefUnit2, BuffDelete, BuffInsert
                                  }                 = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
                                  DefUnit3          = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
                                  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                  FlagCrit          = battle_mod_misc:crit_flag(?null),
                                  DefCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_FRONT, 0, AttrChangeList, BuffChangeList),
                                  AccBattle3        = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
                                  AccBattle4        = battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
                                  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
                              ?false -> AccBattle
                          end
                  end,
            lists:foldl(Fun, Battle, DefList);
        ?null -> Battle
    end;
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
exec_skill_front(?CONST_SKILL_EFFECT_ID_158, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff
exec_skill_front(?CONST_SKILL_EFFECT_ID_159, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle.
%%
%% Local Functions
%%

    
    