%%% 坐骑技能相关
-module(horse_skill_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.base.data.hrl").
-include("record.player.hrl").
-include("record.goods.data.hrl").
-include("record.data.hrl").

%%
%% Exported Functions
%%
-export([init/0, learn/2, login_packet/1, learn_from_base/2, upgrade_skill_base/2,
         lv_up_skill/3]).

%%
%% API Functions
%%
init() ->
    [].

login_packet(Player) ->
    HorseData  = Player#player.horse,
    HorseSkill = HorseData#horse_data.skill,
    pack_all(HorseSkill, <<>>).

upgrade_skill_base(Lv, HorseSkill, SkillId) ->
    case data_horse:get_horse_skill(SkillId) of
        #rec_horse_skill{type = Type, lv = LvNew, color = Color} when Color >= ?CONST_SYS_COLOR_PURPLE ->
            case lists:keytake(Type, #horse_skill.type, HorseSkill) of
                {value, #horse_skill{skill_id = OldSkillId} = Record, HorseSkill2} ->
                    case data_horse:get_horse_skill(OldSkillId) of
                        #rec_horse_skill{lv = LvOld} when LvOld < LvNew andalso LvNew =< Lv ->
                            Packet = horse_api:msg_sc_skill_have(SkillId),
                            Packet2 = horse_api:msg_sc_horseskill(1),
                            {?ok, [Record#horse_skill{skill_id = SkillId}|HorseSkill2], <<Packet/binary, Packet2/binary>>};
                        #rec_horse_skill{lv = LvOld} when LvOld < LvNew ->
                            {{?error, ?TIP_HORSE_LV_NOT_ENOUGH}, HorseSkill, <<>>};
                        _ ->
                            {{?error, ?TIP_HORSE_SKILL}, HorseSkill, <<>>}
                    end;
                _ when LvNew =< Lv ->
                    Packet = horse_api:msg_sc_skill_have(SkillId),
                    Packet2 = horse_api:msg_sc_horseskill(1),
                    {?ok, [#horse_skill{type = Type, skill_id = SkillId}|HorseSkill], <<Packet/binary, Packet2/binary>>};
                _ ->
                    {{?error, ?TIP_HORSE_LV_NOT_ENOUGH}, HorseSkill, <<>>}
            end;
        #rec_horse_skill{} ->
            {?ok, HorseSkill, <<>>};
        _X ->
            {{?error, ?TIP_HORSE_SKILL}, HorseSkill, <<>>}
    end.

learn(Player, Goods) ->
    Info = Player#player.info,
    Lv = Info#info.lv,
    Ext = Goods#goods.exts,
    SkillId = Ext#g_skill_book.skill_id,
    HorseData  = Player#player.horse,
    HorseSkill = HorseData#horse_data.skill,
    {Result, NewHoresSkill, PacketSkill} = 
        upgrade_skill_base(Lv, HorseSkill, SkillId),
    case Result of
        ?ok ->
            NewHorseData = HorseData#horse_data{skill = NewHoresSkill},
            UserId = Player#player.user_id,
            EquipList = Player#player.equip,
            case upgrade_skill(UserId, EquipList, SkillId) of
                {?ok, EquipList2, GoodsPacket} ->
                    OkPacket = message_api:msg_notice(?TIP_HORSE_SKILL_CHANGE_SUCCESS),
                    misc_packet:send(UserId, <<GoodsPacket/binary, PacketSkill/binary, OkPacket/binary>>),
                    {?ok, Player#player{horse = NewHorseData, equip = EquipList2}};
                {?error, ErrorCode} ->
                    ErrorPacket = message_api:msg_notice(ErrorCode),
                    misc_packet:send(UserId, ErrorPacket),
                    {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 从技能库中学习
learn_from_base(Player, SkillId) ->
    try
        HorseData  = Player#player.horse,
        HorseSkill = HorseData#horse_data.skill,
        UserId = Player#player.user_id,
        Result = 
            case data_horse:get_horse_skill(SkillId) of
                #rec_horse_skill{type = Type, lv = NewSkillLv} ->
                    case lists:keyfind(Type, #horse_skill.type, HorseSkill) of
                        #horse_skill{skill_id = OldSkillId} ->
                            case data_horse:get_horse_skill(OldSkillId) of
                                #rec_horse_skill{lv = OldSkillLv} when OldSkillLv =< NewSkillLv ->
                                    EquipList = Player#player.equip,
                                    upgrade_skill(UserId, EquipList, SkillId);
                                _ ->
                                    {?error, ?TIP_HORSE_SKILL}
                            end;
                        _ ->
                            {?error, ?TIP_COMMON_BAD_ARG}
                    end;
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end,
        case Result of
            {?ok, EquipList2, GoodsPacket} ->
                OkPacket = message_api:msg_notice(?TIP_HORSE_SKILL_CHANGE_SUCCESS),
                misc_packet:send(UserId, <<GoodsPacket/binary, OkPacket/binary>>),
                {?ok, Player#player{equip = EquipList2}};
            {?error, ErrorCode} ->
                {?error, ErrorCode}
        end
    catch
        X:Y ->
            ?MSG_ERROR("~p:~p:~p", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG}
    end.

%% 替换坐骑技能
upgrade_skill_base(Player, GoodsList) ->
    HorseData = Player#player.horse,
    HorseSkill = HorseData#horse_data.skill,
    Info = Player#player.info,
    Lv = Info#info.lv,
    {NewHorseSkill, Packet} = upgrade_skill_list(Lv, HorseSkill, GoodsList, <<>>),
    NewHorseData = HorseData#horse_data{skill = NewHorseSkill},
    {Player#player{horse = NewHorseData}, Packet}.
upgrade_skill_list(Lv, HorseSkill, [#goods{type = ?CONST_GOODS_TYPE_EQUIP,
                                              sub_type = ?CONST_GOODS_EQUIP_HORSE, 
                                              exts = #g_equip{skill_id = SkillId}}|Tail], OldPacket) ->
    case upgrade_skill_base(Lv, HorseSkill, SkillId) of
        {?ok, HorseSkill, Packet} ->
            upgrade_skill_list(Lv, HorseSkill, Tail, <<OldPacket/binary, Packet/binary>>);
        _ ->
            upgrade_skill_list(Lv, HorseSkill, Tail, OldPacket)
    end;
upgrade_skill_list(Lv, HorseSkill, [_|Tail], OldPacket) ->
    upgrade_skill_list(Lv, HorseSkill, Tail, OldPacket);
upgrade_skill_list(_Lv, HorseSkill, [], Packet) ->
    {HorseSkill, Packet}.
    
upgrade_skill(UserId, EquipList, SkillId) ->
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            Horse = erlang:element(?CONST_GOODS_EQUIP_HORSE, GoodsTuple),
            case Horse of
                #mini_goods{} ->
                    Ext = Horse#mini_goods.exts,
                    Ext2 = Ext#g_equip{skill_id = SkillId},
                    Horse2 = Horse#mini_goods{exts = Ext2},
                    GoodsTuple2 = erlang:setelement(?CONST_GOODS_EQUIP_HORSE, GoodsTuple, Horse2),
                    EquipCtn2 = EquipCtn#ctn{goods = GoodsTuple2},
                    EquipList2 = [{{UserId, ?CONST_GOODS_CTN_EQUIP_PLAYER}, EquipCtn2}|EquipList],
                    Packet = goods_api:msg_goods_sc_goods_equip_info(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, Horse2, ?CONST_SYS_FALSE),
                    {?ok, EquipList2, Packet};
                _ ->
                    {?error, ?TIP_COMMON_BAD_ARG}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

lv_up_skill(Player, SkillId, Type) ->
    case chk_upgrade_skill(Player, SkillId) of
        {?ok, HorseSkill, _, OldSkillId} ->
            Cost1 = 
                case data_horse:get_horse_skill(SkillId) of
                    #rec_horse_skill{skill_book = GoodsId} ->
                        case data_mall:get_mall({3, GoodsId}) of
                            #rec_mall{c_price = CostT} ->
                                CostT;
                            _ ->
                                0
                        end;
                    _ ->
                        0
                end,
            Cost2 = 
                case data_horse:get_horse_skill(OldSkillId) of
                    #rec_horse_skill{skill_book = OldGoodsId} ->
                        case data_mall:get_mall({3, OldGoodsId}) of
                            #rec_mall{c_price = OldCostT} ->
                                OldCostT;
                            _ ->
                                0
                        end;
                    _ ->
                        0
                end,
            Cost = Cost1 - Cost2,
%%             ?MSG_ERROR("[~p|~p|~p|~p|~p]", [Cost1, Cost2, Cost1 - Cost2, OldSkillId, SkillId]),
            case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, Cost, ?CONST_COST_HORSE_SKILL_LV_UP) of
                ?ok ->
                    Info = Player#player.info,
                    Lv = Info#info.lv,
                    case upgrade_skill_base(Lv, HorseSkill, SkillId) of
                        {?ok, NewHorseSkill, Packet} ->
%%                             TipPacket = message_api:msg_notice(?TIP_HORSE_STRENGTH_LV_UP),
                            misc_packet:send(Player#player.user_id, Packet),
                            HorseData = Player#player.horse,
                            NewHorseData = HorseData#horse_data{skill = NewHorseSkill},
                            Player2 = Player#player{horse = NewHorseData},
                            case Type of
                                ?CONST_SYS_TRUE ->
                                    learn_from_base(Player2, SkillId);
                                _ ->
                                    Player2
                            end;
                        {{?error, ErrorCode}, _HorseSkill, _} ->
                            {?error, ErrorCode}
                    end;
                {?error, _ErrorCode} ->
                    ?error
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 检查坐骑技能
chk_upgrade_skill(Player, SkillId) ->
    Info = Player#player.info,
    Lv = Info#info.lv,
    HorseData = Player#player.horse,
    HorseSkill = HorseData#horse_data.skill,
    case data_horse:get_horse_skill(SkillId) of
        #rec_horse_skill{type = Type, lv = NewLv} ->
            case lists:keyfind(Type, #horse_skill.type, HorseSkill) of
                #horse_skill{skill_id = OldSkillId} ->
                    case data_horse:get_horse_skill(OldSkillId) of
                        #rec_horse_skill{lv = OldLv} when OldLv < NewLv andalso NewLv =< Lv ->
                            {?ok, HorseSkill, Lv, OldSkillId};
                        #rec_horse_skill{lv = OldLv} when OldLv < NewLv ->
                            {?error, ?TIP_HORSE_LV_NOT_ENOUGH};
                        _ ->
                            {?error, ?TIP_HORSE_SKILL}
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
pack_all([#horse_skill{skill_id = HorseSKillId}|Tail], OldPacket) ->
    Packet = horse_api:msg_sc_skill_have(HorseSKillId),
    pack_all(Tail, <<OldPacket/binary, Packet/binary>>);
pack_all([], Packet) ->
    Packet.

