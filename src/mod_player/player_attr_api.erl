%% Author: zero
%% Created: 2012-11-26
%% Description: TODO: Add description to player_attr_api
-module(player_attr_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([attr_plus/2,  attr_plus/3, attr_elite_plus/2,  attr_second_plus/2, attr_convert/2, attr_convert_rate/2]).
-export([attr_multi/2, attr_multi/3, attr_multi/4, attr_multi_single/4, attr_elite_multi/3, attr_second_multi/3]).
-export([attr_rate_group_sum/2]).
-export([caculate_power/1,
         attr_group_sum/2]).
-export([record_attr/0, record_attr/5, record_attr/23, record_attr_second/6, record_attr_elite/14]).
-export([
         refresh_attr/1,
         refresh_attr_lv/1,
         refresh_attr_position/1,
         refresh_attr_title/1,
         refresh_attr_equip/1,
         refresh_attr_ability/1,
         refresh_attr_guild_ability/1,
%%       refresh_attr_group_ability/1,
         refresh_attr_mind/1,
         refresh_attr_assemble/1,
         refresh_attr_assist/1,
         refresh_attr_cultivation/1,
		 refresh_attr_tower/1,
         refresh_buff/1,
         refresh_attr/6,
         refresh_group/2,
         refresh_attr_train/1,
		 refresh_attr_partner_soul/1,
		 refresh_attr_partner_star/1,
		 refresh_power/2,
		 refresh_mcopy_buff/1,
		 refresh_attr_weapon/1,
		 refresh_attr_look/1
        ]).
-export([refresh_reflect/1,
		 attr_reflect_sum/1,
		 read_attrs/1]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 刷新全部属性
refresh_attr(Player) ->
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Lv              = Info#info.lv,
    AttrRate        = Info#info.attr_rate,
    PlayerLevel     = data_player:get_player_level({Pro, Lv}),
    AttrLv          = attr_convert_rate(PlayerLevel#player_level.attr, AttrRate),
    BuffList        = Player#player.buff, 
	{AttrEquip, AttrSuitP} = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, Player#player.user_id),
    {AttrTitle, AttrTitleP} = achievement_api:refresh_attr(Info#info.current_title), 
	{AttrCultiPer, AttrCultiValue}       = player_cultivation_api:refresh_attr_cultivation(Player),
	AttrGroup       = #attr_group{
                                  lv          = AttrLv,                                           						% #attr{}角色基础属性(等级)
                                  train       = partner_api:refresh_attr_train_player(Player),                        	% #attr{}角色培养属性(等级)
                                  position    = player_position_api:refresh_attr(Player#player.position),         		% #attr{}角色官衔
                                  title       = AttrTitle,                	% #attr{}角色称号
                                  equip       = AttrEquip,	% #attr{}角色装备属性(装备)
                                  skill       = skill_api:refresh_attr(Player),                                     % #attr{}组合          
                                  ability     = ability_api:refresh_attr(Player#player.ability),                  		% #attr{}内功
                                  camp        = ?null,                                                             		% #attr{}阵法
                                  mind        = mind_api:refresh_attr(Player#player.mind, ?CONST_MIND_TYPE_PLAYER, Player#player.user_id),  %#attr{}心法
                                  guild       = guild_api:refresh_attr(Player#player.guild),							% #attr{}军团
								  tower		  = tower_api:refresh_attr(Player#player.tower),                             % #attr{}破阵
								  weapon	  = weapon_api:refresh_attr(Player#player.weapon, Pro),                       % #attr{}神兵
								  lookfor	  = partner_api:refresh_attr_lookfor(Player),											% #attr{}寻访激活
								  assemble    = partner_api:refresh_attr_assemble(Player),								% 武将组合
								  partner_soul= partner_soul_api:refresh_attr_partner_soul_player(Player),				% 将魂
								  partner_star= partner_soul_api:refresh_attr_partner_star_player(Player)     			% 将星
                                 },
    AttrRateGroup   = #attr_rate_group{
                                       cultivation = AttrCultiPer,			% 修为加成百分比[]
                                       buff        = buff_api:refresh_attr(BuffList, []),
									   suit		   = AttrSuitP,							% []buff列表
									   title       = AttrTitleP,
                                       equip       = ctn_equip_api:refresh_attr_rate_group(Player)
                                      },
    AttrReflect     = refresh_reflect(Player),
    AttrAssist      = partner_api:refresh_attr_assist(Player, 0),
    AttrTemp        = attr_group_sum(AttrGroup, Pro),
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    AttrReflect2    = attr_reflect_sum(AttrReflect),
    Attr            = attr_plus(AttrTemp2, AttrReflect2),
%%     Attr            = attr_convert(AttrTemp3, Pro),
    %% 最后加上副将的加成和祭星的加成(值)
    Attr2           = attr_plus(Attr, AttrAssist),
	Attr3			= attr_plus(Attr2, AttrCultiValue),
	Power           = caculate_power(Attr3),
    NewInfo         = Info#info{power = Power},
    Player2 		= Player#player{info             = NewInfo, 
									attr_group       = AttrGroup, 
									attr             = Attr3, 
									attr_rate_group  = AttrRateGroup,
									attr_assist      = AttrAssist,
									attr_culti		 = AttrCultiValue,
									attr_sum         = AttrTemp,
									attr_reflect     = AttrReflect,
									attr_sum_reflect = AttrReflect2
								   },
    partner_api:refresh_partner_attr(Player2). %% 刷新每个武将全部属性

read_attrs(Player) ->
    AttrOld         = Player#player.attr,
    AttrGroup       = Player#player.attr_group,
    AttrRateGroup   = Player#player.attr_rate_group,
    AttrAssist      = Player#player.attr_assist,
	AttrCult      	= Player#player.attr_culti,
    AttrReflect     = Player#player.attr_reflect,
    AttrSum         = Player#player.attr_sum,
    AttrReflectSum  = Player#player.attr_sum_reflect,
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCult, AttrReflect, AttrSum, AttrReflectSum}.

%% 刷新
refresh_reflect(Player) ->
    #attr_reflect{
                    group = group_api:refresh_reflect_attr(Player)
                 }.

% #attr{}角色基础属性(等级)
refresh_attr_lv(Player) ->
    % 旧的
    {
	 AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum
	}				= read_attrs(Player),
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Lv              = Info#info.lv,
    AttrRate        = Info#info.attr_rate,
    
    % attr_group
    PlayerLevel     = data_player:get_player_level({Pro, Lv}),
    AttrLv          = attr_convert_rate(PlayerLevel#player_level.attr, AttrRate),
    AttrGroup2      = AttrGroup#attr_group{lv = AttrLv},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_cunlti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    HpMax           = (AttrNew#attr.attr_second)#attr_second.hp_max,
    Power           = caculate_power(AttrNew),
    Info2           = Info#info{expn = PlayerLevel#player_level.exp_next, power = Power},
    Player2         = Player#player{info = Info2},
                    
    BinPower        = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POWER, Power),
    BinHp           = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_HP_MAX, HpMax),
    BinLv           = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_LV, Info2#info.lv),
    BinExpN         = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_EXPN, Info2#info.expn),
    BinMsg          = <<BinLv/binary, BinHp/binary, BinExpN/binary, BinPower/binary>>,
    refresh_attr(Player2, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinMsg).

%% 官衔
refresh_attr_position(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrPosition    = player_position_api:refresh_attr(Player#player.position),
    AttrGroup2      = AttrGroup#attr_group{position = AttrPosition},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_cunlti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 称号
refresh_attr_title(Player)
  when is_record(Player#player.attr_group, attr_group) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
%%     ?MSG_DEBUG("AttrGroup:~p", [AttrGroup]),
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    TitleId         = Info#info.current_title,
    
    % attr_group
    {AttrTitle, AttrTitlePer}       = achievement_api:refresh_attr(TitleId),
    AttrGroup2      = AttrGroup#attr_group{title = AttrTitle},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),

    % attr_rate_group
	AttrRateGroup2  = AttrRateGroup#attr_rate_group{title = AttrTitlePer},
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup2),
 
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_cunlti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
	Player2 		= Player#player{attr_rate_group = AttrRateGroup2},
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower);
refresh_attr_title(Player) -> Player.

%% 装备
refresh_attr_equip(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
    
    UserId          = Player#player.user_id,
    Info            = Player#player.info,
    Pro             = Info#info.pro,
   
    % attr_group
    {AttrEquip, AttrSuitPer}       = ctn_equip_api:refresh_attr(Player, ?CONST_GOODS_CTN_EQUIP_PLAYER, UserId),
    AttrFashion     = ctn_equip_api:refresh_attr_rate_group(Player),
    AttrGroup2      = AttrGroup#attr_group{equip = AttrEquip},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
	AttrRateGroup2  = AttrRateGroup#attr_rate_group{suit = AttrSuitPer, equip = AttrFashion},
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup2),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_cunlti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
	Player2 		= Player#player{attr_rate_group = AttrRateGroup2},
    Player3         = partner_api:refresh_attr_equip(Player2),
    {NewPlayer, BinPower} = refresh_power(Player3, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 内功
refresh_attr_ability(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),    
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Ability         = Player#player.ability,
    
    % attr_group
    AttrAbility     = ability_api:refresh_attr(Ability),
    AttrGroup2      = AttrGroup#attr_group{ability = AttrAbility},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_cunlti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    
    % partner
    Player2         = partner_api:refresh_attr_ability(Player,AttrAbility),
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 心法
refresh_attr_mind(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),   
    
    UserId          = Player#player.user_id,
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Mind            = Player#player.mind,
    
    % attr_group
    AttrMind        = mind_api:refresh_attr(Mind, ?CONST_MIND_TYPE_PLAYER, UserId),
    AttrGroup2      = AttrGroup#attr_group{mind = AttrMind},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

refresh_attr_tower(Player) ->
	 % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player), 
	
	Info			= Player#player.info,
	Pro				= Info#info.pro,
	Tower			= Player#player.tower,
	
	% attr_group
	AttrTower		= tower_api:refresh_attr(Tower),
	AttrGroup2		= AttrGroup#attr_group{tower = AttrTower},
	AttrTemp		= attr_group_sum(AttrGroup2, Pro),
	
	% attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).
	

%% 军团
refresh_attr_guild_ability(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),   
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Guild           = Player#player.guild,
    
    % attr_group
    AttrGuild       = guild_api:refresh_attr(Guild),
    AttrGroup2      = AttrGroup#attr_group{guild = AttrGuild},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    
    % partner
    Player2         = partner_api:refresh_attr_guild_ability(Player,AttrGuild),
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 武将组合
refresh_attr_assemble(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, AttrSum, AttrReflectSum}
        = read_attrs(Player),   
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrAssemble     = partner_api:refresh_attr_assemble(Player),
    AttrGroup2      = AttrGroup#attr_group{assemble = AttrAssemble},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),

    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
	
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = %attr_convert(AttrTemp4, Pro),
    Player2         = partner_api:refresh_attr_assemble_partner(Player, AttrAssemble),
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrSum, BinPower).

%% 武将副将加成
refresh_attr_assist(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, _AttrAssist, AttrCulti, _AttrReflect, AttrSum, AttrReflectSum}
        = read_attrs(Player),       
    
    % attr_group -- none

    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrSum, AttrRateGroup),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrAssist      = partner_api:refresh_attr_assist(Player, 0),
    AttrNew       	= attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    Player1         = Player#player{attr_assist = AttrAssist},
    {NewPlayer, BinPower} = refresh_power(Player1, AttrNew),
    refresh_attr(NewPlayer, AttrGroup, AttrOld, AttrNew, AttrSum, BinPower).

%% 修为加成
refresh_attr_cultivation(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist,  AttrCulti, _AttrReflect, AttrSum, AttrReflectSum}
        = read_attrs(Player),       
    
	Info            = Player#player.info,
    Pro             = Info#info.pro,
    % attr_group
    {AttrCultiPer, AttrCultiValue}       = player_cultivation_api:refresh_attr_cultivation(Player),
	AttrGroup2      = AttrGroup#attr_group{cultivation = AttrCultiValue},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
	
    % attr_rate_group
    AttrRateGroup2  = AttrRateGroup#attr_rate_group{cultivation = AttrCultiPer},
    AttrTemp2        = attr_rate_group_sum(AttrTemp, AttrRateGroup2),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp3, Pro),
	Player1         = Player#player{attr_culti = AttrCultiValue},
    Player2         = partner_api:refresh_attr_cultivation(Player1,AttrCultiPer),
	Player3         = partner_api:refresh_attr_cultivation_value(Player2,AttrCultiValue),
    Player4 		= Player3#player{attr_rate_group = AttrRateGroup2},
    {NewPlayer, BinPower} = refresh_power(Player4, AttrNew),
    refresh_attr(NewPlayer, AttrGroup, AttrOld, AttrNew, AttrSum, BinPower).

%% 培养
refresh_attr_train(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrTrain       = partner_api:refresh_attr_train_player(Player),
    AttrGroup2      = AttrGroup#attr_group{train = AttrTrain},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 将魂
refresh_attr_partner_soul(Player) ->
	{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
	
	Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrSoul        = partner_soul_api:refresh_attr_partner_soul_player(Player),
	?MSG_DEBUG("~n 22222222222222222222222222222222 AttrSoul=~p", [AttrSoul]),
    AttrGroup2      = AttrGroup#attr_group{partner_soul = AttrSoul},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).
	
%% 将星
refresh_attr_partner_star(Player) ->
	{AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),
	
	Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrStar        = partner_soul_api:refresh_attr_partner_star_player(Player),
    AttrGroup2      = AttrGroup#attr_group{partner_star = AttrStar},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    {NewPlayer, BinPower} = refresh_power(Player, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 战力
refresh_power(Player, NewAttr) ->
    Info            = Player#player.info,
    Power           = caculate_power(NewAttr),
    NewInfo         = Info#info{power = Power},
    NewPlayer       = Player#player{info = NewInfo},
    BinPower        = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_POWER, Power),
    PowerTotal      = partner_api:caculate_camp_power(NewPlayer),
	single_arena_api:refresh_power(Player#player.user_id, PowerTotal),
	new_serv_api:finish_achieve(Player#player.user_id, ?CONST_NEW_SERV_POWER_PLAYER, Power, 1),
    {?ok, NewPlayer2} = task_api:update_power(NewPlayer, PowerTotal),
	cross_arena_api:update_power(Player#player.user_id, PowerTotal),
    {NewPlayer2, BinPower}.

%% buff
refresh_buff(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, AttrSum, AttrReflectSum}
        = read_attrs(Player),
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    BuffList        = Player#player.buff,
    
    % attr_group
    AttrTemp        = attr_group_sum(AttrGroup, Pro),
    
    % attr_rate_group
    AttrList        = buff_api:refresh_attr(BuffList, []),
    AttrRateGroup2  = AttrRateGroup#attr_rate_group{buff = AttrList},
    AttrTemp2       = attr_rate_group_sum(AttrSum, AttrRateGroup2),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),
	
    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    Player2 		= Player#player{attr_rate_group = AttrRateGroup2},
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup, AttrOld, AttrNew, AttrTemp, BinPower).

%% mcopy_buff
refresh_mcopy_buff(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, AttrSum, AttrReflectSum}
        = read_attrs(Player),
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    BuffList        = Player#player.mcopy_buff,
    
    % attr_group
    AttrTemp        = attr_group_sum(AttrGroup, Pro),
    
    % attr_rate_group
    AttrList        = mcopy_api:refresh_attr(BuffList, []),
%% 	NewAttrList		= mcopy_api:refresh_attr1(AttrList, []),

%% 	AttrRateGroup2  = #attr_rate_group{mcopy_buff = AttrList},
    AttrRateGroup2  = AttrRateGroup#attr_rate_group{mcopy_buff = AttrList},
    AttrTemp2       = attr_rate_group_sum(AttrSum, AttrRateGroup2),

    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),

    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    Player2 = Player#player{attr_rate_group = AttrRateGroup2},
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),

    refresh_attr(NewPlayer, AttrGroup, AttrOld, AttrNew, AttrTemp, BinPower).

%% 常规组队
refresh_group(Player, GroupBuffList) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, AttrReflect, AttrSum, _AttrReflectSum}
        = read_attrs(Player),
    
    % attr_group -- none

    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrSum, AttrRateGroup),

    % attr_reflect
    AttrReflect2    = AttrReflect#attr_reflect{group = GroupBuffList},
    AttrReflectSum  = attr_reflect_sum(AttrReflect2),
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),

	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),

    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
	Player2         = partner_api:refresh_attr_group(Player, GroupBuffList),
    Player3 		= Player2#player{attr_sum_reflect = AttrReflectSum},
	
    {NewPlayer, BinPower} = refresh_power(Player3, AttrNew),
    refresh_attr(NewPlayer, AttrGroup, AttrOld, AttrNew, AttrSum, BinPower).

