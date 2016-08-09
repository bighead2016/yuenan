%% author: xujingeng
%% create: 2013-11-26
%% desc: 节点单播
%%

-module(node_unicast).

-include("const.common.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

-behaviour(gen_server).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%%-compile(export_all).
-export([start/0, start_link/2]).

-record(state, {}).
-define(TIME_LOOP, 60*1000). %% 定时60秒
-define(TIME_INTERVAL, 3600).%% 间隔一小时

start() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).

init([]) ->
	erlang:send_after(?TIME_LOOP, self(), do_loop),
	?MSG_SYS("node_unicast init Pid = ~w", [self()]),
	{?ok, #state{}}.

handle_call(_Request, _From, State) ->
	Reply = ?ok,
	{?reply, Reply, State}.

handle_cast(_Msg, State) ->
	{?noreply, State}.

%% 循环消息
handle_info(do_loop, State) ->
	try
		do_loop(),
		erlang:send_after(?TIME_LOOP, self(), do_loop),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
%% 获取节点在中心节点信息状态
handle_info({NodeName, Pid, get_state}, State) ->
	try
		?MSG_SYS("NodeName:~w, Pid:~w", [NodeName, Pid]),
		do_query(NodeName, Pid, get_state),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
%% 对中心节点发来的节点状态信息做相应的处理
handle_info({_NodeName, _Pid, state, 1}, State) ->
	try
		?MSG_SYS("have info node:~w, pid:~w", [node(), self()]),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info({NodeName, Pid, state, Any}, State) ->
	try
		?MSG_SYS("Any message:~w", [Any]),
		case NodeName =:= node() andalso Pid =:= self() of
			?true ->
				InfoList = node_api:get_local_node_info(),
				?MSG_SYS("send InfoList:~w", [InfoList]),
				CrossServName = node_api:get_cross_node_name(),
				erlang:send({?MODULE, CrossServName}, {node_info, node(), InfoList});
			?false ->
				?ignore
		end,
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
%% 节点信息
handle_info({node_info, NodeName, InfoList}, State) ->
	try
		?MSG_SYS("NodeName:~w, InfoList:~w", [NodeName, InfoList]),
		node_api:insert_node_info(NodeName, InfoList),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info({print, Pid}, State) ->
	try
		?MSG_SYS("self = ~w, FromPid:~w", [self(), Pid]),
		{?noreply, State}
	catch
		E:R ->
			?MSG_SYS("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()]),
			{?noreply, State}
	end;
handle_info(_Info, State) ->
	{?noreply, State}.

terminate(_Reason, _State) ->
	?MSG_SYS("Reason:~w", [_Reason]),
	?ok.

code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%%===================================
%% 定时循环ping
do_loop() ->
	CrossServName = node_api:get_cross_node_name(),
	case node() of
		CrossServName ->	%% 中心节点不进行ping操作
			?ignore;
		_ ->
			?MSG_SYS("cross ping:~w", [CrossServName]),
			case net_adm:ping(CrossServName) of
				pong ->
					erlang:send({?MODULE, CrossServName}, {node(), self(), get_state});
				pang ->
					?ignore
			end
	end.

%% 查询节点信息状态
do_query(NodeName, Pid, get_state) ->
	State =
		case node_api:lookup_node_info(NodeName) of
			?null ->
				0;
			NodeInfo ->
				case misc:seconds() - NodeInfo#ets_node_info.update_time >= ?TIME_INTERVAL of
					?true ->
						2;
					?false ->
						1
				end
		end,
	?MSG_SYS("do_query NodeName:~w, Pid:~w", [NodeName, Pid]),
	erlang:send({?MODULE, NodeName}, {NodeName, Pid, state, State}).
