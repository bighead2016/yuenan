
%% -------------------------------------------------------------------
%% 定时要执行的函数
%% 唯一ID					间隔秒数        
%% {unique_id,				second					{M,F,A} }
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
{market_buy_interval,	       	20,					{market_mod, 	 			check_buy_sale_goods,	[]}}.
{mall_discount,                	28800,              {mall_api,       			flush_discount,      	[]}}.
{practice_exp,                 	10,                 {practice_api,   			flush_exp,           	[]}}.
 
%% 刷新玩家每秒需要进行的操作
{player_one_second_update,     	1,                  {player_sup,     			refresh,             	[]}}. % 1秒

%% 清地图
{clean_maps,                  	60,                 {map_api,        			clean_maps,          	[]}}. % 1分钟

%% 清理僵死多人组队进程
%% {clean_up,                  	60,                 {team_serv,      			clean_up,            	[]}}. % 1分钟

%% 副本在线数据更新
{update_raid,                  	3,                  {copy_single_raid_api, 		update_raid,     		[]}}. % 3秒
{update_elite_raid,            	3,                  {copy_single_elite_raid_api,update_raid,     		[]}}. % 3秒

%% 闯塔在线数据更新
{update_sweep,                 	5,                  {tower_sweep_api, 			update_sweep,         	[]}}. % 5秒		

%% 常规组队加成刷新
%% {group_refresh_buff,			300,				{group_api,       			refresh_buffer,         []}}. % 300秒	

%% 采集在线数据更新
%% {update_collect,             3,                  {collect_api, 				update_collect,     	[]}}. % 10秒

%% 商路系统
{market_interval,				5,					{commerce_api,				market_clear,			[]}}. %	5秒
{caravan_interval,				5,					{commerce_api,				caravan_clear,			[]}}. %	5秒
{commerce_interval,				10,					{commerce_api,				commerce_clear,			[]}}. %	10秒
%% {friend_interval,			5,					{commerce_api,				friend_clear,			[]}}. %	5秒

%% 怪物心跳
{monster_beat_heart,            1,                 	{monster_api,       		beat_heart,             []}}. % 1秒

%% 一骑讨回写心跳
{single_arena_interval,        	3600,               {single_arena_api, 			refresh_daily_db, 		[]}}. % 1小时

%% 奖池定时增加奖励
{resource_add,    				10,                 {resource_api,				resource_add_award, 	[add_bcash]}}.
{resource_add2,    				10,                 {resource_api,				resource_add_award, 	[update_exp_pool]}}.

%% 异民族机器人
{invasion_robot,    			5,                  {invasion_api,				invasion_robot, 		[]}}.

%% 离线修炼机器人
{practice_robot,				3600, 				{practice_api,				clear_robot,			[]}}.

%% 清理md5
%% {clear_md5_interval,			300, 				{player_login_api, 			clear_md5, 				[]}}.

%% 向中心节点同步服务器信息
{sync_serv_info,				3600,				{center_api, 				sync_serv_info, 		[0]}}.

%% 清理ets
{clear_ets,                     3600,               {ets_api,                   gc,                     []}}.
