
%% -------------------------------------------------------------------
%% erlang版crontab配置文件
%% 长期的定时任务配置
%% 也可以不在这里配置，而直接通过接口调用，向server_crond增加新任务，格式与此相同
%% 取值：
%% 	分：[0-59]  时：[0-23]  日: [1-31] 月：[1-12]  周：[1-7]
%% -------------------------------------------------------------------
%% 在线人数  每5分钟 统计一次
%% {stat_1,	[0,5,10,15,20,25,30,35,40,45,50,55],[] ,				[] ,				[] ,		[] ,			{ stat_api,   online , 			[] } } .

%% 排行榜
{rank1, 			
					[5],         	% min 
					[4,8,12,16,20], % hour
					[],           	% day
					[],           	% month
					[],           	% week
					{rank_api, brocast, [0]} % {M, F, A}
}.
{rank2, 			
					[5],         	% min 
					[0],         	% hour
					[],           	% day
					[],           	% month
					[],           	% week
					{rank_api, brocast, [1]} % {M, F, A}
}.

%% 英雄战场每周积分奖励
{arena_pvp_reward, 	   
					[5],          % min 
					[0],      	  % hour
					[],           % day
					[],           % month
					[1],          % week
					{arena_pvp_api, week_reward, []} % {M, F, A}
}.



%% 恢复体力
{player_refresh_sp,           
                  [0, 30],        % min 
                  [],             % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {player_sup, refresh_sp, []} % {M, F, A}
}.

%% 个人竞技场成员数据回写数据库
{single_arena_db,           
                  [5],        % min 测试数据 
                  [],             % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {single_arena_api, refresh_daily_db, [0]} % {M, F, A}
}.

%% 发放个人竞技场奖励
{single_arena_api,           
                  [0],        	  % min 
                  [20],           % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {single_arena_api, refresh_daily_award, []} % {M, F, A}
}.

%% 0点处理
{player_0,           
                  [0],           % min 
                  [0],           % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {player_api, handle_zero_oclock, []} % {M, F, A}
}.

%% 排行榜刷新
{rank_update_rank_ets_clock,           
                  [30],           % min 
                  [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23],           % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {rank_api, update_rank_ets, [1]} % {M, F, A}
}.

%% 零点处理离线修炼机器人 
{practice_robot, 			
					[1],         	% min 
					[0], % hour
					[],           	% day
					[],           	% month
					[],           	% week
					{practice_api, add_tomorrow_time, []} % {M, F, A}
}.

%% 0点前清离线
{player_before_0,           
                  [30],           % min 
                  [23],           % hour
                  [],             % day
                  [],             % month
                  [],             % week
                  {player_api, clear_player_off_zero, []} % {M, F, A}
}.


%% 零点处理攻城掠地排行榜
{encroach_rank, 			
					[5],         	% min 
					[0], % hour
					[],           	% day
					[],           	% month
					[],           	% week
					{encroach_api, rest_encroach_rank, []} % {M, F, A}
}.
