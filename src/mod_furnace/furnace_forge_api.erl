%% 装备锻造/道具合成api
-module(furnace_forge_api).

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
-export([equip_forge/3, goods_forge/2]).

%%
%% API Functions
%%

%% 装备锻造
equip_forge(Player, EquipId, ?CONST_FURNACE_FORGE_DIRECT) ->
	equip_forge_direct(Player, EquipId);
equip_forge(Player, EquipId, ?CONST_FURNACE_FORGE_NORMAL) ->
	equip_forge_normal(Player, EquipId, ?CONST_FURNACE_FORGE_NORMAL);
%% equip_forge(Player, EquipId, ?CONST_FURNACE_UPGRADE_DIRECT) ->
%% 	equip_forge_direct(Player, EquipId);
equip_forge(Player, EquipId, ?CONST_FURNACE_UPGRADE_NORMAL) ->
	equip_forge_normal(Player, EquipId, ?CONST_FURNACE_UPGRADE_NORMAL);
equip_forge(Player, _EquipId, _) ->
	Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	{?error, 0, Player}.

%% 装备 直接锻造
equip_forge_direct(Player, EquipId) ->
	case check_equip_forge_direct(Player, EquipId) of
		{?ok, Result, CashCost, ScrollId, Materials} ->
		    %%扣金币 消耗卷轴  
