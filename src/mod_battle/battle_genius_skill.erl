%% Author: cobain
%% Created: 2012-11-27
%% Description: TODO: Add description to battle_genius_skill
-module(battle_genius_skill).

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
-export([
		 genius_skill_revise_anger/4,
		 genius_skill_front_revise_attr/4,
		 genius_skill_front_revise_hurt/3,
		 genius_skill_revise_target/3,
		 genius_skill_middle/4,
		 genius_skill_revise_cure/2,
		 genius_skill_cure/3,
		 genius_skill_back/1,
		 refresh_genius_skill/2,
		 genius_skill_refresh_bout/1
		]).

%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_GENIUS_TRIGGER_NULL            天赋技能触发点--空 
%% CONST_SKILL_GENIUS_TRIGGER_DEFAULT         天赋技能触发点--默认(战斗初始化触发) 
%% CONST_SKILL_GENIUS_TRIGGER_BOUT            天赋技能触发点--回合(回合刷新触发) 
%% CONST_SKILL_GENIUS_TRIGGER_MINUS_ANGER     天赋技能触发点--消耗怒气(技能消耗怒气触发) 

%% CONST_SKILL_GENIUS_TRIGGER_CURE            天赋技能触发点--治疗 
%% CONST_SKILL_GENIUS_TRIGGER_BE_CURE         天赋技能触发点--受治疗

%% CONST_SKILL_GENIUS_TRIGGER_CHANGE          天赋技能触发点--改变(生命、怒气、BUFF) 
%% CONST_SKILL_GENIUS_TRIGGER_ATK_ATTR        天赋技能触发点--攻击(修正属性) 
%% CONST_SKILL_GENIUS_TRIGGER_ATK_HURT        天赋技能触发点--攻击(修正伤害) 
%% CONST_SKILL_GENIUS_TRIGGER_DEF_ATTR        天赋技能触发点--防守(修正属性) 
%% CONST_SKILL_GENIUS_TRIGGER_DEF_HURT        天赋技能触发点--防守(修正伤害) 
%% CONST_SKILL_GENIUS_TRIGGER_ATK             天赋技能触发点--攻击 
%% CONST_SKILL_GENIUS_TRIGGER_DEF             天赋技能触发点--防守
%% CONST_SKILL_GENIUS_TRIGGER_ATK_TARGET	     天赋技能触发点--攻击(修正目标) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 修正怒气消耗
genius_skill_revise_anger(Battle, Side, Unit, Factor) ->
	GeniusSkill		= get_genius_skill_list(Unit),
	GeniusParamTemp	= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?true),
	GeniusParam		= battle_mod_misc:set_genius_param_triger(GeniusParamTemp, ?CONST_SKILL_GENIUS_TRIGGER_MINUS_ANGER),
	genius_skill_revise_anger(GeniusSkill, Battle, GeniusParam, Side, Unit, Factor).

genius_skill_revise_anger([GeniusSkill|GeniusSkills], Battle, GeniusParam, Side, Unit, Factor) ->
	Trigger			= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			DValue	= do_genius_skill(Battle, {Side, Unit}, ?null, GeniusParam, GeniusSkill),
			Factor2	= Factor + DValue,
			genius_skill_revise_anger(GeniusSkills, Battle, GeniusParam, Side, Unit, Factor2);
		_ -> genius_skill_revise_anger(GeniusSkills, Battle, GeniusParam, Side, Unit, Factor)
	end;
genius_skill_revise_anger([], _Battle, _GeniusParam, _Side, _Unit, Factor) -> Factor.
	
%% 修正属性
genius_skill_front_revise_attr(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam) ->
	AtkGeniusSkill	= get_genius_skill_list(AtkUnit),
	AtkGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_ATK_ATTR),
	{
	 Battle2, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}
	}	= genius_skill_front_revise_attr(AtkGeniusSkill, Battle, AtkGeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}),
	DefGeniusSkill	= get_genius_skill_list(DefUnit),
	DefGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_DEF_ATTR),
	{
	 Battle3, {AtkSide, AtkUnit3}, {DefSide, DefUnit3}
	}	= genius_skill_front_revise_attr(DefGeniusSkill, Battle2, DefGeniusParam, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}),
	{Battle3, {AtkSide, AtkUnit3}, {DefSide, DefUnit3}}.

genius_skill_front_revise_attr([GeniusSkill|GeniusSkills], Battle, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			{
			 Battle2, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}
			} = do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam, GeniusSkill),
			genius_skill_front_revise_attr(GeniusSkills, Battle2, GeniusParam, {AtkSide, AtkUnit2}, {DefSide, DefUnit2});
		_ ->
			genius_skill_front_revise_attr(GeniusSkills, Battle, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit})
	end;
genius_skill_front_revise_attr([], Battle, _GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}.

%% 修正伤害
genius_skill_front_revise_hurt({AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam) ->
	AtkGeniusSkill	= get_genius_skill_list(AtkUnit),
	AtkGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_ATK_HURT),
	HurtDValueTemp	= genius_skill_front_revise_hurt(AtkGeniusSkill, AtkGeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, 0),
	DefGeniusSkill	= get_genius_skill_list(DefUnit),
	DefGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_DEF_HURT),
	HurtDValue		= genius_skill_front_revise_hurt(DefGeniusSkill, DefGeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, HurtDValueTemp),
	GeniusParam#genius_param.hurt + HurtDValue.

genius_skill_front_revise_hurt([GeniusSkill|GeniusSkills], GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccHurt) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			Value		= do_genius_skill(battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam, GeniusSkill),
			AccHurt2	= AccHurt + Value,
			genius_skill_front_revise_hurt(GeniusSkills, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccHurt2);
		_ ->
			genius_skill_front_revise_hurt(GeniusSkills, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccHurt)
	end;
genius_skill_front_revise_hurt([], _GeniusParam, {_AtkSide, _AtkUnit}, {_DefSide, _DefUnit}, AccHurt) ->
	AccHurt.

%% 天赋技能触发点--攻击(修正目标)
genius_skill_revise_target(_Battle, {Side, _AtkIdx}, {Side, TargetList}) -> {Side, TargetList};
genius_skill_revise_target(Battle, {AtkSide, AtkIdx}, {TargetSide, TargetList}) ->
	AtkUnit			= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	AtkGeniusSkill	= get_genius_skill_list(AtkUnit),
	GeniusParam		= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?false),
	AtkGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_ATK_TARGET),
	genius_skill_revise_target(AtkGeniusSkill, Battle, AtkGeniusParam, {AtkSide, AtkUnit}, {TargetSide, TargetList}).

genius_skill_revise_target([GeniusSkill|GeniusSkills], Battle, GeniusParam, {AtkSide, AtkUnit}, {TargetSide, TargetList}) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			{TargetSide, TargetList2} = do_genius_skill(Battle, {AtkSide, AtkUnit}, {TargetSide, TargetList}, GeniusParam, GeniusSkill),
			genius_skill_revise_target(GeniusSkills, Battle, GeniusParam, {AtkSide, AtkUnit}, {TargetSide, TargetList2});
		_ -> genius_skill_revise_target(GeniusSkills, Battle, GeniusParam, {AtkSide, AtkUnit}, {TargetSide, TargetList})
	end;
genius_skill_revise_target([], _Battle, _GeniusParam, _Atk, {TargetSide, TargetList}) ->
	{TargetSide, TargetList}.




%% 战斗中执行
genius_skill_middle(Battle, {AtkSide, AtkIdx}, {DefSide, DefIdx}, GeniusParam) ->
	Battle2			=
		case battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx) of
			AtkUnit when is_record(AtkUnit, unit) andalso AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
				AtkGeniusSkill	= get_genius_skill_list(AtkUnit),
				AtkGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_ATK),
				genius_skill_middle(AtkGeniusSkill, Battle, AtkGeniusParam, {AtkSide, AtkIdx}, {DefSide, DefIdx});
			_ -> Battle
		end,
	case battle_mod_misc:get_unit(Battle2, DefSide, DefIdx) of
		DefUnit when is_record(DefUnit, unit) ->
%% 		DefUnit when is_record(DefUnit, unit) andalso DefUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
			DefGeniusSkill	= get_genius_skill_list(DefUnit),
			DefGeniusParam	= battle_mod_misc:set_genius_param_triger(GeniusParam, ?CONST_SKILL_GENIUS_TRIGGER_DEF),
			genius_skill_middle(DefGeniusSkill, Battle2, DefGeniusParam, {AtkSide, AtkIdx}, {DefSide, DefIdx});
		_ -> Battle2
	end.
genius_skill_middle([GeniusSkill|GeniusSkills], Battle, GeniusParam, {AtkSide, AtkIdx}, {DefSide, DefIdx}) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			AtkUnit		= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
			DefUnit		= battle_mod_misc:get_unit(Battle, DefSide, DefIdx),
			Battle2		= do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam, GeniusSkill),
			genius_skill_middle(GeniusSkills, Battle2, GeniusParam, {AtkSide, AtkIdx}, {DefSide, DefIdx});
		_ ->
			genius_skill_middle(GeniusSkills, Battle, GeniusParam, {AtkSide, AtkIdx}, {DefSide, DefIdx})
	end;
genius_skill_middle([], Battle, _GeniusParam, _Atk, _Def) ->
	Battle.

