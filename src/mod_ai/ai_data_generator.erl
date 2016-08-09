%% Author: Administrator
%% Created: 2012-12-17
%% Description: TODO: Add description to ai_data_generator
-module(ai_data_generator).
%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_ai/1]).
%%
%% API Functions
%%
%% ai_data_generator:generate().
generate(Ver) ->
	FunDatas1  = {get_base_ai, "ai", "ai.yrl", [#rec_ai.id], ?MODULE, ?null, ?null},
	FunDatasA1 = {get_ai_list, "ai", "ai.yrl", ?null, ?MODULE, change_ai, ?null},
	misc_app:make_gener(data_ai,
							[],
							[FunDatas1, FunDatasA1], Ver).

%% id列表
change_ai(Data) ->
    change_ai(Data, []).

change_ai([Rec|Tail], OldList) ->
    change_ai(Tail, [Rec#rec_ai.id|OldList]);
change_ai([], List) ->
    List.
