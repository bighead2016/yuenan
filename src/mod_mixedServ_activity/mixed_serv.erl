%% @author liuyujian
%% @doc activity               dict  value(key =  {state, Type} )
%%              not start            undefined|ended
%%              start                    start
%%              end                      ended                          note:已结算


-module(mixed_serv).
-include_lib("../../include/const.common.hrl").
-include_lib("../../include/const.define.hrl").
-include_lib("../../include/const.protocol.hrl").
-include_lib("record.data.hrl").
-include_lib("const.cost.hrl").
-include_lib("record.player.hrl").
-include_lib("record.guild.hrl").
-include("record.base.data.hrl").
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 start_link/2,
		 get_rank/2,
		 add_recharge/2,
		 add_consume/2,
		 on_terminate/0,
		 arise_refresh/0,
		 close_activity/1,
		 init_dict/1,
		 
		 test_dict_info/1,
		 test_refresh/1,
		 test_init_all/0,
		 test_close_activity/1
		]).

-record(state, {}).


start_link(ServName, _Cores) ->
    try
    {ok,_Pid} = gen_server:start_link({local, ServName}, ?MODULE, [],[])
    catch 
        X:Y ->
            ?MSG_ERROR("~p~n",[{X,Y,erlang:get_stacktrace()}])
    end.
%% ===================================================================
%% @doc 获得排行榜
%% @para Player Type
%% ===================================================================
get_rank(Player, Type)->
	case check_time(?CONST_MIXED_SERV_ACTIVITY_LOGIN) of
		?true ->
			case check_start(Type) of
				?true ->
					?ok;
				?false ->
					case  check_time(Type) of
						?true-> 
							gen_server:cast(?MODULE, {init_activity, Type}),
							throw(?ok);
						?false -> ?ok
					end
			end,
			Data = get_dict_rank(Type),
			Packet = format_rank(Player, Data, Type),
			send_packet(Player, Packet);
		?false ->
			case check_need_close(Type) of
				?true ->
					close_activity(Type);
				?false ->
					?ok
			end
	end,
	?ok.
get_dict_rank(Type) when is_integer(Type)->
	Pid = whereis(?MODULE),
	{dictionary,Dic} = process_info(Pid,dictionary),
	{{rank, Type}, List} = 
		case lists:keyfind({rank, Type}, 1, 	Dic) of 
			?false -> 
				gen_server:cast(?MODULE, {force_refresh, Type}), 
				{{rank, Type}, ?false};
			Ok -> 
				Ok 
		end,
	case List of
		?false ->
			[];
		Rank ->
			Rank
	end.
%% @parm Type Data
%% @private
save_dict_rank(Type, Data)->
    put({rank, Type}, Data),
	?ok.
