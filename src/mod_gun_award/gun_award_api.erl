%% Author: PXR
%% Created: 2014-1-20
%% Description: TODO: Add description to gun_award_api
-module(gun_award_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").

%%
%% Exported Functions
%%
-export([msg_info/3, login_check/1, add_gun_award/2, check_level_up/1, check_active/2, get_and_up_gun_active/2, get_gun_award/1, zero_refresh/1]).

%%
%% API Functions
%%
get_total_cash(Local) ->
    LastTime = Local#ets_gun_cash_local.last_up_time,
    Now = misc:seconds(),
    case misc:is_same_date(LastTime, Now) of
        false ->
            0;
        _ ->
            Local#ets_gun_cash_local.today_cash
    end.

get_and_up_gun_active(UserId, ActiveId) ->
    Now = misc:seconds(),
    case ets:lookup(?CONST_ETS_GUN_AWARD_EVERYDAY, UserId) of
        [] ->
            ets:insert(?CONST_ETS_GUN_AWARD_EVERYDAY,
                        #ets_gun_award_everyday{user_id = UserId, active_list = [ActiveId], update_time = Now}),
            true;
        [Rec] ->
            Last = Rec#ets_gun_award_everyday.update_time,
            case misc:is_same_date(Now, Last) of
                false ->
                    ets:insert(?CONST_ETS_GUN_AWARD_EVERYDAY,
                                #ets_gun_award_everyday{user_id = UserId, active_list = [ActiveId], update_time = Now}),
                    true;
                _ ->
                    ActiveList = Rec#ets_gun_award_everyday.active_list,
                    case lists:member(ActiveId, ActiveList) of
                        false ->
                            NewActiveList = [ActiveId|ActiveList],
                            ets:update_element(?CONST_ETS_GUN_AWARD_EVERYDAY, UserId, 
                                               [{#ets_gun_award_everyday.active_list, NewActiveList},
                                                {#ets_gun_award_everyday.update_time, Now}]),
                            true;
                        _ ->
                            false
                    end
            end
    end.

check_active(UserId, ActiveId) ->
    case lists:member(ActiveId, [1,3,5,7,11,12]) of
        false ->ok;
        _ ->
            Count = 1,
            case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, UserId) of
                [] ->
                    ok;
                [GunRec] ->
                    case GunRec#ets_gun_cash_local.state of
                        ?CONST_GUN_CASH_ADD_SERVER ->
                            case get_and_up_gun_active(UserId, ActiveId) of
                                false ->
                                    ok;
                                _ ->
                                    add_gun_award(UserId, Count)
                            end;
                        _ ->
                            ok
                    end
            end
    end.     

check_level_up(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Level = Info#info.lv,
    case data_gun_award:get_gun_level_award(Level) of
        null ->ok;
        #rec_gun_cash_level{award = Count} ->
            case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, UserId) of
                [] ->
                    ok;
                [GunRec] ->
                    case GunRec#ets_gun_cash_local.state of
                        ?CONST_GUN_CASH_ADD_SERVER ->
                           add_gun_award(UserId, Count);
                        _ ->
                            ok
                    end
            end
    end.
                    

zero_refresh(Player) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, UserId) of
        [] ->
            ok;
        [Local] ->
            State = Local#ets_gun_cash_local.state,
            TodayCash = 0,
            TotalCash = Local#ets_gun_cash_local.total_cash,
            case State of
                ?CONST_GUN_CASH_ADD_SERVER ->
                    Packet = msg_info(State, TotalCash, TodayCash),
                    misc_packet:send(UserId, Packet);
                _ ->
                    ok
            end
    end.

login_check(Player) when is_record(Player, player)->
    UserId = Player#player.user_id,
    case check_register_time(Player) of
        false ->
            Packet = msg_info(?CONST_GUN_CASH_OTHER_SERVER, 0, 0),
            misc_packet:send(Player#player.user_id, Packet);
        _ ->
            case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, UserId) of
                [] ->
                    CenterNode = center_api:get_center_node(),
                    NodeFrom = node(),
                    Index = Player#player.serv_id,
                    rpc:cast(CenterNode, gun_award_serv, login_check, [Player#player.user_id, Player#player.account, NodeFrom, Index]);
                [Local] ->
                    State = Local#ets_gun_cash_local.state,
                    TodayCash = get_total_cash(Local),
                    TotalCash = Local#ets_gun_cash_local.total_cash,
                    Packet = msg_info(State, TotalCash, TodayCash),
                    misc_packet:send(UserId, Packet)
            end
    end.

check_register_time(Player) ->
    UserId = Player#player.user_id,
    case mysql_api:select([reg_time], game_user, [{user_id, UserId}]) of
        {ok,[[RegTime]]} ->
            RegTime > 1393174861;
        _ ->
            false
    end.

add_gun_award(UserId, Count) ->
    CenterNode = center_api:get_center_node(),
    case player_api:get_player_field(UserId, #player.serv_id) of
        {ok ,Index} when Index > 0 ->
            {ok, Account} = player_api:get_player_field(UserId, #player.account),
            case ets:lookup(?CONST_ETS_GUN_CASH_LOCAL, UserId) of
                [] ->
                    ok;
                [#ets_gun_cash_local{state = ?CONST_GUN_CASH_ADD_SERVER} = Local] ->
                    NewTotal = Local#ets_gun_cash_local.total_cash + Count,
                    NewToday = get_total_cash(Local) + Count,
                    ets:update_element(?CONST_ETS_GUN_CASH_LOCAL, UserId, 
                                       [{#ets_gun_cash_local.today_cash, NewToday},
                                        {#ets_gun_cash_local.total_cash, NewTotal},
                                        {#ets_gun_cash_local.last_up_time, misc:seconds()}]),
                    Packet = msg_info(?CONST_GUN_CASH_ADD_SERVER, NewTotal, NewToday),
                    misc_packet:send(UserId, Packet)
            end,
            rpc:cast(CenterNode, gun_award_serv, add_gun_award, [UserId, Account, Index, node(), Count]);
        _ ->
            ok
    end.

get_gun_award(Player) ->
    CenterNode = center_api:get_center_node(),
    NodeFrom = node(),
    Index = Index = Player#player.serv_id,
    rpc:cast(CenterNode, gun_award_serv, get_gun_award, [Player#player.user_id, Player#player.account, NodeFrom, Index]).
%% 滚服信息
%%[GunState,TotalCash,TodayCash]
msg_info(GunState,TotalCash,TodayCash) ->
    misc_packet:pack(?MSG_ID_GUN_CASH_INFO, ?MSG_FORMAT_GUN_CASH_INFO, [GunState,TotalCash,TodayCash]).

%%
%% Local Functions
%%

