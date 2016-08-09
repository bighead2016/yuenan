%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(npc_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% npc_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_npc(get_npc, Ver),
	FunDatas2 = generate_npc_list(get_npc_list, Ver),
	misc_app:write_erl_file(data_npc,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2], Ver).

%% npc_data_generator:generate_npc(get_npc).
generate_npc(FunName, Ver) ->
	CopyDatas = misc_app:load_file(?DIR_YRL_ROOT++ Ver ++ "/map/npc.yrl"),
	generate_npc(FunName, CopyDatas, []).
generate_npc(FunName, [Data|Datas], Acc) when is_record(Data, rec_npc) ->
	Key		= Data#rec_npc.npc_id,
	Value	= Data,
	When	= ?null,
	generate_npc(FunName, Datas, [{Key, Value, When}|Acc]);
generate_npc(FunName, [], Acc) -> {FunName, Acc}.

generate_npc_list(FunName, Ver) ->
	CopyDatas = misc_app:load_file(?DIR_YRL_ROOT++ Ver ++ "/map/npc.yrl"),
	generate_npc_list(FunName, CopyDatas, []).
generate_npc_list(FunName, [Data|Datas], Acc) when is_record(Data, rec_npc) ->
	generate_npc_list(FunName, Datas, [Data#rec_npc.npc_id|Acc]);
generate_npc_list(FunName, [], Value) ->
	Key		= ?null,
	When	= ?null,
	{FunName, [{Key, Value, When}]}.

%%
%% Local Functions
%%