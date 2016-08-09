%% Author: Administrator
%% Created: 2012-12-24
%% Description: TODO: Add description to ai_mod
-module(ai_mod).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/record.battle.hrl").
-include("../include/record.map.hrl").
-include("../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([trigger_ai/2,
		 start_ai/3,
		 do_ai/3,
		 partner_help_join/4]).

%% -compile(export_all).
%%
%% API Functions
%% 初始化战斗触发ai
trigger_ai(Battle, Trigger) ->
	AiList = (Battle#battle.param)#param.ai_list,
%% 	?MSG_DEBUG("trigger_ai11111111111:~p",[AiList]),
	Fun = fun(Item) ->
				  data_ai:get_base_ai(Item)
		  end,
	AiRecList = lists:map(Fun, AiList),
	trigger_ai(AiRecList, Battle, Trigger, <<>>).

trigger_ai([], Battle, _Trigger, Packet) -> {Battle, Packet};
trigger_ai([AiRec|AiRecList], Battle, Trigger, Packet) ->
	case AiRec#rec_ai.trigger of
		Trigger ->
			{Battle2, Packet2} = start_ai(Battle, AiRec, Packet),
			trigger_ai(AiRecList, Battle2, Trigger, Packet2);
		_ ->
			trigger_ai(AiRecList, Battle, Trigger, Packet)
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%	
%% 触发方式--联动触发			0	CONST_AI_START_LINKAGE
%% 触发方式--第几回合			1	CONST_AI_START_NTH
%% 触发方式--每几回合			2	CONST_AI_START_PER
%% 触发方式--第几回合后每回合	3	CONST_AI_START_NTHTAIL
%% 触发方式--hp达到			4	CONST_AI_START_ATTR_HP
%% 触发方式--怒气改变后达到	5	CONST_AI_START_ATTR_ANGER
%% 触发方式--死亡				6	CONST_AI_START_DIE
%% 触发方式--战斗初始化		7	CONST_AI_START_INIT_BATTLE
%% 触发方式--出手触发			8	CONST_AI_START_ATTACK
%% 触发方式--人数变化			9	CONST_AI_START_UNITS_CHANGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 触发方式--第几回合
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_NTH, Value}} = RecAi, Packet) -> 
	Bout = Battle#battle.bout,
	case Bout =:= Value of
		?true ->
			{Battle1, Packet1}  = do_ai(Battle, RecAi, Packet),
			Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
			{Battle2, Packet1};
		?false ->
			{Battle, Packet}
	end;
%% 触发方式--每几回合
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_PER, Value}} = RecAi, Packet) -> 
	Bout = Battle#battle.bout,
	case Bout rem Value =:= 0 of
		?true ->
			do_ai(Battle, RecAi, Packet);
		?false ->
			{Battle, Packet}
	end;
%% 触发方式--第几回合后每回合
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_NTHTAIL, Value}} = RecAi, Packet) ->
	Bout = Battle#battle.bout,
	case Bout > Value  of
		?true ->
			do_ai(Battle, RecAi, Packet);
		?false ->
			{Battle, Packet}
	end;
%% 触发方式--hp达到%(hp为0表示单位死亡)
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_ATTR_HP, Value}} = RecAi, Packet) ->
	Side = RecAi#rec_ai.con_side,
	case get_con_units(Battle, Side, RecAi) of
		[Unit|_] when is_record(Unit, unit) ->
			{_Attr, AttrSecond, _AttrElite} 	= battle_mod_misc:get_unit_attr(Unit),
			HpMax = AttrSecond#attr_second.hp_max,
			case Unit#unit.hp =< HpMax * Value div ?CONST_SYS_NUMBER_HUNDRED of
				?true ->
					{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),	
					Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
					{Battle2, Packet1};
				?false ->
					{Battle, Packet}
			end;
		_ ->
			{Battle, Packet}
	end;
