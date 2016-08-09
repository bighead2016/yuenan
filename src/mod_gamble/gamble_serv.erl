%% @author liuyujian
%% @doc 青梅煮酒.


-module(gamble_serv).
-include_lib("const.common.hrl").
-include_lib("record.data.hrl").
-include_lib("const.define.hrl").
-include_lib("const.cost.hrl").
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 start_link/2
		, on_terminate/0
		, on_terminate2/1
		, tick1/2
]).



%% ====================================================================
%% Behavioural functions  
%% ====================================================================
% @note  playerlist = [{UserId, RoomId, RoomSid}...] 表示已经开始游戏的玩家 ；just_inroom 为gbtree，表示在房间的玩家，不一定开始游戏了
-record(state, {roomnum = 0, tick = 0, playerlist=[], just_inroom = gb_trees:empty(), windowlist = []}).


start_link(ServName, _Cores) ->
    try
    {ok,_Pid} = gen_server:start_link({local, ServName}, ?MODULE, [],[])
    catch
        X:Y ->
            ?MSG_ERROR("~p~n",[{X,Y,erlang:get_stacktrace()}])
    end.

on_terminate()->
	_ = gen_server:call(self(), {terminate}),	
	tick1(0, {serv_end, ?true}).
on_terminate2(RoomId) ->
	_ = gen_server:cast(self(), {serv_end, RoomId}).
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
	?RANDOM_SEED,% 随机数种子
	erlang:process_flag(trap_exit, ?true),
	timer:send_after(1000, self(), {tick, 1}),
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
handle_call({player_login, UserId}, _, State) ->
	PlayingList = State#state.playerlist,
	Reply = lists:keymember(UserId, 1, PlayingList),
	Tree = State#state.just_inroom,
	Tree2 =
		case gb_trees:lookup(UserId, Tree) of
		none ->
			Tree;
		{value, {RoomId, RoomSid}} ->
			gamble_api:request_leave3(UserId, RoomId, RoomSid),
			gb_trees:delete_any(UserId, Tree)
	end,
	{reply, Reply, State#state{just_inroom=Tree2}};
handle_call({terminate}, _, State) ->
	PlayingList = State#state.playerlist,
	LocalSid = gamble_api:getLocalSid(),
	Fun = 
		fun ({_UserId, RoomId, RoomSid}) when RoomSid =/= LocalSid->
				 gamble_api:pre_cast(RoomSid, ?MODULE, on_terminate2, [RoomId]);
		   (_) ->
				?ok
		end,
	Reply = lists:foreach(Fun, PlayingList),
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
%% @doc 创建房间
handle_cast({book_new_room, {UserId, Chip, Change}}, State) ->
	Roomnum = State#state.roomnum,
	LocalSid = gamble_api:getLocalSid(),
	RegName = misc:to_atom("gamble_room_"++misc:to_list(Roomnum)),
	Room = #ets_gamble_room{
							room_id = Roomnum,
							reg_name = RegName,
							player1_id = UserId,
							player2_id = 0,
							player1_sid = LocalSid,
							player2_sid = 0,
							room_state = ?CONST_GAMBLE_ROOM_STATE_Q1,
							state_time = State#state.tick,
							chip = Chip,
							player1_ready = ?CONST_GAMBLE_PLAYER_NOT_READY,
							player2_ready = ?CONST_GAMBLE_PLAYER_NOT_READY,
							winstate = [0,0]
						   },
	Playinglist = 
		case lists:keyfind(UserId, 1, State#state.playerlist) of
			?false ->
				State#state.playerlist;
			{UserId,RoomId,RoomSid} -> %退出之前的房间
				gamble_api:request_leave(UserId, RoomId, RoomSid),
				lists:keydelete(UserId,1,State#state.playerlist)
		end,
	Tree = State#state.just_inroom,
	Just_inRoom = %% 创建房间一定在本地，直接记录
		case gb_trees:lookup(UserId, Tree) of
			none ->
				gb_trees:insert(UserId, {Roomnum, LocalSid}, Tree);
			{value, {RoomId2, RoomSid2}} ->
				gamble_api:request_leave(UserId, RoomId2, RoomSid2),
				Tree2 = gb_trees:delete_any(UserId, Tree),
				gb_trees:insert(UserId, {Roomnum, LocalSid}, Tree2)
	end,
	case  gamble_room_serv:start_link(RegName, Room) of
		{?ok, Pid} when is_pid(Pid)->
			ets:insert(?CONST_ETS_GAMBLE_ROOM, Room),
			gamble_api:add_mini_room(Roomnum, Chip),
			gamble_api:reply_rooms_info(State#state.windowlist),
			gamble_api:pack_book_room(UserId, [?true, Roomnum, LocalSid, Change, Chip]);
		_ ->
			gamble_api:pack_book_room(UserId, [?false, Roomnum, LocalSid, Change, Chip])
	end,
	{noreply, State#state{roomnum = (Roomnum + 1) rem 512, playerlist = Playinglist, just_inroom = Just_inRoom}};

%% @doc 加入房间     
handle_cast({join_room, Reg, UserId, Sid, Name, Pro, Sex}, State) ->
	Playinglist = 
		case lists:keyfind(UserId, 1, State#state.playerlist) of
			?false ->
				State#state.playerlist;
			{UserId,RoomId,RoomSid} -> %退出之前的房间
				gamble_api:request_leave(UserId, RoomId, RoomSid),
				lists:keydelete(UserId,1,State#state.playerlist)
		end,
	gen_server:cast(Reg, {join_room, UserId, Sid, State#state.tick, Name, Pro, Sex}),
	{noreply, State#state{playerlist = Playinglist}};

%% @doc 请求准备
handle_cast({player_ready,Reg, UserId, Ready} , State) ->
	gen_server:cast(Reg, {player_ready, UserId, Ready, State#state.tick}),
	{noreply, State};

%% @doc 出牌
handle_cast({player_card, Reg, UserId, Card}, State)->
	gen_server:cast(Reg, {player_card, UserId, Card, State#state.tick}),
	{noreply, State};

%% @doc 记录玩家信息
handle_cast({player_onplay, UserId,RoomId, RoomSid, State2}, State) ->
	PlayingList = State#state.playerlist,
	PlayingList2 =
		case State2 of
			?true ->
				[{UserId, RoomId, RoomSid}|PlayingList];
			?false ->
				lists:keydelete(UserId, 1, PlayingList)
		end,
	{noreply, State#state{playerlist = PlayingList2}};

%% @doc 远端服务器停服
handle_cast({serv_end, RoomId}, State) ->
	case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
		[] -> %房间不存在
			?ok;
		Room ->
			Reg = Room#ets_gamble_room.reg_name,
			gen_server:cast(Reg, {serv_end, ?false})
	end,
	PlayingList = lists:keydelete(RoomId, 2, State#state.playerlist) ,
	{noreply, State#state{playerlist = PlayingList}};

%% @doc 更新房间信息,主要是加入和退出
handle_cast({room_info_changed, UserId, RoomId, RoomSid, IsIn}, State) ->
	?MSG_DEBUG("room_info_changed:~n~p", [{UserId, RoomId, RoomSid, IsIn}]),
	Tree = State#state.just_inroom,
	Just_inRoom = 
		case gb_trees:lookup(UserId, Tree) of
			none when IsIn =:= ?true->
				gb_trees:insert(UserId, {RoomId, RoomSid}, Tree);
			{value, {RoomId2, RoomSid2}} ->
				if 
					IsIn ->
						gamble_api:request_leave(UserId, RoomId2, RoomSid2),
						Tree2 =gb_trees:delete_any(UserId, Tree),
						gb_trees:insert(UserId, {RoomId, RoomSid}, Tree2);
					?true ->
						if 
							RoomId2 =:= RoomId andalso RoomSid2 =:= RoomSid-> 
								gb_trees:delete_any(UserId, Tree);
							?true ->
								Tree
						end
				end;
			_ ->
				Tree
		end,
	gamble_api:reply_rooms_info(State#state.windowlist),
	{noreply, State#state{ just_inroom = Just_inRoom }};

%% 跨服进出房间
handle_cast({cross_thing}, State) ->
	gamble_api:reply_rooms_info(State#state.windowlist),
	{noreply, State};

%% 房间关闭
handle_cast({room_dead}, State) ->
	gamble_api:reply_rooms_info(State#state.windowlist),
	{noreply, State};

%% @doc 玩家下线时，不在游戏中要退出房间
handle_cast({player_logout, UserId}, State) ->
	Tree = State#state.just_inroom,
	Tree1 = 
	case gb_trees:lookup(UserId, Tree) of
		none ->
			Tree;
		{value, {RoomId, RoomSid}} ->
			gamble_api:request_leave2(UserId, RoomId, RoomSid),
			gb_trees:delete_any(UserId, Tree)
	end,
	gen_server:cast(self(), {sub_looker, UserId}),
	{noreply, State#state{just_inroom= Tree1}};

%% @doc 玩家对返回游戏的回复
handle_cast({player_back, UserId, Yes}, State) ->
	Playinglist = State#state.playerlist,
	Tree = State#state.just_inroom,
	Tree1 =
		case lists:keyfind(UserId, 1, Playinglist) of
			{UserId, RoomId, RoomSid} ->
				gamble_api:player_back(UserId, RoomId, RoomSid, Yes),
				gb_trees:insert(UserId, {RoomId, RoomSid}, Tree);
			_ ->
				Tree
		end,
	{noreply, State#state{just_inroom= Tree1}};

%% @doc 玩家打开窗口
handle_cast({add_looker, UserId}, State) ->
	Hall = State#state.windowlist,
	Hall2 =
		case lists:member(UserId, Hall) of
			?true ->
				Hall;
			?false ->
				[UserId|Hall]
		end,
	{noreply, State#state{windowlist= Hall2}};

%% @doc 玩家关闭窗口
handle_cast({sub_looker, UserId}, State) ->
	Hall = State#state.windowlist,
	Hall2 = lists:delete(UserId, Hall),
	{noreply, State#state{windowlist= Hall2}};

handle_cast(Msg, State) ->
	?MSG_DEBUG("Unhandled Msg :~n~p~n", [Msg]),
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
handle_info({tick, Time}, State)->
	proc_lib:spawn(?MODULE,  tick1, [Time, {pulse, Time}]),
	timer:send_after(1000, self(), {tick, Time + 1}),
%% 	?MSG_DEBUG("just_inroom:~n~p", [State#state.just_inroom]),
	if (Time rem 5) =:= 0 ->
		   gamble_api:reply_rooms_info(State#state.windowlist);
	   ?true ->
		   ?ok
	end,
	{noreply, State#state{tick = Time}};
handle_info({'EXIT', _, normal}, State)->
	{noreply, State};
handle_info(Info, State) ->
	?MSG_DEBUG("Unhandled Info: ~n~p", [Info]),
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
terminate(normal, _State) ->
	?ok;
terminate(Reason, _State) ->
	?MSG_ERROR("gamble_serv terminate~n--------------------------~nReason:~p~n", [Reason]),
    ?ok.

%% ====================================================================
%% Internal functions
%% ====================================================================
%% @doc 每秒报时
tick1(Time, Msg)->
	case ets:select(?CONST_ETS_GAMBLE_ROOM
					, [{#ets_gamble_room{
										 room_id = '_'
										 , reg_name = '$1' %房间进程注册名
										 , player1_id = '_'
										 , player1_sid = '_'
										 , player2_id = '_'
										 , player2_sid =  '_'
										 , room_state =  '_'
										 , state_time = '_'
										 , player1_score = '_'
										 , player2_score  = '_'
										 , player1_cards =  '_'
										 , player2_cards =  '_'
										 , chip  =  '_'
										 , round  =  '_'
										 , history = '_'
										 , player1_ready  = '_'
										 , player2_ready  = '_'
										 , player1_card  = '_'
										 , player2_card  = '_'
										},[],['$1'] }], 1) of
		'$end_of_table' ->
			?ok;
		{Match,Continuation} ->
			inform_children(Match, Time, Msg),
			tick2(Continuation, Time, Msg)
	end.
tick2(Continuation, Time, Msg)->
	case ets:select(Continuation) of
		'$end_of_table'->
			?ok;
		{Match,Continuation2} ->
			inform_children(Match, Time, Msg),
			tick2(Continuation2, Time, Msg)
	end.
inform_children([ChildReg|T], Time, Msg) ->
	try
		if 
			is_atom(ChildReg) ->
				ChildReg ! Msg;
			?true ->
				%!error
				?ok
		end
	catch 
		error:badarg ->
			case ets:select(?CONST_ETS_GAMBLE_ROOM
							, [{#ets_gamble_room{
												 room_id = '_'
												 , reg_name = ChildReg %房间进程注册名
												 , player1_id = '_'
												 , player1_sid = '_'
												 , player2_id = '_'
												 , player2_sid =  '_'
												 , room_state =  '_'
												 , state_time = '_'
												 , player1_score = '_'
												 , player2_score  = '_'
												 , player1_cards =  '_'
												 , player2_cards =  '_'
												 , chip  =  '_'
												 , round  =  '_'
												 , history = '_'
												 , player1_ready  = '_'
												 , player2_ready  = '_'
												 , player1_card  = '_'
												 , player2_card  = '_'
												},[],['$_'] }]) of
				[R] ->
					_ = ets:delete_object(?CONST_ETS_GAMBLE_ROOM, R);
				_ ->
					?ok
			end;
		Err:Why->
			?MSG_DEBUG("~p:~p", [Err, Why])
	end,
	inform_children(T, Time, Msg);
inform_children([],_T, _Msg) ->
	?ok.
		  

