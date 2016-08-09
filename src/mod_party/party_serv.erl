%% Author: Administrator
%% Created: 2013-4-15
%% Description: TODO: Add description to party_serv
-module(party_serv).
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([
		 add_exp_cast/2,add_sp_cast/2,
		 play_start_cast/2,play_end_cast/2,
		 refresh_monster_cast/6,
		 refresh_monster_hp_cast/2,
		 present_reward_cast/3,
		 broadcast_cast/3
		 ]).

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
	process_flag(trap_exit, ?true),
	% 随机数种子
	?RANDOM_SEED,
	case party_mod:init(GuildId) of
		?ok -> {?ok, #state{guild_id = GuildId}};
		{?error, ErrorCode} -> {?error, ErrorCode}
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

do_cast({add_exp,PartyData}, State) ->
	party_mod:add_exp_handle(PartyData),
	{?noreply, State};
do_cast({add_sp,PartyData}, State) ->
	party_mod:add_sp_handle(PartyData),
	{?noreply, State};
do_cast({play_start,PartyData}, State) ->
	party_mod:play_start_handle(PartyData),
	{?noreply, State};
do_cast({play_end,PartyData}, State) ->
	party_mod:play_end_handle(PartyData),
	{?noreply, State};
do_cast({refresh_monster,UserId,  Name, Id, Hurt, HurtTuple}, State) ->
	GuildId 	= State#state.guild_id,
	party_mod:refresh_monster_handle(GuildId, UserId,  Name, Id, Hurt, HurtTuple),
	{?noreply, State};
do_cast({present_reward,PartyData,Type}, State) ->
	party_mod:present_reward_handle(PartyData,Type),
	{?noreply, State};
do_cast({refresh_monster_hp,PartyData}, State) ->
	party_mod:refresh_monster_hp_handle(PartyData),
	{?noreply, State};

do_cast({broadcast,MemberList,Packet}, State) ->
	party_api:broadcast(MemberList, Packet),
	{?noreply, State};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
	{?noreply, State}.

do_info(party_end, State) ->
    {?stop, ?normal, State};
do_info(Info, State) ->
	?MSG_ERROR("Info:~p State:~w",[Info, State]),
    {?noreply, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_exp_cast(Pid,PartyData) ->
	gen_server:cast(Pid, {add_exp,PartyData}).

add_sp_cast(Pid,PartyData) ->
	gen_server:cast(Pid, {add_sp,PartyData}).

play_start_cast(Pid,PartyData) ->
	gen_server:cast(Pid, {play_start,PartyData}).

play_end_cast(Pid,PartyData) ->
	gen_server:cast(Pid, {play_end,PartyData}).

refresh_monster_cast(Pid, UserId,  Name, Id, Hurt, HurtTuple) ->
	gen_server:cast(Pid, {refresh_monster, UserId,  Name, Id, Hurt, HurtTuple}).

refresh_monster_hp_cast(Pid,PartyData) ->
	gen_server:cast(Pid, {refresh_monster_hp,PartyData}).

present_reward_cast(Pid,PartyData,Type) ->
	gen_server:cast(Pid, {present_reward,PartyData,Type}).

broadcast_cast(Pid,MemberList,Packet) ->
	gen_server:cast(Pid, {broadcast,MemberList,Packet}).
	
