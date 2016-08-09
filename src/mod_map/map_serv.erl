%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-7-14
%%% -------------------------------------------------------------------
-module(map_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.player.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/5]).
-export([enter_map_cast/5, exit_map_cast/3, move_cast/4, request_for_cb/2, 
		 broadcast_cast/2, broadcast_range_cast/3, enter_map_force/3,
         team_exit/1, faction_init_boss/2, clean_map_cast/1, mcopy_battle_over/7,
         start_q/1, invasion_progress/1, invasion_robot/2, invasion_close/2,
		 invasion_mon_battle_start/4, invasion_battle_over/9, update_task/3,
		 start_mcopy_battle/1, get_user_id_list/1, kick_all_cast/1
		]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {map_pid, map_id, map_type, map_param, handler, data}).
%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores, MapId, MapType, Param) ->% 地图进程
	misc_app:gen_server_start_link(?MODULE, [MapId, MapType, Param]).
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
init([MapId, MapType, Param]) ->% 地图进程
    Self = self(),
    % 随机数种子
    ?RANDOM_SEED,
%%     map_mod:regist_map_name(MapId, MapType, Self, Param),    
	case map_mod:init(MapId, MapType, Param) of
		{?ok, Handler, Data} ->
			?MSG_PRINT(" Server Start On Core:~p", [erlang:system_info(scheduler_id)]),
			{?ok, #state{map_pid = Self, map_id = MapId, map_type = MapType, map_param = Param,
						 handler = Handler, data = Data}};
		{?error, ErrorCode} ->
			?MSG_ERROR("ErrorCode:~p, Strace:~p~n", [ErrorCode, erlang:get_stacktrace()]),
			{?stop, {?error, ErrorCode}}
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
handle_call(Request, From, State) ->
    try do_call(Request, From, State) of
		{?reply, Reply, State2} -> {?reply, Reply, State2}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?reply, {?error, ?TIP_COMMON_BAD_ARG}, State}
	end.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, State) ->
	try do_cast(Msg, State) of
		{?noreply, State2} -> {?noreply, State2};
        {?stop, Reason, State3} -> {?stop, Reason, State3}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State}
	end.
    

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_info(Info, State) ->
	try do_info(Info, State) of
		{?noreply, State2} -> {?noreply, State2};
        {?stop, Reason, State3} -> {?stop, Reason, State3}
	catch Error:Reason ->
			  ?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			  {?noreply, State}
	end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(?normal, #state{map_id = MapId, map_pid = MapPid}) ->
    ets:delete(?CONST_ETS_MAP, MapPid),
    Self = self(),
    ?MSG_DEBUG("map[map_id=~p, map_pid=~p|~p] is killed...", [MapId, MapPid, Self]),
    ?ok;
terminate(Reason, State) ->
	?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]),
    ?ok.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
do_call({start_mcopy_battle}, _From, State) ->
	Reply 	= State#state.data,
    {?reply, Reply, State};
do_call(get_user_id_list, _From, State) ->
    Reply = erlang:get(user_id_list),
    {?reply, Reply, State};
do_call(Request, _From, State) ->
	Reply = ?ok,
	?MSG_ERROR("Request:~p   State:~p", [Request, State]),
    {?reply, Reply, State}.

do_cast({move, UserId, Packet, MType}, State) ->
	MapId			= State#state.map_id,
	map_mod:do_move(UserId, Packet, MType, MapId),
	{?noreply, State};
