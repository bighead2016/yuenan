%% author:	xjg
%% create:	2014-1-10
%% desc:	trans party_doll record in the database
%%

-module(trans_party_doll).


-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

-export([trans_party_doll/0]).

trans_party_doll() ->
	misc_sys:init(),
	mysql_api:start(),
	TotalCount = 
		case mysql_api:select(<<"select count(`user_id`) from `game_party_doll`;">>) of
			{?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
				TotalCountT;
			_ ->
				0
		end,
	case TotalCount > 0 of
		?true ->
			OkCount = 
				case mysql_api:select(<<"select `user_id`, `record` from `game_party_doll`;">>) of
					{?ok, [?undefined]} -> 
						?MSG_SYS("undefined<-------------------", []),
						?ok;
					{?ok, DataList} ->
						TupleSize = erlang:tuple_size(#party_doll{}),
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
										  mysql_api:update(<<"update `game_party_doll` set `record` = ", NewBinRd/binary,
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
					?MSG_SYS("table `game_party_doll` count not eq ~p/~p", [OkCount, TotalCount])
			end;
		?false ->
			?MSG_SYS("table `game_party_doll` count=0")
	end.
