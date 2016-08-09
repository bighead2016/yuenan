%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2012-7-17
%%% -------------------------------------------------------------------
-module(battle_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/2, start_child_battle_serv/4, start_child_battle_serv_cross/5]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, Cores) ->
	supervisor:start_link({local, ServName}, ?MODULE, [Cores]).


%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([Cores]) ->
	process_flag(trap_exit, ?true),
	ChildSpec		= misc_app:child_spec(battle_sup, battle_serv, [], temporary,
										  5000, worker, Cores),
	ChildSpecList 	= [ChildSpec],
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 新建并挂载battle_serv
%% battle_sup:start_child_battle_serv(UnitsLeft, UnitsRight, Param).
start_child_battle_serv(UnitsLeft, UnitsRight, MapPid, Param) ->
	case supervisor:start_child(?MODULE, [UnitsLeft, UnitsRight, MapPid, Param]) of
		{?ok, Pid} ->
			{?ok, Pid};
		{?error, {already_started, Pid}} ->
			{?ok, Pid};
		{?error, Reason} ->
			?MSG_ERROR("Reason:~p~n", [Reason]),
			{?error, Reason}
	end.

start_child_battle_serv_cross(BattleL, BattleR, AppendL, AppendR, Param) ->
	case supervisor:start_child(?MODULE, [BattleL, BattleR, AppendL, AppendR, Param]) of
		{?ok, Pid} ->
			{?ok, Pid};
		{?error, {already_started, Pid}} ->
			{?ok, Pid};
		{?error, Reason} ->
			?MSG_ERROR("Reason:~p~n", [Reason]),
			{?error, Reason}
	end.

