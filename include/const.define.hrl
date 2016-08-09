%% 定义的常量名称不能相同

%% ==========================================================
%% 系统通用
%% ==========================================================
-define(CONST_SYS_PRO_NULL,                         0).% 职业--空 
-define(CONST_SYS_ROOT_KEY,                         "%6JW%NY&").% root_key 
-define(CONST_SYS_RESOURCE_KEY,                     ";h-Xiz*E").% 资源key 
-define(CONST_SYS_GM_KEY,                           "RI!%ufwi%u8~qyqE(it8").% gm_key 
-define(CONST_SYS_FCM_KEY,                          "shjdysuwei32*&DSdooiew").% 沉迷key 
-define(CONST_SYS_PRO_XZ,                           1).% 职业--陷阵 
-define(CONST_SYS_PRO_FJ,                           2).% 职业--飞军 
-define(CONST_SYS_PRO_TJ,                           3).% 职业--天机 
-define(CONST_SYS_PRO_GM,                           4).% 职业--鬼谋 
-define(CONST_SYS_PRO_KX,                           5).% 职业--控弦 
-define(CONST_SYS_PRO_JH,                           6).% 职业--惊鸿 
-define(CONST_SYS_MAX_USER_INDEX,                   100000).% 每个服务器的人数上限 
-define(CONST_SYS_RSYNC_MAN_SEC,                    3600000).% 平台同步时间 

-define(CONST_SYS_SEX_NULL,                         0).% 性别--空 
-define(CONST_SYS_SEX_MALE,                         1).% 性别--男生 
-define(CONST_SYS_SEX_FAMALE,                       2).% 性别--女生 

-define(CONST_SYS_COLOR_WHITE,                      1).% 颜色--白 
-define(CONST_SYS_COLOR_GREEN,                      2).% 颜色--绿 
-define(CONST_SYS_COLOR_BLUE,                       3).% 颜色--蓝 
-define(CONST_SYS_COLOR_YELLOW,                     4).% 颜色--金 
-define(CONST_SYS_COLOR_PURPLE,                     5).% 颜色--紫 
-define(CONST_SYS_COLOR_ORANGE,                     6).% 颜色--橙 
-define(CONST_SYS_COLOR_RED,                        7).% 颜色--红 

-define(CONST_SYS_FALSE,                            0).% 各种false(数字：0) 
-define(CONST_SYS_TRUE,                             1).% 各种true(数字：1) 

-define(CONST_SYS_CASH,                             1).% 货币--元宝 
-define(CONST_SYS_CASH_BIND,                        2).% 货币--礼券 
-define(CONST_SYS_GOLD,                             3).% 货币--铜币 
-define(CONST_SYS_GOLD_BIND,                        4).% 货币--绑定铜币 
-define(CONST_SYS_BCASH_FIRST,                      5).% 货币--绑定元宝优先 
-define(CONST_SYS_BGOLD_FIRST,                      6).% 货币--绑定铜币优先 
-define(CONST_SYS_CASH_SUM,                         7).% 货币--元宝总额 
-define(CONST_SYS_CASH_BIND_2,                      8).% 货币--绑定元宝 
-define(CONST_SYS_CASH_ONLY,                        9).% 货币--只扣元宝 

-define(CONST_SYS_USER_STATE_FORBID,                0).% 玩家状态--禁止登录 
-define(CONST_SYS_USER_STATE_NORMAL,                1).% 玩家状态--正常 
-define(CONST_SYS_USER_STATE_GUIDE,                 2).% 玩家状态--指导员 
-define(CONST_SYS_USER_STATE_GM,                    3).% 玩家状态--GM 

-define(CONST_SYS_CELL_WIDTH,                       750).% 格子宽度 

-define(CONST_SYS_COUNTRY_DEFAULT,                  0).% 国家--默认无 
-define(CONST_SYS_COUNTRY_WEI,                      1).% 国家--魏国 
-define(CONST_SYS_COUNTRY_SHU,                      2).% 国家--蜀国 
-define(CONST_SYS_COUNTRY_WU,                       3).% 国家--吴国 

-define(CONST_SYS_PLAYER_LV_MAX,                    80).% 角色最高等级 
-define(CONST_SYS_PLAYER_LV_MAX_2,                    100).% 角色最高等级 
-define(CONST_SYS_POSITION_MAX,                     101).% 官衔最高等级 

-define(CONST_SYS_NUMBER_SEVEN,                     7).% 数字--7 
-define(CONST_SYS_NUMBER_TEN,                       10).% 数字--10 
-define(CONST_SYS_NUMBER_SIXTY,                     60).% 数字--60 
-define(CONST_SYS_NUMBER_HUNDRED,                   100).% 数字--100 
-define(CONST_SYS_NUMBER_THOUSAND,                  1000).% 数字--1000 
-define(CONST_SYS_ONE_HOUR_SECONED,                 3600).% 一天小时的秒数 
-define(CONST_SYS_NUMBER_TEN_THOUSAND,              10000).% 数字--10000 
-define(CONST_SYS_ONE_DAY_SECONDS,                  86400).% 一天的秒数 
-define(CONST_SYS_NUM_MILLION,                      1000000).% 数字--1000000 

-define(CONST_SYS_PLAYER,                           1).% 战斗类型--角色 
-define(CONST_SYS_PARTNER,                          2).% 战斗类型--武将 
-define(CONST_SYS_PET,                              3).% 战斗类型--宠物 
-define(CONST_SYS_HORSE,                            4).% 战斗类型--坐骑 
-define(CONST_SYS_MONSTER,                          10).% 战斗类型--怪物 

-define(CONST_SYS_DB_TYPE_CREAT,                    1).% 角色数据持久化类型--创建 
-define(CONST_SYS_1,                                1).% test 
-define(CONST_SYS_DB_TYPE_INTERVAL,                 2).% 角色数据持久化类型--定时 
-define(CONST_SYS_DB_TYPE_LOGOUT,                   3).% 角色数据持久化类型--退出 

-define(CONST_SYS_CALC_TYPE_PLUS,                   1).% 计算类型--加 
-define(CONST_SYS_CALC_TYPE_MINUS,                  2).% 计算类型--减 
-define(CONST_SYS_CALC_TYPE_MULTI,                  3).% 计算类型--乘 

-define(CONST_SYS_MIN_VIP_LV,                       0).% vip等级下限 
-define(CONST_SYS_MAX_VIP_LV,                       12).% vip等级上限 
-define(CONST_SYS_MAX_SKILL_POINT,                  999).% 技能点上限 
-define(CONST_SYS_MAX_BGOLD,                        1000000000).% 铜钱上限 
-define(CONST_SYS_MAX_CASH,                         1000000000).% 元宝上限 
-define(CONST_SYS_MAX_BCASH,                        1000000000).% 礼券上限 
-define(CONST_SYS_MAX_MERITORIOUS,                  1000000000).% 功勋上限 
-define(CONST_SYS_MAX_EXPERIENCE,                   1000000000).% 历练上限 
-define(CONST_SYS_MAX_EXPLOIT,                      1000000000).% 军团贡献上限 
-define(CONST_SYS_MAX_SPIRIT,                       1000000000).% 心力上限 
-define(CONST_SYS_MAX_HONOUR,                       1000000000).% 声望上限(成就点) 
-define(CONST_SYS_MAX_SEE,                          1000000000).% 阅历上限 

-define(CONST_SYS_GOODS_USE,                        0).% 使用道具 
-define(CONST_SYS_GOODS_MAKE,                       1).% 获得道具 

-define(CONST_SYS_INTERVAL_PLAYER,                  1000).% 关服时每个玩家预留下线时间 

-define(CONST_SYS_CODE_TYPE_MEDIA,                  1).% 激活码类型：媒体激活码 
-define(CONST_SYS_CODE_TYPE_ORDER,                  2).% 激活码类型：预约激活码 

-define(CONST_SYS_CODE_LENGTH_ORDER,                6).% 激活码长度：预约激活码 
-define(CONST_SYS_CODE_LENGTH_MEDIA,                10).% 激活码长度：媒体激活码 

-define(CONST_SYS_CODE_COUNT_MEDIA,                 3000).% 激活码数量：媒体激活码 
-define(CONST_SYS_CODE_COUNT_ORDER,                 50000).% 激活码数量：预约激活码 

-define(CONST_SYS_EXCHANGE_RATE,                    10).% 汇率：单位RMB转元宝数 

-define(CONST_SYS_SEC_DAY,                          86400).% 时间--天 

-define(CONST_SYS_PLATFORM_4399,                    1).% 平台id--4399 
-define(CONST_SYS_PLATFORM_360U9,                   2).% 平台id--360u9 
-define(CONST_SYS_PLATFORM_PPTV,                    3).% 平台id--pptv 
-define(CONST_SYS_PLATFORM_37WAN,                   4).% 平台id--37wan 

-define(CONST_SYS_LOGIN_CHECK_4399,                 1).% 登陆模式--4399 
-define(CONST_SYS_LOGIN_CHECK_360U9,                2).% 登陆模式--360u9 
-define(CONST_SYS_LOGIN_CHECK_TENCENT,              3).% 登陆模式--tencent
-define(CONST_SYS_LOGIN_CHECK_NONE,              	4).% 登陆模式--none

-define(CONST_SYS_STOP_BROADCAST,                   [1]).% 关服广播时间 

%% ==========================================================
%% 玩家
%% ==========================================================
-define(CONST_PLAYER_CLIENT_STATE_LOGIN_YES,        0).% 客户端状态--登陆有角色 
-define(CONST_PLAYER_CLIENT_STATE_UNLOGIN,          1).% 客户端状态--未登录 
-define(CONST_PLAYER_CLIENT_STATE_LOGIN_NO,         2).% 客户端状态--已登录无角色 

-define(CONST_PLAYER_ATTR_FORCE,                    1).% 力(一级) 
-define(CONST_PLAYER_ATTR_FATE,                     2).% 命(一级) 
-define(CONST_PLAYER_ATTR_MAGIC,                    3).% 术(一级) 
-define(CONST_PLAYER_MAX_ATTR_1,                    3).% 一级属性最大序号 
-define(CONST_PLAYER_ATTR_HP_MAX,                   4).% 气血(二级) 
-define(CONST_PLAYER_ATTR_FORCE_ATTACK,             5).% 物攻(二级) 
-define(CONST_PLAYER_ATTR_FORCE_DEF,                6).% 物防(二级) 
-define(CONST_PLAYER_ATTR_MAGIC_ATTACK,             7).% 术攻(二级) 
-define(CONST_PLAYER_ATTR_MAGIC_DEF,                8).% 术防(二级) 
-define(CONST_PLAYER_ATTR_SPEED,                    9).% 速度(二级) 
-define(CONST_PLAYER_MAX_ATTR_2,                    9).% 二级属性最大序号 
-define(CONST_PLAYER_ATTR_E_HIT,                    10).% 命中(精英) 
-define(CONST_PLAYER_ATTR_E_DODGE,                  11).% 闪避(精英) 
-define(CONST_PLAYER_ATTR_E_CRIT,                   12).% 暴击(精英) 
-define(CONST_PLAYER_ATTR_E_PARRY,                  13).% 招架(精英) 
-define(CONST_PLAYER_ATTR_E_RESIST,                 14).% 反击(精英) 
-define(CONST_PLAYER_ATTR_E_CRIT_H,                 15).% 暴击伤害(精英:无双) 
-define(CONST_PLAYER_ATTR_E_R_CRIT,                 16).% 降低暴击(精英:分影) 
-define(CONST_PLAYER_ATTR_E_PARRY_R_H,              17).% 格挡减伤(精英:坚韧) 
-define(CONST_PLAYER_ATTR_E_R_PARRY,                18).% 降低格挡(精英:破袭) 
-define(CONST_PLAYER_ATTR_E_RESIST_H,               19).% 反击伤害(精英:凝神) 
-define(CONST_PLAYER_ATTR_E_R_RESIST,               20).% 降低反击(精英:吉运) 
-define(CONST_PLAYER_ATTR_E_R_CRIT_H,               21).% 降低暴击伤害(精英:相性) 
-define(CONST_PLAYER_ATTR_E_I_PARRY_H,              22).% 无视格挡伤害(精英:致命) 
-define(CONST_PLAYER_ATTR_E_R_RESIST_H,             23).% 降低反击伤害(精英:意念) 
-define(CONST_PLAYER_MAX_ATTR_ELITE,                23).% 精英属性最大序号 
-define(CONST_PLAYER_ATTR_NAME,                     50).% 名称 
-define(CONST_PLAYER_ATTR_PRO,                      51).% 职业 
-define(CONST_PLAYER_ATTR_SEX,                      52).% 性别 
-define(CONST_PLAYER_ATTR_COUNTRY,                  53).% 国家 
-define(CONST_PLAYER_ATTR_LV,                       57).% 等级 
-define(CONST_PLAYER_ATTR_EXP,                      58).% 经验值 
-define(CONST_PLAYER_ATTR_EXPN,                     59).% 下级要多少经验 
-define(CONST_PLAYER_ATTR_HP,                       60).% 生命值（现有） 
-define(CONST_PLAYER_ATTR_SP,                       61).% 体力值（现有） 
-define(CONST_PLAYER_ATTR_SP_TEMP,                  62).% 体力值（临时） 
-define(CONST_PLAYER_ATTR_HONOUR,                   65).% 荣誉(原：成就点) 
-define(CONST_PLAYER_ATTR_MERITORIOUS,              66).% 功勋 
-define(CONST_PLAYER_ATTR_EXPLOIT,                  67).% 军团贡献 
-define(CONST_PLAYER_ATTR_SKILL_POINT,              68).% 武魂(原：技能点) 
-define(CONST_PLAYER_ATTR_POWER,                    69).% 战力 
-define(CONST_PLAYER_ATTR_ANGER,                    70).% 怒气 
-define(CONST_PLAYER_ATTR_POSITION,                 71).% 官衔 
-define(CONST_PLAYER_ATTR_EFFECT_WEAPON,            72).% 装备武器特效 
-define(CONST_PLAYER_ATTR_SKIN_WEAPON,              73).% 装备武器皮肤ID 
-define(CONST_PLAYER_ATTR_SKIN_ARMOR,               74).% 装备衣服皮肤ID 
-define(CONST_PLAYER_ATTR_SKIN_RIDE,                75).% 坐骑皮肤ID 
-define(CONST_PLAYER_ATTR_BUY_POINT,                76).% 充值积分 
-define(CONST_PLAYER_ATTR_VIP_LV,                   77).% VIP等级 
-define(CONST_PLAYER_MIND_SPIRIT,                   78).% 心力 
-define(CONST_PLAYER_EXPERIENCE,                    79).% 历练 
-define(CONST_PLAYER_TRAIN_FORCE,                   80).% 培养的力 
-define(CONST_PLAYER_TRAIN_FATE,                    81).% 培养的命 
-define(CONST_PLAYER_TRAIN_MAGIC,                   82).% 培养的术 
-define(CONST_PLAYER_ATTR_CURRENT_TITLE,            83).% 玩家称号 
-define(CONST_PLAYER_ATTR_CULTIVATION,              84).% 修为 
-define(CONST_PLAYER_ATTR_GUILD_ID,                 85).% 军团id 
-define(CONST_PLAYER_ATTR_GUILD_NAME,               86).% 军团名称 
-define(CONST_PLAYER_ATTR_GUILD_POS,                87).% 军团职位 
-define(CONST_PLAYER_ATTR_GUILD_LV,                 88).% 军团等级 
-define(CONST_PLAYER_ATTR_GUILD_DONATE,             89).% 军团捐献铜钱 
-define(CONST_PLAYER_HORSE_LV,                      90).% 坐骑等级 
-define(CONST_PLAYER_HORSE_EXP,                     91).% 坐骑经验 
-define(CONST_PLAYER_GROW_RATE,                     92).% 玩家成长系数 
-define(CONST_PLAYER_SP_LIMIT,                      93).% 体力上限 
-define(CONST_PLAYER_TRAIN_LEVEL,                   94).% 培养等级 
-define(CONST_PLAYER_SEE,                           95).% 阅历 
-define(CONST_PLAYER_TOTAL_MERITORIOUS,             96).% 累计功勋 

-define(CONST_PLAYER_FCM_STATE_SIGN_JUVENILE,       0).% 防沉迷状态--登记、未成年 
-define(CONST_PLAYER_FCM_STATE_SIGN_ADULT,          1).% 防沉迷状态--登记、成年 
-define(CONST_PLAYER_FCM_STATE_UNSIGNED,            2).% 防沉迷状态--未登记 

-define(CONST_PLAYER_SP_PER_TIME,                   5).% 每次增加体力值 
-define(CONST_PLAYER_BAD_HEART,                     6).% 最大连续错误心跳次数 
-define(CONST_PLAYER_SP_UP_CASH_PER_BUY,            10).% 每次购买增加元宝数 
-define(CONST_PLAYER_SP_INIT_CASH_BUY,              10).% 初始购买体力花费元宝数 
-define(CONST_PLAYER_GC_INTERVAL,                   50).% 角色进程GC间隔 
-define(CONST_PLAYER_TSP_INTERVAL,                  60).% 时间同步协议间隔（秒） 
-define(CONST_PLAYER_DB_INTERVAL,                   1800).% 存储角色数据间隔 
-define(CONST_PLAYER_SP_INTERVAL,                   1800).% 增加体力时间间隔 
-define(CONST_PLAYER_HEART_INTERVAL,                30000).% 心跳间隔时间（毫秒） 

-define(CONST_PLAYER_OFFLINE,                       0).% 离线 
-define(CONST_PLAYER_ONLINE,                        1).% 在线 

-define(CONST_PLAYER_BAG_PER_EXTEND,                6).% 背包每次扩展格子数 
-define(CONST_PLAYER_DEPOT_PER_EXTEND,              8).% 仓库每次扩展格子数 
-define(CONST_PLAYER_EQUIP_MAX_COUNT,               13).% 装备格子上限 
-define(CONST_PLAYER_TEMP_BAG_MAX_COUNT,            100).% 临时背包格子上限 
-define(CONST_PLAYER_TREASURE_MAX_COUNT,            100).% 宝箱仓库最大值 
-define(CONST_PLAYER_BAG_MAX_COUNT,                 150).% 背包最大上限 
-define(CONST_PLAYER_DEPOT_MAX_COUNT,               200).% 仓库最大上限 
-define(CONST_PLAYER_SP_MAX,                        200).% 体力上限 
-define(CONST_PLAYER_SP_MAX_LIMIT,                  1000000000).% 购买的体力上限 

-define(CONST_PLAYER_STATE_SINGLE_PRACTISE,         1).% 玩家状态--单修 
-define(CONST_PLAYER_STATE_DOUBLE_PRACTISE,         2).% 玩家状态--双修 
-define(CONST_PLAYER_STATE_NORMAL,                  3).% 玩家状态--普通 
-define(CONST_PLAYER_STATE_FIGHTING,                4).% 玩家状态--战斗中 
-define(CONST_PLAYER_STATE_DEATH,                   5).% 玩家状态--死亡状态 
-define(CONST_PLAYER_STATE_DRUM,                    6).% 玩家状态--宴会玩家转桶状态 
-define(CONST_PLAYER_STATE_KILL_OR_KISS,            7).% 玩家状态--比武招亲 
-define(CONST_PLAYER_STATE_SITTING,                 8).% 玩家状态--坐轿中 
-define(CONST_PLAYER_STATE_SPRING_1,                10).% 玩家状态--温泉1 
-define(CONST_PLAYER_STATE_SPRING_2,                11).% 玩家状态--温泉2 
-define(CONST_PLAYER_STATE_SPRING_3,                12).% 玩家状态--温泉3 

-define(CONST_PLAYER_PLAY_SPRING,                   1).% 角色玩法状态--温泉 
-define(CONST_PLAYER_PLAY_PARTY,                    2).% 角色玩法状态--军团宴会 
-define(CONST_PLAYER_PLAY_BOSS,                     3).% 角色玩法状态--世界boss 
-define(CONST_PLAYER_PLAY_SINGLE_COPY,              4).% 角色玩法状态--单人副本 
-define(CONST_PLAYER_PLAY_MULTI_COPY,               5).% 角色玩法状态--多人副本 
-define(CONST_PLAYER_PLAY_COUNTRY_WAR,              6).% 角色玩法状态--阵营战 
-define(CONST_PLAYER_PLAY_GUIDE,                    7).% 角色玩法状态--守关 
-define(CONST_PLAYER_PLAY_FIGHT4FLAG,               8).% 角色玩法状态--军团夺旗战 
-define(CONST_PLAYER_PLAY_PLUZZ,                    9).% 角色玩法状态--军团迷宫 
-define(CONST_PLAYER_PLAY_TOWER,                    10).% 角色玩法状态--爬塔 
-define(CONST_PLAYER_PLAY_MARRY,                    11).% 角色玩法状态--结婚场景 
-define(CONST_PLAYER_PLAY_CITY,                     12).% 角色玩法状态--城市场景 
-define(CONST_PLAYER_PLAY_MULTI_ARENA,              14).% 角色玩法状态--多人竞技场 
-define(CONST_PLAYER_PLAY_INVASION,                 15).% 角色玩法状态--异民族 
-define(CONST_PLAYER_PLAY_WORLD,                    16).% 角色玩法状态--乱天下 
-define(CONST_PLAYER_PLAY_COLLECT,                  17).% 角色玩法状态--采集 
-define(CONST_PLAYER_PLAYER_CAMP_PVP,               18).% 角色玩法状态--阵营战 
-define(CONST_PLAYER_GUILD_PVP,                     19).% 角色玩法状态--军团战 

-define(CONST_PLAYER_RECONNECT_ERROR_SYS,           1).% 角色重连失败原因--系统错误 
-define(CONST_PLAYER_RECONNECT_ERROR_NO_MINI,       2).% 角色重连失败原因--MiniClient不存在 
-define(CONST_PLAYER_RECONNECT_ERROR_BAD_IP,        3).% 角色重连失败原因--IP错误 
-define(CONST_PLAYER_RECONNECT_ERROR_NO_PRO,        4).% 角色重连失败原因--角色进程不存在 
-define(CONST_PLAYER_RECONNECT_ERROR_PRO_DEAD,      5).% 角色重连失败原因--角色进程死亡 
-define(CONST_PLAYER_RECONNECT_ERROR_BAD_STATE,     6).% 角色重连失败原因--账号被封 

-define(CONST_PLAYER_CREATE_REPEAT_NAME,            1).% 创建角色失败原因--角色名重复 
-define(CONST_PLAYER_CREATE_TIMEOUT,                2).% 创建角色失败原因--服务器超时 

-define(CONST_PLAYER_LOGIN_ERROR_CHECK,             1).% 角色登录失败原因--验证失败 
-define(CONST_PLAYER_LOGIN_ERROR_SYS,               2).% 角色登录失败原因--服务器错误 
-define(CONST_PLAYER_LOGIN_ERROR_BADARG,            3).% 角色登录失败原因--参数错误 
-define(CONST_PLAYER_LOGIN_ERROR_DEBUG,             4).% 角色登录失败原因--调试登陆错误 
-define(CONST_PLAYER_LOGIN_ERROR_FORBID,            5).% 角色登录失败原因--账号禁止登录 
-define(CONST_PLAYER_LOGIN_ERROR_FCM,               6).% 角色登录失败原因--防沉迷 
-define(CONST_PLAYER_LOGIN_ERROR_IP,                7).% 角色登录失败原因--IP限制 
-define(CONST_PLAYER_LOGIN_ERROR_SERVNO,            8).% 角色登录失败原因--服务器号错误 
-define(CONST_PLAYER_LOGIN_ERROR_TIMEOUT,           9).% 角色登录失败原因--md5超时 
-define(CONST_PLAYER_LOGIN_ERROR_CREATE,            10).% 角色登录失败原因--创建角色失败 

-define(CONST_PLAYER_FCM_RESULT_USER_NULL,          -6).% 防沉迷结果--用户不存在 
-define(CONST_PLAYER_FCM_RESULT_RECORD_ERROR,       -5).% 防沉迷结果--登记失败 
-define(CONST_PLAYER_FCM_RESULT_REPEAT,             -4).% 防沉迷结果--不允许重复登记 
-define(CONST_PLAYER_FCM_RESULT_BAD_ID,             -3).% 防沉迷结果--身份证号码无效 
-define(CONST_PLAYER_FCM_RESULT_CHECK_ERROR,        -2).% 防沉迷结果--验证失败 
-define(CONST_PLAYER_FCM_RESULT_BAD_ARG,            -1).% 防沉迷结果--参数不全 
-define(CONST_PLAYER_FCM_RESULT_ADULT,              1).% 防沉迷结果--成年人 
-define(CONST_PLAYER_FCM_RESULT_JUVENILE,           2).% 防沉迷结果--未成年人 

-define(CONST_PLAYER_FCM_CHECK_ADULT,               1).% 防沉迷验证信息--成功登记并且年龄超过18岁 
-define(CONST_PLAYER_FCM_CHECK_JUVENILE,            2).% 防沉迷验证信息--成功登记但年龄没有超过18岁 
-define(CONST_PLAYER_FCM_CHECK_BAD_ARG,             3).% 防沉迷验证信息--参数不全 
-define(CONST_PLAYER_FCM_CHECK_ERROR,               4).% 防沉迷验证信息--验证失败 
-define(CONST_PLAYER_FCM_CHECK_BAD_ID,              5).% 防沉迷验证信息--身份证号码无效 
-define(CONST_PLAYER_FCM_CHECK_REPEAT,              6).% 防沉迷验证信息--不允许重复登记 
-define(CONST_PLAYER_FCM_CHECK_RECORD_ERROR,        7).% 防沉迷验证信息--登记失败 
-define(CONST_PLAYER_FCM_CHECK_USER_NULL,           8).% 防沉迷验证信息--用户不存在 

-define(CONST_PLAYER_TRAIN_TYPE_0,                  0).% 培养类型--普通培养 
-define(CONST_PLAYER_TRAIN_TYPE_1,                  1).% 培养类型--加强培养 
-define(CONST_PLAYER_TRAIN_TYPE_2,                  2).% 培养类型--白金培养 
-define(CONST_PLAYER_TRAIN_TYPE_3,                  3).% 培养类型--钻石培养 
-define(CONST_PLAYER_TRAIN_TYPE_4,                  4).% 培养类型--至尊培养 
-define(CONST_PLAYER_TRAIN_TYPE_5,                  5).% 培养类型--一键培养 

-define(CONST_PLAYER_CULTI_MIN_POINT,               1).% 修为下限 
-define(CONST_PLAYER_CULTI_DEFAULT_COUNTER,         1).% 默认连击数 
-define(CONST_PLAYER_CULTI_MAX_POINT,               10000).% 修为上限 
-define(CONST_PLAYER_CULTI_DEFAULT_RATE_ANGER,      10000).% 默认怒气系数 
-define(CONST_PLAYER_CULTI_DEFAULT_FACTOR,          12500).% 默认连续技系数 
-define(CONST_PLAYER_CULTI_GOODS_ID,                1090703103).% 修为保护符 

-define(CONST_PLAYER_LIST_RAID_CAN_CHANGE,          [12,13]).% 扫荡中能进的玩法列表 

-define(CONST_PLAYER_SP_PER_BUY,                    30).% 每次购买体力增加的体力值 

-define(CONST_PLAYER_STATE_SP_RAID,                 1).% 扫荡 
-define(CONST_PLAYER_STATE_SP_COMMERCE,             2).% 押镖 

-define(CONST_PLAYER_GIFT_TYPE_COMMON,              0).% 角色礼包类型：通用类型 
-define(CONST_PLAYER_GIFT_TYPE_NEWBIE,              201).% 角色礼包类型：新手礼包 
-define(CONST_PLAYER_GIFT_TYPE_COLLECT,             202).% 角色礼包类型：收藏礼包 
-define(CONST_PLAYER_GIFT_TYPE_PHONE,               203).% 角色礼包类型：手机绑定礼包 
-define(CONST_PLAYER_GIFT_TYPE_LOGIN_DAILY,         204).% 角色礼包类型：每日登陆礼包 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER,              205).% 角色礼包类型：夏日礼包 
-define(CONST_PLAYER_GIFT_TYPE_ORDER,               206).% 角色礼包类型：预约礼包 
-define(CONST_PLAYER_GIFT_TYPE_MAIDEN,              207).% 角色礼包类型：首冲礼包 
-define(CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_6,  36).% 角色礼包类型: 360等级礼包6级 
-define(CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_7,  37).% 角色礼包类型: 360等级礼包7级 
-define(CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_8,  38).% 角色礼包类型: 360等级礼包8级 
-define(CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_9,  39).% 角色礼包类型: 360等级礼包9级 
-define(CONST_PLAYER_CONST_PLAYER_GIFT_TYPE_360_15,  40).% 角色礼包类型: 360等级礼包15级 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_4399,          41).% 角色礼包类型:媒体礼包(4399) 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_07073_20,      51).% 角色礼包类型：媒体礼包(07073|20) 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_07073_30,      52).% 角色礼包类型：媒体礼包(07073|30) 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_07073_50,      53).% 角色礼包类型：媒体礼包(07073|50) 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_265G_30,       56).% 角色礼包类型：媒体礼包(265G|50) 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_BD_20,         61).% 角色礼包类型：媒体礼包(百度|20) 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_188,          71).% 角色礼包类型：夏末礼包188 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_888,          72).% 角色礼包类型：夏末礼包888 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_1888,         73).% 角色礼包类型：夏末礼包1888 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_5888,         74).% 角色礼包类型：夏末礼包5888 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_10888,        75).% 角色礼包类型：夏末礼包10888 
-define(CONST_PLAYER_GIFT_TYPE_SUMMER_88888,        76).% 角色礼包类型：夏末礼包88888 
-define(CONST_PLAYER_GIFT_TYPE_MID_AUTUNM,          81).% 角色礼包类型：中秋300-500元宝礼包兑换 
-define(CONST_PLAYER_GIFT_TYPE_FESTIVAL,            100).% 角色礼包类型：节日礼包 
-define(CONST_PLAYER_GIFT_TYPE_SHOP1,               101).% 角色礼包类型：积分商城激活码1 
-define(CONST_PLAYER_GIFT_TYPE_SHOP2,               102).% 角色礼包类型：积分商城激活码2 
-define(CONST_PLAYER_GIFT_TYPE_SHOP3,               103).% 角色礼包类型：积分商城激活码3 
-define(CONST_PLAYER_GIFT_TYPE_SHOP4,               104).% 角色礼包类型：积分商城激活码4 
-define(CONST_PLAYER_GIFT_TYPE_SHOP5,               105).% 角色礼包类型：积分商城激活码5 
-define(CONST_PLAYER_GIFT_TYPE_WEIXIN,              106).% 角色礼包类型：微信礼包 
-define(CONST_PLAYER_GIFT_TYPE_MEDIA_4399_2,        107).% 角色礼包类型：媒体礼包4399_2 

-define(CONST_PLAYER_LOG_TYPE_LOGIN,                1).% 日志操作类型：角色登陆 
-define(CONST_PLAYER_LOG_TYPE_LOGOUT,               2).% 日志操作类型：角色登出 

-define(CONST_PLAYER_LOG_CASH_TYPE_DEPOIST,         0).% 元宝日志--充值 
-define(CONST_PLAYER_LOG_CASH_TYPE_GAME,            1).% 元宝日志--游戏内部发放 
-define(CONST_PLAYER_LOG_CASH_TYPE_OTHER,           4).% 元宝日志--其他 

-define(CONST_PLAYER_HIDE_SKIN_TYPE_FASHION,        1).% 隐藏皮肤类型--时装 
-define(CONST_PLAYER_HIDE_SKIN_TYPE_HORSE,          2).% 隐藏皮肤类型--坐骑 
-define(CONST_PLAYER_HIDE_SKIN_TYPE_VIP,            3).% 隐藏皮肤类型--vip等级 

-define(CONST_PLAYER_CHANGE_NAME_PERSON,            1).% 改名类型--个人 
-define(CONST_PLAYER_CHANGE_NAME_GUILD,             2).% 改名类型--军团 
-define(CONST_PLAYER_CHANGE_NAME_GOODS,             3).% 改名类型--改名卡 

-define(CONST_PLAYER_TRAIN_OPEN_LEVEL,              80).% 培养开放最大等级 

-define(CONST_PLAYER_TEST_AWARD,                    [50,50,50,50,50,50,50,50,50,50]).% 体验服：元宝 

-define(CONST_PLAYER_EXCH_NAME_GOODS,               1093000046).% 改名卡id 

%% ==========================================================
%% ETS相关
%% ==========================================================
-define(CONST_ETS_ARENA_REPORT_CAMPION,             ets_arena_report_campoin).% 一骑讨冠军战报 
-define(CONST_ETS_CAMP_PVP_BOX,                     ets_camp_pvp_box).% 宝箱列表 
-define(CONST_ETS_CAMP_PVP_CAMP,                    ets_camp_pvp_camp).% 阵营列表 
-define(CONST_ETS_CAMP_PVP_COUNTER,                 ets_camp_pvp_counter).% 阵营战跨服计数 
-define(CONST_ETS_CAMP_PVP_DATA,                    ets_camp_pvp_data).% 阵营战数据 
-define(CONST_ETS_CAMP_PVP_INVITE,                  ets_camp_pvp_invite).% 邀请列表 
-define(CONST_ETS_CAMP_PVP_MONSTER,                 ets_camp_pvp_monster).% 怪物列表 
-define(CONST_ETS_CAMP_PVP_PK_CD,                   ets_camp_pvp_pk_cd).% 大演武pk cd 
-define(CONST_ETS_CAMP_PVP_PLAYER,                  ets_camp_pvp_player).% 阵营玩家列表 
-define(CONST_ETS_CAMP_PVP_ROOM,                    ets_camp_pvp_room).% 阵营战房间 
-define(CONST_ETS_CAMP_PVP_TEAM_CROSS,              ets_camp_pvp_team_cross).% 队伍纪律 
-define(CONST_ETS_CAMP_TEAM_INDEX,                  ets_camp_pvp_team_index).% 阵营战队伍索引 
-define(CONST_ETS_CAMP_TEAM_LIST,                   ets_camp_pvp_team_list).% 阵营战队伍列表 
-define(CONST_ETS_CARD21,                           ets_card21).% 21点record 
-define(CONST_ETS_CROSS_ARENA_MATCH,                ets_cross_arena_match).% 跨服战群雄 
-define(CONST_ETS_CROSS_IN,                         ets_cross_in).% 跨服进来的玩家列表 
-define(CONST_ETS_CROSS_NODE_INFO,                  ets_cross_node_info).% 阵营战跨服信息 
-define(CONST_ETS_CROSS_OUT,                        ets_cross_out).% 跨服出去的玩家 
-define(CONST_ETS_CROSS_USER,                       ets_cross_user).% 计数信息 
-define(CONST_ETS_GUILD_APPLY,                      ets_guild_apply).% 军团申请 
-define(CONST_ETS_GUILD_DATA,                       ets_guild_data).% 军团列表 
-define(CONST_ETS_GUILD_MEMBER,                     ets_guild_member).% 军团成员 
-define(CONST_ETS_GUILD_PARTY,                      ets_guild_party).% 军团宴会 
-define(CONST_ETS_GUILD_PARTY_MEMBER,               ets_guild_party_member).% 军团宴会成员 
-define(CONST_ETS_GUILD_PVP_ATT_WALL,               ets_guild_pvp_att_wall).% 采集玩家列表 
-define(CONST_ETS_GUILD_PVP_CAMP,                   ets_guild_pvp_camp).% 军团战阵营 
-define(CONST_ETS_GUILD_PVP_GUILD,                  ets_guild_pvp_guild).% 军团战军团 
-define(CONST_ETS_GUILD_PVP_MAP_INFO,               ets_guild_pvp_map_info).% 军团战主城信息 
-define(CONST_ETS_GUILD_PVP_MONSTER,                ets_guild_pvp_monster).% 军团战 怪物列表 
-define(CONST_ETS_GUILD_PVP_PLAYER,                 ets_guild_pvp_player).% 军团战玩家 
-define(CONST_ETS_GUILD_PVP_PLAYER_RANK,            ets_guild_pvp_player_rank).% 各个军团玩家排行 
-define(CONST_ETS_GUILD_PVP_RANK,                   ets_guild_pvp_rank).% 军团战排名 
-define(CONST_ETS_GUILD_PVP_STATE,                  ets_guild_pvp_state).% 军团战状态 
-define(CONST_ETS_GUILD_PVP_WATER,                  ets_guild_pvp_water).% 观察城墙的人 
-define(CONST_ETS_GUILD_TIME,                       ets_guild_time).% 退出军团冷却时间 
-define(CONST_ETS_GUN_AWARD_EVERYDAY,               ets_gun_award_everyday).% 滚服礼券每日累计 
-define(CONST_ETS_GUN_CASH_GLOBAL,                  ets_gun_cash_global).% 滚服礼券 中心服 
-define(CONST_ETS_GUN_CASH_LOCAL,                   ets_gun_cash_local).% 滚服礼券 
-define(CONST_ETS_NODE_INFO,                        ets_node_info).% 跨服节点信息 
-define(CONST_ETS_NODES_CONFIG,                     ets_nodes_config).% 跨服配置 
-define(CONST_ETS_SERV_INFO,                        ets_serv_info).% 跨服服务器信息 
-define(CONST_ETS_TEAM_AUTHOR,                      ets_team_author).% 组队授权 

-define(CONST_ETS_MAP,                              ets_map).% 地图ETS 
-define(CONST_ETS_MAP_INFO,                         ets_map_info).% 地图信息 
-define(CONST_ETS_MAP_PLAYER,                       ets_map_player).% 地图角色ETS 
-define(CONST_ETS_MD5,                              ets_md5).% 登陆md5记录 
-define(CONST_ETS_MINI_CLIENT,                      ets_mini_client).% 闪断重连缓存 
-define(CONST_ETS_NET,                              ets_net).% 在线玩家的网络进程id 
-define(CONST_ETS_PLAYER_ACCOUNT,                   ets_player_account).% 角色--平台账号|角色ID对应ETS 
-define(CONST_ETS_PLAYER_ACCOUNT_2,                 ets_player_account_2).% 角色--平台账号|角色ID对应ETS_2 
-define(CONST_ETS_PLAYER_CODES,                     ets_player_codes).% 角色--激活码ETS 
-define(CONST_ETS_PLAYER_DEPOSIT,                   ets_player_deposit).% 角色--充值 
-define(CONST_ETS_PLAYER_GOODS_LIMIT,               ets_player_goods_limit).% 角色--全服物品掉落限制 
-define(CONST_ETS_PLAYER_IP,                        ets_player_ip).% 角色--在线角色IP 
-define(CONST_ETS_PLAYER_MONEY,                     ets_player_money).% 角色--货币ETS 
-define(CONST_ETS_PLAYER_NAME,                      ets_player_name).% 角色--角色名|角色ID对应ETS 
-define(CONST_ETS_PLAYER_OFFLINE,                   ets_player_offline).% 角色--离线玩家ETS 
-define(CONST_ETS_PLAYER_ONLINE,                    ets_player_online).% 角色--在线玩家ETS 
-define(CONST_ETS_SYS,                              ets_sys).% 系统配置 

-define(CONST_ETS_BLESS_INFO,                       ets_bless_info).% 玩家祝福信息 
-define(CONST_ETS_BLESS_USER,                       ets_bless_user).% 玩家祝福瓶信息 
-define(CONST_ETS_RELATION_BE,                      ets_relation_be).% 关系对方列表 
-define(CONST_ETS_RELATION_DATA,                    ets_relation_data).% 关系列表 

-define(CONST_ETS_MAIL,                             ets_mail).% 邮件ETS 

-define(CONST_ETS_PRACTICE,                         ets_practice).% 修炼 
-define(CONST_ETS_PRACTICE_DOLL,                    ets_practice_doll).% 修炼替身 
-define(CONST_ETS_PRACTICE_USER,                    ets_practice_user).% 修炼-玩家 

-define(CONST_ETS_ARENA_MEMBER,                     ets_arena_member).% 竞技场信息 
-define(CONST_ETS_ARENA_RANK,                       ets_arena_rank).% 竞技场英雄榜 
-define(CONST_ETS_ARENA_REPORT,                     ets_arena_report).% 竞技场战报 
-define(CONST_ETS_ARENA_REWARD,                     ets_arena_reward).% 竞技场奖励 
-define(CONST_ETS_CROSS_ARENA_GROUP_REPORT,         ets_cross_arena_group_report).% 跨服竞技场组战报 
-define(CONST_ETS_CROSS_ARENA_MEMBER,               ets_cross_arena_member).% 跨服竞技场信息 
-define(CONST_ETS_CROSS_ARENA_PHASE,                ets_cross_arena_phase).% 跨服竞技场段位信息 
-define(CONST_ETS_CROSS_ARENA_REPORT,               ets_cross_arena_report).% 跨服竞技场战报信息 
-define(CONST_ETS_CROSS_ARENA_ROBOT,                ets_cross_arena_robot).% 跨服竞技场机器人 

-define(CONST_ETS_MALL,                             ets_mall).% 商城 
-define(CONST_ETS_MALL_DISCOUNT,                    ets_mall_discount).% 商城折扣 
-define(CONST_ETS_MALL_SALE,                        ets_mall_sale).% 商城限时抢购 

-define(CONST_ETS_MARKET_BUY,                       ets_market_buy).% 拍卖购买ETS 
-define(CONST_ETS_MARKET_SALE,                      ets_market_sale).% 拍卖寄售ETS 
-define(CONST_ETS_MARKET_SEARCH,                    ets_market_search).% 拍卖热门搜索 

-define(CONST_ETS_GROUP,                            ets_group).% 组队信息 
-define(CONST_ETS_GROUP_APPLY,                      ets_group_apply).% 组队申请 

-define(CONST_ETS_RANK,                             ets_rank).% 排行榜 
-define(CONST_ETS_RANK_AVG_LV,                      ets_rank_avg_lv).% 排行榜平均等级 
-define(CONST_ETS_RANK_DATA,                        ets_rank_data).% 排行榜数据 
-define(CONST_ETS_RANK_EQUIP,                       ets_rank_equip).% 排行榜-装备 
-define(CONST_ETS_RANK_PARTNER,                     ets_rank_partner).% 排行榜-武将 

-define(CONST_ETS_LOTTERY,                          ets_lottery).% 淘宝 

-define(CONST_ETS_HOME,                             ets_home).% 家园列表 

-define(CONST_ETS_HORSE,                            ets_horse).% 坐骑 
-define(CONST_ETS_HORSE_DEVELOP,                    ets_horse_develop).% 坐骑培养 
-define(CONST_ETS_HORSE_TRAIN,                      ets_horse_train).% 坐骑洗练未保存值 

-define(CONST_ETS_SPRING,                           ets_spring).% 温泉 
-define(CONST_ETS_SPRING_DOLL,                      ets_spring_doll).% 温泉替身 
-define(CONST_ETS_SPRING_INFO,                      ets_spring_info).% 温泉信息 

-define(CONST_ETS_MONSTER,                          ets_monster).% 怪物 

-define(CONST_ETS_TOWER_PASS,                       ets_tower_pass).% 闯塔 
-define(CONST_ETS_TOWER_PLAYER,                     ets_tower_player).% 闯塔记录 

-define(CONST_ETS_CARAVAN,                          ets_caravan).% 商路记录 
-define(CONST_ETS_COMMERCE,                         ets_commerce).% 商路玩家信息 
-define(CONST_ETS_COMMERCE_FRIEND,                  ets_commerce_friend).% 商路好友 
-define(CONST_ETS_COMMERCE_MARKET,                  ets_commerce_market).% 商路市场 
-define(CONST_ETS_COMMERCE_ONLINE,                  ets_commerce_online).% 商路场景在线 
-define(CONST_ETS_COMMERCE_ROB_INFO,                ets_commerce_rob_info).% 商路战报 

-define(CONST_ETS_RAID_PLAYER,                      ets_raid_player).% 正在进行扫荡的玩家 

-define(CONST_ETS_FURNACE,                          ets_furnace).% 作坊信息 

-define(CONST_ETS_TEAM_CROSS_GLOBAL,                ets_team_cross_global).% 多人组队跨服信息全局 
-define(CONST_ETS_TEAM_CROSS_LOCAL,                 ets_team_cross_local).% 多人组队跨服信息本地 
-define(CONST_ETS_TEAM_CROSS_MASTER,                ets_team_cross_master).% 多人组队跨服信息中心服 
-define(CONST_ETS_TEAM_EXT_ARENA,                   ets_team_ext_arena).% 多人组队扩展--竞技场 
-define(CONST_ETS_TEAM_HALL_ARENA,                  ets_team_hall_arena).% 多人组队大厅--竞技场 
-define(CONST_ETS_TEAM_HALL_COPY,                   ets_team_hall_copy).% 多人组队大厅--副本 
-define(CONST_ETS_TEAM_HALL_INVASION,               ets_team_hall_invasion).% 多人组队大厅--异民族 
-define(CONST_ETS_TEAM_ID_ARENA,                    ets_team_id_arena).% 多人组队ID--竞技场 
-define(CONST_ETS_TEAM_ID_COPY,                     ets_team_id_copy).% 多人组队ID--副本 
-define(CONST_ETS_TEAM_ID_INVASION,                 ets_team_id_invasion).% 多人组队ID--异民族 
-define(CONST_ETS_TEAM_INFO_ARENA,                  ets_team_info_arena).% 多人组队队伍--竞技场 
-define(CONST_ETS_TEAM_INFO_COPY,                   ets_team_info_copy).% 多人组队队伍--副本 
-define(CONST_ETS_TEAM_INFO_INVASION,               ets_team_info_invasion).% 多人组队队伍--异民族 
-define(CONST_ETS_TEAM_INVITE_CD,                   ets_team_invite_cd).% 替身邀请cd 
-define(CONST_ETS_TEAM_PLAYER_ARENA,                ets_team_player_arena).% 多人组队成员--竞技场 
-define(CONST_ETS_TEAM_PLAYER_COPY,                 ets_team_player_copy).% 多人组队成员--副本 
-define(CONST_ETS_TEAM_PLAYER_INVASION,             ets_team_player_invasion).% 多人组队成员--异民族 

-define(CONST_ETS_ACTIVE,                           ets_active).% 活动表 
-define(CONST_ETS_ACTIVE_TIME,                      ets_active_time).% 活动时间表 

-define(CONST_ETS_WELFARE,                          ets_welfare).% 福利列表 

-define(CONST_ETS_COLLECT,                          ets_collect).% 采集 

-define(CONST_ETS_HALL_GUARD,                       ets_hall_guard).% 守关大厅玩家列表 

-define(CONST_ETS_BOSS,                             ets_boss).% 世界BOSS--Boss等级信息 
-define(CONST_ETS_BOSS_COUNTER,                     ets_boss_counter).% 世界boss_人数累计 
-define(CONST_ETS_BOSS_DATA,                        ets_boss_data).% 世界BOSS--Boss数据 
-define(CONST_ETS_BOSS_DOLL,                        ets_boss_doll).% 世界BOSS--替身娃娃 
-define(CONST_ETS_BOSS_L_USER,                      ets_boss_l_user).% 世界boss--本地玩家 
-define(CONST_ETS_BOSS_LV_PHASE,                    ets_boss_lv_phase).% 世界BOSS--等级段 
-define(CONST_ETS_BOSS_N_USER,                      ets_boss_n_user).% 世界boss--近端玩家 
-define(CONST_ETS_BOSS_PLAYER,                      ets_boss_player).% 世界BOSS--玩家数据 
-define(CONST_ETS_BOSS_R_USER,                      ets_boss_r_user).% 世界boss--远端玩家 
-define(CONST_ETS_BOSS_ROBOT_SETTING,               ets_boss_robot_setting).% 世界boss--机器人配置 

-define(CONST_ETS_INVASION,                         ets_invasion).% 异民族--异民族数据 
-define(CONST_ETS_INVASION_DOLL,                    ets_invasion_doll).% 异民族--替身参加 
-define(CONST_ETS_MONSTER_INVASION,                 ets_monster_invasion).% 异民族--怪物数据 

-define(CONST_ETS_ARENA_PVP,                        ets_arena_pvp).% 多人竞技场 
-define(CONST_ETS_ARENA_PVP_M,                      ets_arena_pvp_m).% 多人竞技场成员 
-define(CONST_ETS_ARENA_PVP_RANK,                   ets_arena_pvp_rank).% 多人竞技场排名 

-define(CONST_ETS_WORLD_BASE,                       ets_world_base).% 乱天下--基础数据 
-define(CONST_ETS_WORLD_DATA,                       ets_world_data).% 乱天下--乱天下数据 
-define(CONST_ETS_WORLD_PLAYER,                     ets_world_player).% 乱天下--玩家数据 
-define(CONST_ETS_WORLD_ROBOT,                      ets_world_robot).% 乱天下--机器人信息 

-define(CONST_ETS_ADMIN_ORDER_MAIL,                 admin_order_mail).% 游戏后台--邮件发送货币、道具订单 

-define(CONST_ETS_FACTION_SIGN_USER,                ets_faction_sign_user).% 阵营战报名的人 

-define(CONST_ETS_MCOPY_INFO,                       ets_mcopy_info).% 多人副本信息 
-define(CONST_ETS_MONSTER_FACTION,                  ets_monster_faction).% 阵营战怪物列表 
-define(CONST_ETS_MONSTER_MCOPY,                    ets_monster_mcopy).% 多人副本怪物 

-define(CONST_ETS_UNIQUE_TITLE,                     ets_unique_title).% 唯一性称号 

-define(CONST_ETS_RAID_ELITE_PLAYER,                ets_raid_elite_player).% 精英副本扫荡玩家 

-define(CONST_ETS_CONTACTED,                        ets_contacted).% 最近联系人列表 

-define(CONST_ETS_TIME,                             ets_time).% 时间 

-define(CONST_ETS_PARTY_ACTIVE,                     ets_party_active).% 宴会-活动 
-define(CONST_ETS_PARTY_AUTO,                       ets_party_auto).% 宴会-自动参加 
-define(CONST_ETS_PARTY_DATA,                       ets_party_data).% 宴会-数据 
-define(CONST_ETS_PARTY_DOLL,                       ets_party_doll).% 宴会-替身 
-define(CONST_ETS_PARTY_PLAYER,                     ets_party_player).% 宴会-玩家 

-define(CONST_ETS_NEW_SERV_RANK,                    ets_new_serv_rank).% 新服活动排名奖 

-define(CONST_ETS_REFRESH_TIME,                     ets_refresh_time).% 刷新时间 

-define(CONST_ETS_CAMP_PVP_BUFF,                    ets_camp_pvp_buff).% 阵营活动buff 

-define(CONST_ETS_AUTO_TURN_CARD,                   ets_auto_turn_card).% 元宝自动翻牌 

-define(CONST_ETS_MID_AUTUMN_ACTIVE,                ets_mid_autumn_active).% 中秋充值消费活动 

-define(CONST_ETS_ACTIVE_DEPOSIT,                   ets_active_deposit).% 充值活动 
-define(CONST_ETS_ACTIVE_DEPOSIT_TIME,              ets_active_deposit_time).% 充值活动时间 

-define(CONST_ETS_CHANGED_NAME,                     ets_changed_name).% 改名名单 
-define(CONST_ETS_CHANGED_NAME_GUILD,               ets_changed_name_guild).% 军团改名名单 

-define(CONST_ETS_OFFLINE_DATA,                     ets_offline_data).% 离线数据 

-define(CONST_ETS_ACCOUNT_USER_ID,                  ets_account_user_id).% 帐号-玩家id列表 

-define(CONST_ETS_FCM,                              ets_fcm).% 防沉迷标志 

-define(CONST_ETS_TOWER_REPORT,                     ets_tower_report).% 破阵战报 
-define(CONST_ETS_TOWER_REPORT_IDX,                 ets_tower_report_idx).% 破阵战报索引 

-define(CONST_ETS_COPY_SINGLE_REPORT,               ets_copy_single_report).% 精英副本战报 
-define(CONST_ETS_COPY_SINGLE_REPORT_IDX,           ets_copy_single_report_idx).% 精英副本战报索引 

-define(CONST_ETS_HERO_RANK,                        ets_hero_rank).% 开服活动英雄榜 
-define(CONST_ETS_HONOR_TITLE,                      ets_honor_title).% 开服活动荣誉榜 

-define(CONST_ETS_SHARED_ACCOUNT,                   ets_shared_account).% 共享用户 

-define(CONST_ETS_RES_POOL,                         ets_res_pool).% 奖池 

-define(CONST_ETS_EXCHANGE_INFO,                    ets_exchange_info).% 兑换信息 

-define(CONST_ETS_RESOURCE_LOOKFOR,                 ets_resource_lookfor).% 资源找回 

-define(CONST_ETS_MAP_ROBOT,                        ets_map_robot).% 机器人地图信息 

-define(CONST_ETS_SNOW_INFO,                        ets_snow_info).% 雪夜赏灯—玩家数据 

-define(CONST_ETS_ACTIVE_WELFARE,                   ets_active_welfare).% 运营活动玩家数据 

-define(CONST_ETS_CAMP_PVP_LEADER,                  ets_camp_pvp_leader).% 阵营战主结点信息 
-define(CONST_ETS_CAMP_PVP_LV_PHASE,                ets_camp_pvp_lv_phase).% 阵营战等级段分配信息 
-define(CONST_ETS_CAMP_PVP_NODES,                   ets_camp_pvp_nodes).% 阵营战存活结点信息 
-define(CONST_ETS_CAMP_PVP_SEEDS,                   ets_camp_pvp_seeds).% 阵营战种子选手列表 

-define(CONST_ETS_GLOBE_ACTIVE,                     ets_globe_active).% 全服--活动申请 
-define(CONST_ETS_GLOBE_ACTIVE_STATE,               ets_globe_active_state).% 全服--活动情况 
-define(CONST_ETS_GLOBE_SETTING,                    ets_globe_setting).% 全服--boss配置信息 

-define(CONST_ETS_ACTIVE_STONE_COMPOSE,             ets_active_stone_compose).% 活动宝石合成 

-define(CONST_ETS_CARD_EXCHANGE_PARTNER,            ets_card_exchange_partner).% 抽卡换武将 

-define(CONST_ETS_BOSS_CROSS_COUNTER,               ets_boss_cross_counter).% 世界boss节点计数器 
-define(CONST_ETS_BOSS_CROSS_IN,                    ets_boss_cross_in).% 世界boss跨服进来的玩家 
-define(CONST_ETS_BOSS_CROSS_LEADER,                ets_boss_cross_leader).% 世界boss主节点信息 
-define(CONST_ETS_BOSS_CROSS_LV_PHASE,              ets_boss_cross_lv_phase).% 世界boss等级段分配信息 
-define(CONST_ETS_BOSS_CROSS_NODES,                 ets_boss_cross_nodes).% 世界boss存活节点信息 
-define(CONST_ETS_BOSS_CROSS_OUT,                   ets_boss_cross_out).% 世界boss跨服出去的玩家 
-define(CONST_ETS_BOSS_CROSS_ROOM,                  ets_boss_cross_room).% 世界boss房间信息 
-define(CONST_ETS_BOSS_CROSS_SEEDS,                 ets_boss_cross_seeds).% 世界boss种子选手列表 
-define(CONST_ETS_BOSS_CROSS_USER,                  ets_boss_cross_user).% 世界boss节点人物信息 

-define(CONST_ETS_CENTER_NODE_INFO,                 ets_center_node_info).% 服-结点对照表 

-define(CONST_ETS_ARCHERY_GRAVITY_T,                ets_archery_gravity_t).% 辕门射戟重力 
-define(CONST_ETS_ARCHERY_INFO,                     ets_archery_info).% 辕门射戟信息表 

-define(CONST_ETS_ENCROACH_INFO,                    ets_encroach_info).% 攻城掠地玩家信息 
-define(CONST_ETS_ENCROACH_RANK,                    ets_encroach_rank).% 攻城掠地排行榜 

-define(CONST_ETS_SECRET,                           ets_secret).% 云游商人数据 
-define(CONST_ETS_SECRET_INFO,                      ets_secret_info).% 云游商人玩家信息 

-define(CONST_ETS_LATERN,                           ets_latern).% 元宵副本 

-define(CONST_ETS_MIXED_SERV_ACT,                   ets_mixed_serv_activity).% 合服活动 

-define(CONST_ETS_GAMBLE_PLAYER,                    ets_gamble_player).% 青梅煮酒玩家 
-define(CONST_ETS_GAMBLE_ROOM,                      ets_gamble_room).% 青梅煮酒房间 
-define(CONST_ETS_GAMBLE_ROOM_MINI,                 ets_gamble_room_mini).% 青梅煮酒房间跨服 

-define(CONST_ETS_ACT_HUNDRED,                      ets_act_hundred).% 百服活动:玩家信息 
-define(CONST_ETS_ACT_HUNDRED_RANK,                 ets_act_hundred_rank).% 百服活动：排名 
-define(CONST_ETS_ACT_INFO,                         ets_act_info).% 活动情况 
-define(CONST_ETS_ACT_TEMP,                         ets_act_temp).% 活动模版 
-define(CONST_ETS_ACT_USER,                         ets_act_user).% 运营活动玩家数据 

-define(CONST_ETS_MIXED_SERV,                       ets_mixed_serv_rank).% 合服活动排名 

-define(CONST_ETS_MATCH_COPY,                       ets_match_copy).% 闯关比赛关卡个人信息 
-define(CONST_ETS_MATCH_COPY_IDX,                   ets_match_copy_idx).% 闯关比赛关卡信息索引 
-define(CONST_ETS_MATCH_PLAYER,                     ets_match_player).% 闯关比赛个人信息 
-define(CONST_ETS_MATCH_RANK,                       ets_match_rank).% 闯关比赛排行榜 

-define(CONST_ETS_MAN_HOUTAI,                       ets_man_houtai).% 中心--后台 

-define(CONST_ETS_TENCENT_INFO,                       ets_tencent_info).

-define(CONST_ETS_TENCENT_INVITE_INFO,                       ets_tencent_invite_info).

-define(CONST_ETS_TENCENT_PAY_TOKEN,                       ets_tencent_pay_token).

%% ==========================================================
%% 军团
%% ==========================================================
-define(CONST_GUILD_SKILL_TYPE_LV,                  1).% 六韬 
-define(CONST_GUILD_SKILL_TYPE_MISSION,             2).% 九章 
-define(CONST_GUILD_SKILL_TYPE_SHOP,                3).% 百宝 
-define(CONST_GUILD_SKILL_TYPE_EXP,                 4).% 武经七书 
-define(CONST_GUILD_SKILL_TYPE_MEMBER,              5).% 府兵制 
-define(CONST_GUILD_SKILL_TYPE_BUSINESS,            6).% 木牛流马 
-define(CONST_GUILD_SKILL_TYPE_COPY,                7).% 制图六体 
-define(CONST_GUILD_SKILL_TYPE_HOME,                8).% 翻车 
-define(CONST_GUILD_SKILL_TYPE_FUNDS,               9).% 屯田 
-define(CONST_GUILD_SKILL_TYPE_GROWTH,              10).% 石工 

-define(CONST_GUILD_LOG_CREATE,                     1).% 日志-创建 
-define(CONST_GUILD_LOG_JOIN,                       2).% 日志-加入 
-define(CONST_GUILD_LOG_QUIT,                       3).% 日志-退出 
-define(CONST_GUILD_LOG_KICK,                       4).% 日志-踢出 
-define(CONST_GUILD_LOG_CHIEF,                      5).% 日志-官位提升-团长 
-define(CONST_GUILD_LOG_VICE_CHIEF,                 6).% 日志-官位提升-副团长 
-define(CONST_GUILD_LOG_ELDER,                      7).% 日志-官位提升-督军 
-define(CONST_GUILD_LOG_ELITE,                      8).% 日志-官位提升-功曹 
-define(CONST_GUILD_LOG_EXECUTIVE,                  9).% 日志-官位提升-车兵卫 
-define(CONST_GUILD_LOG_MEMBER,                     10).% 日志-官位提升-成员 
-define(CONST_GUILD_LOG_CASH,                       11).% 日志-官位提升-捐献元宝 
-define(CONST_GUILD_LOG_BIND_GOLD,                  12).% 日志-官位提升-捐献铜钱 
-define(CONST_GUILD_LOG_IMPACHIEF,                  13).% 日志-军团长弹劾 
-define(CONST_GUILD_LOG_GOODS,                      14).% 日志-分配物品 
-define(CONST_GUILD_LOG_DEFAULT_ADD,                15).% 日志-默认技能增加进度 
-define(CONST_GUILD_LOG_DOWN_VICE_CHIEF,            21).% 日志-官位降低-副团长 
-define(CONST_GUILD_LOG_DOWN_ELITE,                 22).% 日志-官位降低-功曹 
-define(CONST_GUILD_LOG_DOWN_EXECUTIVE,             23).% 日志-官位降低-车兵卫 
-define(CONST_GUILD_LOG_DOWN_MEMBER,                24).% 日志-官位降低-成员 

-define(CONST_GUILD_DEFAULT_MAGIC_LV,               0).% 默认法术等级 
-define(CONST_GUILD_DEFAULT_MAGIC_PROGRESS,         0).% 初始法术进度 
-define(CONST_GUILD_DEFAULT_LV,                     1).% 军团默认等级 
-define(CONST_GUILD_DEFAULT_SKILL,                  1).% 默认技能 
-define(CONST_GUILD_NAME_MIN_SIZE,                  2).% 帮派名字最短限制 
-define(CONST_GUILD_DEFAULT_REDUCE_ATMOSPHERE,      2).% 每三十秒减少氛围 
-define(CONST_GUILD_DISBAND_GUILD_NUM_LIMIT,        4).% 解散军团最大人数 
-define(CONST_GUILD_DEFAULT_NUM_LIMIT,              5).% 军团默认人数上限 
-define(CONST_GUILD_DEFAULT_GUILD_APPLY_LIMIT,      5).% 军团默认申请限制 
-define(CONST_GUILD_IMPEACH_TIME,                   7).% 弹劾团长天数 
-define(CONST_GUILD_DEFAULT_APPLY_LIMIT,            8).% 申请人数上限 
-define(CONST_GUILD_NAME_MAX_SIZE,                  12).% 军团名字最长限制 
-define(CONST_GUILD_DEFAULT_JOIN_GUILD_LV,          20).% 加入帮派最低等级 
-define(CONST_GUILD_CREATE_GOLD_NEED,               20).% 创建军团所需元宝数 
-define(CONST_GUILD_INVITE_TIME,                    30).% 邀请时间间隔 
-define(CONST_GUILD_CRAETE_MEM_COUNT,               30).% 创建初始人数 
-define(CONST_GUILD_LOGS_NUM,                       50).% 日志条数 
-define(CONST_GUILD_SUP_MONEY,                      10000).% 快速邀请花费铜钱 
-define(CONST_GUILD_CREATE_COIN_NEED,               1000000).% 创建军团所需铜钱数量 

-define(CONST_GUILD_PALYER_STATE_APPLY_NO,          1).% 军团未申请 
-define(CONST_GUILD_PALYER_STATE_APPLY_YES,         2).% 军团已申请 
-define(CONST_GUILD_PALYER_STATE_JOIN,              3).% 军团已加入 
-define(CONST_GUILD_PLAYER_STATE_COLD,              4).% 冷却时间中 
-define(CONST_GUILD_CONST_TEAM_TYPE_GROUP,          4).% 军团申请邀请 

-define(CONST_GUILD_POSITION_CHIEF,                 1).% 军团长 
-define(CONST_GUILD_POSITION_VICE_CHIEF,            2).% 副团长 
-define(CONST_GUILD_POSITION_ELDER,                 3).% 督军 
-define(CONST_GUILD_POSITION_ELITE,                 4).% 千夫长 
-define(CONST_GUILD_POSITION_EXECUTIVE,             5).% 百夫长 
-define(CONST_GUILD_POSITION_COMMON,                6).% 成员 

-define(CONST_GUILD_SKILL,                          1).% 技能 
-define(CONST_GUILD_MAGIC,                          2).% 术功 

-define(CONST_GUILD_CASH_DONATE_RATE,               5).% 元宝捐钱比例(1元宝1贡献) 
-define(CONST_GUILD_DONATE_RATE,                    100).% 铜钱捐钱比例(1000铜钱1贡献) 
-define(CONST_GUILD_WELFARE,                        10000).% 工资基本值 

-define(CONST_GUILD_PARTY_ENTER,                    1).% 宴会-加入宴会 
-define(CONST_GUILD_PARTY_LEAVE,                    2).% 宴会-离开宴会 
-define(CONST_GUILD_PARTY_FIRE,                     3).% 宴会-施放烟花 
-define(CONST_GUILD_PARTY_SMALL_CRIT,               4).% 宴会-小暴击 
-define(CONST_GUILD_PARTY_BIG_CRIT,                 5).% 宴会-大暴击 

-define(CONST_GUILD_PARTY_FREE,                     0).% 宴会-空闲 
-define(CONST_GUILD_PARTY_GUESS,                    1).% 宴会-猜拳 
-define(CONST_GUILD_PARTY_ROCK,                     2).% 宴会-摇色子 

-define(CONST_GUILD_PRATY_FIST,                     1).% 宴会-拳头 
-define(CONST_GUILD_PRATY_NET,                      2).% 宴会-布 
-define(CONST_GUILD_PRATY_SCISSORS,                 3).% 宴会-剪刀 

-define(CONST_GUILD_PARTY_LOST,                     0).% 宴会-对方赢 
-define(CONST_GUILD_PARTY_WIN,                      1).% 宴会-我赢 
-define(CONST_GUILD_PARTY_AGAIN,                    2).% 宴会-打平 

-define(CONST_GUILD_PARTY_END,                      0).% 宴会-结束 
-define(CONST_GUILD_PARTY_START,                    1).% 宴会-开始 
-define(CONST_GUILD_PARTY_READY,                    2).% 宴会-准备 

-define(CONST_GUILD_PARTY_GUESS_WIN,                2).% 宴会猜拳胜利 
-define(CONST_GUILD_DEFAULT_ATMOSPHERE_PERPLAY,     5).% 每次施放烟火增加 
-define(CONST_GUILD_PARTY_GUESS_TIMES,              5).% 宴会猜拳次数 
-define(CONST_GUILD_PARTY_ROCK_TIMES,               5).% 宴会摇色子次数 
-define(CONST_GUILD_PARTY_DESK_GOLD,                10).% 重置全肉宴(元宝) 
-define(CONST_GUILD_PARTY_DESK_REWARD,              20).% 宴会每桌奖励 
-define(CONST_GUILD_DEFAULT_PARTY_TIMER,            30).% 定时计算秒数 
-define(CONST_GUILD_PARTY_AUTO_COST,                30).% 自动参加宴会花费 
-define(CONST_GUILD_DEFAULT_ATMOSPHERE,             100).% 氛围初始值 
-define(CONST_GUILD_PARTY_REWARD_TIME,              120).% 宴会定时奖励（秒） 
-define(CONST_GUILD_PARTY_TIME,                     1800).% 宴会时间（秒） 

-define(CONST_GUILD_MEM_LEAVE,                      1).% 离开游戏 
-define(CONST_GUILD_MEM_EXIT,                       2).% 退出宴会 

-define(CONST_GUILD_REW_NORMAL,                     1).% 宴会-正常 
-define(CONST_GUILD_REW_SMALL_CRIT,                 2).% 宴会-小暴击 
-define(CONST_GUILD_REW_BIG_CRIT,                   3).% 宴会-大暴击 

-define(CONST_GUILD_PARTY_NOT_VIP,                  1).% 宴会-非vip 
-define(CONST_GUILD_PARTY_VIP,                      2).% 宴会-vip 
-define(CONST_GUILD_PARTY_DINNER,                   3).% 宴会-全肉宴 

-define(CONST_GUILD_PARTY_ONE,                      1).% 宴会-下午 
-define(CONST_GUILD_PARTY_TWO,                      2).% 宴会-晚上 
-define(CONST_GUILD_PARTY_MAP,                      35001).% 宴会场景 

-define(CONST_GUILD_PARTY_DOLL_TODAY,               0).% 宴会-替身设置今天 
-define(CONST_GUILD_PARTY_DOLL_TOMORROW,            1).% 宴会-替身设置明天 
-define(CONST_GUILD_PARTY_SP,                       10).% 宴会-获得体力基础值 
-define(CONST_GUILD_PARTY_SP_LIMIT,                 30).% 宴会-增加体力值上限 
-define(CONST_GUILD_PARTY_DOLL_COST,                30).% 宴会-替身花费 
-define(CONST_GUILD_PARTY_SP_INTERVAL,              300).% 宴会-获得体力时间间隔 

-define(CONST_GUILD_NULL,                           0).% 空军团 

-define(CONST_GUILD_CD_TIME,                        4).% cd时间-小时 
-define(CONST_GUILD_CLEAN_CD,                       50).% 清除加入cd花费元宝 

-define(CONST_GUILD_OPERATE_APPLY,                  1).% 操作-申请 
-define(CONST_GUILD_OPERATE_CANCEL_APPLY,           2).% 操作-取消申请 
-define(CONST_GUILD_OPERATE_INVITE,                 4).% 操作-邀请 
-define(CONST_GUILD_OPERATE_REFUSE_INVITE,          5).% 操作-拒绝邀请 
-define(CONST_GUILD_OPERATE_AGREE_INVITE,           6).% 操作-同意邀请 
-define(CONST_GUILD_OPERATE_QUIT,                   7).% 操作-退出 
-define(CONST_GUILD_OPERATE_KICK_OUT,               8).% 操作-踢出 
-define(CONST_GUILD_OPERATE_DISBAND,                9).% 操作-解散 
-define(CONST_GUILD_OPERATE_CREATE,                 10).% 操作-创建 
-define(CONST_GUILD_OPERATE_AGREE_APPLY,            11).% 操作-同意申请 
-define(CONST_GUILD_OPERATE_REJECT_APPLY,           12).% 操作-拒绝申请 
-define(CONST_GUILD_OPERATE_CHANGE_CHIEF,           13).% 操作-更换团长 
-define(CONST_GUILD_OPERATE_PROMOTE_POS,            14).% 操作-提升职位 
-define(CONST_GUILD_OPERATE_REMOVE_POS,             15).% 操作-解除职位 
-define(CONST_GUILD_OPERATE_IMPEACH_CHIEF,          16).% 操作-弹劾团长 
-define(CONST_GUILD_OPERATE_DONATE_GOLD,            21).% 操作-铜钱捐献 
-define(CONST_GUILD_OPERATE_DONATE_CASH,            22).% 操作-元宝捐献 
-define(CONST_GUILD_OPERATE_SKILL_UP,               31).% 操作-技能升级 
-define(CONST_GUILD_OPERATE_MAGIC_UP,               32).% 操作-术法升级 
-define(CONST_GUILD_OPERATE_SHOP_BUY,               41).% 操作-百宝购买 
-define(CONST_GUILD_OPERATE_DISTRIBUTE,             42).% 操作-分配物品 

%% ==========================================================
%% 武将
%% ==========================================================
-define(CONST_PARTNER_STATE_NORMAL,                 0).% 正常状态 
-define(CONST_PARTNER_STATE_FIGHTING,               1).% 出战状态 

-define(CONST_PARTNER_TYPE_STORY,                   1).% 武将类型--剧情 
-define(CONST_PARTNER_TYPE_TOWER,                   2).% 武将类型--破阵 
-define(CONST_PARTNER_TYPE_LOOK,                    3).% 武将类型--寻访 

-define(CONST_PARTNER_TEAM_PUB,                     0).% 队伍状态--可招募（招贤馆中） 
-define(CONST_PARTNER_TEAM_IN,                      1).% 队伍状态--已招募（队伍中） 
-define(CONST_PARTNER_TEAM_CAN_LOOK,                2).% 队伍状态--可寻访（寻访列表中） 
-define(CONST_PARTNER_TEAM_LOOKED,                  3).% 队伍状态--寻访到但未邀请 

-define(CONST_PARTNER_STATION_NORMAL,               0).% 武将身份--普通武将 
-define(CONST_PARTNER_STATION_SKIPPER,              1).% 武将身份--主将 
-define(CONST_PARTNER_STATION_ASSISTER,             2).% 武将身份--副将 

-define(CONST_PARTNER_TRAIN_ATTR_COUNT,             6).% 玩家培养属性数 
-define(CONST_PARTNER_TEAM_LIMIT,                   50).% 玩家最大携带武将数 

-define(CONST_PARTNER_LOOK_PER_BUY_TIMES,           5).% 寻访--每次购买得到的寻访次数 
-define(CONST_PARTNER_CAN_LOOK_NUM,                 5).% 寻访--5次以下才能购买 
-define(CONST_PARTNER_LOOK_VIP_LIMIT,               5).% 寻访--至尊刷将VIP等级限制 
-define(CONST_PARTNER_LOOK_NUM,                     10).% 寻访--每日默认次数 
-define(CONST_PARTNER_LOOK_NEED_CASH,               20).% 寻访--消耗元宝 
-define(CONST_PARTNER_LOOK_OPERATE_STAMP,           30).% 寻访--邀请武将时延 
-define(CONST_PARTNER_EXPIRE_TIME,                  48).% 寻访时限 
-define(CONST_PARTNER_LOOK_ADD_CD,                  60).% 寻访--每次增加cd 
-define(CONST_PARTNER_LOOK_NEED_CASH_MAX,           100).% 寻访--消耗元宝上限 
-define(CONST_PARTNER_LOOK_CD,                      600).% 寻访--cd时间 
-define(CONST_PARTNER_LOOK_CD_MAX,                  1200).% 寻访--cd上限 
-define(CONST_PARTNER_LOOK_TASK_30,                 10071).% 寻访--30级任务id 

-define(CONST_PARTNER_INIT_BAG,                     4).% 招贤馆格子--初始个数 
-define(CONST_PARTNER_MAX_BAG,                      8).% 招贤馆格子--最大个数 
-define(CONST_PARTNER_BAG_COST,                     50).% 招贤馆格子--每个格子花费 

-define(CONST_PARTNER_NO_RECRUITED,                 0).% 未招募过 
-define(CONST_PARTNER_RECRUITED,                    1).% 招募过 

-define(CONST_PARTNER_THE_SECOND,                   11202).% 第二个武将 
-define(CONST_PARTNER_THE_FIRST,                    13201).% 第一个武将 

-define(CONST_PARTNER_INFO_INIT,                    0).% 武将信息--初始推送 
-define(CONST_PARTNER_INFO_NEW,                     1).% 武将信息--新增推送 

-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_1,       1).% 副将界面位置交换--不同位置的主将互换位置 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_2,       2).% 副将界面位置交换--不同位置的主将和副将换位置 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_3,       3).% 副将界面位置交换--不同位置的副将和主将换位置 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_4,       4).% 副将界面位置交换--同位置内的主将和副将可换位置 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_5,       5).% 副将界面位置交换--同位置内的副将和主将可换位置 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_6,       6).% 副将界面位置交换--不同位置内的副将交换 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_7,       7).% 副将界面位置交换--相同位置内的副将交换 
-define(CONST_PARTNER_EXCHANGE_ASSIST_TYPE_8,       8).% 副将界面位置交换--有主副将的位置与阵法空位置的切换 

-define(CONST_PARTNER_ASSIST_ADD_ATTR_RATE,         25).% 副将加成百分比 

-define(CONST_PARTNER_FAMOUS_PASS,                  40).% 名满天下开启关卡数 

-define(CONST_PARTNER_ASSIST_LV_1,                  30).% 开放副将等级--一个副将 
-define(CONST_PARTNER_ASSIST_LV_2,                  50).% 开放副将等级--两个副将 
-define(CONST_PARTNER_ASSIST_LV_3,                  70).% 开放副将等级--三个副将 
-define(CONST_PARTNER_ASSIST_LV_4,                  90).% 开放副将等级--四个副将 

-define(CONST_PARTNER_FREE_TYPE_MANU,               1).% 招贤馆遣散--手动遣散 
-define(CONST_PARTNER_FREE_TYPE_AUTO,               2).% 招贤馆遣散--自动遣散 

-define(CONST_PARTNER_TRAIN_FREE_TIMES,             3).% 免费进阶培养次数 

-define(CONST_PARTNER_LOOK_TYPE_COMMON,             1).% 寻访类型--普通寻访 
-define(CONST_PARTNER_LOOK_TYPE_CASH,               2).% 寻访类型--白银寻访 
-define(CONST_PARTNER_LOOK_TYPE_CASH_2,             3).% 寻访类型--白金寻访 
-define(CONST_PARTNER_LOOK_TYPE_CASH_3,             4).% 寻访类型--至尊寻访 

-define(CONST_PARTNER_TRAIN_ITEM,                   1093000005).% 培养消耗物品id 

-define(CONST_PARTNER_LOOK_USE_CASH,                50).% 寻访消耗--白银元宝 
-define(CONST_PARTNER_LOOK_USE_SEE,                 100).% 寻访消耗--阅历 
-define(CONST_PARTNER_LOOK_USE_CASH_2,              200).% 寻访消耗--元宝 
-define(CONST_PARTNER_LOOK_USE_CASH_3,              499).% 寻访消耗--至尊元宝 
-define(CONST_PARTNER_LOOK_USE_GOODS,               1093000003).% 寻访消耗--拜访礼 

-define(CONST_PARTNER_ASSEMBLE_ADD_EXP,             10).% 武将组合--每个兵书增加组合经验 
-define(CONST_PARTNER_ASSEMBLE_MAX_LV,              20).% 武将组合--组合最大等级 
-define(CONST_PARTNER_ASSEMBLE_UP_GOODS,            1093000004).% 武将组合--兵书 

-define(CONST_PARTNER_LOOK_TASK_1_XZ,               10006).% 前三个武将寻访--任务1(陷阵) 
-define(CONST_PARTNER_LOOK_TASK_1_FJ,               10006).% 前三个武将寻访--任务1(飞军天机) 
-define(CONST_PARTNER_LOOK_TASK_2,                  10035).% 前三个武将寻访--任务2 
-define(CONST_PARTNER_LOOK_TASK_3,                  10054).% 前三个武将寻访--任务3 
-define(CONST_PARTNER_LOOK_PARTNER_1_FZ,            11202).% 前三个武将寻访--武将1(马文鹭) 
-define(CONST_PARTNER_LOOK_PARTNER_2,               12213).% 前三个武将寻访--武将2 
-define(CONST_PARTNER_LOOK_PARTNER_1_XZ,            13201).% 前三个武将寻访--武将1(公孙婷) 
-define(CONST_PARTNER_LOOK_PARTNER_3,               14324).% 前三个武将寻访--武将3 

-define(CONST_PARTNER_LOOK_BAG_FOURTH,              5).% 武将寻访--至尊种子武将包 
-define(CONST_PARTNER_LOOK_ADD_RATE_FOURTH,         200).% 武将寻访--至尊增加权重 

%% ==========================================================
%% 成就
%% ==========================================================
-define(CONST_ACHIEVEMENT_LEVELUP,                  1).% 等级成长 
-define(CONST_ACHIEVEMENT_FORCETRAIN,               2).% 力培养 
-define(CONST_ACHIEVEMENT_MAGICTRAIN,               3).% 术培养 
-define(CONST_ACHIEVEMENT_FATETRAIN,                4).% 命培养 
-define(CONST_ACHIEVEMENT_POSITION,                 5).% 官衔成长 
-define(CONST_ACHIEVEMENT_RECRUIT_PARTNER,          6).% 成功招募公孙婷 
-define(CONST_ACHIEVEMENT_PRESENT_GIFT,             7).% 成功招募一个喜好品武将 
-define(CONST_ACHIEVEMENT_RECRUIT_GOLDPARTNER,      8).% 成功招募一个蓝将 
-define(CONST_ACHIEVEMENT_RECRUIT_PURPLEPARTNER,    9).% 成功招募一个紫将 
-define(CONST_ACHIEVEMENT_RECRUIT_ORANGEPARTNER,    10).% 成功招募一个橙将 
-define(CONST_ACHIEVEMENT_RECRUIT_REDPARTNER,       11).% 成功招募一个红将 
-define(CONST_ACHIEVEMENT_LOOKFOR_PARTNER,          12).% 成功寻访一个武将 
-define(CONST_ACHIEVEMENT_LOOKFOR_GOLDPARTNER,      13).% 成功寻访到蓝色武将 
-define(CONST_ACHIEVEMENT_LOOKFOR_PURPLEPARTNER,    14).% 成功寻访到紫色武将 
-define(CONST_ACHIEVEMENT_LOOKFOR_ORANGEPARTNER,    15).% 成功寻访到橙色武将 
-define(CONST_ACHIEVEMENT_LOOKFOR_REDPARTNER,       16).% 成功寻访到红色武将 
-define(CONST_ACHIEVEMENT_LIFE_LEVELUP,             17).% 成功升级长生1次 
-define(CONST_ACHIEVEMENT_CAMP_LEVELUP,             18).% 成功升级任意阵法一次 
-define(CONST_ACHIEVEMENT_HORSE_COLT,               30).% 成功获得一个小马驹 
-define(CONST_ACHIEVEMENT_HORSE,                    31).% 成功获得一个坐骑 
-define(CONST_ACHIEVEMENT_GREEN_HORSE,              32).% 成功获得四十级绿色坐骑 
-define(CONST_ACHIEVEMENT_BLUE_HORSE,               33).% 成功获得六十级蓝色坐骑 
-define(CONST_ACHIEVEMENT_HORSE_INHERIT,            34).% 成功进行一次坐骑等级继承 
-define(CONST_ACHIEVEMENT_GOLD,                     35).% 获得铜钱 
-define(CONST_ACHIEVEMENT_SNATCH,                   36).% 收夺一次 
-define(CONST_ACHIEVEMENT_PURPLE_CHEST,             37).% 收夺获得一个紫色宝箱 
-define(CONST_ACHIEVEMENT_ORANGE_CHEST,             38).% 收夺获得一个橙色宝箱 
-define(CONST_ACHIEVEMENT_RED_CHEST,                39).% 收夺获得一个红色宝箱 
-define(CONST_ACHIEVEMENT_PATROL,                   40).% 巡城一次 
-define(CONST_ACHIEVEMENT_JOIN_GUILD,               41).% 成功加入一个军团 
-define(CONST_ACHIEVEMENT_GUILD_LEVELUP,            42).% 军团升级 
-define(CONST_ACHIEVEMENT_ARMOURY_LEVELUP,          43).% 升级百宝到五级 
-define(CONST_ACHIEVEMENT_IMPEDIMENTA_LEVELUP,      44).% 升级府兵制到五级 
-define(CONST_ACHIEVEMENT_PLAYGROUND_LEVELUP,       45).% 升级武经七书到五十级 
-define(CONST_ACHIEVEMENT_LAIRAGE_LEVELUP,          46).% 升级石工到五十级 
-define(CONST_ACHIEVEMENT_GUILD_PARTY,              47).% 领取十次军饷 
-define(CONST_ACHIEVEMENT_CONTRIBUTION,             48).% 获得五万贡献 
-define(CONST_ACHIEVEMENT_ORIFLAMME_LEVELUP,        49).% 冶铁所军旗升级 
-define(CONST_ACHIEVEMENT_FRIEND,                   50).% 成功添加好友 
-define(CONST_ACHIEVEMENT_INTIMATE,                 51).% 成功添加密友 
-define(CONST_ACHIEVEMENT_COHESION,                 52).% 单个好友亲密度 
-define(CONST_ACHIEVEMENT_SPRING,                   53).% 泡温泉 
-define(CONST_ACHIEVEMENT_AUCTION,                  54).% 成功购买一件拍卖物品 
-define(CONST_ACHIEVEMENT_MARRIAGE,                 55).% 结婚一次 
-define(CONST_ACHIEVEMENT_EPISTLE,                  56).% 发送一封雁书 
-define(CONST_ACHIEVEMENT_TROMBA,                   57).% 使用小喇叭发言一次 
-define(CONST_ACHIEVEMENT_MULTIPLAYER_ARENA,        60).% 成功参加战群雄 
-define(CONST_ACHIEVEMENT_MULTIPLAYER_ARENA_STREAKWIN,  61).% 战群雄获胜五十次 
-define(CONST_ACHIEVEMENT_MULTIPLAYER_COPY,         62).% 参加团队战场一次 
-define(CONST_ACHIEVEMENT_ORIFLAMME_CAPTURE,        63).% 参加一次斩将夺旗 
-define(CONST_ACHIEVEMENT_ORIFLAMME_CAPTURE_ARRAY,  64).% 斩将夺旗积分排名前十 
-define(CONST_ACHIEVEMENT_GUILD_SIEGE,              65).% 参加乱天下一次 
-define(CONST_ACHIEVEMENT_COUNTRY_BATTLE,           66).% 参加阵营战一次 
-define(CONST_ACHIEVEMENT_COUNTRY_BATTLE_WIN,       67).% 参加阵营战获胜十次 
-define(CONST_ACHIEVEMENT_KILL_ENEMY_OFFICER,       68).% 击杀敌方将领十次 
-define(CONST_ACHIEVEMENT_COUNTRY_BATTLE_ARRAY,     69).% 阵营战排名 
-define(CONST_ACHIEVEMENT_COPY_CLEARANCE,           70).% 成功通关战场 
-define(CONST_ACHIEVEMENT_ELITE_COPY_CLEARANCE,     71).% 完成精英战场 
-define(CONST_ACHIEVEMENT_DAILY_TASK_COMPLETION,    72).% 完成日循环任务一轮 
-define(CONST_ACHIEVEMENT_INVASION,                 73).% 成功通过异民族 
-define(CONST_ACHIEVEMENT_TOWER_CLEARANCE,          74).% 闯过破阵 
-define(CONST_ACHIEVEMENT_WELFARE_BARRIER,          75).% 遇到一百次福利关卡 
-define(CONST_ACHIEVEMENT_CLEARANCE,                76).% 扫荡 
-define(CONST_ACHIEVEMENT_KILL_BOSS1,               77).% 参与击杀酸与 
-define(CONST_ACHIEVEMENT_KILL_BOSS2,               78).% 参与击杀张角 
-define(CONST_ACHIEVEMENT_ORANGE_WEAPON,            79).% 成功获得一把五十级橙色武器 
-define(CONST_ACHIEVEMENT_KILL_BOSS1_ARRAY,         81).% 参与击杀酸与的排名 
-define(CONST_ACHIEVEMENT_KILL_BOSS2_ARRAY,         82).% 参与击杀张角的排名 
-define(CONST_ACHIEVEMENT_CARRY,                    83).% 成功派遣商队 
-define(CONST_ACHIEVEMENT_ESCORT,                   84).% 成功护送 
-define(CONST_ACHIEVEMENT_ROB,                      85).% 成功伏击 
-define(CONST_ACHIEVEMENT_HOME_LEVELUP,             86).% 封邑升级 
-define(CONST_ACHIEVEMENT_FARM_LEVELUP,             87).% 农场升级 
-define(CONST_ACHIEVEMENT_RECLAMATION,              88).% 开放额外一块土地 
-define(CONST_ACHIEVEMENT_REDFARM_LEVELUP,          89).% 升级良田一次 
-define(CONST_ACHIEVEMENT_BLACKFARM_LEVELUP,        90).% 升级沃土一次 
-define(CONST_ACHIEVEMENT_PLANTING,                 91).% 农场种植作物一次 
-define(CONST_ACHIEVEMENT_HARVEST,                  92).% 农场收获作物一次 
-define(CONST_ACHIEVEMENT_GRAIN_DISTRIBUTION,       93).% 开仓放粮一次 
-define(CONST_ACHIEVEMENT_FEUDAL_OFFICIAL,          94).% 成功建造官府 
-define(CONST_ACHIEVEMENT_SPECULATION,              95).% 强征一次 
-define(CONST_ACHIEVEMENT_VISIT_FRIEND_HOME,        96).% 拜访好友家园一次 
-define(CONST_ACHIEVEMENT_STEAL_GRAIN,              97).% 偷粮一次 
-define(CONST_ACHIEVEMENT_EXTEND_BAG,               98).% 扩展一行包裹 
-define(CONST_ACHIEVEMENT_EXTEND_DEPOT,             99).% 扩展一行仓库 
-define(CONST_ACHIEVEMENT_PRACTICE,                 100).% 修炼一次 
-define(CONST_ACHIEVEMENT_DOUBLE_PRACTICE,          101).% 双修一次 
-define(CONST_ACHIEVEMENT_CULTIVATION_UP,           130).% 委托修为升级 
-define(CONST_ACHIEVEMENT_PVP_CAMP_RANK,            131).% 阵营战排名 

-define(CONST_ACHIEVEMENT_PRAY,                     119).% 祈天一次 
-define(CONST_ACHIEVEMENT_EQUIP_STAR,               120).% 装备一个星斗 
-define(CONST_ACHIEVEMENT_TRANSFORM_STAR,           121).% 转化一个星斗 
-define(CONST_ACHIEVEMENT_STAR_FORCE,               122).% 获得星力 
-define(CONST_ACHIEVEMENT_SKY_STAR,                 123).% 获得一个地煞星斗 
-define(CONST_ACHIEVEMENT_LAND_STAR,                124).% 获得一个天罡星斗 
-define(CONST_ACHIEVEMENT_CONSTELLATION_STAR,       125).% 获得一个星宿星斗 
-define(CONST_ACHIEVEMENT_SOUL_STAR,                126).% 获得一个元辰星斗 
-define(CONST_ACHIEVEMENT_STAR_LEVELUP,             127).% 提升星斗 
-define(CONST_ACHIEVEMENT_GET_ORANGE_STAR,          128).% 成功获得1个橙色星斗 
-define(CONST_ACHIEVEMENT_GET_MAXLEVEL_STAR_FIVE,   129).% 获得5个10级星斗 

-define(CONST_ACHIEVEMENT_PURPLE_WEAPON,            19).% 成功获得一把紫色武器 
-define(CONST_ACHIEVEMENT_ORANGE_SUITE,             20).% 成功获得一套橙装 
-define(CONST_ACHIEVEMENT_PURPLE_SOUL,              21).% 成功获得一个紫印 
-define(CONST_ACHIEVEMENT_ORANGE_SOUL,              22).% 成功获得一个橙印 
-define(CONST_ACHIEVEMENT_RED_SOUL,                 23).% 成功获得一个红印 
-define(CONST_ACHIEVEMENT_TEN_SOUL,                 24).% 成功获得十个十级印 
-define(CONST_ACHIEVEMENT_ONEKEY_STRENGTHEN,        25).% 成功进行一键强化一次 
-define(CONST_ACHIEVEMENT_EQUIP_SOUL,               26).% 成功进行装备刻印一次 
-define(CONST_ACHIEVEMENT_PLUS,                     27).% 成功洗炼一次 
-define(CONST_ACHIEVEMENT_PLUS_COMPLETION,          28).% 洗炼成功获得满值属性 
-define(CONST_ACHIEVEMENT_PLUS_PERFECTION,          29).% 洗炼成功获得三条满值属性 

-define(CONST_ACHIEVEMENT_ARENA_STREAKWIN,          58).% 达成一骑讨连胜 
-define(CONST_ACHIEVEMENT_ARENA_ARRAY,              59).% 获得一骑讨排名 

-define(CONST_ACHIEVEMENT_FIRST_LV,                 132).% 第一个达到40级的玩家 
-define(CONST_ACHIEVEMENT_FIRST_GUILD_LV,           133).% 第一个将军团升级到4级的军团长 
-define(CONST_ACHIEVEMENT_FIRST_RED_PARTNER,        134).% 第一个获得红色武将的玩家 
-define(CONST_ACHIEVEMENT_FIRST_HOST,               135).% 第一个将坐骑培养到40级的玩家 
-define(CONST_ACHIEVEMENT_FIRST_TOWER_CLEARANCE,    136).% 第一个在破阵中通关七月流火阵的玩家 
-define(CONST_ACHIEVEMENT_FIRST_STONE,              137).% 第一个镶嵌满16颗4级宝石的玩家 
-define(CONST_ACHIEVEMENT_FIRST_RED_STAR,           138).% 第一个获得红色星斗的玩家 
-define(CONST_ACHIEVEMENT_FIRST_FASHION,            139).% 第一个穿戴5级时装的玩家 

-define(CONST_ACHIEVEMENT_GIRL,                     140).% 玲珑宝贝 
-define(CONST_ACHIEVEMENT_RANK_LV,                  141).% 等级排行榜第一 
-define(CONST_ACHIEVEMENT_ARENA_PVP_WIN,            142).% 战群雄20连胜 
-define(CONST_ACHIEVEMENT_RANK_TOWER,               143).% 破阵排行榜第一 
-define(CONST_ACHIEVEMENT_RANK_POWER,               144).% 战力排行榜第一 
-define(CONST_ACHIEVEMENT_360SAFE_KEEPER,           145).% 360安全卫士 
-define(CONST_ACHIEVEMENT_CROSS_ARENA,              146).% 跨服竞技场 

-define(CONST_ACHIEVEMENT_360TITLEID,               10060).% 360安全卫士称号 

-define(CONST_ACHIEVEMENT_360ACHIEVEID,             10319).% 360特权桃园卫士 

-define(CONST_ACHIEVEMENT_GMTITLEID,                10061).% GM称号 

-define(CONST_ACHIEVEMENT_IMGM,                     147).% "我是GM“称号 

-define(CONST_ACHIEVEMENT_ACHIEVEMENT,              1).% 离线成就 
-define(CONST_ACHIEVEMENT_TITLE,                    2).% 离线称号 

-define(CONST_ACHIEVEMENT_NEW_SERV_HORSE_LV,        15).% 第一个将坐骑培养等级 

%% ==========================================================
%% 物品
%% ==========================================================
-define(CONST_GOODS_TYPE_EQUIP,                     1).% 物品大类--装备 
-define(CONST_GOODS_TYPE_EGG,                       2).% 物品大类--蛋 
-define(CONST_GOODS_TYPE_SKILL_BOOK,                3).% 物品大类--技能书 
-define(CONST_GOODS_TYPE_SUPPLY,                    4).% 物品大类--补给，非延时类 
-define(CONST_GOODS_TYPE_BOX,                       5).% 物品大类--宝箱 
-define(CONST_GOODS_TYPE_PACKAGE,                   6).% 物品大类--礼包 
-define(CONST_GOODS_TYPE_TASK,                      7).% 物品大类--任务 
-define(CONST_GOODS_TYPE_BUFF,                      8).% 物品大类--临时属性符buff 
-define(CONST_GOODS_TYPE_FUNC,                      9).% 物品大类--功能消耗材料 
-define(CONST_GOODS_TYPE_COLLECT,                   10).% 物品大类--珍藏品 
-define(CONST_GOODS_TYPE_WEAPON,                    11).% 物品大类--神兵 
-define(CONST_GOODS_EQUIP_STONE,                    12).% 装备大类--宝石 
-define(CONST_GOODS_360CARD,                        13).% 物品打类-360称号卡 

-define(CONST_GOODS_EQUIP_WEAPON,                   1).% 装备-武器 
-define(CONST_GOODS_EQUIP_ARMOR,                    2).% 装备-护甲 
-define(CONST_GOODS_EQUIP_HELMET,                   3).% 装备-头盔 
-define(CONST_GOODS_EQUIP_BOOTS,                    4).% 装备-靴子 
-define(CONST_GOODS_EQUIP_CLOAK,                    5).% 装备-披风 
-define(CONST_GOODS_EQUIP_BELT,                     6).% 装备-腰带 
-define(CONST_GOODS_EQUIP_NECKLACE,                 7).% 装备-项链 
-define(CONST_GOODS_EQUIP_RING,                     8).% 装备-戒指 
-define(CONST_GOODS_EQUIP_FUSION,                   9).% 装备-时装 
-define(CONST_GOODS_EQUIP_BADGE,                    10).% 装备-帮派徽章 
-define(CONST_GOODS_EQUIP_HORSE,                    11).% 装备-坐骑 
-define(CONST_GOODS_EQUIP_FUSION_WEAPON,            12).% 装备-时装武器 
-define(CONST_GOODS_EQUIP_FUSION_STEP,              13).% 装备-时装足迹 
-define(CONST_GOODS_ATTR_VIP,                       14).% 属性-vip等级 

-define(CONST_GOODS_CTN_BAG,                        1).% 容器类型--背包 
-define(CONST_GOODS_CTN_DEPOT,                      2).% 容器类型--仓库 
-define(CONST_GOODS_CTN_BAG_TEMP,                   3).% 容器类型--临时背包 
-define(CONST_GOODS_CTN_EQUIP_PLAYER,               4).% 容器类型--角色装备栏 
-define(CONST_GOODS_CTN_EQUIP_PARTNER,              5).% 容器类型--伙伴装备栏 
-define(CONST_GOODS_CTN_LOTTERY_DEPOT,              6).% 容器类型--宝箱仓库 
-define(CONST_GOODS_CTN_HOME_DEPOT,                 7).% 容器类型--家园仓库 
-define(CONST_GOODS_CTN_GUILD,                      8).% 容器类型--军团仓库 
-define(CONST_GOODS_CTN_WEAPON,                     9).% 容器类型--神兵装备栏 
-define(CONST_GOODS_CTN_REMOTE_DEPOT,               11).% 远程仓库 
-define(CONST_GOODS_CTN_REMOTE_SHOP,                12).% 远程道具店 

-define(CONST_GOODS_DELTA_GOLD,                     2).% 每次扩展元宝增加值 
-define(CONST_GOODS_GOLD_PER_EXT_BAG,               5).% 每次扩展背包花的元宝数 
-define(CONST_GOODS_GOLD_PER_EXT_DEPOT,             5).% 每次扩展仓库花的元宝数 

-define(CONST_GOODS_FUNC_SPEAKER,                   1).% 喇叭 
-define(CONST_GOODS_FUNC_GUILD,                     2).% 帮派道具 
-define(CONST_GOODS_FUNC_MARRY_FIREWORKS,           3).% 结婚烟花 
-define(CONST_GOODS_FUNC_MARRY_KNOT,                4).% 结婚同心结 
-define(CONST_GOODS_FUNC_MARRY_CANDY,               5).% 结婚喜糖 
-define(CONST_GOODS_FUNC_GENIUS_CANDY,              6).% 天赋丹 
-define(CONST_GOODS_FUNC_GENIUS_PROTECT,            7).% 天赋丹保护符 
-define(CONST_GOODS_FUNC_PARTNER_GROW,              8).% 武将培养消耗品 
-define(CONST_GOODS_FUNC_PET_GROW_CANDY,            9).% 宠物成长丹 
-define(CONST_GOODS_FUNC_PET_GROW_PROTECT,          10).% 宠物成长保护符 
-define(CONST_GOODS_FUNC_PET_GENIUS_CANDY,          11).% 宠物资质丹 
-define(CONST_GOODS_FUNC_PET_GENIUS_PROTECT,        12).% 宠物资质保护符 
-define(CONST_GOODS_FUNC_PET_CHAR_CHANGE,           13).% 宠物性格转换道具 
-define(CONST_GOODS_FUNC_PET_REBORN,                14).% 宠物返生丹 
-define(CONST_GOODS_FUNC_EQUIP_COMP,                15).% 装备合成材料 
-define(CONST_GOODS_FUNC_EQUIP_CLEAR,               17).% 装备洗练保护符 
-define(CONST_GOODS_FUNC_EQUIP_BLUEPRINT,           18).% 装备锻造图纸 
-define(CONST_GOODS_FUNC_PARTNER_FAVOURITE,         19).% 武将喜好品 
-define(CONST_GOODS_FUNC_LOTTERY_KEY,               20).% 招财宝箱钥匙 
-define(CONST_GOODS_HORSE_FOOD,                     21).% 精良草料 
-define(CONST_GOODS_FUNC_GOODS_FORMULA,             22).% 道具合成配方 
-define(CONST_GOODS_PARTNER_FIND,                   23).% 拜访礼 
-define(CONST_GOODS_FUNC_HUANHUAKA,                 24).% 坐骑幻化卡 
-define(CONST_GOODS_FUNC_ZHUANZHIDAN,               25).% 转职丹 
-define(CONST_GOODS_FUNC_MIND,                      26).% 星斗包 
-define(CONST_GOODS_FUNC_PARTNER,                   27).% 武将卡 
-define(CONST_GOODS_FUNC_DQJ,                       28).% 定情酒 
-define(CONST_GOODS_FUNC_DMT,                       29).% 灯谜贴 
-define(CONST_GOODS_FUNC_GMK,                       30).% 改名卡 
-define(CONST_GOODS_FUNC_SDK,                       31).% 神刀卡 
-define(CONST_GOODS_FUNC_OTHER,                     99).% 其他 

-define(CONST_GOODS_BOOK_PET,                       1).% 宠物技能书 
-define(CONST_GOODS_BOOK_PLAYER_ACTIVE,             2).% 角色主动技能书 
-define(CONST_GOODS_BOOK_PLAYER_PASSIVE,            3).% 角色被动技能书 
-define(CONST_GOODS_BOOK_DJTS,                      4).% 遁甲天书技能书 
-define(CONST_GOODS_BOOK_HORSE,                     5).% 坐骑技能书 
-define(CONST_GOODS_BOOK_CAMP,                      6).% 阵法书 

-define(CONST_GOODS_SUPPLY_BLOOD_BAG,               1).% 血包 
-define(CONST_GOODS_SUPPLY_PET_EXP,                 2).% 宠物经验书 
-define(CONST_GOODS_SUPPLY_PLAYER_EXP,              3).% 玩家经验书 
-define(CONST_GOODS_SUPPLY_SP_BAG,                  4).% 体力丹 
-define(CONST_GOODS_SUPPLY_GOLD,                    5).% 铜钱卡 
-define(CONST_GOODS_SUPPLY_BCASH,                   6).% 绑定元宝卡 
-define(CONST_GOODS_SUPPLY_MERITORIOUS,             7).% 功勋卡 
-define(CONST_GOODS_SUPPLY_EXPERIENCE,              8).% 历练卡 
-define(CONST_GOODS_SUPPLY_HORSE_EXP,               9).% 坐骑经验卡 
-define(CONST_GOODS_SUPPLY_CASH,                    10).% 充值卡 
-define(CONST_GOODS_SUPPLY_CHESS_DICE,              11).% 骰宝福袋 
-define(CONST_GOODS_SUPPLY_HUFU,                    12).% 虎符 
-define(CONST_GOODS_CASH_BIND,                      13).% 绑定元宝 

-define(CONST_GOODS_BOX_BOX,                        1).% 宝箱 
-define(CONST_GOODS_BOX_PET_COLLECT,                2).% 宠物采集包 
-define(CONST_GOODS_BOX_MARRY,                      3).% 结婚红包 
-define(CONST_GOODS_BOX_DROP_BY_LV,                 4).% 按等级掉落宝箱 

-define(CONST_GOODS_PACKAGE_GROW,                   1).% 成长礼包 
-define(CONST_GOODS_PACKAGE_NEW_FISH,               2).% 新手礼包 
-define(CONST_GOODS_PACKAGE_CHARGE,                 3).% 充值礼包 
-define(CONST_GOODS_PACKAGE_MEDIA,                  4).% 媒体礼包 

-define(CONST_GOODS_TASK_TASK,                      1).% 任务道具 

-define(CONST_GOODS_BUFF_BUFF,                      1).% 临时属性符 

-define(CONST_GOODS_PET_EGG,                        1).% 宠物蛋 
-define(CONST_GOODS_PET_HORSE,                      2).% 小马驹 

-define(CONST_GOODS_UNBIND,                         0).% 物品绑定--未绑定 
-define(CONST_GOODS_BIND,                           1).% 物品绑定--已绑定 

-define(CONST_GOODS_REMOTE_DEPOT_COST_TYPE,         4).% 远程仓库扣钱类型 
-define(CONST_GOODS_REMOTE_SHOP_COST_TYPE,          4).% 远程道具店扣钱类型 
-define(CONST_GOODS_REMOTE_DEPOT_COST_VALUE,        100).% 远程仓库扣钱数 
-define(CONST_GOODS_REMOTE_SHOP_COST_VALUE,         100).% 远程道具店扣钱数 

-define(CONST_GOODS_COLLECT_PICTURE,                1).% 珍藏品--原画 
-define(CONST_GOODS_COLLECT_LONG_WEAPON,            2).% 珍藏品--长兵 
-define(CONST_GOODS_COLLECT_SHORT_WEAPON,           3).% 珍藏品--短兵 
-define(CONST_GOODS_COLLECT_DOUBLE_WEAPON,          4).% 珍藏品--双兵 

-define(CONST_GOODS_REMOTE_VIP,                     1).% 免费vip下限 

-define(CONST_GOODS_TIME_TEMP_BAG,                  86400).% 临时背包物品生存时间 

-define(CONST_GOODS_FASHION_ANGER_TYPE_1,           1).% 时装加怒气类型--角色 
-define(CONST_GOODS_FASHION_ANGER_TYPE_2,           2).% 时装加怒气类型--武将 
-define(CONST_GOODS_FASHION_ANGER_TYPE_3,           3).% 时装加怒气类型--角色和武将 

-define(CONST_GOODS_INIT_STREN_LV,                  0).% 初始强化值 

-define(CONST_GOODS_ID_GIFT_COLLECT,                1040507036).% 物品ID--收藏礼包 
-define(CONST_GOODS_ID_GIFT_NEWBIE,                 1040607023).% 物品ID--新手礼包 
-define(CONST_GOODS_ID_GIFT_PHONE,                  1040607037).% 物品ID--手机绑定礼包 
-define(CONST_GOODS_CHANGE_PRO,                     1090710006).% 物品id--转职丹 
-define(CONST_GOODS_ID_HORSE_FOOD,                  1092105098).% 物品ID--草料 
-define(CONST_GOODS_GOODS_ID_RES_LUCK,              1093000009).% 物品ID--抽奖券 
-define(CONST_GOODS_GOODS_ID_RES_LUCK2,             1093000010).% 物品ID--礼券抽奖卡 
-define(CONST_GOODS_GOODS_ID_RES_EXPLUCK,           1093000011).% 物品ID--经验抽奖券 
-define(CONST_GOODS_DINGQINGJIU,                    1093000044).% 物品ID--定情酒 
-define(CONST_GOODS_ID_CHANGE_NAME,                 2010202457).% 物品ID--改名单 

-define(CONST_GOODS_DROP_TYPE_NORMAL,               1).% 物品掉落类型--普通 
-define(CONST_GOODS_DROP_TYPE_MULTI,                2).% 物品掉落类型--多层 

-define(CONST_GOODS_EQUIP_STONE_WDK,                55).% 装备大类-未打孔 
-define(CONST_GOODS_EQUIP_STONE_YDK,                56).% 装备大类-未镶嵌 

-define(CONST_GOODS_CARD_EXCHANGE_PARTNER,          1093000016).% 抽卡换武将扣道具 

%% ==========================================================
%% 聊天
%% ==========================================================
-define(CONST_CHAT_DATA_MONITOR_WEB,                "http://chat.4399data.com:8080/chatlog").% 聊天监控网址 
-define(CONST_CHAT_WORLD,                           1).% 聊天频道--世界 
-define(CONST_CHAT_SYS,                             2).% 聊天频道--系统 
-define(CONST_CHAT_SPEAKER,                         3).% 聊天频道--喇叭 
-define(CONST_CHAT_MAP,                             4).% 聊天频道--地图 
-define(CONST_CHAT_COUNTRY,                         5).% 聊天频道--国家 
-define(CONST_CHAT_GUILD,                           6).% 聊天频道--军团 
-define(CONST_CHAT_TEAM,                            7).% 聊天频道--组队 
-define(CONST_CHAT_CAMP,                            8).% 聊天频道--阵营 
-define(CONST_CHAT_PRIVATE,                         9).% 聊天频道--私人 
-define(CONST_CHAT_MAIL,                            10).% 聊天频道--邮件 
-define(CONST_CHAT_FOREVER,                         315360000).% 永久封号/禁言时间 
-define(CONST_CHAT_SPEAKER_ID,                      1090100089).% 小喇叭ID 

-define(CONST_CHAT_INTERVAL_WORLD,                  10).% 聊天频率--世界 

-define(CONST_CHAT_SHUTUP_NO,                       0).% 正常发言 
-define(CONST_CHAT_SHUTUP_YES,                      1).% 禁言 

%% ==========================================================
%% 好友
%% ==========================================================
-define(CONST_RELATIONSHIP_MAX_BLACK_LIST,          10).% 黑名单人数上限 
-define(CONST_RELATIONSHIP_RECOMM_N,                10).% 推荐人数 
-define(CONST_RELATIONSHIP_MAX_CONTACT,             10).% 最近联系人上限 
-define(CONST_RELATIONSHIP_MAX_FRIENDS,             100).% 好友数上限 

-define(CONST_RELATIONSHIP_MIN_LV_GET_EXP,          1).% 领取经验瓶最低等级 
-define(CONST_RELATIONSHIP_BLESS_TIMES,             99).% 可祝福次数 
-define(CONST_RELATIONSHIP_MAX_LV_GET_EXP,          1000).% 祝福最高等级 
-define(CONST_RELATIONSHIP_MAX_BOTTLE_EXP,          100000).% 经验瓶最大经验值 

-define(CONST_RELATIONSHIP_DELTA_LV,                10).% 推荐等级差上下n级 

-define(CONST_RELATIONSHIP_BLESS_TYPE_SINGLE_COPY,  1).% 单人副本 
-define(CONST_RELATIONSHIP_BLESS_TYPE_MCOPY,        2).% 多人副本 
-define(CONST_RELATIONSHIP_BLESS_TYPE_INVASION,     3).% 异民族 

-define(CONST_RELATIONSHIP_BTYPE_SCOPY,             1).% 单人副本 
-define(CONST_RELATIONSHIP_BTYPE_MCOPY,             2).% 多人副本 
-define(CONST_RELATIONSHIP_BTYPE_INVASION,          3).% 异民族 
-define(CONST_RELATIONSHIP_BTYPE_LV,                4).% 等级 
-define(CONST_RELATIONSHIP_BTYPE_PARTNER,           5).% 武将 
-define(CONST_RELATIONSHIP_BTYPE_VIPLV,             6).% vip等级 
-define(CONST_RELATIONSHIP_BTYPE_GUILD,             7).% 帮派 
-define(CONST_RELATIONSHIP_BTYPE_ARENA,             8).% 竞技场 
-define(CONST_RELATIONSHIP_BTYPE_MIND,              9).% 心法 
-define(CONST_RELATIONSHIP_BTYPE_EQUIP,             10).% 武器 

-define(CONST_RELATIONSHIP_BRELA_FRIEND,            1).% 数量类型_好友 
-define(CONST_RELATIONSHIP_BRELA_BEST_FRIEND,       2).% 数量类型_密友 
-define(CONST_RELATIONSHIP_BRELA_BLACK_LIST,        3).% 数量类型_黑名单 
-define(CONST_RELATIONSHIP_BRELA_CONTACTED,         4).% 数量类型_最近联系人 

-define(CONST_RELATIONSHIP_BLESS,                   1).% 祝福-可祝福 
-define(CONST_RELATIONSHIP_BE_BLESS,                2).% 祝福-被祝福 

-define(CONST_RELATIONSHIP_PID,                     30).% 进程数 

%% ==========================================================
%% 修炼
%% ==========================================================
-define(CONST_PRACTICE_NORMAL,                      0).% 非修炼状态 
-define(CONST_PRACTICE_SINGLE,                      1).% 单修 
-define(CONST_PRACTICE_DOUBLE,                      2).% 双修 
-define(CONST_PRACTICE_LEAVE,                       3).% 离线修炼 

-define(CONST_PRACTICE_IS_AUTOMATIC,                0).% 是否自动双修 
-define(CONST_PRACTICE_DURATION,                    4).% 修炼时间 
-define(CONST_PRACTICE_LIMIT_LV,                    19).% 限制等级 
-define(CONST_PRACTICE_SYS,                         19).% 开始系统 
-define(CONST_PRACTICE_ONLINE_TIME,                 120).% 在线修炼领取时长（秒） 
-define(CONST_PRACTICE_LEAVE_TIME,                  86400).% 离线领取经验时长（秒） 

-define(CONST_PRACTICE_CLEAR_MONEY,                 1).% 清除时间花费-每120秒 

-define(CONST_PRACTICE_TODAY,                       1).% 替身修炼时间类型--今天 
-define(CONST_PRACTICE_TOMORROW,                    2).% 替身修炼时间类型--明天 
-define(CONST_PRACTICE_TODAY_TOMORROW,              3).% 替身修炼时间类型--今天以及明天 

-define(CONST_PRACTICE_AUTO_CASH,                   0.25).% 替身修炼每分钟花费 

%% ==========================================================
%% 邮件
%% ==========================================================
-define(CONST_MAIL_POSTAGE,                         10).% 邮资 
-define(CONST_MAIL_MAX_NUM,                         50).% 邮件最大上限数 

-define(CONST_MAIL_SEND_FAIL,                       0).% 邮件发送失败 
-define(CONST_MAIL_SEND_SUCCESS,                    1).% 邮件发送成功 
-define(CONST_MAIL_SEND_MAIL_FULL,                  2).% 对方邮件已满 
-define(CONST_MAIL_SEND_MONEY_NOT_ENOUGH,           3).% 铜钱不足 
-define(CONST_MAIL_SEND_NOT_PERSON,                 4).% 无此联系人 
-define(CONST_MAIL_NOT_OPEN,                        5).% 等级不足,无法发送邮件 
-define(CONST_MAIL_SEND_MAX,                        6).% 今日发送已达上限 

-define(CONST_MAIL_SAVE_FAIL,                       0).% 保存失败 
-define(CONST_MAIL_SAVE_SUCCESS,                    1).% 保存成功 
-define(CONST_MAIL_SAVE_CONTAIN_ATTACHMENT,         2).% 邮件中包含附件 
-define(CONST_MAIL_SAVE_AGAIN,                      3).% 已保存 

-define(CONST_MAIL_GET_FAIL,                        0).% 获取附件失败 
-define(CONST_MAIL_GET_SUCCESS,                     1).% 获取附件成功 
-define(CONST_MAIL_GET_BAG_FULL,                    2).% 背包已满 
-define(CONST_MAIL_ATTACHMENT_IS_NOT_EXSIT,         3).% 附件不存在 

-define(CONST_MAIL_SYSTEM,                          1).% 系统邮件 
-define(CONST_MAIL_PRIVATE,                         2).% 好友邮件 
-define(CONST_MAIL_STRANGE,                         3).% 陌生人邮件 
-define(CONST_MAIL_GUILD,                           4).% 军团邮件 
-define(CONST_MAIL_INTEREST,                        5).% 返利邮件 

-define(CONST_MAIL_UNDO,                            0).% 未读/未保存/无附件 
-define(CONST_MAIL_DO,                              1).% 已读/已保存/有附件 

-define(CONST_MAIL_MAX_ATTACHMENT,                  5).% 最大附件物品数量 

-define(CONST_MAIL_OPEN_LV,                         10).% 邮件开放等级 

-define(CONST_MAIL_SEND_MAX_NUM,                    200).% 一天发送上限 

-define(CONST_MAIL_SINGLE_AREA,                     1).% 邮件内容：一骑讨 
-define(CONST_MAIL_SYS_KEEP,                        7).% 系统保存邮件天数 
-define(CONST_MAIL_MARKET_SALE,                     50).% 邮件内容：市集寄售 
-define(CONST_MAIL_MARKET_BUY,                      200).% 邮件内容：市集购买 
-define(CONST_MAIL_ACHEIEVEMENT,                    400).% 邮件内容：新服成就 
-define(CONST_MAIL_GUILD_SEND,                      450).% 邮件内容：军团发放 
-define(CONST_MAIL_INTEREST_SEND,                   500).% 邮件内容：充值返利 
-define(CONST_MAIL_TOWER_SEND,                      550).% 邮件内容：破阵 
-define(CONST_MAIL_MCOPY_SEND,                      600).% 邮件内容：多人副本 
-define(CONST_MAIL_SIGN_SEND,                       650).% 邮件内容：签到礼包 
-define(CONST_MAIL_DEPOSIT,                         700).% 邮件内容:充值礼包过期返回 
-define(CONST_MAIL_FULL_PACKET,                     750).% 邮件内容：背包已满 
-define(CONST_MAIL_POWER_REPLACE,                   800).% 邮件内容：战力英雄榜替代者 
-define(CONST_MAIL_POWER_REPLACED,                  850).% 邮件内容：战力英雄榜被替代者 
-define(CONST_MAIL_GUILD_REPLACE,                   900).% 邮件内容：军团英雄榜 
-define(CONST_MAIL_GUILD_REPLACED,                  950).% 邮件内容：军团英雄榜 
-define(CONST_MAIL_DEVILCOPY_REPLACE,               1000).% 邮件内容：破阵英雄榜 
-define(CONST_MAIL_DEVILCOPY_REPLACED,              1050).% 邮件内容：破阵英雄榜 
-define(CONST_MAIL_GIRL_TITLE,                      1700).% 邮件内容：玲珑宝贝 
-define(CONST_MAIL_DAILY_DEPOSIT_IN,                1750).% 邮件内容：每日充值 
-define(CONST_MAIL_SPRING_DOLL_SEND,                1800).% 邮件内容：骊山汤替身奖励 
-define(CONST_MAIL_BOSS_ROBOT_REWARD,               1850).% 邮件内容：妖魔破奖励 
-define(CONST_MAIL_BOSS_ROBOT_REWARD_2,             1900).% 邮件内容：妖魔破奖励_有元宝 
-define(CONST_MAIL_BOSS_ROBOT_REWARD_STO,           1901).% 邮件内容：妖魔破奖励_关服 
-define(CONST_MAIL_PRACTICE_DOLL_SEND,              1950).% 邮件内容：离线替身修行奖励 
-define(CONST_MAIL_PRACTICE_DOLL_TIME_TOO_SHORT,    1951).% 邮件内容：离线修行时间过短 
-define(CONST_MAIL_PRACTICE_DOLL_MID_REFRESH,       1952).% 邮件内容：离线修行零点刷新 
-define(CONST_MAIL_PRACTICE_DOLL_CASH_NOT_ENOUGH,   1953).% 邮件内容：离线修行元宝不足 
-define(CONST_MAIL_SNOW_BAG_FULL,                   2000).% 邮件内容：雪夜赏灯 
-define(CONST_MAIL_PARTY_DOLL,                      2050).% 邮件内容：军团宴会奖励 
-define(CONST_MAIL_PARTY_DOLL_TIPS,                 2051).% 邮件内容：军团宴会提醒 
-define(CONST_MAIL_CROSS_ARENA_GROUP,               2200).% 邮件内容：跨服竞技小组通知 
-define(CONST_MAIL_CROSS_ARENA_REWARD,              2300).% 邮件内容：跨服竞技奖励 
-define(CONST_MAIL_BUY_GUILD_ITEMS,                 2400).% 邮件内容: 购买军团物质邮件 
-define(CONST_MAIL_GUILD_GIVE_GOODS,                2500).% 邮件内容：物资赠送 
-define(CONST_MAIL_ATTR_GUILD_APP_SUCCESS,          2600).% 邮件内容：攻城军团报名成功 
-define(CONST_MAIL_APP_FAILED,                      2700).% 邮件内容：夺城战报名失败 
-define(CONST_MAIL_ARCHERY_RANK,                    2800).% 邮件内容：辕门射戟排名奖励 
-define(CONST_MAIL_FUND,                            2900).% 邮件内容：元宝基金 
-define(CONST_MAIL_GUN_AWARD,                       3029).% 邮件内容 滚服礼券 
-define(CONST_MAIL_RIDDLE_AWARD,                    3030).% 邮件内容：元宵灯谜 
-define(CONST_MAIL_DEF_GUILD_APP_SUCCESS,           3100).% 邮件内容：守城军团报名成功 
-define(CONST_MAIL_MIXED_RECHARGE,                  3111).% 邮件内容:合服充值榜 
-define(CONST_MAIL_MIXED_CONSUME,                   3112).% 邮件内容:合服消费榜 
-define(CONST_MAIL_MIXED_POWER,                     3113).% 邮件内容:合服战力榜 
-define(CONST_MAIL_MIXED_DEVIL,                     3114).% 邮件内容:合服破阵榜 
-define(CONST_MAIL_MIXED_SINGLE_PK,                 3115).% 邮件内容:合服竞技榜 
-define(CONST_MAIL_MIXED_GUILD_POWER,               3116).% 邮件内容:合服军团榜 
-define(CONST_MAIL_FRIEND_CHANGE_NAME,              3150).% 邮件内容：好友改名 
-define(CONST_MAIL_CHANGE_NAME_SUCCESS,             3151).% 邮件内容：改名成功 

%% ==========================================================
%% 任务
%% ==========================================================
-define(CONST_TASK_TYPE_MAIN,                       1).% 任务类型--主线任务 
-define(CONST_TASK_TYPE_BRANCH,                     2).% 任务类型--支线任务 
-define(CONST_TASK_TYPE_EVERYDAY,                   3).% 任务类型--日常任务 
-define(CONST_TASK_TYPE_GUILD,                      4).% 任务类型--军团环 
-define(CONST_TASK_TYPE_POSITION,                   5).% 任务类型--官衔任务 
-define(CONST_TASK_TYPE_EVERYDAY1,                  6).% 任务类型--每日任务 

-define(CONST_TASK_TARGET_TALK,                     1).% 任务目标--对话类 
-define(CONST_TASK_TARGET_QUESTION,                 2).% 任务目标--问答题 
-define(CONST_TASK_TARGET_KILL,                     3).% 任务目标--击杀怪物 
-define(CONST_TASK_TARGET_GATHER,                   4).% 任务目标--采集 
-define(CONST_TASK_TARGET_COLLECT,                  5).% 任务目标--收集类 
-define(CONST_TASK_TARGET_CTN_GOODS,                6).% 任务目标--检查容器内物品 
-define(CONST_TASK_TARGET_LV,                       7).% 任务目标--升级 
-define(CONST_TASK_TARGET_SKILL,                    8).% 任务目标--技能 
-define(CONST_TASK_TARGET_COPY,                     9).% 任务目标--副本 
-define(CONST_TASK_TARGET_KILL_NPC,                 10).% 任务目标--杀npc 
-define(CONST_TASK_TARGET_ACTIVE,                   11).% 任务目标--活动 
-define(CONST_TASK_TARGET_GUILD,                    12).% 任务目标--加入军团 
-define(CONST_TASK_TARGET_DONATE,                   13).% 任务目标--增加帮贡 
-define(CONST_TASK_TARGET_GUILD_SKILL,              14).% 任务目标--拥有军团技能 
-define(CONST_TASK_TARGET_GUIDE,                    15).% 任务目标--完成引导 
-define(CONST_TASK_TARGET_POWER,                    16).% 任务目标--战力达到 
-define(CONST_TASK_TARGET_SINGLE_ARENA,             17).% 任务目标--一骑讨 
-define(CONST_TASK_TARGET_FURNACE,                  18).% 任务目标--打造紫装 
-define(CONST_TASK_TARGET_POSITION,                 19).% 任务目标--官衔升级 
-define(CONST_TASK_TARGET_STREN,                    20).% 任务目标--装备强化 
-define(CONST_TASK_TARGET_TRAIN,                    21).% 任务目标--培养 
-define(CONST_TASK_TARGET_CAMP,                     22).% 任务目标--阵法 
-define(CONST_TASK_TARGET_SUCC_N_COUNT,             23).% 任务目标--胜利n次 

-define(CONST_TASK_ACCEPT_GUIDE,                    0).% 任务接受方式--引导接受，前置任务引导出再与NPC对话接取 
-define(CONST_TASK_ACCEPT_PASSIVE,                  1).% 任务接受方式--被动接受，与NPC对话接取 
-define(CONST_TASK_ACCEPT_ACTIVE,                   2).% 任务接受方式--主动接受，直接接取 

-define(CONST_TASK_SUBMIT_PASSIVE,                  0).% 任务提交方式--被动提交，与NPC对话提交 
-define(CONST_TASK_SUBMIT_ACTIVE,                   1).% 任务提交方式--主动提交，完成直接提交 

-define(CONST_TASK_REMOVE_REASON_DOWN,              1).% 任务移除原因--完成任务 
-define(CONST_TASK_REMOVE_REASON_ABANDON,           2).% 任务移除原因--放弃任务 

-define(CONST_TASK_STATE_HIDE,                      1).% 任务状态--隐藏 
-define(CONST_TASK_STATE_ACCEPTABLE,                2).% 任务状态-可接受 
-define(CONST_TASK_STATE_UNFINISHED,                3).% 任务状态-接受未完成 
-define(CONST_TASK_STATE_FINISHED,                  4).% 任务状态-完成未提交 
-define(CONST_TASK_STATE_SUBMIT,                    5).% 任务状态-已提交 
-define(CONST_TASK_STATE_NOT_ACCEPTABLE,            6).% 任务状态--主线暂不可接 

-define(CONST_TASK_CASH_AUTO_FINISH,                3).% 自动完成任务消耗元宝数 

-define(CONST_TASK_POS_CONFIRM,                     0).% 检查任务 
-define(CONST_TASK_POS_ACCEPT,                      1).% 接任务 
-define(CONST_TASK_POS_FINISH,                      2).% 完成任务 
-define(CONST_TASK_POS_ABANDON,                     3).% 取消任务 
-define(CONST_TASK_POS_SUMMIT,                      4).% 提交任务 

-define(CONST_TASK_DEFAULT_TASK,                    0).% 默认任务 

-define(CONST_TASK_SP_TASK_LIST,                    [10909,10910]).% 加入军团后增加任务id 

-define(CONST_TASK_COUNT_GUILD,                     5).% 每天军团任务数 
-define(CONST_TASK_COUNT_DAILY,                     10).% 每天日常任务数 

-define(CONST_TASK_NOTE_MCOPY,                      1).% 任务备注--团队战场副本 
-define(CONST_TASK_NOTE_INVASION,                   2).% 任务备注--异民族 
-define(CONST_TASK_NOTE_TOWER,                      3).% 任务备注--破阵 
-define(CONST_TASK_NOTE_ELITE_COPY,                 4).% 任务备注--精英副本 


%% ==========================================================
%% 商城
%% ==========================================================
-define(CONST_MALL_HOT,                             1).% 热卖商城 
-define(CONST_MALL_FASHION,                         2).% 个性时装 
-define(CONST_MALL_ITEM,                            3).% 常用道具 
-define(CONST_MALL_PET_ITEM,                        4).% 宠物道具 
-define(CONST_MALL_JEWEL,                           5).% 宝石护符 
-define(CONST_MALL_SCORE,                           6).% 积分商城 
-define(CONST_MALL_BIND,                            7).% 礼券商城 
-define(CONST_MALL_VIP,                             8).% vip商城 
-define(CONST_MALL_RIDE,                            10).% 时尚坐骑 
-define(CONST_MALL_SELL_IN_TIME,                    16).% 限时购买 
-define(CONST_MALL_DISCOUNT,                        20).% 限时折扣 

-define(CONST_MALL_DISCOUNT_COUNT,                  3).% 限时折扣-物品数量 
-define(CONST_MALL_BUY_POINT,                       7).% 积分类型 
-define(CONST_MALL_DISCOUNT_TIME,                   28800).% 限时折扣-刷新时间间隔 

%% ==========================================================
%% 拍卖
%% ==========================================================
-define(CONST_MARKET_TIME_OUT_OF_DATE,              1).% 已过期 
-define(CONST_MARKET_TIME_SHORT,                    2).% 时间短 
-define(CONST_MARKET_TIME_MIDDLE,                   3).% 时间中等 
-define(CONST_MARKET_TIME_LONG,                     4).% 时间长 
-define(CONST_MARKET_TIME_VERY_LONG,                5).% 时间非常长 

-define(CONST_MARKET_FIXED_PRICE_BUY,               1).% 一口价购买 
-define(CONST_MARKET_COMMON_BUY,                    2).% 普通购买 

-define(CONST_MARKET_ALL_FETCH_ONE_TIME,            1).% 一键领取 

-define(CONST_MARKET_SELL_MAX,                      10).% 寄售最大数量 
-define(CONST_MARKET_INFO_MAX,                      20).% 一页显示信息最大数 
-define(CONST_MARKET_DEFAULT_KEEP_TIME,             24).% 默认保管时间24小时 
-define(CONST_MARKET_KEEP_COST,                     2000).% 固定保管费用 
-define(CONST_MARKET_SET_PRICE_MAX,                 200000000).% 一口价最高限额 

-define(CONST_MARKET_SEARCH_ALL_SALE_INFO,          1).% 查询所有拍卖信息(含热门搜索) 
-define(CONST_MARKET_SEARCH_BUY_INFO,               2).% 查询购买信息 

-define(CONST_MARKET_SALE_MONEY_NOT_ENOUGH,         2).% 寄售铜钱不足 
-define(CONST_MARKET_PRICE_ERROR,                   3).% 价格错误 
-define(CONST_MARKET_SALE_NOT_ALLOW,                4).% 寄售达到上限 

-define(CONST_MARKET_GOODS_NOT_OVERDURE,            2).% 未到期不能取回 
-define(CONST_MARKET_GOODS_NOT_MY,                  3).% 物品不是我的 
-define(CONST_MARKET_NOT_OVERDURE_GOODS,            5).% 无剩余过期物品 

-define(CONST_MARKET_CASH_NOT_ENOUGH,               2).% 购买元宝不足 
-define(CONST_MARKET_BUY_GOODS_OVERDURE,            3).% 物品已过期 
-define(CONST_MARKET_NOT_BUY_SELF_GOOS,             4).% 不能购买自己拍卖物品 

-define(CONST_MARKET_ONE_FIXED_PRICE,               11).% 浏览界面一口价竞拍 
-define(CONST_MARKET_ONE_COM_PRICE,                 12).% 浏览界面普通竞拍 
-define(CONST_MARKET_TWO_FIXED_PRICE,               21).% 竞拍界面一口价竞拍 
-define(CONST_MARKET_TWO_COM_PRICE,                 22).% 竞拍界面普通竞拍 

%% ==========================================================
%% 常规组队
%% ==========================================================
-define(CONST_GROUP_STATE_NO_GROUP,                 0).% 无团队 
-define(CONST_GROUP_STATE_WAITING,                  1).% 待组状态 
-define(CONST_GROUP_STATE_IN_GROUP,                 2).% 团队中 

-define(CONST_GROUP_MAX_MEMBER_COUNT,               3).% 人数上限 
-define(CONST_GROUP_MAX_APPLY_PLAYER,               3).% 玩家申请上限 
-define(CONST_GROUP_MAX_APPLY_GROUP,                5).% 团队被申请上限 
-define(CONST_GROUP_LIST_WAITING_COUNT,             5).% 待组玩家列表返回数 
-define(CONST_GROUP_MAX_DIFF_LV,                    5).% 减半等级差 
-define(CONST_GROUP_MAX_RECOMMEND_COUNT,            10).% 推荐列表上限 
-define(CONST_GROUP_MAX_DIFF_LV_2,                  10).% 无加成等级差 
-define(CONST_GROUP_MAX_PERCENT_LIMIT,              20).% 比例上限 
-define(CONST_GROUP_MIN_OPEN_LV,                    30).% 最低开放等级 

-define(CONST_GROUP_RESTRICT_NONE,                  1).% 无限制 
-define(CONST_GROUP_RESTRICT_COUNTRY,               2).% 国家 
-define(CONST_GROUP_RESTRICT_GUILD,                 3).% 军团 

-define(CONST_GROUP_EFFECT_PLUS_PERCENT,            5).% 队伍中每个有效人数的加成 

-define(CONST_GROUP_RATE_LARGER_10,                 0).% 等级差大于10级 
-define(CONST_GROUP_RATE_5_10,                      100).% 等级差5到10级 
-define(CONST_GROUP_RATE_LESS_5,                    300).% 等级差少于5级 

%% ==========================================================
%% 资源
%% ==========================================================
-define(CONST_RESOURCE_BASERUNECHEST,               5).% 招财兑换宝箱次数 
-define(CONST_RESOURCE_LUCK_DOG_LIST,               10).% 大奖列表长度 
-define(CONST_RESOURCE_REAL_BIG_HIT,                100).% 中多少礼券才是大奖 
-define(CONST_RESOURCE_BASEGOLD,                    2000).% 招财神符的金钱计算基数 

-define(CONST_RESOURCE_COPPER_CHEST,                101).% 铜宝箱 
-define(CONST_RESOURCE_SILVER_CHEST,                102).% 银宝箱 
-define(CONST_RESOURCE_GOLDEN_CHEST,                103).% 金宝箱 

-define(CONST_RESOURCE_PRAY_TIMES,                  1).% 巡城次数 

-define(CONST_RESOURCE_NOBATCHRUNE,                 0).% 普通招财 
-define(CONST_RESOURCE_BATCHRUNE,                   1).% 批量招财 
-define(CONST_RESOURCE_BASENOBATCHRUNE,             1).% 普通招财次数 
-define(CONST_RESOURCE_BASEBATCHRUNE,               10).% 批量招财次数 

-define(CONST_RESOURCE_PRAY_XY,                     1).% 霸王项羽 
-define(CONST_RESOURCE_PRAY_HX,                     2).% 兵仙韩信 
-define(CONST_RESOURCE_PRAY_SW,                     3).% 兵圣孙武 

-define(CONST_RESOURCE_POOL_CD,                     0).% 抽奖cd 
-define(CONST_RESOURCE_POOL_EXP_INTERVAL_MIN,       1000).% 随机经验下限 
-define(CONST_RESOURCE_POOL_EXP_INTERVAL_MAX,       10000).% 随机经验上限 
-define(CONST_RESOURCE_POOL_EXP_INTERVAL,           10000).% 随机经验时间间隔 
-define(CONST_RESOURCE_POOL_BCASH_INTERVAL,         10000).% 礼券时间间隔 
-define(CONST_RESOURCE_POOL_BCASH_MIN,              10000).% 礼券奖池下限 
-define(CONST_RESOURCE_POOL_BCASH_MAX,              100000).% 礼券奖池上限 
-define(CONST_RESOURCE_POOL_EXP_MIN,                1000000).% 经验奖池下限 
-define(CONST_RESOURCE_POOL_EXP_MAX,                10000000).% 经验奖池上限 
-define(CONST_RESOURCE_POOL_MIN,                    100000000).% 奖池下限 
-define(CONST_RESOURCE_POOL_MAX,                    1000000000).% 奖池上限 

-define(CONST_RESOURCE_BGOLD_3RD,                   1000).% 3等奖多少钱 
-define(CONST_RESOURCE_BGOLD_2ND,                   10000).% 2等奖多少钱 
-define(CONST_RESOURCE_BGOLD_1ST,                   200000).% 1等奖多少钱 

-define(CONST_RESOURCE_POOL_LV_MIN,                 21).% 奖池计算等级下限 

%% ==========================================================
%% 排行榜
%% ==========================================================
-define(CONST_RANK_LV,                              1).% 等级 
-define(CONST_RANK_POSITION,                        2).% 官阶 
-define(CONST_RANK_VIP,                             3).% vip 
-define(CONST_RANK_POWER,                           4).% 战斗力 
-define(CONST_RANK_PARTNER,                         5).% 武将战斗力 
-define(CONST_RANK_EQUIP_POWER,                     6).% 装备战力 
-define(CONST_RANK_GUILD,                           7).% 军团 
-define(CONST_RANK_GUILD_POWER,                     8).% 军团战斗力 
-define(CONST_RANK_COPY,                            9).% 战场 
-define(CONST_RANK_ELITECOPY,                       10).% 英雄战场 
-define(CONST_RANK_DEVILCOPY,                       11).% 闯塔 
-define(CONST_RANK_SINGLE_ARENA,                    12).% 一骑讨 
-define(CONST_RANK_ARENA,                           13).% 战群雄 
-define(CONST_RANK_HORSE,                           14).% 坐骑战力 

-define(CONST_RANK_ONE,                             1).% 第一名 
-define(CONST_RANK_TWO,                             2).% 第二名 
-define(CONST_RANK_THREE,                           3).% 第三名 
-define(CONST_RANK_LIMIT_LV,                        18).% 等级限制 

-define(CONST_RANK_LINK,                            http://192.168.52.58:8080/rank/1/).% 排行榜链接 

%% ==========================================================
%% 精英副本
%% ==========================================================
-define(CONST_ELITECOPY_GENERAL,                    1).% 普通副本 
-define(CONST_ELITECOPY_ELITE,                      2).% 精英副本 
-define(CONST_ELITECOPY_DEVIL,                      3).% 魔鬼阵副本 

-define(CONST_ELITECOPY_WAVE_TIME,                  180).% 精英副本一波扫荡时间 

-define(CONST_ELITECOPY_AUTO_TURNCARD_ELITECOPY,    1).% 扫荡自动翻牌：精英副本 
-define(CONST_ELITECOPY_AUTO_TURNCARD_TOWER,        2).% 扫荡自动翻牌：破阵 

%% ==========================================================
%% 淘宝
%% ==========================================================
-define(CONST_LOTTERY_DEFAULTUSERID,                0).% 极品出世索引 
-define(CONST_LOTTERY_FIRSTCLASS,                   1).% 一级宝箱（铜钱宝箱） 
-define(CONST_LOTTERY_SHOW,                         1).% 极品道具展示 
-define(CONST_LOTTERY_MASTERWORK,                   1).% 极品 
-define(CONST_LOTTERY_FETCHSINGLE,                  1).% 取回单个物品 
-define(CONST_LOTTERY_OPENSINGLE,                   1).% 开启单个宝箱 
-define(CONST_LOTTERY_SECONDCLASS,                  2).% 二级宝箱（21-40级阶段的元宝宝箱） 
-define(CONST_LOTTERY_HARVEST,                      2).% 收获 
-define(CONST_LOTTERY_FETCHALL,                     2).% 取回全部物品 
-define(CONST_LOTTERY_THIRDCLASS,                   3).% 三级宝箱（41-60级阶段的元宝宝箱） 
-define(CONST_LOTTERY_BASESHOW,                     20).% 宝箱公告展示条数 
-define(CONST_LOTTERY_CAPACITY,                     100).% 淘宝宝库容量 
-define(CONST_LOTTERY_BASEMORAL,                    100).% 宝箱积累人品值基数 
-define(CONST_LOTTERY_MAXMORAL,                     100).% 宝箱积累人品最大值 

%% ==========================================================
%% 技能
%% ==========================================================
-define(CONST_SKILL_INIT_POINT,                     1).% 角色初始武技点 
-define(CONST_SKILL_SKILL_BAR_COUNT,                6).% 角色技能栏数量 
-define(CONST_SKILL_POINT_RESET_COST,               100).% 技能洗点花费元宝 

-define(CONST_SKILL_TYPE_ACTIVE,                    1).% 技能类型--主动技能 
-define(CONST_SKILL_TYPE_PASSIVE,                   2).% 技能类型--被动技能 
-define(CONST_SKILL_TYPE_NORMAL,                    3).% 技能类型--普通攻击 

-define(CONST_SKILL_ATK_TYPE_NEARBY,                1).% 近程 
-define(CONST_SKILL_ATK_TYPE_FARAWAY,               2).% 远程 

-define(CONST_SKILL_RATIO_FLAG_ROW,                 1).% 技能系数标示--横排 
-define(CONST_SKILL_RATIO_FLAG_COLUMN,              2).% 技能系数标示--竖列 
-define(CONST_SKILL_RATIO_FLAG_COUNT,               3).% 技能系数标示--目标数量 

-define(CONST_SKILL_GENIUS_TRIGGER_NULL,            0).% 天赋技能触发点--空 
-define(CONST_SKILL_GENIUS_TRIGGER_DEFAULT,         1).% 天赋技能触发点--默认(战斗初始化触发) 
-define(CONST_SKILL_GENIUS_TRIGGER_BOUT,            2).% 天赋技能触发点--回合(回合刷新触发) 
-define(CONST_SKILL_GENIUS_TRIGGER_MINUS_ANGER,     3).% 天赋技能触发点--消耗怒气(技能消耗怒气触发) 
-define(CONST_SKILL_GENIUS_TRIGGER_CURE,            4).% 天赋技能触发点--治疗 
-define(CONST_SKILL_GENIUS_TRIGGER_BE_CURE,         5).% 天赋技能触发点--受治疗 
-define(CONST_SKILL_GENIUS_TRIGGER_CHANGE,          6).% 天赋技能触发点--改变(生命、怒气、BUFF) 
-define(CONST_SKILL_GENIUS_TRIGGER_ATK_ATTR,        11).% 天赋技能触发点--攻击(修正属性) 
-define(CONST_SKILL_GENIUS_TRIGGER_ATK_HURT,        12).% 天赋技能触发点--攻击(修正伤害) 
-define(CONST_SKILL_GENIUS_TRIGGER_DEF_ATTR,        13).% 天赋技能触发点--防守(修正属性) 
-define(CONST_SKILL_GENIUS_TRIGGER_DEF_HURT,        14).% 天赋技能触发点--防守(修正伤害) 
-define(CONST_SKILL_GENIUS_TRIGGER_ATK,             15).% 天赋技能触发点--攻击 
-define(CONST_SKILL_GENIUS_TRIGGER_DEF,             16).% 天赋技能触发点--防守 
-define(CONST_SKILL_GENIUS_TRIGGER_ATK_TARGET,      17).% 天赋技能触发点--攻击(修正目标) 

-define(CONST_SKILL_GENIUS_EFFECT_ID_301,           301).% 天赋技能效果ID--默认，[arg1]回合内必然暴击 
-define(CONST_SKILL_GENIUS_EFFECT_ID_351,           351).% 天赋技能效果ID--回合，有[arg1]%几率解除[arg2]个DEBUFF 
-define(CONST_SKILL_GENIUS_EFFECT_ID_401,           401).% 天赋技能效果ID--技能消耗怒气，降低[arg1]%技能怒气消耗 
-define(CONST_SKILL_GENIUS_EFFECT_ID_451,           451).% 天赋技能效果ID--治疗，有[arg1]%几率解除[arg2]个DEBUFF 
-define(CONST_SKILL_GENIUS_EFFECT_ID_452,           452).% 天赋技能效果ID--治疗，有[arg1]%几率增加[arg2]%攻击力[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_501,           501).% 天赋技能效果ID--受治疗，有[arg1]%几率增加[arg2]%治疗效果 
-define(CONST_SKILL_GENIUS_EFFECT_ID_551,           551).% 天赋技能效果ID--怒气改变，怒气高于[arg1]%时，有[arg2]%几率增加[arg3]%物理攻击力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_601,           601).% 天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_602,           602).% 天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率增加[arg3]%法术攻击力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_603,           603).% 天赋技能效果ID--HP改变，生命低于[arg1]%时，有[arg2]%几率对目标[arg3]增加[arg4]%法术攻击力[arg5]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_651,           651).% 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%物理攻击力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_652,           652).% 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%，同时延长[arg1]BUFF效果[arg4]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_653,           653).% 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%暴击率 
-define(CONST_SKILL_GENIUS_EFFECT_ID_654,           654).% 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%速度 
-define(CONST_SKILL_GENIUS_EFFECT_ID_655,           655).% 天赋技能效果ID--BUFF改变，拥有[arg1]BUFF时，有[arg2]%几率增加[arg3]%闪避 
-define(CONST_SKILL_GENIUS_EFFECT_ID_701,           701).% 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%防御力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_702,           702).% 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%法术防御力 
-define(CONST_SKILL_GENIUS_EFFECT_ID_703,           703).% 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%生命上限[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_704,           704).% 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%速度[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_705,           705).% 天赋技能效果ID--攻击，有[arg1]%几率降低目标[arg2]%命中[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_706,           706).% 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率降低[arg2]%治疗效果[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_707,           707).% 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率解除[arg2]个BUFF 
-define(CONST_SKILL_GENIUS_EFFECT_ID_708,           708).% 天赋技能效果ID--攻击(技能攻击)，有[arg1]%几率降低目标[arg2]%怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_709,           709).% 天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%命中[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_710,           710).% 天赋技能效果ID--攻击(暴击)，有[arg1]%几率增加[arg2]%速度[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_711,           711).% 天赋技能效果ID--攻击(死亡)，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_712,           712).% 天赋技能效果ID--攻击(死亡)，有[arg1]%几率增加[arg2]点怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_713,           713).% 天赋技能效果ID--攻击(普通攻击并暴击)，有[arg1]%几率增加免疫DEBUFF[arg2]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_714,           714).% 天赋技能效果ID--攻击(普通攻击)，有[arg1]%几率对目标[arg2]降低[arg3]%命中[arg4]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_751,           751).% 天赋技能效果ID--防守，有[arg1]%几率降低[arg2]%伤害 
-define(CONST_SKILL_GENIUS_EFFECT_ID_752,           752).% 天赋技能效果ID--防守，有[arg1]%几率降低攻击者[arg2]%速度[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_753,           753).% 天赋技能效果ID--防守，伤害高于生命上限[arg1]%时，有[arg2]%几率增加[arg3]%物理防御力[arg4]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_754,           754).% 天赋技能效果ID--防守(受暴击)，有[arg1]%几率降低[arg2]%伤害 
-define(CONST_SKILL_GENIUS_EFFECT_ID_755,           755).% 天赋技能效果ID--防守(受暴击)，有[arg1]%几率增加[arg2]%闪避[arg3]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_756,           756).% 天赋技能效果ID--防守(死亡)，有[arg1]%几率复活，恢复[arg2]%生命 
-define(CONST_SKILL_GENIUS_EFFECT_ID_757,           757).% 天赋技能效果ID--防守，有[arg1]%几率对目标[arg2]增加[arg3]%物理防御力[arg4]回合 
-define(CONST_SKILL_GENIUS_EFFECT_ID_758,           758).% 天赋技能效果ID--防守，有[arg1]%几率反击一次 
-define(CONST_SKILL_GENIUS_EFFECT_ID_759,           759).% 天赋技能效果ID--防守，当发生格挡时，有[arg1]%机率提升[arg2]%物攻持续[arg3]回合，并有[arg4]%机率增加[a 
-define(CONST_SKILL_GENIUS_EFFECT_ID_760,           760).% 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_761,           761).% 天赋技能效果ID--防守发生暴击时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_762,           762).% 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_763,           763).% 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%暴击持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_764,           764).% 天赋技能效果ID--攻击被闪避时，有[arg1]%机率提升[arg2]%闪避持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_765,           765).% 天赋技能效果ID--攻击时，有[arg1]%机率提升[arg2]%术攻持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_766,           766).% 天赋技能效果ID--被治疗时，有[arg1]%机率提升[arg2]%格挡持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_767,           767).% 天赋技能效果ID--防守时，有[arg1]%机率提升[arg2]%双防持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_768,           768).% 天赋技能效果ID--攻击时，有[arg1]%机率多攻击[arg2]个目标，并有[arg3]%机率增加[arg4]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_769,           769).% 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_770,           770).% 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%命中持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_771,           771).% 天赋技能效果ID--攻击发生暴击时，有[arg1]%机率提升[arg2]%气血上限持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_772,           772).% 天赋技能效果ID--攻击时，有[arg1]%机率降低目标[arg2]%物理防御持续[arg3]回合，并有[arg4]%机率增加[arg5]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_773,           773).% 天赋技能效果ID--攻击时，有[arg1]%机率解除目标[arg2]的[arg3]个[arg4]buff，并有[arg5]%机率增加[arg6]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_774,           774).% 天赋技能效果ID--攻击时，有[arg1]%机率封印目标，并有[arg2]%机率增加[arg3]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_775,           775).% 天赋技能效果ID--攻击时，有[arg1]%机率沉默目标，并有[arg2]%机率增加[arg3]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_776,           776).% 天赋技能效果ID--死亡时，有[arg1]%机率提升目标[arg2][arg3]%双攻持续[arg4]回合，并有[arg5]%机率增加[arg6]怒气 
-define(CONST_SKILL_GENIUS_EFFECT_ID_801,           801).% 天赋技能效果ID--攻击(选择目标)，有[arg1]%几率增加[arg2]类型目标[arg3]个单位 

-define(CONST_SKILL_EFFECT_ID_1,                    1).% 技能效果ID--对目标[arg1]常规攻击(连续技) 
-define(CONST_SKILL_EFFECT_ID_2,                    2).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 
-define(CONST_SKILL_EFFECT_ID_3,                    3).% 技能效果ID--对目标[arg1]去掉[arg2]个DEBUFF 
-define(CONST_SKILL_EFFECT_ID_4,                    4).% 技能效果ID--对目标[arg1]有[arg2]几率附加眩晕[arg3]回合 
-define(CONST_SKILL_EFFECT_ID_5,                    5).% 技能效果ID--对目标[arg1]有[arg2]几率降低[arg3]%闪避[arg4]回合 
-define(CONST_SKILL_EFFECT_ID_11,                   11).% 技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 
-define(CONST_SKILL_EFFECT_ID_12,                   12).% 技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%生命[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_13,                   13).% 技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%速度[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_14,                   14).% 技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 对目标[arg4]降低[arg5]%生命[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_15,                   15).% 技能效果ID--对目标[arg1]治疗[arg2]%生命[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_20,                   20).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%怒气 
-define(CONST_SKILL_EFFECT_ID_21,                   21).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]点怒气 
-define(CONST_SKILL_EFFECT_ID_22,                   22).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_23,                   23).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%攻击力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_24,                   24).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理攻击力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_25,                   25).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术攻击力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_26,                   26).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%防御力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_27,                   27).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%物理防御力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_28,                   28).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%法术防御力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_29,                   29).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%速度[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_30,                   30).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%命中[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_31,                   31).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%闪避[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_32,                   32).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%暴击[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_33,                   33).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%招架[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_34,                   34).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%反击[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_35,                   35).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]回合后必然暴击 
-define(CONST_SKILL_EFFECT_ID_36,                   36).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]回合 && 附加免疫暴击[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_37,                   37).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%格档[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_38,                   38).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]提升[arg5]%的暴击和[arg6]%增加暴击伤害[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_51,                   51).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加沉默[arg4]回合 
-define(CONST_SKILL_EFFECT_ID_52,                   52).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加封印[arg4]回合 
-define(CONST_SKILL_EFFECT_ID_53,                   53).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加眩晕[arg4]回合 
-define(CONST_SKILL_EFFECT_ID_54,                   54).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 
-define(CONST_SKILL_EFFECT_ID_61,                   61).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加沉默[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_62,                   62).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_63,                   63).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加眩晕[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_64,                   64).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加[arg5]吸血效果[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_65,                   65).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加无敌效果[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_66,                   66).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫暴击[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_67,                   67).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]附加免疫惊鸿控制[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_81,                   81).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]点怒气 
-define(CONST_SKILL_EFFECT_ID_82,                   82).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_83,                   83).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理防御力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_84,                   84).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%物理攻击力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_85,                   85).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%速度[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_86,                   86).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%闪避[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_87,                   87).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%法术攻击力[ar 
-define(CONST_SKILL_EFFECT_ID_91,                   91).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命上限[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_92,                   92).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%物理防御力[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_93,                   93).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%怒气恢复效果[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_94,                   94).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_95,                   95).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%法术防御力[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_96,                   96).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%速度[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_97,                   97).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%生命[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_101,                  101).% 技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 
-define(CONST_SKILL_EFFECT_ID_102,                  102).% 技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 
-define(CONST_SKILL_EFFECT_ID_103,                  103).% 技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标附加封印[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_104,                  104).% 技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加封印[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_105,                  105).% 技能效果ID--无视被攻击目标[arg1]%防御力对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_106,                  106).% 技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 
-define(CONST_SKILL_EFFECT_ID_107,                  107).% 技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]附加沉默[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_108,                  108).% 技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理防御力[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_109,                  109).% 技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%格挡[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_111,                  111).% 技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 
-define(CONST_SKILL_EFFECT_ID_112,                  112).% 技能效果ID--对目标[arg1]附加[arg2]%吸血效果[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 && 有[arg6]几率对目标[arg7]附加无敌效果[arg8]回合 
-define(CONST_SKILL_EFFECT_ID_113,                  113).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%生命[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_121,                  121).% 技能效果ID--对目标[arg1]增加[arg2]%暴击[arg3]回合 && 对目标[arg4]常规攻击[arg5]连击 
-define(CONST_SKILL_EFFECT_ID_131,                  131).% 技能效果ID--对目标[arg1]增加[arg2]点怒气 && 有[arg3]几率对目标[arg4]附加封印[arg5]回合 
-define(CONST_SKILL_EFFECT_ID_132,                  132).% 技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]%当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_133,                  133).% 技能效果ID--对目标[arg1]增加[arg2]%法术防御力[arg3]回合 && 对目标[arg4]增加无视被攻击目标[arg5]%防御力[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_134,                  134).% 技能效果ID--对目标[arg1]有[arg2]%机率降低[arg3]点当前怒气 && 有[arg4]%机率降低[arg5]%治疗效果[arg6]回合 
-define(CONST_SKILL_EFFECT_ID_151,                  151).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%降低暴击率[arg9]回合 
-define(CONST_SKILL_EFFECT_ID_152,                  152).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率降低[arg4]%治疗效果[arg5]回合 && 有[arg6]几率对目标[arg7]增加[arg8]%物理攻击力[arg9]回合 
-define(CONST_SKILL_EFFECT_ID_153,                  153).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]降低[arg5]%防御力[arg6]回合 && 有[arg7]几率对目标[arg8]增加[arg9]%物理防御力[arg10]回合 
-define(CONST_SKILL_EFFECT_ID_154,                  154).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率附加暴击无效[arg4]回合 && 有[arg5]几率对目标[arg6]增加[arg7]%生命上限[arg8]回合 
-define(CONST_SKILL_EFFECT_ID_155,                  155).% 对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率对目标[arg4]增加[arg5]%生命上限[arg6]%物理[arg7]%法术防御[arg8]回合 
-define(CONST_SKILL_EFFECT_ID_156,                  156).% 技能效果ID--临时增加[arg1]%暴击 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%物理攻击力[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_157,                  157).% 技能效果ID--临时转换[arg1]%防御力到物理攻击力 && 对目标[arg2]常规攻击[arg3]连击 && 有[arg4]几率对目标[arg5]增加[arg6]%吸血[arg7]回合 
-define(CONST_SKILL_EFFECT_ID_158,                  158).% 技能效果ID--无视被攻击目标[arg1]%防御力 并 临时增加[arg2]%暴击 && 对目标[arg3]常规攻击[arg4]连击 
-define(CONST_SKILL_EFFECT_ID_159,                  159).% 技能效果ID--对目标[arg1]常规攻击[arg2]连击 && 有[arg3]几率解除目标[arg4]的[arg5]个增益Buff 

%% ==========================================================
%% 宠物
%% ==========================================================
-define(CONST_PET_BIG_CRIT_PRO_GOLD,                1).% 元宝训练大暴击概率 
-define(CONST_PET_BIG_CRIT_PRO_FAST,                1).% 快速训练大暴击概率 
-define(CONST_PET_SMALL_CRIT_VALUE_NORMAL,          2).% 普通训练小暴击经验加倍 
-define(CONST_PET_SMALL_CRIT_PRO_GOLD,              5).% 元宝训练小暴击概率 
-define(CONST_PET_SMALL_CRIT_VALUE_GOLD,            5).% 元宝训练小暴击加倍 
-define(CONST_PET_SMALL_CRIT_VALUE_FAST,            5).% 快速训练小暴击加倍 
-define(CONST_PET_SMALL_CRIT_PRO_FAST,              10).% 快速训练小暴击概率 
-define(CONST_PET_SMALL_CRIT_PRO_NORMAL,            11).% 普通训练小暴击概率 
-define(CONST_PET_APTITUDE_MAX,                     100).% 宠物资质上限 
-define(CONST_PET_ENHANCE_APTITUDE_COST,            100).% 提升资质花费 

%% ==========================================================
%% 家园
%% ==========================================================
-define(CONST_HOME_PLANT_NULL,                      1).% 空闲 
-define(CONST_HOME_PLANT_TYPE_CASH,                 1).% 种植类型铜钱 
-define(CONST_HOME_PLANT_HAS,                       2).% 已种植 
-define(CONST_HOME_PLANT_TYPE_EXP,                  2).% 种植类型经验 
-define(CONST_HOME_PLANT_CD,                        3).% 种植cd中 
-define(CONST_HOME_MUCK_TIMES,                      10).% 单块土地可被施肥次数 
-define(CONST_HOME_GRAB_FAIL_CD,                    60).% 抢夺失败cd(秒) 
-define(CONST_HOME_CHANGE_RECOM_CD,                 600).% 换一批侍女CD 
-define(CONST_HOME_BLACK_PLAY_TIME,                 600).% 小黑屋互动cd(秒) 
-define(CONST_HOME_LAND_COMMON_CD,                  28800).% 农场种植CD 

-define(CONST_HOME_COM_TASK,                        3).% 官府任务普通刷新(1个格子消耗) 
-define(CONST_HOME_OVER_TASK,                       3).% 任务立即完成消耗元宝数 
-define(CONST_HOME_ONE_KEY_TASK,                    10).% 官府任务一键刷新(1个格子消耗) 

-define(CONST_HOME_BASE,                            1).% 家园 
-define(CONST_HOME_FARM,                            2).% 农场 
-define(CONST_HOME_PUB,                             3).% 酒馆 
-define(CONST_HOME_MARKET,                          4).% 军团市场 
-define(CONST_HOME_PETHOLE,                         5).% 宠物洞 
-define(CONST_HOME_HORST,                           6).% 马厩 
-define(CONST_HOME_GIRL,                            7).% 仕女苑 
-define(CONST_HOME_SHOW,                            8).% 展示厅 
-define(CONST_HOME_OFFICE,                          11).% 官府 

-define(CONST_HOME_LAND_MIN_LV,                     0).% 土地最低等级 
-define(CONST_HOME_PLANT_MIN_LV,                    1).% 作物最低等级 
-define(CONST_HOME_LAND_MAX_LV,                     2).% 土地最高等级 
-define(CONST_HOME_PET_REFRESH_TIMES,               5).% 铜币刷新次数 
-define(CONST_HOME_PLANT_MAX_LV,                    5).% 作物最高等级 
-define(CONST_HOME_PLANT_MAX_COUNT,                 9).% 种植园最大格子数 
-define(CONST_HOME_PLANT_ONEKEYFRESH,               10).% 一键刷新元宝 

-define(CONST_HOME_ACT_GET_BREAD,                   1).% 领取俸禄 
-define(CONST_HOME_ACT_LAND_HARVEST,                2).% 土地收获 
-define(CONST_HOME_ACT_FOR_PRINCE,                  3).% 寻访武将 
-define(CONST_HOME_ACT_PRICE_GOUGING,               4).% 哄抬物价 
-define(CONST_HOME_ACT_GET_TURNOVER,                5).% 领取营业额 
-define(CONST_HOME_ACT_CULTURE_PONY,                6).% 培养马驹 
-define(CONST_HOME_ACT_GET_FRIENDS_BLESSING,        7).% 领取好友祝福 
-define(CONST_HOME_ACT_GET_EXP,                     8).% 获取活跃度经验 
-define(CONST_HOME_GET_GIRL_EXP,                    9).% 领取仕女苑经验 
-define(CONST_HOME_GRAB_GIRL,                       10).% 抢夺仕女 
-define(CONST_HOME_PLAY_GIRL,                       11).% 仕女互动 

-define(CONST_HOME_HOUSEWORK,                       1).% 仕女家务 
-define(CONST_HOME_COOK,                            2).% 仕女烹饪 
-define(CONST_HOME_MUSIC,                           3).% 仕女抚琴 
-define(CONST_HOME_ESCAPE,                          4).% 仕女逃跑 
-define(CONST_HOME_WINE,                            5).% 仕女对饮 
-define(CONST_HOME_RECITE,                          6).% 仕女吟诗 
-define(CONST_HOME_POME,                            7).% 仕女赋诗 

-define(CONST_HOME_MESSAGE_HELP_LOOSEN,             1).% 好友帮助松土 
-define(CONST_HOME_MESSAGE_HELP_MUCK,               2).% 好友帮助施肥 
-define(CONST_HOME_MESSAGE_LOOK_SHOW,               3).% 好友观看了藏宝阁 
-define(CONST_HOME_MESSAGE_GRAB_GIRL,               4).% 你抢夺侍女 
-define(CONST_HOME_MESSAGE_SHOW_MODLE,              5).% 你展示了道具 
-define(CONST_HOME_MESSAGE_USE_STAGE,               6).% 你使用了道具 
-define(CONST_HOME_MESSAGE_GET_REWARD,              7).% 你领取了官府俸禄 
-define(CONST_HOME_MESSAGE_PLAY_GRIL,               8).% 你和侍女互动 
-define(CONST_HOME_MESSAGE_GIRL_ESCAPE,             9).% 你抢夺的仕女逃跑了 
-define(CONST_HOME_GIRL_GRABED,                     10).% 你的好友抢夺了你的仕女 
-define(CONST_HOME_MESSAGE_HELP_UPDATE,             11).% 你帮助了好友升级家园 
-define(CONST_HOME_MESSAGE_HELP_MUCKED,             12).% 你去了好友土地施肥 
-define(CONST_HOME_MESSAGE_HELP_LOOSENED,           13).% 你去了好友土地松土 
-define(CONST_HOME_PLAY_MAIN_GIRL,                  14).% 你去互动了好友仕女 

-define(CONST_HOME_MESSAGE_TYPE0,                   0).% 留言类型--正常值 
-define(CONST_HOME_MESSAGE_TYPE1,                   1).% 留言类型--侍女家务 
-define(CONST_HOME_MESSAGE_TYPE2,                   2).% 留言类型--侍女烹饪 
-define(CONST_HOME_MESSAGE_TYPE3,                   3).% 留言类型--侍女抚琴 
-define(CONST_HOME_MESSAGE_TYPE4,                   4).% 留言类型--时间值 
-define(CONST_HOME_MESSAGE_TYPE5,                   5).% 留言类型--查仕女表 
-define(CONST_HOME_MESSAGE_TYPE6,                   6).% 留言类型--查道具表 

-define(CONST_HOME_GIRL_INFO1,                      1).% 仕女信息--自己 
-define(CONST_HOME_GIRL_INFO2,                      2).% 仕女信息-- 小黑屋 
-define(CONST_HOME_GIRL_INFO3,                      3).% 仕女信息-- 好友 
-define(CONST_HOME_GIRL_INFO4,                      4).% 仕女信息-- 招募列表 

-define(CONST_HOME_PLANT_RATE,                      16).% 种植互动奖励系数 
-define(CONST_HOME_PLANT_BASE,                      64).% 种植互动奖励基数 

-define(CONST_HOME_TASK_FURANCE,                    1).% 官府任务:进行一次强化 
-define(CONST_HOME_TASK_COPY,                       2).% 官府任务:通关一次副本 
-define(CONST_HOME_TASK_FURANCE_SOUL,               3).% 官府任务:装备刻印 
-define(CONST_HOME_TASK_ARENA,                      4).% 官府任务:一骑讨获胜一次 
-define(CONST_HOME_TASK_PATROL,                     5).% 官府任务:巡城一次 
-define(CONST_HOME_TASK_ABILITY,                    5).% 官府任务:奇门升级 
-define(CONST_HOME_TASK_GET_COIN,                   6).% 官府任务:进行一次收夺 
-define(CONST_HOME_TASK_COMMERCE,                   7).% 官府任务:完成一次商路押运 
-define(CONST_HOME_TASK_FRIEND,                     7).% 官府任务:添加好友 
-define(CONST_HOME_TASK_PLANT,                      8).% 官府任务:进行一农场种植 
-define(CONST_HOME_TASK_GRAB,                       9).% 官府任务:进行一次侍女掠夺 
-define(CONST_HOME_TASK_GUILD_DONATE,               10).% 官府任务:完成一次军团捐献 
-define(CONST_HOME_TASK_TRAIN,                      11).% 官府任务:进行一次角色培养 
-define(CONST_HOME_TASK_HORSE,                      12).% 官府任务:进行一次坐骑喂养 
-define(CONST_HOME_TASK_MIND,                       13).% 官府任务:进行一次祈天 

-define(CONST_HOME_AWARD_CASH,                      10).% 封邑日常礼包:礼券 
-define(CONST_HOME_AWARD_MER,                       3000).% 封邑日常礼包:历练 
-define(CONST_HOME_AWARD_GOLD,                      100000).% 封邑日常礼包:铜钱 

-define(CONST_HOME_RESOUCE_EXP,                     1).% 资源类型:经验 
-define(CONST_HOME_RESOUCE_GOLD,                    2).% 资源类型:铜钱 
-define(CONST_HOME_RESOUCE_SER,                     3).% 资源类型:历练 

-define(CONST_HOME_PLANT_EXP,                       3000).% 种植收获:经验 
-define(CONST_HOME_PLANT_GOLD,                      10000).% 种植收获:铜钱 
-define(CONST_HOME_PLANT_MER,                       20000).% 种植收获:历练 

-define(CONST_HOME_PLAY_GIRL_EXP,                   20).% 小黑屋仕女互动系数:经验 
-define(CONST_HOME_PLAY_GIRL_GOLD,                  80).% 小黑屋仕女互动系数:铜钱 
-define(CONST_HOME_PLAY_GIRL_MER,                   200).% 小黑屋仕女互动系数:历练 

-define(CONST_HOME_FLOWER_AWARD,                    10000).% 花魁日俸 

-define(CONST_HOME_PLAY_MAX,                        10).% 主界面仕女互动次数 

-define(CONST_HOME_ADD_GRAB_TIMES,                  100).% 增加抢夺次数耗费 

-define(CONST_HOME_BLACK_NUM,                       3).% 小黑屋最大格子数 
-define(CONST_HOME_GRID_MAX,                        4).% 推荐/小黑屋格子最大数 
-define(CONST_HOME_FLOWER_MAX,                      30).% 花魁互动次数 

-define(CONST_HOME_TASK_NUM,                        13).% 官府任务:总数 

-define(CONST_HOME_RESCUE_TIMES,                    3).% 侍女苑:解救次数 
-define(CONST_HOME_GRAB_MAX,                        4).% 侍女苑:抢夺次数 
-define(CONST_HOME_PLAY_TIMES,                      6).% 侍女苑:互动次数 

%% ==========================================================
%% 地图
%% ==========================================================
-define(CONST_MAP_TYPE_CITY,                        1).% 地图类型--城市 
-define(CONST_MAP_TYPE_COPY,                        2).% 地图类型--副本 
-define(CONST_MAP_TYPE_SPRING,                      31).% 地图类型--温泉 
-define(CONST_MAP_TYPE_TOWER,                       32).% 地图类型--闯塔 
-define(CONST_MAP_TYPE_BOSS,                        33).% 地图类型--世界BOSS 
-define(CONST_MAP_TYPE_GATHER,                      34).% 地图类型--采集 
-define(CONST_MAP_TYPE_GUILD,                       35).% 地图类型--军团宴会 
-define(CONST_MAP_TYPE_COLLECT,                     36).% 地图类型--采集玩法 
-define(CONST_MAP_TYPE_GUARD,                       37).% 地图类型--异民族 
-define(CONST_MAP_TYPE_WORLD,                       38).% 地图类型--乱天下 
-define(CONST_MAP_TYPE_FACTION,                     39).% 地图类型--阵营战 
-define(CONST_MAP_TYPE_MCOPY,                       40).% 地图类型--多人副本 
-define(CONST_MAP_TYPE_CAMP_PVP,                    41).% 地图类型--阵营战交战区 
-define(CONST_MAP_GUILD_PVP_HOME,                   42).% 地图类型-军团战和平区 
-define(CONST_MAP_GUILD_PVP_BATTLE,                 43).% 地图类型-军团战交战区 
-define(CONST_MAP_TYPE_LATERN,                      44).% 地图类型--元宵副本 

-define(CONST_MAP_DEPOT_OPEN,                       1).% 打开仓库 

-define(CONST_MAP_SHOP,                             1).% 打开商店 

-define(CONST_MAP_ACTIVITY_1,                       1).% 活动1 
-define(CONST_MAP_ACTIVITY_2,                       2).% 活动2 

-define(CONST_MAP_PUB_OPEN,                         1).% 打开酒馆 

-define(CONST_MAP_TASK_OPEN,                        1).% 打开任务 

-define(CONST_MAP_NEWFISH_EXCHANGE,                 1).% 兑换新手卡 

-define(CONST_MAP_PTYPE_HUMAN,                      1).% 地图玩家类型--人类 
-define(CONST_MAP_PTYPE_ROBOT,                      2).% 地图玩家类型--温泉机器人 
-define(CONST_MAP_PTYPE_BOSS_ROBOT,                 3).% 地图玩家类型--妖魔破机器人 
-define(CONST_MAP_PTYPE_COPY_ROBOT,                 4).% 地图玩家类型-多人副本 
-define(CONST_MAP_PTYPE_INV_ROBOT,                  5).% 地图玩家类型-异民族 
-define(CONST_MAP_PTYPE_PRACTICE_ROBOT,             6).% 地图玩家类型--修炼机器人 
-define(CONST_MAP_PTYPE_PARTY_ROBOT,                7).% 地图玩家类型--军团宴会机器人 
-define(CONST_MAP_PTYPE_WORLD_ROBOT,                8).% 地图玩家类型--乱天下机器人 

-define(CONST_MAP_NPC_TYPE_DRAMA,                   1).% NPC类型--剧情NPC 
-define(CONST_MAP_NPC_TYPE_FUNC,                    2).% NPC类型--功能NPC 

-define(CONST_MAP_NPC_FUNC_DEPOT,                   1).% NPC功能--仓库 
-define(CONST_MAP_NPC_FUNC_SHOP,                    2).% NPC功能--商店 
-define(CONST_MAP_NPC_FUNC_ACTIVITY,                3).% NPC功能--活动 
-define(CONST_MAP_NPC_FUNC_PUB,                     4).% NPC功能--酒馆 
-define(CONST_MAP_NPC_FUNC_TASK,                    5).% NPC功能--任务 
-define(CONST_MAP_NPC_FUNC_GUIDE,                   6).% NPC功能--新手指导员 
-define(CONST_MAP_NPC_FUNC_COLLECT,                 7).% NPC功能--采集 

-define(CONST_MAP_MAX_LINE,                         10).% 最大分线数 
-define(CONST_MAP_MAX_1,                            50).% 人数上限1级 
-define(CONST_MAP_MAX_MEMBER,                       200).% 地图中的最大人数 
-define(CONST_MAP_MAX_2,                            200).% 人数上限2级 

-define(CONST_MAP_SHOW_TYPE_FIREWORKS,              1).% 全屏效果--烟花 

%% ==========================================================
%% 遁甲天书
%% ==========================================================
-define(CONST_MERIDIAN_EXERCISES,                   1).% 内功 
-define(CONST_MERIDIAN_CAMP,                        2).% 阵法 

-define(CONST_MERIDIAN_MAX_FREE_8_TIMES,            1).% 八门免费次数 
-define(CONST_MERIDIAN_MAX_DICE,                    8).% 八门的最大值 
-define(CONST_MERIDIAN_MAX_CAMP_LV,                 20).% 最大阵法等级 
-define(CONST_MERIDIAN_MAX_EXERCISES_LV,            100).% 最大内功等级 
-define(CONST_MERIDIAN_MAX_CD,                      7200).% 升级的最大cd上限 

-define(CONST_MERIDIAN_ONCE_UPGRATE_CASH,           2).% 一次花费元宝数 

-define(CONST_MERIDIAN_FEED,                        5).% 气血 

%% ==========================================================
%% 战斗
%% ==========================================================
-define(CONST_BATTLE_SKIP_COST,                     2).% 跳过战斗花费元宝数 
-define(CONST_BATTLE_MUSIC_ID,                      7).% 战斗默认音乐 
-define(CONST_BATTLE_BOUT_MAX,                      50).% 战斗最大回合数 
-define(CONST_BATTLE_FREE_SKIP_TIMES,               50).% 免费跳过次数 
-define(CONST_BATTLE_TIME_RESIST,                   2000).% 战斗反击时间(毫秒：2000) 
-define(CONST_BATTLE_TIME_PREPARE,                  3000).% 战斗开始准备时间(毫秒：3000) 
-define(CONST_BATTLE_TIME_PREPARE_HORSE,            4500).% 战斗开始准备时间，包括坐骑技能(毫秒：4500) 
-define(CONST_BATTLE_TIMEOUT,                       600000).% 战斗进程超时时间(毫秒：600000) 

-define(CONST_BATTLE_UNITS_SIDE_LEFT,               1).% 战斗单元集合归属--左 
-define(CONST_BATTLE_UNITS_SIDE_RIGHT,              2).% 战斗单元集合归属--右 

-define(CONST_BATTLE_UNIT_STATE_NORMAL,             100).% 战斗单元状态--正常 
-define(CONST_BATTLE_UNIT_STATE_DEATH,              110).% 战斗单元状态--死亡 

-define(CONST_BATTLE_STEP_FRONT,                    1).% 战斗阶段--前 
-define(CONST_BATTLE_STEP_MIDDLE,                   2).% 战斗阶段--中 
-define(CONST_BATTLE_STEP_BACK,                     3).% 战斗阶段--后 

-define(CONST_BATTLE_STOP_REASON_TIMEOUT,           1).% 强制终止战斗原因--战斗超时 
-define(CONST_BATTLE_STOP_REASON_NEW,               2).% 强制终止战斗原因--新战队开始 

-define(CONST_BATTLE_SINGLE_COPY,                   1).% 战斗类型--单人副本 
-define(CONST_BATTLE_SINGLE_ARENA,                  2).% 战斗类型--单人竞技场 
-define(CONST_BATTLE_BOSS,                          3).% 战斗类型--世界boss 
-define(CONST_BATTLE_TRIBE_COPY,                    4).% 战斗类型--多人副本 
-define(CONST_BATTLE_TRIBE_ARENA,                   5).% 战斗类型--多人竞技场 
-define(CONST_BATTLE_TOWER,                         6).% 战斗类型--闯塔 
-define(CONST_BATTLE_COMMERCE,                      7).% 战斗类型--运镖(商路) 
-define(CONST_BATTLE_KILL_NPC,                      8).% 战斗类型--NPC对话战斗 
-define(CONST_BATTLE_INVASION_GUARD,                9).% 战斗类型--异民族（守关） 
-define(CONST_BATTLE_HOME,                          10).% 战斗类型--家园抢夺仕女 
-define(CONST_BATTLE_FACTION_MONSTER,               11).% 战斗类型--阵营战,和npc打 
-define(CONST_BATTLE_FACTION_PERSON,                12).% 战斗类型--阵营战，与玩家打 
-define(CONST_BATTLE_WORLD,                         14).% 战斗类型--乱天下 
-define(CONST_BATTLE_MCOPY_Q,                       15).% 战斗类型--奇遇发起的战斗 
-define(CONST_BATTLE_INVASION_ATTACK,               16).% 战斗类型--异民族（闯关） 
-define(CONST_BATTLE_PARTY,                         17).% 战斗类型--宴会(类似世界boss) 
-define(CONST_BATTLE_CAMP_PVP,                      18).% 阵营战 
-define(CONST_BATTLE_GUILD_PVE,                     19).% 战斗类型 -- 军团战 pve 
-define(CONST_BATTLE_GUILD_PVP,                     20).% 战斗类型 -- 军团战 pvp 
-define(CONST_BATTLE_PARTY_PK,                      21).% 战斗类型--宴会pk 
-define(CONST_BATTLE_CROSS_ARENA,                   22).% 战斗类型--跨服竞技场 
-define(CONST_BATTLE_CROSS_ARENA_ROBOT,             23).% 战斗类型--跨服竞技场机器人 
-define(CONST_BATTLE_GENERAL_MAP,                   24).% 战斗类型--普通地图切磋 
-define(CONST_BATTLE_ENCROACH_VETERAN,              25).% 战斗类型--攻城掠地精兵 
-define(CONST_BATTLE_ENCROACH_GENERAL,              26).% 战斗类型--攻城掠地大将 
-define(CONST_BATTLE_SINGLE_ROBOT,                  30).% 战斗类型--一骑讨robot 
-define(CONST_BATTLE_TEACH,                         31).% 战斗类型--教学 
-define(CONST_BATTLE_MATCH,                         32).% 战斗类型--闯关璧山 
-define(CONST_BATTLE_TYPE_REPORT,                   99).% 战斗类型--战报 
-define(CONST_BATTLE_TEST_PLAYER,                   101).% 战斗类型--测试(角色) 
-define(CONST_BATTLE_TEST_MONSTER,                  102).% 战斗类型--测试(怪物) 

-define(CONST_BATTLE_CRIT_DEFAULT,                  0).% 战斗暴击标示--默认无效 
-define(CONST_BATTLE_CRIT_TRUE,                     1).% 战斗暴击标示--暴击 
-define(CONST_BATTLE_CRIT_FALSE,                    2).% 战斗暴击标示--非暴击 

-define(CONST_BATTLE_DISPLAY_NORMAL_ATK,            1).% 战斗表现--正常攻击 
-define(CONST_BATTLE_DISPLAY_NORMAL_DEF,            2).% 战斗表现--正常受击(敌方) 
-define(CONST_BATTLE_DISPLAY_NORMAL_DEF2,           3).% 战斗表现--正常受击(己方) 
-define(CONST_BATTLE_DISPLAY_PARRY,                 4).% 战斗表现--格挡 
-define(CONST_BATTLE_DISPLAY_DODGE,                 5).% 战斗表现--闪避 
-define(CONST_BATTLE_DISPLAY_RESIST_ATK,            11).% 战斗表现--反击攻击 
-define(CONST_BATTLE_DISPLAY_RESIST_DEF,            12).% 战斗表现--反击受击 
-define(CONST_BATTLE_DISPLAY_BUFF_FRONT,            21).% 战斗表现--BUFF影响(前) 
-define(CONST_BATTLE_DISPLAY_BUFF_MIDDLE,           22).% 战斗表现--BUFF影响(中) 
-define(CONST_BATTLE_DISPLAY_BUFF_BACK,             23).% 战斗表现--BUFF影响(后) 
-define(CONST_BATTLE_DISPLAY_ATK,                   31).% 战斗表现--普通攻击 
-define(CONST_BATTLE_DISPLAY_DEF,                   32).% 战斗表现--普通受击 
-define(CONST_BATTLE_DISPLAY_GENIUS_ATK_FRONT,      41).% 战斗表现--天赋技能攻击(前) 
-define(CONST_BATTLE_DISPLAY_GENIUS_DEF_FRONT,      42).% 战斗表现--天赋技能防守(前) 
-define(CONST_BATTLE_DISPLAY_GENIUS_ATK_BACK,       43).% 战斗表现--天赋技能攻击(后) 
-define(CONST_BATTLE_DISPLAY_GENIUS_DEF_BACK,       44).% 战斗表现--天赋技能防守(后) 

-define(CONST_BATTLE_TARGET_SIDE_DEFAULT,           0).% 目标方阵--默认 
-define(CONST_BATTLE_TARGET_SIDE_HERE,              1).% 目标方阵--己方 
-define(CONST_BATTLE_TARGET_SIDE_THERE,             2).% 目标方阵--对方 

-define(CONST_BATTLE_TARGET_TYPE_DEFAULT,           0).% 目标类型--默认已有目标 
-define(CONST_BATTLE_TARGET_TYPE_SELF,              1).% 目标类型--自己 
-define(CONST_BATTLE_TARGET_TYPE_SINGLE,            2).% 目标类型--单体 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR,         3).% 目标类型--攻击目标相邻目标 
-define(CONST_BATTLE_TARGET_TYPE_MIN_HP,            4).% 目标类型--血量最少 
-define(CONST_BATTLE_TARGET_TYPE_MAX_MAGIC_ATTACK,  5).% 目标类型--法术攻击力最大 
-define(CONST_BATTLE_TARGET_TYPE_MIN_HP_2,          6).% 目标类型--血量最少2人 
-define(CONST_BATTLE_TARGET_TYPE_MIN_HP_3,          7).% 目标类型--血量最少3人 
-define(CONST_BATTLE_TARGET_TYPE_MIN_HP_4,          8).% 目标类型--血量最少4人 
-define(CONST_BATTLE_TARGET_TYPE_MIN_HP_5,          9).% 目标类型--血量最少5人 
-define(CONST_BATTLE_TARGET_TYPE_ALL,               30).% 目标类型--全体 
-define(CONST_BATTLE_TARGET_TYPE_ALL_MAGIC,         31).% 目标类型--全体法系职业 
-define(CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_1,      32).% 目标类型--敌方随机1人 
-define(CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_2,      33).% 目标类型--敌方随机2人 
-define(CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_3,      34).% 目标类型--敌方随机3人 
-define(CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_4,      35).% 目标类型--敌方随机4人 
-define(CONST_BATTLE_TARGET_TYPE_ALL_RANDOM_5,      36).% 目标类型--敌方随机5人 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_1,       51).% 目标类型--攻击目标相邻目标1人 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_2,       52).% 目标类型--攻击目标相邻目标2人 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_3,       53).% 目标类型--攻击目标相邻目标3人 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_4,       54).% 目标类型--攻击目标相邻目标4人 
-define(CONST_BATTLE_TARGET_TYPE_NEIGHBOUR_5,       55).% 目标类型--攻击目标相邻目标5人 
-define(CONST_BATTLE_TARGET_TYPE_ROW,               60).% 目标类型--攻击目标所在列 
-define(CONST_BATTLE_TARGET_TYPE_COLUMN,            90).% 目标类型--攻击目标所在行（最前排） 
-define(CONST_BATTLE_TARGET_TYPE_COLUMN_LAST,       91).% 目标类型--最后一行 
-define(CONST_BATTLE_TARGET_TYPE_COLUMN_MAGIC,      92).% 目标类型--最后一行的所有法系职业 
-define(CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_1,   93).% 目标类型--最后一行的随机1人 
-define(CONST_BATTLE_TARGET_TYPE_COLUMN_RANDOM_3,   94).% 目标类型--最后两行的随机3人 

-define(CONST_BATTLE_RESULT_DEFAULT,                0).% 战斗结果--默认值 
-define(CONST_BATTLE_RESULT_LEFT,                   1).% 战斗结果--左方胜利 
-define(CONST_BATTLE_RESULT_RIGHT,                  2).% 战斗结果--右方胜利 
-define(CONST_BATTLE_RESULT_DRAW,                   3).% 战斗结果--平局 

-define(CONST_BATTLE_ANGER_MAX_PARTNER,             100).% 战斗怒气上限--武将 
-define(CONST_BATTLE_ANGER_MAX_MONSTER,             100).% 战斗怒气上限--怪物 
-define(CONST_BATTLE_ANGER_MAX_PLAYER,              200).% 战斗怒气上限--角色 

-define(CONST_BATTLE_ANGER_INIT_PLAYER,             50).% 战斗初始怒气--角色 
-define(CONST_BATTLE_ANGER_INIT_PARTNER,            50).% 战斗初始怒气--武将 
-define(CONST_BATTLE_ANGER_INIT_MONSTER,            50).% 战斗初始怒气--怪物 

-define(CONST_BATTLE_ANGER_DVALUE,                  40).% 战斗怒气增量 

-define(CONST_BATTLE_ACT_REASON_FORBID,             0).% 无法使用技能原因--禁止行动 
-define(CONST_BATTLE_ACT_REASON_CD,                 1).% 无法使用技能原因--CD 
-define(CONST_BATTLE_ACT_REASON_ANGER,              2).% 无法使用技能原因--怒气 
-define(CONST_BATTLE_ACT_REASON_BUFF,               3).% 无法使用技能原因--BUFF 

-define(CONST_BATTLE_TARGET_TYPE_EXT_NEIGHBOUR,     1).% 目标类型扩展--攻击目标相邻目标 

-define(CONST_BATTLE_BUFF_IMMUNE,                   1).% 战斗设置BUFF--免疫BUFF 
-define(CONST_BATTLE_BUFF_OPPOSE,                   2).% 战斗设置BUFF--对立BUFF 

%% ==========================================================
%% 坐骑
%% ==========================================================
-define(CONST_HORSE_EQUIP_EXP,                      15).% 装备强化倍数 

-define(CONST_HORSE_DEVELOP,                        1).% 培养 
-define(CONST_HORSE_STRENGTHEN,                     2).% 强化 

-define(CONST_HORSE_NO_CRIT,                        1).% 无暴击 
-define(CONST_HORSE_SMALL_CRIT,                     2).% 小暴击 
-define(CONST_HORSE_BIG_CRIT,                       3).% 大暴击 

-define(CONST_HORSE_MALL_COST_TYPE,                 1).% 商城升级消耗类型 
-define(CONST_HORSE_MALL_COST_VALUE,                10).% 商城升级消耗值 

-define(CONST_HORSE_CD_COST,                        180).% 180秒1元宝 

-define(CONST_HORSE_FREE_COUNT,                     0).% 免费强化次数 

-define(CONST_HORSE_MAX_SLOT,                       4).% 培养槽个数上限 

-define(CONST_HORSE_MIN_SLOT_ID,                    1).% 培养槽起始id 

-define(CONST_HORSE_TEMP_TIME,                      3600).% 坐骑时间 

-define(CONST_HORSE_MAX_LEVEL,                      100).% 坐骑最高等级 

%% ==========================================================
%% 心法
%% ==========================================================
-define(CONST_MIND_DAILY_FREE_TIMES,                3).% 每天免费祈天次数 
-define(CONST_MIND_LV_MAX,                          10).% 心法最大等级 
-define(CONST_MIND_PER_EXTEND_COST,                 50).% 开启每行心法背包费用(元宝) 
-define(CONST_MIND_MIND_MAX,                        100).% 心法数量上限(所有种类心法) 

-define(CONST_MIND_READ_FINISH,                     0).% 一键参阅结束 
-define(CONST_MIND_READ_UNFINISH,                   1).% 一键参阅未结束 

-define(CONST_MIND_POS_1,                           1).% 地煞 
-define(CONST_MIND_POS_2,                           2).% 天罡 
-define(CONST_MIND_POS_3,                           3).% 星辰 
-define(CONST_MIND_POS_4,                           4).% 元辰 

-define(CONST_MIND_TYPE_EQUIP,                      1).% 人物心法区 
-define(CONST_MIND_TYPE_BAG,                        2).% 心法背包区 
-define(CONST_MIND_TYPE_TEMP_BAG,                   3).% 心法临时背包区 

-define(CONST_MIND_UNLOCK,                          0).% 未锁定 
-define(CONST_MIND_LOCK,                            1).% 锁定 

-define(CONST_MIND_PER_EXTEND_NUM,                  5).% 每次开启心法背包格子数 
-define(CONST_MIND_USER_CEIL_MAX,                   8).% 装备区心法数量上限 
-define(CONST_MIND_BAG_CEIL_DEFAULT,                10).% 心法背包默认开启数量 
-define(CONST_MIND_TEMP_BAG_CEIL_MAX,               20).% 心法临时背包数量上限 
-define(CONST_MIND_BAG_CEIL_MAX,                    25).% 心法背包数量上限 

-define(CONST_MIND_PICK_CONVERT,                    1).% 拾取并转化低级心法 
-define(CONST_MIND_ABSORB_NORMAL,                   1).% 心法转换类型：普通 
-define(CONST_MIND_ABSORB_FORCE,                    2).% 心法转换类型：强制 

-define(CONST_MIND_SECRET_CLOSE,                    0).% 心法秘籍关闭 
-define(CONST_MIND_SECRET_OPEN,                     1).% 心法秘籍开启 

-define(CONST_MIND_READ_NORMAL,                     1).% 铜钱参阅 
-define(CONST_MIND_READ_CASH,                       2).% 元宝参阅 

-define(CONST_MIND_FAIL,                            0).% 失败 
-define(CONST_MIND_OK,                              1).% 成功 

-define(CONST_MIND_TYPE_PLAYER,                     1).% 玩家 
-define(CONST_MIND_TYPE_PARTNER,                    2).% 武将 

-define(CONST_MIND_CASH_READ_MAX_A,                 1000000).% 地级参阅每日上限 
-define(CONST_MIND_CASH_READ_MAX_B,                 1000000).% 天级参阅每日上限 

-define(CONST_MIND_READ_CASH_1,                     2).% 星辰祈天递增值 
-define(CONST_MIND_READ_CASH_2,                     5).% 元辰祈天递增值 

-define(CONST_MIND_MAX_SCORE,                       9999999).% 积分上限 

-define(CONST_MIND_EX_TYPE_INNER,                   1).% 交换类型--背包内交换 
-define(CONST_MIND_EX_TYPE_EQUIP,                   2).% 交换类型--装备区内交换 
-define(CONST_MIND_EX_TYPE_BAG2EQUIP,               3).% 交换类型--背包到装备 
-define(CONST_MIND_EX_TYPE_EQUIP2BAG,               4).% 交换类型--装备到背包 

%% ==========================================================
%% 炼炉
%% ==========================================================
-define(CONST_FURNACE_STREN_QUEUE_MAX,              2).% 最大强化队列数目 
-define(CONST_FURNACE_PLUS_DROP_LV,                 50).% 掉落洗练属性的装备等级限制 
-define(CONST_FURNACE_SOUL_MAX,                     64).% 附魂种类数目 
-define(CONST_FURNACE_OPEN_STREN_QUEUE_COST,        100).% 开启强化队列费用 
-define(CONST_FURNACE_CD_PER_CASH,                  300).% 清除CD：一元宝X秒 

-define(CONST_FURNACE_PLUS_COST,                    100).% 洗练费用 
-define(CONST_FURNACE_PLUS_INHERIT_COST,            100).% 洗练继承费用 
-define(CONST_FURNACE_SOUL_COST,                    100).% 附魂费用 
-define(CONST_FURNACE_GOODS_FORGE_COST,             100).% 道具合成费用 
-define(CONST_FURNACE_CLEAR_STREN_QUEUE_COST,       100).% 清除当前强化队列费用 
-define(CONST_FURNACE_CLEAR_FOREVER_COST,           10000).% 永久清除强化队列费用 

-define(CONST_FURNACE_CLEAR_THIS_TIME,              1).% 清除当前CD 
-define(CONST_FURNACE_CLEAR_ALL_QUEUE_THIS_TIME,    2).% 清除所有强化队列 
-define(CONST_FURNACE_CLEAR_FOREVER,                3).% 永久清除CD 

-define(CONST_FURNACE_GREEN_STREN_MODULUS,          10000).% 绿色装备品阶强化系数 
-define(CONST_FURNACE_BLUE__STREN_MODULUS,          15000).% 蓝色装备品阶强化系数 
-define(CONST_FURNACE_PURPLE__STREN_MODULUS,        20000).% 紫色装备品阶强化系数 
-define(CONST_FURNACE_ORANGE__STREN_MODULUS,        25000).% 橙色装备品阶强化系数 
-define(CONST_FURNACE_RED__STREN_MODULUS,           30000).% 红色装备品阶强化系数 

-define(CONST_FURNACE_TIME_CD,                      300).% cd 
-define(CONST_FURNACE_TIME_MAX_QUEUE,               1200).% 最大冷却时间 

-define(CONST_FURNACE_TYPE_CREATE,                  1).% 新建队列 
-define(CONST_FURNACE_TYPE_UPDATE,                  2).% 更新 
-define(CONST_FURNACE_TYPE_DELETE,                  3).% 删除 

-define(CONST_FURNACE_F_TYPE_INHERIT,               1).% 继承 
-define(CONST_FURNACE_F_TYPE_PLUS,                  2).% 洗练 
-define(CONST_FURNACE_F_TYPE_PLUS_INHERIT,          3).% 洗练继承 
-define(CONST_FURNACE_F_TYPE_SOUL,                  4).% 附魂 
-define(CONST_FURNACE_F_TYPE_STREN,                 5).% 强化 

-define(CONST_FURNACE_FORGE_DIRECT,                 1).% 直接锻造 
-define(CONST_FURNACE_FORGE_NORMAL,                 2).% 普通锻造 
-define(CONST_FURNACE_UPGRADE_DIRECT,               3).% 直接升阶 
-define(CONST_FURNACE_UPGRADE_NORMAL,               4).% 普通升阶 

-define(CONST_FURNACE_GREEN_SOUL_FACTOR,            10000).% 绿色附魂系数 
-define(CONST_FURNACE_BLUE_SOUL_FACTOR,             15000).% 蓝色附魂系数 
-define(CONST_FURNACE_PURPLE_SOUL_FACTOR,           20000).% 紫色附魂系数 
-define(CONST_FURNACE_ORANGE_SOUL_FACTOR,           25000).% 橙色附魂系数 
-define(CONST_FURNACE_RED_SOUL_FACTOR,              30000).% 红色附魂系数 

-define(CONST_FURNACE_FASION_SOUL_MAX,              6).% 时装附魂上限 

-define(CONST_FURNACE_HOLE_STATE_EMPTY,             1).% 装备孔的状态-空的 
-define(CONST_FURNACE_HOLE_STATE_NULL,              2).% 装备孔的状态-未开启 
-define(CONST_FURNACE_HOLE_STATE_STONE,             3).% 装备孔的状态-镶有宝石 
-define(CONST_FURNACE_HOLE_STATE_NONE,              4).% 装备孔的状态-无法开启 

-define(CONST_FURNACE_STONE_COMPOSE_COUNT,          3).% 合成宝石所需数量 
-define(CONST_FURNACE_STONE_MAX_LEVEL,              9).% 宝石最大等级 

%% ==========================================================
%% 中心服状态
%% ==========================================================
-define(CONST_CENTER_STATE_NORMAL,                  0).% 状态--正常 
-define(CONST_CENTER_STATE_NOT_EXIST,               1).% 状态--不存在 
-define(CONST_CENTER_STATE_COMBINING,               2).% 状态--合服中 
-define(CONST_CENTER_STATE_NET,                     3).% 状态--网络问题 
-define(CONST_CENTER_STATE_UNKNOWN,                 4).% 状态--未知 
-define(CONST_CENTER_STATE_CLOSE,                   5).% 状态--关服 
-define(CONST_CENTER_MAX_COUNT,                     12).% 最大数量 

%% ==========================================================
%% 温泉
%% ==========================================================
-define(CONST_SPRING_PADDLE,                        1).% 温泉戏水 
-define(CONST_SPRING_RUBBING,                       2).% 温泉搓澡 
-define(CONST_SPRING_MASSAGE,                       3).% 温泉按摩 
-define(CONST_SPRING_INTERACT,                      5).% 温泉互动次数 
-define(CONST_SPRING_SP,                            10).% 基础体力值 
-define(CONST_SPRING_EXP_INTERVAL,                  30).% 获得经验时间间隔 
-define(CONST_SPRING_SP_LIMIT,                      30).% 温泉体力上限 
-define(CONST_SPRING_AUTO_COST,                     30).% 自动参加温泉消费 
-define(CONST_SPRING_INTERACT_EXP,                  500).% 互动经验基础值 
-define(CONST_SPRING_SP_INTERVAL,                   600).% 获得体力时间间隔 
-define(CONST_SPRING_INTERACT_FACTOR,               2000).% 互动好友系数（以10000为基数） 
-define(CONST_SPRING_ACTIVITY_INTERVAL,             3600).% 温泉活动时间间隔 
-define(CONST_SPRING_MAP_ID,                        31001).% 温泉地图ID 

-define(CONST_SPRING_SINGLE,                        0).% 温泉单修 
-define(CONST_SPRING_DOUBLE,                        1).% 温泉双修 

-define(CONST_SPRING_DOUBLE_NONE,                   0).% 温泉单修 
-define(CONST_SPRING_DOUBLE_FIRST,                  1).% 地上双修方式：曲水流觞 
-define(CONST_SPRING_DOUBLE_SECOND,                 2).% 水中、地上双修方式：天灯祈福 
-define(CONST_SPRING_DOUBLE_THIRD,                  3).% 水里双修方式：鸳鸯戏水 

%% ==========================================================
%% 消息系统
%% ==========================================================
-define(CONST_MESSAGE_AREA_CHAT,                    1).% 通知区域--聊天(1区) 
-define(CONST_MESSAGE_AREA_SPEAKER,                 2).% 通知区域--喇叭(2区) 
-define(CONST_MESSAGE_AREA_NOTICE,                  3).% 通知区域--公告(3区) 

-define(CONST_MESSAGE_SYSTEM_A,                     5).% 发送方式--系统消息--主窗口右下角 
-define(CONST_MESSAGE_PROMPT_A,                     6).% 发送方式--提示消息--主窗口下方居中 
-define(CONST_MESSAGE_FLOAT_A,                      11).% 发送方式--浮动型--偏上居中 
-define(CONST_MESSAGE_FLOAT_B,                      12).% 发送方式--浮动型--按钮附近 
-define(CONST_MESSAGE_POP_A,                        21).% 发送方式--弹窗型--居中功能开启 
-define(CONST_MESSAGE_POP_B,                        22).% 发送方式--弹窗型--居中信息提示 
-define(CONST_MESSAGE_POP_C,                        23).% 发送方式--弹窗型--右下角弹出框 
-define(CONST_MESSAGE_FLUTTER_A,                    31).% 发送方式--飘窗型--公告 
-define(CONST_MESSAGE_FLUTTER_B,                    32).% 发送方式--飘窗型--提示 
-define(CONST_MESSAGE_FLUTTER_C,                    33).% 发送方式--飘窗型--滚动显示 
-define(CONST_MESSAGE_DRAMA_A,                      81).% 发送方式--剧情消息--任务简述 
-define(CONST_MESSAGE_DRAMA_B,                      82).% 发送方式--剧情消息--剧情展示 

-define(CONST_MESSAGE_TIP_SYS_TASK,                 1).% TIPS--任务 
-define(CONST_MESSAGE_TIP_SYS_SKILL,                2).% TIPS--技能 
-define(CONST_MESSAGE_TIP_SYS_MIND,                 3).% TIPS--心法 
-define(CONST_MESSAGE_TIP_SYS_PARTNER,              4).% TIPS--武将 
-define(CONST_MESSAGE_TIP_SYS_ABILITY,              5).% TIPS--内功 
-define(CONST_MESSAGE_TIP_SYS_MONSTER,              6).% TIPS--怪物 
-define(CONST_MESSAGE_TIP_SYS_ACHI_GIFT,            7).% TIPS--成就礼品 
-define(CONST_MESSAGE_TIP_SYS_OPEN_PANEL,           8).% TIPS-打开面板 
-define(CONST_MESSAGE_EQUIP,                        9).% TIPS-装备 
-define(CONST_MESSAGE_TIP_MCOPY,                    10).% TIPS-多人副本 
-define(CONST_MESSAGE_NOT_EQUIP,                    11).% TIPS-非装备 
-define(CONST_MESSAGE_TIPS_SYS_TOWER,               12).% TIPS--破阵 
-define(CONST_MESSAGE_TIP_SYS_ACTIVE,               14).% TIPS--活动 
-define(CONST_MESSAGE_TIP_SYS_COMM,                 100).% TIPS--通用消息 

%% ==========================================================
%% GM
%% ==========================================================
-define(CONST_GM_SET_LEVEL,                         1).% 设置等级（可以随意设置到某一个等级） 
-define(CONST_GM_PLUS_MONEY,                        2).% 增加金钱（元宝、铜钱） 
-define(CONST_GM_MINUS_MONEY,                       3).% 减少金钱（元宝、铜钱） 
-define(CONST_GM_PLUS_GOODS,                        4).% 增加物品（物品ID、数量） 
-define(CONST_GM_SET_SPIRIT,                        5).% 设置灵力 
-define(CONST_GM_SET_EXPERIENCE,                    6).% 设置军功 
-define(CONST_GM_SET_GUILD_DONATE,                  7).% 设置军团贡献 
-define(CONST_GM_SET_BAG,                           8).% 快速填充背包 
-define(CONST_GM_CLEAR_BAG,                         9).% 清空背包 
-define(CONST_GM_SET_DEPOT,                         10).% 快速填充仓库 
-define(CONST_GM_CLEAR_DEPOT,                       11).% 清空仓库 
-define(CONST_GM_RESET_ACTIVITY,                    12).% 重置活动次数（活动key、次数） 
-define(CONST_GM_SET_EQUIP_LEVEL,                   13).% 设置装备等级 
-define(CONST_GM_SET_EQUIP_ATTR,                    14).% 设置装备属性（附魂、洗练） 
-define(CONST_GM_UNLIMIT_PARTER,                    15).% 解除雇佣武将限制 
-define(CONST_GM_RESET_TASK,                        16).% 清除已完成任务（特定任务ID） 
-define(CONST_GM_COMPLETE_TASK,                     17).% 完成到某个任务 
-define(CONST_GM_SET_SP,                            18).% 设置体力值 
-define(CONST_GM_CLEAR_CD,                          19).% 清除CD 
-define(CONST_GM_RESET_SKILL,                       20).% 技能重置命令 
-define(CONST_GM_RESET_ATTR,                        21).% 属性重置命令 
-define(CONST_GM_STUDY_SKILL,                       22).% 技能学习命令 
-define(CONST_GM_PLUS_ATTR,                         23).% 属性加点命令 
-define(CONST_GM_SET_SKILL_CD,                      24).% 设置技能CD 
-define(CONST_GM_SET_ONLINE_DURATION,               25).% 设置在线时长 
-define(CONST_GM_SET_VIP_GROWTH,                    26).% 设置VIP成长值 
-define(CONST_GM_REFRESH_MONSTER,                   27).% 刷怪（当前场景输出特定ID怪物） 
-define(CONST_GM_INNER_PAYMENT,                     28).% 内网充值入口 

-define(CONST_GM_OK,                                0).% 0成功 
-define(CONST_GM_ERROR,                             1).% 1失败1 
-define(CONST_GM_IP_FAIL,                           2).% IP不被允许 
-define(CONST_GM_KEY_FAIL,                          3).% KEY校验失败 

%% ==========================================================
%% 阵法
%% ==========================================================
-define(CONST_CAMP_TYPE_PLAYER,                     1).% 玩家 
-define(CONST_CAMP_TYPE_PARTNER,                    2).% 伙伴 

-define(CONST_CAMP_DEFAULT,                         1).% 默认阵法1 

-define(CONST_CAMP_SET_POS_TYPE_1,                  1).% 上阵类型--布阵界面上阵 
-define(CONST_CAMP_SET_POS_TYPE_2,                  2).% 上阵类型--副将界面上阵 

-define(CONST_CAMP_YULIN,                           2).% 鱼鳞阵 
-define(CONST_CAMP_YULIN_LV,                        5).% 鱼鳞阵等级 

-define(CONST_CAMP_CAMP_BOOK_CASH,                  100).% 阵法书元宝数 

%% ==========================================================
%% BUFF
%% ==========================================================
-define(CONST_BUFF_EXPEND_TYPE_TIME,                1).% BUFF消耗类型--时间（秒） 
-define(CONST_BUFF_EXPEND_TYPE_BOUT,                2).% BUFF消耗类型--回合 

-define(CONST_BUFF_CALC_TYPE_PLUS,                  1).% BUFF计算类型--加 
-define(CONST_BUFF_CALC_TYPE_MINUS,                 2).% BUFF计算类型--减 

-define(CONST_BUFF_TRIGGER_NORMAL,                  1).% BUFF触发--默认 
-define(CONST_BUFF_TRIGGER_BOUT,                    2).% BUFF触发--回合 
-define(CONST_BUFF_TRIGGER_ATK,                     3).% BUFF触发--攻击 
-define(CONST_BUFF_TRIGGER_DEF,                     4).% BUFF触发--防守 
-define(CONST_BUFF_TRIGGER_CURE,                    5).% BUFF触发--治疗 
-define(CONST_BUFF_TRIGGER_PLUS_ANGER,              6).% BUFF触发--增加怒气 
-define(CONST_BUFF_TRIGGER_MINUS_ANGER,             7).% BUFF触发--减少怒气 
-define(CONST_BUFF_TRIGGER_BUFF,                    8).% BUFF触发--BUFF 

-define(CONST_BUFF_RELATION_PLUS,                   1).% 同类型BUFF关系--叠加 
-define(CONST_BUFF_RELATION_REPLACE,                2).% 同类型BUFF关系--替换 
-define(CONST_BUFF_RELATION_COEXIST,                3).% 同类型BUFF关系--共存 
-define(CONST_BUFF_RELATION_MUTEX,                  4).% 同类型BUFF关系--互斥 

-define(CONST_BUFF_SOURCE_GOODS,                    1).% BUFF来源--物品 
-define(CONST_BUFF_SOURCE_ACTIVITY,                 2).% BUFF来源--活动 
-define(CONST_BUFF_SOURCE_SKILL,                    3).% BUFF来源--技能 

-define(CONST_BUFF_CHANGE_TYPE_INSERT,              1).% BUFF改变类型--插入 
-define(CONST_BUFF_CHANGE_TYPE_DELETE,              2).% BUFF改变类型--删除 

-define(CONST_BUFF_INSTALL_POINT_DEFAULT,           0).% BUFF安装点--默认 
-define(CONST_BUFF_INSTALL_POINT_BOUT,              1).% BUFF安装点--回合 

-define(CONST_BUFF_TYPE_1,                          1).% BUFF类型--增加X%生命上限持续N回合 
-define(CONST_BUFF_TYPE_2,                          2).% BUFF类型--增加X%攻击力持续N回合 
-define(CONST_BUFF_TYPE_3,                          3).% BUFF类型--增加X%物理攻击力持续N回合 
-define(CONST_BUFF_TYPE_4,                          4).% BUFF类型--增加X%法术攻击力持续N回合 
-define(CONST_BUFF_TYPE_5,                          5).% BUFF类型--增加X%防御力持续N回合 
-define(CONST_BUFF_TYPE_6,                          6).% BUFF类型--增加X%物理防御力持续N回合 
-define(CONST_BUFF_TYPE_7,                          7).% BUFF类型--增加X%法术防御力持续N回合 
-define(CONST_BUFF_TYPE_8,                          8).% BUFF类型--增加X%速度持续N回合 
-define(CONST_BUFF_TYPE_9,                          9).% BUFF类型--物理攻击力转换气血 
-define(CONST_BUFF_TYPE_10,                         10).% BUFF类型--法术攻击力转换气血 
-define(CONST_BUFF_TYPE_11,                         11).% BUFF类型--降低X%生命上限持续N回合 
-define(CONST_BUFF_TYPE_12,                         12).% BUFF类型--降低X%攻击力持续N回合 
-define(CONST_BUFF_TYPE_13,                         13).% BUFF类型--降低X%物理攻击力持续N回合 
-define(CONST_BUFF_TYPE_14,                         14).% BUFF类型--降低X%法术攻击力持续N回合 
-define(CONST_BUFF_TYPE_15,                         15).% BUFF类型--降低X%防御力持续N回合 
-define(CONST_BUFF_TYPE_16,                         16).% BUFF类型--降低X%物理防御力持续N回合 
-define(CONST_BUFF_TYPE_17,                         17).% BUFF类型--降低X%法术防御力持续N回合 
-define(CONST_BUFF_TYPE_18,                         18).% BUFF类型--降低X%速度持续N回合 
-define(CONST_BUFF_TYPE_19,                         19).% BUFF类型--物理攻击力转换气血 
-define(CONST_BUFF_TYPE_20,                         20).% BUFF类型--法术攻击力转换气血 
-define(CONST_BUFF_TYPE_21,                         21).% BUFF类型--增加X%命中持续N回合 
-define(CONST_BUFF_TYPE_22,                         22).% BUFF类型--增加X%闪避持续N回合 
-define(CONST_BUFF_TYPE_23,                         23).% BUFF类型--增加X%暴击持续N回合 
-define(CONST_BUFF_TYPE_24,                         24).% BUFF类型--增加X%招架持续N回合 
-define(CONST_BUFF_TYPE_25,                         25).% BUFF类型--增加X%反击持续N回合 
-define(CONST_BUFF_TYPE_26,                         26).% BUFF类型--增加X%降低暴击持续N回合 
-define(CONST_BUFF_TYPE_27,                         27).% BUFF类型--增加暴击伤害 
-define(CONST_BUFF_TYPE_31,                         31).% BUFF类型--降低X%命中持续N回合 
-define(CONST_BUFF_TYPE_32,                         32).% BUFF类型--降低X%闪避持续N回合 
-define(CONST_BUFF_TYPE_33,                         33).% BUFF类型--降低X%暴击持续N回合 
-define(CONST_BUFF_TYPE_34,                         34).% BUFF类型--降低X%招架持续N回合 
-define(CONST_BUFF_TYPE_35,                         35).% BUFF类型--降低X%反击持续N回合 
-define(CONST_BUFF_TYPE_36,                         36).% BUFF类型--降低X%降低暴击持续N回合 
-define(CONST_BUFF_TYPE_41,                         41).% BUFF类型--增加X%治疗效果持续N回合 
-define(CONST_BUFF_TYPE_42,                         42).% BUFF类型--增加X%怒气恢复效果持续N回合 
-define(CONST_BUFF_TYPE_43,                         43).% BUFF类型--增加X点生命持续N回合 
-define(CONST_BUFF_TYPE_44,                         44).% BUFF类型--增加X%生命持续N回合 
-define(CONST_BUFF_TYPE_45,                         45).% BUFF类型--降低暴击伤害 
-define(CONST_BUFF_TYPE_51,                         51).% BUFF类型--降低X%治疗效果持续N回合 
-define(CONST_BUFF_TYPE_52,                         52).% BUFF类型--降低X%怒气恢复效果持续N回合 
-define(CONST_BUFF_TYPE_53,                         53).% BUFF类型--降低X点生命持续N回合(中毒) 
-define(CONST_BUFF_TYPE_54,                         54).% BUFF类型--降低X点生命持续N回合(中毒) BOSS免疫 
-define(CONST_BUFF_TYPE_55,                         55).% BUFF类型--降低Y点生命N回合(燃烧) 
-define(CONST_BUFF_TYPE_61,                         61).% BUFF类型--附加沉默持续N回合 
-define(CONST_BUFF_TYPE_62,                         62).% BUFF类型--附加封印持续N回合 
-define(CONST_BUFF_TYPE_63,                         63).% BUFF类型--附加眩晕持续N回合 
-define(CONST_BUFF_TYPE_71,                         71).% BUFF类型--附加免疫沉默持续N回合 
-define(CONST_BUFF_TYPE_72,                         72).% BUFF类型--附加免疫封印持续N回合 
-define(CONST_BUFF_TYPE_73,                         73).% BUFF类型--附加免疫眩晕持续N回合 
-define(CONST_BUFF_TYPE_74,                         74).% BUFF类型--附加免疫控制持续N回合 
-define(CONST_BUFF_TYPE_75,                         75).% BUFF类型--附加免疫惊鸿控制持续N回合 
-define(CONST_BUFF_TYPE_81,                         81).% BUFF类型--附加无敌效果持续N回合 
-define(CONST_BUFF_TYPE_82,                         82).% BUFF类型--附加X%吸血效果持续N回合 
-define(CONST_BUFF_TYPE_91,                         91).% BUFF类型--附加免疫DEBUFF持续N回合 
-define(CONST_BUFF_TYPE_92,                         92).% BUFF类型--附加N回合后必然暴击 
-define(CONST_BUFF_TYPE_93,                         93).% BUFF类型--附加免疫暴击持续N回合 
-define(CONST_BUFF_TYPE_94,                         94).% BUFF类型--附加暴击无效持续N回合 
-define(CONST_BUFF_TYPE_101,                        101).% BUFF类型--附加无视防御力持续N回合 
-define(CONST_BUFF_TYPE_102,                        102).% BUFF类型--附加无视物理防御力持续N回合 
-define(CONST_BUFF_TYPE_103,                        103).% BUFF类型--附加无视法术防御力持续N回合 
-define(CONST_BUFF_TYPE_201,                        201).% BUFF类型--增加X%生命上限 
-define(CONST_BUFF_TYPE_202,                        202).% BUFF类型--增加X%物理攻击力 
-define(CONST_BUFF_TYPE_203,                        203).% BUFF类型--增加X%法术攻击力 
-define(CONST_BUFF_TYPE_204,                        204).% BUFF类型--增加X%速度 
-define(CONST_BUFF_TYPE_205,                        205).% BUFF类型--增加X%暴击率 
-define(CONST_BUFF_TYPE_206,                        206).% BUFF类型--增加X%反击率 
-define(CONST_BUFF_TYPE_207,                        207).% BUFF类型--增加X%格挡率 
-define(CONST_BUFF_TYPE_208,                        208).% BUFF类型--增加物攻（将魂） 
-define(CONST_BUFF_TYPE_209,                        209).% BUFF类型--增加术攻（将魂） 
-define(CONST_BUFF_TYPE_210,                        210).% BUFF类型--增加气血（将魂） 
-define(CONST_BUFF_TYPE_211,                        211).% BUFF类型--增加物攻和术攻（将魂） 

-define(CONST_BUFF_NATURE_POSITIVE,                 1).% BUFF性质--积极 
-define(CONST_BUFF_NATURE_NEGATIVE,                 2).% BUFF性质--消极 

%% ==========================================================
%% 商路
%% ==========================================================
-define(CONST_COMMERCE_ESCORT_MAXIMUM,              2).% 每天协助好友护送次数 
-define(CONST_COMMERCE_REFRESH_CASHCOST,            2).% 刷新花费元宝基数 
-define(CONST_COMMERCE_ROBBED_MAXIMUM,              2).% 商队被拦截次数 
-define(CONST_COMMERCE_CARRY_MAXIMUM,               3).% 每天运送次数 
-define(CONST_COMMERCE_FREEREFRESH_MAXIMUM,         3).% 每天免费刷新次数 
-define(CONST_COMMERCE_ROB_MAXIMUM,                 4).% 每天拦截次数 
-define(CONST_COMMERCE_FUNCTION_ON_LV,              27).% 商路功能开启级数 
-define(CONST_COMMERCE_INVITE_TIME,                 30).% 发出邀请超时时间 
-define(CONST_COMMERCE_CARRY_TIME,                  30).% 同意护送超时时间 
-define(CONST_COMMERCE_ROB_CD_TIME,                 60).% 拦截冷却时间 

-define(CONST_COMMERCE_GREEN_CARAVAN,               1).% 绿色商队 
-define(CONST_COMMERCE_BLUE_CARAVAN,                2).% 蓝色商队 
-define(CONST_COMMERCE_PURPLE_CARAVAN,              3).% 紫色商队 
-define(CONST_COMMERCE_ORANGE_CARAVAN,              4).% 橙色商队 
-define(CONST_COMMERCE_RED_CARAVAN,                 5).% 红色商队 

-define(CONST_COMMERCE_NO_BONUS,                    1).% 无加成 
-define(CONST_COMMERCE_GUILD_BONUS,                 2).% 军团加成 
-define(CONST_COMMERCE_MARKET_BONUS,                2).% 市场加成 

-define(CONST_COMMERCE_REPLY_ACCEPT,                0).% 好友回复同意 
-define(CONST_COMMERCE_REPLY_REJECT,                1).% 好友回复拒绝 
-define(CONST_COMMERCE_REPLY_TIMEOUT,               2).% 好友回复超时 

-define(CONST_COMMERCE_CARRY_IDLE,                  0).% 运送状态：空闲 
-define(CONST_COMMERCE_CARRY_WAIT,                  1).% 运送状态：等待好友回复 
-define(CONST_COMMERCE_CARRY_RECEIVE,               2).% 运送状态：好友回复同意 
-define(CONST_COMMERCE_CARRY_ING,                   3).% 运送状态：运镖中 

-define(CONST_COMMERCE_ESCORT_IDLE,                 0).% 护送状态：空闲 
-define(CONST_COMMERCE_ESCORT_RECEIVE,              1).% 护送状态：收到好友请求 
-define(CONST_COMMERCE_ESCORT_REPLY,                2).% 护送状态：同意好友 
-define(CONST_COMMERCE_ESCORT_ING,                  3).% 运送状态：护送中 

-define(CONST_COMMERCE_FRIEND_INVITING,             0).% 好友关系：邀请中 
-define(CONST_COMMERCE_FRIEND_ACCEPT,               1).% 好友关系：同意 
-define(CONST_COMMERCE_FRIEND_REJECT,               2).% 好友关系：拒绝 

-define(CONST_COMMERCE_IDLE,                        0).% 运送状态：空闲 
-define(CONST_COMMERCE_BATTLING,                    1).% 运送状态：战斗中 
-define(CONST_COMMERCE_DELAY,                       2).% 运送状态：延迟 

-define(CONST_COMMERCE_CARRY,                       1).% 离线类型：跑商 
-define(CONST_COMMERCE_ESCORT_START,                2).% 离线类型：护送开始 
-define(CONST_COMMERCE_ESCORT_OVER,                 3).% 离线类型：护送结束 
-define(CONST_COMMERCE_ROB,                         4).% 离线类型：拦截 

-define(CONST_COMMERCE_BUY_ROB_TIMES,               5).% 商路花费：购买拦截次数（前端） 
-define(CONST_COMMERCE_SINGLE_REFRESH,              5).% 商路花费：单次刷新（前端） 
-define(CONST_COMMERCE_ROB_CD,                      10).% 商路花费：清除拦截CD时间（前端） 
-define(CONST_COMMERCE_ONE_KEY_CARRY,               20).% 商路花费：一键运送（前端） 
-define(CONST_COMMERCE_ONE_KEY_REFRESH,             100).% 商路花费：一键刷新（前端） 
-define(CONST_COMMERCE_MARKET_TIME,                 300).% 市场持续时间 
-define(CONST_COMMERCE_BUILD_MARKET,                3000).% 商路花费：建造市场（前端） 

-define(CONST_COMMERCE_KEY_ROB_CD,                  1).% 商路花费：清除拦截CD时间（后端） 
-define(CONST_COMMERCE_KEY_BUY_ROB_TIMES,           2).% 商路花费：购买拦截次数（后端） 
-define(CONST_COMMERCE_KEY_SINGLE_REFRESH,          3).% 商路花费：单次刷新（后端） 
-define(CONST_COMMERCE_KEY_ONE_KEY_REFRESH,         4).% 商路花费：一键刷新（后端） 
-define(CONST_COMMERCE_KEY_ONE_KEY_CARRY,           5).% 商路花费：一键运送（后端） 
-define(CONST_COMMERCE_KEY_BUILD_MARKET,            6).% 商路花费：建造市场（后端） 

-define(CONST_COMMERCE_LV_DIFF,                     14).% 商路抢劫等级差 

%% ==========================================================
%% 一骑讨
%% ==========================================================
-define(CONST_SINGLE_ARENA_STREAK_WIN_AWARD_LIST,   [2,5,10,15,25]).% 需要奖励的连胜次数 
-define(CONST_SINGLE_ARENA_STATE_OFF,               0).% 竞技场界面状态-关闭 
-define(CONST_SINGLE_ARENA_WIN,                     1).% 胜利 
-define(CONST_SINGLE_ARENA_ATTACK,                  1).% 挑战 
-define(CONST_SINGLE_ARENA_STATE_ON,                1).% 竞技场界面状态-开启 
-define(CONST_SINGLE_ARENA_CASH_PER_MIN,            1).% 清除CD时每分钟的元宝消耗 
-define(CONST_SINGLE_ARENA_LOSE,                    2).% 失败 
-define(CONST_SINGLE_ARENA_DEF,                     2).% 被挑战 
-define(CONST_SINGLE_ARENA_TOP_RANK,                3).% 英雄榜展示玩家个数 
-define(CONST_SINGLE_ARENA_CHALLENGE_NUM,           4).% 可挑战玩家数量 
-define(CONST_SINGLE_ARENA_REPORT_MAX,              5).% 玩家保存战报上限 
-define(CONST_SINGLE_ARENA_STREAK_AWARD_MAX,        6).% 连胜奖励规则个数 
-define(CONST_SINGLE_ARENA_DEFAULT_DAILY_TIMES,     15).% 每天默认可挑战次数 
-define(CONST_SINGLE_ARENA_RANK_REWARD_TIME,        20).% 领取排行奖励的时间(20:00) 
-define(CONST_SINGLE_ARENA_RANK_AWARD_MAX,          28).% 排名奖励规则个数 
-define(CONST_SINGLE_ARENA_AUTO_RANK_LV,            30).% 自动晋级等级 
-define(CONST_SINGLE_ARENA_CD,                      600).% 冷却时间 
-define(CONST_SINGLE_ARENA_REPORT_DEADLINE,         259200).% 战报保存期限(秒) 

-define(CONST_SINGLE_ARENA_STREAK_AWARD,            1).% 奖励类型：连胜 
-define(CONST_SINGLE_ARENA_RANK_AWARD,              2).% 奖励类型：排名 
-define(CONST_SINGLE_ARENA_CHALLENGE_AWARD,         3).% 奖励类型：单场挑战 

-define(CONST_SINGLE_ARENA_OK,                      0).% 成功 
-define(CONST_SINGLE_ARENA_ERROR,                   1).% 失败(系统错误) 
-define(CONST_SINGLE_ARENA_CASH_ERROR,              2).% 元宝不足 

-define(CONST_SINGLE_ARENA_RANKUP,                  1).% 趋势：排名上升 
-define(CONST_SINGLE_ARENA_RANKDOWN,                2).% 趋势：排名下降 
-define(CONST_SINGLE_ARENA_RANKSTAY,                3).% 趋势：排名不变 

-define(CONST_SINGLE_ARENA_STATE_NOT_ARRIVE,        0).% 奖励状态--未达成 
-define(CONST_SINGLE_ARENA_STATE_CAN_GET,           1).% 奖励状态--可领取 
-define(CONST_SINGLE_ARENA_STATE_GOT,               2).% 奖励状态--已领取 

-define(CONST_SINGLE_ARENA_REWARD_BCASH,            20).% 每日目标奖励--礼券 
-define(CONST_SINGLE_ARENA_REWARD_BGOLD,            100000).% 每日目标奖励--铜钱 

%% ==========================================================
%% 闯塔
%% ==========================================================
-define(CONST_TOWER_CAMP_COUNT,                     20).% 大阵总数 
-define(CONST_TOWER_OPEN_TOWER_LV,                  23).% 开启闯塔等级限制 
-define(CONST_TOWER_PASS_COUNT,                     200).% 关卡总数 

-define(CONST_TOWER_ELITE_MONSTER,                  1).% 精英怪关卡 
-define(CONST_TOWER_BIG_MONSTER,                    2).% 强boss关卡 
-define(CONST_TOWER_SMALL_MONSTER,                  3).% 弱boss关卡 

-define(CONST_TOWER_VIP_REWARD,                     10).% VIP额外翻牌 
-define(CONST_TOWER_RESET_COST,                     200).% 重置消耗 

-define(CONST_TOWER_SPEED_SWEEP1,                   30).% 快速扫荡(分钟) 
-define(CONST_TOWER_SPEED_SWEEP2,                   60).% 快速扫荡(分钟) 

-define(CONST_TOWER_REPORT_COUNT,                   5).% 每阵战报数量上限 

-define(CONST_TOWER_INTERVAL_TIME,                  14400000).% 同步战报数据时间间隔 

%% ==========================================================
%% 单人副本
%% ==========================================================
-define(CONST_COPY_SINGLE_SP_A_WAVE,                5).% 每波怪扫荡消耗体力 
-define(CONST_COPY_SINGLE_TIME_A_WAVE,              60).% 每波怪模拟扫荡时间 

-define(CONST_COPY_SINGLE_EQ_B_LOW,                 60).% 评价B下限 
-define(CONST_COPY_SINGLE_EQ_A_LOW,                 75).% 评价a下限 
-define(CONST_COPY_SINGLE_EQ_S_LOW,                 90).% 评价s下限 
-define(CONST_COPY_SINGLE_EQ_SS_LOW,                105).% 评价ss下限 
-define(CONST_COPY_SINGLE_EQ_SSS_LOW,               120).% 评价sss下限 

-define(CONST_COPY_SINGLE_EQ_B,                     1).% b 
-define(CONST_COPY_SINGLE_EQ_A,                     2).% a 
-define(CONST_COPY_SINGLE_EQ_S,                     3).% s 
-define(CONST_COPY_SINGLE_EQ_SS,                    4).% ss 
-define(CONST_COPY_SINGLE_EQ_SSS,                   5).% sss 

-define(CONST_COPY_SINGLE_ELITE_MONEY,              5).% 精英副本翻牌的元宝数 

-define(CONST_COPY_SINGLE_QUICK_30,                 1).% 加速30分钟 
-define(CONST_COPY_SINGLE_QUICK_60,                 2).% 加速60分钟 
-define(CONST_COPY_SINGLE_QUICK_0,                  3).% 立即完成 

-define(CONST_COPY_SINGLE_PROCESS_PRE_WAVE_1,       0).% 第1波怪前 
-define(CONST_COPY_SINGLE_PROCESS_WAVE_1,           1).% 第1波怪 
-define(CONST_COPY_SINGLE_PROCESS_WAVE_2,           2).% 第2波怪 
-define(CONST_COPY_SINGLE_PROCESS_WAVE_3,           3).% 第3波怪 
-define(CONST_COPY_SINGLE_PROCESS_AFTER_WAVE_3,     4).% 第3波怪后 

-define(CONST_COPY_SINGLE_QUICK_TIME_0,             0).% 立即完成 
-define(CONST_COPY_SINGLE_QUICK_TIME_30,            1800).% 加速30分钟 
-define(CONST_COPY_SINGLE_QUICK_TIME_60,            3600).% 加速60分钟 

-define(CONST_COPY_SINGLE_BAG_MIN,                  5).% 最小背包空位数 

-define(CONST_COPY_SINGLE_IS_CLOSE_PLOT,            0).% 0不关，1关剧情 
-define(CONST_COPY_SINGLE_IS_REOPEN_PLOT,           0).% 0不重开，1重开 

%% ==========================================================
%% 多人组队
%% ==========================================================
-define(CONST_TEAM_MIN_ROOM_ID,                     1).% 最小房间号 
-define(CONST_TEAM_INCR_ROOM_ID,                    1).% 房间号步长 
-define(CONST_TEAM_MAX_MEMBER,                      3).% 队伍最大人数 
-define(CONST_TEAM_MIN_CAMP_LV,                     3).% 最低阵法等级 
-define(CONST_TEAM_MAX_ROOM_ID,                     999).% 最大房间号 
-define(CONST_TEAM_TIMEOUT,                         36000000).% 组队进程超时时间(毫秒：36000000) 

-define(CONST_TEAM_NO_TEAM,                         0).% 不在队伍中 
-define(CONST_TEAM_IN_TEAM,                         1).% 在队伍中 

-define(CONST_TEAM_OPERATE_MODE_LEADER,             1).% 队伍操作模式--队长操作 
-define(CONST_TEAM_OPERATE_MODE_MEMBER,             2).% 队伍操作模式--成员操作 

-define(CONST_TEAM_QUIT_TO_NORMAL,                  0).% 退出玩法到--正常 
-define(CONST_TEAM_QUIT_TO_HALL,                    1).% 退出玩法到--大厅 
-define(CONST_TEAM_QUIT_TO_TEAM,                    2).% 退出玩法到--组队界面 

-define(CONST_TEAM_REQ_GUILD,                       1).% 请求军团 
-define(CONST_TEAM_REQ_FRIEND,                      2).% 请求好友 

-define(CONST_TEAM_REPLY_AGREE,                     1).% 邀请恢复选项--同意 
-define(CONST_TEAM_REPLY_REJECT,                    2).% 邀请恢复选项--拒绝 
-define(CONST_TEAM_REPLY_TIMEOUT,                   3).% 邀请恢复选项--超时 

-define(CONST_TEAM_TYPE_COPY,                       1).% 组队类型--多人副本 
-define(CONST_TEAM_TYPE_INVASION,                   2).% 组队类型--异民族 
-define(CONST_TEAM_TYPE_ARENA,                      3).% 组队类型--多人竞技场 
-define(CONST_TEAM_TYPE_CAMP_PVP,                   4).% 组队类型--阵营战 

-define(CONST_TEAM_STATE_WAIT,                      1).% 组队状态--等待 
-define(CONST_TEAM_STATE_START,                     2).% 组队状态--开始 
-define(CONST_TEAM_STATE_OTHER,                     3).% 组队状态--其他 

-define(CONST_TEAM_PLAYER_STATE_WAIT,               1).% 队伍角色状态--等待 
-define(CONST_TEAM_PLAYER_STATE_READY,              2).% 队伍角色状态--准备 
-define(CONST_TEAM_PLAYER_STATE_PLAY_START,         3).% 队伍角色状态--玩法开始 
-define(CONST_TEAM_PLAYER_STATE_PLAY_OVER,          4).% 队伍角色状态--玩法结束 

-define(CONST_TEAM_CHECK_CREATE,                    1).% 组队检查类型--创建 
-define(CONST_TEAM_CHECK_INVITE,                    2).% 组队检查类型--邀请 
-define(CONST_TEAM_CHECK_JOIN,                      3).% 组队检查类型--加入 
-define(CONST_TEAM_CHECK_REPLY_JOIN,                4).% 组队检查类型--回复加入 

-define(CONST_TEAM_NOT_AUTHOR,                      0).% 替身类型-非替身 
-define(CONST_TEAM_NORMAL_AUTHOR,                   1).% 替身类型-授权替身 
-define(CONST_TEAM_GOLD_AUTHOR,                     2).% 替身类型-元宝替身 

%% ==========================================================
%% 活动
%% ==========================================================
-define(CONST_ACTIVE_SPRING,                        1).% 温泉1 
-define(CONST_ACTIVE_SPRING2,                       2).% 温泉2 
-define(CONST_ACTIVE_BOSS1,                         3).% 世界boss1 
-define(CONST_ACTIVE_BOSS2,                         4).% 世界boos2 
-define(CONST_ACTIVE_FACTION,                       5).% 阵营战 
-define(CONST_ACTIVE_WORLD,                         6).% 乱天下 
-define(CONST_ACTIVE_ARENA_PVP,                     7).% 战群雄 
-define(CONST_ACTIVE_COMMERCE,                      8).% 军团商路 
-define(CONST_ACTIVE_INVASION,                      9).% 异民族1 
-define(CONST_ACTIVE_BOSS3,                         10).% 世界boss3 
-define(CONST_ACTIVE_BOSS4,                         11).% 世界boss4 
-define(CONST_ACTIVE_TYPE_PARTY,                    12).% 军团宴会1 
-define(CONST_ACTIVE_TYPE_PARTY2,                   13).% 军团宴会2 
-define(CONST_ACTIVE_INVASION2,                     14).% 异民族2 
-define(CONST_ACTIVE_CAMP_PVP,                      15).% 阵营战 
-define(CONST_ACTIVE_GUILD_PVP,                     16).% 军团战 
-define(CONST_ACTIVE_GUILD_PVP_APP,                 17).% 军团战报名截止 
-define(CONST_ACTIVE_MCOPY,                         18).% 团队战场 

-define(CONST_ACTIVE_GUILD_SIEGE_NAME,              guild_siege).% 怪物攻城活动名称 
-define(CONST_ACTIVE_SPRING_NAME,                   spring).% 温泉活动名称 

-define(CONST_ACTIVE_BEGIN,                         active_begin).% 活动开启 
-define(CONST_ACTIVE_END,                           active_end).% 活动结束 

-define(CONST_ACTIVE_MAX_WEEK,                      7).% 周 
-define(CONST_ACTIVE_MONTH,                         12).% 月 
-define(CONST_ACTIVE_MAX_HOUR,                      24).% 时 
-define(CONST_ACTIVE_DAY,                           31).% 天 
-define(CONST_ACTIVE_MAX_SECOND,                    60).% 秒 
-define(CONST_ACTIVE_MAX_MINUTE,                    60).% 分 

-define(CONST_ACTIVE_CURRENT,                       current).% 当前 
-define(CONST_ACTIVE_NEXT,                          next).% 下次 

-define(CONST_ACTIVE_STATE_OFF,                     0).% 状态--结束状态 
-define(CONST_ACTIVE_STATE_PRE_0,                   1).% 状态--准备0(提前15分钟) 
-define(CONST_ACTIVE_STATE_PRE_1,                   2).% 状态--准备1(提前10分钟) 
-define(CONST_ACTIVE_STATE_PRE_2,                   3).% 状态--准备2(提前5分钟) 
-define(CONST_ACTIVE_STATE_PRE_3,                   4).% 状态--准备3(提前1分钟) 
-define(CONST_ACTIVE_STATE_ON,                      5).% 状态--开始 

-define(CONST_ACTIVE_PRE_TIME_1,                    1).% 活动通知--1分钟 
-define(CONST_ACTIVE_PRE_TIME_5,                    5).% 活动通知--5分钟 
-define(CONST_ACTIVE_PRE_TIME_10,                   10).% 活动通知--10分钟 
-define(CONST_ACTIVE_PRE_TIME_15,                   15).% 活动通知--15分钟 

%% ==========================================================
%% 福利
%% ==========================================================
-define(CONST_WELFARE_WEEK2DAY,                     7).% 星期转换天 
-define(CONST_WELFARE_DAY2HOUR,                     24).% 天转换小时 
-define(CONST_WELFARE_MINUTE2SECOND,                60).% 分钟转换秒 
-define(CONST_WELFARE_HOUR2MINUTE,                  60).% 小时转换分钟 

-define(CONST_WELFARE_OTHET,                        0).% 重置条件：其他 
-define(CONST_WELFARE_DAILY,                        1).% 重置条件：每天 
-define(CONST_WELFARE_WEEKLY,                       2).% 重置条件：每周 
-define(CONST_WELFARE_MONTHLY,                      3).% 重置条件：每月 
-define(CONST_WELFARE_SERIES,                       4).% 重置条件：连续 

-define(CONST_WELFARE_NULL,                         0).% 空礼包 
-define(CONST_WELFARE_CONTINUOUS,                   1).% 连续在线礼包 
-define(CONST_WELFARE_OFFLINE,                      2).% 离线奖励 
-define(CONST_WELFARE_LOGIN,                        3).% 连续登陆礼包 
-define(CONST_WELFARE_FIRST_DEPOSIT,                4).% 充值福利：首充 
-define(CONST_WELFARE_SINGLE_DEPOSIT,               5).% 充值福利：单笔充值 
-define(CONST_WELFARE_ACCUM_DEPOSIT,                6).% 充值福利：累计充值 
-define(CONST_WELFARE_VIP_DAILY,                    7).% 每日VIP福利 
-define(CONST_WELFARE_VIP_LEVEL,                    8).% 等级VIP福利 
-define(CONST_WELFARE_NOVICE,                       9).% 新手礼包 
-define(CONST_WELFARE_LEVELUP,                      10).% 成长礼包 
-define(CONST_WELFARE_GIFT_COLLECT,                 11).% 收藏礼包 
-define(CONST_WELFARE_GIFT_PHONE,                   12).% 手机收藏礼包 
-define(CONST_WELFARE_REFIGHT_BATTLEFIELD,          13).% 再战沙场礼包 

-define(CONST_WELFARE_UNFIT,                        0).% 礼包状态：未生效 
-define(CONST_WELFARE_UNCLAIMED,                    1).% 礼包状态：未领取 
-define(CONST_WELFARE_RECEIVED,                     2).% 礼包状态：已领取 
-define(CONST_WELFARE_DEFUNCT,                      3).% 礼包状态：已失效 

-define(CONST_WELFARE_BATTLE,                       1).% 体验战斗 
-define(CONST_WELFARE_STRENGTH,                     2).% 强化任一部位 
-define(CONST_WELFARE_TRAIN,                        3).% 进行人物培养 
-define(CONST_WELFARE_ABILITY,                      4).% 升级奇门长生 
-define(CONST_WELFARE_CHAT,                         5).% 世界聊天 
-define(CONST_WELFARE_SINGLE_COPY,                  6).% 普通副本 
-define(CONST_WELFARE_FRIEND,                       7).% 添加好友 
-define(CONST_WELFARE_PLANT,                        8).% 农场种植 
-define(CONST_WELFARE_GIRL,                         9).% 仕女互动 
-define(CONST_WELFARE_CAMP,                         10).% 升级阵法 
-define(CONST_WELFARE_MALL,                         11).% 商城购物 
-define(CONST_WELFARE_CULTIVATION,                  12).% 提升修为 
-define(CONST_WELFARE_PARTNER,                      13).% 寻访招募武将 
-define(CONST_WELFARE_PRACTICE,                     14).% 修行获得经验 
-define(CONST_WELFARE_HORSE,                        15).% 培养坐骑 
-define(CONST_WELFARE_GUILD,                        16).% 创建或加入军团 
-define(CONST_WELFARE_RUNE,                         17).% 收夺 
-define(CONST_WELFARE_SOUL,                         18).% 刻印 
-define(CONST_WELFARE_PRAY,                         19).% 巡城 
-define(CONST_WELFARE_SINGLE_ARENA,                 20).% 参与一骑讨 
-define(CONST_WELFARE_ELITE_COPY,                   21).% 精英副本 
-define(CONST_WELFARE_MIND,                         22).% 祈天 
-define(CONST_WELFARE_COMMERCE,                     23).% 派遣商队 
-define(CONST_WELFARE_EQUIP,                        24).% 锻造装备 
-define(CONST_WELFARE_COLLECT,                      25).% 采集 
-define(CONST_WELFARE_ASSISTER,                     26).% 主角副将 
-define(CONST_WELFARE_MULTI_ARENA,                  27).% 战群雄 
-define(CONST_WELFARE_MULTI_COPY,                   28).% 多人副本 
-define(CONST_WELFARE_INVASION,                     29).% 异民族 
-define(CONST_WELFARE_GROUP,                        30).% 掠阵 

-define(CONST_WELFARE_LOGIN_FIRST_LV,               2).% 连续登陆--第一个奖励开放等级 
-define(CONST_WELFARE_LOGIN_REVIEW_COST,            10).% 连续登陆--消耗元宝 
-define(CONST_WELFARE_LOGIN_FIRST_ID,               10013).% 连续登陆--第一个id 
-define(CONST_WELFARE_LOGIN_LAST_ID,                10018).% 连续登陆--最后一个id 

-define(CONST_WELFARE_TYPE_GIFT_TYPE_IN,            1).% 充值礼包类型--充值 
-define(CONST_WELFARE_TYPE_GIFT_TYPE_OUT,           2).% 充值礼包类型--消费 

-define(CONST_WELFARE_ATYPE_NORMAL,                 1).% 充值礼包类型--普通 
-define(CONST_WELFARE_ATYPE_NEW_SERV,               2).% 充值礼包类型--新服 
-define(CONST_WELFARE_ATYPE_NDAY,                   3).% 充值礼包类型--每n天一轮 

-define(CONST_WELFARE_HANDLE_TYPE_SINGLE,           1).% 充值礼包处理类型--单笔 
-define(CONST_WELFARE_HANDLE_TYPE_ACCUM,            2).% 充值礼包处理类型--累计 
-define(CONST_WELFARE_HANDLE_TYPE_DAILY_ACCUM,      3).% 充值礼包处理类型--每日累计 

-define(CONST_WELFARE_CONTINUE_LV,                  10).% 连续在线开启等级 

-define(CONST_WELFARE_REFIGHT_BATTLEFIELD_FIRST_ID,  10060).% 再战沙场第一个礼包ID 
-define(CONST_WELFARE_REFIGHT_BATTLEFIELD_LAST_ID,  10064).% 再战沙场最后一个礼包ID 

%% ==========================================================
%% 日志
%% ==========================================================
-define(CONST_LOG_USER,                             1).% 人物 
-define(CONST_LOG_CTN,                              2).% 背包仓库 
-define(CONST_LOG_BATTLE,                           3).% 战斗 
-define(CONST_LOG_PARTNER,                          4).% 武将 
-define(CONST_LOG_MAP,                              5).% 地图 
-define(CONST_LOG_ACHIEVEMENT,                      6).% 成就 
-define(CONST_LOG_HOME,                             7).% 家园 
-define(CONST_LOG_CHAT,                             8).% 聊天 
-define(CONST_LOG_MAIL,                             9).% 邮件 
-define(CONST_LOG_CHESS,                            10).% 双陆 
-define(CONST_LOG_ABILITY_CAMP,                     11).% 内功阵法 
-define(CONST_LOG_FURNACE,                          12).% 作坊 
-define(CONST_LOG_COPY,                             13).% 副本 
-define(CONST_LOG_FRIEND,                           14).% 好友 
-define(CONST_LOG_GUILD,                            15).% 军团 
-define(CONST_LOG_PRACTISE,                         16).% 修炼 
-define(CONST_LOG_MARKET,                           17).% 拍卖 
-define(CONST_LOG_MALL,                             18).% 商城 
-define(CONST_LOG_TEAM,                             19).% 常规组队 
-define(CONST_LOG_TASK,                             20).% 任务 
-define(CONST_LOG_RESOURCE,                         21).% 资源系统 
-define(CONST_LOG_SIG_ARENA,                        22).% 个人竞技场 
-define(CONST_LOG_LOTTERY,                          23).% 淘宝（宝箱,五色井） 
-define(CONST_LOG_MIND,                             24).% 心法 
-define(CONST_LOG_PATROL,                           25).% 巡城 
-define(CONST_LOG_SKILL,                            26).% 技能 
-define(CONST_LOG_HORSE,                            27).% 坐骑 
-define(CONST_LOG_SPRING,                           28).% 温泉 
-define(CONST_LOG_TOWER,                            29).% 闯塔 
-define(CONST_LOG_COMMERCE,                         30).% 商路 
-define(CONST_LOG_WELFARE,                          33).% 福利 
-define(CONST_LOG_COLLECT,                          34).% 采集系统 
-define(CONST_LOG_BOSS,                             35).% BOSS战 
-define(CONST_LOG_INVASION,                         36).% 守关/异民族 
-define(CONST_LOG_SCHEDULE,                         37).% 课程表 
-define(CONST_LOG_SIEGE,                            39).% 怪物攻城 
-define(CONST_LOG_MCOPY,                            41).% 团队战场(多人副本) 
-define(CONST_LOG_STREN,                            42).% 强化 
-define(CONST_LOG_MULTI_ARENA,                      44).% 多人竞技场 
-define(CONST_LOG_RANK,                             45).% 排行榜 
-define(CONST_LOG_120,                              80).% 天命 
-define(CONST_LOG_EXPLOIT,                          81).% 军团贡献 
-define(CONST_LOG_MERITORIOUS,                      82).% 功勋(原：阅历/历练) 
-define(CONST_LOG_RECHARGE,                         91).% 充值 
-define(CONST_LOG_CURRENCY,                         92).% 货币 
-define(CONST_LOG_GM,                               94).% GM系统 
-define(CONST_LOG_CAMPAIGN,                         95).% 玩法活动 
-define(CONST_LOG_QUIT,                             96).% 退出 
-define(CONST_LOG_BATTLE_SKILL,                     100).% 战斗技能统计 
-define(CONST_LOG_BATTLE_PARTNER,                   101).% 战斗武将统计 
-define(CONST_LOG_BATTLE_CAMP,                      102).% 出战阵型统计 
-define(CONST_LOG_BATTLE_STAT,                      103).% 战斗统计 
-define(CONST_LOG_BUFF,                             104).% BUFF 
-define(CONST_LOG_CAMP_BATTLE,                      105).% 阵营站 
-define(CONST_LOG_ACROSS_SERV,                      107).% 跨服战 
-define(CONST_LOG_GUILD_FLAG,                       108).% 斩将夺旗(军团夺旗战) 
-define(CONST_LOG_MARRY,                            110).% 结婚 
-define(CONST_LOG_SHOP,                             123).% 道具店 
-define(CONST_LOG_RECONNECT,                        124).% 闪断重练 
-define(CONST_LOG_LOGIN_CHECK,                      125).% 登陆验证 
-define(CONST_LOG_LOGIN,                            126).% 玩家登录 
-define(CONST_LOG_LOGOUT,                           127).% 玩家登出 
-define(CONST_LOG_LV_UP,                            128).% 玩家升级 
-define(CONST_LOG_GOODS,                            129).% 道具 
-define(CONST_LOG_USER_CREATE,                      130).% 创建角色 
-define(CONST_LOG_TRAINS_POINT,                     131).% 培养 
-define(CONST_LOG_SOUL,                             132).% 作坊:刻印 
-define(CONST_LOG_ROBOT_COST,                       133).% 机器人扣费 
-define(CONST_LOG_WORLD,                            134).% 乱天下 
-define(CONST_LOG_LINK,                             135).% 数据中心的请求 
-define(CONST_LOG_SHOP_SECRET,                      136).% 云游商人 
-define(CONST_LOG_LOGIN_REQ,                        137).% 登录请求 
-define(CONST_LOG_GAMBLE,                           138).% 青梅煮酒筹码结算 
-define(CONST_LOG_GAMBLE_EXCHANGE,                  139).% 青梅煮酒筹码兑换 
-define(CONST_LOG_MARKET_GET,                       140).% 市集下架 
-define(CONST_LOG_SNOW,                             141).% 雪夜赏灯 

-define(CONST_LOG_POS_USER_CREAT,                   1).% 人物：创建角色 
-define(CONST_LOG_FUN_PLAYER_COMMON_TRAIN,          2).% 角色：普通培养(消费102) 
-define(CONST_LOG_POS_USER_TRAIN,                   2).% 人物：培养属性 
-define(CONST_LOG_FUN_PLAYER_TRAIN_1,               3).% 角色：进阶培养(消费103) 
-define(CONST_LOG_POS_USER_LV_UP,                   3).% 人物：升级 
-define(CONST_LOG_FUN_PLAYER_TRAIN_2,               4).% 角色：高级培养(消费104) 
-define(CONST_LOG_POS_USER_LOGIN,                   4).% 角色：登录 
-define(CONST_LOG_FUN_PLAYER_TRAIN_3,               5).% 角色：白金培养(消费105) 
-define(CONST_LOG_FUN_PLAYER_TRAIN_4,               6).% 角色：至尊培养(消费106) 
-define(CONST_LOG_FUN_PLAYER_SKILL_UP,              7).% 角色：武技提升(消费107) 
-define(CONST_LOG_FUN_TITLE_AWARD,                  8).% 官衔：领取福利(产出108) 
-define(CONST_LOG_FUN_PLAYER_CLICK,                 9).% 登录鼠标点击 
-define(CONST_LOG_FUN_USER_CULTIVATION,             10).% 角色：修为（消耗110） 

-define(CONST_LOG_FUN_CTN_EXPAND_BAG,               1).% 扩展背包(消费201) 
-define(CONST_LOG_FUN_CTN_EXPAND_DEPOT,             2).% 扩展仓库(消费202) 
-define(CONST_LOG_FUN_CTN_REMOTE_DEPOT,             3).% 打开远程仓库 
-define(CONST_LOG_FUN_CTN_REMOTE_SHOP,              4).% 打开远程道具店 
-define(CONST_LOG_FUN_CTN_SUPPLY_GOLD,              5).% 使用铜钱补给道具 
-define(CONST_LOG_FUN_CTN_SUPPLY_CASH,              6).% 使用元宝补给道具 

-define(CONST_LOG_FUN_BATTLE_AWARD,                 1).% 战斗结算(产出301) 

-define(CONST_LOG_FUN_PARTNER_RECRUIT_COST,         1).% 武将：招募消耗(消费401) 
-define(CONST_LOG_FUN_PARTNER_FIRE,                 2).% 武将：离队 
-define(CONST_LOG_FUN_PARTNER_LOOKER,               3).% 武将：寻访 
-define(CONST_LOG_FUN_PARTNER_WITH,                 4).% 武将：携带 
-define(CONST_LOG_FUN_PARTNER_COMMON_TRAIN,         5).% 武将：普通培养(消费405) 
-define(CONST_LOG_FUN_PARTNER_UPGRADE_TRAIN,        6).% 武将：进阶培养(消费406) 
-define(CONST_LOG_FUN_PARTNER_HIGH_TRAIN,           7).% 武将：高级培养(消费407) 
-define(CONST_LOG_FUN_PARTNER_WHITE_TRAIN,          8).% 武将：白金培养(消费408) 
-define(CONST_LOG_FUN_PARTNER_GREAT_TRAIN,          9).% 武将：至尊培养(消费409) 
-define(CONST_LOG_FUN_PARTNER_INHERIT,              10).% 武将：属性继承(消费410) 
-define(CONST_LOG_FUN_PARTNER_LOOKER_BUY,           11).% 武将：增加寻访次数(消费411) 
-define(CONST_LOG_FUN_PARTNER_CD,                   12).% 武将：清除寻访时间(消费412) 
-define(CONST_LOG_FUN_PARTNER_TRAIN,                13).% 武将：角色培养(消费413) 
-define(CONST_LOG_FUN_PARTNER_EXTEND_BAG,           14).% 武将：招贤馆格子扩展(消费414) 
-define(CONST_LOG_PARTNER_FIRE_FROM_PUB_AUTO,       15).% 武将：超时酒馆寻访解散 
-define(CONST_LOG_PARTNER_FIRE_FROM_PUB_MANU,       16).% 武将：手动酒馆寻访解散 

-define(CONST_LOG_FUN_HOME_PLANT,                   1).% 家园：种植(消费701) 
-define(CONST_LOG_FUN_HOME_GIRL,                    2).% 家园：仕女苑(消费702) 
-define(CONST_LOG_FUN_HOME_CLEAN_CD,                3).% 家园：清除CD(消费703) 
-define(CONST_LOG_FUN_HOME_UPGRADE,                 4).% 家园：升级(消费704) 
-define(CONST_LOG_FUN_HOME_GOLD_REFRESH,            5).% 家园：种植铜钱刷新(消费705) 
-define(CONST_LOG_FUN_HOME_ONEKEY_REFRESH,          6).% 家园：种植一键刷新(消费706) 
-define(CONST_LOG_FUN_HOME_PLANT_UPGRADE,           7).% 家园：土地升级(消费707) 
-define(CONST_LOG_FUN_HOME_CLEAN_PLANT_CD,          8).% 家园：清除土地CD(消费708) 
-define(CONST_LOG_FUN_HOME_OPEN_PLANT,              9).% 家园：开启种植栏(消费709) 
-define(CONST_LOG_FUN_HOME_PLANT_REWARD,            10).% 家园：土地收获(产出710) 
-define(CONST_LOG_FUN_HOME_UPGRADE_FARM,            11).% 家园：升级农场(消费711) 
-define(CONST_LOG_FUN_HOME_UPGRADE_MARKET,          12).% 家园：升级市场(消费712) 
-define(CONST_LOG_FUN_HOME_UPGRADE_STABLE,          13).% 家园：升级马厩(消费713) 
-define(CONST_LOG_FUN_HOME_UPGRADE_SHOW,            14).% 家园：升级展厅(消费714) 
-define(CONST_LOG_FUN_HOME_GET_REWARD,              15).% 家园：领取奖励(产出15) 
-define(CONST_LOG_FUN_HOME_RECRUIT_GIRL,            16).% 家园：招募仕女(消费16) 

-define(CONST_LOG_FUN_CHAT_BUY,                     1).% 聊天：购买喇叭(消费801) 

-define(CONST_LOG_FUN_MAIL_GOLD,                    1).% 邮件：获得铜钱(产出901) 
-define(CONST_LOG_FUN_MAIL_CASH,                    2).% 邮件：获得元宝(产出902) 
-define(CONST_LOG_FUN_MAIL_OUT_GOLD,                3).% 邮件：支出铜钱(消费903) 

-define(CONST_LOG_FUN_ABILITY_UPGRADE,              1).% 内功升级(消费1101) 
-define(CONST_LOG_FUN_CAMP_UPGRADE,                 2).% 阵法升级(消费1102) 
-define(CONST_LOG_FUN_ABILITY_EXT,                  3).% 八门(消费1103) 

-define(CONST_LOG_FUN_FURNACE_STREN,                1).% 作坊：部位强化(消费1201) 
-define(CONST_LOG_FUN_FURNACE_QUEUE,                2).% 作坊：开启强化队列(消费1202) 
-define(CONST_LOG_FUN_FURNACE_NO_CD,                3).% 作坊：永久清除CD(消费1203) 
-define(CONST_LOG_FUN_FURNACE_CLEAR_CD,             4).% 作坊：清除CD(消费1204) 
-define(CONST_LOG_FUN_FURNACE_FORGE,                5).% 作坊：装备锻造(消费1205) 
-define(CONST_LOG_FUN_FURNACE_FORGE_DIRECT,         6).% 作坊：立即锻造(消费1206) 
-define(CONST_LOG_FUN_FURNACE_PRACTISE,             7).% 作坊:装备洗炼(消费1207) 
-define(CONST_LOG_FUN_FURNACE_PRACTISE_LOCK,        8).% 作坊:装备洗炼锁定(消费1208) 
-define(CONST_LOG_FUN_FURNACE_SOUL,                 9).% 作坊：刻印(消费1209) 
-define(CONST_LOG_FUN_FURNACE_MERGE,                10).% 作坊：道具合成(消费1210) 

-define(CONST_LOG_FUN_COMMON_COPY_BATTLE,           1).% 普通副本：战斗奖励(产出1301) 
-define(CONST_LOG_FUN_COMMON_COPY_BALANCE,          1).% 副本：结算操作 
-define(CONST_LOG_FUN_COMMON_COPY_PASS,             2).% 普通副本：通关奖励(产出1302) 
-define(CONST_LOG_13_12,                            2).% 副本：奖励操作 
-define(CONST_LOG_FUN_COMMON_COPY_SCHE,             3).% 普通副本：进度奖励(产出1303) 
-define(CONST_LOG_FUN_COMMON_COPY_COST,             4).% 普通副本：战斗消耗(消费1304) 
-define(CONST_LOG_FUN_ELITE_COPY_BATTLE,            5).% 精英副本：战斗奖励(产出1305) 
-define(CONST_LOG_FUN_ELITE_COPY_PASS,              6).% 精英副本：通关奖励(产出1306) 
-define(CONST_LOG_FUN_ELITE_COPY_RESET,             7).% 精英副本：重置(消费1307) 
-define(CONST_LOG_COPY_RAID_IN,                     8).% 普通副本：扫荡（消费1308） 
-define(CONST_LOG_COPY_RAID_OUT,                    9).% 普通副本：扫荡（产出1309） 

-define(CONST_LOG_14_1,                             1).% 好友：一键添加好友 
-define(CONST_LOG_14_2,                             2).% 好友：普通添加好友 

-define(CONST_LOG_15_1,                             1).% 军团：创建军团操作 
-define(CONST_LOG_FUN_GUILD_PARTY,                  1).% 军团：军团宴会(出入1501) 
-define(CONST_LOG_15_2,                             2).% 军团：军团将作监技能捐献操作 
-define(CONST_LOG_15_12,                            2).% 军团：军团宝库(消费1502) 
-define(CONST_LOG_15_3,                             3).% 军团：冶炼技能捐献操作 
-define(CONST_LOG_FUN_GUILD_DONATE,                 3).% 军团：军团捐献(出入1503) 
-define(CONST_LOG_FUN_GUILD_MAGIC_DONATE,           4).% 军团：术法捐献操作(消费1504) 
-define(CONST_LOG_FUN_GUILD_CREATE,                 4).% 军团：创建军团(消费1504) 
-define(CONST_LOG_15_5,                             5).% 军团：购买装备操作 
-define(CONST_LOG_FUN_GUILD_WELFARE,                6).% 军团：领取福利(产出1506) 
-define(CONST_LOG_FUN_GUILD_RESET_TIMES,            7).% 军团：重置次数(消费1507) 

-define(CONST_LOG_16_1,                             1).% 修炼：修炼获得(产出1601) 

-define(CONST_LOG_FUN_MARKET_SALE,                  1).% 拍卖：寄售操作 
-define(CONST_LOG_17_11,                            1).% 拍卖：保管(消费1701) 
-define(CONST_LOG_17_2,                             2).% 拍卖：拍卖成功操作 
-define(CONST_LOG_FUN_MARKET_SALE_GET,              3).% 拍卖：拍卖收益(产出1703) 
-define(CONST_LOG_FUN_MARKET_PRICE_FIRST,           4).% 拍卖：一口价(消费1704) 
-define(CONST_LOG_FUN_MARKET_PRICE_FIRST_GET,       5).% 拍卖：一口价收益(产出1705·) 
-define(CONST_LOG_FUN_MARKET_ADD_MONEY,             6).% 拍卖：寄售后加元宝(产出1706) 

-define(CONST_LOG_FUN_MALL_BUY,                     1).% 商城:购买道具操作(消费1801) 
-define(CONST_LOG_FUN_MALL_MONEY,                   1).% 商城：扣钱(消费1801) 

-define(CONST_LOG_19_1,                             1).% 常规组队：创建队伍操作 
-define(CONST_LOG_19_2,                             2).% 常规组队：解散队伍操作 
-define(CONST_LOG_19_3,                             3).% 常规组队：加入队伍操作 
-define(CONST_LOG_19_4,                             4).% 常规组队：邀请组队操作 
-define(CONST_LOG_19_5,                             5).% 常规组队：申请加入操作 

-define(CONST_LOG_FUN_TASK_GUILD,                   1).% 任务：军团任务(产出2001) 
-define(CONST_LOG_FUN_TASK_MAIN,                    2).% 任务；主线任务(产出2002) 
-define(CONST_LOG_FUN_TASK_BRANCH,                  3).% 任务：支线任务(产出2003) 
-define(CONST_LOG_FUN_TASK_COMMON,                  4).% 任务：日常任务(产出2004) 
-define(CONST_LOG_FUN_TASK_DIRECT_FINISH,           5).% 任务：直接完成(消费2005) 
-define(CONST_LOG_FUN_TASK_MAKE_GOODS,              6).% 任务获取道具 

-define(CONST_LOG_FUN_LOTTERY_DO,                   1).% 招财：招财(出入2101) 
-define(CONST_LOG_FUN_LOTTERY_OPEN,                 2).% 招财：开启宝箱(出入2102) 
-define(CONST_LOG_21_3,                             3).% 拜将：拜将(出入2103) 
-define(CONST_LOG_FUN_LOTTERY_UPGRADE,              4).% 招财：提升宝箱品质(消费2104) 

-define(CONST_LOG_FUN_SIG_ARENA_DAY,                1).% 个人竞技：每日领取(产出2201) 
-define(CONST_LOG_FUN_SIG_ARENA_BATTLE,             2).% 个人竞技：战斗结算(产出2202) 
-define(CONST_LOG_FUN_SIG_ARENA_STREAK,             3).% 个人竞技：连胜奖励(产出2203) 
-define(CONST_LOG_FUN_SIG_ARENA_BUY,                4).% 个人竞技：购买次数(消费2204) 
-define(CONST_LOG_FUN_SIG_ARENA_CLEAR,              5).% 个人竞技：清除CD(消费2205) 

-define(CONST_LOG_23_1,                             1).% 五色井：打开铜钱宝箱(消费2301) 
-define(CONST_LOG_23_2,                             2).% 五色井：打开一阶元宝宝箱(消费2302) 
-define(CONST_LOG_23_3,                             3).% 五色井：打开二阶元宝宝箱(消费2303) 
-define(CONST_LOG_23_4,                             4).% 五色井：打开三阶元宝宝箱(消费2304) 
-define(CONST_LOG_23_5,                             5).% 五色井：打开四阶元宝宝箱(消费2305) 
-define(CONST_LOG_23_6,                             6).% 五色井：打开累积型奖励操作 

-define(CONST_LOG_24_1,                             1).% 心法：星宿转化操作(产出2401) 
-define(CONST_LOG_FUN_MIND_ONE_COST,                2).% 心法：参阅地煞(消费2402) 
-define(CONST_LOG_FUN_MIND_TWO_COST,                3).% 心法：参阅天罡(消费2403) 
-define(CONST_LOG_FUN_MIND_THREE_COST,              4).% 心法：参阅星宿(消费2404) 
-define(CONST_LOG_FUN_MIND_FOUR_COST,               5).% 心法：参阅元辰(消费2405) 
-define(CONST_LOG_FUN_MIND_FOUR_CASH,               6).% 心法：元宝参阅元辰(消费2406) 
-define(CONST_LOG_FUN_MIND_THREE_CASH,              7).% 心法：元宝参阅星宿(消费2407) 
-define(CONST_LOG_FUN_MIND_EXTEND_BAG,              8).% 心法：扩展背包(消费2408) 
-define(CONST_LOG_FUN_MIND_UPGRADE,                 9).% 心法：升级(消费2409) 

-define(CONST_LOG_FUN_SKILL_UPGRADE,                1).% 技能：升级(消费2601) 
-define(CONST_LOG_FUN_SKILL_RESET,                  2).% 技能：洗点（消耗2602） 

-define(CONST_LOG_27_1,                             1).% 坐骑:产出小马驹操作 
-define(CONST_LOG_27_11,                            1).% 坐骑：铜钱喂养(消费2701) 
-define(CONST_LOG_FUN_HORSE_STREN,                  2).% 坐骑:坐骑强化操作(消费2702) 
-define(CONST_LOG_27_12,                            2).% 坐骑：元宝喂养(消费2702) 
-define(CONST_LOG_FUN_HORSE_INHERIT,                3).% 坐骑:坐骑继承操作(消费2703) 
-define(CONST_LOG_FUN_HORSE_LV_UP,                  4).% 坐骑：升级(消耗2704) 

-define(CONST_LOG_28_1,                             1).% 温泉：互动操作 
-define(CONST_LOG_28_2,                             2).% 温泉：离开结算操作(消费2802) 

-define(CONST_LOG_29_1,                             1).% 闯塔：重置(消费2901) 
-define(CONST_LOG_29_11,                            1).% 闯塔：结算操作 
-define(CONST_LOG_FUN_TOWER_SPEEDUP,                2).% 闯塔：扫荡加速 
-define(CONST_LOG_29_3,                             3).% 闯塔(破阵)：战斗奖励(产出2903) 
-define(CONST_LOG_FUN_TOWER_GOLD_REWARD,            4).% 闯塔(破阵)：破阵奖励(消费2904) 
-define(CONST_LOG_FUN_TOWER_DIVINE,                 5).% 闯塔：占卜(消费2905) 
-define(CONST_LOG_FUN_TOWER_VIP_AWARD,              6).% 闯塔：VIP翻牌（消费2906） 

-define(CONST_LOG_FUN_COMMERCE_CARRY,               1).% 商路：运送(产出3001) 
-define(CONST_LOG_FUN_COMMERCE_ROB,                 2).% 商路：伏击(产出3002) 
-define(CONST_LOG_FUN_COMMERCE_BUY,                 3).% 商路：购买伏击次数(消费3003) 
-define(CONST_LOG_FUN_COMMERCE_BUILD,               4).% 商路：建造市场(消费3004) 
-define(CONST_LOG_FUN_COMMERCE_ESCORT,              5).% 商路：护送(产出3005) 
-define(CONST_LOG_FUN_COMMERCE_REFRESH,             6).% 商路：刷新品质(消费3006) 
-define(CONST_LOG_30_7,                             7).% 商路：元宝冷却操作(产出3007) 
-define(CONST_LOG_30_8,                             8).% 商路：邀请护送操作 
-define(CONST_LOG_FUN_COMMERCE_FINISH,              9).% 商路：直接完成(消费3009) 

-define(CONST_LOG_FUN_WELFARE_REWARD_GOLD,          1).% 福利：铜钱奖励 
-define(CONST_LOG_FUN_WELFARE_REWARD_CASH,          2).% 福利：元宝奖励 

-define(CONST_LOG_113_1,                            1).% 采集系统：普通采集操作 
-define(CONST_LOG_113_11,                           1).% 采集系统：采集(消耗11301) 
-define(CONST_LOG_113_2,                            2).% 采集系统：额外采集操作 
-define(CONST_LOG_113_3,                            3).% 采集系统：普通采集产出操作 
-define(CONST_LOG_113_4,                            4).% 采集系统：额外采集产出操作 

-define(CONST_LOG_FUN_BOSS_CALC,                    1).% BOSS：战斗结算鼓舞(产出3501) 
-define(CONST_LOG_FUN_BOSS_HURT_RANK,               2).% BOSS：伤害排名(产出3502) 
-define(CONST_LOG_FUN_BOSS_LAST_HIT,                3).% BOSS：最后一击(产出3502) 
-define(CONST_LOG_FUN_BOSS_FIRST_HIT,               4).% BOSS：首次攻击(产出3502) 
-define(CONST_LOG_FUN_BOSS_CHEER,                   5).% BOSS：鼓舞(消费3505) 
-define(CONST_LOG_FUN_BOSS_AUTO,                    6).% BOSS：自动战斗(消费3506) 
-define(CONST_LOG_FUN_BOSS_REBORN,                  7).% BOSS：欲火重生鼓舞(消费3507) 
-define(CONST_LOG_FUN_BOSS_AUTO_JOIN,               8).% BOSS：自动参战鼓舞(消费3508) 
-define(CONST_LOG_FUN_BOSS_CLEAR_CD,                9).% BOSS：清除CD鼓舞(消费3509) 
-define(CONST_LOG_35_10,                            10).% BOSS:参战操作 
-define(CONST_LOG_35_11,                            11).% BOSS:结束统计操作 

-define(CONST_LOG_36_0,                             0).% 守关：通关失败操作 
-define(CONST_LOG_FUN_GUARD_BATTLE,                 1).% 守关：战斗结算(产出3601) 
-define(CONST_LOG_36_1,                             1).% 守关：通关成功操作 
-define(CONST_LOG_FUN_GUARD_PASS,                   2).% 守关：通关奖励(产出3602) 
-define(CONST_LOG_FUN_GUARD_CLEAR,                  3).% 守关：清除CD(消耗3603) 
-define(CONST_LOG_FUN_GUARD_CARD,                   4).% 守关：额外翻牌（消耗36043） 

-define(CONST_LOG_FUN_SCHEDULE_REWARD_GOLD,         1).% 课程表：游戏币奖励(产出3701) 
-define(CONST_LOG_FUN_SCHEDULE_REWARD_CASH,         2).% 课程表：绑定元宝奖励(产出3702) 
-define(CONST_LOG_FUN_SCHEDULE_REVIEW,              3).% 课程表：补签（消耗37005） 

-define(CONST_LOG_112_11,                           1).% 怪物攻城：击杀奖(产出11201) 
-define(CONST_LOG_112_1,                            1).% 怪物攻城战：发出/接受邀请 
-define(CONST_LOG_FUN_SIEGE_REWARD_GOLD,            1).% 怪物攻城：铜钱奖励 
-define(CONST_LOG_112_12,                           2).% 怪物攻城：军团积分奖(产出11202) 
-define(CONST_LOG_112_2,                            2).% 怪物攻城战：结算操作 
-define(CONST_LOG_FUN_SIEGE_REWARD_CASH,            2).% 怪物攻城：元宝奖励 
-define(CONST_LOG_112_13,                           3).% 怪物攻城：伤害排名(产出11203) 
-define(CONST_LOG_112_14,                           4).% 怪物攻城：战斗结算(产出11204) 
-define(CONST_LOG_112_5,                            5).% 怪物攻城战：清除战斗CD 

-define(CONST_LOG_FUN_MULTI_COPY_BATTLE,            1).% 多人副本：战斗奖励(产出10901) 
-define(CONST_LOG_109_11,                           1).% 多人副本：参与操作 
-define(CONST_LOG_FUN_MULTI_COPY_PASS,              2).% 多人副本：通关奖励(产出10902) 
-define(CONST_LOG_FUN_MULTI_COPY_OTHER,             3).% 多人副本：奇遇奖励(产出10903) 

-define(CONST_LOG_BLESS_GET_EXP,                    1).% 祝福：领取经验 

-define(CONST_LOG_FUN_MULTI_ARENA_SHOP,             1).% 多人竞技：商店(消费10601) 
-define(CONST_LOG_FUN_MULTI_ARENA_BATTLE,           2).% 多人竞技：战斗奖励(产出10602) 
-define(CONST_LOG_FUN_MULTI_ARENA_RANK,             3).% 多人竞技：排名奖励(产出10603) 

-define(CONST_LOG_FUN_GM_IN,                        1).% GM系统（产出9401） 
-define(CONST_LOG_FUN_GM_OUT,                       2).% GM系统（消费9402） 

-define(CONST_LOG_105_1,                            1).% 阵营战：参战记录操作 
-define(CONST_LOG_105_11,                           1).% 阵营战：替身娃娃(消耗10501) 
-define(CONST_LOG_105_2,                            2).% 阵营战：使用策略操作 
-define(CONST_LOG_105_12,                           2).% 阵营战：复活(消耗10502) 
-define(CONST_LOG_105_3,                            3).% 阵营战：结束统计操作 
-define(CONST_LOG_105_13,                           3).% 阵营战:胜负奖励(产出10503) 
-define(CONST_LOG_105_14,                           4).% 阵营战:排名奖励(产出10504) 

-define(CONST_LOG_107_1,                            1).% 跨服战：普通挑战操作 
-define(CONST_LOG_107_11,                           1).% 跨服战：购买挑战(消费10701) 
-define(CONST_LOG_107_2,                            2).% 跨服战：超级挑战操作 
-define(CONST_LOG_107_12,                           2).% 跨服战：超级挑战(消费10702) 

-define(CONST_LOG_108_1,                            1).% 斩将夺旗：购买守卫(消费10801) 
-define(CONST_LOG_108_2,                            2).% 斩将夺旗：复活(消费10802) 
-define(CONST_LOG_108_3,                            3).% 斩将夺旗：战斗奖励(产出10803) 

-define(CONST_LOG_123_1,                            1).% 道具店：购买道具(消费12301) 
-define(CONST_LOG_FUN_MALL_SALE,                    3).% 道具店：出售 

-define(CONST_LOG_PLUS_CURRENCY,                    1).% 加货币 
-define(CONST_LOG_MINUS_CURRENCY,                   2).% 减货币 

-define(CONST_LOG_DIR,                              "./../logs").% 日志文件相对路径 
-define(CONST_LOG_FILE_NAME_PRE,                    log).% 日志前缀名 

%% ==========================================================
%% 采集
%% ==========================================================
-define(CONST_COLLECT_COLLECT_TYPE_TASK,            0).% 采集类型--任务 

-define(CONST_COLLECT_COLLECT_TYPE_WOOD,            1).% 采集类型--木材 
-define(CONST_COLLECT_COLLECT_TYPE_ORE,             2).% 采集类型--矿石 
-define(CONST_COLLECT_COLLECT_TYPE_FELL,            3).% 采集类型--兽皮 

-define(CONST_COLLECT_MAP_ID_1,                     36001).% 采集常量--伐木场地图id 
-define(CONST_COLLECT_MAP_ID_2,                     36002).% 采集常量--矿场地图id 
-define(CONST_COLLECT_MAP_ID_3,                     36003).% 采集常量--猎场地图id 

%% ==========================================================
%% 异民族
%% ==========================================================
-define(CONST_INVASION_CD_SUM,                      2).% 清除战斗冷却金额 
-define(CONST_INVASION_TURNCARD_SUM,                5).% 额外翻牌金额 
-define(CONST_INVASION_STEP_LENGTH_X,               7).% 怪物移动步长X 
-define(CONST_INVASION_STEP_LENGTH_Y,               7).% 怪物移动步长Y 
-define(CONST_INVASION_TIME_MON_CHANGE,             10).% 怪物间隔时间修改 
-define(CONST_INVASION_REBORN_DURATION,             30).% 玩家复活时间 
-define(CONST_INVASION_PRE_START_TIME,              1000).% 开始前倒计时 
-define(CONST_INVASION_TIME_PER_MONSTER_STEP,       1000).% 怪物坐标刷新间隔 
-define(CONST_INVASION_TIME_CD_BEAR,                1000).% cd到点容差，秒数 
-define(CONST_INVASION_TIME_MONSTER_ARRIVED,        2000).% 怪物到点后延时 

-define(CONST_INVASION_DAILY_TIMES,                 2).% 每天可用次数 

-define(CONST_INVASION_FIRST,                       1).% 异民族：第一条路径 
-define(CONST_INVASION_SECOND,                      2).% 异民族：第二条路径 
-define(CONST_INVASION_THIRD,                       3).% 异民族：第三条路径 

-define(CONST_INVASION_GUARD,                       1).% 异民族：守关 
-define(CONST_INVASION_ATTACK,                      2).% 异民族：攻关 

-define(CONST_INVASION_GUARD_START,                 0).% 守关开始 

-define(CONST_INVASION_INVASION_TIME,               1800).% 异民族活动时间 

-define(CONST_INVASION_CLEARANCE_DURATION,          300).% 清理时间 

-define(CONST_INVASION_EVALUATION_0,                0).% 通关评价：失败 
-define(CONST_INVASION_EVALUATION_B,                1).% 通关评价：B 
-define(CONST_INVASION_EVALUATION_A,                2).% 通关评价：A 
-define(CONST_INVASION_EVALUATION_S,                3).% 通关评价：S 
-define(CONST_INVASION_EVALUATION_SS,               4).% 通关评价：SS 
-define(CONST_INVASION_EVALUATION_SSS,              5).% 通关评价：SSS 

-define(CONST_INVASION_DIVIDE_B,                    90).% 通关划分：B 
-define(CONST_INVASION_DIVIDE_A,                    100).% 通关划分：A 
-define(CONST_INVASION_DIVIDE_S,                    110).% 通关划分：S 
-define(CONST_INVASION_DIVIDE_SS,                   120).% 通关划分：SS 

-define(CONST_INVASION_IN_PROGRESS,                 0).% 进度：进行中 
-define(CONST_INVASION_PHASE,                       1).% 进度：阶段 
-define(CONST_INVASION_LOSE,                        2).% 进度：失败 
-define(CONST_INVASION_WIN,                         3).% 进度：胜利 

-define(CONST_INVASION_REWARD,                      1).% 离线处理：副本奖励 
-define(CONST_INVASION_TIMES,                       2).% 离线处理：副本次数 

-define(CONST_INVASION_NPC_HP_DELTA,                100).% NPC血量减少量 

-define(CONST_INVASION_ONE,                         1).% 停止行走概率：一 
-define(CONST_INVASION_TWO,                         2).% 停止行走概率：二 

-define(CONST_INVASION_TO_TAEM,                     1).% 退出副本：返回组队界面。 
-define(CONST_INVASION_TO_HALL,                     2).% 退出副本：返回大厅界面。 
-define(CONST_INVASION_TO_CITY,                     3).% 退出副本：返回中立场景。 

-define(CONST_INVASION_DOLL_COST,                   30).% 异民族自动参加消耗元宝 

%% ==========================================================
%% 世界BOSS
%% ==========================================================
-define(CONST_BOSS_CD_REBORN,                       30).% 世界BOSSCD--死亡 
-define(CONST_BOSS_CD_EXIT,                         60).% 世界BOSSCD--退出 

-define(CONST_BOSS_INTERVAL_HP,                     2).% 世界BOSS更新间隔--怪物生命 
-define(CONST_BOSS_INTERVAL_RANK,                   5).% 世界BOSS更新间隔--排名 

-define(CONST_BOSS_END_TYPE_TIMEOUT,                1).% 世界BOSS结束类型--时间到 
-define(CONST_BOSS_END_TYPE_DEATH,                  2).% 世界BOSS结束类型--BOSS死亡 

-define(CONST_BOSS_HP_TAG_10,                       10).% boss血量--10% 
-define(CONST_BOSS_HP_TAG_30,                       30).% boss血量--30% 
-define(CONST_BOSS_HP_TAG_50,                       50).% boss血量--50% 
-define(CONST_BOSS_HP_TAG_70,                       70).% boss血量--70% 

-define(CONST_BOSS_STATE_OPEN,                      1).% 世界BOSS状态--开启 
-define(CONST_BOSS_STATE_START,                     2).% 世界BOSS状态--开始 
-define(CONST_BOSS_STATE_END,                       3).% 世界BOSS状态--结束 
-define(CONST_BOSS_STATE_CLOSE,                     4).% 世界BOSS状态--关闭 

-define(CONST_BOSS_ID_SY,                           10000).% 世界BOSSID--酸与 
-define(CONST_BOSS_ID_ZJ,                           10010).% 世界BOSSID--张角 
-define(CONST_BOSS_ID_ZL,                           10020).% 世界BOSSID--张梁 
-define(CONST_BOSS_ID_ZB,                           10030).% 世界BOSSID--张宝 

-define(CONST_BOSS_GOLD_RATE_1,                     10).% 1阶铜钱系数 
-define(CONST_BOSS_GOLD_RATE_2,                     20).% 2阶铜钱系数 
-define(CONST_BOSS_GOLD_RATE_3,                     30).% 3阶铜钱系数 
-define(CONST_BOSS_GOLD_RATE_4,                     40).% 4阶铜钱系数 
-define(CONST_BOSS_GOLD_RATE_5,                     50).% 5阶铜钱系数 
-define(CONST_BOSS_EXPER_RATE_1,                    100).% 1阶历练系数 
-define(CONST_BOSS_EXPER_RATE_2,                    200).% 2阶历练系数 
-define(CONST_BOSS_EXPER_RATE_3,                    300).% 3阶历练系数 
-define(CONST_BOSS_EXPER_RATE_4,                    400).% 4阶历练系数 
-define(CONST_BOSS_EXPER_RATE_5,                    500).% 5阶历练系数 
-define(CONST_BOSS_HURT_1,                          10000000).% 1阶伤害 
-define(CONST_BOSS_HURT_2,                          20000000).% 2阶伤害 
-define(CONST_BOSS_HURT_3,                          50000000).% 3阶伤害 
-define(CONST_BOSS_HURT_4,                          100000000).% 4阶伤害 

-define(CONST_BOSS_ROBOT_ATOM,                      robot_boss_interval).% 妖魔破机器人心跳id 
-define(CONST_BOSS_ROBOT_INTERVAL_SEC,              1).% 妖魔破机器人心跳时间 

-define(CONST_BOSS_ROBOT_STATE_INIT,                1).% 机器人状态--初始 
-define(CONST_BOSS_ROBOT_STATE_INIT_AFTER,          2).% 机器人状态--初始化后 
-define(CONST_BOSS_ROBOT_STATE_FIGHTING,            3).% 机器人状态--战斗中 
-define(CONST_BOSS_ROBOT_STATE_DEATH,               4).% 机器人状态--死亡中 
-define(CONST_BOSS_ROBOT_STATE_NORMAL,              5).% 机器人状态--正常 
-define(CONST_BOSS_ROBOT_STATE_MOVING,              6).% 机器人状态--移动中 
-define(CONST_BOSS_ROBOT_STATE_ERROR,               7).% 机器人状态--异常 
-define(CONST_BOSS_ROBOT_STATE_ENC,                 8).% 机器人状态--鼓舞中 

-define(CONST_BOSS_LV_PHASE,                        [{0,32},{33,39},{40,49},{50,59},{60,69},{70,79},{80,100}]).% 等级段 
-define(CONST_BOSS_MAX_MEMBER,                      75).% 房间人数上限 

%% ==========================================================
%% 课程表
%% ==========================================================
-define(CONST_SCHEDULE_CONTINUOUS,                  1).% 连续签到礼品 
-define(CONST_SCHEDULE_ACCUMULATIVE,                2).% 累计签到礼品 
-define(CONST_SCHEDULE_LIVENESS,                    3).% 活跃度礼品 

-define(CONST_SCHEDULE_NOT_RETRIEVE,                0).% 日常指引：不可找回 
-define(CONST_SCHEDULE_RETRIEVE,                    1).% 日常指引：可找回 

-define(CONST_SCHEDULE_ACTIVITY,                    1).% 日常活动 
-define(CONST_SCHEDULE_GUIDE,                       2).% 日常指引 

-define(CONST_SCHEDULE_ACTIVITY_EARLY_SPRING,       10001).% 骊山汤 
-define(CONST_SCHEDULE_ACTIVITY_EARLY_BOSS,         10002).% 妖魔破 
-define(CONST_SCHEDULE_ACTIVITY_EARLY_MULTI_ARENA,  10003).% 战群雄 
-define(CONST_SCHEDULE_ACTIVITY_EARLY_INVASION,     10004).% 异民族 
-define(CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,  10005).% 军团宴会 
-define(CONST_SCHEDULE_ACTIVITY_SINGLE_BATTLE,      10006).% 群雄逐鹿 
-define(CONST_SCHEDULE_ACTIVITY_MULTI_BATTLE,       10007).% 团队跨服战 
-define(CONST_SCHEDULE_ACTIVITY_LATE_SPRING,        10008).% 骊山汤 
-define(CONST_SCHEDULE_ACTIVITY_LATE_MULTI_ARENA,   10009).% 战群雄 
-define(CONST_SCHEDULE_ACTIVITY_LATE_BOSS,          10010).% 妖魔破 
-define(CONST_SCHEDULE_ACTIVITY_CAPTURE_FLAG,       10011).% 斩将夺旗 
-define(CONST_SCHEDULE_ACTIVITY_GUILD_LEGEND,       10012).% 军团传奇-战辽东 
-define(CONST_SCHEDULE_ACTIVITY_SINGLE_ARENA,       10013).% 一骑讨 
-define(CONST_SCHEDULE_ACTIVITY_MULTI_COPY,         10014).% 团队战场 
-define(CONST_SCHEDULE_ACTIVITY_COMMERCE,           10015).% 商路 
-define(CONST_SCHEDULE_ACTIVITY_TOWER,              10016).% 破阵 
-define(CONST_SCHEDULE_ACTIVITY_FACTION,            10017).% 大演武 
-define(CONST_SCHEDULE_ACTIVITY_LATE_INVASION,      10018).% 异民族 
-define(CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY,   10019).% 军团宴会 
-define(CONST_SCHEDULE_ACTIVITY_LATE_BOSS_2,        10020).% 妖魔破 
-define(CONST_SCHEDULE_ACTIVITY_LATE_BOSS_3,        10030).% 妖魔破 
-define(CONST_SCHEDULE_ACTIVITY_WORLD,              10031).% 乱天下 

-define(CONST_SCHEDULE_GUIDE_DAILY_LOGIN,           10001).% 每日登陆 
-define(CONST_SCHEDULE_GUIDE_WORLD_CHAT,            10002).% 世界频道喊话 
-define(CONST_SCHEDULE_GUIDE_SINGLE_COPY,           10003).% 普通战场 
-define(CONST_SCHEDULE_GUIDE_FIGURE_TRAIN,          10004).% 人物培养 
-define(CONST_SCHEDULE_GUIDE_SPRING,                10005).% 进入骊山汤 
-define(CONST_SCHEDULE_GUIDE_BOSS,                  10006).% 参与妖魔破 
-define(CONST_SCHEDULE_GUIDE_TOWER,                 10007).% 破阵 
-define(CONST_SCHEDULE_GUIDE_SINGLE_ARENA,          10008).% 一骑讨 
-define(CONST_SCHEDULE_GUIDE_MULTI_ARENA,           10009).% 战群雄 
-define(CONST_SCHEDULE_GUIDE_SINGLE_PRACTICE,       10010).% 成功单修 
-define(CONST_SCHEDULE_GUIDE_ELITE_COPY,            10011).% 英雄战场 
-define(CONST_SCHEDULE_GUIDE_GUILD_TASK,            10012).% 军团任务 
-define(CONST_SCHEDULE_GUIDE_GUILD_PARTY,           10013).% 军团宴会 
-define(CONST_SCHEDULE_GUIDE_HOME_PLANT,            10014).% 家园种植 
-define(CONST_SCHEDULE_GUIDE_MIND,                  10015).% 祈天 
-define(CONST_SCHEDULE_GUIDE_RUNE,                  10016).% 收夺 
-define(CONST_SCHEDULE_GUIDE_COMMERCE_CARRY,        10017).% 商路 
-define(CONST_SCHEDULE_GUIDE_COMMERCE_ESCORT,       10018).% 商路护送 
-define(CONST_SCHEDULE_GUIDE_COMMERCE_ROB,          10019).% 商路拦截 
-define(CONST_SCHEDULE_GUIDE_MULTI_COPY,            10020).% 团队战场 
-define(CONST_SCHEDULE_GUIDE_INVASION,              10021).% 异民族 
-define(CONST_SCHEDULE_GUIDE_WORLD,                 10022).% 乱天下 
-define(CONST_SCHEDULE_GUIDE_CAMP_PVP,              10023).% 阵营战 

-define(CONST_SCHEDULE_ONE,                         1).% 星期一/每月一号 
-define(CONST_SCHEDULE_TIME_BOUNDARY,               16).% 时间分界线 

-define(CONST_SCHEDULE_REVIEW_SUM,                  10).% 补签金额 

-define(CONST_SCHEDULE_PLAY_SINGLE_COPY,            1).% 每日军情玩法--扫荡副本 
-define(CONST_SCHEDULE_PLAY_CYCLE_TASK,             2).% 每日军情玩法--日常任务 
-define(CONST_SCHEDULE_PLAY_COMMERCE_CARRY,         3).% 每日军情玩法--商路派遣 
-define(CONST_SCHEDULE_PLAY_BOSS,                   4).% 每日军情玩法--妖魔破 
-define(CONST_SCHEDULE_PLAY_SINGLE_ARENA,           5).% 每日军情玩法--一骑讨 
-define(CONST_SCHEDULE_PLAY_WORLD,                  6).% 每日军情玩法--乱天下 
-define(CONST_SCHEDULE_PLAY_SPRING,                 7).% 每日军情玩法--骊山汤 
-define(CONST_SCHEDULE_PLAY_HOME,                   8).% 每日军情玩法--封邑仕女互动 
-define(CONST_SCHEDULE_PLAY_RESOURCE_RUNE,          9).% 每日军情玩法--收夺 
-define(CONST_SCHEDULE_PLAY_GUILD_COMMERCE,         10).% 每日军情玩法--军团商路 
-define(CONST_SCHEDULE_PLAY_AREA_PVP,               11).% 每日军情玩法--战群雄 
-define(CONST_SCHEDULE_PLAY_RESOURCE_PRAY,          12).% 每日军情玩法--巡城 
-define(CONST_SCHEDULE_PLAY_CAMP_BATTLE,            13).% 每日军情玩法--大演武 
-define(CONST_SCHEDULE_PLAY_MCOPY,                  14).% 每日军情玩法--团队战场 
-define(CONST_SCHEDULE_PLAY_GUILD_DONATE,           15).% 每日军情玩法--军团贡献 
-define(CONST_SCHEDULE_PLAY_SEIZE,                  16).% 每日军情玩法--斩将夺旗 
-define(CONST_SCHEDULE_PLAY_GUILD_TASK,             17).% 每日军情玩法--军团任务 
-define(CONST_SCHEDULE_PLAY_INVASION,               18).% 每日军情玩法--异民族 
-define(CONST_SCHEDULE_PLAY_TOWER,                  20).% 每日军情玩法--破阵免费重置次数 
-define(CONST_SCHEDULE_PLAY_PARTNER_LOOKFOR,        24).% 每日军情玩法--招贤馆 
-define(CONST_SCHEDULE_PLAY_ELIT_COPY,              25).% 每日军情玩法--精英战场 
-define(CONST_SCHEDULE_PLAY_GROUP,                  26).% 每日军情玩法--掠阵 
-define(CONST_SCHEDULE_PLAY_BUY_SP,                 28).% 每日军情玩法--购买体力 
-define(CONST_SCHEDULE_PLAY_GUILD_PARTY,            29).% 每日军情玩法--军团宴会 
-define(CONST_SCHEDULE_PLAY_MIND,                   31).% 每日军情玩法--祈天 
-define(CONST_SCHEDULE_PLAY_TRAIN,                  32).% 每日军情玩法--培养 
-define(CONST_SCHEDULE_PLAY_CULTIVATE,              33).% 每日军情玩法--修为 
-define(CONST_SCHEDULE_PLAY_MOUNT,                  37).% 每日军情玩法--坐骑免费次数 
-define(CONST_SCHEDULE_PLAY_PARTNER_ASSIST,         38).% 每日军情玩法--副将 
-define(CONST_SCHEDULE_PLAY_COMMERCE_ROB,           44).% 每日军情玩法--商路拦截 
-define(CONST_SCHEDULE_PLAY_COLLECT,                47).% 每日军情玩法--荆楚泽地 
-define(CONST_SCHEDULE_PLAY_FREE_RUNE,              50).% 每日军情玩法--收夺免费次数 
-define(CONST_SCHEDULE_PLAY_ELITE_COPY_RESET,       51).% 每日军情玩法--英雄战场重置次数 
-define(CONST_SCHEDULE_PLAY_TOWER_CASH_RESET,       53).% 每日军情玩法--破阵元宝重置次数 
-define(CONST_SCHEDULE_PLAY_SHUANGLU,               54).% 每日军情玩法--双陆次数 
-define(CONST_SCHEDULE_PLAY_SHOOT,                  55).% 每日军情玩法--射箭次数 
-define(CONST_SCHEDULE_PLAY_GCLD,                   56).% 每日军情玩法--攻城略地次数 
-define(CONST_SCHEDULE_PLAY_JTDC,                   57).% 每日军情玩法--军团夺城次数 

-define(CONST_SCHEDULE_POWER_TYPE_TOTAL,            1).% 战力类型--总战力 
-define(CONST_SCHEDULE_POWER_TYPE_BASE,             2).% 战力类型--基础属性 
-define(CONST_SCHEDULE_POWER_TYPE_EQUIP,            3).% 战力类型--装备 
-define(CONST_SCHEDULE_POWER_TYPE_FASHION,          4).% 战力类型--时装 
-define(CONST_SCHEDULE_POWER_TYPE_HORSE,            5).% 战力类型--坐骑 
-define(CONST_SCHEDULE_POWER_TYPE_MIND,             6).% 战力类型--星斗 
-define(CONST_SCHEDULE_POWER_TYPE_WEAPON,           7).% 战力类型--神兵 
-define(CONST_SCHEDULE_POWER_TYPE_ASSEMBLE,         8).% 战力类型--兵法 
-define(CONST_SCHEDULE_POWER_TYPE_CULTI,            9).% 战力类型--祭星 
-define(CONST_SCHEDULE_POWER_TYPE_POSITION,         10).% 战力类型--官职 
-define(CONST_SCHEDULE_POWER_TYPE_ABILITY,          11).% 战力类型--奇门 
-define(CONST_SCHEDULE_POWER_TYPE_GUILD,            12).% 战力类型--军团技能 
-define(CONST_SCHEDULE_POWER_TYPE_STONE,            13).% 战力类型--宝石 

-define(CONST_SCHEDULE_RESOURCE_BOSS,               1).% 找回资源--妖魔破 
-define(CONST_SCHEDULE_RESOURCE_SPRING,             2).% 找回资源--骊山汤 
-define(CONST_SCHEDULE_RESOURCE_PVP,                3).% 找回资源--战群雄 
-define(CONST_SCHEDULE_RESOURCE_PARTY,              4).% 找回资源--军团宴会 
-define(CONST_SCHEDULE_RESOURCE_CAMP,               5).% 找回资源--阵营战 
-define(CONST_SCHEDULE_RESOURCE_WORLD,              6).% 找回资源--乱天下 
-define(CONST_SCHEDULE_RESOURCE_MCOPY,              7).% 找回资源--团队战场 
-define(CONST_SCHEDULE_RESOURCE_INVISION,           8).% 找回资源--异民族 
-define(CONST_SCHEDULE_RESOURCE_COMMERCE,           9).% 找回资源--商路 
-define(CONST_SCHEDULE_RESOURCE_PRACTICE,           10).% 找回资源--修行 
-define(CONST_SCHEDULE_RESOURCE_HERO,               11).% 找回资源--英雄战场 
-define(CONST_SCHEDULE_RESOURCE_TOWER,              12).% 找回资源--破阵 

%% ==========================================================
%% 新手引导
%% ==========================================================
-define(CONST_GUIDE_FINISHED,                       1).% 已完成 
-define(CONST_GUIDE_OPENED,                         2).% 已开启，未完成 

-define(CONST_GUIDE_CAMP_EXT_LV,                    25).% 阵法的额外引导等级 
-define(CONST_GUIDE_CAMP_EXT_GUIDE_ID,              10014).% 阵法的额外引导id 

-define(CONST_GUIDE_TRAIN,                          10004).% 培养引导id 

%% ==========================================================
%% 怪物攻城
%% ==========================================================
-define(CONST_GUILD_SIEGE_GUILD_LV,                 3).% 军团等级 
-define(CONST_GUILD_SIEGE_PER_MON,                  5).% 每波怪物数量 
-define(CONST_GUILD_SIEGE_COUNTDOWN,                10).% 怪物刷新倒计时 
-define(CONST_GUILD_SIEGE_PLAYER_LV,                25).% 玩家等级 
-define(CONST_GUILD_SIEGE_DEAD_CD,                  30).% 战斗失败冷却时间 
-define(CONST_GUILD_SIEGE_PREPARATION,              60).% 准备时间 

-define(CONST_GUILD_SIEGE_INVITING,                 0).% 邀请状态：邀请中 
-define(CONST_GUILD_SIEGE_ACCEPT,                   1).% 邀请状态：冷却中 
-define(CONST_GUILD_SIEGE_REJECT,                   2).% 邀请状态：拒绝 

-define(CONST_GUILD_SIEGE_MON_HP_REFRESH,           5).% 刷新血条间隔 

-define(CONST_GUILD_SIEGE_GUILD_RANK,               3).% 军团排名 
-define(CONST_GUILD_SIEGE_PLAYER_RANK,              10).% 玩家排名 
-define(CONST_GUILD_SIEGE_RANK_REFRESH,             10).% 排名更新 

-define(CONST_GUILD_SIEGE_HURT2GOLD,                10).% 伤害转换铜钱 
-define(CONST_GUILD_SIEGE_BASE,                     30).% 伤害声望上限 
-define(CONST_GUILD_SIEGE_GOLD_BASE,                100).% 伤害铜钱基数 
-define(CONST_GUILD_SIEGE_HURT2,                    10000).% 伤害转换 

-define(CONST_GUILD_SIEGE_MAP,                      10000).% 怪物攻城地图 

-define(CONST_GUILD_SIEGE_EXIT,                     0).% 怪物攻城：离开 
-define(CONST_GUILD_SIEGE_ENTER,                    1).% 怪物攻城：进入 

-define(CONST_GUILD_SIEGE_QUIT,                     1).% 冷却时间类型：退出场景 
-define(CONST_GUILD_SIEGE_DEAD,                     2).% 冷却时间类型：战斗失败 

-define(CONST_GUILD_SIEGE_MAP_ID,                   38001).% 怪物攻城地图ID 
-define(CONST_GUILD_SIEGE_MON_ID,                   50001).% 怪物攻城怪物ID 

-define(CONST_GUILD_SIEGE_OTHER_QUOTA,              0).% 其他邀请名额数量 
-define(CONST_GUILD_SIEGE_ELDER_QUOTA,              1).% 督军邀请名额数量 
-define(CONST_GUILD_SIEGE_VICE_CHIEF_QUOTA,         2).% 副军团长邀请名额数量 
-define(CONST_GUILD_SIEGE_CHIEF_QUOTA,              3).% 军团长邀请名额数量 

-define(CONST_GUILD_SIEGE_INVITE_TIME,              30).% 发出邀请超时时间 
-define(CONST_GUILD_SIEGE_ACCEPT_TIME,              30).% 同意邀请超时时间 

-define(CONST_GUILD_SIEGE_FRIEND_INVITE,            0).% 好友关系：邀请中 
-define(CONST_GUILD_SIEGE_FRIEND_ACCEPT,            1).% 好友关系：同意 
-define(CONST_GUILD_SIEGE_FRIEND_REJECT,            2).% 好友关系：拒绝 

-define(CONST_GUILD_SIEGE_REPLY_ACCEPT,             0).% 好友回复：同意 
-define(CONST_GUILD_SIEGE_REPLY_REJECT,             1).% 好友回复：拒绝 
-define(CONST_GUILD_SIEGE_REPLY_TIMEOUT,            2).% 好友回复：超时 

-define(CONST_GUILD_SIEGE_MON_DISAPPEAR,            1).% 发起战斗失败：怪物不存在 
-define(CONST_GUILD_SIEGE_DEATH_CD,                 2).% 发起战斗失败：死亡CD 
-define(CONST_GUILD_SIEGE_EXIT_CD,                  3).% 发起战斗失败：退出CD 

-define(CONST_GUILD_SIEGE_SCORE_START,              0).% 积分开始 
-define(CONST_GUILD_SIEGE_BONUS_START,              0).% 犒赏三军开始 
-define(CONST_GUILD_SIEGE_HURT_START,               0).% 伤害开始 
-define(CONST_GUILD_SIEGE_MON_START,                1).% 第一波怪物 

-define(CONST_GUILD_SIEGE_PLAYER_FIRST,             1).% 玩家第一名 
-define(CONST_GUILD_SIEGE_PLAYER_SECOND,            2).% 玩家第二名 
-define(CONST_GUILD_SIEGE_PLAYER_FIRST_THREE,       3).% 玩家前三 
-define(CONST_GUILD_SIEGE_PLAYER_THIRD,             3).% 玩家第三名 

%% ==========================================================
%% 战斗进阶
%% ==========================================================
-define(CONST_AI_TYPE_TALK,                         1).% ai类型--冒泡说话 
-define(CONST_AI_TYPE_PLAY_CARTOON,                 2).% ai类型--播放动画 
-define(CONST_AI_TYPE_BUFF,                         3).% ai类型--buff增加删除 
-define(CONST_AI_TYPE_INIT_JOIN,                    4).% ai类型--战斗初始加入 
-define(CONST_AI_TYPE_JOIN,                         5).% ai类型--单位加入 
-define(CONST_AI_TYPE_QUIT,                         6).% ai类型--单位离开 
-define(CONST_AI_TYPE_SET_ANGER,                    7).% ai类型--设置怒气 
-define(CONST_AI_TYPE_SET_HP,                       8).% ai类型--设置生命值 
-define(CONST_AI_TYPE_PLUS_ATTR,                    9).% ai类型--增加战斗属性 
-define(CONST_AI_TYPE_SET_NO_ATTACK,                10).% ai类型--设置出手(不攻击) 
-define(CONST_AI_TYPE_FINISH_COPY,                  11).% ai类型--己方全死副本通关 
-define(CONST_AI_TYPE_SET_SEQ,                      12).% ai类型--设置出手顺序 
-define(CONST_AI_TYPE_MINUS_ATTR,                   13).% ai类型--降低战斗属性 
-define(CONST_AI_TYPE_ROUND_BATTLE,                 14).% ai类型--车轮战 
-define(CONST_AI_TYPE_FORBID_DODGE,                 15).% ai类型--禁止闪避 
-define(CONST_AI_TYPE_FORBID_PARRY,                 16).% ai类型--禁止格挡 
-define(CONST_AI_TYPE_JOIN_BY_PRO,                  17).% ai类型--按职业加入 
-define(CONST_AI_TYPE_SET_TARGET,                   18).% ai类型--设置攻击目标 
-define(CONST_AI_TYPE_INIT_ROUND,                   19).% ai类型--初始车轮战轮数 
-define(CONST_AI_TYPE_PLUS_ATTR_SERV,               20).% ai类型--增加战斗属性(前端不表现) 
-define(CONST_AI_TYPE_MINUS_ATTR_SERV,              21).% ai类型--降低战斗属性(前端不表现) 
-define(CONST_AI_SKILL_STUDY,                       23).% ai类型--学习技能 
-define(CONST_AI_TYPE_SET_ANGER_BY_PRO,             24).% ai类型--按职业满怒气 

-define(CONST_AI_START_LINKAGE,                     0).% 触发方式--联动触发 
-define(CONST_AI_START_NTH,                         1).% 触发方式--第几回合 
-define(CONST_AI_START_PER,                         2).% 触发方式--每几回合 
-define(CONST_AI_START_NTHTAIL,                     3).% 触发方式--第几回合后每回合 
-define(CONST_AI_START_ATTR_HP,                     4).% 触发方式--hp达到% 
-define(CONST_AI_START_ATTR_ANGER,                  5).% 触发方式--怒气改变后达到% 
-define(CONST_AI_START_DIE,                         6).% 触发方式--死亡 
-define(CONST_AI_START_INIT_BATTLE,                 7).% 触发方式--战斗初始化 
-define(CONST_AI_START_ATTACK,                      8).% 触发方式--出手触发 
-define(CONST_AI_START_UNITS_CHANGE,                9).% 触发方式--人数变化 

-define(CONST_AI_TRIGGER_INIT,                      1).% 触发点--初始化战斗 
-define(CONST_AI_TRIGGER_BOUT_FRONT,                2).% 触发点--回合刷新前 
-define(CONST_AI_TRIGGER_CHANGE,                    3).% 触发点--(生命，怒气等改变) 
-define(CONST_AI_TRIGGER_SET_SEQ,                   4).% 触发点--初始化出手顺序 
-define(CONST_AI_TRIGGER_RIGHT_DEATH,               5).% 触发点--怪物全死光 
-define(CONST_AI_TRIGGER_COPY_OVER,                 6).% 触发点--副本结束 
-define(CONST_AI_TRIGGER_BOUT_BACK,                 7).% 触发点--回合刷新后 

-define(CONST_AI_VALUE_TYPE_1,                      1).% 值类型--百分比 
-define(CONST_AI_VALUE_TYPE_2,                      2).% 值类型--值 

%% ==========================================================
%% 多人副本
%% ==========================================================
-define(CONST_MCOPY_ATYPE_Q,                        1).% 奇遇 
-define(CONST_MCOPY_ATYPE_MCOPY,                    2).% 副本 
-define(CONST_MCOPY_ATYPE_VIP,                      3).% vip 
-define(CONST_MCOPY_ATYPE_CASH,                     4).% 元宝 

-define(CONST_MCOPY_Q_MON,                          1).% 奇遇--遇怪 
-define(CONST_MCOPY_Q_GOODS,                        2).% 奇遇--道具 
-define(CONST_MCOPY_Q_COIN,                         3).% 奇遇--铜钱 
-define(CONST_MCOPY_Q_EXP,                          4).% 奇遇--经验 
-define(CONST_MCOPY_Q_MER,                          5).% 奇遇--功勋 
-define(CONST_MCOPY_Q_BUFF,                         6).% 奇遇--buff 

-define(CONST_MCOPY_VIP_REWARD,                     5).% VIP翻牌消费 

-define(CONST_MCOPY_SER1,                           1).% 多人副本系列1 
-define(CONST_MCOPY_SER2,                           2).% 多人副本系列2 
-define(CONST_MCOPY_SER3,                           3).% 多人副本系列3 
-define(CONST_MCOPY_SER4,                           4).% 多人副本系列4 
-define(CONST_MCOPY_SER5,                           5).% 多人副本系列5 

-define(CONST_MCOPY_BUFF1,                          5).% buffer加成比分子 
-define(CONST_MCOPY_BUFF2,                          10).% buffer加成比分子 
-define(CONST_MCOPY_BUFF3,                          15).% buffer加成比分子 
-define(CONST_MCOPY_BUFF4,                          20).% buffer加成比分子 

-define(CONST_MCOPY_ENTER_MAX,                      3).% 多人副本进入次数 

%% ==========================================================
%% 开启模块
%% ==========================================================
-define(CONST_MODULE_FIGURE,                        0).% 人物 
-define(CONST_MODULE_TASK,                          10).% 任务 
-define(CONST_MODULE_SHIZHUANG,                     15).% 时装 
-define(CONST_MODULE_COPY,                          20).% 副本 
-define(CONST_MODULE_MALL,                          30).% 商城 
-define(CONST_MODULE_SKILL,                         40).% 武技 
-define(CONST_MODULE_BAG,                           50).% 包裹 
-define(CONST_MODULE_STRENGTH,                      60).% 强化 
-define(CONST_MODULE_ZIDONGZHANDOU,                 62).% 自动战斗 
-define(CONST_MODULE_TRAIN,                         70).% 培养 
-define(CONST_MODULE_ABILITY,                       80).% 奇门 
-define(CONST_MODULE_HORSE,                         85).% 坐骑 
-define(CONST_MODULE_MAIL,                          90).% 雁书 
-define(CONST_MODULE_RELATIONSHIP,                  100).% 好友 
-define(CONST_MODULE_ZHUFUPING,                     103).% 祝福瓶 
-define(CONST_MODULE_POSITION,                      110).% 官衔 
-define(CONST_MODULE_RONGYU,                        130).% 成就称号 
-define(CONST_MODULE_CAMP,                          140).% 阵法 
-define(CONST_MODULE_HOME,                          141).% 封邑 
-define(CONST_MODULE_ZHUANGBEIBAOSHI,               145).% 装备宝石 
-define(CONST_MODULE_DEPOT,                         150).% 仓库 
-define(CONST_MODULE_CULTIVATION,                   160).% 修行 
-define(CONST_MODULE_QIDIANZHUANXIANG,              166).% 起点专享 
-define(CONST_MODULE_RANK,                          170).% 排行榜 
-define(CONST_MODULE_PRACTICE,                      190).% 修炼 
-define(CONST_MODULE_INHERIT,                       200).% 继承 
-define(CONST_MODULE_QUNYINGHUI,                    203).% 群英会 
-define(CONST_MODULE_ZHAOXIANGUAN,                  205).% 招贤馆 
-define(CONST_MODULE_RICHANGHUODONG,                210).% 日常活动 
-define(CONST_MODULE_SPRING,                        220).% 骊山汤 
-define(CONST_MODULE_BAOSHIHECHENG,                 222).% 宝石合成 
-define(CONST_MODULE_BAOSHIZHUANHUAN,               225).% 宝石转换 
-define(CONST_MODULE_RAID,                          235).% 扫荡 
-define(CONST_MODULE_GUILD,                         240).% 军团 
-define(CONST_MODULE_JUNTUANGONGXIAN,               241).% 军团贡献 
-define(CONST_MODULE_BOSS,                          250).% 妖魔破 
-define(CONST_MODULE_RUNE,                          260).% 收夺 
-define(CONST_MODULE_FACTION,                       270).% 阵营战 
-define(CONST_MODULE_ZUOQIXILIAN,                   272).% 坐骑洗炼 
-define(CONST_MODULE_ZUOQIHUANXING,                 275).% 坐骑幻形 
-define(CONST_MODULE_SOUL,                          280).% 刻印 
-define(CONST_MODULE_SINGLEARENA,                   285).% 一骑讨 
-define(CONST_MODULE_PRAY,                          300).% 巡城 
-define(CONST_MODULE_MULTIARENA,                    305).% 战群雄 
-define(CONST_MODULE_SIRENZHAN,                     311).% 四人战 
-define(CONST_MODULE_SCHEDULE,                      321).% 每日军情 
-define(CONST_MODULE_GUANFURENWU,                   322).% 官府任务 
-define(CONST_MODULE_DAILYTASK,                     340).% 日常循环任务 
-define(CONST_MODULE_KUAFUJINGJI,                   348).% 跨服竞技 
-define(CONST_MODULE_YIMINZU,                       350).% 异民族一 
-define(CONST_MODULE_MIND,                          360).% 祈天 
-define(CONST_MODULE_TOWER,                         365).% 破阵 
-define(CONST_MODULE_COMMERCE,                      370).% 商路 
-define(CONST_MODULE_FURNACE,                       380).% 锻造 
-define(CONST_MODULE_ELITECOPY,                     382).% 精英副本 
-define(CONST_MODULE_MCOPY1,                        390).% 团队战场一 
-define(CONST_MODULE_MARKET,                        400).% 市集 
-define(CONST_MODULE_COLLECT,                       410).% 采集 
-define(CONST_MODULE_PARTNER,                       431).% 副将 
-define(CONST_MODULE_INVASION1,                     440).% 异民族二 
-define(CONST_MODULE_MCOPY2,                        450).% 团队战场二 
-define(CONST_MODULE_MCOPY3,                        460).% 团队战场三 
-define(CONST_MODULE_SHENBING,                      462).% 神兵 
-define(CONST_MODULE_SHUANGLU,                      465).% 双陆 
-define(CONST_MODULE_INVASION2,                     470).% 异民族三 
-define(CONST_MODULE_GROUP,                         480).% 掠阵 
-define(CONST_MODULE_MCOPY4,                        490).% 团队战场四 
-define(CONST_MODULE_ZHUANGBEISHENGJIE,             495).% 装备升阶 
-define(CONST_MODULE_INVASION3,                     500).% 异民族四 
-define(CONST_MODULE_MCOPY5,                        510).% 团队战场五 
-define(CONST_MODULE_YIMINZU4,                      520).% 异民族五 
-define(CONST_MODULE_TUANDUIZHANCHANG6,             530).% 团队战场六 
-define(CONST_MODULE_TUANDUIZHANCHANG7,             540).% 团队战场七 
-define(CONST_MODULE_YIMINZU5,                      550).% 异民族六 
-define(CONST_MODULE_WUJIANG,                       560).% 武将 
-define(CONST_MODULE_ZHENFASHENGJI,                 570).% 阵法升级 
-define(CONST_MODULE_YUANBAOXUNFANG,                580).% 武将元宝寻访 
-define(CONST_MODULE_HEMOUBINGFA,                   590).% 合谋兵法 
-define(CONST_MODULE_SHINVYUAN,                     600).% 仕女苑 
-define(CONST_MODULE_SKIP_BATTLE,                   610).% 跳过战斗 
-define(CONST_MODULE_ZUOQIPEIYANG,                  620).% 坐骑培养 
-define(CONST_MODULE_SANRENSHANGZHEN,               630).% 三人上阵 
-define(CONST_MODULE_TUBIAOYOUHUA,                  640).% 图标优化 
-define(CONST_MODULE_YIMINZU7,                      650).% 异民族七 
-define(CONST_MODULE_TUANDUIZHANCHANG8,             660).% 团队战场八 
-define(CONST_MODULE_YIMINZU8,                      670).% 异民族八 
-define(CONST_MODULE_TUANDUIZHANCHANG9,             680).% 团队战场九 
-define(CONST_MODULE_YIMINZU9,                      690).% 异民族九 
-define(CONST_MODULE_TUANDUIZHANCHANG10,            700).% 团队战场十 
-define(CONST_MODULE_YIMINZU10,                     710).% 异民族十 
-define(CONST_MODULE_TUANDUIZHANCHANG11,            720).% 团队战场十一 
-define(CONST_MODULE_YUANMENSHEJI,                  730).% 辕门射戟 
-define(CONST_MODULE_GONGCHENGLVEDI,                740).% 攻城掠地 
-define(CONST_MODULE_ZHIJIZHIBI,                    750).% 知己知彼 
-define(CONST_MODULE_JIANGHUN,                      760).% 将魂 
-define(CONST_MODULE_QINGMEIZHUJIU,                 770).% 青梅煮酒 
-define(CONST_MODULE_LUANTIANXIA,                   1010).% 乱天下 
-define(CONST_MODULE_ZHANJIANGDUOQI,                1020).% 斩将夺旗 
-define(CONST_MODULE_JUNTUANYANHUI,                 1030).% 军团宴会 
-define(CONST_MODULE_QUNXIONGZHULU,                 1040).% 群雄逐鹿 
-define(CONST_MODULE_JINGCAIHUODONG,                1050).% 精彩活动 
-define(CONST_MODULE_LIANXUZAIXIAN,                 1060).% 连续在线 
-define(CONST_MODULE_CHENGZHANGLIBAO,               1070).% 成长礼包 
-define(CONST_MODULE_MEIRIVIP,                      1080).% 每日VIP 
-define(CONST_MODULE_LINGQUJIANGLI,                 1090).% 领取奖励 
-define(CONST_MODULE_LIANXUDENGLU,                  1100).% 连续登陆 
-define(CONST_MODULE_LIXIANLIBAO,                   1110).% 离线礼包 
-define(CONST_MODULE_DAOJUHECHENG,                  1120).% 道具合成 
-define(CONST_MODULE_MEIRIFENGLU,                   1130).%  每日俸禄 
-define(CONST_MODULE_SHOUCANGLIBAO,                 1140).% 收藏礼包 
-define(CONST_MODULE_SHOUJILIBAO,                   1150).% 手机礼包 
-define(CONST_MODULE_DENGLUJIANGLI,                 1160).% 登陆奖励 
-define(CONST_MODULE_SHOUFUYUYUE,                   1170).% 首服预约 
-define(CONST_MODULE_SHOUCHONGLIBAO,                1180).% 首充礼包 
-define(CONST_MODULE_HUODONGLIBAO,                  1190).% 活动礼包 
-define(CONST_MODULE_SHOUFUHUODONG,                 1200).% 首服活动 
-define(CONST_MODULE_XIAMOLIBAO,                    1220).% 夏末礼包 
-define(CONST_MODULE_WEIWUBINGFA,                   1230).% 威武兵法 
-define(CONST_MODULE_CHONGZHISONGLI,                1240).% 充值送礼 
-define(CONST_MODULE_XIAOFEISONGLI,                 1250).% 消费送礼 
-define(CONST_MODULE_HUIKUIZENGLI,                  1260).% 回馈赠礼 
-define(CONST_MODULE_CHONGZHIZENGLI,                1270).% 充值赠礼 
-define(CONST_MODULE_XIAOFEIZENGLI,                 1280).% 消费赠礼 
-define(CONST_MODULE_HUANGTUFENGYAN,                1290).% 皇图烽烟 
-define(CONST_MODULE_JINQIUSONGLI,                  1300).% 金秋送礼 
-define(CONST_MODULE_GUOQINGLIBAO,                  1310).% 国庆礼包 
-define(CONST_MODULE_ZAIZHANSHACHANG,               1350).% 再战沙场 
-define(CONST_MODULE_RONGYUBANG,                    1360).% 荣誉榜 
-define(CONST_MODULE_ZHAOCHAYOULI,                  1370).% 找茬有礼 
-define(CONST_MODULE_MIANFEICHONGZHI,               1380).% 免费充值 
-define(CONST_MODULE_TIANJIANGCAISHEN,              1390).% 天降财神 
-define(CONST_MODULE_ANQUANTEQUAN,                  1400).% 360特权 
-define(CONST_MODULE_CHAOJILIBAO,                   1410).% 超级礼包 
-define(CONST_MODULE_MEIRICHONGZHI,                 1420).% 每日充值 
-define(CONST_MODULE_TIYANYUANBAO,                  1430).% 体验元宝 
-define(CONST_MODULE_CHONGZHIFANHUAN,               1440).% 充值返还 
-define(CONST_MODULE_XUEYESHANGDENG,                1450).% 雪夜赏灯 
-define(CONST_MODULE_HUANLESHUANGDAN,               1460).% 欢乐双旦 
-define(CONST_MODULE_SHOUFUZHUANXIANG,              1470).% 首服专享 
-define(CONST_MODULE_SHENDAODIANJIANG,              1480).% 神刀点将 
-define(CONST_MODULE_SHOUJIBANGDING,                1490).% 手机绑定 
-define(CONST_MODULE_ZHUANFUSHENQING,               1500).% 转服申请 
-define(CONST_MODULE_RUYILIANGXIAO,                 1510).% 如意良宵 
-define(CONST_MODULE_YUNYOUSHANGREN,                1520).% 云游商人 
-define(CONST_MODULE_YUANBAOJIJIN,                  1530).% 元宝基金 
-define(CONST_MODULE_CHUNJIEHUODONG,                1540).% 春节活动 
-define(CONST_MODULE_CHONGZHIZHUANPAN,              1550).% 充值转盘 
-define(CONST_MODULE_MEIRIFULI,                     1560).% 每日福利 
-define(CONST_MODULE_FUBAOCHUNGUI,                  1570).% 福报春归 
-define(CONST_MODULE_CHAOJIHUIYUAN,                 1580).% 超级会员 
-define(CONST_MODULE_HEFUHUODONG,                   1590).% 合服活动 
-define(CONST_MODULE_XIUXIANYIKE,                   1600).% 休闲一刻 
-define(CONST_MODULE_CHUNRIXUYU,                    1610).% 春日絮语 
-define(CONST_MODULE_KAIFUYOULI,                    1620).% 开服有礼 
-define(CONST_MODULE_ZHAOXIANGUAN2,                 1630).% 招贤馆2 
-define(CONST_MODULE_BAOSHIHECHENG2,                1640).% 宝石合成2 
-define(CONST_MODULE_CUXIAOSHANGCHENG,              1650).% 促销商城 
-define(CONST_MODULE_JIFENSHANGDIAN,                1660).% 积分商店 
-define(CONST_MODULE_HUANGLINGTANBAO,               1670).% 皇陵探宝 
-define(CONST_MODULE_BAIFUQINGDIAN,                 1680).% 百服庆典 
-define(CONST_MODULE_BAIFUFANLI,                    1690).% 百服返利 
-define(CONST_MODULE_CHONGZHIXIANLI,                1700).% 充值献礼 
-define(CONST_MODULE_DANBICHONGZHI,                 1710).% 单笔充值 

%% ==========================================================
%% 多人竞技场
%% ==========================================================
-define(CONST_ARENA_PVP_LV_LIMIT,                   20).% 等级限制 
-define(CONST_ARENA_PVP_COUNT,                      20).% 每天次数 
-define(CONST_ARENA_PVP_BATTLE_TIME,                20).% 匹配战斗时间 

-define(CONST_ARENA_PVP_LOST_HUFU,                  1).% 失败虎符 
-define(CONST_ARENA_PVP_LOST_SCORE,                 1).% 失败群雄积分 
-define(CONST_ARENA_PVP_DRAW_SCORE,                 2).% 打平群雄积分 
-define(CONST_ARENA_PVP_DRAW_HUFU,                  2).% 打平虎符 
-define(CONST_ARENA_PVP_WIN_HUFU,                   5).% 胜利虎符 
-define(CONST_ARENA_PVP_WIN_SOCRE,                  5).% 胜利群雄积分 

%% ==========================================================
%% 怪物
%% ==========================================================
-define(CONST_MONSTER_COMMON,                       0).% 普通怪 
-define(CONST_MONSTER_ELITE,                        1).% 精英怪 
-define(CONST_MONSTER_COMMON_BOSS,                  2).% 普通BOSS 
-define(CONST_MONSTER_WORLD_BOSS,                   3).% 世界BOSS 
-define(CONST_MONSTER_GUILD_SIEGE,                  50).% 怪物攻城 
-define(CONST_MONSTER_MCOPY,                        51).% 多人副本 
-define(CONST_MONSTER_INVASION,                     52).% 异民族 
-define(CONST_MONSTER_AI_NPC,                       53).% 战斗进阶NPC 

%% ==========================================================
%% 乱天下
%% ==========================================================
-define(CONST_WORLD_CD_REBORN,                      30).% 乱天下CD--死亡CD 
-define(CONST_WORLD_CD_EXIT,                        60).% 乱天下CD--退出CD 

-define(CONST_WORLD_INTERVAL_UPDATE_MONSTER,        2).% 乱天下间隔--更新怪物 
-define(CONST_WORLD_INTERVAL_RANK,                  5).% 乱天下间隔--更新排行榜 
-define(CONST_WORLD_INTERVAL_REFRESH_MONSTER,       5000).% 乱天下间隔--刷新怪物间隔 

-define(CONST_WORLD_REPLY_AGREE,                    1).% 回复邀请决定--同意 
-define(CONST_WORLD_REPLY_REJECT,                   2).% 回复邀请决定--拒绝 
-define(CONST_WORLD_REPLY_TIMEOUT,                  3).% 回复邀请决定--超时 

-define(CONST_WORLD_AUTO_COST,                      30).% 乱天下--替身参加 

%% ==========================================================
%% 系统设置
%% ==========================================================
-define(CONST_SET_CONST_SET_TXJ,                    41).% 同心结使用 
-define(CONST_SET_ZANGGU,                           42).% 战鼓使用 
-define(CONST_SET_HUOHUODAN,                        43).% 军团复活丹 
-define(CONST_SET_ZHANCHUJI,                        44).% 战车出击 
-define(CONST_SET_JIAGUCHENGMEN,                    45).% 加固城门 
-define(CONST_SET_GOUMAIZHANGGU,                    46).% 购买战鼓 
-define(CONST_SET_GOUMAIHHD,                        47).% 购买复活丹 



%% ==========================================================
%% 宴会
%% ==========================================================

%% ==========================================================
%% 活动图标
%% ==========================================================
-define(CONST_HUODONGTUBIAO_RICHANGHUODONG,         38).% 日常活动 

%% ==========================================================
%% 新服活动
%% ==========================================================
-define(CONST_NEW_SERV_STRENGTH,                    1).% 任一装备部位强化至千夫5星 
-define(CONST_NEW_SERV_CULTIVATION,                 2).% 祭星达到11 
-define(CONST_NEW_SERV_TRAIN_HORSE,                 3).% 坐骑培养至35级 
-define(CONST_NEW_SERV_MIND_GET,                    4).% 通过祈天获得一颗紫色及以上品质星斗 
-define(CONST_NEW_SERV_TOWER,                       5).% 破阵通过X层 
-define(CONST_NEW_SERV_POWER_PLAYER,                6).% 主角战力提升 
-define(CONST_NEW_SERV_POWER_PARTNER,               7).% 委托修为 
-define(CONST_NEW_SERV_LEVEL_UP,                    8).% 等级达成 
-define(CONST_NEW_SERV_VIP_LEVEL_UP,                9).% vip等级达成 
-define(CONST_NEW_SERV_PARTNER,                     10).% 获得武将 
-define(CONST_NEW_SERV_CONTINUE,                    11).% 在线得奖励 
-define(CONST_NEW_SERV_DEPOSIT,                     12).% 充值送包 
-define(CONST_NEW_SERV_CONSUME,                     13).% 累计消费 
-define(CONST_NEW_SERV_STONE,                       14).% 宝石合成 
-define(CONST_NEW_SERV_ABILITY,                     15).% 升级奇门 
-define(CONST_NEW_SERV_TRAIN,                       16).% 人物培养 
-define(CONST_NEW_SERV_FASHION,                     17).% 时装合成 
-define(CONST_NEW_SERV_CARRY,                       18).% 商路运送 
-define(CONST_NEW_SERV_REPEAT_CONSUME,              19).% 重复消费送道具 
-define(CONST_NEW_SERV_GOODS_TURN,                  20).% 道具抽奖 
-define(CONST_NEW_SERV_FINISH_DAILY,                21).% 完成日常 
-define(CONST_NEW_SERV_SINGLE_ARENA,                22).% 参加5次一骑讨 
-define(CONST_NEW_SERV_MIND,                        23).% 参加10次祈天 
-define(CONST_NEW_SERV_HOME_TASK,                   24).% 参加10次封邑任务 
-define(CONST_NEW_SERV_COMMERCES,                   25).% 完成两次商路 
-define(CONST_NEW_SERV_INVASION,                    26).% 完成1次异民族 
-define(CONST_NEW_SERV_GROUP,                       27).% 完成一次团队战场 
-define(CONST_NEW_SERV_FURNACE_STREN,               28).% 进行5次强化 
-define(CONST_NEW_SERV_RUNE,                        29).% 完成3次收夺 

-define(CONST_NEW_SERV_UNFIT,                       0).% 成就奖励状态--未达成 
-define(CONST_NEW_SERV_UNRECEIVE,                   1).% 成就奖励状态--未领取 
-define(CONST_NEW_SERV_RECEIVED,                    2).% 成就奖励状态--已领取 
-define(CONST_NEW_SERV_INVAL,                       3).% 成就奖励状态--已失效 

-define(CONST_NEW_SERV_TYPE_ACHIEVE,                1).% 活动类型--达成成就 
-define(CONST_NEW_SERV_TYPE_RANK,                   2).% 活动类型--排名 
-define(CONST_NEW_SERV_TYPE_DEPOSIT_RETURN,         3).% 活动类型--充值返利 
-define(CONST_NEW_SERV_TYPE_FIRST_DEPOSIT,          4).% 活动类型--首充 
-define(CONST_NEW_SERV_TYPE_STORAGE,                5).% 活动类型--生财宝箱 
-define(CONST_NEW_SERV_TYPE_ICON,                   6).% 活动类型--图标显示 
-define(CONST_NEW_SERV_TYPE_ZLPM,                   7).% 活动类型--战力排名 
-define(CONST_NEW_SERV_TYPE_JTPM,                   8).% 活动类型--军团排名 
-define(CONST_NEW_SERV_TYPE_PZPM,                   9).% 活动类型--破阵排名 

-define(CONST_NEW_SERV_PREFER_TIME_THREE,           3).% 活动持续时间--3天 
-define(CONST_NEW_SERV_PREFER_TIME_FIVE,            5).% 活动持续时间--5天 
-define(CONST_NEW_SERV_PREFER_TIME_SEVEN,           7).% 活动持续时间--7天 
-define(CONST_NEW_SERV_DAYS,                        7).% 活动持续时间 
-define(CONST_NEW_SERV_PREFER_TIME_FIFTEEN,         15).% 活动持续时间--15天 

-define(CONST_NEW_SERV_INTEREST_PER,                15).% 数字常量--存储利息百分比 
-define(CONST_NEW_SERV_FIRST_PER,                   50).% 数字常量--存储当日返回百分比 
-define(CONST_NEW_SERV_STORAGE,                     1000).% 数字常量--存储金额 

-define(CONST_NEW_SERV_POWER_EIGHT,                 80000).% 英雄榜-战力值8W 
-define(CONST_NEW_SERV_POWER_NINE,                  90000).% 英雄榜-战力值9W 
-define(CONST_NEW_SERV_POWER_TEN,                   100000).% 英雄榜-战力值10W 

-define(CONST_NEW_SERV_FIRST_LV,                    1).% 荣誉榜:第一个达到40级的玩家 
-define(CONST_NEW_SERV_FIRST_GUILD_LV,              2).% 荣誉榜：第一个将军团升级到4级的军团长 
-define(CONST_NEW_SERV_FIRST_RED_PARTNER,           3).% 荣誉榜：第一个获得红色武将的玩家 
-define(CONST_NEW_SERV_FIRST_HOST,                  4).% 荣誉榜：第一个将坐骑培养到40级的玩家 
-define(CONST_NEW_SERV_FIRST_TOWER_CLEARANCE,       5).% 荣誉榜：第一个在破阵中通关七月流火阵的玩家 
-define(CONST_NEW_SERV_FIRST_STONE,                 6).% 荣誉榜：第一个镶嵌满16颗4级宝石的玩家 
-define(CONST_NEW_SERV_FIRST_RED_STAR,              7).% 荣誉榜：第一个获得红色星斗的玩家 
-define(CONST_NEW_SERV_FIRST_FASHION,               8).% 荣誉榜：第一个穿戴5级时装的玩家 

-define(CONST_NEW_SERV_EXCHANGE_CASH,               1093000007).% 现金兑换令 
-define(CONST_NEW_SERV_EXCHANGE_GOODS,              1093000008).% 实物兑换令 

-define(CONST_NEW_SERV_TURN_COUNT,                  200).% 转盘--次数 
-define(CONST_NEW_SERV_TURN_CASH_SUM,               1000000).% 转盘--充值元宝数 

-define(CONST_NEW_SERV_HERO_CAMP_MIN,               30).% 英雄榜最低阵法id 

-define(CONST_NEW_SERV_GIRL_REWARD,                 1050405061).% 玲珑宝贝礼包 

-define(CONST_NEW_SERV_GLV_LIMIT_LOWER,             3).% 英雄榜军团最低等级 

%% ==========================================================
%% 道具店
%% ==========================================================
-define(CONST_SHOP_MAX_COUNT,                       12).% 最大数量 

-define(CONST_SHOP_SECRET_CHANGE,                   1).% 云游商人-刷新兑换积分 
-define(CONST_SHOP_SECRET_FREE,                     2).% 云游商人-免费可刷新次数 
-define(CONST_SHOP_SECRET_COUNT,                    9).% 云游商人-随机道具个数 
-define(CONST_SHOP_SECRET_REFRESH_COST,             10).% 云游商人-刷新一次花费 
-define(CONST_SHOP_SECRET_BUY_TIMES,                20).% 云游商人-可购买次数 
-define(CONST_SHOP_SECRET_LOG_COUNT,                20).% 云游商人-购买记录条数 

-define(CONST_SHOP_SECRET_UNABLE,                   0).% 云游商人-不可购买 
-define(CONST_SHOP_SECRET_ABLE,                     1).% 云游商人-可购买 

-define(CONST_SHOP_SECRET_BTYPE_GOLD,               1).% 云游商人-购买类型元宝 
-define(CONST_SHOP_SECRET_BTYPE_SCORE,              2).% 云游商人-购买类型积分 

%% ==========================================================
%% 阵营战
%% ==========================================================
-define(CONST_CAMP_PVP_START,                       1).% 阵营战开启 
-define(CONST_CAMP_PVP_CASH_TYPE_GOLD,              1).% 宝箱类型金 
-define(CONST_CAMP_PVP_END,                         2).% 阵营战结束 
-define(CONST_CAMP_PVP_CASH_TYPE_SILVER,            2).% 宝箱类型银 
-define(CONST_CAMP_PVP_OPEN,                        3).% 阵营战开放 
-define(CONST_CAMP_PVP_CASH_TYPE_COPPER,            3).% 宝箱类型铜 
-define(CONST_CAMP_PVP_CLOSE,                       4).% 阵营战关闭 
-define(CONST_CAMP_PVP_CASH_TYPE_IRON,              4).% 宝箱类型铁 
-define(CONST_CAMP_PVP_CONST_CAMP_PVP_PLAYER_STATE_TRAN,  5).% 运矿高级款 
-define(CONST_CAMP_PVP_KILL_BOSS,                   7).% 击杀炮塔奖励 

-define(CONST_CAMP_PVP_PLAYER_STATE_NORMAL,         0).% 处于正常状态 
-define(CONST_CAMP_PVP_PLAYER_STATE_DEAD,           1).% 处于死亡状态 
-define(CONST_CAMP_PVP_PLAYER_STATE_BATTLE,         2).% 战斗中 
-define(CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_LOW,  3).% 运框中 低级矿 
-define(CONST_CAMP_PVP_PLAYER_STATE_WORKING,        4).% 挖矿中 
-define(CONST_CAMP_PVP_PLAYER_STATE_TRANSPORT_HIGH,  5).% 运矿中 高级矿 
-define(CONST_CAMP_PVP_PLAYER_STATE_ATT_CAR,        6).% 攻击战车吟唱中 
-define(CONST_CAMP_PVP_PLAYER_STATE_FLY,            7).% 军团战状态飞行 

-define(CONST_CAMP_PVP_MONSTER_STATE_NORMOL,        0).% 怪物正常状态 
-define(CONST_CAMP_PVP_MONSTER_STATE_BATTLE,        1).% 怪物在战斗 
-define(CONST_CAMP_PVP_MONSTER_STATE_DEAD,          2).% 怪物死了 

-define(CONST_CAMP_PVP_CAMP_1,                      1).% 阵营1 
-define(CONST_CAMP_PVP_CAMP_2,                      2).% 阵营2 

-define(CONST_CAMP_PVP_RECOURCE_TYPE_NULL,          0).% 无矿石 
-define(CONST_CAMP_PVP_RECOURCE_TYPE_LOW,           1).% 低级矿石 
-define(CONST_CAMP_PVP_RECOURCE_TYPE_HIGH,          2).% 高级矿石 

-define(CONST_CAMP_PVP_AWARD_WIN,                   1).% 连胜奖励类型 
-define(CONST_CAMP_PVP_AWARD_BREAK_WIN,             2).% 终结连胜 
-define(CONST_CAMP_PVP_AWARD_RESOURCE,              3).% 低资源奖励 
-define(CONST_CAMP_PVP_AWARD_MONSTER,               4).% 高级资源奖励 
-define(CONST_CAMP_PVP_AWARD_CAMP_WIN,              5).% 胜利奖励 
-define(CONST_CAMP_PVP_AWARD_RANK,                  6).% 积分排名奖励 

-define(CONST_CAMP_PVP_BATTLE_TYPE_PVP,             1).% pvp战斗 
-define(CONST_CAMP_PVP_BATTLE_TYPE_PVM,             2).% 打怪 
-define(CONST_CAMP_PVP_BATTLE_TYPE_PVB,             3).% 打boss 

-define(CONST_CAMP_PVP_EVENT_MONSTER,               1).% 投放怪物 
-define(CONST_CAMP_PVP_EVENT_HP,                    2).% boss减少hp 

-define(CONST_CAMP_PVP_ENTER_CD,                    60).% 离开阵营战在进入cd 

-define(CONST_CAMP_PVP_RESOURCE_SCORE_LOW,          1).% 低级资源积分 
-define(CONST_CAMP_PVP_RESOURCE_SCORE_HIGH,         2).% 高级资源积分 

-define(CONST_CAMP_PVP_PK_CD_SECOND,                30).% 阵营战pkcd 

-define(CONST_CAMP_PVP_LV_PHASE,                    [{0,34},{35,42},{43,49},{50,59},{60,100}]).% 分组等级段 

%% ==========================================================
%% 常用音效
%% ==========================================================


%% ==========================================================
%% 神兵系统
%% ==========================================================
-define(CONST_WEAPON_REFRESH_TIMES,                 3).% 免费洗练次数 
-define(CONST_WEAPON_MAX_COUNT,                     4).% 神兵最大部位数 
-define(CONST_WEAPON_REBUILD_COST,                  20).% 淬火消耗 
-define(CONST_WEAPON_GOODS_CHS,                     1093000045).% 淬火石 

-define(CONST_WEAPON_IDX1,                          1).% 神兵部位--部位1 
-define(CONST_WEAPON_IDX2,                          2).% 神兵部位--部位2 
-define(CONST_WEAPON_IDX3,                          3).% 神兵部位--部位3 
-define(CONST_WEAPON_IDX4,                          4).% 神兵部位--部位4 

-define(CONST_WEAPON_CHESS_BUY_PUTTIMES,            5).% 双陆：每次购买次数 
-define(CONST_WEAPON_CHESS_PUT_TIMES,               8).% 双陆：每日投掷次数 
-define(CONST_WEAPON_CHESS_CD,                      10).% 双陆：冷却时间 
-define(CONST_WEAPON_CHESS_MAX_POS,                 34).% 双陆：最大格子数 
-define(CONST_WEAPON_CHESS_BUY_PUTTIMES_COST,       100).% 双陆：购买次数花费 
-define(CONST_WEAPON_CHESS_FIRST_POS_REWARD,        50000).% 双陆：经过第一个位置奖励铜钱 
-define(CONST_WEAPON_CHESS_GOODS_DICE_BAG,          1040907041).% 双陆：骰宝福袋 
-define(CONST_WEAPON_CHESS_GOODS_CONTROL,           1090700001).% 双陆：玲珑骰子(遥控) 
-define(CONST_WEAPON_CHESS_GOODS_DOUBLE,            1090700002).% 双陆：双骰子(遥控) 

%% ==========================================================
%% 战斗音效
%% ==========================================================


%% ==========================================================
%% 军团战
%% ==========================================================
-define(CONST_GUILD_PVP_STATE_ON,                   1).% 活动状态：开放 
-define(CONST_GUILD_PVP_BOSS_TYPE_WALL,             1).% boss类型-城墙 
-define(CONST_GUILD_PVP_SKILL_CAR_ATT,              1).% 技能类型- 战车出击 
-define(CONST_GUILD_PVP_STATE_START,                2).% 活动状态：开始 
-define(CONST_GUILD_PVP_BOSS_TYPE_BOSS,             2).% boss类型-雅典娜 
-define(CONST_GUILD_PVP_SKILL_FIX_WALL,             2).% 技能类型- 修复城墙 
-define(CONST_GUILD_PVP_STATE_OFF,                  3).% 活动状态：结束 
-define(CONST_GUILD_PVP_BOSS_TYPE_CAR,              3).% boss类型-战车 
-define(CONST_GUILD_PVP_STATE_READY,                4).% 活动状态：报名结束 
-define(CONST_GUILD_PVP_ATT_WALL_CD,                60).% 攻击城墙cd 
-define(CONST_GUILD_PVP_FIX_WALL_CD,                300).% 加固城墙cd 
-define(CONST_GUILD_PVP_NORMAL_MAP_ID,              41007).% 和平时地图 

-define(CONST_GUILD_PVP_CAMP_ATT,                   1).% 军团阵营:功方 
-define(CONST_GUILD_PVP_CAMP_DEF,                   2).% 军团阵营：防守方 

-define(CONST_GUILD_PVP_ENCOURAGE_MAX,              10).% 鼓舞次数上限 
-define(CONST_GUILD_PVP_BRING_BACK,                 100).% 复活话费 
-define(CONST_GUILD_PVP_ENCOURAGE_COST,             500).% 鼓舞话费 
-define(CONST_GUILD_PVP_PREPARE_LAST,               600).% 活动准备时间 
-define(CONST_GUILD_PVP_ENCOURAGE_PER,              1000).% 鼓舞每次增加攻击万分比 

-define(CONST_GUILD_PVP_ATTR_ITEM,                  1093000049).% 战鼓 
-define(CONST_GUILD_PVP_BRING_ITEM,                 1093000050).% 复活丹 

%% ==========================================================
%% 充值
%% ==========================================================
-define(CONST_DEPOSIT_USE_CASH_CARD,                90).% 充值:使用元宝卡 
-define(CONST_DEPOSIT_USE_CASH_OLD,                 91).% 体验服玩家送元宝 
-define(CONST_DEPOSIT_USER_CHANGE_SERVER,           92).% 移民资产转移，送元宝 

%% ==========================================================
%% 跨服竞技场
%% ==========================================================
-define(CONST_CROSS_ARENA_STATE_OFF,                0).% 竞技场界面状态-关闭 
-define(CONST_CROSS_ARENA_RANK_REWARD_TIME,         0).% 领取排行奖励的时间(0:00) 
-define(CONST_CROSS_ARENA_OK,                       0).% 成功 
-define(CONST_CROSS_ARENA_STATE_ON,                 1).% 竞技场界面状态-打开 
-define(CONST_CROSS_ARENA_WIN,                      1).% 胜利 
-define(CONST_CROSS_ARENA_ATTACK,                   1).% 挑战 
-define(CONST_CROSS_ARENA_ERROR,                    1).% 失败 
-define(CONST_CROSS_ARENA_LOSE,                     2).% 失败 
-define(CONST_CROSS_ARENA_DEF,                      2).% 被挑战 
-define(CONST_CROSS_ARENA_ATTACK_TIMES,             9).% 每日挑战次数 

-define(CONST_CROSS_ARENA_FAIL_SCORE,               5).% 失败获取积分 
-define(CONST_CROSS_ARENA_WIN_SCORE,                10).% 胜利获取积分 

-define(CONST_CROSS_ARENA_FIRST_PHASE,              1).% 天神一段 
-define(CONST_CROSS_ARENA_PHASE_SIX,                6).% 白银六段 
-define(CONST_CROSS_ARENA_PHASE_SEVEN,              7).% 黑铁七段 

-define(CONST_CROSS_ARENA_GROUP_UP_COUNT,           2).% 每组晋级人数 
-define(CONST_CROSS_ARENA_GROUP_DOWN_COUNT1,        4).% 前6段每组降级人数 
-define(CONST_CROSS_ARENA_GROUP_DOWN_COUNT2,        6).% 6段后每组降级人数 
-define(CONST_CROSS_ARENA_GROUP_COUNT,              10).% 每组人数 

-define(CONST_CROSS_ARENA_STATE_NORMAL,             0).% 人物跨服状态--正常 
-define(CONST_CROSS_ARENA_STATE_DELETE,             1).% 人物跨服状态--删号 

%% ==========================================================
%% 辕门射戟
%% ==========================================================
-define(CONST_ARCHERY_DICT_ACC,                     acc).% 字典：累积奖励 
-define(CONST_ARCHERY_DICT_NEW_COURT,               dict_new_court).% 字典：新靶场 
-define(CONST_ARCHERY_INSTRUCTION,                  3).% 新手引导次数 
-define(CONST_ARCHERY_SINGLE_HIT,                   5).% 单次击中 
-define(CONST_ARCHERY_G,                            5).% 重力加速度 
-define(CONST_ARCHERY_ARROW_PRICE,                  5).% 购买箭矢 
-define(CONST_ARCHERY_ARROW_COMMON,                 10).% 每天弓箭数量 
-define(CONST_ARCHERY_DOUBLE_HIT,                   20).% 双连击 
-define(CONST_ARCHERY_NEWCOURT_PRICE,               20).% 刷新靶场的元宝数 
-define(CONST_ARCHERY_TRI_HIT,                      40).% 三连击中 
-define(CONST_ARCHERY_LIMIT_BUY,                    50).% 购买次数限制 
-define(CONST_ARCHERY_RANGE,                        68).% 靶子直径 
-define(CONST_ARCHERY_FULL_HIT,                     80).% 四连击中 
-define(CONST_ARCHERY_ARROW_L,                      82).% 箭的长度 

%% ==========================================================
%% 攻城掠地
%% ==========================================================
-define(CONST_ENCROACH_MOVE_CONSUME,                1).% 每次移动消耗的移动力 
-define(CONST_ENCROACH_LOTTERY_TIMES,               1).% 可抽奖次数 
-define(CONST_ENCROACH_TIMES,                       2).% 每天玩法次数 
-define(CONST_ENCROACH_MOVING_FORCE,                8).% 初始移动力 
-define(CONST_ENCROACH_RANK_COUNT,                  10).% 排行榜数量 
-define(CONST_ENCROACH_BUY_M_FORCE_COST,            10).% 购买移动力花费 
-define(CONST_ENCROACH_CAN_BUY_M_FORCE,             16).% 可购买移动力 

-define(CONST_ENCROACH_EVENT_INIT,                  0).% 事件类型-初始位置 
-define(CONST_ENCROACH_EVENT_ARMORY,                1).% 事件类型-军械库 
-define(CONST_ENCROACH_EVENT_GRANARY,               2).% 事件类型-粮仓 
-define(CONST_ENCROACH_EVENT_VETERAN,               3).% 事件类型-精兵 
-define(CONST_ENCROACH_EVENT_GENERAL,               4).% 事件类型-大将 
-define(CONST_ENCROACH_EVENT_CAPITAL,               5).% 事件类型-都城 
-define(CONST_ENCROACH_EVENT_ERROR,                 6).% 事件类型-错误 

-define(CONST_ENCROACH_COUNT_CAPITAL,               1).% 事件数量-都城 
-define(CONST_ENCROACH_COUNT_INIT,                  1).% 事件数量-初始位置 
-define(CONST_ENCROACH_COUNT_GRANARY,               4).% 事件数量-粮仓 
-define(CONST_ENCROACH_COUNT_GENERAL,               4).% 事件数量-大将 
-define(CONST_ENCROACH_COUNT_VETERAN,               7).% 事件数量-精兵 
-define(CONST_ENCROACH_COUNT_ARMORY,                8).% 事件数量-军械库 

-define(CONST_ENCROACH_STATE_CLOSE,                 0).% 位置状态-未开启 
-define(CONST_ENCROACH_STATE_OPEN,                  1).% 位置状态-已开启 
-define(CONST_ENCROACH_STATE_PASS,                  2).% 位置状态-已通过 

%% ==========================================================
%% 雪夜赏灯
%% ==========================================================
-define(CONST_SNOW_TICKET_PER,                      200).% 消费元宝兑换抽奖点的比例 

%% ==========================================================
%% 滚服礼券
%% ==========================================================
-define(CONST_GUN_CASH_ADD_SERVER,                  1).% 滚服礼券服状态 积累服 
-define(CONST_GUN_CASH_SUB_SERVER,                  2).% 滚服礼券服状态 可领取服 
-define(CONST_GUN_CASH_OTHER_SERVER,                3).% 滚服礼券服状态 其他服 

-define(CONST_GUN_CASH_CASH_ACTIVE,                 5).% 滚服礼券服 活动获得礼券 

%% ==========================================================
%% 运营活动
%% ==========================================================
-define(CONST_YUNYING_ACTIVITY_RED_BAG,             16).% 春节红包活动 
-define(CONST_YUNYING_ACTIVITY_BLESS,               17).% 财神祝福活动 
-define(CONST_YUNYING_ACTIVITY_STONE_VALUE,         18).% 宝石积分活动 
-define(CONST_YUNYING_ACTIVITY_TXJ,                 19).% 元宵同心结 
-define(CONST_YUNYING_ACTIVITY_RIDDLE,              20).% 元宵灯谜活动 

-define(CONST_YUNYING_ACTIVITY_EXCHANGE,            13).% 物品兑换活动id 
-define(CONST_YUNYING_ACTIVITY_SPRING,              20).% 春联兑换活动id 
-define(CONST_YUNYING_ACTIVITY_TANGYUAN,            32).% 汤圆兑换活动id 

-define(CONST_YUNYING_ACTIVITY_GOD_CARDS,           3).% 神刀免费次数 

%% ==========================================================
%% 教学
%% ==========================================================
-define(CONST_TEACH_EQ_0,                           0).% 评价0 
-define(CONST_TEACH_EQ_1,                           1).% 评价1 
-define(CONST_TEACH_EQ_2,                           2).% 评价2 

-define(CONST_TEACH_TYPE_SKILL,                     1).% 类型--技能 
-define(CONST_TEACH_TYPE_CAMP,                      2).% 类型--阵法 
-define(CONST_TEACH_TYPE_PARTNER,                   3).% 类型--武将 

%% ==========================================================
%% 合服活动
%% ==========================================================
-define(CONST_MIXED_SERV_ACTIVITY_RECHARGE,         1).% 充值 
-define(CONST_MIXED_SERV_ACTIVITY_CONSUME,          2).% 消费 
-define(CONST_MIXED_SERV_ACTIVITY_POWER,            3).% 战力 
-define(CONST_MIXED_SERV_ACTIVITY_DEVIL,            4).% 破阵 
-define(CONST_MIXED_SERV_ACTIVITY_SINGLE_ARENA,     5).% 竞技场 
-define(CONST_MIXED_SERV_ACTIVITY_GUILD_POWER,      6).% 军团 
-define(CONST_MIXED_SERV_ACTIVITY_PLAYER_COUNT,     10).% 排名人数 
-define(CONST_MIXED_SERV_ACTIVITY_LOGIN,            34).% 合服登入礼包 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_RE,          35).% 合服充值活动 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_CO,          36).% 合服消费活动 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_POWER,       37).% 合服战力活动 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_DEVIL,       38).% 合服破阵活动 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_SA,          39).% 合服竞技场活动 
-define(CONST_MIXED_SERV_ACTIVITY_TIME_GUILD,       40).% 合服军团战力活动 

%% ==========================================================
%% 青梅煮酒
%% ==========================================================
-define(CONST_GAMBLE_ROOM_STATE_Q1,                 1).% room_state:房间少一人 
-define(CONST_GAMBLE_ROOM_STATE_NO_READY,           2).% room_state:房间满，无人准备 
-define(CONST_GAMBLE_ROOM_STATE_ONE_READY,          3).% room_state:房间满，一人准备 
-define(CONST_GAMBLE_ROOM_STATE_PLAYING,            4).% room_state:房间游戏中 
-define(CONST_GAMBLE_WIN_POINT,                     16).% 胜利需要的点数 
-define(CONST_GAMBLE_15_SECOND,                     17).% 15秒等待 

-define(CONST_GAMBLE_PLAYER_READY,                  1).% 玩家准备 
-define(CONST_GAMBLE_PLAYER_NOT_READY,              2).% 玩家未准备 
-define(CONST_GAMBLE_PLAYER_LOST,                   3).% 玩家离线 
-define(CONST_GAMBLE_PLAYER_ON,                     4).% 玩家游戏中 

-define(CONST_GAMBLE_21CARD_STATE_WIN,              1).% 21点状态 赢 
-define(CONST_GAMBLE_21CARD_STATE_LOSE,             2).% 21点状态 输 
-define(CONST_GAMBLE_21CARD_STATE_DRAW,             3).% 21点状态 平 
-define(CONST_GAMBLE_21CARD_STATE_GOING,            4).% 21点状态 进行中 

-define(CONST_GAMBLE_RED_H,                         0).% 牌的花色：红心 
-define(CONST_GAMBLE_RED_S,                         1).% 牌的花色：方片 
-define(CONST_GAMBLE_BLACK_H,                       2).% 牌的花色：黑桃 
-define(CONST_GAMBLE_BLACK_S,                       3).% 牌的花色：梅花 

%% ==========================================================
%% 将魂
%% ==========================================================
-define(CONST_PARTNER_SOUL_EXP,                     5).% 魂器经验 
-define(CONST_PARTNER_SOUL_STAR_OPEN_LEVEL,         10).% 将星开启等级 
-define(CONST_PARTNER_SOUL_STAR_MAX,                100).% 将星最高等级 
-define(CONST_PARTNER_SOUL_WARE,                    1093000047).% 魂器 
-define(CONST_PARTNER_SOUL_STONE,                   1093000048).% 将星石 

-define(CONST_PARTNER_SOUL_XZ,                      39115).% 将魂技:陷阵 
-define(CONST_PARTNER_SOUL_FJ,                      39119).% 将魂技:飞军 
-define(CONST_PARTNER_SOUL_TJ,                      39121).% 将魂技:天机 
-define(CONST_PARTNER_SOUL_KX,                      39124).% 将魂技:控弦 
-define(CONST_PARTNER_SOUL_GM,                      39127).% 将魂技:鬼谋 
-define(CONST_PARTNER_SOUL_JH,                      39132).% 将魂技:惊鸿 

%% ==========================================================
%% 运营活动2
%% ==========================================================
-define(CONST_ACT_ALLOW,                            1).% 平台限制--允许 
-define(CONST_ACT_DISALLOW,                         2).% 平台限制--不允许 

-define(CONST_ACT_NORMAL,                           1).% 活动时间--普通 
-define(CONST_ACT_OPEN,                             2).% 活动时间--开服 
-define(CONST_ACT_PLAN,                             3).% 活动时间--定时 
-define(CONST_ACT_MIX,                              4).% 活动时间--合服 

%% ==========================================================
%% 皇陵探宝
%% ==========================================================
-define(CONST_KB_TREASURE_OPEN_PLAT_LIST,           [0,1,2,3]).% 开放皇陵探宝的平台 
-define(CONST_KB_TREASURE_MULTI_TIMES,              20).% 多次转的次数 

-define(CONST_KB_TREASURE_SILVER_SINGLE,            10).% 白银单次花费 
-define(CONST_KB_TREASURE_GOLD_SINGLE,              50).% 黄金单次花费 
-define(CONST_KB_TREASURE_SILVER_TWENTY,            190).% 白银转20次花费 
-define(CONST_KB_TREASURE_GOLD_TWENTY,              950).% 黄金转20次花费 

-define(CONST_KB_TREASURE_TURN_LEVEL_ONE,           1).% 转盘档次：一档 
-define(CONST_KB_TREASURE_TURN_LEVEL_TWO,           2).% 转盘档次：二档 

-define(CONST_KB_TREASURE_TURN_TYPE_SINGLE,         0).% 转动次数类型：一次 
-define(CONST_KB_TREASURE_TURN_TYPE_MULTI,          1).% 转动次数类型：多次 

-define(CONST_KB_TREASURE_SINGLE_COUNT,             1).% 扣除道具数量：单次 
-define(CONST_KB_TREASURE_MULTI_COUNT,              19).% 扣除道具数量：20次 
-define(CONST_KB_TREASURE_GOODS1,                   1093000061).% 一档扣除道具 
-define(CONST_KB_TREASURE_GOODS2,                   1093000062).% 二档扣除道具 

%% ==========================================================
%% 百服庆典
%% ==========================================================
-define(CONST_HUNDRED_SERV_RECHARGE,                44).% 百服庆典（第100服） 
-define(CONST_HUNDRED_SERV_REFUND,                  45).% 百服庆典：充值返利 

%% ==========================================================
%% 闯关比赛
%% ==========================================================
-define(CONST_MATCH_COPY_RANK_MAX,                  3).% 关卡排行榜数量 
-define(CONST_MATCH_FREE_TIMES,                     3).% 免费参加次数 
-define(CONST_MATCH_COST_GOLD,                      10).% 付费参加花费 
-define(CONST_MATCH_RANK_MAX,                       100).% 排行榜数量 

