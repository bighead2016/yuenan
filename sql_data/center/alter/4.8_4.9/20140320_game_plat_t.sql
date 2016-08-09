CREATE TABLE `game_plat_t` (
  `plat_id` int(20) NOT NULL,
  `plat` text NOT NULL COMMENT '平台名',
  `login_key` text COMMENT '登录key',
  `center` text COMMENT '中心服ip',
  `fcm_site` text COMMENT '防沉迷地址',
  PRIMARY KEY (`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
