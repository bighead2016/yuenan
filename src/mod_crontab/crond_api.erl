%% Author: cobain
%% Created: 2012-7-10
%% Description: TODO: Add description to crond_api
-module(crond_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
%%
%% Exported Functions
%%
-export([reload/0]).
-export([clock_add/9, clock_del/1, clock_list/0]).
-export([interval_add/5, interval_del/1, interval_list/0]).


%%
%% API Functions
%%
%% crond_api:clock_list().
%% 列出当前任务
clock_list() ->
	crond_serv:clock_list_call().
%% 添加一个任务
clock_add(TaskID,Min,Hour,Day,Month,Week,Module,Function,Args) ->
	crond_serv:clock_add_cast(TaskID, Min, Hour, Day, Month, Week, Module, Function, Args).
%% 删除一个任务(参数要与添加任务时提供的参数相同)
clock_del(TaskId) ->
	crond_serv:clock_del_cast(TaskId).
%% 列出当前任务
%% crond_api:interval_list().
interval_list() ->
	crond_serv:interval_list_call().
%% 添加一个任务
interval_add(TaskID,Interval,Module,Function,Args) ->
	crond_serv:interval_add_cast(TaskID, Interval, Module, Function, Args).
%% 删除一个任务(参数要与添加任务时提供的参数相同)
interval_del(TaskId) ->
	crond_serv:interval_del_cast(TaskId).
%% 重载配置文件
reload() ->
	crond_serv:reload_cast().


%%
%% Local Functions
%%

