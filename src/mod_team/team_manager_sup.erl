%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-11-5
%%% -------------------------------------------------------------------
-module(team_manager_sup).

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
-export([start_link/2]).

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
init([_Cores]) ->
	process_flag(trap_exit, ?true),
	List			= [?CONST_TEAM_TYPE_COPY, ?CONST_TEAM_TYPE_INVASION, ?CONST_TEAM_TYPE_ARENA],
	ChildSpecList	= child_spec_list(List, []),
    {?ok, {{one_for_one, 100, 5}, ChildSpecList}}.

child_spec_list([TeamType|List], Acc) ->
	TeamSup		= team_api:team_sup_name(TeamType),
	ChildSpec	= misc_app:child_spec(TeamSup, team_sup, [TeamType], permanent, 1000, supervisor, 1),
	child_spec_list(List, [ChildSpec|Acc]);
child_spec_list([], Acc) -> Acc.
%% ====================================================================
%% Internal functions
%% ====================================================================











