%%% 

-module(goods_data_analyzer).

-include("const.common.hrl").
-include("record.goods.data.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([analyze/1]).

analyze(_Ver) ->
    L = data_goods:get_goods_list(),
    is_rep(L, []).

is_rep([G|Tail], OL) ->
    case lists:member(G, OL) of
        true ->
            case data_goods:get_goods(G) of
                #goods{type = Type, sub_type = SubType} ->
                    ?MSG_SYS("rep goods_id[~p|~p|~p]", [G, Type, SubType]);
                _ ->
                    ?MSG_SYS("rep goods_id[~p] && no this goods", [G])
            end;
        false ->
            ok
    end,
    is_rep(Tail, [G|OL]);
is_rep([], _) ->
    ok.

%% ====================================================================
%% Internal functions
%% ====================================================================

