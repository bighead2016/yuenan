%% Author: Administrator
%% Created: 2012-8-23
%% Description: TODO: Add description to spring_data_generator
-module(spring_data_generator).

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

%% spring_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_spring_init(get_spring_init, Ver),
%% 	FunDatas2 = generate_spring_vip_init(get_spring_vip_init),
	misc_app:write_erl_file(data_spring,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1], Ver).

%% generate_spring_init(FunName) 
generate_spring_init(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/spring/spring.yrl"),
	generate_spring_init(FunName, Datas, []).
generate_spring_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_spring) ->
	Key		= Data#rec_spring.lv,
	Value	= Data,
	When	= ?null,
	generate_spring_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_spring_init(FunName, [], Acc) -> {FunName, Acc}.

%% generate_spring_vip_init(FunName)
%% generate_spring_vip_init(FunName) ->
%% 	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ "/spring/spring.vip.yrl"),
%% 	generate_spring_vip_init(FunName, Datas, []).
%% generate_spring_vip_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_spring_vip) ->
%% 	Key		= Data#rec_spring_vip.lv,
%% 	Value	= Data,
%% 	When	= ?null,
%% 	generate_spring_vip_init(FunName, Datas, [{Key, Value, When}|Acc]);
%% generate_spring_vip_init(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%

