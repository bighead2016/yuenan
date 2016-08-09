%%-----------------------------------------------
%%此文件用于保存伙伴的相关定义
%%-----------------------------------------------

%%记录武将组合属性的加成
-record
	(assemble_addition,
	 	{
%% 			partner_id = 0,              %%加成的武将id
			attribute_type = 0,			%%属性类型(1武力、2术法、3无双、4攻击、5、防御、6暴击、7格挡、8反击、9命中、10闪避、11初始怒气、12、出手速度)
			add_percent = 0 			%%加成百分比
		}
	).

%%记录武将专精属性的加成
-record
	(mastery_addition,
	 	{
			mastery_type = 0,           %%专精类型(1战斗、2辅助)
			partner_id = 0,              %%加成的武将id
			attribute_type = 0,			%%属性类型(1生命回复、2追加普通伤害、3晕眩敌方、4每回合失血、5、提升伤害、6家园守卫等)
			add_percent = 0 			%%加成百分比
		}
	).


%%专精战斗属性加成
-record(mastery_battle_attribute,{
								revert_hp = 0,    %%刚强 战斗每回合回复生命
								add_attack = 0,   %%勇猛 追加普通攻击
								dizzy = 0,   %%狡诈 使被攻击方晕眩
								reduce_hp = 0, %%嗜血 每回合损失血量
								add_hurt = 0   %%怒吼 攻击一定概率提升伤害
								
							   }).   

%%专精收益属性加成
-record(mastery_profit_attribute,{
						  home_ward = 0,   %%家园守卫
						  coin = 0,        %%铜钱收益
						  prestige = 0,    %%声望收益
						  exp = 0,		   %%经验获取
						  goods_drop = 0,      %%增加道具掉落成功率
						  equip_forge = 0      %%增加装备锻造成功率
						  }).


%%玩家战斗相关属性,除了气势
-record(battle_attribute,{
						  key,							%% 唯一键，由玩家id，伙伴id，类型组成。
						  player_id = 0,				%% 所属玩家
						  partner_id = 0,				%% 所属伙伴，玩家自己则为0, 对所有人都有作用则为-1
						  type = 1,						%% 加成类型。使用战斗属性加成标记宏。BAT_ATTR_BASE=1，BAT_ATTR_EQUIP=2，BAT_ATTR_MERIDIAN=3
						 
						  anger 			= 0,					%% 气势			
						  power 			= 0,    				%% 战力	
						  hurt 				= 0,                     %% 伤害，暂定
						%% 一级属性3
						  force		 		= 0, 		% 一级属性-武力
						  fate			 	= 0, 		% 一级属性-体质
						  magic		 		= 0, 		% 一级属性-术法
						
						%% 二级属性5
						  hp_max			= 0, 			% 二级属性-气血上限	
						  speed				= 0, 			% 二级属性-速度	
						  force_attack		= 0, 			% 二级属性-武力攻击
						  magic_attack		= 0,  			% 二级属性-术法攻击
						  force_def			= 0, 			% 二级属性-武力防御
						  magic_def			= 0, 			% 二级属性-术法防御
						
 						 %% 精英属性28
						  hit_svy			    = 0,            % 命中悟性(精英)
						  hit				    = 0,            % 命中(精英)
						  dodge_svy			    = 0,            % 闪避悟性(精英)
						  dodge				    = 0,            % 闪避(精英)
						  crit_svy			    = 0,            % 暴击悟性(精英)
						  crit				    = 0,            % 暴击(精英)
						  parry_svy			    = 0,            % 格挡悟性(精英)
						  parry				    = 0,            % 格挡(精英)
						  resist_svy			= 0,            % 反击悟性(精英)
						  resist				= 0,            % 反击(精英)
						  crit_hurt_svy		    = 0,            % 暴击伤害悟性(精英)
						  unique				= 0,            % 无双(精英)
						  reduce_crit_svy	    = 0,            % 降低暴击悟性(精英)
						  shadow				= 0,            % 分影(精英)
						  parry_hurt_svy		= 0,            % 格挡减伤悟性(精英)
						  tough				    = 0,            % 坚韧(精英)
						  reduce_parry_svy	    = 0,            % 降低格挡悟性(精英)
						  crack				    = 0,            % 破袭(精英)
						  resist_hurt_svy	    = 0,            % 反击伤害悟性(精英)
						  gaze				    = 0,            % 凝神(精英)
						  reduce_resist_svy	    = 0,            % 降低反击悟性(精英)
						  luck				    = 0,            % 吉运(精英)
						  reduce_crit_hurt_svy	= 0,            % 降低暴击伤害悟性(精英)
						  sexy					= 0,            % 相性(精英)
						  ignore_parry_hurt_svy	= 0,            % 无视格挡伤害悟性(精英)
						  fatal					= 0,            % 致命(精英)
						  reduce_resist_hurt_svy	= 0,            % 降低反击伤害悟性(精英)
						  idea					= 0             % 意念(精英)
						 }).
 
%%加成属性类型
-define(ASSEMBLE_FORCE, 5).	%%武力
-define(ASSEMBLE_FATE, 6).%%体质
-define(ASSEMBLE_MAGIC, 7).	%%术法
-define(ASSEMBLE_FORCE_ATTACK , 1).	%%物理攻击
-define(ASSEMBLE_FORCE_DEF, 2).		%%物理防御
-define(ASSEMBLE_MAGIC_ATTACK , 3).	%%法术攻击
-define(ASSEMBLE_MAGIC_DEF, 4).		%%法术防御
-define(ASSEMBLE_CRIT, 8).		%%暴击
-define(ASSEMBLE_PARRY, 9).	%%格挡
-define(ASSEMBLE_COUNTER, 10).	%%反击
-define(ASSEMBLE_HIT, 11).		%%命中
-define(ASSEMBLE_DODGE, 12).	%%闪避
-define(ASSEMBLE_MORALE, 13).  %%初始怒气
-define(ASSEMBLE_SPEED, 14).		%%出手速度	

%%专精属性加成类型
-define(REVERT_HP, 1).%%刚强  
-define(ADD_ATTACK, 2).	%%勇猛
-define(DIZZY, 3).	%%狡诈
-define(REDUCE_HP , 4).	%%嗜血
-define(ADD_HURT, 5).		%%怒吼
-define(HOME_WARD , 6).	%%卸甲
-define(COIN, 7).		%%贪婪
-define(EXP, 8).		%%成长
-define(PRESTIGE, 9).	%%名望
-define(GOODS_DROP, 10).	%%掠夺
-define(EQUIP_FORGE, 11).		%%锻造
