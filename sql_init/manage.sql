CREATE TABLE `game_plat_t` (
  `plat_id` int(20) NOT NULL,
  `plat` text NOT NULL COMMENT '平台名',
  `login_key` text COMMENT '登录key',
  `center` text COMMENT '中心服ip',
  `fcm_site` text COMMENT '防沉迷地址',
  PRIMARY KEY (`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_server_t` (
  `sid` int(20) NOT NULL,
  `plat_id` int(20) NOT NULL,
  `ip_telcom` text NOT NULL,
  `combine` blob NOT NULL,
  PRIMARY KEY (`sid`,`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter TABLE `game_server_t` add column `node` blob NOT NULL COMMENT '结点名' after `combine`;