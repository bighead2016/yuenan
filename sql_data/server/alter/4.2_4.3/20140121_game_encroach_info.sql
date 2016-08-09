SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `game_encroach_info`;
CREATE TABLE `game_encroach_info` (
  `user_id` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
