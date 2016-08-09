%% Author: cobain
%% Created: 2012-11-20
%% Description: TODO: Add description to battle_mod_buff
-module(battle_mod_buff).

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
-export([trigger_buff_bout/3, trigger_buff_plus_anger/1, trigger_buff_revise_attr/2]).
-export([skill_effect_buff/4, genius_skill_effect_buff/4,
		 buff_install/3, buff_uninstall/2]).

%%
%% API Functions
%%

%% BUFF触发--回合 
trigger_buff_bout(EnlargeRate, Unit, Buff = #buff{trigger = Trigger}) when Trigger =:= ?CONST_BUFF_TRIGGER_BOUT ->
    battle_mod_buff:buff_install(EnlargeRate, Unit, Buff#buff{install_point = ?CONST_BUFF_INSTALL_POINT_BOUT});
trigger_buff_bout(_EnlargeRate, Unit, _Buff) ->
    Unit.

%% BUFF触发--恢复怒气
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
trigger_buff_plus_anger(Unit) ->
	trigger_buff_plus_anger(Unit, Unit#unit.buff, 0).
%% CONST_BUFF_TYPE_42	BUFF类型--增加X%怒气恢复效果持续N回合
trigger_buff_plus_anger(Unit, [Buff = #buff{buff_type = ?CONST_BUFF_TYPE_42}|BuffList], AccFactor) ->
	trigger_buff_plus_anger(Unit, BuffList, AccFactor + Buff#buff.buff_value);
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
trigger_buff_plus_anger(Unit, [Buff = #buff{buff_type = ?CONST_BUFF_TYPE_52}|BuffList], AccFactor) ->
	trigger_buff_plus_anger(Unit, BuffList, AccFactor - Buff#buff.buff_value);
trigger_buff_plus_anger(Unit, [_Buff|BuffList], AccFactor) ->
	trigger_buff_plus_anger(Unit, BuffList, AccFactor);
trigger_buff_plus_anger(_Unit, [], AccFactor) -> AccFactor.

%% BUFF触发--攻击|防守
trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{{AtkSide, AtkUnit2}, {DefSide, DefUnit2}} =
		trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit}, AtkUnit#unit.buff, ?CONST_BUFF_TRIGGER_ATK),
	{{AtkSide, AtkUnit3}, {DefSide, DefUnit3}} =
		trigger_buff_revise_attr({AtkSide, AtkUnit2}, {DefSide, DefUnit2}, DefUnit2#unit.buff, ?CONST_BUFF_TRIGGER_DEF),
	{{AtkSide, AtkUnit3}, {DefSide, DefUnit3}}.

trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 [Buff = #buff{buff_id = ?CONST_BUFF_TYPE_101, trigger = Trigger}|BuffList],
						 Trigger) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(DefUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit2}, BuffList, Trigger);
trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 [Buff = #buff{buff_id = ?CONST_BUFF_TYPE_102, trigger = Trigger}|BuffList],
						 Trigger) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(DefUnit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    Value           = Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit2}, BuffList, Trigger);
trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 [Buff = #buff{buff_id = ?CONST_BUFF_TYPE_103, trigger = Trigger}|BuffList],
						 Trigger) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(DefUnit),
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value           = Buff#buff.buff_value,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeMagicDef, - DValueMagicDef}]),
    DefUnit2	    = DefUnit#unit{attr = Attr},
	trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit2}, BuffList, Trigger);
trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 [_Buff|BuffList], Trigger) ->
	trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 BuffList, Trigger);
trigger_buff_revise_attr({AtkSide, AtkUnit}, {DefSide, DefUnit},
						 [], _Trigger) ->
	{{AtkSide, AtkUnit}, {DefSide, DefUnit}}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_BUFF_TRIGGER_NORMAL       BUFF触发--默认 
%% CONST_BUFF_TRIGGER_BOUT         BUFF触发--回合 
%% CONST_BUFF_TRIGGER_ATK          BUFF触发--攻击 
%% CONST_BUFF_TRIGGER_DEF          BUFF触发--防守 
%% CONST_BUFF_TRIGGER_CURE         BUFF触发--治疗 
%% CONST_BUFF_TRIGGER_PLUS_ANGER   BUFF触发--增加怒气 
%% CONST_BUFF_TRIGGER_MINUS_ANGER  BUFF触发--减少怒气 
%% CONST_BUFF_TRIGGER_BUFF         BUFF触发--BUFF 
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
skill_effect_buff(?CONST_SKILL_EFFECT_ID_1, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(Effect#effect.arg4),% BUFF类型--自定义
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,     	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_2		技能效果ID--对目标[arg1]常规攻击[arg2]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_2, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_3		技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF
skill_effect_buff(?CONST_SKILL_EFFECT_ID_3, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_4		技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_4, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_63),% BUFF类型--附加眩晕持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg3               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_5		技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_5, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_32),% BUFF类型--降低X%闪避持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg3,      		    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_11		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_11, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_12		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_12, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_43),% BUFF类型--增加X点生命持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg6,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,     	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_13		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_13, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_8),% BUFF类型--增加X%速度持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg6,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_14		技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_14, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_53),% BUFF类型--降低X点生命持续N回合(中毒)
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_15     技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_15, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--附加沉默持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_20     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气
skill_effect_buff(?CONST_SKILL_EFFECT_ID_20, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_21		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气
skill_effect_buff(?CONST_SKILL_EFFECT_ID_21, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_22		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_22, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_1),% BUFF类型--增加X%生命上限持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6              	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_23		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_23, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_2),% BUFF类型--增加X%攻击力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_24		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_24, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_3),% BUFF类型--增加X%物理攻击力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_25		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_25, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_4),% BUFF类型--增加X%法术攻击力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_26		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_26, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_5),% BUFF类型--增加X%防御力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_27		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_27, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_28		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_28, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_7),% BUFF类型--增加X%法术防御力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_29		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_29, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_8),% BUFF类型--增加X%速度持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,      	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_30		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_30, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_21),% BUFF类型--增加X%命中持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_31		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_31, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_22),% BUFF类型--增加X%闪避持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_32		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_32, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_23),% BUFF类型--增加X%暴击持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_33		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_33, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_24),% BUFF类型--增加X%招架持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_34		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_34, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_25),% BUFF类型--增加X%反击持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_35		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_35, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_92),% BUFF类型--附加N回合后必然暴击
			Buff        = BuffTemp#buff{
										buff_value      = 0,							    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5,              	%% 消耗值
										arg1			= ?false							%% 参数1[是否已暴击]
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_36		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_36, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp1   = buff_api:get_buff(?CONST_BUFF_TYPE_1),% BUFF类型--增加X%生命上限持续N回合
			Buff1       = BuffTemp1#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			BuffTemp2   = buff_api:get_buff(?CONST_BUFF_TYPE_93),% BUFF类型--附加免疫暴击持续N回合
			Buff2       = BuffTemp2#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff1, Buff2]
	end;
%% CONST_SKILL_EFFECT_ID_37		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_37, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp1   = buff_api:get_buff(?CONST_BUFF_TYPE_23),% BUFF类型--增加X%暴击持续N回合
			Buff1       = BuffTemp1#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			BuffTemp2   = buff_api:get_buff(?CONST_BUFF_TYPE_24),% BUFF类型--格档
			Buff2       = BuffTemp2#buff{
										buff_value      = Effect#effect.arg6,           	%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff1, Buff2]
	end;
