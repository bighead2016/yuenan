%% Author: PXR
%% Created: 2013-8-20
%% Description: 跨服用
-module(cross_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.map.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([cross_jump_out/2, get_arena_master/0, get_camp_node/0, asy_node_info/0]).
-export([check_is_cross_in_user/1, send_jump_out_packet/1,get_camp_master/2]).
-export([get_self_node/0, get_self_index/0, get_self_port/0, get_master_port/0, get_master_node/0, get_boss_master/3]).
-export([add_node_2_master/1, update_nodes_config/1, broad_node_2_slave/0]).

-export([msg_cross_jump/3, check_config/0, get_node/1, get_index_from/1]).


get_index_from(UserId) ->
    (UserId div ?CONST_SYS_MAX_USER_INDEX) + 1. 

get_node(Index) ->
    case ets:lookup(?CONST_ETS_NODES_CONFIG, Index) of
        [] ->
            node();
        [Rec] ->
            NodeName = Rec#cross_node_config.node_name,
            list_to_atom(NodeName)
    end.

check_config() ->
    Master = get_master_node(),
    case net_adm:ping(Master) of
        'pong' ->
            io:format("1.check logic master ok~n"),
            ok;
        _ ->
            io:format("can not connect master !!!!~n")
    end,
    ArenaMaster = get_arena_master(),
    case net_adm:ping(ArenaMaster) of
        'pong' ->
            io:format("2.check arena master ok~n"),
            ok;
        _ ->
            io:format("can not connect arena master !!!!~n")
    end,
    {CampMaster, _} = get_camp_master(9999999, 35),
    case net_adm:ping(CampMaster) of
        'pong' ->
            io:format("3.check camp master ok~n"),
            rpc:call(Master, camp_pvp_counter_serv, reset_cast, []),
            ets:delete_all_objects(?CONST_ETS_CROSS_OUT);
        _ ->
            io:format("can not connect CampMaster master !!!!~n")
    end,
    io:format("check cross config finish~n").
%%
%% API Functions
%%
check_is_cross_in_user(UserId) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            false;
        _ ->
            true
    end.



cross_jump_out(UserId, CB) ->
    case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
        [] ->
            Player = player_api:get_user_info_by_id(UserId),
            MasterNode = get_master_node(),
            Node = node(),
            rpc:call(MasterNode, ets, insert, 
                [?CONST_ETS_CROSS_IN, #cross_in{user_id = UserId, call_back = CB, player_data = Player, node = Node}]),
            ets:insert(?CONST_ETS_CROSS_OUT, #cross_out{user_id = UserId, call_back = CB}),
            send_jump_out_packet(UserId);
        [_O] ->
            ?MSG_DEBUG("ERR", [])
    end.

send_jump_out_packet(UserId) ->
    MasterNode = get_master_node(),
    MasterStr = atom_to_list(MasterNode),
    [_, Ip] = string:tokens(MasterStr, "@"),
    ?MSG_ERROR("master ip is ~s", [Ip]),
    Port = get_master_port(),
    msg_cross_jump(Ip, Port, UserId).

get_self_port() ->
   {ok, Port} = config:read_deep([server, base, port]), %application:get_env(gateway, port),
   Port.

get_self_node() ->
   node().

get_arena_master() ->
    PlatId = config:read_deep([server, base, platform_id]),
    case PlatId == ?CONST_SYS_PLATFORM_4399 andalso new_serv_api:is_new_serv_1() of
        true ->
            node();
        _ ->
            Index = get_self_index(),
            case data_arena_pvp:get_cross(Index) of
                Config when is_tuple(Config) ->
                    MasterIndex = Config#rec_arena_pvp_cross.master_indxe,
                    case ets:lookup(?CONST_ETS_NODES_CONFIG, MasterIndex) of
                        [] ->
                            node();
                        [MasterRec] ->
                            NodeName = MasterRec#cross_node_config.node_name,
                            list_to_atom(NodeName)
                    end;
                _ ->
                    node()
            end
    end.

get_master_port() ->
   Port = config:read_deep([server, base, gm_port]), %application:get_env(gateway, master_port),
   Port.
get_master_node() ->
    case config:read(master_node) of
        ?null -> 
            erlang:node();
        MasterNode ->
            misc:to_atom(MasterNode)
    end.

get_camp_master(UserList, Lv) when is_list(UserList)->
        Index = get_self_index(),
        Master1 = get_master_node(),
        {RoomId, Master, CampId} = rpc:call(Master1, camp_pvp_counter_serv, in_call, [Index, UserList, Lv]),
        Fun =
            fun(UserId) ->
                ets:insert(?CONST_ETS_CROSS_OUT, #cross_out{user_id = UserId, node = Master, room_id = RoomId, camp_id = CampId})
            end,
        lists:foreach(Fun, UserList),
        {Master, RoomId};

get_camp_master(UserId, Lv) ->
    case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
        [] ->
            Index = get_self_index(),
            Master1 = get_master_node(),
            {RoomId, Master, CampId} = rpc:call(Master1, camp_pvp_counter_serv, in_call, [Index, [UserId], Lv]),
            ets:insert(?CONST_ETS_CROSS_OUT, #cross_out{user_id = UserId, node = Master, room_id = RoomId, camp_id = CampId}),
            {Master, RoomId};
        [CrossOut] ->
            {CrossOut#cross_out.node, CrossOut#cross_out.room_id}
    end.

%% 获取boss的主节点
get_boss_master(UserId, Lv, IsRobot) ->
	try
		case ets_api:lookup(?CONST_ETS_BOSS_CROSS_OUT, UserId) of
			?null ->
				Index			= get_self_index(),
				Master1			= get_master_node(),
				{RoomId, Master, LvPhase}	= 
					case node() of
						Master1 ->
							boss_cross_counter_serv:in_call(Index, [UserId], Lv, IsRobot);
						_ ->
							rpc:call(Master1, boss_cross_counter_serv, in_call, [Index, [UserId], Lv, IsRobot])
					end,
				%%			?MSG_DEBUG("111111111111111111~p", [{UserId, Lv, Master}]),
				ets_api:insert(?CONST_ETS_BOSS_CROSS_OUT, #ets_boss_cross_out{user_id = UserId, node = Master, room_id = RoomId, lv_phase = LvPhase}),
				{Master, RoomId, LvPhase};
			CrossOut ->
				%%			?MSG_DEBUG("11111111111111111111~p", [{UserId, Lv, CrossOut}]),
				{CrossOut#ets_boss_cross_out.node, CrossOut#ets_boss_cross_out.room_id, CrossOut#ets_boss_cross_out.lv_phase}
		end
	catch
		_:_ ->
			Master2		= node(),
			ets_api:insert(?CONST_ETS_BOSS_CROSS_OUT, #ets_boss_cross_out{user_id = UserId, node = Master2, room_id =100 , lv_phase = 5}),
			{Master2, 100, 5}
	end.
			
get_camp_node() ->
    Index = get_self_index(),
    case data_arena_pvp:get_cross(Index) of
        Config when is_tuple(Config) ->
            MasterIndex = Config#rec_arena_pvp_cross.camp_index,
            case ets:lookup(?CONST_ETS_NODES_CONFIG, MasterIndex) of
                [] ->
                    node();
                [MasterRec] ->
                    NodeName = MasterRec#cross_node_config.node_name,
                    list_to_atom(NodeName)
            end;
        _ ->
            node()
    end.

get_self_index() ->
   config:read_deep([server, base, sid]). %application:get_env(server, serv_id),

%% master 执行
broad_node_2_slave() ->
    NodeList = ets:tab2list(?CONST_ETS_NODES_CONFIG),
    broad_node_2_slave(NodeList, NodeList).
broad_node_2_slave([], _NodeList) ->
    ok;
broad_node_2_slave([Node|RestNode], NodeList) ->
    NodeAtom = list_to_atom(Node#cross_node_config.node_name),
    rpc:cast(NodeAtom, ?MODULE, update_nodes_config, [NodeList]),
    broad_node_2_slave(RestNode, NodeList).


%% slave执行
update_nodes_config([]) ->
    ok;
update_nodes_config([Node|NodeList]) ->
    ets:insert(?CONST_ETS_NODES_CONFIG, Node),
    update_nodes_config(NodeList).

%% master 执行
add_node_2_master(NodeConfig) ->
    Name = NodeConfig#cross_node_config.node_name,
    Index = NodeConfig#cross_node_config.server_index,
    Now = misc:seconds(),
    case ets:lookup(?CONST_ETS_NODES_CONFIG, Index) of
        [] ->
            mysql_api:insert(game_cluster_node_config, [node_name, node_index, update_time], [Name, Index, Now]);
        [_Config] ->
            mysql_api:update(game_cluster_node_config, [{node_name, Name}, {update_time, Now}], [{node_index, Index}])
    end,
    ets:insert(?CONST_ETS_NODES_CONFIG, #cross_node_config{node_name = Name,
                                                           server_index = Index,
                                                           update_time = Now}),
    broad_node_2_slave().


%% 跨服跳转
%%[Ip,Port,CrossId]
msg_cross_jump(Ip,Port,CrossId) ->
    misc_packet:pack(?MSG_ID_CROSS_CROSS_JUMP, ?MSG_FORMAT_CROSS_CROSS_JUMP, [Ip,Port,CrossId]).


asy_node_info() ->
    NodeName = node(),
    Index = cross_api:get_self_index(),
    MasterNode = cross_api:get_master_node(),
    rpc:cast(MasterNode, cross_api, add_node_2_master, [#cross_node_config{server_index = Index, node_name = atom_to_list(NodeName), update_time = Index}]).