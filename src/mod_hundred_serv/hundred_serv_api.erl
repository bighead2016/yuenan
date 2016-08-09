%% @author sitting
%% @doc @todo Add description to hundred_serv_api.


-module(hundred_serv_api).

-include_lib("record.act.hrl").
-include_lib("const.common.hrl").
-include_lib("const.define.hrl").
-include_lib("record.player.hrl").
-include_lib("record.data.hrl").
-include_lib("record.base.data.hrl").
-include_lib("const.protocol.hrl").
-include_lib("const.tip.hrl").
-include_lib("const.cost.hrl").
-include_lib("record.goods.data.hrl").
-define(RECHARGEACT, 44).
-define(REFUNDACT, 45).
-define(TALK, 46).
-define(SERVERID, 100).
-define(GUILDGIFT, 45).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 recharge/2
		 , get_recharge_rank/1
		 , close_activity/1
		 , login/1
		 , logout/1
		 , server_start/0
		 , send_guild_gift/1
		 , login_packet/2
		 , check_time/1
		, talk/3
		, zero_flush/1
		]).

recharge(UserId, Cash) ->
	_ = recharge2(UserId, Cash, ?RECHARGEACT),
	_ = recharge2(UserId, Cash, ?REFUNDACT).

recharge2(UserId, Cash, ActId) ->
	case check_time(ActId) of
		?true ->
			NewPoint = 
				case ets:lookup(?CONST_ETS_ACT_HUNDRED, {UserId, ActId}) of
					[] ->
						ets:insert(?CONST_ETS_ACT_HUNDRED, #ets_act_hundred{key = {UserId, ActId},user_id = UserId, act_id = ActId, point = Cash}),
						Cash;
					[Data] ->
						Point = Data#ets_act_hundred.point + Cash,
						ets:update_element(?CONST_ETS_ACT_HUNDRED, {UserId, ActId}, {#ets_act_hundred.point, Point}),
						Point
				end,
			if ActId =:= ?RECHARGEACT ->
				   sort_rank(UserId, NewPoint);
			   ?true ->
				   ?ok
			end,
			update_db(UserId);
		_ ->
			?ok
	end.

talk(<<230,161,131,229,155,173,231,187,147,228,185,137,230,136,145,230,157,165,229,149,166>>, Player, 1) ->
	case check_time(?TALK) of
		?true ->
			Info = Player#player.info,
			Lv = Info#info.lv,
			if Lv >= 20 ->
				   talk2(Player#player.user_id);
			   ?true ->
				   ?ok
			end;
		_ ->
			?ok
	end;
talk(_, _, _)->
	ok.


talk2(UserId) ->
	case ets:lookup(?CONST_ETS_ACT_HUNDRED, {UserId, ?TALK}) of
		[] ->
			Packet = message_api:msg_notice(?TIP_HUNDRED_SERV_TALK, [{UserId, player_api:get_name(UserId)}], [], []),
			Packet2 = message_api:msg_notice(?TIP_HUNDRED_SERV_GET_BONUS),
			gateway_worker_sup:broadcast_world_2(Packet),
			misc_packet:send(UserId, Packet2),
			player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, 100, ?CONST_COST_HUNDRED_TALK),
			ets:insert(?CONST_ETS_ACT_HUNDRED, #ets_act_hundred{key = {UserId, ?TALK},user_id = UserId, act_id = ?TALK, point = 1});
		[_Data] ->
			?ok
	end.

sort_rank(UserId, NewPoint) ->
	case ets:lookup(?CONST_ETS_ACT_HUNDRED_RANK, rank) of
		[] ->
			ets:insert(?CONST_ETS_ACT_HUNDRED_RANK, {rank, [get_detail(UserId, NewPoint)]});
		[{rank, Data}] ->
			ets:insert(?CONST_ETS_ACT_HUNDRED_RANK,  {rank, sort(Data, UserId, NewPoint)})
	end,
	?ok.

%% @doc sort
sortFun({_, _, _, _, Point1},{_, _, _, _, Point2}) ->
	if Point1 =< Point2 ->
		   true;
	   true ->
		   false
	end.
sort(Rank, UserId, Point) ->
	Len = length(Rank),
	case lists:keyfind(UserId, 1, Rank) of 
		false when Len =:= 3 ->
			Rank2 = [get_detail(UserId, Point)|Rank],
			Rank3 = lists:sort(fun sortFun/2, Rank2),
			[_H|Rank4] = Rank3,
			Rank4;
		false ->
			Rank2 = [get_detail(UserId, Point)|Rank],
			lists:sort(fun sortFun/2, Rank2);
		{UserId, _, _, _, _} ->
			Rank5 = lists:keydelete(UserId, 1, Rank),
			Rank6 = [get_detail(UserId, Point)|Rank5],
			lists:sort(fun sortFun/2, Rank6)
	end.

get_detail(UserId, NewPoint) ->
	{?ok, Info} = player_api:get_player_field(UserId, #player.info),
	{UserId,Info#info.user_name,Info#info.sex,Info#info.pro,NewPoint}.

get_recharge_rank(UserId) ->
	Rank =
		case ets:lookup(?CONST_ETS_ACT_HUNDRED_RANK, rank) of
			[] ->
				[];
			[{rank, Data}] ->
				Data
		end,
	Point = 
		case ets:lookup(?CONST_ETS_ACT_HUNDRED, {UserId, ?RECHARGEACT}) of
			[] ->
				0;
			[Data2] ->
				Data2#ets_act_hundred.point
		end,
	Packet = misc_packet:pack(?MSG_ID_HUNDRED_SERV_REPLY_RANK, ?MSG_FORMAT_HUNDRED_SERV_REPLY_RANK, [Rank, Point]),
	_ = misc_packet:send(UserId, Packet).

%% check activity time, init it and set a clock when necessary
login(Player) ->
	UserId = Player#player.user_id,
	Open1 = check_time(?RECHARGEACT),
	Open2 = check_time(?REFUNDACT),
	case Open1 of
		?true->
			case mysql_api:select(["point"],  "game_hundred_serv", [{"user_id", UserId}, {"act_id", ?RECHARGEACT}]) of
				{?ok, [[R]]} ->
					ets:insert(?CONST_ETS_ACT_HUNDRED, #ets_act_hundred{key={UserId, ?RECHARGEACT}, user_id = UserId, act_id = ?RECHARGEACT, point = R} );
				_ ->
					?ok
			end,
			case mysql_api:select(["point"],  "game_hundred_serv", [{"user_id", UserId}, {"act_id", ?TALK}]) of
				{?ok, [[R2]]} ->
					ets:insert(?CONST_ETS_ACT_HUNDRED, #ets_act_hundred{key={UserId, ?TALK}, user_id = UserId, act_id = ?TALK, point = R2} );
				_ ->
					?ok
			end;
		_ ->
			?ok
	end,
	case Open2 of
		?true->
			case mysql_api:select(["point"],  "game_hundred_serv", [{"user_id", UserId}, {"act_id", ?REFUNDACT}]) of
				{?ok, [[R3]]} ->
					ets:insert(?CONST_ETS_ACT_HUNDRED, #ets_act_hundred{key={UserId, ?REFUNDACT}, user_id = UserId, act_id = ?REFUNDACT, point = R3} );
				_ ->
					?ok
			end;
		_ ->
			?ok
	end,
	ok.

zero_flush(Player)->
	Open1 = check_time(?RECHARGEACT),
	Open2 = check_time(?REFUNDACT),
	Packet1 = misc_packet:pack(?MSG_ID_HUNDRED_SERV_INFORM_OPEN, ?MSG_FORMAT_HUNDRED_SERV_INFORM_OPEN, [Open1, Open2]),
	_ = misc_packet:send(Player#player.user_id, Packet1).

login_packet(Player, Packet) ->
	Open1 = check_time(?RECHARGEACT),
	Open2 = check_time(?REFUNDACT),
	Packet1 = misc_packet:pack(?MSG_ID_HUNDRED_SERV_INFORM_OPEN, ?MSG_FORMAT_HUNDRED_SERV_INFORM_OPEN, [Open1, Open2]),
	{Player, <<Packet/binary, Packet1/binary>>}.

logout(Player) ->
	UserId = Player#player.user_id,
	update_db(UserId).

update_db(UserId) ->
	case ets:select(?CONST_ETS_ACT_HUNDRED, [{#ets_act_hundred{key='_',user_id=UserId,act_id='_',point='_'}, [], ['$_']}]) of
		'$end_of_table' ->
			?ok;
		Records ->
			Fun = fun(Record2) ->
						  Sql = <<"INSERT INTO `game_hundred_serv` (`user_id`,`act_id`,`point`) VALUES(", (misc:to_binary(UserId))/binary, ","
								  ,(misc:to_binary(Record2#ets_act_hundred.act_id))/binary,","
								  ,(misc:to_binary(Record2#ets_act_hundred.point))/binary
								  ," ) ON DUPLICATE KEY UPDATE `point` = "
								  , (misc:to_binary(Record2#ets_act_hundred.point))/binary,";">>,
						  mysql_api:execute(Sql)
				  end,
			lists:foreach(Fun,	 Records)
	end,
	?ok.

%% @return true|false
check_time(ActId)->
	ActId2 = 
		case ActId of
			?TALK ->
				?RECHARGEACT;
			Any ->
				Any
		end,
	Pid = get_platid(),
	case Pid of
		1 ->
			Now = misc:seconds(),
			{Begin, End} = data_welfare:get_deposit_active_time(ActId2),
			Sid = config:read_deep([server, base, sid]),
			if Begin =< Now andalso Now =< End ->
				   case ActId2 of
					   ?RECHARGEACT when Sid =:= ?SERVERID ->
						   ?true;
					   ?REFUNDACT ->
						   ?true;
					   _->
						   ?false
				   end;
			   ?true ->
				   ?false
			end;
		_ ->
			?false
	end.

init(ActId)->
	{_Begin, End} = data_welfare:get_deposit_active_time(ActId),
	{{_Y, Month2, Day2}, {Hour2, Min2, _}}	= misc:seconds_to_localtime(End),
	crond_api:clock_add({hundred_serv, ActId}, [Min2], [Hour2], [Day2], [Month2], [], ?MODULE, close_activity, [ActId]),
	case ActId of
		?RECHARGEACT ->
			crond_api:clock_add({hundred_serv, ActId}, [Min2], [Hour2], [Day2], [Month2], [], ?MODULE, close_activity, [?TALK]);
		_ ->
			?ok
	end,
	?ok.

server_start()->
	try
		init(?RECHARGEACT),
		init(?REFUNDACT),
		Sql = <<"SELECT `user_id`,`point` FROM `game_hundred_serv` where `act_id` = 44 ORDER BY `point` DESC LIMIT 0,3;">>,
		case mysql_api:select(Sql) of
			{?ok, R} ->
				Fun = fun([UserId, Point]) ->
							  catch recharge(UserId, Point)
					  end,
				lists:foreach(Fun, R);
			_ ->
				?ok
		end
	catch
		Err:Why ->
			?MSG_ERROR("error: ~p Why: ~p~~nstack: ~p", [Err, Why, erlang:get_stacktrace()])
	end,
	ok.

send_guild_gift(GuildId)->
	Record = data_hundred_serv:get_reward({get_platid(), ?GUILDGIFT}),
	[{_, Goodid, Bind, Count}] = Record#rec_hundred_serv.goods,
	Goods = goods_api:make(Goodid, Bind, Count), 
	mail_api:send_sys_mail_to_guild(GuildId, 3161, Goods, [{[{misc:to_list(Goodid)}]}], ?CONST_COST_HUNDRED_SERV),
	ok.

close_activity(ActId)->
	try
		case ActId of
			?RECHARGEACT ->
				close_recharge_act();
			?REFUNDACT->
				close_refund();
			_ ->
				?ok
		end,
		mysql_api:select(<<"DELETE FROM `game_hundred_serv` WHERE `act_id` = ", (misc:to_binary(ActId))/binary>>),
		ok
	catch
		E:W ->
			?MSG_ERROR("CLOSE - ACT ~nErr:~P,WHY:~P", [E,W])
	end.

close_recharge_act()->
	Record = data_hundred_serv:get_reward({get_platid(), ?RECHARGEACT}),
	{Titles, Goods} = {Record#rec_hundred_serv.title, Record#rec_hundred_serv.goods},
	case ets:lookup(?CONST_ETS_ACT_HUNDRED_RANK, rank) of
		[] ->
			[];
		[{rank, Data}] ->
			Fun = 
				fun({UserId,Name,_,_,_},Rank) ->
						case lists:keyfind(Rank, 1, Titles) of
							{Rank, _Title, AchieveId} ->
								achievement_api:add_achievement(UserId, AchieveId, 0, 1);
							_ ->
								?ok
						end,
						case lists:keyfind(Rank, 1, Goods) of
							{Rank, Goodid, Bind, Count} ->
								GoodsList = goods_api:make(Goodid, Bind, Count),
								mail_api:send_system_mail_to_one3(Name, <<>>, <<>>, 3160, [{[{misc:to_list(Rank)}]}], GoodsList, 0, 0, 0, ?CONST_COST_HUNDRED_SERV, 0);
							_ ->
								?ok
						end,
						Rank+1
				end,
			lists:foldl(Fun, 1, lists:reverse(Data))
	end,
	ets:delete_all_objects(?CONST_ETS_ACT_HUNDRED_RANK),
	?ok.

close_refund()->
	case ets:select(?CONST_ETS_ACT_HUNDRED, [{#ets_act_hundred{key='_',act_id=?REFUNDACT, point='_', user_id = '_'},[],['$_'] }], 1) of
		'$end_of_table' ->
			?ok;
		{Match, Cont} ->
			pay_back(Match),
			close_refund2(Cont)
	end.
close_refund2(Cont)->
	case ets:select(Cont) of
		'$end_of_table' ->
			?ok;
		{Match, Cont2} ->
			pay_back(Match),
			close_refund2(Cont2)
	end.
pay_back([Record|T]) ->
	ets:delete_object(?CONST_ETS_ACT_HUNDRED, Record),
	UserId = Record#ets_act_hundred.user_id,
	Cash = Record#ets_act_hundred.point,
	Refund = get_refund_num(Cash),
	if Refund > 0 ->
		   mail_api:send_system_mail_to_one3(player_api:get_name(UserId), <<>>
											 , <<>>, 3162, [{[{misc:to_list(Cash)}]},{[{misc:to_list(Refund)}]}], [], 0, 0, 0, 0, Refund);
	   ?true ->
		   ?ok
	end,
	pay_back(T);
pay_back([])->
	?ok.
%% 
%% ====================================================================
%% Internal functions
%% ====================================================================
get_platid()->
	config:read_deep([server, base, platform_id]).

get_refund_num(Cash)->
	if Cash >= 500000 ->
		   58888;
	   Cash >= 50000 ->
		   8888;
	   Cash >= 20000 ->
		   2888;
	   Cash >= 10000 ->
		   1888;
	   Cash >= 5000 ->
		   1588;
	   Cash >= 2000 ->
		   1288;
	   Cash >= 1000 ->
		   888;
	   Cash >= 500 ->
		   488;
	   Cash >= 100 ->
		   100;
	   ?true ->
		   0
	end.
