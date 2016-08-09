%% @author sitting
%% @doc @todo Add description to gamble_api.


-module(gamble_api).
-include_lib("const.common.hrl").
-include_lib("const.define.hrl").
-include_lib("const.protocol.hrl").
-include_lib("record.data.hrl").
-include_lib("const.cost.hrl").
-include_lib("const.tip.hrl").
-include_lib("record.player.hrl").
-define(NOROOM, [?false,0,"",0,0,0,0,0,0,0]).
%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 change_chip/6
		 , change_chip/3
		 , on_login/1
		 , on_logout/1
		 , send_to_user/3
		 , reply_rooms_info/1
		 , book_new_room/4
		 , join_new_room/6
		 , request_leave/3
		 , request_leave2/3
		 , request_leave3/3
		 , request_ready/4
		 , play_card1/3
		 , play_card2/4
		 , player_give_up/3
		 , player_want_history/3
		 , player_onplay/5
		 , request_chip/1
		 , request_chip2/1
		 , exchange_chip/2
		 , change_room_chip/4
		 , play_again/4
		 , check_chip/2
		 , change_room_info/5
		 , mail_outcome/4
		 , add_mini_room/2
		 , sub_mini_room/1
		 , getLocalSid/0
		 , get_node/1
		 , login_packet/2
		 , exchange4chip/2
		 , player_come_back/2
		 , player_back/4
		 , player_need_room_back/7
		 , player_need_room_back2/7
		 , join_cross_room/6
		 , join_new_room/3
		 , pick_tip_no_cross_room/1
		 , try_to_match_cross/2
		 , invite/4
		 , log_chip/2
		 , pre_cast/4
		 , make_trick/2
		 , msg_notice/7
		
		 , pack_book_room/2
		 , pack_join_room/3
		 , pack_inform_join/2
		 , pack_inform_leave/3
		 , pack_inform_ready/3
		 , pack_inform_play/2
		 , pack_inform_user_back/2
		 , pack_inform_user_lost/2
		 , pack_game_start/2
		 , pack_reply_result/3
		 , pack_gamble_result/4
		 , pack_inform_history/3
		 , pack_tip_full_player/2
		 , pack_tip_kick_out/2
		 , pack_tip_leave/2
		 , pack_tip_tie/2
		 , pack_tip_exchange_bat/3
		 , pack_tip_exchange_cash/3
		 , pack_tip_excape/2
		 , pack_reply_chip/2
		]).

