%%% 加载处理

-module(misc_reload).
-record(rec_load, {serv_id, node, cookie, self_node, mod, is_copy, log_path}).

-define(CONF_PATH, "../config/reload.config").
-define(EBIN_PATH, "../ebin/").
-define(LOG(Tag, F, D), io:format("[~p|~p|~p]"++F++"~n", [?MODULE, ?LINE, Tag]++D)).
-define(FOG(FileName, Tag, F, D), file:write_file(lists:concat([FileName, "_", misc_reload:date(), ".log"]), io_lib:format("[~p|~p|~p]"++F++"~n", [?MODULE, ?LINE, Tag]++D), [raw, append])).

%% ====================================================================
%% API functions
%% ====================================================================
-export([load/0, read_vsn/1, load_info_remote/3, date/0, time/0, write_file/4]).

load() ->
    try
        case file:consult(?CONF_PATH) of
            {ok, [Terms]} ->
                load(Terms);
            {error, Reason} ->
                ?LOG(err, "reason[~p]", [Reason])
        end
    catch
        X:Y ->
            ?LOG(err, "file:consult[~p|~p|~p]", [X, Y, erlang:get_stacktrace()])
    end,
    init:stop().

load([NodeList|Tail]) ->
    load_2(NodeList),
    load(Tail);
load([]) ->
    ok.

