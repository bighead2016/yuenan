%% Author: Administrator
%% Created: 2012-7-26
%% Description: TODO: Add description to furnace_data_generator
-module(gun_award_data_generator).

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
    % 装备强化
    FunDatas1   = generate_gun_active_award(get_gun_active_award, Ver),
    FunDatas2   = generate_gun_level_award(get_gun_level_award, Ver),
	misc_app:make_gener(data_gun_award,
							[],
							[FunDatas1, FunDatas2], Ver).
generate_gun_active_award(FunName, Ver) ->
    Datas       = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/gun_cash/gun_cash_active.yrl"),
    generate_gun_active_award(FunName, Datas, []).
generate_gun_active_award(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_gun_cash_active.active_id,
    Value       = Data,
    When        = ?null,
    generate_gun_active_award(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gun_active_award(FunName, [], Acc) -> {FunName, Acc}.

generate_gun_level_award(FunName, Ver) ->
    Datas       = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/gun_cash/gun_cash_level.yrl"),
    generate_gun_level_award(FunName, Datas, []).
generate_gun_level_award(FunName, [Data|Datas], Acc) ->
    Key         = Data#rec_gun_cash_level.level,
    Value       = Data,
    When        = ?null,
    generate_gun_level_award(FunName, Datas, [{Key, Value, When}|Acc]);
generate_gun_level_award(FunName, [], Acc) -> {FunName, Acc}.