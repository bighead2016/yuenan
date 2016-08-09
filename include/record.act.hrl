
%% 定时任务
-record(ets_act_info, {
                    id,
                    start_time,
                    stop_time,
                    template,
                    config_id,
                    reset_daily,
                    clear_over,
                    is_open
                     }).

%% 活动玩家数据
-record(ets_act_user, {
                       key,     % {user_id, act_id}
                       user_id, % 玩家id
                       act_id,  % 活动id
                       data     % 玩家数据
                       }).

%% 活动模版
-record(ets_act_tmp, {
                       temp_id,     % template_id
                       act_id   % 活动id
                       }).

%% 转盘结构
-record(act_turn_data, {
                             in_cash            = 0,    % 已经充值金额
                             got_partner        = 0,    % 获得武将
                             times              = 0,    % 可抽奖次数
                             count              = 0     % 已抽奖次数
                        }).

%% 神刀结构 
-record(act_card_ex, {
					  cards = [], %拥有的卡片
					  points = 0, %积分
					  last_lottery = [], %抽牌界面
					  free = 0 %免费白银次数
					 }).

%% 百服活动玩家信息
-record(ets_act_hundred, {
						  key ,
						  user_id = 0,
						  act_id = 1,
						  point = 0
						 }).
