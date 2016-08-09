%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(home_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([]).

%%
%% API Functions
%%
%% home_data_generator:generate().
generate(Ver) ->
	try
		FunDatas1 = generate_base(get_base, Ver),
		FunDatas2 = generate_info(get_home_info, Ver),
		FunDatas5 = generate_task(get_office_task, Ver),
		FunDatas6 = generate_girlskill(get_girl_skill, Ver),
		FunDatas12= generate_girlinfo(get_girlinfo, Ver),
		misc_app:write_erl_file(data_home,
								["../../include/const.common.hrl",
								 "../../include/record.player.hrl",
								 "../../include/record.base.data.hrl",
								 "../../include/record.data.hrl"],
								[FunDatas1, FunDatas2, FunDatas5, FunDatas6, FunDatas12], Ver)
	catch 
		_Type:Error->
			?MSG_ERROR("~p~n~p~n",[Error,erlang:get_stacktrace()])
	end.

%% 生成家园初始数据
generate_base(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/home/home.base.yrl"),
	generate_base(FunName, Datas, []).

generate_base(FunName, [Data|Datas], Acc) when is_record(Data, rec_home_base) ->
	Key		= Data#rec_home_base.home_lv,
	Value	= Data,
	When	= ?null,
	generate_base(FunName, Datas, [{Key, Value, When}|Acc]);
generate_base(FunName, [], Acc) -> {FunName, Acc}.

%% 生成家园引导数据
generate_info(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/home/home.info.yrl"),
	generate_info(FunName, Datas, []).

generate_info(FunName, [Data|Datas], Acc) when is_record(Data, rec_home_info) ->
	Key		= {Data#rec_home_info.home_level, Data#rec_home_info.vip_level},
	Value	= Data,
	When	= ?null,
	generate_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_info(FunName, [], Acc) -> {FunName, Acc}.

%% 生成家园官府任务数据
generate_task(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/home/home_task.yrl"),
	generate_task(FunName, Datas, []).

generate_task(FunName, [Data|Datas], Acc) when is_record(Data, rec_home_task) ->
	Key		= Data#rec_home_task.task_id,
	Value	= change_task_probablity(Data),
	When	= ?null,
	generate_task(FunName, Datas, [{Key, Value, When}|Acc]);
generate_task(FunName, [], Acc) -> {FunName, Acc}.

change_task_probablity(Data) ->
	RefreshList	= Data#rec_home_task.refresh_probablity,
	List 		= [{Color, Probablity} || {Color, Probablity, _} <- RefreshList], 
	{List1, ExpectSum} = misc_random:odds_list_init(?MODULE, ?LINE, List, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	Color1		= misc_random:odds_one(List1, ExpectSum),
	Data#rec_home_task{refresh_probablity = {Color1, RefreshList}}.

%% 生成家园仕女技能数据
generate_girlskill(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/home/home_girl_skill.yrl"),
	generate_girlskill(FunName, Datas, []).
generate_girlskill(FunName, [Data|Datas], Acc) when is_record(Data, rec_home_girl_skill) ->
	Key     = Data#rec_home_girl_skill.skill_id,
	Value   = Data,
	When	= ?null,
	generate_girlskill(FunName, Datas, [{Key, Value, When}|Acc]);
generate_girlskill(FunName, [], Acc) -> {FunName, Acc}.
	
%% 生成家园仕女基本信息
generate_girlinfo(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/home/home.girl.info.yrl"),
	generate_girlinfo(FunName, Datas, []).
generate_girlinfo(FunName, [Data|Datas], Acc) when is_record(Data, rec_home_girl_info) ->
	Key     = Data#rec_home_girl_info.id,
	Value   = Data,
	When	= ?null,
	generate_girlinfo(FunName, Datas, [{Key, Value, When}|Acc]);
generate_girlinfo(FunName, [], Acc) -> {FunName, Acc}.
%%
%% Local Functions
%%