CREATE TABLE `game_mixed_serv_activity` (
  `userid` bigint(32) NOT NULL COMMENT '玩家ID',
  `type` int(2) NOT NULL COMMENT '类型',
  `value` int(11) NOT NULL COMMENT '值',
  `state` bigint(32) NOT NULL COMMENT '状态',
  `time` bigint(32) NOT NULL COMMENT '记录时间',
  `endtime` bigint(32) NOT NULL COMMENT '结算时间',
  PRIMARY KEY (`userid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;