
%% 道具模块
%% 主要包括检查与使用
-module(goods_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.task.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").

%%
%% Exported Functions
%%
-export([use/3, use_by_id/3, use_by_type/4, pack_dirty/2, use_box_in_batch/7]).

%%
%% API Functions
%%
%% 物品使用
use(Player, [Goods|Tail], GoodsUsedList, Packet) ->
    case use(Player, Goods#mini_goods.idx, Goods#mini_goods.count) of
        {?ok,NewPlayer, Res,Packet2} ->
            use(NewPlayer, Tail, GoodsUsedList++Res, <<Packet/binary, Packet2/binary>>);
        {?error, ErrorCode, Player2} ->
            {?error, ErrorCode, Player2}
    end;
use(Player, [], GoodsUsedList, Packet) ->
    {?ok, Player, GoodsUsedList, Packet}.

use(Player, Idx, Count) ->
    Bag = ctn_bag2_api:get_bag(Player),
    case ctn_bag2_api:read(Bag, Idx) of
        {?ok, Goods} when is_record(Goods, goods) ->
            MiniGoods = goods_api:goods_to_mini(Goods),
            case check(Player, MiniGoods, Count) of
                ?ok ->
                    Goods = goods_api:mini_to_goods(MiniGoods),
                    Type        = Goods#goods.type,
                    SubType     = Goods#goods.sub_type,
                    case is_directory_use(Type, SubType) of
                        ?true ->
                            use_multi(Player, MiniGoods, Count, Type, SubType, []);
                        ?false ->
                            PacketMsg = message_api:msg_notice(?TIP_GOODS_NOT_DIRECT_USE),
                            {?error, ?TIP_GOODS_NOT_DIRECT_USE, Player, PacketMsg}
                    end;
                {?error, ErrorCode} ->
                    PacketMsg = message_api:msg_notice(ErrorCode),
                    {?error, ErrorCode, Player, PacketMsg}
            end;
        _ ->% 物品不存在
            PacketMsg = message_api:msg_notice(?TIP_GOODS_NOT_EXIST),
            {?error, ?TIP_GOODS_NOT_EXIST, Player, PacketMsg}
    end.

%% 从背包使用道具时过滤
%% ?true 能用
%% ?false 不能直接用,要打开界面
is_directory_use(?CONST_GOODS_TYPE_EQUIP, _SubType)         -> ?false;
is_directory_use(?CONST_GOODS_360CARD, _SubType)         -> ?true;
is_directory_use(?CONST_GOODS_TYPE_EGG, _SubType)           -> ?true;
is_directory_use(?CONST_GOODS_TYPE_SKILL_BOOK, ?CONST_GOODS_BOOK_HORSE) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_SKILL_BOOK, _SubType)    -> ?false;
is_directory_use(?CONST_GOODS_TYPE_SUPPLY, ?CONST_GOODS_FUNC_OTHER)        -> ?false;
is_directory_use(?CONST_GOODS_TYPE_SUPPLY, _SubType)        -> ?true;
is_directory_use(?CONST_GOODS_TYPE_BOX, _SubType)           -> ?true;
is_directory_use(?CONST_GOODS_TYPE_PACKAGE, _SubType)       -> ?false;
is_directory_use(?CONST_GOODS_TYPE_TASK, _SubType)          -> ?true;
is_directory_use(?CONST_GOODS_TYPE_BUFF, _SubType)          -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_HORSE_FOOD) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_HUANHUAKA) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_MIND) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_PARTNER) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_DMT) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_SDK) -> ?true;
is_directory_use(?CONST_GOODS_TYPE_FUNC, _SubType)          -> ?false;
is_directory_use(_, _SubType)                               -> ?false.

%% {?ok,NewPlayer,Res,Packet}/{?error, ErrorCode, Player}
use_by_type(Player, Type, SubType, Count) ->
    Bag = Player#player.bag,
    GoodsList = ctn_bag2_api:get_by_type(Bag, Type, SubType),
    Len = erlang:length(GoodsList),
    if
        Len < Count ->
            {?error, ?TIP_COMMON_GOOD_NOT_ENOUGH, Player};
        ?true ->
            case use(Player, GoodsList, [], <<>>) of
                {?ok,NewPlayer,Res,Packet} ->
                    {?ok,NewPlayer,Res,Packet};
                {?error, ErrorCode, Player2} ->
                    {?error, ErrorCode, Player2}
            end
    end.

