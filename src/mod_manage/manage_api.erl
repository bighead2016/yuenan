
-module(manage_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.data.hrl").
-include("record.man.hrl").

%%
%% Exported Functions
%%
-export([init/0, conn_all_center/0, sync_info/0, sync_info_cb/0, get_center_node/1,
         get_master_node/1, get_man_node/0, get_combine_list/2, record_uni_key/1,
         record_uni_key/3, get_combine_list/1, cast/5, cast/4, cast_all_center/3, 
         rsync_houtai/1, get_houtai_all/0, rsync_houtai/2, lookup_houtai_node/2, 
         get_center_node/2, get_combine_list/3, get_master_node/2]).

%%
%% API Functions
%%
init() ->
    case config:read_deep([server, base, debug]) of
        % ?CONST_SYS_TRUE ->
        _ ->
            manage_mod:get_plat_data_file(),
            manage_mod:get_houtai_data_file();
        ?CONST_SYS_FALSE ->
            manage_mod:get_houtai_data(),
            manage_mod:get_plat_data()
    end,
%%     conn_all_center(),

    ok.

conn_all_center() ->
    L = data_misc:get_platform_list(),
    conn_center(L),
    ok.

conn_center([{PlatId, CNode, Plat}|Tail]) ->
    CNode2 = misc:to_list(CNode),
    Plat2 = misc:to_list(Plat),
    Node = misc:to_atom(lists:concat([sanguo, "_", Plat2, "_center@", CNode2])),
    case net_kernel:connect_node(Node) of
        ?true ->
            ?MSG_SYS("ok:conn ~p ok...", [Node]),
            update_serv_state(PlatId, Node, 0);
        ?false ->
            ?MSG_SYS("ok:conn ~p fail...", [Node]),
            update_serv_state(PlatId, Node, 1);
        ?ignore ->
            ?MSG_SYS("ok:conn ~p fail...ignore?", [Node]),
            update_serv_state(PlatId, Node, 2)
    end,
    conn_center(Tail);
conn_center([]) ->
    ok.

sync_info() ->
    List = lists:sort(ets:select(ets_serv_state, [{{'$1','$2',0},[],[{{'$1','$2'}}]}])),
    L = sync_info(List, []),
    ets:delete_all_objects(ets_man_serv_info),
    insert_serv(L),
    ok.

sync_info([{Node, PlatId}|Tail], OldList) ->
    case rpc:call(Node, ?MODULE, sync_info_cb, []) of
        {badrpc, Reason} ->
            ?MSG_SYS("err:sync [~p|~p]", [{Node, PlatId}, Reason]),
            sync_info(Tail, [{PlatId, []}|OldList]);
        Ret ->
            sync_info(Tail, [{PlatId, Ret}|OldList])
    end;
sync_info([], List) ->
    List.

sync_info_cb() ->
    L = lists:sort(ets:tab2list(?CONST_ETS_SERV_INFO)),
    ping_list(L, []).

ping_list([#ets_serv_info{node_name = Node} = Ets|Tail], OldList) ->
    List = 
        case lists:keyfind(Node, #ets_serv_info.node_name, OldList) of
            ?false ->
%%                 ?MSG_SYS("pinging ~p", [Node]),
                case net_adm:ping(Node) of
                    pong ->
                        [Ets|OldList];
                    pang ->
                        OldList
                end;
            _ ->
                [Ets|OldList]
        end,
    ping_list(Tail, List);
ping_list([], List) ->
    List.

insert_serv([{PlatId, ServList}|Tail]) ->
    insert_serv_2(PlatId, ServList),
    insert_serv(Tail);
insert_serv([]) ->
    ok.

insert_serv_2(PlatId, [#ets_serv_info{node_name = Node, sid = Sid, state = State, time = Time}|Tail]) ->
    Rec = #ets_man_serv_info{key = {PlatId, Sid}, plat_id = PlatId, sid = Sid, node_name = Node, state = State, time = Time},
    ets_api:insert(ets_man_serv_info, Rec),
    insert_serv_2(PlatId, Tail);
insert_serv_2(_PlatId, []) ->
    ok.

%% desc:读取中心结点 -- serv
%% in:plat_id
%% out:node
get_center_node(PlatId) ->
    get_center_node(PlatId, 1).

%% desc:读取中心结点 -- serv
%% in:plat_id
%%    type :: integer() :: 0 不查ets;1 先查ets
%% out:node
% get_center_node(PlatId, 0) ->
%     case catch rpc:call(get_man_node(), manage_serv, get_center_node_call, [PlatId]) of
%         ?null -> 'sanguo_4399_center@127.0.0.1'; % XXX 测试
%         {badrpc, _} ->
%             ?null;
%         Node ->
%             misc:to_atom(Node)
%     end;

get_center_node(PlatId, 0) ->
    'sanguo_Tencent_center9999@10.221.248.51';

get_center_node(PlatId, 9999) ->
    'sanguo_Tencent_center9999@10.221.248.51';

% Man = manage_api:get_man_node(),
% rpc:call(Man, manage_serv, get_center_node_call, [64]).
get_center_node(PlatId, _) ->
    case lookup_houtai_node(PlatId, 0) of
        ?null ->
            case catch rpc:call(get_man_node(), manage_serv, get_center_node_call, [PlatId]) of
                ?null -> 'sanguo_4399_center@127.0.0.1'; % XXX 测试
                {badrpc, _} ->
                    ?null;
                Node ->
                    misc:to_atom(Node)
            end;
        Node ->
            misc:to_atom(Node)
    end.

%% desc:读取主控结点 -- serv
%% in:plat_id
%% out:node
get_master_node(PlatId) ->
    get_master_node(PlatId, 1).
get_master_node(PlatId, 0) ->
    'sanguo_Tencent_0@10.221.248.51';
get_master_node(PlatId, 9999) ->
    'sanguo_Tencent_9999@10.221.248.51';
get_master_node(PlatId, _) ->
    case lookup_houtai_node(PlatId, 1) of
        ?null ->
            case catch rpc:call(get_man_node(), manage_serv, get_master_node_call, [PlatId]) of
                ?null -> 'sanguo_4399_1@127.0.0.1'; % XXX 测试
                {badrpc, _} ->
                    ?null;
                Node ->
                    misc:to_atom(Node)
            end;
        Node ->
            misc:to_atom(Node)
    end.

%% desc:合服列表
%% in:plat_id :: integer() 平台id
%%    sid :: integer() 服务器id
%% out:list :: list() 合服列表
get_combine_list(PlatId, Sid) ->
    get_combine_list(PlatId, Sid, 1).

get_combine_list(PlatId, Sid, _) ->         %% laojiajie
    [Sid];
get_combine_list(PlatId, Sid, 0) ->
    case catch rpc:call(get_man_node(), manage_serv, get_combine_list_call, [PlatId, Sid]) of
        ?null -> [Sid,1];
        {badrpc, _} ->
            [Sid];
        L ->
            L
    end;
get_combine_list(PlatId, Sid, 1) ->
    case ets_api:lookup(?CONST_ETS_MAN_HOUTAI, {PlatId, Sid}) of
        ?null ->
            case catch rpc:call(get_man_node(), manage_serv, get_combine_list_call, [PlatId, Sid]) of
                ?null -> [Sid];
                {badrpc, _} ->
                    [Sid];
                L ->
                    L
            end;
        #ets_man_houtai{combine = L} ->
            L
    end.

%% desc:读取本平台所有服的合服列表
get_combine_list(PlatId) ->
    Sql = <<"select `combine` from `game_server_t` where `plat_id` = '", (misc:to_binary(PlatId))/binary, "'; ">>,
    case mysql_api:select(Sql) of
        {?ok, CombineList} ->
            get_combine_list_2(PlatId, CombineList, []);
        _ ->
            []
    end.

get_combine_list_2(PlatId, [[L]|Tail], OldList) ->
    get_combine_list_2(PlatId, Tail, [mysql_api:decode(L)|OldList]);
get_combine_list_2(_PlatId, [], List) ->
    List.

% get_man_node() -> 'sanguo_manage_xxx@10.207.147.34'.
get_man_node() -> 
    Sid = get_sid(),
    if 
        %%不做分中心服
        Sid =< 100000 ->
            'sanguo_manage_xxx@192.168.10.111';

        Sid =< 10 ->
            'sanguo_manage_xxx@58.218.209.198';
        Sid =< 20 ->
             'sanguo_manage_xxx11@58.218.209.198';
        Sid =< 30 ->
             'sanguo_manage_xxx21@58.218.209.198';
        Sid =< 40 ->
             'sanguo_manage_xxx31@58.218.209.198';
        Sid =< 50 ->
             'sanguo_manage_xxx41@58.218.209.198';
        Sid =< 60 ->
             'sanguo_manage_xxx51@58.218.209.198';
        Sid =< 70 ->
             'sanguo_manage_xxx61@58.218.209.198';
        Sid =< 80 ->
             'sanguo_manage_xxx71@58.218.209.198';
        Sid =< 90 ->
             'sanguo_manage_xxx81@58.218.209.198';
        Sid =< 100 ->
             'sanguo_manage_xxx91@58.218.209.198';
        true ->
             'sanguo_manage_xxx101@58.218.209.198'
    end.


get_sid() ->
    % {ok,Base} = application:get_env(server, base),
    Node = atom_to_list(node()),
    Res = ((Node -- "sanguo_tiantang_s")--"managexxxTencent")--"center",
    Fun = fun(A) ->
        A /= 64
    end,
    {Sid,_} = lists:splitwith(Fun,Res),
    case Sid  of
        [] ->
            1;
        _ ->
            list_to_integer(Sid)
    end.






% get_man_node() -> 'sanguo_manage_xxx@127.0.0.1'.
%% desc:封装全平台唯一标识
%% in:plat_id::integer() 平台id
%%    sid::integer() 服务器id
%%    user_id::integer() 玩家id
%% out:key
record_uni_key(PlatId, Sid, UserId) ->
    {PlatId, Sid, UserId}.
record_uni_key(UserId) ->
    case catch misc:to_integer(config:read(node_id)) of
        NodeId when is_integer(NodeId) ->
            PlatId = config:read_deep([server, base, platform_id]),
            Sid    = config:read_deep([server, base, sid]),
            {PlatId, Sid, UserId};
        _ ->
            ?null
    end.

%% desc:跨平台cast
%% in:plat_id::integer() 平台id
%%    sid::integer() 服务器id
%%    mod::模块
%%    func::函数
%%    args::list() 参数列表
%% out:{?ok, Res}/{?error, ErrorCode}
cast(PlatId, Sid, Mod, Func, Args) ->
    CenterNode = get_center_node(PlatId),
    case catch center_serv_info_serv:get_node_call(CenterNode, Sid) of
        {?error, ?TIP_COMMON_ERR_NET} ->
            {?error, ?TIP_COMMON_ERR_NET};
        {NodeName, _NewNodeState} ->
            case catch rpc:cast(NodeName, Mod, Func, Args) of
                {badrpc, Reason} ->
                    ?MSG_ERROR("~p", [Reason]),
                    {?error, ?TIP_COMMON_ERR_NET};
                Res ->
                    {?ok, Res}
            end
    end.

%% desc:跨平台cast center
%% in:plat_id::integer() 平台id
%%    sid::integer() 服务器id
%%    mod::模块
%%    func::函数
%%    args::list() 参数列表
%% out:{?ok, Res}/{?error, ErrorCode}
cast(PlatId, Mod, Func, Args) ->
    CenterNode = get_center_node(PlatId, 1),
    case catch rpc:cast(CenterNode, Mod, Func, Args) of
        {badrpc, Reason} ->
            ?MSG_ERROR("~p", [Reason]),
            {?error, ?TIP_COMMON_ERR_NET};
        Res ->
            {?ok, Res}
    end.

%% desc:发向所有中心服
cast_all_center(Mod, Func, Args) ->
    L = ets:tab2list(?CONST_ETS_MAN_HOUTAI),
    L2 = [Node||#ets_man_houtai{node = Node, sid = 0}<-L],
    L3 = lists:usort(L2),
    Fun = fun(Node) ->
                  catch rpc:cast(Node, Mod, Func, Args)
          end,
    lists:map(Fun, L3).

%% desc:查询后台数据
%% in:plat_id :: integer() 平台id
%%    sid :: integer() 服务器id
%% out:node()/null
lookup_houtai_node(PlatId, Sid) ->
    case catch ets_api:lookup(?CONST_ETS_MAN_HOUTAI, {PlatId, Sid}) of
        #ets_man_houtai{node = Node} -> Node;
        _ -> ?null
    end.

%%===============================================================================
get_houtai_all() ->
    ets:tab2list(?CONST_ETS_MAN_HOUTAI).

%% desc:同步后台数据到各服
%% in:Type :: integer() 
%%                      1:同步各中心服;2:同步各普通服
rsync_houtai(1) ->
    L = get_houtai_all(),
    L2 = lists:usort(L),
    Fun = fun(#ets_man_houtai{sid = 0, node = Node}) ->
%%                   ?MSG_SYS("man->~p", [Node]),
                  catch rpc:cast(Node, center_i_serv, rsync_houtai_cast, [L]);
             (_) ->
                  ?ok
          end,
    lists:foreach(Fun, L2);
rsync_houtai(2) ->
    L = get_houtai_all(),
    L2 = lists:usort(L),
    PlatId = config:read_deep([server, base, platform_id]),
    Fun = fun(#ets_man_houtai{sid = Sid, node = Node, plat_id = PlatIdT}) when 0 =/= Sid andalso PlatIdT =:= PlatId ->
%%                   ?MSG_SYS("center->~p", [Node]),
                  catch rpc:cast(Node, ets_serv, rsync_houtai_cast, [L]);
             (_) ->
                  ?ok
          end,
    lists:foreach(Fun, L2).
rsync_houtai(2, L) ->
    L2 = lists:usort(L),
    PlatId = config:read_deep([server, base, platform_id]),
    Fun = fun(#ets_man_houtai{sid = Sid, node = Node, plat_id = PlatIdT}) when 0 =/= Sid andalso PlatIdT =:= PlatId ->
%%                   ?MSG_SYS("center->~p", [Node]),
                  catch rpc:cast(Node, ets_serv, rsync_houtai_cast, [L]);
             (_) ->
                  ?ok
          end,
    lists:foreach(Fun, L2).

%%
%% Local Functions
%%
update_serv_state(PlatId, Node, State) ->
    ets_api:insert(ets_serv_state, {Node, PlatId, State}).

ping(Node) ->
    case net_adm:ping(Node) of
        pong ->
            Node;
        pang ->
            ?null
    end.
    




    
