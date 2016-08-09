%%% 跨服接口
-module(battle_cross_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.tip.hrl").
-include("const.define.hrl").

-include("record.data.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").

%%
%% Exported Functions
%%
-export([record_battle/3, start/3, init/5, get_user_id_list/1, get_player_fields/2,
         init_get_player/2]).

%%
%% API Functions
%%

%% 封装结构
%% {_, P} = battle_cross_api:record_battle(18, 2, 0).
record_battle(?CONST_BATTLE_TRIBE_ARENA, UserId, TeamId) when is_number(UserId) andalso 0 < UserId ->
    try
        ServerId = config:read_deep([server, base, sid]), % application:get_env(server, serv_id),
        Param = #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA, ai_list = [], attr = [], map_id = 0},
        {?ok, Record,  Camp,  CampAttr}         = init_camp(UserId, Param),
        {Units,  Horse, HorseSkill, HorseAttr} = battle_mod:init_units({?CONST_BATTLE_UNITS_SIDE_LEFT, UserId}, Record, Camp, Param),
        NewUnits  = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_LEFT, Units, CampAttr, HorseAttr, Param),
        {?ok, {NewUnits, HorseSkill, HorseAttr, Horse, TeamId, ServerId}}
    catch
        X:Y ->
            ?MSG_ERROR("[~p~n~p~n~p]", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG}
    end;
record_battle(?CONST_BATTLE_CAMP_PVP, UserId, _) when is_number(UserId) andalso 0 < UserId ->
    try
        ServerId = config:read_deep([server, base, sid]), % application:get_env(server, serv_id),
        Param = #param{battle_type = ?CONST_BATTLE_CAMP_PVP, ai_list = [], attr = [], map_id = 0},
        {?ok, Record,  Camp,  CampAttr}         = init_camp(UserId, Param),
        {Units,  Horse, HorseSkill, HorseAttr} = battle_mod:init_units({?CONST_BATTLE_UNITS_SIDE_LEFT, UserId}, Record, Camp, Param),
        NewUnits  = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_LEFT, Units, CampAttr, HorseAttr, Param),
        {?ok, {NewUnits, HorseSkill, HorseAttr, Horse, ServerId}}
    catch
        X:Y ->
            ?MSG_ERROR("[~p~n~p~n~p]", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG}
    end;
