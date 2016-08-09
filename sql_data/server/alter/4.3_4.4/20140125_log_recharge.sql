
CREATE TABLE `log_recharge` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(5) NOT NULL COMMENT '等级',
  `country` int(5) NOT NULL COMMENT '国家',
  `pro` int(5) NOT NULL COMMENT '职业',
  `a` int(5) NOT NULL,
  `b` int(5) NOT NULL,
  `methord` int(5) NOT NULL COMMENT '途径',
  `money` int(11) NOT NULL COMMENT '充值',
  `cash` int(11) NOT NULL COMMENT '元宝',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
