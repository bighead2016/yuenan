%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(single_arena_data_generator).

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
%% single_arena_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_single_arena_reward(get_base_single_arena_reward, Ver),
	FunDatas2 = generate_single_arena_rank_interval(get_base_single_arena_rank_interval, Ver),
	FunDatas3 = generate_single_arena_rank_show(get_base_single_arena_rank_show, Ver),
	FunDatas4 = generate_robot_list(get_robot_list, Ver),
	FunDatas5 = generate_score_shop(get_score_shop, Ver),
	FunDatas6 = generate_score_score(get_score_score, Ver),
	misc_app:write_erl_file(data_single_arena,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3,
                             FunDatas4, FunDatas5, FunDatas6], Ver).

generate_single_arena_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena.arena_reward.yrl"),
	generate_single_arena_reward(FunName, Datas, []).
generate_single_arena_reward(FunName, [Data|Datas], Acc) ->
	Key		= {Data#rec_arena_reward.lv, Data#rec_arena_reward.type},
	Value	= Data,
	When    = ?null,
	generate_single_arena_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_single_arena_reward(FunName, [], Acc) -> {FunName, Acc}.


%% single_arena_data_generator:generate_single_arena_rank_show(get_player_init).
generate_single_arena_rank_show(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena.arena_rank_show.yrl"),
	generate_single_arena_rank_show(FunName, Datas, []).
generate_single_arena_rank_show(FunName, [Data|Datas], Acc)  ->
	Key		= Data#rec_arena_rank_show.id,
	Value	= Data,
	When    = ?null,
	generate_single_arena_rank_show(FunName, Datas, [{Key, Value, When}|Acc]);
generate_single_arena_rank_show(FunName, [], Acc) -> {FunName, Acc}.

%% 
generate_single_arena_rank_interval(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena.arena_rank_interval.yrl"),
	generate_single_arena_rank_interval(FunName, Datas, []).
generate_single_arena_rank_interval(FunName, [Data|Datas], Acc)  ->
	Key		= Data#rec_arena_rank_interval.id,
	Value	= Data,
	When    = ?null,
	generate_single_arena_rank_interval(FunName, Datas, [{Key, Value, When}|Acc]);
generate_single_arena_rank_interval(FunName, [], Acc) -> {FunName, Acc}.

%% 
generate_robot_list(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena_robot.yrl"),
    generate_robot_list_2(FunName, Datas).
generate_robot_list_2(FunName, Datas)  ->
    Key     = ?null,
    Value   = [{Id, Sex}||#rec_single_arena_robot{robot_id = Id, sex = Sex}<-Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 一骑讨积分商店
generate_score_shop(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena_shop.yrl"),
    generate_score_shop(FunName, Datas, []).
generate_score_shop(FunName, [Data|Datas], Acc)  ->
    Key     = Data#rec_single_arena_shop.id,
    Value   = Data,
    When    = ?null,
    generate_score_shop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_score_shop(FunName, [], Acc) -> {FunName, Acc}.

%% 一骑讨排名积分
generate_score_score(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/single_arena/single_arena_score.yrl"),
    generate_score_score(FunName, Datas, []).
generate_score_score(FunName, [Data|Datas], Acc)  ->
    Key     = Data#rec_single_arena_score.idx,
    Value   = Data,
    When    = ?null,
    generate_score_score(FunName, Datas, [{Key, Value, When}|Acc]);
generate_score_score(FunName, [], Acc) -> {FunName, Acc}.


%%
%% Local Functions
%%