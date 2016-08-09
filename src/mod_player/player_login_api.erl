%% Author: cobain
%% Created: 2012-7-11
%% Description: TODO: Add description to player_login_api
-module(player_login_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.login.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.goods.data.hrl").
-include("record.task.hrl").
-include("tencent.hrl").
-include_lib("xmerl/include/xmerl.hrl").
%%
%% Exported Functions
%%
-export([login/4, reconnect/4, 
		 login_init_data/2, login_ets/1, login_init/2, login_packets/1]).
-export([create/5, check_player_exist/5, login_check_exist/3]).
-export([logout/1, clear_md5/0]).
-export([get_account/3, get_guest_info/1, get_guest_name/1, get_guest_pro_sex/0, create_info/1]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 登录相关
%%    ?uint32,?string,?uint16,?uint8,?uint32,?uint8,?uint8,?uint32,?uint32,?string,?bool,?uint32,?string
%% 	  {AccId, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug,LinkTime,GateName}
login(Key, NetPid, {Time, Ip},{_AccId, Account, ServId, Fcm, OpenID, _Exist, _State, _GameTime, _LogoutTimeLast, Sing, Debug, LinkTime,GateName}) ->
	ServUniqueId	= config:read(server_info, #rec_server_info.serv_uniq_id),
    AccId           = config:read_deep([server, base, platform_id]),
    AccName         = config:read(platform_info, #rec_platform_info.platform),
	try
        [UserId, Exist, State, GameTime, LogoutTimeLast] = 
            check_user_exist(AccId, Account, AccName, ServId, ?CONST_SYS_TRUE),
	    admin_log_api:log_login_req(AccId, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug, LinkTime),
        
        LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
		?ok			= login_check(Key, LoginCheckMode, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug, LinkTime,Ip,GateName),
		?ok			= login_check_state(State),
		?ok			= login_check_sid(ServId),
       % ?ok         = login_check_md5(Sing, AccId),
		Exist2		= login_check_exist(Account, Exist, ServId),
		PlayerName	= misc_app:player_name(UserId),
        ?ok         = login_check_same_acc(Account, UserId),

		case misc:where_is({local, PlayerName}) of
			PlayerPid when is_pid(PlayerPid) ->
				case misc:is_process_alive(PlayerPid) of
					?true ->
						player_serv:update_netpid_cast(PlayerPid, NetPid),
						{?ok, UserId, PlayerPid, ServId, ServUniqueId, State, Fcm, GameTime, LogoutTimeLast, Exist2};
					?false ->
						unregister(PlayerName),
						{?ok, PlayerPid2} = player_sup:start_child_player_serv(NetPid, UserId, ServId, ServUniqueId, State, Time, Ip, Account, Exist2),
						{?ok, UserId, PlayerPid2, ServId, ServUniqueId, State, Fcm, GameTime, LogoutTimeLast, Exist2}
				end;
			?undefined -> % 玩家完全离线
				{?ok, PlayerPid} = player_sup:start_child_player_serv(NetPid, UserId, ServId, ServUniqueId, State, Time, Ip, Account, Exist2),
				{?ok, UserId, PlayerPid, ServId, ServUniqueId, State, Fcm, GameTime, LogoutTimeLast, Exist2}
		end
	catch
		throw:Return ->
			?MSG_ERROR("Return:~p", [Return]),
            Return;
		Error:Reason ->% 服务器错误
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?CONST_PLAYER_LOGIN_ERROR_SYS}
	end;

login(Key, NetPid, {Time, Ip}, {Account, ServId}) ->% 调试登录
	?MSG_DEBUG("LOGIN [~p]:~p", [?MSG_ID_PLAYER_LOGIN_DEBUG, {Account, ServId}]),
	AccId 		= config:read_deep([server, base, platform_id]),
%% 	ServId 		= config_server_id:get_serv_id(),
	Fcm			= ?CONST_PLAYER_FCM_STATE_UNSIGNED,
	Sing		= ?ok,
	Debug		= ?true,
	case player_db_mod:login_debug(AccId, Account, ServId, Time, Fcm, Ip) of
		{?ok, UserId, Exist, State, GameTime, LogoutTimeLast, Fcm2} ->
			login(Key, NetPid, {Time, Ip},
				  {AccId, Account, ServId, Fcm2, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug, misc:seconds()});
		{?error, ErrorCode} ->
			?MSG_ERROR("ErrorCode:~p", [ErrorCode]),
			{?error, ErrorCode}
	end.

reconnect(Client, UserId, AccSN2, BinaryLast) ->
	?MSG_ERROR("RECONNECT [~p]:~p", [?MSG_ID_PLAYER_CS_RECONNECT, {UserId}]),
	try
		case gateway_mod:get_mini_client(UserId) of
			MiniClient when is_record(MiniClient, mini_client) ->
				?ok			= login_check_state(MiniClient#mini_client.user_state),
				?ok			= reconnect_check_ip(MiniClient#mini_client.ip, Client#client.ip),
                NetName     = misc_app:net_name(UserId),
				case misc:where_is({local, NetName}) of
					OldNetPid when is_pid(OldNetPid) ->
						case misc:is_process_alive(OldNetPid) of
							?true ->
                                case gen_tcp:controlling_process(Client#client.socket, OldNetPid) of
                                    ?ok ->
                                        gateway_worker_serv:reconnect_cast(OldNetPid, Client#client.socket, Client#client.ref, AccSN2, BinaryLast),
								        ?ok;
                                    {?error, ErrorCode} ->
                                        {?error, ErrorCode}
                                end;
							?false ->
								{?error, ?CONST_PLAYER_RECONNECT_ERROR_PRO_DEAD}
						end;
					?undefined -> 
                        {?error, ?CONST_PLAYER_RECONNECT_ERROR_NO_PRO}
				end;
			_ -> 
                {?error, ?CONST_PLAYER_RECONNECT_ERROR_NO_MINI}
		end
	catch
		throw:{?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK} ->
			{?error, ?CONST_PLAYER_RECONNECT_ERROR_BAD_STATE};
		throw:Return ->
			?MSG_ERROR("Return:~p", [Return]),
            Return;
		Error:Reason ->% 服务器错误
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?CONST_PLAYER_RECONNECT_ERROR_SYS}
	end.

%% {AccId, Account, ServId, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug}
check_user_exist(AccId, Account, AccName, Sid, IsFirst) ->
    Sql = <<"select `user_id`, `exist`, `state`, `game_time`, `logout_time_last` from `game_user` ",
            " where `account` = '", (misc:to_binary(Account))/binary, 
            "' and `serv_id` = '", (misc:to_binary(Sid))/binary, "';">>,
    case mysql_api:select(Sql) of
        {?ok, [[UserId, Exist, State, GameTime, LogoutTimeLast]]} ->
            [UserId, Exist, State, GameTime, LogoutTimeLast];
        {?ok, []} when IsFirst =:= ?CONST_SYS_TRUE ->
            SqlCreate = <<"insert into `game_user`(`acc_id`, `serv_id`, `acc_name`, `account`) values ('", 
                          (misc:to_binary(AccId))/binary, "', '", 
                          (misc:to_binary(Sid))/binary, "', '",
                          (misc:to_binary(AccName))/binary, "', '",
                          (misc:to_binary(Account))/binary, "');">>,
            case mysql_api:insert(SqlCreate) of
                {?ok, _, _} ->
                    check_user_exist(AccId, Account, AccName, Sid, 0);
                {?error, Reason2} ->
                    ?MSG_ERROR("!err:~p", [Reason2]),
                    throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CREATE})
            end;
        {?ok, []} ->
            ?MSG_ERROR("!err:cannot create new user...", []),
            throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CREATE});
        {?error, Reason} ->
            ?MSG_ERROR("~p", [Reason]),
            throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CREATE})
    end.

