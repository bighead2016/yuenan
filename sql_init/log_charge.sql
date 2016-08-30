select c.*,d.gold_use from(select a.*,b.user_name from(select user_id,account,sum(cash) as gold_recharge  from log_data_recharge group by user_id) a join game_user b on a.user_id = b.user_id) c join

(select user_id,sum(value) as gold_use from log_data_currency where money_type = 1 and type = 2 and value > 0  group by user_id) d on c.user_id = d.user_id

order by gold_recharge desc;




s1:

+---------+-------------------------+---------------+------------------+----------+
| user_id | account                 | gold_recharge | user_name        | gold_use |
+---------+-------------------------+---------------+------------------+----------+
|    1129 | huy19902                |         10000 | 1s1ts            |     7420 |
|    1072 | sanmyphung              |          6000 | Myt              |     6018 |
|    1136 | huntersaga1             |          5000 | Thu1Ti           |     5000 |
|    1109 | gogovitamin             |          5000 | TiểuKiều         |     3105 |
|    1004 | aerosport               |          4500 | Beem             |     2300 |
|    1345 | ngamy12101978           |          2000 | ZzMyMyzZ         |     1605 |
|    1605 | denhdtq                 |          2000 | XUberX           |       25 |
|    1548 | gg110346044509857863212 |          2000 | Fezus            |     1600 |
|    1690 | nhocdenk998             |          1100 | DiệcNgọc         |     1100 |
|    1985 | minhphucq4331           |          1000 | SG.Mars.Q4       |      755 |
|    1201 | linuswiliam4            |          1000 | T                |      916 |
|    1019 | pharmacist1706          |          1000 | ๖ۣۜT๖ۣۜB         |      900 |
|    1384 | s3tamgias3              |          1000 | HươngHương       |     1000 |
|    1007 | thaile                  |           600 | NiệmYên          |      340 |
|    1208 | coluncolun              |           500 | ThínhHàn         |       80 |
|    1863 | ngoisaola001            |           500 | NgoiSaoLa        |      430 |
|    1093 | tinhkan0                |           300 | TriệuTửLoG       |      300 |
|    1217 | phantoan112             |           200 | Ngáo             |      190 |
|    1056 | biii123_bt              |           200 | ÁnhMộng          |      170 |
|    1052 | ducnha1                 |           200 | Chân             |      192 |
|    1978 | fb1630727307256395      |           200 | ThủyPhong        |       20 |
|    1043 | thienpham147            |           200 | HeartGameB       |      174 |
|    1884 | thinh24k                |           200 | LãnhNgọc         |      200 |
|    2095 | daibeovip               |           100 | MộngChi          |      100 |
|    1992 | anhvathienngu5          |           100 | BạchHuyên        |      100 |
|    1143 | tungdavir               |           100 | JonyTung         |       67 |
|    1139 | hoanghuong957           |           100 | ChỉHuy           |      100 |
|    1610 | fb132371607171385       |           100 | A.Tèo            |       90 |
|    2097 | macnhuhai456            |           100 | ÁcLong           |       70 |
|    1087 | luongphieu              |           100 | LươngPhiêu       |       80 |
+---------+-------------------------+---------------+------------------+----------+

s2:

+---------+-------------------------+---------------+---------------+----------+
| user_id | account                 | gold_recharge | user_name     | gold_use |
+---------+-------------------------+---------------+---------------+----------+
|  100021 | tungdavir               |          1000 | Jon           |      988 |
|  101605 | youpqal2001             |          1000 | HảiLam        |      556 |
|  100085 | vitconhap0              |          1000 | NhạnLăng      |      768 |
|  100987 | fb1716045101943041      |          1000 | TaoRảnh       |      880 |
|  100039 | gg114714381745890691080 |          1000 | NgạoLôi       |      580 |
|  100832 | bigundam0101            |           500 | MộThanh       |        5 |
|  101701 | chikua1108              |           500 | Aramir        |      488 |
|  100899 | dolehoa2005             |           200 | HuyễnXảo      |      200 |
|  100757 | mrtinh101               |           200 | ĐanHuyên      |      200 |
|  100633 | luubear                 |           200 | YếnLady       |      125 |
|  100593 | s00ngbui                |           200 | s00ng         |      200 |
|  100187 | gg102820050875910810914 |           200 | TiếuHàn       |      200 |
|  100904 | nguyenbaminhquan59      |           200 | BinThui       |      170 |
|  100034 | baba2412                |           100 | Nhật          |      100 |
|  100008 | fb1689337214618249      |           100 | QuýDM         |       60 |
|  100739 | chicaro121              |           100 | HànThiên      |       75 |
|  100461 | tuankcbt                |           100 | _Viết*Tuân    |      100 |
|  101092 | vicvnzoom               |           100 | BăngHạ        |      100 |
+---------+-------------------------+---------------+---------------+----------+