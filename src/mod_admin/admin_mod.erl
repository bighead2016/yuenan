%% Author: michael
%% Created: 2012-10-13
%% Description: admin funs
-module(admin_mod).
%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("../../include/record.task.hrl").
%%
%% Exported Functions
-compile([export_all]).
%%
-export([treat_admin_cast/2, check_ip/1, http_recv/1, treat_http_request/2, chinese_to_bin/1,do_multifunction/1,flush_offline/2,flush_online_2/2]).
-export([convert_date/1, convert_time/1, convert_date_time/1]).
-export([do_deposit/7, set_player_state/2, white_ip_list/0, do_forbid_login2/3]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 充值需要调用 welfare_api:deposit(UserId, Vip, CurSum, AccSum)，记录日志到数据库log_deposit，技术中心第二版接口未给出该需求，待定

%% 处理HTTP请求
treat_http_request(Socket, [http_request, 'GET', {abs_path, RequestBin}, _Version]) ->
	try
		{CMD, KVList}			= get_cmd_parm(RequestBin),
		{_Status, _Len, Result} = do_handle_request(CMD, KVList),
		send_data(Socket, Result, ?HTTP_CODE_200),
		Ret = case _Len of
				  Len when Len > 50 ->
					  "length above 50,not recorded";
				  _ ->
					  Result
			  end,
		% ?MSG_ERROR("Result = ~p~n Ret = ~w",[Result,Ret]),
		Status = case _Status of
					 ?true ->
						 1;
					 ?false ->
						 0
				 end,
		admin_log_api:log_link(misc:seconds(), RequestBin, Ret, Status),
		?ok
	catch
		What:Why ->
			?MSG_ERROR("What ~p, Why ~p, ~p", [What, Why, erlang:get_stacktrace()]),
			{What, Why}
	end;
treat_http_request(Socket, [http_request, 'POST', _Request, _Version]) ->
	try
        ?MSG_ERROR("1", []),
		Length 					= get_content_length(Socket),
		Msg						= get_post_data(Socket, Length,20),
		{CMD, KVList}			= get_cmd_parm(Msg),
		{_Status, _Len, Result} = do_handle_request(CMD, KVList),
		?MSG_ERROR("Result = ~p",[Result]),
		send_data(Socket, Result, ?HTTP_CODE_200),
		?ok
	catch
		What:Why ->
			?MSG_ERROR("What ~p, Why ~p, ~p", [What, Why, erlang:get_stacktrace()]),
			{What, Why}
	end;
treat_http_request(Socket, Request) ->
	?MSG_ERROR("bad request: ~p", [Request]),
	send_data(Socket, "bad request: " ++ misc:encode(Request), ?HTTP_CODE_400),
	?ok.

get_cmd_parm(Packet) ->
	List = misc:to_list(Packet),
	try
		?MSG_DEBUG("~n get_cmd_param:Packet=~p", [Packet]),
		case string:str(List, "?") of
			0 -> {no_cmd, []};
			N ->
				CMD 		= string:substr(List, 2, N - 2),
				KVList		= total_params(List),
				KeyValue	= key_value_list(List),
				set_kv_list(KeyValue),
				{CMD, KVList}
		end
	catch
		_:_ -> 
			{no_cmd, []}
	end.

get_content_length(Socket) ->
	case gen_tcp:recv(Socket, 0, ?HTTP_TIMEOUT) of
		{ok, {http_header, _, 'Content-Length', _, Length}} ->
			misc:to_integer(Length);
		{ok, {http_header, _, _Header, _, _}} ->
			get_content_length(Socket);
		_ -> 
			0
	end.

get_post_data(Socket, Length, 0) ->
	"";
get_post_data(Socket, Length, Times) ->
	case gen_tcp:recv(Socket, 0) of
		{ok, http_eoh} ->
			inet:setopts(Socket, [{packet, raw}]),
			case gen_tcp:recv(Socket, Length) of
				{ok,Data} ->
					misc:decode(Data);
				Other ->
					?MSG_ERROR("get post data fail with ~p", [Other]),
					""
			end;
		Else ->
			case Times == 1 of
				true ->
					?MSG_ERROR("get post data fail with ~p | ~p", [Else,Socket]);
				false ->
					void
			end,
			get_post_data(Socket, Length,Times -1)
	end.
send_data(Socket, Data, HttpCode) ->
	Data2 			= misc:to_binary(Data),
	HttpCode2 		= misc:to_binary(HttpCode),
	ResponseHeader	= <<"HTTP/1.1 ", HttpCode2/binary, " OK\r\n\r\n">>,
	gen_tcp:send(Socket, <<ResponseHeader/binary, Data2/binary>>),
	gen_tcp:close(Socket).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% http://deposit?pay_num=11111&account=11111&money=11111&cash=11111&order_type=&time=11111&pay_type=11111
%% 玩家充值
do_handle_request("deposit", KVList) ->
	?MSG_DEBUG("DEPOSIT INTO GAME KVList:~p", [KVList]),
	LoginCheckMode = config:read(platform_info, #rec_platform_info.login_check),
	?MSG_DEBUG("LoginCheckMode:~p", [LoginCheckMode]),
	case LoginCheckMode of
		?CONST_SYS_LOGIN_CHECK_TENCENT ->
			?MSG_DEBUG("do tencent deposit", []),
			case mod_tencent:deposit_check() of
				{true,UserId} ->
					case do_deposit() of
						?ok -> 
							?MSG_ERROR("DEPOSIT KVList:~p", [KVList]),
							Ret = 0,
							Reply = {?true, 1, "{\"ret\":0,\"msg\":\"OK\"}"}; % 充值成功
						{?error, ?TIP_PLAYER_DEPOSIT_REPEAT} -> 
							Ret = 4,
							Reply = {?false, 1, "{\"ret\":4,\"msg\":\"订单号重复\"}"}; % 订单号重复
						{?error, ?TIP_COMMON_NO_THIS_PLAYER} -> 
							Ret = 4,
							Reply = {?false, 1, "{\"ret\":4,\"msg\":\"该账号尚无角色\"}"}; % 该账号尚无角色
						{?error, ErrorCode} ->
							?MSG_ERROR("ErrorCode:~p", [ErrorCode]),
							Ret = 4,
							Reply = {?false, 1, "{\"ret\":4,\"msg\":\"系统错误\"}"}
					end;
				{false,UserId} ->
					Ret = 2,
					Reply = {?false, 1, "{\"ret\":2,\"msg\":\"token已过期\"}"}
			end,
			case UserId > 0 of
				true ->
					erlang:send_after(7*1000, self(), {confirm_delivery,UserId,
							mod_tencent:make_agrs(["amt","billno","version","zoneid","payamt_coins"])++[{"token_id",get("token")},{"provide_errno",Ret},{"ts",misc:to_list(misc:seconds()+9)}]});
				false ->
					void
			end,
			Reply;
		?CONST_SYS_LOGIN_CHECK_NONE ->
			mod_tencent:deposit_check_none(),
			case do_deposit() of
				?ok -> 
					?MSG_ERROR("DEPOSIT KVList:~p", [KVList]),
					Ret = 0,
					Reply = {?true, 1, "1"}; % 充值成功
				{?error, ?TIP_PLAYER_DEPOSIT_REPEAT} -> 
					Ret = 4,
					Reply = {?false, 1, "-6"}; % 订单号重复
				{?error, ?TIP_COMMON_NO_THIS_PLAYER} -> 
					Ret = 4,
					Reply = {?false, 1, "-5"}; % 该账号尚无角色
				{?error, ErrorCode} ->
					?MSG_ERROR("ErrorCode:~p", [ErrorCode]),
					Ret = 4,
					Reply = {?false, 1, "-7"}
			end;
		_ ->
			?MSG_DEBUG("do else deposit", []),
			case do_deposit() of
				?ok -> ?MSG_ERROR("DEPOSIT KVList:~p", [KVList]), {?true, 1, "1"}; % 充值成功
				{?error, ?TIP_PLAYER_DEPOSIT_REPEAT} -> {?false, 1, "2"}; % 订单号重复
				{?error, ?TIP_COMMON_NO_THIS_PLAYER} -> {?false, 1, "-3"}; % 该账号尚无角色
				{?error, ErrorCode} ->
					?MSG_ERROR("ErrorCode:~p", [ErrorCode]),
					{?false, 1, "-1"}
			end
	end;

do_handle_request("v3task",KVList) ->
	?MSG_DEBUG("MARKET INTO GAME KVList:~p", [KVList]),
	mod_tencent:do_market();


%% 消息广播
do_handle_request("send_sys_bulletin", KVList) ->
	MsgType		= get_value("msg_type"),
	Flag 		= get_value("flag"),
	Content		= http_uri:decode(get_value("content")),
	case string:to_upper(misc:md5(KVList)) of
		Flag ->
			case misc:to_integer(MsgType) of
				1 -> %聊天栏
%% 					?MSG_ERROR("~nsend_sys_bulletin~nKVList:~s~nContent:~s~n", [KVList, Content]),
					Packet = misc_packet:pack(?MSG_ID_CHAT_SC_SYS, ?MSG_FORMAT_CHAT_SC_SYS, [1, Content, 1, 0]),
					misc_app:broadcast_world_2(Packet),
					{?true, 7, "success"};
				2 -> %顶部滚动
					Packet = misc_packet:pack(?MSG_ID_CHAT_SC_SYS, ?MSG_FORMAT_CHAT_SC_SYS, [1, Content, 1, 0]),
					misc_app:broadcast_world_2(Packet),
					{?true, 7, "success"};
				_Other ->
					{?false, 11, "param_error"}
			end;
		_Other ->
			{?false, 10, "flag_error"}
	end;

%% 发送邮件
do_handle_request("send_mail", KVList) ->
	Flag = get_value("flag"),
	?MSG_DEBUG("send_mail:~p",[Flag]),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_send_mail();
		_Other -> {?false, 10, "flag_error"}
	end;

%% 道具/货币接口 通过邮件发送
do_handle_request("admin_send_gift", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_admin_send_gift();
		Other -> 
		?MSG_ERROR("KVList = ~p,Flag ~p, Other ~p", [KVList,Flag, Other]),

		{?false, 10, "flag_error"}
	end;

%% 查询满足条件的玩家数量
do_handle_request("count_user", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> select_right_users();
		_Other -> {?false, 10, "flag_error"}
	end;

%% 查询满足条件的玩家
do_handle_request("get_users", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_admin_get_user();
		_Other -> {?false, 10, "flag_error"}
	end;

%% 封禁/解封 账号
do_handle_request("forbid_login", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_forbid_login();
		_Other -> {?false, 10, "flag_error"}
	end;

%% 踢人接口
do_handle_request("kick_user", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_kick_user();
		_Other -> {?false, 10, "flag_error"}
	end;

%% GM回复玩家接口
do_handle_request("complain_reply", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag ->
			UserName	= http_uri:decode(get_value("user_name")),
			Content		= http_uri:decode(get_value("content")),
			_CompainId	= get_value("compain_id"),
			mail_api:send_system_mail_to_one2(misc:to_binary(UserName), <<"GM回复">>, misc:to_binary(Content), 0, [], [], 0, 0, 
								0, ?CONST_COST_PLAYER_GM),
			{?true, 7, "success"};
		_Other -> {?false, 10, "flag_error"}
	end;

%% 禁言 / 解禁
do_handle_request("ban_chat", KVList) ->
	Flag  = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_chat_ban();
		_Other -> {?false, 10, "flag_error"}
	end;

%% 新手指导员接口
do_handle_request("game_instructor_manage", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_game_instructor_manage();
		_ -> {?false, 10, "flag_error"}
	end;

%% 玩家信息列表接口
do_handle_request("user_info_list", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_user_info_list();
		_ -> {?false, 10, "flag_error"}
	end;

%% 单个玩家详细信息接口
do_handle_request("user_info_detail", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_user_info_detail();
		Other ->
			?MSG_DEBUG("Flag ~p, Other ~p", [Flag, Other]),
			{?false, 10, "flag_error"}
	end;

%% 玩家帮派信息列表
do_handle_request("guild_info_list", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_guild_info_list();
		_ -> {?false, 10, "flag_error"}
	end;

%% 单个军团详细信息接口
do_handle_request("guild_info_detail", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_guild_info_detail();
		_ -> {?false, 10, "flag_error"}
	end;

%% 刷新在线玩家信息
do_handle_request("freshen_online_user", KVList) ->
	Flag 	= get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag ->
			Online		= player_api:total_online(),
			OnlineBin 	= misc:to_binary(Online),
			Result 		= rfc4627:encode({obj, [{"state", <<"success">>},
												{"desc", <<"null">>},
												{"data", OnlineBin}]}),
			{?true, length(Result), Result};
		_ -> {?false, 10, "flag_error"}
	end;

%% 玩家道具查询(坐骑是装备的一种)
do_handle_request("user_props_list", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_user_props_list();
		_ -> {?false, 10, "flag_error"}
	end;

%% 玩家技能查询接口
do_handle_request("user_skill_list", KVList) ->
	Flag = get_value("flag"),
	case string:to_upper(misc:md5(KVList)) of
		Flag -> do_user_skill_list();
		_ -> {?false, 10, "flag_error"}
	end;

%% 单个玩家设置vip接口
do_handle_request("set_vip", KVList) ->
    Flag = get_value("flag"),
    case string:to_upper(misc:md5(KVList)) of
        Flag -> 
            do_set_vips();
        Other ->
            ?MSG_DEBUG("Flag ~p, Other ~p", [Flag, Other]),
            {?false, 10, "flag_error"}
    end;

%% 改变玩家各类money金额
do_handle_request("money_change", KVList) ->
	Flag = get_value("flag"),
    case string:to_upper(misc:md5(KVList)) of
        Flag -> 
            do_change_money();
        Other ->
            ?MSG_DEBUG("Flag ~p, Other ~p", [Flag, Other]),
            {?false, 10, "flag_error"}
    end;

%% 泛功能接口
do_handle_request("multifunction", KVList) -> 
	Flag = get_value("flag"),
    case string:to_upper(misc:md5(KVList)) of
        Flag -> 
            do_mutilfunction();
        Other ->
            ?MSG_DEBUG("Flag ~p, Other ~p", [Flag, Other]),
            {?false, 10, "flag_error"}
    end;











%% 1 重置玩家位置：很可能玩家已经卡死，踢下线即可

%% 不识别的指令？
do_handle_request(Other, KVList) ->
    ?MSG_ERROR("admin unknown cmd  ~p, ~p", [Other, KVList]),
    {?false, 11, "param_error"}.

%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
do_deposit() ->% pay_num account money cash time pay_pype
	PayNum		= get_value("pay_num"),
	Account 	= misc:to_binary(http_uri:decode(get_value("account"))),
	Money		= 0, % misc:to_integer(get_value("money")),
	Cash		= misc:to_integer(get_value("cash")),
	Time		= misc:to_integer(get_value("time")),
	PayType		= misc:to_integer(get_value("pay_type")),
    ServId      = misc:to_integer(get_value("serv_id")),
	do_deposit(PayNum, Account, Money, Cash, Time, PayType, ServId).
do_deposit(PayNum, Account, Money, Cash, Time, PayType, ServId) ->
	% ?MSG_ERROR("{PayNum, Account, Money, Cash, Time, PayType}~n=~p", [{PayNum, Account, Money, Cash, Time, PayType}]),
	Point	= ?CONST_COST_PLAYER_DEPOSIT,
	case player_money_api:deposit(PayNum, Account, Money, Cash, Time, PayType, Point, ServId) of
		?ok -> ?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

%% 查询符合条件的玩家列表
do_admin_get_user() ->
	Action		= misc:to_integer(get_value("action")),
	UserNames	= string:tokens(http_uri:decode(get_value("user_names")), ","),
	UserIds		= string:tokens(http_uri:decode(get_value("user_ids")), ","),
	MinLv		= get_value("min_lv"),
	MaxLv		= get_value("max_lv"),
	MinLoginTime= get_value("min_login_time"),
	MaxLoginTime= get_value("max_login_time"),
	_MinRegTime	= get_value("min_reg_time"),
	_MaxRegTime	= get_value("max_reg_time"),
	_Sex		= get_value("sex"),
	_Career		= get_value("career"),
	GuildName	= get_value("guild"),
	_VipType	= get_value("viptype"),
	UserNameList= get_user_name_condition_2([MinLv, MaxLv, MinLoginTime, MaxLoginTime,
                                  _MinRegTime, _MaxRegTime, _Sex, _Career, GuildName,_VipType]).



%% 给符合条件的玩家列表发货币/道具邮件
do_admin_send_gift() ->
	OrderId		= get_value("orderid"),
	case ets_api:lookup(?CONST_ETS_ADMIN_ORDER_MAIL, OrderId) of
		?null ->
			ets_api:insert(?CONST_ETS_ADMIN_ORDER_MAIL, {OrderId, []}),
			Action		= misc:to_integer(get_value("action")),
			UserNames	= string:tokens(http_uri:decode(get_value("user_names")), ","),
			AccountIds  = string:tokens(http_uri:decode(get_value("account_ids")), ","),
			UserIds		= string:tokens(http_uri:decode(get_value("user_ids")), ","),
			MinLv		= get_value("min_lv"),
			MaxLv		= get_value("max_lv"),
			MinLoginTime= get_value("min_login_time"),
			MaxLoginTime= get_value("max_login_time"),
			_MinRegTime	= get_value("min_reg_time"),
			_MaxRegTime	= get_value("max_reg_time"),
			_Sex		= get_value("sex"),
			_Career		= get_value("career"),
			GuildName	= get_value("guild"),	
			MailTitle	= http_uri:decode(get_value("mail_title")),
			MailContent	= http_uri:decode(get_value("mail_content")),
			MoneyAmount = string:tokens(http_uri:decode(get_value("money_amounts")), ","),
			MoneyType 	= string:tokens(http_uri:decode(get_value("money_types")), ","),
			ItemIds		= string:tokens(http_uri:decode(get_value("item_ids")), ","),
			ItemTypes	= string:tokens(http_uri:decode(get_value("item_types")), ","),
			ItemCounts	= string:tokens(http_uri:decode(get_value("item_counts")), ","),
			_ItemLevels	= string:tokens(http_uri:decode(get_value("item_levels")), ","),
			_VipType	= get_value("viptype"),
			UserNameList=
				case Action of
					0 -> get_user_name_list();
					1 ->	%%user_names user_ids
						UserNames2 = lists:map(fun(N) -> misc:to_binary(http_uri:decode(N)) end, UserNames),
						UserNames3 = lists:append(user_name_from_id(UserIds), UserNames2),
						lists:append(user_name_from_account_id(AccountIds),UserNames3);
					2 -> 
                        get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime,
                                          _MinRegTime, _MaxRegTime, _Sex, _Career, GuildName,_VipType]);
%%                         get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime, GuildName]);
					3 -> player_api:all_user_online();
					_ -> []
				end,
%%             io:format("UserNameLIst:~p~n",[UserNameList]),
			?MSG_ERROR("UserIds = ~p,~nUserNames = ~p,~nUserNameList=~p~n", [UserIds,UserNames,UserNameList]),
            
            {Cash, Gold, BCash, BCash2}= get_money_list(MoneyType, MoneyAmount),
%%             if BCash2 > 0 ->
%%                    FunBC2 = fun(UserName) ->
%%                                     case player_api:get_user_id(UserName) of 
%%                                         {?ok, UserId} ->
%%                                             case player_api:check_online(UserId) of
%%                                                 ?true ->
%%                                                     player_api:process_send(UserId, ?MODULE, flush_online_2, {UserId,BCash2});
%%                                                 _ -> 
%%                                                     %% 玩家离线时.
%%                                                     player_offline_api:offline(?MODULE, UserId, {UserId,BCash2})
%%                                             end;
%%                                         {?error, ?TIP_COMMON_NO_THIS_PLAYER}->
%%                                             pass
%%                                     end
%%                             end,
%%                    lists:map(FunBC2, UserNameList);
%%                ?true ->
%%                    ?ok
%%             end,
            GoodsList	= get_goods_list(ItemIds, ItemTypes, ItemCounts),
%% 			?MSG_DEBUG("get_goods_list~p~n~p~n",[[ItemIds, ItemTypes, ItemCounts],GoodsList]),
            if 
                (length(ItemIds) =:= length(GoodsList)) ->
                    Fun		= fun(X) -> {X, mail_api:send_system_mail_to_one3(X, MailTitle, MailContent, 0, [], GoodsList, Gold, Cash, 
                                                                              BCash, ?CONST_COST_PLAYER_GM, BCash2)} end,
                    Result	= lists:map(Fun, UserNameList),
                    ets_api:update_element(?CONST_ETS_ADMIN_ORDER_MAIL, OrderId, [{2, Result}]),
                    {?true, 7, "success"};
                ?true -> {?false, 11, "param_error:bad goodid"} % 有物品ID错误
            end;
        _ ->
			{?false, 12, "repeat_order"} % 订单重复
	end.


%% 发离线绑定元宝
flush_offline(Player,{UserId,BCash2}) ->
    try
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, BCash2, ?CONST_COST_PLAYER_GM),
    Player
    catch
        _ -> Player
    end.
%% 发在线元宝
flush_online_2(Player,{UserId,BCash2}) ->
    {?ok,flush_offline(Player,{UserId, BCash2})}.
%% 查询符合条件的玩家数量
select_right_users() ->
    Action		= misc:to_integer(get_value("action")),
    UserNames	= string:tokens(http_uri:decode(get_value("user_names")), ","),
    UserIds		= string:tokens(http_uri:decode(get_value("user_ids")), ","),
    MinLv		= get_value("min_lv"),
    MaxLv		= get_value("max_lv"),
    MinLoginTime= get_value("min_login_time"),
    MaxLoginTime= get_value("max_login_time"),
    _MinRegTime	= get_value("min_reg_time"),
    _MaxRegTime	= get_value("max_reg_time"),
    _Sex		= get_value("sex"),
    _Career		= get_value("career"),
    GuildName	= get_value("guild"),	
	
	case Action of
		1 ->	%%user_names user_ids
			UserNames2 	= lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, UserNames),
			UserIds2	= user_id_from_name(UserNames2),
			
			UserNames3	= user_name_from_id(UserIds),
			Length		= erlang:length(UserIds2) + erlang:length(UserNames3),
			Length2 	= misc:to_list(Length),
			{?ok, erlang:length(Length2), Length2};
		2 ->	%%min~max users
			TotalUserNameList = get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime, GuildName]),
			Length = erlang:length(TotalUserNameList),
			Length2 = misc:to_list(Length),
			{?ok, erlang:length(Length2), Length2}
	end.

%% 封号
do_forbid_login() ->
    UserNames 	= string:tokens(http_uri:decode(get_value("user_names")), ","),
    IsForbid	= get_value("is_forbid"),
    ForbidTime	= get_value("forbid_time"),
    _Reason		= get_value("reason"),

    lists:foreach(fun(UserName) -> do_forbid_login2(http_uri:decode(UserName), IsForbid, ForbidTime)  end, UserNames),
	{?true, 7, "success"}.

do_forbid_login2(UserName, "1", _ForbidDate) ->
%% 	ForbidDate2 = real_forbid_date(misc:to_integer(ForbidDate)),
	case change_player_state(misc:to_binary(UserName), ?CONST_SYS_USER_STATE_FORBID) of
		?ok ->
			case player_api:get_user_id_by_name(misc:to_binary(UserName)) of
				{?ok, UserId} ->
					case player_api:get_player_pid(UserId) of
						Pid when is_pid(Pid) ->
							player_serv:user_logout(Pid),
							{?true, 7, "success"};
						_ -> {?false, 6, "failed"}
					end;
				{?error, _ErrorCode} -> {?false, 6, "failed"}
			end;
		_ -> {?false, 6, "failed"}
	end;
%% 			case player_api:get_player_pid(UserId) of
%% 				Pid when is_pid(Pid) ->
%% 					player_serv:user_ban(Pid, ForbidDate2),
%% 					player_serv:user_logout(Pid),
%% 					{?true, 7, "success"};
%% 				_ ->	%离线玩家 直接更改数据库字段 TODO 离线玩家
%% 					player_api:user_state_db(UserId, ?CONST_SYS_USER_STATE_FORBID),
%% 					{?true, 7, "success"}
%% 			end;
%% 解封
do_forbid_login2(UserName, "0", _ForbidDate) ->
	BinUserName		= misc:to_binary(UserName),
	State			= case player_api:get_user_id_by_name(BinUserName) of
						  {?ok, UserId} ->
							  case player_api:get_player_field(UserId, #player.state) of
								  {?ok,  ?CONST_SYS_USER_STATE_GUIDE} -> ?CONST_SYS_USER_STATE_GUIDE;  %% 原来指导员状态保留
								  _ -> ?CONST_SYS_USER_STATE_NORMAL
							  end;
						  _ -> ?CONST_SYS_USER_STATE_NORMAL
					  end,
	case change_player_state(BinUserName, State) of
		?ok -> {?true, 7, "success"};
		_ -> {?false, 6, "failed"}
	end;
%%     case user_id_from_name([http_uri:decode(UserName)]) of
%% 	[] -> {?false, 6, "failed"};
%% 	[UserId] ->
%% 		
%% 	    case player_api:get_player_pid(UserId) of
%% 		Pid when is_pid(Pid) ->
%% 		    player_serv:user_unban(Pid),
%% 		    {?true, 7, "success"};
%% 		_ ->	%离线玩家 直接更改数据库字段 TODO 离线玩家
%% 		    player_api:user_state_db(UserId, ?CONST_SYS_USER_STATE_NORMAL),
%% 		    {?true, 7, "success"}
%% 	    end;
%% 	_ ->
%% 	    {?false, 10, "flag_error"}
%%     end;
do_forbid_login2(_UserName, _Type, _ForbidDate) ->
    {?false, 10, "flag_error"}.

%% T单个玩家下线
do_kick_user() ->
	UserNames 	= string:tokens(http_uri:decode(get_value("user_names")), ","),
	KickAll		= get_value("kick_all"),
	_Reason		= get_value("reason"),
	case KickAll of
		"0" ->
			lists:foreach(fun(UserName) ->
								  do_kick_user2(misc:to_binary(http_uri:decode(UserName)))
						  end, UserNames),
			{?true, 7, "success"};
		"1" -> do_kick_user3()
	end.
do_kick_user2(UserName) ->
	case user_id_from_name([UserName]) of
		[] ->
			{?false, 6, "failed"};
		[UserId] ->
			case player_api:get_player_pid(UserId) of
				Pid when is_pid(Pid) ->
					player_serv:user_logout(Pid),
					?ok;
				_ ->
					?ok
			end
	end.
%% 踢所有玩家下线
do_kick_user3() ->
	erlang:spawn(fun() -> 
						 ChildList = supervisor:which_children(player_sup),
						 F = fun({_, ChildPid, _, _}) ->
									 player_serv:user_logout(ChildPid)
							 end,
						 lists:foreach(F, ChildList)
				 end),
	{?true, 7, "success"}.

%% 禁言
do_chat_ban() ->
	UserNames 	= string:tokens(http_uri:decode(get_value("user_names")), ","),
	IsBan		= get_value("is_ban"),
	BanDate		= get_value("ban_date"),
	_Reason		= get_value("reason"),
    ?MSG_ERROR("1", []),
	UserNames2  = lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, UserNames),
	UserIds		= user_id_from_name(UserNames2),
	lists:foreach(fun(UserId) -> do_chat_ban(UserId, IsBan, BanDate) end, UserIds),
    ?MSG_ERROR("1", []),
	{?true, 7, "success"}.

do_chat_ban(UserId, "1", BanDate) ->
    ?MSG_ERROR("1", []),
	BanDate2 = real_ban_date(misc:to_integer(BanDate)),
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid) ->
            ?MSG_ERROR("1", []),
			player_serv:user_chat_ban(Pid, BanDate2 - misc:seconds()),
			?ok;
		_ ->
            ?MSG_ERROR("1", []),
			player_db_mod:chat_ban_user(UserId, 1, misc:to_integer(BanDate)),
			?ok
	end;
%% 解除禁言
do_chat_ban(UserId, "0", BanDate) ->
	?MSG_DEBUG("BanDate ~p", [BanDate]),
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid) ->
			player_serv:user_chat_unban(Pid),
			?ok;
		_ ->
			player_db_mod:chat_ban_user(UserId, 0, 0),
			?ok
	end;
do_chat_ban(_UserId, _Type, BanDate) ->
	?MSG_DEBUG("BanDate ~p", [BanDate]),
	?ok.

%% 查询玩家信息列表     TODO 军团/国家信息从ets中取数据进行过滤
do_user_info_list() ->
    Account 	= misc:to_list(get_value("account")),
    IsOnline	= misc:to_integer(get_value("is_online")),
    Ip 			= get_value("last_login_ip"),
    OrderField	= misc:to_list(get_value("order_field")),
    OrderType	= case get_value("order_type") of "0" -> "ASC"; "1" -> "DESC"; _ -> "ASC" end,
    PageNum		= get_value("page_num"),
    PageSize	= get_value("page_size"),
    UserId 		= get_value("user_id"),
	Forbidden = get_value("is_forbid"),
    UserName 	= http_uri:decode(get_value("user_name")),
    do_user_info_list(UserName, UserId, Account, IsOnline, Ip, 
					  OrderField, OrderType, PageNum, PageSize, Forbidden).

do_user_info_list(UserName, UserId, Account, IsOnline, Ip, OrderField, OrderType, PageNumTmp, PageSizeTmp, Forbidden) ->
	Where		= <<" WHERE `user_name` like '", (sql_escape_bin(UserName))/binary, "' AND ",
					"`user_id` like '", (sql_escape_bin(UserId))/binary, "' AND ",
					"`account` like '", (sql_escape_bin(Account))/binary, "' AND ",
					"`exist` <> '", (misc:to_binary(?CONST_SYS_FALSE))/binary, "' ">>,
	WhereExt    = 
		case IsOnline of
			0 ->
				<<"">>;
			1 ->
				<<" and `online_flag` = '1' ">>
		end,
	Order		= if
					  OrderField =:= [] -> <<"">>;
					  ?true -> <<"ORDER BY `", (misc:to_binary(OrderField))/binary, "` ", (misc:to_binary(OrderType))/binary, " ">>
				  end,
	Limit		= if
					  PageNumTmp =:= [] orelse PageSizeTmp =:= [] -> <<"">>;
					  ?true ->
						  PageNum	= misc:to_integer(PageNumTmp), PageSize	= misc:to_integer(PageSizeTmp),
						  <<"LIMIT ", (misc:to_binary((PageNum-1) * PageSize))/binary, ", ", (misc:to_binary(PageSize))/binary>>
				  end,
	IPwhere = if
				  Ip =:= [] ->
					  <<"">>;
				  ?true ->
					  <<" AND `login_ip` = '", (misc:to_binary(Ip))/binary,"'">>
			  end,
	ForbiddenWhere = if
						 Forbidden =:= "1" ->
							 <<" AND `state` = 0 ">>;
						 ?true ->
							 <<>>
					 end,
				  Sql = <<"SELECT `account`, `user_id`, `user_name` , `reg_time`, `lv`,",
						  "`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user` ",
						  Where/binary, WhereExt/binary, IPwhere/binary, ForbiddenWhere/binary, Order/binary, Limit/binary, ";">>,
				  case mysql_api:select_execute(Sql) of
					  {?ok, UserInfoList} ->
			TotalNumber		= case mysql_api:select_execute(<<"SELECT COUNT(*) FROM `game_user` ", Where/binary, WhereExt/binary, ";">>) of
								  {?ok, [[TotalNumberTmp]]} -> TotalNumberTmp;
								  _ -> length(UserInfoList)
							  end,
            
			%% 中文UTF8处理有问题
			Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  {"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")}]},
			?MSG_DEBUG("~nUserInfoList:~p~n", [UserInfoList]),
			UserInfoList2 	= encode_user_info_list(UserInfoList, IsOnline),
			?MSG_DEBUG("~nUserInfoList:~p~n", [UserInfoList2]),
			Result 			= rfc4627:encode({obj, [{"total_number", TotalNumber},
													{"state", <<"success">>},
													{"desc", Desc},
													{"data", UserInfoList2}]}),
			{?true, length(Result), Result};
		_Other ->
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", <<"null">>}, 
										   {"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end.

do_guild_info_single(GuildId)->
	case mysql_api:select_execute(<<"SELECT `guild_id`, `guild_name`, `lv`,`num`,`max_num`, `country`, `chief_id`, `chief_name`,",
									" `create_name`, `create_time`, `money` FROM `game_guild`",
									" WHERE `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>) of
		{?ok, [[GuildId2, Name, Lv,Num,MaxNum, Country, ChiefId, ChiefName, CreateName, CreateTime, Money]|_]} ->
			[Name,Lv,Num,MaxNum,ChiefId,ChiefName,Money,Country];
		_ ->
			["none",0,0,0,0,"none",0,"none"]
	end.


%% 单个玩家详细信息接口
do_user_info_detail() ->
    UserId 		= get_value("user_id"),
    UserName	= get_value("user_name"),
    Account		= get_value("account"),
    ServId      = get_value("serv_id"),
    do_user_info_detail(UserId, http_uri:decode(UserName), Account,ServId).

%% 体力，总战力，vip等级，军团名，军团等级，军团成员数，经验。 （马名字，等级，物攻，法攻，生命，技能）
do_user_info_detail(UserId, _UserName, _Account,ServId) when UserId =/= [] ->
	case mysql_api:select_execute(<<"SELECT `account`, `user_name` , `reg_time`, `lv`,",
									"`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`",
									" WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, [[Account, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]]} ->
			{?ok,[Info,Attr,Guild,Horse]} = player_api:get_player_fields(UserId, [#player.info,#player.attr,#player.guild,#player.horse]),
    		TotalPower = player_attr_api:caculate_power(Attr),
   			[GName,GLv,GNum,GMaxNum,GChiefId,GChiefName,GMoney,Country] = do_guild_info_single(Guild#guild.guild_id),
   			Fun = fun(Skill) ->
   				Skill#horse_skill.skill_id
   			end,
   			HorseSkill = lists:map(Fun,Horse#horse_data.skill),

			Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  %%{"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")},
                          {"sp",misc:to_binary("体力")},
                          {"power",misc:to_binary("个人总战力")},
                          {"vip", misc:to_binary("VIP等级")},
                          {"guild_id",misc:to_binary("军团id")},
                          {"guild_name",misc:to_binary("军团名字")},
                          {"guild_lv",misc:to_binary("军团等级")},
                          {"guild_num",misc:to_binary("军团人数")},
                          {"guild_max_num",misc:to_binary("军团人数上限")},
                          {"guild_chief_id",misc:to_binary("军团长ID")},
                          {"guild_chief_name",misc:to_binary("军团长名字")},
                          {"guild_money",misc:to_binary("军团资金")},
                          {"exp",misc:to_binary("玩家经验")},
                          {"exp_next",misc:to_binary("玩家升级经验")},
                          {"exp_total",misc:to_binary("玩家积累的总经验")},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary("坐骑等级")},
                          {"horse_skill",misc:to_binary("坐骑技能")}

                          ]},
			Data = {obj, [{"account", misc:to_binary(Account)},
						  {"user_id", misc:to_binary(UserId)}, 
						  {"user_name", misc:to_binary(UserName)},
						  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
						  {"level", misc:to_binary(Lv)},
						  {"last_login_ip", misc:to_binary(LoginIp)},
						  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
						  {"country", misc:to_binary(Country)},
						  %%{"guild", misc:to_binary("暂无")},
						  {"career", misc:to_binary(convert_pro(Pro))},
						  {"sex", misc:to_binary(convert_sex(Sex))},
                          {"cash", misc:to_binary(Cash)},
                          {"cash_bind", misc:to_binary(CashBind)},
                          {"gold_bind", misc:to_binary(GoldBind)},
                          {"sp", misc:to_binary(Info#info.sp)},
                          {"power", misc:to_binary(TotalPower)},
                          {"vip",misc:to_binary((Info#info.vip)#vip.lv)},
                          {"guild_id",misc:to_binary(Guild#guild.guild_id)},
                          {"guild_name",misc:to_binary(GName)},
                          {"guild_lv",misc:to_binary(GLv)},
                          {"guild_num",misc:to_binary(GNum)},
                          {"guild_max_num",misc:to_binary(GMaxNum)},
                          {"guild_chief_id",misc:to_binary(GChiefId)},
                          {"guild_chief_name",misc:to_binary(GChiefName)},
                          {"guild_money",misc:to_binary(GMoney)},
                          {"exp",misc:to_binary(Info#info.exp)},
                          {"exp_next",misc:to_binary(Info#info.expn)},
                          {"exp_total",misc:to_binary(Info#info.expt)},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary((Horse#horse_data.train)#horse_train.lv)},
                          {"horse_skill",misc:to_binary(misc:list_to_string(HorseSkill))}
                          ]},
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
		_Other ->
			{?true, 6, "failed"}
	end;
do_user_info_detail(_UserId, UserName, _Account,ServId) when UserName =/= [] ->
	case mysql_api:select_execute(<<"SELECT `account`, `user_id`, `reg_time`, `lv`,",
									"`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`",
									" WHERE `user_name` = '", (misc:to_binary(UserName))/binary, "';">>) of
		{?ok, [[Account, UserId, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]]} ->
			{?ok,[Info,Attr,Guild,Horse]} = player_api:get_player_fields(UserId, [#player.info,#player.attr,#player.guild,#player.horse]),
    		TotalPower = player_attr_api:caculate_power(Attr),
   			[GName,GLv,GNum,GMaxNum,GChiefId,GChiefName,GMoney,Country] = do_guild_info_single(Guild#guild.guild_id),
   			Fun = fun(Skill) ->
   				Skill#horse_skill.skill_id
   			end,
   			HorseSkill = lists:map(Fun,Horse#horse_data.skill),

			Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  %%{"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")},
                          {"sp",misc:to_binary("体力")},
                          {"power",misc:to_binary("个人总战力")},
                          {"vip", misc:to_binary("VIP等级")},
                          {"guild_id",misc:to_binary("军团id")},
                          {"guild_name",misc:to_binary("军团名字")},
                          {"guild_lv",misc:to_binary("军团等级")},
                          {"guild_num",misc:to_binary("军团人数")},
                          {"guild_max_num",misc:to_binary("军团人数上限")},
                          {"guild_chief_id",misc:to_binary("军团长ID")},
                          {"guild_chief_name",misc:to_binary("军团长名字")},
                          {"guild_money",misc:to_binary("军团资金")},
                          {"exp",misc:to_binary("玩家经验")},
                          {"exp_next",misc:to_binary("玩家升级经验")},
                          {"exp_total",misc:to_binary("玩家积累的总经验")},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary("坐骑等级")},
                          {"horse_skill",misc:to_binary("坐骑技能")}

                          ]},
			Data = {obj, [{"account", misc:to_binary(Account)},
						  {"user_id", misc:to_binary(UserId)}, 
						  {"user_name", misc:to_binary(UserName)},
						  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
						  {"level", misc:to_binary(Lv)},
						  {"last_login_ip", misc:to_binary(LoginIp)},
						  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
						  {"country", misc:to_binary(Country)},
						  %%{"guild", misc:to_binary("暂无")},
						  {"career", misc:to_binary(convert_pro(Pro))},
						  {"sex", misc:to_binary(convert_sex(Sex))},
                          {"cash", misc:to_binary(Cash)},
                          {"cash_bind", misc:to_binary(CashBind)},
                          {"gold_bind", misc:to_binary(GoldBind)},
                          {"sp", misc:to_binary(Info#info.sp)},
                          {"power", misc:to_binary(TotalPower)},
                          {"vip",misc:to_binary((Info#info.vip)#vip.lv)},
                          {"guild_id",misc:to_binary(Guild#guild.guild_id)},
                          {"guild_name",misc:to_binary(GName)},
                          {"guild_lv",misc:to_binary(GLv)},
                          {"guild_num",misc:to_binary(GNum)},
                          {"guild_max_num",misc:to_binary(GMaxNum)},
                          {"guild_chief_id",misc:to_binary(GChiefId)},
                          {"guild_chief_name",misc:to_binary(GChiefName)},
                          {"guild_money",misc:to_binary(GMoney)},
                          {"exp",misc:to_binary(Info#info.exp)},
                          {"exp_next",misc:to_binary(Info#info.expn)},
                          {"exp_total",misc:to_binary(Info#info.expt)},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary((Horse#horse_data.train)#horse_train.lv)},
                          {"horse_skill",misc:to_binary(misc:list_to_string(HorseSkill))}
                          ]},
			Result = rfc4627:encode({obj, [{"state", <<"success">>},
										   {"desc", Desc},
										   {"data", Data}]}),
			{?true, length(Result), Result};
		_Other ->
			{?true, 6, "failed"}
	end;
do_user_info_detail(_UserId, _UserName, Account,ServId) when Account =/= [] ->
	case mysql_api:select_execute(<<"SELECT `user_id`, `user_name` , `reg_time`, `lv`,",
									"`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`",
									" WHERE `account` = '", (misc:to_binary(Account))/binary, "' and `serv_id` = '",(misc:to_binary(ServId))/binary,"';">>) of
		{?ok, [[UserId, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]]} ->
			{?ok,[Info,Attr,Guild,Horse]} = player_api:get_player_fields(UserId, [#player.info,#player.attr,#player.guild,#player.horse]),
    		TotalPower = player_attr_api:caculate_power(Attr),
   			[GName,GLv,GNum,GMaxNum,GChiefId,GChiefName,GMoney,Country] = do_guild_info_single(Guild#guild.guild_id),
   			Fun = fun(Skill) ->
   				Skill#horse_skill.skill_id
   			end,
   			HorseSkill = lists:map(Fun,Horse#horse_data.skill),

			Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  %%{"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")},
                          {"sp",misc:to_binary("体力")},
                          {"power",misc:to_binary("个人总战力")},
                          {"vip", misc:to_binary("VIP等级")},
                          {"guild_id",misc:to_binary("军团id")},
                          {"guild_name",misc:to_binary("军团名字")},
                          {"guild_lv",misc:to_binary("军团等级")},
                          {"guild_num",misc:to_binary("军团人数")},
                          {"guild_max_num",misc:to_binary("军团人数上限")},
                          {"guild_chief_id",misc:to_binary("军团长ID")},
                          {"guild_chief_name",misc:to_binary("军团长名字")},
                          {"guild_money",misc:to_binary("军团资金")},
                          {"exp",misc:to_binary("玩家经验")},
                          {"exp_next",misc:to_binary("玩家升级经验")},
                          {"exp_total",misc:to_binary("玩家积累的总经验")},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary("坐骑等级")},
                          {"horse_skill",misc:to_binary("坐骑技能")}

                          ]},
			Data = {obj, [{"account", misc:to_binary(Account)},
						  {"user_id", misc:to_binary(UserId)}, 
						  {"user_name", misc:to_binary(UserName)},
						  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
						  {"level", misc:to_binary(Lv)},
						  {"last_login_ip", misc:to_binary(LoginIp)},
						  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
						  {"country", misc:to_binary(Country)},
						  %%{"guild", misc:to_binary("暂无")},
						  {"career", misc:to_binary(convert_pro(Pro))},
						  {"sex", misc:to_binary(convert_sex(Sex))},
                          {"cash", misc:to_binary(Cash)},
                          {"cash_bind", misc:to_binary(CashBind)},
                          {"gold_bind", misc:to_binary(GoldBind)},
                          {"sp", misc:to_binary(Info#info.sp)},
                          {"power", misc:to_binary(TotalPower)},
                          {"vip",misc:to_binary((Info#info.vip)#vip.lv)},
                          {"guild_id",misc:to_binary(Guild#guild.guild_id)},
                          {"guild_name",misc:to_binary(GName)},
                          {"guild_lv",misc:to_binary(GLv)},
                          {"guild_num",misc:to_binary(GNum)},
                          {"guild_max_num",misc:to_binary(GMaxNum)},
                          {"guild_chief_id",misc:to_binary(GChiefId)},
                          {"guild_chief_name",misc:to_binary(GChiefName)},
                          {"guild_money",misc:to_binary(GMoney)},
                          {"exp",misc:to_binary(Info#info.exp)},
                          {"exp_next",misc:to_binary(Info#info.expn)},
                          {"exp_total",misc:to_binary(Info#info.expt)},
                          {"horse_name",misc:to_binary("坐骑名字")},
                          {"horse_lv",misc:to_binary((Horse#horse_data.train)#horse_train.lv)},
                          {"horse_skill",misc:to_binary(misc:list_to_string(HorseSkill))}
                          ]},
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
		Other ->
            ?MSG_ERROR("1[~p|~p]", [Other, Account]),
			{?true, 6, "failed"}
	end;
do_user_info_detail(_UserId, _UserName, _Account,ServId) ->
    ?MSG_ERROR("1", []),
    {?true, 6, "failed"}.

%% 获取单个玩家信息 TODO
get_single_user_info(Player) when is_record(Player, player) ->
	Account			= Player#player.account,
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	UserName		= Info#info.user_name, 
	RegTime			= misc:seconds(), 
	Lv				= Info#info.lv, 
	LoginIp			= Player#player.ip, 
	LastLoginTime	= 0, 
	Pro				= Info#info.pro, 
	Sex				= Info#info.sex, 
	{Cash, CashBind, GoldBind} =  case player_money_api:read_money(UserId) of
									  Money when is_record(Money, money) ->
										  {Money#money.cash, 
										   Money#money.cash_bind,
										   Money#money.gold_bind};
									  _ -> {0, 0, 0}
								  end,
	Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  {"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")}]},
			Data = {obj, [{"account", misc:to_binary(Account)},
						  {"user_id", misc:to_binary(UserId)}, 
						  {"user_name", misc:to_binary(UserName)},
						  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
						  {"level", misc:to_binary(Lv)},
						  {"last_login_ip", misc:to_binary(LoginIp)},
						  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
						  {"country", misc:to_binary("暂无")},
						  {"guild", misc:to_binary("暂无")},
						  {"career", misc:to_binary(convert_pro(Pro))},
						  {"sex", misc:to_binary(convert_sex(Sex))},
                          {"cash", misc:to_binary(Cash)},
                          {"cash_bind", misc:to_binary(CashBind)},
                          {"gold_bind", misc:to_binary(GoldBind)}]},
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
get_single_user_info(_)  ->
	{?true, 6, "failed"}.

%% 玩家军团信息列表
do_guild_info_list() ->
	GuildName 	= get_value("guild_name"),
	GuildId		= get_value("guild_id"),
	
	case mysql_api:select_execute(<<"SELECT `guild_id`, `guild_name`, `lv`, `country`, `chief_id`, `chief_name`,",
									" `create_name`, `create_time`, `money` FROM `game_guild`",
									" WHERE `guild_name` LIKE '", (sql_escape_bin(GuildName))/binary, "' AND",
									" `guild_id` LIKE '", (sql_escape_bin(GuildId))/binary, "';">>) of
		{?ok, GuildInfoList} ->
			Desc = {obj, [{"guild_id", <<"军团ID">>}, 
						  {"name", <<"军团名字">>}, 
						  {"lv", <<"军团等级">>},
						  {"country", <<"国家">>}, 
						  {"chief_id", <<"帮主ID">>}, 
						  {"chief_name", <<"帮主名字">>},
						  {"create_name", <<"军团创始人">>}, 
						  {"create_time", <<"军团创建时间">>}, 
						  {"money", <<"军团金钱总量">>}]},
			Data = encode_guild_info_list(GuildInfoList),
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
		_Other ->
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", <<"null">>}, 
										   {"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end.

%% 单个军团详细信息
do_guild_info_detail() ->
    GuildName 	= http_uri:decode(get_value("guild_name")),
    GuildId		= get_value("guild_id"),
	?MSG_DEBUG("GuildName ~p, GuildId ~p", [GuildName, GuildId]),
    do_guild_info_detail(GuildId, GuildName).

do_guild_info_detail(GuildId, []) ->
	case mysql_api:select_execute(<<"SELECT `guild_id`, `guild_name`, `lv`, `country`, `chief_id`, `chief_name`,",
									" `create_name`, `create_time`, `money` FROM `game_guild`",
									" WHERE `guild_id` = '", (misc:to_binary(GuildId))/binary, "';">>) of
		{?ok, [[GuildId2, Name, Lv, Country, ChiefId, ChiefName, CreateName, CreateTime, Money]|_]} ->
			Desc = {obj, [{"guild_id", <<"军团ID">>},
						  {"name", <<"军团名字">>},
						  {"lv", <<"军团等级">>},
						  {"country", <<"国家">>},
						  {"chief_id", <<"帮主ID">>},
						  {"chief_name", <<"帮主名字">>},
						  {"create_name", <<"军团创始人">>},
						  {"create_time", <<"军团创建时间">>},
						  {"money", <<"军团金钱总量">>}]},
			Data = {obj, [{"guild_id", misc:to_binary(GuildId2)}, 
						  {"name", Name}, 
						  {"lv", misc:to_binary(Lv)},
						  {"country", misc:to_binary(Country)}, 
						  {"chief_id", misc:to_binary(ChiefId)}, 
						  {"chief_name", ChiefName},
						  {"create_name", CreateName}, 
						  {"create_time", misc:to_binary(convert_date_time(CreateTime))}, 
						  {"money", misc:to_binary(Money)}]},
			Result = rfc4627:encode({obj, [{"state", "success"}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
		_Other ->
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", <<"null">>}, 
										   {"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end;
do_guild_info_detail([], GuildName) ->
	case mysql_api:select_execute(<<"SELECT `guild_id`, `guild_name`, `lv`, `country`, `chief_id`, `chief_name`,",
									" `create_name`, `create_time`, `money` FROM `game_guild`",
									" WHERE `guild_name` = '", (misc:to_binary(GuildName))/binary, "';">>) of
		{?ok, [[GuildId, GuildName2, Lv, Country, ChiefId, ChiefName, CreateName, CreateTime, Money]|_]} ->
			Desc = {obj, [{"guild_id", <<"军团ID">>}, 
						  {"name", <<"军团名字">>}, 
						  {"lv", <<"军团等级">>},
						  {"country", <<"国家">>}, 
						  {"chief_id", <<"帮主ID">>}, 
						  {"chief_name", <<"帮主名字">>},
						  {"create_name", <<"军团创始人">>}, 
						  {"create_time", <<"军团创建时间">>}, 
						  {"money", <<"军团金钱总量">>}]},
			Data = {obj, [{"guild_id", misc:to_binary(GuildId)}, 
						  {"name", GuildName2}, 
						  {"lv", misc:to_binary(Lv)},
						  {"country", misc:to_binary(Country)}, 
						  {"chief_id", misc:to_binary(ChiefId)}, 
						  {"chief_name", ChiefName},
						  {"create_name", CreateName}, 
						  {"create_time", misc:to_binary(CreateTime)}, 
						  {"money", misc:to_binary(Money)}]},
			Result = rfc4627:encode({obj, [{"state", "success"}, 
										   {"desc", Desc}, 
										   {"data", Data}]}),
			{?true, length(Result), Result};
		_Other ->
			Result = rfc4627:encode({obj, [{"state", <<"success">>}, 
										   {"desc", <<"null">>}, 
										   {"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end;
do_guild_info_detail(_, _) ->
    {?false, 6, "failed"}.

%% 查询玩家道具
do_user_props_list() ->
	UserId   = get_value("user_id"),
	UserName = http_uri:decode(get_value("user_name")),
	Account  = http_uri:decode(get_value("account")),
	?MSG_DEBUG("UserId ~p, UserName ~p, Account ~p", [UserId, UserName, Account]),
	UserId2  = get_right_user(UserId, UserName, Account),
	case mysql_api:select([equip, bag, depot], game_player, [{user_id, UserId2}]) of
		{?ok, [[EquipData, BagData, DepotData]]} ->
			Equip = mysql_api:decode(EquipData),
			Bag   = mysql_api:decode(BagData),
			Depot = mysql_api:decode(DepotData),
			{_, EquipCtn} 	= lists:keyfind({UserId2, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, ctn_equip_api:unzip(Equip)),
			PropsList 		= get_user_props_list(EquipCtn, ctn_api:unzip(Bag), ctn_api:unzip(Depot)),
			
			Desc = {obj, [{"goods_id", <<"道具ID">>},
						  {"count", <<"道具数量">>},
						  {"position", <<"道具位置">>},
						  {"goods_name", <<"道具名称">>},
						  {"bind", <<"绑定状态">>},
						  {"lv", <<"道具等级">>},
						  {"color", <<"道具颜色">>}]},
			UserPropsList 	= encode_user_props_list(PropsList),
			Result 			= rfc4627:encode({obj, [{"state", <<"success">>}, 
													{"desc", Desc}, 
													{"data", UserPropsList}]}),
			{?true, length(Result), Result};
		{?ok, []} ->
			Result 			= rfc4627:encode({obj, [{"state", <<"success">>}, 
													{"desc", <<"null">>}, 
													{"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end.

get_user_props_list(Equip, Bag, Depot) ->
	EquipGoods	= misc:to_list(Equip#ctn.goods),
	BagGoods	= misc:to_list(Bag#ctn.goods),
	DepotGoods	= misc:to_list(Depot#ctn.goods),
	get_ctn_props_list(EquipGoods, ?CONST_GOODS_CTN_EQUIP_PLAYER)
		++ get_ctn_props_list(BagGoods, ?CONST_GOODS_CTN_BAG)
		++ get_ctn_props_list(DepotGoods, ?CONST_GOODS_CTN_DEPOT).

get_ctn_props_list(GoodsList, CtnType) ->
	CtnType2	= convert_ctn_type(CtnType),
	get_ctn_props_list(GoodsList, CtnType2, []).

get_ctn_props_list([Goods|T], CtnType, Acc) when is_record(Goods, goods)->
	#goods{goods_id = GoodsId,
		   count	= Count,
		   name		= Name,
		   bind		= Bind,
		   lv		= Lv,
		   color	= Color} = Goods,
	Acc2 = [{GoodsId, Count, CtnType, Name, Bind, Lv, Color}|Acc],
	get_ctn_props_list(T, CtnType, Acc2);
get_ctn_props_list([_Goods|T], CtnType, Acc) ->
	get_ctn_props_list(T, CtnType, Acc);
get_ctn_props_list([], _CtnType, Acc) -> Acc.

%% 查询玩家技能
do_user_skill_list() ->
	UserId   = get_value("user_id"),
	UserName = http_uri:decode(get_value("user_name")),
	Account  = http_uri:decode(get_value("account")),
	
	UserId2  = get_right_user(UserId, UserName, Account),
	case player_api:get_player_field(UserId2, #player.skill) of
		{?ok, #skill_data{skill = SkillList}} ->
			SkillList2 		= get_user_skill_list(SkillList),
			Desc 			= {obj, [{"skill_id", <<"技能ID">>},
									 {"skill_name", <<"技能名字">>}, 
									 {"level", <<"技能等级">>}]},
			UserSkillList 	= encode_user_skill_list(SkillList2),
			Result 			= rfc4627:encode({obj, [{"state", <<"success">>},
													{"desc", Desc},
													{"data", UserSkillList}]}),
			{?true, length(Result), Result};
		_Other ->
			Result 			= rfc4627:encode({obj, [{"state", <<"success">>},
													{"desc", <<"null">>},
													{"data", <<"null">>}]}),
			{?true, length(Result), Result}
	end.

%% 设置vip等级
do_set_vips() ->
    UserIdsFrom = string:tokens(get_value("user_ids"), ","),
    UserIds     = 
        if
            [] =:= UserIdsFrom ->
                UserNames   = string:tokens(http_uri:decode(get_value("user_names")), ","),
                UserNames2  = lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, UserNames),
                user_id_from_name(UserNames2, UserIdsFrom);
            ?true ->
                UserIdsFrom
        end,
    lists:foreach(fun(UserId) -> do_set_vip(UserId) end, UserIds),
    {?true, 7, "success"}.

do_set_vip(UserIdxxx) ->
    ToVipLv  = misc:to_integer(http_uri:decode(get_value("vip_lv"))),
    UserId   = misc:to_integer(UserIdxxx),
    case player_api:get_player_field(UserId, #player.info) of
        {?ok, #info{vip = #vip{lv = FromVipLv}}} when is_number(ToVipLv) andalso ToVipLv > FromVipLv andalso ToVipLv =< 10 ->
            case player_api:get_player_pid(UserId) of
                Pid when is_pid(Pid) ->
                    player_serv:set_viplv(Pid, ToVipLv),
                    {?true, 7, "success"};
                _X -> 
                    {?false, 6, "failed"}
            end;
        _Other ->
            {?false, 6, "failed"}
    end.

get_user_skill_list(List) ->
	get_user_skill_list(List, []).

get_user_skill_list([{SkillId, SkillLv, _Time}|T], Acc) ->
	case data_skill:get_skill({SkillId, SkillLv}) of
		#skill{name = SkillName} ->
			get_user_skill_list(T, [{SkillId, SkillName, SkillLv}|Acc]);
		_ -> get_user_skill_list(T, Acc)
	end;
get_user_skill_list([], Acc) -> Acc.

get_right_user(UserId, _UserName, _Account) when UserId =/= ?null andalso UserId =/= [] ->
	misc:to_integer(UserId);
get_right_user(_UserId, UserName, _Account) when UserName =/= ?null andalso UserName =/= [] ->
	[UserId] = user_id_from_name([UserName]),
	UserId;
get_right_user(_UserId, _UserName, Account) when Account =/= ?null andalso Account =/= [] ->
	case player_api:get_user_id_by_account(Account) of
		{?ok, UserId} -> UserId;
		{?error, _Error} -> 0
	end.

%% 发送邮件
do_send_mail() ->
    Action		= misc:to_integer(get_value("action")),
    AccountIds  = string:tokens(http_uri:decode(get_value("account_ids")), ","),
	UserNames	= string:tokens(http_uri:decode(get_value("user_names")), ","),
    UserIds		= string:tokens(http_uri:decode(get_value("user_ids")), ","),
    MinLv		= get_value("min_lv"),
    MaxLv		= get_value("max_lv"),
    MinLoginTime= get_value("min_login_time"),
    MaxLoginTime= get_value("max_login_time"),
    _MinRegTime	= get_value("min_reg_time"),
    _MaxRegTime	= get_value("max_reg_time"),
    _Sex		= get_value("sex"),
    _Career		= get_value("career"),
    GuildName	= get_value("guild"),	
    MailTitle	= http_uri:decode(get_value("mail_title")),
    MailContent	= http_uri:decode(get_value("mail_content")),
    _VipType    = get_value("viptype"),
    
    TotalUserNameList = 
		case Action of
			0 -> get_user_name_list();
			1 ->	%%user_names user_ids
				UserNames2 = lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, UserNames),
				UserNames3 = lists:append(user_name_from_id(UserIds), UserNames2),
				lists:append(user_name_from_account_id(AccountIds),UserNames3);
			2 ->	%%min~max users
				?MSG_DEBUG("MaxLv ~p, MinLv ~p", [MaxLv, MinLv]),
                get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime,
                                          _MinRegTime, _MaxRegTime, _Sex, _Career, GuildName,_VipType]);
%% 				get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime, GuildName]);
			3 ->	%%all online users
				player_api:all_user_online();
			_ ->
				[]
		end,
%%     io:format("TotalUserNameList:~p~n",[TotalUserNameList]), ?CONST_MAIL_INTEREST
    lists:foreach(fun(X) -> mail_api:send_system_mail_to_one2(
			      X, MailTitle, MailContent, 0, [], [], 0, 0, 0, ?CONST_COST_PLAYER_GM) end, TotalUserNameList),
    {?true, 7, "success"}.

%% 新手指导员接口 TODO(只是挂个称号，还是有特殊的权限，需要指明)
do_game_instructor_manage() ->
	UserName	= misc:to_binary(http_uri:decode(get_value("user_name"))),
    Type	 	= get_value("type"),
    _InstrType	= get_value("instructor_type"),
    _StartTime	= get_value("start_time"),
    _EndTime	= get_value("end_time"),
    State       = case Type of
                      "1" -> case _InstrType of
                                 "1" -> ?CONST_SYS_USER_STATE_GUIDE;
                                 "5" -> ?CONST_SYS_USER_STATE_GM;
                                 _ -> ?CONST_SYS_USER_STATE_NORMAL
                             end;
                      "2" -> ?CONST_SYS_USER_STATE_NORMAL;
                      _ -> ?CONST_SYS_USER_STATE_NORMAL
                  end,
	case change_player_state(UserName, State) of
		?ok -> {?true, 7, "success"};
		_ -> {?false, 6, "failed"}
	end.

%% 改变玩家各类money金额
do_change_money() ->
	UserId   		= misc:to_integer(get_value("user_id")),
	_UserName 		= get_value("user_name"),
	MoneyType		= get_value("money_type"),
	MoneyAccount	= misc:to_integer(get_value("money_account")),
	case MoneyAccount < 0 of
		?true  -> {?false, 6, "failed"};
		?false ->
			case ets_api:lookup(?CONST_ETS_PLAYER_MONEY, UserId) of
				?null -> {?false, 6, "failed"};
				Money ->
					NewMoney = case MoneyType of
								   "1"	-> Money#money{cash = MoneyAccount};
								   "2"  -> Money#money{cash_bind = MoneyAccount};
								   "3"	-> Money#money{gold = MoneyAccount};
								   "4"	-> Money#money{gold_bind = MoneyAccount};
								   _ -> Money
							   end,
					ets_api:insert(?CONST_ETS_PLAYER_MONEY, NewMoney),
					{?true, 7, "success"}
			end
	end.

%% 泛功能接口
do_mutilfunction() ->
    Api_method      = get_value("api_method"),
    catch do_multifunction(Api_method).

do_multifunction("cash_cost") ->
    try
                Username = misc:to_binary(http_uri:decode(get_value("user_name"))) ,
                Cashcost = misc:to_integer(get_value("cash_cost")),
                case Cashcost < 0 of 
                    ?true  -> throw({?false, 30, "元宝花费不可以为负数"});%元宝花费不可以为负数
                    ?false ->
                        User_id = case player_api:get_user_id_by_name(Username) of 
                                      {?ok,Uid} -> Uid;
                                      _ -> throw({?false, 15, "找不到玩家"})
                                  end,
                        case player_money_api:check_money(User_id, ?CONST_SYS_CASH, Cashcost) of 
                            {?ok, _, Flag} ->
                                if Flag ->
                                       case player_api:check_online(User_id) of
                                           ?true -> %玩家在线
                                               case player_money_api:minus_money(User_id, ?CONST_SYS_CASH, Cashcost, ?CONST_COST_GOODS_PARTNER_GET) of
                                                   ?ok ->
                                                       mail_api:send_system_mail_to_one2(
                                                         misc:to_binary(Username), "系统通知", "元宝扣除通知：交易成功，扣除"++misc:to_list(Cashcost)++"元宝", 0, [], [], 0, 0, 0, ?CONST_COST_PLAYER_GM),
                                                       {?true, 7, "success"};
                                                   _ ->
                                                       {?false, 18, "元宝扣除失败"}
                                               end;
                                           ?false -> 
                                               {?false, 30, "玩家不在线，无法扣除"}
                                       end;
                                    ?true ->
                                        {?false, 18, "玩家元宝不足"}
                                end;
                            _ ->
                                {?false, 36, "玩家信息无法读取，请重试"}
                        end
                end
    catch
        throw:X ->
            X
    end;
do_multifunction("task_info")->
	UserId   = get_value("user_id"),
	case player_api:get_player_field(misc:to_integer(UserId), #player.task) of
		{?ok, Task} when is_record(Task, task_data) ->
			Desc = {obj, [
						  {"task_type", <<"任务类型">>}
						  ,{"task_id", <<"任务id">>}
						  ,{"task_state", <<"任务状态">>}
						 ]},
			Branch = Task#task_data.branch,
			?MSG_ERROR("BRanch~p~n", [Branch]),
			Tasks1 = encode_tasklist([Task#task_data.main], 1),
			Tasks2 = encode_tasklist(Branch#branch_task.unfinished, 2),
			Tasks3 = encode_tasklist([Task#task_data.position_task], 3),
			Tasks4 = encode_tasklist([Task#task_data.guild_cycle#task_cycle.current], 4),
			Tasks5 = encode_tasklist([Task#task_data.daily_cycle#task_cycle.current], 5),
			Tasks = Tasks1++Tasks2++Tasks3++Tasks4++Tasks5,
			Result = rfc4627:encode(
					   {obj, [{"state", <<"success">>}
							  ,{"desc", Desc}
							  ,{"data", Tasks}]}),
			{?true, length(Result), Result};
		_Other->
			Result = rfc4627:encode({obj,[
										  {"state", <<"success">>}
										  ,{"desc", <<"null">>}
										  ,{"data", <<"null">>}
										 ]}),
			{?true, length(Result), Result}
	end;
do_multifunction("task_finish")->
	UserId   = misc:to_integer(get_value("user_id")),
	TaskId   = get_value("task_id"),
	TaskType = get_value("task_type"),
	case player_api:check_online(UserId) of
		?true ->
			case player_api:process_send(UserId, gm_mod, execute, ["完成任务", TaskType, TaskId] ) of
				?true  ->{?true, 7, "success"};
				?false ->{?false, 6, "failed"}
			end;
		?false ->
			{?false, 15, "玩家不在线"}
	end;

do_multifunction("title_info")->
	UserId   = misc:to_integer(get_value("user_id")),
	UserId2 = 
		case UserId of 
				  Uid when Uid > 0 ->
					  Uid;
				  _ ->
					  case get_value("user_name") of
						  ?null ->
							  throw({?false, 15, "找不到玩家"}) ;
						  N ->
							  Username = misc:to_binary(http_uri:decode(N)),
							  case player_api:get_user_id_by_name(Username) of
								  {?ok,UserId3} -> UserId3;
								  Why ->
									  ?MSG_DEBUG("can't find player named :~p~nReason:~p~n",[Username,Why]),
									  throw({?false, 15, "找不到玩家"})
							  end
					  
					  end
			  end,
	{?ok, Achievement}	=player_api:get_player_field(UserId2, #player.achievement),
	TitleData	= Achievement#achievement.title_data,
	?MSG_DEBUG("Title :~p", [TitleData]),
	Titles = [{obj, [{"titleid", misc:to_binary(Title#title_data.id)}]}||Title <- TitleData],
	Result = rfc4627:encode({obj,[
										  {"state", <<"success">>}
										  ,{"data", Titles}
										 ]}),
	{?true, length(Result), Result};


do_multifunction("del_title")->
	UserId   = misc:to_integer(get_value("user_id")),
	UserId2 = 
		case UserId of 
				  Uid when Uid > 0 ->
					  Uid;
				  _ ->
					  case get_value("user_name") of
						  ?null ->
							  throw({?false, 15, "找不到玩家"}) ;
						  N ->
							  Username = misc:to_binary(http_uri:decode(N)),
							  case player_api:get_user_id_by_name(Username) of
								  {?ok,UserId3} -> UserId3;
								  Why ->
									  ?MSG_DEBUG("can't find player named :~p~nReason:~p~n",[Username,Why]),
									  throw({?false, 15, "找不到玩家"})
							  end
					  
					  end
			  end,
	TitleId   = misc:to_integer(get_value("title_id")),
	achievement_api:delete_title(UserId2, TitleId),
	{?true, 7, "success"};
	
do_multifunction("setTitle") ->
	try
	Achid            = misc:to_integer(get_value("gm")),
	UserId          = misc:to_integer(get_value("user_id")),
	UserId2 = 
		case UserId of 
				  Uid when Uid > 0 ->
					  Uid;
				  _ ->
					  case get_value("user_name") of
						  ?null ->
							  throw({?false, 15, "找不到玩家"}) ;
						  N ->
							  Username = misc:to_binary(http_uri:decode(N)),
							  case player_api:get_user_id_by_name(Username) of
								  {?ok,UserId3} -> UserId3;
								  Why ->
									  ?MSG_DEBUG("can't find player named :~p~nReason:~p~n",[Username,Why]),
									  throw({?false, 15, "找不到玩家"})
							  end
					  
					  end
			  end,
	achievement_api:add_achievement(UserId2,Achid,0,1),
	{?true, 7, "success"}
	catch
		Err:Why1 ->
			Why2 = misc:to_list(Why1),
			?MSG_ERROR("error: ~p Why: ~p~~nstack: ~p", [Err, Why2, erlang:get_stacktrace()]),
			{?false, length(Why2), Why2}
	end;

do_multifunction(_) ->
	Reply = "接口未开放",
	{?false, length(Reply), Reply}.




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 检查IP是否在白名单中
check_ip(Ip) ->
	true.
    % IpList = white_ip_list(),
    % lists:any(fun(Ip2) -> misc:to_binary(Ip2) =:= misc:to_binary(Ip) end, IpList).

%% 返回IP白名单
white_ip_list() ->
    [_, Ip] = string:tokens(misc:to_list(node()), "@"),
    case config:read(server_info, #rec_server_info.white_ip_list) of
        ?null -> [Ip];
        List  -> [Ip|List]
    end.

total_params(Param) ->
%% 	Config 			= misc_app:load_config(gm),
%% 	{gm_key, GmKey}	= lists:keyfind(gm_key, 1, Config),
	GmKey			= ?CONST_SYS_GM_KEY, %config:read_deep([server, release, gm_key]),
    [_, Param2]		= string:tokens(Param, "?"),
	List  			= [begin
						   case string:tokens(X, "=") of
							   [Key] -> Key;
							   ["flag", _Value] -> "";
							   [Key, Value] -> lists:concat([Key, Value])
						   end
					   end || X <- string:tokens(Param2, "&")],
    lists:concat(List ++ [GmKey]).

key_value_list(Param) ->
	[_, Param2] = string:tokens(Param, "?"),
	[begin
		 case string:tokens(X, "=") of
			 [Key] -> {Key, ""};
			 [Key, Value] -> {Key, Value}
		 end
	 end || X <- string:tokens(Param2, "&")].

%% 处理admin模块的cast消息
treat_admin_cast(Player, [add_equip, GoodsId, Count]) ->
    goods_api:add_goods_gm(Player, GoodsId, Count);
treat_admin_cast(Player, [user_ban, Duration]) ->
    player_api:user_ban(Player, Duration);
treat_admin_cast(Player, [user_unban]) ->
    player_api:user_unban(Player);
%% treat_admin_cast(_Player, [user_list]) ->
%% 	player_api:all_user_online();
treat_admin_cast(Player, [chat_ban, Duration]) ->
    player_api:user_chat_ban(Player, Duration);
treat_admin_cast(Player, [chat_unban]) ->
    player_api:user_chat_unban(Player);
treat_admin_cast(Player, [set_viplv, ToVipLv]) ->
    ToVipLv2 = misc:betweet(ToVipLv, 0, 10),
    player_api:vip(Player, ToVipLv2);
treat_admin_cast(Player, _) ->
    {?ok, Player}.

%% 收数据
http_recv(Socket) ->
	case gen_tcp:recv(Socket, 0, ?CONST_MAX_ADMIN_PACKET) of
		{?ok, BinData} ->
			{?ok, misc:to_list(BinData)};
		Error ->
			{?error, Error}
	end.

%% 从用户名列表获取ID列表
user_id_from_name(UserNameList) ->
    user_id_from_name(UserNameList, []).

user_id_from_name([UserName|T], Acc) ->
	case player_api:get_user_id_by_name(UserName) of
		{?ok, UserId} -> user_id_from_name(T, [UserId|Acc]);
		_Other -> user_id_from_name(T, Acc)
	end;
user_id_from_name([], Acc) -> Acc.

%% 从ID列表获取用户名列表
user_name_from_id(UserIdList) ->
    user_name_from_id(UserIdList, []).

user_name_from_id([], Acc) -> Acc;
user_name_from_id([UserId|T], Acc) ->
    case player_db_mod:select_user_name_by_id(UserId) of
	?false -> user_name_from_id(T, Acc);
	UserName -> user_name_from_id(T, [UserName|Acc])
    end.


user_name_from_account_id(AccountIdList) ->
	user_name_from_account_id(AccountIdList, []).

user_name_from_account_id([], Acc) -> Acc;
user_name_from_account_id([AccountId|T], Acc) ->
    case player_db_mod:select_user_name_by_account(AccountId) of
	?false -> user_name_from_account_id(T, Acc);
	UserName -> user_name_from_account_id(T, [UserName|Acc])
    end.

%% 所有玩家列表
get_user_name_list() ->
	case mysql_api:select_execute(<<"SELECT `user_name` FROM `game_user` WHERE `exist` = 1;">>) of
		{?ok, []} -> [];
		{?ok, NameList} -> lists:map(fun([Name]) -> Name end, NameList);
		_Other -> []
	end.

%% 从限制条件获取用户名列表
get_user_name_condition([MinLv, MaxLv, MinLoginTime, MaxLoginTime, MinRegTime,
                          MaxRegTime, Sex, Career, GuildName,VipType]) ->
    try
    MinLv2             = misc:to_list(MinLv),
    MaxLv2             = misc:to_list(MaxLv),
    MinLoginTime2      = misc:to_list(real_start(MinLoginTime)),
    MaxLoginTime2      = misc:to_list(real_end(MaxLoginTime)),
    MinRegTime2        = misc:to_list(real_start(MinRegTime)),
    MaxRegTime2        = misc:to_list(real_end(MaxRegTime)),
    Sex2               = misc:to_list(Sex),
    Career2            = misc:to_list(Career),
    VipType2           = misc:to_list(VipType),
    Str1 = if  MinLv2 =/= "" -> " AND `game_user`.`lv` > " ++ MinLv2; ?true -> "" end,
    Str2 = if  MaxLv2 =/= "" -> " AND `game_user`.`lv` < " ++ MaxLv2; ?true -> "" end,
    Str3 = if  MinLoginTime2 =/= "" -> " AND `game_user`.`login_time_last` > " ++ MinLoginTime2; ?true -> "" end,
    Str4 = if  MaxLoginTime2 =/= "" -> " AND `game_user`.`login_time_last` < " ++ MaxLoginTime2; ?true -> "" end,
    Str5 = if  MinRegTime2 =/= "" -> " AND `game_user`.`reg_time` >" ++ MinRegTime2; ?true -> "" end,
    Str6 = if  MaxRegTime2 =/= "" -> " AND `game_user`.`reg_time` <" ++ MaxRegTime2; ?true -> "" end,
    Str7 = if  Sex2 =/= "" -> " AND `game_user`.`sex` = " ++ Sex2; ?true -> "" end,
    Str8 = if  Career2 =/= "" -> " AND `game_user`.`pro` = " ++ Career2; ?true -> "" end,
    {Str9, StrTable} = if
                           GuildName =/= "" -> 
                               {" AND `game_guild`.`guild_name` = '"++lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, string:tokens(http_uri:decode(GuildName),"~~"))++"'"++
                                  " AND `game_guild`.`guild_id` = `game_guild_member`.`guild_id`"++
                                    " AND `game_guild_member`.`user_id` = `game_user`.`user_id`",
                                ",`game_guild`,`game_guild_member` "};
                           ?true ->
                               {"",""}
                       end,
    Str10 = case VipType2 of "1" -> " AND `game_user`.`vip` > 0"; "2" -> " AND `game_user`.`vip` = 0" ; _ -> ""end,
    case mysql_api:select_execute(misc:to_binary("SELECT `game_user`.`user_name` FROM `game_user`"++StrTable++
                                    " WHERE 1 = 1"++Str1++Str2++Str3++Str4++Str5++Str6++Str7++Str8++
                                    Str9++Str10)) of
        {?ok, UserNameList} ->
            lists:map(fun([UserName]) -> UserName end, UserNameList);
        _ -> []
    end
    catch
        X:Y ->
            io:format("~n~p|~p|~p:~p|~n~p~n",[?MODULE,?LINE,X,Y,erlang:get_stacktrace()]),
            []
    end;

get_user_name_condition([LvLow, LvUp, LoginStart, LoginEnd, _Fation]) ->
	LvLow2 		= misc:to_integer(LvLow),
	LvUp2 		= misc:to_integer(LvUp),
	LoginStart2 = real_start(LoginStart),
	LoginEnd2 	= real_end(LoginEnd),
	case mysql_api:select_execute(<<"SELECT `user_name` FROM `game_user` WHERE `lv` BETWEEN '", (misc:to_binary(LvLow2))/binary, "'",  
									" AND '", (misc:to_binary(LvUp2))/binary, "'",
									" AND `login_time_last` BETWEEN '", (misc:to_binary(LoginStart2))/binary, "'",
									" AND '", (misc:to_binary(LoginEnd2))/binary, "';">>) of
		{?ok, UserNameList} ->
			lists:map(fun([UserName]) -> UserName end, UserNameList);
		_ -> []
	end.

get_user_name_condition_2([MinLv, MaxLv, MinLoginTime, MaxLoginTime, MinRegTime,
                          MaxRegTime, Sex, Career, GuildName,VipType]) ->
    try
    MinLv2             = misc:to_list(MinLv),
    MaxLv2             = misc:to_list(MaxLv),
    MinLoginTime2      = misc:to_list(real_start(MinLoginTime)),
    MaxLoginTime2      = misc:to_list(real_end(MaxLoginTime)),
    MinRegTime2        = misc:to_list(real_start(MinRegTime)),
    MaxRegTime2        = misc:to_list(real_end(MaxRegTime)),
    Sex2               = misc:to_list(Sex),
    Career2            = misc:to_list(Career),
    VipType2           = misc:to_list(VipType),
    Str1 = if  MinLv2 =/= "" -> " AND `game_user`.`lv` > " ++ MinLv2; ?true -> "" end,
    Str2 = if  MaxLv2 =/= "" -> " AND `game_user`.`lv` < " ++ MaxLv2; ?true -> "" end,
    Str3 = if  MinLoginTime2 =/= "" -> " AND `game_user`.`login_time_last` > " ++ MinLoginTime2; ?true -> "" end,
    Str4 = if  MaxLoginTime2 =/= "" -> " AND `game_user`.`login_time_last` < " ++ MaxLoginTime2; ?true -> "" end,
    Str5 = if  MinRegTime2 =/= "" -> " AND `game_user`.`reg_time` >" ++ MinRegTime2; ?true -> "" end,
    Str6 = if  MaxRegTime2 =/= "" -> " AND `game_user`.`reg_time` <" ++ MaxRegTime2; ?true -> "" end,
    Str7 = if  Sex2 =/= "" -> " AND `game_user`.`sex` = " ++ Sex2; ?true -> "" end,
    Str8 = if  Career2 =/= "" -> " AND `game_user`.`pro` = " ++ Career2; ?true -> "" end,
    {Str9, StrTable} = if
                           GuildName =/= "" -> 
                               {" AND `game_guild`.`guild_name` = '"++lists:map(fun(Y) -> misc:to_binary(http_uri:decode(Y)) end, string:tokens(http_uri:decode(GuildName),"~~"))++"'"++
                                  " AND `game_guild`.`guild_id` = `game_guild_member`.`guild_id`"++
                                    " AND `game_guild_member`.`user_id` = `game_user`.`user_id`",
                                ",`game_guild`,`game_guild_member` "};
                           ?true ->
                               {"",""}
                       end,
    Str10 = case VipType2 of "1" -> " AND `game_user`.`vip` > 0"; "2" -> " AND `game_user`.`vip` = 0" ; _ -> ""end,
    case mysql_api:select_execute(misc:to_binary("SELECT `account`, `user_id`, `user_name` , `reg_time`, `lv`,"++
						  "`login_ip`, `login_time_last`, `pro`, `sex`, `cash`, `cash_bind`, `gold_bind` FROM `game_user`"++StrTable++
                                    " WHERE 1 = 1"++Str1++Str2++Str3++Str4++Str5++Str6++Str7++Str8++
                                    Str9++Str10)) of
        {?ok, UserInfoList} ->
        	TotalNumber	= length(UserInfoList),
            Desc = {obj, [{"account", misc:to_binary("平台帐号")},
						  {"user_id", misc:to_binary("玩家ID")},
						  {"user_name", misc:to_binary("玩家角色名")},
						  {"reg_time", misc:to_binary("角色创建时间")},
						  {"level", misc:to_binary("玩家等级")},
						  {"last_login_ip", misc:to_binary("玩家最后登陆IP")},
						  {"last_login_time", misc:to_binary("玩家最后登陆时间")},
						  {"country", misc:to_binary("玩家阵营名称")},
						  {"guild", misc:to_binary("玩家帮派名称")},
						  {"career", misc:to_binary("玩家职业名称")},
						  {"sex", misc:to_binary("性别")},
                          {"cash", misc:to_binary("元宝")},
                          {"cash_bind", misc:to_binary("礼券")},
                          {"gold_bind", misc:to_binary("铜钱")}]},
			?MSG_DEBUG("~nUserInfoList:~p~n", [UserInfoList]),
			UserInfoList2 	= encode_user_info_list(UserInfoList, ?CONST_SYS_FALSE),
			?MSG_DEBUG("~nUserInfoList:~p~n", [UserInfoList2]),
			Result 			= rfc4627:encode({obj, [{"total_number", TotalNumber},
													{"state", <<"success">>},
													{"desc", Desc},
													{"data", UserInfoList2}]}),
			{?true, length(Result), Result};
        _ -> 
        	{?false, 0, "sql_error"}
    end
    catch
        X:Y ->
            io:format("~n~p|~p|~p:~p|~n~p~n",[?MODULE,?LINE,X,Y,erlang:get_stacktrace()]),
            {?false, 0, "sys_error"}
    end.


encode_user_info_list(List, IsOnline) ->
    encode_user_info_list_2(List, IsOnline, 0, []).

encode_user_info_list_2([[Account, UserId, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]|T], ?CONST_SYS_FALSE, Num, Acc) ->
    Item = {obj, [{"account", misc:to_binary(Account)},
                  {"user_id", misc:to_binary(UserId)}, 
                  {"user_name", misc:to_binary(UserName)},
                  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
                  {"level", misc:to_binary(Lv)},
                  {"last_login_ip", misc:to_binary(LoginIp)},
                  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
                  {"country", misc:to_binary("暂无")},
                  {"guild", misc:to_binary("暂无")},
                  {"career", misc:to_binary(convert_pro(Pro))},
                  {"sex", misc:to_binary(convert_sex(Sex))},
                  {"cash", misc:to_binary(Cash)},
                  {"cash_bind", misc:to_binary(CashBind)},
                  {"gold_bind", misc:to_binary(GoldBind)}]},
    encode_user_info_list_2(T, ?CONST_SYS_FALSE, Num + 1, [Item|Acc]);
encode_user_info_list_2([[Account, UserId, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex, Cash, CashBind, GoldBind]|T], ?CONST_SYS_TRUE, Num, Acc) ->
    case player_api:check_online(UserId) of
        ?true ->
            Item = {obj, [{"account", misc:to_binary(Account)},
                          {"user_id", misc:to_binary(UserId)}, 
                          {"user_name", misc:to_binary(UserName)},
                          {"reg_time", misc:to_binary(convert_date_time(RegTime))},
                          {"level", misc:to_binary(Lv)},
                          {"last_login_ip", misc:to_binary(LoginIp)},
                          {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
                          {"country", misc:to_binary("暂无")},
                          {"guild", misc:to_binary("暂无")},
                          {"career", misc:to_binary(convert_pro(Pro))},
                          {"sex", misc:to_binary(convert_sex(Sex))},
                          {"cash", misc:to_binary(Cash)},
                          {"cash_bind", misc:to_binary(CashBind)},
                          {"gold_bind", misc:to_binary(GoldBind)}]},
            encode_user_info_list_2(T, ?CONST_SYS_TRUE, Num + 1, [Item|Acc]);
        ?false -> encode_user_info_list_2(T, ?CONST_SYS_TRUE, Num, Acc)
    end;
encode_user_info_list_2([], _, _, Acc) -> lists:reverse(Acc).


encode_user_info_list([[Account, UserId, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex]|T], ?CONST_SYS_FALSE, Num, Acc) ->
	Item = {obj, [{"account", misc:to_binary(Account)},
				  {"user_id", misc:to_binary(UserId)}, 
				  {"user_name", misc:to_binary(UserName)},
				  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
				  {"level", misc:to_binary(Lv)},
				  {"last_login_ip", misc:to_binary(LoginIp)},
				  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
				  {"country", misc:to_binary("暂无")},
				  {"guild", misc:to_binary("暂无")},
				  {"career", misc:to_binary(convert_pro(Pro))},
				  {"sex", misc:to_binary(convert_sex(Sex))}]},
	encode_user_info_list(T, ?CONST_SYS_FALSE, Num + 1, [Item|Acc]);
encode_user_info_list([[Account, UserId, UserName, RegTime, Lv, LoginIp, LastLoginTime, Pro, Sex]|T], ?CONST_SYS_TRUE, Num, Acc) ->
	case player_api:check_online(UserId) of
		?true ->
			Item = {obj, [{"account", misc:to_binary(Account)},
						  {"user_id", misc:to_binary(UserId)}, 
						  {"user_name", misc:to_binary(UserName)},
						  {"reg_time", misc:to_binary(convert_date_time(RegTime))},
						  {"level", misc:to_binary(Lv)},
						  {"last_login_ip", misc:to_binary(LoginIp)},
						  {"last_login_time", misc:to_binary(convert_date_time(LastLoginTime))},
						  {"country", misc:to_binary("暂无")},
						  {"guild", misc:to_binary("暂无")},
						  {"career", misc:to_binary(convert_pro(Pro))},
						  {"sex", misc:to_binary(convert_sex(Sex))}]},
			encode_user_info_list(T, ?CONST_SYS_TRUE, Num + 1, [Item|Acc]);
		?false -> encode_user_info_list(T, ?CONST_SYS_TRUE, Num, Acc)
	end;
encode_user_info_list([], _, _, Acc) -> lists:reverse(Acc).

%% 打包军团list
encode_guild_info_list(List) ->
    encode_guild_info_list(List, 0, []).

encode_guild_info_list([[Id, Name, Lv, Country, ChiefId, ChiefName, CreateName, CreateTime, Money]|T], Num, Acc) ->
	Item = {obj, [{"guild_id", misc:to_binary(Id)},
				  {"name", Name}, 
				  {"lv", misc:to_binary(Lv)},
				  {"country", misc:to_binary(Country)},
				  {"chief_id", misc:to_binary(ChiefId)},
				  {"chief_name", ChiefName},
				  {"create_name", CreateName},
				  {"createTime", misc:to_binary(convert_date_time(CreateTime))},
				  {"money", misc:to_binary(Money)}]},
    encode_guild_info_list(T, Num + 1, [Item|Acc]);
encode_guild_info_list([], _, Acc) -> Acc.

%% 打包技能数据
encode_user_skill_list(List) ->
    encode_user_skill_list(List, []).

encode_user_skill_list([{SkillId, SkillName, SkillLevel}|T], Acc) ->
	Item = {obj, [{"skill_id", misc:to_binary(SkillId)}, 
				  {"skill_name", misc:to_binary(SkillName)}, 
				  {"level", misc:to_binary(SkillLevel)}]},
    encode_user_skill_list(T, [Item|Acc]);
encode_user_skill_list([], Acc) -> Acc.

%% 打包道具数据数据
encode_user_props_list(List) ->
    encode_user_props_list(List, []).

encode_user_props_list([{GoodsId, Count, Position, GoodsName, Bind, Level, Color}|T], Acc) ->
	Item = {obj, [{"goods_id", misc:to_binary(GoodsId)},
				  {"count", misc:to_binary(Count)},
				  {"position", misc:to_binary(Position)},
				  {"goods_name", misc:to_binary(GoodsName)},
				  {"bind", misc:to_binary(convert_goods_bind(Bind))},
				  {"lv", misc:to_binary(Level)},
				  {"color", misc:to_binary(convert_goods_color(Color))}]},
    encode_user_props_list(T, [Item|Acc]);
encode_user_props_list([], Acc) -> Acc.



change_player_state(UserName, State) ->
	case player_api:get_user_id_by_name(UserName) of
		{?ok, UserId} ->
			case player_api:check_online(UserId) of
				?true -> change_player_state_online(UserId, State);
				?false -> change_player_state_offline(UserId, State)
			end;
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

change_player_state_online(UserId, State) ->
	case player_api:process_send(UserId, ?MODULE, set_player_state, State) of
		?true -> ?ok;
		?false -> {?error, ?TIP_COMMON_ERROR_DB}
	end.

change_player_state_offline(UserId, State) ->
	case mysql_api:update_execute(<<"UPDATE `game_user` SET ",
							   " `state` = ", (misc:to_binary(State))/binary,
							   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, _} ->
			player_api:delete_player_online(UserId),
			player_api:delete_player_offline(UserId),
			?ok;
		_ -> {?error, ?TIP_COMMON_ERROR_DB}
	end.

set_player_state(Player, State) when is_record(Player, player) ->
	{?ok, Player#player{state = State}}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%各种兼容，获得程序可处理的数据%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 获取整形 检验数据
real_integer([]) -> 0;
real_integer({}) -> 0;
real_integer(Data) ->
    misc:to_integer(Data).

%% -1为永久
real_forbid_date(Num) when Num < 0 orelse Num > 315360000 ->
    315360000;	%10年后，你还来，I服了U
real_forbid_date(Num) ->
    Num.
%% -1为永久
real_ban_date(Num) when Num < 0 orelse Num > 2000000000->
    2000000000;
real_ban_date(Num) ->
    Num.

real_start("") ->
    0;
real_start(<<>>) ->
    0;
real_start(Data) ->
    Data.

real_end("") ->
    2000000000;
real_end(<<>>) ->
    2000000000;
real_end(Data) ->
    Data.

%% SQL字符串转义 加%
sql_escape_bin(Data) ->
    misc:to_binary(sql_escape(Data)).

sql_escape(?null) -> "%";
sql_escape([]) -> "%";
sql_escape(<<"">>) -> "%";
sql_escape(Data) ->
    Data2 = misc:to_list(Data),
    lists:concat(["%", Data2, "%"]).

%% key-value
set_kv_list([{Key, Value}|T]) ->
	?MSG_DEBUG("~n Key=~p, Value=~p", [Key, Value]),
    erlang:put(Key, Value),
    set_kv_list(T);
set_kv_list([]) -> ?ok.

get_value(Key) ->
	case erlang:get(Key) of
		undefined -> ?null;
		Value -> Value
	end.

get_money_list(MoneyType, MoneyAmount) ->
    MoneyList	= get_money_list(MoneyType, MoneyAmount, []),
	Cash		=
		case lists:keyfind(?CONST_SYS_CASH, 1, MoneyList) of
			{?CONST_SYS_CASH, CashValue} -> CashValue;
			?false -> 0
		end,
	Gold		=
		case lists:keyfind(?CONST_SYS_GOLD_BIND, 1, MoneyList) of
			{?CONST_SYS_GOLD_BIND, GoldValue} -> GoldValue;
			?false -> 0
		end,
	BCash 		=
		case lists:keyfind(5, 1, MoneyList) of
			{5, BCashValue} -> BCashValue;
			?false -> 0
		end,
    BCash2      =
        case lists:keyfind(2, 1, MoneyList) of
            {2, BCashValue2} -> BCashValue2;
            ?false -> 0
        end,
	{Cash, Gold, BCash, BCash2}.


get_money_list([MoneyTypeTmp|T], [MoneyAmountTmp|T2], Acc) ->
	MoneyType	= change_money_type(MoneyTypeTmp),
	case MoneyType of
		0 -> get_money_list(T, T2, Acc);
		_ ->
			MoneyAmount	= misc:to_integer(MoneyAmountTmp),
			Acc2		=
				case lists:keytake(MoneyType, 1, Acc) of
					{value, {MoneyType, MoneyValue}, AccTmp} ->
						[{MoneyType, MoneyValue + MoneyAmount}|AccTmp];
					?false -> [{MoneyType, MoneyAmount}|Acc]
				end,
			get_money_list(T, T2, Acc2)
	end;
get_money_list([], _MoneyAmount, Acc) -> Acc;
get_money_list(_MoneyType, [], Acc) -> Acc.

%% 货币类型，同时发放多个币种时，使用逗号分隔，
%% 与货币数量money_amount币种对应。
%% 1=元宝/金币，2=绑定元宝/金币，3=铜币，4=绑定铜币， 5=礼券
%% 若无货币需要发放，此字段为空
change_money_type("1") -> ?CONST_SYS_CASH;
change_money_type("2") -> ?CONST_SYS_CASH_BIND;
change_money_type("3") -> ?CONST_SYS_GOLD_BIND;
change_money_type("4") -> ?CONST_SYS_GOLD_BIND;
change_money_type("5") -> 0;
change_money_type(_) -> 0.

get_goods_list(ItemIds, ItemTypes, ItemCounts) ->
    get_goods_list(ItemIds, ItemTypes, ItemCounts, []).
get_goods_list([], _ItemTypes, _ItemCounts, Acc) -> Acc;
get_goods_list(_ItemIds, _ItemTypes, [], Acc) -> Acc;
get_goods_list([ItemId|T], ItemTypes, [ItemCount|T3], Acc) ->
	{
	 Bind, T2
	}		= case ItemTypes of
				  [ItemType|T2Tmp] -> {real_integer(ItemType), T2Tmp};
				  T2Tmp -> {?CONST_GOODS_BIND, T2Tmp}
			  end,
	Acc2	= case goods_api:make(real_integer(ItemId), Bind, real_integer(ItemCount)) of
				  {?error,_}->
					  [];
				  Goods ->
					  Goods
			  end,
    get_goods_list(T, T2, T3, Acc2 ++Acc).

%% 获取任务信息

encode_tasklist(TaskList, Type)->
	encode_tasklist(TaskList, [], Type).
encode_tasklist([Task|T], Acc, Type) when is_record(Task, mini_task)->
	Desc = {obj, [
				  {"task_type", misc:to_binary(Type)}
				  ,{"task_id", misc:to_binary(Task#mini_task.id)}
				  ,{"task_state", misc:to_binary(Task#mini_task.state)}
				 ]}, 
	encode_tasklist(T, [Desc|Acc], Type);
encode_tasklist([_H|T], Acc, Type)->
	encode_tasklist(T, Acc, Type);
encode_tasklist([], Acc, _Type)->
	Acc.




%% 中文转utf-8字符串
%% 中国--->"\u4E2D\u56FD"
chinese_to_bin(Data) ->
	Data2 = chinese_to_utf8(Data),
	erlang:list_to_binary(Data2).

chinese_to_utf8(Data) ->
	Data2 = unicode:characters_to_list(Data),
	utf8_to_string(Data2, []).

utf8_to_string([], Acc) ->
	Acc;
utf8_to_string([One|T], Acc) ->
	String = erlang:integer_to_list(One, 16),
	utf8_to_string(T, Acc ++ lists:concat(["\u", String])).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 性别转换
convert_sex(?CONST_SYS_SEX_NULL) -> <<"空">>;
convert_sex(?CONST_SYS_SEX_MALE) -> <<"男">>;
convert_sex(?CONST_SYS_SEX_FAMALE) -> <<"女">>;
convert_sex(_) -> <<"error">>.
%% 职业转换
convert_pro(?CONST_SYS_PRO_NULL) -> <<"空">>;
convert_pro(?CONST_SYS_PRO_XZ) -> <<"陷阵">>;
convert_pro(?CONST_SYS_PRO_FJ) -> <<"飞军">>;
convert_pro(?CONST_SYS_PRO_TJ) -> <<"天机">>;
convert_pro(?CONST_SYS_PRO_GM) -> <<"鬼谋">>;
convert_pro(?CONST_SYS_PRO_KX) -> <<"控弦">>;
convert_pro(?CONST_SYS_PRO_JH) -> <<"惊鸿">>;
convert_pro(_) -> <<"error">>.
%% 日期转换
convert_date({Y,M,D}) -> convert_date(Y,M,D);
convert_date({{Y,M,D},_Time}) -> convert_date(Y,M,D).
convert_date(Y,M,D) ->
	misc:to_list(Y)++"年"++date_format(M)++"月"++date_format(D)++"日".
%% 时间转换
convert_time({H,M,S}) -> convert_time(H,M,S);
convert_time({_Date,{H,M,S}}) -> convert_time(H,M,S).
convert_time(H,M,S) ->
	misc:to_list(H)++":"++misc:to_list(M)++":"++misc:to_list(S).
%% 日期时间转换
%% admin_mod:convert_date_time(2343543453).
convert_date_time(Seconds) when is_number(Seconds) ->
	convert_date_time(misc:seconds_to_localtime(Seconds));
convert_date_time({{Y,M,D},{H,Min,S}}) ->
	misc:to_list(Y)++"年"++date_format(M)++"月"++date_format(D)++"日"++
	"--" ++
	misc:to_list(H)++":"++misc:to_list(Min)++":"++misc:to_list(S).

date_format(D) ->
	if D < 10 -> "0" ++ misc:to_list(D); ?true  -> misc:to_list(D) end.
%% 转换物品颜色
convert_goods_color(?CONST_SYS_COLOR_WHITE) 	-> <<"白">>;
convert_goods_color(?CONST_SYS_COLOR_GREEN) 	-> <<"绿">>;
convert_goods_color(?CONST_SYS_COLOR_BLUE) 		-> <<"蓝">>;
convert_goods_color(?CONST_SYS_COLOR_YELLOW) 	-> <<"金">>;
convert_goods_color(?CONST_SYS_COLOR_PURPLE) 	-> <<"紫">>;
convert_goods_color(?CONST_SYS_COLOR_ORANGE) 	-> <<"橙">>;
convert_goods_color(?CONST_SYS_COLOR_RED) 		-> <<"红">>;
convert_goods_color(_) -> <<"error">>.
%% 转换物品绑定状态
convert_goods_bind(?CONST_GOODS_UNBIND)	-> <<"未绑定">>;
convert_goods_bind(?CONST_GOODS_BIND)	-> <<"已绑定">>;
convert_goods_bind(_) -> <<"error">>.
%% 转换容器类型
convert_ctn_type(?CONST_GOODS_CTN_BAG)				-> <<"背包">>;
convert_ctn_type(?CONST_GOODS_CTN_DEPOT)			-> <<"仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_BAG_TEMP)			-> <<"临时背包">>;
convert_ctn_type(?CONST_GOODS_CTN_EQUIP_PLAYER)		-> <<"角色装备栏">>;
convert_ctn_type(?CONST_GOODS_CTN_EQUIP_PARTNER)	-> <<"武将装备栏">>;
convert_ctn_type(?CONST_GOODS_CTN_LOTTERY_DEPOT)	-> <<"宝箱仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_HOME_DEPOT)		-> <<"家园仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_GUILD)			-> <<"军团仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_REMOTE_DEPOT)		-> <<"远程仓库">>;
convert_ctn_type(?CONST_GOODS_CTN_REMOTE_SHOP)		-> <<"远程道具店">>;
convert_ctn_type(_) -> <<"error">>.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%