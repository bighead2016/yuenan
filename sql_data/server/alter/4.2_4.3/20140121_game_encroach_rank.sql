SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `game_encroach_rank` (
  `rank_id` int(11) NOT NULL,
  `data` blob NOT NULL,
  `update_time` int(11) NOT NULL,
  PRIMARY KEY (`rank_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
