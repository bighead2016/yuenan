
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




