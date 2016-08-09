-module(camp_pvp_sup).

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
-export([start_link/2, start_child_monster/1]).

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
init([Cores]) ->
    process_flag(trap_exit, ?true),
    ChildSpec = misc_app:child_spec(camp_pvp_serv, camp_pvp_serv, [], permanent, 1000, worker, Cores),
    {?ok, {{one_for_one, 100, 5}, [ChildSpec]}}.

%% 	ets:update_counter(ets_team_id_copy, 1, {2,1,5,1})
%% 	ets:insert(ets_team_id_copy, {})
%% 	ets:lookup(ets_team_id_copy, 1)
%% 	ets:tab2list(ets_team_id_copy)
%% ====================================================================
%% Internal functions
%% ====================================================================

%% 新建并挂载地图进程
start_child_monster(Monster) ->
    MonsterId = Monster#camp_pvp_monster.monster_id,
    NameStr = "monster_" ++ misc:to_list(MonsterId),
    PName = misc:to_atom(NameStr),
    ChildSpec = misc_app:child_spec(PName, camp_pvp_monster, [Monster], temporary , 1000, worker, 1),
	supervisor:start_child(?MODULE, ChildSpec),
    PName.
