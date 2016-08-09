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
