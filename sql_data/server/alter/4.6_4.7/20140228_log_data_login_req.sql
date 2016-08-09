CREATE TABLE `log_data_login_req` (
  `acc_id` int(20) NOT NULL COMMENT '平台id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `serv_id` int(4) NOT NULL COMMENT '服务器号',
  `fcm` int(4) NOT NULL COMMENT '防沉迷',
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `exist` int(4) NOT NULL COMMENT '存在',
  `state` int(4) NOT NULL COMMENT '状态',
  `game_time` int(20) NOT NULL COMMENT '游戏时间',
  `logout_time_last` int(20) NOT NULL COMMENT '最后登出时间',
  `sing` longtext NOT NULL COMMENT '验证码',
  `debug` char(20) NOT NULL COMMENT '调试模式',
  `link_time` int(20) NOT NULL COMMENT 'php传过来的时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
