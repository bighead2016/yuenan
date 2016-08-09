%%% sup/serv 开启处理
-module(center_sup).

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
                    {worker,        center_manager_serv},
                    {supervisor,    logger_sup},
                    {worker,        center_mysql_serv},
                    {worker,        center_ets_serv},
                    {worker,        crond_center_serv},
					{worker,		center_report_serv},
                    {worker,        tower_report_serv},
                    {worker,        copy_single_report_serv},
                    {supervisor,    center_gift_sup},
                    {worker,        gun_award_serv},
					{worker,		center_serv_info_serv},
                    {worker,        center_i_serv}
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
    L = make_children(),
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



