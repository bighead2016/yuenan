%%% -------------------------------------------------------------------
%%% Author  : michael
%%% Description : admin superviosr
%%%
%%% Created : 2012-10-13
%%% -------------------------------------------------------------------
-module(admin_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([accept/1]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1, start_link/2]).

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
	{?ok, ListenSocket} = gen_tcp:listen(get_gm_port(), ?HTTP_LISTEN_OPTIONS),
	?MSG_ERROR("socket start listen:~p ", [ListenSocket]),
	AcceptPid = spawn_link(?MODULE, accept, [ListenSocket]),
	register(misc:list_to_atom("admin_acceptor"), AcceptPid),
	ChildSpec		= misc_app:child_spec(admin_serv, admin_serv, [], temporary, 5000, worker, Cores),
	ChildSpecList 	= [ChildSpec],
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% 接受连接
accept(ListenSocket) ->
	case gen_tcp:accept(ListenSocket) of

		{ok, Socket} -> 
			% ?MSG_ERROR("socket accept listen:~p ", [Socket]),
			start_child_admin_serv(ListenSocket, Socket);
		Error -> ?MSG_ERROR("accept fail with ~p", [Error])
	end,
	accept(ListenSocket).

%% 新建并挂载gm_serv
start_child_admin_serv(ListenSocket, Socket) ->
	case supervisor:start_child(?MODULE, [ListenSocket, Socket]) of
		{?ok, Pid} -> {?ok, Pid};
		{?error, {already_started, Pid}} -> {?ok, Pid};
		{?error, Reason} -> {?error, Reason}
	end.

%% 获取GM端口
get_gm_port() ->
	config:read_deep([server, base, gm_port]).