record_battle(?CONST_BATTLE_BOSS, UserId, _) when is_number(UserId) andalso 0 < UserId ->
	try
		ServerId		= config:read_deep([server, base, sid]),
		Param 			= #param{battle_type = ?CONST_BATTLE_BOSS, ai_list = [], attr = [], map_id = 0},
		?MSG_DEBUG("~n 22222222222222", []),
		{?ok, Record,  Camp,  CampAttr}		   = init_camp(UserId, Param),
		?MSG_DEBUG("~n 22222222222222", []),
		{Units,  Horse, HorseSkill, HorseAttr} = battle_mod:init_units({?CONST_BATTLE_UNITS_SIDE_LEFT, UserId}, Record, Camp, Param),
		?MSG_DEBUG("~n 22222222222222", []),
		NewUnits  		= battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_LEFT, Units, CampAttr, HorseAttr, Param),
		?MSG_DEBUG("~n 22222222222222", []),
		{?ok, {NewUnits, HorseSkill, HorseAttr, Horse, ServerId}}
	catch
		X:Y ->
			?MSG_ERROR("[~p~n~p~n~p]", [X, Y, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG}
	end;
record_battle(_, _, _) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

%%  发起战斗
start({#units{} = BattleL, HorseSkillLeft, HorseAttrLeft, HorseLeft, TeamIdL, ServerIdL}, 
      {#units{} = BattleR, HorseSkillRight, HorseAttrRight, HorseRight, TeamIdR, ServerIdR}, 
      #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA} = Param) ->
    BattleL2 = BattleL#units{side = ?CONST_BATTLE_UNITS_SIDE_LEFT, serv_id = ServerIdL},
    BattleR2 = BattleR#units{side = ?CONST_BATTLE_UNITS_SIDE_RIGHT, serv_id = ServerIdR},
    UserIdListL = get_user_id_list(BattleL2),
    UserIdListR = get_user_id_list(BattleR2),
    ?MSG_ERROR("UserIdListL size is ~w, ~w", [UserIdListL, UserIdListR]),
    Param2 = Param#param{ad1 = TeamIdL, ad2 = TeamIdR, ad3 = UserIdListL, ad4 = UserIdListR},
    case battle_sup:start_child_battle_serv_cross(BattleL2, BattleR2,
                                            {HorseSkillLeft, HorseAttrLeft, HorseLeft},
                                            {HorseSkillRight, HorseAttrRight, HorseRight},
                                                  Param2) of
        {?ok, _BattlePid} -> ?ok;
        {?error, ErrorCode} -> ?MSG_ERROR("start err",[]),{?error, ErrorCode}
    end;
start({#units{} = BattleL, HorseSkillLeft, HorseAttrLeft, HorseLeft, ServerIdL}, 
      {#units{} = BattleR, HorseSkillRight, HorseAttrRight, HorseRight, ServerIdR}, 
      Param) ->
    BattleL2 = BattleL#units{side = ?CONST_BATTLE_UNITS_SIDE_LEFT, serv_id = ServerIdL},
    BattleL3 = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_LEFT, BattleL2, Param),
    BattleR2 = BattleR#units{side = ?CONST_BATTLE_UNITS_SIDE_RIGHT, serv_id = ServerIdR},
    BattleR3 = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_RIGHT, BattleR2, Param),
    case battle_sup:start_child_battle_serv_cross(BattleL3, BattleR3, 
                                            {HorseSkillLeft, HorseAttrLeft, HorseLeft},
                                            {HorseSkillRight, HorseAttrRight, HorseRight},
                                                  Param) of
        {?ok, _BattlePid} -> ?ok;
        {?error, ErrorCode} -> ?MSG_ERROR("start err",[]),{?error, ErrorCode}
    end;
start({#units{} = BattleL, HorseSkillLeft, HorseAttrLeft, HorseLeft, ServerIdL}, 
      MonId, Param) ->
    BattleL2 = BattleL#units{side = ?CONST_BATTLE_UNITS_SIDE_LEFT, serv_id = ServerIdL},
    BattleL3 = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_LEFT, BattleL2, Param),
    
    % record mon
    ServerId = config:read_deep([server, base, sid]), % application:get_env(server, serv_id),
    {?ok, Record,  Camp,  CampAttr}        = battle_mod:init_camp_right(MonId, Param, ?CONST_BATTLE_UNITS_SIDE_RIGHT),
    {Units,  HorseRight, HorseSkillRight, HorseAttrRight} = battle_mod:init_units({?CONST_BATTLE_UNITS_SIDE_RIGHT, MonId}, Record, Camp, Param),
    BattleR2  = battle_mod:battle_prepare(?CONST_BATTLE_UNITS_SIDE_RIGHT, Units, CampAttr, HorseAttrRight, Param),
    
    case battle_sup:start_child_battle_serv_cross(BattleL3, BattleR2#units{serv_id = ServerId}, 
                                            {HorseSkillLeft, HorseAttrLeft, HorseLeft},
                                            {HorseSkillRight, HorseAttrRight, HorseRight},
                                                  Param) of
        {?ok, _BattlePid} -> ?ok;
        {?error, ErrorCode} -> ?MSG_ERROR("start err",[]),{?error, ErrorCode}
    end;
start(_, _, _) ->?MSG_ERROR("start err",[]),
    {?error, ?TIP_COMMON_BAD_ARG}.

%% 初始化战斗数据
init(UnitL, UnitR, {HorseSkillLeft, HorseAttrLeft, HorseLeft}, {HorseSkillRight, HorseAttrRight, HorseRight}, Param) ->
    try
        Id          = misc:seconds(),
        BattleType  = Param#param.battle_type,
        ReportFlag  = battle_mod_misc:init_battle_report_flag(BattleType),
        Time        = battle_mod:init_prepare_time([HorseLeft, HorseRight]),
        {
         UnitL2, UnitR2
        }           = battle_mod:init_units_final(UnitL, UnitR, Param),
        Battle      = #battle{
                              id                = Id,                           %% 战斗唯一ID
                              type              = BattleType,                   %% 战斗类型
                              report            = ReportFlag,                   %% 战报标示(true:要|false:不要)
                              map_pid           = 0,                            %% 地图进程ID
                              enlarge_rate      = ?CONST_SYS_NUMBER_TEN_THOUSAND,%% 伤害放大比例
                              refresh           = ?true,                        %% 是否刷新战斗单元(初始化和新回合刷新)
                              bout              = 1,                            %% 回合数
                              units_left        = UnitL2,                       %% 战斗单元集合(左)
                              units_right       = UnitR2,                       %% 战斗单元集合(右)
                              param             = Param,                        %% 战斗参数(战斗开始前传入)
                              acc_buff_key      = 1,                            %% BUFFID累加器(预留16位，最大65535)
                              
                              hurt_left         = 0,                            %% 左方战斗总伤害
                              hurt_right        = 0,                            %% 右方战斗总伤害
                              
                              cmds              = [],                           %% 战斗指令累加(执行一次战斗清理一次)
                              cmd_atk           = ?null,                        %% 技能攻击战斗指令(执行一个技能清理一次)
                              cmd_def           = [],                           %% 技能防御战斗指令累加(执行一个技能清理一次)
                              cmd_genius        = [],                           %% 天赋技能战斗指令累加(执行一个技能清理一次)
                              cmd_resist        = [],                           %% 反击战斗指令累加(执行一个技能清理一次)
                              
                              genius_list       = [],                           %% 天赋列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一次战斗清理一次)
                              resist_list       = [],                           %% 反击列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一个技能清理一次)
                              
                              time              = Time,                         %% 每次战斗时间累加(毫秒)(执行一次战斗清理一次)
                              
                              result            = ?CONST_BATTLE_RESULT_DEFAULT, %% 战斗结果
                              memory            = <<>>                          %% 战斗记忆
                             },
        battle_mod:update_battle_pid(Battle, self()),
        %% 战斗初始化触发ai
        {Battle3, AiPacket} = ai_api:trigger_ai(Battle, ?CONST_AI_TRIGGER_INIT),
        Battle4             = ai_api:refresh_seq(Battle3),
        PacketStop          = battle_api:msg_sc_stop(?CONST_BATTLE_STOP_REASON_NEW),
        {
         PacketStart, PacketReport
        }                   = battle_api:msg_battle_start(Battle4),
        PacketHorseSkill    = battle_api:msg_battle_horse_skill(Id, HorseLeft, HorseSkillLeft, HorseAttrLeft, HorseRight, HorseSkillRight, HorseAttrRight),
        PacketSkip          = battle_api:msg_sc_skip_info(0, ?CONST_SYS_FALSE),
        Packet              = <<PacketStop/binary, PacketStart/binary, PacketHorseSkill/binary, AiPacket/binary, PacketSkip/binary>>,
        Battle5             = battle_mod_misc:set_battle_memory(Battle4, <<PacketReport/binary, PacketHorseSkill/binary>>),
        battle_mod:broadcast(Battle5, Packet),
        {?ok, Battle5}
    catch
        throw:Return -> Return;
        Type:Reason ->
            ?MSG_ERROR("~nType:~p Reason:~p StackTrace:~p~n", [Type, Reason, erlang:get_stacktrace()]),
            {?error, Reason}
    end.


get_player_fields(UserId, List) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            player_api:get_player_fields(UserId, List);
        [#cross_in{node = Node}] ->
            rpc:call(Node, player_api, get_player_fields, [UserId, List])
    end.
            

init_get_player(_Node, UserId) ->
    case player_api:get_player_fields(UserId, [#player.info, #player.attr,
                                               #player.equip, #player.skill, #player.camp, #player.partner, #player.style]) of
        {?ok, [Info, Attr, Equip, Skill, Camp, Partner, StyleData]} ->
            {?ok, #player{user_id = UserId, info = Info, attr = Attr,
                          equip = Equip, skill = Skill, camp = Camp, partner = Partner, style = StyleData}};
        _ -> {?error, ?TIP_COMMON_NO_THIS_PLAYER}% 玩家不存在
    end.

%%
%% Local Functions
%%

init_camp(UserId, #param{battle_type = ?CONST_BATTLE_TRIBE_ARENA} = Param) ->
    case player_api:get_player_fields(UserId, [#player.play_state, #player.team_id]) of
        {?ok, [PlayState, TeamId]} ->
            case battle_mod:init_get_player(UserId) of
                {?ok, Player} ->
                    Player2 = Player#player{user_state = ?CONST_PLAYER_STATE_NORMAL, play_state = PlayState, team_id = TeamId},
                    case battle_mod:init_get_team_camp(Player2, UserId) of
                        {?ok, LeaderId} -> battle_mod:init_camp_left(LeaderId, Param, ?CONST_BATTLE_UNITS_SIDE_LEFT);
                        {?ok, Player3, Camp, CampAttr} -> {?ok, Player3, Camp, CampAttr};
                        _ -> battle_mod:get_camp(Player2)
                    end;
                {?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
            end;
        _ -> throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})% 玩家不存在
    end;
init_camp(UserId, #param{battle_type = ?CONST_BATTLE_CAMP_PVP}) ->
    case battle_mod:init_get_player(UserId) of
        {?ok, Player} -> battle_mod:get_camp(Player);
        {?error, ErrorCode} -> throw({?error, ErrorCode})% 玩家不存在
    end;
init_camp(UserId, #param{battle_type = ?CONST_BATTLE_BOSS}) ->
	case battle_mod:init_get_player(UserId) of
		{?ok, Player} -> battle_mod:get_camp(Player);
		{?error, ErrorCode} -> throw({?error, ErrorCode})
	end;
init_camp(_, _) ->
    throw({?error, ?TIP_COMMON_BAD_ARG}).


get_user_id_list(#units{units = UnitTuple}) ->
    UnitList = misc:to_list(UnitTuple),
    get_user_id_list2(UnitList, []).

get_user_id_list(#unit_ext_player{user_id = UserId}, OldList) ->
    [UserId|OldList];
get_user_id_list(_, OldList) ->
    OldList.
    

get_user_id_list2([#unit{unit_ext = Uext}|Tail], OldList) ->
    NewList = get_user_id_list(Uext, OldList),
    get_user_id_list2(Tail, NewList);
get_user_id_list2([_|Tail], OldList) ->
    get_user_id_list2(Tail, OldList);
get_user_id_list2([], List) ->
    List.
    