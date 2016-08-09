%%% sup/serv 开启处理
-module(manage_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0, make_children/0]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

%% 开服开启模块列表---------------------------------------------------------
-define(MOD_LIST, [
                    {supervisor,    logger_sup},
                    {worker,        manage_mysql_serv},
                    {worker,        manage_ets_serv},
                    {worker,        manage_serv},
                    {supervisor,    manage_net_sup},
                    {worker,        center_gamble_serv},
                    {worker,        manage_i_serv}
                  ]).
                 

%% --------------------------------------------------------------------
%% Records
%% --------------------------------------------------------------------

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
	supervisor:start_link({local,?MODULE}, ?MODULE, []).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok,  {SupFlags,  [ChildSpec]}} |
%%          ignore                          |
%%          {error, Reason}
%% --------------------------------------------------------------------
%% init([]) ->
%% 	{ok, {{one_for_one, 3, 10}, []}}.
init([]) ->
	process_flag(trap_exit, true),
    misc_sys:init(),
    observer:start(),
    L = make_children(),
    reloader:start(),
    loglevel:set(),
	{ok, {{one_for_one, 100, 5}, L}}.
%% ====================================================================
%% Internal functions
%% ====================================================================

%% children
make_children() ->
    Cores   = misc:core(),
    make_children(?MOD_LIST, Cores, []).

make_children([{Type, Mod}|Tail], Cores, OldChildSpec) ->
    ChildSpec = misc_app:child_spec(Mod, Mod, [], permanent, 1000, Type, Cores),
    make_children(Tail, Cores, [ChildSpec|OldChildSpec]);
make_children([],  _, L) ->
    lists:reverse(L).

%% ====================================================================
%% Internal functions
%% ====================================================================

%% 获取GM端口
get_port() ->
    config:read_deep([server, base, port]).




