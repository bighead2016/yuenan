%% Author: cobain
%% Created: 2012-6-29
%% Description: TODO: Add description to server
-module(server).

-behaviour(application).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("const.sys.hrl").

%% --------------------------------------------------------------------
%% Behavioural exports
%% --------------------------------------------------------------------
-export([start/2, stop/1]).

%% --------------------------------------------------------------------
%% Internal exports
%% --------------------------------------------------------------------
-export([start/0, stop_i_i/1, stop_i/1, try_terminate_2/1, try_stop/1]).

%% --------------------------------------------------------------------
%% API Functions
%% --------------------------------------------------------------------
%% desc: 启动脚本入口
%% in:   no need
%% out:  no need
start() ->
    try
        ?MSG_SYS("start"),
        application:start(asn1),
        application:start(public_key),
        application:start(ssl),


        do_start(?START_LIST),
        catch gateway_acceptor_serv:switch_cast(?true),
        handle_observer(),
		hundred_serv_api:server_start(), %百服活动
        ?MSG_ERROR("start ok", []),
        ?ok
    catch
        throw:{process, Info, _Type, Why, X} ->
            io:format("start err:reason=[~p]~n-----Slogan-----~n"++misc:to_list(Why)++"~n-----~n~p~n", [Info, X]),
            erlang:halt(0, [{flush, false}]);
        Type:Why ->
            ?MSG_SYS("[~p|~p|~p]", [Type, Why, erlang:get_stacktrace()]),
            erlang:halt(0, [{flush, false}])
    end.

do_start(StartList) ->
    Len = erlang:length(StartList),
    do_start(StartList, Len, 1).
do_start([{Mod, Func, Arg, Msg}|Tail], TotalCount, Count) when Count =< TotalCount ->
    try
        if
            ?null =/= Arg ->
                Mod:Func(Arg);
            ?true ->
                Mod:Func()
        end,
        NewMsg = lists:concat(["ok:", Msg, "..........[", Count, "/", TotalCount, "]"]),
        ?MSG_SYS(NewMsg, []),
        ?ok
    catch
        Type:Why ->
            % ?MSG_SYS("start err with：~p,[~p|~p|~p]", [Count,Type, Why, erlang:get_stacktrace()]),

            throw({process, Msg, Type, Why, erlang:get_stacktrace()})
            
    end,
    do_start(Tail, TotalCount, Count + 1);
do_start([], _, _) ->
    ?ok.

handle_observer() ->
    Debug = config:read_deep([server, base, debug]),
    if
        0 < Debug ->
            erlang:spawn(fun() -> observer:start() end);
        ?true ->
            ?ok
    end.

%% ====================================================================
%% External functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: start/2
%% Returns: {ok, Pid}        |
%%          {ok, Pid, State} |
%%          {error, Reason}
%% --------------------------------------------------------------------
start(?normal, _StartArgs) ->
    case server_sup:start_link() of
        {ok, Pid} ->
            {ok, Pid};
        Error ->
            Error
    end.

%% --------------------------------------------------------------------
%% Func: stop/1
%% Returns: any
%% --------------------------------------------------------------------
stop(_State) ->
    ?ok.

try_stop(Node) ->
    TimeList = misc_sys:get_stop_list(),
    case TimeList of
        [] ->
            stop_from_broadcast([{1, 1}], Node);
        _ ->
            stop_from_broadcast(TimeList, Node)
    end.

stop_from_broadcast(StopTimeList, Node) ->
    try
        misc:make_stop_src(StopTimeList, Node)
    catch
        X:Y ->
            ?MSG_SYS("[~p|~p]~p", [X, Y, erlang:get_stacktrace()]),
            stop_i_i(Node)
    end.

%% 后台脚本立即关闭服务器
stop_i([NodeName]) ->
    io:format("------------------------------begin[0/10]------------------------------------------~n", []),
    NodeNameAtom = misc:to_atom(NodeName),
    case net_adm:ping(NodeNameAtom) of
        pong ->
            case net_kernel:connect_node(NodeNameAtom) of
                ?true ->
                    Self = node(),
                    ?MSG_SYS("ok[~p|~p]: sent[~p].............1/10~n", [Self, ?LINE, NodeNameAtom]),
                    X = rpc:call(NodeNameAtom, server, try_stop, [Self]),
                    ?MSG_SYS("ok[~p|~p]: stop success[~p].............10/10~n", [Self, ?LINE, X]),
                    misc_app:processing_print(10),
                    case net_adm:ping(NodeNameAtom) of
                        pong ->
                            ?MSG_SYS("ok[~p|~p]: pong kill........~n", [Self, ?LINE]),
                            misc_app:do_kill(NodeName);
                        pang ->
                            ?MSG_SYS("ok[~p|~p]: pang kill........~n", [Self, ?LINE]),
                            misc_app:do_kill(NodeName)
                    end,
                    ?MSG_SYS("------------------------------end[10/10]------------------------------------------~n", []),
                    erlang:halt(0, [{flush, false}]);
                _ ->
                    ?MSG_SYS("!err:bad connection.............0/10.~n", []),
                    erlang:halt(0, [{flush, false}])
            end;
        pang ->
            ?MSG_SYS("!err:bad node name[~p].............0/10~n", [NodeNameAtom]),
            erlang:halt(0, [{flush, false}])
    end.