add_mini_room(RoomId, Chip) ->
	?MSG_DEBUG("add_mini_room :~p" , [{RoomId, Chip}]),
	CenterNode = manage_api:get_man_node(),
	rpc:cast(CenterNode, center_gamble_serv, add_room, [#ets_gamble_room_mini{key = {RoomId, node()}, chip = Chip}]).

sub_mini_room(RoomId) ->
	CenterNode = manage_api:get_man_node(),
	rpc:cast(CenterNode, center_gamble_serv, sub_room, [{RoomId, node()}]).

%% @doc 登入
on_login(Player) when is_record(Player, player)->
	UserId = Player#player.user_id,
	case mysql_api:select(["user_id", "chips", "timestamp", "times"]	, "game_gamble_player", [{"user_id", UserId}]) of
		{?ok, [[UserId, Chips, Timestamp, Times] ]}->
			ets:insert(?CONST_ETS_GAMBLE_PLAYER, #ets_gamble_player{user_id = UserId, chips = Chips, timestamp = Timestamp, times = Times});
		_ ->
			?ok
	end, 
	ok.

login_packet(Player, Packet) ->
	Game = gen_server:call(gamble_serv, {player_login, Player#player.user_id}),
	Packet1 = misc_packet:pack(?MSG_ID_GAMBLE_NEVEREND, ?MSG_FORMAT_GAMBLE_NEVEREND, [Game]),
	{Player, <<Packet/binary, Packet1/binary>>}.

%% @doc 登出
on_logout(Player) when is_record(Player, player)->
	UserId = Player#player.user_id,
	on_logout(UserId, ?false).
on_logout(UserId, Update)->
	case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
		[] ->
			?ok;
		[Data] ->
			Sql = <<"insert into `game_gamble_player` (`user_id`,`chips`, `times`,`timestamp`) values (",
					(misc:to_binary(Data#ets_gamble_player.user_id))/binary, ", ",
					(misc:to_binary(Data#ets_gamble_player.chips))/binary, ", ",
					(misc:to_binary(Data#ets_gamble_player.times))/binary, ", ",
					(misc:to_binary(Data#ets_gamble_player.timestamp))/binary, ")",
					" ON DUPLICATE KEY UPDATE `chips` = ",
					(misc:to_binary(Data#ets_gamble_player.chips))/binary, ", `times`='",
					(misc:to_binary(Data#ets_gamble_player.times))/binary, "', `timestamp`='",
					(misc:to_binary(Data#ets_gamble_player.timestamp))/binary, "';">>,
			if Update =:= ?false ->
				   gen_server:cast(gamble_serv, {player_logout, UserId}),
				   ets:delete(?CONST_ETS_GAMBLE_PLAYER, UserId);
			   ?true ->
				   ?ok
			end,
			_ = mysql_api:select(Sql)
	end,
	?ok.
%% @doc 玩家获得|失去筹码
%% @param Chip增减的筹码值，UserId,UserSid，Win2，0平局，1胜2败，RoomChip本局筹码,PlayerState玩家状态
change_chip(Chip, UserId, UserSid, Win2, RoomChip, PlayerState) when is_integer(Chip)->
	?MSG_DEBUG("change_chip, UserId:~p,UserSid:~p,Win2:~p,RoomChip:~p,PlayerState:~p", [UserId, UserSid, Win2, RoomChip, PlayerState]),
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid -> %用户在本节点
			if PlayerState =/= ?CONST_GAMBLE_PLAYER_LOST ->
				   case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
					   [] ->
						   Rtemp = #ets_gamble_player{chips = misc:max(Chip, 0), user_id = UserId},
						   ets:insert(?CONST_ETS_GAMBLE_PLAYER, Rtemp);
					   [Record]->
						   ets:update_element(?CONST_ETS_GAMBLE_PLAYER, Record#ets_gamble_player.user_id
											  , [{#ets_gamble_player.chips, Record#ets_gamble_player.chips + Chip}])
				   end;
			   ?true->
				   mail_outcome(UserId, UserSid, Win2, RoomChip),
				   mysql_api:update("game_gamble_player", [{chips, Chip, add}], [{"user_id", UserId}])
			end;
		?true -> % 用户在其他节点
			pre_cast(UserSid, ?MODULE, change_chip, [Chip, UserId, UserSid, Win2, RoomChip, PlayerState])
	end,
	on_logout(UserId, ?true),
	?ok.

change_chip(Chip, UserId, UserSid) when is_integer(Chip)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid -> %用户在本节点
			if Chip < 0 ->
				   check_chip(UserId, abs(Chip));
			   ?true ->
				   ?ok
			end,
			case player_api:check_online(UserId) of
				?true->
					case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
						[] ->
							Rtemp = #ets_gamble_player{chips = misc:max(Chip, 0), user_id = UserId},
							ets:insert(?CONST_ETS_GAMBLE_PLAYER, Rtemp);
						[Record]->
							ets:update_element(?CONST_ETS_GAMBLE_PLAYER, Record#ets_gamble_player.user_id
											   , [{#ets_gamble_player.chips, Record#ets_gamble_player.chips + Chip}])
					end;
				?false ->
					mysql_api:update("game_gamble_player", [{chips, Chip, add}], [{"user_id", UserId}])
			end;
		?true -> % 用户在其他节点
			pre_cast(UserSid, ?MODULE, change_chip, [Chip, UserId, UserSid])
	end,
	on_logout(UserId, ?true),
	?ok.

%% @doc 筹码变更记录
%% @param UserId, UserServId, {UserId, UserSID, UserPId, Chip1, UserID2, UserSID2, UserPId2, Chip2} = Data
log_chip(UserSid, Data)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid ->
			{UserId1, UserSID1, UserPId1, Chip1, UserID2, UserSID2, UserPId2, Chip2} = Data,
			admin_log_api:log_gamble(UserId1, UserSID1, UserPId1, Chip1, UserID2, UserSID2, UserPId2, Chip2);
		?true ->
			pre_cast(UserSid, admin_log_api, log_gamble, misc:to_list(Data))
	end,
	?ok.

%% @doc 房间信息
reply_rooms_info(Player) when is_record(Player, player)->
	reply_rooms_info(Player#player.user_id);
reply_rooms_info(UserIdList) when is_list(UserIdList)->
	Match = #ets_gamble_room{
							 chip = '_'
							 , history = '_'
							 , player1_card = '_'
							 , player1_cards = '_'
							 , player1_id = '_'
							 , player1_ready = '_'
							 , player1_score = '_'
							 , player1_sid = '_'
							 , player2_card = '_'
							 , player2_cards = '_'
							 , player2_id = '_'
							 , player2_ready = '_'
							 , player2_score = '_'
							 , player2_sid = '_'
							 , reg_name = '_'
							 , room_id = '_'
							 , room_state = '_'
							 , round = '_'
							 , state_time = '_'
							},
	Acc =
		case ets:select(?CONST_ETS_GAMBLE_ROOM, [{Match,[], ['$_']}], 5) of
			'$end_of_table' ->
				[];
			{Match2,Continuation} ->
				D1 = reply_rooms_info2(Match2, []),
				reply_rooms_info(Continuation, D1)
		end,
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_ROOMS_INFO, ?MSG_FORMAT_GAMBLE_REPLY_ROOMS_INFO, [Acc]),
	[ misc_packet:send(UserId, Packet) || UserId <- UserIdList ];
reply_rooms_info(UserId) when is_integer(UserId)->
	Match = #ets_gamble_room{
							 chip = '_'
							 , history = '_'
							 , player1_card = '_'
							 , player1_cards = '_'
							 , player1_id = '_'
							 , player1_ready = '_'
							 , player1_score = '_'
							 , player1_sid = '_'
							 , player2_card = '_'
							 , player2_cards = '_'
							 , player2_id = '_'
							 , player2_ready = '_'
							 , player2_score = '_'
							 , player2_sid = '_'
							 , reg_name = '_'
							 , room_id = '_'
							 , room_state = '_'
							 , round = '_'
							 , state_time = '_'
							},
	Acc =
		case ets:select(?CONST_ETS_GAMBLE_ROOM, [{Match,[], ['$_']}], 5) of
			'$end_of_table' ->
				[];
			{Match2,Continuation} ->
				D1 = reply_rooms_info2(Match2, []),
				reply_rooms_info(Continuation, D1)
		end,
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_ROOMS_INFO, ?MSG_FORMAT_GAMBLE_REPLY_ROOMS_INFO, [Acc]),
	misc_packet:send(UserId, Packet).

reply_rooms_info(Continutaion, Acc)->
	case ets:select(Continutaion) of
		'$end_of_table' ->
			Acc;
		{Match,Continuation2} ->
			D1 = reply_rooms_info2(Match, []),
			reply_rooms_info(Continuation2, D1++Acc)
	end.
reply_rooms_info2([#ets_gamble_room{room_state = State}= Room|T], Acc)
  when is_record(Room, ets_gamble_room) andalso State =/= ?CONST_GAMBLE_ROOM_STATE_PLAYING ->
	UserId = Room#ets_gamble_room.player1_id,
	UserSid = Room#ets_gamble_room.player1_sid,
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid andalso Room#ets_gamble_room.room_state =/= ?CONST_GAMBLE_ROOM_STATE_PLAYING-> %用户在本节点,未开始
			Info =
				case player_api:get_player_field(UserId, #player.info) of
					{?error, _} ->
						?ok; % !error
					{?ok, Ok} ->
						Ok
				end,
			RoomNum =
				case Room#ets_gamble_room.player2_id of
					A when A > 0 ->
						2;
					_ ->
						1
				end,
			Data = {RoomNum, UserId, Info#info.user_name, Info#info.pro
					, Info#info.sex, Room#ets_gamble_room.room_id, UserSid, Room#ets_gamble_room.chip},
			reply_rooms_info2(T, [Data|Acc]);
		?true ->
			reply_rooms_info2(T, Acc)
	end;
reply_rooms_info2([_H|T], Acc) ->
	reply_rooms_info2(T, Acc);
reply_rooms_info2([], Acc)->
	Acc.

%% @doc 创建房间
book_new_room(UserId, Sid, Chip, Change)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= Sid ->
			case check_chip(UserId, Chip) of
				?true ->
					gen_server:cast(gamble_serv
									, {book_new_room, {UserId,  Chip, Change}});
				?false ->
					?ok %元宝不足
			end;
		?true ->
			pre_cast(Sid, ?MODULE, book_new_room, [UserId, Sid, Chip, Change])
	end.

%% 跨服匹配
try_to_match_cross(UserId, {C10, C20, C50, C100}) ->
	?MSG_DEBUG("try_to_match_cross:~p",[{C10, C20, C50, C100}]),
	Chip = misc:max(misc:to_list({C10, C20, C50, C100})),
	case check_chip(UserId, Chip) of
		?true ->
			CenterNode = manage_api:get_man_node(),
			rpc:cast(CenterNode, center_gamble_serv, try_to_match_cross, [UserId, node(),  {C10, C20, C50, C100}]);
		_ ->
			?ok
	end.

%% 邀请
invite(UserId, UserName, RoomId, RoomSid) ->
	case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
		[Room] when Room#ets_gamble_room.room_state =:= ?CONST_GAMBLE_ROOM_STATE_Q1->
			Chip = Room#ets_gamble_room.chip,
			PacketBoard = message_api:msg_notice(?TIP_GAMBLE_INVITE, [{UserId, UserName}], [], [{100,[misc:to_list(Chip)]}, {100,misc:to_list(RoomId)}, {100,misc:to_list(RoomSid)}]),
			gateway_worker_sup:broadcast_world_2(PacketBoard);
		_ ->
			?ok
	end,
	?ok.

join_new_room(UserId, RoomId, RoomNode) ->
	{?ok, Info} = player_api:get_player_field(UserId, #player.info),
	rpc:cast(RoomNode, ?MODULE, join_cross_room, [UserId, getLocalSid(), RoomId, Info#info.user_name, Info#info.pro, Info#info.sex]).

join_cross_room(UserId, UserSid, RoomId, Name, Pro, Sex)->
	case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
		[] ->
			pack_join_room(UserId, UserSid, ?NOROOM);
		[Room] ->
			Reg = Room#ets_gamble_room.reg_name,
			gen_server:cast(gamble_serv, {join_room, Reg, UserId, UserSid, Name, Pro, Sex})
	end.

%% @doc 请求加入房间
join_new_room(UserId, RoomId, RoomSid, Name, Pro, Sex)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] ->
					PacketNo = message_api:msg_notice(?TIP_GAMBLE_NO_ROOM),
					misc_packet:send(UserId, PacketNo),
					pack_join_room(UserId, LocalSid, ?NOROOM);
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					Chip = Room#ets_gamble_room.chip,
					case check_chip(UserId, Chip) of
						?true ->
							gen_server:cast(gamble_serv, {join_room,Reg,  UserId, LocalSid, Name, Pro, Sex});
						?false ->
							pack_join_room(UserId, LocalSid, ?NOROOM)
					end
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, join_new_room, [UserId, RoomId, RoomSid, Name, Pro, Sex])
	end.

%% @doc 请求离开房间
request_leave(UserId, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {leave_room, UserId})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, request_leave, [UserId, RoomId, RoomSid])
	end.

%% @doc 检查玩家下线离开房间
request_leave2(UserId, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[Room] when Room#ets_gamble_room.room_state =/= ?CONST_GAMBLE_ROOM_STATE_PLAYING ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {leave_room, UserId});
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {player_lost, UserId});
				_ -> % 不需要退出
					?ok
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, request_leave2, [UserId, RoomId, RoomSid])
	end.

%% @doc 重复登入顶掉之前的玩家并退出房间
request_leave3(UserId, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[Room] when Room#ets_gamble_room.room_state =/= ?CONST_GAMBLE_ROOM_STATE_PLAYING ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {leave_room, UserId});
				_ -> % 不需要退出
					?ok
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, request_leave2, [UserId, RoomId, RoomSid])
	end.

%% @doc 请求准备|取消
request_ready(UserId, RoomId, RoomSid, Ready) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					?MSG_DEBUG("request_ready user : ~p", [UserId]),
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(gamble_serv, {player_ready,Reg, UserId, Ready})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, request_ready, [UserId, RoomId, RoomSid, Ready])
	end.

%% @doc 给玩家发消息
send_to_user(UserId, Sid, Packet)->
	case getLocalSid() of
		Sid->
			misc_packet:send(UserId, Packet);
		_ ->
			pre_cast(Sid, misc_packet, send, [UserId, Packet])
	end.

%% @doc 检查筹码是否够，不够用元宝代替
check_chip(UserId, Chip) ->
	case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
		[] ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, Chip, ?CONST_COST_GAMBLE_EXCHANGE) of
				{?error, _ } ->
					?true;
				_ ->
					ets:insert(?CONST_ETS_GAMBLE_PLAYER, #ets_gamble_player{user_id=UserId, chips=Chip}),
					on_logout(UserId, ?true),
					?false
			end ;
		[Data] ->
			case Data#ets_gamble_player.chips of
				Chips when Chips >= Chip ->
					?true;
				Chips ->
					Diff = Chip - Chips,
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, Diff, ?CONST_COST_GAMBLE_EXCHANGE) of
						?ok ->
							ets:insert(?CONST_ETS_GAMBLE_PLAYER, Data#ets_gamble_player{user_id=UserId, chips=Chip}),
							on_logout(UserId, ?true),
							?true;
						_ ->
							?false
					end
			end
	end.

%% @doc 玩家出牌提示
play_card1(UserId, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					if 
						Room#ets_gamble_room.player1_id =:= UserId ->
							pack_inform_play(Room#ets_gamble_room.player2_id, Room#ets_gamble_room.player2_sid);
						?true ->
							pack_inform_play(Room#ets_gamble_room.player1_id, Room#ets_gamble_room.player1_sid)
					end
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, play_card1, [UserId, RoomId, RoomSid])
	end.
%% @doc 玩家出牌
play_card2(UserId, RoomId, RoomSid, Card)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(gamble_serv, {player_card, Reg, UserId, Card})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, play_card2, [UserId, RoomId, RoomSid, Card])
	end.

%% @doc 玩家放弃
player_give_up(UserId, RoomId, RoomSid)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {player_give_up, UserId})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, player_give_up, [UserId, RoomId, RoomSid])
	end.

%% @doc 玩家请求历史
player_want_history(UserId, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {player_want_history, UserId})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, player_want_history, [UserId, RoomId, RoomSid])
	end.

%% @doc 记录开局的玩家，记录在玩家本地的gamble_serv中，方便掉线捞回 State::true游戏中|false游戏结束
player_onplay(UserId, UserSid, RoomId, RoomSid, State)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid ->
			gen_server:cast(gamble_serv, {player_onplay, UserId, RoomId, RoomSid, State});
		?true->
			pre_cast(UserSid, ?MODULE, player_onplay, [UserId, UserSid, RoomId, RoomSid, State])
	end.

%% @doc 查看筹码
request_chip(Player)->
	UserId = Player#player.user_id,
	request_chip2(UserId).

request_chip2(UserId)->
	Chip=
		case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
			[] ->
				ets:insert(?CONST_ETS_GAMBLE_PLAYER, #ets_gamble_player{user_id=UserId, chips=0}),
				0;
			[Data] ->
				Data#ets_gamble_player.chips
		end,
	pack_reply_chip(UserId, Chip).

%% @doc 筹码兑换元宝
exchange_chip(Player, Chips)->
	UserId = Player#player.user_id,
	case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
		[] ->
			ets:insert(?CONST_ETS_GAMBLE_PLAYER, #ets_gamble_player{user_id=UserId, chips=0}),
			pack_reply_chip(UserId, 0);
		[Data] ->
			OwnChips = Data#ets_gamble_player.chips,
			Exchange = misc:min(OwnChips, Chips),
			ets:insert(?CONST_ETS_GAMBLE_PLAYER, Data#ets_gamble_player{chips=OwnChips - Exchange}),
			player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Exchange, ?CONST_COST_GAMBLE_EXCHANGE_CASH),
			pack_reply_chip(UserId, OwnChips - Exchange)
	end.

%% @doc 更改房间筹码
change_room_chip(UserId, RoomId, RoomSid, Chip) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {new_chip, Chip})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, change_room_chip, [UserId, RoomId, RoomSid, Chip])
	end.

%% @doc 再来一局
play_again(UserId, Again, RoomId, RoomSid) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {play_again, UserId, Again})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, play_again, [UserId, Again, RoomId, RoomSid])
	end.

%% @doc 更新房间信息
%% @param UserId, UserSid, RoomId, RoomSid, IsIn::boolean() 加入或者退出
change_room_info(UserId, UserSid, RoomId, RoomSid, IsIn) when is_boolean(IsIn)->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= UserSid ->
			gen_server:cast(gamble_serv, {room_info_changed, UserId, RoomId, RoomSid, IsIn});
		?true->
			pre_cast(UserSid, ?MODULE, change_room_info, [UserId, UserSid, RoomId, RoomSid, IsIn])
	end,
	try
		if LocalSid =:= RoomSid ->
			   case IsIn of
				   ?true ->
					   sub_mini_room(RoomId);
				   ?false ->
					   [Room] =  ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId),
					   add_mini_room(RoomId, Room#ets_gamble_room.chip)
			   end;
		   ?true ->
			   ?ok
		end
	catch
		error:{badmatch,[]} ->
			?ok;
		E:W ->
			?MSG_DEBUG("Error:~p,Why:~p~n~p",[E,W,erlang:get_stacktrace()])
	end.

%% @doc 兑换筹码
exchange4chip(UserId, Chip)->
	?MSG_DEBUG("c~p", [Chip]),
	Chips1 =
		case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
			[] ->
				% !error
				0;
			[Record] ->
				Record#ets_gamble_player.chips
		end,
	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH_ONLY, Chip, ?CONST_COST_GAMBLE_EXCHANGE) of
		{?error, _} ->
			pack_reply_chip(UserId, Chips1),
			?true;
		_ ->
			ets:insert(?CONST_ETS_GAMBLE_PLAYER, #ets_gamble_player{user_id=UserId, chips=Chips1+Chip}),
			pack_reply_chip(UserId, Chips1+Chip),
			?false
	end.

%% @doc 玩家返回游戏
player_come_back(UserId, Yes) ->
	gen_server:cast(gamble_serv, {player_back, UserId, Yes}).

player_back(UserId, RoomId, RoomSid, Yes) ->
	LocalSid = getLocalSid(),
	if
		LocalSid =:= RoomSid ->
			case ets:lookup(?CONST_ETS_GAMBLE_ROOM, RoomId) of
				[] -> %房间不存在
					?ok;
				[Room] ->
					Reg = Room#ets_gamble_room.reg_name,
					gen_server:cast(Reg, {player_back, UserId, Yes})
			end;
		?true->
			pre_cast(RoomSid, ?MODULE, player_back, [UserId, RoomId, RoomSid, Yes])
	end.

%% @doc 断线重连房间信息
player_need_room_back(UserId, UserSid, UserId2, UserSid2, Roomid, RoomSid, Chip) ->
	if
		UserSid =:= UserSid2 -> %对方玩家在本地
			{?ok, Info} = player_api:get_player_field(UserId2, #player.info),
			?MSG_DEBUG("player_need_room_back~n~p", [{UserSid2, Info#info.user_name, Info#info.pro, Info#info.sex, RoomSid, Roomid, Chip}]),
			Packet = misc_packet:pack(?MSG_ID_GAMBLE_NEED_ROOM_BACK, ?MSG_FORMAT_GAMBLE_NEED_ROOM_BACK
									  , [UserId2, Info#info.user_name, Info#info.pro, Info#info.sex, RoomSid, Roomid, Chip, UserSid]),
			send_to_user(UserId, UserSid, Packet);
		?true->
			pre_cast(UserSid2, ?MODULE, player_need_room_back2, [UserId, UserSid, UserId2, UserSid2, Roomid, RoomSid, Chip])
	end.
player_need_room_back2(UserId, UserSid, UserId2, UserSid2, Roomid, RoomSid, Chip) ->
	{?ok, Info} = player_api:get_player_field(UserId2, #player.info),
	?MSG_DEBUG("player_need_room_back~n~p", [{UserSid2, Info#info.user_name, Info#info.pro, Info#info.sex, RoomSid, Roomid, Chip}]),
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_NEED_ROOM_BACK, ?MSG_FORMAT_GAMBLE_NEED_ROOM_BACK
							  , [UserId2, Info#info.user_name, Info#info.pro, Info#info.sex, RoomSid, Roomid, Chip, UserSid]),
	send_to_user(UserId, UserSid, Packet).
%% ================================================================================
%% @doc pack and send
%% ================================================================================
pack_book_room(UserId, Result)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_BOOK, ?MSG_FORMAT_GAMBLE_REPLY_BOOK, Result),
	misc_packet:send(UserId, Packet).

pack_join_room(UserId,Sid,Result)->
	?MSG_DEBUG("pack_join_room:~n~p~n", [Result]),
	%% 	Packet1 =
	%% 		if Result =:= ?NOROOM ->
	%% 			   message_api:msg_notice(?TIP_GAMBLE_JOIN_FAIL);
	%% 		   ?true ->
	%% 			   <<>>
	%% 		end,
	Packet2 = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_JOIN, ?MSG_FORMAT_GAMBLE_REPLY_JOIN, Result),
	send_to_user(UserId, Sid, << Packet2/binary>>).

pack_inform_join(UserId, Data)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_INFORM_JOIN, ?MSG_FORMAT_GAMBLE_INFORM_JOIN, Data),
	misc_packet:send(UserId, Packet).

pack_inform_leave(UserId, Sid, Data) ->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_INFORM_LEAVE, ?MSG_FORMAT_GAMBLE_INFORM_LEAVE, Data), 
	send_to_user(UserId, Sid, Packet).

pack_inform_ready(UserId, Sid, Data)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_INFORM_READY, ?MSG_FORMAT_GAMBLE_INFORM_READY, Data),
	send_to_user(UserId, Sid, Packet).

pack_game_start(UserId, Sid)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_GAME_START, ?MSG_FORMAT_GAMBLE_GAME_START, [0]),
	send_to_user(UserId, Sid, Packet).

pack_inform_play(UserId, Sid)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_INFORM_PLAY, ?MSG_FORMAT_GAMBLE_INFORM_PLAY, [0]),
	send_to_user(UserId, Sid, Packet).

pack_reply_result(UserId, Sid, Data)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_RESULT, ?MSG_FORMAT_GAMBLE_REPLY_RESULT, Data),
	send_to_user(UserId, Sid, Packet).

pack_gamble_result(UserId, Sid, Chip, Win)->
	LocalSid = getLocalSid(),
	if 
		LocalSid =:= Sid ->
			Chips1 =
				case ets:lookup(?CONST_ETS_GAMBLE_PLAYER, UserId) of
					[] ->
						% !error
						0;
					[Record] ->
						Record#ets_gamble_player.chips 
				end,
			{?ok, Money} = player_money_api:read_money(UserId),
			Packet = misc_packet:pack(?MSG_ID_GAMBLE_GAMBLE_RESULT, ?MSG_FORMAT_GAMBLE_GAMBLE_RESULT, [Chip, Chips1, Money#money.cash, Win]),
			send_to_user(UserId, Sid, Packet);
		?true ->
			pre_cast(Sid, ?MODULE, pack_gamble_result, [UserId, Sid, Chip, Win])
	end.

%% @doc 邮件通知结果
%% @param UserId, Sid, Win::integer(), 1,胜利;0,平局;2,失败
mail_outcome(UserId, Sid, Win, OutCome) when is_integer(OutCome)->
	LocalSid = getLocalSid(),
	if 
		LocalSid =:= Sid ->
			if Win =:= 1 ->
				   mail_api:send_system_mail_to_one3(misc:to_binary(player_api:get_name(UserId)),	 <<>>, <<>>, 3152, [{[{misc:to_list(OutCome)}]}], [], 0, 0, 0, 0, 0);
			   Win =:= 2 ->
				   mail_api:send_system_mail_to_one3(misc:to_binary(player_api:get_name(UserId)),	 <<>>, <<>>, 3153, [{[{misc:to_list(OutCome)}]}], [], 0, 0, 0, 0, 0);
			   ?true ->
				   mail_api:send_system_mail_to_one3(misc:to_binary(player_api:get_name(UserId)),	 <<>>, <<>>, 3154, [], [], 0, 0, 0, 0, 0)
			end;
		?true ->
			pre_cast(Sid, ?MODULE, mail_outcome, [UserId, Sid, Win, OutCome])
	end.

pack_inform_history(UserId, Sid, Data)->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_INFORM_HISTORY, ?MSG_FORMAT_GAMBLE_INFORM_HISTORY, Data),
	send_to_user(UserId, Sid, Packet).

pack_reply_chip(UserId, Chip) ->
	?MSG_DEBUG("chip:~p", [Chip]),
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_REPLY_CHIP, ?MSG_FORMAT_GAMBLE_REPLY_CHIP, [Chip]),
	misc_packet:send(UserId, Packet).

pack_tip_full_player(UserId, Sid)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_FULL_PLAYER),
	send_to_user(UserId, Sid, Packet).

pack_tip_kick_out(UserId, Sid)->
	Packet1 = misc_packet:pack(?MSG_ID_GAMBLE_BEKICKED, ?MSG_FORMAT_GAMBLE_BEKICKED, []),
	Packet2 = message_api:msg_notice(?TIP_GAMBLE_KICK_OUT),
	send_to_user(UserId, Sid, <<Packet1/binary, Packet2/binary>>).

pack_tip_leave(UserId, Sid)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_LEAVE),
	send_to_user(UserId, Sid, Packet).

pack_tip_tie(UserId, Sid)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_TIE),
	send_to_user(UserId, Sid, Packet).

pack_tip_excape(UserId, Sid)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_ESCAPE),
	send_to_user(UserId, Sid, Packet).

pack_tip_exchange_bat(UserId, Sid, Cash)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_EXCHANGE_BET, [], [], [{?TIP_SYS_COMM, misc:to_list(Cash)}]),
	send_to_user(UserId, Sid, Packet).

pack_tip_exchange_cash(UserId, Sid, Bet)->
	Packet = message_api:msg_notice(?TIP_GAMBLE_EXCHANGE_CASH, [], [], [{?TIP_SYS_COMM, misc:to_list(Bet)}]),
	send_to_user(UserId, Sid, Packet).

pick_tip_no_cross_room(UserId) ->
	Packet = message_api:msg_notice(?TIP_GAMBLE_CROSS_FAIL),
	misc_packet:send(UserId, Packet).

pack_inform_user_lost(UserId, Sid) ->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_LOST_CONN, ?MSG_FORMAT_GAMBLE_LOST_CONN, [0]),
	_ = send_to_user(UserId, Sid, Packet).

pack_inform_user_back(UserId, Sid) ->
	Packet = misc_packet:pack(?MSG_ID_GAMBLE_COME_BACK, ?MSG_FORMAT_GAMBLE_COME_BACK, [0]),
	_ = send_to_user(UserId, Sid, Packet).


%% @doc 获取localsid*1000 + localplatform
getLocalSid() ->
	config:read_deep([server, base, sid]) bsl 10 + config:read_deep([server, base, platform_id]).

%% @doc 获取node
get_node(Sid)->
	Sid2 = Sid bsr 10,
	case center_api:get_serv_info(Sid2) of
		{Node, ?CONST_CENTER_STATE_NORMAL} ->
			Node;
		_ ->
			node()
	end.

%% @doc 聊天框彩蛋
make_trick(State, [PlayerNo, Round])->
	{UserId1, UserSid1, UserId2, UserSid2} =
		case PlayerNo of
			1 ->
				{State#ets_gamble_room.player1_id, State#ets_gamble_room.player1_sid, State#ets_gamble_room.player2_id,State#ets_gamble_room.player2_sid};
			_ ->
				{State#ets_gamble_room.player2_id, State#ets_gamble_room.player2_sid, State#ets_gamble_room.player1_id,State#ets_gamble_room.player1_sid}
		end,
	if 
		Round =:= 1 ->
			msg_notice(?TIP_GAMBLE_TIP_WIN1, UserId1, UserSid1, UserId1, UserSid1, 0, 0),
			msg_notice(?TIP_GAMBLE_LOST_1, UserId2, UserSid2, 0, 0, UserId2, UserSid2);
		Round =:= 3 ->
			msg_notice(?TIP_GAMBLE_TIP_WIN3, UserId1, UserSid1, UserId1, UserSid1, UserId2, UserSid2),
			msg_notice(?TIP_GAMBLE_LOST_3, UserId2, UserSid2, UserId1, UserSid1, UserId2, UserSid2);
		Round =:= 5 ->
			msg_notice(?TIP_GAMBLE_TIP_WIN5, UserId1, UserSid1, UserId1, UserSid1, UserId2, UserSid2),
			msg_notice(?TIP_GAMBLE_LOST_5, UserId2, UserSid2, UserId1, UserSid1, UserId2, UserSid2);
		Round =:= 7 ->
			msg_notice(?TIP_GAMBLE_TIP_WIN7, UserId1, UserSid1, UserId1, UserSid1, UserId2, UserSid2),
			msg_notice(?TIP_GAMBLE_LOST_7, UserId2, UserSid2, UserId1, UserSid1, UserId2, UserSid2);
		Round >= 10 ->
			msg_notice(?TIP_GAMBLE_TIP_WIN10, UserId1, UserSid1, UserId1, UserSid1, UserId2, UserSid2),
			msg_notice(?TIP_GAMBLE_LOST_10, UserId2, UserSid2, UserId1, UserSid1, UserId2, UserSid2);
		?true ->
			?ok
	end.

msg_notice(MsgID, UserId, UserSid, UserId1, UserSid1, UserId2, UserSid2)->
	LocalSid = getLocalSid(),
	if 
		LocalSid =:= UserSid ->
			Packet = message_api:msg_notice(MsgID, [], [], [{100, player_api:get_name(UserId)}]),
			if
				UserId1 > 0 ->
					send_to_user(UserId1, UserSid1, Packet);
				?true->
					?ok
			end,
			if
				UserId2 > 0 ->
					send_to_user(UserId2, UserSid2, Packet);
				?true->
					?ok
			end;
		?true ->
			pre_cast(UserSid, ?MODULE, msg_notice, [MsgID, UserId, UserSid, UserId1, UserSid1, UserId2, UserSid2])
	end.

%% ====================================================================
%% Internal functions
%% ====================================================================
pre_cast(Sid, M, F, A)->
	manage_api:cast(Sid rem 1024, Sid bsr 10, M, F, A).