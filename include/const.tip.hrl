
%% ==========================================================
%% 系统
%% ==========================================================
-define(TIP_SYS_TASK,                              1).% 任务
-define(TIP_SYS_SKILL,                             2).% 武技
-define(TIP_SYS_MIND,                              3).% 祈天
-define(TIP_SYS_PARTNER,                           4).% 名将
-define(TIP_SYS_ABILITY,                           5).% 奇门
-define(TIP_SYS_MONSTER,                           6).% 怪物
-define(TIP_SYS_OPEN_PANEL,                        8).% 打开面板
-define(TIP_SYS_EQUIP,                             9).% 装备
-define(TIP_SYS_MCOPY,                             10).% 团队战场
-define(TIP_SYS_NOT_EQUIP,                         11).% 非装备
-define(TIP_SYS_TOWER,                             12).% 破阵
-define(TIP_SYS_QIYU,                              13).% 奇遇
-define(TIP_SYS_ACTIVE,                            14).% 活动
-define(TIP_SYS_INVASION,                          15).% 异民族
-define(TIP_SYS_MULTI_ARENA,                       16).% 战群雄
-define(TIP_SYS_QUICK_TEAM,                        17).% 快速加入队伍
-define(TIP_SYS_GUILD_NAME,                        18).% 军团名字
-define(TIP_SYS_GIFT,                              19).% 礼包
-define(TIP_SYS_COMMERCE,                          20).% 商路打劫
-define(TIP_SYS_GOODS_SUPPLY,                      21).% 辅助道具提示
-define(TIP_SYS_COMMERCE1,                         22).% 商路品质
-define(TIP_SYS_VIP,                               23).% vip礼包
-define(TIP_SYS_WELFARE,                           24).% 福利
-define(TIP_SYS_TOWER1,                            25).% 破阵关卡
-define(TIP_SYS_FURNACE_FUSION,                    26).% 时装合成
-define(TIP_SYS_PARTNER_ASSEMBLE,                  27).% 武将组合
-define(TIP_SYS_GOODS_ID,                          28).% 物品id
-define(TIP_SYS_COMM,                              100).% 通用消息

%% ==========================================================
%% 通用
%% ==========================================================
-define(TIP_COMMON_BAD_SING,                       501).% 验证码错误！
-define(TIP_COMMON_ERROR_DB,                       502).% 数据库忙
-define(TIP_COMMON_BAD_ARG,                        503).% 参数有误
-define(TIP_COMMON_SYS_ERROR,                      504).% 系统错误
-define(TIP_COMMON_NO_PERMISS,                     505).% 没有权限
-define(TIP_COMMON_CASH_NOT_ENOUGH,                506).% 元宝不足
-define(TIP_COMMON_BIND_CASH_NOT_ENOUGH,           507).% 礼券不足
-define(TIP_COMMON_GOLD_NOT_ENOUGH,                508).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_COMMON_BIND_GOLD_NOT_ENOUGH,           509).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_COMMON_MERITORIOUS_NOT_ENOUGH,         510).% 您的功勋不足，可通过【妖魔破】、【巡城】获取
-define(TIP_COMMON_BAG_NOT_ENOUGH,                 511).% 背包空间不足
-define(TIP_COMMON_DEPOT_NOT_ENOUGH,               512).% 仓库空间不足
-define(TIP_COMMON_GOOD_NOT_EXIST,                 513).% 物品不存在
-define(TIP_COMMON_GOOD_NOT_ENOUGH,                514).% 物品数量不足
-define(TIP_COMMON_LEVEL_NOT_ENOUGH,               515).% 玩家等级不足
-define(TIP_COMMON_SEX_NOT_MATCH,                  516).% 玩家性别不符
-define(TIP_COMMON_VIPLEVEL_NOT_ENOUGH,            517).% 玩家VIP等级不足
-define(TIP_COMMON_CTN_NOT_ENOUGH,                 518).% 容器空间不足
-define(TIP_COMMON_SP_NOT_ENOUGH,                  519).% 体力不足
-define(TIP_COMMON_TIME_NOT_FIT,                   520).% 时间已过
-define(TIP_COMMON_OFF_LINE,                       521).% 玩家不在线
-define(TIP_COMMON_NO_THIS_PLAYER,                 522).% 玩家不存在
-define(TIP_COMMON_EXPERIENCE_NOT_ENOUGH,          523).% 您的历练不足，可通过【妖魔破】玩法大量获取
-define(TIP_COMMON_NOT_SYNCHRONOUS,                524).% 数据不同步
-define(TIP_COMMON_PLAYER_IS_DEATH,                525).% 玩家处理死亡状态
-define(TIP_COMMON_SP,                             526).% 体力回复[10]
-define(TIP_COMMON_SP_IS_ENOUGH,                   527).% 体力已满
-define(TIP_COMMON_BUY_SP_ERROR,                   528).% 体力购买有误
-define(TIP_COMMON_CULTIVATION_NOT_ENOUGH,         529).% 修为不足
-define(TIP_COMMON_PACKET_ERROR,                   530).% 拆包错误
-define(TIP_COMMON_BAD_HEART,                      531).% 心跳不正常
-define(TIP_COMMON_BUFF_NOT_REPLACABLE,            532).% 您使用的新buff等级过低，无法替换
-define(TIP_COMMON_BUY_SP_TIMES_OVER,              533).% 购买体力次数已满
-define(TIP_COMMON_BUY_SP_SUCCESS,                 534).% 购买体力成功
-define(TIP_COMMON_HONOUR_NOT_ENOUGH,              535).% 荣誉不足
-define(TIP_COMMON_ANGER_NOT_ENOUGHT,              536).% 怒气不足
-define(TIP_COMMON_BUY_POINT_NOT_ENOUGH,           537).% 购买积分不足
-define(TIP_COMMON_STATE_FIGHTING,                 538).% 正在战斗中
-define(TIP_COMMON_PLAY_STATE_OTHER,               539).% 当前正在玩法中，无法切换
-define(TIP_COMMON_NO_THIS_MON,                    540).% 怪物不存在
-define(TIP_COMMON_TOO_MUCH_BGOLD,                 541).% 铜钱已达上限
-define(TIP_COMMON_TOO_MUCH_CASH,                  542).% 元宝已达上限
-define(TIP_COMMON_TOO_MUCH_BCASH,                 543).% 礼券已达上限
-define(TIP_COMMON_TOO_MUCH_MERITORIOUS,           544).% 功勋已达上限
-define(TIP_COMMON_TOO_MUCH_EXPLOIT,               545).% 军团贡献已达上限
-define(TIP_COMMON_TOO_MUCH_EXPERIENCE,            546).% 历练已达上限
-define(TIP_COMMON_TOO_MUCH_SKILL_POINT,           547).% 武技点已达上限
-define(TIP_COMMON_NOT_OPENED_HANDLER,             548).% 系统暂未开放
-define(TIP_COMMON_NOT_4_RAIDING,                  549).% 正在扫荡中
-define(TIP_COMMON_ATTR_RATE_NOT_ENOUGH,           550).% 官衔等阶不足
-define(TIP_COMMON_TOO_MUCH_EXP,                   551).% 经验已达上限
-define(TIP_COMMON_SYS_ERR,                        552).% 游戏出现未知错误，请按F5刷新，对您造成不便深表歉意！
-define(TIP_COMMON_DOWN,                           553).% 还有[10]服务器将关闭。
-define(TIP_COMMON_SERVER_TIME,                    555).% 服务器时间：[10]
-define(TIP_COMMON_GM_SUCCESS,                     560).% GM命令设置成功！
-define(TIP_COMMON_GM_FAIL,                        561).% GM命令格式错误，请查看GM文档！
-define(TIP_COMMON_USERNAME_EXIST,                 562).% 该名字已存在
-define(TIP_COMMON_EXCHANGE_OK,                    563).% 兑换成功
-define(TIP_COMMON_HAS_EQUIP,                      564).% 请脱下装备
-define(TIP_COMMON_IMMIGRANT_NOT_EXIT,             565).% 该服务器还未开启
-define(TIP_COMMON_IMMIGRANT_SUCCESS,              566).% 转移成功，本服账号将永久封存！
-define(TIP_COMMON_MOVE_SERVER_FAILED,             567).% 操作失败，请确保本账户在新服务器上线后再执行本操作！
-define(TIP_COMMON_HAS_HORSE,                      568).% 请脱下坐骑
-define(TIP_COMMON_HAS_FASHION,                    569).% 请脱下时装
-define(TIP_COMMON_ACTIVITY_NOT_IN_TIME,           570).% 活动尚未开始或已结束
-define(TIP_COMMON_NO_GET_AWARD,                   571).% 不能领取
-define(TIP_COMMON_TOO_MUCH_BCASH_2,               572).% 绑定元宝已达上限
-define(TIP_COMMON_ERR_NET,                        573).% 网络问题，请稍后再试
-define(TIP_COMMON_CODE_USING,                     574).% 喵。。。再等人家一下下嘛

%% ==========================================================
%% 玩家
%% ==========================================================
-define(TIP_PLAYER_CULTI_MAX,                      1202).% 修为等级已达到上限
-define(TIP_PLAYER_PLAY_STATE_CONFLICT,            1203).% 当前正在玩法中，无法切换
-define(TIP_PLAYER_PLAY_STATE_SPRING,              1204).% 您正在温泉中，无法进行该操作
-define(TIP_PLAYER_PLAY_STATE_BOSS,                1205).% 妖魔破中
-define(TIP_PLAYER_PLAY_STATE_INVASION,            1206).% 异民族中
-define(TIP_PLAYER_PLAY_STATE_ARENA_PVP,           1207).% 战群雄中
-define(TIP_PLAYER_PLAY_STATE_GUILD_PARTY,         1208).% 军团宴会中
-define(TIP_PLAYER_NOT_ENOUGH_SP,                  1301).% 体力不足
-define(TIP_PLAYER_ALREADY_GET_GIFT,               1400).% 礼包已领取！
-define(TIP_PLAYER_BAD_CODE,                       1401).% 无效验证码！
-define(TIP_PLAYER_GET_GIFT_SUCCESS,               1402).% 领取礼包成功！
-define(TIP_PLAYER_GIFT_GOODS,                     1403).% 恭喜[0]在[10]中获得了[10]!
-define(TIP_PLAYER_VIP_GOODS,                      1404).% 获得[10]*[10]
-define(TIP_PLAYER_VIP_DAILY_AWARD,                1405).% 领取成功，获得[10]礼券
-define(TIP_PLAYER_GIFT_TIMEOUT,                   1406).% 该礼包已过期！
-define(TIP_PLAYER_DEPOSIT_REPEAT,                 1500).% 充值订单重复！
-define(TIP_PLAYER_OLD_MAIDEN,                     1501).% 尚未充值！
-define(TIP_PLAYER_BAD_CASH_SUM,                   1502).% 充值金额不足！
-define(TIP_PLAYER_CHANGED_NAME_ERR,               1503).% 名字不可改
-define(TIP_PLAYER_CHANGED_NAME_OK,                1504).% 改名成功
-define(TIP_PLAYER_CHANGED_NAME_ED,                1505).% 名字已改过
-define(TIP_PLAYER_CULTI_SUCCESS,                  1506).% 激活成功
-define(TIP_PLAYER_IS_NOT_NEWBIE,                  1507).% 已经通过新手阶段
-define(TIP_PLAYER_SAME_PRO,                       1508).% 职业相同
-define(TIP_PLAYER_CHANGE_PRO_OK,                  1509).% 转职成功
-define(TIP_PLAYER_GOODS_NOT_ENOUGH,               1510).% 没有改名文书。
-define(TIP_PLAYER_VIP_NOTICE,                     1601).% 祝贺[0]VIP等级提升到[10]级，成为尊贵VIP玩家，尊享VIP特权！
-define(TIP_PLAYER_VIP_GIFT_NOTICE_1,              1611).% 恭喜[0]领取[10]

%% ==========================================================
%% 物品
%% ==========================================================
-define(TIP_GOODS_NOT_OPENED,                      2001).% 该位置未开启
-define(TIP_GOODS_EQUIP_NOT_EXIST,                 2002).% 装备不存在

-define(TIP_GOODS_NOT_EQUIPABLE,                   2003).% 等级不符合装备要求
-define(TIP_GOODS_NOT_MULTI_USE,                   2009).% 该物品不能批量使用
-define(TIP_GOODS_NOT_DIRECT_USE,                  2010).% 该物品无法直接使用
-define(TIP_GOODS_NOT_EXIST,                       2011).% 物品不存在
-define(TIP_GOODS_COUNT_NOT_ENOUGH,                2012).% 物品数量不足
-define(TIP_GOODS_PRO_NOT_USE,                     2013).% 职业不符，无法使用
-define(TIP_GOODS_SEX_NOT_USE,                     2014).% 性别不符，无法使用
-define(TIP_GOODS_LV_NOT_USE,                      2015).% 等级不足，无法使用
-define(TIP_GOODS_TIME_NOT_USE,                    2016).% 该物品已过期
-define(TIP_GOODS_VIP_NOT_USE,                     2017).% vip等级不足
-define(TIP_GOODS_COUNTRY_NOT_USE,                 2018).% 您所在国家不能使用该物品
-define(TIP_GOODS_MAP_NOT_USE,                     2019).% 当前场景不能使用这个物品
-define(TIP_GOODS_NOT_SPLITABLE,                   2020).% 物品不可拆分
-define(TIP_GOODS_ALREADY_MAX,                     2021).% 扩展达到上限
-define(TIP_GOODS_GET_OK,                          2022).% 领取成功
-define(TIP_GOODS_NOT_MATCHSEX,                    2023).% 性别不符，无法装备
-define(TIP_GOODS_USE_OK,                          2024).% 物品使用成功
-define(TIP_GOODS_TEMP_REWARD,                     2025).% 背包空间不足，你获得的物品[10]*[10]已放入临时背包！
-define(TIP_GOODS_THE_COUNT_NOT_ENOUGH,            2026).% [10]数量不足！
-define(TIP_GOODS_FORBID_DROP,                     2027).% 物品禁止掉落！
-define(TIP_GOODS_USE_GOODS,                       2028).% 获得[10]*[10]
-define(TIP_GOODS_USE_ALREADY_MAX,                 2029).% [10]超出上限，无法使用！
-define(TIP_GOODS_MOON_CAKE,                       2030).% 土豪[0]给全服人民发来国庆日问候，祝大家国庆快乐~
-define(TIP_GOODS_STONE_ADD_SAME,                  2031).% 每种类型宝石只能镶嵌一颗！
-define(TIP_GOODS_STONE_MAX_LEVEL,                 2032).% 宝石已等级到最高等级！

%% ==========================================================
%% 战斗
%% ==========================================================
-define(TIP_BATTLE_1,                              3001).% 获得[10]经验
-define(TIP_BATTLE_2,                              3002).% 获得[10]铜钱
-define(TIP_BATTLE_3,                              3003).% 获得[1]*[10]
-define(TIP_BATTLE_4,                              3004).% 累积功勋+[10]
-define(TIP_BATTLE_5,                              3005).% 声望+[10]
-define(TIP_BATTLE_6,                              3006).% 铜钱+[10]
-define(TIP_BATTLE_7,                              3007).% 功勋+[10]
-define(TIP_BATTLE_8,                              3008).% 武技点+[10]
-define(TIP_BATTLE_9,                              3009).% 军团贡献+[10]
-define(TIP_BATTLE_10,                             3010).% 遭遇战斗
-define(TIP_BATTLE_11,                             3011).% [10]
-define(TIP_BATTLE_12,                             3012).% -[10]
-define(TIP_BATTLE_13,                             3013).% +[10]
-define(TIP_BATTLE_14,                             3014).% 闪避
-define(TIP_BATTLE_15,                             3015).% 暴击
-define(TIP_BATTLE_16,                             3016).% 反击
-define(TIP_BATTLE_17,                             3017).% 格挡
-define(TIP_BATTLE_OFF,                            3018).% 发起战斗失败
-define(TIP_BATTLE_REFUSE_PK,                      3019).% 对方拒绝pk
-define(TIP_BATTLE_SKIP_TIMES_OVER,                3020).% 免费次数已用完
-define(TIP_BATTLE_CANNOT_SKIP,                    3021).% 该类型战斗不能跳过
-define(TIP_BATTLE_SKIPPED,                        3022).% 已跳过
-define(TIP_BATTLE_WIN_1,                          3100).% 开始xxxxx

%% ==========================================================
%% 商城
%% ==========================================================
-define(TIP_MALL_NO_DISCOUNT,                      18001).% 限时抢购未开放
-define(TIP_MALL_TIME_OVER,                        18002).% 购买时间已结束
-define(TIP_MALL_NO_GOODS,                         18003).% 物品已售完
-define(TIP_MALL_TYPE,                             18004).% 购买类型不存在
-define(TIP_MALL_GOODS_ENOUGH,                     18005).% 物品数量不足
-define(TIP_MALL_BUY_POINT,                        18006).% 积分不足
-define(TIP_MALL_VIP,                              18007).% vip等级不足
-define(TIP_MALL_MONEY,                            18008).% 元宝不足
-define(TIP_MALL_BAG,                              18009).% 背包已满
-define(TIP_MALL_ZERO,                             18010).% 请输入购买数量
-define(TIP_MALL_GOODS_ERROR,                      18011).% 物品不存在
-define(TIP_MALL_SUCCESS,                          18012).% 购买成功
-define(TIP_MALL_RIDE_COLOR,                       18013).% 放入坐骑的品质不对
-define(TIP_MALL_RIDE_LV,                          18014).% 放入坐骑的等级不对
-define(TIP_MALL_DICOUNT_COUNT,                    18015).% 您的该物品抢购名额已使用，无法继续购买

%% ==========================================================
%% 接入时错误代码
%% ==========================================================

%% ==========================================================
%% 任务
%% ==========================================================
-define(TIP_TASK_TIMES_OVER,                       20001).% 你已经完成该任务
-define(TIP_TASK_NOT_EXSIT,                        20002).% 任务不存在
-define(TIP_TASK_NOT_ACCEPT,                       20003).% 任务不可接
-define(TIP_TASK_NOT_FINISH,                       20005).% 任务未完成
-define(TIP_TASK_TIME_IS_OVER,                     20006).% 不在任务时间内
-define(TIP_TASK_ACCEPT_OK,                        20014).% 领取任务
-define(TIP_TASK_FINISHED,                         20015).% 完成任务

%% ==========================================================
%% 地图
%% ==========================================================
-define(TIP_MAP_NO_MAP,                            5001).% 不在地图中
-define(TIP_MAP_NO_GATHER,                         5002).% 采集品不存在
-define(TIP_MAP_NOT_NEARBY,                        5003).% 距离太远，无法采集
-define(TIP_MAP_GATHER_OK,                         5004).% 采集成功
-define(TIP_MAP_NOT_OPENED,                        5005).% 地图尚未开启
-define(TIP_MAP_END_COLLECT,                       5006).% 您结束了这次采集！
-define(TIP_MAP_INVITE_SUCCESS,                    5007).% 邀请切磋成功
-define(TIP_MAP_REJECT_PK_INVITE,                  5008).% 对方拒绝您的切磋邀请
-define(TIP_MAP_IN_OTHER_PLAY,                     5009).% 正在其他玩法中
-define(TIP_MAP_NOT_IN_SAME_MAP,                   5010).% 不在同一场景

