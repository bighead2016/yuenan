CREATE TABLE `config_trans_version` (
  `ver` char(10) NOT NULL,
  `trans` char(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `config_trans_version` VALUES ('0', '4.1');
