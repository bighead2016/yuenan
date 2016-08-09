%%% 转盘
-module(new_serv_turn_api).

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
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([login/1, login_packet/2, turn/2, in/1, in_cb/2, get_turn_group_id/2, update_player_turn_group/2]).

%%
%% API Functions
%%

login(Player) ->
%%     EndTime = new_serv_api:get_new_serv_end_time(),
%%     Now = misc:seconds(),
%%     if
%%         Now >= EndTime ->
%%             NewServ = Player#player.new_serv,
%%             TurnData = NewServ#new_serv.turn,
%%             TurnData2 = TurnData#turn{times = 0},
%%             NewServ2 = NewServ#new_serv{turn = TurnData2},
%%             Player#player{new_serv = NewServ2};
%%         ?true ->
            NewServ = Player#player.new_serv,
            TurnData = NewServ#new_serv.turn,
            {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
            Count = TurnData#turn.count,
            Times = misc:max(CashSum div 1000 - Count, 0),
            TurnData2 = TurnData#turn{times = Times},
            NewServ2 = NewServ#new_serv{turn = TurnData2},
            Player#player{new_serv = NewServ2}.
%%     end.

login_packet(Player, OldPacket) ->
%%     EndTime = new_serv_api:get_new_serv_end_time(),
%%     Now = misc:seconds(),
%%     if
%%         Now >= EndTime ->
%%             {Player, OldPacket};
%%         ?true ->
            NewServ = Player#player.new_serv,
            TurnData = NewServ#new_serv.turn,
            Times = TurnData#turn.times,
            Packet = new_serv_api:msg_sc_travell_times(Times),
            {Player, <<OldPacket/binary, Packet/binary>>}.
%%     end.

in(UserId) ->
%%     EndTime = new_serv_api:get_new_serv_end_time(),
%%     Now = misc:seconds(),
%%     if
%%         Now >= EndTime ->
%%             ?ok;
%%         ?true ->
            case player_api:check_online(UserId) of
                ?true ->
                    player_api:process_send(UserId, ?MODULE, in_cb, []);
                ?false ->
                    ?ok
            end.
%%     end.

in_cb(Player, _) ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
    Count = TurnData#turn.count,
    Times = misc:max(CashSum div 1000 - Count, 0),
    TurnData2 = TurnData#turn{times = Times},
    NewServ2 = NewServ#new_serv{turn = TurnData2},
    Player2 = Player#player{new_serv = NewServ2},
    Packet = new_serv_api:msg_sc_travell_times(Times),
    misc_packet:send(Player2#player.user_id, Packet),
    {?ok, Player2}.

%% 根据时间获得对应物品组id
get_turn_group_id(Now, Group) ->
	case data_new_serv:get_turn({Group, 1}) of
		ItemInfo when is_record(ItemInfo, rec_new_serv_turn) ->
			if Now >= ItemInfo#rec_new_serv_turn.time_start andalso Now =< ItemInfo#rec_new_serv_turn.time_end ->
				   Group;
			   true ->
				   get_turn_group_id(Now, Group + 1)
			end;
		_ ->
			0
	end.
	
%% 更新player里面记录的转盘物品的group
update_player_turn_group(Player, Group) ->
	NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
	TurnData1 = TurnData#turn{group = Group},
	NewServ1 = NewServ#new_serv{turn = TurnData1},
	Player#player{new_serv = NewServ1}.

%% 转盘抽奖
turn(Player, 1) ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    Times = TurnData#turn.times,
    Info = Player#player.info,
    {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
    if
        Times > 0 ->
            {Player2, _, NewTimes, DirtyList, PartnerId, GoodsList, MailGoodsList, IdxList} = 
				do_turn_onekey(Player, CashSum, Times, [], 0, [], [], []),
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
turn(Player, 0) ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    Times = TurnData#turn.times,
    Count = TurnData#turn.count,
    IsGot = TurnData#turn.got_partner,
    {?ok, CashSum} = player_money_api:read_cash_sum(Player#player.user_id),
    if
        Times > 0 andalso Count > ?CONST_NEW_SERV_TURN_COUNT andalso CashSum >= ?CONST_NEW_SERV_TURN_CASH_SUM andalso 0 =:= IsGot ->
            do_turn_2(Player);
        Times > 0 ->
            do_turn(Player);
        ?true ->
            {?error, ?TIP_OP_TIMES_OVER}
    end.

do_turn_onekey(Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList) when Times > 0 ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    Times = TurnData#turn.times,
    Count = TurnData#turn.count,
    IsGot = TurnData#turn.got_partner,
	Group = TurnData#turn.group,
    
     if
        Count > ?CONST_NEW_SERV_TURN_COUNT andalso CashSum >= ?CONST_NEW_SERV_TURN_CASH_SUM andalso 0 =:= IsGot ->
            RateList = data_new_serv:get_turn_info({Group, 2}),
            Result = misc_random:odds_one(RateList),
            TurnData2 = TurnData#turn{count = Count + 1, times = Times - 1},
            NewServ2 = NewServ#new_serv{turn = TurnData2},
            IdxList = 
                    case lists:keytake(Result, 1, OldIdxList) of
                        {value, {_, C}, OldIdxList2} ->
                            [{Result, C+1}|OldIdxList2];
                        _ ->
                            [{Result, 1}|OldIdxList]
                    end,
            
            case data_new_serv:get_turn({Group, Result}) of
                #rec_new_serv_turn{goods = GoodsTuple, partner = PartnerId} ->
                    GoodsList = make_goods(GoodsTuple, []),
                    case ctn_bag2_api:set_stack_list_dirty(Player#player.user_id, Player#player.bag, GoodsList, 0, OldDirtyList) of
                        {?ok, Bag2, DirtyList} ->
                            {TurnData3, NewPartnerId} = 
                                if
                                    0 =/= PartnerId andalso 0 =:= OldPartnerId ->
                                        {TurnData2#turn{got_partner = ?CONST_SYS_TRUE}, PartnerId};
                                    ?true ->
                                        {TurnData2, OldPartnerId}
                                end,
                            NewServ3 = NewServ2#new_serv{turn = TurnData3},
                            
                            do_turn_onekey(Player#player{new_serv = NewServ3, bag = Bag2}, CashSum, Times-1, DirtyList, NewPartnerId, OldGoodsList++GoodsList, OldMailGoodsList, IdxList);
                        {?error, _ErrorCode} ->
                            do_turn_onekey(Player#player{new_serv = NewServ2}, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList++GoodsList, IdxList)
                    end;
                _ ->
                    {Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}
            end;
        ?true ->
            RateList = data_new_serv:get_turn_info({Group, 1}),
            Result = misc_random:odds_one(RateList),
            TurnData2 = TurnData#turn{count = Count + 1, times = Times - 1},
            NewServ2 = NewServ#new_serv{turn = TurnData2},
            IdxList = 
                    case lists:keytake(Result, 1, OldIdxList) of
                        {value, {_, C}, OldIdxList2} ->
                            [{Result, C+1}|OldIdxList2];
                        _ ->
                            [{Result, 1}|OldIdxList]
                    end,
            
            case data_new_serv:get_turn({Group, Result}) of
                #rec_new_serv_turn{goods = GoodsTuple} ->
                    GoodsList = make_goods(GoodsTuple, []),
                    case ctn_bag2_api:set_stack_list_dirty(Player#player.user_id, Player#player.bag, GoodsList, 0, OldDirtyList) of
                        {?ok, Bag2, DirtyList} ->
                            do_turn_onekey(Player#player{new_serv = NewServ2, bag = Bag2}, CashSum, Times-1, DirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList, IdxList);
                        {?error, _ErrorCode} ->
                            do_turn_onekey(Player#player{new_serv = NewServ2}, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList++GoodsList, OldMailGoodsList++GoodsList, IdxList)
                    end;
                _ ->
                    {Player, CashSum, Times-1, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}
            end
    end;
do_turn_onekey(Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList) ->
    {Player, CashSum, Times, OldDirtyList, OldPartnerId, OldGoodsList, OldMailGoodsList, OldIdxList}.

do_turn(Player) ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    Times = TurnData#turn.times,
    Count = TurnData#turn.count,
	Group = TurnData#turn.group,
	RateList = data_new_serv:get_turn_info({Group, 1}),
    Result = misc_random:odds_one(RateList),
    TurnData2 = TurnData#turn{count = Count + 1, times = Times - 1},
    NewServ2 = NewServ#new_serv{turn = TurnData2},
    Info = Player#player.info,
    UserName = Info#info.user_name,
    
    case data_new_serv:get_turn({Group, Result}) of
        #rec_new_serv_turn{goods = GoodsTuple} ->
            GoodsList = make_goods(GoodsTuple, []),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_NEW_SERV_TURN, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, BagPacket} ->
                    Packet = new_serv_api:msg_sc_target(Result),
                    TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
                    misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                    ReplyPacket = new_serv_api:msg_sc_reply(Result),
                    BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                    Player2#player{offline_packet = <<BagPacket/binary, ReplyPacket/binary>>, broadcast_packet = BroadcastPacket, new_serv = NewServ2};
                {?error, _ErrorCode} ->
                    Info = Player#player.info,
                    GoodsList2 = [{misc:to_list(G#goods.goods_id)}||G<-GoodsList],
                    mail_api:send_interest_mail_to_one2(Info#info.user_name, <<>>, <<>>, ?CONST_MAIL_FULL_PACKET, [{GoodsList2}], GoodsList, 0, 0, 0, ?CONST_COST_NEW_SERV_TURN),
                    Packet = new_serv_api:msg_sc_target(Result),
                    TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
                    misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                    BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                    Player#player{new_serv = NewServ2, broadcast_packet = BroadcastPacket}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

pack_goods([#goods{color = Color} = Goods|Tail], UserId, UserName, OldPacket) when Color > ?CONST_SYS_COLOR_PURPLE ->
	if Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP ->
		BPacket = message_api:msg_notice(?TIP_OP_TURN_EQUIP, [{UserId, UserName}], [Goods], []);
	true ->
		BPacket = message_api:msg_notice(?TIP_OP_TURN_GOODS, [{UserId, UserName}], [Goods], [])
	end,
    pack_goods(Tail, UserId, UserName, <<OldPacket/binary, BPacket/binary>>);
pack_goods([_|Tail], UserId, UserName, OldPacket) ->
    pack_goods(Tail, UserId, UserName, OldPacket);
pack_goods([], _, _, Packet) ->
    Packet.
    
do_turn_2(Player) ->
    NewServ = Player#player.new_serv,
    TurnData = NewServ#new_serv.turn,
    Times = TurnData#turn.times,
    Count = TurnData#turn.count,
	Group = TurnData#turn.group,
	RateList = data_new_serv:get_turn_info({Group, 2}),
    Result = misc_random:odds_one(RateList),
    TurnData2 = TurnData#turn{count = Count + 1, times = Times - 1},
    NewServ2 = NewServ#new_serv{turn = TurnData2},
    
    case data_new_serv:get_turn({Group, Result}) of
        #rec_new_serv_turn{goods = GoodsTuple, partner = PartnerId} ->
            GoodsList = make_goods(GoodsTuple, []),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_NEW_SERV_TURN, 1, 1, 0, 0, 0, 1, []) of
                {?ok, Player2, _, BagPacket} ->
                    Info = Player#player.info,
                    UserName = Info#info.user_name,
                    {Player3, PartnerPacket} = 
                        if
                            0 =/= PartnerId ->
                                PlayerT = partner_api:give_partner_list(Player2, [PartnerId], ?CONST_PARTNER_TEAM_IN),
                                TurnData3 = TurnData2#turn{got_partner = ?CONST_SYS_TRUE},
                                NewServ3 = NewServ2#new_serv{turn = TurnData3},
                                PartnerPacketT = message_api:msg_notice(?TIP_OP_TURN_PARTNER, 
                                                                        [{Player#player.user_id, UserName}], [], 
                                                                        [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)}]),
                                {PlayerT#player{new_serv = NewServ3}, PartnerPacketT};
                            ?true ->
                                {Player2#player{new_serv = NewServ2}, <<>>}
                        end,
                    Packet = new_serv_api:msg_sc_target(Result),
                    TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
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
                                TurnData3 = TurnData2#turn{got_partner = ?CONST_SYS_TRUE},
                                NewServ3 = NewServ2#new_serv{turn = TurnData3},
                                PartnerPacketT = message_api:msg_notice(?TIP_OP_TURN_PARTNER, 
                                                                        [{Player#player.user_id, UserName}], [], 
                                                                        [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)}]),
                                {PlayerT#player{new_serv = NewServ3}, PartnerPacketT};
                            ?true ->
                                {Player#player{new_serv = NewServ2}, <<>>}
                        end,
                    Packet = new_serv_api:msg_sc_target(Result),
                    TimesPacket = new_serv_api:msg_sc_travell_times(Times - 1),
                    misc_packet:send(Player#player.user_id, <<TimesPacket/binary, Packet/binary>>),
                    BroadcastPacket = pack_goods(GoodsList, Player#player.user_id, UserName, <<>>),
                    Player3#player{broadcast_packet = <<PartnerPacket/binary, BroadcastPacket/binary>>}
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
        
    
    
    