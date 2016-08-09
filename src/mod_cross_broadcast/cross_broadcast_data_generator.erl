%% author: xujingeng
%% create: 2013-11-27
%% desc: 跨服模块开关配置
%%

-module(cross_broadcast_data_generator).
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
%% cross_broadcast_data_generator:generate().
generate(Ver)	->
	FunDatas = {get_mod_handler_sw, "mod_switch", "mod_switch.yrl", [#rec_mod_switch.id], ?MODULE, ?null, ?null},
	misc_app:make_gener(data_cross_broadcast,
							[],
							[FunDatas], Ver).

%%
%% Local Functions
%%
