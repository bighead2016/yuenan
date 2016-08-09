%% Author: cobain
%% Created: 2012-10-17
%% Description: TODO: Add description to battle_skill_back
-module(battle_skill_back).

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
-export([exec_skill_back/6]).

%%
%% API Functions
%%




%% 攻击完成无论是否命中执行
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
%% Effect2	= Effect#effect{arg2 = Times, arg3 = Target, arg4 = BuffId, arg5 = BuffValue, arg6 = BuffBout},
exec_skill_back(?CONST_SKILL_EFFECT_ID_1, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg3,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_1, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  %% 加BUFF
						  {
						   AccBattle2, DefUnit2, BuffDelete, BuffInsert
						  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
						  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
						  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
						  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
						  FlagCrit		    = battle_mod_misc:crit_flag(?null),
						  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
						  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
						  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
						  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3)
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_2, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
exec_skill_back(?CONST_SKILL_EFFECT_ID_3, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType} = Effect#effect.arg1,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			exec_uninstall_buff_more(?CONST_SKILL_EFFECT_ID_3, Battle, Skill, Effect, 
									 {AtkSide, AtkIdx}, {DefSide, DefList, Effect#effect.arg2}, ?CONST_BUFF_NATURE_NEGATIVE);
		?null -> 
			Battle
	end;
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_4, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_5, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_11, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_12, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
			HpBase		= battle_mod_calc:calc_cure(AtkUnit, Effect#effect.arg2, Skill#skill.ratio),
			HpPlus		= HpBase * Effect#effect.arg6 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Effect2		= Effect#effect{arg6 = HpPlus},
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_12, Skill, Effect2, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_13, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_13, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false ->
								  AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_14, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			AtkUnit	= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
			Fun	= fun(DefUnit, AccBattle) ->
						  HpBase			= battle_mod_calc:calc_hurt_base(AtkUnit, DefUnit),
						  HpFinal	    	= battle_mod_calc:calc_hurt_random(HpBase),
						  HpMinus			= HpFinal * Effect#effect.arg5 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
						  Effect2			= Effect#effect{arg5 = HpMinus},
                          
						  BuffList	= 
                              case battle_mod_calc:calc_hit(Skill, {0, AtkUnit}, {1, DefUnit}) of
                                  ?true ->
                                      battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_14, Skill, Effect2, ?CONST_BATTLE_STEP_BACK);
                                  ?false ->
                                      []
                              end,
						  %% 加BUFF
						  {
						   AccBattle2, DefUnit2, BuffDelete, BuffInsert
						  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
						  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
						  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
						  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
						  FlagCrit		    = battle_mod_misc:crit_flag(?null),
						  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
						  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
						  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
						  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3)
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_15, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_15, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
exec_skill_back(?CONST_SKILL_EFFECT_ID_20, Battle, _Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 增加怒气
								  Anger				= DefUnit#unit.anger * Effect#effect.arg5 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
								  DefUnit2			= battle_mod_misc:minus_anger_2(DefUnit, Anger),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit2),
								  BuffChangeList    = [],
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle2	    = AccBattle#battle{cmd_def = [DefCmd|AccBattle#battle.cmd_def]},
								  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnit2),
								  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit2);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
exec_skill_back(?CONST_SKILL_EFFECT_ID_21, Battle, _Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 增加怒气
								  DefUnit2			= battle_mod_misc:plus_anger(DefUnit, Effect#effect.arg5),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit2),
								  BuffChangeList    = [],
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle2	    = AccBattle#battle{cmd_def = [DefCmd|AccBattle#battle.cmd_def]},
								  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnit2),
								  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit2);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_22, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_22, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_23, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_23, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_24, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_24, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_25, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_25, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_26, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_26, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_27, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_27, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_28, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_28, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_29, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_29, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_30, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_30, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_31, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_31, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_32, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_32, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_33, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_33, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_34, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_34, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
