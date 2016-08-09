%% Author: yskj
%% Created: 2013-11-12
%% Description: TODO: Add description to y_
-module(y_).

%%
%% Include files
%%
-define(LOG(Format, Data),              % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE] ++ Data)). 
-define(COUNT, 1).

%%
%% Exported Functions
%%
-export([run/0]).


%%
%% API Functions
%%

run() ->
    run(?COUNT, ?COUNT).

run(N, Max) when N > 0 ->
    timer:sleep(500),
    y:start_link(N),
    y:do(N, login),
    run(N-1, Max);
run(_, Max) ->
    run_2(Max).

run_2(Max) ->
%%     timer:sleep(10000),
    
%%     jump_out(Max),
%%     timer:sleep(100000),
    
    Seq = lists:seq(1, Max),
    do_run(Seq, Seq),
    ok.
%% 
%% jump_out(N) when N > 0 ->
%%     timer:sleep(500),
%%     y:start_link(N),
%%     y:do(N, 8001, {1, <<"- 跳过">>}),
%% %%     do_task(N),
%%     jump_out(N-1);
%% jump_out(_) ->
%%     ok.

do_run([AccId|Tail], List) ->
    walk_around(AccId),
    do_run(Tail, List);
do_run([], List) ->
    timer:sleep(1000),
    do_run(List, List).

walk_around(AccId) ->
%%     PointList = [{600,630}, {1100,630}, {1530,630}, {2220, 600}],
%%     R = random(1,4),
%%     {X, Y} = lists:nth(R, PointList),
    X = random(600, 2220),
    Y = random(550, 680),
    y:do(AccId, 5021, {AccId, X, Y}).

%% do_task(AccId) ->
%%     y:do(AccId, 8001, {1, <<"- 设置等级  5">>}),
%%     y:do(AccId, 8001, {1, <<"- go">>}).
%%     y:do(AccId, 8001, {1, <<"- 设置等级 5">>}),
%%     y:do(AccId, 8001, {1, <<"- 充值 9999">>}),
%%     y:do(AccId, 8001, {1, <<"- 扩展背包">>}),
%%     y:do(AccId, 8001, {1, <<"- 接任务 10058">>}).

%%
%% Local Functions
%%
%% 随机数：[1...Integer]
random(Integer)->
    random:uniform(Integer).

%% 随机数：[Min...Max]
random(Min, Min)-> Min;
random(Min, Max) when Min > Max->
    random(Max, Min);
random(Min, Max)->
    Min2 = Min - 1,
    random(Max - Min2) + Min2.
