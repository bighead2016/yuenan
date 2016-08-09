
%%% 作坊 
-module(furnace_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 获取所有强化队列
handler(?MSG_ID_FURNACE_STREN_QUEUE, Player, {}) ->
    UserId = Player#player.user_id,
    FurnaceData = Player#player.furnace,
	Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_CREATE, FurnaceData),
	misc_packet:send(UserId, Packet),
	{?ok, Player};

%% 开启强化队列
handler(?MSG_ID_FURNACE_OPEN_STREN_QUEUE, Player, {}) ->
    UserId = Player#player.user_id,
    FurnaceData = Player#player.furnace,
	case furnace_queue_api:add_queue(Player, FurnaceData) of
		{?ok, NewFurnace} ->
			NewFurnace = furnace_queue_api:add_queue(Player, FurnaceData),
			Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_CREATE, NewFurnace),
			misc_packet:send(UserId, Packet),
		    NewPlayer = Player#player{furnace = NewFurnace},
			{?ok, NewPlayer};
		?error ->
			{?ok, Player}
	end;

%% 清除强化CD
handler(?MSG_ID_FURNACE_CLEAR_STREN_CD, Player, {?CONST_FURNACE_CLEAR_THIS_TIME, QueueId}) -> % 清单一的cd
    UserId = Player#player.user_id,
    FurnaceData = Player#player.furnace,
    case furnace_queue_api:clear_cd(UserId, FurnaceData, QueueId) of
        {?ok, NewFurnaceData} ->
            Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, NewFurnaceData),
            misc_packet:send(UserId, Packet),
            NewPlayer = Player#player{furnace = NewFurnaceData},
            {?ok, NewPlayer};
        {?error, _FurnaceData} ->
            {?ok, Player}
    end;
%% handler(?MSG_ID_FURNACE_CLEAR_STREN_CD, Player, {?CONST_FURNACE_CLEAR_ALL_QUEUE_THIS_TIME, _QueueId}) -> % 清全部的cd
%%     UserId = Player#player.user_id,
%%     FurnaceData = Player#player.furnace,
%%     NewFurnaceData = furnace_queue_api:clear_all_cd(FurnaceData),
%%     Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, NewFurnaceData),
%%     misc_packet:send(UserId, Packet),
%%     NewPlayer = Player#player{furnace = NewFurnaceData},
%%     {?ok, NewPlayer};
%% 永久清cd
%% handler(?MSG_ID_FURNACE_CLEAR_STREN_CD, Player, {?CONST_FURNACE_CLEAR_FOREVER, _QueueId}) -> 
%%     UserId 		= Player#player.user_id,
%%     FurnaceData = Player#player.furnace,
%%     case furnace_queue_api:set_clear_forever(Player, FurnaceData) of
%% 		{?ok, NewFurnaceData} ->
%% 		    Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, NewFurnaceData),
%% 		    misc_packet:send(UserId, Packet),
%% 		    NewPlayer = Player#player{furnace = NewFurnaceData},
%% 		    {?ok, NewPlayer};
%% 		?error ->
%% 			{?ok, Player}
%% 	end;

%% 获取角色强化信息
handler(?MSG_ID_FURNACE_GET_USER_STREN, Player, {}) ->
    UserId = Player#player.user_id,
	Packet = furnace_stren_api:list_stren(Player),
	misc_packet:send(UserId, Packet),
	{?ok, Player};

%% 装备部位强化
handler(?MSG_ID_FURNACE_STREN_PART, Player = #player{user_id = UserId}, {_Id, SubType}) ->
    case furnace_stren_api:can_stren(SubType) of
        ?CONST_SYS_TRUE ->
			case furnace_stren_api:equip_strengthen(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, 0, SubType) of
				{?ok, NewPlayer} ->
					FurnaceData 	= NewPlayer#player.furnace,
					Packet 			= furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_UPDATE, FurnaceData),
					misc_packet:send(UserId, Packet),
					{_, Player2}    = welfare_api:add_pullulation(NewPlayer, ?CONST_WELFARE_STRENGTH, 0, 1),
                    schedule_power_api:do_change_equip(Player2),
					{?ok, Player2};
				?error ->
					{?ok, Player}
			end;
        ?CONST_SYS_FALSE ->
            PacketErr = message_api:msg_notice(?TIP_FURNACE_NOT_STRENABLE),
            misc_packet:send(UserId, PacketErr),
            {?ok, Player}
    end;

