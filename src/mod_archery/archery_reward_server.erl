%% @author liuyujian
%% @doc @todo Add description to ets_archery_reward_server

-module(archery_reward_server).
-include_lib("../../include/const.common.hrl").
-include_lib("../../include/const.define.hrl").
-include_lib("../../include/const.protocol.hrl").
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3,start_link/2]).
-export([init_rank/0]).
%% ====================================================================
%% Behavioural functions 
%% ====================================================================
-record(state, {rank = []}).


%% ====================================================================
%% API functions
%% ====================================================================
-export([archery_point_change/2,archery_top_list/0,clear_list/0]).
%% ====================================================================
%% External functions
%% ====================================================================
start_link(ServName, _Cores) ->
    try
    {ok,_Pid} = gen_server:start_link({local, ServName}, ?MODULE, [],[])
    catch 
        X:Y ->
            ?MSG_ERROR("~p~n",[{X,Y,erlang:get_stacktrace()}])
    end.

%% 得到积分,调整排名,前十排名变化后要广播
archery_point_change(UserId, Point) ->
    gen_server:cast(archery_reward_server,{sort_rank,{UserId, Point}}).

%% 获得排行榜
archery_top_list() ->
	try
	Pid = whereis(archery_reward_server),
	{dictionary,Dic} = process_info(Pid,dictionary),
	{archery_reward_server, List} = lists:keyfind(archery_reward_server, 1, 	Dic),
    List
	catch
		_ ->
			[]
	end.

%% %% 0点清表
clear_list()->
    gen_server:cast(archery_reward_server,{zero_init}).

	
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
init([]) -> %%
	try
		process_flag(trap_exit, ?true),
		%% 随机数种子
		%% 		?RANDOM_SEED,
		Rank = init_rank(),
		put(archery_reward_server,Rank),
		%%     ets:new(ets_archery_gravity_t,?CONST_ETS_OPTIONAL_PARAM(1)),
%% 		ets:insert(?CONST_ETS_ARCHERY_GRAVITY_T, {gravity_t,?CONST_ARCHERY_G}),
		{ok, #state{rank = Rank}}
	catch 
        X:Y ->
            ?MSG_ERROR("~p~n",[{X,Y,erlang:get_stacktrace()}])
    end.


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
%% 维护排行榜
handle_cast({sort_rank,{UserId,_Point}=NewData}, State) ->
    Rank = State#state.rank,
	Rank7 =case lists:keyfind(UserId, 1, Rank) of 
			   false ->
				   Rank2 = [NewData|Rank],
				   Rank3 = lists:sort(fun sortFun/2, Rank2),
				   [_H|Rank4] = Rank3,
				   Rank4;
			   {UserId, _P} ->
				   Rank5 = lists:keydelete(UserId, 1, Rank),
				   Rank6 = [NewData|Rank5],
				   lists:sort(fun sortFun/2, Rank6)
		   end,
	if Rank =/= Rank7 ->
		   put(archery_reward_server,Rank7),
		   {Out, _} = lists:foldl(fun({X1,X2},{Y,Z}) ->{[{Z,X1,X2}|Y],Z-1} end, {[],10}, Rank7),
		   RankOut = lists:filter(fun({_X,_Y,Z}) ->  if Z > 0 -> ?true; ?true -> ?false end end, Out),
		   Packet = misc_packet:pack(?MSG_ID_ARCHERY_BCAST_TOP_10,?MSG_FORMAT_ARCHERY_BCAST_TOP_10,[RankOut]),
		   gateway_worker_sup:broadcast_world_2(Packet);
	   ?true ->
		   ?ok
	end,
	{noreply, State#state{rank=Rank7}};

%% 0点初始化
handle_cast({zero_init},  _State) ->
    Rank = lists:duplicate(10, {0,0}),
%%     ets:insert(ets_archery_reward_server, {rank,Rank}),
    put(archery_reward_server,Rank),
    {noreply, #state{rank = Rank} };

handle_cast(_Msg, _State) ->
    {noreply, _State}.


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
handle_info(_Info, _State) ->
    {noreply, _State}.


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
	?MSG_ERROR("archery reward server terminate ~n-------------------Reason~p~n", [Reason]),
    ok.


%% code_change/3
%% ====================================================================
%% @doc <a href="http://www.erlang.org/doc/man/gen_server.html#Module:code_change-3">gen_server:code_change/3</a>
-spec code_change(OldVsn, State :: term(), Extra :: term()) -> Result when
Result :: {ok, NewState :: term()} | {error, Reason :: term()},
OldVsn :: Vsn | {down, Vsn},
Vsn :: term().
%% ====================================================================
code_change(_OldVsn, _State, _Extra) ->
    {ok, _State}.


%% ====================================================================
%% Internal functions
%% ====================================================================

sortFun({_UserId1,Point1},{_UserId2,Point2}) ->
    if Point1 =< Point2 ->
           true;
       true ->
		   false
	end.

%% get rank data from db
init_rank()->
	try
		Time   = (misc:seconds()-28800) div 86400,
		Sql     = "select `user_id`,`point` from `game_archery_info` where `point` > 0 and time > "++misc:to_list(Time)++" order by `point` desc limit 0,10;",
		case mysql_api:select(misc:to_binary(Sql)) of
			{?ok, [?undefined]} -> lists:duplicate(10, {0,0});
			{?ok, DB} -> 
				L1 = [ {player_api:get_name(X),Y} || [X,Y]<-DB ],
				L2 = case length(L1) of 
						 Len when Len =:= 10 ->
							 [];
						 Len ->
							 lists:duplicate(10-Len, {0,0})
					 end,
				lists:sort(fun sortFun/2, L1++L2);
			_ ->
				?MSG_ERROR("Err Msg at archery_mod : get_top_list_db..",[]),
				lists:duplicate(10, {0,0})
		end
	catch
		_Any ->
			lists:duplicate(10, {0,0})
	end.