%% 神兵
refresh_attr_weapon(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),    
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    Weapon          = Player#player.weapon,
    
    % attr_group
    AttrWeapon      = weapon_api:refresh_attr(Weapon, Pro),
    AttrGroup2      = AttrGroup#attr_group{weapon = AttrWeapon},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),

    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    
    % partner
    Player2         = partner_api:refresh_attr_weapon(Player),
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).

%% 寻访武将激活
refresh_attr_look(Player) ->
    % 旧的
    {AttrOld, AttrGroup, AttrRateGroup, AttrAssist, AttrCulti, _AttrReflect, _AttrSum, AttrReflectSum}
        = read_attrs(Player),    
    
    Info            = Player#player.info,
    Pro             = Info#info.pro,
    
    % attr_group
    AttrLookfor     = partner_api:refresh_attr_lookfor(Player),
    AttrGroup2      = AttrGroup#attr_group{lookfor = AttrLookfor},
    AttrTemp        = attr_group_sum(AttrGroup2, Pro),
    
    % attr_rate_group
    AttrTemp2       = attr_rate_group_sum(AttrTemp, AttrRateGroup),
    
    % attr_reflect
    AttrTemp3       = attr_plus(AttrTemp2, AttrReflectSum),
    
	% attr_culti
    AttrTemp4       = attr_plus(AttrTemp3, AttrCulti),

    % attr_assist
    AttrNew         = attr_plus(AttrTemp4, AttrAssist),
    
    % power
