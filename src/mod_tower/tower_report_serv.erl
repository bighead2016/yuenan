%%% 战报
-module(tower_report_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, update_report_cast/5]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {center_node = ?undefined}).

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
	Node = node(),
	CenterNode = center_api:get_center_node(),
	case CenterNode of
		Node ->
			{ok, #state{}};
		_ ->
			erlang:send_after(?CONST_TOWER_INTERVAL_TIME, self(), {sync_data}),
			erlang:send({?MODULE, CenterNode}, {get_data, Node}),
			{ok, #state{center_node = CenterNode}}
	end.

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
    catch _:_ -> {?reply, {?error}, State}
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
        {?noreply, State2} -> {?noreply, State2}
    catch _:_ -> {?noreply, State}
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
        {?noreply, State2} -> {?noreply, State2}
    catch _:_ -> {?noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
    ?ok.

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
do_call(Request, _From, State) ->
    Reply = ?ok,
    ?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast({update_report_idx, CampId, UserId, Pro, ReportId, EtsReport}, #state{center_node = CenterNode} = State) ->
	gen_server:cast({?MODULE, CenterNode}, {update_report_center, CampId, UserId, Pro, ReportId, EtsReport}),
	tower_mod_report:ets_insert_report(EtsReport),
    tower_mod_report:update_report_idx_cb(CampId, UserId, Pro, ReportId),
    {?noreply, State};
do_cast({update_report_center, CampId, UserId, Pro, ReportId, EtsReport}, State) ->
	tower_mod_report:ets_insert_report(EtsReport),
	tower_mod_report:update_report_idx_cb(CampId, UserId, Pro, ReportId),
	{?noreply, State};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
    {?noreply, State}.

%% 请求中心节点同步数据
do_info({sync_data}, #state{center_node = CenterNode} = State) ->
	erlang:send_after(?CONST_TOWER_INTERVAL_TIME, self(), {sync_data}),
	erlang:send({?MODULE, CenterNode}, {get_data, node()}),
	{?noreply, State};
%% 中心节点同步数据到本地节点
do_info({get_data, FromNode}, State) ->
	Rand = misc:rand(1, 300),
	erlang:send_after(Rand * 1000, self(), {get_data, rand, FromNode}),
	{?noreply, State};
do_info({get_data, rand, FromNode}, State) ->
	List = tower_mod_report:ets_report_list(),
	IndexList = tower_mod_report:ets_report_idx_list(),
	erlang:send({?MODULE, FromNode}, {sync_data, List, IndexList}),
	erlang:garbage_collect(),
	{?noreply, State};
%% 本地节点存储中心节点数据
do_info({sync_data, List, IndexList}, State) ->
	ets:delete_all_objects(?CONST_ETS_TOWER_REPORT),
	tower_mod_report:ets_insert_report(List),
	ets:delete_all_objects(?CONST_ETS_TOWER_REPORT_IDX),
	tower_mod_report:ets_insert_report_idx(IndexList),
	erlang:garbage_collect(),
	{?noreply, State};
do_info(Info, State) ->
    ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.

update_report_cast(CampId, UserId, Pro, ReportId, EtsReport) ->
    gen_server:cast(?MODULE, {update_report_idx, CampId, UserId, Pro, ReportId, EtsReport}).
