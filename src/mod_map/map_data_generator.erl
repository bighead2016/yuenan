%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(map_data_generator).

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
%% map_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_map(get_map, Ver),
	FunDatas2 = generate_map_list(get_map_list, Ver),
    FunDatas3 = generate_npc(get_npc, Ver),
    FunDatas4 = generate_city_npc(get_city_npc, Ver),
	misc_app:write_erl_file(data_map,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4], Ver).

%% map_data_generator:generate_map(get_map).
generate_map(FunName, Ver) ->
    MapDatas = misc_app:get_data_list(Ver ++ "/map/map.yrl"),
	generate_map(FunName, MapDatas, []).
generate_map(FunName, [Data|Datas], Acc) when is_record(Data, rec_map) ->
	Key		= Data#rec_map.map_id,
	Value	= Data,
	When	= ?null,
	generate_map(FunName, Datas, [{Key, Value, When}|Acc]);
generate_map(FunName, [], Acc) -> {FunName, Acc}.

generate_map_list(FunName, Ver) ->
    MapDatas = misc_app:get_data_list(Ver ++ "/map/map.yrl"),
	generate_map_list(FunName, MapDatas, []).
generate_map_list(FunName, [Data|Datas], Acc) when is_record(Data, rec_map) ->
	generate_map_list(FunName, Datas, [Data#rec_map.map_id|Acc]);
generate_map_list(FunName, [], Value) ->
	Key		= ?null,
	When	= ?null,
	{FunName, [{Key, Value, When}]}.

%% map_data_generator:generate_npc(get_npc).
generate_npc(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/map/npc.yrl"),
    generate_npc(FunName, Datas, []).
generate_npc(FunName, [Data|Datas], Acc) when is_record(Data, rec_npc) ->
    Key     = Data#rec_npc.npc_id,
    Value   = Data,
	When	= ?null,
    generate_npc(FunName, Datas, [{Key, Value, When}|Acc]);
generate_npc(FunName, [], Acc) -> {FunName, Acc}.

%% 
generate_city_npc(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver ++ "/map/npc.yrl"),
    generate_city_npc(FunName, Datas, []).
generate_city_npc(FunName, [Data|_Tail] = Datas1, Acc) when is_record(Data, rec_npc) ->
    Key     = Data#rec_npc.map_id,
    Value   = [T#rec_npc.npc_id||T <- Datas1, T#rec_npc.map_id =:= Key],
    When    = ?null,
    F = fun(#rec_npc{npc_id = X} = R, OldDatas) ->
            case lists:member(X, Value) of
                ?true ->
                    OldDatas;
                ?false ->
                    [R|OldDatas]
            end
        end,
    NewDatas = lists:foldl(F, [], Datas1),
    generate_city_npc(FunName, NewDatas, [{Key, Value, When}|Acc]);
generate_city_npc(FunName, [], Acc) -> {FunName, Acc}.


%%
%% Local Functions
%%