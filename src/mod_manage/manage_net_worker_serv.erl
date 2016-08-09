
-module(manage_net_worker_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/6]).
%% gen_server callbacks
-export([init/1,handle_call/3, handle_cast/2, handle_info/2,terminate/2,code_change/3]).
-export([work/1, stop/1]).


%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, Cores, _TimesNull, Times, Socket, ListenSocket) ->
    misc_app:gen_server_start_link(?MODULE, [Cores, Times, Socket, ListenSocket], Cores, Times).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {?ok, State}          |
%%          {?ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([_Cores, _Times, Socket, ListenSocket]) ->
    process_flag(trap_exit, ?true),
    %% 随机数种子
    ?RANDOM_SEED,
    Seconds = misc:seconds(),
    case set_socket(ListenSocket, Socket) of
        ?ok ->
            case async_recv(Socket, 0, ?CONST_TIMEOUT_SOCKET) of
                {?ok, Ref} ->
                    Ip      = misc:ip(Socket),
                    Client  = #client{
                                      net_pid           = self(),       % 玩家Net进程ID
                                      ip                = Ip,           % 玩家IP
                                      socket            = Socket,       % Socket
                                      ref               = Ref,          % Ref
                                      binary            = <<>>,         % Binary
                                      time              = Seconds,      % 登录时间
                                      serv_state        = 0             % 服务器状态
                                     },
                    {?ok, Client};
                Error ->
                    ?MSG_ERROR("Error:~p", [Error]),
                    {?stop, Error}
            end;
        ?error ->
            Error = {?error, set_socket},
            ?MSG_ERROR("Error:~p", [Error]),
            {?stop, Error}
    end.

%% --------------------------------------------------------------------
%% Function: handle_call/3
%% Description: Handling call messages
%% Returns: {reply, Reply, State}          |
%%          {reply, Reply, State, Timeout} |
%%          {noreply, State}               |
%%          {noreply, State, Timeout}      |
%%          {stop, Reason, Reply, State}   | (terminate/2 is called)
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_call(Request, From, Client) ->
    try do_call(Request, From, Client) of
        {?reply, Reply, Client2} -> {?reply, Reply, Client2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?stop, Reason, {?error, ?TIP_COMMON_BAD_ARG}, Client}
    end.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, Client) ->
    try do_cast(Msg, Client) of
        {?noreply, Client2} -> {?noreply, Client2};
        {?stop, Reason, Client} -> {?stop, Reason, Client}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?stop, Reason, Client}
    end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, Client) ->
    try do_info(Info, Client) of
        {?noreply, Client2} -> {?noreply, Client2};
        {?stop, Reason, Client2} -> {?stop, Reason, Client2}
    catch Error:Reason ->
              ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              {?stop, Reason, Client}
    end.

