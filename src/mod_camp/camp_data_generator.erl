%% Author: Administrator
%% Created: 2012-7-25
%% Description: TODO: Add description to camp_data_generator
-module(camp_data_generator).

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
-export([change_camp_list/1]).

%%
%% API Functions
%%

%% camp_data_generator:generate().
generate(Ver) ->
	FunDatas1 = {get_camp, "camp", "camp.yrl", [#rec_camp.camp_id, #rec_camp.lv], ?MODULE, ?null, ?null},
    FunDatas2 = {get_camp_list, "camp", "camp.yrl", ?null, ?MODULE, change_camp_list, ?null},
	misc_app:make_gener(data_camp,
							[],
							[FunDatas1, FunDatas2], Ver).

change_camp_list(Data) ->
    change_camp_list(Data, []).

change_camp_list([#rec_camp{lv = 1, camp_id = CampId, lv_min = LvMin}|Tail], OldList) ->
    change_camp_list(Tail, [{CampId, LvMin}|OldList]);
change_camp_list([_|Tail], OldList) ->
    change_camp_list(Tail, OldList);
change_camp_list([], List) ->
    List.

