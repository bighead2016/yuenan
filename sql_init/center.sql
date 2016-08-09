CREATE TABLE `game_code` (
  `code_type` tinyint(5) NOT NULL COMMENT '激活码类型',
  `code` varchar(255) NOT NULL COMMENT '激活码',
  PRIMARY KEY (`code_type`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_copy_single_report`
-- ----------------------------
DROP TABLE IF EXISTS `game_copy_single_report`;
CREATE TABLE `game_copy_single_report` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `report` longblob NOT NULL COMMENT '??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_copy_single_report_idx`
-- ----------------------------
DROP TABLE IF EXISTS `game_copy_single_report_idx`;
CREATE TABLE `game_copy_single_report_idx` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `record` longblob NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_tower_report`
-- ----------------------------
DROP TABLE IF EXISTS `game_tower_report`;
CREATE TABLE `game_tower_report` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `report` longblob NOT NULL COMMENT '??',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_tower_report_idx`
-- ----------------------------
DROP TABLE IF EXISTS `game_tower_report_idx`;
CREATE TABLE `game_tower_report_idx` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `record` longblob NOT NULL COMMENT '????',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_cross_arena_member`
-- ----------------------------
DROP TABLE IF EXISTS `game_cross_arena_member`;
CREATE TABLE `game_cross_arena_member` (
  `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '玩家名字',
  `player_sex` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家性别',
  `player_lv` int(11) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `player_career` tinyint(1) NOT NULL DEFAULT '0' COMMENT '职业',
  `last_rank` bigint(20) NOT NULL DEFAULT '0' COMMENT '昨日排名',
  `last_phase` bigint(20) NOT NULL DEFAULT '0' COMMENT '昨日段',
  `last_group` int(11) NOT NULL DEFAULT '0' COMMENT '昨日分组',
  `rank` bigint(20) NOT NULL DEFAULT '0' COMMENT '排名',
  `phase` bigint(20) NOT NULL DEFAULT '0' COMMENT '段',
  `group` int(11) NOT NULL DEFAULT '0' COMMENT '组',
  `times` int(11) NOT NULL DEFAULT '0' COMMENT '今日剩余挑战次数',
  `last_win_times` int(11) NOT NULL DEFAULT '0' COMMENT '昨日胜利次数',
  `win_times` int(11) NOT NULL DEFAULT '0' COMMENT '今日胜利次数',
  `fight_force` int(11) NOT NULL DEFAULT '0' COMMENT '战力',
  `partner_list` varchar(50) NOT NULL DEFAULT '[]' COMMENT '上阵武将列表',
  `open_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否打开竞技场界面',
  `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '在线标志',
  `plat_form` varchar(50) NOT NULL DEFAULT '' COMMENT '平台名',
  `sn` int(11) NOT NULL DEFAULT '0' COMMENT '服务器编号',
  `node` varchar(50) NOT NULL DEFAULT '' COMMENT '节点名',
  `achieve` blob NOT NULL COMMENT '成就',
  `score` int(11) NOT NULL DEFAULT '0' COMMENT '积分',
  `fight_list` varchar(50) NOT NULL DEFAULT '' COMMENT '已挑战过列表',
  `cross_state` int(11) NOT NULL DEFAULT '0' COMMENT '跨服状态',
  PRIMARY KEY (`player_id`),
  KEY `player_id` (`player_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场信息';

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_cross_arena_phase`
-- ----------------------------
DROP TABLE IF EXISTS `game_cross_arena_phase`;
CREATE TABLE `game_cross_arena_phase` (
  `phase` int(11) NOT NULL DEFAULT '0' COMMENT '段id',
  `group_list` blob NOT NULL COMMENT '段的组信息',
  PRIMARY KEY (`phase`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_cross_arena_group_report`
-- ----------------------------
DROP TABLE IF EXISTS `game_cross_arena_group_report`;
CREATE TABLE `game_cross_arena_group_report` (
  `phase_group` varchar(50) NOT NULL DEFAULT '' COMMENT '段组',
  `report_list` blob NOT NULL COMMENT '战报id列表',
  PRIMARY KEY (`phase_group`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_cross_arena_report`
-- ----------------------------
DROP TABLE IF EXISTS `game_cross_arena_report`;
CREATE TABLE `game_cross_arena_report` (
  `id` varchar(50) NOT NULL COMMENT '战报ID(唯一)',
  `result` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1胜利2失败',
  `time` int(11) NOT NULL DEFAULT '0' COMMENT '战报存放时间',
  `attack_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `attack_name` varchar(50) NOT NULL DEFAULT '' COMMENT '攻击方名字',
  `deffender_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '防御方ID',
  `deffender_name` varchar(50) NOT NULL DEFAULT '' COMMENT '防御方名字',
  `bin_report` longblob NOT NULL COMMENT '战报',
  PRIMARY KEY (`id`),
  KEY `player_id` (`attack_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场战报';

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_cross_arena_robot`
-- ----------------------------
DROP TABLE IF EXISTS `game_cross_arena_robot`;
CREATE TABLE `game_cross_arena_robot` (
  `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `fight_list` varchar(50) NOT NULL DEFAULT '' COMMENT '已挑战列表',
  PRIMARY KEY (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for `game_serv_info`
-- ----------------------------
DROP TABLE IF EXISTS `game_serv_info`;
CREATE TABLE `game_serv_info` (
  `sid` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`sid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Records of game_serv_info
-- ----------------------------
INSERT INTO `game_serv_info` VALUES ('1', 0x789C6BCE604D61E04D2D298E2F4E2D2A8BCFCC4BCB4F644C6190284ECC4B2FCD8F37363328B58C3774303432D7330042C34486A4A0D3FB5F0000EEE311F5);
INSERT INTO `game_serv_info` VALUES ('2', 0x789C6BCE604D61E04D2D298E2F4E2D2A8BCFCC4BCB4F644A6190284ECC4B2FCD8F37363328B58C3772303432D7330042C344E6A4A0D37B2A00EEB41187);

alter table game_cross_arena_member add column `fail_times` int(11) NOT NULL DEFAULT '0' COMMENT 'Ê§°Ü´ÎÊý' AFTER `win_times`;
alter table game_cross_arena_member add column `player_data` longblob NOT NULL COMMENT '¿ç·þ¾º¼¼Íæ¼ÒÊý¾Ý' AFTER `cross_state`;
alter table game_cross_arena_member add column `update_time` int(11) NOT NULL DEFAULT '0' COMMENT '¸üÐÂÍæ¼ÒÊý¾ÝÊ±¼ä' AFTER `player_data`;

alter table game_cross_arena_member modify column partner_list varchar(200) NOT NULL DEFAULT '';
alter table game_cross_arena_member modify column fight_list varchar(200) NOT NULL DEFAULT '';

alter table game_cross_arena_robot modify column fight_list varchar(200) NOT NULL DEFAULT '';

CREATE TABLE if not exists `game_old_server_user` (
  `user_id` bigint(20) NOT NULL COMMENT 'Íæ¼Òid',
  `account` char(64) NOT NULL COMMENT 'ÕÊºÅ',
  `serv_id` int(5) NOT NULL COMMENT '·þÎñÆ÷ºÅ',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_gun_cash` (
  `account` CHAR(64) NOT NULL,
  `cash_total` INT(11) DEFAULT '0',
  `cash_today` INT(11) DEFAULT '0',
  `add_index` INT(11) DEFAULT '1',
  `get_times` INT(11) DEFAULT '0' COMMENT '领取次数，其实最多领取一次',
  `add_node` CHAR(128) DEFAULT NULL,
  `register_time` INT(11) DEFAULT '0',
  PRIMARY KEY (`account`)
) ENGINE=MYISAM DEFAULT CHARSET=utf8;

alter table game_cross_arena_member add column `player_data2` longblob NOT NULL COMMENT '¿ç·þ¾º¼¼Íæ¼ÒÊý¾Ý2' AFTER `player_data`;
alter table game_cross_arena_member add column `player_data3` longblob NOT NULL COMMENT '¿ç·þ¾º¼¼Íæ¼ÒÊý¾Ý3' AFTER `player_data2`;

truncate `game_tower_report`;
truncate `game_tower_report_idx`;
truncate `game_copy_single_report`;
truncate `game_copy_single_report_idx`;

CREATE TABLE `game_plat_t` (
  `plat_id` int(20) NOT NULL,
  `plat` text NOT NULL COMMENT '平台名',
  `login_key` text COMMENT '登录key',
  `center` text COMMENT '中心服ip',
  `fcm_site` text COMMENT '防沉迷地址',
  PRIMARY KEY (`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_server_t` (
  `sid` int(20) NOT NULL,
  `plat_id` int(20) NOT NULL,
  `ip_telcom` text NOT NULL,
  `combine` blob NOT NULL,
  `node` blob NOT NULL COMMENT '结点名',
  PRIMARY KEY (`sid`,`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;