%% 用户登录验证md5(username + time + 密钥 + cm)
login_check(_Key, _AccId, _Account, _ServId, _Fcm, _UserId, _Exist, _State, _GameTime, _LogoutTimeLast, _Sing, ?true, _,_,_) -> ?ok;% 调试
%% http://test.wwsg.360.com/index.php?username=198914885&time=1384336403&cm=2&flag=a59386b7902169680cc711e77044d45b&server=S1
login_check(Key, ?CONST_SYS_LOGIN_CHECK_360U9, Account, ServId, Fcm, UserId, _Exist, State, _GameTime, LogoutTimeLast, SingBinary, ?false, LinkTime,_,GateName) ->
	Sing	= misc:to_list(SingBinary),
    L = misc:to_list(Account) ++ misc:to_list(LinkTime) ++
                  misc:to_list(Key) ++ misc:to_list(Fcm) ++ lists:concat(["S", ServId]),
	case misc:md5(L) of
		Sing -> ?ok; %% 登录验证通过
		Sing2-> %% 登录验证失败
			?MSG_ERROR("login_check {Sing:~p Sing2:~p, L=[~p]}",[Sing, Sing2, L]),
			admin_log_api:log_login_check(UserId, State, LogoutTimeLast),
			throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK})
	end;
%% 5120097a7a6e7f57b76dcd57df378e67 4399 gfsdghdsh 31 2 3000004 0 1 0 0 
%% 5120097a7a6e7f57b76dcd57df378e67 4399 hzx109911 27 1       0 0 0 0 0
login_check(_Key, ?CONST_SYS_LOGIN_CHECK_4399, _Account, _ServId, _Fcm, _, 0, 1, _GameTime, _LogoutTimeLast, _SingBinary, ?false, _,_,_) ->
    ?ok;
login_check(Key, ?CONST_SYS_LOGIN_CHECK_4399, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, SingBinary, ?false, _,_,_) ->
    PlatformName = config:read(platform_info, #rec_platform_info.platform),
	Sing	= misc:to_list(SingBinary),
	X       =     misc:to_list(Key)         ++      misc:to_list(PlatformName) ++    % misc:to_list(AccId)  ++
                  misc:to_list(Account)     ++      misc:to_list(ServId)    ++
                  misc:to_list(Fcm)         ++      misc:to_list(UserId)    ++
                  misc:to_list(Exist)       ++      misc:to_list(State)     ++
                  misc:to_list(GameTime)    ++      misc:to_list(LogoutTimeLast),
	case misc:md5(X) of
		Sing -> ?ok; %% 登录验证通过
		Sing2-> %% 登录验证失败
			?MSG_ERROR("login_check {Sing:~p Sing2:~p, ~p}",[Sing, Sing2, X]),
			admin_log_api:log_login_check(UserId, State, LogoutTimeLast),
			throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK})
	end;

%% 腾讯平台检验方式：http方式
% http://openapi.tencentyun.com/v3/user/get_info?
% openid=B624064BA065E01CB73F835017FE96FA&
% openkey=5F154D7D2751AEDC8527269006F290F70297B7E54667536C&
% appid=2&
% sig=VrN%2BTn5J%2Fg4IIo0egUdxq6%2B0otk%3D&
% pf=qzone&
% format=json&
% userip=112.90.139.30

% 1. 原始请求信息：
% appkey：228bf094169a40a3bd188ba37ebe8723
% HTTP请求方式：GET
% 请求的URI路径（不含HOST）：/v3/user/get_info
% 请求参数：openid=11111111111111111&openkey=2222222222222222&appid=123456&pf=qzone&format=json&userip=112.90.139.30

% 2. 下面开始构造源串： 
% 第1步：将请求的URI路径进行URL编码，得到： %2Fv3%2Fuser%2Fget_info 

% 第2步：将除“sig”外的所有参数按key进行字典升序排列，排列结果为：appid，format，openid，openkey，pf，userip 