%%     AttrNew         = attr_convert(AttrTemp4, Pro),
    
    % partner
    Player2         = partner_api:refresh_attr_lookfor_partner(Player, AttrLookfor),
    {NewPlayer, BinPower} = refresh_power(Player2, AttrNew),
    refresh_attr(NewPlayer, AttrGroup2, AttrOld, AttrNew, AttrTemp, BinPower).
%% -------------------------------------------------------
%% @desc    计算角色战力
%% @parm    Attr    Level
%% @return  战力
%% -------------------------------------------------------
caculate_power(Attr) when is_record(Attr, attr) ->
    ?FUNC_CALC_POWER(Attr);
caculate_power(_) -> 0.

attr_group_sum(AttrGroup, Pro) ->
    AttrList = misc:to_list(AttrGroup),
    attr_group_sum(AttrList, record_attr(), Pro).
attr_group_sum([Attr|AttrList], AccAttr, Pro) when is_record(Attr, attr) ->
    AccAttr2    = attr_plus(Attr, AccAttr),
    attr_group_sum(AttrList, AccAttr2, Pro);
attr_group_sum([Attr|AttrList], AccAttr, Pro) when is_list(Attr) -> % XXX
    AccAttr2    = attr_plus(AccAttr, Attr),
    attr_group_sum(AttrList, AccAttr2, Pro);
