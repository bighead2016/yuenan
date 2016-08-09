%% @author jin
%% @doc @todo Add description to center_serv_info_serv.


-module(center_serv_info_serv).
-behaviour(gen_server).

-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("record.data.hrl").

-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([start_link/0, start_link/2, get_all_serv_info_call/0, get_all_node_call/0,
         get_node_call/2]).



%% ====================================================================
%% Behavioural functions 
%% ====================================================================
-record(state, {}).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

start_link(ServName, _Cores) ->
    misc_app:gen_server_start_link(ServName, ?MODULE, []).

%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
%% ====================================================================
init([]) ->
	%ServInfos = center_api:get_all_serv_info(),
	%init_serv_ets(ServInfos),
    {?ok, #state{}}.


%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
%% ====================================================================
handle_call(Request, From, State) ->
	try do_call(Request, From, State) of
		{?reply, Reply, State2} -> {?reply, Reply, State2}
	catch Type:Reason ->
			  ?MSG_ERROR("Type:~p Reason:~p, Strace:~p~n", [Type, Reason, erlang:get_stacktrace()]),
			  {?noreply, State}
	end.


%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
%% ====================================================================
handle_cast(_Msg, State) ->
    {?noreply, State}.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
%% ====================================================================
handle_info(Info, State) ->
	try do_info(Info, State) of
		{?noreply, State2} -> {?noreply, State2}
	catch Type:Reason ->
			  ?MSG_ERROR("Type:~p Reason:~p, Strace:~p~n", [Type, Reason, erlang:get_stacktrace()]),
			  {?noreply, State}
	end.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
%% ====================================================================
terminate(_Reason, _State) ->
    ?ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
%% ====================================================================
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.


%% ====================================================================
%% Internal functions
%% ====================================================================
%% init_serv_ets(ServInfos) ->
%% 	F = fun({ServId, NodeName}) ->
%% 				case ets_api:lookup(?CONST_ETS_SERV_INFO, ServId) of
%% 					?null ->
%% 						case net_adm:ping(NodeName) of
%% 							pong ->
%% 								ServInfoRec = #ets_serv_info{
%% 															 sid = ServId,
%% 															 node_name = NodeName,
%% 															 state = ?CONST_CENTER_STATE_NORMAL,
%% 															 time = misc:seconds()
%% 															},
%% 								ets_api:insert(?CONST_ETS_SERV_INFO, ServInfoRec);
%% 							pang ->
%% 								?ignore
%% 						end;
%% 					ServInfoRec ->
%% 						motify_serv_info(ServInfoRec)
%% 				end
%% 		end,
%% 	[F(E) || E <- ServInfos].

do_call({get, SId}, _From, State) ->
	Reply =
		case ets_api:lookup(?CONST_ETS_SERV_INFO, SId) of
			?null ->
				{?error, ?CONST_CENTER_STATE_UNKNOWN};
			ServInfoRec ->
				motify_serv_info(ServInfoRec)
		end,
	{?reply, Reply, State};
do_call(get_all_serv_info, _From, State) ->
%% 	Reply = ets:tab2list(?CONST_ETS_SERV_INFO),
	Reply = get_all_server_info(),
	{?reply, {?ok, Reply}, State};
do_call(get_all_node, _From, State) ->
	Reply = make_node_list(),
	{?reply, {?ok, Reply}, State};
do_call(Request, From, State) ->
	?MSG_ERROR("Request:~p, From:~p", [Request, From]),
	{?reply, ?ok, State}.

do_info({recv, {SId, NodeName, NodeState}}, State) ->
	ets_api:insert(?CONST_ETS_SERV_INFO, #ets_serv_info{sid = SId, node_name = NodeName, state = NodeState, time = misc:seconds()}),
	{?noreply, State};
do_info({recv, List}, State) ->
	[ets_api:insert(?CONST_ETS_SERV_INFO, #ets_serv_info{sid = SId, node_name = NodeName, state = NodeState, time = misc:seconds()})||{SId, NodeName, NodeState}<-List],
	{?noreply, State};
do_info({update, {NodeName, ServList, NodeState}}, State) ->
	F = fun(Id) ->
				ets_api:insert(?CONST_ETS_SERV_INFO, #ets_serv_info{sid = Id, node_name = NodeName, state = NodeState, time = misc:seconds()})
		end,
	[F(E) || E <- ServList],
	{?noreply, State};
do_info(Info, State) ->
	?MSG_ERROR("error info:~p", [Info]),
	{?noreply, State}.


get_all_server_info() ->
	case ets:first(?CONST_ETS_SERV_INFO) of
		'$end_of_table' -> [];
		Key	->
			List		= get_all_server_info(Key, []),
			get_all_server_info1(Key, List)
			
	end.

get_all_server_info(Key, Acc) ->
	case ets_api:lookup(?CONST_ETS_SERV_INFO, Key) of
		?null -> [];
		Info  -> [Info|Acc]
	end.

get_all_server_info1(Key, Acc) ->
	case ets:next(?CONST_ETS_SERV_INFO, Key) of
		'$end_of_table' -> Acc;
		Key1 ->
			Acc1		= get_all_server_info(Key1, Acc),
			get_all_server_info1(Key1, Acc1)
	end.
		
motify_serv_info(#ets_serv_info{sid = SId, node_name = NodeName, state = NodeState}) ->
	NewNodeState =
		case net_adm:ping(NodeName) of
			pong ->
				?CONST_CENTER_STATE_NORMAL;
			pang ->
				case NodeState of
					?CONST_CENTER_STATE_NORMAL -> ?CONST_CENTER_STATE_NET;
					_ -> NodeState
				end
		end,
	ets_api:update_element(?CONST_ETS_SERV_INFO, SId, {#ets_serv_info.state, NewNodeState}),
	{NodeName, NewNodeState}.

%% 读取所有结点信息
get_all_serv_info_call() ->
    CenterNode = center_api:get_center_node(),
    case net_adm:ping(CenterNode) of
        pong ->
            gen_server:call({center_serv_info_serv, CenterNode}, get_all_serv_info, ?CONST_TIMEOUT_CALL);
        pang ->
            {?error, ?TIP_COMMON_ERR_NET}
    end.

%% 读取所有结点信息
get_all_node_call() ->
    CenterNode = center_api:get_center_node(),
    case net_adm:ping(CenterNode) of
        pong ->
            gen_server:call({center_serv_info_serv, CenterNode}, get_all_node, ?CONST_TIMEOUT_CALL);
        pang ->
            {?error, ?TIP_COMMON_ERR_NET}
    end.

%% 封装结点列表
make_node_list() ->
    Key = ets:first(?CONST_ETS_SERV_INFO),
    make_node_list(Key, []).
make_node_list('$end_of_table', OldList) ->
    lists:usort(OldList);
make_node_list(Key, OldList) ->
    case ets_api:lookup(?CONST_ETS_SERV_INFO, Key) of
        ?null ->
            Key2 = ets:next(?CONST_ETS_SERV_INFO, Key),
            make_node_list(Key2, OldList);
        #ets_serv_info{node_name = Node} ->
            Key2 = ets:next(?CONST_ETS_SERV_INFO, Key),
            make_node_list(Key2, [Node|OldList])
    end.

%%
get_node_call(CenterNode, Sid) ->
    case net_adm:ping(CenterNode) of
        pong ->
            gen_server:call({center_serv_info_serv, CenterNode}, {get, Sid}, ?CONST_TIMEOUT_CALL);
        pang ->
            {?error, ?TIP_COMMON_ERR_NET}
    end.

