%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(gateway_acceptor_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/4,switch_cast/1,show_cast/1]).
%% gen_server callbacks
-export([init/1,handle_call/3, handle_cast/2, handle_info/2,terminate/2,code_change/3, stop/1]).

-record(state, {socket, ref, cores, times, switch}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, Cores, N, ListenSocket) ->
	misc_app:gen_server_start_link(ServName, ?MODULE, [Cores, N, ListenSocket], Cores, N).


%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {?ok, State}          |
%%          {?ok, State, Timeout} |
%%          ignore                |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([Cores, N, ListenSocket]) ->
	%% 
	process_flag(trap_exit, ?true),
	%% 随机数种子
	?RANDOM_SEED,
	State	= #state{socket = ListenSocket, cores = Cores, times = N, switch = ?false},
	case accept(State) of
		{?noreply, State2} ->
			?MSG_PRINT(" Server Start On Core:~p",[erlang:system_info(scheduler_id)]),
			{?ok, State2};
		{?stop, Reason, _State2} ->
			{?stop, Reason}
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
handle_call(_Request, _From, State) ->
    Reply = ?ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(show, State) ->
	?MSG_PRINT("~nState:~p~n ",[State]),
	{noreply, State};
handle_cast({switch, Switch}, State) ->
	{noreply, State#state{switch = Switch}};
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({inet_async, ListenSocket, Ref, {?ok, Socket}},
            State = #state{socket = ListenSocket, ref = Ref, cores = Cores, times = Times, switch = Switch}) ->
	case Switch of
		?true ->
			case gateway_worker_sup:start_child_gateway_worker_serv(Cores, Times, Socket, ListenSocket) of
				{?ok, Pid} ->
					try ?ok	= gen_tcp:controlling_process(Socket, Pid)
					catch Error:Reason -> {Error, Reason} % ?MSG_ERROR("Error:~p Reason:~p~n", [Error, Reason])
					end,
					accept(State#state{times = Times + 0.5});
				_ ->
					gen_tcp:close(Socket),
					accept(State#state{times = Times + 1})
			end;
		?false ->
			gen_tcp:close(Socket),
			accept(State#state{times = Times + 1})
	end;
handle_info({inet_async, ListenSocket, Ref, {?error, closed}},
            State = #state{socket = ListenSocket, ref = Ref}) ->
    {?stop, ?normal, State};
handle_info({inet_async, ListenSocket, Ref, {?error, Error}},
            State = #state{socket = ListenSocket, ref = Ref}) ->
	?MSG_ERROR("Error:~p",[Error]),
	{?stop, ?normal, State};

handle_info({'EXIT', Port, ?normal}, State) when is_port(Port)->
	{?noreply, State};
handle_info({'EXIT', Pid, Reason}, State) ->
	?MSG_ERROR("EXIT	Pid:~p   Reason:~p",[Pid, Reason]),
	{?noreply, State};
handle_info(stop, State) ->
    {?stop, ?normal, State};
handle_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p",[Info,State]),
    {?noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
    ListenSocket   = State#state.socket,
    % 把Socket断开
    try ?ok	= gen_tcp:close(ListenSocket)
    catch Any1:Any2 -> ?MSG_ERROR("Error Any1:~p Any2:~p",[Any1,Any2])
    end,
    ?ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {?ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 异步接受Socket连接
accept(State = #state{socket = ListenSocket}) ->
    case prim_inet:async_accept(ListenSocket, -1) of
        {?ok, Ref}	->
			{?noreply, State#state{ref = Ref}}; 
        Error		->
			?MSG_ERROR("prim_inet:async_accept Error:~p~n",[Error]),
			{?stop, Error, State}
    end.

switch_cast(Switch) ->
    Cores = erlang:system_info(schedulers),
    L = lists:seq(1, Cores),
    switch_cast(Switch, L).
switch_cast(Switch, [Core|Tail]) ->
    Name = misc:to_atom(lists:concat([?MODULE, "_", Core])),
	gen_server:cast(Name, {switch, Switch}),
    switch_cast(Switch, Tail);
switch_cast(?false, []) ->
    NetPid = ets:first(?CONST_ETS_NET),
    gateway_worker_serv:stop(NetPid),
    stop_net(NetPid);
switch_cast(_Switch, []) ->
    ok.

stop_net(NetPid) ->
    case ets:next(?CONST_ETS_NET, NetPid) of
        '$end_of_table' ->
            ok;
        NetPid2 ->
            gateway_worker_serv:stop(NetPid),
            stop_net(NetPid2)
    end.

show_cast(Pid) ->
	gen_server:cast(Pid, show).

stop(Pid) ->
    misc:send_to_pid(Pid, stop).