%% 触发方式--怒气达到 点
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_ATTR_ANGER, Value}} = RecAi, Packet) ->
	Side = RecAi#rec_ai.con_side,
	case get_con_units(Battle, Side, RecAi) of
		[Unit|_] when is_record(Unit, unit) ->
			case Unit#unit.anger =:= Value of
				?true ->
					{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
					Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
					{Battle2, Packet1};
				?false ->
					{Battle, Packet}
			end;
		_ ->
			{Battle, Packet}
	end;
%% 触发方式--死亡触发(有单位死亡)
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_DIE, Value}} = RecAi, Packet) ->
	Side = RecAi#rec_ai.con_side,
	Units = get_side_units(Battle, Side),
	case check_dead_num(Units, Value) of
		?true ->
			{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
			Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
			{Battle2, Packet1};
		?false ->
			{Battle, Packet}
	end;

%% 触发方式--战斗初始化
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_INIT_BATTLE, _Value}} = RecAi, Packet) ->
	{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
	Battle2 = del_ai(Battle1, RecAi#rec_ai.id),
	{Battle2, Packet1};

%% 触发方式--出手触发
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_ATTACK, Value}} = RecAi, Packet) ->
	Bout	= Battle#battle.bout,
	Side = RecAi#rec_ai.con_side,
	case get_con_units(Battle, Side, RecAi) of
		[Unit|_] when is_record(Unit, unit) ->
			[Operate|_Seq]	= Battle#battle.seq,
			{_AttackSide, AttackIdx} =  Operate#operate.key,
			case Bout =:= Value andalso Unit#unit.idx =:= AttackIdx of
				?true ->
					{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
					Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
					{Battle2, Packet1};
				?false ->
					{Battle, Packet}
			end;
		_ ->
			{Battle, Packet}
	end;

%% 触发方式--人数变化
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_UNITS_CHANGE, Round}} = RecAi, Packet) ->
	Side 	= RecAi#rec_ai.con_side,
	Units 	= get_side_units(Battle, Side),
	Value	= RecAi#rec_ai.value,
	case Battle#battle.round  =:= Round andalso check_live_num(Units, Value) of
		?true ->
			{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
			Battle2 = del_ai(Battle1, RecAi#rec_ai.id), %% 删除ai保证只触发一次
			{Battle2, Packet1};
		?false ->
			{Battle, Packet}
	end;

%% 触发方式--无条件触发(联动触发的)
start_ai(Battle, #rec_ai{ai_start = {?CONST_AI_START_LINKAGE, _Value}} = RecAi, Packet) ->
	{Battle1, Packet1} = do_ai(Battle, RecAi, Packet),
	Battle2 = del_ai(Battle1, RecAi#rec_ai.id),
	{Battle2, Packet1}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ai类型--冒泡说话			1	CONST_AI_TYPE_TALK
%% ai类型--播放动画			2	CONST_AI_TYPE_PLAY_CARTOON
%% ai类型--buff增加删除		3	CONST_AI_TYPE_BUFF
%% ai类型--战斗初始加入		4	CONST_AI_TYPE_INIT_JOIN
%% ai类型--单位加入			5	CONST_AI_TYPE_JOIN
%% ai类型--单位离开			6	CONST_AI_TYPE_QUIT
%% ai类型--设置怒气			7	CONST_AI_TYPE_SET_ANGER
%% ai类型--设置生命值			8	CONST_AI_TYPE_SET_HP
%% ai类型--增加战斗属性		9	CONST_AI_TYPE_PLUS_ATTR
%% ai类型--设置出手(不攻击)	10	CONST_AI_TYPE_SET_NO_ATTACK
%% ai类型--己方全死副本通关	11	CONST_AI_TYPE_FINISH_COPY
%% ai类型--设置出手顺序		12	CONST_AI_TYPE_SET_SEQ
%% ai类型--降低战斗属性		13	CONST_AI_TYPE_MINUS_ATTR
%% ai类型--车轮战	    		14	CONST_AI_TYPE_ROUND_BATTLE
%% ai类型--禁止闪避			15	CONST_AI_TYPE_FORBID_DODGE
%% ai类型--禁止格挡			16	CONST_AI_TYPE_FORBID_PARRY
%% ai类型--按职业加入			17	CONST_AI_TYPE_JOIN_BY_PRO
%% ai类型--设置攻击目标		18	CONST_AI_TYPE_SET_TARGET
%% ai类型--初始车轮战轮数		19	CONST_AI_TYPE_INIT_ROUND
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 执行ai
%% 说话冒泡
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_TALK, next_ai = NextAi} = RecAi, Packet) ->
	Battle2 	= set_battle_on(Battle, RecAi#rec_ai.is_stop),
	Packet1 	= ai_api:msg_ai_talk(Battle2, RecAi),
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 播放动画
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_PLAY_CARTOON, next_ai = NextAi} = RecAi, Packet) ->
	Battle2 	= set_battle_on(Battle, RecAi#rec_ai.is_stop),
	Packet1 	= ai_api:msg_ai_talk(Battle2, RecAi),
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 特效buff
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_BUFF, next_ai = NextAi} = RecAi, Packet) ->
	Battle2 	= set_battle_on(Battle, RecAi#rec_ai.is_stop),
	Packet1 	= ai_api:msg_ai_talk(Battle2, RecAi),
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 战斗初始加入
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_INIT_JOIN, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	JoinList 	= get_target_List(Side, RecAi),
	{Battle2, _AddList} 	= unit_join(Battle, Side, JoinList, []),
	do_next_ai(Battle2, RecAi, NextAi, Packet);
%% 加入
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_JOIN, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	JoinList 	= get_target_List(Side, RecAi),
	{Battle2, AddList} 	= unit_join(Battle, Side, JoinList, []), 
	Battle3 	= 
		case AddList of
			[] ->
				Battle2;
			_ ->
				set_battle_on(Battle2, RecAi#rec_ai.is_stop)
		end,
	Packet1		= ai_api:msg_ai_join(Battle3, RecAi, AddList), %% 后端加入时记录离开单位发送协议
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle3, RecAi, NextAi, Packet2);
%% 离开
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_QUIT, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	TargertList = get_target_units(Battle, Side, RecAi),
	{Battle2, QuitList}  = unit_quit(Battle, Side, TargertList, []),
	Battle3 	= 
		case QuitList of
			[] ->
				Battle2;
			_ ->
				set_battle_on(Battle2, RecAi#rec_ai.is_stop)
		end,
	Packet1		= ai_api:msg_ai_quit(Battle3, RecAi, QuitList), %% 后端离开时记录离开单位发送协议
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle3, RecAi, NextAi, Packet2);

%% 设置怒气(满怒气即为释放技能)
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_ANGER, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side = RecAi#rec_ai.target_side,
	TargertList = get_target_units(Battle, Side, RecAi),
	{Battle2, EffectList, PacketSkill} = set_anger(Battle, Side, Value, TargertList, [], <<>>),
	Packet1		= ai_api:msg_ai_hp_anger_change(Battle2, RecAi, EffectList), %% 后端离开时记录离开单位发送协议
	Packet2		= <<Packet/binary, Packet1/binary, PacketSkill/binary>>, 
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 设置生命
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_HP, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	EffectList 	= get_target_units(Battle, Side, RecAi),
	ValueType	= RecAi#rec_ai.value_type,
	Battle2 	= set_hp(Battle, Side, ValueType, Value, EffectList),
	Packet1		= ai_api:msg_ai_hp_anger_change(Battle2, RecAi, EffectList), %% 后端离开时记录离开单位发送协议
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 增加属性
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_PLUS_ATTR, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	EffectList 	= get_target_units(Battle, Side, RecAi),
	ValueType	= RecAi#rec_ai.value_type,
	AttrType    = RecAi#rec_ai.attr_type,
	Battle2 	= set_attr(Battle, Side, ValueType, AttrType, Value, EffectList),
	Packet1		= ai_api:msg_ai_attr_change(Battle, RecAi, EffectList),
	Packet2	= <<Packet/binary, Packet1/binary>>,
	do_next_ai(Battle2, RecAi, NextAi, Packet2);
%% 设置出手(不攻击)
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_NO_ATTACK, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side = RecAi#rec_ai.target_side,
	EffectList = get_target_units(Battle, Side, RecAi),
	Battle2 = set_no_attack(Battle, Side, Value, EffectList),
	do_next_ai(Battle2, RecAi, NextAi, Packet);
%% 己方全死，副本通关
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_FINISH_COPY, next_ai = NextAi} = RecAi, Packet) ->
	Battle2 = Battle#battle{result = ?CONST_BATTLE_RESULT_LEFT},
	do_next_ai(Battle2, RecAi, NextAi, Packet);
%% 立即出手
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_SEQ,  next_ai = NextAi} = RecAi, Packet) ->
	Side = RecAi#rec_ai.target_side,
	EffectList = get_target_units(Battle, Side, RecAi),
	Battle2 = set_attack_now(Battle, Side,  EffectList),
	do_next_ai(Battle2, RecAi, NextAi, Packet);

