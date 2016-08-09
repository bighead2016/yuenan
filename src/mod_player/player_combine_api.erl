%%% 合服通用
-module(player_combine_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.tip.hrl").

-include("record.data.hrl").
-include("record.player.hrl").
-include("record.guild.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([do/0, initial_ets/0, is_changed/1, change/1, change_guild/1, change_guild_name/2,
         change_guild_reset/1, change_reset/1, login_packet/1, broadcast_change_guild_name_cb/2]).

%%
%% API Functions
%%
login_packet(Player) ->
    UserId = Player#player.user_id,
    Guild  = Player#player.guild,
    GuilId = Guild#guild.guild_id,
    Pos = Guild#guild.guild_pos,
    IsChangeUser = 
        case is_changed(UserId) of
            ?CONST_SYS_FALSE ->
                1;
            _ ->
                0
        end,
    IsChangeGuild = 
        case is_changed_guild(GuilId) of
            ?CONST_SYS_FALSE when Pos =:= ?CONST_GUILD_POSITION_CHIEF ->
                1;
            _ ->
                0
        end,
    Packet = player_api:msg_sc_change_name_flags(IsChangeUser,IsChangeGuild),
    Packet.

initial_ets() ->
    case mysql_api:select(<<"select `user_id`, `is_changed` from `game_change_name`;">>) of
        {?ok, [?undefined]} -> ?ok;
        {?ok, DataList} ->
            Fun = fun([UserId, IsChanged], X) ->
                          ets_api:insert(?CONST_ETS_CHANGED_NAME, {UserId, IsChanged}),
                          X
            end,
            lists:foldl(Fun, 0, DataList);
        _ ->
           ?ok
    end,
    case mysql_api:select(<<"select `guild_id`, `is_changed` from `game_change_name_guild`;">>) of
        {?ok, [?undefined]} -> ok;
        {?ok, DataList2} ->
            Fun2 = fun([GuildId, IsChanged2], X2) ->
                          ets_api:insert(?CONST_ETS_CHANGED_NAME_GUILD, {GuildId, IsChanged2}),
                          X2
            end,
            lists:foldl(Fun2, 0, DataList2);
        _ ->
           ?ok
    end.

