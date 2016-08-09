%% 角色升级数据
-record(player_level,   {
                         pro                = 0,            % 职业
                         lv                 = 0,            % 等级
						 exp_next			= 0, 			% 升到下一级所需经验
						 skill_point		= 0,			% 升级奖励技能点
                         sp_max             = 0,            % 体力上限
						 skiper_max		 	= 0, 			% 主将数量  
						 assister_max		= 0, 			% 副将数量  
						 partner_max		= 0, 			% 武将携带数量
                         attr               = null         	% 升级属性      
                        }).
%% 角色
-record(player_position, {
						  id                = 0, 			% ID
						  next_id           = 0, 			% 后续官衔ID
						  meritorious       = 0, 			% 所需阅历
						  salary            = 0, 			% 获得俸禄
						  attr              = 0,			% 属性加成
						  task_id			= 0				%  任务ID
						 }).

%% 称号
-record(player_title,	{
						 title_id			= 0,			% ID
						 unique				= 0,			% 唯一性			
						 attr_value			= [],			% 属性加成值
						 attr_per			= [],			% 属性加成百分比
						 is_when			= 0,			% 是否有条件
						 condition			= 0,			%  条件
						 effect_time		= 0				% 时效
						 }).

%% 好友-关系
-record(relation_data,  {
                         user_id			= 0,	% 玩家id
						 friend_list		= [], 	% 好友列表			#relation
						 best_list			= [],	% 密友列表			#relation
						 black_list			= [],	% 黑名单列表			#relation
						 contact_list		= []	% 最近联系人列表    	#relation          
                         }).

-record(relation_be,	{
						 user_id			= 0,
						 be_friend			= [],
						 be_best			= [],
						 be_black			= [],
						 be_contact			= []
						 }).

-record(relation,   {
                         mem_id             = 0,    % 对方
                         time               = 0     % 建立时间                         
                         }).

-record(cross_node_config, {
                            server_index = 0,
                            node_name = null,
                            update_time = 0
                            }).

-record(arena_pvp_cross_match,
        {
         leader_id = 0,
         level = 0,
         streak_win = 0,
         start_time = 0,
         battle_data = null,
         node_from
         }
        ).


-record(ets_gun_award_everyday, {
                             user_id, 
                             active_list = [],
                             update_time = 0
                             }).

-record(ets_gun_cash_local, 
    {
     user_id = 0,
     account = 0,
     state = 0,
     today_cash = 0,
     last_up_time = 0,
     total_cash = 0
    }).

-record(ets_gun_cash_global, 
    {
     account = 0,
     listen_list = []
    }).

%% 祝福
-record(bless_user,    	{
                         user_id            = 0,            %% 玩家id
                         count              = 0,            %% 总祝福次数
                         exp                = 0,            %% 祝福经验瓶累积经验
						 time				= 0, 			%% 祝福时间
						 flag				= 0				%% 是否领取	
                        }).

-record(bless_info,    	{
                         user_id            = 0,            %% 玩家id
                         count				= 0,
                         send_list			= [],
						 recv_list			= []
                        }).

