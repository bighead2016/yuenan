%% Author: Administrator
%% Created: 2012-7-27
%% Description: TODO: Add description to pratice_data_generator
-module(practice_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").

-include("../../include/record.base.data.hrl").


%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%

%% practice_data_generator:generate().
generate(Ver) -> 
	FunDatas1 = generate_practice(get_practice, Ver),
	misc_app:write_erl_file(data_practice,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1], Ver).

%% generate_practice(FunName)
generate_practice(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/practice/practice.yrl"),
	generate_practice(FunName, Datas, []).
generate_practice(FunName, [Data|Datas], Acc) when is_record(Data, rec_practice) ->
	Key		= Data#rec_practice.lv,
	Value	= Data,
	When	= ?null,
	generate_practice(FunName, Datas, [{Key, Value, When}|Acc]);
generate_practice(FunName, [], Acc) -> {FunName, Acc}.




%%
%% Local Functions
%%