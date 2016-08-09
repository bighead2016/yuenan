%% Author: Administrator
%% Created: 2012-7-17
%% Description: TODO: Add description to resource_data_generator
-module(resource_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%
%% resource_data_generator:generate().
generate(Ver)	->
	FunDatas1	= generate_rune_init(get_rune_init, Ver),
	FunDatas2	= generate_rune_chest_init(get_rune_chest_init, Ver),
	FunDatas3	= generate_rune_chest_list(get_rune_chest_list, Ver),
	FunDatas4	= generate_pray_init(get_pray_init, Ver),
	FunDatas5	= generate_key_init(get_key_init, Ver),
	FunDatas6	= generate_drop_init(get_drop_init, Ver),
	FunDatas7	= generate_random_rate(get_random_rate, Ver),
	misc_app:write_erl_file(data_resource,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, 
                             FunDatas5, FunDatas6, FunDatas7], Ver).

%% resource_data_generator:generate_rune_init(get_rune_init).
generate_rune_init(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_rune_init(FunName, Datas2, []).
generate_rune_init(FunName, [Data = #rec_rune{is_when = 0} | Datas], Acc) when is_record(Data, rec_rune) ->
	Key		= Data#rec_rune.data,
	Value	= Data#rec_rune.cash,
	When	= ?null,
	generate_rune_init(FunName, Datas, [{Key, Value, When}|Acc]);
generate_rune_init(FunName, [Data = #rec_rune{is_when = 1} | Datas], Acc) when is_record(Data, rec_rune) ->
	Key		= "N",
	Value	= Data#rec_rune.cash,
	When	= when_process(Data#rec_rune.data),
	generate_rune_init(FunName, Datas, [{Key, Value, When} | Acc]);
generate_rune_init(FunName, [], Acc) -> {FunName, Acc}.

%% resource_data_generator:generate_rune_chest_init(get_rune_chest_init).
generate_rune_chest_init(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.chest.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	Key		= ?null,
	Value	= #chest{list	= [],	sum	= 0},
	When	= ?null,
	Acc		= [{Key, Value, When}],
	generate_rune_chest_init(FunName, Datas2, Acc).
generate_rune_chest_init(FunName, [Data|Datas], [{Key, Value, When}]) when is_record(Data, rec_rune_chest) andalso is_record(Value, chest) ->
	List		= [{Data#rec_rune_chest.id, Data#rec_rune_chest.prob}] ++ Value#chest.list,
	Sum			= Data#rec_rune_chest.prob + Value#chest.sum,
	NewValue	= #chest{list	= List,
						 sum	= Sum},
	NewAcc		= [{Key, NewValue, When}],
	generate_rune_chest_init(FunName, Datas, NewAcc);
generate_rune_chest_init(FunName, [], [{Key, Value, When}]) when is_record(Value, chest) ->
	{List, Sum}	= misc_random:odds_list_init(?MODULE, ?LINE, Value#chest.list, Value#chest.sum),
	Out	= Value#chest{list	= List,
					  sum	= Sum},
	{FunName, [{Key, Out, When}]}.

%% resource_data_generator:generate_rune_chest_list(get_rune_chest_list).
generate_rune_chest_list(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.chest.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_rune_chest_list(FunName, Datas2, []).
generate_rune_chest_list(FunName, [Data | Datas], Acc) when is_record(Data, rec_rune_chest)	->
	case Acc of
		[]	->
			Key		= ?null,
			Value	= [Data#rec_rune_chest.id],
			When	= ?null,
			generate_rune_chest_list(FunName, Datas, [{Key, Value, When}]);
		[{Key, Value, When}]	->
			NewValue	= [Data#rec_rune_chest.id | Value],
			generate_rune_chest_list(FunName, Datas, [{Key, NewValue, When}])
	end;
generate_rune_chest_list(FunName, [], Acc)	->	{FunName, Acc}.

%% resource_data_generator:generate_pray_init(get_pray_init).
generate_pray_init(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/pray.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
    generate_pray_init(FunName, Datas2, []).
generate_pray_init(FunName, [Data | Datas], Acc) when is_record(Data, rec_pray) ->
	Key		= Data#rec_pray.id,
 	Value	= Data,
	When	= ?null,
	generate_pray_init(FunName, Datas, [{Key, Value, When} | Acc]);
generate_pray_init(FunName, [], Acc)	->	{FunName, Acc}.

%% resource_data_generator:generate_key_init(get_key_init).
generate_key_init(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.chest.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_key_init(FunName, Datas2, []).
generate_key_init(FunName, [Data | Datas], Acc) when is_record(Data, rec_rune_chest)	->
	Key		= Data#rec_rune_chest.id,
	Value	= Data#rec_rune_chest.key_id,
	When	= ?null,
	generate_key_init(FunName, Datas, [{Key, Value, When} | Acc]);
generate_key_init(FunName, [], Acc)	->	{FunName, Acc}.

%% resource_data_generator:generate_drop_init(get_drop_init).
generate_drop_init(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/resource/rune.chest.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_drop_init(FunName, Datas2, []).
generate_drop_init(FunName, [Data | Datas], Acc) when is_record(Data, rec_rune_chest)	->
	NewAcc	= drop(Data#rec_rune_chest.id, Data#rec_rune_chest.drop, []),
	generate_drop_init(FunName, Datas, NewAcc ++ Acc);
generate_drop_init(FunName, [], Acc)	->	{FunName, Acc}.

when_process(Data)	->
	case Data of
		{upper, Value}	->
			"N >= " ++ integer_to_list(Value);
		{lower, Value}	->
			"N =< " ++ integer_to_list(Value);
		{greater, Value}	->
			"N > " ++ integer_to_list(Value);
		{less, Value}	->
			"N < " ++ integer_to_list(Value);
		{equal, Value}	->
			"N =:= " ++ integer_to_list(Value);
		{left, MinValue, MaxValue}	->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{right, MinValue, MaxValue}	->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue);
		{open, MinValue, MaxValue}	->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{close, MinValue, MaxValue}	->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue)
	end.

drop(ChestId, [Drop | DropList], Acc)	->
	{MivLv, MaxLv, DropId}	= Drop,
	Key		= lists:concat(["{", ChestId, ", Lv}"]),
	Value	= DropId,
	When	= "Lv >= " ++ integer_to_list(MivLv) ++ " andalso " ++ "Lv =< " ++ integer_to_list(MaxLv),
	NewAcc	= [{Key, Value, When} | Acc],
	drop(ChestId, DropList, NewAcc);
drop(_ChestId, [], Acc)	->	Acc.

generate_random_rate(FunName, _Ver) ->
    L = lists:seq(0, ?CONST_SYS_MAX_VIP_LV),
    generate_random_rate(FunName, L, []).
generate_random_rate(FunName, [VipLv|Datas], Acc) ->
    Key     = VipLv,
    
	Vips = (13-VipLv) * (13-VipLv),
	First = 15*Vips,
	Second = First + 47*Vips,
    LR1 = round(First),
    LR2 = round(Second),
    LR3 = LR1 + LR2,
    LValue   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, LR1}, {2, LR2}, {3, 100000-LR3}], 100000),
    
    R1 = round(First),
    R2 = round(Second),
    R3 = R1 + R2,
    Value   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, R1}, {2, R2}, {3, 100000-R3}], 100000),
    
    HR1 = round(First),
    HR2 = round(Second),
    HR3 = HR1 + HR2,
    RValue   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, HR1}, {2, HR2}, {3, 100000-HR3}], 100000),
    
    % 过了2次
    LR1_2 = 0,
    LR2_2 = round(Second),
    LR3_2 = LR1_2 + LR2_2,
    LValue_2   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, LR1_2}, {2, LR2_2}, {3, 100000-LR3_2}], 100000),
    
    R1_2 = 0,
    R2_2 = round(Second),
    R3_2 = R1_2 + R2_2,
    Value_2   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, R1_2}, {2, R2_2}, {3, 100000-R3_2}], 100000),
    
    HR1_2 = 0,
    HR2_2 = round(Second),
    HR3_2 = HR1_2 + HR2_2,
    RValue_2   = misc_random:odds_list_init(?MODULE, ?LINE, [{1, HR1_2}, {2, HR2_2}, {3, 100000-HR3_2}], 100000),
    
    When    = ?null,
    generate_random_rate(FunName, Datas, [{Key, {LValue, Value, RValue, LValue_2, Value_2, RValue_2}, When}|Acc]);
generate_random_rate(FunName, [], Acc) -> {FunName, Acc}.