%% 物品使用
%% goods_mod:use_by_id(Player,GoodsId, Count).
%% arg :    Player,     玩家信息
%%          GoodsId,    物品id
%%          Count       使用数量
%% return : {?ok,NewPlayer,Res,Packet} | {?error, ErrorCode, Player}
use_by_id(Player,GoodsId, _Count) ->
    case ctn_bag2_api:get_by_id_not_send(Player#player.user_id, Player#player.bag, GoodsId, 1) of
        {?ok, _Bag2, [Goods1], PacketBagTemp} ->
            case check(Player, Goods1, 1) of
                ?ok ->
                    Goods = goods_api:mini_to_goods(Goods1),

                    Type        = Goods#goods.type,
                    SubType     = Goods#goods.sub_type,
                    MiniGoods   = goods_api:goods_to_mini(Goods),
                    case use_multi(Player, MiniGoods, 1, Type, SubType, []) of % 用旧的那个背包
                        {?ok,NewPlayer,Res,Packet} ->
                            {?ok,NewPlayer,Res, <<Packet/binary, PacketBagTemp/binary>>};
                        {?error, ErrorCode, Player2, PacketBag} ->
                            {?error, ErrorCode, Player2, <<PacketBag/binary, PacketBagTemp/binary>>}
                    end;
                {?error, ErrorCode} ->
                    Packet = message_api:msg_notice(ErrorCode),
                    {?error, ErrorCode, Player, Packet}
            end;
        _ ->
            {?error, ?TIP_GOODS_NOT_EXIST, Player}
    end.

use_multi(Player, MiniGoods, Count, Type, SubType, Dirty) when Count > 0 ->
    case use(Player, MiniGoods, 1, Type, SubType, Count, Dirty) of
        {?ok, NewPlayer, _Res, Dirty2} ->
            use_multi(NewPlayer, MiniGoods, Count-1, Type, SubType, Dirty2);
        {?error, ?TIP_GOODS_USE_ALREADY_MAX} -> %% 使用补给品的提示
            Packet = pack_dirty(Player, Dirty),
            PacketErr = message_api:msg_notice(?TIP_GOODS_USE_ALREADY_MAX, [{?TIP_SYS_GOODS_SUPPLY, misc:to_list(SubType)}]),
            {?error, ?TIP_GOODS_USE_ALREADY_MAX, Player, <<Packet/binary, PacketErr/binary>>};
        {?error, ErrorCode} ->
            Packet = pack_dirty(Player, Dirty),
            PacketErr = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, Player, <<Packet/binary, PacketErr/binary>>}
    end;
use_multi(Player, _Goods, _Count, _Type, _SubType, Dirty) ->
    GoodsPacket = pack_dirty(Player, Dirty),
    {?ok, Player, [], GoodsPacket}.

pack_dirty(Player, Dirty) ->
    UserId = Player#player.user_id,
    Bag = Player#player.bag,
    GoodsList = Bag#ctn.goods,
    pack_dirty(UserId, GoodsList, Dirty, <<>>).

pack_dirty(UserId, GoodsList, [{Idx, IsNew}|Tail], OldPacket)  ->
    Goods = erlang:element(Idx, GoodsList),
    GoodsPacket = 
        case Goods of
            0 ->
                goods_api:msg_goods_sc_goods_remove(?CONST_GOODS_CTN_BAG, UserId, Idx);
            Goods ->
                Packet  = goods_api:msg_goods_list_info(?CONST_GOODS_CTN_BAG, UserId, 0, [Goods], IsNew),
                Packet2 = <<>>,
%%                        case IsNew of
%%                            ?CONST_SYS_TRUE -> ctn_bag2_api:msg_reward_get_goods([Goods]);
%%                            _ -> <<>>
%%                        end,
                <<Packet/binary, Packet2/binary>>
        end,
    NewPacket = <<OldPacket/binary, GoodsPacket/binary>>,
    pack_dirty(UserId, GoodsList, Tail, NewPacket);
pack_dirty(_UserId, _GoodsList, [], Packet) ->
    Packet.
    
%% 物品使用
%% goods_mod:use(Player, Goods, Count, Type, SubType).
%% arg : Player, Goods, Count, Type, SubType
%% return : {?ok,NewPlayer,Res,Packet} | {?error, ErrorCode}
use(_Player, _Goods, _Count, ?CONST_GOODS_TYPE_EQUIP, _SubType, _CountNum, _DirtyList) -> % 装备
    {?error,?TIP_GOODS_NOT_DIRECT_USE};
