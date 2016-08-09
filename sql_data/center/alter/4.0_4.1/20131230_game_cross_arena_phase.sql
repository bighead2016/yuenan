/*
Navicat MySQL Data Transfer

Source Server         : hyj
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 65001

Date: 2014-01-03 11:07:48
*/

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

-- ----------------------------
-- Records of game_cross_arena_phase
-- ----------------------------