% 第3步：将第2步中排序后的参数(key=value)用&拼接起来：
% appid=123456&format=json&openid=11111111111111111&openkey=2222222222222222&pf=qzone&userip=112.90.139.30
% 然后进行URL编码（ 编码时请关注URL编码注意事项，否则容易导致后面签名不能通过验证），编码结果为：
% appid%3D123456%26format%3Djson%26openid%3D11111111111111111%26openkey%3D2222222222222222%26pf%3Dqzone%26
% userip%3D112.90.139.30

% 第4步：将HTTP请求方式，第1步以及第3步中的到的字符串用&拼接起来，得到源串：
% GET&%2Fv3%2Fuser%2Fget_info&appid%3D123456%26format%3Djson%26openid%3D11111111111111111%26
% openkey%3D2222222222222222%26pf%3Dqzone%26userip%3D112.90.139.30


%% --------------------------
%% openID:Account   openKey:SingBinary
%%---------------------------
login_check(Key, ?CONST_SYS_LOGIN_CHECK_TENCENT, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, SingBinary, ?false, _,Ip,GateName) ->
    OpenID = misc:to_list(Account),
    OpenKey  = misc:to_list(SingBinary),

    UserIP =misc:to_list(Ip),
    PF = misc:to_list(GateName),

    ets_api:insert(?CONST_ETS_TENCENT_INFO, #ets_tencent_info
                                            {
                                                user_id         = UserId,
                                                open_id         = OpenID,
                                                open_key        = OpenKey,
                                                vip_lv          = 0,       
                                                is_year_vip     = 0, 
                                                pf              = PF,
                                                pf_key          = "",                     
                                                ip              = UserIP
                                            }),
    mod_tencent:is_login(UserId),
    case misc:http_request(UserId,"/v3/user/get_info",[]) of
        {ok, XmlContent} ->
            ?MSG_DEBUG("Login check reply = ~p", [XmlContent]),
            {Element,_} = xmerl_scan:string(XmlContent),
            case misc:get_xml_value("/data/ret",Element) of
                "0"->
                    TecentVip = misc:get_xml_value("/data/yellow_vip_level",Element,"0"),
                    ?MSG_DEBUG("login ,Vip = ~w",[TecentVip]),
                    ets_api:update_element(?CONST_ETS_TENCENT_INFO, UserId, {#ets_tencent_info.vip_lv,misc:to_integer(TecentVip)}),
                    ?ok;
                Code ->
                    ?MSG_ERROR("Login check error,code = ~p,content= ~p", [Code,XmlContent]),
                    throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK})
            end;
        Other ->
            ?MSG_ERROR("Login check err = ~p", [Other]),
            throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK})
            % ?ok
    end;

% xml:
% Content-type: text/html; charset=utf-8
% {
% "ret":0,
% "is_lost":0,
% "nickname":"Peter",
% "gender":"男",
% "country":"中国",
% "province":"广东",
% "city":"深圳",
% "figureurl":"http://imgcache.qq.com/qzone_v4/client/userinfo_icon/1236153759.gif",
% "is_yellow_vip":1,
% "is_yellow_year_vip":1,
% "yellow_vip_level":7,
% "is_yellow_high_vip": 0
% } 

%% java那边检验过
login_check(Key,?CONST_SYS_LOGIN_CHECK_NONE,Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, SingBinary, ?false, _,Ip,GateName) ->
    OpenID = misc:to_list(Account),
    OpenKey  = misc:to_list(SingBinary),
    UserIP =misc:to_list(Ip),
    PF = misc:to_list(GateName),
    ets_api:insert(?CONST_ETS_TENCENT_INFO, #ets_tencent_info
                                            {
                                                user_id         = UserId,
                                                open_id         = OpenID,
                                                open_key        = OpenKey,
                                                vip_lv          = 0,       
                                                is_year_vip     = 0, 
                                                pf              = PF,
                                                pf_key          = "",                     
                                                ip              = UserIP
                                            }),
    ?ok;


login_check(Key, AccId, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, SingBinary, ?false, _,_,_) ->
	Sing	= misc:to_list(SingBinary),
	case misc:md5(misc:to_list(Key)			++		misc:to_list(AccId) 	++
				  misc:to_list(Account)		++		misc:to_list(ServId) 	++
				  misc:to_list(Fcm)			++		misc:to_list(UserId)	++
				  misc:to_list(Exist)		++		misc:to_list(State) 	++
				  misc:to_list(GameTime)	++		misc:to_list(LogoutTimeLast)) of
		Sing -> ?ok; %% 登录验证通过
		Sing2-> %% 登录验证失败
			?MSG_ERROR("login_check {Sing:~p Sing2:~p}",[Sing, Sing2]),
			admin_log_api:log_login_check(UserId, State, LogoutTimeLast),
			throw({?error, ?CONST_PLAYER_LOGIN_ERROR_CHECK})
	end.

