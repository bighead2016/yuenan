
-module(battle_mod_misc).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/record.data.hrl").
-include("../include/record.goods.data.hrl").
-include("../include/record.map.hrl").
-include("../include/record.battle.hrl").
-include("../include/record.guild.hrl").

%%
%% Exported Functions
%%
-export([get_unit_attr/1, get_unit_attr_base/1, get_unit_buff/1, get_unit_id/1, minus_anger_2/2]).
-export([set_unit_state/2]).
-export([set_unit_buffs/3]).
-export([get_unit/3, get_unit_by_id/3, get_unit_min_hp/2, get_unit_max_magic_attack/2, get_unit_all/2, get_unit_all_magic/2,
		 get_unit_random/3, get_monster_ids/1, get_online_player_ids/2,
         set_unit/3, set_unit_list/3, cumsum_hurt/3, revise_hp_tuple/2]).
-export([unit_count/1, clac_hurt_tuple/2, auto_select_skill/1]).
-export([
		 check_auto/1, check_inevitable_crit/1, check_invincible/2, check_immune_crit/5,
		 chenk_bout_over/1, check_battle_over/1, check_skill/2, set_skill_cd/1, decrease_skill_cd/1
		]).
-export([cmd_data/7, cmd_data/8, cmd_data_atk_change/5, attr_change_data/2, buff_change_list/2, set_resist_list/4, set_genius_list/3, display/2, crit_flag/1,
		 init_battle_report_flag/1, record_unit/5, record_operate/4, record_genius_param/6, set_genius_param_triger/2]).
-export([record_temp_param/0, refresh_temp_param/7, set_temp_param_death/2]).
-export([atk_type/1, key/2, key/3, speed_sort/1, buff_sort/1, magic_pro/1, convert_target_side/2]).
-export([plus_anger/2, suck_hp/2, change_cure_effect/1, minus_hp/3, plus_hp/2, minus_anger/2, minus_anger/4, minus_hp_max/2]).
%% -export([calc_cure_value/3]).
-export([set_battle_memory/2, get_unit_min_hp/3]).
%%
%% API Functions
%%

%% 获取战斗单元属性
get_unit_attr(Unit) ->
	Attr 		= Unit#unit.attr,
	AttrSecond 	= Attr#attr.attr_second,
	AttrElite 	= Attr#attr.attr_elite,
	{Attr, AttrSecond, AttrElite}.
%% 获取战斗单元基础属性
get_unit_attr_base(Unit) ->
	AttrBase		= Unit#unit.attr_base,
	AttrBaseSecond 	= AttrBase#attr.attr_second,
	AttrBaseElite 	= AttrBase#attr.attr_elite,
	{AttrBase, AttrBaseSecond, AttrBaseElite}.