%% ==========================================================
%% 家园
%% ==========================================================
-define(TIP_HOME_COIN_NOENOUGH,                    7003).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_HOME_UPDATE_CD,                        7008).% 升级封邑冷却中
-define(TIP_HOME_HARVEST_NONE,                     7014).% 没有可以收获的作物
-define(TIP_HOME_PLANT_INCD,                       7015).% 土地冷却中，无法种植
-define(TIP_HOME_PLANT_OPENPLANT,                  7016).% 请先开垦土地，再种植
-define(TIP_HOME_OFFICE_GETEXP,                    7017).% 成功领取[10]铜钱
-define(TIP_HOME_OFFICE_HASGETEXP,                 7018).% 你今天已经领过活跃度经验了
-define(TIP_HOME_UPDATEHOME_LVLIMIT,               7019).% 人物等级不足，升级封邑失败
-define(TIP_HOME_WARE_ZERO,                        7026).% 您当前的俸禄为0,请继续加油
-define(TIP_HOME_HASGETWARE,                       7027).% 你今天已经领过俸禄了
-define(TIP_HOME_OFFICE_GETWARE,                   7028).% 成功领取俸禄[10]铜钱
-define(TIP_HOME_UPDATE_MAX,                       7029).% 封邑已升到最高级
-define(TIP_HOME_REFRESH_FAIL,                     7043).% 刷新失败
-define(TIP_HOME_HARVAST_SUCCESS,                  7049).% 收获成功，得到[10]铜钱
-define(TIP_HOME_RECRUIT_MAX,                      7050).% 招募仕女达到上限
-define(TIP_HOME_PLANT_MAX,                        7053).% 该土地种植次数已满
-define(TIP_HOME_GRAB_FAIL_CD,                     7054).% 抢夺失败冷却已结束
-define(TIP_HOME_PLAY_GIRL_CD,                     7055).% 侍女互动冷却已结束
-define(TIP_HOME_LOOSEN_AWARD,                     7056).% 松土成功,获得[10]铜钱
-define(TIP_HOME_NOT_OPEN,                         7057).% 对方封邑尚未开启
-define(TIP_HOME_RECUIT_FIRST,                     7058).% 请先招募该仕女
-define(TIP_HOME_GIRL_HAS_EXIST,                   7060).% 仕女已招募
-define(TIP_HOME_BLACK_NUM_OVER,                   7061).% 小黑屋不够，无法抢夺侍女
-define(TIP_HOME_TASK_NOT_ACCEPT,                  7062).% 官府任务尚未接受
-define(TIP_HOME_TASK_OVER,                        7063).% 官府任务已完成
-define(TIP_HOME_TASK_RUNNING,                     7064).% 官府任务正在进行中
-define(TIP_HOME_TASK_NOT_OVER,                    7065).% 官府任务尚未完成
-define(TIP_HOME_TASK_REWARD_OVER,                 7066).% 今日奖励次数已完,本次无收益
-define(TIP_HOME_TASK_REWARD_SUCCESS,              7067).% 领取成功,获得[10]经验
-define(TIP_HOME_NEED_NOT_REFRESH,                 7068).% 已接受的任务无法刷新，当前没有可刷新的未接任务。
-define(TIP_HOME_NOT_ALLOW_OVER,                   7069).% 今日奖励次数已完,无法立即完成
-define(TIP_HOME_NOT_ALLOW_GET,                    7071).% 侍女互动次数不足,无法领取花魁日俸禄
-define(TIP_HOME_GET_GIRL_AWARD,                   7072).% 领取花魁俸禄成功,获得[10]铜钱
-define(TIP_HOME_RECRUIT_NOT_ALLOW,                7073).% 封邑等级不足,无法招募该侍女
-define(TIP_HOME_CONDITION_NOT_FIT,                7074).% 封邑日常任务未完成
-define(TIP_HOME_HAVAST_EXP,                       7075).% 收获成功,得到[10]经验
-define(TIP_HOME_HAVAST_MER,                       7076).% 收获成功,得到[10]历练
-define(TIP_HOME_PLAY_NOT_EXIST,                   7077).% 互动的仕女不存在
-define(TIP_HOME_NOT_PLAY_TWO,                     7078).% 不能互动同一玩家的两名仕女
-define(TIP_HOME_SKILL_HAS_PLAY,                   7079).% 已经与该仕女互动了此技能
-define(TIP_HOME_NOT_GIRL_SKILL,                   7080).% 不是该仕女的技能
-define(TIP_HOME_HAS_VIP_PLAY,                     7081).% 与VIP仕女互动达到上限
-define(TIP_HOME_PLAY_NOT_AWARD,                   7082).% 互动达到上限,本次无收益
-define(TIP_HOME_PLAY_WITH_EXP,                    7083).% 互动成功,获得[10]经验。
-define(TIP_HOME_PLAY_WITH_GOLD,                   7084).% 互动成功,获得[10]铜钱。
-define(TIP_HOME_PLAY_WITH_EXPLOIT,                7085).% 互动成功,获得[10]军贡。
-define(TIP_HOME_PLAY_WITH_MER,                    7086).% 互动成功,获得[10]历练。
-define(TIP_HOME_GET_DAILY,                        7087).% 封邑日常已领取
-define(TIP_HOME_GET_DAILY_SUCCESS,                7088).% 领取成功,获得[10]礼卷，[10]铜钱
-define(TIP_HOME_RECRUIT_SUCCESS,                  7410).% 招募成功
-define(TIP_HOME_RECRUIT_FAIL,                     7411).% 请先招募前一个仕女
-define(TIP_HOME_GRAB_TIMES_OVER,                  7412).% 今天抢仕女次数已用完

-define(TIP_HOME_GRAB_CD,                          7413).% 抢夺冷却时间中
-define(TIP_HOME_HAS_GRAB,                         7414).% 已成功抢夺侍女，无法再抢夺
-define(TIP_HOME_GIRL_NOT_EXSIT,                   7415).% 抢夺的仕女不存在
-define(TIP_HOME_GIRL_GRABING,                     7416).% 此仕女正在被别人抢夺，请排队
-define(TIP_HOME_PLAY_CD,                          7417).% 互动冷却中，请稍候互动
-define(TIP_HOME_GIRL_ESCAPE,                      7418).% 很遗憾，仕女不堪劳累，逃跑了
-define(TIP_HOME_FLOWER_SUCCESS,                   7419).% 恭喜互动成功，跟侍女赏花获得[10]经验
-define(TIP_HOME_WINE_SUCCESS,                     7420).% 恭喜互动成功，你和侍女一起饮酒获得[10]铜钱
-define(TIP_HOME_MUSIC_SUCCESS,                    7421).% 恭喜互动成功，仕女给你弹了一曲获得[10]历练
-define(TIP_HOME_MODEL_NOT_SHOW,                   7422).% 展示失败
-define(TIP_HOME_IS_SHOWING,                       7425).% 仕女已在展示中
-define(TIP_HOME_SHOW_SUCCESS,                     7426).% 恭喜你,展示仕女成功
-define(TIP_HOME_LEAVE_MESSAGE_SUCCESS,            7431).% 留言成功
-define(TIP_HOME_DELETE_LEAVE_MESSAGE,             7432).% 删除留言成功
-define(TIP_HOME_CLEAN_LEAVE_MESSAGE,              7433).% 清空留言成功
-define(TIP_HOME_GET_GIRL_EXP,                     7434).% 领取成功,获得[10]经验
-define(TIP_HOME_HAS_LOOSEN,                       7435).% 您已给该土地松过土
-define(TIP_HOME_LOOSEN_MAX,                       7436).% 该土地松土次数已满
-define(TIP_HOME_LOOSEN_SUCCESS,                   7437).% 松土成功
-define(TIP_HOME_GET_EXP_MAX,                      7438).% 领取经验已达上限
-define(TIP_HOME_GET_EXP_CD,                       7439).% 领取经验冷却中
-define(TIP_HOME_CHANGE_REC_CD,                    7440).% 刷新冷却中
-define(TIP_HOME_LOOSEN_NOT_ALLOW,                 7442).% 松土次数不足
-define(TIP_HOME_OPEN_REC_SUCCESS,                 7443).% 开启成功
-define(TIP_HOME_OPEN_BLACK_SUCCESS,               7444).% 开启成功
-define(TIP_HOME_HAS_ACCEPTE_TASK,                 7445).% 不能同时接受两个任务
-define(TIP_HOME_SLAVER_RESIST,                    7501).% 你是别人奴隶,不能进行抓捕
-define(TIP_HOME_PLAY_TIMES_OVER,                  7503).% 互动次数已用完
-define(TIP_HOME_CANNOT_PLAY,                      7504).% 不是奴隶,无法谄媚
-define(TIP_HOME_CANNOT_PLAY1,                     7505).% 你是奴隶,无侍女互动
-define(TIP_HOME_CANNOT_INVITE,                    7506).% 你不是奴隶,不能邀请好友解救
-define(TIP_HOME_NOT_INVITE_BELONGER,              7507).% 不能邀请自己的主人解救
-define(TIP_HOME_RESCUE_TIMES,                     7508).% 解救次数不足
-define(TIP_HOME_CANNOT_RESCUE,                    7509).% 你是奴隶,无法解救好友
-define(TIP_HOME_CANNOT_RESIST,                    7510).% 你不是奴隶,无法反抗
-define(TIP_HOME_PRESS_TIME,                       7511).% 压榨时间不足
-define(TIP_HOME_GET_EXP,                          7512).% 暂无干活经验
-define(TIP_HOME_CANNOT_RELEASE,                   7513).% 该侍女正被其他玩家抢夺,无法释放
-define(TIP_HOME_BATTLE_SELF,                      7514).% 此侍女已存在你的小黑屋,无法继续抓捕
-define(TIP_HOME_LV_NOT_ENOUGH,                    7515).% 等级差距超过10级,还是释放了吧
-define(TIP_HOME_RESCUE_EXP,                       7516).% 解救成功,获得[10]经验
-define(TIP_HOME_PRESS_EXP,                        7517).% 压榨成功,获得[10]经验
-define(TIP_HOME_DRAW_EXP,                         7518).% 抽取成功,获得[10]经验
-define(TIP_HOME_GET_BLACK_EXP,                    7519).% 提取成功,获得[10]经验
-define(TIP_HOME_RESCU_SELF,                       7520).% 无法解救自己抓捕的侍女
-define(TIP_HOME_REFUSE_INVITE,                    7521).% [10]拒绝了你的解救邀请
-define(TIP_HOME_HAS_BELONGER,                     7522).% 好友已逃出魔掌,无需解救
-define(TIP_HOME_INVITE_SUCCESS,                   7523).% 你已向[10]求助解救您的侍女。
-define(TIP_HOME_LV_NOT_ALLOW,                     7524).% 等级差距超过10级,还是饶了他吧

%% ==========================================================
%% 拍卖
%% ==========================================================
-define(TIP_MARKET_SALE_ACHEIEVE_MAX,              17001).% 寄售物品数量已达上限
-define(TIP_MARKET_SET_PRICE_ERROR,                17002).% 一口价须高于竞拍价
-define(TIP_MARKET_SET_PRICE_MAX,                  17003).% 价格超过输入上限
-define(TIP_MARKET_GOODS_NOT_OVERDURE,             17004).% 物品尚未流拍，无法取回
-define(TIP_MARKET_NOT_BUY_SELF_GOOS,              17005).% 不能购买自己的物品
-define(TIP_MARKET_NOT_OVERDURE_GOODS,             17006).% 没有可下架物品
-define(TIP_MARKET_NOT_BUY_AGAIN,                  17007).% 您已出价，无须竞标
-define(TIP_MARKET_GOODS_OVERDURE,                 17008).% 物品已过期
-define(TIP_MARKET_NOT_ALLOW_BUY,                  17009).% 该物品无法进行一口价竞标
-define(TIP_MARKET_NOT_ALLOW_SELL,                 17010).% 绑定物品无法出售
-define(TIP_MARKET_NUM_ERROR,                      17011).% 请输入寄售数量
-define(TIP_MARKET_BUY_SUCCESS,                    17012).% 恭喜您竞拍成功
-define(TIP_MARKET_FIXED_BUY,                      17013).% 恭喜您竞拍成功,请在邮件里查收
-define(TIP_MARKET_NOTICE_SELLER,                  17014).% [10]在市集中成功竞拍到您的[10]，您获得了[10]元宝！
-define(TIP_MARKET_HAS_BUYER,                      17015).% 物品已被竞拍,无法下架
-define(TIP_MARKET_GET_SUCCESS,                    17016).% 下架成功
-define(TIP_MARKET_HAS_STONE,                      17017).% 镶嵌宝石物品不能寄售

%% ==========================================================
%% 邮件
%% ==========================================================
-define(TIP_MAIL_SEND_SUCCESS,                     9001).% 发送雁书成功
-define(TIP_MAIL_SEND_FAIL,                        9002).% 发送雁书失败
-define(TIP_MAIL_NOT_PERSON,                       9003).% 收信人不存在，请重新输入
-define(TIP_MAIL_DELETE_SUCCESS,                   9004).% 删除雁书成功
-define(TIP_MAIL_SEND_MAX,                         9005).% 今日发送雁书已达上限
-define(TIP_MAIL_GET_ATTACHMENT_FAIL,              9006).% 提取附件失败
-define(TIP_MAIL_GET_ATTACHMENT_SUCCESS,           9007).% 提取附件成功
-define(TIP_MAIL_LV_NOT_ENOUGH,                    9008).% 等级达到30级可发送雁书
-define(TIP_MAIL_NOT_EXSIT,                        9009).% 附件不存在
-define(TIP_MAIL_OTHER_MAIL_FULL,                  9010).% 对方雁书已满
-define(TIP_MAIL_NOT_ATTACHMENT,                   9011).% 无附件领取
-define(TIP_MAIL_GET_GOLD,                         9012).% 获得[10]铜钱

-define(TIP_MAIL_GET_CASH,                         9013).% 获得[10]元宝
-define(TIP_MAIL_GET_GOODS,                        9014).% 获得[10]*[10]
-define(TIP_MAIL_GET_BCASH,                        9015).% 获得[10]礼券
-define(TIP_MAIL_GET_BCASH2,                       9016).% 获得[10]绑定元宝

%% ==========================================================
%% 道具店
%% ==========================================================
-define(TIP_SHOP_1,                                27301).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_SHOP_2,                                27302).% 背包空间不足，无法购买
-define(TIP_SHOP_NOT_SELLABLE,                     27303).% 该道具不可出售
-define(TIP_SHOP_OK,                               27304).% 成功购买
-define(TIP_SHOP_GET_MONEY,                        27305).% 获得[10]铜钱
-define(TIP_SHOP_NOT_OPEN,                         27306).% 云游商人活动未开启
-define(TIP_SHOP_IS_OVER,                          27307).% 云游商人活动已结束
-define(TIP_SHOP_SCORE_NOT_ENOUGH,                 27308).% 兑换积分不足
-define(TIP_SHOP_NO_TIMES,                         27309).% 没有可购买次数
-define(TIP_SHOP_UNABLE_BUY,                       27310).% 道具不可购买
-define(TIP_SHOP_NOT_EXISTS,                       27311).% 道具不存在
-define(TIP_SHOP_BUY_RARE_GOODS,                   27312).% [0]在云游商人兑换了珍稀[1]，真是令人羡慕！
-define(TIP_SHOP_BAG_IS_FULL,                      27313).% 背包空间不足

%% ==========================================================
%% 武将
%% ==========================================================
-define(TIP_PARTNER_TEAM_OVER_MAX,                 4001).% 武将招募名额已满，无法寻访，请解雇一名武将
-define(TIP_PARTNER_NOT_EXIST,                     4002).% 该名将不存在
-define(TIP_PARTNER_BAG_OVER_MAX,                  4003).% 招贤馆没有空位可招募了
-define(TIP_PARTNER_CAN_RECRUIT,                   4004).% 恭喜你成功招募[10]为麾下武将
-define(TIP_PARTNER_LOVE_GOODS_NOT_ENOUGH,         4005).% 喜好品不足，高级喜好品可通过【异民族】【破阵】【团队战场】获得
-define(TIP_PARTNER_NO_LOOK_LIST,                  4006).% 没有可寻访名将
-define(TIP_PARTNER_LOVE_GOOD_OVER,                4007).% 该喜好品已达上限
-define(TIP_PARTNER_LOOK_NUM_NOT_ENOUGH,           4008).% 当日寻访次数已经用完!
-define(TIP_PARTNER_LOOK_IN_CD,                    4009).% 寻访冷却中
-define(TIP_PARTNER_LOOKED_NOT_TREAT,              4010).% 请先处理已寻访的名将！
-define(TIP_PARTNER_HAVE_EQUIP,                    4011).% 该名将携带装备，无法解雇
-define(TIP_PARTNER_HAVE_MIND,                     4012).% 该名将携带星宿，无法解雇
-define(TIP_PARTNER_GET_LOOKER,                    4013).% 获得名将[10]!
-define(TIP_PARTNER_TIME_EXPIRE,                   4014).% 该名将停留时间已结束！
-define(TIP_PARTNER_LOOK_NUM_IS_MAX,               4015).% 当前购买次数达到上限，提升VIP可增加购买次数!
-define(TIP_PARTNER_CAN_LOOK_LIMIT,                4016).% 购买次数为5次以下才能购买！
-define(TIP_PARTNER_SET_ASSIST_FAIL,               4017).% 设置副将失败！0
-define(TIP_PARTNER_CHANGE_POS_FAIL,               4018).% 交换失败！0
-define(TIP_PARTNER_CHANGE_TYPE_1,                 4019).% 不允许该操作！
-define(TIP_PARTNER_CHANGE_TYPE_2,                 4020).% 不同位置，目标副将位为空，源主将有副将，不能操作！0
-define(TIP_PARTNER_CHANGE_TYPE_3,                 4021).% 主角不能交换至副将位置！0
-define(TIP_PARTNER_CHANGE_TYPE_4,                 4022).% 相同位置，目标副将位为空，不能操作！0
-define(TIP_PARTNER_CHANGE_TYPE_5,                 4023).% 目标主将位为空，不能设置副将！0
-define(TIP_PARTNER_CHANGE_TYPE_6,                 4024).% 该名将下有副将，只能被设为主将！0
-define(TIP_PARTNER_FIRE_ASSIST,                   4025).% 主角的副将不能直接解雇！0
-define(TIP_PARTNER_FIRE_STORY,                    4026).% 该名将暂无法解雇！
-define(TIP_PARTNER_SUCCESS_RECRUIT,               4027).% 恭喜你成功招募了武将[10]!
-define(TIP_PARTNER_SUCCESS_FREE,                  4028).% 你已经成功遣散了武将[10]!
-define(TIP_PARTNER_ALREADY_RECRUIT,               4029).% 该武将已招募！
-define(TIP_PARTNER_CANNOT_BUY_LOOKNUM,            4030).% 你还有可使用次数，无法购买！
-define(TIP_PARTNER_GET_SUPPER_COLOR,              4031).% [0]大展宏图，将慕名来投的[10]招至帐下！
-define(TIP_PARTNER_CHANGE_EQUIP_SUCCESS,          4032).% 交换成功！
-define(TIP_PARTNER_TRAIN_FAILED,                  4033).% 培养失败，还需继续努力
-define(TIP_PARTNER_TRAIN_LEVEL_LIMIT,             4034).% 培养等级不能高于主角等级！
-define(TIP_PARTNER_TRAIN_OPEN_LIMIT,              4035).% 已培养至最高级，无法继续培养。
-define(TIP_PARTNER_LOOK_GOODS_NOT_ENOUGH,         4036).% 拜访礼不足，无法进行寻访
-define(TIP_PARTNER_LOOK_CASH_NOT_ENOUGH,          4037).% 元宝不足，无法进行元宝寻访
-define(TIP_PARTNER_CALL_ON_REWARD,                4038).% 拜访[10]成功，阅历+[10],获得兵书X[10]
-define(TIP_PARTNER_LOOK_SUPPER_COLOR,             4039).% 恭喜[0]寻访到名将[10]
-define(TIP_PARTNER_ASSUP_GOODS_NOT_ENOUGH,        4040).% 兵书不足，无法升级
-define(TIP_PARTNER_LOOK_SEE_NOT_ENOUTH,           4041).% 阅历不足，无法消耗阅历提升普通寻访
-define(TIP_PARTNER_CALL_ON_GET_REWARD,            4042).% 拜访[10]成功，你获得兵书X[10]
-define(TIP_PARTNER_LOOKFOR_GET_REWARD,            4043).% 寻访到[10], 你阅历+[10]
-define(TIP_PARTNER_LOOK_GET_SEE,                  4044).% 阅历+[10]
-define(TIP_PARTNER_LOOK_GET_BOOK,                 4045).% 兵书X[10]
-define(TIP_PARTNER_LOOK_SINGLE_ASS,               4046).% 你习得单将兵法[10]，战斗属性获得了提升
-define(TIP_PARTNER_LOOK_TRIBE_ASS,                4047).% 恭喜你激活合谋兵法[10]，你可以升级被激活的合谋兵法提升你的战斗属性
-define(TIP_PARTNER_ASS_LV_MAX,                    4048).% 合谋兵法已满级，无法升级
-define(TIP_PARTNER_VIP_NOT_ENOUGH,                4049).% VIP等级不足5级，无法使用礼券进行至尊刷将。

%% ==========================================================
%% 技能
%% ==========================================================
-define(TIP_SKILL_FULL,                            26104).% 该武技已达到最高级
-define(TIP_SKILL_5,                               26105).% 学习武技成功
-define(TIP_SKILL_6,                               26106).% 您确认花费100元宝重置所有武技吗？
-define(TIP_SKILL_7,                               26107).% 重置成功
-define(TIP_SKILL_8,                               26108).% 武技可升级
-define(TIP_SKILL_9,                               26109).% 武技可学习
-define(TIP_SKILL_10,                              26110).% 学习条件不足
-define(TIP_SKILL_UPDATE_NOT_ALLOW,                26111).% 升级条件不足
-define(TIP_SKILL_EXIST,                           26112).% 武技已装备到技能栏
-define(TIP_SKILL_POINT_NOT_ENOUGH,                26113).% 武技点不足
-define(TIP_SKILL_PRE_NOT_FIT,                     26114).% 学习条件不足
-define(TIP_SKILL_CD_NOT_ENOUGH,                   26115).% 升级冷却中
-define(TIP_SKILL_NOT_WASH_POINT,                  26116).% 武技未学习，重置失败

