%% Author: Administrator
%% Created: 2012-7-25
%% Description: TODO: Add description to ability_data_generator
-module(ability_data_generator).

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
-export([change_ability_ext/1]).

%%
%% API Functions
%%

%% ability_data_generator:generate().
generate(Ver) ->
    FunDatas1   = {get_ability, "ability", "ability.yrl", [#rec_ability.ability_id, #rec_ability.lv], ?MODULE, ?null, ?null},
	FunDatas2 	= generate_ability_ext_id(get_ability_ext_id, Ver),
	FunDatas3 	= {get_ability_ext, "ability", "ability.ext.yrl", [#rec_ability_ext.ability_ext_id], ?MODULE, ?null, ?null},
	FunDatasA1 	= {get_ability_ext_id_list, "ability", "ability.ext.yrl", ?null, ?MODULE, change_ability_ext, ?null},
    misc_app:make_gener(data_ability, 
                        [], 
                        [FunDatas1, FunDatas2, FunDatas3, FunDatasA1], Ver).

generate_ability_ext_id(FunName, Ver) ->
    AbilityDatas 	= misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/ability/ability.yrl"),
	MappingDatas	= change_ability_ext_mapping(AbilityDatas, []),
    generate_ability_ext_id(FunName, MappingDatas, []).
generate_ability_ext_id(FunName, [{Key, Value}|Datas], Acc) ->
    When    = ?null,
    generate_ability_ext_id(FunName, Datas, [{Key, Value, When}|Acc]);
generate_ability_ext_id(FunName, [], Acc) -> {FunName, Acc}.

change_ability_ext_mapping([Data|Datas], Acc) ->
	case Data#rec_ability.ext_id of
		0 -> change_ability_ext_mapping(Datas, Acc);
		ExtId ->
			AbilityId	= Data#rec_ability.ability_id,
			case lists:keytake(AbilityId, 1, Acc) of
				{value, {AbilityId, List}, AccTemp} ->
					change_ability_ext_mapping(Datas, [{AbilityId, [{Data#rec_ability.lv, ExtId}|List]}|AccTemp]);
				?false ->
					change_ability_ext_mapping(Datas, [{AbilityId, [{Data#rec_ability.lv, ExtId}]}|Acc])
			end
	end;
change_ability_ext_mapping([], Acc) ->
	change_ability_ext_mapping2(Acc, []).
change_ability_ext_mapping2([{AbilityId, List}|Datas], Acc) ->
	List2	= lists:keysort(1, List),
	Acc2	= change_ability_ext_mapping3(AbilityId, List2, 1, []),
	change_ability_ext_mapping2(Datas, Acc2 ++ Acc);
change_ability_ext_mapping2([], Acc) -> Acc.

change_ability_ext_mapping3(AbilityId, [{_Lv, ExtId}|List], Count, Acc) ->
	change_ability_ext_mapping3(AbilityId, List, Count + 1, [{{AbilityId, Count}, ExtId}|Acc]);
change_ability_ext_mapping3(_AbilityId, [], _Count, Acc) -> Acc.

%%
change_ability_ext(Data) ->
    change_ability_ext(Data, []).

change_ability_ext([D|Tail], OldList) ->
    change_ability_ext(Tail, [D#rec_ability_ext.ability_ext_id|OldList]);
change_ability_ext([], List) ->
    List.
