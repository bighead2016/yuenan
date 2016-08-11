%% Author: cobain
%% Created: 2012-7-12
%% Description: TODO: Add description to player_db_mod
-module(player_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([check_player/1, check_name/1, default_pro/0, delete_player/1]).
-export([read_player/1, read_player/2]).
-export([login_debug/6, get_old_cash/1]).
-export([insert_offline/3, select_offline/1]).
-export([test/1, ban_user/1, unban_user/1, user_online_flag/2, 
		 check_ban_over/1, ban_user_list/0, get_user_name/1,
         get_user_name_id_list/0, get_account_id_list/0, get_active_user_id/0,
		 select_user_name_by_id/1, select_field/2,select_user_name_by_account/1,
		 chat_ban_user/3, log_deposit/7, log_cash/7, log_in_out/3,
         insert_gm_msg/4, insert_offline_err/3, cc/3, 
         get_account_user_id_list/0, get_account_id_list_2/0]).
-export([write_player/2, create_write_player/2]).

%%

%% API Functions
%%
login_debug(AccId, Account, ServId, Time, Fcm, Ip) ->
	case mysql_api:select_execute(<<"SELECT `user_id`, `exist`, `state`, `game_time`, `logout_time_last`, `fcm` ",
									"FROM `game_user` WHERE ",
									"`account` = '", (misc:to_binary(Account))/binary, "' and ",
									"`serv_id` = '", (misc:to_binary(ServId))/binary, "';">>) of
		{?ok,[[UserId, Exist, State, GameTime, LogoutTimeLast, Fcm2]|_]} ->
			{?ok, UserId, Exist, State, GameTime, LogoutTimeLast, Fcm2};
		_ ->
%% 			ServId 			= config_server_id:get_serv_id(),
            Sid             = config:read_deep([server, base, sid]),
            PlatformId      = config:read_deep([server, base, platform_id]),
			DataMisc    	= data_misc:get_server_info({PlatformId, Sid}), %config_server_id:get_serv_unique_id(),
			AccName 		= DataMisc#rec_server_info.platform,
			ServUniqueId 	= DataMisc#rec_server_info.serv_uniq_id,
			State 			= ?CONST_SYS_USER_STATE_NORMAL,
			RegTime 		= Time,
			RegIp 			= Ip,
			case mysql_api:insert_execute(<<"INSERT INTO `game_user` ",
											"(`serv_id`, `serv_unique_id`, `acc_id`, `acc_name`,",
											" `account`, `state`, `reg_time`, `reg_ip`, `fcm`)",
											" VALUES (",
											" '", (misc:to_binary(ServId))/binary,"',",
											" '", (misc:to_binary(ServUniqueId))/binary,"',",
											" '", (misc:to_binary(AccId))/binary,"',",
											" '", (misc:to_binary(AccName))/binary,"',",
											" '", (misc:to_binary(Account))/binary,"',",
											" '", (misc:to_binary(State))/binary,"',",
											" '", (misc:to_binary(RegTime))/binary,"',",
											" '", (misc:to_binary(RegIp))/binary,"',",
											" '", (misc:to_binary(Fcm))/binary,"');">>) of
				{?ok, _Affect, UserId} ->
					Exist	= ?CONST_SYS_FALSE,
					{?ok, UserId, Exist, State, 0, 0, Fcm};
				X -> 
                    ?MSG_ERROR("X=~p", [X]),
					throw({?error, ?CONST_PLAYER_LOGIN_ERROR_SYS})
			end
	end.

%% 检查有无角色数据
check_player(UserId) ->
	case mysql_api:select_execute(<<"SELECT `user_id` FROM  `game_player` WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok,[[UserId]|_]} -> ?true;
		{?ok,[]} -> ?false;
		_ -> ?false
	end.

%% 检查有无角色昵称
check_name(UserName) ->
	case mysql_api:select([user_id], game_user, [{user_name, UserName}]) of
		{ok, []} -> ?ok;
		_Error ->
%% 			?MSG_ERROR("Error:~p",[Error]),
			{?error, ?CONST_PLAYER_CREATE_REPEAT_NAME}
	end.

%% 取得本服务器人数最少的职业
default_pro() ->
    case mysql_api:select_execute("SELECT count( `user_id` ) AS cc,`pro` FROM `game_user` GROUP BY `pro` ORDER BY cc ASC LIMIT 0 ,1") of
        {?ok, [[_Number,Pro]]} ->
            misc:to_integer(Pro);
        _ -> 1
    end.

%% 删除角色数据
delete_player(UserId)->
	mysql_api:fetch_cast(<<"`game_player`", " `user_id` = '", (misc:to_binary(UserId))/binary, "';">>),
	?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

write_player(Player, L) ->
    Sql1 = <<"UPDATE `game_player` SET ">>,
    Sql2 = <<" WHERE `user_id` = '", (misc:to_binary(Player#player.user_id))/binary, "';">>,
    Sql  = record_update_sql(Player, L, Sql1, Sql2),
    case mysql_api:update(Sql) of
        {?ok, _} ->
            ?ok;
        R ->
            ?MSG_ERROR("x[~p|~p]", [Player#player.user_id, R])
    end.

record_update_sql(Player, L, Sql1, Sql2) ->
    X = cc(Sql1, Player, L),
    <<X/binary, Sql2/binary>>.

cc(OldSql, Data, [{Field, ValueIdx}]) ->
    Value = erlang:element(ValueIdx, Data),
    <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` = ", (mysql_api:encode(Value))/binary, " ">>;
cc(OldSql, Data, [{Field, ValueIdx, Mod, Func, _, _}]) ->
    Value = erlang:element(ValueIdx, Data),
    Value2 = Mod:Func(Value),
    <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` = ", (mysql_api:encode(Value2))/binary, " ">>;
cc(OldSql, Data, [{Field, ValueIdx}|Tail]) ->
    Value = erlang:element(ValueIdx, Data),
    Sql = <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` = ", (mysql_api:encode(Value))/binary, ", ">>,
    cc(Sql, Data, Tail);
cc(OldSql, Data, [{Field, ValueIdx, Mod, Func, _, _}|Tail]) ->
    Value = erlang:element(ValueIdx, Data),
    Value2 = Mod:Func(Value),
    Sql = <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` = ", (mysql_api:encode(Value2))/binary, ", ">>,
    cc(Sql, Data, Tail);
cc(Sql, _, []) ->
    Sql.

create_write_player(Player, L) ->
    Sql1 = <<"INSERT INTO `game_player` ">>,
    Sql = record_insert_sql(Player, L, Sql1, <<";">>),
    case mysql_api:select(Sql) of
        {?ok, _} ->
            ?ok;
        {?ok, _, _} ->
            ?ok;
        R ->
            ?MSG_ERROR("x[~p]", [R])
    end.

record_insert_sql(Player, L, Sql1, Sql2) ->
    {X1, X2} = dd(<<" `user_id`, ">>, <<" '", (misc:to_binary(Player#player.user_id))/binary, "', ">>, Player, L),
    <<Sql1/binary, " (", X1/binary, ") values (", X2/binary, ") ", Sql2/binary>>.

dd(OldSql1, OldSql2, Data, [{Field, ValueIdx}]) ->
    Value = erlang:element(ValueIdx, Data),
    {
     <<OldSql1/binary, " `", (misc:to_binary(Field))/binary, "` ">>,
     <<OldSql2/binary, " ", (mysql_api:encode(Value))/binary, " ">>
    };
dd(OldSql1, OldSql2, Data, [{Field, ValueIdx, Mod, Func, _, _}]) ->
    Value = erlang:element(ValueIdx, Data),
    Value2 = Mod:Func(Value),
    {
     <<OldSql1/binary, " `", (misc:to_binary(Field))/binary, "` ">>,
     <<OldSql2/binary, " ", (mysql_api:encode(Value2))/binary, " ">>
    };
dd(OldSql1, OldSql2, Data, [{Field, ValueIdx}|Tail]) ->
    Value = erlang:element(ValueIdx, Data),
    Sql1 = <<OldSql1/binary, " `", (misc:to_binary(Field))/binary, "`, ">>,
    Sql2 = <<OldSql2/binary, " ", (mysql_api:encode(Value))/binary, ", ">>,
    dd(Sql1, Sql2, Data, Tail);
dd(OldSql1, OldSql2, Data, [{Field, ValueIdx, Mod, Func, _, _}|Tail]) ->
    Value = erlang:element(ValueIdx, Data),
    Value2 = Mod:Func(Value),
    Sql1 = <<OldSql1/binary, " `", (misc:to_binary(Field))/binary, "`, ">>,
    Sql2 = <<OldSql2/binary, " ", (mysql_api:encode(Value2))/binary, ", ">>,
    dd(Sql1, Sql2, Data, Tail);
dd(Sql1, Sql2, _, []) ->
    {Sql1, Sql2}.

record_select_sql(UserId, L) ->
    Sql = ee(<<"select ">>, L),
    <<Sql/binary, " from `game_player` WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>.

ee(OldSql, [{Field, _ValueIdx}]) ->
    <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` ">>;
ee(OldSql, [{Field, _ValueIdx, _Mod, _Func, _, _}]) ->
    <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "` ">>;
ee(OldSql, [{Field, _ValueIdx}|Tail]) ->
    Sql = <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "`, ">>,
    ee(Sql, Tail);
ee(OldSql, [{Field, _ValueIdx, _Mod, _Func, _, _}|Tail]) ->
    Sql = <<OldSql/binary, " `", (misc:to_binary(Field))/binary, "`, ">>,
    ee(Sql, Tail);
ee(Sql, []) ->
    Sql.

%% 反持久化玩家信息
read_player(UserId) ->
    read_player(UserId, #player{}).
read_player(0, _OldPlayer) ->
    {?ok, ?null};
read_player(UserId, OldPlayer) ->
    L = player_mod:get_fields_list(),
    Sql = record_select_sql(UserId, L),
    case mysql_api:select_execute(Sql) of
		{?ok, [PlayerData|_]} ->
			{?ok, Player} = read_player_decode(PlayerData, L, OldPlayer),
            {?ok, Player#player{user_id = UserId}};
		Error ->
%% 			?MSG_ERROR("Error:~p UserId:~p Is Not Exist...",[Error, UserId]),
			{?ok, ?null}
	end.

read_player_decode(Data, List, Record) ->
    ff(Data, List, Record).

ff([D], [{_Field, ValueIdx}], OldPlayer) ->
    ff([], [], erlang:setelement(ValueIdx, OldPlayer, mysql_api:decode(D)));
ff([D], [{_Field, ValueIdx, _Mod, _Func, Mod, Func}], OldPlayer) ->
    ff([], [], erlang:setelement(ValueIdx, OldPlayer, Mod:Func(mysql_api:decode(D))));
ff([D|DTal], [{_Field, ValueIdx}|Tail], OldPlayer) ->
    Player = erlang:setelement(ValueIdx, OldPlayer, mysql_api:decode(D)),
    ff(DTal, Tail, Player);
ff([D|DTal], [{_Field, ValueIdx, _Mod, _Func, Mod, Func}|Tail], OldPlayer) ->
    Player = erlang:setelement(ValueIdx, OldPlayer, Mod:Func(mysql_api:decode(D))),
    ff(DTal, Tail, Player);
ff([], [], Player) ->
    {?ok, Player}.

%% 通过用户ID查询角色名
select_user_name_by_id(UserId) ->
	case mysql_api:select_execute(<<"SELECT `user_name` FROM  `game_user` WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok,[[UserName]|_]} -> UserName;
		{?ok,[]} -> ?false;
		Other -> ?MSG_ERROR("Other ~p", [Other]), ?false
	end.

select_user_name_by_account(Account) ->
    case mysql_api:select_execute(<<"SELECT `user_name` FROM  `game_user` WHERE `account` = '", (misc:to_binary(Account))/binary, "';">>) of
        {?ok,[[UserName]|_]} -> UserName;
        {?ok,[]} -> ?false;
        Other -> ?MSG_ERROR("Other ~p", [Other]), ?false
    end.


%%
%% Local Functions
%%
%% 查询
select_field(UserId, L) ->
    Sql = record_select_sql(UserId, L),
    case mysql_api:select_execute(Sql) of
        {?ok, [Data|_]} ->
            Tuple = erlang:make_tuple(erlang:length(L), 0, []),
            {?ok, Data2} = read_player_decode(Data, L, Tuple),
            erlang:tuple_to_list(Data2);
        Error ->
            ?MSG_ERROR("Error:~p UserId:~p Is Not Exist...",[Error, UserId]),
            {?ok, ?null}
    end.

get_old_cash(Account) ->
    case  mysql_api:select_execute(<<"SELECT `cash` FROM  `game_cash_old` WHERE `acount` = '",
                                                        (misc:to_binary(Account))/binary, "';">>) of
        {?ok,CashList} ->
            
            mysql_api:delete(game_cash_old, "acount = '" ++  misc:to_list(Account) ++ "';"), 
            list_sum(CashList, 0);
        _ ->
            
            0
    end.

list_sum([], Sum) ->
    Sum;
list_sum([[Cash]|Rest], Sum) ->
    list_sum(Rest, Sum + Cash).

%% 离线数据
insert_offline(UserId, Module, Data) ->
    Now = misc:seconds(),
    case mysql_api:insert(game_offline, [{user_id, UserId}, {module, Module}, {data, Data}, {time, Now}]) of
        {?ok, _, _} ->
            ?ok;
        {?error, _ErrorCode} ->
            {?error, ?TIP_COMMON_ERROR_DB}
    end.

%% 上线捞数据
%% [[Module, Data, Now]...]
select_offline(UserId) ->
    case mysql_api:select([module, data, time], game_offline, [{user_id, UserId}]) of
        {?ok, List} ->
            mysql_api:delete("delete from `game_offline` where `user_id` = "++misc:to_list(UserId)),
            {?ok, List};
        _ ->
            {?error, ?TIP_COMMON_ERROR_DB}
    end.

%% 离线处理有误数据备份
insert_offline_err(UserId, Module, Data) ->
    Now = misc:seconds(),
    case mysql_api:insert(game_offline_err, [{user_id, UserId}, {module, Module}, {data, Data}, {time, Now}]) of
        {?ok, _, _} ->
            ?ok;
        {?error, _ErrorCode} ->
            {?error, ?TIP_COMMON_ERROR_DB}
    end.

%%GM封号
ban_user(UserId) ->
	mysql_api:update_execute(<<"UPDATE `game_user` SET ",
							   " `state` = ", (misc:to_binary(?CONST_SYS_USER_STATE_FORBID))/binary,
							   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>).
%%GM解封帐号
unban_user(UserId) ->
	mysql_api:update_execute(<<"UPDATE `game_user` SET ",
							   " `state` = ", (misc:to_binary(?CONST_SYS_USER_STATE_NORMAL))/binary,
							   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>).
%%GM禁言
chat_ban_user(UserId, Status, Time) ->
	case mysql_api:select_execute(<<"SELECT `info` FROM `game_player`", 
								" WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>) of
		{?ok, [[BinInfo]]} ->
			Info = mysql_api:decode(BinInfo),
			BinInfo2 = mysql_api:encode(Info#info{chat_status = Status, shutup_over = Time}),
			mysql_api:update_execute(<<"UPDATE `game_player` SET",
									   " `info` = ", BinInfo2/binary,
									   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>);
		Other ->
			?MSG_DEBUG("Other ~p", [Other])
	end.

%%更新在线状态
user_online_flag(UserId, Flag) ->
	mysql_api:update_execute(<<"UPDATE `game_user` SET ",
							   " `online_flag` = ", (misc:to_binary(Flag))/binary,
							   " WHERE `user_id` = '", (misc:to_binary(UserId))/binary, "';">>).
%% 检查账号是否解封
check_ban_over(UserId) ->
	case mysql_api:select([state], game_user, [{user_id, UserId}]) of
		{?ok, [[State]]} ->
			case State of
				?CONST_SYS_USER_STATE_FORBID ->
					{?ok, Info} = select_field(UserId, [{"info", 1}]),
                    ?MSG_ERROR("[~p]", [Info]),
					case (misc:seconds() >= Info#info.ban_over) of
						?true -> ?true;
						?false -> ?false
					end;
				_Other -> ?true
			end;
		{?ok, []} -> ?false
	end.

%% 封号玩家列表
ban_user_list() ->
	case mysql_api:select([user_id], game_user, [{state, ?CONST_SYS_USER_STATE_FORBID}]) of
		{?ok, List} ->
			lists:map(fun([UserId]) -> UserId end, List);
		_Other ->
			[]
	end.

%% 查询玩家名字
get_user_name(UserId) ->
	case mysql_api:select([user_name], game_user, [{user_id, UserId}]) of
		{?ok, [[UserName]]} when is_binary(UserName) ->
			UserName;
        {?ok, [[UserName]]} when is_list(UserName) ->
            erlang:list_to_binary(UserName);
		_Other ->
			?null
	end.

%% 查询所有玩家的名字
get_user_name_id_list() ->
	case mysql_api:select([user_name, user_id], game_user, [{user_name, "<>", ""}]) of
		{?ok, List} ->
            F = fun([UserName, UserId], AccNameIdList) when is_binary(UserName) ->
						[{UserName, UserId}|AccNameIdList];
                   ([UserName, UserId], AccNameIdList) when is_list(UserName) ->
						?MSG_ERROR("UserId:~p UserName:~p", [UserId, UserName]),
						[{misc:to_binary(UserName), UserId}|AccNameIdList]
                end,
            lists:foldl(F, [], List);
		Other -> ?MSG_ERROR("Other:~p", [Other]), []
	end.

%% 查询所有玩家的账号
get_account_id_list() ->
	Where	= [{user_name, "<>", ""}, {exist, "<>", 0}, {lv, "<>", 0}, {pro, "<>", 0}, {sex, "<>", 0}],
	case mysql_api:select([account, user_id], game_user, Where) of
		{?ok, List} ->
            F = fun([Account, UserId], AccNameIdList) when is_binary(Account) ->
						case mysql_api:select_execute(<<"SELECT `user_id` FROM  `game_player` WHERE `user_id` = '",
														(misc:to_binary(UserId))/binary, "';">>) of
							{?ok,[[UserId]|_]} -> [{Account, UserId}|AccNameIdList];
							{?ok,[]} -> AccNameIdList;
							Any ->
								?MSG_ERROR("UserId:~p Account:~p Any:~p", [UserId, Account, Any]),
								AccNameIdList
						end;
                   ([Account, UserId], AccNameIdList) when is_list(Account) ->
						?MSG_ERROR("UserId:~p Account:~p", [UserId, Account]),
						[{misc:to_binary(Account), UserId}|AccNameIdList]
                end,
            lists:foldl(F, [], List);
		Other -> ?MSG_ERROR("Other:~p", [Other]), []
	end.

%% 查询所有玩家的账号
get_account_id_list_2() ->
	Where	= [{user_name, "<>", ""}, {exist, "<>", 0}, {lv, "<>", 0}, {pro, "<>", 0}, {sex, "<>", 0}],
	case mysql_api:select([account, serv_id, user_id], game_user, Where) of
		{?ok, List} ->
            F = fun([Account, ServId, UserId], AccNameIdList) when is_binary(Account) ->
						case mysql_api:select_execute(<<"SELECT `user_id` FROM  `game_player` WHERE `user_id` = '",
														(misc:to_binary(UserId))/binary, "';">>) of
							{?ok,[[UserId]|_]} -> [{{Account, ServId}, UserId}|AccNameIdList];
							{?ok,[]} -> AccNameIdList;
							Any ->
								?MSG_ERROR("UserId:~p Account:~p Any:~p", [UserId, Account, Any]),
								AccNameIdList
						end;
                   ([Account, ServId, UserId], AccNameIdList) when is_list(Account) ->
						?MSG_ERROR("UserId:~p serv_id:~p Account:~p", [UserId, ServId, Account]),
						[{{misc:to_binary(Account), ServId}, UserId}|AccNameIdList]
                end,
            lists:foldl(F, [], List);
		Other -> ?MSG_ERROR("Other:~p", [Other]), []
	end.

%% 查询所有玩家的账号-玩家id列表
get_account_user_id_list() ->
    Sql = <<"select `account`, `user_id` from `game_user` where `user_id` in (select `user_id` from `game_player`) ",
            " and `user_name` <> '' and `exist` <> '0' and `lv` <> '0' and `pro` <> '0' and `sex` <> '0' ; ">>,
    case mysql_api:select(Sql) of
        {?ok, List} ->
            F = fun([Account, UserId], OldList) ->
                        case lists:keytake(Account, 1, OldList) of
                            {value, {_, OldL}, OldList2} ->
                                Record = {Account, [UserId|OldL]},
                                [Record|OldList2];
                            _ ->
                                Record = {Account, [UserId]},
                                [Record|OldList]
                        end
                end,
            lists:foldl(F, [], List);
        Other -> 
            ?MSG_ERROR("Other:~p", [Other]), 
            []
    end.

% 查询活跃玩家ID列表
get_active_user_id() ->
	case mysql_api:select_execute(<<"SELECT `user_id` FROM `game_user` ",
									"WHERE `user_name` <> '""' ",
									"ORDER BY `logout_time_last` DESC ",
									"LIMIT ", (misc:to_binary(?CONST_START_PROLOAD_PLAYER_NUMBER))/binary, ";">>) of
		{?ok, UserIdList} -> {?ok, UserIdList};
		Error -> ?MSG_ERROR("Error get_active_user_id():~p",[Error]), {?error, Error}
	end.


%% 充值
%% 
%% E|18:20:49|<0.3680.0>|player_db_mod|704|[{0,14,0,6,0,1000,1376648449}]

 
log_deposit(PayNum, UserId, Account, Lv, PayType, Cash, Time) ->
	case mysql_api:insert_execute(<<"INSERT INTO `log_deposit` ",
									"(`id`, `user_id`, `account`, `lv`, `pay_type`, `pay_money`, `time`)",
									" VALUES (",
									" '", (misc:to_binary(PayNum))/binary, "',",
									" '", (misc:to_binary(UserId))/binary, "',",
									" '", (misc:to_binary(Account))/binary, "',",
									" '", (misc:to_binary(Lv))/binary, "',",
									" '", (misc:to_binary(PayType))/binary, "',",
									" '", (misc:to_binary(Cash))/binary, "',",
									" '", (misc:to_binary(Time))/binary, "');">>) of
        {?ok, _, _} -> ?ok;
        {?error, _ErrorCode} ->
            {?error, ?TIP_COMMON_ERROR_DB}
    end.

%% 元宝日志
log_cash(UserId, Account, Type, TypeDesc, CashChange, Cash, Time) ->
	case mysql_api:insert_execute(<<"INSERT INTO `techcenter_log_cash` ",
									"(`user_id`, `account`, `type`, `type_desc`, `cash_change`, `cash`, `time`)",
									" VALUES (",
									" '", (misc:to_binary(UserId))/binary, "',",
									" '", (misc:to_binary(Account))/binary, "',",
									" '", (misc:to_binary(Type))/binary, "',",
									" '", (misc:to_binary(TypeDesc))/binary, "',",
									" '", (misc:to_binary(CashChange))/binary, "',",
									" '", (misc:to_binary(Cash))/binary, "',",
									" '", (misc:to_binary(Time))/binary, "');">>) of
        {?ok, _, _} -> ?ok;
        {?error, _ErrorCode} ->
            {?error, ?TIP_COMMON_ERROR_DB}
    end.

%% 登陆、退出记录日志
log_in_out(Player, Type, Time) ->
	try
		UserId	= Player#player.user_id,
		SQL		= case Type of
					  ?CONST_PLAYER_LOG_TYPE_LOGIN ->
						  <<"INSERT INTO `techcenter_log_in_out` (`user_id`, `time_login`)  VALUES (",
							" '", (misc:to_binary(UserId))/binary, "', '", (misc:to_binary(Time))/binary, "');">>;
					  ?CONST_PLAYER_LOG_TYPE_LOGOUT ->
						  {UserName, Lv}	=
							  case Player#player.info of
								  #info{user_name = UserNameTmp, lv = LvTmp} -> {UserNameTmp, LvTmp};
								  _ -> {<<"新角色">>, 0}
							  end,
						  <<"UPDATE `techcenter_log_in_out` SET ",
							"`user_name` = '", (misc:to_binary(UserName))/binary,
							"', `lv` = '", (misc:to_binary(Lv))/binary,
							"', `time_logout` = '", (misc:to_binary(Time))/binary,
							"' WHERE `user_id` = ", (misc:to_binary(UserId))/binary, " and `time_logout` = 0;">>
				  end,
		mysql_api:execute_sql(SQL)
	catch
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

test(UserId) ->
	mysql_api:select_execute(<<"SELECT `user_id`, `state`",
							   "FROM `game_user` WHERE `user_id` = '",
							   (misc:to_binary(UserId))/binary, "';">>).

insert_gm_msg(UserId, GuildId, Type, Content) ->
    Sql = <<"insert into `techcenter_gm` (`account`, `ip`, `user_id`, `user_name`, `level`, `faction`, `mtime`, `mtype`, `content`)",
			" select `account`, `login_ip`, `user_id`, `user_name`, `lv`, '", 
            (misc:to_binary(GuildId))/binary, "', '",
            (misc:to_binary(misc:seconds()))/binary, "', '", 
            (misc:to_binary(Type))/binary, "', '",
            (misc:to_binary(Content))/binary,
            "' from `game_user` where `user_id` = '",
            (misc:to_binary(UserId))/binary, "';">>,
    case mysql_api:insert(Sql) of
        {?ok, _, _} -> ?ok;
        {?error, _ErrorCode} -> {?error, ?TIP_COMMON_ERROR_DB}
    end.