attr_group_sum([_Attr|AttrList], AccAttr, Pro) ->
    attr_group_sum(AttrList, AccAttr, Pro);
attr_group_sum([], AccAttr, Pro) ->
    attr_convert(AccAttr, Pro).

%% 反向影响
attr_reflect_sum(AttrReflect) ->
    AttrList = misc:to_list(AttrReflect),
    attr_reflect_sum(AttrList, record_attr()).
attr_reflect_sum([Attr|AttrList], AccAttr) when is_record(Attr, attr) ->
    AccAttr2    = attr_plus(AccAttr, Attr),
    attr_reflect_sum(AttrList, AccAttr2);
attr_reflect_sum([Attr|AttrList], AccAttr) when is_list(Attr) andalso Attr =/= [] ->
    [H|_] = Attr,
    AccAttr2    = 
        case H of
            {_, _} ->
                attr_plus(AccAttr, Attr);
            {_, _, _} ->
                Attr2 = [{Type, Value}||{_UserId, Type, Value} <- Attr],
                attr_plus(AccAttr, Attr2)
        end,
    attr_reflect_sum(AttrList, AccAttr2);
attr_reflect_sum([_Attr|AttrList], AccAttr) ->
    attr_reflect_sum(AttrList, AccAttr);
attr_reflect_sum([], AccAttr) ->
    AccAttr.

