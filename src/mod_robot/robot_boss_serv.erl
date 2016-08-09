%%% 妖魔破机器人
-module(robot_boss_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.data.hrl").

%% --------------------------------------------------------------------
%% External exports
-export([robot_start_cast/1, robot_battle_over_cast/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,
         start_link/2]).

-record(state, {boss_id=0}).

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
    try do_call(Request, From, State) of
        {?reply, Reply, State2} -> {?reply, Reply, State2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
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
handle_info(Info, State) ->
    try do_info(Info, State) of
        {?noreply, State2} -> {?noreply, State2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?noreply, State}
    end.

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
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call(Request, _From, State) ->
    Reply = ?ok,
    ?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast({robot_start, BossId}, State) ->
    crond_api:interval_add(?CONST_BOSS_ROBOT_ATOM, ?CONST_BOSS_ROBOT_INTERVAL_SEC, robot_boss_api, interval, [BossId]),
    {?noreply, State#state{boss_id = BossId}};
do_cast({robot_battle_over, UserId, Result, RobotList}, State) ->
    robot_boss_api:battle_over(UserId, Result, RobotList),
    {?noreply, State};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
    {?noreply, State}.

do_info(Info, State) ->
    ?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.

%% robot_boss_serv:robot_start_cast(10002).
robot_start_cast(BossId) ->
    gen_server:cast(?MODULE, {robot_start, BossId}).

%% robot_boss_serv:robot_battle_over_cast(1, 1).
robot_battle_over_cast(UserId, Result, RobotList) ->
    gen_server:cast(?MODULE, {robot_battle_over, UserId, Result, RobotList}).

