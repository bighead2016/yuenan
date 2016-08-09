 %%% -------------------------------------------------------------------
%%% Author  : Administrator
%%% Description :
%%%
%%% Created : 2011-6-21
%%% -------------------------------------------------------------------
-module(gateway_worker_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/9, repeat_login_cast/1, reconnect_cast/5]).
%% gen_server callbacks
-export([init/1,handle_call/3, handle_cast/2, handle_info/2,terminate/2,code_change/3]).
-export([work/1, stop/1]).


%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, Cores, LoginKey, RootKey, ResourceKey, _TimesNull, Times, Socket, ListenSocket) ->
	misc_app:gen_server_start_link(?MODULE, [LoginKey, RootKey, ResourceKey, Cores, Times, Socket, ListenSocket], Cores, Times).

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {?ok, State}          |
%%          {?ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([LoginKey, RootKey, ResourceKey, _Cores, _Times, Socket, ListenSocket]) ->
	process_flag(trap_exit, ?true),
	%% 随机数种子
    ?RANDOM_SEED,
	Seconds	= misc:seconds(),
    case set_socket(ListenSocket, Socket) of
		?ok ->
			case async_recv(Socket, 0, ?CONST_TIMEOUT_SOCKET) of
				{?ok, Ref} ->
					Ip		= misc:ip(Socket),
					Heart	= #heart{heart = 0, bad = 0, tsp = Seconds, db = Seconds, gc = Seconds, ip = Seconds},
					Client  = #client{
									  login_key			= LoginKey,		% 登陆Key
									  root_key			= RootKey,		% 根Key
									  app_key			= 0,			% 应用Key
									  resource_key		= ResourceKey,	% 资源KEY
									  sn				= 1,			% 数据包序列号[1-65535]
									  
									  serv_id			= 0,			% 服务器ID
									  serv_unique_id	= 0,			% 服务器唯一ID
									  user_id 			= 0,			% 玩家ID
									  net_pid			= self(),		% 玩家Net进程ID
									  reg_name			= 0,			% 注册名
									  player_pid		= 0,			% 玩家游戏逻辑进程ID
									  ip				= Ip,	    	% 玩家IP
									  socket			= Socket,		% Socket
									  ref				= Ref,			% Ref
									  binary			= <<>>,			% Binary
									  state  			= ?CONST_PLAYER_CLIENT_STATE_UNLOGIN,% 客户端状态  0：登陆有角色|1:未登录|2：已登录无角色
									  heart				= Heart,		% 心跳record
									  time              = Seconds,      % 登录时间
									  fcm				= ?null,		% 防沉迷record
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
	% ?MSG_DEBUG("do_info info = ~w,Client = ~w",[Info, Client]),
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


do_cast(repeat_login, Client) ->% 重复登录
	Packet = player_api:msg_player_repeat_login(),
	misc_app:send(Client#client.socket, Packet),
	% 把Socket断开
	try
		gen_tcp:close(Client#client.socket)
    catch
		Any1:Any2 -> ?MSG_ERROR("Error Any1:~p Any2:~p",[Any1,Any2])
    end,
	{?stop, repeat_login, Client};
do_cast({reconnect, Socket, _Ref, NewSn, BinaryLast}, Client) ->
    AppCipher   = gateway_mod:encrypt_app_key(Client#client.root_key, Client#client.app_key),
    Packet = player_api:msg_sc_reconnect_success(AppCipher),
    DelayPacket = Client#client.delay_packet,
    TotalPacket = <<Packet/binary, DelayPacket/binary>>,
    ?ANALYSIS(x2, Client#client.net_pid, TotalPacket),
    misc_app:send(Socket, TotalPacket),
    case async_recv(Socket, 0, ?CONST_TIMEOUT_SOCKET) of
        {?ok, Ref2} -> 
            OldBinary = Client#client.binary,
            {?noreply, Client#client{socket = Socket, ref = Ref2, sn = NewSn, 
                                     state = ?CONST_PLAYER_CLIENT_STATE_LOGIN_YES, 
                                     delay_packet = <<>>,
                                     binary = <<OldBinary/binary, BinaryLast/binary>>}};
        Error -> 
            ?MSG_ERROR("~nError:~p Stack=~p~n", [Error, erlang:get_stacktrace()]),
            {?stop, reconnect_ref, Client}
    end;
do_cast(exit, Client) ->
    {?stop, ?normal, Client};
do_cast(stop, Client) ->
    {?noreply, Client#client{serv_state = 1}};
do_cast(Msg, Client) ->
    ?MSG_ERROR("UserId:~p Msg:~p Strace:~p",[Client#client.user_id, Msg, erlang:get_stacktrace()]),
	{?noreply, Client}.

% do_info({inet_async, Socket, Ref, {?ok, SocketBinary}},
%         Client = #client{socket = 0, ref = Ref,rece_pack = 0}) ->
% 	{?noreply,Client#client{rece_pack = 1}};  %% /腾讯平台接入，第一个处理扔掉
do_info({inet_async, Socket, Ref, {?ok, SocketBinary}},
        Client = #client{socket = 0, ref = Ref}) ->
	case SocketBinary of
		?SECURITY_PREFIX ->
			?MSG_DEBUG("RECEIVE SECURITY PREFIX...", []),
			gen_tcp:send(Client#client.socket, ?SECURITY),
			?MSG_DEBUG("SEND SECURITY...", []),
			{?stop, ?normal, Client};
		_ ->
			Bin = Client#client.binary,
            case work(Client#client{socket = Socket, binary = <<Bin/binary, SocketBinary/binary>>}) of
                {?ok, reconnected} ->
                    {?stop, {work, reconnect}, Client};
                {?ok, Client2} ->
                    {?noreply, Client2};
                {?error, Error} ->
                    {?stop, {work, Error}, Client}
            end
	end;
do_info({inet_async, Socket, Ref, {?ok, SocketBinary}},
        Client = #client{socket = Socket, ref = Ref}) ->
	case SocketBinary of
		?SECURITY_PREFIX ->
			?MSG_DEBUG("RECEIVE SECURITY PREFIX...", []),
			gen_tcp:send(Client#client.socket, ?SECURITY),
			?MSG_DEBUG("SEND SECURITY...", []),
			{?stop, ?normal, Client};
		_ ->
 			% ?MSG_DEBUG("RECEIVE SocketBinary from  [~p]:   ~p~n", [misc:ip(Socket), SocketBinary]),
			Bin = Client#client.binary,
			case work(Client#client{binary = <<Bin/binary, SocketBinary/binary>>}) of
                {?ok, reconnected} ->
                    {?stop, {work, reconnect}, Client#client{socket = 0}};
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

do_info({inet_async, _, _, {error, closed}}, #client{socket = 0} = Client) -> % 当gen_tcp断了，会收到这个消息
    {?noreply, Client};
do_info({inet_async, _, _, {error, closed}}, Client) ->
	{?stop, ?normal, Client};

do_info({inet_async,  _,  _, {?error, ?timeout}}, Client) ->
	?MSG_ERROR("ERROR:USERID:~p SOCKET TIMEOUT", [Client#client.user_id]),
	{?stop, {?error, socket_timeout}, Client};
do_info({inet_async,  _,  _, {?error, ?etimedout}}, #client{serv_state = 1} = Client) ->% 网络环境差，要做闪断重连处理
    {?stop, ?normal, Client};
do_info({inet_async,  _,  _, {?error, ?etimedout}}, Client) ->% 网络环境差，要做闪断重连处理
	?ok	= gateway_mod:set_mini_client(Client),
	?MSG_ERROR("ERROR:USERID:~p SOCKET ETIMEDOUT", [Client#client.user_id]),
    gen_tcp:close(Client#client.socket),
    Client#client.player_pid ! {'EXIT', Client#client.net_pid, {?error, ?etimedout}},
    {?noreply, Client#client{socket = 0, state = ?CONST_PLAYER_CLIENT_STATE_UNLOGIN}};

do_info({inet_async,  X,  Y, Reason}, Client) ->
	?MSG_ERROR("ERROR:~p|~p|~p", [X, Y, Reason]),
	{?stop, Reason, Client};

do_info(exit, Client) ->
	{?stop, ?normal, Client};

do_info({update_fcm_state, FcmState}, Client) ->
	Client2	= gateway_mod:do_update_fcm_state(Client, FcmState),
	{?noreply, Client2};

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
        gateway_worker_sup:delete_net(Client#client.net_pid),
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
	?true 	   = inet_db:register_socket(Socket, Mod),
	case prim_inet:getopts(ListenSocket, ?CONST_SET_CLIENT_TCP_OPTIONS) of
		{?ok, Opts} ->
			case prim_inet:setopts(Socket, Opts) of
				?ok		-> ?ok;
				?error 	-> gen_tcp:close(Socket), ?error
			end;
		?error -> gen_tcp:close(Socket), ?error
	end.


work(#client{rece_pack = 0} = Client) ->
	?MSG_DEBUG("drop packet = ~p", [Client#client.binary]),
	case async_recv(Client#client.socket, 0, ?CONST_TIMEOUT_SOCKET) of
		{?ok, Ref} -> {?ok, Client#client{rece_pack = 1,ref = Ref,binary = <<>>}};
		Error -> 
			?MSG_ERROR("~nError:~p Stack=~p~n", [Error, erlang:get_stacktrace()]),
			Error
	end;

%% 结构：长度(2字节)+序列号(1字节)+校验位(16个字节)+协议号(2字节)+包体
work(Client = #client{app_key = AppKey, sn = AccSN
,					  binary = <<Length:16/big-integer-unsigned,
								 SN:8/big-integer-unsigned,
								 Sing:8/binary,
								 MsgId:16/big-integer-unsigned,
								 Binary:Length/binary,
								 BinaryLast/binary>>}) ->
	% ?MSG_DEBUG("Length:~p SN:~p Sing=~p,MsgId = ~p,Binary = ~p,BinaryLast  = ~p", [Length, SN, Sing, MsgId,Binary,BinaryLast]),
	case misc_packet:unpack(AppKey, AccSN, SN, Sing, MsgId, Binary) of
		{?ok, AccSN2, _ModHandler, ?MSG_ID_PLAYER_HEART, _Datas} ->
		% ?MSG_DEBUG("heart : AccSN2:~p SN:~p ", [AccSN2, ?MSG_ID_PLAYER_HEART]),
			case gateway_mod:heart(Client, BinaryLast) of
				{?ok, Client2} ->
					work(Client2#client{sn = AccSN2});
				{?error, ErrorCode} ->
					?MSG_ERROR("~nErrorCode:~p Stack=~p~n", [ErrorCode, erlang:get_stacktrace()]),
					{?error, ErrorCode}
			end;
		{?ok, AccSN2, ModHandler, MsgId, Datas} ->
			% ?MSG_DEBUG("AccSN2:~p ModHandler:~p MsgId=~p,Datas = ~p", [AccSN2, ModHandler, MsgId, Datas]),
			Result	=
				try gateway_mod:do_work(Client, ModHandler, MsgId, Datas, BinaryLast, AccSN2) of
                    {?ok, reconnected} ->
                        {?ok, reconnected};
					{?ok, Client2} -> 
                        {?ok, Client2#client{sn = AccSN2}};
					{?error, go_to_hell_damn_you} -> 
                        {?error, go_to_hell_damn_you};
					{?error, ErrorCode} -> 
                        {?error, ErrorCode}
				catch Error:Reason ->
						  ?MSG_ERROR("Error:~p Reason:~p Stack=~p", [Error, Reason, erlang:get_stacktrace()]),
						  {?ok, Client#client{sn = AccSN2, binary = BinaryLast}}
				end,
			case Result of
                {?ok, reconnected} ->
                    {?ok, reconnected};
				{?ok, Client3} -> 
                    work(Client3);
				{?error, Error2} -> 
                    {?error, Error2}
			end;
		Error ->
			?MSG_ERROR("BAD PACKET === MsgId:~p Binary:~p", [MsgId, Binary]),
			?MSG_ERROR("Error:~p Stack:~p", [Error, erlang:get_stacktrace()]),
			{?error, bad_packet}
	end;
work(#client{socket = 0} = Client) ->
	% ?MSG_DEBUG("drop packet with socket = 0", []),	
    {?ok, Client};
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

repeat_login_cast(NetPid) ->
	gen_server:cast(NetPid, repeat_login).

reconnect_cast(NetPid, Socket, Ref, Sn, BinaryLast) ->
    gen_server:cast(NetPid, {reconnect, Socket, Ref, Sn, BinaryLast}).

stop(NetPid) when is_pid(NetPid) ->
    gen_server:cast(NetPid, stop);
stop(_) ->
    ok.

