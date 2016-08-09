%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to player_data_generator
-module(copy_single_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% copy_data_generator:generate().
generate(Ver) ->
	FunDatas1 = {get_copy_single, "map", "copy_single.yrl", [#rec_copy_single.id], ?MODULE, ?null, ?null},
	FunDatas2 = generate_copy_list(get_copy_list, Ver),
	FunDatas3 = generate_copy_list_lv(get_copy_list_lv, Ver),
    FunDatas4 = generate_serial(get_serial, Ver),
    FunDatas5 = generate_serial_list(get_serial_list, Ver),
    FunDatas6 = generate_all(get_all, Ver),
	misc_app:make_gener(data_copy_single,
							[],
							[FunDatas1, FunDatas2, FunDatas3, FunDatas4, FunDatas5, FunDatas6], Ver).

generate_copy_list(FunName, Ver) ->
    CopyDatas   = misc_app:get_data_list(Ver++"/map/copy_single.yrl"),
	LvList		= lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
	generate_copy_list(LvList, FunName, CopyDatas, []).

generate_copy_list([Lv|LvList], FunName, CopyDatas, Acc) ->
	Key		= Lv,
	Value	= [Copy#rec_copy_single.id || Copy <- CopyDatas,
								   is_record(Copy, rec_copy_single),
								   (Copy#rec_copy_single.lv_min =< Lv orelse Copy#rec_copy_single.lv_min =:= 0)],
	When	= ?null,
	generate_copy_list(LvList, FunName, CopyDatas, [{Key, Value, When}|Acc]);
generate_copy_list([], FunName, _CopyDatas, Acc) ->
	{FunName, Acc}.


generate_copy_list_lv(FunName, Ver) ->
	CopyDatas   = misc_app:get_data_list(Ver++"/map/copy_single.yrl"),
	LvList		= lists:seq(1, ?CONST_SYS_PLAYER_LV_MAX),
	generate_copy_list_lv(LvList, FunName, CopyDatas, []).

generate_copy_list_lv([Lv|LvList], FunName, CopyDatas, Acc) ->
	Key		= Lv,
	Value	= [Copy#rec_copy_single.id || Copy <- CopyDatas,
								   is_record(Copy, rec_copy_single),
								   Copy#rec_copy_single.lv_min =< Lv],
	When	= ?null,
	generate_copy_list_lv(LvList, FunName, CopyDatas, [{Key, Value, When}|Acc]);
generate_copy_list_lv([], FunName, _CopyDatas, Acc) ->
	{FunName, Acc}.

generate_serial(FunName, Ver) ->
    Datas   = misc_app:get_data_list(Ver ++"/map/copy_single.yrl"),
    generate_serial(FunName, Datas, []).
generate_serial(FunName, [RecCopySingle|Tail], List) ->
    Key = {RecCopySingle#rec_copy_single.serial_id, RecCopySingle#rec_copy_single.nth},
    Value = RecCopySingle#rec_copy_single.id,
    When = ?null,
    generate_serial(FunName, Tail, [{Key, Value, When}|List]);
generate_serial(FunName, [], List) ->
    {FunName, List}.

generate_serial_list(FunName, Ver) ->
    Datas   = misc_app:get_data_list(Ver ++ "/map/copy_single.yrl"),
    generate_serial_list(FunName, Datas, []).
generate_serial_list(FunName, Datas, List) when Datas =/= [] ->
    [RecCopySingle|_Tail] = Datas,
    Key = RecCopySingle#rec_copy_single.serial_id,
    Value = [D#rec_copy_single.id || D <- Datas, D#rec_copy_single.serial_id =:= Key],
    Datas1_2 = [X || X <- Datas, X#rec_copy_single.serial_id =/= Key],
    When = ?null,
    generate_serial_list(FunName, Datas1_2, [{Key, Value, When}|List]);
generate_serial_list(FunName, [], List) ->
    {FunName, List}.

generate_all(FunName, Ver) ->
    Datas   = misc_app:get_data_list(Ver ++ "/map/copy_single.yrl"),
    generate_all_2(FunName, Datas).
generate_all_2(FunName, Datas) when Datas =/= [] ->
    Key = ?null,
    Value = [D#rec_copy_single.id || D <- Datas],
    When = ?null,
    {FunName, [{Key, Value, When}]}.

%%
%% Local Functions
%%