CREATE TABLE if not exists `game_old_server_user` (
  `user_id` bigint(20) NOT NULL COMMENT '���id',
  `account` char(64) NOT NULL COMMENT '�ʺ�',
  `serv_id` int(5) NOT NULL COMMENT '��������',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
