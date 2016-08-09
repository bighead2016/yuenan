%% @author zane
%% @doc @todo Add description to yunying_activity_handler.


-module(yunying_activity_handler).
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([handler/3]).



%% ====================================================================
%% Internal functions
%% ====================================================================
handler(?MSG_ID_YUNYING_ACTIVITY_REQUEST_DATA, Player, {}) ->
    {?ok,Player2} = yunying_activity_mod:activity_request_data(Player),
    {?ok, Player2};
handler(?MSG_ID_YUNYING_ACTIVITY_REQUEST_SD_DATA,Player,{})->
	{?ok,Player2} = yunying_activity_mod:shuangdan_activity_request_data(Player),
    {?ok, Player2};
handler(?MSG_ID_YUNYING_ACTIVITY_GET_SD_GIFT,Player,{Type,AchieveId})->
	{?ok,Player2} = yunying_activity_mod:get_shuangdan_activity_gift(Player,Type,AchieveId),
	{?ok,Player2};

%%前端通知，在线得奖励活动开启和玩家上线时发来的请求
handler(?MSG_ID_YUNYING_ACTIVITY_ONLINE_START,Player,{})->
	yunying_activity_api:init_activity_online_award(Player),
	{?ok,Player};


%% 物品兑换
%% Type：兑换类型；Id：兑换id
handler(?MSG_ID_YUNYING_ACTIVITY_EXCHANGE,Player,{Type, Id}) ->
	try
		yunying_activity_mod:exchange_goods(Player, ?CONST_YUNYING_ACTIVITY_EXCHANGE, Type, Id)
	catch
		throw:?error -> ?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 请求春联兑换活动
%% Type：兑换类型；Id：兑换id
%% 限于表结构，后期考虑如何和MSG_ID_YUNYING_ACTIVITY_EXCHANGE合并一条协议
handler(?MSG_ID_YUNYING_ACTIVITY_CS_SPRING_EXCHANGE, Player, {Type, Id}) ->
	try
		yunying_activity_mod:exchange_goods(Player, ?CONST_YUNYING_ACTIVITY_SPRING, Type, Id)
	catch
		throw:?error -> ?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 请求汤圆兑换活动
handler(?MSG_ID_YUNYING_ACTIVITY_CS_TANGYUAN_EXCHANGE, Player, {Type, Id}) ->
	try
		yunying_activity_mod:exchange_goods(Player, ?CONST_YUNYING_ACTIVITY_TANGYUAN, Type, Id)
	catch
		throw:?error -> ?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 获取宝石合成的信息
handler(?MSG_ID_YUNYING_ACTIVITY_CS_STONE_INFO,Player,{}) ->
	try
		yunying_activity_mod:get_stone_compose(Player)
	catch
		throw:?TIP_COMMON_ACTIVITY_NOT_IN_TIME ->
			?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 领取宝石合成的奖励
handler(?MSG_ID_YUNYING_ACTIVITY_CS_STONE_AWARD,Player,{StoneLv}) ->
	try 
		yunying_activity_mod:get_stone_compose_award(Player,StoneLv)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
	
%% 查看未领红包数量
handler(?MSG_ID_YUNYING_ACTIVITY_CS_REDBAG_INFO, Player, {}) ->
	spirit_festival_activity_api:query_redbag_num(Player#player.user_id),
	?ok;
	
%% 领取红包
handler(?MSG_ID_YUNYING_ACTIVITY_CS_GET_REDBAG, Player, {}) ->
	spirit_festival_activity_api:get_redbag(Player);

%% 开红包
handler(?MSG_ID_YUNYING_ACTIVITY_CS_OPEN_REDBAG, Player, {ActivityId, Type}) ->
	spirit_festival_activity_api:open_redbag(Player, ActivityId, Type);
	
%%%%%%%%%%%%%%%%%%%下面是抽卡换武将活动%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%打开抽卡界面请求信息
handler(?MSG_ID_YUNYING_ACTIVITY_LOTTERY_REQUEST_INFO, Player,{ })->
    act_card_ex_mod:card_lottery_request_info(Player),
    {?ok,Player};

%%抽卡{牌类型，抽取次数}
handler(?MSG_ID_YUNYING_ACTIVITY_CS_LOTTERY,Player,{Type,Count})->
	act_card_ex_mod:card_lottery(Player,Type,Count);

%% 抽奖收集卡牌换武将——请求武将兑换或者点数兑换的界面信息
handler(?MSG_ID_YUNYING_ACTIVITY_CS_EXCHANGE_INFO,Player,{}) ->
	try 
		act_card_ex_mod:get_partner_exchange_info(Player)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;


%% 抽奖收集卡牌换武将——兑换武将或物品
handler(?MSG_ID_YUNYING_ACTIVITY_PARTNER_EXCHANGE,Player,{Type,Id}) ->
	try 
		act_card_ex_mod:partner_exchange(Player, Type, Id)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
	
%% 抽奖收集卡牌换武将——点数兑换
handler(?MSG_ID_YUNYING_ACTIVITY_POINT_EXCHANGE,Player,{Type,Id}) ->
	try 
		act_card_ex_mod:point_exchange(Player, Type, Id)
	catch
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
%% 请求神刀免费次数
handler(?MSG_ID_YUNYING_ACTIVITY_CS_FREE_EXCHANGE, Player, {}) ->
	act_card_ex_mod:freetimes(Player),
	?ok;

%% 请求祝福界面信息
handler(?MSG_ID_YUNYING_ACTIVITY_CS_BLESS_INFO, Player, {}) ->
	yunying_activity_mod:get_bless_info(Player),
	?ok;

%% 请求一次祝福
handler(?MSG_ID_YUNYING_ACTIVITY_CS_BLESS_VALUE, Player, {Type}) ->
	try
		yunying_activity_mod:get_bless_value(Player, Type)
	catch
		throw:?error ->
			?ok;
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 请求祝福兑换物品
handler(?MSG_ID_YUNYING_ACTIVITY_CS_BLESS_GET_AWARD, Player, {Type, Id}) ->
	try
		yunying_activity_mod:bless_exchange_goods(Player, Type, Id)
	catch
		throw:?error -> ?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 请求宝石积分界面信息
handler(?MSG_ID_YUNYING_ACTIVITY_CS_STONE_VALUE_INFO, Player, {}) ->
	yunying_activity_mod:get_stone_value_info(Player),
	?ok;

%% 请求宝石积分兑换物品
handler(?MSG_ID_YUNYING_ACTIVITY_CS_STONE_VALUE_GET_AWARD, Player, {Type, Id}) ->
	try
		yunying_activity_mod:get_stone_value_exchange_goods(Player, Type, Id)
	catch
		throw:?error -> ?ok;
		throw:Return -> Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;

%% 猜灯谜
handler(?MSG_ID_YUNYING_ACTIVITY_CS_RIDDLE_ANSWER, Player, {Id, Ans}) ->
	spirit_festival_activity_api:answer_riddle(Player#player.user_id, 
											   (Player#player.info)#info.user_name, 
											   Id, Ans),
	?ok;

%% 查询灯谜累计答题奖励信息
handler(?MSG_ID_YUNYING_ACTIVITY_CS_RIDDLE_AWARD_INFO, Player, {}) ->
	spirit_festival_activity_api:query_riddle_award_info(Player#player.user_id),
	?ok;
handler(_,Player,_)->
	?MSG_ERROR("illegal message",[]),
	{?ok,Player}.