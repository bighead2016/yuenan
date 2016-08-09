%% Author: cobain
%% Created: 2012-10-17
%% Description: TODO: Add description to battle_skill_middle
-module(battle_skill_middle).

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
-export([exec_skill_middle/6]).

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
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
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
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_1		技能效果ID--对目标[arg1]常规攻击(连续技)
exec_skill_middle(?CONST_SKILL_EFFECT_ID_1, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_2, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
exec_skill_middle(?CONST_SKILL_EFFECT_ID_3, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_4, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	exec_install_buff_more(?CONST_SKILL_EFFECT_ID_4, Battle, Skill, Effect, AtkSide, AtkIdx);
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_5, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	exec_install_buff_more(?CONST_SKILL_EFFECT_ID_5, Battle, Skill, Effect, AtkSide, AtkIdx);
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_11, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg3,
	CureRate					= Effect#effect.arg2, % / Times,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_12, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg3,
	CureRate					= Effect#effect.arg2, %/ Times,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_13, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg3,
	CureRate					= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_14, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg3,
	CureRate					= Effect#effect.arg2, % / Times,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_15, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg3,
	CureRate					= Effect#effect.arg2, % / Times,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
exec_skill_middle(?CONST_SKILL_EFFECT_ID_20, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
exec_skill_middle(?CONST_SKILL_EFFECT_ID_21, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_22, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_23, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_24, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_25, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_26, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_27, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_28, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_29, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_30, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_31, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_32, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_33, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_34, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_35, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_36, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_37, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_38, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_51, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_52, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_53, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_54, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_61, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_62, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_63, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_64, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_65, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_66, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_67, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
exec_skill_middle(?CONST_SKILL_EFFECT_ID_81, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_82, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_83, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_84, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_85, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_86, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_87, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_91, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_92, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_93, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_94, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_95, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_96, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合  
exec_skill_middle(?CONST_SKILL_EFFECT_ID_97, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_101, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_102, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_103, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_104, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_105, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_106, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_107, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_108, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_109, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg2,
	Times						= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_111, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	Times						= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_112, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	Times						= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_113, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg1,
    Times                       = Effect#effect.arg2,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        ?null -> Battle;
        {DefSide, DefList} ->
            exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
    end;
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_121, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	Times						= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_131, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_plus_anger_more(Battle, Skill, Effect, Effect#effect.arg2, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_132, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_minus_anger_more(Battle, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_133, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	exec_install_buff_more(?CONST_SKILL_EFFECT_ID_133, Battle, Skill, Effect, AtkSide, AtkIdx);
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_134, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg1,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        ?null -> Battle;
        {DefSide, DefList} ->
            exec_minus_anger_more_point(Battle, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
    end;
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_151, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_152, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_153, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_154, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_155, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end;
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
exec_skill_middle(?CONST_SKILL_EFFECT_ID_156, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}   = Effect#effect.arg2,
    Times                       = Effect#effect.arg3,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        ?null -> Battle;
        {DefSide, DefList} ->
            exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
    end;
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
exec_skill_middle(?CONST_SKILL_EFFECT_ID_157, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg2,
    Times                       = Effect#effect.arg3,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        ?null -> Battle;
        {DefSide, DefList} ->
            exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
    end;
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
exec_skill_middle(?CONST_SKILL_EFFECT_ID_158, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg3,
    Times                       = Effect#effect.arg4,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        ?null -> Battle;
        {DefSide, DefList} ->
            exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
    end;
%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff
exec_skill_middle(?CONST_SKILL_EFFECT_ID_159, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Times						= Effect#effect.arg2,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		?null -> Battle;
		{DefSide, DefList} ->
			exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, 1})
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exec_attack_more(Battle, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, Num}) ->
	AtkUnit			= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkType			= battle_mod_misc:atk_type(Skill),
	Battle2			= battle_mod_misc:set_genius_list(Battle, AtkSide, AtkUnit),					%% 设置天赋资格列表
	exec_attack_more2(Battle2, AtkType, Times, Skill, Effect, {AtkUnit, AtkSide, AtkIdx, [], []}, {DefSide, DefList, Num}).

exec_attack_more2(Battle, AtkType, Times, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx, AtkBuffDelete, AtkBuffInsert}, {DefSide, [DefUnit|DefList], Num}) ->
	AtkUnit			= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	{
	 AtkUnit2, InevitableCrit
	}				= battle_mod_misc:check_inevitable_crit(AtkUnit),
	Battle2			= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
	{
	 Battle3, AtkBuffDelete2, AtkBuffInsert2
	}				= do_exec_attack(Battle2, Times, InevitableCrit, AtkType, Skill, Effect,
									 {AtkSide, AtkUnit2, AtkBuffDelete, AtkBuffInsert}, {DefSide, DefUnit, Num}),
	exec_attack_more2(Battle3, AtkType, Times, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx, AtkBuffDelete2, AtkBuffInsert2}, {DefSide, DefList, Num + 1});
exec_attack_more2(Battle, _AtkType, _Times, Skill, _Effect, {AtkUnitOld, AtkSide, AtkIdx, AtkBuffDelete, AtkBuffInsert}, {_DefSide, [], _Num}) ->
	AtkUnit			= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkUnitNew		= battle_mod_misc:plus_anger(AtkUnit, Skill),
	FlagCrit		= battle_mod_misc:crit_flag(?null),
	Battle2			= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnitNew),
	AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnitOld, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	DefCmds			= case battle_mod_misc:cmd_data_atk_change(AtkSide, AtkUnitOld, AtkUnitNew, AtkBuffDelete, AtkBuffInsert) of
						  ?null -> Battle2#battle.cmd_def;
						  AtkChangeCmd -> [AtkChangeCmd|Battle2#battle.cmd_def]
					  end,
%% 	%% 属性变化触发ai
%% 	{Battle3, AiPacket} = ai_api:trigger_ai(Battle2, ?CONST_AI_TRIGGER_CHANGE),
%% 	OldAiPacket = Battle3#battle.ai_packet,
%% 	Battle4	= Battle3#battle{ai_packet = <<OldAiPacket/binary, AiPacket/binary>>},
	%% 清除ai设置的攻击目标
	AtkUnit2	= battle_mod_misc:get_unit(Battle2, AtkSide, AtkUnit#unit.idx),
	AtkUnit3 	= AtkUnit2#unit{target = []},
	Battle3 	= battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit3),
	Battle3#battle{cmd_atk = AtkCmd, cmd_def = DefCmds}.

do_exec_attack(Battle, Times, InevitableCrit, AtkType, Skill, Effect,
			   {AtkSide, AtkUnit, AtkBuffDelete, AtkBuffInsert}, {DefSide, DefUnit, Num}) ->
	%% 天赋技能--每次攻击修正角色属性--在这里(不保存)
	{Battle2, {AtkSide, AtkUnitRevise}, {DefSide, DefUnitRevise}} = 								%% 根据天赋技能效果修正战斗单元(临时)
		battle_genius_skill:genius_skill_front_revise_attr(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit},
														   battle_mod_misc:record_genius_param(AtkType, ?null, 0, ?false, ?false, ?false)),
	{
	 {AtkSide, AtkUnitRevise2}, {DefSide, DefUnitRevise2}											%% 根据技能效果修正战斗单元(临时)
	} 			= revise_unit_skill_effect(Effect#effect.effect_id, Skill, Effect, {AtkSide, AtkUnitRevise}, {DefSide, DefUnitRevise}),
	{
	 {AtkSide, AtkUnitRevise3}, {DefSide, DefUnitRevise3}											%% 根据BUFF修正战斗单元(临时)
	} 			= battle_mod_buff:trigger_buff_revise_attr({AtkSide, AtkUnitRevise2}, {DefSide, DefUnitRevise2}),
	
	TempParam	= battle_mod_misc:record_temp_param(),
	{
	 Battle9, TempParam2, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}
	}			= do_exec_attack_times(Battle2, InevitableCrit, AtkType, Skill, Effect, Times, 1, TempParam,
									   {AtkSide, AtkUnit, AtkUnitRevise3},
									   {DefSide, DefUnit, DefUnitRevise3, Num}),
	%% 天赋技能--每次攻击给防守方加BUFF--在这里(保存)
	GeniusParam	= battle_mod_misc:record_genius_param(AtkType, TempParam2#temp_param.crit, TempParam2#temp_param.hurt, TempParam2#temp_param.death, TempParam2#temp_param.parry, 
                                                      TempParam2#temp_param.hit),
	Battle10	= battle_genius_skill:genius_skill_middle(Battle9, {AtkSide, AtkUnit2#unit.idx}, {DefSide, DefUnit2#unit.idx}, GeniusParam),
	Battle11	= battle_mod_misc:set_genius_list(Battle10, DefSide, DefUnit2),						%% 设置天赋资格列表
%% 	%% 属性变化触发ai
%% 	{Battle12, AiPacket} = ai_api:trigger_ai(Battle11, ?CONST_AI_TRIGGER_CHANGE),
%% 	?MSG_DEBUG("skill_middle:~p",[Battle12#battle.units_right]),
%% 	OldAiPacket = Battle12#battle.ai_packet,
%% 	Battle13	= Battle12#battle{ai_packet = <<OldAiPacket/binary, AiPacket/binary>>},
%% 	%% 清除ai设置的攻击目标
%% 	AtkUnit3	= battle_mod_misc:get_unit(Battle10, AtkSide, AtkUnit2#unit.idx),
%% 	AtkUnit4 	= AtkUnit3#unit{target = []},
%% 	?MSG_DEBUG("skill_middle2:~p",[Battle13#battle.units_right]),
%% 	Battle14 	= battle_mod_misc:set_unit(Battle13, AtkSide, AtkUnit4),
%% 	?MSG_DEBUG("skill_middle3:~p",[Battle14#battle.units_right]),
	{Battle11, AtkBuffDelete, AtkBuffInsert}.


do_exec_attack_times(Battle, _InevitableCrit, _AtkType, Skill, Effect, Times, AccTimes, TempParam,
					 {AtkSide, AtkUnit, _AtkUnitRevise}, {DefSide, DefUnit, _DefUnitRevise, _Num})
  when AccTimes > Times ->
	case TempParam#temp_param.hit of
		?true ->
			{Battle2, DefUnit2} =																			%% 执行命中后技能效果
				exec_skill_middle_hit(Effect#effect.effect_id, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}),
			Battle3		    = battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit),							%% 
			Battle4		    = battle_mod_misc:set_unit(Battle3, DefSide, DefUnit2),							%%
			Battle5			= battle_mod_misc:set_resist_list(Battle4, TempParam#temp_param.resist, DefSide, DefUnit2),		%% 设置反击列表
			{Battle5, TempParam, {AtkSide, AtkUnit}, {DefSide, DefUnit2}};
		?false ->
			Battle2		    = battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit),							%% 
			Battle3		    = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit),							%%
			{Battle3, TempParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}}
	end;
do_exec_attack_times(Battle, InevitableCrit, AtkType, Skill, Effect, Times, AccTimes, TempParam,
					 {AtkSide, AtkUnit, AtkUnitRevise}, {DefSide, DefUnit, DefUnitRevise, Num}) ->
	{
	 ?ok, Hit, Dodge, Crit, Parry, Resist, HurtFinalTmp
	} 				= do_exec_attack_single(Battle, InevitableCrit, AtkType, Skill, Effect, Times, AccTimes,
											{AtkSide, AtkUnitRevise}, {DefSide, DefUnitRevise, Num}),
	TempParam2		= battle_mod_misc:refresh_temp_param(TempParam, Hit, Dodge, Crit, Parry, HurtFinalTmp, Resist),
	DefDisplay	    = battle_mod_misc:display(Hit, Parry),								%% 战斗表现类型
	FlagCrit	    = battle_mod_misc:crit_flag(Crit),									%% 暴击标记
	AtkUnit2		= battle_mod_misc:suck_hp(AtkUnit, HurtFinalTmp),					%% 执行吸血
	{
	 DefUnit2, Death, HurtFinal
	}				= battle_mod_misc:minus_hp(Battle#battle.enlarge_rate, DefUnit, HurtFinalTmp),	%% 执行伤害
	TempParam3		= battle_mod_misc:set_temp_param_death(TempParam2, Death),
	Battle2 	    = battle_mod_misc:cumsum_hurt(Battle, AtkSide, HurtFinal),			%% 统计输出
	DefCmd 		    = battle_mod_misc:cmd_data(AccTimes, DefSide, DefUnit2, FlagCrit, DefDisplay, HurtFinal, [], []),
	Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
	do_exec_attack_times(Battle3, InevitableCrit, AtkType, Skill, Effect, Times, AccTimes + 1, TempParam3,
						 {AtkSide, AtkUnit2, AtkUnitRevise}, {DefSide, DefUnit2, DefUnitRevise, Num}).

%% 执行单次攻击(连击中单次攻击)
do_exec_attack_single(Battle, InevitableCrit, AtkType, Skill, _Effect, Times, _AccTimes,
					  {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}) ->
%% 	{Hit, Crit}		= {?true, ?false}, % XXX test 必中，必暴
	{Hit, Crit}		= % {?false, ?false}, % XXX test 必闪
		case InevitableCrit of
			?true  -> {?true, ?true};% 必然暴击
			?false -> {battle_mod_calc:calc_hit(Skill, {AtkSide, AtkUnit}, {DefSide, DefUnit}), ?false};% 必不暴击
			?null  ->% 顺其自然
				{
				 battle_mod_calc:calc_hit(Skill, {AtkSide, AtkUnit}, {DefSide, DefUnit}),
				 battle_mod_calc:calc_crit(AtkUnit, DefUnit)
				}
		end,
	Hit2			= case Battle#battle.forbid_dodge of ?false -> Hit; ?true -> ?true end,
	case Hit2 of
		?true ->
			Dodge		= ?false,
			HurtBase	= battle_mod_calc:calc_hurt_base(AtkUnit, DefUnit),							%% 计算基础伤害
			HurtSkill	= battle_mod_calc:calc_skill_ratio(HurtBase, Num, Times, DefUnit#unit.idx, Skill#skill.ratio),%% 计算技能伤害
			HurtCrit	=
				case Crit of
					?true ->
						battle_mod_calc:calc_hurt_crit(HurtSkill, AtkUnit, DefUnit);
					?false -> HurtSkill
				end,
			
			case battle_mod_misc:check_invincible(DefUnit, HurtCrit) of
				{0, ?true} ->
					Crit2		= ?false,
					Parry		= ?false,
					Resist		= ?true,
					HurtFinal	= 0,
					{?ok, Hit2, Dodge, Crit2, Parry, Resist, HurtFinal};
				{HurtInvincible, Invincible} ->
					{HurtImmuneCrit, _Immune, Crit2} =																%% 检测并计算免疫暴击伤害
						battle_mod_misc:check_immune_crit(DefUnit, HurtSkill, Crit, HurtInvincible, Invincible),
%% 					Parry 		= ?true, % XXX test 必档
                    Parry =
						case Battle#battle.forbid_parry of
							?false ->	%% 允许格挡
								battle_mod_calc:calc_parry(AtkUnit, DefUnit);
							?true ->	%% 禁止格挡
								?false
						end,
					HurtParry	=
						case Parry of
							?true ->
								battle_mod_calc:calc_hurt_parry(HurtImmuneCrit, AtkUnit, DefUnit);
							?false ->
								HurtImmuneCrit
						end,
					HurtRandom	    = battle_mod_calc:calc_hurt_random(HurtParry),							%% 计算伤害随机(最终伤害)
%%                     HurtRandom      = HurtParry, % XXX test 不随机
					%% 天赋技能--每次修正伤害--在这里(不保存)
					HurtFinalTemp	= battle_genius_skill:genius_skill_front_revise_hurt({AtkSide, AtkUnit}, {DefSide, DefUnit},
																						 battle_mod_misc:record_genius_param(AtkType, Crit2, HurtRandom, ?false, Parry, Hit2)),
					HurtFinal		= round(battle_mod_calc:calc_skill_plus(HurtFinalTemp, Num, Skill#skill.plus)),
					Resist			= ?true,
					{?ok, Hit2, Dodge, Crit2, Parry, Resist, HurtFinal}
			end;
		?false ->
			Dodge			= ?true,
			Parry			= ?false,
			HurtFinal		= 0,
			Resist			= ?false,
			{?ok, Hit2, Dodge, Crit, Parry, Resist, HurtFinal}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exec_cure_more(Battle, CureRate, Times, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= battle_mod_misc:set_genius_list(Battle, AtkSide, AtkUnit),						%% 设置天赋资格列表
	exec_cure_more2(Battle2, CureRate, Times, Skill, Effect, {AtkUnit, AtkSide, AtkIdx}, {DefSide, DefList, Num}).

exec_cure_more2(Battle, CureRate, Times, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, [DefUnit|DefList], Num}) ->
	Battle2		= do_exec_cure(Battle, Skill, Effect, CureRate, Times, {AtkSide, AtkIdx}, {DefSide, DefUnit, Num}),	
	exec_cure_more2(Battle2, CureRate, Times, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, DefList, Num + 1});
exec_cure_more2(Battle, _CureRate, _Times, _Skill, _Effect, {AtkUnitOld, AtkSide, _AtkIdx}, {_DefSide, [], _Num}) ->
	FlagCrit	= battle_mod_misc:crit_flag(?null),	
	AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnitOld, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	Battle#battle{cmd_atk = AtkCmd}.

do_exec_cure(Battle, Skill, Effect, CureRate, Times, {AtkSide, AtkIdx}, {DefSide, DefUnit, Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	{Battle2, {AtkSide, AtkUnit}, {DefSide, DefUnit2}} =
		do_exec_cure_times(Battle, Skill, Effect, CureRate, Times, 1, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}),
	Battle3		= battle_genius_skill:genius_skill_cure(Battle2, {AtkSide, AtkIdx}, {DefSide, DefUnit2}),
	battle_mod_misc:set_genius_list(Battle3, DefSide, DefUnit2).									%% 设置天赋资格列表

do_exec_cure_times(Battle, Skill, Effect, _CureRate, Times, AccTimes, {AtkSide, AtkUnit}, {DefSide, DefUnit, _Num})
  when AccTimes > Times ->
	{Battle2, DefUnit2} =																			%% 执行命中后技能效果
		exec_skill_middle_hit(Effect#effect.effect_id, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}),
	Battle3		    = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit2),							%%
	{Battle3, {AtkSide, AtkUnit}, {DefSide, DefUnit2}};
do_exec_cure_times(Battle, Skill, Effect, CureRate, Times, AccTimes, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}) ->
	% 最终治疗值 = (基础治疗值 * (天赋系数 + BUFF系数) + 技能附加值) * 随机 * 技能治疗系数----------------志宇确定的
	HpBase		    = battle_mod_calc:calc_cure(AtkUnit, Times, Skill#skill.ratio),
	%% 天赋技能--每次修正治疗值--在这里(不保存)
	FactorGenius    = battle_genius_skill:genius_skill_revise_cure({AtkSide, AtkUnit}, {DefSide, DefUnit}),
	FactorBuff	    = battle_mod_misc:change_cure_effect(DefUnit),
	Factor			= FactorGenius + FactorBuff,
	HpFinalTemp		= HpBase * (?CONST_SYS_NUMBER_TEN_THOUSAND + Factor) div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	HpPlus			= battle_mod_calc:calc_skill_plus(HpFinalTemp, Num, Skill#skill.plus),
	HpRandom		= battle_mod_calc:calc_hurt_random(HpPlus),										%% 计算伤害随机(最终伤害)
	HpFinal			= round(HpRandom * CureRate) div ?CONST_SYS_NUMBER_TEN_THOUSAND,						%% 技能治疗系数
	DefUnit2 	    = battle_mod_misc:plus_hp(DefUnit, HpFinal),
	Battle2		    = battle_mod_misc:set_unit(Battle, DefSide, DefUnit2),
	DefDisplay	    = ?CONST_BATTLE_DISPLAY_NORMAL_DEF2,% battle_mod_misc:display(?true, ?false),	%% 战斗表现类型
	FlagCrit	    = battle_mod_misc:crit_flag(?null),												%% 暴击标记
	DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit2),							%% 属性变化
	DefCmd 		    = battle_mod_misc:cmd_data(AccTimes, DefSide, DefUnit2, FlagCrit, DefDisplay, 0, DefAttrChange, []),
	Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
	do_exec_cure_times(Battle3, Skill, Effect, CureRate, Times, AccTimes + 1, {AtkSide, AtkUnit}, {DefSide, DefUnit2, Num}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_plus_anger_more(Battle, Skill, Effect, AngerBase, {AtkSide, AtkIdx}, {DefSide, DefList, Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= battle_mod_misc:set_genius_list(Battle, AtkSide, AtkUnit),						%% 设置天赋资格列表
	exec_plus_anger_more2(Battle2, Skill, Effect, AngerBase, {AtkSide, AtkIdx}, {DefSide, DefList, Num}).

exec_plus_anger_more2(Battle, Skill, Effect, AngerBase, {AtkSide, AtkIdx}, {DefSide, [DefUnit|DefList], Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= do_plus_anger(Battle, Skill, Effect, AngerBase, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}),
	exec_plus_anger_more2(Battle2, Skill, Effect, AngerBase, {AtkSide, AtkIdx}, {DefSide, DefList, Num});
exec_plus_anger_more2(Battle, _Skill, _Effect, _AngerBase, {AtkSide, AtkIdx}, {_DefSide, [], _Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, ?CONST_BATTLE_CRIT_DEFAULT, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	Battle#battle{cmd_atk = AtkCmd}.

do_plus_anger(Battle, Skill, Effect, AngerBase, {AtkSide, AtkUnit}, {DefSide, DefUnit, _Num}) ->
	DefUnit2		= battle_mod_misc:minus_anger(DefUnit, AngerBase),
	DefDisplay		= ?CONST_BATTLE_DISPLAY_NORMAL_DEF2,% battle_mod_misc:display(?true, ?false),
	FlagCrit		= battle_mod_misc:crit_flag(?null),
	HurtFinal		= 0,
	DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit2),							%% 属性变化
	DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, DefDisplay, HurtFinal, DefAttrChange, []),
	{																								%% 攻击命中后技能效果的处理在这里
	 Battle2, DefUnit3
	}				= exec_skill_middle_hit(Effect#effect.effect_id, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit2}),
	Battle3		    = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),	
	Battle4			= battle_mod_misc:set_genius_list(Battle3, DefSide, DefUnit3),					%% 设置天赋资格列表
	Battle4#battle{cmd_def = [DefCmd|Battle4#battle.cmd_def]}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_minus_anger_more(Battle, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= battle_mod_misc:set_genius_list(Battle, AtkSide, AtkUnit),						%% 设置天赋资格列表
	exec_minus_anger_more2(Battle2, Skill, Effect, {AtkUnit, AtkSide, AtkIdx}, {DefSide, DefList, Num}).

exec_minus_anger_more2(Battle, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, [DefUnit|DefList], Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= do_exec_minus_anger(Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}),
	exec_minus_anger_more2(Battle2, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, DefList, Num + 1});
exec_minus_anger_more2(Battle, Skill, _Effect, {AtkUnitOld, AtkSide, AtkIdx}, {_DefSide, [], _Num}) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkUnit2	= battle_mod_misc:plus_anger(AtkUnit, Skill),
	Battle2		= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
	AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnitOld, ?CONST_BATTLE_CRIT_DEFAULT, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	Battle2#battle{cmd_atk = AtkCmd}.
do_exec_minus_anger(Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit, _Num}) ->
	case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			Anger		= DefUnit#unit.anger * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			DefUnit2	= battle_mod_misc:minus_anger_2(DefUnit, Anger),
			DefDisplay	= ?CONST_BATTLE_DISPLAY_NORMAL_DEF,% battle_mod_misc:display(?true, ?false),
			FlagCrit	= battle_mod_misc:crit_flag(?null),
			HurtFinal	= 0;
		?false ->
			DefUnit2	= DefUnit,
			DefDisplay	= battle_mod_misc:display(?false, ?false),
			FlagCrit	= battle_mod_misc:crit_flag(?null),
			HurtFinal	= 0
	end,
	DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit2),							%% 属性变化
	DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, DefDisplay, HurtFinal, DefAttrChange, []),
	{																								%% 攻击命中后技能效果的处理在这里
	 Battle2, DefUnit3
	}				= exec_skill_middle_hit(Effect#effect.effect_id, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit2}),
	Battle3		    = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),	
	Battle4			= battle_mod_misc:set_genius_list(Battle3, DefSide, DefUnit),					%% 设置天赋资格列表	
	Battle4#battle{cmd_def = [DefCmd|Battle4#battle.cmd_def]}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_minus_anger_more_point(Battle, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, Num}) ->
    AtkUnit     = battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
    Battle2     = battle_mod_misc:set_genius_list(Battle, AtkSide, AtkUnit),                        %% 设置天赋资格列表
    exec_minus_anger_more_point2(Battle2, Skill, Effect, {AtkUnit, AtkSide, AtkIdx}, {DefSide, DefList, Num}).

exec_minus_anger_more_point2(Battle, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, [DefUnit|DefList], Num}) ->
    AtkUnit     = battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
    Battle2     = do_exec_minus_anger_point(Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}),
    exec_minus_anger_more_point2(Battle2, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, DefList, Num + 1});
exec_minus_anger_more_point2(Battle, Skill, _Effect, {AtkUnitOld, AtkSide, AtkIdx}, {_DefSide, [], _Num}) ->
    AtkUnit     = battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
    AtkUnit2    = battle_mod_misc:plus_anger(AtkUnit, Skill),
    Battle2     = battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
    AtkCmd      = battle_mod_misc:cmd_data(0, AtkSide, AtkUnitOld, ?CONST_BATTLE_CRIT_DEFAULT, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
    Battle2#battle{cmd_atk = AtkCmd}.
do_exec_minus_anger_point(Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit, _Num}) ->
    case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        ?true ->
            DefUnit2    = battle_mod_misc:minus_anger_2(DefUnit, Effect#effect.arg3),
            DefDisplay  = ?CONST_BATTLE_DISPLAY_NORMAL_DEF,% battle_mod_misc:display(?true, ?false),
            FlagCrit    = battle_mod_misc:crit_flag(?null),
            HurtFinal   = 0;
        ?false ->
            DefUnit2    = DefUnit,
            DefDisplay  = battle_mod_misc:display(?false, ?false),
            FlagCrit    = battle_mod_misc:crit_flag(?null),
            HurtFinal   = 0
    end,
    DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit2),                          %% 属性变化
    DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, DefDisplay, HurtFinal, DefAttrChange, []),
    {                                                                                               %% 攻击命中后技能效果的处理在这里
     Battle2, DefUnit3
    }               = exec_skill_middle_hit(Effect#effect.effect_id, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit2}),
    Battle3         = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3), 
    Battle4         = battle_mod_misc:set_genius_list(Battle3, DefSide, DefUnit),                   %% 设置天赋资格列表 
    Battle4#battle{cmd_def = [DefCmd|Battle4#battle.cmd_def]}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
exec_install_buff_more(?CONST_SKILL_EFFECT_ID_4, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_4, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit3);
							  ?false ->
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF, 0, [], []),
								  AccBattle#battle{cmd_def = [DefCmd|AccBattle#battle.cmd_def]}
						  end

				  end,
			Battle2		= lists:foldl(Fun, Battle, DefList),
			
			AtkUnit		= battle_mod_misc:get_unit(Battle2, AtkSide, AtkIdx),
			FlagCrit	= battle_mod_misc:crit_flag(?null),
			AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
			Battle2#battle{cmd_atk = AtkCmd};
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
exec_install_buff_more(?CONST_SKILL_EFFECT_ID_5, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_5, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit3);
							  ?false ->
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF, 0, [], []),
								  AccBattle#battle{cmd_def = [DefCmd|AccBattle#battle.cmd_def]}
						  end

				  end,
			Battle2		= lists:foldl(Fun, Battle, DefList),
			
			AtkUnit		= battle_mod_misc:get_unit(Battle2, AtkSide, AtkIdx),
			FlagCrit	= battle_mod_misc:crit_flag(?null),
			AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
			Battle2#battle{cmd_atk = AtkCmd};
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
exec_install_buff_more(?CONST_SKILL_EFFECT_ID_133, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{BuffList1, BuffList2}		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_133, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
	{TargetSide, TargetType}	= Effect#effect.arg1,
	Battle2		=
		case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
			{DefSide, DefList} ->
				Fun	= fun(DefUnit, AccBattle) ->
							  %% 加BUFF
							  {
							   AccBattle2, DefUnit2, BuffDelete, BuffInsert
							  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList1, DefUnit),
							  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
							  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
							  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
							  FlagCrit		    = battle_mod_misc:crit_flag(?null),
							  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF2, 0, AttrChangeList, BuffChangeList),
							  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
							  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit3)
					  end,
				lists:foldl(Fun, Battle, DefList);
			?null -> Battle
		end,
	{TargetSide2, TargetType2}	= Effect#effect.arg4,
	Battle3		=
		case battle_mod_target:target(Battle2, AtkSide, AtkIdx, TargetSide2, TargetType2) of
			{DefSide2, DefList2} ->
				Fun2	= fun(DefUnit, AccBattle) ->
							  %% 加BUFF
							  {
							   AccBattle2, DefUnit2, BuffDelete, BuffInsert
							  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList2, DefUnit),
							  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
							  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
							  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
							  FlagCrit		    = battle_mod_misc:crit_flag(?null),
							  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide2, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF2, 0, AttrChangeList, BuffChangeList),
							  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
							  battle_mod_misc:set_unit(AccBattle3, DefSide2, DefUnit3)
					  end,
				lists:foldl(Fun2, Battle2, DefList2);
			?null -> Battle2
		end,
	AtkUnit		= battle_mod_misc:get_unit(Battle3, AtkSide, AtkIdx),
	FlagCrit	= battle_mod_misc:crit_flag(?null),
	AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	Battle3#battle{cmd_atk = AtkCmd}.

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
%% CONST_SKILL_EFFECT_ID_37		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
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
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合  
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
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_1		技能效果ID--对目标[arg1]常规攻击(连续技)
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_1, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_2, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_3, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_4, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_5, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_11, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_12, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_13, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_14, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_15, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_20, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_21, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_22, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_23, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_24, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_25, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_26, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_27, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_28, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_29, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_30, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_31, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_32, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_33, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_34, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_35, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_36, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_37, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_38, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_51, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_52, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_53, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_54, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_61, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_62, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_63, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_64, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_65, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_66, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_67, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_81, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_82, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_83, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_84, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_85, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_86, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_87, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_91, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_92, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_93, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_94, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_95, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_96, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合   
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_97, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_101, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, _AttrBaseSecond, AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Effect#effect.arg1,
    Crit        = AttrBaseElite#attr_elite.crit,
    DValue      = Crit * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2	= AtkUnit#unit{attr = Attr},	
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_102, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(AtkUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Effect#effect.arg1,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	{{AtkSide, AtkUnit}, {DefSide, DefUnit2}};
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_103, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(AtkUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Effect#effect.arg1,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	{{AtkSide, AtkUnit}, {DefSide, DefUnit2}};
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_104, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(AtkUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Effect#effect.arg1,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	{{AtkSide, AtkUnit}, {DefSide, DefUnit2}};
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_105, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(AtkUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Effect#effect.arg1,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	{{AtkSide, AtkUnit}, {DefSide, DefUnit2}};
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_106, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Effect#effect.arg1,
    Def			= AttrBaseSecond#attr_second.force_def + AttrBaseSecond#attr_second.magic_def,
    DValue      = Def * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2	= AtkUnit#unit{attr = Attr},	
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_107, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, _AttrBaseSecond, AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Effect#effect.arg1,
    Crit        = AttrBaseElite#attr_elite.crit,
    DValue      = Crit * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2	= AtkUnit#unit{attr = Attr},	
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_108, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Effect#effect.arg1,
    Def			= AttrBaseSecond#attr_second.force_def + AttrBaseSecond#attr_second.magic_def,
    DValue      = Def * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2	= AtkUnit#unit{attr = Attr},	
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_109, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Effect#effect.arg1,
    Def			= AttrBaseSecond#attr_second.force_def + AttrBaseSecond#attr_second.magic_def,
    DValue      = Def * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2	= AtkUnit#unit{attr = Attr},	
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_111, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_112, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_113, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
    {{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_121, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_131, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_132, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_133, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_134, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
    {{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_151, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_152, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_153, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_154, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_155, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_156, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{
     _AttrBase, _AttrBaseSecond, AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Effect#effect.arg1,
    Crit        = AttrBaseElite#attr_elite.crit,
    DValue      = Crit * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2    = AtkUnit#unit{attr = Attr},    
    {{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_157, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(AtkUnit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Effect#effect.arg1,
    Def         = AttrBaseSecond#attr_second.force_def + AttrBaseSecond#attr_second.magic_def,
    DValue      = Def * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2    = AtkUnit#unit{attr = Attr},    
    {{AtkSide, AtkUnit2}, {DefSide, DefUnit}};
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_158, _Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
    {
     _AttrBase, AttrBaseSecond, AttrBaseElite
    }               = battle_mod_misc:get_unit_attr_base(AtkUnit),
    TypeForceDef    = ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Effect#effect.arg1,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,

    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value2       = Effect#effect.arg2,
    Crit        = AttrBaseElite#attr_elite.crit,
    DValue      = Crit * Value2 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(AtkUnit#unit.attr, Type, DValue),
    AtkUnit2    = AtkUnit#unit{attr = Attr},    

    Attr2            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2        = DefUnit#unit{attr = Attr2},
    {{AtkSide, AtkUnit2}, {DefSide, DefUnit2}};
%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff
revise_unit_skill_effect(?CONST_SKILL_EFFECT_ID_159, _Skill, _Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
%% Local Functions
%%

%% 攻击完成命中后执行
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
%% CONST_SKILL_EFFECT_ID_37		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
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
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
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
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_EFFECT_ID_1		技能效果ID--对目标[arg1]常规攻击(连续技)
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_1, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_2, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_3, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_4, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_5, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_11, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_12, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_13, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_14, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_15, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_20, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_21, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_22, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_23, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_24, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_25, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_26, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_27, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_28, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_29, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_30, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_31, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_32, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_33, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_34, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_35, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_36, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_37, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
    {Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_38, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
    {Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_51, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_51, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_52, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_52, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_53, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_53, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_54, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_54, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_61, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_62, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_63, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_64, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_65, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_66, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_67, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_81, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_82, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_83, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_84, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_85, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_86, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_87, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_91, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_91, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_92, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_92, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_93, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_93, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_94, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_94, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_95, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_95, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_96, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_96, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_97, Battle, Skill, Effect, {_, AtkUnit}, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
            HpBase          = battle_mod_calc:calc_hurt_base(AtkUnit, DefUnit),
            HpFinal         = battle_mod_calc:calc_hurt_random(HpBase),
            HpMinus         = HpFinal * Effect#effect.arg4 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
            Effect2         = Effect#effect{arg4 = HpMinus},
            BuffList        = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_97, Skill, Effect2, ?CONST_BATTLE_STEP_MIDDLE),
            
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> 
            {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_101, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_102, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_103, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_103, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_104, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_105, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_106, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_107, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_108, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_109, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_111, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_112, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_113, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
    {Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_121, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_131, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_132, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_132, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_133, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_134, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        ?true ->
            BuffList        = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_134, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
            %% 加BUFF
            {
             Battle2, DefUnit2, BuffDelete, BuffInsert
            }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
            DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
            FlagCrit        = battle_mod_misc:crit_flag(?null),
            DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
            DefBuffChange   = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),             %% BUFF变化
            DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
            Battle3         = Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
            {Battle3, DefUnit3};
        ?false -> {Battle, DefUnit}
    end;
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_151, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_151, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_152, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_152, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_153, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_154, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_154, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_155, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_155, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			DefBuffChange	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),				%% BUFF变化
			DefCmd 		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
			Battle3			= Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
			{Battle3, DefUnit3};
		?false -> {Battle, DefUnit}
	end;
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_156, Battle, Skill, Effect, _Atk, {DefSide, DefUnit}) ->
	case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        ?true ->
            BuffList        = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_156, Skill, Effect, ?CONST_BATTLE_STEP_MIDDLE),
            %% 加BUFF
            {
             Battle2, DefUnit2, BuffDelete, BuffInsert
            }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
            DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
            FlagCrit        = battle_mod_misc:crit_flag(?null),
            DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
            DefBuffChange   = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),             %% BUFF变化
            DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_MIDDLE, 0, DefAttrChange, DefBuffChange),
            Battle3         = Battle2#battle{cmd_def = [DefCmd|Battle2#battle.cmd_def]},
            {Battle3, DefUnit3};
        ?false -> {Battle, DefUnit}
    end;
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_157, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
    {Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_158, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
    {Battle, DefUnit};
%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff 
exec_skill_middle_hit(?CONST_SKILL_EFFECT_ID_159, Battle, _Skill, _Effect, _Atk, {_DefSide, DefUnit}) ->
	{Battle, DefUnit}.
