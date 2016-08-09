%% -------------------------------------------------------------------
%% Author  : hezr@4399.net
%% Description :
%%					独立开发版本，不依赖于其他包可以直接运行
%% Created : 2012-6-18
%% -------------------------------------------------------------------
%% 状态机状态转移图如下:
%%                off
%%                 ^| "on"
%%           "off" |V
%%  +------------> on ------------------+
%%  |               ^                   | 
%%  |               |                   |
%%  |               +----------------- +| 
%%  |                                  || "login"
%%  |                         "logout" || 
%%  |                                  ||
%%  |                                  ||
%%  | "logout"/"error"                 |V "do"
%%  +--------doing<--------------------login                    
%%   
%%----------------------------------------------------------------------------                

-module(y).

-behaviour(gen_fsm).
-export([code_change/4, handle_event/3, handle_info/3, handle_sync_event/4, init/1, terminate/3]).
-compile(export_all).
%%=======================================records============================================
-record(map,     {
                 map_id  = 0,
                 x       = 0,
                 y       = 0,
                 real_map = [] % #real_map{}
                 }).

-record(guild,   {
                  id   = 0,
                  name = 0,
                  pos  = 0,
                  exploit = 0 
                 }).

-record(info,    {
                  lv   = 0,
                  exp  = 0,
                  expn = 0,
                  honour = 0,
                  meritorious = 0,
                  skill_point = 0,
                  power    = 0,
                  vip      = 0,
                  pro      = 0,
                  sex      = 0,
                  sp       = 0,
                  position = 0,
                  name     = "",
                  spirit   = 0,
                  title    = 0,
                  cultivation = 0,
                  experience = 0,
                  sys_id   = 0
                 }).

-record(money,   {
                  cash  = 0,
                  bcash = 0,
                  gold  = 0,
                  bgold = 0
                 }).

-record(attr,    {
                  force = 0,
                  fate = 0,
                  magic = 0,
                  hp_max = 0,
                  speed = 0,
                  force_atk = 0,
                  force_def = 0,
                  magic_atk = 0,
                  magic_def = 0,
                  hit = 0,
                  dodge = 0,
                  crit = 0,
                  parry = 0,
                  resist = 0,
                  unique = 0,
                  shadow = 0,
                  tough = 0,
                  crack = 0,
                  gaze = 0,
                  luck = 0,
                  sexy = 0,
                  fatal = 0,
                  idea = 0
                 }).

-record(train,  {
                 force = 0,
                 fate = 0,
                 magic = 0,
                 force_all = 0,
                 fate_all = 0,
                 magic_all = 0
                }).

-record(task,   {
                 id = 0,
                 state = 0,
                 count = 0,
                 time = 0,
                 target_list = [] % #target_list{}
                }).

-record(target_list, {
                      idx = 0,
                      ad1 = 0,
                      ad2 = 0,
                      ad3 = 0,
                      ad4 = 0,
                      ad5 = 0 
                     }).

-record(copy_data, {
                    copy_cur = []  % #copy_cur{}
                   }).

-record(copy_cur,  {
                    id = 0,
                    mon_id = 0,
                    wave = 0,
                    plot_id = 0 
                   }).
%% 
%% -record(unit_group, {
%%                      side = 0,
%%                      camp_id = 0,
%%                      camp_lv = 0,
%%                      player_units = [],
%%                      partner_units = [],
%%                      mon_units = [] 
%%                     }).
%% 
%% -record(player_unit, {
%%                       idx = 0,
%%                       anger = 0,
%%                       anger_max = 0,
%%                       hp = 0,
%%                       hp_max = 0,
%%                       user_id = 0,
%%                       name = "",
%%                       lv = 0,
%%                       pro = 0,
%%                       sex = 0,
%%                       vip = 0,
%%                       armor = 0,
%%                       weapon = 0,
%%                       assister_list = [] % [id,id,id...]
%%                      }).
%% 
%% -record(partner_unit, {
%%                        idx = 0,
%%                        anger = 0,
%%                        anger_max = 0,
%%                        hp = 0,
%%                        hp_max = 0,
%%                        partner_id = 0,
%%                        assister_list = [] % [id,id,id...]
%%                       }).
%% 
%% -record(mon_unit, {
%%                    idx = 0,
%%                    anger = 0,
%%                    anger_max = 0,
%%                    hp = 0,
%%                    hp_max = 0,
%%                    mon_id = 0
%%                   }).

-record(real_map,  {
                    x,
                    y,
                    user_id,
                    sex
                   }).

-record(player, {
                 user_id = 0,
                 serv_id = 0,
                 account = 0,
                 time    = 0,
                 user_state = 0,
                 is_a    = 0,
                 map     = #map{},
                 guild   = #guild{},
                 info    = #info{},
                 money   = #money{},
                 attr    = #attr{},
                 train   = #train{},
                 task    = [], % #task{}
                 copy    = #copy_data{}
                }).
%%=s=======================================define & records======================================
% protocol
-define(PROTOCOL_HEAD_LENGTH, 5).                % 协议头长度 
-define(IP,                   "127.0.0.1").  % ip
-define(PORT,                 8001).             % 端口

% tcp
-define(TCP_OPTIONS,          [binary, {packet, 0}, {active, false}]). % tcp选项
-define(TCP_TIMEOUT,          1000). % 解析协议超时时间

% sys
-define(REG_NAME,             erlang:list_to_atom(lists:concat([?MODULE, "_", ?ACC_NAME]))). % 注册名
-define(REG_NAME(AccId),      erlang:list_to_atom(lists:concat([?MODULE, "_", ?ACC_NAME(AccId)]))). % 注册名
-define(F(AccId),             ok). %lists:concat([p, AccId, ".log"])). % 文件名
-define(FILE_OPTIONS,         [append, raw]). % 文件打开选项
-define(DO(Cmd),              gen_fsm:send_event(?REG_NAME, Cmd)). % 状态转换
-define(DO(AccId, Cmd),       gen_fsm:send_event(?REG_NAME(AccId), Cmd)). % 状态转换
-define(EVENT(Msg),           gen_fsm:send_all_state_event(?REG_NAME, Msg)).
-define(EVENT(AccId, Msg),           gen_fsm:send_all_state_event(?REG_NAME(AccId), Msg)).
-define(LOG(Format, Data),              % 日志
			io:format("[~p]:" ++ Format ++ " ~n", [?LINE] ++ Data)). 
-define(LOG(Format),                    % 日志
			io:format("[~p]:" ++ Format ++ " ~n", [?LINE])). 