exec_skill_back(?CONST_SKILL_EFFECT_ID_35, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_35, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_36, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_36, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_37     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_37, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg4,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        {DefSide, DefList} ->
            BuffList    = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_37, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
            Fun = fun(DefUnit, AccBattle) ->
                          case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                              ?true ->
                                  %% 加BUFF
                                  {
                                   AccBattle2, DefUnit2, BuffDelete, BuffInsert
                                  }                 = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
                                  DefUnit3          = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
                                  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                  FlagCrit          = battle_mod_misc:crit_flag(?null),
                                  DefCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
                                  AccBattle3        = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
                                  AccBattle4        = battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
                                  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
                              ?false -> AccBattle
                          end
                  end,
            lists:foldl(Fun, Battle, DefList);
        ?null -> Battle
    end;
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_38, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg4,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        {DefSide, DefList} ->
            BuffList    = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_38, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
            Fun = fun(DefUnit, AccBattle) ->
                          case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                              ?true ->
                                  %% 加BUFF
                                  {
                                   AccBattle2, DefUnit2, BuffDelete, BuffInsert
                                  }                 = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
                                  DefUnit3          = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
                                  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                  FlagCrit          = battle_mod_misc:crit_flag(?null),
                                  DefCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
                                  AccBattle3        = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
                                  AccBattle4        = battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
                                  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
                              ?false -> AccBattle
                          end
                  end,
            lists:foldl(Fun, Battle, DefList);
        ?null -> Battle
    end;
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_51, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_52, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_53, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_54, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_61, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_61, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_62, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_62, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_63, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_63, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true -> 
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_64, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_64, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_65, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_65, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_66, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_66, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_67, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_67, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
exec_skill_back(?CONST_SKILL_EFFECT_ID_81, Battle, _Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 降低怒气
								  DefUnit2			= battle_mod_misc:minus_anger_2(DefUnit, Effect#effect.arg5),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit2),
								  BuffChangeList    = [],
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle2	    = AccBattle#battle{cmd_def = [DefCmd|AccBattle#battle.cmd_def]},
								  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnit2),
								  battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnit2);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_82, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  HpMinus			= DefUnit#unit.hp * Effect#effect.arg5 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
								  Effect2			= Effect#effect{arg5 = HpMinus},
								  BuffList			= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_82, Skill, Effect2, ?CONST_BATTLE_STEP_BACK),
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_83, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_83, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_84, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_84, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_85, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_85, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_86, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_86, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_87, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_87, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_91, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_92, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_93, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_94, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_95, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_96, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合   
exec_skill_back(?CONST_SKILL_EFFECT_ID_97, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_101, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_102, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_103, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_104, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_104, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_105, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_105, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_106, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_107, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_107, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_108, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_108, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_109, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_109, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_111, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_112, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg7,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_112, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg6, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_113, Battle, Skill, Effect, AtkSide, AtkIdx) ->
    {TargetSide, TargetType}    = Effect#effect.arg4,
    case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
        {DefSide, DefList} ->
            AtkUnit = battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
            Fun = fun(DefUnit, AccBattle) ->
                          HpBase            = battle_mod_calc:calc_hurt_base(AtkUnit, DefUnit),
                          HpFinal           = battle_mod_calc:calc_hurt_random(HpBase),
                          HpMinus           = HpFinal * Effect#effect.arg5 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
                          Effect2           = Effect#effect{arg5 = HpMinus},
                          BuffList          = battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_14, Skill, Effect2, ?CONST_BATTLE_STEP_BACK),
                          
                          case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                              ?true ->
                                  %% 加BUFF
                                  {
                                   AccBattle2, DefUnit2, BuffDelete, BuffInsert
                                  }                 = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
                                  DefUnit3          = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
                                  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                  FlagCrit          = battle_mod_misc:crit_flag(?null),
                                  DefCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
                                  AccBattle3        = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
                                  AccBattle4        = battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
                                  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
                              ?false -> AccBattle
                          end
                  end,
            lists:foldl(Fun, Battle, DefList);
        ?null -> Battle
    end;
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_121, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_131, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_131, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_132, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_133, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
	Battle;
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_134, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
    Battle;
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_151, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg7,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_151, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg6, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_152, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg7,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_152, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg6, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_153, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{BuffList1, BuffList2}		= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_153, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
	{TargetSide1, TargetType1}	= Effect#effect.arg4,
	Battle2	=
		case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide1, TargetType1) of
			{DefSide1, DefList1} ->
				Fun1	= fun(DefUnit, AccBattle) ->
								  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
									  ?true ->
										  %% 加BUFF
										  {
										   AccBattle2, DefUnit2, BuffDelete, BuffInsert
										  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList1, DefUnit),
										  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
										  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
										  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
										  FlagCrit		    = battle_mod_misc:crit_flag(?null),
										  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide1, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
										  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
										  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide1, DefUnit3),
										  battle_mod_misc:set_unit(AccBattle4, DefSide1, DefUnit3);
									  ?false -> AccBattle
								  end
						  end,
				lists:foldl(Fun1, Battle, DefList1);
			?null -> Battle
		end,
	{TargetSide2, TargetType2}	= Effect#effect.arg8,
	case battle_mod_target:target(Battle2, AtkSide, AtkIdx, TargetSide2, TargetType2) of
		{DefSide2, DefList2} ->
			Fun2	= fun(DefUnit, AccBattle) ->
							  case misc_random:odds(Effect#effect.arg7, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
								  ?true ->
									  %% 加BUFF
									  {
									   AccBattle2, DefUnit2, BuffDelete, BuffInsert
									  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList2, DefUnit),
									  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
									  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
									  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
									  FlagCrit		    = battle_mod_misc:crit_flag(?null),
									  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide2, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
									  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
									  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide2, DefUnit3),
									  battle_mod_misc:set_unit(AccBattle4, DefSide2, DefUnit3);
								  ?false -> AccBattle
							  end
					  end,
			lists:foldl(Fun2, Battle2, DefList2);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_154, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg6,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_154, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg5, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_155, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_155, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
