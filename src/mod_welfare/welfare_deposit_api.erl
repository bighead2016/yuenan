%%% 充值活动
-module(welfare_deposit_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.base.data.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([init/0, login_packet/1, flush_offline/2, login/1, refresh/1]).
-export([in/3, out/3, in_cb/2, out_cb/2, get_gift/2, drop/1,send_mail/2]).

%%
%% API Functions
%%

%% 初始化
init() ->
    [].

flush_offline(Player, [in_cb, Cash, Sec, IsSend]) ->
    {?ok, NewPlayer} = in_cb(Player, [Cash, Sec, IsSend]),
    {?ok, NewPlayer};
flush_offline(Player, [out_cb, Cash, Sec, IsSend]) ->
    {?ok, NewPlayer} = out_cb(Player, [Cash, Sec, IsSend]),
    {?ok, NewPlayer}.

login(Player) ->
    drop(Player).

refresh(Player) ->
    Player2 = drop_zero(Player),
    Packet = login_packet(Player2),
    misc_packet:send(Player#player.user_id, Packet),
    {?ok, Player2}.

%% 过期
drop(Player) ->
    Welfare = Player#player.welfare,
    DepositList = Welfare#welfare.deposit,
    Sec = misc:seconds(),
    Login = Welfare#welfare.login,
    IsSameDay = misc:is_same_date(Login, Sec),
    {Player2, DepositList2} = 
        if
            ?false =:= IsSameDay ->
                ?MSG_ERROR("1[~p|~p|~p]", [Login, Sec, IsSameDay]),
                drop_zero(Player, DepositList, Sec, []);
            ?true ->
                ?MSG_ERROR("1[~p|~p|~p]", [Login, Sec, IsSameDay]),
                drop(Player, DepositList, Sec, [])
        end,
    Welfare2 = Player2#player.welfare,
    Player2#player{welfare = Welfare2#welfare{deposit = DepositList2}}.

drop(Player, [#deposit_group{group_id = GroupId} = DepGroup|Tail], Sec, OldList) ->
    NewServSec = new_serv_api:get_serv_start_time(), 
    case data_welfare:get_deposit_active_time(GroupId) of
        {new_serv, EndSec} 
          when EndSec =/= 0 andalso NewServSec+EndSec*?CONST_SYS_ONE_DAY_SECONDS < Sec ->
            Player2 = drop_group(Player, DepGroup),
            drop(Player2, Tail, Sec, OldList);
        {S, EndSec} 
          when EndSec =/= 0 andalso EndSec < Sec andalso S =/= 'new_serv' ->
            Player2 = drop_group(Player, DepGroup),
            drop(Player2, Tail, Sec, OldList);
        _ ->
            drop(Player, Tail, Sec, [DepGroup|OldList])
    end;
drop(Player, [], _, List) ->
    {Player, List}.

drop_zero(Player) ->
    Welfare = Player#player.welfare,
    DepositList = Welfare#welfare.deposit,
    Sec = misc:seconds(),
    {Player2, DepositList2} = drop_zero(Player, DepositList, Sec, []),
    Welfare2 = Player2#player.welfare,
    Player2#player{welfare = Welfare2#welfare{deposit = DepositList2, login = Sec}}.

drop_zero(Player, [#deposit_group{group_id = GroupId} = DepGroup|Tail], Sec, OldList) ->
    MoneyPacket = welfare_api:msg_sc_rmb(GroupId, 0, 0),
    misc_packet:send(Player#player.user_id, MoneyPacket),
    NewServSec = new_serv_api:get_serv_start_time(),
    case data_welfare:get_deposit_active_time(GroupId) of
        {new_serv, EndSec} 
          when EndSec =/= 0 andalso NewServSec+EndSec*?CONST_SYS_ONE_DAY_SECONDS < Sec ->
            Player2 = drop_group(Player, DepGroup),
            drop_zero(Player2, Tail, Sec, OldList);
        {nday, NDays, _BeginSec, EndSec} 
          when NDays =/= 0 orelse EndSec < Sec ->
            Diff = misc:round((Sec - NewServSec) / ?CONST_SYS_ONE_DAY_SECONDS) rem NDays,
            if
                0 =:= Diff ->
                    Player2 = drop_group(Player, DepGroup),
                    drop_zero(Player2, Tail, Sec, OldList);
                ?true ->
                    drop_zero(Player, Tail, Sec, OldList)
            end;
        {S, EndSec} 
          when EndSec =/= 0 andalso EndSec < Sec andalso S =/= 'new_serv' ->
            Player2 = drop_group(Player, DepGroup),
            drop_zero(Player2, Tail, Sec, OldList);
        _ ->
            drop_zero(Player, Tail, Sec, [DepGroup|OldList])
    end;
drop_zero(Player, [], _, List) ->
    {Player, List}.

drop_group(Player, #deposit_group{single_data = SingleData, accum_data = AccumData}) ->
    Player2 = drop_list(Player, SingleData),
    drop_list(Player2, AccumData).

drop_list(Player, [#deposit_gift{gift_id = GiftId, state = ?CONST_WELFARE_UNCLAIMED}|Tail]) ->
    case data_welfare:get_deposit_gift_info(GiftId) of
        #rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_DAILY_ACCUM} ->
            ?ok;
        _ ->
            send_mail(Player, GiftId)
    end,
    drop_list(Player, Tail);
drop_list(Player, [#deposit_gift{gift_id = GiftId, acitve_id = AId, state = State}|Tail]) ->
    case data_welfare:get_deposit_gift_info(GiftId) of
        #rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_DAILY_ACCUM} ->
            P = welfare_api:msg_sc_deposit_info(AId, GiftId, ?CONST_WELFARE_UNCLAIMED),
            misc_packet:send(Player#player.user_id, P);
        _ when ?CONST_WELFARE_RECEIVED =:= State ->
            ?ok;
        _ ->
            send_mail(Player, GiftId)
    end,
    drop_list(Player, Tail);
drop_list(Player, [_|Tail]) ->
    drop_list(Player, Tail);
drop_list(Player, []) ->
    Player.

send_mail(Player, GiftId) ->
    Info = Player#player.info,
    UserName = Info#info.user_name,
    case data_welfare:get_deposit_gift_info(GiftId) of
        #rec_welfare_deposit{cash = Cash, cash_bind = BCash, gold = BGold, goods = GoodsTupleList} ->
            GoodsList = make_goods(GoodsTupleList, []),
            send_mail(UserName, <<"">>, <<"">>, GoodsList, BGold, Cash, BCash);
        _ ->
            ?ok
    end.

send_mail(UserName, Title, Content, GoodsList, BGold, Cash, BCash) ->
	GoodsIdList		= mail_api:get_goods_id(GoodsList, []),
	Content1		= [{GoodsIdList}],
    mail_api:send_interest_mail_to_one2(UserName, Title, Content, ?CONST_MAIL_DEPOSIT, Content1, 
									  GoodsList, BGold, Cash, BCash, ?CONST_COST_WELFARE_OVERTIME).

make_goods([{GoodsId, Count, IsBind}|Tail], OldList) ->
    NewGoodsList = 
        case goods_api:make(GoodsId, Count, IsBind) of
            {?error, _} ->
                OldList;
            GoodsList ->
                GoodsList ++ OldList
        end,
    make_goods(Tail, NewGoodsList);
make_goods([], List) ->
    List.

%% ------------------------------------- 充值 ---------------------------------------------------
in(UserId, Cash, Sec) ->
    case player_api:check_online(UserId) of
        ?true ->
            player_api:process_send(UserId, ?MODULE, in_cb, [Cash, Sec, ?CONST_SYS_TRUE]);
        ?false ->
            player_offline_api:offline(?MODULE, UserId, [in_cb, Cash, Sec, ?CONST_SYS_FALSE])
    end.

in_cb(Player, [Cash, Sec, IsSend]) ->
    UserId      = Player#player.user_id,
    Info        = Player#player.info,
    UserName    = Info#info.user_name,
    ActingGroupList = get_acting_group_list(Sec),
    Welfare     = Player#player.welfare,
    DepositList = Welfare#welfare.deposit,
    {NewDepositList, Packet} = handle_in(ActingGroupList, DepositList, Cash, <<>>, UserName),
    NewPlayer   = 
        if
            ?CONST_SYS_TRUE =:= IsSend ->
                misc_packet:send(UserId, Packet),
                Player;
            ?true ->
                OfflinePacket = Player#player.offline_packet,
                Player#player{offline_packet = <<OfflinePacket/binary, Packet/binary>>}
        end,
    NewWelfare = Welfare#welfare{deposit = NewDepositList},
    NewPlayer2 = NewPlayer#player{welfare = NewWelfare},
    {?ok, NewPlayer2}.

handle_in([#rec_welfare_deposit_time{group_id = GroupId}|Tail], DepositList, Cash, OldPacket, UserName) ->
    {NewDepositList, NewPacket} = 
        case data_welfare:get_deposit_group_in(GroupId) of
            List when is_list(List) ->
                {DepositList2, MoneyPacket} = update_amount_in(DepositList, GroupId, Cash, [], ?CONST_SYS_FALSE, <<>>),
                handle_in_2(List, DepositList2, Cash, MoneyPacket, UserName);
            _ ->
                {DepositList, <<>>}
        end,
    handle_in(Tail, NewDepositList, Cash, <<OldPacket/binary, NewPacket/binary>>, UserName);
handle_in([], DepositList, _Cash, Packet, _) ->
    {DepositList, Packet}.

update_amount_in([#deposit_group{group_id = GroupId, amount_in = AmountIn} = DepGroup|Tail], GroupId, Cash, OldList, _, OldPacket) ->
    DepGroup2 = DepGroup#deposit_group{amount_in = AmountIn + Cash},
    AmountOut = DepGroup2#deposit_group.amount_out,
    MoneyPacket = welfare_api:msg_sc_rmb(GroupId, AmountOut, AmountIn + Cash),
    update_amount_in(Tail, GroupId, Cash, [DepGroup2|OldList], ?CONST_SYS_TRUE, <<OldPacket/binary, MoneyPacket/binary>>);
update_amount_in([#deposit_group{} = DepGroup|Tail], GroupId, Cash, OldList, IsExists, OldPacket) ->
    update_amount_in(Tail, GroupId, Cash, [DepGroup|OldList], IsExists, OldPacket);
update_amount_in([], _, _, OldList, ?CONST_SYS_TRUE, OldPacket) ->
    {OldList, OldPacket};
update_amount_in([], GroupId, Cash, OldList, ?CONST_SYS_FALSE, OldPacket) ->
    MoneyPacket = welfare_api:msg_sc_rmb(GroupId, 0, Cash),
    {[#deposit_group{group_id = GroupId, amount_in = Cash, amount_out = 0, accum_data = [], single_data = []}|OldList], <<OldPacket/binary, MoneyPacket/binary>>}.

handle_in_2([#rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_SINGLE} = RecDep|Tail], DepositList, Cash, OldPacket, UserName) ->
    {DepositList2, Packet} = handle_single_in(DepositList, RecDep, Cash),
    handle_in_2(Tail, DepositList2, Cash, <<OldPacket/binary, Packet/binary>>, UserName);
handle_in_2([#rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_ACCUM} = RecDep|Tail], DepositList, Cash, OldPacket, UserName) ->
    {DepositList2, Packet} = handle_accum_in(DepositList, RecDep),
    handle_in_2(Tail, DepositList2, Cash, <<OldPacket/binary, Packet/binary>>, UserName);
handle_in_2([#rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_DAILY_ACCUM} = RecDep|Tail], DepositList, Cash, OldPacket, UserName) ->
    {DepositList2, Packet} = handle_daily_accum_in(DepositList, RecDep, UserName),
    handle_in_2(Tail, DepositList2, Cash, <<OldPacket/binary, Packet/binary>>, UserName);
handle_in_2([_|Tail], DepositList, Cash, OldPacket, UserName) ->
    handle_in_2(Tail, DepositList, Cash, OldPacket, UserName);
handle_in_2([], DepositList, _, OldPacket, _UserName) ->
    {DepositList, OldPacket}.

%% 处理单笔充值
handle_single_in(DepositList, #rec_welfare_deposit{group_id = GroupId, money_from = MFrom, money_to = MTo} = RecDep, Cash) 
  when MFrom =< Cash andalso Cash =< MTo ->
    Gift            = record_deposit_gift(RecDep),
    {NewDepositList, Packet}  = 
        case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
            {value, DepositGroup, DepositList2} ->
                SingleData      = DepositGroup#deposit_group.single_data,
                {DepositList3, TotalPacket}   = 
                    case is_exist(SingleData, Gift) of
                        ?true ->
                            {DepositList, <<>>};
                        ?false ->
                            SingleData2   = [Gift|SingleData],
                            DepositGroup2 = DepositGroup#deposit_group{single_data = SingleData2},
                            SinglePacket  = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED),
                            {[DepositGroup2|DepositList2], SinglePacket}
                    end,
                {DepositList3, TotalPacket};
            _ ->
                TotalPacket  = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED),
                {[record_deposit_group(GroupId, [Gift])|DepositList], TotalPacket}
        end,
    {NewDepositList, Packet};
handle_single_in(DepositList, _, _) ->
    {DepositList, <<>>}.

%% 处理累计充值
handle_accum_in(DepositList, #rec_welfare_deposit{group_id = GroupId, money_from = MFrom} = RecDep) ->
    Gift            = record_deposit_gift(RecDep),
    {NewDepositList, NewPacket}  = 
        case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
            {value, DepositGroup, DepositList2} ->
                AccumData       = DepositGroup#deposit_group.accum_data,
                AmountIn        = DepositGroup#deposit_group.amount_in,
                if
                    MFrom =< AmountIn -> % andalso AmountIn =< MTo ->
                        case is_exist(AccumData, Gift) of
                            ?true ->
                                {DepositList, <<>>};
                            ?false ->
                                AccumData2    = [Gift|AccumData],
                                DepositGroup2 = DepositGroup#deposit_group{accum_data = AccumData2},
                                AccumPacket   = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED),
                                {[DepositGroup2|DepositList2], AccumPacket}
                        end;
                    ?true ->
                        {DepositList, <<>>}
                end;
            _ ->
                {DepositList, <<>>}
        end,
    {NewDepositList, NewPacket}.
handle_daily_accum_in(DepositList, #rec_welfare_deposit{group_id = GroupId, money_from = MFrom} = RecDep, UserName) ->
    Gift            = record_deposit_gift(RecDep, ?CONST_WELFARE_RECEIVED),
    {NewDepositList, NewPacket}  = 
        case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
            {value, DepositGroup, DepositList2} ->
                AccumData       = DepositGroup#deposit_group.accum_data,
                AmountIn        = DepositGroup#deposit_group.amount_in,
                if
                    MFrom =< AmountIn -> % andalso AmountIn =< MTo ->
                        case is_exist(AccumData, Gift) of
                            ?true ->
                                {DepositList, <<>>};
                            ?false ->
                                AccumData2    = [Gift|AccumData],
                                DepositGroup2 = DepositGroup#deposit_group{accum_data = AccumData2},
                                case data_welfare:get_deposit_gift_info(Gift#deposit_gift.gift_id) of
                                    #rec_welfare_deposit{cash = Cash, cash_bind = BCash, gold = BGold, goods = GoodsList} ->
                                        GoodsList2 = make_goods(GoodsList, []),
                                        mail_api:send_interest_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_DAILY_DEPOSIT_IN, 
                                                                          [{[{misc:to_list(MFrom)}]}], GoodsList2, BGold, Cash, BCash, 
                                                                          ?CONST_COST_WELFARE_DAILY_GIFT),
                                        DepositInfoPacket = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_RECEIVED),
                                        {[DepositGroup2|DepositList2], DepositInfoPacket};
                                    _ ->
                                        {[DepositGroup2|DepositList2], <<>>}
                                end
                        end;
                    ?true ->
                        {DepositList, <<>>}
                end;
            _ ->
                {DepositList, <<>>}
        end,
    {NewDepositList, NewPacket}.

is_exist([#deposit_gift{gift_id = GiftId}|_], #deposit_gift{gift_id = GiftId}) -> ?true;
is_exist([#deposit_gift{}|Tail], Gift) -> 
    is_exist(Tail, Gift);
is_exist([], _) -> ?false.
%% ------------------------------------- 消费  ---------------------------------------------------
out(UserId, Cash, Sec) ->
    case player_api:check_online(UserId) of
        ?true ->
            player_api:process_send(UserId, ?MODULE, out_cb, [Cash, Sec, ?CONST_SYS_TRUE]);
        ?false ->
            player_offline_api:offline(?MODULE, UserId, [out_cb, Cash, Sec, ?CONST_SYS_FALSE])
    end.

out_cb(Player, [Cash, Sec, IsSend]) ->
    UserId      = Player#player.user_id,
    ActingGroupList = get_acting_group_list(Sec),
    Welfare     = Player#player.welfare,
    DepositList = Welfare#welfare.deposit,
    {NewDepositList, Packet} = handle_out(ActingGroupList, DepositList, Cash, <<>>),
    NewPlayer   = 
        if
            ?CONST_SYS_TRUE =:= IsSend ->
                misc_packet:send(UserId, Packet),
                Player;
            ?true ->
                OfflinePacket = Player#player.offline_packet,
                Player#player{offline_packet = <<OfflinePacket/binary, Packet/binary>>}
        end,
    NewWelfare = Welfare#welfare{deposit = NewDepositList},
    NewPlayer2 = NewPlayer#player{welfare = NewWelfare},
    {?ok, NewPlayer2}.

handle_out([#rec_welfare_deposit_time{group_id = GroupId}|Tail], DepositList, Cash, OldPacket) ->
    {NewDepositList, NewPacket} = 
        case data_welfare:get_deposit_group_out(GroupId) of
            List when is_list(List) ->
                {DepositList2, MoneyPacket} = update_amount_out(DepositList, GroupId, Cash, [], ?CONST_SYS_FALSE, <<>>),
                handle_out_2(List, DepositList2, Cash, MoneyPacket);
            _ ->
                {DepositList, <<>>}
        end,
    handle_out(Tail, NewDepositList, Cash, <<OldPacket/binary, NewPacket/binary>>);
handle_out([], DepositList, _Cash, Packet) ->
    {DepositList, Packet}.

update_amount_out([#deposit_group{group_id = GroupId, amount_out = AmountOunt} = DepGroup|Tail], GroupId, Cash, OldList, _, OldPacket) ->
    DepGroup2 = DepGroup#deposit_group{amount_out = AmountOunt + Cash},
    AmountIn  = DepGroup#deposit_group.amount_in,
    MoneyPacket = welfare_api:msg_sc_rmb(GroupId, AmountOunt + Cash, AmountIn),
    update_amount_out(Tail, GroupId, Cash, [DepGroup2|OldList], ?CONST_SYS_TRUE, <<OldPacket/binary, MoneyPacket/binary>>);
update_amount_out([#deposit_group{} = DepGroup|Tail], GroupId, Cash, OldList, IsExist, OldPacket) ->
    update_amount_out(Tail, GroupId, Cash, [DepGroup|OldList], IsExist, OldPacket);
update_amount_out([], _, _, OldList, ?CONST_SYS_TRUE, Packet) ->
    {OldList, Packet};
update_amount_out([], GroupId, Cash, OldList, ?CONST_SYS_FALSE, Packet) ->
    {[#deposit_group{group_id = GroupId, amount_in = 0, amount_out = Cash, accum_data = [], single_data = []}|OldList], Packet}.

handle_out_2([#rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_SINGLE} = RecDep|Tail], DepositList, Cash, OldPacket) ->
    {DepositList2, Packet} = handle_single_out(DepositList, RecDep, Cash),
    handle_out_2(Tail, DepositList2, Cash, <<OldPacket/binary, Packet/binary>>);
handle_out_2([#rec_welfare_deposit{type = ?CONST_WELFARE_HANDLE_TYPE_ACCUM} = RecDep|Tail], DepositList, Cash, OldPacket) ->
    {DepositList2, Packet} = handle_accum_out(DepositList, RecDep),
    handle_out_2(Tail, DepositList2, Cash, <<OldPacket/binary, Packet/binary>>);
handle_out_2([_|Tail], DepositList, Cash, OldPacket) ->
    handle_out_2(Tail, DepositList, Cash, OldPacket);
handle_out_2([], DepositList, _, OldPacket) ->
    {DepositList, OldPacket}.

%% 处理单笔充值
handle_single_out(DepositList, #rec_welfare_deposit{group_id = GroupId, money_from = MFrom, money_to = MTo} = RecDep, Cash) 
  when MFrom =< Cash andalso Cash =< MTo ->
    Gift            = record_deposit_gift(RecDep),
    SinglePacket    = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED),
    NewDepositList  = 
        case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
            {value, DepositGroup, DepositList2} ->
                SingleData      = DepositGroup#deposit_group.single_data,
                NewSingleData   = [Gift|SingleData],
                DepositGroup2   = DepositGroup#deposit_group{single_data = NewSingleData},
                [DepositGroup2|DepositList2];
            _ ->
                [record_deposit_group(GroupId, [Gift])|DepositList]
        end,
    {NewDepositList, SinglePacket};
handle_single_out(DepositList, _, _) ->
    {DepositList, <<>>}.

%% 处理累计充值
handle_accum_out(DepositList, #rec_welfare_deposit{group_id = GroupId, money_from = MFrom} = RecDep) ->
    Gift            = record_deposit_gift(RecDep),
    {NewDepositList, NewPacket}  = 
        case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
            {value, DepositGroup, DepositList2} ->
                AccumData       = DepositGroup#deposit_group.accum_data,
                AmountOut       = DepositGroup#deposit_group.amount_out,
                if
                    MFrom =< AmountOut -> % andalso AmountOut =< MTo ->
                        case is_exist(AccumData, Gift) of
                            ?true ->
                                {DepositList, <<>>};
                            ?false ->
                                AccumData2    = [Gift|AccumData],
                                DepositGroup2 = DepositGroup#deposit_group{accum_data = AccumData2},
                                AccumPacket   = welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED),
                                {[DepositGroup2|DepositList2], AccumPacket}
                        end;
                    ?true ->
                        {DepositList, <<>>}
                end;
            _ ->
                {DepositList, <<>>}
        end,
    {NewDepositList, NewPacket}.

%% ----------------------------------------------------------------------------------------

%% 领取
get_gift(Player, GiftId) ->
    UserId  = Player#player.user_id,
    Welfare = Player#player.welfare,
    DepositList = Welfare#welfare.deposit,
    case data_welfare:get_deposit_gift_info(GiftId) of
        #rec_welfare_deposit{group_id = GroupId, type = Type} ->
            Now = misc:seconds(),
            NewServSec = new_serv_api:get_serv_start_time(),
            case data_welfare:get_deposit_active_time(GroupId) of
                {new_serv, TimeLast} when NewServSec =< Now andalso Now =< TimeLast+NewServSec*86400 ->
                    case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
                        {value, DepGroup, DepositList2} ->
                            {Player2, DepGroup2} = get_gift_2(Player, GiftId, Type, DepGroup),
                            DepositList3 = [DepGroup2|DepositList2],
                            Welfare2 = Welfare#welfare{deposit = DepositList3},
                            Player2#player{welfare = Welfare2};
                        _ ->
                            PacketErr = message_api:msg_notice(?TIP_WELFARE_NOT_EXIST),
                            misc_packet:send(UserId, PacketErr),
                            Player
                    end;
                {FromSec, ToSec} when FromSec =< Now andalso Now =< ToSec andalso FromSec =/= 'new_serv' ->
                    case lists:keytake(GroupId, #deposit_group.group_id, DepositList) of
                        {value, DepGroup, DepositList2} ->
                            {Player2, DepGroup2} = get_gift_2(Player, GiftId, Type, DepGroup),
                            DepositList3 = [DepGroup2|DepositList2],
                            Welfare2 = Welfare#welfare{deposit = DepositList3},
                            Player2#player{welfare = Welfare2};
                        _ ->
                            PacketErr = message_api:msg_notice(?TIP_WELFARE_NOT_EXIST),
                            misc_packet:send(UserId, PacketErr),
                            Player
                    end;
                {_, _} ->
                    PacketErr = message_api:msg_notice(?TIP_COMMON_TIME_NOT_FIT),
                    misc_packet:send(UserId, PacketErr),
                    Player
            end;
        _ ->
            PacketErr = message_api:msg_notice(?TIP_WELFARE_NOT_EXIST),
            misc_packet:send(UserId, PacketErr),
            Player
    end.
                
get_gift_2(Player, GiftId, GiftType, DepGroup) ->
    UserId   = Player#player.user_id,
    Info     = Player#player.info,
    UserName = Info#info.user_name,
    GiftList = 
            case GiftType of
                ?CONST_WELFARE_HANDLE_TYPE_SINGLE ->
                    DepGroup#deposit_group.single_data;
                ?CONST_WELFARE_HANDLE_TYPE_ACCUM ->
                    DepGroup#deposit_group.accum_data
            end,
    {GiftListT, NonGiftListT} = flit(GiftId, GiftList, [], []),
    case lists:keytake(GiftId, #deposit_gift.gift_id, GiftListT) of
        {value, #deposit_gift{state = ?CONST_WELFARE_UNCLAIMED} = Gift, GiftListT_2} ->
            case reward(Player, GiftId) of
                {?ok, Player2, PacketBag} ->
                    NewGiftListT_2 = [Gift#deposit_gift{state = ?CONST_WELFARE_RECEIVED}|GiftListT_2]++NonGiftListT,
                    Len = erlang:length(GiftListT_2),
                    PacketT = 
                        if
                            Len > 0 ->
                                welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED);
                            ?true andalso ?CONST_WELFARE_HANDLE_TYPE_ACCUM =:= GiftType ->
                                welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_RECEIVED);
                            ?true ->
                                welfare_api:msg_sc_deposit_info(Gift#deposit_gift.acitve_id, Gift#deposit_gift.gift_id, ?CONST_WELFARE_RECEIVED)
                        end,
                    
                    NewDepGroup = 
                        case GiftType of
                            ?CONST_WELFARE_HANDLE_TYPE_SINGLE ->
                                DepGroup#deposit_group{single_data = NewGiftListT_2};
                            ?CONST_WELFARE_HANDLE_TYPE_ACCUM ->
                                DepGroup#deposit_group{accum_data = NewGiftListT_2}
                        end,
                    misc_packet:send(UserId, <<PacketBag/binary, PacketT/binary>>),
                    BroadcastPacket = message_api:msg_notice(?TIP_WELFARE_GET_DEPOSIT, [{UserId, UserName}], [], 
                                                             [{?TIP_SYS_GIFT, misc:to_list(Gift#deposit_gift.gift_id)}, 
                                                              {?TIP_SYS_OPEN_PANEL, misc:to_list("")}]),
                    misc_app:broadcast_world_2(BroadcastPacket),
                    {Player2, NewDepGroup};
                {?error, ErrorCode} ->
                    Packet = message_api:msg_notice(ErrorCode),
                    misc_packet:send(UserId, Packet),
                    {Player, DepGroup}
            end;
        _ ->
            UserId = Player#player.user_id,
            Packet = message_api:msg_notice(?TIP_WELFARE_RECEIVED),
            misc_packet:send(UserId, Packet),
            {Player, DepGroup}
    end.

flit(GiftId, [#deposit_gift{state = ?CONST_WELFARE_UNCLAIMED, gift_id = GiftId} = Gift|Tail], GiftList, NonGiftList) ->
    flit(GiftId, Tail, [Gift|GiftList], NonGiftList);
flit(GiftId, [Gift|Tail], GiftList, NonGiftList) ->
    flit(GiftId, Tail, GiftList, [Gift|NonGiftList]);
flit(_, [], GiftList, NonGiftList) ->
    {GiftList, NonGiftList}.

%% ----------------------------------------------------------------------------------------------
%% 读取活动期间的活动列表
get_acting_group_list(Sec) when is_integer(Sec) ->
    TimeList        = data_welfare:get_deposit_time_all(),
    get_acting_group_list(Sec, TimeList, []).

get_acting_group_list(Sec, [#rec_welfare_deposit_time{group_type = ?CONST_WELFARE_ATYPE_NORMAL} = RecDepTime|Tail], OldList) ->
    NewList = 
        case is_fit_normal(Sec, RecDepTime) of
            ?true ->
                [RecDepTime|OldList];
            _ ->
                OldList
        end,
    get_acting_group_list(Sec, Tail, NewList);
get_acting_group_list(Sec, [#rec_welfare_deposit_time{group_type = ?CONST_WELFARE_ATYPE_NEW_SERV} = RecDepTime|Tail], OldList) ->
    NewList = 
        case is_fit_new_serv(Sec, RecDepTime) of
            ?true ->
                [RecDepTime|OldList];
            _ ->
                OldList
        end,
    get_acting_group_list(Sec, Tail, NewList);
get_acting_group_list(Sec, [#rec_welfare_deposit_time{group_type = ?CONST_WELFARE_ATYPE_NDAY} = RecDepTime|Tail], OldList) ->
    NewList = 
        case is_fit_nday(Sec, RecDepTime) of
            ?true ->
                [RecDepTime|OldList];
            _ ->
                OldList
        end,
    get_acting_group_list(Sec, Tail, NewList);
get_acting_group_list(Sec, [_|Tail], OldList) ->
    get_acting_group_list(Sec, Tail, OldList);
get_acting_group_list(_, [], List) ->
    List.

%% 普通活动
is_fit_normal(Sec, #rec_welfare_deposit_time{time_start = StartSec, time_end = EndSec}) 
  when StartSec =< Sec andalso Sec =< EndSec -> 
    ?true;
is_fit_normal(_, _) ->
    ?false.

%% 新服活动
is_fit_new_serv(Sec, RecDepTime) -> 
    StartServSec = new_serv_api:get_serv_start_time(),
    EndSec       = RecDepTime#rec_welfare_deposit_time.time_last * ?CONST_SYS_ONE_DAY_SECONDS + StartServSec,
    StartServSec =< Sec andalso Sec =< EndSec.

%% 普通活动
is_fit_nday(Sec, #rec_welfare_deposit_time{time_start = StartSec, time_end = EndSec}) 
  when StartSec =< Sec andalso Sec =< EndSec ->
    StartServSec = new_serv_api:get_serv_start_time(),
    NewServEndSec= ?CONST_NEW_SERV_DAYS * ?CONST_SYS_ONE_DAY_SECONDS + StartServSec,
    IsNewServ    = (StartServSec =< Sec andalso Sec =< NewServEndSec),
    % if
    %     ?false =:= IsNewServ -> %% (新服活动期间，n天一次的活动不开启)
    %         ?true;
    %     ?true ->
    %         ?false
    % end;
    ?true;
is_fit_nday(_, _) ->
    ?false.
%% ------------------------------ 奖励 ----------------------------------------------------------------
%% {?ok, Player3, PacketBag}/{?error, ErrorCode}
reward(Player, GiftId) ->
    case data_welfare:get_deposit_gift_info(GiftId) of
        #rec_welfare_deposit{} = RecWelfare ->
            get_gift_reward(Player, RecWelfare, ?CONST_COST_WELFARE_GIFT);
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

get_gift_reward(Player, RecWelfare, Point) when is_record(RecWelfare, rec_welfare_deposit) ->
    UserId      = Player#player.user_id,
    case get_gift_reward_goods(Player, RecWelfare#rec_welfare_deposit.goods, Point) of
        {?ok, Player2, PacketBag} ->
            Player3 = partner_api:give_partner_list(Player2, RecWelfare#rec_welfare_deposit.partner_list, ?CONST_PARTNER_TEAM_IN, 0),
            get_gift_reward_cash(UserId, RecWelfare#rec_welfare_deposit.cash, Point),
            get_gift_reward_cash_bind(UserId, RecWelfare#rec_welfare_deposit.cash_bind, Point),
            get_gift_reward_gold(UserId, RecWelfare#rec_welfare_deposit.gold, Point),
            {?ok, Player3, PacketBag};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

get_gift_reward_goods(Player, [], _Point) -> {?ok, Player, <<>>};
get_gift_reward_goods(Player = #player{info = #info{pro = Pro, sex = Sex}}, GoodsData, Point) ->
    Fun         = fun({GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, SexTmp, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro andalso SexTmp =:= Sex ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({?CONST_SYS_PRO_NULL, SexTmp, GoodsId, Bind, Count}, AccGoods) when SexTmp =:= Sex ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     ({ProTmp, ?CONST_SYS_SEX_NULL, GoodsId, Bind, Count}, AccGoods) when ProTmp =:= Pro ->
                          GoodsTemp = goods_api:make(GoodsId, Bind, Count),
                          GoodsTemp ++ AccGoods;
                     (_, AccGoods) -> AccGoods
                  end,
    GoodsList   = lists:foldl(Fun, [], GoodsData),
    case ctn_bag_api:put(Player, GoodsList, Point, 1, 1, 0, 0, 0, 1, []) of
        {?ok, Player2, _, PacketBag} ->
            {?ok, Player2, PacketBag};
        {?error, ErrorCode} -> {?error, ErrorCode}
    end.

get_gift_reward_cash(_UserId, 0, _Point) -> ?ok;
get_gift_reward_cash(UserId, Cash, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, Point).

get_gift_reward_cash_bind(_UserId, 0, _Point) -> ?ok;
get_gift_reward_cash_bind(UserId, CashBind, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, CashBind, Point).

get_gift_reward_gold(_UserId, 0, _Point) -> ?ok;
get_gift_reward_gold(UserId, Gold, Point) ->
    player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, Point).

%% --------------------------------- ets && record ----------------------------------------------------
record_deposit_group(GroupId, SingleData) ->
    #deposit_group{group_id = GroupId, single_data = SingleData}.

record_deposit_gift(#rec_welfare_deposit{group_id = ActiveId, id = GiftId}) ->
    #deposit_gift{acitve_id = ActiveId, gift_id = GiftId, state = ?CONST_WELFARE_UNCLAIMED}.
record_deposit_gift(#rec_welfare_deposit{group_id = ActiveId, id = GiftId}, State) ->
    #deposit_gift{acitve_id = ActiveId, gift_id = GiftId, state = State}.

%% --------------------------------- packet ----------------------------------------------------
%% 上线
login_packet(Player) ->
    Warefare    = Player#player.welfare,
    Deposit     = Warefare#welfare.deposit,
    Sec         = new_serv_api:get_serv_start_time(),
    Packet      = welfare_api:msg_sc_end_time(Sec),
    packet_group(Deposit, Packet).

packet_group([#deposit_group{single_data = SingleData, accum_data = AccumData, 
                             amount_in = AmountIn, amount_out = AmountOut, group_id = GroupId}|Tail], OldPacket) ->
    Packet = packet_gift(SingleData, SingleData, OldPacket),
    Packet2 = packet_gift(AccumData, AccumData, Packet),
    MoneyPacket = welfare_api:msg_sc_rmb(GroupId, AmountOut, AmountIn),
    packet_group(Tail, <<OldPacket/binary, Packet2/binary, MoneyPacket/binary>>);
packet_group([], Packet) ->
    Packet.

packet_gift([DGift|Tail], Deposit, Packet) ->
    {GiftList, _NonGiftList} = flit(DGift#deposit_gift.gift_id, Deposit, [], []),
    Len = erlang:length(GiftList),
    RecWelfareDeposit = data_welfare:get_deposit_gift_info(DGift#deposit_gift.gift_id),
    PacketT = 
        if
            Len > 0 ->
                welfare_api:msg_sc_deposit_info(DGift#deposit_gift.acitve_id, DGift#deposit_gift.gift_id, ?CONST_WELFARE_UNCLAIMED);
            ?true andalso ?CONST_WELFARE_HANDLE_TYPE_ACCUM =:= RecWelfareDeposit#rec_welfare_deposit.type ->
                welfare_api:msg_sc_deposit_info(DGift#deposit_gift.acitve_id, DGift#deposit_gift.gift_id, ?CONST_WELFARE_RECEIVED);
            ?true ->
                welfare_api:msg_sc_deposit_info(DGift#deposit_gift.acitve_id, DGift#deposit_gift.gift_id, ?CONST_WELFARE_RECEIVED)
        end,
    packet_gift(Tail, Deposit, <<Packet/binary, PacketT/binary>>);
packet_gift([], _, Packet) -> Packet.

%%------------------------------------------------------------------------------------------

%% sum_goods([#goods{goods_id = Id, count = Count} = Goods|Tail], OldList) ->
%%     case lists:keytake(Id, #goods.goods_id, OldList) of
%%         {value, G, OldList2} ->
%%             sum_goods(Tail, [G#goods{count = Count+G#goods.count}|OldList2]);
%%         _ ->
%%             sum_goods(Tail, [Goods|OldList])
%%     end;
%% sum_goods([], List) ->
%%     List.
        