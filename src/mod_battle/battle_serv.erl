%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-7-17
%%% -------------------------------------------------------------------
-module(battle_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../include/const.common.hrl").
-include("../include/const.define.hrl").
-include("../include/const.tip.hrl").
-include("../include/record.player.hrl").
-include("../include/record.battle.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/6, start_link/7]).
-export([operate_cast/3, offline_cast/2, auto_battle_cast/3, set_battle_sleep_cast/2,
         skip_battle_cast/2, cross_cast/2, cross_cast/4]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores, Left, Right, MapPid, Param) ->
	misc_app:gen_server_start_link(?MODULE, [Left, Right, MapPid, Param]).
start_link(_ServName, _Cores, BattleL, BattleR, AppendL, AppendR, Param) ->
	misc_app:gen_server_start_link(?MODULE, [BattleL, BattleR, AppendL, AppendR, Param]).

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
init([Left, Right, MapPid, Param]) ->
	%% 
	process_flag(trap_exit, ?true),
	%% 随机数种子
	?RANDOM_SEED,
	case battle_mod:init(Left, Right, MapPid, Param) of
		{?ok, State} ->
			erlang:send_after(State#battle.time, self(), battle_exec),
			{?ok, State, ?CONST_BATTLE_TIMEOUT};
		{?error, ErrorCode} -> {?stop, ErrorCode}
	end;
init([BattleL, BattleR, AppendL, AppendR, Param]) ->
	%% 
	process_flag(trap_exit, ?true),
	%% 随机数种子
	?RANDOM_SEED,
	case battle_cross_api:init(BattleL, BattleR, AppendL, AppendR, Param) of
		{?ok, State} ->
			erlang:send_after(State#battle.time, self(), battle_exec),
			{?ok, State, ?CONST_BATTLE_TIMEOUT};
		{?error, ErrorCode} -> {?stop, ErrorCode}
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
		{?reply, Reply, State2} -> {?reply, Reply, State2, ?CONST_BATTLE_TIMEOUT}
	catch Error:Reason ->
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
	try do_cast(Msg, State) of
		{?noreply, State2} -> {?noreply, State2, ?CONST_BATTLE_TIMEOUT}
	catch Error:Reason ->
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
	try do_info(Info, State) of
		{?noreply, State2} -> {?noreply, State2, ?CONST_BATTLE_TIMEOUT};
		{?stop, ?normal, State2} ->
			{?stop, ?normal, State2};
		{?stop, battle_timeout, State2} ->
			{?stop, battle_timeout, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State, ?CONST_BATTLE_TIMEOUT}
	end.
%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, State) ->
	case Reason of
		?normal -> ?ok;
		battle_timeout -> 
			UnitsLeft 	= State#battle.units_left,
			LeftId		= UnitsLeft#units.id,
			?MSG_ERROR("STOP Reason=:~p, UserId=:~p, BattleType=:~p Sleep=:~p", [Reason, LeftId, State#battle.type, State#battle.sleep]), ?ok;
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
%% call
do_call(Request, _From, State) ->
    ?MSG_ERROR("Request:~p State:~p",[Request, State]),
	Reply = ?ok,
    {?reply, Reply, State}.

%% cast
do_cast({operate, UserId, SkillIdx}, State) ->
	State2	= battle_mod:do_operate(State, UserId, SkillIdx),
	{?noreply, State2};
do_cast({offline, UserId}, State) ->
	State2	= battle_mod:do_offline(State, UserId),
	{?noreply, State2};
do_cast({auto_battle, UserId, IsAuto}, State) ->
	State2	= battle_mod:do_auto_battle(State, UserId, IsAuto),
	{?noreply, State2};
do_cast({skip_battle, _UserId}, Battle) ->
    Battle2 = Battle#battle{skip = ?true},
	{?noreply, Battle2};
do_cast({set_battle_sleep, SleepNew}, State = #battle{sleep = SleepOld}) ->
	?MSG_DEBUG("SleepOld:~p, SleepNew:~p~n",[SleepOld, SleepNew]),
	State2	= State#battle{sleep = SleepNew},
	case {SleepOld, SleepNew} of 
		{?true, ?false} -> 
			erlang:send_after(0, self(), battle_exec); 
		_ -> 
			?ok end,
	{?noreply, State2};
do_cast(Msg, State) ->
    ?MSG_ERROR("Msg:~p State:~p",[Msg, State]),
	{?noreply, State}.

%% info
do_info(battle_exec, State) ->
	case State#battle.sleep of
		?false ->
			State2	= battle_mod:do_battle_exec(State),
			case State2#battle.result of
				?CONST_BATTLE_RESULT_DEFAULT ->
                    case State2#battle.skip of
                        ?true -> % 跳过战斗
                            erlang:send_after(0, self(), battle_exec); 
                        _ ->
        					Time	= State2#battle.time,
        					erlang:send_after(Time, self(), battle_exec)
                    end,
					{?noreply, State2};
				_ -> {?stop, ?normal, State2}
			end;
		?true -> {?noreply, State}
	end;
do_info(?timeout, State) ->% 战斗进程超时
	battle_mod:do_battle_timeout(State, ?CONST_BATTLE_STOP_REASON_TIMEOUT),
	{?stop, battle_timeout, State};
do_info(Info, State) ->
	?MSG_ERROR("Info:~w State:~w",[Info, State]),
    {?noreply, State}.

operate_cast(BattlePid, UserId, SkillIdx) ->
	gen_server:cast(BattlePid, {operate, UserId, SkillIdx}).

offline_cast(BattlePid, UserId) ->
	misc_app:cast(BattlePid, {offline, UserId}).

auto_battle_cast(BattlePid, UserId, IsAuto) ->
	gen_server:cast(BattlePid, {auto_battle, UserId, IsAuto}).

set_battle_sleep_cast(BattlePid, IsOn) ->
	gen_server:cast(BattlePid, {set_battle_sleep, IsOn}).

%% 跳过战斗
skip_battle_cast(BattlePid, UserId) ->
    gen_server:cast(BattlePid, {skip_battle, UserId}).

%% 多服cast
cross_cast(Func, Arg) ->
    Node = cross_api:get_arena_master(),
    rpc:cast(Node, ?MODULE, Func, Arg).

%% 多服cast
cross_cast(UserId, Lv, Func, Arg) ->
    case cross_api:get_camp_master(UserId, Lv) of
        {Node, _Room} ->
            rpc:cast(Node, ?MODULE, Func, Arg);
        _ ->
            ?ok
    end.