%% CONST_SKILL_EFFECT_ID_38     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_38, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp1   = buff_api:get_buff(?CONST_BUFF_TYPE_23),% BUFF类型--增加X%暴击持续N回合
			Buff1       = BuffTemp1#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			BuffTemp2   = buff_api:get_buff(?CONST_BUFF_TYPE_27),% BUFF类型--增加X%招架持续N回合
			Buff2       = BuffTemp2#buff{
										buff_value      = Effect#effect.arg6,           	%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff1, Buff2]
	end;
%% CONST_SKILL_EFFECT_ID_51		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_51, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--附加沉默持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_52		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_52, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--附加封印持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_53		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率眩晕[arg4]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_53, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_63),% BUFF类型--附加眩晕持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_54		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_54, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_94),% BUFF类型--附加暴击无效持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_61		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_61, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--附加沉默持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_62		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_62, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--附加封印持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_63		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_63, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_63),% BUFF类型--附加眩晕持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_64		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_64, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_82),% BUFF类型--附加X%吸血效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_65		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_65, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_81),% BUFF类型--附加无敌效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_66		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_66, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_93),% BUFF类型--附加免疫暴击持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_67		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_67, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_73),% BUFF类型--附加免疫眩晕持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_81		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气
skill_effect_buff(?CONST_SKILL_EFFECT_ID_81, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_82		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_82, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_54),% BUFF类型--降低X点生命持续N回合(中毒)
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_83		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_83, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_16),% 降低X%物理防御力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_84		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_84, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_13),% BUFF类型--降低X%物理攻击力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_85     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_85, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_18),% BUFF类型--降低X%速度持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_86		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_86, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_32),% BUFF类型--降低X%闪避持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_87     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[arg6]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_87, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_14),% BUFF类型--降低X%闪避持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_91		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_91, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_11),% BUFF类型--降低X%生命上限持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_92		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_92, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_16),% BUFF类型--降低X%物理防御力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_93		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_93, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_52),% BUFF类型--降低X%怒气恢复效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_PLUS_ANGER,   %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_94		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_94, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_95		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_95, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_17),% BUFF类型--降低X%法术防御力持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end; 
%% CONST_SKILL_EFFECT_ID_96		技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_96, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_18),% BUFF类型--降低X%速度持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_97     技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_97, _Skill, Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE -> 
            BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_55),% BUFF类型--降低X点生命持续N回合(燃烧)
            Buff        = BuffTemp#buff{
                                        buff_value      = Effect#effect.arg4,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg5                %% 消耗值
                                       },
            [Buff];
        ?CONST_BATTLE_STEP_BACK -> []
    end;
%% CONST_SKILL_EFFECT_ID_101	技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_101, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_102	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_102, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_103	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_103, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--附加封印持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,			    				%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_104	技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_104, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--附加封印持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,			    				%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_105    技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_105, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--附加沉默持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,			    				%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_106    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_106, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_EFFECT_ID_107    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_107, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--附加沉默持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,			    				%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_108	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_108, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg6,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_109	技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_109, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_24),% BUFF类型--增加X%招架持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg6,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_111	技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_111, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_82),% BUFF类型--附加X%吸血效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg2,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg3               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_112    技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_112, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_82),% BUFF类型--附加X%吸血效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg2,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg3               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_81),% BUFF类型--附加无敌效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg8               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_113    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_113, _Skill, Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE -> [];
        ?CONST_BATTLE_STEP_BACK ->
            BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_53),% BUFF类型--降低X点生命持续N回合(中毒)
            Buff        = BuffTemp#buff{
                                        buff_value      = Effect#effect.arg5,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg6                %% 消耗值
                                       },
            [Buff]
    end;
%% CONST_SKILL_EFFECT_ID_121	技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_121, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_23),% BUFF类型--增加X%暴击持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg2,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg3               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_131	技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_131, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--附加封印持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = 0,           					    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_132	技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_132, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_133	技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_133, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp1   = buff_api:get_buff(?CONST_BUFF_TYPE_7),% BUFF类型--增加X%法术防御力持续N回合
			Buff1       = BuffTemp1#buff{
										buff_value      = Effect#effect.arg2,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg3               	%% 消耗值
									   },
			BuffTemp2   = buff_api:get_buff(?CONST_BUFF_TYPE_101),% BUFF类型--增加X%法术防御力持续N回合
			Buff2       = BuffTemp2#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_ATK,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg6               	%% 消耗值
									   },
			{[Buff1], [Buff2]};
		?CONST_BATTLE_STEP_BACK -> []
	end;
%% CONST_SKILL_EFFECT_ID_134    技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_134, _Skill, Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE ->
            BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合
            Buff        = BuffTemp#buff{
                                        buff_value      = Effect#effect.arg5,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg6                %% 消耗值
                                       },
            [Buff];
        ?CONST_BATTLE_STEP_BACK -> []
    end;
%% CONST_SKILL_EFFECT_ID_151	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_151, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_26),% BUFF类型--增加X%降低暴击持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg8,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg9               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_152	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_152, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg4,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg5               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_3),% BUFF类型--增加X%物理攻击力持续N回合
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg8,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg9               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_153	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_153, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp1   = buff_api:get_buff(?CONST_BUFF_TYPE_15),% BUFF类型--降低X%防御力持续N回合
			Buff1       = BuffTemp1#buff{
										 buff_value      = Effect#effect.arg5,			    %% 值
										 
										 source          = ?CONST_BUFF_SOURCE_SKILL,        %% BUFF来源增加X%物理防御力持续N回合 
										 trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										 expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,	%% 消耗类型
										 expend_value    = Effect#effect.arg6               %% 消耗值
										},
			BuffTemp2   = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合 
			Buff2       = BuffTemp2#buff{
										 buff_value      = Effect#effect.arg9,			    %% 值
										 
										 source          = ?CONST_BUFF_SOURCE_SKILL,        %% BUFF来源
										 trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										 expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,	%% 消耗类型
										 expend_value    = Effect#effect.arg10              %% 消耗值
										},
			{[Buff1], [Buff2]}
	end;
%% CONST_SKILL_EFFECT_ID_154	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_154, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT -> [];
		?CONST_BATTLE_STEP_MIDDLE ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_94),% BUFF类型--附加暴击无效持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = 0,			    				%% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg4               	%% 消耗值
									   },
			[Buff];
		?CONST_BATTLE_STEP_BACK ->
			BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_1),% BUFF类型--增加X%生命上限持续N回合 
			Buff        = BuffTemp#buff{
										buff_value      = Effect#effect.arg7,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg8               	%% 消耗值
									   },
			[Buff]
	end;
%% CONST_SKILL_EFFECT_ID_155    技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_155, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT  -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK   ->
			BuffTemp1    = buff_api:get_buff(?CONST_BUFF_TYPE_1),% BUFF类型--增加X%生命上限持续N回合 
			Buff1        = BuffTemp1#buff{
										buff_value      = Effect#effect.arg5,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg8               	%% 消耗值
									   },
            BuffTemp2    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物防 
            Buff2        = BuffTemp2#buff{
                                        buff_value      = Effect#effect.arg6,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg8                %% 消耗值
                                       },
            BuffTemp3    = buff_api:get_buff(?CONST_BUFF_TYPE_7),% BUFF类型--增加X%术防 
            Buff3        = BuffTemp3#buff{
                                        buff_value      = Effect#effect.arg7,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg8                %% 消耗值
                                       },
			[Buff1, Buff2, Buff3]
	end;
%% CONST_SKILL_EFFECT_ID_156    技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_156, _Skill, Effect, Step) ->
	case Step of
		?CONST_BATTLE_STEP_FRONT  -> [];
		?CONST_BATTLE_STEP_MIDDLE -> [];
		?CONST_BATTLE_STEP_BACK   ->
			BuffTemp1    = buff_api:get_buff(?CONST_BUFF_TYPE_3),% BUFF类型--增加X%生命上限持续N回合 
			Buff1        = BuffTemp1#buff{
										buff_value      = Effect#effect.arg6,			    %% 值
										
										source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
										trigger         = ?CONST_BUFF_TRIGGER_BOUT,       	%% BUFF触发时机
										expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
										expend_value    = Effect#effect.arg7               	%% 消耗值
									   },
			[Buff1]
	end;
