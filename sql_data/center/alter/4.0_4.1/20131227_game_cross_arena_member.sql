/*
Navicat MySQL Data Transfer

Source Server         : hyj
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 65001

Date: 2014-01-03 11:07:37
*/

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

-- ----------------------------
-- Records of game_cross_arena_member
-- ----------------------------