attr_convert(Attr, Pro) ->
    Force   = Attr#attr.force,
    Fate    = Attr#attr.fate,
    Magic   = Attr#attr.magic,
    {
     ForceRate, FateRate, MagicRate
    }               = data_player:get_player_pro_rate(Pro),
    AttrSecondPlus  = #attr_second{
                                   hp_max       = ?FUNC_CALC_ATTR_HP_MAX(Fate, FateRate),
                                   force_attack = ?FUNC_CALC_ATTR_FORCE_ATTACK(Force, ForceRate),
                                   force_def    = ?FUNC_CALC_ATTR_FORCE_DEF(Fate, FateRate),
                                   magic_attack = ?FUNC_CALC_ATTR_MAGIC_ATTACK(Magic, MagicRate),
                                   magic_def    = ?FUNC_CALC_ATTR_MAGIC_DEF(Fate, FateRate),
                                   speed        = ?FUNC_CALC_ATTR_SPEED(Force, ForceRate, Magic, MagicRate)
                                  },
    AttrSecond      = attr_second_plus(Attr#attr.attr_second, AttrSecondPlus),
    Attr#attr{attr_second = AttrSecond}.

attr_convert_rate(Attr, Rate) ->
    Attr#attr{
              force     = Attr#attr.force * Rate div ?CONST_SYS_NUMBER_TEN_THOUSAND,    % 力(一级)
              fate      = Attr#attr.fate * Rate div ?CONST_SYS_NUMBER_TEN_THOUSAND,     % 命(一级)
              magic     = Attr#attr.magic * Rate div ?CONST_SYS_NUMBER_TEN_THOUSAND     % 术(一级)
             }.

refresh_attr(Player, AttrGroup, AttrOld, AttrNew, AttrSum, BinMsg)->
    schedule_power_api:packet_send(packet_total, Player), % 战力：总
    BinChange   = player_api:msg_attr_change(?CONST_SYS_PLAYER, AttrOld, AttrNew),
    case <<BinMsg/binary, BinChange/binary>> of
        <<>>   ->
            Player#player{attr_group = AttrGroup, attr_sum = AttrSum};
        Packet ->
            misc_packet:send(Player#player.user_id, Packet),
            Player#player{attr_group = AttrGroup, attr = AttrNew, attr_sum = AttrSum}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
record_attr() ->
    #attr{attr_second = #attr_second{}, attr_elite = #attr_elite{}}.

record_attr(Force, Fate, Magic,
            HpMax, ForceAttack, ForceDef, MagicAttack, MagicDef, Speed,
            Hit,             Dodge,              Crit,
            Parry,           Resist,             CritHurt,     
            ReduceCrit,      ParryReduceHurt,    ReduceParry,  
            ResistHurt,      ReduceResist,       ReduceCritHurt, 
            IgnoreParryReduceHurt, ReduceResistHurt) ->
    AttrSecond  = record_attr_second(HpMax, ForceAttack, MagicAttack, ForceDef, MagicDef, Speed),
    AttrElite   = record_attr_elite(Hit,             Dodge,            Crit,
                                    Parry,           Resist,           CritHurt,     
                                    ReduceCrit,      ParryReduceHurt,  ReduceParry,  
                                    ResistHurt,      ReduceResist,     ReduceCritHurt, 
                                    IgnoreParryReduceHurt, ReduceResistHurt),
    record_attr(Force, Fate, Magic, AttrSecond, AttrElite).
record_attr(Force, Fate, Magic, AttrSecond, AttrElite)
  when is_record(AttrSecond, attr_second) andalso is_record(AttrElite, attr_elite) ->
    #attr{
          force             = Force,            % 力(一级)
          fate              = Fate,             % 命(一级)
          magic             = Magic,            % 术(一级)
          attr_second       = AttrSecond,       % 二级属性#attr_second{}
          attr_elite        = AttrElite         % 精英属性#attr_elite{}
         };
record_attr(Health, Force, Magic, AttrSecond, AttrElite) ->
    ?MSG_ERROR("Health:~p Force:~p Magic:~p AttrSecond:~p AttrElite:~p",
               [Health, Force, Magic, AttrSecond, AttrElite]).

record_attr_second(HpMax, ForceAttack, MagicAttack, ForceDef, MagicDef, Speed) ->
    #attr_second{
                 hp_max             = HpMax,            % 气血上限  
                 force_attack       = ForceAttack,      % 武力攻击
                 magic_attack       = MagicAttack,      % 术法攻击
                 force_def          = ForceDef,         % 武力防御
                 magic_def          = MagicDef,         % 术法防御
                 speed              = Speed             % 速度    
                }.

record_attr_elite(Hit,             Dodge,        Crit,
                  Parry,           Resist,       CritHurt,     
                  ReduceCrit,      ParryReduceHurt,    ReduceParry,  
                  ResistHurt,      ReduceResist, ReduceCritHurt, 
                  IgnoreParryReduceHurt, ReduceResistHurt) ->
    #attr_elite{
                hit                 = Hit,                   % 命中悟性(精英)
                dodge               = Dodge,                 % 闪避悟性(精英)
                crit                = Crit,                  % 暴击悟性(精英)
                parry               = Parry,                 % 格挡悟性(精英)
                resist              = Resist,                % 反击悟性(精英)
                crit_h              = CritHurt,              % 暴击伤害悟性(精英)
                r_crit              = ReduceCrit,            % 降低暴击悟性(精英)
                parry_r_h           = ParryReduceHurt,       % 格挡减伤悟性(精英)
                r_parry             = ReduceParry,           % 降低格挡悟性(精英)
                resist_h            = ResistHurt,            % 反击伤害悟性(精英)
                r_resist            = ReduceResist,          % 降低反击悟性(精英)
                r_crit_h            = ReduceCritHurt,        % 降低暴击伤害悟性(精英)
                i_parry_h           = IgnoreParryReduceHurt, % 无视格挡伤害悟性(精英)
                r_resist_h          = ReduceResistHurt       % 降低反击伤害悟性(精英)
               }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% -----------------------------------------------------------------
