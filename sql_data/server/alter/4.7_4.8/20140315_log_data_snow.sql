CREATE TABLE `log_data_snow` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `point` int(7) NOT NULL COMMENT '积分',
  `state` int(1) NOT NULL COMMENT '动作(1,充值；2,点灯)',
  `time` int(20) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
