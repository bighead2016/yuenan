alter table `game_user` MODIFY column `exist` tinyint(5) NOT NULL DEFAULT '0' COMMENT '0无角色 1有角色';
alter table `game_user` MODIFY column `state` tinyint(5) NOT NULL DEFAULT '1' COMMENT '玩家状态--0禁止登录 1正常 2指导员 3GM';
alter table `game_user` MODIFY column `fcm` tinyint(5) NOT NULL DEFAULT '2' COMMENT '防沉迷状态--0登记、未成年 1登记、成年 2未登记';
alter table `game_user` add column  `cash_bind_2` int(10) NOT NULL DEFAULT '0' COMMENT '绑定元宝' after `cash_bind`;
alter table `game_user` add column  `cash_bind_3` int(10) NOT NULL DEFAULT '0' COMMENT '保留字段' after `cash_bind_2`;

CREATE TABLE `config_version` (
  `table` char(255) NOT NULL COMMENT '表名',
  `time` int(11) NOT NULL COMMENT '时间',
  PRIMARY KEY (`table`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;DROP TABLE IF EXISTS `game_active_welfare`;
CREATE TABLE `game_active_welfare` (
  `user_id` bigint(32) NOT NULL COMMENT '玩家id',
  `type` bigint(32) NOT NULL COMMENT '类型',
  `gift_got` longblob NOT NULL COMMENT '',
  `data` bigint(32) NOT NULL COMMENT '',
  `time_s` bigint(32) NOT NULL COMMENT '',
  `time_e` bigint(32) NOT NULL COMMENT '',
  PRIMARY KEY (`user_id`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

insert into `config_version` values ('../sql_data/server/base.sql', '0');

drop table if exists `db_table_version`;

alter table `game_group_apply` MODIFY column `type` smallint(5) NOT NULL COMMENT '申请类型 1:player->group 2:group->player';