%% CONST_SKILL_EFFECT_ID_157    技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合
skill_effect_buff(?CONST_SKILL_EFFECT_ID_157, _Skill, Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE -> [];
        ?CONST_BATTLE_STEP_BACK ->
            BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_82),% BUFF类型--增加X%吸血[arg7]回合
            Buff        = BuffTemp#buff{
                                        buff_value      = Effect#effect.arg6,               %% 值
                                        
                                        source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                        trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                        expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                        expend_value    = Effect#effect.arg7                %% 消耗值
                                       },
            [Buff]
    end;
%% CONST_SKILL_EFFECT_ID_158    技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击
skill_effect_buff(?CONST_SKILL_EFFECT_ID_158, _Skill, _Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE -> [];
        ?CONST_BATTLE_STEP_BACK -> []
    end;

%% CONST_SKILL_EFFECT_ID_159	技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff 
skill_effect_buff(?CONST_SKILL_EFFECT_ID_159, _Skill, _Effect, Step) ->
    case Step of
        ?CONST_BATTLE_STEP_FRONT -> [];
        ?CONST_BATTLE_STEP_MIDDLE -> [];
        ?CONST_BATTLE_STEP_BACK -> []
    end.	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_GENIUS_EFFECT_ID_301	天赋技能效果ID--默认，[arg1]回合内必然暴击
%% CONST_SKILL_GENIUS_EFFECT_ID_351	天赋技能效果ID--回合，有[arg1]%几率解除[arg2]个DEBUFF
%% CONST_SKILL_GENIUS_EFFECT_ID_401	天赋技能效果ID--技能消耗怒气，降低[arg1]%技能怒气消耗
%% CONST_SKILL_GENIUS_EFFECT_ID_451	天赋技能效果ID--治疗，有[arg1]%几率解除[arg2]个DEBUFF
%% CONST_SKILL_GENIUS_EFFECT_ID_452	天赋技能效果ID--治疗，有[arg1]%几率增加[arg2]%攻击力[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_501	天赋技能效果ID--受治疗，有[arg1]%几率增加[arg2]%治疗效果

%% CONST_SKILL_GENIUS_EFFECT_ID_551	天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
%% CONST_SKILL_GENIUS_EFFECT_ID_601	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力
%% CONST_SKILL_GENIUS_EFFECT_ID_602	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力
%% CONST_SKILL_GENIUS_EFFECT_ID_603	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_651	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力
%% CONST_SKILL_GENIUS_EFFECT_ID_652	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合。
%% CONST_SKILL_GENIUS_EFFECT_ID_653	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率
%% CONST_SKILL_GENIUS_EFFECT_ID_654	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度
%% CONST_SKILL_GENIUS_EFFECT_ID_655	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避

%% CONST_SKILL_GENIUS_EFFECT_ID_701	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%防御力--攻击(修正属性)
%% CONST_SKILL_GENIUS_EFFECT_ID_702	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%法术防御力--攻击(修正属性)
%% CONST_SKILL_GENIUS_EFFECT_ID_703	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%生命上限[arg3]回合 
%% CONST_SKILL_GENIUS_EFFECT_ID_704	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%速度[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_705	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%命中[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_706	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率降低[arg2]%治疗效果[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_707	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率解除[arg2]个BUFF
%% CONST_SKILL_GENIUS_EFFECT_ID_708	天赋技能效果ID--攻击(技能攻击)，有[arg1]%几率降低目标[arg2]%怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_709	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%命中[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_710	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%速度[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_711	天赋技能效果ID--攻击(死亡)，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_712	天赋技能效果ID--攻击(死亡)，有[arg1]%几率增加[arg2]点怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_713	天赋技能效果ID--攻击(普通攻击并暴击)，有[arg1]%几率增加免疫DEBUFF[arg2]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_714 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率对目标[arg2]降低[arg3]%命中[arg4]回合 

%% CONST_SKILL_GENIUS_EFFECT_ID_751	天赋技能效果ID--防守，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
%% CONST_SKILL_GENIUS_EFFECT_ID_752	天赋技能效果ID--防守，有[arg1]%几率降低攻击者[arg2]%速度[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_753	天赋技能效果ID--防守，伤害高于生命上限[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力[arg4]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_754	天赋技能效果ID--防守(受暴击)，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
%% CONST_SKILL_GENIUS_EFFECT_ID_755	天赋技能效果ID--防守(受暴击)，有[arg1]%几率增加[arg2]%闪避[arg3]回合
%% CONST_SKILL_GENIUS_EFFECT_ID_756	天赋技能效果ID--防守(死亡)，有[arg1]%几率复活，恢复[arg2]%生命
%% CONST_SKILL_GENIUS_EFFECT_ID_757 天赋技能效果ID--防守，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
%% CONST_SKILL_GENIUS_EFFECT_ID_758 天赋技能效果ID--防守，有[arg1]%几率反击一次 
%% CONST_SKILL_GENIUS_EFFECT_ID_759 天赋技能效果ID--防守，当发生格挡时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]%怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_760 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气

%% CONST_SKILL_GENIUS_EFFECT_ID_801	天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_GENIUS_EFFECT_ID_301	天赋技能效果ID--默认，[arg1]回合内必然暴击
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_301, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_92),% BUFF类型--附加N回合后必然暴击
	Buff        = BuffTemp#buff{
								buff_value      = 0,							    %% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_NORMAL,       %% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,		%% 消耗类型
								expend_value    = Effect#effect.arg1,              	%% 消耗值
								arg1			= ?false							%% 参数1[是否已暴击]
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_351	天赋技能效果ID--回合，有[arg1]%几率解除[arg2]个DEBUFF
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_351, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_401	天赋技能效果ID--技能消耗怒气，降低[arg1]%技能怒气消耗
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_401, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_451	天赋技能效果ID--治疗，有[arg1]%几率解除[arg2]个DEBUFF
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_451, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_452	天赋技能效果ID--治疗，有[arg1]%几率增加[arg2]%攻击力[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_452, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_2),% BUFF类型--增加X%攻击力持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_501	天赋技能效果ID--受治疗，有[arg1]%几率增加[arg2]%治疗效果
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_501, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_551	天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_551, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_601	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_601, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_602	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_602, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_603	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_603, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_4),% BUFF类型--增加X%法术攻击力持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg4,		        %% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg5                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_651	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_651, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_652	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合。
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_652, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_653	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_653, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_654	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_654, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_655	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_655, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_701	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%防御力--攻击(修正属性)
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_701, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_702	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%法术防御力--攻击(修正属性)
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_702, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_703	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%生命上限[arg3]回合 
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_703, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_11),% BUFF类型--降低X%生命上限持续N回合 
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,		        %% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_704	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%速度[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_704, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_18),% BUFF类型--降低X%速度持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_705	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%命中[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_705, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_31),% BUFF类型--降低X%命中持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_706	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率降低[arg2]%治疗效果[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_706, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_51),% BUFF类型--降低X%治疗效果持续N回合 
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_CURE,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_707	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率解除[arg2]个BUFF
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_707, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_708	天赋技能效果ID--攻击(技能攻击)，有[arg1]%几率降低目标[arg2]%怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_708, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_709	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%命中[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_709, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_21),% BUFF类型--增加X%命中持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_710	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%速度[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_710, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_8),% BUFF类型--增加X%速度持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_711	天赋技能效果ID--攻击(死亡)，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_711, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg3,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg4                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_712	天赋技能效果ID--攻击(死亡)，有[arg1]%几率增加[arg2]点怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_712, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_713	天赋技能效果ID--攻击(普通攻击并暴击)，有[arg1]%几率增加免疫DEBUFF[arg2]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_713, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_91),% BUFF类型--附加免疫DEBUFF持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = 0,				             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg2                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_714 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率对目标[arg2]降低[arg3]%命中[arg4]回合 
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_714, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_31),% BUFF类型--增加X%物理防御力持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg3,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg4                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_751	天赋技能效果ID--防守，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_751, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_752	天赋技能效果ID--防守，有[arg1]%几率降低攻击者[arg2]%速度[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_752, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_18),% BUFF类型--降低X%速度持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_753	天赋技能效果ID--防守，伤害高于生命上限[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力[arg4]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_753, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg3,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg4                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_754	天赋技能效果ID--防守(受暴击)，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_754, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_755	天赋技能效果ID--防守(受暴击)，有[arg1]%几率增加[arg2]%闪避[arg3]回合
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_755, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_22),% BUFF类型--增加X%闪避持续N回合
	Buff        = BuffTemp#buff{
								buff_value      = Effect#effect.arg2,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg3                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_756	天赋技能效果ID--防守(死亡)，有[arg1]%几率复活，恢复[arg2]%生命
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_756, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_757 天赋技能效果ID--防守，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_757, _Skill, Effect, _Step) ->
	BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物理防御力持续N回合
	Buff        = BuffTemp#buff{ 
								buff_value      = Effect#effect.arg3,             	%% 值
								
								source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
								trigger         = ?CONST_BUFF_TRIGGER_BOUT,			%% BUFF触发时机
								expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
								expend_value    = Effect#effect.arg4                %% 消耗值
							   },
	[Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_758 天赋技能效果ID--防守，有[arg1]%几率反击一次 
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_758, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_759 天赋技能效果ID--防守，当发生格挡时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]%怒气 
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_759, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_208),% BUFF类型--增加X%物理防御力持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_760 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_760, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_24),% BUFF类型--增加X%格挡持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_761 天赋技能效果ID--防守发生暴击时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_761, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_22),% BUFF类型--增加X%闪避持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_762 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_762, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_23),% BUFF类型--增加X%暴击持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_763 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_763, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_208),% BUFF类型--增加X%物攻持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_764 天赋技能效果ID--攻击被闪避时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_764, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_21),% BUFF类型--增加X%命中持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_765 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%术攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_765, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_209),% BUFF类型--增加X%法术攻击力持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_766 天赋技能效果ID--被治疗时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_766, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_24),% BUFF类型--增加X%格挡持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_767 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%双防持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_767, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_6),% BUFF类型--增加X%物防持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    BuffTemp2    = buff_api:get_buff(?CONST_BUFF_TYPE_7),% BUFF类型--增加X%术防持续N回合
    Buff2        = BuffTemp2#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff, Buff2];
