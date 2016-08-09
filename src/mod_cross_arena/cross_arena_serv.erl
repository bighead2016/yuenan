%% Author: Administrator
%% Created: 2013-12-17
%% Description: TODO: Add description to cross_arena_data_api
-module(cross_arena_serv).

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


-export([deal_with_rank_cast/4, update_partner_cast/3, update_power_cast/2
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
	cross_arena_mod:deal_with_rank(UserId, EnemyId, Result, BinReport),
	{?noreply, State};
do_cast({update_partner, UserId, PartnerList, Power}, State) ->
	cross_arena_mod:update_partner(UserId, PartnerList, Power),
	{?noreply, State};
do_cast({update_power, UserId, Power}, State) ->
	cross_arena_mod:update_power(UserId, Power),
	{?noreply, State}.

deal_with_rank_cast(UserId, EnemyId, Result, BinReport) ->
	gen_server:cast(cross_arena_serv, {deal_with_rank,UserId, EnemyId, Result, BinReport}).

update_partner_cast(UserId, PartnerList, Power) ->
	gen_server:cast(cross_arena_serv, {update_partner,UserId, PartnerList, Power}).

update_power_cast(UserId, Power) ->
	gen_server:cast(cross_arena_serv, {update_power,UserId, Power}).

