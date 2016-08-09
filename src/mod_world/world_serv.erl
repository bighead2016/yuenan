%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2013-4-10
%%% -------------------------------------------------------------------
-module(world_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/3, invite_call/3, refresh_monster_cast/9,
		 reply_agree_call/3, reply_reject_cast/2, quit_cast/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {guild_id = 0}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores, GuildId) ->
    misc_app:gen_server_start_link(?MODULE, [GuildId]).


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
init([GuildId]) ->
	case world_mod:init(GuildId) of
		?ok -> {?ok, #state{guild_id = GuildId}};
		{?error, Reason} -> {?stop, Reason}
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
terminate(Reason, State) ->
    case Reason of
		?normal -> ?ok;
		shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
		_ ->
			?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
			?ok
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
do_call({invite, GuildPos, UserId}, _From, State) ->
	Reply = world_mod:do_invite(State#state.guild_id, GuildPos, UserId),
	{?reply, Reply, State};
do_call({reply_agree, GuildPos, UserId}, _From, State) ->
    Reply = world_mod:do_reply_agree(State#state.guild_id, GuildPos, UserId),
    {?reply, Reply, State};
do_call(Request, _From, State) ->
    ?MSG_ERROR("Request:~p Strace:~p",[Request, erlang:get_stacktrace()]),
	Reply = ?ok,
    {?reply, Reply, State}.


do_cast({quit,UserId},State) ->
	world_mod:do_quit(State#state.guild_id, UserId),
	{?noreply, State};
do_cast({reply_reject, UserId}, State) ->
	world_mod:do_reply_reject(State#state.guild_id, UserId),
	{?noreply, State};
do_cast({refresh_monster, GuildId, UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple}, State) ->
	world_mod:do_refresh_monster(GuildId, UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple),
	{?noreply, State};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
	{?noreply, State}.

do_info(notice_refresh_monster_step, State) ->
	world_mod:do_notice_refresh_monster_step(State#state.guild_id),
    {?noreply, State};
do_info(world_start, State) ->
	world_mod:do_world_start(State#state.guild_id),
    {?noreply, State};
do_info(world_end, State) ->
	world_mod:do_world_end(State#state.guild_id),
    {?stop, ?normal, State};
do_info(Info, State) ->
	?MSG_ERROR("Info:~p State:~w",[Info, State]),
    {?noreply, State}.

invite_call(Pid, GuildPos, UserId) ->
	gen_server:call(Pid, {invite, GuildPos, UserId}, ?CONST_TIMEOUT_CALL).
reply_agree_call(Pid, GuildPos, UserId) ->
	gen_server:call(Pid, {reply_agree, GuildPos, UserId}, ?CONST_TIMEOUT_CALL).
reply_reject_cast(Pid, UserId) ->
	gen_server:cast(Pid, {reply_reject, UserId}).
refresh_monster_cast(Pid, GuildId, UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple) ->
	gen_server:cast(Pid, {refresh_monster, GuildId, UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple}).
quit_cast(Pid,UserId) ->
	gen_server:cast(Pid,{quit,UserId}).