%%% 装备栏操作相关的api
-module(ctn_equip_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([create/1, ctn_info/4, replace/6,
		 equip_on/3, equip_off/3, create/2,
		 refresh_attr/3, free_partner_equip/2,
		 check_partner_equip/2, equip_make_achievement/2,
		 equip_on_achievement/1, equip_soul_achievement/2,
         get_equip_ctn/4, get_part_info/5, replace_ctn/4,
		 bind_equip/2, login_packet/2, equip_list_make_achievement/2,
         calc_partner_list/1, get_partner_equip_effect/2, 
		 add_strengthen_attr/4, select_color_modules/2,
		 attr_plus_by_equip/5, refresh_attr_rate_group/1,
		 get_part_list/1, equip_skin_effect/2, change_skin/2, get_max_lv/1,
         is_non_equip/1]).
-export([zip/1, unzip/1]).
-export([record_key/2]).

%%
%% API Functions
%%

%% 新建装备容器
create(UserId) when is_number(UserId) ->
    Count = ?CONST_PLAYER_EQUIP_MAX_COUNT,
    case ctn_mod:init(Count, Count) of
        {?ok, Equip} ->
            Equip2 = init_ext(Equip, Count),
            PlayerEquipCtn = record_equip_ctn(UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER, Equip2),
            [PlayerEquipCtn];
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 初始化武将装备容器
create(PartnerId, EquipCtnList) when is_number(PartnerId) ->
    Count = ?CONST_PLAYER_EQUIP_MAX_COUNT,
    case ctn_mod:init(Count, Count) of
        {?ok, Equip} ->
            Equip2 = init_ext(Equip, Count),
            PartnerEquipCtn = record_equip_ctn(PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER, Equip2),
            [PartnerEquipCtn|EquipCtnList];
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 初始化强化部位
init_ext(Equip, Count) ->
    Ext		= erlang:make_tuple(Count, ?CONST_GOODS_INIT_STREN_LV, []),
    Equip2	= Equip#ctn{ext = Ext},
    Equip2.

%%--------------------------------------------------------------------------------------

%% 读取装备栏信息
%% {?ok, #ctn{}}/throw({?error, ErrorCode})
get_equip_ctn_inner(?CONST_GOODS_CTN_EQUIP_PLAYER = CtnType, UserId, _PartnerId, EquipList) ->
    case lists:keyfind({UserId, CtnType}, 1, EquipList) of
        {_, Equip} when is_record(Equip, ctn) ->
            {?ok, Equip};
        ?false ->
            throw({?error, ?TIP_COMMON_BAD_ARG})
    end;
get_equip_ctn_inner(?CONST_GOODS_CTN_EQUIP_PARTNER = CtnType, _UserId, PartnerId, EquipList) ->
    case lists:keyfind({PartnerId, CtnType}, 1, EquipList) of
        {_, Equip} when is_record(Equip, ctn) ->
            {?ok, Equip};
        ?false ->
            throw({?error, ?TIP_COMMON_BAD_ARG})
    end.

%% 读取装备栏信息
get_equip_ctn(CtnType, UserId, PartnerId, EquipList) ->
    try
        get_equip_ctn_inner(CtnType, UserId, PartnerId, EquipList)
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end.

%% 读取部位信息
get_part_info(CtnType, UserId, PartnerId, EquipList, Idx) when is_list(EquipList) ->
    try
        {?ok, Equip} = get_equip_ctn_inner(CtnType, UserId, PartnerId, EquipList),
        Ext = Equip#ctn.ext,
        StrLv = erlang:element(Idx, Ext), 
        {?ok, StrLv}
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end;
get_part_info(_CtnType, _UserId, _PartnerId, Equip, Idx) ->
    Ext = Equip#ctn.ext,
    StrLv = erlang:element(Idx, Ext),
    {?ok, StrLv}.

%% 获取人物部位强化等级列表
get_part_list(UserId) ->
	case player_api:get_player_field(UserId, #player.equip) of
		{?ok, Equip} ->
			case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, Equip) of
				{{_UserId, _Type}, Ctn} when is_record(Ctn, ctn) ->
					List = misc:to_list(Ctn#ctn.ext),
					lv_list_with_type(List, 1, []);
				_Other -> []
			end;
		_Other -> []
	end.

lv_list_with_type([], _Nth, Acc) ->
	Acc;
lv_list_with_type(_, Nth, Acc) when Nth > 8 ->
	Acc;
lv_list_with_type([Lv|T], Nth, Acc) ->
	lv_list_with_type(T, Nth+1, [{Nth, Lv}|Acc]).

ctn_info(Player = #player{user_id = UserId}, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PLAYER) ->% 请求自己角色装备
	EquipList	= Player#player.equip,
	case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
		?false ->
			<<>>;
		{_, Container} ->
			BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, Container#ctn.usable),
			GoodsList	= misc:to_list(Container#ctn.goods),
			BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, GoodsList, ?CONST_SYS_FALSE),
			<<BinCtnInfo/binary, BinGoodsInfo/binary>>
	end;
ctn_info(Player = #player{user_id = UserId}, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PARTNER) ->% 请求自己所有武将装备
    F = fun({{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, Container}, OldPacket) when is_record(Container, ctn) ->
                BinCtnInfo  = goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, Container#ctn.usable),
                GoodsList   = misc:to_list(Container#ctn.goods),
                BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, GoodsList, ?CONST_SYS_FALSE),
                <<BinCtnInfo/binary, BinGoodsInfo/binary, OldPacket/binary>>;
           (_, OldPacket) ->
                OldPacket
        end,
    lists:foldl(F, <<>>, Player#player.equip);
ctn_info(Player = #player{user_id = UserId}, UserId, PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER) ->% 请求自己武将装备
	EquipList	= Player#player.equip,
	case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
		?false ->
			<<>>;
		{_, Container} ->
			BinCtnInfo	= goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, 0, Container#ctn.usable),
			GoodsList	= misc:to_list(Container#ctn.goods),
			BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, GoodsList, ?CONST_SYS_FALSE),
			<<BinCtnInfo/binary, BinGoodsInfo/binary>>
	end;
ctn_info(_, UserId2, 0, ?CONST_GOODS_CTN_EQUIP_PLAYER) -> % 请求其他角色装备
    case player_api:get_player_field(UserId2, #player.equip) of
		{?ok, EquipList} ->
            case lists:keyfind({UserId2, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
                ?false ->
                    <<>>;
                {_, Container} ->
                    BinCtnInfo  = goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId2, 0, Container#ctn.usable),
                    GoodsList   = misc:to_list(Container#ctn.goods),
                    BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId2, 0, GoodsList, ?CONST_SYS_FALSE),
                    <<BinCtnInfo/binary, BinGoodsInfo/binary>>
            end;
        _ -> message_api:msg_notice(?TIP_COMMON_BAD_ARG)
    end;
ctn_info(_, UserId2, 0, ?CONST_GOODS_CTN_EQUIP_PARTNER) ->% 请求其他玩家武将装备
    case player_api:get_player_field(UserId2, #player.equip) of
        {?ok, EquipList} ->
            F = fun({{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, Container}, OldPacket) ->
                        BinCtnInfo  = goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId2, 0, Container#ctn.usable),
                        GoodsList   = misc:to_list(Container#ctn.goods),
                        BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId2, PartnerId, GoodsList, ?CONST_SYS_FALSE),
                        <<BinCtnInfo/binary, BinGoodsInfo/binary, OldPacket/binary>>;
                   ({_, ?CONST_GOODS_CTN_EQUIP_PLAYER}, OldPacket) ->
                        OldPacket
                end,
            lists:foldl(F, <<>>, EquipList);
        _ -> message_api:msg_notice(?TIP_COMMON_BAD_ARG)
    end;
ctn_info(_, UserId2, PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER) ->% 请求其他玩家武将装备
    case player_api:get_player_field(UserId2, #player.equip) of
        {?ok, EquipList} ->
            case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
                ?false ->
                    <<>>;
                {_, Container} ->
                    BinCtnInfo  = goods_api:msg_goods_sc_ctn_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId2, 0, Container#ctn.usable),
                    GoodsList   = misc:to_list(Container#ctn.goods),
                    BinGoodsInfo= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId2, PartnerId, GoodsList, ?CONST_SYS_FALSE),
                    <<BinCtnInfo/binary, BinGoodsInfo/binary>>
            end;
        _ -> message_api:msg_notice(?TIP_COMMON_BAD_ARG)
    end.

login_packet(Player, Packet) ->
    UserId = Player#player.user_id,
    Packet2 = ctn_info(Player, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PLAYER),
    Packet3 = ctn_info(Player, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PARTNER),
    {Player, <<Packet/binary, Packet2/binary, Packet3/binary>>}.
    
%% 替换物品到容器的目标位置
%% {error, ErrorCode} | {ok, NewContainer, Packet}
replace(UserId, PartnerId, CtnType, Container, Idx, Goods) ->
	case ctn_mod:replace(Container, Idx, Goods) of
		{?ok, Container2, ChangeList} ->
			Packet	= goods_api:msg_goods_list_info(CtnType, UserId, PartnerId, ChangeList, ?CONST_SYS_FALSE),
			{?ok, Container2, Packet};
        {?error, ?TIP_GOODS_NOT_OPENED} ->
            Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_OPENED),
            misc_packet:send(UserId, Packet),
            {?error, ?TIP_GOODS_NOT_OPENED};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%% 替换容器
replace_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER = CtnType, UserId, Equip, NewEquip) ->
    lists:keyreplace({UserId, CtnType}, 1, Equip, {{UserId, CtnType}, NewEquip});
replace_ctn(?CONST_GOODS_CTN_EQUIP_PARTNER = CtnType, PartnerId, Equip, NewEquip) ->
    lists:keyreplace({PartnerId, CtnType}, 1, Equip, {{PartnerId, CtnType}, NewEquip}).

equip_on(Player, PartnerId, Idx) ->
	Key = case PartnerId of
			  0 -> {Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER};
			  _ -> {PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}
		  end,
	case lists:keyfind(Key, 1, Player#player.equip) of
		{Key, CtnEquip} ->
			equip_on2(Player, Key, CtnEquip, Idx, PartnerId);
		?false ->
			Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.
equip_on2(Player = #player{net_pid = NetPid, info = Info}, Key, CtnEquip, Idx, PartnerId) ->
	UserLv  = Info#info.lv,
	UserSex = Info#info.sex,
	case ctn_bag2_api:read(Player#player.bag, Idx) of
		{?ok, ?null} ->% 装备不存在
			Packet  =   message_api:msg_notice(?TIP_GOODS_EQUIP_NOT_EXIST),
            misc_packet:send(Player#player.net_pid, Packet),
            {?error, ?TIP_GOODS_EQUIP_NOT_EXIST};
		{?ok, Goods} ->
            EquipSex = Goods#goods.sex, 
            EquipLv = Goods#goods.lv,
            MiniGoods = goods_api:goods_to_mini(Goods),
			case select_idx_by_type(Key, MiniGoods) of
				{?error, ?TIP_GOODS_NOT_EQUIPABLE} ->
                    Packet  =   message_api:msg_notice(?TIP_GOODS_NOT_EQUIPABLE),
                    misc_packet:send(NetPid, Packet),
                    {?error, ?TIP_GOODS_NOT_EQUIPABLE};
				{?error, ErrorCode} ->
                    Packet  =   message_api:msg_notice(ErrorCode),
                    misc_packet:send(NetPid, Packet),
					{?error, ErrorCode};
				EquipIdx ->
					try
						?ok   = check_equip_lv(UserLv, EquipLv),
						?ok   = check_equip_sex(EquipIdx, UserSex, EquipSex),
						?ok = check_partner_pro(Player, PartnerId, Goods#goods.pro),
						equip_on(Player, Key, CtnEquip, EquipIdx, Idx)
					catch
						throw:{?error, ErrorCode} ->
							PacketError = message_api:msg_notice(ErrorCode),
							misc_packet:send(NetPid, PacketError),
            				{?error, ErrorCode};
						X:Y ->
                            ?MSG_ERROR("~p:~p:~p", [X, Y, erlang:get_stacktrace()]),
                            PacketError = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                            misc_packet:send(NetPid, PacketError),
							{?error, ?TIP_COMMON_BAD_ARG}
					end
						
			end
	end.

check_equip_lv(UserLv, EquipLv) ->
	if UserLv < EquipLv ->
		   throw({?error, ?TIP_GOODS_LV_NOT_USE});
	   ?true ->
		   ?ok
	end.

check_partner_pro(_, _, 0) -> ?ok;
check_partner_pro(Player, 0, Pro) ->
    Info = Player#player.info,
    case Info#info.pro =:= Pro of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_GOODS_PRO_NOT_USE})
	end;
check_partner_pro(Player, PartnerId, Pro) ->
    case partner_api:get_partner_by_id(Player, PartnerId) of
        {?ok, Partner} ->
            case Partner#partner.pro =:= Pro of
				?true ->
					?ok;
				?false ->
					throw({?error, ?TIP_GOODS_PRO_NOT_USE})
			end;
        {?error, _} ->
            throw({?error, ?TIP_GOODS_PRO_NOT_USE})
    end.
%% 检查装备(时装)性别限制
check_equip_sex(?CONST_GOODS_EQUIP_FUSION, _UserSex, 0) -> ?ok;
check_equip_sex(?CONST_GOODS_EQUIP_FUSION, Sex, Sex) -> ?ok;
check_equip_sex(?CONST_GOODS_EQUIP_FUSION, _UserId, _EquipSex) -> ?error;
check_equip_sex(_Idx, _UserSex, 0) ->
	?ok.

equip_on(Player, Key, CtnEquip, EquipIdx, Idx) ->
	{Id, CtnType}	= Key,
	{?ok, Bag, ChangeListFrom, RemoveListFrom, CtnEquip2, ChangeListTo, RemoveListTo} =
		ctn_mod:outer_exchange(Player#player.bag, Idx, CtnEquip, EquipIdx),
	[GoodsTo]		= ChangeListTo,
	ChangeListTo2	= [GoodsTo#mini_goods{bind = ?CONST_GOODS_BIND}],
	BinChangeFrom	= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, Player#player.user_id, Id, ChangeListFrom, ?CONST_SYS_TRUE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, Player#player.user_id, RemoveListFrom),
	BinChangeTo		= goods_api:msg_goods_list_info(CtnType, Player#player.user_id, Id, ChangeListTo2, ?CONST_SYS_FALSE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(CtnType, Id, RemoveListTo),
	Packet			= <<BinChangeFrom/binary, BinRemoveFrom/binary, BinChangeTo/binary, BinRemoveTo/binary>>,
	
	CtnEquip3 		= bind_equip(CtnEquip2, EquipIdx),
	EquipList		= lists:keyreplace(Key, 1, Player#player.equip, {Key, CtnEquip3}),
    Player2	        = Player#player{bag = Bag, equip = EquipList},
    Player5			=
        case CtnType of
            ?CONST_GOODS_CTN_EQUIP_PLAYER ->
                Player3 = equip_skin_effect(Player2, GoodsTo),
    			Player4 = player_attr_api:refresh_attr_equip(Player3),
                change_skin(Player4, EquipIdx),
                %% 荣誉榜：第一个穿戴5级时装的玩家
                {?ok, PlayerFashion} = 
                    if (GoodsTo#mini_goods.exts)#g_equip.fusion_lv >= 5 ->
                           new_serv_api:add_honor_title(Player4, ?CONST_NEW_SERV_FIRST_FASHION, ?CONST_ACHIEVEMENT_FIRST_FASHION);
                       ?true ->
                           {?ok, Player4}
                    end,
				PlayerFashion;
            ?CONST_GOODS_CTN_EQUIP_PARTNER ->
                partner_api:refresh_attr_equip(Player2, Id)
        end,
	{_, Player6} = equip_on_achievement(Player5),
	{?ok, Player6, EquipIdx, Packet}.

%% 穿装备更新人物INFO
equip_skin_effect(Player, #mini_goods{exts = Exts} = MiniGoods) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    SubType = Goods#goods.sub_type,
    case Goods of
		_  when SubType =:= ?CONST_GOODS_EQUIP_FUSION_WEAPON
					orelse SubType =:= ?CONST_GOODS_EQUIP_HORSE
					orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION
					orelse SubType =:= ?CONST_GOODS_EQUIP_FUSION_STEP
		  ->
        	#g_equip{skin_id = SkinId} = Exts,
        	goods_style_api:change_skin_style(Player, SkinId, SubType); 
        _ ->
        	#g_equip{skin_id = SkinId} = Exts,
            goods_style_api:change_non_skin_style(Player, SkinId, SubType)
    end;
equip_skin_effect(Player, _Goods) ->
	Player.

equip_off(Player, PartnerId, EquipIdx) ->
	Key = case PartnerId of
			  0 -> {Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER};
			  _ -> {PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}
		  end,
	{Key, CtnEquip}	= lists:keyfind(Key, 1, Player#player.equip),
	case ctn_bag2_api:read(CtnEquip, EquipIdx) of
		{?ok, ?null} ->% 装备不存在
            Packet  =   message_api:msg_notice(?TIP_GOODS_EQUIP_NOT_EXIST),
            misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_GOODS_EQUIP_NOT_EXIST};
		{?ok, _Goods} ->
			case ctn_mod:empty_search(Player#player.bag) of
				{?ok, ?null} -> 
                    Packet  =   message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
                    misc_packet:send(Player#player.net_pid, Packet),
                    {?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
				{?ok, Idx} ->
                    try
					   equip_off(Player, Key, CtnEquip, EquipIdx, Idx)
                    catch
                        X:Y ->
                            ?MSG_ERROR("~p:~p:~p", [X, Y, erlang:get_stacktrace()]),
                            Packet  =   message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                            misc_packet:send(Player#player.net_pid, Packet),
                            {?error, ?TIP_COMMON_BAD_ARG}
                    end
			end
	end.
	
equip_off(Player, Key, CtnEquip, EquipIdx, Idx) ->
	{Id, CtnType}	= Key,
	{?ok, CtnEquip2, ChangeListFrom, RemoveListFrom, Bag, ChangeListTo, RemoveListTo} =
		ctn_mod:outer_exchange(CtnEquip, EquipIdx, Player#player.bag, Idx),
	[GoodsTo]		= ChangeListTo,
	BinChangeFrom	= goods_api:msg_goods_list_info(CtnType, Player#player.user_id, Id, ChangeListFrom, ?CONST_SYS_FALSE),
	BinRemoveFrom	= goods_api:msg_goods_list_remove(CtnType, Id, RemoveListFrom),
	BinChangeTo		= goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, Player#player.user_id, Id, ChangeListTo, ?CONST_SYS_TRUE),
	BinRemoveTo		= goods_api:msg_goods_list_remove(?CONST_GOODS_CTN_BAG, Player#player.user_id, RemoveListTo),
	Packet			= <<BinChangeFrom/binary, BinRemoveFrom/binary, BinChangeTo/binary, BinRemoveTo/binary>>,
	
	EquipList		= lists:keyreplace(Key, 1, Player#player.equip, {Key, CtnEquip2}),
	Exts			= (GoodsTo#mini_goods.exts)#g_equip{skin_id = 0},
	Player2       	= Player#player{bag = Bag, equip = EquipList},
    Player5			=
        case CtnType of
            ?CONST_GOODS_CTN_EQUIP_PLAYER ->
                Player3 = equip_skin_effect(Player2, GoodsTo#mini_goods{exts = Exts}),
                Player4	= player_attr_api:refresh_attr_equip(Player3),
				TmpPlayer = furnace_chest_api:remove_armor(Player4, EquipIdx),
				change_skin(TmpPlayer, EquipIdx),
				TmpPlayer;
            ?CONST_GOODS_CTN_EQUIP_PARTNER ->
                partner_api:refresh_attr_equip(Player2, Id)
        end,
	{?ok, Player5, Packet}.

change_skin(Player, EquipIdx) ->
	case EquipIdx of
		?CONST_GOODS_EQUIP_WEAPON ->
			team_api:update_team_player(Player),
			map_api:change_skin_weapon(Player);
		?CONST_GOODS_EQUIP_ARMOR ->
			team_api:update_team_player(Player),
			map_api:change_skin_armor(Player);
		?CONST_GOODS_EQUIP_FUSION_WEAPON ->
            schedule_power_api:do_update_fashion(Player),
			team_api:update_team_player(Player),
			map_api:change_skin_weapon(Player);
		?CONST_GOODS_EQUIP_FUSION_STEP ->
            schedule_power_api:do_update_fashion(Player),
			team_api:update_team_player(Player),
			map_api:change_skin_step(Player);
		?CONST_GOODS_EQUIP_FUSION ->
            schedule_power_api:do_update_fashion(Player),
			team_api:update_team_player(Player),
			map_api:change_skin_fashion(Player);
		?CONST_GOODS_EQUIP_HORSE ->
			team_api:update_team_player(Player),
			map_api:change_skin_ride(Player);
		_Other -> 
            ?ok
	end.

bind_equip(CtnEquip, Index) ->
	GoodsTuple = CtnEquip#ctn.goods,
	case element(Index, GoodsTuple) of
		?null ->
			CtnEquip;
		Goods ->
			NewGoods = Goods#mini_goods{bind = ?CONST_GOODS_BIND},
			GoodsTuple2 = setelement(Index, GoodsTuple, NewGoods),
			CtnEquip#ctn{goods = GoodsTuple2}
	end.

%% 检查武将是否穿戴装备 提供给武将遣散的接口
check_partner_equip(UserId, PartnerId) ->
	case player_api:get_player_field(UserId, #player.equip) of
		{?ok, EquipList} ->
			case lists:keyfind({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, EquipList) of
				?false -> ?false;
				{{_UserId, _CtnType}, Container} ->
					if
						Container#ctn.used > 0 -> ?true;
						?true -> ?false
					end
			end;
		_ -> ?false
	end.

%% 解雇武将 清空武将的装备信息和强化信息
free_partner_equip(Player, PartnerId) ->
	Equip  = Player#player.equip,
	Equip2 = lists:keydelete({PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, 1, Equip),
    Equip3 = ctn_equip_api:create(PartnerId, Equip2),
	Player#player{equip = Equip3}.

%% 佩戴装备成就
equip_on_achievement(Player) ->
	IsOrangeWeaponAll = check_all_equip_orange(Player),
	case IsOrangeWeaponAll of
		?true ->
			achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_ORANGE_SUITE, 0, 1);
		?false ->
			{?error, Player}
	end.

%% 得到装备成就(同时得到附魂)    TODO 需要掉落装备的模块调用该接口
equip_make_achievement(UserId, MiniGoods) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
	#goods{type = Type, sub_type = SubType, lv = Lv, color = Color} = Goods,
	case Type of
		?CONST_GOODS_TYPE_EQUIP ->
			equip_soul_achievement(UserId, MiniGoods),
			IsPurpleWeapon = (SubType =:= ?CONST_GOODS_EQUIP_WEAPON andalso Color =:= ?CONST_SYS_COLOR_PURPLE),	%紫色
			case IsPurpleWeapon of
				?true ->
					achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_PURPLE_WEAPON, Lv, 1);
				?false ->
					skip
			end;
		_Other ->
			skip
	end.

equip_list_make_achievement(_UserId, []) ->
	ok;
equip_list_make_achievement(UserId, [Goods|T]) when is_record(Goods, goods) ->
    MiniGoods = goods_api:goods_to_mini(Goods),
	equip_make_achievement(UserId, MiniGoods),
	equip_list_make_achievement(UserId, T);
equip_list_make_achievement(UserId, [MiniGoods|T]) when is_record(MiniGoods, mini_goods) ->
	equip_make_achievement(UserId, MiniGoods),
	equip_list_make_achievement(UserId, T);
equip_list_make_achievement(UserId, [_Goods|T]) ->
	equip_list_make_achievement(UserId, T).

%% 附魂装备成就
equip_soul_achievement(UserId, Equip) ->
	Exts		= Equip#mini_goods.exts,
	SoulList 	= Exts#g_equip.soul_list,
	check_equip_soul_color(UserId, SoulList).

%% 附魂是否得到成就
check_equip_soul_color(_UserId, _) ->
	?ok;
check_equip_soul_color(UserId, [{SoulId, SoulLv}|SoulList]) ->
	RecSoul = data_furnace:get_furnace_soul(SoulId),
	Color = RecSoul#rec_furnace_soul.color,
%% 	1/0,
	case Color of
		?CONST_SYS_COLOR_PURPLE ->		% TODO 具体的等级也有区分
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_PURPLE_SOUL, SoulLv, 1);
		?CONST_SYS_COLOR_ORANGE ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_ORANGE_SOUL, SoulLv, 1);
		?CONST_SYS_COLOR_RED ->
			achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_RED_SOUL, SoulLv, 1);
		_Other ->
			?ok
	end,
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_TEN_SOUL, SoulLv, 1),
	check_equip_soul_color(UserId, SoulList).

%%周身橙装
check_all_equip_orange(#player{user_id = UserId, equip = EquipList}) ->
	case lists:keyfind({UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, EquipList) of
		{_, CtnEquip} ->
			Equips = misc:to_list(CtnEquip#ctn.goods),
			check_all_equip_orange_help(Equips, 1);
		?false ->
			?false
	end.
check_all_equip_orange_help(_, 8) ->
	?true;
check_all_equip_orange_help([#mini_goods{} = MiniGoods|T], Acc) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    Type = Goods#goods.type,
    Color = Goods#goods.color,
    if
        Type =:= ?CONST_GOODS_TYPE_EQUIP andalso Color =:= ?CONST_SYS_COLOR_ORANGE ->
	       check_all_equip_orange_help(T, Acc+1);
        ?true ->
            ?false
    end;
check_all_equip_orange_help(_, _) ->
	?false.
	

%% 计算属性加成
refresh_attr(Player, Type, Id) -> % 伙伴或者玩家
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    HorseData = Player#player.horse,
    HorseTrain = HorseData#horse_data.train,
	case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
		{?ok, PlayerEquip} ->
		    case lists:keyfind({Id, Type}, 1, EquipList) of
		        {{_, ?CONST_GOODS_CTN_EQUIP_PLAYER}, CtnEquip} -> 
		            refresh_attr_ext(HorseTrain, PlayerEquip, CtnEquip, Id, 0);
		        {{_, ?CONST_GOODS_CTN_EQUIP_PARTNER}, CtnEquip} -> 
                    Horse = erlang:element(?CONST_GOODS_EQUIP_HORSE, PlayerEquip#ctn.goods),
		            refresh_attr_ext(HorseTrain, PlayerEquip, CtnEquip, Id, Horse);
		        ?false ->
					{player_attr_api:record_attr(), []}
		    end;
		_ ->
			{player_attr_api:record_attr(), []}
	end.

refresh_attr_ext(HorseTrain, PlayerEquip, Equip, UserId, Horse)
  when is_record(Equip, ctn) ->
    EquipTuple 	= Equip#ctn.goods,
    EquipList  	= erlang:tuple_to_list(EquipTuple),
	AccAttr		= player_attr_api:record_attr(),
   	AccAttr2 	= attr_plus(UserId, HorseTrain, EquipList, PlayerEquip, AccAttr, Horse), %% 这里把第人物的装备传进去算强化属性
	%% 在这计算套装属性
	{AttrVal, AttrPer}	= refresh_suit_attr(EquipList),
	AccAttr3	= player_attr_api:attr_plus(AccAttr2, AttrVal),
	{AccAttr3, AttrPer};
refresh_attr_ext(_, _PlayerEquip, _EquipList, _UserId, _) ->
    player_attr_api:record_attr().

%% 计算套装属性
refresh_suit_attr(EquipList) ->
	SuitIdList		= [(X#mini_goods.exts)#g_equip.suit_id|| X <- EquipList, is_record(X, mini_goods), (X#mini_goods.exts)#g_equip.suit_id =/= 0],
	SuitList		= misc:get_list_repeat_num(SuitIdList),
	InitAttr		= player_attr_api:record_attr(),
	AttrValList	 	= get_suit_attr_value(SuitList, []),
	AttrVal			= calc_suit_attr_value(AttrValList, InitAttr),
	AttrPer			= get_suit_attr_per(SuitList, []),
	{AttrVal, AttrPer}.

%% 计算套装加成属性
calc_suit_attr_value([], Attr) -> Attr;
calc_suit_attr_value([{Type, Value}|List], Attr) ->
	NewAttr	= player_attr_api:attr_plus(Attr, Type, Value),
	calc_suit_attr_value(List, NewAttr).
%% 获取套装加成值列表
get_suit_attr_value([], Acc) -> Acc;
get_suit_attr_value([{SuitId, Num}|SuitList], Acc) ->
	NewAcc =
		case data_goods:get_equip_suit_attr({SuitId, Num}) of
			SuitAttr when is_record(SuitAttr, rec_equip_suit_attr) ->
				Acc ++ SuitAttr#rec_equip_suit_attr.attr_value;
			_ ->
				Acc
		end,
	get_suit_attr_value(SuitList, NewAcc);
get_suit_attr_value([Other|SuitList], Acc) ->
	?MSG_ERROR("error suit attr per:~p~n ", [Other]),
	get_suit_attr_value(SuitList, Acc).
%% 获取套装加成百分比列表
get_suit_attr_per([], Acc) -> 
	Fun = fun({Type, Factor}, AccIn) ->
				  [{Type, Factor, ?CONST_SYS_NUMBER_TEN_THOUSAND}|AccIn]
		  end,
	lists:foldl(Fun, [], Acc);
get_suit_attr_per([{SuitId, Num}|SuitList], Acc) ->
	NewAcc =
		case data_goods:get_equip_suit_attr({SuitId, Num}) of
			SuitAttr when is_record(SuitAttr, rec_equip_suit_attr) ->
				Acc ++ SuitAttr#rec_equip_suit_attr.attr_per;
			_ ->
				Acc
		end,
	get_suit_attr_per(SuitList, NewAcc);
get_suit_attr_per([Other|SuitList], Acc) ->
	?MSG_ERROR("error suit attr per:~p~n ", [Other]),
	get_suit_attr_per(SuitList, Acc).
	
calc_partner_list(Player) ->
	EquipList 		= Player#player.equip,
	UserId			= Player#player.user_id,
	case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, UserId, EquipList) of
		{?ok, Equip} ->
			UserEquip		= calc_goods_list(Player,UserId,Equip,Equip),
			PartnerEquip	= calc_partner_list(Player,EquipList,Equip),
			lists:append(UserEquip, PartnerEquip);
		_ -> []
	end.

calc_partner_list(Player,EquipList,Ext) ->
	PartnerList = partner_api:get_out_partner(Player),
	calc_partner_list2(Player,PartnerList,EquipList,[],Ext).

calc_partner_list2(_Player,[],_EquipList,List,_Ext) ->
	List;
calc_partner_list2(Player,[Partner|PartnerList],EquipList,List,Ext) ->
	UserId 		= Player#player.user_id,
	PartnerId	= Partner#partner.partner_id,
	List2		= case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, EquipList) of
					{?ok, Equip} ->
						calc_goods_list(Player,PartnerId,Equip,Ext);
					_ -> []
				  end,
	calc_partner_list2(Player,PartnerList,EquipList,lists:append(List, List2),Ext).
	
calc_goods_list(Player,PartnerId,Equip,Ext) ->
	GoodsList 	= erlang:tuple_to_list(Equip#ctn.goods),
	calc_goods_list2(Player,PartnerId,GoodsList,Equip,[],Ext).

calc_goods_list2(_Player,_PartnerId,[],_,List,_) -> 
	List;
calc_goods_list2(Player,PartnerId,[#mini_goods{} = MiniGoods|GoodsList],EquipCtn,List,Ext) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    if
        Goods#goods.color >= ?CONST_SYS_COLOR_BLUE 
		  andalso Goods#goods.lv >= 20 andalso Goods#goods.sub_type =< ?CONST_GOODS_EQUIP_RING ->
        	GoodsId = Goods#goods.goods_id,
        	Type	= Goods#goods.sub_type,
        	UserId	= Player#player.user_id,
        	AccAttr	= player_attr_api:record_attr(),
            HorseData = horse_api:get_horse_train(Player),
        	NewAttr	= attr_plus_by_equip(UserId, HorseData, MiniGoods, Ext, AccAttr),
        	Power	= player_attr_api:caculate_power(NewAttr),
        	List2	= [{PartnerId,Type,GoodsId,Power,Goods#goods.color,Goods#goods.lv}|List],			 
        	calc_goods_list2(Player,PartnerId,GoodsList,EquipCtn,List2,Ext);
        ?true ->
            calc_goods_list2(Player,PartnerId,GoodsList,EquipCtn,List,Ext)
    end;
calc_goods_list2(Player,PartnerId,[_|GoodsList],Equip,List,Ext) ->
	calc_goods_list2(Player,PartnerId,GoodsList,Equip,List,Ext).

get_partner_equip_effect(Player, PartnerId) when is_record(Player, player) ->
    EquipList = Player#player.equip,
    get_partner_equip_effect(EquipList, PartnerId);
get_partner_equip_effect([{{_UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, _Equip2}|Tail], PartnerId) ->
    get_partner_equip_effect(Tail, PartnerId);
get_partner_equip_effect([{{PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}, Equip}|_], PartnerId) ->
    get_equip_effect(PartnerId, Equip);
get_partner_equip_effect([{{_, ?CONST_GOODS_CTN_EQUIP_PARTNER}, _}|Tail], PartnerId) ->
    get_partner_equip_effect(Tail, PartnerId);
get_partner_equip_effect([], PartnerId) ->
    {PartnerId, 0, 0}.

get_equip_effect(PartnerId, Equip) ->
    try
        GoodsTuple = Equip#ctn.goods,
        WeaponGoods = erlang:element(?CONST_GOODS_EQUIP_WEAPON, GoodsTuple),
        Id1 = get_weapon_id(WeaponGoods),
        ArmorGoods  = erlang:element(?CONST_GOODS_EQUIP_ARMOR, GoodsTuple),
        Id2 = get_weapon_id(ArmorGoods),
        {PartnerId, Id1, Id2}
    catch
        _:_ ->
            {PartnerId, 0, 0}
    end.

get_weapon_id(Goods) when is_record(Goods, mini_goods) ->
    Exts = Goods#mini_goods.exts,
    Exts#g_equip.skin_id;
get_weapon_id(Goods) when is_record(Goods, goods) ->
    Exts = Goods#goods.exts,
    Exts#g_equip.skin_id;
get_weapon_id(_) ->
    0.

%% 读取最大强化等级
get_max_lv(Player) ->
    EquipList = Player#player.equip,
    case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, Player#player.user_id, 0, EquipList) of
        {?ok, Ctn} ->
            StrenTuple = Ctn#ctn.ext,
            StrenList  = erlang:tuple_to_list(StrenTuple),
            get_max_lv(StrenList, 0);
        _ ->
            0
    end.

get_max_lv([Lv|Tail], OldMaxLv) when Lv > OldMaxLv ->
    get_max_lv(Tail, Lv);
get_max_lv([_|Tail], OldMaxLv) ->
    get_max_lv(Tail, OldMaxLv);
get_max_lv([], Lv) ->
    Lv.
    

    

%%
%% Local Functions
%%
    
%% 计算属性
attr_plus(UserId, HorseTrain, [Goods|Tail], EquipCtn, AccAttr, Horse) when is_record(Goods, goods) ->
	AccAttr5   	 	= attr_plus_by_equip(UserId, HorseTrain, Goods, EquipCtn, AccAttr),	
	attr_plus(UserId, HorseTrain, Tail, EquipCtn, AccAttr5, Horse);
attr_plus(UserId, HorseTrain, [Goods|Tail], EquipCtn, AccAttr, Horse) when is_record(Goods, mini_goods) ->
	AccAttr5   	 	= attr_plus_by_equip(UserId, HorseTrain, Goods, EquipCtn, AccAttr),	
	attr_plus(UserId, HorseTrain, Tail, EquipCtn, AccAttr5, Horse);
attr_plus(UserId, HorseTrain, [_Equip|Tail], EquipCtn, AccAttr, Horse) ->
	attr_plus(UserId, HorseTrain, Tail, EquipCtn, AccAttr, Horse);
attr_plus(UserId, HorseTrain, [], EquipCtn, AccAttr, Horse) ->
    attr_plus_by_equip(UserId, HorseTrain, Horse, EquipCtn, AccAttr).

%% 计算单个装备
attr_plus_by_equip(UserId, HorseTrain, MiniGoods, EquipCtn, AccAttr) when is_record(MiniGoods, mini_goods) ->
	Exts		 	= MiniGoods#mini_goods.exts,
    Goods           = goods_api:mini_to_goods(MiniGoods),
	BaseAttr		= Exts#g_equip.attr,
	SoulList	 	= furnace_mod:trans_soul_id_value2(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, Exts#g_equip.soul_list),
	RideList		= horse_mod:get_ride_list(Exts#g_equip.ride_list),
	StrenList 		= add_strengthen_attr(UserId, HorseTrain, MiniGoods, EquipCtn),		%强化后的装备属性，每次强化都要刷新
	AccAttr2		= case Goods#goods.sub_type of
						  ?CONST_GOODS_EQUIP_HORSE -> AccAttr;
						  _ -> player_attr_api:attr_plus(AccAttr, BaseAttr) %基础ATTR
					  end,
	AccAttr3	 	= player_attr_api:attr_plus(AccAttr2, StrenList),	%强化属性
	AccAttr4   	 	= player_attr_api:attr_plus(AccAttr3, SoulList),	%附魂属性
	AccAttr5   	 	= player_attr_api:attr_plus(AccAttr4, RideList),	%坐骑
	AccAttr5;
attr_plus_by_equip(_, _, _, _, Attr) ->
    Attr.
	
%% 强化值
add_strengthen_attr(UserId, HorseTrain, MiniGoods, EquipCtn) ->
    Equip = goods_api:mini_to_goods(MiniGoods),
    case Equip#goods.sub_type of
        ?CONST_GOODS_EQUIP_HORSE ->
	       horse_api:get_attr_list(HorseTrain, Equip#goods.color, Equip#goods.lv);
        ?CONST_GOODS_EQUIP_FUSION ->
            [];
        _ ->
        	ColorModulus 	= select_color_modules(Equip#goods.color, Equip#goods.lv),
        	{?ok, Lv}       = get_part_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipCtn, Equip#goods.sub_type),
        	RecStrengthen 	= furnace_stren_api:get_stren_lv(Equip#goods.sub_type, Equip#goods.pro),	
        	case is_record(RecStrengthen, rec_furnace_strengthen) of
        		?true ->
        			List	= RecStrengthen#rec_furnace_strengthen.list,
        			lists:map(fun({Type, Value}) -> {Type, (Lv * Value * ColorModulus div 10000)} end, List);
        		?false ->
        			case furnace_stren_api:get_stren_lv(Equip#goods.sub_type, 0) of
        				RecStrengthen2 when is_record(RecStrengthen2, rec_furnace_strengthen) ->
        					List2	= RecStrengthen2#rec_furnace_strengthen.list,
        					lists:map(fun({Type2, Value2}) -> {Type2, (Lv * Value2 * ColorModulus div 10000)} end, List2);
        				_ ->
        					[]
        			end
        	end
    end.

%% 不同品阶的强化系数
select_color_modules(Color, Lv) ->
	Lv2 = color_lv((Lv div 10) + 1),
	case data_furnace:get_furnace_stren_color(Lv2) of
		?null ->
			1;
		List ->
			case lists:keyfind(Color, 1, List) of
				?false ->
					1;
				{_Color, Value} ->	%value是浮点数
					misc:ceil(Value * 10000)
			end
	end.

color_lv(Lv) when Lv < 0 ->
	1;
color_lv(Lv) when Lv > 10 ->
	10;
color_lv(Lv) ->
	Lv.
	
		  
%% 装备类型转换成装备位置
select_idx_by_type(Key, MiniGoods) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
	case Key of
		{_, ?CONST_GOODS_CTN_EQUIP_PLAYER} ->
			select_idx(Goods#goods.type, Goods#goods.sub_type);
		{_, ?CONST_GOODS_CTN_EQUIP_PARTNER} ->
			case Goods#goods.type =/= ?CONST_GOODS_EQUIP_BADGE andalso
				 Goods#goods.type =/= ?CONST_GOODS_EQUIP_HORSE	 of
				?true ->
					select_idx(Goods#goods.type, Goods#goods.sub_type);
				?false ->
					{?error, ?TIP_GOODS_NOT_OPENED}
			end;
		_Other ->
			{?error, ?TIP_GOODS_NOT_OPENED}
	end.
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_WEAPON) 	-> ?CONST_GOODS_EQUIP_WEAPON;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_ARMOR) 	-> ?CONST_GOODS_EQUIP_ARMOR;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_HELMET)	-> ?CONST_GOODS_EQUIP_HELMET;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_BOOTS)	-> ?CONST_GOODS_EQUIP_BOOTS;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_CLOAK)  	-> ?CONST_GOODS_EQUIP_CLOAK;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_BELT)   	-> ?CONST_GOODS_EQUIP_BELT;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_NECKLACE)-> ?CONST_GOODS_EQUIP_NECKLACE;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_RING)   	-> ?CONST_GOODS_EQUIP_RING;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_FUSION) 	-> ?CONST_GOODS_EQUIP_FUSION;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_BADGE) 	-> ?CONST_GOODS_EQUIP_BADGE;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_HORSE)   -> ?CONST_GOODS_EQUIP_HORSE;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_FUSION_WEAPON)   -> ?CONST_GOODS_EQUIP_FUSION_WEAPON;
select_idx(?CONST_GOODS_TYPE_EQUIP, 	?CONST_GOODS_EQUIP_FUSION_STEP)   -> ?CONST_GOODS_EQUIP_FUSION_STEP;
select_idx(_Type, _SubType) -> {?error, ?TIP_GOODS_NOT_EQUIPABLE}.% 该物品不能装备

zip(EquipList) when is_list(EquipList) ->
    zip(EquipList, []).

zip([{Key, CtnEquip}|Tail], ResultList) ->
    ZipedCtnEquip = ctn_api:zip(CtnEquip),
    NewResultList = [{Key, ZipedCtnEquip}|ResultList],
    zip(Tail, NewResultList);
zip([], ResultList) ->
    ResultList.

unzip(EquipList) when is_list(EquipList) ->
    unzip(EquipList, []).

unzip([{Key, CtnEquip}|Tail], ResultList) ->
    ZipedCtnEquip = ctn_api:unzip(CtnEquip),
    NewResultList = [{Key, ZipedCtnEquip}|ResultList],
    unzip(Tail, NewResultList);
unzip([], ResultList) ->
    ResultList.

%% 计算时装的加成
refresh_attr_rate_group(Player) ->
	UserId = Player#player.user_id,
	EquipList = Player#player.equip,
	case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
		{?ok, EquipCtn} ->
			GoodsTuple = EquipCtn#ctn.goods,
			List1 =
				case erlang:element(?CONST_GOODS_EQUIP_FUSION, GoodsTuple) of
					#mini_goods{exts = Exts} when is_record(Exts, g_equip) ->
						FusionLv = Exts#g_equip.fusion_lv,
						case data_furnace:get_fusion_attr({?CONST_GOODS_EQUIP_FUSION, FusionLv}) of
							#rec_furnace_fashion_attr{attr_per = AttrList} ->
								[{X1,X2,?CONST_SYS_NUMBER_TEN_THOUSAND}||{X1,X2}<-AttrList];
							_ ->
								[]
						end;
					_ ->
						[]
				end,
			List2 =
				case erlang:element(?CONST_GOODS_EQUIP_FUSION_WEAPON, GoodsTuple) of
					#mini_goods{exts = Exts1} when is_record(Exts1, g_equip) ->
						FusionLv1 = Exts1#g_equip.fusion_lv,
						case data_furnace:get_fusion_attr({?CONST_GOODS_EQUIP_FUSION_WEAPON, FusionLv1}) of
							#rec_furnace_fashion_attr{attr_per = AttrList1} ->
								[{X3,X4,?CONST_SYS_NUMBER_TEN_THOUSAND}||{X3,X4}<-AttrList1];
							_ ->
								[]
						end;
					_ ->
						[]
				end,
			F = fun({Type, Factor, Base}, Acc) ->
						case lists:keytake(Type, 1, Acc) of
							?false ->
								[{Type, Factor, Base} | Acc];
							{value, {Type, Factor1, Base}, Acc2} ->
								[{Type, Factor + Factor1, Base} | Acc2]
						end
				end,
			lists:foldl(F, List1, List2);
		_ ->
			[]
	end.

%% 玩家无装备
%% ?true/?false
is_non_equip(Player) ->
    EquipList = Player#player.equip,
    case get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, Player#player.user_id, 0, EquipList) of
        {?ok, EquipCtn} ->
            is_non_equip_2(erlang:tuple_to_list(EquipCtn#ctn.goods));
        {?error, ErrorCode} ->
            ?MSG_ERROR("no ctn err=[~p], user_id=[~p]", [ErrorCode, Player#player.user_id]),
            0
    end.

is_non_equip_2([#mini_goods{} = MiniGoods|_Tail]) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
    case Goods#goods.sub_type of
        ?CONST_GOODS_EQUIP_HORSE -> 2;
        ?CONST_GOODS_EQUIP_FUSION -> 3;
        ?CONST_GOODS_EQUIP_FUSION_STEP -> 3;
        ?CONST_GOODS_EQUIP_FUSION_WEAPON -> 3;
        _ -> 1
    end;
is_non_equip_2([0|Tail]) ->
    is_non_equip_2(Tail);
is_non_equip_2([]) ->
    0.

%% --------------------------------------------------------------------------------
%% 封装record_equip_ctn
record_equip_ctn(Id, Type, Ctn) -> {{Id, Type}, Ctn}.

record_key(Id, Type) -> {Id, Type}.