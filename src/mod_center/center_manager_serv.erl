%%% 
-module(center_manager_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.data.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores) -> 
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

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
    try
        process_flag(trap_exit, ?true),
        ?ok = misc_sys:make_config(),
        ?ok = misc_sys:set_time_diff(),
        loglevel:set(),
        case os:type() of
            {_, nt} ->
                erlang:spawn(fun() -> observer:start() end);
            _ ->
                ok
        end
    catch
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end,
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
    catch _Error:_Reason ->
%%               ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
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
    catch _Error:_Reason ->
%%               ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
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
    catch _Error:_Reason ->
%%               ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, _State) ->
    case Reason of
        shutdown -> ?ok;%?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
        _ -> ?ok %?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
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
do_call(_Request, _From, State) ->
    Reply = ?ok,
%%     ?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast(_Msg, State) ->
%%     ?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
    {?noreply, State}.

do_info(_Info, State) ->
%%     ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.
%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

