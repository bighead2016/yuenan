%% author:	jiangxiaoyu
%% create:	2014-01-21
%% desc:	trans turn record in the database
%%

-module(trans_turn).


-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

-export([trans_turn/0]).

trans_turn() ->
	misc_sys:init(),
	mysql_api:start(),
	TotalCount = 
        case mysql_api:select(<<"select count(`user_id`) from `game_player`;">>) of
            {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                TotalCountT;
            _ ->
                0
        end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`, `new_serv` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, NewServE], OldCount) ->
                                try
                                    NewServD = mysql_api:decode(NewServE),
                                    {turn, X1, X2, X3} = NewServD#new_serv.turn,
									NewServD2 = NewServD#new_serv{turn = {turn, X1, X2, X3, 0}},
                                    NewServE2 = mysql_api:encode(NewServD2), 
                                    mysql_api:update(<<"update `game_player` set `new_serv` = ", NewServE2/binary,
                                                                     " where `user_id`=", (misc:to_binary(UserId))/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_player` count=0")
    end.