%% 降低属性
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_MINUS_ATTR, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	EffectList 	= get_target_units(Battle, Side, RecAi),
	ValueType	= RecAi#rec_ai.value_type,
	AttrType    = RecAi#rec_ai.attr_type,
	Battle2 	= set_attr(Battle, Side, ValueType, AttrType, -Value, EffectList),
	Packet1		= ai_api:msg_ai_attr_change(Battle, RecAi, EffectList),
	Packet2	= <<Packet/binary, Packet1/binary>>,
	do_next_ai(Battle2, RecAi, NextAi, Packet2);

%% 车轮战
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_ROUND_BATTLE, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	JoinList 	= get_target_List(Side, RecAi),
	{Battle2, AddList} 	= unit_join(Battle, Side, JoinList, []), 
	Battle3 	= 
		case AddList of
			[] ->
				Battle2;
			_ ->
				set_battle_on(Battle2, RecAi#rec_ai.is_stop)
		end,
	Packet1		= ai_api:msg_ai_join(Battle3, RecAi, AddList), %% 后端加入时记录离开单位发送协议
	Packet2		= <<Packet/binary, Packet1/binary>>,
	%% 重置出手顺序
	{Seq, Operate, _} = battle_mod:init_seq(Battle3#battle.units_left, Battle3#battle.units_right, Battle3#battle.operate),
	[CurOperate|RemainSeq] = Battle3#battle.seq,
	Seq2 		= round_battle_set_seq(Seq, RemainSeq),
	Battle4		= Battle3#battle{seq = [CurOperate|Seq2], operate = Operate, refresh = ?true, round_refresh = ?true}, 
%% 	?MSG_DEBUG("do_ai_round11111111111111111111:~p",[{Battle4#battle.operate, Battle4#battle.seq}]),
	do_next_ai(Battle4, RecAi, NextAi, Packet2);
	
%% 禁止闪避
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_FORBID_DODGE,  next_ai = NextAi} = RecAi, Packet) ->
	Battle2 = Battle#battle{forbid_dodge = ?true},
	do_next_ai(Battle2, RecAi, NextAi, Packet);

%% 禁止格挡
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_FORBID_PARRY,  next_ai = NextAi} = RecAi, Packet) ->
	Battle2 = Battle#battle{forbid_parry = ?true},
	do_next_ai(Battle2, RecAi, NextAi, Packet);

%% 按职业初始加入
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_JOIN_BY_PRO, next_ai = NextAi} = RecAi, Packet) ->
	case get_unit_player(Battle) of
		{?ok, UnitPlayer} ->
			Side 		= RecAi#rec_ai.target_side,
			TargetList	= get_target_List(Side, RecAi),
			Pro = UnitPlayer#unit.pro,
			{_, JoinId, Idx}		= lists:keyfind(Pro, 1, TargetList),
			{Battle2, _AddList} 	= unit_join(Battle, Side, [{JoinId, Idx}], []), 
			do_next_ai(Battle2, RecAi, NextAi, Packet);
		{?error, _ErrorCode} ->
			Battle
	end;

%% 设置攻击目标
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_TARGET, next_ai = NextAi} = RecAi, Packet) ->
	Side 	= RecAi#rec_ai.target_side,
	case get_target_units(Battle, Side, RecAi) of
		[Unit|_] when is_record(Unit, unit) ->
			DefSide 	= RecAi#rec_ai.def_side,
			DefList		= get_def_units(Battle, DefSide, RecAi),
			Unit2		= Unit#unit{target = DefList},
			Battle2		= battle_mod_misc:set_unit(Battle, Side, Unit2),
			do_next_ai(Battle2, RecAi, NextAi, Packet);
		_ ->
			do_next_ai(Battle, RecAi, NextAi, Packet)
	end;

