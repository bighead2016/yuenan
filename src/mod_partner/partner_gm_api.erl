%% Author: yskj
%% Created: 2014-1-23
%% Description: TODO: Add description to partner_gm_api
-module(partner_gm_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([up_top/1]).

%%
%% API Functions
%%

up_top(Player) ->
    try
        Info = Player#player.info,
        
        Pl = partner_api:get_all_partner(Player),
        up_top_2(Player, [Player|Pl], Info#info.lv)
    catch
        X:Y ->
            ?MSG_ERROR("1[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            Player
    end.

up_top_2(Player, [#partner{partner_id = PartnerId, train = TrainLevel}|Tail], Lv) ->
    Player2 = up_top_3(Player, PartnerId, TrainLevel),
    up_top_2(Player2, Tail, Lv);
up_top_2(Player, [#player{train = TrainLevel}|Tail], Lv) ->
    Player2 = up_top_3(Player, 0, TrainLevel),
    up_top_2(Player2, Tail, Lv);
up_top_2(Player, _, _) ->
    Player.

up_top_3(#player{info = #info{lv = Lv}} = Player, PartnerId, TrainLevel) when Lv > TrainLevel ->
    Rec = data_partner:get_train(TrainLevel + 1),
    Count = Rec#rec_train_rate.cost_cout,
    GoodsList = goods_api:make(?CONST_PARTNER_TRAIN_ITEM, Count),
    {?ok, Player2, _Changelist, _Packet} = ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GM_CHAT, 0, 1, 0, 0, 1, 1, []),
    
    Player4 = 
        case partner_api:train(Player2, PartnerId) of
            {?ok, Player3} ->
                Player3;
            _ ->
                Player2
        end,
    case PartnerId of
        0 ->
            TrainLevel2 = Player4#player.train,
            up_top_3(Player4, PartnerId, TrainLevel2);
        _ ->
            {?ok, Partner} = partner_api:get_partner_by_id(Player4, PartnerId),
            up_top_3(Player4, PartnerId, Partner#partner.train)
    end;
up_top_3(Player, _, _) ->
    Player.

%%
%% Local Functions
%%

