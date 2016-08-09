%% 装备锻造/道具合成api
-module(furnace_forge_new_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").

%%
%% Exported Functions
%%
-export([equip_forge/5]).

%%
%% API Functions
%%

%% 装备锻造
equip_forge(Player, CtnType, Idx, NewEquipId, PartnerId) ->
	equip_forge_normal(Player, CtnType, Idx, NewEquipId, PartnerId).

%% 升阶
make_upgrade(GoodsId, #mini_goods{} = OldGoods) ->
    Ext = OldGoods#mini_goods.exts,
    if
        is_record(Ext, g_equip) ->
            SoulList = Ext#g_equip.soul_list,
            Bind     = OldGoods#mini_goods.bind,
            Idx      = OldGoods#mini_goods.idx,
            [NewGoods|_] = goods_api:make(GoodsId, Bind, 1),
            NewGoods2 = NewGoods#goods{idx = Idx},
            NewGoods3 = merg_soul(NewGoods2, SoulList),
            goods_api:goods_to_mini(NewGoods3);
        ?true ->
            0
    end;
make_upgrade(_GoodsId, _) ->
    0.

%% 直接替换
exchange(Ctn, Idx, NewGoods) when is_record(NewGoods, mini_goods) orelse 0 =:= NewGoods ->
    GoodsTuple  = Ctn#ctn.goods,
    GoodsTuple2 = erlang:setelement(Idx, GoodsTuple, NewGoods),
    Ctn#ctn{goods = GoodsTuple2};
exchange(Ctn, _, _) ->
    Ctn.

%% 设置容器
reset(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, Ctn, _PartnerId) ->
    EquipList = Player#player.equip,
    UserId = Player#player.user_id,
    NewEquipList = 
        case lists:keytake({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
            {value, _, EquipList2} ->
                [{{UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, Ctn}|EquipList2];
            ?false ->
                [{{UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, Ctn}|EquipList]
        end,
    Player#player{equip = NewEquipList};
reset(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, Ctn, PartnerId) ->
    EquipList = Player#player.equip,
    NewEquipList = 
        case lists:keytake({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
            {value, _, EquipList2} ->
                [{{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, Ctn}|EquipList2];
            ?false ->
                [{{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, Ctn}|EquipList]
        end,
    Player#player{equip = NewEquipList};
reset(Player, _CtnType, _Ctn, _PartnerId) ->
    Player.

%% 装备 普通锻造
equip_forge_normal(Player = #player{net_pid = NetPid, user_id = UserId, bag = Bag}, ?CONST_GOODS_CTN_BAG = CtnType, Idx, NewEquipId, PartnerId) ->
    case check_equip_forge_normal(Player, CtnType, Idx, NewEquipId, PartnerId) of
        {?ok, Result, ScrollId, GoodsId, GoldCost, OldGoods, _} ->
            %书
            {?ok, NewBag, _GoodsList, Packet2} = 
                case GoodsId of
                    0 ->
                        Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                        {?ok, Bag, [], Packet};
                    _ ->
                        case ctn_bag2_api:get_by_id_not_send(UserId, Bag, ScrollId, 1) of
                            {?ok, Bag2, GoodsList, Packet} ->
                                {?ok, Bag2, GoodsList, Packet};
                            {?error, ErrorCode} ->
                                Packet = message_api:msg_notice(ErrorCode),
                                {?ok, Bag, [], Packet}
                        end
                end,
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, ScrollId, 1, misc:seconds()),
            % 扣钱
            player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost, ?CONST_COST_FURNACE_FORGE_COST),
            
            % 新装备
            % #goods{}/0
            NewGoods = make_upgrade(NewEquipId, OldGoods),
			{Player1, StylePacket} = goods_style_api:add_style_list(Player, [goods_api:mini_to_goods(NewGoods)]),
            % 直接替换
            NewBag2 = exchange(NewBag, Idx, NewGoods),
            Player2 = Player1#player{bag = NewBag2},
            GoodsPacket = goods_api:msg_goods_sc_goods_equip_info(CtnType, UserId, PartnerId, NewGoods, ?CONST_SYS_FALSE),
            Now  = misc:seconds(),
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_FURNACE_FORGE_COST, NewEquipId, 1, Now),
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, GoodsId, 1, Now),
            
            %% 新服成就
%%             {?ok, Player3}          = new_serv_api:finish_achieve(Player2, ?CONST_NEW_SERV_EQUIP_FORGE, NewGoods#goods.color, 1),
            OkPacket                = message_api:msg_notice(?TIP_FURNACE_UPGRADE_OK, [{?TIP_SYS_EQUIP, misc:to_list(NewEquipId)}]),
            FinalPacket             = <<Packet2/binary, GoodsPacket/binary, OkPacket/binary, StylePacket/binary>>,
            misc_packet:send(NetPid, FinalPacket),
            admin_log_api:log_furnace(Player2, ?CONST_LOG_FUN_FURNACE_FORGE, 0, 0, NewEquipId, 0),
            
            % 放置
            {?ok, Result, Player2};
        {?error, _Result} ->
            {?error, 0, Player}
    end;
equip_forge_normal(Player = #player{net_pid = NetPid, user_id = UserId, bag = Bag}, CtnType, Idx, NewEquipId, PartnerId) ->
	case check_equip_forge_normal(Player, CtnType, Idx, NewEquipId, PartnerId) of
		{?ok, Result, ScrollId, GoodsId, GoldCost, OldGoods, Ctn} ->
			%书
			{?ok, NewBag, _GoodsList, Packet2} = 
                case GoodsId of
                    0 ->
                        Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                        {?ok, Bag, [], Packet};
                    _ ->
                        case ctn_bag2_api:get_by_id_not_send(UserId, Bag, ScrollId, 1) of
                            {?ok, Bag2, GoodsList, Packet} ->
                                {?ok, Bag2, GoodsList, Packet};
                            {?error, ErrorCode} ->
                                Packet = message_api:msg_notice(ErrorCode),
                                {?ok, Bag, [], Packet}
                        end
                end,
            Player1 = Player#player{bag = NewBag},
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, ScrollId, 1, misc:seconds()),
			% 扣钱
            player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost, ?CONST_COST_FURNACE_FORGE_COST),
            
            % 新装备
            % #goods{}/0
            NewGoods = make_upgrade(NewEquipId, OldGoods),
			{Player2, StylePacket} = goods_style_api:add_style_list(Player1, [goods_api:mini_to_goods(NewGoods)]),
            % 直接替换
            Ctn2 = exchange(Ctn, Idx, NewGoods),
            GoodsPacket = goods_api:msg_goods_sc_goods_equip_info(CtnType, UserId, PartnerId, NewGoods, ?CONST_SYS_FALSE),
            Now  = misc:seconds(),
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_FURNACE_FORGE_COST, NewEquipId, 1, Now),
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, GoodsId, 1, Now),
			
			%% 新服成就
%% 			{?ok, Player3}          = new_serv_api:finish_achieve(Player2, ?CONST_NEW_SERV_EQUIP_FORGE, NewGoods#goods.color, 1),
            OkPacket                = message_api:msg_notice(?TIP_FURNACE_UPGRADE_OK, [{?TIP_SYS_EQUIP, misc:to_list(NewEquipId)}]),
            Info                    = Player2#player.info,
            UserName                = Info#info.user_name,
			FinalPacket             = <<Packet2/binary, GoodsPacket/binary, OkPacket/binary, StylePacket/binary>>,
			misc_packet:send(NetPid, FinalPacket),
			admin_log_api:log_furnace(Player2, ?CONST_LOG_FUN_FURNACE_FORGE, 0, 0, NewEquipId, 0),
            OkPacket2               = message_api:msg_notice(?TIP_FURNACE_UPGRADE_OK_2, [{UserId, UserName}], [NewGoods], 
                                                             [{?TIP_SYS_EQUIP, misc:to_list(NewEquipId)}]),
            misc_app:broadcast_world_2(OkPacket2),
            
            % 放置
%%             Info    = Player3#player.info,
%%             Info2   = 
%%                 case NewGoods of
%%                     #goods{exts = Exts} ->
%%                         SkinId = Exts#g_equip.weapon_id,
%%                         case Idx of
%%                             ?CONST_GOODS_EQUIP_ARMOR ->
%%                                 Info#info{skin_armor = SkinId};
%%                             ?CONST_GOODS_EQUIP_WEAPON ->
%%                                 Info#info{skin_weapon = SkinId};
%%                             _ ->
%%                                 Info
%%                         end;
%%                     _ ->
%%                         Info
%%                 end,
%%             Player3_2 = Player3#player{info = Info2},
            Player4 = reset(Player2, CtnType, Ctn2, PartnerId),
            case Idx of
                ?CONST_GOODS_EQUIP_ARMOR ->
                    map_api:change_skin_armor(Player4);
                ?CONST_GOODS_EQUIP_WEAPON ->
                    map_api:change_skin_weapon(Player4);
                _ ->
                    ?ok
            end,
			Player5 = player_attr_api:refresh_attr_equip(Player4),
			{?ok, Result, Player5};
		{?error, _Result} ->
			{?error, 0, Player}
	end;
equip_forge_normal(Player, CtnType, Idx, NewEquipId, PartnerId) ->
    ?MSG_ERROR("user_id=[~p],ctn_type=[~p],idx=[~p],goods_id=[~p],partner_id=[~p]", 
               [Player#player.user_id, CtnType, Idx, NewEquipId, PartnerId]),
    {?error, 0, Player}.

merg_soul(Goods, []) ->
    Goods;
merg_soul(#goods{exts = Exts} = Goods, SoulList) ->
    NewSoulList = Exts#g_equip.soul_list,
    NewNoneCount = get_none_count(NewSoulList),
    SoulList1 = SoulList -- lists:duplicate(4, ?CONST_FURNACE_HOLE_STATE_NONE),
    SoulList2 = SoulList1 ++ lists:duplicate(NewNoneCount, ?CONST_FURNACE_HOLE_STATE_NONE),
    NullCount = 4 - length(SoulList2),
    SoulList3 = SoulList2 ++ lists:duplicate(NullCount, ?CONST_FURNACE_HOLE_STATE_NULL),
    Fun =
        fun(Id1, Id2) ->
                if 
                    Id1 > 4 ->
                        true;
                    Id2 > 4 ->
                        false;
                    true ->
                        Id1 < Id2
                end
        end,
    SoulList4 = lists:sort(Fun, SoulList3),
    NewExt = Exts#g_equip{soul_list = SoulList4},
    Goods#goods{exts = NewExt}.

get_none_count(NewSoulList) ->
    get_none_count(NewSoulList, 0).

get_none_count([], Count) ->
    Count;
get_none_count([?CONST_FURNACE_HOLE_STATE_NONE|Rest], Count) ->
    get_none_count(Rest, Count + 1);
get_none_count([_|Rest], Count) ->
    get_none_count(Rest, Count).
 

check_goods(Player, ?CONST_GOODS_CTN_BAG, _GoodsId, _Idx, _PartnerId) ->
    Bag = Player#player.bag,
    {?true, Bag, 0};
check_goods(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, GoodsId, Idx, 0) ->
    EquipList = Player#player.equip,
    UserId = Player#player.user_id,
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            Equip = erlang:element(Idx, GoodsTuple),
            case Equip of
                #mini_goods{goods_id = GoodsId} = Goods ->
                    {?true, EquipCtn, Goods};
                _ ->
                    {?false, EquipCtn, 0}
            end;
        _ ->
            {?false, ?null, 0}
    end;
check_goods(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, GoodsId, Idx, PartnerId) ->
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PARTNER, 0, PartnerId, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            Equip = erlang:element(Idx, GoodsTuple),
            case Equip of
                #mini_goods{goods_id = GoodsId} = Goods ->
                    {?true, EquipCtn, Goods};
                _ ->
                    {?false, EquipCtn, 0}
            end;
        _ ->
            {?false, ?null, 0}
    end;
check_goods(_Player, _CtnType, _GoodsId, _Idx, _PartnerId) ->
    {?false, ?null, 0}.

%% 检查普通锻造
check_equip_forge_normal(Player, CtnType, Idx, NewEquipId, PartnerId) ->
    ForgeInfo           = data_furnace:get_furnace_forge(NewEquipId),
    #rec_furnace_forge{scroll_id = ScrollId, material = [{GoodsId, _}|_], cost = GoldCost} = ForgeInfo,
    
    NetPid              = Player#player.net_pid,
    Bag                 = Player#player.bag,
    % 书    
    ScrollNum           = ctn_bag2_api:get_goods_count(Bag, ScrollId),
    % 原装备
    {IsGoodsEnough, Ctn, OldGoods}
                        = check_goods(Player, CtnType, GoodsId, Idx, PartnerId),    
    % 钱
    UserId              = Player#player.user_id,
    IsFitGold           =   case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost) of
                                {?ok, _, ?true} ->
                                    {?ok, 0, 0};
                                {?ok, _, ?false} ->
                                    {?error, ?TIP_COMMON_GOLD_NOT_ENOUGH};
                                {?error, ErrorCodeMoney} ->
                                    {?error, ErrorCodeMoney}
                            end,
    if
        ScrollNum < 1 ->                                %%卷轴不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_SCROLL_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_SCROLL_NOT_ENOUGH};   
        IsGoodsEnough =:= ?false -> %%材料不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_EQUIP_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_EQUIP_NOT_ENOUGH}; 
        ?error =:= erlang:element(1, IsFitGold) -> %% 铜钱不足
            {_, ErrorCode} = IsFitGold,
            ErrorPacket = message_api:msg_notice(ErrorCode),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ErrorCode};
        ?true ->
            {?ok, 1, ScrollId, GoodsId, GoldCost, OldGoods, Ctn}
    end.


%%
%% Local Functions
%%
