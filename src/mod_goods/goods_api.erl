%% Author: zero
%% Created: 2012-7-20
%% Description: TODO: Add description to goods_api
-module(goods_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.task.hrl").
%%
%% Exported Functions
%%
-export([goods/1, make/2, make/3, goods_drop/1, get_goods_stack/1,get_attr_list/1, use_goods_by_type/4]).
-export([bind/1, unbind/1]).
-export([use_goods_by_id/3, use_goods_by_index/3, use_goods_by_id_list/2, calc_goods_power/2,
         pack_dirty/2, goods_to_mini/1, goods_to_mini/2, x/1, mini_to_goods/1]).

-export([
		 msg_group_goods/4,
		 msg_group_goods_equip/4,
		 msg_group_goods_weapon/4,
		 msg_goods_list_info/5,
		 msg_goods_list_remove/3,
		  
		 msg_goods_sc_ctn_info/4,
		 msg_goods_sc_goods_info/5,
		 msg_goods_sc_goods_equip_info/5,
		 msg_goods_sc_goods_remove/3,
		 msg_goods_sc_enlarge_ctn/2,
         msg_sc_open_remote/2
		]).

-export([zip_goods/1, unzip_goods/1]).

-export([add_goods_gm/3]).
%%
%% API Functions
%%

%% 获取道具信息  没有数据时返回 null
%% goods_api:goods(GoodsId).
%% arg 		: GoodsId
%% return 	: ?null | Goods
goods(GoodsId) ->
	data_goods:get_goods(GoodsId).
make(GoodsId, Count) ->
	make(GoodsId, ?CONST_GOODS_BIND, Count).
%% 生成物品
%% goods_api:make(GoodsId, Bind, Count).
%% arg 		: GoodsId, Bind, Count
%% return 	: {?error,ErrorCode} | Goods
make(GoodsId, Bind, Count) ->
	case data_goods:get_goods(GoodsId) of
        GoodsTemp when is_record(GoodsTemp, goods) ->
			case check_goods_limit(GoodsTemp) of
				?true ->
					Goods	= set_goods_bind(GoodsTemp, Bind),
					if
						Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP andalso 
						Goods#goods.sub_type =:= ?CONST_GOODS_EQUIP_HORSE -> %% 坐骑
							make_horse(Goods,Count);
						Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP ->	%% 装备
%% 							Goods2	= furnace_soul_api:make_equip(Goods),
							Goods3	= set_goods_time(Goods),
							make2(Goods3, Count, []);
						Goods#goods.type =:= ?CONST_GOODS_TYPE_WEAPON ->	%% 神兵碎片
							make_weapon_chips(Goods, Count);
						?true ->
							Goods2	= set_goods_time(Goods),
							make2(Goods2, Count, [])
					end;
				?false -> {?error, ?TIP_GOODS_FORBID_DROP}
			end;
        ?null -> {?error, ?TIP_GOODS_NOT_EXIST}
    end.

make2(Goods, Count, Acc) when Count > 0 ->
	Goods2	= set_goods_count(Goods, Count),
    Goods3 = change_goods_name(Goods2),
	make2(Goods, Count - Goods3#goods.count, [Goods3|Acc]);
make2(_Goods, Count, Acc) when Count =< 0 ->
	lists:reverse(Acc).

change_goods_name(#goods{name = Name} = Goods) when is_number(Name) ->
    Name2 = misc:to_binary(io_lib:format("~p", [Name])),
    Goods#goods{name = Name2};
change_goods_name(Goods) ->
    Goods.

%% 生成坐骑
make_horse(Goods,Count) ->
	case horse_api:make_horse(Goods) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		Goods2 ->			
			Goods3	= set_goods_time(Goods2),
			make2(Goods3, Count, [])
	end.

%% 生成神兵碎片
make_weapon_chips(Goods,Count) ->
	case weapon_api:make_weapon_chips(Goods) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		Goods2 ->			
			Goods3	= set_goods_time(Goods2),
			make2(Goods3, Count, [])
	end.


%% 检查物品世界掉落限制
check_goods_limit(Goods) when is_record(Goods, goods) ->
	GoodsId	= Goods#goods.goods_id,
	Limit	= (Goods#goods.flag)#g_flag.is_limit,
	if
		Limit =:= ?CONST_SYS_FALSE -> ?true;
		?true ->
			Seconds	= misc:seconds(),
			case ets_api:lookup(?CONST_ETS_PLAYER_GOODS_LIMIT, GoodsId) of
				{GoodsId, LimitTime} when LimitTime >= Seconds -> ?false;
				_ ->
					ets_api:insert(?CONST_ETS_PLAYER_GOODS_LIMIT, {GoodsId, Seconds + Limit}),
					?true
			end
	end;
check_goods_limit(_Goods) -> ?false.


%% 物品掉落
%% goods_api:goods_drop(1).
goods_drop(0) -> [];
goods_drop(DropId) -> goods_drop_api:goods_drop(DropId).
%% goods_drop(0) -> [];
%% goods_drop(DropId) ->
%%     GoodsList = 
%%     	case data_goods:get_goods_drop(DropId) of
%%     		?null -> [];
%%     		GoodsDropData ->
%%     			case misc_random:odds_one(GoodsDropData) of
%%     				?null -> [];
%%     				GoodsData ->
%%     					goods_drop(GoodsData, [])
%%     			end
%%     	end,
%%     % ?MSG_DEBUG("drop:~p", [GoodsList]),
%%     GoodsList.
%% 
%% %% goods_drop([{{GoodsId, Bind, Count}, Odds}|GoodsData], Acc) ->
%% goods_drop([{{GoodsId, Bind, Count}, Odds}|GoodsData], Acc) ->
%% 	Acc2	= case misc_random:odds(Odds, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
%% 				  ?true ->
%% 					  case make(GoodsId, Bind, Count) of
%% 						  GoodsList	when is_list(GoodsList) -> GoodsList ++ Acc;
%% 						  _ -> Acc
%% 					  end;
%% 				  ?false -> Acc
%% 			  end,
%% 	goods_drop(GoodsData, Acc2);
%% goods_drop([], Acc) ->
%% 	Acc.

%% 设置物品绑定
set_goods_bind(Goods, Bind) ->
	Goods#goods{bind = Bind}.

%% 设置物品数量
set_goods_count(Goods, Count) ->
	if Goods#goods.stack >= Count ->
		   Goods#goods{count = Count};
	   ?true ->
		   Goods#goods{count = Goods#goods.stack}
	end.

%% 设置物品有效期
set_goods_time(Goods) ->
	case Goods#goods.duration of
		0 -> Goods#goods{start_time = 0, end_time = 0};
		Time ->
			case Goods#goods.start_time of
				0 -> Goods#goods{end_time = misc:seconds() + Time};
				StartTime -> Goods#goods{end_time = StartTime + Time}
			end
	end.

%% 获取物品堆叠数
get_goods_stack(Goods) when is_record(Goods, goods) ->
	Goods#goods.stack;
get_goods_stack(GoodsId) when is_number(GoodsId)->
	Goods = goods(GoodsId),
	get_goods_stack(Goods);
get_goods_stack(_Any) -> 1.

%% 绑定物品
bind(Goods) 	-> set_goods_bind(Goods, ?CONST_GOODS_BIND).
%% 解绑定物品
unbind(Goods) 	-> set_goods_bind(Goods, ?CONST_GOODS_UNBIND).

use_goods_by_type(Player, Type, SubType, Count) ->
    goods_mod:use_by_type(Player, Type, SubType, Count).

%% 根据背包位置使用道具
%% @param  Idx     在背包中的位置
%% @param  Player  使用者信息
%% @param  Count   使用数量
%% @return {?ok,NewPlayer,Res,Packet} /{?error, ErrorCode, Player}
use_goods_by_index(Player, Idx, Count) ->
    goods_mod:use(Player, Idx, Count).

%% 根据物品id使用道具 - 只扣不使用
%% @param  GoodsId 道具id
%% @param  Count   数量
%% @param  Player  使用者信息
%% @return {?ok,NewPlayer,Res,Packet}/{?error, ErrorCode, Player2, Packet}
use_goods_by_id(Player,GoodsId, Count) ->
    goods_mod:use_by_id(Player,GoodsId, Count).

%% 根据列表使用 - 只扣不使用
%% @param  GoodsList  	[{GoodsId,Count},...] 道具id 数量
%% @param  Player  		使用者信息
%% @return {?ok,Player,Res,Packet}/{?error, ErrorCode}
use_goods_by_id_list(Player,GoodsList) ->
	use_goods_by_id_list2(Player,GoodsList,[],<<>>) .

use_goods_by_id_list2(Player,[],Res,Packet) ->
	{?ok,Player,Res,Packet};
use_goods_by_id_list2(Player, [{GoodsId,Count}|GoodsList], Res,Packet) ->
	Count2 = ctn_bag2_api:get_goods_count(Player#player.bag, GoodsId),
	if
		Count2 =:= 0 ->
			Res2 = [{GoodsId,Count} | Res],
			use_goods_by_id_list2(Player,GoodsList,Res2,Packet);
		Count2 < Count ->
			Res2 = [{GoodsId,(Count - Count2)} | Res],
			use_goods_by_id_list3(Player,GoodsList,GoodsId,Count2,Res2,Packet);
		?true ->
			use_goods_by_id_list3(Player,GoodsList,GoodsId,Count,Res,Packet)
	end.

use_goods_by_id_list3(Player,GoodsList,GoodsId,Count,Res,Packet) ->
    Bag = ctn_bag2_api:get_bag(Player),
	case ctn2_mod:get_by_id(Bag, GoodsId, Count) of
		{?ok, Bag2, _, ChangeList, RemoveList} ->
			UserId			= Player#player.user_id,
			BinGoodsInfo	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, ChangeList, ?CONST_SYS_FALSE),
			BinRemove		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveList),
			Packet2			= <<BinGoodsInfo/binary, BinRemove/binary>>,
			Player2			= ctn_bag2_api:set_bag(Player, Bag2),
			use_goods_by_id_list2(Player2,GoodsList,Res,<<Packet/binary,Packet2/binary>>);
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

calc_goods_power(_Player, Goods) when ?CONST_GOODS_TYPE_EQUIP =:= Goods#goods.type ->
    EquipExt = Goods#goods.exts,
    Attr = EquipExt#g_equip.attr,
    player_attr_api:caculate_power(Attr);
calc_goods_power(_, _) ->
    0.

%% 压缩结构
goods_to_mini([G|Tail], OldList) ->
    G2 = goods_to_mini(G),
    goods_to_mini(Tail, [G2|OldList]);
goods_to_mini([], List) ->
    List.
    
goods_to_mini(#goods{} = Goods) ->
    #goods{
           goods_id = GoodsId, exts = Exts, idx = Idx, count = Count,
           start_time = Stime, end_time = Etime, bind = IsBind, time_temp = TimeTemp 
          } = Goods,
    #mini_goods{
                goods_id = GoodsId, exts = Exts, idx = Idx, count = Count, 
                start_time = Stime, end_time = Etime, bind = IsBind, time_temp = TimeTemp 
                };
goods_to_mini(G) when is_list(G) ->
    goods_to_mini(G, []);
goods_to_mini(G) -> G.

mini_to_goods(#mini_goods{} = MiniGoods) ->
    #mini_goods{
                goods_id = GoodsId, exts = Exts, idx = Idx, count = Count, 
                start_time = Stime, end_time = Etime, bind = IsBind, time_temp = TimeTemp 
                } = MiniGoods,
    case data_goods:get_goods(GoodsId) of
        #goods{} = G ->
            G#goods{
                   goods_id = GoodsId, exts = Exts, idx = Idx, count = Count,
                   start_time = Stime, end_time = Etime, bind = IsBind, time_temp = TimeTemp 
                  };
        _ ->
            MiniGoods
    end;
mini_to_goods(Goods) ->
    Goods.
		
%%
%% Local Functions
%%

pack_dirty(Player, Dirty) ->
    goods_mod:pack_dirty(Player, Dirty).

%% 物品列表信息 
msg_goods_list_info(CtnType, UserId, PartnerId, GoodsList, IsNew) ->
	msg_goods_list_info(CtnType, UserId, PartnerId, GoodsList, IsNew, <<>>).
msg_goods_list_info(CtnType, UserId, PartnerId, [MiniGoods|GoodsList], IsNew, BinMsg)
  when is_record(MiniGoods, mini_goods) ->
    Goods = data_goods:get_goods(MiniGoods#mini_goods.goods_id),
	Packet	= case Goods#goods.type of
				  ?CONST_GOODS_TYPE_EQUIP ->
					  msg_goods_sc_goods_equip_info(CtnType, UserId, PartnerId, MiniGoods, IsNew);
				  ?CONST_GOODS_TYPE_WEAPON ->
                      msg_goods_sc_goods_weapon_info(CtnType, UserId, PartnerId, MiniGoods, IsNew);
				  _ -> 
					  msg_goods_sc_goods_info(CtnType, UserId, PartnerId, MiniGoods, IsNew)
			  end,
	msg_goods_list_info(CtnType, UserId, PartnerId, GoodsList, IsNew, <<BinMsg/binary, Packet/binary>>);
msg_goods_list_info(CtnType, UserId, PartnerId, [_Goods|GoodsList], IsNew, BinMsg) ->
	msg_goods_list_info(CtnType, UserId, PartnerId, GoodsList, IsNew, BinMsg);
msg_goods_list_info(_CtnType, _UserId, _PartnerId, [], _IsNew, BinMsg) -> BinMsg.

%% 物品列表移除 
msg_goods_list_remove(CtnType, UserId, GoodsList) ->
	msg_goods_list_remove(CtnType, UserId, GoodsList, <<>>).
msg_goods_list_remove(CtnType, UserId, [MiniGoods|GoodsList], BinMsg)
  when is_record(MiniGoods, mini_goods) ->
	Packet	= msg_goods_sc_goods_remove(CtnType, UserId, MiniGoods#mini_goods.idx),
	msg_goods_list_remove(CtnType, UserId, GoodsList, <<BinMsg/binary, Packet/binary>>);
msg_goods_list_remove(CtnType, UserId, [_Goods|GoodsList], BinMsg) ->
	msg_goods_list_remove(CtnType, UserId, GoodsList, BinMsg);
msg_goods_list_remove(_CtnType, _UserId, [], BinMsg) -> BinMsg.

%% 2102 	返回容器信息 
msg_goods_sc_ctn_info(CtnType, UserId, PartnerId, Usable) ->
	Datas	= [UserId, PartnerId, CtnType, Usable],
	misc_packet:pack(?MSG_ID_GOODS_SC_CTN_INFO, ?MSG_FORMAT_GOODS_SC_CTN_INFO, Datas).
%% 2110 	普通物品信息 
msg_goods_sc_goods_info(CtnType, UserId, PartnerId, Goods, IsNew) ->
	Datas = msg_group_goods(CtnType, UserId, PartnerId, Goods),
    D2 = tuple_to_list(Datas),
	misc_packet:pack(?MSG_ID_GOODS_SC_GOODS_INFO, ?MSG_FORMAT_GOODS_SC_GOODS_INFO, D2 ++ [IsNew]).

%% 2120 	物品装备信息 
msg_goods_sc_goods_equip_info(CtnType, UserId, PartnerId, Goods, IsNew) ->
	Datas = msg_group_goods_equip(CtnType, UserId, PartnerId, Goods),
    D2 = tuple_to_list(Datas),
    SoulList = furnace_soul_api:get_hole_list(Goods),
%%     ?MSG_ERROR("SoulList is ~w", [SoulList]),
	misc_packet:pack(?MSG_ID_GOODS_SC_GOODS_EQUIP_INFO, ?MSG_FORMAT_GOODS_SC_GOODS_EQUIP_INFO, D2++[IsNew] ++ [SoulList]).

%% 2120 	物品神兵信息 
msg_goods_sc_goods_weapon_info(CtnType, UserId, PartnerId, Goods, IsNew) ->
	Datas = msg_group_goods_weapon(CtnType, UserId, PartnerId, Goods),
    D2 = tuple_to_list(Datas),
    SoulList = [],
%%     ?MSG_ERROR("SoulList is ~w", [SoulList]),
	misc_packet:pack(?MSG_ID_GOODS_SC_GOODS_EQUIP_INFO, ?MSG_FORMAT_GOODS_SC_GOODS_EQUIP_INFO, D2++[IsNew] ++ [SoulList]).

%% 2130 	移除物品 
msg_goods_sc_goods_remove(CtnType, Id, Idx) ->
    Datas = [CtnType, Id, Idx],
	misc_packet:pack(?MSG_ID_GOODS_SC_GOODS_REMOVE, ?MSG_FORMAT_GOODS_SC_GOODS_REMOVE, Datas).

%% 2190 	扩充容器返回 
msg_goods_sc_enlarge_ctn(CtnType, Usable) ->
	misc_packet:pack(?MSG_ID_GOODS_SC_ENLARGE_CTN, ?MSG_FORMAT_GOODS_SC_ENLARGE_CTN, [CtnType, Usable]).

%% 通用物品协议组数据
msg_group_goods(CtnType, UserId, PartnerId, Goods)
  when is_record(Goods, goods) ->
	 {
	  CtnType, UserId, PartnerId,
	  Goods#goods.idx,
	  Goods#goods.goods_id,
	  Goods#goods.count,
	  Goods#goods.bind,
	  Goods#goods.start_time,
	  Goods#goods.end_time,
      Goods#goods.time_temp
	 };
msg_group_goods(CtnType, UserId, PartnerId, MiniGoods)
  when is_record(MiniGoods, mini_goods) ->
	 {
	  CtnType, UserId, PartnerId,
	  MiniGoods#mini_goods.idx,
	  MiniGoods#mini_goods.goods_id,
	  MiniGoods#mini_goods.count,
	  MiniGoods#mini_goods.bind,
	  MiniGoods#mini_goods.start_time,
	  MiniGoods#mini_goods.end_time,
      MiniGoods#mini_goods.time_temp
	 }.
%% 通用物品装备协议组
msg_group_goods_equip(CtnType, UserId, PartnerId, Goods)
  when is_record(Goods, goods) ->
	Exts		= Goods#goods.exts,
    {AttrList2, SoulLvList2, StrengthLv2} = 
    	case Goods#goods.sub_type of
    		?CONST_GOODS_EQUIP_HORSE ->
    			AttrList 	= horse_mod:get_ride_list(Exts#g_equip.ride_list),
              
%%     			List2 		= horse_api:get_attr_list(UserId,Goods#goods.color,Goods#goods.lv),
%%     			AttrList 	= List2 ++ List1,
    			SoulLvList	= [],
				StrengthLv  = horse_api:get_horse_lv(UserId),
                {AttrList, SoulLvList, StrengthLv};
    		X when ?CONST_GOODS_EQUIP_FUSION =:= X orelse ?CONST_GOODS_EQUIP_FUSION_WEAPON =:= X orelse ?CONST_GOODS_EQUIP_FUSION_STEP =:= X  ->
                SoulList    = [],
    			SoulLvList	= furnace_mod:trans_soul_id_value(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, SoulList),
    			AttrList 	= [],
				StrengthLv  = Exts#g_equip.fusion_lv,
                {AttrList, SoulLvList, StrengthLv};
    		_ -> 
    			AttrList    = [],
				StrengthLv	= Exts#g_equip.strength_lv,
                {AttrList, [], StrengthLv}
    	end,
    SoulList1 = furnace_soul_api:get_hole_list(Goods),
	{
	 CtnType, UserId, PartnerId,
	 Goods#goods.idx,
	 Goods#goods.goods_id,
	 Goods#goods.count,
	 Goods#goods.bind,
	 Goods#goods.start_time,
	 Goods#goods.end_time,
     Goods#goods.time_temp,
	 StrengthLv2,
	 Exts#g_equip.exp,
	 Exts#g_equip.skill_id,
	 AttrList2,
	 [],
	 SoulLvList2,
     SoulList1
	};
%% 通用物品装备协议组
msg_group_goods_equip(CtnType, UserId, PartnerId, MiniGoods)
  when is_record(MiniGoods, mini_goods) ->
	Exts		= MiniGoods#mini_goods.exts,
    Goods       = mini_to_goods(MiniGoods),
    {AttrList2, SoulLvList2, StrengthLv2} = 
    	case Goods#goods.sub_type of
    		?CONST_GOODS_EQUIP_HORSE ->
    			AttrList 	= horse_mod:get_ride_list(Exts#g_equip.ride_list),
              
%%     			List2 		= horse_api:get_attr_list(UserId,Goods#goods.color,Goods#goods.lv),
%%     			AttrList 	= List2 ++ List1,
    			SoulLvList	= [],
				StrengthLv  = horse_api:get_horse_lv(UserId),
                {AttrList, SoulLvList, StrengthLv};
    		X when ?CONST_GOODS_EQUIP_FUSION =:= X orelse ?CONST_GOODS_EQUIP_FUSION_WEAPON =:= X orelse ?CONST_GOODS_EQUIP_FUSION_STEP =:= X  ->
                SoulList    = [],
    			SoulLvList	= furnace_mod:trans_soul_id_value(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, SoulList),
    			AttrList 	= [],
				StrengthLv  = Exts#g_equip.fusion_lv,
                {AttrList, SoulLvList, StrengthLv};
    		_ -> 
    			AttrList    = [],
				StrengthLv	= Exts#g_equip.strength_lv,
                {AttrList, [], StrengthLv}
    	end,
    SoulList1 = furnace_soul_api:get_hole_list(Goods),
	{
	 CtnType, UserId, PartnerId,
	 Goods#goods.idx,
	 Goods#goods.goods_id,
	 Goods#goods.count,
	 Goods#goods.bind,
	 Goods#goods.start_time,
	 Goods#goods.end_time,
     Goods#goods.time_temp,
	 StrengthLv2,
	 Exts#g_equip.exp,
	 Exts#g_equip.skill_id,
	 AttrList2,
	 [],
	 SoulLvList2,
     SoulList1
	}.

%% 通用物品神兵协议组
msg_group_goods_weapon(CtnType, UserId, PartnerId, Goods)
  when is_record(Goods, goods) ->
	Exts		= Goods#goods.exts,
	AttrList	= Exts#g_weapon.attr_list,
	{
	 CtnType, UserId, PartnerId,
	 Goods#goods.idx,
	 Goods#goods.goods_id,
	 Goods#goods.count,
	 Goods#goods.bind,
	 Goods#goods.start_time,
	 Goods#goods.end_time,
     Goods#goods.time_temp,
	 0,
	 0,
	 0,
	 AttrList,
	 [],
	 [],
	 []
	};
msg_group_goods_weapon(CtnType, UserId, PartnerId, MiniGoods)
  when is_record(MiniGoods, mini_goods) ->
	Exts		= MiniGoods#mini_goods.exts,
	AttrList	= Exts#g_weapon.attr_list,
	{
	 CtnType, UserId, PartnerId,
	 MiniGoods#mini_goods.idx,
	 MiniGoods#mini_goods.goods_id,
	 MiniGoods#mini_goods.count,
	 MiniGoods#mini_goods.bind,
	 MiniGoods#mini_goods.start_time,
	 MiniGoods#mini_goods.end_time,
     MiniGoods#mini_goods.time_temp,
	 0,
	 0,
	 0,
	 AttrList,
	 [],
	 [],
	 []
	}.

get_attr_list(Attr) when is_record(Attr,attr) ->
	AttrSecond = Attr#attr.attr_second, 
	List	= [
				{?CONST_PLAYER_ATTR_HP_MAX, 	  	AttrSecond#attr_second.hp_max},
				{?CONST_PLAYER_ATTR_SPEED, 		    AttrSecond#attr_second.speed},
				{?CONST_PLAYER_ATTR_FORCE_ATTACK,  	AttrSecond#attr_second.force_attack},
				{?CONST_PLAYER_ATTR_MAGIC_ATTACK, 	AttrSecond#attr_second.magic_attack},
				{?CONST_PLAYER_ATTR_FORCE_DEF,    	AttrSecond#attr_second.force_def},
				{?CONST_PLAYER_ATTR_MAGIC_DEF,     	AttrSecond#attr_second.magic_def}
	 			],
	[ {AttrType,AttrValue} || {AttrType,AttrValue} <- List,AttrValue > 0];

get_attr_list(_Attr) ->
	[].
	
%% 测试 
%% {ok, NewContainer, Packet} | {?error, ErrorCode}
add_goods_gm(Player, GoodsId, Count) ->
	UserId	  = Player#player.user_id,
	GoodsList = goods_api:make(GoodsId, ?CONST_GOODS_BIND, Count),
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_PLAYER_GM, 1, 1, 0, 0, 1, 1, []) of
		{?ok, Player2, _, Packet} ->
			{?ok, Player2};
		{?error, _ErrorCode} ->
			{?error, Player}
	end.

%% 打开远程容器
%%[CtnType,NpcId]
msg_sc_open_remote(CtnType,NpcId) ->
    misc_packet:pack(?MSG_ID_GOODS_SC_OPEN_REMOTE, ?MSG_FORMAT_GOODS_SC_OPEN_REMOTE, [CtnType,NpcId]).

%% 静态数据处理
zip_goods(Goods = #goods{}) ->
    zip_goods(goods_to_mini(Goods));
zip_goods(MiniGoods = #mini_goods{goods_id = GoodsId, exts = Exts}) when is_record(Exts, g_equip) ->
    case data_goods:get_goods(GoodsId) of
        #goods{sub_type = SubType} when (SubType =:= ?CONST_GOODS_EQUIP_FUSION
          orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_WEAPON
          orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_STEP) ->
            ExtsTuple  = zip_g_fasion(Exts),
            {MiniGoods#mini_goods.goods_id, ExtsTuple, MiniGoods#mini_goods.idx, MiniGoods#mini_goods.count,
             0,     MiniGoods#mini_goods.start_time,     MiniGoods#mini_goods.end_time,
             MiniGoods#mini_goods.time_temp, MiniGoods#mini_goods.bind};
        #goods{} ->
            ExtsTuple  = zip_g_equip(Exts),
            {MiniGoods#mini_goods.goods_id, ExtsTuple, MiniGoods#mini_goods.idx, MiniGoods#mini_goods.count,
             0,     MiniGoods#mini_goods.start_time,     MiniGoods#mini_goods.end_time,
             MiniGoods#mini_goods.time_temp, MiniGoods#mini_goods.bind}
    end;
zip_goods(MiniGoods = #mini_goods{exts = Exts}) when is_record(Exts, g_weapon) -> %% 神兵
    ExtsTuple  = zip_g_weapon(Exts),
    {MiniGoods#mini_goods.goods_id, ExtsTuple, MiniGoods#mini_goods.idx, MiniGoods#mini_goods.count,
     0,     MiniGoods#mini_goods.start_time,     MiniGoods#mini_goods.end_time,
     MiniGoods#mini_goods.time_temp, MiniGoods#mini_goods.bind};
zip_goods(MiniGoods) when is_record(MiniGoods, mini_goods) ->
    ExtsTuple  = ?null,
    {MiniGoods#mini_goods.goods_id, ExtsTuple, MiniGoods#mini_goods.idx, MiniGoods#mini_goods.count,
     0,     MiniGoods#mini_goods.start_time, MiniGoods#mini_goods.end_time,
     MiniGoods#mini_goods.time_temp, MiniGoods#mini_goods.bind};
zip_goods(?null) -> ?null.
    
%% zip_g_equip(#g_equip{strength_lv = StrengthLv, exp = Exp, skill_id = SkillId, attr_practise = AttrPractise, 
%%                      attr_soul   = AttrSoul,   temp_attr_practise = TempAttrPractise,
%%                      temp_attr_soul = TempAttrSoul}) ->
%%     {StrengthLv, Exp,              SkillId,     AttrPractise, 
%%      AttrSoul,   TempAttrPractise, TempAttrSoul};
zip_g_equip(#g_equip{strength_lv = StrengthLv, exp = Exp, skill_id = SkillId, 
                      soul_list  = SoulList,ride_list = RideList}) ->
    {StrengthLv, Exp, SkillId, SoulList,RideList}; 
zip_g_equip(?null) -> ?null.


%% 神兵压缩
zip_g_weapon(#g_weapon{attr_list = AttrList}) ->
    AttrList; 
zip_g_weapon(?null) -> ?null.

zip_g_fasion(#g_equip{exp = Exp, skill_id = SkillId, 
                      soul_list  = SoulList,ride_list = RideList, fusion_lv = FusionLv}) ->
    {FusionLv, Exp, SkillId, SoulList,RideList}; 
zip_g_fasion(?null) -> ?null.

unzip_goods({GoodsId, ExtsTuple, GoodsIdx, GoodsCount, _GoodsFlag,
			 GoodsStartTime, GoodsEndTime, GoodsTimeTemp, GoodsBind}) ->
	case goods_api:goods(GoodsId) of
		RecGoods when is_record(RecGoods, goods) ->
			Exts 	= unzip_goods_ext(RecGoods#goods.type, RecGoods#goods.sub_type, ExtsTuple, RecGoods#goods.exts),
			RecGoods2 = RecGoods#goods{exts = Exts, idx = GoodsIdx, count = GoodsCount, start_time = GoodsStartTime,
						               end_time = GoodsEndTime, time_temp = GoodsTimeTemp, bind = GoodsBind},
            goods_to_mini(RecGoods2);
		_ -> ?null
	end.

unzip_goods_ext(?CONST_GOODS_TYPE_EQUIP, SubType, {FusionLv, Exp, SkillId, SoulList,RideList}, RecGoodsExts) 
  when (SubType =:= ?CONST_GOODS_EQUIP_FUSION
  orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_WEAPON
  orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_STEP) ->
    RecGoodsExts#g_equip{exp = Exp, skill_id = SkillId,
                         soul_list = SoulList,ride_list = RideList, fusion_lv = FusionLv};
unzip_goods_ext(?CONST_GOODS_TYPE_EQUIP, _, {StrengthLv, Exp, SkillId, SoulList,RideList}, RecGoodsExts) ->
    RecGoodsExts#g_equip{strength_lv = StrengthLv, exp = Exp, skill_id = SkillId,
                         soul_list = SoulList,ride_list = RideList};
unzip_goods_ext(?CONST_GOODS_TYPE_WEAPON, _, AttrList, RecGoodsExts) ->
    RecGoodsExts#g_weapon{attr_list = AttrList};
unzip_goods_ext(_Type, _, _ExtsTuple, RecGoodsExts) ->
    RecGoodsExts.

x(X) ->
    P = player_api:get_user_info_by_id(X),
    ?MSG_SYS("~p", [P#player.bag]).
    
    