%% 获取战斗单元BUFF列表(按优先级排序)
get_unit_buff(Unit) ->
	buff_sort(Unit#unit.buff).

%% 获取战斗单元ID
get_unit_id(Unit) ->
	case Unit#unit.type of
		?CONST_SYS_PLAYER -> (Unit#unit.unit_ext)#unit_ext_player.user_id;
		?CONST_SYS_PARTNER -> (Unit#unit.unit_ext)#unit_ext_partner.partner_id;
		?CONST_SYS_MONSTER -> (Unit#unit.unit_ext)#unit_ext_monster.monster_id
	end.
%% get_unit_ai_list(Battle) ->
%% 	{LeftId, RightId} = get({left_id, right_id}),
%% 	case monster_api:monster(RightId) of
%% 		Monster when is_record(Monster, monster) ->
%% 			AiId  = Monster#monster.ai_id,
%% 			AiRec = data_ai:get_ai(AiId);
%% 		_Other ->
%% 			Battle
%% 	end.
%% get_unit_ai_list(Battle, TargetList) ->
	
%% get战斗单元
get_unit(Battle, Side, Idx)  ->
	Units	= case Side of
				  ?CONST_BATTLE_UNITS_SIDE_LEFT  -> Battle#battle.units_left;
				  ?CONST_BATTLE_UNITS_SIDE_RIGHT -> Battle#battle.units_right
			  end,
%% 	?MSG_ERROR("~nIdx:~p~nUnits：~p~n", [Idx, Units]),
	case element(Idx, Units#units.units) of
		Unit when is_record(Unit, unit) -> Unit;
		_ -> ?null
	end.

%% get自己的战斗单元
get_unit_by_id(Battle, UnitType, UserId)  ->
	case battle_mod_misc:key(Battle, UnitType, UserId) of
		{Side, Idx} ->
			get_unit(Battle, Side, Idx);
		?null -> Battle
	end.

%%---------------------------------hp比率最少1人-----------------------------------------------------zh
%% get生命最少的战斗单元
get_unit_min_hp(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) ->
	get_unit_min_hp(misc:to_list((Battle#battle.units_left)#units.units));
get_unit_min_hp(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT) ->
	get_unit_min_hp(misc:to_list((Battle#battle.units_right)#units.units)).

get_unit_min_hp(UnitList) ->
	get_unit_min_hp2(UnitList, ?null).
get_unit_min_hp2([Unit|UnitList], ?null)
  when is_record(Unit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	get_unit_min_hp2(UnitList, Unit);
get_unit_min_hp2([Unit|UnitList], AccUnit)
  when is_record(Unit, unit) andalso
	   is_record(AccUnit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	AccRatio	= AccUnit#unit.hp / ((AccUnit#unit.attr)#attr.attr_second)#attr_second.hp_max,
	Ratio		= Unit#unit.hp / ((Unit#unit.attr)#attr.attr_second)#attr_second.hp_max,
	if
		AccRatio > Ratio -> get_unit_min_hp2(UnitList, Unit);
		?true -> get_unit_min_hp2(UnitList, AccUnit)
	end;
get_unit_min_hp2([_Unit|UnitList], AccUnit) ->
	get_unit_min_hp2(UnitList, AccUnit);
get_unit_min_hp2([], AccUnit) ->
	AccUnit.

%%---------------------------------hp比率最少n人-----------------------------------------------------zr
%% get生命最少的战斗单元
get_unit_min_hp(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Count) ->
	get_unit_min_hp_2(misc:to_list((Battle#battle.units_left)#units.units), Count);
get_unit_min_hp(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Count) ->
	get_unit_min_hp_2(misc:to_list((Battle#battle.units_right)#units.units), Count).

get_unit_min_hp_2(UnitList, Count) ->
    UnitRatioList = sort_hp_ratio(UnitList, []),
    get_unit_min_hp_2_2(UnitRatioList, Count, 0, []).

%% 按现有hp比率排序
%% 1.去掉0血的
%% 2.排序
sort_hp_ratio([Unit|UnitList], CurList)
  when is_record(Unit, unit) andalso
       Unit#unit.state =:= ?CONST_BATTLE_UNIT_STATE_DEATH ->
    sort_hp_ratio(UnitList, CurList);
sort_hp_ratio([Unit|UnitList], CurList)
  when is_record(Unit, unit)
    ->
    % 当前单元的hp比率
    Ratio = Unit#unit.hp / ((Unit#unit.attr)#attr.attr_second)#attr_second.hp_max,
    CurList2 = lists:sort(fun sort_insert/2, [{Ratio, Unit}|CurList]),
    sort_hp_ratio(UnitList, CurList2);
sort_hp_ratio([_Unit|UnitList], CurList) ->
    sort_hp_ratio(UnitList, CurList);
sort_hp_ratio([], CurList) ->
    CurList.

sort_insert({Ratio1, _}, {Ratio2, _}) when Ratio1 =< Ratio2 -> ?true;
sort_insert(_, _) -> ?false.

get_unit_min_hp_2_2([{_Ratio, Unit}|Tail], Total, Count, ResultList) when Count < Total -> % ok
    get_unit_min_hp_2_2(Tail, Total, Count+1, [Unit|ResultList]);
get_unit_min_hp_2_2([], _Total, _Count, ResultList) -> % 没了
    ResultList;
get_unit_min_hp_2_2(_, _Total, _Count, ResultList) -> % 超了
    ResultList.

%%--------------------------------法术攻击力最大-----------------------------------------------------
%% get法术攻击力最大的战斗单元
get_unit_max_magic_attack(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) ->
	get_unit_max_magic_attack(misc:to_list((Battle#battle.units_left)#units.units));
get_unit_max_magic_attack(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT) ->
	get_unit_max_magic_attack(misc:to_list((Battle#battle.units_right)#units.units)).

get_unit_max_magic_attack(UnitList) ->
	get_unit_max_magic_attack2(UnitList, ?null).
get_unit_max_magic_attack2([Unit|UnitList], ?null)
  when is_record(Unit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	get_unit_max_magic_attack2(UnitList, Unit);
get_unit_max_magic_attack2([Unit|UnitList], AccUnit)
  when is_record(Unit, unit) andalso
	   is_record(AccUnit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	AccMagicAttack	= ((AccUnit#unit.attr)#attr.attr_second)#attr_second.magic_attack,
	MagicAttack		= ((Unit#unit.attr)#attr.attr_second)#attr_second.magic_attack,
	if
		MagicAttack > AccMagicAttack -> get_unit_max_magic_attack2(UnitList, Unit);
		?true -> get_unit_max_magic_attack2(UnitList, AccUnit)
	end;
get_unit_max_magic_attack2([_Unit|UnitList], AccUnit) ->
	get_unit_max_magic_attack2(UnitList, AccUnit);
get_unit_max_magic_attack2([], AccUnit) ->
	AccUnit.

%% get全部战斗单元
get_unit_all(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) ->
%% 	?MSG_PRINT("~n~p~n", [Battle#battle.units_left]),
	get_unit_all(misc:to_list((Battle#battle.units_left)#units.units));
get_unit_all(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT) ->
%% 	?MSG_PRINT("~n~p~n", [Battle#battle.units_right]),
	get_unit_all(misc:to_list((Battle#battle.units_right)#units.units));
get_unit_all(_Battle, Data) ->
	?MSG_ERROR("ERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERRORERROR~nData:~p~n", [Data]),
	[].

get_unit_all(UnitList) ->
	get_unit_all2(UnitList, []).
get_unit_all2([Unit|UnitList], Acc)
  when is_record(Unit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	get_unit_all2(UnitList, [Unit|Acc]);
get_unit_all2([_Unit|UnitList], Acc) ->
	get_unit_all2(UnitList, Acc);
get_unit_all2([], Acc) -> Acc.

%% get全部法术战斗单元
get_unit_all_magic(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) ->
	get_unit_all_magic(misc:to_list((Battle#battle.units_left)#units.units));
get_unit_all_magic(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT) ->
	get_unit_all_magic(misc:to_list({Battle#battle.units_right}#units.units)).

get_unit_all_magic(UnitList) ->
	get_unit_all_magic2(UnitList, []).
get_unit_all_magic2([Unit|UnitList], Acc)
  when is_record(Unit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case magic_pro(Unit#unit.pro) of
		?true -> get_unit_all_magic2(UnitList, [Unit|Acc]);
		?false -> get_unit_all_magic2(UnitList, Acc)
	end;
get_unit_all_magic2([_Unit|UnitList], Acc) ->
	get_unit_all_magic2(UnitList, Acc);
get_unit_all_magic2([], Acc) -> Acc.

%% get全部战斗单元中随机Count个
get_unit_random(Battle, Side, Count) ->
	UnitList	= get_unit_all(Battle, Side),
	misc_random:random_list_norepeat(UnitList, Count).


%% set战斗单元
set_unit_list(Battle, Side, [Unit|UnitList]) ->
	Battle2	= set_unit(Battle, Side, Unit),
	set_unit_list(Battle2, Side, UnitList);
set_unit_list(Battle, _Side, []) ->
	Battle.
set_unit(Battle, Side, Unit) ->
	case Side of
		?CONST_BATTLE_UNITS_SIDE_LEFT  ->
			Units		= Battle#battle.units_left,
			UnitsTuple	= setelement(Unit#unit.idx, Units#units.units, Unit),
			Units2		= Units#units{units = UnitsTuple},
			Battle#battle{units_left = Units2};
		?CONST_BATTLE_UNITS_SIDE_RIGHT ->
			Units		= Battle#battle.units_right,
			UnitsTuple	= setelement(Unit#unit.idx, Units#units.units, Unit),
			Units2		= Units#units{units = UnitsTuple},
			Battle#battle{units_right = Units2}
	end.
	
%% 统计累加伤害
cumsum_hurt(Battle, _Side, 0) -> Battle;
cumsum_hurt(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Hurt) ->
	Battle#battle{hurt_left = Hurt + Battle#battle.hurt_left};
cumsum_hurt(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Hurt) ->
	Battle#battle{hurt_right = Hurt + Battle#battle.hurt_right}.

%% 校正生命元祖
revise_hp_tuple({Hp1, Hp2, Hp3, Hp4, Hp5, Hp6, Hp7, Hp8, Hp9},
				{HpTemp1, HpTemp2, HpTemp3, HpTemp4, HpTemp5, HpTemp6, HpTemp7, HpTemp8, HpTemp9}) ->
	F = fun(Hp, HpTemp) -> if Hp =< HpTemp -> Hp; ?true -> HpTemp end end,
	{
	 F(Hp1, HpTemp1), F(Hp2, HpTemp2), F(Hp3, HpTemp3),
	 F(Hp4, HpTemp4), F(Hp5, HpTemp5), F(Hp6, HpTemp6),
	 F(Hp7, HpTemp7), F(Hp8, HpTemp8), F(Hp9, HpTemp9)
	}.

%% 设置战斗单元状态
set_unit_state(Unit, State) ->
	Unit#unit{state = State}.


%% 设置战斗单元BUFF
set_unit_buffs(Battle, BuffList, Unit) ->
	set_unit_buffs(Battle, BuffList, Unit, [], []).

set_unit_buffs(Battle, [Buff|BuffList], Unit, AccDelete, AccInsert) ->
	case check_buff(Unit, Buff) of
		?ok ->
			{Battle2, Buff2}	= buff_generator(Battle, Buff),
			{
			 Unit2, AccDelete2, AccInsert2
			}	= set_unit_buff(Buff2, Unit, AccDelete, AccInsert),
			set_unit_buffs(Battle2, BuffList, Unit2, AccDelete2, AccInsert2);
		{?error, _} -> set_unit_buffs(Battle, BuffList, Unit, AccDelete, AccInsert)
	end;
set_unit_buffs(Battle, [], Unit, AccDelete, AccInsert) ->
	{Battle, Unit, AccDelete, AccInsert}.

%% 检查战斗单元免疫BUFF和对立BUFF类型列表
check_buff(Unit, Buff) ->
	case check_immune_buff(Unit, Buff) of
		?ok -> check_oppose_buff(Buff#buff.oppose_buff_type, Unit#unit.buff);
		_ -> {?error, 110}
	end.
%% 检查战斗单元免疫BUFF
check_immune_buff(Unit, Buff) ->
	ImmuneBuffs		= get_unit_immune_buffs(Unit),
	case lists:member(Buff#buff.buff_type, ImmuneBuffs) of
		?true -> {?error, ?CONST_BATTLE_BUFF_IMMUNE};% 战斗单元免疫BUFF
		?false -> ?ok
	end.
%% 检查对立BUFF类型列表
check_oppose_buff([OpposeBuffType|OpposeBuffTypes], BuffList) ->
	case lists:member(OpposeBuffType, BuffList) of
		?true -> {?error, ?CONST_BATTLE_BUFF_OPPOSE};% 已有对立BUFF
		?false -> check_oppose_buff(OpposeBuffTypes, BuffList)
	end;
check_oppose_buff([], _BuffList) -> ?ok.

%% 增加生命上限
set_unit_buff(Buff, Unit, AccDelete, AccInsert) when is_record(Buff, buff) ->
	{
	 BuffList, AccDelete2, AccInsert2
	}			= set_buff(Buff, Unit#unit.buff, AccDelete, AccInsert),
	Unit2		= Unit#unit{buff = BuffList},
	{Unit2, AccDelete2, AccInsert2};
set_unit_buff(_Buff, Unit, AccDelete, AccInsert) ->
	{Unit, AccDelete, AccInsert}.

set_buff(Buff, BuffList, AccDelete, AccInsert) ->
	case lists:keyfind(Buff#buff.buff_type, #buff.buff_type, BuffList) of
		BuffOld when is_record(BuffOld, buff) ->
			case Buff#buff.relation of
				?CONST_BUFF_RELATION_PLUS ->% 同类型BUFF关系--叠加
					Value		= misc:min(BuffOld#buff.buff_value + Buff#buff.buff_value, Buff#buff.limit),
					BuffNew		= Buff#buff{buff_value = Value},
					BuffList2	= lists:delete(BuffOld, BuffList),
					BuffList3	= [BuffNew|BuffList2],
					{BuffList3, [BuffOld|AccDelete], [BuffNew|AccInsert]};
				?CONST_BUFF_RELATION_REPLACE ->% 同类型BUFF关系--替换
					if
						Buff#buff.buff_value > BuffOld#buff.buff_value ->
							BuffList2	= lists:delete(BuffOld, BuffList),
							BuffList3	= [Buff|BuffList2],
							{BuffList3, [BuffOld|AccDelete], [Buff|AccInsert]};
						?true ->
							{BuffList, AccDelete, AccInsert}
					end;
				?CONST_BUFF_RELATION_COEXIST ->% 同类型BUFF关系--共存
					{[Buff|BuffList], AccDelete, [Buff|AccInsert]};
				?CONST_BUFF_RELATION_MUTEX ->% 同类型BUFF关系--互斥
					{BuffList, AccDelete, AccInsert}
			end;
		_ ->
			{[Buff|BuffList], AccDelete, [Buff|AccInsert]}
	end.

%% 获取战斗单元免疫BUFF列表
get_unit_immune_buffs(#unit{unit_ext = UnitExt})
  when is_record(UnitExt, unit_ext_monster) ->
	UnitExt#unit_ext_monster.immune_buffs;
get_unit_immune_buffs(_Unit) -> [].
	
%% 得到战斗中角色ID列表
get_online_player_ids(Battle, Side) ->
	Units		= case Side of
					  ?CONST_BATTLE_UNITS_SIDE_LEFT -> Battle#battle.units_left;
					  ?CONST_BATTLE_UNITS_SIDE_RIGHT -> Battle#battle.units_right
				  end,
	UnitsList	= misc:to_list(Units#units.units),
	Fun = fun(Unit, AccPlayerId)
			   when is_record(Unit, unit) andalso
					Unit#unit.type =:= ?CONST_SYS_PLAYER andalso
					(Unit#unit.unit_ext)#unit_ext_player.online =:= ?true ->
				  [(Unit#unit.unit_ext)#unit_ext_player.user_id|AccPlayerId];
			 (_, AccPlayerId) -> AccPlayerId
		  end,
	lists:foldl(Fun, [], UnitsList).

%% 得到战斗中怪物ID列表
get_monster_ids(Battle) ->
	UnitsRight		= Battle#battle.units_right,
	UnitsRightList	= misc:to_list(UnitsRight#units.units),
	Fun = fun(Unit, AccMonsterId)
			   when is_record(Unit, unit) andalso
					Unit#unit.type =:= ?CONST_SYS_MONSTER ->
				  [{(Unit#unit.unit_ext)#unit_ext_monster.monster_id}|AccMonsterId];
			 (_, AccMonsterId) -> AccMonsterId
		  end,
	lists:foldl(Fun, [], UnitsRightList).

buff_generator(Battle, Buff) ->
	BuffId	= Battle#battle.acc_buff_key,
	Battle2	= Battle#battle{acc_buff_key = BuffId + 1},
	Buff2	= Buff#buff{buff_id = BuffId},
	{Battle2, Buff2}.

%% 计算阵型人数
unit_count(PositionList) ->
	unit_count(PositionList, 0).
unit_count([0|PositionList], AccCount) ->
	unit_count(PositionList, AccCount);
unit_count([1|PositionList], AccCount) ->
	unit_count(PositionList, AccCount);
unit_count([CampPos|PositionList], AccCount)
  when is_record(CampPos, camp_pos) ->
	unit_count(PositionList, AccCount + 1);
unit_count([], AccCount) -> AccCount.

clac_hurt_tuple({HpPre1, HpPre2, HpPre3, HpPre4, HpPre5, HpPre6, HpPre7, HpPre8, HpPre9},
				{Hp1, Hp2, Hp3, Hp4, Hp5, Hp6, Hp7, Hp8, Hp9}) ->
	{
	 clac_hurt(HpPre1, Hp1), clac_hurt(HpPre2, Hp2), clac_hurt(HpPre3, Hp3),
	 clac_hurt(HpPre4, Hp4), clac_hurt(HpPre5, Hp5), clac_hurt(HpPre6, Hp6),
	 clac_hurt(HpPre7, Hp7), clac_hurt(HpPre8, Hp8), clac_hurt(HpPre9, Hp9)
	}.
clac_hurt(HpPre, Hp) when HpPre > Hp -> HpPre - Hp;
clac_hurt(_HpPre, _Hp) -> 0.

%%自动战斗选技能(角色)
auto_select_skill(Unit) when Unit#unit.type =:= ?CONST_SYS_PLAYER ->
	Anger		= Unit#unit.anger,
	ActiveList	= misc:to_list(Unit#unit.active_skill),
	NormalSkill = Unit#unit.normal_skill,
	auto_select_skill(Unit, Anger, ActiveList, 1, {0, NormalSkill});
%% 获取武将技能(武将)
auto_select_skill(Unit) when Unit#unit.type =:= ?CONST_SYS_PARTNER ->
	Anger		= Unit#unit.anger,
	ActiveList	= [Unit#unit.active_skill],
	NormalSkill = Unit#unit.normal_skill,
	auto_select_skill(Unit, Anger, ActiveList, 1, {0, NormalSkill});
%% 获取怪物技能(怪物)
auto_select_skill(Unit) when Unit#unit.type =:= ?CONST_SYS_MONSTER ->
	Anger		= Unit#unit.anger,
	ActiveList	= [Unit#unit.active_skill],
	NormalSkill = Unit#unit.normal_skill,
	auto_select_skill(Unit, Anger, ActiveList, 1, {0, NormalSkill}).

auto_select_skill(Unit, Anger, [Skill|ActiveList], Counter, {Idx, AccSkill}) when is_integer(Idx) ->
	{Idx2, AccSkill2}	=
		case check_skill(Unit, Skill) of
			?ok ->
				#skill{anger = AngerSkill} = AccSkill,
				ScreenFlag	= check_skill_screen(Skill#skill.skill_id),
				if
					Skill#skill.anger > AngerSkill andalso ScreenFlag  -> {Counter, Skill};
					?true -> {Idx, AccSkill}
				end;
			{?error, ?CONST_BATTLE_ACT_REASON_FORBID} ->
				{?error, ?CONST_BATTLE_ACT_REASON_FORBID};
			_ -> 
                {Idx, AccSkill}
		end,
	auto_select_skill(Unit, Anger, ActiveList, Counter + 1, {Idx2, AccSkill2});
auto_select_skill(_Unit, _Anger, [_Skill|_ActiveList], _Counter, {_Idx, _AccSkill}) -> % 眩晕同时主角怒气满了
	{?error, ?CONST_BATTLE_ACT_REASON_FORBID};
auto_select_skill(Unit, _Anger, [], _Counter, {Idx, AccSkill}) ->
	case battle_mod_misc:check_skill(Unit, AccSkill) of
		?ok -> {?ok, Idx, AccSkill};
		{?error, ?CONST_BATTLE_ACT_REASON_FORBID} ->
			{?error, ?CONST_BATTLE_ACT_REASON_FORBID};
		_ -> 
            {?error, ?CONST_BATTLE_ACT_REASON_FORBID}
	end.

%% 检测是否是需屏蔽的技能
%% 因为没有攻击力
check_skill_screen(SkillId) -> 
	case lists:member(SkillId, [11006, 12005, 13002, 13005]) of
		?true -> %% 需屏蔽
			?false;
		?false -> %% 不需屏蔽
			?true
	end.

%% 检查是否自动战斗
check_auto(#unit{unit_ext = #unit_ext_player{auto = ?CONST_SYS_TRUE}}) -> ?true;
check_auto(#unit{unit_ext = #unit_ext_player{auto = ?CONST_SYS_FALSE}}) -> ?false;
check_auto(_Unit) -> ?true.

%% 检查攻击方是否暴击无效和必然暴击
check_inevitable_crit(Unit, Acc, AccBuff, [Buff = #buff{buff_type = ?CONST_BUFF_TYPE_92, arg1 = ?false}|BuffList]) ->% 必然暴击
	{Buff2, Acc2}	=
		case Acc of
			?null ->
				case Buff#buff.expend_value of
					1 -> {Buff#buff{arg1 = ?true}, ?true};
					_ -> 
						case misc_random:odds(?CONST_SYS_NUMBER_HUNDRED / 2, ?CONST_SYS_NUMBER_HUNDRED) of
							?true -> {Buff#buff{arg1 = ?true}, ?true};
							?false -> {Buff, ?null}
						end
				end;
			?false -> {Buff, ?false};
			?true -> {Buff#buff{arg1 = ?true}, ?true}
		end,
	check_inevitable_crit(Unit, Acc2, [Buff2|AccBuff], BuffList);
check_inevitable_crit(Unit, _Acc, AccBuff, [Buff = #buff{buff_type = ?CONST_BUFF_TYPE_94}|BuffList]) ->% 暴击无效
	check_inevitable_crit(Unit, ?false, [Buff|AccBuff], BuffList);
check_inevitable_crit(Unit, Acc, AccBuff, [Buff|BuffList]) ->
	check_inevitable_crit(Unit, Acc, [Buff|AccBuff], BuffList);
check_inevitable_crit(Unit, Acc, AccBuff, []) ->
	Unit2	= Unit#unit{buff = AccBuff},
	{Unit2, Acc}.

check_inevitable_crit(Unit) when is_record(Unit, unit) ->
	check_inevitable_crit(Unit, ?null, [], Unit#unit.buff).

%% 检测并计算无敌伤害
check_invincible([#buff{buff_type = ?CONST_BUFF_TYPE_81}|_BuffList], _Hurt) -> {0, ?true};
check_invincible([_Buff|BuffList], Hurt) -> check_invincible(BuffList, Hurt);
check_invincible([], Hurt) -> {Hurt, ?false};
check_invincible(Unit, Hurt) when is_record(Unit, unit) ->
	check_invincible(Unit#unit.buff, Hurt).

%% 检测并计算免疫暴击伤害
check_immune_crit(Unit, Hurt, Crit, HurtInvincible, Invincible) ->
	case Invincible of
		?true -> {HurtInvincible, ?true, Crit};
		?false ->
			case Crit of
				?true -> check_immune_crit(Unit#unit.buff, Hurt, HurtInvincible, Crit);
				?false -> {HurtInvincible, ?false, Crit}
			end
	end.
check_immune_crit([#buff{buff_type = ?CONST_BUFF_TYPE_93}|_BuffList], Hurt, _HurtInvincible, _Crit) -> {Hurt, ?true, ?false};
check_immune_crit([_Buff|BuffList], Hurt, HurtInvincible, Crit) -> check_immune_crit(BuffList, Hurt, HurtInvincible, Crit);
check_immune_crit([], _Hurt, HurtInvincible, Crit) -> {HurtInvincible, ?false, Crit}.

%% 检查战斗是否结束
%% 战斗结果--左方胜利	1	CONST_BATTLE_RESULT_LEFT
%% 战斗结果--右方胜利	2	CONST_BATTLE_RESULT_RIGHT
%% 战斗结果--平局		3	CONST_BATTLE_RESULT_DRAW
check_battle_over(Battle) when Battle#battle.type =:= ?CONST_BATTLE_BOSS ->
	{Flag, Result}	= check_battle_over_ext(Battle),
	case Flag of
		?true ->
			case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
				[UserId]	->
					BattleParam		= Battle#battle.param,
					UnitsRight		= Battle#battle.units_right,
					HpTupleTempNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
					HpTupleTempOld	= BattleParam#param.ad3,
					HurtTuple		= battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
					boss_api:refresh_monster(UserId, BattleParam#param.ad1, HurtTuple),
					{Flag, Result};
				_Other -> {Flag, Result}
			end;
		?false -> {Flag, Result}
	end;


 check_battle_over(Battle) when Battle#battle.type =:= ?CONST_BATTLE_PARTY	->
	check_battle_over_ext(Battle);
check_battle_over(Battle) when Battle#battle.type =:= ?CONST_BATTLE_WORLD	->
	check_battle_over_ext(Battle);
check_battle_over(Battle)
  when Battle#battle.type =:= ?CONST_BATTLE_INVASION_GUARD -> 
	Param		= Battle#battle.param,
	UniqueId	= Param#param.ad1,
	TeamId		= Param#param.ad4,
	Now			= misc:seconds(),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Object | _] when is_record(Object, invasion_info) andalso Object#invasion_info.end_time > Now	->
%% 			?MSG_ERROR("Object ~p", [Object]),
			case (Object#invasion_info.npc)#invasion_npc.cur_hp > 0 of
				?true ->																					%NPC还活着，继续
					Mons	= Object#invasion_info.mons,
					case lists:keyfind(UniqueId, #invasion_mon.id, Mons) of
						Tuple when is_record(Tuple, invasion_mon) andalso Tuple#invasion_mon.cur_hp > 0	->	%怪物还活着，继续		
							check_battle_over_ext(Battle);
						_OtherL	->																			%怪物挂了，玩家胜
							{?true, ?CONST_BATTLE_RESULT_LEFT}
					end;
				?false ->																					%NPC挂了，玩家败
					{?true, ?CONST_BATTLE_RESULT_RIGHT}
			end;
		_OtherE	->																							%时间到，玩家败	
			{?true, ?CONST_BATTLE_RESULT_RIGHT}
	end;
check_battle_over(Battle)
  when Battle#battle.type =:= ?CONST_BATTLE_INVASION_ATTACK -> 
	Param		= Battle#battle.param,
	UniqueId	= Param#param.ad1,
	TeamId		= Param#param.ad4,
	Now			= misc:seconds(),
	case ets:lookup(?CONST_ETS_INVASION, TeamId) of
		[Object | _] when is_record(Object, invasion_info) andalso Object#invasion_info.end_time > Now	->
%% 			?MSG_ERROR("Object222 ~p", [Object]),
			Mons	= Object#invasion_info.mons,
			case lists:keyfind(UniqueId, #invasion_mon.id, Mons) of
				Tuple when is_record(Tuple, invasion_mon) andalso Tuple#invasion_mon.cur_hp > 0	->	%怪物还活着，继续		
					check_battle_over_ext(Battle);
				_OtherL	->																			%怪物挂了，玩家胜
					{?true, ?CONST_BATTLE_RESULT_LEFT}
			end;
		_OtherE	->																					%时间到，玩家败	
			{?true, ?CONST_BATTLE_RESULT_RIGHT}
	end;
check_battle_over(Battle) ->
	check_battle_over_ext(Battle).

%% 检查是否最大回合或单元是否死光
check_battle_over_ext(Battle) ->
	if
		Battle#battle.bout >= ?CONST_BATTLE_BOUT_MAX  ->
%%         Battle#battle.bout >= 10 -> % XXX
			{?true, ?CONST_BATTLE_RESULT_DRAW};
		?true ->
			UnitsLeft	= Battle#battle.units_left,
			case check_battle_over_unit(misc:to_list(UnitsLeft#units.units)) of
				?true ->  	  %% Left 死光了
					{?true, ?CONST_BATTLE_RESULT_RIGHT};
				?false ->
					UnitsRight	= Battle#battle.units_right,
					case check_battle_over_unit(misc:to_list(UnitsRight#units.units)) of
						?true ->  %% Right 死光了
							{?true, ?CONST_BATTLE_RESULT_LEFT};
						?false -> %% 都没死光 
							{?false, ?CONST_BATTLE_RESULT_DRAW}
					end
			end
	end.
check_battle_over_unit([#unit{state = ?CONST_BATTLE_UNIT_STATE_DEATH}|UnitList]) ->
	check_battle_over_unit(UnitList);
check_battle_over_unit([#unit{state = _}|_UnitList]) -> ?false;
check_battle_over_unit([0|UnitList]) -> check_battle_over_unit(UnitList);
check_battle_over_unit([1|UnitList]) -> check_battle_over_unit(UnitList);
check_battle_over_unit([]) -> ?true.

%% 检查回合是否结束
chenk_bout_over(#battle{bout = 0}) -> ?true;
chenk_bout_over(Battle) ->
	case Battle#battle.seq of
		[] -> ?true;
		_ -> ?false
	end.

%% 检查操作
check_skill(Unit, Skill) when is_record(Skill, skill) ->
	try
		?ok = check_unit_death(Unit),
		?ok	= check_condition(Unit, Skill#skill.condition),
		?ok	= check_anger(Unit, Skill),
		?ok	= check_cd(Skill),
		?ok
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, unknow}
	end;
check_skill(_Unit, 0) -> {?error, unknow};
check_skill(_Unit, ?null) -> {?error, unknow};
check_skill(Unit, Skill) ->
	?MSG_ERROR("UnitType:~p Skill:~p, Strace:~p~n", [Unit#unit.type, Skill, erlang:get_stacktrace()]),
	{?error, unknow}.

check_unit_death(#unit{hp = Hp, state = State})
  when Hp > 0 andalso State =/= ?CONST_BATTLE_UNIT_STATE_DEATH -> ?ok;
check_unit_death(_Unit) -> throw({?error, ?CONST_BATTLE_ACT_REASON_FORBID}).

check_anger(Unit, Skill) ->
	if
		Skill#skill.anger =:= 0 -> ?ok;
		Unit#unit.anger >= Skill#skill.anger -> ?ok;
		?true -> throw({?error, ?CONST_BATTLE_ACT_REASON_ANGER})
	end.
check_cd(Skill) ->
	if
		Skill#skill.cd_temp =:= 0 -> ?ok;
		?true -> throw({?error, ?CONST_BATTLE_ACT_REASON_CD})
	end.
check_condition(Unit, [?CONST_BUFF_TYPE_63|L]) ->
	case lists:keymember(?CONST_BUFF_TYPE_63, #buff.buff_type, Unit#unit.buff) of
		?true -> throw({?error, ?CONST_BATTLE_ACT_REASON_FORBID});
		?false -> check_condition(Unit, L)
	end;
check_condition(Unit, [BuffType|L]) ->
	case lists:keymember(BuffType, #buff.buff_type, Unit#unit.buff) of
		?true -> throw({?error, ?CONST_BATTLE_ACT_REASON_BUFF});
		?false -> check_condition(Unit, L)
	end;
check_condition(_Unit, []) -> ?ok.

%% 设置技能冷却时间
set_skill_cd(Skill) ->
	Skill#skill{cd_temp = Skill#skill.cd}.

%% 技能回合递减
decrease_skill_cd(Skill) when is_record(Skill, skill) ->
	if
		Skill#skill.cd_temp > 0 -> Skill#skill{cd_temp = Skill#skill.cd_temp - 1};
		?true -> Skill#skill{cd_temp = 0}
	end;
decrease_skill_cd(Skill) -> Skill.

%% 攻击类型
atk_type(#skill{type = ?CONST_SKILL_TYPE_ACTIVE}) -> ?CONST_SKILL_TYPE_ACTIVE;
atk_type(#skill{type = ?CONST_SKILL_TYPE_PASSIVE}) -> ?CONST_SKILL_TYPE_PASSIVE;
atk_type(#skill{type = ?CONST_SKILL_TYPE_NORMAL}) -> ?CONST_SKILL_TYPE_NORMAL.

%% 生成战斗Key
key(Side, Idx) -> {Side, Idx}.

key(Battle, UnitType, UserId) ->
	LeftList	= misc:to_list((Battle#battle.units_left)#units.units),
	case key(?CONST_BATTLE_UNITS_SIDE_LEFT, LeftList, UnitType, UserId) of
		{Side, Idx} -> {Side, Idx};
		?null ->
			RightList	= misc:to_list((Battle#battle.units_right)#units.units),
			key(?CONST_BATTLE_UNITS_SIDE_RIGHT, RightList, UnitType, UserId)
	end.
key(Side, [Unit = #unit{type = ?CONST_SYS_PLAYER}|List], ?CONST_SYS_PLAYER, UserId) ->
	UnitExt	= Unit#unit.unit_ext,
	case UnitExt#unit_ext_player.user_id of
		UserId -> {Side, Unit#unit.idx};
		_ -> key(Side, List, ?CONST_SYS_PLAYER, UserId)
	end;
key(Side, [_Unit|List], UnitType, UserId) ->
	key(Side, List, UnitType, UserId);
key(_Side, [], _UnitType, _UserId) -> ?null.

%% 是否是法术职业
magic_pro(?CONST_SYS_PRO_TJ) -> ?true;
magic_pro(?CONST_SYS_PRO_GM) -> ?true;
magic_pro(?CONST_SYS_PRO_JH) -> ?true;
magic_pro(_) -> ?false.

%% 战斗目标方阵
convert_target_side(TargetSide, Side) ->
	case TargetSide of
		?CONST_BATTLE_TARGET_SIDE_HERE -> Side;
		?CONST_BATTLE_TARGET_SIDE_THERE ->
			case Side of
				?CONST_BATTLE_UNITS_SIDE_LEFT -> ?CONST_BATTLE_UNITS_SIDE_RIGHT;
				?CONST_BATTLE_UNITS_SIDE_RIGHT -> ?CONST_BATTLE_UNITS_SIDE_LEFT
			end
	end.

%% 快速排序
speed_sort([Operate = #operate{speed = S}|L]) ->
	speed_sort([E ||E <- L, E#operate.speed >= S])
		++ [Operate] ++
	speed_sort([E ||E <- L, E#operate.speed <  S]);
speed_sort([]) -> [].

%% BUFF优先级排序
buff_sort(BuffList) ->
	lists:keysort(#buff.priority, BuffList).

%% 技能攻击者指令数据
cmd_data_atk_change(_AtkSide,
					#unit{hp = Hp, anger = Anger, attr = #attr{attr_second = #attr_second{hp_max = HpMax}}},
					#unit{hp = Hp, anger = Anger, attr = #attr{attr_second = #attr_second{hp_max = HpMax}}},
					[], []) ->
	?null;
cmd_data_atk_change(AtkSide, _AtkUnitOld, AtkUnitNew, AtkBuffDelete, AtkBuffInsert) ->
	FlagCrit		= battle_mod_misc:crit_flag(?null),
	AtkAttrChange 	= [], % battle_mod_misc:attr_change_data(AtkUnitOld, AtkUnitNew),
	AtkBuffChange 	= battle_mod_misc:buff_change_list(AtkBuffDelete, AtkBuffInsert),
	battle_mod_misc:cmd_data(0, AtkSide, AtkUnitNew, FlagCrit, ?CONST_BATTLE_DISPLAY_NORMAL_DEF2, 0, AtkAttrChange, AtkBuffChange).
	
cmd_data(Side, Unit, FlagCrit, Display, Hurt, AttrChangeList, BuffChangeList) ->
	Attr	= Unit#unit.attr,
	{
	 Side,
	 Unit#unit.idx,
	 FlagCrit,
	 Display,
	 Hurt,
	 Unit#unit.hp,
	 (Attr#attr.attr_second)#attr_second.hp_max,
	 Unit#unit.anger,
	 AttrChangeList,
	 BuffChangeList
	}.
cmd_data(Times, Side, Unit, FlagCrit, Display, Hurt, AttrChangeList, BuffChangeList) ->
	Attr	= Unit#unit.attr,
	{
	 Times,
	 Side,
	 Unit#unit.idx,
	 FlagCrit,
	 Display,
	 Hurt,
	 Unit#unit.hp,
	 (Attr#attr.attr_second)#attr_second.hp_max,
	 Unit#unit.anger,
	 AttrChangeList,
	 BuffChangeList
	}.

attr_change_data(UnitOld, UnitNew) ->
	attr_change_data(UnitOld, UnitNew, []).
attr_change_data(UnitOld, UnitNew, AttrChangeList) ->
	{_AttrOld, AttrSecondOld, AttrEliteOld}	= get_unit_attr(UnitOld),
	{_AttrNew, AttrSecondNew, AttrEliteNew}	= get_unit_attr(UnitNew),
%% 	AttrChangeList2		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_HP,% 生命（现有） 
%% 												   UnitOld#unit.hp,
%% 												   UnitNew#unit.hp,
%% 												   AttrChangeList),
%% 	AttrChangeList3		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_ANGER,% 怒气 （现有） 
%% 												   UnitOld#unit.anger,
%% 												   UnitNew#unit.anger,
%% 												   AttrChangeList2),

%% 	AttrChangeList4		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_HP_MAX,% 生命上限(二级)
%% 												   AttrSecondOld#attr_second.hp_max,
%% 												   AttrSecondNew#attr_second.hp_max,
%% 												   AttrChangeList3),
	AttrChangeList5		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_FORCE_ATTACK,% 物攻(二级)
												   AttrSecondOld#attr_second.force_attack,
												   AttrSecondNew#attr_second.force_attack,
												   AttrChangeList), 
	AttrChangeList6		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_FORCE_DEF,% 物防(二级)
												   AttrSecondOld#attr_second.force_def,
												   AttrSecondNew#attr_second.force_def,
												   AttrChangeList5),
	AttrChangeList7		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_MAGIC_ATTACK,% 术攻(二级)
												   AttrSecondOld#attr_second.magic_attack,
												   AttrSecondNew#attr_second.magic_attack,
												   AttrChangeList6),
	AttrChangeList8		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_MAGIC_DEF,% 术防(二级)
												   AttrSecondOld#attr_second.magic_def,
												   AttrSecondNew#attr_second.magic_def,
												   AttrChangeList7),
	AttrChangeList9		= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_SPEED,% 速度(二级)
												   AttrSecondOld#attr_second.speed,
												   AttrSecondNew#attr_second.speed,
												   AttrChangeList8),
	AttrChangeList10	= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_E_HIT,% 命中(精英)
												   AttrEliteOld#attr_elite.hit,
												   AttrEliteNew#attr_elite.hit,
												   AttrChangeList9),
	AttrChangeList11	= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_E_DODGE,% 闪避(精英)
												   AttrEliteOld#attr_elite.dodge,
												   AttrEliteNew#attr_elite.dodge,
												   AttrChangeList10),
	AttrChangeList12	= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_E_CRIT,% 暴击(精英)
												   AttrEliteOld#attr_elite.crit,
												   AttrEliteNew#attr_elite.crit,
												   AttrChangeList11),
	AttrChangeList13	= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_E_PARRY,% 招架(精英)
												   AttrEliteOld#attr_elite.parry,
												   AttrEliteNew#attr_elite.parry,
												   AttrChangeList12),
	AttrChangeList14	= ?BATTLE_ATTR_CHANGE_DATA(?CONST_PLAYER_ATTR_E_RESIST,% 反击(精英)
												   AttrEliteOld#attr_elite.resist,
												   AttrEliteNew#attr_elite.resist,
												   AttrChangeList13),
	AttrChangeList14.

%% 封装buff变化列表
%% 1.将被删除的部分，设置为minus
%% 2.将新增加的部分，设置为plus
%% 3.封装到一个列表中
buff_change_list(BuffDelete, BuffInsert) ->
	FunDelete		= fun(Buff, Acc) ->
							  [{
								?CONST_BUFF_CALC_TYPE_MINUS,
								Buff#buff.buff_id,
								Buff#buff.buff_type,
								Buff#buff.buff_value,
								Buff#buff.expend_value
							   }|Acc]
					  end,
	BuffChangeTemp	= lists:foldl(FunDelete, [], BuffDelete),
	FunInsert		= fun(Buff, Acc) ->
							  [{
								?CONST_BUFF_CALC_TYPE_PLUS,
								Buff#buff.buff_id,
								Buff#buff.buff_type,
								Buff#buff.buff_value,
								Buff#buff.expend_value
							   }|Acc]
					  end,
	BuffChangeList	= lists:foldl(FunInsert, BuffChangeTemp, BuffInsert),
	BuffChangeList.

%% 增加怒气值
%% 返回:#unit{}
plus_anger(Unit, #skill{type = ?CONST_SKILL_TYPE_NORMAL}) ->
	Factor		= battle_mod_buff:trigger_buff_plus_anger(Unit),
	AngerPlus	= ?CONST_BATTLE_ANGER_DVALUE * (?CONST_SYS_NUMBER_TEN_THOUSAND + Factor) div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	plus_anger(Unit, AngerPlus);
plus_anger(Unit, AngerPlus) when is_number(AngerPlus) ->
	Anger		= Unit#unit.anger,
	AngerMax	= Unit#unit.anger_max,
	Anger2		= misc:betweet(Anger + AngerPlus, 0, AngerMax),
	Unit#unit{anger = Anger2};
plus_anger(Unit, _Skill) -> Unit.

%% 技能消耗怒气
minus_anger(Battle, _Side, _Idx, #skill{anger = 0}) -> Battle;
minus_anger(Battle, Side, Idx, #skill{anger = AngerSkill}) ->
    Unit        = battle_mod_misc:get_unit(Battle, Side, Idx),
	Factor		= battle_genius_skill:genius_skill_revise_anger(Battle, Side, Unit, 0),
	AngerSkill2	= AngerSkill * (?CONST_SYS_NUMBER_TEN_THOUSAND + Factor) div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    Unit2       = minus_anger(Unit, AngerSkill2),
    battle_mod_misc:set_unit(Battle, Side, Unit2);
minus_anger(Battle, _Side, _Idx, _Skill) -> Battle.

%% 减少怒气
minus_anger(Unit, 0) -> Unit;
minus_anger(Unit, Anger) ->
	AngerOld    	= Unit#unit.anger,
	AngerMax		= Unit#unit.anger_max,
    Anger2      	= misc:betweet(AngerOld - Anger, 0, AngerMax),
    Unit#unit{anger = Anger2}.

%% 减少怒气
minus_anger_2(Unit, 0) -> Unit;
minus_anger_2(#unit{unit_ext = #unit_ext_monster{immune_buffs = ImmuneBuffList}} = Unit, Anger) when [] =/= ImmuneBuffList ->
    case lists:member(?CONST_BUFF_TYPE_52, ImmuneBuffList) of
        ?true ->
            Unit;
        _ ->
            AngerOld        = Unit#unit.anger,
            AngerMax        = Unit#unit.anger_max,
            Anger2          = misc:betweet(AngerOld - Anger, 0, AngerMax),
            Unit#unit{anger = Anger2}
    end;
minus_anger_2(Unit, Anger) ->
	AngerOld    	= Unit#unit.anger,
	AngerMax		= Unit#unit.anger_max,
    Anger2      	= misc:betweet(AngerOld - Anger, 0, AngerMax),
    Unit#unit{anger = Anger2}.

%% 增加生命值
plus_hp(Unit, 0) -> Unit;
plus_hp(Unit, HpPlus) ->
    Hp       		= Unit#unit.hp + HpPlus,
    AttrUnit 		= Unit#unit.attr,
    AttrSecondUnit	= AttrUnit#attr.attr_second,
    HpMax        	= AttrSecondUnit#attr_second.hp_max,
    HpNew 			= misc:betweet(Hp, 0, HpMax),
    Unit#unit{hp = HpNew}.

%% 减少生命
minus_hp(_EnlargeRate, Unit, 0) -> {Unit, ?false, 0};
minus_hp(EnlargeRate, Unit, Hurt) ->
    Buff = Unit#unit.buff,
    case lists:keyfind(?CONST_BUFF_TYPE_81, 3, Buff) of % 无敌
        ?false -> 
            HurtFinal   = Hurt * EnlargeRate div ?CONST_SYS_NUMBER_TEN_THOUSAND,
            Hp          = Unit#unit.hp - HurtFinal,
            if 
                Hp =< 0 -> {Unit#unit{hp = 0, state = ?CONST_BATTLE_UNIT_STATE_DEATH}, ?true, HurtFinal};
                ?true -> {Unit#unit{hp = Hp}, ?false, HurtFinal}
            end;
        _      -> 
            {Unit, ?false, 0}
    end.
        
	

%% 吸生命
suck_hp(Unit, 0) -> Unit;
suck_hp(Unit, Hurt) ->
	case check_suck_hp(Unit#unit.buff) of
		{?ok, ?null} -> Unit;
		{?ok, #buff{buff_value = Factor}} ->
			HpPlus	= Hurt * Factor div ?CONST_SYS_NUMBER_TEN_THOUSAND,
			plus_hp(Unit, HpPlus)
	end.
check_suck_hp([Buff = #buff{buff_type = ?CONST_BUFF_TYPE_82}|_BuffList]) -> {?ok, Buff};
check_suck_hp([_Buff|BuffList]) -> check_suck_hp(BuffList);
check_suck_hp([]) -> {?ok, ?null}.

%% 治疗时改变治疗效果
change_cure_effect(Unit) ->
	check_cure_effect(Unit#unit.buff, 0).
check_cure_effect([#buff{buff_type = ?CONST_BUFF_TYPE_41, buff_value = Plus}|BuffList], AccFactor) ->
	check_cure_effect(BuffList, AccFactor + Plus);
check_cure_effect([#buff{buff_type = ?CONST_BUFF_TYPE_51, buff_value = Minus}|BuffList], AccFactor) ->
	check_cure_effect(BuffList, AccFactor - Minus);
check_cure_effect([_Buff|BuffList], AccFactor) -> check_cure_effect(BuffList, AccFactor);
check_cure_effect([], AccFactor) -> AccFactor.




%% hp_max下降
%% 1.调减hp_max
%% 2.调整hp.如果hp>hp_max的话，调减.
%% 返回#unit{}.
minus_hp_max(Unit, Buff) ->
    Type = ?CONST_PLAYER_ATTR_HP_MAX,
    
    % hp_max上限减了
    AttrUnit = Unit#unit.attr,
    AttrBase = Unit#unit.attr_base,
    AttrSecondBase = AttrBase#attr.attr_second,
    HpMaxBase = AttrSecondBase#attr_second.hp_max,
    HpMaxRate = Buff#buff.buff_value,
    Delta = HpMaxBase * HpMaxRate div ?CONST_SYS_NUMBER_TEN_THOUSAND,
    NewAttrUnit = player_attr_api:attr_plus(AttrUnit, Type, - Delta), 
    
    % hp调整
    Hp = Unit#unit.hp,
    NewAttrSecondUnit = NewAttrUnit#attr.attr_second,
    HpMaxUnit = NewAttrSecondUnit#attr_second.hp_max,
    Hp2 = misc:min(Hp, HpMaxUnit),
    Unit#unit{hp = Hp2, attr = NewAttrUnit}.

%% 设置反击列表
set_resist_list(Battle, ?true, Side, #unit{idx = Idx, state = State})
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	ResistList	= Battle#battle.resist_list,
	Battle#battle{resist_list = [{Side, Idx}|ResistList]};
set_resist_list(Battle, _ResistFlag, _Side, _Unit) -> Battle.

%% 设置天赋资格列表
set_genius_list(Battle, Side, #unit{idx = Idx, state = State})
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	Elem		= {Side, Idx},
	GeniusList	= Battle#battle.genius_list,
	case lists:member(Elem, GeniusList) of
		?true -> Battle;
		?false -> Battle#battle{genius_list = [Elem|GeniusList]}
	end;
set_genius_list(Battle, _Side, _Unit) -> Battle.

%% 计算治疗效果
%% calc_cure_value(Skill, AtkUnit, DefUnit) ->
%% 	Ratio = Skill#skill.ratio,
%% 	AttrSecond = (AtkUnit#unit.attr)#attr.attr_second,
%% 	MagicAttack = AttrSecond#attr_second.magic_attack,
%% 	CureRate = 
%% 		case lists:keyfind(?CONST_BUFF_TYPE_6, #buff.buff_type, DefUnit#unit.buff) of
%% 			?false ->
%% 				Ratio;
%% 			Buff ->
%% 				Ratio + Buff#buff.buff_value
%% 		end,
%% 	TempHpFinal  = ?FUNC_BATTLE_CURE(MagicAttack, Ratio),
%% 	TempHpFinal*(?CONST_SYS_NUMBER_TEN_THOUSAND + CureRate) div ?CONST_SYS_NUMBER_TEN_THOUSAND.
%% 
display(?true, ?false) 		-> ?CONST_BATTLE_DISPLAY_NORMAL_DEF;
display(?true, ?true)		-> ?CONST_BATTLE_DISPLAY_PARRY;
display(?false, _FlagParry)	-> ?CONST_BATTLE_DISPLAY_DODGE.


crit_flag(?true)	-> ?CONST_BATTLE_CRIT_TRUE;
crit_flag(?false) 	-> ?CONST_BATTLE_CRIT_FALSE;
crit_flag(_) 		-> ?CONST_BATTLE_CRIT_DEFAULT.

init_battle_report_flag(?CONST_BATTLE_SINGLE_COPY) ->      	?true;		% 战斗类型--单人副本 
init_battle_report_flag(?CONST_BATTLE_SINGLE_ARENA) ->    	?true;      % 战斗类型--单人竞技场 
init_battle_report_flag(?CONST_BATTLE_SINGLE_ROBOT) ->    	?true;      % 战斗类型--单人竞技场 
init_battle_report_flag(?CONST_BATTLE_BOSS) ->            	?false;    	% 战斗类型--世界boss 
init_battle_report_flag(?CONST_BATTLE_TRIBE_COPY) ->       	?false;     % 战斗类型--多人副本 
init_battle_report_flag(?CONST_BATTLE_TRIBE_ARENA) ->     	?false;     % 战斗类型--多人竞技场 
init_battle_report_flag(?CONST_BATTLE_TOWER) ->            	?true;      % 战斗类型--闯塔 
init_battle_report_flag(?CONST_BATTLE_COMMERCE) ->         	?false;     % 战斗类型--运镖(商路) 
init_battle_report_flag(?CONST_BATTLE_KILL_NPC) ->         	?false;     % 战斗类型--NPC对话战斗 
init_battle_report_flag(?CONST_BATTLE_INVASION_GUARD) ->   	?false;     % 战斗类型--异民族（守关） 
init_battle_report_flag(?CONST_BATTLE_HOME) ->             	?false;     % 战斗类型--家园抢夺仕女 
init_battle_report_flag(?CONST_BATTLE_WORLD) ->      		?false;     % 战斗类型--怪物攻城 
init_battle_report_flag(?CONST_BATTLE_MCOPY_Q) ->          	?false;     % 战斗类型--奇遇发起的战斗 
init_battle_report_flag(?CONST_BATTLE_INVASION_ATTACK) ->   ?false;     % 战斗类型--异民族（闯关） 
init_battle_report_flag(?CONST_BATTLE_PARTY) ->   			?false;     % 战斗类型--宴会 
init_battle_report_flag(?CONST_BATTLE_PARTY_PK) ->      	?false;     % 战斗类型--宴会pk 
init_battle_report_flag(?CONST_BATTLE_TEST_PLAYER) ->      	?false;     % 战斗类型--测试(角色) 
init_battle_report_flag(?CONST_BATTLE_TEST_MONSTER) ->     	?false;     % 战斗类型--测试(怪物) 
init_battle_report_flag(?CONST_BATTLE_CAMP_PVP) ->          ?false;     % 战斗类型--测试(怪物) 
init_battle_report_flag(?CONST_BATTLE_GUILD_PVE) ->         ?false;     % 战斗类型 -- 军团战 pve
init_battle_report_flag(?CONST_BATTLE_GUILD_PVP) ->         ?false;     % 战斗类型 -- 军团战 pvp
init_battle_report_flag(?CONST_BATTLE_CROSS_ARENA) ->       ?true;      % 战斗类型 -- 跨服竞技场
init_battle_report_flag(?CONST_BATTLE_TEACH) ->             ?false;     % 战斗类型 -- 教学
init_battle_report_flag(_)                      ->          ?false.      

%% --------------------------------------------------
%% 战斗单元
%% --------------------------------------------------
record_unit(_Record, Player, Side, Idx, Param) when is_record(Player, player) ->
	Info		= Player#player.info,
	Pro 		= Info#info.pro,
	Type		= ?CONST_SYS_PLAYER,
	Anger		= init_anger(Player, Type, ?CONST_BATTLE_ANGER_INIT_PLAYER),
	AttrBase 	= Player#player.attr,
	UnitExt		= record_unit_ext_player(Player, Side, Param),
	{
	 NormalSkill,
	 ActiveSkill,
	 GeniusSkill
	}			= skill_api:battle_skill(Player),
	#unit{
		  type				= Type,								                %% 战斗单元：1--玩家|2--武将|10--怪物
		  idx				= Idx,						                        %% 阵型中的位置索引
		  state				= ?CONST_BATTLE_UNIT_STATE_NORMAL,	                %% 战斗状态
		  pro				= Pro, 								                %% 职业
		  power				= Info#info.power, 					                %% 战力
		  lv				= Info#info.lv,						                %% 等级
		  hp				= (AttrBase#attr.attr_second)#attr_second.hp_max,   %% 当前生命
		  anger				= Anger,							                %% 怒气值
		  anger_max			= ?CONST_BATTLE_ANGER_MAX_PLAYER,	                %% 怒气值上限
		  attr				= AttrBase,		           			                %% 属性
		  attr_base			= AttrBase,		            		                %% 基础属性(初始值:战斗前)
		  attr_ext			= ?null,											%% 附加属性(阵型附加、坐骑技能附加)
		  normal_skill		= NormalSkill,							            %% 普通技能
		  active_skill		= ActiveSkill,							            %% 主动技能
		  genius_skill		= GeniusSkill, 							            %% 天赋技能(被动技能)
		  buff				= [],						                        %% Buff
		  buff_ext			= [],									            %% 战斗外部BUFF列表
		  resist			= ?false,											%% 是否必然反击标示[?true:必然反击|?false:非必然反击]
          is_soul           = ?false,
		  unit_ext			= UnitExt					                        %% 战斗单元扩展
		 };
record_unit(Player, Partner, _Side, Idx, _Param) when is_record(Partner, partner) ->
	UnitExt		= record_unit_ext_partner(Player, Partner),
	Pro 		= Partner#partner.pro,
	Type		= ?CONST_SYS_PARTNER,
	Anger		= init_anger(Player, Type, ?CONST_BATTLE_ANGER_INIT_PARTNER),
	AttrBase 	= Partner#partner.attr,
    GSkillList  = skill_api:genius_skill(Player, Partner), 
	#unit{
		  type				= Type,												%% 战斗单元：1--玩家|2--武将|10--怪物
		  idx				= Idx,						           	 			%% 阵型中的位置索引
		  state				= ?CONST_BATTLE_UNIT_STATE_NORMAL,					%% 战斗状态
		  hp				= (AttrBase#attr.attr_second)#attr_second.hp_max,	%% 当前生命
		  pro				= Pro, 												%% 职业
		  power				= Partner#partner.power, 							%% 战力
		  lv				= Partner#partner.lv,								%% 等级
		  anger				= Anger,							    			%% 怒气值
		  anger_max			= ?CONST_BATTLE_ANGER_MAX_PARTNER,					%% 怒气值上限
		  attr				= AttrBase,											%% 属性
		  attr_base			= AttrBase,			            					%% 基础属性(初始值)
		  attr_ext			= ?null,											%% 附加属性(阵型附加、坐骑技能附加)
		  normal_skill		= Partner#partner.normal_skill,						%% 普通技能
		  active_skill		= Partner#partner.active_skill, 					%% 主动技能
		  genius_skill		= GSkillList, 					                    %% 天赋技能(被动技能)
		  buff				= [],						            			%% Buff
		  buff_ext			= [],												%% 战斗外部BUFF列表
		  resist			= ?false,											%% 是否必然反击标示[?true:必然反击|?false:非必然反击]
          is_soul           = ?false,
		  unit_ext			= UnitExt 					            			%% 战斗单元扩展
		 };
record_unit(_Record, Monster, _Side, Idx, _Param) when is_record(Monster, monster) ->
	Power 		= Monster#monster.power,
	Type		= ?CONST_SYS_MONSTER,
	Anger		= init_anger(Monster, Type, ?CONST_BATTLE_ANGER_INIT_MONSTER),
	UnitExt		= record_unit_ext_monster(Monster),
	#unit{
		  type				= Type,												%% 战斗单元：1--玩家|2--武将|10--怪物
		  idx				= Idx,						            			%% 阵型中的位置索引
		  state				= ?CONST_BATTLE_UNIT_STATE_NORMAL,					%% 战斗状态
		  hp				= Monster#monster.hp,		            			%% 当前生命
		  pro				= Monster#monster.pro, 								%% 职业
		  power				= Power,											%% 战力
		  lv				= Monster#monster.lv,								%% 等级
		  anger				= Anger,							      			%% 怒气值
		  anger_max			= ?CONST_BATTLE_ANGER_MAX_MONSTER,					%% 怒气值上限
		  attr				= Monster#monster.attr,								%% 属性
		  attr_base			= Monster#monster.attr,		            			%% 基础属性(初始值)
		  attr_ext			= ?null,											%% 附加属性(阵型附加、坐骑技能附加)
		  normal_skill		= Monster#monster.normal_skill,						%% 普通技能
		  active_skill		= Monster#monster.skill,	           				%% 主动技能
		  genius_skill		= Monster#monster.genus_skill, 						%% 天赋技能(被动技能)
		  buff				= [],						            			%% Buff
		  buff_ext			= [],												%% 战斗外部BUFF列表
		  resist			= ?false,											%% 是否必然反击标示[?true:必然反击|?false:非必然反击]
          is_soul           = ?false,
		  unit_ext			= UnitExt 					           				%% 战斗单元扩展
		 }.
%% --------------------------------------------------
%% 战斗单元扩展
%% --------------------------------------------------
%% 角色
record_unit_ext_player(Player, Side, Param) ->
	Info		= Player#player.info,
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
	PartnersTmp = partner_api:get_partner_id_list(Player, 0),
	Partners	= [{PartnerId} || PartnerId <- PartnersTmp],
	UserId		= Player#player.user_id,
	IsRobot		= lists:member(UserId, Param#param.robot),
	Auto		= case IsRobot of
					  ?true ->
						  ?CONST_SYS_TRUE;
					  ?false ->
						  init_unit_auto(Side, Param, Info#info.is_auto)
				  end,
	OnLine		= init_unit_online(Side, Param),
    PSoulData   = Player#player.partner_soul,
    PSoul       = min(8,PSoulData#partner_soul.star_lv), 
	#unit_ext_player{
					 user_id			= Player#player.user_id,	%% 角色ID
					 name        		= Info#info.user_name,		%% 角色
					 
					 country			= Info#info.country,		%% 国家
					 guild        		= 0,        				%% 军团
					 sex				= Info#info.sex,			%% 性别
					 vip				= player_api:get_vip_lv(Info),%% VIP等级
					 fashion			= SkinFashion,				%% 装备时装ID
					 armor				= SkinArmor,		        %% 装备衣服ID
					 weapon				= SkinWeapon,	            %% 装备武器ID
					 partners			= Partners,					%% 副将ID列表
					 is_leader			= 0, 						%% 是否是队长：?CONST_SYS_FALSE--不是|?CONST_SYS_TRUE--是
					 auto				= Auto, 					%% 是否自动战斗:?CONST_SYS_FALSE--不是|?CONST_SYS_TRUE--是
					 online				= OnLine,   				%% 是否在线:?true:是 | ?false:否
                     psoul              = PSoul                     %% 将星等级
					}.
%% 伙伴
record_unit_ext_partner(Player, Partner) ->
	Id			= Partner#partner.partner_id,
	{
	 _, SkinWeapon, SkinArmor
	}			= ctn_equip_api:get_partner_equip_effect(Player, Id),
	PartnersTmp	= partner_api:get_partner_id_list(Player, Id),
	Partners	= [{PartnerId} || PartnerId <- PartnersTmp],
    PSoulData   = Partner#partner.partner_soul, 
    PSoul       = min(8,PSoulData#partner_soul.star_lv), 
	#unit_ext_partner{
					  partner_id		= Id,			%% 伙伴ID
					  armor				= SkinArmor,	%% 装备衣服ID
					  weapon			= SkinWeapon,	%% 装备武器ID
					  partners			= Partners,		%% 副将ID列表
                      psoul             = PSoul         %% 将星等级
					 }.	
%% 怪物
record_unit_ext_monster(Monster) ->
	#unit_ext_monster{
					  monster_id		= Monster#monster.monster_id,	%% 怪物ID
					  monster_unique_id	= Monster#monster.id,			%% 怪物唯一ID
					  immune_buffs		= Monster#monster.immune_buffs,	%% 免疫BUFF列表
                      psoul             = 0
					 }.
%% 操作指令结果
record_operate(Key, Speed, SkillIdx, Skill) ->
	#operate{key = Key, speed = Speed, skill_idx = SkillIdx, skill = Skill}.

%% 天赋技能所需参数
record_genius_param(AtkType, Crit, Hurt, Death, Parry, Hit) ->
	#genius_param{
				  atk_type			= AtkType,			%% 攻击类型
				  crit			    = Crit,	        	%% 暴击(?true|?false)
				  hurt				= Hurt,				%% 伤害值
				  death				= Death,			%% 死亡(?true|?false)
                  parry             = Parry,
                  hit               = Hit
				 }.
%% 战斗临时参数
record_temp_param() ->
	#temp_param{
				hit					= ?false,			%% 命中(?true|?false)
				dodge				= ?false,			%% 闪避(?true|?false)
				crit			    = ?false,       	%% 暴击(?true|?false)
				parry				= ?false,       	%% 招架(?true|?false)
				resist				= ?false,			%% 反击(?true|?false)
				death				= ?false,			%% 死亡(?true|?false)
				hurt				= 0 				%% 伤害值
			   }.
refresh_temp_param(TempParam, Hit, Dodge, Crit, Parry, HurtFinal, Resist) ->
	#temp_param{
				hit					= case TempParam#temp_param.hit of ?true -> TempParam#temp_param.hit; ?false -> Hit end,
				dodge				= case TempParam#temp_param.dodge of ?true -> TempParam#temp_param.dodge; ?false -> Dodge end,
				crit			    = case TempParam#temp_param.crit of ?true -> TempParam#temp_param.crit; ?false -> Crit end,
				parry				= case TempParam#temp_param.parry of ?true -> TempParam#temp_param.parry; ?false -> Parry end,
				resist				= case TempParam#temp_param.resist of ?true -> TempParam#temp_param.resist; ?false -> Resist end,
				hurt				= TempParam#temp_param.hurt + HurtFinal
			   }.
set_temp_param_death(TempParam, Death) ->
	TempParam#temp_param{death = case TempParam#temp_param.death of ?true -> TempParam#temp_param.death; ?false -> Death end}.

%% 设置天赋技能参数触发点
set_genius_param_triger(GeniusParam, Trigger) ->
	GeniusParam#genius_param{trigger = Trigger}.

%% 初始化战斗单元自动战斗标示
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_BOSS, ad2 = ?true}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_SINGLE_COPY}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_SINGLE_ARENA}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_COMMERCE}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_HOME}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_INVASION_GUARD}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_LEFT,  #param{battle_type = ?CONST_BATTLE_INVASION_ATTACK}, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_SINGLE_ARENA}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_SINGLE_ROBOT}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_COMMERCE}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_HOME}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_CROSS_ARENA}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_CROSS_ARENA_ROBOT}, _) -> ?CONST_SYS_TRUE;
init_unit_auto(_Side, _Param, _IsAuto) -> ?CONST_SYS_FALSE.

%% 初始化战斗单元广播标示
init_unit_online(Side, Param) ->
	SingleCast = [?CONST_BATTLE_SINGLE_ARENA, 
				  ?CONST_BATTLE_COMMERCE, 
				  ?CONST_BATTLE_HOME, 
				  ?CONST_BATTLE_SINGLE_ROBOT, 
				  ?CONST_BATTLE_CROSS_ARENA, 
				  ?CONST_BATTLE_CROSS_ARENA_ROBOT],
	case lists:member(Param#param.battle_type, SingleCast) of
		?true ->
			case Side of
				?CONST_BATTLE_UNITS_SIDE_LEFT -> ?true;
				?CONST_BATTLE_UNITS_SIDE_RIGHT -> ?false
			end;
		?false -> ?true
	end.

%% 设置战斗记忆数据--战斗开始
set_battle_memory(Battle, <<>>) -> Battle;
set_battle_memory(Battle = #battle{report = ?true}, Packet) ->
	Memory		= Battle#battle.memory,
	Battle#battle{memory = <<Memory/binary, Packet/binary>>};
set_battle_memory(Battle = #battle{report = ?false}, _Packet) ->
	Battle.

%% 初始化怒气
init_anger(Player, UnitType, AngerBase) when is_record(Player, player) ->
	Key			= {Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER},
	case lists:keyfind(Key, 1, Player#player.equip) of
        {Key, EquipCtn} when is_record(EquipCtn, ctn) ->
			case ctn_api:read_info(EquipCtn, ?CONST_GOODS_EQUIP_FUSION) of
				{?ok, #mini_goods{exts = #g_equip{fusion_lv = FusionLv}}} ->
                    AngerPlus = 
                        case data_furnace:get_fusion_attr({?CONST_GOODS_EQUIP_FUSION, FusionLv}) of
                            #rec_furnace_fashion_attr{anger = [AngerPlusT]} ->
            					AngerPlusT;
                            ?null ->
                                0
                        end,
                    init_anger_ext(UnitType, AngerBase, AngerPlus);
				_ -> AngerBase
			end;
        ?false -> AngerBase
    end;
init_anger(_Player, _UnitType, AngerBase) -> AngerBase.

init_anger_ext(?CONST_SYS_PLAYER, AngerBase, {FashionType, AngerPlus})
  when FashionType =:= ?CONST_GOODS_FASHION_ANGER_TYPE_1 orelse
	   FashionType =:= ?CONST_GOODS_FASHION_ANGER_TYPE_3 ->
	misc:min(AngerBase + AngerPlus, ?CONST_BATTLE_ANGER_MAX_PLAYER);
init_anger_ext(?CONST_SYS_PARTNER, AngerBase, {FashionType, AngerPlus})
  when FashionType =:= ?CONST_GOODS_FASHION_ANGER_TYPE_2 orelse
	   FashionType =:= ?CONST_GOODS_FASHION_ANGER_TYPE_3 ->
	misc:min(AngerBase + AngerPlus, ?CONST_BATTLE_ANGER_MAX_PARTNER);
init_anger_ext(_UnitType, AngerBase, _AngerPlus) -> AngerBase.



%%
%% Local Functions
%%

