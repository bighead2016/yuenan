CREATE TABLE `game_card_chip` (
  `user_id` INT(11) NOT NULL DEFAULT '0',
  `chip_total` INT(11) DEFAULT '0',
  PRIMARY KEY (`user_id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8