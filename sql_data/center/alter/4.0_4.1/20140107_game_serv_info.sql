/*
Navicat MySQL Data Transfer

Source Server         : wwsg
Source Server Version : 50522
Source Host           : localhost:3306
Source Database       : center

Target Server Type    : MYSQL
Target Server Version : 50522
File Encoding         : 10008

Date: 2014-01-07 16:54:16
*/

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
