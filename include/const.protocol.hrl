%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% sys  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SYS,                 1000). % 系统预留
-define(MODULE_PACKET_SYS,               sys_packet). 
-define(MODULE_HANDLER_SYS,              sys_handler). 

-define(MSG_ID_SYS_GROUP_ATTR,           1). % 属性协议组
-define(MSG_FORMAT_SYS_GROUP_ATTR,       {?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_SYS_GROUP_GOODS,          2). % 通用物品协议组
-define(MSG_FORMAT_SYS_GROUP_GOODS,      {?uint8,?uint32,?uint16,?uint8,?uint32,?uint16,?bool,?uint32,?uint32,?uint32}).
-define(MSG_ID_SYS_GROUP_GOODS_EQUP,     3). % 通用物品装备协议组
-define(MSG_FORMAT_SYS_GROUP_GOODS_EQUP, {?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}).
-define(MSG_ID_SYS_BROADCAST_GROUP_USER, 4). % 消息广播-玩家信息协议组
-define(MSG_FORMAT_SYS_BROADCAST_GROUP_USER, {?uint32,?string}).
-define(MSG_ID_SYS_BROADCAST_GROUP_GOODS, 5). % 消息广播-物品协议组
-define(MSG_FORMAT_SYS_BROADCAST_GROUP_GOODS, {?uint32,?uint16,?bool,?uint32,?uint32}).
-define(MSG_ID_SYS_BROADCAST_GROUP_EQUIP, 6). % 消息广播-物品装备协议组
-define(MSG_FORMAT_SYS_BROADCAST_GROUP_EQUIP, {?uint32,?uint8,?bool,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}).
-define(MSG_ID_SYS_BROADCAST_GROUP_RESERVE, 7). % 消息广播-预留协议组
-define(MSG_FORMAT_SYS_BROADCAST_GROUP_RESERVE, {?uint8,?string}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% player  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PLAYER,              2000). % 玩家
-define(MODULE_PACKET_PLAYER,            player_packet). 
-define(MODULE_HANDLER_PLAYER,           player_handler). 

-define(MSG_ID_PLAYER_LOGIN_REQUEST,     1001). % 玩家登陆请求
-define(MSG_FORMAT_PLAYER_LOGIN_REQUEST, {?uint32,?string,?uint16,?uint8,?uint32,?uint8,?uint8,?uint32,?uint32,?string,?bool,?uint32,?string}).
-define(MSG_ID_PLAYER_LOGIN_OK,          1002). % 玩家登陆成功
-define(MSG_FORMAT_PLAYER_LOGIN_OK,      {?bool,?string,?string}).
-define(MSG_ID_PLAYER_LOGIN_DEBUG,       1003). % 玩家登陆请求(调试)
-define(MSG_FORMAT_PLAYER_LOGIN_DEBUG,   {?string,?uint16}).
-define(MSG_ID_PLAYER_LOGIN_ERROR,       1004). % 玩家登陆失败
-define(MSG_FORMAT_PLAYER_LOGIN_ERROR,   {?uint8}).
-define(MSG_ID_PLAYER_CREAT_REQUEST,     1005). % 玩家创建角色请求
-define(MSG_FORMAT_PLAYER_CREAT_REQUEST, {?string,?uint8,?uint8}).
-define(MSG_ID_PLAYER_CREAT_OK,          1006). % 玩家创建角色成功
-define(MSG_FORMAT_PLAYER_CREAT_OK,      {}).
-define(MSG_ID_PLAYER_CS_REQ_LOGIN_INFO, 1007). % 请求角色登录数据
-define(MSG_FORMAT_PLAYER_CS_REQ_LOGIN_INFO, {}).
-define(MSG_ID_PLAYER_CREAT_ERROR,       1008). % 玩家创建角色失败
-define(MSG_FORMAT_PLAYER_CREAT_ERROR,   {?uint8}).
-define(MSG_ID_PLAYER_CS_LOGIN_GUEST,    1009). % 游客模式登陆请求
-define(MSG_FORMAT_PLAYER_CS_LOGIN_GUEST, {?uint32,?string,?uint16,?uint32,?uint8,?string}).
-define(MSG_ID_PLAYER_DATA_REQUEST,      1011). % 请求角色数据
-define(MSG_FORMAT_PLAYER_DATA_REQUEST,  {?uint32}).
-define(MSG_ID_PLAYER_DATA_INFO,         1012). % 角色数据
-define(MSG_FORMAT_PLAYER_DATA_INFO,     {?uint32,?uint16,?uint8,?uint8,?string,?uint8,?uint8,?uint16,?uint16,?uint16,?uint8,?uint16,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8,?uint16,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint16,?uint32,?uint32,{?cycle,{?uint16}},{?cycle,{?uint8,?uint8}},?uint32,?uint16,?uint32,?uint32,?uint32,?uint32,?uint16,?uint32,?uint8,?uint32,?uint32}).
-define(MSG_ID_PLAYER_SC_AB,             1014). % a/b
-define(MSG_FORMAT_PLAYER_SC_AB,         {?uint8}).
-define(MSG_ID_PLAYER_ATTR_UPDATE,       1020). % 玩家单个属性更新
-define(MSG_FORMAT_PLAYER_ATTR_UPDATE,   {?uint8,?uint32}).
-define(MSG_ID_PLAYER_ATTR_UPDATE_STR,   1022). % 玩家单个属性更新（字符串）
-define(MSG_FORMAT_PLAYER_ATTR_UPDATE_STR, {?uint8,?string}).
-define(MSG_ID_PLAYER_SC_UPDATE_MONEY,   1024). % 更新货币
-define(MSG_FORMAT_PLAYER_SC_UPDATE_MONEY, {?uint8,?uint32}).
-define(MSG_ID_PLAYER_SC_VIP_INFO,       1026). % 更新VIP信息
-define(MSG_FORMAT_PLAYER_SC_VIP_INFO,   {?uint8,?uint32,{?cycle,{?uint8}}}).
-define(MSG_ID_PLAYER_CS_POSITION_INFO,  1101). % 请求官衔信息
-define(MSG_FORMAT_PLAYER_CS_POSITION_INFO, {}).
-define(MSG_ID_PLAYER_CS_UPGRADE,        1103). % 请求升级官衔
-define(MSG_FORMAT_PLAYER_CS_UPGRADE,    {?uint32}).
-define(MSG_ID_PLAYER_SC_UPGRADE,        1104). % 官衔升级
-define(MSG_FORMAT_PLAYER_SC_UPGRADE,    {?uint32}).
-define(MSG_ID_PLAYER_CS_SALARY,         1105). % 请求领取俸禄
-define(MSG_FORMAT_PLAYER_CS_SALARY,     {}).
-define(MSG_ID_PLAYER_SC_POSITION_INFO,  1110). % 官衔信息
-define(MSG_FORMAT_PLAYER_SC_POSITION_INFO, {?uint32}).
-define(MSG_ID_PLAYER_CS_BUFF_INFO,      1121). % 请求BUFF列表信息
-define(MSG_FORMAT_PLAYER_CS_BUFF_INFO,  {}).
-define(MSG_ID_PLAYER_SC_BUFF_INFO,      1130). % 返回BUFF列表信息
-define(MSG_FORMAT_PLAYER_SC_BUFF_INFO,  {{?cycle,{?uint32,?uint8,?uint32,?uint32}}}).
-define(MSG_ID_PLAYER_SC_BUFF_INSERT,    1132). % 插入BUFF通知
-define(MSG_FORMAT_PLAYER_SC_BUFF_INSERT, {?uint32,?uint8,?uint32,?uint32}).
-define(MSG_ID_PLAYER_SC_BUFF_DELETE,    1134). % 移除BUFF通知
-define(MSG_FORMAT_PLAYER_SC_BUFF_DELETE, {?uint32,?uint8}).
-define(MSG_ID_PLAYER_CS_BUY_SP,         1201). % 购买体力
-define(MSG_FORMAT_PLAYER_CS_BUY_SP,     {}).
-define(MSG_ID_PLAYER_SC_BUY_SP_INFO,    1202). % 购买体力信息
-define(MSG_FORMAT_PLAYER_SC_BUY_SP_INFO, {?uint8,?uint16}).
-define(MSG_ID_PLAYER_CS_SP_BUY_TIMES,   1203). % 请求体力次数
-define(MSG_FORMAT_PLAYER_CS_SP_BUY_TIMES, {}).
-define(MSG_ID_PLAYER_CS_RECONNECT,      1213). % 闪断重连
-define(MSG_FORMAT_PLAYER_CS_RECONNECT,  {?uint32}).
-define(MSG_ID_PLAYER_SC_RECONNECT_SUCCESS, 1214). % 闪断重连成功
-define(MSG_FORMAT_PLAYER_SC_RECONNECT_SUCCESS, {?string}).
-define(MSG_ID_PLAYER_SC_RECONNECT_FAIL, 1218). % 闪断重连失败
-define(MSG_FORMAT_PLAYER_SC_RECONNECT_FAIL, {}).
-define(MSG_ID_PLAYER_SC_GIFT_CASH,      1222). % 登陆发放元宝(公测用)
-define(MSG_FORMAT_PLAYER_SC_GIFT_CASH,  {?bool}).
-define(MSG_ID_PLAYER_CS_GET_GIFT_CASH,  1223). % 领取登陆发送元宝(公测用)
-define(MSG_FORMAT_PLAYER_CS_GET_GIFT_CASH, {}).
-define(MSG_ID_PLAYER_CS_GET_GIFT,       1225). % 领取激活码礼包
-define(MSG_FORMAT_PLAYER_CS_GET_GIFT,   {?uint8,?string}).
-define(MSG_ID_PLAYER_SC_GET_GIFT_INFO,  1226). % 已领取礼包信息
-define(MSG_FORMAT_PLAYER_SC_GET_GIFT_INFO, {{?cycle,{?uint8}}}).
-define(MSG_ID_PLAYER_SC_OLD_SERVER_USER, 1227). % 旧服玩家礼包（再战沙场）
-define(MSG_FORMAT_PLAYER_SC_OLD_SERVER_USER, {?uint8}).
-define(MSG_ID_PLAYER_SC_FCM_NOTICE,     1300). % 防沉迷通知
-define(MSG_FORMAT_PLAYER_SC_FCM_NOTICE, {?uint8,?uint32,?uint8}).
-define(MSG_ID_PLAYER_CS_FCM_SUBMIT_INFO, 1301). % 提交防沉迷信息
-define(MSG_FORMAT_PLAYER_CS_FCM_SUBMIT_INFO, {?string,?string}).
-define(MSG_ID_PLAYER_SC_FCM_SUBMIT_INFO, 1310). % 提交防沉迷返回信息
-define(MSG_FORMAT_PLAYER_SC_FCM_SUBMIT_INFO, {?uint8}).
-define(MSG_ID_PLAYER_CS_HIDE_SKIN,      1311). % 请求隐藏皮肤
-define(MSG_FORMAT_PLAYER_CS_HIDE_SKIN,  {?uint8}).
-define(MSG_ID_PLAYER_SC_HIDE_SKIN_INFO, 1312). % 返回隐藏皮肤状态
-define(MSG_FORMAT_PLAYER_SC_HIDE_SKIN_INFO, {?uint8,?uint8}).
-define(MSG_ID_PLAYER_SC_FCM_OFFLINE_NOTICE, 1320). % 防沉迷离线通知
-define(MSG_FORMAT_PLAYER_SC_FCM_OFFLINE_NOTICE, {}).
-define(MSG_ID_PLAYER_CS_OPEN_SYS_INFO,  1401). % 请求开启模块
-define(MSG_FORMAT_PLAYER_CS_OPEN_SYS_INFO, {}).
-define(MSG_ID_PLAYER_SC_OPEN_SYS_INFO,  1410). % 返回开启模块列表
-define(MSG_FORMAT_PLAYER_SC_OPEN_SYS_INFO, {?uint16}).
-define(MSG_ID_PLAYER_SC_OPEN_SYS_NOTICE, 1420). % 开启模块通知
-define(MSG_FORMAT_PLAYER_SC_OPEN_SYS_NOTICE, {?uint16}).
-define(MSG_ID_PLAYER_CS_UPGRATE_CULTIVATION, 1501). % 提升修为
-define(MSG_FORMAT_PLAYER_CS_UPGRATE_CULTIVATION, {}).
-define(MSG_ID_PLAYER_SC_CULTI_NOW,      1502). % 当前修为值
-define(MSG_FORMAT_PLAYER_SC_CULTI_NOW,  {?uint32}).
-define(MSG_ID_PLAYER_CS_GET_GIFT_VIP,   1503). % 请求领取VIP礼包
-define(MSG_FORMAT_PLAYER_CS_GET_GIFT_VIP, {?uint8}).
-define(MSG_ID_PLAYER_SC_GIFT_VIP_INFO,  1504). % VIP礼包信息
-define(MSG_FORMAT_PLAYER_SC_GIFT_VIP_INFO, {{?cycle,{?uint8}}}).
-define(MSG_ID_PLAYER_CS_GET_DAILY_VIP,  1505). % 请求领取VIP日常奖励
-define(MSG_FORMAT_PLAYER_CS_GET_DAILY_VIP, {}).
-define(MSG_ID_PLAYER_SC_VIP_DAILY_INFO, 1506). % VIP日常奖励信息
-define(MSG_FORMAT_PLAYER_SC_VIP_DAILY_INFO, {?bool}).
-define(MSG_ID_PLAYER_CS_OPEN_CULTI,     1507). % 打开祭星界面
-define(MSG_FORMAT_PLAYER_CS_OPEN_CULTI, {}).
-define(MSG_ID_PLAYER_SC_OPEN_CULTI,     1508). % 打开祭星界面
-define(MSG_FORMAT_PLAYER_SC_OPEN_CULTI, {?uint8}).
-define(MSG_ID_PLAYER_CLICK,             1601). % 玩家登陆鼠标点击
-define(MSG_FORMAT_PLAYER_CLICK,         {}).
-define(MSG_ID_PLAYER_CS_SEND_TO_GM,     1603). % gm反馈
-define(MSG_FORMAT_PLAYER_CS_SEND_TO_GM, {?uint8,?string}).
-define(MSG_ID_PLAYER_SC_GM_RETURN,      1604). % gm返回
-define(MSG_FORMAT_PLAYER_SC_GM_RETURN,  {?uint8}).
-define(MSG_ID_PLAYER_CS_STAT,           1605). % 流失统计日志
-define(MSG_FORMAT_PLAYER_CS_STAT,       {?uint8}).
-define(MSG_ID_PLAYER_SC_ILLEGAL_NOTICE, 1606). % 使用外挂掉线通知
-define(MSG_FORMAT_PLAYER_SC_ILLEGAL_NOTICE, {}).
-define(MSG_ID_PLAYER_SC_NOT_ENOUGH_SP,  1608). % 体力不足
-define(MSG_FORMAT_PLAYER_SC_NOT_ENOUGH_SP, {}).
-define(MSG_ID_PLAYER_CS_CHANGE_NAME,    1609). % 改名
-define(MSG_FORMAT_PLAYER_CS_CHANGE_NAME, {?string,?uint8}).
-define(MSG_ID_PLAYER_IS_OK,             1610). % 改名结果
-define(MSG_FORMAT_PLAYER_IS_OK,         {?uint8}).
-define(MSG_ID_PLAYER_SC_CHANGE_NAME_FLAGS, 1612). % 改名标志
-define(MSG_FORMAT_PLAYER_SC_CHANGE_NAME_FLAGS, {?uint8,?uint8}).
-define(MSG_ID_PLAYER_CS_ENTER_NEWBIE,   1613). % 进入新手流程
-define(MSG_FORMAT_PLAYER_CS_ENTER_NEWBIE, {}).
-define(MSG_ID_PLAYER_SC_NEWBIE_STEP,    1614). % 新手流程进度
-define(MSG_FORMAT_PLAYER_SC_NEWBIE_STEP, {?uint16}).
-define(MSG_ID_PLAYER_CS_ARENA_RANK,     1701). % 一骑讨排名
-define(MSG_FORMAT_PLAYER_CS_ARENA_RANK, {?uint32}).
-define(MSG_ID_PLAYER_SC_ARENA_RANK,     1702). % 一骑讨排名
-define(MSG_FORMAT_PLAYER_SC_ARENA_RANK, {?uint32,?uint32}).
-define(MSG_ID_PLAYER_SC_WORLD_LV,       1704). % 世界等级
-define(MSG_FORMAT_PLAYER_SC_WORLD_LV,   {?uint8}).
-define(MSG_ID_PLAYER_SC_TEST_SERVER,    1705). % 是体验服
-define(MSG_FORMAT_PLAYER_SC_TEST_SERVER, {}).
-define(MSG_ID_PLAYER_CS_CHANGE_PRO,     1707). % 转职
-define(MSG_FORMAT_PLAYER_CS_CHANGE_PRO, {?uint8}).
-define(MSG_ID_PLAYER_MOVE_SERVER,       1801). % 移民
-define(MSG_FORMAT_PLAYER_MOVE_SERVER,   {?uint32}).
-define(MSG_ID_PLAYER_MOVE_SERVER_SUCCESS, 1802). % 移民成功
-define(MSG_FORMAT_PLAYER_MOVE_SERVER_SUCCESS, {}).
-define(MSG_ID_PLAYER_CS_TEST_SERVER_INFO, 1803). % 请求体验服数据
-define(MSG_FORMAT_PLAYER_CS_TEST_SERVER_INFO, {}).
-define(MSG_ID_PLAYER_SC_TEST_SERVER_INFO, 1804). % 返回体验服数据
-define(MSG_FORMAT_PLAYER_SC_TEST_SERVER_INFO, {?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_PLAYER_CS_GET_TEST_SERVER_AWARD, 1805). % 请求领取体验服每日元宝
-define(MSG_FORMAT_PLAYER_CS_GET_TEST_SERVER_AWARD, {}).
-define(MSG_ID_PLAYER_IS_CAN_GET_TEST_AWARD, 1806). % 本日是否已经领取体验服元宝
-define(MSG_FORMAT_PLAYER_IS_CAN_GET_TEST_AWARD, {?bool,?uint32}).
-define(MSG_ID_PLAYER_CS_REQUEST_TEST_AWARD_INFO, 1807). % 请求是否可以领取每日测试服奖励
-define(MSG_FORMAT_PLAYER_CS_REQUEST_TEST_AWARD_INFO, {}).
-define(MSG_ID_PLAYER_SC_TSP,            1998). % 时间同步协议
-define(MSG_FORMAT_PLAYER_SC_TSP,        {?uint32}).
-define(MSG_ID_PLAYER_HEART,             1999). % 心跳数据包
-define(MSG_FORMAT_PLAYER_HEART,         {}).
-define(MSG_ID_PLAYER_REPEAT_LOGIN,      2000). % 重复登录通知
-define(MSG_FORMAT_PLAYER_REPEAT_LOGIN,  {}).

-define(MSG_ID_TENCENT_INFO_REQUEST,      2001). % 获取腾讯平台信息
-define(MSG_FORMAT_TENCENT_INFO_REQUEST,  {}).

-define(MSG_ID_PLATFROM_INFO_RETURN,      2005). % 平黄砖等级{0没,其他对应等级},是否有每日礼包{0没,1有},等级礼包{0没得领,其他对应相应等级},黄砖新手礼包，是否年费用户)
-define(MSG_FORMAT_PLATFROM_INFO_RETURN,  {?uint16,?uint8,?uint8,?uint32,?uint8,?uint8}).

-define(MSG_ID_TENCENT_DEPOSIT,      2002). % 腾讯平台充值(客户端请求){元宝数量,pfkey},物品图片url
-define(MSG_FORMAT_TENCENT_DEPOSIT,  {?uint32,?string,?string}).

-define(MSG_ID_TENCENT_DEPOSIT_RETURN, 2003). % 腾讯平台充值(服务端返回){充值url}
-define(MSG_FORMAT_TENCENT_DEPOSIT_RETURN,  {?string}).

-define(MSG_ID_TENCENT_PACK_GET,      2004). % 礼包领取
-define(MSG_FORMAT_TENCENT_PACK_GET,  {?uint8}). % 1每日礼包，2等级礼包，3黄砖新手

-define(MSG_ID_TENCENT_ERR_RETURN,      2006). % 提示返回
-define(MSG_FORMAT_TENCENT_ERR_RETURN,  {?string}). 

-define(MSG_ID_TENCENT_INVITE,	      2007). % 邀请登记
-define(MSG_FORMAT_TENCENT_INVITE,  {?string}). 


% int16：  邀请总数
% int16：  昨日上线
% int8：  分享过程（0,1一步，2两步，3，已领）
% int8:   5个奖励是否已领（0未,1已领）
% int8:   10个奖励是否已领（0,1）
% int8:   20个奖励是否已领（0,1）
% int8:   40个奖励是否已领（0,1）
% int8:   上线5个奖励是否已领（0,1）

-define(MSG_ID_TENCENT_INVITE_INFO,	      2008). % 邀请登记
-define(MSG_FORMAT_TENCENT_INVITE_INFO,  {?uint16,?uint16,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,{?cycle,{?uint16}}}). 

-define(MSG_ID_TENCENT_INVITE_AWARD,	      2009). % 邀请奖励
-define(MSG_FORMAT_TENCENT_INVITE_AWARD,  {?uint16}). 


-define(MSG_ID_ROBOT_LVUP_REQUEST,      2010). % 机器人请求升级
-define(MSG_FORMAT_ROBOT_LVUP_REQUEST,  {}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% goods  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GOODS,               3000). % 物品
-define(MODULE_PACKET_GOODS,             goods_packet). 
-define(MODULE_HANDLER_GOODS,            goods_handler). 

-define(MSG_ID_GOODS_CS_CTN_INFO,        2101). % 请求物品数据
-define(MSG_FORMAT_GOODS_CS_CTN_INFO,    {?uint32,?uint16,?uint8}).
-define(MSG_ID_GOODS_SC_CTN_INFO,        2102). % 返回容器信息
-define(MSG_FORMAT_GOODS_SC_CTN_INFO,    {?uint32,?uint16,?uint8,?uint8}).
-define(MSG_ID_GOODS_SC_GOODS_INFO,      2110). % 普通物品信息
-define(MSG_FORMAT_GOODS_SC_GOODS_INFO,  {?uint8,?uint32,?uint16,?uint8,?uint32,?uint16,?bool,?uint32,?uint32,?uint32,?uint8}).
-define(MSG_ID_GOODS_SC_GOODS_EQUIP_INFO, 2120). % 物品装备信息
-define(MSG_FORMAT_GOODS_SC_GOODS_EQUIP_INFO, {?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}},?uint8,{?cycle,{?uint32}}}).
-define(MSG_ID_GOODS_SC_GOODS_REMOVE,    2130). % 移除物品
-define(MSG_FORMAT_GOODS_SC_GOODS_REMOVE, {?uint8,?uint32,?uint8}).
-define(MSG_ID_GOODS_CS_REFRESH,         2141). % 刷新容器
-define(MSG_FORMAT_GOODS_CS_REFRESH,     {?uint8}).
-define(MSG_ID_GOODS_CS_REMOVE,          2151). % 移除物品
-define(MSG_FORMAT_GOODS_CS_REMOVE,      {?uint8,?uint8}).
-define(MSG_ID_GOODS_CS_DRAG,            2161). % 物品移动
-define(MSG_FORMAT_GOODS_CS_DRAG,        {?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_GOODS_CS_SPLIT,           2171). % 拆分物品
-define(MSG_FORMAT_GOODS_CS_SPLIT,       {?uint8,?uint8,?uint8}).
-define(MSG_ID_GOODS_CS_ENLARGE_CTN,     2181). % 扩充容器
-define(MSG_FORMAT_GOODS_CS_ENLARGE_CTN, {?uint8}).
-define(MSG_ID_GOODS_SC_ENLARGE_CTN,     2190). % 扩充容器返回
-define(MSG_FORMAT_GOODS_SC_ENLARGE_CTN, {?uint8,?uint8}).
-define(MSG_ID_GOODS_CS_USE,             2201). % 物品使用
-define(MSG_FORMAT_GOODS_CS_USE,         {?uint8,?uint8}).
-define(MSG_ID_GOODS_CS_EQUIP_ON,        2211). % 穿装备
-define(MSG_FORMAT_GOODS_CS_EQUIP_ON,    {?uint16,?uint8}).
-define(MSG_ID_GOODS_CS_EQUIP_OFF,       2221). % 脱装备
-define(MSG_FORMAT_GOODS_CS_EQUIP_OFF,   {?uint16,?uint8}).
-define(MSG_ID_GOODS_SC_OPEN_REMOTE,     2222). % 打开远程容器
-define(MSG_FORMAT_GOODS_SC_OPEN_REMOTE, {?uint8,?uint16}).
-define(MSG_ID_GOODS_CS_OVER_TIME,       2223). % 临时背包道具过期判定请求
-define(MSG_FORMAT_GOODS_CS_OVER_TIME,   {?uint8}).
-define(MSG_ID_GOODS_CS_HIDE_EQUIP,      2225). % 隐藏装备
-define(MSG_FORMAT_GOODS_CS_HIDE_EQUIP,  {?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% battle  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_BATTLE,              4000). % 战斗
-define(MODULE_PACKET_BATTLE,            battle_packet). 
-define(MODULE_HANDLER_BATTLE,           battle_handler). 

-define(MSG_ID_BATTLE_CS_START,          3001). % 开始战斗
-define(MSG_FORMAT_BATTLE_CS_START,      {?uint8,?uint32}).
-define(MSG_ID_BATTLE_SC_OVER,           3012). % 战斗结束
-define(MSG_FORMAT_BATTLE_SC_OVER,       {?uint32,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint8}},{?cycle,{?uint32}},?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_BATTLE_SC_STOP,           3016). % 强制终止战斗
-define(MSG_FORMAT_BATTLE_SC_STOP,       {?uint8}).
-define(MSG_ID_BATTLE_SC_START2,         3100). % 战斗开始
-define(MSG_FORMAT_BATTLE_SC_START2,     {?uint32,?bool,?uint8,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}},?uint16,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}},?uint16}).
-define(MSG_ID_BATTLE_UNITS_GROUP,       3110). % 战斗单元集合协议组
-define(MSG_FORMAT_BATTLE_UNITS_GROUP,   {?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}},?uint16}).
-define(MSG_ID_BATTLE_UNIT_PLAYER_GROUP, 3120). % 战斗单元协议组--角色
-define(MSG_FORMAT_BATTLE_UNIT_PLAYER_GROUP, {?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}).
-define(MSG_ID_BATTLE_UNIT_PARTNER_GROUP, 3130). % 战斗单元协议组--武将
-define(MSG_FORMAT_BATTLE_UNIT_PARTNER_GROUP, {?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}).
-define(MSG_ID_BATTLE_UNIT_MONSTER_GROUP, 3140). % 战斗单元协议组--怪物
-define(MSG_FORMAT_BATTLE_UNIT_MONSTER_GROUP, {?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}).
-define(MSG_ID_BATTLE_SC_SEQ,            3150). % 出手顺序
-define(MSG_FORMAT_BATTLE_SC_SEQ,        {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_BATTLE_SC_HORSE_SKILL,    3160). % 坐骑技能
-define(MSG_FORMAT_BATTLE_SC_HORSE_SKILL, {?uint32,?uint8,?uint8,?uint32,{?cycle,{?uint16}},{?cycle,{?uint8,?uint32}}}).
-define(MSG_ID_BATTLE_CS_OPERATE,        3501). % 战斗操作
-define(MSG_FORMAT_BATTLE_CS_OPERATE,    {?uint8}).
-define(MSG_ID_BATTLE_SC_OPERATE_NOTICE, 3502). % 战斗操作通知
-define(MSG_FORMAT_BATTLE_SC_OPERATE_NOTICE, {?uint8,?uint8,?uint16}).
-define(MSG_ID_BATTLE_CS_AUTO,           3503). % 自动战斗
-define(MSG_FORMAT_BATTLE_CS_AUTO,       {?uint8}).
-define(MSG_ID_BATTLE_SC_CMD_DATA,       3600). % 战斗指令数据
-define(MSG_FORMAT_BATTLE_SC_CMD_DATA,   {?uint32,?uint8,{?cycle,{?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}}}}}}).
-define(MSG_ID_BATTLE_GROUP_CMD_DATA,    3610). % 指令数据协议组
-define(MSG_FORMAT_BATTLE_GROUP_CMD_DATA, {?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_BATTLE_SC_REFRESH_BOUT,   3620). % 回合刷新
-define(MSG_FORMAT_BATTLE_SC_REFRESH_BOUT, {?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint16}}}},?uint8}).
-define(MSG_ID_BATTLE_CS_ASK_PK,         3621). % 请求pk(版署)
-define(MSG_FORMAT_BATTLE_CS_ASK_PK,     {?uint8,?uint32}).
-define(MSG_ID_BATTLE_SC_ASK_PK,         3622). % 请求pk(版署)
-define(MSG_FORMAT_BATTLE_SC_ASK_PK,     {?uint8,?uint32}).
-define(MSG_ID_BATTLE_CS_ANSWER_PK,      3623). % 回应pk请求(版署)
-define(MSG_FORMAT_BATTLE_CS_ANSWER_PK,  {?uint8,?uint32,?uint8}).
-define(MSG_ID_BATTLE_SC_ANSWER_PK,      3624). % 回应pk请求(版署)
-define(MSG_FORMAT_BATTLE_SC_ANSWER_PK,  {?uint8,?uint32,?uint8}).
-define(MSG_ID_BATTLE_CS_REPORT_DATA,    3651). % 请求战报数据
-define(MSG_FORMAT_BATTLE_CS_REPORT_DATA, {}).
-define(MSG_ID_BATTLE_SC_REPORT_DATA,    3652). % 返回战报数据
-define(MSG_FORMAT_BATTLE_SC_REPORT_DATA, {?uint8,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}},?uint16,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint16,?uint16,{?cycle,{?uint32}},?uint16}},{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}},?uint16,{?cycle,{?uint8,{?cycle,{?uint32,?uint16}}}},{?cycle,{?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8}}}},{?cycle,{?uint8,{?cycle,{?uint16,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint16,?uint8,?uint32,?uint8}}}}}}}).
-define(MSG_ID_BATTLE_CS_START_COPY_TEST, 3701). % 副本战斗测试
-define(MSG_FORMAT_BATTLE_CS_START_COPY_TEST, {?uint16,?uint8}).
-define(MSG_ID_BATTLE_SC_SKIP,           3703). % 跳过战斗
-define(MSG_FORMAT_BATTLE_SC_SKIP,       {}).
-define(MSG_ID_BATTLE_CS_REQ_REPORT_MULTI, 3705). % 请求各类型战报
-define(MSG_FORMAT_BATTLE_CS_REQ_REPORT_MULTI, {?uint16,?string}).
-define(MSG_ID_BATTLE_SC_SKIP_INFO,      3706). % 跳过战斗次数
-define(MSG_FORMAT_BATTLE_SC_SKIP_INFO,  {?uint16,?uint8}).
-define(MSG_ID_BATTLE_CS_REPORT_LIST,    3707). % 请求战报列表
-define(MSG_FORMAT_BATTLE_CS_REPORT_LIST, {?uint16,?uint32,?uint8}).
-define(MSG_ID_BATTLE_SC_REPORT_LIST,    3708). % 战报列表
-define(MSG_FORMAT_BATTLE_SC_REPORT_LIST, {?uint32,{?cycle,{?uint32,?string,?string,?uint16,?uint16,?uint16,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% partner  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PARTNER,             5000). % 武将
-define(MODULE_PACKET_PARTNER,           partner_packet). 
-define(MODULE_HANDLER_PARTNER,          partner_handler). 

-define(MSG_ID_PARTNER_CS_INFO,          4001). % 接收武将信息
-define(MSG_FORMAT_PARTNER_CS_INFO,      {?uint32}).
-define(MSG_ID_PARTNER_SC_INFO,          4002). % 武将信息
-define(MSG_FORMAT_PARTNER_SC_INFO,      {?uint8,?uint32,{?cycle,{?uint16,?uint16,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint16,?uint32,?uint8,?uint32,{?cycle,{?uint16}},?uint32}}}).
-define(MSG_ID_PARTNER_SC_ATTR_UPDATE,   4004). % 武将单个属性改变
-define(MSG_FORMAT_PARTNER_SC_ATTR_UPDATE, {?uint16,?uint8,?uint32}).
-define(MSG_ID_PARTNER_CS_FREE,          4005). % 解散武将
-define(MSG_FORMAT_PARTNER_CS_FREE,      {?uint16}).
-define(MSG_ID_PARTNER_SC_FREE,          4006). % 解散武将
-define(MSG_FORMAT_PARTNER_SC_FREE,      {?uint16}).
-define(MSG_ID_PARTNER_CS_ASSEMBLE,      4007). % 武将组合
-define(MSG_FORMAT_PARTNER_CS_ASSEMBLE,  {?uint32}).
-define(MSG_ID_PARTNER_SC_ASSEMBLE,      4008). % 武将组合
-define(MSG_FORMAT_PARTNER_SC_ASSEMBLE,  {?uint8,?uint32,{?cycle,{?uint16,?uint8,?uint8}}}).
-define(MSG_ID_PARTNER_MIND_INFO,        4009). % 人物面板心法信息
-define(MSG_FORMAT_PARTNER_MIND_INFO,    {?uint32,?uint16}).
-define(MSG_ID_PARTNER_SC_MIND_INFO,     4010). % 人物面板心法信息
-define(MSG_FORMAT_PARTNER_SC_MIND_INFO, {?uint32,?uint16,{?cycle,{?uint8,?uint8,?uint8}}}).
-define(MSG_ID_PARTNER_CS_TRAIN,         4011). % 武将培养
-define(MSG_FORMAT_PARTNER_CS_TRAIN,     {?uint8,?uint16}).
-define(MSG_ID_PARTNER_SC_TRAIN,         4012). % 武将培养
-define(MSG_FORMAT_PARTNER_SC_TRAIN,     {?uint8,?uint16,?uint16,?uint16,?uint16,?uint16}).
-define(MSG_ID_PARTNER_CS_SAVE_TRAIN,    4013). % 保存培养属性
-define(MSG_FORMAT_PARTNER_CS_SAVE_TRAIN, {?uint16}).
-define(MSG_ID_PARTNER_SC_SAVE_TRAIN,    4014). % 保存培养属性
-define(MSG_FORMAT_PARTNER_SC_SAVE_TRAIN, {?uint16,?uint16,?uint16,?uint16}).
-define(MSG_ID_PARTNER_CS_CANCEL_TAIN,   4015). % 取消培养的属性
-define(MSG_FORMAT_PARTNER_CS_CANCEL_TAIN, {?uint32}).
-define(MSG_ID_PARTNER_CS_INHERIT,       4017). % 武将继承
-define(MSG_FORMAT_PARTNER_CS_INHERIT,   {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SC_INHERIT,       4018). % 武将继承
-define(MSG_FORMAT_PARTNER_SC_INHERIT,   {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SC_SET_SKIPPER,   4020). % 设置主将
-define(MSG_FORMAT_PARTNER_SC_SET_SKIPPER, {{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_CS_SET_ASSIST,    4023). % 副将界面设置武将
-define(MSG_FORMAT_PARTNER_CS_SET_ASSIST, {?uint16,?uint16,?uint8}).
-define(MSG_ID_PARTNER_CS_REMOVE_ASSIST, 4025). % 副将界面移除武将
-define(MSG_FORMAT_PARTNER_CS_REMOVE_ASSIST, {?uint16,?uint8}).
-define(MSG_ID_PARTNER_ASSIST_GROUP,     4028). % 副将协议组
-define(MSG_FORMAT_PARTNER_ASSIST_GROUP, {{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_SC_SET_ASSIST,    4030). % 副将界面设置返回
-define(MSG_FORMAT_PARTNER_SC_SET_ASSIST, {{?cycle,{?uint16,{?cycle,{?uint16}}}}}).
-define(MSG_ID_PARTNER_SC_CHANGE_STATION, 4032). % 副将界面武将状态改变
-define(MSG_FORMAT_PARTNER_SC_CHANGE_STATION, {?uint16,?uint8}).
-define(MSG_ID_PARTNER_CS_CAMP_LIST,     4033). % 武将所有阵法列表
-define(MSG_FORMAT_PARTNER_CS_CAMP_LIST, {?uint16}).
-define(MSG_ID_PARTNER_SC_CAMP_LIST,     4034). % 武将所有阵法列表
-define(MSG_FORMAT_PARTNER_SC_CAMP_LIST, {?uint16,{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_CS_GET_RECRUIT,   4101). % 读取招募列表
-define(MSG_FORMAT_PARTNER_CS_GET_RECRUIT, {}).
-define(MSG_ID_PARTNER_SC_GET_RECRUIT,   4102). % 读取招募列表
-define(MSG_FORMAT_PARTNER_SC_GET_RECRUIT, {?uint16,?uint16,?uint16,?uint16,?uint8,?uint8}).
-define(MSG_ID_PARTNER_CS_EXT_BAG,       4107). % 扩展招贤馆格子数
-define(MSG_FORMAT_PARTNER_CS_EXT_BAG,   {}).
-define(MSG_ID_PARTNER_SC_EXT_BAG,       4108). % 扩展招贤馆格子数
-define(MSG_FORMAT_PARTNER_SC_EXT_BAG,   {?uint8}).
-define(MSG_ID_PARTNER_CS_PUB_FREE,      4109). % 招贤馆过期武将清除
-define(MSG_FORMAT_PARTNER_CS_PUB_FREE,  {?uint8,?uint16}).
-define(MSG_ID_PARTNER_SC_PUB_FREE,      4110). % 招贤馆过期武将清除
-define(MSG_FORMAT_PARTNER_SC_PUB_FREE,  {?uint16}).
-define(MSG_ID_PARTNER_CS_ADD_LOOKNUM,   4115). % 增加寻访次数
-define(MSG_FORMAT_PARTNER_CS_ADD_LOOKNUM, {}).
-define(MSG_ID_PARTNER_SC_ADD_LOOKNUM,   4116). % 增加寻访次数
-define(MSG_FORMAT_PARTNER_SC_ADD_LOOKNUM, {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SC_OPEN_LOOKFOR,  4122). % 打开寻访界面
-define(MSG_FORMAT_PARTNER_SC_OPEN_LOOKFOR, {?uint8,?uint32,?uint16,?uint16,?uint8,?uint16}).
-define(MSG_ID_PARTNER_CS_CLEAN_LOOK_CD, 4123). % 清除寻访cd
-define(MSG_FORMAT_PARTNER_CS_CLEAN_LOOK_CD, {}).
-define(MSG_ID_PARTNER_SC_CLEAN_LOOK_CD, 4124). % 清除寻访cd
-define(MSG_FORMAT_PARTNER_SC_CLEAN_LOOK_CD, {?uint8}).
-define(MSG_ID_PARTNER_CS_FAMOUS,        4125). % 招贤馆名满天下标签
-define(MSG_FORMAT_PARTNER_CS_FAMOUS,    {}).
-define(MSG_ID_PARTNER_SC_FAMOUS,        4126). % 招贤馆名满天下标签
-define(MSG_FORMAT_PARTNER_SC_FAMOUS,    {?bool,?uint8}).
-define(MSG_ID_PARTNER_SC_FREE_TRAIN,    4128). % 免费培养次数
-define(MSG_FORMAT_PARTNER_SC_FREE_TRAIN, {?uint8}).
-define(MSG_ID_PARTNER_CS_CHANGE_EQUIP_ONCE, 4131). % 一键换装备
-define(MSG_FORMAT_PARTNER_CS_CHANGE_EQUIP_ONCE, {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SC_CHANGE_EQUIP_ONCE, 4132). % 一键换装备
-define(MSG_FORMAT_PARTNER_SC_CHANGE_EQUIP_ONCE, {?uint8}).
-define(MSG_ID_PARTNER_CS_CHANGE_MIND_ONCE, 4133). % 一键换心法
-define(MSG_FORMAT_PARTNER_CS_CHANGE_MIND_ONCE, {?uint16,?uint16}).
-define(MSG_ID_PARTNER_CS_LOOKFOR_INFO,  4201). % 寻访界面信息
-define(MSG_FORMAT_PARTNER_CS_LOOKFOR_INFO, {}).
-define(MSG_ID_PARTNER_SC_LOOKFOR_INFO,  4202). % 寻访界面信息
-define(MSG_FORMAT_PARTNER_SC_LOOKFOR_INFO, {?uint16,?uint32,?uint16,?uint16,?uint32,?uint8}).
-define(MSG_ID_PARTNER_CS_LOOKFOR,       4203). % 寻访
-define(MSG_FORMAT_PARTNER_CS_LOOKFOR,   {?uint8,?uint8,?uint8}).
-define(MSG_ID_PARTNER_SC_LOOKFOR,       4204). % 寻访
-define(MSG_FORMAT_PARTNER_SC_LOOKFOR,   {?uint16,?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_PARTNER_CS_RECRUIT,       4205). % 招募
-define(MSG_FORMAT_PARTNER_CS_RECRUIT,   {?uint16}).
-define(MSG_ID_PARTNER_SC_RECRUIT,       4206). % 招募
-define(MSG_FORMAT_PARTNER_SC_RECRUIT,   {?uint16}).
-define(MSG_ID_PARTNER_CS_CALL_ON,       4207). % 拜见
-define(MSG_FORMAT_PARTNER_CS_CALL_ON,   {?uint16}).
-define(MSG_ID_PARTNER_SC_CALL_ON,       4208). % 拜见
-define(MSG_FORMAT_PARTNER_SC_CALL_ON,   {?uint16,?uint32}).
-define(MSG_ID_PARTNER_CS_ASSEMBLE_INFO, 4209). % 组合界面信息
-define(MSG_FORMAT_PARTNER_CS_ASSEMBLE_INFO, {}).
-define(MSG_ID_PARTNER_SC_ASSEMBLE_INFO, 4210). % 组合界面信息
-define(MSG_FORMAT_PARTNER_SC_ASSEMBLE_INFO, {{?cycle,{?uint16,?uint8,?uint32}}}).
-define(MSG_ID_PARTNER_CS_UP_ASSEMBLE,   4211). % 升级组合
-define(MSG_FORMAT_PARTNER_CS_UP_ASSEMBLE, {?uint16,?uint32}).
-define(MSG_ID_PARTNER_SC_UP_ASSEMBLE,   4212). % 升级组合
-define(MSG_FORMAT_PARTNER_SC_UP_ASSEMBLE, {?uint16,?uint8,?uint32}).
-define(MSG_ID_PARTNER_CS_LOOKED_LIST,   4213). % 已激活武将列表
-define(MSG_FORMAT_PARTNER_CS_LOOKED_LIST, {}).
-define(MSG_ID_PARTNER_SC_LOOKED_LIST,   4214). % 已激活武将列表
-define(MSG_FORMAT_PARTNER_SC_LOOKED_LIST, {{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_CS_LOOK_NEW_LIST, 4215). % 新获得武将列表
-define(MSG_FORMAT_PARTNER_CS_LOOK_NEW_LIST, {}).
-define(MSG_ID_PARTNER_SC_LOOK_NEW_LIST, 4216). % 新获得武将列表
-define(MSG_FORMAT_PARTNER_SC_LOOK_NEW_LIST, {{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_CS_DEL_LOOK_NEW,  4217). % 查看新武将
-define(MSG_FORMAT_PARTNER_CS_DEL_LOOK_NEW, {?uint16}).
-define(MSG_ID_PARTNER_SC_DEL_LOOK_NEW,  4218). % 查看新武将
-define(MSG_FORMAT_PARTNER_SC_DEL_LOOK_NEW, {?uint16}).
-define(MSG_ID_PARTNER_CS_LOOK_NEW_ASSEMBLE, 4219). % 新获得兵法列表
-define(MSG_FORMAT_PARTNER_CS_LOOK_NEW_ASSEMBLE, {}).
-define(MSG_ID_PARTNER_SC_LOOK_NEW_ASSEMBLE, 4220). % 新获得兵法列表
-define(MSG_FORMAT_PARTNER_SC_LOOK_NEW_ASSEMBLE, {{?cycle,{?uint16}}}).
-define(MSG_ID_PARTNER_CS_DEL_ASS_NEW,   4221). % 查看新兵法
-define(MSG_FORMAT_PARTNER_CS_DEL_ASS_NEW, {?uint16}).
-define(MSG_ID_PARTNER_SC_DEL_ASS_NEW,   4222). % 查看新兵法
-define(MSG_FORMAT_PARTNER_SC_DEL_ASS_NEW, {?uint16}).
-define(MSG_ID_PARTNER_SC_LOOK_NEW_ID,   4224). % 新获得武将id
-define(MSG_FORMAT_PARTNER_SC_LOOK_NEW_ID, {?uint16}).
-define(MSG_ID_PARTNER_CS_LOOK_NOTICE,   4225). % 寻访提示
-define(MSG_FORMAT_PARTNER_CS_LOOK_NOTICE, {?uint16}).
-define(MSG_ID_PARTNER_CS_REQUEST_TRAN,  4301). % 请求培养
-define(MSG_FORMAT_PARTNER_CS_REQUEST_TRAN, {?uint32}).
-define(MSG_ID_PARTNER_TRAN_RESULT,      4302). % 是否培养成功
-define(MSG_FORMAT_PARTNER_TRAN_RESULT,  {?bool,?uint32}).
-define(MSG_ID_PARTNER_CS_SET_FOLLOW,    4401). % 设置跟随武将
-define(MSG_FORMAT_PARTNER_CS_SET_FOLLOW, {?uint16}).
-define(MSG_ID_PARTNER_SC_SET_FOLLOW,    4402). % 设置跟随武将
-define(MSG_FORMAT_PARTNER_SC_SET_FOLLOW, {?uint16}).
-define(MSG_ID_PARTNER_CS_ATTR,          4411). % 武将属性
-define(MSG_FORMAT_PARTNER_CS_ATTR,      {?uint32,?uint16}).
-define(MSG_ID_PARTNER_SC_ATTR,          4412). % 武将属性
-define(MSG_FORMAT_PARTNER_SC_ATTR,      {?uint32,?uint16,?uint16,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% map  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MAP,                 6000). % 地图
-define(MODULE_PACKET_MAP,               map_packet). 
-define(MODULE_HANDLER_MAP,              map_handler). 

-define(MSG_ID_MAP_ENTER,                5001). % 请求进入地图
-define(MSG_FORMAT_MAP_ENTER,            {?uint16}).
-define(MSG_ID_MAP_ENTER_PLAYER,         5010). % 进入地图角色数据
-define(MSG_FORMAT_MAP_ENTER_PLAYER,     {?uint16,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint8,?uint32,?uint16,?uint16,?uint8,?uint32,?uint32,?uint32,?uint32,?uint16,?uint16,?string,?uint16,?uint8,?uint32,?uint8,?uint8,?uint16,?uint16,?uint32,?uint32}).
-define(MSG_ID_MAP_EXIT,                 5012). % 离开
-define(MSG_FORMAT_MAP_EXIT,             {?uint16,?uint32,?uint8}).
-define(MSG_ID_MAP_PLAYER_MOVE,          5021). % 角色移动
-define(MSG_FORMAT_MAP_PLAYER_MOVE,      {?uint32,?uint16,?uint16}).
-define(MSG_ID_MAP_PLAYER_MOVE_NOTICE,   5022). % 角色移动通知
-define(MSG_FORMAT_MAP_PLAYER_MOVE_NOTICE, {?uint32,?uint16,?uint16}).
-define(MSG_ID_MAP_SC_CHANGE_LV,         5030). % 角色等级改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_LV,     {?uint32,?uint8}).
-define(MSG_ID_MAP_SC_CHANGE_VIP,        5040). % 角色VIP改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_VIP,    {?uint32,?uint8}).
-define(MSG_ID_MAP_SC_CHANGE_STATE,      5050). % 角色状态改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_STATE,  {?uint32,?uint8}).
-define(MSG_ID_MAP_SC_CHANGE_SKIN_FASHION, 5060). % 角色时装皮肤改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_SKIN_FASHION, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_SKIN_WEAPON, 5070). % 角色武器皮肤改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_SKIN_WEAPON, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_SKIN_ARMOR, 5080). % 角色衣服皮肤改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_SKIN_ARMOR, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_SKIN_STEP,  5086). % 角色足迹皮肤改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_SKIN_STEP, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_DOUBLE,     5088). % 双修时玩家状态改变
-define(MSG_FORMAT_MAP_SC_CHANGE_DOUBLE, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_SKIN_RIDE,  5090). % 角色坐骑皮肤改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_SKIN_RIDE, {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_TITLE,      5092). % 角色称号改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_TITLE,  {?uint32,?uint16}).
-define(MSG_ID_MAP_SC_CHANGE_GUILD,      5094). % 角色军团改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_GUILD,  {?uint32,?uint16,?string}).
-define(MSG_ID_MAP_SC_CHANGE_POSITION,   5096). % 角色官衔改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_POSITION, {?uint32,?uint16}).
-define(MSG_ID_MAP_CS_CHANGE_INFO_STATE, 5098). % 玩家状态改变
-define(MSG_FORMAT_MAP_CS_CHANGE_INFO_STATE, {?uint32,?uint8}).
-define(MSG_ID_MAP_SC_MONSTER_INFO,      5100). % 怪物信息
-define(MSG_FORMAT_MAP_SC_MONSTER_INFO,  {?uint32,?uint32,?uint16,?uint16}).
-define(MSG_ID_MAP_SC_MONSTER_MOVE,      5102). % 怪物移动广播
-define(MSG_FORMAT_MAP_SC_MONSTER_MOVE,  {?uint32,?uint16,?uint16,?uint16,?uint16,?uint8}).
-define(MSG_ID_MAP_SC_CHANGE_TEAM,       5104). % 组队状态改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_TEAM,   {?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_NAME,       5106). % 玩家名字改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_NAME,   {?uint32,?string}).
-define(MSG_ID_MAP_SC_MONSTER_REMOVE,    5110). % 移除怪物
-define(MSG_FORMAT_MAP_SC_MONSTER_REMOVE, {?uint32}).
-define(MSG_ID_MAP_SC_VIP_HIDE,          5112). % 隐藏vip等级广播
-define(MSG_FORMAT_MAP_SC_VIP_HIDE,      {?uint32,?uint32}).
-define(MSG_ID_MAP_CS_OPENED_MAP_LIST,   5201). % 请求开启地图列表
-define(MSG_FORMAT_MAP_CS_OPENED_MAP_LIST, {}).
-define(MSG_ID_MAP_SC_OPENED_MAP_LIST,   5202). % 开启地图列表
-define(MSG_FORMAT_MAP_SC_OPENED_MAP_LIST, {{?cycle,{?uint16}}}).
-define(MSG_ID_MAP_SC_UPDATE_MAP,        5204). % 更新开启地图列表
-define(MSG_FORMAT_MAP_SC_UPDATE_MAP,    {?uint16}).
-define(MSG_ID_MAP_CS_COPY_INFO,         5501). % 请求副本信息
-define(MSG_FORMAT_MAP_CS_COPY_INFO,     {}).
-define(MSG_ID_MAP_SC_COPY_INFO,         5510). % 副本信息
-define(MSG_FORMAT_MAP_SC_COPY_INFO,     {{?cycle,{?uint16}},{?cycle,{?uint16,?uint8}}}).
-define(MSG_ID_MAP_CS_NPC,               5601). % NPC功能请求
-define(MSG_FORMAT_MAP_CS_NPC,           {?uint16,?uint8}).
-define(MSG_ID_MAP_SC_COLLECTION,        5603). % 采集
-define(MSG_FORMAT_MAP_SC_COLLECTION,    {?uint16}).
-define(MSG_ID_MAP_SC_PLAYER_MOVE,       5604). % 角色瞬移广播
-define(MSG_FORMAT_MAP_SC_PLAYER_MOVE,   {?uint32,?uint16,?uint16}).
-define(MSG_ID_MAP_CS_FLY,               5605). % 请求瞬移
-define(MSG_FORMAT_MAP_CS_FLY,           {?uint32,?uint32,?uint32}).
-define(MSG_ID_MAP_SC_CHANGE_GUILD_LV,   5606). % 军团等级改变
-define(MSG_FORMAT_MAP_SC_CHANGE_GUILD_LV, {?uint32,?uint8}).
-define(MSG_ID_MAP_SC_SHOW_MAP,          5608). % 全屏效果
-define(MSG_FORMAT_MAP_SC_SHOW_MAP,      {?uint32,?uint16}).
-define(MSG_ID_MAP_SC_CHANGE_FOLLOW,     5610). % 跟随武将改变广播
-define(MSG_FORMAT_MAP_SC_CHANGE_FOLLOW, {?uint32,?uint16}).
-define(MSG_ID_MAP_CS_INVITE_PK,         5701). % 发起pk邀请
-define(MSG_FORMAT_MAP_CS_INVITE_PK,     {?uint32}).
-define(MSG_ID_MAP_SC_INVITE_PK,         5702). % 发起pk邀请回复
-define(MSG_FORMAT_MAP_SC_INVITE_PK,     {?uint32,?string}).
-define(MSG_ID_MAP_CS_REPLY_PK,          5703). % 回复pk邀请
-define(MSG_FORMAT_MAP_CS_REPLY_PK,      {?uint8,?uint32}).
-define(MSG_ID_MAP_STAR_LV_CHANGE,       5704). % 将星等级变化
-define(MSG_FORMAT_MAP_STAR_LV_CHANGE,   {?uint32,?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% achievement  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ACHIEVEMENT,         7000). % 成就系统
-define(MODULE_PACKET_ACHIEVEMENT,       achievement_packet). 
-define(MODULE_HANDLER_ACHIEVEMENT,      achievement_handler). 

-define(MSG_ID_ACHIEVEMENT_CSARRIVALDATA, 6101). % 获取成就数据
-define(MSG_FORMAT_ACHIEVEMENT_CSARRIVALDATA, {}).
-define(MSG_ID_ACHIEVEMENT_SCARRIVALDATA, 6102). % 获取成就数据
-define(MSG_FORMAT_ACHIEVEMENT_SCARRIVALDATA, {{?cycle,{?uint16,?uint32}},{?cycle,{?uint16}},{?cycle,{?uint16}}}).
-define(MSG_ID_ACHIEVEMENT_SCARRIVAL,    6104). % 通知达成新的成就
-define(MSG_FORMAT_ACHIEVEMENT_SCARRIVAL, {?uint16,?uint32,?uint8}).
-define(MSG_ID_ACHIEVEMENT_CSARRIVALGIFT, 6105). % 兑换成就礼品
-define(MSG_FORMAT_ACHIEVEMENT_CSARRIVALGIFT, {?uint16}).
-define(MSG_ID_ACHIEVEMENT_SCARRIVALGIFT, 6106). % 兑换成就礼品
-define(MSG_FORMAT_ACHIEVEMENT_SCARRIVALGIFT, {?uint16}).
-define(MSG_ID_ACHIEVEMENT_CSTITLECHANGE, 6201). % 更改称号
-define(MSG_FORMAT_ACHIEVEMENT_CSTITLECHANGE, {?uint16}).
-define(MSG_ID_ACHIEVEMENT_SCTITLECHANGE, 6202). % 更改称号
-define(MSG_FORMAT_ACHIEVEMENT_SCTITLECHANGE, {?uint32,?uint16}).
-define(MSG_ID_ACHIEVEMENT_CS_TITLE_LIST, 6203). % 已有称号列表
-define(MSG_FORMAT_ACHIEVEMENT_CS_TITLE_LIST, {}).
-define(MSG_ID_ACHIEVEMENT_SC_TITLE_LIST, 6204). % 已有称号列表
-define(MSG_FORMAT_ACHIEVEMENT_SC_TITLE_LIST, {{?cycle,{?uint16,?uint32}}}).
-define(MSG_ID_ACHIEVEMENT_SC_TITLE_CHANGE, 6206). % 称号获得或取消
-define(MSG_FORMAT_ACHIEVEMENT_SC_TITLE_CHANGE, {?uint16,?bool,?uint32}).
-define(MSG_ID_ACHIEVEMENT_CS_INVALIDATE, 6207). % 称号失效
-define(MSG_FORMAT_ACHIEVEMENT_CS_INVALIDATE, {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% home  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_HOME,                8000). % 家园系统
-define(MODULE_PACKET_HOME,              home_packet). 
-define(MODULE_HANDLER_HOME,             home_handler). 

-define(MSG_ID_HOME_CS_MAIN,             7001). % 家园主系统
-define(MSG_FORMAT_HOME_CS_MAIN,         {}).
-define(MSG_ID_HOME_SC_MAIN,             7002). % 家园主系统
-define(MSG_FORMAT_HOME_SC_MAIN,         {?uint8,?uint32,{?cycle,{?uint32,?string,?uint8,?uint8,?uint8}},{?cycle,{?uint8,?uint8,?uint32,?uint8}},?uint8,?uint8,{?cycle,{?uint8,?uint8,?uint32,?string,?uint8,?uint8,?uint32}},{?cycle,{?uint8,?string,?string,?uint8,?uint32}},?uint32}).
-define(MSG_ID_HOME_SC_SLAVER_INFO,      7004). % 奴隶主信息
-define(MSG_FORMAT_HOME_SC_SLAVER_INFO,  {?uint32,?string,?uint8,?uint8,?uint8,?uint32}).
-define(MSG_ID_HOME_CS_LVUPHOME,         7007). % 升级家园
-define(MSG_FORMAT_HOME_CS_LVUPHOME,     {}).
-define(MSG_ID_HOME_SC_LVUPHOME,         7008). % 升级家园返回
-define(MSG_FORMAT_HOME_SC_LVUPHOME,     {?uint32}).
-define(MSG_ID_HOME_CS_DAILY_AWARD,      7009). % 领取封邑日常奖励
-define(MSG_FORMAT_HOME_CS_DAILY_AWARD,  {}).
-define(MSG_ID_HOME_SC_GET_AWARD,        7010). % 封邑日常奖励信息
-define(MSG_FORMAT_HOME_SC_GET_AWARD,    {?uint8}).
-define(MSG_ID_HOME_CS_OFFICE_TASK,      7011). % 请求封邑官府任务信息
-define(MSG_FORMAT_HOME_CS_OFFICE_TASK,  {}).
-define(MSG_ID_HOME_SC_OFFICE_TASK,      7012). % 封邑官府信息返回
-define(MSG_FORMAT_HOME_SC_OFFICE_TASK,  {{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint8}},?uint32}).
-define(MSG_ID_HOME_CS_REFRESH_TASK,     7013). % 封邑日常任务刷新
-define(MSG_FORMAT_HOME_CS_REFRESH_TASK, {?uint8}).
-define(MSG_ID_HOME_SC_REFRESH_ONE_TASK, 7014). % 刷新单个封邑官府任务
-define(MSG_FORMAT_HOME_SC_REFRESH_ONE_TASK, {?uint8,?uint8,?uint8,?uint32,?uint8}).
-define(MSG_ID_HOME_CS_TASK_OPERATE,     7015). % 任务操作请求
-define(MSG_FORMAT_HOME_CS_TASK_OPERATE, {?uint8,?uint8}).
-define(MSG_ID_HOME_SC_TASK_TIMES,       7016). % 官府任务完成次数
-define(MSG_FORMAT_HOME_SC_TASK_TIMES,   {?uint8}).
-define(MSG_ID_HOME_SC_GUIDE_INFO,       7100). % 每日引导返回
-define(MSG_FORMAT_HOME_SC_GUIDE_INFO,   {?uint8,?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_HOME_CS_GIRL_INFO,        7101). % 请求仕女苑抢夺仇人信息
-define(MSG_FORMAT_HOME_CS_GIRL_INFO,    {}).
-define(MSG_ID_HOME_SC_GIRL_INFO,        7102). % 仕女信息返回
-define(MSG_FORMAT_HOME_SC_GIRL_INFO,    {{?cycle,{?uint32,?string,?uint16,?uint8,?uint8,?uint8,?uint32,?uint32,?string,?uint32}},{?cycle,{?uint32,?string,?uint16,?uint8,?uint8,?uint8,?uint32,?uint32,?string,?uint32}},?uint8,?uint32}).
-define(MSG_ID_HOME_CS_START_BATTLE,     7103). % 抢夺仕女发起战斗
-define(MSG_FORMAT_HOME_CS_START_BATTLE, {?uint8,?uint32}).
-define(MSG_ID_HOME_SC_GIRL_INFO1,       7104). % 侍女信息--玩法说明
-define(MSG_FORMAT_HOME_SC_GIRL_INFO1,   {?uint8,?uint8,?uint8,?uint32}).
-define(MSG_ID_HOME_CS_RESCUE_BATTLE,    7105). % 解救好友发起战斗
-define(MSG_FORMAT_HOME_CS_RESCUE_BATTLE, {?uint32}).
-define(MSG_ID_HOME_CS_RECURIT_INFO,     7109). % 请求招募仕女信息
-define(MSG_FORMAT_HOME_CS_RECURIT_INFO, {}).
-define(MSG_ID_HOME_SC_RECURIT_INFO,     7110). % 招募信息返回
-define(MSG_FORMAT_HOME_SC_RECURIT_INFO, {?uint32,{?cycle,{?uint8}}}).
-define(MSG_ID_HOME_CS_RECUIT_GIRL,      7113). % 请求招募仕女
-define(MSG_FORMAT_HOME_CS_RECUIT_GIRL,  {?uint8}).
-define(MSG_ID_HOME_SC_RECURIT_GIRL,     7114). % 招募返回
-define(MSG_FORMAT_HOME_SC_RECURIT_GIRL, {?uint8}).
-define(MSG_ID_HOME_CS_LOOSEN,           7117). % 请求松土
-define(MSG_FORMAT_HOME_CS_LOOSEN,       {?uint32,?uint8}).
-define(MSG_ID_HOME_SC_LOOSEN,           7118). % 松土返回
-define(MSG_FORMAT_HOME_SC_LOOSEN,       {?uint8}).
-define(MSG_ID_HOME_CS_ADD_TIMES,        7119). % 增加抓捕次数
-define(MSG_FORMAT_HOME_CS_ADD_TIMES,    {}).
-define(MSG_ID_HOME_SC_LOOSEN_STATE,     7122). % 松土状态更新
-define(MSG_FORMAT_HOME_SC_LOOSEN_STATE, {?uint32,?uint8}).
-define(MSG_ID_HOME_CS_BLACK_GIRL_PLAY,  7129). % 小黑屋侍女互动
-define(MSG_FORMAT_HOME_CS_BLACK_GIRL_PLAY, {?uint8,?uint8}).
-define(MSG_ID_HOME_SC_GIRL_PLAY,        7130). % 互动成功返回
-define(MSG_FORMAT_HOME_SC_GIRL_PLAY,    {?uint8}).
-define(MSG_ID_HOME_CS_HOMEMAIN_GIRL_PLAY, 7131). % 主界面仕女互动
-define(MSG_FORMAT_HOME_CS_HOMEMAIN_GIRL_PLAY, {?uint8}).
-define(MSG_ID_HOME_SC_HOME_FRIENDS_GIRLS, 7132). % 好友仕女已经招募列表
-define(MSG_FORMAT_HOME_SC_HOME_FRIENDS_GIRLS, {{?cycle,{?uint8}}}).
-define(MSG_ID_HOME_CS_RESIST,           7133). % 反抗
-define(MSG_FORMAT_HOME_CS_RESIST,       {}).
-define(MSG_ID_HOME_CS_RESCUE_LIST,      7135). % 请求需解救列表
-define(MSG_FORMAT_HOME_CS_RESCUE_LIST,  {}).
-define(MSG_ID_HOME_SC_RESCUE_LIST,      7136). % 返回需要被解救列表
-define(MSG_FORMAT_HOME_SC_RESCUE_LIST,  {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?uint32,?string,?uint32}}}).
-define(MSG_ID_HOME_CS_INVITE_RESCUE,    7137). % 邀请好友解救
-define(MSG_FORMAT_HOME_CS_INVITE_RESCUE, {?uint32}).
-define(MSG_ID_HOME_SC_INVITE_RESCUE,    7138). % 返回邀请好友解救
-define(MSG_FORMAT_HOME_SC_INVITE_RESCUE, {?uint32,?string,?uint32,?string,?uint32}).
-define(MSG_ID_HOME_CS_INVITE_RESULT,    7139). % 回复邀请结果
-define(MSG_FORMAT_HOME_CS_INVITE_RESULT, {?uint32,?uint8}).
-define(MSG_ID_HOME_CS_PRESS,            7141). % 压榨|抽干请求
-define(MSG_FORMAT_HOME_CS_PRESS,        {?uint8,?uint8}).
-define(MSG_ID_HOME_CS_FAWN,             7143). % 献媚
-define(MSG_FORMAT_HOME_CS_FAWN,         {}).
-define(MSG_ID_HOME_MSG_SC_USER_STATE,   7144). % 人物状态改变
-define(MSG_FORMAT_HOME_MSG_SC_USER_STATE, {?uint32,?uint8}).
-define(MSG_ID_HOME_MSG_SC_MAIN_BLACK,   7146). % 主界面小黑屋侍女信息
-define(MSG_FORMAT_HOME_MSG_SC_MAIN_BLACK, {{?cycle,{?uint8,?uint8,?uint32,?string,?uint8,?uint8,?uint32}}}).
-define(MSG_ID_HOME_SC_INTER_INFO,       7148). % 互动信息
-define(MSG_FORMAT_HOME_SC_INTER_INFO,   {?uint8,?string,?string,?uint8,?uint32}).
-define(MSG_ID_HOME_CS_BLACK_GIRLINFO,   7201). % 请求小黑屋仕女信息
-define(MSG_FORMAT_HOME_CS_BLACK_GIRLINFO, {}).
-define(MSG_ID_HOME_SC_BLACK_GIRLINFO,   7202). % 请求小黑屋信息返回
-define(MSG_FORMAT_HOME_SC_BLACK_GIRLINFO, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_HOME_CS_SHOW_GIRL,        7207). % 请求展示仕女
-define(MSG_FORMAT_HOME_CS_SHOW_GIRL,    {?uint8}).
-define(MSG_ID_HOME_CS_RELEASE_GIRL,     7209). % 手动释放侍女
-define(MSG_FORMAT_HOME_CS_RELEASE_GIRL, {?uint8}).
-define(MSG_ID_HOME_SC_RELEASE_GIRL,     7210). % 手动释放返回
-define(MSG_FORMAT_HOME_SC_RELEASE_GIRL, {?uint8}).
-define(MSG_ID_HOME_CS_OTHERHOME,        7405). % 进入别人家园
-define(MSG_FORMAT_HOME_CS_OTHERHOME,    {?uint32}).
-define(MSG_ID_HOME_SC_OTHERHOME,        7406). % 进入别人家园返回
-define(MSG_FORMAT_HOME_SC_OTHERHOME,    {{?cycle,{?uint8,?uint8,?uint32,?uint8}},?uint8,?uint8,?uint32}).
-define(MSG_ID_HOME_CS_GROUND_INFO,      7407). % 请求玩家土地信息
-define(MSG_FORMAT_HOME_CS_GROUND_INFO,  {?uint32}).
-define(MSG_ID_HOME_SC_GROUND_INFO,      7408). % 土地信息返回
-define(MSG_FORMAT_HOME_SC_GROUND_INFO,  {{?cycle,{?uint8,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_HOME_CS_PLANT,            7409). % 神树种植
-define(MSG_FORMAT_HOME_CS_PLANT,        {?uint8,?uint8}).
-define(MSG_ID_HOME_SC_PLANT,            7410). % 神树种植返回
-define(MSG_FORMAT_HOME_SC_PLANT,        {?uint8,?uint8}).
-define(MSG_ID_HOME_CS_REFRESHPLANT,     7411). % 神树刷新
-define(MSG_FORMAT_HOME_CS_REFRESHPLANT, {?uint8}).
-define(MSG_ID_HOME_SC_REFRESHPLANT,     7412). % 神树刷新返回
-define(MSG_FORMAT_HOME_SC_REFRESHPLANT, {?uint8,?uint16,?uint32}).
-define(MSG_ID_HOME_CS_KEYREFRESH,       7413). % 一键刷新
-define(MSG_FORMAT_HOME_CS_KEYREFRESH,   {?uint8}).
-define(MSG_ID_HOME_SC_KEYREFRESH,       7414). % 一键刷新返回
-define(MSG_FORMAT_HOME_SC_KEYREFRESH,   {?uint32}).
-define(MSG_ID_HOME_CS_GROUNDLVUP,       7415). % 土地升级
-define(MSG_FORMAT_HOME_CS_GROUNDLVUP,   {?uint8}).
-define(MSG_ID_HOME_SC_GROUNDLVUP,       7416). % 土地升级返回
-define(MSG_FORMAT_HOME_SC_GROUNDLVUP,   {?uint8,?uint8}).
-define(MSG_ID_HOME_CS_CLEARCOLD,        7417). % 清除土地种植冷却时间
-define(MSG_FORMAT_HOME_CS_CLEARCOLD,    {?uint8}).
-define(MSG_ID_HOME_SC_CLEARCOLD,        7418). % 清除土地种植冷却时间返回
-define(MSG_FORMAT_HOME_SC_CLEARCOLD,    {?uint8}).
-define(MSG_ID_HOME_CS_OPENPLANT,        7419). % 开启种植栏
-define(MSG_FORMAT_HOME_CS_OPENPLANT,    {?uint8}).
-define(MSG_ID_HOME_SC_OPENPLANT,        7420). % 开启种植栏返回
-define(MSG_FORMAT_HOME_SC_OPENPLANT,    {?uint8}).
-define(MSG_ID_HOME_CS_HARVEST,          7421). % 土地块收获
-define(MSG_FORMAT_HOME_CS_HARVEST,      {?uint8}).
-define(MSG_ID_HOME_SC_HARVEST,          7422). % 土地块收获返回
-define(MSG_FORMAT_HOME_SC_HARVEST,      {?uint8,?uint32}).
-define(MSG_ID_HOME_CS_PLANT_REWARD,     7423). % 请求土地收获信息
-define(MSG_FORMAT_HOME_CS_PLANT_REWARD, {?uint8}).
-define(MSG_ID_HOME_SC_PLANT_REWARD,     7424). % 信息返回
-define(MSG_FORMAT_HOME_SC_PLANT_REWARD, {?uint32}).
-define(MSG_ID_HOME_CS_OFFICE_AWARD,     7609). % 请求官府俸禄信息
-define(MSG_FORMAT_HOME_CS_OFFICE_AWARD, {}).
-define(MSG_ID_HOME_SC_OFFICE_AWARD,     7610). % 官府俸禄信息返回
-define(MSG_FORMAT_HOME_SC_OFFICE_AWARD, {?bool}).
-define(MSG_ID_HOME_CS_GETACTIVES,       7611). % 领取俸禄
-define(MSG_FORMAT_HOME_CS_GETACTIVES,   {?uint8}).
-define(MSG_ID_HOME_CS_CLEAR_MESSAGE,    7901). % 请求清空留言版
-define(MSG_FORMAT_HOME_CS_CLEAR_MESSAGE, {}).
-define(MSG_ID_HOME_SC_CLEAR_MESSAGE,    7902). % 清空留言版返回
-define(MSG_FORMAT_HOME_SC_CLEAR_MESSAGE, {?uint8}).
-define(MSG_ID_HOME_CS_DECLEAR_INFO,     7903). % 请求城池信息
-define(MSG_FORMAT_HOME_CS_DECLEAR_INFO, {?uint32}).
-define(MSG_ID_HOME_SC_DECLEAR_INFO,     7904). % 城池信息返回
-define(MSG_FORMAT_HOME_SC_DECLEAR_INFO, {?uint8,?uint8,?uint8,?uint8,?uint8,?string}).
-define(MSG_ID_HOME_CS_ETDIT_OWNER,      7905). % 编辑城主宣言
-define(MSG_FORMAT_HOME_CS_ETDIT_OWNER,  {?string}).
-define(MSG_ID_HOME_SC_EDIT_OWNER,       7906). % 编辑城主宣言返回
-define(MSG_FORMAT_HOME_SC_EDIT_OWNER,   {?uint8}).
-define(MSG_ID_HOME_CS_LEAVE_MESSAGE,    7907). % 玩家留言
-define(MSG_FORMAT_HOME_CS_LEAVE_MESSAGE, {?uint32,?string}).
-define(MSG_ID_HOME_SC_EDIT_MESSAGE,     7908). % 编辑留言返回
-define(MSG_FORMAT_HOME_SC_EDIT_MESSAGE, {?uint8}).
-define(MSG_ID_HOME_CS_APPLY_LEAVE_MESSAGE, 7909). % 请求玩家留言信息
-define(MSG_FORMAT_HOME_CS_APPLY_LEAVE_MESSAGE, {?uint32}).
-define(MSG_ID_HOME_SC_LEAVE_MESSAGE,    7910). % 请求玩家留言返回
-define(MSG_FORMAT_HOME_SC_LEAVE_MESSAGE, {{?cycle,{?uint8,?uint32,?string,?uint32,?string}}}).
-define(MSG_ID_HOME_CS_DELETE_MESSAGE,   7911). % 删除留言
-define(MSG_FORMAT_HOME_CS_DELETE_MESSAGE, {?uint8}).
-define(MSG_ID_HOME_SC_DELETE_MESSAGE,   7912). % 删除留言返回
-define(MSG_FORMAT_HOME_SC_DELETE_MESSAGE, {?uint8}).
-define(MSG_ID_HOME_CS_VISIT_RECORD,     7913). % 请求访客记录
-define(MSG_FORMAT_HOME_CS_VISIT_RECORD, {?uint32}).
-define(MSG_ID_HOME_SC_VISIT_RECORD,     7914). % 访客记录返回
-define(MSG_FORMAT_HOME_SC_VISIT_RECORD, {{?cycle,{?uint32,?uint32,{?cycle,{?uint8,?string}}}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% chat  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CHAT,                9000). % 聊天
-define(MODULE_PACKET_CHAT,              chat_packet). 
-define(MODULE_HANDLER_CHAT,             chat_handler). 

-define(MSG_ID_CHAT_CS_CHAT,             8001). % 聊天
-define(MSG_FORMAT_CHAT_CS_CHAT,         {?uint8,?string,{?cycle,{?uint8,?uint16,?uint8}}}).
-define(MSG_ID_CHAT_SC_CHAT,             8002). % 聊天非装备信息返回
-define(MSG_FORMAT_CHAT_SC_CHAT,         {?uint8,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint8,?uint8,?string,{?cycle,{?uint8,?uint32,?uint16,?uint8,?uint32,?uint16,?bool,?uint32,?uint32,?uint32}},{?cycle,{?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}}}).
-define(MSG_ID_CHAT_SC_SYS,              8006). % 系统信息
-define(MSG_FORMAT_CHAT_SC_SYS,          {?uint8,?string,?uint8,?uint32}).
-define(MSG_ID_CHAT_CS_PRIVATE,          8011). % 私聊发送
-define(MSG_FORMAT_CHAT_CS_PRIVATE,      {?uint32,?string}).
-define(MSG_ID_CHAT_SC_PRIVATE,          8012). % 私聊接收
-define(MSG_FORMAT_CHAT_SC_PRIVATE,      {?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint8,?string}).
-define(MSG_ID_CHAT_SC_BLACK,            8014). % 黑名单接收
-define(MSG_FORMAT_CHAT_SC_BLACK,        {?uint32}).
-define(MSG_ID_CHAT_CS_REQUEST_DATA,     8021). % 请求对方信息
-define(MSG_FORMAT_CHAT_CS_REQUEST_DATA, {?uint32,?uint8}).
-define(MSG_ID_CHAT_SC_USER_DATA,        8022). % 对方信息
-define(MSG_FORMAT_CHAT_SC_USER_DATA,    {?uint32,?string,?uint8,?uint8,?uint8,?uint8,?string,?uint8,?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% mail  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MAIL,                10000). % 邮件
-define(MODULE_PACKET_MAIL,              mail_packet). 
-define(MODULE_HANDLER_MAIL,             mail_handler). 

-define(MSG_ID_MAIL_CS_LIST_REQUEST,     9001). % 请求邮件列表
-define(MSG_FORMAT_MAIL_CS_LIST_REQUEST, {}).
-define(MSG_ID_MAIL_SC_LIST_INFO,        9002). % 返回邮件列表信息
-define(MSG_FORMAT_MAIL_SC_LIST_INFO,    {?uint32,?uint32,?uint8,?uint32,?string,?uint32,?string,?string,?uint32,?string,?uint32,?uint32,?uint32,?bool,?bool,?bool,{?cycle,{?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}},?uint32,?uint8,?uint16,{?cycle,{{?cycle,{?string}}}}}).
-define(MSG_ID_MAIL_CS_READ,             9003). % 读取邮件
-define(MSG_FORMAT_MAIL_CS_READ,         {?uint32}).
-define(MSG_ID_MAIL_CS_DELETE,           9005). % 删除信件
-define(MSG_FORMAT_MAIL_CS_DELETE,       {{?cycle,{?uint32}}}).
-define(MSG_ID_MAIL_SC_DELETE,           9006). % 删除信件返回
-define(MSG_FORMAT_MAIL_SC_DELETE,       {{?cycle,{?uint32}}}).
-define(MSG_ID_MAIL_CS_SAVE,             9011). % 保存信件
-define(MSG_FORMAT_MAIL_CS_SAVE,         {{?cycle,{?uint32}}}).
-define(MSG_ID_MAIL_SC_SAVE,             9012). % 保存信件返回
-define(MSG_FORMAT_MAIL_SC_SAVE,         {?uint8,{?cycle,{?uint32}}}).
-define(MSG_ID_MAIL_CS_GET_ATTACH,       9013). % 提取附件
-define(MSG_FORMAT_MAIL_CS_GET_ATTACH,   {?uint32}).
-define(MSG_ID_MAIL_SC_GET_ATTACH,       9014). % 提取附件返回
-define(MSG_FORMAT_MAIL_SC_GET_ATTACH,   {?uint8}).
-define(MSG_ID_MAIL_CS_GET_ALL,          9015). % 领取所有附件
-define(MSG_FORMAT_MAIL_CS_GET_ALL,      {}).
-define(MSG_ID_MAIL_CS_SEND,             9021). % 发送邮件
-define(MSG_FORMAT_MAIL_CS_SEND,         {?string,?string,?string,?uint8}).
-define(MSG_ID_MAIL_SC_SEND_RESULT,      9022). % 发送邮件结果
-define(MSG_FORMAT_MAIL_SC_SEND_RESULT,  {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% pet  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PET,                 11000). % 宠物
-define(MODULE_PACKET_PET,               pet_packet). 
-define(MODULE_HANDLER_PET,              pet_handler). 

-define(MSG_ID_PET_LIST_REQUEST,         10001). % 获取宠物列表
-define(MSG_FORMAT_PET_LIST_REQUEST,     {}).
-define(MSG_ID_PET_LIST_ANSWER,          10002). % 宠物列表返回
-define(MSG_FORMAT_PET_LIST_ANSWER,      {?uint8,?uint8,{?cycle,{?uint32,?uint32,?uint8,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8,?uint8,?uint32,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_PET_OPEN_COLUMN_REQU,     10003). % 开启宠物栏
-define(MSG_FORMAT_PET_OPEN_COLUMN_REQU, {}).
-define(MSG_ID_PET_OPEN_COLUMN_ANSW,     10004). % 开启宠物栏返回
-define(MSG_FORMAT_PET_OPEN_COLUMN_ANSW, {?uint8,?uint8}).
-define(MSG_ID_PET_BORN_REQUEST,         10005). % 宠物孵化
-define(MSG_FORMAT_PET_BORN_REQUEST,     {?uint32}).
-define(MSG_ID_PET_BORN_ANSWER,          10006). % 宠物孵化返回
-define(MSG_FORMAT_PET_BORN_ANSWER,      {?uint8,?uint32}).
-define(MSG_ID_PET_CHANGE_STATUS_RE,     10007). % 更改宠物状态
-define(MSG_FORMAT_PET_CHANGE_STATUS_RE, {?uint32}).
-define(MSG_ID_PET_CHANGE_STATUS_AN,     10008). % 更改宠物状态返回
-define(MSG_FORMAT_PET_CHANGE_STATUS_AN, {?uint8,?uint32,?uint8}).
-define(MSG_ID_PET_RENAME_REQUEST,       10009). % 宠物改名
-define(MSG_FORMAT_PET_RENAME_REQUEST,   {?uint32,?string}).
-define(MSG_ID_PET_RENAME_ANSWER,        10010). % 宠物改名返回
-define(MSG_FORMAT_PET_RENAME_ANSWER,    {?uint8,?uint32,?string,?uint8}).
-define(MSG_ID_PET_USE_EXP_REQUEST,      10011). % 宠物使用经验丹
-define(MSG_FORMAT_PET_USE_EXP_REQUEST,  {?uint32}).
-define(MSG_ID_PET_USE_EXP_ANSWER,       10012). % 宠物使用经验丹返回
-define(MSG_FORMAT_PET_USE_EXP_ANSWER,   {?uint8,?uint32,?uint32,?uint32,?uint8,?uint32}).
-define(MSG_ID_PET_TRAIN_REQUEST,        10013). % 宠物训练
-define(MSG_FORMAT_PET_TRAIN_REQUEST,    {?uint32,?uint8}).
-define(MSG_ID_PET_TRAIN_ANSWER,         10014). % 宠物训练返回
-define(MSG_FORMAT_PET_TRAIN_ANSWER,     {?uint8,?uint32,?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_PET_CHANGE_CHARACTER,     10015). % 宠物更改性格
-define(MSG_FORMAT_PET_CHANGE_CHARACTER, {?uint32,?uint8,?uint32}).
-define(MSG_ID_PET_CHARACTER_RESULT,     10016). % 更改性格返回
-define(MSG_FORMAT_PET_CHARACTER_RESULT, {?uint8,?uint8,?uint32,?uint8,{?cycle,{?uint32,?uint32,?uint8,?uint8}}}).
-define(MSG_ID_PET_STUDY_SKILL,          10017). % 宠物学习技能
-define(MSG_FORMAT_PET_STUDY_SKILL,      {?uint32,?uint32}).
-define(MSG_ID_PET_STUDY_SKILL_ANS,      10018). % 宠物学习技能返回
-define(MSG_FORMAT_PET_STUDY_SKILL_ANS,  {?uint8,?uint32}).
-define(MSG_ID_PET_UPGRADE_REQUEST,      10021). % 提升资质/成长
-define(MSG_FORMAT_PET_UPGRADE_REQUEST,  {?uint32,?uint8,?uint8}).
-define(MSG_ID_PET_UPGRADE_ANSWER,       10022). % 提升资质/成长返回
-define(MSG_FORMAT_PET_UPGRADE_ANSWER,   {?uint8,?uint32,?uint8,?uint8,?uint8}).
-define(MSG_ID_PET_INHERIT,              10025). % 宠物继承
-define(MSG_FORMAT_PET_INHERIT,          {?uint32,?uint32}).
-define(MSG_ID_PET_INHERIT_ANSWER,       10026). % 宠物继承返回
-define(MSG_FORMAT_PET_INHERIT_ANSWER,   {?uint8}).
-define(MSG_ID_PET_REBORN,               10027). % 宠物返生
-define(MSG_FORMAT_PET_REBORN,           {?uint32}).
-define(MSG_ID_PET_REBORN_ANSWER,        10028). % 宠物返生返回
-define(MSG_FORMAT_PET_REBORN_ANSWER,    {?uint8,?uint32}).
-define(MSG_ID_PET_FREE,                 10029). % 宠物放生
-define(MSG_FORMAT_PET_FREE,             {?uint32}).
-define(MSG_ID_PET_FREE_ANSWER,          10030). % 宠物放生返回
-define(MSG_FORMAT_PET_FREE_ANSWER,      {?uint8,?uint32}).
-define(MSG_ID_PET_GET_SKILL,            10031). % 获取宠物技能
-define(MSG_FORMAT_PET_GET_SKILL,        {?uint32}).
-define(MSG_ID_PET_GET_SKIL_ANSWER,      10032). % 获取宠物技能返回
-define(MSG_FORMAT_PET_GET_SKIL_ANSWER,  {?uint8,?uint32,{?cycle,{?uint8,?uint32,?uint8,?uint8}},?uint8,{?cycle,{?uint8,?uint32,?uint8,?uint8}},{?cycle,{?uint8,?uint32,?uint8,?uint8}}}).
-define(MSG_ID_PET_PET_INFO,             10033). % 获取一个宠物信息
-define(MSG_FORMAT_PET_PET_INFO,         {?uint32}).
-define(MSG_ID_PET_PET_INFO_ANSWER,      10034). % 宠物信息返回
-define(MSG_FORMAT_PET_PET_INFO_ANSWER,  {?uint8,{?cycle,{?uint32,?uint32,?uint8,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8,?uint8,?uint32,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_PET_PET_ATTR_UPDATE,      10036). % 宠物单个属性改变
-define(MSG_FORMAT_PET_PET_ATTR_UPDATE,  {?uint32,?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% ability  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ABILITY,             11500). % 内功
-define(MODULE_PACKET_ABILITY,           ability_packet). 
-define(MODULE_HANDLER_ABILITY,          ability_handler). 

-define(MSG_ID_ABILITY_CS_INFO,          11001). % 获取内功信息
-define(MSG_FORMAT_ABILITY_CS_INFO,      {}).
-define(MSG_ID_ABILITY_CS_UPGRADE,       11003). % 升级内功
-define(MSG_FORMAT_ABILITY_CS_UPGRADE,   {?uint16}).
-define(MSG_ID_ABILITY_CS_CLEAR_CD,      11005). % 清除CD
-define(MSG_FORMAT_ABILITY_CS_CLEAR_CD,  {}).
-define(MSG_ID_ABILITY_CS_EXT_INFO,      11007). % 请求八门信息
-define(MSG_FORMAT_ABILITY_CS_EXT_INFO,  {?uint16,?uint8}).
-define(MSG_ID_ABILITY_CS_EXT_REFRESH,   11009). % 八门转动
-define(MSG_FORMAT_ABILITY_CS_EXT_REFRESH, {?uint16,?uint8}).
-define(MSG_ID_ABILITY_SC_CD,            11010). % 内功总CD
-define(MSG_FORMAT_ABILITY_SC_CD,        {?uint32}).
-define(MSG_ID_ABILITY_SC_INFO,          11020). % 单条内功信息
-define(MSG_FORMAT_ABILITY_SC_INFO,      {?uint16,?uint8,?uint32,?uint8}).
-define(MSG_ID_ABILITY_SC_EXT_INFO,      11030). % 八门信息
-define(MSG_FORMAT_ABILITY_SC_EXT_INFO,  {?uint8,?uint32,?uint8,?uint16,?uint8,?uint32,?uint8}).
-define(MSG_ID_ABILITY_MONEY_LEVEL_UP,   11031). % 升阶请求
-define(MSG_FORMAT_ABILITY_MONEY_LEVEL_UP, {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% camp  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CAMP,                12000). % 阵法
-define(MODULE_PACKET_CAMP,              camp_packet). 
-define(MODULE_HANDLER_CAMP,             camp_handler). 

-define(MSG_ID_CAMP_CS_INFO,             11501). % 请求阵法信息
-define(MSG_FORMAT_CAMP_CS_INFO,         {}).
-define(MSG_ID_CAMP_CS_UPGRADE,          11503). % 升级阵法
-define(MSG_FORMAT_CAMP_CS_UPGRADE,      {?uint16}).
-define(MSG_ID_CAMP_CS_REMOVE_POS,       11517). % 阵型站位移除
-define(MSG_FORMAT_CAMP_CS_REMOVE_POS,   {?uint16,?uint8}).
-define(MSG_ID_CAMP_CS_EXCHANGE_POS,     11519). % 阵型站位交换
-define(MSG_FORMAT_CAMP_CS_EXCHANGE_POS, {?uint16,?uint8,?uint8}).
-define(MSG_ID_CAMP_CS_SET_POS,          11521). % 设置阵型站位
-define(MSG_FORMAT_CAMP_CS_SET_POS,      {?uint16,?uint8,?uint8,?uint32}).
-define(MSG_ID_CAMP_CS_START_CAMP,       11523). % 启用阵型
-define(MSG_FORMAT_CAMP_CS_START_CAMP,   {?uint16}).
-define(MSG_ID_CAMP_CS_POS_INFO,         11525). % 请求阵型站位数据
-define(MSG_FORMAT_CAMP_CS_POS_INFO,     {?uint16}).
-define(MSG_ID_CAMP_SC_USE,              11600). % 当前使用阵型
-define(MSG_FORMAT_CAMP_SC_USE,          {?uint16}).
-define(MSG_ID_CAMP_SC_INFO,             11610). % 阵型信息
-define(MSG_FORMAT_CAMP_SC_INFO,         {?uint16,?uint8}).
-define(MSG_ID_CAMP_SC_NEW,              11612). % 新学习的阵法
-define(MSG_FORMAT_CAMP_SC_NEW,          {?uint16}).
-define(MSG_ID_CAMP_SC_POS_UPDATE,       11620). % 更新阵型站位信息
-define(MSG_FORMAT_CAMP_SC_POS_UPDATE,   {?uint16,?uint8,?uint8,?uint32,?uint8}).
-define(MSG_ID_CAMP_SC_POS_REMOVE,       11630). % 移除阵型站位信息
-define(MSG_FORMAT_CAMP_SC_POS_REMOVE,   {?uint16,?uint8,?uint8}).
-define(MSG_ID_CAMP_CS_POS_NULL,         11631). % 请求阵法是否有空位
-define(MSG_FORMAT_CAMP_CS_POS_NULL,     {}).
-define(MSG_ID_CAMP_SC_POS_NULL,         11632). % 阵法是否有空位
-define(MSG_FORMAT_CAMP_SC_POS_NULL,     {?bool}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% furnace  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_FURNACE,             13000). % 炼炉
-define(MODULE_PACKET_FURNACE,           furnace_packet). 
-define(MODULE_HANDLER_FURNACE,          furnace_handler). 

-define(MSG_ID_FURNACE_STREN_QUEUE,      12101). % 获取所有强化队列
-define(MSG_FORMAT_FURNACE_STREN_QUEUE,  {}).
-define(MSG_ID_FURNACE_OPEN_STREN_QUEUE, 12105). % 开启强化队列
-define(MSG_FORMAT_FURNACE_OPEN_STREN_QUEUE, {}).
-define(MSG_ID_FURNACE_CLEAR_STREN_CD,   12107). % 清除强化CD
-define(MSG_FORMAT_FURNACE_CLEAR_STREN_CD, {?uint8,?uint8}).
-define(MSG_ID_FURNACE_STREN_QUEUE_RETURN, 12108). % 强化队列推送（更新）
-define(MSG_FORMAT_FURNACE_STREN_QUEUE_RETURN, {?uint8,?uint32,?uint8,?uint8}).
-define(MSG_ID_FURNACE_SC_CANCEL_STREN_QUEUE, 12110). % 无强化队列(取消强化队列)
-define(MSG_FORMAT_FURNACE_SC_CANCEL_STREN_QUEUE, {}).
-define(MSG_ID_FURNACE_GET_USER_STREN,   12201). % 获取角色强化信息
-define(MSG_FORMAT_FURNACE_GET_USER_STREN, {}).
-define(MSG_ID_FURNACE_GET_USER_STREN_RETURN, 12202). % 角色强化信息返回
-define(MSG_FORMAT_FURNACE_GET_USER_STREN_RETURN, {?uint32,{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_FURNACE_STREN_PART,       12203). % 装备部位强化
-define(MSG_FORMAT_FURNACE_STREN_PART,   {?uint32,?uint8}).
-define(MSG_ID_FURNACE_STREN_PART_RETURN, 12204). % 装备部位强化返回
-define(MSG_FORMAT_FURNACE_STREN_PART_RETURN, {?uint32,?uint8,?uint8}).
-define(MSG_ID_FURNACE_EQUIP_FORGE,      12301). % 进行装备锻造
-define(MSG_FORMAT_FURNACE_EQUIP_FORGE,  {?uint32,?uint8}).
-define(MSG_ID_FURNACE_EQUIP_FORGE_RETURN, 12302). % 装备锻造返回
-define(MSG_FORMAT_FURNACE_EQUIP_FORGE_RETURN, {?uint8,?uint8}).
-define(MSG_ID_FURNACE_CS_UPGRADE_MULTI, 12303). % 多位置升阶
-define(MSG_FORMAT_FURNACE_CS_UPGRADE_MULTI, {?uint8,?uint32,?uint32,?uint32}).
-define(MSG_ID_FURNACE_SC_UPGRADE_MULTI, 12304). % 多位置升阶返回
-define(MSG_FORMAT_FURNACE_SC_UPGRADE_MULTI, {?uint8}).
-define(MSG_ID_FURNACE_PLUS_INHERIT,     12401). % 洗练继承
-define(MSG_FORMAT_FURNACE_PLUS_INHERIT, {?uint8,?uint16,?uint8,?uint8,?uint16,?uint8,?uint8}).
-define(MSG_ID_FURNACE_PLUS_INHERIT_RETURN, 12402). % 洗练继承返回
-define(MSG_FORMAT_FURNACE_PLUS_INHERIT_RETURN, {?uint8}).
-define(MSG_ID_FURNACE_EQUIP_PLUS,       12503). % 进行装备洗练
-define(MSG_FORMAT_FURNACE_EQUIP_PLUS,   {?uint8,?uint16,?uint8,{?cycle,{?uint8}}}).
-define(MSG_ID_FURNACE_EQUIP_PLUS_RETURN, 12504). % 装备洗练返回
-define(MSG_FORMAT_FURNACE_EQUIP_PLUS_RETURN, {?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint32,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_FURNACE_PLUS_CONFIRM,     12505). % 洗练确认
-define(MSG_FORMAT_FURNACE_PLUS_CONFIRM, {?uint8,?uint8,?uint8}).
-define(MSG_ID_FURNACE_PLUS_CONFIRM_RETURN, 12506). % 洗练确认返回
-define(MSG_FORMAT_FURNACE_PLUS_CONFIRM_RETURN, {?uint8}).
-define(MSG_ID_FURNACE_SOUL_CONFIRM,     12603). % 刻印
-define(MSG_FORMAT_FURNACE_SOUL_CONFIRM, {?uint8,?uint16,?uint8,?uint8,?uint16,?uint8,{?cycle,{?uint8,?uint8}},{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_FURNACE_SOUL_CONFIRM_RETURN, 12604). % 刻印返回
-define(MSG_FORMAT_FURNACE_SOUL_CONFIRM_RETURN, {?bool}).
-define(MSG_ID_FURNACE_GOODS_FORGE,      12701). % 道具合成
-define(MSG_FORMAT_FURNACE_GOODS_FORGE,  {?uint32,?uint8}).
-define(MSG_ID_FURNACE_GOODS_FORGE_RETURN, 12702). % 道具合成返回
-define(MSG_FORMAT_FURNACE_GOODS_FORGE_RETURN, {?uint8}).
-define(MSG_ID_FURNACE_STREN_VALUE_UPDATE, 12800). % 强化成功属性更新
-define(MSG_FORMAT_FURNACE_STREN_VALUE_UPDATE, {{?cycle,{?uint8,?uint32}}}).
-define(MSG_ID_FURNACE_SC_STYLE,         12850). % 外形
-define(MSG_FORMAT_FURNACE_SC_STYLE,     {?uint32,?uint16}).
-define(MSG_ID_FURNACE_CS_FASHION_FUSION, 12851). % 时装合成
-define(MSG_FORMAT_FURNACE_CS_FASHION_FUSION, {?uint32,?uint32}).
-define(MSG_ID_FURNACE_SC_FUSION_RETURN, 12852). % 时装合成返回
-define(MSG_FORMAT_FURNACE_SC_FUSION_RETURN, {?uint8,?uint32,?uint8}).
-define(MSG_ID_FURNACE_CS_SAVE_FASHION,  12853). % 时装保存
-define(MSG_FORMAT_FURNACE_CS_SAVE_FASHION, {?uint32,?uint32,?uint32}).
-define(MSG_ID_FURNACE_CS_EQUIP_STATES,  12855). % 请求装备激活状态
-define(MSG_FORMAT_FURNACE_CS_EQUIP_STATES, {?uint8}).
-define(MSG_ID_FURNACE_SC_EQUIP_STATES,  12856). % 返回装备激活状态
-define(MSG_FORMAT_FURNACE_SC_EQUIP_STATES, {?uint8,?uint32}).
-define(MSG_ID_FURNACE_CS_SAVE_IMAGE,    12857). % 保存形象
-define(MSG_FORMAT_FURNACE_CS_SAVE_IMAGE, {?uint32,?uint32}).
-define(MSG_ID_FURNACE_COMPOSE_STONE,    12911). % 请求合成宝石
-define(MSG_FORMAT_FURNACE_COMPOSE_STONE, {?uint32,?uint32}).
-define(MSG_ID_FURNACE_ADD_STONE,        12912). % 请求镶嵌宝石
-define(MSG_FORMAT_FURNACE_ADD_STONE,    {?uint8,?uint32,?uint32,?uint8}).
-define(MSG_ID_FURNACE_SUB_STONE,        12913). % 请求摘除宝石
-define(MSG_FORMAT_FURNACE_SUB_STONE,    {?uint8,?uint32,?uint32,?uint8}).
-define(MSG_ID_FURNACE_ADD_HOLE,         12914). % 请求打孔
-define(MSG_FORMAT_FURNACE_ADD_HOLE,     {?uint8,?uint32,?uint32}).
-define(MSG_ID_FURNACE_CHANGE_STONE,     12915). % 请求转换宝石
-define(MSG_FORMAT_FURNACE_CHANGE_STONE, {?uint8,?uint32}).
-define(MSG_ID_FURNACE_REQUEST_UP_STONE, 12916). % 请求宝石升级
-define(MSG_FORMAT_FURNACE_REQUEST_UP_STONE, {?uint8,?uint32,?uint32,?uint32}).
-define(MSG_ID_FURNACE_CS_OK_COM_STONE_QUERY, 12917). % 一键合成宝石查询
-define(MSG_FORMAT_FURNACE_CS_OK_COM_STONE_QUERY, {}).
-define(MSG_ID_FURNACE_SC_OK_COM_STONE_QUERY, 12918). % 一键合成宝石查询回复
-define(MSG_FORMAT_FURNACE_SC_OK_COM_STONE_QUERY, {?uint32}).
-define(MSG_ID_FURNACE_SC_OK_COM_STONE,  12919). % 一键合成宝石
-define(MSG_FORMAT_FURNACE_SC_OK_COM_STONE, {}).
-define(MSG_ID_FURNACE_SC_COMPOSE_STONE, 12921). % 请求合成宝石返回
-define(MSG_FORMAT_FURNACE_SC_COMPOSE_STONE, {?bool}).
-define(MSG_ID_FURNACE_SC_ADD_STONE,     12922). % 镶嵌宝石是否成功
-define(MSG_FORMAT_FURNACE_SC_ADD_STONE, {?bool}).
-define(MSG_ID_FURNACE_SC_SUB_STONE,     12923). % 摘除宝石是否成功
-define(MSG_FORMAT_FURNACE_SC_SUB_STONE, {?bool}).
-define(MSG_ID_FURNACE_SC_ADD_HOLE,      12924). % 请求打孔是否成功
-define(MSG_FORMAT_FURNACE_SC_ADD_HOLE,  {?bool}).
-define(MSG_ID_FURNACE_SC_CHANGE_STONE,  12925). % 成功转化宝石列表
-define(MSG_FORMAT_FURNACE_SC_CHANGE_STONE, {{?cycle,{?uint32,?uint32}}}).
-define(MSG_ID_FURNACE_CS_OK_TRANSFER,   12927). % 一键转移
-define(MSG_FORMAT_FURNACE_CS_OK_TRANSFER, {?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_FURNACE_SC_OK_TRANSFER,   12928). % 一键转移结果
-define(MSG_FORMAT_FURNACE_SC_OK_TRANSFER, {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% copy_single  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_COPY_SINGLE,         14000). % 副本系统
-define(MODULE_PACKET_COPY_SINGLE,       copy_single_packet). 
-define(MODULE_HANDLER_COPY_SINGLE,      copy_single_handler). 

-define(MSG_ID_COPY_SINGLE_CS_ENTER_COPY, 13001). % 进入副本
-define(MSG_FORMAT_COPY_SINGLE_CS_ENTER_COPY, {?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_MONSTER_INFO, 13002). % 怪物信息
-define(MSG_FORMAT_COPY_SINGLE_SC_MONSTER_INFO, {?uint16,?uint32,?uint8,?uint16,?uint8}).
-define(MSG_ID_COPY_SINGLE_SC_BATTLE_OK, 13004). % 发起战斗成功
-define(MSG_FORMAT_COPY_SINGLE_SC_BATTLE_OK, {?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_EXIT_COPY, 13005). % 离开副本
-define(MSG_FORMAT_COPY_SINGLE_CS_EXIT_COPY, {}).
-define(MSG_ID_COPY_SINGLE_CS_COPY_INFO, 13007). % 请求副本信息
-define(MSG_FORMAT_COPY_SINGLE_CS_COPY_INFO, {}).
-define(MSG_ID_COPY_SINGLE_SC_COPY_INFO, 13008). % 副本信息 - X
-define(MSG_FORMAT_COPY_SINGLE_SC_COPY_INFO, {{?cycle,{?uint16,?uint8}},{?cycle,{?uint16,?uint8,?uint8}}}).
-define(MSG_ID_COPY_SINGLE_CS_AGAIN,     13009). % 再次挑战副本
-define(MSG_FORMAT_COPY_SINGLE_CS_AGAIN, {}).
-define(MSG_ID_COPY_SINGLE_SC_COPY_END,  13010). % 副本已完成
-define(MSG_FORMAT_COPY_SINGLE_SC_COPY_END, {?uint16,?bool,{?cycle,{?uint32,?uint8}},?uint8,?uint32,?uint32,?uint16,?uint32,?uint32,?uint32}).
-define(MSG_ID_COPY_SINGLE_SC_UPDATE_COPY, 13012). % 副本信息更新
-define(MSG_FORMAT_COPY_SINGLE_SC_UPDATE_COPY, {?uint16,?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_RAID,      13013). % 副本扫荡请求
-define(MSG_FORMAT_COPY_SINGLE_CS_RAID,  {?uint16,?uint8}).
-define(MSG_ID_COPY_SINGLE_SC_PROCCESS_UPDATE, 13014). % 副本开启状态改变
-define(MSG_FORMAT_COPY_SINGLE_SC_PROCCESS_UPDATE, {?uint16,?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_RAID_INFO, 13015). % 请求副本扫荡信息
-define(MSG_FORMAT_COPY_SINGLE_CS_RAID_INFO, {}).
-define(MSG_ID_COPY_SINGLE_SC_RAID_INFO, 13016). % 扫荡信息
-define(MSG_FORMAT_COPY_SINGLE_SC_RAID_INFO, {?uint16,?uint16,?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_RAID_A_WAVE, 13018). % 每波扫荡结果
-define(MSG_FORMAT_COPY_SINGLE_SC_RAID_A_WAVE, {{?cycle,{?uint32,?uint16}},?uint32,?uint32,?uint32,?uint16,?uint8,?uint8,?uint8,{?cycle,{?uint32,?uint8}},?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_STOP,      13021). % 请求停止扫荡
-define(MSG_FORMAT_COPY_SINGLE_CS_STOP,  {?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_QUICK,     13023). % 快速扫荡
-define(MSG_FORMAT_COPY_SINGLE_CS_QUICK, {?uint8,?uint8}).
-define(MSG_ID_COPY_SINGLE_SC_QUICK_OK,  13024). % 完成扫荡
-define(MSG_FORMAT_COPY_SINGLE_SC_QUICK_OK, {?uint32}).
-define(MSG_ID_COPY_SINGLE_CS_BATTLE,    13025). % 发起战斗
-define(MSG_FORMAT_COPY_SINGLE_CS_BATTLE, {?uint32,?uint16,?uint8,?uint8}).
-define(MSG_ID_COPY_SINGLE_IS_EMPTY_5,   13027). % 请求背包是否有5个空位
-define(MSG_FORMAT_COPY_SINGLE_IS_EMPTY_5, {}).
-define(MSG_ID_COPY_SINGLE_SC_EMPTY,     13028). % 回复背包空位数
-define(MSG_FORMAT_COPY_SINGLE_SC_EMPTY, {?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_VIP_REQ,   13031). % 请求vip副本翻牌
-define(MSG_FORMAT_COPY_SINGLE_CS_VIP_REQ, {}).
-define(MSG_ID_COPY_SINGLE_SC_VIP_REWARD, 13032). % vip副本翻牌奖励
-define(MSG_FORMAT_COPY_SINGLE_SC_VIP_REWARD, {?uint32,?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_RESET_ELITE, 13033). % 重置精英副本次数
-define(MSG_FORMAT_COPY_SINGLE_CS_RESET_ELITE, {?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_RESET_LIST, 13034). % 副本系列重置信息
-define(MSG_FORMAT_COPY_SINGLE_SC_RESET_LIST, {{?cycle,{?uint16}}}).
-define(MSG_ID_COPY_SINGLE_SC_RESET,     13036). % 副本系列重置情况 - X
-define(MSG_FORMAT_COPY_SINGLE_SC_RESET, {?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_NOTICE_ELITE_RESET, 13038). % 0点精英副本重置
-define(MSG_FORMAT_COPY_SINGLE_SC_NOTICE_ELITE_RESET, {?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_ELITE_INFO, 13041). % 请求精英副本扫荡信息
-define(MSG_FORMAT_COPY_SINGLE_CS_ELITE_INFO, {?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_ELITE_INFO, 13042). % 返回精英副本扫荡信息
-define(MSG_FORMAT_COPY_SINGLE_SC_ELITE_INFO, {?uint16,{?cycle,{?uint16}},?uint8,?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_ELITE_RESULT, 13044). % 精英副本扫荡结果
-define(MSG_FORMAT_COPY_SINGLE_SC_ELITE_RESULT, {{?cycle,{?uint32,?uint16}},?uint32,?uint32,?uint32,?uint16,{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_COPY_SINGLE_CS_START_ELITE, 13045). % 开始精英副本扫荡
-define(MSG_FORMAT_COPY_SINGLE_CS_START_ELITE, {?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_START_ELITE, 13046). % 返回精英副本扫荡开始信息
-define(MSG_FORMAT_COPY_SINGLE_SC_START_ELITE, {?uint16,?uint16}).
-define(MSG_ID_COPY_SINGLE_SC_COPY_ALL_INFO, 13050). % 副本整体信息 - 替13008
-define(MSG_FORMAT_COPY_SINGLE_SC_COPY_ALL_INFO, {{?cycle,{?uint16,?uint8}},{?cycle,{?uint16,?uint8}},{?cycle,{?uint16}}}).
-define(MSG_ID_COPY_SINGLE_CS_AUTO_TURNCARD, 13051). % 请求扫荡自动翻牌
-define(MSG_FORMAT_COPY_SINGLE_CS_AUTO_TURNCARD, {?uint8,?bool}).
-define(MSG_ID_COPY_SINGLE_SC_AUTOCARD,  13052). % 请求自动翻牌返回
-define(MSG_FORMAT_COPY_SINGLE_SC_AUTOCARD, {?uint8,?bool}).
-define(MSG_ID_COPY_SINGLE_AUTO_TURNCARD_REWARD, 13054). % 元宝自动翻牌奖励
-define(MSG_FORMAT_COPY_SINGLE_AUTO_TURNCARD_REWARD, {?uint8,{?cycle,{?uint32,?uint16}},?uint8}).
-define(MSG_ID_COPY_SINGLE_CS_REPORT_LIST, 13055). % 请求副本战报信息
-define(MSG_FORMAT_COPY_SINGLE_CS_REPORT_LIST, {?uint32}).
-define(MSG_ID_COPY_SINGLE_SC_REPORT_LIST, 13056). % 副本战报信息
-define(MSG_FORMAT_COPY_SINGLE_SC_REPORT_LIST, {?uint32,{?cycle,{?uint32,?string,?string}}}).
-define(MSG_ID_COPY_SINGLE_CS_STEP_OK,   13057). % 步骤完成
-define(MSG_FORMAT_COPY_SINGLE_CS_STEP_OK, {?uint16,?uint8}).
-define(MSG_ID_COPY_SINGLE_SC_EQUIP,     13058). % 装备
-define(MSG_FORMAT_COPY_SINGLE_SC_EQUIP, {?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% relationship  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_RELATIONSHIP,        14500). % 好友
-define(MODULE_PACKET_RELATIONSHIP,      relationship_packet). 
-define(MODULE_HANDLER_RELATIONSHIP,     relationship_handler). 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% relation  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_RELATION,            14800). % 好友2
-define(MODULE_PACKET_RELATION,          relation_packet). 
-define(MODULE_HANDLER_RELATION,         relation_handler). 

-define(MSG_ID_RELATION_CS_LIST,         14501). % 信息列表
-define(MSG_FORMAT_RELATION_CS_LIST,     {?uint8}).
-define(MSG_ID_RELATION_SC_LIST,         14502). % 信息列表
-define(MSG_FORMAT_RELATION_SC_LIST,     {?uint8,{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?string,?uint8,?uint32,?uint32}}}).
-define(MSG_ID_RELATION_INFO_GROUP,      14504). % 好友信息协议组
-define(MSG_FORMAT_RELATION_INFO_GROUP,  {?uint32,?string,?uint8,?uint8,?uint8,?string,?uint8,?uint32,?uint32}).
-define(MSG_ID_RELATION_CS_ADD,          14511). % 增加关系
-define(MSG_FORMAT_RELATION_CS_ADD,      {?uint8,?uint32,?string}).
-define(MSG_ID_RELATION_SC_ADD,          14512). % 增加一条信息
-define(MSG_FORMAT_RELATION_SC_ADD,      {?uint8,?uint8,?uint32,?string,?uint8,?uint8,?uint8,?string,?uint8,?uint32,?uint32}).
-define(MSG_ID_RELATION_ADD_NOTICE,      14514). % 增加好友通知
-define(MSG_FORMAT_RELATION_ADD_NOTICE,  {?uint32,?string,?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_RELATION_CS_CHANGE,       14521). % 改变关系
-define(MSG_FORMAT_RELATION_CS_CHANGE,   {?uint8,?uint32,?uint8}).
-define(MSG_ID_RELATION_SC_CHANGE,       14522). % 改变关系返回
-define(MSG_FORMAT_RELATION_SC_CHANGE,   {?uint8,?uint32,?uint8}).
-define(MSG_ID_RELATION_CS_DELETE,       14531). % 删除关系人
-define(MSG_FORMAT_RELATION_CS_DELETE,   {?uint8,?uint32}).
-define(MSG_ID_RELATION_SC_DELETE,       14532). % 删除关系人
-define(MSG_FORMAT_RELATION_SC_DELETE,   {?uint8,?uint32}).
-define(MSG_ID_RELATION_SC_ON_OFF,       14540). % 上下线通知
-define(MSG_FORMAT_RELATION_SC_ON_OFF,   {?uint8,?uint32,?uint8}).
-define(MSG_ID_RELATION_CS_RECOMMEND,    14551). % 好友推荐列表
-define(MSG_FORMAT_RELATION_CS_RECOMMEND, {}).
-define(MSG_ID_RELATION_SC_RECOMMEND,    14552). % 好友推荐列表
-define(MSG_FORMAT_RELATION_SC_RECOMMEND, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?string,?uint8,?uint32,?uint32}}}).
-define(MSG_ID_RELATION_CS_ONE_KEY,      14553). % 一键添加
-define(MSG_FORMAT_RELATION_CS_ONE_KEY,  {{?cycle,{?uint32}}}).
-define(MSG_ID_RELATION_CS_COUNT,        14561). % 请求关系人数量
-define(MSG_FORMAT_RELATION_CS_COUNT,    {}).
-define(MSG_ID_RELATION_SC_COUNT,        14562). % 关系人数量
-define(MSG_FORMAT_RELATION_SC_COUNT,    {?uint8,?uint8,?uint8}).
-define(MSG_ID_RELATION_CS_ONE_KEY_DEL,  14571). % 批量删除好友
-define(MSG_FORMAT_RELATION_CS_ONE_KEY_DEL, {?uint8,{?cycle,{?uint32}}}).
-define(MSG_ID_RELATION_SC_ONE_KEY_DEL,  14572). % 批量删除好友
-define(MSG_FORMAT_RELATION_SC_ONE_KEY_DEL, {{?cycle,{?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% bless  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_BLESS,               15000). % 祝福
-define(MODULE_PACKET_BLESS,             bless_packet). 
-define(MODULE_HANDLER_BLESS,            bless_handler). 

-define(MSG_ID_BLESS_CS_BLESS,           14801). % 给好友发送祝福
-define(MSG_FORMAT_BLESS_CS_BLESS,       {?uint32,?uint32}).
-define(MSG_ID_BLESS_SC_BLESS,           14802). % 祝福/被祝福获得经验
-define(MSG_FORMAT_BLESS_SC_BLESS,       {?uint8,?uint32}).
-define(MSG_ID_BLESS_CS_GET_EXP,         14811). % 领取经验
-define(MSG_FORMAT_BLESS_CS_GET_EXP,     {}).
-define(MSG_ID_BLESS_CS_BATTLE_DATA,     14815). % 请求祝福瓶信息
-define(MSG_FORMAT_BLESS_CS_BATTLE_DATA, {}).
-define(MSG_ID_BLESS_SC_BATTLE_DATA,     14816). % 经验瓶信息
-define(MSG_FORMAT_BLESS_SC_BATTLE_DATA, {?uint32,?uint8}).
-define(MSG_ID_BLESS_BATTLE_INFO,        14818). % 经验瓶信息
-define(MSG_FORMAT_BLESS_BATTLE_INFO,    {?uint8,?uint32,?uint8}).
-define(MSG_ID_BLESS_SC_BLESS_DATA,      14820). % 祝福信息
-define(MSG_FORMAT_BLESS_SC_BLESS_DATA,  {?uint8,?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?string,?uint32,?uint32}).
-define(MSG_ID_BLESS_CS_ONE_KEY,         14831). % 一键祝福
-define(MSG_FORMAT_BLESS_CS_ONE_KEY,     {}).
-define(MSG_ID_BLESS_CS_READ,            14833). % 读取祝福
-define(MSG_FORMAT_BLESS_CS_READ,        {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% guild_party  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUILD_PARTY,         15500). % 军团宴会
-define(MODULE_PACKET_GUILD_PARTY,       guild_party_packet). 
-define(MODULE_HANDLER_GUILD_PARTY,      guild_party_handler). 

-define(MSG_ID_GUILD_PARTY_CS_LIST,      15001). % 请求军团列表
-define(MSG_FORMAT_GUILD_PARTY_CS_LIST,  {}).
-define(MSG_ID_GUILD_PARTY_SC_LIST,      15002). % 返回军团列表
-define(MSG_FORMAT_GUILD_PARTY_SC_LIST,  {{?cycle,{?uint32,?uint32,?string,?string,?uint8,?uint8,?uint32,?uint32,?uint8,?string}},?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_PASSAPPLY, 15003). % 同意申请请求
-define(MSG_FORMAT_GUILD_PARTY_CS_PASSAPPLY, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PASSAPPLY, 15004). % 同意申请返回
-define(MSG_FORMAT_GUILD_PARTY_SC_PASSAPPLY, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_REFUSEAPPLY, 15005). % 拒绝申请请求
-define(MSG_FORMAT_GUILD_PARTY_CS_REFUSEAPPLY, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_REFUSEAPPLY, 15006). % 拒绝申请返回
-define(MSG_FORMAT_GUILD_PARTY_SC_REFUSEAPPLY, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_CREATEGUILD, 15007). % 创建军团请求
-define(MSG_FORMAT_GUILD_PARTY_CS_CREATEGUILD, {?string,?string}).
-define(MSG_ID_GUILD_PARTY_SC_CREATEGUILD, 15008). % 创建军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_CREATEGUILD, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_DONATECOIN, 15009). % 捐献铜钱申请
-define(MSG_FORMAT_GUILD_PARTY_CS_DONATECOIN, {?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_DONATECOIN, 15010). % 捐献铜钱返回
-define(MSG_FORMAT_GUILD_PARTY_SC_DONATECOIN, {?uint8,?uint32,?uint32,?uint8,?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_JOINGUILD, 15011). % 加入军团申请
-define(MSG_FORMAT_GUILD_PARTY_CS_JOINGUILD, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_JOINGUILD, 15012). % 加入军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_JOINGUILD, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_DISBANDGUILD, 15013). % 解散军团请求
-define(MSG_FORMAT_GUILD_PARTY_CS_DISBANDGUILD, {}).
-define(MSG_ID_GUILD_PARTY_SC_DISBANDGUILD, 15014). % 解散军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_DISBANDGUILD, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_STATE_CHANGE, 15016). % 军团状态发生变更返回
-define(MSG_FORMAT_GUILD_PARTY_SC_STATE_CHANGE, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_QUITGUILD, 15017). % 退出军团申请
-define(MSG_FORMAT_GUILD_PARTY_CS_QUITGUILD, {}).
-define(MSG_ID_GUILD_PARTY_SC_QUITGUILD, 15018). % 退出军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_QUITGUILD, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_CANCELAPLLY, 15019). % 取消申请加入军团
-define(MSG_FORMAT_GUILD_PARTY_CS_CANCELAPLLY, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_CANCELAPPLY, 15020). % 取消申请加入军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_CANCELAPPLY, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_LEARNMAGIC, 15021). % 学习军团术法申请
-define(MSG_FORMAT_GUILD_PARTY_CS_LEARNMAGIC, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_LEARNMAGIC, 15022). % 学习军团术法返回
-define(MSG_FORMAT_GUILD_PARTY_SC_LEARNMAGIC, {?uint8,?uint32,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_DEFAULTSKILL, 15023). % 设置军团默认技能申请
-define(MSG_FORMAT_GUILD_PARTY_CS_DEFAULTSKILL, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_DEFAULTSKILL, 15024). % 设置军团默认技能返回
-define(MSG_FORMAT_GUILD_PARTY_SC_DEFAULTSKILL, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_GUILDINFO, 15025). % 请求军团详情信息
-define(MSG_FORMAT_GUILD_PARTY_CS_GUILDINFO, {}).
-define(MSG_ID_GUILD_PARTY_SC_GUILDINFO, 15026). % 请求军团详情信息返回
-define(MSG_FORMAT_GUILD_PARTY_SC_GUILDINFO, {?uint8,?string,?uint8,?uint32,?uint32,?string,?string,?uint8,?uint32,?string,?string,?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_GUILDMEM,  15027). % 加载成员列表请求
-define(MSG_FORMAT_GUILD_PARTY_CS_GUILDMEM, {}).
-define(MSG_ID_GUILD_PARTY_SC_GUILDMEM,  15028). % 加载成员列表返回
-define(MSG_FORMAT_GUILD_PARTY_SC_GUILDMEM, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?string}}}).
-define(MSG_ID_GUILD_PARTY_CS_SKILLLIST, 15029). % 技能列表请求
-define(MSG_FORMAT_GUILD_PARTY_CS_SKILLLIST, {}).
-define(MSG_ID_GUILD_PARTY_SC_SKILLLIST, 15030). % 技能列表返回
-define(MSG_FORMAT_GUILD_PARTY_SC_SKILLLIST, {?uint32,?uint32,?uint8,{?cycle,{?uint32,?uint8,?uint32}}}).
-define(MSG_ID_GUILD_PARTY_CS_MAGICLIST, 15031). % 术法列表请求
-define(MSG_FORMAT_GUILD_PARTY_CS_MAGICLIST, {}).
-define(MSG_ID_GUILD_PARTY_SC_MAGICLIST, 15032). % 术法列表返回
-define(MSG_FORMAT_GUILD_PARTY_SC_MAGICLIST, {?uint32,{?cycle,{?uint32,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_GUILD_PARTY_CS_TRESUARE,  15033). % 请求军团宝藏信息
-define(MSG_FORMAT_GUILD_PARTY_CS_TRESUARE, {}).
-define(MSG_ID_GUILD_PARTY_SC_TREASURE,  15034). % 军团宝藏信息返回
-define(MSG_FORMAT_GUILD_PARTY_SC_TREASURE, {?uint8,?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_APPLYLIST, 15035). % 军团申请列表请求
-define(MSG_FORMAT_GUILD_PARTY_CS_APPLYLIST, {}).
-define(MSG_ID_GUILD_PARTY_SC_APPLYLIST, 15036). % 军团申请列表返回
-define(MSG_FORMAT_GUILD_PARTY_SC_APPLYLIST, {?uint8,{?cycle,{?uint32,?string,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_GUILD_PARTY_CS_KICKOUT,   15037). % 踢出军团请求
-define(MSG_FORMAT_GUILD_PARTY_CS_KICKOUT, {?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_KICKOUT,   15038). % 踢出军团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_KICKOUT, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_CHIEF,     15039). % 提升至军团长
-define(MSG_FORMAT_GUILD_PARTY_CS_CHIEF, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_CHIEF,     15040). % 提升至军团长返回
-define(MSG_FORMAT_GUILD_PARTY_SC_CHIEF, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_VICECHIEF, 15041). % 提升至副军团长
-define(MSG_FORMAT_GUILD_PARTY_CS_VICECHIEF, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_VICECHIEF, 15042). % 提升至副军团长返回
-define(MSG_FORMAT_GUILD_PARTY_SC_VICECHIEF, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_AUTO,      15043). % 自动提升职位
-define(MSG_FORMAT_GUILD_PARTY_CS_AUTO,  {}).
-define(MSG_ID_GUILD_PARTY_SC_AUTO,      15044). % 自动提升职位返回
-define(MSG_FORMAT_GUILD_PARTY_SC_AUTO,  {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_REMOVEDUTY, 15045). % 移除职位
-define(MSG_FORMAT_GUILD_PARTY_CS_REMOVEDUTY, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_REMOVEDUTY, 15046). % 移除职位返回
-define(MSG_FORMAT_GUILD_PARTY_SC_REMOVEDUTY, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_IMPEACHCHIEF, 15047). % 弹劾军团长
-define(MSG_FORMAT_GUILD_PARTY_CS_IMPEACHCHIEF, {}).
-define(MSG_ID_GUILD_PARTY_SC_IMPEACHCHIEF, 15048). % 弹劾军团长返回
-define(MSG_FORMAT_GUILD_PARTY_SC_IMPEACHCHIEF, {?uint8,?uint32,?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_MODIFYMESSAGE, 15049). % 修改个人留言
-define(MSG_FORMAT_GUILD_PARTY_CS_MODIFYMESSAGE, {?string}).
-define(MSG_ID_GUILD_PARTY_SC_MODIFYMESSAGE, 15050). % 修改个人留言返回
-define(MSG_FORMAT_GUILD_PARTY_SC_MODIFYMESSAGE, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_GUILDLOG,  15051). % 加载军团日志
-define(MSG_FORMAT_GUILD_PARTY_CS_GUILDLOG, {}).
-define(MSG_ID_GUILD_PARTY_SC_GUILDLOG,  15052). % 加载军团日志返回
-define(MSG_FORMAT_GUILD_PARTY_SC_GUILDLOG, {{?cycle,{?uint32,?uint8,{?cycle,{?string}}}}}).
-define(MSG_ID_GUILD_PARTY_CS_WELFEAR,   15053). % 军团福利
-define(MSG_FORMAT_GUILD_PARTY_CS_WELFEAR, {?uint32,?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_WELFEAR,   15054). % 军团福利返回
-define(MSG_FORMAT_GUILD_PARTY_SC_WELFEAR, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_BUYTRESURE, 15055). % 购买军团宝藏
-define(MSG_FORMAT_GUILD_PARTY_CS_BUYTRESURE, {?uint32,?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_BUYTRESURE, 15056). % 购买军团宝藏返回
-define(MSG_FORMAT_GUILD_PARTY_SC_BUYTRESURE, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_DEALAPPLY, 15057). % 处理军团邀请
-define(MSG_FORMAT_GUILD_PARTY_CS_DEALAPPLY, {?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_DEALAPPLY, 15058). % 处理军团邀请返回
-define(MSG_FORMAT_GUILD_PARTY_SC_DEALAPPLY, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_MODIFYANNOU, 15061). % 修改军团公告
-define(MSG_FORMAT_GUILD_PARTY_CS_MODIFYANNOU, {?uint8,?string}).
-define(MSG_ID_GUILD_PARTY_SC_MODIFYANNOU, 15062). % 修改军团公告返回
-define(MSG_FORMAT_GUILD_PARTY_SC_MODIFYANNOU, {?uint8,?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_INVITEGUILD, 15063). % 邀请入团
-define(MSG_FORMAT_GUILD_PARTY_CS_INVITEGUILD, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_INVITEGUILD, 15064). % 邀请入团返回
-define(MSG_FORMAT_GUILD_PARTY_SC_INVITEGUILD, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_INVITEED,  15066). % 邀请入军团(被邀请方)
-define(MSG_FORMAT_GUILD_PARTY_SC_INVITEED, {?uint32,?uint32,?string,?string}).
-define(MSG_ID_GUILD_PARTY_SC_INVITE,    15068). % 邀请入军团反馈(邀请方)
-define(MSG_FORMAT_GUILD_PARTY_SC_INVITE, {?string,?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_END_TIME,  15069). % 宴会倒计时到点
-define(MSG_FORMAT_GUILD_PARTY_CS_END_TIME, {}).
-define(MSG_ID_GUILD_PARTY_SC_PARTYINFO, 15070). % 军团宴会信息返回
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTYINFO, {?uint8,?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_PARTYMEM,  15072). % 军团宴会成员返回
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTYMEM, {{?cycle,{?uint32,?string,?uint8,?uint8}}}).
-define(MSG_ID_GUILD_PARTY_SC_PARTYPARTNER, 15074). % 军团宴会实时参加的人
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTYPARTNER, {?uint8,?string,?uint8}).
-define(MSG_ID_GUILD_PARTY_PLAY_FIREWORKS, 15075). % 施法烟火
-define(MSG_FORMAT_GUILD_PARTY_PLAY_FIREWORKS, {}).
-define(MSG_ID_GUILD_PARTY_CS_ENTER_PARTY, 15077). % 进入军团宴会
-define(MSG_FORMAT_GUILD_PARTY_CS_ENTER_PARTY, {}).
-define(MSG_ID_GUILD_PARTY_SC_ENTER_PARTY, 15078). % 进入宴会返回
-define(MSG_FORMAT_GUILD_PARTY_SC_ENTER_PARTY, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_LEAVE_PARTY, 15079). % 退出宴会
-define(MSG_FORMAT_GUILD_PARTY_CS_LEAVE_PARTY, {}).
-define(MSG_ID_GUILD_PARTY_SC_LEAVE_PARTY, 15080). % 退出宴会返回
-define(MSG_FORMAT_GUILD_PARTY_SC_LEAVE_PARTY, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_GUESS_INFO, 15102). % 接收猜拳玩家信息
-define(MSG_FORMAT_GUILD_PARTY_SC_GUESS_INFO, {?uint32,?uint8,?uint32,?string,?uint32,?uint32,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_INVITE_GUESS, 15103). % 邀请玩家猜拳
-define(MSG_FORMAT_GUILD_PARTY_CS_INVITE_GUESS, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_INVITE_GUESS, 15104). % 返回被邀请猜拳玩家
-define(MSG_FORMAT_GUILD_PARTY_SC_INVITE_GUESS, {?uint32,?string}).
-define(MSG_ID_GUILD_PARTY_CS_AGREE_REFUSE, 15105). % 同意或者拒绝被邀请玩家
-define(MSG_FORMAT_GUILD_PARTY_CS_AGREE_REFUSE, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_OUT_GUESS, 15107). % 玩家出猜拳
-define(MSG_FORMAT_GUILD_PARTY_CS_OUT_GUESS, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_OUT_GUESS, 15108). % 玩家出猜拳返回
-define(MSG_FORMAT_GUILD_PARTY_SC_OUT_GUESS, {?uint32,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_OUT_RES,   15109). % 玩家出猜拳结果
-define(MSG_FORMAT_GUILD_PARTY_SC_OUT_RES, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_RES_GUESS, 15110). % 猜拳结果返回
-define(MSG_FORMAT_GUILD_PARTY_SC_RES_GUESS, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_EXIT_GUESS, 15111). % 退出猜拳
-define(MSG_FORMAT_GUILD_PARTY_CS_EXIT_GUESS, {}).
-define(MSG_ID_GUILD_PARTY_SC_EXIT_GUESS, 15112). % 退出猜拳返回
-define(MSG_FORMAT_GUILD_PARTY_SC_EXIT_GUESS, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_ROCK_DATA, 15120). % 接收摇色子玩家信息
-define(MSG_FORMAT_GUILD_PARTY_SC_ROCK_DATA, {?uint32,?uint8,?uint32,?string,?uint8,?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_INVITE_ROCK, 15121). % 邀请玩家摇色子
-define(MSG_FORMAT_GUILD_PARTY_CS_INVITE_ROCK, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_INVITE_ROCK, 15122). % 返回被邀请摇色子玩家
-define(MSG_FORMAT_GUILD_PARTY_SC_INVITE_ROCK, {?uint32,?string}).
-define(MSG_ID_GUILD_PARTY_CS_ROCK_AGREE, 15123). % 邀请摇色子处理
-define(MSG_FORMAT_GUILD_PARTY_CS_ROCK_AGREE, {?uint8,?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_ROCK_START, 15124). % 通知开始摇色子
-define(MSG_FORMAT_GUILD_PARTY_SC_ROCK_START, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_ROCK,      15125). % 玩家请求摇色子
-define(MSG_FORMAT_GUILD_PARTY_CS_ROCK,  {}).
-define(MSG_ID_GUILD_PARTY_SC_ROCK,      15126). % 玩家摇色子结果返回
-define(MSG_FORMAT_GUILD_PARTY_SC_ROCK,  {?uint32,?uint8,?uint8,?uint8}).
-define(MSG_ID_GUILD_PARTY_ROCK_RESULT,  15127). % 当前局摇骰子结果返回
-define(MSG_FORMAT_GUILD_PARTY_ROCK_RESULT, {?uint8,?uint8,?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_ROCK_RES,  15128). % 摇色子结果返回
-define(MSG_FORMAT_GUILD_PARTY_SC_ROCK_RES, {?uint8,?uint32,?uint32,?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_EXIT_ROCK, 15129). % 退出摇色子
-define(MSG_FORMAT_GUILD_PARTY_CS_EXIT_ROCK, {}).
-define(MSG_ID_GUILD_PARTY_SC_EXIT_ROCK, 15130). % 退出摇色子返回
-define(MSG_FORMAT_GUILD_PARTY_SC_EXIT_ROCK, {?uint32}).
-define(MSG_ID_GUILD_PARTY_CS_DESK_TIMES, 15131). % 请求宴会桌子次数
-define(MSG_FORMAT_GUILD_PARTY_CS_DESK_TIMES, {}).
-define(MSG_ID_GUILD_PARTY_SC_DESK_TIMES, 15132). % 返回宴会桌子次数
-define(MSG_FORMAT_GUILD_PARTY_SC_DESK_TIMES, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_GET_DESKREWARD, 15133). % 领取宴会桌子的奖励
-define(MSG_FORMAT_GUILD_PARTY_CS_GET_DESKREWARD, {}).
-define(MSG_ID_GUILD_PARTY_SC_GET_DESKREWARD, 15134). % 领取宴会桌子的奖励成功
-define(MSG_FORMAT_GUILD_PARTY_SC_GET_DESKREWARD, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_RESET_TIMES, 15135). % 重置宴会桌子次数
-define(MSG_FORMAT_GUILD_PARTY_CS_RESET_TIMES, {}).
-define(MSG_ID_GUILD_PARTY_SC_RESET_TIMES, 15136). % 重置宴会桌子次数返回
-define(MSG_FORMAT_GUILD_PARTY_SC_RESET_TIMES, {?uint8}).
-define(MSG_ID_GUILD_PARTY_MEAT,         15138). % 获取宴会桌子是否有肉
-define(MSG_FORMAT_GUILD_PARTY_MEAT,     {?uint8}).
-define(MSG_ID_GUILD_PARTY_PARTY_NORMAL_STATE, 15141). % 宴会请求变回正常状态
-define(MSG_FORMAT_GUILD_PARTY_PARTY_NORMAL_STATE, {}).
-define(MSG_ID_GUILD_PARTY_SC_ROCK_EXIT, 15150). % 对方退出摇色子
-define(MSG_FORMAT_GUILD_PARTY_SC_ROCK_EXIT, {?uint8}).
-define(MSG_ID_GUILD_PARTY_SC_END_REWARD, 15152). % 宴会结束奖励通知
-define(MSG_FORMAT_GUILD_PARTY_SC_END_REWARD, {?uint8,?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_EXP, 15154). % 增加经验
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_EXP, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_SP,  15156). % 增加体力
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_SP, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_GOLD, 15158). % 增加铜钱
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_GOLD, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_EXPERIENCE, 15160). % 增加历练
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_EXPERIENCE, {?uint32}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_RANK, 15162). % 排行信息
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_RANK, {{?cycle,{?uint32,?uint32,?string}}}).
-define(MSG_ID_GUILD_PARTY_SC_PARTY_QUIT_NOTICE, 15170). % 退出宴会通知
-define(MSG_FORMAT_GUILD_PARTY_SC_PARTY_QUIT_NOTICE, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_PARTY_END_QUIT, 15171). % 宴会结束请求退出
-define(MSG_FORMAT_GUILD_PARTY_CS_PARTY_END_QUIT, {}).
-define(MSG_ID_GUILD_PARTY_CTN_REQUEST,  15201). % 请求仓库信息
-define(MSG_FORMAT_GUILD_PARTY_CTN_REQUEST, {}).
-define(MSG_ID_GUILD_PARTY_CS_DISTRIBUTE, 15203). % 分配仓库物品
-define(MSG_FORMAT_GUILD_PARTY_CS_DISTRIBUTE, {?uint32,{?cycle,{?uint32,?uint16}}}).
-define(MSG_ID_GUILD_PARTY_SC_DISTRIBUTE, 15204). % 分配仓库物品成功返回
-define(MSG_FORMAT_GUILD_PARTY_SC_DISTRIBUTE, {?uint8}).
-define(MSG_ID_GUILD_PARTY_CS_GUILD_MEMINFO, 15301). % 请求军团成员信息
-define(MSG_FORMAT_GUILD_PARTY_CS_GUILD_MEMINFO, {}).
-define(MSG_ID_GUILD_PARTY_SC_GUILD_MEMINFO, 15302). % 军团成员信息返回
-define(MSG_FORMAT_GUILD_PARTY_SC_GUILD_MEMINFO, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_GUILD_PARTY_GUILD_BAG_EMPTY, 15303). % 军团背包清空
-define(MSG_FORMAT_GUILD_PARTY_GUILD_BAG_EMPTY, {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% guild  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUILD,               16000). % 军团
-define(MODULE_PACKET_GUILD,             guild_packet). 
-define(MODULE_HANDLER_GUILD,            guild_handler). 

-define(MSG_ID_GUILD_CS_LIST,            15501). % 请求军团列表
-define(MSG_FORMAT_GUILD_CS_LIST,        {}).
-define(MSG_ID_GUILD_SC_LIST,            15502). % 返回军团列表
-define(MSG_FORMAT_GUILD_SC_LIST,        {{?cycle,{?uint32,?string,?string,?uint8,?uint8,?uint8,?string,?uint8,?uint8}}}).
-define(MSG_ID_GUILD_CS_DATA,            15503). % 请求军团详情信息
-define(MSG_FORMAT_GUILD_CS_DATA,        {}).
-define(MSG_ID_GUILD_SC_DATA,            15504). % 请求军团详情信息返回
-define(MSG_FORMAT_GUILD_SC_DATA,        {?string,?uint8,?uint8,?uint8,?string,?uint32,?string,?string,?string,?uint32,?uint32,?uint16}).
-define(MSG_ID_GUILD_CS_MEMBER,          15505). % 加载成员列表请求
-define(MSG_FORMAT_GUILD_CS_MEMBER,      {}).
-define(MSG_ID_GUILD_SC_MEMBER,          15506). % 加载成员列表返回
-define(MSG_FORMAT_GUILD_SC_MEMBER,      {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_CS_APPLY_LIST,      15507). % 军团申请列表请求
-define(MSG_FORMAT_GUILD_CS_APPLY_LIST,  {}).
-define(MSG_ID_GUILD_SC_APPLY_LIST,      15508). % 军团申请列表返回
-define(MSG_FORMAT_GUILD_SC_APPLY_LIST,  {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8,?uint32}}}).
-define(MSG_ID_GUILD_CS_CREATE,          15511). % 创建军团请求
-define(MSG_FORMAT_GUILD_CS_CREATE,      {?string,?bool}).
-define(MSG_ID_GUILD_SC_CREATE,          15512). % 创建军团返回
-define(MSG_FORMAT_GUILD_SC_CREATE,      {?uint32}).
-define(MSG_ID_GUILD_DISBAND,            15513). % 解散军团请求
-define(MSG_FORMAT_GUILD_DISBAND,        {}).
-define(MSG_ID_GUILD_QUIT,               15515). % 退出军团请求
-define(MSG_FORMAT_GUILD_QUIT,           {}).
-define(MSG_ID_GUILD_CS_CD,              15517). % 请求cd时间
-define(MSG_FORMAT_GUILD_CS_CD,          {}).
-define(MSG_ID_GUILD_CS_CLEAN_CD,        15519). % 清除cd时间
-define(MSG_FORMAT_GUILD_CS_CLEAN_CD,    {}).
-define(MSG_ID_GUILD_SC_CD,              15520). % 是否cd时间内
-define(MSG_FORMAT_GUILD_SC_CD,          {?uint8}).
-define(MSG_ID_GUILD_CS_APPLY,           15521). % 加入军团申请
-define(MSG_FORMAT_GUILD_CS_APPLY,       {?uint32}).
-define(MSG_ID_GUILD_CS_CANCEL_APPLY,    15523). % 取消申请加入军团
-define(MSG_FORMAT_GUILD_CS_CANCEL_APPLY, {?uint32}).
-define(MSG_ID_GUILD_SC_APPLY,           15524). % 军团申请返回
-define(MSG_FORMAT_GUILD_SC_APPLY,       {?uint32,?uint8}).
-define(MSG_ID_GUILD_CS_DEAL_APPLY,      15525). % 申请请求处理
-define(MSG_FORMAT_GUILD_CS_DEAL_APPLY,  {?uint8,?uint32}).
-define(MSG_ID_GUILD_CS_INVITE,          15527). % 邀请入团
-define(MSG_FORMAT_GUILD_CS_INVITE,      {?uint32}).
-define(MSG_ID_GUILD_SC_INVITE,          15528). % 邀请入团返回
-define(MSG_FORMAT_GUILD_SC_INVITE,      {?uint32,?string,?uint32,?string}).
-define(MSG_ID_GUILD_CS_DEAL_INVITE,     15529). % 处理军团邀请
-define(MSG_FORMAT_GUILD_CS_DEAL_INVITE, {?uint32,?uint8}).
-define(MSG_ID_GUILD_CS_DONATE,          15531). % 捐献申请
-define(MSG_FORMAT_GUILD_CS_DONATE,      {?uint8,?uint32}).
-define(MSG_ID_GUILD_CS_SKILL_DONATE,    15533). % 技能捐献申请
-define(MSG_FORMAT_GUILD_CS_SKILL_DONATE, {?uint16,?uint8,?uint32}).
-define(MSG_ID_GUILD_CS_SKILL_LIST,      15541). % 军团技能列表请求
-define(MSG_FORMAT_GUILD_CS_SKILL_LIST,  {}).
-define(MSG_ID_GUILD_SC_SKILL_LIST,      15542). % 军团技能列表返回
-define(MSG_FORMAT_GUILD_SC_SKILL_LIST,  {{?cycle,{?uint16,?uint8,?uint32}}}).
-define(MSG_ID_GUILD_CS_SKILL_LEARN,     15543). % 学习军团技能申请
-define(MSG_FORMAT_GUILD_CS_SKILL_LEARN, {?uint16}).
-define(MSG_ID_GUILD_SC_SKILL_LEARN,     15544). % 学习军团技能返回
-define(MSG_FORMAT_GUILD_SC_SKILL_LEARN, {?uint16}).
-define(MSG_ID_GUILD_CS_MAGIC_LEARN,     15551). % 学习军团术法申请
-define(MSG_FORMAT_GUILD_CS_MAGIC_LEARN, {?uint16}).
-define(MSG_ID_GUILD_SC_MAGIC_LEARN,     15552). % 学习军团术法返回
-define(MSG_FORMAT_GUILD_SC_MAGIC_LEARN, {?uint16}).
-define(MSG_ID_GUILD_CS_MAGIC_LIST,      15553). % 术法列表请求
-define(MSG_FORMAT_GUILD_CS_MAGIC_LIST,  {}).
-define(MSG_ID_GUILD_SC_MAGIC_LIST,      15554). % 术法列表返回
-define(MSG_FORMAT_GUILD_SC_MAGIC_LIST,  {{?cycle,{?uint16,?uint8}}}).
-define(MSG_ID_GUILD_CS_TREASURE,        15561). % 请求军团宝藏信息
-define(MSG_FORMAT_GUILD_CS_TREASURE,    {}).
-define(MSG_ID_GUILD_SC_TREASURE,        15562). % 军团宝藏信息返回
-define(MSG_FORMAT_GUILD_SC_TREASURE,    {?uint8}).
-define(MSG_ID_GUILD_CS_BUY_TREASURE,    15563). % 购买军团宝藏
-define(MSG_FORMAT_GUILD_CS_BUY_TREASURE, {?uint16,?uint32,?uint8}).
-define(MSG_ID_GUILD_CS_KICK_OUT,        15571). % 踢出成员
-define(MSG_FORMAT_GUILD_CS_KICK_OUT,    {?uint32}).
-define(MSG_ID_GUILD_CS_CHIEF,           15573). % 提升至军团长
-define(MSG_FORMAT_GUILD_CS_CHIEF,       {?uint32,?uint8}).
-define(MSG_ID_GUILD_CS_REMOVE_POS,      15575). % 移除职位
-define(MSG_FORMAT_GUILD_CS_REMOVE_POS,  {?uint32}).
-define(MSG_ID_GUILD_CS_IMPEACH_CHIEF,   15577). % 弹劾军团长
-define(MSG_FORMAT_GUILD_CS_IMPEACH_CHIEF, {}).
-define(MSG_ID_GUILD_CS_PROMOTE_POS,     15579). % 自动提升职位
-define(MSG_FORMAT_GUILD_CS_PROMOTE_POS, {}).
-define(MSG_ID_GUILD_CS_INTRODUCE,       15581). % 修改个人留言
-define(MSG_FORMAT_GUILD_CS_INTRODUCE,   {?string}).
-define(MSG_ID_GUILD_CS_ANNOUNCE,        15583). % 修改军团公告
-define(MSG_FORMAT_GUILD_CS_ANNOUNCE,    {?uint8,?string}).
-define(MSG_ID_GUILD_SC_ANNOUNCE,        15584). % 修改军团公告返回
-define(MSG_FORMAT_GUILD_SC_ANNOUNCE,    {?uint8,?string,?uint32}).
-define(MSG_ID_GUILD_CS_LOG,             15591). % 加载军团日志
-define(MSG_FORMAT_GUILD_CS_LOG,         {}).
-define(MSG_ID_GUILD_SC_LOG,             15592). % 军团日志返回
-define(MSG_FORMAT_GUILD_SC_LOG,         {{?cycle,{?uint32,?uint8,{?cycle,{?uint8,?string,?uint32}}}}}).
-define(MSG_ID_GUILD_CTN_REQUEST,        15601). % 请求仓库信息
-define(MSG_FORMAT_GUILD_CTN_REQUEST,    {}).
-define(MSG_ID_GUILD_DISTRIBUTE,         15603). % 分配仓库物品
-define(MSG_FORMAT_GUILD_DISTRIBUTE,     {?uint32,{?cycle,{?uint32,?uint16}}}).
-define(MSG_ID_GUILD_SC_DISTRIBUTE,      15604). % 分配仓库物品成功返回
-define(MSG_FORMAT_GUILD_SC_DISTRIBUTE,  {?uint8}).
-define(MSG_ID_GUILD_MEMBER_INFO,        15701). % 请求军团成员信息
-define(MSG_FORMAT_GUILD_MEMBER_INFO,    {}).
-define(MSG_ID_GUILD_SC_MEMBER_INFO,     15702). % 军团成员信息返回
-define(MSG_FORMAT_GUILD_SC_MEMBER_INFO, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_GUILD_CS_MEMBER_NAME,     15703). % 成员名字信息
-define(MSG_FORMAT_GUILD_CS_MEMBER_NAME, {}).
-define(MSG_ID_GUILD_SC_MEMBER_NAME,     15704). % 成员名字信息
-define(MSG_FORMAT_GUILD_SC_MEMBER_NAME, {{?cycle,{?string}}}).
-define(MSG_ID_GUILD_SC_ON_OFF,          15706). % 成员上下线
-define(MSG_FORMAT_GUILD_SC_ON_OFF,      {?uint32,?uint32,?string}).
-define(MSG_ID_GUILD_CS_CD_LEAVE_TIME,   15801). % 请求CD剩余时间
-define(MSG_FORMAT_GUILD_CS_CD_LEAVE_TIME, {}).
-define(MSG_ID_GUILD_SC_CD_LEAVE_TIME,   15802). % CD剩余时间
-define(MSG_FORMAT_GUILD_SC_CD_LEAVE_TIME, {?uint32}).
-define(MSG_ID_GUILD_CS_MEM_DETAIL,      15803). % 成员详情信息
-define(MSG_FORMAT_GUILD_CS_MEM_DETAIL,  {?uint32}).
-define(MSG_ID_GUILD_SC_MEM_DETAIL,      15804). % 成员详情信息返回
-define(MSG_FORMAT_GUILD_SC_MEM_DETAIL,  {?uint32,?string,?uint8,?uint8,?uint32,{?cycle,{?uint32}}}).
-define(MSG_ID_GUILD_CS_SUP_APPLY,       15805). % 快速邀请
-define(MSG_FORMAT_GUILD_CS_SUP_APPLY,   {}).
-define(MSG_ID_GUILD_SC_SUP_APPLY,       15806). % 快速邀请返回
-define(MSG_FORMAT_GUILD_SC_SUP_APPLY,   {?uint8,?uint32}).
-define(MSG_ID_GUILD_SUP_APPLY_ADD,      15807). % 快速申请
-define(MSG_FORMAT_GUILD_SUP_APPLY_ADD,  {?uint32}).
-define(MSG_ID_GUILD_TIMEOUT_TICK,       15809). % 设置下线超时踢人时间
-define(MSG_FORMAT_GUILD_TIMEOUT_TICK,   {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% practice  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PRACTICE,            17000). % 修炼
-define(MODULE_PACKET_PRACTICE,          practice_packet). 
-define(MODULE_HANDLER_PRACTICE,         practice_handler). 

-define(MSG_ID_PRACTICE_SINGLE_REQUEST,  16001). % 修炼请求
-define(MSG_FORMAT_PRACTICE_SINGLE_REQUEST, {}).
-define(MSG_ID_PRACTICE_SINGLE,          16002). % 单修成功
-define(MSG_FORMAT_PRACTICE_SINGLE,      {?uint8,?uint32}).
-define(MSG_ID_PRACTICE_DOUBLE_REQUEST,  16003). % 双修请求
-define(MSG_FORMAT_PRACTICE_DOUBLE_REQUEST, {?uint32}).
-define(MSG_ID_PRACTICE_DOUBLE_RECEIVE,  16004). % 双修邀请
-define(MSG_FORMAT_PRACTICE_DOUBLE_RECEIVE, {?uint32,?string}).
-define(MSG_ID_PRACTICE_DOUBLE_REPLY,    16005). % 双修邀请回复
-define(MSG_FORMAT_PRACTICE_DOUBLE_REPLY, {?uint8,?uint32}).
-define(MSG_ID_PRACTICE_DOUBLE,          16006). % 双修成功
-define(MSG_FORMAT_PRACTICE_DOUBLE,      {?uint32,?uint8,?uint32}).
-define(MSG_ID_PRACTICE_REWARD,          16008). % 修炼奖励
-define(MSG_FORMAT_PRACTICE_REWARD,      {?uint8,?uint32}).
-define(MSG_ID_PRACTICE_CANCEL,          16010). % 取消修炼
-define(MSG_FORMAT_PRACTICE_CANCEL,      {}).
-define(MSG_ID_PRACTICE_CANCEL_DATA,     16011). % 取消修炼通知对方
-define(MSG_FORMAT_PRACTICE_CANCEL_DATA, {?uint8}).
-define(MSG_ID_PRACTICE_VIP_OPTIONS,     16101). % vip双修设定
-define(MSG_FORMAT_PRACTICE_VIP_OPTIONS, {?uint8}).
-define(MSG_ID_PRACTICE_OPTIONS,         16103). % 双修设定
-define(MSG_FORMAT_PRACTICE_OPTIONS,     {}).
-define(MSG_ID_PRACTICE_OPTIONS_DATA,    16104). % 双修设定
-define(MSG_FORMAT_PRACTICE_OPTIONS_DATA, {?uint8}).
-define(MSG_ID_PRACTICE_CS_LEAVE_EXP,    16105). % 请求离线经验
-define(MSG_FORMAT_PRACTICE_CS_LEAVE_EXP, {}).
-define(MSG_ID_PRACTICE_SC_LEAVE_EXP,    16106). % 请求离线经验
-define(MSG_FORMAT_PRACTICE_SC_LEAVE_EXP, {?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_PRACTICE_CS_DOUBLE_STATE, 16107). % 请求转成双修状态
-define(MSG_FORMAT_PRACTICE_CS_DOUBLE_STATE, {}).
-define(MSG_ID_PRACTICE_CS_OFFLINE_SET,  16108). % 离线修炼设置
-define(MSG_FORMAT_PRACTICE_CS_OFFLINE_SET, {?uint8,?uint32}).
-define(MSG_ID_PRACTICE_SC_OFFLINE_SET_RES, 16109). % 离线修炼设置结果
-define(MSG_FORMAT_PRACTICE_SC_OFFLINE_SET_RES, {?uint8}).
-define(MSG_ID_PRACTICE_CS_QUERY_OFFLINE_SET, 16110). % 查询离线修炼设置
-define(MSG_FORMAT_PRACTICE_CS_QUERY_OFFLINE_SET, {}).
-define(MSG_ID_PRACTICE_SC_OFFLINE_SET_REP, 16111). % 查询离线修炼设置结果
-define(MSG_FORMAT_PRACTICE_SC_OFFLINE_SET_REP, {?uint8}).
-define(MSG_ID_PRACTICE_CS_CANCEL_OFFLINE_SET, 16112). % 取消离线修炼设置
-define(MSG_FORMAT_PRACTICE_CS_CANCEL_OFFLINE_SET, {}).
-define(MSG_ID_PRACTICE_CS_GET_VALID_TIME, 16113). % 获取可修炼时间
-define(MSG_FORMAT_PRACTICE_CS_GET_VALID_TIME, {?uint8}).
-define(MSG_ID_PRACTICE_SC_VALID_TIME,   16114). % 回复可修炼时间
-define(MSG_FORMAT_PRACTICE_SC_VALID_TIME, {?uint8,?uint32}).
-define(MSG_ID_PRACTICE_SC_OFFLINE_CLEAN, 16115). % 清除离线设置
-define(MSG_FORMAT_PRACTICE_SC_OFFLINE_CLEAN, {}).
-define(MSG_ID_PRACTICE_CS_CLEAR_CD,     16201). % 清除CD
-define(MSG_FORMAT_PRACTICE_CS_CLEAR_CD, {?uint8}).
-define(MSG_ID_PRACTICE_SC_TIME,         16202). % 剩余修炼时间
-define(MSG_FORMAT_PRACTICE_SC_TIME,     {?uint32}).
-define(MSG_ID_PRACTICE_SC_FINISH_TIME,  16300). % 修炼时长
-define(MSG_FORMAT_PRACTICE_SC_FINISH_TIME, {?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% market  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MARKET,              18000). % 拍卖
-define(MODULE_PACKET_MARKET,            market_packet). 
-define(MODULE_HANDLER_MARKET,           market_handler). 

-define(MSG_ID_MARKET_CS_MARKET_SEARCH,  17001). % 交易查询
-define(MSG_FORMAT_MARKET_CS_MARKET_SEARCH, {?uint8,?string,?uint8,?uint16,?uint16,?uint16,?uint16,?uint16,?uint16,?uint8,?uint8}).
-define(MSG_ID_MARKET_SC_SEARCH_INFO,    17002). % 交易查询返回
-define(MSG_FORMAT_MARKET_SC_SEARCH_INFO, {?uint16,{?cycle,{?uint32,?string,?string,?uint32,?uint32,?uint32,?uint16,?uint16,?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}},?uint8}).
-define(MSG_ID_MARKET_CS_SEAL_GOODS,     17003). % 寄售物品
-define(MSG_FORMAT_MARKET_CS_SEAL_GOODS, {?uint32,?uint16,?uint8,?uint32,?uint32}).
-define(MSG_ID_MARKET_SC_SEAL_RESULT,    17004). % 寄售物品状态
-define(MSG_FORMAT_MARKET_SC_SEAL_RESULT, {?uint8}).
-define(MSG_ID_MARKET_CS_BUY_GOODS,      17005). % 竞拍物品
-define(MSG_FORMAT_MARKET_CS_BUY_GOODS,  {?uint8,?uint32,?uint32}).
-define(MSG_ID_MARKET_SC_BUY_RESULT,     17006). % 竞拍状态
-define(MSG_FORMAT_MARKET_SC_BUY_RESULT, {?uint8}).
-define(MSG_ID_MARKET_CS_FETCH_GOODS,    17007). % 取回过期物品
-define(MSG_FORMAT_MARKET_CS_FETCH_GOODS, {?uint8,?uint32,?uint32}).
-define(MSG_ID_MARKET_SC_FETCH_RESULT,   17008). % 取回物品状态
-define(MSG_FORMAT_MARKET_SC_FETCH_RESULT, {?uint8}).
-define(MSG_ID_MARKET_CS_SEAL_INFO,      17009). % 查看寄售物品
-define(MSG_FORMAT_MARKET_CS_SEAL_INFO,  {}).
-define(MSG_ID_MARKET_SC_SEAL_INFO,      17010). % 查看寄售物品返回
-define(MSG_FORMAT_MARKET_SC_SEAL_INFO,  {?uint32,?string,?string,?uint32,?uint32,?uint32,?uint16,?uint16,?uint16,?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?bool,?uint32,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}).
-define(MSG_ID_MARKET_CS_HOT_SEARCH,     17011). % 查看热门搜索物品
-define(MSG_FORMAT_MARKET_CS_HOT_SEARCH, {}).
-define(MSG_ID_MARKET_SC_HOT_SEARCH,     17012). % 查看热门搜索物品返回
-define(MSG_FORMAT_MARKET_SC_HOT_SEARCH, {{?cycle,{?string}}}).
-define(MSG_ID_MARKET_CS_SEARCH_HOT_GOODS, 17013). % 热门搜索物品
-define(MSG_FORMAT_MARKET_CS_SEARCH_HOT_GOODS, {?string,?uint8}).
-define(MSG_ID_MARKET_SC_BUY_SUCCESS,    17104). % 拍卖成功提示
-define(MSG_FORMAT_MARKET_SC_BUY_SUCCESS, {?string,?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% mall  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MALL,                18100). % 商城
-define(MODULE_PACKET_MALL,              mall_packet). 
-define(MODULE_HANDLER_MALL,             mall_handler). 

-define(MSG_ID_MALL_DATA_REQUEST,        18001). % 商城数据请求
-define(MSG_FORMAT_MALL_DATA_REQUEST,    {}).
-define(MSG_ID_MALL_DATA_RECV,           18002). % 限时抢购数据返回
-define(MSG_FORMAT_MALL_DATA_RECV,       {?uint32,{?cycle,{?uint32,?uint16}}}).
-define(MSG_ID_MALL_BUY,                 18003). % 请求购买
-define(MSG_FORMAT_MALL_BUY,             {?uint8,?uint32,?uint16,?uint8}).
-define(MSG_ID_MALL_CS_BUY_SALE,         18005). % 请求购买折扣物品
-define(MSG_FORMAT_MALL_CS_BUY_SALE,     {?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_MALL_CS_RIDE_UP,          18007). % 请求坐骑升级
-define(MSG_FORMAT_MALL_CS_RIDE_UP,      {?uint8,?uint8,?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% team2  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_TEAM2,               19000). % 多人组队
-define(MODULE_PACKET_TEAM2,             team2_packet). 
-define(MODULE_HANDLER_TEAM2,            team2_handler). 

-define(MSG_ID_TEAM2_CS_CREAT,           18105). % 请求创建队伍
-define(MSG_FORMAT_TEAM2_CS_CREAT,       {?uint32}).
-define(MSG_ID_TEAM2_CS_JOIN,            18107). % 请求加入队伍
-define(MSG_FORMAT_TEAM2_CS_JOIN,        {?uint16,?string}).
-define(MSG_ID_TEAM2_CS_REMOVE,          18109). % 请求移除队伍成员
-define(MSG_FORMAT_TEAM2_CS_REMOVE,      {?uint32}).
-define(MSG_ID_TEAM2_CS_QUIT,            18111). % 请求退出队伍
-define(MSG_FORMAT_TEAM2_CS_QUIT,        {}).
-define(MSG_ID_TEAM2_CS_CHANGE_LEADER,   18113). % 请求更换队长
-define(MSG_FORMAT_TEAM2_CS_CHANGE_LEADER, {?uint32}).
-define(MSG_ID_TEAM2_CS_INVITE,          18115). % 请求邀请角色
-define(MSG_FORMAT_TEAM2_CS_INVITE,      {?uint32}).
-define(MSG_ID_TEAM2_CS_REPLY,           18117). % 回复组队邀请
-define(MSG_FORMAT_TEAM2_CS_REPLY,       {?uint8,?uint32,?uint8}).
-define(MSG_ID_TEAM2_CS_SET_MEMBER_STATE, 18119). % 请求队伍成员状态
-define(MSG_FORMAT_TEAM2_CS_SET_MEMBER_STATE, {?uint8}).
-define(MSG_ID_TEAM2_CS_SET_CAMP,        18201). % 设置阵型
-define(MSG_FORMAT_TEAM2_CS_SET_CAMP,    {?uint16}).
-define(MSG_ID_TEAM2_CS_SET_CAMP_POS,    18203). % 设置阵型站位
-define(MSG_FORMAT_TEAM2_CS_SET_CAMP_POS, {?uint8,?uint8}).
-define(MSG_ID_TEAM2_CS_AUTOJOIN,        18205). % 自动加入
-define(MSG_FORMAT_TEAM2_CS_AUTOJOIN,    {?uint16}).
-define(MSG_ID_TEAM2_CS_QUIT_HALL,       18207). % 请求退出大厅
-define(MSG_FORMAT_TEAM2_CS_QUIT_HALL,   {}).
-define(MSG_ID_TEAM2_CS_QUICK_JOIN,      18209). % 快速加入
-define(MSG_FORMAT_TEAM2_CS_QUICK_JOIN,  {?uint8,?uint16,?uint16,?string}).
-define(MSG_ID_TEAM2_CS_LOCK_UNLOCK,     18211). % 队伍加锁解锁
-define(MSG_FORMAT_TEAM2_CS_LOCK_UNLOCK, {?string}).
-define(MSG_ID_TEAM2_CS_CHANGE_COPY2,    18212). % 切换战场
-define(MSG_FORMAT_TEAM2_CS_CHANGE_COPY2, {?uint32}).
-define(MSG_ID_TEAM2_AUTHOR_LIST,        18213). % 请求授权列表
-define(MSG_FORMAT_TEAM2_AUTHOR_LIST,    {?uint8}).
-define(MSG_ID_TEAM2_CS_INVITE_AUTHOR,   18214). % 请求可邀请的替身列表
-define(MSG_FORMAT_TEAM2_CS_INVITE_AUTHOR, {?uint8}).
-define(MSG_ID_TEAM2_CS_SET_AUTHOR_LIST, 18215). % 设置授权列表
-define(MSG_FORMAT_TEAM2_CS_SET_AUTHOR_LIST, {?uint32,?bool,?uint8}).
-define(MSG_ID_TEAM2_INVITE_AUTHOR,      18216). % 邀请替身
-define(MSG_FORMAT_TEAM2_INVITE_AUTHOR,  {?uint32}).
-define(MSG_ID_TEAM2_GOLD_HIRE,          18217). % 请求元宝雇佣信
-define(MSG_FORMAT_TEAM2_GOLD_HIRE,      {}).
-define(MSG_ID_TEAM2_GOLD_HIRE_INVITE,   18218). % 元宝雇佣
-define(MSG_FORMAT_TEAM2_GOLD_HIRE_INVITE, {?uint32}).
-define(MSG_ID_TEAM2_CS_QUICK_JOIN_CROSS, 18301). % 快速跨服加入
-define(MSG_FORMAT_TEAM2_CS_QUICK_JOIN_CROSS, {?uint8,?uint32,?uint16,?uint32,?string}).
-define(MSG_ID_TEAM2_SC_ENTER_HALL,      18400). % 进入组队大厅
-define(MSG_FORMAT_TEAM2_SC_ENTER_HALL,  {}).
-define(MSG_ID_TEAM2_SC_ENTER_HALL_NOTICE, 18500). % 角色进入大厅通知
-define(MSG_FORMAT_TEAM2_SC_ENTER_HALL_NOTICE, {?uint32,?string,?uint8,?uint8,?uint8}).
-define(MSG_ID_TEAM2_SC_QUIT_HALL_NOTICE, 18502). % 角色退出大厅通知
-define(MSG_FORMAT_TEAM2_SC_QUIT_HALL_NOTICE, {?uint32}).
-define(MSG_ID_TEAM2_SC_TEAM_INSERT_NOTICE, 18510). % 插入队伍信息
-define(MSG_FORMAT_TEAM2_SC_TEAM_INSERT_NOTICE, {?uint16,?uint8,?uint8,?string,?uint8,?uint8,?uint8,?uint8,?uint16,?string}).
-define(MSG_ID_TEAM2_SC_TEAM_DELETE_NOTICE, 18512). % 删除队伍通知
-define(MSG_FORMAT_TEAM2_SC_TEAM_DELETE_NOTICE, {?uint16}).
-define(MSG_ID_TEAM2_SC_INVITE_NOTICE,   18520). % 邀请组队通知
-define(MSG_FORMAT_TEAM2_SC_INVITE_NOTICE, {?uint8,?uint32,?uint16,?string,?uint8,?uint32,?uint8}).
-define(MSG_ID_TEAM2_SC_REMOVE_INVITE,   18524). % 移除邀请组队通知
-define(MSG_FORMAT_TEAM2_SC_REMOVE_INVITE, {?uint32}).
-define(MSG_ID_TEAM2_SC_QUIT_NOTICE,     18526). % 退出队伍通知
-define(MSG_FORMAT_TEAM2_SC_QUIT_NOTICE, {?uint8}).
-define(MSG_ID_TEAM2_SC_INFO,            18530). % 队伍详细信息
-define(MSG_FORMAT_TEAM2_SC_INFO,        {?uint16,?uint8,?uint16,?uint8,?uint32,?uint16,?string,{?cycle,{?uint32,?uint8,?uint8,?string,?uint8,?uint8,?uint8,?uint16,?uint32,?uint32,?uint32,?uint32,?uint8,?uint16,{?cycle,{?uint16}}}}}).
-define(MSG_ID_TEAM2_SC_QUIT_PLAY_TO,    18540). % 退出玩法到去向通知
-define(MSG_FORMAT_TEAM2_SC_QUIT_PLAY_TO, {?uint8,?uint8}).
-define(MSG_ID_TEAM2_SC_CHANGE_COPY2,    18541). % 切换战场返回
-define(MSG_FORMAT_TEAM2_SC_CHANGE_COPY2, {?uint8,?bool}).
-define(MSG_ID_TEAM2_SC_AUTHOR_LIST,     18542). % 授权别表返回
-define(MSG_FORMAT_TEAM2_SC_AUTHOR_LIST, {{?cycle,{?uint32}},?uint32,?bool,?uint8}).
-define(MSG_ID_TEAM2_SC_INVITE_AUTHOR_LIST, 18543). % 返回可邀请的替身
-define(MSG_FORMAT_TEAM2_SC_INVITE_AUTHOR_LIST, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint32}},?uint8}).
-define(MSG_ID_TEAM2_SC_GOLD_HIRE,       18544). % 请求元宝雇佣信息返回
-define(MSG_FORMAT_TEAM2_SC_GOLD_HIRE,   {{?cycle,{?uint32,?string,?uint32,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% group  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GROUP,               20000). % 常规组队
-define(MODULE_PACKET_GROUP,             group_packet). 
-define(MODULE_HANDLER_GROUP,            group_handler). 

-define(MSG_ID_GROUP_CS_LIST_GROUP,      19001). % 查询团队信息
-define(MSG_FORMAT_GROUP_CS_LIST_GROUP,  {?uint32}).
-define(MSG_ID_GROUP_SC_LIST_GROUP,      19002). % [回复]团队信息
-define(MSG_FORMAT_GROUP_SC_LIST_GROUP,  {?uint32,?string,?uint8,?uint8,?string,?uint8,?uint8,?uint8,?uint32,?uint32,?uint16}).
-define(MSG_ID_GROUP_CS_CREATE,          19003). % 创建团队
-define(MSG_FORMAT_GROUP_CS_CREATE,      {?uint8}).
-define(MSG_ID_GROUP_CS_QUIT,            19005). % 离开团队
-define(MSG_FORMAT_GROUP_CS_QUIT,        {}).
-define(MSG_ID_GROUP_CS_NEW_LEADER,      19007). % 转换队长
-define(MSG_FORMAT_GROUP_CS_NEW_LEADER,  {?uint32}).
-define(MSG_ID_GROUP_CS_REQ2JOIN,        19009). % 申请加入团队
-define(MSG_FORMAT_GROUP_CS_REQ2JOIN,    {?uint32}).
-define(MSG_ID_GROUP_SC_REQ2JOIN,        19010). % [回复]申请加入团队
-define(MSG_FORMAT_GROUP_SC_REQ2JOIN,    {?string,?uint8,?uint32,?uint32}).
-define(MSG_ID_GROUP_CS_RSP2JOIN,        19011). % 回复申请加入团队
-define(MSG_FORMAT_GROUP_CS_RSP2JOIN,    {?uint8,?uint32}).
-define(MSG_ID_GROUP_CS_KICKOUT,         19013). % 踢出团队
-define(MSG_FORMAT_GROUP_CS_KICKOUT,     {?uint32}).
-define(MSG_ID_GROUP_SC_KICKOUT,         19014). % [回复]踢出队伍
-define(MSG_FORMAT_GROUP_SC_KICKOUT,     {?uint32}).
-define(MSG_ID_GROUP_CS_CANCEL2JOIN,     19015). % 取消申请加入
-define(MSG_FORMAT_GROUP_CS_CANCEL2JOIN, {?uint32}).
-define(MSG_ID_GROUP_SC_CANCEL2JOIN,     19016). % 取消申请加入返回
-define(MSG_FORMAT_GROUP_SC_CANCEL2JOIN, {?uint32}).
-define(MSG_ID_GROUP_CS_AUTOJOIN,        19017). % 自动加入
-define(MSG_FORMAT_GROUP_CS_AUTOJOIN,    {}).
-define(MSG_ID_GROUP_CS_REQ2WAITING,     19019). % 申请成为待组玩家
-define(MSG_FORMAT_GROUP_CS_REQ2WAITING, {}).
-define(MSG_ID_GROUP_CS_CANCEL2WAIT,     19021). % 待组玩家状态取消
-define(MSG_FORMAT_GROUP_CS_CANCEL2WAIT, {}).
-define(MSG_ID_GROUP_DELETE_WAITER,      19022). % 删除加入队伍的待组玩家
-define(MSG_FORMAT_GROUP_DELETE_WAITER,  {?uint32}).
-define(MSG_ID_GROUP_CS_INVITE,          19023). % 邀请玩家
-define(MSG_FORMAT_GROUP_CS_INVITE,      {?uint8,?uint32}).
-define(MSG_ID_GROUP_SC_INVITE,          19024). % [回复]邀请玩家
-define(MSG_FORMAT_GROUP_SC_INVITE,      {?string,?uint32}).
-define(MSG_ID_GROUP_CS_RSP2INVITE,      19025). % 邀请玩家回复
-define(MSG_FORMAT_GROUP_CS_RSP2INVITE,  {?uint32,?uint32,?uint8}).
-define(MSG_ID_GROUP_SC_LIST_WAIT,       19026). % [回复]待组玩家列表
-define(MSG_FORMAT_GROUP_SC_LIST_WAIT,   {?uint8,{?cycle,{?uint32,?string,?uint8,?string,?uint8,?uint8}}}).
-define(MSG_ID_GROUP_CS_LIST_WAIT,       19027). % 获取待组玩家列表
-define(MSG_FORMAT_GROUP_CS_LIST_WAIT,   {?uint8}).
-define(MSG_ID_GROUP_SC_UPD_ON_OFF,      19028). % 上下线通知
-define(MSG_FORMAT_GROUP_SC_UPD_ON_OFF,  {?uint32,?uint8}).
-define(MSG_ID_GROUP_CS_RECOMMEND,       19029). % 推荐队伍列表
-define(MSG_FORMAT_GROUP_CS_RECOMMEND,   {}).
-define(MSG_ID_GROUP_SC_RECOMMEND,       19030). % [回复]推荐队伍列表
-define(MSG_FORMAT_GROUP_SC_RECOMMEND,   {{?cycle,{?uint32,?string,?uint8,?string,?uint8}},{?cycle,{?uint32,?uint32,?string,?uint8,?uint8,?string,?uint8,?uint8}}}).
-define(MSG_ID_GROUP_SC_DISBAND,         19032). % 解散队伍
-define(MSG_FORMAT_GROUP_SC_DISBAND,     {?uint8}).
-define(MSG_ID_GROUP_SC_BUFFER,          19034). % buffer加成
-define(MSG_FORMAT_GROUP_SC_BUFFER,      {?uint32,{?cycle,{?uint8,?uint16}}}).
-define(MSG_ID_GROUP_CS_TEMP_BUFFER,     19035). % 请求属性加成
-define(MSG_FORMAT_GROUP_CS_TEMP_BUFFER, {?uint8,?uint32}).
-define(MSG_ID_GROUP_SC_TEMP_BUFFER,     19036). % 属性加成
-define(MSG_FORMAT_GROUP_SC_TEMP_BUFFER, {?uint8,?uint32,?string,?uint8,?uint32,?uint8}).
-define(MSG_ID_GROUP_CS_MEMBER_POWER,    19037). % 请求成员战力
-define(MSG_FORMAT_GROUP_CS_MEMBER_POWER, {?uint32}).
-define(MSG_ID_GROUP_SC_MEMBER_POWER,    19038). % 返回成员战力
-define(MSG_FORMAT_GROUP_SC_MEMBER_POWER, {?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% task  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_TASK,                21000). % 任务
-define(MODULE_PACKET_TASK,              task_packet). 
-define(MODULE_HANDLER_TASK,             task_handler). 

-define(MSG_ID_TASK_CS_INFO,             20001). % 请求任务信息
-define(MSG_FORMAT_TASK_CS_INFO,         {}).
-define(MSG_ID_TASK_SC_INFO,             20010). % 返回任务信息
-define(MSG_FORMAT_TASK_SC_INFO,         {?uint16,?uint8,?uint8,?uint32,{?cycle,{?uint8,?uint8,?uint8,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_TASK_CS_ACCEPT,           20011). % 接任务
-define(MSG_FORMAT_TASK_CS_ACCEPT,       {?uint16}).
-define(MSG_ID_TASK_SC_NOT_ACCEPTABLE_MAIN, 20012). % 未可接主线任务
-define(MSG_FORMAT_TASK_SC_NOT_ACCEPTABLE_MAIN, {?uint16}).
-define(MSG_ID_TASK_CS_SUBMIT,           20021). % 交任务
-define(MSG_FORMAT_TASK_CS_SUBMIT,       {?uint16}).
-define(MSG_ID_TASK_CS_ABANDON,          20031). % 放弃任务
-define(MSG_FORMAT_TASK_CS_ABANDON,      {?uint16}).
-define(MSG_ID_TASK_CS_AUTO_FINISH,      20041). % 自动完成任务
-define(MSG_FORMAT_TASK_CS_AUTO_FINISH,  {?uint16}).
-define(MSG_ID_TASK_SC_REMOVE,           20050). % 移除任务
-define(MSG_FORMAT_TASK_SC_REMOVE,       {?uint16,?uint8}).
-define(MSG_ID_TASK_SC_DAILY_COUNT,      20060). % 日常任务次数
-define(MSG_FORMAT_TASK_SC_DAILY_COUNT,  {?uint8}).
-define(MSG_ID_TASK_SC_GUILD_COUNT,      20070). % 军团任务次数
-define(MSG_FORMAT_TASK_SC_GUILD_COUNT,  {?uint8}).
-define(MSG_ID_TASK_CS_TEST_KILL,        20901). % 测试杀怪任务
-define(MSG_FORMAT_TASK_CS_TEST_KILL,    {?uint16,?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% rank  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_RANK,                21100). % 排行榜
-define(MODULE_PACKET_RANK,              rank_packet). 
-define(MODULE_HANDLER_RANK,             rank_handler). 

-define(MSG_ID_RANK_CS_PLAYER,           21001). % 人物信息
-define(MSG_FORMAT_RANK_CS_PLAYER,       {?uint32,?uint32}).
-define(MSG_ID_RANK_SC_PLAYER,           21002). % 人物信息
-define(MSG_FORMAT_RANK_SC_PLAYER,       {?uint32,?uint8,?string,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8,?uint8,?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% resource  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_RESOURCE,            22100). % 资源
-define(MODULE_PACKET_RESOURCE,          resource_packet). 
-define(MODULE_HANDLER_RESOURCE,         resource_handler). 

-define(MSG_ID_RESOURCE_CSRUNEINFO,      21101). % 招财信息
-define(MSG_FORMAT_RESOURCE_CSRUNEINFO,  {}).
-define(MSG_ID_RESOURCE_SCRUNEINFO,      21102). % 招财信息
-define(MSG_FORMAT_RESOURCE_SCRUNEINFO,  {?uint16,?uint16,{?cycle,{?uint16,?uint16,?uint32}}}).
-define(MSG_ID_RESOURCE_CSUSERUNE,       21103). % 招财
-define(MSG_FORMAT_RESOURCE_CSUSERUNE,   {?uint8}).
-define(MSG_ID_RESOURCE_SCRUNECHESTINFO, 21106). % 招财宝箱信息
-define(MSG_FORMAT_RESOURCE_SCRUNECHESTINFO, {{?cycle,{?uint16,?uint16,?uint32,?uint16}}}).
-define(MSG_ID_RESOURCE_CSRUNEUPGRADE,   21107). % 提升招财宝箱品质
-define(MSG_FORMAT_RESOURCE_CSRUNEUPGRADE, {?uint16}).
-define(MSG_ID_RESOURCE_CSOPENRUNECHEST, 21109). % 开启招财宝箱
-define(MSG_FORMAT_RESOURCE_CSOPENRUNECHEST, {?uint16}).
-define(MSG_ID_RESOURCE_CSPRAYINFO,      21111). % 拜将信息
-define(MSG_FORMAT_RESOURCE_CSPRAYINFO,  {}).
-define(MSG_ID_RESOURCE_SCPRAYINFO,      21112). % 拜将信息
-define(MSG_FORMAT_RESOURCE_SCPRAYINFO,  {?uint8}).
-define(MSG_ID_RESOURCE_CSUSEPRAY,       21113). % 拜将
-define(MSG_FORMAT_RESOURCE_CSUSEPRAY,   {?uint8}).
-define(MSG_ID_RESOURCE_SC_POOL,         21200). % 奖金
-define(MSG_FORMAT_RESOURCE_SC_POOL,     {?uint16,?uint32}).
-define(MSG_ID_RESOURCE_CS_1,            21201). % 抽奖
-define(MSG_FORMAT_RESOURCE_CS_1,        {?uint16}).
-define(MSG_ID_RESOURCE_SC_COUNT,        21202). % 奖券数量
-define(MSG_FORMAT_RESOURCE_SC_COUNT,    {?uint16}).
-define(MSG_ID_RESOURCE_CS_REQ_POOL,     21203). % 请求奖池数据
-define(MSG_FORMAT_RESOURCE_CS_REQ_POOL, {?uint16}).
-define(MSG_ID_RESOURCE_SC_CD,           21204). % cd
-define(MSG_FORMAT_RESOURCE_SC_CD,       {?uint32}).
-define(MSG_ID_RESOURCE_CS_CLEAR_CD,     21205). % 清除cd
-define(MSG_FORMAT_RESOURCE_CS_CLEAR_CD, {}).
-define(MSG_ID_RESOURCE_SC_WINNING,      21206). % 中奖玩家信息
-define(MSG_FORMAT_RESOURCE_SC_WINNING,  {?uint32,?string,?uint32,?uint16}).
-define(MSG_ID_RESOURCE_CS_BIG_AWARD,    21207). % 请求一等奖玩家信息
-define(MSG_FORMAT_RESOURCE_CS_BIG_AWARD, {}).
-define(MSG_ID_RESOURCE_SC_BIG_AWARD,    21208). % 一等奖玩家信息
-define(MSG_FORMAT_RESOURCE_SC_BIG_AWARD, {?uint32,?string,?uint32,?uint16}).
-define(MSG_ID_RESOURCE_SC_AWARD,        21210). % 抽奖结果
-define(MSG_FORMAT_RESOURCE_SC_AWARD,    {?uint8,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% single_arena  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SINGLE_ARENA,        23100). % 一骑讨
-define(MODULE_PACKET_SINGLE_ARENA,      single_arena_packet). 
-define(MODULE_HANDLER_SINGLE_ARENA,     single_arena_handler). 

-define(MSG_ID_SINGLE_ARENA_CS_ENTER,    22101). % 打开/关闭竞技场界面
-define(MSG_FORMAT_SINGLE_ARENA_CS_ENTER, {?uint8}).
-define(MSG_ID_SINGLE_ARENA_SC_ENTER,    22102). % 打开/关闭竞技场界面
-define(MSG_FORMAT_SINGLE_ARENA_SC_ENTER, {?uint8,?uint32,?uint16,?uint8,?uint32,?uint8,?uint32,?uint32,?uint32,?uint8,?uint32,?uint16,?uint16,?uint8,{?cycle,{?uint8}},{?cycle,{?uint32,?uint8,?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?string,?uint32,?uint32,?uint32}},{?cycle,{?string,?uint8,?uint32,?uint32,?string,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_SINGLE_ARENA_CS_CLEAR_CD, 22107). % 清除cd
-define(MSG_FORMAT_SINGLE_ARENA_CS_CLEAR_CD, {}).
-define(MSG_ID_SINGLE_ARENA_SC_CLEAR_CD, 22108). % 清除cd
-define(MSG_FORMAT_SINGLE_ARENA_SC_CLEAR_CD, {?uint8}).
-define(MSG_ID_SINGLE_ARENA_CS_START_BATTLE, 22109). % 发起战斗
-define(MSG_FORMAT_SINGLE_ARENA_CS_START_BATTLE, {?uint32}).
-define(MSG_ID_SINGLE_ARENA_CS_WIN_STREAK_AWARD, 22111). % 领取连胜奖励
-define(MSG_FORMAT_SINGLE_ARENA_CS_WIN_STREAK_AWARD, {?uint16}).
-define(MSG_ID_SINGLE_ARENA_SC_WIN_STREAK_AWARD, 22112). % 领取连胜奖励返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_WIN_STREAK_AWARD, {?uint8,{?cycle,{?uint8}}}).
-define(MSG_ID_SINGLE_ARENA_CS_RANK,     22113). % 竞技场排行榜（前三）
-define(MSG_FORMAT_SINGLE_ARENA_CS_RANK, {}).
-define(MSG_ID_SINGLE_ARENA_SC_RANK,     22114). % 竞技场排行榜返回（前三）
-define(MSG_FORMAT_SINGLE_ARENA_SC_RANK, {{?cycle,{?uint32,?uint8,?uint8,?uint32,?string,?uint8,?uint32,?uint8,?uint8,?uint32}}}).
-define(MSG_ID_SINGLE_ARENA_CS_BUY_CHALLENGE_TIME, 22115). % 购买战斗次数
-define(MSG_FORMAT_SINGLE_ARENA_CS_BUY_CHALLENGE_TIME, {}).
-define(MSG_ID_SINGLE_ARENA_SC_BUY_CHALLENGE_TIME, 22116). % 购买战斗次数返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_BUY_CHALLENGE_TIME, {?uint8,?uint8}).
-define(MSG_ID_SINGLE_ARENA_CS_RANK_AWARD, 22117). % 领取排名奖励
-define(MSG_FORMAT_SINGLE_ARENA_CS_RANK_AWARD, {}).
-define(MSG_ID_SINGLE_ARENA_SC_RANK_AWARD, 22118). % 领取排名奖励返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_RANK_AWARD, {?uint16}).
-define(MSG_ID_SINGLE_ARENA_CS_GET_REPORT, 22119). % 请求战报
-define(MSG_FORMAT_SINGLE_ARENA_CS_GET_REPORT, {?string}).
-define(MSG_ID_SINGLE_ARENA_SC_REFRESH_PER_REPORT, 22200). % 战报更新
-define(MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_PER_REPORT, {?string,?uint8,?uint32,?uint32,?string,?uint8,?uint32,?uint8}).
-define(MSG_ID_SINGLE_ARENA_CS_CHAMPION_REPORT, 22201). % 请求冠军战报
-define(MSG_FORMAT_SINGLE_ARENA_CS_CHAMPION_REPORT, {}).
-define(MSG_ID_SINGLE_ARENA_SC_CHAMPION_REPORT, 22202). % 冠军战报更新
-define(MSG_FORMAT_SINGLE_ARENA_SC_CHAMPION_REPORT, {?string,?uint32,?string,?uint32,?string,?uint32}).
-define(MSG_ID_SINGLE_ARENA_CS_TOP_RANK, 22301). % 竞技场英雄榜
-define(MSG_FORMAT_SINGLE_ARENA_CS_TOP_RANK, {?uint8}).
-define(MSG_ID_SINGLE_ARENA_SC_TOP_RANK, 22302). % 竞技场英雄榜返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_TOP_RANK, {{?cycle,{?uint32,?uint32,?string,?uint8,?uint8,?uint32,?uint8}}}).
-define(MSG_ID_SINGLE_ARENA_CS_TOP_STREAK, 22303). % 竞技场连胜榜
-define(MSG_FORMAT_SINGLE_ARENA_CS_TOP_STREAK, {?uint8}).
-define(MSG_ID_SINGLE_ARENA_SC_TOP_STREAK, 22304). % 竞技场连胜榜返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_TOP_STREAK, {{?cycle,{?uint32,?uint32,?string,?uint8,?uint32,?uint16}}}).
-define(MSG_ID_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, 22800). % 更新挑战列表
-define(MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_CHALLENGE_LIST, {{?cycle,{?uint32,?uint8,?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint8,?uint32,?uint32,?uint32,?string,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_SINGLE_ARENA_SC_REFRESH_REPORT, 22900). % 更新战斗信息
-define(MSG_FORMAT_SINGLE_ARENA_SC_REFRESH_REPORT, {?uint32,?uint16,?uint16,?uint16,?uint8,?uint32,?uint32,?uint32,?uint8,?uint32}).
-define(MSG_ID_SINGLE_ARENA_CS_LOGIN_DATA, 22909). % 登录推送挑战次数/CD请求
-define(MSG_FORMAT_SINGLE_ARENA_CS_LOGIN_DATA, {}).
-define(MSG_ID_SINGLE_ARENA_SC_LOGIN_DATA, 22910). % 登录推送挑战次数/CD返回
-define(MSG_FORMAT_SINGLE_ARENA_SC_LOGIN_DATA, {?uint8,?uint32,?uint8}).
-define(MSG_ID_SINGLE_ARENA_CS_EXCHANGE, 22911). % 积分兑换
-define(MSG_FORMAT_SINGLE_ARENA_CS_EXCHANGE, {?uint32,?uint16}).
-define(MSG_ID_SINGLE_ARENA_SC_SCORE_UPDATE, 22912). % 积分改变
-define(MSG_FORMAT_SINGLE_ARENA_SC_SCORE_UPDATE, {?uint32}).
-define(MSG_ID_SINGLE_ARENA_SC_TARGET,   22914). % 每日目标
-define(MSG_FORMAT_SINGLE_ARENA_SC_TARGET, {?uint32,?uint8}).
-define(MSG_ID_SINGLE_ARENA_CS_GET_TARGET_REWARD, 22915). % 领目标奖励
-define(MSG_FORMAT_SINGLE_ARENA_CS_GET_TARGET_REWARD, {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% lottery  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_LOTTERY,             24100). % 淘宝
-define(MODULE_PACKET_LOTTERY,           lottery_packet). 
-define(MODULE_HANDLER_LOTTERY,          lottery_handler). 

-define(MSG_ID_LOTTERY_CSINTERFACE,      23101). % 打开淘宝界面
-define(MSG_FORMAT_LOTTERY_CSINTERFACE,  {}).
-define(MSG_ID_LOTTERY_SCINTERFACE,      23102). % 打开淘宝界面
-define(MSG_FORMAT_LOTTERY_SCINTERFACE,  {?uint16,?uint16,?uint16,?uint16,{?cycle,{?uint8,?uint32,?string,?uint32}}}).
-define(MSG_ID_LOTTERY_CSDRAW,           23105). % 抽奖
-define(MSG_FORMAT_LOTTERY_CSDRAW,       {?uint8,?uint8}).
-define(MSG_ID_LOTTERY_SCDRAW,           23106). % 抽奖
-define(MSG_FORMAT_LOTTERY_SCDRAW,       {?bool,{?cycle,{?uint8,?uint32,?uint8}}}).
-define(MSG_ID_LOTTERY_CSACCUMULATOR,    23107). % 累计奖励
-define(MSG_FORMAT_LOTTERY_CSACCUMULATOR, {{?cycle,{?uint8}}}).
-define(MSG_ID_LOTTERY_CSFETCH,          23109). % 仓库道具直接取出到背包
-define(MSG_FORMAT_LOTTERY_CSFETCH,      {?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% mind  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MIND,                25100). % 心法系统
-define(MODULE_PACKET_MIND,              mind_packet). 
-define(MODULE_HANDLER_MIND,             mind_handler). 

-define(MSG_ID_MIND_LIST,                24101). % 获取心法列表(装备区和背包)
-define(MSG_FORMAT_MIND_LIST,            {?uint8,?uint32,?uint8}).
-define(MSG_ID_MIND_LIST_RETURN,         24102). % 玩家心法列表返回
-define(MSG_FORMAT_MIND_LIST_RETURN,     {?uint8,?uint32,?uint8,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint8}}}).
-define(MSG_ID_MIND_READ_LIST,           24105). % 获取参阅状态列表
-define(MSG_FORMAT_MIND_READ_LIST,       {}).
-define(MSG_ID_MIND_READ_LIST_RETURN,    24106). % 参阅状态列表返回
-define(MSG_FORMAT_MIND_READ_LIST_RETURN, {?uint8,?uint16,?uint16,{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_MIND_UPGRADE,             24107). % 心法升级
-define(MSG_FORMAT_MIND_UPGRADE,         {?uint32,?uint8,?uint8,?uint8}).
-define(MSG_ID_MIND_UPGRADE_RETURN,      24108). % 心法升级返回
-define(MSG_FORMAT_MIND_UPGRADE_RETURN,  {?uint8,?uint32}).
-define(MSG_ID_MIND_ABSORB,              24109). % 心法吸收(转化灵力)
-define(MSG_FORMAT_MIND_ABSORB,          {?uint8,?uint8}).
-define(MSG_ID_MIND_ABSORB_RETURN,       24110). % 心法吸收返回
-define(MSG_FORMAT_MIND_ABSORB_RETURN,   {?uint8,?uint8,?uint8}).
-define(MSG_ID_MIND_ONE_KEY_ABSORB,      24111). % 一键吸收
-define(MSG_FORMAT_MIND_ONE_KEY_ABSORB,  {?uint8}).
-define(MSG_ID_MIND_ONE_KEY_ABSORB_RETURN, 24112). % 一键吸收返回
-define(MSG_FORMAT_MIND_ONE_KEY_ABSORB_RETURN, {?uint8,?uint32}).
-define(MSG_ID_MIND_READ_SECRET,         24113). % 参阅秘籍(自动刷新下一参阅状态)
-define(MSG_FORMAT_MIND_READ_SECRET,     {?uint8,?uint8}).
-define(MSG_ID_MIND_READ_SECRET_RETURN,  24114). % 参阅秘籍返回
-define(MSG_FORMAT_MIND_READ_SECRET_RETURN, {?uint8,?uint8,?uint8,?uint32}).
-define(MSG_ID_MIND_ONE_KEY_READ,        24115). % 一键参阅
-define(MSG_FORMAT_MIND_ONE_KEY_READ,    {}).
-define(MSG_ID_MIND_ONE_KEY_READ_RETURN, 24116). % 一键参阅返回
-define(MSG_FORMAT_MIND_ONE_KEY_READ_RETURN, {?uint8,{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_MIND_EXTERN_BAG,          24121). % 扩展背包
-define(MSG_FORMAT_MIND_EXTERN_BAG,      {?uint8}).
-define(MSG_ID_MIND_EXTERN_BAG_RETURN,   24122). % 扩展背包返回
-define(MSG_FORMAT_MIND_EXTERN_BAG_RETURN, {?uint8,?uint8}).
-define(MSG_ID_MIND_TEMP_BAG_LIST,       24123). % 获取临时背包
-define(MSG_FORMAT_MIND_TEMP_BAG_LIST,   {}).
-define(MSG_ID_MIND_TEMP_BAG_LIST_RETURN, 24124). % 获取临时背包返回
-define(MSG_FORMAT_MIND_TEMP_BAG_LIST_RETURN, {{?cycle,{?uint8}}}).
-define(MSG_ID_MIND_PICK,                24125). % 拾取心法
-define(MSG_FORMAT_MIND_PICK,            {?uint8,?uint8}).
-define(MSG_ID_MIND_PICK_RESULT,         24126). % 拾取心法返回
-define(MSG_FORMAT_MIND_PICK_RESULT,     {?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_MIND_ONE_KEY_PICK,        24127). % 一键拾取
-define(MSG_FORMAT_MIND_ONE_KEY_PICK,    {?uint8}).
-define(MSG_ID_MIND_ONE_KEY_PICK_RESULT, 24128). % 一键拾取返回
-define(MSG_FORMAT_MIND_ONE_KEY_PICK_RESULT, {?uint8,?uint32,{?cycle,{?uint8,?uint8,?uint8}}}).
-define(MSG_ID_MIND_EXCHANGE,            24129). % 交换心法位置(包含装备卸载)
-define(MSG_FORMAT_MIND_EXCHANGE,        {?uint8,?uint8,?uint32,?uint8,?uint8}).
-define(MSG_ID_MIND_EXCHANGE_RESULT,     24130). % 交换心法位置返回(包含装备卸载)
-define(MSG_FORMAT_MIND_EXCHANGE_RESULT, {?uint8}).
-define(MSG_ID_MIND_GET_MIND_BY_POS,     24131). % 更新心法信息(对于单个心法格子)
-define(MSG_FORMAT_MIND_GET_MIND_BY_POS, {?uint8,?uint8,?uint32,?uint8}).
-define(MSG_ID_MIND_GET_MIND_BY_POS_RETURN, 24132). % 更新心法信息返回
-define(MSG_FORMAT_MIND_GET_MIND_BY_POS_RETURN, {?uint8,?uint8,?uint32,?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_MIND_CHANGE_BAG_STATUS,   24133). % 锁定/解锁心法
-define(MSG_FORMAT_MIND_CHANGE_BAG_STATUS, {?uint8,?uint8,?uint32,?uint8}).
-define(MSG_ID_MIND_GET_SPIRIT,          24199). % 获取玩家灵力值
-define(MSG_FORMAT_MIND_GET_SPIRIT,      {}).
-define(MSG_ID_MIND_UPDATE_SPIRIT,       24200). % 更新灵力值
-define(MSG_FORMAT_MIND_UPDATE_SPIRIT,   {?uint32}).
-define(MSG_ID_MIND_UPDATE_FREE_TIMES,   24300). % 更新免费参阅次数
-define(MSG_FORMAT_MIND_UPDATE_FREE_TIMES, {?uint8}).
-define(MSG_ID_MIND_CS_GET_SCORE,        24401). % 查询祈天积分
-define(MSG_FORMAT_MIND_CS_GET_SCORE,    {}).
-define(MSG_ID_MIND_SC_UPDATE_SCORE,     24402). % 更新祈天积分
-define(MSG_FORMAT_MIND_SC_UPDATE_SCORE, {?uint32}).
-define(MSG_ID_MIND_CS_EXCHANGE_SCORE,   24403). % 兑换心法
-define(MSG_FORMAT_MIND_CS_EXCHANGE_SCORE, {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% message  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MESSAGE,             26100). % 消息系统
-define(MODULE_PACKET_MESSAGE,           message_packet). 
-define(MODULE_HANDLER_MESSAGE,          message_handler). 

-define(MSG_ID_MESSAGE_SC_WINDOW,        25102). % 弹窗消息
-define(MSG_FORMAT_MESSAGE_SC_WINDOW,    {?uint8}).
-define(MSG_ID_MESSAGE_SC_NOTICE,        25200). % 通知消息
-define(MSG_FORMAT_MESSAGE_SC_NOTICE,    {?uint16}).
-define(MSG_ID_MESSAGE_SC_SYSTEM,        25300). % 系统消息
-define(MSG_FORMAT_MESSAGE_SC_SYSTEM,    {?uint16,{?cycle,{?uint32,?string}},{?cycle,{?uint32,?uint16,?bool,?uint32,?uint32}},{?cycle,{?uint32,?uint8,?bool,?uint32,?uint32,?uint8,{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},{?cycle,{?uint32}}}},{?cycle,{?uint8,?string}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% skill  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SKILL,               27100). % 技能
-define(MODULE_PACKET_SKILL,             skill_packet). 
-define(MODULE_HANDLER_SKILL,            skill_handler). 

-define(MSG_ID_SKILL_CS_SKILL_INFO,      26101). % 请求技能信息
-define(MSG_FORMAT_SKILL_CS_SKILL_INFO,  {}).
-define(MSG_ID_SKILL_CS_UPGRADE_SKILL,   26111). % 升级技能
-define(MSG_FORMAT_SKILL_CS_UPGRADE_SKILL, {?uint16}).
-define(MSG_ID_SKILL_CS_ENABLE_SKILL,    26121). % 启用技能
-define(MSG_FORMAT_SKILL_CS_ENABLE_SKILL, {?uint16,?uint8}).
-define(MSG_ID_SKILL_CS_DISABLE_SKILL,   26131). % 停用技能
-define(MSG_FORMAT_SKILL_CS_DISABLE_SKILL, {?uint8}).
-define(MSG_ID_SKILL_CS_EXCHANGE_SKILL_BAR, 26141). % 交换技能栏位置
-define(MSG_FORMAT_SKILL_CS_EXCHANGE_SKILL_BAR, {?uint8,?uint8}).
-define(MSG_ID_SKILL_CS_RESET_SKILL_POINT, 26151). % 技能洗点
-define(MSG_FORMAT_SKILL_CS_RESET_SKILL_POINT, {}).
-define(MSG_ID_SKILL_SC_SKILL_INFO,      26200). % 技能信息
-define(MSG_FORMAT_SKILL_SC_SKILL_INFO,  {{?cycle,{?uint16,?uint8}}}).
-define(MSG_ID_SKILL_SC_UPDRADE_SUCCESS, 26202). % 升级技能返回
-define(MSG_FORMAT_SKILL_SC_UPDRADE_SUCCESS, {?uint16}).
-define(MSG_ID_SKILL_SC_SKILL_BAR_INFO,  26210). % 技能栏信息
-define(MSG_FORMAT_SKILL_SC_SKILL_BAR_INFO, {{?cycle,{?uint16}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% horse  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_HORSE,               27300). % 坐骑
-define(MODULE_PACKET_HORSE,             horse_packet). 
-define(MODULE_HANDLER_HORSE,            horse_handler). 

-define(MSG_ID_HORSE_CS_DEVELOP,         27201). % 坐骑培养数据请求
-define(MSG_FORMAT_HORSE_CS_DEVELOP,     {}).
-define(MSG_ID_HORSE_SC_DEVELOP,         27202). % 坐骑培养数据返回
-define(MSG_FORMAT_HORSE_SC_DEVELOP,     {?uint8,?uint32,?uint32}).
-define(MSG_ID_HORSE_SC_DEL_DEVELOP,     27204). % 删除小马驹
-define(MSG_FORMAT_HORSE_SC_DEL_DEVELOP, {?uint8}).
-define(MSG_ID_HORSE_CS_TAKE_OUT,        27205). % 取出
-define(MSG_FORMAT_HORSE_CS_TAKE_OUT,    {?uint8}).
-define(MSG_ID_HORSE_CS_FEEDHORSE,       27207). % 喂养坐骑装备
-define(MSG_FORMAT_HORSE_CS_FEEDHORSE,   {{?cycle,{?uint16}}}).
-define(MSG_ID_HORSE_CS_NORMALDEVE,      27209). % 强化
-define(MSG_FORMAT_HORSE_CS_NORMALDEVE,  {?uint8}).
-define(MSG_ID_HORSE_CS_HORSESKILL,      27217). % 坐骑替换技能
-define(MSG_FORMAT_HORSE_CS_HORSESKILL,  {?uint32}).
-define(MSG_ID_HORSE_SC_HORSESKILL,      27218). % 技能替换返回
-define(MSG_FORMAT_HORSE_SC_HORSESKILL,  {?uint8}).
-define(MSG_ID_HORSE_SC_SKILL_HAVE,      27220). % 坐骑技能
-define(MSG_FORMAT_HORSE_SC_SKILL_HAVE,  {?uint32}).
-define(MSG_ID_HORSE_CS_USER_EXP_CARD,   27221). % 使用坐骑经验卡
-define(MSG_FORMAT_HORSE_CS_USER_EXP_CARD, {?uint8}).
-define(MSG_ID_HORSE_CS_CLEAR_CD,        27231). % 清除CD时间
-define(MSG_FORMAT_HORSE_CS_CLEAR_CD,    {?uint8}).
-define(MSG_ID_HORSE_CS_ONE_KEY,         27241). % 一键升级
-define(MSG_FORMAT_HORSE_CS_ONE_KEY,     {}).
-define(MSG_ID_HORSE_SC_CRIT,            27250). % 暴击类型返回
-define(MSG_FORMAT_HORSE_SC_CRIT,        {?uint8}).
-define(MSG_ID_HORSE_STREN_COUNT,        27260). % 免费强化次数
-define(MSG_FORMAT_HORSE_STREN_COUNT,    {?uint8}).
-define(MSG_ID_HORSE_CS_REFRESH,         27271). % 坐骑洗练
-define(MSG_FORMAT_HORSE_CS_REFRESH,     {?uint8,?uint8,?uint8,{?cycle,{?uint16}}}).
-define(MSG_ID_HORSE_CS_REPLACESKIN,     27273). % 更改皮肤
-define(MSG_FORMAT_HORSE_CS_REPLACESKIN, {?uint32}).
-define(MSG_ID_HORSE_SC_USESKIN,         27274). % 可用的坐骑皮肤
-define(MSG_FORMAT_HORSE_SC_USESKIN,     {?uint32,?uint32}).
-define(MSG_ID_HORSE_CS_LVUPSKILL,       27275). % 升级坐骑技能
-define(MSG_FORMAT_HORSE_CS_LVUPSKILL,   {?uint8,?uint8}).
-define(MSG_ID_HORSE_CS_TIME_OVER,       27277). % 皮肤时间到
-define(MSG_FORMAT_HORSE_CS_TIME_OVER,   {?uint32}).
-define(MSG_ID_HORSE_SC_DEL_SKIN,        27278). % 删除皮肤
-define(MSG_FORMAT_HORSE_SC_DEL_SKIN,    {?uint32}).
-define(MSG_ID_HORSE_CS_HORSE_ATTR_NOT_SAVE, 27279). % 请求未保存坐骑洗练属性
-define(MSG_FORMAT_HORSE_CS_HORSE_ATTR_NOT_SAVE, {?uint8,?uint8,?uint8}).
-define(MSG_ID_HORSE_ATTR_NOT_SAVE,      27280). % 坐骑未保存的属性
-define(MSG_FORMAT_HORSE_ATTR_NOT_SAVE,  {{?cycle,{?uint8,?uint32}}}).
-define(MSG_ID_HORSE_CS_SAVE_ATTR_HORSE, 27281). % 保存/取消保存洗练属性
-define(MSG_FORMAT_HORSE_CS_SAVE_ATTR_HORSE, {?bool,?uint8,?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% shop  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SHOP,                28300). % 道具店
-define(MODULE_PACKET_SHOP,              shop_packet). 
-define(MODULE_HANDLER_SHOP,             shop_handler). 

-define(MSG_ID_SHOP_CS_SELL,             27301). % 出售物品
-define(MSG_FORMAT_SHOP_CS_SELL,         {?uint16}).
-define(MSG_ID_SHOP_SC_GOODS,            27302). % 回购信息
-define(MSG_FORMAT_SHOP_SC_GOODS,        {?uint16,?uint32,?uint8}).
-define(MSG_ID_SHOP_CS_LIST_REPURCHASE,  27303). % 申请回购列表
-define(MSG_FORMAT_SHOP_CS_LIST_REPURCHASE, {}).
-define(MSG_ID_SHOP_CS_PURCHASE,         27305). % 购买物品
-define(MSG_FORMAT_SHOP_CS_PURCHASE,     {?uint32,?uint8}).
-define(MSG_ID_SHOP_CS_REPURCHASE,       27307). % 回购物品
-define(MSG_FORMAT_SHOP_CS_REPURCHASE,   {?uint16}).
-define(MSG_ID_SHOP_SC_DEL_GOODS,        27308). % 删除物品
-define(MSG_FORMAT_SHOP_SC_DEL_GOODS,    {?uint16}).
-define(MSG_ID_SHOP_CS_SELL_LIST,        27309). % 批量卖出
-define(MSG_FORMAT_SHOP_CS_SELL_LIST,    {{?cycle,{?uint16}}}).
-define(MSG_ID_SHOP_CS_SECRET_INIT,      27311). % 云游商人初始化信息
-define(MSG_FORMAT_SHOP_CS_SECRET_INIT,  {}).
-define(MSG_ID_SHOP_SC_SECRET_INIT,      27312). % 云游商人初始化信息
-define(MSG_FORMAT_SHOP_SC_SECRET_INIT,  {?uint32,?uint16,?uint16,?uint32,?uint16,{?cycle,{?uint32,?uint32,?uint16,?uint32,?uint32,?uint8}}}).
-define(MSG_ID_SHOP_CS_SECRET_REFRESH,   27313). % 云游商人刷新
-define(MSG_FORMAT_SHOP_CS_SECRET_REFRESH, {}).
-define(MSG_ID_SHOP_SC_SECRET_REFRESH,   27314). % 云游商人刷新
-define(MSG_FORMAT_SHOP_SC_SECRET_REFRESH, {?uint8}).
-define(MSG_ID_SHOP_CS_BUY_GOODS,        27315). % 云游商人购买物品
-define(MSG_FORMAT_SHOP_CS_BUY_GOODS,    {?uint8,?uint32,?uint32}).
-define(MSG_ID_SHOP_SC_BUY_GOODS,        27316). % 云游商人购买物品
-define(MSG_FORMAT_SHOP_SC_BUY_GOODS,    {?uint8}).
-define(MSG_ID_SHOP_SC_LOG_INFO,         27318). % 云游商人购买记录信息
-define(MSG_FORMAT_SHOP_SC_LOG_INFO,     {{?cycle,{?string,?uint32,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% spring  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SPRING,              28400). % 温泉
-define(MODULE_PACKET_SPRING,            spring_packet). 
-define(MODULE_HANDLER_SPRING,           spring_handler). 

-define(MSG_ID_SPRING_CSENTER,           28303). % 进入温泉
-define(MSG_FORMAT_SPRING_CSENTER,       {}).
-define(MSG_ID_SPRING_SCENTER,           28304). % 进入温泉
-define(MSG_FORMAT_SPRING_SCENTER,       {?uint32}).
-define(MSG_ID_SPRING_CSEXIT,            28305). % 离开温泉
-define(MSG_FORMAT_SPRING_CSEXIT,        {}).
-define(MSG_ID_SPRING_SCEXIT,            28306). % 离开温泉
-define(MSG_FORMAT_SPRING_SCEXIT,        {?uint32}).
-define(MSG_ID_SPRING_SCEXP,             28308). % 经验
-define(MSG_FORMAT_SPRING_SCEXP,         {?uint32}).
-define(MSG_ID_SPRING_SCPS,              28310). % 体力
-define(MSG_FORMAT_SPRING_SCPS,          {?uint8}).
-define(MSG_ID_SPRING_SCOFF,             28314). % 温泉活动结束
-define(MSG_FORMAT_SPRING_SCOFF,         {?uint32,?uint8,?uint32}).
-define(MSG_ID_SPRING_CS_GET_SP,         28315). % 请求获得体力
-define(MSG_FORMAT_SPRING_CS_GET_SP,     {}).
-define(MSG_ID_SPRING_SC_SP_TIME,        28316). % 体力累计时间
-define(MSG_FORMAT_SPRING_SC_SP_TIME,    {?uint32}).
-define(MSG_ID_SPRING_SC_REQUEST,        28320). % 成功邀请
-define(MSG_FORMAT_SPRING_SC_REQUEST,    {?uint8}).
-define(MSG_ID_SPRING_CSDOUBLEREQUEST,   28321). % 双修请求
-define(MSG_FORMAT_SPRING_CSDOUBLEREQUEST, {?uint32,?uint8}).
-define(MSG_ID_SPRING_SCDOUBLERECEIVE,   28322). % 双修邀请
-define(MSG_FORMAT_SPRING_SCDOUBLERECEIVE, {?uint32,?string,?uint8}).
-define(MSG_ID_SPRING_CSDOUBLEREPLY,     28323). % 双修邀请回复
-define(MSG_FORMAT_SPRING_CSDOUBLEREPLY, {?uint32,?uint8,?bool}).
-define(MSG_ID_SPRING_SCDOUBLE,          28324). % 双修成功
-define(MSG_FORMAT_SPRING_SCDOUBLE,      {?uint32,?uint8,?bool}).
-define(MSG_ID_SPRING_CSCANCEL,          28331). % 取消双修
-define(MSG_FORMAT_SPRING_CSCANCEL,      {}).
-define(MSG_ID_SPRING_SCINFORMCANCEL,    28332). % 通知对方取消双修
-define(MSG_FORMAT_SPRING_SCINFORMCANCEL, {?uint32,?bool}).
-define(MSG_ID_SPRING_CS_NOTICE_REQ,     28345). % 双修整屏通知
-define(MSG_FORMAT_SPRING_CS_NOTICE_REQ, {?uint32,?uint8}).
-define(MSG_ID_SPRING_SC_NOTICE,         28346). % 双修整屏通知
-define(MSG_FORMAT_SPRING_SC_NOTICE,     {?uint32,?uint32,?uint8}).
-define(MSG_ID_SPRING_SC_CANCEL_NOTICE,  28348). % 取消双修广播
-define(MSG_FORMAT_SPRING_SC_CANCEL_NOTICE, {?uint32,?uint32}).
-define(MSG_ID_SPRING_SC_END_QUIT,       28350). % 温泉结束退出
-define(MSG_FORMAT_SPRING_SC_END_QUIT,   {?uint8}).
-define(MSG_ID_SPRING_CS_END_QUIT,       28351). % 温泉结束请求退出
-define(MSG_FORMAT_SPRING_CS_END_QUIT,   {}).
-define(MSG_ID_SPRING_CS_AUTO,           28361). % 设置自动双修
-define(MSG_FORMAT_SPRING_CS_AUTO,       {?uint8}).
-define(MSG_ID_SPRING_SC_AUTO,           28362). % 设置自动双修
-define(MSG_FORMAT_SPRING_SC_AUTO,       {?uint8}).
-define(MSG_ID_SPRING_SC_AUTO_REWARD,    28370). % 自动参加奖励
-define(MSG_FORMAT_SPRING_SC_AUTO_REWARD, {?uint32,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% gm  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GM,                  29500). % GM
-define(MODULE_PACKET_GM,                gm_packet). 
-define(MODULE_HANDLER_GM,               gm_handler). 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% tower  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_TOWER,               30500). % 闯塔
-define(MODULE_PACKET_TOWER,             tower_packet). 
-define(MODULE_HANDLER_TOWER,            tower_handler). 

-define(MSG_ID_TOWER_SC_OPEN_TOWER,      29501). % 打开闯塔
-define(MSG_FORMAT_TOWER_SC_OPEN_TOWER,  {}).
-define(MSG_ID_TOWER_OPEN_TOWER,         29502). % 打开闯塔
-define(MSG_FORMAT_TOWER_OPEN_TOWER,     {?uint8}).
-define(MSG_ID_TOWER_CS_SELECT_CAMP,     29503). % 选择大阵
-define(MSG_FORMAT_TOWER_CS_SELECT_CAMP, {?uint8}).
-define(MSG_ID_TOWER_SC_SELECT_CAMP,     29504). % 选择大阵
-define(MSG_FORMAT_TOWER_SC_SELECT_CAMP, {{?cycle,{?uint8,?uint8}},?uint8,?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_TOWER_CS_START_RUSH,      29505). % 进入关卡
-define(MSG_FORMAT_TOWER_CS_START_RUSH,  {?uint8}).
-define(MSG_ID_TOWER_SC_START_RUSH,      29506). % 进入关卡
-define(MSG_FORMAT_TOWER_SC_START_RUSH,  {?uint8,?uint32}).
-define(MSG_ID_TOWER_CS_DIVINE,          29507). % 占卜
-define(MSG_FORMAT_TOWER_CS_DIVINE,      {}).
-define(MSG_ID_TOWER_SC_DIVINE,          29508). % 占卜
-define(MSG_FORMAT_TOWER_SC_DIVINE,      {?uint8}).
-define(MSG_ID_TOWER_CS_AUTO_RUSH,       29509). % 闯塔扫荡
-define(MSG_FORMAT_TOWER_CS_AUTO_RUSH,   {?uint8,?uint8}).
-define(MSG_ID_TOWER_SC_AUTO_RUSH,       29510). % 闯塔扫荡
-define(MSG_FORMAT_TOWER_SC_AUTO_RUSH,   {{?cycle,{?uint8}}}).
-define(MSG_ID_TOWER_CS_STOP_RUSH,       29511). % 终止扫荡
-define(MSG_FORMAT_TOWER_CS_STOP_RUSH,   {}).
-define(MSG_ID_TOWER_SC_STOP_RUSH,       29512). % 终止扫荡
-define(MSG_FORMAT_TOWER_SC_STOP_RUSH,   {?uint8}).
-define(MSG_ID_TOWER_CS_RESET,           29513). % 重置
-define(MSG_FORMAT_TOWER_CS_RESET,       {?uint8}).
-define(MSG_ID_TOWER_CS_CARD,            29515). % 选择关卡
-define(MSG_FORMAT_TOWER_CS_CARD,        {?uint8}).
-define(MSG_ID_TOWER_SC_CARD,            29516). % 选择关卡
-define(MSG_FORMAT_TOWER_SC_CARD,        {?string,?uint32,?string,?uint32}).
-define(MSG_ID_TOWER_CS_AWARD,           29517). % 破阵奖励
-define(MSG_FORMAT_TOWER_CS_AWARD,       {?uint8}).
-define(MSG_ID_TOWER_SC_AWARD,           29518). % 领取奖励返回
-define(MSG_FORMAT_TOWER_SC_AWARD,       {?uint8}).
-define(MSG_ID_TOWER_CS_START_BATTLE,    29519). % 发起战斗
-define(MSG_FORMAT_TOWER_CS_START_BATTLE, {?uint32}).
-define(MSG_ID_TOWER_SC_START_BATTLE,    29520). % 关卡奖励返回
-define(MSG_FORMAT_TOWER_SC_START_BATTLE, {{?cycle,{?uint32,?uint8}},?uint32,?uint32}).
-define(MSG_ID_TOWER_CS_SPEED_TYPE,      29521). % 加速类型
-define(MSG_FORMAT_TOWER_CS_SPEED_TYPE,  {?uint8}).
-define(MSG_ID_TOWER_SC_SPEED_TYPE,      29522). % 加速类型返回
-define(MSG_FORMAT_TOWER_SC_SPEED_TYPE,  {?uint32,{?cycle,{?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint32}}}}}).
-define(MSG_ID_TOWER_SC_OPEN_RUSH,       29524). % 重新登录 打开扫荡
-define(MSG_FORMAT_TOWER_SC_OPEN_RUSH,   {?uint8,?uint8,?uint32,?uint8,{?cycle,{?uint8,?uint32,?uint32,{?cycle,{?uint32,?uint8}}}}}).
-define(MSG_ID_TOWER_CS_RUSH_OVER,       29525). % 扫荡结束
-define(MSG_FORMAT_TOWER_CS_RUSH_OVER,   {}).
-define(MSG_ID_TOWER_SC_RUSH_OVER,       29526). % 扫荡结束返回
-define(MSG_FORMAT_TOWER_SC_RUSH_OVER,   {?uint8,?uint32}).
-define(MSG_ID_TOWER_SC_WIPE_CARD,       29528). % 扫荡关卡返回
-define(MSG_FORMAT_TOWER_SC_WIPE_CARD,   {?uint8,?uint8,?uint32,?uint32,{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_TOWER_CS_DIVINE_INFO,     29529). % 请求占卜信息
-define(MSG_FORMAT_TOWER_CS_DIVINE_INFO, {}).
-define(MSG_ID_TOWER_CS_QUIT_TOWER,      29531). % 退出闯塔
-define(MSG_FORMAT_TOWER_CS_QUIT_TOWER,  {}).
-define(MSG_ID_TOWER_CS_VIP_AWARD,       29533). % VIP翻牌奖励
-define(MSG_FORMAT_TOWER_CS_VIP_AWARD,   {}).
-define(MSG_ID_TOWER_SC_VIP_AWARD,       29534). % VIP翻牌奖励返回
-define(MSG_FORMAT_TOWER_SC_VIP_AWARD,   {{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_TOWER_SC_BOSS_AWARD,      29536). % boss翻牌奖励
-define(MSG_FORMAT_TOWER_SC_BOSS_AWARD,  {?uint8,?bool,{?cycle,{?uint32,?uint8}},?uint8,?uint32,?uint32,?uint8,?uint32,?uint32,?uint32}).
-define(MSG_ID_TOWER_CS_BUY_TIMES,       29537). % VIP购买重置次数
-define(MSG_FORMAT_TOWER_CS_BUY_TIMES,   {}).
-define(MSG_ID_TOWER_SC_RESET_TIMES,     29538). % 购买重置次数返回
-define(MSG_FORMAT_TOWER_SC_RESET_TIMES, {?uint8}).
-define(MSG_ID_TOWER_CS_REPORT_LIST,     29539). % 请求战报列表
-define(MSG_FORMAT_TOWER_CS_REPORT_LIST, {?uint32}).
-define(MSG_ID_TOWER_SC_REPORT_LIST,     29540). % 战报列表
-define(MSG_FORMAT_TOWER_SC_REPORT_LIST, {?uint32,{?cycle,{?uint32,?string,?string}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% commerce  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_COMMERCE,            31000). % 商路
-define(MODULE_PACKET_COMMERCE,          commerce_packet). 
-define(MODULE_HANDLER_COMMERCE,         commerce_handler). 

-define(MSG_ID_COMMERCE_CSENTERSCENE,    30501). % 进入商路场景
-define(MSG_FORMAT_COMMERCE_CSENTERSCENE, {}).
-define(MSG_ID_COMMERCE_SC_ROB_INFO,     30502). % 商路战报信息
-define(MSG_FORMAT_COMMERCE_SC_ROB_INFO, {?uint32,?string,?uint32,?string,?uint8,?uint32,?uint32}).
-define(MSG_ID_COMMERCE_CSEXITSCENE,     30503). % 离开商路场景
-define(MSG_FORMAT_COMMERCE_CSEXITSCENE, {}).
-define(MSG_ID_COMMERCE_ROB_FLAG,        30504). % 拦截交战标志
-define(MSG_FORMAT_COMMERCE_ROB_FLAG,    {?uint32,?uint8}).
-define(MSG_ID_COMMERCE_SC_GUILD_ADD,    30506). % 返回军团增益等级
-define(MSG_FORMAT_COMMERCE_SC_GUILD_ADD, {?uint8}).
-define(MSG_ID_COMMERCE_SCCARAVANINFO,   30512). % 商队信息
-define(MSG_FORMAT_COMMERCE_SCCARAVANINFO, {?uint32,?uint8,?uint32,?string,?uint8,?uint8,?uint8,?string,?uint32,?string,?uint16,?uint8,?bool,?uint32,?uint32,?uint32,?uint8}).
-define(MSG_ID_COMMERCE_SCCARAVANROBBED, 30514). % 商队被劫
-define(MSG_FORMAT_COMMERCE_SCCARAVANROBBED, {?uint16,?uint8}).
-define(MSG_ID_COMMERCE_SCPLAYERINFO,    30516). % 商路玩家信息
-define(MSG_FORMAT_COMMERCE_SCPLAYERINFO, {?uint8,?uint8,?uint8,?uint16,?uint16}).
-define(MSG_ID_COMMERCE_SCCARAVANVANISH, 30518). % 商队消失
-define(MSG_FORMAT_COMMERCE_SCCARAVANVANISH, {?uint32,?bool}).
-define(MSG_ID_COMMERCE_CSROB,           30521). % 拦截
-define(MSG_FORMAT_COMMERCE_CSROB,       {?uint32}).
-define(MSG_ID_COMMERCE_SCROB,           30522). % 拦截返回
-define(MSG_FORMAT_COMMERCE_SCROB,       {?uint32,?string,?uint32,?string,?uint8,?uint32,?uint32}).
-define(MSG_ID_COMMERCE_CSCDROBTIME,     30523). % 清除拦截冷却时间
-define(MSG_FORMAT_COMMERCE_CSCDROBTIME, {}).
-define(MSG_ID_COMMERCE_CSROBTIMES,      30525). % 购买拦截次数
-define(MSG_FORMAT_COMMERCE_CSROBTIMES,  {}).
-define(MSG_ID_COMMERCE_CSINVITE,        30531). % 邀请好友
-define(MSG_FORMAT_COMMERCE_CSINVITE,    {?uint32,?string}).
-define(MSG_ID_COMMERCE_SCINVITEBACK,    30532). % 发送邀请成功，开始倒计时
-define(MSG_FORMAT_COMMERCE_SCINVITEBACK, {?uint8}).
-define(MSG_ID_COMMERCE_CSREPLY,         30533). % 好友答复
-define(MSG_FORMAT_COMMERCE_CSREPLY,     {?uint32,?uint8}).
-define(MSG_ID_COMMERCE_SCINVITATIONREPLY, 30536). % 邀请结果
-define(MSG_FORMAT_COMMERCE_SCINVITATIONREPLY, {?uint32,?string,?uint8}).
-define(MSG_ID_COMMERCE_SCINFORMFRIEND,  30538). % 通知好友
-define(MSG_FORMAT_COMMERCE_SCINFORMFRIEND, {?uint32,?string}).
-define(MSG_ID_COMMERCE_SCFRIENDINFO,    30542). % 好友信息
-define(MSG_FORMAT_COMMERCE_SCFRIENDINFO, {?uint32,?string,?uint8,?uint8}).
-define(MSG_ID_COMMERCE_CSQUALITYREQUEST, 30551). % 请求开始运送信息
-define(MSG_FORMAT_COMMERCE_CSQUALITYREQUEST, {}).
-define(MSG_ID_COMMERCE_SCQUALITY,       30552). % 商队品质
-define(MSG_FORMAT_COMMERCE_SCQUALITY,   {?uint8,?uint32,?uint8,?uint32}).
-define(MSG_ID_COMMERCE_CSREFRESH,       30553). % 刷新商队品质
-define(MSG_FORMAT_COMMERCE_CSREFRESH,   {}).
-define(MSG_ID_COMMERCE_CSONEKEYREFRESH, 30555). % 一键刷新
-define(MSG_FORMAT_COMMERCE_CSONEKEYREFRESH, {}).
-define(MSG_ID_COMMERCE_CSCARRY,         30557). % 开始运送
-define(MSG_FORMAT_COMMERCE_CSCARRY,     {}).
-define(MSG_ID_COMMERCE_CSSPEEDUP,       30559). % 加速运送
-define(MSG_FORMAT_COMMERCE_CSSPEEDUP,   {}).
-define(MSG_ID_COMMERCE_CS_IGNORE_INVITE, 30561). % 标记忽略邀请
-define(MSG_FORMAT_COMMERCE_CS_IGNORE_INVITE, {?uint8}).
-define(MSG_ID_COMMERCE_SC_IGNORE_INVITE, 30562). % 返回标记忽略邀请
-define(MSG_FORMAT_COMMERCE_SC_IGNORE_INVITE, {?uint8}).
-define(MSG_ID_COMMERCE_SCCARRYCOMPLETION, 30566). % 完成运送
-define(MSG_FORMAT_COMMERCE_SCCARRYCOMPLETION, {?uint32,?uint32,?uint32}).
-define(MSG_ID_COMMERCE_CSBUILDMARKET,   30591). % 建造市场
-define(MSG_FORMAT_COMMERCE_CSBUILDMARKET, {}).
-define(MSG_ID_COMMERCE_SCBUILDMARKET,   30592). % 建造市场
-define(MSG_FORMAT_COMMERCE_SCBUILDMARKET, {?uint32}).
-define(MSG_ID_COMMERCE_SCMARKETINFO,    30594). % 市场信息
-define(MSG_FORMAT_COMMERCE_SCMARKETINFO, {?uint32,?string,?uint32}).
-define(MSG_ID_COMMERCE_SCMARKETVANISH,  30596). % 市场消失
-define(MSG_FORMAT_COMMERCE_SCMARKETVANISH, {?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% active  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ACTIVE,              33000). % 活动
-define(MODULE_PACKET_ACTIVE,            active_packet). 
-define(MODULE_HANDLER_ACTIVE,           active_handler). 

-define(MSG_ID_ACTIVE_BEGIN,             32002). % 活动开启
-define(MSG_FORMAT_ACTIVE_BEGIN,         {?uint16,?uint16}).
-define(MSG_ID_ACTIVE_END,               32004). % 活动关闭
-define(MSG_FORMAT_ACTIVE_END,           {?uint16,?uint16}).
-define(MSG_ID_ACTIVE_PREPARE,           32006). % 活动倒计时
-define(MSG_FORMAT_ACTIVE_PREPARE,       {?uint16,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% welfare  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_WELFARE,             34000). % 福利
-define(MODULE_PACKET_WELFARE,           welfare_packet). 
-define(MODULE_HANDLER_WELFARE,          welfare_handler). 

-define(MSG_ID_WELFARE_CSGIFTINFO,       33001). % 请求礼包信息
-define(MSG_FORMAT_WELFARE_CSGIFTINFO,   {?uint8}).
-define(MSG_ID_WELFARE_SCGIFTINFO,       33002). % 礼包信息
-define(MSG_FORMAT_WELFARE_SCGIFTINFO,   {?uint8,{?cycle,{?uint16,?uint8,?uint32}}}).
-define(MSG_ID_WELFARE_CSDRAW,           33003). % 领取礼包
-define(MSG_FORMAT_WELFARE_CSDRAW,       {?uint16,?bool}).
-define(MSG_ID_WELFARE_SCDRAW,           33004). % 领取礼包成功
-define(MSG_FORMAT_WELFARE_SCDRAW,       {?uint8,{?cycle,{?uint16}}}).
-define(MSG_ID_WELFARE_SCPULLULATION,    33010). % 已开启目标
-define(MSG_FORMAT_WELFARE_SCPULLULATION, {{?cycle,{?uint16,?bool,?uint8}}}).
-define(MSG_ID_WELFARE_CSRECEIVE,        33011). % 领取奖励
-define(MSG_FORMAT_WELFARE_CSRECEIVE,    {?uint16}).
-define(MSG_ID_WELFARE_SCRECEIVE,        33012). % 领取奖励成功
-define(MSG_FORMAT_WELFARE_SCRECEIVE,    {?uint16}).
-define(MSG_ID_WELFARE_SC_POWER,         33014). % 威武之路信息
-define(MSG_FORMAT_WELFARE_SC_POWER,     {?uint16}).
-define(MSG_ID_WELFARE_CS_LOGIN_REVIEW,  33017). % 连续登陆补签
-define(MSG_FORMAT_WELFARE_CS_LOGIN_REVIEW, {?uint16}).
-define(MSG_ID_WELFARE_SC_LOGIN_SIGN_TIMES, 33020). % 连续登陆补签次数
-define(MSG_FORMAT_WELFARE_SC_LOGIN_SIGN_TIMES, {?uint8}).
-define(MSG_ID_WELFARE_SC_DEPOSIT_INFO,  33100). % 充值礼包
-define(MSG_FORMAT_WELFARE_SC_DEPOSIT_INFO, {?uint32,?uint32,?uint8}).
-define(MSG_ID_WELFARE_SC_RMB,           33102). % 充值信息
-define(MSG_FORMAT_WELFARE_SC_RMB,       {?uint32,?uint32,?uint32}).
-define(MSG_ID_WELFARE_SC_END_TIME,      33104). % 活动结束时间
-define(MSG_FORMAT_WELFARE_SC_END_TIME,  {?uint32}).
-define(MSG_ID_WELFARE_CS_GET_GIFT_2,    33105). % 领取礼包
-define(MSG_FORMAT_WELFARE_CS_GET_GIFT_2, {?uint32}).
-define(MSG_ID_WELFARE_CS_JJ,            33107). % 请求基金活动
-define(MSG_FORMAT_WELFARE_CS_JJ,        {?uint8}).
-define(MSG_ID_WELFARE_SC_JJ_STATE,      33108). % 基金状态
-define(MSG_FORMAT_WELFARE_SC_JJ_STATE,  {?uint8,?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% collect  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_COLLECT,             35000). % 采集
-define(MODULE_PACKET_COLLECT,           collect_packet). 
-define(MODULE_HANDLER_COLLECT,          collect_handler). 

-define(MSG_ID_COLLECT_CS_START_COLLECT, 34001). % 开始采集
-define(MSG_FORMAT_COLLECT_CS_START_COLLECT, {?uint8,?uint8,?uint8}).
-define(MSG_ID_COLLECT_SC_START,         34002). % 开始采集
-define(MSG_FORMAT_COLLECT_SC_START,     {?uint8}).
-define(MSG_ID_COLLECT_SC_COLLECT_INFO,  34004). % 采集收获
-define(MSG_FORMAT_COLLECT_SC_COLLECT_INFO, {{?cycle,{?uint32,?uint8}},{?cycle,{?uint32,?uint8}},?uint8}).
-define(MSG_ID_COLLECT_CS_END_COLLECT,   34005). % 结束采集
-define(MSG_FORMAT_COLLECT_CS_END_COLLECT, {}).
-define(MSG_ID_COLLECT_CS_ENTER_MAP,     34007). % 进入采集地图
-define(MSG_FORMAT_COLLECT_CS_ENTER_MAP, {?uint16}).
-define(MSG_ID_COLLECT_CS_EXIT_MAP,      34009). % 退出采集地图
-define(MSG_FORMAT_COLLECT_CS_EXIT_MAP,  {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% boss  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_BOSS,                36000). % 世界BOSS
-define(MODULE_PACKET_BOSS,              boss_packet). 
-define(MODULE_HANDLER_BOSS,             boss_handler). 

-define(MSG_ID_BOSS_CS_ENTER,            35101). % 请求进入世界BOSS
-define(MSG_FORMAT_BOSS_CS_ENTER,        {?uint16}).
-define(MSG_ID_BOSS_CS_AUTO,             35111). % 自动
-define(MSG_FORMAT_BOSS_CS_AUTO,         {?bool}).
-define(MSG_ID_BOSS_CS_ENCOURAGE,        35121). % 鼓舞
-define(MSG_FORMAT_BOSS_CS_ENCOURAGE,    {}).
-define(MSG_ID_BOSS_CS_REBORN,           35131). % 浴火重生
-define(MSG_FORMAT_BOSS_CS_REBORN,       {}).
-define(MSG_ID_BOSS_CS_BATTLE,           35141). % 战斗开始
-define(MSG_FORMAT_BOSS_CS_BATTLE,       {?bool}).
-define(MSG_ID_BOSS_CS_REVIVE,           35151). % 复活
-define(MSG_FORMAT_BOSS_CS_REVIVE,       {}).
-define(MSG_ID_BOSS_CS_AUTO_REVIVE,      35153). % 自动复活
-define(MSG_FORMAT_BOSS_CS_AUTO_REVIVE,  {}).
-define(MSG_ID_BOSS_CS_QUIT,             35161). % 退出世界BOSS
-define(MSG_FORMAT_BOSS_CS_QUIT,         {}).
-define(MSG_ID_BOSS_CS_HIRE_DOLL,        35171). % 世界BOSS雇佣替身娃娃
-define(MSG_FORMAT_BOSS_CS_HIRE_DOLL,    {?uint16,?uint8,?uint8,?uint8,?uint32}).
-define(MSG_ID_BOSS_CS_DOLL_CASH,        35173). % 查询替身元宝数
-define(MSG_FORMAT_BOSS_CS_DOLL_CASH,    {?uint16}).
-define(MSG_ID_BOSS_CS_CHECK_STATE,      35181). % 查询状态
-define(MSG_FORMAT_BOSS_CS_CHECK_STATE,  {?uint16}).
-define(MSG_ID_BOSS_SC_ENTER,            35200). % 进入世界BOSS
-define(MSG_FORMAT_BOSS_SC_ENTER,        {?uint16,?uint8,?uint32,?uint32,?uint32,?bool,?uint32,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32,?uint8,?uint32,?uint8,?uint8,?string}).
-define(MSG_ID_BOSS_SC_STATE,            35202). % 状态信息
-define(MSG_FORMAT_BOSS_SC_STATE,        {?uint8}).
-define(MSG_ID_BOSS_SC_MONSTER_INFO,     35210). % 怪物信息
-define(MSG_FORMAT_BOSS_SC_MONSTER_INFO, {?uint32,?uint32,?uint32}).
-define(MSG_ID_BOSS_SC_QUIT_OK,          35212). % 退出世界BOSS成功
-define(MSG_FORMAT_BOSS_SC_QUIT_OK,      {}).
-define(MSG_ID_BOSS_SC_AUTO,             35220). % 自动返回
-define(MSG_FORMAT_BOSS_SC_AUTO,         {?bool}).
-define(MSG_ID_BOSS_SC_ENCOURAGE,        35230). % 鼓舞
-define(MSG_FORMAT_BOSS_SC_ENCOURAGE,    {?uint32}).
-define(MSG_ID_BOSS_SC_REBORN,           35240). % 浴火重生
-define(MSG_FORMAT_BOSS_SC_REBORN,       {?uint8}).
-define(MSG_ID_BOSS_SC_REVIVE,           35250). % 复活
-define(MSG_FORMAT_BOSS_SC_REVIVE,       {}).
-define(MSG_ID_BOSS_SC_HURT,             35260). % 个人伤害更新
-define(MSG_FORMAT_BOSS_SC_HURT,         {?uint32}).
-define(MSG_ID_BOSS_SC_REWARD,           35270). % 奖励通知
-define(MSG_FORMAT_BOSS_SC_REWARD,       {?uint16,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_BOSS_SC_EXIT_CD,          35280). % 世界BOSS冷却时间
-define(MSG_FORMAT_BOSS_SC_EXIT_CD,      {?uint32}).
-define(MSG_ID_BOSS_CS_DOLL_FLAG,        35290). % 世界BOSS替身状态
-define(MSG_FORMAT_BOSS_CS_DOLL_FLAG,    {?uint16,?bool}).
-define(MSG_ID_BOSS_SC_OPEN_NOTICE,      35300). % 世界BOSS开启通知(广播)
-define(MSG_FORMAT_BOSS_SC_OPEN_NOTICE,  {}).
-define(MSG_ID_BOSS_SC_START_NOTICE,     35310). % 世界BOSS开始通知(广播)
-define(MSG_FORMAT_BOSS_SC_START_NOTICE, {}).
-define(MSG_ID_BOSS_SC_END_NOTICE,       35320). % 世界BOSS结束通知(广播)
-define(MSG_FORMAT_BOSS_SC_END_NOTICE,   {?uint8}).
-define(MSG_ID_BOSS_SC_MONSTER_HP_NOTICE, 35330). % 世界BOSS怪物血量通知(广播)
-define(MSG_FORMAT_BOSS_SC_MONSTER_HP_NOTICE, {?uint32,?string,?uint8,?uint8,?uint32,?uint8}).
-define(MSG_ID_BOSS_SC_REMOVE_MONSTER_NOTICE, 35340). % 移除怪物通知(广播)
-define(MSG_FORMAT_BOSS_SC_REMOVE_MONSTER_NOTICE, {?uint32}).
-define(MSG_ID_BOSS_SC_UPDATE_MONSTER_NOTICE, 35350). % 更新怪物通知(广播)
-define(MSG_FORMAT_BOSS_SC_UPDATE_MONSTER_NOTICE, {?uint32,?uint32}).
-define(MSG_ID_BOSS_SC_RANK_NOTICE,      35360). % 排行数据通知(广播)
-define(MSG_FORMAT_BOSS_SC_RANK_NOTICE,  {{?cycle,{?string,?uint32}}}).
-define(MSG_ID_BOSS_SC_AUTO_REWARD,      35370). % 替身奖励
-define(MSG_FORMAT_BOSS_SC_AUTO_REWARD,  {?uint32,?uint32,?uint32}).
-define(MSG_ID_BOSS_SC_DOLL_CASH,        35372). % 替身元宝数
-define(MSG_FORMAT_BOSS_SC_DOLL_CASH,    {?uint16,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% invasion  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_INVASION,            37000). % 异民族
-define(MODULE_PACKET_INVASION,          invasion_packet). 
-define(MODULE_HANDLER_INVASION,         invasion_handler). 

-define(MSG_ID_INVASION_CS_START_GUARD,  36001). % 守关开始
-define(MSG_FORMAT_INVASION_CS_START_GUARD, {?uint16}).
-define(MSG_ID_INVASION_SC_START_GUARD,  36002). % 守关开始
-define(MSG_FORMAT_INVASION_SC_START_GUARD, {?uint8}).
-define(MSG_ID_INVASION_CS_END,          36003). % 退出副本
-define(MSG_FORMAT_INVASION_CS_END,      {}).
-define(MSG_ID_INVASION_SC_END,          36004). % 退出副本返回
-define(MSG_FORMAT_INVASION_SC_END,      {?uint8}).
-define(MSG_ID_INVASION_SCDEFENDEND,     36006). % 守关结束
-define(MSG_FORMAT_INVASION_SCDEFENDEND, {?bool,?bool}).
-define(MSG_ID_INVASION_SCMONHP,         36008). % 血量变化
-define(MSG_FORMAT_INVASION_SCMONHP,     {?uint32,?uint32,?uint32,?bool}).
-define(MSG_ID_INVASION_SC_REBORN,       36010). % 复活时间点
-define(MSG_FORMAT_INVASION_SC_REBORN,   {?uint32}).
-define(MSG_ID_INVASION_CS_START_BATTLE, 36011). % 发起战斗
-define(MSG_FORMAT_INVASION_CS_START_BATTLE, {?uint32}).
-define(MSG_ID_INVASION_SC_START_MONSTER, 36012). % 开始刷怪
-define(MSG_FORMAT_INVASION_SC_START_MONSTER, {?uint8,?uint32,?uint8}).
-define(MSG_ID_INVASION_CS_CLEAR_REBORN_CD, 36013). % 清复活CD
-define(MSG_FORMAT_INVASION_CS_CLEAR_REBORN_CD, {}).
-define(MSG_ID_INVASION_CS_I_WANA_REBORN, 36015). % 复活时间到点
-define(MSG_FORMAT_INVASION_CS_I_WANA_REBORN, {}).
-define(MSG_ID_INVASION_CSHALLINFO,      36017). % 大厅信息
-define(MSG_FORMAT_INVASION_CSHALLINFO,  {}).
-define(MSG_ID_INVASION_SCHALLINFO,      36018). % 大厅信息
-define(MSG_FORMAT_INVASION_SCHALLINFO,  {?uint8}).
-define(MSG_ID_INVASION_SCATTACK,        36022). % 攻关开始
-define(MSG_FORMAT_INVASION_SCATTACK,    {?uint8}).
-define(MSG_ID_INVASION_SCATTACKOVER,    36026). % 攻关结束
-define(MSG_FORMAT_INVASION_SCATTACKOVER, {?bool}).
-define(MSG_ID_INVASION_SCMONSTERINFO,   36030). % 异民族怪物信息
-define(MSG_FORMAT_INVASION_SCMONSTERINFO, {?bool,?uint8,?uint32,?uint32,?uint16,?uint16}).
-define(MSG_ID_INVASION_HURT_RANK,       36032). % 玩家伤害排名
-define(MSG_FORMAT_INVASION_HURT_RANK,   {{?cycle,{?uint32,?string,?uint32}}}).
-define(MSG_ID_INVASION_CSEVALUATION,    36039). % 评价
-define(MSG_FORMAT_INVASION_CSEVALUATION, {}).
-define(MSG_ID_INVASION_SCEVALUATION,    36040). % 评价
-define(MSG_FORMAT_INVASION_SCEVALUATION, {?uint8,?uint32,?uint32,?uint8,?uint32,?uint32,{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_INVASION_CSTURNCARD,      36043). % 翻牌
-define(MSG_FORMAT_INVASION_CSTURNCARD,  {}).
-define(MSG_ID_INVASION_SCTURNCARD,      36044). % 翻牌
-define(MSG_FORMAT_INVASION_SCTURNCARD,  {?bool,{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_INVASION_SCBATTLE,        36046). % 战斗返回
-define(MSG_FORMAT_INVASION_SCBATTLE,    {?uint8}).
-define(MSG_ID_INVASION_MON_COLLISON,    36050). % 怪物碰撞城门
-define(MSG_FORMAT_INVASION_MON_COLLISON, {?uint32,?uint32}).
-define(MSG_ID_INVASION_MON_START_BATTLE, 36052). % 怪物发起战斗
-define(MSG_FORMAT_INVASION_MON_START_BATTLE, {{?cycle,{?uint32}}}).
-define(MSG_ID_INVASION_DOLL_REWARD,     36054). % 替身奖励
-define(MSG_FORMAT_INVASION_DOLL_REWARD, {?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint8}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% schedule  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SCHEDULE,            38000). % 课程表
-define(MODULE_PACKET_SCHEDULE,          schedule_packet). 
-define(MODULE_HANDLER_SCHEDULE,         schedule_handler). 

-define(MSG_ID_SCHEDULE_CSSIGNINFO,      37001). % 签到信息
-define(MSG_FORMAT_SCHEDULE_CSSIGNINFO,  {}).
-define(MSG_ID_SCHEDULE_SCSIGNINFO,      37002). % 签到信息
-define(MSG_FORMAT_SCHEDULE_SCSIGNINFO,  {{?cycle,{?uint32}},?uint8,?uint8,?uint8}).
-define(MSG_ID_SCHEDULE_CSSIGN,          37003). % 每日签到
-define(MSG_FORMAT_SCHEDULE_CSSIGN,      {}).
-define(MSG_ID_SCHEDULE_CSREVIEW,        37005). % 每日补签
-define(MSG_FORMAT_SCHEDULE_CSREVIEW,    {}).
-define(MSG_ID_SCHEDULE_SCSIGNGIFT,      37008). % 签到礼品
-define(MSG_FORMAT_SCHEDULE_SCSIGNGIFT,  {?uint16,?bool}).
-define(MSG_ID_SCHEDULE_CSDRAWSIGNGIFT,  37009). % 领取签到礼品
-define(MSG_FORMAT_SCHEDULE_CSDRAWSIGNGIFT, {?uint16}).
-define(MSG_ID_SCHEDULE_CSACTIVITYINFO,  37021). % 日常活动信息
-define(MSG_FORMAT_SCHEDULE_CSACTIVITYINFO, {}).
-define(MSG_ID_SCHEDULE_SCACTIVITYINFO,  37022). % 日常活动信息
-define(MSG_FORMAT_SCHEDULE_SCACTIVITYINFO, {?uint16,?uint8,?bool}).
-define(MSG_ID_SCHEDULE_CSAUTO,          37023). % 自动完成活动（替身娃娃）
-define(MSG_FORMAT_SCHEDULE_CSAUTO,      {?uint16,?bool}).
-define(MSG_ID_SCHEDULE_SCAUTO,          37024). % 自动完成活动（替身娃娃）
-define(MSG_FORMAT_SCHEDULE_SCAUTO,      {?uint16,?bool}).
-define(MSG_ID_SCHEDULE_CSGUIDEINFO,     37041). % 日常引导信息
-define(MSG_FORMAT_SCHEDULE_CSGUIDEINFO, {}).
-define(MSG_ID_SCHEDULE_SCGUIDEINFO,     37042). % 日常引导信息
-define(MSG_FORMAT_SCHEDULE_SCGUIDEINFO, {?uint32,?uint16,?uint8}).
-define(MSG_ID_SCHEDULE_SCLIVENESS,      37044). % 活跃度
-define(MSG_FORMAT_SCHEDULE_SCLIVENESS,  {?uint16}).
-define(MSG_ID_SCHEDULE_SCLIVENESSGIFT,  37046). % 活跃度礼品
-define(MSG_FORMAT_SCHEDULE_SCLIVENESSGIFT, {?uint16,?bool}).
-define(MSG_ID_SCHEDULE_CSDRAWLIVENESSGIFT, 37047). % 领取活跃度礼品
-define(MSG_FORMAT_SCHEDULE_CSDRAWLIVENESSGIFT, {?uint16}).
-define(MSG_ID_SCHEDULE_SCDRAWLIVENESSGIFT, 37048). % 领取活跃度礼品
-define(MSG_FORMAT_SCHEDULE_SCDRAWLIVENESSGIFT, {?uint16}).
-define(MSG_ID_SCHEDULE_CSLOGIN,         37061). % 登录信息
-define(MSG_FORMAT_SCHEDULE_CSLOGIN,     {}).
-define(MSG_ID_SCHEDULE_SCLOGIN,         37062). % 登录信息
-define(MSG_FORMAT_SCHEDULE_SCLOGIN,     {?bool}).
-define(MSG_ID_SCHEDULE_SC_REVIEW_FLAG,  37064). % 补签标志
-define(MSG_FORMAT_SCHEDULE_SC_REVIEW_FLAG, {?bool}).
-define(MSG_ID_SCHEDULE_CS_PLAY_TIMES,   37065). % 每日军情玩法次数
-define(MSG_FORMAT_SCHEDULE_CS_PLAY_TIMES, {}).
-define(MSG_ID_SCHEDULE_SC_PLAY_TIMES,   37066). % 每日军情玩法次数
-define(MSG_FORMAT_SCHEDULE_SC_PLAY_TIMES, {?uint16,?uint32}).
-define(MSG_ID_SCHEDULE_CS_RESOURCE_LOOKFOR, 37071). % 请求资源找回
-define(MSG_FORMAT_SCHEDULE_CS_RESOURCE_LOOKFOR, {}).
-define(MSG_ID_SCHEDULE_SC_RESOURCE_LOOKFOR, 37072). % 请求资源找回返回
-define(MSG_FORMAT_SCHEDULE_SC_RESOURCE_LOOKFOR, {{?cycle,{?uint8,?uint32,?uint8}}}).
-define(MSG_ID_SCHEDULE_CS_SINGLE_RESOURCE, 37073). % 请求单个找回
-define(MSG_FORMAT_SCHEDULE_CS_SINGLE_RESOURCE, {?uint8,?uint8}).
-define(MSG_ID_SCHEDULE_SC_SINGLE_RESOURCE, 37074). % 请求单个找回返回
-define(MSG_FORMAT_SCHEDULE_SC_SINGLE_RESOURCE, {?uint8,?uint8}).
-define(MSG_ID_SCHEDULE_CS_ALL_RESOURCE, 37075). % 一键找回
-define(MSG_FORMAT_SCHEDULE_CS_ALL_RESOURCE, {?uint8}).
-define(MSG_ID_SCHEDULE_SC_ALL_RESOURCE, 37076). % 一键找回返回
-define(MSG_FORMAT_SCHEDULE_SC_ALL_RESOURCE, {?uint8}).
-define(MSG_ID_SCHEDULE_CS_POWER_INFO,   37901). % 战力信息
-define(MSG_FORMAT_SCHEDULE_CS_POWER_INFO, {}).
-define(MSG_ID_SCHEDULE_SC_POWER,        37902). % 战力信息
-define(MSG_FORMAT_SCHEDULE_SC_POWER,    {?uint16,?uint16,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% guide  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUIDE,               39000). % 新手引导
-define(MODULE_PACKET_GUIDE,             guide_packet). 
-define(MODULE_HANDLER_GUIDE,            guide_handler). 

-define(MSG_ID_GUIDE_CSINFO,             38001). % 模块信息
-define(MSG_FORMAT_GUIDE_CSINFO,         {}).
-define(MSG_ID_GUIDE_SCINFO,             38002). % 模块信息
-define(MSG_FORMAT_GUIDE_SCINFO,         {{?cycle,{?uint16,?uint8}}}).
-define(MSG_ID_GUIDE_CSUPDATE,           38003). % 模块更新
-define(MSG_FORMAT_GUIDE_CSUPDATE,       {?uint16}).
-define(MSG_ID_GUIDE_CS_1ST,             38005). % 请求拿钱
-define(MSG_FORMAT_GUIDE_CS_1ST,         {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% guild_siege  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUILD_SIEGE,         40000). % 怪物攻城
-define(MODULE_PACKET_GUILD_SIEGE,       guild_siege_packet). 
-define(MODULE_HANDLER_GUILD_SIEGE,      guild_siege_handler). 

-define(MSG_ID_GUILD_SIEGE_CSENTER,      39001). % 进入怪物攻城
-define(MSG_FORMAT_GUILD_SIEGE_CSENTER,  {?uint32}).
-define(MSG_ID_GUILD_SIEGE_SCENTER,      39002). % 进入怪物攻城
-define(MSG_FORMAT_GUILD_SIEGE_SCENTER,  {?uint32}).
-define(MSG_ID_GUILD_SIEGE_CSEXIT,       39003). % 离开怪物攻城
-define(MSG_FORMAT_GUILD_SIEGE_CSEXIT,   {?uint32}).
-define(MSG_ID_GUILD_SIEGE_SCEXIT,       39004). % 离开怪物攻城
-define(MSG_FORMAT_GUILD_SIEGE_SCEXIT,   {}).
-define(MSG_ID_GUILD_SIEGE_SCON,         39006). % 活动开启
-define(MSG_FORMAT_GUILD_SIEGE_SCON,     {}).
-define(MSG_ID_GUILD_SIEGE_SCOFF,        39008). % 活动结束
-define(MSG_FORMAT_GUILD_SIEGE_SCOFF,    {}).
-define(MSG_ID_GUILD_SIEGE_SCCOUNTDOWN,  39010). % 活动倒计时
-define(MSG_FORMAT_GUILD_SIEGE_SCCOUNTDOWN, {?uint32}).
-define(MSG_ID_GUILD_SIEGE_CSINVITE,     39011). % 邀请好友
-define(MSG_FORMAT_GUILD_SIEGE_CSINVITE, {?uint32,?string}).
-define(MSG_ID_GUILD_SIEGE_SCINFORM,     39014). % 通知好友
-define(MSG_FORMAT_GUILD_SIEGE_SCINFORM, {?uint32,?string,?uint32,?string}).
-define(MSG_ID_GUILD_SIEGE_CSREPLY,      39015). % 好友答复
-define(MSG_FORMAT_GUILD_SIEGE_CSREPLY,  {?uint32,?uint32,?uint8}).
-define(MSG_ID_GUILD_SIEGE_SCTIMEOUT,    39018). % 答复超时
-define(MSG_FORMAT_GUILD_SIEGE_SCTIMEOUT, {?uint32,?string}).
-define(MSG_ID_GUILD_SIEGE_SCREPLY,      39020). % 邀请结果
-define(MSG_FORMAT_GUILD_SIEGE_SCREPLY,  {?uint32,?string,?uint8}).
-define(MSG_ID_GUILD_SIEGE_SCTIMESTAMP,  39022). % 时间戳
-define(MSG_FORMAT_GUILD_SIEGE_SCTIMESTAMP, {?uint32}).
-define(MSG_ID_GUILD_SIEGE_CSMONINFO,    39023). % 怪物信息
-define(MSG_FORMAT_GUILD_SIEGE_CSMONINFO, {}).
-define(MSG_ID_GUILD_SIEGE_SCMONINFO,    39024). % 怪物信息（给玩家）
-define(MSG_FORMAT_GUILD_SIEGE_SCMONINFO, {?uint32,?uint8,{?cycle,{?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_SIEGE_SCMONREFRESH, 39026). % 怪物信息（刷新血量）
-define(MSG_FORMAT_GUILD_SIEGE_SCMONREFRESH, {{?cycle,{?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_SIEGE_CSFRIENDINFO, 39027). % 好友信息
-define(MSG_FORMAT_GUILD_SIEGE_CSFRIENDINFO, {}).
-define(MSG_ID_GUILD_SIEGE_SCFRIENDINFO, 39028). % 好友信息
-define(MSG_FORMAT_GUILD_SIEGE_SCFRIENDINFO, {{?cycle,{?uint32,?string,?uint8}}}).
-define(MSG_ID_GUILD_SIEGE_CSBATTLESTART, 39031). % 开始战斗
-define(MSG_FORMAT_GUILD_SIEGE_CSBATTLESTART, {?uint32}).
-define(MSG_ID_GUILD_SIEGE_SCBATTLEFAIL, 39032). % 发起战斗失败
-define(MSG_FORMAT_GUILD_SIEGE_SCBATTLEFAIL, {?uint8}).
-define(MSG_ID_GUILD_SIEGE_SCBATTLEOVER, 39034). % 战斗结果
-define(MSG_FORMAT_GUILD_SIEGE_SCBATTLEOVER, {?uint8}).
-define(MSG_ID_GUILD_SIEGE_SCMONDIE,     39036). % 怪物死亡
-define(MSG_FORMAT_GUILD_SIEGE_SCMONDIE, {?uint32,?uint32}).
-define(MSG_ID_GUILD_SIEGE_CSRELIEVE,    39037). % 解除玩家死亡状态
-define(MSG_FORMAT_GUILD_SIEGE_CSRELIEVE, {}).
-define(MSG_ID_GUILD_SIEGE_SCMOTIVATE,   39040). % 激发鼓舞
-define(MSG_FORMAT_GUILD_SIEGE_SCMOTIVATE, {?uint32}).
-define(MSG_ID_GUILD_SIEGE_CSENCOURAGE,  39041). % 鼓舞
-define(MSG_FORMAT_GUILD_SIEGE_CSENCOURAGE, {}).
-define(MSG_ID_GUILD_SIEGE_SCHURTDATA,   39050). % 个人伤害值
-define(MSG_FORMAT_GUILD_SIEGE_SCHURTDATA, {?uint32,?uint32}).
-define(MSG_ID_GUILD_SIEGE_SCPLAYERRANK, 39052). % 玩家排行榜数据
-define(MSG_FORMAT_GUILD_SIEGE_SCPLAYERRANK, {{?cycle,{?uint32,?string,?uint32}}}).
-define(MSG_ID_GUILD_SIEGE_SCGUILDRANK,  39054). % 军团积分榜数据
-define(MSG_FORMAT_GUILD_SIEGE_SCGUILDRANK, {{?cycle,{?uint32,?string,?uint32}}}).
-define(MSG_ID_GUILD_SIEGE_SCAWARD,      39062). % 奖励
-define(MSG_FORMAT_GUILD_SIEGE_SCAWARD,  {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% faction  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_FACTION,             41000). % 阵营战
-define(MODULE_PACKET_FACTION,           faction_packet). 
-define(MODULE_HANDLER_FACTION,          faction_handler). 

-define(MSG_ID_FACTION_CS_FIGHT,         40001). % 发起战斗
-define(MSG_FORMAT_FACTION_CS_FIGHT,     {?uint32,?uint8}).
-define(MSG_ID_FACTION_SC_CHANGE_HP,     40002). % 怪物血量变化
-define(MSG_FORMAT_FACTION_SC_CHANGE_HP, {?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% mcopy  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MCOPY,               42000). % 多人副本
-define(MODULE_PACKET_MCOPY,             mcopy_packet). 
-define(MODULE_HANDLER_MCOPY,            mcopy_handler). 

-define(MSG_ID_MCOPY_CS_ENTER,           41001). % 进入副本
-define(MSG_FORMAT_MCOPY_CS_ENTER,       {}).
-define(MSG_ID_MCOPY_ENCOUNTER,          41002). % 返回(创建奇遇物)
-define(MSG_FORMAT_MCOPY_ENCOUNTER,      {?uint32,?uint8}).
-define(MSG_ID_MCOPY_POINT,              41004). % 返回(创建跳转点)
-define(MSG_FORMAT_MCOPY_POINT,          {?uint32}).
-define(MSG_ID_MCOPY_MONSTER,            41006). % 返回(创建怪物)
-define(MSG_FORMAT_MCOPY_MONSTER,        {?uint32,?uint32,?uint16,?uint16}).
-define(MSG_ID_MCOPY_CS_LIST_COPY,       41007). % 请求副本列表
-define(MSG_FORMAT_MCOPY_CS_LIST_COPY,   {}).
-define(MSG_ID_MCOPY_SC_LIST_COPY,       41008). % 副本列表
-define(MSG_FORMAT_MCOPY_SC_LIST_COPY,   {{?cycle,{?uint32}}}).
-define(MSG_ID_MCOPY_SC_BAR,             41010). % 返回(创建栅栏)
-define(MSG_FORMAT_MCOPY_SC_BAR,         {?uint32,?bool}).
-define(MSG_ID_MCOPY_SC_ENTER,           41012). % 进入副本返回
-define(MSG_FORMAT_MCOPY_SC_ENTER,       {?uint8}).
-define(MSG_ID_MCOPY_SC_LEFT_TIMES,      41014). % 剩余次数返回
-define(MSG_FORMAT_MCOPY_SC_LEFT_TIMES,  {?uint8}).
-define(MSG_ID_MCOPY_CS_BATTLE,          41101). % 遇到奇遇
-define(MSG_FORMAT_MCOPY_CS_BATTLE,      {?uint32}).
-define(MSG_ID_MCOPY_CS_NORMAL_BATTLE,   41103). % 发起战斗
-define(MSG_FORMAT_MCOPY_CS_NORMAL_BATTLE, {?uint32}).
-define(MSG_ID_MCOPY_CS_GET_AWARD,       41201). % 领取奖励
-define(MSG_FORMAT_MCOPY_CS_GET_AWARD,   {}).
-define(MSG_ID_MCOPY_SC_AWARD,           41202). % 奖励
-define(MSG_FORMAT_MCOPY_SC_AWARD,       {?uint32,?uint32,?uint8}).
-define(MSG_ID_MCOPY_CS_BUY_TIMES,       41203). % vip购买副本次数
-define(MSG_FORMAT_MCOPY_CS_BUY_TIMES,   {?uint32}).
-define(MSG_ID_MCOPY_CS_EXIT,            41301). % 退出副本
-define(MSG_FORMAT_MCOPY_CS_EXIT,        {?uint8}).
-define(MSG_ID_MCOPY_SC_EXIT,            41302). % 退出副本返回
-define(MSG_FORMAT_MCOPY_SC_EXIT,        {?uint8}).
-define(MSG_ID_MCOPY_CS_ENTER_SKIP,      41401). % 跳转点进入副本
-define(MSG_FORMAT_MCOPY_CS_ENTER_SKIP,  {?uint32}).
-define(MSG_ID_MCOPY_SC_END,             41402). % 奖励返回
-define(MSG_FORMAT_MCOPY_SC_END,         {?uint16,?bool,{?cycle,{?uint32,?uint8}},?uint8,?uint32,?uint32,?uint16,?uint32,?uint32,?uint32}).
-define(MSG_ID_MCOPY_SC_BUFF,            41404). % 返回buff信息
-define(MSG_FORMAT_MCOPY_SC_BUFF,        {{?cycle,{?uint8,?uint8}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% ai  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_AI,                  43000). % 战斗进阶
-define(MODULE_PACKET_AI,                ai_packet). 
-define(MODULE_HANDLER_AI,               ai_handler). 

-define(MSG_ID_AI_CS_END,                42001). % ai播放结束
-define(MSG_FORMAT_AI_CS_END,            {}).
-define(MSG_ID_AI_SC_START,              42002). % ai开始播放(冒泡、动画、特效等)
-define(MSG_FORMAT_AI_SC_START,          {?uint16,?uint8}).
-define(MSG_ID_AI_SC_UNIT_JOIN,          42004). % 角色加入
-define(MSG_FORMAT_AI_SC_UNIT_JOIN,      {?uint16,?uint8,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16}}}).
-define(MSG_ID_AI_SC_UNIT_QUIT,          42006). % 角色离开
-define(MSG_FORMAT_AI_SC_UNIT_QUIT,      {?uint16,?uint8,?uint8,{?cycle,{?uint8}}}).
-define(MSG_ID_AI_SC_BATTLE_ROUND,       42008). % 车轮战轮数
-define(MSG_FORMAT_AI_SC_BATTLE_ROUND,   {?uint16,?uint8}).
-define(MSG_ID_AI_SC_HP_ANGER_CHANGE,    42010). % ai生命怒气变化
-define(MSG_FORMAT_AI_SC_HP_ANGER_CHANGE, {?uint16,?uint8,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint32,?uint32}}}).
-define(MSG_ID_AI_SC_ATTR_CHANGE,        42012). % ai战斗属性变化
-define(MSG_FORMAT_AI_SC_ATTR_CHANGE,    {?uint16,?uint8,?uint8,{?cycle,{?uint8,?uint8,?uint8,?uint16}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% arena_pvp  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ARENA_PVP,           45000). % 多人竞技场
-define(MODULE_PACKET_ARENA_PVP,         arena_pvp_packet). 
-define(MODULE_HANDLER_ARENA_PVP,        arena_pvp_handler). 

-define(MSG_ID_ARENA_PVP_ENTER,          44001). % 打开组队确认
-define(MSG_FORMAT_ARENA_PVP_ENTER,      {}).
-define(MSG_ID_ARENA_PVP_SC_ENTER,       44002). % 进入玩法返回
-define(MSG_FORMAT_ARENA_PVP_SC_ENTER,   {?uint32}).
-define(MSG_ID_ARENA_PVP_CS_ENTER_DATA,  44003). % 请求战群雄信息
-define(MSG_FORMAT_ARENA_PVP_CS_ENTER_DATA, {}).
-define(MSG_ID_ARENA_PVP_START,          44005). % 队长开始
-define(MSG_FORMAT_ARENA_PVP_START,      {}).
-define(MSG_ID_ARENA_PVP_CS_TIGER,       44009). % 请求更新虎符值
-define(MSG_FORMAT_ARENA_PVP_CS_TIGER,   {}).
-define(MSG_ID_ARENA_PVP_SC_TIGER,       44010). % 更新虎符值
-define(MSG_FORMAT_ARENA_PVP_SC_TIGER,   {?uint32}).
-define(MSG_ID_ARENA_PVP_EXCHANGE,       44011). % 兑换物品
-define(MSG_FORMAT_ARENA_PVP_EXCHANGE,   {?uint32,?uint8}).
-define(MSG_ID_ARENA_PVP_CANCEL,         44013). % 取消开始
-define(MSG_FORMAT_ARENA_PVP_CANCEL,     {}).
-define(MSG_ID_ARENA_PVP_CS_REWARD,      44017). % 请求结束奖励
-define(MSG_FORMAT_ARENA_PVP_CS_REWARD,  {}).
-define(MSG_ID_ARENA_PVP_SC_REWARD,      44018). % 结束奖励
-define(MSG_FORMAT_ARENA_PVP_SC_REWARD,  {?uint8,?uint8,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_ARENA_PVP_SC_DATA,        44020). % 群雄数据
-define(MSG_FORMAT_ARENA_PVP_SC_DATA,    {?uint8,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8}).
-define(MSG_ID_ARENA_PVP_CS_AUTO,        44021). % 是否自动准备
-define(MSG_FORMAT_ARENA_PVP_CS_AUTO,    {?uint8,?uint8}).
-define(MSG_ID_ARENA_PVP_SC_AUTO,        44022). % 是否自动准备
-define(MSG_FORMAT_ARENA_PVP_SC_AUTO,    {?uint8,?uint8}).
-define(MSG_ID_ARENA_PVP_CS_AUTO_DATA,   44023). % 请求自动信息
-define(MSG_FORMAT_ARENA_PVP_CS_AUTO_DATA, {}).
-define(MSG_ID_ARENA_PVP_SC_WEEK_REWARD, 44102). % 每周奖励
-define(MSG_FORMAT_ARENA_PVP_SC_WEEK_REWARD, {?uint32,?uint32,?uint32,{?cycle,{?uint32,?uint8,?uint8}}}).
-define(MSG_ID_ARENA_PVP_END_TIMES_NOTICE, 44104). % 结束次数不足提示
-define(MSG_FORMAT_ARENA_PVP_END_TIMES_NOTICE, {?uint8}).
-define(MSG_ID_ARENA_PVP_CS_RANK_DATA,   44201). % 请求排名数据
-define(MSG_FORMAT_ARENA_PVP_CS_RANK_DATA, {}).
-define(MSG_ID_ARENA_PVP_SC_RANK_DATA,   44202). % 排名数据
-define(MSG_FORMAT_ARENA_PVP_SC_RANK_DATA, {{?cycle,{?uint8,?uint32,?string,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% world  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_WORLD,               45500). % 乱天下
-define(MODULE_PACKET_WORLD,             world_packet). 
-define(MODULE_HANDLER_WORLD,            world_handler). 

-define(MSG_ID_WORLD_CS_ENTER,           45001). % 请求进入乱天下
-define(MSG_FORMAT_WORLD_CS_ENTER,       {}).
-define(MSG_ID_WORLD_CS_EXIT,            45011). % 请求退出乱天下
-define(MSG_FORMAT_WORLD_CS_EXIT,        {}).
-define(MSG_ID_WORLD_CS_AUTO_REVIVE,     45021). % 请求自动复活
-define(MSG_FORMAT_WORLD_CS_AUTO_REVIVE, {}).
-define(MSG_ID_WORLD_CS_BATTLE_START,    45031). % 请求开始战斗
-define(MSG_FORMAT_WORLD_CS_BATTLE_START, {?uint8,?uint32}).
-define(MSG_ID_WORLD_CS_GET_BUFF,        45041). % 请求领取犒赏三军BUFF
-define(MSG_FORMAT_WORLD_CS_GET_BUFF,    {}).
-define(MSG_ID_WORLD_CS_INVITE,          45051). % 发起邀请
-define(MSG_FORMAT_WORLD_CS_INVITE,      {?uint32}).
-define(MSG_ID_WORLD_CS_REPLY,           45061). % 回复邀请
-define(MSG_FORMAT_WORLD_CS_REPLY,       {?uint32,?uint32,?uint8,?uint8}).
-define(MSG_ID_WORLD_CS_DOLL,            45063). % 乱天下替身
-define(MSG_FORMAT_WORLD_CS_DOLL,        {?uint8,?uint8}).
-define(MSG_ID_WORLD_SC_DOLL,            45064). % 乱天下替身
-define(MSG_FORMAT_WORLD_SC_DOLL,        {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_WORLD_SC_ENTER,           45100). % 进入乱天下返回
-define(MSG_FORMAT_WORLD_SC_ENTER,       {?uint8,?uint8,?uint32,?uint32}).
-define(MSG_ID_WORLD_SC_UPDATE_MONSTER,  45110). % 更新怪物通知
-define(MSG_FORMAT_WORLD_SC_UPDATE_MONSTER, {?uint8,{?cycle,{?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_WORLD_SC_REMOVE_MONSTER,  45120). % 移除怪物通知
-define(MSG_FORMAT_WORLD_SC_REMOVE_MONSTER, {?uint32}).
-define(MSG_ID_WORLD_SC_EXIT_CD,         45130). % 退出乱天下冷却时间
-define(MSG_FORMAT_WORLD_SC_EXIT_CD,     {?uint32}).
-define(MSG_ID_WORLD_SC_UPDATE_HURT,     45140). % 个人伤害更新
-define(MSG_FORMAT_WORLD_SC_UPDATE_HURT, {?uint32}).
-define(MSG_ID_WORLD_SC_RANK_GUILD,      45300). % 军团排名通知
-define(MSG_FORMAT_WORLD_SC_RANK_GUILD,  {{?cycle,{?string,?uint8}}}).
-define(MSG_ID_WORLD_SC_RANK_PLAYER,     45310). % 个人排名通知
-define(MSG_FORMAT_WORLD_SC_RANK_PLAYER, {{?cycle,{?string,?uint32}}}).
-define(MSG_ID_WORLD_SC_START,           45320). % 乱天下正式开始
-define(MSG_FORMAT_WORLD_SC_START,       {}).
-define(MSG_ID_WORLD_SC_END,             45330). % 乱天下结束
-define(MSG_FORMAT_WORLD_SC_END,         {}).
-define(MSG_ID_WORLD_SC_BUFF_NOTICE,     45340). % 乱天下犒赏三军通知
-define(MSG_FORMAT_WORLD_SC_BUFF_NOTICE, {?uint8}).
-define(MSG_ID_WORLD_SC_BUFF_INFO,       45342). % 角色犒赏三军信息
-define(MSG_FORMAT_WORLD_SC_BUFF_INFO,   {?uint8}).
-define(MSG_ID_WORLD_SC_INVITE_NOTICE,   45350). % 邀请通知
-define(MSG_FORMAT_WORLD_SC_INVITE_NOTICE, {?uint32,?string,?uint8,?uint32,?string}).
-define(MSG_ID_WORLD_SC_NEXT_MONSTER_NOTICE, 45360). % 下一波刷怪通知
-define(MSG_FORMAT_WORLD_SC_NEXT_MONSTER_NOTICE, {?uint8,?uint8}).
-define(MSG_ID_WORLD_SC_LEADER_NOTICE,   45370). % 战斗结束军团长通知
-define(MSG_FORMAT_WORLD_SC_LEADER_NOTICE, {?uint8}).
-define(MSG_ID_WORLD_REWARD_INFO,        45380). % 奖励信息
-define(MSG_FORMAT_WORLD_REWARD_INFO,    {?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% party  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PARTY,               46000). % 宴会
-define(MODULE_PACKET_PARTY,             party_packet). 
-define(MODULE_HANDLER_PARTY,            party_handler). 

-define(MSG_ID_PARTY_CS_ENTER,           45501). % 进入军团宴会
-define(MSG_FORMAT_PARTY_CS_ENTER,       {}).
-define(MSG_ID_PARTY_CS_QUIT,            45503). % 退出宴会
-define(MSG_FORMAT_PARTY_CS_QUIT,        {}).
-define(MSG_ID_PARTY_SC_TIME,            45504). % 宴会时间
-define(MSG_FORMAT_PARTY_SC_TIME,        {?uint32,?uint32}).
-define(MSG_ID_PARTY_SC_PLAY_TIME,       45506). % 玩法时间
-define(MSG_FORMAT_PARTY_SC_PLAY_TIME,   {?uint8,?uint32}).
-define(MSG_ID_PARTY_SC_PLAY_START,      45508). % 玩法开始
-define(MSG_FORMAT_PARTY_SC_PLAY_START,  {?uint8}).
-define(MSG_ID_PARTY_SC_REWARD,          45510). % 收益
-define(MSG_FORMAT_PARTY_SC_REWARD,      {?uint8,?uint32}).
-define(MSG_ID_PARTY_CS_GET_SP,          45511). % 请求获得体力
-define(MSG_FORMAT_PARTY_CS_GET_SP,      {}).
-define(MSG_ID_PARTY_SC_SP_TIME,         45512). % 体力累计时间
-define(MSG_FORMAT_PARTY_SC_SP_TIME,     {?uint8}).
-define(MSG_ID_PARTY_SC_BOX_DATA,        45520). % 更新宝箱信息
-define(MSG_FORMAT_PARTY_SC_BOX_DATA,    {{?cycle,{?uint8,?uint8,?uint16,?uint16}}}).
-define(MSG_ID_PARTY_CS_OPEN_BOX,        45521). % 打开宝箱
-define(MSG_FORMAT_PARTY_CS_OPEN_BOX,    {?uint8}).
-define(MSG_ID_PARTY_SC_REMOVE_BOX,      45522). % 移除宝箱
-define(MSG_FORMAT_PARTY_SC_REMOVE_BOX,  {?uint8}).
-define(MSG_ID_PARTY_SC_MONSTER_DATA,    45524). % 更新怪物信息
-define(MSG_FORMAT_PARTY_SC_MONSTER_DATA, {?uint8,?uint32,?uint16,?uint16,?uint32,?uint32,?uint8}).
-define(MSG_ID_PARTY_CS_BATTLE_START,    45525). % 击杀怪物
-define(MSG_FORMAT_PARTY_CS_BATTLE_START, {?uint8}).
-define(MSG_ID_PARTY_SC_REMOVE_MONSTER,  45526). % 移除怪物
-define(MSG_FORMAT_PARTY_SC_REMOVE_MONSTER, {?uint8}).
-define(MSG_ID_PARTY_SC_END_REWARD,      45530). % 宴会结束奖励通知
-define(MSG_FORMAT_PARTY_SC_END_REWARD,  {?uint32,?uint32,?uint8,?uint32}).
-define(MSG_ID_PARTY_SC_NOTICE,          45540). % 事件提示
-define(MSG_FORMAT_PARTY_SC_NOTICE,      {?uint8,?string,{?cycle,{?uint32}}}).
-define(MSG_ID_PARTY_SC_AUTO_REWARD,     45550). % 自动参宴奖励提示
-define(MSG_FORMAT_PARTY_SC_AUTO_REWARD, {?uint32,?uint8}).
-define(MSG_ID_PARTY_CS_AUTO_PK,         45561). % 设置自动pk
-define(MSG_FORMAT_PARTY_CS_AUTO_PK,     {?uint8}).
-define(MSG_ID_PARTY_SC_AUTO_PK,         45562). % 设置自动pk
-define(MSG_FORMAT_PARTY_SC_AUTO_PK,     {?uint8}).
-define(MSG_ID_PARTY_CS_APPLY_PK,        45563). % 发起pk邀请
-define(MSG_FORMAT_PARTY_CS_APPLY_PK,    {?uint32}).
-define(MSG_ID_PARTY_SC_APPLY_PK,        45564). % 发起pk邀请
-define(MSG_FORMAT_PARTY_SC_APPLY_PK,    {?uint32,?string}).
-define(MSG_ID_PARTY_CS_REPLY_PK,        45565). % 回复pk邀请
-define(MSG_FORMAT_PARTY_CS_REPLY_PK,    {?uint8,?uint32}).
-define(MSG_ID_PARTY_CS_DOLL,            45567). % 宴会替身
-define(MSG_FORMAT_PARTY_CS_DOLL,        {?uint8,?uint8}).
-define(MSG_ID_PARTY_SC_DOLL,            45568). % 宴会替身
-define(MSG_FORMAT_PARTY_SC_DOLL,        {{?cycle,{?uint8,?uint8}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% new_serv  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_NEW_SERV,            46500). % 新服活动
-define(MODULE_PACKET_NEW_SERV,          new_serv_packet). 
-define(MODULE_HANDLER_NEW_SERV,         new_serv_handler). 

-define(MSG_ID_NEW_SERV_CS_ACHIEVE,      46001). % 请求达成目标信息
-define(MSG_FORMAT_NEW_SERV_CS_ACHIEVE,  {}).
-define(MSG_ID_NEW_SERV_SC_ACHIEVE,      46002). % 已达成目标
-define(MSG_FORMAT_NEW_SERV_SC_ACHIEVE,  {?uint16,?bool,?uint8,?uint32}).
-define(MSG_ID_NEW_SERV_CS_ACHIEVE_RECEIVE, 46003). % 领取成就奖励
-define(MSG_FORMAT_NEW_SERV_CS_ACHIEVE_RECEIVE, {?uint16}).
-define(MSG_ID_NEW_SERV_SC_ACHIEVE_RECEIVE, 46004). % 领取成就奖励
-define(MSG_FORMAT_NEW_SERV_SC_ACHIEVE_RECEIVE, {?uint16}).
-define(MSG_ID_NEW_SERV_CS_RANK,         46005). % 新服排名奖
-define(MSG_FORMAT_NEW_SERV_CS_RANK,     {?uint8}).
-define(MSG_ID_NEW_SERV_SC_RANK,         46006). % 新服排名奖
-define(MSG_FORMAT_NEW_SERV_SC_RANK,     {?uint8,{?cycle,{?string}},{?cycle,{?string}},{?cycle,{?string}},?uint32,?uint32,?uint32}).
-define(MSG_ID_NEW_SERV_CS_STORAGE_INFO, 46007). % 生财宝箱信息
-define(MSG_FORMAT_NEW_SERV_CS_STORAGE_INFO, {}).
-define(MSG_ID_NEW_SERV_SC_STORAGE_INFO, 46008). % 生财宝箱信息
-define(MSG_FORMAT_NEW_SERV_SC_STORAGE_INFO, {?uint32,?uint32}).
-define(MSG_ID_NEW_SERV_CS_STORAGE,      46009). % 存钱
-define(MSG_FORMAT_NEW_SERV_CS_STORAGE,  {}).
-define(MSG_ID_NEW_SERV_CS_DRAW_STORAGE, 46011). % 领取每日元宝
-define(MSG_FORMAT_NEW_SERV_CS_DRAW_STORAGE, {}).
-define(MSG_ID_NEW_SERV_CS_END_TIME,     46013). % 活动剩余时间
-define(MSG_FORMAT_NEW_SERV_CS_END_TIME, {?uint8}).
-define(MSG_ID_NEW_SERV_SC_END_TIME,     46014). % 活动剩余时间
-define(MSG_FORMAT_NEW_SERV_SC_END_TIME, {?uint8,?uint32}).
-define(MSG_ID_NEW_SERV_CS_HERO_RANK,    46015). % 英雄榜前三甲排名
-define(MSG_FORMAT_NEW_SERV_CS_HERO_RANK, {}).
-define(MSG_ID_NEW_SERV_SC_HERO_RANK,    46016). % 英雄榜
-define(MSG_FORMAT_NEW_SERV_SC_HERO_RANK, {{?cycle,{?uint16,?string,?uint8,?uint8,?uint8,?uint8,?uint8,?string}}}).
-define(MSG_ID_NEW_SERV_CS_DEPOSIT_REWARD, 46017). % 充值返利
-define(MSG_FORMAT_NEW_SERV_CS_DEPOSIT_REWARD, {}).
-define(MSG_ID_NEW_SERV_SC_DEPOSIT_REWARD, 46018). % 充值返利
-define(MSG_FORMAT_NEW_SERV_SC_DEPOSIT_REWARD, {?uint32}).
-define(MSG_ID_NEW_SERV_CS_HONOR_PLAYER_INFO, 46019). % 请求荣誉榜玩家信息
-define(MSG_FORMAT_NEW_SERV_CS_HONOR_PLAYER_INFO, {}).
-define(MSG_ID_NEW_SERV_SC_HONOR_PLAYER_INFO, 46020). % 荣誉榜玩家信息
-define(MSG_FORMAT_NEW_SERV_SC_HONOR_PLAYER_INFO, {{?cycle,{?uint8,?uint32,?string,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_NEW_SERV_SC_TRAVELL_TIMES, 46100). % 可转次数
-define(MSG_FORMAT_NEW_SERV_SC_TRAVELL_TIMES, {?uint32}).
-define(MSG_ID_NEW_SERV_CS_TURN,         46101). % 转盘抽奖
-define(MSG_FORMAT_NEW_SERV_CS_TURN,     {?uint8}).
-define(MSG_ID_NEW_SERV_SC_TARGET,       46102). % 目标
-define(MSG_FORMAT_NEW_SERV_SC_TARGET,   {?uint8}).
-define(MSG_ID_NEW_SERV_CS_SEND,         46103). % 发协议
-define(MSG_FORMAT_NEW_SERV_CS_SEND,     {}).
-define(MSG_ID_NEW_SERV_SC_REPLY,        46104). % 到背包
-define(MSG_FORMAT_NEW_SERV_SC_REPLY,    {?uint8}).
-define(MSG_ID_NEW_SERV_CS_EXCHANGE_CASH, 46105). % 现金兑换
-define(MSG_FORMAT_NEW_SERV_CS_EXCHANGE_CASH, {?string,?string,?string,?string,?string}).
-define(MSG_ID_NEW_SERV_CS_EXCHANGE_GOODS, 46107). % 实物兑换
-define(MSG_FORMAT_NEW_SERV_CS_EXCHANGE_GOODS, {?string,?string,?string,?string}).
-define(MSG_ID_NEW_SERV_CS_EXCHANGE_INFO, 46109). % 请求获奖名单
-define(MSG_FORMAT_NEW_SERV_CS_EXCHANGE_INFO, {}).
-define(MSG_ID_NEW_SERV_SC_EXCHANGE_INFO, 46110). % 返回获奖名单
-define(MSG_FORMAT_NEW_SERV_SC_EXCHANGE_INFO, {{?cycle,{?uint16,?string,?uint8,?uint32}}}).
-define(MSG_ID_NEW_SERV_SC_TOTAL_SHOW,   46112). % 转盘所得
-define(MSG_FORMAT_NEW_SERV_SC_TOTAL_SHOW, {{?cycle,{?uint8,?uint32}}}).
-define(MSG_ID_NEW_SERV_CS_TURN_GROUP_ID, 46113). % 请求转盘物品的组别
-define(MSG_FORMAT_NEW_SERV_CS_TURN_GROUP_ID, {}).
-define(MSG_ID_NEW_SERV_SC_TURN_GROUP_ID, 46114). % 返回转盘物品的组别
-define(MSG_FORMAT_NEW_SERV_SC_TURN_GROUP_ID, {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% camp_pvp  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CAMP_PVP,            47000). % 阵营战
-define(MODULE_PACKET_CAMP_PVP,          camp_pvp_packet). 
-define(MODULE_HANDLER_CAMP_PVP,         camp_pvp_handler). 

-define(MSG_ID_CAMP_PVP_CS_ENTER,        46501). % 请求进入阵营战
-define(MSG_FORMAT_CAMP_PVP_CS_ENTER,    {}).
-define(MSG_ID_CAMP_PVP_CS_DIG_RECOURCE, 46502). % 采集资源
-define(MSG_FORMAT_CAMP_PVP_CS_DIG_RECOURCE, {?uint8}).
-define(MSG_ID_CAMP_PVP_CS_SUBMIT_RECOURCE, 46503). % 提交资源
-define(MSG_FORMAT_CAMP_PVP_CS_SUBMIT_RECOURCE, {}).
-define(MSG_ID_CAMP_PVP_CS_BATTLE,       46504). % 发起战斗
-define(MSG_FORMAT_CAMP_PVP_CS_BATTLE,   {?uint8,?uint32}).
-define(MSG_ID_CAMP_PVP_CS_EXIT,         46505). % 退出阵营战
-define(MSG_FORMAT_CAMP_PVP_CS_EXIT,     {}).
-define(MSG_ID_CAMP_PVP_CS_CAMP_INFO,    46506). % 请求阵营战信息
-define(MSG_FORMAT_CAMP_PVP_CS_CAMP_INFO, {}).
-define(MSG_ID_CAMP_PVP_CS_CHANGE_STATE, 46507). % 请求改变状态
-define(MSG_FORMAT_CAMP_PVP_CS_CHANGE_STATE, {}).
-define(MSG_ID_CAMP_PVP_GIVE_UP_MINING,  46508). % 放弃采集
-define(MSG_FORMAT_CAMP_PVP_GIVE_UP_MINING, {}).
-define(MSG_ID_CAMP_PVP_BATTLE_OVER_JUMP, 46509). % 战斗结束请求跳地图
-define(MSG_FORMAT_CAMP_PVP_BATTLE_OVER_JUMP, {}).
-define(MSG_ID_CAMP_PVP_MAP_INIT_FINISH, 46510). % 地图初始化完成
-define(MSG_FORMAT_CAMP_PVP_MAP_INIT_FINISH, {?uint32}).
-define(MSG_ID_CAMP_PVP_ENCOURAGE,       46511). % 请求鼓舞
-define(MSG_FORMAT_CAMP_PVP_ENCOURAGE,   {}).
-define(MSG_ID_CAMP_PVP_CS_ATT_CAR,      46512). % 请求打车
-define(MSG_FORMAT_CAMP_PVP_CS_ATT_CAR,  {?uint32}).
-define(MSG_ID_CAMP_PVP_GIVE_UP_ATT_CAR, 46513). % 放弃攻击战车
-define(MSG_FORMAT_CAMP_PVP_GIVE_UP_ATT_CAR, {}).
-define(MSG_ID_CAMP_PVP_BUY_ITEM,        46514). % 请求兑换物品
-define(MSG_FORMAT_CAMP_PVP_BUY_ITEM,    {?uint32,?uint32}).
-define(MSG_ID_CAMP_PVP_REQUEST_SCORE,   46515). % 请求积分
-define(MSG_FORMAT_CAMP_PVP_REQUEST_SCORE, {}).
-define(MSG_ID_CAMP_PVP_CREATE_TEAM,     46516). % 创建队伍
-define(MSG_FORMAT_CAMP_PVP_CREATE_TEAM, {}).
-define(MSG_ID_CAMP_PVP_LEAVE_TEAM,      46517). % 离开队伍
-define(MSG_FORMAT_CAMP_PVP_LEAVE_TEAM,  {}).
-define(MSG_ID_CAMP_PVP_INVITE,          46518). % 邀请
-define(MSG_FORMAT_CAMP_PVP_INVITE,      {?uint32}).
-define(MSG_ID_CAMP_PVP_KICK,            46519). % 踢人
-define(MSG_FORMAT_CAMP_PVP_KICK,        {?uint32}).
-define(MSG_ID_CAMP_PVP_OPEN_CASH,       46520). % 请求开宝箱
-define(MSG_FORMAT_CAMP_PVP_OPEN_CASH,   {?uint8}).
-define(MSG_ID_CAMP_PVP_OPEN_CASH_FINISH, 46521). % 开宝箱结束
-define(MSG_FORMAT_CAMP_PVP_OPEN_CASH_FINISH, {?uint8}).
-define(MSG_ID_CAMP_PVP_SC_ENTER,        46601). % 进入阵营战成功
-define(MSG_FORMAT_CAMP_PVP_SC_ENTER,    {?uint8}).
-define(MSG_ID_CAMP_PVP_SC_RANK,         46602). % 排行榜数据广播
-define(MSG_FORMAT_CAMP_PVP_SC_RANK,     {?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,{?cycle,{?string,?uint32,?uint8,?uint32}},{?cycle,{?string,?uint8,?uint8,?uint32}},{?cycle,{?uint8,?uint8,?uint32}},?uint32,?uint32,?uint32}).
-define(MSG_ID_CAMP_PVP_SC_DIG_SUCCESS,  46603). % 开始采集资源
-define(MSG_FORMAT_CAMP_PVP_SC_DIG_SUCCESS, {?uint32,?uint32}).
-define(MSG_ID_CAMP_PVP_SC_START,        46604). % 活动开始
-define(MSG_FORMAT_CAMP_PVP_SC_START,    {}).
-define(MSG_ID_CAMP_PVP_SC_END,          46605). % 活动结束
-define(MSG_FORMAT_CAMP_PVP_SC_END,      {{?cycle,{?string,?uint32,?uint32,?uint8,?string}},?uint32,?bool,?bool,?uint32,?uint32,?uint32,?uint32,?uint32,?uint8,?uint8,?uint8,?string,?uint32}).
-define(MSG_ID_CAMP_PVP_ADD_MONSTER,     46606). % 加怪物
-define(MSG_FORMAT_CAMP_PVP_ADD_MONSTER, {?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_CAMP_PVP_MONSTER_MOVE,    46607). % 怪物开始移动
-define(MSG_FORMAT_CAMP_PVP_MONSTER_MOVE, {?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_CAMP_PVP_MONSTER_STOP,    46608). % 怪物停止移动
-define(MSG_FORMAT_CAMP_PVP_MONSTER_STOP, {?uint32}).
-define(MSG_ID_CAMP_PVP_MONSTER_KILLED,  46609). % 怪物被杀死
-define(MSG_FORMAT_CAMP_PVP_MONSTER_KILLED, {?uint32}).
-define(MSG_ID_CAMP_PVP_MONSTER_ATTACK,  46610). % 怪物攻击buffnpc
-define(MSG_FORMAT_CAMP_PVP_MONSTER_ATTACK, {?uint32}).
-define(MSG_ID_CAMP_PVP_SC_CAMP_INFO,    46611). % 请求阵营战信息返回
-define(MSG_FORMAT_CAMP_PVP_SC_CAMP_INFO, {{?cycle,{?uint8,?uint8,?uint32,?uint8,{?cycle,{?uint8,?uint8,?uint8}}}},?uint32,?uint8,?uint8}).
-define(MSG_ID_CAMP_PVP_SC_MONSTER_INFO, 46612). % 交战区怪物信息
-define(MSG_FORMAT_CAMP_PVP_SC_MONSTER_INFO, {{?cycle,{?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?bool,?uint8,?uint32,?uint32}}}).
-define(MSG_ID_CAMP_PVP_PLAYER_STATE,    46613). % 广播玩家状态
-define(MSG_FORMAT_CAMP_PVP_PLAYER_STATE, {?uint32,?uint8}).
-define(MSG_ID_CAMP_PVP_PLAYER_STATE_LIST, 46614). % 玩家状态广播组
-define(MSG_FORMAT_CAMP_PVP_PLAYER_STATE_LIST, {{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_CAMP_PVP_BUFF_MISS,       46615). % buff怪挂了，buff消失
-define(MSG_FORMAT_CAMP_PVP_BUFF_MISS,   {?uint32,?uint8,?uint8,?uint8,?uint32}).
-define(MSG_ID_CAMP_PVP_HURT_ALL_BOSS,   46617). % 雷霆一击
-define(MSG_FORMAT_CAMP_PVP_HURT_ALL_BOSS, {?uint8,{?cycle,{?uint32}}}).
-define(MSG_ID_CAMP_PVP_HP_CHANGE,       46618). % 血量变化通知
-define(MSG_FORMAT_CAMP_PVP_HP_CHANGE,   {{?cycle,{?uint8,?uint32,?uint32,?uint32,?uint8,?uint32,?uint16,?uint16,?uint32}}}).
-define(MSG_ID_CAMP_PVP_IS_BATTLE_START, 46619). % 发起战斗是否成功
-define(MSG_FORMAT_CAMP_PVP_IS_BATTLE_START, {?bool}).
-define(MSG_ID_CAMP_PVP_ENTER_CD,        46620). % 大演武冷却时间
-define(MSG_FORMAT_CAMP_PVP_ENTER_CD,    {?uint32}).
-define(MSG_ID_CAMP_PVP_CALL_MONSTER,    46621). % 召唤怪
-define(MSG_FORMAT_CAMP_PVP_CALL_MONSTER, {}).
-define(MSG_ID_CAMP_PVP_ECOURAGE_SUCCESS, 46622). % 鼓舞成功
-define(MSG_FORMAT_CAMP_PVP_ECOURAGE_SUCCESS, {?uint8}).
-define(MSG_ID_CAMP_PVP_ATT_CAR_SUCCESS, 46623). % 攻击战车成功进入读秒
-define(MSG_FORMAT_CAMP_PVP_ATT_CAR_SUCCESS, {}).
-define(MSG_ID_CAMP_PVP_RESPONSE_SCORE,  46624). % 返回当前积分
-define(MSG_FORMAT_CAMP_PVP_RESPONSE_SCORE, {?uint32}).
-define(MSG_ID_CAMP_PVP_BROAD_TEAM_INFO, 46625). % 广播队伍信息
-define(MSG_FORMAT_CAMP_PVP_BROAD_TEAM_INFO, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint16,?uint16,?uint32}},?uint32}).
-define(MSG_ID_CAMP_PVP_TEAM_OVER,       46626). % 队伍解散
-define(MSG_FORMAT_CAMP_PVP_TEAM_OVER,   {}).
-define(MSG_ID_CAMP_PVP_CASH_ACTIVE_START, 46627). % 礼券活动开始
-define(MSG_FORMAT_CAMP_PVP_CASH_ACTIVE_START, {}).
-define(MSG_ID_CAMP_PVP_REFRESH_CASH,    46628). % 刷新宝箱
-define(MSG_FORMAT_CAMP_PVP_REFRESH_CASH, {{?cycle,{?uint8,?uint16,?uint16,?uint32}},?bool}).
-define(MSG_ID_CAMP_PVP_OPEN_CASH_RESULT, 46629). % 请求开宝箱结果
-define(MSG_FORMAT_CAMP_PVP_OPEN_CASH_RESULT, {?bool}).
-define(MSG_ID_CAMP_PVP_REMOVE_CASH_BOX, 46630). % 移除宝箱
-define(MSG_FORMAT_CAMP_PVP_REMOVE_CASH_BOX, {?uint32}).
-define(MSG_ID_CAMP_PVP_BOX_LEFT,        46631). % 可开启宝箱数量
-define(MSG_FORMAT_CAMP_PVP_BOX_LEFT,    {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% weapon  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_WEAPON,              47500). % 神兵系统
-define(MODULE_PACKET_WEAPON,            weapon_packet). 
-define(MODULE_HANDLER_WEAPON,           weapon_handler). 

-define(MSG_ID_WEAPON_CS_WEAPON_ON,      47001). % 装备神兵碎片
-define(MSG_FORMAT_WEAPON_CS_WEAPON_ON,  {?uint8,?uint8}).
-define(MSG_ID_WEAPON_CS_WEAPON_OFF,     47003). % 卸下神兵碎片
-define(MSG_FORMAT_WEAPON_CS_WEAPON_OFF, {?uint8,?uint8}).
-define(MSG_ID_WEAPON_CS_REFRESH,        47005). % 神兵洗炼
-define(MSG_FORMAT_WEAPON_CS_REFRESH,    {?uint8,?uint8,?uint8,{?cycle,{?uint8}}}).
-define(MSG_ID_WEAPON_CS_FREE_REFRESH,   47007). % 神兵免费次数
-define(MSG_FORMAT_WEAPON_CS_FREE_REFRESH, {}).
-define(MSG_ID_WEAPON_SC_FREE_REFRESH,   47008). % 神兵免费洗练次数
-define(MSG_FORMAT_WEAPON_SC_FREE_REFRESH, {?uint8}).
-define(MSG_ID_WEAPON_CS_QUENCH,         47009). % 神兵淬火
-define(MSG_FORMAT_WEAPON_CS_QUENCH,     {?uint8,?uint8,?uint8,?uint8}).
-define(MSG_ID_WEAPON_CS_CHESS_INFO,     47101). % 双陆信息
-define(MSG_FORMAT_WEAPON_CS_CHESS_INFO, {}).
-define(MSG_ID_WEAPON_SC_CHESS_INFO,     47102). % 双陆信息
-define(MSG_FORMAT_WEAPON_SC_CHESS_INFO, {?uint16,?uint32,?uint32,?uint16}).
-define(MSG_ID_WEAPON_CS_CHESS_BUY_DICE, 47103). % 购买骰子
-define(MSG_FORMAT_WEAPON_CS_CHESS_BUY_DICE, {?uint8,?uint32}).
-define(MSG_ID_WEAPON_CS_CHESS_DICE,     47105). % 扔掷骰子
-define(MSG_FORMAT_WEAPON_CS_CHESS_DICE, {?uint8}).
-define(MSG_ID_WEAPON_SC_CHESS_DICE,     47106). % 扔掷骰子
-define(MSG_FORMAT_WEAPON_SC_CHESS_DICE, {?uint8,?uint8}).
-define(MSG_ID_WEAPON_CS_CHESS_CONTROL_DICE, 47107). % 遥控骰子
-define(MSG_FORMAT_WEAPON_CS_CHESS_CONTROL_DICE, {?uint8,?uint8,?uint8}).
-define(MSG_ID_WEAPON_CS_CHESS_FIRST_POS, 47109). % 路过第一个位置
-define(MSG_FORMAT_WEAPON_CS_CHESS_FIRST_POS, {}).
-define(MSG_ID_WEAPON_CLEAR_CHESS_CD,    47111). % 清除cd
-define(MSG_FORMAT_WEAPON_CLEAR_CHESS_CD, {}).
-define(MSG_ID_WEAPON_SC_CLEAR_CHESS_CD, 47112). % 清除cd
-define(MSG_FORMAT_WEAPON_SC_CLEAR_CHESS_CD, {?uint32}).
-define(MSG_ID_WEAPON_SC_CHESS_REWARD,   47114). % 双陆收益
-define(MSG_FORMAT_WEAPON_SC_CHESS_REWARD, {?uint32,?uint32,?uint8,{?cycle,{?uint32,?uint32}}}).
-define(MSG_ID_WEAPON_CS_BUY_PUT_TIMES,  47115). % 购买双陆次数
-define(MSG_FORMAT_WEAPON_CS_BUY_PUT_TIMES, {}).
-define(MSG_ID_WEAPON_SC_BUY_PUT_TIMES,  47116). % 购买双陆次数
-define(MSG_FORMAT_WEAPON_SC_BUY_PUT_TIMES, {?uint16,?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% guild_pvp  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUILD_PVP,           47700). % 军团战
-define(MODULE_PACKET_GUILD_PVP,         guild_pvp_packet). 
-define(MODULE_HANDLER_GUILD_PVP,        guild_pvp_handler). 

-define(MSG_ID_GUILD_PVP_CS_ENTER,       47501). % 请求进入军团战
-define(MSG_FORMAT_GUILD_PVP_CS_ENTER,   {}).
-define(MSG_ID_GUILD_PVP_CS_BATTLE,      47502). % 发起战斗
-define(MSG_FORMAT_GUILD_PVP_CS_BATTLE,  {?uint8,?uint32}).
-define(MSG_ID_GUILD_PVP_CS_EXIT,        47503). % 退出军团战
-define(MSG_FORMAT_GUILD_PVP_CS_EXIT,    {}).
-define(MSG_ID_GUILD_PVP_CS_CHANGE_STATE, 47504). % 请求改变状态
-define(MSG_FORMAT_GUILD_PVP_CS_CHANGE_STATE, {}).
-define(MSG_ID_GUILD_PVP_CS_INIT_MAP_OK, 47505). % 地图初始化完成
-define(MSG_FORMAT_GUILD_PVP_CS_INIT_MAP_OK, {?uint32}).
-define(MSG_ID_GUILD_PVP_CS_ENCOURAGE,   47506). % 请求鼓舞
-define(MSG_FORMAT_GUILD_PVP_CS_ENCOURAGE, {?bool}).
-define(MSG_ID_GUILD_PVP_CS_APP,         47507). % 请求报名军团战
-define(MSG_FORMAT_GUILD_PVP_CS_APP,     {?uint8}).
-define(MSG_ID_GUILD_PVP_CS_GET_APP_INFO, 47508). % 请求军团战报名信息
-define(MSG_FORMAT_GUILD_PVP_CS_GET_APP_INFO, {}).
-define(MSG_ID_GUILD_PVP_CS_ADD_DEF_GUILD, 47509). % 添加防守军团
-define(MSG_FORMAT_GUILD_PVP_CS_ADD_DEF_GUILD, {?uint32}).
-define(MSG_ID_GUILD_PVP_CS_CAR_FIRE,    47510). % 请求战车出击
-define(MSG_FORMAT_GUILD_PVP_CS_CAR_FIRE, {}).
-define(MSG_ID_GUILD_PVP_CS_FIX_WALL,    47511). % 请求修复城门
-define(MSG_FORMAT_GUILD_PVP_CS_FIX_WALL, {}).
-define(MSG_ID_GUILD_PVP_CS_BRING_BACK,  47512). % 请求浴火重生
-define(MSG_FORMAT_GUILD_PVP_CS_BRING_BACK, {?bool}).
-define(MSG_ID_GUILD_PVP_CS_GUILD_WALL_INFO, 47513). % 请求军团战出战信息
-define(MSG_FORMAT_GUILD_PVP_CS_GUILD_WALL_INFO, {}).
-define(MSG_ID_GUILD_PVP_CS_WALL_LIST,   47514). % 请求观察进攻城墙玩家列表
-define(MSG_FORMAT_GUILD_PVP_CS_WALL_LIST, {}).
-define(MSG_ID_GUILD_PVP_CS_ATT_WALL,    47515). % 请求进攻城墙
-define(MSG_FORMAT_GUILD_PVP_CS_ATT_WALL, {}).
-define(MSG_ID_GUILD_PVP_CS_GIVEUP_WALL, 47516). % 放弃观察采集城墙列表
-define(MSG_FORMAT_GUILD_PVP_CS_GIVEUP_WALL, {}).
-define(MSG_ID_GUILD_PVP_CS_APP_LIST,    47517). % 请求军团列表详细信息
-define(MSG_FORMAT_GUILD_PVP_CS_APP_LIST, {}).
-define(MSG_ID_GUILD_PVP_ENTER_INFO,     47518). % 进入战场界面
-define(MSG_FORMAT_GUILD_PVP_ENTER_INFO, {}).
-define(MSG_ID_GUILD_PVP_TOWER_OWNER_INFO, 47519). % 请求军团地图城主信息
-define(MSG_FORMAT_GUILD_PVP_TOWER_OWNER_INFO, {}).
-define(MSG_ID_GUILD_PVP_GUILD_UP_ATT_WALL, 47520). % 放弃采集城墙
-define(MSG_FORMAT_GUILD_PVP_GUILD_UP_ATT_WALL, {}).
-define(MSG_ID_GUILD_PVP_REQUEST_BUG_GUILD_ITEMS, 47521). % 请求购买军团物资
-define(MSG_FORMAT_GUILD_PVP_REQUEST_BUG_GUILD_ITEMS, {?uint32,?uint32,?bool,?uint32,?bool}).
-define(MSG_ID_GUILD_PVP_CS_GUILD_MEMBER_LIST, 47522). % 请求军团成员列表
-define(MSG_FORMAT_GUILD_PVP_CS_GUILD_MEMBER_LIST, {}).
-define(MSG_ID_GUILD_PVP_BROAD_RANK,     47601). % 广播排行榜
-define(MSG_FORMAT_GUILD_PVP_BROAD_RANK, {?uint8,?uint8,?uint8,?uint8,?uint32,{?cycle,{?string,?uint32,?uint32}},?bool,?bool,{?cycle,{?uint32,?string}}}).
-define(MSG_ID_GUILD_PVP_SC_ENCOURAGE,   47602). % 鼓舞成功
-define(MSG_FORMAT_GUILD_PVP_SC_ENCOURAGE, {?uint8,?uint32,?string,?uint8,?uint8}).
-define(MSG_ID_GUILD_PVP_SC_STATE_CHANGE, 47603). % 状态变化广播
-define(MSG_FORMAT_GUILD_PVP_SC_STATE_CHANGE, {{?cycle,{?uint32,?uint32,?uint32,?uint8,?uint16,?bool,?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_PVP_MONSTER_HP,     47604). % 怪物血量变化
-define(MSG_FORMAT_GUILD_PVP_MONSTER_HP, {{?cycle,{?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_PVP_MONSTER_DEAD,   47605). % 怪物死亡
-define(MSG_FORMAT_GUILD_PVP_MONSTER_DEAD, {?uint32}).
-define(MSG_ID_GUILD_PVP_BROAD_END,      47606). % 广播结束包
-define(MSG_FORMAT_GUILD_PVP_BROAD_END,  {?bool,?string,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?bool}).
-define(MSG_ID_GUILD_PVP_APP_INFO,       47607). % 报名面板信息
-define(MSG_FORMAT_GUILD_PVP_APP_INFO,   {?uint8,?string,?uint8,?uint8,?uint8,?bool,?bool,{?cycle,{?string,?string,?uint32,?uint32}}}).
-define(MSG_ID_GUILD_PVP_APP_LIST,       47608). % 申请列表
-define(MSG_FORMAT_GUILD_PVP_APP_LIST,   {?bool,?uint8,{?cycle,{?bool,?uint32,?string,?uint32}},{?cycle,{?uint32,?string,?uint32,?string}}}).
-define(MSG_ID_GUILD_PVP_SC_ENTER_INFO,  47609). % 进入战场界面返回
-define(MSG_FORMAT_GUILD_PVP_SC_ENTER_INFO, {{?cycle,{?uint32,?string,?uint32}},{?cycle,{?uint32,?string,?uint32}}}).
-define(MSG_ID_GUILD_PVP_SC_TOWER_OWNER_INFO, 47610). % 军团城主信息返回
-define(MSG_FORMAT_GUILD_PVP_SC_TOWER_OWNER_INFO, {?string,?bool}).
-define(MSG_ID_GUILD_PVP_SC_ATT_WALL_LIST, 47611). % 广播采集城墙信息
-define(MSG_FORMAT_GUILD_PVP_SC_ATT_WALL_LIST, {{?cycle,{?uint32,?string,?uint32,?uint32}},?bool,?bool}).
-define(MSG_ID_GUILD_PVP_BOSS_STATE,     47612). % boss状态
-define(MSG_FORMAT_GUILD_PVP_BOSS_STATE, {?bool,?bool}).
-define(MSG_ID_GUILD_PVP_ENTER_SUCCESS,  47613). % 进入军团战成功
-define(MSG_FORMAT_GUILD_PVP_ENTER_SUCCESS, {?uint8,?uint32,?uint32}).
-define(MSG_ID_GUILD_PVP_TIME_SYC,       47614). % 时间同步
-define(MSG_FORMAT_GUILD_PVP_TIME_SYC,   {?uint32}).
-define(MSG_ID_GUILD_PVP_MONSTER_INFO,   47615). % 交战区怪物信息
-define(MSG_FORMAT_GUILD_PVP_MONSTER_INFO, {{?cycle,{?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?bool,?uint32,?uint32,?uint32,?uint8}}}).
-define(MSG_ID_GUILD_PVP_MSG_ID_GUILD_PVP_ENTER_CD, 47616). % 冷却时间
-define(MSG_FORMAT_GUILD_PVP_MSG_ID_GUILD_PVP_ENTER_CD, {?uint32}).
-define(MSG_ID_GUILD_PVP_SKILL_CD,       47617). % 技能冷却时间
-define(MSG_FORMAT_GUILD_PVP_SKILL_CD,   {?uint32,?uint32}).
-define(MSG_ID_GUILD_PVP_ANNOUNMENT,     47618). % 军团战滑动公告
-define(MSG_FORMAT_GUILD_PVP_ANNOUNMENT, {?uint8,?string}).
-define(MSG_ID_GUILD_PVP_BRING_BACK_RESULT, 47619). % 浴火重生是否成功
-define(MSG_FORMAT_GUILD_PVP_BRING_BACK_RESULT, {?bool}).
-define(MSG_ID_GUILD_PVP_SC_ATT_WALL_INFO, 47620). % 单挑墙状态信息
-define(MSG_FORMAT_GUILD_PVP_SC_ATT_WALL_INFO, {?uint32,?string,?uint32,?uint32,?bool}).
-define(MSG_ID_GUILD_PVP_MAP_INFO,       47621). % 主程地图信息
-define(MSG_FORMAT_GUILD_PVP_MAP_INFO,   {{?cycle,{?uint32,?uint8,?uint8,?uint8,?uint32,?string,?string}}}).
-define(MSG_ID_GUILD_PVP_GUILD_ITEM_NOT_ENOUGH, 47622). % 物品不足
-define(MSG_FORMAT_GUILD_PVP_GUILD_ITEM_NOT_ENOUGH, {?uint32}).
-define(MSG_ID_GUILD_PVP_SC_GUILD_MEMBER_LIST, 47623). % 军团成员列表
-define(MSG_FORMAT_GUILD_PVP_SC_GUILD_MEMBER_LIST, {{?cycle,{?uint32,?string}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% a  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_A,                   47800). % 待用
-define(MODULE_PACKET_A,                 a_packet). 
-define(MODULE_HANDLER_A,                a_handler). 



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% snow  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_SNOW,                48000). % 雪夜赏灯
-define(MODULE_PACKET_SNOW,              snow_packet). 
-define(MODULE_HANDLER_SNOW,             snow_handler). 

-define(MSG_ID_SNOW_CS_GET_INFO,         47801). % 获取雪夜赏灯的信息
-define(MSG_FORMAT_SNOW_CS_GET_INFO,     {}).
-define(MSG_ID_SNOW_SC_GET_INFO,         47802). % 雪夜赏灯界面信息
-define(MSG_FORMAT_SNOW_SC_GET_INFO,     {?uint32,?uint8,?uint8,?uint8,{?cycle,{?uint8,{?cycle,{?uint8}}}},{?cycle,{?uint8}}}).
-define(MSG_ID_SNOW_CS_CLICK,            47803). % 点灯
-define(MSG_FORMAT_SNOW_CS_CLICK,        {}).
-define(MSG_ID_SNOW_SC_AWARD,            47804). % 抽中的物品
-define(MSG_FORMAT_SNOW_SC_AWARD,        {?uint8,?uint8}).
-define(MSG_ID_SNOW_CS_CLICK_ONEKEY,     47805). % 一键点灯
-define(MSG_FORMAT_SNOW_CS_CLICK_ONEKEY, {}).
-define(MSG_ID_SNOW_CS_STORE_AWARD,      47807). % 获取收集奖励
-define(MSG_FORMAT_SNOW_CS_STORE_AWARD,  {?uint8}).
-define(MSG_ID_SNOW_SC_STORE_AWARD,      47808). % 获取收集奖励返回
-define(MSG_FORMAT_SNOW_SC_STORE_AWARD,  {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% cross  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CROSS,               48999). % 跨服
-define(MODULE_PACKET_CROSS,             cross_packet). 
-define(MODULE_HANDLER_CROSS,            cross_handler). 

-define(MSG_ID_CROSS_CROSS_JUMP,         48001). % 跨服跳转
-define(MSG_FORMAT_CROSS_CROSS_JUMP,     {?string,?uint32,?uint32}).
-define(MSG_ID_CROSS_JUMP_SUCCESS,       48002). % 跳转后socket连接成功
-define(MSG_FORMAT_CROSS_JUMP_SUCCESS,   {?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% yunying_activity  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_YUNYING_ACTIVITY,    49100). % 运营活动
-define(MODULE_PACKET_YUNYING_ACTIVITY,  yunying_activity_packet). 
-define(MODULE_HANDLER_YUNYING_ACTIVITY, yunying_activity_handler). 

-define(MSG_ID_YUNYING_ACTIVITY_REQUEST_DATA, 49001). % 请求获奖信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_REQUEST_DATA, {}).
-define(MSG_ID_YUNYING_ACTIVITY_AWARD_INFO, 49002). % 活动获奖信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_AWARD_INFO, {{?cycle,{?uint32}}}).
-define(MSG_ID_YUNYING_ACTIVITY_ONLINE_START, 49003). % 在线得奖励活动开启通知
-define(MSG_FORMAT_YUNYING_ACTIVITY_ONLINE_START, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SD_INFO, 49004). % 双旦活动获奖信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SD_INFO, {{?cycle,{?uint32}},{?cycle,{?uint32}}}).
-define(MSG_ID_YUNYING_ACTIVITY_REQUEST_SD_DATA, 49005). % 请求双旦活动获奖信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_REQUEST_SD_DATA, {}).
-define(MSG_ID_YUNYING_ACTIVITY_GET_SD_GIFT, 49007). % 双旦活动领取奖励
-define(MSG_FORMAT_YUNYING_ACTIVITY_GET_SD_GIFT, {?uint32,?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_GET_AWARD_SUCC, 49008). % 领取奖励返回
-define(MSG_FORMAT_YUNYING_ACTIVITY_GET_AWARD_SUCC, {?uint32,?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_EXCHANGE, 49009). % 活动—兑换物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_EXCHANGE, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_STONE_INFO, 49011). % 请求宝石合成的信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_STONE_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_STONE_INFO, 49012). % 获取宝石合成的信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_INFO, {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_STONE_AWARD, 49013). % 领取宝石合成的物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_STONE_AWARD, {?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_STONE_AWARD, 49014). % 领取宝石合成物品返回
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_AWARD, {?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_LOTTERY_REQUEST_INFO, 49015). % 打开抽卡界面请求
-define(MSG_FORMAT_YUNYING_ACTIVITY_LOTTERY_REQUEST_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_LAST_LOTTERY_INFO, 49016). % 打开抽卡界面返回
-define(MSG_FORMAT_YUNYING_ACTIVITY_LAST_LOTTERY_INFO, {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_LOTTERY, 49017). % 抽卡
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_LOTTERY, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_LOTTERY_RESULT, 49018). % 抽卡结果返回
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_LOTTERY_RESULT, {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_YUNYING_ACTIVITY_PARTNER_EXCHANGE, 49019). % 兑换武将或物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_PARTNER_EXCHANGE, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_POINT_EXCHANGE, 49021). % 点数兑换
-define(MSG_FORMAT_YUNYING_ACTIVITY_POINT_EXCHANGE, {?uint8,{?cycle,{?uint8,?uint32}}}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_EXCHANGE_INFO, 49023). % 请求武将兑换或点数兑换的界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_EXCHANGE_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_EXCHANGE_INFO, 49024). % 获取武将兑换或点数兑换的界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_EXCHANGE_INFO, {{?cycle,{?uint8,?uint32}},?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_BLESS_INFO, 49025). % 请求祝福界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_BLESS_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_BLESS_INFO, 49026). % 获取祝福界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_INFO, {?uint32,?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_BLESS_VALUE, 49027). % 请求一次祝福
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_BLESS_VALUE, {?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_BLESS_VALUE, 49028). % 获取一次祝福的祝福值
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_VALUE, {?uint32,?uint32,?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_BLESS_GET_AWARD, 49029). % 请求祝福兑换物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_BLESS_GET_AWARD, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_BLESS_GET_AWARD, 49030). % 返回祝福兑换信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_GET_AWARD, {?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_REDBAG_INFO, 49031). % 查询未领红包数量
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_REDBAG_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_REDBAB_NUM, 49032). % 返回未领红包数量
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_REDBAB_NUM, {?uint16}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_GET_REDBAG, 49033). % 领取红包
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_GET_REDBAG, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_REDBAG_OUTPUT, 49034). % 返回开红包得到的物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_REDBAG_OUTPUT, {?uint8,{?cycle,{?uint32,?uint16}}}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_SPRING_EXCHANGE, 49035). % 请求春联兑换活动
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_SPRING_EXCHANGE, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_GET_REDBAG, 49036). % 返回红包领取成功
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_GET_REDBAG, {}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_OPEN_REDBAG, 49037). % 开红包
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_OPEN_REDBAG, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_STONE_VALUE_INFO, 49039). % 请求宝石积分界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_STONE_VALUE_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_STONE_VALUE_INFO, 49040). % 获取宝石积分界面信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_VALUE_INFO, {?uint32}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_STONE_VALUE_GET_AWARD, 49041). % 请求宝石积分兑换物品
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_STONE_VALUE_GET_AWARD, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_INFO, 49042). % 接收灯谜谜面
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_INFO, {?uint16}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_RIDDLE_ANSWER, 49043). % 发送灯谜答案
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_RIDDLE_ANSWER, {?uint16,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_ANSWER, 49044). % 返回回答是否正确
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_ANSWER, {?bool}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_RIDDLE_AWARD_INFO, 49045). % 查询累积答题领奖信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_RIDDLE_AWARD_INFO, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_RIDDLE_AWARD_INFO, 49046). % 返回奖励信息
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_RIDDLE_AWARD_INFO, {?bool,?bool,?bool,?bool,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_TANGYUAN_EXCHANGE, 49047). % 请求汤圆兑换活动
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_TANGYUAN_EXCHANGE, {?uint8,?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_CS_FREE_EXCHANGE, 49051). % 请求神刀免费次数
-define(MSG_FORMAT_YUNYING_ACTIVITY_CS_FREE_EXCHANGE, {}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_FREE_EXCHANGE, 49052). % 返回神刀免费次数
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_FREE_EXCHANGE, {?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SUPER_VIP, 49054). % 返回超级会员资料
-define(MSG_FORMAT_YUNYING_ACTIVITY_SUPER_VIP, {?uint8}).
-define(MSG_ID_YUNYING_ACTIVITY_SC_TIME_INFO, 49090). % 活动时间
-define(MSG_FORMAT_YUNYING_ACTIVITY_SC_TIME_INFO, {{?cycle,{?uint32,?uint32,?uint32}}}).
-define(MSG_ID_YUNYING_ACTIVITY_TIME_INFO, 49091). % 运营活动时间
-define(MSG_FORMAT_YUNYING_ACTIVITY_TIME_INFO, {{?cycle,{?uint32,?uint32,?uint32}},{?cycle,{?uint32,?uint32,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% cross_arena  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CROSS_ARENA,         49200). % 跨服竞技场
-define(MODULE_PACKET_CROSS_ARENA,       cross_arena_packet). 
-define(MODULE_HANDLER_CROSS_ARENA,      cross_arena_handler). 

-define(MSG_ID_CROSS_ARENA_CS_ENTER,     49101). % 打开跨服竞技场界面
-define(MSG_FORMAT_CROSS_ARENA_CS_ENTER, {?uint8}).
-define(MSG_ID_CROSS_ARENA_SC_ENTER,     49102). % 打开跨服竞技场
-define(MSG_FORMAT_CROSS_ARENA_SC_ENTER, {?uint8,?uint32,?uint16,?uint16,?uint32,?uint16,?uint16,?uint8,?uint8,?uint8,?uint8,?uint32,?uint32,?uint8,{?cycle,{?uint32,?uint8}},{?cycle,{?string,?uint32,?string,?uint32,?string,?uint8}}}).
-define(MSG_ID_CROSS_ARENA_CS_START_BATTLE, 49103). % 发起战斗
-define(MSG_FORMAT_CROSS_ARENA_CS_START_BATTLE, {?string,?uint32,?uint32}).
-define(MSG_ID_CROSS_ARENA_REFRESH_GROUP_INFO, 49106). % 更新挑战列表
-define(MSG_FORMAT_CROSS_ARENA_REFRESH_GROUP_INFO, {{?cycle,{?uint32,?uint32,?uint32}}}).
-define(MSG_ID_CROSS_ARENA_REFRESH_MEMBER_INFO, 49108). % 更新战斗信息
-define(MSG_FORMAT_CROSS_ARENA_REFRESH_MEMBER_INFO, {?uint8,?uint32,?uint32,?uint8,?uint8,{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_CROSS_ARENA_CS_TOP_PHASE_INFO, 49109). % 天神榜信息
-define(MSG_FORMAT_CROSS_ARENA_CS_TOP_PHASE_INFO, {}).
-define(MSG_ID_CROSS_ARENA_SC_TOP_PHASE_INFO, 49110). % 段位内成员信息
-define(MSG_FORMAT_CROSS_ARENA_SC_TOP_PHASE_INFO, {?uint8,?uint32,?uint32,{?cycle,{?uint32,?string,?uint32,?string,?uint32,?uint8,?uint8,?uint32,?uint32,{?cycle,{?uint16}}}}}).
-define(MSG_ID_CROSS_ARENA_CS_RANK_AWARD, 49111). % 领取排名奖励
-define(MSG_FORMAT_CROSS_ARENA_CS_RANK_AWARD, {}).
-define(MSG_ID_CROSS_ARENA_SC_RANK_AWARD, 49112). % 领取排名奖励
-define(MSG_FORMAT_CROSS_ARENA_SC_RANK_AWARD, {?uint32}).
-define(MSG_ID_CROSS_ARENA_CS_ACHIEVE,   49113). % 打开成就界面
-define(MSG_FORMAT_CROSS_ARENA_CS_ACHIEVE, {}).
-define(MSG_ID_CROSS_ARENA_SC_ACHIEVE,   49114). % 打开成就界面
-define(MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE, {{?cycle,{?uint32,?uint8}}}).
-define(MSG_ID_CROSS_ARENA_CS_ACHIEVE_REWARD, 49115). % 领取成就奖励
-define(MSG_FORMAT_CROSS_ARENA_CS_ACHIEVE_REWARD, {?uint32}).
-define(MSG_ID_CROSS_ARENA_SC_ACHIEVE_REWARD, 49116). % 领取成就奖励
-define(MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE_REWARD, {?uint32}).
-define(MSG_ID_CROSS_ARENA_CROSS_ARENA_CS_BUY, 49117). % 天神商店购买
-define(MSG_FORMAT_CROSS_ARENA_CROSS_ARENA_CS_BUY, {?uint32,?uint32}).
-define(MSG_ID_CROSS_ARENA_SC_REFRESH_REPORT, 49120). % 战报更新
-define(MSG_FORMAT_CROSS_ARENA_SC_REFRESH_REPORT, {?string,?uint32,?string,?uint32,?string,?uint8}).
-define(MSG_ID_CROSS_ARENA_CS_CROSS_PLAYER_INFO, 49121). % 查看人物详细
-define(MSG_FORMAT_CROSS_ARENA_CS_CROSS_PLAYER_INFO, {?string,?uint32,?uint32}).
-define(MSG_ID_CROSS_ARENA_PARTNER_INFO, 49123). % 查看武将信息
-define(MSG_FORMAT_CROSS_ARENA_PARTNER_INFO, {?string,?uint8,?uint32,?uint16}).
-define(MSG_ID_CROSS_ARENA_CROSS_ARENA_PARTNER, 49125). % 获取武将列表
-define(MSG_FORMAT_CROSS_ARENA_CROSS_ARENA_PARTNER, {?string,?uint8,?uint32}).
-define(MSG_ID_CROSS_ARENA_PARTNER_GROUP, 49130). % 武将协议组
-define(MSG_FORMAT_CROSS_ARENA_PARTNER_GROUP, {{?cycle,{?uint16}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% archery  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ARCHERY,             49300). % 辕门射戟
-define(MODULE_PACKET_ARCHERY,           archery_packet). 
-define(MODULE_HANDLER_ARCHERY,          archery_handler). 

-define(MSG_ID_ARCHERY_GET_SRCEEN,       49201). % 请求界面信息
-define(MSG_FORMAT_ARCHERY_GET_SRCEEN,   {}).
-define(MSG_ID_ARCHERY_SRCEEN_INFO,      49202). % 返回界面信息
-define(MSG_FORMAT_ARCHERY_SRCEEN_INFO,  {?uint8,?uint8,{?cycle,{?uint32,?uint32,?uint8}},?bool,?bool}).
-define(MSG_ID_ARCHERY_ASK_TOP_LIST,     49203). % 请求排行榜信息
-define(MSG_FORMAT_ARCHERY_ASK_TOP_LIST, {}).
-define(MSG_ID_ARCHERY_GET_TOP_LIST,     49204). % 返回排行榜信息
-define(MSG_FORMAT_ARCHERY_GET_TOP_LIST, {{?cycle,{?uint8,?string,?uint32}},?uint16}).
-define(MSG_ID_ARCHERY_CONFIG,           49205). % 配置游戏参数
-define(MSG_FORMAT_ARCHERY_CONFIG,       {?uint16}).
-define(MSG_ID_ARCHERY_SHOOT,            49207). % 射击
-define(MSG_FORMAT_ARCHERY_SHOOT,        {?uint8,?uint16}).
-define(MSG_ID_ARCHERY_RESULT_SHOOT,     49208). % 射击结果
-define(MSG_FORMAT_ARCHERY_RESULT_SHOOT, {{?cycle,{?uint8}}}).
-define(MSG_ID_ARCHERY_ADD_ARROW,        49209). % 增加箭矢
-define(MSG_FORMAT_ARCHERY_ADD_ARROW,    {}).
-define(MSG_ID_ARCHERY_GET_ADD_ARROW,    49210). % 剩余箭矢返回
-define(MSG_FORMAT_ARCHERY_GET_ADD_ARROW, {?uint16,?uint8}).
-define(MSG_ID_ARCHERY_GET_REWORD,       49211). % 领取奖励
-define(MSG_FORMAT_ARCHERY_GET_REWORD,   {}).
-define(MSG_ID_ARCHERY_SC_REWORD,        49212). % 累计奖励
-define(MSG_FORMAT_ARCHERY_SC_REWORD,    {?uint32,?uint16}).
-define(MSG_ID_ARCHERY_REFRESH_COURT,    49213). % 刷新靶场
-define(MSG_FORMAT_ARCHERY_REFRESH_COURT, {}).
-define(MSG_ID_ARCHERY_BCAST_TOP_10,     49216). % 广播排行榜前十
-define(MSG_FORMAT_ARCHERY_BCAST_TOP_10, {{?cycle,{?uint8,?string,?uint32}}}).
-define(MSG_ID_ARCHERY_ADD_REWARD,       49218). % 获得奖励
-define(MSG_FORMAT_ARCHERY_ADD_REWARD,   {?uint8,?uint32,?uint32}).
-define(MSG_ID_ARCHERY_ASK_ARROW,        49219). % 请求箭矢数量
-define(MSG_FORMAT_ARCHERY_ASK_ARROW,    {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% encroach  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_ENCROACH,            49400). % 攻城掠地
-define(MODULE_PACKET_ENCROACH,          encroach_packet). 
-define(MODULE_HANDLER_ENCROACH,         encroach_handler). 

-define(MSG_ID_ENCROACH_CS_INIT_INFO,    49301). % 获取初始化信息
-define(MSG_FORMAT_ENCROACH_CS_INIT_INFO, {}).
-define(MSG_ID_ENCROACH_SC_INIT_INFO,    49302). % 初始化信息
-define(MSG_FORMAT_ENCROACH_SC_INIT_INFO, {{?cycle,{?uint8,?uint8,?uint8}},?uint8,?uint8,?uint32,?uint16,?uint8}).
-define(MSG_ID_ENCROACH_CS_MOVE,         49303). % 移动
-define(MSG_FORMAT_ENCROACH_CS_MOVE,     {?uint8}).
-define(MSG_ID_ENCROACH_SC_MOVE,         49304). % 移动结果
-define(MSG_FORMAT_ENCROACH_SC_MOVE,     {?uint8}).
-define(MSG_ID_ENCROACH_SC_REST_POINT,   49305). % 剩余行动力
-define(MSG_FORMAT_ENCROACH_SC_REST_POINT, {?uint8,?uint8}).
-define(MSG_ID_ENCROACH_SC_EVENT_REWARD, 49306). % 事件奖励
-define(MSG_FORMAT_ENCROACH_SC_EVENT_REWARD, {?uint32,{?cycle,{?uint32,?uint32}}}).
-define(MSG_ID_ENCROACH_CS_RANK_INFO,    49307). % 获取排行榜
-define(MSG_FORMAT_ENCROACH_CS_RANK_INFO, {}).
-define(MSG_ID_ENCROACH_SC_RANK_INFO,    49308). % 排行榜信息
-define(MSG_FORMAT_ENCROACH_SC_RANK_INFO, {{?cycle,{?uint32,?uint8,?string,?uint8,?uint32}}}).
-define(MSG_ID_ENCROACH_CS_RESET,        49309). % 重置玩法
-define(MSG_FORMAT_ENCROACH_CS_RESET,    {}).
-define(MSG_ID_ENCROACH_SC_RESET,        49310). % 重置结果
-define(MSG_FORMAT_ENCROACH_SC_RESET,    {?uint8}).
-define(MSG_ID_ENCROACH_SC_SETTLEMENT,   49311). % 结算
-define(MSG_FORMAT_ENCROACH_SC_SETTLEMENT, {{?cycle,{?uint8,?uint8,?uint8}},{?cycle,{?uint32,?uint32,?uint8}},?uint32,?uint8}).
-define(MSG_ID_ENCROACH_CS_BUY_POINT,    49312). % 购买移动力
-define(MSG_FORMAT_ENCROACH_CS_BUY_POINT, {?uint8}).
-define(MSG_ID_ENCROACH_SC_BUY_POINT,    49313). % 购买移动力结果
-define(MSG_FORMAT_ENCROACH_SC_BUY_POINT, {?uint8}).
-define(MSG_ID_ENCROACH_SC_LOTTERY_TIMES, 49314). % 可抽奖次数
-define(MSG_FORMAT_ENCROACH_SC_LOTTERY_TIMES, {?uint32}).
-define(MSG_ID_ENCROACH_CS_LOTTERY,      49315). % 抽奖
-define(MSG_FORMAT_ENCROACH_CS_LOTTERY,  {}).
-define(MSG_ID_ENCROACH_SC_TARGET,       49316). % 目标
-define(MSG_FORMAT_ENCROACH_SC_TARGET,   {?uint8}).
-define(MSG_ID_ENCROACH_CS_SEND,         49317). % 发协议
-define(MSG_FORMAT_ENCROACH_CS_SEND,     {}).
-define(MSG_ID_ENCROACH_SC_REPLY,        49318). % 到背包
-define(MSG_FORMAT_ENCROACH_SC_REPLY,    {?uint8}).
-define(MSG_ID_ENCROACH_CS_AWARD_GOODS,  49319). % 查看获得物品
-define(MSG_FORMAT_ENCROACH_CS_AWARD_GOODS, {}).
-define(MSG_ID_ENCROACH_SC_AWARD_GOODS,  49320). % 查看获得物品
-define(MSG_FORMAT_ENCROACH_SC_AWARD_GOODS, {{?cycle,{?uint32,?uint32,?uint8}}}).
-define(MSG_ID_ENCROACH_CS_CHK_CAN_MOV,  49321). % 检测是否可移动
-define(MSG_FORMAT_ENCROACH_CS_CHK_CAN_MOV, {?uint8}).
-define(MSG_ID_ENCROACH_SC_CHK_CAN_MOV,  49322). % 检查是否可移动结果
-define(MSG_FORMAT_ENCROACH_SC_CHK_CAN_MOV, {?uint8}).
-define(MSG_ID_ENCROACH_CS_REST_TIMES,   49323). % 获取剩余次数
-define(MSG_FORMAT_ENCROACH_CS_REST_TIMES, {}).
-define(MSG_ID_ENCROACH_SC_REST_TIMES,   49324). % 剩余次数
-define(MSG_FORMAT_ENCROACH_SC_REST_TIMES, {?uint16}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% lantern  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_LANTERN,             49500). % 元宵你妹啊
-define(MODULE_PACKET_LANTERN,           lantern_packet). 
-define(MODULE_HANDLER_LANTERN,          lantern_handler). 

-define(MSG_ID_LANTERN_CS_LEAVE,         49401). % 离开队伍
-define(MSG_FORMAT_LANTERN_CS_LEAVE,     {?uint32}).
-define(MSG_ID_LANTERN_CS_REQ,           49403). % 邀请
-define(MSG_FORMAT_LANTERN_CS_REQ,       {?uint32}).
-define(MSG_ID_LANTERN_CS_T,             49405). % t人
-define(MSG_FORMAT_LANTERN_CS_T,         {?uint32}).
-define(MSG_ID_LANTERN_CS_ENTER,         49407). % 进入副本
-define(MSG_FORMAT_LANTERN_CS_ENTER,     {}).
-define(MSG_ID_LANTERN_SC_TEAM_INFO,     49450). % 队伍信息
-define(MSG_FORMAT_LANTERN_SC_TEAM_INFO, {{?cycle,{?uint32,?uint8,?uint8,?uint8,?uint32,?uint32,?uint32,?uint8}}}).
-define(MSG_ID_LANTERN_SC_COPY_INFO,     49452). % 副本信息
-define(MSG_FORMAT_LANTERN_SC_COPY_INFO, {?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% card21  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_CARD21,              49600). % 21点
-define(MODULE_PACKET_CARD21,            card21_packet). 
-define(MODULE_HANDLER_CARD21,           card21_handler). 

-define(MSG_ID_CARD21_INIT_GAME,         49501). % 请求初始化一局
-define(MSG_FORMAT_CARD21_INIT_GAME,     {?uint32}).
-define(MSG_ID_CARD21_SC_INIT_GAME,      49502). % 当前牌局状态
-define(MSG_FORMAT_CARD21_SC_INIT_GAME,  {{?cycle,{?uint8,?uint8}},{?cycle,{?uint8,?uint8}},?uint8}).
-define(MSG_ID_CARD21_HIT,               49503). % 翻牌
-define(MSG_FORMAT_CARD21_HIT,           {}).
-define(MSG_ID_CARD21_STAND,             49504). % 停牌
-define(MSG_FORMAT_CARD21_STAND,         {}).
-define(MSG_ID_CARD21_REQUEST_CHIP_TOTAL, 49505). % 请求当前筹码数
-define(MSG_FORMAT_CARD21_REQUEST_CHIP_TOTAL, {}).
-define(MSG_ID_CARD21_SC_TOTAL_CHIP,     49506). % 返回当前筹码数
-define(MSG_FORMAT_CARD21_SC_TOTAL_CHIP, {?uint32}).
-define(MSG_ID_CARD21_BUY_CHIP,          49507). % 请求买筹码
-define(MSG_FORMAT_CARD21_BUY_CHIP,      {?uint32}).
-define(MSG_ID_CARD21_SELL_CHIP,         49508). % 请求卖筹码
-define(MSG_FORMAT_CARD21_SELL_CHIP,     {?uint32}).
-define(MSG_ID_CARD21_QUIT,              49509). % 中途退出
-define(MSG_FORMAT_CARD21_QUIT,          {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% gun_cash  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GUN_CASH,            59999). % 滚服礼券
-define(MODULE_PACKET_GUN_CASH,          gun_cash_packet). 
-define(MODULE_HANDLER_GUN_CASH,         gun_cash_handler). 

-define(MSG_ID_GUN_CASH_INFO,            50001). % 滚服信息
-define(MSG_FORMAT_GUN_CASH_INFO,        {?uint8,?uint32,?uint32}).
-define(MSG_ID_GUN_CASH_GET_GUN_CASH,    50002). % 领取滚服礼券
-define(MSG_FORMAT_GUN_CASH_GET_GUN_CASH, {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% teach  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_TEACH,               60299). % 教学
-define(MODULE_PACKET_TEACH,             teach_packet). 
-define(MODULE_HANDLER_TEACH,            teach_handler). 

-define(MSG_ID_TEACH_CS_PROCESS,         60001). % 请求进度
-define(MSG_FORMAT_TEACH_CS_PROCESS,     {}).
-define(MSG_ID_TEACH_SC_PROCESS,         60002). % 进度
-define(MSG_FORMAT_TEACH_SC_PROCESS,     {{?cycle,{?uint8,?uint8,?uint16,?uint8,?uint8}}}).
-define(MSG_ID_TEACH_CS_BATTLE,          60003). % 发起战斗
-define(MSG_FORMAT_TEACH_CS_BATTLE,      {?uint8,?uint16,?uint8,?uint8}).
-define(MSG_ID_TEACH_CS_ANSWER,          60005). % 答题
-define(MSG_FORMAT_TEACH_CS_ANSWER,      {?uint16,?uint8}).
-define(MSG_ID_TEACH_SC_ANSWER,          60006). % 答题结果
-define(MSG_FORMAT_TEACH_SC_ANSWER,      {?uint8}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% mixed_serv  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_MIXED_SERV,          60399). % 合服活动
-define(MODULE_PACKET_MIXED_SERV,        mixed_serv_packet). 
-define(MODULE_HANDLER_MIXED_SERV,       mixed_serv_handler). 

-define(MSG_ID_MIXED_SERV_REQUEST_RANK,  60301). % 请求合服排行榜
-define(MSG_FORMAT_MIXED_SERV_REQUEST_RANK, {?uint8}).
-define(MSG_ID_MIXED_SERV_RANK_LIST,     60302). % 排行榜信息
-define(MSG_FORMAT_MIXED_SERV_RANK_LIST, {?uint8,{?cycle,{?uint32,?string,?uint8,?uint8,?string,?string}},?string}).
-define(MSG_ID_MIXED_SERV_SEE_GIFT,      60303). % 请求合服礼包状态
-define(MSG_FORMAT_MIXED_SERV_SEE_GIFT,  {}).
-define(MSG_ID_MIXED_SERV_A_GIFT,        60304). % 合服礼包状态
-define(MSG_FORMAT_MIXED_SERV_A_GIFT,    {?bool}).
-define(MSG_ID_MIXED_SERV_WANT_GIFT,     60305). % 请求领取合服礼包
-define(MSG_FORMAT_MIXED_SERV_WANT_GIFT, {}).
-define(MSG_ID_MIXED_SERV_SC_WANT_GIFT,  60306). % 领取奖励返回
-define(MSG_FORMAT_MIXED_SERV_SC_WANT_GIFT, {?bool}).
-define(MSG_ID_MIXED_SERV_CS_JOINSER_TIME, 60307). % 请求合服时间
-define(MSG_FORMAT_MIXED_SERV_CS_JOINSER_TIME, {}).
-define(MSG_ID_MIXED_SERV_SC_JOINSER_TIME, 60308). % 合服时间返回
-define(MSG_FORMAT_MIXED_SERV_SC_JOINSER_TIME, {?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% partner_soul  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_PARTNER_SOUL,        62000). % 将魂
-define(MODULE_PACKET_PARTNER_SOUL,      partner_soul_packet). 
-define(MODULE_HANDLER_PARTNER_SOUL,     partner_soul_handler). 

-define(MSG_ID_PARTNER_SOUL_CS_UPGRADE,  61001). % 将魂升级
-define(MSG_FORMAT_PARTNER_SOUL_CS_UPGRADE, {?uint16}).
-define(MSG_ID_PARTNER_SOUL_SC_UPGRADE,  61002). % 将魂升级
-define(MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE, {?uint16,?uint8,?uint32}).
-define(MSG_ID_PARTNER_SOUL_CS_UPGRADE_STAR, 61003). % 将魂星级升级
-define(MSG_FORMAT_PARTNER_SOUL_CS_UPGRADE_STAR, {?uint16}).
-define(MSG_ID_PARTNER_SOUL_SC_UPGRADE_STAR, 61004). % 将魂星级升级
-define(MSG_FORMAT_PARTNER_SOUL_SC_UPGRADE_STAR, {?uint16,?uint8}).
-define(MSG_ID_PARTNER_SOUL_CS_INHERIT,  61005). % 将魂继承
-define(MSG_FORMAT_PARTNER_SOUL_CS_INHERIT, {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SOUL_SC_INHERIT,  61006). % 将魂继承
-define(MSG_FORMAT_PARTNER_SOUL_SC_INHERIT, {?uint16,?uint16}).
-define(MSG_ID_PARTNER_SOUL_CS_INFO,     61007). % 请求将魂信息
-define(MSG_FORMAT_PARTNER_SOUL_CS_INFO, {?uint16}).
-define(MSG_ID_PARTNER_SOUL_SC_INFO,     61008). % 请求将魂信息
-define(MSG_FORMAT_PARTNER_SOUL_SC_INFO, {?uint16,?uint8,?uint32,?uint8}).
-define(MSG_ID_PARTNER_SOUL_CS_ATTR,     61009). % 将魂属性
-define(MSG_FORMAT_PARTNER_SOUL_CS_ATTR, {?uint32,?uint16}).
-define(MSG_ID_PARTNER_SOUL_SC_ATTR,     61010). % 将魂战力
-define(MSG_FORMAT_PARTNER_SOUL_SC_ATTR, {?uint32,?uint16,?uint16,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32,?uint32}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% gamble  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_GAMBLE,              62100). % 青梅煮酒
-define(MODULE_PACKET_GAMBLE,            gamble_packet). 
-define(MODULE_HANDLER_GAMBLE,           gamble_handler). 

-define(MSG_ID_GAMBLE_REQUEST_ROOMS,     62001). % 请求房间信息
-define(MSG_FORMAT_GAMBLE_REQUEST_ROOMS, {}).
-define(MSG_ID_GAMBLE_REPLY_ROOMS_INFO,  62002). % 房间信息
-define(MSG_FORMAT_GAMBLE_REPLY_ROOMS_INFO, {{?cycle,{?uint8,?uint8,?string,?uint8,?uint8,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_GAMBLE_BOOK_NEW_ROOM,     62003). % 请求创建房间
-define(MSG_FORMAT_GAMBLE_BOOK_NEW_ROOM, {?uint32}).
-define(MSG_ID_GAMBLE_REPLY_BOOK,        62004). % 创建房间返回
-define(MSG_FORMAT_GAMBLE_REPLY_BOOK,    {?bool,?uint32,?uint32,?bool,?uint32}).
-define(MSG_ID_GAMBLE_JOIN_ROOM,         62005). % 请求加入房间
-define(MSG_FORMAT_GAMBLE_JOIN_ROOM,     {?uint32,?uint32}).
-define(MSG_ID_GAMBLE_REPLY_JOIN,        62006). % 加入房间返回
-define(MSG_FORMAT_GAMBLE_REPLY_JOIN,    {?bool,?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint8,?uint32,?uint32}).
-define(MSG_ID_GAMBLE_INFORM_JOIN,       62008). % 玩家加入房间推送
-define(MSG_FORMAT_GAMBLE_INFORM_JOIN,   {?uint32,?uint32,?string,?uint8,?uint8}).
-define(MSG_ID_GAMBLE_REQUEST_LEAVE,     62009). % 请求离开房间
-define(MSG_FORMAT_GAMBLE_REQUEST_LEAVE, {?uint32,?uint32}).
-define(MSG_ID_GAMBLE_INFORM_LEAVE,      62010). % 玩家退出房间
-define(MSG_FORMAT_GAMBLE_INFORM_LEAVE,  {?uint32}).
-define(MSG_ID_GAMBLE_REQUEST_READY,     62011). % 请求准备|取消
-define(MSG_FORMAT_GAMBLE_REQUEST_READY, {?uint8,?uint32,?uint32}).
-define(MSG_ID_GAMBLE_INFORM_READY,      62012). % 玩家准备状态推送
-define(MSG_FORMAT_GAMBLE_INFORM_READY,  {?uint8,?uint8}).
-define(MSG_ID_GAMBLE_GAME_START,        62014). % 游戏开始推送
-define(MSG_FORMAT_GAMBLE_GAME_START,    {?uint8}).
-define(MSG_ID_GAMBLE_PLAY_CARD,         62015). % 请求出牌1
-define(MSG_FORMAT_GAMBLE_PLAY_CARD,     {?uint32,?uint32}).
-define(MSG_ID_GAMBLE_INFORM_PLAY,       62016). % 玩家出牌推送
-define(MSG_FORMAT_GAMBLE_INFORM_PLAY,   {?uint8}).
-define(MSG_ID_GAMBLE_PLAY_CARD2,        62017). % 请求出牌2
-define(MSG_FORMAT_GAMBLE_PLAY_CARD2,    {?uint8,?uint32,?uint32}).
-define(MSG_ID_GAMBLE_REPLY_RESULT,      62018). % 本轮结果推送
-define(MSG_FORMAT_GAMBLE_REPLY_RESULT,  {?uint32,?uint8,?bool,?uint8,?uint8}).
-define(MSG_ID_GAMBLE_PLAYER_GIVE_UP,    62019). % 玩家放弃
-define(MSG_FORMAT_GAMBLE_PLAYER_GIVE_UP, {?uint32,?uint32}).
-define(MSG_ID_GAMBLE_INFORM_HISTORY,    62022). % 对战历史推送
-define(MSG_FORMAT_GAMBLE_INFORM_HISTORY, {{?cycle,{?uint8,?uint8}}}).
-define(MSG_ID_GAMBLE_REQUEST_CHIP,      62023). % 查看自己筹码
-define(MSG_FORMAT_GAMBLE_REQUEST_CHIP,  {}).
-define(MSG_ID_GAMBLE_REPLY_CHIP,        62024). % 查看筹码返回
-define(MSG_FORMAT_GAMBLE_REPLY_CHIP,    {?uint32}).
-define(MSG_ID_GAMBLE_EXCHANGE_CHIP,     62025). % 筹码兑成元宝
-define(MSG_FORMAT_GAMBLE_EXCHANGE_CHIP, {?uint32}).
-define(MSG_ID_GAMBLE_GAMBLE_RESULT,     62028). % 每局结果
-define(MSG_FORMAT_GAMBLE_GAMBLE_RESULT, {?uint8,?uint32,?uint32,?uint8}).
-define(MSG_ID_GAMBLE_PLAY_AGAIN,        62029). % 再来一局
-define(MSG_FORMAT_GAMBLE_PLAY_AGAIN,    {?bool,?uint32,?uint32}).
-define(MSG_ID_GAMBLE_EXCHANGE_GOLD,     62031). % 元宝兑换筹码
-define(MSG_FORMAT_GAMBLE_EXCHANGE_GOLD, {?uint32}).
-define(MSG_ID_GAMBLE_LOST_CONN,         62032). % 对方掉线
-define(MSG_FORMAT_GAMBLE_LOST_CONN,     {?uint8}).
-define(MSG_ID_GAMBLE_COME_BACK,         62034). % 对方回来
-define(MSG_FORMAT_GAMBLE_COME_BACK,     {?uint8}).
-define(MSG_ID_GAMBLE_NEED_COMEBACK,     62035). % 是否需要返回游戏
-define(MSG_FORMAT_GAMBLE_NEED_COMEBACK, {?bool}).
-define(MSG_ID_GAMBLE_NEVEREND,          62036). % 有游戏没结束
-define(MSG_FORMAT_GAMBLE_NEVEREND,      {?bool}).
-define(MSG_ID_GAMBLE_NEED_ROOM_BACK,    62038). % 断线重连房间信息
-define(MSG_FORMAT_GAMBLE_NEED_ROOM_BACK, {?uint32,?string,?uint8,?uint8,?uint32,?uint32,?uint32,?uint32}).
-define(MSG_ID_GAMBLE_BEKICKED,          62040). % 被踢出
-define(MSG_FORMAT_GAMBLE_BEKICKED,      {}).
-define(MSG_ID_GAMBLE_CROSS_SERV,        62041). % 跨服匹配
-define(MSG_FORMAT_GAMBLE_CROSS_SERV,    {?bool,?bool,?bool,?bool}).
-define(MSG_ID_GAMBLE_INVITE,            62043). % 邀人打牌
-define(MSG_FORMAT_GAMBLE_INVITE,        {?uint32,?uint32}).
-define(MSG_ID_GAMBLE_OPEN_WINDOW,       62045). % 玩家打开界面
-define(MSG_FORMAT_GAMBLE_OPEN_WINDOW,   {}).
-define(MSG_ID_GAMBLE_CLOSE_WINDOW,      62047). % 玩家关闭界面
-define(MSG_FORMAT_GAMBLE_CLOSE_WINDOW,  {}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% kb_treasure  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_KB_TREASURE,         62199). % 皇陵探宝
-define(MODULE_PACKET_KB_TREASURE,       kb_treasure_packet). 
-define(MODULE_HANDLER_KB_TREASURE,      kb_treasure_handler). 

-define(MSG_ID_KB_TREASURE_CS_TURN,      62101). % 转盘抽奖
-define(MSG_FORMAT_KB_TREASURE_CS_TURN,  {?uint8,?uint8}).
-define(MSG_ID_KB_TREASURE_SC_TARGET,    62102). % 目标
-define(MSG_FORMAT_KB_TREASURE_SC_TARGET, {?uint8}).
-define(MSG_ID_KB_TREASURE_CS_SEND,      62103). % 发协议
-define(MSG_FORMAT_KB_TREASURE_CS_SEND,  {}).
-define(MSG_ID_KB_TREASURE_SC_REPLY,     62104). % 到背包
-define(MSG_FORMAT_KB_TREASURE_SC_REPLY, {?uint8}).
-define(MSG_ID_KB_TREASURE_CS_GET_GROUP, 62105). % 获取组别
-define(MSG_FORMAT_KB_TREASURE_CS_GET_GROUP, {?uint8}).
-define(MSG_ID_KB_TREASURE_SC_GROUP_RESULT, 62106). % 返回组别
-define(MSG_FORMAT_KB_TREASURE_SC_GROUP_RESULT, {?uint8,?uint8}).
-define(MSG_ID_KB_TREASURE_SC_TOTAL,     62108). % 转盘所得
-define(MSG_FORMAT_KB_TREASURE_SC_TOTAL, {{?cycle,{?uint8,?uint32}}}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% hundred_serv  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_HUNDRED_SERV,        62299). % 百服庆典
-define(MODULE_PACKET_HUNDRED_SERV,      hundred_serv_packet). 
-define(MODULE_HANDLER_HUNDRED_SERV,     hundred_serv_handler). 

-define(MSG_ID_HUNDRED_SERV_REQUEST_RANK, 62201). % 请求充值排行榜
-define(MSG_FORMAT_HUNDRED_SERV_REQUEST_RANK, {}).
-define(MSG_ID_HUNDRED_SERV_REPLY_RANK,  62202). % 排行榜信息
-define(MSG_FORMAT_HUNDRED_SERV_REPLY_RANK, {{?cycle,{?uint32,?string,?uint8,?uint8,?uint32}},?uint32}).
-define(MSG_ID_HUNDRED_SERV_INFORM_OPEN, 62204). % 通知百服活动是否开启
-define(MSG_FORMAT_HUNDRED_SERV_INFORM_OPEN, {?bool,?bool}).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% limit_mall  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
-define(MODULE_TAIL_LIMIT_MALL,          63399). % 限购商城
-define(MODULE_PACKET_LIMIT_MALL,        limit_mall_packet). 
-define(MODULE_HANDLER_LIMIT_MALL,       limit_mall_handler). 

-define(MSG_ID_LIMIT_MALL_REQUEST_MALL,  63301). % 请求商城界面
-define(MSG_FORMAT_LIMIT_MALL_REQUEST_MALL, {}).
-define(MSG_ID_LIMIT_MALL_MALL_GOODS,    63302). % 商城物品信息
-define(MSG_FORMAT_LIMIT_MALL_MALL_GOODS, {{?cycle,{?uint32,?uint32,?uint32,?uint32}}}).
-define(MSG_ID_LIMIT_MALL_OPEN_DOOR,     63304). % 限购商城开启
-define(MSG_FORMAT_LIMIT_MALL_OPEN_DOOR, {?bool,?uint32}).
-define(MSG_ID_LIMIT_MALL_BUY,           63305). % 购买
-define(MSG_FORMAT_LIMIT_MALL_BUY,       {?uint32,?uint32}).
-define(MSG_ID_LIMIT_MALL_RECEIPT,       63306). % 购买反馈
-define(MSG_FORMAT_LIMIT_MALL_RECEIPT,   {?uint32,?uint8}).