-record(bless,    		{
						 key				= 0,
						 type				= 0,
						 value				= 0,
						 time				= 0
						}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 修炼
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(practice_user,  {
				  		user_id 			= 0,	% 玩家id	
						mem_id				= 0,	% 双修队友id
						auto				= 1,	% 是否自动	
						sum_time			= 0,	% 修炼时间总和
						start_time			= 0		%  开始时间
				 	 	}).
-record(practice,		{
						 user_id			= 0,	% 玩家id	
						 state				= 0,	% 单修/双修
						 exp_time			= 0		% 上次获得经验时间
						 }).
-record(practice_doll,	{
						 user_id			= 0,	% 玩家id
						 type				= 0,	% 时间类型
						 logout_time		= 0,	% 下线时间
						 date_uts			= [],	% 有效修炼时长[{date, time}]
						 valid_times		= [0,0],	% 有效时长[set_day_ut,set_next_day_ut]
						 total_time			= 0,	% 设置时长
						 rest_time			= 0,	% 剩余时间
						 set_time			= 0,	% 设置时间
						 set_date			= {1970,1,1},	% 设置日期
						 set_next_date		= {1970,1,2},	% 设置下一天日期
						 is_set 			= 0,	% 是否有设置0无1有
						 practice_state		= 3,	% 修炼状态
						 map_id				= 0		% 地图id
						 }).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 心法系统
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(mind_data,		{
						 last_clear_date	= 0,	%上次更新当日心法的日期(20120101)
						 today_total_times	= 0,	%当日祈天总次数(备用)
						 today_third_times	= 0,	%当日元宝星辰祈天次数
						 today_fourth_times	= 0,	%当日元宝元辰祈天次数
						 minds				= ?null,%玩家获得的心法#mind_info{}
						 mind_uses			= [],	%已经装备的心法#mind_use{}列表
						 guide_finish		= ?false%引导是否完成
						 }).
%% 玩家心法信息
-record(mind_info,		{
                         score              = 0,    %积分
						spirit				= 0,	%灵力（用来消耗升级的部分）
						mind_bag			= [],	%心法背包#ceil_state{}列表
						mind_bag_temp		= [],	%心法临时背包#ceil_temp{}列表
						mind_learn			= [],	%心法秘籍参阅状况#secret_state{}列表
						daily_free_times	= 0		%每天免费开启心法次数
						 }).
%%角色心法装备
-record(mind_use,		{
						user_id				= 0,	%玩家ID
						type				= 0,	%类型,1为玩家2为伙伴
						index				= 0,	%索引
						user_spirit			= 0,	%心力（人物面板，玩家装备心法的灵力和）
						mind_use_info		= []	%#ceil_state{}已经装备的心法列表   -->更改为ceil_state 有利于背包和装备区的心法交换
				  		}).
%%背包中心法信息
-record(ceil_state,		{
						 pos				= 0,	%背包中心法的位置    索引
						 state				= 0, 	%开启状态：0关闭 1开启
						 mind_id			= 0,	%心法ID
						 lv					= 0,	%心法等级
						 lock				= 0		%是否锁定（锁定状态不能转化）						 
						}).
%%心法学习
-record(secret_state, 	{
						 state				= 0,	%开启状态：0关闭 1开启
						 pos				= 0		%位置	 索引
						}).
%%临时背包中心法信息
-record(ceil_temp,		{
						 mind_id			= 0,	%心法ID
						 pos				= 0		%位置  索引
						}).

%%淘宝数据
-record(lottery_data,	{
						 id			= 0,		% 道具系列ID
						 data		= ?null,	% 道具概率
						 sum		= 0			% 概率之和
						}).

%% 淘宝公告栏
-record(bulletin,		{
						 user_id			= 0,	% 关键字
						 data				= ?null	% [{极品/收获, 玩家ID, 玩家昵称, 道具ID}]
						}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 灵兽
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(pet_data,			{
							 max 			= 0,		%%宠物栏最大值
							 canhave 		= 0,		%%目前可拥有宠物数量
							 haved 			= 0,		%%实际拥有宠物数量
							 opened			= 0,		%%已开启宠物栏
							 pets			= {}		%%宠物列表#pet_info{}  	 
							}).

-record(pet_info,			{
							 id,                                %% 宠物栏索引（位置）      
							 player_id			= 0,            %% 角色ID 
							 goods_id 			= 0,            %% 宠物类型id     
							 pet_resource_id 	= 0,            %% 宠物资源id     
							 is_home	 		= 0,            %% 召唤状态 0宠物栏 1家园
							 petstatus 			= 0,            %% 宠物状态值1.休战 2.出战  3.采集        
							 name 				= [],           %% 宠物名称       
							 rename_count 		= 100,          %% 重命名次数     
							 level 				= 0,            %% 宠物级别              
							 aptitude 			= 0,            %% 资质值 
							 quality 			= 0,            %% 质品值 0灰色1绿色2蓝色3紫色4橙色       
							 grow 				= 0,            %% 成长值 
							 hatch_start 		= 0,            %% 出生时间 
							 hp_current 		= 0,            %% 宠物当前生命值 
							 hp_toplimit 		= 0,            %% 宠物生命值上限 
							 exp 				= 0,            %% 宠物当前经验值 
							 exp_upgrade 		= 0,            %% 宠物升级所需经验值     
							 character 			= 0,            %% 宠物性格
							 active_skill_id 	= 0,            %% 宠物主动技能ID 
							 active_skill_lv	= 0,			%% 宠物主动技能等级
							 character_skills 	= [],        	%% 宠物性格技能  格式为 [{技能栏位置技能id,技能lv}....],  
							 passive_skills 	= [],        	%% 宠物已经学习的被动技能格式为\r\n[{技能栏位置技能id,技能lv}....],       
							 skill_column_num 	= 0,            %% 宠物被动技能栏        
							 temp_character 	= 0,            %% 用于更改宠物性格时 缓存宠物的性格      
							 temp_character_skills = [],        %% 用于更改宠物性格时 缓存宠物性格技能    
							 temp_collect_count = 0,            %% 昨天的采集次数 
							 reset_aptitude		= 0,            %% 初始资质       
							 reset_grow			= 0,            %% 初始成长       
							 reset_character	= 0,            %% 初始性格       
							 reset_character_skills = [],    	%% 初始性格技能   
							 reset_active_skill_id = 0,         %% 初始主动技能ID 
							 reset_passive_skills = [],       	%% 初始被动技能
							 %%宠物基础战斗属性
							 hp_max				= 0,			%% 气血（二级）
							 force_attack 		= 0,            %% 物攻(二级)
							 force_def 			= 0,            %% 物防(二级)   
							 magic_attack 		= 0,            %% 法攻(二级)   
							 magic_def 			= 0,            %% 法防(二级)   
							 speed 				= 0,            %% 速度（二级）      
							 %%宠物家园数据
							 amused_times 		= 0,            %% 被逗次数(家园)       
							 amuse_times_limit 	= 0,            %% 被逗次数上限(家园)   
							 amuse_exp 			= 0,            %% 被逗经验值(家园)     
							 amused_player_list = [],        	%% 被逗玩家列表(家园)     
							 current_map		= 0,			%% 当前地图(家园)
							 hunt_times			= 0,			%% 寻宝次数(家园)
							 refresh_times		= 0 			%% 刷新次数
							 
							}).

%%技能宠物属性加成
-record(pet_attribute,{                                                                                                                                                                                                                      
					   hp = 0,  
					   attack = 0,  
					   defense = 0,  
					   magic_attack = 0,  
					   magic_defense = 0,  
					   stunt_attack = 0,  
					   stunt_defense = 0,
					   duck = 0,
					   hit = 0,
					   crit = 0,
					   parry = 0,
					   counterattack = 0 
					  }). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 坐骑
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 马厩结构
-record(horse_data,     {
                         pony_stable        = [],       % 小马厩
                         skill              = [],       % 技能
                         train              = ?null     % 培养信息                         
                        }).

%% 小马厩
-record(pony,           {
                         idx                = 0,        % 索引
                         egg_id             = 0,        % 物品id
                         ok_time            = 0         % 成熟时间点 
                        }).

%% 坐骑培养
-record(horse_train,    {
                         lv                 = 0,        % 等级
                         exp                = 0,        % 经验
                         time               = 0,        % 强化时间
                         times              = 0         % 当天培养次数 
                        }).

%% 坐骑技能库
-record(horse_skill,    {
                            type            = 0,        % 类型
                            skill_id        = 0         % 技能id
                        }).


%% 商城
-record(mall_sale,{
					   key					= 0,			%% {id,goods_id}
					   num					= 0,			%% 数量
					   end_time				= 0				%%  结束时间
					   }).

-record(mall_discount,{
					   key					= 0,			%% {user_id,goods_id}
					   num					= 0				%% 数量
					   }).

%% 温泉
-record(spring_info,	{
						 user_id			= 0,			% 玩家ID
						 state				= 0,			% 玩家状态：单修还是双修
						 exp				= 0,			% 经验
						 sp					= 0,			% 体力
						 mem_id				= 0,			% 双修玩家ID
						 enter_time			= 0,			% 进入时间
						 sp_time			= 0,			% 体力累计时间
						 time				= 0,			% 温泉累计时间
						 auto				= 1,			% 是否自动双修
						 count				= 0				%   被互动次数
						 }).

-record(spring_active,	{
						 id					= 0,
						 state				= 0,
						 flag				= 0,
						 sp_time			= 0,
						 exp_time			= 0,
						 start_time			= 0,			
						 end_time			= 0
						 }).

-record(spring_doll,	{
						 user_id			= 0,
						 time				= 0,
						 spring_ids			= [],
						 map_pid			= 0,
						 bcash				= 0,
						 cash				= 0
						 }).


%% 排行榜
-record(rank,			{
						 id					= 0,
						 flag				= 0,
						 data				= [],
						 list				= [],
						 time				= 0
						 }).


-record(chest,				{
							 list,						% 招财宝箱概率
							 sum						% 招财宝箱概率总和
							}).

%%炼炉信息
-record(furnace_data,		{
							 queues_flag		= 0,		% 强化队列标示(0:启用|1:关闭)
							 queues           	= []	    % 强化队列[#furnace_cd{}]
							}).

%%炼炉强化CD
-record(furnace_cd,			{
							 id	       = 0,		        %玩家强化队列号
							 deadline  = 0      		%当前队列上次强化时间
							}).

%% 竞技场信息		
-record(ets_arena_member, {	
      player_id = 0,                          %% 玩家ID	
      player_name = "",                       %% 玩家名字	
      player_sex = 0,                         %% 玩家性别	
      player_lv = 0,                          %% 玩家等级			需要从人物属性刷新	
      player_career = 0,                      %% 职业	
      rank = 0,                               %% 排名	
      times = 0,                              %% 今日剩余挑战次数	
      winning_streak = 0,                     %% 胜连次数	
      cd = 0,                                 %% 冷却时间	
      fight_force = 0,                        %% 战力				需要从人物属性刷新
      open_flag = 0,                          %% 是否打开竞技场界面	
      daily_buy_time = 0,                     %% 每天购买次数	
      clean_times_time = 0,                   %% 清空剩余次数和每天购买次数的时间	
      on_line_flag = 0,                       %% 在线标志	
      sn = 0,                                 %% 服务器编号	
      streak_wining_reward = [],              %% 已经领过的连胜奖励	
      daily_max_win = 0,                      %% 今日最大连胜次数	
      max_win = 0,							  %% 历史最大连胜
	  meritorious = 0,     					  %% 未领取功勋
      score = 0,                              %% 积分
      daily_target = 0,                       %% 每日目标
      target_state = 0                        %% 每日目标状态
	}).	
	
%% 竞技场战报	 	
-record(ets_arena_report, {	
      id,                                     %% 战报ID(唯一 UserId_Time)	
      type = 0,                               %% 1挑战 2被挑战	
      result = 0,                             %% 1胜利2失败	
      time = 0,                               %% 战报存放时间	
      player_id = 0,                          %% 玩家ID	
      deffender_id = 0,                       %% 防御方ID	
      deffender_name = "",                    %% 防御方名字	
      rank_change_type = 0,                   %% 1上升 2下降 3不变	
      rank = 0,                               %% 排名	
      bin_report = <<>>		                  %% 战报	
    }).	
	
%% 竞技场奖励（排名）		
-record(ets_arena_reward, {	
      player_id = 0,                          %% 玩家ID	
      get_date = 0,                           %% 领取奖励时间	
	  meritorious = 0,						  %% 功勋
	  experience = 0,						  %% 培养值
	  rank = 0,                               %% 排名	
	  goods,                                  %% 物品列表[{GoodsId, Bind, Count}]
	  on_line_flag = 0,                       %% 在线标志	
      sn = 0,                                 %% 服务器编号	
      settlement_date = 0,                    %% 计算时间
      score = 0                               %% 积分	
    }).	

%% %% 竞技场排名
%% -record(ets_arena_rank,	  {
%% 	  rank,
%% 	  player_id	= 0
%% }).

%% 商路场景在线
-record(commerce_online,	{
							 user_id					= 0,		% 玩家ID
							 lv							= 0
  							}).

%% 商路市场
-record(commerce_market,	{
							 id							= 0,		% 市场ID
							 user_id					= 0,		% 玩家ID
							 user_name					= <<"">>,	% 玩家昵称
							 start_time					= 0,		% 开始时间
							 end_time					= 0			% 结束时间
							}).

%% 商路信息
-record(caravan,			{
							 id							= 0,		% 商队ID
							 quality					= 0,		% 商队品质
							 name						= <<"">>,	% 商队名称
							 user_id					= 0,		% 玩家ID
							 user_name					= <<"">>,	% 玩家昵称
							 pro						= 0,		% 玩家职业
							 sex						= 0,		% 玩家性别
							 lv							= 0,		% 玩家等级
							 guild_id					= 0,		% 帮派ID
							 guild_name					= <<"">>,	% 玩家帮派名称
							 friend_id					= 0,		% 好友ID
							 friend_name				= <<"">>,	% 好友昵称
							 start_time					= 0,		% 开始时间
							 end_time					= 0,		% 结束时间
							 battling					= 0,		% 战斗状态
							 failure					= 0,		% 拦截失败次数
							 robber						= [],		% 拦截记录
							 market						= 0,		% 建造市场buff加成
							 guild						= 0,		% 帮派加成
							 factor						= 0		    % 品质系数
							}).

%% 商路玩家信息
-record(commerce,			{
							 user_id					= 0,		% 玩家ID
							 date						= 0,		% 日期
							 carry						= 0,		% 运送次数
							 escort						= 0,		% 护送好友次数
							 rob						= 0,		% 抢劫次数
							 vip_rob					= 0,		% VIP抢劫次数
							 freerefresh				= 0,		% 免费刷新品质次数
							 refresh					= 0,		% 刷新品质次数（每次运送重置为0）
							 quality					= 0,		% 商队品质
							 carry_time					= 0,		% 运送冷却时间
							 escort_time				= 0,		% 护送冷却时间
							 rob_time					= 0,		% 拦截冷却时间
							 flag_invite			    = 0			% 忽略所有邀请标记
							}).

-record(commerce_friend,	{
							 user_id					= 0,		% 邀请者ID
							 user_name					= <<"">>,	% 玩家昵称
							 friend_id					= 0,		% 好友ID
							 friend_name				= <<"">>,	% 好友昵称
							 state						= 0,		% 状态：0-邀请中, 1-同意, 2-拒绝
							 invite_time				= 0,		% 邀请过期时间
							 escort_time				= 0			% 护送过期时间
							}).

-record(commerce_rob_info,  {
							  id						= 0,        % Id
							  rob_list				    = []		% 拦截成功战报[{Id1,Name1,Id2,Name2,Type,Value1,Value2}]
							 }).

-record(commerce_offline,	{
							 type						= 0,		% 类型：1：运送；2：护送；3：拦截。
							 user_name					= 0,		% 抢劫次数
							 escort_time				= 0,		% 护送结束时间
							 experience					= 0,		% 历练加成
							 gold						= 0			% 铜钱奖励
							}).

-record(achievement_offline,	{
								 category				= 0,		% 类别：1、离线成就；2、离线称号。
								 type					= 0,		% 类型，在后台配置
								 matchdata				= 0,		% 匹配的数据，后台配置
								 times					= 0			% 本次调用接口时的完成次数
								}).

-record(welfare_offline,	{
							 vip						= 0,		% 玩家VIP等级
							 cur_sum					= 0,		% 本次充值金额
							 acc_sum					= 0			% 累计充值金额
							}).

-record(pullulation_offLine,	{
								 type					= 0,		% 类型，在后台配置
								 matchdata				= 0,		% 匹配的数据，后台配置
								 times					= 0			% 本次调用接口时的完成次数
								}).

-record(achieve_offline,	{
								 type					= 0,		% 类型，在后台配置
								 matchdata				= 0,		% 匹配的数据，后台配置
								 times					= 0			% 本次调用接口时的完成次数
								}).
%% 扫荡信息
-record(raid_player,        {
                             user_id                    = 0,        % 玩家id
                             copy_id                    = 0,        % 副本id
                             map_id                     = 0,        % 当前副本的地图id
                             mons_tuple                 = ?null,    % 怪物组
                             mons_group                 = ?null,    % 当前波的怪物群
                             next_skip                  = 0,        % 下一跳时间点,下波怪或者下一轮的时间点
                             total_round                = 0,        % 总轮数 -- 不变
                             round                      = 0,        % 轮
                             wave                       = 0,        % 当前第几波怪
                             wave_size                  = 0,        % 每轮n波怪
                             end_time                   = 0,        % 结束时间
                             sp_used                    = 0,        % 使用了的总体力
                             cash_used                  = 0,        % 使用了的绑定元宝
                             is_even_wave               = 0,        % 偶数波? ?true/?false
                             wave_reward                = [],       % 每波奖励 {{exp, meritorious, bgold, goods_drop_id}...}
                             round_reward               = {0,0,0,0},% 每轮奖励 {exp, meritorious, bgold, goods_drop_id}
                             is_online                  = 0         % 0离线，1在线
                            }).

-record(raid_elite,         {
                             copy_id                    = 0,        % 副本id
                             map_id                     = 0,        % 当前副本的地图id
                             mons_list                  = ?null,    % 当前波的怪物群
                             reward_monster             = ?null,    % 怪物奖励 
                             reward_pass                = ?null     % 通关奖励
                            }).

-record(raid_elite_player,  {
                             user_id                    = 0,
                             serial_id                  = 0,        % 系列id
                             copy_list                  = [],       % 副本列表#raid_elite{}
                             total_copy_list            = [],       % 副本id列表
                             total_round                = 0,        % 总轮数
                             round                      = 0,        % 现在第几轮
                             next_skip                  = 0,        % 下一跳时间点,下波怪或者下一轮的时间点
                             end_time                   = 0,
                             cash_used                  = 0,
                             is_even_wave               = 0,        % 偶数波? ?true/?false
                             is_online                  = 0         % 0离线，1在线
                            }).

%% 怪物组
-record(mons,               {
                             mons_group                 = {[], [], []} 
                             
                            }).

%% 采集系统
-record(collect,           {
							user_id						= 0,		% 玩家ID
							lv							= 0,		% 采集等级
							type						= 0,		% 类型
							sp							= 0,		% 消耗体力
							time						= 0,        % 采集时间
							normal_goods			    = 0,		% 普通物品掉落id
							adv_rate					= 0,		% 奇遇几率
							adv_goods					= 0,		% 奇遇物品掉落id
							state						= 0,		% 采集状态（0停止1采集中）
							times						= 0,		% 采集次数
							reward_time					= 0         % 获得采集物品时间
						   }).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 世界BOSS
-record(boss_data,			{
							 room						= 0,		% boss所属房间
							 key						= 0,		% Key
							 id							= 0,		% ID
							 lv							= 0,		% 等级Lv
							 map_id						= 0,		% 地图ID
							 monsters					= 0,		% 怪物列表
							 reward_kill				= 0,        % 击杀奖励
							 reward_valiant				= 0,        % 英勇奖励
							 reward_damage_gold			= 0,        % 伤害奖励(金币)
							 reward_damage_meritorious	= 0,        % 伤害奖励(功勋)
							 reward_damage_experience	= 0,        % 伤害奖励(历练)
							 reward_rank_gold			= 0,        % 排名奖励(金币)
							 reward_rank_meritorious	= 0,        % 排名奖励(功勋)
							 reward_rank_experience		= 0,        % 排名奖励(历练)
							 kill_user					= 0,        % 最后一击的UserId
							 
							 state						= 0,		% 状态
							 end_type					= 0,		% 世界BOSS结束类型(1:时间到|2:BOSS死亡)
							 time_start					= 0,		% 开始时间戳
							 time_end					= 0,		% 结束时间戳
							 boss_hp					= 0, 		% 世界BOSS总血量
							 node						= ""		% 所在节点
							}).

%% 世界BOSS怪物信息
-record(boss_monster,		{
							 monster_id					= 0,		% 怪物ID
							 hp							= 0,		% 怪物当前总生命
							 hp_max 					= 0,		% 怪物总生命上限
							 broadcast_tag				= [],		% 公告标记(0、正常1、70%以下、2、50%以下3、30%以下4、10%以下)
							 hp_tuple					= 0,		% 怪物组血量
							 first						= 0			% 第一个动手的UserId
							}).

%% 世界BOSS玩家信息
-record(boss_player,		{
							 boss_id					= 0,		% BOSSID
							 user_id					= 0,		% 玩家id
							 user_name 					= <<"">>,	% 玩家名称
							 pro						= 0,		% 职业
							 sex						= 0,		% 性别
							 lv							= 0,		% 玩家等级
							 vip						= 0,		% VIP等级
							 encourage					= 0,		% 鼓舞
							 reborn						= 0,		% 浴火重生(0:否|1:是)
							 reborn_times				= 0,		% 浴火重生次数
							 hurt						= 0,		% 伤害
							 hurt_tmp					= 0,		% 伤害(临时)单场战斗累计伤害
							 auto						= 0,		% 自动战斗(0:否|1:是)
							 cd_death					= 0,		% 死亡复活CD
							 cd_exit					= 0, 		% 退出CD
							 exist						= 0,		% 存在(0:是|1:否)
							 achievement				= 0,		% 成就(0:是|1:否)
                             hurt_reward                = {0, 0, 0},% 总伤害奖励
							 room_id					= 0,		% 房间
							 serv_id					= 0,        % 服务器id
							 map_id						= 0, 		% 所在地图id
							 node						= "",	    % 所在节点
							 master_node				= "",       % 主节点
							 robot						= ?false    % 机器人标志(true:机器人false:非机器人)
							}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 乱天下
-record(world_base,			{
							 map_id						= 0,		% 地图ID
							 x							= 0,		% X
							 y							= 0,		% Y
							 time_start					= 0,		% 开始时间戳
							 time_end					= 0			%   结束时间戳
							}).
-record(world_data,			{
							 guild_id					= 0,		% 军团ID
							 guild_name					= 0,		% 军团名称
							 pid						= 0,		% 军团对应的乱天下进程Pid
							 map_pid					= 0,		% 军团对应的乱天下地图进程Pid
							 step						= 0,		% 当前进度(当前波数)
							 step_max					= 0,		% 怪物总波数
							 monster_activate			= ?false,	% 怪物激活标示(true:已激活|false:未激活)
							 monsters					= ?null,	% 乱天下怪物组信息#world_monsters{}
							 buff						= [],		% 犒赏三军属性加成列表[#world_buff{}]
							 invite_quota				= [],		% 邀请名额列表[{Pos, Quota, []}]
							 invite						= []		% 邀请列表[UserId, UserId, UserId...]
							}).
%% 乱天下怪物组信息
-record(world_monsters,		{
							 reward_exp					= 0,		% 奖励经验
							 reward_goods				= [],		% 奖励物品
							 monsters					= ?null		% 怪物列表
							}).
%% 乱天下怪物信息
-record(world_monster,		{
							 id							= 0,		% 怪物唯一ID(怪物生成ID)
							 monster_id					= 0,		% 怪物ID
							 reward_gold				= 0,		% 击杀奖(铜钱)
							 reward_exp					= 0,		% 奖励经验
							 reward_goods				= [],		% 奖励物品
							 hp							= 0,		% 怪物当前总生命
							 hp_max 					= 0,		% 怪物总生命上限
							 hp_tuple					= 0,		% 怪物组血量
							 death						= ?false	% 怪物是否死亡标示
							}).
%% 乱天下玩家信息
-record(world_player,		{
							 user_id					= 0,		% 玩家id
							 belong						= 0,		% 归属军团
							 guild_id					= 0,		% 玩家所属军团
							 user_name 					= <<"">>,	% 玩家名称
							 lv							= 0,		% 玩家等级
							 vip						= 0,		% VIP等级
%% 							 buff						= {0, []},	% 犒赏三军属性加成{BuffId, [{CalcType, AttrType, AttrValue}]}
							 hurt						= 0,		% 伤害
							 kill						= 0,		% 累积杀怪数量
							 reward_kill				= 0,		% 累积伤害奖励
							 auto						= 0,		% 自动战斗(0:否|1:是)
							 cd_death					= 0,		% 死亡复活CD
							 cd_exit					= 0, 		% 退出CD
							 exist						= 0 		% 存在(0:是|1:否)
							}).
%% 乱天下BUFF
-record(world_buff,			{
							 id							= 0,		% BUFFID
							 founder_uid				= 0,		% 创始人Uid
							 founder_name				= 0,		% 创始人名字
							 buff						= 0,		% BUFF列表
							 value						= 0			% 加成值
							}).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 采集任务结构
-record(gather,             {
                             id                         = 0,        % 采集id
                             x                          = 0,        % x
                             y                          = 0,        % y
                             goods_id                   = 0         % 物品id 
                            }).

%% 报名
-record(sign_user_faction,   {
                             user_id                    = 0,        % 玩家id
                             power                      = 0,        % 战力
                             faction                    = 0,        % 阵营
                             person_honor               = 0         % 个人荣誉    
                            }).

%% 阵营
-record(faction,            {
                             id                         = 0,        % 阵营id
                             count                      = 0,        % 人数 
                             member                     = [],       % 阵营成员列表
                             power                      = 0,        % 总战力
                             power_max                  = 0         % 最大战力#sign_user_faction
                            }).

%% 阵营
-record(factions,            {
                             faction_atk                  = 0,      % 攻方#faction{}
                             faction_def                  = 0       % #faction{} 
                             }).

-record(faction_boss,        {
                              monster_id                  = 0,
                              units                       = 0      
                             }).

-record(invasion_info,			{
								 team_id				= 0,		%% 队伍ID(ets的key)
								 team_type				= 0,		%% 
								 map_pid				= 0,		%% MapPid
								 map_id					= 0,		%% MapId
								 prior					= 0,		%% 最初副本ID
								 copy					= 0,		%% 当前副本ID
								 mode					= 0,		%% 攻关/守关
								 wave					= 0,		%% 最大进度
								 progress				= 0,		%% 当前进度
								 begin_time				= 0,		%% 副本开始时间
								 end_time				= 0,		%% 副本结束时间
								 activity				= ?false,	%% 活动结束标志：true：活动结束；false：活动未结束。
								 hurt_left				= 0,		%% 玩家伤害
								 hurt_right				= 0,		%% 怪物伤害
								 reborn					= ?null,	%% 复活（守关）
								 hurt					= ?null,	%% 玩家伤害排名
								 npc					= ?null,	%% NPC信息
								 start					= 0,		%% 控制出怪时间
								 mons					= ?null,	%% 怪物信息[#invasion_mon{}]
								 state					= 0,		%% 0：进行中；1、阶段；2、失败；3、成功；
								 team_robot				= [],		%% 队伍机器人列表
								 robot					= []		%% {robot_id, is_battle, timestamp} {机器人id,战斗状态,复活时间戳}
								}).

-record(invasion_npc,			{
								 id						= 0,		%% 唯一ID
								 npc_id					= 0,		%% 怪物表ID
								 max_hp					= 0,		%% 最大血量
								 cur_hp					= 0,		%% 当前血量
								 delta_hp				= 0,		%% 碰撞减少血量
								 x						= 0,		%% 位置X
								 y						= 0			%% 位置Y
								}).

-record(invasion_mon,			{
								 id						= 0,		%% 唯一ID
								 mon_id					= 0,		%% 怪物表ID
								 max_hp					= 0,		%% 最大血量
								 cur_hp					= 0,		%% 当前血量
								 target_x				= 0,		%% 怪物目标X：在转折点前为转折点，在转折点后为NPC
								 target_y				= 0,		%% 怪物目标Y：在转折点前为转折点，在转折点后为NPC
								 turn_x					= 0,		%% 转折点X
								 turn_y					= 0,		%% 转折点Y
								 cur_x					= 0,		%% 当前位置X
								 cur_y					= 0,		%% 当前位置Y
								 next_x					= 0,		%% 内部位置点X(后端计算 每次心跳/秒)
								 next_y					= 0,		%% 内部位置点Y(后端计算 每次心跳/秒)
								 part_x					= 0,		%% 下一位置X(通知前端 每一次行走)
								 part_y					= 0,		%% 下一位置Y(通知前端 每一次行走)
								 speed					= 0,		%% 怪物移动速度
								 duration				= 0,		%% 停留时间（倒计时）
								 space					= ?null,	%% 对应invasion表中的walk字段
								 time					= ?null,	%% 对应invasion表中的halt字段
								 user_id				= 0,		%% 玩家ID(守关)
								 battling				= 0,		%% 是否战斗
								 units_hp				= ?null		%% 怪物组血量(经过压缩处理)
								}).

-record(invasion_offline,		{
								 type					= 0,
								 prior					= 0,
								 copy					= 0,
								 result					= 0
								}).

%% 多人副本数据
-record(mcopy_serial,   {
                         id                 = 0,            % 副本系列id
                         daily_count        = 0,            % 每天可进入次数
                         lv_min             = 0,            % 最低等级限制
						 module				= 0,			% 模块ID
                         mcopy_list         = [],           % 副本列表#rec_mcopy{}
                         need_sp            = 0,            % 消耗体力
                         goods              = 0,            % 副本奖励道具
                         exp                = 0,            % 副本经验
                         gold_bind          = 0,            % 副本绑定铜钱
                         meritorious        = 0,            % 副本功勋,
						 standard_time		= 0				%  副本标准通关时间
                        }).

-record(mcopy_map_data, {
                         wave               = 0,            % 当前第几波
						 condition			= 0,            % 奇遇/跳转点/结束
                         mon_list           = [],           % 怪物列表
                         goods_drop_id      = 0,            % 道具掉落id
                         exp                = 0,            % 经验
                         gold_bind          = 0,            % 绑定铜钱
                         meritorious        = 0,            % 功勋
                         q                  = 0,            % 奇遇数据#rec_encounter{}
                         q_type             = 0,            % 0其他;1打怪物
                         q_finish           = 0,            % 0未过;1已过奇遇,
						 standard_time		= 0             % 副本标准通关时间
                        }).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%华丽的分割线%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-record(party_active,		{
							 id							= 0,		% 活动id
							 state						= 0,		% 活动状态
							 play_state					= 0,
							 flag						= 0,		% 活动标识（第一场或者第二场）
							 start_time					= 0,		% 开始时间
							 end_time					= 0,		% 结束时间
							 
							 play1_start_time			= 0,		% 第一次玩法开始时间
							 play1_end_time				= 0,		% 第一次玩法结束时间
							 play2_start_time			= 0,		% 第二次玩法开始时间
							 play2_end_time				= 0,		% 第二次玩法结束时间
							 
							 sp_time					= 0,		% 获取体力时间
							 exp_time					= 0,		% 获取经验时间
							 
							 map_id						= 0,
							 x							= 0,
							 y							= 0
							}).

-record(party_data,			{
							 guild_id					= 0,		% 军团id
							 guild_name					= <<"">>,	% 军团名
							 guild_lv					= 0,
							 pid						= 0,		% 军团对应宴会进程
							 play_type					= 0,		% 玩法类型
							 name_list					= [],		% UserName
							 member_list				= [],
							 box_list					= [],
							 monster_list				= []
						 	}).

-record(party_box,			{
							 id							= 0,		% 唯一id	
							 type						= 0,		% 宝箱类型
							 x							= 0,		% x坐标
							 y							= 0			% y坐标
							 }).

-record(party_monster,		{
							 id							= 0,		% 唯一id	
							 monster_id					= 0,		% 怪物id
							 x							= 0,		% x坐标
							 y							= 0,		% y坐标
							 hp							= 0,		% 怪物当前生命
							 hp_max						= 0,		% 怪物总生命上限
							 hp_tuple					= 0,		% 怪物组血量
							 death						= 0,
							 battle_list				= []
							 }).

-record(party_player,		{
							 user_id					= 0,
							 user_name					= <<"">>,
							 guild_id					= 0,
							 time						= 0,
							 sp_time					= 0,
							 enter_time					= 0,
							 cd_death					= 0,
							 exp						= 0,
							 sp							= 0,
							 gold						= 0,
							 exist						= 0,
							 auto_pk					= 0
							 }).

-record(party_doll,			{
							 user_id					= 0,		% 玩家id
							 lv							= 1,		% 玩家等级
							 vip_lv						= 0,		% vip等级
							 user_name					= <<"">>,	% 玩家名字
							 guild_id					= 0,		% 军团id
							 map_pid					= 0,		% 地图进程id
							 party_ids					= [],		% 自动参加的活动列表{act_id, date}
							 bcash						= 0,		% 绑定元宝
							 cash						= 0			% 元宝
							}).

%% 阵营战阵营信息
-record(camp_pvp_camp,      {
                             camp_id                    = 0,        % 阵营ID
                             combat                     = 0,        % 阵营战斗力
                             streak_count               = 0,        % 连续进入的人数
                             count                      = 0,        % 当前人数
                             scores                     = 0,        % 阵营积分
                             resource                   = 0,        % 阵营资源
                             boss                       = [],        % 大将军#camp_pvp_monster{}
                             event                      = [],       % 已触发事件列表[EventId]
                             buff                       = [],       % BUFF列表[{CalcType, AttrType, AttrValue}]
                             monster                    = []        % 召唤怪物列表[#camp_pvp_monster{}, #camp_pvp_monster{}]
                            }).

-record(camp_pvp_team_cross,
        {
         user_id,
         leader_id,
         camp_id,
         memlist  =[]
         }
        ).

%% -define(CONST_SYS_PLAYER,                           1).% 战斗类型--角色 
%% -define(CONST_SYS_PARTNER,                          2).% 战斗类型--武将 
%% -define(CONST_SYS_MONSTER,                          10).% 战斗类型--怪物 
%% 阵营战玩家信息
-record(camp_pvp_player,    {
                             camp_id                    = 0,        % 阵营ID
                             room_id                    = 0,
                             encourage_times            = 0,        % 鼓舞次数
                             user_id                    = 0,        % 玩家id
                             user_name                  = <<"">>,   % 玩家名称
                             pro                        = 0,        % 职业
                             guild_name                 = <<"">>,     % 军团名
                             sex                        = 0,        % 性别
                             lv                         = 0,        % 玩家等级
                             vip                        = 0,        % VIP等级
                             power                      = 0,        % 战力
                             scores                     = 0,        % 个人积分
                             scores_update_time         = 0,        % 积分更新时间
                             hp                         = [],       % 生命列表[{{Type, ID}, Maxhp, Hp}, {{Type, ID}, Maxhp, Hp}]
                             hp_expression              = {1,1},    %{当前hp, 最大hp}
                             hurt                       = 0,        % 伤害
                             auto                       = 0,        % 自动战斗(0:否|1:是)
                             exist                      = 0,         % 存在(0:是|1:否)
                             enter_cd                   = 0,        % 进入阵营战的cd
                             state                     = 0,     %% 4挖矿中,3运框中， 2战斗中， 1死亡，0 其他,
                             state_end_time            = 0,     %% 复活时间点
                             recource_type             = 0,
                             collect_streak            = 0,
                             kill_amount               = 0,     %% 杀人数
                             kill_streak               = 0,     %% 连续杀人数
                             kill_streak_max           = 0,     %% 最高连续杀人数
                             kill_streak_max_time      = 0,      %% 最高连胜的时间戳
                             killed_amount             = 0,      %% 被杀数
                             silier                    = 0, 
                             att_car_id                = 0, %% 采集战车的id
                             exploit                   = 0,      % 功勋
                             map_id                    = 0,       %% 当前地图id
                             jiangyin                  = 0,  %% 将印
                             serv_id                    = 0,
                             cash_count                = 0,
                             battle_cash_count          = 0,
                             buff_list                 = []
                            }).

-record(camp_pvp_cash_list, {
                             id = 0,
                             x = 0,
                             y = 0,
                             type = 0,
                             is_open = false
                             }).

-record(camp_room, {
                    room_id,
                    map_pid1,
                    map_pid2,
                    map_pid3,
                    box_list = []
                    }).

%% 阵营战怪物信息
-record(camp_pvp_monster,   {
                             monster_id                 = 0,        % 怪物ID
                             hp                         = 0,        % 怪物当前总生命
                             camp                       = 1,        %% 阵营
                             walkPoint                  = [],
                             killed_user_id             = 0,       % 被谁杀的
                             born_point_y               = 0,
                             monster_pid                = undefined,
                             hp_max                     = 0,        % 怪物总生命上限
                             harm                       = 0,         %% 对boss 的伤害
                             hp_tuple                   = [],         % 怪物组血量
                             hp_tuple_boss                  = {},         % 怪物组血量
                             state                      = 0
                            }).


-record(camp_pvp_invite, 
                        {
                        user_id = 0,
                        invite_list= [],
                        invited_list = []
                        }).

%% 军团战怪物信息
-record(guild_pvp_monster, {
                            monster_type = 0,
                            monster_id  = 0,
                            hp = 0,
                            camp_id = 0,
                            hp_max = 0,
                            hp_tuple_boss = {},
                            state = 0
                            }).

%% 阵营战
-record(camp_pvp_data,      {
                             state                      = 0,        % 状态
                             start_time                 = 0,        % 开始时间戳
                             end_time                   = 0,         % 结束时间戳
                             combat_top10               = []
                            }).

-record(camp_pvp_pk_cd,      {
                              user_id                    = 0,       % 玩家id
                              cd_dict                    = dict:new() % [{k,v}] k:userid, v:pk_cd_end  
                              }).


-record(cross_in,            {
                             user_id = 0,
                             player_data = {},
                             call_back = [],
                             node = "",
                             team_id = 0,
                             member_id_list = [],
                             serv_index = 0,
                             battle_player = {}
                             }).


-record(cross_out,           {
                              user_id = 0,
                              node = node(),
                              room_id = 0,
                              camp_id = 0,
                              call_back = []
                            }).

%% 合服数据
-record(combine_reward,     {
                                lv_min                  = 0,
                                lv_max                  = 0,
                                mail_title              = "",
                                mail_content            = "",
                                bgold                   = 0,
                                bcash                   = 0,
                                cash                    = 0,
                                goods                   = []
                            }).

-record(guild_pvp_guild, {
                          guild_id = 0,
                          score = 0,
                          name = 0,
                          is_leader = false,
                          camp_id = 0, % 1 供方，2 收房
                          power = 0, 
                          choosed_def = false,
                          enter_counter = 0, % 入场人数
                          first_enter_time = 0, % 第一个入场人的时间
                          rank = 0
                          }).

-record(guild_pvp_camp, {
                         camp_id = 0,
                         leader_guild_id = 0,
                         encourage_times = 0,
                         next_fire_time = 0,
                         next_fix_time = 0,
                         guild_id_list = [],
                         score = 0,
                         count = 0
                         }).

-record(guild_pvp_player,  {
                           camp_id = 0,
                           user_id = 0,
                           hp = [],
                           name = "",
                           lv = 0,
                           guild_name = "",
                           power = 0,
                           gulid_id = 0,
                           map_id = 0,
                           state = 0,
                           exist = true,
                           steak_kill = 0,
                           dead_end_time = 0,
                           position = 0,
                           hurt = 0,
                           enter_cd = 0,
						   scores = 0,
                           copper = 0,
                           encourage_times = 0,
                           bring_time = 0
                           }).

%% 每个帮派的个人积分排行 排到前5
-record(guild_pvp_score_rank, {
                              guild_id =0, 
                              score_list = [] %{name, score}
                              }).

-record(guild_pvp_state, {
                          state = 0,
                          start_time = 0,
                          on_time = 0,
                          off_time = 0
                          }).

-record(guild_pvp_map_info, {
                             user_id,
                             user_name, 
                             guild_id,
                             guild_name,
                             rank,
                             career,
                             chenghao,
                             sex
                             }).

-record(guild_pvp_rank, {
                         guild_id,
                         guild_score,
                         guild_name,
                         guild_master_name,
                         camp_id = 0
                         }).

-record(guild_pvp_watch, {
                          player_id
                          }).

-record(guild_pvp_att_wall, {
                             user_id = 0,
                             name = "",
                             level = 0,
                             start_time = 0,
                             state = 0
                             }).

%%% 活动倍数
-record(ets_active,     {
                         type,
                         state,
                         begin_time,
                         rate
                        }).

%% 充值、消费礼包
-record(deposit_group,  {
                            group_id    = 0,    % 活动组id
                            single_data = [],   % 单笔
                            amount_in   = 0,    % 总累计值
                            amount_out  = 0,    % 总累计值
                            accum_data  = []    % 累计
                        }).

%% 礼包
-record(deposit_gift,   {
                            acitve_id   = 0,
                            gift_id     = 0,
                            state       = 0       % 礼包状态：0、未生效；1、未领取；2、已领取；3、已失效。
                        }).

%% 神兵
-record(weapon_data,   {
							date		= 0,	% 日期用于刷新
                            refresh_times   = 0,% 神兵免费洗练次数
							pos			= 0,	% 双陆位置
							put_times	= 0,	% 每日投掷次数
							buy_times   = 0,	% 每日购买次数
							cd			= 0,	% 冷却时间
                            data     	= []	% 神兵数据
                        }).

%% 破阵战报
-record(ets_tower_report, {
						   	id = 0,					%% 战报ID(唯一PlatformId_SId_UserId_Time)   
						   	camp = 0,				%% 第几阵
							platform_id	= 0,		%% 平台id
							sid = 0,				%% 服务器id
							user_id = 0,			%% 玩家id
							time = 0,				%% 战报保存时间
 							lv = 0,					%% 玩家等级
							power =	0,				%% 战力值
							bin_report = <<>>,		%% 战报
							user_name = <<>>		%% 玩家名字		
						   }).

%% 破阵战报索引
-record(ets_tower_report_idx, {
                                camp_id,        %% 阵id
                                reports         %% 战报id列表[{user_id, report_id},...] 
                              }). 

%% 精英副本战报
-record(ets_copy_single_report,{ 
								id = 0,                 %% 战报ID(唯一 UserId_Time)   
								copy_id = 0,          	%% 副本id
								platform_id = 0,		%% 平台id
								sid = 0,				%% 服务器id
								user_id = 0,            %% 玩家id
								time = 0,               %% 战报存放时间
								lv = 0,					%% 玩家等级
								power = 0,				%% 战力值
								bin_report = <<>>,		%% 战报
								user_name = <<>>		%% 玩家名字
								}).

%% 破阵战报索引
-record(ets_copy_single_report_idx, {
                                copy_id,        %% 副本id
                                reports         %% 战报id列表[id,id...] 
                              }). 

%% 跨服结点信息
-record(ets_cross_node_info, {
                                node,           %% 结点名
                                serv,           %% 服务器id列表
                                room_list       %% 战场id列表
                             }).

%% 阵营战计数器
-record(ets_camp_pvp_counter, {
                                room_id  = 0,
                                node     = 0,
                                lv_phase = 0,
                                seeds    = [],
                                seeds_count = 0,
                                count    = 0,
                                last_camp_id = 0,
                                camp_power_1 = 0,
                                camp_power_2 = 0
                              }).

-record(ets_camp_pvp_leader,  {
                               leader_id = 0, 
                               last_node = 0
                              }).

-record(ets_camp_pvp_lv_phase, {
                                lv_phase     = 0,
                                room_list    = [],
                                lv_from      = 0,
                                lv_to        = 0, 
                                last_room_id = 0
                               }).
-record(ets_active_stone_compose, {
								  user_id				= 0,
								  stone_compose_list	= []	% [{lv,count}]
								}).

%% 阵营战种子选手
-record(ets_camp_pvp_seeds,   {
                                user_id = 0,
                                power   = 0,
                                lv      = 0,
                                serv_id = 0,
                                camp_id = 0,
                                room_id = 0
                              }).

%% 
-record(ets_camp_pvp_nodes, {
                                key = null, % {leader_id, node}
                                next = 0
                               }).

%% 
-record(ets_cross_user,       {
                                user_id = 0,
                                serv_id = 0, 
                                lv      = 0,
                                node    = 0,
                                room_id = 0,
                                camp_id = 0
                              }).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 世界boss计数器
-record(ets_boss_cross_counter, {
                                room_id  	= 0,			%% 分配到所在房间
                                node     	= 0,			%% 分配到所在节点
                                lv_phase 	= 0,			%% 等级段
                                seeds    	= [],			%% 种子列表
                                seeds_count = 0,
                                count    	= 0,			%% 房间总人数
								human_count = 0,			%% 房间自然人数
								robot_count = 0             %% 房间机器人数
                              }).

%% 世界boss主节点信息
-record(ets_boss_cross_leader,  {
                               leader_id = 0, 
                               last_node = 0
                              }).
%% 世界boss等级段分配信息
-record(ets_boss_cross_lv_phase, {
                                lv_phase     = 0,
                                room_list    = [],
                                lv_from      = 0,
                                lv_to        = 0, 
                                last_room_id = 0
                               }).
%% 世界boss存活节点信息
-record(ets_boss_cross_nodes, {
                                key = null, % {leader_id, node}
                                next = 0
                               }).
%% 世界boss节点人物信息
-record(ets_boss_cross_user,    {
                                user_id = 0,
                                serv_id = 0, 
                                lv      = 0,
                                node    = 0,
                                room_id = 0
                              }).

%% 世界boss种子选手
-record(ets_boss_cross_seeds,   {
                                user_id = 0,
                                power   = 0,
                                lv      = 0,
                                serv_id = 0,
                                room_id = 0
                              }).
%% 世界boss跨服进来
-record(ets_boss_cross_in,            {
                             user_id = 0,
                             player_data = {},
                             call_back = [],
                             node = "",
                             room_id = 0,
                             serv_index = 0,
							 lv_phase = 0
                             }).

%% 世界boss跨服出去
-record(ets_boss_cross_out,   {
                              user_id = 0,
                              node = node(),
                              room_id = 0,
                              call_back = [],
							  lv_phase = 0
                            }).

%% 世界boss房间信息
-record(ets_boss_cross_room, {
							 room = 0,
							 map_id = 0,
 							 map_pid = 0
								}).		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 开服活动荣誉榜
-record(rec_honor_title,
		{
		 honor_id = 0,		% 荣誉榜ID
		 user_id = 0,		% 玩家ID
		 user_name = 0,		% 玩家名称
		 lv = 0,			% 玩家等级
		 sex = 0,			% 性别
		 pro = 0,			% 职业
		 weapon = 0,		% 武器ID
		 fashion = 0,		% 时装ID
		 armor = 0			% 衣服ID
		}
	   ).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 开服活动英雄榜
-record(rec_hero_rank,
		{
			type,			% 1、战力；2、军团等级；3、破阵 
			data			% 前三甲信息：#hero_rank{id, name, lv}
		 }
	   ).

-record(hero_rank_data,
		{
			id,			% 玩家ID或军团ID 
			name,		% 名称
			lv,			% 等级
			rank		% 名次
		 }
	   ).



-record(camp_team_index, {
                          user_id,
                          leader_id
                          }).

-record(camp_team_list, {
                          leader_id,
                          id_list = []
                          }).

-record(camp_team_member, {
                           user_id,
                           name,
                           sex,
                           career,
                           lv,
                           choth,
                           fashion,
                           weapon,
                           attr_type,
                           attr_value
                           }).

%% 节点信息
-record(ets_node_info, {
						node_name = null,	% 节点名
						info_list = [],		% 节点开关列表
						update_time = 0	% 更新时间
					   }
	   ).

-record(snow_info,{
                					user_id					= 0,			% 角色id
                					count					= 0,			% 剩余礼灯数
                					level					= 0,			% 当前的层数
                					last_level				= 0,			% 上一次点亮的层
                					last_pos				= 0,			% 上一次点亮的位置
                					lighted_list			= [],			% 点亮信息
                					store_list				= []			% 收集信息
					}).

-record(snow_lighted_list,{
        						    level,			         % 层
        						    lighted_list		     % 已点亮的位置列表
						   }).

-record(snow_goods_list,{
            						 level			= 0,	% 层
            						 goods_list		= [],	% 物品列表{pos,rate,goodsid,bind,num}
            						 goods_list2	= [],	% 收集物品
                                     need_count		= 0,	% 消耗的礼灯数
                                     start_time,			% 开始时间
            						 end_time				% 结束时间
						 }).
-record(goods_info,          {
                					 pos			= 0,	% 位置
                					 rate		    = 0,	% 概率
                					 goods_id	    = 0,	% 物品id
                					 bind		    = 0,	% 绑定
					                 num			= 0		% 数量
					         }).

-record(snow_store_goodslist,{
							         level			= 0,	% 层
							         goods_list	    = []		% 物品列表
							  }).
-record(yunying_activity_exchange,{
								   id				= 0,		% 兑换id
								   type,						% 类型
								   need_goods,					% 需要的物品
								   exchange_goods				% 兑换的物品
								  }).

-record(yunying_activity_stone_compose,{
								   		stone_lv		= 0,		% 宝石等级
								   		award_goods				% 奖励物品
								  }).

-record(yunying_activity_parnter_exchange,{
										   type			= 0,
										   id			= 0,
										   need_goods,					% 需要的物品
										   exchange_goods				% 兑换的物品
										  }).
%% md5信息记录
-record(ets_md5,                {
                                     md5  = 0,
                                     time = 0
                                }).
                                
%% 跨服竞技场信息		
-record(ets_cross_arena_member, {	
      player_id = 0,                          %% 玩家ID	
      player_name = "",                       %% 玩家名字	
      player_sex = 0,                         %% 玩家性别	
      player_lv = 0,                          %% 玩家等级			需要从人物属性刷新	
      player_career = 0,                      %% 职业	
      last_rank	= 0,						  %% 昨天排名
      last_phase = 0,						  %% 昨天段位
      last_group = 0,						  %% 昨日分组
      rank = 0,                               %% 排名	
      phase	= 0,							  %% 段位
      group	= 0,							  %% 分组
      times = 0,                              %% 今日剩余挑战次数	
      last_win_times	= 0,				  %% 昨日日胜利次数
      win_times	= 0,						  %% 今日胜利次数
      fail_times = 0,						  %% 今日失败次数
      fight_force = 0,                        %% 战力				需要从人物属性刷新
      partner_list = [],                      %% 计算时间
      open_flag = 0,                          %% 是否打开竞技场界面	
      on_line_flag = 0,                       %% 在线标志	
      platform	= "",						  %% 平台名
      sn = 0,                                 %% 服务器编号	
      node = "",							  %% 节点名
      achieve = [],              			  %% 已经领过的连胜奖励 #cross_arena_achieve{}
      score = 0,                              %% 积分
      fight_list = [],						  %% 已挑战列表
      cross_state = 0,						  %% 跨服状态
      player_data = ?null,					  %% 跨服player
      player_data2 = ?null,					  %% 跨服player
      player_data3 = ?null,					  %% 跨服player
      update_time = 0						  %% 跨服player更新时间
	}).	
	
%% 跨服竞技场成就
-record(cross_arena_phase, {	
	  phase = 0,				  	  		  %% 组
	  group_list = []						  %% {group, user_list}
	}).
	
%% 跨服竞技场成就
-record(cross_arena_achieve, {	
	  id = 0,								  %% 成就id
	  flag = 0								  %% 是否领取
	}).

%% 跨服竞技场战报	 	
-record(cross_arena_report, {	
      id,                                     %% 战报ID(唯一 UserId_Time)	
      result = 0,                             %% 1胜利2失败	
      time = 0,                               %% 战报存放时间	
      attack_id = 0,                          %% 攻击方ID
      attack_name = "",						  %% 攻击方名字	
      deffender_id = 0,                       %% 防御方ID	
      deffender_name = "",                    %% 防御方名字	
      bin_report = <<>>		                  %% 战报	
    }).	

%% 跨服竞技场组内战报
-record(cross_arena_group_report, {	
      phase_group,                            %% {段id, 组id}	
      report_list = []						  %% 战报列表 [report_id, ...]
    }).	
  
-record(cross_arena_robot_member, {	
      player_id,                              %% 玩家id
      fight_list = []						  %% 已挑战列表
    }).	
         
%% %% 
%% -record(ets_center_node_info, {
%%         sid   = 0,  % 服务器号
%%         node  = 0,  % 结点名
%%         state = 0,  % 状态
%%         time  = 0   % 重置时间点
%%     }).

%% 激活码
-record(ets_player_code, {
        code = 0,
        code_type = 0,
        state = 0,
        delay = 0
    }).

%% 服务器节信息表
-record(ets_serv_info, {
						sid 		= 0, 	% 服务器号
						node_name 	= null,	% 节点名
						state		= 0,	% 状态
						time		= 0		% 时间戳
					   }).

%% 辕门射戟信息表
-record(ets_archery_info, {
                             user_id ,   %玩家ID
                             power    =0,%射击力度
                             angle    =45,%射击角度
                             arrow    =5, %箭矢
                             accGet   =0, %累计奖励
                             done     =0, %通关靶场
							 courtInfo=null,%靶场信息 [{Pos,Length,Hight}..]
							 point    =0, %得分
							 time     =0,  %时间戳
							 instrution = 0, %新手引导次数
							 limit_buy = 0  %限制购买次数
						  }).

%% 攻城掠地信息表
-record(ets_encroach_info, {
							user_id			= 0,	% 玩家id
							pos				= 1,	% 当前位置
							next_pos		= 0,	% 下一个要移动的位置(精兵和大将战斗失败使用)
							info_list		= [],	% {Pos, Type, State}
							m_force			= 0,	% 当前移动力
							total_m_force	= 0,	% 总的移动力
							exp				= 0,	% 获得的经验
							reward			= [],	% 获得道具
							times			= 0,	% 玩家每天次数
							update_time		= 0,	% 更新时间
							lottery_idx		= 0,	% 抽奖索引位置
							lottery_packet	= <<>>	% 抽奖广播
						   }).

%% 基金
-record(fund_data,       {
                            in = 0,             % 总存入
                            start_time = 0,     % 开始时间
                            type = 0,           % 基金类型
                            returned_times = 0  % 已返还次数
                        }).

%% 攻城掠地个人排行榜数据
-record(encroach_rank, {
						user_id		= 0,		% 玩家id
						rank		= 0,		% 排行
						user_name	= <<>>,		% 玩家名字
						lv			= 0,		% 等级
						exp			= 0,		% 经验
						update_time	= 0			% 更新时间
					   }).

%% 攻城掠地排行榜数据
-record(ets_encroach_rank, {
							rank_id		= 0,	% 排行榜id
							data		= [],	% 排行榜数据
							update_time	= 0		% 更新时间
						   }).

%% 云游商人
-record(ets_secret, {
					 id			= 0,		% id
					 log_data	= [],		% 记录数据
					 start_time	= 0,		% 开始时间
					 end_time 	= 0			%  结束时间
					}).

%% 云游商人玩家信息
-record(ets_secret_info, {
						  user_id		= 0,	% 玩家id
						  data			= [],	% 货架数据[{Id, Data, State},...]
						  free 			= 0,	% 免费刷新次数
						  refresh 		= 0,	% 花费刷新次数
						  score 		= 0,	% 积分
						  buy_times		= 0,	% 已购买次数 
						  update_time	= 0		%  更新时间
						 }).

-record(ets_gamble_room_mini, 
                        {
                             key = {0,0}, % {roomid, sevId}
                             chip = 0
                        }).

%% 青梅煮酒房间信息
-record(ets_gamble_room,{
						 room_id = 0
						 , reg_name = null %房间进程注册名
						 , player1_id =0 %玩家1的id
                         , player1_sid = 0 %玩家2sid
						 , player2_id =0 %玩家2的id
						 , player2_sid =0%玩家2的sid
						 , room_state = 0%房间状态（1游戏未开始，缺一个；2游戏未开，2个没准备；3游戏未开始，1个已准备；4游戏中
						 , state_time =0 %状态时间戳
						 , player1_score =0%玩家1得分
						 , player2_score  =0%玩家2得分
						 , player1_cards = []%玩家1手牌
                         , player2_cards = []%玩家2手牌
						 , chip  =0 %本轮筹码
						 , round  =1 %游戏进行轮数
						 , history =null%出牌历史[{card1,card2}...]
						 , player1_ready  =0%玩家1准备状态
						 , player2_ready  =0%玩家2准备状态
						 , player1_card  =0%玩家1出牌
						 , player2_card  =0%玩家2出牌
						 , winstate = '_'
 }).
%% 青梅煮酒玩家信息
-record(ets_gamble_player, {
							user_id =0 %玩家ID
							, chips = 0 %玩家筹码
							, timestamp = 0 %时间戳
							, times = 0 %游戏次数
						   }).

-record(ets_card21, 
        {
            user_id = 0,
            chip_total = 0,
            chip_now = 0,
            state = 0,
            self_cardId_list = [],
            computer_cardId_list = [],
            rest_card_list = []
         }).

%% 闯关比赛玩家信息
-record(ets_match_player,{
						  uni_key = {0,0,0},	%% 全平台唯一id {platform_id,sid,user_id}
						  user_name = <<>>,		%% 玩家名字
						  pro = 0,				%% 职业
						  sex = 0,				%% 性别
						  lv = 0,				%% 等级
						  score = 0,			%% 总分数
						  free_times = 0,		%% 免费参加次数
						  total_times = 0,		%% 总的已参加次数
						  rank = 0,				%% 排行
						  list = [],			%% 各关数据 [#match_player_copy]
						  update_time = 0		%% 更新时间
						 }).

%% 闯关排行榜
-record(ets_match_rank,{
						rank = 0,				%% 排行
						uni_key = {0,0,0},		%% 全平台唯一id {platform_id,sid,user_id}
						user_name = <<>>,		%% 玩家名字
						pro = 0,				%% 职业
						sex = 0,				%% 性别
						lv = 0,					%% 等级
						score = 0,				%% 总分数
						update_time = 0			%% 更新时间
					   }).

%% 闯关比赛关卡个人记录
-record(ets_match_copy,{
						rank = 0,				%% 排行
						uni_key = {0,0,0},		%% 全平台唯一id {platform_id,sid,user_id}
						user_name = <<>>,		%% 玩家名字
						pro = 0,				%% 职业
						sex = 0,				%% 性别
						lv = 0,					%% 等级
						score = 0,				%% 最高分数
						update_time = 0			%% 更新时间
					   }).

%% 闯关比赛关卡排行信息
-record(ets_match_copy_idx,{
							copy_id = 0,		%% 关卡id
							data = []			%% 关卡玩家排行数据[{rank,uni_key,data}]
						   }).

%% 闯关比赛玩家关卡信息
-record(match_player_copy, {
							copy_id = 0,		%% 关卡id
							best_score = 0,		%% 最好成绩
							last_score = 0,		%% 上次成绩
							state =  0,			%% 状态 0未通 1已通
							set_data = [],		%% 设置数据 武将装备宝石武技
							update_time = 0		%% 更新时间
						   }).