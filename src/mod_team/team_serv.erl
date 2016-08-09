%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-11-5
%%% -------------------------------------------------------------------
-module(team_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/7]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, gold_invite_call/2]).
-export([join_call/2, remove_call/2, quit_cast/3, change_leader_call/3, invite_call/2, invite_call2/2, change_team/3,
		 reply_call/4, set_camp_call/2, set_camp_pos_call/3, set_team_state_cast/2, set_team_param_cast/2,
		 play_start_cast/1, play_over_cast/1, destroy_cast/1, quick_join_call/2, lock_and_unlock_call/2]).

-record(state, {team_id, team_type}).

%% ====================================================================
%% External functions
%% ====================================================================
%% team_serv:start_link(team_serv, 1).
start_link(_ServName, _Cores, TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam) ->
	misc_app:gen_server_start_link(?MODULE, [TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam]).


change_team(TeamPid, Id, TeamParam) ->
    gen_server:call(TeamPid, {change_team, Id, TeamParam}).

join_call({NodeFrom, TeamPid}, TeamPlayer) ->
    rpc:call(NodeFrom, gen_server, call, [TeamPid, {join, TeamPlayer}, ?CONST_TIMEOUT_CALL]);
join_call(TeamPid, TeamPlayer) ->
	gen_server:call(TeamPid, {join, TeamPlayer}, ?CONST_TIMEOUT_CALL).

remove_call(TeamPid, UserId) ->
	gen_server:call(TeamPid, {remove, UserId}, ?CONST_TIMEOUT_CALL).

quit_cast({NodeFrom, TeamPid}, UserId, Packet) ->
    rpc:cast(NodeFrom, gen_server, cast, [TeamPid, {quit, UserId, Packet}]);

quit_cast(TeamPid, UserId, Packet) ->
	gen_server:cast(TeamPid, {quit, UserId, Packet}).

change_leader_call(TeamPid, UserId, Camp) ->
	gen_server:call(TeamPid, {change_leader, UserId, Camp}, ?CONST_TIMEOUT_CALL).

invite_call2(TeamPid, UserId) ->
    gen_server:call(TeamPid, {invite2, UserId}, ?CONST_TIMEOUT_CALL).

gold_invite_call(TeamPid, UserId) ->
    gen_server:call(TeamPid, {gold_invite, UserId}, ?CONST_TIMEOUT_CALL).

invite_call(TeamPid, UserId) ->
	gen_server:call(TeamPid, {invite, UserId}, ?CONST_TIMEOUT_CALL).

reply_call(TeamPid, UserId, TeamPlayer, Flag) ->
	gen_server:call(TeamPid, {reply, UserId, TeamPlayer, Flag}, ?CONST_TIMEOUT_CALL).

set_camp_call(TeamPid, Camp) ->
	gen_server:call(TeamPid, {set_camp, Camp}, ?CONST_TIMEOUT_CALL).

set_camp_pos_call(TeamPid, IdxFrom, IdxTo) ->
	gen_server:call(TeamPid, {set_camp_pos, IdxFrom, IdxTo}, ?CONST_TIMEOUT_CALL).

quick_join_call(TeamPid, TeamPlayer) ->
	gen_server:call(TeamPid, {quick_join, TeamPlayer}, ?CONST_TIMEOUT_CALL).

lock_and_unlock_call(TeamPid, Password) ->
	gen_server:call(TeamPid, {lock_and_unlock, Password}, ?CONST_TIMEOUT_CALL).
	
set_team_state_cast(TeamPid, TeamState) ->
	gen_server:cast(TeamPid, {set_team_state, TeamState}).

set_team_param_cast(TeamPid, TeamParam) ->
	gen_server:cast(TeamPid, {set_team_param, TeamParam}).

play_start_cast(TeamPid) ->
	gen_server:cast(TeamPid, play_start).

play_over_cast(TeamPid) ->
	gen_server:cast(TeamPid, play_over).

