%%% 坐骑
-module(horse_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.data.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
-export([use_goods/3, add_achievement/2, make_horse/1, clear_cd/2, take_out/2, replace/5,
         mall_lv_up/5, get_horse/4, get_horse_info/4, refresh/5, get_ride_list/1]).


%%
%% API Functions
%%

%%---------------------------------------------------------------------------------
%% 使用小马驹道具
%% return : Player | {?error, ErrorCode}
use_goods(Player, GoodsId, GrowTime) ->
    NetPid = Player#player.net_pid,
    case player_sys_api:is_open_sys(Player, ?CONST_MODULE_HORSE) of
        ?true ->
            case horse_stable_api:insert_pony(Player, GoodsId, GrowTime) of
                {?ok, Pony, Player2} ->
                    Packet	= horse_stable_api:pack_pony(Pony),
                    {?ok, Player3} = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_HORSE_COLT, 0, 1),
                    misc_packet:send(NetPid, Packet),
                    {?ok, Player3};
                {?error, ErrorCode} ->
                    %PacketErr = message_api:msg_notice(ErrorCode),
                    %misc_packet:send(NetPid, PacketErr),
                    {?error, ErrorCode}
            end;
        ?false ->
            {?error,?TIP_HORSE_USE_EGG}
    end.

%% 获取成就
add_achievement(Player,#goods{color = Color,lv = Lv}) ->
	{?ok, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_HORSE, 0, 1),
	if
		Color =:= ?CONST_SYS_COLOR_GREEN andalso Lv =:= 40 ->
			achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_GREEN_HORSE, 0, 1);
		Color =:= ?CONST_SYS_COLOR_BLUE andalso Lv =:= 60 ->
			achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_BLUE_HORSE, 0, 1);
		?true ->
			{?ok, Player2}
	end.

