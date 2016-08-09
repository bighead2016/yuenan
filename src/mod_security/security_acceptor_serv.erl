%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(security_acceptor_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/4]).
%% gen_server callbacks
-export([init/1,handle_call/3, handle_cast/2, handle_info/2,terminate/2,code_change/3]).

-record(state, {socket, ref, cores, times}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores, _N, ListenSocket) ->
	gen_server:start_link({local, ServName}, ?MODULE, [ListenSocket], []).


%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {?ok, State}          |
%%          {?ok, State, Timeout} |
%%          ignore                |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([ListenSocket]) ->
	State	= #state{socket = ListenSocket},
	case accept(State) of
		{?noreply, State2} ->
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
			State = #state{socket = ListenSocket, ref = Ref}) ->
	Pid		= spawn(fun() -> send_policy(Socket) end),
	case gen_tcp:controlling_process(Socket, Pid) of
		?ok	-> ?ok;
		{?error, _Reason} -> ?ok
	end,
	accept(State);
handle_info({inet_async, ListenSocket, Ref, {?error, closed}},
            State = #state{socket = ListenSocket, ref = Ref}) ->
    {?stop, ?normal, State};
handle_info({inet_async, ListenSocket, Ref, {?error, _Error}},
            State = #state{socket = ListenSocket, ref = Ref}) ->
	{?stop, ?normal, State};

handle_info({'EXIT', Port, ?normal}, State) when is_port(Port)->
	{?noreply, State};
handle_info({'EXIT', _Pid, _Reason}, State) ->
	{?noreply, State};
handle_info(stop, State) ->
    {?stop, ?normal, State};
handle_info(_Info, State) ->
    {?noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
    ListenSocket   = State#state.socket,
    % 把Socket断开
    try
        gen_tcp:close(ListenSocket)
    catch
        _Any1:_Any2 -> ?ok
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
        {?ok, Ref}	-> {?noreply, State#state{ref = Ref}}; 
        Error		->
			{?stop, {cannot_accept, Error}, State}
    end.

send_policy(Socket) ->
	try
		?ok	= misc_app:send_fast(Socket, ?SECURITY),
		?ok	= gen_tcp:close(Socket)
	catch
		_Error:_Reason -> ?ok
	end.