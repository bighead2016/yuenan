
-module(sg_serv_bhv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").

-record(state, {mod, inner_state}).

%% --------------------------------------------------------------------
%% External exports
-export([start_link/3, behaviour_info/1]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

behaviour_info(callbacks) ->
    [
       {do_init, 1},
       {do_call, 3},
       {do_cast, 2},
       {do_info, 2},
       {do_terminate, 2}
    ];
behaviour_info(_) ->
    ?undefined.

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, Mod, InitParam) ->
    gen_server:start_link({local, ServName}, ?MODULE, [Mod, InitParam], []).

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
init([Mod, InitParam]) ->
    ?PROC_INIT(),
    case Mod:do_init(InitParam) of
        {?ok, State}          -> {?ok, #state{mod = Mod, inner_state = State}};
        {?ok, State, Timeout} -> {?ok, #state{mod = Mod, inner_state = State}, Timeout};
        X                     -> X
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
    Mod = State#state.mod,
    case catch Mod:do_call(Request, From, State#state.inner_state) of
		{?reply, Reply, NewInnerState} -> 
            {?reply, Reply, State#state{inner_state = NewInnerState}, ?CONST_BATTLE_TIMEOUT};
        {Error, Reason} ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?reply, {?error, ?TIP_BATTLE_OFF}, State, ?CONST_BATTLE_TIMEOUT}
    end.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
    Mod = State#state.mod,
    case catch Mod:do_cast(Msg, State#state.inner_state) of
		{?noreply, NewInnerState} -> 
            {?noreply, State#state{inner_state = NewInnerState}, ?CONST_BATTLE_TIMEOUT};
	    {Error, Reason} ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State, ?CONST_BATTLE_TIMEOUT}
	end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    Mod = State#state.mod,
    case catch Mod:do_info(Info, State#state.inner_state) of
        {?noreply, NewInnerState} -> 
            {?noreply, State#state{inner_state = NewInnerState}, ?CONST_BATTLE_TIMEOUT};
        {?stop, Reason, NewInnerState} ->
            {?stop, Reason, State#state{inner_state = NewInnerState}};
        {Error, Reason} ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State, ?CONST_BATTLE_TIMEOUT}
    end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
    Mod = State#state.mod,
    catch Mod:terminate(Reason, State#state.inner_state).

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