exec_skill_back(?CONST_SKILL_EFFECT_ID_156, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType}	= Effect#effect.arg5,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			BuffList	= battle_mod_buff:skill_effect_buff(?CONST_SKILL_EFFECT_ID_156, Skill, Effect, ?CONST_BATTLE_STEP_BACK),
			Fun	= fun(DefUnit, AccBattle) ->
						  case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
							  ?true ->
								  %% 加BUFF
								  {
								   AccBattle2, DefUnit2, BuffDelete, BuffInsert
								  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnit),
								  DefUnit3		    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
								  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),
								  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
								  FlagCrit		    = battle_mod_misc:crit_flag(?null),
								  DefCmd		    = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_BUFF_BACK, 0, AttrChangeList, BuffChangeList),
								  AccBattle3	    = AccBattle2#battle{cmd_def = [DefCmd|AccBattle2#battle.cmd_def]},
								  AccBattle4		= battle_mod_misc:set_genius_list(AccBattle3, DefSide, DefUnit3),
								  battle_mod_misc:set_unit(AccBattle4, DefSide, DefUnit3);
							  ?false -> AccBattle
						  end
				  end,
			lists:foldl(Fun, Battle, DefList);
		?null -> Battle
	end;
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
exec_skill_back(?CONST_SKILL_EFFECT_ID_157, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
    Battle;
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
exec_skill_back(?CONST_SKILL_EFFECT_ID_158, Battle, _Skill, _Effect, _AtkSide, _AtkIdx) ->
    Battle;

%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff
exec_skill_back(?CONST_SKILL_EFFECT_ID_159, Battle, Skill, Effect, AtkSide, AtkIdx) ->
	{TargetSide, TargetType} = Effect#effect.arg4,
	case battle_mod_target:target(Battle, AtkSide, AtkIdx, TargetSide, TargetType) of
		{DefSide, DefList} ->
			case misc_random:odds(Effect#effect.arg3, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					exec_uninstall_buff_more(?CONST_SKILL_EFFECT_ID_159, Battle, Skill, Effect, 
											 {AtkSide, AtkIdx}, {DefSide, DefList, Effect#effect.arg5}, ?CONST_BUFF_NATURE_POSITIVE);
				?false ->
					Battle
			end;
		?null ->
			Battle
	end.
%%
%% Local Functions
%%
%% 去除buff
exec_uninstall_buff_more(EffecId, Battle, Skill, Effect, {AtkSide, AtkIdx}, {DefSide, DefList, Num}, BuffType) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	exec_uninstall_buff_more2(EffecId, Battle, Skill, Effect, {AtkUnit, AtkSide, AtkIdx}, {DefSide, DefList, Num}, BuffType).

exec_uninstall_buff_more2(EffecId, Battle, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, [DefUnit|DefList], Num}, BuffType) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	Battle2		= do_exec_uninstall_buff(EffecId, Battle, Skill, Effect, {AtkSide, AtkUnit}, {DefSide, DefUnit, Num}, BuffType),
	exec_uninstall_buff_more2(EffecId, Battle2, Skill, Effect, {AtkUnitOld, AtkSide, AtkIdx}, {DefSide, DefList, Num}, BuffType);
exec_uninstall_buff_more2(_EffecId, Battle, Skill, _Effect, {AtkUnitOld, AtkSide, AtkIdx}, {_DefSide, [], _Num}, _BuffType) ->
	AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkUnit2	= battle_mod_misc:plus_anger(AtkUnit, Skill),
	FlagCrit	= battle_mod_misc:crit_flag(?null),
	Battle2		= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
	AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnitOld, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_ATK, 0, [], []),
	Battle2#battle{cmd_atk = AtkCmd}.

do_exec_uninstall_buff(_EffecId, Battle, _Skill, _Effect, {_AtkSide, _AtkUnit}, {DefSide, DefUnit, Num}, BuffType) ->
	{
	 DefUnit2, BuffDelete
	}				= do_exec_uninstall_buff(DefUnit, DefUnit#unit.buff, Num, [], [], BuffType),
	FlagCrit		= battle_mod_misc:crit_flag(?null),
	DefDisplay		= battle_mod_misc:display(?true, ?false),
	HurtFinal		= 0,
	AttrChangeList	= battle_mod_misc:attr_change_data(DefUnit, DefUnit2),
	BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, []),
	DefCmd			= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, DefDisplay, HurtFinal, AttrChangeList, BuffChangeList),
    Battle2         = battle_mod_misc:set_unit(Battle, DefSide, DefUnit2),
	Battle2#battle{cmd_def = [DefCmd|Battle#battle.cmd_def]}.

do_exec_uninstall_buff(Unit, BuffList, Count, AccBuff, AccBuffDelete, _BuffType) when Count =< 0 ->
	BuffListNew		= misc:list_merge(BuffList, AccBuff),
	Unit2			= Unit#unit{buff = BuffListNew},
	{Unit2, AccBuffDelete};
do_exec_uninstall_buff(Unit, [Buff|BuffList], Count, AccBuff, AccBuffDelete, BuffType) when Buff#buff.nature =:= BuffType ->
	Unit2			= battle_mod_buff:buff_uninstall(Unit, Buff),
	do_exec_uninstall_buff(Unit2, BuffList, Count - 1, AccBuff, [Buff|AccBuffDelete], BuffType);
do_exec_uninstall_buff(Unit, [Buff|BuffList], Count, AccBuff, AccBuffDelete, BuffType) ->
	do_exec_uninstall_buff(Unit, BuffList, Count, [Buff|AccBuff], AccBuffDelete, BuffType);
do_exec_uninstall_buff(Unit, [], _Count, AccBuff, AccBuffDelete, _BuffType) ->
	Unit2			= Unit#unit{buff = AccBuff},
	{Unit2, AccBuffDelete}.