%% 治疗中执行(修正治疗效果)
genius_skill_revise_cure({AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	GeniusParamTemp	= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?false),
	GeniusParam		= battle_mod_misc:set_genius_param_triger(GeniusParamTemp, ?CONST_SKILL_GENIUS_TRIGGER_BE_CURE),
	GeniusSkill		= get_genius_skill_list(DefUnit),
	genius_skill_revise_cure(GeniusSkill, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, 0).
genius_skill_revise_cure([GeniusSkill|GeniusSkills], GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccFactor) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			Factor		= do_genius_skill(?null, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam, GeniusSkill),
			AccFactor2	= AccFactor + Factor,
			genius_skill_revise_cure(GeniusSkills, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccFactor2);
		_ ->
			genius_skill_revise_cure(GeniusSkills, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}, AccFactor)
	end;
genius_skill_revise_cure([], _GeniusParam, _Atk, _Def, AccFactor) ->
	AccFactor.

%% 治疗后执行(附加其他效果)
genius_skill_cure(Battle, {AtkSide, AtkIdx}, {DefSide, DefUnit}) ->
	AtkUnit			= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	GeniusSkill		= get_genius_skill_list(AtkUnit),
	GeniusParamTemp	= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?false),
	GeniusParam		= battle_mod_misc:set_genius_param_triger(GeniusParamTemp, ?CONST_SKILL_GENIUS_TRIGGER_CURE),
	{
	 Battle2, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}
	}		= genius_skill_cure(GeniusSkill, Battle, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}),
	Battle3	= battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit2),
	battle_mod_misc:set_unit(Battle3, DefSide, DefUnit2).
genius_skill_cure([GeniusSkill|GeniusSkills], Battle, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			{
			 Battle2, {AtkSide, AtkUnit2}, {DefSide, DefUnit2}
			}		= do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, GeniusParam, GeniusSkill),
			genius_skill_cure(GeniusSkills, Battle2, GeniusParam, {AtkSide, AtkUnit2}, {DefSide, DefUnit2});
		_ ->
			genius_skill_cure(GeniusSkills, Battle, GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit})
	end;
genius_skill_cure([], Battle, _GeniusParam, {AtkSide, AtkUnit}, {DefSide, DefUnit}) ->
	{Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}.


%% 天赋技能后续处理流程
genius_skill_back(Battle) ->
	GeniusParamTemp	= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?false),
	GeniusParam		= battle_mod_misc:set_genius_param_triger(GeniusParamTemp, ?CONST_SKILL_GENIUS_TRIGGER_CHANGE),
	GeniusList		= Battle#battle.genius_list,
	genius_skill_back(Battle, GeniusParam, GeniusList).
genius_skill_back(Battle, GeniusParam, [{Side, Idx}|GeniusList]) ->
	%% 触发天赋技能
	Unit			= battle_mod_misc:get_unit(Battle, Side, Idx),
	GeniusSkill		= get_genius_skill_list(Unit),
	Battle2			= genius_skill_back_trigger(GeniusSkill, Battle, GeniusParam, Side, Unit),
	%% 取消天赋技能
	Unit2			= battle_mod_misc:get_unit(Battle2, Side, Idx),
	GeniusTrigger	= get_genius_skill_trigger_list(Unit2),
	Battle3			= genius_skill_back_cancel(GeniusTrigger, Battle2, GeniusParam, Side, Unit2),
	genius_skill_back(Battle3, GeniusParam, GeniusList);
genius_skill_back(Battle, _GeniusParam, []) -> Battle.

%% 触发天赋技能
genius_skill_back_trigger([GeniusSkill|GeniusSkills], Battle, GeniusParam, Side, Unit) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			case check_genius_skill_trigger(Unit, GeniusSkill) of
				?true -> genius_skill_back_trigger(GeniusSkills, Battle, GeniusParam, Side, Unit);
				?false ->
					Battle2 = do_genius_skill(Battle, {Side, Unit}, ?null, GeniusParam, GeniusSkill),
					genius_skill_back_trigger(GeniusSkills, Battle2, GeniusParam, Side, Unit)
			end;
		_ -> genius_skill_back_trigger(GeniusSkills, Battle, GeniusParam, Side, Unit)
	end;
genius_skill_back_trigger([], Battle, _GeniusParam, _Side, _Unit) ->
	Battle.
%% 取消天赋技能
genius_skill_back_cancel([GeniusSkill|GeniusSkills], Battle, GeniusParam, Side, Unit) ->
	Trigger		= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(GeniusSkill) of
		Trigger ->
			Battle2 = undo_genius_skill(Battle, Side, Unit, GeniusParam, GeniusSkill),
			genius_skill_back_cancel(GeniusSkills, Battle2, GeniusParam, Side, Unit);
		_ ->
			genius_skill_back_cancel(GeniusSkills, Battle, GeniusParam, Side, Unit)
	end;
genius_skill_back_cancel([], Battle, _GeniusParam, _Side, _Unit) ->
	Battle.

%% 天赋技能触发点--回合(回合刷新触发) 
genius_skill_refresh_bout(Battle) ->
	UnitsLeft   	= Battle#battle.units_left,
    UnitsRight  	= Battle#battle.units_right,
	
	GeniusParamTemp	= battle_mod_misc:record_genius_param(0, ?null, 0, ?false, ?false, ?false),
	GeniusParam		= battle_mod_misc:set_genius_param_triger(GeniusParamTemp, ?CONST_SKILL_GENIUS_TRIGGER_BOUT),
	Battle2			= genius_skill_refresh_bout2(Battle, GeniusParam, ?CONST_BATTLE_UNITS_SIDE_LEFT, misc:to_list(UnitsLeft#units.units)),
	genius_skill_refresh_bout2(Battle2, GeniusParam, ?CONST_BATTLE_UNITS_SIDE_RIGHT, misc:to_list(UnitsRight#units.units)).

genius_skill_refresh_bout2(Battle, GeniusParam, Side, [Unit|UnitsList])
  when is_record(Unit, unit) andalso Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	GeniusSkill		= get_genius_skill_list(Unit),
	Battle2			= genius_skill_refresh_bout3(Battle, GeniusSkill, GeniusParam, Side, Unit#unit.idx),
	genius_skill_refresh_bout2(Battle2, GeniusParam, Side, UnitsList);
genius_skill_refresh_bout2(Battle, GeniusParam, Side, [_Unit|UnitsList]) ->
	genius_skill_refresh_bout2(Battle, GeniusParam, Side, UnitsList);
genius_skill_refresh_bout2(Battle, _GeniusParam, _Side, []) ->
	Battle.

genius_skill_refresh_bout3(Battle, [Skill|GeniusSkill], GeniusParam, Side, Idx) ->
	Trigger			= GeniusParam#genius_param.trigger,
	case get_genius_skill_trigger(Skill) of
		Trigger ->
			Unit	= battle_mod_misc:get_unit(Battle, Side, Idx),
			Battle2	= do_genius_skill(Battle, {Side, Unit}, ?null, GeniusParam, Skill),
			genius_skill_refresh_bout3(Battle2, GeniusSkill, GeniusParam, Side, Idx);
		_ ->
			genius_skill_refresh_bout3(Battle, GeniusSkill, GeniusParam, Side, Idx)
	end;
genius_skill_refresh_bout3(Battle, [], _GeniusParam, _Side, _Idx) ->
	Battle.
  
  
%%
%% Local Functions
%%

%% CONST_BATTLE_DISPLAY_GENIUS_ATK_FRONT    战斗表现--天赋技能攻击(前) 
%% CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT    战斗表现--天赋技能防守(前) 
%% CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK     战斗表现--天赋技能攻击(后) 
%% CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK     战斗表现--天赋技能防守(后) 
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
%% CONST_SKILL_GENIUS_EFFECT_ID_761 天赋技能效果ID--防守发生暴击时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_762 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_763 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_764 天赋技能效果ID--攻击被闪避时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_765 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%术攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_766 天赋技能效果ID--被治疗时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_767 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%双防持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_768 天赋技能效果ID--攻击时，有[arg1]%机率多攻击[arg2]个目标，并有[arg3]%机率增加[arg4]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_769 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_770 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_771 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%气血上限持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_772 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%法术防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_773 天赋技能效果ID--攻击时，有[arg1]%机率解除目标[arg2]的[arg3]个[arg4]buff，并有[arg5]%机率增加[arg6]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_774 天赋技能效果ID--攻击时，有[arg1]%机率封印目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_775 天赋技能效果ID--攻击时，有[arg1]%机率沉默目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
%% CONST_SKILL_GENIUS_EFFECT_ID_776 天赋技能效果ID--死亡时，有[arg1]%机率提升目标[arg2][arg3]%双攻持续[arg4]回合，并有[arg5]%机率增加[arg6]怒气

%% CONST_SKILL_GENIUS_EFFECT_ID_801	天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% CONST_SKILL_GENIUS_EFFECT_ID_301	天赋技能效果ID--默认，[arg1]回合内必然暴击
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect  = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_301}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
%% 	Unit2		= Unit#unit{genius_trigger = [Skill|Unit#unit.genius_trigger]},
	case lists:keymember(Skill#skill.skill_id, #skill.skill_id, Unit#unit.genius_trigger) of
		?true -> Battle;
		?false ->
			Key			= key(Side, Unit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_301, Skill, Effect, ?null),
					%% 加BUFF
					{
					 Battle2, Unit2, BuffDelete, BuffInsert
					}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, Unit),
					Unit3			= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, Unit2, BuffDelete, BuffInsert),
					Unit4			= Unit3#unit{genius_trigger = [Skill|Unit3#unit.genius_trigger]},
					DefAttrChange	= battle_mod_misc:attr_change_data(Unit, Unit4),					%% 属性变化
					BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
					
					FlagCrit		= battle_mod_misc:crit_flag(?null),
					AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_FRONT, 0, [], []),
					DefCmd			= battle_mod_misc:cmd_data(0, Side, Unit4, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT, 0, DefAttrChange, BuffChangeList),
					Battle3			= Battle2#battle{cmd_genius = [{Key, AtkCmd, [DefCmd]}|GeniusCmds]},
					battle_mod_misc:set_unit(Battle3, Side, Unit4)
			end
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_351	天赋技能效果ID--回合，有[arg1]%几率解除[arg2]个DEBUFF
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_351}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			%% 解除BUFF
			FlagCrit		= battle_mod_misc:crit_flag(?null),
			{Unit2, DefCmd}	= do_exec_uninstall_buff(Side, Unit, ?CONST_BUFF_NATURE_NEGATIVE, Effect#effect.arg2),
			Key				= key(Side, Unit2, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						AtkCmd		= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			Battle#battle{cmd_genius = GeniusCmds2};
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_401	天赋技能效果ID--技能消耗怒气，降低[arg1]%技能怒气消耗
do_genius_skill(_Battle, {_Side, _Unit}, _Def, _GeniusParam,
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_401}}) ->
	- Effect#effect.arg1;
%% CONST_SKILL_GENIUS_EFFECT_ID_451	天赋技能效果ID--治疗，有[arg1]%几率解除[arg2]个DEBUFF
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_451}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			%% 解除BUFF
			FlagCrit	= battle_mod_misc:crit_flag(?null),
			{DefUnit2, DefCmd}	= do_exec_uninstall_buff(DefSide, DefUnit, ?CONST_BUFF_NATURE_NEGATIVE, Effect#effect.arg2),
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false -> % XXX def实际上是攻击方，如神机8阵,不然，atk在前面没有修改，会有问题
                        AtkCmd      = 
                            if
                                DefSide =:= AtkSide ->
    						        battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []);
                                ?true ->
                                    battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], [])
                            end,
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			{Battle#battle{cmd_genius = GeniusCmds2}, {AtkSide, AtkUnit}, {DefSide, DefUnit2}};
		?false -> {Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_452	天赋技能效果ID--治疗，有[arg1]%几率增加[arg2]%攻击力[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_452}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_452, Skill, Effect, ?null),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
			
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], BuffChangeList),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			{Battle2#battle{cmd_genius = GeniusCmds2}, {AtkSide, AtkUnit}, {DefSide, DefUnit3}};
		?false -> {Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_501	天赋技能效果ID--受治疗，有[arg1]%几率增加[arg2]%治疗效果
do_genius_skill(_Battle, _Atk, _Def, _GeniusParam,
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_501}}) ->
	Effect#effect.arg2;
