alter table game_cross_arena_member add column `fail_times` int(11) NOT NULL DEFAULT '0' COMMENT 'ʧ�ܴ���' AFTER `win_times`;
alter table game_cross_arena_member add column `player_data` longblob NOT NULL COMMENT '��������������' AFTER `cross_state`;
alter table game_cross_arena_member add column `update_time` int(11) NOT NULL DEFAULT '0' COMMENT '�����������ʱ��' AFTER `player_data`;