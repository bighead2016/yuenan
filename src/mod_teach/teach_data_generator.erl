-module(teach_data_generator).

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
-export([generate/1,gen_anwser/1]).
%%
%% API Functions
%%

%% teach_data_generator:generate().
generate(Ver) ->
    FunDatas1   = {get_teach, "teach", "teach.yrl", [#rec_teach.type, #rec_teach.pass_id, #rec_teach.pro], ?MODULE, ?null, ?null},
	FunDatas2   = {get_teach_ans, "teach", "teach.yrl", [#rec_teach.pass_id], ?MODULE,gen_anwser,?null},
    misc_app:make_gener(data_teach, 
                        [], 
                        [FunDatas1,FunDatas2], Ver).
gen_anwser(Teach) ->
	{Teach#rec_teach.answer, Teach#rec_teach.q_goods}.