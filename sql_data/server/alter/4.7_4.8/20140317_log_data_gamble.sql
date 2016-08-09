ALTER TABLE `log_data_gamble`
ADD COLUMN `platform1` int(4) NOT NULL  COMMENT '玩家平台ID' AFTER `user_sid`;
ALTER TABLE `log_data_gamble`
ADD COLUMN `platform2` int(4) NOT NULL  COMMENT '对手玩家平台ID' AFTER `user_sid1`;