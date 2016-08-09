%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2014-1-20
%%% -------------------------------------------------------------------
-module(gun_award_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([login_check/4, add_gun_award/5, update_cash/3, start_link/2, get_gun_award/4, update_state/2, up_add_state_local/4]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_, _) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).
add_gun_award(UserId, Account, Index, NodeFrom, Count) ->
    gen_server:cast(?MODULE, {add_gun_award, UserId, Account, Index, NodeFrom, Count}).

get_gun_award(UserId, Account, NodeFrom, Index) ->
    gen_server:cast(?MODULE, {get_gun_award, UserId, Account, NodeFrom, Index}).

login_check(UserId, Account, NodeFrom, Index) ->
    gen_server:cast(?MODULE, {login_check, UserId, Account, NodeFrom, Index}).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    {ok, #state{}}.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_cast({add_gun_award, UserId, Account, Index, NodeFrom, Count}, State) ->
    case mysql_api:select([account, cash_total, cash_today, add_index, get_times], game_gun_cash, [{account, Account}]) of
        {ok, [[_, CashTotal, _CashToday, Index, Times]]} when Times < 1 -> %% 积累礼券服
            mysql_api:update(game_gun_cash, [{cash_total, CashTotal + Count}], [{account, Account}]),
            broad_update(Account, CashTotal + Count);
        _ ->
            Packet = gun_award_api:msg_info(?CONST_GUN_CASH_OTHER_SERVER,0,0),
            rpc:cast(NodeFrom, misc_packet, send, [UserId, Packet]),
            ok
    end,
    {noreply, State};

handle_cast({get_gun_award, UserId, Account, NodeFrom, Index}, State) ->
    case mysql_api:select([account, cash_total, cash_today, add_index, get_times, add_node, register_time], game_gun_cash, [{account, Account}]) of
        {ok, []} ->
            ok;
        {ok, [[_, _, _, _, Times,_, _]]} when Times > 0 -> %% 已领取
            Packet = gun_award_api:msg_info(?CONST_GUN_CASH_OTHER_SERVER,0,0),
            TipsPacket = message_api:msg_notice(?TIP_GUN_CASH_ALREADY_GET),
            rpc:cast(NodeFrom, misc_packet, send, [UserId, <<Packet/binary, TipsPacket/binary>>]);
        {ok, [[_, _CashTotal, _CashToday, Index, _Times, _, _]]} -> %% 积累礼券服
            ok;
        {ok, [[_, CashTotal, _CashToday, AddIndex, Times, AddNode, RegisterTime]]} when Times == 0  -> %% 可领取礼券服
            ?MSG_ERROR("AddNode is ~w Account is ~w, RegisterTime is ~w", [AddNode, Account, RegisterTime]),
            case mysql_api:update(game_gun_cash, [{get_times, 1}], [{account, Account}]) of
                {?ok, _} ->
                    Now = misc:seconds(),
                    DayDiff = misc:get_diff_days(Now, RegisterTime) + 1,
                    MaxCash = min(CashTotal, DayDiff * ?CONST_GUN_CASH_CASH_ACTIVE * 6 + 3000),
                    ?MSG_ERROR("CashTotal is ~w, DayDiff is ~w, MaxCash is ~w", [CashTotal, DayDiff, MaxCash]),
                    TipsPacket = message_api:msg_notice(?TIP_GUN_CASH_GET_SUCCESS),
                    broad_state_get(Account),
                    rpc:cast(NodeFrom, misc_packet, send, [UserId, TipsPacket]),
                    rpc:cast(NodeFrom, player_money_api, 
                             plus_money, 
                              [UserId, ?CONST_SYS_CASH_BIND, MaxCash, ?CONST_COST_GUN_CASH_AWARD]),
                    up_add_server_state(Account, AddIndex, misc:to_atom(AddNode), Index, MaxCash);
                _ ->
                    ?MSG_ERROR("udpate sql error !",[]),
                    ok
            end;
        _ ->
            ok
    end,
    {noreply, State};

handle_cast({login_check, UserId, Account, NodeFrom, Index}, State) ->
    case mysql_api:select([account, cash_total, cash_today, add_index, get_times], game_gun_cash, [{account, Account}]) of
        {ok, []} -> %% 第一个查询的服，变成积累服
            ?MSG_ERROR("User ~w is first login check ", [UserId]),
            NodeStr = misc:to_list(NodeFrom),
            mysql_api:insert(game_gun_cash, [account, cash_total, cash_today, add_index, get_times, add_node, register_time], [Account, 0, 0, Index, 0, NodeStr, misc:seconds()]),
            GunState = ?CONST_GUN_CASH_ADD_SERVER,
            CashTotal = 0,
            CashToday = 0;
        {ok, [[_, _, _, _, Times]]} when Times > 0 -> %% 已领取
            GunState = ?CONST_GUN_CASH_OTHER_SERVER,
            CashTotal = 0,
            CashToday = 0;
        {ok, [[_, CashTotal, CashToday, Index, _]]} -> %% 积累礼券服
           NodeStr = misc:to_list(NodeFrom),
            mysql_api:update(game_gun_cash, [{add_node, NodeStr}], [{account, Account}]),
            GunState = ?CONST_GUN_CASH_ADD_SERVER;
        {ok, [[_, CashTotal, CashToday, _, _]]} -> %% 可领取礼券服
            add_follow(Account, NodeFrom, UserId),
            GunState = ?CONST_GUN_CASH_SUB_SERVER
    end,
    Packet = gun_award_api:msg_info(GunState,CashTotal,CashToday),
    rpc:cast(NodeFrom, ets, insert, [?CONST_ETS_GUN_CASH_LOCAL, 
                                     #ets_gun_cash_local{account = Account, 
                                                         state = GunState, 
                                                         today_cash = CashToday, 
                                                         total_cash = CashTotal,
                                                         user_id = UserId,
                                                         last_up_time = misc:seconds()}]),
    rpc:cast(NodeFrom, misc_packet, send, [UserId, Packet]),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%%更新累计服的状态
