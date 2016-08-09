CREATE TABLE `game_guild_rank` (
  `guild_id` bigint(32) NOT NULL COMMENT '军团ID',
  `rank` int(4) NOT NULL AUTO_INCREMENT COMMENT '排名',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;