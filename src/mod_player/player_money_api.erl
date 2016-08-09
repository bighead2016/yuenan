%% Author: Administrator
%% Created: 2012-7-13
%% Description: TODO: Add description to player_money_api
-module(player_money_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("record.player.hrl").
-include("record.data.hrl").



%%
%% Exported Functions
%%

-export([initial_ets/0, minus_money_sp/4]).
-export([read_money/1, read_cash_sum/1, plus_money/4, minus_money/4, check_money/3, deposit/8]).
-export([insert_money/1, lookup_money/1, update_element_money/2, handle_minus/3]).
-export([insert_deposit/1, insert_deposit/5, lookup_deposit/1, deposit_2/8]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 初始化ETS--玩家货币信息
initial_ets() ->
	?ok		= initial_ets_player_money(),
	?ok		= initial_ets_player_deposit(),
	?ok.

initial_ets_player_money() ->
	MonsyList	= get_money_list(),
	?true		= insert_money(MonsyList),
	?ok.

initial_ets_player_deposit() ->
	DepositList	= get_deposit_list(),
	?true		= insert_deposit(DepositList),
	?ok.

%% 查询所有玩家货币信息
get_money_list() ->
	case mysql_api:select_execute(<<"SELECT `user_id`, `account`, `cash`, `cash_sum`, `cash_bind`, `cash_bind_2`, `cash_bind_3`, `gold`, `gold_bind` FROM  `game_user` WHERE `exist` = 1;">>) of
		{?ok, MonsyDataList} -> record_money(MonsyDataList);
		Other -> ?MSG_ERROR("Other:~p", [Other]), []
	end.
%% 查询所有充值信息
get_deposit_list() ->
	case mysql_api:select_execute(<<"SELECT `id`, `account`, `pay_money`, `time`, `user_id` FROM  `log_deposit`;">>) of
		{?ok, DepositDatas} ->
			[{Id, Account, Cash, Time, UserId} || [Id, Account, Cash, Time, UserId] <- DepositDatas];
		Other -> ?MSG_ERROR("Other:~p", [Other]), []
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 充值
deposit(PayNum, Account, RMB, Cash, Time, PayType, Point, ServId) ->
	case check_deposit(PayNum, Account, Cash, Time, ServId) of
		{?ok, UserId, MoneyOld} ->
			case deposit_2(PayNum, Account, UserId, RMB, Cash, Time, PayType, Point) of
				?ok ->
                    act_bhv:cash_in(UserId, Cash, Point),
					check_activity_deposit_consume(UserId,Cash,3),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,21),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,22),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,23),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,24),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,25),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,26),                        %运营充值/消费活动检测
					check_activity_deposit_consume(UserId,Cash,27),                        %运营充值/消费活动检测
                    yunying_activity_mod:activity_unlimitted_award(UserId,Cash,15),  %情暖寒冬——单笔充值活动检测
					?ok;
				{?error, ErrorCode} -> 
					cancel_deposit(PayNum, MoneyOld),
					{?error, ErrorCode}
			end;
		{?error, ?TIP_PLAYER_DEPOSIT_REPEAT} ->
			{?error, ?TIP_PLAYER_DEPOSIT_REPEAT};
		{?error, ErrorCode} ->
			cancel_deposit(PayNum, ?null),
			{?error, ErrorCode}
	end.
