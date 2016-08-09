/*
Navicat MySQL Data Transfer

Source Server         : hyj
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 65001

Date: 2014-01-03 11:08:32
*/

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

-- ----------------------------
-- Records of game_cross_arena_robot
-- ----------------------------