%% CONST_SKILL_GENIUS_EFFECT_ID_768 天赋技能效果ID--攻击时，有[arg1]%机率多攻击[arg2]个目标，并有[arg3]%机率增加[arg4]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_768, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_769 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_769, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_16),% BUFF类型--增加X%物防持续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_770 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_770, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_21),% BUFF类型--增加X%命中持续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_771 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%气血上限持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_771, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_210),% BUFF类型--增加X%气血上限持续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_772 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_772, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_17),% BUFF类型--增加X%法术防御持续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg3                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_773 天赋技能效果ID--攻击时，有[arg1]%机率解除目标[arg2]的[arg3]个[arg4]buff，并有[arg5]%机率增加[arg6]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_773, _Skill, _Effect, _Step) -> [];
%% CONST_SKILL_GENIUS_EFFECT_ID_774 天赋技能效果ID--攻击时，有[arg1]%机率封印目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_774, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_62),% BUFF类型--增加X%封印续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg2                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_775 天赋技能效果ID--攻击时，有[arg1]%机率沉默目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_775, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_61),% BUFF类型--增加X%封印续持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg2,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg2                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_776 天赋技能效果ID--死亡时，有[arg1]%机率提升目标[arg2][arg3]%双攻持续[arg4]回合，并有[arg5]%机率增加[arg6]怒气
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_776, _Skill, Effect, _Step) -> 
    BuffTemp    = buff_api:get_buff(?CONST_BUFF_TYPE_211),% BUFF类型--增加X%物防持续N回合
    Buff        = BuffTemp#buff{
                                buff_value      = Effect#effect.arg3,               %% 值
                                
                                source          = ?CONST_BUFF_SOURCE_SKILL,         %% BUFF来源
                                trigger         = ?CONST_BUFF_TRIGGER_BOUT,         %% BUFF触发时机
                                expend_type     = ?CONST_BUFF_EXPEND_TYPE_BOUT,     %% 消耗类型
                                expend_value    = Effect#effect.arg4                %% 消耗值
                               },
    [Buff];
