%% Author: Administrator
%% Created: 2012-7-25
%% Description: TODO: Add description to skill_api
-module(skill_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
%%
%% Exported Functions
%%
-export([create/1, refresh_attr/1, refresh_skill_info/1, skill_info/2,
		 battle_operate/2, battle_skill/1, battle_skill_for_ai/4,
		 normal_skill/1, normal_skill/2, login_packet/2, reset_skill_point/1,
         calc_skill_point/1, genius_skill/2]).
-export([
		 msg_sc_skill_info/2,
		 msg_sc_skill_bar_info/1,msg_sc_upgrade_skill/1
		]).
%%
%% API Functions
%%
%% 创建角色技能数据
create(InitSkillList) ->
	Fun				= fun({SkillId, _Lv}, {AccIdx, Acc})
						   when AccIdx >= 1 andalso AccIdx =< ?CONST_SKILL_SKILL_BAR_COUNT ->
							  {AccIdx+1, [{AccIdx, SkillId}|Acc]};
						 (_, {AccIdx, Acc}) -> {AccIdx+1, Acc}
					  end,
	{_, InitData}	= lists:foldr(Fun, {1, []}, lists:reverse(InitSkillList)),
	SkillBar 		= erlang:make_tuple(?CONST_SKILL_SKILL_BAR_COUNT, 0, InitData),
	InitSkillList2	= [{SkillId, Lv, 0} || {SkillId, Lv} <- InitSkillList],
	#skill_data{
				skill_bar			= SkillBar,		 % 技能栏
				skill				= InitSkillList2 % 技能列表[{SkillId, Lv, Time}, {SkillId, Lv, Time}]
			   }.

%% 上线返回技能信息请求
login_packet(Player, Packet) ->
    Packet2 = skill_mod:skill_info(Player),
    {Player, <<Packet/binary, Packet2/binary>>}.

%% 重置技能点
reset_skill_point(Player) ->
    skill_mod:reset_skill_point(Player).

calc_skill_point(Player) ->
    skill_mod:calc_skill_point(Player).

refresh_attr(_Player) ->
	player_attr_api:record_attr().

