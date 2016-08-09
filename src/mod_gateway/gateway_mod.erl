%% Author: cobain
%% Created: 2012-7-12
%% Description: TODO: Add description to gateway_mod
-module(gateway_mod).

-define(CONST_SYS_FCM_NORMAL, 1).
-define(CONST_SYS_FCM_HALF,   2).
-define(CONST_SYS_FCM_NULL,   3).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([do_work/6, heart/2, do_update_fcm_state/2]).
-export([generate_app_key/0, encrypt_app_key/2]).
-export([set_mini_client/1,
		 get_mini_client/1,
		 del_mini_client/1,
		 client_zip/1, mini_client_unzip/2]).
%%
%% API Functions
%%
do_work(Client, ModHandler, MsgId, Datas, BinaryLast, AccSN2) ->
	% ?MSG_DEBUG("do_work:~p",[{Client, ModHandler, MsgId, Datas, BinaryLast, AccSN2}]),
	case Client#client.state of
		?CONST_PLAYER_CLIENT_STATE_LOGIN_YES ->% 已登录
			% ?MSG_DEBUG("do_work has login:pid = ~w",[Client#client.player_pid]),
			gen_server:cast(Client#client.player_pid, {?handler, ModHandler, MsgId, Datas}),
			{?ok, Client#client{binary = BinaryLast}};
		?CONST_PLAYER_CLIENT_STATE_UNLOGIN ->% 未登陆
			case MsgId of
				?MSG_ID_PLAYER_LOGIN_REQUEST -> login(Client, Datas, BinaryLast);
				?MSG_ID_PLAYER_LOGIN_DEBUG ->	login(Client, Datas, BinaryLast);
				?MSG_ID_PLAYER_CS_RECONNECT ->	reconnect(Client, Datas, BinaryLast, AccSN2);
				_Any ->
 					?MSG_ERROR("~nMsgId = ~p Datas = ~p~n", [MsgId, Datas]),
					{?error, go_to_hell_damn_you}
%% 					{?error, ?CONST_PLAYER_LOGIN_ERROR_BADARG}
			end;
		?CONST_PLAYER_CLIENT_STATE_LOGIN_NO ->% 已登录，无角色，去创建
			case player_serv:create_call(Client#client.player_pid, MsgId, Datas) of
                ?ok ->% 创建角色成功
					Packet = player_api:msg_player_create_ok(),
                    ?ANALYSIS(x2, Client#client.net_pid, Packet),
					misc_app:send(Client#client.socket, Packet),
                    {?ok, Client#client{binary  = BinaryLast, state   = ?CONST_PLAYER_CLIENT_STATE_LOGIN_YES}};
                {?error, ErrorCode} ->% 创建角色出错
					Packet = player_api:msg_player_create_error(ErrorCode),
                    ?ANALYSIS(x2, Client#client.net_pid, Packet),
					misc_app:send(Client#client.socket, Packet),
                    {?ok, Client#client{binary = BinaryLast}}
            end
	end.

%% 平台正常登陆
login(Client, Datas, BinaryLast) ->
	?MSG_DEBUG("login!",[]),
	Seconds		= Client#client.time,
	Ip			= Client#client.ip,
	case player_login_api:login(Client#client.login_key, Client#client.net_pid, {Seconds, Ip}, Datas) of
		{?ok, UserId, PlayerPid, ServId, ServUniqueId, UserState, FcmState, GameTime, LogoutTimeLast, Exist} ->
			?MSG_DEBUG("login success :~p", [{UserId, PlayerPid, ServId, ServUniqueId, UserState, FcmState, GameTime, LogoutTimeLast, Exist}]),
			State	= case Exist of
						  ?CONST_SYS_TRUE -> ?CONST_PLAYER_CLIENT_STATE_LOGIN_YES;
						  ?CONST_SYS_FALSE -> ?CONST_PLAYER_CLIENT_STATE_LOGIN_NO
					  end,
			NetName = misc_app:net_name(UserId),
			register_net_pid(NetName, Client#client.net_pid),
			case fcm_init(FcmState, GameTime, LogoutTimeLast, Seconds, UserId) of
				{?ok, Fcm, FcmPacket} ->
					AppKey			= generate_app_key(),
					Client2 		= Client#client{app_key			= AppKey,		% 应用Key
													serv_id			= ServId,		% 服务器ID
													serv_unique_id	= ServUniqueId,	% 服务器唯一ID
													user_id 		= UserId,		% 玩家ID
													reg_name 		= NetName,		% 注册名
													player_pid		= PlayerPid,	% 玩家游戏逻辑进程ID
													binary 			= BinaryLast,	% Binary
													state  			= State,		% 状态
													user_state      = UserState,    % 玩家状态
													fcm				= Fcm},		    % 防沉迷record
					?true 			= erlang:link(PlayerPid),
					AppCipher		= encrypt_app_key(Client2#client.root_key, Client2#client.app_key),
					ResourceCipher	= encrypt_app_key(Client2#client.root_key, Client2#client.resource_key),
					PacketLogin 	= player_api:msg_player_login_ok(Exist, AppCipher, ResourceCipher), % XXX
					Packet 			= <<PacketLogin/binary, FcmPacket/binary>>,
					?ANALYSIS(x2, Client#client.net_pid, Packet),
					misc_app:send(Client2#client.socket, Packet),
					mysql_api:fetch_cast(<<"UPDATE `game_user` SET ",
										   "  `game_time` 		= '", 		(misc:to_binary(Fcm#fcm.game_time))/binary,
										   "',`login_time_last` = '",		(misc:to_binary(Seconds))/binary,
										   "',`login_ip` 		= '",	    (misc:to_binary(Ip))/binary,
										   "', `online_flag`	= '",		(misc:to_binary(?CONST_PLAYER_ONLINE))/binary,
										   "',`login_times` = `login_times` + '", (misc:to_binary(1))/binary,
										   "' WHERE `user_id` 	= ", 		(misc:to_binary(UserId))/binary,
										   " LIMIT 1 ;">>),
					gateway_worker_sup:insert_net(Client#client.net_pid),
					{?ok, Client2};
				{?error, ErrorCode} ->
					Packet 	= player_api:msg_player_login_error(ErrorCode),
					?ANALYSIS(x2, Client#client.net_pid, Packet),
					misc_app:send(Client#client.socket, Packet),
					?MSG_DEBUG("FCM:SEND---:~p", [Packet]),
					{?ok, Client#client{binary = BinaryLast}}
			end;
		{?error, ErrorCode} -> % 登录失败
			?MSG_ERROR("ErrorCode:~p Stack:~p", [ErrorCode, erlang:get_stacktrace()]),
			Packet 	= player_api:msg_player_login_error(ErrorCode),
			?ANALYSIS(x2, Client#client.net_pid, Packet),
			misc_app:send(Client#client.socket, Packet),
			{?ok, Client#client{binary = BinaryLast}}
	end.

reconnect(Client, {UserId}, BinaryLast, AccSN2) ->
	case player_login_api:reconnect(Client, UserId, AccSN2, BinaryLast) of
		?ok ->
            {?ok, reconnected};
		{?error, ErrorCode} -> % 闪断重连失败
			admin_log_api:log_reconnect(UserId, ErrorCode, Client#client.times),
			Packet 		= player_api:msg_sc_reconnect_fail(),
			?ANALYSIS(x2, Client#client.net_pid, Packet),
			misc_app:send(Client#client.socket, Packet),
			{?error, ErrorCode}
	end.

encrypt_app_key(RootKey, AppKey) ->
	misc:bin_to_hex(crypto:des_ecb_encrypt(RootKey, AppKey)).

%% AppKey	= gateway_mod:generate_app_key().
%% gateway_mod:encrypt_app_key("%6JW%NY&", AppKey).
generate_app_key() ->
	generate_app_key(?CHARACTER_LIST, 8).

generate_app_key(List, Count) ->
	generate_app_key(List, Count, []).
generate_app_key(_List, 0, Acc) -> Acc;
generate_app_key(List, Count, Acc) ->
	case misc_random:random_one(List) of
		?null -> generate_app_key(List, Count, Acc);
		Data  -> generate_app_key(List, Count - 1, [Data|Acc])
	end.


heart(Client, BinaryLast) ->
    Seconds         = misc:seconds(),
	Client2			= db(Client, Seconds),
	Client3			= fcm(Client2, Seconds),
	Client4			= tsp(Client3, Seconds),
	Client5			= gc(Client4, Seconds),
	Client6			= insert_ip(Client5, Seconds),
	
	mod_tencent:check_login(Client#client.user_id),

	Heart			= Client6#client.heart,
	if
		Seconds - Heart#heart.heart >= (?CONST_PLAYER_HEART_INTERVAL/1000 - 1) -> % tcp超时由tcp控制，这里不用考虑
			Heart2	= Heart#heart{heart = Seconds, bad = 0},
			{?ok, Client6#client{binary = BinaryLast, heart = Heart2}};
		?true ->
			Heart2	= Heart#heart{heart = Seconds, bad = Heart#heart.bad + 1},
			if
				Heart2#heart.bad >= ?CONST_PLAYER_BAD_HEART -> % 作弊行为
					Packet	= player_api:msg_sc_illegal_notice(),
					misc_app:send(Client6#client.socket, Packet),
					?MSG_ERROR("BAD HEART ---------- :~p", [Heart2#heart.bad]),
					{?error, ?TIP_COMMON_BAD_HEART};
				?true -> {?ok, Client6#client{binary = BinaryLast, heart = Heart2}}
			end
	end.


db(Client = #client{player_pid = PlayerPid, heart = Heart = #heart{db = Db}}, Seconds)
  when Seconds >= Db andalso is_pid(PlayerPid) ->
	player_serv:db_write_cast(PlayerPid),
	Heart2	= Heart#heart{db = Seconds + ?CONST_PLAYER_DB_INTERVAL},
	Client#client{heart = Heart2};
db(Client, _Seconds) ->
	Client.

%% 时间同步协议(Time Synchronization Protocol)
tsp(Client = #client{heart = Heart = #heart{tsp = Tsp}}, Seconds)
  when Seconds >= Tsp ->
	PacketTime 	= player_api:msg_player_sc_tsp(Seconds),
	misc_app:send(Client#client.socket, PacketTime),
	Heart2	= Heart#heart{tsp = Seconds + ?CONST_PLAYER_TSP_INTERVAL},
	Client#client{heart = Heart2};
tsp(Client, _Seconds) ->
	Client.

%% player进程GC
gc(Client = #client{player_pid = PlayerPid, heart = Heart = #heart{gc = GcTime}}, Seconds)
  when Seconds >= GcTime andalso is_pid(PlayerPid) ->
	erlang:garbage_collect(PlayerPid),
	Heart2	= Heart#heart{gc = Seconds + ?CONST_PLAYER_GC_INTERVAL},
	Client#client{heart = Heart2};
gc(Client, _Seconds) ->
	Client.

%% 角色IP
insert_ip(Client = #client{ip = IP, heart = Heart = #heart{ip = IPTime}}, Seconds)
  when Seconds >= IPTime ->
	player_api:insert_ip(IP),
	Heart2	= Heart#heart{ip = Seconds + ?CONST_PLAYER_GC_INTERVAL},
	Client#client{heart = Heart2};
insert_ip(Client, _Seconds) ->
	Client.
%%
%% Local Functions
%%
register_net_pid(NetName, NetPid) ->
	case misc:where_is({local, NetName}) of
		?undefined ->
			misc:register(local, NetName, NetPid);
		NetPid -> ?ok;
		NetPidOld ->
			gateway_worker_serv:repeat_login_cast(NetPidOld),
			erlang:unregister(NetName),
			register_net_pid(NetName, NetPid)
	end.

%% 防沉迷初始化
fcm_init(FcmState, GameTime, LogoutTimeLast, Seconds, UserId) ->
	case FcmState of
		?CONST_PLAYER_FCM_STATE_SIGN_ADULT ->% 未纳入防沉迷系统
			Fcm	= #fcm{
					   game_time	= 0,				%% 防沉迷-游戏时间
					   fcm_state	= FcmState, 		%% 防沉迷-状态
					   fcm_next		= 0					%%   防沉迷-下次触发时间
					  },
			FcmPacket	= player_api:msg_sc_fcm_notice(FcmState, GameTime, 0),
			{?ok, Fcm, FcmPacket};
		_ ->% 纳入防沉迷系统
			fcm_init2(FcmState, GameTime, LogoutTimeLast, Seconds, UserId)
	end.
fcm_init2(FcmState, GameTime, LogoutTimeLast, Seconds, UserId) ->
%% 	?MSG_DEBUG("Seconds:~p LogoutTimeLast:~p~n", [Seconds, LogoutTimeLast]),
	GameTime2	= if
					  Seconds - LogoutTimeLast >= ?CONST_FCM_FREE_TIME -> 0;% 离线时常大于等于五小时
					  ?true -> GameTime % 离线时常小于五小时
				  end,
	case fcm_init(GameTime2, Seconds) of
		{?ok, FcmNext, FcmFlag} ->% 在线时长小于三小时
			Fcm	= #fcm{
					   game_time	= GameTime2,	%% 防沉迷-游戏时间
					   fcm_state	= FcmState, 	%% 防沉迷-状态
					   fcm_next		= FcmNext		%% 防沉迷-下次触发时间
					  },
            FcmPacket   = 
                case ets_api:lookup(?CONST_ETS_FCM, UserId) of
                    ?null ->
                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
    			        player_api:msg_sc_fcm_notice(FcmState, GameTime2, 1);
                    {_, OldFcmFlag} when OldFcmFlag < FcmFlag ->
                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
                        player_api:msg_sc_fcm_notice(FcmState, GameTime2, 1);
                    _ ->
                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
                        player_api:msg_sc_fcm_notice(FcmState, GameTime2, 0)
                end,
			{?ok, Fcm, FcmPacket};
		{?error, ErrorCode} ->% 在线时长大于等于三小时
			case config_fcm:get_data() of
				?CONST_SYS_TRUE ->
					{?error, ErrorCode};
				?CONST_SYS_FALSE ->
					Fcm	= #fcm{
							   game_time	= GameTime2,%% 防沉迷-游戏时间
							   fcm_state	= FcmState,	%% 防沉迷-状态
							   fcm_next		= 0			%% 防沉迷-下次触发时间
							  },
					?MSG_DEBUG("Fcm:~p~n", [Fcm]),
					{?ok, Fcm, <<>>}
			end
	end.

fcm_init(GameTime, Seconds)-> % 登录时
	if
		GameTime < 3600 -> % 小于一小时
			{?ok, Seconds + 3600 - GameTime, 1};
		GameTime < 7200 -> % 小于二小时
			{?ok, Seconds + 7200 - GameTime, 2};
		GameTime < 10500 -> % 小于二小时五十五分钟
			{?ok, Seconds + 10500 - GameTime, 3};
		GameTime < 10800 -> % 小于三小时
			{?ok, Seconds + 10800 - GameTime, 4};
		?true -> % 大于等于三小时
            {?ok, Seconds + 10800 - GameTime, 5}
%% 			{?error, ?CONST_PLAYER_LOGIN_ERROR_FCM}% 禁止登陆
	end.


%% fcm_init(GameTime, Seconds)-> % 登录时
%% 	if
%% 		GameTime < 100 -> % 小于一小时
%% 			{?ok, Seconds + 100 - GameTime};
%% 		GameTime < 200 -> % 小于二小时
%% 			{?ok, Seconds + 200 - GameTime};
%% 		GameTime < 300 -> % 小于二小时五十五分钟
%% 			{?ok, Seconds + 300 - GameTime};
%% 		GameTime < 400 -> % 小于三小时
%% 			{?ok, Seconds + 400 - GameTime};
%% 		?true -> % 大于等于三小时
%% 			{?error, ?CONST_PLAYER_LOGIN_ERROR_FCM}% 禁止登陆
%% 	end.

%% 防沉迷
fcm(Client = #client{fcm = Fcm, user_id = UserId}, Seconds)
  when is_record(Fcm, fcm) ->
	case config_fcm:get_data() of
		?CONST_SYS_TRUE ->
			case Fcm#fcm.fcm_state of
				?CONST_PLAYER_FCM_STATE_SIGN_ADULT -> Client;
				_  ->
					if
						Seconds - Fcm#fcm.fcm_next > 0 ->
							{?ok, FcmNext, FcmPacket, FcmFlag, GameTime, FcmState} = fcm_interval(Fcm, Client#client.time, Seconds),
                            FcmPacket2 = 
                                case ets_api:lookup(?CONST_ETS_FCM, UserId) of
                                    ?null ->
                                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
                                        player_api:msg_sc_fcm_notice(FcmState, GameTime, 1);
                                    {_, OldFcmFlag} when OldFcmFlag < FcmFlag ->
                                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
                                        player_api:msg_sc_fcm_notice(FcmState, GameTime, 1);
                                    _ ->
                                        ets_api:insert(?CONST_ETS_FCM, {UserId, FcmFlag}),
                                        player_api:msg_sc_fcm_notice(FcmState, GameTime, 0)
                                end,
							Fcm2 = Fcm#fcm{fcm_next = FcmNext},
							misc_app:send(Client#client.socket, <<FcmPacket/binary, FcmPacket2/binary>>),
							Client#client{fcm = Fcm2};
						?true -> Client
					end
			end;
		?CONST_SYS_FALSE ->
			Client
	end;
fcm(Client, _Seconds)->
	Client.

fcm_interval(Fcm, LoginTime, Seconds) ->
	FcmInit		= Fcm#fcm.game_time,
	FcmState	= Fcm#fcm.fcm_state,
	GameTime 	= FcmInit + Seconds - LoginTime,
    {FcmPacket, FcmNext, Flag} = 
    	if
    		GameTime < 3600 -> % 小于一小时
%%     			FcmPacketT	= player_api:msg_sc_fcm_notice(FcmState, GameTime, 1),
    			FcmNextT	= Seconds + 3600 - GameTime, 
                {<<>>, FcmNextT, 1};
    		GameTime < 7200 -> % 小于二小时
%%     			FcmPacketT	= player_api:msg_sc_fcm_notice(FcmState, GameTime, 2),
    			FcmNextT	= Seconds + 7200 - GameTime,
                {<<>>, FcmNextT, 2};
    		GameTime < 10500 -> % 小于二小时五十五分钟
%%     			FcmPacketT	= player_api:msg_sc_fcm_notice(FcmState, GameTime, 3),
    			FcmNextT	= Seconds + 10500 - GameTime,
                {<<>>, FcmNextT, 3};
    		GameTime < 10800 -> % 小于三小时
%%     			FcmPacketT	= player_api:msg_sc_fcm_notice(FcmState, GameTime, 4),
    			FcmNextT	= Seconds + 10800 - GameTime,
                {<<>>, FcmNextT, 4};
    		?true -> % 大于等于三小时
%%     			FcmPacketT	= player_api:msg_sc_fcm_offline_notice(),
    			FcmNextT	= 0,
                {<<>>, FcmNextT, 5}
    	end,
	{?ok, FcmNext, FcmPacket, Flag, GameTime, FcmState}.


do_update_fcm_state(Client = #client{fcm = Fcm}, FcmState) ->
	Fcm2 = Fcm#fcm{fcm_state = FcmState},
	Client#client{fcm = Fcm2}.

client_zip(#client{
				   serv_id			= ServId,		% [M]服务器ID
				   serv_unique_id	= ServUniqueId,	% [M]服务器唯一ID
				   user_id 			= UserId,		% [M]玩家ID
				   ip				= Ip,	        % [M]玩家IP
				   state  			= State,		% [M]状态
				   user_state       = UserState,    % [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
				   time             = Time,         % [M]登录时间
				   fcm				= Fcm,			% [M]防沉迷record
				   times			= Times			% [M]闪断重连次数
				  }) ->
	#mini_client{
				 serv_id			= ServId,		% [M]服务器ID
				 serv_unique_id		= ServUniqueId,	% [M]服务器唯一ID
				 user_id 			= UserId,		% [M]玩家ID
				 ip					= Ip,	        % [M]玩家IP
				 state  			= State,		% [M]状态
				 user_state       	= UserState,    % [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
				 time             	= Time,         % [M]登录时间
				 fcm				= Fcm,			% [M]防沉迷record
				 times				= Times			% [M]闪断重连次数
				}.

mini_client_unzip(Client, #mini_client{
									   serv_id			= ServId,		% [M]服务器ID
									   serv_unique_id	= ServUniqueId,	% [M]服务器唯一ID
									   user_id 			= UserId,		% [M]玩家ID
									   ip				= Ip,	        % [M]玩家IP
									   state  			= State,		% [M]状态
									   user_state       = UserState,    % [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
									   time             = Time,         % [M]登录时间
									   fcm				= Fcm,			% [M]防沉迷record
									   times			= Times			% [M]闪断重连次数
									  }) ->
	Client#client{
				  serv_id			= ServId,		% [M]服务器ID
				  serv_unique_id	= ServUniqueId,	% [M]服务器唯一ID
				  user_id 			= UserId,		% [M]玩家ID
				  ip				= Ip,	        % [M]玩家IP
				  state  			= State,		% [M]状态
				  user_state      	= UserState,    % [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
				  time            	= Time,         % [M]登录时间
				  fcm				= Fcm,			% [M]防沉迷record
				  times				= Times			% [M]闪断重连次数
				 }.

%% 设置闪断重连数据
set_mini_client(Client) ->
	MiniClient	= gateway_mod:client_zip(Client),
	ets_api:insert(?CONST_ETS_MINI_CLIENT, MiniClient),
	?ok.

%% 获取闪断重连数据
get_mini_client(UserId) ->
	ets_api:lookup(?CONST_ETS_MINI_CLIENT, UserId).

%% 删除闪断重连数据
del_mini_client(UserId) ->
	ets_api:delete(?CONST_ETS_MINI_CLIENT, UserId).