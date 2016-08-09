ALTER TABLE `game_mail`
ADD COLUMN `bcash2` int(10) NULL DEFAULT 0   COMMENT '绑定元宝'
AFTER `content1`