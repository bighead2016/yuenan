%% %%% 跨服信息提取
-module(misc_cross).
%% 
%% %%
%% %% Include files
%% %%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.data.hrl").
-include("record.base.data.hrl").
%% 
%% %%
%% %% Exported Functions
%% %%
-export([get_alive_nodes/0, update_node_info/2,
         get_physical_node_info/0]).

%%
%% API Functions
%%

%% 物理结点信息
%% misc_cross:get_physical_node_info().
get_physical_node_info() ->
    AliveNodeList = get_alive_nodes(),
    PlatId = config:read_deep([server, base, platform_id]),
    NodeList = get_physical_node_info(AliveNodeList, [], PlatId),
    ets:delete_all_objects(?CONST_ETS_CROSS_NODE_INFO),
    ets:insert(?CONST_ETS_CROSS_NODE_INFO, NodeList),
%%     ets:tab2list(?CONST_ETS_CROSS_NODE_INFO),
%%     ?MSG_SYS("cross:~n~p", [L]),
    NodeList.

get_physical_node_info([{LeaderId, Node, ServId}|Tail], OldList, PlatId) ->
%%     NodeInfo = rpc:call(Node, ?MODULE, get_self_node_info, []),
    NodeInfo = config:read(combine), %   data_misc:get_node_combine_list({ServId, PlatId}),
    NewList = 
        case lists:keytake(LeaderId, 1, OldList) of
            {value, {_, OldNodeList}, OldList2} ->
                NewNodeList = change(NodeInfo, Node, OldNodeList),
                [{LeaderId, NewNodeList}|OldList2];
            ?false ->
                ?MSG_SYS("~p|~p", [NodeInfo, Node]),
                NewNodeList = change(NodeInfo, Node, []),
                [{LeaderId, NewNodeList}|OldList]
        end,
    get_physical_node_info(Tail, NewList, PlatId);
get_physical_node_info([], List, _PlatId) ->
    List.

change([Sid|Tail], Node, OldList) ->
    case lists:keyfind(Sid, 1, OldList) of
        ?false ->        
            change(Tail, Node, [{Sid, Node}|OldList]);
        _ ->
            change(Tail, Node, OldList)
    end;
change([], _, List) ->
    List;
change(_, _, List) ->
    List.


get_cross_config() ->
    Sid = config:read_deep([server, base,sid]),
    ServList = 
    if 
        %%不做分中心服
        Sid =< 1000 -> [{1, lists:seq(1,100)}];

        Sid =< 10 -> [{1, lists:seq(1,10)}];
        Sid =< 20 -> [{11, lists:seq(11,20)}];
        Sid =< 30 -> [{21, lists:seq(21,30)}];
        Sid =< 40 -> [{31, lists:seq(31,40)}];
        Sid =< 50 -> [{41, lists:seq(41,50)}];
        Sid =< 60 -> [{51, lists:seq(51,60)}];
        Sid =< 70 -> [{61, lists:seq(61,70)}];
        Sid =< 80 -> [{71, lists:seq(71,80)}];
        Sid =< 90 -> [{81, lists:seq(81,90)}];
        Sid =< 100 -> [{91, lists:seq(91,100)}];
        true -> [{101, lists:seq(101,200)}]
    end,

    
    PlatformId = config:read_deep([server, base, platform_id]),
    {ServList, PlatformId}.

%% 读取存活结点信息
get_alive_nodes() ->
    {ServList, PlatformId} = get_cross_config(),
    case center_api:get_all_serv_info() of
        {?ok, NodeList} ->
            {List, _} = get_alive_node(ServList, [], [], PlatformId, NodeList),
            List;
        {?error, _} ->
            []
    end.

get_alive_node([{ServId, SidList}|Tail], OldAliveList, OldDeadList, PlatformId, NodeList) ->
    SidList2 = lists:reverse(SidList),
    {AliveList, DeadList} = get_alive_node_2(ServId, SidList2, OldAliveList, OldDeadList, PlatformId, NodeList),
    get_alive_node(Tail, AliveList, DeadList, PlatformId, NodeList);
get_alive_node([], AliveList, DeadList, _PlatformId, _NodeList) ->
    {AliveList, DeadList}.

get_alive_node_2(LeaderId, [ServId|Tail], OldAliveList, OldDeadList, PlatformId, NodeList) ->
    NodeName = get_node_name(ServId, NodeList),
    case chk_alive(NodeName) of
        ?CONST_SYS_TRUE ->
            get_alive_node_2(LeaderId, Tail, [{LeaderId, NodeName, ServId}|OldAliveList], OldDeadList, PlatformId, NodeList);
        ?CONST_SYS_FALSE ->
            get_alive_node_2(LeaderId, Tail, OldAliveList, [{LeaderId, NodeName, ServId}|OldDeadList], PlatformId, NodeList)
    end;
get_alive_node_2(_LeaderId, [], AliveList, DeadList, _PlatformId, _NodeList) ->
    {AliveList, DeadList}.

get_node_name(ServId, NodeList) when is_list(NodeList) ->
    case lists:keyfind(ServId, #ets_serv_info.sid, NodeList) of
        #ets_serv_info{node_name = NodeName} ->
            NodeName;
        ?false ->
            ?undefined
    end;
get_node_name(_, _) ->
    ?undefined.

%% 更新结点信息
update_node_info(Node, SidList) ->
    ets:insert(ets_cross_node_info, {Node, SidList}).
    

%%
%% Local Functions
%%

%% 存活证明
chk_alive(NodeName) -> 
    case net_adm:ping(NodeName) of
        pong ->
            case rpc:call(NodeName, ets, info, [?CONST_ETS_PLAYER_ONLINE, size]) of
                C when C >= 0 ->
                    ?CONST_SYS_TRUE;
                _ ->
                    case config:read_deep([server, base, debug]) of
                        ?CONST_SYS_TRUE ->
                            ?CONST_SYS_TRUE;
                        ?CONST_SYS_FALSE ->
                            ?CONST_SYS_FALSE
                    end
            end;
        pang ->
            ?CONST_SYS_FALSE
    end.


