
一. 在线人数记录查询：
select FROM_UNIXTIME(time) as time,player,ip from techcenter_online ;


二. 每日货币后台记录（总获得，总使用，总剩余）
techcenter_daily_currency


三. boss伤害记录
log_data_boss

四. 消费类型
log_data_currency


五. 物品记录
log_data_goods

六. 邮件日志
log_data_mail

七. 商城日志
log_data_mall


八. 充值日志
select (select count(*) from game_player) as regist_num,(select sum(cash)*100*0.0003 from log_data_recharge) as charge_RMB;



九. 充值和使用记录
select c.*,d.gold_use from(select a.*,b.user_name from(select user_id,account,sum(cash) as gold_recharge  from log_data_recharge group by user_id) a join game_user b on a.user_id = b.user_id) c join
(select user_id,sum(value) as gold_use from log_data_currency where money_type = 1 and type = 2 and value > 0  group by user_id) d on c.user_id = d.user_id
order by gold_recharge desc;

+---------+-------------------------+---------------+------------------+----------+
| user_id | account                 | gold_recharge | user_name        | gold_use |
+---------+-------------------------+---------------+------------------+----------+
|    1129 | huy19902                |         10000 | 1s1ts            |     7420 |
|    1072 | sanmyphung              |          6000 | Myt              |     6018 |
|    1136 | huntersaga1             |          5000 | Thu1Ti           |     5000 |
|    1109 | gogovitamin             |          5000 | TiểuKiều         |     3105 |
|    1004 | aerosport               |          4500 | Beem             |     2300 |
|    1345 | ngamy12101978           |          2000 | ZzMyMyzZ         |     1605 |




十. ccu日志












