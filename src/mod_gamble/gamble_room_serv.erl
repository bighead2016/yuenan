%% @author liuyujian
%% @doc 青梅煮酒房间，处理房间中所有玩家操作的逻辑.

-module(gamble_room_serv).
-include_lib("const.common.hrl").
-include_lib("const.define.hrl").
-include_lib("record.player.hrl").
-include_lib("record.data.hrl").
-include_lib("const.cost.hrl").
-behaviour(gen_server).
-define(NOROOM, [?false,0,"",0,0,0,0,0,0,0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 start_link/2]).



%% ====================================================================
%% Behavioural functions 
%% ====================================================================

start_link(ServName, Args)->
	misc_app:gen_server_start_link(ServName, ?MODULE	, Args).

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
init(Args) ->
    ?RANDOM_SEED,% 随机数种子
    {ok, Args}.


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

%% @doc 平局
handle_cast({game_tie},  #ets_gamble_room{room_state=RState}=State)
	when  RState =:= ?CONST_GAMBLE_ROOM_STATE_PLAYING->
	UserId1 = State#ets_gamble_room.player1_id,
	UserSid1 = State#ets_gamble_room.player1_sid,
	UserId2 = State#ets_gamble_room.player2_id,
	UserSid2 = State#ets_gamble_room.player2_sid,
	Chip = State#ets_gamble_room.chip,
	%% 记录玩家游戏结束，方便掉线捞回
	RoomId = State#ets_gamble_room.room_id,
	RoomSid = UserSid1,
	gamble_api:player_onplay(UserId1, UserSid1, RoomId, RoomSid, ?false),
	gamble_api:player_onplay(UserId2, UserSid2, RoomId, RoomSid, ?false),
	_ = gamble_api:change_chip(Chip, UserId1, UserSid1, 0, Chip, State#ets_gamble_room.player1_ready),
	_ = gamble_api:change_chip(Chip, UserId2, UserSid2, 0, Chip, State#ets_gamble_room.player2_ready),
	_ = gamble_api:pack_gamble_result(UserId1, UserSid1, Chip, 0), %通报游戏结果
	_ = gamble_api:pack_gamble_result(UserId2, UserSid2, Chip, 0),
	_ = gen_server:cast(gamble_serv, {cross_thing}),
	if State#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
		   gen_server:cast(self(), {leave_room, UserId2 });
	   ?true ->
		   ?ok
	end,
	if State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
		   gen_server:cast(self(), {leave_room, UserId1 });
	   ?true ->
		   ?ok
	end,
	{noreply, State#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_NO_READY, player1_ready = ?CONST_GAMBLE_PLAYER_NOT_READY, player2_ready = ?CONST_GAMBLE_PLAYER_NOT_READY, winstate=[0,0]}};

%% @doc 因为停服导致的平局
handle_cast({serv_end, Local}, #ets_gamble_room{room_state=RState}=State)
  when  RState =:= ?CONST_GAMBLE_ROOM_STATE_PLAYING->
	UserId1 = State#ets_gamble_room.player1_id,
	UserSid1 = State#ets_gamble_room.player1_sid,
	UserId2 = State#ets_gamble_room.player2_id,
	UserSid2 = State#ets_gamble_room.player2_sid,
	%% 记录玩家游戏结束，方便掉线捞回
	RoomId = State#ets_gamble_room.room_id,
	Chip = State#ets_gamble_room.chip,
	RoomSid = UserSid1,
	gamble_api:player_onplay(UserId1, UserSid1, RoomId, RoomSid, ?false),
	gamble_api:player_onplay(UserId2, UserSid2, RoomId, RoomSid, ?false),
	_ = gamble_api:change_chip(Chip, UserId1, UserSid1, 0, Chip, State#ets_gamble_room.player1_ready),
	_ = gamble_api:change_chip(Chip, UserId2, UserSid2, 0, Chip, State#ets_gamble_room.player2_ready),
	_ = gamble_api:pack_gamble_result(UserId1, UserSid1, Chip, 0, Chip), %通报游戏结果
	_ = gamble_api:pack_gamble_result(UserId2, UserSid2, Chip, 0, Chip),
	case Local of
		?true -> %本地停服
			_ = gamble_api:mail_outcome(UserId1, UserSid1, 0, 0),
			_ = mail_api:send_system_mail_to_one3(player_api:get_name(UserId1), "", "", 3154, [], [], 0, 0, 0, 0, 0),
			_ = gen_server:cast(self(), {leave_room, UserId1}),
			_ = gamble_api:pack_tip_tie(UserId2, UserSid2);
		_ ->
			_ = gamble_api:mail_outcome(UserId2, UserSid2, 0, 0),
			_ = gen_server:cast(self(), {leave_room, UserId2}),
			_ = gamble_api:pack_tip_tie(UserId1, UserSid1)
	end,
	_ = gamble_api:change_chip(Chip, UserId1, UserSid1),
	_ = gamble_api:change_chip(Chip, UserId2, UserSid2),
	_ = gen_server:cast(gamble_serv, {cross_thing}),
	{noreply, State#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_NO_READY, player1_ready = ?CONST_GAMBLE_PLAYER_NOT_READY, player2_ready = ?CONST_GAMBLE_PLAYER_NOT_READY}};

%% @doc 玩家获胜
handle_cast({winer, Player}, #ets_gamble_room{room_state=RState}=State) 
  when is_integer(Player) andalso RState =:= ?CONST_GAMBLE_ROOM_STATE_PLAYING->
	Chip = State#ets_gamble_room.chip,
	{Chip1, Chip2, Win1, Win2} =
		if
			Player =:= 1 ->
				{Chip * 2, 0, 1, 2};
			?true ->
				{0 , Chip * 2, 2, 1}
		end,
	UserId1 = State#ets_gamble_room.player1_id,
	UserSid1 = State#ets_gamble_room.player1_sid,
	UserId2 = State#ets_gamble_room.player2_id,
	UserSid2 = State#ets_gamble_room.player2_sid,
	%% 记录玩家游戏结束，方便掉线捞回
	RoomId = State#ets_gamble_room.room_id,
	RoomSid = UserSid1,
	_ = gamble_api:player_onplay(UserId1, UserSid1, RoomId, RoomSid, ?false),
	_ = gamble_api:player_onplay(UserId2, UserSid2, RoomId, RoomSid, ?false),
	_ = gamble_api:change_chip(Chip1, UserId1, UserSid1, Win1, Chip, State#ets_gamble_room.player1_ready),
	_ = gamble_api:change_chip(Chip2, UserId2, UserSid2, Win2, Chip, State#ets_gamble_room.player2_ready),
	_ = gamble_api:pack_gamble_result(UserId1, UserSid1, Chip, Win1),%通报游戏结果
	_ = gamble_api:pack_gamble_result(UserId2, UserSid2, Chip, Win2),
	Log = {UserId1, UserSid1 bsr 10, UserSid1 rem 1024, Chip1, UserId2, UserSid2 bsr 10, UserSid2 rem 1024, Chip2},
	_ = gamble_api:log_chip(UserSid1, Log),
	_ = gamble_api:log_chip(UserSid2, Log),
	if State#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
		   gen_server:cast(self(), {leave_room, UserId2 });
	   ?true ->
		   ?ok
	end,
	if State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
		   gen_server:cast(self(), {leave_room, UserId1 });
	   ?true ->
		   ?ok
	end,
	NewWinState =
		case State#ets_gamble_room.winstate of
			[Player,WinRound] ->
				[Player, WinRound+1];
			_ ->
				[Player, 1]
		end,
	_ = gamble_api:make_trick(State, NewWinState),
	{noreply, State#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_NO_READY, player1_ready = ?CONST_GAMBLE_PLAYER_NOT_READY, player2_ready = ?CONST_GAMBLE_PLAYER_NOT_READY,winstate=NewWinState}};

%% @doc 开启游戏
handle_cast({init_game, Time}, State)->
	State2 = gamble_init(State, Time),
	%% 记录开局的玩家，方便掉线捞回
	RoomId = State#ets_gamble_room.room_id,
	RoomSid = State#ets_gamble_room.player1_sid,
	_ = gamble_api:player_onplay(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, RoomId, RoomSid, ?true),
	_ = gamble_api:player_onplay(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, RoomId, RoomSid, ?true),
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State2),
	{noreply, State2};

%% @doc 玩家准备|取消准备
handle_cast({player_ready, UserId, Ready, Time}, State) ->
	State2 = 
		if 
			State#ets_gamble_room.player1_id =:= UserId ->
				gamble_api:pack_inform_ready(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, [UserId, Ready]),
			   State#ets_gamble_room{player1_ready = Ready, state_time = Time};
		   ?true ->
			   gamble_api:pack_inform_ready(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, [UserId, Ready]),
			   State#ets_gamble_room{player2_ready = Ready, state_time = Time}
		end,
	State3 =
		if 
			State2#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_READY andalso State2#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_READY
																						 andalso State2#ets_gamble_room.room_state =:= ?CONST_GAMBLE_ROOM_STATE_ONE_READY->
			   gen_server:cast(self(), {init_game, Time}),
			   State2#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_PLAYING};
		   (State2#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_READY orelse State2#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_READY)
			   andalso State2#ets_gamble_room.player1_sid > 0 andalso State2#ets_gamble_room.player2_sid>0->
			   State2#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_ONE_READY};
		   State2#ets_gamble_room.player1_sid > 0 andalso State2#ets_gamble_room.player2_sid>0 ->
			   State2#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_NO_READY};
		   ?true ->
			   State2#ets_gamble_room{room_state = ?CONST_GAMBLE_ROOM_STATE_Q1}
		end,
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State3),
	{noreply, State3};

%% @doc 换房间筹码
handle_cast({new_chip, Chip}, State)->
	State2 = State#ets_gamble_room{chip = Chip},
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State2),
	{noreply, State2};

%% @doc 加入房间
handle_cast({join_room, UserId, Sid, Tick, Name, Pro, Sex}, State)->
	?MSG_DEBUG("~p(~p) join ~p~n", [Name, UserId, self()]),
	State2 =
		case State#ets_gamble_room.player2_id of
			Id when Id =:= 0 -> %可以加入
				RoomState = 
					if
						State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_READY ->
							?CONST_GAMBLE_ROOM_STATE_ONE_READY;
						?true ->
							?CONST_GAMBLE_ROOM_STATE_NO_READY
					end,
				UserId2 = State#ets_gamble_room.player1_id,
				Info =
					case player_api:get_player_field(UserId2, #player.info) of
						{?error, _} ->
							?ok; % !error
						{?ok, Ok}->
							Ok
					end,
				% 通知其他地方，房间已经满了
				_ = gen_server:cast(gamble_serv, {cross_thing}),
				gamble_api:pack_join_room(UserId, Sid, 
										  [?true, UserId2, Info#info.user_name
										   , Info#info.pro, Info#info.sex, gamble_api:getLocalSid()
										  , State#ets_gamble_room.room_id
										  , State#ets_gamble_room.player1_ready
										  , State#ets_gamble_room.chip
										  , Sid]),
				gamble_api:pack_inform_join(UserId2, {UserId, Sid, Name, Pro, Sex}),
				gamble_api:change_room_info(UserId, Sid, State#ets_gamble_room.room_id, State#ets_gamble_room.player1_sid, ?true),
				State#ets_gamble_room{
									  player2_id = UserId,
									  player2_sid = Sid,
									  room_state = RoomState,
									  state_time = Tick,
									  player2_ready = ?CONST_GAMBLE_PLAYER_NOT_READY
									 };
			_ -> %房间已满
				gamble_api:pack_tip_full_player(UserId, Sid),
				gamble_api:pack_join_room(UserId, Sid, ?NOROOM),
				State
		end,
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State2),
	{noreply, State2};

%% @doc 离开房间
handle_cast({leave_room, UserId}, State) ->
	Player1_id = State#ets_gamble_room.player1_id,
	Player1_sid = State#ets_gamble_room.player1_sid,
	Player2_id = State#ets_gamble_room.player2_id,
	Player2_sid = State#ets_gamble_room.player2_sid,
	Player1_ready = State#ets_gamble_room.player1_ready,
	Player2_ready = State#ets_gamble_room.player2_ready,
	Chip = State#ets_gamble_room.chip,
	RoomId = State#ets_gamble_room.room_id,
	State2 = 
		case UserId of
			Player1_id -> %房主离开
				gamble_api:pack_inform_leave(Player2_id, Player2_sid, [Player1_id]),
				if 
					Player2_ready =:= ?CONST_GAMBLE_PLAYER_READY andalso Player2_id > 0->
						gamble_api:pack_tip_leave(Player2_id, Player2_sid); % TIP 对方已经离开
					?true ->
						?ok
				end,
				if
					Player2_id =/= 0 ->
						%% 房间转移
						gamble_api:book_new_room(Player2_id, Player2_sid, Chip, ?true);
					?true->
						?ok
				end,
				self() ! {stop, normal},
				ets:delete(?CONST_ETS_GAMBLE_ROOM, RoomId),
				gamble_api:player_onplay(Player1_id, Player1_sid, RoomId, Player1_sid, ?false),
				gamble_api:change_room_info(Player1_id, Player1_sid, RoomId, Player1_sid, ?false),
				State;
			Player2_id ->
				if 
					Player1_ready =:= ?CONST_GAMBLE_PLAYER_READY andalso Player2_id > 0->
						gamble_api:pack_tip_leave(Player1_id, Player1_sid);%  TIP 对方已经离开
					?true ->
						?ok
				end,
				_ = gamble_api:pack_inform_leave(Player1_id, Player1_sid, [Player2_id]),
				State3 = State#ets_gamble_room{player2_id = 0, player2_sid = 0, room_state = ?CONST_GAMBLE_ROOM_STATE_Q1,player1_ready=?CONST_GAMBLE_PLAYER_NOT_READY,player2_ready=?CONST_GAMBLE_PLAYER_NOT_READY},
				_ = ets:insert(?CONST_ETS_GAMBLE_ROOM, State3),
				_ = gamble_api:player_onplay(Player2_id, Player2_ready, RoomId, Player1_sid, ?false),
				_ = gamble_api:change_room_info(Player2_id, Player2_sid, RoomId, Player1_sid, ?false),
				_ = gen_server:cast(gamble_serv, {cross_thing}),
				State3;
			_ ->
				State
		end,
	{noreply, State2#ets_gamble_room{winstate=[0,0]}};	

%% @doc 玩家放弃退出
handle_cast({player_give_up, UserId}, State) ->
	Player1_id = State#ets_gamble_room.player1_id,
	Player1_sid = State#ets_gamble_room.player1_sid,
	Player2_id = State#ets_gamble_room.player2_id,
	Player2_sid = State#ets_gamble_room.player2_sid,
	if 
		UserId =:= Player1_id ->
			gamble_api:pack_tip_excape(Player2_id, Player2_sid),
			gen_server:cast(self(), {winer, 2}),
			gen_server:cast(self(), {leave_room, UserId});
		?true ->
			gamble_api:pack_tip_excape(Player1_id, Player1_sid),
			gen_server:cast(self(), {winer, 1}),
			gen_server:cast(self(), {leave_room, UserId})
	end,
	{noreply, State};
			
%% @doc 出牌
handle_cast({player_card, UserId, Card, _Tick}, State) ->
	State2 =
		if 
			State#ets_gamble_room.player1_id =:= UserId andalso State#ets_gamble_room.player1_card =:= 0->
				L1 = lists:delete(Card, State#ets_gamble_room.player1_cards),
				Len2 = length(State#ets_gamble_room.player1_cards),
				{Card2, Player_cards1} =
					case length(L1) of
						Len2 ->
							[C1|T1] = L1,
							{C1, T1};
						_ ->
							{Card, L1}
					end,
				State#ets_gamble_room{player1_card = Card2, player1_cards = Player_cards1};
			State#ets_gamble_room.player2_card =:= 0 ->
				L2 = lists:delete(Card, State#ets_gamble_room.player2_cards),
				Len3 = length(State#ets_gamble_room.player2_cards),
				{Card3, Player_cards2} =
					case length(L2) of
						Len3 ->
							[C2|T2] = L2,
							{C2, T2};
						_ ->
							{Card, L2}
					end,
				State#ets_gamble_room{player2_card = Card3, player2_cards = Player_cards2};
			?true ->
				State
		end,
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State2),
	{noreply, State2};	

%% @doc 请求出牌历史
handle_cast({player_want_history, UserId}, State) ->
	History = State#ets_gamble_room.history ,
	{History2, Sid} =
		if
			State#ets_gamble_room.player1_id =:= UserId ->
				{History, State#ets_gamble_room.player1_sid};
			?true ->
				{[{C2, C1} || {C1, C2} <- History], State#ets_gamble_room.player2_sid}
		end,
	gamble_api:pack_inform_history(UserId, Sid, [History2]),
	{noreply, State};

%% @doc 再来一局
handle_cast({play_again, UserId, Again}, State) ->
	case Again of
		?true ->
			case gamble_api:check_chip(UserId, State#ets_gamble_room.chip) of
				?true ->
					gen_server:cast(gamble_serv, {player_ready, self(), UserId, ?CONST_GAMBLE_PLAYER_NOT_READY});
				_ ->
					?ok
			end;
		_ ->
			gen_server:cast( self(), {leave_room, UserId})
	end,
	{noreply, State};

%% @doc 玩家返回游戏答复
handle_cast({player_back, UserId, Yes}, State) ->
	Player1_id = State#ets_gamble_room.player1_id,
	Player1_sid = State#ets_gamble_room.player1_sid,
	Player2_id = State#ets_gamble_room.player2_id,
	Player2_sid = State#ets_gamble_room.player2_sid,
	State2 =
		case Yes of
			?true ->
				gen_server:cast(self(),{player_want_history, UserId}),
				if UserId =:= Player1_id ->
					   gamble_api:player_need_room_back(Player1_id, Player1_sid, 
														Player2_id, Player2_sid, State#ets_gamble_room.room_id, Player1_sid, State#ets_gamble_room.chip ),
					   gamble_api:pack_inform_user_back(Player2_id, Player2_sid),
					   State#ets_gamble_room{player1_ready = ?CONST_GAMBLE_PLAYER_ON};
				   UserId =:= Player2_id ->
					   gamble_api:player_need_room_back(Player2_id, Player2_sid, 
														Player1_id, Player1_sid, State#ets_gamble_room.room_id, Player1_sid, State#ets_gamble_room.chip ),
					   gamble_api:pack_inform_user_back(Player1_id, Player1_sid),
					   State#ets_gamble_room{player2_ready = ?CONST_GAMBLE_PLAYER_ON};
				   ?true ->
					   State
				end;
			_ ->
				gen_server:cast(self(), {player_give_up, UserId}),
				State
		end,
	{noreply, State2};

%% @doc 玩家掉线
handle_cast({player_lost, UserId}, State) ->
	Player1_id = State#ets_gamble_room.player1_id,
	Player1_sid = State#ets_gamble_room.player1_sid,
	Player2_id = State#ets_gamble_room.player2_id,
	Player2_sid = State#ets_gamble_room.player2_sid,
	State2 =
		if State#ets_gamble_room.room_state =:= ?CONST_GAMBLE_ROOM_STATE_PLAYING ->
			   case UserId of
				   Player1_id ->
					   gamble_api:pack_inform_user_lost(Player2_id, Player2_sid),
					   State#ets_gamble_room{player1_ready = ?CONST_GAMBLE_PLAYER_LOST};
				   _ ->
					   gamble_api:pack_inform_user_lost(Player1_id, Player1_sid),
					   State#ets_gamble_room{player2_ready = ?CONST_GAMBLE_PLAYER_LOST}
			   end;
		   ?true ->
			   State
			end,
		{noreply, State2};

handle_cast(Msg, State)->
	?MSG_DEBUG("Unhandled Cast :~n~p~n", [Msg]),
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
%% @doc 时钟脉冲
handle_info({pulse, Time}, State) ->
	RoomState = State#ets_gamble_room.room_state,
	StateTime = State#ets_gamble_room.state_time,
	Rem = (Time - StateTime) rem ?CONST_GAMBLE_15_SECOND,
	Rem2 = (Time - StateTime) rem 30,
%% 	?MSG_DEBUG("Room: ~p, Rem: ~p", [State#ets_gamble_room.room_id, Rem2]),
	State2 =
		case RoomState of
			?CONST_GAMBLE_ROOM_STATE_PLAYING when Rem2 =:= 0->
				gambling(State, Time);
			?CONST_GAMBLE_ROOM_STATE_PLAYING 
			  when State#ets_gamble_room.player1_card > 0
											 andalso  State#ets_gamble_room.player2_card > 0->
				gambling(State, Time);
			?CONST_GAMBLE_ROOM_STATE_PLAYING 
			  when  State#ets_gamble_room.player1_card > 0 andalso State#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
				gambling(State, Time);
			?CONST_GAMBLE_ROOM_STATE_PLAYING 
			  when  State#ets_gamble_room.player2_card > 0 andalso State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
				gambling(State, Time);
			?CONST_GAMBLE_ROOM_STATE_PLAYING 
			  when  State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_LOST
											  andalso State#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_LOST ->
				gambling(State, Time);
			?CONST_GAMBLE_ROOM_STATE_ONE_READY when Rem =:= 0->
				?MSG_DEBUG("KICK~n" ,[]),
				kick_noready(State, Time);
			_ ->
				State
		end,
	ets:insert(?CONST_ETS_GAMBLE_ROOM, State2),
	{noreply, State2};
handle_info({serv_end}, State)->
	gen_server:cast(self(), {serv_end}),
	{noreply, State};
handle_info({stop, Reason}, State)->
	{stop, Reason, State};
handle_info(Info, State) ->
	?MSG_DEBUG("Unhandled Info:~p~n", [Info]),
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
terminate(normal, State) ->
	gen_server:cast(gamble_serv, {room_dead}),
	gamble_api:sub_mini_room(State#ets_gamble_room.room_id),
	?ok;
terminate(Reason, State) ->
	gen_server:cast(gamble_serv, {room_dead}),
	gamble_api:sub_mini_room(State#ets_gamble_room.room_id),
	?MSG_ERROR("gamble_room terminate~n--------------------------~nReason:~p~n", [Reason]),
    ?ok.


%% ====================================================================
%% Internal functions
%% ====================================================================
%% @doc 对弈
%% @return ets_gamble_room
gambling(State, Time)->
	{C1, State1} = players_card(1, State),
	{C2, State2} = players_card(2, State1),
	{Score1, Score2} = 
	if 
		C1 > C2 ->
		   % player 1 win this round
			gamble_api:pack_reply_result(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, [State#ets_gamble_room.player1_id,C1+C2,?false,C1,C2]),
			gamble_api:pack_reply_result(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, [State#ets_gamble_room.player1_id,C1+C2,?false,C1,C2]),
			{C1 + C2, 0};
	   C1 < C2 ->
		   % player 2 win this round
			gamble_api:pack_reply_result(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, [State#ets_gamble_room.player2_id,C1+C2,?false,C2,C1]),
			gamble_api:pack_reply_result(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, [State#ets_gamble_room.player2_id,C1+C2,?false,C2,C1]),
			{0, C1 + C2};
	   ?true ->
		   % tie
			gamble_api:pack_reply_result(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, [0,0,?true,C1,C2]),
			gamble_api:pack_reply_result(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, [0,0,?true,C1,C2]),
            {C1, C2}
	end,
	NewRound = State2#ets_gamble_room.round+1,
	{NewScore1, NewScore2} = {check_winer(1, Score1, State2), check_winer(2, Score2, State2)},
	check_winer2(NewScore1, NewScore2, NewRound),
	History = [{C1,C2} | State2#ets_gamble_room.history],
	State2#ets_gamble_room{player1_score=NewScore1, player2_score = NewScore2, round = NewRound, state_time = Time,history = History, player1_card = 0, player2_card = 0}.

%% @doc T掉不准备玩家
%% @return ets_gamble_room
kick_noready(State, Time)->
	if
		State#ets_gamble_room.player1_ready =:= ?CONST_GAMBLE_PLAYER_NOT_READY->
			%% player1 leave
			UserId = State#ets_gamble_room.player1_id,
			State2 = State#ets_gamble_room{room_state= ?CONST_GAMBLE_ROOM_STATE_Q1, state_time = Time},
			gamble_api:pack_tip_kick_out(UserId, State#ets_gamble_room.player1_sid),
			gen_server:cast(self(), {leave_room, UserId}),
			State2;
		State#ets_gamble_room.player2_ready =:= ?CONST_GAMBLE_PLAYER_NOT_READY->
			%% player2 leave
			UserId = State#ets_gamble_room.player2_id,
			State3 =State#ets_gamble_room{room_state= ?CONST_GAMBLE_ROOM_STATE_Q1, state_time = Time},
			gamble_api:pack_tip_kick_out(UserId, State#ets_gamble_room.player2_sid),
			gen_server:cast(self(), {leave_room, UserId}),
			State3;
		?true ->
			State
	end.
%% @doc 游戏初始化
%% @return ets_gamble_room
gamble_init(State, Time)->
	Cards = [1,2,3,4,5],
	Chip = State#ets_gamble_room.chip * (-1),
	Player1_id = State#ets_gamble_room.player1_id,
	Player1_sid = State#ets_gamble_room.player1_sid,
	Player2_id = State#ets_gamble_room.player2_id,
	Player2_sid = State#ets_gamble_room.player2_sid,
	gamble_api:pack_game_start(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid),
	gamble_api:pack_game_start(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid),
	_ = gamble_api:change_chip(Chip, Player1_id, Player1_sid),
	_ = gamble_api:change_chip(Chip, Player2_id, Player2_sid),
	State#ets_gamble_room{
						  room_state = ?CONST_GAMBLE_ROOM_STATE_PLAYING,
						  state_time = Time,
						  player1_score = 0,
						  player2_score = 0,
						  player1_cards = Cards,
						  player2_cards = Cards,
						  player1_ready = ?CONST_GAMBLE_PLAYER_ON,
						  player2_ready = ?CONST_GAMBLE_PLAYER_ON,
						  player1_card = 0,
						  player2_card = 0,
						  history = [],
						  round = 1
						  }.
%% @doc 获取选手出牌，未出牌则随机出牌
%% @return {card::integer(), NewState}
players_card(Player, State) when is_integer(Player)->
	{_,_,MicroS} = erlang:now(),
	case Player of
		1 ->
			C1 = State#ets_gamble_room.player1_card,
			if 
				C1 =:= 0 -> %自动出牌
				   Len1 = length(State#ets_gamble_room.player1_cards),
				   if
					   Len1 > 0 ->
%% 						   gamble_api:pack_inform_play(State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid),
							Randon1 = (MicroS bsr Len1) rem Len1 +1,
						   PickCard = lists:nth(Randon1, State#ets_gamble_room.player1_cards),
						   Cards1 = lists:delete(PickCard, State#ets_gamble_room.player1_cards),
						   {PickCard, State#ets_gamble_room{player1_cards = Cards1} };
					   ?true ->
						   gen_server:cast(self(), {game_tie}),
						  {0,State}
				   end;
			   ?true ->
				   {C1, State}
			end;
		2 ->
			C4 = State#ets_gamble_room.player2_card,
			if 
				C4 =:= 0 ->%自动出牌
				   Len2 = length(State#ets_gamble_room.player2_cards),
				   if
					   Len2 > 0 ->
%% 						   gamble_api:pack_inform_play(State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid),
							Randon2 = (MicroS bsl Len2) rem Len2 +1,
						   PickCard2 = lists:nth(Randon2, State#ets_gamble_room.player2_cards),
						   Cards2 = lists:delete(PickCard2, State#ets_gamble_room.player2_cards),
						   {PickCard2, State#ets_gamble_room{player2_cards = Cards2} };	
					   ?true ->
						   gen_server:cast(self(), {game_tie}),
						  {0,State}
				   end;
			   ?true ->
				   {C4, State}
			end;
		_ ->
			% !error
			{0, State}
	end.
%% @doc 检查有没有人超过15分
%% @return NewScore
check_winer(Player, AddScore, State) when is_integer(Player), is_record(State, ets_gamble_room)->
	Score1 = 
		case Player of
			1 ->
				State#ets_gamble_room.player1_score;
			2 ->
				State#ets_gamble_room.player2_score;
			_ ->
				% !error
				0
		end,
	Score2 = Score1 + AddScore,
	if Score2 >= ?CONST_GAMBLE_WIN_POINT ->
		   Score2;
	   ?true ->
		   Score2
	end.
check_winer2(Score1, Score2, Round) ->
	if Score2 >= ?CONST_GAMBLE_WIN_POINT andalso Score1 =/= Score2 ->
		   gen_server:cast(self(), {winer, 2});
	   Score1 >= ?CONST_GAMBLE_WIN_POINT andalso Score1 =/= Score2  ->
		   gen_server:cast(self(), {winer, 1});
	   Round =:= 6 ->
		    gen_server:cast(self(), {game_tie});
	   ?true ->
		   ?ok
	end.




