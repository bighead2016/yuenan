%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(security_sup).

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
-export([start_link/2, init/1, start_link/1]).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_) ->
    try
        supervisor:start_link({local, ?MODULE}, ?MODULE, [1, 1, 1])
    catch
        Error:Reason -> io:format("Error:~p Reason:~p",[Error, Reason])
    end.
        
%% security_sup:start_link(security_sup, 1).
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
	case gen_tcp:listen(?SECURITY_PORT, ?CONST_TCP_OPTIONS_LISTEN) of
        {?ok, ListenSocket} ->
			CoreList	   	= lists:seq(1, Cores),
			ChildSpecList 	= misc_app:child_spec_list(CoreList, [], security_acceptor_serv, Cores,
													   [ListenSocket], transient, brutal_kill, worker),
			{?ok, {{one_for_one, 100, 5}, ChildSpecList}};
		{?error, eaddrinuse} ->
			{?ok, {{one_for_one, 100, 5}, []}};
		_Reason ->
			{?ok, {{one_for_one, 100, 5}, []}}
	end.
%% ====================================================================
%% Internal functions
%% ====================================================================



