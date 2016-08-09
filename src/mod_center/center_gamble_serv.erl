%%% 
-module(center_gamble_serv).
-behaviour(gen_server).
%% --------------------------------------------------------------------
%% Include files
%% --------------------------------------------------------------------
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.data.hrl").
%% --------------------------------------------------------------------
%% External exports
-export([start_link/2]).
-export([try_to_match_cross/3]).
-export([add_room/1, sub_room/1]).
-compile(export_all).
%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {room_list = []}).

%% ====================================================================
%% External functions
%% ====================================================================
start_link(_ServName, _Cores) -> 
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

add_room(MiniRoom) ->
    gen_server:cast(?MODULE, {add_room, MiniRoom}).

sub_room(RoomKey) ->
    gen_server:cast(?MODULE, {sub_room, RoomKey}).

try_to_match_cross(UserId, From,  {C10, C20, C50, C100}) ->
    gen_server:cast(?MODULE, {From, match, UserId, [C10, C20, C50, C100]}).
%% ====================================================================
%% Server functions
%% ====================================================================
init([]) ->
	{?ok, #state{}}.

handle_call(Request, _From, State) ->
      ?MSG_ERROR("Error:~p ", [Request]),
      {?noreply, State}.

handle_cast({add_room, MiniRoom}, #state{room_list = OldRoomList} = State) ->
	?MSG_DEBUG("add_room:~p", [{add_room, MiniRoom}]),
    {noreply, State#state{room_list = [MiniRoom|OldRoomList]}};
handle_cast({sub_room, RoomKey}, #state{room_list = OldRoomList} = State) ->
	NewRoomList = lists:keydelete(RoomKey, #ets_gamble_room_mini.key, OldRoomList),
	{noreply, State#state{room_list = NewRoomList}};
handle_cast({From, match, UserId, Chips}, #state{room_list = OldRoomList} = State) ->
	[RoomChoosed, NewRoomList] = pick_room(OldRoomList, Chips),
	?MSG_DEBUG("rooms :~p", [OldRoomList]),
	case RoomChoosed of
		noroom ->
			rpc:cast(From, gamble_api, pick_tip_no_cross_room, [UserId]);
		RoomChoosed ->
			{RoomId, RoomNode} = RoomChoosed#ets_gamble_room_mini.key,
			rpc:cast(From, gamble_api, join_new_room, [UserId, RoomId, RoomNode])
	end,
	{noreply, State#state{room_list = NewRoomList}};
handle_cast(Msg, State) ->
      ?MSG_ERROR("Error:~p ", [Msg]),
      {?noreply, State}.

handle_info(Info, State) ->
      ?MSG_ERROR("Error:~p ", [Info]),
      {?noreply, State}.

terminate(Reason, State) ->
    case Reason of
        shutdown -> ?MSG_ERROR("STOP Reason:~p", [Reason]), ?ok;
        _ -> ?MSG_ERROR("STOP Reason:~p   State:~p", [Reason, State]), ?ok
    end.

code_change(_OldVsn, State, _Extra) ->
    {?ok, State}.

pick_room(OldRoomList, [Chip|T]) ->
	case lists:keytake(Chip, #ets_gamble_room_mini.chip, OldRoomList) of
        false ->
            pick_room(OldRoomList, T);
        {value, RoomChoosed, NewRoomList} ->
            [RoomChoosed, NewRoomList]
    end;
pick_room(OldRoomList, []) ->
	[noroom, OldRoomList].
