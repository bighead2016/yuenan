
CREATE TABLE `game_teach` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `teach` longblob NOT NULL COMMENT '教学信息',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家教学信息表';

truncate game_encroach_info;
