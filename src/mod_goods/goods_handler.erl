%% Author: php
%% Created: 2012-07-24 18
%% Description: TODO: Add description to goods_handler
-module(goods_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 请求物品数据
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 容器类型--背包 
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId,PartnerId,?CONST_GOODS_CTN_BAG}) ->
    Packet = ctn_bag2_api:ctn_info(Player#player.user_id, PartnerId, Player#player.bag),
    misc_packet:send(Player#player.net_pid, Packet),
    ?ok;
%% 容器类型--仓库  
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId,PartnerId,?CONST_GOODS_CTN_DEPOT}) ->
    Packet = ctn_depot_api:ctn_info(Player#player.user_id, PartnerId, Player#player.depot),
    misc_packet:send(Player#player.net_pid, Packet),
    ?ok;
%% 容器类型--临时背包 
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId, _PartnerId,?CONST_GOODS_CTN_BAG_TEMP}) ->
    {?ok, NewBag, Packet} = ctn_bag2_api:ctn_info_temp(Player#player.user_id, Player#player.bag),
    NewPlayer = Player#player{bag = NewBag},
    misc_packet:send(NewPlayer#player.net_pid, Packet),
    {?ok, NewPlayer};
%% 容器类型--角色装备栏 
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {UserId, _PartnerId, ?CONST_GOODS_CTN_EQUIP_PLAYER}) ->
    Packet = ctn_equip_api:ctn_info(Player, UserId, 0, ?CONST_GOODS_CTN_EQUIP_PLAYER),
    misc_packet:send(Player#player.net_pid, Packet),
    ?ok;
%% 容器类型--伙伴装备栏 
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {UserId2, PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER}) -> 
    Packet	= ctn_equip_api:ctn_info(Player, UserId2, PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER),
    misc_packet:send(Player#player.net_pid, Packet),
    ?ok;
%% 容器类型--角色神兵栏 
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {UserId2, _PartnerId, ?CONST_GOODS_CTN_WEAPON}) ->
    UserId = Player#player.user_id,
    Packet = weapon_api:weapon_info(Player, UserId2),
    misc_packet:send(UserId, Packet),
    ?ok;
%% 容器类型--宝箱仓库
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId, _PartnerId, ?CONST_GOODS_CTN_LOTTERY_DEPOT}) ->
    {?ok, NewPlayer, Packet} = lottery_api:ctn_info(Player),
    misc_packet:send(NewPlayer#player.net_pid, Packet),
    {?ok, NewPlayer};
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId, _PartnerId, ?CONST_GOODS_CTN_REMOTE_DEPOT}) -> % 远程仓库
    VipLv	= player_api:get_vip_lv(Player),
    IsFree	= player_vip_api:get_remote_bag_cost(VipLv),

    if
        IsFree =:= ?CONST_SYS_FALSE ->
            case player_money_api:minus_money(Player#player.user_id, ?CONST_GOODS_REMOTE_DEPOT_COST_TYPE, ?CONST_GOODS_REMOTE_DEPOT_COST_VALUE, ?CONST_COST_GOODS_REMOTE_DEPOT) of
                ?ok ->
                    Packet = goods_api:msg_sc_open_remote(?CONST_GOODS_CTN_REMOTE_DEPOT, 0),
                    misc_packet:send(Player#player.net_pid, Packet);
                {?error, _ErrorCode} ->
                    ?ok
            end;
        ?true ->
            Packet = goods_api:msg_sc_open_remote(?CONST_GOODS_CTN_REMOTE_DEPOT, 0),
            misc_packet:send(Player#player.net_pid, Packet)
    end,
    ?ok;
handler(?MSG_ID_GOODS_CS_CTN_INFO, Player, {_UserId, _PartnerId, ?CONST_GOODS_CTN_REMOTE_SHOP}) -> % 远程道具店
    VipLv = player_api:get_vip_lv(Player),
    IsFree = player_vip_api:get_remote_shop_cost(VipLv),

    if
        IsFree =:= ?CONST_SYS_FALSE ->
            case player_money_api:minus_money(Player#player.user_id, ?CONST_GOODS_REMOTE_SHOP_COST_TYPE, ?CONST_GOODS_REMOTE_SHOP_COST_VALUE, ?CONST_COST_GOODS_REMOTE_SHOP) of
                ?ok ->
                    OpenedMapList = Player#player.maps,
                    Info = Player#player.info,
                    Pro = Info#info.pro,
                    Sex = Info#info.sex,
                    PlayerInit = data_player:get_player_init({Pro, Sex}),
                    MapId = PlayerInit#rec_player_init.map,
                    NpcId = map_api:get_max_city_npc_id(OpenedMapList, MapId),
                    Packet = goods_api:msg_sc_open_remote(?CONST_GOODS_CTN_REMOTE_SHOP, NpcId),
                    misc_packet:send(Player#player.net_pid, Packet);
                {?error, _ErrorCode} ->
                    ?ok
            end;
        ?true ->
            OpenedMapList = Player#player.maps,
            Info = Player#player.info,
            Pro = Info#info.pro,
            Sex = Info#info.sex,
            PlayerInit = data_player:get_player_init({Pro, Sex}),
            MapId = PlayerInit#rec_player_init.map,
            NpcId = map_api:get_max_city_npc_id(OpenedMapList, MapId),
            Packet = goods_api:msg_sc_open_remote(?CONST_GOODS_CTN_REMOTE_SHOP, NpcId),
            misc_packet:send(Player#player.net_pid, Packet)
    end,
    ?ok;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 刷新容器
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handler(?MSG_ID_GOODS_CS_REFRESH, Player, {?CONST_GOODS_CTN_BAG}) ->
    {?ok, NewContainer} = ctn_bag2_api:refresh(Player#player.user_id, Player#player.bag),
    {?ok, Player#player{bag = NewContainer}};
handler(?MSG_ID_GOODS_CS_REFRESH, Player, {?CONST_GOODS_CTN_DEPOT}) ->
    {?ok, NewContainer} = ctn_depot_api:refresh(Player#player.user_id, Player#player.depot),
    {?ok, Player#player{depot = NewContainer}};
%% handler(?MSG_ID_GOODS_CS_REFRESH, Player, {?CONST_GOODS_CTN_BAG_TEMP}) ->
%%     {?ok, NewContainer} = ctn_temp_bag_api:refresh(Player#player.user_id, Player#player.temp_bag),
%%     {?ok, Player#player{temp_bag = NewContainer}};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 移除物品
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handler(?MSG_ID_GOODS_CS_REMOVE, Player, {CtnType,Idx}) ->
    case CtnType of
        ?CONST_GOODS_CTN_BAG ->
            case ctn_bag2_api:get_by_idx(Player#player.user_id, Player#player.bag, Idx) of
                {?ok, Container, GoodsList, Packet} ->
                    misc_packet:send(Player#player.net_pid, Packet),
                    admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_DROP_BAG, GoodsList, misc:seconds()),
                    {?ok, Player#player{bag = Container}};
                {?error, _ErrorCode} ->
                    ?error
            end;
		 ?CONST_GOODS_CTN_DEPOT ->
            case ctn_depot_api:get_by_idx(Player#player.user_id, Player#player.depot, Idx) of
                {?ok, Container, GoodsList, Packet} ->
                    misc_packet:send(Player#player.net_pid, Packet),
                    admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_DROP_DEPOT, GoodsList, misc:seconds()),
                    {?ok, Player#player{depot = Container}};
                {?error, _ErrorCode} ->
                    ?error
            end;
        _ -> ?ok
    end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 拖动物品请求--同一容器内
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_BAG,IdxFrom,?CONST_GOODS_CTN_BAG,IdxTo}) ->
    case ctn_bag2_api:inner_exchange(Player#player.user_id, Player#player.bag, IdxFrom, IdxTo) of
        {?ok, NewContainer, Packet} ->
            misc_packet:send(Player#player.net_pid, Packet),
            {?ok, Player#player{bag = NewContainer}};
        {?error, _ErrorCode, PacketErr} ->
            misc_packet:send(Player#player.net_pid, PacketErr),
            ?error
    end;
handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_DEPOT,IdxFrom,?CONST_GOODS_CTN_DEPOT,IdxTo}) ->
    {?ok, NewContainer, Packet} =
        ctn_depot_api:inner_exchange(Player#player.user_id, Player#player.depot, IdxFrom, IdxTo),
    misc_packet:send(Player#player.net_pid, Packet),
    {?ok, Player#player{depot = NewContainer}};
handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_BAG_TEMP,IdxFrom,?CONST_GOODS_CTN_BAG_TEMP,IdxTo}) ->
    {?ok, NewContainer, Packet} =
        ctn_temp_bag_api:inner_exchange(Player#player.user_id, Player#player.temp_bag, IdxFrom, IdxTo),
    misc_packet:send(Player#player.net_pid, Packet),
    {?ok, Player#player{temp_bag = NewContainer}};
%% 拖动物品请求--不同容器间
handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_BAG,IdxFrom,?CONST_GOODS_CTN_DEPOT,IdxTo}) ->
    {?ok, NewContainerFrom, NewContainerTo, Packet} =
        ctn_bag2_api:outer_exchange(Player#player.user_id, Player#player.bag, IdxFrom, 
                                   ?CONST_GOODS_CTN_DEPOT, Player#player.depot, IdxTo),
    misc_packet:send(Player#player.net_pid, Packet),
    {?ok, Player#player{bag = NewContainerFrom, depot = NewContainerTo}};
handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_DEPOT,IdxFrom,?CONST_GOODS_CTN_BAG,IdxTo}) ->
    {?ok, NewContainerFrom, NewContainerTo, Packet} =
        ctn_depot_api:outer_exchange(Player#player.user_id, Player#player.depot, IdxFrom, 
                                     ?CONST_GOODS_CTN_BAG, Player#player.bag, IdxTo),
    misc_packet:send(Player#player.net_pid, Packet),
    {?ok, Player#player{bag = NewContainerTo, depot = NewContainerFrom}};
%% handler(?MSG_ID_GOODS_CS_DRAG, Player, {?CONST_GOODS_CTN_BAG_TEMP,IdxFrom,?CONST_GOODS_CTN_BAG, IdxTo}) ->
%%     case ctn_bag2_api:outer_exchange(Player#player.user_id, Player#player.bag, IdxFrom, 
%%                                         ?CONST_GOODS_CTN_BAG, Player#player.bag, IdxTo) of
%%         {?ok, NewContainerFrom, NewContainerTo, Packet} ->
%%             PacketTip = message_api:msg_notice(?TIP_GOODS_GET_OK),
%%             misc_packet:send(Player#player.user_id, <<Packet/binary, PacketTip/binary>>),
%%             {?ok, Player#player{temp_bag = NewContainerFrom, bag = NewContainerTo}};
%%         {?error, ErrorCode} ->
%%             UserId = Player#player.user_id,
%%             PacketErr = message_api:msg_notice(ErrorCode),
%%             misc_packet:send(UserId, PacketErr),
%%             {?ok, Player}
%%     end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 拆分物品
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handler(?MSG_ID_GOODS_CS_SPLIT, Player, {CtnType,Idx,Count}) ->
    case case CtnType of
             ?CONST_GOODS_CTN_BAG ->
                 ctn_bag2_api:split(Player#player.user_id, Player#player.bag, Idx, Count);
             ?CONST_GOODS_CTN_DEPOT ->
                 ctn_depot_api:split(Player#player.user_id, Player#player.depot, Idx, Count);
             ?CONST_GOODS_CTN_BAG_TEMP ->
                 ctn_temp_bag_api:split(Player#player.user_id, Player#player.temp_bag, Idx, Count);
             _ ->
                 {?error, ?TIP_COMMON_BAD_ARG}
         end of
        {?ok, Container2, Packet} ->
            misc_packet:send(Player#player.net_pid, Packet),
            case CtnType of
                ?CONST_GOODS_CTN_BAG ->
                    {?ok, Player#player{bag = Container2}};
                ?CONST_GOODS_CTN_DEPOT ->
                    {?ok, Player#player{depot = Container2}};
                ?CONST_GOODS_CTN_BAG_TEMP ->
                    {?ok, Player#player{temp_bag = Container2}}
            end;
        {?error, ErrorCode} ->
            Packet  = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, Packet),
            ?error
    end;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 扩充容器
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
handler(?MSG_ID_GOODS_CS_ENLARGE_CTN, Player, {?CONST_GOODS_CTN_BAG}) ->
        case ctn_bag2_api:enlarge_container(Player#player.user_id, Player#player.bag) of
            {?ok, NewBag, Packet} ->
                misc_packet:send(Player#player.net_pid, Packet), 
                Player2 = Player#player{bag = NewBag},
                achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_EXTEND_BAG, 0, 1);
            {?error, _ErrorCode} ->
                ?error
        end;
handler(?MSG_ID_GOODS_CS_ENLARGE_CTN, Player, {?CONST_GOODS_CTN_DEPOT}) ->
        case ctn_depot_api:enlarge_container(Player#player.user_id, Player#player.depot) of
            {?ok, NewDepot, Packet} ->
                misc_packet:send(Player#player.net_pid, Packet), 
                Player2 = Player#player{depot = NewDepot},
                achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_EXTEND_DEPOT, 0, 1);
            {?error, _ErrorCode} ->
                ?error
        end;

%% 物品使用
handler(?MSG_ID_GOODS_CS_USE, Player, {Idx,Count}) ->
	case goods_mod:use(Player, Idx, Count) of
		{?ok, Player2,_Res,Packet} ->
			misc_packet:send(Player2#player.net_pid, Packet),
			{?ok, Player2};
		{?error, _ErrorCode, Player3, Packet} ->
            misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player3}
	end;
%% 穿装备
handler(?MSG_ID_GOODS_CS_EQUIP_ON, Player, {PartnerId,Idx}) ->
	case ctn_equip_api:equip_on(Player, PartnerId, Idx) of
		{?ok, Player2, EquipIdx, Packet} ->
            schedule_power_api:packet_send(packet_equip_horse, Player2, EquipIdx, PartnerId),
            misc_packet:send(Player2#player.user_id, Packet),
			{?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;
%% 脱装备
handler(?MSG_ID_GOODS_CS_EQUIP_OFF, Player, {PartnerId,Idx}) ->
	case ctn_equip_api:equip_off(Player, PartnerId, Idx) of
		{?ok, Player2, Packet} ->
            schedule_power_api:packet_send(packet_equip_horse, Player2, Idx, PartnerId),
            misc_packet:send(Player2#player.user_id, Packet),
			{?ok, Player2};
		{?error, _ErrorCode} ->
			?error
	end;

%% 临时背包道具过期判定请求
handler(?MSG_ID_GOODS_CS_OVER_TIME, Player, {Idx}) ->
    {?ok, NewBag}	= ctn_bag2_api:check_over_time(Player#player.user_id, Player#player.bag, Idx),
    NewPlayer		= Player#player{bag = NewBag},
    {?ok, NewPlayer};

%% %% 隐藏装备
%% handler(?MSG_ID_GOODS_CS_HIDE_EQUIP, Player, {_Type,_Flag}) ->
%% 	{?ok, Player};


handler(?MSG_ID_TENCENT_DEPOSIT,Player,{Money,Pfkey,Url}) ->
    case mod_tencent:client_deposit(Player, Money,Pfkey,Url) of
        {?ok, Player2, Packet} ->
            misc_packet:send(Player2#player.user_id, Packet),
            {?ok, Player2};
        {?error, _ErrorCode} ->
            ?error
    end;


handler(?MSG_ID_TENCENT_INFO_REQUEST,Player,_) ->
    mod_tencent:client_get_tencent_info(Player),
    {?ok, Player};

handler(?MSG_ID_TENCENT_PACK_GET,Player,{Type}) ->
    Player2 = mod_tencent:get_packet(Player,Type),
    {?ok, Player2};


handler(?MSG_ID_ROBOT_LVUP_REQUEST,Player,{}) ->
    Player2 = mod_tencent:robot_lv_up(Player),
    {?ok, Player2};


handler(?MSG_ID_TENCENT_INVITE,Player,{InviteOpenID}) ->
    mod_tencent:mark_invite(Player,InviteOpenID),
    Player2 = mod_tencent:check_invite(Player),
    mod_tencent:send_invite_info(Player2),
    {?ok, Player2};

handler(?MSG_ID_TENCENT_INVITE_AWARD,Player,{Type}) ->
    Player2 = mod_tencent:take_invite_award(Player,Type),
    {?ok,Player2};


handler(MsgId,Player,Datas) ->
    ?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
    ?error.
%%
%% Local Functions
%%
