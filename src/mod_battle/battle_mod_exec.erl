%% Author: cobain
%% Created: 2012-9-11
%% Description: TODO: Add description to battle_mod_exec
-module(battle_mod_exec).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/record.battle.hrl").
-include("../../include/record.map.hrl").
%%
%% Exported Functions
%%
-export([refresh/1]).
-export([exec/1]).
-export([change_unit_buff/4, exec_skill_over/2]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh(Battle) ->
    Battle2 = Battle#battle{
                            cmds		= [],		%% 战斗指令累加(执行一次战斗清理一次)
                            time		= 0     	%% 每次战斗时间累加(毫秒)(执行一次战斗清理一次)
                           },
	Battle3	= refresh_monster(Battle2),
    refresh2(Battle3).

refresh2(Battle = #battle{refresh = ?false}) -> {Battle, <<>>};
refresh2(Battle = #battle{refresh = ?true}) ->
	%% 回合刷新前ai
	Battle2		= refresh_enlarge_rate(Battle),
	{Battle3, AiPacket1} = ai_api:trigger_ai(Battle2, ?CONST_AI_TRIGGER_BOUT_FRONT),
	BattleType	= Battle3#battle.type,
	EnlargeRate	= Battle3#battle.enlarge_rate,
	Bout		= Battle3#battle.bout,
    UnitsLeft   = Battle3#battle.units_left,
    UnitsRight  = Battle3#battle.units_right,
    {
     UnitsLeftTuple, DatasTemp
    }           = refresh_unit_list(BattleType, Bout, EnlargeRate, ?CONST_BATTLE_UNITS_SIDE_LEFT, misc:to_list(UnitsLeft#units.units), [], []),
    {
     UnitsRightTuple, Datas
    }           = refresh_unit_list(BattleType, Bout, EnlargeRate, ?CONST_BATTLE_UNITS_SIDE_RIGHT, misc:to_list(UnitsRight#units.units), [], DatasTemp),
    UnitsLeft2  = UnitsLeft#units{units = UnitsLeftTuple},
    UnitsRight2 = UnitsRight#units{units = UnitsRightTuple},
    Battle4     = Battle3#battle{refresh = ?false, units_left = UnitsLeft2, units_right = UnitsRight2},
	Battle5		= battle_genius_skill:genius_skill_refresh_bout(Battle4),
	{Seq, Operate, PacketOperate}
				= battle_mod:init_seq(Battle5#battle.units_left, Battle5#battle.units_right, Battle5#battle.operate),
	Battle6		= 
		case Battle5#battle.round_refresh of
			?true -> Battle5#battle{round_refresh = ?false};
			?false -> Battle5#battle{seq = Seq, operate = Operate}
		end,
	PacketRefresh= battle_api:msg_battle_refresh_bout(Battle6#battle.id, Battle6#battle.bout, Datas, ?CONST_SYS_FALSE),
	PacketSeq	= battle_api:msg_battle_seq(Battle6#battle.seq),
	%% 回合刷新后ai
	{Battle7, AiPacket2} = ai_api:trigger_ai(Battle6, ?CONST_AI_TRIGGER_BOUT_BACK),
    {Battle7, <<PacketRefresh/binary, AiPacket1/binary, PacketSeq/binary, PacketOperate/binary, AiPacket2/binary>>}.

refresh_enlarge_rate(Battle) ->
	case data_player:get_battle_enlarge({Battle#battle.type, Battle#battle.bout}) of
		BattleEnlarge when is_number(BattleEnlarge) -> Battle#battle{enlarge_rate = BattleEnlarge};
		_ -> Battle
	end.

refresh_unit_list(BattleType, Bout, EnlargeRate, Side, [Unit|UnitList], Acc, AccDatas) ->
    case refresh_unit(BattleType, Bout, EnlargeRate, Side, Unit) of
        {Unit2, Data} ->
            refresh_unit_list(BattleType, Bout, EnlargeRate, Side, UnitList, [Unit2|Acc], [Data|AccDatas]);
        _ -> refresh_unit_list(BattleType, Bout, EnlargeRate, Side, UnitList, [Unit|Acc], AccDatas)
    end;
refresh_unit_list(_BattleType, _Bout, _EnlargeRate, _Side, [], Acc, AccDatas) ->
    UnitsTuple  = misc:to_tuple(lists:reverse(Acc)),
    {UnitsTuple, AccDatas}.


refresh_unit(_BattleType, Bout, EnlargeRate, Side, Unit)
  when is_record(Unit, unit) andalso Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
    BuffList    = battle_mod_misc:get_unit_buff(Unit),
	Unit3		=
		case Bout of
			1 -> Unit;
			_ ->
				Unit2       = Unit#unit{attr = Unit#unit.attr_base},
				AttrTemp	= player_attr_api:attr_plus(Unit2#unit.attr, Unit2#unit.attr_ext),
				Unit2#unit{attr = AttrTemp}
		end,
    {
     Unit4, BuffDelete
    }           = refresh_unit_buffs(EnlargeRate, Unit3, BuffList, [], []),
	Unit5		= refresh_unit_skill(Unit4),
	Unit6		= refresh_unit_normal_skill(Unit5),
	Unit7		= refresh_unit_genius_skill(Unit6),
	Unit8		= Unit7#unit{resist = ?false, is_soul = ?false},
    Attr        = Unit8#unit.attr,
    HpMax       = (Attr#attr.attr_second)#attr_second.hp_max,
    Hp          = Unit8#unit.hp,
    Hurt        = if Hp >= Unit#unit.hp -> 0; ?true -> abs(Hp - Unit#unit.hp) end,
    Data        = {Side, Unit8#unit.idx, Hurt, Hp, HpMax, Unit8#unit.anger, BuffDelete},
    {Unit8, Data};
refresh_unit(_BattleType, _Bout, _EnlargeRate, _Side, Unit) -> Unit.

refresh_unit_buffs(EnlargeRate, Unit, [Buff|BuffList], AccBuffList, AccDelete) ->
    case buff_api:decrease_buff(Buff) of
        Buff2 when is_record(Buff2, buff) andalso Buff2#buff.expend_value =:= 0 ->
			refresh_unit_buffs(EnlargeRate, Unit, BuffList, AccBuffList, [{Buff2#buff.buff_id}|AccDelete]);
        Buff2 when is_record(Buff2, buff) ->
            Unit2   = battle_mod_buff:trigger_buff_bout(EnlargeRate, Unit, Buff2),
            refresh_unit_buffs(EnlargeRate, Unit2, BuffList, [Buff2|AccBuffList], AccDelete);
        _ ->
            refresh_unit_buffs(EnlargeRate, Unit, BuffList, AccBuffList, AccDelete)
    end;
refresh_unit_buffs(_EnlargeRate, Unit, [], AccBuffList, AccDelete) ->
	{
	 _Attr, AttrSecond, _AttrElite
	}		= battle_mod_misc:get_unit_attr(Unit),
	Hp		= misc:betweet(Unit#unit.hp, 0, AttrSecond#attr_second.hp_max),
    {Unit#unit{hp = Hp, buff = AccBuffList}, AccDelete}.

refresh_unit_skill(Unit = #unit{type = ?CONST_SYS_PLAYER}) ->
	SkillList	= misc:to_list(Unit#unit.active_skill),
	ActiveSkill	= refresh_unit_skill(SkillList, []),
	Unit#unit{active_skill = ActiveSkill};
refresh_unit_skill(Unit = #unit{type = ?CONST_SYS_PARTNER}) ->
	ActiveSkill	= battle_mod_misc:decrease_skill_cd(Unit#unit.active_skill),
	Unit#unit{active_skill = ActiveSkill};
refresh_unit_skill(Unit = #unit{type = ?CONST_SYS_MONSTER}) ->
	ActiveSkill	= battle_mod_misc:decrease_skill_cd(Unit#unit.active_skill),
	Unit#unit{active_skill = ActiveSkill};
refresh_unit_skill(Unit) -> Unit.


refresh_unit_skill([Skill|SkillList], AccSkill) ->
	Skill2	= battle_mod_misc:decrease_skill_cd(Skill),
	refresh_unit_skill(SkillList, [Skill2|AccSkill]);
refresh_unit_skill([], AccSkill) ->
	misc:to_tuple(lists:reverse(AccSkill)).

refresh_unit_normal_skill(Unit) ->
	Skill	= battle_mod_misc:decrease_skill_cd(Unit#unit.normal_skill),
	Unit#unit{normal_skill = Skill}.

refresh_unit_genius_skill(Unit) ->
	GeniusSkillTrigger	= Unit#unit.genius_trigger,
	refresh_unit_genius_skill(Unit, GeniusSkillTrigger).
refresh_unit_genius_skill(Unit, [GeniusSkill|GeniusSkillTrigger]) ->
	Unit2	= battle_genius_skill:refresh_genius_skill(Unit, GeniusSkill),
	refresh_unit_genius_skill(Unit2, GeniusSkillTrigger);
refresh_unit_genius_skill(Unit, []) -> Unit.

refresh_monster(Battle) when Battle#battle.type =:= ?CONST_BATTLE_CAMP_PVP ->
    case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
        [UserId]    ->
            BattleParam     = Battle#battle.param,
            UnitsRight      = Battle#battle.units_right,
            case BattleParam#param.ad3  of
                ?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
                    HpTupleTempNew  = battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
                    HpTupleTempOld  = BattleParam#param.ad5,
                    ?MSG_DEBUG("666666HpTupleTempNew is ~w, HpTupleTempOld is ~w", [HpTupleTempNew, HpTupleTempOld]),
                    HurtTuple       = battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
                    HpTupleNew      = camp_pvp_api:refresh_monster(UserId, UnitsRight#units.id, HurtTuple),
                    HpTuple         = battle_mod_misc:revise_hp_tuple(HpTupleTempNew, HpTupleNew),
                    UnitTupe2       = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
                    ?MSG_DEBUG("111111111111111111111111111111111111111111111111BattleParam#param.ad2 is ~w", [BattleParam#param.ad2]),
                    Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
                                  param = BattleParam#param{ad5 = HpTuple}};
                ?CONST_CAMP_PVP_BATTLE_TYPE_PVM ->
                    case camp_pvp_mod:check_camp_open() of
                        false ->
                            HpTuple         = erlang:make_tuple(9, 0, []),
                            UnitTupe2       = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
                            Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
                                    param = BattleParam#param{ad5 = HpTuple}};
                        true ->
                            Battle
                    end;
                _ ->
                    Battle
            end;
        _Other -> Battle
    end;

refresh_monster(Battle) when Battle#battle.type =:= ?CONST_BATTLE_BOSS ->
	case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
		[UserId]	->
			BattleParam		= Battle#battle.param,
			UnitsRight		= Battle#battle.units_right,
			HpTupleTempNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
			HpTupleTempOld	= BattleParam#param.ad3,
			HurtTuple		= battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
			HpTupleNew	 	= boss_api:refresh_monster(UserId, BattleParam#param.ad1, HurtTuple),
			HpTuple			= battle_mod_misc:revise_hp_tuple(HpTupleTempNew, HpTupleNew),
			UnitTupe2		= battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
			Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
						  param = BattleParam#param{ad3 = HpTuple}};
		_Other -> Battle
	end;
refresh_monster(Battle) when Battle#battle.type =:= ?CONST_BATTLE_WORLD ->
	case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
		[UserId]	->
			BattleParam		= Battle#battle.param,
			UnitsRight		= Battle#battle.units_right,
			HpTupleTempNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
			HpTupleTempOld	= BattleParam#param.ad3,
			HurtTuple		= battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
			HpTupleNew	 	= world_api:refresh_monster(UserId, BattleParam#param.ad1, BattleParam#param.ad2, HurtTuple),
			HpTuple			= battle_mod_misc:revise_hp_tuple(HpTupleTempNew, HpTupleNew),
			UnitTupe2		= battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
			Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
						  param = BattleParam#param{ad3 = HpTuple}};
		_Other -> Battle
	end;
refresh_monster(Battle) when Battle#battle.type =:= ?CONST_BATTLE_PARTY ->
	case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
		[UserId]	->
			BattleParam		= Battle#battle.param,
			UnitsRight		= Battle#battle.units_right,
			HpTupleTempNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
			HpTupleTempOld	= BattleParam#param.ad3,
			HurtTuple		= battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
			HpTupleNew	 	= party_api:refresh_monster(UserId, BattleParam#param.ad2, HurtTuple),
			HpTuple			= battle_mod_misc:revise_hp_tuple(HpTupleTempNew, HpTupleNew),
			UnitTupe2		= battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
			Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
						  param = BattleParam#param{ad3 = HpTuple}};
		_Other -> Battle
	end;

refresh_monster(Battle) when Battle#battle.type =:= ?CONST_BATTLE_GUILD_PVE ->
    case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
        [UserId]    ->
            BattleParam     = Battle#battle.param,
            UnitsRight      = Battle#battle.units_right,
            HpTupleTempNew  = battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
            HpTupleTempOld  = BattleParam#param.ad5,
            HurtTuple       = battle_mod_misc:clac_hurt_tuple(HpTupleTempOld, HpTupleTempNew),
            HpTupleNew      = guild_pvp_api:refresh_monster(UserId, UnitsRight#units.id, HurtTuple),
            HpTuple         = battle_mod_misc:revise_hp_tuple(HpTupleTempNew, HpTupleNew),
            UnitTupe2       = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), HpTuple),
            Battle#battle{units_right = UnitsRight#units{units = UnitTupe2},
                          param = BattleParam#param{ad5 = HpTuple}};
        _Other -> Battle
    end;

refresh_monster(Battle) -> Battle.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exec(Battle) ->
	[RecOperate|_]		= Battle#battle.seq,
	{AtkSide, AtkIdx}	= RecOperate#operate.key,
	SkillIdxSelect		= RecOperate#operate.skill_idx,
	AtkUnit				= battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
	SkillSelect			= get_exec_skill(AtkUnit, SkillIdxSelect),
	Result				=
		case battle_mod_misc:check_skill(AtkUnit, SkillSelect) of
			?ok -> {?ok, SkillIdxSelect, SkillSelect};
			{?error, ?CONST_BATTLE_ACT_REASON_FORBID} ->
				{?error, ?CONST_BATTLE_ACT_REASON_FORBID};
			_Any ->
				NormalSkill	= if
								  is_record(AtkUnit, unit) -> AtkUnit#unit.normal_skill;
								  ?true -> ?null
							  end,
				case battle_mod_misc:check_skill(AtkUnit, NormalSkill) of
					?ok -> {?ok, 0, NormalSkill};
					{?error, ?CONST_BATTLE_ACT_REASON_FORBID} ->
						{?error, ?CONST_BATTLE_ACT_REASON_FORBID};
					_Any -> {?error, ?CONST_BATTLE_ACT_REASON_FORBID}
				end
		end,
	Battle3		=
		case Result of
			{?ok, SkillIdx, Skill} ->
				Skill2		= battle_mod_misc:set_skill_cd(Skill),
				case set_exec_skill(AtkUnit, SkillIdx, Skill2) of
					AtkUnit2 when is_record(AtkUnit2, unit) ->
						Battle2		= battle_mod_misc:set_unit(Battle, AtkSide, AtkUnit2),
						exec_skill(Battle2, Skill2, AtkSide, AtkIdx);
					?null -> Battle
				end;
			_ -> Battle
		end,
	NewSeq		= lists:keydelete({AtkSide, AtkIdx}, #operate.key, Battle3#battle.seq),
	battle_mod:refresh_seq(Battle3#battle{seq = NewSeq}).


get_exec_skill(AtkUnit, SkillIdx)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_PLAYER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case SkillIdx of
		0 -> AtkUnit#unit.normal_skill;
		SkillIdx -> element(SkillIdx, AtkUnit#unit.active_skill)
	end;
get_exec_skill(AtkUnit, SkillIdx)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_PARTNER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case SkillIdx of
		0 -> AtkUnit#unit.normal_skill;
		_ -> AtkUnit#unit.active_skill
	end;
get_exec_skill(AtkUnit, SkillIdx)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_MONSTER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case SkillIdx of
		0 -> AtkUnit#unit.normal_skill;
		_ -> AtkUnit#unit.active_skill
	end;
get_exec_skill(AtkUnit, SkillIdx) ->
%% 	?MSG_ERROR("AtkUnit:~p SkillIdx:~p Stack:~p", [AtkUnit, SkillIdx, erlang:get_stacktrace()]),
	?null.

set_exec_skill(AtkUnit, SkillIdx, Skill)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_PLAYER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	UserId 		= (AtkUnit#unit.unit_ext)#unit_ext_player.user_id,
%% 	admin_log_api:log_battle_skill(UserId, AtkUnit#unit.lv, Skill#skill.skill_id, AtkUnit#unit.pro, 0),
	case SkillIdx of
		0 -> AtkUnit#unit{normal_skill = Skill};
		SkillIdx -> AtkUnit#unit{active_skill = setelement(SkillIdx, AtkUnit#unit.active_skill, Skill)}
	end;
set_exec_skill(AtkUnit, SkillIdx, Skill)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_PARTNER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case SkillIdx of
		0 -> AtkUnit#unit{normal_skill = Skill};
		_ -> AtkUnit#unit{active_skill = Skill}
	end;
set_exec_skill(AtkUnit, SkillIdx, Skill)
  when is_record(AtkUnit, unit) andalso
	   AtkUnit#unit.type =:= ?CONST_SYS_MONSTER andalso
	   AtkUnit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	case SkillIdx of
		0 -> AtkUnit#unit{normal_skill = Skill};
		_ -> AtkUnit#unit{active_skill = Skill}
	end;
set_exec_skill(AtkUnit, SkillIdx, Skill) ->
	?MSG_ERROR("AtkUnit:~p SkillIdx:~p Skill:~p Stack:~p", [AtkUnit, SkillIdx, Skill, erlang:get_stacktrace()]),
	?null.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exec_skill(Battle, Skill, AtkSide, AtkIdx) ->
    Effect   	= Skill#skill.effect,
    EffecId 	= Effect#effect.effect_id,
    Battle2     = battle_mod_misc:minus_anger(Battle, AtkSide, AtkIdx, Skill),								%% 减怒气
    Battle3     = battle_skill_front:exec_skill_front(EffecId, Battle2, Skill, Effect, AtkSide, AtkIdx),	%% 技能预先处理流程
    Battle4     = battle_skill_middle:exec_skill_middle(EffecId, Battle3, Skill, Effect, AtkSide, AtkIdx),	%% 技能执行处理流程
    Battle5     = battle_skill_back:exec_skill_back(EffecId, Battle4, Skill, Effect, AtkSide, AtkIdx),		%% 技能后续处理流程
    Battle6		= exe_ai(Battle5),																			%% 攻击受击触发ai
	Battle7     = exec_resist(Battle6, Skill, Effect, AtkSide, AtkIdx),										%% 技能反击处理流程
	Battle8     = battle_genius_skill:genius_skill_back(Battle7),											%% 天赋技能后续处理流程
    Battle9     = exec_skill_over(Battle8, Skill),
	Battle9.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 攻击受击ai触发
exe_ai(Battle) ->
	{Battle2, AiPacket} = ai_api:trigger_ai(Battle, ?CONST_AI_TRIGGER_CHANGE),
	OldAiPacket = Battle2#battle.ai_packet,
	Battle2#battle{ai_packet = <<OldAiPacket/binary, AiPacket/binary>>}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 反击流程
exec_resist(Battle, Skill, Effect, AtkSide, AtkIdx) ->
    case Skill#skill.counter of
        ?CONST_SYS_FALSE -> Battle;
        _ -> exec_resist_more(Battle#battle.resist_list, Battle, Skill, Effect, AtkSide, AtkIdx, [], ?false)
    end.

exec_resist_more([{DefSide, DefIdx}|ResistList], Battle, Skill, Effect, AtkSide, AtkIdx, ResistCmds, ResistFlag) ->
    DefUnit     = battle_mod_misc:get_unit(Battle, DefSide, DefIdx),
    AtkUnit     = battle_mod_misc:get_unit(Battle, AtkSide, AtkIdx),
    if is_record(DefUnit, unit) andalso is_record(AtkUnit, unit) ->
           {
            Battle2, ResistCmd, ResistFlag2
           }    = do_exec_resist(Battle, Skill, Effect, {DefSide, DefUnit}, {AtkSide, AtkUnit}, ResistFlag),
           exec_resist_more(ResistList, Battle2, Skill, Effect, AtkSide, AtkIdx, ResistCmds ++ ResistCmd, ResistFlag2);
       ?true ->
           exec_resist_more(ResistList, Battle, Skill, Effect, AtkSide, AtkIdx, ResistCmds, ResistFlag)
    end;
exec_resist_more([], Battle, _Skill, _Effec, _AtkSide, _AtkIdx, ResistCmds, ResistFlag) ->
    ResistTime  = case ResistFlag of ?true -> ?CONST_BATTLE_TIME_RESIST; ?false -> 0 end,
    Battle#battle{cmd_resist = ResistCmds, time = Battle#battle.time + ResistTime}.

do_exec_resist(Battle, Skill, _Effec, {ResistAtkSide, ResistAtkUnit}, {ResistDefSide, ResistDefUnit}, ResistFlag) ->
    case check_resist(Skill, ResistAtkUnit) of
        ?true ->
			case battle_mod_calc:calc_resist(ResistAtkUnit, ResistDefUnit) of
				?true ->% 反击
%%                 _ -> % 必反
					FlagCrit    = battle_mod_misc:crit_flag(?false),
					
					HurtBase    = battle_mod_calc:calc_hurt_base(ResistAtkUnit, ResistDefUnit),
					RAtkHurt	= 0,
					RAtkDisplay	= ?CONST_BATTLE_DISPLAY_RESIST_ATK,
					HurtFinalTmp= battle_mod_calc:calc_hurt_resist(HurtBase, ResistDefUnit, ResistAtkUnit),
                    HurtFinalTmp2 = calc_buff(HurtFinalTmp, ResistDefUnit, ResistAtkUnit),
					{
					 ResistDefUnit2, _Death, HurtFinal
					}			= battle_mod_misc:minus_hp(Battle#battle.enlarge_rate, ResistDefUnit, HurtFinalTmp2),
					ResistAtkUnit2	= ResistAtkUnit#unit{resist = ?null},
					Battle2     = battle_mod_misc:set_unit(Battle, ResistAtkSide, ResistAtkUnit2),
					Battle3     = battle_mod_misc:set_unit(Battle2, ResistDefSide, ResistDefUnit2),
					Battle4     = battle_mod_misc:cumsum_hurt(Battle3, ResistAtkSide, HurtFinal),
					Battle5		= exe_ai(Battle4), %% 反击也触发攻击受击ai
					RDefDisplay	= ?CONST_BATTLE_DISPLAY_RESIST_DEF,
					
					RAtkCmd		= battle_mod_misc:cmd_data(0, ResistAtkSide, ResistAtkUnit, FlagCrit, RAtkDisplay, RAtkHurt, [], []),
					RDefCmd		= battle_mod_misc:cmd_data(0, ResistDefSide, ResistDefUnit2, FlagCrit, RDefDisplay, HurtFinal, [], []),
					{Battle5, [RAtkCmd, RDefCmd], ?true};
				?false ->
					{Battle, [], ResistFlag}
			end;
        ?false ->
            {Battle, [], ResistFlag}
    end.

%% 反击判定
%% 当攻方远，守方近时，必不能反；其他需要另外计算
%% atk, def
check_resist(SkillAtk, #unit{normal_skill = SkillDef}) ->
    check_resist(SkillAtk, SkillDef);
check_resist(#skill{skill_type = ?CONST_SKILL_ATK_TYPE_FARAWAY},
			 #skill{skill_type = ?CONST_SKILL_ATK_TYPE_NEARBY}) ->
    ?false;
check_resist(_, _) ->
    ?true.

%% 特殊buff影响伤害
calc_buff(Hurt, #unit{buff = []}, _ResistAtkUnit) -> Hurt;
calc_buff(Hurt, ResistDefUnit, _ResistAtkUnit) ->
    Buff = ResistDefUnit#unit.buff,
    case lists:keyfind(?CONST_BUFF_TYPE_81, 3, Buff) of % 无敌
        ?false -> Hurt;
        _      -> 0
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% {Key, AtkCmd, [DefCmd|DefCmds]}		{SkillId, SkillLv, AtkSide, AtkIdx}
%% 处理战斗指令集
exec_skill_over(Battle, Skill) ->
    AtkCmd      = Battle#battle.cmd_atk,
    DefCmds     = Battle#battle.cmd_def,
%% 	DefCmds     = lists:reverse(Battle#battle.cmd_def),
    ResistCmds  = Battle#battle.cmd_resist,
	GeniusCmds  = [begin
					   {GeniusSkillId, GeniusSkillLv, [GeniusAtkCmd|GeniusDefCmds]}
				   end
				   || {{GeniusSkillId, GeniusSkillLv, _AtkSide, _AtkIdx}, GeniusAtkCmd, GeniusDefCmds} <- Battle#battle.cmd_genius],
    CmdsTemp    = DefCmds ++ ResistCmds,
    Cmds        = {Skill#skill.skill_id, Skill#skill.lv, [AtkCmd|CmdsTemp]},
%%  Battle2     = exec_skill_over_buff_data(Battle, Skill),
    Time        = Battle#battle.time + Skill#skill.time,
	Battle#battle{
				  cmds         	= [Cmds|Battle#battle.cmds] ++ GeniusCmds,
%% 				  cmd_pre_atk	= ?null,
%% 				  cmd_pre_def	= [],
				  cmd_atk      	= ?null,
				  cmd_def      	= [],
				  cmd_resist   	= [],
				  cmd_genius	= [],
				  
				  genius_list	= [],
				  resist_list	= [],
				  time         	= Time
				 }.

change_unit_buff(EnlargeRate, Unit, BuffDelete, BuffInsert) ->
    FunUninstall    = fun(Buff, AccUnit) ->
                              battle_mod_buff:buff_uninstall(AccUnit, Buff)
                      end,
    Unit2           = lists:foldl(FunUninstall, Unit, BuffDelete),
    FunInstall      = fun(Buff, AccUnit) ->
                              battle_mod_buff:buff_install(EnlargeRate, AccUnit, Buff#buff{install_point = ?CONST_BUFF_INSTALL_POINT_DEFAULT})
                      end,
    Unit3			= lists:foldl(FunInstall, Unit2, BuffInsert),
	Unit3.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Local Functions
%%

