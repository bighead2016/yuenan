-define(LOGIN_PACKET_LIST, 
        [
            player_api,				%% 玩家
			player_vip_api,			%% 玩家VIP信息
			horse_api,				%% 坐骑
            map_api,				%% 地图
            ctn_bag2_api,			%% 背包
            ctn_depot_api,
            ctn_equip_api,			%% 装备
%%             lottery_api,			%% 宝箱仓库先不开放
%%             group_api,
            guide_api,
			guild_api,				%% 军团
            camp_api,
            copy_single_api,		%% 单人副本
            partner_api,
 			home_api,				%% 家园
			skill_api,				%% 技能
            furnace_api,
			welfare_api,			%% 福利
			resource_api,
			schedule_api,
            active_api,
			relation_api,			%% 好友
			bless_api,				%% 祝福
			practice_api,			%% 修炼
			boss_api,
			world_api,
            camp_pvp_api,
            task_api,				%% 任务
			tower_api,				%% 闯塔
            battle_skip_api,        %% 战斗
            new_serv_turn_api,      %% 转盘
            mind_api,               %% 心法
            welfare_fund_api,        %% 基金
			act_bhv,				%% 运营活动
			mail_api,       		%% 邮件  NOTICE : 如果前面调用了邮件接口，请把mail_api放最后
			furnace_chest_api,		%% 装备衣柜
            guild_pvp_api
			, hundred_serv_api%百服活动
			, gamble_api %青梅煮酒
                  , yunying_activity_api
        ]).