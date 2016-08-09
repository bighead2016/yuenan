
-module(trans_style).

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
-export([trans_1231/0]).

%%
%% API Functions
%%

%% 转坐骑id
trans_1231() ->
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
            case mysql_api:select(<<"select `user_id`, `style` from `game_player`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, StyleDataE], OldCount) ->
                                try
                                    StyleDataD = mysql_api:decode(StyleDataE),
                                    StyleDataD2 = change_style(StyleDataD),
                                    StyleData2E = mysql_api:encode(StyleDataD2), 
                                    mysql_api:update(<<"update `game_player` set `style` = ", StyleData2E/binary,
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
%%     ok.

%%
%% Local Functions
%%
%% 新旧id对照
%% 旧                               新
%% 白鹤2011103001          2011106013
%% 紫骍2011105002          2011107012
%% 的卢2011106001          2011106012
%% 雪狮2011106003          2011106011
%% 绝影2011107001          2011105004
%% 猎豹2011107002          2011107011
change_id(2011103001) -> 2011106013;
change_id(2011105002) -> 2011107012;
change_id(2011106001) -> 2011106012;
change_id(2011106003) -> 2011106011;
change_id(2011107001) -> 2011105004;
change_id(2011107002) -> 2011107011;
change_id(Id)         -> Id.

change_style(#style_data{bag = Bag, cur_skin = L2} = Data) ->
    NewBag = 
        case lists:keytake(?CONST_GOODS_EQUIP_HORSE, 1, Bag) of
            {value, {_, StyleList}, Bag2} ->
                StyleList2 = change_sytle_2(StyleList, []),
                [{?CONST_GOODS_EQUIP_HORSE, StyleList2}|Bag2];
            _ ->
                Bag
        end,
    NewL2 = 
        case lists:keytake(?CONST_GOODS_EQUIP_HORSE, 1, L2) of
            {value, {_, LL}, L2_2} ->
                LL2 = change_id(LL),
                [{?CONST_GOODS_EQUIP_HORSE, LL2}|L2_2];
            _ ->
                L2
        end,
    Data#style_data{bag = NewBag, cur_skin = NewL2}.
              
change_sytle_2([{Style, Time}|Tail], OldList) ->
    Style2 = change_id(Style),
    change_sytle_2(Tail, [{Style2, Time}|OldList]);
change_sytle_2([], OldList) ->
    OldList.

