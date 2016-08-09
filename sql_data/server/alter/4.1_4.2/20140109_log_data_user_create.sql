DROP TABLE IF EXISTS `log_data_user_create`;
CREATE TABLE `log_data_user_create` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `pro` int(4) NOT NULL COMMENT '职业',
  `country` int(4) NOT NULL COMMENT '国家',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;