CREATE TABLE `game_gamble_player`(
`user_id` int(11) PRIMARY KEY,
`chips` int(11) COMMENT '筹码 ',
`timestamp` int(11),
`times` int(5)
)DEFAULT CHARSET=utf8;