%% 生成坐骑
%% return : Goods | {?error, ErrorCode}
make_horse(Goods = #goods{color = Color,lv = Lv,exts = Exts}) ->
	case data_horse:get_horse({Color,Lv}) of
		?null ->  % 无对应品质、等级的坐骑
			{?error,?TIP_HORSE_GOODS};
		#rec_horse{count = Count, skill = SkillList, color_num = ColorNum,attr_lower = Lower, attr_upper = Upper} ->
			AttrNull = get_init_attr(),
			case Exts#g_equip.attr of
				AttrNull -> % 	初始属性为0 - 则随即生成属性
					OddList			= data_horse:get_horse_attr(),
					[{_,AttrList}]	= misc_random:random_list_norepeat(OddList, 1),			%% 随机获取属性组
					AttrList2		= misc_random:random_list_norepeat(AttrList, Count),	%% 属性组随机属性
					AttrList3		= make_horse_attr(AttrList2,Lv,ColorNum,Lower,Upper),
					{?ok, SkillId}	= get_skill_id(SkillList),								%% 技能id	
					Exts2 			= Exts#g_equip{skill_id = SkillId,ride_list = AttrList3}, 
					Goods#goods{exts = Exts2};
				Attr -> % 生成固定属性
					AttrList		= get_horse_list(Attr),
					{?ok, SkillId}	= get_skill_id(SkillList),		%% 技能id	
					Exts2 			= Exts#g_equip{attr = AttrNull, skill_id = SkillId, ride_list = AttrList}, 
					Goods#goods{exts = Exts2}
			end
	end.

%% 取出固定的2级属性
get_horse_list(#attr{attr_second = AttrSecond}) when is_record(AttrSecond,attr_second) ->
	List = [
	 {?CONST_PLAYER_ATTR_HP_MAX,		AttrSecond#attr_second.hp_max},
	 {?CONST_PLAYER_ATTR_FORCE_ATTACK,	AttrSecond#attr_second.force_attack},
	 {?CONST_PLAYER_ATTR_FORCE_DEF,		AttrSecond#attr_second.force_def},
	 {?CONST_PLAYER_ATTR_MAGIC_ATTACK,	AttrSecond#attr_second.magic_attack},
	 {?CONST_PLAYER_ATTR_MAGIC_DEF,		AttrSecond#attr_second.magic_def},
	 {?CONST_PLAYER_ATTR_SPEED,			AttrSecond#attr_second.speed}
	 ],
	get_horse_list(List,[]);
get_horse_list(_) -> []. 

get_horse_list([],List) ->
	List;
get_horse_list([{_,0}|L],List) ->
	get_horse_list(L,List);
get_horse_list([H|L],List) ->
	get_horse_list(L,[H|List]).

%% 取得随机数
get_random_value(Lower,Upper) ->
	misc_random:random(Lower, Upper) / ?CONST_SYS_NUMBER_TEN_THOUSAND.

%%--------------------------- 生成属性 --------------------------------------------------
make_horse_attr(AttrList,Lv,ColorRate,Lower,Upper) ->
	make_horse_attr(AttrList,Lv,ColorRate,Lower,Upper,[]).

make_horse_attr([],_Lv,_ColorRate,_Lower,_Upper,Result) ->
	Result;
make_horse_attr([{AttrType,AttrValue}|AttrList],Lv,ColorRate,Lower,Upper,Result) ->
	RandomNum	= get_random_value(Lower,Upper),
	AttrValue2 	= misc:ceil(AttrValue * Lv * ColorRate/?CONST_SYS_NUMBER_TEN_THOUSAND * RandomNum),
	Result2		= [{AttrType,AttrValue2}|Result],
	make_horse_attr(AttrList,Lv,ColorRate,Lower,Upper,Result2).
%%-----------------------------------------------------------------------------
%% 取出小马
%% return : {?ok, Player} | {?error, ErrorCode}
take_out(Player, Idx) ->
    case player_sys_api:is_open_sys(Player, ?CONST_MODULE_HORSE) of
        ?true ->
            case horse_stable_api:take_pony(Player, Idx) of
                {?ok, Horse, Player2} ->
                    case ctn_bag_api:put(Player2, [Horse], ?CONST_COST_HORSE_GET, 1, 1, 0, 0, 0, 1, []) of
                        {?ok, Player3, _, BagPacket} ->
                            
                            {?ok, Player4} = horse_mod:add_achievement(Player3, Horse), % 成就
                            {?ok, Player5} = welfare_api:add_pullulation(Player4, ?CONST_WELFARE_HORSE, 0, 1),  % 福利
                            
                            DelPacket  = horse_api:msg_sc_del_develop(Idx),
                            TipsPacket = message_api:msg_notice(?TIP_HORSE_TAKE_SUCCESS),
                            Packet     = <<BagPacket/binary, DelPacket/binary, TipsPacket/binary>>,
                            {?ok, Player5, Packet};
                        {?error, ErrorCode} ->
                            {?error, ErrorCode}
                    end;
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        ?false ->
            {?error, ?TIP_HORSE_USE_EGG}
    end.

%% 清除CD
clear_cd(Player, Idx) ->
    UserId = Player#player.user_id,
    case horse_stable_api:chk_clear_cd(Player, Idx) of
        {?ok, Pony} ->
            Cost = horse_stable_api:get_cd_cost(Pony#pony.ok_time),
            case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_HORSE_CLEAR_CD) of
                ?ok ->
                    case horse_stable_api:clear_cd(Player, Idx) of
                        {?ok, Player2, NewPony} ->
                            Packet = horse_stable_api:pack_pony(NewPony),
                            {?ok, Player2, Packet};
                        {?error, ErrorCode} ->
                            {?error, ErrorCode}
                    end;
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 获取坐骑数据
%% return : Goods	
get_horse(Player, Type, ParentId, HorseGrid) ->
	case get_horse_info(Player, Type, ParentId, HorseGrid) of
		?null ->
			throw({?error, ?TIP_HORSE_GOODS});
		{?ok, EquipInfo} ->
			?ok	= check_is_horse(EquipInfo),
			{?ok, EquipInfo}
	end.

get_horse_info(#player{user_id = UserId,bag = Bag,equip = Equip}, CtnType, _ParentId, Index) ->
	case CtnType of
		?CONST_GOODS_CTN_BAG -> %% 背包
			ctn_bag2_api:read(Bag, Index);
		?CONST_GOODS_CTN_EQUIP_PLAYER -> %% 角色装备
			case lists:keyfind({UserId, CtnType}, 1, Equip) of
				?false -> ?null;
				{_,Container} ->
					ctn_bag2_api:read(Container, Index)
			end;
		_ ->
			?null
	end.

%% 替换坐骑装备
%% return : Player | {?error, ErrorCode}
replace(Player = #player{user_id = UserId,bag = Container},?CONST_GOODS_CTN_BAG,_ParentId,Index,Goods) ->
	case ctn_bag2_api:replace(UserId, Container, Index, Goods) of
		{?error, ErrorCode}	->
			throw({?error, ErrorCode});
		{?ok, NewContainer, Packet} ->
			Player2 = Player#player{bag = NewContainer},
			{?ok, Player2, Packet}
	end;
replace(Player = #player{user_id = UserId,equip = Equip},CtnType,_ParentId,Index,Goods) 
  when CtnType =:= ?CONST_GOODS_CTN_EQUIP_PLAYER->
	Key = {UserId,CtnType},
	case lists:keytake(Key, 1, Equip) of
		?false ->
			throw({?error, ?TIP_HORSE_GOODS});
		{value, {_,Container}, Equip2} ->
 			case ctn_equip_api:replace(UserId, 0, CtnType, Container, Index, Goods) of	
				{?error, ErrorCode}	->
					throw({?error, ErrorCode});
				{?ok, NewContainer, Packet} ->
					NewEquip = [{Key,NewContainer}|Equip2],
					Player2  = Player#player{equip = NewEquip},
					{?ok, Player2, Packet}
			end
	end;	
replace(Player = #player{user_id = UserId,equip = Equip},CtnType,ParentId,Index,Goods) 
  when CtnType =:= ?CONST_GOODS_CTN_EQUIP_PLAYER->
	Key = {ParentId,CtnType},
	case lists:keytake(Key, 1, Equip) of
		?false ->
			throw({?error, ?TIP_HORSE_GOODS});
		{value, {_,Container}, Equip2} ->
			case ctn_equip_api:replace(UserId, ParentId, CtnType, Container, Index, Goods) of	
				{?error, ErrorCode}	->
					throw({?error, ErrorCode});
				{?ok, NewContainer, Packet} ->
					NewEquip = [{Key,NewContainer}|Equip2],
					Player2  = Player#player{equip = NewEquip},
					{?ok, Player2, Packet}
			end
	end;
replace(_,_,_,_,_) ->
	throw({?error, ?TIP_HORSE_GOODS}).
	
%% 商城一键升级
mall_lv_up(Player,CtnType,PartnerId,Grid,Goods) ->
	try
		NewGoods				= make_horse(Goods),
		{?ok, Player2, Packet2} = replace(Player,CtnType,PartnerId,Grid,NewGoods), 	%% 更新新的坐骑
		{?ok, Player2, Packet2}
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

%%------------------------------------------------------------------------------
%% 洗练
refresh(_Player, _CtnType, _PartnerId, _Grid,[]) ->
    {?error,?TIP_HORSE_REFRESH_ERROR};
refresh(Player, CtnType, PartnerId, Grid, List) ->
    try
        UserId                  = Player#player.user_id,
        {?ok,EquipInfo}         = get_horse(Player, CtnType, PartnerId, Grid),      %% 坐骑信息
        Exts                    = EquipInfo#goods.exts,
        ?ok                     = check_refresh_attr(Exts#g_equip.ride_list,List),
        {?ok,AttrList,Cash,Gold,Count}= get_refresh_attr_list(get_ride_list(Exts#g_equip.ride_list),EquipInfo#goods.color,EquipInfo#goods.lv,List),    
        Exts2                   = Exts#g_equip{ride_list = [Exts#g_equip.ride_list, AttrList]},  
        EquipInfo2              = EquipInfo#goods{exts = Exts2},
        {?ok, Player2, _Packet}  = horse_mod:replace(Player,CtnType,PartnerId,Grid,EquipInfo2), %% 更新新的坐骑
        ?ok                     = check_refresh_money(UserId,Cash,Gold,Count),
        Packet = horse_api:msg_attr_not_save(AttrList),
        misc_packet:send(UserId, Packet),
        {?ok,Player2}
    catch
        throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        A:B ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
            {?error,?TIP_HORSE_REFRESH_ERROR}
    end.    

get_ride_list([AttrList, _]) when is_list(AttrList) ->
    AttrList;
get_ride_list(AttrList) ->
    AttrList.
            
get_refresh_attr_list(RideList,Color,LvXXX,List) ->
    Lv = 
        if
            LvXXX < 20 ->
                20;
            ?true ->
                LvXXX
        end,
    {?ok,ColorNum,Lower,Upper,Cash,Gold} = get_refresh_data(Color,Lv),
    OddList         = data_horse:get_horse_attr(),
    [{_,AttrList}]  = misc_random:random_list_norepeat(OddList, 1),         %% 随机获取属性组                                
    {?ok,RideList2,AttrList2} = get_refresh_attr_list2(AttrList,RideList,List,[]),
    AttrList3       = make_horse_attr(AttrList2,Lv,ColorNum,Lower,Upper),
    AttrList4       = AttrList3 ++ RideList2,
    Count           = length(RideList) - length(AttrList3),
    Count2          = misc:ceil(math:pow(2, Count)),
    
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
    
check_refresh_money(UserId,Cash,Gold,Count) ->
    ?ok             = check_refresh_money2(UserId,?CONST_SYS_CASH,Cash * Count),
    ?ok             = check_refresh_money2(UserId,?CONST_SYS_GOLD_BIND,Gold * Count),
    ?ok             = check_minus_money(UserId,?CONST_SYS_CASH,Cash * Count,?CONST_COST_HORSE_REFRESH) , 
    ?ok             = check_minus_money(UserId,?CONST_SYS_GOLD_BIND,Gold * Count,?CONST_COST_HORSE_REFRESH) ,
    ?ok.

check_refresh_money2(UserId,?CONST_SYS_CASH,Cost) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_CASH, Cost) of
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

get_refresh_data(Color,Lv) ->
    case data_horse:get_horse({Color,Lv}) of
        ?null -> %% 无对应品质、等级的坐骑
            throw({?error,?TIP_HORSE_GOODS});
        #rec_horse{color_num = ColorNum,attr_lower = Lower, attr_upper = Upper,refresh_cash = Cash,refresh_gold = Gold} ->
            {?ok,ColorNum,Lower,Upper,Cash,Gold} 
    end.

check_refresh_attr(_AttrList,[]) ->
    ?ok;
check_refresh_attr(AttrList,[{AttrType}|L]) ->
    case lists:keyfind(AttrType, 1, AttrList) of
        ?false ->
            throw({?error,?TIP_HORSE_REFRESH_ERROR});
        {_,0} ->
            throw({?error,?TIP_HORSE_REFRESH_ZERO});
        _ -> 
            check_refresh_attr(AttrList,L)
    end.     

%% 检查金币
check_minus_money(UserId,CostType,Cost,Point) ->
    case player_money_api:minus_money(UserId,CostType, Cost, Point) of
        ?ok -> ?ok;
        {?error, _ErrorCode} ->
            throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH})
    end.
    

%%
%% Local Functions
%%

%% 初始属性为0
get_init_attr() ->
    #attr{
          attr_second   = #attr_second{},
          attr_elite    = #attr_elite{}
          }.

%% 取得技能id
get_skill_id([]) -> 
    {?ok, 0};
get_skill_id(SkillList) ->
    case misc_random:odds_list_norepeat(SkillList, 1) of
        [SkillId] ->
            {?ok, SkillId};
        _ ->
            {?ok, 0}
    end.

%% 是否为坐骑
check_is_horse(#goods{type = Type, sub_type = SubType}) 
  when Type =:= ?CONST_GOODS_TYPE_EQUIP andalso SubType =:= ?CONST_GOODS_EQUIP_HORSE ->
    ?ok;
check_is_horse(_) ->
    throw({?error, ?TIP_HORSE_GOODS}).

