%%% -------------------------------------------------------------------
%%% Author  : michael
%%% Description : admin server
%%%
%%% Created : 2012-10-13
%%% -------------------------------------------------------------------
-module(admin_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").

-record(state, {socket, pid}).
%% --------------------------------------------------------------------
%% External exports
-export([start_link/4]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores, ListenSocket, Socket) ->
	misc_app:gen_server_start_link(?MODULE, [ListenSocket, Socket]).

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
init([ListenSocket, Socket]) ->
	set_socket(ListenSocket, Socket),
	process_flag(trap_exit, ?true),
	Pid 	= self(),
    State 	= #state{socket = Socket, pid = Pid},
	spawn_link(fun() -> gm_work(State) end),
	{?ok, State}.

set_socket(ListenSocket, Socket) ->
	{?ok, Mod} = inet_db:lookup_socket(ListenSocket),
	?true 	   = inet_db:register_socket(Socket, Mod),
	case prim_inet:getopts(ListenSocket, [active, nodelay, keepalive, delay_send, priority, tos]) of
		{?ok, Opts} ->  
			case prim_inet:setopts(Socket, [{recbuf, ?CONST_MAX_ADMIN_PACKET},   % recbuf控制接收时的缓冲区大小
                                            {packet_size, ?CONST_MAX_ADMIN_PACKET}|Opts]) of
				?ok -> ?ok;
				?error -> gen_tcp:close(Socket), ?error
			end;
		?error -> gen_tcp:close(Socket), ?error
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
    {?reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    try do_cast(Msg, State) of
		{?noreply, State2} -> 
			{?noreply, State2};
        {?stop, Reason, State3} -> 
			{?stop, Reason, State3}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State}
	end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({confirm_delivery,UserID,Args},State) ->
	mod_tencent:confirm_delivery(UserID,Args),
	{?noreply, State};

handle_info(_Info, State) ->
	{?noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(?normal, _State) ->
	?ok;
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

do_cast(close, State) ->
	{?stop, ?normal, State};
do_cast(_Msg, State) ->
	{?noreply, State}.

gm_work(#state{pid = Pid, socket = Socket}) ->
	gen_tcp:controlling_process(Socket, Pid),
	Ip = misc:ip(Socket),
	case admin_mod:check_ip(Ip) of
		?true ->
		    case admin_mod:http_recv(Socket) of
		        {?ok, Data} ->
					?MSG_DEBUG("ADMIN DATA:~p IP:~p", [Data, Ip]),
					case admin_mod:treat_http_request(Socket, Data) of
						?ok ->
							gen_tcp:close(Socket),
							close_cast(Pid);
						{?error, Reason} ->
							?MSG_ERROR("Data:~p Reason:~p", [Data, Reason]),
							gen_tcp:close(Socket),
							close_cast(Pid),
							?error
					end;
		        {?error, {?error, 'closed'}} ->
                    gen_tcp:close(Socket),
                    close_cast(Pid),
                    ?error;
		        {?error, Reason} ->
					?MSG_ERROR("Reason:~p", [Reason]),
					gen_tcp:close(Socket),
					close_cast(Pid),
					?error
		    end;
		?false ->
			?MSG_ERROR("The request from ~p is not in the white ip list", [Ip]),
			close_cast(Pid),
			?error
	end.

close_cast(Pid) ->
	gen_server:cast(Pid, close).
