CREATE TABLE `log_data_sig_arena` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `old_rank` int(11) NOT NULL COMMENT '旧排名',
  `new_rank` int(11) NOT NULL COMMENT '新排名',
  `new_wins` int(4) NOT NULL COMMENT '新连胜次数',
  `ack_user_id` int(11) NOT NULL COMMENT '攻击方玩家id',
  `is_active` int(4) NOT NULL COMMENT '主动',
  `new_times` int(4) NOT NULL COMMENT '新剩余次数',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