%% CONST_SKILL_GENIUS_EFFECT_ID_801	天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位
genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_801, _Skill, _Effect, _Step) -> [].


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_BUFF_TYPE_1	BUFF类型--增加X%生命上限持续N回合
%% CONST_BUFF_TYPE_2	BUFF类型--增加X%攻击力持续N回合
%% CONST_BUFF_TYPE_3	BUFF类型--增加X%物理攻击力持续N回合
%% CONST_BUFF_TYPE_4	BUFF类型--增加X%法术攻击力持续N回合
%% CONST_BUFF_TYPE_5	BUFF类型--增加X%防御力持续N回合
%% CONST_BUFF_TYPE_6	BUFF类型--增加X%物理防御力持续N回合
%% CONST_BUFF_TYPE_7	BUFF类型--增加X%法术防御力持续N回合
%% CONST_BUFF_TYPE_8	BUFF类型--增加X%速度持续N回合
%% CONST_BUFF_TYPE_11	BUFF类型--降低X%生命上限持续N回合
%% CONST_BUFF_TYPE_12	BUFF类型--降低X%攻击力持续N回合
%% CONST_BUFF_TYPE_13	BUFF类型--降低X%物理攻击力持续N回合
%% CONST_BUFF_TYPE_14	BUFF类型--降低X%法术攻击力持续N回合
%% CONST_BUFF_TYPE_15	BUFF类型--降低X%防御力持续N回合
%% CONST_BUFF_TYPE_16	BUFF类型--降低X%物理防御力持续N回合
%% CONST_BUFF_TYPE_17	BUFF类型--降低X%法术防御力持续N回合
%% CONST_BUFF_TYPE_18	BUFF类型--降低X%速度持续N回合
%% CONST_BUFF_TYPE_21	BUFF类型--增加X%命中持续N回合
%% CONST_BUFF_TYPE_22	BUFF类型--增加X%闪避持续N回合
%% CONST_BUFF_TYPE_23	BUFF类型--增加X%暴击持续N回合
%% CONST_BUFF_TYPE_24	BUFF类型--增加X%格挡持续N回合
%% CONST_BUFF_TYPE_25	BUFF类型--增加X%反击持续N回合
%% CONST_BUFF_TYPE_26	BUFF类型--增加X%降低暴击持续N回合
%% CONST_BUFF_TYPE_31	BUFF类型--降低X%命中持续N回合
%% CONST_BUFF_TYPE_32	BUFF类型--降低X%闪避持续N回合
%% CONST_BUFF_TYPE_33	BUFF类型--降低X%暴击持续N回合
%% CONST_BUFF_TYPE_34	BUFF类型--降低X%格挡持续N回合
%% CONST_BUFF_TYPE_35	BUFF类型--降低X%反击持续N回合
%% CONST_BUFF_TYPE_36	BUFF类型--降低X%降低暴击持续N回合
%% CONST_BUFF_TYPE_41	BUFF类型--增加X%治疗效果持续N回合
%% CONST_BUFF_TYPE_42	BUFF类型--增加X%怒气恢复效果持续N回合
%% CONST_BUFF_TYPE_43	BUFF类型--增加X点生命持续N回合
%% CONST_BUFF_TYPE_44	BUFF类型--增加X%生命持续N回合
%% CONST_BUFF_TYPE_45   BUFF类型--降低暴击伤害
%% CONST_BUFF_TYPE_51	BUFF类型--降低X%治疗效果持续N回合
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
%% CONST_BUFF_TYPE_53	BUFF类型--降低X点生命持续N回合(中毒)
%% CONST_BUFF_TYPE_54	BUFF类型--降低X点生命持续N回合(中毒) BOSS免疫 
%% CONST_BUFF_TYPE_55	BUFF类型--降低X点生命持续N回合(燃烧) 
%% CONST_BUFF_TYPE_61	BUFF类型--附加沉默持续N回合
%% CONST_BUFF_TYPE_62	BUFF类型--附加封印持续N回合
%% CONST_BUFF_TYPE_63	BUFF类型--附加眩晕持续N回合
%% CONST_BUFF_TYPE_71	BUFF类型--附加免疫沉默持续N回合
%% CONST_BUFF_TYPE_72	BUFF类型--附加免疫封印持续N回合
%% CONST_BUFF_TYPE_73	BUFF类型--附加免疫眩晕持续N回合
%% CONST_BUFF_TYPE_74	BUFF类型--附加免疫控制持续N回合
%% CONST_BUFF_TYPE_75	BUFF类型--附加免疫惊鸿控制持续N回合
%% CONST_BUFF_TYPE_81	BUFF类型--附加无敌效果持续N回合
%% CONST_BUFF_TYPE_82	BUFF类型--附加X%吸血效果持续N回合
%% CONST_BUFF_TYPE_91	BUFF类型--附加免疫DEBUFF持续N回合
%% CONST_BUFF_TYPE_92	BUFF类型--附加N回合后必然暴击
%% CONST_BUFF_TYPE_93	BUFF类型--附加免疫暴击持续N回合
%% CONST_BUFF_TYPE_94	BUFF类型--附加暴击无效持续N回合 
%% CONST_BUFF_TYPE_101	BUFF类型--附加无视防御力持续N回合 
%% CONST_BUFF_TYPE_102	BUFF类型--附加无视物理防御力持续N回合 
%% CONST_BUFF_TYPE_103	BUFF类型--附加无视法术防御力持续N回合 
%% CONST_BUFF_TYPE_201	BUFF类型--增加X%生命上限
%% CONST_BUFF_TYPE_202	BUFF类型--增加X%物理攻击力
%% CONST_BUFF_TYPE_203	BUFF类型--增加X%法术攻击力
%% CONST_BUFF_TYPE_204	BUFF类型--增加X%速度
%% CONST_BUFF_TYPE_205	BUFF类型--增加X%暴击率
%% CONST_BUFF_TYPE_206	BUFF类型--增加X%反击率
%% CONST_BUFF_TYPE_207	BUFF类型--增加X%格挡率
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BUFF安装
%% CONST_BUFF_TYPE_1	BUFF类型--增加X%生命上限持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_1} = Buff) ->
	case Buff#buff.install_point of
		?CONST_BUFF_INSTALL_POINT_DEFAULT ->
			{
			 _AttrBase, AttrBaseSecond, _AttrBaseElite
			}			= battle_mod_misc:get_unit_attr_base(Unit),
			Type        = ?CONST_PLAYER_ATTR_HP_MAX,
			Value       = Buff#buff.buff_value,
			HpMax	    = AttrBaseSecond#attr_second.hp_max,
			DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
			Unit2		= Unit#unit{attr = Attr},
			battle_mod_misc:plus_hp(Unit2, DValue);
		?CONST_BUFF_INSTALL_POINT_BOUT ->
			{
			 _AttrBase, AttrBaseSecond, _AttrBaseElite
			}			= battle_mod_misc:get_unit_attr_base(Unit),
			Type        = ?CONST_PLAYER_ATTR_HP_MAX,
			Value       = Buff#buff.buff_value,
			HpMax	    = AttrBaseSecond#attr_second.hp_max,
			DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
			Unit#unit{attr = Attr}
	end;
%% CONST_BUFF_TYPE_2	BUFF类型--增加X%攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_2} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk	= ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       	= Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, DValueForceAtk}, {TypeMagicAtk, DValueMagicAtk}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_3	BUFF类型--增加X%物理攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_3} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_4	BUFF类型--增加X%法术攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_4} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_5	BUFF类型--增加X%防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_5} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       	= Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceDef, DValueForceDef}, {TypeMagicDef, DValueMagicDef}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_6	BUFF类型--增加X%物理防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_6} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_DEF,
    Value       = Buff#buff.buff_value,
    ForceDef    = AttrBaseSecond#attr_second.force_def,
    DValue      = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_7	BUFF类型--增加X%法术防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_7} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       = Buff#buff.buff_value,
    MagicDef    = AttrBaseSecond#attr_second.magic_def,
    DValue      = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_8	BUFF类型--增加X%速度持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_8} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_SPEED,
    Value       = Buff#buff.buff_value,
    Speed       = AttrBaseSecond#attr_second.speed,
    DValue      = Speed * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_11	BUFF类型--降低X%生命上限持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_11} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_HP_MAX,
    Value       = Buff#buff.buff_value,
    HpMax	    = AttrBaseSecond#attr_second.hp_max,
    DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Hp          = misc:betweet(Unit#unit.hp, 0, (Attr#attr.attr_second)#attr_second.hp_max),
    Unit#unit{hp = Hp, attr = Attr};
%% CONST_BUFF_TYPE_12	BUFF类型--降低X%攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_12} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk	= ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       	= Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, - DValueForceAtk}, {TypeMagicAtk, - DValueMagicAtk}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_13	BUFF类型--降低X%物理攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_13} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_14	BUFF类型--降低X%法术攻击力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_14} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_15	BUFF类型--降低X%防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_15} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       	= Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_16	BUFF类型--降低X%物理防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_16} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_DEF,
    Value       = Buff#buff.buff_value,
    ForceDef    = AttrBaseSecond#attr_second.force_def,
    DValue      = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_17	BUFF类型--降低X%法术防御力持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_17} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       = Buff#buff.buff_value,
    MagicDef    = AttrBaseSecond#attr_second.magic_def,
    DValue      = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_18	BUFF类型--降低X%速度持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_18} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_SPEED,
    Value       = Buff#buff.buff_value,
    Speed       = AttrBaseSecond#attr_second.speed,
    DValue      = Speed * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_21	BUFF类型--增加X%命中持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_21} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_HIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_22	BUFF类型--增加X%闪避持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_22} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_DODGE,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_23	BUFF类型--增加X%暴击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_23} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_24	BUFF类型--增加X%招架持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_24} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_PARRY,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_25	BUFF类型--增加X%反击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_25} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_RESIST,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_26	BUFF类型--增加X%降低暴击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_26} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_R_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_27	BUFF类型--增加暴击伤害
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_27} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT_H,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_31	BUFF类型--降低X%命中持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_31} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_HIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_32	BUFF类型--降低X%闪避持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_32} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_DODGE,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_33	BUFF类型--降低X%暴击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_33} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_34	BUFF类型--降低X%招架持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_34} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_PARRY,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_35	BUFF类型--降低X%反击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_35} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_RESIST,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_36	BUFF类型--降低X%降低暴击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_36} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_R_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_41	BUFF类型--增加X%治疗效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_41}) ->
	Unit;