%% 		    ?MSG_DEBUG("CashCost ~p", [CashCost]),
				case goods_api:use_goods_by_id_list(Player, Materials) of
					{?ok, Player2, _GList, UsePacket} ->
						case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, CashCost, ?CONST_COST_FURNACE_FORGE_DIRECT) of
							?ok ->
					            {?ok, NewBag, _GoodsList, Packet} = ctn_bag2_api:get_by_id(Player2#player.user_id, Player2#player.bag, ScrollId, 1),
					            
					            %%生成新装备 放入到背包
								[EquipInfo]				= goods_api:make(EquipId, ?CONST_GOODS_UNBIND, 1),
			%% 		            [EquipInfo]             = goods_api:make(EquipId, 1),
                                {?ok, Player3, _, Packet2} = ctn_bag_api:put(Player2#player{bag = NewBag}, [EquipInfo], ?CONST_COST_FURNACE_FORGE_DIRECT, 1, 1, 0, 0, 0, 1, []),
					            
					            OkPacket                = message_api:msg_notice(?TIP_FURNACE_FORGE_OK, [{?TIP_SYS_EQUIP, misc:to_list(EquipId)}]),
                                
                                %% 锻造任务
                                {?ok, Player4} = task_api:update_furnace(Player3, EquipInfo#goods.color),
					            
								%% 新服成就
%% 								{?ok, Player5}          = new_serv_api:finish_achieve(Player4, ?CONST_NEW_SERV_EQUIP_FORGE, EquipInfo#goods.color, 1),
					            FinalPacket = <<UsePacket/binary, Packet/binary, Packet2/binary, OkPacket/binary>>,
					            misc_packet:send(Player#player.net_pid, FinalPacket),
					            admin_log_api:log_furnace(Player, ?CONST_LOG_FUN_FURNACE_FORGE_DIRECT, 0, 0, EquipId, 0),
								F = fun({GoodsId, Num}) ->
											admin_log_api:log_goods(Player#player.user_id, 0, ?CONST_COST_FURNACE_FORGE_DIRECT, GoodsId, Num, misc:seconds());
									   (_) -> ?ok
									end,
								lists:foreach(F, Materials),
					            {?ok, Result, Player4};
					        _Other ->            %%检查有足够的铜钱 金币，却扣取失败？？？
					            {?error, 0, Player}
					    end;
					{error, Error} ->
					    MsgErrorPacket = message_api:msg_notice(Error),
			   		    misc_packet:send(Player#player.user_id, MsgErrorPacket),
					    ?ok
			   end;
		{?error, _Result} ->
			{?error, 0, Player}
	end.

%% 检查直接锻造  
check_equip_forge_direct(Player = #player{net_pid = NetPid, info = Info, bag = Bag}, EquipId) ->
	CanImForge  = player_vip_api:can_furnace_immediately(player_api:get_vip_lv(Info)),
    ForgeInfo   = data_furnace:get_furnace_forge(EquipId),
    #rec_furnace_forge{scroll_id = ScrollId, material = Materials} = ForgeInfo,
    
    EquipInfo   = data_goods:get_goods(EquipId),
    _EquipLv     = EquipInfo#goods.lv,
    _PlayerLv    = Info#info.lv,
    
    LackGoodsList = check_materials(Bag, Materials),
    CashCost    = get_material_cash(LackGoodsList),
    
    ScrollNum   = ctn_bag2_api:get_goods_count(Player#player.bag, ScrollId),
    {_, BagCeilRemain} = ctn_bag2_api:empty_count(Player#player.bag),
    
	if
        CanImForge =:= 0 ->
			ErrorPacket = message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_COMMON_VIPLEVEL_NOT_ENOUGH}; 
%% 		EquipLv > PlayerLv ->   %%装备等级超过人物  2012-11-28/黄思敏
%%             ErrorPacket = message_api:msg_notice(?TIP_FURNACE_LV_OVER_PLAYER),
%%             misc_packet:send(NetPid, ErrorPacket),
%%             {?error, ?TIP_FURNACE_LV_OVER_PLAYER};  
        ScrollNum < 1 ->        %%卷轴不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_SCROLL_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_SCROLL_NOT_ENOUGH};   
        BagCeilRemain < 1 ->    %%背包空间不足
            ErrorPacket = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        ?true ->
            {?ok, 1, CashCost, ScrollId, Materials}
    end.
%% 装备 普通锻造
equip_forge_normal(Player = #player{net_pid = NetPid, user_id = UserId, bag = Bag}, EquipId, Type) ->
	case check_equip_forge_normal(Player, EquipId, Type) of
		{?ok, Result, ScrollId, Materials, GoldCost} ->
			%%消耗卷轴和材料
			{?ok, NewBag, _GoodsList, Packet} = ctn_bag2_api:get_by_id(UserId, Bag, ScrollId, 1),
			misc_packet:send(Player#player.user_id, Packet),
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, ScrollId, 1, misc:seconds()),
            
			% 扣钱
            if(?CONST_FURNACE_UPGRADE_NORMAL =:= Type) -> 
                    player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost, ?CONST_COST_FURNACE_FORGE_COST);
              ?true ->
                    ?ok
            end,
            
			Fun = fun({GoodsId, GoodsNum}, {TempBag, TempPacket, OldEquipSoulList, OldBind}) ->
						  {?ok, NewBag2, GoodsList2, Packet2} = ctn_bag2_api:get_by_id(UserId, TempBag, GoodsId, GoodsNum),
                          admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_FURNACE_FORGE_COST, GoodsId, GoodsNum, misc:seconds()),
						  TempPacket2 = <<TempPacket/binary, Packet2/binary>>,
                          {EquipSoulList, Bind2} = 
                              if
                                  ?CONST_FURNACE_UPGRADE_NORMAL =:= Type ->
                                      [EquipGoods|_] = GoodsList2,
                                      Ext = EquipGoods#mini_goods.exts,
                                      if
                                          is_record(Ext, g_equip) ->
%%                                               ?MSG_DEBUG("old[~n~p~n~p~n]", [Ext#g_equip.soul_list, EquipGoods#goods.exts#g_equip.attr_soul]),
                                              {Ext#g_equip.soul_list, EquipGoods#mini_goods.bind};
                                          ?true ->
                                              {OldEquipSoulList, OldBind}
                                      end;
                                  ?true ->
                                      {OldEquipSoulList, OldBind}
                              end,
						  {NewBag2, TempPacket2, EquipSoulList, Bind2}
				  end,
			{NewBag3, NewPacket, NewOldEquipSoulList, NewBind} = lists:foldl(Fun, {NewBag, <<>>, [], ?CONST_GOODS_UNBIND}, Materials),
			%%生成新装备 放入到背包
            [EquipInfo]             = 
                        if
                            [] =:= NewOldEquipSoulList ->
                                goods_api:make(EquipId, ?CONST_GOODS_UNBIND, 1);
                            ?true ->
                                goods_api:make(EquipId, NewBind, 1)
                        end,
            NewEquipInfo            = merg_soul(EquipInfo, NewOldEquipSoulList),
			{?ok, Palyer_2, _, Packet3} = ctn_bag_api:put(Player#player{bag = NewBag3}, [NewEquipInfo], ?CONST_COST_FURNACE_FORGE_COST, 1, 1, 0, 0, 0, 1, []), 
            %% 锻造任务
            {?ok, Player2} = 
                case Type of
                    ?CONST_FURNACE_FORGE_NORMAL ->
                        task_api:update_furnace(Palyer_2, EquipInfo#goods.color);
                    _ ->
                        {?ok, Palyer_2}
                end,
			%% 新服成就
%% 			{?ok, Player3}          = new_serv_api:finish_achieve(Player2, ?CONST_NEW_SERV_EQUIP_FORGE, EquipInfo#goods.color, 1),
            OkPacket                = 
                case Type of
                    ?CONST_FURNACE_UPGRADE_NORMAL ->
                         InfoX    = Player2#player.info,
                         UserName = InfoX#info.user_name,
                         OkPacket2               = message_api:msg_notice(?TIP_FURNACE_UPGRADE_OK_2, [{UserId, UserName}], [EquipInfo], 
                                                             []),
                         misc_app:broadcast_world_2(OkPacket2),
        			     message_api:msg_notice(?TIP_FURNACE_UPGRADE_OK, [{?TIP_SYS_EQUIP, misc:to_list(EquipId)}]);
                    _ ->
    			         message_api:msg_notice(?TIP_FURNACE_FORGE_OK, [{?TIP_SYS_EQUIP, misc:to_list(EquipId)}])
                end,
			FinalPacket             = <<NewPacket/binary, Packet3/binary, OkPacket/binary>>,
			misc_packet:send(NetPid, FinalPacket),
			admin_log_api:log_furnace(Player2, ?CONST_LOG_FUN_FURNACE_FORGE, 0, 0, EquipId, 0),
			{?ok, Result, Player2};
		{?error, _Result} ->
			{?error, 0, Player}
	end.
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
 
  

%% 检查普通锻造
check_equip_forge_normal(#player{user_id = UserId, net_pid = NetPid, info = _Info, bag = Bag}, EquipId, Type) ->
    ForgeInfo           = data_furnace:get_furnace_forge(EquipId),
    #rec_furnace_forge{scroll_id = ScrollId, material = Materials, cost = GoldCost} = ForgeInfo,
    
%%     EquipInfo           = data_goods:get_goods(EquipId),
%%     EquipLv             = EquipInfo#goods.lv,
%%     PlayerLv            = Info#info.lv,
    
    ScrollNum           = ctn_bag2_api:get_goods_count(Bag, ScrollId),
    IsGoodsEnough       = check_materials2(Bag, Materials),
    {_, BagCeilRemain}  = ctn_bag2_api:empty_count(Bag),
    IsFitGold           = 
                    if(?CONST_FURNACE_UPGRADE_NORMAL =:= Type) ->
                            case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, GoldCost) of
                                {?ok, _, ?true} ->
                                    {?ok, 0, 0};
                                {?ok, _, ?false} ->
                                    {?error, ?TIP_COMMON_GOLD_NOT_ENOUGH};
                                {?error, ErrorCodeMoney} ->
                                    {?error, ErrorCodeMoney}
                            end;
                      ?true ->
                            {?ok, 0, 0}
                    end,
    if
%%         EquipLv > PlayerLv ->                           %%装备等级超过人物
%%             ErrorPacket = message_api:msg_notice(?TIP_FURNACE_LV_OVER_PLAYER),
%%             misc_packet:send(NetPid, ErrorPacket),
%%             {?error, ?TIP_FURNACE_LV_OVER_PLAYER};      
        ScrollNum < 1 ->                                %%卷轴不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_SCROLL_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_SCROLL_NOT_ENOUGH};   
        IsGoodsEnough =:= 0 andalso ?CONST_FURNACE_UPGRADE_NORMAL =:= Type -> %%材料不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_EQUIP_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_EQUIP_NOT_ENOUGH}; 
        IsGoodsEnough =:= 0 ->                          %%材料不足
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_MATERIAL_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_MATERIAL_NOT_ENOUGH}; 
        BagCeilRemain < 1 ->                            %%背包空间不足
            ErrorPacket = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        ?error =:= erlang:element(1, IsFitGold) -> %% 铜钱不足
            {_, ErrorCode} = IsFitGold,
            ErrorPacket = message_api:msg_notice(ErrorCode),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ErrorCode};
        ?true ->
            {?ok, 1, ScrollId, Materials, GoldCost}
    end.

%% 道具合成
goods_forge(Player = #player{user_id = UserId}, GoodsId) ->
	case goods_forge_check(Player, GoodsId) of
		{?ok, _Result, GoodsForge} ->
			GoodsId		= GoodsForge#rec_furnace_merge.goods_id,
			FormulaId	= GoodsForge#rec_furnace_merge.formula_id,
			PiecesList 	= GoodsForge#rec_furnace_merge.pieces,
			PiecesList2	= [{FormulaId, 1}|PiecesList],
			Player2		= do_goods_pieces(Player, PiecesList2),
			GoodsList	= goods_api:make(GoodsId, 1),
%% 			{?ok, Bag2, Packet} = ctn_bag2_api:set_list(UserId, Player2#player.bag, GoodsList, ?CONST_COST_FURNACE_MERGE),
			{?ok, Player3, _, Packet} = ctn_bag_api:put(Player2, GoodsList, ?CONST_COST_FURNACE_MERGE, 1, 2, 0, 0, 0, 1, []),
			Packet2		= message_api:msg_notice(?TIP_FURNACE_GOODS_FORGE_OK),
			misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>),
			admin_log_api:log_furnace(Player3, ?CONST_LOG_FUN_FURNACE_MERGE, 0, 0, GoodsId, 0),
			{?ok, 1, Player3};
		{?error, Result} ->
			{?error, Result, Player}
	end.

%% 检查道具合成条件
goods_forge_check(#player{net_pid = NetPid, bag = Bag}, GoodsId) ->
    GoodsForge                  = data_furnace:get_furnace_merge(GoodsId),
    {CanForge, FormulaId, PiecesList}		= merge_info(GoodsForge),
	PiecesList2					= [{FormulaId, 1}|PiecesList],
	IsEnough					= check_pieces_enough(Bag, PiecesList2),
    {?ok, BagEmptyCount}        = ctn_bag2_api:empty_count(Bag),
    if
        CanForge =:= ?false ->
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_NOT_GOODS_PIECE),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_NOT_GOODS_PIECE};
        IsEnough =:= ?false  ->
            ErrorPacket = message_api:msg_notice(?TIP_FURNACE_PIECES_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_FURNACE_PIECES_NOT_ENOUGH};
        BagEmptyCount < 1 ->
            ErrorPacket = message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
            misc_packet:send(NetPid, ErrorPacket),
            {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
        ?true ->
            {?ok, 1, GoodsForge}
    end.

%% 消耗道具
do_goods_pieces(Player, []) ->
	Player;
do_goods_pieces(Player, [{GoodsId, Num}|T]) ->
	{?ok, Bag2, _GoodsList, Packet} = ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, GoodsId, Num),
	misc_packet:send(Player#player.net_pid, Packet),
	do_goods_pieces(Player#player{bag = Bag2}, T).

%%
%% Local Functions
%%

%% 检查锻造材料
%% check_materials(Bag, Materials) ->
%%     Fun = fun({GoodsId, NeedNum}, {Flag, TempId, TempNum}) ->
%%                   GoodsNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
%%                   if
%%                       GoodsNum < NeedNum ->
%%                           {0, GoodsId, NeedNum-GoodsNum};
%%                       ?true ->
%%                           {Flag, TempId, TempNum}
%%                   end
%%           end,
%%     lists:foldl(Fun, {1, 0, 0}, Materials).
check_materials(Bag, Meterials) ->
	check_materials(Bag, Meterials, []).

check_materials(_Bag, [], Acc) ->
	Acc;
check_materials(Bag, [{GoodsId, NeedNum}|T], Acc) ->
	RealNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
	case (RealNum < NeedNum) of
		?true ->
			check_materials(Bag, T, [{GoodsId, (NeedNum-RealNum)}|Acc]);
		?false ->
			check_materials(Bag, T, Acc)
	end.
	

%% 检查锻造材料2
check_materials2(Bag, Materials) ->
    Fun = fun({GoodsId, NeedNum}, Flag) ->
                  GoodsNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
                  if
                      GoodsNum < NeedNum ->
                          0;
                      ?true ->
                          Flag
                  end
          end,
    lists:foldl(Fun, 1, Materials).

%% 获取缺少材料的折算元宝
get_material_cash(GoodsList) ->
	get_material_cash(GoodsList, 0).

get_material_cash([], Acc) ->
	Acc;
get_material_cash([{GoodsId, GoodsNum}|T], Acc) ->
	RecGoods = data_goods:get_goods(GoodsId),
    Exts     = RecGoods#goods.exts,
    Cash     = 
        if 
            is_record(Exts, g_func) ->
                Exts#g_func.convert_cash;
            is_record(Exts, g_equip) ->
                Exts#g_equip.upgrade_price
        end,
	get_material_cash(T, Acc+Cash*GoodsNum).

%% get_material_cash(0, GoodsId, NewNum) ->
%%     RecGoods = data_goods:get_goods(GoodsId),
%%     Exts     = RecGoods#goods.exts,
%%     Cash     = Exts#g_func.convert_cash,
%% 	?MSG_DEBUG("Cash ~p, NewNum ~p", [Cash, NewNum]),
%%     Cash * NewNum;
%% get_material_cash(1, _GoodsId, _NewNum) ->
%%     0;
%% get_material_cash(_, _GoodsId, _NewNum) ->
%%     0.

%% 道具合成信息
merge_info(GoodsForge) when is_record(GoodsForge, rec_furnace_merge) ->
    {?true, GoodsForge#rec_furnace_merge.formula_id, GoodsForge#rec_furnace_merge.pieces};
merge_info(_GoodsForge) ->
    {?false, 0, 0}.

%% 道具碎片是否充足
check_pieces_enough(_Bag, []) ->
	?true;
check_pieces_enough(Bag, [{GoodsId, Num}|T]) ->
	RealNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
	case (Num >= RealNum) of
		?true ->
			check_pieces_enough(Bag, T);
		?false ->
			?false
	end.