use(Player, Goods, Count, ?CONST_GOODS_TYPE_BOX, _SubType, _CountNum, DirtyList) -> % 宝箱
    UserId = Player#player.user_id,
    Lv     = (Player#player.info)#info.lv,
    Bag    = ctn_bag2_api:get_bag(Player),
    case use_box(UserId, Bag, Lv, Goods, Count, DirtyList, []) of
        {?ok, Bag2, DirtyList2, DropList} ->
			%% 在这提示获得多少个物品
    		Packet = ctn_bag2_api:msg_reward_get_goods(DropList),
    		misc_packet:send(UserId, Packet),
            Player2 = ctn_bag2_api:set_bag(Player, Bag2),
            {?ok, Player2, [], DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
use(Player, Goods, Count, ?CONST_GOODS_TYPE_BUFF, _SubType, _CountNum, DirtyList) -> % 临时属性符
    % 扣物品
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, Goods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            case buff_api:insert_buff(Player, Goods) of
                {?ok, Player2} ->
                    admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, Goods#mini_goods.goods_id, Count, misc:seconds()),
                    Player3 = ctn_bag2_api:set_bag(Player2, Bag2),
                    {?ok, Player3, [], DirtyList2};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
use(_Player, _MiniGoods, _Count, ?CONST_GOODS_TYPE_EGG, ?CONST_GOODS_PET_EGG, _CountNum, _DirtyList) -> % 蛋
    {?error,?TIP_GOODS_NOT_DIRECT_USE};
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_EGG, ?CONST_GOODS_PET_HORSE, _CountNum, DirtyList) -> % 小马驹
    Bag     = Player#player.bag,
    case ctn_bag2_api:get_by_idx_dirty(Bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            Exts    = MiniGoods#mini_goods.exts,
            Goods   = goods_api:mini_to_goods(MiniGoods),
            Color   = Goods#goods.color,
            GoodsId = Goods#goods.goods_id,
            Bind    = Goods#goods.bind, 
            Player2 = Player#player{bag = Bag2},
            admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
            case horse_api:use_goods(Player2, GoodsId, Color, Bind, Exts#g_egg.target_id, Exts#g_egg.exp) of
                {?ok, NewPlayer} ->
                    {?ok, NewPlayer, [], DirtyList2};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
%% use(_Player, _Goods, _Count, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_HORSE_FOOD, _CountNum, _DirtyList) -> % 精良草料
%%  {?error,?TIP_GOODS_NOT_DIRECT_USE}; 
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_HUANHUAKA, _CountNum, DirtyList) -> % 功能性物品
    ?MSG_ERROR("1", []),
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            ?MSG_ERROR("1", []),
            Player2 = ctn_bag2_api:set_bag(Player, Bag2),
            Ext = MiniGoods#mini_goods.exts,
            StyleData = Player2#player.style,
            StyleBag = StyleData#style_data.bag,
            Effect_Time = 
                case Ext#g_func.effect_time of
                    0 ->  % 0 表示永久激活的幻化
                        0;
                    ET ->
                        ET+misc:seconds()
                end,
            {Packet, StyleBag2} = goods_style_api:add_style(Player2, StyleBag, Ext#g_func.effect_id, Effect_Time, ?CONST_GOODS_EQUIP_HORSE),
            StyleData2 = StyleData#style_data{bag = StyleBag2},
            Player3= Player2#player{style = StyleData2},
            ?MSG_ERROR("1", []),
            Player4 =
                case goods_style_api:is_exist_style(StyleData2, Ext#g_func.effect_id, ?CONST_GOODS_EQUIP_HORSE) of
                    ?true ->
                        Player3T = goods_style_api:change_skin_style(Player3, Ext#g_func.effect_id, ?CONST_GOODS_EQUIP_HORSE),
                        map_api:change_skin_ride(Player3T),
                        Player3T;
                    ?false ->
                        Player3
                end,
            ?MSG_ERROR("1", []),
            TipPacket = message_api:msg_notice(?TIP_GOODS_USE_OK),
            misc_packet:send(Player#player.user_id, <<Packet/binary, TipPacket/binary>>),
            {?ok, Player4, [], DirtyList2};
        {?error, ErrorCode} ->
            ?MSG_ERROR("1", []),
            {?error, ErrorCode}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_MIND, _CountNum, DirtyList) -> % 星斗卡
    MindBag = mind_mod:get_bag_mind(Player),
    case mind_api:check_bag(MindBag) of
        ?true ->
            case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
                {?ok, Bag2, DirtyList2} ->
                    Player2 = ctn_bag2_api:set_bag(Player, Bag2),
                    Ext = MiniGoods#mini_goods.exts,
                    MindId = Ext#g_func.effect_id,
                    
                    {NewMindBag, _BagPos} = mind_mod:bag_add(MindBag, MindId),
                    NewPlayer       = mind_mod:update_mind_bag(Player2, NewMindBag),
        
                    TipPacket = message_api:msg_notice(?TIP_GOODS_USE_OK),
                    misc_packet:send(Player#player.user_id, TipPacket),
                    {?ok, NewPlayer, [], DirtyList2};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        ?false ->
            {?error, ?TIP_MIND_BAG_CEIL_NOT_ENOUGH}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_PARTNER, _CountNum, DirtyList) -> % 武将卡
    Ext = MiniGoods#mini_goods.exts,
    case partner_api:is_partner_exist(Player, Ext#g_func.effect_id) of 
    ?false ->
        % 扣武将卡
        case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
            {?ok, Bag2, DirtyList2} ->
                Player2 = ctn_bag2_api:set_bag(Player, Bag2),
                admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
                case partner_api:give_partner_list(Player2, [Ext#g_func.effect_id],?CONST_PARTNER_TEAM_IN) of
                    {?error, ErrorCode} ->
                        {?error, ErrorCode};
                    Player3 ->
                        {?ok, Player3, [], DirtyList2}
                end;
            {?error, ErrorCode} ->
                {?error, ErrorCode}
        end;
    ?true ->
        TipPacket   = message_api:msg_notice(?TIP_PARTNER_ALREADY_RECRUIT),
        misc_packet:send(Player#player.net_pid, TipPacket),        
        {?error, ?TIP_PARTNER_ALREADY_RECRUIT}
    end;

%% 灯谜帖
use(Player, MiniGoods, 1, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_DMT, _CountNum, DirtyList) ->
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, 1, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            Player2 = ctn_bag2_api:set_bag(Player, Bag2),
            admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, 
									?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, 
									1, misc:seconds()),
			spirit_festival_activity_api:start_riddle(Player#player.net_pid),
            {?ok, Player2, [], DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
%% 神刀卡
use(#player{user_id = UserId} = Player, MiniGoods, 1, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_SDK, _CountNum, DirtyList) ->
	Ext = MiniGoods#mini_goods.exts,
	case yunying_activity_mod:add_card_exchange_partner_by_goods(Player, Ext#g_func.effect_id) of
		?ok ->
			case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, 1, DirtyList) of
				{?ok, Bag2, DirtyList2} ->
					Player2 = ctn_bag2_api:set_bag(Player, Bag2),
					admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, 
											?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, 1, misc:seconds()),
					TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_GET_GOODS, [],[MiniGoods],[]),
					misc_packet:send(Player#player.user_id, TipPacket),
					{?ok, Player2, [], DirtyList2};
				{?error, ErrorCode} ->
					message_api:send_msg(UserId, ErrorCode),
					{?error, ErrorCode}
			end;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end;
use(_Player, _Goods, _Count, ?CONST_GOODS_TYPE_FUNC, ?CONST_GOODS_FUNC_DMT, _CountNum, _DirtyList) ->
	{?error, ?TIP_GOODS_NOT_MULTI_USE};

use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_FUNC, _SubType, _CountNum, DirtyList) -> % 功能性物品
    ?MSG_ERROR("1[~p]", [MiniGoods#mini_goods.idx]),
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            ?MSG_ERROR("1", []),
            Player2 = ctn_bag2_api:set_bag(Player, Bag2),
            admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
            {?ok, Player2, [], DirtyList2};
        {?error, ErrorCode} ->
            ?MSG_ERROR("1", []),
            {?error, ErrorCode}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_PACKAGE, _SubType, _CountNum, DirtyList) ->
    % 获取掉落物品列表
    UserId = Player#player.user_id,
    Goods = goods_api:mini_to_goods(MiniGoods),
    GoodsDropList = goods_api:goods_drop(Goods#goods.goods_id),
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            case ctn_bag2_api:set_stack_list_dirty(UserId, Bag2, GoodsDropList, ?CONST_COST_GOODS_USED, DirtyList2) of
                {?ok, Bag3, DirtyList3} ->
                    Player2 = ctn_bag2_api:set_bag(Player, Bag3),
                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, Goods#goods.goods_id, Count, misc:seconds()),
                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_GOODS_PACKET_GET, GoodsDropList, misc:seconds()),
                    {?ok, Player2, [], DirtyList3};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_SKILL_BOOK, ?CONST_GOODS_BOOK_HORSE, _CountNum, DirtyList) -> % 坐骑技能书
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            Player2 = Player#player{bag = Bag2},
            Goods = goods_api:mini_to_goods(MiniGoods),
            case horse_skill_api:learn(Player2, Goods) of
                {?ok, Player3} ->
                    admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
                    {?ok, Player3, [], DirtyList2};
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_SKILL_BOOK, _SubType, _CountNum, DirtyList) -> % 技能书
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            Player2 = Player#player{bag = Bag2},
            admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
            {?ok, Player2, [], DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_SUPPLY, _SubType, CountNum, DirtyList) -> % 供给品
%%     ?MSG_DEBUG("use supply  ~p~n",[{  MiniGoods, Count, ?CONST_GOODS_TYPE_SUPPLY, _SubType, CountNum, DirtyList}]),
    case use_goods_supply_check(Player, MiniGoods, Count) of
        ?true ->
            case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
                {?ok, Bag2, DirtyList2} ->
                    {_, Player2} = use_goods_supply(Player, MiniGoods, Count, CountNum),
                    if
                        1040907040 =:= MiniGoods#mini_goods.goods_id ->
                            map_api:broadcast_show(Player, ?CONST_MAP_SHOW_TYPE_FIREWORKS),
                            CakePacket = message_api:msg_notice(?TIP_GOODS_MOON_CAKE, [{Player#player.user_id,(Player#player.info)#info.user_name}],
                                                                [], []),
                            misc_app:broadcast_world_2(CakePacket);
                        ?true ->
                            ?ok
                    end,
                    admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
                    {?ok, Player2#player{bag = Bag2}, [], DirtyList2};
                {?error, ErrorCode} ->
                    TipPacket   = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
                    misc_packet:send(Player#player.net_pid, TipPacket),
                    {?error, ErrorCode}
            end;
        ?false when MiniGoods#mini_goods.goods_id =:= 1040907041 ->
            {?error, ?TIP_WEAPON_CHESS_HAVE_PUT_TIMES};
        {?false, ErrorCode} ->
            {?error, ErrorCode};
        _ ->
            {?error, ?TIP_GOODS_USE_ALREADY_MAX}
    end;
use(Player, MiniGoods, Count, ?CONST_GOODS_TYPE_TASK, _SubType, _CountNum, DirtyList) -> % 任务物品
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            Ext = MiniGoods#mini_goods.exts,
            TaskId = Ext#g_task.task_id,
            Task = task_api:read_task(TaskId),
            Task2 = Task#task{state = ?CONST_TASK_STATE_ACCEPTABLE},
            Player2 = Player#player{bag = Bag2},
            Player3 = task_api:add_acceptable(Player2, Task2),
            {?ok, Player4} = task_api:accept(Player3, TaskId),
            admin_log_api:log_goods(Player4#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
            {?ok,Player4, [], DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode} 
    end;

use(Player, MiniGoods, Count, ?CONST_GOODS_360CARD, _SubType, _CountNum, DirtyList) -> % 任务物品
    case ctn_bag2_api:get_by_idx_dirty(Player#player.bag, MiniGoods#mini_goods.idx, Count, DirtyList) of
        {?ok, Bag2, DirtyList2} ->
            achievement_api:add_achievement(Player#player.user_id, ?CONST_ACHIEVEMENT_360SAFE_KEEPER, 0, 1),
            Player2 = Player#player{bag = Bag2},
            admin_log_api:log_goods(Player2#player.user_id, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, MiniGoods#mini_goods.goods_id, Count, misc:seconds()),
            {?ok,Player2, [], DirtyList2};
        {?error, ErrorCode} ->
            {?error, ErrorCode} 
    end;
use(_Player, _Goods, _Count, _Type, _SubType, _CountNum, _DirtyList) ->
    ?MSG_ERROR("1", []),
    {?error,?TIP_GOODS_NOT_DIRECT_USE}.

check(Player, MiniGoods, Count) ->
    try
        Info    = Player#player.info,
        Vip     = player_api:get_vip_lv(Info),
        Time    = misc:seconds(),
        CurMapId = map_api:get_cur_map_id(Player),
        Goods   = goods_api:mini_to_goods(MiniGoods),
        case map_api:check_goods(CurMapId, Goods#goods.goods_id) of
            ?true ->
                ?ok     = check_count(Goods#goods.count, Count),
                ?ok     = check_pro(Info#info.pro, Goods#goods.pro),
                ?ok     = check_sex(Info#info.sex, Goods#goods.sex),
                ?ok     = check_lv(Info#info.lv, Goods#goods.lv),
                ?ok     = check_time(Time, Goods#goods.start_time, Goods#goods.end_time),
                ?ok     = check_vip(Vip, Goods#goods.vip),
                ?ok     = check_country(Info#info.country, Goods#goods.country),
                ?ok;
            ?false ->
                {?error, ?TIP_GOODS_MAP_NOT_USE}
        end
    catch
        throw:Return ->
            Return;
        _:_ ->
            {?error, ?TIP_GOODS_NOT_EXIST}
    end.

%% 检查物品数量
check_count(RequestCount, Count) when 0 =< Count andalso Count =< RequestCount -> ?ok;
check_count(_RequestCount, Count) when 0 >= Count -> throw({?error, ?TIP_GOODS_COUNT_NOT_ENOUGH});
check_count(_, _) -> throw({?error, ?TIP_GOODS_COUNT_NOT_ENOUGH}).
%% 检查职业
check_pro(_Pro, ?CONST_SYS_PRO_NULL) -> ?ok;
check_pro(Pro, Pro) -> ?ok;
check_pro(_, _) -> throw({?error, ?TIP_GOODS_PRO_NOT_USE}).
%% 检查性别
check_sex(_Sex, ?CONST_SYS_SEX_NULL) -> ?ok;
check_sex(Sex, Sex) -> ?ok;
check_sex(_, _) -> throw({?error, ?TIP_GOODS_SEX_NOT_USE}).
%% 检查等级
check_lv(_Lv, 0) -> ?ok;
check_lv(Lv, RequestLv) when Lv >= RequestLv -> ?ok;
check_lv(_, _) -> throw({?error, ?TIP_GOODS_LV_NOT_USE}).
%% 检查有效期
check_time(_Time, 0, 0) -> ?ok;
check_time(Time, 0, EndTime) when Time =< EndTime -> ?ok;
check_time(Time, StartTime, 0) when Time >= StartTime -> ?ok;
check_time(Time, StartTime, EndTime) when Time >= StartTime andalso Time =< EndTime -> ?ok;
check_time(_, _, _) -> throw({?error, ?TIP_GOODS_TIME_NOT_USE}).
%% 检查VIP
check_vip(_Vip, 0) -> ?ok;
check_vip(Vip, RequestVip) when Vip >= RequestVip -> ?ok;
check_vip(_, _) -> throw({?error, ?TIP_GOODS_VIP_NOT_USE}).
%% 检查国家
check_country(_Country, 0) -> ?ok;
check_country(Country, Country) -> ?ok;
check_country(_, _) -> throw({?error, ?TIP_GOODS_COUNTRY_NOT_USE}).

%% 使用补给道具
%% {?ok, Player}/{?error, Player}
use_goods_supply(Player, Goods, _Count, CountNum) ->
    GoodsId     = Goods#mini_goods.goods_id,
    RecGoods    = data_goods:get_goods(GoodsId),
    SubType     = RecGoods#goods.sub_type,
    Exts        = RecGoods#goods.exts,
    Value       = Exts#g_supply.effect_value,
    Value2      = Value * 1,
    ?MSG_DEBUG("Exts:~p~nValue:~p~nValue2:~p~n",[Exts,Value,Value2]),

    case SubType of
        ?CONST_GOODS_SUPPLY_BLOOD_BAG ->
            use_goods_blood_bag(Player, Value2);
        ?CONST_GOODS_SUPPLY_PLAYER_EXP ->
            use_goods_exp_bag(Player, Value2);
        ?CONST_GOODS_SUPPLY_SP_BAG ->
            use_goods_sp_bag(Player, Value2);
        ?CONST_GOODS_SUPPLY_GOLD ->
            use_goods_gold(Player, Value2);
        ?CONST_GOODS_SUPPLY_BCASH ->
            use_goods_bcash(Player, Value2);
        ?CONST_GOODS_SUPPLY_MERITORIOUS ->
            use_goods_meritorious(Player, Value2);
        ?CONST_GOODS_SUPPLY_EXPERIENCE ->
            use_goods_experience(Player, Value2);
        ?CONST_GOODS_SUPPLY_CASH ->
            use_goods_cash(Player, Value2, CountNum);
        ?CONST_GOODS_SUPPLY_CHESS_DICE ->
            use_goods_chess_dice(Player, Value);
        ?CONST_GOODS_SUPPLY_HUFU ->
            use_goods_hufu(Player, Value);
        ?CONST_GOODS_CASH_BIND ->
            use_goods_bind_cash(Player, Value2);
        _Other ->
            {?error, Player}
    end.
use_goods_blood_bag(Player, Value) ->
    Info        = Player#player.info,
    Hp          = Info#info.hp,
    
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    HpMax       = AttrSecond#attr_second.hp_max,
    
    if
        Hp >= HpMax ->
            {?error, Player};
        ?true ->
            player_api:hp(Player, Value)
    end.
use_goods_exp_bag(Player, Value) ->
    Info = Player#player.info,
    Exp = Info#info.exp,
    {?ok, Player2} = player_api:exp(Player, Value),
    Info2 = Player2#player.info,
    Exp2 = Info2#info.exp,
    if
        Exp =:= Exp2 ->
            {?error, Player};
        ?true ->
            {?ok, Player2}
    end.
use_goods_sp_bag(Player, Value) ->
    Info = Player#player.info,
    Sp   = Info#info.sp,
    Vip   = Info#info.vip,
    VipLv = Vip#vip.lv,
    VipLimit = player_vip_api:get_sp_limit(VipLv),
    if
        Sp >= VipLimit -> {?error, Player};
        ?true ->
            player_api:plus_sp(Player, Value, ?CONST_COST_PLAYER_USE_GOODS)
    end.
use_goods_gold(Player, Value) ->
    UserId = Player#player.user_id,
    case player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_PLAYER_USE_GOODS) of
        ?ok ->
            {?ok, Player};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, Player}
    end.
use_goods_bcash(Player, Value) ->
    UserId = Player#player.user_id,
    case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, Value, ?CONST_COST_PLAYER_USE_GOODS) of
        ?ok ->
            {?ok, Player};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, Player}
    end.
use_goods_meritorious(Player, Value) ->
    player_api:plus_meritorious(Player, Value, ?CONST_COST_PLAYER_USE_GOODS).
use_goods_experience(Player, Value) ->
    NewPlayer   = player_api:plus_experience(Player, Value),
    {?ok, NewPlayer}.
use_goods_cash(Player, Value, CountNum) ->
    PayNum      = misc:to_list(misc:seconds()) ++ misc:to_list(CountNum),
    case player_money_api:deposit_2(PayNum, "", Player#player.user_id, Value, Value, misc:seconds(), ?CONST_DEPOSIT_USE_CASH_CARD, ?CONST_COST_PLAYER_DEPOSIT) of
        ?ok -> {?ok, Player};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, Packet),
            {?error, Player}
    end.
use_goods_chess_dice(Player, Value) ->
    Weapon      = Player#player.weapon,
    PutTimes    = Weapon#weapon_data.put_times,
    NewPutTimes = PutTimes + Value,
    Weapon2     = Weapon#weapon_data{put_times = NewPutTimes},
    Player2     = Player#player{weapon = Weapon2},
    NewPutTimes = Weapon2#weapon_data.put_times,
    Cd          = Weapon2#weapon_data.cd,
    Pos         = Weapon2#weapon_data.pos,
    BuyTimes    = Weapon2#weapon_data.buy_times,
    VipLv       = player_api:get_vip_lv(Player),
    VipTimes    = player_vip_api:get_chess_buy_dice(VipLv),
    CanBuy      = misc:uint(VipTimes - BuyTimes),
    Packet      = weapon_api:msg_chess_info(NewPutTimes, Cd, Pos, CanBuy),
    misc_packet:send(Player#player.user_id, Packet),
    {?ok, Player2}.
use_goods_hufu(Player, Value) ->
    #arena_pvp_m{hufu = Hufu} = arena_pvp_api:ets_arena_pvp_m(Player#player.user_id),
    ets_api:update_element(?CONST_ETS_ARENA_PVP_M, Player#player.user_id, [{#arena_pvp_m.hufu, Hufu+Value}]),
    {?ok, Player}.
%% 发绑定元宝
use_goods_bind_cash(Player, Value) ->
    UserId = Player#player.user_id,
    case player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, Value, ?CONST_COST_PLAYER_USE_GOODS) of
        ?ok ->
            {?ok, Player};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            {?error, Player}
    end.
%% 检查补给道具是否可以使用
use_goods_supply_check(Player, MiniGoods, Count) ->
    GoodsId     = MiniGoods#mini_goods.goods_id,
    RecGoods    = data_goods:get_goods(GoodsId),
    SubType     = RecGoods#goods.sub_type,
    Exts        = RecGoods#goods.exts,
    Value       = Exts#g_supply.effect_value,
    Value2      = Value * Count,
    case SubType of
        ?CONST_GOODS_SUPPLY_BLOOD_BAG ->
            use_goods_blood_bag_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_PLAYER_EXP ->
            use_goods_exp_bag_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_SP_BAG ->
            use_goods_sp_bag_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_GOLD ->
            use_goods_gold_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_BCASH ->
            use_goods_bcash_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_MERITORIOUS ->
            use_goods_meritorious_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_EXPERIENCE ->
            use_goods_experience_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_CASH ->
            use_goods_cash_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_CHESS_DICE ->
            use_goods_chess_dice_check(Player, Value2);
        ?CONST_GOODS_SUPPLY_HUFU ->
            use_goods_hufu_check(Player, Value2);
        ?CONST_GOODS_CASH_BIND ->
            use_goods_bind_cash_check(Player, Value2);
        _Other ->
            ?false
    end.
use_goods_blood_bag_check(Player, Value) ->
    Info        = Player#player.info,
    Hp          = Info#info.hp,
    
    Attr        = Player#player.attr,
    AttrSecond  = Attr#attr.attr_second,
    HpMax       = AttrSecond#attr_second.hp_max,
    
    if
        Hp + Value > HpMax ->
            ?false;
        ?true ->
            ?true
    end.
use_goods_exp_bag_check(Player, _Value) ->
    Info = Player#player.info,
    Lv = Info#info.lv,
    Lv =< 100.
use_goods_sp_bag_check(Player, Value) ->
    Info = Player#player.info,
    Sp   = Info#info.sp,
    Vip  = Info#info.vip,
    VipLv = Vip#vip.lv,
    VipLimit = player_vip_api:get_sp_limit(VipLv),
    
    if
        Sp + Value > VipLimit ->
            ?false;
        ?true ->
            ?true
    end.
use_goods_gold_check(_Player, _Value) ->
    ?true.
use_goods_bcash_check(_Player, _Value) ->
    ?true.
use_goods_meritorious_check(_Player, _Value) ->
    ?true.
use_goods_experience_check(_Player, _Value) ->
    ?true.
use_goods_cash_check(_Player, _Value) ->
    ?true.
use_goods_chess_dice_check(Player, _Value) ->
    Weapon      = Player#player.weapon,
    PutTimes    = Weapon#weapon_data.put_times,
    if
        PutTimes > 0 -> 
            ?false;
        ?true ->
            ?true
    end.
use_goods_hufu_check(Player, _Value) ->
    case arena_pvp_api:ets_arena_pvp_m(Player#player.user_id) of
        #arena_pvp_m{} ->
            ?true;
        _ ->
            Info   = Player#player.info,
            Position = Player#player.position,
            ArenaM = #arena_pvp_m{user_id = Player#player.user_id, 
                         user_name = Info#info.user_name,
                         pro = Info#info.pro,
                         sex = Info#info.sex,
                         lv  = Info#info.lv,
                         position = Position#position_data.position},
            arena_pvp_api:insert_arena_pvp_m(ArenaM),
            ?true
    end.
use_goods_bind_cash_check(Player, _Value) ->
    ?true.

%% 一个个用
%% {?ok, Bag, DirtyList}/{?error, ErrorCode}
use_box(UserId, Bag, Lv, Goods, Count, DirtyList, DropList) when Count > 0 ->
    GoodsExt      = Goods#mini_goods.exts,
%%     GoodsDropId   = GoodsExt#g_box.goods_drop_id,
    GoodsDropId   = get_box_drop_id(GoodsExt#g_box.goods_drop_id, Lv),
    GoodsDropList = goods_api:goods_drop(GoodsDropId),
    GoodsIdx      = Goods#mini_goods.idx,
	case ctn_bag2_api:is_full(Bag) of
		true ->
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH};
		false ->
		    case ctn_bag2_api:get_by_idx_dirty(Bag, GoodsIdx, 1, DirtyList) of
		        {?ok, Bag2, DirtyList2} ->
		            case ctn_bag2_api:set_stack_list_dirty(UserId, Bag2, GoodsDropList, ?CONST_COST_GOODS_USED, DirtyList2) of
		                {?ok, Bag3, DirtyList3} -> % XXX 假设放进人物身上是成功的
		                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_GOODS_USED, Goods#mini_goods.goods_id, 1, misc:seconds()),
		                    admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, ?CONST_COST_GOODS_BOX_GET, GoodsDropList, misc:seconds()),
		                    use_box(UserId, Bag3, Lv, Goods, Count-1, DirtyList3, GoodsDropList ++ DropList);
		                {?error, ErrorCode} ->
		                    {?error, ErrorCode}
		            end;
		        {?error, ErrorCode} ->
		            {?error, ErrorCode}
		    end
	end;

use_box(_UserId, Bag, _Lv, _Goods, _Count, DirtyList, DropList) ->
    {?ok, Bag, DirtyList, DropList}.


%% 根据列表GoodsList批量使用箱子
use_box_in_batch(_UserId, Bag, _Lv, _GoodsList, 0, DirtyList, DropList) ->
	{?ok, Bag, DirtyList, DropList};
use_box_in_batch(UserId, Bag, Lv, [Goods|Tail], NeedNum, DirtyList, DropList) ->
	Count = 
		if Goods#mini_goods.count >= NeedNum ->
			   NeedNum;
		   true ->
			   Goods#mini_goods.count
		end,
	case use_multi_box(UserId, Bag, Lv, Goods, Count, DirtyList, DropList) of
		{?ok, Bag2, DirtyList2, DropList2} ->
			use_box_in_batch(UserId, Bag2, Lv, Tail, NeedNum - Count, DirtyList2, DropList2);
		{?error, ErrorCode, Bag2, DirtyList2, DropList2} ->
			{?error, ErrorCode, Bag2, DirtyList2, DropList2}
    end.

use_multi_box(UserId, Bag, Lv, Goods, Count, DirtyList, DropList) when Count > 0 ->
    case use_box(UserId, Bag, Lv, Goods, 1, DirtyList, DropList) of
		{?ok, Bag2, DirtyList2, DropList2} ->
            use_multi_box(UserId, Bag2, Lv, Goods, Count - 1, DirtyList2, DropList2);
        {?error, ErrorCode} ->
			{?error, ErrorCode, Bag, DirtyList, DropList}
    end;
use_multi_box(_UserId, Bag, _Lv, _Goods, 0, DirtyList, DropList) ->
	{?ok, Bag, DirtyList, DropList}.

%% 获取box的掉落id
get_box_drop_id(Drop, _Lv) when is_integer(Drop) ->
    Drop;
get_box_drop_id([{MinLv, MaxLv, Id}|_DropList], Lv) when Lv >= MinLv andalso Lv =< MaxLv ->
    Id;
get_box_drop_id([_Drop|DropList], Lv) ->
    get_box_drop_id(DropList, Lv);
get_box_drop_id([], Lv) ->
    ?MSG_ERROR("ERROR get box drop id:~p", [Lv]).
    
    
    