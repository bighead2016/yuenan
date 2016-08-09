-module (server_tools).

-include_lib("kernel/include/file.hrl").

-compile(export_all).

-define(TMP_FILE, "/tmp/result_tmp_file").

stop_srv([ConfigFile]) ->
	{ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),

	ThisNode = list_to_atom("stop_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
			file:write(Fd, io_lib:format("Init node failed, reason: ~p~n", [Reason])),
			% io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pang ->
					file:write(Fd, io_lib:format("ping server node: ~w failed!!!~n", [ServerNode])),
					io:format("ping server node: ~w failed!!!~n", [ServerNode]);
				pong ->
					file:write(Fd, io_lib:format("ping server node: ~w success!!!~n", [ServerNode])),
					file:write(Fd, io_lib:format("~n*********** start stop server node: ~w ***********~n~n", [ServerNode])),
					io:format("ping server node: ~w success!!!~n", [ServerNode]),
					io:format("~n*********** start stop server node: ~w ***********~n~n", [ServerNode]),
					Result = rpc:call(ServerNode, main, stop, []),
					file:write(Fd, io_lib:format("~n*********** stop server node return: ~p ***********~n~n", [Result])),
					io:format("~n*********** stop server node return: ~p ***********~n~n", [Result]),
					timer:sleep(1500)
			end,
			case net_adm:ping(LogNode) of
				pang ->
					file:write(Fd, io_lib:format("ping log node: ~w failed!!!~n", [LogNode])),
					io:format("ping log node: ~w failed!!!~n", [LogNode]);
				pong ->
					file:write(Fd, io_lib:format("*********** start stop log node: ~w ***********~n", [LogNode])),
					io:format("*********** start stop log node: ~w ***********~n", [LogNode]),
					rpc:call(LogNode, log, stop, []),
					timer:sleep(1500)
			end,
			true
	end,
	io:format("=========== end of stop server ===========~n"),
	file:write(Fd, "=========== end of stop server ===========~n"),
	file:sync(Fd),
	file:close(Fd),
	init:stop().

srv_status([ConfigFile]) ->
	{ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),

	ThisNode = list_to_atom("status_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
			file:write(Fd, io_lib:format("Init node failed, reason: ~p~n", [Reason])),
			% io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pong ->
					file:write(Fd, io_lib:format("server node: ~w is [alive]~n~n", [ServerNode]));
					% io:format("server node: ~w is [alive]~n~n", [ServerNode]);
				pang ->
					file:write(Fd, io_lib:format("server node: ~w is [die]~n~n", [ServerNode]))
					% io:format("server node: ~w is [die]~n~n", [ServerNode])
			end,
			case net_adm:ping(LogNode) of
				pong ->
					file:write(Fd, io_lib:format("log node: ~w is [alive]~n~n", [LogNode]));
					% io:format("log node: ~w is [alive]~n~n", [LogNode]);
				pang ->
					file:write(Fd, io_lib:format("log node: ~w is [die]~n~n", [LogNode]))
					% io:format("log node: ~w is [die]~n~n", [LogNode])
			end
	end,
	file:write(Fd, "=========== end of get servre status ===========~n"),
	file:sync(Fd),
	file:close(Fd),
	init:stop().

hot_reload([ConfigFile]) ->
	%%{ok, #file_info{mtime = LastTime}} = file:read_file_info("temp"),
	LastTime = 0,
	% {ok, Fd} = file:open(?TMP_FILE, [write]),
	{ServerNode, _LogNode, Cookie} = get_nodes_info(atom_to_list(ConfigFile)),
	ThisNode = list_to_atom("reload_" ++ atom_to_list(ServerNode)),

	case net_kernel:start([ThisNode]) of
		{error, Reason} ->
	
			% file:write(Fd, io_lib:format("Init node failed, reason: ~p", [Reason])),
			io:format("Init node failed, reason: ~p", [Reason]),
			false;
		{ok, _Pid} ->
			erlang:set_cookie(ThisNode, Cookie),
			case net_adm:ping(ServerNode) of
				pong ->
					%% do reload
					ALLCode = rpc:call(ServerNode, util, get_all_module_info, []),
					Module_list = do_reload(ServerNode, ALLCode, LastTime,[]),

					Load_module = fun(Module)->
						rpc:call(ServerNode, code, load_file, [Module]),
						io:format("reloaded ~p ~n",[Module])
					end,
					[Load_module(Module) || Module <- Module_list]; 
					 
				pang ->
					% file:write(Fd, io_lib:format("server node: ~w is [die]~n~n", [ServerNode]))
					io:format("server node: ~w is [die]~n~n", [ServerNode])
			end
	end,
	% file:write(Fd, "=========== end of hot reload ===========~n"),
	% file:sync(Fd),
	% file:close(Fd),
	init:stop().
%%{Module, Filename} <- ALLCode, is_list(Filename)];
do_reload(_ServerNode,[] , _LastTime, Module_list) -> Module_list;
do_reload(ServerNode, [{Module, Version, FileName} | Rest], LastTime, Module_list) ->
    case rpc:call(ServerNode, code, is_sticky, [Module]) of
        true->
            do_reload(ServerNode, Rest, LastTime, Module_list);
        false ->
            case beam_lib:version(FileName) of
                {ok, {Module, [NewVersion | _]}} ->
                    case Version =/= NewVersion of
                        true ->
                            PurgeResult = rpc:call(ServerNode, code, soft_purge, [Module]), 
                            %%rpc:call(ServerNode, code, load_file, [Module]),
                            % file:write(Fd, io_lib:format("reloading: [~w]~n", [Module]));
                            io:format("reloading: [~w], purge result ~w~n", [Module, PurgeResult]),
                            do_reload(ServerNode, Rest, LastTime, [Module | Module_list]);
                        false ->
                            do_reload(ServerNode, Rest, LastTime, Module_list)
                    end;
                {error, beam_lib, {missing_chunk, _, _}} ->
                    PurgeResult = rpc:call(ServerNode, code, soft_purge, [Module]), 
                    io:format("reloading: [~w(stripped)], purge result ~w~n", [Module, PurgeResult]),
                    do_reload(ServerNode, Rest, LastTime, [Module | Module_list]);
                {error, beam_lib, {file_error, _, enoent}} ->	
                    do_reload(ServerNode, Rest, LastTime, Module_list);
                {error, beam_lib, Reason} ->	
                    % file:write(Fd, io_lib:format("Error reading ~s's file info: ~p~n", [FileName, Reason]));
                    io:format("Error reading ~s's file info: ~p~n", [FileName, Reason]),
                    do_reload(ServerNode, Rest, LastTime, Module_list);
                _Other ->
                    io:format("WTF?! FileName = ~s, _Other = ~w~n", [FileName, _Other]),
                    do_reload(ServerNode, Rest, LastTime, Module_list)
            end
    end.

get_nodes_info(ConfigFile) -> 
	{ok, [Terms]} = file:consult(ConfigFile),
	{server, KeyValueList} = lists:keyfind(server, 1, Terms),
	{node_name, ServerNode} = lists:keyfind(node_name, 1, KeyValueList),
	{log_node, LogNode} = lists:keyfind(log_node, 1, KeyValueList),
	{node_cookie, Cookie} = lists:keyfind(node_cookie, 1, KeyValueList),
	{ServerNode, LogNode, Cookie}.

get_center_name_list() ->
    CenterInfoList = data_misc:get_platform_list(),
    Fun =
        fun({_, IpBinary,NameBinary}) ->
                Ip = binary_to_list(IpBinary),
                Name = binary_to_list(NameBinary),
                string:join(["sanguo_", Name, "_center@", Ip], "")
        end,
    lists:map(Fun, CenterInfoList).



get_vsn(Module,Node) ->
    case catch rpc:call(Node, Module, module_info,[attributes]) of
        Att when is_list(Att) ->
            case lists:keyfind(vsn, 1, Att) of
                {vsn, Vsn} ->
                    Vsn;
                _ ->
                    0
            end;
        _ ->
            0
    end.

get_base_vsn(Module) ->
    BaseNode = 'sanguo_4399_center@183.61.136.81',
    get_vsn(Module,BaseNode).

check_center_vsn(Module) ->
    case get_base_vsn(Module) of
        0 ->
            io:format("check vsn failed, can not get base vsn !");
        BaseVsn ->
            CenterList = get_center_name_list(),
            Result = check_center_vsn(BaseVsn, Module, CenterList),
            case Result of
                {false, Center, Vsn} ->
                    io:format("check vsn failed, basevsn is ~w, but node ~w 's vsn is ~w !", [BaseVsn, Center, Vsn]);
                _ ->
                    io:format("check vsn success, all ~w's center vsn is ~w", [length(CenterList), BaseVsn])
            end
    end.

check_center_vsn(_BaseVsn, _Module, []) ->
    true;
check_center_vsn(BaseVsn, Module, [Center|Rest]) ->
     Vsn = get_vsn(Module, Center),
     case Vsn  of
         0 ->
             {false, Center, Vsn};
         BaseVsn ->
             check_center_vsn(BaseVsn, Module, Rest);
         _ ->
             {false, Center, Vsn}
     end.

%% 热更58
%% 把本地beam文件热更到58服务器上
%% server_tools:hot58(player_api).
hot58(NameAtom) ->
    NameStr = atom_to_list(NameAtom),
    OldCookie = erlang:get_cookie(),
    erlang:set_cookie(node(), 'sanguo_1'),
    {ok, Binary} = file:read_file(NameStr ++ ".beam"),
    Node = 'sanguo_1@172.16.10.120',
    rpc:call(Node, server_tools, write_file, [NameStr, Binary]),
    erlang:set_cookie(node(), OldCookie).

write_file(Name, Binary) ->
    BaseDir = "../ebin/",
    Result = file:write_file(BaseDir ++ Name ++ ".beam", Binary),
    io:format("result is ~w~n", [Result]),
    c:l(erlang:list_to_atom(Name)).