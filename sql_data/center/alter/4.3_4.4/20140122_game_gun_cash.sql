CREATE TABLE `game_gun_cash` (
  `account` CHAR(64) NOT NULL,
  `cash_total` INT(11) DEFAULT '0',
  `cash_today` INT(11) DEFAULT '0',
  `add_index` INT(11) DEFAULT '1',
  `get_times` INT(11) DEFAULT '0' COMMENT '领取次数，其实最多领取一次',
  `add_node` CHAR(128) DEFAULT NULL,
  `register_time` INT(11) DEFAULT '0',
  PRIMARY KEY (`account`)
) ENGINE=MYISAM DEFAULT CHARSET=utf8