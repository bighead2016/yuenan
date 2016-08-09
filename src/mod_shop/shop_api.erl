%% 道具店
-module(shop_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([sell/4, repurchase/3, list_repurchase/1, check_purchage/4, sell_list/4]).
-export([
		 msg_sc_secret_init/6,
		 msg_sc_buy_goods/1,
		 msg_sc_secret_refresh/1,
		 msg_sc_log_info/1
		]).

%%
%% API Functions
%%

%% 出售物品
sell(UserId, Bag, Idx, ShopTempList) ->
    case ctn_bag2_api:get_by_idx(UserId, Bag, Idx) of
        {?ok, NewBag, [MiniGoods], PacketBag} ->
            Goods = goods_api:mini_to_goods(MiniGoods),
            if
                1 =:= (Goods#goods.flag)#g_flag.is_sell ->
                    ShopIndex = next_shop_idx(),
                    Len = erlang:length(ShopTempList),
                    {NewShopTempList2, Packet2} = 
                        if
                            Len < ?CONST_SHOP_MAX_COUNT -> % < 12
                                NewShopTempList = ShopTempList ++ [{ShopIndex, Goods}],
                                PacketGoods = msg_sc_goods(ShopIndex, MiniGoods#mini_goods.goods_id, MiniGoods#mini_goods.count),
                                Packet = <<PacketBag/binary, PacketGoods/binary>>,
                                {NewShopTempList, Packet};
                            ?true -> % =:= 12
                                [{HShopIndex, _Goods}|ShopTempList2] = ShopTempList,
                                NewShopTempList = ShopTempList2 ++ [{ShopIndex, Goods}],
                                PacketDel = msg_sc_del_goods(HShopIndex),
                                PacketGoods = msg_sc_goods(ShopIndex, MiniGoods#mini_goods.goods_id, MiniGoods#mini_goods.count),
                                Packet = <<PacketDel/binary, PacketBag/binary, PacketGoods/binary>>,
                                {NewShopTempList, Packet}
                        end,
                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_SHOP_SOLD, [MiniGoods], misc:seconds()),
                    do_plus(UserId, Goods, NewBag, NewShopTempList2, Packet2);
                ?true ->
                    Packet = message_api:msg_notice(?TIP_SHOP_NOT_SELLABLE),
                    misc_packet:send(UserId, Packet),
                    {?error, ?TIP_SHOP_NOT_SELLABLE}
            end;
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, ErrorCode};
        _X ->
            Packet = message_api:msg_notice(?TIP_SHOP_NOT_SELLABLE),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_SHOP_NOT_SELLABLE}
    end.

sell_list(UserId, Bag, List, ShopTempList) ->
    sell_list(UserId, Bag, List, ShopTempList, <<>>, 0).

sell_list(UserId, #ctn{usable = Usable} = Bag, [{Idx}|Tail], ShopTempList, OldPacket, OldMoney) when Idx > Usable ->
    sell_list(UserId, Bag, Tail, ShopTempList, OldPacket, OldMoney);
sell_list(UserId, Bag, [{Idx}|Tail], ShopTempList, OldPacket, OldMoney) ->
    {?ok, NewBagT, NewShopTempListT, NewPacketT, NewMoneyT} = 
        case ctn_bag2_api:get_by_idx_not_send(UserId, Bag, Idx) of
            {?ok, NewBag, [MiniGoods], PacketBag} ->
                Goods = goods_api:mini_to_goods(MiniGoods),
                if
                    1 =:= (Goods#goods.flag)#g_flag.is_sell ->
                        ShopIndex = next_shop_idx(),
                        Len = erlang:length(ShopTempList),
                        {NewShopTempList2, Packet2} = 
                            if
                                Len < ?CONST_SHOP_MAX_COUNT -> % < 12
                                    NewShopTempList = ShopTempList ++ [{ShopIndex, Goods}],
                                    PacketGoods = msg_sc_goods(ShopIndex, Goods#goods.goods_id, Goods#goods.count),
                                    PacketTotal = <<OldPacket/binary, PacketBag/binary, PacketGoods/binary>>,
                                    {NewShopTempList, PacketTotal};
                                ?true -> % =:= 12
                                    [{HShopIndex, _Goods}|ShopTempList2] = ShopTempList,
                                    NewShopTempList = ShopTempList2 ++ [{ShopIndex, Goods}],
                                    PacketDel = msg_sc_del_goods(HShopIndex),
                                    PacketGoods = msg_sc_goods(ShopIndex, Goods#goods.goods_id, Goods#goods.count),
                                    PacketTotal = <<OldPacket/binary, PacketDel/binary, PacketBag/binary, PacketGoods/binary>>,
                                    {NewShopTempList, PacketTotal}
                            end,
                        case do_plus(UserId, Goods, NewBag, NewShopTempList2, Packet2) of
                            {?ok, NewBagTT, NewShopTempListTT, PacketTT, SellValueTT} ->
                                admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_SHOP_SOLD, [Goods], misc:seconds()),
                                {?ok, NewBagTT, NewShopTempListTT, PacketTT, SellValueTT + OldMoney};
                            {?error, _ErrorCode} -> % money里面发了
                                {?ok, Bag, ShopTempList, OldPacket, OldMoney}
                        end;
                    ?true ->
                        {?ok, Bag, ShopTempList, OldPacket, OldMoney}
                end
        end,
    sell_list(UserId, NewBagT, Tail, NewShopTempListT, NewPacketT, NewMoneyT);
sell_list(_UserId, Bag, [], ShopTempList, Packet, Money) ->
    MoneyStr  = integer_to_list(Money),
    PacketTip = message_api:msg_notice(?TIP_SHOP_GET_MONEY, [{100, MoneyStr}]),
    {?ok, Bag, ShopTempList, <<Packet/binary, PacketTip/binary>>}.

do_plus(UserId, Goods, NewBag, NewShopTempList, Packet) ->
    case Goods#goods.sell_price * Goods#goods.count of
        0 ->
            {?ok, NewBag, NewShopTempList, Packet, 0};
        SellValue ->
            case player_money_api:plus_money(UserId, Goods#goods.sell_type, SellValue, ?CONST_COST_SHOP_SOLD) of
                ?ok ->
                    {?ok, NewBag, NewShopTempList, Packet, SellValue};
                {?error, ErrorCode} -> % money里面发了
                    {?error, ErrorCode}
            end
    end.

%% 花钱
do_cost(UserId, Goods, NewBag, NewShopTempList, Packet) ->
    case Goods#goods.sell_price * Goods#goods.count of
        0 ->
            {?ok, NewBag, NewShopTempList, Packet};
        SellValue ->
            case player_money_api:minus_money(UserId, Goods#goods.sell_type, SellValue, ?CONST_COST_SHOP_REPURCHASE) of
                ?ok ->
                    {?ok, NewBag, NewShopTempList, Packet};
                {?error, ErrorCode} -> % money里面发了
                    {?error, ErrorCode}
            end
    end.
    
%% 回购物品
repurchase(Player, ShopTempList, Idx) ->
    Bag = Player#player.bag,
    UserId = Player#player.user_id,
    {?ok, EmptyCount} = ctn_bag2_api:empty_count(Bag),
    if 
        EmptyCount =< 0 ->
            Packet = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        ?true ->
            delete_goods(Player, ShopTempList, Idx)
    end.
                    
%% 物品从回购列表转到背包
delete_goods(Player, ShopTempList, Idx) ->
    UserId = Player#player.user_id,
    case lists:keytake(Idx, 1, ShopTempList) of
        {value, {Idx, Goods}, NewShopTempList} ->
            Bag = Player#player.bag,
            case do_cost(UserId, Goods, Bag, NewShopTempList, <<>>) of
                {?ok, Bag2, NewShopTempList, Packet2} ->
                    case ctn_bag_api:put(Player#player{bag = Bag2}, [Goods], ?CONST_COST_SHOP_REPURCHASE, 1, 0, 0, 0, 0, 1, []) of
                        {?ok, Player2, _, PacketBag} ->
                            PacketDel = msg_sc_del_goods(Idx),
                            Packet = <<PacketBag/binary, PacketDel/binary, Packet2/binary>>,
                            {?ok, Player2, NewShopTempList, Packet};
                        {?error, ErrorCode} -> 
                            {?error, ErrorCode}
                    end;
                {?error, ErrorCode2} -> 
                    {?error, ErrorCode2}
            end;
        ?false ->
            Packet = message_api:msg_notice(?TIP_COMMON_GOOD_NOT_EXIST),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_COMMON_GOOD_NOT_EXIST}
    end.

%% 回购列表
list_repurchase(ShopTempList) ->
    F = fun({Idx, Goods}, OldPacket) ->
                Packet = msg_sc_goods(Idx, Goods#goods.goods_id, Goods#goods.count),
                <<Packet/binary, OldPacket/binary>>
        end,
    lists:foldl(F, <<>>, ShopTempList).


check_purchage(Player, GoodsId, Count, RecShop) ->
    try
        ?ok = check_goods(RecShop),
        ?ok = check_enough(Player, GoodsId, Count)
    catch
        throw:Reason ->
            Reason;
        _:_ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

check_goods(RecShop) when is_record(RecShop, rec_shop) ->
    ?ok;
check_goods(_RecShop) ->
    throw({?error, ?TIP_COMMON_GOOD_NOT_EXIST}).

check_enough(Player, GoodsId, Count) ->
    Goods = data_goods:get_goods(GoodsId),
    {?ok, EmptyNum} = ctn_bag2_api:empty_count(Player#player.bag),
    Num  = Count div Goods#goods.stack,
    Num2 = Count rem Goods#goods.stack,
    Num3 = 
        if
            0 < Num2 ->
                1;
            ?true ->
                0
        end,
    case EmptyNum >= (Num + Num3) of
        ?true ->
            ?ok;
        ?false ->
            throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
    end.

%% 回购信息
%%[Index,GoodsId,Count]
msg_sc_goods(Index,GoodsId,Count) ->
    misc_packet:pack(?MSG_ID_SHOP_SC_GOODS, ?MSG_FORMAT_SHOP_SC_GOODS, [Index,GoodsId,Count]).
%% 删除物品
%%[Idx]
msg_sc_del_goods(Idx) ->
    misc_packet:pack(?MSG_ID_SHOP_SC_DEL_GOODS, ?MSG_FORMAT_SHOP_SC_DEL_GOODS, [Idx]).
%% 云游商人初始化信息
%%[RestTime,RefreshTimes,RefreshTotal,Score,FreeTimes,{Id,GoodsId2,Num,Price,Sell,State}]
msg_sc_secret_init(RestTime,RefreshTimes,RefreshTotal,Score,FreeTimes,List1) ->
	misc_packet:pack(?MSG_ID_SHOP_SC_SECRET_INIT, ?MSG_FORMAT_SHOP_SC_SECRET_INIT, [RestTime,RefreshTimes,RefreshTotal,Score,FreeTimes,List1]).
%% 云游商人刷新
%%[Result]
msg_sc_secret_refresh(Result) ->
	misc_packet:pack(?MSG_ID_SHOP_SC_SECRET_REFRESH, ?MSG_FORMAT_SHOP_SC_SECRET_REFRESH, [Result]).
%% 云游商人购买物品
%%[Result]
msg_sc_buy_goods(Result) ->
	misc_packet:pack(?MSG_ID_SHOP_SC_BUY_GOODS, ?MSG_FORMAT_SHOP_SC_BUY_GOODS, [Result]).
%% 云游商人购买记录信息
%%[{UserName,Cost,GoodsId}]
msg_sc_log_info(List1) ->
	misc_packet:pack(?MSG_ID_SHOP_SC_LOG_INFO, ?MSG_FORMAT_SHOP_SC_LOG_INFO, [List1]).
%%
%% Local Functions
%%
%% get_shop_idx() ->
%%     case get(shop_idx) of
%%         undefined ->
%%             1;
%%         Idx ->
%%             Idx
%%     end.

next_shop_idx() ->
    case get(shop_idx) of
        undefined ->
            put(shop_idx, 2),
            1;
        Idx ->
            put(shop_idx, Idx + 1),
            Idx
    end.
