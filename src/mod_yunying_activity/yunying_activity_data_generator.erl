%%% 运营活动数据生成器
-module(yunying_activity_data_generator).

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
	FunDatas1 = generate_yunying_acitvity(get_yunying_activity_data, Ver),
	FunDatas2 = generate_yunying_acitvity_exchange(get_yunying_activity_exchange, Ver),
	FunDatas3 = generate_yunying_acitvity_stone_compose(get_activity_stone_compose, Ver),
	FunDatas4 = generate_yunying_acitvity_partner_exchange(get_partner_exchange, Ver),
	FunDatas5 = generate_yunying_acitvity_card_lottery(get_card_lottery_data, Ver),
	FunDatas6 = generate_yunying_acitvity_stone_value(get_stone_value, Ver),
	FunDatas7 = generate_yunying_activity_riddle(get_riddle, Ver),
	FunDatas8 = generate_yunying_activity_riddle_length(get_riddle_length, Ver),
	misc_app:write_erl_file(data_yunying_activity,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4,
							 FunDatas5, FunDatas6, FunDatas7, FunDatas8], Ver).

generate_yunying_acitvity(FunName, Ver) ->
    ActivityData = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_data.yrl"),
    generate_yunying_acitvity(FunName, ActivityData, []).
generate_yunying_acitvity(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_data) ->
	Key		= Data#rec_yunying_activity_data.type,
	Value	= Data,
	When	= ?null,
	generate_yunying_acitvity(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity(FunName, [], Acc) -> {FunName, Acc}.

generate_yunying_acitvity_stone_compose(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_stone_compose.yrl"),
    generate_yunying_acitvity_stone_compose(FunName, Data, []).
generate_yunying_acitvity_stone_compose(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_stone_compose) ->
	Key		= Data#rec_yunying_activity_stone_compose.stone_lv,
	Value	= Data,
	When	= ?null,
	generate_yunying_acitvity_stone_compose(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity_stone_compose(FunName, [], Acc) -> {FunName, Acc}.



generate_yunying_acitvity_exchange(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_exchange.yrl"),
    generate_yunying_acitvity_exchange(FunName, Data, []).
generate_yunying_acitvity_exchange(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_exchange) ->
	Key		= Data#rec_yunying_activity_exchange.id,
	Value	= Data,
	When	= ?null,
	generate_yunying_acitvity_exchange(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity_exchange(FunName, [], Acc) -> {FunName, Acc}.


generate_yunying_acitvity_partner_exchange(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_partner_exchange.yrl"),
    generate_yunying_acitvity_partner_exchange(FunName, Data, []).
generate_yunying_acitvity_partner_exchange(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_partner_exchange) ->
	Key		= {Data#rec_yunying_activity_partner_exchange.mode, Data#rec_yunying_activity_partner_exchange.type,Data#rec_yunying_activity_partner_exchange.id},
	Value	= Data,
	When	= ?null,
	generate_yunying_acitvity_partner_exchange(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity_partner_exchange(FunName, [], Acc) -> {FunName, Acc}.


generate_yunying_acitvity_card_lottery(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_card_lottery.yrl"),
    generate_yunying_acitvity_card_lottery(FunName, Data, []).
generate_yunying_acitvity_card_lottery(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_card_lottery) ->
	Key		= Data#rec_yunying_activity_card_lottery.type,
	Value	= Data,
	When	= ?null,
	generate_yunying_acitvity_card_lottery(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity_card_lottery(FunName, [], Acc) -> {FunName, Acc}.

generate_yunying_acitvity_stone_value(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/yunying_activity_stone_value.yrl"),
	generate_yunying_acitvity_stone_value(FunName, Data, []).
generate_yunying_acitvity_stone_value(FunName, [Data|Datas], Acc) when is_record(Data, rec_yunying_activity_stone_value) ->
	Key   = {Data#rec_yunying_activity_stone_value.stone_lv, Data#rec_yunying_activity_stone_value.type},
	Value = Data,
	When  = ?null,
	generate_yunying_acitvity_stone_value(FunName, Datas, [{Key, Value, When}|Acc]);
generate_yunying_acitvity_stone_value(FunName, [], Acc) -> {FunName, Acc}.

generate_yunying_activity_riddle(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/riddle.yrl"),
	generate_yunying_activity_riddle(FunName, Data, []).
generate_yunying_activity_riddle(FunName, [Data|Rem], Acc) when is_record(Data, rec_riddle) ->
	Key = Data#rec_riddle.id,
	Value = Data,
	When = ?null,
	generate_yunying_activity_riddle(FunName, Rem, [{Key, Value, When}|Acc]);
generate_yunying_activity_riddle(FunName, [], Acc) -> {FunName, Acc}.

generate_yunying_activity_riddle_length(FunName, Ver) ->
	Data = misc_app:get_data_list(Ver++"/yunying_activity/riddle.yrl"),
	Key = ?null,
	Value = length(Data),
	When = ?null, 
	{FunName, [{Key, Value, When}]}.
%% ====================================================================
%% Internal functions
%% ====================================================================

