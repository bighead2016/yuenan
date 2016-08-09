/*
Navicat MySQL Data Transfer

Source Server         : hyj
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 65001

Date: 2014-01-03 11:07:14
*/

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

-- ----------------------------
-- Records of game_cross_arena_group_report
-- ----------------------------
