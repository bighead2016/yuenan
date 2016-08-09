%% @author sitting
%% @doc @todo Add description to mixed_serv_mod.


-module(mixed_serv_api).
-include_lib("../../include/const.common.hrl").
-include_lib("../../include/const.define.hrl").
-include_lib("../../include/const.cost.hrl").
-include_lib("../../include/const.protocol.hrl").
-include_lib("record.player.hrl").

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 on_login/1,
		 on_logout/1,
		 stop_serv/0,
		 get_login_gift/1,
		 get_login_gift_info/1
		, update_db/2
		]).

%% @doc 登入 db -> ets
on_login(Player)->
	UserId = Player#player.user_id,
	case mysql_api:select(["userid","type","value","state","time","endtime"], "game_mixed_serv_activity", [{"userid", UserId}]) of
		{?ok, R} ->
			Fun = fun ([UserId, Type,Value, State, Time, EndTime]) ->
						   ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, Type},Value, State, Time, EndTime })
				  end,
			if
				length(R) > 0 ->lists:foreach(Fun, R);
			   ?true ->?ok end;
		{?error, Tip} ->
			?MSG_ERROR("on_login error Tips:~p~n", [Tip]);
		Any ->
			?MSG_ERROR("on_login error Tips:~p~n", [Any])
	end,
	Player.
%% @doc 登出 ets -> db
on_logout(Player)->
	UserId = Player#player.user_id,
	update_db(UserId, ?true).

%% @doc 更数据库
update_db(UserId, Del) ->
	case ets:select(?CONST_ETS_MIXED_SERV_ACT, [{{{UserId, '_'},'_','_','_','_'}, [], ['$_']}]) of
		'$end_of_table' ->
			?ok;
		Data ->
			Fun = fun ({{UserId, Type},Value, State, Time, EndTime }) ->
						   Sql = <<"insert into `game_mixed_serv_activity` (`userid`,`type`,`value`,`state`,`time`,`endtime`) values ('",
								   (misc:to_binary(UserId))/binary, "',' ",
								   (misc:to_binary(Type))/binary, "', ",
								   (misc:to_binary(Value))/binary, ",' ",
								   (misc:to_binary(State))/binary, "', '",
								   (misc:to_binary(Time))/binary, "',' ",
								   (misc:to_binary(EndTime))/binary, "')",
								   " ON DUPLICATE KEY UPDATE `value` = ",
								   (misc:to_binary(Value))/binary, ", `state`='",
								   (misc:to_binary(State))/binary, "', `time`='",
								   (misc:to_binary(Time))/binary, "',`endtime`='",
								   (misc:to_binary(EndTime))/binary, "';">>,
						   case Del of
							   ?true ->
								   ets:delete(?CONST_ETS_MIXED_SERV_ACT, {UserId, Type});
							   _ ->
								   ?ok
						   end,
						   mysql_api:select(Sql)
				  end,
			lists:foreach(Fun, Data)
	end,
	?ok.

%% @doc 停服 ps:暂时没用到
stop_serv()->
	mixed_serv:on_terminate().

%% @doc 获得时效登陆礼包信息
get_login_gift_info(Player)->
	UserId = Player#player.user_id,
	Now     = misc:seconds(), 
	{Begin,End} = mixed_serv_time:get_activity(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	GiftValue = 
		if 
			Now =< End andalso Begin =< Now ->
			   case ets:lookup(?CONST_ETS_MIXED_SERV_ACT, {UserId, 0}) of
				   [] ->
					   ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, 0}, 1, 0, misc:seconds(),End}),
					   ?true;
				   [{{UserId, 0},Value, _State, Time, _EndTime }] ->
					   case  misc:is_same_date(Time, Now)  of
						   ?true when Value =:= 0->
							   ?false;
						   _ ->
							   ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, 0}, 1, 0, misc:seconds(),End}),
							   ?true
					   end
			   end;
		   ?true ->
			   ?false
		end,
	pack_s(UserId, GiftValue),
	?ok.

get_login_gift(Player)->
	UserId = Player#player.user_id,
	Now     = misc:seconds(), 
	{Begin,End} = mixed_serv_time:get_activity(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	if
		Now =< End andalso Begin =< Now ->
		   case ets:lookup(?CONST_ETS_MIXED_SERV_ACT, {UserId, 0}) of
			   [] ->
				   pack_s(UserId, ?false),
				   send_gift(Player, End);
			   [{{UserId, 0},Value, _State, Time, _EndTime }] ->
				   case  misc:is_same_date(Time, Now)  of
					   ?true when Value =:= 0->
						   ?ok;
					   _ ->
						   pack_s(UserId, ?false),
						   send_gift(Player, End)
				   end
		   end;
	   ?true ->
		   ?ok
	end.
send_gift(Player, End)->
	UserId = Player#player.user_id,
	Goods = data_mixedServ_activity:get_ms_login_reward(),
	Fun = fun({Goodid, Bind, Count})->
				  goods_api:make(Goodid, Bind, Count)
		  end,
	GoodLists = lists:flatten(lists:map(Fun, Goods)),
	case ctn_bag_api:put(Player, GoodLists, ?CONST_COST_MIXED_LOGIN, 1, 1, 1, 0, 1, 1, []) of
		{?ok, Player2, _Changelist, _Packet}->
			ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, 0}, 0, 0, misc:seconds(),End}),
			admin_log_api:log_goods(Player#player.user_id, ?CONST_SYS_GOODS_MAKE, 
                                                    ?CONST_COST_MIXED_LOGIN, GoodLists, misc:seconds()),
			Packet2 = misc_packet:pack(?MSG_ID_MIXED_SERV_SC_WANT_GIFT, ?MSG_FORMAT_MIXED_SERV_SC_WANT_GIFT, [?true]),
			misc_packet:send(Player#player.user_id, Packet2),
			{?ok, Player2};
		{?error, _ErrorCode}->
			?ok
	end.


%% ====================================================================
%% Internal functions
%% ====================================================================

%% @doc pack and send
pack_s(UserId,Value) ->
	Packet = misc_packet:pack(?MSG_ID_MIXED_SERV_A_GIFT, ?MSG_FORMAT_MIXED_SERV_A_GIFT, [Value]),
	misc_packet:send(UserId, Packet).

%% @doc TODO test