deposit_2(PayNum, Account, UserId, RMB, Cash, Time, PayType, Point) ->
	case plus_money(UserId, ?CONST_SYS_CASH, Cash, Point) of
	?ok ->
		case read_money(UserId) of
		{?ok, MoneyNew} when is_record(MoneyNew, money) andalso 
                                 (Point =:= ?CONST_COST_PLAYER_DEPOSIT orelse Point =:= ?CONST_COST_PLAYER_DEPOSIT_OLD) ->
			case mysql_api:update_execute(<<"UPDATE `game_user` SET ",
											"`cash` = '", (misc:to_binary(MoneyNew#money.cash))/binary,
											"', `cash_sum` = '", (misc:to_binary(MoneyNew#money.cash_sum))/binary,
											"' WHERE `user_id` = ", (misc:to_binary(UserId))/binary, ";">>) of
			{?ok, _} ->
				Lv	= case player_api:get_player_field(UserId, #player.info) of
						  {?ok, #info{lv = LvTmp}} -> LvTmp;
						  _ -> 100
					  end,
				admin_log_api:log_deposit(Account, UserId, RMB, Cash, Point, Time),
				player_vip_api:refresh_vip(UserId),
%% 				new_serv_api:deposit_award(PayNum, UserId, RMB, Cash), %% 新服充值返利
				player_db_mod:log_deposit(PayNum, UserId, Account, Lv, PayType, Cash, Time),
				mixed_serv:add_recharge(UserId, Cash),  %合服活动--充值检测
				hundred_serv_api:recharge(UserId, Cash), %百服活动
                welfare_deposit_api:in(UserId, Cash, Time),
                new_serv_turn_api:in(UserId),
				?ok;
			{?error, Error} ->
				?MSG_ERROR("Error In deposit(Account:~p, UserId:~p, RMB:~p, Cash:~p, Time:~p, Point:~p) Error:~p",
						   [Account, UserId, RMB, Cash, Time, Point, Error]),
				{?error, ?TIP_COMMON_ERROR_DB}
			end;
		{?ok, MoneyNew} when is_record(MoneyNew, money) -> ?ok;
		{?error, ErrorCode} ->
			?MSG_ERROR("Error In deposit(Account:~p, UserId:~p, RMB:~p, Cash:~p, Time:~p, Point:~p) ErrorCode:~p",
					   [Account, UserId, RMB, Cash, Time, Point, ErrorCode]),
			{?error, ErrorCode}
		end;
	{?error, ErrorCode} ->
		?MSG_ERROR("Error In deposit(Account:~p, UserId:~p, RMB:~p, Cash:~p, Time:~p, Point:~p) ErrorCode:~p",
				   [Account, UserId, RMB, Cash, Time, Point, ErrorCode]),
		{?error, ErrorCode}
	end.

check_deposit(PayNum, Account, Cash, Time, ServId) ->
	try
		{?ok, UserId}	= check_deposit_account(Account, ServId),
		?ok				= check_deposit_repeat(PayNum, Account, Cash, Time, UserId),
		{?ok, Money}	= check_deposit_money(UserId),
		{?ok, UserId, Money}
	catch
		throw:Return ->
            Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
check_deposit_account(Account, ServId) ->
    case mysql_api:select(<<"select `user_id` from `game_user` where `account` = '", (misc:to_binary(Account))/binary, "' and serv_id = '", (misc:to_binary(ServId))/binary, "';">>) of
        {?ok, [[0]]} ->
            throw({?error, ?TIP_COMMON_NO_THIS_PLAYER});
        {?ok, [[UserIdXX]]} ->
            case mysql_api:select(<<"select `user_id` from `game_player` where `user_id` = '", (misc:to_binary(UserIdXX))/binary, "';">>) of
                {?ok, [[0]]} ->
                    throw({?error, ?TIP_COMMON_NO_THIS_PLAYER});
                {?ok, [[UserIdXX]]} ->
                    {?ok,UserIdXX};
                _ ->
                    throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})
            end;
        _ ->
            case player_api:lookup_account_2(Account, ServId) of
                {?ok, UserId} -> 
                    {?ok, UserId};
                _ ->
                    throw({?error, ?TIP_COMMON_NO_THIS_PLAYER}) 
            end
    end.
	
check_deposit_repeat(PayNum, Account, Cash, Time, UserId) ->
	case lookup_deposit(PayNum) of
		?null -> insert_deposit(PayNum, Account, Cash, Time, UserId), ?ok;
		_ -> throw({?error, ?TIP_PLAYER_DEPOSIT_REPEAT})% 充值订单重复
	end.
check_deposit_money(UserId) ->
	case read_money(UserId) of
		{?ok, Money} -> {?ok, Money};
		{?error, ErrorCode} -> throw({?error, ErrorCode})
	end.


cancel_deposit(PayNum, Money) when is_record(Money, money) ->
	delete_deposit(PayNum),
	insert_money(Money),
	MsgData	= [
			   {?CONST_SYS_CASH, Money#money.cash},
			   {?CONST_SYS_CASH_BIND, Money#money.cash_bind},
			   {?CONST_SYS_GOLD, Money#money.gold},
			   {?CONST_SYS_GOLD_BIND, Money#money.gold_bind}
			  ],
	Packet	= player_api:msg_player_sc_update_money(MsgData),
	misc_packet:send(Money#money.user_id, Packet);
cancel_deposit(PayNum, _Money) ->
	delete_deposit(PayNum).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% 读取角色货币信息
%% 返回值：Money = #money{}
read_money(UserId) ->
	case lookup_money(UserId) of
		Money when is_record(Money, money) -> {?ok, Money};
		Any ->
			?MSG_ERROR("UserId:~p Any:~p", [UserId, Any]),
			case mysql_api:select_execute(<<"SELECT `account`, `cash`, `cash_sum`, `cash_bind`, `cash_bind_2`, `cash_bind_3`, `gold`, `gold_bind` FROM  `game_user` WHERE `user_id` = '", 
                                            (misc:to_binary(UserId))/binary, "';">>) of
				{?ok, [[Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold]|_]} ->
					Money	= record_money(UserId, Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold),
					insert_money(Money),
					{?ok, Money};
				Other ->
					?MSG_ERROR("UserId:~p Other:~p", [UserId, Other]), 
					{?error, ?TIP_COMMON_SYS_ERROR}
			end
	end.

%% 读取角色货币信息
%% 返回值：Money = #money{}
read_cash_sum(UserId) ->
	case lookup_element_money(UserId, #money.cash_sum) of
		CashSum when is_integer(CashSum) -> {?ok, CashSum};
		Any ->
			?MSG_ERROR("UserId:~p Any:~p", [UserId, Any]),
			case mysql_api:select_execute(<<"SELECT `account`, `cash`, `cash_sum`, `cash_bind`, `cash_bind_2`, `cash_bind_3`, `gold`, `gold_bind` FROM  `game_user` WHERE `user_id` = '", 
                                            (misc:to_binary(UserId))/binary, "';">>) of
				{?ok, [[Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold]|_]} ->
					Money	= record_money(UserId, Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold),
					insert_money(Money),
					{?ok, Money#money.cash_sum};
				Other ->
					?MSG_ERROR("UserId:~p Other:~p", [UserId, Other]), 
					{?error, ?TIP_COMMON_SYS_ERROR}
			end
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%% 增加金钱
%% 返回值：?ok | {?error, ErrorCode}
%% player_money_api:plus_money(75, 1, 100000, 2850).
plus_money(UserId, Type, Value, Point) when is_integer(Value) andalso Value > 0 ->
	case read_money(UserId) of
		{?ok, Money = #money{account = Account}} ->
			Result =
				case Type of
					?CONST_SYS_GOLD_BIND ->
                        if
                            ?CONST_SYS_MAX_BGOLD =< Money#money.gold_bind ->
                                {?error, ?TIP_COMMON_TOO_MUCH_BGOLD};
                            ?true ->
        						Value2	= misc:floor(Money#money.gold_bind + Value),
                                case misc:min(Value2, ?CONST_SYS_MAX_BGOLD) of
                                    Value2 ->
                						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, Value2, ?CONST_SYS_GOLD_BIND),
                						Packet 		= message_api:msg_reward_add_bind_gold(Value),
                                        misc_packet:send(UserId, Packet),
                						{
										 ?ok,
										 [{#money.gold_bind, Value2}],
										 [{?CONST_SYS_GOLD_BIND, Value2}],
										 Money#money{gold_bind = Value2}
										};
                                    ?CONST_SYS_MAX_BGOLD ->
                                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, ?CONST_SYS_MAX_BGOLD, ?CONST_SYS_GOLD_BIND),
                                        Packet      = message_api:msg_reward_add_bind_gold(Value),
                                        Packet2     = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_BGOLD),
                                        misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>),
                                        {
										 ?ok,
										 [{#money.gold_bind, ?CONST_SYS_MAX_BGOLD}],
										 [{?CONST_SYS_GOLD_BIND, ?CONST_SYS_MAX_BGOLD}],
										 Money#money{gold_bind = ?CONST_SYS_MAX_BGOLD}
										}
                                end
                        end;
					?CONST_SYS_CASH ->
                        if
                            ?CONST_SYS_MAX_CASH =< Money#money.cash ->
                                {?error, ?TIP_COMMON_TOO_MUCH_CASH};
                            ?true ->
                                Value2  = misc:floor(Money#money.cash + Value),
								Value3	= misc:min(Value2, ?CONST_SYS_MAX_CASH),
								admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, Value3, ?CONST_SYS_CASH),
								log_cash(UserId, Account, ?CONST_LOG_PLUS_CURRENCY, Point, Value3 - Money#money.cash, Value3),
								Packet	=
									case Value3 of
										Value2 -> message_api:msg_reward_add_cash(Value);
										?CONST_SYS_MAX_CASH ->
											PacketTemp1	= message_api:msg_reward_add_cash(Value),
											PacketTemp2	= message_api:msg_notice(?TIP_COMMON_TOO_MUCH_CASH),
											<<PacketTemp1/binary, PacketTemp2/binary>>
									end,
								misc_packet:send(UserId, Packet),
								case Point of
									?CONST_COST_PLAYER_DEPOSIT ->
										CashSum	= Money#money.cash_sum + Value,
										{
										 ?ok,
										 [{#money.cash, Value3}, {#money.cash_sum, CashSum}],
										 [{?CONST_SYS_CASH, Value3}, {?CONST_SYS_CASH_SUM, CashSum}],
										 Money#money{cash = Value3, cash_sum = CashSum}
										};
                                    ?CONST_COST_PLAYER_DEPOSIT_OLD ->
                                        CashSum = Money#money.cash_sum + Value,
                                        {
                                         ?ok,
                                         [{#money.cash, Value3}, {#money.cash_sum, CashSum}],
                                         [{?CONST_SYS_CASH, Value3}, {?CONST_SYS_CASH_SUM, CashSum}],
                                         Money#money{cash = Value3, cash_sum = CashSum}
                                        };
									_ ->
%%                                         handle_return_cash(UserId, Value, Point),
										{
										 ?ok,
										 [{#money.cash, Value3}],
										 [{?CONST_SYS_CASH, Value3}],
										 Money#money{cash = Value3}
										}
								end
                        end;
					?CONST_SYS_CASH_BIND ->
                        if
                            ?CONST_SYS_MAX_BCASH =< Money#money.cash_bind ->
                                {?error, ?TIP_COMMON_TOO_MUCH_BCASH};
                            ?true ->
                                Value2  = misc:floor(Money#money.cash_bind + Value),
                                case misc:min(Value2, ?CONST_SYS_MAX_BCASH) of
                                    Value2 ->
                                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, Value2, ?CONST_SYS_CASH_BIND),
                                        Packet      = message_api:msg_reward_add_bind_cash(Value),
                                        misc_packet:send(UserId, Packet),
                                        {
										 ?ok,
										 [{#money.cash_bind, Value2}],
										 [{?CONST_SYS_CASH_BIND, Value2}],
										 Money#money{cash_bind = Value2}
										};
                                    ?CONST_SYS_MAX_BCASH ->
                                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, ?CONST_SYS_MAX_BCASH, ?CONST_SYS_CASH_BIND),
                                        Packet      = message_api:msg_reward_add_bind_cash(Value),
                                        Packet2     = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_BCASH),
                                        misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>),
                                        {
										 ?ok,
										 [{#money.cash_bind, ?CONST_SYS_MAX_BCASH}],
										 [{?CONST_SYS_CASH_BIND, ?CONST_SYS_MAX_BCASH}],
										 Money#money{cash_bind = ?CONST_SYS_MAX_BCASH}
										}
                                end
                        end;
					?CONST_SYS_CASH_BIND_2 ->
                        if
                            ?CONST_SYS_MAX_CASH =< Money#money.cash_bind_2 ->
                                {?error, ?TIP_COMMON_TOO_MUCH_BCASH_2};
                            ?true ->
                                Value2  = misc:floor(Money#money.cash_bind_2 + Value),
                                case misc:min(Value2, ?CONST_SYS_MAX_CASH) of
                                    Value2 ->
                                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, Value2, ?CONST_SYS_CASH_BIND_2),
                                        Packet      = message_api:msg_reward_add_bind_cash_2(Value),
                                        misc_packet:send(UserId, Packet),
                                        {
										 ?ok,
										 [{#money.cash_bind_2, Value2}],
										 [{?CONST_SYS_CASH_BIND_2, Value2}],
										 Money#money{cash_bind_2 = Value2}
										};
                                    ?CONST_SYS_MAX_BCASH ->
                                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_PLUS_CURRENCY, Point, Value, ?CONST_SYS_MAX_CASH, ?CONST_SYS_CASH_BIND_2),
                                        Packet      = message_api:msg_reward_add_bind_cash_2(Value),
                                        Packet2     = message_api:msg_notice(?TIP_COMMON_TOO_MUCH_BCASH_2),
                                        misc_packet:send(UserId, <<Packet/binary, Packet2/binary>>),
                                        {
										 ?ok,
										 [{#money.cash_bind_2, ?CONST_SYS_MAX_CASH}],
										 [{?CONST_SYS_CASH_BIND_2, ?CONST_SYS_MAX_CASH}],
										 Money#money{cash_bind_2 = ?CONST_SYS_MAX_CASH}
										}
                                end
                        end;
					_ ->
						?MSG_ERROR("BAD ARG Type:~p Value:~p~n", [Type, Value]),
						{?error, ?TIP_COMMON_BAD_ARG}
				end,
			case Result of
				{?error, ErrorCode} ->
                    ?MSG_DEBUG("p1:ErrorCode=~p", [ErrorCode]),
                    PacketErr = message_api:msg_notice(ErrorCode),
                    misc_packet:send(UserId, PacketErr),
					{?error, ErrorCode};
				{?ok, DataList, MsgData, Money2} ->
					money_update(DataList, MsgData, Money2)
			end;
		{?error, ErrorCode} ->
            ?MSG_DEBUG("p3:ErrorCode=~p", [ErrorCode]),
            PacketErr2 = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, PacketErr2),
			{?error, ErrorCode}
	end;
plus_money(UserId, Type, Value, Point) when Value > 0 ->
    Value2 = erlang:round(Value),
    plus_money(UserId, Type, Value2, Point);
plus_money(_UserId, _Type, 0, _Point) ->
    ?ok;
plus_money(UserId, Type, Value, _Point) ->
	?MSG_ERROR("BAD ARG UserId:~p Type:~p Value:~p~n", [UserId, Type, Value]),
    Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
    misc_packet:send(UserId, Packet),
	{?error, ?TIP_COMMON_BAD_ARG}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 替身扣元宝特殊处理
minus_money_sp(_UserId, _Type, 0, _Point) -> {0, 0, 0};
minus_money_sp(UserId, Type, Value, Point) when Value > 0 andalso is_integer(Value) ->
    case check_money_sp(UserId, Type, Value) of
        {?ok, Money = #money{account = Account}, ?true} ->
            {Result, CashTuple} =
                case Type of
                    ?CONST_SYS_CASH ->
                        {{CashBind2, CashBind2Value}, {Cash, CashValue}} = minus_first(Value, Money#money.cash_bind_2, Money#money.cash),
                        hanele_minus_d(UserId, Point, CashValue),
                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBind2Value, CashBind2, ?CONST_SYS_CASH_BIND_2),
                        FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashValue, Cash, ?CONST_SYS_CASH),
                        log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, Cash - Money#money.cash, Cash),
                        hanele_minus_d(UserId, Point, CashBind2Value),
                        {{
                         ?ok,
                         [{#money.cash_bind_2, CashBind2}, {#money.cash, Cash}],
                         [{?CONST_SYS_CASH_BIND_2, CashBind2}, {?CONST_SYS_CASH, Cash}],
                         Money#money{cash_bind_2 = CashBind2, cash = Cash, first_consume = FirstConsume}
                        },
                        {0, CashBind2Value, CashValue}};
                    ?CONST_SYS_CASH_BIND ->
                        NewValue    = misc:floor(Money#money.cash_bind - Value),
                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_CASH_BIND),
                        {{?ok, [{#money.cash_bind, NewValue}], [{?CONST_SYS_CASH_BIND, NewValue}], Money#money{cash_bind = NewValue}},
                        {Value, 0, 0}};
                    ?CONST_SYS_CASH_ONLY ->
                        NewValue    = misc:floor(Money#money.cash - Value),
                        hanele_minus_d(UserId, Point, Value),
                        FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_CASH),
                        log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, -Value, NewValue),
                        {{?ok, [{#money.cash, NewValue}], [{?CONST_SYS_CASH, NewValue}], Money#money{cash = NewValue, first_consume = FirstConsume}},
                        {0, 0, Value}};
                    ?CONST_SYS_BCASH_FIRST ->   %%优先扣除绑定元宝
                        {{CashBind, CashBindValue}, {CashBind2, CashBind2Value}} = minus_first(Value, Money#money.cash_bind, Money#money.cash_bind_2),
                        {{Cash, CashValue}, _} = minus_first(misc:max(Value-CashBind, 0), Money#money.cash, 0),
                        hanele_minus_d(UserId, Point, CashValue),
                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBindValue, CashBind, ?CONST_SYS_CASH_BIND),
                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBind2Value, CashBind2, ?CONST_SYS_CASH_BIND_2),
                        FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashValue, Cash, ?CONST_SYS_CASH),
                        log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, Cash - Money#money.cash, Cash),
                        {{
                         ?ok,
                         [{#money.cash_bind, CashBind}, {#money.cash, Cash}, {#money.cash_bind_2, CashBind2}],
                         [{?CONST_SYS_CASH_BIND, CashBind}, {?CONST_SYS_CASH, Cash}, {?CONST_SYS_CASH_BIND_2, CashBind2}],
                         Money#money{cash_bind = CashBind, cash = Cash, cash_bind_2 = CashBind2, first_consume = FirstConsume}
                        },
                        {CashBindValue, CashBind2Value, CashValue}};
                    X ->
                        ?MSG_ERROR("~p", [X]),
                        Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                        misc_packet:send(UserId, Packet),
                        {?error, ?TIP_COMMON_BAD_ARG}
                end,
            case Result of
                {?ok, DataList, MsgData, Money2} ->
                    ?MSG_DEBUG("Money2 ~p", [Money2]),
                    money_update(DataList, MsgData, Money2),
                    CashTuple;
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
        {?ok, _Money, ?false} ->% 余额不足
            {?error,ErrorCode, TT} = 
            case Type of
                ?CONST_SYS_CASH ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
                ?CONST_SYS_CASH_BIND ->
                    {?error, ?TIP_COMMON_BIND_CASH_NOT_ENOUGH, ?CONST_SYS_CASH_BIND};
                ?CONST_SYS_CASH_BIND_2 ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
                ?CONST_SYS_BCASH_FIRST ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
				?CONST_SYS_CASH_ONLY ->
					{?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH}
            end,
            Packet = message_api:msg_sc_window(TT),
            misc_packet:send(UserId, Packet),
            {?error,ErrorCode};
        {?error, ErrorCode} ->
            Packet = message_api:msg_sc_window(?CONST_SYS_CASH),
            misc_packet:send(UserId, Packet),
            {?error, ErrorCode}
    end;
minus_money_sp(UserId, Type, Value, Point) when Value > 0 ->
    Value2 = erlang:round(Value),
    minus_money_sp(UserId, Type, Value2, Point);
minus_money_sp(UserId, Type, Value, _Point) ->
    ?MSG_ERROR("BAD ARG UserId:~p Type:~p Value:~p~n", [UserId, Type, Value]),
    Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
    misc_packet:send(UserId, Packet),
    {?error, ?TIP_COMMON_BAD_ARG}.

%% 判断金钱是否充足
%% {?ok, Money, Flag} | {?error, ErrorCode}
check_money_sp(UserId, Type, Value) ->
    case read_money(UserId) of
        {?ok, Money} ->
            case Type of
                ?CONST_SYS_CASH ->
                    {?ok, Money,
                     Value =< Money#money.cash + Money#money.cash_bind_2};
                ?CONST_SYS_CASH_BIND ->
                    {?ok, Money,
                     Value =< Money#money.cash_bind};
                ?CONST_SYS_CASH_BIND_2 ->
                    {?ok, Money,
                     Value =< Money#money.cash_bind_2};
                ?CONST_SYS_BCASH_FIRST ->
                    {?ok, Money,
                     Value =< Money#money.cash_bind + Money#money.cash + Money#money.cash_bind_2};
				?CONST_SYS_CASH_ONLY ->
					{?ok, Money,
                     Value =< Money#money.cash};
                _ -> {?error, ?TIP_COMMON_BAD_ARG}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.
 
%% 扣除金钱
%% 返回值：?ok | {?error, ErrorCode}
minus_money(_UserId, _Type, 0, _Point) -> ?ok;
minus_money(UserId, Type, Value, Point) when Value > 0 andalso is_integer(Value) ->
	case check_money(UserId, Type, Value) of
		{?ok, Money = #money{account = Account}, ?true} ->
			Result =
				case Type of
					?CONST_SYS_GOLD ->
						NewValue	= misc:floor(Money#money.gold - Value),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_GOLD),
						{?ok, [{#money.gold, NewValue}], [{?CONST_SYS_GOLD, NewValue}], Money#money{gold = NewValue}};
					?CONST_SYS_GOLD_BIND ->
						NewValue	= misc:floor(Money#money.gold_bind - Value),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_GOLD_BIND),
						{?ok, [{#money.gold_bind, NewValue}], [{?CONST_SYS_GOLD_BIND, NewValue}], Money#money{gold_bind = NewValue}};
					?CONST_SYS_CASH_ONLY ->
						NewValue    = misc:floor(Money#money.cash - Value),
                        hanele_minus_d(UserId, Point, Value),
                        FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_CASH),
                        log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, -Value, NewValue),
                        {?ok, [{#money.cash, NewValue}], [{?CONST_SYS_CASH, NewValue}], Money#money{cash = NewValue, first_consume = FirstConsume}};
					?CONST_SYS_CASH ->
                        {{CashBind2, CashBind2Value}, {Cash, CashValue}} = minus_first(Value, Money#money.cash_bind_2, Money#money.cash),
                        hanele_minus_d(UserId, Point, CashValue),
                        admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBind2Value, CashBind2, ?CONST_SYS_CASH_BIND_2),
                        FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashValue, Cash, ?CONST_SYS_CASH),
                        log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, Cash - Money#money.cash, Cash),
                        hanele_minus_d(UserId, Point, CashBind2Value),
                        {
                         ?ok,
                         [{#money.cash_bind_2, CashBind2}, {#money.cash, Cash}],
                         [{?CONST_SYS_CASH_BIND_2, CashBind2}, {?CONST_SYS_CASH, Cash}],
                         Money#money{cash_bind_2 = CashBind2, cash = Cash, first_consume = FirstConsume}
                        };
                    
%% 						NewValue	= misc:floor(Money#money.cash - Value),
%% 						FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_CASH),
%% 						log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, NewValue - Money#money.cash, NewValue),
%%                         hanele_minus_d(UserId, Point, Value),
%% 						{?ok, [{#money.cash, NewValue}], [{?CONST_SYS_CASH, NewValue}], Money#money{cash = NewValue, first_consume = FirstConsume}};
					?CONST_SYS_CASH_BIND ->
						NewValue	= misc:floor(Money#money.cash_bind - Value),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, Value, NewValue, ?CONST_SYS_CASH_BIND),
						{?ok, [{#money.cash_bind, NewValue}], [{?CONST_SYS_CASH_BIND, NewValue}], Money#money{cash_bind = NewValue}};
					?CONST_SYS_BGOLD_FIRST ->	%%优先扣除绑定铜钱
						{{GoldBind, GoldBindValue}, {Gold, GoldValue}} = minus_first(Value, Money#money.gold_bind, Money#money.gold),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, GoldBindValue, GoldBind, ?CONST_SYS_GOLD_BIND),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, GoldValue, Gold, ?CONST_SYS_GOLD),
                        {
						 ?ok,
						 [{#money.gold_bind, GoldBind}, {#money.gold, Gold}],
						 [{?CONST_SYS_GOLD_BIND, GoldBind}, {?CONST_SYS_GOLD, Gold}],
						 Money#money{gold_bind = GoldBind, gold = Gold}
						};
					?CONST_SYS_BCASH_FIRST ->	%%优先扣除绑定元宝
						{{CashBind, CashBindValue}, {CashBind2T, CashBind2ValueT}} = minus_first(Value, Money#money.cash_bind, Money#money.cash_bind_2),
%%                         ?MSG_ERROR("~p, ~p, ~p", [{CashBind, CashBindValue}, {CashBind2, CashBind2Value}, Value-CashBind-CashBind2]),
                        {Cash, CashValue, CashBind2, CashBind2Value} = 
                            if
                                CashBind2T >= 0 ->
                                    {Money#money.cash, 0, CashBind2T, CashBind2ValueT};
                                ?true ->
    						        {misc:max(Money#money.cash+CashBind2T, 0), -CashBind2T, 0, -Money#money.cash_bind_2}
                            end,
%%                         ?MSG_ERROR("~p, ~p, ~p", [{CashBind, CashBindValue}, {Cash, CashValue}, {CashBind2, CashBind2Value}]),
						hanele_minus_d(UserId, Point, CashValue),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBindValue, CashBind, ?CONST_SYS_CASH_BIND),
						admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashBind2Value, CashBind2, ?CONST_SYS_CASH_BIND_2),
						FirstConsume = admin_log_api:log_currency(UserId, Account, 0, ?CONST_LOG_MINUS_CURRENCY, Point, CashValue, Cash, ?CONST_SYS_CASH),
						log_cash(UserId, Account, ?CONST_LOG_MINUS_CURRENCY, Point, Cash - Money#money.cash, Cash),
                        {
						 ?ok,
						 [{#money.cash_bind, CashBind}, {#money.cash, Cash}, {#money.cash_bind_2, CashBind2}],
						 [{?CONST_SYS_CASH_BIND, CashBind}, {?CONST_SYS_CASH, Cash}, {?CONST_SYS_CASH_BIND_2, CashBind2}],
						 Money#money{cash_bind = CashBind, cash = Cash, cash_bind_2 = CashBind2, first_consume = FirstConsume}
						};
                    _ ->
                        Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
                        misc_packet:send(UserId, Packet),
                        {?error, ?TIP_COMMON_BAD_ARG}
				end,
			case Result of
				{?ok, DataList, MsgData, Money2} ->
					?MSG_DEBUG("Money2 ~p", [Money2]),
					money_update(DataList, MsgData, Money2);
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end;
		{?ok, _Money, ?false} ->% 余额不足
            {?error,ErrorCode, TT} = 
			case Type of
                ?CONST_SYS_GOLD ->
                    {?error, ?TIP_COMMON_GOLD_NOT_ENOUGH, ?CONST_SYS_GOLD};
                ?CONST_SYS_GOLD_BIND ->
                    {?error, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH, ?CONST_SYS_GOLD_BIND};
                ?CONST_SYS_CASH ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
                ?CONST_SYS_CASH_ONLY ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
                ?CONST_SYS_CASH_BIND ->
                    {?error, ?TIP_COMMON_BIND_CASH_NOT_ENOUGH, ?CONST_SYS_CASH_BIND};
                ?CONST_SYS_CASH_BIND_2 ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH};
                ?CONST_SYS_BGOLD_FIRST ->
                    {?error, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH, ?CONST_SYS_GOLD};
                ?CONST_SYS_BCASH_FIRST ->
                    {?error, ?TIP_COMMON_CASH_NOT_ENOUGH, ?CONST_SYS_CASH}
            end,
			Packet = message_api:msg_sc_window(TT),
            misc_packet:send(UserId, Packet),
			{?error,ErrorCode};
		{?error, ErrorCode} ->
%%             Packet = message_api:msg_notice(?TIP_COMMON_CASH_NOT_ENOUGH),
%%             misc_packet:send(UserId, Packet),
            Packet = message_api:msg_sc_window(?CONST_SYS_CASH),
            misc_packet:send(UserId, Packet),
			{?error, ErrorCode}
	end;
minus_money(UserId, Type, Value, Point) when Value > 0 ->
    Value2 = erlang:round(Value),
    minus_money(UserId, Type, Value2, Point);
minus_money(UserId, Type, Value, _Point) ->
	?MSG_ERROR("BAD ARG UserId:~p Type:~p Value:~p~n", [UserId, Type, Value]),
    Packet = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
    misc_packet:send(UserId, Packet),
	{?error, ?TIP_COMMON_BAD_ARG}.

%% 优先扣钱
minus_first(Value, Money1st, Money2nd) ->
	NewMoney1st	= Money1st - Value,
    if
		NewMoney1st >= 0 -> {{NewMoney1st, Value}, {Money2nd, 0}};
        ?true -> {{0, Money1st}, {Money2nd + NewMoney1st, - NewMoney1st}}
    end.
    
%% 判断金钱是否充足
%% {?ok, Money, Flag} | {?error, ErrorCode}
check_money(UserId, Type, Value) ->
	case read_money(UserId) of
		{?ok, Money} ->
			case Type of
				?CONST_SYS_GOLD ->
					{?ok, Money,
					 Value =< Money#money.gold};
				?CONST_SYS_GOLD_BIND ->
					{?ok, Money,
					 Value =< Money#money.gold_bind};
				?CONST_SYS_CASH ->
					{?ok, Money,
					 Value =< Money#money.cash + Money#money.cash_bind_2};
				?CONST_SYS_CASH_ONLY ->
					{?ok, Money,
					 Value =< Money#money.cash};
				?CONST_SYS_CASH_BIND ->
					{?ok, Money,
					 Value =< Money#money.cash_bind};
				?CONST_SYS_CASH_BIND_2 ->
					{?ok, Money,
					 Value =< Money#money.cash_bind_2};
				?CONST_SYS_BGOLD_FIRST ->
					{?ok, Money,
					 Value =< Money#money.gold_bind + Money#money.gold};
				?CONST_SYS_BCASH_FIRST ->
					{?ok, Money,
					 Value =< Money#money.cash_bind + Money#money.cash + Money#money.cash_bind_2};
				_ -> {?error, ?TIP_COMMON_BAD_ARG}
			end;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
insert_money(Money) ->
    ets_api:insert(?CONST_ETS_PLAYER_MONEY, Money).
lookup_money(UserId) ->
    ets_api:lookup(?CONST_ETS_PLAYER_MONEY, UserId).
lookup_element_money(UserId, Pos) ->
    ets_api:lookup_element(?CONST_ETS_PLAYER_MONEY, UserId, Pos).
update_element_money(UserId, Datas) ->
	ets_api:update_element(?CONST_ETS_PLAYER_MONEY, UserId, Datas).

insert_deposit(Datas) ->
    ets_api:insert(?CONST_ETS_PLAYER_DEPOSIT, Datas).
insert_deposit(Id, Account, Cash, Time, UserId) ->
    ets_api:insert(?CONST_ETS_PLAYER_DEPOSIT, {Id, Account, Cash, Time, UserId}).
lookup_deposit(Id) ->
    ets_api:lookup(?CONST_ETS_PLAYER_DEPOSIT, Id).
delete_deposit(Id) ->
	ets_api:delete(?CONST_ETS_PLAYER_DEPOSIT, Id).


money_update(DataList, MsgData, Money) when is_record(Money, money) ->
	update_element_money(Money#money.user_id, DataList),
	Packet = player_api:msg_player_sc_update_money(MsgData),
	misc_packet:send(Money#money.user_id, Packet),
	%%增加铜钱达成成就
	Fun = fun({?CONST_SYS_GOLD_BIND, Value}) ->
				  achievement_api:add_achievement(Money#money.user_id, ?CONST_ACHIEVEMENT_GOLD, Value, 1);
			 ({_Type, _Value}) -> ?ok
		  end,
	lists:foreach(Fun, MsgData),
	?ok.

record_money(MonsyDataList) ->
	record_money(MonsyDataList, []).
record_money([[UserId, Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold]|MonsyDataList], Acc) ->
	Money	= record_money(UserId, Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold),
	record_money(MonsyDataList, [Money|Acc]);
record_money([], Acc) -> Acc.

record_money(UserId, Account, Cash, CashSum, BCash, BCash2, BCash3, Gold, BGold) ->
	#money{
		   user_id				= UserId,			% 角色ID
		   account				= Account,			% 平台帐号
		   cash					= Cash,            	% 元宝
		   cash_sum           	= CashSum,			% 累积元宝总量
		   cash_bind          	= BCash,            % 礼券
		   cash_bind_2         	= BCash2,           % 绑定元宝
		   gold               	= Gold,				% 铜币
		   gold_bind          	= BGold,            % 绑定铜币
           cash_bind_3          = BCash3            % 保留字段
		  }.

%% 0:充值 1:游戏内部发放 2:自己购买物品 3：和其他玩家交易 4:其他
log_cash(_UserId, _Account, _OptType, _Point, 0, _Cash) -> ?ok;
log_cash(UserId, Account, OptType, Point, CashChange, Cash) ->
	try
		Type		= log_cash_type(OptType, Point),
		TypeDesc	= log_cash_type_desc(Point),
		Time		= misc:seconds(),
		player_db_mod:log_cash(UserId, Account, Type, TypeDesc, CashChange, Cash, Time)
	catch
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
log_cash_type(?CONST_LOG_PLUS_CURRENCY, ?CONST_COST_PLAYER_DEPOSIT) -> ?CONST_PLAYER_LOG_CASH_TYPE_DEPOIST;
log_cash_type(?CONST_LOG_PLUS_CURRENCY, ?CONST_COST_PLAYER_GM) -> ?CONST_PLAYER_LOG_CASH_TYPE_GAME;
log_cash_type(?CONST_LOG_PLUS_CURRENCY, _) -> ?CONST_PLAYER_LOG_CASH_TYPE_OTHER;
log_cash_type(_, _) -> ?CONST_PLAYER_LOG_CASH_TYPE_OTHER.

log_cash_type_desc(Point) ->
	case data_player:get_dictionary_cost(Point) of
		?null -> misc:to_binary(Point);
		Desc -> Desc
	end.

%%运营活动充值/消费 yunying_activity_mod:update_activity_info(200024,21,{0,30000})
check_activity_deposit_consume(UserId,Cash,Type)->
	try 
		case yunying_activity_mod:check_activity_open(Type) of
			{true,_,_} ->
				case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
					{_,_,Data,Time_S,Time_E} ->
						Now = misc:seconds(),
						case Now >= Time_S andalso Now =< Time_E of
							true ->
								yunying_activity_mod:update_activity_info(UserId,Type,{Data,Data+Cash});
							false ->
								yunying_activity_mod:update_activity_info(UserId,Type,{0,Cash})
						end;
					_ ->
						yunying_activity_mod:update_activity_info(UserId,Type,{0,Cash})
				end;
			_ ->
				next
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.


change_consume_data(UserId,Point,CashValue) ->
	case Point =/= ?CONST_COST_MARKET_ONCE andalso Point =/=?CONST_COST_MARKET_ONCE_2 
			 andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE_2
			 andalso Point =/= ?CONST_COST_GAMBLE_EXCHANGE
             andalso Point =/= ?CONST_COST_WLEFARE_BUY_FUND of
		true ->
			try 
				snow_api:check_snow_start_time(),
				admin_log_api:log_snow(UserId, CashValue/?CONST_SNOW_TICKET_PER, 1),
				case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
					[] ->
						ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=CashValue,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
						SnowInfoPacket = snow_api:msg_sc_snow_info(trunc(CashValue/?CONST_SNOW_TICKET_PER),1,0,0,[],[]),
						misc_packet:send(UserId,SnowInfoPacket);
					[SnowInfo] ->
						#snow_info{count=Count,level=Level,last_level=LastLevel,last_pos=LastPos,lighted_list=LightedList,store_list=StoreList} = SnowInfo,
						ets:insert(?CONST_ETS_SNOW_INFO, SnowInfo#snow_info{count=Count+CashValue}),
						SnowInfoPacket = snow_api:msg_sc_snow_info(trunc((Count+CashValue)/?CONST_SNOW_TICKET_PER),Level,LastLevel,LastPos,LightedList,StoreList),
						misc_packet:send(UserId,SnowInfoPacket)
				end
			catch
				throw:_Reason ->
					nil
			end;
		false ->
			nil
	end.
%% 
%% handle_return_cash(UserId, Value, Point) ->
%%     L = [?CONST_COST_BOSS_ROBOT_RETURN],
%%     case lists:member(Point, L) of
%%         ?true ->
%%             change_consume_data(UserId, Point, -Value),
%%             ok;
%%         ?false ->
%%             ok
%%     end.

%% 直接扣的部分
hanele_minus_d(UserId, Point, Value) ->
    L = [?CONST_COST_BOSS_ROBOT, ?CONST_COST_SPRING_AUTO_CASH, ?CONST_COST_PARTY_AUTO, ?CONST_COST_WORLD_SET_ROBOT],
    case lists:member(Point, L) of
        ?false ->
            change_consume_data(UserId,Point,Value),
            if
                Point =/= ?CONST_COST_MARKET_SALE andalso Point =/= ?CONST_COST_MARKET_RETURN andalso Point =/= ?CONST_COST_MARKET_ONCE
                    andalso Point =/= ?CONST_COST_MARKET_ONCE_REWARD andalso Point =/= ?CONST_COST_MARKET_ONCE_2 
                    andalso Point =/= ?CONST_COST_MARKET_ADD andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE 
                    andalso Point =/= ?CONST_COST_GET_GOODS andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE_2
                    andalso Point =/= ?CONST_COST_WLEFARE_BUY_FUND
					andalso Point =/= ?CONST_COST_GAMBLE_EXCHANGE
                    andalso Value > 0 ->
                        check_activity_deposit_consume(UserId, Value,4),                        %运营充值/消费活动检测
                        check_activity_deposit_consume(UserId, Value,14),                        %运营重复消费活动检测
						mixed_serv:add_consume(UserId, Value),                                        %合服活动--消费检测
                        welfare_deposit_api:out(UserId, Value, misc:seconds());
                ?true ->
                    ?ok
            end;
        ?true ->
            ?ok
    end,
    ok.

%% 实际操作时才扣的部分
handle_minus(UserId, Point, Value) ->
    L = [?CONST_COST_BOSS_ROBOT, ?CONST_COST_SPRING_AUTO_CASH, ?CONST_COST_PARTY_AUTO, ?CONST_COST_WORLD_SET_ROBOT],
    case lists:member(Point, L) of
        ?true ->
            change_consume_data(UserId,Point,Value),
            if
                Point =/= ?CONST_COST_MARKET_SALE andalso Point =/= ?CONST_COST_MARKET_RETURN andalso Point =/= ?CONST_COST_MARKET_ONCE
                    andalso Point =/= ?CONST_COST_MARKET_ONCE_REWARD andalso Point =/= ?CONST_COST_MARKET_ONCE_2 
                    andalso Point =/= ?CONST_COST_MARKET_ADD andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE 
                    andalso Point =/= ?CONST_COST_GET_GOODS andalso Point =/= ?CONST_COST_MARKET_NORMAL_SALE_2
                    andalso Point =/= ?CONST_COST_WLEFARE_BUY_FUND
					andalso Point =/= ?CONST_COST_GAMBLE_EXCHANGE
                    andalso Value > 0 ->
                        check_activity_deposit_consume(UserId, Value,4),                        %运营充值/消费活动检测
                        check_activity_deposit_consume(UserId, Value,14),                        %运营重复消费活动检测
						mixed_serv:add_consume(UserId, Value),                                        %合服活动--消费检测
                        welfare_deposit_api:out(UserId, Value, misc:seconds());
                ?true ->
                    ?ok
            end;
        ?false ->
            ?ok
    end,
    ok.

%% handle_plus(UserId, Point, Value) ->
%%     ok.