%% ==========================================================
%% 成就系统
%% ==========================================================
-define(TIP_ACHIEVEMENT_GIFT_NOTEXIST,             6001).% 物品不存在！
-define(TIP_ACHIEVEMENT_GIFT_RECEIVED,             6002).% 已经领取奖励！
-define(TIP_ACHIEVEMENT_GIFT_INFO,                 6003).% 你获得了[10]*[10]！
-define(TIP_ACHIEVEMENT_TITLE_NOTEXIST,            6011).% 称号不存在！
-define(TIP_ACHIEVEMENT_TITLE_CURRENT,             6012).% 该称号为当前称号！
-define(TIP_ACHIEVEMENT_TITLE_UNFIT,               6013).% 称号未生效！
-define(TIP_ACHIEVEMENT_TITLE_CHANGE,              6014).% 更换成功！

%% ==========================================================
%% 资源
%% ==========================================================
-define(TIP_RESOURCE_RUNE_INSUFFICIENCY,           22101).% 今日已没有可夺铜钱次数
-define(TIP_RESOURCE_GOLD_UPPERLIMIT,              22102).% 铜钱达到上限！
-define(TIP_RESOURCE_GET_GOLD,                     22103).% 获得[10]铜钱！
-define(TIP_RESOURCE_PRAY_INSUFFICIENCY,           22106).% 今日已没有可巡城次数
-define(TIP_RESOURCE_MERITORIOUS_UPPERLIMIT,       22107).% 功勋达到上限！
-define(TIP_RESOURCE_CHEST_INSUFFICIENCY,          22111).%  封赏数量不足！
-define(TIP_RESOURCE_KEY_INSUFFICIENCY,            22112).%  封赏所需钥匙数量不足！
-define(TIP_RESOURCE_OPEN_CHEST,                   22113).% 开启封赏成功，获得[10]*[10]
-define(TIP_RESOURCE_UPGRADE_SUCCESS,              22114).% 封赏品质提升成功0
-define(TIP_RESOURCE_UPGRADE_FAILURE,              22115).%  封赏品质提升失败0
-define(TIP_RESOURCE_VIP_INSUFFICIENCY,            22116).% 夺铜钱次数不足，升级VIP等级，可以获得更多的次数
-define(TIP_RESOURCE_QUALITY_MAXIMUM,              22117).%  封赏品质已经达到最高！0
-define(TIP_RESOURCE_ADD_MERITORIOUS,              22118).% 获得功勋[10]!
-define(TIP_RESOURCE_CD_IS_0,                      22119).% 没有cd
-define(TIP_RESOURCE_CDING,                        22120).% cd中
-define(TIP_RESOURCE_GET_AWARD,                    22121).% [0]在天降财神中意外抽中[10]铜钱，鸿运齐天，你还不去[10]？
-define(TIP_RESOURCE_TRY,                          22122).% 试试
-define(TIP_RESOURCE_GET_EXP_AWARD,                22123).% [0]在天降财神中抽到了[10]经验，鸿运齐天，令人羡慕！快去[10]吧
-define(TIP_RESOURCE_GET_BCASH_AWARD,              22124).% [0]在天降财神中抽到了[10]礼券，鸿运齐天，令人羡慕！快去[10]吧
-define(TIP_RESOURCE_GET_NOTHING,                  22125).% 抱歉你没有抽中奖励

%% ==========================================================
%% 淘宝
%% ==========================================================
-define(TIP_LOTTERY_WAREHOUSE_INSUFFICIENCY,       23101).% 宝箱仓库空间不足！
-define(TIP_LOTTERY_MORAL_INSUFFICIENCY,           23106).% 人品值不足！
-define(TIP_LOTTERY_BAG_NOT_ENOUGH,                23107).% 背包已满，无法取出
-define(TIP_LOTTERY_TRANSFERENCE_SUCCESS,          23108).% 物品放入背包成功
-define(TIP_LOTTERY_MORAL_ERUPTION,                23109).% 【人名】在开启宝箱中人品大爆发，获得了【道具名】
-define(TIP_LOTTERY_MONEY_NOT_ENOUGH,              23110).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_LOTTERY_HARVEST_INFO,                  23111).% 你获得了【道具名】*数量
-define(TIP_LOTTERY_SUCCESS,                       23112).% 开启宝箱成功

%% ==========================================================
%% 温泉
%% ==========================================================
-define(TIP_SPRING_OFF,                            28308).% 骊山汤泉尚未开启！
-define(TIP_SPRING_MEMBER_NOT_SELF,                28321).% 玩家不能和自己进行互动！
-define(TIP_SPRING_PLAYER_OFF,                     28322).% 玩家不在骊山汤泉中！
-define(TIP_SPRING_PLAYER_IN_DOUBLE,               28323).% 玩家正在互动！
-define(TIP_SPRING_PLAYER_NOT_DOUBLE,              28324).% 玩家不在互动！
-define(TIP_SPRING_MEMBER_OFF,                     28331).% 对方不在骊山汤泉中！
-define(TIP_SPRING_MEMBER_NOT_DOUBLE,              28332).% 对方不在互动！
-define(TIP_SPRING_MEMBER_IN_DOUBLE,               28333).% 对方正在互动！
-define(TIP_SPRING_MEMBER_OFF_LINE,                28334).% 对方不在线！
-define(TIP_SPRING_NO_THIS_MEMBER,                 28335).% 对方不存在！
-define(TIP_SPRING_OPEN,                           28336).% 骊山汤泉已经开放，玩家进入后，可获得经验和体力奖励，千万不要错过哟！
-define(TIP_SPRING_CLOSE,                          28337).% 骊山汤泉已经结束，请等待下一次汤泉的开启！
-define(TIP_SPRING_SYS_OPEN,                       28338).% 未开启骊山汤泉
-define(TIP_SPRING_CANCEL,                         28340).% [10]取消互动
-define(TIP_SPRING_REJECT,                         28341).% [10]拒绝与你互动
-define(TIP_SPRING_JION_NOW,                       28342).% 你已经在骊山汤泉
-define(TIP_SPRING_AUTO_FAIL,                      28351).% 自动参加宴会失败
-define(TIP_SPRING_AUTO_VIP,                       28352).% VIP等级不足，无法替身参加
-define(TIP_SPRING_AUTO_OPEN,                      28353).% 活动已开启，无法设置替身状态
-define(TIP_SPRING_AUTO_STATE,                     28354).% 你已经设置替身参加，活动结束可获得奖励
-define(TIP_SPRING_AUTO_SUCCESS,                   28355).% 取消替身参加骊山汤，返还给您[10]元宝。
-define(TIP_SPRING_AUTO_SET_SUCCESS,               28356).% 设置替身成功，替身将自动参加活动

%% ==========================================================
%% 炼炉
%% ==========================================================
-define(TIP_FURNACE_BAD_CTN_TYPE,                  12101).% 装备类型错误
-define(TIP_FURNACE_IN_CD_TIME,                    12102).% 强化队列冷却中，无法强化
-define(TIP_FURNACE_STREN_LV_LIMIT,                12103).% 部位强化等级不能超过主角等级
-define(TIP_FURNACE_STREN_LV_MAX,                  12104).% 强化等级已达上限
-define(TIP_FURNACE_STREN_OK,                      12110).% 强化成功
-define(TIP_FURNACE_15,                            12115).% 强化功能开启，强化装备可以快速提升实力
-define(TIP_FURNACE_16,                            12116).% 你确认开启强化队列吗？
-define(TIP_FURNACE_17,                            12117).% 您确认花费[10]元宝永久清除强化冷却吗？
-define(TIP_FURNACE_21,                            12121).% 【人名】强化A装备到B等级，获得C武器0
-define(TIP_FURNACE_23,                            12123).% 【人名】强化A装备到B等级，获得C武器。0
-define(TIP_FURNACE_QUEUE_NOT_EXIST,               12125).% 强化队列不存在
-define(TIP_FURNACE_QUEUE_LIMIT,                   12126).% 强化队列已达上限
-define(TIP_FURNACE_INHERIT_OK,                    12207).% 强化继承成功0
-define(TIP_FURNACE_INHERIT_CHECK,                 12218).% 您确认把X星Y级的XX装备的强化等级继承到XX装备上么？0
-define(TIP_FURNACE_SCROLL_NOT_ENOUGH,             12308).% 缺少英雄战场掉落的卷轴
-define(TIP_FURNACE_MATERIAL_NOT_ENOUGH,           12309).% 缺少普通战场掉落的材料
-define(TIP_FURNACE_FORGE_OK,                      12310).% 锻造成功，您获得了[10]。
-define(TIP_FURNACE_22,                            12322).% 【人名】锻造获得了神兵Y。0
-define(TIP_FURNACE_24,                            12324).% 【人名】锻造获得了神兵Y。0
-define(TIP_FURNACE_BOTH_NO_SOUL,                  12401).% 该装备没有印属性
-define(TIP_FURNACE_SAME_SOUL_ONE_EQUIP,           12402).% 该装备已有同类型刻印
-define(TIP_FURNACE_SOUL_OK,                       12411).% 刻印成功
-define(TIP_FURNACE_NOT_GOODS_PIECE,               12510).% 该物品不能合成
-define(TIP_FURNACE_NO_CD,                         12511).% 冷却时间已结束
-define(TIP_FURNACE_GOODS_FORGE_OK,                12512).% 道具合成成功
-define(TIP_FURNACE_PIECES_NOT_ENOUGH,             12513).% 材料不足，无法合成
-define(TIP_FURNACE_NOT_STRENABLE,                 12601).% 该部位不能强化
-define(TIP_FURNACE_UPGRADE_OK,                    12602).% 升阶成功，您获得了[10]
-define(TIP_FURNACE_EQUIP_NOT_ENOUGH,              12603).% 缺少升阶所需的紫色装备
-define(TIP_FURNACE_UPGRADE_OK_2,                  12604).% [0]历经千锤百炼，终于成功锻造出[2]！！！
-define(TIP_FURNACE_FUSION_OK,                     12605).% 时装进阶成功，阶数+1
-define(TIP_FURNACE_FUSION_FAIL,                   12606).% 时装进阶失败，阶数保持最大值不变
-define(TIP_FURNACE_FUSION_NEW,                    12607).% 恭喜您，得到一件新的时装
-define(TIP_FURNACE_FUSION_OK_BROADCAST,           12608).% 恭喜[0]在[10]中将[2]阶数提升到[10]！
-define(TIP_FURNACE_FUSION_SAVE_OK,                12609).% 成功更换新形象
-define(TIP_FURNACE_FUSION_TOP,                    12610).% 已到顶级
-define(TIP_FURNACE_TRANSFER_OK,                   12611).% 宝石转移成功。
-define(TIP_FURNACE_TRANSFER_CON_NOT_ENOUGH,       12612).% 转移条件不满足。
-define(TIP_FURNACE_LV_OVER_PLAYER,                12901).% 装备等级不能超过人物0
-define(TIP_FURNACE_SUBTYPE_ERROR,                 12905).% 请放入相同部位的装备
-define(TIP_FURNACE_BAD_ARG,                       12999).% 参数错误

%% ==========================================================
%% 心法
%% ==========================================================
-define(TIP_MIND_BAG_CEIL_NOT_ENOUGH,              24101).% 星斗背包已满
-define(TIP_MIND_TEMP_BAG_CEIL_NOT_ENOUGH,         24102).% 星斗临时背包已满
-define(TIP_MIND_SPIRIT_NOT_ENOUGH,                24105).% 天命不足
-define(TIP_MIND_LV_MAX,                           24106).% 星斗已满级
-define(TIP_MIND_BAD_ARG,                          24107).% 参数错误
-define(TIP_MIND_ALREADY_PICK,                     24108).% 星斗已全部归位
-define(TIP_MIND_DUP_TYPE,                         24109).% 已装备同类型星斗
-define(TIP_MIND_NOT_OPEN,                         24110).% 该级别祈天未开启
-define(TIP_MIND_LOCK,                             24111).% 星斗已锁定,无法转化
-define(TIP_MIND_READ_BROADCAST,                   24112).% [0]祈天人品爆发，获得[10]，心动不如行动，请[10]吧！
-define(TIP_MIND_READ_LIMIT,                       24113).% 当日元宝祈天次数已达上限
-define(TIP_MIND_CHANGE_SPIRIT,                    24114).% 获得了[10]天命
-define(TIP_MIND_ALL_ABSORB,                       24115).% 星斗转化成功
-define(TIP_MIND_READ_BROADCAST2,                  24116).% [0]祈天人品爆发，获得[10]，心动不如行动，请[10]吧！
-define(TIP_MIND_MIND_NOT_EXIST,                   24117).% 心法不存在
-define(TIP_MIND_SCORE_NOT_ENOUGH,                 24118).% 积分不足
-define(TIP_MIND_EXCHANGE_OK,                      24119).% 兑换成功

%% ==========================================================
%% 常规组队
%% ==========================================================
-define(TIP_GROUP_IN_GROUP,                        19001).% 当前正在掠阵
-define(TIP_GROUP_IS_FULL,                         19002).% 掠阵队伍已满
-define(TIP_GROUP_NOT_EXIST,                       19003).% 掠阵队伍不存在
-define(TIP_GROUP_NOT_FIT_COUNRY,                  19004).% 国家不符合
-define(TIP_GROUP_NOT_FIT_GUILD,                   19005).% 军团不符合
-define(TIP_GROUP_REJECT_JOIN,                     19006).% 对方拒绝了您的申请
-define(TIP_GROUP_PASS_JOIN,                       19007).% 对方通过了您的申请
-define(TIP_GROUP_REJECT_ERROR,                    19008).% 拒绝失败
-define(TIP_GROUP_NOT_APPLYING,                    19009).% 你不在申请状态
-define(TIP_GROUP_NOT_LEADER,                      19010).% 你不是队长
-define(TIP_GROUP_GET_LIST_FAIL,                   19011).% 无推荐队伍列表
-define(TIP_GROUP_DISBAND,                         19012).% 队伍已经解散
-define(TIP_GROUP_QUIT,                            19013).% 您已经离开了队伍
-define(TIP_GROUP_WAITING_STATE,                   19014).% 已经是待组玩家
-define(TIP_GROUP_IS_WAITER,                       19015).% 您成为了待组玩家
-define(TIP_GROUP_CANCEL_WAITING,                  19016).% 取消待组成功
-define(TIP_GROUP_NOT_WAITING_STATE,               19017).% 您不是待组玩家
-define(TIP_GROUP_NOT_WAITING_LIST,                19018).% 无待组列表
-define(TIP_GROUP_NOT_ALLOW_INVITE,                19019).% 您不在队伍中，不能邀请玩家组队
-define(TIP_GROUP_NOT_ONLINE,                      19020).% 对方不在线，邀请失败
-define(TIP_GROUP_REJECT_INVITE,                   19021).% 对方拒绝您的邀请
-define(TIP_GROUP_JOIN_SUCCESS,                    19022).% 成功加入队伍
-define(TIP_GROUP_INVITE_SUCCESS,                  19023).% 邀请对方成功
-define(TIP_GROUP_REJECT_SUCCESS,                  19024).% 拒绝成功
-define(TIP_GROUP_APPLY_TIME_OVER,                 19025).% 同时只能向3支队伍发送申请
-define(TIP_GROUP_NOT_WAITING_USER,                19026).% 对方已不是待组玩家
-define(TIP_GROUP_USER_NOT_IN_GROUP,               19027).% 请您选择要转移的队长
-define(TIP_GROUP_AUTO_APPLY_SUCCESS,              19028).% 自动加入申请成功
-define(TIP_GROUP_APPLIED_MAX,                     19029).% 您申请加入的队伍被申请过多，请换支队伍申请
-define(TIP_GROUP_NOT_FIT_PRO,                     19030).% 您所加入的队伍中有与您职业相同的角色,无法组成掠阵。
-define(TIP_GROUP_CANCEL_JOIN,                     19031).% 取消申请成功
-define(TIP_GROUP_HAS_CANCEL_JOIN,                 19032).% 对方已不在申请状态
-define(TIP_GROUP_WAITING_INFO,                    19033).% 请加入队伍后再查看待组信息
-define(TIP_GROUP_NOT_OPEN,                        19034).% 对方还未开启掠阵功能
-define(TIP_GROUP_NOT_ALLOW_LEADER,                19035).% 无法转移给非在线玩家
-define(TIP_GROUP_APPLY_RANDOM_SEND,               19036).% 随机加入掠阵申请已发出
-define(TIP_GROUP_PRO_NOT_FIT,                     19037).% 队伍中有与您所邀请的玩家相同的职业,无法组成掠阵
-define(TIP_GROUP_IN_GROUP1,                       19039).% 对方当前正在掠阵
-define(TIP_GROUP_PRO_NOT_FIT1,                    19308).% 邀请的玩家职业与您相同,无法组成掠阵

%% ==========================================================
%% 坐骑
%% ==========================================================
-define(TIP_HORSE_NO_GIRD,                         27201).% 坐骑培养栏已满
-define(TIP_HORSE_NO_DEVELOP_HORSE,                27202).% 没有可进化的小马驹
-define(TIP_HORSE_GROW,                            27203).% 坐骑成长值不足，无法进化
-define(TIP_HORSE_NO_TAKE_HORSE,                   27204).% 没有可领取的坐骑
-define(TIP_HORSE_GOODS,                           27205).% 没有选中坐骑
-define(TIP_HORSE_NO_FEED,                         27206).% 没有可培养的小马驹
-define(TIP_HORSE_GOODS_POS,                       27207).% 该物品无法用于坐骑培养
-define(TIP_HORSE_GOODS_COLOR,                     27208).% 该物品无法用于坐骑培养
-define(TIP_HORSE_FEED_FULL,                       27209).% 培养已达上限
-define(TIP_HORSE_STRENGTH_LV,                     27210).% 坐骑培养等级不能超过主角等级
-define(TIP_HORSE_STRENGTH_FULL,                   27211).% 坐骑等级已满
-define(TIP_HORSE_COST_TYPE,                       27212).% 操作不正确
-define(TIP_HORSE_MONEY,                           27213).% 元宝不足
-define(TIP_HORSE_STRENGTH_DATA,                   27214).% 提升失败
-define(TIP_HORSE_INHERIT_LV,                      27215).% 不能继承更低或相同的等级
-define(TIP_HORSE_STRENGTH_EQUIP,                  27216).% 该坐骑无法用于坐骑等级提升
-define(TIP_HORSE_DEVELOP_FINISH,                  27217).% 进化成功
-define(TIP_HORSE_STRENGTH_LV_UP,                  27218).% 坐骑升级成功
-define(TIP_HORSE_SKILL,                           27219).% 已经拥有该技能
-define(TIP_HORSE_FEED_FINISH,                     27220).% 完成培养
-define(TIP_HORSE_TAKE_SUCCESS,                    27221).% 领取坐骑成功
-define(TIP_HORSE_INHERIT_SAME,                    27230).% 不能继承相同的坐骑
-define(TIP_HORSE_INHERIT_SUCCESS,                 27231).% 继承成功
-define(TIP_HORSE_SKILL_CHANGE_SUCCESS,            27232).% 学习技能成功
-define(TIP_HORSE_LV_NOT_ENOUGH,                   27233).% 坐骑培养等级不满足学习条件
-define(TIP_HORSE_CD_TIME,                         27234).% 坐骑可进化
-define(TIP_HORSE_NO_SKILL_BOOK,                   27235).% 没有相应的技能书
-define(TIP_HORSE_FEED_SUCCESS,                    27241).% 培养成功
-define(TIP_HORSE_STRENGTH_SUCCESS,                27242).% 坐骑获得[10]经验
-define(TIP_HORSE_STRENGTH_SMALL,                  27243).% 恭喜出现小暴击,坐骑获得[10]经验
-define(TIP_HORSE_STRENGTH_BIG,                    27244).% 恭喜出现大暴击,坐骑直接升级
-define(TIP_HORSE_STRENGTH_EQUIP_NULL,             27245).% 请放入要交换的物品
-define(TIP_HORSE_USE_EGG,                         27246).% 封邑尚未开放，无法培养小马驹
-define(TIP_HORSE_GOLD_STREN,                      27251).% 您给坐骑喂养了普通草料为其增加了[10]点经验
-define(TIP_HORSE_GOLD_STREN_SMALL,                27252).% 人品爆发，您喂养的普通草料为为坐骑增加了5倍经验[10]点
-define(TIP_HORSE_CASH_STREN,                      27253).% 您给坐骑喂养了精良草料为其增加了[10]点经验。
-define(TIP_HORSE_CASH_STREN_SMALL,                27254).% 人品爆发，您喂养的精良草料为坐骑增加了5倍经验[10]点。
-define(TIP_HORSE_CASH_STREN_BIG,                  27255).% 天降福星，您喂养坐骑精良草料的过程中，坐骑直接升级了。
-define(TIP_HORSE_EQUIP_STREN,                     27256).% 您使用装备换回来的草料增加了坐骑[10]点经验。
-define(TIP_HORSE_STREN_LV_UP,                     27257).% 恭喜，在您不断的喂养下坐骑等级提升了！
-define(TIP_HORSE_REFRESH_ERROR,                   27261).% 坐骑洗练失败
-define(TIP_HORSE_REFRESH_ZERO,                    27262).% 属性值为0，锁定失败
-define(TIP_HORSE_CD_IS_0,                         27263).% cd已清

