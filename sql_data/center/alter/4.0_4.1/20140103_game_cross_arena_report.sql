/*
Navicat MySQL Data Transfer

Source Server         : hyj
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 65001

Date: 2014-01-03 11:08:14
*/

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

-- ----------------------------
-- Records of game_cross_arena_report
-- ----------------------------
