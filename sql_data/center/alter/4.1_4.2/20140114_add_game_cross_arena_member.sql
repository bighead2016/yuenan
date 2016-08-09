alter table game_cross_arena_member add column `fail_times` int(11) NOT NULL DEFAULT '0' COMMENT '失败次数' AFTER `win_times`;
alter table game_cross_arena_member add column `player_data` longblob NOT NULL COMMENT '跨服竞技玩家数据' AFTER `cross_state`;
alter table game_cross_arena_member add column `update_time` int(11) NOT NULL DEFAULT '0' COMMENT '更新玩家数据时间' AFTER `player_data`;