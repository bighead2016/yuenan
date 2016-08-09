%% Author: Administrator
%% Created: 2013-4-15
%% Description: TODO: Add description to party_sup
-module(party_sup).

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
-export([start_link/2, start_child_party_serv/1, init/1, party_end/0]).

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
	process_flag(trap_exit, ?true),
	ChildSpec		= misc_app:child_spec(party_serv, party_serv, [], temporary,
										  5000, worker, Cores),
	ChildSpecList 	= [ChildSpec],
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 新建并挂载party_serv
%% party_sup:start_child_party_serv(1).
start_child_party_serv(GuildId) ->
	case supervisor:start_child(?MODULE, [GuildId]) of
		{?ok, Pid} ->
			{?ok, Pid};
		{?error, {already_started, Pid}} ->
			{?ok, Pid};
		{?error, Reason} ->
			?MSG_ERROR("Reason:~p~n", [Reason]),
			{?error, Reason}
	end.

party_end() ->
    ChildList = supervisor:which_children(?MODULE),
    F = fun({_, ChildPid, _, _}) ->
				misc:send_to_pid(ChildPid, party_end)
        end,
    lists:foreach(F, ChildList).