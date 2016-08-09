%%% 计数
-module(camp_pvp_counter_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.data.hrl").
-include("record.base.data.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, go/0]).
-export([update_node_info_cast/0, in_call/3, reset_cast/0, next_node/2, get_all_call/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}). 

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).

%% camp_pvp_counter_serv:go().
go() ->
    ets_api:insert(?CONST_ETS_CAMP_PVP_SEEDS, #ets_camp_pvp_seeds{camp_id = 0, lv = 47, power = 0, room_id = 0, serv_id = 1, user_id = 2}),
    ets_api:insert(?CONST_ETS_CAMP_PVP_SEEDS, #ets_camp_pvp_seeds{camp_id = 0, lv = 49, power = 0, room_id = 0, serv_id = 2, user_id = 3}),
    ets_api:insert(?CONST_ETS_CAMP_PVP_SEEDS, #ets_camp_pvp_seeds{camp_id = 0, lv = 48, power = 0, room_id = 0, serv_id = 2, user_id = 4}),
    ets_api:insert(?CONST_ETS_CAMP_PVP_SEEDS, #ets_camp_pvp_seeds{camp_id = 0, lv = 47, power = 0, room_id = 0, serv_id = 1, user_id = 5}),
    
    
    camp_pvp_counter_serv:in_call(1,1,48),
    camp_pvp_counter_serv:in_call(1,2,47),
    camp_pvp_counter_serv:in_call(2,3,49),
    camp_pvp_counter_serv:in_call(2,4,48),
    camp_pvp_counter_serv:in_call(1,5,47),
    camp_pvp_counter_serv:in_call(2,6,45),
%%     camp_pvp_counter_serv:in_call(7,7,40),
%%     camp_pvp_counter_serv:in_call(8,8,40),
%%     camp_pvp_counter_serv:in_call(9,9,40),
%%     camp_pvp_counter_serv:in_call(10,10,40),
%%     camp_pvp_counter_serv:in_call(11,11,40),
%%     camp_pvp_counter_serv:in_call(1,12,50),
%%     camp_pvp_counter_serv:in_call(1,13,50),
%%     camp_pvp_counter_serv:in_call(1,14,50),
%%     camp_pvp_counter_serv:in_call(1,15,50),
%%     camp_pvp_counter_serv:in_call(1,16,50),
%%     camp_pvp_counter_serv:in_call(1,17,38),
%%     camp_pvp_counter_serv:in_call(1,18,60),
    ok.

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
    process_flag(trap_exit, ?true),
    L = misc_cross:get_physical_node_info(),
    put_alive_node_list(L, []),
    put(last_room_id, 0),
	{?ok, #state{}}.

put_alive_node_list([{LeaderId, NodeList}|Tail], OldLeaderList) ->
    get_alive_node_list(NodeList, undefined, [], undefined, LeaderId),
    init_lv_phase(LeaderId),
    ets_api:insert(?CONST_ETS_CAMP_PVP_LEADER, #ets_camp_pvp_leader{leader_id = LeaderId, last_node = ?undefined}),
    put_alive_node_list(Tail, [{LeaderId, undefined}|OldLeaderList]);
put_alive_node_list([], LeaderList) ->
    LeaderList.

get_alive_node_list([{_ServId, Node}|Tail], LastNode, OldList, ?undefined, LeaderId) ->
    ets_api:insert(?CONST_ETS_CAMP_PVP_NODES, #ets_camp_pvp_nodes{key = {LeaderId, LastNode}, next = Node}),
    case lists:member(Node, OldList) of
        ?true ->
            get_alive_node_list(Tail, LastNode, OldList, ?undefined, LeaderId);
        ?false ->
            get_alive_node_list(Tail, Node, [Node|OldList], Node, LeaderId)
    end;
get_alive_node_list([{_ServId, Node}|Tail], LastNode, OldList, FirstNode, LeaderId) ->
    ets_api:insert(?CONST_ETS_CAMP_PVP_NODES, #ets_camp_pvp_nodes{key = {LeaderId, LastNode}, next = Node}),
    case lists:member(Node, OldList) of
        ?true ->
            get_alive_node_list(Tail, LastNode, OldList, FirstNode, LeaderId);
        ?false ->
            get_alive_node_list(Tail, Node, [Node|OldList], FirstNode, LeaderId)
    end;
get_alive_node_list([], _Node, List, _FirstNode, _LeaderId) ->
    List.

init_lv_phase(LeaderId) ->
    init_lv_phase(?CONST_CAMP_PVP_LV_PHASE, 1, LeaderId),
    ?ok.

init_lv_phase([{LvFrom, LvTo}|Tail], Count, LeaderId) ->
    ets_api:insert(?CONST_ETS_CAMP_PVP_LV_PHASE, 
                   #ets_camp_pvp_lv_phase{lv_phase = {LeaderId, Count}, room_list = [],
                                          lv_from = LvFrom, lv_to = LvTo}),
    init_lv_phase(Tail, Count+1, LeaderId);
init_lv_phase([], _, _) ->
    ?ok. 

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
handle_call(Request, From, State) ->
    try do_call(Request, From, State) of
		{?reply, Reply, State2} -> {?reply, Reply, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
              {?stop, Reason, State}
	end.
%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
	try do_cast(Msg, State) of
		{?noreply, State2} -> {?noreply, State2};
        {?stop, Reason, State2} -> {?stop, Reason, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
              {?stop, Reason, State}
	end.
%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	try do_info(Info, State) of
		{?noreply, State2} -> {?noreply, State2};
		{?stop, Reason, State2} ->
			{?stop, Reason, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
              {?stop, Reason, State}
	end.
%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    case Reason of
		?normal -> ?ok;
		shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
		_ ->
			?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
			?ok
	end.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call({in, ServId, UserIdList, Lv}, _From, State) ->
    case in_user(ServId, UserIdList, Lv) of
        {RoomId, Node, CampId} ->
            {?reply, {RoomId, Node, CampId}, State};
        ?error ->
            {?reply, {0, 0, 0}, State}
    end;
do_call({next_node, Node, LeaderId}, _From, State) ->
    Y = get({next_node, Node, LeaderId}),
    {?reply, Y, State};
do_call(get_all, _From, State) ->
    Y = get(),
    ?MSG_SYS("sss[~p]", [State]),
    {?reply, Y, State};
do_call(Request, _From, State) ->
    ?MSG_ERROR("Request:~p Strace:~p",[Request, erlang:get_stacktrace()]),
	Reply = ?ok,
    {?reply, Reply, State}.

do_cast(update_node_info, State) ->
    misc_cross:get_physical_node_info(),
	{?noreply, State};
do_cast(reset, _State) ->
    reset(),
    L = misc_cross:get_physical_node_info(),
    put_alive_node_list(L, []),
    erlang:erase(),
    {?noreply, #state{}};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
	{?noreply, State}.

do_info(Info, State) ->
	?MSG_ERROR("Info:~p State:~w",[Info, State]),
    {?noreply, State}.

%% 种子选手?
get_seeds(UserIdList) ->
    get_seeds(UserIdList, []).

get_seeds([UserId|Tail], OldList) ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_SEEDS, UserId) of
        #ets_camp_pvp_seeds{power = Power} ->
            get_seeds(Tail, [{UserId, Power}|OldList]);
        _ ->
            get_seeds(Tail, OldList)
    end;
get_seeds([], List) ->
    List.

%% 读取等级段id
get_lv_phase(Lv) ->
    get_lv_phase(Lv, ?CONST_CAMP_PVP_LV_PHASE, 1).

get_lv_phase(Lv, [{LvFrom, LvTo}|_Tail], Count) when LvFrom =< Lv andalso Lv =< LvTo ->
    Count;
get_lv_phase(Lv, [_|Tail], Count) ->
    get_lv_phase(Lv, Tail, Count+1);
get_lv_phase(_, [], Count) ->
    Count.

%% inner
in_user(ServId, [UserId|_] = UserIdList, Lv) ->
    case ets_api:lookup(?CONST_ETS_CROSS_USER, UserId) of
        #ets_cross_user{room_id = RoomIdT, node = NodeT, lv = OldLv, serv_id = OldServId, camp_id = CampId} -> %  已经进过
            ?MSG_ERROR("user exists:userid=[~p],serv_id=[~p|~p],lv=[~p|~p],room=[~p],node=[~p]", [UserId, OldServId, ServId, Lv, OldLv, RoomIdT, NodeT]),
            {RoomIdT, NodeT, CampId};
        _ -> % 没进过
            case get_seeds(UserIdList) of
                [] -> % 没有种子选手
                    handle_normal(ServId, UserIdList, Lv, []);
                Seeds ->
                    handle_seed(ServId, UserIdList, Lv, Seeds)
            end
    end;
in_user(ServId, UserId, Lv) ->
    in_user(ServId, [UserId], Lv).

handle_seed(ServId, UserIdList, Lv, Seeds) ->
    LeaderId = get_leader_id(ServId),
    LvPhase  = get_lv_phase(Lv),
    Key      = {LeaderId, LvPhase},
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_LV_PHASE, Key) of
        #ets_camp_pvp_lv_phase{room_list = RoomList} ->
            RoomId = select_room(RoomList),
            handle_seed_2(ServId, UserIdList, Lv, Seeds, RoomId);
        _ ->
            ?MSG_ERROR("no this key=[~p|~p]", [LeaderId, LvPhase]),
            ?error
    end.

handle_seed_2(ServId, UserIdList, Lv, Seeds, ?false) ->
    handle_normal(ServId, UserIdList, Lv, Seeds);
handle_seed_2(ServId, UserIdList, Lv, Seeds, RoomId) ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_COUNTER, RoomId) of
        #ets_camp_pvp_counter{seeds_count = SCount, seeds = SList, count = Count, node = Node, last_camp_id = LastCampId, camp_power_1 = P1, camp_power_2 = P2} ->
            Len = erlang:length(UserIdList),
            Power = calc_power(Seeds, 0),
%%             CampId = get_next_camp_id(LastCampId),
            {P1_2, P2_2, CampId} = get_next_camp_id(P1, P2, Power, LastCampId),
            ets_api:update_element(?CONST_ETS_CAMP_PVP_COUNTER, RoomId, [{#ets_camp_pvp_counter.seeds_count, SCount+erlang:length(Seeds)},
                                                                         {#ets_camp_pvp_counter.seeds,       SList++Seeds},
                                                                         {#ets_camp_pvp_counter.count,       Count+Len},
                                                                         {#ets_camp_pvp_counter.last_camp_id, CampId},
                                                                         {#ets_camp_pvp_counter.camp_power_1, P1_2},
                                                                         {#ets_camp_pvp_counter.camp_power_2, P2_2}
                                                                        ]),
            insert_cross_users(UserIdList, RoomId, Node, ServId, Lv, CampId),
            ?MSG_ERROR("user in new room=[~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p]", [UserIdList, ServId, Lv, RoomId, Node, P1, P2, P1_2, P2_2, Power, Seeds]),
            {RoomId, Node, CampId};
        _ ->
            ?MSG_ERROR("no this key=[~p|~p]", [RoomId, UserIdList]),
            ?error
    end.

calc_power([{UserId, Power}|Tail], OldPower) ->
    calc_power(Tail, OldPower+Power);
calc_power([], Power) ->
    Power.

select_room(RoomIdList) ->
    L = select(RoomIdList, []),
    ?MSG_ERROR("room:~p|~p", [RoomIdList, L]),
    select_2(L).

select([RoomId|Tail], OldList) ->
    SeedsCount = 6,
    Result = 
        case ets_api:lookup(?CONST_ETS_CAMP_PVP_COUNTER, RoomId) of
            #ets_camp_pvp_counter{seeds_count = SCount, camp_power_1 = Camp1Power, camp_power_2 = Camp2Power} ->
                IsFitDiff = is_fit_diff(Camp1Power, Camp2Power),
                if
                    SCount < SeedsCount andalso ?true =:= IsFitDiff -> % len(seed) < 6 andalso diff(power) > 20%
                        ?MSG_ERROR("!ok:select:[~p|~p|~p|~p|~p|~p]", [RoomId, SCount, Camp1Power, Camp2Power, IsFitDiff, 1]),
                        {RoomId, 1};
                    SCount =< 0 -> % len(seed) =:= 0
                        ?MSG_ERROR("!ok:select:[~p|~p|~p|~p|~p|~p]", [RoomId, SCount, Camp1Power, Camp2Power, IsFitDiff, 2]),
                        {RoomId, 2};
                    SCount >= SeedsCount andalso ?true =:= IsFitDiff -> % len(seed) >= 6 andalso diff(power) > 20%
                        ?MSG_ERROR("!ok:select:[~p|~p|~p|~p|~p|~p]", [RoomId, SCount, Camp1Power, Camp2Power, IsFitDiff, 3]),
                        {RoomId, 3};
                    SCount =< SeedsCount andalso ?false =:= IsFitDiff -> % len(seed) =< 6 andalso diff(power) =< 20%
                        ?MSG_ERROR("!ok:select:[~p|~p|~p|~p|~p|~p]", [RoomId, SCount, Camp1Power, Camp2Power, IsFitDiff, 4]),
                        {RoomId, 4};
                    ?true ->
                        ?MSG_ERROR("!ok:select:[~p|~p|~p|~p|~p|~p]", [RoomId, SCount, Camp1Power, Camp2Power, IsFitDiff, 0]),
                        ?false
                end;
            _ ->
                ?MSG_ERROR("!err:select:[~p] no this room", [RoomId]),
                ?false
        end,
    List2 = 
        case Result of
            {RoomId, Idx} ->
                case lists:keytake(RoomId, 1, OldList) of
                    {value, {_, R1}, OldList2} ->
                        [{Idx, R1++[RoomId]}|OldList2];
                    _ ->
                        [{Idx, [RoomId]}|OldList]
                end;
            _ ->
                OldList
        end,
    select(Tail, List2);
select([], List) ->
    lists:sort(fun({X, _}, {Y, _}) -> X =< Y end, List).

select_2([{_, []}|Tail]) ->
    select_2(Tail);
select_2([{_, [RoomId|_]}|_Tail]) ->
    RoomId;
select_2([]) ->
    ?false.

handle_normal(ServId, [UserId|_] = UserIdList, Lv, Seeds) ->
    LeaderId = get_leader_id(ServId),
    LvPhase  = get_lv_phase(Lv),
    Key      = {LeaderId, LvPhase},
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_LV_PHASE, Key) of
        #ets_camp_pvp_lv_phase{last_room_id = LastRoomId} ->
            case ets_api:lookup(?CONST_ETS_CAMP_PVP_COUNTER, LastRoomId) of
                #ets_camp_pvp_counter{count = Count, last_camp_id = LastCampId} when Count >= 100 ->
                    NextMaxRoomId = get_next_room_id(),
                    Len = erlang:length(UserIdList),
                    NextNode = get_next_node(LeaderId),
%%                     CampId = get_next_camp_id(LastCampId),
                    Power = calc_power(Seeds, 0),
                    {P1_2, P2_2, CampId} = get_next_camp_id(0, 0, Power, LastCampId),
                    ets_api:insert(?CONST_ETS_CAMP_PVP_COUNTER, 
                                   #ets_camp_pvp_counter{lv_phase = LvPhase, count = Len, 
                                    node = NextNode, room_id = NextMaxRoomId, seeds = Seeds, 
                                    last_camp_id = CampId, seeds_count = erlang:length(Seeds),
                                                         camp_power_1 = P1_2, camp_power_2 = P2_2}),
                    update_lv_phase(Key, NextMaxRoomId),
                    insert_cross_users(UserIdList, NextMaxRoomId, NextNode, ServId, Lv, CampId),
                    ?MSG_ERROR("user in new room=[~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p]", [UserId, UserIdList, ServId, Lv, NextMaxRoomId, NextNode, P1_2, P2_2, Power, Seeds, LastCampId, CampId]),
                    {NextMaxRoomId, NextNode, CampId};
                #ets_camp_pvp_counter{count = Count, node = Node, room_id = RoomId, last_camp_id = LastCampId, 
                                      camp_power_1 = P1, camp_power_2 = P2, seeds = OldSeeds, seeds_count = OldSCount} ->
                    Len = erlang:length(UserIdList),
%%                     CampId = get_next_camp_id(LastCampId),
                    Power = calc_power(Seeds, 0),
                    {P1_2, P2_2, CampId} = get_next_camp_id(P1, P2, Power, LastCampId),
                    ets_api:update_element(?CONST_ETS_CAMP_PVP_COUNTER, RoomId, 
                                           [
                                             {#ets_camp_pvp_counter.count, Count + Len},
                                             {#ets_camp_pvp_counter.last_camp_id, CampId},
                                             {#ets_camp_pvp_counter.seeds, OldSeeds++Seeds},
                                             {#ets_camp_pvp_counter.seeds_count, erlang:length(Seeds)+OldSCount},
                                             {#ets_camp_pvp_counter.camp_power_1, P1_2},
                                             {#ets_camp_pvp_counter.camp_power_2, P2_2}
                                           ]),
                    insert_cross_users(UserIdList, RoomId, Node, ServId, Lv, CampId),
                    ?MSG_ERROR("user in exists room=[~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p]", [UserId, UserIdList, ServId, Lv, RoomId, Node, P1_2, P2_2, Power, Seeds, LastCampId, CampId]),
                    {RoomId, Node, CampId};
                _ ->
                    NextMaxRoomId = get_next_room_id(),
                    Len = erlang:length(UserIdList),
                    NextNode = get_next_node(LeaderId),
%%                     CampId = get_next_camp_id(2),
                    Power = calc_power(Seeds, 0),
                    {P1_2, P2_2, CampId} = get_next_camp_id(0, 0, Power, 2),
                    ets_api:insert(?CONST_ETS_CAMP_PVP_COUNTER, 
                                   #ets_camp_pvp_counter{lv_phase = LvPhase, count = Len, 
                                    node = NextNode, room_id = NextMaxRoomId, seeds = Seeds, 
                                    last_camp_id = CampId, seeds_count = erlang:length(Seeds),
                                                         camp_power_1 = P1_2, camp_power_2 = P2_2}),
                    update_lv_phase(Key, NextMaxRoomId),
                    insert_cross_users(UserIdList, NextMaxRoomId, NextNode, ServId, Lv, CampId),
                    ?MSG_ERROR("user in new room=[~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p|~p]", [UserId, UserIdList, ServId, Lv, NextMaxRoomId, NextNode, P1_2, P2_2, Power, Seeds, 2, CampId]),
                    {NextMaxRoomId, NextNode, CampId}
            end;
        _ ->
            ?MSG_ERROR("no this key=[~p|~p]", [LeaderId, LvPhase]),
            ?error
    end.

%% 读取对应的leader_id
get_leader_id(Sid) ->
    case data_arena_pvp:get_cross(Sid) of
        #rec_arena_pvp_cross{camp_index = LeaderId} ->
            LeaderId;
        _ ->
            Sid
    end.

%% 更新等级段信息
update_lv_phase(Key, RoomId) ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_LV_PHASE, Key) of
        #ets_camp_pvp_lv_phase{room_list = OldRoomList} ->
            ets_api:update_element(?CONST_ETS_CAMP_PVP_LV_PHASE, Key, [{#ets_camp_pvp_lv_phase.room_list, [RoomId|OldRoomList]},
                                                                       {#ets_camp_pvp_lv_phase.last_room_id, RoomId}]);
        _ ->
            ok
    end.

%% 
insert_cross_users([UserId|Tail], RoomId, Node, ServId, Lv, CampId) ->
    ets_api:insert(?CONST_ETS_CROSS_USER, #ets_cross_user{room_id = RoomId, user_id = UserId, node = Node, serv_id = ServId, lv = Lv, camp_id = CampId}),
    insert_cross_users(Tail, RoomId, Node, ServId, Lv, CampId);
insert_cross_users([], _RoomId, _Node, _ServId, _Lv, _CampId) -> 
    ?ok.
    
reset() ->
    ets:delete_all_objects(?CONST_ETS_CROSS_USER),
    ets:delete_all_objects(?CONST_ETS_CAMP_PVP_COUNTER),
    ets:delete_all_objects(?CONST_ETS_CAMP_PVP_LEADER),
    ets:delete_all_objects(?CONST_ETS_CAMP_PVP_LV_PHASE),
    ets:delete_all_objects(?CONST_ETS_CAMP_PVP_NODES).

%% 获取全局最后一个room_id
get_next_room_id() ->
    case get(last_room_id) of
        ?undefined ->
            put(last_room_id, 1),
            1;
        Id ->
            NextId = get_next_room_id(Id),
            put(last_room_id, NextId),
            NextId
    end.
get_next_room_id(Id) when Id >= 999 ->
    1;
get_next_room_id(Id) ->
    Id + 1.

get_next_node(LeaderId) ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_LEADER, LeaderId) of
        #ets_camp_pvp_leader{last_node = LastNode} ->
            case ets_api:lookup(?CONST_ETS_CAMP_PVP_NODES, {LeaderId, LastNode}) of
                #ets_camp_pvp_nodes{next = NextNode} ->
                    ets_api:update_element(?CONST_ETS_CAMP_PVP_LEADER, LeaderId, [{#ets_camp_pvp_leader.last_node, NextNode}]),
                    NextNode;
                _ ->
                    LastNode
            end;
        _ ->
            node()
    end.

get_next_camp_id(1) -> 2;
get_next_camp_id(2) -> 1.

get_next_camp_id(P1, P2, 0,     OldCampId)  ->              {P1, P2, get_next_camp_id(OldCampId)};
get_next_camp_id(P1, P2, Power, _OldCampId) when P1 > P2 -> {P1, P2+Power, 2};
get_next_camp_id(P1, P2, Power, _OldCampId) ->              {P1+Power, P2, 1}.

%% 差值大于20%?
is_fit_diff(X, Y) ->
    X2 = 
        if
            X =< 0 ->
                1;
            ?true ->
                X
        end,
    Y2 = 
        if
            Y =< 0 ->
                1;
            ?true ->
                Y
        end,
    Diff = erlang:abs(X2-Y2),
    Min  = misc:min(X2, Y2),
    (Diff / Min) > 0.2.

%% API
update_node_info_cast() ->
    gen_server:cast(?MODULE, update_node_info).

%% camp_pvp_counter_serv:in_call(1,1,30).
in_call(ServId, UserIdList, Lv) ->
    gen_server:call(?MODULE, {in, ServId, UserIdList, Lv}, infinity). %?CONST_TIMEOUT_CALL).

reset_cast() ->
    gen_server:cast(?MODULE, reset).

next_node(Node, LeaderId) ->
    gen_server:call(?MODULE, {next_node, Node, LeaderId}, ?CONST_TIMEOUT_CALL).

get_all_call() ->
    gen_server:call(?MODULE, get_all, ?CONST_TIMEOUT_CALL).