%% CONST_BUFF_TYPE_42	BUFF类型--增加X%怒气恢复效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_42}) ->
	Unit;
%% CONST_BUFF_TYPE_43	BUFF类型--增加X点生命持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_43} = Buff) ->
	battle_mod_misc:plus_hp(Unit, Buff#buff.buff_value);
%% CONST_BUFF_TYPE_44	BUFF类型--增加X%生命持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_44} = Buff) ->
	{_Attr, AttrSecond, _AttrElite}	= battle_mod_misc:get_unit_attr(Unit),
	Value	= AttrSecond#attr_second.hp_max * Buff#buff.buff_value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	battle_mod_misc:plus_hp(Unit, Value);
%% CONST_BUFF_TYPE_45   BUFF类型--降低暴击伤害
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_45} = Buff) ->
	Type        = ?CONST_PLAYER_ATTR_E_CRIT_H,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_51	BUFF类型--降低X%治疗效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_51}) ->
	Unit;
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_52}) ->
	Unit;
%% CONST_BUFF_TYPE_53	BUFF类型--降低X点生命持续N回合(中毒)
buff_install(EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_53} = Buff) ->
	{Unit2, _Death, _HurtFinal}	= battle_mod_misc:minus_hp(EnlargeRate, Unit, Buff#buff.buff_value),
	Unit2;
%% CONST_BUFF_TYPE_54	BUFF类型--降低X点生命持续N回合(中毒) BOSS免疫 
buff_install(EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_54} = Buff) ->
	{Unit2, _Death, _HurtFinal}	= battle_mod_misc:minus_hp(EnlargeRate, Unit, Buff#buff.buff_value),
	Unit2;
%% CONST_BUFF_TYPE_55   BUFF类型--降低X点生命持续N回合(燃烧)
buff_install(EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_55} = Buff) ->
    {Unit2, _Death, _HurtFinal} = battle_mod_misc:minus_hp(EnlargeRate, Unit, Buff#buff.buff_value),
    Unit2;
%% CONST_BUFF_TYPE_61	BUFF类型--附加沉默持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_61}) ->
	Unit;
%% CONST_BUFF_TYPE_62	BUFF类型--附加封印持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_62}) ->
	Unit;
%% CONST_BUFF_TYPE_63	BUFF类型--附加眩晕持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_63}) ->
	Unit;
%% CONST_BUFF_TYPE_71	BUFF类型--附加免疫沉默持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_71}) ->
	Unit;
%% CONST_BUFF_TYPE_72	BUFF类型--附加免疫封印持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_72}) ->
	Unit;
%% CONST_BUFF_TYPE_73	BUFF类型--附加免疫眩晕持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_73}) ->
	Unit;
%% CONST_BUFF_TYPE_74	BUFF类型--附加免疫控制持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_74}) ->
	Unit;
%% CONST_BUFF_TYPE_75	BUFF类型--附加免疫惊鸿控制持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_75}) ->
	Unit;
%% CONST_BUFF_TYPE_81	BUFF类型--附加无敌效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_81}) ->
	Unit;
%% CONST_BUFF_TYPE_82	BUFF类型--附加X%吸血效果持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_82}) ->
	Unit;
%% CONST_BUFF_TYPE_91	BUFF类型--附加免疫DEBUFF持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_91}) ->
	Unit;
%% CONST_BUFF_TYPE_92	BUFF类型--附加N回合后必然暴击
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_92}) ->
	Unit;
%% CONST_BUFF_TYPE_93	BUFF类型--附加免疫暴击持续N回合
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_93}) ->
	Unit;
%% CONST_BUFF_TYPE_94	BUFF类型--附加暴击无效持续N回合 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_94}) ->
	Unit;
%% CONST_BUFF_TYPE_101	BUFF类型--附加无视防御力持续N回合 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_101}) ->
	Unit;
%% CONST_BUFF_TYPE_102	BUFF类型--附加无视物理防御力持续N回合 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_102}) ->
	Unit;
%% CONST_BUFF_TYPE_103	BUFF类型--附加无视法术防御力持续N回合 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_103}) ->
	Unit;
%% CONST_BUFF_TYPE_201  BUFF类型--增加X%生命上限 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_201}) ->
	Unit;
%% CONST_BUFF_TYPE_202  BUFF类型--增加X%物理攻击力 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_202}) ->
	Unit;
%% CONST_BUFF_TYPE_203  BUFF类型--增加X%法术攻击力 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_203}) ->
	Unit;
%% CONST_BUFF_TYPE_204  BUFF类型--增加X%速度 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_204}) ->
	Unit;
%% CONST_BUFF_TYPE_205  BUFF类型--增加X%暴击率 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_205}) ->
	Unit;
%% CONST_BUFF_TYPE_206  BUFF类型--增加X%反击率 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_206}) ->
	Unit;
%% CONST_BUFF_TYPE_207  BUFF类型--增加X%格挡率 
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_207}) ->
	Unit;
%% CONST_BUFF_TYPE_208  BUFF类型--增加物攻（将魂）
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_208} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_209  BUFF类型--增加术攻（将魂）
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_209} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_210  BUFF类型--增加气血上限（将魂）
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_210} = Buff) ->
    case Buff#buff.install_point of
        ?CONST_BUFF_INSTALL_POINT_DEFAULT ->
            {
             _AttrBase, AttrBaseSecond, _AttrBaseElite
            }           = battle_mod_misc:get_unit_attr_base(Unit),
            Type        = ?CONST_PLAYER_ATTR_HP_MAX,
            Value       = Buff#buff.buff_value,
            HpMax       = AttrBaseSecond#attr_second.hp_max,
            DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
            Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
            Unit2       = Unit#unit{attr = Attr},
            battle_mod_misc:plus_hp(Unit2, DValue);
        ?CONST_BUFF_INSTALL_POINT_BOUT ->
            {
             _AttrBase, AttrBaseSecond, _AttrBaseElite
            }           = battle_mod_misc:get_unit_attr_base(Unit),
            Type        = ?CONST_PLAYER_ATTR_HP_MAX,
            Value       = Buff#buff.buff_value,
            HpMax       = AttrBaseSecond#attr_second.hp_max,
            DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
            Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
            Unit#unit{attr = Attr}
    end;
