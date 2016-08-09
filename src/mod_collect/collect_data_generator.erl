%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(collect_data_generator).

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
%% collect_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_collect(get_base_collect, Ver),
    FunDatas2 = generate_gather(get_gather, Ver),
	misc_app:write_erl_file(data_collect,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2], Ver).

%% collect_data_generator:generate_collect(get_base_collect).
generate_collect(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/collect/collect.yrl"),
	generate_collect(FunName, Datas, []).
generate_collect(FunName, [Data|Datas], Acc) when Data#rec_collect.type =:= 1 ->
	Key = {Data#rec_collect.lv, Data#rec_collect.collect_type},
	Value = Data,
	When    = ?null,
	generate_collect(FunName, Datas, [{Key, Value, When}|Acc]);
generate_collect(FunName, [_Data|Datas], Acc) ->
	generate_collect(FunName, Datas, Acc);
generate_collect(FunName, [], Acc) -> {FunName, Acc}.
	
generate_gather(FunName, Ver) ->
    Datas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/collect/collect.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
    generate_gather(FunName, Datas, []).
generate_gather(FunName, [Data|Datas], Acc) when is_record(Data, rec_collect) andalso Data#rec_collect.type =:= 2 ->
    Key     = Data#rec_collect.id,
    Value   = #gather{id = Data#rec_collect.id, x = Data#rec_collect.x, y = Data#rec_collect.y, goods_id = Data#rec_collect.goods_id},
    When    = ?null,
    generate_gather(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gather(FunName, [_Data|Datas], Acc) ->
    generate_gather(FunName, Datas, Acc);
generate_gather(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%