%% @private
init_dict(?CONST_MIXED_SERV_ACTIVITY_RECHARGE)->
	{Begin, _End} = get_time(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	Sql     = "select `userid`,`value` from `game_mixed_serv_activity` where `value` > 0 and type = 1 and time > "++misc:to_list(Begin)++" order by `value` desc limit 0,10;",
	Rank = case mysql_api:select(misc:to_binary(Sql)) of
			   {?ok, [?undefined]} -> lists:duplicate(10, {0,0});
			   {?ok, DB} -> 
				   L1 = [ {X,Y} || [X,Y]<-DB ],
				   L2 = case length(L1) of 
							Len when Len =:= 10 ->
								[];
							Len ->
								lists:duplicate(10-Len, {0,0})
						end,
				   lists:sort(fun sortFun/2, L1++L2);
			   _ ->
				   ?MSG_ERROR("init_dict",[]),
				   lists:duplicate(10, {0,0})
		   end,
	ets:insert(?CONST_ETS_MIXED_SERV, {{rank, recharge}, Rank}),
	erlang:put({rank, recharge}, Rank);
%% @private
init_dict(?CONST_MIXED_SERV_ACTIVITY_CONSUME)->
	{Begin, _End} = get_time(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	Sql     = "select `userid`,`value` from `game_mixed_serv_activity` where `value` > 0 and type = 2  and time > "++misc:to_list(Begin)++" order by `value` desc limit 0,10;",
	Rank = case mysql_api:select(misc:to_binary(Sql)) of
			   {?ok, [?undefined]} -> lists:duplicate(10, {0,0});
			   {?ok, DB} -> 
				   L1 = [ {X,Y} || [X,Y]<-DB ],
				   L2 = case length(L1) of 
							Len when Len =:= 10 ->
								[];
							Len ->
								lists:duplicate(10-Len, {0,0})
						end,
				   lists:sort(fun sortFun/2, L1++L2);
			   _ ->
				   ?MSG_ERROR("init_dict",[]),
				   lists:duplicate(10, {0,0})
		   end,
	ets:insert(?CONST_ETS_MIXED_SERV, {{rank, consume}, Rank}),
	erlang:put({rank, consume}, Rank). 
%% @private
set_dict_recharge(Rank)->
	ets:insert(?CONST_ETS_MIXED_SERV, {{rank, recharge}, Rank}),
	erlang:put({rank, recharge}, Rank).
get_dict_recharge()->
	case ets:lookup(?CONST_ETS_MIXED_SERV, {rank, recharge}) of
		[{{rank, recharge}, Data}]   ->
			Data;
		_ ->
			init_dict(?CONST_MIXED_SERV_ACTIVITY_RECHARGE),
			get_dict_recharge()
	end.
%% @private
set_dict_consume(Rank)->
	ets:insert(?CONST_ETS_MIXED_SERV, {{rank, consume}, Rank}),
	erlang:put({rank, consume}, Rank).
get_dict_consume()->
	case ets:lookup(?CONST_ETS_MIXED_SERV, {rank, consume}) of
		[{{rank, consume}, Data}] ->
			Data;
		_ ->
			init_dict(?CONST_MIXED_SERV_ACTIVITY_CONSUME),
			get_dict_consume()
	end.
format_rank(Player, Data, Type)->
	UserId = Player#player.user_id,
	SelfPoint = 
		case Type of
			?CONST_MIXED_SERV_ACTIVITY_RECHARGE ->
				{{_, _},Value, _, _, _} = get_user_ets(UserId, ?CONST_MIXED_SERV_ACTIVITY_RECHARGE),
				Value;
			?CONST_MIXED_SERV_ACTIVITY_CONSUME ->
				{{_, _},Value, _, _, _} = get_user_ets(UserId, ?CONST_MIXED_SERV_ACTIVITY_CONSUME),
				Value;
			?CONST_MIXED_SERV_ACTIVITY_POWER->
				partner_api:caculate_camp_power(UserId);
			?CONST_MIXED_SERV_ACTIVITY_DEVIL->
				tower_api:get_top_pass(UserId);
			?CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA ->
				partner_api:caculate_camp_power(UserId);
			?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER ->
				Guild = Player#player.guild,
				GuildId = Guild#guild.guild_id,
				case GuildId of
					0 ->
						?undefined;
					Gid ->
						case mysql_api:select(["rank"], "game_guild_rank", [{"guild_id",Gid}]) of
							{?ok,[[Gid2]]} ->Gid2;
							_ ->?undefined
						end
				end
		end,
	misc_packet:pack(?MSG_ID_MIXED_SERV_RANK_LIST, 
					 ?MSG_FORMAT_MIXED_SERV_RANK_LIST,
					 [Type,Data,misc:to_binary(SelfPoint)]).
send_packet(Player, Packet)->
	misc_packet:send(Player#player.user_id, Packet),
	?ok.
check_time(Type)-> 
	{Start, End} = get_time(Type) ,
	Now = misc:seconds(),
	if Now >= Start andalso Now =< End ->
		   ?true;
	   ?true ->
		   ?false
	end.
check_start(Type) ->
	Pid = whereis(?MODULE),
	{dictionary,Dic} = process_info(Pid,dictionary),
	case lists:keyfind({state, Type}, 1, 	Dic) of
		{{state, Type},start} ->
			?true;
		_ ->
			?false
	end.
check_ended(Type)->
	Pid = whereis(?MODULE),
	{dictionary,Dic} = process_info(Pid,dictionary),
	case lists:keyfind({state, Type}, 1, 	Dic) of
		{{state, Type},ended} ->
			?true;
		_ ->
			?false
	end.
check_need_close(Type) ->
	case check_ended(Type) of
		?true ->
			?false;
		?false ->
			case check_start(Type)of
				?true ->
					?start;
				?false ->
					?false
			end
	end.
add_recharge(UserId, Point) ->
	try
		case check_time(?CONST_MIXED_SERV_ACTIVITY_RECHARGE) of 
			?true ->
				{{UserId, Type},Value, State, Time, EndTime } = get_user_ets(UserId, ?CONST_MIXED_SERV_ACTIVITY_RECHARGE),
				ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, Type},Value+Point, State, Time, EndTime }),
				mixed_serv_api:update_db(UserId, ?false),
				gen_server:cast(?MODULE, {add_recharge, UserId, Value+Point});
			?false ->
				case check_need_close(?CONST_MIXED_SERV_ACTIVITY_RECHARGE) of
					?true ->
						close_activity(?CONST_MIXED_SERV_ACTIVITY_RECHARGE);
					?false ->
						?ok
				end
		end
	catch
		Err:Why ->
			?MSG_ERROR("error: ~p Why: ~p~~nstack: ~p", [Err, Why, erlang:get_stacktrace()])
	end,
	?ok.
