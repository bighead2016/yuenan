%% Author: Administrator
%% Created: 2013-5-24
%% Description: TODO: Add description to relation_sup
-module(relation_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start_link/2, init/1]).

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
	ChildSpecList = child_spec_list(Cores, [], Cores),
	{ok, {{one_for_one, 100, 5}, ChildSpecList}}.
%% ====================================================================
%% Internal functions
%% ====================================================================
child_spec_list(0, ChildSpecs, _Cores) -> 
	lists:reverse(ChildSpecs);
child_spec_list(Num, ChildSpecs, Cores) ->
	ServName		= get_serv_name(Num),
	ChildSpec		= misc_app:child_spec(ServName, relation_serv, [], temporary,
										  5000, worker, Cores),
	child_spec_list(Num-1, [ChildSpec|ChildSpecs], Cores).

get_serv_name(Num) ->
	misc:to_atom("relation_srev_" ++ misc:to_list(Num)).
