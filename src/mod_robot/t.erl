%%% -------------------------------------------------------------------
%%% Author  : np
%%% Description :
%%%
%%% Created : 2013-1-18
%%% -------------------------------------------------------------------
-module(t).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
% protocol
-define(PROTOCOL_HEAD_LENGTH, 5).                % 协议头长度 
-define(IP,                   "192.168.52.106").  % ip
-define(PORT,                 6443).             % 端口

% tcp
-define(TCP_OPTIONS,          [binary, {packet, 0}, {active, false}]). % tcp选项
-define(TCP_TIMEOUT,          1000). % 解析协议超时时间

% logical
-define(HEART_BEAT_TIME,      31*1000). % 心跳

-define(LOG(Format, Data),              % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE] ++ Data)). 
-define(LOG(Format),                    % 日志
            io:format("[~p]:" ++ Format ++ " ~n", [?LINE])). 
-define(TRUE,  1).
-define(FALSE, 0).
%% --------------------------------------------------------------------
%% External exports
-export([
         get_heart_pid/1, get_rev_pid/1, get_state_socket/1, 
         set_heart_pid/2, set_rev_pid/2, set_state_socket/2
        ]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3, start_link/0]).

-record(state, {socket=0, heart_beat_pid=0, recv_pid=0, schedule=0}).
-record(schedule, {
                    in  = [],
                    out = []
                  }).
%% -record(task,     {
%%                     id    = 0,
%%                     state = 0
%%                   }).

%% ====================================================================
%% External functions
%% ====================================================================
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ====================================================================
%% Server functions
%% ====================================================================

%% --------------------------------------------------------------------
%% Function: init/1
%% Description: Initiates the server
%% Returns: {ok, State}          |
%%          {ok, State, Timeout} |
%%          ignore               |
%%          {stop, Reason}
%% --------------------------------------------------------------------
init([]) ->
    State = 
        case connect(0) of
            {ok, Socket} ->
                set_state_socket(#state{}, Socket);
            {error, Err} ->
                io:format("!err=~p", [Err]),
                #state{}
        end,
    State2  = State#state{schedule = #schedule{out = []}},
    Socket2 = get_state_socket(State2),
    send(Socket2, login_1003),
    State3 = handle_heart_beat(State2),
    State4 = handle_recv(State3),
    {ok, State4}.

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
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(_Msg, State) ->
    {noreply, State}.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info({Cmd, BinData}, State) ->
    Schedule  = State#state.schedule,
    {Packet, Schedule2} = t_mod:handle(Schedule, Cmd, BinData),
    Socket = get_state_socket(State),
    send(Socket, Packet),
    State2 = State#state{schedule = Schedule2},
    sleep(1000),
    {noreply, State2}.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(_Reason, State) ->
    close_socket(State),
    ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------

handle_heart_beat(StateData) ->
    Socket = StateData#state.socket,
    Pid = spawn_link(fun()-> run_heart(Socket) end),
    set_heart_pid(StateData, Pid).

handle_recv(StateData) ->
    Self = self(),
    Pid  = spawn_link(fun() -> do_parse_packet(StateData, Self, 0) end),
    set_rev_pid(StateData, Pid).

%% 接受信息
async_recv(Sock, Length, Timeout) when is_port(Sock) ->
    case prim_inet:async_recv(Sock, Length, Timeout) of
        {error, Reason} ->  throw({Reason});
        {ok, Res}       ->  Res
    end.

%%接收来自服务器的数据
do_parse_packet(StateData, Pid, Mark) when is_record(StateData, state) ->
    Socket = get_state_socket(StateData),
    if
        0 =/= Socket ->
            do_parse_packet(Socket, Pid, Mark);
        true ->
            ok
    end;
do_parse_packet(Socket, Pid, Mark) ->
    Ref = async_recv(Socket, ?PROTOCOL_HEAD_LENGTH, ?HEART_BEAT_TIME),
    receive
        {inet_async, Socket, Ref, {ok, <<Len:16, Cmd:16, IsZiped:1, _:7>>}} ->          
            BodyLen = Len,
            RecvData = 
                case BodyLen > 0 of
                    true ->
                        Ref1 = async_recv(Socket, BodyLen, ?TCP_TIMEOUT),
                        receive
                           {inet_async, Socket, Ref1, {ok, Binary}} ->
                                {ok, Binary};
                           Other ->
                                {fail, Other}
                        end;
                    false ->
                        {ok, <<>>}
                end,    
            case RecvData of
                {ok, BinData} ->
                    handle_protocol(Cmd, IsZiped, BinData, Pid),
                    do_parse_packet(Socket, Pid, Mark); 
                %%超时处理
                {fail, {inet_async, Socket, _Ref, {error,timeout}}} ->
                    ?LOG("~ts - do_parse_packet_2(~p)~n", [<<"收包超时">>, {Socket}]),
                    do_parse_packet(Socket, Pid, Mark); % 10006居然不返回
                {fail, Y} ->
                    ?LOG("~ts - do_parse_packet_1(~p)~n", [<<"收包失败">>, {Socket, Pid, Y}]),  
                    close_socket(Socket)
            end;
        %%超时处理
        {inet_async, Socket, Ref, {error,timeout}} ->
            do_parse_packet(Socket, Pid, Mark); % 10006居然不返回
        %%用户断开连接或出错
        Reason ->
            ?LOG("~ts - do_parse_packet_3(~p)~n", [<<"收包出错">>, {Socket, Reason}]),          
            close_socket(Socket)
    end.

run_heart(Socket) ->
    case send(Socket, heart_beat) of
        ok ->
            sleep(?HEART_BEAT_TIME),
            run_heart(Socket);
        _ ->
            error
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   休息T(ms)时间
%% @param  T 微秒数
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sleep(T) ->
    receive
    after T -> ok
    end.

%% 协议处理
handle_protocol(Cmd, ?FALSE, BinData, Pid) ->
    send_to_pid(Pid, {Cmd, BinData});
handle_protocol(Cmd, ?TRUE, BinData, Pid) ->
    BinData2 = zlib:uncompress(BinData),
    send_to_pid(Pid, {Cmd, BinData2}). 

send_to_pid(Pid, Msg) ->
    Pid ! Msg.

%% 建立tcp连接
%% {ok, Socket}/{error, Reason}
connect(0) ->
    gen_tcp:connect(?IP, ?PORT, ?TCP_OPTIONS);
connect(Socket) ->
    {ok, Socket}.

%% 关闭socket
close_socket(0) -> ok;
close_socket(Socket) ->
    gen_tcp:close(Socket).

%% 发送
send(Socket, Packet) when is_binary(Packet) ->
    gen_tcp:send(Socket, Packet);
send(Socket, PacketId) ->
    Packet = t_packet:get_packet(PacketId),
    gen_tcp:send(Socket, Packet).

set_state_socket(StateData, Socket) ->
    StateData#state{socket = Socket}.
get_state_socket(StateData) ->
    StateData#state.socket.

%% 心跳
set_heart_pid(StateData, Pid) ->
    StateData#state{heart_beat_pid=Pid}.
get_heart_pid(StateData) ->
    StateData#state.heart_beat_pid.

%% 接收器的pid
set_rev_pid(StateData, Pid) ->
    StateData#state{recv_pid=Pid}.
get_rev_pid(StateData) ->
    StateData#state.recv_pid.