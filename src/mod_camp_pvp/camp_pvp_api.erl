%% Author: PXR
%% Created: 2013-7-8
%% Description: TODO: Add description to camp_pvp_api
-module(camp_pvp_api).

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


-export([on/1, off/1]).
-export([mining/2,              %采集 
         get_box/2,
         open_box_end/2,
         get_index_count/2,
         send_award/2,
         submit_resource/1,     % 提交资源 
         camp_info_4_client/2,
         send_award_cross/2,
         start_battle/3,        % 发起pvp
         check_state/1,
         enter_camp_map/1,      % 进入阵营战玩法
         exit_camp/1,           % 前端请求退出阵营战玩法
         camp_pvp_interval/0,   % 心跳
         battle_over/2,         % 战斗结束结算
         refresh_monster/3,     % 每次出手刷新boss血量
         check_player_battle/2, % 检查是否可以开始战斗，给战斗模块回调用的
         exit_camp_pvp_map/1,   % 退出交战区地图， 设置状态编程广播部可见
         exit_camp_pvp_map1/1,
         player_logout/1,       % 玩家掉线
         player_logout1/1,
         give_up_mining/1,      % 放弃采矿
         try_join_team/2,
         reply_team/3,
         get_pk_cd_left/2,
         leave_team/2,
         get_camp_id_random/1,
         leave_team/1,
         msg_response_score/1,
         msg_cash_active_start/0,msg_refresh_cash/2,msg_open_cash_result/1,
         msg_team_over/0,
         set_resource/2,        % 设置资源， gm命令
         login_packet/2,        % 登录 补充自行的奖励发放
         map_init_finish/2,     % 跳地图前端场景初始化完成，请求后端发送怪物、玩家等信息
         broad_rank/1,          % 广播排行榜
         player_state_change/1, % 前端请求改变自己的状态  死亡 -> 正常 、 采集中 -> 运送， 
         get_reward_hurt/3,     % 得到伤害的奖励
         encourage/1,           % 请求鼓舞
         give_up_att_car/1,
         get_boss_state/1,
         camp_info_4_client/1   % 返回阵营战当前战况： 两边阵营人数，积分，资源， buf ，介绍等信息
        ]).  

-export([msg_sc_enter/1, 
         msg_sc_rank/12,
         msg_call_monster/0,  
         msg_sc_dig_success/2,
         msg_hurt_all_boss/2,
         msg_sc_start/0,
         msg_sc_end/14,
         msg_add_monster/6,
         msg_monster_move/4,
         msg_monster_killed/1,
         msg_monster_attack/1,
         msg_buff_miss/5,
         msg_remove_cash_box/1,
         msg_player_state_list/1,
         msg_sc_monster_info/1,
         msg_is_battle_start/1,
         msg_monster_stop/1,
         msg_hp_change/1,
         msg_player_state/2,
         msg_broad_team_info/2,
         msg_att_car_success/0,
         msg_ecourage_success/1,
         get_room_pid/4,
         create_map/3,
         get_camp_born_point/1,
         buy_item/3,
         broad_camp/3,
         broad_camp_cp/2,
         create_team/1,
         join_team/2,
         broad_team/2,
         invite/2,
         msg_box_left/1,
         kick/2,
         msg_sc_camp_info/4]).

-define(RANK_BROAD_INTERVAL, 5). % 广播排行榜间隔


%%
%% API Functions
%%

%% 可开启宝箱数量
%%[Count]
msg_box_left(Count) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_BOX_LEFT, ?MSG_FORMAT_CAMP_PVP_BOX_LEFT, [Count]).

kick(_Player, UserId) ->
    misc_packet:send_tips(UserId, ?TIP_TEAM_LEADER_REMOVE),
    PlayerPid = player_api:get_player_pid(UserId), 
    player_api:process_send(PlayerPid, ?MODULE, leave_team, []).

update_team_info_broad(MemList, LeaderId) ->
    Fun = 
        fun(Member) ->
                ?MSG_ERROR("Member is ~w", [Member]),
            {Member#camp_team_member.user_id,
             Member#camp_team_member.name,
             Member#camp_team_member.career,
             Member#camp_team_member.sex,
             Member#camp_team_member.lv,
             Member#camp_team_member.weapon,
             Member#camp_team_member.choth,
             Member#camp_team_member.attr_type,
             Member#camp_team_member.attr_value,
             Member#camp_team_member.fashion
             }
        end,
    FormatList = lists:map(Fun, MemList),
    Packet = msg_broad_team_info(FormatList, LeaderId),
    broad_team(MemList, Packet).

broad_team(MemList, Packet) ->
    Fun =
        fun(Member) ->
                UserId = Member#camp_team_member.user_id,
                case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
                    [] ->
                        misc_packet:send(UserId, Packet);
                    _ ->
                        ok
                end
        end,
    lists:foreach(Fun, MemList).

delete_team(MemList) ->
    Fun =
        fun(Member) ->
                UserId = Member#camp_team_member.user_id,
                ets:delete(?CONST_ETS_CAMP_TEAM_INDEX, UserId)
        end,
    lists:foreach(Fun, MemList).

leave_team(Player, []) ->
    case leave_team(Player) of
        {ok, Player2} ->
            {ok, Player2};
        _ ->
            {ok, Player}
    end.

