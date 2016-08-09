%% Author: Administrator
%% Created: 2013-4-17
%% Description: TODO: Add description to party_data_generator
-module(party_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%
%% party_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_party(get_party, Ver),
	FunDatas2 = generate_party_box(get_party_box, Ver),
	FunDatas3 = generate_party_pos(get_party_pos, Ver),
	FunDatas4 = generate_party_reward(get_party_reward, Ver),
	misc_app:write_erl_file(data_party,						
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1,FunDatas2,FunDatas3,FunDatas4], Ver).

%%
%% Local Functions
%%

%% 宴会怪物、宝箱
generate_party(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/party/party.yrl"),
	generate_party(FunName, Datas, []).
generate_party(FunName, [Data|Datas], Acc) when is_record(Data, rec_party) ->
	Key     = Data#rec_party.guild_lv,
	Value   = Data,
	When	= ?null,
	generate_party(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party(FunName, [], Acc) -> {FunName, Acc}.

%% 宴会宝箱奖励
generate_party_box(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/party/party.box.yrl"),
	generate_party_box(FunName, Datas, []).
generate_party_box(FunName, [Data|Datas], Acc) when is_record(Data, rec_party_box) ->
	Key     = Data#rec_party_box.type,
	Value   = Data,
	When	= ?null,
	generate_party_box(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party_box(FunName, [], Acc) -> {FunName, Acc}.

%% 宴会经验奖励
generate_party_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/party/party.reward.yrl"),
	generate_party_reward(FunName, Datas, []).
generate_party_reward(FunName, [Data|Datas], Acc) when is_record(Data, rec_party_reward) ->
	Key     = Data#rec_party_reward.lv,
	Value   = Data,
	When	= ?null,
	generate_party_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_party_reward(FunName, [], Acc) -> {FunName, Acc}.

%% 宴会随机位置
generate_party_pos(FunName, Ver) ->
	Datas 	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/party/party.pos.yrl"),
	F		= fun(D,Acc) when is_record(D, rec_party_pos) ->
					  [{D#rec_party_pos.x,D#rec_party_pos.y}|Acc]
			  end,
	Value	= lists:foldl(F, [], Datas),	
	{FunName,[{?null,Value,?null}]}.
