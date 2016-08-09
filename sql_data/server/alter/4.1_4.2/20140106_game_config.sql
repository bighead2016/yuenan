alter table `game_config` add column `version` char(255) NOT NULL COMMENT '版本' after `combine_reward` ;
INSERT INTO `game_config` VALUES ('0', '4.0');