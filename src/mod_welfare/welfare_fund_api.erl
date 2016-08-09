%%% 基金活动

-module(welfare_fund_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([buy_fund/2, get_dividend/1, login_packet/2, init/0, login/1, logout/1,
         refresh_zero/1]).

%%
%% API Functions
%%

%% 登陆处理
login_packet(Player, OldPacket) ->
    case get_dividend(Player) of
        {?ok, Player2, Packet} ->
            {Player2, <<OldPacket/binary, Packet/binary>>};
        {?error, _ErrorCode} ->
            {Player, OldPacket}
    end.

%% 0点刷新
refresh_zero(Player) ->
    case get_dividend(Player) of
        {?ok, Player2, Packet} ->
            {Player2, Packet};
        {?error, _ErrorCode} ->
            {Player, <<>>}
    end.

%% 初始化数据结构
init() ->
    [].

login(Player) ->
    Sql = <<"select `fund` from `game_fund` where `user_id` = '", (misc:to_binary(Player#player.user_id))/binary, "'">>,
    case mysql_api:select(Sql) of
        {?ok, [FundDataList]} ->
            FundDataList2 = mysql_api:decode(FundDataList),
            Player#player{fund = FundDataList2};
        {?ok, []} ->
            Player#player{fund = []};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

logout(Player) ->
    FundDataList = Player#player.fund,
    mysql_api:insert(<<"replace into `game_fund` (`user_id`,`fund`) values ('", 
                       (misc:to_binary(Player#player.user_id))/binary, "', ", 
                       (mysql_api:encode(FundDataList))/binary, " )">>),
    ok.

%% 购买基金
buy_fund(Player, Type) ->
    try
        RecFund = get_fund(Type),
        check_fund(Player, RecFund),
        case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH_ONLY, RecFund#rec_fund.in, ?CONST_COST_WLEFARE_BUY_FUND) of
            ?ok ->
                ?ok;
            _ ->
                throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
        end,
        Player2 = add_fund(Player, RecFund),
		Packet = welfare_api:msg_sc_jj_state(Type, 1),
		PacketTip   = message_api:msg_notice(?TIP_WELFARE_BUY_OK),
		PacketTip2 = 
			case Type of 
				1 ->
					message_api:msg_notice(?TIP_WELFARE_MAKE_DEAL1);
				2 ->
					message_api:msg_notice(?TIP_WELFARE_MAKE_DEAL2);
				3 ->
					message_api:msg_notice(?TIP_WELFARE_MAKE_DEAL3);
				4 ->
					message_api:msg_notice(?TIP_WELFARE_MAKE_DEAL4)
			end,
		misc_packet:send(Player2#player.user_id, <<PacketTip/binary, Packet/binary,PacketTip2/binary>>),
		{?ok, Player2}
	catch
        throw:{?error, ErrorCode} ->
            {?error, ErrorCode};
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_WELFARE_NX_FUND}
    end.

%% 分红
get_dividend(Player) ->
    try
        FundDataList = Player#player.fund,
        Date = misc:date_num(),
        {?ok, Player2, Packet} = get_dividend(Player, FundDataList, Date, [], <<>>),
        P = pack_all(Player2),
        {?ok, Player2, <<P/binary, Packet/binary>>}
%%         misc_packet:send(Player#player.user_id, Packet),
%%         {?ok, Player2}
    catch
        throw:{?error, ErrorCode} ->
            ?MSG_DEBUG("1[~p]", [ErrorCode]),
            {?error, ErrorCode};
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_WELFARE_NX_FUND}
    end.

pack_all(Player) ->
    FundDataList = Player#player.fund,
    pack_all_2(FundDataList, <<>>).
pack_all_2([#fund_data{type = Type}|Tail], OldPacket) ->
    Packet = welfare_api:msg_sc_jj_state(Type, 1),
    pack_all_2(Tail, <<OldPacket/binary, Packet/binary>>);
pack_all_2([], Packet) ->
    Packet.

get_dividend(Player, [#fund_data{returned_times = Ret, start_time = StartDate, type = Type} = FundData|Tail], Date, OldList, OldPacket) ->
    RecFund = get_fund(Type),
    Diff = get_diff_days(StartDate, Date, Ret),
    {RetTimes, NewRet} = get_ret_times(Diff, Ret, RecFund#rec_fund.days),
    ?MSG_DEBUG("1[~p|~p|~p|~p]", [{RetTimes, NewRet}, Diff, Ret, RecFund#rec_fund.days]),
    Return = trunc(RecFund#rec_fund.out_per_day * RetTimes),
%%     player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH_BIND_2, Return, ?CONST_COST_WELFARE_DIVIDEND),
    Info = Player#player.info,
    ReturnM = make_mail_mark(RecFund#rec_fund.out_per_day),
    if
        Return > 0 ->
            MailId = get_mail_id(Type),
            send_n_main(Info#info.user_name, <<>>, <<>>, MailId, ReturnM, RecFund#rec_fund.days-Ret-1, ?CONST_COST_WELFARE_DIVIDEND, RecFund#rec_fund.out_per_day, RetTimes);
        ?true ->
            ok
    end,
    if
        NewRet >= RecFund#rec_fund.days ->
            get_dividend(Player, Tail, Date, OldList, OldPacket);
        ?true ->
            get_dividend(Player, Tail, Date, [FundData#fund_data{returned_times = NewRet}|OldList], OldPacket)
    end;
get_dividend(Player, [], _, List, OldPacket) ->
    {?ok, Player#player{fund = List}, OldPacket};
get_dividend(Player, ?null, _, List, OldPacket) ->
    {?ok, Player#player{fund = List}, OldPacket}.

get_mail_id(1) -> 2900;
get_mail_id(2) -> 2901;
get_mail_id(3) -> 2902;
get_mail_id(4) -> 2903.

send_n_main(Name, Title, Cont, Type, M1, Days, Point, Return, Times) when Times > 0 ->
    DaysM = make_mail_mark(Days),
    mail_api:send_interest_mail_to_one3(Name, Title, Cont, Type, M1++DaysM, [], 0, 0, 0, ?CONST_COST_WELFARE_DIVIDEND, Return),
    send_n_main(Name, Title, Cont, Type, M1, Days-1, Point, Return, Times-1);
send_n_main(_Name, _Title, _Cont, _Type, _M, _, _Point, _Return, _) ->
    ok.

get_diff_days(StartDate, Date, Ret) ->
    X = misc:date_to_seconds(StartDate),
    Y = misc:date_to_seconds(Date),
    Diff = erlang:trunc((Y - X)/60/60/24) - Ret,
    if
        Diff =< 0 ->
            0;
        ?true ->
            Diff
    end.

get_ret_times(_T1, _T2, T3) when T3 =< 0 -> {0, T3};
get_ret_times(T1, T2, T3) when T2 =< T3 andalso T1 =< T3 - T2 -> {T1, T2 + T1};
get_ret_times(_T1, T2, T3) when T2 =< T3 -> {T3-T2, T3};
get_ret_times(_T1, _T2, T3) -> {0, T3}.

get_fund(Type) ->
    case data_welfare:get_fund(Type) of
        #rec_fund{} = RecFund ->
            RecFund;
        _ ->
            throw({?error, ?TIP_WELFARE_NX_FUND})
    end.

check_fund(Player, RecFund) ->
    FundDataList = Player#player.fund,
    UserId = Player#player.user_id,
    check_money(UserId, RecFund#rec_fund.in),
    case lists:keyfind(RecFund#rec_fund.type, #fund_data.type, FundDataList) of
        #fund_data{} ->
            throw({?error, ?TIP_WELFARE_HAD_BOUGHT});
        ?false ->
            ?ok
    end.

%% 检查元宝
check_money(UserId, In) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_CASH, In) of
        {?ok, _, ?true} ->
            ok;
        _ ->
            throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
    end.

%% 
add_fund(Player, RecFund) ->
    FundDataList = Player#player.fund,
    NewFundData = record_fund(RecFund),
    NewFundDataList = 
        case lists:keyfind(RecFund#rec_fund.type, #fund_data.type, FundDataList) of
            {_} ->
                FundDataList;
            ?false ->
                [NewFundData|FundDataList]
        end,
    Player#player{fund = NewFundDataList}.


%%
%% Local Functions
%%
record_fund(#rec_fund{in = In, type = Type}) ->
    Now = misc:date_num(),
    #fund_data{in = In, returned_times = 0, start_time = Now, type = Type}.

make_mail_mark(Value) ->
    [{[{misc:to_list(Value)}]}].