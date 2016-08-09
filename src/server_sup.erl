%%% sup/serv 开启处理
-module(server_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/0]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1, start_children/0]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------

-define(LOAD_LIST, [{supervisor, security_sup}, {worker, reloader}]).


%% 开服开启模块列表------------------------------------------------------------------------------
-define(MOD_LIST, [
                     {supervisor,   logger_sup},
                     {worker,       crond_serv},
                     {worker,       ets_serv},
                     {worker,       active_serv},
                     {supervisor,   player_sup},
                     {supervisor,   map_sup},
                     {supervisor,   gateway_sup},
                     {supervisor,   admin_sup},
                     {worker,       guild_serv},
                     {supervisor,   party_sup},
                     {supervisor,   battle_sup},
                     {supervisor,   team_manager_sup},
                     {supervisor,   camp_pvp_sup},
                     {worker,       guild_pvp_serv},
                     {worker,       monster_serv},
                     {worker,       arena_pvp_serv},
                     {worker,       single_arena_serv},
                     {worker,       boss_serv},
                     {worker,       buff_serv},
                     {worker,       cross_serv},
                     {supervisor,   world_sup},
                     {supervisor,   relation_sup},
                     {worker,       arena_cross_match},
                     {worker,       tower_report_serv},
                     {worker,       copy_single_report_serv},
                     {worker,       camp_pvp_counter_serv},
					 {worker,       boss_cross_counter_serv},
                     {worker,       resource_serv},
                     {supervisor,   robot_sup},
					 {worker,		cross_arena_serv},
                     {worker,       gun_award_serv},
                     {worker,       archery_reward_server}, %辕门射击排名服务 
					 {worker,       mixed_serv}, %合服活动
					 {worker,       gamble_serv} %青梅煮酒
                     %{worker,       node_unicast},
                     %{worker,       node_serv}
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
	{ok, {{one_for_one, 100, 5}, []}}.
%% ====================================================================
%% Internal functions
%% ====================================================================
 
%% children
start_children() ->
    Cores   = misc:core(),
    Debug   = config:read_deep([server, base, debug]),
    ModListExt = 
        if
            1 =:= Debug ->
                ?MOD_LIST ++ ?LOAD_LIST;
            ?true ->
                ?MOD_LIST
        end,
    Len     = erlang:length(ModListExt),
    start_children(ModListExt, Cores, 1, Len).

start_children([{Type, Mod}|Tail], Cores, Nth, Len) ->
    ChildSpec = misc_app:child_spec(Mod, Mod, [], permanent, 1000, Type, Cores),
    case supervisor:start_child(?MODULE, ChildSpec) of
        {?ok, _Pid} ->
            ?MSG_SYS("ok:server[~p|~p].....[~p/~p]", [Type, Mod, Nth, Len]),
            start_children(Tail, Cores, Nth+1, Len);
        {?error, {already_started, _Pid}} ->
            ?MSG_SYS("ok:server[~p|~p]......[~p/~p]", [Type, Mod, Nth, Len]),
            start_children(Tail, Cores, Nth+1, Len);
        {?error, Reason} ->
            ?MSG_SYS("!err:not support[~p|~p]~nReason=[~p]", [Type, Mod, Reason]),
            throw({?error, Reason})
    end;
start_children([], _, Nth, Len) when Nth =/= Len + 1 ->
    throw({?error, "server_sup start error"});
start_children([], _, _, _) ->
    ?ok.



