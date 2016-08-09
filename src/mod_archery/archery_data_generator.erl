%% @author liuyujian

-module(archery_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).

%%
%% API Functions
%%

%% archery_data_generator:generate().
generate(Ver) ->
    FunDatas1 = generate_courtInfo(get_court_info, Ver),
    FunDatas2 = generate_bonus(get_archery_bonus, Ver),
    misc_app:write_erl_file(data_archery,
                            [],
                            [FunDatas1,FunDatas2], Ver).

generate_courtInfo(FunName, Ver) ->
    CourtData = misc_app:get_data_list(Ver++ "/archery/archery_place.yrl"),
%%     io:format("CourtData:~p~n", [CourtData]),
    generate_courtInfo(FunName, CourtData, []).
generate_courtInfo(FunName, [Data|Datas], Acc) ->
    Key     = element(2, Data),
    Value   = element(3, Data),
    When    = ?null,
%%     io:format("{Key, Value, When}:~p~n", [{Key, Value, When}]),
    generate_courtInfo(FunName, Datas, [{Key, Value, When}|Acc]);
generate_courtInfo(FunName, [], Acc) -> {FunName, Acc}.

generate_bonus(FunName, Ver) ->
    Bonus = misc_app:get_data_list(Ver++"/archery/archery_bonus.yrl"),
    gererate_bonus(FunName, Bonus, []).

gererate_bonus(FunName, [], Acc) -> {FunName, Acc};
gererate_bonus(FunName, [Data|Datas], Acc) ->
    Key     = Data#rec_archery_bonus.rank,
    Value   = {Data#rec_archery_bonus.good,Data#rec_archery_bonus.coins,Data#rec_archery_bonus.meritorious},
    When    = ?null ,
    gererate_bonus(FunName, Datas, [{Key, Value, When}|Acc]).
