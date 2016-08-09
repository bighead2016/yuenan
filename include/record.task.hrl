%%% 玩家任务数据 

%% 任务主结构
-record(task_data,      {
                         main               = ?null,        % 主线任务
                         main_idx           = ?null,        % 主线任务索引
                         branch             = ?null,        % 任务列表
                         position_task      = ?null,        % 官衔任务 #task{}
                         guild_cycle        = ?null,        % 军团任务 #task_cycle{},
                         daily_cycle        = ?null,        % 日常任务 #task_cycle{},
                         acceptable_count   = 0,            % 可接任务数
                         unfinished_count   = 0,            % 未完成任务数
                         
                         note               = [],         %% 记录
						 everyday_task		= ?null         % 每日任务列表
                        }).

%% 支线任务
-record(branch_task,    {
                         unacceptable       = [],           % 不可接任务列表  [#task{}]
                         acceptable         = [],           % 可接任务列表   [#task{}]
                         unfinished         = [],           % 未完成任务列表  [#task{}]
                         finished           = []            % 已完成任务id列表 [id]
                        }).

%% 环任务结构
-record(task_cycle,    {
                         current            = ?null,        % 当前任务 #task{}
                         lib                = [],           % 当前环的任务列表 [#task{}]
                         lib_id             = 0,            % 库id
                         special_reward     = 0,			% 特殊体力奖励
                         goods              = [],           % 完成后的物品奖励列表
                         times              = 0,            % 已经提交的次数
                         total_count        = 0,            % 总次数
                         date               = 0             % 日期 
                       }).
%% 
%% %% 官衔任务
%% -record(position_task,  {
%%                          current            = ?null,        % 当前任务 #task{}
%%                          acceptable         = [],           % 系列任务列表
%%                          unacceptable       = [],           % 不可接任务列表
%%                          lib_id             = 0             % 系列id
%%                         }).

%% 普通任务结构
-record(task,           {
                         id                 = 0,            % 任务ID
						 name				= <<"">>,		% 任务名称
						 idx				= 0, 			% 主线任务索引
                         type               = 0,            % 任务类型
                         open_sys           = 0,            % 接任务开启系统ID
                         open_sys_2         = 0,            % 完成任务开启系统ID
                         open_map_id        = 0,            % 开启地图ID
                         flag_accept        = 0,            % 接任务标示
                         flag_submit        = 0,            % 交任务标示
                         prev               = 0,            % 前置任务ID
                         next               = 0,            % 后续任务ID
                         abandon            = 0,            % 是否可放弃
                         ignore             = 0,            % 是否可呼略
                         quick              = 0,            % 是否快速完成
                         quick_cost         = 0,            % 快速完成花费
                         cycle              = 0,            % 重复次数
                         lv_min             = 0,            % 等级下限
                         lv_max             = 0,            % 等级上限
                         time_limit         = 0,            % 时间限制
                         pro                = 0,            % 职业
                         require_attr_id    = 0,            % 要求属性ID
                         require_attr_value = 0,            % 要求属性具体值
                         require_goods      = 0,            % 要求物品ID
                         position_id        = 0,            % 要求官衔id
                         target             = 0,            % 任务目标
                         exp                = 0,            % 经验
                         gold               = 0,            % 金币
                         gold_bind          = 0,            % 邦定金币
                         copy_id            = 0,            % 副本ID
                         require_attr_rate  = 0,            % 要求属性系数
                         attr_rate          = 0,            % 属性系数
                         partner            = [],           % 武将列表
                         partner_look_for   = [],           % 寻武将列表
                         award_attr_id      = 0,            % 其他奖励属性ID
                         award_attr_value   = 0,            % 奖励属性值
                         goods              = 0,            % 物品
                         experience         = 0,            % 培养值
                         meritorious        = 0,            % 功勋
                         pullulation        = 0,            % 成长点
                         pullulation_power  = 0,            % 威武id
                         copy_id_finished   = 0,            % 完成副本后投放
                         need_show			= [],           % 需表现武将

                         state              = 0,            % 状态   0:未激活  1:已激活(隐藏)   2:可接受    3:接受未完成   4:完成未提交  5:已提交
                         count              = 0,            % 每天接任务次数(日常:每天重复次数|随机:随机次数)
                         date               = 0,            % 任务接受日期
                         time               = 0,            % 任务接受时间
                         is_temp            = 0             % 是否进临时背包          
                        }).

%% 压缩后的任务结构
-record(mini_task,      {
                         id                 = 0,            % 任务ID
                         target             = 0,            % 任务目标

                         state              = 0,            % 状态   0:未激活  1:已激活(隐藏)   2:可接受    3:接受未完成   4:完成未提交  5:已提交
                         count              = 0,            % 每天接任务次数(日常:每天重复次数|随机:随机次数)
                         date               = 0,            % 任务接受日期
                         time               = 0             % 任务接受时间
                        }).

%% 

%% 任务目标
-record(task_target,    {
                         idx                = 0,  % 目标索引
                         target_type        = 0,  % 目标类型
                         
                         as1                = 0,  % 静态属性
                         as2                = 0,  % 静态属性
                         as3                = 0,  % 静态属性
                         as4                = 0,  % 静态属性
                         as5                = 0,  % 静态属性
                         
                         ad1                = 0,  % 动态属性
                         ad2                = 0,  % 动态属性
                         ad3                = 0,  % 动态属性
                         ad4                = 0,  % 动态属性
                         ad5                = 0   % 动态属性
                        }).

-record(task_type,  {
                         type               = 0  :: non_neg_integer(),  % 类型常量
                         mod                = "" :: atom()  % 对应模块名
                    }).

-record(task_func,  {
                         export             = "",
                         func_s             = "",
                         func               = "",
                         begin_str          = "", 
                         end_str            = ""
                     }).

%% 记录
-record(task_note,   {
                         id                 = 0,
                         value              = 0
                     }).


