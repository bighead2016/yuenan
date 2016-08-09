DROP TABLE IF EXISTS `game_archery_info`;
CREATE TABLE `game_archery_info` (
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `power` int(11) DEFAULT NULL COMMENT '拉力',
  `angle` int(11) DEFAULT NULL COMMENT '角度',
  `arrow` int(11) DEFAULT NULL COMMENT '箭矢',
  `accGet` int(16)             COMMENT '累计奖励',
  `done` int(11) DEFAULT NULL COMMENT '当天通关靶场',
  `courtInfo` longblob COMMENT '靶场信息',
  `point` int(11) DEFAULT NULL COMMENT '今日积分',
  `time` int(11) DEFAULT NULL COMMENT '时间戳',
   PRIMARY KEY (`user_id`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;