%% CONST_BUFF_TYPE_211  BUFF类型--增加物攻和术攻（将魂）
buff_install(_EnlargeRate, Unit, #buff{buff_type = ?CONST_BUFF_TYPE_211} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }               = battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value           = Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, DValueForceAtk}, {TypeMagicAtk, DValueMagicAtk}]),
    Unit#unit{attr = Attr}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_BUFF_TYPE_1	BUFF类型--增加X%生命上限持续N回合
%% CONST_BUFF_TYPE_2	BUFF类型--增加X%攻击力持续N回合
%% CONST_BUFF_TYPE_3	BUFF类型--增加X%物理攻击力持续N回合
%% CONST_BUFF_TYPE_4	BUFF类型--增加X%法术攻击力持续N回合
%% CONST_BUFF_TYPE_5	BUFF类型--增加X%防御力持续N回合
%% CONST_BUFF_TYPE_6	BUFF类型--增加X%物理防御力持续N回合
%% CONST_BUFF_TYPE_7	BUFF类型--增加X%法术防御力持续N回合
%% CONST_BUFF_TYPE_8	BUFF类型--增加X%速度持续N回合
%% CONST_BUFF_TYPE_11	BUFF类型--降低X%生命上限持续N回合
%% CONST_BUFF_TYPE_12	BUFF类型--降低X%攻击力持续N回合
%% CONST_BUFF_TYPE_13	BUFF类型--降低X%物理攻击力持续N回合
%% CONST_BUFF_TYPE_14	BUFF类型--降低X%法术攻击力持续N回合
%% CONST_BUFF_TYPE_15	BUFF类型--降低X%防御力持续N回合
%% CONST_BUFF_TYPE_16	BUFF类型--降低X%物理防御力持续N回合
%% CONST_BUFF_TYPE_17	BUFF类型--降低X%法术防御力持续N回合
%% CONST_BUFF_TYPE_18	BUFF类型--降低X%速度持续N回合
%% CONST_BUFF_TYPE_21	BUFF类型--增加X%命中持续N回合
%% CONST_BUFF_TYPE_22	BUFF类型--增加X%闪避持续N回合
%% CONST_BUFF_TYPE_23	BUFF类型--增加X%暴击持续N回合
%% CONST_BUFF_TYPE_24	BUFF类型--增加X%招架持续N回合
%% CONST_BUFF_TYPE_25	BUFF类型--增加X%反击持续N回合
%% CONST_BUFF_TYPE_26	BUFF类型--增加X%降低暴击持续N回合
%% CONST_BUFF_TYPE_27   BUFF类型--增加暴击伤害
%% CONST_BUFF_TYPE_31	BUFF类型--降低X%命中持续N回合
%% CONST_BUFF_TYPE_32	BUFF类型--降低X%闪避持续N回合
%% CONST_BUFF_TYPE_33	BUFF类型--降低X%暴击持续N回合
%% CONST_BUFF_TYPE_34	BUFF类型--降低X%招架持续N回合
%% CONST_BUFF_TYPE_35	BUFF类型--降低X%反击持续N回合
%% CONST_BUFF_TYPE_36	BUFF类型--降低X%降低暴击持续N回合
%% CONST_BUFF_TYPE_41	BUFF类型--增加X%治疗效果持续N回合
%% CONST_BUFF_TYPE_42	BUFF类型--增加X%怒气恢复效果持续N回合
%% CONST_BUFF_TYPE_43	BUFF类型--增加X点生命持续N回合
%% CONST_BUFF_TYPE_44	BUFF类型--增加X%生命持续N回合
%% CONST_BUFF_TYPE_51	BUFF类型--降低X%治疗效果持续N回合
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
%% CONST_BUFF_TYPE_53	BUFF类型--降低X点生命持续N回合(中毒)
%% CONST_BUFF_TYPE_54	BUFF类型--降低X点生命持续N回合(中毒) BOSS免疫 
%% CONST_BUFF_TYPE_55	BUFF类型--降低X点生命持续N回合(燃烧)
%% CONST_BUFF_TYPE_61	BUFF类型--附加沉默持续N回合
%% CONST_BUFF_TYPE_62	BUFF类型--附加封印持续N回合
%% CONST_BUFF_TYPE_63	BUFF类型--附加眩晕持续N回合
%% CONST_BUFF_TYPE_71	BUFF类型--附加免疫沉默持续N回合
%% CONST_BUFF_TYPE_72	BUFF类型--附加免疫封印持续N回合
%% CONST_BUFF_TYPE_73	BUFF类型--附加免疫眩晕持续N回合
%% CONST_BUFF_TYPE_74	BUFF类型--附加免疫控制持续N回合
%% CONST_BUFF_TYPE_75	BUFF类型--附加免疫惊鸿控制持续N回合
%% CONST_BUFF_TYPE_81	BUFF类型--附加无敌效果持续N回合
%% CONST_BUFF_TYPE_82	BUFF类型--附加X%吸血效果持续N回合
%% CONST_BUFF_TYPE_91	BUFF类型--附加免疫DEBUFF持续N回合
%% CONST_BUFF_TYPE_92	BUFF类型--附加N回合后必然暴击
%% CONST_BUFF_TYPE_93	BUFF类型--附加免疫暴击持续N回合
%% CONST_BUFF_TYPE_94	BUFF类型--附加暴击无效持续N回合 
%% CONST_BUFF_TYPE_101	BUFF类型--附加无视防御力持续N回合 
%% CONST_BUFF_TYPE_102	BUFF类型--附加无视物理防御力持续N回合 
%% CONST_BUFF_TYPE_103	BUFF类型--附加无视法术防御力持续N回合 
%% CONST_BUFF_TYPE_201	BUFF类型--增加X%生命上限
%% CONST_BUFF_TYPE_202	BUFF类型--增加X%物理攻击力
%% CONST_BUFF_TYPE_203	BUFF类型--增加X%法术攻击力
%% CONST_BUFF_TYPE_204	BUFF类型--增加X%速度
%% CONST_BUFF_TYPE_205	BUFF类型--增加X%暴击率
%% CONST_BUFF_TYPE_206	BUFF类型--增加X%反击率
%% CONST_BUFF_TYPE_207	BUFF类型--增加X%格挡率
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BUFF卸载
%% CONST_BUFF_TYPE_1	BUFF类型--增加X%生命上限持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_1} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_HP_MAX,
    Value       = Buff#buff.buff_value,
    HpMax	    = AttrBaseSecond#attr_second.hp_max,
    DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Hp          = misc:betweet(Unit#unit.hp, 0, (Attr#attr.attr_second)#attr_second.hp_max),
    Unit#unit{hp = Hp, attr = Attr};
%% CONST_BUFF_TYPE_2	BUFF类型--增加X%攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_2} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk	= ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       	= Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, - DValueForceAtk}, {TypeMagicAtk, - DValueMagicAtk}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_3	BUFF类型--增加X%物理攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_3} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_4	BUFF类型--增加X%法术攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_4} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_5	BUFF类型--增加X%防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_5} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       	= Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_6	BUFF类型--增加X%物理防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_6} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_DEF,
    Value       = Buff#buff.buff_value,
    ForceDef    = AttrBaseSecond#attr_second.force_def,
    DValue      = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_7	BUFF类型--增加X%法术防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_7} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       = Buff#buff.buff_value,
    MagicDef    = AttrBaseSecond#attr_second.magic_def,
    DValue      = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_8	BUFF类型--增加X%速度持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_8} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_SPEED,
    Value       = Buff#buff.buff_value,
    Speed       = AttrBaseSecond#attr_second.speed,
    DValue      = Speed * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_11	BUFF类型--降低X%生命上限持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_11} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_HP_MAX,
    Value       = Buff#buff.buff_value,
    HpMax	    = AttrBaseSecond#attr_second.hp_max,
    DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_12	BUFF类型--降低X%攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_12} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk	= ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       	= Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, DValueForceAtk}, {TypeMagicAtk, DValueMagicAtk}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_13	BUFF类型--降低X%物理攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_13} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_14	BUFF类型--降低X%法术攻击力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_14} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_15	BUFF类型--降低X%防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_15} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}				= battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
    TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       	= Buff#buff.buff_value,
    ForceDef        = AttrBaseSecond#attr_second.force_def,
    MagicDef        = AttrBaseSecond#attr_second.magic_def,
    DValueForceDef  = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicDef  = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceDef, DValueForceDef}, {TypeMagicDef, DValueMagicDef}]),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_16	BUFF类型--降低X%物理防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_16} = Buff) ->
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_DEF,
    Value       = Buff#buff.buff_value,
    ForceDef    = AttrBaseSecond#attr_second.force_def,
    DValue      = ForceDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_17	BUFF类型--降低X%法术防御力持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_17} = Buff) ->    
	{
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_DEF,
    Value       = Buff#buff.buff_value,
    MagicDef    = AttrBaseSecond#attr_second.magic_def,
    DValue      = MagicDef * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_18	BUFF类型--降低X%速度持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_18} = Buff) ->
    {
	 _AttrBase, AttrBaseSecond, _AttrBaseElite
	}			= battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_SPEED,
    Value       = Buff#buff.buff_value,
    Speed       = AttrBaseSecond#attr_second.speed,
    DValue      = Speed * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_21	BUFF类型--增加X%命中持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_21} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_HIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_22	BUFF类型--增加X%闪避持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_22} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_DODGE,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_23	BUFF类型--增加X%暴击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_23} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_24	BUFF类型--增加X%招架持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_24} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_PARRY,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_25	BUFF类型--增加X%反击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_25} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_RESIST,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_26	BUFF类型--增加X%降低暴击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_26} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_R_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_27   BUFF类型--增加暴击伤害
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_27} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT_H,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_31	BUFF类型--降低X%命中持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_31} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_HIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_32	BUFF类型--降低X%闪避持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_32} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_DODGE,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_33	BUFF类型--降低X%暴击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_33} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_34	BUFF类型--降低X%招架持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_34} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_PARRY,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_35	BUFF类型--降低X%反击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_35} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_RESIST,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_36	BUFF类型--降低X%降低暴击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_36} = Buff) ->
    Type        = ?CONST_PLAYER_ATTR_E_R_CRIT,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_41	BUFF类型--增加X%治疗效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_41}) ->
	Unit;
