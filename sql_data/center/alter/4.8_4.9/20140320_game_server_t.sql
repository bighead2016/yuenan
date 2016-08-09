CREATE TABLE `game_server_t` (
  `sid` int(20) NOT NULL,
  `plat_id` int(20) NOT NULL,
  `ip_telcom` text NOT NULL,
  `combine` blob NOT NULL,
  `node` blob NOT NULL COMMENT '结点名',
  PRIMARY KEY (`sid`,`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
