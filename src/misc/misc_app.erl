-module(misc_app).

%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("record.player.hrl").

-export([broadcast_world/1, broadcast_world_2/1]).
-export([net_name/1, player_name/1, send/2, send_fast/2,
		  load_beam/0, reload_beam/0, load_file/1, do_exist_app/0,
         load_config/0, load_config/1, load_config/2, load_beam/1,
         get_data_list/1, get_data_list_rev/1, stop_shell/0]).
-export([spawn/3, spawn/5, spawn_link/3, spawn_link/5]).
-export([generate_summer_codes/0, generate_order_codes/0,
		 generate_common_codes/3, increase_codes/2]).
-export([gen_server_start_link/2, gen_server_start_link/4,
		 gen_server_start_link/3, gen_server_start_link/5,
		 call/2, call/3,
		 call_timeout/3,
		 call_timeout/4,
		 cast/2, cast/3,
		 serv_name/2,serv_namecall/2]).
-export([
		 child_spec_list/7, child_spec_list/8,
		 child_spec/7,
		 list_to_string/4,
		 ping_node/1,
         processing_print/1,
         do_kill/1,
         mark_vsn/0,
         mark_vsn/1,
         is_same_vsn/0,
         mark_vsn_stop/0,
         is_same_vsn_stop/0,
         generate_template/8,
         make_gener/4
        ]).