%% 关闭远端结点
stop_i_i(Node) ->
    Self = node(),
    ?MSG_ERROR("ok[~p|~p]: recv.............2/10~n", [Self, ?LINE]),
%%     AtomCounter = lists:prefix("atom", string:tokens(binary_to_list(erlang:system_info(info)),"\n")),
%%     ?MSG_ERROR("!import:SystemStat=~p", [AtomCounter]),
    ?MSG_ERROR("ok[~p|~p]: broadcast end.............3/10~n", [Self, ?LINE]),
    catch single_arena_api:refresh_daily_db(Self),
    ?MSG_ERROR("ok[~p|~p]: write single arena db end.............4/10~n", [Self, ?LINE]),
    catch center_api:sync_serv_info(?CONST_CENTER_STATE_CLOSE),
    ?MSG_ERROR("ok[~p|~p]: center_api:sync_serv_info end.............4.1/10~n", [Self, ?LINE]),
	catch tower_api:stop_all_sweep(),
    ?MSG_ERROR("ok[~p|~p]: tower_api:stop_all_sweep end.............4.2/10~n", [Self, ?LINE]),
	catch tower_api:save_all(),
    ?MSG_ERROR("ok[~p|~p]: tower_api:save_all end.............4.3/10~n", [Self, ?LINE]),
	catch copy_single_report_api:save_all(),
    ?MSG_ERROR("ok[~p|~p]: copy_single_report_api:save_all end.............4.4/10~n", [Self, ?LINE]),
    catch new_serv_api:save_data_hero(),
    ?MSG_ERROR("ok[~p|~p]: new_serv_api:save_data_hero end.............4.5/10~n", [Self, ?LINE]),
    catch resource_api:save_all(),
    ?MSG_ERROR("ok[~p|~p]: resource_api:save_all end.............4.6/10~n", [Self, ?LINE]),
    catch robot_boss_api:save_all(),
    ?MSG_ERROR("ok[~p|~p]: robot_boss_api:save_all end.............4.7/10~n", [Self, ?LINE]),
	catch snow_api:save_all(),
    ?MSG_ERROR("ok[~p|~p]: snow_api:save_all end.............4.8/10~n", [Self, ?LINE]),
	catch spring_api:save_all_doll(),
    ?MSG_ERROR("ok[~p|~p]: spring_api:save_all_doll end.............4.9/10~n", [Self, ?LINE]),
	catch practice_api:save_all_doll(),
    ?MSG_ERROR("ok[~p|~p]: practice_api:save_all_doll end.............4.10/10~n", [Self, ?LINE]),
	catch party_api:save_all_doll(),
    ?MSG_ERROR("ok[~p|~p]: party_api:save_all_doll end.............4.11/10~n", [Self, ?LINE]),
	catch yunying_activity_api:activity_data_save(),                                 %运营活动回写数据
    ?MSG_ERROR("ok[~p|~p]: yunying_activity_api:activity_data_save end.............4.12/10~n", [Self, ?LINE]),
	catch party_api:save_activity_data(),
    ?MSG_ERROR("ok[~p|~p]: party_api:save_activity_data end.............4.13/10~n", [Self, ?LINE]),
	catch encroach_api:save_rank_data(),
    ?MSG_ERROR("ok[~p|~p]: encroach_api:save_rank_data end.............4.14/10~n", [Self, ?LINE]),
	catch shop_secret:save_active_data(),
    ?MSG_ERROR("ok[~p|~p]: shop_secret:save_active_data end.............4.15/10~n", [Self, ?LINE]),
	catch gamble_serv:on_terminate(),
    ?MSG_ERROR("ok[~p|~p]: gamble_serv:closing rooms.............4.16/10~n", [Self, ?LINE]),
    catch gateway_acceptor_serv:switch_cast(?false),
    ?MSG_ERROR("ok[~p|~p]: all kill msg sent.............7/10~n", [Self, ?LINE]),
    catch try_terminate_2(Node),
    ?MSG_SYS("[~p]calling halt...............~n", [Self]),
    erlang:halt(0, [{flush, false}]).

try_terminate_2(Node) ->
    Self      = node(),
    ?MSG_ERROR("ok[~p|~p] try terminating.............8/10~n", [Self, ?LINE]),
    % 关网关
    player_sup:kill_all_players(),
    Len       = player_sup:stat_online(),
    if
        Len =< 0 ->
            ?MSG_ERROR("ok[~p|~p]: send && stoped.............9/10~n", [Self, ?LINE]),
            if
                Node =:= 0 ->
                    ?MSG_ERROR("1", []),
                    ok;
                ?true ->
                    misc_sys:stop_apps(lists:reverse(?APPS)),
                    misc_app:processing_print(3)
            end;
        ?true -> 
            ?MSG_ERROR("ok[~p|~p]: remind ~p players.............8.5/10~n", [Self, ?LINE, Len]),
            try_terminate_2(Node)
    end.
