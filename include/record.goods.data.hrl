
%% 容器                                        
-record(ctn,            {                               
                         max                = 0,            % 最大格子数          
                         usable             = 0,            % 可用格子数           
                         used               = 0,            % 已使用格子数         
                         goods              = {},           % 物品列表(元组)
                         ext                = {},           % 扩展字段       
                         extend_times       = 0             % 总扩展次数
                        }).
                              

%% 物品标志位集
-record(g_flag,         {
						 is_limit	  		 = 0, % 物品限制掉落(0为不限制|策划配置小时数)
                         is_logs             = 0, % 物品记录日志	只有勾选后服务器才会记录次物品的日志，方便查询追踪
                         is_sell             = 0, % 物品出售          	这里的出售指的是npc商店
                         is_depot            = 0, % 物品存仓库
                         is_biz              = 0, % 物品交易
                         is_destroy          = 0, % 物品销毁
                         is_bind             = 0, % 物品自动绑定
                         is_timer            = 0, % 物品立即计时
                         is_split            = 0, % 物品拆分
                         is_part             = 0  % 物品装备分解
                        }).

%% 物品
-record(goods,          {                    
                         goods_id            = 0,            % 物品的ID
                         name                = "",           % 物品名称
                         type                = 0,            % 物品类型:装备/宝石/丹药
                         sub_type            = 0,            % 物品子类型:武器、头盔等
                         sell_type           = 0,            % 物品出售价格类型
                         sell_price          = 0,            % 物品出售价格
						 lv                  = 0,            % 等级
                         pro                 = 0,            % 职业(0为不限制)
                         sex                 = 0,            % 性别（0为不限，1为男，2为女）
                         vip                 = 0,            % vip等级限制，0为不限制
                         country             = 0,            % 国家
                         stack               = 1,            % 可叠加数
                         color               = 0,            % 物品颜色，0 绿色，1 蓝色，2 紫色，3 橙色， 4 红色
                         duration            = 99999999,     % 可用持续时间 从收到物品开始，可持续使用时间，单位秒
						 
                         exts                = ?null,        % 扩展数据
                         idx                 = 1,            % 所在容器位置索引
                         count               = 1,            % 物品数量
                         flag                = #g_flag{},    % 在内存中是#rec_goods_flag{}
                         start_time          = 0,            % 可用结束时间Unix元年制
						 end_time	         = 0,            % 可用结束时间Unix元年制
                         bind                = 0,            % 绑定状态
                         time_temp           = 0             % 临时背包结束时间
                        }).

%% 装备
%% 1.武器；2.胸甲；3.头盔；4.靴子；5.披风；6.腰带；
%% 7.项链；8.戒指；9.时装；10.帮派徽章；11.坐骑；
%% 12.装备-时装武器；13.装备-时装足迹
-record(g_equip,        {
						 strength_lv			= 0,	   % 强化等级，具体的强化值需要的时候根据公式计算(0-99)
                         suit_id                = 0,       % 套装id
						 skin_id				= 0,	   % 皮肤id	
                         exp					= 0,	   % 经验(坐骑)
						 skill_id				= 0,	   % 技能ID
						 attr                   = ?null,   % 常规属性#attr{}
						 soul_list				= [], 	   % 附魂属性列表[{SoulId, SoulLv}, {SoulId, SoulLv}, ...]
						 attr_soul				= [],	   % 附魂属性[{AttrType, AttrValue},{AttrType, AttrValue}, ...]
						 ride_list				= [],
                         fusion_lv              = 0,       % 时装等级
                         upgrade_price          = 0        % 升阶费用
						}).

%% 宠物蛋                         
%% 1.宠物蛋               
-record(g_egg,          {
                         target_id, 	% 目标宠物id
						 exp
                        }).

%% 技能书                                     
%% 1：宠物技能书;2：角色技能书 3：遁甲天书技能书 99：其他   
-record(g_skill_book,   {
                         skill_id 		% 技能id
                        }).

%% 补给品 -- 立即全部收益        
%% 1：血包；2：宠物经验书；3：武将经验书 99：其他                                
-record(g_supply,       {
                         effect_value 	% 效果id
                        }).

%% 宝箱 
%% 1,普通宝箱；2，宠物采集包 3：结婚红包,4:招财宝箱 99：其他
-record(g_box,          {
                         goods_drop_id 	% 物品掉落id
                        }).

%% 礼包
%% 1：成长礼包；2：新手礼包；3：充值礼包；4：媒体礼包；99：其他礼包 
-record(g_package,      {
                         goods_drop_id 	% 物品掉落id
                        }).
%% 任务道具
%% 1:任务道具 99：其他
-record(g_task,         {
                         task_id 		% 任务id
                        }).

%% 临时属性符buff
%% 1：临时属性符 99：其他
-record(g_buff,         {
						 buff_type,		% BUFF类型
						 buff_value,	% BUFF值
						 time			% 有效期
                        }).

%% 功能消耗材料
%% 01：喇叭 02：帮派建立道具 03：结婚烟花 04：结婚同心结 05：结婚喜糖 
%% 06：天赋丹 07：天赋丹保护符 08：武将培养消耗品  09：宠物成长丹 10：宠物成长保护符 
%% 11：宠物资质丹12：宠物资质保护符13：宠物性格转换道具 14：宠物返生丹 15：装备合成材料  
%% 16：装备洗练符  17：装备洗练保护符  18：装备锻造图纸  19武将喜好品 20 招财宝箱钥匙
-record(g_func,         {
                         exp, % 经验
                         meritorious, % 阅历
                         convert_cash, % 折算元宝
                         effect_time,  % 生效秒数
                         effect_id     % 效果id
						}).

%% 神兵碎片
%% 1.部位1；2.部位2；3.部位3；4.部位4；
-record(g_weapon,       {
						 attr_list                   = []   % 常规属性#attr{}
						}).

%% 容器中的物品结构
-record(mini_goods, {
                         goods_id            = 0,            % 物品id
                         exts                = ?null,        % 扩展数据
                         idx                 = 1,            % 所在容器位置索引
                         count               = 1,            % 物品数量
                         start_time          = 0,            % 可用结束时间Unix元年制
                         end_time            = 0,            % 可用结束时间Unix元年制
                         bind                = 0,            % 绑定状态
                         time_temp           = 0             % 临时背包结束时间
                    }).