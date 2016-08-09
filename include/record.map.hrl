
%% 地图数据--参数
-record(map_param,     	{
						 ad1			    = 0,	        %% 数据1
						 ad2			    = 0,	        %% 数据2
						 ad3			    = 0,	        %% 数据3
						 ad4			    = 0,	        %% 数据4
						 ad5			    = 0		        %% 数据5
                        }).
%% 地图数据--NPC
-record(map_npc,        {
                         npc_id             = 0,            % NPC ID
                         func               = [],           % NPC功能列表
                         x                  = 0,            % NPC X坐标
                         y                  = 0             % NPC Y坐标
                        }).
%% 地图数据--传送门
-record(map_door,       {
                         door_id            = 0,            % 传送门 ID                    
                         type               = 0,            % 传送门 类型
                         door_x             = 0,            % 传送门 X坐标
                         door_y             = 0,            % 传送门 Y坐标
                         map_id             = 0,            % 传送门 目标地图ID
                         x                  = 0,            % 目标地图X坐标
                         y                  = 0             % 目标地图Y坐标
                        }).
%% 地图数据--角色
-record(map_player,     {
                         key                = {0, 0},       % {类型，对应user_id}
                         user_id            = 0,            % 玩家Id
                         user_name          = <<"">>,       % 昵称
                         pro                = 0,            % 职业
                         sex                = 0,            % 性别
                         lv                 = 0,            % 等级
                         vip                = 0,            % VIP
                         state              = 0,            % 状态
                         leader             = 0,            % 队伍队长user_id
                         
                         x                  = 0,            % X坐标
                         y                  = 0,            % Y坐标
                         
						 skin_fashion		= 0,			% 装备时装皮肤ID
                         skin_weapon        = 0,            % 装备武器皮肤ID
                         skin_step          = 0,            % 时装足迹皮肤id
                         skin_armor         = 0,            % 装备衣服皮肤ID
                         skin_ride          = 0,            % 坐骑皮肤ID
						 hide_fashion		= 0,			% 隐藏时装
						 hide_ride          = 0,            % 隐藏坐骑
                         title              = 0,            % 称号   
                         guild_id           = 0,            % 军团id
                         guild_name         = "",           % 军团名称 
                         guild_lv           = 0,            % 军团等级
                         position           = 0,            % 官衔
                         user_state         = 0,            % 玩家状态
                         practice_state     = 0,            % 修炼状态
                         other_user_id      = 0,            % 双修时，其他玩家的id
						 follow_id			= 0,			% 跟随武将id
						 vip_hide			= 0,				% vip等级隐藏标识
                         star_lv            = 0             % 将星
                        }).

%% 地图数据--宠物
-record(map_pet,        {
                         pet_user_id        = 0,            % 宠物主人ID
                         pet_id             = 0,            % 宠物ID
                         pet_lv             = 0,            % 宠物等级
                         pet_name           = 0,            % 宠物名字
                         pet_colour         = 0             % 宠物颜色
                        }).

%% 怪物
-record(monster, 	{
						 id					= 0,			% 怪物唯一ID
                         pos_x              = 0,            % 当前x
                         pos_y              = 0,            % 当前y
                         target_x           = 0,            % 目标x
                         target_y           = 0,            % 目标y
                         hp                 = 0,            % hp,非重生怪时，每次需要记录下来
						 anger        		= 0, 	        % 怒气
                         name               = <<"">>,       % 怪物名
						 
						 monster_id        	= 0, 	        % 怪物编号
						 type        		= 0, 	        % 怪物类型
						 pro                = 0, 	        % 职业
						 lv        			= 0, 	        % 等级
						 power        		= 0, 	        % 战力
						 skill        		= 0, 	        % 主动技能
                         genus_skill        = 0,            % 天赋技能
                         normal_skill       = 0,            % 普通攻击
						 move_speed        	= 0, 	        % 移动速度
						 map_id        		= 0, 	        % 所属地图
						 x        			= 0, 	        % 默认出生X
						 y        			= 0, 	        % 默认出生Y
						 attack_range_x     = 0, 	        % 攻击范围X
						 attack_range_y     = 0, 	        % 攻击范围Y
						 share				= 0,			% 怪物是否共享
						 renew				= 0,			% 是否重生
						 attr				= ?null,        % 怪物属性 #attr
						 
						 exp        		= 0, 	        % 怪物经验
						 hook_exp        	= 0, 	        % 挂机经验
						 gold        		= 0, 	        % 奖励铜钱
						 meritorious        = 0, 	        % 奖励历练
						 ai_id        		= 0, 	        % 怪物AI的ID
						 drop_id        	= 0, 	        % 掉落表ID
						 immune_buffs		= [],			% 免疫BUFF列表
						 camp        		= 0 	        % 怪物阵型 
						}).