%% attr算术
%% -----------------------------------------------------------------
attr_plus(Attr, Type, Value)
  when is_record(Attr, attr) andalso 0 < Type andalso Type =< ?CONST_PLAYER_MAX_ATTR_1 ->
    Idx = Type + 1,
    Element = erlang:element(Idx, Attr),
    NewElement = Element + Value,
    erlang:setelement(Idx, Attr, NewElement);
attr_plus(Attr = #attr{attr_second = ?null}, Type, _Value) 
  when is_record(Attr, attr) andalso 0 < Type andalso Type =< ?CONST_PLAYER_MAX_ATTR_2 ->
    Attr;
attr_plus(Attr = #attr{attr_second = AttrSecond}, Type, Value) 
  when is_record(Attr, attr) andalso 0 < Type andalso Type =< ?CONST_PLAYER_MAX_ATTR_2 ->
    Idx = Type - ?CONST_PLAYER_MAX_ATTR_1 + 1,
    Element = erlang:element(Idx, AttrSecond),
    NewElement = Element + Value,
    NewAttrSecond = erlang:setelement(Idx, AttrSecond, NewElement),
    Attr#attr{attr_second = NewAttrSecond};
attr_plus(Attr = #attr{attr_elite = ?null}, Type, _Value) 
  when is_record(Attr, attr) andalso 0 < Type andalso Type =< ?CONST_PLAYER_MAX_ATTR_ELITE ->
    Attr;
attr_plus(Attr = #attr{attr_elite = AttrElite}, Type, Value) 
  when is_record(Attr, attr) andalso 0 < Type andalso Type =< ?CONST_PLAYER_MAX_ATTR_ELITE ->
    Idx = Type - ?CONST_PLAYER_MAX_ATTR_2 + 1,
    Element = erlang:element(Idx, AttrElite),
    NewElement = Element + Value,
    NewAttrElite = erlang:setelement(Idx, AttrElite, NewElement),
    Attr#attr{attr_elite = NewAttrElite};
attr_plus(Attr, _, _) ->
    Attr.

%% 部分属性相加
%% [{type, value}...]
attr_plus(Attr, [{Type, Value}|Tail]) when is_record(Attr, attr) ->
    Attr2   = attr_plus(Attr, Type, Value),
    attr_plus(Attr2, Tail);
attr_plus(Attr, []) when is_record(Attr, attr) ->
    Attr;
attr_plus(Attr, ?null) when is_record(Attr, attr) ->
    Attr;

%% 加。相同属性直接相加
attr_plus(#attr{fate = FateL, force = ForceL, magic = MagicL, attr_elite = AttrEliteL, attr_second = AttrSecondL}, 
          #attr{fate = FateR, force = ForceR, magic = MagicR, attr_elite = AttrEliteR, attr_second = AttrSecondR}) ->
    FateNew = FateL + FateR,
    ForceNew = ForceL + ForceR,
    MagicNew = MagicL + MagicR,
    AttrEliteNew = attr_elite_plus(AttrEliteL, AttrEliteR),
    AttrSecondNew = attr_second_plus(AttrSecondL, AttrSecondR),
    #attr{fate = FateNew, force = ForceNew, magic = MagicNew, attr_elite = AttrEliteNew, attr_second = AttrSecondNew};
attr_plus(?null, ?null) ->
    record_attr();
attr_plus(?null, AttrR) ->
    AttrR;
attr_plus(AttrL, ?null) ->
    AttrL.

attr_elite_plus(?null, ?null) ->
    ?null; % 两边都没初始化，就不管他了
attr_elite_plus(?null, AttrEliteR) ->
    attr_elite_plus(#attr_elite{}, AttrEliteR);
attr_elite_plus(AttrEliteL, ?null) ->
    attr_elite_plus(AttrEliteL, #attr_elite{});
attr_elite_plus(#attr_elite{
                           hit        = HitL,             
                           dodge      = DodgeL,           
                           crit       = CritL,            
                           parry      = ParryL,           
                           resist     = ResistL,           
                           crit_h     = CritHurtL,         
                           r_crit     = ReduceCritL,      
                           parry_r_h  = ParryReduceHurtL,       
                           r_parry    = ReduceParryL,     
                           resist_h   = ResistHurtL,      
                           r_resist   = ReduceResistL,    
                           r_crit_h   = ReduceCritHurtL,  
                           i_parry_h  = IgnoreParryReduceHurtL, 
                           r_resist_h = ReduceResistHurtL}, 
               #attr_elite{ 
                           hit        = HitR,            
                           dodge      = DodgeR,          
                           crit       = CritR,           
                           parry      = ParryR,          
                           resist     = ResistR,          
                           crit_h     = CritHurtR,        
                           r_crit     = ReduceCritR,     
                           parry_r_h  = ParryReduceHurtR,      
                           r_parry    = ReduceParryR,    
                           resist_h   = ResistHurtR,     
                           r_resist   = ReduceResistR,   
                           r_crit_h   = ReduceCritHurtR, 
                           i_parry_h  = IgnoreParryReduceHurtR,
                           r_resist_h = ReduceResistHurtR}) ->
    #attr_elite{hit        = HitL                   + HitR,             
                dodge      = DodgeL                 + DodgeR,           
                crit       = CritL                  + CritR,            
                parry      = ParryL                 + ParryR,           
                resist     = ResistL                + ResistR,          
                crit_h     = CritHurtL              + CritHurtR,        
                r_crit     = ReduceCritL            + ReduceCritR,      
                parry_r_h  = ParryReduceHurtL       + ParryReduceHurtR,       
                r_parry    = ReduceParryL           + ReduceParryR,     
                resist_h   = ResistHurtL            + ResistHurtR,      
                r_resist   = ReduceResistL          + ReduceResistR,    
                r_crit_h   = ReduceCritHurtL        + ReduceCritHurtR,  
                i_parry_h  = IgnoreParryReduceHurtL + IgnoreParryReduceHurtR, 
                r_resist_h = ReduceResistHurtL      + ReduceResistHurtR}. 

attr_second_plus(?null, ?null) ->
    ?null;
attr_second_plus(?null, AttrSecondR) -> AttrSecondR;
attr_second_plus(AttrSecondL, ?null) -> AttrSecondL;
attr_second_plus(#attr_second{
                             hp_max       = HpMaxL,
                             force_attack = ForceAttackL,
                             force_def    = ForceDefL,
                             magic_attack = MagicAttackL,
                             magic_def    = MagicDefL,
                             speed        = SpeedL
                            }, 
                #attr_second{
                             hp_max       = HpMaxR,
                             force_attack = ForceAttackR,
                             force_def    = ForceDefR,
                             magic_attack = MagicAttackR,
                             magic_def    = MagicDefR,
                             speed        = SpeedR
                            }) ->
    #attr_second{
                 hp_max       = HpMaxL       + HpMaxR,      
                 force_attack = ForceAttackL + ForceAttackR,
                 force_def    = ForceDefL    + ForceDefR,   
                 magic_attack = MagicAttackL + MagicAttackR,
                 magic_def    = MagicDefL    + MagicDefR,   
                 speed        = SpeedL       + SpeedR       
                }.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 部分属性相乘
%% [{type, Factor, Base}...]
attr_multi(Attr, [{Type, Factor, Base}|Tail])
  when is_record(Attr, attr) andalso Type > 0 ->
    Attr2   = attr_multi(Attr, Type, Factor, Base),
    attr_multi(Attr2, Tail);
attr_multi(Attr, []) ->
    Attr;
attr_multi(Attr, [{Type, Factor, Base}|Tail]) ->
    ?MSG_ERROR("~nBAD DATA:~nAttr:~p~nType:~p~nFactor:~p~nBase:~p~n", [Attr, Type, Factor, Base]),
    attr_multi(Attr, Tail).

attr_multi(Attr, Type, Factor, Base) 
  when Type =< ?CONST_PLAYER_MAX_ATTR_1 ->
    Idx             = Type + 1,
    Element         = erlang:element(Idx, Attr),
    NewElement      = Element * Factor div Base,
    erlang:setelement(Idx, Attr, NewElement);
attr_multi(Attr = #attr{attr_second = AttrSecond}, Type, Factor, Base)
  when is_record(AttrSecond, attr_second) andalso Type =< ?CONST_PLAYER_MAX_ATTR_2 ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_1 + 1,
    Element         = erlang:element(Idx, AttrSecond),
    NewElement      = Element * Factor div Base,
    NewAttrSecond   = erlang:setelement(Idx, AttrSecond, NewElement),
    Attr#attr{attr_second = NewAttrSecond};
attr_multi(Attr = #attr{attr_elite = AttrElite}, Type, Factor, Base)
  when is_record(AttrElite, attr_elite) andalso Type =< ?CONST_PLAYER_MAX_ATTR_ELITE ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_2 + 1,
    Element         = erlang:element(Idx, AttrElite),
    NewElement      = Element * Factor div Base,
    NewAttrElite    = erlang:setelement(Idx, AttrElite, NewElement),
    Attr#attr{attr_elite = NewAttrElite};
attr_multi(Attr, Type, Factor, Base) ->
    ?MSG_ERROR("~nBAD DATA:~nAttr:~p~nType:~p~nFactor:~p~nBase:~p~n", [Attr, Type, Factor, Base]),
    Attr.

%% 乘法
attr_rate_group_sum(Attr, AttrRateGroup) when is_record(AttrRateGroup, attr_rate_group) ->
    [_|AttrList] = misc:to_list(AttrRateGroup),
    attr_multi_plus(Attr, AttrList).


attr_multi_plus(Attr, [{Type, Factor, _Base}|Tail]) 
  when is_record(Attr, attr) andalso Type > ?CONST_PLAYER_MAX_ATTR_2 ->
    Attr2 = attr_plus(Attr, Type, Factor),
    attr_multi_plus(Attr2, Tail);
attr_multi_plus(Attr, [{Type, Factor, Base}|Tail]) 
  when is_record(Attr, attr) andalso Type > 0 ->
    Value = attr_multi_single(Attr, Type, Factor, Base),
    Attr2 = attr_plus(Attr, Type, Value),
    attr_multi_plus(Attr2, Tail);
attr_multi_plus(Attr, [List|Tail]) 
  when is_record(Attr, attr) andalso is_list(List) ->
	Attr2 = attr_multi_plus(Attr, List),
    attr_multi_plus(Attr2, Tail);
attr_multi_plus(Attr, []) ->
    Attr;
attr_multi_plus(Attr, [_|Tail]) ->
    attr_multi_plus(Attr, Tail).
        

%% 乘。将所有属性乘以因子，数据会向
%% Factor = 因子
%% Base   = 基数
%% 例如：1% -> Factor = 1, Base = 100; 1 -> Factor = 1, Base = 1.
attr_multi(?null, Factor, Base) ->
    attr_multi(#attr{attr_elite = #attr_elite{}, attr_second = #attr_second{}}, Factor, Base);
attr_multi(Attr, _Factor, 0) ->
    ?MSG_ERROR("Base = 0", []),
    Attr;
attr_multi(#attr{fate = FateL, force = ForceL, magic = MagicL, attr_elite = AttrEliteL, attr_second = AttrSecondL}, 
         Factor, Base) ->
    FateNew  = FateL  * Factor div Base,
    ForceNew = ForceL * Factor div Base,
    MagicNew = MagicL * Factor div Base,
    AttrEliteNew  = attr_elite_multi(AttrEliteL,  Factor,  Base),
    AttrSecondNew = attr_second_multi(AttrSecondL, Factor, Base),
    #attr{fate = FateNew, force = ForceNew, magic = MagicNew, attr_elite = AttrEliteNew, attr_second = AttrSecondNew}.

attr_second_multi(?null, Factor, Base) ->
    attr_second_multi(#attr_second{}, Factor, Base);
attr_second_multi(AttrSecond, _Factor, 0) ->
    ?MSG_ERROR("Base = 0", []),
    AttrSecond;
attr_second_multi(#attr_second{
                             hp_max       = HpMaxL,
                             force_attack = ForceAttackL,
                             force_def    = ForceDefL,
                             magic_attack = MagicAttackL,
                             magic_def    = MagicDefL,
                             speed        = SpeedL
                            }, 
                Factor, Base) ->
    #attr_second{
                 hp_max       = HpMaxL       * Factor div Base,
                 force_attack = ForceAttackL * Factor div Base,
                 force_def    = ForceDefL    * Factor div Base,
                 magic_attack = MagicAttackL * Factor div Base,
                 magic_def    = MagicDefL    * Factor div Base,
                 speed        = SpeedL       * Factor div Base
                }.

attr_elite_multi(?null, Factor, Base) ->
    attr_elite_multi(#attr_elite{}, Factor, Base);
attr_elite_multi(AttrElite, _Factor, 0) ->
    ?MSG_ERROR("Base = 0", []),
    AttrElite;
attr_elite_multi(#attr_elite{
                           hit        = HitL,             
                           dodge      = DodgeL,           
                           crit       = CritL,            
                           parry      = ParryL,           
                           resist     = ResistL,          
                           crit_h     = CritHurtL,        
                           r_crit     = ReduceCritL,      
                           parry_r_h  = ParryReduceHurtL,       
                           r_parry    = ReduceParryL,     
                           resist_h   = ResistHurtL,      
                           r_resist   = ReduceResistL,    
                           r_crit_h   = ReduceCritHurtL,  
                           i_parry_h  = IgnoreParryReduceHurtL, 
                           r_resist_h = ReduceResistHurtL}, 
               Factor, Base) ->
    #attr_elite{hit        = HitL                   * Factor div Base,    
                dodge      = DodgeL                 * Factor div Base,  
                crit       = CritL                  * Factor div Base,   
                parry      = ParryL                 * Factor div Base,  
                resist     = ResistL                * Factor div Base,  
                crit_h     = CritHurtL              * Factor div Base,  
                r_crit     = ReduceCritL            * Factor div Base,  
                parry_r_h  = ParryReduceHurtL       * Factor div Base,  
                r_parry    = ReduceParryL           * Factor div Base,  
                resist_h   = ResistHurtL            * Factor div Base,  
                r_resist   = ReduceResistL          * Factor div Base,  
                r_crit_h   = ReduceCritHurtL        * Factor div Base,  
                i_parry_h  = IgnoreParryReduceHurtL * Factor div Base,  
                r_resist_h = ReduceResistHurtL      * Factor div Base}. 

attr_multi_single(Attr, Type, Factor, Base) 
  when Type =< ?CONST_PLAYER_MAX_ATTR_1 ->
    Idx             = Type + 1,
    Element         = erlang:element(Idx, Attr),
    Element * Factor div Base;
attr_multi_single(#attr{attr_second = AttrSecond}, Type, Factor, Base)
  when is_record(AttrSecond, attr_second) andalso Type =< ?CONST_PLAYER_MAX_ATTR_2 ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_1 + 1,
    Element         = erlang:element(Idx, AttrSecond),
    Element * Factor div Base;
attr_multi_single(#attr{attr_elite = AttrElite}, Type, Factor, Base)
  when is_record(AttrElite, attr_elite) andalso Type =< ?CONST_PLAYER_MAX_ATTR_ELITE ->
    Idx             = Type - ?CONST_PLAYER_MAX_ATTR_2 + 1,
    Element         = erlang:element(Idx, AttrElite),
	?MSG_DEBUG("00:~p~n",[{Element,Factor,Base}]),
    Element * Factor div Base;
attr_multi_single(Attr, Type, Factor, Base) ->
    ?MSG_ERROR("~nBAD DATA:~nAttr:~p~nType:~p~nFactor:~p~nBase:~p~nStrace:~p~n", [Attr, Type, Factor, Base, erlang:get_stacktrace()]),
    0.
%%
%% Local Functions
%%