%% ==========================================================
%% 内功
%% ==========================================================
-define(TIP_ABILITY_NOT_EXIST,                     11001).% 奇门不存在
-define(TIP_ABILITY_EXP_NOT_ENOUGH,                11002).% 您的功勋不足，可通过【妖魔破】、【巡城】获取
-define(TIP_ABILITY_LV_NOT_ENOUGH,                 11003).% 等级不足，奇门尚未开放
-define(TIP_ABILITY_IN_CD,                         11004).% 冷却时间中
-define(TIP_ABILITY_LV_NOT_OPEN,                   11005).% 奇门等级不能超过人物等级
-define(TIP_ABILITY_MONEY_NOT_ENOUGH,              11006).% 您的铜钱不足，可通过【商路】【夺铜钱】大量获取
-define(TIP_ABILITY_LV_UPGRADE,                    11007).% [0]等级提升
-define(TIP_ABILITY_GOODS_NOT_ENOUGH,              11008).% 您没有[10]，无法升级
-define(TIP_ABILITY_NOT_OPEN,                      11014).% 对应八门未开启

%% ==========================================================
%% 阵法
%% ==========================================================
-define(TIP_CAMP_NOT_EXIST,                        11501).% 阵法不存在
-define(TIP_CAMP_EXP_NOT_ENOUGH,                   11502).% 您的功勋不足，可通过【妖魔破】、【巡城】获取
-define(TIP_CAMP_LV_NOT_OPEN,                      11503).% 阵法等级不能超过人物等级
-define(TIP_CAMP_LV_NOT_ENOUGH,                    11504).% 阵法等级不能超过人物等级
-define(TIP_CAMP_GOODS_NOT_ENOUGH,                 11505).% 你没有对应的阵法升级书，无法继续升级
-define(TIP_CAMP_PARTNER_NOT_EXIST,                11506).% 名将不存在
-define(TIP_CAMP_SOURCE_NULL,                      11507).% 源位置为空
-define(TIP_CAMP_DEST_ILLEGAL,                     11508).% 目标位置不可站
-define(TIP_CAMP_REMOVE_FAIL,                      11509).% 站位移除失败
-define(TIP_CAMP_LV_MAX,                           11510).% 阵法等级已经最高
-define(TIP_CAMP_SET_FAIL,                         11511).% 设置阵法失败
-define(TIP_CAMP_READ_FAIL,                        11512).% 读取阵法失败
-define(TIP_CAMP_SELF,                             11513).% 无法移除主角
-define(TIP_CAMP_ALREADY_IN_CAMP,                  11514).% 已经在阵法中
-define(TIP_CAMP_NOT_FOR_ASSIST,                   11515).% 副将不允许
-define(TIP_CAMP_NOT_OPENED_POSITION,              11516).% 该位置不可站

%% ==========================================================
%% 破阵
%% ==========================================================

%% ==========================================================
%% 修炼
%% ==========================================================
-define(TIP_PRACTICE_NOW,                          16001).% 正在修行
-define(TIP_PRACTICE_YOURSELF,                     16002).% 无法邀请自己对饮
-define(TIP_PRACTICE_DOUBLE_NOW,                   16003).% 正在对饮
-define(TIP_PRACTICE_MEM_DOUBLE_NOW,               16004).% 对方正在对饮
-define(TIP_PRACTICE_MEM_DOUBLE_ERROR,             16005).% 对方现在无法进行对饮
-define(TIP_PRACTICE_DOUBLE_CANCEL_NAME,           16006).% [10]取消对饮
-define(TIP_PRACTICE_ERROR,                        16101).% 当前无法修行
-define(TIP_PRACTICE_MAP,                          16102).% 对方不在同一主城，无法对饮
-define(TIP_PRACTICE_MAP_ERROR,                    16103).% 当前场景不能修行
-define(TIP_PRACTICE_DOUBLE_SUCCESS,               16104).% 对饮成功
-define(TIP_PRACTICE_NO_DATA,                      16105).% 无修行数据
-define(TIP_PRACTICE_REQUEST,                      16106).% 成功发送请求
-define(TIP_PRACTICE_REJECT,                       16107).% [10]拒绝与你同饮
-define(TIP_PRACTICE_SINGLE_CANCEL,                16108).% 取消修行
-define(TIP_PRACTICE_DOUBLE_CANCEL,                16109).% 取消对饮
-define(TIP_PRACTICE_AUTO_FAIL,                    16111).% 离线修炼设置失败
-define(TIP_PRACTICE_AUTO_SUCCESS,                 16112).% 离线修炼设置成功
-define(TIP_PRACTICE_AUTO_CANCEL_SUCCESS,          16113).% 取消离线设置成功
-define(TIP_PRACTICE_AUTO_PLEASE_SET,              16114).% 请先进行离线修行设置
-define(TIP_PRACTICE_DATA_ERROR,                   16200).% 对方已下线
-define(TIP_PRACTICE_TIME_FULL,                    16201).% 今日已完成修行
-define(TIP_PRACTICE_MEM_TIME_FULL,                16202).% 对方已完成修行

%% ==========================================================
%% 好友
%% ==========================================================
-define(TIP_RELATIONSHIP_GOT_RELATIONSHIP,         14001).% 关系已经存在
-define(TIP_RELATIONSHIP_MAXIMUM,                  14002).% 好友已达上限！
-define(TIP_RELATIONSHIP_NO_RELATIONSHIP,          14004).% 关系不存在
-define(TIP_RELATIONSHIP_FRIENDS,                  14005).% 存在好友关系
-define(TIP_RELATIONSHIP_BLACKLIST,                14006).% 您已被该玩家加入黑名单！
-define(TIP_RELATIONSHIP_FRIENDS_FULL,             14007).% 好友数已满！
-define(TIP_RELATIONSHIP_OK,                       14008).% 成功添加好友
-define(TIP_RELATIONSHIP_REJUSE,                   14009).% [10]拒绝加您为好友

-define(TIP_RELATIONSHIP_AGREE,                    14010).% [10]同意加您为好友
-define(TIP_RELATIONSHIP_NOT_FRIEND,               14011).% 双方不是互为好友
-define(TIP_RELATIONSHIP_NOT_DOUBLE_FRIEND,        14012).% 对方没加你为好友
-define(TIP_RELATIONSHIP_NOT_BLESSABLE,            14013).% 该战场不可祝福
-define(TIP_RELATIONSHIP_BLESS_TIMES_OVER,         14014).% 今天祝福次数已用完
-define(TIP_RELATIONSHIP_BEBLESSED_TIMES_OVER,     14015).% 对方被祝福次数已用完
-define(TIP_RELATIONSHIP_IS_OVER,                  14016).% 该祝福已经过期
-define(TIP_RELATIONSHIP_LV_TOO_LOW_TO_GET_EXP,    14017).% 还没到领取等级
-define(TIP_RELATIONSHIP_SEND_OK,                  14018).% 发送邀请成功
-define(TIP_RELATIONSHIP_OK_TO_ADD_BLACKLIST,      14019).% 成功添加黑名单
-define(TIP_RELATIONSHIP_BLESS_OK,                 14020).% 祝福成功，获取[10]点经验
-define(TIP_RELATIONSHIP_MAX_BLACK_LIST,           14021).% 黑名单已达上限
-define(TIP_RELATIONSHIP_BLESSED,                  14022).% 已发送祝福
-define(TIP_RELATIONSHIP_NO_EXP,                   14023).% 没有可领取的经验
-define(TIP_RELATIONSHIP_GET_EXP_OK,               14024).% 您领取了[10]点祝福瓶经验，VIP额外加成经验[10]点。

%% ==========================================================
%% 副本
%% ==========================================================
-define(TIP_COPY_SINGLE_TIME_IS_OVER,              13001).% 进入战场次数已满
-define(TIP_COPY_SINGLE_PREV_FIRST,                13002).% 前置战场未通过
-define(TIP_COPY_SINGLE_NOT_EXIST,                 13003).% 战场不存在
-define(TIP_COPY_SINGLE_HAD_GOT,                   13004).% 奖励已领取
-define(TIP_COPY_SINGLE_NOTHING,                   13005).% 没有奖励
-define(TIP_COPY_SINGLE_PROCESS_NOT_ARRIVED,       13006).% 进度还没到
-define(TIP_COPY_SINGLE_ALREADY_EXIT,              13007).% 已经退出战场
-define(TIP_COPY_SINGLE_STATE,                     13008).% 玩家状态不对，无法退出
-define(TIP_COPY_SINGLE_NOT_CUR_MON,               13009).% 怪物数据错误
-define(TIP_COPY_SINGLE_NOT_IN_COPY,               13010).% 不在战场中
-define(TIP_COPY_SINGLE_ALREADY_IN,                13011).% 已在战场中
-define(TIP_COPY_SINGLE_NO_CAN_RAID,               13012).% 没有可以扫荡的战场
-define(TIP_COPY_SINGLE_RESETED,                   13013).% 战场重置次数已用完
-define(TIP_COPY_SINGLE_NO_RESET,                  13014).% 没有可以重置的战场
-define(TIP_COPY_SINGLE_NOT_OPEN,                  13015).% 副本未开启

%% ==========================================================
%% 商路
%% ==========================================================
-define(TIP_COMMERCE_SPEEDUP_NOCASH,               30501).% 元宝不足
-define(TIP_COMMERCE_HIGHEST_QUALITY,              30502).% 品质达到最大，无需刷新
-define(TIP_COMMERCE_DEFEAT_ROBBER,                30503).% [10]对您进行打劫，被您英勇地击退

-define(TIP_COMMERCE_ROBBED,                       30504).% [10]打劫了您的[10]，点击此处查看战报

-define(TIP_COMMERCE_MYSELF,                       30505).% 无法对自己的商品进行打劫
-define(TIP_COMMERCE_ROB_OVER,                     30506).% 打劫次数不足
-define(TIP_COMMERCE_HAVE_ROBBED,                  30507).% 您已打劫过此商品
-define(TIP_COMMERCE_ROBBED_OVER,                  30508).% 该商品已没有可打劫次数
-define(TIP_COMMERCE_CD_NOCASH,                    30509).% 元宝不足
-define(TIP_COMMERCE_ROB_SUCCEED,                  30510).% 打劫成功，获得XX铜钱，XX声望
-define(TIP_COMMERCE_ROB_FAIL,                     30511).% 该商品已运送完毕,打劫失败
-define(TIP_COMMERCE_INVITE_ESCORT,                30512).% 您的好友[10]邀请您护送商品，是否护送？
-define(TIP_COMMERCE_ESCORTING,                    30513).% 该好友正在护送其他商品
-define(TIP_COMMERCE_ESCORT_START,                 30514).% 你为[10]护送的商品出发了！
-define(TIP_COMMERCE_ESCORT_OVER,                  30515).% 你为[10]护送的货物顺利到达了，获得[10]铜钱！
-define(TIP_COMMERCE_NO_ROB_TIMES,                 30516).% 购买次数达到上限，提高VIP等级可增加购买次数
-define(TIP_COMMERCE_BUY_ROB_TIMES,                30517).% 购买成功
-define(TIP_COMMERCE_BUY_ROB_TIPS,                 30518).% 是否要消耗XX元宝购买1次打劫次数？
-define(TIP_COMMERCE_NOCASH,                       30519).% 元宝不足
-define(TIP_COMMERCE_CARRY_BROADCAST,              30520).% [0]雄赳赳气昂昂的押着[10]出发了，大家快去瞧瞧啊！[10]
-define(TIP_COMMERCE_ROB_BROADCAST,                30521).% [0]跑商时，连续抵抗了[10]次打劫，真的是武艺高强啊！
-define(TIP_COMMERCE_MARKET_BROADCAST,             30522).% [0]大发善心，为大家建造市场，大家快去跑商啊！
-define(TIP_COMMERCE_CARRY_OVER,                   30523).% 该商品已运送完毕,加速失败
-define(TIP_COMMERCE_CARRYING,                     30524).% 正在运送中
-define(TIP_COMMERCE_ROB_CD_TIME,                  30525).% 打劫冷却中
-define(TIP_COMMERCE_ROBBED_FAIL,                  30526).% 您对[10]进行打劫，被成功击退！
-define(TIP_COMMERCE_ROBBED_SUCCEED,               30527).% [10]打劫了您的[10]，点击此处查看战报！
-define(TIP_COMMERCE_CARRY_START,                  30528).% [10]已经开始了运送商品！
-define(TIP_COMMERCE_MARKET_EXIST,                 30529).% 市场已成功建造
-define(TIP_COMMERCE_CARRY_INCOME,                 30530).% 商队成功到达，获得[10]铜钱。
-define(TIP_COMMERCE_CARRY_BATTLING,               30531).% 该商品正在被打劫
-define(TIP_COMMERCE_FRIEND,                       30532).% 不能打劫自己护送的商队
-define(TIP_COMMERCE_REFRESH_SUCCESS,              30533).% 采购商品品质提升成功
-define(TIP_COMMERCE_REFRESH_FAIL,                 30534).% 采购商品品质提升失败
-define(TIP_COMMERCE_GUILD_READY_BROADCAST30,      30551).% 军团商路将在30分钟后开放，军团成员即可参与，获取大量奖励！
-define(TIP_COMMERCE_GUILD_READY_BROADCAST10,      30552).% 军团商路将在10分钟后开放，军团成员即可参与，获取大量奖励！
-define(TIP_COMMERCE_GUILD_READY_BROADCAST5,       30553).% 军团商路将在5分钟后开放，军团成员即可参与，获取大量奖励！
-define(TIP_COMMERCE_GUILD_READY_BROADCAST1,       30554).% 军团商路将在1分钟后开放，军团成员即可参与，获取大量奖励！
-define(TIP_COMMERCE_GUILD_START_BROADCAST,        30555).% 军团商路已经开放，军团成员即可参与，获取大量奖励！
-define(TIP_COMMERCE_OPEN,                         30556).% 军团商路已经开放，所有军团成员都可参与活动，并获得大量奖励！
-define(TIP_COMMERCE_CLOSE,                        30557).% 军团商路已经关闭，敬请期待下次开放！
-define(TIP_COMMERCE_INVITE_OVERDURE,              30558).% 邀请已过时，请好友再次邀请
-define(TIP_COMMERCE_IGNORE_INVITE,                30559).% 您邀请护送的玩家已忽略所有请求
-define(TIP_COMMERCE_BUILD_MARKET_SUCCESS,         30560).% 建造市场成功，获得[10]功勋
-define(TIP_COMMERCE_CARRY_NO_TIMES,               30561).% 派遣商队次数已达上限
-define(TIP_COMMERCE_ESCORT_NO_TIMES,              30562).% 对方护送次数已达上限
-define(TIP_COMMERCE_ESCORT_NOT_TIMES,             30563).% 护送次数已达上限
-define(TIP_COMMERCE_CARRY_INCOME1,                30564).% [10]获得了[10]铜钱[10]历练！
-define(TIP_COMMERCE_ESCORT_OVER1,                 30565).% 你为[10]护送的货物顺利到达了，获得[10]铜钱[10]历练！

%% ==========================================================
%% 排行榜
%% ==========================================================
-define(TIP_RANK_LV_ONE,                           21001).% [0]勇猛精进，荣登等级榜第一名！
-define(TIP_RANK_LV_TWO,                           21002).% [0]勇猛精进，荣登等级榜第二名！
-define(TIP_RANK_LV_THREE,                         21003).% [0]勇猛精进，荣登等级榜第三名！
-define(TIP_RANK_POSITION_ONE,                     21004).% [0]勇猛精进，荣登官衔榜第一名！
-define(TIP_RANK_POSITION_TWO,                     21005).% [0]勇猛精进，荣登官衔榜第二名！
-define(TIP_RANK_POSITION_THREE,                   21006).% [0]勇猛精进，荣登官衔榜第三名！
-define(TIP_RANK_POWER_ONE,                        21007).% [0]勇猛精进，荣登战力榜第一名！
-define(TIP_RANK_POWER_TWO,                        21008).% [0]勇猛精进，荣登战力榜第二名！
-define(TIP_RANK_POWER_THREE,                      21009).% [0]勇猛精进，荣登战力榜第三名！
-define(TIP_RANK_GUILD_ONE,                        21010).% [10]军团勇猛精进，荣登军团榜第一名！
-define(TIP_RANK_GUILD_TWO,                        21011).% [10]军团勇猛精进，荣登军团榜第二名！
-define(TIP_RANK_GUILD_THREE,                      21012).% [10]军团勇猛精进，荣登军团榜第三名！
-define(TIP_RANK_GENERAL_COPY_ONE,                 21013).% [0]勇猛精进，荣登普通战场榜第一名！
-define(TIP_RANK_GENERAL_COPY_TWO,                 21014).% [0]勇猛精进，荣登普通战场榜第二名！
-define(TIP_RANK_GENERAL_COPY_THREE,               21015).% [0]勇猛精进，荣登普通战场榜第三名！
-define(TIP_RANK_ELITE_COPY_ONE,                   21016).% [0]勇猛精进，荣登英雄战场榜第一名！
-define(TIP_RANK_ELITE_COPY_TWO,                   21017).% [0]勇猛精进，荣登英雄战场榜第二名！
-define(TIP_RANK_ELITE_COPY_THREE,                 21018).% [0]勇猛精进，荣登英雄战场榜第三名！
-define(TIP_RANK_DEVIL_COPY_ONE,                   21019).% [0]勇猛精进，荣登破阵战场榜第一名！
-define(TIP_RANK_DEVIL_COPY_TWO,                   21020).% [0]勇猛精进，荣登破阵战场榜第二名！
-define(TIP_RANK_DEVIL_COPY_THREE,                 21021).% [0]勇猛精进，荣登破阵战场榜第三名！
-define(TIP_RANK_VIP_ONE,                          21031).% [0]勇猛精进，荣登vip英雄榜第一名！
-define(TIP_RANK_VIP_TWO,                          21032).% [0]勇猛精进，荣登vip英雄榜第二名！
-define(TIP_RANK_VIP_THREE,                        21033).% [0]勇猛精进，荣登vip英雄榜第三名！
-define(TIP_RANK_EQUIP_ONE,                        21034).% [0]勇猛精进，荣登装备英雄榜第一名！
-define(TIP_RANK_EQUIP_TWO,                        21035).% [0]勇猛精进，荣登装备英雄榜第二名！
-define(TIP_RANK_EQUIP_THREE,                      21036).% [0]勇猛精进，荣登装备英雄榜第三名！
-define(TIP_RANK_PARTNER_ONE,                      21037).% [0]的[10]，荣登武将英雄榜第一名！
-define(TIP_RANK_PARTNER_TWO,                      21038).% [0]的[10]，荣登武将英雄榜第二名！
-define(TIP_RANK_PARTNER_THREE,                    21039).% [0]的[10]，荣登武将英雄榜第三名！
-define(TIP_RANK_GUILD_POWER_ONE,                  21040).% [10]军团勇猛精进，荣登军团战力英雄榜第一名！
-define(TIP_RANK_GUILD_POWER_TWO,                  21041).% [10]军团勇猛精进，荣登军团战力英雄榜第二名！
-define(TIP_RANK_GUILD_POWER_THREE,                21042).% [10]军团勇猛精进，荣登军团战力英雄榜第三名！
-define(TIP_RANK_SINGLE_ARENA_ONE,                 21043).% [0]勇猛精进，荣登竞技场英雄榜第一名！
-define(TIP_RANK_SINGLE_ARENA_TWO,                 21044).% [0]勇猛精进，荣登竞技场英雄榜第二名！
-define(TIP_RANK_SINGLE_ARENA_THREE,               21045).% [0]勇猛精进，荣登竞技场英雄榜第三名！
-define(TIP_RANK_ARENA_ONE,                        21046).% [0]勇猛精进，荣登战群雄英雄榜第一名！
-define(TIP_RANK_ARENA_TWO,                        21047).% [0]勇猛精进，荣登战群雄英雄榜第二名！
-define(TIP_RANK_ARENA_THREE,                      21048).% [0]勇猛精进，荣登战群雄英雄榜第三名！
-define(TIP_RANK_HORSE_ONE,                        21049).% [0]的[10]，荣登坐骑战力榜第一名！
-define(TIP_RANK_HORSE_TWO,                        21050).% [0]的[10]，荣登坐骑战力榜第二名！
-define(TIP_RANK_HORSE_THREE,                      21051).% [0]的[10]，荣登坐骑战力榜第三名！

