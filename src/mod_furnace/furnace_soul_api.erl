%% 附魂api
-module(furnace_soul_api).

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
-include("../../include/const.protocol.hrl").

%%
%% Exported Functions
%%
-export([msg_sc_compose_stone/1, msg_sc_add_stone/1, msg_sc_sub_stone/1, msg_sc_add_hole/1, msg_sc_change_stone/1, get_add_hole_cost/1]).

-export([make_equip/1,check_is_stone/1, equip_make_soul/9, get_equip_info/4, have_same_soul/1, testit/1, get_ctn/3, get_hole_list/1, get_stone_change_list/1]).

-export([compose_soul/3, add_stone/5, sub_stone/5, add_hole/4, get_stone_change_cost/1, change_stone/3, get_soul_attr_add/1]).

-export([get_stone_attr_add/1, get_stone_compose_id/1, get_stone_compose_cost/1, get_stone_sub_limit/1, get_stone_lv/1, get_hole_empty_count/2, get_stone_type/1]).

-export([get_stone_change_stone_cost/1, up_stone/5]).

-export([one_key_compose_calc/1, one_key_compose_stone/1]).

-export([check_is_inset_stone/1, one_key_transfer/5]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   根据装备#goods{} 返回具有附加属性 附魂属性装备#goods{}
%% @name   make_equip/1
%% @param  GoodsInfo
%% @return NewGoodsInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% furnace_soul_api:testit(2010133347).2010117055
testit(Id) ->
	make_equip(data_goods:get_goods(Id)).

%% 检查装备是否有镶嵌宝石
check_is_inset_stone(#mini_goods{} = Goods) ->
	check_is_inset_stone(goods_api:mini_to_goods(Goods));
check_is_inset_stone(#goods{exts = Ext}) when is_record(Ext, g_equip)->
	StoneList = Ext#g_equip.soul_list,
	lists:filter(fun(Id) -> check_is_stone(Id) end, StoneList) =/= [];
check_is_inset_stone(_) ->
	?false.

get_soul_attr_add(SoulList) ->
    get_soul_attr_add(SoulList, []).
get_soul_attr_add([], AttList) ->
    AttList;
get_soul_attr_add([Id|Rest], AttList) ->
    case Id of
        ?CONST_FURNACE_HOLE_STATE_EMPTY ->
            get_soul_attr_add(Rest, AttList);
        ?CONST_FURNACE_HOLE_STATE_NULL ->
            get_soul_attr_add(Rest, AttList);
        _ ->
            Attr = get_stone_attr_add(Id),
            get_soul_attr_add(Rest, [Attr|AttList])
    end.

get_stone_attr_add(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Type = Rec#rec_furnace_stone.type,
            Value = Rec#rec_furnace_stone.value,
            {Type, Value};
        _ ->
            {0, 0}
    end.

get_stone_type(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.type;
        _ ->
            0
    end.


get_stone_change_list(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.change_list;
        _ ->
            []
    end.

check_is_stone(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            ?true;
        _ ->
            ?false
    end.

get_stone_compose_id(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.next_id;
        _ ->
            Id
    end.

get_stone_compose_cost(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.cost_gold;
        _ ->
            0
    end.

get_stone_change_stone_cost(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.change_cost;
        _ ->
            0
    end.

get_stone_sub_limit(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.subtype;
        _ ->
            {}
    end.

get_add_hole_cost(Level) ->
    Cost = round((Level/10)*3000),
    case data_mall:get_mall({3, 1093000002}) of
        Rec when is_tuple(Rec) ->
            Gold = Rec#rec_mall.c_price,
            {Cost,[1093000002], Gold};
        _ ->
            {Cost,[1093000002], 0}
    end.

get_stone_lv(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.lv;
        _ ->
            0
    end.

get_stone_change_cost(Id) ->
    case data_furnace:get_furnace_stone(Id) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.change_cost;
        _ ->
            0
    end.

%% 宝石转换
change_stone(#player{user_id = UserId, bag = Bag} = Player, Index, Count) ->
	try
		StoneInfo = 
			case get_equip_info(Player, ?CONST_GOODS_CTN_BAG, 0, Index) of
				Tuple when is_record(Tuple, goods) ->
					Tuple;
				_ ->
					throw({?error, not_goods})
			end,
		TotalCount = ctn_bag2_api:get_goods_count(Bag, StoneInfo#goods.goods_id),
		case TotalCount < Count of
			?true ->
				?MSG_ERROR("count not enough", []),
				throw({?error, not_enough});
			?false ->
				?ok
		end,
		case ctn_bag2_api:is_full(Bag) of
			?true ->
				misc_packet:send_tips(UserId, ?TIP_COMMON_BAG_NOT_ENOUGH),
				throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH});
			?false ->
				?ok
		end,
		Price = get_stone_change_stone_cost(StoneInfo#goods.goods_id),
		Money = player_money_api:lookup_money(UserId),
		CountGoldLimit = erlang:min(Count, Money#money.gold_bind div Price),
		case CountGoldLimit of
			0 ->
				Packet = message_api:msg_sc_window(?CONST_SYS_GOLD_BIND),
				misc_packet:send(UserId, Packet),
				%%player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Price, ?CONST_COST_STONE_CHANGE),
				{?ok, Player};
			_ ->
				{Player2, Nth, NewList, DirtyList} = changeStone(Player, StoneInfo, CountGoldLimit, [], []),
				ChangeCount = CountGoldLimit - Nth,
				CostGold = Price * ChangeCount,
				case ChangeCount > StoneInfo#goods.count of
					?true ->
						{?ok, Bag2, GoodsList2, Packet2} = ctn_bag2_api:get_by_idx(UserId, Player2#player.bag, Index),
						{?ok, Bag3, GoodsList3, Packet3} = 
							ctn_bag2_api:get_by_id(UserId, Bag2, StoneInfo#goods.goods_id, ChangeCount - StoneInfo#goods.count),
						DirtyList2 = ctn_bag2_api:mark_dirty(GoodsList2, DirtyList, ?CONST_SYS_FALSE),
						DirtyList3 = ctn_bag2_api:mark_dirty(GoodsList3, DirtyList2, ?CONST_SYS_FALSE),
						PacketDirty = goods_api:pack_dirty(Player2#player{bag = Bag3}, DirtyList3),
						PacketBag = <<Packet2/binary, Packet3/binary, PacketDirty/binary>>;
					?false ->
						{?ok, Bag3, GoodsList3, PacketBagT} = ctn_bag2_api:get_by_idx(UserId, Player2#player.bag, Index, ChangeCount),
						DirtyList2 = ctn_bag2_api:mark_dirty(GoodsList3, DirtyList, ?CONST_SYS_FALSE),
						PacketDirty = goods_api:pack_dirty(Player2#player{bag = Bag3}, DirtyList2),
						PacketBag = <<PacketBagT/binary, PacketDirty/binary>>
				end,
				case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, CostGold, ?CONST_COST_STONE_CHANGE) of
					?ok ->
						PacketMsg = msg_sc_change_stone(NewList),
						misc_packet:send(UserId, <<PacketBag/binary, PacketMsg/binary>>),
						{?ok, Player2#player{bag = Bag3}};
					_ ->
						?MSG_ERROR("gold not enough", [])
				end
		end
	catch
		throw:{?error, ErrorCode} ->
			?MSG_ERROR("change stone error:~p", [ErrorCode]);
		E:R ->
			?MSG_ERROR("Error:~w, Reason:~w, Stacktrace:~w", [E, R, erlang:get_stacktrace()])
	end.

changeStone(#player{} = Player, _StoneInfo, 0, NewList, DirtyList) ->
	{Player, 0, NewList, DirtyList};
changeStone(#player{user_id = UserId, bag = Bag} = Player, StoneInfo, Nth, NewList, DirtyList) ->
	case ctn_bag2_api:is_full(Bag) of
		?true ->
			misc_packet:send_tips(UserId, ?TIP_COMMON_BAG_NOT_ENOUGH),
			{Player, Nth, NewList, DirtyList};
		?false ->
			GoodsId = StoneInfo#goods.goods_id,
			ChangeList = get_stone_change_list(GoodsId),
			Rand = misc:rand(1, length(ChangeList)),
			ChangeType = lists:nth(Rand, ChangeList),
			Type = get_stone_type(ChangeType),
			NewListStone = 
				case lists:keyfind(Type, 1, NewList) of
					?false ->
						[{Type, 1}|NewList];
					{Type, TypeCount} ->
						lists:keyreplace(Type, 1, NewList, {Type, TypeCount + 1})
				end,
			Goods = goods_api:make(ChangeType, 1),
			{?ok, Bag2, DirtyList2} = ctn_bag2_api:set_stack_list_dirty(UserId, Bag, Goods, 0, DirtyList),%ctn_bag_api:put(Player#player{bag = Bag}, Goods, ?CONST_COST_STONE_CHANGE, 1, 1, 1, 0, 0, 1, []),
			?MSG_DEBUG("[~p]", [DirtyList2]),
			changeStone(Player#player{bag = Bag2}, StoneInfo, Nth - 1, NewListStone, DirtyList2)
	end.
            
            
make_equip(Goods) ->
	case data_furnace:get_special_equip(Goods#goods.goods_id) of
		SpecEquip when is_record(SpecEquip, rec_special_equip) ->
			Exts	= Goods#goods.exts,
			SoulList= SpecEquip#rec_special_equip.soul_list,
			SoulAttr= furnace_mod:trans_soul_id_value2(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, SoulList),
			NewExts = Exts#g_equip{attr_soul = SoulAttr, soul_list = SoulList},
			Goods#goods{exts = NewExts};
		_Other -> make_equip2(Goods)
	end.

make_equip2(GoodsInfo = #goods{color = Color, sub_type = SubType, exts = Exts}) ->
    SoulMakeInfo    = data_furnace:get_furnace_soul_make(Color),
    Num             = case misc_random:odds_one(SoulMakeInfo#rec_equip_soul_make.soul_init) of
						  ?null -> 0;
						  NumTemp -> NumTemp
					  end,
	Odds            = SoulMakeInfo#rec_equip_soul_make.soul_make_odds,
    SoulList        = furnace_mod:get_some_soul(Num, Odds, SubType),
%% 	?MSG_ERROR("Num ~p, SoulList ~p", [Num, SoulList]),
    SoulAttr        = furnace_mod:trans_soul_id_value2(GoodsInfo#goods.sub_type, GoodsInfo#goods.color, GoodsInfo#goods.lv, SoulList),
    NewExts         = Exts#g_equip{attr_soul = SoulAttr, soul_list = SoulList},
    GoodsInfo#goods{exts = NewExts}.

have_same(_, []) -> ?false;
have_same(StoneType, [Id|RestStoneList]) ->
    case get_stone_type(Id) of
        StoneType ->
            ?true;
        _ ->
            have_same(StoneType, RestStoneList)
    end.
add_stone(Player, CtnType, PartnerId, Index, StoneIndex) ->
    UserId = Player#player.user_id,
    EquipInfo       = get_equip_info(Player, CtnType, PartnerId, Index),
    case get_equip_info(Player, ?CONST_GOODS_CTN_BAG, 0, StoneIndex) of
        StoneInfo when is_record(StoneInfo, goods) andalso StoneInfo#goods.type == ?CONST_GOODS_EQUIP_STONE ->
            StoneId = StoneInfo#goods.goods_id,
            SubType = EquipInfo#goods.sub_type,
            Ext = EquipInfo#goods.exts,
            StoneList = Ext#g_equip.soul_list,
            StoneType = get_stone_type(StoneId),
            case have_same(StoneType, StoneList) of
                ?true ->
                    misc_packet:send_tips(UserId, ?TIP_GOODS_STONE_ADD_SAME);
                _ ->
                    case string:chr(StoneList, ?CONST_FURNACE_HOLE_STATE_EMPTY) of
                        0 ->
                            ?MSG_ERROR("no empty hole to add stone !!!", []);
                        Nth ->
                            LimitType = get_stone_sub_limit(StoneId),
                            LimitList = tuple_to_list(LimitType),
                            case lists:member(SubType, LimitList) of
                                ?false ->
                                    ?MSG_ERROR("not in limit subtype can not add", []);
                                _ ->
                                    NewStoneList = stone_replace(StoneList, Nth, StoneId),
                                    NewExt = Ext#g_equip{soul_list = NewStoneList},
                                    NewEquip = EquipInfo#goods{exts = NewExt},
                                    {?ok, Player2} = furnace_mod:update_one_equip(Player, CtnType, Index, PartnerId, NewEquip),
                                    {?ok, Container, _NewGoodsList, Packet} = ctn_bag2_api:get_by_id(UserId, Player2#player.bag, StoneId, 1),
                                    PacketMsg = msg_sc_add_stone(?true),
                                    misc_packet:send(UserId, <<Packet/binary, PacketMsg/binary>>),
                                    Player3 = Player2#player{bag = Container},
                                    {?ok, Player4} = 
                                        if
											CtnType == ?CONST_GOODS_CTN_BAG ->
                                                {?ok, Player3};
                                            PartnerId == 0 ->
                                                Player5 = player_attr_api:refresh_attr_equip(Player3),
												StoneLv = get_stone_lv(StoneId),
												plus_stone_num(Player5, StoneLv, 1);
                                            ?true ->
                                                Player5 = partner_api:refresh_attr_equip(Player3, PartnerId),
												StoneLv = get_stone_lv(StoneId),
												plus_stone_num(Player5, StoneLv, 1)
                                        end,
                                    {?ok, Player4}
                            end
                    end
            end;
        _ ->
            ?ok
    end.

%% 增加减少镶嵌的四级以上宝石数量
plus_stone_num(Player, StoneLv, Num) ->
	Info = Player#player.info,
	StoneNum = Info#info.stone_num,
	NewStoneNum = StoneNum + Num,
	if StoneLv >= 4 andalso NewStoneNum >= 0 ->
		   {?ok, Player3} =
			   if NewStoneNum =:= 16 ->
					  %% {?ok, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_FIRST_STONE, 0, 1),%% 成就
					  new_serv_api:add_honor_title(Player, ?CONST_NEW_SERV_FIRST_STONE, ?CONST_ACHIEVEMENT_FIRST_STONE);
				  ?true ->
					  {?ok, Player}
			   end,
		   Info2 = Player3#player.info, 
		   NewInfo = Info2#info{stone_num = NewStoneNum},
		   {?ok, Player3#player{info = NewInfo}};
	   true ->
		   {?ok, Player}
	end.

stone_replace(StoneList, Nth, StoneId) ->
    {L, [_|R]} = lists:split(Nth - 1, StoneList),
    L ++ [StoneId|R].



get_hole_list(#goods{} = Goods) ->
    Ext = Goods#goods.exts,
    HoleList = Ext#g_equip.soul_list,
    Fun =
        fun(Hole) ->
                {Hole}
        end,
    lists:map(Fun, HoleList);
get_hole_list(#mini_goods{} = MiniGoods) ->
    Ext = MiniGoods#mini_goods.exts,
    HoleList = Ext#g_equip.soul_list,
    Fun =
        fun(Hole) ->
                {Hole}
        end,
    lists:map(Fun, HoleList).
    

add_hole(Player, CtnType, PartnerId, Index) ->
    UserId = Player#player.user_id,
    EquipInfo = get_equip_info(Player, CtnType, PartnerId, Index),
    Ext = EquipInfo#goods.exts,
    Level = EquipInfo#goods.lv,
    StoneList = Ext#g_equip.soul_list,
    case string:chr(StoneList, ?CONST_FURNACE_HOLE_STATE_NULL) of
        0 ->
            ?MSG_ERROR("not have hole to hole", []),
            ?ok;
        Nth ->
            {Gold, Items, Cash} = get_add_hole_cost(Level),
            case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, Gold) of
                {?ok, _Money, ?true} -> 
                    case check_and_use(UserId, Items, Player#player.bag, <<>>) of
                        {Container, Packet1} ->
                            Result = ?true;
                        _ ->
                            Container = Player#player.bag,
                            Packet1 = <<>>,
                            case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_STONE_ADD_HOLE) of
                                ?ok ->
                                    Result = ?true;
                                _ ->
                                    Result = ?false
                            end
                    end,
                    case Result of
                        ?true ->
                            player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_STONE_ADD_HOLE),
                            NewStoneList = stone_replace(StoneList, Nth, ?CONST_FURNACE_HOLE_STATE_EMPTY),
                            NewExt = Ext#g_equip{soul_list = NewStoneList},
                            NewEquip = EquipInfo#goods{exts = NewExt, bind = ?CONST_GOODS_BIND},
                            {?ok, Player2} = furnace_mod:update_one_equip(Player#player{bag = Container}, CtnType, Index, PartnerId, NewEquip),
                            Packet2 = msg_sc_add_hole(?true),
                            misc_packet:send(Player2#player.user_id, <<Packet1/binary, Packet2/binary>>),
                            {?ok, Player2};
                        _ ->
                            ?ok
                    end;
                _ ->
                    misc_packet:send_tips(UserId, ?TIP_COMMON_GOLD_NOT_ENOUGH)
            end
    end.

check_and_use(_UserId, [], Bag, Packet) ->
    {Bag, Packet};
check_and_use(UserId, [GoodsId|Rest], Bag, Packet) ->
    case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, 1) of
        {?ok, Container, _NewGoodsList, Packet2} ->
			admin_log_api:log_goods(UserId, 0, ?CONST_COST_STONE_ADD_HOLE, GoodsId, 1, misc:seconds()),
            check_and_use(UserId, Rest, Container, <<Packet2/binary, Packet/binary>>);
        _ ->
            ?false
    end.
	
sub_stone(Player, CtnType, PartnerId, Index, StoneIndex) ->
    UserId = Player#player.user_id,
    EquipInfo = get_equip_info(Player, CtnType, PartnerId, Index),
    Ext = EquipInfo#goods.exts,
    StoneList = Ext#g_equip.soul_list,
    case ctn_bag2_api:is_full(Player#player.bag) of
        ?true ->
            misc_packet:send_tips(UserId, ?TIP_COMMON_BAG_NOT_ENOUGH);
        _ ->
            case lists:nth(StoneIndex, StoneList) of
                ?CONST_FURNACE_HOLE_STATE_EMPTY ->
                    ?ok;
                ?CONST_FURNACE_HOLE_STATE_NULL ->
                    ?ok;
                StoneId ->
                    NewList = stone_replace(StoneList, StoneIndex, ?CONST_FURNACE_HOLE_STATE_EMPTY),
                    NewExt = Ext#g_equip{soul_list = NewList},
                    NewGoods = EquipInfo#goods{exts = NewExt},
                    Stone = goods_api:make(StoneId, ?CONST_GOODS_BIND, 1),
                    {?ok, Player2} = furnace_mod:update_one_equip(Player, CtnType, Index, PartnerId, NewGoods),
                    case ctn_bag_api:put(Player2, Stone, ?CONST_COST_STONE_ADD_STONE, 1, 1, 1, 0, 0, 1, []) of
                        {?ok, Player3, _, Packet} ->
							StoneLv = get_stone_lv(StoneId),
							{?ok, Player4} = plus_stone_num(Player3, StoneLv, -1), 
                            PacketMsg = msg_sc_sub_stone(?true),
                            misc_packet:send(UserId, <<Packet/binary, PacketMsg/binary>>),
                            Player5 = 
                                if
                                    CtnType == ?CONST_GOODS_CTN_BAG ->
                                        Player4;
                                    PartnerId == 0 ->
                                        player_attr_api:refresh_attr_equip(Player4);
                                    ?true ->
                                        partner_api:refresh_attr_equip(Player4, PartnerId)
                                end,
                            {?ok, Player5};
                        _ ->
                            ?ok
                    end
            end
    end.
            
    

get_hole_empty_count([], {HoleEmpty, HoleNull, HoleEquip}) ->
    {HoleEmpty, HoleNull, HoleEquip};
get_hole_empty_count([Hole|RestHole], {HoleEmpty, HoleNull, HoleEquip}) ->
    case Hole of
        ?CONST_FURNACE_HOLE_STATE_EMPTY ->
            get_hole_empty_count(RestHole, {HoleEmpty + 1, HoleNull, HoleEquip});
        ?CONST_FURNACE_HOLE_STATE_NULL ->
            get_hole_empty_count(RestHole, {HoleEmpty, HoleNull + 1, HoleEquip});
        _ ->
            get_hole_empty_count(RestHole, {HoleEmpty, HoleNull, HoleEquip + 1})
    end.
   

up_stone(Player, CtnType,PartnerId,EquipIndex,StoneIndex) ->
    UserId = Player#player.user_id,
    case check_up_soul(Player, CtnType,PartnerId,EquipIndex,StoneIndex) of
        ?false ->
            ?MSG_ERROR("check failed", []),
            {?ok, Player};
        {NewEquipInfo, NewGoodsId, StoneId, BuyCount, BuyCost} ->
            GoldCost = get_stone_compose_cost(StoneId),
            case player_money_api:check_money(UserId, ?CONST_SYS_CASH, BuyCost) of
                 {?ok, _Money, ?true} -> 
                    case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost, ?CONST_COST_STONE_COMPOSE) of
                        ?ok ->
                            admin_log_api:log_goods(UserId, 0, ?CONST_COST_STONE_COMPOSE, StoneId, 1, misc:seconds()),
                            Container = get_ctn(Player, CtnType, PartnerId),
                            case ctn_bag2_api:replace(CtnType, UserId, PartnerId, Container, EquipIndex, NewEquipInfo) of
                                {?error, Tips2} ->
                                    misc_packet:send_tips(UserId, Tips2),
                                    {?ok, Player};
                                {?ok, Container2, Packet} ->
                                    CostCount = 2 - BuyCount,
                                    Player2 = set_ctn(Player, CtnType, Container2, PartnerId),
                                    player_money_api:minus_money(UserId, ?CONST_SYS_CASH, BuyCost, ?CONST_COST_STONE_COMPOSE),
                                    PacketSuccess = msg_sc_compose_stone(?true),
                                    case CostCount == 0 of
                                        ?true ->
                                            {?ok, Bag2, PacketBag} = {?ok, Player2#player.bag, <<>>};
                                        _ ->
                                            {?ok, Bag2, _GoodsList, PacketBag} = ctn_bag2_api:get_by_id(UserId, Player2#player.bag, StoneId, CostCount)
                                    end,
                                    misc_packet:send(UserId, <<Packet/binary,PacketSuccess/binary, PacketBag/binary>>),
									Player3 = 
										if
											PartnerId == 0 ->
												player_attr_api:refresh_attr_equip(Player2);
											?true ->
												partner_api:refresh_attr_equip(Player2, PartnerId)
										end,
									{?ok, Player4} = up_stone_activity(Player3, StoneId, NewGoodsId, BuyCount),
									{?ok, Player4#player{bag = Bag2}}
                            end;
                        {?error, _ErrorCode} ->
                            ?MSG_ERROR("gold not enough", [])
                    end;
                _ ->
                    misc_packet:send_tips(UserId, ?TIP_COMMON_CASH_NOT_ENOUGH)
            end
    end.
		
%% 处理涉及宝石升级的成就，活动等
up_stone_activity(Player, StoneId, NewStoneId, BuyCount) ->
	UserId = Player#player.user_id,
	NewLv = get_stone_lv(NewStoneId),
	%% 运营活动宝石合成送礼包
	yunying_activity_mod:activity_unlimitted_award(Player, NewLv, 7),
	%% 宝石合成送材料——手动领取
	yunying_activity_mod:stone_compose_count(Player, NewLv, 1),
	if BuyCount > 0 -> %有购买宝石行为
		   OldLv = get_stone_lv(StoneId),
		   yunying_activity_mod:add_activity_stone_value(UserId, OldLv, BuyCount, 1);
	   ?true ->
		   skip
	end,
	%% 宝石合成送积分
	yunying_activity_mod:add_activity_stone_value(UserId, NewLv, 1, 2),
	%% 春节红包活动
	case NewLv of
		4 ->
			spirit_festival_activity_api:receive_redbag(UserId, 16, 4);
		6 ->
			spirit_festival_activity_api:receive_redbag(UserId, 16, 18);
		8 ->
			spirit_festival_activity_api:receive_redbag(UserId, 16, 64);
		_ ->
			skip
	end,
	{?ok, Player2} = new_serv_api:finish_achieve(Player, ?CONST_NEW_SERV_STONE, NewLv, 1),
	if NewLv =:= 4 ->
		   plus_stone_num(Player2, NewLv, 1);
	   true ->
		   {?ok, Player2}
	end.

%% 一键转移宝石
%% CtnType1 背包 CtnType2 身上(角色或者伙伴装备栏)
%% EquipInfo1 背包 EquipInfo2身上
one_key_transfer(#player{user_id = UserId} = Player, Index1, CtnType2, PartnerId2, Index2)
  when CtnType2 =:= ?CONST_GOODS_CTN_EQUIP_PLAYER orelse CtnType2 =:= ?CONST_GOODS_CTN_EQUIP_PARTNER ->
	try
		CtnType1 = ?CONST_GOODS_CTN_BAG,
		PartnerId1 = 0,
		EquipInfo1 = get_equip_info(Player, CtnType1, PartnerId1, Index1),
		EquipInfo2 = get_equip_info(Player, CtnType2, PartnerId2, Index2),
		?ok = chk_transfer_condition(EquipInfo1, EquipInfo2),
		{Num, Gold, GoodsId, Cash} = calc_transfer_cost(EquipInfo2, EquipInfo1),
		{?ok, Player2, Packet} = transfer_cost(Player, Num, Gold, GoodsId, Cash),
		{?ok, Player3} = transfer_stone(Player2, CtnType1, PartnerId1, Index1, CtnType2, PartnerId2, Index2, EquipInfo2, EquipInfo1, Num),
		Packet2 = furnace_api:msg_sc_ok_transfer(?CONST_SYS_TRUE),
		TipPacket = message_api:msg_notice(?TIP_FURNACE_TRANSFER_OK),
		misc_packet:send(UserId, <<Packet/binary, Packet2/binary, TipPacket/binary>>),
		{?ok, Player3}
	catch
		throw:{?error, ErrorCode} ->
			?MSG_ERROR("one key transfer ErrorCode:~w", [ErrorCode]),
			TipPacket2 = message_api:msg_notice(ErrorCode),
			Packet3 = furnace_api:msg_sc_ok_transfer(?CONST_SYS_FALSE),
			misc_packet:send(UserId, <<Packet3/binary, TipPacket2/binary>>),
			{?ok, Player};
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()]),
			{?ok, Player}
	end;
one_key_transfer(Player, _Index1, _CtnType2, _PartnerId2, _Index2) ->
	{?ok, Player}.

%% 转移宝石操作
%% CtnType1 背包 CtnType2 身上(角色或者伙伴装备栏)
%% EquipInfo1 身上 EquipInfo2 背包
transfer_stone(Player, CtnType1, PartnerId1, Index1, CtnType2, PartnerId2, Index2, EquipInfo1, EquipInfo2, Num) ->
	Ext1		= EquipInfo1#goods.exts,
	StoneList1	= Ext1#g_equip.soul_list,
	StoneTuple = get_stone_list(StoneList1),
	F1 = fun({StoneIdx1, _Id1}, Acc1) ->
				 stone_replace(Acc1, StoneIdx1, ?CONST_FURNACE_HOLE_STATE_EMPTY)
		 end,
	NewList1	= lists:foldl(F1, StoneList1, StoneTuple),
	NewExt1		= Ext1#g_equip{soul_list = NewList1},
	NewGoods1	= EquipInfo1#goods{exts = NewExt1},

	Ext2		= EquipInfo2#goods.exts,
	StoneList2	= Ext2#g_equip.soul_list,
	EmptyHole	= get_hole_list_by_state(StoneList2, ?CONST_FURNACE_HOLE_STATE_EMPTY),
	NullHole	= get_hole_list_by_state(StoneList2, ?CONST_FURNACE_HOLE_STATE_NULL),
	HoleList	= EmptyHole ++ lists:sublist(NullHole, Num),
%	?MSG_ERROR("EmptyHole:~w, NullHole:~w, HoleList:~w, Num:~w", [EmptyHole, NullHole, HoleList, Num]),
	F2 = fun({_StoneIdx2, Id2}, {Acc2, Acc3}) ->
				 Idx = lists:nth(Acc3, HoleList),
				 {stone_replace(Acc2, Idx, Id2), Acc3 + 1}
		 end,
	{NewList2, _A3}	= lists:foldl(F2, {StoneList2, 1}, StoneTuple),
	NewExt2		= Ext2#g_equip{soul_list = NewList2},
	NewGoods2	= EquipInfo2#goods{exts = NewExt2},
	
	{?ok, Player2} = furnace_mod:update_one_equip(Player, CtnType1, Index1, PartnerId1, NewGoods2),	%% CtnType1 背包
	{?ok, Player3} = furnace_mod:update_one_equip(Player2, CtnType2, Index2, PartnerId2, NewGoods1),%% CtnType2 身上
	
%% 	F3 = fun({_StoneIdx3, Id3}, Acc4) ->
%% 				 StoneLv = get_stone_lv(Id3),
%% 				 {?ok, TmpPlayer} = plus_stone_num(Acc4, StoneLv, -1),
%% 				 {?ok, TmpPlayer2} = plus_stone_num(TmpPlayer, StoneLv, 1),
%% 				 TmpPlayer2
%% 		 end,
	Player4 = Player3,%lists:foldl(F3, Player3, StoneTuple),
	Player5 = 
		case PartnerId2 =:= 0 of
			?true ->
				player_attr_api:refresh_attr_equip(Player4);
			?false ->
				partner_api:refresh_attr_equip(Player4, PartnerId2)
		end,
	{?ok, Player5}.

%% 获取宝石id列表
get_stone_list(StoneList) ->
	F = fun(Id, {Acc1, Acc2}) ->
				case check_is_stone(Id) of
					?true ->
						{[{Acc2, Id}|Acc1], Acc2 + 1};
					?false ->
						{Acc1, Acc2 + 1}
				end
		end,
	{A1, _A2} = lists:foldl(F, {[], 1}, StoneList),
	lists:reverse(A1).

%% 获取状态为空的孔列表
get_hole_list_by_state(StoneList, State) ->
	F = fun(Id, {Acc1, Acc2}) ->
				case Id =:= State of
					?true ->
						{[Acc2|Acc1], Acc2 + 1};
					?false ->
						{Acc1, Acc2 + 1}
				end
		end,
	{A1, _A2} = lists:foldl(F, {[], 1}, StoneList),
	lists:reverse(A1).

%% 检查转移宝石条件
%% EquipInfo1:背包 EquipInfo2:身上
chk_transfer_condition(EquipInfo1, EquipInfo2) ->
	Power1 = calc_base_power(EquipInfo1),
	Power2 = calc_base_power(EquipInfo2),
%	?MSG_ERROR("Power1:~w, Power2:~w", [Power1, Power2]),
	case Power1 >= Power2 of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_FURNACE_TRANSFER_CON_NOT_ENOUGH})
	end,
	case check_is_inset_stone(EquipInfo1) of
		?false ->
			?ok;
		?true ->
			throw({?error, ?TIP_FURNACE_TRANSFER_CON_NOT_ENOUGH})
	end,
	case check_is_inset_stone(EquipInfo2) of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_FURNACE_TRANSFER_CON_NOT_ENOUGH})
	end.

%% 计算装备的基础战斗力
calc_base_power(Goods) when is_record(Goods, goods) ->
	Exts = Goods#goods.exts,
	BaseAttr = Exts#g_equip.attr,
	player_attr_api:caculate_power(BaseAttr).

%% 计算转移花费
%% EquipInfo1 身上 EquipInfo2 背包
calc_transfer_cost(EquipInfo1, EquipInfo2) ->
	Ext1 = EquipInfo1#goods.exts,
	StoneList1 = Ext1#g_equip.soul_list,
	Num1 = erlang:length(lists:filter(fun(Id) -> check_is_stone(Id) end, StoneList1)),
	Ext2 = EquipInfo2#goods.exts,
	StoneList2 = Ext2#g_equip.soul_list,
	Num2 = erlang:length(lists:filter(fun(Id) -> Id =:= ?CONST_FURNACE_HOLE_STATE_EMPTY end, StoneList2)),
	Num = erlang:max(0, Num1 - Num2),
	Level = EquipInfo2#goods.lv,
	{Gold, [GoodsId|_], Cash} = get_add_hole_cost(Level),
	{Num, Gold, GoodsId, Cash}.

%% 转移扣费
transfer_cost(Player, ?CONST_SYS_FALSE, _Gold, _GoodsId, _Cash) -> %% 不需要打孔费用
	{?ok, Player, <<>>};
transfer_cost(#player{user_id = UserId, bag = Bag} = Player, Num, Gold, GoodsId, Cash) ->
	HaveNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
	case player_money_api:minus_money(UserId, ?CONST_SYS_BGOLD_FIRST, Gold * Num, ?CONST_COST_STONE_TRANSFER) of
		?ok ->	%% 扣除铜钱
			?ok;
		{?error, ErrorCode} ->
			throw({?error, ErrorCode})
	end,
	if
		HaveNum =:= ?CONST_SYS_FALSE ->	%% 没有龙鳞钻
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash * Num, ?CONST_COST_STONE_TRANSFER) of
				?ok ->
					{?ok, Player, <<>>};
				{?error, ErrorCode2} ->
					throw({?error, ErrorCode2})
			end;
		HaveNum >= Num ->				%% 龙鳞钻足够
			case ctn_bag2_api:get_by_id(UserId, Bag, GoodsId, Num) of
				{?ok, Bag2, _GoodsList, Packet} ->
					admin_log_api:log_goods(UserId, ?CONST_SYS_FALSE, ?CONST_COST_STONE_TRANSFER, GoodsId, Num, misc:seconds()),
					{?ok, Player#player{bag = Bag2}, Packet};
				{?error, ErrorCode2} ->
					throw({?error, ErrorCode2})
			end;
		?true ->						%% 部分龙鳞钻，部分元宝
			NeedNum = Num - HaveNum,
			{Player2, Packet2} =
				case ctn_bag2_api:get_by_id(UserId, Bag, GoodsId, HaveNum) of
				{?ok, Bag2, _GoodsList, Packet} ->
					admin_log_api:log_goods(UserId, ?CONST_SYS_FALSE, ?CONST_COST_STONE_TRANSFER, GoodsId, HaveNum, misc:seconds()),
					{Player#player{bag = Bag2}, Packet};
				{?error, ErrorCode2} ->
					throw({?error, ErrorCode2})
			end,
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash * NeedNum, ?CONST_COST_STONE_TRANSFER) of
				?ok ->
					{?ok, Player2, Packet2};
				{?error, ErrorCode3} ->
					throw({?error, ErrorCode3})
			end
	end.
			
%% 计算一键合成宝石
one_key_compose_calc(#player{bag = #ctn{goods = Goods}} = Player) ->
	try
		?ok = check_can_ok_com_stone(Player),
		F = fun(#mini_goods{goods_id = GId, count = GC, idx = Idx}, Acc) ->
					Lv = get_stone_lv(GId),
					case check_is_stone(GId) andalso Lv < ?CONST_FURNACE_STONE_MAX_LEVEL of
						?true ->
							case lists:keytake(GId, 1, Acc) of
								?false ->
									[{GId, GC, Idx} | Acc];
								{value, {GId, GC2, Idx2}, Acc1} ->
									[{GId, GC + GC2, Idx2} | Acc1]
							end;
						?false ->
							Acc
					end;
			   (_, Acc) ->
					Acc
			end,
		StoneList = lists:foldr(F, [], erlang:tuple_to_list(Goods)),
		F2 = fun({GId, GC, Idx}, {Acc1, Acc2}) when GC >= ?CONST_FURNACE_STONE_COMPOSE_COUNT ->
					 GC2 = GC div ?CONST_FURNACE_STONE_COMPOSE_COUNT,
					 {Acc1 + GC2 * get_stone_compose_cost(GId), [{GId, GC2, Idx} | Acc2]};
				(_, Acc) ->
					 Acc
			 end,
		lists:foldl(F2, {0, []}, StoneList)
	catch
		T:R ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [T, R, erlang:get_stacktrace()]),
			{0, []}
	end.

%% 一键合成宝石
one_key_compose_stone(#player{user_id = UserId} = Player) ->
	try
		?ok = check_can_ok_com_stone(Player),
		{GoldCost, StoneList} = one_key_compose_calc(Player),
		case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost) of
			{?ok, _Money, ?true} ->
				F = fun({_GoodsId, Count, Index}, Acc) ->
							{?ok, NewPlayer} = compose_soul(Acc, Index, Count),
							NewPlayer
					end,
				NewPlayer = lists:foldl(F, Player, StoneList),
				{?ok, NewPlayer};
			_ ->
				misc_packet:send_tips(UserId, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH),
				{?ok, Player}
		end
	catch
		T:R ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [T, R, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 检查是否能一键合成宝石
check_can_ok_com_stone(#player{info = Info}) ->
	VipLv = Info#info.vip#vip.lv,
	case player_vip_api:is_ok_compose_stone(VipLv) of
		?CONST_SYS_TRUE ->
			?ok;
		_ ->
			throw({?error, vip_lv_not_enough})
	end.

compose_soul(#player{user_id = UserId} = Player, Index, Count) ->
    case check_compose_soul(Player, Index, Count) of
        ?false ->
            ?MSG_ERROR("check failed", []),
            {?ok, Player};
        {GoodsId,  OldGoodsId, Bag3, PacketBag, BuyCost, BuyCount} ->
            GoldCost = Count * get_stone_compose_cost(OldGoodsId),
            case player_money_api:check_money(UserId, ?CONST_SYS_CASH, BuyCost) of
                 {?ok, _Money, ?true} ->
                    case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost, ?CONST_COST_STONE_COMPOSE) of
                        ?ok ->
                            NewGood = goods_api:make(GoodsId, ?CONST_GOODS_BIND, Count),
							OldLv   = get_stone_lv(OldGoodsId),
							NewLv	= get_stone_lv(GoodsId),
							admin_log_api:log_goods(UserId, 0, ?CONST_COST_STONE_COMPOSE, OldGoodsId, Count, misc:seconds()),
                            case ctn_bag_api:put(Player#player{bag = Bag3}, NewGood, ?CONST_COST_STONE_COMPOSE, 1, 1, 1, 0, 0, 1, []) of
                                {?error, Tips2} ->
                                    misc_packet:send_tips(UserId, Tips2),
                                    {?ok, Player};
                                {?ok, Player2, _, Packet2} ->
                                    player_money_api:minus_money(UserId, ?CONST_SYS_CASH, BuyCost, ?CONST_COST_STONE_COMPOSE),
                                    PacketSuccess = msg_sc_compose_stone(?true),
                                    misc_packet:send(UserId, <<PacketBag/binary, Packet2/binary, PacketSuccess/binary>>),
                                    {?ok, Player3} = new_serv_api:finish_achieve(Player2, ?CONST_NEW_SERV_STONE, NewLv, Count),
									lists:foreach(fun(_N)->yunying_activity_mod:activity_unlimitted_award(Player3,NewLv,7) end,lists:seq(1, Count)),         %运营活动宝石合成送礼包
									yunying_activity_mod:stone_compose_count(Player3,NewLv,Count),		%宝石合成送材料——手动领取
									if BuyCount > 0 ->
										   yunying_activity_mod:add_activity_stone_value(Player3#player.user_id, OldLv, BuyCount, 1);%宝石购买送积分
									   ?true ->
										   skip
									end,
									yunying_activity_mod:add_activity_stone_value(Player3#player.user_id, NewLv, Count, 2), %宝石合成送积分
                                    %% 春节红包活动
									case NewLv of
										4 ->
											spirit_festival_activity_api:receive_redbag(UserId, 16, 4 * Count);
										6 ->
											spirit_festival_activity_api:receive_redbag(UserId, 16, 18 * Count);
										8 ->
											spirit_festival_activity_api:receive_redbag(UserId, 16, 64 * Count);
										_ ->
											skip
									end,
									{?ok, Player3}
                            end;
                        {?error, _ErrorCode} ->
                            ?MSG_ERROR("gold not enough", [])
                    end;
                _ ->
                    misc_packet:send_tips(UserId, ?TIP_COMMON_CASH_NOT_ENOUGH)
            end
    end.
        

%% 刻印
equip_make_soul(Player,CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo,SoulFromList,SoulToList) ->
	case check_equip_soul(Player,CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo,SoulFromList,SoulToList) of
        {?ok, ExtFrom, ExtTo, EquipFromInfo, EquipToInfo, Cost} ->
            case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_FURNACE_SOUL) of
                ?ok ->
					BindFrom		= EquipFromInfo#goods.bind,
					BindTo			= EquipToInfo#goods.bind,
					IsChangeFrom    = check_soul_change(ExtFrom#g_equip.soul_list, SoulFromList),
					IsChangeTo      = check_soul_change(ExtTo#g_equip.soul_list, SoulToList),
					{IsBindFrom, IsBindTo} = real_bind(BindFrom, BindTo, IsChangeFrom, IsChangeTo),
					ExtTo2			= ExtTo#g_equip{soul_list = SoulToList},
                    EquipToInfo2    = EquipToInfo#goods{exts = ExtTo2, bind = IsBindTo},
					
					ExtFrom2		= ExtFrom#g_equip{soul_list = SoulFromList},
                    EquipFromInfo2  = EquipFromInfo#goods{exts = ExtFrom2, bind = IsBindFrom},
                    
					{_, Player2} 	= furnace_mod:update_one_equip(Player, CtnFrom, IndexFrom, PartnerFrom, EquipFromInfo2),
					{_, Player3} 	= furnace_mod:update_one_equip(Player2, CtnTo, IndexTo, PartnerTo, EquipToInfo2),
					Player4      	= furnace_mod:refresh_attr_equip(Player3, CtnFrom, PartnerFrom),
					Player5      	= furnace_mod:refresh_attr_equip(Player4, CtnTo, PartnerTo),
					{?ok, Player6}  = achievement_api:add_achievement(Player5, ?CONST_ACHIEVEMENT_EQUIP_SOUL, 0, 1),
					{_, Player7} 	= welfare_api:add_pullulation(Player6, ?CONST_WELFARE_SOUL, 0, 1),
					admin_log_api:log_soul(Player7,CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo,Cost), %%日志记录 
                    {?ok, Player7};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end;
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

%% 检查是否获得新属性
check_soul_change(_OutSoulList,  []) -> ?false;
check_soul_change(OutSoulList,  [Soul|SoulList]) ->
	case lists:member(Soul, OutSoulList) of
		?false ->  %%原来无此属性 说明新获得
			?true;
		?true ->   %%原来有该属性
			check_soul_change(OutSoulList,  SoulList)
	end.

%% 刻印影响绑定
real_bind(?CONST_GOODS_BIND, ?CONST_GOODS_BIND, _, _) ->
	{?CONST_GOODS_BIND, ?CONST_GOODS_BIND};
real_bind(?CONST_GOODS_BIND, ?CONST_GOODS_UNBIND, _, IsChangeTo) ->
	case IsChangeTo of
		?true ->
			{?CONST_GOODS_BIND, ?CONST_GOODS_BIND};
		?false ->
			{?CONST_GOODS_BIND, ?CONST_GOODS_UNBIND}
	end;
real_bind(?CONST_GOODS_UNBIND, ?CONST_GOODS_BIND, IsChangeFrom, _) ->
	case IsChangeFrom of
		?true ->
			{?CONST_GOODS_BIND, ?CONST_GOODS_BIND};
		?false ->
			{?CONST_GOODS_UNBIND, ?CONST_GOODS_BIND}
	end;
real_bind(?CONST_GOODS_UNBIND, ?CONST_GOODS_UNBIND, _, _) ->
	{?CONST_GOODS_UNBIND, ?CONST_GOODS_UNBIND}.

%% real_bind(?CONST_GOODS_BIND, _) ->
%% 	?CONST_GOODS_BIND;
%% real_bind(_, ?CONST_GOODS_BIND) ->
%% 	?CONST_GOODS_BIND;
%% real_bind(_, _) ->
%% 	?CONST_GOODS_UNBIND.

get_next_soul_id(SoulId) ->
   get_stone_compose_id(SoulId).

get_bug_cost(GoodsId) ->
    case data_furnace:get_furnace_stone(GoodsId) of
        Rec when is_tuple(Rec) ->
            Rec#rec_furnace_stone.stone_price;
        _ ->
            0
    end.

check_up_soul(Player, CtnType,PartnerId,EquipIndex,StoneIndex) ->
    EquipInfo = get_equip_info(Player, CtnType, PartnerId, EquipIndex),
    Ext = EquipInfo#goods.exts,
    SoulList = Ext#g_equip.soul_list,
    StoneId = lists:nth(StoneIndex, SoulList),
    AllCount = ctn_bag2_api:get_goods_count(Player#player.bag, StoneId),
    BuyCount = max(2  - AllCount, 0),
    BuyCost = BuyCount * get_bug_cost(StoneId),
    case check_is_stone(StoneId) of
        ?false ->
            ?MSG_ERROR("not stone ~w", [EquipInfo#goods.goods_id]),
            ?false;
        _ ->
            case get_stone_lv(StoneId) >= 9 of
                ?true ->
                    ?MSG_ERROR("lv to high", []),
                    ?false;
                _ ->
                    NewGoodsId = get_next_soul_id(StoneId),
                    NewSoulList = stone_replace(SoulList, StoneIndex, NewGoodsId),
                    NewEquipInfo = EquipInfo#goods{exts = Ext#g_equip{soul_list = NewSoulList}},
                    {NewEquipInfo, NewGoodsId, StoneId, BuyCount, BuyCost}
            end
    end.

check_compose_soul(#player{user_id = UserId, bag = Bag} = Player, Index, Count) ->
    #goods{goods_id = GoodsId, count = GoodsCount, lv = Lv} = get_equip_info(Player, ?CONST_GOODS_CTN_BAG, 1, Index),
    AllCount = ctn_bag2_api:get_goods_count(Bag, GoodsId),
    CostCount = Count * ?CONST_FURNACE_STONE_COMPOSE_COUNT,
    BuyCount = max(CostCount  - AllCount, 0),
    BuyCost = BuyCount * get_bug_cost(GoodsId),
    case check_is_stone(GoodsId) of
        ?false ->
            ?MSG_ERROR("not stone ~w", [GoodsId]),
            ?false;
        _ ->
            case GoodsCount >= CostCount - BuyCount of
                ?false ->
                    {?ok, Bag2, _GoodsList, Packet2} = ctn_bag2_api:get_by_idx(UserId, Bag, Index),
                    {?ok, Bag3, _GoodsList2, Packet3} = 
                        ctn_bag2_api:get_by_id(UserId, Bag2, GoodsId, CostCount - GoodsCount - BuyCount),
                    PacketBag = <<Packet2/binary, Packet3/binary>>;
                _ ->
                    {?ok, Bag3, _GoodsList, PacketBag} = ctn_bag2_api:get_by_idx(UserId, Bag, Index, CostCount - BuyCount)
            end,
            case Lv >= ?CONST_FURNACE_STONE_MAX_LEVEL of
                ?true ->
                    ?false;
                _ ->
                    NewGoodsId = get_next_soul_id(GoodsId),
                    NewIdCount = ctn_bag2_api:get_goods_count(Bag, NewGoodsId),
                    {?ok, EmptyCount} = ctn_bag2_api:empty_count(Bag),
                    case  EmptyCount >= 1 orelse NewIdCount =/= 0 of
                        ?false ->
                            misc_packet:send_tips(UserId, ?TIP_COMMON_BAG_NOT_ENOUGH),
                            ?false;
                        _ ->
                            {NewGoodsId, GoodsId, Bag3, PacketBag, BuyCost, BuyCount}
                    end
            end
    end.

%% 检查装备附魂
check_equip_soul(Player,CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo,SoulFromList,SoulToList) ->
    EquipFromInfo		= get_equip_info(Player, CtnFrom, PartnerFrom, IndexFrom),
    EquipToInfo			= get_equip_info(Player, CtnTo, PartnerTo, IndexTo),
	try
		?ok				= check_equip_soul_goods(EquipFromInfo, EquipToInfo, CtnFrom, PartnerFrom, IndexFrom, CtnTo, PartnerTo, IndexTo),
		?ok				= check_equip_soul_type(EquipFromInfo#goods.sub_type, EquipToInfo#goods.sub_type),
		#goods{lv = _LvFrom, exts = ExtFrom} = EquipFromInfo,
		SoulFromList2	= ExtFrom#g_equip.soul_list,
		#goods{lv = _LvTo, exts = ExtTo} = EquipToInfo,
		SoulToList2		= ExtTo#g_equip.soul_list,
		?ok				= check_equip_soul_num(SoulFromList2, SoulToList2),
		
		IsCorrectSoul	= is_correct_soul(SoulFromList, SoulToList, SoulFromList2, SoulToList2),
		HaveSameSoul	= have_same_soul(SoulFromList, SoulToList),
		TempCost		= calc_soul_cost(SoulToList, SoulToList2),
		TempCost2		= calc_soul_cost(SoulFromList, SoulFromList2),
		Cost			= TempCost + TempCost2,
		if
			IsCorrectSoul =:= ?false ->
				{?error, ?TIP_COMMON_BAD_ARG};
			HaveSameSoul =:= ?false ->
				{?error, ?TIP_FURNACE_SAME_SOUL_ONE_EQUIP};
			?true ->
				{?ok, ExtFrom, ExtTo, EquipFromInfo, EquipToInfo, Cost}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

check_equip_soul_goods(EquipFrom, EquipTo, CtnFrom, PartnerFrom, IndexFrom, CtnTo, PartnerTo, IndexTo)
  when is_record(EquipFrom, goods) andalso is_record(EquipTo, goods) ->
	if
		(CtnFrom =:= CtnTo andalso PartnerFrom =:= PartnerTo andalso IndexFrom =:= IndexTo) ->
		   throw({?error, ?TIP_COMMON_BAD_ARG});%%同一件装备
		?true -> ?ok
	end;
check_equip_soul_goods(_, _, _, _, _, _, _, _) ->
	throw({?error, ?TIP_COMMON_BAD_ARG}).

check_equip_soul_type(?CONST_GOODS_EQUIP_ARMOR, ?CONST_GOODS_EQUIP_FUSION) -> ?ok;
check_equip_soul_type(?CONST_GOODS_EQUIP_FUSION, ?CONST_GOODS_EQUIP_ARMOR) -> ?ok;
check_equip_soul_type(Type, Type) -> ?ok;
check_equip_soul_type(_FromType, _ToType) -> throw({?error, ?TIP_FURNACE_SUBTYPE_ERROR}).

check_equip_soul_num(SoulFromList, SoulToList) ->
	SoulFromNum	= length(SoulFromList),
	SoulToNum	= length(SoulToList),
	if
		(SoulFromNum + SoulToNum) > 0 -> ?ok;
		?true -> throw({?error, ?TIP_FURNACE_BOTH_NO_SOUL})
	end.

%% 检查前端发送的附魂数据是否合法
is_correct_soul(SoulFromList, SoulToList, SoulFromList2, SoulToList2) ->
	NewList = lists:append(SoulFromList, SoulToList),
	OldList = lists:append(SoulFromList2, SoulToList2),
	NewList2 = total_soul_list(NewList),
	OldList2 = total_soul_list(OldList),
	compare_soul_list(NewList2, OldList2).

%% 汇总一组附魂（用来比较总的结果）
total_soul_list(List) ->
	total_soul_list(List, []).

total_soul_list([{Id, Lv}|T], Acc) ->
	case lists:keyfind(Id, 1, Acc) of
		{Id, Lv2} ->
			Acc2 = lists:keyreplace(Id, 1, Acc, {Id, Lv+Lv2}),
			total_soul_list(T, Acc2);
		_Other ->
			total_soul_list(T, [{Id, Lv}|Acc])
	end;
total_soul_list([], Acc) -> Acc.

%% 比较两组附魂是否完全相同
compare_soul_list([], []) -> ?true;
compare_soul_list([], _List) -> ?false;
compare_soul_list(_List, []) -> ?false;
compare_soul_list([{Id, Lv}|List], List2) ->
	case lists:any(fun({Id2,Lv2}) -> Id =:= Id2 andalso Lv =:= Lv2 end, List2) of
		?true ->
			List3 = lists:keydelete(Id, 1, List2),
			compare_soul_list(List, List3);
		?false -> ?false
	end.

%% 每组是否有相同的附魂属性
have_same_soul(SoulFromList) ->
	Fun = fun(Id) ->
				  case data_furnace:get_furnace_soul(Id) of
					  #rec_furnace_soul{type = Type} -> Type;
					  _Other ->
						  0
				  end
		  end,
	FromList = lists:map(Fun, SoulFromList),
	(erlang:length(lists:usort(FromList)) =:= erlang:length(FromList)).

have_same_soul(SoulFromList, SoulToList) ->
	Fun = fun({Id, _Lv}) ->
				  case data_furnace:get_furnace_soul(Id) of
					  #rec_furnace_soul{type = Type} -> Type;
					  _Other -> 0
				  end
		  end,
	FromList = lists:map(Fun, SoulFromList),
	ToList	 = lists:map(Fun, SoulToList),
	(erlang:length(lists:usort(FromList)) =:= erlang:length(FromList)) andalso
	(erlang:length(lists:usort(ToList)) =:= erlang:length(ToList)).

%% 计算附魂费用
calc_soul_cost(ResultList, OldList) ->
	calc_soul_cost(ResultList, OldList, 0).	
	
calc_soul_cost([], _List, Acc) -> Acc;
calc_soul_cost([{Id,Lv}|T], List, Acc) ->
	case lists:keyfind(Id, 1, List) of
		{Id, Lv2} ->
			FromLv	= misc:min(Lv, Lv2),
			ToLv    = misc:max(Lv, Lv2),
%% 			Cost = per_soul_cost(erlang:abs(Lv - Lv2)),
			Cost	= per_soul_cost(FromLv, ToLv, 0),
			calc_soul_cost(T, List, Acc+Cost);
		?false ->
			Cost = per_soul_cost(Lv),
			calc_soul_cost(T, List, Acc+Cost)
	end.

%% 升级刻印费用
per_soul_cost(FromLv, ToLv, Acc) when FromLv < ToLv ->
	RecCost = data_furnace:get_furnace_cost(FromLv + 1),
	Cost 	= RecCost#rec_furnace_cost.cost,
	NewAcc  = Cost + Acc,
	per_soul_cost(FromLv + 1, ToLv, NewAcc);
per_soul_cost(_FromLv, _ToLv, Acc) -> Acc.

%% 单个刻印费用
per_soul_cost(Lv) ->
	per_soul_cost(Lv, 0).

per_soul_cost(0, Acc) -> Acc;
per_soul_cost(Lv, Acc) ->
	RecCost = data_furnace:get_furnace_cost(Lv),
	Cost = RecCost#rec_furnace_cost.cost,
	per_soul_cost(Lv-1, Cost+Acc).
			
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获取背包/玩家/武将特定位置的装备信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_equip_info(Player, ?CONST_GOODS_CTN_BAG, _PartnerId, Index) ->
    Bag = Player#player.bag,
	element_equip(Index, Bag#ctn.goods);
get_equip_info(#player{user_id = UserId, equip = EquipList}, ?CONST_GOODS_CTN_EQUIP_PLAYER, _PartnerId, Index) ->
    case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
        ?false -> {};
        {{_UserId, _CtnType}, Container} ->
            element_equip(Index, Container#ctn.goods)
    end;
get_equip_info(#player{equip = EquipList}, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId, Index) ->
    case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
        ?false -> {};
        {{_UserId, _CtnType}, Container} ->
            element_equip(Index, Container#ctn.goods)
    end;

get_equip_info(_Player, _Other, _PartnerId, _Index) ->
    {}.

set_ctn(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, NewCtn, _PartnerId) ->
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    NewEquipList= lists:keyreplace({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList, {{UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, NewCtn}),
    Player#player{equip = NewEquipList};


set_ctn(Player, ?CONST_GOODS_CTN_EQUIP_PARTNER, NewCtn, PartnerId) ->
    EquipList = Player#player.equip,
    NewEquipList = lists:keyreplace({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1,  EquipList, {{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, NewCtn}),
    Player#player{equip = NewEquipList};

set_ctn(Player, ?CONST_GOODS_CTN_BAG, NewCtn, _PartnerId) ->
    Player#player{bag = NewCtn}.


get_ctn(Player, ?CONST_GOODS_CTN_BAG, _PartnerId) ->
    Player#player.bag;
get_ctn(#player{user_id = UserId, equip = EquipList}, ?CONST_GOODS_CTN_EQUIP_PLAYER, _PartnerId) ->
    case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
        ?false -> #ctn{};
        {{_UserId, _CtnType}, Container} ->
            Container
    end;
get_ctn(#player{equip = EquipList}, ?CONST_GOODS_CTN_EQUIP_PARTNER, PartnerId) ->
    case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
        ?false -> #ctn{};
        {{_UserId, _CtnType}, Container} ->
            Container
    end.

element_equip(Index, Goods) ->
	try 
        MiniGoods = element(Index, Goods),
        goods_api:mini_to_goods(MiniGoods)
	catch
        throw:{?error, _ErrorCode} -> 0;
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
            0 % 入参有误
    end.

%% 请求合成宝石返回
%%[IsSuccess]
msg_sc_compose_stone(IsSuccess) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_COMPOSE_STONE, ?MSG_FORMAT_FURNACE_SC_COMPOSE_STONE, [IsSuccess]).
%% 镶嵌宝石是否成功
%%[IsSuccess]
msg_sc_add_stone(IsSuccess) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_ADD_STONE, ?MSG_FORMAT_FURNACE_SC_ADD_STONE, [IsSuccess]).
%% 摘除宝石是否成功
%%[IsSuccess]
msg_sc_sub_stone(IsSuccess) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_SUB_STONE, ?MSG_FORMAT_FURNACE_SC_SUB_STONE, [IsSuccess]).
%% 请求打孔是否成功
%%[IsSuccess]
msg_sc_add_hole(IsSuccess) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_ADD_HOLE, ?MSG_FORMAT_FURNACE_SC_ADD_HOLE, [IsSuccess]).
%% 成功转化宝石列表
%%[{StoneType,StoneCount}]
msg_sc_change_stone(List1) ->
    misc_packet:pack(?MSG_ID_FURNACE_SC_CHANGE_STONE, ?MSG_FORMAT_FURNACE_SC_CHANGE_STONE, [List1]).
%% is_correct_soul([], _SoulFromList, _SoulToList) ->
%% 	?true;
%% is_correct_soul([{0, _LvTo, 0, _LvFrom}|T], SoulFromList, SoulToList) ->
%% 	is_correct_soul(T, SoulFromList, SoulToList);
%% is_correct_soul([{0, _LvTo, IdFrom, LvFrom}|T], SoulFromList, SoulToList) ->
%% 	ResultFrom = lists:keyfind(IdFrom, 1, SoulFromList),
%% 	if
%% 		ResultFrom =/= {IdFrom, LvFrom} ->
%% 			?false;
%% 		?true ->
%% 			is_correct_soul(T, SoulFromList, SoulToList)
%% 	end;
%% is_correct_soul([{IdTo, LvTo, 0, _LvFrom}|T], SoulFromList, SoulToList) ->
%% 	ResultTo = lists:keyfind(IdTo, 1, SoulToList),
%% 	if
%% 		ResultTo =/= {IdTo, LvTo} ->
%% 			?false;
%% 		?true ->
%% 			is_correct_soul(T, SoulFromList, SoulToList)
%% 	end;
%% is_correct_soul([{IdTo, LvTo, IdFrom, LvFrom}|T], SoulFromList, SoulToList) ->
%% 	try
%% 		{ResultFromId, ResultFromLv} = lists:keyfind(IdFrom, 1, SoulFromList),
%% 		{ResultToId, ResultToLv} = lists:keyfind(IdTo, 1, SoulToList),
%% 		if
%% 			(IdFrom =:= IdTo) andalso (LvTo+LvFrom =:= ResultToLv+ResultFromLv) ->
%% 				is_correct_soul(T, SoulFromList, SoulToList);
%% 			{IdFrom, LvFrom} =/= {ResultFromId, ResultFromLv}  ->
%% 				?false;
%% 			 {IdTo, LvTo} =/= {ResultToId, ResultToLv} ->
%% 				?false;
%% 			?true ->
%% 				is_correct_soul(T, SoulFromList, SoulToList)
%% 		end
%% 	catch
%% 		_:_ ->
%% 			?false
%% 	end;
%% is_correct_soul([_|_T], _SoulFromList, _SoulToList) ->
%% 	?false.

%% 处理附魂合并规则
%% handle_equip_soul([], SoulFromList, SoulToList) ->
%%     {treat_null_soul(SoulFromList), treat_null_soul(SoulToList)};
%% handle_equip_soul([{IdTo, LvTo, IdFrom, LvFrom}|T], SoulFromList, SoulToList) ->
%%     case (IdFrom =:= IdTo) of
%%         ?false ->			%非同种附魂，交换位置(一方可能为空)
%%             SoulFromList2 = lists:keydelete(IdFrom, 1, SoulFromList),
%%             SoulToList2 = lists:keydelete(IdTo, 1, SoulToList),
%% 			handle_equip_soul(T, [{IdTo, LvTo}|SoulFromList2], [{IdFrom, LvFrom}|SoulToList2]);
%%         ?true ->	%同种附魂，合并
%%             if
%%                 LvFrom + LvTo > 10 ->
%%                     MinusLv = LvFrom + LvTo - 10,
%% 					SoulToList2 = lists:keyreplace(IdTo, 1, SoulToList, {IdTo, 10}),
%% 					SoulFromList2 = lists:keyreplace(IdFrom, 1, SoulFromList, {IdFrom, MinusLv}),
%%                     handle_equip_soul(T, SoulFromList2, SoulToList2);
%%                 ?true ->	
%%                     SoulToList2 = lists:keyreplace(IdTo, 1, SoulToList, {IdTo, LvFrom + LvTo}),
%% 					SoulFromList2 = lists:keydelete(IdFrom, 1, SoulFromList),
%%                     handle_equip_soul(T, SoulFromList2, SoulToList2)
%%             end
%%     end.

%% 列表去掉空的附魂
%% treat_null_soul(List) ->
%% 	treat_null_soul(List, []).
%% 
%% treat_null_soul([], Acc) ->
%% 	Acc;
%% treat_null_soul([{Id, Lv}|T], Acc) when Lv > 0 ->
%% 	treat_null_soul(T, [{Id, Lv}|Acc]);
%% treat_null_soul([_|T], Acc) ->
%% 	treat_null_soul(T, Acc).

%% %% 计算刻印费用
%% calc_soul_cost(SoulIdList) ->
%% 	calc_soul_cost(SoulIdList, 0).
%% 
%% calc_soul_cost([], Acc) ->
%% 	Acc;
%% calc_soul_cost([{IdTo, LvTo, IdFrom, LvFrom}|T], Acc) ->
%% 	case (IdTo =:= IdFrom) of
%% 		?true ->
%% 			case LvTo + LvFrom >= 10 of
%% 				?true ->
%% 					Cost = per_soul_cost(10 - LvTo),
%% 					calc_soul_cost(T, Cost + Acc);
%% 				?false ->
%% 					Cost = per_soul_cost(LvFrom),
%% 					calc_soul_cost(T, Cost + Acc)
%% 			end;
%% 		?false ->
%% 			Cost = per_soul_cost(LvFrom) + per_soul_cost(LvTo),
%% 			calc_soul_cost(T, Cost + Acc)
%% 	end.



