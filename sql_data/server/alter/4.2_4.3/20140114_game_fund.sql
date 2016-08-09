CREATE TABLE `game_fund` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `fund` bigint(20) NOT NULL COMMENT '基金信息',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家基金信息表';