%% ==========================================================
%% 一骑讨
%% ==========================================================
-define(TIP_SINGLE_ARENA_CD,                       31001).% 挑战冷却中
-define(TIP_SINGLE_ARENA_NO_TIMES,                 31002).% 没有可挑战次数
-define(TIP_SINGLE_ARENA_LIST_CHANGE,              31003).% 挑战列表已更新
-define(TIP_SINGLE_ARENA_NOT_OPEN,                 31004).% 竞技场未开启
-define(TIP_SINGLE_ARENA_TIMES_NOT_USE,            31005).% 挑战次数未用完
-define(TIP_SINGLE_ARENA_BUY_TIMES_OVER,           31006).% 购买次数用完
-define(TIP_SINGLE_ARENA_STREAK_NOT_ENOUGH,        31007).% 每日24点当日连胜数刷新，此奖励已过期。
-define(TIP_SINGLE_ARENA_VIP_NOT_ENOUGH,           31008).% VIP等级不足
-define(TIP_SINGLE_ARENA_BUY_TIMES_OK,             31009).% 购买成功
-define(TIP_SINGLE_ARENA_PLAY_FAIL,                31010).% 在进行其他玩法，无法挑战
-define(TIP_SINGLE_ARENA_RANK_REWARD_FAIL,         31011).% 排行奖励已领取或过期
-define(TIP_SINGLE_ARENA_WIN_STREAK_10,            31012).% [10]在竞技场中大杀四方，已取得10连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_WIN_STREAK_15,            31013).% [10]在竞技场中无人能挡，已取得15连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_WIN_STREAK_20,            31014).% [10]在竞技场中杀戮无双，已取得20连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_WIN_STREAK_25,            31015).% [10]在竞技场中杀人盈野，已取得25连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_WIN_STREAK_30,            31016).% [10]在竞技场中已杀戮成神，已取得30连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_WIN_STREAK_OVER_30,       31017).% [10]在竞技场中已超越神之杀戮，已取得[10]连胜，快来终结他吧！
-define(TIP_SINGLE_ARENA_BATTLE_WIN,               31018).% [0]大发神威击败[0],竞技场排名上升到第[10]!
-define(TIP_SINGLE_ARENA_SCORE_NOT_ENOUGH,         31019).% 竞技场积分不足
-define(TIP_SINGLE_ARENA_GOODS_NOT_EXISTS,         31020).% 兑换物品不存在

%% ==========================================================
%% 闯塔
%% ==========================================================
-define(TIP_TOWER_OPEN_LEVELNOENOUGH,              31501).% 等级没有达到要求，无法进入破阵
-define(TIP_TOWER_CAMP_DISABLE,                    31502).% 请先通关上一个阵法
-define(TIP_TOWER_CAMP_MAXPASS,                    31503).% 此阵已达最高关卡
-define(TIP_TOWER_CAMP_AWARD,                      31504).% 成功领取破阵奖励
-define(TIP_TOWER_BROADCAST,                       31505).% [0]以雷霆万钧之势冲破[10]，尽显王者风范！
-define(TIP_TOWER_SWEEP_OVER,                      31506).% 扫荡已完成
-define(TIP_TOWER_CARD_NOT_PASS,                   31507).% 尚未通关，无法领取
-define(TIP_TOWER_REWARD_NOT_EXIST,                31508).% 奖励已领取
-define(TIP_TOWER_RESET_OVER,                      31509).% 重置次数不足
-define(TIP_TOWER_RESET_SUCCESS,                   31510).% 重置成功
-define(TIP_TOWER_DIVINE_MAX,                      31511).% 已经占卜到最高级
-define(TIP_TOWER_DIVINE_SUCCESS,                  31512).% 占卜成功
-define(TIP_TOWER_DIVINE_FAIL,                     31513).% 占卜失败
-define(TIP_TOWER_SPEED_SUCCESS,                   31514).% 加速成功
-define(TIP_TOWER_IN_SWEEP_STATE,                  31515).% 扫荡中，无法破阵
-define(TIP_TOWER_SWEEP_TIMES_OVER,                31516).% 没有需要扫荡的关卡
-define(TIP_TOWER_ENTER_FAIL,                      31517).% 请重置后继续破阵
-define(TIP_TOWER_ALL_OVER,                        31518).% 破阵已通关
-define(TIP_TOWER_UNABLE_ENTER,                    31519).% 在其它玩法中，请稍后破阵
-define(TIP_TOWER_NOT_RESET,                       31520).% 没有需要扫荡的关卡,无法重置
-define(TIP_TOWER_NOTICE_GOODS,                    31521).% [0]人品爆发，从[10]第[10]关中获得[1]，真是可喜可贺
-define(TIP_TOWER_NOTICE_GOODS_EQUIP,              31522).% [0]人品爆发，从[10]第[10]关中获得[2]，真是可喜可贺
-define(TIP_TOWER_BROADCAST1,                      31523).% [0]以雷霆万钧之势冲破[10]，尽显王者风范！

%% ==========================================================
%% 多人玩法组队
%% ==========================================================
-define(TIP_TEAM_ALREADY_IN_TEAM,                  32001).% 已在队伍中
-define(TIP_TEAM_NO_IN,                            32002).% 没有队伍
-define(TIP_TEAM_NO_THIS_TEAM,                     32003).% 队伍不存在
-define(TIP_TEAM_NO_CAMP,                          32004).% 当前阵法等级不足，无法创建队伍
-define(TIP_TEAM_PLAYER_ALREADY_IN_TEAM,           32005).% [0]已在其他队伍中！
-define(TIP_TEAM_ALREADY_EXIST,                    32006).% 队伍已经存在
-define(TIP_TEAM_IS_FULL,                          32007).% 队伍已满
-define(TIP_TEAM_REPEAT_INVITE,                    32008).% 目前已发送有效邀请，不必重复发送！
-define(TIP_TEAM_NOT_LEADER,                       32009).% 您不是队长
-define(TIP_TEAM_INVITE_SUCCESS,                   32010).% 邀请发送成功！
-define(TIP_TEAM_LEADER_REMOVE,                    32011).% 您被队长踢出队伍
-define(TIP_TEAM_SOMEONE_NOT_READY,                32012).% 队员[0]尚未准备，不能开始！
-define(TIP_TEAM_REPLY_TIMEOUT_NOTICE,             32013).% 您发送给[0]的邀请已过期！
-define(TIP_TEAM_NO_SAME_TEAM,                     32014).% 不在同一个队伍当中
-define(TIP_TEAM_REPLY_REJECT_NOTICE,              32015).% [0]拒绝了您的邀请!
-define(TIP_TEAM_REPLY_AGREE_NOTICE,               32016).% [0]同意加入
-define(TIP_TEAM_NOT_TEAM_PLAY,                    32017).% 不在多人玩法中
-define(TIP_TEAM_POSITION_COUNT_LESS,              32018).% 阵法站位不足
-define(TIP_TEAM_NO_FIT_TEAM,                      32019).% 没有合适的队伍
-define(TIP_TEAM_NOT_FIT,                          32020).% 无法加入队伍
-define(TIP_TEAM_ALREADY_START,                    32021).% 队伍已经开始
-define(TIP_TEAM_BAD_COPY_ID,                      32022).% 请先选择战场
-define(TIP_TEAM_ERR_IN_QUIT,                      32023).% 退出队伍时发生未知错误
-define(TIP_TEAM_PLAYER_OFFLINE,                   32024).% 该玩家已离线，无法邀请
-define(TIP_TEAM_CHANGE_LEADER_NOTICE,             32025).% 队长成功转移给[0]！
-define(TIP_TEAM_REPLY_TIMEOUT,                    32026).% 邀请已过期！
-define(TIP_TEAM_NO_CAMP_CREATE,                   32030).% 当前阵法等级不足，无法创建队伍！
-define(TIP_TEAM_NO_CAMP_CHANGE_LEADER,            32031).% 该队员默认阵法等级不足，无法转移队长！
-define(TIP_TEAM_NO_CAMP_SET_CAMP,                 32032).% 该阵法等级不足，无法使用！
-define(TIP_TEAM_PUBLISH_MULTI_COPY,               32033).% [0]创建了团队战场的[10]的队伍，赶紧加入吧！[10]
-define(TIP_TEAM_PUBLISH_INVASION,                 32034).% [0]创建了异民族的[10]的队伍，赶紧加入吧！[10]
-define(TIP_TEAM_PUBLISH_MULTI_ARENA,              32035).% [0]创建了异民族的的队伍，赶紧加入吧！[10]
-define(TIP_TEAM_BAD_PASSWORD,                     32036).% 房间密码错误！
-define(TIP_TEAM_MEMBER_NOT_OPEN_COPY,             32037).% 队员未开启该副本
-define(TIP_TEAM_DISMISS,                          32038).% 队伍被队长解散
-define(TIP_TEAM_AUTHOR_IN_CD,                     32039).% 正在冷却，请邀请其他玩家替身
-define(TIP_TEAM_IS_AUTHOR_PLAYER,                 32040).% 无法对替身进行该操作！
-define(TIP_TEAM_REAL_IN_TEAM,                     32041).% 该玩家已在这个房间，不能邀请此玩家的替身
-define(TIP_TEAM_AUTHOR_IN_TEAM,                   32042).% 该玩家替身已经在队伍中
-define(TIP_TEAM_IS_CROSS_PLAYER,                  32043).% 不能将队长转让给跨服玩家！

%% ==========================================================
%% 福利
%% ==========================================================
-define(TIP_WELFARE_RECEIVED,                      33001).% 礼包已经领取！
-define(TIP_WELFARE_NOT_EXIST,                     33002).% 礼包不存在！
-define(TIP_WELFARE_BROADCAST,                     33003).% 恭喜[10]玩家在[10]活动中获得了[10]礼券！
-define(TIP_WELFARE_UNFIT,                         33004).% 礼包未生效！
-define(TIP_WELFARE_LOGIN_SIGN_IS_MAX,             33005).% 今日补签次数已满！
-define(TIP_WELFARE_GET_DEPOSIT,                   33006).% [0]领取了[10]，得到了多种诱人的道具，[10]吧！

-define(TIP_WELFARE_GET_GIFT,                      33007).% [0]领取了[10]活动大礼包，获得高额奖励,请[10]吧！
-define(TIP_WELFARE_GO,                            33008).% 快去看看
-define(TIP_WELFARE_HAD_BOUGHT,                    33009).% 已经购买
-define(TIP_WELFARE_BUY_OK,                        33010).% 购买成功
-define(TIP_WELFARE_NX_FUND,                       33011).% 该类型基金不存在
-define(TIP_WELFARE_MAKE_DEAL1,                    33012).% 恭喜你投资白银基金成功，接下来7天内你持续获得基金的元宝分红
-define(TIP_WELFARE_MAKE_DEAL2,                    33013).% 恭喜你投资白金基金成功，接下来14天内你持续获得基金的元宝分红
-define(TIP_WELFARE_MAKE_DEAL3,                    33014).% 恭喜你投资钻石基金成功，接下来21天内你持续获得基金的元宝分红
-define(TIP_WELFARE_MAKE_DEAL4,                    33015).% 恭喜你投资至尊基金成功，接下来28天内你持续获得基金的元宝分红

%% ==========================================================
%% 招财
%% ==========================================================
-define(TIP_RUNE_1,                                34001).% 元宝不足，请充值
-define(TIP_RUNE_2,                                34002).% 今日没有可招财次数
-define(TIP_RUNE_3,                                34003).% 获得XXXXXXXX铜钱
-define(TIP_RUNE_4,                                34004).% 消耗XX元宝可招财10次，获得XXXX铜钱
-define(TIP_RUNE_5,                                34005).%  封赏品质提升成功
-define(TIP_RUNE_6,                                34006).% 封赏品质提升失败
-define(TIP_RUNE_7,                                34007).% 您打开了XX 封赏，获得了XXX物品

%% ==========================================================
%% 军团
%% ==========================================================
-define(TIP_GUILD_CREATE,                          15001).% 创建成功
-define(TIP_GUILD_CREATE_SUCCESS,                  15002).% [10]创建[10]军团成功
-define(TIP_GUILD_DISBAND_NUM,                     15003).% 军团成员多于3人，不能直接解散军团
-define(TIP_GUILD_EXPLOIT_RANK,                    15004).% 军团贡献不足，无法提升
-define(TIP_GUILD_DISBAND_SUCCESS,                 15005).% 您所在军团已经解散
-define(TIP_GUILD_HAD_NO_JOIN,                     15007).% 对方已不在军团
-define(TIP_GUILD_IS_VECH_CHIEF,                   15008).% 对方已经是副团长
-define(TIP_GUILD_NOT_VICE_CHIEF,                  15009).% 该成员不是副团长，无法提升为团长
-define(TIP_GUILD_NOT_PROMOT,                      15010).% 职位已不能提升
-define(TIP_GUILD_JION,                            15101).% 你已经加入军团
-define(TIP_GUILD_CREATE_LV,                       15102).% 等级不足，不能创建军团
-define(TIP_GUILD_CREATE_NAME,                     15103).% 军团名已存在，请重新输入名称
-define(TIP_GUILD_DISBAND,                         15104).% 该军团不存在
-define(TIP_GUILD_APPLY_LV,                        15105).% 等级不足，申请失败
-define(TIP_GUILD_APPLY_FULL,                      15106).% 该军团申请人数已满
-define(TIP_GUILD_IN_APPLY,                        15107).% 已成功申请
-define(TIP_GUILD_NOT_IN_APPLY,                    15108).% 该申请已失效
-define(TIP_GUILD_NOT_CHIEF,                       15109).% 您不是团长
-define(TIP_GUILD_NOT_JION,                        15110).% 尚未加入军团
-define(TIP_GUILD_INVITE_IN,                       15111).% 对方已加入军团
-define(TIP_GUILD_INVITE_WAIT,                     15112).% 邀请已发送
-define(TIP_GUILD_COUNTRY,                         15113).% 国家不同，不能加入该军团0
-define(TIP_GUILD_INVITE_LV,                       15114).% 对方等级不足，不能邀请
-define(TIP_GUILD_INVITE_FULL,                     15115).% 邀请人数已满
-define(TIP_GUILD_NOT_INVITE,                      15116).% 不在邀请中
-define(TIP_GUILD_FULL,                            15117).% 军团人数已满
-define(TIP_GUILD_NOT_LEAVE,                       15118).% 团长无法直接退出
-define(TIP_GUILD_NOT_POS,                         15119).% 对方没有职位，无法解除
-define(TIP_GUILD_JOIN_SUCCESS,                    15120).% 恭喜加入[10]军团
-define(TIP_GUILD_LEAVE_SUCCESS,                   15121).% 成功退出军团
-define(TIP_GUILD_TICK_OUT,                        15122).% 你已被踢出军团
-define(TIP_GUILD_MODIFY,                          15123).% 修改成功
-define(TIP_GUILD_TICK_OUT_SUCCESS,                15124).% 成功踢出该成员
-define(TIP_GUILD_DEFAULT,                         15125).% 已经设置为默认技能
-define(TIP_GUILD_NO_SKILL,                        15126).% 技能还没开启
-define(TIP_GUILD_NO_LEARN_SKILL,                  15127).% 无可学习的技能
-define(TIP_GUILD_NO_EXPLOIT,                      15128).% 军团贡献不足
-define(TIP_GUILD_USER_LV,                         15129).% 人物等级不足
-define(TIP_GUILD_ARMY_LV,                         15130).% 六韬等级不足，请先提升六韬等级
-define(TIP_GUILD_MAGIC_FULL,                      15131).% 该科技已满级
-define(TIP_GUILD_MAGIC_OPEN,                      15132).% 该科技未开放
-define(TIP_GUILD_SKILL_OPEN,                      15133).% 该技能未开放
-define(TIP_GUILD_BUY_SUCCESS,                     15134).% 购买成功
-define(TIP_GUILD_LEVLE_UP_SUCCESS,                15135).% 升级成功
-define(TIP_GUILD_DONA_SUCCESS,                    15136).% 捐献成功，获得[10]贡献
-define(TIP_GUILD_DONATE_FULL,                     15137).% 今天捐献已达上限
-define(TIP_GUILD_DONATE_TYPE,                     15138).% 不能捐献
-define(TIP_GUILD_GET_WELFARE,                     15139).% 已经领取奖励
-define(TIP_GUILD_NO_WELFARE,                      15140).% 无工资可以领取
-define(TIP_GUILD_IMPEACH_YOURSELF,                15150).% 不能弹劾自己
-define(TIP_GUILD_IMPEACH_FAIL,                    15151).% 团长离线未满7天，无法弹劾
-define(TIP_GUILD_POS_FULL,                        15152).% 职位已满
-define(TIP_GUILD_DONATE_CASH,                     15153).% [10]捐献了[10]元宝
-define(TIP_GUILD_NOT_OPEN,                        15201).% 宴会还没开始
-define(TIP_GUILD_NOT_IN,                          15202).% 不在宴会中
-define(TIP_GUILD_MEM_CANCEL_APPLY,                15203).% 对方已取消申请
-define(TIP_GUILD_STATE_NOT_JOIN,                  15204).% 当前无法加入宴会
-define(TIP_GUILD_PLAY_NOT_JOIN,                   15205).% 当前玩法无法加入宴会
-define(TIP_GUILD_PARTY_NOT_JION,                  15301).% 你还没加入宴会
-define(TIP_GUILD_PARTY_DISBAND,                   15302).% 宴会已开始，新建的军团不能参加
-define(TIP_GUILD_PARTY_NOT_START,                 15303).% 宴会还没开始
-define(TIP_GUILD_PARTY_END,                       15304).% 宴会已结束
-define(TIP_GUILD_PARTY_ATMOSPHERE_FULL,           15305).% 气氛值已满
-define(TIP_GUILD_PARTY_OTHER,                     15306).% 你在进行其他活动
-define(TIP_GUILD_PARTY_GUESS_FULL,                15307).% 猜拳次数已满
-define(TIP_GUILD_PARTY_MEM_NOT_JOIN,              15308).% 对方不在宴会
-define(TIP_GUILD_PARTY_MEM_OTHER_GAME,            15309).% 对方在进行其他活动
-define(TIP_GUILD_PARTY_MEM_GUESS_FULL,            15310).% 对方猜拳次数已满
-define(TIP_GUILD_PARTY_GUESS_SEND,                15311).% 你已经猜拳了，请等待对方出拳
-define(TIP_GUILD_PARTY_ROCK_FULL,                 15312).% 摇色子次数已满
-define(TIP_GUILD_PARTY_MEM_ROCK_FULL,             15313).% 对方摇色子次数已满
-define(TIP_GUILD_PARTY_HAD_MEAT,                  15314).% 还可以领取，可不用重置
-define(TIP_GUILD_PARTY_DESK_ERROR,                15315).% 已无可领取的奖励
-define(TIP_GUILD_PARTY_NO_MEAT,                   15316).% 没有奖励可以领取
-define(TIP_GUILD_PARTY_GET_MEAT,                  15317).% 已经领取了奖励
-define(TIP_GUILD_GUESS_TYPE_ERROR,                15318).% 猜拳操作不对
-define(TIP_GUILD_PARTY_REJECT,                    15319).% [10]拒绝你的请求
-define(TIP_GUILD_AUTOMATIC,                       15320).% 已经自动参加宴会
-define(TIP_GUILD_VIP,                             15321).% VIP等级不足
-define(TIP_GUILD_PARTY_READY_BRO1,                15401).% 军团宴会还有10分钟开始
-define(TIP_GUILD_PARTY_READY_BRO2,                15402).% 军团宴会还有3分钟开始
-define(TIP_GUILD_PARTY_READY_BRO3,                15403).% 军团宴会活动已开放
-define(TIP_GUILD_PARTY_START_BROCAST,             15404).% 军团宴会开始
-define(TIP_GUILD_PARTY_END_BROCAST,               15405).% 军团宴会结束
-define(TIP_GUILD_GUESS_WIN,                       15406).% 恭喜[10]成为猜拳大师
-define(TIP_GUILD_ROCK_WIN,                        15407).% 恭喜[10]成为投骰子大师
-define(TIP_GUILD_PARTY_ADD_EXP,                   15408).% 增加[10]经验
-define(TIP_GUILD_PARTY_ADD_SP,                    15409).% 增加[10]体力
-define(TIP_GUILD_PARTY_DOLL_FAIL,                 15410).% 军团宴会替身设置失败
-define(TIP_GUILD_PARTY_DOLL_SUCCESS,              15411).% 军团宴会替身设置成功，替身将自动参加活动。
-define(TIP_GUILD_PARTY_DOLL_STATE,                15412).% 你已经设置替身参加，活动结束可获得奖励。
-define(TIP_GUILD_PARTY_DOLL_CANCEL,               15413).% 取消军团宴会替身成功，返还给您[10]元宝。
-define(TIP_GUILD_PARTY_IS_OPEN,                   15414).% 军团宴会活动进行中，禁止进行替身设置操作。
-define(TIP_GUILD_PARTY_IS_OVER,                   15415).% 军团宴会替身设置失败，今天活动已经结束。
-define(TIP_GUILD_POS_IS_NOT_FIT,                  15416).% 职位不满足，或者已经发生变动
-define(TIP_GUILD_ONLINE,                          15501).% [10]上线了
-define(TIP_GUILD_OFFLINE,                         15502).% [10]下线了
-define(TIP_GUILD_NO_PLAYER,                       15503).% 现在不能邀请对方
-define(TIP_GUILD_NOT_DISTRIBUTE,                  15504).% 分配物品失败
-define(TIP_GUILD_SKILL_FULL,                      15505).% 军团技能已满级
-define(TIP_GUILD_PARTY_DRUM_STATE,                15506).% 你还在惩罚状态中，不能邀请
-define(TIP_GUILD_PARTY_M_DRUM_STATE,              15507).% 对方还在惩罚状态中，不能邀请
-define(TIP_GUILD_INVITE_YOURSELF,                 15508).% 无法邀请自己进行游戏
-define(TIP_GUILD_DEFAULT_ZERO,                    15601).% 默认增加进度为0
-define(TIP_GUILD_PARTY_SEND_SUCCESS,              15602).% 成功向对方发送请求
-define(TIP_GUILD_DESK_REWARD_SUCCESS,             15603).% 参宴成功，获得[10]经验奖励
-define(TIP_GUILD_REFUSE_JOIN,                     15604).% [10]团长不同意你的申请
-define(TIP_GUILD_AUTO_PARTY_FAIL,                 15605).% 自动参宴失败
-define(TIP_GUILD_AUTO_PARTY_SUCCESS,              15606).% 自动参宴成功
-define(TIP_GUILD_PRE_QUIT,                        15607).% [10]提前退出，活动结束
-define(TIP_GUILD_MAGIC_LV,                        15701).% 军团科技等级不足
-define(TIP_GUILD_PROMOTE_NOT_ENOUGH,              15702).% 军团贡献不足，无法提升职位
-define(TIP_GUILD_VICE_TICK,                       15703).% 副团长只能踢出成员
-define(TIP_GUILD_MONEY,                           15704).% 军团资金不足
-define(TIP_GUILD_DEAL_DELETE,                     15705).% 拒绝成功
-define(TIP_GUILD_DEAL_ADD,                        15706).% 添加成功
-define(TIP_GUILD_APPL_NOTICE,                     15707).% [10]申请加入军团
-define(TIP_GUILD_COLD_TIME,                       15708).% 今日尚在军团加入冷却期内，无法加入军团。
-define(TIP_GUILD_M_COLD_TIME,                     15709).% 您邀请的玩家今日尚在军团加入冷却期内，无法加入您的军团。
-define(TIP_GUILD_NAME_LONG,                       15711).% 您输入的军团名字太长
-define(TIP_GUILD_ANNOUNCE_LENGTH,                 15712).% 公告文字过多
-define(TIP_GUILD_APPLY_SUCCESS,                   15715).% 申请成功
-define(TIP_GUILD_APPLY_CANCLE,                    15716).% 成功取消申请
-define(TIP_GUILD_INVITE_SUCCESS,                  15717).% 邀请成功
-define(TIP_GUILD_PROMOT_SUCCESS,                  15718).% 提升成功
-define(TIP_GUILD_CHANGE_CHIEF,                    15719).% 恭喜你被提升为[10]军团团长
-define(TIP_GUILD_VICE_CHIEF,                      15720).% 恭喜你被提升为[10]军团副团长
-define(TIP_GUILD_REMOVE_POS,                      15721).% 解除成功
-define(TIP_GUILD_CHEIF_PROMOTE_SELF,              15722).% 无法提升自己的职位
-define(TIP_GUILD_KICK_OUT_SELF,                   15723).% 无法将自己踢出军团
-define(TIP_GUILD_M_SYS_NOT_OPEN,                  15725).% 对方尚未开启军团
-define(TIP_GUILD_SYS_NOT_OPEN,                    15726).% 军团尚未开放
-define(TIP_GUILD_IMPEACH,                         15727).% 贡献排名不满足，无法弹劾
-define(TIP_GUILD_APPLY_FAILED,                    15728).% 你申请[10]军团资格被他人顶替，请重新申请

