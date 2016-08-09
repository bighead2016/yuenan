%% Author: Administrator
%% Created: 2014-2-24
%% Description: TODO: Add description to partner_soul_data_generator
-module(partner_soul_data_generator).

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

%%
%% API Functions
%%
generate(Ver) ->
	try
		FunDatas1 = generate_partner_soul(get_partner_soul, Ver),
		FunDatas2 = generate_partner_star(get_partner_star, Ver),
		misc_app:write_erl_file(data_partner_soul,
								["../../include/const.common.hrl",
								 "../../include/record.player.hrl",
								 "../../include/record.base.data.hrl",
								 "../../include/record.data.hrl"],
								[FunDatas1, FunDatas2], Ver)
	catch 
		_Type:Error->
			?MSG_ERROR("~p~n~p~n",[Error,erlang:get_stacktrace()])
	end.

%% 生成将魂初始数据
generate_partner_soul(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner_soul/partner_soul.yrl"),
	generate_partner_soul(FunName, Datas, []).

generate_partner_soul(FunName, [Data|Datas], Acc) when is_record(Data, rec_partner_soul) ->
	Key		= {Data#rec_partner_soul.lv, Data#rec_partner_soul.carrer},
	Value	= Data,
	When	= ?null,
	generate_partner_soul(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_soul(FunName, [], Acc) -> {FunName, Acc}.

%% 生成将星初始数据
generate_partner_star(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/partner_soul/partner_star.yrl"),
	generate_partner_star(FunName, Datas, []).

generate_partner_star(FunName, [Data|Datas], Acc) when is_record(Data, rec_partner_star) ->
	Key		= Data#rec_partner_star.lv,
	Value	= Data,
	When	= ?null,
	generate_partner_star(FunName, Datas, [{Key, Value, When}|Acc]);
generate_partner_star(FunName, [], Acc) -> {FunName, Acc}.



%%
%% Local Functions
%%