-define(FOG(StateData, Format, Data),
            ok).%file:write(StateData#state.fd, io_lib:format(Format++ " ~n", Data))).
-define(DEFAULT_ROOT_KEY,             "%6JW%NY&").

% 状态
-define(ON,                   on).
-define(OFF,                  off).
-define(LOGIN,                login).
-define(DOING,                doing).

-define(TRUE,  1).
-define(FALSE, 0).

% logical
-define(HEART_BEAT_TIME,      31*1000). % 心跳
-define(SERV_ID,               1). % 帐号
-define(ACC_ID,               "1"). % 帐号
-define(ACC_NAME,             lists:concat(["tty", ?ACC_ID])). % 玩家名
-define(ACC_NAME(AccId),      lists:concat(["tty", AccId])). % 玩家名
%% -define(ACC_NAME,             "tty"). % 玩家名
-define(MIN_SN,               1).
-define(MAX_SN,               250).

% ets
-define(ETS_PLAYER,           ets_player).

-record(state, {state=?OFF, socket=0, heart_beat_pid=0, recv_pid=0, 
                logical_pid=0, fd=0, player=#player{}, observer_pid=0,
                app_key="", root_key=?DEFAULT_ROOT_KEY, res_key="",
                app_cipher="", resource_cipher="", sn=1, acc_id = 0,
                acc_name = ""}).
-record(arg, {cmd, param}).
%%=e========================================define & records======================================

start_link() ->
	gen_fsm:start_link({local, ?REG_NAME}, ?MODULE, [], []).
start_link(AccId) ->
	gen_fsm:start_link({local, ?REG_NAME(AccId)}, ?MODULE, [AccId], []).

%% ====================================================================
%% Server functions
%% ====================================================================
%% --------------------------------------------------------------------
%% Func: init/1
%% Returns: {ok, StateName, StateData}          |
%%          {ok, StateName, StateData, Timeout} |
%%          ignore                              |
%%          {stop, StopReason}
%% --------------------------------------------------------------------
init([]) ->
    handle_init(),
    StateData  = init_state(?ON),
%%     Pideobj    = spawn_link(fun() -> observer:start() end),
%%     StateData2 = set_state_obj_id(StateData, Pideobj),
    {ok, ?ON, StateData};
init([AccId]) ->
    handle_init(),
    StateData  = init_state(?ON, AccId),
%%     Pideobj    = spawn_link(fun() -> observer:start() end),
%%     StateData2 = set_state_obj_id(StateData, Pideobj),
    {ok, ?ON, StateData}.

do(AccId, Cmd)          -> ?DO(AccId, Cmd).
do(AccId, Cmd, Param)   -> ?DO(AccId, {doing, #arg{cmd=Cmd, param=Param}}).
test(AccId, Cmd, Param) -> ?DO(AccId, {test,  #arg{cmd=Cmd, param=Param}}).
do_error(AccId, Reason) -> ?DO(AccId, {error, Reason}).

show(AccId) -> ?EVENT(AccId, show).
show(AccId, Args) -> ?EVENT(AccId, {show, Args}).
stop(AccId) -> ?EVENT(AccId, stop).

%% --------------------------------------------------------------------
%% Func: StateName/2
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
on(off, StateData) ->
    switch_state(StateData, ?OFF);
on(login, StateData) ->
	case handle_login(StateData) of
		{ok, NewStateData} ->
			NewStateData2 = handle_recv(NewStateData),
            switch_state(NewStateData2, ?LOGIN);
		{error, _Reason} ->
            switch_state(StateData, ?ON)
	end;
on(Event, StateData) ->
    err_msg(StateData, Event),
    switch_state(StateData, ?ON).

off(on, StateData) ->
	switch_state(StateData, ?ON);
off(Event, StateData) ->
    err_msg(StateData, Event),
    switch_state(StateData, ?OFF).

login(do, StateData) ->
    switch_state(StateData, ?DOING);
login({doing, Arg}, StateData) ->
	StateData2 = handle_doing(Arg, StateData),
    switch_state(StateData2, ?DOING);
login(logout, StateData) ->
	NewStateData = handle_logout(StateData),
    switch_state(NewStateData, ?ON);
login({error, Reason}, StateData) ->
    err_msg(StateData, Reason),
    switch_state(StateData, ?OFF);
login(Event, StateData) ->
	err_msg(StateData, Event),
    switch_state(StateData, ?LOGIN).

doing(do, StateData) ->
    switch_state(StateData, ?DOING);
doing(logout, StateData) ->
	NewStateData = handle_logout(StateData),
    switch_state(NewStateData, ?ON);
doing({error, Reason}, StateData) ->
	err_msg(StateData, Reason),
    switch_state(StateData, ?ON);
doing({doing, Arg}, StateData) ->
	StateData2 = handle_doing(Arg, StateData),
    switch_state(StateData2, ?DOING);
doing(Event, StateData) ->
    err_msg(StateData, Event),
    switch_state(StateData, ?DOING).

%%-----------------------处理器----------------------------------------------
handle_login(StateData) ->
	case connect(StateData) of
		{ok, StateData2} ->
			case send(StateData2, 1003, 0) of
				{ok, StateData3} ->
                    {ok, StateData3};
				{error, Reason} ->
                    err_msg(StateData, Reason),
				  	{error, Reason}
			end;
		{error, Reason} ->
            err_msg(StateData, Reason),
			{error, Reason}
	end.

handle_logout(StateData) ->
    close_socket(StateData),
	send_to_pid(StateData#state.heart_beat_pid, stop), 
	send_to_pid(StateData#state.recv_pid, stop), 
    init_state(StateData).

handle_heart_beat(StateData, Pid) ->
    send_to_pid(Pid, heart_beat),
    StateData.
handle_heart_beat(StateData) ->
    Self = self(),
    {_, StateData2} = send(StateData, heart_beat),
    erlang:send_after(?HEART_BEAT_TIME, Self, heart),
    StateData2.

handle_doing(#arg{cmd=Cmd, param=Param}, StateData) ->
    {_, StateData2} = send(StateData, {Cmd, Param}),
    StateData2;
handle_doing(X, StateData) ->
    err_msg(StateData, X),
    StateData.

handle_recv(StateData) ->
    Self = self(),
	Pid  = spawn_link(fun() -> do_parse_packet(StateData, Self, 0) end),
    set_rev_pid(StateData, Pid).

%% 初始化
handle_init() ->
    OsType = os:type(),
    case OsType of
        {_, nt} -> os:cmd("taskkill\ /f\ /im\ cmd.exe"), ok;
        _ -> ok
    end,
    init_ets(),
    application:start(crypto),
    ok.

%% 初始化玩家日志
%% {ok, IoDevice} | {error, Reason}
init_file(AccId) ->
    FileName = ?F(AccId),
    file:open(FileName, ?FILE_OPTIONS).

%%========================================其他===================================================
%% 状态转换
switch_state(StateData, State) ->
    OrgState = StateData#state.state,
    StateStr = lists:concat([OrgState, "->", State]),
    ?LOG(StateStr),
    {next_state, State, StateData#state{state=State}}.

err_msg(StateData, Event) when is_list(Event) ->
    ?FOG(StateData, "![err]event=~s", [Event]);
err_msg(StateData, Event) ->
    ?FOG(StateData, "![err]event=~p", [Event]).

%% 插入玩家数据
insert_player(Player) ->
    ets:insert(?ETS_PLAYER, Player).

%% 删除玩家数据
delete_player(UserId) ->
    ets:delete(?ETS_PLAYER, UserId).

%% sn

    
%%==================================getter & setter===============================================
set_state_socket(StateData, Socket) ->
    StateData#state{socket = Socket}.
get_state_socket(StateData) ->
    StateData#state.socket.

%% app key
set_socket_app_chiper(StateData, AppChiper) when is_binary(AppChiper) ->
    AppKeyDe = decrypt_app_key(StateData#state.root_key, AppChiper),
    set_socket_app_chiper(StateData, AppChiper, AppKeyDe).
set_socket_app_chiper(StateData, AppChiper, AppKeyDe) ->
    StateData#state{app_cipher = AppChiper, app_key = AppKeyDe}.
get_socket_app_chiper(StateData) ->
    StateData#state.app_cipher.
get_socket_app_key(StateData) ->
    StateData#state.app_key.

%% res key
set_socket_resource_cipher(StateData, ResourceChiper) when is_binary(ResourceChiper) ->
    ResourceChiperDe = decrypt_app_key(StateData#state.root_key, ResourceChiper),
    set_socket_resource_cipher(StateData, ResourceChiper, ResourceChiperDe).
set_socket_resource_cipher(StateData, ResourceChiper, ResourceChiperDe) ->
    StateData#state{res_key = ResourceChiperDe, resource_cipher = ResourceChiper}.
get_socket_resource_cipher(StateData) ->
    StateData#state.resource_cipher.
get_socket_resource_key(StateData) ->
    StateData#state.res_key.

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

get_state_fd(StateData) ->
    StateData#state.fd.

%% player
set_state_player(StateData, Player) ->
    StateData#state{player = Player}.
get_state_player(StateData) ->
    StateData#state.player.

set_state_obj_id(StateData, Pideobj) ->
    StateData#state{observer_pid = Pideobj}.

set_state(StateData, State) ->
    StateData#state{state = State}.

set_player_time(StateData, Time) ->
    Player = get_state_player(StateData),
    Player2 = Player#player{time = Time},
    StateData#state{player = Player2}.
get_player_time(StateData) ->
    Player = StateData#state.player,
    Player#player.time.

get_player_info(Player) ->
    Player#player.info.
set_player_info(Player, Info) ->
    Player#player{info = Info}.

set_player_sys_id(StateData, SysId) ->
    Player  = get_state_player(StateData),
    Info    = get_player_info(Player),
    Info2   = Info#info{sys_id = SysId},
    Player2 = set_player_info(Player, Info2),
    StateData#state{player = Player2}.

get_player_task(Player) when is_record(Player, player) ->
    Player#player.task;
get_player_task(StateData) ->
    Player = StateData#state.player,
    get_player_task(Player).
set_player_task(StateData, Task) when is_record(Task, task) ->
    Player  = get_state_player(StateData),
    Task2   = get_player_task(Player),
    Task3   = lists:keydelete(Task#task.id, #task.id, Task2),
    Player2 = Player#player{task = [Task|Task3]},
    StateData#state{player = Player2};
set_player_task(StateData, Task) ->
    Player  = get_state_player(StateData),
    Player2 = Player#player{task = Task},
    StateData#state{player = Player2}.

get_player_map(Player)   -> Player#player.map.
set_player_map(Player, MapData) -> Player#player{map = MapData}.

get_player_guild(Player) -> Player#player.guild.
get_player_money(Player) -> Player#player.money.
get_player_attr(Player)  -> Player#player.attr.
get_player_train(Player) -> Player#player.train.

set_player_copy(Player, CopyData) -> Player#player{copy = CopyData}.
get_player_copy(Player) -> Player#player.copy.
set_copy_cur(Player, CopyCur) -> 
    CopyData  = get_player_copy(Player),
    CopyData2 = CopyData#copy_data{copy_cur = CopyCur},
    set_player_copy(Player, CopyData2).

get_player_user_state(Player) -> Player#player.user_state.
set_player_user_state(Player, State) -> Player#player{user_state = State}.

get_player_user_id(Player) -> Player#player.user_id.

get_real_map(MapData) ->
    MapData#map.real_map.
set_real_map(MapData, RealMapUnit) ->
    RealMap = get_real_map(MapData),
    RealMap2 = lists:keydelete(RealMapUnit#real_map.user_id, #real_map.user_id, RealMap),
    RealMap3 = [RealMapUnit|RealMap2],
    MapData#map{real_map = RealMap3}.
set_real_map(MapData, UserId, X, Y) ->
    RealMap = get_real_map(MapData),
    {value, RealMap2, Tuple2} = lists:keytake(UserId, #real_map.user_id, RealMap),
    RealMap3 = [RealMap2#real_map{x = X, y = Y}|Tuple2],
    {MapData#map{real_map = RealMap3}, RealMap2#real_map.x, RealMap2#real_map.y}.
del_real_map(MapData, UserId) ->
    RealMap = get_real_map(MapData),
    RealMap2 = lists:keydelete(UserId, #real_map.user_id, RealMap),
    MapData#map{real_map = RealMap2}.

set_info_lv(Info, Lv) when Info#info.lv < Lv -> 
    Info#info{lv = Lv};
set_info_lv(Info, _Lv) -> Info.

get_state_sn(StateData) ->
    StateData#state.sn.
set_state_sn(StateData, Sn) ->
    StateData#state{sn = Sn}.
upgrade_state_sn(StateData) ->
    Sn = StateData#state.sn,
    NewSn = Sn + 1,
    if
        NewSn > ?MAX_SN ->
            StateData#state{sn = ?MIN_SN};
        true ->
            StateData#state{sn = NewSn}
    end.

%%========================================init===================================================
%% 初始化进程状态
init_state(StateData) when is_record(StateData, state) ->
    StateData#state{socket = 0, heart_beat_pid = 0, recv_pid = 0};
init_state(State) ->
    LogicalPid = self(),
    Fd2 = 
        case init_file(?ACC_ID) of
            {ok, Fd} ->
                Fd;
            {error, _Reason} ->
                0
        end,
    #state{socket = 0, heart_beat_pid = 0, recv_pid = 0, state = State, logical_pid = LogicalPid, fd = Fd2}.
init_state(State, AccId) ->
    LogicalPid = self(),
    Fd2 = 
        case init_file(AccId) of
            {ok, Fd} ->
                Fd;
            {error, _Reason} ->
                0
        end,
    #state{socket = 0, heart_beat_pid = 0, recv_pid = 0, state = State, logical_pid = LogicalPid, fd = Fd2, acc_id = AccId, acc_name = ?ACC_NAME(AccId)}.

%% 初始化所有ets
init_ets() ->
    try
        ets:new(?ETS_PLAYER, [set,public,named_table,{keypos, #player.user_id},{write_concurrency,true}])
    catch
        _:_ ->
            ok
    end,
    ok.

%%========================================其他===================================================
%% 建立tcp连接
%% {ok, Socket}/{error, Reason}
connect(StateData) ->
    Socket = get_state_socket(StateData),
    if
        0 =:= Socket ->
            case gen_tcp:connect(?IP, ?PORT, ?TCP_OPTIONS) of
                {ok, Socket2} ->
                    StateData2 = set_state_socket(StateData, Socket2),
                    {ok, StateData2};
                {error, Reason} ->
                    {error, Reason}
            end;
        true ->
            {ok, StateData}
    end.

%% 发送协议
send(StateData, <<>>) -> {ok, StateData};
send(StateData, Packet) when is_binary(Packet) ->
    Socket = get_state_socket(StateData),
    Result = gen_tcp:send(Socket, Packet),
    {Result, StateData};
send(StateData, CmdStr) ->
    Socket = get_state_socket(StateData),
    {StateData2, Packet} = get_packet(StateData, CmdStr),
    Result = gen_tcp:send(Socket, Packet),
    ?FOG(StateData2, "<<~p", [CmdStr]),
    {Result, StateData2}.
send(StateData, Cmd, Args) when is_record(StateData, state) ->
    Socket = get_state_socket(StateData),
    ?FOG(StateData, "<<~p", [Cmd]),
    {StateData2, Packet} = get_packet(StateData, {Cmd, Args}),
    Result = gen_tcp:send(Socket, Packet),
    {Result, StateData2}.

%% 关闭socket
close_socket(StateData) when is_record(StateData, state) ->
    Socket = get_state_socket(StateData),
    if
        0 =/= Socket ->
            gen_tcp:close(Socket);
        true ->
            ok
    end;
close_socket(StateData) ->
    err_msg(StateData, StateData),
    ok.

close_file(StateData) when is_record(StateData, state) ->
    Fd = get_state_fd(StateData),
    if
        0 =/= Fd ->
            file:close(Fd);
        true ->
            ok
    end;
close_file(_StateData) ->
    ok.

encode_string(String) when is_list(String) ->
    Bin = unicode:characters_to_binary(String),
    Len = get_len(Bin),
    <<Len:16, Bin:Len/binary>>;
encode_string(Bin) ->
    Len = get_len(Bin),
    <<Len:16, Bin:Len/binary>>.

%% --------------------------------------------------------------------
%% Func: StateName/3
%% Returns: {next_state, NextStateName, NextStateData}            |
%%          {next_state, NextStateName, NextStateData, Timeout}   |
%%          {reply, Reply, NextStateName, NextStateData}          |
%%          {reply, Reply, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}                          |
%%          {stop, Reason, Reply, NewStateData}
%% --------------------------------------------------------------------
on(off, _From, StateData) ->
    Reply = ok,
    {reply, Reply, off, StateData}.

off(_Event, _From, StateData) ->
    Reply = ok,
    {reply, Reply, on, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_event/3
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
handle_event(show, StateName, StateData) ->
	format_show_state(StateData),
	{next_state, StateName, StateData};
handle_event({show, info}, StateName, StateData) ->
	format_show_info(StateData),
	{next_state, StateName, StateData};
handle_event({show, guild}, StateName, StateData) ->
	format_show_guild(StateData),
	{next_state, StateName, StateData};
handle_event({show, money}, StateName, StateData) ->
	format_show_money(StateData),
	{next_state, StateName, StateData};
handle_event({show, attr}, StateName, StateData) ->
	format_show_attr(StateData),
	{next_state, StateName, StateData};
handle_event({show, task}, StateName, StateData) ->
	format_show_task(StateData),
	{next_state, StateName, StateData};
handle_event({show, real_map}, StateName, StateData) ->
	format_show_real_map(StateData),
	{next_state, StateName, StateData};
handle_event(stop, _StateName, StateData) ->
	close_socket(StateData),
	{stop, ?OFF, StateData};
handle_event(Event, StateName, StateData) ->
	err_msg(StateData, Event),
    {next_state, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_sync_event/4
%% Returns: {next_state, NextStateName, NextStateData}            |
%%          {next_state, NextStateName, NextStateData, Timeout}   |
%%          {reply, Reply, NextStateName, NextStateData}          |
%%          {reply, Reply, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}                          |
%%          {stop, Reason, Reply, NewStateData}
%% --------------------------------------------------------------------
handle_sync_event(Event, _From, StateName, StateData) ->
	?LOG("handle_sync_event:Event=~w", [Event]),
    Reply = ok,
    {reply, Reply, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: handle_info/3
%% Returns: {next_state, NextStateName, NextStateData}          |
%%          {next_state, NextStateName, NextStateData, Timeout} |
%%          {stop, Reason, NewStateData}
%% --------------------------------------------------------------------
handle_info(heart, StateName, StateData) ->
    StateData2 = handle_heart_beat(StateData),
    {next_state, StateName, StateData2};
handle_info({Cmd, BinData}, StateName, StateData) ->
    Protocol = do_bin2protocol(Cmd, BinData),
    case Protocol of
        {0} ->
            ok;
        _ ->
            ?FOG(StateData, "~p ->|~w", [Cmd, Protocol])
    end,
    StateData2 = do_protocol_handler(Cmd, Protocol, StateData),
    {next_state, StateName, StateData2};
handle_info(Info, StateName, StateData) ->
	?LOG("handle_info:Info=~w", [Info]),
    {next_state, StateName, StateData}.

%% --------------------------------------------------------------------
%% Func: terminate/3
%% Purpose: Shutdown the fsm
%% Returns: any
%% --------------------------------------------------------------------
terminate(_Reason, _StateName, StateData) ->
    close_socket(StateData),
    close_file(StateData).

%% --------------------------------------------------------------------
%% Func: code_change/4
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState, NewStateData}
%% --------------------------------------------------------------------
code_change(_OldVsn, StateName, StateData, _Extra) ->
    {ok, StateName, StateData}.

%%------------------------------------------------------------------------
%% 接受信息
async_recv(Sock, Length, Timeout) when is_port(Sock) ->
    case prim_inet:async_recv(Sock, Length, Timeout) of
        {error, Reason} -> 	throw({Reason});
        {ok, Res}       ->  Res
    end.

%%接收来自服务器的数据
do_parse_packet(StateData, Pid, Mark) when is_record(StateData, state) ->
    AccId = StateData#state.acc_id,
    Socket = get_state_socket(StateData),
    if
        0 =/= Socket ->
            do_parse_packet_2(AccId, Socket, Pid, Mark);
        true ->
            ok
    end.
do_parse_packet_2(AccId, Socket, Pid, Mark) ->
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
                    ?LOG(">>[~p]", [BinData]),
                    handle_protocol(Cmd, IsZiped, BinData, Pid),
					do_parse_packet_2(AccId, Socket, Pid, Mark);	
                %%超时处理
                {fail, {inet_async, Socket, _Ref, {error,timeout}}} ->
                    ?LOG("~ts - do_parse_packet_2(~p)~n", [<<"收包超时">>, {Socket}]),
                    do_parse_packet_2(AccId, Socket, Pid, Mark); % 10006居然不返回
				{fail, Y} ->
					?LOG("~ts - do_parse_packet_1(~p)~n", [<<"收包失败">>, {Socket, Pid, Y}]),	
					gen_tcp:close(Socket),
					do_error(AccId, "socket_error_1")
			end;
		%%超时处理
		{inet_async, Socket, Ref, {error,timeout}} ->
%% 			?LOG("~ts - do_parse_packet_2(~p)~n", [<<"收包超时">>, {Socket}]),
			do_parse_packet_2(AccId, Socket, Pid, Mark); % 10006居然不返回
        'heart' ->
            handle_heart_beat(Socket, Pid);
        %%用户断开连接或出错
        Reason ->
			?LOG("~ts - do_parse_packet_3(~p)~n", [<<"收包出错">>, {Socket, Reason}]),			
            gen_tcp:close(Socket),
			do_error(AccId, "socket_error_2")
    end.

%% 协议处理
handle_protocol(Cmd, ?FALSE, BinData, Pid) ->
    send_to_pid(Pid, {Cmd, BinData});
handle_protocol(Cmd, ?TRUE, BinData, Pid) ->
    BinData2 = zlib:uncompress(BinData),
    send_to_pid(Pid, {Cmd, BinData2}). 

send_to_pid(Pid, Msg) ->
    Pid ! Msg.
%%====================================packet=================================================
get_packet(StateData, heart_beat) ->
    Body = <<>>,
    pack(StateData, 1999, Body);
get_packet(StateData, {1003, _}) ->
    AccName = StateData#state.acc_name,
    Account = encode_string(AccName),
    pack(StateData, 1003, <<Account/binary, ?SERV_ID:16>>);
get_packet(StateData, {1005, _Param}) ->
    AccName = StateData#state.acc_name,
    Name = encode_string(AccName),
    Body = <<Name/binary, 1:8, 1:8>>,
    pack(StateData, 1005, Body);
get_packet(StateData, {1007, _}) ->
    pack(StateData, 1007, <<>>);
%% 地图
get_packet(StateData, {5001, MapId}) -> % 进地图
    pack(StateData, 5001, <<MapId:16>>);
get_packet(StateData, {5021, {_, X, Y}}) -> % 角色移动
    Player  = get_state_player(StateData),
    UserId = get_player_user_id(Player),
    pack(StateData, 5021, <<UserId:32, X:16, Y:16>>);
%% 聊天
get_packet(StateData, {8001, {Channel, Content}}) ->
    BinContent = encode_string(Content),
    pack(StateData, 8001, <<Channel:8, BinContent/binary, 0:16>>);
%% 
get_packet(StateData, {4203, Type}) -> % 寻访
    pack(StateData, 4203, <<Type:8, 0:8, 0:8>>);
get_packet(StateData, {4205, PartnerId}) -> % 招募
    pack(StateData, 4205, <<PartnerId:16>>);
%% 副本
get_packet(StateData, {13001, CopyId}) -> % 进入副本
    pack(StateData, 13001, <<CopyId:16>>);
get_packet(StateData, {13005, _}) -> % 离开副本
    pack(StateData, 13005, <<>>);
get_packet(StateData, {13025, MonId}) -> % 发起战斗
    pack(StateData, 13025, <<MonId:16>>);
%% 任务
get_packet(StateData, {20011, TaskId}) -> % 接任务
    pack(StateData, 20011, <<TaskId:16>>);
get_packet(StateData, {20021, TaskId}) -> % 交任务
    pack(StateData, 20021, <<TaskId:16>>);
%%
get_packet(StateData, {27301, _}) -> 
    pack(StateData, 27301, <<0:16>>);
get_packet(StateData, AnyOther) ->
    ?LOG("![err]packet=~p", [AnyOther]),
    {StateData, <<>>}.
%%================================bin2protocol=======================================================
do_bin2protocol(1002, <<IsTrue:8, L:16, AppCipher:L/binary, L2:16, ResourceCipher:L2/binary>>) ->
    {IsTrue, AppCipher, ResourceCipher};
do_bin2protocol(1006, X) ->
    {X};
do_bin2protocol(1014, <<X:8>>) ->
    {X};
do_bin2protocol(1012, BinData) ->
    Player = bin2record(BinData, player),
    {Player};
do_bin2protocol(1020, <<Type:8, Value:32>>) ->
    {Type, Value};
do_bin2protocol(1410, <<SysId:8>>) ->
    {SysId};
do_bin2protocol(2110, _) -> %
    {0};
do_bin2protocol(2120, _) ->
    {0};
do_bin2protocol(3012, <<Result:8, _Tail/binary>>) -> % 战斗结果
    if
        1 =:= Result ->
            {win};
        true ->
            {lose}
    end;
do_bin2protocol(3100, _) ->
    {x};
do_bin2protocol(3150, _) -> % 
    {o};
do_bin2protocol(3160, _) -> % 
    {x};
do_bin2protocol(3600, _) -> % 
    {o};
do_bin2protocol(3620, _) -> % 
    {x};
do_bin2protocol(5010, <<MapId:16, UserId:32, UserNameLen:16, _UserName:UserNameLen/binary, _Pro:8,
                        Sex:8, _Lv:8, _Vip:8, _State:8, _LeaderId:32, X:16, Y:16, _/binary>>) ->
    {MapId, UserId, Sex, X, Y};
do_bin2protocol(5012, <<MapId:16, UserId:32, _Reason:8>>) ->
    {MapId, UserId};
do_bin2protocol(5022, <<UserId:32, X:16, Y:16>>) ->
    {UserId, X, Y};
do_bin2protocol(5030, _) ->
    {0};
do_bin2protocol(1300, <<FcmState:8, Time:32>>) -> % 防沉迷通知
    {FcmState, Time};
do_bin2protocol(1998, <<_Time:32>>) -> % 时间同步协议
    {0};
do_bin2protocol(5098, <<UserId:32, State:8>>) -> % 玩家状态改变
    {UserId, State};
do_bin2protocol(8006, _) -> % 系统消息
    {0};
%% 副本
do_bin2protocol(13002, <<CopyId:16, MonId:16, Wave:8, PlotId:16>>) -> % 副本怪物信息
    {CopyId, MonId, Wave, PlotId};
do_bin2protocol(13012, _) -> % 
    {0};
do_bin2protocol(13010, _) -> % 副本结束
    {copy_over};
do_bin2protocol(13008, <<Len1:16, Tail1/binary>>) -> %
    UnitLen1 = 24,
    Len1_2 = Len1 * UnitLen1,
    <<X1:Len1_2/bitstring, _Len2:16, X2/binary>> = Tail1,
    List1 = decode_cycle(UnitLen1, X1, fun de_func_13008_1/1),
    UnitLen2 = 32,
    List2 = decode_cycle(UnitLen2, X2, fun de_func_13008_2/1),
    {List1, List2};
do_bin2protocol(16008, _) -> % 
    {0};
%% 任务
do_bin2protocol(20010, <<TaskId:16, State:8, Count:8, Time:32, _Cycle:16, Tail/binary>>) -> % 返回任务信息
    List = decode_cycle(Tail, []),
    {TaskId, State, Count, Time, List};
do_bin2protocol(20050, <<TaskId:16, Reason:8>>) -> % 删除任务
    {TaskId, Reason};
do_bin2protocol(20060, <<Count:8>>) -> % 日常任务次数
    {Count};
%% 消息
do_bin2protocol(25200, <<MsgId:16>>) -> % 返回任务信息
    {MsgId};
do_bin2protocol(25300, _) -> % 返回任务信息
    {0};
do_bin2protocol(32002, <<_Type:16>>) -> % 活动开启
    {0};
do_bin2protocol(_, X) ->
    {X}.

de_func_13008_1(<<CopyId:16, State:8>>) -> {CopyId, State}.
de_func_13008_2(<<CopyId:16, Times:8, IsTaken:8>>) -> {CopyId, Times, IsTaken}.

decode_cycle(UnitLen, Binary, Func) when is_function(Func) -> 
    decode_cycle(UnitLen, Binary, Func, []).

decode_cycle(_UnitLen, <<>>, Func, ResultList) when is_function(Func) -> ResultList;
decode_cycle(UnitLen, BinaryTotal, Func, ResultList) when is_function(Func) ->
    <<Binary:UnitLen/bitstring, Tail/binary>> = BinaryTotal,
    Result = Func(Binary),
    NewResultList = [Result|ResultList],
    decode_cycle(UnitLen, Tail, Func, NewResultList).

decode_cycle(<<Idx:8, Ad1:8, Ad2:8, Ad3:8, Ad4:8, Ad5:8, Tail/binary>>, List) ->
    List2 = [#target_list{idx = Idx, ad1 = Ad1, ad2 = Ad2, ad3 = Ad3, ad4 = Ad4, ad5 = Ad5}|List],
    decode_cycle(Tail, List2);
decode_cycle(<<>>, List) -> List.
%%=======================================================================================
do_protocol_handler(1002, {?FALSE, AppChiper, ResourceChiper}, StateData) -> % 登录成功,没有人物
    StateData2 = set_socket_app_chiper(StateData, AppChiper),
    StateData3 = set_socket_resource_cipher(StateData2, ResourceChiper),
    {_, StateData4} = send(StateData3, 1005, 0),
%%     {_, StateData5} = send(StateData4, 8001, {1, "- 跳过"}),
    StateData5 = handle_heart_beat(StateData4),
    StateData5;
do_protocol_handler(1002, {?TRUE, AppChiper, ResourceChiper}, StateData) -> % 登录成功,有人物
    StateData2 = set_socket_app_chiper(StateData, AppChiper),
    StateData3 = set_socket_resource_cipher(StateData2, ResourceChiper),
    {_, StateData4} = send(StateData3, 1007, 0),
    StateData5 = handle_heart_beat(StateData4),
    StateData5;
do_protocol_handler(1006, _, StateData) -> % 创建成功
    {_, StateData2} = send(StateData, 1007, 0),
    StateData2;
do_protocol_handler(1014, {IsA}, StateData) -> % a/b版
    Player = get_state_player(StateData),
    Player2 = Player#player{is_a = IsA},
    StateData2 = set_state_player(StateData, Player2),
    StateData2;
do_protocol_handler(1012, {Player}, StateData) -> %
    StateData2 = set_state_player(StateData, Player),
    {_, StateData3} = send(StateData2, 5001, 0),
    StateData3;
do_protocol_handler(1020, {58, Value}, StateData) -> % 单个属性更新
    Player = get_state_player(StateData),
    Info = get_player_info(Player),
    Info2 = set_info_lv(Info, Value),
    Player2 = set_player_info(Player, Info2),
    set_state_player(StateData, Player2);
do_protocol_handler(1020, {_, _Value}, StateData) -> % 单个属性更新
    StateData;
do_protocol_handler(2102, _, StateData) -> %
    StateData;
do_protocol_handler(2110, _, StateData) -> %
    StateData;
do_protocol_handler(2120, _, StateData) -> %
    StateData;
do_protocol_handler(3012, _, StateData) -> % 
    StateData;
do_protocol_handler(3100, _, StateData) -> % 
    StateData;
do_protocol_handler(3150, _, StateData) -> %
    StateData;
do_protocol_handler(3160, _, StateData) -> %
    StateData;
do_protocol_handler(3600, _, StateData) -> %
    StateData;
do_protocol_handler(3620, _, StateData) -> %
    StateData;
do_protocol_handler(4002, _, StateData) -> %
    StateData;
do_protocol_handler(5010, {MapId, UserId, Sex, X, Y}, StateData) -> %
    ?FOG(StateData, "~w is standing on map[~w] (~w, ~w)", [UserId, MapId, X, Y]),
    Player = get_state_player(StateData),
    MapData = get_player_map(Player),
    MapData2 = set_real_map(MapData, #real_map{sex = Sex, user_id = UserId, x = X, y = Y}),
    Player2 = set_player_map(Player, MapData2),
    StateData2 = set_state_player(StateData, Player2),
    StateData2;
do_protocol_handler(5012, {_MapId, UserId}, StateData) -> %
    Player = get_state_player(StateData),
    MapData = get_player_map(Player),
    MapData2 = del_real_map(MapData, UserId),
    ?FOG(StateData, "~p is left", [UserId]),
    Player2 = set_player_map(Player, MapData2),
    StateData2 = set_state_player(StateData, Player2),
    StateData2;
do_protocol_handler(5022, {UserId, X, Y}, StateData) -> %
    Player = get_state_player(StateData),
    MapData = get_player_map(Player),
    {MapData2, OldX, OldY} = set_real_map(MapData, UserId, X, Y),
    ?FOG(StateData, "~p is moving (~p, ~p) -> (~p, ~p)", [UserId, OldX, OldY, X, Y]),
    Player2 = set_player_map(Player, MapData2),
    StateData2 = set_state_player(StateData, Player2),
    StateData2;
do_protocol_handler(5030, _, StateData) -> %
    StateData;
do_protocol_handler(5204, _, StateData) -> %
    StateData;
do_protocol_handler(11610, _, StateData) -> %
    StateData;
do_protocol_handler(38002, _, StateData) -> %
    StateData;
do_protocol_handler(14002, _, StateData) -> %
    StateData;
do_protocol_handler(12108, _, StateData) -> %
    StateData;
do_protocol_handler(1202, _, StateData) -> %
    StateData;
do_protocol_handler(1410, {SysId}, StateData) -> %
    set_player_sys_id(StateData, SysId);
do_protocol_handler(1130, _, StateData) -> %
    StateData;
do_protocol_handler(1300, _, StateData) -> % 防沉迷通知
    StateData;
do_protocol_handler(1998, {_Time}, StateData) -> % 时间同步协议
%%     set_player_time(StateData, Time);
    StateData;
do_protocol_handler(5098, {UserId, State}, StateData) -> %
    Player  = get_state_player(StateData),
    UserId2 = get_player_user_id(Player),
    Player2 = 
        if
            UserId =:= UserId2 ->
                ?FOG(StateData, "state=~w", [State]),
                set_player_user_state(Player, State);
            true ->
                Player
        end,
    set_state_player(StateData, Player2);
do_protocol_handler(13002, {CopyId, MonId, Wave, PlotId}, StateData) -> % 副本怪物信息
    ?FOG(StateData, "copy is entered~ncopy_id=~w, mon_id=~w, wave=~w, plot_id=~w", [CopyId, MonId, Wave, PlotId]),
    CopyCur = record_copy_cur(CopyId, MonId, Wave, PlotId),
    update_copy_cur(StateData, CopyCur);
do_protocol_handler(13008, {_List1, _List2}, StateData) -> %
    StateData;
do_protocol_handler(14040, _, StateData) -> %
    StateData;
do_protocol_handler(11600, _, StateData) -> %
    StateData;
do_protocol_handler(13012, _, StateData) -> %
    StateData;
do_protocol_handler(4122, _, StateData) -> %
    StateData;
do_protocol_handler(5010, _, StateData) -> %
    StateData;
do_protocol_handler(4008, _, StateData) -> %
    StateData;
do_protocol_handler(8006, _, StateData) -> % 系统消息
    StateData;
do_protocol_handler(26200, _, StateData) -> %
    StateData;
do_protocol_handler(12202, _, StateData) -> %
    StateData;
do_protocol_handler(16008, _, StateData) -> %
    StateData;
do_protocol_handler(13008, _, StateData) -> %
    StateData;
do_protocol_handler(13010, _, StateData) -> %
    StateData;
do_protocol_handler(20010, {TaskId, State, Count, Time, List}, StateData) -> % 返回任务信息
    Task = record_task(TaskId, State, Count, Time, List),
    AccId = StateData#state.acc_id,
    show(AccId, task),
    set_player_task(StateData, Task);
do_protocol_handler(20050, {TaskId, Reason}, StateData) -> % 删除任务
    remove_task(StateData, TaskId, Reason);
do_protocol_handler(20060, {_Count}, StateData) -> % 日常任务次数
    StateData;
do_protocol_handler(25200, {MsgId}, StateData) -> %
    BinMsg = id2msg(MsgId),
    err_msg(StateData, BinMsg),
    StateData;
do_protocol_handler(25300, _, StateData) -> %
    StateData;
do_protocol_handler(26210, _, StateData) -> %
    StateData;
do_protocol_handler(32002, _, StateData) -> %
    StateData;
do_protocol_handler(Cmd, Data, StateData) ->
    err_msg(StateData, io_lib:format("~w:~w", [Cmd, Data])),
    StateData.

%%=======================================================================================
id2msg(13011) -> <<"already in copy">>;
id2msg(20002) -> <<"no this task">>;
id2msg(20005) -> <<"task not finished">>;
id2msg(20014) -> <<"task accept ok">>;
id2msg(20015) -> <<"task finish ok">>;
id2msg(MsgId) -> io_lib:format("~w", [MsgId]).

%%=======================================================================================
bin2record(BinData, player) ->
     <<
      UserId:32,
      ServId:16,
      _State:8,
      Vip:8,
      LenUserBin:16,
      UserName:LenUserBin/binary,
      Pro:8,
      Sex:8,
      MapId:16,
      X:16,
      Y:16,
      _Country:8,
      GuildId:16,
      LenGuildName:16,
      GuildName:LenGuildName/binary,
      GuildPos:8,
      Lv:8,
      Exp:32,
      ExpN:32,
      _Hp:32,
      Sp:32,
      _SpTemp:32,
      Honour:32,
      Meritorious:32,
      Exploit:32,
      SkillPoint:32,
      Power:32,
      _Anger:8,
      Position:16,
      _EffectWeapon:16,
      _SkinWeapon:32,
      _SkinArmor:32,
      _SkinRide:32,
      Cash:32,
      CashBind:32,
      Gold:32,
      GoldBind:32,
      % group_attr
      Force:32,
      Fate:32,
      Magic:32,
      HpMax:32,
      Speed:32,
      ForceAttack:32,
      MagicAttack:32,
      ForceDef:32,
      MagicDef:32,
      Hit:32,
      Dodge:32,
      Crit:32,
      Parry:32,
      Resist:32,
      Unique:32,
      Shadow:32,
      Tough:32,
      Crack:32,
      Gaze:32,
      Luck:32,
      Sexy:32,
      Fatal:32,
      Idea:32,
      
      Spirit:32,
      TrainForce:32,
      TrainFate:32,
      TrainMagic:32,
      TrainForceAll:32,
      TrainFateAll:32,
      TrainMagicAll:32,
      Title:16,
      Experience:32,
      Cultivation:32,
      _Tail/binary
      >> = BinData,
     Info   = record_info(Lv, Exp, ExpN, Cultivation, Honour, Meritorious, UserName, 
                         Position, Power, Pro, Sex, SkillPoint, Sp, Spirit, Title, Vip, Experience),
     Guild  = record_guild(GuildId, GuildName, GuildPos, Exploit),
     Map    = record_map(MapId, X, Y),
     Money  = record_money(CashBind, GoldBind, Cash, Gold),
     Attr   = record_attr(Crack, Crit, Dodge, Fatal, Fate, Force, ForceAttack, Gaze, Hit, 
                         HpMax, Idea, Luck, Magic, MagicAttack, Parry, Resist, Sexy, Shadow, 
                         Speed, Tough, Unique, ForceDef, MagicDef),
     Train  = record_train(TrainFate, TrainFateAll, TrainForce, TrainForceAll, TrainMagic, TrainMagicAll),
     Player = record_player(?ACC_ID, Guild, Info, Money, ServId, UserId, Attr, Map, Train),
     insert_player(Player),
     Player.

%%==================================================================================================
record_info(Lv, Exp, ExpN, Cultivation, Honour, Meritorious, UserName, Position,
            Power, Pro, Sex, SkillPoint, Sp, Spirit, Title, Vip, Experience) ->
    #info{
           lv = Lv, exp = Exp, expn = ExpN, cultivation = Cultivation, honour = Honour,
           meritorious = Meritorious, name = UserName, position = Position, 
           power = Power, pro = Pro, sex = Sex, skill_point = SkillPoint, 
           sp = Sp, spirit = Spirit, title = Title, vip = Vip,
           experience = Experience
         }.
record_attr(Crack, Crit, Dodge, Fatal, Fate, Force, ForceAttack, Gaze, Hit,
            HpMax, Idea, Luck, Magic, MagicAttack, Parry, Resist, Sexy, Shadow,
            Speed, Tough, Unique, ForceDef, MagicDef) ->
    #attr{
           crack = Crack, crit = Crit, dodge = Dodge, fatal = Fatal, fate = Fate,
           force = Force, force_atk = ForceAttack, gaze = Gaze, hit = Hit,
           hp_max = HpMax, idea = Idea, luck = Luck, magic = Magic, magic_atk = MagicAttack,
           parry = Parry, resist = Resist, sexy = Sexy, shadow = Shadow, 
           speed = Speed, tough = Tough, unique = Unique, force_def = ForceDef,
           magic_def = MagicDef 
         }.
record_player(Account, Guild, Info, Money, ServId, UserId, Attr, Map, Train) ->
    #player{
             account = Account, guild   = Guild,  info    = Info,  
             money   = Money,   serv_id = ServId, user_id = UserId,
             attr    = Attr,    map     = Map,    train   = Train
            }.
record_train(TrainFate, TrainFateAll, TrainForce, TrainForceAll, TrainMagic, TrainMagicAll) ->
    #train{
            fate = TrainFate, fate_all = TrainFateAll,
            force = TrainForce, force_all = TrainForceAll,
            magic = TrainMagic, magic_all = TrainMagicAll
           }.
record_money(CashBind, GoldBind, Cash, Gold) -> 
    #money{bcash = CashBind, bgold = GoldBind, cash = Cash, gold = Gold}.
record_map(MapId, X, Y) ->
    #map{map_id = MapId, x = X, y = Y}.
record_guild(GuildId, GuildName, GuildPos, Exploit) ->
    #guild{exploit = Exploit, id = GuildId, name = GuildName, pos = GuildPos}.
record_task(TaskId, State, Count, Time, List) ->
    #task{id = TaskId, count = Count, state = State, time = Time, target_list = List}.
record_copy_cur(CopyId, MonId, Wave, PlotId) ->
    #copy_cur{id = CopyId, mon_id = MonId, plot_id = PlotId, wave = Wave}.
%%=====================================format show=============================================================
format_show_state(StateData) ->
    Player = get_state_player(StateData),
    State  = StateData#state.state,
    Info   = get_player_info(Player),
    Task   = get_player_task(Player),
    Map    = get_player_map(Player),
    Guild  = get_player_guild(Player),
    Money  = get_player_money(Player),
    Attr   = get_player_attr(Player),
    Train  = get_player_train(Player),
    ?FOG(StateData, 
         "======================================================================================~n"
         ++ "State=~w~nInfo=~w~nTask=~w~nmap=~w~nguild=~w~nmoney=~w~nattr=~w~ntrain=~w~n"
         ++ "======================================================================================", 
         [State, Info, Task, Map, Guild, Money, Attr, Train]).

format_show_info(StateData) ->
    Player = get_state_player(StateData),
    Info   = get_player_info(Player),
    Culti = Info#info.cultivation,
    Exp = Info#info.exp,
    Experience = Info#info.experience,
    ExpN = Info#info.expn,
    Honour = Info#info.honour,
    Lv = Info#info.lv,
    Meritorious = Info#info.meritorious,
    Name = Info#info.name,
    Position = Info#info.position,
    Power = Info#info.power,
    Pro = Info#info.pro,
    Sex = Info#info.sex,
    Vip = player_api:get_vip_lv(Info),
    Title = Info#info.title,
    SysId = Info#info.sys_id,
    Spirit = Info#info.spirit,
    Sp = Info#info.sp,
    SkillPoint = Info#info.skill_point,
    ?FOG(StateData, "===================================info===================================================~n"
             ++"culti=~w\texp=~w\texpn=~w\t~nexperience=~w\thonour=~w\tlv=~w\tmeritorious=~w~n"
             ++"name=~s\tposition=~w\tpower=~w\tpro=~w~nsex=~w\tvip=~w\ttitle=~w\tsys_id=~w\t"
             ++"spirit=~w\tsp=~w\tskill_point=~w~n"
             ++"==========================================================================================", 
         [Culti, Exp, ExpN, Experience, Honour, Lv, Meritorious,
          Name, Position, Power, Pro, Sex, Vip, Title, SysId,
          Spirit, Sp, SkillPoint]).   

format_show_guild(StateData) ->
    Player = get_state_player(StateData),
    Guild  = get_player_guild(Player),
    GuildId = Guild#guild.id,
    Name = Guild#guild.name,
    Pos = Guild#guild.pos,
    Exploit = Guild#guild.exploit,
    ?FOG(StateData, "===================================guild==================================================~n"
             ++"guild_id=~w\tguild_name=~w\tguild_pos=~w\tguild_exploit=~w~n"
             ++"==========================================================================================", 
         [GuildId, Name, Pos, Exploit]).   

format_show_money(StateData) ->
    Player = get_state_player(StateData),
    Money  = get_player_money(Player),
    BCash  = Money#money.bcash,
    Cash   = Money#money.cash,
    BGold  = Money#money.bgold,
    Gold   = Money#money.gold,
    ?FOG(StateData, "===================================money==================================================~n"
             ++"bcash=~w\tcash=~w\tbgold=~w\tgold=~w~n"
             ++"==========================================================================================", 
         [BCash, Cash, BGold, Gold]).   

format_show_attr(StateData) ->
    Player = get_state_player(StateData),
    Attr   = get_player_attr(Player),
    Crack  = Attr#attr.crack,  Crit  = Attr#attr.crit,
    Dodge  = Attr#attr.dodge,  Fatal = Attr#attr.fatal,
    Fate   = Attr#attr.fate,   Force = Attr#attr.force,
    ForceDef = Attr#attr.force_def, ForceAtk = Attr#attr.force_atk,
    Hit    = Attr#attr.hit,    Gaze  = Attr#attr.gaze,
    HpMax  = Attr#attr.hp_max, Idea  = Attr#attr.idea,
    Magic  = Attr#attr.magic,  Luck  = Attr#attr.luck,
    MagicAtk = Attr#attr.magic_atk, MagicDef = Attr#attr.magic_def,
    Resist = Attr#attr.resist, Parry = Attr#attr.parry,
    Sexy   = Attr#attr.sexy,  Shadow = Attr#attr.shadow,
    Tough  = Attr#attr.tough,  Speed = Attr#attr.speed,
    Unique = Attr#attr.unique,
    ?FOG(StateData, "===================================attr==================================================~n"
             ++"crack=~w\tcrit=~w\tdodge=~w\tfatal=~w\tfate=~w\t~n"
             ++"force=~w\tforce_def=~w\tforce_atk=~w\thit=~w\tgaze=~w\t~n"
             ++"hp_max=~w\tidea=~w\tmagic=~w\tluck=~w\tmagic_atk=~w\t~n"
             ++"magic_def=~w\tresist=~w\tparry=~w\tsexy=~w\tshadow=~w\t~n"
             ++"tough=~w\tspeed=~w\tunique=~w~n"
             ++"==========================================================================================", 
         [Crack, Crit, Dodge, Fatal, Fate, Force, ForceDef, ForceAtk,
          Hit, Gaze, HpMax, Idea, Magic, Luck, MagicAtk, MagicDef,
          Resist, Parry, Sexy, Shadow, Tough, Speed, Unique]).   

format_show_task(StateData) ->
    Player = get_state_player(StateData),
    Task   = get_player_task(Player),
    ?FOG(StateData, "===================================task===================================================", []),
    F = fun(#task{id=TaskId, state=TaskState, count=TaskCount, target_list=TaskTargetList, time=TaskTime}) ->
                TaskState2 = 
                    case TaskState of
                        1 -> <<"hidden">>;
                        2 -> <<"acceptable">>;
                        3 -> <<"\"not finished\"">>;
                        4 -> <<"\"not delived\"">>;
                        5 -> <<"delived">>;
                        _ -> <<"unknown">>
                    end,
                ?FOG(StateData, "id=~w\tstate=~s\tcount=~w\ttime=~w", [TaskId, TaskState2, TaskCount, TaskTime]),
                F2 = fun(#target_list{idx=Idx, ad1=Ad1, ad2=Ad2, ad3=Ad3, ad4=Ad4, ad5=Ad5}) ->
                             ?FOG(StateData, "idx=~w\tad1=~w\tad2=~w\tad3=~w\tad4=~w\tad5=~w", [Idx, Ad1, Ad2, Ad3, Ad4, Ad5]);
                        (_) ->
                             ok
                     end,
                lists:foreach(F2, TaskTargetList);
           (_) ->
                ok
        end,
    lists:foreach(F, Task),
    ?FOG(StateData, "==========================================================================================~n", []).

-define(IGNORE_Y, 400).
-define(Y_PER_POINT, 25).
-define(X_PER_POINT, 60).
-define(X_PER_LINE, round(2000/?X_PER_POINT + 1)).
-define(TOTAL_POINT, round(400/?Y_PER_POINT * ?X_PER_LINE)).
format_show_real_map(StateData) ->
    Player = get_state_player(StateData),
    Info = get_player_info(Player),
    Sex = Info#info.sex,
    MapData = get_player_map(Player),
    RealMap = get_real_map(MapData),
    EmptyTuple = erlang:make_tuple(?TOTAL_POINT, z),
    F = fun(#real_map{x = X, y = Y, sex = 1}, OldTuple) ->
                Idx = (((Y - ?IGNORE_Y) div ?Y_PER_POINT) - 1) * ?X_PER_LINE + X div ?X_PER_POINT,
                change_mod(OldTuple, Idx, x);
           (#real_map{x = X, y = Y, sex = 2}, OldTuple) ->
                Idx = (((Y - ?IGNORE_Y) div ?Y_PER_POINT) - 1) * ?X_PER_LINE + X div ?X_PER_POINT,
                change_mod(OldTuple, Idx, o)
        end,
    NewTuple = 
        if
            0 =/= MapData#map.x andalso undefined =/= MapData#map.x ->
                RealMapSelf = #real_map{x = MapData#map.x, y = MapData#map.y, sex = Sex},
                lists:foldl(F, EmptyTuple, [RealMapSelf|RealMap]);
            true ->
                lists:foldl(F, EmptyTuple, RealMap)
        end,
    List = erlang:tuple_to_list(NewTuple),
    ?FOG(StateData, "===================================map====================================================", []),
    split_show(List, StateData),
    ?FOG(StateData, "==========================================================================================~n", []).

split_show(List, StateData) when [] =/= List ->
    {List2, ListTail} = lists:split(?X_PER_LINE, List),
    ?FOG(StateData, "~p", [List2]),
    split_show(ListTail, StateData);
split_show([], _StateData) -> ok.

change_mod(Tuple, Idx, Sig) ->
    case erlang:element(Idx, Tuple) of
        z ->
            erlang:setelement(Idx, Tuple, Sig);
        X when is_number(X) ->
            erlang:setelement(Idx, Tuple, X+1);
        _ ->
            erlang:setelement(Idx, Tuple, 2)
    end.
    
%%==========================================logical========================================================
%% 移除任务
remove_task(StateData, TaskId, Reason) ->
    Player = get_state_player(StateData),
    Task = get_player_task(Player),
    Task3 = 
        case lists:keytake(TaskId, #task.id, Task) of
            {value, RecTask, Task2} ->
                ?FOG(StateData, "task=~w is deleted, reason=~w", [RecTask, Reason]),
                Task2;
            false ->
                err_msg(StateData, "the task is not accepted"),
                Task
        end,
    set_player_task(StateData, Task3).

update_copy_cur(StateData, CopyCur) ->
    Player  = get_state_player(StateData),
    Player2 = set_copy_cur(Player, CopyCur),
    set_state_player(StateData, Player2).
%%=========================================what i want=========================================================
    
%%=======================================================================================

%% --------------------------------------------------------------------
%%% 工具
%% --------------------------------------------------------------------
pack(StateData, Cmd, Body) ->
    Len    = get_len(Body),
    Sn     = get_state_sn(StateData),
    StateData2 = upgrade_state_sn(StateData),
    AppKey = get_socket_app_key(StateData),
    Sing   = calc_sing(Body, AppKey),
    {StateData2, <<Len:16/big-integer-unsigned, Sn:8/big-integer-unsigned, Sing:8/binary, Cmd:16/big-integer-unsigned, Body/binary>>}.
%%     P      = <<Len:16/big-integer-unsigned, Sn:8/big-integer-unsigned, Sing:8/binary, Cmd:16/big-integer-unsigned, Body/binary>>,
%%     io:format("kkkkkk[~p|~p|~p]~n", [AppKey, Sing, P]),
%%     {StateData2, P}.

calc_sing(Body, AppKey) ->
    erlang:md5(erlang:binary_to_list(Body) ++ AppKey).

get_len(BitString) when is_binary(BitString) ->
    erlang:byte_size(BitString);
get_len(String) when is_list(String) ->
    BitString = erlang:list_to_binary(String),
    erlang:byte_size(BitString);
get_len(Number) when is_number(Number) ->
    BitString = erlang:list_to_binary(integer_to_list(Number)),
    erlang:byte_size(BitString).
	
time_format(Now) -> 
	{{Y,M,D},{H,MM,S}} = calendar:now_to_local_time(Now),
	lists:concat([Y, "-", one_to_two(M), "-", one_to_two(D), " ", 
						one_to_two(H) , ":", one_to_two(MM), ":", one_to_two(S)]).

one_to_two(One) -> io_lib:format("~2..0B", [One]).

write_string(Str) ->
	Bin = to_binary(Str),
    Len = byte_size(Bin),	
	<<Len:16, Bin/binary>>.

read_string(Bin) ->
    case Bin of
        <<Len:16, Bin1/binary>> ->
            case Bin1 of
                <<Str:Len/binary-unit:8, Rest/binary>> ->
                    {binary_to_list(Str), Rest};
                _R1 ->
                    {[],<<>>}
            end;
        _R1 ->
            {[],<<>>}
    end.

%% @doc convert other type to binary
to_binary(Msg) when is_binary(Msg) -> 
    Msg;
to_binary(Msg) when is_atom(Msg) ->
	list_to_binary(atom_to_list(Msg));
	%%atom_to_binary(Msg, utf8);
to_binary(Msg) when is_list(Msg) -> 
	list_to_binary(Msg);
to_binary(Msg) when is_integer(Msg) -> 
	list_to_binary(integer_to_list(Msg));
to_binary(Msg) when is_float(Msg) -> 
	list_to_binary(f2s(Msg));
to_binary(_Msg) ->
    throw(other_value).

%% @doc convert float to string,  f2s(1.5678) -> 1.57
f2s(N) when is_integer(N) ->
    integer_to_list(N) ++ ".00";
f2s(F) when is_float(F) ->
    [A] = io_lib:format("~.2f", [F]),
	A.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   休息T(ms)时间
%% @param  T 微秒数
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sleep(T) ->
    receive
    after T -> ok
    end.

get_now() ->
	calendar:now_to_local_time(erlang:now()).

%% 二进制转16进制
bin_to_hex(Bin) ->
    List = binary_to_list(Bin),
    lists:flatten(list_to_hex(List)).
list_to_hex(L) -> 
    lists:map(fun(X) -> int_to_hex(X) end, L).
int_to_hex(N) when N < 256 ->
    [hex(N div 16), hex(N rem 16)]. 
hex(N) when N < 10 -> 
    $0 + N;
hex(N) when N >= 10, N < 16 ->
    $a + (N-10).

hex_to_list(<<$":8, Tail/binary>>, List) -> hex_to_list(Tail, List);
hex_to_list(<<X,Y,Tail/binary>>, List) ->
    XX = hex_to_list(X),
    YY = hex_to_list(Y),
    ZZ = [16*XX+YY],
    List2 = [ZZ|List],
    hex_to_list(Tail, List2);
hex_to_list(<<>>, List) -> lists:reverse(List).
hex_to_list(N) when $0 =< N andalso N =< $9 ->
    N - $0;
hex_to_list(N) when $a =< N andalso N =< $z ->
    N - $a + 10;
hex_to_list(N) when $A =< N andalso N =< $Z ->
    N - $A + 10;
hex_to_list(X) ->
    io:format("[~p]key[~p]~n", [?LINE, X]),
    X.

decrypt_app_key(RootKey, AppKey) ->
    K  = hex_to_list(AppKey, []),
    K2 = erlang:binary_to_list(crypto:des_ecb_decrypt(RootKey, K)),
    K3 = [[X]||X<-K2],
    K3.