%% ==========================================================
%% 世界boss
%% ==========================================================
-define(TIP_BOSS_NOT_OPEN,                         34501).% 妖魔破尚未开启!
-define(TIP_BOSS_CLOSE,                            34502).% 妖魔破已结束!
-define(TIP_BOSS_PLAYER_ABSENT,                    34503).% 玩家未在妖魔破活动中!
-define(TIP_BOSS_DOLL,                             34504).% 已开启自动参战，无法进入!
-define(TIP_BOSS_CD_EXIT,                          34505).% 退出妖魔破活动时间限制!
-define(TIP_BOSS_CD_DEATH,                         34506).% 死亡等待复活！
-define(TIP_BOSS_ENCOURAGE_MAX,                    34507).% 鼓舞达到上限
-define(TIP_BOSS_REBORN_TIMES_MAX,                 34508).% 浴火重生次数达到上限!
-define(TIP_BOSS_DOLL_BAN,                         34509).% 妖魔破已经开启，无法更改自动参战状态！
-define(TIP_BOSS_ENCOURAGE_SUCCESS,                34510).% 鼓舞成功，战斗力[10]%！
-define(TIP_BOSS_OVER_FAIL,                        34511).% 本次妖魔破活动失败，[10]继续肆虐四方，望各位英雄再接再厉，挽江山于既倒！
-define(TIP_BOSS_OVER_WIN,                         34512).% [10]已被成功击退，[0]、[0]、[0]在本次妖魔破活动中战功彪炳，威震四方！
-define(TIP_BOSS_FIRST,                            34513).% [0]英勇无敌，率先对[10]发起攻击，获得[10]铜钱奖励！
-define(TIP_BOSS_KILL,                             34514).% [0]锋芒毕露，一击斩杀[10]，获得[10]铜钱奖励！
-define(TIP_BOSS_IN_START_CD,                      34515).% 正在准备cd中...
-define(TIP_BOSS_IN_REBORN_CD,                     34516).% 正在复活cd中...
-define(TIP_BOSS_IN_BATTLE,                        34517).% 正在战斗中！
-define(TIP_BOSS_HIRE_OK,                          34518).% 设置替身成功，替身将自动参加活动

-define(TIP_BOSS_RETURN_OK,                        34519).% 取消替身参加妖魔破，返还[10]元宝
-define(TIP_BOSS_INIT,                             34601).% 1
-define(TIP_BOSS_GET_BOSS_PLAYER,                  34602).% 1
-define(TIP_BOSS_GET_BOSS,                         34603).% 1
-define(TIP_BOSS_SUAN_YU_BEGIN,                    34604).% 妖魔破已经开放，请英雄入得宫中，击杀上古凶兽酸与！
-define(TIP_BOSS_SUAN_YU_END,                      34605).% 妖魔破已经关闭，敬请期待下次开放！
-define(TIP_BOSS_ZHANG_JIAO_BEGIN,                 34606).% 妖魔破已经开放，请英雄降妖除魔，击败死而复生的张角三兄弟！
-define(TIP_BOSS_ZHANG_JIAO_END,                   34607).% 妖魔破已经关闭，敬请期待下次开放！
-define(TIP_BOSS_CASH_NOT_ENOUGH,                  34608).% 元宝不足，需花费[10]元宝
-define(TIP_BOSS_BLOOD_PHASE1,                     34701).% [10]在[0]的攻击下阵型出现了混乱！
-define(TIP_BOSS_BLOOD_PHASE2,                     34702).% [10]在[0]的强攻下显示出了退却的迹象！
-define(TIP_BOSS_BLOOD_PHASE3,                     34703).% [10]在[0]的猛攻下受到了重创！
-define(TIP_BOSS_BLOOD_PHASE4,                     34704).% [10]在[0]的冲击下正在迅速的溃败中！
-define(TIP_BOSS_AUTO_FAIL,                        34705).% 无法使用替身参战

%% ==========================================================
%% 异民族
%% ==========================================================
-define(TIP_INVASION_NO_TARGET,                    36001).% 城门不存在
-define(TIP_INVASION_NO_HP,                        36002).% 城门血量不同步
-define(TIP_INVASION_NO_COPY,                      36003).% 战场不存在
-define(TIP_INVASION_TIME_IS_RUNNING,              36004).% 时间尚未结束
-define(TIP_INVASION_CLEAR_CD,                     36005).% 清除等待时间成功
-define(TIP_INVASION_OPEN,                         36006).% 异民族活动已经开放，所有成员都可参与活动，并获得大量奖励！
-define(TIP_INVASION_OFF,                          36007).% 异民族活动已经关闭，敬请期待下次开放！
-define(TIP_INVASION_USE_UP,                       36008).% 异民族次数已经用完！
-define(TIP_INVASION_LEVEL_NOT_ENOUGH,             36009).% 玩家等级不足，无法加入队伍！
-define(TIP_INVASION_NO_ACCESS,                    36010).% 异民族活动已经结束，无法进入！
-define(TIP_INVASION_COLLISION,                    36011).% 怪物[10]进攻城门，城门耐久度降低[10]！
-define(TIP_INVASION_KILL,                         36012).% 玩家[10]击杀了[10]！
-define(TIP_INVASION_REFRESH,                      36013).% 怪物[10]刷新了！
-define(TIP_INVASION_DURATION,                     36014).% 城门耐久度降低到了[10]，请加强守护！
-define(TIP_INVASION_KILL_GOODS,                   36015).% 玩家[10]击杀了[10]，获得[1]！
-define(TIP_INVASION_TEN_MINS_BROADCAST,           36016).% 异民族活动将在[10]分钟后开始
-define(TIP_INVASION_KILL_EQUIP_GOODS,             36017).% 玩家[10]击杀了[10]，获得[2]！
-define(TIP_INVASION_NOT_OPEN,                     36020).% 异民族未开启
-define(TIP_INVASION_DOLL_BAN,                     36021).% 异民族已开启，无法更改自动参战状态！
-define(TIP_INVASION_DOLL_FAIL,                    36022).% 无法使用替身参战！
-define(TIP_INVASION_DOLL,                         36023).% 已开启替身参战，无法进入
-define(TIP_INVASION_GET_NOTHING,                  36024).% 次数不够，无法获得奖励
-define(TIP_INVASION_NOTICE_GOODS,                 36025).% [0]人品爆发，从[10]中获得[1]，真是可喜可贺
-define(TIP_INVASION_NOTICE_GOODS_EQUIP,           36026).% [0]人品爆发，从[10]中获得[2]，真是可喜可贺

%% ==========================================================
%% 课程表
%% ==========================================================
-define(TIP_SCHEDULE_1,                            37001).% 背包空间不足，无法领取奖励
-define(TIP_SCHEDULE_2,                            37002).% 该日常指引不可找回！0
-define(TIP_SCHEDULE_3,                            37003).% 该日常指引可找回！0
-define(TIP_SCHEDULE_4,                            37004).% 该礼品不存在！0
-define(TIP_SCHEDULE_5,                            37005).% 已经领取过该礼品！0
-define(TIP_SCHEDULE_SIGN_SUCCESS,                 37006).% 签到成功！
-define(TIP_SCHEDULE_GOODS_REWARD,                 37007).% 恭喜您获得[10]*[10]!
-define(TIP_SCHEDULE_RESOURCE_HAS_GET,             37008).% 资源已找回
-define(TIP_SCHEDULE_RESOURCE_NO_TIMES,            37009).% 资源找回次数不足
-define(TIP_SCHEDULE_RESOURCE_GOLD,                37010).% 资源找回成功,获得[10]铜钱
-define(TIP_SCHEDULE_RESOURCE_EXP,                 37011).% 资源找回成功,获得[10]经验
-define(TIP_SCHEDULE_RESOURCE_MER,                 37012).% 资源找回成功,获得[10]功勋
-define(TIP_SCHEDULE_RESOUCE_ALL_GET,              37013).% 无资源可找回
-define(TIP_SCHEDULE_RESOUCE_ALL_REWARD,           37014).% 资源找回成功,获得[10]铜钱,[10]经验,[10]功勋

%% ==========================================================
%% 新手引导
%% ==========================================================

%% ==========================================================
%% 怪物攻城
%% ==========================================================
-define(TIP_GUILD_SIEGE_1,                         39001).% 已有军团成员向该玩家发起邀请；
-define(TIP_GUILD_SIEGE_2,                         39002).% 该邀请已失效；
-define(TIP_GUILD_SIEGE_3,                         39003).% 该玩家进入时间冷却中，请稍候；
-define(TIP_GUILD_SIEGE_4,                         39004).% 军职级别过低，无法邀请。
-define(TIP_GUILD_SIEGE_5,                         39005).% 没有足够的邀请数。
-define(TIP_GUILD_SIEGE_6,                         39006).% [10]拒绝邀请。
-define(TIP_GUILD_SIEGE_7,                         39007).% 您拒绝了该邀请。
-define(TIP_GUILD_SIEGE_8,                         39008).% 您同意了该邀请。
-define(TIP_GUILD_SIEGE_9,                         39009).% 怪物被击杀。
-define(TIP_GUILD_SIEGE_OFF,                       39011).% 怪物攻城活动尚未开启！
-define(TIP_GUILD_SIEGE_NULL,                      39012).% 您没有加入任何军团！
-define(TIP_GUILD_SIEGE_CD,                        39013).% 冷却时间[10]秒，请稍候进入；
-define(TIP_GUILD_SIEGE_10,                        39014).% 不能重复邀请[10]！
-define(TIP_GUILD_SIEGE_11,                        39015).% [10]已经在军团怪物攻城场景中！
-define(TIP_GUILD_SIEGE_12,                        39016).% 冷却时间[10]秒，请稍候进入；
-define(TIP_GUILD_SIEGE_FIRST,                     39017).% 军团[10]在本次怪物攻城活动中排名第一！
-define(TIP_GUILD_SIEGE_PLAYER_FIRST,              39018).% 玩家[10]在本次怪物攻城活动中伤害排名第一！
-define(TIP_GUILD_SIEGE_PLAYER_SECOND,             39019).% 玩家[10]在本次怪物攻城活动中伤害排名第二！
-define(TIP_GUILD_SIEGE_PLAYER_THIRD,              39020).% 玩家[10]在本次怪物攻城活动中伤害排名第三！
-define(TIP_GUILD_SIEGE_OPEN,                      39021).% 乱天下已经开放，所有玩家可参与玩法，挽江山于既倒，获得丰厚奖励！
-define(TIP_GUILD_SIEGE_CLOSE,                     39022).% 乱天下已经关闭，敬请期待下次开放！

%% ==========================================================
%% 阵营战
%% ==========================================================
-define(TIP_FACTION_HAD_SIGNED,                    40001).% 已经报名

%% ==========================================================
%% 聊天
%% ==========================================================
-define(TIP_CHAT_SHUTUP,                           40501).% 您已被禁言

%% ==========================================================
%% 收益提示
%% ==========================================================
-define(TIP_REWARD_ADD_EXP,                        41001).% 获得  [10]经验
-define(TIP_REWARD_ADD_SP_TEMP,                    41002).% 获得  [10]体力
-define(TIP_REWARD_ADD_HONOUR,                     41003).% 获得  [10]声望
-define(TIP_REWARD_ADD_MERITORIOUS,                41004).% 获得  [10]功勋
-define(TIP_REWARD_ADD_EXPLOIT,                    41005).% 获得  [10]军团贡献
-define(TIP_REWARD_ADD_MIND_SPIRIT,                41006).% 获得  [10]天命
-define(TIP_REWARD_ADD_EXPERIENCE,                 41007).% 获得  [10]历练
-define(TIP_REWARD_ADD_CASH,                       41008).% 获得  [10]元宝
-define(TIP_REWARD_ADD_BIND_CASH,                  41009).% 获得  [10]礼券
-define(TIP_REWARD_ADD_BIND_GOLD,                  41010).% 获得  [10]铜钱
-define(TIP_REWARD_ADD_GOODS,                      41011).% 获得  [10]*[10]
-define(TIP_REWARD_ADD_ARENA_SCORE,                41012).% 获得  [10]群雄积分
-define(TIP_REWARD_ADD_HUFU,                       41013).% 获得  [10]虎符
-define(TIP_REWARD_ADD_BIND_CASH_2,                41014).% 获得 [10]礼券
-define(TIP_REWARD_ADD_BIND_GOLD_2,                41015).% 获得 [10]铜钱
-define(TIP_REWARD_ADD_BIND_CASH_3,                41016).% 获得 [10]绑定元宝

%% ==========================================================
%% 多人竞技场
%% ==========================================================
-define(TIP_ARENA_PVP_READY1,                      44001).% 战群雄活动将在10分钟后开始
-define(TIP_ARENA_PVP_READY2,                      44002).% 战群雄活动将在3分钟后开始
-define(TIP_ARENA_PVP_READY3,                      44003).% 战群雄活动将在1分钟后开始
-define(TIP_ARENA_PVP_ON,                          44004).% 战群雄活动开始
-define(TIP_ARENA_PVP_OFF,                         44005).% 战群雄活动结束
-define(TIP_ARENA_PVP_NOT_OPEN,                    44101).% 战群雄活动还没开启
-define(TIP_ARENA_PVP_NOT_JOIN,                    44102).% 当前不能参加战群雄活动
-define(TIP_ARENA_PVP_TIMES_FULL,                  44103).% 今日挑战次数已经用完，请明日继续参加
-define(TIP_ARENA_PVP_SYS,                         44104).% 玩法未开启，无法参加战群雄活动
-define(TIP_ARENA_PVP_HUFU,                        44105).% 虎符数量不足，不能兑换
-define(TIP_ARENA_PVP_SHOP_DATA,                   44106).% 兑换数据不对
-define(TIP_ARENA_PVP_NOT_LEADER,                  44107).% 不是队长不能点击开始
-define(TIP_ARENA_PVP_NO_TEAM,                     44108).% 正在匹配队伍，请稍等
-define(TIP_ARENA_PVP_TEAM_DATA,                   44109).% 队伍信息错误
-define(TIP_ARENA_PVP_MEM_TIMES,                   44110).% 挑战次数已达上限
-define(TIP_ARENA_PVP_EXCHANGE_SUCCESS,            44111).% 兑换成功
-define(TIP_ARENA_PVP_ACTIVE_OVER,                 44112).% 战群雄活动已经结束
-define(TIP_ARENA_PVP_MATCH_FAIL,                  44113).% 未找到合适的对手，已自动获得胜利

-define(TIP_ARENA_PVP_ADD_SCORE,                   44114).% 恭喜获得[10]群雄积分
-define(TIP_ARENA_PVP_M_SYS,                       44115).% 对方还不能战群雄活动
-define(TIP_ARENA_PVP_M_COUNT,                     44116).% 对方今日挑战次数已经用完
-define(TIP_ARENA_PVP_CROSS_MATCH_FAIL_AWARD,      44117).% 铜钱+[10]，虎符+[10]，连胜+1
-define(TIP_ARENA_PVP_PARTNER_IS_EXCHANGED,        44118).% 该武将已经兑换
-define(TIP_ARENA_PVP_WIN_TIMES_FIVE,              44201).% [10]在战群雄中取得5连胜,已经主宰了比赛!!!
-define(TIP_ARENA_PVP_WIN_TIMES_EIGHT,             44202).% [10]在战群雄中取得10连胜,已经无人能挡!!!
-define(TIP_ARENA_PVP_WIN_TIMES_TEN,               44203).% [10]在战群雄中无人能敌,已经接近神了,拜托谁杀了他吧!!!

%% ==========================================================
%% 多人副本
%% ==========================================================
-define(TIP_MCOPY_TIMES_OVER,                      45001).% 团队战场次数已用完
-define(TIP_MCOPY_BAD,                             45002).% 运气不足，遇到了埋伏
-define(TIP_MCOPY_BOX_EXP,                         45003).% 恭喜你获得了[10]经验
-define(TIP_MCOPY_ALL_BUFF,                        45004).% 恭喜你获得了气血+[10]%,攻击+[10]%,防御+[10]%,速度+[10]%
-define(TIP_MCOPY_BUFF_HP,                         45005).% 恭喜你获得了气血+[10]%

