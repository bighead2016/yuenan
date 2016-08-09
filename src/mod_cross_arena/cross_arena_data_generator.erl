%% Author: Administrator
%% Created: 2013-12-21
%% Description: TODO: Add description to player_data_generator
-module(cross_arena_data_generator).

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
%% cross_arena_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_cross_arena_achieve(get_cross_arena_achieve, Ver),
	FunDatas2 = generate_cross_arena_achieve_list(get_cross_arena_achieve_list, Ver),
	FunDatas3 = generate_cross_arena_reward(get_cross_arena_reward, Ver),
	FunDatas4 = generate_robot_list(get_robot_list, Ver),
	FunDatas5 = generate_score_shop(get_score_shop, Ver),
	misc_app:write_erl_file(data_cross_arena,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5
                             ], Ver).

%% 
generate_cross_arena_achieve(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_achieve.yrl"),
	generate_cross_arena_achieve(FunName, Datas, []).
generate_cross_arena_achieve(FunName, [Data|Datas], Acc)  ->
	Key		= Data#rec_cross_arena_achieve.phase,
	Value	= Data,
	When    = ?null,
	generate_cross_arena_achieve(FunName, Datas, [{Key, Value, When}|Acc]);
generate_cross_arena_achieve(FunName, [], Acc) -> {FunName, Acc}.

generate_cross_arena_achieve_list(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_achieve.yrl"),
	generate_cross_arena_achieve_list(FunName, Datas, [], Ver).
generate_cross_arena_achieve_list(FunName, [Data|Datas], Acc, Ver)  ->
	AllList = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_achieve.yrl"),
	Key		= Data#rec_cross_arena_achieve.phase,
	Value	= [X#rec_cross_arena_achieve.phase || X <- AllList, X#rec_cross_arena_achieve.phase >= Key],
	When    = ?null,
	generate_cross_arena_achieve_list(FunName, Datas, [{Key, Value, When}|Acc], Ver);
generate_cross_arena_achieve_list(FunName, [], Acc, _Ver) -> {FunName, Acc}.

generate_cross_arena_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_reward.yrl"),
	generate_cross_arena_reward(FunName, Datas, []).
generate_cross_arena_reward(FunName, [Data|Datas], Acc) ->
	Key		= {Data#rec_cross_arena_reward.type, Data#rec_cross_arena_reward.phase, Data#rec_cross_arena_reward.count},
	Value	= Data,
	When    = ?null,
	generate_cross_arena_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_cross_arena_reward(FunName, [], Acc) -> {FunName, Acc}.


%% 
%% 
generate_robot_list(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_robot.yrl"),
    generate_robot_list_2(FunName, Datas).
generate_robot_list_2(FunName, Datas)  ->
    Key     = ?null,
    Value   = [{Id, Sex, PartnerList}||#rec_cross_arena_robot{robot_id = Id, sex = Sex, partner_list = PartnerList}<-Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

%% 一骑讨积分商店
generate_score_shop(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/cross_arena/cross_arena_shop.yrl"),
    generate_score_shop(FunName, Datas, []).
generate_score_shop(FunName, [Data|Datas], Acc)  ->
    Key     = Data#rec_cross_arena_shop.id,
    Value   = Data,
    When    = ?null,
    generate_score_shop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_score_shop(FunName, [], Acc) -> {FunName, Acc}.
%% 
%% %% 一骑讨排名积分
%% generate_score_score(FunName) ->
%%     Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "cross_arena/cross_arena_score.yrl"),
%%     generate_score_score(FunName, Datas, []).
%% generate_score_score(FunName, [Data|Datas], Acc)  ->
%%     Key     = Data#rec_cross_arena_score.idx,
%%     Value   = Data,
%%     When    = ?null,
%%     generate_score_score(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_score_score(FunName, [], Acc) -> {FunName, Acc}.


%%
%% Local Functions
%%