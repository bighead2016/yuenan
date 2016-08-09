%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-7-6
%%% -------------------------------------------------------------------
-module(player_sup).

-behaviour(supervisor).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
%% --------------------------------------------------------------------
%% External exports
%% --------------------------------------------------------------------
-export([start_link/2, start_child_player_serv/9]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([init/1, refresh/0, refresh_sp/0, refresh_oclock/0]).
-export([stat_online/0, stat_online_ip/0]).
-export([kill_player/3, kill_all_players/0]).
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
	ChildSpec		= misc_app:child_spec(player_serv, player_serv, [], temporary,
										  10000, worker, Cores),
	ChildSpecList 	= [ChildSpec],
    {?ok, {{simple_one_for_one, 100, 5}, ChildSpecList}}.

%% ====================================================================
%% Internal functions
%% ====================================================================

%% 新建并挂载player_serv
start_child_player_serv(NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist) ->
	case supervisor:start_child(?MODULE, [NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist]) of
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

%% 更新玩家ets
%% ChildList=[{undefined,<0.267.0>,worker,[player_serv]},
%%            {undefined,<0.308.0>,worker,[player_serv]}]
refresh() ->
    ChildList = supervisor:which_children(?MODULE),
    F = fun({_, ChildPid, _, _}) ->
                player_api:process_send(ChildPid, player_api, refresh_cb, [])
        end,
    lists:foreach(F, ChildList).

%% 体力更新
refresh_sp() ->
    ChildList = supervisor:which_children(?MODULE),
    F = fun({_, ChildPid, _, _}) ->
                player_api:process_send(ChildPid, player_api, sp_cb, [?CONST_PLAYER_SP_PER_TIME])
        end,
    lists:foreach(F, ChildList).

%% 每天0点更新
refresh_oclock() ->
	try
		ChildList = supervisor:which_children(?MODULE),
		F = fun({_, ChildPid, _, _}) ->
					player_api:process_send(ChildPid, player_api, handle_zero_oclock_cb, []),
                    RandTime = misc:rand(1000, 2000),
                    misc:sleep(RandTime)
			end,
		lists:foreach(F, ChildList),
        erlang:garbage_collect()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

%% 统计在线人数
%% player_sup:stat_online().
stat_online() -> erlang:length(supervisor:which_children(?MODULE)).

%% 统计在线IP数
stat_online_ip() -> ets_api:info(?CONST_ETS_PLAYER_IP, size).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 清玩家 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
kill_all_players() ->
    List = supervisor:which_children(?MODULE),
    kill_player(List, 1, erlang:length(List)).

kill_player([{_, ChildPid, _, _}|Tail], Idx, Total) ->
    player_serv:user_logout(ChildPid),
    ?MSG_ERROR("kill ~p sent.................[~p/~p]~n", [ChildPid, Idx, Total]),
    misc:sleep(?CONST_SYS_INTERVAL_PLAYER),
    kill_player(Tail, Idx + 1, Total);
kill_player([], _, _) ->
    ok.

%% F = fun({_, ChildPid, _, _}) -> player_serv:user_logout(ChildPid) end.
%% lists:foreach(F, supervisor:which_children(player_sup)).
