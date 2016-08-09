%%% 活动数据格式分析

-module(active_data_analyzer).

%% ====================================================================
%% API functions
%% ====================================================================
-export([analyze/0]).

analyze() ->
    ModList  = data_active:get_active_list(),
    DataList = [data_active:get_active(Mod)||Mod <- ModList],
    misc:check_type(DataList, [
                               atom, atom, number, binary, 
                               list, list, list, list, list, atom, atom, list, 
                               list, list, list, list, list, atom, atom, list
                              ]).

%% ====================================================================
%% Internal functions
%% ====================================================================

