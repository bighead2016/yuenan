CREATE TABLE `game_act_user`(
`user_id` int(11) COMMENT '玩家ID',
`act_id` int(11) COMMENT '活动ID',
`data` longblob COMMENT '玩家数据',
PRIMARY KEY (`user_id`,`act_id`)
)