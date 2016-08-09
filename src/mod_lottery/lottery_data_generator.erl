%% Author: Administrator
%% Created: 2012-8-10
%% Description: TODO: Add description to lottery_data_generator
-module(lottery_data_generator).

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
%% lottery_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_lottery_init(get_lottery_init, Ver),
	FunDatas2 = generate_accumulator_init(get_accumulator_init, Ver),
	misc_app:write_erl_file(data_lottery,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2], Ver).

%%
%% Local Functions
%%
%% lottery_data_generator:generate_lottery_init(get_lottery_init).
generate_lottery_init(FunName, Ver) ->
	case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/lottery/lottery.yrl") of
        Datas when is_list(Datas) ->
            Datas2 = lists:reverse(Datas);
        Datas ->
            Datas2 = [Datas]
    end,
    generate_lottery_init(FunName, Datas2, []).
generate_lottery_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_lottery) ->
	Key			= Data#rec_lottery.id,
 	{List, ExpectSum}	= misc_random:odds_list_init(?MODULE, ?LINE, Data#rec_lottery.formula, Data#rec_lottery.sum),
	Value		= #rec_lottery{id			= Data#rec_lottery.id,
							   formula		= List,
							   sum			= ExpectSum,
							   data			= process_lottery_data(Data#rec_lottery.data),
							   information	= Data#rec_lottery.information},
	When    = ?null,
	generate_lottery_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_lottery_init(FunName, [], Acc) -> {FunName, Acc}.

process_lottery_data([]) ->
	[];
process_lottery_data(Data) ->
	[Head | Tail] = Data,
	NewHead = process_probability_data(Head#lottery_data.data),
	{List, ExpectSum}	= misc_random:odds_list_init(?MODULE, ?LINE, NewHead, Head#lottery_data.sum),
	First	= #lottery_data{id		= Head#lottery_data.id,
							data	= List,
							sum		= ExpectSum},
	Second	= process_lottery_data(Tail),
	[First | Second].

process_probability_data([]) ->
	[];
process_probability_data(Data) ->
	[Head | Tail] = Data,
%% 	?MSG_PRINT("~nHead=~p~nTail=~p~n", [Head, Tail]),
	{GoodsId, BindState, GoodsCount, IsShow, Probability} = Head,
	First	= {{GoodsId, BindState, GoodsCount, IsShow}, Probability},
	Second	= process_probability_data(Tail),
	[First | Second].

%%
%% Local Functions
%%
%% lottery_data_generator:generate_accumulator_init(get_accumulator_init).
generate_accumulator_init(FunName, Ver) ->
	case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/lottery/accumulator.yrl") of
        Datas when is_list(Datas) ->
            Datas2 = lists:reverse(Datas);
        Datas ->
            Datas2 = [Datas]
    end,
    generate_accumulator_init(FunName, Datas2, []).
generate_accumulator_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_accumulator) ->
	Key		= Data#rec_accumulator.category,
	Formula = process_probability_data(Data#rec_accumulator.formula),
 	{List, ExpectSum}	= misc_random:odds_list_init(?MODULE, ?LINE, Formula, Data#rec_accumulator.sum),
	Value	= #rec_accumulator{category		= Data#rec_accumulator.category,
							   formula		= List,
							   sum			= ExpectSum},
	When    = ?null,
	generate_accumulator_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_accumulator_init(FunName, [], Acc) -> {FunName, Acc}.