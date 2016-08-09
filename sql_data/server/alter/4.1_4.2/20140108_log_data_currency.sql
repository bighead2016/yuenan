drop table if exists `log_data_currency`;
CREATE TABLE `log_data_currency` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(5) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `is_first` int(4) NOT NULL COMMENT '首次消费',
  `money_type` int(4) NOT NULL COMMENT '货币类型',
  `value` int(11) NOT NULL COMMENT '变化值',
  `value_new` int(11) NOT NULL COMMENT '新值',
  `type` int(4) NOT NULL COMMENT '类型',
  `point` int(11) NOT NULL COMMENT '消费点',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
