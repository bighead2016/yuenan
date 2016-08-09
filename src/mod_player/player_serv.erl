%%% -------------------------------------------------------------------
%%% Author  : cobain
%%% Description :
%%%
%%% Created : 2012-7-6
%%% -------------------------------------------------------------------
-module(player_serv).

-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("../../include/const.define.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.cost.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/11]).
-export([process_send/4, process_call/4]).
-export([create_call/3, reconnect_call/2, db_write_cast/1, update_netpid_cast/2]).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([
         update_team_pid/2, add_equip/3, user_logout/1, user_ban/2, user_unban/1, user_state/1,
         user_chat_ban/2, user_chat_unban/1, guild_party_end/1, force2offline/2, set_viplv/2,
         far_conn_call/2, return_city/1
        ]).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores, NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist) ->
%% 	gen_server:start_link(?MODULE,
%% 						  [NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist],
%% 						  [{spawn_opt,[{fullsweep_after, 1000}]}]).
    misc_app:gen_server_start_link(?MODULE, [NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist]).

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
init([NetPid, UserId, ServId, ServUniqueId, State, LoginTime, Ip, Account, Exist]) ->
	process_flag(trap_exit, ?true),
	% 随机数种子
	?RANDOM_SEED,
    Player  = #player{
                      user_id			= UserId,       				% [first]玩家ID
                      serv_id			= ServId,       				% [Temp]服务器ID
                      serv_unique_id	= ServUniqueId, 				% [Temp]服务器唯一ID
                      net_pid			= NetPid,       				% [Temp]玩家Net进程ID
                      ip				= Ip,			 				% [Temp]玩家登录IP
					  account			= Account,		 				% [Temp]玩家平台帐号
					  battle_pid		= 0,            				% [Temp]玩家战斗进程ID
                      state				= State,        				% [Temp]状态  0：封号|1:普通玩家|2：指导员|3：GM
                      user_state		= ?CONST_PLAYER_STATE_NORMAL,	% [Temp] 玩家状态
                      play_state		= ?CONST_PLAYER_PLAY_CITY,
                      practice_state    = ?CONST_PLAYER_STATE_NORMAL,   % [Temp] 
                      time_login		= LoginTime    		 		    % [Temp]登录时间
                     },
	try
		{?ok, Player2}		= player_login_api:login_init_data(Player, Exist),
		case player_login_api:login_init(Player2, Exist) of
			{?ok, Player3} ->% 初始化其他系统
				% 统计--角色登陆
				?MSG_DEBUG("INFO:~p", [Player3#player.info]),
				Player4		= admin_log_api:log_login(Player3, Exist),
				player_db_mod:log_in_out(Player4, ?CONST_PLAYER_LOG_TYPE_LOGIN, LoginTime),
				PlayerName	= misc_app:player_name(UserId),
				?true       = is_atom(PlayerName),
				?ok   	    = player_mod:register_player_pid(PlayerName, self()),
				?true       = is_record(Player4, player),
				?true       = player_login_api:login_ets(Player4),
				{?ok, Player5} = player_offline_api:flush_offline(Player4, Exist),% 刷离线数据
				yunying_activity_mod:stone_compose_mail(Player4), % 宝石合成，过期礼包
				player_api:sp_offline(Player5); %% 刷完离线数据如扫荡后才加离线体力
			Any ->         
				?MSG_ERROR("~nAny:~p~nStrace:~p~n", [Any, erlang:get_stacktrace()]),
				{?stop, {?error, Any}}
		end
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~nProcessInfo:~p~n",
					   [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
			{?stop, {Error, Reason}}
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
%%获取用户信息(测试用)
handle_call('PLAYER', _From, Player) ->
	put(last_msg, ['PLAYER']),%%监控记录接收到的最后的消息
    {reply, Player, Player};

handle_call(Request, From, Player) ->
    try do_call(Request, From, Player) of
		{?reply, Reply, Player2} -> {?reply, Reply, Player2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
%%            {?noreply, Player}
              {?stop, Reason, Player}
	end.

%% --------------------------------------------------------------------
%% Function: handle_cast/2
%% Description: Handling cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------
handle_cast(Msg, Player) ->
	try do_cast(Msg, Player) of
		{?noreply, Player2} -> {?noreply, Player2};
        {?stop, Reason, Player2} -> {?stop, Reason, Player2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
%% 			  {?noreply, Player}
              Packet = message_api:msg_notice(?TIP_COMMON_SYS_ERR),
              misc_packet:send(Player#player.user_id, Packet),
              {?stop, Reason, Player}
	end.

%% --------------------------------------------------------------------
%% Function: handle_info/2
%% Description: Handling all non call/cast messages
%% Returns: {noreply, State}          |
%%          {noreply, State, Timeout} |
%%          {stop, Reason, State}            (terminate/2 is called)
%% --------------------------------------------------------------------

handle_info(check_old_cash, Player) ->
    case player_db_mod:get_old_cash(Player#player.account) of
        0 ->
            ok;
        Cash1 ->
            Cash = round(Cash1 * 1.2),
            UserId = Player#player.user_id,
            Time = misc:seconds(),
            Id = UserId * 10000000000 + Time,
            case player_money_api:deposit_2(misc:to_list(Id), Player#player.account, UserId, 0, Cash, Time, ?CONST_DEPOSIT_USE_CASH_OLD, ?CONST_COST_PLAYER_DEPOSIT_OLD) of
                ?ok -> 
                    player_money_api:insert_deposit(misc:to_list(Id), Player#player.account, Cash, Time, UserId),
                    Info = Player#player.info,
                    Name = Info#info.user_name,
                    Title = "体验服充值返利",
                    Content = io_lib:format("您在体验服充值了~w元宝，现赠送给您~w元宝。请注意查收",[Cash1, Cash]),
                    mail_api:send_interest_mail_to_one2(Name, Title, Content, 0, [],[], 0, 0, 0, 0);
                {?error, ErrorCode} ->
                    Packet = message_api:msg_notice(ErrorCode),
                    misc_packet:send(Player#player.net_pid, Packet)
            end
    end,
    {?noreply, Player};

handle_info(Info, Player) ->
	try do_info(Info, Player) of
		{?noreply, Player2} -> {?noreply, Player2};
		{?stop, Reason, Player2} ->
			{?stop, Reason, Player2}
	catch Error:Reason ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
						 [Error, Reason, erlang:get_stacktrace(), erlang:process_info(self())]),
              {?stop, Reason, Player}
	end.

%% --------------------------------------------------------------------
%% Function: terminate/2
%% Description: Shutdown the server
%% Returns: any (ignored by gen_server)
%% --------------------------------------------------------------------
terminate(Reason, Player) ->
	try
		LogoutTime 		= misc:seconds(),
		UserId	= Player#player.user_id,
		case Reason of
			?normal -> ?ok;
			{error,socket_timeout}  -> ?ok;
			{error,reconnect_timeout} -> ?ok;
			"kick"  -> ?ok;
			_ -> ?MSG_ERROR("~nSTOP UserId:~p~nReason:~w~nStrace:~p~nProcessInfo:~p~n",
							[UserId, Reason, erlang:get_stacktrace(), erlang:process_info(self())])
		end,
		gateway_mod:del_mini_client(UserId),
		% 玩家退出
		player_db_mod:log_in_out(Player, ?CONST_PLAYER_LOG_TYPE_LOGOUT, LogoutTime),
		Player4	=
			case Player#player.info of
				Info when is_record(Info, info) ->
					% 统计--登出日志
					admin_log_api:log_logout(Player, LogoutTime, Reason),
					NewInfo 		= Info#info{time_last_off = LogoutTime},
					Player2         = Player#player{info = NewInfo},
					{?ok, Player3} 	= player_login_api:logout(Player2),
					player_mod:write_player(Player3, ?CONST_SYS_DB_TYPE_LOGOUT),
					Player3;
				?null -> Player
			end,
		catch yunying_activity_api:logout_activity_online_time(Player4),              %运营活动在线得奖励下线处理
        catch yunying_activity_api:activity_write_db_logout(Player4),                     %运营，双旦活动下线写数据库，和上面的调用不可调换顺序
        catch yunying_activity_mod:card_exchange_partner_write_db_logout(Player4),          %抽卡换武将，玩家下线时处理
        player_api:logout(Player4)                                    % 玩家下线，数据转移
	catch Type:Error ->
			  ?MSG_ERROR("~nError:~p~nReason:~w~nStrace:~p~n", [Type, Error, erlang:get_stacktrace()])
	end.

%% --------------------------------------------------------------------
%% Func: code_change/3
%% Purpose: Convert process state when code is changed
%% Returns: {ok, NewState}
%% --------------------------------------------------------------------
code_change(_OldVsn, Player, _Extra) ->
    {?ok, Player}.

%% --------------------------------------------------------------------
%%% Internal functions
%% --------------------------------------------------------------------
%% 获取人物status(测试用)
do_call('PLAYER', _From, Player) ->
    {?reply, Player, Player};

%% call
do_call({?handler,  MsgId, {UserName, Por, Sex}}, _From, Player) -> % 创建角色
    case player_login_api:create(MsgId, Player, UserName, Por, Sex) of
        {?ok, Player2} ->
			% 统计--创建角色
			Player3		= admin_log_api:log_player_create(Player2),
            misc:send_to_pid(self(), check_old_cash),
			{?reply, ?ok, Player3};
        {?error, ErrorCode} -> {?reply, {?error, ErrorCode}, Player}
    end;
do_call({exec, Mod, Fun, Arg}, _From, Player) ->
	case Mod:Fun(Player, Arg) of
		{?ok, Reply, Player2} ->
			{?reply, Reply, Player2};
        {?ok, Player2} ->
            {?reply, noreply, Player2};
		Any ->
			?MSG_ERROR("Any:~p Strace:~p",[Any, erlang:get_stacktrace()]),
			{?stop, bad_reply, Player}
	end;
do_call({reconnect, NetPid}, _From, Player) ->
	gateway_mod:del_mini_client(Player#player.user_id),
	Player2		= Player#player{net_pid = NetPid, reconnect = ?false},
	{?reply, ?ok, Player2};
do_call({far_conn, FromUserId}, _From, Player) ->
    player_far_conn_api:far_conn_cb(Player#player.user_id, FromUserId),
	{?reply, ?ok, Player};

do_call(Request, _From, Player) ->
    ?MSG_ERROR("Request:~p Strace:~p",[Request, erlang:get_stacktrace()]),
	Reply = ?ok,
    {?reply, Reply, Player}.

%% cast
do_cast({?handler, ModHandler, MsgId, Datas}, Player) -> % 分发处理协议
    UserId = Player#player.user_id,
    ?MSG_DEBUG("recv|~p|~p|~p|~p", [UserId, ModHandler, MsgId, Datas]),
    case switcher:is_opened(ModHandler) of
        ?CONST_SYS_TRUE ->
            case ModHandler:handler(MsgId, Player, Datas) of
                ?ok ->
                    {?noreply, Player};
                ?error ->
                    {?noreply, Player};
                #player{} = Player2 ->
                    {?noreply, Player2};
                {?ok, #player{} = Player2} ->
                    {?noreply, Player2};
                {?error, ErrorCode} ->
                    misc_packet:send_tips(UserId, ErrorCode),
                    {?noreply, Player};
                ?undefined ->
                    ?MSG_ERROR("~p|undefined|~p|~w",[UserId, MsgId, Datas]),
                    {?noreply, Player};
                X ->
                    ?MSG_ERROR("!err:~p", [{X, ModHandler, MsgId, Datas}]),
                    {?noreply, Player}
            end;
        ?CONST_SYS_FALSE ->
            misc_packet:send_tips(UserId, ?TIP_COMMON_NOT_OPENED_HANDLER),
            {?noreply, Player}
    end;
do_cast(db_write, Player) ->% 存储数据库
    case Player#player.equip of
        ?null -> {?noreply, Player};
        _ ->
	        player_mod:write_player(Player, ?CONST_SYS_DB_TYPE_INTERVAL),
            {?noreply, Player}
    end;
do_cast({update_netpid, NetPid}, Player) ->% 更新网络进程
	{?ok, Player2} = player_api:do_when_update_net(Player),
	{?noreply, Player2#player{net_pid = NetPid, user_state = ?CONST_PLAYER_STATE_NORMAL, play_state = ?CONST_PLAYER_PLAY_CITY}};
do_cast(guild_party_end, Player) ->
    {?ok, NewPlayer} 	= task_api:update_active(Player, {?CONST_ACTIVE_TYPE_PARTY, 1}),
	{?noreply, NewPlayer};

%% GM系统
do_cast({admin, [stop, Reason]}, Player) ->
	LogoutTime = misc:seconds(),
    Info 	= Player#player.info,
    NewInfo = Info#info{time_last_off = LogoutTime},
    {?ok, Player2} = player_login_api:logout(Player#player{info = NewInfo}),
    player_mod:write_player(Player2, ?CONST_SYS_DB_TYPE_LOGOUT),
	{stop, Reason, Player2};
do_cast({admin, CmdList}, Player) ->
	{?ok, NewPlayer} = admin_mod:treat_admin_cast(Player, CmdList),
	{?noreply, NewPlayer};
do_cast({off, Msg}, Player) ->
	{?stop, Msg, Player};
do_cast(return_city, Player) ->
    NewPlayer = map_api:return_last_city(Player),
	{?noreply, NewPlayer};

do_cast(Msg, Player) ->
    ?MSG_ERROR("Msg:~p Strace:~p",[Msg, erlang:get_stacktrace()]),
	{?noreply, Player}.

%% info
do_info({exec, Mod, Fun, Arg}, Player) ->
	case Mod:Fun(Player, Arg) of
		{?ok, Player2} ->
			{?noreply, Player2};
        {?true, Player2} ->
            {?noreply, Player2};
		Any ->
			?MSG_ERROR("Any:~p Strace:~p",[Any, erlang:get_stacktrace()]),
			{?stop, bad_reply, Player}
	end;
do_info({set_state, NewState, TimeStamp}, Player) ->
	NewPlayer = player_state_api:set_state(Player, NewState, TimeStamp),
	{?noreply, NewPlayer};
do_info(reconnect_timeout, Player) ->% 闪断重连超时
	case Player#player.reconnect of
		?true -> {?stop, {?error, reconnect_timeout}, Player};
		?false -> {?noreply, Player}
	end;
do_info({'EXIT', NetPid, {?error, ?etimedout}}, Player = #player{net_pid = NetPid}) ->% 网络环境差，要做闪断重连处理
	erlang:send_after(?CONST_TIME_MINUTE_MSEC, self(), reconnect_timeout),
	Player2	= Player#player{reconnect = ?true},
	{?noreply, Player2};
do_info({'EXIT', NetPid, Reason}, Player = #player{net_pid = NetPid}) ->% 玩家网络进程退出
    {?stop, Reason, Player};
do_info({'EXIT', _NetPid, Reason}, Player) -> % 重复登录
    ?MSG_ERROR("UserId:~p Reason:~p", [Player#player.user_id, Reason]),
    {?noreply, Player};
do_info({Ref, Data}, Player) when is_reference(Ref) ->
	?MSG_ERROR("Ref:~p Data:~p Strace:~p~n", [Ref, Data, erlang:get_stacktrace()]),
    {?noreply, Player};
do_info({?ok, _Ref,{mysql_result,_,_,0,_,_}}, Player) ->
	?MSG_ERROR("Strace:~p~n", [erlang:get_stacktrace()]),
    {?noreply, Player};
do_info({yunying_activity_online_start},Player)->        %运营在线得奖励活动开启
	yunying_activity_api:init_activity_online_award(Player),
	{?noreply,Player}; 
do_info({yunying_activity_online_award},Player)->        %到时间发在线得奖励的奖品
	yunying_activity_mod:send_activity_online_award(Player),
	{?noreply,Player}; 
do_info({yunying_activity_online_zero},Player)->       %运营活动在线得奖励零点刷新
	yunying_activity_mod:refresh_activity_online_zero(Player),
	{?noreply,Player};
do_info(Info, Player) ->
	?MSG_ERROR("Info:~p Player:~w",[Info, Player]),
	{?noreply, Player}.

%% 
process_send(PlayerPid, Mod, Fun, Arg) ->
    case misc:send_to_pid(PlayerPid, {exec, Mod, Fun, Arg}) of
        ?true -> ?true;
        ?false -> ?MSG_ERROR("Strace:~p~n", [erlang:get_stacktrace()]), ?false
    end.
%% 
process_call(PlayerPid, Mod, Fun, Arg) ->
	gen_server:call(PlayerPid, {exec, Mod, Fun, Arg}, ?CONST_TIMEOUT_CALL).

%% 
create_call(PlayerPid, MsgId, Datas) ->
	gen_server:call(PlayerPid, {?handler, MsgId, Datas}, ?CONST_TIMEOUT_CALL).

reconnect_call(PlayerPid, NetPid) ->
	gen_server:call(PlayerPid, {reconnect, NetPid}, ?CONST_TIMEOUT_CALL).
	
db_write_cast(PlayerPid) ->
	gen_server:cast(PlayerPid, db_write).

update_netpid_cast(PlayerPid, NetPid) ->
	gen_server:cast(PlayerPid, {update_netpid, NetPid}).

update_team_pid(PlayerPid, TeamPid) ->
	gen_server:cast(PlayerPid, {update_team_pid, TeamPid}).

%% GM系统
user_logout(PlayerPid) ->
	gen_server:cast(PlayerPid, {admin, [stop, "kick"]}).

add_equip(PlayerPid, GoodsId, Count) ->
	gen_server:cast(PlayerPid, {admin, [add_equip, GoodsId, Count]}).

user_ban(PlayerPid, Duration) ->
	gen_server:cast(PlayerPid, {admin, [user_ban, Duration]}).

user_unban(PlayerPid) ->
	gen_server:cast(PlayerPid, {admin, [user_unban]}).

user_state(PlayerPid) ->
	gen_server:cast(PlayerPid, {admin, [user_state]}).

user_chat_ban(PlayerPid, Duration) ->
	gen_server:cast(PlayerPid, {admin, [chat_ban, Duration]}).

user_chat_unban(PlayerPid) ->
	gen_server:cast(PlayerPid, {admin, [chat_unban]}).

set_viplv(PlayerPid, ToVipLv) ->
    gen_server:cast(PlayerPid, {admin, [set_viplv, ToVipLv]}).


%% guild
guild_party_end(PlayerPid) ->
	gen_server:cast(PlayerPid, guild_party_end).

force2offline(UserId, Msg) ->
    misc_app:cast(UserId, {off, Msg}).

far_conn_call(ToUserId, FromUserId) ->
    gen_server:call(ToUserId, {far_conn, FromUserId}, ?CONST_TIMEOUT_CALL).

%
return_city(UserId) ->
    misc_app:cast(UserId, return_city).