add_consume(UserId, Point) ->
	try
		case check_time(?CONST_MIXED_SERV_ACTIVITY_CONSUME) of 
			?true -> 
				{{UserId, Type},Value, State, Time, EndTime } = get_user_ets(UserId, ?CONST_MIXED_SERV_ACTIVITY_CONSUME),
				ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, Type},Value+Point, State, Time, EndTime }),
				mixed_serv_api:update_db(UserId, ?false),
				gen_server:cast(?MODULE, {add_consume, UserId, Value+Point});
			?false ->
				case check_need_close(?CONST_MIXED_SERV_ACTIVITY_RECHARGE) of
					?true ->
						close_activity(?CONST_MIXED_SERV_ACTIVITY_RECHARGE);
					?false ->
						?ok
				end
		end
	catch
		Err:Why ->
			?MSG_ERROR("error: ~p Why: ~p~~nstack: ~p", [Err, Why, erlang:get_stacktrace()])
	end,
	?ok.
arise_refresh()->
	gen_server:cast(?MODULE, {refresh}).
%% @doc should active this before terminate server
on_terminate() ->
	gen_server:cast(?MODULE, {terminate}),
	?ok.
%% @doc 获取时效数据
get_user_ets(UserId, Type) ->
	Now = misc:seconds(),
	{_Start, End} = get_time(Type) ,
	case ets:lookup(?CONST_ETS_MIXED_SERV_ACT, {UserId, Type}) of
		[{{UserId, Type},Value, State, Time, EndTime }]  ->
			if EndTime < Now -> 
				   ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId, Type},Value, State, Now, End}),
				   {{UserId, Type},Value, State, Now, End};
			   ?true ->
				   {{UserId, Type},Value, State, Time, EndTime }
			end;
		_ ->
			case mysql_api:select(["userid","type","value","state","time","endtime"], "game_mixed_serv_activity", [{"userid", UserId}, {"type", Type}]) of
				{?ok, [[UserId1, Type1,Value1, State1, Time1, EndTime1]]} ->
					ets:insert(?CONST_ETS_MIXED_SERV_ACT, {{UserId1, Type1},Value1, State1, Time1, EndTime1 }),
					{{UserId1, Type1},Value1, State1, Time1, EndTime1 };
				_ ->
					{{UserId, Type},0, 0, Now, End}
			end
	end.
%% init/1
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:init-1">gen_server:init/1</a>
-spec init(Args :: term()) -> Result when
	Result :: {ok, State}
			| {ok, State, Timeout}
			| {ok, State, hibernate}
			| {stop, Reason :: term()}
			| ignore,
	State :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
