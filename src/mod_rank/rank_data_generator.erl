%% Author: Administrator
%% Created: 2012-8-6
%% Description: TODO: Add description to rank_data_generator
-module(rank_data_generator).


%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.base.data.hrl").


%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%

%% rank_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_rank_reward(rank_reward, Ver),
	FunDatas2 = generate_rank_explain(rank_explain, Ver),
	misc_app:write_erl_file(data_rank,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1,FunDatas2], Ver).





%% generate_rank_score(FunName)
generate_rank_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/rank/rank_reward.yrl"),
	generate_rank_reward(FunName, Datas, []).
generate_rank_reward(FunName, [Data|Datas], Acc) when is_record(Data, rec_rank_reward) -> 
	When	= ?null,
	List	= [
			   {{Data#rec_rank_reward.level,?CONST_RANK_LV,?CONST_RANK_ONE},Data#rec_rank_reward.lv_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_LV,?CONST_RANK_TWO},Data#rec_rank_reward.lv_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_LV,?CONST_RANK_THREE},Data#rec_rank_reward.lv_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_POSITION,?CONST_RANK_ONE},Data#rec_rank_reward.pos_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_POSITION,?CONST_RANK_TWO},Data#rec_rank_reward.pos_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_POSITION,?CONST_RANK_THREE},Data#rec_rank_reward.pos_3,When},
			   
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_VIP,?CONST_RANK_ONE},Data#rec_rank_reward.vip_1,When},
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_VIP,?CONST_RANK_TWO},Data#rec_rank_reward.vip_2,When},
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_VIP,?CONST_RANK_THREE},Data#rec_rank_reward.vip_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_POWER,?CONST_RANK_ONE},Data#rec_rank_reward.power_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_POWER,?CONST_RANK_TWO},Data#rec_rank_reward.power_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_POWER,?CONST_RANK_THREE},Data#rec_rank_reward.power_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_EQUIP_POWER,?CONST_RANK_ONE},Data#rec_rank_reward.equip_power_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_EQUIP_POWER,?CONST_RANK_TWO},Data#rec_rank_reward.equip_power_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_EQUIP_POWER,?CONST_RANK_THREE},Data#rec_rank_reward.equip_power_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_PARTNER,?CONST_RANK_ONE},Data#rec_rank_reward.partner_power_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_PARTNER,?CONST_RANK_TWO},Data#rec_rank_reward.partner_power_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_PARTNER,?CONST_RANK_THREE},Data#rec_rank_reward.partner_power_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD,?CONST_RANK_ONE},Data#rec_rank_reward.guild_lv_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD,?CONST_RANK_TWO},Data#rec_rank_reward.guild_lv_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD,?CONST_RANK_THREE},Data#rec_rank_reward.guild_lv_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD_POWER,?CONST_RANK_ONE},Data#rec_rank_reward.guild_power_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD_POWER,?CONST_RANK_TWO},Data#rec_rank_reward.guild_power_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_GUILD_POWER,?CONST_RANK_THREE},Data#rec_rank_reward.guild_power_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_COPY,?CONST_RANK_ONE},Data#rec_rank_reward.copy_general_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_COPY,?CONST_RANK_TWO},Data#rec_rank_reward.copy_general_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_COPY,?CONST_RANK_THREE},Data#rec_rank_reward.copy_general_3,When},
			   
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_ELITECOPY,?CONST_RANK_ONE},Data#rec_rank_reward.copy_elite_1,When},
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_ELITECOPY,?CONST_RANK_TWO},Data#rec_rank_reward.copy_elite_2,When},
%% 			   {{Data#rec_rank_reward.level,?CONST_RANK_ELITECOPY,?CONST_RANK_THREE},Data#rec_rank_reward.copy_elite_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_DEVILCOPY,?CONST_RANK_ONE},Data#rec_rank_reward.copy_devil_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_DEVILCOPY,?CONST_RANK_TWO},Data#rec_rank_reward.copy_devil_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_DEVILCOPY,?CONST_RANK_THREE},Data#rec_rank_reward.copy_devil_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_SINGLE_ARENA,?CONST_RANK_ONE},Data#rec_rank_reward.arena_single_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_SINGLE_ARENA,?CONST_RANK_TWO},Data#rec_rank_reward.arena_single_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_SINGLE_ARENA,?CONST_RANK_THREE},Data#rec_rank_reward.arena_single_3,When},
			   
			   {{Data#rec_rank_reward.level,?CONST_RANK_ARENA,?CONST_RANK_ONE},Data#rec_rank_reward.arena_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_ARENA,?CONST_RANK_TWO},Data#rec_rank_reward.arena_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_ARENA,?CONST_RANK_THREE},Data#rec_rank_reward.arena_3,When},
              
			   {{Data#rec_rank_reward.level,?CONST_RANK_HORSE,?CONST_RANK_ONE},Data#rec_rank_reward.horse_1,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_HORSE,?CONST_RANK_TWO},Data#rec_rank_reward.horse_2,When},
			   {{Data#rec_rank_reward.level,?CONST_RANK_HORSE,?CONST_RANK_THREE},Data#rec_rank_reward.horse_3,When}
			  ],
	generate_rank_reward(FunName, Datas, List ++ Acc);
generate_rank_reward(FunName, [], Acc) -> {FunName, Acc}.

%% 
generate_rank_explain(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/rank/rank.explain.yrl"),
	generate_rank_explain(FunName, Datas, []).
generate_rank_explain(FunName, [Data|Datas], Acc) when is_record(Data, rec_rank_explain) ->
	Key     = {Data#rec_rank_explain.type,Data#rec_rank_explain.rank},
	Value   = Data,
	When	= ?null,
	generate_rank_explain(FunName, Datas, [{Key, Value, When}|Acc]);
generate_rank_explain(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%

