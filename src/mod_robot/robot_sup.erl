%%% 机器人
-module(robot_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").

%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([
	 init/1, start_link/2
        ]).

%% --------------------------------------------------------------------
%% Macros
%% --------------------------------------------------------------------
-define(MOD_LIST, [
                    {worker, robot_boss_serv}    % 妖魔破机器人 
                  ]).

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
    List = make_child_list(?MOD_LIST, Cores, []),
    {ok, {{one_for_one, 100, 5}, List}}.

%% ====================================================================
%% Internal functions
%% ====================================================================
make_child_list([{Type, Mod}|Tail], Cores, OldList) ->
    ?MSG_SYS("ok:robot[~p]", [{Type, Mod}]),
    ChildSpec = misc_app:child_spec(Mod, Mod, [], permanent, 1000, Type, Cores),
    make_child_list(Tail, Cores, [ChildSpec|OldList]);
make_child_list([], _, L) ->
    L.



%% children
%% start_children() ->
%%     Cores   = misc:core(),
%% %%     ModList = config:read(mod),
%% %%     Len     = erlang:length(ModList),
%%     start_children([], Cores, 1, 0).
%% 
%% start_children([{Type, Mod}|Tail], Cores, Nth, Len) ->
%%     ChildSpec = misc_app:child_spec(Mod, Mod, [], permanent, 1000, Type, Cores),
%%     case supervisor:start_child(?MODULE, ChildSpec) of
%%         {?ok, _Pid} ->
%%             ?MSG_SYS("ok:server[~p|~p].....[~p/~p]", [Type, Mod, Nth, Len]),
%%             start_children(Tail, Cores, Nth+1, Len);
%%         {?error, {already_started, _Pid}} ->
%%             ?MSG_SYS("ok:server[~p|~p]......[~p/~p]", [Type, Mod, Nth, Len]),
%%             start_children(Tail, Cores, Nth+1, Len);
%%         {?error, Reason} ->
%%             ?MSG_SYS("!err:not support[~p|~p]~nReason=[~p]", [Type, Mod, Reason]),
%%             throw({?error, Reason})
%%     end;
%% start_children([], _, Nth, Len) when Nth =/= Len + 1 ->
%%     throw({?error, "server_sup start error"});
%% start_children([], _, _, _) ->
%%     ?ok.
