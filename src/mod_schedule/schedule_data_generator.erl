%% Author: Administrator
%% Created: 2012-10-21
%% Description: TODO: Add description to schedule_data_generator
-module(schedule_data_generator).

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
%% schedule_data_generator:generate().
generate(Ver) ->
	FunDatas1 = generate_guide_info(get_guide_info, Ver),
	FunDatas2 = generate_gift(get_gift, Ver),
	FunDatas3 = generate_gift_info(get_gift_info, Ver),
	FunDatas4 = generate_gift_list(get_gift_list, Ver),
	FunDatas5 = gen_activity_play_list(get_activity_play_list, Ver),
	FunDatas6 = generate_resource_lookfor(get_back_resource, Ver),
	misc_app:write_erl_file(data_schedule,
							["../../include/const.common.hrl",
							 "../../include/record.base.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6], Ver).


generate_guide_info(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/guide.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_guide_info(FunName, Datas2, []).
generate_guide_info(FunName, [Data|Datas], Acc) when is_record(Data, rec_guide) ->
	Key		= Data#rec_guide.id,
	Value	= Data,
	When	= ?null,
	generate_guide_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_guide_info(FunName, [], Acc) -> {FunName, Acc}.

generate_gift(FunName, Ver)	->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/schedule.gift.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_gift(FunName, Datas2, []).
generate_gift(FunName, [Data|Datas], Acc) when is_record(Data, rec_schedule_gift)	->
	Key		= lists:concat(["{", Data#rec_schedule_gift.type, ", N}"]),
	Value	= Data#rec_schedule_gift.id,
	When	= when_process(Data#rec_schedule_gift.times),
	generate_gift(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gift(FunName, [], Acc)	->
	ReverseAcc	= lists:reverse(Acc),
	{FunName, ReverseAcc}.

generate_gift_info(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/schedule.gift.yrl") of
				  Datas when is_list(Datas) ->
					  lists:reverse(Datas);
				  Datas ->
					  [Datas]
			  end,
	generate_gift_info(FunName, Datas2, []).
generate_gift_info(FunName, [Data|Datas], Acc) when is_record(Data, rec_schedule_gift) ->
	Key		= Data#rec_schedule_gift.id,
	Value	= Data,
	When	= ?null,
	generate_gift_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gift_info(FunName, [], Acc)	->	{FunName, Acc}.

%% schedule_data_generator:generate_gift_list(get_gift_list).
generate_gift_list(FunName, Ver)	->
	Datas	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/schedule.gift.yrl") of
				  Data when is_list(Data)	->
					  Data;
				  Data	->
					  [Data]
			  end,
	generate_gift_list(FunName, Datas, []).
generate_gift_list(FunName, [Data | Datas], Acc) when is_record(Data, rec_schedule_gift) ->
	Key		= Data#rec_schedule_gift.type,
	Value	= case lists:keyfind(Key, 1, Acc) of
				  {Key, IdList, _When}	->	[Data#rec_schedule_gift.id | IdList];
				  ?false				->	[Data#rec_schedule_gift.id]
			  end,
	When	= ?null,
	DelAcc	= lists:keydelete(Key, 1, Acc),
	generate_gift_list(FunName, Datas, [{Key, Value, When} | DelAcc]);
generate_gift_list(FunName, [], Acc)	->	{FunName, Acc}.

%% schedule_data_generator:gen_activity_play_list(get_activity_play_list).
gen_activity_play_list(FunName, Ver)	->
	Datas	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/activity.yrl") of
				  Data when is_list(Data)	->
					  Data;
				  Data	->
					  [Data]
			  end,
	gen_activity_play_list_2(FunName, Datas).
gen_activity_play_list_2(FunName, Datas) ->
	Key		= ?null,
	Value   = [Active#rec_activity.id||Active <- Datas, Active#rec_activity.is_count =:= 1],
	When	= ?null,
	{FunName, [{Key, Value, When}]}.
	

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


%% 生成资源找回数据
generate_resource_lookfor(FunName, Ver) ->
	Datas2	= case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/schedule/resource.back.yrl") of
				  Datas when is_list(Datas)	->
					  lists:reverse(Datas);
				  Datas	->
					  [Datas]
			  end,
	generate_resource_lookfor(FunName, Datas2, []).
generate_resource_lookfor(FunName, [Data|Datas], Acc) when is_record(Data, rec_resource_back) ->
	Key		= Data#rec_resource_back.id,
	Value	= Data,
	When	= ?null,
	generate_resource_lookfor(FunName, Datas, [{Key, Value, When}|Acc]);
generate_resource_lookfor(FunName, [], Acc) -> {FunName, Acc}.
%%
%% Local Functions
%%

