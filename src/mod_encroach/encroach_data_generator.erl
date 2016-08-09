%% author: xjg
%% create: 2014-1-9
%% desc:   encroach_data_generator
%%

-module(encroach_data_generator).

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
	FunDatas1 = generate_encroach_init(get_encroach_data, Ver),
	FunDatas2 = generate_encroach_pos(get_encroach_pos, Ver),
	FunDatas3 = generate_encroach_lottery(get_encroach_lottery, Ver),
	misc_app:write_erl_file(data_encroach,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3], Ver).


generate_encroach_init(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/encroach/encroach.yrl"),
	generate_encroach_init(FunName, Datas, []).
generate_encroach_init(FunName, [Data|Datas], Acc) when is_record(Data, rec_encroach) ->
	Key		= Data#rec_encroach.lv,
	Value	= Data,
	When	= ?null,
	generate_encroach_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_encroach_init(FunName, [], Acc) -> {FunName, lists:reverse(Acc)}.

generate_encroach_pos(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/encroach/encroach_pos.yrl"),
	generate_encroach_pos(FunName, Datas, []).
generate_encroach_pos(FunName, [Data|Datas], Acc) when is_record(Data, rec_encroach_pos) ->
	Key		= Data#rec_encroach_pos.pos,
	Value	= Data,
	When	= ?null,
	generate_encroach_pos(FunName, Datas, [{Key, Value, When}|Acc]);
generate_encroach_pos(FunName, [], Acc) -> {FunName, lists:reverse(Acc)}.

generate_encroach_lottery(FunName, Ver) ->
	Data = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/encroach/encroach_lottery.yrl"),
	Key = ?null,
	Value = Data,
	When = ?null,
	{FunName, [{Key, Value, When}]}.


