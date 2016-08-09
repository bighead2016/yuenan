%%% 背包/临时背包接口
-module(ctn_bag_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([put/10]).

%%
%% API Functions
%%

%% Player, GoodsList, Point, IsNew, IsStack, IsInTemp, IsIgnore, IsSend, IsLog, Ext
%% {?ok, Player2, Changelist, Packet}/{?error, ErrorCode}
put(Player, GoodsList, Point, IsNew, IsStack, IsInTemp, IsIgnore, IsSend, IsLog, Ext) ->
    UserId = Player#player.user_id,
    Bag    = Player#player.bag,
    MiniGoodsList = [goods_api:goods_to_mini(G)||G<-GoodsList],
    Result = 
        case IsStack of
            ?CONST_SYS_TRUE ->
                case ctn2_mod:set_stack_list_ignore_with_temp(Bag, MiniGoodsList) of
                    {?ok, Bag2, ChangeListBag, ChangeList2TempBag, IsDroped} ->
                        case IsDroped of
                            ?CONST_SYS_TRUE when ?CONST_SYS_FALSE =:= IsIgnore ->
                                {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
                            _ ->
                                case IsInTemp of
                                    ?CONST_SYS_TRUE ->
                                        TempTipPacket = msg_goods_temp_reward(ChangeList2TempBag),
                                        ChangeList    = ChangeListBag ++ ChangeList2TempBag,
                                        {?ok, Bag2, ChangeList, TempTipPacket};
                                    ?CONST_SYS_FALSE when [] =:= ChangeList2TempBag ->
                                        {?ok, Bag2, ChangeListBag, <<>>};
                                    ?CONST_SYS_FALSE when ?CONST_SYS_TRUE =:= IsIgnore ->
                                        {?ok, Bag2, ChangeListBag, <<>>};
                                    ?CONST_SYS_FALSE ->
                                        {?error, ?TIP_COMMON_BAG_NOT_ENOUGH}
                                end
                        end;
                    {?error, ErrorCode} ->
                        {?error, ErrorCode}
                end;
            ?CONST_SYS_FALSE ->
                case ctn_mod:set_list_ignore(Bag, MiniGoodsList) of
                    {?ok, Bag2, ChangeList, IsDroped} ->
                        case IsDroped of
                            ?CONST_SYS_TRUE when ?CONST_SYS_FALSE =:= IsIgnore ->
                                {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
                            _ ->
                                {?ok, Bag2, ChangeList, <<>>}
                        end;
                    {?error, ErrorCode} ->
                        {?error, ErrorCode}
                end
        end,
    case Result of
        {?ok, NewBag, NewChangeList, NewPacket} ->
            ctn_equip_api:equip_list_make_achievement(UserId, MiniGoodsList),
            {Player2, StylePacket} = goods_style_api:add_style_list(Player#player{bag = NewBag}, GoodsList),
            {Player3, SkillPacket} = horse_skill_api:upgrade_skill_base(Player2, GoodsList),
            
            NewGoodsPacket = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, NewChangeList, IsNew),
            NewTipPacket   = msg_reward_get_goods(MiniGoodsList),
            NewTotalPacket = <<NewGoodsPacket/binary, NewTipPacket/binary, NewPacket/binary, StylePacket/binary, SkillPacket/binary>>,
            case IsSend of
                ?CONST_SYS_TRUE ->
                    misc_packet:send(UserId, NewTotalPacket);
                ?CONST_SYS_FALSE ->
                    ?ok
            end,
            case IsLog of
                ?CONST_SYS_TRUE ->
                    case Ext of
                        [] ->
                            [admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, Goods, misc:seconds())||Goods <- MiniGoodsList];
                        [A1] ->
                            [admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, Goods, misc:seconds(), A1, 0, 0, 0, 0, 0)||Goods <- MiniGoodsList];
                        [A1, A2, A3, A4, A5, A6] ->
                            [admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, Goods, misc:seconds(), A1, A2, A3, A4, A5, A6)||Goods <- MiniGoodsList];
                        _ ->
                            [admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Point, Goods, misc:seconds(), 0, 0, 0, 0, 0, 0)||Goods <- MiniGoodsList]
                    end;
                ?CONST_SYS_FALSE ->
                    ?ok
            end,
            {?ok, Player3, NewChangeList, NewTotalPacket};
        {?error, NewErrorCode} ->
            case IsSend of
                ?CONST_SYS_TRUE ->
                    NewErrPacket = message_api:msg_notice(NewErrorCode),
                    misc_packet:send(UserId, NewErrPacket);
                ?CONST_SYS_FALSE ->
                    ?ok
            end,
            {?error, NewErrorCode}
    end.


      