up_add_server_state(Account, AddIndex, Node, Index, CashTotal) ->
    rpc:cast(Node, ?MODULE, up_add_state_local, [Account, AddIndex, Index, CashTotal]).

up_add_state_local(Account, AddIndex, Index, CashTotal) ->
    {_, UserId} = player_api:lookup_account_2(Account, AddIndex),
    Name = player_api:get_name(UserId),
    
    mail_api:send_interest_mail_to_one2(Name, <<"">>, <<"">>, ?CONST_MAIL_GUN_AWARD, 
                                      [{[{misc:to_list(Index)}]},{[{misc:to_list(CashTotal)}]}], [], 0, 0, 0, 0),
    Packet = gun_award_api:msg_info(?CONST_GUN_CASH_OTHER_SERVER, 0, 0),
    misc_packet:send(UserId, Packet),
    ets:update_element(?CONST_ETS_GUN_CASH_LOCAL, UserId, {#ets_gun_cash_local.state, ?CONST_GUN_CASH_OTHER_SERVER}).

broad_state_get(Account) ->
    case ets:lookup(?CONST_ETS_GUN_CASH_GLOBAL, Account) of
        [] ->
            ok;
        [Global] ->
            List = Global#ets_gun_cash_global.listen_list,
            Fun =
                fun({Node, Id}) ->
                    rpc:cast(Node, ?MODULE, update_state, [Account, Id])
                end,
            lists:foreach(Fun, List)
    end.

broad_update(Account, CashTotal) ->
    case ets:lookup(?CONST_ETS_GUN_CASH_GLOBAL, Account) of
        [] ->
            ok;
        [Global] ->
            List = Global#ets_gun_cash_global.listen_list,
            Fun =
                fun({Node, Id}) ->
                    rpc:cast(Node, ?MODULE, update_cash, [Account, Id, CashTotal])
                end,
            lists:foreach(Fun, List)
    end.

update_state(Account, Id) ->
    case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, Id) of
        [] ->
            ets:insert(?CONST_ETS_GUN_CASH_LOCAL, 
                       #ets_gun_cash_local{account = Account, 
                                           state = ?CONST_GUN_CASH_OTHER_SERVER, 
                                           user_id = Id});
        [_Local] ->
            ets:update_element(?CONST_ETS_GUN_CASH_LOCAL, Id, {#ets_gun_cash_local.state, ?CONST_GUN_CASH_OTHER_SERVER}),
            Packet = gun_award_api:msg_info(?CONST_GUN_CASH_OTHER_SERVER, 0, 0),
            misc_packet:send(Id, Packet)
    end.

update_cash(Account, Id, CashTotal) ->
    case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, Id) of
        [] ->
            ets:insert(?CONST_ETS_GUN_CASH_LOCAL, 
                       #ets_gun_cash_local{account = Account, 
                                           state = ?CONST_GUN_CASH_SUB_SERVER, 
                                           user_id = Id, 
                                           total_cash = CashTotal});
        [Local] ->
            TodayCash = Local#ets_gun_cash_local.today_cash,
            ets:update_element(?CONST_ETS_GUN_CASH_LOCAL, Id, {#ets_gun_cash_local.total_cash, CashTotal}),
            Packet = gun_award_api:msg_info(?CONST_GUN_CASH_SUB_SERVER, CashTotal, TodayCash),
            misc_packet:send(Id, Packet)
    end.


add_follow(Account, NodeFrom, UserId) ->
    case ets:lookup(?CONST_ETS_GUN_CASH_GLOBAL, Account) of
        [] ->
            ets:insert(?CONST_ETS_GUN_CASH_GLOBAL, #ets_gun_cash_global{account = Account, listen_list = [{NodeFrom, UserId}]});
        [CashGlobal] ->
            NodeList = CashGlobal#ets_gun_cash_global.listen_list,
            case lists:member({NodeFrom, UserId}, NodeList) of
                false ->
                    NewNodeList = [{NodeFrom, UserId}|NodeList],
                    ets:update_element(?CONST_ETS_GUN_CASH_GLOBAL, Account, {#ets_gun_cash_global.listen_list, NewNodeList});
                _ ->
                    ok
            end
    end.