open_box_end(Player, BoxId) when is_record(Player, player)->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, open_box_end, [UserId, BoxId]);
open_box_end(UserId, BoxId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [#camp_pvp_player{cash_count = Count, room_id = RoomId}] ->
            case Count >= 5 of
                true ->
                    Packet = message_api:msg_notice(?TIP_CAMP_PVP_BOX_FULL),
                    misc_packet:send_cross(UserId, Packet);
                false ->
                    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, RoomId) of
                        [] ->
                            ok;
                        [#camp_room{box_list = BoxList}] ->
                            case lists:keyfind(BoxId, #camp_pvp_cash_list.id, BoxList) of
                                false ->
                                    ok;
                                CashRec ->
                                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.cash_count, Count + 1}),
                                    send_award_cross(UserId, CashRec#camp_pvp_cash_list.type),
                                    Msg = camp_pvp_serv:get_room_msg(RoomId),
                                    case Msg == <<>> of
                                        true ->ok;
                                        _ ->
                                            camp_pvp_mod:broad(Msg, RoomId)
                                    end
                            end
                    end
            end
    end.
                    
send_award_cross(UserId, Type) ->
    camp_pvp_mod:cross_cast(UserId, ?MODULE, send_award, [UserId, Type]).

send_award(UserId, Type) ->
    CashCount = 
        case Type of
            ?CONST_CAMP_PVP_CASH_TYPE_IRON ->
                misc:rand(1, 5);
            ?CONST_CAMP_PVP_CASH_TYPE_COPPER ->
                misc:rand(6, 10);
            ?CONST_CAMP_PVP_CASH_TYPE_SILVER ->
                misc:rand(11, 15);
            _ ->
                misc:rand(16, 20)
        end,
    player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, CashCount, ?CONST_COST_CAMP_PVP_AWARD),
    PacketSuccess  = message_api:msg_notice(?TIP_CAMP_PVP_BOX_AWARD,
                                 [{?TIP_SYS_COMM, misc:to_list(CashCount)}]),
    misc_packet:send(UserId, PacketSuccess).
    
    

get_box(Player, BoxId) when is_record(Player, player)->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    camp_pvp_mod:cross_cast(UserId, Lv, camp_pvp_serv, get_box, [UserId, BoxId]).


leave_team(Player) ->
    UserId = Player#player.user_id,
    ?MSG_ERROR("user ~w leave team", [ UserId]),
    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
        [] ->
            ?MSG_ERROR("user ~w not in team ", [UserId]),
            ok;
        [TeamIndex] ->
            ets:delete(?CONST_ETS_CAMP_TEAM_INDEX, UserId),
            LeaderId = TeamIndex#camp_team_index.leader_id,
            case ets:lookup(?CONST_ETS_CAMP_TEAM_LIST, LeaderId) of
                [] ->
                    ?MSG_ERROR("User ~w leave team , but can not find his leader ~w", [UserId, LeaderId]),
                    ok;
                [Team] ->
                     MemList = Team#camp_team_list.id_list,
                     case LeaderId == UserId of
                         true ->
                             delete_team(MemList),
                             ets:delete(?CONST_ETS_CAMP_TEAM_LIST, LeaderId),
                             set_team_state(MemList),
                             Packet = msg_team_over(),
                             broad_team(MemList, Packet);
                         _ ->
                             NewMemList = lists:keydelete(UserId, #camp_team_member.user_id, MemList),
                             ?MSG_ERROR("NewMemList is ~w", [NewMemList]),
                             ets:update_element(?CONST_ETS_CAMP_TEAM_LIST, LeaderId, {#camp_team_list.id_list, NewMemList}),
                             PacketLeave = msg_team_over(),
                             misc_packet:send(UserId, PacketLeave),
                             update_team_info_broad(NewMemList, LeaderId)
                     end
            end
    end,
    case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
        {?true, Player2} ->
            {ok, Player2};
        _ ->
            ok
    end.

set_team_state(MemList) ->
    Fun =
        fun(Mem) ->
                UserId = Mem#camp_team_member.user_id,
                PlayerPid = player_api:get_player_pid(UserId),
                player_api:process_send(PlayerPid, player_state_api, try_set_state_play, ?CONST_PLAYER_PLAY_CITY)
        end,
    lists:foreach(Fun, MemList).


get_pro_type(?CONST_SYS_PRO_XZ) -> ?CONST_PLAYER_ATTR_HP_MAX;           % 陷阵加hp_max
get_pro_type(?CONST_SYS_PRO_FJ) -> ?CONST_PLAYER_ATTR_FORCE_ATTACK;     % 飞军加物攻
get_pro_type(?CONST_SYS_PRO_TJ) -> ?CONST_PLAYER_ATTR_MAGIC_ATTACK.     % 天机加法攻

get_team_player(Player) ->
    Info = Player#player.info,
    UserId = Player#player.user_id,
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    ARMOR = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
    Attrs = Player#player.attr,
    Type = get_pro_type(Info#info.pro),
    ?MSG_ERROR("ARMOR is ~w, SkinFashion is ~w", [ARMOR, SkinFashion]),
    Value        = player_attr_api:attr_multi_single(Attrs, Type, 200, 
                                                                    ?CONST_SYS_NUMBER_TEN_THOUSAND),
   #camp_team_member{
                            attr_type = Type,
                            attr_value = Value,
                            weapon = SkinWeapon,
                            choth = ARMOR,
                            fashion = SkinFashion,
                            lv = Info#info.lv,
                            user_id = UserId,
                            sex = Info#info.sex,
                            name = Info#info.user_name,
                            career = Info#info.pro
                            }.

create_team(Player) ->
   case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAYER_CAMP_PVP) of
        {?true, Player2} ->
            UserId = Player#player.user_id,
            case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
                [_Rec] ->
                    misc_packet:send_tips(UserId, ?TIP_TEAM_ALREADY_IN_TEAM);
                _ ->
                    ets:insert(?CONST_ETS_CAMP_TEAM_INDEX, #camp_team_index{user_id = UserId, leader_id = UserId}),
                    Mem = get_team_player(Player),
                    MemList = [Mem],
                    ets:insert(?CONST_ETS_CAMP_TEAM_LIST, #camp_team_list{leader_id = UserId, id_list = MemList}),
                    update_team_info_broad(MemList, UserId)
            end,
            {ok , Player2};
       {?false, Player2, _Tips} ->
            Player2
    end.


try_join_team(Player, {TeamId, Mem}) ->
    case ets:lookup(?CONST_ETS_CAMP_TEAM_LIST, TeamId) of
        [] ->
            Reply = ?TIP_TEAM_ALREADY_START;
        [Team] ->
            MemList = Team#camp_team_list.id_list,
            case length(MemList) of
                3 ->
                    Reply = ?TIP_TEAM_ALREADY_START;
                _ ->
                    NewMemList = [Mem|MemList],
                    ?MSG_ERROR("broad ~w", [NewMemList]),
                    ets:update_element(?CONST_ETS_CAMP_TEAM_LIST, TeamId, {#camp_team_list.id_list, NewMemList}),
                    update_team_info_broad(NewMemList, TeamId),
                    Reply = ok
            end
    end,
    {?ok, Reply, Player}.

check_state(UserId) ->
    case player_api:check_online(UserId) of
        false ->
            false;
        _ ->
            ets:lookup(?CONST_ETS_CROSS_OUT, UserId) == []
    end.

clear_invited(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ok;
        [Rec] ->
            InvitedList = Rec#camp_pvp_invite.invited_list,
            Fun =
                fun(Id) ->
                        sub_invite_list(Id, UserId)
                end,
            lists:foreach(Fun, InvitedList)
    end.
    

get_invite_list(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ets:insert(?CONST_ETS_CAMP_PVP_INVITE, #camp_pvp_invite{user_id = UserId, invite_list = [], invited_list = []}),
            [];
        [Rec] ->
            Rec#camp_pvp_invite.invite_list
    end.


sub_invited_list(UserId, InviteId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ok;
        [Rec] ->
            InvitedList = Rec#camp_pvp_invite.invited_list,
            NewInviteList = InvitedList -- [InviteId],
            ets:update_element(?CONST_ETS_CAMP_PVP_INVITE, UserId, {#camp_pvp_invite.invited_list, NewInviteList})
    end.

sub_invite_list(UserId, InviteId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ok;
        [Rec] ->
            InviteList = Rec#camp_pvp_invite.invite_list,
            NewInviteList = InviteList -- [InviteId],
            ets:update_element(?CONST_ETS_CAMP_PVP_INVITE, UserId, {#camp_pvp_invite.invite_list, NewInviteList})
    end.

add_invite_list(UserId, InviteId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ets:insert(?CONST_ETS_CAMP_PVP_INVITE, #camp_pvp_invite{user_id = UserId, invite_list = [InviteId], invited_list = []});
        [Rec] ->
            InviteList = Rec#camp_pvp_invite.invite_list,
            ets:update_element(?CONST_ETS_CAMP_PVP_INVITE, UserId, {#camp_pvp_invite.invite_list, [InviteId|InviteList]})
    end.

add_invited_list(UserId, InvitedId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_INVITE, UserId) of
        [] ->
            ets:insert(?CONST_ETS_CAMP_PVP_INVITE, #camp_pvp_invite{user_id = UserId, invite_list = [], invited_list = [InvitedId]});
        [Rec] ->
            InvitedList = Rec#camp_pvp_invite.invited_list,
            ets:update_element(?CONST_ETS_CAMP_PVP_INVITE, UserId, {#camp_pvp_invite.invited_list, [InvitedId|InvitedList]})
    end.
            

check_invite(InviteId, InvitedId) ->
    List = get_invite_list(InviteId),
    case lists:member(InvitedId, List) of
        true ->
            false;
        _ ->
            add_invite_list(InviteId, InvitedId),
            add_invited_list(InvitedId, InviteId),
            true
    end.
            

invite(Player, UserId2) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
        [] ->
            ok;
        _ ->
            case ets:lookup(?CONST_ETS_CAMP_TEAM_LIST, UserId) of
                [Team] ->
                    case length(Team#camp_team_list.id_list) >= 3 of
                        true ->
                            ok;
                        _ ->
                            case check_team_level(Info#info.lv, UserId2) of
                                false ->
                                    misc_packet:send_tips(UserId, ?TIP_CAMP_PVP_LEVEL_ERR);
                                _ ->
                                    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId2) of
                                        [_] ->
                                            misc_packet:send_tips(UserId, ?TIP_TEAM_ALREADY_IN_TEAM);
                                        _ ->
                                            case check_state(UserId2) of
                                                false ->
                                                    misc_packet:send_tips(UserId, ?TIP_CAMP_PVP_IN_CAMP);
                                                _ ->
                                                    case check_invite(UserId, UserId2) of
                                                        true ->
                                                            Packet18520 = team_api:msg_sc_invite_notice(?CONST_TEAM_TYPE_CAMP_PVP, UserId, UserId,
                                                                               Info#info.user_name, Info#info.lv, Info#info.power, player_api:get_vip_lv(Info)),
                                                            misc_packet:send(UserId2, Packet18520),
                                                            misc_packet:send_tips(UserId, ?TIP_TEAM_INVITE_SUCCESS);
                                                        _ ->
                                                            misc_packet:send_tips(UserId, ?TIP_TEAM_REPEAT_INVITE)
                                                    end
                                            end
                                    end
                            end
                    end
            end
    end.
                                           
find_lv_tuple(_Lv, []) ->
    {};
find_lv_tuple(Lv, [LvTuple|RestLvList]) ->
    {LvMin, LvMax} = LvTuple,
    case Lv >= LvMin andalso Lv =< LvMax of
        true ->
            LvTuple;
        _ ->
            find_lv_tuple(Lv, RestLvList)
    end.
check_team_level(Lv1, UserId2) ->
    Lv2 = player_api:get_level(UserId2),
    LvList = [{0,34},{35,42},{43,49},{50,59},{60,100}],
    LvTuple1 = find_lv_tuple(Lv1, LvList),
    LvTuple2 = find_lv_tuple(Lv2, LvList),
    LvTuple1 == LvTuple2.

                                    

reply_team(Player, TeamId, Decide) ->
    sub_invite_list(TeamId, Player#player.user_id),
    sub_invited_list(Player#player.user_id, TeamId),
    case Decide of
        ?CONST_TEAM_REPLY_AGREE ->
            join_team(Player, TeamId);
        _ ->
            UserList = [{Player#player.user_id, (Player#player.info)#info.user_name}],
            Packet      = message_api:msg_notice(?TIP_TEAM_REPLY_REJECT_NOTICE, UserList, [], []),
            misc_packet:send(TeamId, Packet)
    end.

join_team(Player, TeamId) ->
   case ets:lookup(?CONST_ETS_CROSS_OUT, TeamId) of
       [] ->
           case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAYER_CAMP_PVP) of
                {?true, Player2} ->
                    UserId = Player#player.user_id,
                    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
                        [_Rec] ->
                            misc_packet:send_tips(UserId, ?TIP_TEAM_ALREADY_IN_TEAM);
                        _ ->
                            PlayerPid = player_api:get_player_pid(TeamId), 
                            Mem = get_team_player(Player), 
                            case player_serv:process_call(PlayerPid, ?MODULE, try_join_team, {TeamId, Mem}) of
                                ok ->
                                    ets:insert(?CONST_ETS_CAMP_TEAM_INDEX, #camp_team_index{leader_id = TeamId, user_id = UserId}),
                                    {ok , Player2};
                                ErrCode ->
                                    misc_packet:send_tips(UserId, ErrCode)
                            end
                    end;
               {?false, Player2, Tips} ->
                   misc_packet:send_tips(Player#player.user_id, Tips),
                    Player2
            end;
       _ ->
           misc_packet:send_tips(Player#player.user_id, ?TIP_TEAM_ALREADY_START)
   end.

                

broad_camp(UserId, Lv, Packet) ->
    {Node, RoomId} = cross_api:get_camp_master(UserId, UserId, Lv),
    rpc:cast(Node, ?MODULE, broad_camp_cb, [RoomId, Packet]).

broad_camp_cp(RoomId, Packet) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, RoomId) of
        [] ->
            ok;
        _ ->
            camp_pvp_mod:broad(Packet, RoomId)
    end.

buy_item(Player, ItemId, Count) ->
    Info = Player#player.info,
    Score = Info#info.camp_score,
    ItemConfig = data_camp_pvp:get_shop(ItemId),
    GoodsId = ItemConfig#rec_camp_pvp_shop.goods_id,
    IsBind = ItemConfig#rec_camp_pvp_shop.bind,
    Cost =ItemConfig#rec_camp_pvp_shop.cost,
    case GoodsId == 0 of
        true ->
            PartnerId = ItemConfig#rec_camp_pvp_shop.partner_id,
            case Score >= Count * Cost of
                true ->
                    try
                        Player2 = arena_pvp_mod:exchange_partner(Player, PartnerId),
                        NewInfo = Info#info{camp_score = Score - Count * Cost},
                        Packet = msg_response_score(Score - Count * Cost),
                        misc_packet:send(Player#player.user_id, Packet),
                        Player3 = Player2#player{info = NewInfo},
                        {ok, Player3}
                    catch 
                        throw:{?error,ErrorCode} ->
                            misc_packet:send_tips(Player#player.user_id, ErrorCode)
                    end;
                _ ->
                    ok
            end;
        _ ->
            case ctn_bag2_api:is_full(Player#player.bag) of
                true ->
                    misc_packet:send_tips(Player#player.user_id, ?TIP_COMMON_BAG_NOT_ENOUGH);
                false ->
                    case Score >= Count * Cost of
                        true ->
                            Goods = goods_api:make(GoodsId, IsBind, Count),
                            NewInfo = Info#info{camp_score = Score - Count * Cost},
                            case ctn_bag_api:put(Player, Goods, ?CONST_COST_CAMP_PVP_BUY, 1, 1, 1, 1, 1, 1, []) of
                                {?ok, Player2, _, _} ->
                                     Packet = msg_response_score(Score - Count * Cost),
                                     misc_packet:send(Player#player.user_id, Packet),
                                    {ok, Player2#player{info = NewInfo}};
                                _ ->
                                    {ok, Player}
                            end;
                        _ ->
                            ok
                    end
            end
    end.
            
get_room_pid(UserId, MapType, MapId, Param) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ?MSG_ERROR(" player not in camp ~w", [UserId]),
            false;
        [UserRec] ->
            {X, Y} = camp_pvp_api:get_camp_born_point(UserRec#camp_pvp_player.camp_id),
            RoomId = UserRec#camp_pvp_player.room_id,
            case ets:lookup(?CONST_ETS_CAMP_PVP_ROOM, RoomId) of
                [] ->
                    ?MSG_ERROR(" player not in room", [UserId]),
                    false;
                [RoomRec] ->
                    case MapType of
                        ?CONST_MAP_TYPE_CAMP_PVP ->
                            case is_process_alive(RoomRec#camp_room.map_pid3) of
                                true ->
                                    {RoomRec#camp_room.map_pid3, X, Y};
                                false ->
                                    {ok, Pid} = camp_pvp_api:create_map(MapId, MapType, Param),
                                    ets:update_element(?CONST_ETS_CAMP_PVP_ROOM, RoomId, {#camp_room.map_pid3, Pid}),
                                    {Pid, X, Y}
                            end;
                        _ ->
                            case UserRec#camp_pvp_player.camp_id rem 10 of
                                ?CONST_CAMP_PVP_CAMP_1 ->
                                    case is_process_alive(RoomRec#camp_room.map_pid1) of
                                        true ->
                                            RoomRec#camp_room.map_pid1;
                                        false ->
                                            {ok, Pid} = camp_pvp_api:create_map(MapId, MapType, Param),
                                            ets:update_element(?CONST_ETS_CAMP_PVP_ROOM, RoomId, {#camp_room.map_pid1, Pid}),
                                            Pid
                                    end;
                                _ ->
                                    case is_process_alive(RoomRec#camp_room.map_pid2) of
                                        true ->
                                            RoomRec#camp_room.map_pid2;
                                        false ->
                                            {ok, Pid} = camp_pvp_api:create_map(MapId, MapType, Param),
                                            ets:update_element(?CONST_ETS_CAMP_PVP_ROOM, RoomId, {#camp_room.map_pid2, Pid}),
                                            Pid
                                    end
                            end
                    end
            end
    end.
                    

create_map(MapId, Type, Param) ->
    {?ok, MapPid} = map_sup:start_child_map_serv(MapId, Type, Param),
    ets_api:insert(?CONST_ETS_MAP, {MapPid, MapId, 0}),
    {?ok, MapPid}.

get_camp_born_point(CampId) ->
    CampConfig = data_camp_pvp:get_camp_pvp_config(CampId rem ?CONST_SYS_NUM_MILLION),
    PointList = CampConfig#rec_camp_pvp_config.born_points,
    N = misc:rand(1, length(PointList)),
    lists:nth(N, PointList).

encourage(Player) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [Rec] ->
            OldTimes = Rec#camp_pvp_player.encourage_times,
            case OldTimes >= 5 of
                true ->
                    misc_packet:send_tips(UserId, ?TIP_CAMP_PVP_ENCOURAGE);
                false ->
                    CampData = data_camp_pvp:get_camp_pvp_data(1),
                    Cost    = CampData#rec_camp_pvp_data.encourage_cost,
                    case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_CAMP_PVP_ENCOURAGE) of
                        ?ok ->
                            NewTimes = OldTimes + 1,
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.encourage_times, NewTimes}),
                            AddPer = camp_pvp_mod:get_ecourage_per(NewTimes),
                            Packet = msg_ecourage_success(AddPer),
                            misc_packet:send(UserId, Packet);
                        {?error, ErrorCode} ->
                            Packet = message_api:msg_notice(ErrorCode),
                            misc_packet:send(Player#player.net_pid, Packet)
                    end
            end
    end.


get_jiangyin(UserId, Player1Rec, Player2Rec) ->
    case Player1Rec#camp_pvp_player.user_id of
         UserId ->
            LvDif =  Player1Rec#camp_pvp_player.lv - Player2Rec#camp_pvp_player.lv;

        _ ->
            LvDif = Player2Rec#camp_pvp_player.lv - Player1Rec#camp_pvp_player.lv
    end,
    if 
        LvDif =< 5 ->
            2;
        LvDif =<10 ->
            1;
        true ->
            0
    end.

get_reward_hurt(UserId, Battle, Result) ->
    Param = Battle#battle.param,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            {0,0,0,0,0,0};
        [UserRec] ->
            Rate = camp_pvp_mod:get_active_rate(),
            Name = UserRec#camp_pvp_player.user_name,
            Level = UserRec#camp_pvp_player.lv,
            BattleType = Param#param.ad3,
            UnitsRight      = Battle#battle.units_right,
            {UserId1 , UserId2} = Param#param.ad4,
            case BattleType of
                ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
                    Player1Rec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId1),
                    Player2Rec = ets_api:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId2),
                    {Per1, Per2, _Jiangyin} = camp_pvp_mod:get_award_per(Player1Rec, Player2Rec),
                    {Per, OIdRec} = 
                        case UserId of
                            UserId1 -> {Per1, Player2Rec};
                            _ -> {Per2, Player1Rec}
                        end,
                    case Result of
                        1 ->
                            Jiangyin1 = get_jiangyin(UserId, Player1Rec, Player2Rec),
                            {AScore, ACopper} = camp_pvp_mod:stop_steak_kill_award(OIdRec),
                            case AScore + ACopper > 0 of
                                true ->
                                    CampName = camp_pvp_mod:get_camp_name(UserRec#camp_pvp_player.camp_id),
                                    PacketTips   = message_api:msg_notice(?TIP_CAMP_PVP_STOP_STEAK_KILL, 
                                        [{UserId,Name}, {OIdRec#camp_pvp_player.user_id,OIdRec#camp_pvp_player.user_name}],[],
                                        [{?TIP_SYS_COMM, misc:to_list(OIdRec#camp_pvp_player.kill_streak)},
                                         {?TIP_SYS_COMM, misc:to_list(CampName)},
                                         {?TIP_SYS_COMM, misc:to_list(AScore)}]),
                                       camp_pvp_mod:broad(PacketTips, Player1Rec#camp_pvp_player.room_id);
                                false ->
                                    ol
                            end,
                            WinAwardRec = data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_WIN, 1}),
                            ScoreAdd = round(Per * WinAwardRec#rec_camp_pvp_award.score) + AScore,
                            StreakTime = UserRec#camp_pvp_player.kill_streak + 1,
                            StreakScore = 
                                case data_camp_pvp:get_camp_pvp_award({?CONST_CAMP_PVP_AWARD_WIN, StreakTime}) of
                                    null ->
                                        0;
                                    WinStreakRec ->
                                        case StreakTime of
                                            1 ->
                                                0;
                                            _ ->
                                                 WinStreakRec#rec_camp_pvp_award.score
                                        end
                                end,
                            Gold = round(Rate * Per * ?FUN_CAMP_PVP_WIN(Level)) + ACopper;
                        _ ->
                            
                            Gold = round(Rate * Per * ?FUN_CAMP_PVP_LOST(Level)),
                            StreakTime = 0,
                            StreakScore = 0,
                            ScoreAdd = 0,
                            Jiangyin1 = 0
                    end,
                    Hurt = 0;
                ?CONST_CAMP_PVP_BATTLE_TYPE_PVM ->
                    OldHp = camp_pvp_mod:get_monster_hp(UserId2),
                    Units = misc:to_list(UnitsRight#units.units),
                    ?MSG_DEBUG("Units is ~w", [Units]),
                    Fun = 
                        fun(#unit{hp = NewHp1}, Acc) ->
                                NewHp1 + Acc;
                           (_, Acc) ->Acc
                        end,
                    NewHp = lists:foldl(Fun, 0, Units),
                    ?MSG_DEBUG("OldHp is ~w, NewHp is ~w, ", [OldHp, NewHp]),
                    Hurt = OldHp - NewHp,
                    Gold = ((Rate * Hurt) div 200),
                    StreakTime = 0, 
                    StreakScore = 0,
                    Jiangyin1 = 0,
                    ScoreAdd = 0;
                _ ->
                    ScoreAdd = 
                        case Result of
                            1 ->
                                Hurt = camp_pvp_serv:get_and_clear_boss_hurt(UserId),
                                MonsterId = camp_pvp_serv:get_monster_id_by_user(UserId, UserId2),
                                case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
                                    [#camp_pvp_monster{killed_user_id = UserId}] ->
                                        camp_pvp_mod:get_scores_by_kill_boss();
                                    _ ->
                                        0
                                end;
                            _ ->
                                Hurt = camp_pvp_mod:get_and_clear_boss_hurt(UserId),
                                0
                        end,
                    StreakTime = 0, 
                    StreakScore = 0,
                    Jiangyin1 = 0,
                    
                    Gold = (Rate * Hurt) div 200
            end,
            {Gold, ScoreAdd, StreakTime, StreakScore, Hurt, 0}
    end.
                    
map_init_finish(UserId, MapId) when is_integer(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.map_id, MapId}),
            case MapId == 41003 of
                true ->
                    Packet = camp_pvp_serv:get_room_msg(PlayerRec#camp_pvp_player.room_id),
                    misc_packet:send_cross(UserId, Packet);
                _ ->
                    ok
            end,
            BoxLeft = 3 - PlayerRec#camp_pvp_player.cash_count,
            PacketBoxLeft = camp_pvp_api:msg_box_left(BoxLeft),
            misc_packet:send_cross(UserId, PacketBoxLeft),
            camp_pvp_mod:init_and_broad_self_info(PlayerRec, MapId)
    end;

map_init_finish(Player, MapId) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, map_init_finish, [UserId, MapId]).
    

give_up_mining(UserId) when is_integer(UserId)->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [#camp_pvp_player{state = ?CONST_CAMP_PVP_PLAYER_STATE_WORKING}] ->
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                               [{#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL},
                                {#camp_pvp_player.recource_type, ?CONST_CAMP_PVP_RECOURCE_TYPE_NULL}]);
        _ ->
            ok
    end;

%% 放弃采集
give_up_mining(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, give_up_mining, [UserId]).


        
give_up_att_car(Player) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
             case PlayerRec#camp_pvp_player.state  of
                 ?CONST_CAMP_PVP_PLAYER_STATE_ATT_CAR ->
                            case PlayerRec#camp_pvp_player.recource_type of
                                ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH;
                                ?CONST_CAMP_PVP_RECOURCE_TYPE_LOW ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW;
                                _ ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL
                            end,
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.state, NewState});
                 _ ->
                     ok
             end
    end.
                 
player_state_change(UserId) when is_integer(UserId)->
    ?MSG_DEBUG("player ~w request change state", [UserId]),
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            case PlayerRec#camp_pvp_player.state_end_time =< misc:seconds() + 1 of
                true ->
                    case PlayerRec#camp_pvp_player.state  of
                        ?CONST_CAMP_PVP_PLAYER_STATE_DEAD ->
                            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.hp_expression, {1,1}}),
                            HpChangePackage = msg_hp_change([{2, UserId, 1, 1, PlayerRec#camp_pvp_player.camp_id rem 10, 
                                                              PlayerRec#camp_pvp_player.power,
                                                              PlayerRec#camp_pvp_player.lv,
                                                              PlayerRec#camp_pvp_player.kill_streak,
                                                              PlayerRec#camp_pvp_player.serv_id}]),
                            camp_pvp_mod:cross_send(UserId, HpChangePackage),
                            NewState = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL;
                        ?CONST_CAMP_PVP_PLAYER_STATE_WORKING ->
                            case PlayerRec#camp_pvp_player.recource_type of
                                ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH;
                                _ ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW
                            end;
                        ?CONST_CAMP_PVP_PLAYER_STATE_ATT_CAR ->
                            MonsterId = PlayerRec#camp_pvp_player.att_car_id,
                            camp_pvp_serv:att_car(UserId, MonsterId),
                            case PlayerRec#camp_pvp_player.recource_type of
                                ?CONST_CAMP_PVP_RECOURCE_TYPE_HIGH ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH;
                                ?CONST_CAMP_PVP_RECOURCE_TYPE_LOW ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW;
                                _ ->
                                    NewState = ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL
                            end;
                        _ -> 
                            NewState = PlayerRec#camp_pvp_player.state
                    end,
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, {#camp_pvp_player.state, NewState}),
                    Packet = msg_player_state(UserId, NewState),
                    camp_pvp_mod:broad(Packet, PlayerRec#camp_pvp_player.room_id);
                false ->
                    ok
            end
    end;

%% 前端请求状态改变
player_state_change(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, player_state_change, [UserId]).

%% 玩家下线
player_logout(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, UserId) of
        [] ->
            ok;
        [_TeamIndex] ->
            leave_team(#player{user_id = UserId})
    end,
    clear_invited(UserId),
    case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
        [] ->
            ok;
        _ ->
            Lv = player_api:get_level(UserId),
            camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, player_logout1, [UserId])
    end.

player_logout1(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [UserRec] ->
            case UserRec#camp_pvp_player.exist of
                false ->
                    ok;
                true ->
                    EnterCd = misc:seconds() + ?CONST_CAMP_PVP_ENTER_CD,
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                                       [{#camp_pvp_player.exist, false}, 
                                        {#camp_pvp_player.enter_cd, EnterCd},
                                        {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}]),
                    camp_pvp_serv:exit_camp(UserRec#camp_pvp_player.camp_id, UserRec#camp_pvp_player.power)
            end
    end.

%% 退出交战区地图， 设置状态编程广播部可见
exit_camp_pvp_map(UserId) ->
    Lv = player_api:get_level(UserId),
    camp_pvp_mod:cross_cast(UserId, Lv, ?MODULE, exit_camp_pvp_map1, [UserId]).

exit_camp_pvp_map1(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ok;
        [PlayerRec] ->
            case PlayerRec#camp_pvp_player.state == ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH orelse 
                  PlayerRec#camp_pvp_player.state  == ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW  of
                 true ->
                    ?MSG_DEBUG("user ~w state change to normal", [UserId]),
                    StatePacket = camp_pvp_api:msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL),
                    camp_pvp_mod:broad(StatePacket, PlayerRec#camp_pvp_player.room_id),
                    camp_pvp_mod:submit_resource(UserId);
                _ ->
                    case PlayerRec#camp_pvp_player.state == ?CONST_CAMP_PVP_PLAYER_STATE_DEAD of
                        true ->
                            StatePacket = camp_pvp_api:msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_DEAD),
                            camp_pvp_mod:broad(StatePacket, PlayerRec#camp_pvp_player.room_id);
                        false ->
                            ok
                    end
            end
    end.
            
%% 设置当前阵营资源采集量 gm命令
set_resource(Player, Recource) ->
    UserId = Player#player.user_id,
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->ok;
        [UserRec] ->
            CampId = UserRec#camp_pvp_player.camp_id,
            camp_pvp_serv:submit_recource(CampId, Recource, 0)
    end.

exit_camp(UserId) when is_integer(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            ?MSG_DEBUG("user ~w not in camp pvp, not need exit", [UserId]),
            Packet = msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL),
            camp_pvp_mod:cross_send(UserId, Packet);
        [CampPlayer] ->
            Now = misc:seconds(),
            EnterCd = Now + ?CONST_CAMP_PVP_ENTER_CD,
            Param = 
                case CampPlayer#camp_pvp_player.state of
                    ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH ->
                        [{#camp_pvp_player.exist, false},
                                 {#camp_pvp_player.enter_cd, EnterCd},
                                {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}];
                    ?CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW ->
                        [{#camp_pvp_player.exist, false},  
                                 {#camp_pvp_player.enter_cd, EnterCd},
                                 {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL}];
                    _ ->
                        [{#camp_pvp_player.exist, false},
                                 {#camp_pvp_player.enter_cd, EnterCd}]
                end,
            ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, Param),
            camp_pvp_serv:exit_camp(CampPlayer#camp_pvp_player.camp_id, CampPlayer#camp_pvp_player.power),
            Packet = msg_player_state(UserId, ?CONST_CAMP_PVP_PLAYER_STATE_NORMAL),
            camp_pvp_mod:cross_send(UserId, Packet)
    end;

%% 前端请求退出阵营战玩法
exit_camp(Player) ->
    ?MSG_DEBUG("user ~w request exit camp pvp", [Player#player.user_id]),
    Info = Player#player.info,
    Lv = Info#info.lv,
    BuffPacket = group_api:msg_sc_buffer(Player#player.user_id, []),
    misc_packet:send(Player#player.user_id, BuffPacket),
    case camp_pvp_mod:check_camp_open() of
        false ->
            ok;
        _ ->
            case ets:lookup(?CONST_ETS_CAMP_TEAM_INDEX, Player#player.user_id) of
                [] ->
                    ok;
                _ ->
                    TeamPacket = msg_team_over(),
                    misc_packet:send(Player#player.user_id, TeamPacket)
            end,
            ?MSG_ERROR("~w request exit camp pvp", [Player#player.user_id]),
            camp_pvp_mod:cross_cast(Player#player.user_id, Lv, ?MODULE, exit_camp, [Player#player.user_id])
    end,
    Player2 = map_api:return_last_city(Player),
    Player4 = 
        case player_state_api:try_set_state_play(Player2, ?CONST_PLAYER_PLAY_CITY) of
            {?true, Player3} ->
                Player3;
            {?false, Player3, _Tips} ->
                Player3
        end,
    {?ok, Player4}.


camp_info_4_client(Player, []) ->
    UserId = Player#player.user_id,
   case ets:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
       [] ->
           misc_packet:send_tips(UserId, ?TIP_CAMP_PVP_NOT_OPEN);
       [Rec] ->
           EndTime = Rec#camp_pvp_data.end_time,
           Fun =
               fun(CampId) ->
                       Score = 0,
                       PlayerCount = 0,
                       Resource = 0,
                       BuffList = [],
                       {CampId, PlayerCount, Score, Resource, BuffList}
               end,
           List = lists:map(Fun, [?CONST_CAMP_PVP_CAMP_1, ?CONST_CAMP_PVP_CAMP_2]),
           Packet = msg_sc_camp_info(List, EndTime, 3,get_camp_id_random(?CONST_CAMP_PVP_CAMP_2)),
           misc_packet:send(UserId, Packet),
           enter_camp_map(Player)
    end.

%% 点击阵营战button后请求阵营战信息
camp_info_4_client(Player) ->
    UserId = Player#player.user_id,
   case ets:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
       [] ->
           misc_packet:send_tips(UserId, ?TIP_CAMP_PVP_NOT_OPEN);
       [Rec] ->
           EndTime = Rec#camp_pvp_data.end_time,
           Fun =
               fun(CampId) ->
                       Score = 0,
                       PlayerCount = 0,
                       Resource = 0,
                       BuffList = [],
                       {CampId, PlayerCount, Score, Resource, BuffList}
               end,
           List = lists:map(Fun, [?CONST_CAMP_PVP_CAMP_1, ?CONST_CAMP_PVP_CAMP_2]),
           Packet = msg_sc_camp_info(List, EndTime, 3,get_camp_id_random(?CONST_CAMP_PVP_CAMP_2)),
           misc_packet:send(UserId, Packet),
           case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
               [] ->
                   ok;
               _ ->
                   enter_camp_map(Player)
           end
    end.

get_camp_id_random(Id) ->
    if 
        Id == 1 ->
            3;
        true ->
            W = calendar:day_of_the_week(date()),
            W rem 2 +1
    end.
        

%% 战斗结束
battle_over(Result, Param) ->
    case camp_pvp_mod:check_camp_open() of
        true ->
            camp_pvp_mod:battle_over(Result, Param);
        false ->
            ok
    end.
         

%% 活动开启
on([]) ->
    camp_pvp_serv:open().

%% 活动结束
off([]) ->ok.

%% 活动心跳
camp_pvp_interval() ->
    case ets_api:lookup(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data) of
        Campdata when is_record(Campdata, camp_pvp_data) ->
            camp_pvp_interval(Campdata);
        false ->
            skip
    end.
    

camp_pvp_interval(#camp_pvp_data{state = ?CONST_CAMP_PVP_OPEN, start_time = StartTime}) ->
    Now = misc:seconds(),
    case  Now > StartTime of
        true ->
            ets:update_element(?CONST_ETS_CAMP_PVP_DATA, camp_pvp_data, {#camp_pvp_data.state, ?CONST_CAMP_PVP_START}),
            broad_start();
        false ->
            skip
    end;
        
camp_pvp_interval(#camp_pvp_data{state = ?CONST_CAMP_PVP_START, end_time = EndTime}) ->
    Now = misc:seconds(),
    {_H,M,S} = time(),
    if
        EndTime + 5*60 =< Now ->
            broad_rank(Now *  ?RANK_BROAD_INTERVAL),
            camp_pvp_serv:end1();
        EndTime == Now ->
            Packet = msg_cash_active_start(),
            camp_pvp_mod:broad(Packet);
        EndTime < Now ->
            case S == 30  of
                true ->
                    Count = get_index_count(M, S),
                    ?MSG_ERROR("refresh ~w at ~w",[Count, Now]),
                    camp_pvp_serv:refresh_room_box(Count);
                _ ->
                    ok
            end,
            broad_rank(Now);
        true -> 
            broad_rank(Now)
            
    end.

get_index_count(M,S) ->
    AwardList = [15,25,35,45,60,20,25,25,40,40,1,1],
    Index = M -30 +1,
    case Index >5 of
        true ->
            10;
        _ ->
            lists:nth(Index, AwardList)
    end.

login_packet(Player, AccPacket) ->
    case camp_pvp_mod:check_camp_open() of
        true ->
            UserId = Player#player.user_id,
            Info = Player#player.info,
            Lv = Info#info.lv,
            case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
                [] ->
                    {Player, AccPacket};
                _ ->
                    case camp_pvp_mod:cross_call(UserId, Lv, ets, lookup, [?CONST_ETS_CAMP_PVP_PLAYER, UserId]) of
                        [CampPlayer] ->
                            Cd = CampPlayer#camp_pvp_player.enter_cd,
                            Packet  = msg_enter_cd(Cd),
                            {Player, <<AccPacket/binary, Packet/binary>>};
                        _ -> {Player, AccPacket}
                    end
            end;
        _ -> {Player, AccPacket}
    end.

%% boss每回合刷新血量
refresh_monster(UserId, MonsterId, HurtTuple) ->
    ?MSG_DEBUG("~w try to refresh boss hp, hurttuple is ~w", [UserId, HurtTuple]),
    MonsterId2 = camp_pvp_serv:get_monster_id_by_user(UserId, MonsterId),
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId2) of 
        [#camp_pvp_monster{state = ?CONST_CAMP_PVP_MONSTER_STATE_DEAD}] ->
            erlang:make_tuple(9, 0, []);
        [#camp_pvp_monster{hp_tuple_boss = HpTuple}]->
            ?MSG_DEBUG("new HpTuple is ~w ", [HpTuple]),
            case HurtTuple of
                {0,0,0,0,0,0,0,0,0} -> HpTuple;
                _ ->
                    case camp_pvp_mod:check_camp_open() of
                        false ->
                            ?MSG_ERROR("camp pvp end set boss hp 0", []),
                            erlang:make_tuple(9, 0, []);
                        true ->
                            Hurt        = lists:sum(misc:to_list(HurtTuple)),
                            camp_pvp_serv:refresh_monster_cast(MonsterId, Hurt, HurtTuple, UserId),
                            boss_mod:set_hp_tuple(HpTuple, HurtTuple) %% 这里可能不准了 lz
                    end
            end;
        _ -> erlang:make_tuple(9, 0, [])
    end.

%% 广播活动开始信息
broad_start() ->
    ?MSG_DEBUG("camp pvp is start at ~w", [misc:seconds()]),
    Packet = camp_pvp_msg:msg_sc_start(),
    camp_pvp_mod:broad(Packet).

%% 广播排行榜
broad_rank(Now) ->
    case Now rem ?RANK_BROAD_INTERVAL == 0 of
        true ->
            camp_pvp_mod:broad_monster_info(),
            PlayerList = ets:tab2list(?CONST_ETS_CAMP_PVP_PLAYER),
            Dict = dict:new(),
            Fun =
                fun(Room, OldDict) ->
                    RoomId = Room#camp_room.room_id,
                    FilterFun = 
                        fun(Player) ->
                                Player#camp_pvp_player.room_id == RoomId
                        end,
                    RoomList = lists:filter(FilterFun, PlayerList),
                    ScoreSortFun = 
                        fun(#camp_pvp_player{scores = Score1, scores_update_time = Time1}, 
                            #camp_pvp_player{scores = Score2, scores_update_time = Time2}) ->
                                if 
                                    Score1 > Score2 -> true;
                                    Score1 < Score2 -> false;
                                    true ->
                                        Time1 =< Time2
                                end
                        end,
                    StreakSortFun = 
                        fun(#camp_pvp_player{kill_streak_max = Streak1, kill_streak_max_time = Time1},
                             #camp_pvp_player{kill_streak_max = Streak2, kill_streak_max_time = Time2}) ->
                                if
                                    Streak1 > Streak2 -> true;
                                    Streak1 < Streak2 -> false;
                                    true ->
                                        Time1 =< Time2
                                end
                        end,
                    ScoreSortedList = lists:sort(ScoreSortFun, RoomList),
                    StreakSortedList = lists:sort(StreakSortFun, RoomList),
                    Top5 = lists:sublist(ScoreSortedList, 5),
                    Top3 = lists:sublist(StreakSortedList, 3),
                    FormatFun = 
                        fun(#camp_pvp_player{scores = Score, user_name = Name, camp_id = Camp_id, serv_id = ServId}) ->
                                {Name, Score, Camp_id rem ?CONST_SYS_NUM_MILLION, ServId}
                        end,
                    FormatFun2 = 
                        fun(#camp_pvp_player{kill_streak_max = Streak, user_name = Name, camp_id = Camp_id, serv_id = ServId}) ->
                                {Name, Streak, Camp_id rem ?CONST_SYS_NUM_MILLION, ServId}
                        end,
                    Top5Format = lists:map(FormatFun, Top5),
                    Top3Format = lists:map(FormatFun2, Top3),
                    dict:store(RoomId, {Top5Format, Top3Format}, OldDict)
                end,
            NewDict = lists:foldl(Fun, Dict, ets:tab2list(?CONST_ETS_CAMP_PVP_ROOM)),
            broad_info(PlayerList, NewDict);
        false ->
            ok
    end.

get_camp_by_room(RoomId) ->
    CampId1 = camp_pvp_serv:get_monster_id(RoomId, ?CONST_CAMP_PVP_CAMP_1),
    CampId2 = camp_pvp_serv:get_monster_id(RoomId, ?CONST_CAMP_PVP_CAMP_2),
    Camp1 = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId1),
    Camp2 = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId2),
    {Camp1, Camp2}.

broad_info([], _NewDict) ->
    ok;
broad_info([Player|RestPlayerList], NewDict) ->
    case Player#camp_pvp_player.exist == false of
        true ->
            ok;
        _ ->
            {Camp1, Camp2} = get_camp_by_room(Player#camp_pvp_player.room_id),
            Score1 = Camp1#camp_pvp_camp.scores,
            Score2 = Camp2#camp_pvp_camp.scores,
            Camp1Resource = Camp1#camp_pvp_camp.resource,
            Camp2Resource = Camp2#camp_pvp_camp.resource,
            Count1 = Camp1#camp_pvp_camp.count,
            Count2 = Camp2#camp_pvp_camp.count,
            SelfScore = Player#camp_pvp_player.scores,
            RoomId = Player#camp_pvp_player.room_id,
            case dict:find(RoomId, NewDict) of
                {ok, {Top5, Top3}} ->
                    SelfWinStreak = Player#camp_pvp_player.kill_streak_max,
                    SelfWinStreakNow = Player#camp_pvp_player.kill_streak,
                    BuffList = get_camp_Buff_list(Player#camp_pvp_player.camp_id),
                    case Player#camp_pvp_player.camp_id rem ?CONST_SYS_NUM_MILLION of
                        ?CONST_CAMP_PVP_CAMP_1 ->
                            Packet = msg_sc_rank(SelfScore,Score1,Score2,Camp1Resource,Count1, Count2, Top5, Top3, BuffList, SelfWinStreak, SelfWinStreakNow, Camp2Resource);
                        _ ->
                            Packet = msg_sc_rank(SelfScore, Score2,Score1,Camp2Resource, Count2,Count1, Top5, Top3, BuffList, SelfWinStreak, SelfWinStreakNow, Camp1Resource)
                    end,
                    camp_pvp_mod:cross_send(Player#camp_pvp_player.user_id, Packet);
                _ ->
                    ?MSG_ERROR("User ~w room is ~w,but the room not exit !!!!!!!!!", [Player#player.user_id, RoomId]),
                    ok
            end
    end,
    broad_info(RestPlayerList, NewDict).

%% 进入阵营战玩发
enter_camp_map(Player) ->
    {?ok, Player1}  = schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_CAMP_PVP),
    Info = Player#player.info,
    Lv = Info#info.lv,
    UserId = Player#player.user_id,
	schedule_api:add_resource_times(UserId, ?CONST_SCHEDULE_RESOURCE_CAMP),
    case ets:lookup(?CONST_ETS_CROSS_OUT, UserId) of
        [] ->
            case get_team_member(UserId) of
                [] ->
                    {_Node, Room} = cross_api:get_camp_master(Player#player.user_id, Lv),
                    camp_pvp_mod:enter_camp_map(Player1, Room);
                MemList ->
                    {Node, Room} = cross_api:get_camp_master(MemList, Lv),
                    camp_pvp_mod:enter_camp_map(Node, MemList, Room)
            end;
        [_Rec] ->
            {_Node, Room} = cross_api:get_camp_master(Player#player.user_id, Lv),
            camp_pvp_mod:enter_camp_map(Player1, Room)
    end.

get_team_member(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_TEAM_LIST, UserId) of
        [] ->
            [];
        [Team] ->
            MemList = Team#camp_team_list.id_list,
            case length(MemList) == 1 of
                true ->
                    [];
                _ ->
                    [Mem#camp_team_member.user_id || Mem<-MemList]
            end
    end.

get_camp_Buff_list(CampId) ->
    CameRec = ets_api:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId),
    CameRec#camp_pvp_camp.buff.
    

%% 采集资源
mining(Player, Type) ->
    ?MSG_DEBUG("camp_pvp, user ~w try to mining resource (Type : ~w)", [Player#player.user_id, Type]),
    camp_pvp_mod:mining(Player, Type).

%% 提交资源
submit_resource(Player) ->
    ?MSG_DEBUG("camp_pvp, user ~w try to submit resource ", [Player#player.user_id]),
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    case camp_pvp_mod:check_camp_open() of
        false ->
            ok;
        _ ->
            camp_pvp_mod:cross_cast(UserId, Lv, camp_pvp_mod, submit_resource, [UserId])
    end.

%% 请求战斗
start_battle(Player, UserId, Type) ->
    Info = Player#player.info,
    Lv = Info#info.lv,
    case camp_pvp_mod:check_camp_open() of
        true ->
            camp_pvp_mod:cross_cast(Player#player.user_id, Lv, camp_pvp_serv, start_battle, [Player#player.user_id, UserId, Type]);
        false ->
            ?MSG_DEBUG("camp_pvp ~w check to battle where ~w, but camp not open(battle type ~w)",
                        [Player#player.user_id, UserId, Type]),
            Packet = msg_is_battle_start(false),
            misc_packet:send(Player#player.user_id, Packet),
            {?ok, Player}
    end.


start_battle1(Player, UserId, Type1) ->
    Type = camp_pvp_mod:get_battle_type_by_id(Type1, UserId),
    ?MSG_DEBUG("camp_pvp, user ~w try to battle with ~w,(battle type : ~w) ", [Player#player.user_id,UserId, Type]),
    case check_battle_state(Player, UserId, Type) of
        {?ok, Buff1, Hp1, Buff2, Hp2, Ad5} ->
            ?MSG_DEBUG("Buff1, Hp1, Buff2, Hp2, Ad5} is ~w", [{Buff1, Hp1, Buff2, Hp2, Ad5}]),
            Param = 
                 #param{battle_type = ?CONST_BATTLE_CAMP_PVP, 
                        attr = {Buff1, Buff2}, 
                        ad1 = Hp1, 
                        ad2 = Hp2, 
                        ad3 = Type,
                        ad4 = {Player#player.user_id, UserId},
                        ad5 = Ad5},
            case Type of
                ?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
                    ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, Player#player.user_id, 
                                       [{#camp_pvp_player.att_car_id, UserId},
                                        {#camp_pvp_player.state_end_time, misc:seconds() + 10},
                                        {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_ATT_CAR}]),
                    Packet = msg_att_car_success(),
                    misc_packet:send(Player#player.user_id, Packet);
                _ ->
                    case battle_api:start(Player, UserId, Param) of
                        {?ok, _} ->
                            Packet = msg_is_battle_start(true),
                            misc_packet:send(Player#player.user_id, Packet),
                            camp_pvp_mod:broad_state_change_to_battle(Player#player.user_id, UserId, Type),
                            ok;
                        _ ->
                            Packet = msg_is_battle_start(false),
                            misc_packet:send(Player#player.user_id, Packet),
                            reset_state(Player#player.user_id, UserId, Type)
                    end
            end;
        _ ->
            Packet = msg_is_battle_start(false),
            misc_packet:send(Player#player.user_id, Packet),
            ok
    end.

%%
%% Local Functions
%%

% 只有冲锋怪需要设置状态


reset_state(UserId1, UserId2, Type) when Type == ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
    camp_pvp_mod:reset_player_state(UserId1),
    camp_pvp_mod:reset_player_state(UserId2);
reset_state(UserId, MonsterId, Type) when Type == ?CONST_CAMP_PVP_BATTLE_TYPE_PVM ->
    camp_pvp_mod:reset_player_state(UserId),
    camp_pvp_mod:reset_monster_state(MonsterId);
reset_state(UserId1, _UserId2, _Type)  ->
    camp_pvp_mod:reset_player_state(UserId1).
 
check_battle_state(Player, MonsterId1, Type) when Type == ?CONST_CAMP_PVP_BATTLE_TYPE_PVM ->
    MonsterId = camp_pvp_serv:get_monster_id_by_user(Player#player.user_id, MonsterId1),
    case camp_pvp_mod:check_camp_monster(Player#player.user_id, MonsterId) of
        true ->
            case  check_battle_state(Player#player.user_id) of
                {?ok, Buff1, Hp1} ->
                    case  camp_pvp_monster:check_and_set_state(MonsterId) of
                        {?ok, Buff2, Hp2} ->
                            Packet = msg_monster_stop(MonsterId),
                            camp_pvp_mod:broad(Packet, MonsterId div ?CONST_SYS_NUM_MILLION),
                            {?ok, Buff1, Hp1, Buff2, Hp2,0};
                        {false, ?CONST_CAMP_PVP_MONSTER_STATE_BATTLE} ->
                            ?MSG_DEBUG("camp pvp monster ~w is battle", [MonsterId]),
                            camp_pvp_mod:reset_player_state(Player#player.user_id),
                            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_MONSTER_ALREADY_BATTLE);
                        Other ->
                            ?MSG_DEBUG("check monster state failed, reason:~w", [Other]),
                            camp_pvp_mod:reset_player_state(Player#player.user_id),
                            ?false
                    end;
                Other ->
                    ?MSG_DEBUG("playe not ready , because:~w", [Other]),
                    ?false
            end;
        _ ->
            ?MSG_DEBUG("~w try to battle where ~w, battle they are same camp", 
                       [Player#player.user_id, MonsterId]),
            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_SAME_CAMP),
            ?false
     end;

check_battle_state(Player, BossId, Type) when Type == ?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
     case camp_pvp_mod:check_camp_monster(Player#player.user_id, BossId) of
         true ->
            case check_battle_state(Player#player.user_id) of
                {?ok, Buff1, Hp1} ->
                    case get_boss_state(BossId) of
                        {?ok, Buff2, Hp2, Ad2} ->
                             {?ok, Buff1, Hp1, Buff2, Hp2, Ad2};
                        _ ->
                            ?MSG_DEBUG("~w try to battle with ~w but, boss have dead", 
                                       [Player#player.user_id, BossId]),
                            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_MONSTER_DEAD),
                            camp_pvp_mod:reset_player_state(Player#player.user_id),
                            ?false
                    end;
                Other ->
                    ?MSG_DEBUG("playe not ready , because:~w", [Other]),
                    ?false
            end;
         _ ->
            ?MSG_DEBUG("~w try to battle where ~w, battle they are same camp", 
                       [Player#player.user_id, BossId]),
             misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_SAME_CAMP),
             ?false
     end;


check_battle_state(Player, UserId, Type) when Type == ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
    case camp_pvp_mod:check_camp(Player#player.user_id, UserId) of
        false -> 
            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_SAME_CAMP),
            ?MSG_DEBUG("user ~w , user  ~w  in camp pvp", [Player#player.user_id, UserId]),
            ?false;
        _ ->
            case get_pk_cd_left(Player#player.user_id, UserId) of
                0 ->
                    case check_battle_state(Player#player.user_id) of
                        {?ok, Buff1, Hp1} ->
                            PlayerPid = player_api:get_player_pid(UserId), 
                            case player_serv:process_call(PlayerPid, ?MODULE, check_player_battle, UserId) of
                                {?ok, Buff2, Hp2} ->
                                    {?ok, Buff1, Hp1, Buff2, Hp2,0};
                                O ->
                                    case O of
                                        {?false, working} ->
                                            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_WORKING);
                                        {?false, deading} ->
                                            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_DEAD);
                                        {?false, battleing} ->
                                            misc_packet:send_tips(Player#player.user_id, ?TIP_CAMP_PVP_USER_BATTLING);
                                        _ ->
                                            ?false
                                    end,
                                    camp_pvp_mod:reset_player_state(Player#player.user_id),
                                    ?MSG_DEBUG("user ~w can not start battle, reason : ~w", [UserId, O]),
                                    ?false
                           end;
                        O ->
                            ?MSG_DEBUG("user ~w can not start battle, reason : ~w", [Player#player.user_id, O]),
                            ?false
                    end;
                CdLeft ->
                    ?MSG_DEBUG("~w can pk ~w after ~w second", [Player#player.user_id, UserId, CdLeft]),
                    PacketCd  = message_api:msg_notice(?TIP_CAMP_PVP_PK_CD,
                                                 [{?TIP_SYS_COMM, misc:to_list(CdLeft)}]),
                    misc_packet:send_cross(Player#player.user_id, PacketCd),
                    false
            end
    end.

get_pk_cd_left(AttId, DefId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PK_CD, AttId) of
        [] ->
            0;
        [CdRec] ->
            CdDict = CdRec#camp_pvp_pk_cd.cd_dict,
            case dict:find(DefId, CdDict) of
                {ok, EndTime} ->
                    ?MSG_DEBUG("EndTime is ~w", [EndTime]),
                    TimeLeft = max(0, EndTime - misc:seconds()),
                    case TimeLeft > 0 of
                        true ->
                            TimeLeft;
                        false ->
                            NewCdDict = dict:erase(DefId, CdDict),
                            ets:update_element(?CONST_ETS_CAMP_PVP_PK_CD, AttId, {#camp_pvp_pk_cd.cd_dict, NewCdDict}),
                            0
                    end;
                _ ->
                    0
            end
    end.

get_boss_state(MonsterId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_MONSTER, MonsterId) of
        [] ->
            {?ok, [], [], {0,0,0,0,0,0,0,0,0}};
        [BossRec] ->
            case BossRec#camp_pvp_monster.state of
                ?CONST_CAMP_PVP_MONSTER_STATE_DEAD ->
                    {?false, boss_dead};
                _ ->
                     {?ok, [], BossRec#camp_pvp_monster.hp_tuple, BossRec#camp_pvp_monster.hp_tuple_boss}
            end
    end.

check_player_battle(Player, UserId) ->
    Result = check_battle_state(UserId),
    ?MSG_DEBUG("--------------check player ~w's start result is ~w", [UserId, Result]),
    {?ok, Result, Player}.

check_battle_state(UserId) ->
    State = 
        case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
            [] ->
                EncourageTime = 0,
                ?MSG_ERROR("userId ~w try camp pvp, but he not at camp map", [UserId]),
                {?false, not_find};
            [CampPlayer] ->
                EncourageTime = CampPlayer#camp_pvp_player.encourage_times,
                PvpMapId = camp_pvp_mod:get_camp_pvp_map_id(),
                case CampPlayer#camp_pvp_player.map_id == PvpMapId of
                    true ->
                        case CampPlayer#camp_pvp_player.state of
                            ?CONST_CAMP_PVP_PLAYER_STATE_WORKING ->
                                case CampPlayer#camp_pvp_player.state_end_time =< misc:seconds() of
                                    true ->
                                        ?ok;
                                    false ->
                                        {?false, working}
                                end;
                            ?CONST_CAMP_PVP_PLAYER_STATE_DEAD ->
                                case CampPlayer#camp_pvp_player.state_end_time =< misc:seconds() of
                                    true ->
                                        ?ok;
                                    false ->
                                        {?false, deading}
                                end;
                            ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE ->
                                {?false, battleing};
                            _ ->
                                ets:update_element(?CONST_ETS_CAMP_PVP_PLAYER, UserId, 
                                        {#camp_pvp_player.state, ?CONST_CAMP_PVP_PLAYER_STATE_BATTLE}),
                                ?ok
                        end;
                    false ->
                        ?MSG_ERROR("user ~w not in pvp map, but try to start battle", [UserId]),
                        {?false, deading}
               end
        end,
    case State of
        ?ok ->
            {Buff,Hp} = get_buff_hp(UserId),
            PerAdd = camp_pvp_mod:get_ecourage_per(EncourageTime),
            case PerAdd of
                0 ->
                    Buff1=Buff;
                _ ->
                    AddBuff = [{3, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, PerAdd*100}, 
                               {3, ?CONST_PLAYER_ATTR_FORCE_ATTACK, PerAdd*100}],
                    Buff1 = Buff ++ AddBuff
            end,
            {?ok, Buff1, Hp};
        Other ->
            Other
    end.

get_buff_hp(UserId) ->
    case ets:lookup(?CONST_ETS_CAMP_PVP_PLAYER, UserId) of
        [] ->
            {};
        [CampPlayer] ->
            Hp = CampPlayer#camp_pvp_player.hp,
            CampId = CampPlayer#camp_pvp_player.camp_id,
            Buff = 
                case ets:lookup(?CONST_ETS_CAMP_PVP_CAMP, CampId) of
                    [] ->
                        [];
                    [CampRec] ->
                        CampRec#camp_pvp_camp.buff
                end,
            {Buff, Hp}
    end.
            
    


msg_sc_enter(Camp) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_ENTER, ?MSG_FORMAT_CAMP_PVP_SC_ENTER, [Camp]).
%% 排行榜数据广播
%%[SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,SelfCampCount,OtherCampCount,{Name,Score,CampId1,ScoreServId},{Name1,SteakCount,CampId2,WinServId},{CampId,BuffId,Value},SelfStreakWin,SelfStreakWinNow,OtherRecourceTotal]
msg_sc_rank(SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,SelfCampCount,OtherCampCount,List1,List2,List3,SelfStreakWin,SelfStreakWinNow,OtherRecourceTotal) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_RANK, ?MSG_FORMAT_CAMP_PVP_SC_RANK, [SelfScore,SelfCampScore,OtherCampScore,RecourceTotal,SelfCampCount,OtherCampCount,List1,List2,List3,SelfStreakWin,SelfStreakWinNow,OtherRecourceTotal]).

%% 开始采集资源
%%[Time,Speed]
msg_sc_dig_success(Time,Speed) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_DIG_SUCCESS, ?MSG_FORMAT_CAMP_PVP_SC_DIG_SUCCESS, [Time,Speed]).
%% 活动开始
%%[]
msg_sc_start() ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_START, ?MSG_FORMAT_CAMP_PVP_SC_START, []).
%% 活动结束
%%[{Name1,CampId1,Level1,Career1,GuildName1},ExpCamp,IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,ExpRank,Career,Level,CampId,GuildName,Jiangyin]
msg_sc_end(List1,ExpCamp,IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,ExpRank,Career,Level,CampId,GuildName,Jiangyin) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_END, ?MSG_FORMAT_CAMP_PVP_SC_END, [List1,ExpCamp,IsCampSuccess,IsTop5,TopAward,RankPositon,Score,Gold,ExpRank,Career,Level,CampId,GuildName,Jiangyin]).
%% 加怪物
%%[MonsterId,PositionX,PositionY,Speed,TargetX,TargetY]
msg_add_monster(MonsterId,PositionX,PositionY,Speed,TargetX,TargetY) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_ADD_MONSTER, ?MSG_FORMAT_CAMP_PVP_ADD_MONSTER, [MonsterId,PositionX,PositionY,Speed,TargetX,TargetY]).
%% 怪物开始移动
%%[MonsterId,TargetX,TargetY,Speed]
msg_monster_move(MonsterId,TargetX,TargetY,Speed) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_MOVE, ?MSG_FORMAT_CAMP_PVP_MONSTER_MOVE, [MonsterId,TargetX,TargetY,Speed]).
%% 怪物被杀死
%%[MonsterId]
msg_monster_killed(MonsterId) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_KILLED, ?MSG_FORMAT_CAMP_PVP_MONSTER_KILLED, [MonsterId]).
%% 怪物攻击buffnpc
%%[MonsterId]
msg_monster_attack(MonsterId) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_ATTACK, ?MSG_FORMAT_CAMP_PVP_MONSTER_ATTACK, [MonsterId]).
%% 请求阵营战信息返回
%%[{CampId,PlayerCount,Score,Resource,{BuffType,BuffId,BuffValue}},TimeEnd,LeftCamp,RightCamp]
msg_sc_camp_info(List1,TimeEnd,LeftCamp,RightCamp) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_CAMP_INFO, ?MSG_FORMAT_CAMP_PVP_SC_CAMP_INFO, [List1,TimeEnd,LeftCamp,RightCamp]).
%%
%% 交战区怪物信息
%%[{MonsterId,MonsterX,MonsterY,TargetX,TargetY,Speed,IsBattle,CampId,HpNow,HpMax}]
msg_sc_monster_info(List1) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_SC_MONSTER_INFO, ?MSG_FORMAT_CAMP_PVP_SC_MONSTER_INFO, [List1]).
%% 怪物停止移动
%%[MonsterId]
msg_monster_stop(MonsterId) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_MONSTER_STOP, ?MSG_FORMAT_CAMP_PVP_MONSTER_STOP, [MonsterId]).
%% 广播玩家状态
%%[UserId,State]
msg_player_state(UserId,State) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_PLAYER_STATE, ?MSG_FORMAT_CAMP_PVP_PLAYER_STATE, [UserId,State]).

%% 玩家状态广播组
%%[{UserId,State}]
msg_player_state_list(List1) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_PLAYER_STATE_LIST, ?MSG_FORMAT_CAMP_PVP_PLAYER_STATE_LIST, [List1]).

%% buff怪挂了，buff消失
%%[MonsterId,CampId,BuffId,AddType,Value]
msg_buff_miss(MonsterId,CampId,BuffId,AddType,Value) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_BUFF_MISS, ?MSG_FORMAT_CAMP_PVP_BUFF_MISS, [MonsterId,CampId,BuffId,AddType,Value]).

%% 雷霆一击
%%[CampId,{MonsterId}]
msg_hurt_all_boss(CampId,List1) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_HURT_ALL_BOSS, ?MSG_FORMAT_CAMP_PVP_HURT_ALL_BOSS, [CampId,List1]).

%% 血量变化通知
%%[{Type,Id,Hp,HpMax,CampId,Combat,Lv,SteakKill}]
msg_hp_change(List1) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_HP_CHANGE, ?MSG_FORMAT_CAMP_PVP_HP_CHANGE, [List1]).

%% 发起战斗是否成功
%%[IsBattleStart]
msg_is_battle_start(IsBattleStart) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_IS_BATTLE_START, ?MSG_FORMAT_CAMP_PVP_IS_BATTLE_START, [IsBattleStart]).
%% 大演武冷却时间
%%[Time]
msg_enter_cd(Time) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_ENTER_CD, ?MSG_FORMAT_CAMP_PVP_ENTER_CD, [Time]).

%% 鼓舞成功
%%[AddPer]
msg_ecourage_success(AddPer) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_ECOURAGE_SUCCESS, ?MSG_FORMAT_CAMP_PVP_ECOURAGE_SUCCESS, [AddPer]).

%% 广播队伍信息
%%[{UserId,Name,Career,Sex},LeaderId]
msg_broad_team_info(List1,LeaderId) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_BROAD_TEAM_INFO, ?MSG_FORMAT_CAMP_PVP_BROAD_TEAM_INFO, [List1,LeaderId]).

%% 礼券活动开始
%%[]
msg_cash_active_start() ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_CASH_ACTIVE_START, ?MSG_FORMAT_CAMP_PVP_CASH_ACTIVE_START, []).
%% 刷新宝箱
%%[{Type,X,Y,Id},IsNewFresh]
msg_refresh_cash(List1,IsNewFresh) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_REFRESH_CASH, ?MSG_FORMAT_CAMP_PVP_REFRESH_CASH, [List1,IsNewFresh]).
%% 请求开宝箱结果
%%[IsSuccess]
msg_open_cash_result(IsSuccess) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_OPEN_CASH_RESULT, ?MSG_FORMAT_CAMP_PVP_OPEN_CASH_RESULT, [IsSuccess]).

%% 召唤怪
%%[]
msg_call_monster() ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_CALL_MONSTER, ?MSG_FORMAT_CAMP_PVP_CALL_MONSTER, []).

%% 返回当前积分
%%[Score]
msg_response_score(Score) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_RESPONSE_SCORE, ?MSG_FORMAT_CAMP_PVP_RESPONSE_SCORE, [Score]).

%% 移除宝箱
%%[Id]
msg_remove_cash_box(Id) ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_REMOVE_CASH_BOX, ?MSG_FORMAT_CAMP_PVP_REMOVE_CASH_BOX, [Id]).

%% 队伍解散
%%[]
msg_team_over() ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_TEAM_OVER, ?MSG_FORMAT_CAMP_PVP_TEAM_OVER, []).

msg_att_car_success() ->
    misc_packet:pack(?MSG_ID_CAMP_PVP_ATT_CAR_SUCCESS, ?MSG_FORMAT_CAMP_PVP_ATT_CAR_SUCCESS, []).