load_2(NodeInfo) ->
    case record_load(NodeInfo) of
        #rec_load{} = RecLoad ->
            load_3(RecLoad#rec_load.node, RecLoad);
        _ ->
            ?LOG(err, "config is missing", []),
            ok
    end.

load_3([Node|Tail], #rec_load{} = RecLoad) ->
    ?LOG(sys, "loaded config", []),
    ?FOG(RecLoad#rec_load.log_path, sys, "~nreloading node=[~p], time=[~w]", [RecLoad#rec_load.node, misc_reload:time()]),
    load_info(Node, RecLoad),
    load_3(Tail, RecLoad);
load_3([], _) ->
    ok.

%% 加载单一节点数据
load_info(Node, #rec_load{} = RecLoad) ->
    case start_node(RecLoad) of
        ok ->
            erlang:set_cookie(RecLoad#rec_load.self_node, RecLoad#rec_load.cookie),
            case net_adm:ping(Node) of
                pong ->
                    load_info_2(Node, RecLoad);
                pang ->
                    ?LOG(err, "[~p] is off ...", [Node])
            end;
        {error, ErrorCode} ->
            ?LOG(err, "[~p][~p]", [Node, ErrorCode])
    end,
    net_kernel:stop();
load_info(Node, X) ->
    ?LOG(err, "[~p][~p]", [Node, X]),
    ok.

load_info_2(Node, RecLoad) ->
    ModList = get_mod_list(RecLoad),
    rpc:call(Node, ?MODULE, load_info_remote, [RecLoad#rec_load.log_path, ModList, Node]),
    ok.

start_node(#rec_load{self_node = Node}) ->
    case net_kernel:start([Node]) of
        {ok, _Pid} -> 
            ok;
        {error, {already_started, _}} ->
            ok;
        {error, ErrorCode} ->
            {error, ErrorCode};
        X ->
            {error, X}
    end.

load_info_remote(Log, [{Mod, Binary}|Tail], CallerNode) ->
    case code:is_sticky(Mod) of
        true ->
            ignore;
        false ->
            case code:soft_purge(Mod) of
                true ->
                    case write_file_remote(Log, Mod, Binary, CallerNode) of
                        ok ->
                            do_load_remote(Log, Mod, CallerNode);
                        err ->
                            err
                    end;
                false ->
                    rpc:call(CallerNode, ?MODULE, write_file, [Log, err, "[~p|~p|~p]purge error", [node(), ?LINE, Mod]])
            end
    end,
    load_info_remote(Log, Tail, CallerNode);
load_info_remote(Log, [Mod|Tail], CallerNode) ->
    case code:is_sticky(Mod) of
        true ->
            ignore;
        false ->
            case code:soft_purge(Mod) of
                true ->
                    do_load_remote(Log, Mod, CallerNode);
                false ->
                    rpc:call(CallerNode, ?MODULE, write_file, [Log, err, "[~p|~p|~p]purge error", [node(), ?LINE, Mod]])
            end
    end,
    load_info_remote(Log, Tail, CallerNode);
load_info_remote(Log, [], CallerNode) ->
    rpc:call(CallerNode, ?MODULE, write_file, [Log, sys, "[~p][~p]update done...", [node(), ?LINE]]).

do_load_remote(Log, Mod, CallerNode) ->
    OldVsn = read_vsn_old(Mod),
    case code:load_file(Mod) of
        {module, _} ->
            NewVsn = read_vsn(Mod),
            if
                OldVsn =:= NewVsn ->
                    rpc:call(CallerNode, ?MODULE, write_file, [Log, err, "[~p|~p|~p] no update vsn=[~p]", [node(), ?LINE, Mod, NewVsn]]);
                true ->
                    rpc:call(CallerNode, ?MODULE, write_file, [Log, sys, "[~p|~p|~p] update done vsn=[~p|~p]", [node(), ?LINE, Mod, OldVsn, NewVsn]])
            end;
        {error, ErrorRsn} ->
            rpc:call(CallerNode, ?MODULE, write_file, [Log, err, "[~p|~p~p|~p]", [node(), ?LINE, Mod, ErrorRsn]])
    end.

write_file(Logger, Tag, Format, Data) ->
    ?FOG(Logger, Tag, Format, Data).

%% ====================================================================
%% Internal functions
%% ====================================================================
record_load(List) ->
    try
        {_, Cookie}  = lists:keyfind(cookie,  1, List),
        {_, IsCopy}  = lists:keyfind(is_copy, 1, List),
        {_, LogPath} = lists:keyfind(log_path, 1, List),
        {_, ModList} = lists:keyfind(mod,     1, List),
        
        {_, NodeList}    = lists:keyfind(node,    1, List),
        SelfNode = erlang:list_to_atom(lists:concat(["wwsg_reload_xx@127.0.0.1"])),
        #rec_load{node = NodeList, cookie = Cookie, self_node = SelfNode, 
                  mod = ModList, is_copy = IsCopy, log_path = LogPath}
    catch
        X:Y ->
            ?LOG(sys, "[~p|~p|~p]~n", [X, Y, erlang:get_stacktrace()]),
            err
    end.

%% 读取版本号
read_vsn(Mod) ->
    {_, {_, [X]}} = beam_lib:version(Mod),
    X.

read_vsn_old(Mod) ->
    AttrList = Mod:module_info(attributes),
    {_, [Vsn]} = lists:keyfind(vsn, 1, AttrList),
    Vsn.
    
%% 读取mod列表
get_mod_list(RecLoad) ->
    #rec_load{is_copy = IsCopy, mod = OldModList} = RecLoad,
    get_mod_list(IsCopy, OldModList).

get_mod_list(0, ModList) ->
    ?LOG(sys, "calling mod...[~p]", [ModList]),
    ModList;
get_mod_list(1, ModList) ->
    get_mod_list_2(ModList, []).
    
get_mod_list_2([Mod|Tail], OldModList) ->
    FileName = lists:concat([?EBIN_PATH, Mod, ".beam"]),
    NewModList = 
        case file:read_file(FileName) of
            {ok, Binary} ->
                [{Mod, Binary}|OldModList];
            {error, Reason} ->
                ?LOG(err, "[~p]", [Reason]),
                OldModList
        end,
    get_mod_list_2(Tail, NewModList);
get_mod_list_2([], ModList) ->
    ModList.

write_file_remote(Log, Mod, Binary, CallerNode) ->
    FileName = lists:concat([?EBIN_PATH, Mod, ".beam"]),
    case file:write_file(FileName, Binary) of
        ok ->
            rpc:call(CallerNode, ?MODULE, write_file, [Log, sys, "[~p|~p]wrote[~p]", [node(), ?LINE, FileName]]),
            ok;
        {error, Reason} ->
            rpc:call(CallerNode, ?MODULE, write_file, [Log, err, "[~p|~p|~p]", [node(), ?LINE, Reason]]),
            err
    end.
    
%% 根据秒数获得日期 --20120630
date() ->
    {{Y, M, D}, {_, _, _}} = misc_reload:time(),
    Y * 10000 + M * 100 + D.

time() ->
    {MegaSecs, Secs, _} = erlang:now(),
    SecondsTemp         = MegaSecs * 1000000 + Secs,
    DateTime = calendar:gregorian_seconds_to_datetime(SecondsTemp + 62167219200),
    calendar:universal_time_to_local_time(DateTime).
    