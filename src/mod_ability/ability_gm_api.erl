
-module(ability_gm_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
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
        up_top_2(Player, 1, Info#info.lv)
    catch
        X:Y ->
            ?MSG_ERROR("1[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            Player
    end.

up_top_2(Player, AbilityId, Lv) when AbilityId =< 8 ->
    Abi = (Player#player.ability)#ability_data.ability,
    {_, _, AbiLv} = ability_mod:get_ability(AbilityId, Abi),
    Count = 
        if
            AbiLv =< Lv ->
                Lv - AbiLv + 1;
            ?true ->
                0
        end,
    Player2 = up_top_3(Player, AbilityId, Count, AbiLv),
    up_top_2(Player2, AbilityId+1, Lv);
up_top_2(Player, _, _) ->
    Player.

up_top_3(Player, AbilityId, Count, CurLv) when Count > 0 ->
    Player2 = up_top(Player, AbilityId, CurLv),
    up_top_3(Player2, AbilityId, Count-1, CurLv+1);
up_top_3(Player, _, _, _) ->
    Player.

up_top(Player, AbilityId, CurLv) ->
    NewPlayer = 
        case data_ability:get_ability({AbilityId, CurLv+1}) of
            #rec_ability{cost = Cost, meritorious = M} ->
                {?ok, Player2} = player_api:plus_meritorious(Player, M),
                player_money_api:plus_money(Player2#player.user_id, ?CONST_SYS_CASH, Cost, ?CONST_COST_GM_CHAT),
                case ability_mod:upgrade(Player2, AbilityId) of
                    {?ok, Player3} ->  Player3;
                    {?error, _} -> Player2
                end;
            _ ->
                Player
        end,
    R = CurLv rem 20,
    if
        0 =:= R andalso CurLv > 0 ->
            P = 
                case ability_mod:refresh_ability_ext(NewPlayer, AbilityId, trunc(CurLv div 20)) of
                    {?ok, NewPlayer2} ->  NewPlayer2;
                    {?error, _} -> NewPlayer
                end,
%%             misc:sleep(6000),
            P;
        ?true ->
            NewPlayer
    end.
    

%%
%% Local Functions
%%

