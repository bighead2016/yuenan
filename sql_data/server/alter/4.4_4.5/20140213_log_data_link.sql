CREATE TABLE `log_data_link` (
  `time` bigint(12) NOT NULL COMMENT '时间',
  `link` longtext NOT NULL COMMENT '连接',
  `ret` text NOT NULL COMMENT '返回值',
  `success` char NOT NULL COMMENT '是否成功'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;