-define(TIP_MCOPY_BUFF_ATT,                        45006).% 恭喜你获得了攻击+[10]%
-define(TIP_MCOPY_BOX_GOLD,                        45007).% 恭喜你获得了[10]铜钱
-define(TIP_MCOPY_BOX_MET,                         45008).% 恭喜你获得了[10]功勋
-define(TIP_MCOPY_BUFF_DEF,                        45009).% 恭喜你获得了防御+[10]%
-define(TIP_MCOPY_BUFF_SPEED,                      45010).% 恭喜你获得了速度+[10]%
-define(TIP_MCOPY_PASS,                            45011).% 恭喜[0]带领队员们通过了[10]
-define(TIP_MCOPY_NOTHING,                         45012).% 很遗憾，没有获得任何奖励
-define(TIP_MCOPY_NOT_OPEN,                        45013).% 该战场尚未开放
-define(TIP_MCOPY_BOX_GOODS,                       45014).% 恭喜你获得了[10]
-define(TIP_MCOPY_FRIEND_NOT_OPEN,                 45015).% 对方未开启此战场,不能邀请组队！
-define(TIP_MCOPY_GET_NOTHING,                     45016).% 玩法次数不足,无法获得奖励
-define(TIP_MCOPY_KILL,                            45017).% 玩家[10]击杀了[10]！
-define(TIP_MCOPY_KILL_GOODS,                      45018).% 玩家[10]击杀了[10]，获得[10]！
-define(TIP_MCOPY_VIP_REWARD,                      45019).% [0]鸿运当头，通关[10]副本获得[1]
-define(TIP_MCOPY_TIP_MCOPY_VIP_EQUIP_REWARD,      45020).% [0]鸿运当头，通关[10]副本获得[2]
-define(TIP_MCOPY_Q_EXP,                           45021).% [10]天资聪颖，从[10]中获得[10]经验
-define(TIP_MCOPY_Q_MET,                           45022).% [10]披荆斩棘，从[10]中获得[10]功勋
-define(TIP_MCOPY_Q_GOLD,                          45023).% 天降横财,[10]从[10]中获得[10]铜钱
-define(TIP_MCOPY_Q_GOODS,                         45024).% [10]人品爆发，从[10]中获得[1]
-define(TIP_MCOPY_Q_GOODS_EQUIP,                   45025).% [10]人品爆发，从[10]中获得[2]
-define(TIP_MCOPY_Q_GOODS1,                        45026).% [10]人品爆发，从[10]中获得[1]
-define(TIP_MCOPY_Q_GOODS_EQUIP1,                  45027).% [10]人品爆发，从[10]中获得[2]

%% ==========================================================
%% 乱天下
%% ==========================================================
-define(TIP_WORLD_BUFF_NOTICE,                     45501).% [0]对乱军造成[10]伤害。国舅董承下令嘉奖犒赏三军。
-define(TIP_WORLD_BEGIN,                           45503).% 乱天下已经开放，所有玩家可参与玩法，挽江山于既倒，获得丰厚奖励！
-define(TIP_WORLD_END,                             45505).% 乱天下已经关闭，敬请期待下次开放！
-define(TIP_WORLD_MONSTER_NOTICE,                  45511).% 第[10]波怪物即将在[10]秒内出现！
-define(TIP_WORLD_KILL_MONSTER_NOTICE,             45521).% [0]成功击杀了[10]，获得了[10]铜钱！
-define(TIP_WORLD_RANK_GUILD_NOTICE,               45531).% [10]在本次乱天下中坚不可摧，堪为所有军团的表率！
-define(TIP_WORLD_RANK_PLAYER_NOTICE,              45541).% 天下纷争告一段落，[0]在本次乱天下中战功显赫，威震天下！
-define(TIP_WORLD_NOT_OPEN,                        45600).% 乱天下尚未开启！
-define(TIP_WORLD_NOT_START,                       45601).% 乱天下尚未开始！
-define(TIP_WORLD_GUILD_NULL,                      45602).% 尚未加入军团！
-define(TIP_WORLD_FULL_QUOTA,                      45603).% 名额已满！
-define(TIP_WORLD_NOT_LEADER,                      45604).% 您不是当前军团的leader！
-define(TIP_WORLD_NOT_GUILD_MEMBER,                45605).% 您不属于当前军团！
-define(TIP_WORLD_NOT_IN_ACTIVE,                   45606).% 未在乱天下活动中！
-define(TIP_WORLD_MONSTER_DEATH,                   45607).% 怪物已经死亡！
-define(TIP_WORLD_MONSTER_ABSENT,                  45608).% 怪物不存在！
-define(TIP_WORLD_CD_EXIT,                         45609).% 退出乱天下冷却时间限制！
-define(TIP_WORLD_CD_DEATH,                        45610).% 死亡冷却时间限制！
-define(TIP_WORLD_GUILD_LV_NOT_ENOUGH,             45611).% 军团等级不足！
-define(TIP_WORLD_OVER,                            45612).% 乱天下已经结束！
-define(TIP_WORLD_INVITE_TIMEOUT,                  45613).% 邀请已过期！
-define(TIP_WORLD_IN_OTHER_GUILD,                  45614).% 该玩家已在其他军团活动中！
-define(TIP_WORLD_REPEAT_INVITE,                   45615).% 已发送有效邀请，不必重复发送！
-define(TIP_WORLD_GET_BUFF,                        45616).% 您获得[0]的犒赏三军，攻击+[10]%！
-define(TIP_WORLD_INVITE_SUCCESS,                  45617).% 邀请发送成功！
-define(TIP_WORLD_REPLY_REJECT_NOTICE,             45618).% [0]拒绝了您的邀请！
-define(TIP_WORLD_MEM_GUILD_NULL,                  45701).% 该玩家尚未加入军团！
-define(TIP_WORLD_MEM_FIGHT,                       45702).% 该玩家正在战斗中，无法接受您的邀请！
-define(TIP_WORLD_MEM_COPY,                        45703).% 该玩家在其它战场中，无法接受您的邀请！
-define(TIP_WORLD_MEM_OFFLINE,                     45704).% 该玩家已下线！
-define(TIP_WORLD_MEM_JION,                        45705).% 该玩家已加入！
-define(TIP_WORLD_ACTIVE_OPEN,                     45706).% 活动已开启，无法设置替身状态
-define(TIP_WORLD_NOT_CANCEL,                      45707).% 不是勾选状态, 不能取消
-define(TIP_WORLD_NOT_CANCEL1,                     45708).% 活动已结束,无法设置替身状态
-define(TIP_WORLD_NO_ENTER,                        45709).% 已设置替身参战,无法进入
-define(TIP_WORLD_SET_SUCCESS,                     45710).% 替身设置成功,消耗[10]元宝
-define(TIP_WORLD_MEM_ROBOT,                       45711).% 该玩家已设置替身参战,无法接受您的邀请
-define(TIP_WORLD_CANCEL_SUCCESS,                  45712).% 替身取消成功,返回[10]元宝

%% ==========================================================
%% 宴会
%% ==========================================================
-define(TIP_PARTY_BOX_REWARD1,                     46001).% [10]鸿运当头，在赐福中获得了[1]！！！
-define(TIP_PARTY_BOX_REWARD2,                     46002).% [10]鸿运当头，在赐福中获得了[2]！！！
-define(TIP_PARTY_BOX_REWARD3,                     46003).% [10]鸿运当头，在赐福中获得奖励！！！
-define(TIP_PARTY_BOX_FINISH,                      46004).% [10]在本次天官赐福中福运绵延，为大家赢得天官赐福的经验奖励！！！
-define(TIP_PARTY_MONSTER_REWARD1,                 46101).% 天降大任，[10]一击斩杀[10]，获得[1]！！！
-define(TIP_PARTY_MONSTER_REWARD2,                 46102).% 天降大任，[10]一击斩杀[10]，获得[2]！！！
-define(TIP_PARTY_MONSTER_REWARD3,                 46103).% 天降大任，[10]一击斩杀[10]
-define(TIP_PARTY_MONSTER_FINISH,                  46104).% [10]在本次活动中战功彪炳，威震四方，为大家赢得异族乱入的经验奖励！！！
-define(TIP_PARTY_MONSTER_EXIST,                   46105).% 异族乱入，入侵[10]军团，成功破坏其宴会！！！
-define(TIP_PARTY_MONSTER_BATTLE_FULL,             46110).% 当前怪物只能同时与五个玩家战斗，请稍候
-define(TIP_PARTY_MONSTER_DEAD,                    46111).% 该怪物已经死亡
-define(TIP_PARTY_OVER,                            46112).% 宴会活动已经结束
-define(TIP_PARTY_NOT_JION,                        46113).% 不在宴会场景
-define(TIP_PARTY_NOT_START,                       46114).% 宴会还没开始
-define(TIP_PARTY_NO_GUILD,                        46115).% 您还没加入军团，不能参加军团宴会
-define(TIP_PARTY_NO_BOX,                          46117).% 很遗憾，该赐福已被领取
-define(TIP_PARTY_AUTO,                            46118).% 您已设置自动参加，宴会结束可以获得奖励
-define(TIP_PARTY_AUTO_FAIL,                       46119).% 自动参加宴会失败
-define(TIP_PARTY_AUTO_SUCCESS,                    46120).% 军团宴会活动中，使用替身参战获得[10]经验和[10]体力奖励
-define(TIP_PARTY_IN_BATTLE,                       46121).% 已经在战斗中
-define(TIP_PARTY_LV,                              46122).% 军团等级不足，不能参加宴会活动
-define(TIP_PARTY_AUTO_START,                      46123).% 军团宴会已经开始，无法更改自动参加状态！
-define(TIP_PARTY_REQUEST_PK,                      46201).% 邀请成功
-define(TIP_PARTY_USER_NOT_PK,                     46202).% 当前在玩法中，无法进行切磋
-define(TIP_PARTY_MEM_NOT_PK,                      46203).% 对方当前在玩法中，无法进行切磋
-define(TIP_PARTY_USER_NOT_IN,                     46204).% 当前不在宴会场景，无法进行切磋
-define(TIP_PARTY_MEM_NOT_IN,                      46205).% 对方当前不在宴会场景，无法进行切磋

%% ==========================================================
%% 活动
%% ==========================================================
-define(TIP_ACTIVE_PRE_MINS,                       46501).% [10]活动将在[10]分钟后开始！
-define(TIP_ACTIVE_PRE_CAN_ENTER,                  46502).% [10]活动将在[10]分钟后开始，你可以提前进入！
-define(TIP_ACTIVE_PRE_MINS_2,                     46503).% [10]活动将在[10]分钟后开始！

%% ==========================================================
%% 好友2
%% ==========================================================
-define(TIP_RELATION_MEM_SYS,                      14501).% 对方未开启好友系统
-define(TIP_RELATION_COUNT,                        14502).% 好友数量已达上限
-define(TIP_RELATION_SYS,                          14503).% 还未开启好友系统
-define(TIP_RELATION_FRIEND,                       14504).% 对方已是您的好友
-define(TIP_RELATION_BEST,                         14505).% 对方已是您的密友
-define(TIP_RELATION_BLACK,                        14506).% 对方已在黑名单
-define(TIP_RELATION_BLACK_COUNT,                  14507).% 黑名单数量已达上限
-define(TIP_RELATION_NOT_FRIEND,                   14511).% 对方已不是您的好友
-define(TIP_RELATION_ONE_KEY_DEL,                  14522).% 删除成功

%% ==========================================================
%% 祝福
%% ==========================================================
-define(TIP_BLESS_NOT_EXIST,                       14801).% 祝福信息已过期
-define(TIP_BLESS_LV,                              14802).% 等级不足，还不能领取祝福经验
-define(TIP_BLESS_COUNT,                           14803).% 今日祝福次数已达上限
-define(TIP_BLESS_EXP,                             14804).% 没有经验可领取
-define(TIP_BLESS_BOTTLE_EXP,                      14805).% 您领取了[10]点祝福瓶经验
-define(TIP_BLESS_ONE_KEY,                         14806).% VIP等级不足，无法使用一键功能
-define(TIP_BLESS_MAX_LV,                          14807).% 等级已达领取祝福经验上限
-define(TIP_BLESS_EXP_NOT_FULL,                    14809).% 经验瓶经验未满，不能领取
-define(TIP_BLESS_HAD_GET_EXP,                     14810).% 你已经领取了祝福经验

%% ==========================================================
%% 阵营战
%% ==========================================================
-define(TIP_CAMP_PVP_NOT_IN_WORKING_STATE,         47002).% 当前状态不能采矿！
-define(TIP_CAMP_PVP_NOT_START,                    47003).% 阵营战尚未开启！
-define(TIP_CAMP_PVP_SUBMIT_SOURCE_SUCCESS,        47004).% 资源提交成功，获得[10]铜钱、[10]积分！
-define(TIP_CAMP_PVP_SUBMIT_SOURCE_FAILED,         47005).% 资源运送失败！
-define(TIP_CAMP_PVP_USER_BATTLING,                47006).% 该玩家正在交战中
-define(TIP_CAMP_PVP_FULL,                         47007).% 活动人数已达上限，暂时无法加入！
-define(TIP_CAMP_PVP_NOT_OPEN,                     47008).% 阵营战尚未开启！
-define(TIP_CAMP_PVP_START,                        47009).% 阵营战已开放，请英雄速速加入，击退敌营！
-define(TIP_CAMP_PVP_END,                          47010).% 阵营战已结束！
-define(TIP_CAMP_PVP_KILL_BOSS,                    47011).% [10]阵营发出演武令，用霹雳火给敌营战车造成沉重的打击！
-define(TIP_CAMP_PVP_KILL_MONSTER,                 47012).% [0]勇猛无匹，将敌营勇士斩于马下！
-define(TIP_CAMP_PVP_HURT_BOSS,                    47013).% [10]阵营勇士只身冲入敌营，大杀四方，让[10]阵营阵型大乱！
-define(TIP_CAMP_PVP_CALL_MONSTER,                 47014).% [10]阵营发出演武令，令营中勇士全力攻打敌方阵营！
-define(TIP_CAMP_PVP_BUFF_REMOVE,                  47015).% [10]营的[10]被毁，全营士气低落，鼓舞状态消失！
-define(TIP_CAMP_PVP_WORKING,                      47016).% 正在采集中！
-define(TIP_CAMP_PVP_DEAD,                         47017).% 玩家已经死亡！
-define(TIP_CAMP_PVP_MONSTER_BATTLE,               47018).% 该玩家正在战斗中！
-define(TIP_CAMP_PVP_MONSTER_DEAD,                 47019).% 对方已经死亡，无法与之战斗！
-define(TIP_CAMP_PVP_SAME_CAMP,                    47020).% 同一阵营不能交战
-define(TIP_CAMP_PVP_PVP_WIN,                      47021).% 恭喜你成功击杀敌营将士，获得了[10]铜钱、[10]积分！
-define(TIP_CAMP_PVP_PVP_LOSE,                     47022).% 很遗憾，你被敌营将士击败，此战获得[10]铜钱奖励，还望你再接再厉，挽回颓势！
-define(TIP_CAMP_PVP_PVE_COPPER,                   47023).% 你英勇无敌，给敌营战车造成[10]伤害，获得[10]铜钱
-define(TIP_CAMP_PVP_PVP_WIN_STREAK,               47024).% [0]锋芒毕露，完成了[10]杀，[10]营获得[10]积分！
-define(TIP_CAMP_PVP_RECOURCE_STREAK,              47025).% [0]辛勤耕耘，连续运送10次资源，[10]营获得[10]积分！

-define(TIP_CAMP_PVP_ENTER_CD,                     47026).% 正在准备CD中……
-define(TIP_CAMP_PVP_CAMP_FULL,                    47027).% 阵营人数已满，请稍后再尝试加入……
-define(TIP_CAMP_PVP_SHAODANGING,                  47028).% 扫荡中，不能参加阵营战
-define(TIP_CAMP_PVP_START_LEFT,                   47029).% 活动[10]秒后正式开始
-define(TIP_CAMP_PVP_MONSTER_ALREADY_BATTLE,       47030).% 冲锋死士正在战斗中，无法与其交战
-define(TIP_CAMP_PVP_PK_CD,                        47031).% 您刚刚与该玩家战斗过，[10]秒后可以再次与其交战
-define(TIP_CAMP_PVP_ENCOURAGE,                    47032).% 鼓舞已经到达上限
-define(TIP_CAMP_PVP_STOP_STEAK_KILL,              47033).% [0]终于终结了[0]的[10]连杀，为[10]营获得[10]积分
-define(TIP_CAMP_PVP_CARR_DEAD,                    47034).% 战车已经被其他玩家击毁
-define(TIP_CAMP_PVP_ATT_CAR_SUCCESS,              47035).% 您成功进攻了战车，获得[10]积分，[10]铜钱。
-define(TIP_CAMP_PVP_LEVEL_ERR,                    47036).% 被邀请玩家与您不在一个等级段战场
-define(TIP_CAMP_PVP_IN_CAMP,                      47037).% 被邀请玩家已经在阵营战玩法中，无法被邀请
-define(TIP_CAMP_PVP_BOX_OPENED,                   47038).% 该宝箱正在被人开启
-define(TIP_CAMP_PVP_BOX_FULL,                     47039).% 今日无法开启更多的宝箱了
-define(TIP_CAMP_PVP_BOX_AWARD,                    47040).% 恭喜！您在宝箱中获得了[10]礼券
-define(TIP_CAMP_PVP_PVP_WIN_CASH,                 47041).% [0]大发神威，轻松将对手斩落马下，意外获得[10]礼券
-define(TIP_CAMP_PVP_RESOURCE_CASH,                47042).% [0]勤勤恳恳，在一次挖煤的过程中，竟获得[10]礼券。
-define(TIP_CAMP_PVP_PVE_WIN_CASH,                 47043).% [0]在破坏敌方阵营战车的过程中，还不忘变卖废铁，获得[10]礼券。

%% ==========================================================
%% 神兵
%% ==========================================================
-define(TIP_WEAPON_GOODS,                          47502).% 没有选中神兵
-define(TIP_WEAPON_REFRESH_ERROR,                  47503).% 神兵洗练失败
-define(TIP_WEAPON_REFRESH_ZERO,                   47504).% 属性值为0，锁定失败
-define(TIP_WEAPON_CHESS_TIMES_NOT_ENONGH,         47510).% 投掷次数不够
-define(TIP_WEAPON_CHESS_IN_CD,                    47511).% 投掷冷却cd中
-define(TIP_WEAPON_CHESS_GET_DICE,                 47512).% 获得[10]次投掷次数
-define(TIP_WEAPON_SUCCESS_BUY_DICE,               47513).% 购买成功
-define(TIP_WEAPON_CHESS_HAVE_PUT_TIMES,           47514).% 当前还有剩余次数未用完
-define(TIP_WEAPON_CHESS_BUY_TIMES_NOT_ENOUGH,     47515).% 购买次数不够
-define(TIP_WEAPON_QUENCH_SUCCESS,                 47516).% 神兵淬火成功
-define(TIP_WEAPON_QUENCH_FAIL,                    47517).% 神兵淬火失败
-define(TIP_WEAPON_QUENCH_GOODS_NOT_ENOUGH,        47518).% 淬火石数量不足！

