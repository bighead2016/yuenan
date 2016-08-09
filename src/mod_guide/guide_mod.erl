%% Author: Administrator
%% Created: 2012-10-22
%% Description: TODO: Add description to guide_mod
-module(guide_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([add_module/2, finish_module/2, init/2, flag_got/3]).

%%
%% API Functions
%%
init([GuideId|Tail], GuideList) ->
    NewGuideList = add_module(GuideList, GuideId),
    init(Tail, NewGuideList);
init([], GuideList) ->
    GuideList.

add_module(GuideList, ModuleList) when is_list(ModuleList) ->
    F = fun(Module, OldList) ->
                G = add_module(GuideList, Module),
                G ++ OldList
        end,
    lists:foldl(F, [], ModuleList);
add_module(GuideList, Module) ->
    case lists:keyfind(Module, #guide.module, GuideList) of
        ?false -> 
              Guide = #guide{module = Module, state = ?CONST_GUIDE_OPENED, is_got = ?CONST_SYS_FALSE},
%%               Guide = #guide{module = Module, state = ?CONST_GUIDE_FINISHED}, % XXX 测试用
              [Guide|GuideList];
        _Tuple -> 
              GuideList
    end.

finish_module(GuideList, 0) ->
    GuideList;
finish_module(GuideList, ?null) ->
    GuideList;
finish_module(GuideList, Module) ->
	case lists:keytake(Module, #guide.module, GuideList) of
        ?false ->
            Guide = #guide{module = Module, state = ?CONST_GUIDE_FINISHED},
            [Guide|GuideList];
        {value, Guide, GuideList2}  ->
            NewGuid = Guide#guide{state = ?CONST_GUIDE_FINISHED},
            [NewGuid|GuideList2]
    end.

flag_got(UserId, GuideList, Module) ->
    case lists:keytake(Module, #guide.module, GuideList) of
        ?false ->
            Guide = #guide{module = Module, is_got = ?CONST_SYS_TRUE},
            reward(UserId, Module),
            [Guide|GuideList];
        {value, Guide = #guide{is_got = ?CONST_SYS_FALSE}, GuideList2}  ->
            NewGuid = Guide#guide{is_got = ?CONST_SYS_TRUE},
            reward(UserId, Module),
            [NewGuid|GuideList2];
        _ ->
            GuideList
    end.

read_reward(Module) ->
    case data_guide:get_money(Module) of
        {Gold, BCash} ->
            {Gold, BCash};
        _ ->
            {0,0}
    end.

%%
%% Local Functions
%%
reward(UserId, Module) ->
    {Gold, BCash} = read_reward(Module),
    if
        is_number(Gold) andalso 0 < Gold -> 
            player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_GUIDE_REWARD),
            player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, BCash, ?CONST_COST_GUIDE_REWARD);
        ?true ->
            ?ok
    end.
