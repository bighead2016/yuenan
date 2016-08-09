CREATE TABLE `log_data_guild` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `time` int(11) NOT NULL COMMENT '时间',
  `guild_id` int(11) NOT NULL COMMENT '军团id',
  `operate` int(4) NOT NULL COMMENT '操作类型',
  `other_id` int(11) NOT NULL COMMENT '其他对象id',
  `goods_id` int(11) NOT NULL COMMENT '物品id',
  `num` int(4) NOT NULL COMMENT '数量',
  `skill_type` int(4) NOT NULL COMMENT '技能类型',
  `skill_lv` int(4) NOT NULL COMMENT '技能等级',
  `cost` int(11) NOT NULL COMMENT '花费'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

