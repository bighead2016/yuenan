%% @author jin
%% @doc @todo Add description to kb_treasure_data_generator.


-module(kb_treasure_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%

%% kb_treasure_data_generator:generate("zh_CN").
generate(Ver) ->
	FunDatas1	= {get_turn_data, "kb_treasure", "kb_treasure.yrl", [#rec_kb_treasure.config_id, #rec_kb_treasure.level, #rec_kb_treasure.idx], ?MODULE, ?null, ?null},
	FunDatas2	= generate_rate_list(get_rate_list, Ver),
	misc_app:make_gener(data_kb_treasure, 
						[], 
						[FunDatas1, FunDatas2], Ver).


%%
change_to_turn_list(Data) ->
    change_to_turn_list(Data, []).

change_to_turn_list([D|Tail], OldList) ->
    case lists:member(D#rec_kb_treasure.config_id, OldList) of
        ?false ->
            change_to_turn_list(Tail, [D#rec_kb_treasure.config_id|OldList]);
        _ ->
            change_to_turn_list(Tail, OldList)
    end;
change_to_turn_list([], List) ->
    lists:sort(List).

%%
get_level_list(List) ->
	get_level_list(List, []).
get_level_list([D|List], Acc) ->
	case lists:member(D#rec_kb_treasure.level, Acc) of
		?true ->
			get_level_list(List, Acc);
		?false ->
			get_level_list(List, [D#rec_kb_treasure.level | Acc])
	end;
get_level_list([], Acc) ->
	lists:reverse(Acc).

generate_rate_list(FunName, Ver) ->
	Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/kb_treasure/kb_treasure.yrl"),
	IdList = change_to_turn_list(Datas),
	generate_turn_group_info(FunName, Datas, IdList, []).
generate_turn_group_info(FunName, Datas, [Id|IdList], Acc) ->
	List = lists:filter(fun(D) -> D#rec_kb_treasure.config_id =:= Id end, Datas),
	LevelList = get_level_list(List),
	F = fun(Level, Acc2) ->
				Key = {Id, Level},
				Value = [{Data#rec_kb_treasure.idx, Data#rec_kb_treasure.weight} || Data <- List, Data#rec_kb_treasure.level =:= Level],
				Sum = lists:sum([E || {_, E} <- Value]),
				When = ?null,
				[{Key, {Value, Sum}, When} | Acc2]
		end,
	A = lists:foldl(F, [], LevelList),
	generate_turn_group_info(FunName, Datas, IdList, lists:append(A, Acc));
generate_turn_group_info(FunName, _Datas, [], Acc) -> {FunName, lists:sort(Acc)}.


