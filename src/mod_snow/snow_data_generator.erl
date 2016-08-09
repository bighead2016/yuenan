%%% 雪夜赏灯数据生成器
-module(snow_data_generator).

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

%% shop_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_snow(get_snow_goods_list, Ver),
	misc_app:write_erl_file(data_snow,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1], Ver).

generate_snow(FunName, Ver) ->
    SnowData = misc_app:get_data_list(Ver++"/snow/snow_goods_list.yrl"),
    generate_snow(FunName, SnowData, []).
generate_snow(FunName, [Data|Datas], Acc) when is_record(Data, rec_snow_goods_list) ->
	Key		= Data#rec_snow_goods_list.level,
	Value	= Data,
	When	= ?null,
	generate_snow(FunName, Datas, [{Key, Value, When}|Acc]);
generate_snow(FunName, [], Acc) -> {FunName, Acc}.

%% ====================================================================
%% Internal functions
%% ====================================================================


