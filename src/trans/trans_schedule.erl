%% author:	xjg
%% create:	2013-12-30
%% desc:	trans_schedule record in the database
%%

-module(trans_schedule).


-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

-export([trans_schedule/0]).

trans_schedule() ->
	misc_sys:init(),
	mysql_api:start(),
	TotalCount = 
		case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
			{?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
				TotalCountT;
			_ ->
				0
		end,
	case TotalCount > 0 of
		?true ->
			OkCount = 
				case mysql_api:select(<<"select `user_id`, `schedule` from `game_player`;">>) of
					{?ok, [?undefined]} -> 
						?MSG_SYS("undefined<-------------------", []),
						?ok;
					{?ok, DataList} ->
						TupleSize = erlang:tuple_size(#schedule{}),
						Fun = fun([UserId, BinRd], OldCount) ->
									  try
										  Rd = mysql_api:decode(BinRd),
										  NewRd = 
											  case erlang:tuple_size(Rd) =:= TupleSize - 1 of
												  ?true -> erlang:append_element(Rd, 0); 
												  ?false ->
													  List = erlang:tuple_to_list(Rd),
													  List2 = lists:sublist(List, TupleSize),
													  Len = erlang:length(List2),
													  Ext = TupleSize - Len,
													  case Ext > 0 of
														  ?true ->
															  erlang:list_to_tuple(List2 ++ lists:duplicate(Ext, 0));
														  ?false ->
															  erlang:list_to_tuple(List2)
													  end
											  end,
										  NewBinRd = mysql_api:encode(NewRd), 
										  mysql_api:update(<<"update `game_player` set `schedule` = ", NewBinRd/binary,
															 " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
										  OldCount2 = OldCount + 1,
										  ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
										  OldCount2
									  catch 
										  X:Y -> 
											  ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
											  OldCount
									  end
							  end,
						lists:foldl(Fun, 0, DataList);
					X ->
						?MSG_SYS("~p<-------------------", [X]),
						0
				end,
			case (TotalCount - OkCount) =:= 0 of
				?true ->
					?MSG_SYS("ok");
				?false ->
					?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
			end;
		?false ->
			?MSG_SYS("table `game_player` count=0")
	end,
	erlang:halt().
