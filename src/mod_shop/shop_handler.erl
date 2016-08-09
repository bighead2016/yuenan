%%% 道具店协议处理器
-module(shop_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.task.hrl").

%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 出售物品
handler(?MSG_ID_SHOP_CS_SELL, _Player, {0}) ->
    ?error;
handler(?MSG_ID_SHOP_CS_SELL, Player, {Idx}) ->
    case shop_api:sell(Player#player.user_id, Player#player.bag, Idx, Player#player.shop_temp_list) of
        {?ok, NewBag, NewShopTempList, Packet, _} ->
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, Player#player{bag = NewBag, shop_temp_list = NewShopTempList}};
        {?error, _ErrorCode} ->
            ?error
    end;

%% 批量卖出
handler(?MSG_ID_SHOP_CS_SELL_LIST, Player, {{_, List}}) ->
    UserId = Player#player.user_id,
    Bag    = Player#player.bag,
    ShopTempList = Player#player.shop_temp_list,
    case shop_api:sell_list(UserId, Bag, List, ShopTempList) of
        {?ok, NewBag, NewShopTempList, Packet} ->
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, Player#player{bag = NewBag, shop_temp_list = NewShopTempList}};
        {?error, _ErrorCode} ->
            PacketErr = message_api:msg_notice(?TIP_SHOP_GET_MONEY, [{100, "0"}]),
            misc_packet:send(Player#player.user_id, PacketErr),
            ?error
    end;

%% 回购物品
handler(?MSG_ID_SHOP_CS_REPURCHASE, Player, {Idx}) ->
    case shop_api:repurchase(Player, Player#player.shop_temp_list, Idx) of
        {?ok, NewPlayer, NewShopTempList, Packet} ->
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, NewPlayer#player{shop_temp_list = NewShopTempList}};
        {?error, _ErrorCode} ->
            ?error
    end;

%% 申请回购列表
handler(?MSG_ID_SHOP_CS_LIST_REPURCHASE, Player, {}) ->
    Packet = shop_api:list_repurchase(Player#player.shop_temp_list),
    misc_packet:send(Player#player.user_id, Packet),
	?ok;

%% 购买物品
handler(?MSG_ID_SHOP_CS_PURCHASE, _Player, {_GoodsId, 0}) ->
    ?ok;
handler(?MSG_ID_SHOP_CS_PURCHASE, _Player, {0, _Count}) ->
    ?ok;
handler(?MSG_ID_SHOP_CS_PURCHASE, Player, {GoodsId,Count}) ->
    RecShop = data_shop:get_shop_goods(GoodsId),
	case shop_api:check_purchage(Player, GoodsId, Count, RecShop) of
        {?error, Reason} ->
            {?error, Reason};
        ?ok ->
            Gold    = round(RecShop#rec_shop.price * Count),
            case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_SHOP_BOUGHT) of
                ?ok ->
                    GoodsList = goods_api:make(GoodsId, RecShop#rec_shop.bind, Count),
					%% 判断是否为日常、军团、官衔任务,购买装备 
					Flag = check_buy_equip_for_task(Player, GoodsId),
                    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SHOP_BOUGHT, Flag, 0, 0, 0, 0, 1, []) of
                        {?ok, NewPlayer, _, Packet} ->
                            PacketOk = message_api:msg_notice(?TIP_SHOP_OK),
                            Packet2 = <<Packet/binary, PacketOk/binary>>,
                            misc_packet:send(Player#player.user_id, Packet2),
                            {?ok, NewPlayer};
                        {?error, _ErrorCode} ->
                        	?error
                    end;
                {?error, _ErrorCode} ->
                    ?error
            end
    end;

%% 云游商人初始化信息
handler(?MSG_ID_SHOP_CS_SECRET_INIT, Player, {}) ->
	shop_secret:get_init_info(Player),
	{?ok, Player};

%% 云游商人刷新
handler(?MSG_ID_SHOP_CS_SECRET_REFRESH, Player, {}) ->
	shop_secret:refresh(Player),
	{?ok, Player};

%% 云游商人购买物品
handler(?MSG_ID_SHOP_CS_BUY_GOODS, Player, {Type,Id,Num}) ->
	shop_secret:buy(Player, Id, Type, Num);

handler(MsgId,Player,Datas) ->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	?error.
%%
%% Local Functions
%%
					
			

%% 判断是否为日常、军团、官衔任务,购买装备  
check_buy_equip_for_task(Player, GoodsId) ->
	TaskData    = Player#player.task,
	GuildCycleTask = TaskData#task_data.guild_cycle,
	DailyCycleTask = TaskData#task_data.daily_cycle,
	PositionTask = TaskData#task_data.position_task,
	CurrentGuildTask = GuildCycleTask#task_cycle.current,
	CurrentDailyTask = DailyCycleTask#task_cycle.current,
	check_state_and_goodsid([PositionTask,CurrentGuildTask,CurrentDailyTask], GoodsId, ?CONST_SYS_TRUE).


%% 任务未完成，且购买的装备是所需物品
check_state_and_goodsid([Task|TaskList], GoodsId, Acc) ->
	case is_record(Task,task) of
		?true ->
			TargetList = Task#task.target,
			case TargetList == [] of
				true ->
					check_state_and_goodsid(TaskList, GoodsId, Acc);
				false ->
					Result =
						lists:foldl(fun(Target,Acc0) ->
											case Acc0 == ?CONST_SYS_FALSE of
												true ->
													Acc0;
												false ->
													case Target#task_target.target_type =:= ?CONST_TASK_TARGET_CTN_GOODS 
																andalso Target#task_target.as2 =:= GoodsId
																andalso  Task#task.state =:= ?CONST_TASK_STATE_UNFINISHED of
														?true ->
															?CONST_SYS_FALSE;
														?false ->
															Acc0
													end
											end
									end, Acc, TargetList),
					case Result == ?CONST_SYS_FALSE of
						?true ->
							?CONST_SYS_FALSE;
						?false ->
							check_state_and_goodsid(TaskList, GoodsId, Acc)
					end
			end;
		?false ->
			check_state_and_goodsid(TaskList, GoodsId, Acc)
	end;
check_state_and_goodsid([], _GoodsId, Acc) ->
	Acc.


