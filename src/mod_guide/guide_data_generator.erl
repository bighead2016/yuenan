%% Author: Administrator
%% Created: 2012-10-22
%% Description: TODO: Add description to guide_data_generator
-module(guide_data_generator).

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
generate(Ver) ->
	FunDatas1 = generate_guide(get_guide, Ver),
	FunDatas2 = generate_guide_rank(get_guide_rank, Ver),
	FunDatas3 = generate_money(get_money, Ver),
	FunDatas4 = generate_module_list(get_module_list, Ver),
    FunDatas5 = generate_tast_rank(get_task_rank, Ver),
    FunDatas6 = generate_sys_id(get_sys_id, Ver),
    FunDatas7 = generate_sys_id_by_rank_id(get_sys_id_by_rank_id, Ver),
	misc_app:write_erl_file(data_guide,
							["../../include/const.common.hrl",
							 "../../include/record.base.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6, FunDatas7], Ver).

%% 玩家状态
generate_sys_id_by_rank_id(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver ++ "/sys/sys.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_sys_id_by_rank_id(FunName, DatasGuide2, DatasGuide2, []).
generate_sys_id_by_rank_id(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_sys) ->
    Key     = Data#rec_sys.open_rank,
    Value   = Data#rec_sys.module,
    When    = ?null,
    generate_sys_id_by_rank_id(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_sys_id_by_rank_id(FunName, [], _, Acc) -> {FunName, Acc}.

%% 玩家状态
generate_sys_id(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver ++ "/sys/sys.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_sys_id(FunName, DatasGuide2, DatasGuide2, []).
generate_sys_id(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_sys) ->
    Key     = Data#rec_sys.point,
    Value   = Data#rec_sys.module,
    When    = ?null,
    generate_sys_id(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_sys_id(FunName, [], _, Acc) -> 
    Acc2 = [{A,B,C}||{A,B,C}<-Acc, A =/= 0],
    Acc3 = [{0,0,?null}|Acc2],
    {FunName, Acc3}.


%% 玩家状态
generate_tast_rank(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver ++ "/sys/sys.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_tast_rank(FunName, DatasGuide2, DatasGuide2, []).
generate_tast_rank(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_sys) ->
    Key     = Data#rec_sys.module,
    Value   = Data#rec_sys.open_rank,
    When    = ?null,
    generate_tast_rank(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_tast_rank(FunName, [], _, Acc) -> {FunName, Acc}.

%% 玩家状态
generate_guide(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver ++ "/sys/sys.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_guide(FunName, DatasGuide2, DatasGuide2, []).
generate_guide(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_sys) ->
    Key     = Data#rec_sys.module,
    Value   = [D#rec_sys.point||D <- Datas2, D#rec_sys.module =:= Key],
    When    = ?null,
    generate_guide(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_guide(FunName, [], _, Acc) -> {FunName, Acc}.

%% 玩家状态
generate_guide_rank(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver ++ "/sys/sys.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_guide_rank(FunName, DatasGuide2, DatasGuide2, []).
generate_guide_rank(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_sys) ->
    Key     = Data#rec_sys.open_rank,
    Value   = Data#rec_sys.point, %[D#rec_sys.point||D <- Datas2, D#rec_sys.module =:= Key],
    When    = ?null,
    generate_guide_rank(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_guide_rank(FunName, [], _, Acc) -> {FunName, Acc}.

%% 玩家状态
generate_money(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver++"/sys/novice_money.yrl"),
    DatasGuide2 = lists:reverse(DatasGuide),
    generate_money(FunName, DatasGuide2, DatasGuide2, []).
generate_money(FunName, [Data|Datas], Datas2, Acc) when is_record(Data, rec_novice_money) ->
    Key     = Data#rec_novice_money.guide_id,
    Value   = {Data#rec_novice_money.gold, Data#rec_novice_money.bcash},
    When    = ?null,
    generate_money(FunName, Datas, Datas2, [{Key, Value, When}|Acc]);
generate_money(FunName, [], _, Acc) -> {FunName, Acc}.


generate_module_list(FunName, Ver) ->
    DatasGuide  = misc_app:get_data_list(Ver++"/sys/sys.yrl"),
    generate_module_list_2(FunName, DatasGuide).
generate_module_list_2(FunName, DatasGuide) ->
    Key     = ?null,
    Value   = [{D#rec_sys.module, D#rec_sys.name}||D <- DatasGuide],
    When    = ?null,
	{FunName, [{Key, Value, When}]}.
%%
%% Local Functions
%%

