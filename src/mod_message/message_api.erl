%% Author: Administrator
%% Created: 2012-8-18
%% Description: TODO: Add description to massage_api
-module(message_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/const.tip.hrl"). 
%%
%% Exported Functions
%%
-export([
		 send_msg/2,
		 msg_notice/1,msg_notice/2, msg_notice/4]).

-export([
		 msg_reward_add_exp/1,msg_reward_add_sp/1,
		 msg_reward_add_honour/1,msg_reward_add_meritorious/1,
		 msg_reward_add_exploit/1,msg_reward_add_mind_spirit/1,
		 msg_reward_add_experience/1,msg_reward_add_cash/1,
		 msg_reward_add_bind_cash/1,msg_reward_add_bind_gold/1,
		 msg_reward_add_goods/2,msg_reward_add_arena_score/1,
		 msg_reward_add_hufu/1, msg_sc_window/1,
         msg_reward_add_bind_cash_2/1
		]).




send_msg(Pid,MsgId) when is_pid(Pid)->
	Packet = msg_notice(MsgId),
	misc_packet:send(Pid,Packet);
send_msg(UserId,MsgId) when is_number(UserId)->
	Packet = msg_notice(MsgId),
	misc_packet:send(UserId,Packet);
send_msg(_,_) ->
	?ok.
	
%% 提示消息
%% message_api:msg_notice(502).   数据库忙(在58上定常量值)
msg_notice(?CONST_SYS_FALSE) -> ?ok;
msg_notice(MsgId) ->
	misc_packet:pack(?MSG_ID_MESSAGE_SC_NOTICE, ?MSG_FORMAT_MESSAGE_SC_NOTICE, [MsgId]).
%% 系统消息(提示消息调用接口)
%% message_api:msg_notice(15002, [{type, String},{type, String}, {type, String}]).
%% message_api:msg_notice(15002, [{100, UserName}, {100, GuildName}, {2, misc:to_list(SkillId)}]). 100表示不需要前端查表 2表示查技能表
msg_notice(?CONST_SYS_FALSE, _) -> ?ok;
msg_notice(MsgId, ReseveList) ->
	msg_notice(MsgId, [], [], ReseveList).
%% 系统消息(全服广播调用接口)
%% message_api:msg_notice(19003, [{UserId, UserName}], [Goods|GoosList], [{type, String}]).
msg_notice(?CONST_SYS_FALSE, _, _, _) ->?ok;
msg_notice(MsgId, UserList, GoodsList, ReserveList) ->
	BinMsgId	= misc_packet:encode(?uint16, MsgId),
	BinUser		= msg_notice_player(UserList),
	{
	 BinGoodsProp,
	 BinGoodsEquip
	}			= msg_notice_goods(GoodsList),
	BinReserve	= msg_notice_reserve(ReserveList),
	BinData		= <<BinMsgId/binary, BinUser/binary, BinGoodsProp/binary, BinGoodsEquip/binary, BinReserve/binary>>,
	misc_packet:pack(?MSG_ID_MESSAGE_SC_SYSTEM, BinData).

%% 角色
msg_notice_player(UserList) ->
	Acc	= misc_packet:encode(?uint16, length(UserList)),
	msg_notice_player(UserList, Acc).
msg_notice_player([{UserId, UserName}|UserList], Acc) ->
	BinPlayer	= msg_notice_player2(UserId, UserName),
	msg_notice_player(UserList, <<Acc/binary, BinPlayer/binary>>);
msg_notice_player([], Acc) -> Acc.
msg_notice_player2(UserId, UserName) ->
	BinUserId	= misc_packet:encode(?uint32, UserId),
	BinUserName	= misc_packet:encode(?string, UserName),
	<<BinUserId/binary, BinUserName/binary>>.

%% 物品
msg_notice_goods(GoodsList) ->
	msg_notice_goods(GoodsList, 0, <<>>, 0, <<>>).
msg_notice_goods([#goods{} = Goods|GoodsList], CountGoodsProp, AccGoodsProp, CountGoodsEquip, AccGoodsEquip) ->
	case Goods#goods.type of
		?CONST_GOODS_TYPE_EQUIP ->
			BinGoodsEquip	= msg_notice_goods_equip(Goods),
			CountGoodsEquip2= CountGoodsEquip + 1,
			AccGoodsEquip2	= <<AccGoodsEquip/binary, BinGoodsEquip/binary>>,
			msg_notice_goods(GoodsList, CountGoodsProp, AccGoodsProp, CountGoodsEquip2, AccGoodsEquip2);
		_ ->
			BinGoodsProp	= msg_notice_goods_prop(Goods),
			CountGoodsProp2	= CountGoodsProp + 1,
			AccGoodsProp2	= <<AccGoodsProp/binary, BinGoodsProp/binary>>,
			msg_notice_goods(GoodsList, CountGoodsProp2, AccGoodsProp2, CountGoodsEquip, AccGoodsEquip)
	end;
msg_notice_goods([#mini_goods{} = MiniGoods|GoodsList], CountGoodsProp, AccGoodsProp, CountGoodsEquip, AccGoodsEquip) ->
    Goods = goods_api:mini_to_goods(MiniGoods),
	case Goods#goods.type of
		?CONST_GOODS_TYPE_EQUIP ->
			BinGoodsEquip	= msg_notice_goods_equip(Goods),
			CountGoodsEquip2= CountGoodsEquip + 1,
			AccGoodsEquip2	= <<AccGoodsEquip/binary, BinGoodsEquip/binary>>,
			msg_notice_goods(GoodsList, CountGoodsProp, AccGoodsProp, CountGoodsEquip2, AccGoodsEquip2);
		_ ->
			BinGoodsProp	= msg_notice_goods_prop(Goods),
			CountGoodsProp2	= CountGoodsProp + 1,
			AccGoodsProp2	= <<AccGoodsProp/binary, BinGoodsProp/binary>>,
			msg_notice_goods(GoodsList, CountGoodsProp2, AccGoodsProp2, CountGoodsEquip, AccGoodsEquip)
	end;
msg_notice_goods([], CountGoodsProp, AccGoodsProp, CountGoodsEquip, AccGoodsEquip) ->
	BinCountGoodsProp	= misc_packet:encode(?uint16, CountGoodsProp),
	BinCountGoodsEquip	= misc_packet:encode(?uint16, CountGoodsEquip),
	{<<BinCountGoodsProp/binary, AccGoodsProp/binary>>, <<BinCountGoodsEquip/binary, AccGoodsEquip/binary>>}.

msg_notice_goods_prop(Goods) ->
	BinGoodsId			= misc_packet:encode(?uint32, 	Goods#goods.goods_id),
	BinGoodsCount		= misc_packet:encode(?uint16, 	Goods#goods.count),
	BinGoodsBind		= misc_packet:encode(?bool, 	Goods#goods.bind),
	BinGoodsStartTime	= misc_packet:encode(?uint32, 	Goods#goods.start_time),
	BinGoodsEndTime		= misc_packet:encode(?uint32, 	Goods#goods.end_time),
	<<BinGoodsId/binary, BinGoodsCount/binary, BinGoodsBind/binary, BinGoodsStartTime/binary, BinGoodsEndTime/binary>>.
msg_notice_goods_equip(Goods) ->
	BinGoodsId			= misc_packet:encode(?uint32, 	Goods#goods.goods_id),
	BinGoodsCount		= misc_packet:encode(?uint8, 	Goods#goods.count),
	BinGoodsBind		= misc_packet:encode(?bool, 	Goods#goods.bind),
	BinGoodsStartTime	= misc_packet:encode(?uint32, 	Goods#goods.start_time),
	BinGoodsEndTime		= misc_packet:encode(?uint32, 	Goods#goods.end_time),
	BinStrengthenLv		= misc_packet:encode(?uint8, 	(Goods#goods.exts)#g_equip.strength_lv),
%% 	BinAttr				= msg_notice_goods_equip_plus([]),
%% 	Attr				= (Goods#goods.exts)#g_equip.attr,
%% 	case Goods#goods.sub_type of
%% 		?CONST_GOODS_EQUIP_HORSE ->
%% 			goods_api:get_attr_list(Attr);
%% 		 _ -> []
%% 	end,
	Attr = case Goods#goods.sub_type of
			   ?CONST_GOODS_EQUIP_HORSE ->
				   horse_mod:get_ride_list(Goods#goods.exts#g_equip.ride_list);
			   _ ->
				   []
		   end,
	BinAttr = msg_notice_goods_equip_horse(Attr),
	
	SoulList 			= [],
	SoulLvList 			= furnace_mod:trans_soul_id_value(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, SoulList),

	BinPractise			= msg_notice_goods_equip_plus([]),
	BinSoul				= msg_notice_goods_equip_soul(SoulLvList),	 					%%Two Line change 2013-01-22
    SoulList2 = furnace_soul_api:get_hole_list(Goods),
    BinSoulList2 = msg_notice_goods_equip_stone(SoulList2),
	<<BinGoodsId/binary, BinGoodsCount/binary, BinGoodsBind/binary, BinGoodsStartTime/binary, BinGoodsEndTime/binary,
	  BinStrengthenLv/binary, BinAttr/binary, BinPractise/binary, BinSoul/binary, BinSoulList2/binary>>.

msg_notice_goods_equip_stone(SoulList2) ->
    Length = length(SoulList2),
    Acc = misc_packet:encode(?uint16, Length),
    msg_notice_goods_equip_stone(SoulList2, Acc).
msg_notice_goods_equip_stone([], Acc) ->Acc;
msg_notice_goods_equip_stone([{SoulId}|Rest], Acc) ->
    BinId         = misc_packet:encode(?uint32,    SoulId),
    msg_notice_goods_equip_stone(Rest, <<Acc/binary, BinId/binary>>).

msg_notice_goods_equip_plus(AttrPlusList) ->
	Acc	= misc_packet:encode(?uint16, length(AttrPlusList)),
	msg_notice_goods_equip_plus(AttrPlusList, Acc).
msg_notice_goods_equip_plus([{AttrType, _Color, AttrValue}|AttrPlusList], Acc) ->
	BinAttrType			= misc_packet:encode(?uint8, 	AttrType),
	BinAttrValue		= misc_packet:encode(?uint32, 	AttrValue),
	msg_notice_goods_equip_plus(AttrPlusList, <<Acc/binary, BinAttrType/binary, BinAttrValue/binary>>);
msg_notice_goods_equip_plus([], Acc) -> Acc.

msg_notice_goods_equip_horse(AttrHorseList) ->
	Acc = misc_packet:encode(?uint16, length(AttrHorseList)),
	msg_notice_goods_equip_horse(AttrHorseList, Acc).
msg_notice_goods_equip_horse([{AttrType, AttrValue}|AttrHorseList], Acc) ->
	BinAttrType			= misc_packet:encode(?uint8, 	AttrType),
	BinAttrValue		= misc_packet:encode(?uint32, 	AttrValue),
	msg_notice_goods_equip_horse(AttrHorseList, <<Acc/binary, BinAttrType/binary, BinAttrValue/binary>>);
msg_notice_goods_equip_horse([], Acc) -> Acc.

msg_notice_goods_equip_soul(AttrSoulList) ->
	Acc	= misc_packet:encode(?uint16, length(AttrSoulList)),
	msg_notice_goods_equip_soul(AttrSoulList, Acc).
msg_notice_goods_equip_soul([{AttrType, Lv, AttrValue}|AttrSoulList], Acc) ->
	BinAttrType			= misc_packet:encode(?uint8, 	AttrType),
	BinLv				= misc_packet:encode(?uint8, 	Lv),
	BinAttrValue		= misc_packet:encode(?uint32, 	AttrValue),
	msg_notice_goods_equip_soul(AttrSoulList, <<Acc/binary, BinAttrType/binary, BinLv/binary, BinAttrValue/binary>>);
msg_notice_goods_equip_soul([], Acc) -> Acc.

msg_notice_reserve(ReserveList) ->
	Acc	= misc_packet:encode(?uint16, length(ReserveList)),
	msg_notice_reserve(ReserveList, Acc).
msg_notice_reserve([{Type, Value}|ReserveList], Acc) ->
	BinType				= misc_packet:encode(?uint8,    Type),
	BinValue			= misc_packet:encode(?string, 	Value),
	msg_notice_reserve(ReserveList, <<Acc/binary, BinType/binary, BinValue/binary>>);
msg_notice_reserve([], Acc) -> Acc.

%% 收益提示
msg_reward_add_exp(Value) ->        %经验
	msg_notice(?TIP_REWARD_ADD_EXP, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_sp(Value) ->         %体力
	msg_notice(?TIP_REWARD_ADD_SP_TEMP, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_honour(Value) ->     %声望
	msg_notice(?TIP_REWARD_ADD_HONOUR, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_meritorious(Value) -> %功勋
	msg_notice(?TIP_REWARD_ADD_MERITORIOUS, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_exploit(Value) -> 	 %军团贡献
	msg_notice(?TIP_REWARD_ADD_EXPLOIT, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_mind_spirit(Value) -> %心法灵力
	msg_notice(?TIP_REWARD_ADD_MIND_SPIRIT, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_experience(Value) ->  %历练
	msg_notice(?TIP_REWARD_ADD_EXPERIENCE, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_cash(Value) ->        %元宝
	msg_notice(?TIP_REWARD_ADD_CASH, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_bind_cash(Value) ->   %礼券
	msg_notice(?TIP_REWARD_ADD_BIND_CASH, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_bind_cash_2(Value) ->   %绑定元宝
	msg_notice(?TIP_REWARD_ADD_BIND_CASH_3, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_bind_gold(Value) ->   %绑定铜钱
	msg_notice(?TIP_REWARD_ADD_BIND_GOLD, [{?TIP_SYS_COMM, misc:to_list(Value)}]). 

msg_reward_add_goods(GoodsId, Num) -> %获得物品
	msg_notice(?TIP_REWARD_ADD_GOODS, [{?TIP_SYS_COMM, misc:to_list(GoodsId)}, {?TIP_SYS_COMM, misc:to_list(Num)}]). 

msg_reward_add_arena_score(Value) ->  %战群雄积分
	msg_notice(?TIP_REWARD_ADD_ARENA_SCORE, [{?TIP_SYS_COMM, misc:to_list(Value)}]).

msg_reward_add_hufu(Value) ->  %战群雄虎符
	msg_notice(?TIP_REWARD_ADD_HUFU, [{?TIP_SYS_COMM, misc:to_list(Value)}]).
	
%% 弹窗消息
%%[Type]
msg_sc_window(Type) ->
    misc_packet:pack(?MSG_ID_MESSAGE_SC_WINDOW, ?MSG_FORMAT_MESSAGE_SC_WINDOW, [Type]).
