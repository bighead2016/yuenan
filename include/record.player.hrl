%%%% Net
-record(client, 		{
						 login_key			= 0,			% 登陆Key
						 root_key			= 0,			% 根Key
						 app_key			= 0,			% 应用Key
						 resource_key		= 0,			% 资源KEY
						 
						 sn					= 0,			% 数据包序列号[1-65535]
						 
						 serv_id			= 0,			% [M]服务器ID
						 serv_unique_id		= 0,			% [M]服务器唯一ID
						 user_id 			= 0,			% [M]玩家ID
						 net_pid			= 0,			% 玩家Net进程ID
						 reg_name			= 0,			% 注册名
						 player_pid			= 0,			% 玩家游戏逻辑进程ID
						 ip					= 0,	        % [M]玩家IP
						 socket				= 0,			% Socket
						 ref				= 0,			% Ref
						 binary				= <<>>,			% Binary
						 state  			= 1,			% [M]状态
						 user_state         = 0,           	% [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
						 heart				= ?null,		% 心跳record
						 time               = 0,           	% [M]登录时间
						 fcm				= ?null,		% [M]防沉迷record
                         delay_packet       = <<>>,         % 累计包
						 times				= 0,			% [M]闪断重连次数
                         serv_state         = 0,             % 服务器当前状态
                         rece_pack 			= 0 			% 收包数
						}).

-record(mini_client, 	{
						 serv_id			= 0,			% [M]服务器ID
						 serv_unique_id		= 0,			% [M]服务器唯一ID
						 user_id 			= 0,			% [M]玩家ID
						 ip					= 0,	        % [M]玩家IP
						 state  			= 1,			% [M]状态
						 user_state         = 0,           	% [M]玩家状态  0：封号|1:普通玩家|2：指导员|3：GM
						 time               = 0,           	% [M]登录时间
						 fcm				= ?null,		% [M]防沉迷record
						 times				= 0				% [M]闪断重连次数
						}).

-record(heart, 			{
						 heart				= 0,			% 收到心跳时间
						 bad				= 0,			% 连续错误心跳次数
						 tsp				= 0,	 		% 时间同步协议(Time Synchronization Protocol)
						 db					= 0,			% 数据库
						 gc					= 0,			% player进程GC
						 ip					= 0 			% 统计在线IP
						}).
-record(fcm,			{
						 game_time			= 0,	        % 防沉迷-游戏时长
						 fcm_state			= 0,	        % 防沉迷-状态
						 fcm_next			= 0		        % 防沉迷-下次触发时间
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 角色record
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(player,         {
						 user_id            = 0,            % [First]玩家ID
						 serv_id            = 0,            % [Temp]服务器ID
						 serv_unique_id     = 0,            % [Temp]服务器唯一ID
						 net_pid            = 0,            % [Temp]玩家Net进程ID
						 ip					= ?null,		% [Temp]玩家登陆IP
						 account			= <<"">>,		% [Temp]玩家平台帐号
						 map_pid            = 0,            % [Temp]玩家地图进程ID
						 battle_pid         = 0,            % [Temp]玩家战斗进程ID
                         is_skiped          = 0,            % [Temp]跳过标示
                         can_skip           = 0,            % [Temp]可跳过标志
                         battle_type        = 0,            % [Temp]战斗类型
						 state              = 0,            % [Temp]状态  0：封号|1:普通玩家|2：指导员|3：GM
                         user_state         = 0,            % [Temp]玩家状态 '战斗'|'站立'|'死亡',
                         play_state         = 0,            % [Temp]玩家当前所在玩法 '温泉'...,
                         practice_state     = 0,            % [Temp]修炼状态 '单修'|'双修'
						 date_login			= 0,			% [Temp]登录日期
						 time_login         = 0,            % [Temp]登录时间
						 team_id			= 0,			% [Temp]玩家队伍ID		todo
						 leader				= 0,			% [Temp]队长user_id		todo
						 attr_group			= ?null,		% [Temp]角色属性集合 
                         attr_rate_group    = ?null,        % [Temp]角色属性比例加成集合
						 attr_assist		= ?null,		% [Temp]角色副将加成#attr{}
						 attr_culti			= ?null,		% [Temp]角色祭星加成值#attr{}
                         attr_reflect       = ?null,        % [Temp]受别人的属性，而产生的属性加成集合
                         attr_sum           = ?null,        % [Temp]角色相加属性#attr{} = sigma(attr_sum)
                         attr_sum_reflect   = ?null,        % [Temp]受别人的属性，而产生的属性加成的和
                         shop_temp_list     = [],           % [Temp]商店回购列表
						 tower_passid		= 0,			% [Temp]当前闯塔关卡
                         offline_packet     = <<>>,         % [Temp]上线时用的临时包，在login_pakcet发后，这个包会发到最后
                         broadcast_packet   = <<>>,         % [Temp]临时广播包
						 reconnect			= ?false,		% [Temp]断线重连标示(true:允许断线重连|false:不允许断线重连)
						 access_time		= 0,            % [Temp]最后访问时间(离线数据中使用)
						 logs_tmp			= 0,			% [Temp]临时登陆日志
                         can_gm             = 0,            % [Temp]0不能用gm;1能用gm

						 info               = ?null,        % [First]积累信息#info{}
						 buff				= [],			% [First]BUFF列表
						 mcopy_buff			= [],           % [First]多人BUFF列表
						 
						 attr               = ?null,        % [First]角色最终属性
            												% #attr{} = sigma(attr_group) * (attr_rate_group) + sigma(attr_assist) + sigma(attr_reflect)
						 equip              = ?null,        % [First]装备[{{UserId, CtnType}, #ctn{}}]  todo
						 skill              = [],        	% [First]技能#skill_data{}
						 camp				= ?null,		% [First]阵型#camp_data{}  todo
						 position           = 0,            % [First]官衔#position_data{}
						 partner   			= ?null,		% [First]武将#partner_data{}
						 guild				= ?null,		% [First]军团#guild{}
						 mind				= ?null,		% [First]心法#mind_data{}
						 train 				= ?null,        % [First]培养的三个一级属性旧值和新值
						 partner_soul		= ?null,        % [First]将魂
						 tower				= [],			% [First]破阵[{Type, Value}]
                         style              = ?null,        % [First]时装#style_data{}
						 maps               = ?null,        % [Second]地图信息#map_data{}
						 
						 bag                = ?null,        % [Second]背包#ctn{}
						 depot              = ?null,        % [Second]仓库#ctn{}
                         temp_bag           = ?null,        % [Second]临时背包#ctn{}
						 sys_rank           = ?null,        % [Second]最新开放系统ID
						 task               = ?null,        % [Second]任务#task_data{}
						 copy               = ?null,        % [Second]副本#copy_data{}
						 ability			= ?null,		% [Second]内功#ability_data{}
						 achievement        = ?null,        % [Second]成就#achievement{}
						 practice			= ?null,		% [Second]修炼[]
						 resource			= ?null,		% [Second]资源系统#resource{}
						 lottery			= ?null,		% [Second]淘宝系统#lottery{}
						 spring				= ?null,		% [Second]温泉系统#spring{}
						 furnace			= ?null,  		% [Second]炼炉系统#furnace_data{}
						 guide				= ?null,		% [Second]新手指引#guide_data{}
                         invasion           = ?null,        % [Second]异民族#invasion_data{}
						 schedule			= ?null,		% [Second]课程表#schedule_data{}
                         bless              = ?null,        % [Second]祝福#bless_data{}
                         mcopy              = ?null,        % [Second]多人副本#mcopy_data{}
						 welfare			= ?null,		% [Second]福利系统#welfare{}   todo
						 war_guild			= ?null,		% [Second]军团战(预留)
						 new_serv			= ?null,		% [Second]新服活动#new_serv{}
						 weapon				= ?null,		% [Second]神兵#weapon_data{}
						 lookfor			= ?null,  		% [Second]寻访武将#lookfor_data{}
                         horse              = ?null,        % [Second]坐骑#horse_data{}
                         fund               = ?null,        % [Second]基金[]
                         teach              = ?null,        % [Second]教学#teach_data{}
                         tencent 			= ?null 		% [Second]腾讯接入#tencent_data{}

				}).

%% 属性
-record(info,           {
						 attr_rate			= 0,			% 属性系数
						 user_name          = <<"">>,	    % 角色名称
						 pro                = 0,            % 职业
						 sex                = 0,            % 性别
						 country			= 0,   			% 国家  0：无国家|1：魏国|2：蜀国|3:吴国
						 lv                 = 0,            % 等级
						 exp                = 0,            % 经验值：玩家升级的一种方式
						 expn               = 0,            % 下级要多少经验
						 expt               = 0,            % 总共集了多少 经验
						 exp_time           = 0,            % 获取经验时间
						 hp                 = 0,            % 生命值（现有）
						 sp                 = 0,            % 体力值（现有）
						 sp_temp            = 0,            % 体力值（临时）
                         sp_buy_times       = 0,            % 体力已购买次数
						 vip                = 0,            % #vip{}
						 chat_status		= 0,			% 是否禁言    0：正常 1：禁言						 
						 ban_over			= 0,			% 账号解封时间
						 shutup_over		= 0,			% 禁言解除时间
						 first_consume		= 0,			% 首次消费 0非首次 1首次
						 honour				= 0,			% 成就点
						 meritorious		= 0,			% 功勋
						 meritorioust		= 0,			% 已获得功勋
						 exploit            = 0,            % 军团贡献度
						 skill_point		= 0,			% 技能点
						 experience			= 0,			% 历练(该字段暂时废弃)
						 see				= 0,			% 阅历
						 power 				= 0,            % 战力
						 anger              = 0,			% 怒气
						 buy_point			= 0,			% 购买积分
						 current_title      = 0,            % 当前称号id
						 encourage			= {0, 0},		% 鼓舞百分数
                         cultivation        = 0,            % 修为值
						 culti_flag			= 0,			% 是否第一次打开祭星(0是1否)
						 gifts				= [],			% 领取过的礼包类型列表
						 gift_cash			= ?false,		% 是否领取过登陆赠送元宝
						 assist_partner		= {0,0,0,0},	% 副将
                         time_last_off      = 0,            % 最近一次离线时间 unix元年制
                         time_active        = 0,            % 最近一次上线/离线时间 unix元年制

						 date				= 0,     		% 用于跨日刷新数据 
                         free_skip_times    = 0,            % 免费跳过次数
                         camp_score         = 0,            % 阵营战积分 
                         is_newbie          = 0,            % 新手?
						 stone_num			= 0,			% 四级或以上宝石的数量
                         is_draw            = 0,            % 是否已领取老玩家回归礼包
                         is_auto            = 0,             % 自动战斗?
                         test_server_time   = 0,            % 最近一次领取体验服时间
						 cross_arena_flag	= 0				% 是否可以跨服(0需打机器人1可以跨服)
						}).

%% VIP数据
-record(vip,			{
						 lv					= 0,			% VIP等级
						 gift				= [],			% 已领取过VIP礼包的VIP
						 date				= 0,			% 日期
						 daily				= ?false		% 是否已领取VIP日常奖励
						}).

%% 货币类
-record(money,          {
						 user_id			= 0,			% 角色ID
						 account			= <<"">>,		% 平台帐号
						 first_consume		= 0,			% 首次消费标志 0非首次 1首次
						 cash               = 0,            % 元宝
						 cash_sum           = 0,            % 累积元宝总量
						 cash_bind          = 0,            % 礼券
                         cash_bind_2        = 0,            % 绑定元宝
						 gold               = 0,            % 铜币
						 gold_bind          = 0,            % 绑定铜币
                         cash_bind_3        = 0             % 保留字段
						}).

%% 角色属性集合
-record(attr_group,		{
						 lv					= ?null,		% #attr{}角色基础属性(等级)
						 train				= ?null,		% #attr{}角色培养属性
						 position			= ?null,		% #attr{}角色官衔
						 title				= ?null,		% #attr{}角色称号
						 equip	            = ?null,		% #attr{}角色装备属性(装备)
						 skill	            = ?null,		% #attr{}技能
						 ability			= ?null,		% #attr{}内功
						 camp				= ?null,		% #attr{}阵法
						 mind				= ?null,		% #attr{}心法
						 guild				= ?null,        % #attr{}军团
						 tower				= ?null,		% #attr{}破阵
						 weapon				= ?null,		% #attr{}神兵
						 cultivation		= ?null,		% #attr{}修为
						 lookfor			= ?null,		% #attr{}寻访激活武将
						 assemble			= ?null,	    % #attr{}武将组合
						 partner_soul		= ?null,		% #attr{}将魂
						 partner_star		= ?null			% #attr{}将星
						}).

%% 角色属性比例加成集合
-record(attr_rate_group, {
						  cultivation		= ?null,        % 修为
						  buff				= ?null,        % []buff列表
						  mcopy_buff		= ?null,		% []多人副本buff列表
						  suit				= ?null,		% 套装
						  title				= ?null,		% 称号
                          equip             = ?null
						 }).

%% 受别人属性影响的加成集合
-record(attr_reflect,   {
                         group              = ?null         % 常规组队
                        }).

%% 属性
-record(attr, 			{
						 force		 		= 0, 			% 力(一级)
						 fate		 		= 0, 			% 命(一级)
						 magic		 		= 0, 			% 术(一级)
						 
						 attr_second		= ?null,		% 二级属性#attr_second{}
						 
						 attr_elite			= ?null			% 精英属性#attr_elite{}
						}).
%% 二级属性
-record(attr_second, 	{
						 hp_max				= 0,            % 气血(二级)
						 force_attack		= 0,            % 物攻(二级)
						 force_def			= 0,            % 物防(二级)
						 magic_attack		= 0,            % 术攻(二级)
						 magic_def			= 0,            % 术防(二级)
						 speed				= 0             % 速度(二级)
						}).
%% 精英属性
%%
%% e               cx                  ch-sz               ch-xt
%% hit             命中              命中悟性            命中
%% dodge           躲闪              躲闪悟性            闪避
%% crit            暴击              暴击悟性            暴击
%% parry           招架              招架悟性            格挡
%% resist          反击              反击悟性            反击
%% crit_h          暴击伤害            暴击伤害悟性      无双
%% r_crit          降低暴击            降低暴击悟性      分影
%% parry_r_h       格挡减伤            格挡减伤悟性      坚韧
%% r_parry         降低格挡            降低格挡悟性      破袭
%% resist_h        反击伤害            反击伤害悟性      凝神
%% r_resist        降低反击            降低反击悟性      吉运
%% r_crit_h        降低暴击伤害      降低暴击伤害悟性     相性
%% i_parry_h       无视格挡伤害      无视格挡伤害悟性     致命
%% r_resist_h      降低反击伤害      降低反击伤害悟性     意念
-record(attr_elite, 	{
						 hit			    = 0,            % 命中(精英)
						 dodge			    = 0,            % 躲闪(精英)
						 crit			    = 0,            % 暴击(精英)
						 parry			    = 0,            % 招架(精英)
						 resist			    = 0,            % 反击(精英)
						 crit_h		        = 0,            % 暴击伤害(精英)
						 r_crit	            = 0,            % 降低暴击(精英)
						 parry_r_h		    = 0,            % 格挡减伤(精英)   
						 r_parry	        = 0,            % 降低格挡(精英)  
						 resist_h	        = 0,            % 反击伤害(精英)
						 r_resist	        = 0,            % 降低反击(精英)
						 r_crit_h	        = 0,            % 降低暴击伤害(精英)
						 i_parry_h	        = 0,            % 无视格挡伤害(精英)
						 r_resist_h	        = 0             % 降低反击伤害(精英)
						}).

%% 玩家武将数据
-record(partner_data,   {
						follow_id			= 0, 			%% 跟随武将id
						list                = []			%% 武将列表 #partner{}
						}).


%% 武将信息表
-record(partner, 		{
						 partner_id 		= 0,            %% 伙伴ID
						 partner_name		= "",			%% 伙伴名称
						 type				= 0, 			%% 类型（1剧情，2破阵，3寻访）
						 pro				= 0, 			%% 职业
						 sex				= 0, 			%% 性别
						 normal_skill		= 0,			%% 普通攻击技能id
						 active_skill		= 0, 			%% 技能
						 genius_skill		= 0, 			%% 被动技能
						 color				= 0, 			%% 品质
						 rate				= 0, 			%% 成长系数
						 assemble_id		= 0, 			%% 组合
						 assemble_partner_id = [],			%% 组合的武将id
						 assemble_addition	= 0,			%% 组合加成
						 
						 gold				= 0, 			%% 招募所需铜钱
						 init_love_goods	= [], 			%% 培养忠诚度所需道具
						 player_lv			= 0, 			%% 开放等级
						 partner_bag_id		= 0, 			%% 武将包id
					     partner_bag_rate	= 0,			%% 武将包权重
						 call_on_goods		= [],			%% 拜见获得兵书
						 call_on_see		= 0,			%% 拜见获得阅历
						 look_attr			= ?null,		%% 寻访激活属性

						 lv 				= 1,            %% 等级
						 exp 				= 0,            %% 经验
						 expn               = 0,            %% 下级要多少经验
						 hp 				= 0,            %% 气血
						 
						 attr				= ?null,		%% 武将属性#attr{}
						 attr_group			= ?null,		%% 武将属性集合
						 attr_rate_group    = ?null,        %% 角色属性比例加成集合
						 attr_assist		= ?null,		%% 副将加成#attr{}
						 attr_culti			= ?null,		%% 角色祭星加成值#attr{}
						 attr_sum           = ?null,        %% 角色相加属性#attr{} = sigma(attr_sum)
						 attr_reflect		= ?null,        %% 受别人的属性，而产生的属性加成#attr_reflect{}
						 attr_reflect_sum   = ?null,        %% 受别人的属性，而产生的属性加成集合

						 train				= 0,			%% 培养的一级属性旧值和新值
						 
						 partner_soul		= ?null,        %% 将魂#partner_soul{}
						 
						 anger 				= 0, 		    %% 气势
						 team 				= 0,            %% 队伍（可招募/招贤馆中，1已招募/在队伍中2可寻访/寻访列表中）
						 power 				= 0,            %% 战力
						 is_skipper 		= 0,            %% 是否主将(0,普通，1为主将，2为副将)
						 assist	 			= {0,0,0,0},    %% 副将
						 is_recruit			= 0  			%% 是否被招募过(0未被招募1被招募过)
%% 						 expire_stamp		= 0				%%  武将到期时间戳
						}).

%% 将魂数据
-record(partner_soul,   {
						 lv  				= 0,            %% 将魂等级
						 exp				= 0,            %% 将魂经验
						 star_lv			= 0,            %% 将魂星等级
						 skill_lv			= 0,			%% 将魂技等级
						 skill_id			= 0				%% 将魂id
						}).

%% 玩家寻访数据
-record(lookfor_data,   {
						look_flag_1			= ?true,		%% 寻访标志1(是否第一次寻访)
						look_flag_2			= ?true,		%% 寻访标志2(是否第二次寻访)
						look_flag_3			= ?true,		%% 寻访标志3(是否第一次寻访)
						look_cash_bind		= 0,			%% 每日寻访优先使用礼券次数
						look_stamp			= 0,			%% 寻访冷却时间戳
						lucky				= 0,			%% 寻访幸运值
						looking_list		= [],			%% 寻访待处理的武将(永远只有一个)
						looked_list         = [],			%% 已寻访激活的武将列表
						assemble_list		= [],			%% 组合信息列表#assemble{}
						look_new_list		= [],			%% 新投放未被查看武将列表
						look_new_ass		= [],			%% 新开启未被查看的组合列表
						date				= 0,			%% 用于跨日刷新数据
						look_bag_list		= []			%% 武将包列表	
						}).
%% 组合信息表
-record(assemble,    {
						 id					= ?null,		%% 组合id
						 lv					= ?null,		%% 组合等级
						 exp				= ?null			%% 组合当前经验
						}).
%% 成就信息表
-record(achievement,    {
						 data				= ?null,		%% 所获得的成就数据
						 gifts				= ?null,		%% 已兑换的所有礼品
						 times				= ?null,
						 title_data			= []			%% 称号记录
						}).

%% 成就系统定义partner_data
-record(achievement_data,	{
							 id				= 0,			%% 成就ID
							 flag			= ?false,		%% 是否完成
							 times			= 0,			%% 完成次数
							 time			= 0				%% 完成时间
							}).

-record(title_data,			{
							 id				= 0,			%% 称号ID
							 unique			= 0,			%% 唯一性
							 flag			= ?false,		%% 是否完成
							 time			= 0				%% 完成时间
							}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家邮件数据 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(mailbox,   	{
					 count       			= 0,	        % 邮件数量
					 mails       			= ?null         % 邮件数据#mail{}
					}).
-record(mail,		{
					 mail_id				= 0,			% 邮件ID
					 type					= 0,			% 邮件类型(系统:0|私人:1)
					 send_uid				= 0,			% 发件人UserId
					 send_name				= <<>>,			% 发件人名字
					 send_sex				= 0,		    % 发件人性别
					 recv_uid				= 0,			% 收件人UserId
					 recv_name				= <<>>,			% 收件人名字
					 title					= <<>>,			% 标题
					 time					= 0,			% 时间
					 content				= <<>>,			% 内容
					 message_id				= 0,            % 消息id
					 content1				= [],			% 消息内容
					 cash					= 0,			% 元宝
					 bcash					= 0, 			% 绑定元宝
					 gold					= 0,			% 铜币
					 goods					= [],			% 物品列表
					 is_read				= 0,			% 邮件状态(未读:0|已读:1)
					 is_save				= 0,			% 邮件状态(未读:0|已读:1)
					 is_pick				= 0,			% 附件是否提取(无附件:0|未提取:1|已提取:2)
					 point					= 0,     		% 功能消费点
                     bcash2                  = 0             % 绑定元宝
					}).

-record(resource,	{
					 date					= 0,			% 日期
					 tot_rune_cnt			= 0,			% 招财累计使用次数（用于计算招财宝箱）
					 rune_cnt				= 0,			% 招财当天使用次数
					 rune_tips				= ?true,		% 招财提示（默认提示）
					 rune_chest				= [],			% 招财宝箱记录[{招财宝箱ID, 招财宝箱数量}]
					 pray_cnt				= 0,			% 拜将当天使用次数
                     pool_cd                = 0,             % 奖池cd
                     pool_gift_limit    =0              %礼券大奖次数
					}).

-record(chest_data,	{
					 chest_id				= 0,			% 宝箱ID
					 chest_num				= 0				% 宝箱数量
					}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家技能数据 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(skill_data,		{
						 skill_bar			= ?null,		% 技能栏
						 skill				= []			% 技能列表[{SkillId, Lv, Time}, {SkillId, Lv, Time}]
						}).
-record(skill,			{
						 skill_id			= 0, 			%% 技能id
						 lv					= 0, 			%% 等级
						 lv_max			    = 0, 			%% 最大等级
						 type			    = 0, 			%% 技能类型
                         skill_type         = 0,            %% 1近；其他，远
						 belong			    = 0, 			%% 技能归属
						 pro			    = 0, 			%% 职业
						 name				= <<"">>, 		%% 技能名称
						 skill_cd			= 0, 			%% 冷却时间(升级)
						 cd					= 0, 			%% 冷却回合(使用)
						 time				= 0, 			%% 技能消耗时间(毫秒)
						 condition			= 0, 			%% 条件状态
						 counter			= 0, 			%% 是否反击
						 skill_hit			= 0,			%% 技能命中加成
						 anger				= 0, 			%% 消耗怒气
						 prev_skill			= 0, 			%% 前置技能（列表格式为[{技能id,等级}]）
						 lv_player			= 0, 			%% 玩家等级
						 skill_point		= 0, 			%% 技能点
						 gold				= 0, 			%% 所需铜钱
						 goods_id			= 0, 			%% 所需物品id
						 goods_count		= 0, 			%% 所需物品数量
						 ratio				= 0,			%% 技能系数
						 plus				= 0,			%% 技能加成
						 effect				= ?null, 		%% 技能效果

                         cd_temp            = 0             %% 还剩回合数
						}).

-record(effect,			{
						 effect_id			= 0, 			%% 技能效果id
						 arg1				= 0, 			%% 参数1
						 arg2				= 0, 			%% 参数2
						 arg3				= 0, 			%% 参数3
						 arg4				= 0, 			%% 参数4
						 arg5				= 0, 			%% 参数5
						 arg6				= 0, 			%% 参数6
						 arg7				= 0, 			%% 参数7
						 arg8				= 0, 			%% 参数8
						 arg9				= 0, 			%% 参数9
						 arg10				= 0 			%% 参数10
						}).

-record(buff,			{
						 buff_id        	= 0,            %% ID
						 buff_type          = 0,            %% 类型
						 buff_value         = 0,            %% 值
						 priority			= 0,            %% 优先级
						 relation		    = 0,            %% 同类型BUFF关系
						 oppose_buff_type	= [],			%% 对立BUFF类型列表
						 limit        	    = 0,            %% 叠加上限
                         nature          	= 0,            %% BUFF性质：1积极|2消极
						
						 source				= 0,            %% BUFF来源
						 trigger			= 0,			%% BUFF触发时机
						 install_point		= 0,			%% BUFF安装点
						 odds        		= 0,            %% 生效几率
						 expend_type     	= 0,            %% 消耗类型
						 expend_value    	= 0,            %% 消耗值
						 
						 arg1				= 0,			%% 参数1
						 arg2				= 0,			%% 参数2
						 arg3				= 0,			%% 参数3
						 arg4				= 0 			%% 参数4
						}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家官衔数据 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(position_data,	{
						 position			= 0,			% 当前官衔ID
						 date				= 0				% 领取俸禄日期
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 内功
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 内功数据
-record(ability_data, 	{
						 ability               	= [],      		% 内功 [#ability{}]
						 cd						= 0,			% 总CD
						 date					= 0,			% 日期
						 upgrade_times     		= 0             % 当天升级次数
						}).
%% 内功的实例数据
-record(ability, 		{
						 ability_id           	= 0,            % 内功id
						 lv                     = 0,            % 等级
						 ability_ext         	= []            % 八门列表[{ExtId, N, Count}, {ExtId, N, Count}...]
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 阵型
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 阵型数据
-record(camp_data, 		{
						 camp               	= [],      		% 阵型 [#camp{}]
						 camp_use				= 0				%  当前使用的阵型
						}).
%% 阵型的实例数据
-record(camp, 			{
						 camp_id           		= 0,            		% 阵法id
						 lv                     = 0,            		% 等级
						 position               = {0,0,0,0,0,0,0,0,0}	% 阵型 {#camp_pos, ...} 固定9个格子
						}).
%% 站位
-record(camp_pos, 		{
						 idx                    = 0,            % 第几格
						 type                   = 0,            % 类型：1玩家，2伙伴
						 id                     = 0             % 对应的id:user_id/partner_id
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 队伍
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 队伍信息
-record(team,               {
							 team_id					= 0,        % 队伍ID
							 team_pid					= 0,		% 队伍进程ID
							 type                       = 0,        % 队伍类型
							 state						= 0,		% 队伍状态
							 lock						= <<"">>,	% 加锁密码
							 operate_mode				= 0,		% 队伍操作模式(用于切换地图1:队长操作|2:成员操作)
							 count		    			= 0, 		% 队伍人数
							 count_max	    			= 0, 		% 队伍人数上限
							 avg_lv						= 0,		% 队伍平均等级
							 leader_uid                 = 0,        % 队长ID
							 leader_name                = <<"">>,   % 队长名称 
							 leader_pro                 = 0,        % 队长职业
							 leader_sex                 = 0,        % 队长性别
							 leader_lv                  = 0,        % 队长等级
							 camp                       = [],       % #camp{},
							 invite						= [],		% 邀请列表[UserId, UserId, UserId...]
							 param                     	= 0,         % 队伍参数#team_param{}
                             author_list                = [],        %授权列表
                             cross_list                 = [],
                             last_quick_enter_time_dict       = dict:new()
							}).
%% 队伍参数
-record(team_param,         {
							 id							= 0,		%% ID
							 count_max	    			= 0, 		%% 队伍人数上限
							 arg1				        = 0, 		%% 参数1
							 arg2				        = 0, 		%% 参数2
							 arg3				        = 0 		%% 参数3
							}).

-record(team_author, {
                        key = {0,0},
                        name = "",
                        lv = 0,
                        career = 0,
                        team_to = [],
                        team_from = [],
                        is_guild_all = false,
                        last_add_count_time = 0,
                        times = 0
                    }).

-record(team_invite_cd, {
                         key = {},
                         last_invite_time = 0
                         }).

-record(team_cross, {
                     key, %% {team_id, serv_id}
                     team_type,
                     copy_id,
                     level,
                     count,
                     max_count
                     }).

%% 队伍成员信息
-record(team_player,        {
							 uid		                = 0,        % 玩家ID
							 name                       = <<"">>,   % 名称
							 pro                        = 0,        % 职业
							 sex                        = 0,        % 性别
							 lv                         = 0,        % 等级
							 state                      = 0,        % 状态
							 position					= 0,		% 官衔
							 power						= 0,		% 战力
							 partners					= [],		% 副将列表
							 skin_fashion               = 0,        % 装备时装皮肤ID
							 skin_weapon                = 0,        % 装备武器皮肤ID
                             skin_armor                 = 0,        % 装备衣服皮肤ID
							 hide_fashion				= 0,		% 隐藏时装
							 hide_ride          		= 0,         % 隐藏坐骑
                             index_from                 = 1,
                             is_gold_author                  = false
							}).
%% 大厅角色信息
-record(team_hall,       	{
							 uid		                = 0,        % 玩家ID
							 name                       = <<"">>,   % 名称
							 pro                        = 0,        % 职业
							 sex                        = 0,        % 性别
							 lv                         = 0         % 等级
							}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家拍卖数据 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(market_sale, 	{
      					sale_id  			= 0,            %% 自增寄售ID	
      					seller_id 			= 0,            %% 寄售者ID	
      					seller_name 		= <<>>,         %% 寄售者昵称	
						buyer_id  			= 0,            %% 购买者id	
						buyer_name  		= <<>>,         %% 购买者昵称	
						goods       		= [],           %% 物品列表
						goods_name			= <<>>,			%% 物品名称	
						category			= 0,		    %% 搜索种类
						goods_type  		= 0,            %% 物品类型	
						goods_sub_type  	= 0,            %% 物品子类型	
						goods_level  		= 0,            %% 物品等级限制	
						goods_color  		= 0,            %% 物品颜色
						goods_pro  			= 0,            %% 职业限制	
						goods_attr_type		= 0,			%% 物品宝石属性	
						current_price 		= 0,            %% 出售价格：当前价格	
						fixed_price 		= 0,            %% 出售价格：一口价格	
						end_time 			= 0             %% 寄售物品的过期时间
    					}).

-record(market_buy, 	{	
      					buy_id  			= 0,            %% 自增购买ID	
      					seller_id 			= 0,            %% 寄售者ID	
      					seller_name 		= <<>>,         %% 寄售者昵称	
						buyer_id  			= 0,            %% 购买者id	
						buyer_name  		= <<>>,         %% 购买者昵称	
						goods       		= [],           %% 物品列表
						goods_name			= <<>>,			%% 物品名称	
						category			= 0,			%% 搜索种类
						goods_type  		= 0,            %% 物品类型	
						goods_sub_type  	= 0,            %% 物品子类型	
						goods_level  		= 0,            %% 物品等级限制	
						goods_color  		= 0,            %% 物品颜色	
						goods_pro  			= 0,            %% 职业限制
						goods_attr_type		= 0,			%% 物品宝石属性	
						current_price 		= 0,            %% 出售价格：当前价格
						fixed_price 		= 0,            %% 出售价格：一口价格	
						bid_price			= 0,			%% 玩家竞拍的价格
						end_time 			= 0,            %% 寄售物品的过期时间
						sale_id				= 0				%% 寄售记录
    					}).

-record(market_search,  {
						goods_id			= 0,			%% 物品id
						goods_name			= <<>>,			%% 物品名称
						search_times   		= 0				%% 搜索次数
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(guild,          {
						 guild_id 			= 0,			% 军团id
						 guild_name			= <<"">>,		% 军团名称
						 guild_pos 			= 0,			% 军团职位
						 guild_magic        = [],           % 军团术法列表
						 donate_time		= 0,			% 捐献时间
 						 donate_sum			= 0,			% 总贡献
						 donate_gold		= 0,			% 捐献铜钱
						 
						 ad1				= ?null,
						 ad2				= ?null
						}). 



-record(lottery,		{
						 date				= 0,			% 日期
						 moral				= 0,			% 人品值
						 warehouse			= ?null			% 宝箱仓库
						}).

-record(spring,			{
						 time				= 0,			%% 本次进入温泉时间（秒）
						 flag				= 0				%% 活动标示
%% 						 count				= 0 			%% 累计温泉次数
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 常规组队
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(group,
						{
						id,                                 %% 自增id	
                        name,                               %% 队伍名=队长名	
                        lv 	                = 0,            %% 队伍等级=队长等级	
                        online_num          = 0,            %% 在线人数	
                        in_group_num        = 0,            %% 队中已加人数	
                        leader_id           = 0,            %% 队长id	
                        country             = 0,            %% 队伍国家=队长国家	
                        guild_id            = 0,            %% 队伍军团=队长军团
						guild_name			= <<>>,			%% 队伍名称	
                        member_list			= [],          	%% 成员列表	
                        online_member_list	= [],           %% 在线成员列表	
                        limit,          					%% 1无限制 2所在国家 3所在军团	
						apply_mount			= 0,			%% 被申请总数
						pro_list			= []            %% 加入队伍中人员的职业
						}).

-record(group_apply,	{
						 id,								%% 自增id
						 user_id,                           %% 申请玩家id	
                         lv                 = 0,            %% 等级
                         pro                = 0,            %% 职业                              
                         type,                              %% 申请类型 1.player->group;2.group->player.	
                         group_id           = 0,            %% 申请队伍ID	
						 state				= 0				%% 玩家状态0无状态 2已在对伍3申请成功4申请失败						
						 }).

%% 玩家状态
-record(states,        {
                        is_raid             = 0             %% 副本扫荡中?
                        }).

%% 新手指引
-record(guide,			{
						 module				= 0,			%% 模块ID
						 state				= 0,			%% 状态：0：未开启；1：已完成；2：正在进行。
                         is_got             = 0             %% 领取状态：0未领取；1已领取
						}).

-record(invasion,		{
						 date				= 0,
						 times				= 0,
						 data				= ?null
						}).

%% 异民族结构
-record(invasion_data,  {
						 copy				= 0,
						 times				= 0,
						 amount				= 0
                        }).

%% 课程表结构
-record(schedule,		{
						 date				= 0,			%% 日期
						 month				= 0,			%% 月份：作为玩家每月清零的依据
						 accum_times		= 0,			%% 累积签到次数
						 cont_times			= 0,			%% 连续签到次数
						 sign				= [],			%% 签到日期列表
						 sign_gift			= [],			%% 签到礼品ID
						 activity			= [],			%% 日常活动
						 liveness			= 0,			%% 活跃度
						 guide				= [],			%% 日常引导
						 liveness_gift		= [],			%% 活跃度礼品ID
						 refit_times		= 0				%% 已经补签次数
						}).

%% 课程表结构
-record(schedule_activity,	{
							 type			= 0,			%% 类型：1、日常活动；2、日常引导。
							 id				= 0,			%% 日常活动ID或日常引导ID
							 date			= 0,			%% 日期
							 times			= 0,			%% 完成次数
							 auto			= ?false		%% 是否自动完成（替身娃娃）
							}).

%% 课程表结构
-record(schedule_gift,	{
						 id					= 0,			%% 签到礼品ID或活跃度礼品ID
						 state				= 0				%% 是否领取
						}).

%% 多人副本
-record(mcopy_data,     {
						 date				= 0,			%% 刷新日期
						 times				= 0,			%% 进入次数
                         list               = []            %% 开启列表
                        }). 

-record(mcopy_info,		{
						 user_id			= 0,		    %% 玩家id
						 info				= []            %% 信息[{MapId, Times}..]
                        }).

%% 修为
-record(cultivation,    {
                         point              = 0,            %% 修为点
                         gold               = 0,            %% 铜钱
                         goods_id           = 0,            %% 道具id
                         phase              = 0,            %% 段
                         count              = 0,            %% 连击次数
                         attr_list          = [],           %% 属性加成列表
					     attr_value_list	= [],			%% 属性额外加成值列表
                         rate               = 0,            %% 成功率
                         factor             = 0,            %% 连续技系数
                         rate_anger         = 0,            %% 怒气系数
						 skill_ext			= ?null			%% 技能扩展
                        }).

%% 福利系统
-record(welfare,			{
							 user_id					= 0,		% 玩家ID
							 first_login				= 0,		% 首次登陆时间
							 login						= 0,		% 本次登录时间（秒）
							 online						= 0,		% 累计在线时间
							 fill_sign_times			= 0,		% 连续登陆补签次数
							 data						= [],		% 礼包信息（存放welfare_data）
							 pullulation				= [],		% 成长礼包(不需要了，暂不删除)
						     pullulation_power			= [],       % 威武之路
                             deposit                    = []        % 充值礼包	
							}).

%% 单个礼包信息
-record(welfare_data,		{
							 type						= 0,		% 福利类型
							 first						= 0,		% 首要条件
							 second						= 0,		% 次要条件
							 id							= 0,		% 礼包ID
							 state						= 0			% 礼包状态：0、未生效；1、未领取；2、已领取；3、已失效。
							}).

%% 成长礼包定义pullulation
-record(pullulation,		{
							 id							= 0,		%% 成就ID
							 flag						= ?false,	%% 是否完成
							 times						= 0,		%% 完成次数
							 time						= 0,		%% 完成时间
							 received					= 0			%% 是否完成
							}).

%% 威武之路定义pullulation_power
-record(pullulation_power,	{
							 id							= 0,		%% 成就ID
							 flag						= ?false,	%% 是否完成
							 time						= 0,		%% 完成时间
							 received					= 0			%% 是否完成
							}).

%% 新服活动
-record(new_serv,			{
							 date						= 0,		%% 用于刷新
							 achieve					= [],		%% 达成成就
							 storage					= [], 		%% 生财宝箱
							 first_return				= 0,		%% 存钱当日返回
							 award						= 0,		%% 存入金额转换后剩余可领
							 draw_flag					= ?false,   %% 每日领取标志
                             turn                       = ?null,    %% 转盘
							 continue					= 0,		%% 活动期间在线时间
							 consume					= 0,		%% 活动期间累计消费
							 ext_data				    = ?null 	%% 扩展数据
							}).

%% 新服达成成就定义
-record(achieve,			{
							 id							= 0,		%% 成就ID
							 flag						= ?false,	%% 是否完成
							 times						= 0,		%% 完成次数
							 time						= 0,		%% 完成时间
							 received					= 0			%% 是否领取
							}).

%% 新服存钱
-record(storage,			{
							 diff_day					= 0,		%% 开服第几天
							 value						= 0 		%% 存储金额			
							}).

%% 新服转盘
-record(turn,               {
                             got_partner        = 0,    %% 获得武将
                             times              = 0,    %% 可抽奖次数
                             count              = 0,    %% 已抽奖次数
							 group				= 0
                            }).
%% 兑换信息列表
-record(exchange_info,       {
							 list				= []    %% 兑换信息列表
							}).

%% 多人竞技场
-record(arena_pvp_m,		{
							 user_id			= 0,	%% 玩家id
							 user_name			= 0,	%% 玩家名称
							 pro				= 0,	%% 职业
							 sex				= 0,	%% 性别
							 lv					= 0,	%% 等级
							 position			= 0,    %% 官衔
							 
							 hufu				= 0,	%% 虎符数量
							 score_week			= 0,	%% 周积分	
							 time				= 0,	%% 参加时间
							 
							 auto_ready			= 0,	%% 自动准备
							 auto_start			= 0,	%% 自动开始	
							 		 
							 score_today		= 0,	%% 今日积分
							 score_current		= 0,	%% 当场积分
							 hufu_today			= 0,	%% 今日虎符
							 hufu_current		= 0,	%% 当场虎符
							 
							 count				= 0,	%% 当场参加次数
							 win				= 0,	%% 当前连胜次数
							 win_max			= 0,	%% 最高连胜纪录
							 win_sum			= 0,	%% 胜利次数
							 rank				= 0,		%%  排行
                             gold_today         = 0
							}).

-record(arena_pvp_t,		{
							 team_id			= 0,	%% 队伍id
							 leader_id			= 0,	%% 队长id
							 lv					= 0		%% 平均等级	 
							}).

-record(arena_pvp_active,	{
							 id					= 0,
							 end_time			= 0
							}).

-record(arena_pvp_rank,		{
							 rank				= 0,
							 user_id			= 0,
							 user_name			= <<"">>,
							 score				= 0	
							}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 时装
-record(style_data,         {
                             hide_flags         = [],     % 隐藏标志
                             cur_non_skin       = [],     % 当前非变化外形列表     
                             cur_skin           = [],     % 当前变化外形列表 
                             bag                = []      % 已激活变化外形列表
                            }).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 地图信息
-record(map_info,       {
                         map_id             = 0,            % 地图Id
                         x                  = 0,            % X坐标
                         y                  = 0             % Y坐标
                        }).

%% 地图信息
-record(map_data,       {
                         opened             = [],           % 已开放地图id列表
                         cur                = #map_info{},  % 当前地图信息
                         last               = #map_info{}   % 对上一次的地图信息 
                        }).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 
-record(resource_info, {
						date				= 0,            % 日期
						list				= []            % 资源找回列表[{type, num, flag}]
						}).	

-record(resource_lookfor,{
						  user_id			= 0,            % 角色id
						  yesterday			= {},           % 昨日资源
						  today				= {}           	% 今日资源
						  }).
