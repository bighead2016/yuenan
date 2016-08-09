%% Author: Administrator
%% Created: 2013-5-24
%% Description: TODO: Add description to relation_serv
-module(relation_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.data.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
		 relation_be_add_cast/3,
		 relation_be_del_cast/3,
		 logout_cast/1
		 ]).

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
	process_flag(trap_exit, ?true),
	% 随机数种子
	?RANDOM_SEED,
	{?ok, #state{}}.

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
terminate(?normal, _State) -> ?ok;
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
    ?MSG_ERROR("Request:~p Strace:~p",[Request, erlang:get_stacktrace()]),
	Reply = ?ok,
    {?reply, Reply, State}.

do_cast({relation_be_add,UserId,MemId,Type}, State) ->
	relation_mod:add_relation_handle(UserId,MemId,Type),
	{?noreply, State};

do_cast({relation_be_del,UserId,MemId,Type}, State) ->
	relation_mod:del_relation_handle(UserId,MemId,Type),
	{?noreply, State};

do_cast({logout,UserId}, State) ->
	relation_api:logout_handle(UserId), 
	{?noreply, State};

do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
	{?noreply, State}.

do_info(Info, State) ->
	?MSG_ERROR("Info:~p State:~w",[Info, State]),
    {?noreply, State}.

relation_be_add_cast(UserId,MemId,Type) ->
	Pid = get_pid(UserId),
	gen_server:cast(Pid, {relation_be_add,UserId,MemId,Type}).

relation_be_del_cast(UserId,MemId,Type) ->
	Pid = get_pid(UserId),
	gen_server:cast(Pid, {relation_be_del,UserId,MemId,Type}).

logout_cast(UserId) ->
	Pid = get_pid(UserId),
	gen_server:cast(Pid, {logout,UserId}).
 
get_pid(UserId) ->
	Cores	= misc:core(),
	Num		= (UserId rem Cores) + 1,
	misc:to_atom("relation_srev_" ++ misc:to_list(Num)).
	