init([]) ->
	process_flag(trap_exit, true),
	init_activity_time(),
	one_hour_clock(),
	refresh_guild2(),
	ets:delete_all_objects(?CONST_ETS_MIXED_SERV),
    {ok, #state{}}.


%% handle_call/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_call-3">gen_server:handle_call/3</a>
-spec handle_call(Request :: term(), From :: {pid(), Tag :: term()}, State :: term()) -> Result when
	Result :: {reply, Reply, NewState}
			| {reply, Reply, NewState, Timeout}
			| {reply, Reply, NewState, hibernate}
			| {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason, Reply, NewState}
			| {stop, Reason, NewState},
	Reply :: term(),
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity,
	Reason :: term().
%% ====================================================================
handle_call({terminate}, _From, State) ->
    {reply, ?ok, State};
handle_call({test_init_all},_From,State)->
	Reply =  lists:foreach(fun init_activity/1, lists:seq(1, 6)),
	{reply, Reply, State};
handle_call({test_refresh, Type}, _From, State)->
	Reply =  refresh(Type),
	{reply, Reply, State};
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


%% handle_cast/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_cast-2">gen_server:handle_cast/2</a>
-spec handle_cast(Request :: term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_cast({init_activity, Type}, State) ->
	_ = init_activity(Type),
	{noreply, State};
%% @doc refresh all type of data
handle_cast({refresh}, State) ->
	L = lists:seq(1, 6),
	lists:map(fun refresh/1, L),
	{noreply, State};
%% @doc 更新充值排行
handle_cast({add_recharge, UserId, Point}, State) ->
	R = get_dict_recharge(),
	R2 = sort(R, UserId, Point),
	set_dict_recharge(R2),
    {noreply, State};
%% @doc 更新消费排行
handle_cast({add_consume, UserId, Point}, State) ->
	R = get_dict_consume(),
	R2 = sort(R, UserId, Point),
	set_dict_consume(R2),
	{noreply, State};
handle_cast({close_activity, Type}, State)->
	try
	case check_ended(Type) of
		?false ->
			if Type =/= 0 ->
				   refresh(Type,?true),
				   sendMail(Type),
				   sendTitle(Type);
			   ?true ->
				   crond_api:interval_del({?MODULE, 0}),
				   clearAllDict()
			end,
			put({state, Type}, ended),
			clearDB(Type),
			crond_api:clock_del({?MODULE, Type});
		?true ->
			?ok
	end
	catch 
        X:Y ->
            ?MSG_ERROR("~p~n",[{X,Y,erlang:get_stacktrace()}])
    end,
	{noreply, State};
handle_cast({force_refresh, Type}, State)->
	refresh(Type, ?true),
	{noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.


%% handle_info/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:handle_info-2">gen_server:handle_info/2</a>
-spec handle_info(Info :: timeout | term(), State :: term()) -> Result when
	Result :: {noreply, NewState}
			| {noreply, NewState, Timeout}
			| {noreply, NewState, hibernate}
			| {stop, Reason :: term(), NewState},
	NewState :: term(),
	Timeout :: non_neg_integer() | infinity.
%% ====================================================================
handle_info(_Info, State) ->
    {noreply, State}.


%% terminate/2
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:terminate-2">gen_server:terminate/2</a>
-spec terminate(Reason, State :: term()) -> Any :: term() when
	Reason :: normal
			| shutdown
			| {shutdown, term()}
			| term().
%% ====================================================================
terminate(Reason, _State) ->
	?MSG_ERROR("mixed_serv terminate~n--------------------------~nReason:~p~n", [Reason]),
    ok.


%% ====================================================================
%% Internal functions
%% ====================================================================

%% ====================================================================
%% @doc 活动初始化
%%             1,充值;2,消费;3,战力;4,破阵;5,竞技场;6,军团
%% ====================================================================
init_activity(Type) ->
	case check_start(Type) of
		?false ->
			recover_title(Type),
			init_data(Type),
			init_clock(Type),
			clearDB2(Type),
			put({state, Type}, start);
		?true ->
			?ok
	end,
	?ok.

%% @doc 回收称号
recover_title(Type)->
	case mysql_api:select(["userid","state"],"game_mixed_serv_activity",[{"state", "!=", "0"},{"type", Type}]) of
		{?ok, [_H|_T] = Data} ->
			Fun = fun([UserId, TitleId])->
						  achievement_api:delete_title(UserId, TitleId)
				  end,
			lists:foreach(Fun, Data);
		_ ->
			?ok
	end.

%% @doc 初始化数据，存入字典,设置定时更新数据
init_data(Type) when is_integer(Type)->
	if Type =:=  ?CONST_MIXED_SERV_ACTIVITY_RECHARGE orelse Type =:= ?CONST_MIXED_SERV_ACTIVITY_CONSUME->
		   init_dict(Type);
	   ?true ->
		   ?ok
	end,
	arise_refresh(),
    ?ok.
one_hour_clock()->
	{_, End} = get_time(0),
	{{_Y, Month, Day}, {Hour, Min, _}}	= misc:seconds_to_localtime(End+60),
    crond_api:interval_add(mixed_serv_intervel, 3600, ?MODULE, arise_refresh, []),
	crond_api:clock_add({?MODULE, 0}, [Min], [Hour], [Day], [Month], [], ?MODULE, close_activity, [0]),
	?ok.
%% @doc 设置活动结算定时, 记入字典活动已经初始化
%% @private
init_clock(Type)->
	{_, End} = get_time(Type),
	{{_Y, Month, Day}, {Hour, Min, _}}	= misc:seconds_to_localtime(End),
	crond_api:clock_add({?MODULE, Type}, [Min], [Hour], [Day], [Month], [], ?MODULE, close_activity, [Type]),
	put({state, Type}, start),
    ?ok.
%% ====================================================================
%% @doc 活动结算
%% ====================================================================
close_activity(Type)->
	gen_server:cast(?MODULE, {close_activity,Type}).

%% @doc 发送称号奖励
sendTitle(Type)->
	Reward = data_mixedServ_activity:get_ms_reward(Type),
	Titles= Reward#rec_mixed_serv_reward.title,
	Rank = lists:reverse(get_dict_rank(Type)),
	Rank2 = [ R || {R, _, _, _, _, _} <- Rank],
	Fun = 
		fun(UID,N)->
				case lists:keyfind(N, 1, Titles) of
					?false ->
						N+1;
					{N, TitleId, AchieveId} ->
						achievement_api:add_achievement(UID, AchieveId, 0, 1),
						catch recordTitle(TitleId, UID, Type),
						N+1
				end
		end,
	lists:foldr(Fun, 1, Rank2),
	?ok.
sendMail(Type)->
	Reward = data_mixedServ_activity:get_ms_reward(Type),
	Goods = Reward#rec_mixed_serv_reward.goods,
	GuildGoods = Reward#rec_mixed_serv_reward.guildgoods,
	Rank = lists:reverse(get_dict_rank(Type)),
	Rank2 = [ {UID, GuildName} || {UID, _, _, _, _, GuildName} <- Rank],
	Fun = 
		fun({UID, GuildName},N)->
				case lists:keyfind(N, 1, Goods) of
					?false ->
						N+1;
					{N, Goods2} ->
						Fun = fun({Goodid, Bind, Count}, Acc)->
									  goods_api:make(Goodid, Bind, Count)++Acc
							  end,
						GoodLists = lists:foldl(Fun, [], Goods2),
						mail_api:send_interest_mail_to_one3(player_api:get_name(UID), <<>>, <<>>, get_messageId(Type), [{[{misc:to_list(N)}]}], GoodLists, 0, 0, 0, ?CONST_COST_MIXED_RANK, 0),
						if Type =:= ?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER ->
							   GuildId = guild_api:get_guild_id_by_name(GuildName),
							   case lists:keyfind(N, 1, GuildGoods) of
								   {N, Goods3} ->
									   GoodLists2 = lists:foldl(Fun, [], Goods3),
									   mail_api:send_sys_mail_to_guildmember(GuildId, get_messageId(Type), GoodLists2, [{[{misc:to_list(N)}]}], ?CONST_COST_MIXED_RANK);
								   _ ->
									   ?ok
							   end;
						   ?true ->
							   ?ok
						end,
						N+1
				end
		end,
	lists:foldr(Fun, 1, Rank2),
	?ok.
get_messageId(Type)->
	case Type of
		?CONST_MIXED_SERV_ACTIVITY_RECHARGE ->
			?CONST_MAIL_MIXED_RECHARGE;
		?CONST_MIXED_SERV_ACTIVITY_CONSUME ->
			?CONST_MAIL_MIXED_CONSUME;
		?CONST_MIXED_SERV_ACTIVITY_POWER ->
			?CONST_MAIL_MIXED_POWER;
		?CONST_MIXED_SERV_ACTIVITY_DEVIL ->
			?CONST_MAIL_MIXED_DEVIL;
		?CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA ->
			?CONST_MAIL_MIXED_SINGLE_PK;
		?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER ->
			?CONST_MAIL_MIXED_GUILD_POWER
	end.
%% @doc 记录本次活动称号获得者
recordTitle(TitleId, UID, Type)->
	case ets:select(?CONST_ETS_MIXED_SERV_ACT, [{{{UID, Type},'_','_','_','_'}, [], ['$_']}]) of
		[] ->
			mysql_api:insert("game_mixed_serv_activity", ["userid","type","value","state","time","endtime"]
					, [misc:to_binary(UID), misc:to_binary(Type), 0, misc:to_binary(TitleId), misc:to_binary(misc:seconds()), misc:to_binary(0)]);
		Data ->
			Fun = fun ({{UserId, Type},_Value, _State, Time, EndTime }) ->
						   Sql = <<"insert into `game_mixed_serv_activity` (`userid`,`type`,`value`,`state`,`time`,`endtime`) values ('",
								   (misc:to_binary(UserId))/binary, "',' ",
								   (misc:to_binary(Type))/binary, "', ",
								   (misc:to_binary(0))/binary, ",' ",
								   (misc:to_binary(TitleId))/binary, "', '",
								   (misc:to_binary(Time))/binary, "',' ",
								   (misc:to_binary(EndTime))/binary, "')",
								   " ON DUPLICATE KEY UPDATE `value` = ",
								   (misc:to_binary(0))/binary, ", `state`='",
								   (misc:to_binary(TitleId))/binary, "', `time`='",
								   (misc:to_binary(Time))/binary, "',`endtime`='",
								   (misc:to_binary(EndTime))/binary, "';">>,
						   mysql_api:select(Sql)
				  end,
			lists:foreach(Fun, Data)
	end,
	?ok.
%% @doc  clear process dict
%% @private
clearAllDict()->
	L = lists:seq(1, 6),
	lists:foreach(fun clearDict/1, L).
clearDict(Type)->
	erase({rank, Type}),
	if Type =:= ?CONST_MIXED_SERV_ACTIVITY_RECHARGE ->
		   erase({rank, recharge});
	   Type =:= ?CONST_MIXED_SERV_ACTIVITY_CONSUME ->
		   erase({rank, consume});
	   ?true ->
		   ?ok
	end,
	put({state, Type}, ended),
	?ok.
%% @doc  clear data in database 
clearDB(Type)->
	mysql_api:delete("game_mixed_serv_activity", "state = 0 and type="++misc:to_list(Type)),
	ets:select_delete(?CONST_ETS_MIXED_SERV_ACT, [{{{'_', Type},'_','_','_','_'}, [], [true]}]),
	?ok.
clearDB2(Type)->
	{Begin, _} = get_time(?CONST_MIXED_SERV_ACTIVITY_LOGIN),
	mysql_api:delete("game_mixed_serv_activity", "type="++misc:to_list(Type)++" AND time < "++misc:to_list(Begin)),
	?ok.
%% @doc 刷新排行榜
refresh(Type)->refresh(Type, ?false).
refresh(Type, Force)->
	Ok = 
		case Force of
			 ?true -> ?true;
			 _ ->check_time(Type)
		 end,
	case Ok of 
		?true ->
			case Type of
				?CONST_MIXED_SERV_ACTIVITY_RECHARGE ->
					refresh_recharge();
				?CONST_MIXED_SERV_ACTIVITY_CONSUME ->
					refresh_consume();
				?CONST_MIXED_SERV_ACTIVITY_POWER ->
					refresh_power();
				?CONST_MIXED_SERV_ACTIVITY_DEVIL ->
					refresh_devil();
				?CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA ->
					refresh_single_arena();
				?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER ->
					refresh_guild()
			end;
		_ -> ?ok
	end.
%% @doc 1,充值   2,消费;3,战力;4,破阵;5,竞技场;6,军团
refresh_recharge() ->
	init_dict(?CONST_MIXED_SERV_ACTIVITY_RECHARGE),
	R = get_dict_recharge(),
	R2 = format(R),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_RECHARGE, R2),
	?ok.
%% @doc 消费 2
refresh_consume()->
	init_dict(?CONST_MIXED_SERV_ACTIVITY_CONSUME),
	R = get_dict_consume(),
	R2 = format(R),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_CONSUME, R2),
	?ok.
%% @doc 战力 3
refresh_power()->
	Sql     = "select `user_id` from `game_player_rank` where `power` > 0 order by `power` desc limit 0,10;",
	{?ok, Data} = mysql_api:select(Sql),
	R2 = [ {UserId, partner_api:caculate_camp_power(UserId)} || [UserId] <- Data],
	R3 = [{UserId, Power} || {UserId,Power} <- R2, Power > 0],
	R4 = format(lists:reverse(R3)),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_POWER, R4),
	?ok.
