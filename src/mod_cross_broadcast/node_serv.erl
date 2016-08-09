%% author: xujingeng
%% create: 2013-11-27
%% desc: 跨节点服务
%%

-module(node_serv).

-include("const.common.hrl").

-behaviour(gen_server).

-export([init/1, handle_cast/2, handle_call/3, handle_info/2, terminate/2, code_change/3]).

-export([start/0, start_link/2]).

-compile(export_all).

-record(state, {}).

start() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).
	
init([]) ->
	{?ok, #state{}}.

handle_cast(_Msg, State) ->
	{?noreply, State}.

handle_call(_Request, _From, State) ->
	Reply = ?ok,
	{?reply, Reply, State}.

handle_info({local_to_center, {Handler, Packet}}, State) ->
	try
		do_local_to_center({Handler, Packet}),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info({node_broadcast, SourceNode, {Handler, Packet}}, State) ->
	try
		do_broadcast(SourceNode, {Handler, Packet}),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info({recv_broadcast, SourceNode, {Handler, Packet}}, State) ->
	try
		do_recv_broadcast(SourceNode, {Handler, Packet}),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info(_Info, State) ->
	{?noreply, State}.

terminate(_Reason, _State) ->
	?ok.

code_change(_OldVsn, State, _Extra) ->
	{?ok, State}.

%%===========================
%% 本地节点发送给中心节点
do_local_to_center({Handler, Packet}) ->
	CrossServName = node_api:get_cross_node_name(),
	?MSG_SYS("CrossServName:~w", [CrossServName]),
	erlang:send({?MODULE, CrossServName}, {node_broadcast, node(), {Handler, Packet}}),
	?ok.

%% 中心节点转发消息
do_broadcast(SourceNode, {Handler, Packet}) ->
	CrossServName = node_api:get_cross_node_name(),
	case node() of
		CrossServName ->
			?MSG_SYS("the center node:~w", [node()]),
			node_api:center_to_node(SourceNode, Handler, Packet),
			?ok;
		Other ->
			?MSG_SYS("not the CenterNode:~w", [Other]),
			?ignore
	end.

%% 其他非消息源节点发送消息给前端
do_recv_broadcast(SourceNode, {Handler, Packet}) ->
	?MSG_SYS("recv broadcast SourceNode:~w, Handler:~w, Packet:~w", [SourceNode, Handler, Packet]),
	misc_app:broadcast_world(Packet),
	?ok.