%% login_check_md5(?ok, _) ->
%%     ?ok;
%% login_check_md5(Sing, K) when K =:= 3 orelse K =:= 5 -> % pptv/qidian
%%     Now = misc:seconds(),
%%     case ets_api:lookup(?CONST_ETS_MD5, Sing) of
%%         ?null ->
%%             ets_api:insert(?CONST_ETS_MD5, #ets_md5{md5 = Sing, time = Now}),
%%             ?ok;
%%         #ets_md5{time = Time} when Time - Now > 600 ->
%%             ets_api:delete(?CONST_ETS_MD5, Sing),
%%             ?ok;
%%         #ets_md5{} ->
%%             throw({?error, ?CONST_PLAYER_LOGIN_ERROR_TIMEOUT})
%%     end;
%% login_check_md5(_Sing, _) ->
%%     ?ok.

clear_md5() ->
    Now = misc:seconds(),
    case ets:first(?CONST_ETS_MD5) of
        '$end_of_table' ->
            ?ok;
        Key ->
            clear_md5(Key, Now)
    end.

clear_md5(Key, Now) ->
    case ets:lookup(?CONST_ETS_MD5, Key) of
        #ets_md5{time = Time} when Now - Time > 600 ->
            ets:delete(?CONST_ETS_MD5, Key);
        #ets_md5{} ->
            ?ok;
        ?true ->
            ets:delete(?CONST_ETS_MD5, Key)
    end,
    case ets:next(?CONST_ETS_MD5, Key) of
        '$end_of_table' ->
            ?ok;
        Key2 ->
            clear_md5(Key2, Now)
    end.

%%     ?ok.
%% 用户登录状态检查
login_check_state(?CONST_SYS_USER_STATE_NORMAL) -> ?ok;
login_check_state(?CONST_SYS_USER_STATE_GUIDE) -> ?ok;
login_check_state(?CONST_SYS_USER_STATE_GM) -> ?ok;
login_check_state(?CONST_SYS_USER_STATE_FORBID) ->
	throw({?error, ?CONST_PLAYER_LOGIN_ERROR_FORBID}).

% 1.相同服
% 2.已经合到某个服
%% desc:检查玩家服务器号
login_check_sid(ServId) ->
    CombineList = config:read(combine), 
    case lists:member(ServId, CombineList) of
        ?true ->
            ?ok;
        ?false ->
            ?MSG_ERROR("CombineList = ~p,ServId = ~p",[CombineList,ServId]),
            throw({?error, ?CONST_PLAYER_LOGIN_ERROR_SERVNO})
    end.

%% 同帐号t人
login_check_same_acc(Account, UserId) ->
    case catch config:read(platform_info, #rec_platform_info.same_account) of
        ?CONST_SYS_TRUE -> ?ok;
        _ -> case catch player_api:lookup_account_user_id(Account) of
                {_, AccountUserList} ->
                    AccountUserList2     = lists:delete(UserId, AccountUserList),
                    player_api:tick(AccountUserList2);
                _ ->
                    ?ok
            end
    end.
    

%% 用户登录检查角色是否存在
login_check_exist(_Account, ?CONST_SYS_TRUE, _) -> ?CONST_SYS_TRUE;
login_check_exist(Account, ?CONST_SYS_FALSE, ServId) ->
	player_api:check_account_player(Account, ServId).
%% %% 用户登录检查角色是否存在
%% login_check_exist(_Account, ?CONST_SYS_TRUE) -> ?CONST_SYS_TRUE;
%% login_check_exist(Account, ?CONST_SYS_FALSE) ->
%% 	player_api:check_account_player(Account).
%% 检查玩家角色是否存在
check_player_exist(_UserName, 0, 0, ?CONST_SYS_PRO_NULL, ?CONST_SYS_SEX_NULL) -> ?false;
check_player_exist(_UserName, _Exp, _Lv, _Pro, _Sex) -> ?true.

reconnect_check_ip(Ip, Ip) -> ?ok;
reconnect_check_ip(IpOld, IpNew) ->
	?MSG_ERROR("IpOld:~p IpNew:~p", [IpOld, IpNew]),
	throw({?error, ?CONST_PLAYER_RECONNECT_ERROR_BAD_IP}).

%% 登陆初始化
%% 主要处理玩家持久化后的数据
login_init_data(Player, ?CONST_SYS_TRUE) ->
	case player_api:lookup_player_offline(Player#player.user_id) of
		Player2 when is_record(Player2, player) ->
			Player3		= login_init_data_merge(Player, Player2),
			player_api:delete_player_offline(Player3#player.user_id),
			{?ok, Player3};
		?null ->% 离线ETS中无数据，去读数据库
			case player_mod:read_player(Player#player.user_id, Player) of
                {?ok, #player{} = Player2} -> {?ok, Player2};
                {?ok, ?null} -> {?ok, Player}
            end
	end;
login_init_data(Player, ?CONST_SYS_FALSE) ->
	{?ok, Player}.
%% 角色数据进行转换 Player + Player2 = Player3
login_init_data_merge(Player1, Player2) ->
    #player{user_id = UserId, serv_id = ServId, serv_unique_id = ServUniqueId,
            net_pid = NetPid, ip = Ip, account = Account,
            battle_pid = BattlePid, state = State, user_state  = UserState,
            play_state = PlayState, time_login = LoginTime, practice_state = PracState,
            date_login = DateLogin, battle_type = BattleType, can_skip = CanSkip,
            is_skiped = IsSkiped, map_pid = MapPid, team_id = TeamId, leader = LeaderId,
            attr_group = AttrGroup, attr_assist = AttrAssist, attr_rate_group = AttrRateGroup,
            attr_sum = AttrSum, attr_reflect = AttrReflect, attr_sum_reflect = AttrSumReflect,
            shop_temp_list = ShopTempList, tower_passid = TowerPassId, offline_packet = OfflinePacket,
            reconnect = Reconnect, access_time = AccessTime, logs_tmp = LogsTmp} = Player1,
    Player2#player{
                   user_id            = UserId,            % [First]玩家ID
                   serv_id            = ServId,            % [Temp]服务器ID
                   serv_unique_id     = ServUniqueId,            % [Temp]服务器唯一ID
                   net_pid            = NetPid,            % [Temp]玩家Net进程ID
                   ip                 = Ip,        % [Temp]玩家登陆IP
                   account            = Account,       % [Temp]玩家平台帐号
                   map_pid            = MapPid,            % [Temp]玩家地图进程ID
                   battle_pid         = BattlePid,            % [Temp]玩家战斗进程ID
                   is_skiped          = IsSkiped,            % [Temp]跳过标示
                   can_skip           = CanSkip,            % [Temp]可跳过标志
                   battle_type        = BattleType,            % [Temp]战斗类型
                   state              = State,            % [Temp]状态  0：封号|1:普通玩家|2：指导员|3：GM
                   user_state         = UserState,            % [Temp]玩家状态 '单修'|'双修'|'战斗'|'站立',
                   play_state         = PlayState,            % [Temp]玩家当前所在玩法 '温泉'...,
                   practice_state     = PracState,
                   date_login         = DateLogin,            % [Temp]登录日期
                   time_login         = LoginTime,            % [Temp]登录时间
                   team_id            = TeamId,            % [Temp]玩家队伍ID
                   leader             = LeaderId,            % [Temp]队长user_id
                   attr_group         = AttrGroup,        % [Temp]角色属性集合 
                   attr_rate_group    = AttrRateGroup,        % [Temp]角色属性比例加成集合
                   attr_assist        = AttrAssist,        % [Temp]角色副将加成#attr{}
                   attr_reflect       = AttrReflect,        % [Temp]受别人的属性，而产生的属性加成集合
                   attr_sum           = AttrSum,        % [Temp]角色相加属性#attr{} = sigma(attr_sum)
                   attr_sum_reflect   = AttrSumReflect,        % [Temp]受别人的属性，而产生的属性加成的和
                   shop_temp_list     = ShopTempList,           % [Temp]商店回购列表
                   tower_passid       = TowerPassId,            % [Temp]当前闯塔关卡
                   offline_packet     = OfflinePacket,         % [Temp]上线时用的临时包，在login_pakcet发后，这个包会发到最后 
                   reconnect          = Reconnect,       % [Temp]断线重连标示(true:允许断线重连|false:不允许断线重连)
                   access_time        = AccessTime,            % [Temp]最后访问时间(离线数据中使用)
                   logs_tmp           = LogsTmp            % [Temp]临时登陆日志
                  }.

login_ets(Player) ->
    % 玩家在线信息同步
	player_api:delete_player_offline(Player#player.user_id),
    PlayerOnLine = player_api:player_online_data(Player),
	ets_api:insert(?CONST_ETS_PLAYER_ONLINE, PlayerOnLine).
%% 玩家后续数据处理，初始化
login_init(Player, ?CONST_SYS_TRUE) when is_record(Player, player) ->
	try
        Info = Player#player.info,
        if
            not is_record(Info, info) ->
                ?MSG_ERROR("not this server user_id[~p]", [Player#player.user_id]),
                {?error, ?TIP_COMMON_BAD_ARG};
            ?true ->
        		% XXX 其他系统数据初始化，有需要在玩家数据反持久化后初始化的，都插到这里后面
        		{?ok, Player2}	= player_vip_api:refresh_vip(Player, ?null),					% VIP
        		% 影响到玩家信息的初始化操作
                Player2_2       = player_sys_api:login(Player2),                                % 开启模块
        		Player3 		= guild_api:login_init(Player2_2), 		                        % 军团
        		?true 			= is_record(Player3, player),
        		Player5     	= map_api:login_init(Player3),      	                        % 地图
        		?true 			= is_record(Player5, player),
        		Player6 		= practice_api:login(Player5),			                        % 修炼
        		?true 			= is_record(Player5, player),
        		Player7     	= player_api:login(Player6),        	                        % 人物
        		?true 			= is_record(Player7, player),
        		Player8			= mind_api:login(Player7),										% 心法
        		?true 			= is_record(Player8, player),
        		Player9     	= bless_api:login(Player8),                                     % 祝福
        		?true 			= is_record(Player9, player),
        		Player10    	= furnace_api:login(Player9),		                            % 作坊
        		?true 			= is_record(Player10, player),
        		Player11    	= mcopy_api:login(Player10),                                    % 多人副本
        		?true 			= is_record(Player11, player),
        		Player12		= partner_api:login(Player11),									% 武将寻访
        		?true 			= is_record(Player12, player),
        		Player13    	= copy_single_api:login(Player12),                              % 单人副本
        		?true 			= is_record(Player13, player),
        		Player14    	= relation_api:login(Player13), 	      						% 好友
        		?true 			= is_record(Player14, player),
        		Player15    	= ctn_bag2_api:login(Player14),                                 % 背包
        		?true       	= is_record(Player15, player),
        		Player16    	= new_serv_api:login(Player15),                                 % 新服活动
				?true       	= is_record(Player16, player),
        		Player17 		= player_attr_api:refresh_attr(Player16), 	                    % 属性
        		?true 			= is_record(Player17, player),
        		Player18		= achievement_api:login(Player17),								% 成就/称号
        		?true			= is_record(Player18, player),
				Player19 		= single_arena_api:login(Player18),								% 竞技场
        		?true       	= is_record(Player19, player),
				Player20 		= invasion_api:login(Player19),									% 异民族
        		?true       	= is_record(Player20, player),
                Player21        = task_api:login(Player20),                                     % 任务
                ?true           = is_record(Player21, player),
                Player22        = welfare_deposit_api:login(Player21),                          % 充值礼包
                ?true           = is_record(Player22, player),
				Player23        = weapon_api:login(Player22),                          			% 神兵
                ?true           = is_record(Player23, player),
				Player24        = horse_api:login(Player23),                          			% 坐骑
				?true           = is_record(Player24, player),
				Player25		= robot_world_api:login(Player24),								% 乱天下
                ?true           = is_record(Player25, player),
				%% Player25        = welfare_api:login_init(Player24),                          % 再战沙场活动
                %% ?true           = is_record(Player25, player),
        		{?ok, Player26} = player_api:vip(Player25, player_api:get_vip_lv(Player25)),	% 初始化VIP
                ?true           = is_record(Player26, player),
        		Player27        = welfare_fund_api:login(Player26),
                ?true           = is_record(Player27, player),
				{?ok, Player28} = schedule_api:login(Player27),									% 课程表
                ?true           = is_record(Player28, player),
				Player29        = archery_api:get_history_reword(Player28),            			% 辕门射击
                ?true           = is_record(Player29, player),
                Player30        = teach_api:login(Player29),                                    % 教学
                ?true           = is_record(Player30, player),
				Player31		= furnace_chest_api:fix_hide_flags(Player30),					% 装备衣柜
				?true			= is_record(Player31, player),
                Player32        = mod_tencent_api:login(Player31),
                ?true           = is_record(Player32,player),
%% 				Player32		= act_bhv:login(Player31),					                   % 装备衣柜
%% 				?true			= is_record(Player32, player),
				NewPlayer       = Player32,
        		
                mod_tencent:get_vip_info(NewPlayer),

        		% 不影响到玩家信息的初始化操作
        		rank_api:login(NewPlayer),
        		tower_api:login(NewPlayer),														% 破阵
%%         		group_api:login(NewPlayer#player.user_id),				       					% 常规组队
				encroach_api:login(NewPlayer),													% 攻城掠地
				shop_secret:login(NewPlayer),													% 云游商人
                team_login_api:login(NewPlayer#player.user_id),                                 % 上线后清除多人组队关系
				mixed_serv_api:on_login(NewPlayer),													% 合服活动
				gamble_api:on_login(NewPlayer),                                                         % 青梅煮酒
				hundred_serv_api:login(NewPlayer),     %百服活动
				?ok = yunying_activity_api:init_yunying_activity_after_login(NewPlayer),        % 上线后初始化运营活动
				catch act_bhv:login(NewPlayer), %活动机制
%%                 yunying_activity_api:activity_read_db_login(NewPlayer),               %玩家上线初始化运营，双旦活动数据，和下面的调用不能乱顺序
%%                 yunying_activity_api:init_shuangdan_login(NewPlayer),                      %双旦活动上线初始化
%%                 yunying_activity_api:init_activity_online_award(NewPlayer),          %运营活动在线得奖励，上线时处理
%%                 yunying_activity_mod:card_exchange_partner_read_db_login(NewPlayer),      %抽卡换武将玩家上线时处理
                {_,_,StatePlay} = player_state_api:get_state(NewPlayer),
                case (StatePlay == ?CONST_PLAYER_PLAYER_CAMP_PVP andalso camp_pvp_mod:check_camp_open() == false) of
                    true ->
                        NewPlayer2 = map_api:enter_map(NewPlayer, 10001),
                        case player_state_api:try_set_state_play(NewPlayer2,?CONST_PLAYER_PLAY_CITY) of
                            {?true,NewPlayer1} ->
                                void;
                            {?false,NewPlayer1,Tips} ->
                                ?MSG_ERROR("change state err ~p",[Tips])
                        end;
                    false ->
                        NewPlayer1 = NewPlayer
                end,

                {?ok, NewPlayer1}
        end
	catch
		Type:Error ->
			?MSG_ERROR("Type:~p Error:~p Stack:~p", [Type, Error, erlang:get_stacktrace()]),
			{Type, Error}
	end;
login_init(Player, ?CONST_SYS_FALSE) when is_record(Player, player) -> {?ok, Player};
login_init(_Player, _) -> {?error, ?TIP_COMMON_BAD_ARG}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 创建角色相关,第一次登陆时调用
create(_MsgId, Player, UserName, Pro, Sex) ->
    case player_api:check_name(UserName) of
		?ok ->
			Player2 = create(Player, UserName, Pro, Sex),
			UserId	= Player2#player.user_id,
			Account	= Player2#player.account,
            ServId  = Player2#player.serv_id,
			player_mod:write_player(Player2, ?CONST_SYS_DB_TYPE_CREAT),
            PlayerOnLine = player_api:player_online_data(Player2),
            ets_api:insert(?CONST_ETS_PLAYER_ONLINE, PlayerOnLine),
            player_api:insert_name(UserName, UserId),
			player_api:insert_account(Account, UserId),
			player_api:insert_account_2(Account, ServId, UserId),
            player_api:insert_account_user_id(Account, UserId),
			player_money_api:insert_money(#money{user_id = UserId, account = Account, first_consume = ?CONST_SYS_FALSE}),
			{?ok, Player2};
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 玩家的初始属性
create(Player = #player{user_id = UserId, serv_id = ServId, account = Account}, UserName, Pro, Sex) ->
    #rec_player_init{
					 bag   = InitBag,
                     camp  = InitCamp,
                     sys   = Sys,
                     task  = InitTask,
                     task_2 = InitTask2
					} 				= data_player:get_player_init({Pro, Sex}),
	#player{
				info             	= Info,      		% [first]积累信息#info{}
	            buff                = Buff,             % [first]buff
				attr				= Attr,				% [first]角色属性#attr{}
%% 			    pet              	= Pet,           	% [first]灵兽#pet_data{}
				skill            	= SkillData,    	% [first]技能#skill_data{}
				position         	= Position,     	% [First]官衔#position_data{}
%% 				partner   		 	= PartnerData,	 	% [first]武将#partner_data{}
				partner_soul		= PartnerSoul,		% [first]将魂
				guild              	= Guild,     		% [First]帮派#guild{}
				tower				= Tower,			% [First]破阵
				sys_rank            = Sys,            	% [first]开放系统
                style               = StyleData,        % [First]外形
				
				bag              	= Bag,        		% [second]背包#ctn{}
				depot            	= Depot,         	% [second]仓库#ctn{}
				temp_bag         	= TempBag, 			% [second]临时背包#ctn{}
	            maps                = MapData,          % [Second]开放地图ID列表[]
				copy             	= Copy,          	% [second]副本#copy_data{}
				ability				= AbilityData,		% [Second]内功#ability_data{}
				achievement      	= Achievement,   	% [second]成就#achievement{}
				resource			= Resource,			% [second]资源#resource{}
				train    			= Train,			% [second]培养属性
				spring				= Spring,			% [second]温泉属性
				furnace				= Furnace,			% [second]炼炉属性
				guide				= Guide,	  		% [second]新手指引#guide_data{}
	            invasion            = Invasion,         % [second]异民族#invasion_data{}
				schedule			= Schedule,		    % [second]课程表系统
	            bless               = Bless,            % [second]祝福#bless_data{}
                teach               = Teach,             % [second]教学#teach_data{}
                tencent             = Tencent
			} = data_player_template:get_player_template({Pro, Sex}),
	
    IsA           = 
        case config:read(server_info, #rec_server_info.newbie) of
            1 ->
                1;
            2 ->
                0;
            3 ->
                misc_random:random(0, 1)
        end,
    
    % first
    IsDraw        = center_api:is_elder(Account, ServId),
    Info2         = 
        case IsA of
            1 ->
    	        Info#info{user_name = UserName, date = misc:date_num(), is_draw = IsDraw};	   % 玩家信息
            0 ->
                Info#info{user_name = UserName, date = misc:date_num(), is_draw = IsDraw, is_newbie = 10}
        end,
	Equip 		  = ctn_equip_api:create(UserId),                                  % 装备
    CampData      = camp_api:init(UserId, Pro, InitCamp),                          % 阵法
	Mind		  = mind_api:create_mind(UserId),                                  % 心法
	PartnerData   = partner_api:create_partner_data(),                             % 武将
	MCopyData     = mcopy_api:init(),                                              % 多人副本

    % second
	Copy2		  = 
        case IsA of
            1 ->
                copy_single_api:init(Copy);									   % 副本
            0 ->
                Copy_2 = copy_single_api:init([]),
                copy_single_api:init(Copy_2)
    end,
	Lottery		  = lottery_api:initial_player_lottery(UserId),                    % 宝箱
    Invasion2	  = invasion_api:init(Invasion),								   % 异民族
	Welfare       = welfare_api:init_player_welfare(UserId),					   % 福利
	NewServ		  = new_serv_api:init(),										   % 首服活动
	Weapon		  = weapon_api:create(),									  	   % 神兵
	Lookfor		  = partner_api:create_lookfor_data(),							   % 寻访
    HorseData     = horse_api:init(),                                              % 坐骑
    FundDataList  = welfare_fund_api:init(),
	ctn_bag2_api:init_set_list_log(0, InitBag, 0),   %% 初始投入物品日志

    Task          = 
        case IsA of
            1 ->
                task_api:create(InitTask);                                     % 任务
            0 ->
                task_api:create(InitTask2)
        end,
	
	Player2			= Player#player{
									info             	= Info2,      		% [first]积累信息#info{}
                                    buff                = Buff,             % [first]buff
									attr				= Attr,			    % [first]角色属性#attr{}
									equip       		= Equip,			% [first]装备#ctn{}
%% 									pet              	= Pet,           	% [first]灵兽#pet_data{}
									skill            	= SkillData,    	% [first]技能#skill_data{}
									position         	= Position,     	% [First]官衔#position_data{}
									partner   		 	= PartnerData,	 	% [first]武将#partner_data{}
									partner_soul		= PartnerSoul,		% [first]将魂
									guild              	= Guild,     		% [First]帮派#guild{}
                                    camp                = CampData,         % [First]阵法#camp_data{}
									mind				= Mind,				% [first]心法#mind_data{}
									tower				= Tower,            % [first]破阵
									sys_rank            = Sys,            	% [first]开放系统
                                    style               = StyleData,        % [first]外形
									
									bag              	= Bag,        		% [second]背包#ctn{}
									depot            	= Depot,         	% [second]仓库#ctn{}
									temp_bag         	= TempBag,       	% [second]临时背包#ctn{}
                                    maps                = MapData,          % [Second]开放地图ID列表[]
									task             	= Task,          	% [second]任务#task_data{}
									copy             	= Copy2,          	% [second]副本#copy_data{}
									ability				= AbilityData,		% [Second]内功#ability_data{}
									achievement      	= Achievement,   	% [second]成就#achievement{}
									resource			= Resource,			% [second]资源#resource{}
									train    			= Train,			% [second]培养属性
									lottery				= Lottery,			% [second]淘宝属性
									spring				= Spring,			% [second]温泉属性
									furnace				= Furnace,			% [second]炼炉属性
									guide				= Guide,	  		% [second]新手指引#guide_data{}
                                    invasion            = Invasion2,        % [second]异民族#invasion_data{}
									schedule			= Schedule,		    % [second]课程表系统
                                    bless               = Bless,            % [second]祝福#bless_data{}
                                    mcopy               = MCopyData,        % [second]多人副本#mcopy_data{}
									welfare				= Welfare,			% [second]福利系统#welfare{}
									new_serv			= NewServ,			% [second]首服活动#new_serv{},
									weapon				= Weapon,			% [second]神兵
									lookfor				= Lookfor,			% [second]寻访#lookfor_data{}
                                    horse               = HorseData,        % [second]坐骑#horse_data{}
                                    fund                = FundDataList,     % [second]基金[]
                                    teach               = Teach,             % [second]教学#teach_data{}
                                    tencent             = Tencent
								   },
	Player3 =  welfare_api:login_init(Player2),        
	player_attr_api:refresh_attr(Player3).

%% #info封装
create_info(RecPlayerInit) ->
    % player_init
    #rec_player_init{sex = Sex, pro = Pro, lv = Lv, skill_point = SkillPoint, skip = SkipTimes} = RecPlayerInit,
    % player_level
    PlayerLevel = data_player:get_player_level({Pro, Lv}),
	#player_level{exp_next = ExpNext, sp_max = SpMax,
                  attr = #attr{attr_second = #attr_second{hp_max = HpMax}}} = PlayerLevel,
	Today		= misc:date_num(),
    % 组装
	#info{
		  attr_rate			= ?CONST_SYS_NUMBER_TEN_THOUSAND,			% 属性系数
		  pro               = Pro,                                      % 职业
		  sex              	= Sex,                                      % 性别
		  country			= ?CONST_SYS_COUNTRY_DEFAULT,				% 国家  0：无国家|1：魏国|2：蜀国|3:吴国
          lv                = Lv,                                       % 等级
		  exp               = 0,            							% 经验值：玩家升级的一种方式
		  expn              = ExpNext,                                  % 下级要多少经验
		  expt              = 0,            							% 总共集了多少 经验
		  hp                = HpMax,                                    % 生命值（现有）
		  sp                = SpMax,                                    % 体力值（现有）
		  sp_temp           = 0,                                        % 体力值（临时）
		  vip				= #vip{},           	 					% #vip{}

		  honour			= 0,			                            % 荣誉(原：成就点)
		  meritorious		= 0,            		                    % 军功(原：阅历/历练)
		  exploit           = 0,                                        % 功勋(原：军团贡献度)
		  skill_point		= SkillPoint,			                    % 武魂(原：技能点)
		  experience		= 0,										% 培养值
		  power 			= 0,   		                                % 战力
		  anger             = 0,			                            % 怒气
		  buy_point			= 0,										% 购买积分

		  cultivation       = 0,            							% 修为值
		  gifts				= [],										% 领取过的礼包类型列表
		  gift_cash			= ?false,									% 是否领取过登陆赠送元宝
		  date				= Today,									% 刷新数据日期
          free_skip_times   = SkipTimes,
          is_newbie         = ?CONST_SYS_TRUE
		 }.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家下线处理
logout(Player) ->
    try
        {?ok, Player2}		= team_api:logout(Player),                  % 多人组队
        guild_api:logout(Player2), 					                    % 军团退出
    	practice_api:logout(Player2),				                    % 修炼
    	rank_api:logout(Player2),                                       % 排行榜
%%     	group_api:logout(Player2),										% 常规组队
    	commerce_api:logout(Player2),                                   % 商路
        home_api:logout(Player2),										% 家园
		schedule_api:logout(Player2),									% 每日资源找回
    	%% collect_api:logout(Player2),                                 % 采集				
		bless_api:logout(Player2),										% 祝福	
        camp_pvp_api:player_logout(Player2#player.user_id),             % 阵营战
        guild_pvp_api:player_logout(Player2#player.user_id),            % 阵营战
		snow_api:logout(Player2#player.user_id),						% 雪夜赏灯
        Player3 			= task_api:logout(Player2),  		        % 玩家退出时，刷新任务数据
    	{?ok, Player4}		= spring_api:logout(Player3),               % 玩家退出，处理温泉数据
    	{?ok, Player5}		= battle_api:offline(Player4),              % 战斗阻止广播
        Player6 			= copy_single_api:logout(Player5),          % 单人副本
    	Player7				= welfare_api:logout(Player6),              % 福利
    	{?ok, Player8}		= invasion_api:logout(Player7),             % 异民族
        Player9 			= relation_api:logout(Player8),        	 	% 好友
		{?ok, Player10}		= boss_api:logout(Player9),					% 世界BOSS
		{?ok, Player11}		= world_api:logout(Player10),				% 乱天下
		{?ok, Player12} 	= party_api:logout(Player11), 				% 宴会
		Player13			= mcopy_api:logout(Player12),				% 多人副本
%%         Player14            = act_bhv:logout(Player13),                 % 运营活动
    	map_api:logout(Player13), 					                    % 地图退出
    	welfare_fund_api:logout(Player13), 					            % 基金
		encroach_api:logout(Player13),									% 攻城掠地
		shop_secret:logout(Player13),									% 云游商人
        teach_api:logout(Player13),                                     % 教学关卡
        mod_tencent_api:logout(Player13),
		archery_api:save_archery(Player13),         %辕门射击
		mixed_serv_api:on_logout(Player13),             % 合服活动
		gamble_api:on_logout(Player13), 				% 青梅煮酒
		hundred_serv_api:logout(Player13),           % 百服活动
		catch act_bhv:logout(Player13),        %活动机制
    	{?ok, Player13}
    catch 
        X:Y ->
            ?MSG_ERROR("X=~p, y=~p, x=~p", [X, Y, erlang:get_stacktrace()]),
            {?ok, Player}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 登陆后直接发的协议
login_packets(Player) ->
    F = fun(Module, {OldPlayer, OldPacket}) ->
                Module:login_packet(OldPlayer, OldPacket)
        end,
    
    gun_award_api:login_check(Player),
    {Player3, Packet3} = lists:foldl(F, {Player, <<>>}, ?LOGIN_PACKET_LIST),
    PacketOffline = Player#player.offline_packet,
    Packet4 = <<Packet3/binary, PacketOffline/binary>>,
    {?ok, Player3#player{offline_packet = <<>>}, Packet4}.

%% 获取账号
get_account(Account, Pid, Time) ->
	misc:to_list(Account) ++ pid_to_list(Pid) ++ misc:to_list(Time).

%% ================================== 游客模式 ===========================================================================
get_guest_info(UserId) ->
    {Pro, Sex} = get_guest_pro_sex(),
    {
     get_guest_name(UserId),
     Pro, 
     Sex
    }.

%% 游客名
get_guest_name(UserId) ->
	list_to_binary("游_" ++ misc:to_list(UserId)).

get_guest_pro_sex() ->
	case ets_api:lookup(?CONST_ETS_SYS, pro_sex) of
		?null ->
			{Pro, Sex} = get_next_pro_sex(?null),
			ets_api:insert(?CONST_ETS_SYS, {pro_sex, {Pro, Sex}}),
			{Pro, Sex};
		{_, X} ->
			{Pro, Sex} = get_next_pro_sex(X),
			ets_api:insert(?CONST_ETS_SYS, {pro_sex, {Pro, Sex}}),
			{Pro, Sex}
	end.

get_next_pro_sex(?null)   -> {?CONST_SYS_PRO_XZ, ?CONST_SYS_SEX_MALE};
get_next_pro_sex({?CONST_SYS_PRO_XZ, ?CONST_SYS_SEX_MALE})   -> {?CONST_SYS_PRO_FJ, ?CONST_SYS_SEX_FAMALE};
get_next_pro_sex({?CONST_SYS_PRO_FJ, ?CONST_SYS_SEX_FAMALE}) -> {?CONST_SYS_PRO_TJ, ?CONST_SYS_SEX_MALE};
get_next_pro_sex({?CONST_SYS_PRO_TJ, ?CONST_SYS_SEX_MALE})   -> {?CONST_SYS_PRO_XZ, ?CONST_SYS_SEX_MALE}.
