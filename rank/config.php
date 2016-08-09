<?php
/**
 * 设定时区
 */
date_default_timezone_set('Asia/Shanghai');
/*************************************************************************
 * 生成目录配置 : 
 *************************************************************************/
$GLOBALS['wwsg']['rank']['root'][1] = '/var/www/html/php_new/www_tool/rank/1/';
$GLOBALS['wwsg']['rank']['root'][2] = '/var/www/html/php_new/www_tool/rank/2/';
$GLOBALS['wwsg']['rank']['root'][91] = '/var/www/html/php_new/www_tool/rank/91/';
$GLOBALS['wwsg']['rank']['root'][92] = '/var/www/html/php_new/www_tool/rank/92/';
$GLOBALS['wwsg']['rank']['root'][93] = '/var/www/html/php_new/www_tool/rank/93/';

/*************************************************************************
 * 数据库配置 : 
 *************************************************************************/
$GLOBALS['wwsg']['rank']['db'][1] = array(
	/* 游戏服务器数据库主机: s<SerID>.<GameCode>.db.gamecore.cn 	*/
    'host'       => 'localhost',
    /* 数据库: server_<SerID> */
    'database'   => 'wwsg_root',
    /* 用户名: 数据库  	*/
    'username'   => 'wwsg',
    /* 用户密码			*/
    'password'   => '123456',
    /* 数据库编码 		*/
    'charset'    => 'utf8'
);
$GLOBALS['wwsg']['rank']['db'][2] = array(
     /* 游戏服务器数据库主机: s<SerID>.<GameCode>.db.gamecore.cn     */
    'host'       => 'localhost',
    /* 数据库: server_<SerID> */
    'database'   => 'wwsg_fenzhi',
    /* 用户名: 数据库   */
    'username'   => 'wwsg',
    /* 用户密码                 */
    'password'   => '123456',
    /* 数据库编码               */
    'charset'    => 'utf8'
);
$GLOBALS['wwsg']['rank']['db'][91] = array(
     /* 游戏服务器数据库主机: s<SerID>.<GameCode>.db.gamecore.cn     */
    'host'       => 'localhost',
    /* 数据库: server_<SerID> */
    'database'   => 'z1',
    /* 用户名: 数据库   */
    'username'   => 'wwsg',
    /* 用户密码                 */
    'password'   => '123456',
    /* 数据库编码               */
    'charset'    => 'utf8'
);
$GLOBALS['wwsg']['rank']['db'][92] = array(
     /* 游戏服务器数据库主机: s<SerID>.<GameCode>.db.gamecore.cn     */
    'host'       => 'localhost',
    /* 数据库: server_<SerID> */
    'database'   => 'z2',
    /* 用户名: 数据库   */
    'username'   => 'wwsg',
    /* 用户密码                 */
    'password'   => '123456',
    /* 数据库编码               */
    'charset'    => 'utf8'
);
$GLOBALS['wwsg']['rank']['db'][93] = array(
     /* 游戏服务器数据库主机: s<SerID>.<GameCode>.db.gamecore.cn     */
    'host'       => 'localhost',
    /* 数据库: server_<SerID> */
    'database'   => 'z1_2',
    /* 用户名: 数据库   */
    'username'   => 'wwsg',
    /* 用户密码                 */
    'password'   => '123456',
    /* 数据库编码               */
    'charset'    => 'utf8'
);




?>