%%
%% Local Functions
%%
%% 获得物品提示
msg_reward_get_goods(GoodsList) ->
    GoodsInfoList   = cal_same_goods_num(GoodsList, []),
    F   = fun({GoodsId, _GoodsName, GoodsNum}) ->
                  {GoodsId, GoodsNum}
          end,
    NewAcc  = [F(GoodsInfo )|| GoodsInfo <- GoodsInfoList],
    get_msg_goods_notice(NewAcc, <<>>).

get_msg_goods_notice([{GoodsId, GoodsNum} |GoodsInfo], Acc) ->
     TipPacket      = message_api:msg_reward_add_goods(GoodsId, GoodsNum),
     NewAcc         = <<Acc/binary, TipPacket/binary>>,
    get_msg_goods_notice(GoodsInfo, NewAcc);
get_msg_goods_notice([], Acc) ->
    Acc.

%% 获得临时物品提示
msg_goods_temp_reward(GoodsList) ->
    GoodsInfoList   = ctn_bag2_api:cal_same_goods_num(GoodsList, []),
    F   = fun({GoodsId, _, GoodsNum}) ->
                  {GoodsId, GoodsNum}
          end,
    NewAcc  = [F(GoodsInfo )|| GoodsInfo <- GoodsInfoList],
    get_msg_temp_goods_notice(NewAcc, <<>>).

get_msg_temp_goods_notice([{GoodsId, GoodsNum} |GoodsInfo], Acc) ->
     TipPacket      = message_api:msg_notice(?TIP_GOODS_TEMP_REWARD, [{?TIP_SYS_NOT_EQUIP, misc:to_list(GoodsId)}, 
                                                                     {?TIP_SYS_COMM, misc:to_list(GoodsNum)}]), 
     NewAcc         = <<Acc/binary, TipPacket/binary>>,
    get_msg_temp_goods_notice(GoodsInfo, NewAcc);
get_msg_temp_goods_notice([], Acc) ->
    Acc.

%% 统计相同物品个数
cal_same_goods_num([MiniGoods|GoodsList], GoodsInfoList) when is_record(MiniGoods, mini_goods) ->
    GoodsId     = MiniGoods#mini_goods.goods_id,
    Goods = data_goods:get_goods(GoodsId),
    GoodsName   = Goods#goods.name,
    GoodsNum    = MiniGoods#mini_goods.count,
    case lists:keyfind(GoodsId, 1, GoodsInfoList) of
        {GoodsId, GoodsName, Num}   ->
            NewTuple            = {GoodsId, GoodsName, Num + GoodsNum},
            NewGoodsInfoList    = lists:keyreplace(GoodsId, 1, GoodsInfoList, NewTuple),
            cal_same_goods_num(GoodsList, NewGoodsInfoList);
        ?false ->
            NewTuple            = {GoodsId, GoodsName, GoodsNum},
            NewGoodsInfoList    = [NewTuple|GoodsInfoList],
            cal_same_goods_num(GoodsList, NewGoodsInfoList)
    end;
cal_same_goods_num([Goods|GoodsList], GoodsInfoList) when is_record(Goods, goods) ->
    GoodsId     = Goods#goods.goods_id,
    GoodsName   = Goods#goods.name,
    GoodsNum    = Goods#goods.count,
    case lists:keyfind(GoodsId, 1, GoodsInfoList) of
        {GoodsId, GoodsName, Num}   ->
            NewTuple            = {GoodsId, GoodsName, Num + GoodsNum},
            NewGoodsInfoList    = lists:keyreplace(GoodsId, 1, GoodsInfoList, NewTuple),
            cal_same_goods_num(GoodsList, NewGoodsInfoList);
        ?false ->
            NewTuple            = {GoodsId, GoodsName, GoodsNum},
            NewGoodsInfoList    = [NewTuple|GoodsInfoList],
            cal_same_goods_num(GoodsList, NewGoodsInfoList)
    end;
cal_same_goods_num([], GoodsInfoList) ->
    GoodsInfoList.