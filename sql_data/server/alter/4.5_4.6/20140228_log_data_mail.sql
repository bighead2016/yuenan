alter table log_data_mail add column `bcash` int(11) NOT NULL COMMENT '礼券' after `point`;
alter table log_data_mail add column `bcash_2` int(11) NOT NULL COMMENT '绑定元宝' after `bcash`;
