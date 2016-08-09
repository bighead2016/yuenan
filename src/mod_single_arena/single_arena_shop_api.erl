%%% 积分商店
-module(single_arena_shop_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([exchange/3]).

%%
%% API Functions
%%

exchange(Player, Id, Count) ->
    Member = single_arena_api:get_myself_info(Player#player.user_id),
    Score = Member#ets_arena_member.score,
    case data_single_arena:get_score_shop(Id) of
        #rec_single_arena_shop{cost = Cost, goods_id = 0, partner_id = PartnerId} ->
            Cost2 = round(Cost * Count),
            if
                Score >= Cost2 ->
                    Player2 = partner_api:give_partner_list(Player, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                    NewScore = Score - Cost2,
                    Member2 = Member#ets_arena_member{score = NewScore},
                    ets_api:insert(?CONST_ETS_ARENA_MEMBER, Member2),
                    ScorePacket = single_arena_api:msg_sc_score_update(NewScore),
                    TipPacket = message_api:msg_notice(?TIP_COMMON_EXCHANGE_OK),
                    misc_packet:send(Player#player.user_id, <<ScorePacket/binary, TipPacket/binary>>),
                    {?ok, Player2};
                ?true ->
                    {?error, ?TIP_SINGLE_ARENA_SCORE_NOT_ENOUGH}
            end;
        #rec_single_arena_shop{cost = Cost, goods_id = GoodsId} ->
            Cost2 = round(Cost * Count),
            if
                Score >= Cost2 ->
                    case goods_api:make(GoodsId, ?CONST_SYS_TRUE, Count) of
                        {?error, ErrorCode} ->
                            {?error, ErrorCode};
                        GoodsList ->
                            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SINGLE_ARENA_EXCHANGE, 1, 1, 1, 0, 0, 1, []) of
                                {?ok, Player2, _, GoodsPacket} ->
                                    NewScore = Score - Cost2,
                                    Member2 = Member#ets_arena_member{score = NewScore},
                                    ets_api:insert(?CONST_ETS_ARENA_MEMBER, Member2),
                                    ScorePacket = single_arena_api:msg_sc_score_update(NewScore),
                                    TipPacket = message_api:msg_notice(?TIP_COMMON_EXCHANGE_OK),
                                    misc_packet:send(Player#player.user_id, <<GoodsPacket/binary, ScorePacket/binary, TipPacket/binary>>),
                                    {?ok, Player2};
                                {?error, ErrorCode} ->
                                    {?error, ErrorCode}
                            end
                    end;
                ?true ->
                    {?error, ?TIP_SINGLE_ARENA_SCORE_NOT_ENOUGH}
            end;
        _ ->
            {?error, ?TIP_SINGLE_ARENA_GOODS_NOT_EXISTS}
    end.

%%
%% Local Functions
%%

