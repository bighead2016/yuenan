/*
Navicat MySQL Data Transfer

Source Server         : wwsg
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : wwsg

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 10008

Date: 2013-12-25 18:47:19
*/

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

-- ----------------------------
-- Records of game_tower_report
-- ----------------------------