%% 车轮战副本初始显示轮数
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_INIT_ROUND, next_ai = NextAi} = RecAi, Packet) ->
	Value 		= RecAi#rec_ai.value,
	Packet1		= ai_api:msg_ai_round(RecAi#rec_ai.id, Value),
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	do_next_ai(Battle, RecAi, NextAi, Packet2);

%% 增加属性(前端不表现)
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_PLUS_ATTR_SERV, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	EffectList 	= get_target_units(Battle, Side, RecAi),
	ValueType	= RecAi#rec_ai.value_type,
	AttrType    = RecAi#rec_ai.attr_type,
	Battle2 	= set_attr(Battle, Side, ValueType, AttrType, Value, EffectList),
	do_next_ai(Battle2, RecAi, NextAi, Packet);

%% 降低属性(前端不表现)
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_MINUS_ATTR_SERV, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Side 		= RecAi#rec_ai.target_side,
	EffectList 	= get_target_units(Battle, Side, RecAi),
	ValueType	= RecAi#rec_ai.value_type,
	AttrType    = RecAi#rec_ai.attr_type,
	Battle2 	= set_attr(Battle, Side, ValueType, AttrType, -Value, EffectList),
	do_next_ai(Battle2, RecAi, NextAi, Packet);

%% 学习技能
do_ai(Battle, #rec_ai{type = ?CONST_AI_SKILL_STUDY, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	Battle2 	= set_battle_on(Battle, RecAi#rec_ai.is_stop),
	Packet1 	= ai_api:msg_ai_talk(Battle2, RecAi),
	Packet2		= <<Packet/binary, Packet1/binary>>, 
	Side		= ?CONST_BATTLE_UNITS_SIDE_LEFT,
	case get_unit_player(Battle2) of
		{?ok, UnitPlayer} ->
			Pro = UnitPlayer#unit.pro,
			{_, SkillId, Lv}		= lists:keyfind(Pro, 1, Value),
			Unit2	 			= set_skill(UnitPlayer, {SkillId, Lv}),
			Battle3 			= battle_mod_misc:set_unit(Battle2, Side, Unit2),
			Battle4				= set_skill_ext(Battle3, Side, Unit2),
			do_next_ai(Battle4, RecAi, NextAi, Packet2);
		{?error, _ErrorCode} ->
			Battle
	end;

%% 按职业设置怒气(满怒气即为释放技能)
do_ai(Battle, #rec_ai{type = ?CONST_AI_TYPE_SET_ANGER_BY_PRO, value = Value, next_ai = NextAi} = RecAi, Packet) ->
	case get_unit_player(Battle) of
		{?ok, UnitPlayer} ->
			Side 		= RecAi#rec_ai.target_side,
			TargetList	= get_target_List(Side, RecAi),
			Pro 		= UnitPlayer#unit.pro,
			{_, Id, _}	= lists:keyfind(Pro, 1, TargetList),
			case get_unit(Battle, Side, Id) of
				{?ok, Unit} ->
					{Battle2, _EffectList, PacketSkill} = set_anger(Battle, Side, Value, [Unit], [], <<>>),
					Packet1		= <<>>,%ai_api:msg_ai_hp_anger_change(Battle2, RecAi, EffectList),
					Packet2		= <<Packet/binary, Packet1/binary, PacketSkill/binary>>, 
					do_next_ai(Battle2, RecAi, NextAi, Packet2);
				_ ->
					do_next_ai(Battle, RecAi, NextAi, Packet)
			end;
		{?error, _ErrorCode} ->
			Battle
	end.

%% 执行联动ai
do_next_ai(Battle, CurRecAi, NextAi, Packet) ->
	NextRecAi = data_ai:get_base_ai(NextAi),
	case CurRecAi#rec_ai.id =/= NextAi andalso is_record(NextRecAi, rec_ai) of
		?true ->
			Battle2 = add_ai(Battle, NextAi),
			case NextRecAi#rec_ai.trigger =:= 0 of  %% 判断是否为联动触发类型
				?true ->
					start_ai(Battle2, NextRecAi, Packet);
				?false ->
					{Battle2, Packet}
			end;
		?false ->
			{Battle, Packet}
	end.

	
%% 往ailist增加新的aiid
add_ai(Battle, AiId) ->
	Param = Battle#battle.param,
	AiList = Param#param.ai_list,
	AiList2 = [AiId|AiList],
	Param2 = Param#param{ai_list = AiList2},
	Battle#battle{param = Param2}.

%% 删除ai_list中的ai_id保证只触发一次
del_ai(Battle, AiId) ->
	Param = Battle#battle.param,
	AiList = Param#param.ai_list,
	AiList2 = lists:delete(AiId, AiList),
	Param2 = Param#param{ai_list = AiList2},
	Battle#battle{param = Param2}.

%% 更改战斗开启标志
set_battle_on(Battle, IsStop) ->
	case IsStop =:= 1 of
		?true ->
			Battle#battle{sleep = ?true};
		?false ->
			Battle
	end.

%% 获取con_units
get_con_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, RecAi) ->
	ConList = RecAi#rec_ai.con_units_1,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, ConList, []);
get_con_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, RecAi) ->
	ConList = RecAi#rec_ai.con_units_2,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, ConList, []);
get_con_units(_Battle, _Side, _RecAi) -> [].

%% 获取target_units
get_target_List(?CONST_BATTLE_UNITS_SIDE_LEFT, RecAi) ->
	RecAi#rec_ai.target_units_1;
get_target_List(?CONST_BATTLE_UNITS_SIDE_RIGHT, RecAi) ->
	RecAi#rec_ai.target_units_2;
get_target_List(_Side, _RecAi) -> [].

%% 获取target_units
get_target_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, RecAi) ->
	TargetList = RecAi#rec_ai.target_units_1,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, TargetList, []);
get_target_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, RecAi) ->
	TargetList = RecAi#rec_ai.target_units_2,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, TargetList, []);
get_target_units(_Battle, _Side, _RecAi) -> [].

%% 获取def_units
get_def_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, RecAi) ->
	TargetList = RecAi#rec_ai.def_units_1,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, TargetList, []);
get_def_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, RecAi) ->
	TargetList = RecAi#rec_ai.def_units_2,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, TargetList, []);
get_def_units(_Battle, _Side, _RecAi) -> [].
	
%% 转化target_units
convert_to_units(_Battle, _Side, [], AccList) -> AccList;
convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, [1|Tail], AccList) ->
	Units 		= get_side_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT),
	UnitList    = misc:to_list(Units#units.units),
	Fun = fun(#unit{type = ?CONST_SYS_PARTNER} = Unit, Acc) ->
				  [Unit|Acc];
			 (_Unit, Acc) ->
				  Acc
		  end,
	NewUnitList = lists:foldl(Fun, [], UnitList),
	NewAccList  = NewUnitList ++ AccList,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Tail, NewAccList);
convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, [Id|Tail], AccList) ->
	NewAccList  = 
		case get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Id) of
			{?ok, Unit} ->
				[Unit|AccList];
			_ ->
				AccList
		end,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Tail, NewAccList);
convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, [1|Tail], AccList) ->
	Units 		= get_side_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT),
	UnitList    = misc:to_list(Units#units.units),
	Fun = fun(#unit{type = ?CONST_SYS_PARTNER} = Unit, Acc) ->
				  [Unit|Acc];
			 (_Unit, Acc) ->
				  Acc
		  end,
	NewUnitList = lists:foldl(Fun, [], UnitList),
	NewAccList  = NewUnitList ++ AccList,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Tail, NewAccList);
convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, [{_Id, Idx}|Tail], AccList) ->
	NewAccList  = 
		case get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Idx) of
			{?ok, Unit} ->
				[Unit|AccList];
			_ ->
				AccList
		end,
	convert_to_units(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Tail, NewAccList).
	
			

%%
%% 获取battle的units
get_side_units(Battle, Side) ->
	case Side of
		?CONST_BATTLE_UNITS_SIDE_LEFT ->
			Battle#battle.units_left;
		_ ->
			Battle#battle.units_right
	end.
