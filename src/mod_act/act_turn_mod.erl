%%% 转盘

-module(act_turn_mod).
-behaviour(act_bhv).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.act.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([init/1, join/2, over/1, login/1, logout/1, login_packet/2, offline/2, refresh/2 ]).
-export([turn/2]).

%%
%% API Functions
%%

refresh(UserId, ACTID)->
  	?ok.	

login(OldPlayer) ->
    OldPlayer.

logout(OldPlayer) ->
    OldPlayer.

login_packet(OldPlayer, ActId) ->
    UserId = OldPlayer#player.user_id,
    % case act_db_mod:sel_ets_act_user({UserId, ActId}) of
    %     #ets_act_user{data = Data} ->
    %         Packet = new_serv_api:msg_sc_travell_times(Data#act_turn_data.times),
    %         {OldPlayer, Packet};
    %     _ ->
            {OldPlayer, <<>>}.
    % end.

init(Id) ->
%%     ?MSG_ERROR("init:~p...", [Id]),
    ok.

join(cash_in, [UserId, Cash, Point, ActInfo]) ->
    do_cash_in(UserId, ActInfo, Cash, Point);
join(_, [UserId, Cash, Point, ActInfo]) ->
    ok.

over(EtsActUser) ->
%%     ?MSG_ERROR("over:...", []),
    ok.

offline(Player, _Data) ->
    {?ok, Player}.

do_cash_in(UserId, #ets_act_info{id = ActId}, Cash, _) ->
    case act_bhv:get_act_user(UserId, ActId) of
        #ets_act_user{data = Data} = Rec ->
            OldCash  = Data#act_turn_data.in_cash,
            NewCash  = OldCash + Cash,
            OldCount = Data#act_turn_data.count,
            NewTimes = calc_times(NewCash, OldCount),
            Data2    = Data#act_turn_data{times = NewTimes, in_cash = NewCash},
            act_db_mod:ins_ets_act_user(Rec#ets_act_user{data = Data2}),
            case player_api:check_online(UserId) of
                ?true ->
                    Packet = new_serv_api:msg_sc_travell_times(NewTimes),
                    misc_packet:send(UserId, Packet);
                ?false ->
                    ?ok
            end;
        _ ->
            NewTimes = calc_times(Cash, 0), 
            Data     = #act_turn_data{count = 0, got_partner = 0, in_cash = Cash, times = NewTimes},
            act_db_mod:ins_ets_act_user(#ets_act_user{data = Data, act_id = ActId, key = {UserId, ActId}, user_id = UserId}),
            case player_api:check_online(UserId) of
                ?true ->
                    Packet = new_serv_api:msg_sc_travell_times(NewTimes),
                    misc_packet:send(UserId, Packet);
                ?false ->
                    ?ok
            end
    end.

%% 1 次/1000yb
calc_times(Cash, OldCount) ->
    misc:max(Cash div 1000 - OldCount, 0).

%% 转盘抽奖
turn(Player, Type) ->
    case act_db_mod:sel_ets_act_temp(1) of
        #ets_act_tmp{act_id = ActId} ->
            turn(Player, Type, ActId);
        _ ->
            ok
    end.
turn(Player, 1, ActId) ->
    case act_bhv:get_act_user(Player#player.user_id, ActId) of
        #ets_act_user{data = Data} ->
            Times = Data#act_turn_data.times,
            Info = Player#player.info,
            {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
            if
                Times > 0 ->
                    {Player2, _, NewTimes, DirtyList, PartnerId, GoodsList, MailGoodsList, IdxList} = 
                        do_turn_onekey(Player, CashSum, Times, [], 0, [], [], [], ActId),
                    GoodsList2 = sum_goods(GoodsList, []),
                    MailGoodsList2 = sum_goods(MailGoodsList, []),
                    MailGoodsList3 = [{misc:to_list(G#goods.goods_id)}||G<-MailGoodsList2],
                    mail_api:send_interest_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, [{MailGoodsList3}], 
                                                        MailGoodsList2, 0, 0, 0, ?CONST_COST_NEW_SERV_TURN),
                    
                    % XXX
                    {Player2_2, StylePacket} = goods_style_api:add_style_list(Player2, GoodsList),
                    {Player2_3, SkillPacket} = horse_skill_api:upgrade_skill_base(Player2_2, GoodsList),
                    
                    TimesPacket = new_serv_api:msg_sc_travell_times(NewTimes),
                    misc_packet:send(Player2_3#player.user_id, TimesPacket),
                    BroadcastPacket = pack_goods(GoodsList2, Player#player.user_id, Info#info.user_name, <<>>),
                    GoodsPacket = goods_api:pack_dirty(Player2_3, DirtyList),
                    IdxPacket = new_serv_api:msg_sc_total_show(IdxList),
                    
                    if
                        0 =/= PartnerId ->
                            Player3 = partner_api:give_partner_list(Player2_3, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                            PartnerPacketT = message_api:msg_notice(?TIP_OP_TURN_PARTNER, 
                                                                    [{Player#player.user_id, Info#info.user_name}], [], 
                                                                    [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)}]),
                            misc_packet:send(Player#player.user_id, <<PartnerPacketT/binary, GoodsPacket/binary, IdxPacket/binary, StylePacket/binary, SkillPacket/binary>>),
                            misc_app:broadcast_world_2(BroadcastPacket),
                            {?ok, Player3};
                        ?true ->
                            misc_packet:send(Player#player.user_id, <<GoodsPacket/binary, IdxPacket/binary, StylePacket/binary, SkillPacket/binary>>),
                            misc_app:broadcast_world_2(BroadcastPacket),
                            {?ok, Player2}
                    end;
                ?true ->
                    {?error, ?TIP_OP_TIMES_OVER}
            end;
        _ ->
            {?error, ?TIP_OP_TIMES_OVER}
    end;
turn(Player, 0, ActId) ->
    case act_bhv:get_act_user(Player#player.user_id, ActId) of
        #ets_act_user{data = Data} ->
            Times = Data#act_turn_data.times,
            Count = Data#act_turn_data.count,
            IsGot = Data#act_turn_data.got_partner,
            {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
            if
                Times > 0 andalso Count > ?CONST_NEW_SERV_TURN_COUNT andalso CashSum >= ?CONST_NEW_SERV_TURN_CASH_SUM andalso 0 =:= IsGot ->
                    do_turn_2(Player, ActId);
                Times > 0 ->
                    do_turn(Player, ActId);
                ?true ->
                    {?error, ?TIP_OP_TIMES_OVER}
            end;
        _ ->
            {?error, ?TIP_OP_TIMES_OVER}
    end.

do_turn_onekey(Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList, ActId) when Times > 0 ->
    case act_bhv:get_act_user(Player#player.user_id, ActId) of
        #ets_act_user{data = Data} = EtsActUser ->
            Times2 = Data#act_turn_data.times,
            Count = Data#act_turn_data.count,
            IsGot = Data#act_turn_data.got_partner,
            if
                Count > ?CONST_NEW_SERV_TURN_COUNT andalso CashSum >= ?CONST_NEW_SERV_TURN_CASH_SUM andalso 0 =:= IsGot ->
                    #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
                    RateList = data_act:get_turn_info({ConfigId, 2}),
%%                     Result = misc_random:odds_one(RateList),
                    Result = 10,
                    Data2 = Data#act_turn_data{count = Count + 1, times = Times2 - 1}, 
                    IdxList = 
                        case lists:keytake(Result, 1, OldIdxList) of
                            {value, {_, C}, OldIdxList2} ->
                                [{Result, C+1}|OldIdxList2];
                            _ ->
                                [{Result, 1}|OldIdxList]
                        end,
                    #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
                    case data_act:get_act_turn({ConfigId, Result}) of
                        #rec_act_turn{goods = GoodsTuple, partner = PartnerId} ->
                            GoodsList = make_goods(GoodsTuple, []),
                            case ctn_bag2_api:set_stack_list_dirty(Player#player.user_id, Player#player.bag, GoodsList, 0, OldDirtyList) of
                                {?ok, Bag2, DirtyList} ->
                                    NewPartnerId = 
                                        if
                                            0 =/= PartnerId andalso 0 =:= OldPartnerId ->
                                                Data3 = Data2#act_turn_data{got_partner = ?CONST_SYS_TRUE},
                                                EtsActUser2 = EtsActUser#ets_act_user{data = Data3},
                                                act_db_mod:ins_ets_act_user(EtsActUser2),
                                                PartnerId;
                                            ?true ->
                                                EtsActUser2 = EtsActUser#ets_act_user{data = Data2},
                                                act_db_mod:ins_ets_act_user(EtsActUser2),
                                                OldPartnerId
                                        end,
                                    do_turn_onekey(Player#player{bag = Bag2}, CashSum, Times-1, DirtyList, NewPartnerId, OldGoodsList++GoodsList, OldMailGoodsList, IdxList, ActId);
                                {?error, _ErrorCode} ->
                                    do_turn_onekey(Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList++GoodsList, IdxList, ActId)
                            end;
                        _ ->
                            {Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}
                    end;
                ?true ->
                    #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
                    RateList = data_act:get_turn_info({ConfigId, 1}),
%%                     Result = misc_random:odds_one(RateList),
                    Result = 10,
                    Data2 = Data#act_turn_data{count = Count + 1, times = Times2 - 1}, 
                    IdxList = 
                        case lists:keytake(Result, 1, OldIdxList) of
                            {value, {_, C}, OldIdxList2} ->
                                [{Result, C+1}|OldIdxList2];
                            _ ->
                                [{Result, 1}|OldIdxList]
                        end,
                    #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
                    case data_act:get_act_turn({ConfigId, Result}) of
                        #rec_act_turn{goods = GoodsTuple} ->
                            GoodsList = make_goods(GoodsTuple, []),
                            EtsActUser2 = EtsActUser#ets_act_user{data = Data2},
                            act_db_mod:ins_ets_act_user(EtsActUser2),
                            case ctn_bag2_api:set_stack_list_dirty(Player#player.user_id, Player#player.bag, GoodsList, 0, OldDirtyList) of
                                {?ok, Bag2, DirtyList} ->
                                    do_turn_onekey(Player#player{bag = Bag2}, CashSum, Times-1, DirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList, IdxList, ActId);
                                {?error, _ErrorCode} ->
                                    do_turn_onekey(Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList++GoodsList, IdxList, ActId)
                            end;
                        _ ->
                            {Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}
                    end
            end;
        _ ->
            {?error, ?TIP_OP_TIMES_OVER}
    end;
do_turn_onekey(Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList, _) ->
    {Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}.

do_turn(Player, ActId) ->
    case act_db_mod:sel_ets_act_user({Player#player.user_id, ActId}) of
        #ets_act_user{data = Data} = EtsActUser ->
            Times = Data#act_turn_data.times,
            Count = Data#act_turn_data.count,
            #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
            RateList = data_act:get_turn_info({ConfigId, 1}),
%%             Result = misc_random:odds_one(RateList),
            Result = 10,
            Data2 = Data#act_turn_data{count = Count + 1, times = Times - 1}, 
            EtsActuser2 = EtsActUser#ets_act_user{data = Data2},
            act_db_mod:ins_ets_act_user(EtsActuser2),
            Info = Player#player.info,
            UserName = Info#info.user_name,
            
            case data_act:get_act_turn({ConfigId, Result}) of
                #rec_act_turn{goods = GoodsTuple} ->
                    GoodsList = make_goods(GoodsTuple, []),
                    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_NEW_SERV_TURN, 1, 1, 0, 0, 0, 1, []) of
                        {?ok, Player2, _, BagPacket} ->
                            Packet = new_serv_api:msg_sc_target(Result),
                            TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
                            misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                            ReplyPacket = new_serv_api:msg_sc_reply(Result),
                            BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                            Player2#player{offline_packet = <<BagPacket/binary, ReplyPacket/binary>>, broadcast_packet = BroadcastPacket};
                        {?error, _ErrorCode} ->
                            Info = Player#player.info,
                            GoodsList2 = [{misc:to_list(G#goods.goods_id)}||G<-GoodsList],
                            mail_api:send_interest_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, [{GoodsList2}], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_TURN),
                            Packet = new_serv_api:msg_sc_target(Result),
                            TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
                            misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                            BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                            Player#player{broadcast_packet = BroadcastPacket}
                    end;
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

pack_goods([#goods{color = Color} = Goods|Tail], UserId, UserName, OldPacket) when Color > ?CONST_SYS_COLOR_PURPLE ->
    BPacket = 
        if Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP ->
            message_api:msg_notice(?TIP_OP_TURN_EQUIP, [{UserId, UserName}], [Goods], []);
        true ->
            message_api:msg_notice(?TIP_OP_TURN_GOODS, [{UserId, UserName}], [Goods], [])
        end,
    pack_goods(Tail, UserId, UserName, <<OldPacket/binary, BPacket/binary>>);
pack_goods([_|Tail], UserId, UserName, OldPacket) ->
    pack_goods(Tail, UserId, UserName, OldPacket);
pack_goods([], _, _, Packet) ->
    Packet.
    
do_turn_2(Player, ActId) ->
    case act_db_mod:sel_ets_act_user({Player#player.user_id, ActId}) of
        #ets_act_user{data = Data} = EtsActUser ->
            Times = Data#act_turn_data.times,
            Count = Data#act_turn_data.count,
            #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
            RateList = data_act:get_turn_info({ConfigId, 2}),
%%             Result = misc_random:odds_one(RateList),
            Result = 10,
            NewTimes = Times - 1,
            Data2 = Data#act_turn_data{count = Count + 1, times = NewTimes}, 
            Info = Player#player.info,
            UserName = Info#info.user_name,
            #rec_act_time{config_id = ConfigId} = data_act:get_act(ActId),
            case data_act:get_act_turn({ConfigId, Result}) of
                #rec_act_turn{goods = GoodsTuple, partner = PartnerId} ->
                    GoodsList = make_goods(GoodsTuple, []),
                    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_NEW_SERV_TURN, 1, 1, 0, 0, 0, 1, []) of
                        {?ok, Player2, _, BagPacket} ->
                            Info = Player#player.info,
                            UserName = Info#info.user_name,
                            {Player3, PartnerPacket} = 
                                if
                                    0 =/= PartnerId ->
                                        PlayerT = partner_api:give_partner_list(Player2, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                                        Data3 = Data2#act_turn_data{got_partner = ?CONST_SYS_TRUE},
                                        EtsActuser2 = EtsActUser#ets_act_user{data = Data3},
                                        act_db_mod:ins_ets_act_user(EtsActuser2),
                                        PartnerPacketT = message_api:msg_notice(?TIP_OP_TURN_PARTNER, 
                                                                                [{Player#player.user_id, UserName}], [], 
                                                                                [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)}]),
                                        {PlayerT, PartnerPacketT};
                                    ?true ->
                                        EtsActuser2 = EtsActUser#ets_act_user{data = Data2},
                                        act_db_mod:ins_ets_act_user(EtsActuser2),
                                        {Player2, <<>>}
                                end,
                            Packet = new_serv_api:msg_sc_target(Result),
                            TimesPacket = new_serv_api:msg_sc_travell_times(NewTimes),
                            misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                            ReplyPacket = new_serv_api:msg_sc_reply(Result),
                            BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                            Player3#player{offline_packet = <<BagPacket/binary, ReplyPacket/binary>>, broadcast_packet = <<PartnerPacket/binary, BroadcastPacket/binary>>};
                        {?error, _ErrorCode} ->
                            Info = Player#player.info,
                            GoodsList2 = [{misc:to_list(G#goods.goods_id)}||G<-GoodsList],
                            mail_api:send_interest_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, [{GoodsList2}], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_TURN),
                            Info = Player#player.info,
                            UserName = Info#info.user_name,
                            {Player3, PartnerPacket} = 
                                if
                                    0 =/= PartnerId ->
                                        PlayerT = partner_api:give_partner_list(Player, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                                        Data3 = Data2#act_turn_data{got_partner = ?CONST_SYS_TRUE},
                                        EtsActuser2 = EtsActUser#ets_act_user{data = Data3},
                                        act_db_mod:ins_ets_act_user(EtsActuser2),
                                        PartnerPacketT = message_api:msg_notice(?TIP_OP_TURN_PARTNER, 
                                                                                [{Player#player.user_id, UserName}], [], 
                                                                                [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)}]),
                                        {PlayerT, PartnerPacketT};
                                    ?true ->
                                        EtsActuser2 = EtsActUser#ets_act_user{data = Data2},
                                        act_db_mod:ins_ets_act_user(EtsActuser2),
                                        {Player, <<>>}
                                end,
                            Packet = new_serv_api:msg_sc_target(Result),
                            TimesPacket = new_serv_api:msg_sc_travell_times(NewTimes),
                            misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                            BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                            Player3#player{broadcast_packet = <<PartnerPacket/binary, BroadcastPacket/binary>>}
                    end;
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

%%
%% Local Functions
%%
make_goods([{GoodsId, IsBind, Count}|Tail], OldList) ->
    case goods_api:make(GoodsId, IsBind, Count) of
        {?error, _} ->
            make_goods(Tail, OldList);
        GoodsList -> 
            make_goods(Tail, OldList++GoodsList)
    end;
make_goods([], List) ->
    List;
make_goods(_, OldList) ->
    OldList.

sum_goods([#goods{goods_id = Id, count = Count} = Goods|Tail], OldList) ->
    case lists:keytake(Id, #goods.goods_id, OldList) of
        {value, G, OldList2} ->
            sum_goods(Tail, [G#goods{count = Count+G#goods.count}|OldList2]);
        _ ->
            sum_goods(Tail, [Goods|OldList])
    end;
sum_goods([], List) ->
    List.
        
    
