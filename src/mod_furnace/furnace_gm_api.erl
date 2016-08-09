-module(furnace_gm_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").

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
        VipData = Info#info.vip,
        OldVipLv = VipData#vip.lv,
        Player2 = 
            if
                OldVipLv < 2 ->
                    V2 = VipData#vip{lv = 2},
                    Info2 = Info#info{vip = V2},
                    Player#player{info = Info2};
                ?true ->
                    Player
            end,
        Player3 = up_top_2(Player2, 1, Info#info.lv),
        Info3 = Player3#player.info,
        VipData2 = Info3#info.vip,
        VipData3 = VipData2#vip{lv = OldVipLv},
        Info4 = Info3#info{vip = VipData3},
        Player3#player{info = Info4}
    catch
        X:Y ->
            ?MSG_ERROR("1[~p|~p]~n~p", [X, Y, erlang:get_stacktrace()]),
            Player
    end.

up_top_2(Player, SubType, Lv) when SubType =< 9 ->
    EquipList = Player#player.equip,
    {Count, CurLv} = 
        case lists:keytake({Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
            {value, {_Key, Equip}, _EquipList2} ->
                Ext = Equip#ctn.ext,
                StrLv = erlang:element(SubType, Ext),
                case trunc(Lv - StrLv) of
                    Diff when Diff < 0 ->
                        {0, StrLv};
                    Diff ->
                        {Diff, StrLv}
                end;
            ?false ->
                {0, Lv}
        end,
    Player2 = up_top_3(Player, SubType, Count, CurLv),
    up_top_2(Player2, SubType+1, Lv);
up_top_2(Player, _, _) ->
    Player.

up_top_3(Player, SubType, Count, CurLv) when Count > 0 ->
    Player2 = up_top(Player, SubType, CurLv),
    up_top_3(Player2, SubType, Count-1, CurLv+1);
up_top_3(Player, _, _, _) ->
    Player.

up_top(Player, SubType, CurLv) ->
    UserId = Player#player.user_id,
    Cost        = data_furnace:get_furnace_strengthen_cost({CurLv+1, SubType}),
    if
        ?null =/= Cost ->
            player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_GM_CHAT),
            case furnace_stren_api:can_stren(SubType) of
                ?CONST_SYS_TRUE ->
                    case furnace_stren_api:equip_strengthen(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, 0, SubType) of
                        {?ok, NewPlayer} ->
                            FurnaceData     = NewPlayer#player.furnace,
                            Packet          = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, FurnaceData),
                            misc_packet:send(UserId, Packet),
                            {_, Player2}    = welfare_api:add_pullulation(NewPlayer, ?CONST_WELFARE_STRENGTH, 0, 1),
                            schedule_power_api:do_change_equip(Player2),
                            Player2;
                        ?error ->
                            Player
                    end;
                ?CONST_SYS_FALSE ->
                    PacketErr = message_api:msg_notice(?TIP_FURNACE_NOT_STRENABLE),
                    misc_packet:send(UserId, PacketErr),
                    Player
            end;
        ?true ->
            Player
    end.

%%
%% Local Functions
%%