%% ==========================================================
%% 军团战
%% ==========================================================
-define(TIP_GUILD_PVP_GUILD_NOT_APP,               48002).% 您所在的军团未取得参加军团战的资格
-define(TIP_GUILD_PVP_END,                         48003).% 军团战已经结束
-define(TIP_GUILD_PVP_ENTER_CD,                    48004).% 正在准备CD中……
-define(TIP_GUILD_PVP_ACTIVE_START,                48005).% 本次军团战报名已经结束！
-define(TIP_GUILD_PVP_APP_403,                     48006).% 只有军团长和副军团长才能报名
-define(TIP_GUILD_PVP_DEF_FULL,                    48007).% 防守军团数量已满
-define(TIP_GUILD_PVP_ENCOURAGE_MAX,               48008).% 鼓舞到达最大值
-define(TIP_GUILD_PVP_START,                       48009).% 军团夺城战已开放，请英雄速速加入，击退敌营！
-define(TIP_GUILD_PVP_OFF,                         48010).% 军团夺城战已结束！
-define(TIP_GUILD_PVP_APP_END_30,                  48011).% 军团战报名还有30分钟截止，请各军团长抓紧时间报名！
-define(TIP_GUILD_PVP_APP_END,                     48012).% 军团战报名已经截止，报名结果请查看邮件！
-define(TIP_GUILD_PVP_ENTER_403,                   48013).% 对不起，您的军团可能战力偏低错过了此次战斗，请再接再厉。
-define(TIP_GUILD_PVP_WALL_KILLED_ATT,             48014).% 城门已经被[0]攻破了，打败护国将军胜利就是咱们的了，兄弟们冲啊！
-define(TIP_GUILD_PVP_WALL_KILLED_DEF,             48015).% 城门已经被[0]攻破，大家快回来施援护国将军！
-define(TIP_GUILD_PVP_BOSS_KILLED_ATT,             48016).% 在大家的努力下终于攻破城池可喜可贺！
-define(TIP_GUILD_PVP_BOSS_KILLED_DEF,             48017).% 很遗憾，城池被攻破，英雄们再接再厉！
-define(TIP_GUILD_PVP_CAR_KILLED_ATT,              48018).% 我军的攻城车被[0]攻破，攻城车可对城门照成大量伤害大家注意保护！
-define(TIP_GUILD_PVP_CAR_KILLED_DEF,              48019).% 我军的[0]击破的敌军的攻城车，极大的减小了城门受到的威胁！
-define(TIP_GUILD_PVP_ATT_WIN,                     48020).% 诸侯们顺利的夺下了长安，同时[10]以攻城方最高积分获得长安的拥有权！
-define(TIP_GUILD_PVP_DEF_WIN,                     48021).% [10]军团经过连番苦战终于守住了长安，保住了自己的城池拥有权！
-define(TIP_GUILD_PVP_APP_SUCCESS,                 48022).% 报名[10]成功！
-define(TIP_GUILD_PVP_MASTER_CAN_NOT_APP,          48023).% 城主不能报名！
-define(TIP_GUILD_PVP_FIRST_GUILD_CAN_NOT_APP_DEF, 48024).% 首次军团战不能申请守城方！
-define(TIP_GUILD_PVP_LV_NOT_ENOUGH,               48025).% 报名军团夺城战需军团等级到达2级
-define(TIP_GUILD_PVP_APP_END_LEFT,                48026).% 军团夺城战报名还有[10]小时截止，还未报名的军团赶快报名啊！
-define(TIP_GUILD_PVP_SKILL_403,                   48027).% 只有军团长和副军团战才能使用该技能
-define(TIP_GUILD_PVP_BRING_MAX,                   48028).% 浴火重生次数不足！
-define(TIP_GUILD_PVP_CAR_ATT,                     48029).% 攻城方[0]一掷千金对守城方使用了“霹雳打击”，对[10]造成了严重的伤害
-define(TIP_GUILD_PVP_FIX_WALL,                    48030).% 守城方[0]一掷千金使用了“固若金汤”，[10]的气血得到了回复
-define(TIP_GUILD_PVP_KILL_WALL,                   48031).% [0]率先攻破了城门，为己方军团增加了[10]积分。
-define(TIP_GUILD_PVP_KILL_BOSS,                   48032).% [0]奋起一击，成功的打败了护国将军，为己方军团增加了[10]积分
-define(TIP_GUILD_PVP_KILL_CAR,                    48033).% [0]率先破坏了攻城战车，极大地鼓舞了守城士气，为己方军团获得[10]积分。
-define(TIP_GUILD_PVP_APPED,                       48034).% 您的军团已经报名成功，无需重复报名！
-define(TIP_GUILD_PVP_ADD_DEF_SUCESS,              48035).% 添加守城军团成功！
-define(TIP_GUILD_PVP_PVP_GIVE_ITEM,               48036).% [10]军团的[0]将[10]个[1]交给了[0]：“下次军团夺城的时候一定要给力哦！
-define(TIP_GUILD_PVP_NO_WINER,                    48037).% 由于没有军团报名军团夺城战，本次活动平局！
-define(TIP_GUILD_PVP_ADD_PVP_SCORE_BY_BUY,        48038).% 购买成功，获得[10]点功德
-define(TIP_GUILD_PVP_GUILD_PVP_OPERATION_ERROR,   48039).% 您的军团正在争夺长安城，期间无法进行该操作!
-define(TIP_GUILD_PVP_NOT_START_CAN_NOT_ENTER,     48040).% 倒计时结束后开始军团夺城

%% ==========================================================
%% 领取各种礼包提示
%% ==========================================================

%% ==========================================================
%% 运营活动
%% ==========================================================
-define(TIP_OP_TIMES_OVER,                         50002).% 转盘次数不足
-define(TIP_OP_TURN_PARTNER,                       50003).% 天啊，[0]在充值转盘中招募到了绝世神将[10]，不知还有谁能与之抗衡，快去看看吧。
-define(TIP_OP_TURN_GOODS,                         50004).% [0]在充值转盘中得到了[1]，鸿运齐天，财神降临，快去看看吧。
-define(TIP_OP_EXCHANGE,                           50005).% 成功提交信息，感谢您的参与
-define(TIP_OP_INFO_CORRECT,                       50006).% 请正确填写信息
-define(TIP_OP_TURN_EQUIP,                         50007).% [0]在充值转盘中得到了[2]，鸿运齐天，财神降临，快去看看吧。

%% ==========================================================
%% 雪夜赏灯
%% ==========================================================
-define(TIP_SNOW_NOT_OPEN,                         50502).% 雪夜赏灯活动尚未开启！
-define(TIP_SNOW_GET_GOODS,                        50503).% 获得[10]*[10]
-define(TIP_SNOW_CANNOT_STORE_GET,                 50504).% 收集图标未点亮，不能领取
-define(TIP_SNOW_COUNT_NOT_ENOUGH,                 50505).% 抽奖点不足
-define(TIP_SNOW_STORE_LIGHTED,                    50506).% 恭喜你点亮第[10]层全部图标，可领取收集奖励。
-define(TIP_SNOW_GET_BIG_AWARD,                    50507).% 恭喜[0]在雪夜赏灯中获得了[1]，你还不去[10]么？
-define(TIP_SNOW_GET_BIG_AWARD2,                   50508).% 恭喜[0]在雪夜赏灯中获得了[2]，你还不去[10]么？

%% ==========================================================
%% 运营活动
%% ==========================================================
-define(TIP_YUNYING_ACTIVITY_TRAIN_HORSE,          51002).% 天道酬勤，[0]将坐骑培养到[10]级，获得丰厚大奖，真是可喜可贺。
-define(TIP_YUNYING_ACTIVITY_DEPOSIT,              51003).% [0]领取了[10]元宝充值礼包，里面的奖励好诱人，Ta乐得合不上嘴！
-define(TIP_YUNYING_ACTIVITY_TOWER,                51004).% [0]在破阵中通过了第[10]层，得到了我们送出的奖励，真令人羡慕啊！
-define(TIP_YUNYING_ACTIVITY_CULTIVATION,          51005).% [0]祭星中点燃了灯盏[10]，获得了一个大礼包，真开心！
-define(TIP_YUNYING_ACTIVITY_NO_REWARD,            51006).% 目前没达到领取要求，不可领取
-define(TIP_YUNYING_ACTIVITY_EXCHANGE_SUCC,        51007).% 兑换成功
-define(TIP_YUNYING_ACTIVITY_HORSE_BIG_AWARD,      51008).% [0]终于收集足够的圣诞兑换令，终于兑换到了[2]，你不心动么？快去[10]吧！
-define(TIP_YUNYING_ACTIVITY_FUSION_BIG_AWARD,     51009).% [0]不辞万苦收集圣诞碎片，终于兑换到了[2]，你不心动么？快去[10]吧！
-define(TIP_YUNYING_ACTIVITY_PARTNER_ALREADY,      51010).% 该武将已招募，不可兑换。
-define(TIP_YUNYING_ACTIVITY_CARD_NOT_ENOUGH,      51011).% 神刀不足，无法兑换。
-define(TIP_YUNYING_ACTIVITY_PARTNER_FULL,         51012).% 已招募武将过多，请先解雇不需要的武将
-define(TIP_YUNYING_ACTIVITY_PARTNER_SUCC,         51013).% 成功招募[10]
-define(TIP_YUNYING_ACTIVITY_PARTNER_RECRUIT,      51014).% [0]在神刀点将的活动中，成功招募了[10]。你也来[10]吧！
-define(TIP_YUNYING_ACTIVITY_POINT_NOT_ENOUGH,     51015).% 点数不足，无法兑换神刀。
-define(TIP_YUNYING_ACTIVITY_POINT_EXCHANGE_SUCC,  51016).% 花费点数[10]成功兑换神刀
-define(TIP_YUNYING_ACTIVITY_EXCHANGE_POINT_SUCC,  51017).% 成功兑换，获得[10]点数
-define(TIP_YUNYING_ACTIVITY_EXCHANGE_WRONG_NUM,   51018).% 请先选择要兑换的数量
-define(TIP_YUNYING_ACTIVITY_BLESS_AWARD,          51019).% [0]诚心祭祀财神，财神特赐予[2]，你也来[10]，为来年祈福吧。
-define(TIP_YUNYING_ACTIVITY_TOWER1,               51020).% [0]通过了第[10]层，得到我们送出的大奖，尽显霸气之风。
-define(TIP_YUNYING_ACTIVITY_TOWER2,               51021).% [0]通过了第[10]层，得到我们送出的大奖，尽显王者之风。
-define(TIP_YUNYING_ACTIVITY_TOWER3,               51022).% [0]通过了第[10]层，得到我们送出的大奖，不愧是一代枭雄。
-define(TIP_YUNYING_ACTIVITY_BLESS_AWARD_1,        51023).% [0]诚心祭祀财神，财神特赐予[10]，你也来[10]，为来年祈福吧。
-define(TIP_YUNYING_ACTIVITY_BLESS_AWARD_2,        51024).% [0]诚心祭祀财神，财神特赐予[1]，你也来[10]，为来年祈福吧。
-define(TIP_YUNYING_ACTIVITY_STONE_EXCHANGE_AWARD, 51025).% [0]在宝石积分商店中兑换到了[1]，真是令人艳羡，你也来[10]吧！
-define(TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_1, 51026).% [0]参加【跃马迎春】活动，集齐了福星高照，获得了[1]，你还没来[10]？
-define(TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_2, 51027).% [0]参加【跃马迎春】活动，集齐了金玉满堂，获得了[1]，你还没来[10]？
-define(TIP_YUNYING_ACTIVITY_REDBAG_NOT_ENOUGH,    51030).% 红包数量不足
-define(TIP_YUNYING_ACTIVITY_NO_REDAB,             51031).% 无未领取红包
-define(TIP_YUNYING_ACTIVITY_REDBAG_GG1,           51032).% [0]参加【跃马迎春】活动，打开红包，获得了[1]，马年鸿运齐天，你不来[10]？
-define(TIP_YUNYING_ACTIVITY_REDBAG_GG2,           51033).% [0]参加【跃马迎春】活动，打开红包，获得了[2]，马年鸿运齐天，你不来[10]？
-define(TIP_YUNYING_ACTIVITY_TXJ_GG1,              51034).% [0]参加【如意良宵】活动，打开同心结，获得了[1]，马年鸿运齐天，你不来[10]？
-define(TIP_YUNYING_ACTIVITY_TXJ_GG2,              51035).% [0]参加【如意良宵】活动，打开同心结，获得了[2]，马年鸿运齐天，你不来[10]？
-define(TIP_YUNYING_ACTIVITY_ADD_COPPER,           51036).% 获得[10]铜钱
-define(TIP_YUNYING_ACTIVITY_NOT_OPEN,             51037).% 活动未开启，无法使用。
-define(TIP_YUNYING_ACTIVITY_GET_GOODS,            51038).% 成功使用，获得[1]。

%% ==========================================================
%% 跨服竞技场
%% ==========================================================
-define(TIP_CROSS_ARENA_ALREADY_FIGHT,             51502).% 今日已挑战过该目标
-define(TIP_CROSS_ARENA_REFRESHING,                51503).% 该玩家所在服正在更新中
-define(TIP_CROSS_ARENA_NO_TIMES,                  51504).% 今日挑战次数已用完
-define(TIP_CROSS_ARENA_NOT_SAME_PHASE,            51505).% 段位已更改，不能挑战
-define(TIP_CROSS_ARENA_REWARD_SUCCESS,            51506).% 领取成功
-define(TIP_CROSS_ARENA_ALREADY_OVER,              51507).% 今日跨服竞技挑战已结束，请0点后再行挑战！！！
-define(TIP_CROSS_ARENA_SKIP_WIN,                  51508).% 该玩家被你的英姿吓得落荒而逃，恭喜你直接获得胜利！

%% ==========================================================
%% 辕门射戟
%% ==========================================================
-define(TIP_ARCHERY_ACCGET,                        52003).% 领取累计奖励！
-define(TIP_ARCHERY_NO_ARROW,                      52004).% 箭矢不足哦
-define(TIP_ARCHERY_NO_ACCGET,                     52005).% 没有累计奖励可以领取o(╯□╰)o
-define(TIP_ARCHERY_NEWCOURT,                      52006).% 刷新成功
-define(TIP_ARCHERY_LIMIT_BUY,                     52008).% 今日购买次数已达上限
-define(TIP_ARCHERY_NO_SHOOTTING,                  52009).% 今日已无箭矢，请明日再来

%% ==========================================================
%% 攻城掠地
%% ==========================================================
-define(TIP_ENCROACH_ARMORY_EXP,                   52502).% 恭喜您在城池中夺取了军械库，经验提升[10]。
-define(TIP_ENCROACH_GRANARY_EXP,                  52503).% 恭喜您在城池中夺取了粮仓，经验提升[10]
-define(TIP_ENCROACH_VETERAN_SUCCESS,              52504).% 恭喜您击败守城精兵，成功攻占此城池。
-define(TIP_ENCROACH_VETERAN_FAIL,                 52505).% 守城精兵死守城池，您暂时撤退了。
-define(TIP_ENCROACH_GENERAL_SUCCESS,              52506).% 恭喜您击败守城大将，成功攻占此城池。
-define(TIP_ENCROACH_GENERAL_FAIL,                 52507).% 守城大将勇猛奋战，您暂时撤退了。
-define(TIP_ENCROACH_GENERAL_LOTTERY,              52508).% [0]在“攻城掠地”中斩杀四方大将，获得[1]。
-define(TIP_ENCROACH_GRANARY_EXP_GOODS,            52509).% 恭喜您在城池中夺取了粮仓，经验提升[10]，并意外发现了[1]。
-define(TIP_ENCROACH_CAPITAL_EXP,                  52510).% 恭喜您成功夺取都城，经验提升[10]。
-define(TIP_ENCROACH_NO_TIMES,                     52511).% 您今日的攻城掠地次数已经用完，请等待明日玩法重置。
-define(TIP_ENCROACH_NO_BUY_TIMES,                 52512).% 购买次数已达上限。
-define(TIP_ENCROACH_NOT_ENOUGH_M_FORCE,           52513).% 移动力不足。
-define(TIP_ENCROACH_INVALID_POS,                  52514).% 无效移动位置。
-define(TIP_ENCROACH_BAG_IS_FULL,                  52515).% 背包空间不足。
-define(TIP_ENCROACH_NO_START,                     52516).% 没玩过此玩法，无需重置。
-define(TIP_ENCROACH_BUY_MFORCE_SUCCESS,           52517).% 购买移动力成功。
-define(TIP_ENCROACH_GENERAL_LOTTERY2,             52518).% [0]在“攻城掠地”中斩杀四方大将，获得[2]。
-define(TIP_ENCROACH_GRANARY_EXP_GOODS2,           52519).% 恭喜您在城池中夺取了粮仓，经验提升[10]，并意外发现了[2]。

%% ==========================================================
%% 元宵你妹啊
%% ==========================================================
-define(TIP_LATERN_HAVE_TEAM,                      53002).% 已经在队伍中a

%% ==========================================================
%% 滚服礼券
%% ==========================================================
-define(TIP_GUN_CASH_ALREADY_GET,                  53503).% 重生礼券已经被领取过
-define(TIP_GUN_CASH_GET_SUCCESS,                  53504).% 领取重生礼券成功！

%% ==========================================================
%% 将魂
%% ==========================================================
-define(TIP_PARTNER_SOUL_NOT_OPEN,                 54002).% 将魂未开启
-define(TIP_PARTNER_SOUL_LV_MAX,                   54003).% 将魂等级不能高于人物等级
-define(TIP_PARTNER_SOUL_STAR_NOT_OPEN,            54004).% 将星未开启
-define(TIP_PARTNER_SOUL_STAR_LV_MAX,              54005).% 已提升至最高级，无法继续升级。
-define(TIP_PARTNER_SOUL_NOT_INHERIT_SELF,         54006).% 不能对自身进行继承
-define(TIP_PARTNER_SOUL_NOT_INHERIT_HERO,         54007).% 只有武将才能进行继承
-define(TIP_PARTNER_SOUL_LV_LOW,                   54008).% 目标的将魂等级高于此武将，无法继承
-define(TIP_PARTNER_SOUL_STAR_LV_LOW,              54009).% 目标的将魂星级高于此武将，无法继承
-define(TIP_PARTNER_SOUL_WARE_NOT_ENOUGH,          54010).% 魂器不足,无法提升将魂等级
-define(TIP_PARTNER_SOUL_STONE_NOT_ENOUGH,         54011).% 将星石不足,无法提升将魂星级
-define(TIP_PARTNER_SOUL_COIN_NOT_ENOUGH,          54012).% 铜钱不足,无法进行将魂继承
-define(TIP_PARTNER_SOUL_LV_NOTICE,                54013).% 将魂等级升至[10]级
-define(TIP_PARTNER_SOUL_STAR_NOTICE,              54014).% 将魂星级升至[10]级
-define(TIP_PARTNER_SOUL_SKILL_NOTICE,             54015).% 将魂技升至[10]级

%% ==========================================================
%% 青梅煮酒
%% ==========================================================
-define(TIP_GAMBLE_FULL_ROOM,                      54502).% 房间数量达到上限，请加入其它玩家创建的房间进行游戏

-define(TIP_GAMBLE_FULL_PLAYER,                    54503).% 该房间人数已满，请选择其他房间加入。

-define(TIP_GAMBLE_NO_MATCH,                       54504).% 暂时无法匹配到合适的房间，请稍后继续。

-define(TIP_GAMBLE_JOIN,                           54505).% 是否兑换[10]元宝作为酒筹进入游戏？

-define(TIP_GAMBLE_EXCHANGE_BET,                   54506).% 花费[10]元宝，获得[10]酒筹

-define(TIP_GAMBLE_EXCHANGE_CASH,                  54507).% 消耗[10]酒筹，获得[10]元宝

-define(TIP_GAMBLE_KICK_OUT,                       54508).% 倒计时内未准备，自动退出房间

-define(TIP_GAMBLE_LEAVE,                          54509).% 对方退出房间,取消准备状态。

-define(TIP_GAMBLE_TIE,                            54510).% 对方服务器已关闭，本局为平局。

-define(TIP_GAMBLE_CROSS_FAIL,                     54511).% 没有找到合适的房间！
-define(TIP_GAMBLE_JOIN_FAIL,                      54512).% 加入房间失败
-define(TIP_GAMBLE_INVITE,                         54513).% [0]在青梅煮酒中等待英雄前来一叙，筹码[10]，可有人敢来？[10][10]。
-define(TIP_GAMBLE_ESCAPE,                         54514).% 对方逃跑，您不战而胜！
-define(TIP_GAMBLE_NO_ROOM,                        54516).% 加入失败，房间不存在
-define(TIP_GAMBLE_TIP_WIN3,                       54517).% 手气绝佳，[10]已获得三局三胜！
-define(TIP_GAMBLE_TIP_WIN5,                       54518).% 五连胜, [10]毫无压力，快来打败他吧。
-define(TIP_GAMBLE_TIP_WIN1,                       54519).% 您轻易取得了第一场胜利!
-define(TIP_GAMBLE_TIP_WIN7,                       54520).% [10]战无不胜，赢钱赢得手都软了!
-define(TIP_GAMBLE_TIP_WIN10,                      54521).% [10]财神附体，人生在世只求一败！
-define(TIP_GAMBLE_LOST_7,                         54522).% 人不输钱枉少年，[10]就当散财行善！

-define(TIP_GAMBLE_LOST_5,                         54523).% [10]手气真差，求求谁让他赢一局吧。
-define(TIP_GAMBLE_LOST_10,                        54524).% [10]衰神附体，输得连内裤都没剩！

-define(TIP_GAMBLE_LOST_3,                         54525).% 天啊，[10]已经输得无可救药了。
-define(TIP_GAMBLE_LOST_1,                         54526).% 手气欠佳，小输一局。


%% ==========================================================
%% 皇陵探宝
%% ==========================================================
-define(TIP_KB_TREASURE_NO_START,                  55002).% 活动未开启
-define(TIP_KB_TREASURE_NOT_EXISTS,                55003).% 活动不存在
-define(TIP_KB_TREASURE_TURN_GOODS,                55004).% [0]在深幽的墓穴中不断的探索，终于挖出[1]。
-define(TIP_KB_TREASURE_TURN_EQUIP,                55005).% [0]在深幽的墓穴中不断的探索，终于挖出[2]。

%% ==========================================================
%% 百服庆典
%% ==========================================================
-define(TIP_HUNDRED_SERV_TALK,                     55202).% [0]祝福桃园结义，参与百服祝福，获得100礼券。
-define(TIP_HUNDRED_SERV_GET_BONUS,                55203).% 百服祝福成功，获得100礼券

%% ==========================================================
%% 限购商城
%% ==========================================================
-define(TIP_LIMIT_MALL_MALL_CLOSE,                 55302).% 商城维护中，暂停营业！
-define(TIP_LIMIT_MALL_BUY_OK,                     55303).% 购买成功
-define(TIP_LIMIT_MALL_BUY_FAIL,                   55304).% 物品已售完
-define(TIP_LIMIT_MALL_NO_GOODS,                   55305).% 物品尚未上架！
-define(TIP_LIMIT_MALL_BAG_FULL,                   55306).% 背包已满，请整理您的背包！


%%-----------tencent
-define(TIP_TENCENT_INVITE_MAX,                   55401).% 每天最多邀请两次哦



