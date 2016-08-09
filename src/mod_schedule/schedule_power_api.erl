%%% 战力计算
-module(schedule_power_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([login/1, packet_all/1, confirm/1, change_list_to_attr/1, attr_to_power/2]).
-export([packet_ability/1, packet_assemble/1,
         packet_base/1, packet_culti/1, packet_equip/2, 
         packet_guild/1, packet_horse/1, packet_mind/1, packet_position/1,
         packet_total/1, packet_equip/1, packet_equip_horse/3, packet_stone/1,
         packet_send/4, packet_send/2]).
-export([do_change_mind/3, do_lv_up/1, do_upgrade_ability/1, do_upgrade_position/1,
         do_upgrade_guild_magic/1, do_upgrade_culti/1, do_change_assemble/1, 
         do_change_equip/1, do_update_horse/1, do_update_weapon/1, do_update_fashion/1,
         do_update_stone/1]).

%%
%% API Functions
%%
%% 登录
login(Player) ->
    Packet = packet_all(Player),
    {Player, Packet}.

%% 心法
do_change_mind(Player, 1, _) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    MindPacket = packet_mind(Player),
    misc_packet:send(UserId, <<TotalPacket/binary, MindPacket/binary>>);
do_change_mind(Player, 2, PartnerId) ->
    UserId = Player#player.user_id,
    case partner_api:get_partner_by_id(Player, PartnerId) of
        {?ok, Partner} ->
            TotalPacket = packet_total_p(Partner),
            MindPacket = packet_mind_p(Partner),
            misc_packet:send(UserId, <<TotalPacket/binary, MindPacket/binary>>);
        {?error, _} ->
            ?ok
    end.

%% 基础属性
do_lv_up(Player) ->
    UserId = Player#player.user_id,
    Packet = packet_all(Player),
    misc_packet:send(UserId, Packet).

%% 升级奇门
do_upgrade_ability(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_ability(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_ability_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 升级官衔
do_upgrade_position(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_position(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_position_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 升级术法
do_upgrade_guild_magic(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_guild(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_guild_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 升级修为
do_upgrade_culti(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_culti(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_culti_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 换组合
do_change_assemble(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_assemble(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_assemble_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 强化
do_change_equip(Player) ->
    UserId = Player#player.user_id,
    TotalPacket = packet_total(Player),
    PlayerPacket = packet_equip(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_equip_p(Player, PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 坐骑更新
do_update_horse(Player) ->
    UserId = Player#player.user_id,
    TotalPacket  = packet_total(Player),
    {_Power, PlayerPacket} = packet_horse(Player),
    misc_packet:send(UserId, <<PlayerPacket/binary, TotalPacket/binary>>).

%% 神兵更新
do_update_weapon(Player) ->
    UserId = Player#player.user_id,
    TotalPacket  = packet_total(Player),
    PlayerPacket = packet_weapon(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_weapon_p(PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, Packet).

%% 时装更新
do_update_fashion(Player) ->
    UserId = Player#player.user_id,
    TotalPacket  = packet_total(Player),
    {_Power, Packet} = packet_fashion(Player),
    misc_packet:send(UserId, <<Packet/binary, TotalPacket/binary>>).

%% 宝石更新
do_update_stone(Player) ->
    UserId = Player#player.user_id,
    TotalPacket  = packet_total(Player),
    PlayerPacket = packet_stone(Player),
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_stone_p(Player, PartnerList, <<PlayerPacket/binary, TotalPacket/binary>>),
    misc_packet:send(UserId, <<Packet/binary, TotalPacket/binary>>).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

packet_all(Player) ->
    PlayerPacket = packet_player(Player),
    PartnerPacket = packet_partners(Player),
    <<PlayerPacket/binary, PartnerPacket/binary>>.

packet_player(Player) ->
    PlayerPowerPacket = packet_total(Player),
    BasePowerPacket   = packet_base(Player),
    {HorsePower, HorsePowerPacket} = packet_horse(Player),
    EquipPowerPacket  = packet_equip(Player, HorsePower),
    {_, FashionPowerPacket}  = packet_fashion(Player),
    MindPowerPacket   = packet_mind(Player),
    PositionPowerPacket = packet_position(Player),
    AbilityPowerPacket  = packet_ability(Player),
    GuildPowerPacket    = packet_guild(Player),
    CultiPowerPacket    = packet_culti(Player),
    AssemblePowerPacket = packet_assemble(Player),
    WeaponPowerPacket   = packet_weapon(Player),
    {_, StonePowerPacket}   = packet_stone(Player),
    <<PlayerPowerPacket/binary, BasePowerPacket/binary, EquipPowerPacket/binary, 
      HorsePowerPacket/binary, MindPowerPacket/binary, PositionPowerPacket/binary,
      AbilityPowerPacket/binary, GuildPowerPacket/binary,
      CultiPowerPacket/binary, FashionPowerPacket/binary,
      AssemblePowerPacket/binary, WeaponPowerPacket/binary,
      StonePowerPacket/binary>>.

packet_partners(Player) ->
    PartnerList = partner_api:get_out_partner(Player),
    Packet = packet_partner(Player, PartnerList, <<>>),
    if
        is_binary(Packet) ->
            Packet;
        ?true ->
            <<>>
    end.

packet_partner(Player, [Partner|Tail], OldPacket) ->
    Packet = packet_partner(Player, Partner),
    NewPacket = <<OldPacket/binary, Packet/binary>>,
    packet_partner(Player, Tail, NewPacket);
packet_partner(_Player, [], Packet) ->
    Packet.

packet_partner(Player, Partner) ->
    PartnerPowerPacket = packet_total_p(Partner),
    BasePowerPacket    = packet_base_p(Partner),
    EquipPowerPacket   = packet_equip_p(Player, Partner),
    MindPowerPacket    = packet_mind_p(Partner),
    PositionPowerPacket = packet_position_p(Partner),
    AbilityPowerPacket  = packet_ability_p(Partner),
    GuildPowerPacket    = packet_guild_p(Partner),
    CultiPowerPacket    = packet_culti_p(Partner),
    AssemblePowerPacket = packet_assemble_p(Partner),
    WeaponPowerPacket   = packet_weapon_p(Partner),
    {_, StonePowerPacket}   = packet_stone_p(Player, Partner),
    <<PartnerPowerPacket/binary, BasePowerPacket/binary, EquipPowerPacket/binary, 
      MindPowerPacket/binary, PositionPowerPacket/binary,
      AbilityPowerPacket/binary, GuildPowerPacket/binary, 
      CultiPowerPacket/binary, 
      AssemblePowerPacket/binary, WeaponPowerPacket/binary,
      StonePowerPacket/binary>>.

packet_send(packet_equip, Player, HorsePower, _PartnerId) ->
    Packet = packet_equip(Player, HorsePower),
    packet_send_2(Player, Packet);
packet_send(packet_equip_horse, Player, Idx, PartnerId) ->
    case packet_equip_horse(Player, Idx, PartnerId) of
        {_, Packet} ->
            packet_send_2(Player, Packet);
        Packet ->
            packet_send_2(Player, Packet)
    end.

packet_send(packet_base, Player) ->
    Packet = packet_base(Player),
    packet_send_2(Player, Packet);
packet_send(packet_horse, Player) ->
    Packet = packet_horse(Player),
    packet_send_2(Player, Packet);
packet_send(packet_mind, Player) ->
    Packet = packet_mind(Player),
    packet_send_2(Player, Packet);
packet_send(packet_position, Player) ->
    Packet = packet_position(Player),
    packet_send_2(Player, Packet);
packet_send(packet_ability, Player) ->
    Packet = packet_ability(Player),
    packet_send_2(Player, Packet);
packet_send(packet_guild, Player) ->
    Packet = packet_guild(Player),
    packet_send_2(Player, Packet);
packet_send(packet_culti, Player) ->
    Packet = packet_culti(Player),
    packet_send_2(Player, Packet);
packet_send(packet_assemble, Player) ->
    Packet = packet_assemble(Player),
    packet_send_2(Player, Packet);
packet_send(packet_weapon, Player) ->
    Packet = packet_weapon(Player),
    packet_send_2(Player, Packet);
packet_send(packet_fashion, Player) ->
    Packet = packet_fashion(Player),
    packet_send_2(Player, Packet);
packet_send(packet_stone, Player) ->
    Packet = packet_stone(Player),
    packet_send_2(Player, Packet);
packet_send(packet_total, Player) ->
    Packet = packet_total(Player),
    packet_send_2(Player, Packet).

packet_send_2(Player, Packet) ->
    UserId = Player#player.user_id,
    misc_packet:send(UserId, Packet).

%% 个人总战力
packet_total(Player) ->
    Attr = Player#player.attr,
    TotalPower = player_attr_api:caculate_power(Attr),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_TOTAL, 0, TotalPower).
packet_total_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Attr = Partner#partner.attr,
    TotalPower = player_attr_api:caculate_power(Attr),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_TOTAL, PartnerId, TotalPower).

%% 基础属性
packet_base(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    
    % 等级
    LvAttr    = AttrGroup#attr_group.lv,
    {_LvAttr2, LvPower}  = attr_to_power(LvAttr, Pro),
    % 培养
    TrainAttr = AttrGroup#attr_group.train,
    {_TrainAttr2, TrainPower}  = attr_to_power(TrainAttr, Pro),
    % 破阵
    TowerAttr = AttrGroup#attr_group.tower,
    {_TowerAttr2, TowerPower}  = attr_to_power(TowerAttr, Pro),
    
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_BASE, 0, LvPower+TrainPower+TowerPower).
packet_base_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    
    % 等级
    LvAttr    = AttrGroup#attr_group.lv,
    {_LvAttr2, LvPower}  = attr_to_power(LvAttr, Pro),
    % 培养
    TrainAttr = AttrGroup#attr_group.train,
    {_TrainAttr2, TrainPower}  = attr_to_power(TrainAttr, Pro),
    % 破阵
    TowerAttr = AttrGroup#attr_group.tower,
    {_TowerAttr2, TowerPower}  = attr_to_power(TowerAttr, Pro),
    
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_BASE, PartnerId, LvPower+TrainPower+TowerPower).

packet_equip_horse(Player, ?CONST_GOODS_EQUIP_HORSE, 0) ->
    packet_horse(Player);
packet_equip_horse(_Player, ?CONST_GOODS_EQUIP_HORSE, _PartnerId) ->
    <<>>;
packet_equip_horse(Player, _, 0) ->
    packet_equip(Player);
packet_equip_horse(Player, _, PartnerId) ->
    case partner_api:get_partner_by_id(Player, PartnerId) of
        {?ok, Partner} ->
            packet_equip_p(Player, Partner);
        _ ->
            <<>>
    end.

%% 装备
packet_equip(Player, HorsePower) ->
    Info         = Player#player.info,
    Pro          = Info#info.pro,
    AttrGroup    = Player#player.attr_group,
    % 装备
    EquipAttr    = AttrGroup#attr_group.equip,
    {_EquipAttr2, EquipPower}  = attr_to_power(EquipAttr, Pro),
    % 套装
    AttrRateGroup = Player#player.attr_rate_group,
    SuitAttr      = AttrRateGroup#attr_rate_group.suit,
    FashionAttrList = ctn_equip_api:refresh_attr_rate_group(Player), 
    AttrSum       = Player#player.attr_sum,
    {_SuitAttr2, SuitPower}  = attr_to_power(SuitAttr++FashionAttrList, Pro, AttrSum),
    % 时装
    {FashionPower, _Packet} = packet_fashion(Player),
    % 宝石
    {StonePower, _} = packet_stone(Player),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_EQUIP, 0, SuitPower+EquipPower-HorsePower-FashionPower-StonePower).
packet_equip(Player) ->
    Info         = Player#player.info,
    Pro          = Info#info.pro,
    AttrGroup    = Player#player.attr_group,
    % 装备
    EquipAttr    = AttrGroup#attr_group.equip,
    {_EquipAttr2, EquipPower}  = attr_to_power(EquipAttr, Pro),
    % 套装
    AttrRateGroup = Player#player.attr_rate_group,
    SuitAttr      = AttrRateGroup#attr_rate_group.suit,
    FashionAttrList = ctn_equip_api:refresh_attr_rate_group(Player), 
    AttrSum       = Player#player.attr_sum,
    {_SuitAttr2, SuitPower}  = attr_to_power(SuitAttr++FashionAttrList, Pro, AttrSum),
    % 坐骑
    HorsePower  = handle_horse(Player),
    % 时装
    {FashionPower, _Packet} = packet_fashion(Player),
    % 宝石
    {StonePower, _} = packet_stone(Player),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_EQUIP, 0, SuitPower+EquipPower-HorsePower-FashionPower-StonePower).
packet_equip_p(Player, [Partner|Tail], OldPacket) ->
    Packet = packet_equip_p(Player, Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_equip_p(Player, Tail, NewPacket);
packet_equip_p(_Player, [], Packet) ->
    Packet.
packet_equip_p(Player, Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    % 装备
    EquipAttr    = AttrGroup#attr_group.equip,
    {_EquipAttr2, EquipPower}  = attr_to_power(EquipAttr, Pro),
    % 套装
    AttrRateGroup = Partner#partner.attr_rate_group,
    SuitAttr      = AttrRateGroup#attr_rate_group.suit,
    AttrSum       = Partner#partner.attr_sum,
    {_SuitAttr2, SuitPower}  = attr_to_power(SuitAttr, Pro, AttrSum),
    % 坐骑
    HorsePower  = handle_horse_p(Player, Pro),
    % 宝石
    {StonePower, _} = packet_stone_p(Player, Partner),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_EQUIP, PartnerId, SuitPower+EquipPower-HorsePower-StonePower).

%% 坐骑
packet_horse(Player) ->
    Power  = handle_horse(Player),
    Packet = schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_HORSE, 0, Power),
    PartnerList = partner_api:get_out_partner(Player),
    Packet2 = packet_horse_2(Player, PartnerList, Packet),
    {Power, Packet2}.

packet_horse_2(Player, [#partner{partner_id = PartnerId, pro = Pro}|Tail], OldPacket) ->
    Power = handle_horse_p(Player, Pro),
    Packet = schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_HORSE, PartnerId, Power),
    packet_horse_2(Player, Tail, <<OldPacket/binary, Packet/binary>>);    
packet_horse_2(_, [], OldPacket) ->
    OldPacket.

%% 时装
packet_fashion(Player) ->
    Power = handle_fashion(Player),
    Packet = schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_FASHION, 0, Power),
    {Power, Packet}.

%% 
packet_stone(Player) ->
    Power = handle_stone(Player, 0),
    Packet = schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_STONE, 0, Power),
    {Power, Packet}.
packet_stone_p(Player, [Partner|Tail], OldPacket) ->
    {_Power, Packet} = packet_stone_p(Player, Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_stone_p(Player, Tail, NewPacket);
packet_stone_p(_Player, [], Packet) ->
    Packet.
packet_stone_p(Player, Partner) ->
    Power = handle_stone(Player, Partner),
    Packet = schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_STONE, Partner#partner.partner_id, Power),
    {Power, Packet}.

%% 星斗
packet_mind(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    MindAttr  = AttrGroup#attr_group.mind,
    {_MindAttr2, MindPower}  = attr_to_power(MindAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_MIND, 0, MindPower).
packet_mind_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    MindAttr  = AttrGroup#attr_group.mind,
    {_MindAttr2, MindPower}  = attr_to_power(MindAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_MIND, PartnerId, MindPower).

%% 官职
packet_position(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    PositionAttr    = AttrGroup#attr_group.position,
    {_PositionAttr2, PositionPower}  = attr_to_power(PositionAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_POSITION, 0, PositionPower).
packet_position_p([Partner|Tail], OldPacket) ->
    Packet = packet_position_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary>>,
    packet_position_p(Tail, NewPacket);
packet_position_p([], Packet) ->
    Packet.
packet_position_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    PositionAttr    = AttrGroup#attr_group.position,
    {_PositionAttr2, PositionPower}  = attr_to_power(PositionAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_POSITION, PartnerId, PositionPower).

%% 奇门
packet_ability(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    AbiAttr   = AttrGroup#attr_group.ability,
    {_AbiAttr2, AbiPower}  = attr_to_power(AbiAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_ABILITY, 0, AbiPower).
packet_ability_p([Partner|Tail], OldPacket) ->
    Packet = packet_ability_p(Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_ability_p(Tail, NewPacket);
packet_ability_p([], Packet) ->
    Packet.
packet_ability_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    AbiAttr   = AttrGroup#attr_group.ability,
    {_AbiAttr2, AbiPower}  = attr_to_power(AbiAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_ABILITY, PartnerId, AbiPower).

%% 军团技能
packet_guild(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    GuildAttr = AttrGroup#attr_group.guild,
    {_GuildAttr2, GuildPower}  = attr_to_power(GuildAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_GUILD, 0, GuildPower).
packet_guild_p([Partner|Tail], OldPacket) ->
    Packet = packet_guild_p(Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_guild_p(Tail, NewPacket);
packet_guild_p([], Packet) ->
    Packet.
packet_guild_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    GuildAttr = AttrGroup#attr_group.guild,
    {_GuildAttr2, GuildPower}  = attr_to_power(GuildAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_GUILD, PartnerId, GuildPower).

%% 祭星
packet_culti(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrRateGroup = Player#player.attr_rate_group,
    CultiAttr     = AttrRateGroup#attr_rate_group.cultivation,
    AttrSum   = Player#player.attr_sum,
    {_CultiAttr2, CultiPower}  = attr_to_power(CultiAttr, Pro, AttrSum),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_CULTI, 0, CultiPower).
packet_culti_p([Partner|Tail], OldPacket) ->
    Packet = packet_culti_p(Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_culti_p(Tail, NewPacket);
packet_culti_p([], Packet) ->
    Packet.
packet_culti_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrRateGroup = Partner#partner.attr_rate_group,
    CultiAttr     = AttrRateGroup#attr_rate_group.cultivation,
    AttrSum   = Partner#partner.attr_sum,
    {_CultiAttr2, CultiPower}  = attr_to_power(CultiAttr, Pro, AttrSum),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_CULTI, PartnerId, CultiPower).

%% 组合技
packet_assemble(Player) -> 
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    AssembleAttr = AttrGroup#attr_group.assemble,
    AssembleAttr2 = change_list_to_attr(AssembleAttr),
    {_AssembleAttr3, AssemblePower}  = attr_to_power(AssembleAttr2, Pro),
    
    LookForAttr = AttrGroup#attr_group.lookfor,
    LookForAttr2 = change_list_to_attr(LookForAttr),
    {_LookForAttr3, LookForPower}  = attr_to_power(LookForAttr2, Pro),
    
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_ASSEMBLE, 0, AssemblePower+LookForPower).
packet_assemble_p([Partner|Tail], OldPacket) ->
    Packet = packet_assemble_p(Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_assemble_p(Tail, NewPacket);
packet_assemble_p([], Packet) ->
    Packet.
packet_assemble_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro        = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    AssembleAttr = AttrGroup#attr_group.assemble,
    AssembleAttr2 = change_list_to_attr(AssembleAttr),
    {_AssembleAttr3, AssemblePower}  = attr_to_power(AssembleAttr2, Pro),
    
    LookForAttr = AttrGroup#attr_group.lookfor,
    LookForAttr2 = change_list_to_attr(LookForAttr),
    {_LookForAttr3, LookForPower}  = attr_to_power(LookForAttr2, Pro),
    
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_ASSEMBLE, PartnerId, AssemblePower+LookForPower).

%% 神兵
packet_weapon(Player) ->
    Info      = Player#player.info,
    Pro       = Info#info.pro,
    AttrGroup = Player#player.attr_group,
    WeaponAttr = AttrGroup#attr_group.weapon,
    {_WeaponAttr2, WeaponPower}  = attr_to_power(WeaponAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_WEAPON, 0, WeaponPower).
packet_weapon_p([Partner|Tail], OldPacket) ->
    Packet = packet_weapon_p(Partner),
    Packet2 = packet_total_p(Partner),
    NewPacket = <<OldPacket/binary, Packet/binary, Packet2/binary>>,
    packet_weapon_p(Tail, NewPacket);
packet_weapon_p([], Packet) ->
    Packet.
packet_weapon_p(Partner) ->
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    AttrGroup = Partner#partner.attr_group,
    WeaponAttr = AttrGroup#attr_group.weapon,
    {_WeaponAttr2, WeaponPower}  = attr_to_power(WeaponAttr, Pro),
    schedule_api:msg_sc_power(?CONST_SCHEDULE_POWER_TYPE_WEAPON, PartnerId, WeaponPower).

%%
%% Local Functions
%%

change_list_to_attr(AttrList) ->
    player_attr_api:attr_plus(confirm(#attr{}), AttrList).

attr_to_power(?null, _) ->
    {confirm(#attr{}), 0};
attr_to_power(Attr, Pro) when is_record(Attr, attr) ->
    Attr2 = player_attr_api:attr_convert(Attr, Pro),
    Attr3 = confirm(Attr2),
    Power = player_attr_api:caculate_power(Attr3),
    {Attr3, Power}.
attr_to_power([], _, _BaseAttr) -> 
    Attr = #attr{},
    Attr2 = confirm_2(Attr),
    {Attr2, 0};
attr_to_power(AttrList, _Pro, BaseAttr) ->
    BaseAttr3 = confirm_2(BaseAttr),
    Attr = attr_multi(BaseAttr3, AttrList),
    Power = player_attr_api:caculate_power(Attr),
    {Attr, Power}.

confirm(#attr{attr_second = null} = Attr) ->
    confirm(Attr#attr{attr_second = #attr_second{}});
confirm(#attr{attr_elite = null} = Attr) ->
    confirm(Attr#attr{attr_elite = #attr_elite{}});
confirm(Attr) when is_record(Attr, attr) ->
    Attr;
confirm(_) ->
    confirm(#attr{}).
confirm_2(#attr{attr_second = null} = Attr) ->
    confirm_2(Attr#attr{attr_second = #attr_second{}});
confirm_2(#attr{attr_elite = null} = Attr) ->
    confirm_2(Attr#attr{attr_elite = #attr_elite{}});
confirm_2(Attr) when is_record(Attr, attr) ->
    Attr#attr{attr_elite = #attr_elite{}};
confirm_2(_) ->
    confirm_2(#attr{}).

attr_multi(BaseAttr, AttrList) ->
    Attr = confirm_2(#attr{}),
    attr_multi(BaseAttr, AttrList, Attr).
attr_multi(BaseAttr, [{Type, Factor, Base}|Tail], Attr) 
  when Type =< ?CONST_PLAYER_MAX_ATTR_1 ->
    Idx             = Type + 1,
    Element         = erlang:element(Idx, BaseAttr),
    NewElement      = Element * Factor div Base,
    Attr2 = erlang:setelement(Idx, Attr, NewElement),
    attr_multi(BaseAttr, Tail, Attr2);
attr_multi(BaseAttr, [{Type, Factor, Base}|Tail], Attr) 
  when Type =< ?CONST_PLAYER_MAX_ATTR_2 ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_1 + 1,
    AttrSecond      = BaseAttr#attr.attr_second,
    Element         = erlang:element(Idx, AttrSecond),
    NewElement      = Element * Factor div Base,
    AttrSecond2     = Attr#attr.attr_second,
    NewAttrSecond   = erlang:setelement(Idx, AttrSecond2, NewElement),
    Attr2 = Attr#attr{attr_second = NewAttrSecond},
    attr_multi(BaseAttr, Tail, Attr2);
attr_multi(BaseAttr, [{Type, Factor, Base}|Tail], Attr)
  when Type =< ?CONST_PLAYER_MAX_ATTR_ELITE ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_2 + 1,
    AttrElite       = BaseAttr#attr.attr_elite,
    Element         = erlang:element(Idx, AttrElite),
    NewElement      = Element * Factor div Base,
    AttrElite2      = Attr#attr.attr_elite,
    NewAttrElite    = erlang:setelement(Idx, AttrElite2, NewElement),
    Attr2           = Attr#attr{attr_elite = NewAttrElite},
    attr_multi(BaseAttr, Tail, Attr2);
attr_multi(_, _, Attr) ->
    Attr.

%% 处理坐骑的属性
handle_horse(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Pro = Info#info.pro,
    EquipList = Player#player.equip,
    HorseTrain = horse_api:get_horse_train(Player),
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            case erlang:element(?CONST_GOODS_EQUIP_HORSE, GoodsTuple) of
                #mini_goods{} = Goods ->
                    Attr  = ctn_equip_api:attr_plus_by_equip(UserId, HorseTrain, Goods, EquipCtn, confirm(#attr{})),
                    Attr2 = player_attr_api:attr_convert(Attr, Pro),
                    Power = player_attr_api:caculate_power(Attr2),
                    Power;
                _ ->
                    0
            end;
        {?error, ErrorCode} ->
            ?MSG_ERROR("e[~p]", [ErrorCode]),
            0
    end.
handle_horse_p(Player, PPro) ->
    UserId = Player#player.user_id,
    EquipList = Player#player.equip,
    HorseTrain = horse_api:get_horse_train(Player),
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            case erlang:element(?CONST_GOODS_EQUIP_HORSE, GoodsTuple) of
                #mini_goods{} = Goods ->
                    Attr  = ctn_equip_api:attr_plus_by_equip(UserId, HorseTrain, Goods, EquipCtn, confirm(#attr{})),
                    Attr2 = player_attr_api:attr_convert(Attr, PPro),
                    Power = player_attr_api:caculate_power(Attr2),
                    Power;
                _ ->
                    0
            end;
        {?error, ErrorCode} ->
            ?MSG_ERROR("e[~p]", [ErrorCode]),
            0
    end.

%% 处理时装属性
handle_fashion(Player) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Pro = Info#info.pro,
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
		{?ok, EquipCtn} ->
			GoodsTuple = EquipCtn#ctn.goods,
			Power1 = 
				case erlang:element(?CONST_GOODS_EQUIP_FUSION, GoodsTuple) of
					#mini_goods{} = Goods ->
						Exts = Goods#mini_goods.exts,
						FusionLv = Exts#g_equip.fusion_lv,
						AttrList = 
							case data_furnace:get_fusion_attr({?CONST_GOODS_EQUIP_FUSION, FusionLv}) of
								#rec_furnace_fashion_attr{attr_per = AttrListT} ->
									[{X1,X2,?CONST_SYS_NUMBER_TEN_THOUSAND}||{X1,X2}<-AttrListT];
								_ ->
									[]
							end,
						Attr = attr_multi(Player#player.attr_sum, AttrList),
						Attr2 = player_attr_api:attr_convert(Attr, Pro),
						player_attr_api:caculate_power(Attr2);
					_ ->
						0
				end,
			Power2 = 
				case erlang:element(?CONST_GOODS_EQUIP_FUSION_WEAPON, GoodsTuple) of
					#mini_goods{} = Goods1 ->
						Exts1 = Goods1#mini_goods.exts,
						FusionLv1 = Exts1#g_equip.fusion_lv,
						AttrList1 = 
							case data_furnace:get_fusion_attr({?CONST_GOODS_EQUIP_FUSION_WEAPON, FusionLv1}) of
								#rec_furnace_fashion_attr{attr_per = AttrListT1} ->
									[{X3,X4,?CONST_SYS_NUMBER_TEN_THOUSAND}||{X3,X4}<-AttrListT1];
								_ ->
									[]
							end,
						Attr3 = attr_multi(Player#player.attr_sum, AttrList1),
						Attr4 = player_attr_api:attr_convert(Attr3, Pro),
						player_attr_api:caculate_power(Attr4);
					_ ->
						0
				end,
			Power1 + Power2;
        {?error, ErrorCode} ->
            ?MSG_ERROR("e[~p]", [ErrorCode]),
            0
    end.

%% 处理时装属性
handle_stone(Player, 0) ->
    UserId = Player#player.user_id,
    Info = Player#player.info,
    Pro = Info#info.pro,
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PLAYER, UserId, 0, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            GoodsList = erlang:tuple_to_list(GoodsTuple),
            handle_stone(GoodsList, confirm(#attr{}), Pro);
        {?error, ErrorCode} ->
            ?MSG_ERROR("e[~p]", [ErrorCode]),
            0
    end;
handle_stone(Player, Partner) ->
    UserId = Player#player.user_id,
    PartnerId = Partner#partner.partner_id,
    Pro = Partner#partner.pro,
    EquipList = Player#player.equip,
    case ctn_equip_api:get_equip_ctn(?CONST_GOODS_CTN_EQUIP_PARTNER, UserId, PartnerId, EquipList) of
        {?ok, EquipCtn} ->
            GoodsTuple = EquipCtn#ctn.goods,
            GoodsList = erlang:tuple_to_list(GoodsTuple),
            handle_stone(GoodsList, confirm(#attr{}), Pro);
        {?error, ErrorCode} ->
            ?MSG_ERROR("e[~p]", [ErrorCode]),
            0
    end.

handle_stone([#mini_goods{} = MiniGoods|Tail], Attr, Pro) ->
    Exts = MiniGoods#mini_goods.exts,
    Goods = goods_api:mini_to_goods(MiniGoods),
    SoulList = furnace_api:trans_soul_id_value2(Goods#goods.sub_type, Goods#goods.color, Goods#goods.lv, Exts#g_equip.soul_list),
    Attr2 = player_attr_api:attr_plus(Attr, SoulList), 
    handle_stone(Tail, Attr2, Pro);
handle_stone([_|Tail], Attr, Pro) ->
    handle_stone(Tail, Attr, Pro);
handle_stone([], Attr, Pro) ->
    Attr2 = player_attr_api:attr_convert(Attr, Pro),
    Power = player_attr_api:caculate_power(Attr2),
    Power.