%% CONST_BUFF_TYPE_42	BUFF类型--增加X%怒气恢复效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_42}) ->
	Unit;
%% CONST_BUFF_TYPE_43	BUFF类型--增加X点生命持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_43}) ->
	Unit;
%% CONST_BUFF_TYPE_44	BUFF类型--增加X%生命持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_44}) ->
	Unit;
%% CONST_BUFF_TYPE_45   BUFF类型--降低暴击伤害
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_45} = Buff) ->
	Type        = ?CONST_PLAYER_ATTR_E_CRIT_H,
    Value       = Buff#buff.buff_value,
    DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_51	BUFF类型--降低X%治疗效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_51}) ->
	Unit;
%% CONST_BUFF_TYPE_52	BUFF类型--降低X%怒气恢复效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_52}) ->
	Unit;
%% CONST_BUFF_TYPE_53	BUFF类型--降低X点生命持续N回合(中毒)
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_53}) ->
	Unit;
%% CONST_BUFF_TYPE_54	BUFF类型--降低X点生命持续N回合(中毒) BOSS免疫 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_54}) ->
	Unit;
%% CONST_BUFF_TYPE_55   BUFF类型--降低X点生命持续N回合(燃烧)
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_55}) ->
    Unit;
%% CONST_BUFF_TYPE_61	BUFF类型--附加沉默持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_61}) ->
	Unit;
%% CONST_BUFF_TYPE_62	BUFF类型--附加封印持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_62}) ->
	Unit;
%% CONST_BUFF_TYPE_63	BUFF类型--附加眩晕持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_63}) ->
	Unit;
%% CONST_BUFF_TYPE_71	BUFF类型--附加免疫沉默持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_71}) ->
	Unit;
%% CONST_BUFF_TYPE_72	BUFF类型--附加免疫封印持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_72}) ->
	Unit;
%% CONST_BUFF_TYPE_73	BUFF类型--附加免疫眩晕持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_73}) ->
	Unit;
%% CONST_BUFF_TYPE_74	BUFF类型--附加免疫控制持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_74}) ->
	Unit;
%% CONST_BUFF_TYPE_75	BUFF类型--附加免疫惊鸿控制持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_75}) ->
	Unit;
%% CONST_BUFF_TYPE_81	BUFF类型--附加无敌效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_81}) ->
	Unit;
%% CONST_BUFF_TYPE_82	BUFF类型--附加X%吸血效果持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_82}) ->
	Unit;
%% CONST_BUFF_TYPE_91	BUFF类型--附加免疫DEBUFF持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_91}) ->
	Unit;
%% CONST_BUFF_TYPE_92	BUFF类型--附加N回合后必然暴击
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_92}) ->
	Unit;
%% CONST_BUFF_TYPE_93	BUFF类型--附加免疫暴击持续N回合
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_93}) ->
	Unit;
%% CONST_BUFF_TYPE_94	BUFF类型--附加暴击无效持续N回合 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_94}) ->
	Unit;
%% CONST_BUFF_TYPE_101	BUFF类型--附加无视防御力持续N回合 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_101}) ->
	Unit;
%% CONST_BUFF_TYPE_102	BUFF类型--附加无视物理防御力持续N回合 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_102}) ->
	Unit;
%% CONST_BUFF_TYPE_103	BUFF类型--附加无视法术防御力持续N回合 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_103}) ->
	Unit;
%% CONST_BUFF_TYPE_201  BUFF类型--增加X%生命上限 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_201}) ->
	Unit;
%% CONST_BUFF_TYPE_202  BUFF类型--增加X%物理攻击力 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_202}) ->
	Unit;
%% CONST_BUFF_TYPE_203  BUFF类型--增加X%法术攻击力 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_203}) ->
	Unit;
%% CONST_BUFF_TYPE_204  BUFF类型--增加X%速度 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_204}) ->
	Unit;
%% CONST_BUFF_TYPE_205  BUFF类型--增加X%暴击率 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_205}) ->
	Unit;
%% CONST_BUFF_TYPE_206  BUFF类型--增加X%反击率 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_206}) ->
	Unit;
%% CONST_BUFF_TYPE_207  BUFF类型--增加X%格挡率 
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_207}) ->
	Unit;
%% CONST_BUFF_TYPE_208    BUFF类型--增加物攻（将魂）
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_208} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    Value       = Buff#buff.buff_value,
    ForceAtk    = AttrBaseSecond#attr_second.force_attack,
    DValue      = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_209    BUFF类型--增加术攻（将魂）
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_209} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value       = Buff#buff.buff_value,
    MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
    DValue      = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Unit#unit{attr = Attr};
%% CONST_BUFF_TYPE_210    BUFF类型--增加气血（将魂）
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_210} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }           = battle_mod_misc:get_unit_attr_base(Unit),
    Type        = ?CONST_PLAYER_ATTR_HP_MAX,
    Value       = Buff#buff.buff_value,
    HpMax       = AttrBaseSecond#attr_second.hp_max,
    DValue      = HpMax * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr        = player_attr_api:attr_plus(Unit#unit.attr, Type, - DValue),
    Hp          = misc:betweet(Unit#unit.hp, 0, (Attr#attr.attr_second)#attr_second.hp_max),
    Unit#unit{hp = Hp, attr = Attr};
%% CONST_BUFF_TYPE_211    BUFF类型--增加物攻和术攻（将魂）
buff_uninstall(Unit, #buff{buff_type = ?CONST_BUFF_TYPE_211} = Buff) ->
    {
     _AttrBase, AttrBaseSecond, _AttrBaseElite
    }               = battle_mod_misc:get_unit_attr_base(Unit),
    TypeForceAtk    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
    TypeMagicAtk    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
    Value           = Buff#buff.buff_value,
    ForceAtk        = AttrBaseSecond#attr_second.force_attack,
    MagicAtk        = AttrBaseSecond#attr_second.magic_attack,
    DValueForceAtk  = ForceAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    DValueMagicAtk  = MagicAtk * Value div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Attr            = player_attr_api:attr_plus(Unit#unit.attr, [{TypeForceAtk, - DValueForceAtk}, {TypeMagicAtk, - DValueMagicAtk}]),
    Unit#unit{attr = Attr}.


%%
%% Local Functions
%%

