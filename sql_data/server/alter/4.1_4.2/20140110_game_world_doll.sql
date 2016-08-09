alter table `game_world_doll` add column `cash_today` int(11) NOT NULL COMMENT '今天元宝';
alter table `game_world_doll` add column `bcash_2_today` int(11) NOT NULL COMMENT '今天绑定元宝';
alter table `game_world_doll` add column `cash_tomorrow` int(11) NOT NULL COMMENT '明天元宝';
alter table `game_world_doll` add column `bcash_2_tomorrow` int(11) NOT NULL COMMENT '明天绑定元宝';
update `game_world_doll` set `cash_today` = `today` * 50, `bcash_2_today` = 0, `cash_tomorrow` = `tomorrow` * 50, `bcash_2_tomorrow` = 0;