%% Author: cobain
%% Created: 2012-7-13
%% Description: TODO: Add description to monster_data_generator
-module(monster_data_generator).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([generate/1]).
%%
%% API Functions
%%
%% monster_data_generator:generate().
generate(Ver) ->
	FunDatas1  = generate_monster(get_monster, Ver),
	FunDatasA1 = generate_monster_list(get_monster_list, Ver),
	misc_app:write_erl_file(data_monster,
							["../../include/const.common.hrl",
							 "../../include/record.player.hrl",
                             "../../include/record.base.data.hrl",
							 "../../include/record.data.hrl"],
							[FunDatas1, FunDatasA1], Ver).

%% monster_data_generator:generate_monster(get_monster).
generate_monster(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/map/monster.yrl"),
	generate_monster(FunName, Datas, []).
generate_monster(FunName, [Data|Datas], Acc) when is_record(Data, rec_monster) ->
	Key		= Data#rec_monster.monster_id,
	Value	= change_monster(Data),
	When	= ?null,
	generate_monster(FunName, Datas, [{Key, Value, When}|Acc]);
generate_monster(FunName, [], Acc) -> {FunName, Acc}.


change_monster(Data) ->
    Attr    = player_attr_api:record_attr(Data#rec_monster.force, Data#rec_monster.fate, Data#rec_monster.magic,
                                     
                                     Data#rec_monster.hp_max, Data#rec_monster.force_attack,  Data#rec_monster.force_def,
                                     Data#rec_monster.magic_attack, Data#rec_monster.magic_def, Data#rec_monster.speed,

                                     Data#rec_monster.hit, 		    % 命中(精英)
                                     Data#rec_monster.dodge, 	    % 闪避(精英)
                                     Data#rec_monster.crit, 	    % 暴击(精英)
                                     Data#rec_monster.parry, 	    % 格挡(精英)
                                     Data#rec_monster.resist, 	    % 反击(精英)
                                     Data#rec_monster.crit_h, 	    % 暴击伤害(精英)
                                     Data#rec_monster.r_crit, 	    % 降低暴击(精英)
                                     Data#rec_monster.parry_h, 		% 格挡减伤(精英)
                                     Data#rec_monster.r_parry, 		% 降低格挡(精英)
                                     Data#rec_monster.resist_h, 	% 反击伤害(精英)
                                     Data#rec_monster.r_resist, 	% 降低反击(精英)
                                     Data#rec_monster.r_crit_h, 	% 降低暴击伤害(精英)
                                     Data#rec_monster.i_parry_h, 	% 无视格挡伤害(精英)
                                     Data#rec_monster.r_resist_h),	% 降低反击伤害(精英)
									
	F		= fun(0, {AccIdx, AccCamp}) ->
					  {AccIdx + 1, [0|AccCamp]};
				 (MonsterId, {AccIdx, AccCamp}) ->
					  CampPos	= #camp_pos{id = MonsterId, type = ?CONST_SYS_MONSTER, idx = AccIdx},
					  {AccIdx + 1, [CampPos|AccCamp]}
			  end,
	{_, CampTemp}	= lists:foldl(F, {1, []}, Data#rec_monster.camp),
	CampPosition	= misc:to_tuple(lists:reverse(CampTemp)),
	Camp			= #camp{camp_id = 0, lv = 0, position = CampPosition},
	Skill			= get_monster_skill(Data#rec_monster.skill),
	GenusSkill		= get_monster_skill(Data#rec_monster.genus_skill),
	NormalSkill		= get_monster_normal_skill(Data#rec_monster.normal_skill),
	#monster{
			 monster_id        	= Data#rec_monster.monster_id, 	    % 怪物编号
			 type        		= Data#rec_monster.type, 	        % 怪物类型
			 pro                = Data#rec_monster.pro, 	        % 职业
			 lv        			= Data#rec_monster.lv, 	        	% 等级
			 power        		= Data#rec_monster.power, 	        % 战力
             name               = Data#rec_monster.name,            % 名称
             
			 skill        		= Skill, 	        				% 主动技能
             genus_skill        = GenusSkill,     					% 天赋技能
             normal_skill       = NormalSkill,    					% 普通攻击
			 hp					= Data#rec_monster.hp_max,			% 怪物血量
			 anger        		= Data#rec_monster.anger, 	        % 怒气
			 move_speed        	= Data#rec_monster.move_speed, 	    % 移动速度
			 map_id        		= Data#rec_monster.map_id, 	        % 所属地图
			 x        			= Data#rec_monster.x, 	        	% 默认出生X
			 y        			= Data#rec_monster.y, 	        	% 默认出生Y
			 attack_range_x     = Data#rec_monster.attack_range_x, 	% 攻击范围X
			 attack_range_y     = Data#rec_monster.attack_range_y, 	% 攻击范围Y
			 share				= Data#rec_monster.share,			% 怪物是否共享
			 renew				= Data#rec_monster.renew,			% 是否重生
			 attr				= Attr,        						% 怪物属性
			 
			 exp        		= Data#rec_monster.exp, 	        % 怪物经验
			 hook_exp        	= Data#rec_monster.hook_exp, 	    % 挂机经验
			 gold        		= Data#rec_monster.gold, 	        % 奖励铜钱
			 meritorious      	= Data#rec_monster.meritorious,     % 奖励历练
			 ai_id        		= Data#rec_monster.ai_id, 	        % 怪物AI的ID
			 drop_id        	= Data#rec_monster.drop_id, 	    % 掉落表ID
			 immune_buffs		= Data#rec_monster.immune_buffs,	% 免疫BUFF列表
			 camp        		= Camp						        % 怪物阵型 
			}.

generate_monster_list(FunName, Ver) ->
    Datas = misc_app:get_data_list(Ver++"/map/monster.yrl"),
    generate_monster_list_2(FunName, Datas).
generate_monster_list_2(FunName, Datas) ->
    Key     = ?null,
    Value   = [Monster#rec_monster.monster_id||Monster <- Datas],
    When    = ?null,
    {FunName, [{Key, Value, When}]}.

get_monster_skill(0) -> 0;
get_monster_skill({SkillId, SkillLv}) ->
	data_skill:get_skill({SkillId, SkillLv});
get_monster_skill(_) -> 1.

get_monster_normal_skill(0) -> 0;
get_monster_normal_skill({SkillId, SkillLv}) ->
	data_skill:get_default_skill({SkillId, SkillLv});
get_monster_normal_skill(_) -> 1.
%%
%% Local Functions
%%