do_call(Request, _From, Client) ->
    ?MSG_ERROR("UserId:~p Request:~p Strace:~p",[Client#client.user_id, Request, erlang:get_stacktrace()]),
    Reply = ?ok,
    {?reply, Reply, Client}.

do_cast(exit, Client) ->
    {?stop, ?normal, Client};
do_cast(stop, Client) ->
    {?noreply, Client#client{serv_state = 1}};
do_cast(Msg, Client) ->
    ?MSG_ERROR("UserId:~p Msg:~p Strace:~p",[Client#client.user_id, Msg, erlang:get_stacktrace()]),
    {?noreply, Client}.

do_info({inet_async, Socket, Ref, {?ok, SocketBinary}},
        Client = #client{socket = Socket, ref = Ref}) ->
    case SocketBinary of
        ?SECURITY_PREFIX ->
            ?MSG_DEBUG("RECEIVE SECURITY PREFIX...", []),
            gen_tcp:send(Client#client.socket, ?SECURITY),
            ?MSG_DEBUG("SEND SECURITY...", []),
            {?stop, ?normal, Client};
        _ ->
            Bin = Client#client.binary,
            case work(Client#client{binary = <<Bin/binary, SocketBinary/binary>>}) of
                {?ok, Client2} ->
                    {?noreply, Client2};
                {?error, Error} ->
                    {?stop, {work, Error}, Client}
            end
    end;

do_info({send, BinMsg}, Client) ->
    case Client#client.socket of
        0 ->
            DelayPacket = Client#client.delay_packet,
            {?noreply, Client#client{delay_packet = <<DelayPacket/binary, BinMsg/binary>>}};
        _ ->
            misc_app:send(Client#client.socket, BinMsg),
            {?noreply, Client}
    end;
do_info({inet_reply, _Socket, ?ok}, Client) ->
    {?noreply, Client};
do_info({'EXIT', PlayerPid, Reason}, Client = #client{player_pid = PlayerPid}) ->% 玩家游戏逻辑进程退出
    {?stop, Reason, Client};

do_info({inet_async, _, _, {error, closed}}, Client) ->
    {?stop, ?normal, Client};

do_info({inet_async,  _,  _, {?error, ?timeout}}, Client) ->
    ?MSG_ERROR("ERROR:USERID:~p SOCKET TIMEOUT", [Client#client.user_id]),
    {?stop, {?error, socket_timeout}, Client};
do_info({inet_async,  _,  _, {?error, ?etimedout}}, Client) ->% 网络环境差，要做闪断重连处理
    {?stop, ?normal, Client};

do_info({inet_async,  X,  Y, Reason}, Client) ->
    ?MSG_ERROR("ERROR:~p|~p|~p", [X, Y, Reason]),
    {?stop, Reason, Client};

do_info(exit, Client) ->
    {?stop, ?normal, Client};

do_info(Info, Client) ->
    ?MSG_ERROR("UserId:~p Info:~p Strace:~p",[Client#client.user_id, Info, erlang:get_stacktrace()]),
    {?noreply, Client}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, Client) ->
    % 记下 退出 日志
    case Reason of
        ?normal ->
            ?ok;
        _ ->
            ?ok
    end,
    % 把Socket断开
    try
%%         manage_net_worker_sup:delete_net(Client#client.net_pid),
        case Client#client.socket of
            0 ->
                ?ok;
            _ ->
                gen_tcp:close(Client#client.socket)
        end
    catch
        Any1:Any2 -> ?MSG_ERROR("Error:~p|~p~n~p",[Any1,Any2, erlang:get_stacktrace()])
    end.
%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {?ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 异步接受Socket连接
set_socket(ListenSocket, Socket) ->
    {?ok, Mod} = inet_db:lookup_socket(ListenSocket),
    ?true      = inet_db:register_socket(Socket, Mod),
    case prim_inet:getopts(ListenSocket, ?CONST_SET_CLIENT_TCP_OPTIONS) of
        {?ok, Opts} ->
            case prim_inet:setopts(Socket, Opts) of
                ?ok     -> ?ok;
                ?error  -> gen_tcp:close(Socket), ?error
            end;
        ?error -> gen_tcp:close(Socket), ?error
    end.

%% 结构：长度(2字节)+序列号(1字节)+校验位(16个字节)+协议号(2字节)+包体
work(Client = #client{binary = Binary, socket = Socket}) ->
%%     ?MSG_SYS("got~n~p~n------", [Binary]),
    manage_interface_mod:treat_http_request(Socket, Binary),
    {?error, 1};
work(Client) ->
    case async_recv(Client#client.socket, 0, ?CONST_TIMEOUT_SOCKET) of
        {?ok, Ref} -> {?ok, Client#client{ref = Ref}};
        Error -> 
            ?MSG_ERROR("~nError:~p Stack=~p~n", [Error, erlang:get_stacktrace()]),
            Error
    end.

async_recv(Socket, Length, Timeout) ->
    case prim_inet:async_recv(Socket, Length, Timeout) of
        {?ok, Ref} -> {?ok, Ref};
        Error ->
            ?MSG_ERROR("ERROR:~p", [Error]),
            {?error, {async_recv, Error}}
    end.

stop(NetPid) when is_pid(NetPid) ->
    gen_server:cast(NetPid, stop);
stop(_) ->
    ok.

