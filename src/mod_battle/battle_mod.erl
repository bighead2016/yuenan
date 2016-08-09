%% Author: cobain
%% Created: 2012-8-31
%% Description: TODO: Add description to battle_mod
-module(battle_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([start/3, init/4, update_battle_pid_cb/2, do_battle_exec/1, do_operate/3, do_offline/2, 
		 do_auto_battle/3, broadcast/2, broadcast_over/1, do_battle_timeout/2, broadcast_units_cross/3,
         battle_prepare/5, battle_prepare/3]).
-export([
		 init_camp_left/3,
		 init_camp_right/3,
		 init_units/4,
		 refresh_seq/1,
		 init_seq/3,
         init_get_player/1,
         init_get_team_camp/2,
         get_camp/1,
         init_prepare_time/1,
         update_battle_pid/2,
         init_units_final/3
		]).

%%
%% API Functions
%%
%% battbattle_sup:start_child_battle_serv({1, 7}, {2, 8}, null).
start(Player, Id, Param) ->
	UserId		= Player#player.user_id,
	MapPid		= Player#player.map_pid,
	case battle_sup:start_child_battle_serv({?CONST_BATTLE_UNITS_SIDE_LEFT, UserId},
											{?CONST_BATTLE_UNITS_SIDE_RIGHT, Id},
											MapPid, Param) of
		{?ok, BattlePid} -> 
            
            Player2 = battle_skip_api:handle_skip(Player, Param),
            Info = Player2#player.info,
            {?ok, Player2#player{battle_pid = BattlePid, info = Info#info{is_auto = ?false}}};
		{?error, ErrorCode} -> 
            
            {?error, ErrorCode}
	end.

%% 初始化战斗数据
init({Left, LeftId}, {Right, RightId}, MapPid, Param) ->
	try
		Id			= misc:seconds(),
        Sid         = config:read_deep([server, base, sid]), %application:get_env(server, serv_id),
		BattleType	= Param#param.battle_type,
		ReportFlag	= battle_mod_misc:init_battle_report_flag(BattleType),
		{?ok, RecordLeft,  CampLeft,  CampAttrLeft}		= init_camp_left(LeftId, Param, Left),
		{?ok, RecordRight, CampRight, CampAttrRight}	= init_camp_right(RightId, Param, Right),
		{UnitsLeft,  HorseLeft, HorseSkillLeft,  HorseAttrLeft}		= init_units({Left, LeftId}, RecordLeft, CampLeft, Param),
		{UnitsRight, HorseRight, HorseSkillRight, HorseAttrRight}	= init_units({Right, RightId}, RecordRight, CampRight, Param),
        SidUnitsLeft  = UnitsLeft#units{serv_id = Sid},
        SidUnitsRight = UnitsRight#units{serv_id = Sid},
		%% 某些战斗保存的血量加载进来
		{
		 UnitsLeft2, UnitsRight2
		} 			= init_units_final(SidUnitsLeft, SidUnitsRight, Param),
		%% 战斗前预先处理--坐骑技能|阵型加成
		UnitsLeft3	= battle_prepare(Left, UnitsLeft2, CampAttrLeft, HorseAttrLeft, Param),
		UnitsRight3	= battle_prepare(Right, UnitsRight2, CampAttrRight, HorseAttrRight, Param),
		%% 初始化战斗准备时间
		Time		= init_prepare_time([HorseLeft, HorseRight]),
		Battle		= #battle{
							  id				= Id,							%% 战斗唯一ID
							  type				= BattleType,					%% 战斗类型
							  report			= ReportFlag,					%% 战报标示(true:要|false:不要)
							  map_pid			= MapPid,				        %% 地图进程ID
							  enlarge_rate		= ?CONST_SYS_NUMBER_TEN_THOUSAND,%% 伤害放大比例
							  refresh			= ?true,				        %% 是否刷新战斗单元(初始化和新回合刷新)
							  bout				= 1,					        %% 回合数
							  units_left		= UnitsLeft3,			        %% 战斗单元集合(左)
							  units_right		= UnitsRight3,			        %% 战斗单元集合(右)
							  param				= Param,				        %% 战斗参数(战斗开始前传入)
							  acc_buff_key		= 1,							%% BUFFID累加器(预留16位，最大65535)
							  
							  hurt_left			= 0,					        %% 左方战斗总伤害
							  hurt_right		= 0,					        %% 右方战斗总伤害
							  
							  cmds				= [],							%% 战斗指令累加(执行一次战斗清理一次)
							  cmd_atk			= ?null,						%% 技能攻击战斗指令(执行一个技能清理一次)
							  cmd_def			= [],							%% 技能防御战斗指令累加(执行一个技能清理一次)
							  cmd_genius		= [],							%% 天赋技能战斗指令累加(执行一个技能清理一次)
							  cmd_resist		= [],							%% 反击战斗指令累加(执行一个技能清理一次)
							  
							  genius_list		= [],							%% 天赋列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一次战斗清理一次)
							  resist_list		= [],							%% 反击列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一个技能清理一次)
							  
							  time				= Time,							%% 每次战斗时间累加(毫秒)(执行一次战斗清理一次)
							  
							  result			= ?CONST_BATTLE_RESULT_DEFAULT, %% 战斗结果
							  memory			= <<>>							%% 战斗记忆
							 },
        
		update_battle_pid(Battle, self()),
        
		%% 战斗初始化触发ai
		{Battle3, AiPacket} = ai_api:trigger_ai(Battle, ?CONST_AI_TRIGGER_INIT),
		Battle4 			= ai_api:refresh_seq(Battle3),
        
		%% 武将体验ai
		{Battle5, _List}	= ai_mod:partner_help_join(Battle4, ?CONST_BATTLE_UNITS_SIDE_LEFT, Param#param.ai_partner, []),
		PacketStop			= battle_api:msg_sc_stop(?CONST_BATTLE_STOP_REASON_NEW),
		{
		 PacketStart, PacketReport
		}					= battle_api:msg_battle_start(Battle5),
        
		PacketHorseSkill	= battle_api:msg_battle_horse_skill(Id, HorseLeft, HorseSkillLeft, HorseAttrLeft, HorseRight, HorseSkillRight, HorseAttrRight),
        PacketSkip =    case battle_skip_api:chk_can_skip(BattleType) of
                            ?false ->
                                battle_api:msg_sc_skip_info(0, ?CONST_SYS_FALSE);
                            _ ->
                                <<>>
                        end,
        
		Packet				= <<PacketStop/binary, PacketStart/binary, PacketHorseSkill/binary, AiPacket/binary, PacketSkip/binary>>,
		Battle6				= battle_mod_misc:set_battle_memory(Battle5, <<PacketReport/binary, PacketHorseSkill/binary>>),
		broadcast(Battle6, Packet),
        
		{?ok, Battle6}
	catch
		throw:Return -> Return;
		Type:Reason ->
			?MSG_ERROR("~nType:~p Reason:~p StackTrace:~p~n", [Type, Reason, erlang:get_stacktrace()]),
			{?error, Reason}
	end.

init_units_final(UnitsLeft, UnitsRight, Param) ->
	case Param#param.battle_type of
		?CONST_BATTLE_BOSS ->
			UnitsHp		= Param#param.ad3,
			{NewUnits, NewCamp}  = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		?CONST_BATTLE_WORLD	->
			UnitsHp		= Param#param.ad3,
			{NewUnits, NewCamp}  = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		?CONST_BATTLE_PARTY ->
			UnitsHp		= Param#param.ad3,
			{NewUnits, NewCamp}  = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		?CONST_BATTLE_INVASION_GUARD	->
			UnitsHp		= Param#param.ad2,
			{NewUnits, NewCamp}	= battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
			{UnitsLeft, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		?CONST_BATTLE_INVASION_ATTACK	->
			UnitsHp		= Param#param.ad2,
			{NewUnits, NewCamp}  = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		?CONST_BATTLE_CAMP_PVP ->
			case Param#param.ad3 of
				?CONST_CAMP_PVP_BATTLE_TYPE_PVB ->
					UnitsHp		= Param#param.ad5,
                    {NewUnitsL, NewCampL}   = battle_api:set_units_hp(misc:to_list(UnitsLeft#units.units), Param#param.ad1, UnitsLeft#units.camp, ?CONST_SYS_FALSE),
					{NewUnits, NewCamp}    = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
                    {UnitsLeft#units{units = NewUnitsL, camp = NewCampL}, UnitsRight#units{units = NewUnits, camp = NewCamp}};
				_ ->
					{NewUnitsL, NewCampL}	= battle_api:set_units_hp(misc:to_list(UnitsLeft#units.units), Param#param.ad1, UnitsLeft#units.camp, ?CONST_SYS_FALSE),
					{NewUnitsR, NewCampR}	= battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), Param#param.ad2, UnitsRight#units.camp, ?CONST_SYS_FALSE),
                    {UnitsLeft#units{units = NewUnitsL, camp = NewCampL}, UnitsRight#units{units = NewUnitsR, camp = NewCampR}}
			end;
        ?CONST_BATTLE_GUILD_PVE ->
            {NewUnitsL, NewCampL}   = battle_api:set_units_hp(misc:to_list(UnitsLeft#units.units), Param#param.ad1, UnitsLeft#units.camp, ?CONST_SYS_FALSE),
            {NewUnits, NewCamp}    =  battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), Param#param.ad2, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft#units{units = NewUnitsL, camp = NewCampL}, UnitsRight#units{units = NewUnits, camp = NewCamp}};
        ?CONST_BATTLE_GUILD_PVP ->
            UnitsHp     = Param#param.ad5,
            {NewUnitsL, NewCampL}   = battle_api:set_units_hp(misc:to_list(UnitsLeft#units.units), Param#param.ad1, UnitsLeft#units.camp, ?CONST_SYS_FALSE),
            {NewUnits, NewCamp}    = battle_api:set_units_hp(misc:to_list(UnitsRight#units.units), UnitsHp, UnitsRight#units.camp, ?CONST_SYS_FALSE),
            {UnitsLeft#units{units = NewUnitsL, camp = NewCampL}, UnitsRight#units{units = NewUnits, camp = NewCamp}};
		_ -> {UnitsLeft, UnitsRight}
	end.

%% 初始化战斗阵型
init_camp_left(UserId, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_LEFT)
  when is_integer(UserId) andalso
	   (BattleType =:= ?CONST_BATTLE_SINGLE_COPY orelse
	    BattleType =:= ?CONST_BATTLE_SINGLE_ARENA orelse
	    BattleType =:= ?CONST_BATTLE_SINGLE_ROBOT orelse
	    BattleType =:= ?CONST_BATTLE_BOSS orelse
	    BattleType =:= ?CONST_BATTLE_TOWER orelse
	    BattleType =:= ?CONST_BATTLE_COMMERCE orelse
	    BattleType =:= ?CONST_BATTLE_KILL_NPC orelse
	    BattleType =:= ?CONST_BATTLE_INVASION_GUARD orelse
	    BattleType =:= ?CONST_BATTLE_HOME orelse
	    BattleType =:= ?CONST_BATTLE_WORLD orelse
	    BattleType =:= ?CONST_BATTLE_PARTY orelse
		BattleType =:= ?CONST_BATTLE_PARTY_PK orelse	
	    BattleType =:= ?CONST_BATTLE_TEST_PLAYER orelse
        BattleType =:= ?CONST_BATTLE_CAMP_PVP orelse
        BattleType =:= ?CONST_BATTLE_GUILD_PVE orelse
        BattleType =:= ?CONST_BATTLE_GUILD_PVP orelse
	    BattleType =:= ?CONST_BATTLE_TEST_MONSTER orelse
		BattleType =:= ?CONST_BATTLE_GENERAL_MAP orelse
		BattleType =:= ?CONST_BATTLE_CROSS_ARENA orelse
		BattleType =:= ?CONST_BATTLE_CROSS_ARENA_ROBOT orelse
	   	BattleType =:= ?CONST_BATTLE_ENCROACH_VETERAN orelse
		BattleType =:= ?CONST_BATTLE_ENCROACH_GENERAL) ->% 角色(根据战斗参数判断)
	case init_get_player(UserId) of
		{?ok, Player} -> get_camp(Player);
		{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
	end;
init_camp_left(UserId, #param{battle_type = BattleType, ad1 = RecTeach, ad2 = Choice, ad3 = Pro}, ?CONST_BATTLE_UNITS_SIDE_LEFT)
  when is_integer(UserId) andalso
       (BattleType =:= ?CONST_BATTLE_TEACH) -> % 角色(根据战斗参数判断)
    Player2 = teach_api:init_get_player(UserId, Pro, RecTeach),
    teach_api:get_camp(Player2, RecTeach, Choice);
init_camp_left(UserId, #param{battle_type = BattleType} = Param, ?CONST_BATTLE_UNITS_SIDE_LEFT)
  when is_integer(UserId) andalso
	   (BattleType =:= ?CONST_BATTLE_TRIBE_COPY orelse
		BattleType =:= ?CONST_BATTLE_TRIBE_ARENA orelse
		BattleType =:= ?CONST_BATTLE_MCOPY_Q orelse
		BattleType =:= ?CONST_BATTLE_INVASION_ATTACK) ->% 角色(根据战斗参数判断)
    case battle_cross_api:get_player_fields(UserId, [#player.play_state, #player.team_id]) of
%% 	case player_api:get_player_fields(UserId, [#player.play_state, #player.team_id]) of
		{?ok, [PlayState, TeamId]} ->
			case init_get_player(UserId) of
				{?ok, Player} ->
					Player2	= Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL, play_state = PlayState, team_id = TeamId},
					case init_get_team_camp(Player2, UserId) of
						{?ok, LeaderId} -> init_camp_left(LeaderId, Param, ?CONST_BATTLE_UNITS_SIDE_LEFT);
						{?ok, Player3, Camp, CampAttr} -> {?ok, Player3, Camp, CampAttr};
						_ -> get_camp(Player2)
					end;
				{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
			end;
		_ -> throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})% 玩家不存在
	end.


init_camp_right(UserId, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
  when is_integer(UserId) andalso
	(BattleType =:= ?CONST_BATTLE_SINGLE_ARENA orelse
	 BattleType =:= ?CONST_BATTLE_COMMERCE orelse
	 BattleType =:= ?CONST_BATTLE_HOME orelse
	 BattleType =:= ?CONST_BATTLE_PARTY_PK  orelse	 
	 BattleType =:= ?CONST_BATTLE_TEST_PLAYER orelse
	 BattleType =:= ?CONST_BATTLE_GENERAL_MAP) ->% 角色(根据战斗参数判断,单人、多人竞技场)
	case init_get_player(UserId) of
		{?ok, Player} -> get_camp(Player);
		{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
	end;
init_camp_right(UserId, #param{battle_type = BattleType} = Param, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
  when is_integer(UserId) andalso
	(BattleType =:= ?CONST_BATTLE_TRIBE_ARENA) ->% 角色(根据战斗参数判断,单人、多人竞技场)
	case player_api:get_player_fields(UserId, [#player.play_state, #player.team_id]) of
		{?ok, [PlayState, TeamId]} ->
			case init_get_player(UserId) of
				{?ok, Player} ->
					Player2	= Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL, play_state = PlayState, team_id = TeamId},
					case init_get_team_camp(Player2, UserId) of
						{?ok, LeaderId} -> init_camp_left(LeaderId, Param, ?CONST_BATTLE_UNITS_SIDE_LEFT);
						{?ok, Player3, Camp, CampAttr} -> {?ok, Player3, Camp, CampAttr};
						_ -> get_camp(Player2)
					end;
				{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
			end;
		_ -> throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})% 玩家不存在
	end;
init_camp_right(UserId, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
  when is_integer(UserId) andalso
		(BattleType =:= ?CONST_BATTLE_SINGLE_ROBOT orelse 
		 BattleType =:= ?CONST_BATTLE_CROSS_ARENA_ROBOT)-> % 一骑讨打robot
    case monster_api:monster(UserId) of
        Monster when is_record(Monster, monster) ->
            Camp        = Monster#monster.camp,
            CampAttr    = camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
            {?ok, Monster, Camp, CampAttr};
        ?null ->
            ?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", [BattleType, ?CONST_BATTLE_UNITS_SIDE_RIGHT, UserId]),
            throw({?error, ?TIP_COMMON_NO_THIS_MON})
    end;
init_camp_right(Id, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
  when is_integer(Id) andalso 
	(BattleType =:= ?CONST_BATTLE_SINGLE_COPY orelse
	 BattleType =:= ?CONST_BATTLE_BOSS orelse
	 BattleType =:= ?CONST_BATTLE_TRIBE_COPY orelse
	 BattleType =:= ?CONST_BATTLE_TOWER orelse
	 BattleType =:= ?CONST_BATTLE_KILL_NPC orelse
	 BattleType =:= ?CONST_BATTLE_INVASION_GUARD orelse 
	 BattleType =:= ?CONST_BATTLE_WORLD orelse
	 BattleType =:= ?CONST_BATTLE_MCOPY_Q orelse
	 BattleType =:= ?CONST_BATTLE_INVASION_ATTACK orelse
	 BattleType =:= ?CONST_BATTLE_PARTY orelse
	 BattleType =:= ?CONST_BATTLE_TEST_MONSTER orelse
	 BattleType =:= ?CONST_BATTLE_ENCROACH_VETERAN orelse
	 BattleType =:= ?CONST_BATTLE_ENCROACH_GENERAL) ->% 怪物(根据战斗参数判断,单人、多人副本，世界boss)
	case monster_api:monster(Id) of
		Monster when is_record(Monster, monster) ->
			Camp		= Monster#monster.camp,
			CampAttr	= camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
			{?ok, Monster, Camp, CampAttr};
		?null ->
			?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", [BattleType, ?CONST_BATTLE_UNITS_SIDE_RIGHT, Id]),
			throw({?error, ?TIP_COMMON_NO_THIS_MON})
	end;
init_camp_right(UserId, #param{battle_type = BattleType, ad3 = SubType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
    when is_integer(UserId) andalso  BattleType =:= ?CONST_BATTLE_CAMP_PVP ->
    case SubType of
        ?CONST_CAMP_PVP_BATTLE_TYPE_PVP ->
			case init_get_player(UserId) of
				{?ok, Player} -> get_camp(Player);
				{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
			end;
        _ ->
            case monster_api:monster(UserId) of
                Monster when is_record(Monster, monster) ->
                    Camp        = Monster#monster.camp,
                    CampAttr    = camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
                    {?ok, Monster, Camp, CampAttr};
                ?null ->
                    ?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", [BattleType, ?CONST_BATTLE_UNITS_SIDE_RIGHT, UserId]),
                    throw({?error, ?TIP_COMMON_NO_THIS_MON})
            end
    end;
init_camp_right(UserId, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
    when is_integer(UserId) andalso  BattleType =:= ?CONST_BATTLE_GUILD_PVE ->
    case monster_api:monster(UserId) of
        Monster when is_record(Monster, monster) ->
            Camp        = Monster#monster.camp,
            CampAttr    = camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
            {?ok, Monster, Camp, CampAttr};
        ?null ->
            ?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", [BattleType, ?CONST_BATTLE_UNITS_SIDE_RIGHT, UserId]),
            throw({?error, ?TIP_COMMON_NO_THIS_MON})
    end;
init_camp_right(UserId, #param{battle_type = BattleType, cross_node = CrossData}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
  when is_integer(UserId) andalso
	(BattleType =:= ?CONST_BATTLE_CROSS_ARENA) ->% 跨服竞技场
	Node	= node(),
	Member		= cross_arena_mod:get_arena_info_by_id(UserId),
	case CrossData =:= ?CONST_SYS_TRUE andalso is_record(Member, ets_cross_arena_member) of
		?true ->
			PlayerData = cross_arena_data_api:get_player_data(UserId),
			get_camp(PlayerData);
		_ ->
			CrossNode	= misc:to_atom(CrossData),
			case Node =/= CrossNode of
				?true ->
					?MSG_DEBUG("init_camp_right11111:~p",[{Node, CrossNode, UserId}]),
					case rpc:call(CrossNode, ?MODULE, init_get_player, [UserId]) of
						{?ok, Player} -> 
							cross_arena_mod:update_player_data(Player, Member),
							get_camp(Player);
						{?error, ErrorCode} -> throw({?error, ErrorCode});% 玩家不存在
						_ -> throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})
					end;
				?false ->
					?MSG_DEBUG("init_camp_right22222:~p",[UserId]),
					case init_get_player(UserId) of
						{?ok, Player} -> 
							cross_arena_mod:update_player_data(Player, Member),
							get_camp(Player);
						{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
		    		end
			end
	end;
init_camp_right(UserId, #param{battle_type = BattleType, ad1 = RecTeach, ad2 = Choice}, ?CONST_BATTLE_UNITS_SIDE_RIGHT) 
  when is_integer(UserId) andalso
    (BattleType =:= ?CONST_BATTLE_TEACH) -> 
    teach_api:init_mon(UserId, RecTeach, Choice);
init_camp_right(UserId, #param{battle_type = BattleType}, ?CONST_BATTLE_UNITS_SIDE_RIGHT)
    when is_integer(UserId) andalso  BattleType =:= ?CONST_BATTLE_GUILD_PVP ->
	case init_get_player(UserId) of
		{?ok, Player} -> get_camp(Player);
		{?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
    end.

init_get_player(UserId) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.attr,
											   #player.equip, #player.skill, #player.camp, 
                                               #player.partner, #player.style,
                                               #player.partner_soul]) of
		{?ok, [Info, Attr, Equip, Skill, Camp, Partner, StyleData, PartnerSoul]} ->
			{?ok, #player{user_id = UserId, info = Info, attr = Attr,
						  equip = Equip, skill = Skill, camp = Camp, 
                          partner = Partner, style = StyleData, partner_soul = PartnerSoul#partner_soul{star_lv = min(8,PartnerSoul#partner_soul.star_lv),skill_lv = 0}}};
		_ ->
            case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                [] ->
                    {?error, ?TIP_COMMON_NO_THIS_PLAYER};% 玩家不存在
                [Rec] ->
                    Rec#cross_in.battle_player
        	end
    end.

init_get_team_camp(Player, UserId) ->
	case team_api:get_team(Player) of
		{?ok, Team} ->
			case team_api:get_team_uids(Team) of
				[UserId|_UserIdList] ->% 是队长进程
					Camp		= Team#team.camp,
					CampAttr	= camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
					{?ok, Player, Camp, CampAttr};
				[LeaderId|_UserIdList] ->% 不是队长进程
					{?ok, LeaderId};
				_ -> {?error, ?TIP_TEAM_NO_THIS_TEAM}
			end;
		_O ->
			Camp		= camp_api:default_camp(),
			CampAttr	= camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
			{?ok, Player, Camp, CampAttr}
	end.

%% 获取当前使用阵型
get_camp(Player) ->
	Camp		= camp_api:get_curent_camp(Player),
	CampAttr	= camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
	{?ok, Player, Camp, CampAttr}.

%% 初始化战斗单元集合
init_units({Side, Id}, Record, Camp, Param) ->
	{
	 UnitsTuple, Horse, HorseSkill, HorseAttr
	}			= init_unit(Side, Record, Camp, Param),
	Units		= #units{
						 side			= Side,			%% 战斗单元集合归属：0--左|1--右
						 id				= Id,			%% 主动战斗单元ID|被动战斗单元ID
						 camp			= Camp, 	    %% 阵型
						 units			= UnitsTuple,	%% 战斗单元列表
						 horse_attr		= HorseAttr		%% 坐骑技能属性加成
						},
	{Units, Horse, HorseSkill, HorseAttr}.

%% 初始化战斗单元
init_unit(Side, Record, Camp, Param) ->
	Position	= misc:to_list(Camp#camp.position),
	UnitsTuple	= erlang:make_tuple(tuple_size(Camp#camp.position), 0, []),
	init_unit(Position, Side, Record, Param, 1, UnitsTuple, [], [], player_attr_api:record_attr()).

init_unit([?CONST_SYS_FALSE|Position], Side, Record, Param, Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->
	UnitsTuple2	= setelement(Idx, UnitsTuple, ?CONST_SYS_FALSE),
	init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
init_unit([?CONST_SYS_TRUE|Position], Side, Record, Param, Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->
	UnitsTuple2	= setelement(Idx, UnitsTuple, ?CONST_SYS_TRUE),
	init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
init_unit([CampPos = #camp_pos{type = ?CONST_SYS_PLAYER}|Position], Side, Record, Param, Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->% 角色
	UserId		= Record#player.user_id,
	case CampPos#camp_pos.id of
		UserId ->
			Unit			= battle_mod_misc:record_unit(Record, Record, Side, CampPos#camp_pos.idx, Param),
			{
			 AccHorse2, AccHorseSkill2, AccHorseAttr2
			}				=
				case horse_api:get_horse_skill(Record) of
					{?ok, 0, 0, ?null, ?null} -> 
                        
                        {AccHorse, AccHorseSkill, AccHorseAttr};
					{?ok, HorseId, HorseSkillId, HorseAttr, Selection}	->
                        
						{[{Idx, HorseId, Selection}|AccHorse],
						 [{HorseSkillId}|AccHorseSkill],
						 player_attr_api:attr_plus(AccHorseAttr, HorseAttr)}
				end,
			UnitsTuple2		= setelement(Idx, UnitsTuple, Unit),
			init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse2, AccHorseSkill2, AccHorseAttr2);
		Id ->
			case init_get_player(Id) of
				{?ok, Player} ->
					Unit		= battle_mod_misc:record_unit(Record, Player, Side, CampPos#camp_pos.idx, Param),
					{
					 AccHorse2, AccHorseSkill2, AccHorseAttr2
					}			=
						case horse_api:get_horse_skill(Player) of
							{?ok, 0, 0, ?null, ?null} ->
								{AccHorse, AccHorseSkill, AccHorseAttr};
							{?ok, HorseId, HorseSkillId, HorseAttr, Selection}	->
								{[{Idx, HorseId, Selection}|AccHorse],
								 [{HorseSkillId}|AccHorseSkill],
								 player_attr_api:attr_plus(AccHorseAttr, HorseAttr)}
						end,
                    
					UnitsTuple2	= setelement(Idx, UnitsTuple, Unit),
					init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse2, AccHorseSkill2, AccHorseAttr2);
				_ -> 
                    
                    throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})
			end
	end;
init_unit([CampPos = #camp_pos{type = ?CONST_SYS_PARTNER}|Position], Side, Record, Param, Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->% 武将
    case Param#param.battle_type of
        ?CONST_BATTLE_TEACH ->
            case teach_api:get_partner_by_id(CampPos#camp_pos.id) of
                {?ok, Partner} ->
                    Unit        = battle_mod_misc:record_unit(Record, Partner, Side, CampPos#camp_pos.idx, Param),
                    UnitsTuple2 = setelement(Idx, UnitsTuple, Unit),
                    init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
                {?error, ErrorCode} ->
                    throw({?error, ErrorCode})
            end;
        _ ->
        	case partner_api:get_partner_by_id(Record, CampPos#camp_pos.id) of
        		{?ok, Partner} ->
        			Unit		= battle_mod_misc:record_unit(Record, Partner, Side, CampPos#camp_pos.idx, Param),
        			UnitsTuple2	= setelement(Idx, UnitsTuple, Unit),
        			init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
        		{?error, ErrorCode} ->
        			throw({?error, ErrorCode})
        	end
    end;
init_unit([CampPos = #camp_pos{type = ?CONST_SYS_MONSTER}|Position], Side, Record, Param, Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->% 怪物
    case Param#param.battle_type of
        ?CONST_BATTLE_TEACH when ?CONST_BATTLE_UNITS_SIDE_LEFT =:= Side ->
            case monster_api:monster(CampPos#camp_pos.id) of
                Monster when is_record(Monster, monster) ->
                    Unit        = battle_mod_misc:record_unit(Record, Monster, Side, CampPos#camp_pos.idx, Param),
                    UnitsTuple2 = setelement(Idx, UnitsTuple, Unit),
                    init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
                _ ->
                    throw({?error, ?TIP_COMMON_NO_THIS_MON})
            end;
        _ ->
        	MonsterId	= Record#monster.monster_id,
        	case CampPos#camp_pos.id of
        		MonsterId ->
        			Unit		= battle_mod_misc:record_unit(Record, Record, Side, CampPos#camp_pos.idx, Param),
        			UnitsTuple2	= setelement(Idx, UnitsTuple, Unit),
        			init_unit(Position, Side, Record, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
        		Id ->
        			case monster_api:monster(Id) of
        				Monster when is_record(Monster, monster) ->
        					Unit		= battle_mod_misc:record_unit(Record, Monster, Side, CampPos#camp_pos.idx, Param),
        					UnitsTuple2	= setelement(Idx, UnitsTuple, Unit),
        					init_unit(Position, Side, Monster, Param, Idx + 1, UnitsTuple2, AccHorse, AccHorseSkill, AccHorseAttr);
        				_ ->
        					?MSG_ERROR("BattleType:~p Side:~p MONSTERID:~p Is Not Exist", [Param#param.battle_type, Side, Id]),
        					throw({?error, ?TIP_COMMON_NO_THIS_MON})
        			end
        	end
    end;
init_unit([], _Side, _Record, _Param, _Idx, UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr) ->
	{UnitsTuple, AccHorse, AccHorseSkill, AccHorseAttr}.


battle_prepare(Side, Units, CampAttrList, HorseAttr, Param) ->
	UnitsList	= misc:to_list(Units#units.units),
	AttrPlusList= get_attr_plus_list(Side, Param),
	UnitsTuple	= battle_prepare_ext(UnitsList, CampAttrList, HorseAttr, AttrPlusList, []),
	Units#units{units = UnitsTuple}.

battle_prepare(Side, Units, Param) ->
    UnitsList   = misc:to_list(Units#units.units),
    AttrPlusList= get_attr_plus_list(Side, Param),
    UnitsTuple  = battle_prepare_ext(UnitsList, [], [], AttrPlusList, []),
    Units#units{units = UnitsTuple}.

get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_LEFT, #param{battle_type = ?CONST_BATTLE_BOSS, attr = AttrList}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_LEFT, #param{battle_type = ?CONST_BATTLE_WORLD, attr = AttrList}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_LEFT, #param{battle_type = ?CONST_BATTLE_CAMP_PVP, attr = {AttrList, _}}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_CAMP_PVP, attr = {_, AttrList}}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_LEFT, #param{battle_type = ?CONST_BATTLE_GUILD_PVE, attr = {AttrList, _}}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_GUILD_PVE, attr = {_, AttrList}}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_LEFT, #param{battle_type = ?CONST_BATTLE_GUILD_PVP, attr = {AttrList, _}}) -> AttrList;
get_attr_plus_list(?CONST_BATTLE_UNITS_SIDE_RIGHT, #param{battle_type = ?CONST_BATTLE_GUILD_PVP, attr = {_, AttrList}}) -> AttrList;
get_attr_plus_list(_Side, _Param) -> [].


battle_prepare_ext([Unit|UnitsList], CampAttrList, HorseAttr, AttrPlusList, Acc)
  when is_record(Unit, unit) ->
	{AttrBase, _AttrBaseSecond, _AttrBaseElite}	= battle_mod_misc:get_unit_attr_base(Unit),
	Fun			= fun({?CONST_SYS_CALC_TYPE_MULTI, Type, Value}, AccCampAttr) ->
						  CampAttrTemp	= player_attr_api:attr_multi_single(AttrBase, Type, Value, ?CONST_SYS_NUMBER_TEN_THOUSAND),
						  player_attr_api:attr_plus(AccCampAttr, Type, CampAttrTemp);
					 ({?CONST_SYS_CALC_TYPE_PLUS, Type, Value}, AccCampAttr) ->
						  player_attr_api:attr_plus(AccCampAttr, Type, Value);
					 ({Type, Value}, AccCampAttr) ->
						  player_attr_api:attr_plus(AccCampAttr, Type, Value);
					 (Any, AccCampAttr) -> ?MSG_ERROR("ERROR Any:~p", [Any]), AccCampAttr
				  end,
	CampAttr	= lists:foldl(Fun, player_attr_api:record_attr(), CampAttrList),
	PlusAttr	= lists:foldl(Fun, player_attr_api:record_attr(), AttrPlusList),
	AttrExtTemp	= player_attr_api:attr_plus(CampAttr, HorseAttr),
	AttrExt		= player_attr_api:attr_plus(AttrExtTemp, PlusAttr),
	Attr		= player_attr_api:attr_plus(Unit#unit.attr, AttrExt),
%% 	Hp 			= Unit#unit.hp + (AttrExt#attr.attr_second)#attr_second.hp_max,
	Hp 			= if Unit#unit.hp =:= ((Unit#unit.attr)#attr.attr_second)#attr_second.hp_max ->
						 Unit#unit.hp + (AttrExt#attr.attr_second)#attr_second.hp_max;
					 ?true -> Unit#unit.hp
				  end,
	Unit2		= Unit#unit{hp = Hp, attr = Attr, attr_ext = AttrExt},
	battle_prepare_ext(UnitsList, CampAttrList, HorseAttr, AttrPlusList, [Unit2|Acc]);
battle_prepare_ext([Unit|UnitsList], CampAttrList, HorseAttr, AttrPlusList, Acc) ->
	battle_prepare_ext(UnitsList, CampAttrList, HorseAttr, AttrPlusList, [Unit|Acc]);
battle_prepare_ext([], _CampAttrList, _HorseAttr, _AttrPlusList, Acc) ->
	misc:to_tuple(lists:reverse(Acc)).

update_battle_pid(Battle, BattlePid) ->
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
	Param			= Battle#battle.param,
	Robotlist		= Param#param.robot,
	update_battle_pid2(misc:to_list(UnitsLeft#units.units), BattlePid, Robotlist),
	update_battle_pid2(misc:to_list(UnitsRight#units.units), BattlePid, Robotlist).

update_battle_pid2([#unit{type = ?CONST_SYS_PLAYER, unit_ext = UnitExt}|UnitsList], BattlePid, Robotlist)
  when is_record(UnitExt, unit_ext_player) andalso UnitExt#unit_ext_player.online =:= ?true ->
    UserId = UnitExt#unit_ext_player.user_id,
	case lists:member(UserId, Robotlist) of
		?true ->
			?ok;
		?false ->
		    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
		        [] ->
		            player_api:process_send(UserId, ?MODULE, update_battle_pid_cb, BattlePid);
		        [CrossRec] ->
		            Node = CrossRec#cross_in.node,
		            rpc:call(Node, player_api, process_send, [UserId, ?MODULE, update_battle_pid_cb, BattlePid])
		    end
	end,
	update_battle_pid2(UnitsList, BattlePid, Robotlist);
update_battle_pid2([_Unit|UnitsList], BattlePid, Robotlist) ->
	update_battle_pid2(UnitsList, BattlePid, Robotlist);
update_battle_pid2([], _BattlePid, _Robotlist) -> ?ok.

update_battle_pid_cb(Player, BattlePid) ->
	{?ok, Player#player{battle_pid = BattlePid}}.

init_prepare_time([[]|List]) -> init_prepare_time(List);
init_prepare_time([_|_List]) -> ?CONST_BATTLE_TIME_PREPARE_HORSE;
init_prepare_time([]) -> ?CONST_BATTLE_TIME_PREPARE.

do_operate(Battle, UserId, SkillIdx) ->
	case battle_mod_misc:key(Battle, ?CONST_SYS_PLAYER, UserId) of
		{Side, Idx} ->
			Unit	= battle_mod_misc:get_unit(Battle, Side, Idx),
			case element(SkillIdx, Unit#unit.active_skill) of
				Skill when is_record(Skill, skill) ->
					%% 有操作则打断自动战斗
					UnitExt = Unit#unit.unit_ext,
					NewUnitExt = UnitExt#unit_ext_player{auto = 0}, %0手动操作1自动战斗
					NewUnit = Unit#unit{unit_ext = NewUnitExt},
					Battle2 = battle_mod_misc:set_unit(Battle, Side, NewUnit),
					do_operate(Battle2, Side, NewUnit, SkillIdx, Skill);
				_ -> Battle
			end;
		?null -> Battle
	end.
do_operate(Battle, Side, Unit, SkillIdx, Skill) ->
	Key			= battle_mod_misc:key(Side, Unit#unit.idx),
	Seq			= Battle#battle.seq,
	OperateList	= Battle#battle.operate,
	case lists:keyfind(Key, #operate.key, Seq) of
		RecOperate when is_record(RecOperate, operate) ->	% 未出手
			case RecOperate#operate.skill of
				#skill{type = ?CONST_SKILL_TYPE_NORMAL} ->
					%% 广播选中技能
					broadcast_skill(Battle, Side, Unit, Skill),
					RecOperate2	= RecOperate#operate{skill_idx = SkillIdx, skill = Skill},
					Seq2		= lists:keyreplace(Key, #operate.key, Seq, RecOperate2),
					Battle#battle{seq = Seq2};
				_ -> Battle
			end;
		?false ->	% 已出手
			case lists:keyfind(Key, #operate.key, OperateList) of
				RecOperate when is_record(RecOperate, operate) -> % 出手后已选过技能
					case RecOperate#operate.skill of
						#skill{type = ?CONST_SKILL_TYPE_NORMAL} ->
							%% 广播选中技能
							broadcast_skill(Battle, Side, Unit, Skill),
							RecOperate2	= RecOperate#operate{skill_idx = SkillIdx, skill = Skill},
							OperateList2= lists:keyreplace(Key, #operate.key, OperateList, RecOperate2),
							Battle#battle{operate = OperateList2};
						_ -> Battle
					end;
				?false ->	% 出手后第一次选技能
					%% 广播选中技能
					broadcast_skill(Battle, Side, Unit, Skill),
					Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
					RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
					Battle#battle{operate = [RecOperate|OperateList]}
			end
	end.


do_offline(Battle, UserId) ->
	case battle_mod_misc:key(Battle, ?CONST_SYS_PLAYER, UserId) of
		{Side, Idx} ->
			case battle_mod_misc:get_unit(Battle, Side, Idx) of
				Unit = #unit{type = ?CONST_SYS_PLAYER, unit_ext = UnitExt} ->
					UnitExt2	= UnitExt#unit_ext_player{online = ?false},
					Unit2		= Unit#unit{unit_ext = UnitExt2},
					?MSG_DEBUG("~nBATTLE UserId:~p OFFLINE...~n", [UserId]),
					battle_mod_misc:set_unit(Battle, Side, Unit2);
				_ -> Battle
			end;
		?null -> Battle
	end.

%% 广播选中技能
broadcast_skill(Battle, Side, Unit, Skill)
  when Skill#skill.type =/= ?CONST_SKILL_TYPE_NORMAL andalso 
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	Packet = battle_api:msg_battle_operate_notice(Side, Unit#unit.idx, Skill#skill.skill_id),
	broadcast(Battle, Packet);
broadcast_skill(_Battle, _Side, _Unit, _Skill) ->
	?ok.

%% 自动战斗
do_auto_battle(Battle, UserId, IsAuto) ->
	case battle_mod_misc:key(Battle, ?CONST_SYS_PLAYER, UserId) of
		{Side, Idx} ->
			Unit	= battle_mod_misc:get_unit(Battle, Side, Idx),
			UnitExt = Unit#unit.unit_ext,
			NewUnitExt = UnitExt#unit_ext_player{auto = IsAuto},
			NewUnit = Unit#unit{unit_ext = NewUnitExt},
			battle_mod_misc:set_unit(Battle, Side, NewUnit);
		?null ->
			Battle
	end.

%% 强制终止战斗--战斗超时
do_battle_timeout(Battle, Reason) ->
	Packet	= battle_api:msg_sc_stop(Reason),
	broadcast(Battle, Packet),
	?ok.

%% 战斗执行
do_battle_exec(Battle) ->
	{
	 Battle2, PacketRefresh
	}				= battle_mod_exec:refresh(Battle),
    
    % 跳过时不发刷新包
    case Battle2#battle.skip of
        ?false ->
            broadcast(Battle2, PacketRefresh);
        ?true ->
            ?ok
    end,
    % 战报一样记录
	Battle3			= battle_mod_misc:set_battle_memory(Battle2, PacketRefresh),
	case battle_mod_misc:check_battle_over(Battle3) of
		{?false, _} ->% 战斗尚未结束
			case battle_mod_misc:chenk_bout_over(Battle3) of
				?true ->% 回合结束
					Battle4		= Battle3#battle{bout = Battle3#battle.bout + 1, refresh = ?true},
					%% ai触发的立即出手
					Battle5 	= ai_api:refresh_seq(Battle4),
					do_battle_exec(Battle5);
				?false ->% 回合未结束
					%% ai触发的立即出手
					Battle4 	= ai_api:refresh_seq(Battle3),
					Battle5		= battle_mod_exec:exec(Battle4),
					Battle6		= refresh_seq(Battle5),
					Packet		= battle_api:msg_battle_cmd_data(Battle6),
					PacketSeq	= battle_api:msg_battle_seq(Battle6#battle.seq),
					{Battle7, PacketAi}		= ai_api:get_ai_packet(Battle6),
                    case Battle6#battle.skip of
                        ?false ->
					        broadcast(Battle7, <<Packet/binary, PacketSeq/binary, PacketAi/binary>>);
                        ?true ->
                            ?ok
                    end,
					battle_mod_misc:set_battle_memory(Battle7, Packet)
			end;
		{?true, ?CONST_BATTLE_RESULT_DRAW} ->% 平局
            PacketOverRefresh = battle_skip_api:packet_over_bout(Battle3),
            broadcast(Battle3, PacketOverRefresh),
			?MSG_BATTLE("~nTime:~p BATTLE OVER...DRAW~n", [misc:time()]),
			Battle4 = Battle3#battle{result = ?CONST_BATTLE_RESULT_RIGHT},
			broadcast_over(Battle4),
			Battle4;
		{?true, WinSide} ->% 一方获胜
            % 跳过时发刷新包
            PacketOverRefresh = battle_skip_api:packet_over_bout(Battle3),
            broadcast(Battle3, PacketOverRefresh),
			?MSG_BATTLE("~nTime:~p BATTLE OVER...WINNER IS ~p~n", [misc:time(), WinSide]),
			Battle4 = Battle3#battle{result = WinSide},
			broadcast_over(Battle4),
			Battle4
	end.

broadcast_over(Battle) ->
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
	MonsterList 	= battle_mod_misc:get_monster_ids(Battle),
	broadcast_units_over(misc:to_list(UnitsLeft#units.units), UnitsLeft#units.side, Battle, MonsterList),
	broadcast_units_over(misc:to_list(UnitsRight#units.units), UnitsRight#units.side, Battle, MonsterList),
	%% 战斗结束通知其他模块
    Result          = Battle#battle.result,
    FakeOverPacket  = battle_api:msg_sc_over(Battle#battle.id, 0, 0, ?CONST_BATTLE_TYPE_REPORT, Result, {0, 0, 0, 0, 0, 0, [], [], 0, 0, 0, 0}, []),
    Memory          = Battle#battle.memory,
    Battle2         = Battle#battle{memory = <<Memory/binary, FakeOverPacket/binary>>},
	broadcast_over_notice(Battle2, MonsterList).

%% 战斗结束通知其他模块
broadcast_over_notice(Battle, MonsterList) ->
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
	UserIdsLeft		= battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT),
%% 	UserIdsRight	= battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_RIGHT),
    BattleParam 	= Battle#battle.param,
    MapId 			= BattleParam#param.map_id,
    Result          = Battle#battle.result,
    
	%% 更新任务 
	task_api:update_battle(UserIdsLeft, MapId, MonsterList, Result, BattleParam),
	%% 战斗调用其他模块接口
	case Battle#battle.type of
		?CONST_BATTLE_SINGLE_COPY -> %%单人副本
			case UserIdsLeft of
				[UserId] ->
					{Battle2, AiPacket} = ai_api:trigger_ai(Battle, ?CONST_AI_TRIGGER_COPY_OVER),
					broadcast(Battle2, AiPacket),
                    Param           = Battle#battle.param,
                    CopyId          = Param#param.ad1,
                    CopyType        = Param#param.ad2,
                    Report          = Battle#battle.memory,
					copy_single_api:battle_over(Battle2#battle.result, {UserId, Battle2#battle.hurt_left, Battle2#battle.hurt_right, Report, CopyId, CopyType});
				_ -> ?ok
			end;
		?CONST_BATTLE_SINGLE_ARENA ->
			LeftId		= UnitsLeft#units.id,
			RightId		= UnitsRight#units.id,
			WinSide 	= Battle#battle.result,
			single_arena_api:battle_over(LeftId, WinSide, RightId, Battle#battle.memory);
		?CONST_BATTLE_SINGLE_ROBOT ->
			LeftId		= UnitsLeft#units.id,
			single_arena_robot_api:battle_over(LeftId);
		?CONST_BATTLE_BOSS ->
            if
                [] =/= BattleParam#param.robot ->
                    case UserIdsLeft of
                        [UserId] -> robot_boss_serv:robot_battle_over_cast(UserId, Result, BattleParam);
                        _ -> ?ok
                    end;
                ?true ->
        			case UserIdsLeft of
        				[UserId] -> boss_api:battle_over(UserId, Battle#battle.result, Battle#battle.param);
        				_ -> ?ok
        			end
            end;
		?CONST_BATTLE_TOWER ->
			case UserIdsLeft of
				[UserId] ->
					MonsterId		= UnitsRight#units.id,
					AtkPoint		= Battle#battle.hurt_left,           
					DefPoint		= Battle#battle.hurt_right,
                    Report          = Battle#battle.memory,
                    Param           = Battle#battle.param,
                    CampId          = Param#param.ad1,
					tower_api:battle_over(Battle#battle.result, {UserId, MonsterId, Battle#battle.bout, AtkPoint, DefPoint, Report, CampId});
				_ -> ?ok
			end;
		?CONST_BATTLE_HOME ->
			case UserIdsLeft of
				[UserId] ->
					GrabedId		= UnitsRight#units.id,
					BattleParam		= Battle#battle.param,
					home_mod_battle:battle_over(Battle#battle.result, {UserId, GrabedId, Battle#battle.param});
				_ -> ?ok
			end;
		?CONST_BATTLE_COMMERCE ->
			UserId			= UnitsLeft#units.id,
			CaravanId		= (Battle#battle.param)#param.ad1,
			commerce_api:battle_over(Battle#battle.result, {UserId, CaravanId});
		?CONST_BATTLE_KILL_NPC ->
			?ok;
		?CONST_BATTLE_PARTY ->
			case UserIdsLeft of
				[UserId] -> party_api:battle_over(UserId, Battle#battle.result, Battle#battle.param);
				_ -> ?ok
			end;
		?CONST_BATTLE_PARTY_PK ->
			?ok;
		?CONST_BATTLE_WORLD ->
			case UserIdsLeft of
				[UserId] -> world_api:battle_over(UserId, Battle#battle.result, Battle#battle.param);
				_ -> ?ok
			end;
        ?CONST_BATTLE_TRIBE_COPY -> % 多人副本
			MonsterId		= UnitsRight#units.id,
			MapPid 			= Battle#battle.map_pid,
			AtkPoint		= Battle#battle.hurt_left,           
			DefPoint		= Battle#battle.hurt_right,  
			TeamId			= (Battle#battle.param)#param.ad5,
			RobotList		= (Battle#battle.param)#param.robot,
			mcopy_api:battle_over(Battle#battle.result, UserIdsLeft, MapPid, MonsterId, AtkPoint, DefPoint, TeamId, RobotList);
		?CONST_BATTLE_INVASION_GUARD	->
			RightUnitsHpNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
			RightUnitsHpOld	= BattleParam#param.ad2,
			HurtLeft		= lists:sum(misc:to_list(battle_mod_misc:clac_hurt_tuple(RightUnitsHpOld, RightUnitsHpNew))),
			invasion_api:battle_over(Battle#battle.result, UnitsLeft#units.id, BattleParam#param.battle_type, BattleParam#param.ad1, BattleParam#param.ad3,
									 BattleParam#param.ad4, RightUnitsHpNew, HurtLeft, Battle#battle.hurt_right);
		?CONST_BATTLE_INVASION_ATTACK	->
			case UserIdsLeft of
				[UserId | _UserIdList]	->
					RightUnitsHpNew	= battle_api:get_units_hp(misc:to_list(UnitsRight#units.units)),
					RightUnitsHpOld	= BattleParam#param.ad2,
					HurtLeft		= lists:sum(misc:to_list(battle_mod_misc:clac_hurt_tuple(RightUnitsHpOld, RightUnitsHpNew))),
					invasion_api:battle_over(Battle#battle.result, UserId, BattleParam#param.battle_type, BattleParam#param.ad1, BattleParam#param.ad3,
											 BattleParam#param.ad4, RightUnitsHpNew, HurtLeft, Battle#battle.hurt_right);
				_ -> ?ok
			end;
		?CONST_BATTLE_TRIBE_ARENA -> %% 多人竞技场
%% 			case UserIdsLeft of
%% 				[UserId] ->
%% 					RightId			= UnitsRight#units.id,
					arena_pvp_api:battle_over(BattleParam#param.ad1,Battle#battle.result,BattleParam#param.ad2,
											  BattleParam#param.ad3,BattleParam#param.ad4);
%% 				_ -> ?ok
%% 			end;
		?CONST_BATTLE_CAMP_PVP -> %% 阵营战 
			{WinList, HpList}	=
				case Battle#battle.result of
					?CONST_BATTLE_RESULT_LEFT ->
						{misc:to_list(UnitsLeft#units.units), BattleParam#param.ad1};
					?CONST_BATTLE_RESULT_RIGHT ->
						{misc:to_list(UnitsRight#units.units), BattleParam#param.ad2}
				end,
			Fun	= fun(Unit = #unit{type = Type, attr_base = AttrBase, hp = NewHp}, Acc) ->
						  Id	= case Unit#unit.unit_ext of
									  #unit_ext_player{user_id = UserIdTmp} -> UserIdTmp;
									  #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
									  #unit_ext_monster{monster_id = MonsterId} -> MonsterId
								  end,
						  MaxHp	= (AttrBase#attr.attr_second)#attr_second.hp_max,
						  case lists:keytake({Type, Id}, 1, Acc) of
							  {value, {{Type, Id}, _MaxHp, _OldHp}, AccTmp} ->
								  [{{Type, Id}, MaxHp, NewHp} | AccTmp];
							  _ -> [{{Type, Id}, MaxHp, NewHp} | Acc]
						  end;
					 (_, Acc) -> Acc
				  end,
			WinHpList	= lists:foldl(Fun, HpList, WinList),
			LoseHpList	= [],
			BattleParam2= case Battle#battle.result of
							  ?CONST_BATTLE_RESULT_LEFT -> BattleParam#param{ad1 = WinHpList, ad2 = LoseHpList};
							  ?CONST_BATTLE_RESULT_RIGHT -> BattleParam#param{ad1 = LoseHpList, ad2 = WinHpList}
						  end,
			camp_pvp_api:battle_over(Battle#battle.result, BattleParam2);
        ?CONST_BATTLE_GUILD_PVE ->
            {WinList, HpList}   =
                case Battle#battle.result of
                    ?CONST_BATTLE_RESULT_LEFT ->
                        {misc:to_list(UnitsLeft#units.units), BattleParam#param.ad1};
                    ?CONST_BATTLE_RESULT_RIGHT ->
                        {misc:to_list(UnitsRight#units.units), BattleParam#param.ad2}
                end,
            
            Fun = fun(Unit = #unit{type = Type, attr_base = AttrBase, hp = NewHp}, Acc) ->
                          Id    = case Unit#unit.unit_ext of
                                      #unit_ext_player{user_id = UserIdTmp} -> UserIdTmp;
                                      #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
                                      #unit_ext_monster{monster_id = MonsterId} -> MonsterId
                                  end,
                          MaxHp = (AttrBase#attr.attr_second)#attr_second.hp_max,
                          case lists:keytake({Type, Id}, 1, Acc) of
                              {value, {{Type, Id}, _MaxHp, _OldHp}, AccTmp} ->
                                  [{{Type, Id}, MaxHp, NewHp} | AccTmp];
                              _ -> [{{Type, Id}, MaxHp, NewHp} | Acc]
                          end;
                     (_, Acc) -> Acc
                  end,
            WinHpList   = 
                case is_tuple(HpList) of
                    true ->
                        HpList;
                    false ->
                        lists:foldl(Fun, HpList, WinList)
                end,
            LoseHpList  = [],
            BattleParam2= case Battle#battle.result of
                              ?CONST_BATTLE_RESULT_LEFT -> BattleParam#param{ad1 = WinHpList, ad2 = LoseHpList, ad3 = Battle#battle.type};
                              ?CONST_BATTLE_RESULT_RIGHT -> BattleParam#param{ad1 = LoseHpList, ad2 = WinHpList, ad3 = Battle#battle.type}
                          end,
            guild_pvp_api:battle_over(Battle#battle.result, BattleParam2);
        ?CONST_BATTLE_GUILD_PVP ->
            {WinList, HpList}	=
				case Battle#battle.result of
					?CONST_BATTLE_RESULT_LEFT ->
						{misc:to_list(UnitsLeft#units.units), BattleParam#param.ad1};
					?CONST_BATTLE_RESULT_RIGHT ->
						{misc:to_list(UnitsRight#units.units), BattleParam#param.ad2}
				end,
			Fun	= fun(Unit = #unit{type = Type, attr_base = AttrBase, hp = NewHp}, Acc) ->
						  Id	= case Unit#unit.unit_ext of
									  #unit_ext_player{user_id = UserIdTmp} -> UserIdTmp;
									  #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
									  #unit_ext_monster{monster_id = MonsterId} -> MonsterId
								  end,
						  MaxHp	= (AttrBase#attr.attr_second)#attr_second.hp_max,
						  case lists:keytake({Type, Id}, 1, Acc) of
							  {value, {{Type, Id}, _MaxHp, _OldHp}, AccTmp} ->
								  [{{Type, Id}, MaxHp, NewHp} | AccTmp];
							  _ -> [{{Type, Id}, MaxHp, NewHp} | Acc]
						  end;
					 (_, Acc) -> Acc
				  end,
			WinHpList	= lists:foldl(Fun, HpList, WinList),
			LoseHpList	= [],
			BattleParam2= case Battle#battle.result of
							  ?CONST_BATTLE_RESULT_LEFT -> BattleParam#param{ad1 = WinHpList, ad2 = LoseHpList, ad3 = Battle#battle.type};
							  ?CONST_BATTLE_RESULT_RIGHT -> BattleParam#param{ad1 = LoseHpList, ad2 = WinHpList, ad3 = Battle#battle.type}
						  end,
			guild_pvp_api:battle_over(Battle#battle.result, BattleParam2);
		?CONST_BATTLE_CROSS_ARENA ->
			LeftId		= UnitsLeft#units.id,
			RightId		= UnitsRight#units.id,
			WinSide 	= Battle#battle.result,
			cross_arena_api:battle_over(LeftId, WinSide, RightId, Battle#battle.memory);
		?CONST_BATTLE_CROSS_ARENA_ROBOT ->
			LeftId		= UnitsLeft#units.id,
			RightId		= UnitsRight#units.id,
			cross_arena_robot_api:battle_over(LeftId, RightId, Battle#battle.result);
		?CONST_BATTLE_ENCROACH_VETERAN ->
            case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
                [] ->
                    ?ok;
                _ ->
        			LeftId		= UnitsLeft#units.id,
        			RightId		= UnitsRight#units.id,
        			WinSide 	= Battle#battle.result,
        			encroach_api:battle_over(LeftId, RightId, WinSide, Battle#battle.type)
            end;
		?CONST_BATTLE_ENCROACH_GENERAL ->
            case battle_mod_misc:get_online_player_ids(Battle, ?CONST_BATTLE_UNITS_SIDE_LEFT) of
                [] ->
                    ?ok;
                _ ->
                    LeftId      = UnitsLeft#units.id,
                    RightId     = UnitsRight#units.id,
                    WinSide     = Battle#battle.result,
                    encroach_api:battle_over(LeftId, RightId, WinSide, Battle#battle.type)
            end;
        ?CONST_BATTLE_TEACH ->
            LeftId      = UnitsLeft#units.id,
            RightId     = UnitsRight#units.id,
            WinSide     = Battle#battle.result,
            Bout        = Battle#battle.bout,
            teach_api:battle_over(LeftId, RightId, WinSide, Battle#battle.param, Bout);
		_ -> ?ok
	end.

broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA}} = Battle, MonsterList) ->
	Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
	Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
	MonId  = (Battle#battle.units_right)#units.id, 
	OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, []),
	misc_packet:send_cross(UserId, OverPacket),
	broadcast_units_over(UnitsList, Side, Battle, MonsterList);
broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_TRIBE_COPY}} = Battle, MonsterList) ->
    Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
    Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
    MonId  = (Battle#battle.units_right)#units.id, 
    Param           = Battle#battle.param,
    Robotlist       = Param#param.robot,
    OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, Robotlist),
    case lists:member(UserId, Robotlist) of
        ?true ->
            broadcast_units_over(UnitsList, Side, Battle, MonsterList);
        ?false ->
            misc_packet:send_cross(UserId, OverPacket),
            broadcast_units_over(UnitsList, Side, Battle, MonsterList)
    end;
broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_INVASION_GUARD}} = Battle, MonsterList) ->
    Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
    Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
    MonId  = (Battle#battle.units_right)#units.id, 

    Param           = Battle#battle.param,
    Robotlist       = Param#param.robot,
    OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, Robotlist),
    case lists:member(UserId, Robotlist) of
        ?true ->
            broadcast_units_over(UnitsList, Side, Battle, MonsterList);
        ?false ->
            misc_packet:send_cross(UserId, OverPacket),
            broadcast_units_over(UnitsList, Side, Battle, MonsterList)
    end;

broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_INVASION_ATTACK}} = Battle, MonsterList) ->
    Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
    Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
    MonId  = (Battle#battle.units_right)#units.id, 
    Param           = Battle#battle.param,
    Robotlist       = Param#param.robot,
    OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, Robotlist),
    case lists:member(UserId, Robotlist) of
        ?true ->
            broadcast_units_over(UnitsList, Side, Battle, MonsterList);
        ?false ->
            misc_packet:send_cross(UserId, OverPacket),
            broadcast_units_over(UnitsList, Side, Battle, MonsterList)
    end;
broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_MCOPY_Q}} = Battle, MonsterList) ->
    Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
    Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
    MonId  = (Battle#battle.units_right)#units.id, 
    OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, []),
    misc_packet:send_cross(UserId, OverPacket),
    broadcast_units_over(UnitsList, Side, Battle, MonsterList);
broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, 
                     #battle{param = #param{battle_type = ?CONST_BATTLE_CAMP_PVP}} = Battle, MonsterList) ->
	Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
	Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
	MonId  = (Battle#battle.units_right)#units.id, 
	OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, []),
	misc_packet:send_cross(UserId, OverPacket),
	broadcast_units_over(UnitsList, Side, Battle, MonsterList);
broadcast_units_over([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Side, Battle, MonsterList) ->
	Result = if Battle#battle.result =:= Side -> 1; ?true -> 2 end,% 等前段有时间要改掉
	Reward = battle_api:get_battle_reward(Battle, UserId, MonsterList, Result),
	MonId  = (Battle#battle.units_right)#units.id,
	Param			= Battle#battle.param,
	Robotlist		= Param#param.robot,
	OverPacket = battle_api:msg_sc_over(Battle#battle.id, UserId, MonId, Battle#battle.type, Result, Reward, Robotlist),
	case lists:member(UserId, Robotlist) of
		?true ->
			broadcast_units_over(UnitsList, Side, Battle, MonsterList);
		?false ->
			misc_packet:send(UserId, OverPacket),
			broadcast_units_over(UnitsList, Side, Battle, MonsterList)
	end;
broadcast_units_over([_Unit|UnitsList], Side, Battle, MonsterList) ->
	broadcast_units_over(UnitsList, Side, Battle, MonsterList);
broadcast_units_over([], _Side, _Battle, _MonsterList) -> ?ok.



broadcast(_Battle, <<>>) -> 
    
    ?ok;
broadcast(#battle{param = #param{battle_type = BattleType}} = Battle, Packet)
  when ?CONST_BATTLE_TRIBE_ARENA =:= BattleType 
  orelse ?CONST_BATTLE_CAMP_PVP =:= BattleType 
  orelse ?CONST_BATTLE_TRIBE_COPY =:= BattleType
  orelse ?CONST_BATTLE_INVASION_GUARD =:= BattleType 
  orelse ?CONST_BATTLE_INVASION_ATTACK =:= BattleType 
  orelse ?CONST_BATTLE_MCOPY_Q =:= BattleType
  orelse ?CONST_BATTLE_BOSS =:= BattleType ->
    
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
    Param           = Battle#battle.param,
    Robotlist       = Param#param.robot,
	broadcast_units_cross(misc:to_list(UnitsLeft#units.units), Robotlist, Packet),
	broadcast_units_cross(misc:to_list(UnitsRight#units.units), Robotlist, Packet);
broadcast(Battle, Packet) ->
    
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
	Param			= Battle#battle.param,
	Robotlist		= Param#param.robot,
	broadcast_units(misc:to_list(UnitsLeft#units.units), Robotlist, Packet),
	broadcast_units(misc:to_list(UnitsRight#units.units), Robotlist, Packet).
broadcast_units([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Robotlist, Packet) ->
    
	case lists:member(UserId, Robotlist) of
		?true ->
            
			broadcast_units(UnitsList, Robotlist, Packet);
		?false ->
            
			misc_packet:send(UserId, Packet),
			broadcast_units(UnitsList, Robotlist, Packet)
	end;
broadcast_units([_Unit|UnitsList], Robotlist, Packet) ->
    
	broadcast_units(UnitsList, Robotlist, Packet);
broadcast_units([], _Robotlist, _Packet) -> 
    
    ?ok.
%% 多服广播
broadcast_units_cross([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Robotlist, Packet) ->
    
    case lists:member(UserId, Robotlist) of
        ?true ->
            
            broadcast_units_cross(UnitsList, Robotlist, Packet);
        _ ->
            
        	misc_packet:send_cross(UserId, Packet),
        	broadcast_units_cross(UnitsList, Robotlist, Packet)
    end;
broadcast_units_cross([_Unit|UnitsList], Robotlist, Packet) ->
    
	broadcast_units_cross(UnitsList, Robotlist, Packet);
broadcast_units_cross([], _Robotlist, _Packet) -> 
    
    ?ok.

%% broadcast_units_boss_cross([#unit{type = ?CONST_SYS_PLAYER, unit_ext = #unit_ext_player{online = ?true, user_id = UserId}}|UnitsList], Packet) ->
%% 	misc_packet:send_boss_cross(UserId, Packet),
%% 	broadcast_units_boss_cross(UnitsList, Packet);
%% broadcast_units_boss_cross([_Unit|UnitsList], Packet) ->
%% 	broadcast_units_boss_cross(UnitsList, Packet);
%% broadcast_units_boss_cross([], _Packet) -> ?ok.

%%
%% Local Functions
%%
%% 初始化战斗排序
init_seq(UnitsLeft, UnitsRight, OperateListOld) ->
	{SeqListTemp, OperateListTemp, PacketTemp} =
		init_seq(UnitsLeft#units.side, misc:to_list(UnitsLeft#units.units), OperateListOld, [], <<>>),
	{SeqListTemp2, OperateList, Packet} =
		init_seq(UnitsRight#units.side, misc:to_list(UnitsRight#units.units), OperateListTemp, SeqListTemp, PacketTemp),
	SeqList		= battle_mod_misc:speed_sort(SeqListTemp2),
	{SeqList, OperateList, Packet}.
init_seq(Side, [Unit|UnitList], OperateList, AccSeq, AccPacket)
  when is_record(Unit, unit) andalso
	   Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
	Idx			= Unit#unit.idx,
	Key			= battle_mod_misc:key(Side, Idx),
	Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
	{OperateList2, SkillIdx, Skill, Packet} =
		case battle_mod_misc:check_auto(Unit) of
			?true ->
%% 				?MSG_DEBUG("OperateList:~p", [OperateList]),
				OperateListTemp	= lists:keydelete(Key, #operate.key, OperateList),
				case battle_mod_misc:auto_select_skill(Unit) of
					{?ok, 0, SkillTemp} -> {OperateListTemp, 0, SkillTemp, <<>>};
					{?ok, SkillIdxTemp, SkillTemp} ->
						{OperateListTemp, SkillIdxTemp, SkillTemp,
						 battle_api:msg_battle_operate_notice(Side, Idx, SkillTemp#skill.skill_id)};
					_ -> {OperateListTemp, 0, Unit#unit.normal_skill, <<>>}
				end;
			?false ->
				case lists:keytake(Key, #operate.key, OperateList) of
					?false -> {OperateList, 0, Unit#unit.normal_skill, <<>>};
					{value, #operate{skill_idx = SkillIdxTemp, skill = SkillTemp}, OperateListTemp} ->
						{OperateListTemp, SkillIdxTemp, SkillTemp, <<>>}
				end
		end,
	RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
	init_seq(Side, UnitList, OperateList2, [RecOperate|AccSeq], <<AccPacket/binary, Packet/binary>>);
init_seq(Side, [_Unit|UnitList], OperateList, AccSeq, AccPacket) ->
	init_seq(Side, UnitList, OperateList, AccSeq, AccPacket);
init_seq(_Side, [], OperateList, AccSeq, AccPacket) -> {AccSeq, OperateList, AccPacket}.


%% 刷新战斗排序
refresh_seq(Battle) ->
	UnitsLeft		= Battle#battle.units_left,
	UnitsRight		= Battle#battle.units_right,
	SeqOld			= Battle#battle.seq,
	SeqTemp			= refresh_seq(SeqOld, UnitsLeft#units.units, UnitsRight#units.units, []),
	Seq				= battle_mod_misc:speed_sort(SeqTemp),
	Battle#battle{seq = Seq}.

refresh_seq([SeqOperate|SeqOld], UnitsLeft, UnitsRight, Acc) ->
	{Side, Idx}	= SeqOperate#operate.key,
	UnitsTuple	= case Side of
					  ?CONST_BATTLE_UNITS_SIDE_LEFT -> UnitsLeft;
					  ?CONST_BATTLE_UNITS_SIDE_RIGHT -> UnitsRight
				  end,
	case element(Idx, UnitsTuple) of
		Unit when is_record(Unit, unit) andalso
				  Unit#unit.state =/= ?CONST_BATTLE_UNIT_STATE_DEATH ->
			Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
			RecOperate	= SeqOperate#operate{speed = Speed},
			refresh_seq(SeqOld, UnitsLeft, UnitsRight, [RecOperate|Acc]);
		_ ->
			refresh_seq(SeqOld, UnitsLeft, UnitsRight, Acc)
	end;
refresh_seq([], _UnitsLeft, _UnitsRight, Acc) -> Acc.


