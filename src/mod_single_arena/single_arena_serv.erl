%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-9-14
%%% -------------------------------------------------------------------
-module(single_arena_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).


-export([deal_with_rank_cast/4,
         deal_with_rank_robot_cast/1,
		 auto_rank_cast/1
		 ]).
-record(state, {}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) ->
	misc_app:gen_server_start_link(ServName, ?MODULE, []).

%%动态获取处理进程 
%% get_mod_arena_pid() ->
%% 	case misc:where_is({local, ?MODULE}) of
%%         Pid when is_pid(Pid) -> 
%% 			Pid;
%%         ?undefined ->
%%             ?undefined
%%     end.

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
handle_cast(Msg, State) ->
	try do_cast(Msg, State) of
		{?noreply, State2} -> {?noreply, State2}
	catch
		Error:Reason ->
			?MSG_ERROR("Error ~p, Reason ~p, Strace ~p", [Error, Reason, erlang:get_stacktrace()]),
			{?noreply, State}
	end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, _State) ->
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
do_cast({deal_with_rank, UserId, EnemyId, Result, BinReport}, State) ->
	single_arena_mod:deal_with_rank(UserId, EnemyId, Result, BinReport),
	{?noreply, State};
do_cast({deal_with_rank_robot, UserId}, State) ->
	single_arena_robot_api:deal_with_rank(UserId),
	{?noreply, State};
do_cast({auto_rank, UserId}, State) ->
	single_arena_mod:auto_rank(UserId),
	{?noreply, State}.

deal_with_rank_cast(UserId, EnemyId, Result, BinReport) ->
	gen_server:cast(single_arena_serv, {deal_with_rank,UserId, EnemyId, Result, BinReport}).

deal_with_rank_robot_cast(UserId) ->
	gen_server:cast(single_arena_serv, {deal_with_rank_robot,UserId}).

auto_rank_cast(UserId) ->
	gen_server:cast(single_arena_serv, {auto_rank,UserId}).
	


