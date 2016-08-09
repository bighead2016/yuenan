%% @author jin
%% @doc @todo Add description to kb_treasure_mod.
%% 皇陵探宝


-module(kb_treasure_mod).


-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.goods.data.hrl").

-export([turn/3, get_config_id/0]).


%% 转盘抽奖
turn(#player{user_id = UserId, info = #info{user_name = UserName}} = Player, Level, Type) ->
	try
		{?ok, Player2, Packet} = chk_condition(Player, Level, Type),
		misc_packet:send(UserId, Packet),
		ConfigId = get_config_id(),
		{?ok, Player4} =
			case Type of
				?CONST_KB_TREASURE_TURN_TYPE_SINGLE ->
					do_turn(Player2, ConfigId, Level);
				?CONST_KB_TREASURE_TURN_TYPE_MULTI ->
					{Player3, DirtyList, GoodsList, MailGoodsList, IdxList} =
						do_onekey_turn(Player2, ConfigId, Level, ?CONST_KB_TREASURE_MULTI_TIMES, [], [], [], []),
					GoodsList2 = sum_goods(GoodsList, []),
					case MailGoodsList =/= [] of
						?true ->
							MailGoodsList2 = sum_goods(MailGoodsList, []),
							MailGoodsList3 = [{misc:to_list(G#goods.goods_id)} || G <- MailGoodsList2],
							mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, 
													[{MailGoodsList3}], MailGoodsList2, 0, 0, 0, ?CONST_COST_KB_TREASURE_TURN_GOODS);
						?false ->
							?ok
					end,
					{Player2_2, StylePacket} = goods_style_api:add_style_list(Player3, GoodsList),
					{Player2_3, SkillPacket} = horse_skill_api:upgrade_skill_base(Player2_2, GoodsList),
					BroadcastPacket = pack_goods(GoodsList2, UserId, UserName, <<>>),
					GoodsPacket = goods_api:pack_dirty(Player2_3, DirtyList),
					IdxPacket = kb_treasure_api:msg_sc_total(IdxList),
					misc_packet:send(UserId, <<GoodsPacket/binary, IdxPacket/binary, StylePacket/binary, SkillPacket/binary>>),
					misc_app:broadcast_world_2(BroadcastPacket),
					{?ok, Player3}
			end,
		{?ok, Player4}
	catch
		throw:{?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
			{?ok, Player};
		throw:{?error, ErrorCode} ->
			?MSG_ERROR("king tomb treasure error:~w", [ErrorCode]),
			TipPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(UserId, TipPacket),
			{?ok, Player};
		Type:Reason ->
			?MSG_ERROR("Type:~p, Reason:~p, Stacktrace:~p", [Type, Reason, erlang:get_stacktrace()]),
			{?ok, Player}
	end.	

%% 转一次
do_turn(#player{user_id = UserId, info = #info{user_name = UserName}} = Player, ConfigId, Level) ->
	RateList = get_rate_list(ConfigId, Level),
	Result = misc_random:random_list(RateList),
	#rec_kb_treasure{goods = GoodsTuple} = get_rec_data(ConfigId, Level, Result),
	GoodsList = make_goods(GoodsTuple, []),
	{Player3, Packet} =
		case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_KB_TREASURE_TURN_GOODS, 1, 1, 0, 0, 0, 1, []) of
			{?ok, Player2, _, BagPacket} ->
				{Player2, BagPacket};
			{?error, ErrorCode} ->
				?MSG_ERROR("king tomb do turn error:~w", [ErrorCode]),
				GoodsList2 = [{misc:to_list(G#goods.goods_id)} || G <- GoodsList],
				mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, 
													[{GoodsList2}], GoodsList, 0, 0, 0, ?CONST_COST_KB_TREASURE_TURN_GOODS),
				{Player, <<>>}
		end,
	TargetPacket = kb_treasure_api:msg_sc_target(Result),
	misc_packet:send(UserId, TargetPacket),
	ReplyPacket = kb_treasure_api:msg_sc_reply(Result),
	BroadcastPacket = pack_goods(GoodsList, UserId, UserName, <<>>),
	{?ok, Player3#player{offline_packet = <<Packet/binary, ReplyPacket/binary>>, broadcast_packet = BroadcastPacket}}.

%% 转多次
do_onekey_turn(Player, ConfigId, Level, Times, OldDirtyList, OldGoodsList, OldMailGoodsList, OldIdxList) when Times > 0 ->
	#player{user_id = UserId, bag = Bag} = Player,
	RateList =  get_rate_list(ConfigId, Level),
	Result = misc_random:random_list(RateList),
	IdxList = 
		case lists:keytake(Result, 1, OldIdxList) of
			{value, {_, C}, OldIdxList2} ->
				[{Result, C+1}|OldIdxList2];
			_ ->
				[{Result, 1}|OldIdxList]
		end,
	#rec_kb_treasure{goods = GoodsTuple} = get_rec_data(ConfigId, Level, Result),
	GoodsList = make_goods(GoodsTuple, []),
	case ctn_bag2_api:set_stack_list_dirty(UserId, Bag, GoodsList, 0, OldDirtyList) of
		{?ok, Bag2, DirtyList} ->
			do_onekey_turn(Player#player{bag = Bag2}, ConfigId, Level, Times - 1, DirtyList, OldGoodsList ++ GoodsList, OldMailGoodsList, IdxList);
		{?error, _ErrorCode} ->
			do_onekey_turn(Player, ConfigId, Level, Times - 1, OldDirtyList, OldGoodsList ++ GoodsList, OldMailGoodsList ++ GoodsList, IdxList)
	end;
do_onekey_turn(Player, _ConfigId, _Level, _Times, OldDirtyList, OldGoodsList, OldMailGoodsList, OldIdxList) ->
    {Player, OldDirtyList, OldGoodsList, OldMailGoodsList, OldIdxList}.

%% 检查条件
chk_condition(#player{user_id = UserId, bag = Bag} = Player, Level, Type) ->
%% 	PlatId = config:read_deep([server, base, platform_id]),
%% 	case lists:member(PlatId, ?CONST_KB_TREASURE_OPEN_PLAT_LIST) of
%% 		?true ->
%% 			?ok;
%% 		?false ->
%% 			throw({?error, ?TIP_KB_TREASURE_NOT_EXISTS})
%% 	end,
	NowSec = misc:seconds(),
	{StartTime, EndTime} = data_welfare:get_deposit_active_time(43),
	case NowSec >= StartTime andalso NowSec =< EndTime of
		?true ->
			?ok;
		?false ->
			throw({?error, ?TIP_KB_TREASURE_NO_START})
	end,
	{Price, GoodsId, Count} =
		case {Level, Type} of
			{?CONST_KB_TREASURE_TURN_LEVEL_ONE, ?CONST_KB_TREASURE_TURN_TYPE_SINGLE} ->
				{?CONST_KB_TREASURE_SILVER_SINGLE, ?CONST_KB_TREASURE_GOODS1, ?CONST_KB_TREASURE_SINGLE_COUNT};
			{?CONST_KB_TREASURE_TURN_LEVEL_ONE, ?CONST_KB_TREASURE_TURN_TYPE_MULTI } ->
				{?CONST_KB_TREASURE_SILVER_SINGLE, ?CONST_KB_TREASURE_GOODS1, ?CONST_KB_TREASURE_MULTI_COUNT};
			{?CONST_KB_TREASURE_TURN_LEVEL_TWO, ?CONST_KB_TREASURE_TURN_TYPE_SINGLE} ->
				{?CONST_KB_TREASURE_GOLD_SINGLE,   ?CONST_KB_TREASURE_GOODS2, ?CONST_KB_TREASURE_SINGLE_COUNT};
			{?CONST_KB_TREASURE_TURN_LEVEL_TWO, ?CONST_KB_TREASURE_TURN_TYPE_MULTI } ->
				{?CONST_KB_TREASURE_GOLD_SINGLE,   ?CONST_KB_TREASURE_GOODS2, ?CONST_KB_TREASURE_MULTI_COUNT}
		end,
	HaveNum = ctn_bag2_api:get_goods_count(Bag, GoodsId),
	if
		HaveNum =:= ?CONST_SYS_FALSE ->	%% 没有道具可以扣除
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Price * Count, ?CONST_COST_KB_TREASURE_TURN_COST) of
				?ok ->
					{?ok, Player, <<>>};
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end;
		HaveNum >= Count ->				%% 道具足够扣除
			case ctn_bag2_api:get_by_id(UserId, Bag, GoodsId, Count) of
				{?ok, Bag2, _GoodsList, Packet} ->
					admin_log_api:log_goods(UserId, ?CONST_SYS_FALSE, ?CONST_COST_KB_TREASURE_TURN_COST, GoodsId, Count, misc:seconds()),
					{?ok, Player#player{bag = Bag2}, Packet};
				{?error, ErrorCode} ->
					throw({?error, ErrorCode})
			end;
		?true ->						%% 道具优先扣除
			NeedNum = Count - HaveNum,
			{Player2, Packet2} =
				case ctn_bag2_api:get_by_id(UserId, Bag, GoodsId, HaveNum) of
				{?ok, Bag2, _GoodsList, Packet} ->
					admin_log_api:log_goods(UserId, ?CONST_SYS_FALSE, ?CONST_COST_KB_TREASURE_TURN_COST, GoodsId, HaveNum, misc:seconds()),
					{Player#player{bag = Bag2}, Packet};
				{?error, ErrorCode2} ->
					throw({?error, ErrorCode2})
			end,
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Price * NeedNum, ?CONST_COST_KB_TREASURE_TURN_COST) of
				?ok ->
					{?ok, Player2, Packet2};
				{?error, ErrorCode3} ->
					throw({?error, ErrorCode3})
			end
	end.

%% 获取配置id
get_config_id() ->
	case data_welfare:get_deposit_time(43) of
		#rec_welfare_deposit_time{para = Para} ->
			Para;
		_ ->
			1
	end.

%% 获取概率列表
get_rate_list(ConfigId, Level) ->
	case data_kb_treasure:get_rate_list({ConfigId, Level}) of
		?null ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		List ->
			List
	end.

%% 获取配置数据
get_rec_data(ConfigId, Level, Result) ->
	case data_kb_treasure:get_turn_data({ConfigId, Level, Result}) of
		?null ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		Rec ->
			Rec
	end.

%% 创建物品
make_goods([{GoodsId, IsBind, Count}|Tail], OldList) ->
    case goods_api:make(GoodsId, IsBind, Count) of
        {?error, _} ->
            make_goods(Tail, OldList);
        GoodsList -> 
            make_goods(Tail, OldList++GoodsList)
    end;
make_goods([], List) ->
    List;
make_goods(_, OldList) ->
    OldList.

%% 打包物品广播
pack_goods([#goods{color = Color} = Goods | Tail], UserId, UserName, OldPacket) when Color > ?CONST_SYS_COLOR_PURPLE ->
	BPacket =
		case Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP of
			?true ->
				message_api:msg_notice(?TIP_KB_TREASURE_TURN_EQUIP, [{UserId, UserName}], [Goods], []);
			?false ->
				message_api:msg_notice(?TIP_KB_TREASURE_TURN_GOODS, [{UserId, UserName}], [Goods], [])
		end,
    pack_goods(Tail, UserId, UserName, <<OldPacket/binary, BPacket/binary>>);
pack_goods([_|Tail], UserId, UserName, OldPacket) ->
    pack_goods(Tail, UserId, UserName, OldPacket);
pack_goods([], _, _, Packet) ->
    Packet.

%% 合并相同物品
sum_goods([#goods{goods_id = Id, count = Count} = Goods | Tail], OldList) ->
    case lists:keytake(Id, #goods.goods_id, OldList) of
        {value, G, OldList2} ->
            sum_goods(Tail, [G#goods{count = Count + G#goods.count} | OldList2]);
        _ ->
            sum_goods(Tail, [Goods | OldList])
    end;
sum_goods([], List) ->
    List.