%% 进行装备锻造
handler(?MSG_ID_FURNACE_EQUIP_FORGE, Player = #player{user_id = UserId}, {EquipId, Type}) ->
	{Status, Result2, NewPlayer} = furnace_forge_api:equip_forge(Player, EquipId, Type),
	Packet = furnace_api:msg_equip_forge_return(Result2, Type),
	misc_packet:send(UserId, Packet),
	{_, Player2} = welfare_api:add_pullulation(NewPlayer, ?CONST_WELFARE_EQUIP, 0, 1),
	
	case Status of
		?ok ->
			bless_api:send_be_blessed(Player2, ?CONST_RELATIONSHIP_BTYPE_EQUIP, data_goods:get_goods(EquipId));
		?error ->
			?error
	end,
	{?ok, Player2};

%% 多位置升阶
handler(?MSG_ID_FURNACE_CS_UPGRADE_MULTI, Player, {CtnType, Idx, NewEquipId, PartnerId}) ->
    UserId = Player#player.user_id,
    {Status, Result2, NewPlayer} = furnace_forge_new_api:equip_forge(Player, CtnType, Idx, NewEquipId, PartnerId),
    Packet = furnace_api:msg_sc_upgrade_multi(Result2),
    misc_packet:send(UserId, Packet),
    {_, Player2} = welfare_api:add_pullulation(NewPlayer, ?CONST_WELFARE_EQUIP, 0, 1),
    
    case Status of
        ?ok ->
            bless_api:send_be_blessed(Player2, ?CONST_RELATIONSHIP_BTYPE_EQUIP, data_goods:get_goods(NewEquipId));
        ?error ->
            ?error
    end,
    {?ok, Player2};

%% 刻印
handler(?MSG_ID_FURNACE_SOUL_CONFIRM, Player, {CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo, {_Len, SoulFromList}, {_Len2, SoulToList}}) ->
	case furnace_soul_api:equip_make_soul(Player,CtnFrom,PartnerFrom,IndexFrom,CtnTo,PartnerTo,IndexTo,SoulFromList,SoulToList) of
		{?ok, Player2} ->
			PacketNotice = message_api:msg_notice(?TIP_FURNACE_SOUL_OK),
			PacketResult = misc_packet:pack(?MSG_ID_FURNACE_SOUL_CONFIRM_RETURN, ?MSG_FORMAT_FURNACE_SOUL_CONFIRM_RETURN, [?true]),
			misc_packet:send(Player#player.net_pid, <<PacketNotice/binary, PacketResult/binary>>),
            schedule_power_api:do_change_equip(Player2),
			{?ok, Player2};
		{?error, _ErrorCode} ->
			PacketResult = misc_packet:pack(?MSG_ID_FURNACE_SOUL_CONFIRM_RETURN, ?MSG_FORMAT_FURNACE_SOUL_CONFIRM_RETURN, [?false]),
			misc_packet:send(Player#player.user_id, PacketResult),
			{?ok, Player}
	end;

%% 道具合成
handler(?MSG_ID_FURNACE_GOODS_FORGE, Player, {GoodsId}) ->
	{_, Result, NewPlayer} = furnace_forge_api:goods_forge(Player, GoodsId),
	Packet = furnace_api:msg_goods_forge_return(Result),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, NewPlayer};

%% 时装合成
handler(?MSG_ID_FURNACE_CS_FASHION_FUSION, Player, {Idx1,Idx2}) ->
    {?ok, Player2} = furnace_fusion_api:fusion(Player, Idx1, Idx2),
    {?ok, Player2};

%% 时装保存
handler(?MSG_ID_FURNACE_CS_SAVE_FASHION, Player, {EquipStyle,ClothStyle,StepStyle}) ->
    Player2 = furnace_fusion_api:save(Player, EquipStyle, ClothStyle, StepStyle),
    {?ok, Player2};

%% 请求合成宝石
handler(?MSG_ID_FURNACE_COMPOSE_STONE, Player, {Index,Count}) ->
    case furnace_soul_api:compose_soul(Player, Index, Count) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求镶嵌宝石
handler(?MSG_ID_FURNACE_ADD_STONE, Player, {CtnType,Index,PartnerId,StoneIndex}) ->
    case furnace_soul_api:add_stone(Player, CtnType, PartnerId, Index, StoneIndex) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求摘除宝石
handler(?MSG_ID_FURNACE_SUB_STONE, Player, {CtnType,Index,PartnerId,StoneIndex}) ->
    case furnace_soul_api:sub_stone(Player, CtnType, PartnerId, Index, StoneIndex) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求打孔
handler(?MSG_ID_FURNACE_ADD_HOLE, Player, {CtnType,PartnerId,Index}) ->
    case furnace_soul_api:add_hole(Player, CtnType, PartnerId, Index) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;
%% 请求转换宝石
handler(?MSG_ID_FURNACE_CHANGE_STONE, Player, {Index,Count}) ->
    case furnace_soul_api:change_stone(Player, Index, Count) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            {?ok, Player}
    end;

%% 请求宝石升级
handler(?MSG_ID_FURNACE_REQUEST_UP_STONE, Player, {CtnType,PartnerId,EquipIndex,StoneIndex}) ->
   case furnace_soul_api:up_stone(Player, CtnType, PartnerId, EquipIndex, StoneIndex) of
        {?ok, Player2} ->
            {?ok, Player2};
       _ ->
           {?ok, Player}
   end;

%% 一键合成宝石查询
handler(?MSG_ID_FURNACE_CS_OK_COM_STONE_QUERY, Player, {}) ->
	{CostGold, _} = furnace_soul_api:one_key_compose_calc(Player),
	Packet = furnace_api:msg_sc_ok_com_stone_query(CostGold),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};

%% 一键合成宝石
handler(?MSG_ID_FURNACE_SC_OK_COM_STONE, Player, {}) ->
	furnace_soul_api:one_key_compose_stone(Player);

%% 请求装备激活状态
handler(?MSG_ID_FURNACE_CS_EQUIP_STATES, Player, {Type}) ->
	Packet = furnace_chest_api:get_active_equip(Player, Type),
	misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};

%% 保存形象
handler(?MSG_ID_FURNACE_CS_SAVE_IMAGE, Player, {Weapon,Cloth}) ->
	{?ok, Player2} = furnace_chest_api:save_image(Player, Weapon, Cloth),
	{?ok, Player2};

%% 一键转移
handler(?MSG_ID_FURNACE_CS_OK_TRANSFER, Player, {Index1,CtnType2,Index2,PartnerId2}) ->
	{?ok, Player2} = furnace_soul_api:one_key_transfer(Player, Index1, CtnType2, PartnerId2, Index2),
	{?ok, Player2};

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	{?ok, Player}.
