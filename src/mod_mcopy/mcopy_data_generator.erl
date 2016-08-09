
%%% 多人副本数据生成器
-module(mcopy_data_generator).

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

generate(Ver) ->
	FunDatas1 = generate_mcopy(get_mcopy, Ver),
	FunDatas2 = generate_mcopy_serial(get_mcopy_serial, Ver),
	FunDatas3 = generate_mcopy_list(get_mcopy_list, Ver),
	FunDatas4 = generate_mcopy_id(get_mcopy_id, Ver),
	FunDatas5 = generate_encounter(get_encounter, Ver),
	misc_app:write_erl_file(data_mcopy,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5], Ver).

%% 副本信息
generate_mcopy(FunName, Ver) ->
	McopyDatas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mcopy/mcopy.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
	generate_mcopy(FunName, McopyDatas, []).
generate_mcopy(FunName, [Data|Datas], Acc) when is_record(Data, rec_mcopy) ->
	Key		= Data#rec_mcopy.map,
	Value	= Data,
	When	= ?null,
	generate_mcopy(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mcopy(FunName, [], Acc) -> {FunName, Acc}.

%% 副本系列信息
generate_mcopy_serial(FunName, Ver) ->
    McopySerDatas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mcopy/mcopy_serial.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
    McopyDatas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mcopy/mcopy.yrl") of
            Data2 when is_list(Data2) ->
                Data2;
            Data2 ->
                [Data2]
        end,
    generate_mcopy_serial(FunName, McopyDatas, McopySerDatas, []).
generate_mcopy_serial(FunName, McopyDatas, [Data|Datas], Acc) when is_record(Data, rec_mcopy_serial) ->
    Key     = Data#rec_mcopy_serial.id,
    List    = Data#rec_mcopy_serial.mcopy_list,
    List2   = change_mcopy_list(List, McopyDatas, []),
    Value   = change_mcopy_ser(Data, List2),
    When    = ?null,
    generate_mcopy_serial(FunName, McopyDatas, Datas, [{Key, Value, When}|Acc]);
generate_mcopy_serial(FunName, _McopyDatas, [], Acc) -> {FunName, Acc}.

%% 封装副本系列下的副本列表
change_mcopy_list([Id|Tail], McopyDatas, ResultList) ->
    {NewResultList, NewMcopyDatas} = 
        case lists:keytake(Id, #rec_mcopy.id, McopyDatas) of
            {value, RecMCopy, McopyDatas2} ->
                {[RecMCopy|ResultList], McopyDatas2};
            ?false ->
                {ResultList, McopyDatas}
        end,
    change_mcopy_list(Tail, NewMcopyDatas, NewResultList);
change_mcopy_list([], _McopyDatas, ResultList) ->
    lists:reverse(ResultList).

%% 封装副本系列
change_mcopy_ser(MCopySer, MCopyList) ->
    #rec_mcopy_serial{id = Id, daily_count = DailyCount, 
                      exp = Exp, gold_bind = GoldBind,
                      goods = GoodsDropId, lv_min = LvMin, module = Module,
                      meritorious = Meritorious, need_sp = NeedSp, standard_time= StandardTime} = MCopySer,
    #mcopy_serial{id = Id, daily_count = DailyCount,
                  exp = Exp, gold_bind = GoldBind,
                  goods = GoodsDropId, lv_min = LvMin, module = Module,
                  meritorious = Meritorious, mcopy_list = MCopyList,
                  need_sp = NeedSp, standard_time = StandardTime}.
        
%% 副本列表
generate_mcopy_list(FunName, Ver) ->
    McopyDatas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mcopy/mcopy_serial.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
    generate_mcopy_list_2(FunName, McopyDatas).
generate_mcopy_list_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [MCopy#rec_mcopy_serial.id||MCopy <- Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

generate_mcopy_id(FunName, Ver) ->
	DataList = misc_app:get_data_list(Ver ++ "/mcopy/mcopy_serial.yrl"),
    generate_mcopy_id(FunName, DataList, []).
generate_mcopy_id(FunName, [Data|Datas], Acc) when is_record(Data, rec_mcopy_serial) ->
    Key     = Data#rec_mcopy_serial.module,
    Value   = Data#rec_mcopy_serial.id,
    When    = ?null,
    generate_mcopy_id(FunName, Datas, [{Key, Value, When}|Acc]);
generate_mcopy_id(FunName, [], Acc) -> {FunName, Acc}.

%% 奇遇信息
generate_encounter(FunName, Ver) ->
    EncounterDatas = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/mcopy/encounter.yrl") of
            Data when is_list(Data) ->
                Data;
            Data ->
                [Data]
        end,
    generate_encounter(FunName, EncounterDatas, []).
generate_encounter(FunName, [Data|Datas], Acc) when is_record(Data, rec_encounter) ->
    Key     = Data#rec_encounter.id,
    Value   = Data,
    When    = ?null,
    generate_encounter(FunName, Datas, [{Key, Value, When}|Acc]);
generate_encounter(FunName, [], Acc) -> {FunName, Acc}.

%%
%% Local Functions
%%