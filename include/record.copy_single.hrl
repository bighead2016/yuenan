%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家副本数据 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 副本
-record(copy_data,      {
                         date               = 0,    % 日期
						 top_id				= 0,	% 最高精英副本id
						 top_time			= 0,	% 最高精英副本通过时间
                         copy_bag           = [],   % 副本列表
                         serial_bag         = [],   % 系列列表
                         copy_cur           = null % 当前副本信息
                        }).

%% 副本信息 - 加标志位版
-record(copy_one,      {
                         id                 = 0,    % id         
                         flags              = null, % 众标志
                         daily_times        = 0     % 当天已做次数
                        }).

-record(copy_flags,     {
                         is_passed          = 0,    % 已经通关?
                         is_tasked          = 0,    % 对应主线任务已经完成?
                         is_shadowed        = 0,    % 隐藏中?
                         is_2               = 0     % 第2波?
                        }).

-record(serial_one,     {
                         id                 = 0,    % id
                         is_passed          = 0,    % 全系列通关?
                         reseted_times      = 0     % 重置次数
                        }).

%% 当前副本信息
-record(copy_cur,       {
                         copy_id            = 0,    % 当前副本ID
                         type               = 0,    % 当前副本类型
                         serial_id          = 0,    % 当前副本系列id
                         map_id             = 0,    % 当前副本地图id                         
                         map_step           = 0,    % 当前副本地图进度
                         monster_id         = 0,    % 当前副本怪物id
                         ai_id              = 0,    % 当前副本怪物aiid
                         mon_tuple          = null,% 当前副本的怪物元组
                         plot_id            = 0,    % 当前剧情id
                         plot_tuple         = null,% 当前剧情元组
                         total_waves        = 0,    % 总波数
                         rewards            = null,% 当前副本的奖励
                         times_limit        = 0,    % 次数限制
                         standard_time      = 0,    % 标准时间差
                         begin_time         = 0,    % 开始时间
                         total_hurt_l       = 0,    % 左边的总战斗伤害 
                         total_hurt_r       = 0,    % 右边的总战斗伤害
                         need_sp            = 0,    % 需要体力
                         is_cost_sp         = 0     % 扣体力了?
                        }).

%% 副本奖励
-record(copy_reward,    {
                         goods_drop_id      = 0,    % 物品掉落id
                         exp                = 0,    % 经验
                         gold               = 0     % 铜钱
                        }).