%% 获取玩家unit
get_unit_player(Battle) ->
	Units 		= Battle#battle.units_left,
	UnitsTuple  = Units#units.units,
	UnitsList	= misc:to_list(UnitsTuple),
	case lists:keyfind(?CONST_SYS_PLAYER, #unit.type, UnitsList) of
		Unit when is_record(Unit, unit) ->
			{?ok, Unit};
		_ ->
			{?error, ?TIP_COMMON_BAD_ARG}
	end.	

%% 【实现】单位加入 CONST_AI_TYPE_JOIN
unit_join(Battle, _Side, [], AddList) -> {Battle, AddList};
unit_join(Battle, Side, [{Id, 0}|IdList], AddList) ->
	%% idx为0自己找空位加入
	Units 		= get_side_units(Battle, Side),
	UnitsTuple  = Units#units.units,
	{NewAddList, UnitsTuple2, RecOperate} =
		case get_empty(UnitsTuple, Side, 1) of
			{?ok, Idx} ->
				unit_join_ext(Side, Id, Idx, UnitsTuple, AddList);
			{?error, _ErrorCode} ->
				{AddList, UnitsTuple,[]}
		end,
	NewUnits 	= Units#units{units = UnitsTuple2},
	OldSeq		= Battle#battle.seq,
	NewSeq		= [RecOperate|lists:reverse(OldSeq)],
    Battle2  	= 
		case Side of
			?CONST_BATTLE_UNITS_SIDE_LEFT ->
				Battle#battle{units_left = NewUnits, seq = lists:reverse(NewSeq)};
			?CONST_BATTLE_UNITS_SIDE_RIGHT ->
				Battle#battle{units_right = NewUnits, seq = lists:reverse(NewSeq)};
			_ ->
				Battle
		end,
	unit_join(Battle2, Side, IdList, NewAddList);
unit_join(Battle, Side, [{Id, Idx}|JoinList], AddList) ->
	%% idx非0指定位置加入
	Units 		= get_side_units(Battle, Side),
	TempUnitsTuple  = Units#units.units,
	UnitsTuple	= 
		case Side of
			?CONST_BATTLE_UNITS_SIDE_RIGHT ->
				clear_dead_unit(misc:to_list(TempUnitsTuple), []);
			_ ->
				TempUnitsTuple
		end,
	case element(Idx, UnitsTuple) of
		Unit when is_record(Unit, unit) ->
			NewJoinList	= [{Id, 0}|JoinList],
			unit_join(Battle, Side, NewJoinList, AddList);
		_ ->
			{NewAddList, UnitsTuple2, RecOperate} = unit_join_ext(Side, Id, Idx, UnitsTuple, AddList),
			NewUnits 	= Units#units{units = UnitsTuple2},
			OldSeq		= Battle#battle.seq,
		 	NewSeq		= [RecOperate|lists:reverse(OldSeq)],
			Battle2  	= 
				case Side of
					?CONST_BATTLE_UNITS_SIDE_LEFT ->
						Battle#battle{units_left = NewUnits, seq = lists:reverse(NewSeq)};
					?CONST_BATTLE_UNITS_SIDE_RIGHT ->
						Battle#battle{units_right = NewUnits, seq = lists:reverse(NewSeq)};
					_ ->
						Battle
				end,
		%% 	Battle3 	= battle_mod:refresh_seq(Battle2),
			unit_join(Battle2, Side, JoinList, NewAddList)
	end.

unit_join_ext(Side, Id, Idx, UnitsTuple, AddList) ->
	case monster_api:monster(Id) of
		Monster when is_record(Monster, monster) ->  
			Unit		= battle_mod_misc:record_unit(?null, Monster, Side, Idx, ?null),
			Key = {Side, Unit#unit.idx},
			Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
			SkillIdx    = 0,
			Skill		= Unit#unit.normal_skill,
			RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
			NewAddList  = [Unit|AddList],
			UnitsTuple2 = setelement(Idx, UnitsTuple, Unit),
			{NewAddList, UnitsTuple2, RecOperate};
		_ ->
			{AddList, UnitsTuple, []}
	end.

%% 怪物边清除死亡单位
clear_dead_unit([#unit{state = ?CONST_BATTLE_UNIT_STATE_DEATH} = _Unit|Units], AccUnits) ->
	NewAccUnits = [0|AccUnits],
	clear_dead_unit(Units, NewAccUnits);
clear_dead_unit([Unit|Units], AccUnits) ->
	NewAccUnits = [Unit|AccUnits],
	clear_dead_unit(Units, NewAccUnits);
clear_dead_unit([], AccUnits) -> 
	UnitsList = lists:reverse(AccUnits),
	misc:to_tuple(UnitsList).
	
get_empty(Units, ?CONST_BATTLE_UNITS_SIDE_LEFT, Idx) when Idx =< 9 ->
    case erlang:element(Idx, Units) of
        Unit when is_record(Unit, unit) ->
			get_empty(Units, ?CONST_BATTLE_UNITS_SIDE_LEFT, Idx + 1);
        _ -> {?ok, Idx}
    end;
get_empty(Units, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Idx) when Idx =< 9 ->
	case erlang:element(Idx, Units) of
        Unit when is_record(Unit, unit) andalso Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
			get_empty(Units, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Idx + 1);
        _ -> {?ok, Idx}
    end;
get_empty(_Position, _Side, _) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

%% 【实现】单位离开 CONST_AI_TYPE_QUIT
unit_quit(Battle, _Side, [], QuitList) -> {Battle, QuitList};
unit_quit(Battle, Side, [#unit{state = State} = Unit|UnitList], QuitList) 
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	Units = get_side_units(Battle, Side),
	Unit2 	= 0,
	UnitsTuple	= setelement(Unit#unit.idx, Units#units.units, Unit2),
	NewQuitList	= [Unit|QuitList],
	NewUnits	= Units#units{units = UnitsTuple},
	Battle1 	= 
		case Side of
			?CONST_BATTLE_UNITS_SIDE_LEFT ->
				Battle#battle{units_left = NewUnits};
			?CONST_BATTLE_UNITS_SIDE_RIGHT ->
				Battle#battle{units_right = NewUnits}
		end,
	Key = {Side, Unit#unit.idx},
	Seq2 = lists:keydelete(Key, #operate.key, Battle1#battle.seq),
	Battle2 	= Battle1#battle{seq = Seq2},
	unit_quit(Battle2, Side, UnitList, NewQuitList);
unit_quit(Battle, Side, [_Unit|UnitList], QuitList) ->
	unit_quit(Battle, Side, UnitList, QuitList).


%% 【实现】设置怒气(用怒气触发主动被动技能)  CONST_AI_TYPE_SET_ANGER
set_anger(Battle, _Side, _Value, [], EffectList, Packet) -> {Battle, EffectList, Packet};
set_anger(Battle, Side, Value, [#unit{state = State} = Unit|UnitList], EffectList, Packet)
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	Unit2 		= Unit#unit{anger = Value},
	Battle2 	= battle_mod_misc:set_unit(Battle, Side, Unit2),
	{Battle3, Packet1}	= 
		case Unit#unit.type of
			?CONST_SYS_PLAYER ->
				{Battle2, <<>>};
			_ ->
				battle_api:auto_select_skill(Battle2, Side, Unit2)
		end,
	Packet2		= <<Packet/binary, Packet1/binary>>,
	NewEffList	= [Unit|EffectList],
	set_anger(Battle3, Side, Value, UnitList, NewEffList, Packet2);
set_anger(Battle, Side, Value, [_Unit|UnitList], EffectList, Packet) ->
	set_anger(Battle, Side, Value, UnitList, EffectList, Packet).



%% 【实现】设置战斗属性  CONST_AI_TYPE_SET_ATTR
set_attr(Battle, _Side, _ValueType, _AttrType, _Value, []) -> Battle;
set_attr(Battle, Side, ValueType, AttrType, Value, [#unit{state = State} = Unit|UnitList])
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	AttrValue   = get_attr_by_type(Unit, AttrType),
	AddValue 	= 
		case ValueType of
			?CONST_AI_VALUE_TYPE_1 ->
				AttrValue * Value div ?CONST_SYS_NUMBER_HUNDRED;
			?CONST_AI_VALUE_TYPE_2 ->
				Value;
			_ ->
				0
		end,
	NewAttr  	= player_attr_api:attr_plus(Unit#unit.attr_base, AttrType, AddValue),
	Unit2	    = Unit#unit{attr_base = NewAttr, attr = NewAttr},
	AttrTemp	= player_attr_api:attr_plus(Unit2#unit.attr, Unit2#unit.attr_ext),
	Unit3		= 
		case AttrType of
			?CONST_PLAYER_ATTR_HP_MAX ->
				Unit2#unit{attr = AttrTemp, hp = Unit#unit.hp + AddValue};
			_ ->
				Unit2#unit{attr = AttrTemp}
		end,
	Battle2		= battle_mod_misc:set_unit(Battle, Side, Unit3),
	set_attr(Battle2, Side, ValueType, AttrType, Value, UnitList);
set_attr(Battle, Side, ValueType, AttrType, Value, [_Unit|UnitList]) ->
	set_attr(Battle, Side, ValueType, AttrType, Value, UnitList).

%% 【实现】设置生命  CONST_AI_TYPE_SET_HP
set_hp(Battle, _Side, _ValueType, _Value, []) -> Battle;
set_hp(Battle, Side, ValueType, Value, [#unit{attr_base = AttrBase} = Unit|UnitList]) ->
	AttrValue   = get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_HP_MAX),
	FinalValue 	= 
		case ValueType of
			?CONST_AI_VALUE_TYPE_1 ->
				AttrValue * Value div ?CONST_SYS_NUMBER_HUNDRED;
			?CONST_AI_VALUE_TYPE_2 ->
				Value;
			_ ->
				0
		end,
	AttrSecond	= AttrBase#attr.attr_second,
	BaseHpMax		= 
		case FinalValue > AttrValue of
			?true ->
				FinalValue;
			?false ->
				AttrValue
		end,
	AttrSecond2	= AttrSecond#attr_second{hp_max = BaseHpMax},
	NewAttrBase	= AttrBase#attr{attr_second = AttrSecond2},
	NewAttr		= player_attr_api:attr_plus(NewAttrBase, Unit#unit.attr_ext),
	FinalHp	= 
		case FinalValue < AttrValue of
			?true ->
				FinalValue;
			?false ->
				(NewAttr#attr.attr_second)#attr_second.hp_max
		end,
%% 	FinalValue 	= AttrValue * Value div ?CONST_SYS_NUMBER_HUNDRED,
	Unit2	    = 
		if 
		FinalValue =< 0 -> Unit#unit{hp = 0, state = ?CONST_BATTLE_UNIT_STATE_DEATH};
		?true -> Unit#unit{hp = FinalHp, attr_base = NewAttrBase, attr = NewAttr, state = ?CONST_BATTLE_UNIT_STATE_NORMAL}
	end,
	Battle2		= battle_mod_misc:set_unit(Battle, Side, Unit2),
	set_hp(Battle2, Side, ValueType, Value, UnitList);
set_hp(Battle, Side, ValueType, Value, [_Unit|UnitList]) ->
	set_hp(Battle, Side, ValueType, Value, UnitList).

%% 二级属性
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_HP_MAX) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.hp_max;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_FORCE_ATTACK) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.force_attack;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_FORCE_DEF) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.force_def;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_MAGIC_ATTACK) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.magic_attack;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_MAGIC_DEF) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.magic_def;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_SPEED) ->
	{_AttrBase,	AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseSecond#attr_second.speed;
%% 部分精英属性
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_E_HIT) ->
	{_AttrBase,	_AttrBaseSecond, AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseElite#attr_elite.hit;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_E_DODGE) ->
	{_AttrBase,	_AttrBaseSecond, AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseElite#attr_elite.dodge;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_E_CRIT) ->
	{_AttrBase,	_AttrBaseSecond, AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseElite#attr_elite.crit;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_E_PARRY) ->
	{_AttrBase,	_AttrBaseSecond, AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseElite#attr_elite.parry;
get_attr_by_type(Unit, ?CONST_PLAYER_ATTR_E_RESIST) ->
	{_AttrBase,	_AttrBaseSecond, AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	AttrBaseElite#attr_elite.resist;
get_attr_by_type(_Unit, _Other) ->
	0.

%% 【实现】设置出手(单位不出手) CONST_AI_TYPE_SET_NO_ATTACK
set_no_attack(Battle, _Side, _Value, []) -> Battle;
set_no_attack(Battle, Side, Value, [#unit{idx = Idx} = _Unit|UnitList]) ->
	Key = {Side, Idx},
	Seq2 = lists:keydelete(Key, #operate.key, Battle#battle.seq),
	Battle2 = Battle#battle{seq = Seq2},
	set_no_attack(Battle2, Side, Value, UnitList);
set_no_attack(Battle, Side, Value, [_Unit|UnitList]) ->
	set_no_attack(Battle, Side, Value, UnitList).

%% 【实现】设置出手顺序(立即出手) CONST_AI_TYPE_SET_ATTACK_NOW
set_attack_now(Battle, _Side, []) -> Battle;
set_attack_now(Battle, Side, [#unit{idx = Idx} = Unit|UnitList]) ->
	Key = {Side, Idx},
	Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
	SkillIdx    = 0,
	Skill		= Unit#unit.normal_skill,
	RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
	OldFirstSeq = Battle#battle.first_seq,
	Battle2 	= Battle#battle{first_seq = [RecOperate|OldFirstSeq]},
	set_attack_now(Battle2, Side, UnitList);
set_attack_now(Battle, Side, [_Unit|UnitList]) ->
	set_attack_now(Battle, Side, UnitList).

%% set_forbid_dodge(Battle, _Side, []) -> Battle;
%% set_forbid_dodge(Battle, Side, [Unit|UnitList]) ->
%% 	Unit2		= Unit#unit{forbid_dodge = ?true},
%% 	Battle2		= battle_mod_misc:set_unit(Battle, Side, Unit2),
%% 	set_forbid_dodge(Battle2, Side, UnitList).

%% 左边根据id 右边根据idx获取战斗单位
get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, Id) ->
	get_unit_left(Battle, Id);
get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Idx) ->
	Unit = battle_mod_misc:get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Idx),
	{?ok, Unit}.

get_unit_left(Battle, Id) ->
	Units = Battle#battle.units_left,
	UnitsTuple = Units#units.units,
	get_unit_ext(UnitsTuple, 1, Id).

get_unit_ext(Units, Idx, Id) when Idx =< 9 ->
	case erlang:element(Idx, Units) of
		Unit when is_record(Unit, unit)  ->
			case check_unit(Unit, Id) of
				?true ->
					{?ok, Unit};
				?false ->
					get_unit_ext(Units, Idx + 1, Id)
			end;
		_ ->
			get_unit_ext(Units, Idx + 1, Id)
	end;
get_unit_ext(_Units, _Idx, _Id) ->
	{?error, ?TIP_COMMON_BAD_ARG}.
	
check_unit(#unit{type = ?CONST_SYS_PLAYER} = _Unit, Id) ->
	if Id =:= 0 -> ?true;
	   ?true ->   ?false
	end;
check_unit(#unit{type = ?CONST_SYS_PARTNER} = Unit, Id) ->
	UnitExt = Unit#unit.unit_ext,
	if is_record(UnitExt, unit_ext_partner) andalso UnitExt#unit_ext_partner.partner_id =:= Id ->
			?true;
		?true -> ?false
	end;
check_unit(#unit{type = ?CONST_SYS_MONSTER} = Unit, Id) ->
	UnitExt = Unit#unit.unit_ext,
	if is_record(UnitExt, unit_ext_monster) andalso UnitExt#unit_ext_monster.monster_id =:= Id ->
			?true;
		?true -> ?false
	end.		
	
%% 检查剩余人数
check_live_num(Units, Value) ->
	UnitsList = misc:to_list(Units#units.units),
	LiveNum = stat_live_num(UnitsList, 0),
	LiveNum =< Value.
%% 	lists:keymember(?CONST_BATTLE_UNIT_STATE_DEATH, #unit.state, UnitsList).

%% 统计剩余人数
stat_live_num([], AccNum) ->	AccNum;
stat_live_num([#unit{state = State} = _Unit|UnitsList], AccNum) 
  when State =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	NewAccNum = AccNum + 1,
	stat_live_num(UnitsList, NewAccNum);
stat_live_num([_Unit|UnitsList], AccNum) ->
	stat_live_num(UnitsList, AccNum).
	
%% 检查死亡人数
check_dead_num(Units, Value) ->
	UnitsList = misc:to_list(Units#units.units),
	DeadNum = stat_dead_num(UnitsList, 0),
	DeadNum >= Value.

%% 统计剩余人数
stat_dead_num([], AccNum) ->	AccNum;
stat_dead_num([#unit{state = State} = _Unit|UnitsList], AccNum) 
  when State =:= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	NewAccNum = AccNum + 1,
	stat_dead_num(UnitsList, NewAccNum);
stat_dead_num([_Unit|UnitsList], AccNum) ->
	stat_dead_num(UnitsList, AccNum).

%% 车轮战设置出手顺序
round_battle_set_seq(Seq, []) -> Seq;
round_battle_set_seq(Seq, [Operate|OperateList]) ->
	Seq2 = lists:keyreplace(Operate#operate.key, #operate.key, Seq, Operate),
	round_battle_set_seq(Seq2, OperateList).
%% 检查是否有人死亡(已废弃)
%% check_unit_death(Units) ->
%% 	UnitsList = misc:to_list(Units#units.units),
%% 	lists:keymember(?CONST_BATTLE_UNIT_STATE_DEATH, #unit.state, UnitsList).

%% 学习技能
set_skill(Unit, {SkillId, Lv}) ->
	Skill 		= skill_api:battle_skill_for_ai(Unit#unit.pro, 1, SkillId, Lv),
	set_skill(Unit, Skill, 1).
set_skill(Unit, #skill{skill_id = _SkillId} = Skill, Index) when Index =< ?CONST_SKILL_SKILL_BAR_COUNT ->
	ActiveSkill = Unit#unit.active_skill,
	case element(Index, ActiveSkill) of
		Tuple when is_record(Tuple, skill) ->
			set_skill(Unit, Skill, Index + 1);
		_ ->
			NewActiveSkill = setelement(Index, ActiveSkill, Skill),
			Unit#unit{active_skill = NewActiveSkill}
	end;
set_skill(Unit, _Skill, _Index) -> Unit. 

set_skill_ext(Battle, Side, Unit) ->
	Key			= battle_mod_misc:key(Side, Unit#unit.idx),
	Seq			= Battle#battle.seq,
	case lists:keyfind(Key, #operate.key, Seq) of
		RecOperate when is_record(RecOperate, operate) ->
			NormalSkill	= Unit#unit.normal_skill,
			RecOperate2 = RecOperate#operate{key = Key, skill_idx = 0, skill = NormalSkill},
			Seq2		= lists:keyreplace(Key, #operate.key, Seq, RecOperate2),
			Battle#battle{seq = Seq2, operate = []};
		_ ->
			Battle#battle{operate = []}
	end.

%% 初始加入助阵武将ai
partner_help_join(Battle, _Side, [], AddList) -> {Battle, AddList};
partner_help_join(Battle, Side, [{Id, 0}|IdList], AddList) ->
	%% idx为0自己找空位加入
	Units 		= get_side_units(Battle, Side),
	UnitsTuple  = Units#units.units,
	{NewAddList, UnitsTuple2, RecOperate} =
		case get_empty(UnitsTuple, Side, 1) of
			{?ok, Idx} ->
				partner_help_join_ext(Battle, Side, Id, Idx, UnitsTuple, AddList);
			{?error, _ErrorCode} ->
				{AddList, UnitsTuple,[]}
		end,
	NewUnits 	= Units#units{units = UnitsTuple2},
	OldSeq		= Battle#battle.seq,
	NewSeq		= [RecOperate|lists:reverse(OldSeq)],
    Battle2  	= 
		case Side of
			?CONST_BATTLE_UNITS_SIDE_LEFT ->
				Battle#battle{units_left = NewUnits, seq = lists:reverse(NewSeq)};
			?CONST_BATTLE_UNITS_SIDE_RIGHT ->
				Battle#battle{units_right = NewUnits, seq = lists:reverse(NewSeq)};
			_ ->
				Battle
		end,
	partner_help_join(Battle2, Side, IdList, NewAddList);
partner_help_join(Battle, Side, [{Id, Idx}|JoinList], AddList) ->
	%% idx非0指定位置加入
	Units 		= get_side_units(Battle, Side),
	TempUnitsTuple  = Units#units.units,
	UnitsTuple	= 
		case Side of
			?CONST_BATTLE_UNITS_SIDE_RIGHT ->
				clear_dead_unit(misc:to_list(TempUnitsTuple), []);
			_ ->
				TempUnitsTuple
		end,
	case element(Idx, UnitsTuple) of
		Unit when is_record(Unit, unit) ->
			NewJoinList	= [{Id, 0}|JoinList],
			partner_help_join(Battle, Side, NewJoinList, AddList);
		_ ->
			{NewAddList, UnitsTuple2, RecOperate} = partner_help_join_ext(Battle, Side, Id, Idx, UnitsTuple, AddList),
			NewUnits 	= Units#units{units = UnitsTuple2},
			OldSeq		= Battle#battle.seq,
		 	NewSeq		= [RecOperate|lists:reverse(OldSeq)],
			Battle2  	= 
				case Side of
					?CONST_BATTLE_UNITS_SIDE_LEFT ->
						Battle#battle{units_left = NewUnits, seq = lists:reverse(NewSeq)};
					?CONST_BATTLE_UNITS_SIDE_RIGHT ->
						Battle#battle{units_right = NewUnits, seq = lists:reverse(NewSeq)};
					_ ->
						Battle
				end,
			partner_help_join(Battle2, Side, JoinList, NewAddList)
	end.

partner_help_join_ext(Battle, Side, Id, Idx, UnitsTuple, AddList) ->
	case monster_api:monster(Id) of
		Monster when is_record(Monster, monster) ->  
			{?ok, PlayerUnit}	= get_unit(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT, 0),
			Lv			= PlayerUnit#unit.lv,
			Param		= Battle#battle.param,
			Unit		= record_unit(Lv, Monster, Idx, Param),
			Key = {Side, Unit#unit.idx},
			Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
			SkillIdx    = 0,
			Skill		= Unit#unit.normal_skill,
			RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
			NewAddList  = [Unit|AddList],
			UnitsTuple2 = setelement(Idx, UnitsTuple, Unit),
			{NewAddList, UnitsTuple2, RecOperate};
		_ ->
			{AddList, UnitsTuple, []}
	end.

record_unit(Lv, Monster, Idx, Param) when is_record(Monster, monster) ->
	Type		= ?CONST_SYS_MONSTER,
	Anger		= Param#param.init_anger,
	UnitExt		= record_unit_ext_monster(Monster),
	Pro			= Monster#monster.pro,
	Attr		= Monster#monster.attr,
	NewAttr		= convert_attr(Attr, Pro, Lv),
	Power 		= player_attr_api:caculate_power(NewAttr),
	Hp			= (NewAttr#attr.attr_second)#attr_second.hp_max,
	#unit{
		  type				= Type,												%% 战斗单元：1--玩家|2--武将|10--怪物
		  idx				= Idx,						            			%% 阵型中的位置索引
		  state				= ?CONST_BATTLE_UNIT_STATE_NORMAL,					%% 战斗状态
		  hp				= Hp,		            							%% 当前生命
		  pro				= Pro, 												%% 职业
		  power				= Power,											%% 战力
		  lv				= Lv,												%% 等级
		  anger				= Anger,							      			%% 怒气值
		  anger_max			= ?CONST_BATTLE_ANGER_MAX_MONSTER,					%% 怒气值上限
		  attr				= NewAttr,											%% 属性
		  attr_base			= NewAttr,		           				 			%% 基础属性(初始值)
		  attr_ext			= ?null,											%% 附加属性(阵型附加、坐骑技能附加)
		  normal_skill		= Monster#monster.normal_skill,						%% 普通技能
		  active_skill		= Monster#monster.skill,	           				%% 主动技能
		  genius_skill		= Monster#monster.genus_skill, 						%% 天赋技能(被动技能)
		  buff				= [],						            			%% Buff
		  buff_ext			= [],												%% 战斗外部BUFF列表
		  resist			= ?false,											%% 是否必然反击标示[?true:必然反击|?false:非必然反击]
		  unit_ext			= UnitExt 					           				%% 战斗单元扩展
		 }.

record_unit_ext_monster(Monster) ->
	#unit_ext_monster{
					  monster_id		= Monster#monster.monster_id,	%% 怪物ID
					  monster_unique_id	= Monster#monster.id,			%% 怪物唯一ID
					  immune_buffs		= Monster#monster.immune_buffs	%% 免疫BUFF列表
					 }.

convert_attr(Attr, Pro, Lv) ->
	{ForceRate, FateRate, MagicRate}		= data_player:get_player_pro_rate(Pro),
	HelpRate		= data_partner:get_help_rate(Lv),
	AttrSecond		= Attr#attr.attr_second,
	#attr_second{
				 force_attack = ForceAttack,
				 force_def	  = ForceDef,
				 hp_max		  = HpMax,
				 magic_attack = MagicAttack,
				 magic_def    = MagicDef,
				 speed		  = Speed
				}		= AttrSecond,
	NewAttrSecond	=
					#attr_second{force_attack  	= misc:floor(HelpRate * ForceRate/10000 * ForceAttack/10000 * 4),
							   force_def	  	= misc:floor(HelpRate * FateRate/10000 * ForceDef/10000 * 4),
							   magic_attack  	= misc:floor(HelpRate * MagicRate/10000 * MagicAttack/10000 * 4),
							   magic_def		= misc:floor(HelpRate * FateRate/10000 * MagicDef/10000 * 4),
							   hp_max		  	= misc:floor(HelpRate * FateRate/10000 * HpMax/10000 * 30),
							   speed		 	= misc:floor(HelpRate * (ForceRate + MagicRate)/10000 * Speed/10000 * 6)
							  },
	Attr#attr{attr_second = NewAttrSecond}.

	
%%
%% Local Functions
%%