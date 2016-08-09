%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(manage_net_worker_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/2]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).
-export([start_child_gateway_worker_serv/4, delete_net/1, insert_net/1]).

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
%% Returns: {?ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {?error, Reason}
%% --------------------------------------------------------------------
init([Cores]) ->
	process_flag(trap_exit, ?true),
	ChildSpec		= misc_app:child_spec(manage_net_worker_serv, manage_net_worker_serv, [],
										  temporary, 5000, worker, Cores),
	ChildSpecList = [ChildSpec],
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% 新建并挂载gateway_worker_serv
start_child_gateway_worker_serv(Cores, TimesF, Socket, ListenSocket)->
	Times   = trunc(TimesF),
	case supervisor:start_child(?MODULE, [Cores, Times, Socket, ListenSocket]) of
		{?ok, Pid} ->
			unlink(Pid),
			{?ok, Pid};
		{?error, {already_started, Pid}} ->
			unlink(Pid),
			{?ok, Pid};
		{?error, Reason} ->
			?MSG_ERROR("Reason:~p~n", [Reason]),
			{?error, Reason}
	end.

insert_net(NetPid) ->
    ets_api:insert(?CONST_ETS_NET, {NetPid}).

delete_net(NetPid) ->
    ets_api:delete(?CONST_ETS_NET, NetPid).