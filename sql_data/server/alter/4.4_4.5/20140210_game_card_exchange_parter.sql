ALTER TABLE `game_card_exchange_partner`
ADD COLUMN `freetimes` int(3)  NULL DEFAULT 0   COMMENT '白银宝箱免费次数'
AFTER `time_e`