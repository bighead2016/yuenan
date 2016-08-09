%% Author: Administrator
%% Created: 2013-6-13
%% Description: TODO: Add description to new_serv_data_generator
-module(new_serv_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").

%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% new_serv_data_generator:generate().
generate(Ver)	->
	FunDatas1	= generate_achieve_list(get_achieve_list, Ver),
	FunDatas2	= generate_achieve_info(get_achieve_info, Ver),
	FunDatas3	= generate_achieve_by_id(get_achieve_by_id, Ver),
	FunDatas4	= generate_achieve_goods(get_achieve_goods, Ver),
%% 	FunDatas5	= generate_achieve_sub(get_achieve_sub),
	FunDatas6	= generate_rank(get_rank_reward, Ver), 
	FunDatas7	= generate_turn(get_turn, Ver), 
	FunDatas8	= generate_turn_info(get_turn_info, Ver), 
	FunDatas9	= generate_deposit_reward(get_deposit_reward, Ver), 
	FunDatas10  = generate_honor_title(get_honor_title, Ver),
	misc_app:write_erl_file(data_new_serv,
							["../../include/const.common.hrl",
							 "../../include/record.base.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3,FunDatas4,
                             FunDatas6, FunDatas7,FunDatas8,
							 FunDatas9, FunDatas10
                            ], Ver).

	
%% new_serv_data_generator:generate_achieve_list(get_achieve_list).
generate_achieve_list(FunName, Ver)	->
	TempDatas1	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/achieve.yrl"),
	Datas2	= TempDatas1,
	generate_achieve_list(FunName, Datas2, []).
generate_achieve_list(FunName, [Data = #rec_achieve{is_when = 0} | Datas], Acc)
  when is_record(Data, rec_achieve)	->
	Key		= {Data#rec_achieve.type},
	Value	= [Data#rec_achieve.id],
	When	= ?null,
	generate_achieve_list(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_list(FunName, [Data = #rec_achieve{is_when = 1} | Datas], Acc)
  when is_record(Data, rec_achieve)	->
	Key		= {Data#rec_achieve.type},	%% lists:concat(["{", Data#rec_achieve.type, ", N}"]),
	NewAcc	= case lists:keyfind(Key, 1, Acc) of
				  {Key, Value, When}	->
					  DelAcc	= lists:keydelete(Key, 1, Acc),
					  NewValue	= [Data#rec_achieve.id | Value],
					  [{Key, NewValue, When} | DelAcc];
				  ?false				->
					  When	= ?null,	%% when_process(Data#rec_achieve.condition),
					  [{Key, [Data#rec_achieve.id], When} | Acc]
			  end,
	generate_achieve_list(FunName, Datas, NewAcc);
generate_achieve_list(FunName, [], Acc)	->	{FunName, Acc}.
%% 	ReverseAcc	= lists:reverse(Acc),
%% 	{FunName, ReverseAcc}.

%% new_serv_data_generator:generate_achieve_info(get_achieve_info).
generate_achieve_info(FunName, Ver)	->
	TempDatas1	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/achieve.yrl"),
	Datas2	= TempDatas1,
	generate_achieve_info(FunName, Datas2, []).
generate_achieve_info(FunName, [Data = #rec_achieve{is_when = 0} |Datas], Acc) when is_record(Data, rec_achieve)	->
	Key		= Data#rec_achieve.id,
	Value	= Data,
	When	= ?null,
	generate_achieve_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_info(FunName, [Data = #rec_achieve{is_when = 1} |Datas], Acc) when is_record(Data, rec_achieve)	->
	Key		= lists:concat(["{", Data#rec_achieve.id, ", N}"]),
	Value	= Data,
	When	= when_process(Data#rec_achieve.condition),
	generate_achieve_info(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_info(FunName, [], Acc)	->	{FunName, Acc}.


%% new_serv_data_generator:generate_achieve_by_id(get_achieve_by_id).
generate_achieve_by_id(FunName, Ver)	->
	TempDatas1	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/achieve.yrl"),
	Datas2	= TempDatas1,
	generate_achieve_by_id(FunName, Datas2, []).
generate_achieve_by_id(FunName, [Data|Datas], Acc) when is_record(Data, rec_achieve)	->
	Key		= Data#rec_achieve.id,
	Value	= Data,
	When	= ?null,
	generate_achieve_by_id(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_by_id(FunName, [Data|Datas], Acc) when is_record(Data, rec_achieve_ext)	->
	Key		= Data#rec_achieve_ext.id,
	Value	= erlang:setelement(1, Data, rec_achieve),
	When	= ?null,
	generate_achieve_by_id(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_by_id(FunName, [], Acc)	->	{FunName, Acc}.

%% new_serv_data_generator:generate_achieve_goods(get_achieve_goods).
generate_achieve_goods(FunName, Ver)	->
	TempDatas1	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/achieve.yrl"),
	Datas2	= TempDatas1,
	generate_achieve_goods(FunName, Datas2, []).
generate_achieve_goods(FunName, [Data | Datas], Acc) when is_record(Data, rec_achieve)	->
	Key		= Data#rec_achieve.id,
	Value	= Data,
	When	= ?null,
	generate_achieve_goods(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_goods(FunName, [Data | Datas], Acc) when is_record(Data, rec_achieve_ext)	->
	Key		= Data#rec_achieve_ext.id,
	Value	= erlang:setelement(1, Data, rec_achieve),
	When	= ?null,
	generate_achieve_goods(FunName, Datas, [{Key, Value, When} | Acc]);
generate_achieve_goods(FunName, [], Acc)	->	{FunName, Acc}.
	
when_process(Data) ->
	case Data of
		{upper, Value} ->
			"N >= " ++ integer_to_list(Value);
		{lower, Value} ->
			"N =< " ++ integer_to_list(Value);
		{greater, Value} ->
			"N > " ++ integer_to_list(Value);
		{less, Value} ->
			"N < " ++ integer_to_list(Value);
		{equal, Value} ->
			"N =:= " ++ integer_to_list(Value);
		{left, MinValue, MaxValue} ->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{right, MinValue, MaxValue} ->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue);
		{open, MinValue, MaxValue} ->
			"N > " ++ integer_to_list(MinValue) ++ " andalso " ++ "N < " ++ integer_to_list(MaxValue);
		{close, MinValue, MaxValue} ->
			"N >= " ++ integer_to_list(MinValue) ++ " andalso " ++ "N =< " ++ integer_to_list(MaxValue)
	end.

generate_rank(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/new_serv_rank.yrl"),
	generate_rank(FunName, Datas, []).
generate_rank(FunName, [Data|Datas], Acc) when is_record(Data, rec_new_serv_rank) ->
	Key     = {Data#rec_new_serv_rank.type,Data#rec_new_serv_rank.rank},
	Value   = Data,
	When	= ?null,
	generate_rank(FunName, Datas, [{Key, Value, When}|Acc]);
generate_rank(FunName, [], Acc) -> {FunName, Acc}.

generate_turn(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/new_serv_turn.yrl"),
    generate_turn(FunName, Datas, []).
generate_turn(FunName, [Data|Datas], Acc) when is_record(Data, rec_new_serv_turn) ->
	Time_Start = Data#rec_new_serv_turn.time_start,
	Time_End = Data#rec_new_serv_turn.time_end,
	Start = 
		case Time_Start of
			0 -> 0;
			_ ->
				misc:date_time_to_stamp(Time_Start)
		end,
	End = 
		case Time_End of
			0 -> 0;
			_ -> 
				misc:date_time_to_stamp(Time_End)
		end,
    Key     = {Data#rec_new_serv_turn.group, Data#rec_new_serv_turn.idx},
    Value   = Data#rec_new_serv_turn{time_start = Start, time_end = End},
    When    = ?null,
    generate_turn(FunName, Datas, [{Key, Value, When}|Acc]);
generate_turn(FunName, [], Acc) -> {FunName, Acc}.

generate_turn_info(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/new_serv_turn.yrl"),
	generate_turn_info(FunName, Datas, 0, []).
generate_turn_info(FunName, [], _GroupId, Acc) ->
	{FunName, Acc};
generate_turn_info(FunName, Rem, GroupId, Acc) ->
	{NSub, NRem} = lists:split(12, Rem),
    L1 = change_turn_1(NSub, []),
    L2 = change_turn_2(NSub, []),
	L = [{{GroupId, 1}, L1, ?null}, {{GroupId, 2}, L2, ?null}],
	generate_turn_info(FunName, NRem, GroupId + 1, lists:append(L, Acc)).
	
%% new_serv_data_generator:generate_deposit_reward(get_deposit_reward).
generate_deposit_reward(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/deposit.yrl"),
	generate_deposit_reward(FunName, Datas, []).
generate_deposit_reward(FunName, [Data|Datas], Acc)  ->
	Key		= Data#rec_deposit.id,
	Value	= Data,
	When    = ?null,
	generate_deposit_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_deposit_reward(FunName, [], Acc) -> {FunName, Acc}.
%%
%% Local Functions
%%
%% change_turn([]) ->
%%     misc_random:odds_list_init(?MODULE, ?LINE, [], ExpectSum),
%%     ok.
change_turn_1([#rec_new_serv_turn{idx = Idx, weight_1 = W1}|Tail], List) ->
    change_turn_1(Tail, [{Idx, W1}|List]);
change_turn_1([], List) ->
    misc_random:odds_list_init(?MODULE, ?LINE, List, 10000).

change_turn_2([#rec_new_serv_turn{idx = Idx, weight_2 = W2}|Tail], List) ->
    change_turn_2(Tail, [{Idx, W2}|List]);
change_turn_2([], List) ->
    misc_random:odds_list_init(?MODULE, ?LINE, List, 10000).


generate_honor_title(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/new_serv/new_serv_honor_title.yrl"),
    generate_honor_title(FunName, Datas, []).
generate_honor_title(FunName, [Data|Datas], Acc) when is_record(Data, rec_new_serv_honor_title) ->
    Key     = Data#rec_new_serv_honor_title.honor_id,
    Value   = Data,
    When    = ?null,
    generate_honor_title(FunName, Datas, [{Key, Value, When}|Acc]);
generate_honor_title(FunName, [], Acc) -> {FunName, Acc}.




