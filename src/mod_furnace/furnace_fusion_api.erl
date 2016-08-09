%%% 时装合成
-module(furnace_fusion_api).

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
-export([init/0, show_all/1, fusion/3, save/4, add_style_default/2]).

%%
%% API Functions
%%

%% 初始化
init() ->
    #style_data{cur_non_skin = [], cur_skin = [], bag = [], hide_flags = []}.

%% 展示
show_all(Player) when is_record(Player, player) ->
    StyleData = Player#player.style,
    FashionWeaponPacket = pack_style(StyleData, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    FashionClothPacket  = pack_style(StyleData, ?CONST_GOODS_EQUIP_FUSION),
    FashionStepPacket   = pack_style(StyleData, ?CONST_GOODS_EQUIP_FUSION_STEP),
    <<FashionWeaponPacket/binary, FashionClothPacket/binary, FashionStepPacket/binary>>;    
show_all(_) ->
    <<>>.

add_style_default(Player, GoodsId) ->
    case data_goods:get_goods(GoodsId) of
        #goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION} ->
            StyleData = Player#player.style,
            StyleBag  = StyleData#style_data.bag,
            {Style, SubType}     = 
                case data_goods:get_goods(GoodsId) of
                    #goods{exts = Exts, sub_type = SubTypeT} ->
                        {Exts#g_equip.skin_id, SubTypeT};
                    _ ->
                        {0, 0}
                end,
            {Packet, StyleBag2} = goods_style_api:add_style(Player, StyleBag, Style, SubType),
            StyleData2 = StyleData#style_data{bag = StyleBag2},
            UserId = Player#player.user_id,
            misc_packet:send(UserId, Packet),
            Player#player{style = StyleData2};
        _ ->
            Player
    end.

%% 融合
fusion(Player, Idx1, Idx2) ->
    UserId = Player#player.user_id,
    Bag = Player#player.bag,
    case ctn_bag2_api:get_by_idx(UserId, Bag, Idx1) of
        {?ok, Bag2, [MiniGoods1], PacketBag1} ->
			Goods1 = goods_api:mini_to_goods(MiniGoods1),
            case ctn_bag2_api:get_by_idx(UserId, Bag2, Idx2) of
                {?ok, Bag3, [MiniGoods2], PacketBag2} ->
					Goods2 = goods_api:mini_to_goods(MiniGoods2),
                    case get_rec(Goods1, Goods2) of
                        {?ok, RecFu} ->
                            Result = 
                                case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, RecFu#rec_furnace_fashion.gold_bind, ?CONST_COST_PLAYER_FUSION) of
                                    ?ok ->
                                        ?ok;
                                    {?error, ErrorCode} ->
                                        PacketErr = message_api:msg_notice(ErrorCode),
                                        misc_packet:send(UserId, PacketErr)
                                end,
                            case Result of
                                ?ok ->
                                    SoulList = merg_soul(Goods1, Goods2),
                                    IsBind   = chk_bind(Goods1, Goods2),
                                    IsUpgrade = misc_random:odds(RecFu#rec_furnace_fashion.up_rate, ?CONST_SYS_NUMBER_TEN_THOUSAND),
									NewLv = do_upgrade(IsUpgrade, RecFu#rec_furnace_fashion.lv_1, RecFu#rec_furnace_fashion.lv_2),
									NewGoodsId = misc_random:odds_one({RecFu#rec_furnace_fashion.style_list, ?CONST_SYS_NUMBER_TEN_THOUSAND}),
									Player2 = Player#player{bag = Bag3},
									case IsUpgrade of
										?true->
											yunying_activity_mod:activity_unlimitted_award(Player2, NewLv, 12);
										_ ->
											next
									end,	
                                    admin_log_api:log_goods(UserId, 0, ?CONST_COST_PLAYER_FUSION, [Goods1|Goods2], misc:seconds()),
                                    Player4 = 
                                        case add_style(Player2, NewLv, NewGoodsId, SoulList, IsBind) of
                                            {?error, ErrorCode2} ->
                                                PacketErr2 = message_api:msg_notice(ErrorCode2),
                                                OkPacket = furnace_api:msg_sc_fusion_return(?CONST_SYS_FALSE, 0, 0),
                                                FailPacket2 = message_api:msg_notice(?TIP_FURNACE_FUSION_FAIL),
                                                misc_packet:send(UserId, <<PacketErr2/binary, OkPacket/binary, FailPacket2/binary>>),
                                                Player2;
                                            {Player2_2, NewBagPacket, GoodsChanged} ->
                                                FusionNewPacket = 
                                                    if
                                                        Goods1#goods.goods_id =/= NewGoodsId andalso Goods2#goods.goods_id =/= NewGoodsId ->
                                                            OkPacket = furnace_api:msg_sc_fusion_return(?CONST_SYS_TRUE, GoodsChanged#goods.idx, ?CONST_SYS_TRUE),
                                                            MsgPacket = message_api:msg_notice(?TIP_FURNACE_FUSION_NEW),
                                                            <<MsgPacket/binary, OkPacket/binary>>;
                                                        ?true ->
                                                            furnace_api:msg_sc_fusion_return(?CONST_SYS_TRUE, GoodsChanged#goods.idx, ?CONST_SYS_FALSE)
                                                    end,
                                                FusionOkPacket = 
                                                    case IsUpgrade of
                                                        ?true ->
                                                            message_api:msg_notice(?TIP_FURNACE_FUSION_OK);
                                                        _ ->
                                                            message_api:msg_notice(?TIP_FURNACE_FUSION_FAIL)
                                                    end,
                                                if
                                                    NewLv >= 4 andalso IsUpgrade ->
                                                        Info = Player2_2#player.info,
                                                        UserName = Info#info.user_name,
                                                        PacketBroadcast = message_api:msg_notice(?TIP_FURNACE_FUSION_OK_BROADCAST, [{UserId, UserName}], 
                                                                                        [GoodsChanged], 
                                                                                        [{?TIP_SYS_OPEN_PANEL, misc:to_list("时装合成")},
                                                                                        {?TIP_SYS_COMM, misc:to_list(NewLv)}]),
                                                        misc_app:broadcast_world_2(PacketBroadcast);
                                                    ?true ->
                                                        ?ok
                                                end,
                                                    
                                                misc_packet:send(UserId, <<PacketBag1/binary, PacketBag2/binary, NewBagPacket/binary, 
                                                                           FusionOkPacket/binary, FusionNewPacket/binary>>),
                                                Player2_2
                                        end,
                                    Player5 = furnace_mod:refresh_attr_equip(Player4, ?CONST_GOODS_CTN_EQUIP_PLAYER, 0),
                                    {?ok, Player5};
                                _ ->
                                    OkPacket = furnace_api:msg_sc_fusion_return(?CONST_SYS_FALSE, 0, 0),
                                    misc_packet:send(UserId, OkPacket),
                                    {?ok, Player}
                            end;
                        {?error, ErrorCode} ->
                            OkPacket = furnace_api:msg_sc_fusion_return(?CONST_SYS_FALSE, 0, 0),
                            PacketErr = 
                                if
                                    ?TIP_COMMON_BAD_ARG =:= ErrorCode ->
                                        message_api:msg_notice(?TIP_FURNACE_FUSION_TOP);
                                    ?true ->
                                        message_api:msg_notice(ErrorCode)
                                end,
                            misc_packet:send(UserId, <<PacketErr/binary, OkPacket/binary>>),
                            {?ok, Player}
                    end;
                {?error, ErrorCode} ->
                    PacketErr = message_api:msg_notice(ErrorCode),
                    OkPacket  = furnace_api:msg_sc_fusion_return(?CONST_SYS_FALSE, 0, 0),
                    FailPacket = message_api:msg_notice(?TIP_FURNACE_FUSION_FAIL),
                    misc_packet:send(UserId, <<PacketErr/binary, OkPacket/binary, FailPacket/binary>>),
                    {?ok, Player}
            end;
        {?error, ErrorCode} ->
            PacketErr = message_api:msg_notice(ErrorCode),
            OkPacket  = furnace_api:msg_sc_fusion_return(?CONST_SYS_FALSE, 0, 0),
            FailPacket = message_api:msg_notice(?TIP_FURNACE_FUSION_FAIL),
            misc_packet:send(UserId, <<PacketErr/binary, OkPacket/binary, FailPacket/binary>>),
            {?ok, Player}
    end.

get_rec(#goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION} = Goods1,
        #goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION} = Goods2) ->
    Ext1 = Goods1#goods.exts,
    Ext2 = Goods2#goods.exts,
    FusionLv1 = Ext1#g_equip.fusion_lv,
    FusionLv2 = Ext2#g_equip.fusion_lv,
    case data_furnace:get_fusion_cost({FusionLv1, FusionLv2, ?CONST_GOODS_EQUIP_FUSION}) of
        ?null ->
            {?error, ?TIP_COMMON_BAD_ARG}; % FIXME 不存在此合成
        #rec_furnace_fashion{} = RecFu ->
            {?ok, RecFu}
    end;
get_rec(#goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION_WEAPON} = Goods1,
        #goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION_WEAPON} = Goods2) ->
    Ext1 = Goods1#goods.exts,
    Ext2 = Goods2#goods.exts,
    FusionLv1 = Ext1#g_equip.fusion_lv,
    FusionLv2 = Ext2#g_equip.fusion_lv,
    case data_furnace:get_fusion_cost({FusionLv1, FusionLv2, ?CONST_GOODS_EQUIP_FUSION_WEAPON}) of
        ?null ->
            {?error, ?TIP_COMMON_BAD_ARG}; % FIXME 不存在此合成
        #rec_furnace_fashion{} = RecFu ->
            {?ok, RecFu}
    end;
get_rec(#goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION_STEP} = Goods1,
        #goods{type = ?CONST_GOODS_TYPE_EQUIP, sub_type = ?CONST_GOODS_EQUIP_FUSION_STEP} = Goods2) ->
    Ext1 = Goods1#goods.exts,
    Ext2 = Goods2#goods.exts,
    FusionLv1 = Ext1#g_equip.fusion_lv,
    FusionLv2 = Ext2#g_equip.fusion_lv,
    case data_furnace:get_fusion_cost({FusionLv1, FusionLv2, ?CONST_GOODS_EQUIP_FUSION_STEP}) of
        ?null ->
            {?error, ?TIP_COMMON_BAD_ARG}; % FIXME 不存在此合成
        #rec_furnace_fashion{} = RecFu ->
            {?ok, RecFu}
    end;
get_rec(_, _) ->
    {?error, ?TIP_COMMON_BAD_ARG}. % FIXME 不存在此合成

chk_bind(#goods{bind = ?CONST_SYS_TRUE}, #goods{bind = _}) ->
    ?CONST_SYS_TRUE;
chk_bind(#goods{bind = _}, #goods{bind = ?CONST_SYS_TRUE}) ->
    ?CONST_SYS_TRUE;
chk_bind(#goods{bind = _}, #goods{bind = _}) ->
    ?CONST_SYS_FALSE.

do_upgrade(?true, Lv1, Lv2) when Lv1 =< Lv2 ->
    Lv2 + 1;
do_upgrade(?true, Lv1, _) ->
    Lv1 + 1;
do_upgrade(?false, Lv1, Lv2) when Lv1 =< Lv2 ->
    Lv2;
do_upgrade(?false, Lv1, _) ->
    Lv1.
    
add_style(Player, NewLv, NewGoodsId, SoulList, IsBind) ->
    case goods_api:make(NewGoodsId, 1) of
        [Goods] ->
            Ext = Goods#goods.exts,
            SoulAttr = furnace_mod:trans_soul_id_value2(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, SoulList),
            NewExt   = Ext#g_equip{attr_soul = SoulAttr, soul_list = SoulList},
            Ext2     = 
                case Goods#goods.sub_type of
                    ?CONST_GOODS_EQUIP_FUSION ->
                        NewExt#g_equip{fusion_lv = NewLv};
                    ?CONST_GOODS_EQUIP_FUSION_STEP ->
                        NewExt#g_equip{fusion_lv = NewLv};
                    ?CONST_GOODS_EQUIP_FUSION_WEAPON ->
                        NewExt#g_equip{fusion_lv = NewLv};
                    _ ->
                        NewExt
                end,
            Goods2 = Goods#goods{exts = Ext2, bind = IsBind},
            Style  = Ext2#g_equip.skin_id,
            case ctn_bag_api:put(Player, [Goods2], ?CONST_COST_PLAYER_FUSION, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, [MiniGoods], BagPacket} ->
					GoodsChanged = goods_api:mini_to_goods(MiniGoods),
                    OldStyleData = Player#player.style,
                    SubType = Goods#goods.sub_type,
                    OldStyleBag = OldStyleData#style_data.bag,
                    {StylePacket, NewStyleData} = 
                        if
                            SubType =:= ?CONST_GOODS_EQUIP_FUSION 
                            orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_STEP 
                            orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_WEAPON ->
                                {P, L} = goods_style_api:add_style(Player, OldStyleBag, Style, SubType),
                                {P, OldStyleData#style_data{bag = L}};
                            ?true ->
                                {<<>>, OldStyleData}
                        end,
                    ExtChanged = GoodsChanged#goods.exts,
                    ExtChanged2 = ExtChanged#g_equip{strength_lv = NewLv},
                    GoodsChanged2 = GoodsChanged#goods{exts = ExtChanged2},
                    {Player2#player{style = NewStyleData}, <<BagPacket/binary, StylePacket/binary>>, GoodsChanged2};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 合成附魂
merg_soul(_, _) ->
    [].


get_n([Soul|Tail], Result, Count, Max) when Count < Max ->
    get_n(Tail, [Soul|Result], Count+1, Max);
get_n(_, Result, Count, Max) when Count >= Max ->
    Result;
get_n([], Result, _, _) ->
    Result.

%% 保存
%% 保存
save(Player, WeaponStyle, ClothStyle, StepStyle) ->
    StyleData     = Player#player.style,
    IsExistWeapon = goods_style_api:is_exist_style(StyleData, WeaponStyle, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    IsExistCloth  = goods_style_api:is_exist_style(StyleData, ClothStyle, ?CONST_GOODS_EQUIP_FUSION),
    IsExistStep   = goods_style_api:is_exist_style(StyleData, StepStyle, ?CONST_GOODS_EQUIP_FUSION_STEP),
    {ClothStyleX, WeaponStyleX, StepStyleX} = 
        case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, Player#player.user_id, 0, Player#player.equip) of
            {?ok, EquipCtn} ->
                Fashion       = erlang:element(?CONST_GOODS_EQUIP_FUSION, EquipCtn#ctn.goods),
                FashionWeapon = erlang:element(?CONST_GOODS_EQUIP_FUSION_WEAPON, EquipCtn#ctn.goods),
                FashionStep   = erlang:element(?CONST_GOODS_EQUIP_FUSION_STEP, EquipCtn#ctn.goods),
                ClothStyle2   = chk(Fashion, IsExistCloth, ClothStyle),
                WeaponStyle2  = chk(FashionWeapon, IsExistWeapon, WeaponStyle),
                StepStyle2    = chk(FashionStep, IsExistStep, StepStyle),
                {ClothStyle2, WeaponStyle2, StepStyle2};
            {?error, _ErrorCode} ->
                {0, 0, 0}
        end,
    
    CurSkinList  = StyleData#style_data.cur_skin,
    CurSkinList2 = 
        if
            0 =/= WeaponStyle -> 
                lists:keystore(?CONST_GOODS_EQUIP_FUSION_WEAPON, 1, CurSkinList,  {?CONST_GOODS_EQUIP_FUSION_WEAPON, WeaponStyleX});
            ?true ->
                CurSkinList
        end,
    CurSkinList3 = lists:keystore(?CONST_GOODS_EQUIP_FUSION,        1, CurSkinList2, {?CONST_GOODS_EQUIP_FUSION,        ClothStyleX}),
    CurSkinList4 = lists:keystore(?CONST_GOODS_EQUIP_FUSION_STEP,   1, CurSkinList3, {?CONST_GOODS_EQUIP_FUSION_STEP,   StepStyleX}),
    StyleData2   = StyleData#style_data{cur_skin = CurSkinList4}, 
    Player2 = Player#player{style = StyleData2},
    PacketOk = message_api:msg_notice(?TIP_FURNACE_FUSION_SAVE_OK),
    UserId = Player2#player.user_id,
    misc_packet:send(UserId, PacketOk),
    map_api:change_skin_fashion(Player2),
    map_api:change_skin_weapon(Player2),
    map_api:change_skin_step(Player2),
    Player2.

chk(0, _, _X) -> 0;
chk(_, 0, _X) -> 0;
chk(_, _, X)  -> X.


%%
%% Local Functions
%%

pack_style(StyleData, Idx) ->
    Bag = StyleData#style_data.bag,
    case lists:keyfind(Idx, 1, Bag) of
        {_, StyleList} ->
            pack_style(StyleList, Idx, <<>>);
        ?false ->
            <<>>
    end.
    
pack_style([{StyleId, _}|Tail], Idx, OldPacket) ->
    Packet = furnace_api:msg_sc_style(StyleId, Idx),
    pack_style(Tail, Idx, <<OldPacket/binary, Packet/binary>>);
pack_style([], _, Packet) ->
    Packet.


    