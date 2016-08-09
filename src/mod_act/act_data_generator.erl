
-module(act_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1, change_to_list/1, change_to_turn_list/1, limit_mall_goods/1]).

%%
%% API Functions
%%

%% act_data_generator:generate("zh_CN").
generate(Ver) ->  
    FunDatas1   = {get_act, "act", "act_time.yrl", [#rec_act_time.id], ?MODULE, ?null, ?null},
    FunDatas2   = {get_act_list, "act", "act_time.yrl", ?null, ?MODULE, change_to_list, ?null},
    FunDatas3   = {get_act_turn, "act", "act_turn.yrl", [#rec_act_turn.config_id, #rec_act_turn.idx], ?MODULE, ?null, ?null},
    FunDatas4   = {get_act_turn_list, "act", "act_turn.yrl", ?null, ?MODULE, change_to_turn_list, ?null},
    FunDatas5   = generate_turn_info(get_turn_info, Ver),
    FunDatas6   = generate_temp(get_temp, Ver),
	FunDatas7   = {get_limit_mall, "limit_mall", "limit_mall.yrl", [#rec_limit_mall.id], ?MODULE, limit_mall_goods, ?null},
    misc_app:make_gener(data_act, 
                        [], 
                        [FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5,
                         FunDatas6
						, FunDatas7], Ver).

change_to_list(Data) ->
    change_to_list(Data, []).

change_to_list([D|Tail], OldList) ->
    change_to_list(Tail, [D#rec_act_time.id|OldList]);
change_to_list([], List) ->
    lists:reverse(List).

%%
change_to_turn_list(Data) ->
    change_to_turn_list(Data, []).

change_to_turn_list([D|Tail], OldList) ->
    case lists:member(D#rec_act_turn.config_id, OldList) of
        ?false ->
            change_to_turn_list(Tail, [D#rec_act_turn.config_id|OldList]);
        _ ->
            change_to_turn_list(Tail, OldList)
    end;
change_to_turn_list([], List) ->
    lists:sort(List).
    
%%
generate_turn_info(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/act/act_turn.yrl"),
    IdList = change_to_turn_list(Datas),
    generate_turn_info(FunName, Datas, IdList, []).
generate_turn_info(FunName, Rem, [Id|Tail], Acc) ->
    Rem2 = [D||#rec_act_turn{} = D <- Rem, D#rec_act_turn.config_id =:= Id],
    L1 = change_turn_1(Rem2, []),
    L2 = change_turn_2(Rem2, []),
    L = [{{Id, 1}, L1, ?null}, {{Id, 2}, L2, ?null}],
    generate_turn_info(FunName, Rem, Tail, Acc++L);
generate_turn_info(FunName, _Rem, [], Acc) ->
    {FunName, Acc}.

change_turn_1([#rec_act_turn{idx = Idx, weight_1 = W1}|Tail], List) ->
    change_turn_1(Tail, [{Idx, W1}|List]);
change_turn_1([], List) ->
    misc_random:odds_list_init(?MODULE, ?LINE, List, 10000).

change_turn_2([#rec_act_turn{idx = Idx, weight_2 = W2}|Tail], List) ->
    change_turn_2(Tail, [{Idx, W2}|List]);
change_turn_2([], List) ->
    misc_random:odds_list_init(?MODULE, ?LINE, List, 10000).

%% 
generate_temp(FunName, Ver) ->
    Datas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/act/act_time.yrl"),
    IdList = change_to_temp_list(Datas),
    generate_temp(FunName, Datas, IdList, []).
generate_temp(FunName, Datas, [Id|Tail], Acc) ->
    Rem2    = [D||D <- Datas, D#rec_act_time.template =:= Id],
    Key     = Id,
    Value   = [D#rec_act_time.id||D <- Rem2],
    When    = ?null,
    generate_temp(FunName, Datas, Tail, [{Key, Value, When}|Acc]);
generate_temp(FunName, _, [], Acc) -> {FunName, lists:reverse(Acc)}.

change_to_temp_list(Data) ->
    change_to_temp_list(Data, []).

change_to_temp_list([D|Tail], OldList) ->
    case lists:member(D#rec_act_time.config_id, OldList) of
        ?false ->
            change_to_temp_list(Tail, [D#rec_act_time.config_id|OldList]);
        _ ->
            change_to_temp_list(Tail, OldList)
    end;
change_to_temp_list([], List) ->
    lists:sort(List).

limit_mall_goods(Record) when is_record(Record, rec_limit_mall) ->
	Record#rec_limit_mall.gooods.

