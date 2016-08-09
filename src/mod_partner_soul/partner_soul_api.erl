%% Author: Administrator
%% Created: 2014-2-24
%% Description: TODO: Add description to partner_soul_api
-module(partner_soul_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([create_partner_soul/0,
		 get_soul_skill_info/2, 
		 refresh_attr_partner_soul_player/1,
		 refresh_attr_partner_star_player/1,
		
		refresh_attr_soul_partner/2,
		refresh_attr_star_partner/2
		]).
-export([msg_sc_upgrade_soul/3,
		 msg_sc_upgrade_star/2,
		 msg_sc_inherit/2,
		 msg_sc_partner_soul_info/4,
		 msg_sc_soul_attr/4]).
-export([upgrade_partner_soul/3, upgrade_partner_star/3, a/1, test/1, test1/1, test2/1]).

%%
%% API Functions
%%
%% 初始化将魂和将星等级
create_partner_soul() ->
	#partner_soul{lv = 0, exp = 0, star_lv = 0, skill_lv = 0, skill_id = 0}.

%%-------------------------------------------------------------------------------------------------
%% 刷新主角将魂/将星属性
%%-------------------------------------------------------------------------------------------------
refresh_attr_partner_soul_player(Player) ->
	Info			= Player#player.info,
	PartnerSoul		= Player#player.partner_soul,
	PartnerSoulLv	= PartnerSoul#partner_soul.lv,
    Pro 			= Info#info.pro,
	case data_partner_soul:get_partner_soul({PartnerSoulLv, Pro}) of
		#rec_partner_soul{hp_max = HpMax, force_attack = ForceAttack, force_def = ForceDef, magic_attack = MagicAttack, magic_def= MagicDef,
						  speed = Speed, hit = Hit, dodge = Dodge, crit = Crit, parry = Parry, resist = Resist, crit_h = CritH,
						  r_crit = RCrit, r_parry = RParry, i_parry_h = IParryH, parry_h = ParryH, r_crit_h= RCritH,
						  r_resist = RResist, r_resist_h = RResistH, resist_h = ResistH} ->
			AttrSecond = #attr_second{hp_max = HpMax, force_attack = ForceAttack, force_def = ForceDef, magic_attack = MagicAttack, 
									  magic_def= MagicDef, speed = Speed},
			AttrElite  = #attr_elite{hit = Hit, dodge = Dodge, crit = Crit, parry = Parry, resist = Resist, crit_h = CritH,
						  r_crit = RCrit, parry_r_h = ParryH, r_parry = RParry, i_parry_h = IParryH, r_crit_h= RCritH,
						  r_resist = RResist, r_resist_h = RResistH, resist_h = ResistH},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite};
		_ ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite}
	end.

refresh_attr_partner_star_player(Player) ->
	PartnerSoul		= Player#player.partner_soul,
	PartnerStarLv	= PartnerSoul#partner_soul.star_lv,
	case data_partner_soul:get_partner_star(PartnerStarLv) of
		#rec_partner_star{force = Force, fate = Fate, magic = Magic} ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{force = Force, fate = Fate, magic = Magic, attr_second = AttrSecond, attr_elite = AttrElite};
		_ ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite}
	end.
