%% --------------------------------------------------
%% 战斗数据
%% --------------------------------------------------
-record(battle,				{
							 id					= 0,			%% 战斗唯一ID
							 type				= 0,			%% 战斗类型
							 report				= ?false,		%% 战报标示(true:要|false:不要)
							 map_pid			= 0,			%% 地图进程ID
							 enlarge_rate		= 0,			%% 伤害放大比例
							 refresh			= ?true,		%% 是否刷新战斗单元(初始化和新回合刷新)
							 bout				= 0,			%% 回合数
							 seq				= [],			%% 战斗序列[{side, idx, operate}]
							 operate			= [],			%% 战斗操作[{side, idx, operate}]
							 count_left			= 0,			%% 战斗单元数(左)
							 count_right		= 0,			%% 战斗单元数(右)
							 units_left			= 0,			%% 战斗单元集合(左)
							 units_right		= 0,			%% 战斗单元集合(右)
							 param				= ?null,		%% 战斗参数(战斗开始前传入)
							 
							 acc_buff_key		= 0,			%% BUFFID累加器(预留16位，最大65535)
							 
							 hurt_left			= 0,			%% 战斗总伤害(左)
							 hurt_right			= 0,			%% 战斗总伤害(右)
							 
							 cmds				= [],			%% 战斗指令累加(执行一次战斗清理一次)
							 cmd_atk			= ?null,		%% 技能攻击战斗指令(执行一次战斗清理一次)
							 cmd_def			= [],			%% 技能防御战斗指令累加(执行一次战斗清理一次)
							 cmd_genius			= [],			%% 天赋技能战斗指令累加(执行一次战斗清理一次)
							 cmd_resist			= [],			%% 反击战斗指令累加(执行一次战斗清理一次)
							 
							 genius_list		= [],			%% 天赋列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一次战斗清理一次)
							 resist_list		= [],			%% 反击列表(有资格反击攻击者的定位)[{Side, Idx}...](执行一次战斗清理一次)
							 
							 time				= 0,			%% 每次战斗时间累加(毫秒)(执行一次战斗清理一次)
							 
							 result				= 0,			%% 战斗结果
							 memory				= <<>>,			%% 战斗记忆

							 sleep				= ?false,		%% 战斗是否暂停
                             skip               = ?false,       %% 跳过战斗
							 first_seq			= [],			%% 优先需要出手的
							 forbid_dodge		= ?false,		%% 是否禁止闪避(true:禁止|false:不禁止即可以闪避)
							 forbid_parry		= ?false,		%% 是否禁止格挡(true:禁止|false:不禁止即可以格挡)
							 round_refresh		= ?false,		%% 是否刷新战斗轮数(车轮战时用 true：刷新|false：不刷新)
							 round				= 1,			%% 第几轮战斗(车轮战时用,默认一轮)
							 ai_packet			= <<>>			%% ai数据包
							}).
%% --------------------------------------------------
%% 战斗单元集合
%% --------------------------------------------------
-record(units,				{
							 side				= 0,			%% 战斗单元集合归属：0--左|1--右
                             serv_id            = 0,            %% 服务器id
							 id					= 0,			%% 主动战斗单元ID|被动战斗单元ID
							 camp				= ?null, 	    %% 阵型
							 units				= {},			%% 战斗单元列表
							 horse_attr			= ?null			%% 坐骑技能属性加成
							}).
%% --------------------------------------------------
%% 战斗单元
%% --------------------------------------------------
-record(unit,				{
							 type				= 0,			%% 战斗单元：1--玩家|2--武将|10--怪物
							 idx				= 0,			%% 阵型中的位置索引
							 state				= 0,			%% 战斗状态
%% 							 map_id				= 0,			%% 地图ID
							 pro				= 0, 			%% 职业
							 power				= 0, 			%% 战力
							 lv					= 0,			%% 等级
							 hp					= 0,			%% 当前生命
							 anger				= 0,			%% 怒气值
							 anger_max			= 0,			%% 怒气值上限
							 
							 attr				= ?null,		%% 属性
							 attr_base			= ?null,		%% 基础属性(初始值)
							 attr_ext			= ?null,		%% 附加属性(阵型附加、坐骑技能附加)
							 
							 normal_skill		= ?null,		%% 普通技能
							 active_skill		= {},			%% 主动技能
							 genius_skill		= [], 			%% 天赋技能(被动技能)
							 genius_trigger		= [],			%% 天赋技能(被动技能)已触发
							 
							 buff				= [],			%% Buff
							 buff_ext			= [],			%% 战斗外部BUFF列表
							 
							 resist				= ?false,		%% 是否必然反击标示(被动技能758专用)[?true:必然反击|?null:技能不再触发|?false:非必然反击]
							 target				= [],			%% 攻击目标
                             is_soul            = ?false,       %% 将魂技

							 unit_ext			= 0 			%% 战斗单元扩展
							}).
