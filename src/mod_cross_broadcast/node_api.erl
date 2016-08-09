%% author: xujingeng
%% create: 2013-11-28
%% desc: 跨服转发接口函数
%%

-module(node_api).

-include("const.common.hrl").
-include("record.base.data.hrl").
-include("const.define.hrl").
-include("record.data.hrl").

-export([
		 get_cross_node_name/0,
		 send_info/2,
		 center_to_node/3,
		 get_local_node_info/0,
		 insert_node_info/2,
		 lookup_node_info/1
		]).


%% 获取跨服节点配置 XXX
get_cross_config() ->
	ServId      = config:read_deep([server, base, sid]),
%%     NodePre     =
%%         case config:read(platform_info, #rec_platform_info.node_pre) of
%%             ?null ->
%%                 "";
%%             NodePreT ->
%%                 NodePreT
%%         end,
%%     NodeSuf     = 
%%         case config:read(server_info, #rec_server_info.node_suffix) of
%%             ?null ->
%%                 "";
%%             NodeSufT ->
%%                 NodeSufT
%%         end,
    {ServId, "", ""}.

%% 读取对应的结点名
get_cross_node_name() ->
	{ServId, NodePre, NodeSuf} = get_cross_config(),
    Result = misc:to_atom(lists:concat([NodePre, ServId, NodeSuf])),
	Result.

%% 发送消息给转发进程
send_info(Handler, Packet) ->
	Pid = erlang:whereis(node_serv),
	case erlang:is_pid(Pid) andalso erlang:is_process_alive(Pid) of
		?true ->	
			Pid ! {local_to_center, {Handler, Packet}};
		_ ->
			?MSG_SYS("node_serv process is down"),
			?ignore
	end.

%% 中心节点发送到普通节点
center_to_node(SourceNode, Handler, Packet) ->
	NodeList = nodes() -- [SourceNode],
	F = fun(NodeName) ->
				case lookup_node_info(NodeName) of
					?null ->
						?MSG_SYS("the center node no have the node info Node:~w", [NodeName]),
						?ignore;
					#ets_node_info{info_list = InfoList} ->
						case lists:keyfind(Handler, #rec_mod_switch.mod_handler, InfoList) of
							#rec_mod_switch{} ->
								erlang:send({node_serv, NodeName}, {recv_broadcast, SourceNode, {Handler, Packet}}),
								?ok;
							?false ->
								?MSG_SYS("author fail handler NodeName:~w, Handler:~w", [NodeName, Handler]),
								?ignore
						end
				end
		end,
	[F(Node) || Node <- NodeList],
	?ok.

%% 获取本地的节点信息
get_local_node_info() ->
	Length = (data_cross_broadcast:get_mod_handler_sw(0))#rec_mod_switch.switch,
	case Length > 0 andalso erlang:is_integer(Length) of
		?true ->
			F = fun(Id) ->
						Rd = data_cross_broadcast:get_mod_handler_sw(Id),
						{Rd#rec_mod_switch.id, Rd#rec_mod_switch.switch}
				end,
			[F(Id) || Id <- lists:seq(1, Length)];
		?false ->
			[]
	end.

%% 保存节点信息
%% 中心节点不保存节点信息
insert_node_info(NodeName, InfoList) when NodeName =:= erlang:node() ->
	?MSG_SYS("center noded no save info:~w,~w", [node(), InfoList]),
	?ignore;
insert_node_info(NodeName, InfoList) ->
	NewInfoList = transfer_info(InfoList),
	ets_api:insert(?CONST_ETS_NODE_INFO, {ets_node_info, NodeName, NewInfoList, misc:seconds()}).

%% 把协议id信息转成协议信息
transfer_info(InfoList) ->
	F = fun({Id, Switch}) ->
				Rd = data_cross_broadcast:get_mod_handler_sw(Id),
				Rd#rec_mod_switch{switch = Switch}
		end,
	[F(E) || E <- InfoList].
				
%% 查询节点信息
lookup_node_info(NodeName) ->
	ets_api:lookup(?CONST_ETS_NODE_INFO, NodeName).