destroy_cast(TeamPid) ->
	gen_server:cast(TeamPid, destroy).

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
init([TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam]) ->
	case team_mod:do_create(TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam) of
		?ok -> {?ok, #state{team_id = TeamId, team_type = TeamType}, ?CONST_TEAM_TIMEOUT};
		{?error, ErrorCode} -> {stop, {?error, ErrorCode}}
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
		{?reply, Reply, State2} -> {?reply, Reply, State2, ?CONST_TEAM_TIMEOUT}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State, ?CONST_TEAM_TIMEOUT}
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
		{?noreply, State2} -> {?noreply, State2, ?CONST_TEAM_TIMEOUT};
        {?stop, ?normal, State2} -> {?stop, ?normal, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State, ?CONST_TEAM_TIMEOUT}
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
		{?noreply, State2} -> {?noreply, State2, ?CONST_TEAM_TIMEOUT};
		{?stop, team_timeout, State} -> {?stop, team_timeout, State}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State, ?CONST_TEAM_TIMEOUT}
	end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(?normal, _State) -> 
    TeamId = get(team_id),
    TeamType = get(team_type),
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
    }   = team_api:team_ets(TeamType),
    ets:delete(EtsTeamInfo, TeamId),
    CrossKey = team_api:get_cross_team_key(TeamId),
    ets:delete(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey),
    ?ok;
terminate(Reason, State) ->
    TeamId = get(team_id),
    TeamType = get(team_type),
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
    }   = team_api:team_ets(TeamType),
    ets:delete(EtsTeamInfo, TeamId),
    CrossKey = team_api:get_cross_team_key(TeamId),
    ets:delete(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey),
	?MSG_ERROR("STOP Reason:~p State:~p Strace:~p~n", [Reason, State, erlang:get_stacktrace()]),
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
do_call({join, TeamPlayer}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_join(TeamId, TeamType, TeamPlayer),
    {?reply, Reply, State};
do_call({remove, UserId}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_remove(TeamId, TeamType, UserId),
	{?reply, Reply, State};
do_call({change_leader, UserId, Camp}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_change_leader(TeamId, TeamType, UserId, Camp),
    {?reply, Reply, State};
do_call({invite, UserId}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_invite(TeamId, TeamType, UserId),
    {?reply, Reply, State};

do_call({invite2, UserId}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
    Reply = team_mod:do_invite2(TeamId, TeamType, UserId),
    {?reply, Reply, State};

do_call({gold_invite, UserId}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
    Reply = team_mod:do_gold_invite2(TeamId, TeamType, UserId),
    {?reply, Reply, State};

do_call({reply, UserId, TeamPlayer, Flag}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_reply(TeamId, TeamType, UserId, TeamPlayer, Flag),
	{?reply, Reply, State};
do_call({set_camp, Camp}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_set_camp(TeamId, TeamType, Camp),
    {?reply, Reply, State};
do_call({set_camp_pos, IdxFrom, IdxTo}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_set_camp_pos(TeamId, TeamType, IdxFrom, IdxTo),
    {?reply, Reply, State};
do_call({quick_join, TeamPlayer}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_quick_join(TeamId, TeamType, TeamPlayer),
	{?reply, Reply, State};
do_call({lock_and_unlock, Password}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
	Reply = team_mod:do_lock_and_unlock(TeamId, TeamType, Password),
	{?reply, Reply, State};

do_call({change_team, Id, TeamParam}, _From, #state{team_id = TeamId, team_type = TeamType} = State) ->
    Reply = team_mod:change_team(TeamId, TeamType, Id, TeamParam),
    {?reply, Reply, State};
do_call(Request, _From, State) ->
	Reply = ?ok,
	?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.


do_cast({quit, UserId, Packet}, #state{team_id = TeamId, team_type = TeamType} = State) ->
	case team_mod:do_quit(TeamId, TeamType, UserId, Packet) of
		?ok -> {?noreply, State};
		?stop -> {?stop, ?normal, State#state{team_type = 0, team_id = 0}}
	end;
do_cast({set_team_state, TeamState}, #state{team_id = TeamId, team_type = TeamType} = State) ->
	team_mod:do_set_team_state(TeamId, TeamType, TeamState),
	{?noreply, State};
do_cast({set_team_param, TeamParam}, #state{team_id = TeamId, team_type = TeamType} = State) ->
	team_mod:do_set_team_param(TeamId, TeamType, TeamParam),
	{?noreply, State};

do_cast(play_start, #state{team_id = TeamId, team_type = TeamType} = State) ->
	team_mod:do_play_start(TeamId, TeamType),
	{?noreply, State};
do_cast(play_over, #state{team_id = TeamId, team_type = TeamType} = State) ->
	team_mod:do_play_over(TeamId, TeamType),
	{?noreply, State};
do_cast(destroy, State) ->
	{?stop, ?normal, State#state{team_type = 0, team_id = 0}};

do_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
	{?noreply, State}.

do_info(?timeout, State) ->% 组队进程超时
	{?stop, team_timeout, State};
do_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.