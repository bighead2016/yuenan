SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `game_shop_secret` (
  `id` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