refresh_skill_info(Player) ->
	Packet	= skill_api:msg_sc_skill_info(Player, (Player#player.skill)#skill_data.skill),
	misc_packet:send(Player#player.net_pid, Packet),
	Player.

skill_info(Player, SkillIdx)
  when is_number(SkillIdx) andalso
	   SkillIdx >= 1 andalso SkillIdx =< ?CONST_SKILL_SKILL_BAR_COUNT ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillList	= SkillData#skill_data.skill,
	SkillId		= element(SkillIdx, SkillBar),
	case lists:keyfind(SkillId, 1, SkillList) of
		{SkillId, Lv, _Time} ->
			{?ok, SkillId, Lv};
		_ ->
			{?error, ?TIP_COMMON_SYS_ERROR}
	end;
skill_info(_Player, _SkillIdx) -> % 参数错误
	{?error, ?TIP_COMMON_BAD_ARG}.

battle_operate(Player, SkillIdx) ->
	case skill_info(Player, SkillIdx) of
		{?ok, SkillId, Lv} ->
			Skill = data_skill:get_skill({SkillId, Lv}),
			case {Skill#skill.belong, Skill#skill.type} of
				{?CONST_SYS_PLAYER, ?CONST_SKILL_TYPE_ACTIVE} ->
					{?ok, Skill};
				_ -> {?error, ?TIP_COMMON_SYS_ERROR}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

battle_skill_for_ai(Pro, CultivationNum, SkillId, SkillLv) ->
	Skill = data_skill:get_skill({SkillId, SkillLv}),
	case (Skill#skill.effect)#effect.effect_id of
		?CONST_SKILL_EFFECT_ID_1 -> active_skill_ext(Pro, CultivationNum, Skill);
		_ -> Skill
	end.

battle_skill(Player) ->
	NormalSkill	= normal_skill(Player),
	ActiveSkill	= active_skill(Player),
	GeniusSkill	= genius_skill(Player),
	{NormalSkill, ActiveSkill, GeniusSkill}.

normal_skill(Player) when is_record(Player, player) ->
	Info	= Player#player.info,
	normal_skill(Info#info.pro);
normal_skill(Pro) ->
	data_skill:get_default_skill(Pro).

normal_skill(SkilId, SkillLv) ->
	data_skill:get_default_skill(SkilId, SkillLv).

active_skill(Player) ->
	SkillData	= Player#player.skill,
	SkillBar	= SkillData#skill_data.skill_bar,
	SkillList	= SkillData#skill_data.skill,
	active_skill(Player, SkillList, misc:to_list(SkillBar), []).
active_skill(Player, SkillList, [0|SkillBarList], Acc) ->
	active_skill(Player, SkillList, SkillBarList, [0|Acc]);
active_skill(Player, SkillList, [SkillId|SkillBarList], Acc) ->
	case lists:keyfind(SkillId, 1, SkillList) of
		{SkillId, Lv, _Time} ->
			Skill = data_skill:get_skill({SkillId, Lv}),
			case Skill#skill.type of
				?CONST_SKILL_TYPE_ACTIVE ->
					case (Skill#skill.effect)#effect.effect_id of
						?CONST_SKILL_EFFECT_ID_1 ->
							Skill2	= active_skill_ext(Player, Skill),
							active_skill(Player, SkillList, SkillBarList, [Skill2|Acc]);
						_ -> active_skill(Player, SkillList, SkillBarList, [Skill|Acc])
					end;
				_ -> active_skill(Player, SkillList, SkillBarList, [0|Acc])
			end;
		?false -> active_skill(Player, SkillList, SkillBarList, [0|Acc])
	end;
active_skill(_Player, _SkillList, [], Acc) ->
	misc:to_tuple(lists:reverse(Acc)).

%% 连续技特殊处理
active_skill_ext(Player, Skill) when is_record(Player, player) ->
	active_skill_ext((Player#player.info)#info.pro, (Player#player.info)#info.cultivation, Skill).
active_skill_ext(Pro, CultivationNum, Skill) ->
	Effect	= Skill#skill.effect,
	{
	 Times, Ratio, RatioAnger, {Target, BuffId, BuffValue, BuffBout}
	}		= player_cultivation_api:get_special_skill(Pro, CultivationNum),
	Anger	= Skill#skill.anger * RatioAnger div ?CONST_SYS_NUMBER_TEN_THOUSAND,
	Time	= element(Times, Skill#skill.time),
	Effect2	= Effect#effect{arg2 = Times, arg3 = Target, arg4 = BuffId, arg5 = BuffValue, arg6 = BuffBout},
	Skill#skill{lv = Times, time = Time, anger = Anger, ratio = Ratio, effect = Effect2}.

genius_skill(#player{} = Player) ->
	SkillData	= Player#player.skill,
    SkillList   = get_p_soul_skill(Player, 0),
	FunPassive	= fun({SkillId, Lv, _Time}, AccPassiveSkill) ->
						  Skill = data_skill:get_skill({SkillId, Lv}),
						  case Skill#skill.type of
							  ?CONST_SKILL_TYPE_PASSIVE ->
								  [Skill|AccPassiveSkill];
							  _ -> AccPassiveSkill
						  end
				  end,
	lists:foldl(FunPassive, SkillList, SkillData#skill_data.skill).
genius_skill(Player, Partner) ->
	GSkill      = Partner#partner.genius_skill,
    SkillList   = get_p_soul_skill(Player, Partner#partner.partner_id),
    List = 
        case GSkill of
            _ when is_list(GSkill) ->
                SkillList ++ GSkill;
            _ ->
                [GSkill|SkillList]
        end,
    lists:usort(List).

%% desc:取出玩家的被动技能(将魂)
%% in:#player{}
%% out:[#skill{}|...] 
get_p_soul_skill(Player, PartnerId) ->
    {SkillId, Lv} = partner_soul_api:get_soul_skill_info(Player, PartnerId),
    Skill = data_skill:get_skill({SkillId, Lv}),
    case catch Skill#skill.type of
        ?CONST_SKILL_TYPE_PASSIVE ->
            [Skill];
        _ ->
            []
    end.

%%
%% Local Functions
%%

%% 26200 	技能信息 
msg_sc_skill_info(Player, SkillList) ->
	NewSkillList	= [{SkillId, Lv} || {SkillId, Lv, _} <- SkillList],
	case erlang:length(NewSkillList) of
		0 ->
			misc_packet:pack(?MSG_ID_SKILL_SC_SKILL_INFO, ?MSG_FORMAT_SKILL_SC_SKILL_INFO, [NewSkillList]);
		_Num ->
%% 			{Skill, _}	= lists:nth(Num, NewSkillList),
            Info = Player#player.info,
            Skill = 
                case Info#info.pro of
                    ?CONST_SYS_PRO_XZ -> 11001;
                    ?CONST_SYS_PRO_FJ -> 12001; 
                    ?CONST_SYS_PRO_TJ -> 13001
                end,
			{
			 SkillLv, _, _, _
			}			= player_cultivation_api:get_special_skill(Player),
			Lists		= lists:keyreplace(Skill, 1, NewSkillList, {Skill, SkillLv}),
			misc_packet:pack(?MSG_ID_SKILL_SC_SKILL_INFO, ?MSG_FORMAT_SKILL_SC_SKILL_INFO, [Lists])
	end.


%% 26202    升级技能返回
msg_sc_upgrade_skill(SkillId) ->
	misc_packet:pack(?MSG_ID_SKILL_SC_UPDRADE_SUCCESS, ?MSG_FORMAT_SKILL_SC_UPDRADE_SUCCESS, [SkillId]).
%% 26210 	技能栏信息 
msg_sc_skill_bar_info(SkillBar) ->
	SkillBarList	= misc:to_list(SkillBar),
	SkillBarList2	= [{SkillId} || SkillId <- SkillBarList],
	misc_packet:pack(?MSG_ID_SKILL_SC_SKILL_BAR_INFO, ?MSG_FORMAT_SKILL_SC_SKILL_BAR_INFO, [SkillBarList2]).


