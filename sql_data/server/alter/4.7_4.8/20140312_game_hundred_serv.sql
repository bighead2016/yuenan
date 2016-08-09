CREATE TABLE `game_hundred_serv`(
`user_id` int(11) COMMENT '玩家ID',
`act_id` int(11) COMMENT '活动ID',
`point` int(11) COMMENT '玩家数据',
PRIMARY KEY (`user_id`,`act_id`)
)