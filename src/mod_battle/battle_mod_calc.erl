%% Author: cobain
%% Created: 2012-9-13
%% Description: TODO: Add description to battle_mod_calc
-module(battle_mod_calc).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.battle.hrl").
%%
%% Exported Functions
%%
-export([
		 calc_hurt_base/2, calc_hurt_force/2, calc_hurt_magic/2,
		 calc_hurt_resist/3, calc_hurt_crit/3, calc_hurt_parry/3,
		 calc_skill_ratio/5, calc_skill_plus/3, calc_hurt_random/1, calc_cure/3
		]).
-export([calc_hit/3, calc_resist/2, calc_crit/2, calc_parry/2]).

%%
%% API Functions
%%
%% -------------------------------------------------------
%% @desc    计算普通攻击基础伤害
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_base(AtkUnit, DefUnit) ->
	case battle_mod_misc:magic_pro(AtkUnit#unit.pro) of
		?true -> calc_hurt_magic(AtkUnit, DefUnit);
		?false -> calc_hurt_force(AtkUnit, DefUnit)
	end.

%% -------------------------------------------------------
%% @desc    计算治疗效果
%% @parm    AtkUnit          攻击方
%% -------------------------------------------------------
calc_cure(Unit, Times, Fator) ->
    {_Attr, AttrSecond, _AttrElite}    = battle_mod_misc:get_unit_attr(Unit),
    ?FUNC_BATTLE_CURE(AttrSecond#attr_second.magic_attack, Times, Fator).

%% -------------------------------------------------------
%% @desc    计算物理普通攻击伤害
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_force(AtkUnit, DefUnit) ->
	{_AtkAttr, AtkAttrSecond, _AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, DefAttrSecond, _DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_HURT_FORCE(AtkAttrSecond#attr_second.force_attack,
							AtkUnit#unit.lv,
							DefAttrSecond#attr_second.force_def,
							DefUnit#unit.lv,
							AtkUnit#unit.power,
							DefUnit#unit.power).
%% -------------------------------------------------------
%% @desc    计算法术普通攻击伤害
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_magic(AtkUnit, DefUnit) ->
	{_AtkAttr, AtkAttrSecond, _AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, DefAttrSecond, _DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_HURT_MAGIC(AtkAttrSecond#attr_second.magic_attack,
							AtkUnit#unit.lv,
							DefAttrSecond#attr_second.magic_def,
							DefUnit#unit.lv,
							AtkUnit#unit.power,
							DefUnit#unit.power).

%% -------------------------------------------------------
%% @desc    计算反击伤害
%% @parm    Hurt		   	 普通攻击伤害
%% @parm    AtkUnit      	 攻击方 
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_resist(Hurt, AtkUnit, DefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_RESIST_HURT(Hurt,
							 DefAttrElite#attr_elite.resist_h,
							 AtkAttrElite#attr_elite.r_resist_h).
%% -------------------------------------------------------
%% @desc    计算暴击伤害
%% @parm    Hurt		   	 普通攻击伤害
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_crit(Hurt, AtkUnit, DefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_CRIT_HURT(Hurt,
						   AtkAttrElite#attr_elite.crit_h,
						   DefAttrElite#attr_elite.r_crit_h).
%% -------------------------------------------------------
%% @desc    计算格挡减伤
%% @parm    Hurt		   	 普通攻击伤害
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% -------------------------------------------------------
calc_hurt_parry(Hurt, AtkUnit, DefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_PARRY_HURT(Hurt,
							DefAttrElite#attr_elite.parry_r_h,
							AtkAttrElite#attr_elite.r_parry).
%% -------------------------------------------------------
%% @desc    计算技能系数伤害
%% @parm    Hurt      	 伤害值
%% @parm    Num    	 	 排序位置
%% @parm    Ratio  	 	 技能系数|技能系数元祖
%% -------------------------------------------------------
calc_skill_ratio(Value, _Num, Times, _Idx, ?CONST_SYS_NUMBER_TEN_THOUSAND) ->
	Value div Times;
calc_skill_ratio(Value, _Num, Times, _Idx, Ratio) when is_number(Ratio) ->
	round(Value * Ratio / Times / ?CONST_SYS_NUMBER_TEN_THOUSAND);
calc_skill_ratio(Value, Num, Times, Idx, {?CONST_SKILL_RATIO_FLAG_ROW, Ratios}) when is_tuple(Ratios) ->
	N	= battle_mod_target:get_row(Idx),
	calc_skill_ratio(Value, Num, Times, Idx, element(N, Ratios));
calc_skill_ratio(Value, Num, Times, Idx, {?CONST_SKILL_RATIO_FLAG_COLUMN, Ratios}) when is_tuple(Ratios) ->
	N	= battle_mod_target:get_column(Idx),
	calc_skill_ratio(Value, Num, Times, Idx, element(N, Ratios));
calc_skill_ratio(Value, Num, Times, Idx, {?CONST_SKILL_RATIO_FLAG_COUNT, Ratios}) when is_tuple(Ratios) ->
	calc_skill_ratio(Value, Num, Times, Idx, element(Num, Ratios)).
%% -------------------------------------------------------
%% @desc    计算技能加成伤害
%% @parm    Hurt      	 伤害值
%% @parm    Num    	 	 排序位置
%% @parm    Plus  	 	 技能加成|技能加成元祖
%% -------------------------------------------------------
calc_skill_plus(Value, _Num, 0) -> Value;
calc_skill_plus(Value, _Num, Plus) when is_number(Plus) ->
	Value + Plus;
calc_skill_plus(Value, Num, PlusTuple) when is_tuple(PlusTuple) ->
	calc_skill_plus(Value, Num, element(Num, PlusTuple)).
%% -------------------------------------------------------
%% @desc    计算随机伤害
%% @parm    Hurt		   	 伤害
%% -------------------------------------------------------
calc_hurt_random(0) -> 0;
calc_hurt_random(Hurt) ->
	Num = misc_random:random(9000, 11000),
	misc:ceil(Hurt * Num / ?CONST_SYS_NUMBER_TEN_THOUSAND).


%% -------------------------------------------------------
%% @desc    计算命中
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% @return  bool():			?true | ?false
%% -------------------------------------------------------
calc_hit(_Skill, {Side, _AtkUnit}, {Side, _DefUnit}) -> ?true;
calc_hit(Skill, {_AtkSide, AtkUnit}, {_DefSide, DefUnit}) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_HIT(AtkAttrElite#attr_elite.hit + Skill#skill.skill_hit, DefUnit#unit.lv, DefAttrElite#attr_elite.dodge).
%% -------------------------------------------------------
%% @desc    计算反击
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% @return  bool():			?true | ?false
%% -------------------------------------------------------
calc_resist(#unit{resist = ?true}, _RDefUnit) -> ?true;
calc_resist(RAtkUnit, RDefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(RAtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(RDefUnit),
	?FUNC_BATTLE_RESIST(AtkAttrElite#attr_elite.resist, DefAttrElite#attr_elite.r_resist).
%% -------------------------------------------------------
%% @desc    计算暴击
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% @return  bool():			?true | ?false
%% -------------------------------------------------------
calc_crit(AtkUnit, DefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
%% 	?MSG_PRINT("~ncrit:~p~nr_crit:~p~n", [AtkAttrElite#attr_elite.crit, DefAttrElite#attr_elite.r_crit]),
	?FUNC_BATTLE_CRIT(AtkAttrElite#attr_elite.crit, DefAttrElite#attr_elite.r_crit).
%% -------------------------------------------------------
%% @desc    计算格挡
%% @parm    AtkUnit      	 攻击方
%% @parm    DefUnit    	 	 防御方
%% @return  bool():			?true | ?false
%% -------------------------------------------------------
calc_parry(AtkUnit, DefUnit) ->
	{_AtkAttr, _AtkAttrSecond, AtkAttrElite}	= battle_mod_misc:get_unit_attr(AtkUnit),
	{_DefAttr, _DefAttrSecond, DefAttrElite}	= battle_mod_misc:get_unit_attr(DefUnit),
	?FUNC_BATTLE_PARRY(DefAttrElite#attr_elite.parry, AtkAttrElite#attr_elite.r_parry).



%%
%% Local Functions
%%
