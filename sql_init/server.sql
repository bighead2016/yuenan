
SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `config_version`;
CREATE TABLE `config_version` (
  `table` char(255) NOT NULL COMMENT '表名',
  `time` int(11) NOT NULL COMMENT '时间',
  PRIMARY KEY (`table`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;DROP TABLE IF EXISTS `game_active_welfare`;
CREATE TABLE `game_active_welfare` (
  `user_id` bigint(32) NOT NULL COMMENT '����˺�',
  `type` bigint(32) NOT NULL COMMENT '�����',
  `gift_got` longblob NOT NULL COMMENT '�Ѵ��Ŀ��id�б�',
  `data` bigint(32) NOT NULL COMMENT '����',
  `time_s` bigint(32) NOT NULL COMMENT '����',
  `time_e` bigint(32) NOT NULL COMMENT '����',
  PRIMARY KEY (`user_id`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_activity_record`;
CREATE TABLE `game_activity_record` (
  `activity_id` int(11) NOT NULL DEFAULT '0' COMMENT '�id',
  `record` blob COMMENT '���¼',
  PRIMARY KEY (`activity_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_activity_stone_compose`;
CREATE TABLE `game_activity_stone_compose` (
  `user_id` int(10) NOT NULL COMMENT '���id',
  `stone_compose_list` longblob NOT NULL COMMENT '��ʯ�ϳ��б�',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_arena_champion_report`;
CREATE TABLE `game_arena_champion_report` (
  `report_id` varchar(50) NOT NULL COMMENT '战报ID',
  `user_id` int(11) NOT NULL COMMENT '挑战方ID',
  `user_name` varchar(50) NOT NULL COMMENT '挑战方名字',
  `opp_id` int(11) NOT NULL COMMENT '被挑战方ID',
  `opp_name` varchar(50) NOT NULL COMMENT '被挑战方名字',
  `time` int(11) NOT NULL COMMENT '战报时间',
  `bin_report` longblob NOT NULL COMMENT '战报内容',
  PRIMARY KEY (`report_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='历任榜首战报';



DROP TABLE IF EXISTS `game_arena_member`;
CREATE TABLE `game_arena_member` (
  `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '玩家名字',
  `player_sex` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家性别',
  `player_lv` int(11) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `player_career` tinyint(1) NOT NULL DEFAULT '0' COMMENT '职业',
  `rank` bigint(20) NOT NULL DEFAULT '0' COMMENT '名排',
  `times` int(11) NOT NULL DEFAULT '0' COMMENT '今日剩余挑战次数',
  `winning_streak` int(11) NOT NULL DEFAULT '0' COMMENT '胜连次数',
  `cd` int(11) NOT NULL DEFAULT '0' COMMENT '冷却时间',
  `fight_force` int(11) NOT NULL DEFAULT '0' COMMENT '战力',
  `open_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否打开竞技场界面',
  `daily_buy_time` int(11) NOT NULL DEFAULT '0' COMMENT '每天购买次数',
  `clean_times_time` int(11) NOT NULL DEFAULT '0' COMMENT '清空剩余次数和每天购买次数的时间',
  `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '在线标志',
  `sn` int(11) NOT NULL DEFAULT '0' COMMENT '服务器编号',
  `streak_wining_reward` varchar(200) NOT NULL DEFAULT '[]' COMMENT '已经领过的连胜奖励',
  `daily_max_win` int(11) NOT NULL DEFAULT '0' COMMENT '当日最大连胜次数',
  `max_win` int(11) NOT NULL COMMENT '历史最大连胜',
  `meritorious` int(11) NOT NULL,
  `score` int(11) NOT NULL COMMENT '积分',
  `daily_target` int(11) NOT NULL COMMENT '每日目标',
  `target_state` int(4) NOT NULL COMMENT '每日目标状态',
  PRIMARY KEY (`player_id`),
  KEY `player_id` (`player_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场信息';



DROP TABLE IF EXISTS `game_arena_pvp`;
CREATE TABLE `game_arena_pvp` (
  `user_id` int(10) NOT NULL COMMENT '玩家id',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家姓名',
  `pro` smallint(4) NOT NULL DEFAULT '0' COMMENT '职业',
  `sex` smallint(4) NOT NULL DEFAULT '0' COMMENT '性别',
  `lv` smallint(4) NOT NULL DEFAULT '0' COMMENT '等级',
  `hufu` int(10) NOT NULL DEFAULT '0' COMMENT '虎符',
  `score` int(10) NOT NULL DEFAULT '0' COMMENT '当天积分',
  `score_week` int(10) NOT NULL DEFAULT '0' COMMENT '周积分',
  `time` int(10) NOT NULL DEFAULT '0' COMMENT '参加时间',
  `win` int(10) NOT NULL DEFAULT '0' COMMENT '连胜次数',
  `count` int(10) NOT NULL DEFAULT '0' COMMENT '今天参加次数',
  `position` int(10) NOT NULL COMMENT '����',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='多人竞技场';



DROP TABLE IF EXISTS `game_arena_report`;
CREATE TABLE `game_arena_report` (
  `id` varchar(50) NOT NULL COMMENT '战报ID(唯一)',
  `type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1.挑战 2被挑战',
  `result` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1胜利2失败',
  `time` int(11) NOT NULL DEFAULT '0' COMMENT '战报存放时间',
  `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `deffender_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '防御方ID',
  `deffender_name` varchar(50) NOT NULL DEFAULT '' COMMENT '防御方名字',
  `rank_change_type` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1上升 2下降 3不变',
  `rank` bigint(20) NOT NULL DEFAULT '0' COMMENT '排名',
  `bin_report` longblob NOT NULL COMMENT '战报',
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场战报';



DROP TABLE IF EXISTS `game_arena_reward`;
CREATE TABLE `game_arena_reward` (
  `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `get_date` int(11) NOT NULL DEFAULT '0' COMMENT '领取奖励时间',
  `meritorious` int(11) NOT NULL DEFAULT '0' COMMENT '功勋',
  `experience` int(11) NOT NULL DEFAULT '0' COMMENT '培养值',
  `rank` int(11) NOT NULL DEFAULT '0' COMMENT '排名',
  `goods` blob NOT NULL COMMENT '物品列表',
  `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '在线标志',
  `sn` int(11) NOT NULL DEFAULT '0' COMMENT '服务器编号',
  `settlement_date` int(11) NOT NULL DEFAULT '0' COMMENT '计算时间',
  `score` int(11) NOT NULL COMMENT '积分',
  PRIMARY KEY (`player_id`),
  KEY `player_id` (`player_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场奖励';



DROP TABLE IF EXISTS `game_bless_user`;
CREATE TABLE `game_bless_user` (
  `user_id` int(10) NOT NULL,
  `exp` int(10) NOT NULL,
  `count` int(10) NOT NULL,
  `flag` int(10) NOT NULL,
  `time` int(10) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_boss`;
CREATE TABLE `game_boss` (
  `lv` int(10) NOT NULL,
  PRIMARY KEY (`lv`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_camp_data`;
CREATE TABLE `game_camp_data` (
  `userid` int(11) NOT NULL DEFAULT '0',
  `nth` int(11) DEFAULT '0',
  PRIMARY KEY (`userid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_caravan`;
CREATE TABLE `game_caravan` (
  `id` bigint(10) NOT NULL AUTO_INCREMENT COMMENT '商队ID',
  `name` varchar(60) NOT NULL COMMENT '商队名称',
  `quality` tinyint(1) NOT NULL COMMENT '商队品质',
  `user_id` bigint(10) NOT NULL COMMENT '玩家ID',
  `user_name` varchar(64) NOT NULL COMMENT '玩家昵称',
  `pro` tinyint(5) NOT NULL COMMENT '玩家职业',
  `sex` tinyint(5) NOT NULL COMMENT '玩家性别',
  `lv` smallint(5) NOT NULL COMMENT '玩家等级',
  `guild_id` bigint(10) NOT NULL COMMENT '玩家帮派ID',
  `guild_name` varchar(64) NOT NULL COMMENT '玩家帮派名称',
  `friend_id` bigint(10) NOT NULL COMMENT '好友ID',
  `friend_name` varchar(64) NOT NULL COMMENT '好友名字',
  `start_time` bigint(20) NOT NULL COMMENT '开始时间',
  `end_time` bigint(20) NOT NULL COMMENT '结束时间',
  `battling` tinyint(1) NOT NULL COMMENT '战斗状态',
  `failure` int(8) NOT NULL COMMENT '拦截失败次数',
  `robber` blob NOT NULL COMMENT '拦截记录',
  `market` tinyint(1) NOT NULL DEFAULT '1' COMMENT '建造市场加成',
  `guild` tinyint(1) NOT NULL DEFAULT '1' COMMENT '军团活动加成',
  `factor` smallint(3) NOT NULL DEFAULT '30' COMMENT '品质系数',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商路信息';



DROP TABLE IF EXISTS `game_card_exchange_partner`;
CREATE TABLE `game_card_exchange_partner` (
  `user_id` bigint(32) NOT NULL COMMENT '����˺�',
  `cards` longblob NOT NULL COMMENT '�ѳ鵽�Ŀ�Ƭ��Ϣ',
  `points` bigint(32) NOT NULL COMMENT '����',
  `last_lottery` longblob NOT NULL COMMENT '���һ�γ鵽�Ŀ�Ƭ��Ϣ',
  `time_s` bigint(32) NOT NULL COMMENT '�����ʱ��',
  `time_e` bigint(32) NOT NULL COMMENT '�����ʱ��',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_cash_old`;
CREATE TABLE `game_cash_old` (
  `cash` int(11) DEFAULT NULL,
  `acount` char(64) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_change_name`;
CREATE TABLE `game_change_name` (
  `user_id` int(20) NOT NULL,
  `is_changed` int(1) NOT NULL COMMENT '0可改,1已改',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_change_name_guild`;
CREATE TABLE `game_change_name_guild` (
  `guild_id` int(20) NOT NULL,
  `is_changed` int(1) NOT NULL COMMENT '0可改,1已改',
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_cluster_node_config`;
CREATE TABLE `game_cluster_node_config` (
  `node_name` varchar(512) DEFAULT NULL,
  `node_index` int(11) NOT NULL,
  `update_time` int(11) DEFAULT NULL,
  PRIMARY KEY (`node_index`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_code`;
CREATE TABLE `game_code` (
  `code_type` tinyint(5) NOT NULL COMMENT '激活码类型',
  `code` varchar(255) NOT NULL COMMENT '激活码',
  PRIMARY KEY (`code_type`,`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_commerce`;
CREATE TABLE `game_commerce` (
  `user_id` bigint(10) unsigned NOT NULL COMMENT '玩家ID',
  `date` bigint(10) unsigned NOT NULL DEFAULT '0' COMMENT '日期',
  `carry` tinyint(1) NOT NULL DEFAULT '0' COMMENT '运送次数',
  `escort` tinyint(1) NOT NULL DEFAULT '0' COMMENT '好友护送次数',
  `rob` tinyint(1) NOT NULL DEFAULT '0' COMMENT '抢劫次数',
  `vip_rob` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'VIP抢劫次数',
  `freerefresh` tinyint(1) NOT NULL DEFAULT '0' COMMENT '免费刷新品质次数',
  `refresh` tinyint(4) NOT NULL DEFAULT '0' COMMENT '刷新品质次数（每次运送重置为0）',
  `quality` tinyint(1) NOT NULL COMMENT '商队品质',
  `carry_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家运送状态: 0-空闲, 1-等待好友回复, 2-收到好友回复(好友同意), 3-运镖中',
  `carry_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家运送状态过期时间',
  `escort_status` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家护送状态: 0-空闲, 1-到收好友请求, 2-已回复好友(同意), 3-护镖中',
  `escort_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家护送状态过期时间',
  `rob_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '拦截冷却时间',
  `flag_invite` smallint(4) NOT NULL DEFAULT '0' COMMENT '忽略邀请标志',
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家商路信息';



DROP TABLE IF EXISTS `game_commerce_market`;
CREATE TABLE `game_commerce_market` (
  `id` bigint(10) NOT NULL AUTO_INCREMENT COMMENT '自增ID',
  `user_id` bigint(10) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `user_name` varchar(64) NOT NULL DEFAULT '' COMMENT '玩家昵称',
  `start_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '开始时间',
  `end_time` bigint(20) NOT NULL DEFAULT '0' COMMENT '结束时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='商路市场';



DROP TABLE IF EXISTS `game_config`;
CREATE TABLE `game_config` (
  `combine_reward` int(2) NOT NULL DEFAULT '0' COMMENT '�Ϸ�����:0δ��,1����'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_copy_single_report`;
CREATE TABLE `game_copy_single_report` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `report` longblob NOT NULL COMMENT '战报',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_copy_single_report_idx`;
CREATE TABLE `game_copy_single_report_idx` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `record` longblob NOT NULL COMMENT '战报索引',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_group`;
CREATE TABLE `game_group` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `name` char(64) NOT NULL COMMENT '队伍名=队长名',
  `lv` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '队伍等级=队长等级',
  `online_num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '在线人数',
  `in_group_num` smallint(5) unsigned NOT NULL DEFAULT '0' COMMENT '队中已加人数',
  `leader_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '队长id',
  `country` smallint(1) unsigned NOT NULL DEFAULT '0' COMMENT '队伍国家=队长国家',
  `guild_id` int(10) unsigned NOT NULL DEFAULT '0' COMMENT '队伍军团=队长军团',
  `guild_name` char(64) NOT NULL COMMENT '帮派名',
  `member_list` blob NOT NULL COMMENT '成员列表',
  `online_member_list` blob NOT NULL COMMENT '在线成员列表',
  `limit` smallint(1) NOT NULL COMMENT '1无限制 2所在国家 3所在军团',
  `apply_mount` smallint(1) NOT NULL DEFAULT '0' COMMENT '申请总数',
  `pro_list` blob NOT NULL COMMENT '队伍中人员的职业',
  PRIMARY KEY (`id`),
  KEY `guild_id` (`guild_id`),
  KEY `leader_id` (`leader_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=COMPACT;



DROP TABLE IF EXISTS `game_group_apply`;
CREATE TABLE `game_group_apply` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint(20) NOT NULL COMMENT '申请人id',
  `lv` smallint(4) NOT NULL DEFAULT '0' COMMENT '等级',
  `pro` smallint(4) NOT NULL COMMENT '职业',
  `type` smallint(5) NOT NULL COMMENT '申请类型 1:player->group 2:group->player',
  `group_id` bigint(20) unsigned NOT NULL DEFAULT '0' COMMENT '申请队伍ID',
  `state` tinyint(1) NOT NULL COMMENT '玩家状态：0无状态2已在对伍3申请成功4申请失败',
  PRIMARY KEY (`id`),
  KEY `index_guild_apply_guild_id` (`group_id`),
  KEY `id` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 CHECKSUM=1 DELAY_KEY_WRITE=1 ROW_FORMAT=DYNAMIC COMMENT='氏族申请';



DROP TABLE IF EXISTS `game_guild`;
CREATE TABLE `game_guild` (
  `guild_id` int(10) NOT NULL AUTO_INCREMENT,
  `guild_name` char(50) NOT NULL,
  `country` smallint(4) NOT NULL,
  `lv` smallint(4) NOT NULL,
  `exp` int(10) NOT NULL,
  `num` smallint(4) NOT NULL,
  `num_max` smallint(4) NOT NULL,
  `chief_id` int(10) NOT NULL,
  `chief_name` char(50) NOT NULL,
  `create_name` char(50) NOT NULL,
  `create_time` int(10) NOT NULL,
  `bulletin_in` varchar(100) NOT NULL,
  `bulletin_out` varchar(250) NOT NULL,
  `money` int(10) NOT NULL,
  `member_list` longblob NOT NULL,
  `pos_list` longblob NOT NULL,
  `skill` longblob NOT NULL,
  `log` longblob NOT NULL,
  `ctn` longblob NOT NULL,
  `guess_win` longblob NOT NULL,
  `rock_win` longblob NOT NULL,
  `kick_money` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_apply`;
CREATE TABLE `game_guild_apply` (
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `user_name` char(50) NOT NULL DEFAULT '' COMMENT '申请名称',
  `guild_list` longblob NOT NULL COMMENT '申请列表',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='军团申请';



DROP TABLE IF EXISTS `game_guild_member`;
CREATE TABLE `game_guild_member` (
  `user_id` int(10) NOT NULL,
  `user_name` char(50) NOT NULL,
  `guild_id` int(10) NOT NULL,
  `guild_name` char(50) NOT NULL,
  `pos` smallint(4) NOT NULL,
  `power` int(10) NOT NULL,
  `donate_sum` int(10) NOT NULL,
  `donate_today` int(10) NOT NULL,
  `introduce` char(200) NOT NULL,
  `party_flag1` smallint(4) NOT NULL,
  `party_flag2` smallint(4) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_pvp`;
CREATE TABLE `game_guild_pvp` (
  `guild_id` int(11) DEFAULT NULL,
  `guild_score` int(11) DEFAULT NULL,
  `camp_id` int(11) DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_pvp_app`;
CREATE TABLE `game_guild_pvp_app` (
  `guild_id` int(11) NOT NULL DEFAULT '0',
  `is_leader` tinyint(1) DEFAULT NULL,
  `camp_id` int(11) DEFAULT '0',
  `power` int(11) DEFAULT '0',
  `choosed_def` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_pvp_boss_level`;
CREATE TABLE `game_guild_pvp_boss_level` (
  `boss_type` int(11) NOT NULL DEFAULT '0',
  `boss_level` int(11) DEFAULT '0',
  PRIMARY KEY (`boss_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_pvp_log`;
CREATE TABLE `game_guild_pvp_log` (
  `active_end_time` int(11) DEFAULT '0',
  `max_def_count` int(11) DEFAULT '0',
  `max_att_count` int(11) DEFAULT '0',
  `fix_count` int(11) DEFAULT '0',
  `fire_count` int(11) DEFAULT '0',
  `encourage_count` int(11) DEFAULT '0',
  `active_begin_time` int(11) NOT NULL DEFAULT '0',
  `car_killed_time` int(11) DEFAULT '0',
  `wall_killed_time` int(11) DEFAULT '0',
  `boss_killed_time` int(11) DEFAULT '0',
  `active_last_time` int(11) DEFAULT '0',
  PRIMARY KEY (`active_begin_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_guild_time`;
CREATE TABLE `game_guild_time` (
  `user_id` int(10) NOT NULL COMMENT '玩家id',
  `time` int(10) NOT NULL COMMENT '退出时间',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_hero_rank`;
CREATE TABLE `game_hero_rank` (
  `type` smallint(10) NOT NULL DEFAULT '0' COMMENT '1、战力榜；2、军团等级、3、破阵',
  `rank` smallint(10) NOT NULL DEFAULT '0' COMMENT '名次：1、2、3',
  `id` int(10) NOT NULL COMMENT '玩家或军团ID',
  `name` char(64) NOT NULL COMMENT '玩家或军团名称',
  `lv` smallint(10) NOT NULL COMMENT '玩家或军团等级',
  `pro` tinyint(5) NOT NULL COMMENT '玩家职业',
  `sex` tinyint(5) NOT NULL COMMENT '玩家性别'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_home`;
CREATE TABLE `game_home` (
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `lv` int(11) DEFAULT '0' COMMENT '家园等级',
  `update_time` bigint(20) DEFAULT '0' COMMENT '升级开始时间',
  `message` longblob NOT NULL COMMENT '告示牌',
  `farm` longblob NOT NULL COMMENT '农场',
  `task_info` longblob NOT NULL COMMENT '任务信息',
  `girl` longblob NOT NULL COMMENT '仕女苑',
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_honor_title`;
CREATE TABLE `game_honor_title` (
  `honor_id` int(10) NOT NULL DEFAULT '0' COMMENT '荣誉榜标志',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '用户ID',
  `user_name` char(64) NOT NULL DEFAULT '0' COMMENT '玩家名称',
  `lv` smallint(5) NOT NULL DEFAULT '0' COMMENT '玩家等级',
  `sex` smallint(5) NOT NULL DEFAULT '0' COMMENT '玩家性别',
  `pro` smallint(5) NOT NULL DEFAULT '0' COMMENT '玩家职业',
  `weapon` int(10) NOT NULL DEFAULT '0' COMMENT '武器Id',
  `fashion` int(10) NOT NULL DEFAULT '0' COMMENT '时装ID',
  `armor` int(10) NOT NULL COMMENT '衣服ID',
  PRIMARY KEY (`honor_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_horse`;
CREATE TABLE `game_horse` (
  `user_id` int(10) unsigned NOT NULL COMMENT '玩家id',
  `lv` smallint(4) NOT NULL,
  `exp` int(10) NOT NULL,
  `stren_time` int(10) NOT NULL DEFAULT '0',
  `stren_count` int(10) NOT NULL DEFAULT '0',
  `list` blob NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='坐骑';



DROP TABLE IF EXISTS `game_mail`;
CREATE TABLE `game_mail` (
  `mail_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '信件id(自增)',
  `type` tinyint(1) NOT NULL COMMENT '类型（0绑定物品的系统邮件、1系统、2私人）',
  `send_uid` int(10) NOT NULL COMMENT '发件人id',
  `send_name` char(64) NOT NULL COMMENT '发件人名字',
  `send_sex` tinyint(5) NOT NULL DEFAULT '0' COMMENT '发件人性别',
  `recv_uid` int(10) NOT NULL COMMENT '收件人id',
  `recv_name` char(64) NOT NULL COMMENT '收件人昵称',
  `title` char(64) NOT NULL COMMENT '信件标题',
  `time` int(11) NOT NULL COMMENT '发信时间',
  `content` varchar(500) NOT NULL COMMENT '信件正文',
  `cash` int(10) NOT NULL DEFAULT '0' COMMENT '元宝数',
  `gold` int(10) NOT NULL DEFAULT '0' COMMENT '铜钱数',
  `goods` longblob COMMENT '物品',
  `is_read` tinyint(1) NOT NULL COMMENT '是否未读(0未读1已读)',
  `is_save` tinyint(1) NOT NULL COMMENT '是否保存(0未存1已存)',
  `is_pick` tinyint(1) NOT NULL COMMENT '是否提取(0无附件1未提取2已提取)',
  `point` int(10) NOT NULL DEFAULT '0',
  `bcash` int(10) NOT NULL DEFAULT '0',
  `message_id` int(10) NOT NULL DEFAULT '0',
  `content1` blob,
  PRIMARY KEY (`mail_id`),
  KEY `recv_uid` (`recv_uid`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='邮件';



DROP TABLE IF EXISTS `game_market_buy`;
CREATE TABLE `game_market_buy` (
  `buy_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '������¼id',
  `seller_id` int(10) NOT NULL COMMENT '������id',
  `seller_name` char(64) NOT NULL COMMENT '�������ǳ�',
  `buyer_id` int(10) NOT NULL COMMENT '������id',
  `buyer_name` char(64) NOT NULL COMMENT '�������ǳ�',
  `goods` longblob NOT NULL COMMENT '��Ʒ',
  `goods_name` char(64) NOT NULL COMMENT '��Ʒ����',
  `category` tinyint(5) NOT NULL COMMENT '��������',
  `goods_type` tinyint(5) NOT NULL COMMENT '��Ʒ����',
  `goods_sub_type` smallint(5) NOT NULL COMMENT '宝石属性类型',
  `goods_level` tinyint(5) NOT NULL COMMENT '��Ʒ�ȼ�',
  `goods_color` tinyint(1) NOT NULL COMMENT '��Ʒ��ɫ',
  `goods_pro` tinyint(1) NOT NULL COMMENT '��Ʒְҵ����',
  `goods_attr_type` smallint(5) NOT NULL COMMENT '�����б�',
  `current_price` int(10) NOT NULL COMMENT '��ǰ�۸�',
  `fixed_price` int(10) NOT NULL COMMENT 'һ�ڼ۸�',
  `bid_price` int(10) NOT NULL COMMENT '��Ҿ��ĵļ۸�',
  `end_time` int(11) NOT NULL COMMENT '���۵���ʱ��',
  `sale_id` int(10) NOT NULL COMMENT '���ۼ�¼id',
  PRIMARY KEY (`buy_id`),
  KEY `buyer_id` (`buyer_id`) USING BTREE,
  KEY `sale_id` (`sale_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_market_sale`;
CREATE TABLE `game_market_sale` (
  `sale_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '���ۼ�¼id',
  `seller_id` int(10) NOT NULL COMMENT '������id',
  `seller_name` char(64) NOT NULL COMMENT '�������ǳ�',
  `buyer_id` int(10) NOT NULL COMMENT '������id',
  `buyer_name` char(64) NOT NULL COMMENT '�������ǳ�',
  `goods` longblob NOT NULL COMMENT '��Ʒ',
  `goods_name` char(64) NOT NULL COMMENT '��Ʒ����',
  `category` tinyint(5) NOT NULL COMMENT '��������',
  `goods_type` tinyint(5) NOT NULL COMMENT '��Ʒ����',
  `goods_sub_type` tinyint(5) NOT NULL COMMENT '��Ʒ������',
  `goods_level` smallint(5) NOT NULL COMMENT '��Ʒ�ȼ�',
  `goods_color` tinyint(1) NOT NULL COMMENT '��Ʒ��ɫ',
  `goods_pro` tinyint(1) NOT NULL COMMENT '��Ʒְҵ����',
  `goods_attr_type` smallint(5) NOT NULL DEFAULT '0' COMMENT '宝石属性类型',
  `current_price` int(10) NOT NULL COMMENT '��ʼ�۸�',
  `fixed_price` int(10) NOT NULL COMMENT 'һ�ڼ۸�',
  `end_time` int(11) NOT NULL COMMENT '���۵���ʱ��',
  PRIMARY KEY (`sale_id`),
  KEY `seller_id` (`seller_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_market_search`;
CREATE TABLE `game_market_search` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '����id',
  `goods_id` int(10) NOT NULL,
  `goods_name` char(64) NOT NULL DEFAULT '' COMMENT '��Ʒ����',
  `search_times` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `goods_id` (`goods_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_offline`;
CREATE TABLE `game_offline` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增',
  `user_id` int(20) NOT NULL COMMENT '受影响的玩家id',
  `module` char(30) NOT NULL COMMENT '模块名',
  `data` blob NOT NULL COMMENT '要保存的数据',
  `time` int(10) NOT NULL COMMENT '插入时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_offline_err`;
CREATE TABLE `game_offline_err` (
  `id` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '自增',
  `user_id` int(20) NOT NULL COMMENT '受影响的玩家id',
  `module` char(30) NOT NULL COMMENT '模块名',
  `data` blob NOT NULL COMMENT '要保存的数据',
  `time` int(10) NOT NULL COMMENT '插入时间',
  PRIMARY KEY (`id`),
  KEY `user_id` (`user_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_old_server_user`;
CREATE TABLE `game_old_server_user` (
  `user_id` char(64) NOT NULL COMMENT '玩家ID',
  `user_name` char(64) NOT NULL COMMENT '玩家名称',
  `user_lv` smallint(5) NOT NULL COMMENT '玩家等级',
  `is_draw` tinyint(5) NOT NULL DEFAULT '0' COMMENT '是否领取完再战沙场礼包',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_party_doll`;
CREATE TABLE `game_party_doll` (
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '���id',
  `record` blob COMMENT '�����������record',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='��������������ݱ�';



DROP TABLE IF EXISTS `game_player`;
CREATE TABLE `game_player` (
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `info` longblob NOT NULL COMMENT '玩家信息',
  `buff` longblob NOT NULL COMMENT '临时属性',
  `attr` longblob NOT NULL COMMENT '玩家属性',
  `equip` longblob NOT NULL COMMENT '装备栏',
  `skill` longblob NOT NULL COMMENT '技能数据',
  `camp` longblob NOT NULL COMMENT '阵法',
  `position` longblob NOT NULL COMMENT '官衔',
  `partner` longblob NOT NULL COMMENT '伙伴',
  `guild` longblob NOT NULL COMMENT '军团',
  `mind` longblob NOT NULL COMMENT '心法',
  `tower` longblob NOT NULL COMMENT '破阵',
  `bag` longblob NOT NULL COMMENT '背包',
  `depot` longblob NOT NULL COMMENT '仓库',
  `temp_bag` longblob NOT NULL COMMENT '临时背包',
  `sys` longblob NOT NULL COMMENT '开放系统',
  `maps` longblob NOT NULL COMMENT '地图列表',
  `task` longblob NOT NULL COMMENT '任务',
  `copy` longblob NOT NULL COMMENT '副本',
  `ability` longblob NOT NULL COMMENT '内功',
  `achievement` longblob NOT NULL COMMENT '成就',
  `practice` longblob NOT NULL COMMENT '修炼',
  `resource` longblob NOT NULL COMMENT '资源',
  `train` longblob NOT NULL COMMENT '培养',
  `lottery` longblob NOT NULL COMMENT '宝箱',
  `spring` longblob NOT NULL COMMENT '温泉',
  `guide` longblob NOT NULL COMMENT '新手指引',
  `invasion` longblob NOT NULL COMMENT '异民族',
  `schedule` longblob NOT NULL COMMENT '课程表',
  `bless` longblob NOT NULL COMMENT '祝福',
  `mcopy` longblob NOT NULL COMMENT '多人副本',
  `welfare` longblob NOT NULL COMMENT '福利系统',
  `new_serv` longblob NOT NULL COMMENT '新服活动',
  `weapon` longblob NOT NULL COMMENT '���',
  `style` longblob NOT NULL COMMENT '外形',
  `lookfor` longblob NOT NULL COMMENT 'Ѱ��',
  `horse` longblob NOT NULL COMMENT '坐骑',
  `furnace` longblob NOT NULL COMMENT '强化',
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`) USING HASH
) ENGINE=MYISAM DEFAULT CHARSET=utf8 ROW_FORMAT=COMPRESSED COMMENT='玩家数据表';



DROP TABLE IF EXISTS `game_player_rank`;
CREATE TABLE `game_player_rank` (
  `user_id` int(10) NOT NULL COMMENT '玩家id',
  `user_name` char(64) NOT NULL COMMENT '玩家姓名',
  `pro` smallint(4) NOT NULL DEFAULT '0' COMMENT '职业',
  `sex` smallint(4) NOT NULL DEFAULT '0' COMMENT '性别',
  `lv` smallint(4) NOT NULL DEFAULT '0' COMMENT '等级',
  `position` int(10) NOT NULL DEFAULT '0' COMMENT '官位',
  `exp` int(10) NOT NULL DEFAULT '0' COMMENT '经验',
  `exp_time` int(10) NOT NULL DEFAULT '0' COMMENT '获得经验时间',
  `vip` smallint(4) NOT NULL DEFAULT '0' COMMENT 'vip',
  `cash` int(10) NOT NULL,
  `title` int(10) NOT NULL DEFAULT '0' COMMENT '成就称号',
  `power` int(10) NOT NULL DEFAULT '0' COMMENT '战斗力',
  `guild_name` char(64) NOT NULL COMMENT '军团名称',
  `elite_copy` int(10) NOT NULL DEFAULT '0' COMMENT '精英副本',
  `elite_time` int(10) NOT NULL,
  `devil_copy` int(10) NOT NULL DEFAULT '0' COMMENT '魔鬼阵',
  `devil_time` int(10) NOT NULL,
  `meritorioust` int(10) NOT NULL DEFAULT '0',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_practice`;
CREATE TABLE `game_practice` (
  `user_id` int(10) NOT NULL COMMENT '玩家id',
  `exp_time` int(10) NOT NULL DEFAULT '0' COMMENT '获取经验时间',
  `vip_time` int(10) NOT NULL DEFAULT '0' COMMENT 'vip修炼时间累计',
  `automatic` tinyint(4) NOT NULL DEFAULT '0' COMMENT '是否自动双修',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_practice_doll`;
CREATE TABLE `game_practice_doll` (
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '���id',
  `record` blob COMMENT '������������record',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='���������������ݱ�';



DROP TABLE IF EXISTS `game_rank_data`;
CREATE TABLE `game_rank_data` (
  `type` int(10) NOT NULL COMMENT '类型',
  `rank` int(10) NOT NULL COMMENT '排名',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家姓名',
  `lv` smallint(4) NOT NULL,
  `other_id` int(11) NOT NULL DEFAULT '0' COMMENT '其他id',
  `other_name` char(64) NOT NULL DEFAULT '' COMMENT '其他名称',
  PRIMARY KEY (`type`,`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_rank_equip`;
CREATE TABLE `game_rank_equip` (
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `user_name` char(64) NOT NULL COMMENT '玩家名称',
  `pro` smallint(4) NOT NULL DEFAULT '0' COMMENT '职业',
  `sex` smallint(4) NOT NULL DEFAULT '0' COMMENT '性别',
  `lv` smallint(4) NOT NULL DEFAULT '0' COMMENT '等级',
  `vip` smallint(4) NOT NULL DEFAULT '0' COMMENT 'vip',
  `title` int(10) NOT NULL DEFAULT '0' COMMENT '称号',
  `partner_id` int(10) NOT NULL DEFAULT '0' COMMENT '武将id',
  `equip_type` int(10) NOT NULL DEFAULT '0' COMMENT '装备类型',
  `equip_id` int(10) NOT NULL DEFAULT '0' COMMENT '装备id',
  `equip_power` int(10) NOT NULL DEFAULT '0' COMMENT '装备战力',
  `equip_color` int(10) NOT NULL DEFAULT '0',
  `equip_lv` int(10) NOT NULL DEFAULT '0',
  `online_flag` smallint(4) NOT NULL DEFAULT '0' COMMENT '在线标识',
  `time` int(10) NOT NULL DEFAULT '0' COMMENT '更新时间',
  PRIMARY KEY (`user_id`,`partner_id`,`equip_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_rank_guild`;
CREATE TABLE `game_rank_guild` (
  `guild_id` bigint(10) NOT NULL COMMENT '军团id',
  `power` bigint(10) NOT NULL COMMENT '军团总战力',
  `lv` int(4) NOT NULL COMMENT '军团等级',
  PRIMARY KEY (`guild_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_rank_horse`;
CREATE TABLE `game_rank_horse` (
  `horse_id` int(20) NOT NULL COMMENT '坐骑id',
  `horse_name` char(63) NOT NULL COMMENT '坐骑名',
  `lv` int(20) NOT NULL COMMENT '坐骑等级',
  `color` int(10) NOT NULL COMMENT '颜色',
  `user_id` int(20) NOT NULL COMMENT '所属玩家',
  `user_name` char(127) NOT NULL COMMENT '玩家名',
  `power` int(255) NOT NULL COMMENT '战力',
  `time` int(126) NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_rank_partner`;
CREATE TABLE `game_rank_partner` (
  `partner_id` int(10) NOT NULL DEFAULT '0' COMMENT '武将id',
  `partner_name` char(64) NOT NULL DEFAULT '' COMMENT '武将名称',
  `partner_power` int(10) NOT NULL DEFAULT '0' COMMENT '武将战力',
  `partner_color` smallint(4) NOT NULL,
  `partner_pro` smallint(4) NOT NULL DEFAULT '0' COMMENT '武将职业',
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家名',
  `online_flag` tinyint(2) NOT NULL DEFAULT '0' COMMENT '在线标识',
  `time` int(10) NOT NULL DEFAULT '0' COMMENT '更新时间',
  `lv` smallint(4) NOT NULL,
  PRIMARY KEY (`partner_id`,`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_relation`;
CREATE TABLE `game_relation` (
  `user_id` int(10) NOT NULL,
  `friend_list` longblob NOT NULL,
  `best_list` longblob NOT NULL,
  `black_list` longblob NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_resource_lookfor`;
CREATE TABLE `game_resource_lookfor` (
  `user_id` int(10) NOT NULL COMMENT '玩家ID',
  `yesterday` blob COMMENT '昨日资源情况',
  `today` blob COMMENT '今日资源情况',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_resource_pool`;
CREATE TABLE `game_resource_pool` (
  `bgold` bigint(32) NOT NULL COMMENT 'ͭǮ',
  `list` longblob NOT NULL COMMENT '�н�����',
  `bexp` bigint(32) NOT NULL COMMENT '����',
  `list_exp` longblob NOT NULL COMMENT '�����н�����',
  `bcash` bigint(32) NOT NULL COMMENT '��ȯ',
  `bcash_list` longblob NOT NULL COMMENT '��ȯ�н�����'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_snow_info`;
CREATE TABLE `game_snow_info` (
  `user_id` int(10) NOT NULL COMMENT '���id',
  `count` int(10) NOT NULL COMMENT '�������',
  `level` int(10) NOT NULL COMMENT '��ǰ���ڵĲ�',
  `last_level` int(10) NOT NULL COMMENT '�ϴε����Ĳ�',
  `last_pos` int(10) NOT NULL COMMENT '�ϴε�����λ��',
  `lighted_list` longblob NOT NULL COMMENT 'ÿ������б�',
  `store_list` longblob NOT NULL COMMENT '�ղ���Ϣ�б�',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_spring_doll`;
CREATE TABLE `game_spring_doll` (
  `user_id` int(11) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `record` blob COMMENT '替身record',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='温泉替身';



DROP TABLE IF EXISTS `game_team_invite_offline`;
CREATE TABLE `game_team_invite_offline` (
  `userId` int(11) NOT NULL DEFAULT '0',
  `type` int(11) NOT NULL DEFAULT '0',
  `team_to` varchar(2048) DEFAULT '[]',
  `team_from` varchar(2048) DEFAULT '[]',
  `is_guild_all` tinyint(1) DEFAULT '0',
  `last_add_count_time` int(11) DEFAULT '0',
  `times` int(11) DEFAULT '0',
  PRIMARY KEY (`userId`,`type`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_tower_pass`;
CREATE TABLE `game_tower_pass` (
  `id` int(11) NOT NULL DEFAULT '0',
  `pass_type` int(11) DEFAULT NULL COMMENT '关卡类型(强BOSS,弱BOSS,福利关卡, 精英关卡)',
  `camp_id` int(11) DEFAULT NULL COMMENT '所属大阵id',
  `pass_id` int(11) DEFAULT NULL COMMENT '关卡id',
  `first_name` char(64) DEFAULT NULL COMMENT '关卡首杀玩家',
  `first_id` int(11) DEFAULT NULL COMMENT '关卡首杀玩家id',
  `best_pass` char(64) DEFAULT NULL COMMENT '最佳通关玩家',
  `best_passid` int(11) DEFAULT NULL COMMENT '最佳通关id',
  `best_score` smallint(4) DEFAULT NULL COMMENT '最佳通关回合数',
  PRIMARY KEY (`id`),
  KEY `pass_id` (`pass_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_tower_player`;
CREATE TABLE `game_tower_player` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `player_id` int(11) NOT NULL DEFAULT '0' COMMENT '玩家id',
  `top_score` int(11) DEFAULT '0' COMMENT '最高记录',
  `reset_times` smallint(4) DEFAULT '0' COMMENT '重置次数',
  `sweep_times` smallint(4) DEFAULT '0' COMMENT '扫荡次数',
  `camp` longblob COMMENT '关卡信息',
  `sweep` longblob COMMENT '扫荡',
  `top_time` int(10) DEFAULT '0' COMMENT '最高关卡首次通过的时间',
  PRIMARY KEY (`id`),
  KEY `player_id` (`player_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_tower_report`;
CREATE TABLE `game_tower_report` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `report` longblob NOT NULL COMMENT '战报',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_tower_report_idx`;
CREATE TABLE `game_tower_report_idx` (
  `id` int(20) NOT NULL AUTO_INCREMENT,
  `record` longblob NOT NULL COMMENT '战报索引',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_user`;
CREATE TABLE `game_user` (
  `user_id` int(10) NOT NULL AUTO_INCREMENT COMMENT '玩家ID',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家昵称',
  `serv_id` int(10) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `serv_unique_id` int(10) NOT NULL DEFAULT '0' COMMENT '服务器唯一ID',
  `acc_id` int(10) NOT NULL DEFAULT '4399' COMMENT '平台ID',
  `acc_name` char(32) NOT NULL DEFAULT 'tencent' COMMENT '平台名称',
  `account` char(64) NOT NULL DEFAULT '0' COMMENT '玩家平台账号',
  `exist` tinyint(5) NOT NULL DEFAULT '0' COMMENT '0：无角色 1：有角色',
  `state` tinyint(5) NOT NULL DEFAULT '1' COMMENT '玩家状态--0禁止登录 1正常 2指导员 3GM',
  `exp` bigint(20) NOT NULL DEFAULT '0' COMMENT '经验',
  `lv` smallint(5) NOT NULL DEFAULT '0' COMMENT '等级',
  `pro` tinyint(5) NOT NULL DEFAULT '0' COMMENT '职业',
  `sex` tinyint(5) NOT NULL DEFAULT '0' COMMENT '性别',
  `cash` int(10) NOT NULL DEFAULT '0' COMMENT '充值（现有）',
  `cash_sum` int(10) NOT NULL DEFAULT '0' COMMENT '充值总额',
  `cash_use` int(10) NOT NULL DEFAULT '0' COMMENT '充值已消耗',
  `cash_bind` int(10) NOT NULL DEFAULT '0' COMMENT '礼券（现有）',
  `cash_bind_2` int(10) NOT NULL DEFAULT '0' COMMENT '绑定元宝',
  `cash_bind_3` int(10) NOT NULL DEFAULT '0' COMMENT '保留字段',
  `gold` int(10) NOT NULL DEFAULT '0' COMMENT '金币（现有）',
  `gold_bind` int(10) NOT NULL DEFAULT '0' COMMENT '绑定金币（现有）',
  `vip` tinyint(4) NOT NULL DEFAULT '0' COMMENT 'VIP等级',
  `reg_time` int(10) NOT NULL DEFAULT '0' COMMENT '玩家注册时间',
  `reg_ip` char(15) NOT NULL DEFAULT '' COMMENT '注册IP',
  `fcm` tinyint(5) NOT NULL DEFAULT '2' COMMENT '防沉迷状态--0登记、未成年 1登记、成年 2未登记',
  `game_time` int(10) NOT NULL DEFAULT '0' COMMENT '防沉迷游戏时间',
  `login_time_last` int(10) NOT NULL DEFAULT '0' COMMENT '玩家最近登陆时间',
  `logout_time_last` int(10) NOT NULL DEFAULT '0' COMMENT '玩家最近登出时间',
  `login_ip` char(15) NOT NULL DEFAULT '' COMMENT '玩家最近登陆IP',
  `login_times` int(10) NOT NULL DEFAULT '0' COMMENT '玩家登陆总次数',
  `online` int(10) NOT NULL DEFAULT '0' COMMENT '玩家在线总时长',
  `online_flag` tinyint(5) NOT NULL DEFAULT '0' COMMENT '在线状态：0离线 1在线',
  PRIMARY KEY (`user_id`),
  KEY `index_union` (`serv_id`,`acc_id`,`account`) USING HASH,
  KEY `index_name` (`user_name`) USING HASH,
  KEY `index_account` (`account`) USING HASH,
  KEY `index_user_id` (`user_id`) USING HASH
) ENGINE=InnoDB AUTO_INCREMENT=100000 DEFAULT CHARSET=utf8 COMMENT='玩家信息表';



DROP TABLE IF EXISTS `game_welfare_deposit`;
CREATE TABLE `game_welfare_deposit` (
  `user_id` int(20) NOT NULL,
  `single` blob NOT NULL COMMENT '单笔礼包',
  `accum` blob NOT NULL COMMENT '累计礼包',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `game_world_doll`;
CREATE TABLE `game_world_doll` (
  `user_id` int(10) NOT NULL COMMENT '角色id',
  `today` tinyint(4) NOT NULL COMMENT '今日状态',
  `tomorrow` tinyint(4) NOT NULL COMMENT '明日状态',
  `date` int(10) NOT NULL COMMENT '今日时间戳',
  PRIMARY KEY (`user_id`),
  KEY `user_id` (`user_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `log_create_user_stat`;
CREATE TABLE `log_create_user_stat` (
  `logId` bigint(20) NOT NULL COMMENT 'logID标识',
  `accountName` varchar(32) NOT NULL,
  `uid` int(11) NOT NULL,
  `sid` int(11) NOT NULL,
  `optime` bigint(20) NOT NULL,
  `step` int(11) NOT NULL COMMENT '步骤',
  `ip` bigint(20) NOT NULL COMMENT 'ip',
  `date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：创建页流失相关日志(技术中心OR前端写入)';



DROP TABLE IF EXISTS `log_deposit`;
CREATE TABLE `log_deposit` (
  `id` char(25) NOT NULL COMMENT '订单号',
  `user_id` int(10) NOT NULL COMMENT '玩家ID',
  `account` char(64) NOT NULL COMMENT '平台账户',
  `lv` smallint(5) NOT NULL COMMENT '玩家等级',
  `pay_type` smallint(5) NOT NULL COMMENT '充值渠道',
  `pay_money` float(20,0) NOT NULL COMMENT '充值金额',
  `time` int(10) NOT NULL COMMENT '充值时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：充值(erlang后端记录，接口模块)';



DROP TABLE IF EXISTS `log_level_user_num`;
CREATE TABLE `log_level_user_num` (
  `lid` int(11) NOT NULL AUTO_INCREMENT,
  `serverID` int(11) NOT NULL COMMENT '服务器ID',
  `level` int(11) NOT NULL COMMENT '等级',
  `playerNum` bigint(20) NOT NULL COMMENT '数量',
  `date` date NOT NULL COMMENT '日期',
  PRIMARY KEY (`lid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：每天各等级玩家数量(技术中心SQL处理)';



DROP TABLE IF EXISTS `log_lost_user`;
CREATE TABLE `log_lost_user` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `lost_1` int(11) DEFAULT NULL COMMENT '一天流失用户',
  `lost_5` int(11) DEFAULT NULL COMMENT '五天流失用户',
  `lost_7` int(11) DEFAULT NULL COMMENT '七天流失用户',
  `total_user` int(11) DEFAULT NULL COMMENT '用户总数',
  `date` date DEFAULT NULL COMMENT '流失用户统计时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：流失用户统计（每天统计昨天流失用户 技术中心写入）';



DROP TABLE IF EXISTS `log_review_user`;
CREATE TABLE `log_review_user` (
  `review_1` int(11) DEFAULT NULL COMMENT '一天留存用户',
  `review_3` int(11) DEFAULT NULL COMMENT '三天留存用户',
  `review_7` int(11) DEFAULT NULL COMMENT '七天留存用户',
  `register_user` int(11) DEFAULT NULL COMMENT '注册用户',
  `date` date DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：用户回访(技术中心写入)';



DROP TABLE IF EXISTS `techcenter_campaign_time`;
CREATE TABLE `techcenter_campaign_time` (
  `id` int(10) NOT NULL DEFAULT '0',
  `sys_id` int(11) NOT NULL COMMENT '活动ID',
  `start` varchar(50) NOT NULL COMMENT '开始时间',
  `end` varchar(50) NOT NULL COMMENT '结束时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：游戏活动时间字典';



DROP TABLE IF EXISTS `techcenter_click_link`;
CREATE TABLE `techcenter_click_link` (
  `user_name` varchar(50) NOT NULL COMMENT '用户名',
  `time` int(11) NOT NULL COMMENT '时间',
  PRIMARY KEY (`user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='jump log(技术中心写入)';



DROP TABLE IF EXISTS `techcenter_cost`;
CREATE TABLE `techcenter_cost` (
  `consume_id` int(10) NOT NULL,
  `consume_explain` char(100) NOT NULL,
  PRIMARY KEY (`consume_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：消费点字典（货币）';



DROP TABLE IF EXISTS `techcenter_daily_currency`;
CREATE TABLE `techcenter_daily_currency` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '后台：每日货币剩余数量(erlang后端记录)',
  `date` date NOT NULL,
  `cash` bigint(20) NOT NULL,
  `cash_bind` bigint(20) NOT NULL,
  `gold_bind` bigint(20) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_exchange_cash`;
CREATE TABLE `techcenter_exchange_cash` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` int(10) NOT NULL COMMENT '玩家ID',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家昵称',
  `serv_id` int(10) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `account` char(64) NOT NULL DEFAULT '' COMMENT '玩家平台账号',
  `recv_name` char(64) NOT NULL DEFAULT '' COMMENT '收款方姓名',
  `bank_name` char(64) NOT NULL DEFAULT '' COMMENT '收款方开户行',
  `bank_id` char(64) NOT NULL DEFAULT '0' COMMENT '收款方银行卡卡号',
  `bank_addr` char(64) NOT NULL DEFAULT '' COMMENT '开户行所在地',
  `phone` char(64) NOT NULL DEFAULT '0' COMMENT '收款方联系电话',
  `time` int(10) NOT NULL COMMENT '获奖时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_exchange_goods`;
CREATE TABLE `techcenter_exchange_goods` (
  `id` int(10) NOT NULL AUTO_INCREMENT COMMENT '自增id',
  `user_id` int(10) NOT NULL COMMENT '玩家ID',
  `user_name` char(64) NOT NULL DEFAULT '' COMMENT '玩家呢称',
  `serv_id` int(10) NOT NULL DEFAULT '0' COMMENT '服务器ID',
  `account` char(64) NOT NULL DEFAULT '' COMMENT '玩家平台账号',
  `recv_name` char(64) NOT NULL DEFAULT '' COMMENT '收货方姓名',
  `recv_addr` char(64) NOT NULL DEFAULT '' COMMENT '收货方地址',
  `phone` char(64) NOT NULL DEFAULT '0' COMMENT '收货方电话',
  `remark` char(64) NOT NULL COMMENT '备注',
  `time` int(10) NOT NULL COMMENT '获奖时间',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_gm`;
CREATE TABLE `techcenter_gm` (
  `id` int(15) NOT NULL AUTO_INCREMENT COMMENT 'id',
  `account` varchar(50) NOT NULL COMMENT '平台帐号',
  `ip` varchar(15) NOT NULL COMMENT 'IP',
  `user_id` int(11) NOT NULL COMMENT '角色ID',
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '角色名字',
  `pay_amount` int(11) NOT NULL DEFAULT '0' COMMENT '玩家已充值总额',
  `qq` varchar(15) NOT NULL DEFAULT '' COMMENT '玩家QQ号码',
  `level` int(11) NOT NULL DEFAULT '1' COMMENT '玩家角色级别',
  `faction` int(10) NOT NULL COMMENT '军团',
  `mtime` int(11) NOT NULL DEFAULT '0' COMMENT '玩家提交投诉的时间',
  `mtype` tinyint(4) NOT NULL COMMENT '投诉的类型',
  `mtitle` varchar(100) NOT NULL DEFAULT '' COMMENT '投诉的标题',
  `content` text NOT NULL COMMENT '投诉的正文',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：GM投诉记录(erlang后端记录)';



DROP TABLE IF EXISTS `techcenter_goods`;
CREATE TABLE `techcenter_goods` (
  `id` int(11) NOT NULL COMMENT 'id',
  `name` varchar(50) NOT NULL COMMENT '物品名称',
  `type` tinyint(3) NOT NULL COMMENT '物品类型 1装备 2蛋 3技能书 4补给品 5宝箱 6礼包 7任务道具 8临时BUFF 9功能消耗品 10珍藏品 ',
  `subtype` tinyint(3) NOT NULL COMMENT '物品子类型 1武器 2护甲 3头盔 4靴子 5披风 6腰带 7项链 8戒指 9时装 10帮派徽章 11坐骑',
  `lv` tinyint(3) NOT NULL COMMENT '物品等级',
  `pro` tinyint(3) NOT NULL COMMENT '职业 0空 1陷阵 2飞军 3天机 4鬼谋 5控弦 6惊鸿',
  `sex` tinyint(3) NOT NULL COMMENT '性别 0空 1男 2女',
  `color` tinyint(3) NOT NULL COMMENT '颜色/品质 1白 2绿 3蓝 4金 5紫 6橙 7红',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：道具字典';



DROP TABLE IF EXISTS `techcenter_item`;
CREATE TABLE `techcenter_item` (
  `consume_id` int(10) NOT NULL,
  `consume_explain` char(100) NOT NULL,
  PRIMARY KEY (`consume_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：道具消耗字典';



DROP TABLE IF EXISTS `techcenter_link`;
CREATE TABLE `techcenter_link` (
  `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '平台账户',
  `time` int(10) NOT NULL DEFAULT '0' COMMENT '时间戳',
  PRIMARY KEY (`user_name`,`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='页面加载日志';



DROP TABLE IF EXISTS `techcenter_log_cash`;
CREATE TABLE `techcenter_log_cash` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL,
  `account` char(64) NOT NULL,
  `type` tinyint(5) NOT NULL,
  `type_desc` varchar(255) NOT NULL,
  `cash_change` int(10) NOT NULL,
  `cash` int(10) NOT NULL,
  `time` int(10) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_log_in_out`;
CREATE TABLE `techcenter_log_in_out` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `user_id` int(10) NOT NULL,
  `user_name` char(64) NOT NULL,
  `lv` smallint(5) NOT NULL,
  `time_login` int(10) NOT NULL,
  `time_logout` int(10) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `time` (`time_login`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_map`;
CREATE TABLE `techcenter_map` (
  `id` int(11) NOT NULL COMMENT '场景ID',
  `name` varchar(50) NOT NULL COMMENT '场景名称',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：场景字典';



DROP TABLE IF EXISTS `techcenter_map_online`;
CREATE TABLE `techcenter_map_online` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `time` int(10) NOT NULL,
  `map_id` int(10) NOT NULL,
  `count` int(5) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_online`;
CREATE TABLE `techcenter_online` (
  `time` int(10) NOT NULL COMMENT '时间',
  `player` int(10) NOT NULL COMMENT '在线人数',
  `ip` int(10) NOT NULL,
  PRIMARY KEY (`time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：全服在线人数/5mins(crontab脚本处理log_online.sh)';



DROP TABLE IF EXISTS `techcenter_open_sys`;
CREATE TABLE `techcenter_open_sys` (
  `id` int(11) NOT NULL COMMENT '开启的系统ID',
  `data` varchar(50) NOT NULL COMMENT '模块说明',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：开启模块字典';



DROP TABLE IF EXISTS `techcenter_partner`;
CREATE TABLE `techcenter_partner` (
  `partner_id` int(10) NOT NULL DEFAULT '0',
  `partner_name` char(20) DEFAULT NULL,
  `partner_color` int(2) DEFAULT NULL,
  PRIMARY KEY (`partner_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_pre_role`;
CREATE TABLE `techcenter_pre_role` (
  `user_name` varchar(32) NOT NULL,
  `time` int(11) NOT NULL,
  PRIMARY KEY (`user_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：进入角色创建页面(技术中心写入)';



DROP TABLE IF EXISTS `techcenter_sys_name`;
CREATE TABLE `techcenter_sys_name` (
  `sys_id` int(5) NOT NULL DEFAULT '0' COMMENT 'ģ��id',
  `name` char(128) NOT NULL DEFAULT '' COMMENT 'ģ����',
  `lv` int(4) NOT NULL DEFAULT '0' COMMENT '��Ϳ��ŵȼ�',
  PRIMARY KEY (`sys_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;



DROP TABLE IF EXISTS `techcenter_task`;
CREATE TABLE `techcenter_task` (
  `task_id` int(10) NOT NULL COMMENT '任务id',
  `task_name` char(50) NOT NULL COMMENT '任务名',
  `task_lv` int(10) NOT NULL COMMENT '任务等级',
  `prev_task_id` int(10) NOT NULL,
  `task_id_order` int(10) NOT NULL,
  `task_type` int(5) NOT NULL,
  PRIMARY KEY (`task_id`),
  KEY `task_id` (`task_id`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：任务字典';



DROP TABLE IF EXISTS `techcenter_task_open_sys`;
CREATE TABLE `techcenter_task_open_sys` (
  `task_id` int(11) NOT NULL COMMENT '任务ID',
  `open_sys` int(11) NOT NULL COMMENT '开启的系统ID',
  `open_sys_2` int(11) NOT NULL COMMENT '交任务开启的系统ID',
  PRIMARY KEY (`task_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='后台：任务开启模块字典';

CREATE TABLE `config_trans_version` (
  `ver` char(10) NOT NULL,
  `trans` char(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `config_trans_version` VALUES ('0', '4.1');

alter table `game_config` add column `version` char(255) NOT NULL COMMENT '版本' after `combine_reward` ;
INSERT INTO `game_config` VALUES ('0', '4.0');


DROP TABLE IF EXISTS `log_data_ability_camp`;
CREATE TABLE `log_data_ability_camp` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `operate` int(4) NOT NULL COMMENT '行为类型',
  `id` int(12) NOT NULL COMMENT 'id',
  `to_lv` int(4) NOT NULL COMMENT '新等级',
  `exp` int(12) NOT NULL COMMENT '经验'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_bless`;
CREATE TABLE `log_data_bless` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `operate` int(4) NOT NULL COMMENT '行为类型',
  `times` int(4) NOT NULL COMMENT '操作次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_boss`;
CREATE TABLE `log_data_boss` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `type` int(4) NOT NULL COMMENT '行为类型',
  `idx` int(4) NOT NULL COMMENT '名次',
  `hurt` int(12) NOT NULL COMMENT '总伤害',
  `hgold` int(12) NOT NULL COMMENT '伤害铜钱',
  `hmeritorious` int(12) NOT NULL COMMENT '伤害功勋',
  `hexperience` int(12) NOT NULL COMMENT '伤害历练',
  `rgold` int(12) NOT NULL COMMENT '排名铜钱',
  `rmeritorious` int(12) NOT NULL COMMENT '排名功勋',
  `rexperience` int(12) NOT NULL COMMENT '排名历练'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_campaign`;
CREATE TABLE `log_data_campaign` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `campaign` int(4) NOT NULL COMMENT '活动id',
  `time` int(11) NOT NULL COMMENT '时间',
  `sid` int(4) NOT NULL COMMENT '服务器id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_camp_battle`;
CREATE TABLE `log_data_camp_battle` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `time` int(11) NOT NULL COMMENT '时间',
  `rank` int(5) NOT NULL COMMENT '排名',
  `score` int(11) NOT NULL COMMENT '积分',
  `coin` int(11) NOT NULL COMMENT '铜钱奖励',
  `mer1` int(11) NOT NULL COMMENT '功勋',
  `mer2` int(11) NOT NULL COMMENT '排名功勋'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_chess`;
CREATE TABLE `log_data_chess` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `viplv` int(4) NOT NULL COMMENT '玩家vip等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `type` int(4) NOT NULL COMMENT '类型',
  `times` int(5) NOT NULL COMMENT '当天次数',
  `left_times` int(5) NOT NULL COMMENT '剩余次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_furnace`;
CREATE TABLE `log_data_furnace` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `operate` int(4) NOT NULL COMMENT '行为类型',
  `cost_type` int(4) NOT NULL COMMENT '消费类型',
  `cost` int(12) NOT NULL COMMENT '消费值',
  `equip_id` int(12) NOT NULL COMMENT '装备id',
  `equip_id2` int(12) NOT NULL COMMENT '装备id2'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_goods`;
CREATE TABLE `log_data_goods` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `pos` int(5) NOT NULL COMMENT '位置',
  `point` int(11) NOT NULL COMMENT '消费点',
  `goods_id` int(11) NOT NULL COMMENT '物品id',
  `num` int(4) NOT NULL COMMENT '数量',
  `time` int(11) NOT NULL COMMENT '时间',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `arg1` int(11) NOT NULL,
  `arg2` int(11) NOT NULL,
  `arg3` int(11) NOT NULL,
  `arg4` int(11) NOT NULL,
  `arg5` int(11) NOT NULL,
  `arg6` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_guild_operate`;
CREATE TABLE `log_data_guild_operate` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `guild_id` int(12) NOT NULL COMMENT '军团id',
  `operate` int(4) NOT NULL COMMENT '操作',
  `other_id` int(12) NOT NULL COMMENT '操作对象id',
  `goods_id` int(12) NOT NULL COMMENT '涉及到的道具id',
  `num` int(5) NOT NULL COMMENT '涉及到的数量',
  `skill_type` int(5) NOT NULL COMMENT '军团技能id',
  `skill_lv` int(5) NOT NULL COMMENT '技能等级',
  `cost` int(12) NOT NULL COMMENT '消费值'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_login`;
CREATE TABLE `log_data_login` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `ip` char(255) NOT NULL COMMENT 'ip',
  `map_id` int(11) NOT NULL COMMENT '地图id',
  `time` int(11) NOT NULL COMMENT '时间',
  `sid` int(4) NOT NULL COMMENT '服务器id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_login_check`;
CREATE TABLE `log_data_login_check` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `state` int(4) NOT NULL COMMENT '状态',
  `logout_time_last` int(11) NOT NULL COMMENT '最后退出时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_logout`;
CREATE TABLE `log_data_logout` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `login_time` int(11) NOT NULL COMMENT '登录时间',
  `logout_time` int(11) NOT NULL COMMENT '退出时间',
  `time` int(11) NOT NULL COMMENT '时间',
  `login_lv` int(4) NOT NULL COMMENT '登录等级',
  `logout_lv` int(4) NOT NULL COMMENT '退出等级',
  `task_id` int(11) NOT NULL COMMENT '任务id',
  `map_id` int(11) NOT NULL COMMENT '地图id',
  `ip` char(255) NOT NULL COMMENT 'ip',
  `logout_reason` int(4) NOT NULL COMMENT '退出原因'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_lv_up`;
CREATE TABLE `log_data_lv_up` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `lv2` int(4) NOT NULL COMMENT '等级2',
  `time` int(11) NOT NULL COMMENT '时间',
  `ip` char(255) NOT NULL COMMENT 'ip'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_mail`;
CREATE TABLE `log_data_mail` (
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `time` int(11) NOT NULL COMMENT '时间',
  `mail_id` int(11) NOT NULL COMMENT '邮件id',
  `operate` int(4) NOT NULL COMMENT '操作',
  `type` int(4) NOT NULL COMMENT '行为类型',
  `goods_id` int(11) NOT NULL COMMENT '道具id',
  `count` int(4) NOT NULL COMMENT '数量',
  `bind` int(4) NOT NULL COMMENT '绑定?',
  `sname` char(255) NOT NULL COMMENT '发送方名',
  `rname` char(255) NOT NULL COMMENT '接受方名',
  `stime` int(11) NOT NULL COMMENT '发送时间',
  `cash` int(11) NOT NULL COMMENT '元宝',
  `gold` int(11) NOT NULL COMMENT '铜钱',
  `point` int(11) NOT NULL COMMENT '消耗点',
  `user_id` int(11) NOT NULL COMMENT '玩家id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_mall`;
CREATE TABLE `log_data_mall` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `money_type` int(4) NOT NULL COMMENT '货币类型',
  `cost` int(12) NOT NULL COMMENT '消耗值',
  `goods_id` int(12) NOT NULL COMMENT '道具id',
  `goods_num` int(5) NOT NULL COMMENT '物品数量',
  `time` int(11) NOT NULL COMMENT '时间',
  `shop_type` int(4) NOT NULL COMMENT '类型'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_market`;
CREATE TABLE `log_data_market` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '玩家vip等级',
  `op` int(4) NOT NULL COMMENT '操作类型',
  `market_id` int(12) NOT NULL COMMENT '市集id',
  `goods_id` int(12) NOT NULL COMMENT '物品id',
  `goods_count` int(5) NOT NULL COMMENT '物品数量',
  `market_price` int(12) NOT NULL COMMENT '价格',
  `once_price` int(12) NOT NULL COMMENT '一口价',
  `time` int(11) NOT NULL COMMENT '时间',
  `seller_id` int(11) NOT NULL COMMENT '卖方id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_mcopy`;
CREATE TABLE `log_data_mcopy` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `mcopy_id` int(12) NOT NULL COMMENT '副本id',
  `times` int(4) NOT NULL COMMENT '次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_mind`;
CREATE TABLE `log_data_mind` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `mind_id` int(11) NOT NULL COMMENT '心法id',
  `operate` int(4) NOT NULL COMMENT '操作类型',
  `from_lv` int(4) NOT NULL COMMENT '等级1',
  `to_lv` int(4) NOT NULL COMMENT '等级2',
  `cost` int(11) NOT NULL COMMENT '消耗'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_partner`;
CREATE TABLE `log_data_partner` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `partner_id` int(12) NOT NULL COMMENT '武将id',
  `operate` int(4) NOT NULL COMMENT '操作类型',
  `cost_gold` int(12) NOT NULL COMMENT '消耗铜钱',
  `cash` int(12) NOT NULL COMMENT '消费元宝',
  `type` int(4) NOT NULL COMMENT '类型'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_patrol`;
CREATE TABLE `log_data_patrol` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(11) NOT NULL COMMENT '时间',
  `minus_type` int(4) NOT NULL COMMENT '行为类型',
  `minus_amount` int(11) NOT NULL COMMENT '消耗',
  `meritorious` int(11) NOT NULL COMMENT '功勋'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_rank`;
CREATE TABLE `log_data_rank` (
  `type` int(4) NOT NULL COMMENT '类型',
  `num` int(4) NOT NULL COMMENT '排名',
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `other_id` int(11) NOT NULL COMMENT '对应id',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_reconnect`;
CREATE TABLE `log_data_reconnect` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `time` int(11) NOT NULL COMMENT '时间',
  `reason` int(4) NOT NULL COMMENT '原因',
  `times` int(4) NOT NULL COMMENT '重连次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_robot`;
CREATE TABLE `log_data_robot` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `time` int(11) NOT NULL COMMENT '时间',
  `lv` int(4) NOT NULL COMMENT '等级',
  `boss_id` int(11) NOT NULL COMMENT ' boss_id',
  `cost` int(11) NOT NULL COMMENT '消耗',
  `type` int(4) NOT NULL COMMENT '类型',
  `left_cost` int(11) NOT NULL COMMENT '剩余'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_single_arena`;
CREATE TABLE `log_data_single_arena` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `old_rank` int(11) NOT NULL COMMENT '旧排名',
  `new_rank` int(11) NOT NULL COMMENT '新排名',
  `new_wins` int(4) NOT NULL COMMENT '新连胜',
  `atk_user_id` int(11) NOT NULL COMMENT '攻击方玩家id',
  `is_active` int(4) NOT NULL COMMENT '主动？',
  `new_times` int(4) NOT NULL COMMENT '新可用次数',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_skill`;
CREATE TABLE `log_data_skill` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(4) NOT NULL COMMENT '等级',
  `time` int(11) NOT NULL COMMENT '时间',
  `skill_id` int(11) NOT NULL COMMENT '技能id',
  `skill_lv_old` int(4) NOT NULL COMMENT '旧技能等级',
  `skill_lv_new` int(4) NOT NULL COMMENT '新技能等级',
  `skill_point` int(4) NOT NULL COMMENT '技能点',
  `skill_point_new` int(4) NOT NULL COMMENT '操作后技能点'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_stren`;
CREATE TABLE `log_data_stren` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(4) NOT NULL COMMENT '等级',
  `part` int(4) NOT NULL COMMENT '部位',
  `old_value` int(12) NOT NULL COMMENT '旧值',
  `new_value` int(12) NOT NULL COMMENT '新值',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_task`;
CREATE TABLE `log_data_task` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `pro` int(4) NOT NULL COMMENT '职业',
  `lv` int(4) NOT NULL COMMENT '等级',
  `task_id` int(11) NOT NULL COMMENT '任务id',
  `state` int(4) NOT NULL COMMENT '任务当前状态',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_tower`;
CREATE TABLE `log_data_tower` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `time` int(11) NOT NULL COMMENT '时间',
  `a` int(4) NOT NULL,
  `b` int(12) NOT NULL COMMENT '值',
  `viplv` int(4) NOT NULL COMMENT 'vip等级',
  `left_times` int(4) NOT NULL COMMENT '剩余次数'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_transpoint`;
CREATE TABLE `log_data_transpoint` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `v1` int(5) NOT NULL COMMENT '变化值1',
  `v1_new` int(5) NOT NULL COMMENT '新值1',
  `v2` int(5) NOT NULL COMMENT '变化值2',
  `v2_new` int(5) NOT NULL COMMENT '新值2',
  `v3` int(5) NOT NULL COMMENT '变化值3',
  `v3_new` int(5) NOT NULL COMMENT '新值3',
  `time` int(11) NOT NULL COMMENT '时间',
  `partner_id` int(11) NOT NULL COMMENT '武将id'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_user`;
CREATE TABLE `log_data_user` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '玩家等级',
  `time` int(12) NOT NULL COMMENT '时间',
  `type` int(4) NOT NULL COMMENT '行为类型',
  `sort` int(4) NOT NULL,
  `value` int(12) NOT NULL COMMENT '值',
  `other` int(12) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `log_data_world`;
CREATE TABLE `log_data_world` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `viplv` int(4) NOT NULL COMMENT 'vip等级',
  `time` int(11) NOT NULL COMMENT '时间',
  `hurt` int(11) NOT NULL COMMENT '伤害',
  `kill_count` int(11) NOT NULL COMMENT '人头',
  `exploit` int(11) NOT NULL COMMENT '军贡',
  `gold` int(11) NOT NULL COMMENT '铜钱',
  `robot` int(4) NOT NULL COMMENT '机器人'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DROP TABLE IF EXISTS `game_archery_info`;
CREATE TABLE `game_archery_info` (
  `user_id` int(10) NOT NULL DEFAULT '0' COMMENT '玩家ID',
  `power` int(11) DEFAULT NULL COMMENT '拉力',
  `angle` int(11) DEFAULT NULL COMMENT '角度',
  `arrow` int(11) DEFAULT NULL COMMENT '箭矢',
  `accGet` int(16)             COMMENT '累计奖励',
  `done` int(11) DEFAULT NULL COMMENT '当天通关靶场',
  `courtInfo` longblob COMMENT '靶场信息',
  `point` int(11) DEFAULT NULL COMMENT '今日积分',
  `time` int(11) DEFAULT NULL COMMENT '时间戳',
   PRIMARY KEY (`user_id`) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

drop table if exists `log_data_currency`;
CREATE TABLE `log_data_currency` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(5) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `is_first` int(4) NOT NULL COMMENT '首次消费',
  `money_type` int(4) NOT NULL COMMENT '货币类型',
  `value` int(11) NOT NULL COMMENT '变化值',
  `value_new` int(11) NOT NULL COMMENT '新值',
  `type` int(4) NOT NULL COMMENT '类型',
  `point` int(11) NOT NULL COMMENT '消费点',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table `log_data_robot` add column `cost_type` int(11) NOT NULL COMMENT '剩余' after `left_cost`;

DROP TABLE IF EXISTS `log_data_user_create`;
CREATE TABLE `log_data_user_create` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `pro` int(4) NOT NULL COMMENT '职业',
  `country` int(4) NOT NULL COMMENT '国家',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table `game_world_doll` add column `cash_today` int(11) NOT NULL COMMENT '今天元宝';
alter table `game_world_doll` add column `bcash_2_today` int(11) NOT NULL COMMENT '今天绑定元宝';
alter table `game_world_doll` add column `cash_tomorrow` int(11) NOT NULL COMMENT '明天元宝';
alter table `game_world_doll` add column `bcash_2_tomorrow` int(11) NOT NULL COMMENT '明天绑定元宝';
update `game_world_doll` set `cash_today` = `today` * 50, `bcash_2_today` = 0, `cash_tomorrow` = `tomorrow` * 50, `bcash_2_tomorrow` = 0;

CREATE TABLE `game_fund` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `fund` bigint(20) NOT NULL COMMENT '基金信息',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家基金信息表';

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

CREATE TABLE `log_data_sig_arena` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `sid` int(4) NOT NULL COMMENT '服务器id',
  `lv` int(4) NOT NULL COMMENT '等级',
  `old_rank` int(11) NOT NULL COMMENT '旧排名',
  `new_rank` int(11) NOT NULL COMMENT '新排名',
  `new_wins` int(4) NOT NULL COMMENT '新连胜次数',
  `ack_user_id` int(11) NOT NULL COMMENT '攻击方玩家id',
  `is_active` int(4) NOT NULL COMMENT '主动',
  `new_times` int(4) NOT NULL COMMENT '新剩余次数',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table `game_fund` modify column `fund` blob NOT NULL COMMENT '基金信息';

ALTER TABLE `game_mail`
ADD COLUMN `bcash2` int(10) NULL DEFAULT 0   COMMENT '绑定元宝'
AFTER `content1`;

SET FOREIGN_KEY_CHECKS=0;

DROP TABLE IF EXISTS `game_encroach_info`;
CREATE TABLE `game_encroach_info` (
  `user_id` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `game_encroach_rank` (
  `rank_id` int(11) NOT NULL,
  `data` blob NOT NULL,
  `update_time` int(11) NOT NULL,
  PRIMARY KEY (`rank_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `game_shop_secret` (
  `id` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

SET FOREIGN_KEY_CHECKS=0;

CREATE TABLE `game_shop_secret_info` (
  `user_id` int(11) NOT NULL,
  `record` blob NOT NULL,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `log_recharge` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(5) NOT NULL COMMENT '等级',
  `country` int(5) NOT NULL COMMENT '国家',
  `pro` int(5) NOT NULL COMMENT '职业',
  `a` int(5) NOT NULL,
  `b` int(5) NOT NULL,
  `methord` int(5) NOT NULL COMMENT '途径',
  `money` int(11) NOT NULL COMMENT '充值',
  `cash` int(11) NOT NULL COMMENT '元宝',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE `log_data_recharge` (
  `user_id` int(11) NOT NULL COMMENT '玩家id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `lv` int(5) NOT NULL COMMENT '等级',
  `country` int(5) NOT NULL COMMENT '国家',
  `pro` int(5) NOT NULL COMMENT '职业',
  `a` int(5) NOT NULL,
  `b` int(5) NOT NULL,
  `methord` int(5) NOT NULL COMMENT '途径',
  `money` int(11) NOT NULL COMMENT '充值',
  `cash` int(11) NOT NULL COMMENT '元宝',
  `time` int(11) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `game_card_exchange_partner`
ADD COLUMN `freetimes` int(3)  NULL DEFAULT 0   COMMENT '白银宝箱免费次数'
AFTER `time_e`;

CREATE TABLE `log_data_shop_secret` (
  `user_id` int(11) NOT NULL,
  `account` char(255) NOT NULL,
  `sid` int(4) NOT NULL,
  `money_type` int(4) NOT NULL,
  `cost` int(12) NOT NULL,
  `score` int(12) NOT NULL,
  `goods_id` int(12) NOT NULL,
  `goods_num` int(5) NOT NULL,
  `time` int(11) NOT NULL,
  `shop_type` int(4) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `log_data_link` (
  `time` bigint(12) NOT NULL COMMENT '时间',
  `link` longtext NOT NULL COMMENT '连接',
  `ret` text NOT NULL COMMENT '返回值',
  `success` char NOT NULL COMMENT '是否成功'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_teach` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `teach` longblob NOT NULL COMMENT '教学信息',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='玩家教学信息表';

truncate game_encroach_info;

ALTER TABLE `game_archery_info`
ADD COLUMN `instruction` int(2) NOT NULL DEFAULT 0 COMMENT '新手引导次数';

ALTER TABLE `game_archery_info`
ADD COLUMN `limit_buy` int(3) NOT NULL DEFAULT 0 COMMENT '每日购买次数限制';

ALTER TABLE `game_guild_member`     ADD COLUMN `pvp_score` INT DEFAULT '0' NULL COMMENT '军团功德' AFTER `party_flag2`;

CREATE TABLE `game_mixed_serv_activity` (
  `userid` bigint(32) NOT NULL COMMENT '玩家ID',
  `type` int(2) NOT NULL COMMENT '类型',
  `value` int(11) NOT NULL COMMENT '值',
  `state` bigint(32) NOT NULL COMMENT '状态',
  `time` bigint(32) NOT NULL COMMENT '记录时间',
  `endtime` bigint(32) NOT NULL COMMENT '结算时间',
  PRIMARY KEY (`userid`,`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_guild_rank` (
  `guild_id` bigint(32) NOT NULL COMMENT '军团ID',
  `rank` int(4) NOT NULL AUTO_INCREMENT COMMENT '排名',
  PRIMARY KEY (`rank`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table log_data_mail add column `bcash` int(11) NOT NULL COMMENT '礼券' after `point`;
alter table log_data_mail add column `bcash_2` int(11) NOT NULL COMMENT '绑定元宝' after `bcash`;

CREATE TABLE `log_data_login_req` (
  `acc_id` int(20) NOT NULL COMMENT '平台id',
  `account` char(255) NOT NULL COMMENT '帐号',
  `serv_id` int(4) NOT NULL COMMENT '服务器号',
  `fcm` int(4) NOT NULL COMMENT '防沉迷',
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `exist` int(4) NOT NULL COMMENT '存在',
  `state` int(4) NOT NULL COMMENT '状态',
  `game_time` int(20) NOT NULL COMMENT '游戏时间',
  `logout_time_last` int(20) NOT NULL COMMENT '最后登出时间',
  `sing` longtext NOT NULL COMMENT '验证码',
  `debug` char(20) NOT NULL COMMENT '调试模式',
  `link_time` int(20) NOT NULL COMMENT 'php传过来的时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_gamble_player`(
`user_id` int(11) PRIMARY KEY,
`chips` int(11) COMMENT '筹码 ',
`timestamp` int(11),
`times` int(5)
)DEFAULT CHARSET=utf8;

CREATE TABLE `log_data_gamble`(
`user_id` int(11),
`user_sid` int(3),
`chip1` int(5),
`user_id2` int(11),
`user_sid1` int(3),
`chip2` int(5),
`time` int(11)
)DEFAULT CHARSET=utf8;

ALTER TABLE `game_player`     
ADD COLUMN `partner_soul` LONGBLOB NOT NULL COMMENT '½«»ê' AFTER `furnace`;

CREATE TABLE `game_act_time` (
  `id` int(20) NOT NULL,
  `type` int(4) NOT NULL COMMENT '0关1开',
  `sec` int(4) NOT NULL COMMENT '秒',
  `min` int(4) NOT NULL COMMENT '分钟',
  `hour` int(4) NOT NULL COMMENT '小时',
  `day` int(4) NOT NULL COMMENT '天',
  `month` int(4) NOT NULL COMMENT '月',
  `year` int(5) NOT NULL COMMENT '年',
  `unix_time` int(12) NOT NULL,
  `exem` text NOT NULL COMMENT '模块',
  `exef` text NOT NULL COMMENT '函数名',
  `exea` blob NOT NULL COMMENT '参数',
  `template` int(20) NOT NULL COMMENT '模版id',
  `config_id` int(20) NOT NULL COMMENT '配置id',
  `reset_daily` int(4) NOT NULL COMMENT '每天重置',
  `clear_over` int(4) NOT NULL COMMENT '过期清空'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

alter table `game_act_time` drop column `type`;
alter table `game_act_time` drop column `sec`;
alter table `game_act_time` drop column `min`;
alter table `game_act_time` drop column `hour`;
alter table `game_act_time` drop column `day`;
alter table `game_act_time` drop column `month`;
alter table `game_act_time` drop column `year`;
alter table `game_act_time` drop column `unix_time`;
alter table `game_act_time` drop column `exem`;
alter table `game_act_time` drop column `exef`;
alter table `game_act_time` drop column `exea`;
alter table `game_act_time` add column `start_time` int(20) NOT NULL after `id`;
alter table `game_act_time` add column `stop_time` int(20) NOT NULL after `start_time`;

CREATE TABLE `game_act_user`(
`user_id` int(11) COMMENT '玩家ID',
`act_id` int(11) COMMENT '活动ID',
`data` longblob COMMENT '玩家数据',
PRIMARY KEY (`user_id`,`act_id`)
);

CREATE TABLE `game_hundred_serv`(
`user_id` int(11) COMMENT '玩家ID',
`act_id` int(11) COMMENT '活动ID',
`point` int(11) COMMENT '玩家数据',
PRIMARY KEY (`user_id`,`act_id`)
);

CREATE TABLE `log_data_snow` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `point` int(7) NOT NULL COMMENT '积分',
  `state` int(1) NOT NULL COMMENT '动作(1,充值；2,点灯)',
  `time` int(20) NOT NULL COMMENT '时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

ALTER TABLE `log_data_gamble`
ADD COLUMN `platform1` int(4) NOT NULL  COMMENT '玩家平台ID' AFTER `user_sid`;
ALTER TABLE `log_data_gamble`
ADD COLUMN `platform2` int(4) NOT NULL  COMMENT '对手玩家平台ID' AFTER `user_sid1`;

CREATE TABLE `game_card_chip` (
  `user_id` INT(11) NOT NULL DEFAULT '0',
  `chip_total` INT(11) DEFAULT '0',
  PRIMARY KEY (`user_id`)
) ENGINE=INNODB DEFAULT CHARSET=utf8;

truncate `game_tower_report`;
truncate `game_tower_report_idx`;
truncate `game_copy_single_report`;
truncate `game_copy_single_report_idx`;

CREATE TABLE `game_plat_t` (
  `plat_id` int(20) NOT NULL,
  `plat` text NOT NULL COMMENT '平台名',
  `login_key` text COMMENT '登录key',
  `center` text COMMENT '中心服ip',
  `fcm_site` text COMMENT '防沉迷地址',
  PRIMARY KEY (`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_server_t` (
  `sid` int(20) NOT NULL,
  `plat_id` int(20) NOT NULL,
  `ip_telcom` text NOT NULL,
  `combine` blob NOT NULL,
  `node` blob NOT NULL COMMENT '结点名',
  PRIMARY KEY (`sid`,`plat_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `game_tencent` (
  `user_id` int(20) NOT NULL COMMENT '玩家id',
  `tencent` longblob NOT NULL COMMENT '腾讯用户信息',
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='腾讯用户信息信息表';


CREATE TABLE if not exists `game_arena_member_tmp` ( 
           `player_id` bigint(20) NOT NULL DEFAULT '0' COMMENT '玩家ID',
           `player_name` varchar(50) NOT NULL DEFAULT '' COMMENT '玩家名字',
           `player_sex` tinyint(1) NOT NULL DEFAULT '0' COMMENT '玩家性别',
           `player_lv` int(11) NOT NULL DEFAULT '0' COMMENT '玩家等级',
           `player_career` tinyint(1) NOT NULL DEFAULT '0' COMMENT '职业',
           `rank` bigint(20) NOT NULL  AUTO_INCREMENT  COMMENT '名排' ,
           `times` int(11) NOT NULL DEFAULT '0' COMMENT '今日剩余挑战次数',
           `winning_streak` int(11) NOT NULL DEFAULT '0' COMMENT '胜连次数',
           `cd` int(11) NOT NULL DEFAULT '0' COMMENT '冷却时间',
           `fight_force` int(11) NOT NULL DEFAULT '0' COMMENT '战力',
           `open_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '是否打开竞技场界面',
           `daily_buy_time` int(11) NOT NULL DEFAULT '0' COMMENT '每天购买次数',
           `clean_times_time` int(11) NOT NULL DEFAULT '0' COMMENT '清空剩余次数和每天购买次数的时间',
           `on_line_flag` tinyint(1) NOT NULL DEFAULT '0' COMMENT '在线标志',
           `sn` int(11) NOT NULL DEFAULT '0' COMMENT '服务器编号',
           `streak_wining_reward` varchar(200) NOT NULL DEFAULT '[]' COMMENT '已经领过的连胜奖励',
           `daily_max_win` int(11) NOT NULL DEFAULT '0' COMMENT '当日最大连胜次数',
           `max_win` int(11) NOT NULL COMMENT '历史最大连胜',
           `meritorious` int(11) NOT NULL,
           `score` int(11) NOT NULL COMMENT '积分',
           `daily_target` int(11) NOT NULL COMMENT '每日目标',
           `target_state` int(4) NOT NULL COMMENT '每日目标状态',
           PRIMARY KEY (`rank`),
           KEY `rank` (`rank`) USING HASH
           ) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='竞技场信息';


