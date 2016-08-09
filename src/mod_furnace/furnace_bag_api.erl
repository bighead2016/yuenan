%%% 造坊背包
-module(furnace_bag_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").

-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([check_goods/2]).

%%
%% API Functions
%%
check_goods(Idx, Ctn) ->
    GoodsTuple = Ctn#ctn.goods,
    case get_idx(Idx, GoodsTuple) of
        #goods{} = Goods ->
            Goods;
        _ ->
            ?null
    end.


%%
%% Local Functions
%%
get_idx(Idx, Tuple) ->
    Len = erlang:size(Tuple),
    if
        Idx =< Len ->
            erlang:element(Idx, Tuple);
        ?true ->
            ?error
    end.
