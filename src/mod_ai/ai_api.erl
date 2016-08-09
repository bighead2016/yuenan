%% Author: Administrator
%% Created: 2012-11-12
%% Description: TODO: Add description to ai_api
-module(ai_api).

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
-export([trigger_ai/2, refresh_seq/1, set_battle_on/2, get_ai_packet/1]).

-export([msg_ai_talk/2, 
		 msg_ai_join/3, 
		 msg_ai_quit/3, 
		 msg_ai_round/2, 
		 msg_ai_hp_anger_change/3, 
		 msg_ai_attr_change/3]).


%%
%% API Functions
%% 初始化战斗触发ai
trigger_ai(Battle, Trigger) ->
	Battle2 = init_ai(Battle),
	ai_mod:trigger_ai(Battle2, Trigger).

%% 初始化ai 所有有ai的战斗都禁止闪避和格挡
init_ai(Battle) ->
	AiList = (Battle#battle.param)#param.ai_list,
	case AiList of
		[] ->	%% 无ai的战斗
			Battle;
		_Other -> %% 有ai的战斗
			Battle#battle{forbid_dodge = ?true, forbid_parry = ?true}
	end.

%% 刷新出手顺序
refresh_seq(Battle) ->
	OldSeq = Battle#battle.seq,
%% 	?MSG_DEBUG("refresh_seq_ai1:~p~n",[{OldSeq,Battle#battle.first_seq}]),
	case Battle#battle.first_seq of
		[] ->
			Battle;
		[Operate|OperateList] ->
			Key = Operate#operate.key,
			case lists:keytake(Key, #operate.key, OldSeq) of
				{value, Operate1, Seq2} ->
					NewSeq = [Operate1|Seq2],
%% 					?MSG_DEBUG("refresh_seq_ai2:~p~n",[{Battle#battle.seq,NewSeq}]),
					Battle#battle{seq = NewSeq, first_seq = OperateList};
				_Other ->
					NewSeq = [Operate|OldSeq],
%% 					?MSG_DEBUG("refresh_seq_ai3:~p~n",[{Battle#battle.seq,NewSeq}]),
					Battle#battle{seq = NewSeq, first_seq = OperateList}
			end
	end. 

%% 开启战斗
set_battle_on(Player, Sleep) ->
	?MSG_DEBUG("BattlePid:~p, Sleep:~p",[Player#player.battle_pid, Sleep]),
	battle_api:set_battle_sleep(Player#player.battle_pid, Sleep),
	{?ok, Player}.

%% 获取ai_packet
get_ai_packet(Battle) ->
	AiPacket = Battle#battle.ai_packet,
	Battle2  = Battle#battle{ai_packet = <<>>},
	Battle3  = refresh_round(Battle2),
	{Battle3, AiPacket}.

%% 刷新战斗轮数
refresh_round(#battle{round_refresh = ?true} = Battle) ->
	OldRound = Battle#battle.round,
	Battle#battle{bout = 1, round = OldRound + 1};
refresh_round(Battle) -> Battle.

%% 打包说话、动画、特效等前端表现ai
msg_ai_talk(Battle, RecAi) ->
	Datas = [RecAi#rec_ai.id, Battle#battle.bout],
	?MSG_DEBUG("msg_ai_talk:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_START, ?MSG_FORMAT_AI_SC_START, Datas).

%% 打包角色加入ai
msg_ai_join(_Battle, _RecAi, []) -> <<>>;
msg_ai_join(Battle, RecAi, AddList) ->
	Side = RecAi#rec_ai.target_side,
%% 	JoinList = ai_mod:get_target_units(Battle, Side, RecAi),
	Monster = msg_ai_join_ext(Battle, Side, AddList, []),
	Datas = 
		[RecAi#rec_ai.id,
		 Battle#battle.bout,
		 Side,
		 Monster],
	?MSG_DEBUG("msg_ai_join:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_UNIT_JOIN, ?MSG_FORMAT_AI_SC_UNIT_JOIN, Datas). 

msg_ai_join_ext(_Battle, _Side, [], AccDatas) -> AccDatas;
msg_ai_join_ext(Battle, Side, [Unit|UnitList], AccDatas) ->
	NewDatas = 
		case is_record(Unit#unit.unit_ext, unit_ext_monster) of
			?true ->
				Attr		= Unit#unit.attr,
				UnitExt		= Unit#unit.unit_ext,
				Datas		= {
							   Unit#unit.idx,
							   Unit#unit.anger,
							   Unit#unit.anger_max,
							   Unit#unit.hp,
							   (Attr#attr.attr_second)#attr_second.hp_max,
							   UnitExt#unit_ext_monster.monster_id,
                               UnitExt#unit_ext_monster.psoul
							  },
				[Datas|AccDatas];
			?false ->
				AccDatas
		end,
	msg_ai_join_ext(Battle, Side, UnitList, NewDatas).
	
%% 打包角色离开ai
msg_ai_quit(_Battle, _RecAi, []) -> <<>>;
msg_ai_quit(Battle, RecAi, QuitList) ->
	Side = RecAi#rec_ai.target_side,
	Monster = msg_ai_quit_ext(Battle, Side, QuitList, []),
	Datas = 
		[RecAi#rec_ai.id,
		 Battle#battle.bout,
		 Side,
		 Monster],
	?MSG_DEBUG("msg_ai_quit333:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_UNIT_QUIT, ?MSG_FORMAT_AI_SC_UNIT_QUIT, Datas).


msg_ai_quit_ext(_Battle, _Side, [], AccDatas) -> AccDatas;
msg_ai_quit_ext(Battle, Side, [Unit|UnitList], AccDatas) ->
	NewDatas = 
		case is_record(Unit#unit.unit_ext, unit_ext_monster) of
			?true ->
				Datas = {
						 Unit#unit.idx
						},
				[Datas|AccDatas];
			?false ->
				AccDatas
		end,
	msg_ai_quit_ext(Battle, Side, UnitList, NewDatas).
	
msg_ai_round(AiId, Round) ->
	Datas = 
		[
		 AiId,
		 Round
		 ],
	?MSG_DEBUG("msg_ai_round:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_BATTLE_ROUND, ?MSG_FORMAT_AI_SC_BATTLE_ROUND, Datas).

%% 打包怒气生命改变
msg_ai_hp_anger_change(_Battle, _RecAi, []) -> <<>>;
msg_ai_hp_anger_change(Battle, RecAi, ChangeList) ->
	Side 		= RecAi#rec_ai.target_side,
	UnitsData 	= msg_ai_hp_anger_change_ext(Battle, Side, ChangeList, []),
	Datas =
		[
		 RecAi#rec_ai.id,
		 Battle#battle.bout,
		 RecAi#rec_ai.target_side,
		 UnitsData
		 ],
	?MSG_DEBUG("msg_ai_hp_anger_change:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_HP_ANGER_CHANGE, ?MSG_FORMAT_AI_SC_HP_ANGER_CHANGE, Datas).

msg_ai_hp_anger_change_ext(_Battle, _Side, [], AccDatas) -> AccDatas;
msg_ai_hp_anger_change_ext(Battle, Side, [#unit{idx = Idx} = _Unit|UnitList], AccDatas) ->
	NewUnit	= battle_mod_misc:get_unit(Battle, Side, Idx),
	NewDatas = 
		case is_record(NewUnit, unit) of
			?true ->
				Attr  		= NewUnit#unit.attr,
				Datas = {
						 NewUnit#unit.idx,
						 NewUnit#unit.anger,
						 NewUnit#unit.anger_max,
						 NewUnit#unit.hp,
						 (Attr#attr.attr_second)#attr_second.hp_max
						},
				[Datas|AccDatas];
			?false ->
				AccDatas
		end,
	msg_ai_hp_anger_change_ext(Battle, Side, UnitList, NewDatas);
msg_ai_hp_anger_change_ext(Battle, Side, [_Unit|UnitList], AccDatas) -> 
	msg_ai_hp_anger_change_ext(Battle, Side, UnitList, AccDatas).

%% 打包战斗属性改变
msg_ai_attr_change(_Battle, _RecAi, []) -> <<>>;
msg_ai_attr_change(Battle, RecAi, ChangeList) ->
	UnitsData 	= msg_ai_attr_change_ext(RecAi, ChangeList, []),
	Datas =
		[
		 RecAi#rec_ai.id,
		 Battle#battle.bout,
		 RecAi#rec_ai.target_side,
		 UnitsData
		 ],
	?MSG_DEBUG("msg_ai_attr_change:~p~n",[Datas]),
	misc_packet:pack(?MSG_ID_AI_SC_ATTR_CHANGE, ?MSG_FORMAT_AI_SC_ATTR_CHANGE, Datas).

msg_ai_attr_change_ext(_RecAi, [], AccDatas) -> AccDatas;
msg_ai_attr_change_ext(RecAi, [#unit{idx = Idx} = _Unit|UnitList], AccDatas) ->
	?MSG_DEBUG("msg_ai_attr1:~p",[RecAi]),
	ChangeType	= 
		case RecAi#rec_ai.type of
			?CONST_AI_TYPE_PLUS_ATTR ->
				?CONST_BUFF_CHANGE_TYPE_INSERT;
			?CONST_AI_TYPE_MINUS_ATTR ->
				?CONST_BUFF_CHANGE_TYPE_DELETE
		end,
	Datas		= {Idx,
				   ChangeType,
				   RecAi#rec_ai.attr_type,
				   RecAi#rec_ai.value
				   },
	NewDatas 	= [Datas|AccDatas],
	
	msg_ai_attr_change_ext(RecAi, UnitList, NewDatas);
msg_ai_attr_change_ext(RecAi, [_Unit|UnitList], AccDatas) -> 
	msg_ai_attr_change_ext(RecAi, UnitList, AccDatas).
%%
%% Local Functions
%%

