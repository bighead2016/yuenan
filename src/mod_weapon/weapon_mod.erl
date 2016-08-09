%% Author: Administrator
%% Created: 2013-8-13
%% Description: TODO: Add description to weapon_mod
-module(weapon_mod).
%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
%% -include("../../include/const.item.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl"). 
%%
%% Exported Functions
%%
-export([weapon_quench/5,
		 make_weapon_chips/1,
		 weapon_on/3,
		 weapon_off/3,
		 attr_refresh/5,
		 chess_info/1,
		 buy_dice/3,
		 dice/2,
		 control_dice/4,
		 reward_first_pos/1,
		 clear_chess_cd/1,
		 buy_put_times/1
		 ]).

%% -compile(export_all).
%%
%% API Functions
%%
%% 神兵淬火
weapon_quench(#player{user_id = UserId} = Player, CtnType, Pro, Index, Type) ->
	try
		{?ok, WeaponInfo} 		= get_weapon(Player, CtnType, Pro, Index),				%% 神兵信息
		Exts 					= WeaponInfo#goods.exts,
		?ok						= check_refresh_attr(Exts#g_weapon.attr_list, [{Type}]),
		{?ok, AttrList, QuenchGoods}= get_quench_attr_list(WeaponInfo, Type),	
		{?ok, CostCash}			= check_condition(Player, QuenchGoods),
		{?ok, Player2, Packet}	= do_consume(Player, QuenchGoods, CostCash),
		Exts2 					= Exts#g_weapon{attr_list = AttrList},  
		WeaponInfo2 			= WeaponInfo#goods{exts = Exts2},
		{?ok, Player3, Packet2}	= replace(Player2, CtnType, Pro, Index, WeaponInfo2),	%% 更新新的神兵
		Player4 				= player_attr_api:refresh_attr_weapon(Player3),			%% 更新属性
		TipPacket				= message_api:msg_notice(?TIP_WEAPON_QUENCH_SUCCESS),
		misc_packet:send(UserId, <<Packet/binary, Packet2/binary, TipPacket/binary>>),
		{?ok, Player4}
	catch
		throw:{?error, ErrorCode} ->
			TipPacket2 = message_api:msg_notice(?TIP_WEAPON_QUENCH_FAIL),
			misc_packet:send(UserId, TipPacket2),
			{?error, ErrorCode};
		ErrType:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p~n ", [ErrType, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_WEAPON_QUENCH_FAIL}
	end.

%% 淬火操作
%% 随机一个跟原来所有属性都不同的属性，规则跟生产神兵碎片一样
get_quench_attr_list(WeaponInfo, Type) ->
	RideList 		= (WeaponInfo#goods.exts)#g_weapon.attr_list, 
	Color	 		= WeaponInfo#goods.color, 
	Lv				= WeaponInfo#goods.lv,
	Pro				= WeaponInfo#goods.pro,
	Index			= WeaponInfo#goods.sub_type,
	{?ok, ColorNum, Lower, Upper, QuenchGoods} = get_quench_data(Color,Lv),
	AttrList		= data_weapon:get_weapon_attr({Pro, Index}),
	{?ok, _RideList2, AttrList2} = get_quench_attr_list2(AttrList, RideList, Type, []),
	AttrList3		= make_weapon_attr(AttrList2, Lv, ColorNum, Lower, Upper),
	[NewTuple|_]	= AttrList3,
	AttrList4		= lists:keyreplace(Type, 1, RideList, NewTuple),
	{?ok, AttrList4, QuenchGoods}.

%% 去掉要淬火的属性，随机一个新的属性
get_quench_attr_list2(AttrList, RideList, Type, []) ->
	F = fun({AttrType, _}, Acc) -> lists:keydelete(AttrType, 1, Acc) end,
	AttrList2 = lists:foldl(F, AttrList, RideList),
	AttrList3 = misc_random:random_list_norepeat(AttrList2, 1),	%% 属性组随机属性
	RideList2 = lists:keydelete(Type, 1, RideList),
	{?ok, RideList2, AttrList3}.

%% 获取淬火配置数据
get_quench_data(Color, Lv) ->
	case data_weapon:get_weapon({Color,Lv}) of
		?null -> %% 无对应品质、等级的神兵
			throw({?error, ?TIP_WEAPON_GOODS});
		#rec_weapon{color_num = ColorNum, attr_lower = Lower, attr_upper = Upper, quench_goods = QuenchGoods} ->
			{?ok, ColorNum, Lower, Upper, QuenchGoods} 
	end.

%% 检查淬火条件是否满足
check_condition(Player, GoodsList) ->
	case check_quench_goods(Player, GoodsList) of
		?ok ->
			{?ok, ?CONST_SYS_FALSE};
		{?error, _} ->%% 淬火石不足则检查元宝是否足够
			case player_money_api:check_money(Player#player.user_id, ?CONST_SYS_CASH, ?CONST_WEAPON_REBUILD_COST) of
				{?ok, _Money, ?true} ->
					{?ok, ?CONST_WEAPON_REBUILD_COST};
				{?ok, _Money, ?false} ->
					throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH});
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end
	end.

%% 检查淬火扣除道具是否足够(淬火石)
check_quench_goods(_Player, []) -> ?ok;
check_quench_goods(#player{bag = Bag} = Player, [{GoodsId, Num}|GoodsInfo]) ->
	case ctn_bag2_api:get_goods_count(Bag, GoodsId) >= Num of
		?true ->
			check_quench_goods(Player, GoodsInfo);
		?false ->
			{?error, ?TIP_WEAPON_QUENCH_GOODS_NOT_ENOUGH}
	end.

%% 淬火消耗
do_consume(Player, QuenchGoods, ?CONST_SYS_FALSE) ->
	get_quench_goods(Player, QuenchGoods, <<>>);
do_consume(Player, _QuenchGoods, _CostCash) ->
	case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, ?CONST_WEAPON_REBUILD_COST, ?CONST_COST_WEAPON_QUENCH) of
		?ok ->
			{?ok, Player, <<>>};
		{?error, ErrorCode} ->
			?MSG_ERROR("weapon quench error:~p", [ErrorCode]),
			throw({?error, ErrorCode})
	end.

%% 扣除淬火石
get_quench_goods(Player, [], Packet) -> {?ok, Player, Packet};
get_quench_goods(#player{user_id = UserId, bag = Bag} = Player, [{GoodsId, Num}|GoodsInfo], OldPacket) ->
	case ctn_bag2_api:get_by_id(UserId, Bag, GoodsId, Num) of
		{?ok, Bag2, _GoodsList, Packet} ->
			admin_log_api:log_goods(UserId, 0, ?CONST_COST_WEAPON_QUENCH, GoodsId, Num, misc:seconds()),
			get_quench_goods(Player#player{bag = Bag2}, GoodsInfo, <<OldPacket/binary, Packet/binary>>);
		{?error, ErrorCode} ->
			throw({?error, ErrorCode})
	end.

%% 生成神兵碎片
%% weapon_api:make_weapon_chips(Goods).
%% arg : Goods
%% return : Goods | {?error, ErrorCode}
make_weapon_chips(Goods = #goods{pro = Pro, sub_type = SubType, color = Color, lv = Lv, exts = Exts}) ->
	case data_weapon:get_weapon({Color,Lv}) of
		?null -> %% 无对应碎片
			{?error, ?TIP_GOODS_NOT_EXIST};
		#rec_weapon{count = Count,  color_num = ColorNum,attr_lower = Lower, attr_upper = Upper} ->
			AttrList		= data_weapon:get_weapon_attr({Pro, SubType}),
%% 			[{_, _, AttrList}]	= misc_random:random_list_norepeat(OddList, 1),			%% 随机获取属性组
			AttrList2		= misc_random:random_list_norepeat(AttrList, Count),	%% 属性组随机属性
			AttrList3		= make_weapon_attr(AttrList2,Lv,ColorNum,Lower,Upper),
			Exts2 			= Exts#g_weapon{attr_list = AttrList3}, 
			Goods#goods{exts = Exts2}
	end.

%% 取得随机数
get_random_value(Lower,Upper) ->
	misc_random:random(Lower,Upper)/?CONST_SYS_NUMBER_TEN_THOUSAND.

%% 生成属性
make_weapon_attr(AttrList,Lv,ColorRate,Lower,Upper) ->
	make_weapon_attr(AttrList,Lv,ColorRate,Lower,Upper,[]).

make_weapon_attr([],_Lv,_ColorRate,_Lower,_Upper,Result) ->
	Result;
make_weapon_attr([{AttrType,AttrValue}|AttrList],Lv,ColorRate,Lower,Upper,Result) ->
	RandomNum	= get_random_value(Lower,Upper),
	AttrValue2 	= misc:ceil(AttrValue * Lv * ColorRate/?CONST_SYS_NUMBER_TEN_THOUSAND * RandomNum),
	Result2		= [{AttrType,AttrValue2}|Result],
	make_weapon_attr(AttrList,Lv,ColorRate,Lower,Upper,Result2).

%% 装备神兵
weapon_on(Player, Pro, Idx) ->
	Weapon	= Player#player.weapon,
	case lists:keyfind(Pro, 1, Weapon#weapon_data.data) of
		{Pro, CtnWeapon} ->
			weapon_on2(Player, Pro, CtnWeapon, Idx);
		?false ->
			Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.
weapon_on2(Player = #player{net_pid = NetPid, info = Info}, Key, CtnWeapon, Idx) ->
	UserLv  = Info#info.lv,
	UserSex = Info#info.sex,
	case ctn_bag2_api:read(Player#player.bag, Idx) of
		{?ok, ?null} ->% 装备不存在
			Packet  =   message_api:msg_notice(?TIP_GOODS_EQUIP_NOT_EXIST),
            misc_packet:send(Player#player.user_id, Packet),
            {?error, ?TIP_GOODS_EQUIP_NOT_EXIST};
		{?ok, _Goods = #goods{sex = WeaponSex, lv = WeaponLv, sub_type = SubType}} ->
			try
				?ok   = check_weapon_lv(UserLv, WeaponLv),
				?ok   = check_weapon_sex(UserSex, WeaponSex),
				weapon_on(Player, Key, CtnWeapon, SubType, Idx)
			catch
				throw:{?error, ErrorCode} ->
					PacketError = message_api:msg_notice(ErrorCode),
					misc_packet:send(NetPid, PacketError),
    				{?error, ErrorCode};
				_:_ ->
					{?error, ?TIP_COMMON_BAD_ARG}
			end
	end.

check_weapon_lv(UserLv, WeaponLv) ->
	if UserLv < WeaponLv ->
		   throw({?error, ?TIP_GOODS_LV_NOT_USE});
	   ?true ->
		   ?ok
	end.

%% 检查装备(时装)性别限制
check_weapon_sex(_UserSex, 0) -> ?ok;
check_weapon_sex(Sex, Sex) -> ?ok;
check_weapon_sex(_UserSex, _WeaponSex) -> ?error.

weapon_on(Player, Key, CtnWeapon, WeaponIdx, Idx) ->
	UserId 			= Player#player.user_id,
	{?ok, Bag, ChangeListFrom, RemoveListFrom, CtnWeapon2, ChangeListTo, RemoveListTo} =
		ctn_mod:outer_exchange(Player#player.bag, Idx, CtnWeapon, WeaponIdx),
	[GoodsTo]		= ChangeListTo,
	ChangeListTo2	= [GoodsTo#mini_goods{bind = ?CONST_GOODS_BIND}],
	BinChangeFrom	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, UserId, ChangeListFrom, ?CONST_SYS_FALSE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, UserId, RemoveListFrom),
	BinChangeTo		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_WEAPON, UserId, UserId, ChangeListTo2, ?CONST_SYS_FALSE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_WEAPON, UserId, RemoveListTo),
	Packet			= <<BinChangeFrom/binary, BinRemoveFrom/binary, BinChangeTo/binary, BinRemoveTo/binary>>,
	misc_packet:send(Player#player.user_id, Packet),
	CtnWeapon3 		= bind_weapon(CtnWeapon2, WeaponIdx),
	Weapon			= Player#player.weapon,
	WeaponList		= lists:keyreplace(Key, 1, Weapon#weapon_data.data, {Key, CtnWeapon3}),
	NewWeapon		= Weapon#weapon_data{data = WeaponList},
    Player2	        = Player#player{bag = Bag, weapon = NewWeapon},
    Player3			= player_attr_api:refresh_attr_weapon(Player2),
	schedule_power_api:do_update_weapon(Player3),
	{?ok, Player3}.

bind_weapon(CtnWeapon, Index) ->
	GoodsTuple = CtnWeapon#ctn.goods,
	case element(Index, GoodsTuple) of
		?null ->
			CtnWeapon;
		Goods ->
			NewGoods = Goods#mini_goods{bind = ?CONST_GOODS_BIND},
			GoodsTuple2 = setelement(Index, GoodsTuple, NewGoods),
			CtnWeapon#ctn{goods = GoodsTuple2}
	end.

%% 卸下神兵
weapon_off(Player, Pro, WeaponIdx) ->
	Weapon				= Player#player.weapon,
	Key = Pro,
	{Key, CtnWeapon}	= lists:keyfind(Key, 1, Weapon#weapon_data.data),
	case ctn_bag2_api:read(CtnWeapon, WeaponIdx) of
		{?ok, ?null} ->% 装备不存在
            Packet  =   message_api:msg_notice(?TIP_GOODS_EQUIP_NOT_EXIST),
            misc_packet:send(Player#player.user_id, Packet),
			{?error, ?TIP_GOODS_EQUIP_NOT_EXIST};
		{?ok, _Goods} ->
			case ctn_mod:empty_search(Player#player.bag) of
				{?ok, ?null} -> 
                    Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                    misc_packet:send(Player#player.user_id, Packet),
                    {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
				{?ok, Idx} ->
					weapon_off(Player, Key, CtnWeapon, WeaponIdx, Idx)
			end
	end.
	
weapon_off(Player, Key, CtnWeapon, WeaponIdx, Idx) ->
	UserId 			= Player#player.user_id,
	Weapon			= Player#player.weapon,
	{?ok, CtnWeapon2, ChangeListFrom, RemoveListFrom, Bag, ChangeListTo, RemoveListTo} =
		ctn_mod:outer_exchange(CtnWeapon, WeaponIdx, Player#player.bag, Idx),
	BinChangeFrom	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_WEAPON, UserId, UserId, ChangeListFrom, ?CONST_SYS_FALSE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_WEAPON, Key, RemoveListFrom),
	BinChangeTo		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, UserId, ChangeListTo, ?CONST_SYS_TRUE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, Key, RemoveListTo),
	Packet			= <<BinChangeFrom/binary, BinRemoveFrom/binary, BinChangeTo/binary, BinRemoveTo/binary>>,
	misc_packet:send(Player#player.user_id, Packet),
	WeaponList		= lists:keyreplace(Key, 1, Weapon#weapon_data.data, {Key, CtnWeapon2}),
	NewWeapon		= Weapon#weapon_data{data = WeaponList},
	Player2       	= Player#player{bag = Bag, weapon = NewWeapon},
    Player3		= player_attr_api:refresh_attr_weapon(Player2),
	schedule_power_api:do_update_weapon(Player3),
	{?ok, Player3}.

%% 神兵洗炼
attr_refresh(_Player, _CtnType, _Pro, _Index, []) ->
	{?error,?TIP_WEAPON_REFRESH_ERROR};
attr_refresh(Player, CtnType, Pro, Index, List) ->
	try
		UserId					= Player#player.user_id,
		{?ok, WeaponInfo} 		= get_weapon(Player, CtnType, Pro, Index),		%% 神兵信息
		Exts 					= WeaponInfo#goods.exts,
		?ok						= check_refresh_attr(Exts#g_weapon.attr_list, List),
		{?ok,AttrList,Cash,Gold,Count}= get_refresh_attr_list(WeaponInfo,  List),	
		Exts2 					= Exts#g_weapon{attr_list = AttrList},  
		WeaponInfo2 			= WeaponInfo#goods{exts = Exts2},
%% 		{?ok, Player2}			= check_refresh_free_times(Player, Cash, Gold, Count),
		?ok						= check_refresh_money(UserId, Cash, Gold, Count),
		{?ok, Player3, Packet}	= replace(Player,CtnType, Pro, Index, WeaponInfo2), %% 更新新的神兵
		Player4 				= player_attr_api:refresh_attr_weapon(Player3), %%　更新属性
		schedule_power_api:do_update_weapon(Player4),
%% 		NewRefreshTimes			= (Player4#player.weapon)#weapon_data.refresh_times,
%% 		PacketRefresh			= weapon_api:msg_free_refresh_times(NewRefreshTimes),
		misc_packet:send(UserId, Packet),
		{?ok,Player4}
	catch
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_WEAPON_REFRESH_ERROR}
	end.	

%% 获取神兵数据
%% weapon_mod:get_weapon(Player, Index).
%% arg : Player, Index
%% return : Goods	
get_weapon(Player, CtnType, Pro, Index) ->
	case get_weapon_info(Player, CtnType, Pro, Index) of
		?null ->
			throw({?error, ?TIP_WEAPON_GOODS});
		{?ok, WeaponInfo} ->
			?ok	= check_is_weapon(WeaponInfo),
			{?ok, WeaponInfo}
	end.

get_weapon_info(#player{bag = Bag, weapon = Weapon}, CtnType, Pro, Index) ->
	case CtnType of
		?CONST_GOODS_CTN_BAG -> %% 背包
			ctn_bag2_api:read(Bag, Index);
		?CONST_GOODS_CTN_WEAPON -> %% 角色装备
			case lists:keyfind(Pro, 1, Weapon#weapon_data.data) of
				?false -> ?null;
				{_, Container} ->
					ctn_bag2_api:read(Container, Index)
			end;
		_ ->
			?null
	end.

%% 是否为神兵
check_is_weapon(#goods{type = Type}) 
  when Type =:= ?CONST_GOODS_TYPE_WEAPON  ->
	?ok;
check_is_weapon(_) ->
	throw({?error, ?TIP_WEAPON_GOODS}).

check_refresh_attr(_AttrList,[]) ->
	?ok;
check_refresh_attr(AttrList,[{AttrType}|L]) ->
	case lists:keyfind(AttrType, 1, AttrList) of
		?false ->
			throw({?error,?TIP_WEAPON_REFRESH_ERROR});
		{_,0} ->
			throw({?error,?TIP_WEAPON_REFRESH_ZERO});
		_ -> 
			check_refresh_attr(AttrList,L)
	end.

get_refresh_attr_list(WeaponInfo, List) ->
	RideList 		= (WeaponInfo#goods.exts)#g_weapon.attr_list, 
	Color	 		= WeaponInfo#goods.color, 
	Lv				= WeaponInfo#goods.lv,
	Pro				= WeaponInfo#goods.pro,
	Index			= WeaponInfo#goods.sub_type,
	{?ok,ColorNum,Lower,_Upper,Cash,Gold} = get_refresh_data(Color,Lv),
	AttrList			= data_weapon:get_weapon_attr({Pro, Index}),
%% 	[{_, _, AttrList}]	= misc_random:random_list_norepeat(OddList, 1),			%% 随机获取属性组								  
	{?ok,RideList2,AttrList2} = get_refresh_attr_list2(AttrList,RideList,List,[]),
	AttrList3		= make_weapon_attr(AttrList2, Lv, ColorNum, Lower, ?CONST_SYS_NUMBER_TEN_THOUSAND), %% 洗练上限随机数是1
	AttrList4		= AttrList3 ++ RideList2,
	Count			= length(RideList) - length(AttrList3),
	Count2			= misc:uint(Count + 1),
	{?ok,AttrList4,Cash,Gold,Count2}.

get_refresh_attr_list2(_,RideList,[],List) ->
	{?ok,RideList,List};
get_refresh_attr_list2(AttrList,RideList,[{Type}|L],List) ->
	case lists:keytake(Type, 1, AttrList) of
		?false ->
			get_refresh_attr_list2(AttrList,RideList,L,List);
		{value, Tuple, _TupleList2} ->
			RideList2 = lists:keydelete(Type, 1, RideList),
			get_refresh_attr_list2(AttrList,RideList2,L,[Tuple|List]) 
	end.

get_refresh_data(Color,Lv) ->
	case data_weapon:get_weapon({Color,Lv}) of
		?null -> %% 无对应品质、等级的神兵
			throw({?error,?TIP_WEAPON_GOODS});
		#rec_weapon{color_num = ColorNum, attr_lower = Lower, attr_upper = Upper, refresh_cash = Cash, refresh_gold = Gold} ->
			{?ok, ColorNum, Lower, Upper, Cash, Gold} 
	end.

%% 替换神兵
%% weapon_mod:replace(Player, CtnType, Pro, Index, Goods).
%% arg : Player, CtnType, Pro, Index, Goods
%% return : Player | {?error, ErrorCode}
replace(Player = #player{user_id = UserId,bag = Container},?CONST_GOODS_CTN_BAG, _Pro, Index, Goods) ->
	case ctn_bag2_api:replace(UserId, Container, Index, Goods) of
		{?error, ErrorCode}	->
			throw({?error, ErrorCode});
		{?ok, NewContainer, Packet} ->
			Player2 = Player#player{bag = NewContainer},
			{?ok, Player2, Packet}
	end;
replace(Player = #player{user_id = UserId, weapon = Weapon},CtnType, Pro, Index, Goods) 
  when CtnType =:= ?CONST_GOODS_CTN_WEAPON ->
	Key = Pro,
	WeaponData	= Weapon#weapon_data.data,
	case lists:keytake(Key, 1, WeaponData) of
		?false ->
			throw({?error, ?TIP_WEAPON_GOODS});
		{value, {_,Container}, WeaponData2} ->
 			case ctn_equip_api:replace(UserId, 0, CtnType, Container, Index, Goods) of	
				{?error, ErrorCode}	->
					throw({?error, ErrorCode});
				{?ok, NewContainer, Packet} ->
					NewWeaponData = [{Key, NewContainer}|WeaponData2],
					NewWeapon	  = Weapon#weapon_data{data = NewWeaponData},
					Player2   = Player#player{weapon = NewWeapon},
					{?ok, Player2, Packet}
			end
	end;	
replace(_, _, _, _, _) ->
	throw({?error, ?TIP_WEAPON_GOODS}).

%% 检查免费洗练次数
%% check_refresh_free_times(Player, Cash, Gold, Count) ->
%% 	UserId			= Player#player.user_id,
%% 	Weapon			= Player#player.weapon,
%% 	FreeTimes		= Weapon#weapon_data.refresh_times,
%% 	case FreeTimes	> 0 of
%% 		?true ->
%% 			NewWeapon		= Weapon#weapon_data{refresh_times = FreeTimes - 1},
%% 			NewPlayer		= Player#player{weapon = NewWeapon},
%% 			{?ok, NewPlayer};
%% 		?false ->
%% 			?ok = check_refresh_money(UserId, Cash, Gold, Count),
%% 			{?ok, Player}
%% 	end.

check_refresh_money(UserId, Cash, Gold, Count) ->
	?ok				= check_refresh_money2(UserId, ?CONST_SYS_BCASH_FIRST, Cash * Count),
	?ok				= check_refresh_money2(UserId, ?CONST_SYS_GOLD_BIND, Gold * Count),
	?ok				= check_minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cash * Count, ?CONST_COST_WEAPON_REFRESH), 
	?ok				= check_minus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold * Count, ?CONST_COST_WEAPON_REFRESH),
	?ok.

check_refresh_money2(UserId,?CONST_SYS_BCASH_FIRST,Cost) ->
	case player_money_api:check_money(UserId, ?CONST_SYS_BCASH_FIRST, Cost) of
		{?ok,_,?true} -> ?ok;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		_ -> 
			throw({?error,?TIP_COMMON_CASH_NOT_ENOUGH})
	end;
check_refresh_money2(UserId,?CONST_SYS_GOLD_BIND,Cost) ->
	case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, Cost) of
		{?ok,_,?true} -> ?ok;
		{?error,ErrorCode} ->
			throw({?error,ErrorCode});
		_ -> 
			throw({?error,?TIP_COMMON_GOLD_NOT_ENOUGH})
	end.	

%% 检查金币
check_minus_money(UserId, CostType, Cost, Point) ->
	case player_money_api:minus_money(UserId,CostType, Cost, Point) of
		?ok -> ?ok;
		{?error, _ErrorCode} ->
			throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH})
	end.

%%%================================== 双陆玩法 =====================================%%%
%% 双陆信息
chess_info(Player) ->
	Weapon		= Player#player.weapon,
	PutTimes	= Weapon#weapon_data.put_times,
	Cd			= Weapon#weapon_data.cd,
	Pos			= Weapon#weapon_data.pos,
	BuyTimes	= Weapon#weapon_data.buy_times,
	VipLv		= player_api:get_vip_lv(Player),
	VipTimes	= player_vip_api:get_chess_buy_dice(VipLv),
	CanBuy		= misc:uint(VipTimes - BuyTimes),
	Packet		= weapon_api:msg_chess_info(PutTimes, Cd, Pos, CanBuy),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player}.

%% 购买骰子
buy_dice(Player, Type, Num) ->
	try
		UserId		= Player#player.user_id,
		RecChessGoods = data_weapon:get_weapon_chess_goods(Type),
		Cost		= RecChessGoods#rec_chess_goods.gold,
		GoodsId		= RecChessGoods#rec_chess_goods.id,
		?ok			= check_money(UserId, Cost),
		{?ok, Player2, Packet} = check_bag(Player, GoodsId, 1, Num), 
		?ok = player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_WEAPON_CHESS_REWARD),
		TipsPacket = message_api:msg_notice(?TIP_WEAPON_SUCCESS_BUY_DICE),
		misc_packet:send(Player#player.user_id, <<Packet/binary, TipsPacket/binary>>),
		{?ok, Player2}
	catch
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.
%% 扔掷骰子
dice(Player, Type) ->
	try
		UserId		= Player#player.user_id,
		Bag			= Player#player.bag,
		?ok			= check_chess_put_times(Player),
		?ok			= check_chess_cd(Player),
		{Bag2, Num1, Num2} =
			case Type of
				1 ->
					TemNum1 = misc:rand(1, 6),
					TemNum2 = 0,
					{Bag, TemNum1, TemNum2};
				2 ->
					TempBag	= check_goods(UserId, Bag, ?CONST_WEAPON_CHESS_GOODS_DOUBLE),
					TemNum1 = misc:rand(1, 6),
					TemNum2 = misc:rand(1, 6),
					{TempBag, TemNum1, TemNum2}
			end,
		Weapon		= Player#player.weapon,
		Pos			= Weapon#weapon_data.pos,
		NewPutTimes	= Weapon#weapon_data.put_times - 1,
		NewPos		= 
			case (Pos + Num1 + Num2) =< ?CONST_WEAPON_CHESS_MAX_POS of
				?true ->
					(Pos + Num1 + Num2);
				?false ->
					(Pos + Num1 + Num2) rem ?CONST_WEAPON_CHESS_MAX_POS
			end,
		NewCd		= misc:seconds() + ?CONST_WEAPON_CHESS_CD * 60,
		NewWeapon 	= Weapon#weapon_data{pos = NewPos, cd = NewCd, put_times = NewPutTimes},
		Player2 	= Player#player{bag = Bag2, weapon = NewWeapon},
		RecChess	= data_weapon:get_weapon_chess(NewPos),
		{?ok, Player3} = reward(Player2, RecChess),
%% 		?MSG_DEBUG("msg_chess_info111111111111111111111111111111:~p",[{Type, Num1, Num2, NewPutTimes, NewCd, NewPos}]),
		NewPutTimes2 = (Player3#player.weapon)#weapon_data.put_times,
		VipLv		= player_api:get_vip_lv(Player),
		VipTimes	= player_vip_api:get_chess_buy_dice(VipLv),
		CanBuy		= misc:uint(VipTimes - (Player3#player.weapon)#weapon_data.buy_times),
		Packet1 	= weapon_api:msg_dice(Num1, Num2),
		Packet2		= weapon_api:msg_chess_info(NewPutTimes2, NewCd, NewPos, CanBuy),
		misc_packet:send(UserId, <<Packet1/binary, Packet2/binary>>),
		admin_log_api:log_chess(Player3, 0, 1, NewPutTimes),
		{?ok, Player3}
	catch
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	

%% 遥控骰子
control_dice(Player, Type, Num1, Num2) ->
	try
		UserId		= Player#player.user_id,
		Bag			= Player#player.bag,
		?ok			= check_chess_put_times(Player),
		?ok			= check_chess_cd(Player),
%% 		RecChessGoods = data_weapon:get_weapon_chess_goods(Type),
%% 		GoodId		= RecChessGoods#rec_chess_goods.id,
		Bag2 		= check_goods(UserId, Bag, ?CONST_WEAPON_CHESS_GOODS_CONTROL),
		Bag3		= 
			case Type of
				1 ->
					Bag2;
				2 ->
					check_goods(UserId, Bag2, ?CONST_WEAPON_CHESS_GOODS_DOUBLE)
			end,
		Weapon		= Player#player.weapon,
		Pos			= Weapon#weapon_data.pos,
		NewPutTimes	= Weapon#weapon_data.put_times - 1,
		NewPos		= 
			case (Pos + Num1 + Num2) =< ?CONST_WEAPON_CHESS_MAX_POS of
				?true ->
					(Pos + Num1 + Num2);
				?false ->
					(Pos + Num1 + Num2) rem ?CONST_WEAPON_CHESS_MAX_POS
			end,
		NewCd		= misc:seconds() + ?CONST_WEAPON_CHESS_CD * 60,
		NewWeapon 	= Weapon#weapon_data{pos = NewPos,  cd = NewCd, put_times = NewPutTimes},
		Player2 	= Player#player{bag = Bag3, weapon = NewWeapon},
		RecChess	= data_weapon:get_weapon_chess(NewPos),
		{?ok, Player3} = reward(Player2, RecChess),
		NewPutTimes2 = (Player3#player.weapon)#weapon_data.put_times,
		VipLv		= player_api:get_vip_lv(Player),
		VipTimes	= player_vip_api:get_chess_buy_dice(VipLv),
		CanBuy		= misc:uint(VipTimes - (Player3#player.weapon)#weapon_data.buy_times),
		Packet1 	= weapon_api:msg_dice(Num1, Num2),
		Packet2		= weapon_api:msg_chess_info(NewPutTimes2, NewCd, NewPos, CanBuy),
		misc_packet:send(UserId, <<Packet1/binary, Packet2/binary>>),
		admin_log_api:log_chess(Player3, 0, 1, NewPutTimes),
		{?ok, Player3}
	catch
		throw:{?error,ErrorCode} ->
			{?error,ErrorCode};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%% 达到位置奖励
reward(Player, RecChess)
  when is_record(Player, player) andalso is_record(RecChess, rec_chess)	->
	Lv				= (Player#player.info)#info.lv,
	GoodsDropId		= get_drop_id(RecChess#rec_chess.goods, Lv),
	WeaponDropId	= get_drop_id(RecChess#rec_chess.weapon, Lv),
	{?ok, Player2, GoodsList} = reward_goods(Player, GoodsDropId),
	{?ok, Player3, WeaponList} = reward_goods(Player2, WeaponDropId),
	Gold					   = RecChess#rec_chess.gold,
	Exp						   = RecChess#rec_chess.exp,
	Dice					   = RecChess#rec_chess.dice,
	RewardGold				   = misc:floor(Gold *(0.8 + 0.2 * Lv)),
	RewardExp				   = misc:floor(Exp *(0.4 + 0.6 * Lv)),
	?ok						   = reward_gold(Player3#player.user_id, RewardGold),
	{?ok, Player4} 			   = reward_exp(Player3, RewardExp),
	{?ok, Player5} 			   = reward_dice(Player4, Dice),
	Fun	= 
		fun(Goods) ->
				{Goods#goods.goods_id, Goods#goods.count}
		end,
	GoodsIdList 			   = lists:map(Fun, GoodsList ++ WeaponList),
	Packet					   = weapon_api:msg_chess_reward(RewardGold, RewardExp, Dice, GoodsIdList),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player5};
reward(Player, _)	->	{?ok, Player}.

reward_exp(Player, 0) -> {?ok, Player};
reward_exp(Player, Exp) -> 
	{?ok, Player2} = player_api:exp(Player, Exp),
	{?ok, Player2}.

%% 铜钱奖励
reward_gold(_UserId, 0) -> ?ok;
reward_gold(UserId, Gold) ->
	case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_WEAPON_CHESS_REWARD) of
		?ok -> 
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 物品奖励
reward_goods(Player, GoodsDrop) when is_record(Player, player) andalso is_integer(GoodsDrop)	->
	GoodsList	= goods_api:goods_drop(GoodsDrop),
	reward_goods(Player, GoodsList);
reward_goods(Player, GoodsList) when is_record(Player, player) andalso is_list(GoodsList)	->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_WEAPON_CHESS_REWARD, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _, _PacketBag} ->
			{?ok, Player2, GoodsList};
		{?error, _ErrorCode}	->
			{?ok, Player, []}
	end;
reward_goods(Player, _)	->	{?ok, Player, []}.

%% 奖励投掷次数
reward_dice(Player, 0) -> {?ok, Player};
reward_dice(Player, Dice) ->
	Weapon		= Player#player.weapon,
	PutTimes	= Weapon#weapon_data.put_times,
	NewWeapon   = Weapon#weapon_data{put_times = PutTimes + Dice},
	Player2		= Player#player{weapon = NewWeapon},
%% 	Packet		= message_api:msg_notice(?TIP_WEAPON_CHESS_GET_DICE, [{?TIP_SYS_COMM, misc:to_list(Dice)}]),
%% 	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player2}.

%% 获取奖励物品的掉落id
get_drop_id(Drop, _Lv) when is_integer(Drop) ->
	Drop;
get_drop_id([{MinLv, MaxLv, Id}|_DropList], Lv) when Lv >= MinLv andalso Lv =< MaxLv ->
	Id;
get_drop_id([_Drop|DropList], Lv) ->
	get_drop_id(DropList, Lv);
get_drop_id([], Lv) ->
	?MSG_ERROR("ERROR get drop id:~p", [Lv]).

%% 路过第一个位置奖励
reward_first_pos(Player) ->
	Gold		= ?CONST_WEAPON_CHESS_FIRST_POS_REWARD,
	case reward_gold(Player#player.user_id, Gold) of
		?ok ->
			{?ok, Player};
		{?error, ErrorCode} -> 
			{?error, ErrorCode}
	end.

%% 清除cd
clear_chess_cd(Player) ->
	Weapon			= Player#player.weapon,
	OldCd			= Weapon#weapon_data.cd,
	Now    			= misc:seconds(),
	case OldCd > Now of
		?true ->
			Cost   = misc:ceil((OldCd - Now)/60),
			case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_WEAPON_CHESS_REWARD) of
				?ok ->
					NewWeapon		= Weapon#weapon_data{cd = 0},
					NewPlayer		= Player#player{weapon = NewWeapon},
					Packet			= weapon_api:msg_chess_cd(0),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, NewPlayer};
				_Other ->
					{?ok, Player}
			end;
		?false ->
			{?ok, Player}
	end.


%% 购买投掷次数
buy_put_times(Player) ->
	UserId			= Player#player.user_id,
	Bag				= Player#player.bag,
	Weapon			= Player#player.weapon,
	PutTimes		= Weapon#weapon_data.put_times,
	Cost			= ?CONST_WEAPON_CHESS_BUY_PUTTIMES_COST,
	AddTimes		= ?CONST_WEAPON_CHESS_BUY_PUTTIMES,
	VipLv			= player_api:get_vip_lv(Player),
	VipTimes		= player_vip_api:get_chess_buy_dice(VipLv),
	BuyTimes		= Weapon#weapon_data.buy_times,
	CanBuy			= misc:uint(VipTimes - BuyTimes),
	case ctn_bag2_api:get_by_id_not_send(UserId, Bag, ?CONST_WEAPON_CHESS_GOODS_DICE_BAG, 1) of
		{?ok, Bag2, _GoodsList2, Packet} ->
			admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_WEAPON_CHESS_REWARD, ?CONST_WEAPON_CHESS_GOODS_DICE_BAG, 1, misc:seconds()),
			NewPutTimes	= PutTimes + AddTimes,
			NewCanBuy	= VipTimes - BuyTimes,
			Weapon2		= Weapon#weapon_data{put_times = NewPutTimes},
			Player2		= Player#player{weapon = Weapon2, bag = Bag2},
			Packet1		= weapon_api:msg_chess_buy_put_times(NewPutTimes, NewCanBuy),
			Packet2 		= message_api:msg_notice(?TIP_WEAPON_CHESS_GET_DICE),
			misc_packet:send(UserId, <<Packet/binary, Packet1/binary, Packet2/binary>>),
			admin_log_api:log_chess(Player2, 1, AddTimes, NewPutTimes),
			{?ok, Player2};
		_ ->
			if PutTimes > 0 -> %% 次数大于0不能购买
				   {?ok, Player};
			   CanBuy =< 0 ->
				   TipsPacket = message_api:msg_notice(?TIP_WEAPON_CHESS_BUY_TIMES_NOT_ENOUGH),
				   misc_packet:send(UserId, TipsPacket),
				   {?ok, Player};
			   ?true ->
				   case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_WEAPON_CHESS_REWARD) of
					   ?ok ->
						   NewPutTimes	= PutTimes + AddTimes,
						   NewCanBuy	= VipTimes - (BuyTimes + 1),
						   Weapon2		= Weapon#weapon_data{put_times = NewPutTimes, buy_times = BuyTimes + 1},
						   Player2		= Player#player{weapon = Weapon2},
						   Packet		= weapon_api:msg_chess_buy_put_times(NewPutTimes, NewCanBuy),
						   Packet1 		= message_api:msg_notice(?TIP_WEAPON_CHESS_GET_DICE),
						   misc_packet:send(UserId, <<Packet/binary, Packet1/binary>>),
						   admin_log_api:log_chess(Player2, 1, AddTimes, NewPutTimes),
						   {?ok, Player2};
					   _ ->
						   {?ok, Player}
				   end
			end
	end.
			
%% 检查投掷cd
check_chess_put_times(Player) ->
	Weapon			= Player#player.weapon,
	PutTimes		= Weapon#weapon_data.put_times,
	case PutTimes > 0 of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_WEAPON_CHESS_TIMES_NOT_ENONGH})
	end.

%% 检查投掷cd
check_chess_cd(Player) ->
	Weapon			= Player#player.weapon,
	Cd				= Weapon#weapon_data.cd,
	Now				= misc:seconds(),
	case Cd =< Now of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_WEAPON_CHESS_IN_CD})
	end.

%% 背包检查
check_bag(Player, GoodsId, Bind, Num) ->
    Bag = Player#player.bag,
	case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
		?false ->		
			GoodsList = goods_api:make(GoodsId, Bind, Num),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_WEAPON_CHESS_REWARD, 1, 1, 0, 0, 0, 1, []) of
				{?ok, Player2, _, Packet} ->
					{?ok, Player2, Packet};
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end;
		_ -> throw({?error, ?TIP_MALL_BAG})
	end.

%% 背包里道具够?
check_goods(UserId, Bag, GoodsId) ->
    case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, 1) of
        {?ok, Bag2, _GoodsList2, Packet} ->
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_WEAPON_CHESS_REWARD, GoodsId, 1, misc:seconds()),
            misc_packet:send(UserId, Packet),
            Bag2;
        _X ->
			Packet = message_api:msg_notice(?TIP_GOODS_THE_COUNT_NOT_ENOUGH, 
											 [{?TIP_SYS_NOT_EQUIP, misc:to_list(GoodsId)}]),
            misc_packet:send(UserId, Packet),
            throw({?error, ?TIP_GOODS_COUNT_NOT_ENOUGH})
    end.
       
%% 检查钱是否足够
check_money(UserId, Cost) ->
	case player_money_api:check_money(UserId, ?CONST_SYS_CASH, Cost) of
		{?ok, _Money, ?true} ->
			?ok;
		_ ->
			throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
	end.

	
