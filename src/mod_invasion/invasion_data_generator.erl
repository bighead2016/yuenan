-module(invasion_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
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
%% invasion_data_generator:generate().
generate(Ver)	->
	FunDatas1	= generate_invasion_info(get_invasion_info, Ver),
	FunDatas2	= generate_init_copy_list(init_copy_list, Ver),
	FunDatas3	= generate_get_copy_list(get_copy_list, Ver),
	FunDatas4	= generate_map2copy(map2copy, Ver),
	FunDatas5	= generate_map_list(get_map_list, Ver),
	FunDatas6	= generate_invasion_gift(get_invasion_gift, Ver),
	FunDatas7	= generate_attack_to_guard(attack_to_guard, Ver),
	FunDatas8	= generate_invasion_doll_reward(get_invasion_doll_reward, Ver),
%% 	FunDatas7	= generate_part(get_part),
	misc_app:write_erl_file(data_invasion,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, 
							 FunDatas5, FunDatas6, FunDatas7, FunDatas8], Ver).

%% invasion_data_generator:generate_invasion_info(get_invasion_info).
generate_invasion_info(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_invasion_info(FunName, Datas, []).
generate_invasion_info(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion)	->
	Key		= Data#rec_invasion.id,
	Value	= process(Data),
	When	= ?null,
	generate_invasion_info(FunName, Datas, [{Key, Value, When}|Acc]);
generate_invasion_info(FunName, [], Acc)	->	{FunName, Acc}.

process(Data) when is_record(Data, rec_invasion)	->
	First	= monster(Data#rec_invasion.monster, ?CONST_INVASION_FIRST, []),
	Second	= monster(Data#rec_invasion.other, ?CONST_INVASION_SECOND, []),
	Third	= monster(Data#rec_invasion.another, ?CONST_INVASION_THIRD, []),
	Monster	= First ++ Second ++ Third,
	Data#rec_invasion{monster	= Monster,	other	= [],	another		= []}.

monster([MonInfo | MonInfoList], Nth, Acc)	->
	{Wave, MonIdList}	= MonInfo,
	Mon	= make(Wave, MonIdList, Nth, []),
	monster(MonInfoList, Nth, Acc ++ Mon);
monster([], _Nth, Acc)	->	Acc.

make(Wave, [MonId | MonIdList], Nth, Acc)	->
	make(Wave, MonIdList, Nth, Acc ++ [{Wave, MonId, Nth}]);
make(_Wave, [], _Nth, Acc)	->	Acc.

%% process(Data) when is_record(Data, rec_invasion) ->
%% 	Monster	= Data#rec_invasion.monster,
%% 	Born	= Data#rec_invasion.born,
%% 	Turn	= Data#rec_invasion.turn,

%% invasion_data_generator:generate_map2copy(map2copy).
generate_map2copy(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_map2copy(FunName, Datas, []).
generate_map2copy(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion)	->
	Key		= Data#rec_invasion.map_id,
	Value	= Data#rec_invasion.id,
	When	= ?null,
	generate_map2copy(FunName, Datas, [{Key, Value, When} | Acc]);
generate_map2copy(FunName, [], Acc)	->	{FunName, Acc}.

%% invasion_data_generator:generate_map_list(get_map_list).
generate_map_list(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_map_list(FunName, Datas, []).
generate_map_list(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion) ->
	Key		= Data#rec_invasion.mode,
	Value	= case lists:keyfind(Key, 1, Acc) of
				  {Key, MapList, _When}	->	[Data#rec_invasion.map_id | MapList];
				  ?false				->	[Data#rec_invasion.map_id]
			  end,
	When	= ?null,
	DelAcc	= lists:keydelete(Key, 1, Acc),
	generate_map_list(FunName, Datas, [{Key, Value, When} | DelAcc]);
generate_map_list(FunName, [], Acc) -> {FunName, Acc}.

%% 副本列表
generate_init_copy_list(FunName, Ver)	->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	LvList	= lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
	generate_init_copy_list(FunName, LvList, Datas, []).
generate_init_copy_list(FunName, [Lv | LvList], Datas, Acc) ->
	Key		= Lv,
	Value	= [#invasion_data{copy		= RecInvasion#rec_invasion.id,
							  times		= RecInvasion#rec_invasion.times,
							  amount	= RecInvasion#rec_invasion.amount}
			  || RecInvasion <- Datas, is_record(RecInvasion, rec_invasion), 
				 RecInvasion#rec_invasion.times =/= 0, RecInvasion#rec_invasion.lv =< Lv],
	When	= ?null,
	generate_init_copy_list(FunName, LvList, Datas, [{Key, Value, When} | Acc]);
generate_init_copy_list(FunName, [], _TaskDatas, Acc) -> {FunName, Acc}.

%% 副本列表
generate_get_copy_list(FunName, Ver) ->
	Datas	=
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	DatasList	= [X || X <- Datas, X#rec_invasion.mode =:= 1],	
    generate_get_copy_list(FunName, DatasList, []).
generate_get_copy_list(FunName, [Data | DatasList],  Acc) ->
	Key		= Data#rec_invasion.module,
	Value	= #invasion_data{copy 	= Data#rec_invasion.id,
							 times	= Data#rec_invasion.times,
							 amount	= Data#rec_invasion.amount},
	When	= ?null,
	generate_get_copy_list(FunName, DatasList, [{Key, Value, When} | Acc]);
generate_get_copy_list(FunName, [], Acc)	->	{FunName, Acc}.

%% invasion_data_generator:generate_invasion_gift(get_invasion_gift).
generate_invasion_gift(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.gift.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_invasion_gift(FunName, Datas, []).
generate_invasion_gift(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion_gift)	->
	Key		= {Data#rec_invasion_gift.id, Data#rec_invasion_gift.type},
	Value	= Data,
	When	= ?null,
	generate_invasion_gift(FunName, Datas, [{Key, Value, When}|Acc]);
generate_invasion_gift(FunName, [], Acc)	->	{FunName, Acc}.

%% generate_part(FunName)	->
%% 	Datas	=
%% 		case misc_app:load_file(?DIR_YRL_ROOT ++ "invasion/invasion.yrl") of
%% 			Data when is_list(Data) ->
%% 				Data;
%% 			Data ->
%% 				[Data]
%% 		end,
%% 	generate_part(FunName, Datas, []).
%% generate_part(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion) ->
%% 	Walk	= lists:sort(Data#rec_invasion.walk),
%% 	AddAcc	= part(Data#rec_invasion.id, Walk, 1, []),
%% 	generate_part(FunName, Datas, AddAcc ++ Acc);
%% generate_part(FunName, [], Acc) -> {FunName, Acc}.
%% 
%% part(Copy, [Interval | IntervalList], Value, Acc)	->
%% 	Key		= lists:concat(["{", Copy, ", N}"]),
%% 	{
%% 	 XLeft, XRight
%% 	}		= Interval,
%% 	When	= "N > " ++ integer_to_list(XLeft) ++ " andalso " ++ "N =< " ++ integer_to_list(XRight),
%% 	NewAcc	= [{Key, Value, When} | Acc],
%% 	part(Copy, IntervalList, Value + 1, NewAcc);
%% part(_Copy, [], _Value, Acc)	->
%% 	Acc.

%% invasion_data_generator:generate_attack_to_guard(attack_to_guard).
generate_attack_to_guard(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_attack_to_guard(FunName, Datas, []).
generate_attack_to_guard(FunName, [Data | Datas], Acc) 
  when is_record(Data, rec_invasion) andalso Data#rec_invasion.next > 0	->
	Key		= Data#rec_invasion.next,
	Value	= Data#rec_invasion.id,
	When	= ?null,
	generate_attack_to_guard(FunName, Datas, [{Key, Value, When} | Acc]);
generate_attack_to_guard(FunName, [_Data | Datas], Acc)  ->
	generate_attack_to_guard(FunName, Datas, Acc);
generate_attack_to_guard(FunName, [], Acc)	->	{FunName, Acc}.

%% invasion_data_generator:generate_invasion_doll_reward(get_invasion_doll_reward).
generate_invasion_doll_reward(FunName, Ver)	->
	Datas	= 
		case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/invasion/invasion.doll.yrl") of
			Data when is_list(Data)	->
				Data;
			Data	->
				[Data]
		end,
	generate_invasion_doll_reward(FunName, Datas, []).
generate_invasion_doll_reward(FunName, [Data | Datas], Acc) when is_record(Data, rec_invasion_doll)	->
	Key		= Data#rec_invasion_doll.lv,
	Value	= Data,
	When	= ?null,
	generate_invasion_doll_reward(FunName, Datas, [{Key, Value, When}|Acc]);
generate_invasion_doll_reward(FunName, [], Acc)	->	{FunName, Acc}.
