%%% -------------------------------------------------------------------
%%% Author  : PXR
%%% Description :
%%%
%%% Created : 2013-8-20
%%% -------------------------------------------------------------------
-module(cross_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
-include("const.tip.hrl").
-include("record.base.data.hrl").
-include("record.map.hrl").
-include("const.protocol.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, generate_seeds_info/1, update_global/1,send_local_team_to_master/1, broad_team_global/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SEED_SQL, "select game_user.user_id, power,game_user.lv  from game_player_rank, game_user where game_user.user_id = game_player_rank.user_id and game_user.lv > 30 and logout_time_last > ~w order by power desc;").

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================

start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).
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
    init_cross_config_from_db(),
    erlang:send_after(60*60*1000, self(), check_event),
    erlang:send_after(1000, self(), broad_team),
    erlang:send_after(60*1000, ?MODULE, check_self_node_config),
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
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(broad_team, State) ->
    erlang:send_after(1000, self(), broad_team),
    Master = cross_api:get_master_node(),
    send_local_team_to_master(Master),
    Self = node(),
    case Master == Self of
        true ->
            broad_team_global();
        _ ->
            ok
    end,
    {noreply, State};

handle_info(check_event, State) ->
    erlang:send_after(60*60*1000, self(), check_event),
    {H,_,_} = time(),
    generate_seeds_info(H),
    {noreply, State};

handle_info(check_self_node_config, State) ->
    NodeName = node(),
    Index = cross_api:get_self_index(),
    MasterNode = cross_api:get_master_node(),
    case ets:lookup(?CONST_ETS_NODES_CONFIG, Index) of
        [#cross_node_config{node_name = NodeName}] ->
            ok;
        _ ->
            ?MSG_ERROR("self node info not asy with master node!!!", []),
            rpc:cast(MasterNode, cross_api, add_node_2_master, [#cross_node_config{server_index = Index, node_name = atom_to_list(NodeName), update_time = Index}]),
            %% check is asy success after 1 hour time
            erlang:send_after(60*60*1000, ?MODULE, check_self_node_config)
    end,
    {noreply, State};

handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
    ?MSG_ERROR("cross server terminate!!!, reason is ~w", [Reason]),
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

send_local_team_to_master(Master) ->
    TeamList = ets:tab2list(?CONST_ETS_TEAM_CROSS_LOCAL),
    rpc:cast(Master, ets, insert, [?CONST_ETS_TEAM_CROSS_MASTER, TeamList]).

update_global(TeamList) ->
    ets:delete_all_objects(?CONST_ETS_TEAM_CROSS_GLOBAL),
    ets:insert(?CONST_ETS_TEAM_CROSS_GLOBAL, TeamList).

broad_team_global() ->
    TeamList = ets:tab2list(?CONST_ETS_TEAM_CROSS_MASTER),
    ets:delete_all_objects(?CONST_ETS_TEAM_CROSS_MASTER),
    NodeList = ets:tab2list(?CONST_ETS_NODES_CONFIG),
    Fun = 
        fun(#cross_node_config{node_name = NodeName}) ->
                Node = list_to_atom(NodeName),
                rpc:cast(Node, ?MODULE, update_global, [TeamList])
        end,
    lists:foreach(Fun, NodeList).
    

generate_seeds_info(H) ->
    Now = misc:seconds(),
    LastTime = Now - 3 * ?CONST_SYS_ONE_DAY_SECONDS,
    Index = cross_api:get_self_index(),
    CampMaster = cross_api:get_camp_node(),
    Master = cross_api:get_master_node(),
    SelfNode = node(),
    case H  of
        13 ->
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_SEEDS);
        14 ->
            Sql = io_lib:format(?SEED_SQL, [LastTime]),
            case mysql_api:select(Sql) of
                {ok, Datas} ->
                    Fun =
                        fun([UserId, Power, Lv]) ->
                                #ets_camp_pvp_seeds{user_id = UserId, power = Power, lv = Lv, serv_id = Index}
                        end,
                    Result = lists:map(Fun, Datas),
                    
                    rpc:cast(CampMaster, ets, insert, [?CONST_ETS_CAMP_PVP_SEEDS, Result]);
                _ ->
                    ok
            end;
        15 when SelfNode == CampMaster ->
            DataList = ets:tab2list(?CONST_ETS_CAMP_PVP_SEEDS),
            ets:delete_all_objects(?CONST_ETS_CAMP_PVP_SEEDS),
            LvList = ?CONST_CAMP_PVP_LV_PHASE,
            Fun =
                fun({B,E}) ->
                        FilterFun =
                            fun(#ets_camp_pvp_seeds{lv = Lv}) ->
                                    Lv >= B andalso Lv =< E
                            end,
                        SeedList = lists:filter(FilterFun, DataList),
                        SortFun =
                            fun(#ets_camp_pvp_seeds{power = Power1}, #ets_camp_pvp_seeds{power = Power2}) ->
                                    Power1 > Power2
                            end,
                        SortedList = lists:sort(SortFun, SeedList),
                        SeedCount = length(SeedList),
                        SeedLimit = max(6, round(SeedCount * 0.03)),
                        LimitList = lists:sublist(SortedList, SeedLimit),
                        ets:insert(?CONST_ETS_CAMP_PVP_SEEDS, LimitList)
                end,
            lists:foreach(Fun, LvList);
        16 when SelfNode == CampMaster ->
            SeedList = ets:tab2list(?CONST_ETS_CAMP_PVP_SEEDS),
            rpc:cast(Master, ets, insert, [?CONST_ETS_CAMP_PVP_SEEDS, SeedList]);
        _ ->
            ok
    end.

init_cross_config_from_db() ->
    case mysql_api:select("select node_name, node_index, update_time  from game_cluster_node_config") of
        {ok, ConfigList} ->
            init_cross_config_from_db(ConfigList);
        _ ->
            ?MSG_ERROR("init cross config from db failed!!!", [])
    end.

init_cross_config_from_db([]) ->
    ok;
init_cross_config_from_db([Config|RestConfig]) ->
    [Name, Index, Time] = Config,
    ets:insert(?CONST_ETS_NODES_CONFIG, #cross_node_config{node_name = binary_to_list(Name), server_index = Index, update_time = Time}),
    init_cross_config_from_db(RestConfig).