do() ->
    try
        Sid       = config:read(server_info, #rec_server_info.serv_id),
        CombineId = config:read(server_info, #rec_server_info.combined),
        if
            Sid =/= CombineId ->
                IsRewarded = 
                    case mysql_api:select(<<"select `combine_reward` from `game_config`;">>) of
                        {?ok, [[1]]} ->
                            1;
                        _ ->
                            0
                    end,
                if
                    ?CONST_SYS_FALSE =:= IsRewarded ->
                        reward_all();
                    ?true ->
%%                         misc_killer:do_kill(),
                        ?ok
                end;
            ?true ->
%%                 misc_killer:do_kill(),
                ?ok
        end
    catch
        X:Y ->
            ?MSG_SYS("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
            throw({?error, 1})
    end.

reward_all() ->
    TotalCount = 
            case mysql_api:select(<<"select count(`user_id`) from `game_user`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_name`, `lv`, `serv_id` from `game_user`;">>) of
                {?ok, [?undefined]} -> ok;
                {?ok, DataList} ->
                    Fun = fun([UserName, Lv, _ServId], OldCount) ->
%%                                   BaseRewardId = 
%%                                       case lists:member(ServId, ServList) of
%%                                           ?true ->
%%                                               BaseReward;
%%                                           ?false ->
%%                                               0
%%                                       end,
%%                                   case data_player:get_combine(Lv) of
%%                                       #combine_reward{bgold = BGoldBase, cash = CashBase, bcash = BCashBase, goods = GoodsListBase, mail_title = Title, mail_content = Content} ->
                                          case data_player:get_combine(Lv) of
                                              #combine_reward{bgold = FinalBGold, cash = FinalCash, bcash = FinalBCash, goods = GoodsList, mail_title = Title, mail_content = Content} ->
                                                    FinalGoodsList = make_goods(GoodsList, []),
                                                    send_mail(UserName, Title, Content, FinalGoodsList, FinalBGold, FinalCash, FinalBCash),
                                                    OldCount+1;
                                               _ ->
                                                   ?MSG_SYS("!err:no[~p]", [Lv]),
                                                   OldCount
%%                                           end;
%%                                       _ ->
%%                                           ?MSG_SYS("!err:no[~p]", [Lv]),
%%                                           OldCount
                                        end
                          end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                _ ->
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_market_buy` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_market_buy` count=0")
    end,
    ok.

%% 改名了没?
is_changed(UserId) ->
    case ets_api:lookup(?CONST_ETS_CHANGED_NAME, UserId) of
        {_, 1} ->
            ?CONST_SYS_TRUE;
        {_, 0} ->
            ?CONST_SYS_FALSE;
        _ ->
            ?null
    end.

%% 改名了没?
is_changed_guild(UserId) ->
    case ets_api:lookup(?CONST_ETS_CHANGED_NAME_GUILD, UserId) of
        {_, 1} ->
            ?CONST_SYS_TRUE;
        {_, 0} ->
            ?CONST_SYS_FALSE;
        _ ->
            ?null
    end.

%% 改
change(UserId) ->
    ets_api:update_element(?CONST_ETS_CHANGED_NAME, UserId, [{2, 1}]),
    mysql_api:select(<<"update `game_change_name` set `is_changed` = '1' where `user_id` = '",
                       (misc:to_binary(UserId))/binary, "';">>).

change_guild(GuildId) ->
    ets_api:update_element(?CONST_ETS_CHANGED_NAME_GUILD, GuildId, [{2, 1}]),
    mysql_api:select(<<"update `game_change_name_guild` set `is_changed` = '1' where `guild_id` = '",
                       (misc:to_binary(GuildId))/binary, "';">>).

change_guild_reset(GuildId) ->
    ets_api:update_element(?CONST_ETS_CHANGED_NAME_GUILD, GuildId, [{2, 0}]),
    mysql_api:select(<<"update `game_change_name_guild` set `is_changed` = '0' where `guild_id` = '",
                       (misc:to_binary(GuildId))/binary, "';">>).

change_reset(UserId) ->
    ets_api:update_element(?CONST_ETS_CHANGED_NAME, UserId, [{2, 0}]),
    mysql_api:select(<<"update `game_change_name` set `is_changed` = '0' where `user_id` = '",
                       (misc:to_binary(UserId))/binary, "';">>).

%% 改军团名
change_guild_name(Player, NewGuildName) ->
    UserId = Player#player.user_id,
    GuildDataT = Player#player.guild,
    GuildId = GuildDataT#guild.guild_id,
    Pos = GuildDataT#guild.guild_pos,
    case guild_api:ets_guild_data(GuildId) of
        ?null -> 
            Packet = message_api:msg_notice(?TIP_GUILD_DISBAND),
            misc_packet:send(UserId, Packet),
            Player;
        #guild_data{chief_id = UserId} = GuildData -> 
            case is_changed_guild(GuildId) of
                ?CONST_SYS_FALSE ->
                    case guild_api:check_name_use(NewGuildName) of
                        ?ok ->
                            ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId, [{#guild_data.guild_name, NewGuildName}]),
                            guild_db_mod:update_data(GuildData#guild_data{guild_name = NewGuildName}),
                            broadcast_change_guild_name(GuildId, NewGuildName),
                            NewPlayer = Player#player{guild = GuildDataT#guild{guild_name = NewGuildName}},
                            map_api:change_guild(NewPlayer),
                            change_guild(GuildId),
                            Packet = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_OK),
                            IsChangeUser = 
                                case is_changed(UserId) of
                                    ?CONST_SYS_FALSE ->
                                        1;
                                    _ ->
                                        0
                                end,
                            IsChangeGuild = 
                                case is_changed_guild(GuildId) of
                                    ?CONST_SYS_FALSE when Pos =:= ?CONST_GUILD_POSITION_CHIEF ->
                                        1;
                                    _ ->
                                        0
                                end,
                            PacketOk = player_api:msg_sc_change_name_flags(IsChangeUser,IsChangeGuild),
                            misc_packet:send(UserId, <<PacketOk/binary, Packet/binary>>),
                            NewPlayer;
                        {?error, ErrorCode} ->
                            MsgPacket = message_api:msg_notice(ErrorCode),
                            misc_packet:send(UserId, MsgPacket),
                            Player
                    end;
                ?CONST_SYS_TRUE ->
                    MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_ED),
                    misc_packet:send(UserId, MsgPacket),
                    Player;
                _ ->
                    MsgPacket = message_api:msg_notice(?TIP_PLAYER_CHANGED_NAME_ERR),
                    misc_packet:send(UserId, MsgPacket),
                    Player
            end;
        _ ->
            Packet = message_api:msg_notice(?TIP_GUILD_NOT_CHIEF),
            misc_packet:send(UserId, Packet),
            Player
    end.

broadcast_change_guild_name(GuildId, NewGuildName) ->
    MemberList = guild_api:get_guild_members(GuildId),
    broadcast_change_guild_name_2(MemberList, NewGuildName).

broadcast_change_guild_name_2([{UserId, _, _}|Tail], NewGuildName) ->
    case player_api:check_online(UserId) of
        ?true ->
            player_api:process_send(UserId, ?MODULE, broadcast_change_guild_name_cb, NewGuildName);
        ?false ->
            ?ok
    end,
    broadcast_change_guild_name_2(Tail, NewGuildName);
broadcast_change_guild_name_2([], _) ->
    ?ok.

broadcast_change_guild_name_cb(Player, NewGuildName) ->
    Guild = Player#player.guild,
    NewPlayer = Player#player{guild = Guild#guild{guild_name = NewGuildName}},
    map_api:change_guild(NewPlayer),    
    {?ok, NewPlayer}.

%%
%% Local Functions
%%
%% reward_all_2([Id|Tail], NameList) ->
%%     case data_player:get_combine(Id) of
%%         #combine_reward{bgold = BGold, cash = Cash, bcash = BCash, goods = GoodsList, mail_title = Title, mail_content = Content} ->
%%             GoodsList2 = make_goods(GoodsList, []),
%%             [send_mail(UserName, Title, Content, GoodsList2, BGold, Cash, BCash)||UserName<-NameList],
%%             ok;
%%         _ ->
%%             ok
%%     end,
%%     reward_all_2(Tail, NameList);
%% reward_all_2([], _) ->
%%     ok.


send_mail(UserName, Title, Content, GoodsList, BGold, Cash, BCash) ->
    mail_api:send_system_mail_to_one2(UserName, Title, Content, 0, [], GoodsList, BGold, Cash, BCash, ?CONST_COST_PLAYER_COMBINE_GIVE).

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
    
