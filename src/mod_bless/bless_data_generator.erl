-module(bless_data_generator).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
-export([change_bless_data/1]).

%%
%% API Functions
%%
%%
%% bless_data_generator:generate().
generate(Ver) ->
	FunDatas1  = {get_bless, "bless", "bless.yrl", [#rec_bless.lv], ?MODULE, change_bless_data, ?null},
    FunDatas2  = {get_bcopy, "bless", "bless_copy.yrl", [#rec_bless_copy.copy_id, #rec_bless_copy.type], ?MODULE, ?null, ?null},
	misc_app:make_gener(data_bless,
							[],
							[FunDatas1, FunDatas2], Ver).

%%
change_bless_data(Data) ->
    Data#rec_bless.exp.
