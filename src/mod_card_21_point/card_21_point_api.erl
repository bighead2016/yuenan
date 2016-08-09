-module(card_21_point_api).
-author(liuzhe).
%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-define(CONST_CARD21_SET_COUNT, 8).
-define(CONST_CARD21_CHIP_RANGE, [5, 10, 50, 100]).
-define(CONST_CARD21_SPEC_FLAG, false).
%%
%% Exported Functions
%%
-export([login_packet/2, quit/1]).
-export([hit/1, stand/1, init_game/2]).
-export([request_chip/1, buy_chip/2, sell_chip/2]).

-compile(export_all).
%%
%% API Functions
%%

quit(UserId) ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{chip_now = Now, chip_total = Total, state = State}] ->
            case State of
                ?CONST_GAMBLE_21CARD_STATE_GOING ->
                    ets:update_element(?CONST_ETS_CARD21, UserId, 
                                       [{#ets_card21.state, ?CONST_GAMBLE_21CARD_STATE_LOSE},
                                        {#ets_card21.chip_now, 0},
                                        {#ets_card21.chip_total = Total - Now}]);
                _ ->
                    ok
            end
    end.
            

%% 初始化
login_packet(Player, AccPacket) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            case mysql_api:select([chip_total], game_card_chip, [{user_id, UserId}]) of
                {ok, [[Total]]} ->
                    ets:insert(?CONST_ETS_CARD21, #ets_card21{user_id = UserId, chip_total = Total});
                _ ->
                    ets:insert(?CONST_ETS_CARD21, #ets_card21{user_id = UserId}),
                    mysql_api:insert(game_card_chip, [user_id], [UserId])
            end;
        _ ->
            ok
    end,
    {Player, AccPacket}.

%% 买筹码
sell_chip(UserId, Count) when Count > 0->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{chip_total = Total}] ->
            case Total >= Count of
                false ->
                    ok;
                _ ->
                    Rest = Total - Count ,
                    case mysql_api:update(game_card_chip, [{chip_total, Rest}], [{user_id, UserId}]) of
                        {ok, _} ->
                            player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Count, ?CONST_COST_CARD21_CHIP),
                            ets:update_element(?CONST_ETS_CARD21, UserId, {#ets_card21.chip_total, Rest}),
                            request_chip(UserId);
                        Err ->
                            ?MSG_ERROR("update db error : ~p", [Err])
                    end
            end
    end.

%% 卖筹码
buy_chip(UserId, Count) when Count > 0 ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{chip_total = TotalOld}] ->
            case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Count, ?CONST_COST_CARD21_CHIP) of
                false ->
                    ok;
                _ ->
                    mysql_api:update(game_card_chip, [{chip_total, TotalOld + Count}], [{user_id, UserId}]),
                    ets:update_element(?CONST_ETS_CARD21, UserId, {#ets_card21.chip_total, TotalOld + Count}),
                    request_chip(UserId)
            end
    end.

%% 请求筹码信息
request_chip(UserId)->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [Data] ->
            Chip = Data#ets_card21.chip_total,
            Packet = msg_sc_total_chip(Chip),
            misc_packet:send(UserId, Packet),
            case Data#ets_card21.state of
                ?CONST_GAMBLE_21CARD_STATE_GOING ->
                    send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_GOING);
                _ ->
                    ok
            end
    end.

%% 初始化一局
init_game(UserId, Chip)  when Chip > 0 ->
    case lists:member(Chip, ?CONST_CARD21_CHIP_RANGE) of
        true ->
            case ets:lookup(?CONST_ETS_CARD21, UserId) of
                [] ->
                    ok;
                [#ets_card21{chip_total = Total, state = State}] ->
                    case Total >= Chip of
                        true ->
                            case State == ?CONST_GAMBLE_21CARD_STATE_GOING of
                                true ->
                                    send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_GOING);
                                _ ->
                                    CardList = generate_game(),
                                    {RestCardList1, SCardList, SScore} = init_2_card(CardList),
                                    {RestCardList2, CCardList, CScore} = 
                                        case ?CONST_CARD21_SPEC_FLAG of
                                            true ->
                                                init_2_card_spec(RestCardList1);
                                            _ ->
                                                init_2_card(CardList)
                                        end,
                                    io:format("self  "),
                                    cpint(SCardList),
                                    io:format("computer "),
                                    cpint(CCardList),
                                    ets:update_element(?CONST_ETS_CARD21, UserId,
                                                        [{#ets_card21.rest_card_list, RestCardList2},
                                                         {#ets_card21.computer_cardId_list, CCardList},
                                                         {#ets_card21.self_cardId_list, SCardList},
                                                         {#ets_card21.chip_now, Chip},
                                                         {#ets_card21.state, ?CONST_GAMBLE_21CARD_STATE_GOING}]),
                                    if 
                                        SScore == 21 andalso CScore == 21 ->
                                            draw(UserId),
                                            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_DRAW);
                                        SScore == 21 ->
                                            win(UserId),
                                            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_WIN);
                                        CScore == 21 ->
                                            lose(UserId),
                                            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_LOSE);
                                        true ->
                                            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_GOING)
                                    end
                            end;
                        _ ->
                            ok
                    end
            end;
        _ ->
            ok
    end.
    
%% 停牌
stand(UserId) ->
    [#ets_card21{rest_card_list = RList, self_cardId_list = SList, computer_cardId_list = CList}] = ets:lookup(?CONST_ETS_CARD21, UserId),
    case stand_computer(CList, RList) of
        {bust, _CScoreTotal, NewCList} ->
            ets:update_element(?CONST_ETS_CARD21, UserId, {#ets_card21.computer_cardId_list, NewCList}),
            cpint(NewCList),
            win(UserId),
            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_WIN),
            win;
       {stand, CScoreTotal, NewCList} ->
           ets:update_element(?CONST_ETS_CARD21, UserId, {#ets_card21.computer_cardId_list, NewCList}),
           cpint(NewCList),
           SelfScoreTotal = get_cards_score(SList),
           if
               CScoreTotal > SelfScoreTotal  ->
                   lose(UserId),
                   send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_LOSE),
                   lose;
               CScoreTotal == SelfScoreTotal ->
                   draw(UserId),
                   send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_DRAW),
                   draw;
               true ->
                   win(UserId),
                   send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_WIN),
                   win
           end
    end.
    
%% 要拍
hit(UserId) ->
    [#ets_card21{rest_card_list = RList, self_cardId_list = SList}] = ets:lookup(?CONST_ETS_CARD21, UserId),
    case hit(RList, SList) of
        {bust, ScoreTotal, NewSList} ->
            cpint(NewSList),
            ets:update_element(?CONST_ETS_CARD21, UserId, 
                               [{#ets_card21.self_cardId_list, NewSList}]),
            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_LOSE),
            lose(UserId),
            {failed, ScoreTotal};
        {hit, ScoreTotal, NewSList, NewRList} ->
            cpint(NewSList),
            ets:update_element(?CONST_ETS_CARD21, UserId, 
                               [{#ets_card21.self_cardId_list, NewSList},
                                {#ets_card21.rest_card_list, NewRList}]),
            send_game_state(UserId, ?CONST_GAMBLE_21CARD_STATE_GOING),
            {hit, ScoreTotal}
    end.
       
%%
%% Local Functions
%%

win(UserId) ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{chip_total = Total, chip_now = Now}] ->
            ets:update_element(?CONST_ETS_CARD21, UserId, 
                               [{#ets_card21.chip_total , Total - Now},
                                {#ets_card21.state, ?CONST_GAMBLE_21CARD_STATE_WIN}])
    end.

lose(UserId) ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{chip_total = Total, chip_now = Now}] ->
            ets:update_element(?CONST_ETS_CARD21, UserId, 
                               [{#ets_card21.chip_total , Total + Now},
                                {#ets_card21.state, ?CONST_GAMBLE_21CARD_STATE_LOSE}])
    end.
            
draw(UserId) ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        _ ->
            ets:update_element(?CONST_ETS_CARD21, UserId, {#ets_card21.state, ?CONST_GAMBLE_21CARD_STATE_DRAW})
    end.

send_game_state(UserId, State) ->
    case ets:lookup(?CONST_ETS_CARD21, UserId) of
        [] ->
            ok;
        [#ets_card21{self_cardId_list = SCard, computer_cardId_list = CCard}] ->
            Format =
                fun(CardId) ->
                        card_id_2_pcard(CardId)
                end,
            List1 = lists:map(Format, SCard),
            List2 = lists:map(Format, CCard),
            Packet = msg_sc_init_game(List1, List2, State),
            misc_packet:send(UserId, Packet)
    end.

test() ->
    Fun =
        fun(_) ->
                io:format("~w~n", [random:uniform(10)])
        end,
    lists:foreach(Fun, lists:seq(1, 1000)).

init_2_card_spec(CardList) ->
     {NewRList1, NewSList1, Score} = init_2_card(CardList),
     case Score =< 15 andalso Score >= 12 of
         true ->
             init_2_card_spec(CardList);
         _ ->
            {NewRList1, NewSList1, Score}
     end.

init_2_card(CardList) ->
    {hit, _, NewSList, NewRList} = hit(CardList, []),
    {hit, Score, NewSList1, NewRList1} = hit(NewRList, NewSList),
    {NewRList1, NewSList1, Score}.

get_cards_score(CList) ->
    Fun =
        fun(CardId) ->
                get_score(CardId)
        end,
    ScoreList= lists:map(Fun, CList),
    get_cards_score_loop(ScoreList).
get_cards_score_loop(ScoreList) ->
    Sum = lists:sum(ScoreList),
    case Sum > 21 andalso lists:member(11, ScoreList) of
        false ->
            Sum;
        _ ->
           ScoreList1 = lists:delete(11, ScoreList),
           get_cards_score_loop([1|ScoreList1])
    end.
    
stand_computer(Clist, RList) ->
    ScoreTotal = get_cards_score(Clist),
    case ScoreTotal > 16 of
        true ->
            {stand, ScoreTotal, Clist};
        _ ->
            case hit(RList, Clist) of
                {bust, ScoreTotal1, NewSList} ->
                    {bust, ScoreTotal1, NewSList};
                {hit, _ScoreTotal1, NewCList, NewRList} ->
                    stand_computer(NewCList, NewRList)
            end
    end.
        
cpint(CardList) ->
    io:format("cardList is :"),
    Fun =
        fun(CardId) ->
                {CardNumb, _} = card_id_2_pcard(CardId),
                io:format("~w  ", [CardNumb])
        end,
    lists:foreach(Fun, lists:reverse(CardList)),
    io:format(",, score is ~w~n", [get_cards_score(CardList)]).

 
hit(RList, SList) ->
    {NewRList, CardId} = get_a_pcard_random(RList),
    NewSList = [CardId|SList],
    ScoreTotal = get_cards_score(NewSList),
    case ScoreTotal > 21 of
        true ->
            {bust, ScoreTotal, NewSList};
        _ ->
            {hit, ScoreTotal, NewSList, NewRList}
    end.  
        
generate_set() ->
    lists:seq(1, 52).

generate_game() ->
    Fun =
        fun(_, AccList) ->
            L = generate_set(),
            AccList ++ L
        end,
    lists:foldl(Fun,[], lists:seq(1, ?CONST_CARD21_SET_COUNT)).

card_id_2_pcard(Id) ->
    Numb = Id rem 13 ,
    Color = Id div 13,
    case Numb == 0 of
        true ->
            {13, Color -1};
        _ ->
            {Numb, Color}
    end.

get_score(CardId) ->
    {Numb, _Color} = card_id_2_pcard(CardId),
    if
        Numb == 1 ->
            11;
        Numb > 10 ->
            10;
        true ->
            Numb
    end.

get_a_pcard_random(Set) ->
    N = misc:rand(1, length(Set)),
    CardId = lists:nth(N, Set),
    NewSet = lists:delete(CardId, Set),
    {NewSet, CardId}.

%% 当前牌局状态
%%[{CardPoint,CardColor},{BcardPoint,BcardColor},State]
msg_sc_init_game(List1,List2,State) ->
    misc_packet:pack(?MSG_ID_CARD21_SC_INIT_GAME, ?MSG_FORMAT_CARD21_SC_INIT_GAME, [List1,List2,State]).
%% 返回当前筹码数
%%[TotalChip]
msg_sc_total_chip(TotalChip) ->
    misc_packet:pack(?MSG_ID_CARD21_SC_TOTAL_CHIP, ?MSG_FORMAT_CARD21_SC_TOTAL_CHIP, [TotalChip]).