-export([write_erl_file/4, write_erl_file_without_head/3, write_erl_file_only_head/3]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 广播相关
broadcast_world(Packet) ->
	gateway_worker_sup:broadcast_word(Packet).

broadcast_world_2(Packet) ->
	gateway_worker_sup:broadcast_world_2(Packet).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
net_name(UserId) ->
    misc:to_atom("net_" ++ misc:to_list(UserId)).
player_name(UserId) ->
    misc:to_atom("player_" ++ misc:to_list(UserId)).

send(_Socket,<<>>) -> ?true;
send(Socket,BinMsg) when is_port(Socket)->
    % ?MSG_DEBUG("send Socket:~p ,BinMsg = ~p ", [Socket,BinMsg]),
	?ANALYSIS(x2, 2, BinMsg),
	case gen_tcp:send(Socket,BinMsg) of
%% 	case send_fast(Socket,BinMsg) of
		?ok 			  -> ?true;
		{?error, _Reason} -> ?false % exit(Reason)
	end;
send(Mpid,BinMsg) when is_pid(Mpid) ->
    ?MSG_DEBUG("send Mpid:~p ,BinMsg = ~p ", [Mpid,BinMsg]),
	case misc:send_to_pid(Mpid, {send, BinMsg}) of
		?true  -> ?true;
		?false -> ?false
	end;
send(X, BinMsg) ->
    ?MSG_ERROR("~p|~p", [X, BinMsg]),
    ?false.

% 高速Send
send_fast(Socket, BinMsg) ->
    ?MSG_DEBUG("send fast Socket:~p ,BinMsg = ~p ", [Socket,BinMsg]),
	try erlang:port_command(Socket,BinMsg,[force,nosuspend]) of
		?true  -> ?ok;
		?false ->
			?MSG_ERROR("~nReason:~p~n", [busy]),
			{?error,busy}
	catch
		error:Error ->
			?MSG_ERROR("~nPid:~p Socket:~p BinMsg:~p Reason:~p~n", [self(),Socket,BinMsg,Error]),
			{?error,einval}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 生成激活码
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 生成媒体激活码
%% misc_app:generate_summer_codes().

generate_summer_codes() ->
	generate_common_codes(?CONST_PLAYER_GIFT_TYPE_SUMMER, ?CONST_SYS_CODE_COUNT_MEDIA, ?NUMBER_CHARACTER_LIST, ?CONST_SYS_CODE_LENGTH_MEDIA).

%% 生成预约激活码
%% misc_app:generate_order_codes().
generate_order_codes() ->
	generate_common_codes(?CONST_PLAYER_GIFT_TYPE_ORDER, ?CONST_SYS_CODE_COUNT_ORDER, ?NUMBER_CHARACTER_LIST, ?CONST_SYS_CODE_LENGTH_ORDER).

%% 增加激活码
%% misc_app:increase_codes(1, 1).
increase_codes(Type, Count) ->
	{?ok, [[CountRest]]}	= mysql_api:select_execute("SELECT COUNT(*) FROM `game_code` WHERE `code_type` = 0"),
	 if
		 CountRest >= Count ->
			 SQL	= "UPDATE `game_code` SET `code_type` = " ++ misc:to_list(Type) ++ " WHERE `code_type` = 0 LIMIT " ++ misc:to_list(Count) ++ ";",
			 case mysql_api:update_execute(SQL) of
				 {?ok, _Data} -> ?ok;
				 Error -> Error
			 end;
		 ?true -> {?error, CountRest, Count}
	 end.
	
%% 生成通用激活码
%% misc_app:generate_common_codes(Type, Count, Length).
generate_common_codes(Type, Count, Length) ->
	generate_common_codes(Type, Count, ?NUMBER_CHARACTER_LIST, Length).

generate_common_codes(Type, Count, CharacterList, Length) ->
	% 随机数种子
	?RANDOM_SEED,
	CodeList	= generate_codes(Count, CharacterList, Length),
	Fun			= fun(Code) ->
						  mysql_api:insert(game_code, [code_type, code], [Type, Code])
				  end,
	lists:foreach(Fun, CodeList),
	case mysql_api:select("SELECT count(*) FROM `game_code` WHERE `code_type` = " ++ misc:to_list(Type) ++ ";") of
		{?ok, [[Count]]} -> ?ok;
		{?ok, [[CountDB]]} ->
			?MSG_ERROR("generate_order_codes() Count:~p CountDB:~p", [Count, CountDB]),
			mysql_api:execute("DELETE FROM `game_code` WHERE `code_type` = " ++ misc:to_list(Type) ++ ";"),
			{?error, ?TIP_COMMON_SYS_ERROR};
		{?error, Error} ->
			?MSG_ERROR("generate_order_codes() Error:~p", [Error]),
			mysql_api:execute("DELETE FROM `game_code` WHERE `code_type` = " ++ misc:to_list(Type) ++ ";"),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

generate_codes(Count, CharacterList, Length) ->
	generate_codes(Count, CharacterList, Length, [], []).

generate_codes(Count, CharacterList, Length, AccUp, Acc) when Count > 0->
	Code		= generate_code(CharacterList, Length),
	CodeUpper	= string:to_upper(Code),
	case lists:member(CodeUpper, AccUp) of
		?true -> generate_codes(Count, CharacterList, Length, AccUp, Acc);
		?false -> generate_codes(Count - 1, CharacterList, Length, [CodeUpper|AccUp], [Code|Acc])
	end;
generate_codes(_Count, _CharacterList, _Length, _AccUp, Acc) ->
	Acc.

generate_code(CharacterList, Length) ->
	generate_code(CharacterList, Length, []).
generate_code(_CharacterList, 0, Acc) -> Acc;
generate_code(CharacterList, Length, Acc) ->
	case misc_random:random_one(CharacterList) of
		?null -> generate_code(CharacterList, Length, Acc);
		Data  -> generate_code(CharacterList, Length - 1, [Data|Acc])
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 加载 文件
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD编译文件
load_beam() ->
    do_exist_app(),
    FileList2       = filelib:wildcard("*.beam"),
    Len = erlang:length(FileList2),
    ?MSG_SYS("------------------------------------------------------------"),
	Fun = fun(FileBaseName, N)->
                  ModName = misc:to_atom(filename:rootname(FileBaseName)),
                  c:l(ModName),
                  ?MSG_SYS("loaded(~p).........~p/~p",[ModName, N, Len]),
                  N+1
		  end,
	Count = lists:foldl(Fun, 1, FileList2),
    ?MSG_SYS("-------------------------------------------------------------"),
    if
        Count =/= (Len + 1) ->
            throw(1);
        ?true ->
            ?ok
    end.

load_beam(Path) ->
%%     do_exist_app(),
    case os:type() of
        {unix, _} ->
            c:cd("../ebin/");
        _ ->
            ?ok
    end,
    FileList2       = filelib:wildcard("*.beam", Path),
    Len = erlang:length(FileList2),
    c:l(misc),
    c:cd(Path),
%%     ?MSG_SYS("------------------------------------------------------------"),
    Fun = fun(FileBaseName, N)->
                  ModName = misc:to_atom(filename:rootname(FileBaseName)),
                  c:l(ModName),
%%                   ?MSG_SYS("loaded(~p).........~p/~p",[ModName, N, Len]),
                  N+1
          end,
    Count = lists:foldl(Fun, 1, FileList2),
%%     ?MSG_SYS("-------------------------------------------------------------"),
    c:cd(".."),
    if
        Count =/= (Len + 1) ->
            throw(1);
        ?true ->
            ?ok
    end.

mark_vsn_stop() ->
    mark_vsn(),
    erlang:halt().

is_same_vsn_stop() ->
    Result = is_same_vsn(),
    ?MSG_SYS("result=[~p]", [Result]),
    erlang:halt().

mark_vsn() ->
    mark_vsn("../").

mark_vsn(Path) ->
    file:delete(lists:concat([Path, beam_info])),
    file:delete(lists:concat([Path, beam_vsn])),
    FileList2       = filelib:wildcard("*.beam"),
	Fun = fun(FileBaseName, N)->
                  ModName = misc:to_atom(filename:rootname(FileBaseName)),
                  AttrList = ModName:module_info(attributes),
                  {_, [Vsn]} = lists:keyfind(vsn, 1, AttrList),
                  
                  CompileInfoList = ModName:module_info(compile),
                  {_, Src} = lists:keyfind(source, 1, CompileInfoList),
                  {_, Time} = lists:keyfind(time,   1, CompileInfoList),
                  file:write_file(lists:concat([Path, beam_info]), io_lib:format("{~p,~p,~p,~w}.~n", [ModName, Vsn, Src, Time]), [append]),
                  N+1
		  end,
	lists:foldl(Fun, 1, FileList2),
    {_, BeamInfo} = file:read_file(lists:concat([Path, beam_info])),
    Md5 = erlang:md5(BeamInfo),
    file:write_file(lists:concat([Path, beam_vsn]), io_lib:format("{time,~p,~p,~p}. {md5,~p}.~n", 
                                                                  [erlang:now(), erlang:date(), erlang:time(), misc:to_binary(misc:bin_to_hex(Md5))])),
    ?ok.

is_same_vsn() ->
    mark_vsn("./"),
    case file:consult("../beam_vsn") of
        {ok, T1} ->
            case file:consult("./beam_vsn") of
                {ok, T2} ->
                    Md5_1 = 
                        case lists:keyfind(md5, 1, T1) of
                            {_, Md5_1T} ->
                                Md5_1T;
                            _ ->
                                undefined
                        end,
                    Md5_2 = 
                        case lists:keyfind(md5, 1, T2) of
                            {_, Md5_2T} ->
                                Md5_2T;
                            _ ->
                                undefined
                        end,
                    if
                        Md5_1 =:= Md5_2 andalso undefined =/= Md5_1 andalso undefined =/= Md5_2 ->
                            true;
                        true ->
                            ?MSG_SYS("~p~n~p", [Md5_1, Md5_2]),
                            false
                    end;
                {error, _Reason} ->
                    ?MSG_SYS("no this file[./beam_vsn]", []),
                    false
            end;
        {error, _Reason} ->
            ?MSG_SYS("no this file[../beam_vsn]", []),
            false
    end.

%% 确保server.app存在
do_exist_app() ->
    L = ["server", "sanguo_center", "sanguo_manage"],
    case file:get_cwd() of
        {ok, Dir} ->
            case lists:suffix("ebin", Dir) of
                ?true ->
                    do_exist_app(L);
                ?false ->
                    do_exist_app(L)
            end;
        {error, _Reason} ->
            ok
    end.

do_exist_app([File|Tail]) ->
    Filename = lists:concat([File, ".app"]),
    case filelib:is_file(Filename) of
        ?true ->
            ?ok;
        _ ->
            file:copy("../app/"++Filename, "./"++Filename)
    end,
    do_exist_app(Tail);
do_exist_app([]) ->
    ?ok.

reload_beam() ->
	FileList2       = filelib:wildcard("*.beam"),
    Len = erlang:length(FileList2),
    ?MSG_SYS("------------------------------------------------------------"),
    Fun = fun(FileBaseName, N)->
                  ModName = misc:to_atom(filename:rootname(FileBaseName)),
                  case code:is_sticky(ModName) of
                     true ->
                        ignore;
                     false ->
                        case code:soft_purge(ModName) of
                            true ->
                                code:load_file(ModName);
                            false ->
                                ok
                        end
                  end,
                  ?MSG_SYS("loaded(~p).........~p/~p",[ModName, N, Len]),
                  N+1
          end,
    Count = lists:foldl(Fun, 1, FileList2),
    ?MSG_SYS("-------------------------------------------------------------"),
    if
        Count =/= (Len + 1) ->
            ?ok;
        ?true ->
            ?ok
    end.

%% 生成文件时处理
get_data_list(?DIR_YRL_ROOT ++ _Path = P) ->
    case misc_app:load_file(P) of
        Data when is_list(Data) ->
            Data;
        MonoData ->
            [MonoData]
    end;
get_data_list(Path) ->
    case misc_app:load_file(?DIR_YRL_ROOT ++ Path) of
        Data when is_list(Data) ->
            Data;
        MonoData ->
            [MonoData]
    end.
get_data_list_rev(?DIR_YRL_ROOT++_Path = P) ->
    DataList = 
        case misc_app:load_file(P) of
            Data when is_list(Data) ->                Data;
            MonoData ->
                [MonoData]
        end,
    lists:reverse(DataList);
get_data_list_rev(Path) ->
    DataList = 
        case misc_app:load_file(?DIR_YRL_ROOT ++ Path) of
            Data when is_list(Data) ->
                Data;
            MonoData ->
                [MonoData]
        end,
    lists:reverse(DataList).

load_file(FileName) ->
	case load_file2(FileName) of
		{?ok, 	Data}   -> Data;
        {?error, Why} 	-> 
            ?MSG_ERROR("load file[~p|~p]~n~p", [Why, file:get_cwd(), FileName]),
            ?null
    end.
load_file2(FileName) ->
	case filelib:is_file(FileName) of
		?true -> 
			case file:consult(FileName) of
				{?ok, [Data]} -> {?ok, Data};
				{?ok, Data}   -> {?ok, Data};
				{?error, Why} -> {?error, {FileName, Why}}
			end;
		?false ->
			{?error, "Can not find file:" ++ misc:to_list(FileName)}
	end. 

%% 加载配置文件
load_config() ->
    try
        case init:get_argument(config) of
            {?ok,[[FileName]]} ->
                FileNameFull = 
                    case lists:suffix(".config", FileName) of
                        ?true ->
                            FileName;
                        _ ->
                            lists:concat([FileName, ".config"])
                    end,
                load_file(FileNameFull);
            _ ->
                ?MSG_SYS("Could not find config file:[config]", []),
                ?null
        end
    catch
        X:Y ->
            ?MSG_SYS("err:~n~p~n~p~n~p", [X, Y, erlang:get_stacktrace()]),
            ?null
    end.
load_config(Mod) ->
    try
        ModString = misc:to_list(Mod),
        case init:get_argument(config) of
            {?ok,[[FileName]]} ->
                FileNameFull = 
                    case lists:suffix(".config", FileName) of
                        ?true ->
                            FileName;
                        _ ->
                            lists:concat([FileName, ".config"])
                    end,
                Datas     = load_file(FileNameFull),
                case lists:keyfind(Mod, 1, Datas) of
                    ?false ->
                        ?MSG_SYS("Could not find config:" ++ ModString ++ " file:" ++ misc:to_list(FileNameFull), []);
                    {Mod,Value} ->
                        Value
                end;
            _ ->
                ?MSG_SYS("Could not find config:" ++ ModString ++ " file:[config]", [])
        end
    catch
        X:Y ->
            ?MSG_SYS("err:~n~p~n~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.
load_config(Mod, Sid) ->
	ModString = misc:to_list(Mod),
	SidString = misc:to_list(Sid),
	FileName  = ?DIR_CONFIG_ROOT ++ "server_" ++ SidString ++ ".config",
	Datas 	  = load_file(FileName),
	case lists:keyfind(Mod, 1, Datas) of
		?false ->
			exit({?error, "Could not find config:" ++ ModString ++ " file:" ++ misc:to_list(FileName)});
		{Mod,Value} ->
			Value
	end.
%% load_config(Mod) ->
%% 	Sid	= sid(),
%% 	load_config(Mod, Sid).
%% load_config(Mod, Sid) ->
%% 	ModString = misc:to_list(Mod),
%% 	SidString = misc:to_list(Sid),
%% 	FileName  = ?DIR_CONFIG_ROOT ++ "server_" ++ SidString ++ ".config",
%% 	Datas 	  = load_file(FileName),
%% 	case lists:keyfind(Mod, 1, Datas) of
%% 		?false ->
%% 			exit({?error, "Could not find config:" ++ ModString ++ " file:" ++ misc:to_list(FileName)});
%% 		{Mod,Value} ->
%% 			Value
%% 	end.

%% 指定CPU
spawn(Module,Function,Args)->
	Schedulers 	= erlang:system_info(schedulers),
	Num			= random:uniform(Schedulers),
	spawn(Module,Function,Args,Schedulers,Num).
spawn(Module,Function,Args,Schedulers,Num)->
	case Schedulers of
		1 ->
			erlang:spawn(Module, Function, Args);
		_ ->
			N 	= (Num rem Schedulers) + 1,
			spawn_opt(Module,Function,Args,[{scheduler,N}])
	end.
spawn_link(Module,Function,Args)->
	Schedulers 	= erlang:system_info(schedulers),
	Num			= random:uniform(Schedulers),
	spawn_link(Module,Function,Args,Schedulers,Num).
spawn_link(Module,Function,Args,Schedulers,Num)->
	case Schedulers of
		1 ->
			erlang:spawn_link(Module, Function, Args);
		_ ->
			N 	= (Num rem Schedulers) + 1,
			spawn_opt(Module,Function,Args,[link,{scheduler,N}])
	end.
gen_server_start_link(Mod,Args)->
	Schedulers 	= erlang:system_info(schedulers),
	Num			= random:uniform(Schedulers),
	gen_server_start_link(Mod,Args,Schedulers,Num).
gen_server_start_link(Mod,Args,Schedulers,Num)->
	case Schedulers of
		1 ->
			gen_server:start_link(Mod, Args, []);
		_ ->
			N 	= (Num rem Schedulers) + 1,
			gen_server:start_link(Mod, Args, [{spawn_opt,[{scheduler,N}]}])
	end.
gen_server_start_link(ServName,Mod,Args)->
	Schedulers 	= erlang:system_info(schedulers),
	Num			= random:uniform(Schedulers),
	gen_server_start_link(ServName,Mod,Args,Schedulers,Num).
gen_server_start_link(ServName,Mod,Args,Schedulers,Num)->
	case Schedulers of
		1 ->
			gen_server:start_link({local, ServName}, Mod, Args, []);
		_ ->
			N 	= (Num rem Schedulers) + 1,
			gen_server:start_link({local, ServName}, Mod, Args, [{spawn_opt,[{scheduler,N}]}])
	end.

call(Mod, Request) ->
	N = erlang:system_info(scheduler_id),
	call(Mod, N, Request).
call(Mod, Suffix, Request) ->
	Handler = serv_namecall(Mod, Suffix),
	case gen_server:call(Handler, Request,?CONST_TIMEOUT_CALL) of
		{?error, Error} ->
			?MSG_ERROR("call(Mod:~p Suffix:~p Request:~p):~p",[Mod, Suffix, Request, {?error, Error}]),
			{?error, Error};
		Reply ->
			Reply
	end.
call_timeout(Mod, Request, Timeout)->
	N = erlang:system_info(scheduler_id),
	call_timeout(Mod, Request, N, Timeout).
call_timeout(Mod, Request, Suffix, Timeout) ->
	Handler = serv_namecall(Mod, Suffix),
	case gen_server:call(Handler, Request, Timeout) of
		{?error, Error} ->
			?MSG_ERROR("call_timeout(Mod:~p Request:~p Suffix:~p Timeout:~p):~p",[Mod, Request, Suffix, Timeout, {?error, Error}]),
			{?error, Error};
		Reply ->
			Reply
	end.

cast(0, _Param) ->
    0;
cast(Pid, Param) when is_pid(Pid) ->
    gen_server:cast(Pid, Param);
cast({Pid, Node}, Param) when is_pid(Pid) ->
    rpc:cast(Node, gen_server, cast, [Pid, Param]);

cast(UserId, Param) when is_number(UserId) ->
    case player_api:get_player_pid(UserId) of
        Pid when is_pid(Pid) ->
            cast(Pid, Param);
        _ -> % 不在线
            ?error 
    end;
cast(Mod, Request) ->
	N = erlang:system_info(scheduler_id),
	cast(Mod, N, Request).
cast(Mod, Suffix, Request) ->
	Handler = serv_namecall(Mod, Suffix),
	gen_server:cast(Handler, Request).

%% ChildSpec列表(开多个相同的子进程)
child_spec_list([N|TList], Rs, Mod, Cores, Args, Restart, Shutdown, Type) ->
	ServName	= serv_name(Mod, N),
	R  			= {ServName,											%% Id 		 = term()
				   {Mod, start_link, [ServName, Cores, N|Args]},		%% StartFunc = {M, F, A}
				   Restart,												%% Restart 	 = permanent | transient | temporary
				   Shutdown,											%% Shutdown  = brutal_kill | integer() >=0 | infinity
				   Type,												%% Type 	 = worker | supervisor
				   [Mod]												%% Modules 	 = [Module] | dynamic
				  },
	child_spec_list(TList, [R|Rs], Mod, Cores, Args, Restart, Shutdown, Type);
child_spec_list([], Rs, _Mod, _Cores, _Args, _Restart, _Shutdown, _Type) -> lists:reverse(Rs).

%% ChildSpec列表(开多个相同的子进程)
child_spec_list([{N, Args}|TList], Rs, Mod, Cores, Restart, Shutdown, Type) ->
	ServName 	= serv_name(Mod, N),
	R  			= {ServName,											%% Id 		 = term()
				   {Mod, start_link, [ServName, Cores, N|Args]},		%% StartFunc = {M, F, A}
				   Restart,												%% Restart 	 = permanent | transient | temporary
				   Shutdown,											%% Shutdown  = brutal_kill | integer() >=0 | infinity
				   Type,												%% Type 	 = worker | supervisor
				   [Mod]												%% Modules 	 = [Module] | dynamic
				  },
	?MSG_PRINT("ServName:~p N:~p",[ServName, N]),
	child_spec_list(TList, [R|Rs], Mod, Cores, Restart, Shutdown, Type);
child_spec_list([], Rs, _Mod, _Cores, _Restart, _Shutdown, _Type) -> lists:reverse(Rs).

child_spec(ServName, Mod, Args, Restart, Shutdown, Type, Cores) ->
	{ServName,											%% Id 		 = term()
	 {Mod, start_link, [ServName, Cores|Args]},			%% StartFunc = {M, F, A}
	 Restart,											%% Restart 	 = permanent | transient | temporary
	 Shutdown,											%% Shutdown  = brutal_kill | integer() >=0 | infinity
	 Type,												%% Type 	 = worker | supervisor
	 [Mod]												%% Modules 	 = [Module] | dynamic
	}.

%% 节点ping通
ping_node(Node)->
	case net_adm:ping(Node) of
		pong -> ?true;
		_ 	 -> ?false
	end.


serv_name(Mod, N) ->
	misc:list_to_atom(misc:to_list(Mod) ++ "_" ++ misc:to_list(N)).

serv_namecall(Mod, N) ->
	list_to_existing_atom(misc:to_list(Mod) ++ "_" ++ misc:to_list(N)).


%% 数组转成字符串
%% List -> String 
%% H 附加在开头
%% M 夹在中间
%% T 附加在尾部
list_to_string([],_H,_M,_T) -> [];
list_to_string([HList|TList], H, M,T)     -> list_to_string(TList,H,M,T,H++HList).
list_to_string([],           _H,_M,T,Str) -> Str++T;
list_to_string([HList|TList], H, M,T,Str) -> list_to_string(TList,H,M,T,Str++M++HList).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入模块文件
%% @param  RecordName 记录名
%% @return ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_erl_file(ModName, IncludeList, DataList, Ver) ->
    Dir = lists:concat([?DIR_SRC_ROOT, "data/", Ver, "/"]),
%%     Dir = "../data/",
    FileName = lists:concat([ModName, ".erl"]),
    file:delete(Dir ++ FileName),
    case file:open(Dir ++ FileName, [append, raw]) of
        {ok, Fd} ->
            write_module_head(Fd), % 模块头
            file:write(Fd, io_lib:format("-module(~p).~n", [ModName])),
            F = fun(Include) -> 
                    file:write(Fd, io_lib:format("-include(~p).~n", [Include]))
                end,
            lists:foreach(F, IncludeList),
            file:write(Fd, io_lib:format("-compile(export_all).~n~n", [])),
            write_line(Fd, DataList, 1),
            file:close(Fd),
            ?ok;
        Any ->
            io:format("l=~p~n", [Dir++FileName]),
            Any
    end.

%% 去除头部，作中转文件用
write_erl_file_without_head(ModName, DataList, Ver) ->
    Dir = lists:concat([?DIR_SRC_ROOT, "data/", Ver, "/"]),
    FileName = lists:concat([ModName, ".erl"]),
    file:delete(Dir ++ FileName),
    case file:open(Dir ++ FileName, [append, raw]) of
        {ok, Fd} ->
            write_line(Fd, DataList, 0),
            file:close(Fd),
            ?ok;
        Any ->
            Any
    end.

%% 只写头
write_erl_file_only_head(ModName, IncludeList, Ver) ->
    Dir = lists:concat([?DIR_SRC_ROOT, "data/", Ver, "/"]),
    FileName = lists:concat([ModName, ".erl"]),
    file:delete(Dir ++ FileName),
    case file:open(Dir ++ FileName, [append, raw]) of
        {ok, Fd} ->
            write_module_head(Fd), % 模块头
            file:write(Fd, io_lib:format("-module(~p).~n", [ModName])),
            F = fun(Include) -> 
                    file:write(Fd, io_lib:format("-include(~p).~n", [Include]))
                end,
            lists:foreach(F, IncludeList),
            file:write(Fd, io_lib:format("-compile(export_all).~n~n", [])),
            file:close(Fd),
            ?ok;
        Any ->
            Any
    end.
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   写入模块头
%% @param  RecordName 记录名
%% @return ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
write_module_head(Fd) ->
    file:write(Fd, io_lib:format("~n~n", [])),
    file:write(Fd, io_lib:format("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", [])),
    file:write(Fd, io_lib:format("%% 自动生成 ~n", [])),
%%     {{Y, M, D}, {H, Mi, S}} = calendar:now_to_local_time(erlang:now()),
%%     file:write(Fd, io_lib:format("%% Data : ~w.~w.~w ~w:~w:~w ~n", [Y, M, D, H, Mi, S])),
    file:write(Fd, io_lib:format("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%~n", [])),
    ?ok.

write_line(Fd, [{FunName, Data}|Tail], HasTail) ->
    write_data(Fd, FunName, Data, HasTail),
    file:write(Fd, io_lib:format("~n", [])),
    write_line(Fd, Tail, HasTail);
write_line(_Fd, [], _HasTail) ->
    ?ok.

%% write_data(Fd, FunName, [{Key, Value, ?null}|[]], 1) when is_list(Value) ->
%%     file:write(Fd, io_lib:format("~p(~p) ->~n", [FunName, Key])),
%%     file:write(Fd, io_lib:format("\t"++Value++";~n", [])),
%% 	file:write(Fd, io_lib:format("~p(_Any) -> ~n\tnull.~n", [FunName])),
%%     write_data(Fd, FunName, [], 1);
%% write_data(Fd, FunName, [{Key, Value, When}|[]], 1) when is_list(Value) ->
%%     file:write(Fd, io_lib:format("~p("++Key++") when "++When++" ->~n", [FunName])),
%%     file:write(Fd, io_lib:format("\t"++Value++";~n", [])),
%% 	file:write(Fd, io_lib:format("~p(_Any) -> ~n\tnull.~n", [FunName])),
%%     write_data(Fd, FunName, [], 1);
write_data(Fd, FunName, [{?null, Value, ?null}|[]], 1) ->
    file:write(Fd, io_lib:format("~p() ->~n", [FunName])),
    file:write(Fd, io_lib:format("\t~p.~n", [Value])),
    write_data(Fd, FunName, [], 1);
write_data(Fd, FunName, [{Key, Value, ?null}|[]], 1) ->
    file:write(Fd, io_lib:format("~p(~p) ->~n", [FunName, Key])),
    file:write(Fd, io_lib:format("\t~p;~n", [Value])),
	file:write(Fd, io_lib:format("~p(_Any) -> ~n\tnull.~n", [FunName])),
    write_data(Fd, FunName, [], 1);
write_data(Fd, FunName, [{Key, Value, When}|[]], 1) ->
    file:write(Fd, io_lib:format("~p("++Key++") when "++When++" ->~n", [FunName])),
    file:write(Fd, io_lib:format("\t~p;~n", [Value])),
	file:write(Fd, io_lib:format("~p(_Any) ->~n\tnull.~n", [FunName])),
    write_data(Fd, FunName, [], 1);

%% write_data(Fd, FunName, [{Key, Value, ?null}|Tail], HasTail) when is_list(Value) ->
%%     file:write(Fd, io_lib:format("~p(~p) ->~n", [FunName, Key])),
%%     file:write(Fd, io_lib:format("\t"++Value++";~n", [])),
%%     write_data(Fd, FunName, Tail, HasTail);
%% write_data(Fd, FunName, [{Key, Value, When}|Tail], HasTail) when is_list(Value) ->
%%     file:write(Fd, io_lib:format("~p("++Key++") when "++When++" ->~n", [FunName])),
%%     file:write(Fd, io_lib:format("\t"++Value++";~n", [])),
%%     write_data(Fd, FunName, Tail, HasTail);
write_data(Fd, FunName, [{Key, Value, ?null}|Tail], HasTail) ->
    file:write(Fd, io_lib:format("~p(~p) ->~n", [FunName, Key])),
    file:write(Fd, io_lib:format("\t~p;~n", [Value])),
    write_data(Fd, FunName, Tail, HasTail);
write_data(Fd, FunName, [{Key, Value, When}|Tail], HasTail) ->
    file:write(Fd, io_lib:format("~p("++Key++") when "++When++" ->~n", [FunName])),
    file:write(Fd, io_lib:format("\t~p;~n", [Value])),
    write_data(Fd, FunName, Tail, HasTail);
write_data(_Fd, _FunName, [], _) ->
    ?ok.

stop_shell() ->
	OsType = os:type(),
	case OsType of
		{_, nt} -> os:cmd("taskkill\ /f\ /im\ cmd.exe"), ?ok;
		_ -> ?ok
	end.

%% 拖延时间
processing_print(Max) ->
    processing_print(0, Max).
processing_print(Count, Max) when Count =< Max ->
    io:format("waiting........[~p/~p]\r", [Count, Max]),
    misc:sleep(1000),
    processing_print(Count+1, Max);
processing_print(_, Max) -> 
    io:format("waiting........[~p/~p]\n", [Max, Max]),
    ok.

%% 自杀
do_kill(NodeName) ->
    case os:type() of
        {_, nt} -> ?ok;
        _ -> 
            PidList  = os:cmd("ps awux | grep "++misc:to_list(NodeName)++" | grep -v \"grep\" | awk '{print $2}' > nul"),
            PidList2 = re:split(PidList, "\n"),
            do_kill_2(PidList2)
    end.

do_kill_2([Pid|Tail]) ->
    os:cmd("kill -9 " ++ misc:to_list(Pid)),
    do_kill_2(Tail);
do_kill_2([]) ->
    ok.

%% gner模板
generate_template(FunName, YrlPath, Path, KeyIdx, Module, DataHandler, WhenHandler, Ver) ->
    Datas       = misc_app:get_data_list(?DIR_YRL_ROOT ++ Ver ++ "/" ++ YrlPath ++ "/" ++ Path),
    generate_template_2(FunName, Datas, [], KeyIdx, Module, DataHandler, WhenHandler).
generate_template_2(FunName, Data, _, ?null, Module, DataHandler, WhenHandler) ->
    Key         = ?null,
    Value       = 
        if
            ?null =:= DataHandler ->
                Data;
            ?true ->
                Module:DataHandler(Data)
        end,
    When        = 
        if
            ?null =:= WhenHandler ->
                ?null;
            ?true ->
                Module:WhenHandler(Data)
        end,
    {FunName, [{Key, Value, When}]};
generate_template_2(FunName, [Data|Datas], Acc, KeyIdx, Module, DataHandler, WhenHandler) ->
    Key         = make_key(KeyIdx, Data, []),
    Value       = 
        if
            ?null =:= DataHandler ->
                Data;
            ?true ->
                Module:DataHandler(Data)
        end,
    When        = 
        if
            ?null =:= WhenHandler ->
                ?null;
            ?true ->
                Module:WhenHandler(Data)
        end,
    generate_template_2(FunName, Datas, [{Key, Value, When}|Acc], KeyIdx, Module, DataHandler, WhenHandler);
generate_template_2(FunName, [], Acc, _, _, _, _) -> {FunName, lists:reverse(Acc)}.

make_key([KeyIdx], Data, _) ->
    erlang:element(KeyIdx, Data);
make_key([KeyIdx|Tail], Data, OldList) ->
    DK = erlang:element(KeyIdx, Data),
    make_key_2(Tail, Data, [DK|OldList]);
make_key([], _, List) ->
    erlang:list_to_tuple(List).

make_key_2([KeyIdx|Tail], Data, OldList) ->
    DK = erlang:element(KeyIdx, Data),
    make_key_2(Tail, Data, [DK|OldList]);
make_key_2([], _, List) ->
    erlang:list_to_tuple(lists:reverse(List)).

%% 
make_gener(DataModule, IncludeList, FuncList, Ver) ->
    FuncList2 = make_gener_2(FuncList, [], Ver),
    misc_app:write_erl_file(DataModule,
                            ["const.common.hrl", "const.define.hrl", "record.player.hrl", "record.base.data.hrl", "record.data.hrl"] ++ IncludeList,
                            FuncList2, Ver).

make_gener_2([{FunName, YrlPath, Path, KeyIdx, Module, DataHandler, WhenHandler}|Tail], OldFuncList, Ver) ->
    X = generate_template(FunName, YrlPath, Path, KeyIdx, Module, DataHandler, WhenHandler, Ver),
    make_gener_2(Tail, [X|OldFuncList], Ver);
make_gener_2([Func|Tail], OldFuncList, Ver) ->
    make_gener_2(Tail, [Func|OldFuncList], Ver);
make_gener_2([], List, _) ->
    List.