%%-------------------------------------------------------------------------------------------------
%% 刷新武将将魂/将星属性
%%-------------------------------------------------------------------------------------------------
refresh_attr_soul_partner(Pro, Partner) ->
	PartnerSoul			= Partner#partner.partner_soul,
	?MSG_DEBUG("~n 555555555 =~p", [PartnerSoul]),
	PartnerSoulLv		= PartnerSoul#partner_soul.lv,
	case data_partner_soul:get_partner_soul({PartnerSoulLv, Pro}) of
		#rec_partner_soul{hp_max = HpMax, force_attack = ForceAttack, force_def = ForceDef, magic_attack = MagicAttack, magic_def= MagicDef,
						  speed = Speed, hit = Hit, dodge = Dodge, crit = Crit, parry = Parry, resist = Resist, crit_h = CritH,
						  r_crit = RCrit, r_parry = RParry, i_parry_h = IParryH, parry_h = ParryH, r_crit_h= RCritH,
						  r_resist = RResist, r_resist_h = RResistH, resist_h = ResistH} ->
			AttrSecond = #attr_second{hp_max = HpMax, force_attack = ForceAttack, force_def = ForceDef, magic_attack = MagicAttack, 
									  magic_def= MagicDef, speed = Speed},
			AttrElite  = #attr_elite{hit = Hit, dodge = Dodge, crit = Crit, parry = Parry, resist = Resist, crit_h = CritH,
						  r_crit = RCrit, parry_r_h = ParryH, r_parry = RParry, i_parry_h = IParryH, r_crit_h= RCritH,
						  r_resist = RResist, r_resist_h = RResistH, resist_h = ResistH},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite};
		_ ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite}
	end.

%% 获取武将将星属性
refresh_attr_star_partner(_Pro, Partner) ->
	PartnerSoul		= Partner#partner.partner_soul,
	PartnerStarLv	= PartnerSoul#partner_soul.star_lv,
	case data_partner_soul:get_partner_star(PartnerStarLv) of
		#rec_partner_star{force = Force, fate = Fate, magic = Magic} ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{force = Force, fate = Fate, magic = Magic, attr_second = AttrSecond, attr_elite = AttrElite};
		_ ->
			AttrSecond = #attr_second{},
			AttrElite  = #attr_elite{},
			#attr{fate = 0, force = 0, magic = 0, attr_second = AttrSecond, attr_elite = AttrElite}
	end.

%%-------------------------------------------------------------------------------------------------
%% GM命令
%%-------------------------------------------------------------------------------------------------
%% 升级将魂
upgrade_partner_soul(Player, 0, Lv) ->
	Pro				=(Player#player.info)#info.pro,
	PartnerSoul		= Player#player.partner_soul,
	SkillId			= partner_soul_mod:get_init_skill_id(Pro),
	NewPartnerSoul 	= PartnerSoul#partner_soul{lv = Lv, exp = 0, skill_id = SkillId},
	Player1  		= Player#player{partner_soul = NewPartnerSoul},
	Player2  		= player_attr_api:refresh_attr_partner_soul(Player1),
	Packet		    = msg_sc_upgrade_soul(0, Lv, 0),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player2};
upgrade_partner_soul(Player, PartnerId, Lv) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} -> 
			Pro				= PartnerInfo#partner.pro,
			SkillId			= partner_soul_mod:get_init_skill_id(Pro),
			PartnerSoul		= PartnerInfo#partner.partner_soul,
			NewPartnerSoul 	= PartnerSoul#partner_soul{lv = Lv, exp = 0, skill_id = SkillId},
			NewPartnerInfo 	= PartnerInfo#partner{partner_soul = NewPartnerSoul},
			Player1			= partner_mod:update_partner(Player, NewPartnerInfo),
			Player2  		= partner_api:refresh_attr_partner_soul(Player1),
			Packet		    = msg_sc_upgrade_soul(PartnerId, Lv, 0),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player2};
		{?error, ErrorCode} ->
			TipPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 升级将星
upgrade_partner_star(Player, 0, Lv) ->
	Pro					=(Player#player.info)#info.pro,
	SkillId				= partner_soul_mod:get_init_skill_id(Pro),
	PartnerSoul			= Player#player.partner_soul,
	SkillLv				= Lv div 10,
	NewPartnerSoul		= PartnerSoul#partner_soul{star_lv = Lv, skill_lv = SkillLv, skill_id = SkillId},
	Player1				= Player#player{partner_soul = NewPartnerSoul},
	Player2				= player_attr_api:refresh_attr_partner_star(Player1),
	{?ok, Player2};
upgrade_partner_star(Player, PartnerId, Lv) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, PartnerInfo} -> 
			Pro					= PartnerInfo#partner.pro,
			SkillId				= partner_soul_mod:get_init_skill_id(Pro),
			PartnerSoul			= PartnerInfo#partner.partner_soul,
			SkillLv				= Lv div 10,							%% 更新将星技等级和刷新属性
			NewPartnerSoul		= PartnerSoul#partner_soul{star_lv = Lv, skill_lv = SkillLv, skill_id = SkillId},
			NewPartnerInfo		= PartnerInfo#partner{partner_soul =  NewPartnerSoul},
			
			Player2 			= partner_mod:update_partner(Player, NewPartnerInfo),
			Player3  			= partner_api:refresh_attr_partner_star(Player2),
			{?ok, Player3};
		{?error, ErrorCode} -> 
			TipPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

