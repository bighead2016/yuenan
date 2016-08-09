%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-11-5
%%% -------------------------------------------------------------------
-module(team_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/3, start_child_team_serv/4]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(SERVER, ?MODULE).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link(TeamSupName, _Cores, TeamType) ->
	supervisor:start_link({local, TeamSupName}, ?MODULE, [TeamType]).



%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
init([TeamType]) ->
	process_flag(trap_exit, ?true),
	?ok				= team_api:init_tesm_ets(TeamType),
	ChildSpec		= misc_app:child_spec(team_serv, team_serv, [], temporary, 5000, worker, 0),
	ChildSpecList 	= [ChildSpec],
	?MSG_PRINT(" Server Start On Core:~p", [erlang:system_info(scheduler_id)]),
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% 	ets:update_counter(ets_team_id_copy, 1, {2,1,5,1})
%% 	ets:insert(ets_team_id_copy, {})
%% 	ets:lookup(ets_team_id_copy, 1)
%% 	ets:tab2list(ets_team_id_copy)
%% ====================================================================
%% Internal functions
%% ====================================================================

%% 新建并挂载地图进程
start_child_team_serv(TeamType, TeamCamp, TeamPlayer, TeamParam) ->
	TeamSup		= team_api:team_sup_name(TeamType),
	TeamId		= team_api:generate_team_id(TeamType),
	case supervisor:start_child(TeamSup, [TeamType, TeamId, TeamCamp, TeamPlayer, TeamParam]) of
		{?ok, Pid} -> {?ok, Pid, TeamId};
		{?error, {already_started, Pid}} -> {?ok, Pid, TeamId};
		{?error, Reason} -> ?MSG_ERROR("Reason:~p~n", [Reason]), {?error, Reason}
	end.
