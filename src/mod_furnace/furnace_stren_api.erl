
%% Description: 作坊强化接口
-module(furnace_stren_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([read_cost/2, equip_strengthen/4, list_stren/1, can_stren/1, get_stren_lv/2, vip/1]).

%%
%% API Functions
%%
%% VIP自动开启第二个强化队列
vip(Player = #player{info = Info, furnace = Furnace}) when is_record(Info, info) ->
	Vip			= player_api:get_vip_lv(Info),
	Queues		= Furnace#furnace_data.queues,
	QueueCount	= player_vip_api:get_furnace_queues(Vip),
	{
	 QueuesFlag, Queues2
	}			= furnace_queue_api:refresh_queue(QueueCount, Queues),
	Furnace2 	= Furnace#furnace_data{queues_flag = QueuesFlag, queues = Queues2},
    Player#player{furnace = Furnace2}.


%% 			Packet = furnace_queue_api:list_queue(?CONST_FURNACE_TYPE_CREATE, Furnace2),
%% 			misc_packet:send(Player#player.user_id, Packet),

%% 读取强化花费
read_cost(Lv, Idx) ->
    data_furnace:get_furnace_strengthen_cost({Lv, Idx}).

%% 部位强化
%% Idx = 装备栏位置，装备的subtype
equip_strengthen(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER = CtnType, PartnerId, Idx) ->
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    try
        {?ok, Cost, Queue} = check_equip_strengthen(Player, CtnType, PartnerId, Idx),
        case Queue of
            ?null -> % 无cd
                ?ok = minus_money(UserId, Cost),
                {?ok, NewEquipList, NewStrLv} = str_part(CtnType, UserId, PartnerId, EquipList, Idx),
                
                PacketLv = furnace_api:msg_stren_part_return(UserId, Idx, NewStrLv),
                PacketOk = message_api:msg_notice(?TIP_FURNACE_STREN_OK),
                misc_packet:send(UserId, <<PacketLv/binary, PacketOk/binary>>),
                
                Player2 = Player#player{equip = NewEquipList},
                
                {_, Player3}                 = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_ONEKEY_STRENGTHEN, 0, 1),
                {?ok, Player4}				 = new_serv_api:finish_achieve(Player3, ?CONST_NEW_SERV_STRENGTH, NewStrLv, 1),
				Player5                      = furnace_mod:refresh_attr_equip(Player4, CtnType, PartnerId),
                {?ok, Player6}               = task_api:update_furnace_stren(Player5, NewStrLv),
                admin_log_api:log_stren(Player6, Idx, NewStrLv-1, NewStrLv),
                admin_log_api:log_furnace(Player6, ?CONST_LOG_FUN_FURNACE_STREN, ?CONST_SYS_GOLD_BIND, Cost, Idx, Idx),    %钱的消耗，统一在钱那里记录日志
                {?ok, Player6};
            Queue ->
				?ok = minus_money(UserId, Cost),
                FurnaceData                   = Player#player.furnace,
				Vip							  = player_api:get_vip_lv(Player),
				IsFurCd						  = player_vip_api:is_furnace_no_cd(Vip),
                {FurnaceData2, _NewDeadLine}  = furnace_queue_api:push_queue(IsFurCd, Queue, FurnaceData),
                {?ok, NewEquipList, NewStrLv} = str_part(CtnType, UserId, PartnerId, EquipList, Idx),
                _QueueId     = Queue#furnace_cd.id,
%%                 PacketQueue = furnace_api:msg_stren_queue_return(QueueId, NewDeadLine, 
%%                                                      ?CONST_FURNACE_TYPE_UPDATE, 
%%                                                      ?CONST_SYS_TRUE),
                PacketLv = furnace_api:msg_stren_part_return(UserId, Idx, NewStrLv),
				
				ColorModules = 
					case furnace_soul_api:get_equip_info(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, 0, Idx) of
						Equip when is_record(Equip, goods) ->
							ctn_equip_api:select_color_modules(Equip#goods.color, Equip#goods.lv);
						_Other ->
							ctn_equip_api:select_color_modules(?CONST_SYS_COLOR_GREEN, 1)
					end,
				
				RecStrengthen 	= furnace_stren_api:get_stren_lv(Idx, (Player#player.info)#info.pro),
				Datas = 
					case is_record(RecStrengthen, rec_furnace_strengthen) of
						?true ->
							List	= RecStrengthen#rec_furnace_strengthen.list,
							lists:map(fun({Type, Value}) -> {Type, (Value * ColorModules div 10000)} end, List);
						?false ->
							case furnace_stren_api:get_stren_lv(Idx, 0) of
								RecStrengthen2 when is_record(RecStrengthen2, rec_furnace_strengthen) ->
									List2	= RecStrengthen2#rec_furnace_strengthen.list,
									lists:map(fun({Type2, Value2}) -> {Type2, (Value2 * ColorModules div 10000)} end, List2);
								_ ->
									[]
							end
					end,
				?MSG_DEBUG("Datas ~p", [Datas]),	
				PacketOk = furnace_api:msg_stren_value_update(Datas),
%%                 PacketOk = message_api:msg_notice(?TIP_FURNACE_STREN_OK),
%%                 misc_packet:send(UserId, <<PacketQueue/binary, PacketLv/binary, PacketOk/binary>>),
                misc_packet:send(UserId, <<PacketLv/binary, PacketOk/binary>>),
                
                Player2 = Player#player{equip = NewEquipList, furnace = FurnaceData2},
                {_, Player3}                 = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_ONEKEY_STRENGTHEN, 0, 1),
                {?ok, Player4}				 = new_serv_api:finish_achieve(Player3, ?CONST_NEW_SERV_STRENGTH, NewStrLv, 1),
				Player5                      = furnace_mod:refresh_attr_equip(Player4, CtnType, PartnerId),
                {?ok, Player6}               = task_api:update_furnace_stren(Player5, NewStrLv),
                admin_log_api:log_stren(Player6, Idx, NewStrLv-1, NewStrLv),
                admin_log_api:log_furnace(Player6, ?CONST_LOG_FUN_FURNACE_STREN, ?CONST_SYS_GOLD_BIND, Cost, Idx, Idx),
                {?ok, Player6}
        end
    catch
        throw:{?error, ErrorCode} ->
            case ErrorCode of
				?TIP_COMMON_BIND_GOLD_NOT_ENOUGH ->
					?error;
				Other when is_number(Other) ->
					PacketErr = message_api:msg_notice(ErrorCode),
		            misc_packet:send(UserId, PacketErr),
		            ?error;
				Other2 ->
					?MSG_ERROR("that's weird ~p", [Other2]),
					?error
			end;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", 
                       [Type, Why, ErrorStack]),
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            PacketErr = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, PacketErr),
            ?error
    end.

%% 扣钱
minus_money(UserId, Cost) ->
    case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_FURNACE_STREN_PART) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 装备强化检查
%% 1.读取队列与cd
%% 2.返回队列信息
check_equip_strengthen(Player, CtnType, PartnerId, Idx) ->
    % 1
    FurnaceData 	= Player#player.furnace,
    Result 			= 
        case FurnaceData#furnace_data.queues_flag of
            ?CONST_SYS_TRUE -> ?CONST_SYS_TRUE;
            _ ->
                case furnace_queue_api:get_free_queue(FurnaceData) of
                    FreeQueue when is_record(FreeQueue, furnace_cd) ->
                        FreeQueue;
                    _ -> ?CONST_SYS_FALSE
                end
        end,
    % 2
    EquipList 	= Player#player.equip,
    UserId 		= Player#player.user_id,
    Info 		= Player#player.info,
    {?ok, StrLv}    = ctn_equip_api:get_part_info(CtnType, UserId, PartnerId, EquipList, Idx),
    case Result of
		_Queue when StrLv >= ?CONST_SYS_PLAYER_LV_MAX ->
			throw({?error, ?TIP_FURNACE_STREN_LV_MAX});
        Queue when is_record(Queue, furnace_cd) andalso StrLv < Info#info.lv -> % 有队列
            NewStrLv    = StrLv + 1,
            Cost        = read_cost(NewStrLv, Idx),
            {?ok, Cost, Queue};
        Queue when is_record(Queue, furnace_cd) -> 						% 有队列,强化等级>=人物等级
            throw({?error, ?TIP_FURNACE_STREN_LV_LIMIT});
        ?CONST_SYS_TRUE when StrLv < Info#info.lv -> 					% 无cd
            NewStrLv    = StrLv + 1,
            Cost        = read_cost(NewStrLv, Idx),
            {?ok, Cost, ?null};
        ?CONST_SYS_TRUE -> 												% 等级不够,强化等级>=人物等级	
            throw({?error, ?TIP_FURNACE_STREN_LV_LIMIT});
        ?CONST_SYS_FALSE -> 											% cd中
            throw({?error, ?TIP_FURNACE_IN_CD_TIME})
    end.

%% 强化部位
str_part(?CONST_GOODS_CTN_EQUIP_PLAYER = CtnType, UserId, _PartnerId, EquipList, Idx) ->
    case lists:keytake({UserId, CtnType}, 1, EquipList) of
        {value, {_Key, Equip}, _EquipList2} ->
            Ext = Equip#ctn.ext,
            StrLv = erlang:element(Idx, Ext),
            NewStrLv = StrLv + 1,
            NewExt = erlang:setelement(Idx, Ext, NewStrLv),
			NewEquipList = str_all_part(EquipList, NewExt, []), %人物/武将的CTN EXT都更新
            {?ok, NewEquipList, NewStrLv};
        ?false ->
            throw({?error, ?TIP_COMMON_BAD_ARG})
    end.

str_all_part([], _Ext, Acc) ->
	lists:reverse(Acc);
str_all_part([{Key, Equip}|T], Ext, Acc) ->
	Equip2 = Equip#ctn{ext = Ext},
	Acc2 = [{Key, Equip2}|Acc],
	str_all_part(T, Ext, Acc2).

%% 列出玩家强化信息
list_stren(Player) ->
    EquipList = Player#player.equip,
    UserId = Player#player.user_id,
    F = fun({{Id, _Type}, Equip}, OldPacket) when Id =:= UserId ->
                P = furnace_api:msg_get_user_stren_return(UserId, Equip),
                <<OldPacket/binary, P/binary>>;
           ({{_PartnerId, _Type}, _Equip}, OldPacket) ->	%去掉武将强化信息
				<<OldPacket/binary>>
        end,
    lists:foldl(F, <<>>, EquipList).

get_stren_lv(SubType, Pro) ->
	data_furnace:get_furnace_strengthen({SubType, Pro}).

%% 能强化的部位?
can_stren(?CONST_GOODS_EQUIP_WEAPON) -> % 1
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_ARMOR) -> % 2
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_HELMET) -> % 3
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_BOOTS) -> % 4
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_CLOAK) -> % 5
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_BELT) -> % 6
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_NECKLACE) -> % 7
    ?CONST_SYS_TRUE;
can_stren(?CONST_GOODS_EQUIP_RING) -> % 8
    ?CONST_SYS_TRUE;
can_stren(_SubType) ->
    ?CONST_SYS_FALSE.
    