get_soul_skill_info(_,_) ->
	{0,0};


get_soul_skill_info(Player, 0) ->
	PartnerSoul		= Player#player.partner_soul,
	SkillLv			= PartnerSoul#partner_soul.skill_lv,
	SkillId			= PartnerSoul#partner_soul.skill_id,
	{SkillId, SkillLv};
get_soul_skill_info(Player, PartnerId) ->
	case partner_api:get_partner_by_id(Player, PartnerId) of
		{?ok, Partner} ->
			PartnerSoul			= Partner#partner.partner_soul,
			SkillLv				= PartnerSoul#partner_soul.skill_lv,
			SkillId				= PartnerSoul#partner_soul.skill_id,
			{SkillId, SkillLv};
		_ ->
			{0, 0}
	end.
%%
%% Local Functions
%%
%%-------------------------------------------------------------------------------------------------
%% 将魂协议返回
%%-------------------------------------------------------------------------------------------------
%% 请求将魂信息
msg_sc_partner_soul_info(PartnerId, SoulLv, Exp, StarLv) ->
	misc_packet:pack(?MSG_ID_PARTNER_SOUL_SC_INFO, ?MSG_FORMAT_PARTNER_SOUL_SC_INFO, [PartnerId, SoulLv, Exp, StarLv]).

%% 升级将魂返回
msg_sc_upgrade_soul(Id, Lv, Exp) ->
	misc_packet:pack(?MSG_ID_PARTNER_SOUL_SC_UPGRADE, ?MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE, [Id, Lv, Exp]).

%% 升级将星返回
msg_sc_upgrade_star(Id, Lv) ->
	misc_packet:pack(?MSG_ID_PARTNER_SOUL_SC_UPGRADE_STAR, ?MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE_STAR, [Id, Lv]).

%% 将魂/将星继承返回
msg_sc_inherit(ToPartnerId, FromPartnerId) ->
	misc_packet:pack(?MSG_ID_PARTNER_SOUL_SC_INHERIT, ?MSG_FORMAT_PARTNER_SOUL_SC_INHERIT, [ToPartnerId, FromPartnerId]).

%% 将魂属性返回
msg_sc_soul_attr(UserId, PartnerId, Power, AttrData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SOUL_SC_ATTR, ?MSG_FORMAT_PARTNER_SOUL_SC_ATTR, [UserId, PartnerId, Power]++ AttrData).
%%
%% test Functions
%%
a(UserId) ->
	{?ok, Player, _}  = player_api:get_player_first(UserId),
	Flag = is_record(Player, player),
	?MSG_DEBUG("~n Player=~p, ~n Flag =~p ~n index=~p", [Player, Flag, #player.partner_soul]).

test(UserId) ->
	{?ok, PartnerData}		= player_api:get_player_field(UserId, #player.partner),
	?MSG_DEBUG("~n PartnerData=~p", [PartnerData]),
	PartnerList		= PartnerData#partner_data.list,
	?MSG_DEBUG("~n PartnerList=~p", [PartnerList]).

test1(UserId) ->
	PartnerSoul		= player_api:get_player_field(UserId, #player.partner_soul),
	?MSG_DEBUG("~n PartnerSoul=~p", [PartnerSoul]).

test2(UserId) ->
	{?ok, Player, _}  = player_api:get_player_first(UserId),
	?MSG_DEBUG("~n 2222222222222222 Player=~p", [Player]),
	partner_soul_mod:upgrade_partner_soul(Player, 0).