%% --------------------------------------------------
%% 战斗单元扩展
%% --------------------------------------------------
%% 角色
-record(unit_ext_player,	{
							 user_id			= 0,			%% 角色ID
							 name        		= <<>>,			%% 角色
							 country			= 0,			%% 国家
							 guild        		= 0,        	%% 军团
							 sex				= 0,			%% 性别
							 vip				= 0,			%% VIP等级
							 fashion			= 0,			%% 装备时装ID
							 armor				= 0,			%% 装备衣服ID
							 weapon				= 0,			%% 装备武器ID
							 partners			= [],			%% 副将ID列表
							 is_leader			= 0,			%% 是否是队长：?CONST_SYS_FALSE--不是|?CONST_SYS_TRUE--是
							 auto				= 0, 			%% 是否自动战斗:?CONST_SYS_FALSE--不是|?CONST_SYS_TRUE--是
							 online				= ?true,			%% 是否在线:?true:是 | ?false:否
                             psoul               = 0             %% 将魂
							}).
%% 伙伴
-record(unit_ext_partner,	{
							 partner_id			= 0,			%% 伙伴ID
							 armor				= 0,			%% 装备衣服ID
							 weapon				= 0,			%% 装备武器ID
							 partners			= [],			%% 副将ID列表
                             psoul              = 0             %% 将魂
							}).
%% 怪物
-record(unit_ext_monster,	{
							 monster_id			= 0,			%% 怪物ID
							 monster_unique_id	= 0, 			%% 怪物唯一ID
							 immune_buffs		= [],			%% 免疫BUFF列表
                             psoul              = 0             %% 将魂
							}).
%% 战斗参数
-record(param,				{
							 battle_type		= 0,			%% 战斗类型
							 attr				= [],			%% 属性加成
                             map_id             = 0,            %% 地图id
							 ai_list			= [],			%% ai列表
							 ai_partner			= [],			%% 体验武将列表
							 init_anger			= 0,			%% 初始怒气
							 robot				= [],			%% 机器人列表
							 cross_node			= 0,			%% 节点名
							 ad1			    = 0,	        %% 数据1
							 ad2			    = 0,	        %% 数据2
							 ad3			    = 0,	        %% 数据3
							 ad4			    = 0,	        %% 数据4
							 ad5			    = 0		        %% 数据5
							}).

%% 战斗操作
-record(operate,			{
							 key				= 0,			%% 主键:{side,idx}
							 speed				= 0,			%% 出手速度
							 skill_idx			= 0,			%% 技能索引
							 skill				= ?null			%% 战斗所选技能
							}).

%% 天赋技能所需参数
-record(genius_param,		{
							 trigger			= 0,			%% 触发点
							 atk_type			= 0,			%% 攻击类型
							 crit			    = ?false,       %% 暴击(?true|?false)
							 hurt				= 0,			%% 伤害值
							 death				= ?false,		%% 死亡(?true|?false)
                             dodge              = ?false,       %% 闪避(?true|?false)
                             parry              = ?false,       %% 格挡(?true|?false)
                             resist             = ?false,       %% 反击(?true|?false)
                             hit                = ?false        %% 命中(?true|?false)
							}).

%% 战斗临时参数
-record(temp_param,			{
							 hit				= ?false,		%% 命中(?true|?false)
							 dodge				= ?false,		%% 闪避(?true|?false)
							 crit			    = ?false,       %% 暴击(?true|?false)
							 parry				= ?false,       %% 招架(?true|?false)
							 resist				= ?false,		%% 反击(?true|?false)
							 death				= ?false,		%% 死亡(?true|?false)
							 hurt				= 0 			%% 伤害值
							}).