%% @doc 破阵 4
refresh_devil()->
	Sql     = "select `user_id` from `game_player_rank` where `devil_copy` > 0 order by `devil_copy` DESC ,`devil_time` ASC ,`user_id` ASC limit 0,10;",
	{?ok, Data} = mysql_api:select(Sql),
	R2 = [ {UserId, tower_api:get_top_pass(UserId)} || [UserId] <- Data],
	R3 = [{UserId, Power} || {UserId,Power} <- R2, Power > 0],
	R4 = format(lists:reverse(R3)),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_DEVIL, R4),
	?ok.
%% @doc 竞技场 5
refresh_single_arena()->
	R = single_arena_api:get_single_arena_top_rank_ets(?CONST_MIXED_SERV_ACTIVITY_PLAYER_COUNT),
	R2 = [ {UserId ,partner_api:caculate_camp_power(UserId)} || {_Rank ,UserId} <- R ],
	R3 = [{UserId, Power} || {UserId,Power} <- R2, Power > 0],
	R4 = format(R3),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA, R4),
	?ok.
%% @doc 军团 6
refresh_guild()->
	refresh_guild2(),
	Sql     = "select `guild_id` from `game_guild_rank`order by `rank` ASC limit 0,3;",
	{?ok, Data} = mysql_api:select(Sql),
	Fun = fun (Guild_Id) -> 
				   case ets:lookup(?CONST_ETS_GUILD_DATA, Guild_Id) of
					   [Guild] when is_record(Guild, guild_data) ->
						   {?ok, [[GuildPower]]} = mysql_api:select(["power"], "game_rank_guild", [{"guild_id", misc:to_list(Guild#guild_data.guild_id)}]),
						   {Guild#guild_data.chief_id, GuildPower, Guild#guild_data.guild_name};
					   Wrong  ->
								   ?MSG_ERROR("wrong Guild_Id:~p, can't find player detail info--------------~nmessage:~p ", [Guild_Id, Wrong]),
								   {?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
						   end
			end,
	R2 = [Fun(Guild_id) || [Guild_id] <- Data],
	R3 = [{ChiefId, Power, Name} || {ChiefId, Power, Name} <-R2, ChiefId > 0 ],
	R4 = format(lists:reverse(R3)),
	save_dict_rank(?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER	, R4),
	?ok.
refresh_guild2()->
	Sql = "TRUNCATE `game_guild_rank`; ",
	Sql2 = "INSERT INTO `game_guild_rank`(`guild_id`) SELECT `game_rank_guild`.`guild_id` FROM `game_rank_guild` ORDER BY `game_rank_guild`.`power` DESC;",
	A =  mysql_api:select(Sql),
	B = mysql_api:select(Sql2),
	{A,B}.
%% @doc sort
sortFun({_UserId1,Point1},{_UserId2,Point2}) ->
    if Point1 < Point2 ->
           ?true;
       ?true ->
		   ?false
	end.
sort(Rank, UserId, Point) ->
	case lists:keyfind(UserId, 1, Rank) of 
		false ->
			Rank2 = [{UserId, Point}|Rank],
			Rank3 = lists:sort(fun sortFun/2, Rank2),
			[_H|Rank4] = Rank3,
			Rank4;
		{UserId, _P} ->
			Rank5 = lists:keydelete(UserId, 1, Rank),
			Rank6 = [{UserId, Point}|Rank5],
			lists:sort(fun sortFun/2, Rank6)
	end.
%% @doc player detail desc
player_detail(UserId) ->
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} when is_record(Player, player) ->
			Info = Player#player.info,
			[Player#player.user_id,
			 Info#info.user_name,
			 %%   Info#info.lv,
			 Info#info.sex,
			 Info#info.pro
%% 			 goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
%% 			 goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
%% 			 goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR)
			];
		Wrong ->
			?MSG_ERROR("wrong userid:~p, can't find player detail info--------------~nmessage:~p ", [UserId, Wrong]),
			[]
	end.
%% format 
format(R) -> format(R, []).
format([], Acc) -> Acc;
format([{UserId, Point}|Tail], Acc) when UserId > 0->
	format(Tail, [misc:to_tuple(player_detail(UserId)++[misc:to_binary(Point),"null"])|Acc]);
format([{UserId, Ele1, Ele2}|Tail], Acc)  when UserId > 0->
	format(Tail, [misc:to_tuple(player_detail(UserId)++[misc:to_binary(Ele1), Ele2])|Acc]);
format([_H|T], Acc) ->
	format(T, Acc).
%% @doc get from ets_rank_data 这个ets很难用，就不用这个数据源
%% @para Num Type
get_ets_rank_data(Num, T) ->
	get_ets_rank_data(1, Num, [], T).
get_ets_rank_data(From, To, Acc,_T) when From > To -> Acc;
get_ets_rank_data(From, To, Acc,T) ->
	case ets:select(?CONST_ETS_RANK_DATA, [{{{T,From},'$1', '_','_','$2','$3', '_', '_', '_'}, [], ['$$']}]) of
		'$end_of_table' ->
			get_ets_rank_data(From+1, To, Acc, T);
		[] ->
			get_ets_rank_data(From+1, To, Acc, T);
		[Result|_] ->
			get_ets_rank_data(From+1, To, [Result|Acc], T)
	end.
%% @doc 获取活动时间
get_time(Type)->
	ActivityID = 
		case Type  of
			?CONST_MIXED_SERV_ACTIVITY_RECHARGE ->
				?CONST_MIXED_SERV_ACTIVITY_TIME_RE;
			?CONST_MIXED_SERV_ACTIVITY_CONSUME ->
				?CONST_MIXED_SERV_ACTIVITY_TIME_CO;
			?CONST_MIXED_SERV_ACTIVITY_POWER->
				?CONST_MIXED_SERV_ACTIVITY_TIME_POWER;
			?CONST_MIXED_SERV_ACTIVITY_DEVIL->
				?CONST_MIXED_SERV_ACTIVITY_TIME_DEVIL;
			?CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA ->
				?CONST_MIXED_SERV_ACTIVITY_TIME_SA;
			?CONST_MIXED_SERV_ACTIVITY_GUILD_POWER ->
				?CONST_MIXED_SERV_ACTIVITY_TIME_GUILD;
			_ -> % 登入礼包活动
				?CONST_MIXED_SERV_ACTIVITY_LOGIN
		end,
	mixed_serv_time:get_activity(ActivityID).

%% @doc 编译合服活动时间
init_activity_time()->
	Head = "-module(mixed_serv_time). \n-compile(export_all). \n"++
	"get_begin()->
    {Y, M, D, H, Min, S} = config:read_deep([server, release, combined_time]),
	misc:date_time_to_stamp({Y, M, D, H, Min, S}). \n",
	Alltimes = data_welfare:get_deposit_time_all(),
	Body = [ " get_activity("++misc:to_list(A#rec_welfare_deposit_time.group_id)++")->{get_begin(), get_begin()+"
				 ++misc:to_list(?CONST_SYS_ONE_DAY_SECONDS*(A#rec_welfare_deposit_time.time_last))++"}; \n" 
			 || A <- Alltimes , A#rec_welfare_deposit_time.group_type =:= 4],
	Src = Head++lists:concat(Body)++" get_activity(_)->{0, 0}. ",
	{Mod, Code} = dynamic_compile:from_string(Src),
	code:load_binary(Mod, "mixed_serv_time.erl", Code).
%% =========================================================================
%% @doc test
%% =========================================================================
test_dict_info(Type) ->
	Data = get_dict_rank(Type),
	?MSG_DEBUG("Dict Type:~p~n----------------------------~nData:~n~p~n", [Type, Data]),
	[Type, Data].
test_refresh(Type)->
	gen_server:call(?MODULE, {test_refresh, Type}).
test_init_all()->
	one_hour_clock(),
	gen_server:call(?MODULE, {test_init_all}).
test_close_activity(Type)->
	close_activity(Type).