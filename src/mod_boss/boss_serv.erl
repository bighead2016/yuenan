%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-10-17
%%% -------------------------------------------------------------------
-module(boss_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2, boss_start_call/1, boss_end_call/2, boss_close_call/1, refresh_monster_cast/7, reward_first_cast/4,
         confirm_first_cast/2, reward_last_cast/5]).

-export([get_boss_cross_map_id/4, start_battle/3]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

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
handle_call(Request, From, State) ->
    try do_call(Request, From, State) of
		{?reply, Reply, State2} -> {?reply, Reply, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?reply, {?error, 110}, State}
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

do_call({boss_start, BossData}, _From, State) ->
	Reply = boss_mod:do_boss_start(BossData),
    {?reply, Reply, State};
do_call({boss_end, BossData, EndType}, _From, State) ->
	Reply = boss_mod:do_boss_end(BossData, EndType),
    {?reply, Reply, State};
do_call({boss_close, BossData}, _From, State) ->
	Reply = boss_mod:do_boss_close(BossData),
    {?reply, Reply, State};
do_call({get_boss_cross_map_id, _UserId, RoomId, LvPhase, BossId}, _From, State) ->
	Reply = boss_mod:init_monster_by_room(RoomId, LvPhase, BossId),
	{?reply, Reply, State};
do_call({start_battle, Player, RoomId, Param}, _From, State) ->
	Reply = boss_mod:do_start_battle(Player, RoomId, Param),
	{?reply, Reply, State};
do_call(Request, _From, State) ->
	Reply = ?ok,
	?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast({refresh_monster, BossData, UserId, UserName, BossPlayer, MonsterId, Hurt, HurtTuple}, State) ->
	boss_mod:do_refresh_monster(BossData, UserId, UserName, BossPlayer, MonsterId, Hurt, HurtTuple),
	{?noreply, State};
%% do_cast({refresh_monster, BossId, UserId, UserName, Pro, Sex, MonsterId, Hurt, HurtTuple}, State) ->
%% 	boss_mod:do_refresh_monster(BossId, UserId, UserName, Pro, Sex, MonsterId, Hurt, HurtTuple),
%% 	{?noreply, State};
do_cast({reward_first, MasterNode, RoomId, Player, MonsterId}, State) ->
	?MSG_DEBUG("~nssssssssssssssssssssssssss ~p", [{RoomId, MonsterId}]),
	boss_mod:do_reward_first(MasterNode, RoomId, Player, MonsterId),
	{?noreply, State};
do_cast({reward_last, MaterNode, RoomId, UserId, MonsterId, BossData}, State) ->
	boss_mod:do_reward_last(MaterNode, RoomId, UserId, MonsterId, BossData),
	{?noreply, State};
do_cast({confirm_first, UserId, BossId}, State) ->
	boss_mod:do_confirm_first(UserId, BossId),
	{?noreply, State};
do_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
	{?noreply, State}.

do_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.

boss_start_call(BossData) ->
	gen_server:call(?MODULE, {boss_start, BossData}, ?CONST_TIMEOUT_CALL).
	
boss_end_call(BossData, EndType) ->
	gen_server:call(?MODULE, {boss_end, BossData, EndType}, ?CONST_TIMEOUT_CALL).

boss_close_call(BossData) ->
	gen_server:call(?MODULE, {boss_close, BossData}, ?CONST_TIMEOUT_CALL).

refresh_monster_cast(BossData, UserId, UserName, BossPlayer, MonsterId, Hurt, HurtTuple) ->
	gen_server:cast(?MODULE, {refresh_monster, BossData, UserId, UserName, BossPlayer, MonsterId, Hurt, HurtTuple}).

reward_first_cast(MasterNode, RoomId, Player, MonsterId) ->
	gen_server:cast(?MODULE, {reward_first, MasterNode, RoomId, Player, MonsterId}).

reward_last_cast(MaterNode, RoomId, UserId, MonsterId, BossData) ->
	gen_server:cast(?MODULE, {reward_last, MaterNode, RoomId, UserId, MonsterId, BossData}).

confirm_first_cast(UserId, BossId) ->
    gen_server:cast(?MODULE, {confirm_first, UserId, BossId}).

get_boss_cross_map_id(UserId, RoomId, LvPhase, BossId) ->
	gen_server:call(?MODULE, {get_boss_cross_map_id, UserId, RoomId, LvPhase, BossId}).

start_battle(Player, RoomId, Param) ->
	gen_server:call(?MODULE, {start_battle, Player, RoomId, Param}).