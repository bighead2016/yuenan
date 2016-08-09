%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to boss_data_generator
-module(camp_pvp_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
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
%% camp_pvp_data_generator:generate().
generate(Ver) ->
	FunDatas1	= generate_camp_pvp_config(get_camp_pvp_config, Ver),
    FunDatas2   = generate_camp_pvp_recource(get_camp_pvp_recource, Ver),
    FunDatas3   = generate_camp_pvp_type(get_camp_pvp_award, Ver),
    FunDatas4   = generate_camp_pvp_monster(get_camp_pvp_monster, Ver),
    FunDatas5   = generate_camp_pvp_event(get_camp_pvp_event, Ver),
    FunDatas6   = generate_camp_pvp_data(get_camp_pvp_data, Ver),
    FunDatas7   = generate_shop(get_shop, Ver),
	misc_app:write_erl_file(data_camp_pvp,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
							 "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6, FunDatas7], Ver).

%% 竞技场-兑换商店
generate_shop(FunName, Ver) ->
    MapDatas = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_shop.yrl"),
    generate_shop(FunName, MapDatas, []).

generate_shop(FunName, [Data|Datas], Acc) when is_record(Data, rec_camp_pvp_shop) ->
    Key     = Data#rec_camp_pvp_shop.id,
    Value   = Data,
    When    = ?null,
    generate_shop(FunName, Datas, [{Key, Value, When}|Acc]);
generate_shop(FunName, [], Acc) -> {FunName, Acc}.

generate_camp_pvp_config(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_config.yrl"),
    generate_camp_pvp_config(FunName, Datas, []).
generate_camp_pvp_config(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_camp_pvp_config.camp_id,
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_config(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_config(FunName, [], Acc) -> {FunName, Acc}.

generate_camp_pvp_recource(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_resource.yrl"),
    generate_camp_pvp_recource(FunName, Datas, []).
generate_camp_pvp_recource(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_camp_pvp_resource.type,
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_recource(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_recource(FunName, [], Acc) -> {FunName, Acc}.


generate_camp_pvp_type(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_award.yrl"),
    generate_camp_pvp_type(FunName, Datas, []).
generate_camp_pvp_type(FunName, [Data|Datas], Acc) ->
    Key         = {Data#rec_camp_pvp_award.type, Data#rec_camp_pvp_award.value},
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_type(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_type(FunName, [], Acc) -> {FunName, Acc}.

generate_camp_pvp_monster(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_monster.yrl"),
    generate_camp_pvp_monster(FunName, Datas, []).
generate_camp_pvp_monster(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_camp_pvp_monster.monster_id,
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_monster(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_monster(FunName, [], Acc) -> {FunName, Acc}.

generate_camp_pvp_event(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_event.yrl"),
    generate_camp_pvp_event(FunName, Datas, []).
generate_camp_pvp_event(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_camp_pvp_event.event_id,
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_event(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_event(FunName, [], Acc) -> {FunName, Acc}.


generate_camp_pvp_data(FunName, Ver) ->
    Datas       = misc_app:load_file(?DIR_YRL_ROOT ++ Ver ++ "/camp_pvp/camp_pvp_data.yrl"),
%%     io:format("Datas is ~w", [Datas]),
    generate_camp_pvp_data(FunName, Datas, []).

generate_camp_pvp_data(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_camp_pvp_data.index,
    Value       = Data,
    When        = ?null,
    generate_camp_pvp_data(FunName, Datas, [{Key, Value, When}|Acc]);
generate_camp_pvp_data(FunName, [], Acc) -> {FunName, Acc};
generate_camp_pvp_data(FunName, Data, Acc) ->
    Key         = Data#rec_camp_pvp_data.index,
    Value       = Data,
    When        = ?null,
    {FunName, [{Key, Value, When}|Acc]}.

%%
%% Local Functions
%%