do_cast({enter_map, UserIdList, _MapId, X, Y}, State) ->%% 角色进入地图
	map_mod:do_enter_map(UserIdList, State#state.map_pid, State#state.map_id, X, Y, State#state.map_type, State#state.map_param),
	NewState =
		case State#state.map_type of
			?CONST_MAP_TYPE_MCOPY ->
				Times = (State#state.map_param)#map_param.ad4,
				Data  = mcopy_api:start_mcopy(State#state.data, State#state.map_pid, State#state.map_id, Times),
				State#state{data = Data};
			?CONST_MAP_TYPE_GUARD ->
				invasion_api:switch(State#state.map_id),
				State;
			_ ->
				State
		end,
    {?noreply, NewState};
do_cast({exit_map, UserId, MType}, State) ->
	map_mod:do_exit_map(UserId, State#state.map_pid, State#state.map_id, State#state.map_type, State#state.map_param, MType),
	{?noreply, State};
do_cast({broadcast, Packet}, State) ->
	map_mod:do_broadcast(Packet),
	{?noreply, State};
do_cast({broadcast_range, UserId, Packet}, State) ->
	map_mod:do_broadcast_range(UserId, Packet),
	{?noreply, State};
do_cast({enter_map_force, UserList, MapPid, MapId}, State) ->
    map_mod:do_enter_map_force(UserList, MapPid, MapId),
    {?noreply, State};
do_cast(team_exit, State) ->
    map_mod:do_team_exit(),
    {?noreply, State};
do_cast({faction_init_boss, MonsterId}, State) ->
    faction_api:init_boss_cb(MonsterId),
    {?noreply, State};
do_cast(clean_map, State) ->
    case map_api:clean_maps_cb(State#state.map_type) of
        ?stop ->
            {?stop, ?normal, State};
        _ ->
            {?noreply, State}
    end;
do_cast({mcopy_battle_over, UserId, UniqueId, AtkPoint, DefPoint, TeamId, RobotList}, State) ->
    MapPid		= State#state.map_pid,
    Data 		= State#state.data,
	MapParam	= State#state.map_param,
    MapData 	= mcopy_api:mcopy_battle_over(UserId, UniqueId, MapPid, Data, MapParam, AtkPoint, DefPoint, TeamId, RobotList),
    {?noreply, State#state{data = MapData}};
do_cast({start_q, Player, MapPid}, State) ->
    {?ok, _, MapData }= mcopy_api:start_q_cb(Player, State#state.data, MapPid),
    {?noreply, State#state{data = MapData}};
do_cast({invasion_progress}, State) ->
	invasion_api:progress(),
	{?noreply, State};
do_cast({invasion_robot, TeamId}, State) ->
	invasion_api:robot_exec(TeamId),
	{?noreply, State};
do_cast({invasion_close, TeamId}, State) ->
	invasion_api:close(TeamId),
	{?noreply, State};

do_cast({request_for_cb, {Mod, Func, Param}}, State) ->
    Mod:Func(Param),
    {?noreply, State};

do_cast({invasion_mon_battle_start, TeamId, UniqueId, UserId}, State) ->
	invasion_api:mon_battle_start(TeamId, UniqueId, UserId),
	{?noreply, State};
do_cast({invasion_battle_over, Result, UserId, BattleType, UniqueId, TeamId, RightUnits, HurtLeft, HurtRight}, State) ->
	invasion_mod:battle_over(Result, UserId, BattleType, UniqueId, TeamId, RightUnits, HurtLeft, HurtRight),
	{?noreply, State};
do_cast({update_task, Type, Id}, State) ->
	map_api:do_update_task(Type, Id),
	{?noreply, State};
do_cast(kick_all, State) ->
	map_mod:kick_all(),
	{?noreply, State};
do_cast(Msg, State) ->
	?MSG_ERROR("Msg:~p   State:~p", [Msg, State]),
	{?noreply, State}.

do_info({exec, Mod, Fun, Arg}, State) ->
    Mod:Fun(State, Arg),
    {?noreply, State};
do_info(Info, State) ->
	?MSG_ERROR("Info:~p   State:~p", [Info, State]),
    {?noreply, State}.

%% 角色进入地图(MapPid, UserIdList)
enter_map_cast(MapPid, UserIdList, MapId, X, Y) ->
    case MapPid of
        {Pid, Node} ->
            rpc:cast(Node, gen_server, cast, [Pid, {enter_map, UserIdList, MapId, X, Y}]);
        _ ->
	        gen_server:cast(MapPid, {enter_map, UserIdList, MapId, X, Y})
    end.

%% 角色离开地图
exit_map_cast(MapPid, UserId, MType) ->
	misc_app:cast(MapPid, {exit_map, UserId, MType}).

%% 角色移动
move_cast(MapPid, UserId, Packet, MType) ->
	misc_app:cast(MapPid, {move, UserId, Packet, MType}).

%% 地图广播
broadcast_cast(MapPid, Packet) ->
	misc_app:cast(MapPid, {broadcast, Packet}).
%% 地图可视区域广播
broadcast_range_cast(MapPid, UserId, Packet) ->
	misc_app:cast(MapPid, {broadcast_range, UserId, Packet}).

%% 强制进入地图
enter_map_force(MapPid, UserList, MapId) ->
    misc_app:cast(MapPid, {enter_map_force, UserList, MapPid, MapId}).

%% 队伍离开地图
team_exit(MapPid) ->
    misc_app:cast(MapPid, team_exit).

%% 初始化将领
faction_init_boss(MapPid, MonsterId) ->
    misc_app:cast(MapPid, {faction_init_boss, MonsterId}).

%% 清地图
clean_map_cast(MapPid) ->
    misc_app:cast(MapPid, clean_map).

%% 移除怪物
mcopy_battle_over(MapPid, UserId, UniqueId, AtkPoint, DefPoint, TeamId, RobotList) ->
    misc_app:cast(MapPid, {mcopy_battle_over, UserId, UniqueId, AtkPoint, DefPoint, TeamId, RobotList}).

start_mcopy_battle(Player) ->
	MapPid 	= Player#player.map_pid,
	gen_server:call(MapPid, {start_mcopy_battle}).

%% 开始奇遇
start_q(Player) ->
    MapPid = Player#player.map_pid,
    misc_app:cast(MapPid, {start_q, Player, MapPid}).

invasion_progress(MapPid) ->
	gen_server:cast(MapPid, {invasion_progress}).

invasion_robot(MapPid, TeamId) ->
	gen_server:cast(MapPid, {invasion_robot, TeamId}).

invasion_close(MapPid, TeamId) ->
	gen_server:cast(MapPid, {invasion_close, TeamId}).

%% 请求在地图进程中调用方法
request_for_cb(MapPid, {Mod, Func, Param}) ->
    gen_server:cast(MapPid, {request_for_cb, {Mod, Func, Param}}).


invasion_mon_battle_start({MapPid,_}, TeamId, UniqueId, UserId) ->
    gen_server:cast(MapPid, {invasion_mon_battle_start, TeamId, UniqueId, UserId});
invasion_mon_battle_start(MapPid, TeamId, UniqueId, UserId) ->
	gen_server:cast(MapPid, {invasion_mon_battle_start, TeamId, UniqueId, UserId}).

invasion_battle_over(Result, UserId, BattleType, UniqueId, {MapPid, _}, TeamId, RightUnits, HurtLeft, HurtRight) ->
    gen_server:cast(MapPid, {invasion_battle_over, Result, UserId, BattleType, UniqueId, TeamId, RightUnits, HurtLeft, HurtRight});

invasion_battle_over(Result, UserId, BattleType, UniqueId, MapPid, TeamId, RightUnits, HurtLeft, HurtRight) ->
	gen_server:cast(MapPid, {invasion_battle_over, Result, UserId, BattleType, UniqueId, TeamId, RightUnits, HurtLeft, HurtRight}).

%% 更新活动
update_task(MapPid, Type, Id) ->
    misc_app:cast(MapPid, {update_task, Type, Id}).

%% 更新活动
get_user_id_list(MapPid) ->
    misc_app:cast(MapPid, get_user_id_list).

%% kick
kick_all_cast(MapPid) ->
    misc_app:cast(MapPid, kick_all).