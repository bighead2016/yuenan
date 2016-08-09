%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-12-21
%%% -------------------------------------------------------------------
-module(arena_pvp_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../include/const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
		 match_battle_cast/0,
		 clear_cast/0,
		 week_reward_cast/0
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
	?RANDOM_SEED, 
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
handle_call(Request, From, State) ->
	?MSG_ERROR("handle_call Pid:~p  Request:~p From:~p state:~p", [self(), Request, From, State]),
	Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast({match_battle}, State) ->
	arena_pvp_mod:match_battle_handle(),
    {noreply, State};

handle_cast({clear}, State) ->
	arena_pvp_api:clear_handle(),
    {noreply, State};

handle_cast({week_reward}, State) ->
	arena_pvp_api:week_reward_handle(),
    {noreply, State};

handle_cast(Msg, State) ->
	?MSG_ERROR("handle_cast Pid:~p Msg:~p State:~p", [self(), Msg, State]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
    ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	case Reason of
		shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
		_ -> ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
	end.
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


match_battle_cast() ->
    case ?IS_CROSS_OPEN of
        true ->ok;
        false ->
            gen_server:cast(arena_pvp_serv, {match_battle})
    end.

clear_cast() ->
	gen_server:cast(arena_pvp_serv,{clear}).

week_reward_cast() ->
	gen_server:cast(arena_pvp_serv, {week_reward}).