%% CONST_SKILL_GENIUS_EFFECT_ID_551	天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_551}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	Ratio		= round(Unit#unit.anger / Unit#unit.anger_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio > Effect#effect.arg1 ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
					ForceAtk    = AttrBaseSecond#attr_second.force_attack,
					DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit2, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrSecond#attr_second.force_attack,
																		   (Attr#attr.attr_second)#attr_second.force_attack,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_601	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力--HP改变
do_genius_skill(Battle, {Side, Unit},  _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_601}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	Ratio		= round(Unit#unit.hp / AttrSecond#attr_second.hp_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio < Effect#effect.arg1 ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_FORCE_DEF,
					ForceDef    = AttrBaseSecond#attr_second.force_def,
					DValue      = ForceDef * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit2, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrSecond#attr_second.force_def,
																		   (Attr#attr.attr_second)#attr_second.force_def,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_602	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力--HP改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_602}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	Ratio		= round(Unit#unit.hp / AttrSecond#attr_second.hp_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio < Effect#effect.arg1 ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
					MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
					DValue      = MagicAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit2, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),										  
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrSecond#attr_second.magic_attack,
																		   (Attr#attr.attr_second)#attr_second.magic_attack,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_603	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_603}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(AtkUnit),
	Ratio		= round(AtkUnit#unit.hp / AttrSecond#attr_second.hp_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio < Effect#effect.arg1 ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					{TargetSide, TargetType}	= Effect#effect.arg3,
					case battle_mod_target:target(Battle, AtkSide, AtkUnit#unit.idx, TargetSide, TargetType) of
						{DefSideNew, DefListNew} ->
							BuffList			= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_603, Skill, Effect, ?null),
							FlagCrit			= battle_mod_misc:crit_flag(?null),
							Fun	= fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
										  case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
											  ?true ->
												  %% 加BUFF
												  {
												   AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
												  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnitNew),
												  DefUnitNew3	    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
												  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnitNew, DefUnitNew3),
												  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
												  DefCmd			= battle_mod_misc:cmd_data(0, DefSideNew, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
												  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSideNew, DefUnitNew3),
												  AccBattle4		= battle_mod_misc:set_unit(AccBattle3, DefSideNew, DefUnitNew3),
												  {AccBattle4, [DefCmd|AccDefCmds]};
											  ?false -> {AccBattle, AccDefCmds}
										  end
								  end,
							{Battle2, DefCmds}	= lists:foldl(Fun, {Battle, []}, DefListNew),
							AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							Battle2#battle{cmd_genius = [{Key, AtkCmd, DefCmds}|GeniusCmds]};
						?null -> Battle
					end
			end;
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_651	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力--BUFF改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_651}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?true ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
					ForceAtk    = AttrBaseSecond#attr_second.force_attack,
					DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrSecond#attr_second.force_attack,
																		   (Attr#attr.attr_second)#attr_second.force_attack,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_652	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合--BUFF改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_652}}) ->
	Battle;
%% CONST_SKILL_GENIUS_EFFECT_ID_653	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率--BUFF改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_653}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	{_Attr, 	_AttrSecond, 	AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?true ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_E_CRIT,
					DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),										  
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrElite#attr_elite.crit,
																		   (Attr#attr.attr_elite)#attr_elite.crit,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_654	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度--BUFF改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_654}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?true ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_SPEED,
					Speed	    = AttrBaseSecond#attr_second.speed,
					DValue      = Speed * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit2, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),										  
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrSecond#attr_second.speed,
																		   (Attr#attr.attr_second)#attr_second.speed,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_655	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避--BUFF改变
do_genius_skill(Battle, {Side, Unit}, _Def, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_655}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	{_Attr, 	_AttrSecond, 	AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
%% 	?MSG_DEBUG("Effect#effect.arg1:~p  Unit#unit.buff:~p", [Effect#effect.arg1, Unit#unit.buff]),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?true ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType    = ?CONST_PLAYER_ATTR_E_DODGE,
					DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
					Unit2		= Unit#unit{attr = Attr, genius_trigger = [Skill|Unit#unit.genius_trigger]},
					Key			= key(Side, Unit2, Skill),
					GeniusCmds2	=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),										  
								AtkCmd			= battle_mod_misc:cmd_data(0, Side, Unit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								AttrChangeList	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   AttrElite#attr_elite.dodge,
																		   (Attr#attr.attr_elite)#attr_elite.dodge,
																		   []),
								DefCmd	= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, Side, Unit2);
				?false -> Battle
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_701	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%防御力(修正属性)--攻击(修正属性)
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_701}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(DefUnit),
			TypeForceDef	= ?CONST_PLAYER_ATTR_FORCE_DEF,
			TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
			ForceDef        = AttrBaseSecond#attr_second.force_def,
			MagicDef        = AttrBaseSecond#attr_second.magic_def,
			DValueForceDef  = ForceDef * Effect#effect.arg2 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			DValueMagicDef  = MagicDef * Effect#effect.arg2 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeForceDef, - DValueForceDef}, {TypeMagicDef, - DValueMagicDef}]),
			DefUnit2	    = DefUnit#unit{attr = Attr},
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit		= battle_mod_misc:crit_flag(?null),
						AttrChangeList	= [],
						DefCmd	= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT, 0, AttrChangeList, []),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit		= battle_mod_misc:crit_flag(?null),
						AttrChangeList	= [],
						AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_FRONT, 0, [], []),
						DefCmd	= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT, 0, AttrChangeList, []),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			{Battle#battle{cmd_genius = GeniusCmds2}, {AtkSide, AtkUnit}, {DefSide, DefUnit2}};
		?false -> {Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_702	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%法术防御力--攻击(修正属性)
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_702}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(DefUnit),
			TypeMagicDef    = ?CONST_PLAYER_ATTR_MAGIC_DEF,
			MagicDef        = AttrBaseSecond#attr_second.magic_def,
			DValueMagicDef  = MagicDef * Effect#effect.arg2 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr            = player_attr_api:attr_plus(DefUnit#unit.attr, [{TypeMagicDef, - DValueMagicDef}]),
			DefUnit2	    = DefUnit#unit{attr = Attr},
			
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit		= battle_mod_misc:crit_flag(?null),
						AttrChangeList	= [],
						DefCmd	= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT, 0, AttrChangeList, []),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit		= battle_mod_misc:crit_flag(?null),
						AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_FRONT, 0, [], []),
						AttrChangeList	= [],
						DefCmd	= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT, 0, AttrChangeList, []),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			{Battle#battle{cmd_genius = GeniusCmds2}, {AtkSide, AtkUnit}, {DefSide, DefUnit2}};
		?false -> {Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}}
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_703	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%生命上限[arg3]回合 
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, #genius_param{hurt = _Hurt},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_703}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_703, Skill, Effect, ?null),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
			
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], BuffChangeList),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
			battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_704	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%速度[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_704}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_704, Skill, Effect, ?null),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
			
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], BuffChangeList),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
			battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_705	天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%命中[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_705}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true ->
			BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_705, Skill, Effect, ?null),
			%% 加BUFF
			{
			 Battle2, DefUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
			DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
			DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
			BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
			
			Key				= key(AtkSide, AtkUnit, Skill),
			GeniusCmds2		=
				case lists:keytake(Key, 1, GeniusCmds) of
					{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], BuffChangeList),
						[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
					?false ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
			battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_706	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率降低[arg2]%治疗效果[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit},
				#genius_param{atk_type = AtkType},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_706}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case AtkType of
		?CONST_SKILL_TYPE_NORMAL ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_706, Skill, Effect, ?null),
					%% 加BUFF
					{
					 Battle2, DefUnit2, BuffDelete, BuffInsert
					}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
					DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
					DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),			%% 属性变化
					BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
					
					Key				= key(AtkSide, AtkUnit, Skill),
					GeniusCmds2		=
						case lists:keytake(Key, 1, GeniusCmds) of
							{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
								FlagCrit	= battle_mod_misc:crit_flag(?null),
								DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], BuffChangeList),
								[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
							?false ->
								FlagCrit	= battle_mod_misc:crit_flag(?null),
								AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_707	天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率解除[arg2]个BUFF
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit},
				#genius_param{atk_type = AtkType},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_707}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case AtkType of
		?CONST_SKILL_TYPE_NORMAL ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					%% 解除BUFF
					FlagCrit		= battle_mod_misc:crit_flag(?null),
					{DefUnit2, DefCmd}	= do_exec_uninstall_buff(DefSide, DefUnit, ?CONST_BUFF_NATURE_POSITIVE, Effect#effect.arg2),
					Key				= key(AtkSide, AtkUnit, Skill),
					GeniusCmds2		=
						case lists:keytake(Key, 1, GeniusCmds) of
							{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
								[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
							?false ->
								AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2			= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, DefSide, DefUnit2);
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_708	天赋技能效果ID--攻击(技能攻击)，有[arg1]%几率降低目标[arg2]%怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit},
				#genius_param{atk_type = AtkType},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_708}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case AtkType of
		?CONST_SKILL_TYPE_ACTIVE ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					AttrType		= ?CONST_PLAYER_ATTR_ANGER,
					DValue      	= DefUnit#unit.anger * Effect#effect.arg2 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
					Anger			= misc:betweet(DefUnit#unit.anger - DValue, 0, DefUnit#unit.anger_max),
                    DefUnit2        = battle_mod_misc:minus_anger_2(DefUnit, Anger),
%% 					DefUnit2		= DefUnit#unit{anger = Anger},
					Key				= key(AtkSide, AtkUnit, Skill),
					GeniusCmds2		=
						case lists:keytake(Key, 1, GeniusCmds) of
							{value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
								FlagCrit		= battle_mod_misc:crit_flag(?null),
								DefAttrChange	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   DefUnit#unit.anger,
																		   DefUnit2#unit.anger,
																		   []),
								DefCmd			= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
								[{Key, AtkCmd, [DefCmd|DefCmds]}|GeniusCmdsTemp];
							?false ->
								FlagCrit	= battle_mod_misc:crit_flag(?null),
								DefAttrChange	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																		   DefUnit#unit.anger,
																		   DefUnit2#unit.anger,
																		   []),
								AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle2			= Battle#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle2, DefSide, DefUnit2);
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_709	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%命中[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
				#genius_param{crit = Crit},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_709}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case Crit of
		?true ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
						?true ->
							BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_709, Skill, Effect, ?null),
							%% 加BUFF
							{
							 Battle2, AtkUnit2, BuffDelete, BuffInsert
							}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
							AtkUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
							DefAttrChange	= battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),					%% 属性变化
							BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
							
							FlagCrit		= battle_mod_misc:crit_flag(?null),
							AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							DefCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
							GeniusCmds2		= [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
							Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
							battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3);
						?false -> Battle
					end
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_710	天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%速度[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
				#genius_param{crit = Crit},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_710}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case Crit of
		?true ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
						?true ->
							BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_710, Skill, Effect, ?null),
							%% 加BUFF
							{
							 Battle2, AtkUnit2, BuffDelete, BuffInsert
							}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
							AtkUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
							DefAttrChange	= battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),					%% 属性变化
							BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
							
							FlagCrit		= battle_mod_misc:crit_flag(?null),
							AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							DefCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
							GeniusCmds2		= [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
							Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
							battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3);
						?false -> Battle
					end
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_711	天赋技能效果ID--攻击(死亡)，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, _Def,
				#genius_param{death = Death},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_711}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case Death of
		?true ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					{TargetSide, TargetType}	= Effect#effect.arg2,
					case battle_mod_target:target(Battle, AtkSide, AtkUnit#unit.idx, TargetSide, TargetType) of
						{DefSideNew, DefListNew} ->
							BuffList			= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_711, Skill, Effect, ?null),
							FlagCrit			= battle_mod_misc:crit_flag(?null),
							Fun	= fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
										  case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
											  ?true ->
												  %% 加BUFF
												  {
												   AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
												  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnitNew),
												  DefUnitNew3	    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
												  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnitNew, DefUnitNew3),
												  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
												  DefCmd			= battle_mod_misc:cmd_data(0, DefSideNew, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
												  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSideNew, DefUnitNew3),
												  AccBattle4		= battle_mod_misc:set_unit(AccBattle3, DefSideNew, DefUnitNew3),
												  {AccBattle4, [DefCmd|AccDefCmds]};
											  ?false -> {AccBattle, AccDefCmds}
										  end
								  end,
							{Battle2, DefCmds}	= lists:foldl(Fun, {Battle, []}, DefListNew),
							AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							Battle2#battle{cmd_genius = [{Key, AtkCmd, DefCmds}|GeniusCmds]};
						?null -> Battle
					end
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_712	天赋技能效果ID--攻击(死亡)，有[arg1]%几率增加[arg2]点怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, _Def,
				#genius_param{death = Death},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_712}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case Death of
		?true ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					FlagCrit			= battle_mod_misc:crit_flag(?null),
					case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
						?true ->
							AttrType	= ?CONST_PLAYER_ATTR_ANGER,
							Anger		= misc:betweet(AtkUnit#unit.anger + Effect#effect.arg2, 0, AtkUnit#unit.anger_max),
							AtkUnit2	= AtkUnit#unit{anger = Anger},
							AttrChange	= ?BATTLE_ATTR_CHANGE_DATA(AttrType,
																   AtkUnit#unit.anger,
																   AtkUnit2#unit.anger,
																   []),
							DefCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChange, []),
							Battle2		= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
							AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							Battle2#battle{cmd_genius = [{Key, AtkCmd, [DefCmd]}|GeniusCmds]};
						?false -> Battle
					end
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_713	天赋技能效果ID--攻击(普通攻击并暴击)，有[arg1]%几率增加免疫DEBUFF[arg2]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
				#genius_param{atk_type = AtkType, crit = Crit},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_713}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case {AtkType, Crit} of
		{?CONST_SKILL_TYPE_NORMAL, ?true} ->
			Key				= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
						?true ->
							BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_713, Skill, Effect, ?null),
							%% 加BUFF
							{
							 Battle2, AtkUnit2, BuffDelete, BuffInsert
							}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
							AtkUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
							DefAttrChange	= battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),					%% 属性变化
							BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
							
							FlagCrit		= battle_mod_misc:crit_flag(?null),
							AtkCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							DefCmd			= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
							GeniusCmds2		= [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
							Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
							battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3);
						?false -> Battle
					end
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_714 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率对目标[arg2]降低[arg3]%命中[arg4]回合 
do_genius_skill(Battle, {AtkSide, AtkUnit}, _Def,
				#genius_param{atk_type = AtkType},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_714}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	case AtkType of
		?CONST_SKILL_TYPE_NORMAL ->
			Key		= key(AtkSide, AtkUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					{TargetSide, TargetType}	= Effect#effect.arg2,
					case battle_mod_target:target(Battle, AtkSide, AtkUnit#unit.idx, TargetSide, TargetType) of
						{DefSideNew, DefListNew} ->
							BuffList			= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_714, Skill, Effect, ?null),
							FlagCrit			= battle_mod_misc:crit_flag(?null),
							Fun	= fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
										  case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
											  ?true ->
												  %% 加BUFF
												  {
												   AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
												  }				    = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnitNew),
												  DefUnitNew3	    = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
												  AttrChangeList    = battle_mod_misc:attr_change_data(DefUnitNew, DefUnitNew3),
												  BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
												  DefCmd			= battle_mod_misc:cmd_data(0, DefSideNew, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
												  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSideNew, DefUnitNew3),
												  AccBattle4		= battle_mod_misc:set_unit(AccBattle3, DefSideNew, DefUnitNew3),
												  {AccBattle4, [DefCmd|AccDefCmds]};
											  ?false -> {AccBattle, AccDefCmds}
										  end
								  end,
							{Battle2, DefCmds}	= lists:foldl(Fun, {Battle, []}, DefListNew),
							AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							Battle2#battle{cmd_genius = [{Key, AtkCmd, DefCmds}|GeniusCmds]};
						?null -> Battle
					end
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_751	天赋技能效果ID--防守，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
do_genius_skill(_Battle, {_AtkSide, _AtkUnit}, {_DefSide, _DefUnit},
				#genius_param{hurt = Hurt},
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_751}}) ->
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true -> - (Hurt * Effect#effect.arg2 div ?CONST_SYS_NUMBER_TEN_THOUSAND);
		?false -> 0
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_752	天赋技能效果ID--防守，有[arg1]%几率降低攻击者[arg2]%速度[arg3]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_752}}) ->
	Dead	= (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
	case Dead andalso misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		{?false, ?true} ->
			GeniusCmds		= Battle#battle.cmd_genius,
			BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_752, Skill, Effect, ?null),
			%% 加BUFF
			{
			 Battle2, AtkUnit2, BuffDelete, BuffInsert
			}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
			AtkUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
			DefAttrChange	= battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),					%% 属性变化
			BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
			Key				= key(DefSide, DefUnit, Skill),
			GeniusCmds2		=
				case lists:keymember(Key, 1, GeniusCmds) of
					?true -> GeniusCmds;
					?false ->
						FlagCrit	= battle_mod_misc:crit_flag(?null),
						AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
						DefCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
						[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
				end,
			Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
			battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3);
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_753	天赋技能效果ID--防守，伤害高于生命上限[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力[arg4]回合
do_genius_skill(Battle, _Atk, {DefSide, DefUnit},
				#genius_param{hurt = Hurt},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_753}}) ->
	GeniusCmds		= Battle#battle.cmd_genius,
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(DefUnit),
	Ratio		= round(Hurt * ?CONST_SYS_NUMBER_TEN_THOUSAND / AttrSecond#attr_second.hp_max),
	Dead		= (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
	if
		Dead =:= ?false andalso Ratio >= Effect#effect.arg1 ->
			case misc_random:odds(Effect#effect.arg2, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_753, Skill, Effect, ?null),
					%% 加BUFF
					{
					 Battle2, DefUnit2, BuffDelete, BuffInsert
					}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
					DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
					DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
					BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
					Key				= key(DefSide, DefUnit, Skill),
					GeniusCmds2		=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit	= battle_mod_misc:crit_flag(?null),
								AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
				?false -> Battle
			end;
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_754	天赋技能效果ID--防守(受暴击)，有[arg1]%几率降低[arg2]%伤害--防守(修正伤害)
do_genius_skill(_Battle, {_AtkSide, _AtkUnit}, {_DefSide, _DefUnit},
				#genius_param{crit = Crit, hurt = Hurt},
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_754}}) ->
	case Crit of
		?true ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true -> - (Hurt * Effect#effect.arg2 / ?CONST_SYS_NUMBER_TEN_THOUSAND);
				?false -> 0
			end;
		?false -> 0
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_755	天赋技能效果ID--防守(受暴击)，有[arg1]%几率增加[arg2]%闪避[arg3]回合
do_genius_skill(Battle, _Atk, {DefSide, DefUnit}, #genius_param{crit = Crit},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_755}}) ->
	Dead		= (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
	case {Dead, Crit} of
		{?false, ?true} ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					GeniusCmds		= Battle#battle.cmd_genius,
					BuffList		= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_755, Skill, Effect, ?null),
					%% 加BUFF
					{
					 Battle2, DefUnit2, BuffDelete, BuffInsert
					}				= battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
					DefUnit3		= battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
					DefAttrChange	= battle_mod_misc:attr_change_data(DefUnit, DefUnit3),					%% 属性变化
					BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
					Key				= key(DefSide, DefUnit, Skill),
					GeniusCmds2		=
						case lists:keymember(Key, 1, GeniusCmds) of
							?true -> GeniusCmds;
							?false ->
								FlagCrit	= battle_mod_misc:crit_flag(?null),
								AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
								DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
								[{Key, AtkCmd, [DefCmd]}|GeniusCmds]
						end,
					Battle3			= Battle2#battle{cmd_genius = GeniusCmds2},
					battle_mod_misc:set_unit(Battle3, DefSide, DefUnit3);
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_756	天赋技能效果ID--防守(死亡)，有[arg1]%几率复活，恢复[arg2]%生命
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit},
				#genius_param{death = Death},
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_756}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(DefUnit),
	GeniusCmds		= Battle#battle.cmd_genius,
	case Death of
		?true ->
			Key		= key(DefSide, DefUnit, Skill),
			case lists:keymember(Key, 1, GeniusCmds) of
				?true -> Battle;
				?false ->
					case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
						?true ->
							HpBase	    = AttrBaseSecond#attr_second.hp_max,
							DValue      = round(HpBase * Effect#effect.arg2 / ?CONST_SYS_NUMBER_TEN_THOUSAND),
							DefUnit2	= battle_mod_misc:plus_hp(DefUnit, DValue),
							DefUnit3	= DefUnit2#unit{state = ?CONST_BATTLE_UNIT_STATE_NORMAL},
							FlagCrit	= battle_mod_misc:crit_flag(?null),
							AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
%% 							AtkCmd		= battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], []),
							GeniusCmds2	= [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
							Battle2		= Battle#battle{cmd_genius = GeniusCmds2},
							battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3);
						?false -> Battle
					end
			end;
		?false -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_757 天赋技能效果ID--防守，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_757}}) ->
	GeniusCmds	= Battle#battle.cmd_genius,
	Key			= key(DefSide, DefUnit, Skill),
	Dead		= (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
	case {Dead, lists:keymember(Key, 1, GeniusCmds)} of
		{?false, ?false} ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					{TargetSide, TargetType}	= Effect#effect.arg2,
					case battle_mod_target:target(Battle, DefSide, DefUnit#unit.idx, TargetSide, TargetType) of
						{DefSideNew, DefListNew} ->
							BuffList			= battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_711, Skill, Effect, ?null),
							FlagCrit			= battle_mod_misc:crit_flag(?null),
							Fun	= fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
										  %% 加BUFF
										  {
										   AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
										  }					= battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnitNew),
										  DefUnitNew3		= battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
										  AttrChangeList	= battle_mod_misc:attr_change_data(DefUnitNew, DefUnitNew3),
										  BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
										  DefCmd			= battle_mod_misc:cmd_data(0, DefSideNew, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
										  AccBattle3		= battle_mod_misc:set_genius_list(AccBattle2, DefSideNew, DefUnitNew3),
										  AccBattle4		= battle_mod_misc:set_unit(AccBattle3, DefSideNew, DefUnitNew3),
										  {AccBattle4, [DefCmd|AccDefCmds]}
								  end,
							{Battle2, DefCmds}	= lists:foldl(Fun, {Battle, []}, DefListNew),
							AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
							Battle2#battle{cmd_genius = [{Key, AtkCmd, DefCmds}|GeniusCmds]};
						?null -> Battle
					end;
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_758 天赋技能效果ID--防守，有[arg1]%几率反击一次 
do_genius_skill(Battle, _Atk, {DefSide, DefUnit}, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_758}}) ->
	Dead		= (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
	case {Dead, DefUnit#unit.resist} of
		{?false, ?false} ->
			case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
				?true ->
					GeniusCmds	= Battle#battle.cmd_genius,
					Key			= key(DefSide, DefUnit, Skill),
					
					DefUnit2	= DefUnit#unit{resist = ?true},
					Battle2		= battle_mod_misc:set_unit(Battle, DefSide, DefUnit2),
					FlagCrit	= battle_mod_misc:crit_flag(?null),
					AtkCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
					DefCmd		= battle_mod_misc:cmd_data(0, DefSide, DefUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, [], []),
					Battle2#battle{cmd_genius = [{Key, AtkCmd, [DefCmd]}|GeniusCmds]};
				?false -> Battle
			end;
		_ -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_759 天赋技能效果ID--防守，当发生格挡时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]点怒气
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit}, GeniusParam,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_759}}) ->
    GeniusCmds  = Battle#battle.cmd_genius,
    Key         = key(DefSide, DefUnit, Skill),
    Dead        = (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
    #genius_param{atk_type = AtkType} = GeniusParam,
    IsSoul = DefUnit#unit.is_soul,
    if
        ?true =:= GeniusParam#genius_param.parry andalso ?false =:= Dead andalso ?CONST_SKILL_TYPE_NORMAL =:= AtkType andalso ?false =:= IsSoul -> 
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList            = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_759, Skill, Effect, ?null),
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                %% 加BUFF
                                {
                                 AccBattle2, DefUnit222, BuffDelete, BuffInsert
                                }                 = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnitNew2       = DefUnit222#unit{is_soul = ?true},
                                DefUnitNew3       = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
                                AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnitNew3),
                                BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                AtkCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmds           = battle_mod_misc:cmd_data(0, DefSide, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
                                AccBattle3        = battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnitNew3),
                                Battle2           = battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnitNew3),
                                {Battle2, AtkCmd, [DefCmds], DefUnitNew3, ?true};
                            ?false ->
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
%%                             Anger           = misc:betweet(NewDefUnit#unit.anger + Effect#effect.arg5, 0, NewDefUnit#unit.anger_max),
                            NewDefUnit2_2     = battle_mod_misc:plus_anger(NewDefUnit, Effect#effect.arg5),
                            NewDefUnit2       = NewDefUnit2_2#unit{is_soul = ?true},
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            DefAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewDefUnit#unit.anger,
                                                                       NewDefUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, DefSide, NewDefUnit2),
                            DefCmd          = battle_mod_misc:cmd_data(0, DefSide, NewDefUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_760 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_760}}) ->
    GeniusCmds  = Battle#battle.cmd_genius,
    Key         = key(DefSide, DefUnit, Skill),
    Dead        = (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
    if
        ?false =:= Dead -> 
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList            = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_760, Skill, Effect, ?null),
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                %% 加BUFF
                                {
                                 AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
                                }                 = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnitNew3       = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
                                AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnitNew3),
                                BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                AtkCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmds           = battle_mod_misc:cmd_data(0, DefSide, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
                                AccBattle3        = battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnitNew3),
                                Battle2           = battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnitNew3),
                                {Battle2, AtkCmd, [DefCmds], DefUnitNew3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewDefUnit2     = battle_mod_misc:plus_anger(NewDefUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            DefAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewDefUnit#unit.anger,
                                                                       NewDefUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, DefSide, NewDefUnit2),
                            DefCmd          = battle_mod_misc:cmd_data(0, DefSide, NewDefUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_761 天赋技能效果ID--防守发生暴击时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit}, GeniusParam,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_761}}) ->
    GeniusCmds  = Battle#battle.cmd_genius,
    Key         = key(DefSide, DefUnit, Skill),
    Dead        = (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
    if
        ?false =:= Dead andalso ?true =:= GeniusParam#genius_param.crit -> 
            {NewBattle, NewAtkCmd, NewDefCmds, NewDefUnit, Is1} = 
                case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                    ?true ->
                        BuffList            = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_761, Skill, Effect, ?null),
                        FlagCrit            = battle_mod_misc:crit_flag(?null),
                        %% 加BUFF
                        {
                         AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
                        }                 = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                        DefUnitNew3       = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
                        AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnitNew3),
                        BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                        AtkCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                        DefCmds           = battle_mod_misc:cmd_data(0, DefSide, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
                        AccBattle3        = battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnitNew3),
                        Battle2           = battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnitNew3),
                        {Battle2, AtkCmd, [DefCmds], DefUnitNew3, ?true};
                    ?false -> 
                        FlagCrit            = battle_mod_misc:crit_flag(?null),
                        AtkCmd              = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                        {Battle, AtkCmd, [], DefUnit, ?false}
                end,
            % 加怒气
            case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                ?true ->
                    NewDefUnit2     = battle_mod_misc:plus_anger(NewDefUnit, Effect#effect.arg5),
                    FlagCrit2       = battle_mod_misc:crit_flag(?null),
                    DefAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                               NewDefUnit#unit.anger,
                                                               NewDefUnit2#unit.anger,
                                                               []),
                    NewBattle2      = battle_mod_misc:set_unit(NewBattle, DefSide, NewDefUnit2),
                    DefCmd          = battle_mod_misc:cmd_data(0, DefSide, NewDefUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
                    NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd|NewDefCmds]}|GeniusCmds]};
                ?false ->
                    case Is1 of
                        ?true ->
                            NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                        ?false ->
                            Battle
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_762 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_762}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                            case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                                ?true ->
                                    BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_762, Skill, Effect, ?null),
                                    %% 加BUFF
                                    {
                                     Battle2, AtkUnit2, BuffDelete, BuffInsert
                                    }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                    AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                    DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                    BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                    
                                    FlagCrit        = battle_mod_misc:crit_flag(?null),
                                    AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                    DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                    Battle4         = battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit3),
                                    {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                                ?false -> 
                                    FlagCrit            = battle_mod_misc:crit_flag(?null),
                                    AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                    {Battle, AtkCmd, [], AtkUnit, ?false}
                            end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_763 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType, crit = Crit},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_763}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType andalso ?true =:= Crit ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                            case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                                ?true ->
                                    BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_763, Skill, Effect, ?null),
                                    %% 加BUFF
                                    {
                                     Battle2, AtkUnit2, BuffDelete, BuffInsert
                                    }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                    AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                    DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                    BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                    
                                    FlagCrit        = battle_mod_misc:crit_flag(?null),
                                    AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                    DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                    Battle4         = battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit3),
                                    {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                                ?false -> 
                                    FlagCrit            = battle_mod_misc:crit_flag(?null),
                                    AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                    {Battle, AtkCmd, [], AtkUnit, ?false}
                            end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_764 天赋技能效果ID--攻击被闪避时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType, hit = Hit},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_764}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType andalso ?false =:= Hit ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_764, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, AtkUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                Battle4         = battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit3),
                                {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                            ?false ->
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], AtkUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_765 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%术攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_765}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_765, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, AtkUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                GeniusCmds2     = [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
                                Battle3         = Battle2#battle{cmd_genius = GeniusCmds2},
                                Battle4         = battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3),
                                {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], AtkUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_766 天赋技能效果ID--被治疗时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_766}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
            ?true ->
                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_766, Skill, Effect, ?null),
                %% 加BUFF
                {
                 Battle2, AtkUnit2, BuffDelete, BuffInsert
                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                
                FlagCrit        = battle_mod_misc:crit_flag(?null),
                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                Battle4         = battle_mod_misc:set_unit(Battle2, AtkSide, AtkUnit3),
                {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
            ?false -> 
                FlagCrit            = battle_mod_misc:crit_flag(?null),
                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                {Battle, AtkCmd, [], AtkUnit, ?false}
        end,
    % 加怒气
    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        ?true ->
            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
            FlagCrit2       = battle_mod_misc:crit_flag(?null),
            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                       NewAtkUnit#unit.anger,
                                                       NewAtkUnit2#unit.anger,
                                                       []),
            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
            {NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]}, {AtkSide, NewAtkUnit2}, {DefSide, DefUnit}};
        ?false ->
            case Is1 of
                ?true ->
                    {NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]}, {AtkSide, NewAtkUnit}, {DefSide, DefUnit}};
                ?false ->
                    {Battle, {AtkSide, NewAtkUnit}, {DefSide, DefUnit}}
            end
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_767 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%双防持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {_AtkSide, _AtkUnit}, {DefSide, DefUnit}, _GeniusParam,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_767}}) ->
    GeniusCmds  = Battle#battle.cmd_genius,
    Key         = key(DefSide, DefUnit, Skill),
    Dead        = (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
    if
        ?false =:= Dead -> 
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList            = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_767, Skill, Effect, ?null),
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                %% 加BUFF
                                {
                                 AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
                                }                 = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnitNew3       = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
                                AttrChangeList    = battle_mod_misc:attr_change_data(DefUnit, DefUnitNew3),
                                BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                AtkCmd            = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmds           = battle_mod_misc:cmd_data(0, DefSide, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
                                AccBattle3        = battle_mod_misc:set_genius_list(AccBattle2, DefSide, DefUnitNew3),
                                Battle2           = battle_mod_misc:set_unit(AccBattle3, DefSide, DefUnitNew3),
                                {Battle2, AtkCmd, [DefCmds], DefUnitNew3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, DefSide, DefUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewDefUnit2     = battle_mod_misc:plus_anger(NewDefUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            DefAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewDefUnit#unit.anger,
                                                                       NewDefUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, DefSide, NewDefUnit2),
                            DefCmd          = battle_mod_misc:cmd_data(0, DefSide, NewDefUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                            
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_768	天赋技能效果ID--攻击时，有[arg1]%机率多攻击[arg2]个目标
do_genius_skill(Battle, _Atk, {TargetSide, TargetList}, _GeniusParam,
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_768}}) ->
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true -> battle_mod_target:revise_select(Battle, ?CONST_BATTLE_TARGET_TYPE_EXT_NEIGHBOUR, Effect#effect.arg2, {TargetSide, TargetList});
		?false -> {TargetSide, TargetList}
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_769 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_769}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    {NewBattle, NewAtkCmd, NewDefCmds, _NewDefUnit, Is1} = 
        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
            ?true ->
                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_769, Skill, Effect, ?null),
                %% 加BUFF
                {
                 Battle2, DefUnit2, BuffDelete, BuffInsert
                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                
                FlagCrit        = battle_mod_misc:crit_flag(?null),
                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                Battle4         = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),
                {Battle4, AtkCmd, [DefCmd], DefUnit3, ?true};
            ?false -> 
                FlagCrit            = battle_mod_misc:crit_flag(?null),
                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                {Battle, AtkCmd, [], DefUnit, ?false}
        end,
    % 加怒气
    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
        ?true ->
            NewAtkUnit2     = battle_mod_misc:plus_anger(AtkUnit, Effect#effect.arg5),
            FlagCrit2       = battle_mod_misc:crit_flag(?null),
            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                       AtkUnit#unit.anger,
                                                       NewAtkUnit2#unit.anger,
                                                       []),
            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
        ?false ->
            case Is1 of
                ?true ->
                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                ?false ->
                    Battle
            end
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_770 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType, crit = Crit},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_770}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType andalso ?true =:= Crit ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_770, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, AtkUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                GeniusCmds2     = [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
                                Battle3         = Battle2#battle{cmd_genius = GeniusCmds2},
                                Battle4         = battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3),
                                {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], AtkUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_771 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%气血上限持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit},
                #genius_param{atk_type = AtkType, crit = Crit},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_771}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType andalso ?true =:= Crit ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, NewAtkUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_771, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, AtkUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, AtkUnit),
                                AtkUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, AtkUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(AtkUnit, AtkUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                GeniusCmds2     = [{Key, AtkCmd, [DefCmd]}|GeniusCmds],
                                Battle3         = Battle2#battle{cmd_genius = GeniusCmds2},
                                Battle4         = battle_mod_misc:set_unit(Battle3, AtkSide, AtkUnit3),
                                {Battle4, AtkCmd, [DefCmd], AtkUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], AtkUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(NewAtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       NewAtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_772 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%法术防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_772}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, _NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_772, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, DefUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                Battle4         = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),
                                {Battle4, AtkCmd, [DefCmd], DefUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(AtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       AtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true -> 
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_773 天赋技能效果ID--攻击时，有[arg1]%机率解除目标[arg2]的[arg3]个[arg4]buff，并有[arg5]%机率增加[arg6]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {_DefSide, _DefUnit}, #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_773}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    % 加怒气
                    {NewBattle, NewDefCmd}       = 
                        case misc_random:odds(Effect#effect.arg5, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                AtkUnit2        = battle_mod_misc:plus_anger(AtkUnit, Effect#effect.arg6),
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                           AtkUnit#unit.anger,
                                                                           AtkUnit2#unit.anger,
                                                                           []),
                                Battle2         = battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
                                DefCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                                {Battle2, [DefCmd]};
                            %%                 Battle2#battle{cmd_genius = [{Key, [], [DefCmd2]}|GeniusCmds]};
                            ?false ->
                                {Battle, []}
                        end,
                    
                    {TargetSide, TargetType}    = Effect#effect.arg2,
                    case battle_mod_target:target(NewBattle, AtkSide, AtkUnit#unit.idx, TargetSide, TargetType) of
                        {DefSideNew, DefListNew} ->
                            Fun = fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
                                          case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                                              ?true ->
                                                  %% 解除BUFF
                                                  FlagCrit2        = battle_mod_misc:crit_flag(?null),
                                                  {AtkUnit2T, DefCmdT} = do_exec_uninstall_buff(DefSideNew, DefUnitNew, Effect#effect.arg4, Effect#effect.arg3),
                                                  Key             = key(DefSideNew, AtkUnit2T, Skill),
                                                  GeniusCmds2     =
                                                      case lists:keytake(Key, 1, AccDefCmds) of
                                                          {value, {Key, AtkCmd, DefCmds}, GeniusCmdsTemp} ->
                                                              [{Key, AtkCmd, [DefCmdT|DefCmds]}|GeniusCmdsTemp];
                                                          ?false ->
                                                              AtkCmd      = battle_mod_misc:cmd_data(0, DefSideNew, AtkUnit2T, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                                              [{Key, AtkCmd, [DefCmdT]}|AccDefCmds]
                                                      end,
                                                  AccBattle#battle{cmd_genius = GeniusCmds2};
                                              ?false -> AccBattle
                                          end
                                  end,
                            lists:foldl(Fun, {NewBattle, GeniusCmds++NewDefCmd}, DefListNew);
                        _ ->
                            NewBattle
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_774 天赋技能效果ID--攻击时，有[arg1]%机率封印目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_774}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, _NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_774, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, DefUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                Battle4         = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),
                                {Battle4, AtkCmd, [DefCmd], DefUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(AtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       AtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_775 天赋技能效果ID--攻击时，有[arg1]%机率沉默目标[arg2]回合，并有[arg3]%机率增加[arg4]怒气
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, #genius_param{atk_type = AtkType},
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_775}}) ->
    GeniusCmds      = Battle#battle.cmd_genius,
    Key             = key(AtkSide, AtkUnit, Skill),
    if
        ?CONST_SKILL_TYPE_NORMAL =:= AtkType ->
            case lists:keymember(Key, 1, GeniusCmds) of
                ?true -> Battle;
                ?false ->
                    {NewBattle, NewAtkCmd, NewDefCmds, _NewDefUnit, Is1} = 
                        case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                            ?true ->
                                BuffList        = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_775, Skill, Effect, ?null),
                                %% 加BUFF
                                {
                                 Battle2, DefUnit2, BuffDelete, BuffInsert
                                }               = battle_mod_misc:set_unit_buffs(Battle, BuffList, DefUnit),
                                DefUnit3        = battle_mod_exec:change_unit_buff(Battle2#battle.enlarge_rate, DefUnit2, BuffDelete, BuffInsert),
                                DefAttrChange   = battle_mod_misc:attr_change_data(DefUnit, DefUnit3),                  %% 属性变化
                                BuffChangeList  = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                
                                FlagCrit        = battle_mod_misc:crit_flag(?null),
                                AtkCmd          = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                DefCmd          = battle_mod_misc:cmd_data(0, DefSide, DefUnit3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, DefAttrChange, BuffChangeList),
                                Battle4         = battle_mod_misc:set_unit(Battle2, DefSide, DefUnit3),
                                {Battle4, AtkCmd, [DefCmd], DefUnit3, ?true};
                            ?false -> 
                                FlagCrit            = battle_mod_misc:crit_flag(?null),
                                AtkCmd              = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                                {Battle, AtkCmd, [], DefUnit, ?false}
                        end,
                    % 加怒气
                    case misc_random:odds(Effect#effect.arg4, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                        ?true ->
                            NewAtkUnit2     = battle_mod_misc:plus_anger(AtkUnit, Effect#effect.arg5),
                            FlagCrit2       = battle_mod_misc:crit_flag(?null),
                            AtkAttrChange   = ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,
                                                                       AtkUnit#unit.anger,
                                                                       NewAtkUnit2#unit.anger,
                                                                       []),
                            NewBattle2      = battle_mod_misc:set_unit(NewBattle, AtkSide, NewAtkUnit2),
                            DefCmd2         = battle_mod_misc:cmd_data(0, AtkSide, NewAtkUnit2, FlagCrit2, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AtkAttrChange, []),
                            NewBattle2#battle{cmd_genius = [{Key, NewAtkCmd, [DefCmd2|NewDefCmds]}|GeniusCmds]};
                        ?false ->
                            case Is1 of
                                ?true ->
                                    NewBattle#battle{cmd_genius = [{Key, NewAtkCmd, NewDefCmds}|GeniusCmds]};
                                ?false ->
                                    Battle
                            end
                    end
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_776 天赋技能效果ID--死亡时，有[arg1]%机率提升目标[arg2][arg3]%双攻持续[arg4]回合
do_genius_skill(Battle, {AtkSide, AtkUnit}, {DefSide, DefUnit}, _,
                Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_776}}) ->
    GeniusCmds  = Battle#battle.cmd_genius,
    Key         = key(DefSide, DefUnit, Skill),
    Dead        = (DefUnit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH),
    if
        ?true =:= Dead -> 
            {TargetSide, TargetType}    = Effect#effect.arg2,
            case battle_mod_target:target(Battle, DefSide, DefUnit#unit.idx, TargetSide, TargetType) of
                {DefSideNew, DefListNew} ->
                    BuffList            = battle_mod_buff:genius_skill_effect_buff(?CONST_SKILL_GENIUS_EFFECT_ID_776, Skill, Effect, ?null),
                    FlagCrit            = battle_mod_misc:crit_flag(?null),
                    Fun = fun(DefUnitNew, {AccBattle, AccDefCmds}) ->
                                  case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                                      ?true ->
                                          %% 加BUFF
                                          {
                                           AccBattle2, DefUnitNew2, BuffDelete, BuffInsert
                                          }                 = battle_mod_misc:set_unit_buffs(AccBattle, BuffList, DefUnitNew),
                                          DefUnitNew3       = battle_mod_exec:change_unit_buff(AccBattle2#battle.enlarge_rate, DefUnitNew2, BuffDelete, BuffInsert),
                                          AttrChangeList    = battle_mod_misc:attr_change_data(DefUnitNew, DefUnitNew3),
                                          BuffChangeList    = battle_mod_misc:buff_change_list(BuffDelete, BuffInsert),
                                          DefCmd            = battle_mod_misc:cmd_data(0, DefSideNew, DefUnitNew3, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
                                          AccBattle3        = battle_mod_misc:set_genius_list(AccBattle2, DefSideNew, DefUnitNew3),
                                          AccBattle4        = battle_mod_misc:set_unit(AccBattle3, DefSideNew, DefUnitNew3),
                                          {AccBattle4, [DefCmd|AccDefCmds]};
                                      ?false -> {AccBattle, AccDefCmds}
                                  end
                          end,
                    {Battle2, DefCmds}  = lists:foldl(Fun, {Battle, []}, DefListNew),
                    AtkCmd      = battle_mod_misc:cmd_data(0, AtkSide, AtkUnit, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK, 0, [], []),
                    Battle2#battle{cmd_genius = [{Key, AtkCmd, DefCmds}|GeniusCmds]};
                ?null -> Battle
            end;
        ?true ->
            Battle
    end;
%% CONST_SKILL_GENIUS_EFFECT_ID_801	天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位
do_genius_skill(Battle, _Atk, {TargetSide, TargetList}, _GeniusParam,
				#skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_801}}) ->
	case misc_random:odds(Effect#effect.arg1, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
		?true -> battle_mod_target:revise_select(Battle, Effect#effect.arg2, Effect#effect.arg3, {TargetSide, TargetList});
		?false -> {TargetSide, TargetList}
	end;
do_genius_skill(Battle, _Atk, _Def, _GeniusParam, Skill) ->
	?MSG_ERROR("GeniusSkill:~p~n", [{Skill#skill.skill_id, Skill#skill.lv}]),
	Battle.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_GENIUS_EFFECT_ID_551	天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_551}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	Ratio	= round(Unit#unit.anger / Unit#unit.anger_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio =< Effect#effect.arg1 ->
			AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
			ForceAtk    = AttrBaseSecond#attr_second.force_attack,
			DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),					
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_601	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力--HP改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_601}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	Ratio		= round(Unit#unit.hp / AttrSecond#attr_second.hp_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio >= Effect#effect.arg1 ->
			AttrType    = ?CONST_PLAYER_ATTR_FORCE_DEF,
			ForceDef    = AttrBaseSecond#attr_second.force_def,
			DValue      = ForceDef * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_602	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力--HP改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_602}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	{_Attr, 	AttrSecond, 	_AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
	Ratio		= round(Unit#unit.hp / AttrSecond#attr_second.hp_max * ?CONST_SYS_NUMBER_TEN_THOUSAND),
	if
		Ratio >= Effect#effect.arg1 ->
			AttrType    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
			MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
			DValue      = MagicAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_603	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
undo_genius_skill(Battle, _Side, _Unit, _GeniusParam, #skill{effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_603}}) ->
	Battle;
%% CONST_SKILL_GENIUS_EFFECT_ID_651	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力--BUFF改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_651}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?false ->
			AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
			ForceAtk    = AttrBaseSecond#attr_second.force_attack,
			DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_652	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合--BUFF改变
undo_genius_skill(Battle, _Side, _Unit, _GeniusParam, #skill{effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_652}}) ->
	Battle;
%% CONST_SKILL_GENIUS_EFFECT_ID_653	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率--BUFF改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_653}}) ->
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?false ->
			AttrType    = ?CONST_PLAYER_ATTR_E_CRIT,
			DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_654	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度--BUFF改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_654}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?false ->
			AttrType    = ?CONST_PLAYER_ATTR_SPEED,
			Speed	    = AttrBaseSecond#attr_second.speed,
			DValue      = Speed * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
%% CONST_SKILL_GENIUS_EFFECT_ID_655	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避--BUFF改变
undo_genius_skill(Battle, Side, Unit, _GeniusParam,
				Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_655}}) ->
	case lists:keymember(Effect#effect.arg1, #buff.buff_type, Unit#unit.buff) of
		?false ->
			AttrType    = ?CONST_PLAYER_ATTR_E_DODGE,
			DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, - DValue),
			Unit2		= Unit#unit{attr = Attr, genius_trigger = lists:delete(Skill, Unit#unit.genius_trigger)},
			battle_mod_misc:set_unit(Battle, Side, Unit2);
		?true -> Battle
	end;
undo_genius_skill(Battle, _Side, _Unit, _GeniusParam, Skill) ->
	?MSG_ERROR("GeniusSkill:~p~n", [{Skill#skill.skill_id, Skill#skill.lv}]),
	Battle.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% CONST_SKILL_GENIUS_EFFECT_ID_301	天赋技能效果ID--默认，[arg1]回合内必然暴击
refresh_genius_skill(Unit, Skill = #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_301}}) ->
	GeniusSkillTrigger	=
		case Effect#effect.arg1 of
			1 -> lists:delete(Skill, Unit#unit.genius_trigger);
			_N ->
				Skill2	= Skill#skill{effect = Effect#effect{arg1 = (Effect#effect.arg1 - 1)}},
				lists:keyreplace(Skill#skill.skill_id, #skill.skill_id, Unit#unit.genius_trigger, Skill2)
		end,
	Unit#unit{genius_trigger = GeniusSkillTrigger};
%% CONST_SKILL_GENIUS_EFFECT_ID_551	天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_551}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
	ForceAtk    = AttrBaseSecond#attr_second.force_attack,
	DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),					
	Unit#unit{attr = Attr};
%% CONST_SKILL_GENIUS_EFFECT_ID_601	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_601}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrType    = ?CONST_PLAYER_ATTR_FORCE_DEF,
	ForceDef    = AttrBaseSecond#attr_second.force_def,
	DValue      = ForceDef * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
%% CONST_SKILL_GENIUS_EFFECT_ID_602	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_602}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrType    = ?CONST_PLAYER_ATTR_MAGIC_ATTACK,
	MagicAtk    = AttrBaseSecond#attr_second.magic_attack,
	DValue      = MagicAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
%% CONST_SKILL_GENIUS_EFFECT_ID_603	天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合
refresh_genius_skill(Unit, #skill{effect = _Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_603}}) ->
	Unit;
%% CONST_SKILL_GENIUS_EFFECT_ID_651	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_651}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrType    = ?CONST_PLAYER_ATTR_FORCE_ATTACK,
	ForceAtk    = AttrBaseSecond#attr_second.force_attack,
	DValue      = ForceAtk * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
%% CONST_SKILL_GENIUS_EFFECT_ID_652	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合
refresh_genius_skill(Unit, #skill{effect = _Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_652}}) ->
	Unit;
%% CONST_SKILL_GENIUS_EFFECT_ID_653	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_653}}) ->
	AttrType    = ?CONST_PLAYER_ATTR_E_CRIT,
	DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
%% CONST_SKILL_GENIUS_EFFECT_ID_654	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_654}}) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrType    = ?CONST_PLAYER_ATTR_SPEED,
	Speed	    = AttrBaseSecond#attr_second.speed,
	DValue      = Speed * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
	%% CONST_SKILL_GENIUS_EFFECT_ID_655	天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避
refresh_genius_skill(Unit, #skill{effect = Effect = #effect{effect_id = ?CONST_SKILL_GENIUS_EFFECT_ID_655}}) ->
	AttrType    = ?CONST_PLAYER_ATTR_E_DODGE,
	DValue      = ?CONST_SYS_NUMBER_TEN_THOUSAND * Effect#effect.arg3 div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Attr        = player_attr_api:attr_plus(Unit#unit.attr, AttrType, DValue),
	Unit#unit{attr = Attr};
refresh_genius_skill(Unit, Skill) ->
	?MSG_ERROR("GeniusSkill:~p~n", [{Skill#skill.skill_id, Skill#skill.lv}]),
	Unit.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

do_exec_uninstall_buff(Side, Unit, BuffNature, Count) ->
	{
	 Unit2, BuffDelete
	}				= do_exec_uninstall_buff(Unit, Unit#unit.buff, BuffNature, Count, [], []),
	FlagCrit		= battle_mod_misc:crit_flag(?null),
	AttrChangeList	= battle_mod_misc:attr_change_data(Unit, Unit2),
	BuffChangeList	= battle_mod_misc:buff_change_list(BuffDelete, []),
	DefCmd			= battle_mod_misc:cmd_data(0, Side, Unit2, FlagCrit, ?CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK, 0, AttrChangeList, BuffChangeList),
	{Unit2, DefCmd}.

do_exec_uninstall_buff(Unit, BuffList, _BuffNature, Count, AccBuff, AccBuffDelete) when Count =< 0 ->
	BuffListNew		= misc:list_merge(BuffList, AccBuff),
	Unit2			= Unit#unit{buff = BuffListNew},
	{Unit2, AccBuffDelete};
do_exec_uninstall_buff(Unit, [Buff = #buff{nature = BuffNature}|BuffList], BuffNature, Count, AccBuff, AccBuffDelete) ->
	Unit2			= battle_mod_buff:buff_uninstall(Unit, Buff),
	do_exec_uninstall_buff(Unit2, BuffList, BuffNature, Count - 1, AccBuff, [Buff|AccBuffDelete]);
do_exec_uninstall_buff(Unit, [Buff|BuffList], BuffNature, Count, AccBuff, AccBuffDelete) ->
	do_exec_uninstall_buff(Unit, BuffList, BuffNature, Count, [Buff|AccBuff], AccBuffDelete);
do_exec_uninstall_buff(Unit, [], _BuffNature, _Count, AccBuff, AccBuffDelete) ->
	Unit2			= Unit#unit{buff = AccBuff},
	{Unit2, AccBuffDelete}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
key(AtkSide, AtkUnit, Skill) ->
	{Skill#skill.skill_id, Skill#skill.lv, AtkSide, AtkUnit#unit.idx}.

%% 获取天赋技能触发点
get_genius_skill_trigger(#skill{type = ?CONST_SKILL_TYPE_PASSIVE, effect = #effect{arg10 = Trigger}}) -> Trigger;
get_genius_skill_trigger(_) -> ?CONST_SKILL_GENIUS_TRIGGER_NULL.

%% 获取天赋技能列表
get_genius_skill_list(#unit{genius_skill = GeniusSkills}) when is_list(GeniusSkills) -> GeniusSkills;
get_genius_skill_list(#unit{genius_skill = GeniusSkill}) when is_record(GeniusSkill, skill)-> [GeniusSkill];
get_genius_skill_list(_) -> [].

%% 获取已触发天赋技能列表
get_genius_skill_trigger_list(#unit{genius_trigger = TriggerGeniusSkills}) when is_list(TriggerGeniusSkills) -> TriggerGeniusSkills;
get_genius_skill_trigger_list(_) -> [].


%% 检查当前被动技能是否已出发
check_genius_skill_trigger(Unit, Skill) ->
	case lists:keymember(Skill#skill.skill_id, #skill.skill_id, Unit#unit.genius_trigger) of
		?true -> ?true;
		?false -> ?false
	end.