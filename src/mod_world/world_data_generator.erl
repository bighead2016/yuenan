%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to world_data_generator
-module(world_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% world_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_world_config(get_world_config, Ver),
	FunDatas2	= generate_world_monster(get_world_monster, Ver),
	FunDatas3	= generate_world_monster_steps(get_world_monster_steps, Ver),
	FunDatas4	= generate_world_buff_list(get_world_buff_list, Ver),
	FunDatas5	= generate_world_buff(get_world_buff, Ver),
	misc_app:write_erl_file(data_world,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5], Ver).


generate_world_config(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/world/world_config.yrl"),
	generate_world_config(FunName, [Datas], []).
generate_world_config(FunName, [Data|Datas], Acc) ->
	Key     	= ?null,
	Value 		= Data,
	When    	= ?null,
	generate_world_config(FunName, Datas, [{Key, Value, When}|Acc]);
generate_world_config(FunName, [], Acc) -> {FunName, Acc}.


generate_world_monster(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/world/world_monster.yrl"),
	generate_world_monster(FunName, Datas, []).

generate_world_monster(FunName, [Data|Datas], Acc) ->
	Key     	= Data#rec_world_monster.index,
	Value		= record_world_monsters(Data),
	When    	= ?null,
	generate_world_monster(FunName, Datas, [{Key, Value, When}|Acc]);
generate_world_monster(FunName, [], Acc) -> {FunName, Acc}.

generate_world_monster_steps(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/world/world_monster.yrl"),
	Key     	= ?null,
	Value 		= length(Datas),
	When    	= ?null,
	{FunName, [{Key, Value, When}]}.

generate_world_buff_list(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/world/world_buff.yrl"),
	generate_world_buff_list(FunName, Datas, Datas, []).
generate_world_buff_list(FunName, [Data|Datas], AllDatas, Acc) ->
	Key 		= "Hurt",
	Value 		= [X#rec_world_buff.id || X <- AllDatas, Data#rec_world_buff.hurt >= X#rec_world_buff.hurt],
	When    	= "Hurt >= " ++ integer_to_list(Data#rec_world_buff.hurt),
	generate_world_buff_list(FunName, Datas, AllDatas, [{Key, Value, When}|Acc]);
generate_world_buff_list(FunName, [], _AllDatas, Acc) -> {FunName, Acc}.

generate_world_buff(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/world/world_buff.yrl"),
	generate_world_buff(FunName, Datas, []).
generate_world_buff(FunName, [Data|Datas], Acc) ->
	Key 		= Data#rec_world_buff.id,
	Value 		= Data,
	When    	= ?null,
	generate_world_buff(FunName, Datas, [{Key, Value, When}|Acc]);
generate_world_buff(FunName, [], Acc) -> {FunName, Acc}.
%%
%% Local Functions
%%


record_world_monsters(RecWorldMonster) ->
	RewardExp	= RecWorldMonster#rec_world_monster.reward_exp,
	RewardGoods	= RecWorldMonster#rec_world_monster.reward_goods,
	Monsters	= world_monsters(RecWorldMonster),
	#world_monsters{
					reward_exp		= RewardExp,		% 奖励经验
					reward_goods	= RewardGoods,		% 奖励物品
					monsters		= Monsters			% 怪物列表
				   }.

world_monsters(RecWorldMonster) ->
	WorldMonster	= record_world_monster(RecWorldMonster),
	lists:duplicate(RecWorldMonster#rec_world_monster.count, WorldMonster).

record_world_monster(RecWorldMonster) ->
	MonsterId				= RecWorldMonster#rec_world_monster.monster_id,
	RewardGold				= RecWorldMonster#rec_world_monster.reward_gold,
	{?ok, HpMax, HpTuple}	= get_monster_group_hp(MonsterId),
	#world_monster{
				   monster_id		= MonsterId,		% 怪物ID
				   reward_gold		= RewardGold,		% 击杀奖(铜钱)
				   hp				= HpMax,			% 怪物当前总生命
				   hp_max 			= HpMax,			% 怪物总生命上限
				   hp_tuple			= HpTuple, 			% 怪物组血量
				   death 			= ?false			% 怪物是否死亡标示
				  }.

%% 获取怪物组生命总和
get_monster_group_hp(MonsterId) ->
	Monster		= data_monster:get_monster(MonsterId),
	Camp		= Monster#monster.camp,
	HpTupleTemp	= erlang:make_tuple(tuple_size(Camp#camp.position), 0, []),
	HpTuple		= get_monster_group_hp(misc:to_list(Camp#camp.position), HpTupleTemp),
	HpMax		= lists:sum(misc:to_list(HpTuple)),
	{?ok, HpMax, HpTuple}.

get_monster_group_hp([#camp_pos{idx = Idx, id = MonsterId}|Position], HpTuple) ->
	Monster		= data_monster:get_monster(MonsterId),
	HpTuple2	= setelement(Idx, HpTuple, Monster#monster.hp),
	get_monster_group_hp(Position, HpTuple2);
get_monster_group_hp([_|Position], HpTuple) ->
	get_monster_group_hp(Position, HpTuple);
get_monster_group_hp([], HpTuple) -> HpTuple.






