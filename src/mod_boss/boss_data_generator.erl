%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to boss_data_generator
-module(boss_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% boss_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_boss_data(get_boss_data, Ver),
	FunDatas2	= generate_boss_id(get_boss_id, Ver),
	FunDatas3	= generate_boss_config(get_boss_config, Ver),
	FunDatas4	= generate_boss_reward_config(get_boss_reward_config, Ver),
	FunDatas5	= generate_boss_hurt_reward(get_boss_hurt_reward, Ver),
	misc_app:write_erl_file(data_boss,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4,
                             FunDatas5], Ver).

%% boss_data_generator:generate_boss_data(get_boss_data).
generate_boss_data(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_data.yrl"),
	generate_boss_data(FunName, Datas, []).
generate_boss_data(FunName, [Data|Datas], Acc) ->
	BossData	= change_boss_data(Data),
	Key 		= BossData#boss_data.key,
	Value 		= BossData,
	When    	= ?null,
	generate_boss_data(FunName, Datas, [{Key, Value, When}|Acc]);
generate_boss_data(FunName, [], Acc) -> {FunName, Acc}.

change_boss_data(#rec_boss_data{id = Id, lv = Lv, map_id = MapId, monsters = Monsters, reward_kill = RewardKill, reward_valiant = RewardValiant,
								reward_damage_gold = RewardDamageGold, reward_damage_meritorious = RewardDamageMeritorious, reward_damage_experience = RewardDamageExperience,
								reward_rank_gold = RewardRankGold, reward_rank_meritorious = RewardRankMeritorious, reward_rank_experience = RewardRankExperience,
								lv_phase = LvPhase}) ->
	#boss_data{
			   room						= 0,                        % 所属房间
			   key						= {Id, LvPhase},			% Key{boss_id, 等级段}
			   id						= Id,						% ID
			   lv						= Lv,						% 等级Lv
			   map_id					= MapId,					% 地图ID
			   monsters					= Monsters,					% 怪物列表
			   reward_kill				= RewardKill,        		% 击杀奖励
			   reward_valiant			= RewardValiant,        	% 英勇奖励
			   reward_damage_gold		= RewardDamageGold,        	% 伤害奖励(金币)
			   reward_damage_meritorious= RewardDamageMeritorious,  % 伤害奖励(功勋)
			   reward_damage_experience	= RewardDamageExperience,   % 伤害奖励(历练)
			   reward_rank_gold			= RewardRankGold,        	% 排名奖励(金币)
			   reward_rank_meritorious	= RewardRankMeritorious,    % 排名奖励(功勋)
			   reward_rank_experience	= RewardRankExperience,     % 排名奖励(历练)
			   
			   state					= 0,						% 状态
			   time_start				= 0 						% 开始时间戳
			  };
change_boss_data(Data) ->
	?MSG_ERROR("Data:~p~n", [Data]).
	
%% boss_data_generator:generate_boss_id(get_boss_id).
generate_boss_id(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_data.yrl"),
	generate_boss_id_2(FunName, Datas).
generate_boss_id_2(FunName, Datas) ->
    Key     	= ?null,
	Value 		= get_boss_id(Datas, []),
	When    	= ?null,
	{FunName, [{Key, Value, When}]}.

get_boss_id([#rec_boss_data{id = Id}|Datas], Acc) ->
	case lists:member(Id, Acc) of
		?true -> get_boss_id(Datas, Acc);
		?false -> get_boss_id(Datas, [Id|Acc])
	end;
get_boss_id([], Acc) -> Acc.



generate_boss_config(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_config.yrl"),
	generate_boss_config(FunName, [Datas], []).
generate_boss_config(FunName, [Data|Datas], Acc) ->
	Key     	= ?null,
	Value 		= Data,
	When    	= ?null,
	generate_boss_config(FunName, Datas, [{Key, Value, When}|Acc]);
generate_boss_config(FunName, [], Acc) -> {FunName, Acc}.


generate_boss_reward_config(FunName, Ver) ->
	Datas 		= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_reward_config.yrl"),
	generate_boss_reward_config(FunName, Datas, []).
generate_boss_reward_config(FunName, [Data|Datas], Acc) ->
	Key 		= "N",
	Value 		= Data,
	When    	= "N >= " ++ integer_to_list(Data#rec_boss_reward_config.head) ++
				  " andalso " ++
			      "N =< " ++ integer_to_list(Data#rec_boss_reward_config.tail),
	generate_boss_reward_config(FunName, Datas, [{Key, Value, When}|Acc]);
generate_boss_reward_config(FunName, [], Acc) -> {FunName, Acc}.

%% 伤害奖励
generate_boss_hurt_reward(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_hurt_reward.yrl"),
    Datas2      = lists:reverse(Datas),
    generate_boss_hurt_reward(FunName, Datas2, []).
generate_boss_hurt_reward(FunName, [Data|Datas], Acc) when is_record(Data, rec_boss_hurt_reward) ->
    Key         = "N",
    Value       = Data,
    When        = handle_hurt_when(Data),
    generate_boss_hurt_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_boss_hurt_reward(FunName, [], Acc) -> {FunName, Acc}.

%% 伤害奖励
generate_boss_hurt_step(FunName, Ver) ->
    Datas       = misc:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/boss/boss_hurt_reward.yrl"),
    Datas2      = lists:reverse(Datas),
    generate_boss_hurt_step(FunName, Datas2, []).
generate_boss_hurt_step(FunName, [Data|Datas], Acc) when is_record(Data, rec_boss_hurt_reward) ->
    Key         = ?null,
    Value       = [{D#rec_boss_hurt_reward.hurt_from, D#rec_boss_hurt_reward.hurt_to}||D<-Data],
    When        = ?null,
    generate_boss_hurt_step(FunName, Datas, [{Key, Value, When}|Acc]);
generate_boss_hurt_step(FunName, [], Acc) -> {FunName, Acc}.



%%
%% Local Functions
%%
handle_hurt_when(#rec_boss_hurt_reward{hurt_from = HurtFrom, hurt_to = 0}) ->
    misc:to_list(HurtFrom) ++ " =< N "; 
handle_hurt_when(#rec_boss_hurt_reward{hurt_from = HurtFrom, hurt_to = HurtTo}) ->
    " N > " ++ misc:to_list(HurtFrom) 
        ++ " andalso "
        ++ misc:to_list(HurtTo) ++ " >= N ".