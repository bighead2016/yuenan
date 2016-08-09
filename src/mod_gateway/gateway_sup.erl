%%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(gateway_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.base.data.hrl").

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start_link/2, init/1, stop_acceptors/0]).

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
%% gateway_sup:start_link(gateway_sup, 1).
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
%% 	{port, Port}= ets_api:lookup(?CONST_ETS_SYS, port),
    Port        = config:read_deep([server, base, port]),
	LoginKey	= misc:to_list(config:read(platform_info, #rec_platform_info.login_key)),
	RootKey		= ?CONST_SYS_ROOT_KEY,
	ResourceKey	= ?CONST_SYS_RESOURCE_KEY,
	case gen_tcp:listen(Port, ?CONST_TCP_OPTIONS_LISTEN) of
        {?ok, ListenSocket} ->
			CoreList	   	= lists:seq(1, Cores),
			ChildSpec      	= misc_app:child_spec(gateway_worker_sup, gateway_worker_sup, [LoginKey, RootKey, ResourceKey],
												  permanent, brutal_kill, supervisor, Cores),
			ChildSpecList 	= misc_app:child_spec_list(CoreList, [], gateway_acceptor_serv, Cores,
													   [ListenSocket], transient, brutal_kill, worker),
			List			= [ChildSpec|ChildSpecList],
			{?ok, {{one_for_one, 100, 5}, List}};
		Reason ->
			?MSG_ERROR(" Reason:~p ",[Reason]),
			{?error, Reason}
	end.

%% %% gateway_sup:down().
%% down() ->
%% 	 Children = supervisor:which_children(?MODULE),
%% 	 down(Children).
%% down([{_ServName,Pid,_Type,[gateway_acceptor_serv]}|Children]) ->
%% 	gateway_acceptor_serv:switch(Pid, ?false),
%% 	down(Children);
%% down([_|Children]) ->
%% 	down(Children);
%% down([]) -> ?ok.
%% %% gateway_sup:wake_up().
%% wake_up() ->
%% 	 Children = supervisor:which_children(?MODULE),
%% 	 wake_up(Children).
%% wake_up([{_ServName,Pid,_Type,[gateway_acceptor_serv]}|Children]) ->
%% 	gateway_acceptor_serv:switch(Pid, ?true),
%% 	wake_up(Children);
%% wake_up([_|Children]) ->
%% 	wake_up(Children);
%% wake_up([]) -> ?ok.
%% %% gateway_sup:show().
%% show() ->
%% 	Children = supervisor:which_children(?MODULE),
%% 	show(Children).
%% show([{_ServName,Pid,_Type,[gateway_acceptor_serv]}|Children]) ->
%% 	gateway_acceptor_serv:show(Pid),
%% 	show(Children);
%% show([_|Children]) ->
%% 	show(Children);
%% show([]) -> ?ok.

stop_acceptors() ->
    ChildList = supervisor:which_children(?MODULE),
    F = fun({_, ChildPid, _, ['gateway_acceptor_serv']}) ->
                gateway_acceptor_serv:stop(ChildPid);
           (_) ->
                ?ok
        end,
    lists:foreach(F, ChildList).
%% ====================================================================
%% Internal functions
%% ====================================================================



