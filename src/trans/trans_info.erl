%% Author: yskj
%% Created: 2013-11-6
%% Description: TODO: Add description to trans_horse
-module(trans_info).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([trans_1111/0]).

%%
%% API Functions
%%

trans_1111() ->
    misc_sys:init(),
    mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_user`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`, `info` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, InfoE], OldCount) ->
                                try
                                    InfoD = mysql_api:decode(InfoE),
                                    InfoD2 = erlang:tuple_to_list(InfoD),
                                    InfoD3 = erlang:list_to_tuple(InfoD2++[0]),
                                    InfoE2 = mysql_api:encode(InfoD3), 
                                    mysql_api:update(<<"update `game_player` set `info` = ", InfoE2/binary,
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
    end,
    erlang:halt().

%%
%% Local Functions
%%

