CREATE TABLE if not exists `game_old_server_user` (
  `user_id` bigint(20) NOT NULL COMMENT 'Íæ¼Òid',
  `account` char(64) NOT NULL COMMENT 'ÕÊºÅ',
  `serv_id` int(5) NOT NULL COMMENT '·þÎñÆ÷ºÅ',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
