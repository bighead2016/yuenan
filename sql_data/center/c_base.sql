CREATE TABLE `game_code` (
  `code_type` tinyint(5) NOT NULL COMMENT '激活码类型',
  `code` varchar(255) NOT NULL COMMENT '激活码',
  PRIMARY KEY (`code_type`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
