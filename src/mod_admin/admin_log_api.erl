%% Author: Administrator
%% Created: 2012-10-13
%% Description: 玩家行为日志(主要部分通过平台接口分析)
%% !!!重点记录的日志
-module(admin_log_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.task.hrl").
-include("record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([get_user_account/1, is_first/3, log_ability_camp/5, 
         log_boss/10, log_camp_battle/6, log_campaign/5, log_chat/3,
         log_chat_clc_heart/0, log_bless/3,
         log_currency/7, log_currency/8, log_deposit/6, log_furnace/6,
         log_goods/5, log_goods/6,log_rank/7,log_patrol/4,log_mcopy/3,
         log_goods/11, log_goods/12, log_guild_operate/9, 
         log_level_up/1, log_login/2, log_logout/3,
		 log_mall/6, log_market/8, log_mind/6, log_login_check/3,
         log_partner/6, log_player/5, log_player_create/1,log_reconnect/3,
         log_single_arena/7, log_skill_learn_active/4, 
         log_task/3, log_task/5, log_tower/2, user_info/1,
         log_mail/15, log_transpoint/8, log_stren/4, log_soul/8,
		 log_chess/4, log_robot/6, log_world/6,log_market_get/3,
		 log_link/4,  log_shop_secret/7, log_login_req/12
		, log_gamble/8
		, log_snow/3]).
-export([get_tab_name/1]).
%%
%% API Functions
%%

%% %% 空字符串''
%% test(UserId) ->
%% 	{UserLv, _Vip, ServId, Time} = user_info(UserId),
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p",
%% 				[0, UserId, ServId, UserLv, Time]).
%% 
%% %%测试登录
%% log_login_debug(UserId, Type, Ip) ->
%% 	{UserLv, _Vip, ServId, Time} = user_info(UserId),
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~ts,,,",
%% 			  	[?CONST_LOG_USER, UserId, ServId, UserLv, Time, Type, misc:to_list(Ip)]).

%% !!! 所有Player参数，传入UserId也可以，但会多出通过ETS查询信息，尽量使用Player
%% 优先级 1从Player传递参数  2查ETS 3查数据库

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	聊天
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 游戏缩写|服务器代号|平台帐号|玩家角色|玩家 IP|聊天内容
log_chat(Player, Channel, ContentBinary) ->
	ServId		= "S" ++ misc:to_list(Player#player.serv_id),
	Account		= misc:to_list(Player#player.account),
	UserName	= misc:to_list((Player#player.info)#info.user_name),
	IP	 		= misc:to_list(Player#player.ip),
	Content		= misc:to_list(ContentBinary),
	Time		= misc:seconds(),
	?MSG_CHAT("~p|~ts|~ts|~ts|~ts|~ts|~p|~p", [wwsg, ServId, Account, UserName, IP, Content, Channel, Time]).

%% 游戏缩写|服务器代号|test|test|test|test
log_chat_clc_heart() ->
	ServId		= "S" ++ misc:to_list(config:read_deep([server, base, sid])),
	IP	 		= misc:to_list(<<"0.0.0.0">>),
	?MSG_CHAT("~p|~ts|~p|~p|~ts|~p", [wwsg, ServId, test, test, IP, test]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	人物!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 人物行为
log_player(Player, Type, Sort, Value, Other) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_USER, UserId, ServId, UserLv, Time, Type, Sort, Value, Other]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	武将!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 武将
log_partner(Player, PartnerId, Operate, CostGold, Cash, Type) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_PARTNER, UserId, ServId, UserLv, Time, PartnerId, Operate, CostGold, Cash, Type]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	双陆
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Type|Times|LeftTimes
%% 0减1加|加减次数|剩余次数
log_chess(Player, Type, Times, LeftTimes) ->
	{UserId, _UserLv, Vip, ServId, Time, _Account} = user_info(Player),
	VipLv			= Vip#vip.lv,
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_CHESS, UserId, ServId, VipLv, Time, Type, Times, LeftTimes]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	奇门、阵法
%% 玩家id|服务器id|玩家等级|时间|操作|id|新等级|历练
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 内功阵法
log_ability_camp(Player, Operate, Id, Lv, Exp) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_ABILITY_CAMP, UserId, ServId, UserLv, Time, Operate, Id, Lv, Exp]). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	作坊!!!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%作坊
log_furnace(Player, Operate, CostType, Cost, EquipId, EquipId2) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_FURNACE, UserId, ServId, UserLv, Time, Operate, CostType, Cost, EquipId, EquipId2]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	军团
%% 玩家id|服务器id|玩家等级|时间|军团id|操作类型|操作参数|物品id|物品数量|技能类型|技能等级|花费
%% UserId|ServId|UserLv|Time|GuildId|Operate|OtherId|GoodsId|Num|SkillType|SkillLv|Cost
%% 操作类型：	
%%              1 -> 申请 		2 -> 取消申请		
%%              4 -> 邀请 		5 -> 拒绝邀请		6 -> 同意邀请
%%              7 -> 退出 		8 -> 踢出			9 -> 解散
%%              10 -> 创建 		11 -> 同意申请		12 -> 拒绝申请

%%              13 -> 更换团长	14 -> 提升职位		15 -> 解除职位
%%				16 -> 弹劾团长

%%              21 -> 铜钱捐献 	22 -> 元宝捐献	
%%              31 -> 技能升级  	32 -> 术法升级
%%              41 -> 百宝购买  	42 -> 分配物品

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团操作  admin_log_api:log_guild_operate(Player, GuildId, Operate, 0, 0, 0, 0, 0, 0).
log_guild_operate(Player, GuildId, Operate, OtherId, GoodsId, Num, SkillType, SkillLv, Cost) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_GUILD, UserId, ServId, UserLv, Time, GuildId, Operate, OtherId, GoodsId, Num, SkillType, SkillLv, Cost]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	拍卖!!!
%% 玩家id|玩家帐号|服务器id|操作类型|流水id|物品id|物品数量|竞拍价|一口价|时间|卖家Id
%% UserId|Account|ServId  |Op     |MarketId|GoodsId|GoodsCount|MarketPrice|OncePrice|Time|SellerId
%% 操作类型：0 -> 放上去拍卖
%%                1 -> 拍卖成功(竞拍得到 -> 一口价为0;一口价得到 -> 竞拍价为0)
%%                2 -> 拍卖失败(竞拍价、一口价都为0)
%% 例如：
%% 类型|竞拍价|一口价|         说明
%% 0        1         2            放上去拍卖，竞拍价1，一口价2
%% 1        1         0            拍卖成功，竞拍得到，成交价1
%% 1        0         2            拍卖成功，一口价得到，成交价2
%% 2        0         0            拍卖失败
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 拍卖 
log_market(Player, Op, MarketId, GoodsId, GoodsCount, MarketPrice, OncePrice, SellerId) ->
	{UserId, _UserLv, _Vip, ServId, _Time, Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_MARKET, UserId, misc:to_list(Account), ServId, Op, MarketId, GoodsId, GoodsCount,
				 MarketPrice, OncePrice, misc:seconds(), SellerId]).

log_market_get(UserId, MarketId, GoodsId) ->
	{UserId, _UserLv, _Vip, ServId, _Time, Account} = user_info(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p", [?CONST_LOG_MARKET_GET, UserId, misc:to_list(Account), ServId, MarketId, GoodsId]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	商城!!!   
%% 玩家ID	玩家账号	商城类型	货币类型	货币值	物品ID	物品数量	时间戳
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%商城购买道具
log_mall(Player, GoodsId, GoodsNum, MoneyType, Cost, Time) ->
	{UserId, _UserLv, _Vip, ServId, Time, Account} = user_info(Player),
	ShopType = 1,
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_MALL, UserId, misc:to_list(Account), ServId, MoneyType, Cost, GoodsId, GoodsNum, Time, ShopType]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	任务!!!
%% 玩家ID|玩家账号|职业|等级|任务ID|任务状态|时间戳
%% UserId|Account|Pro|Sex|TaskId|Status|Time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_task(Player, TaskId, Status) when is_record(Player, player) ->
	log_task(Player#player.user_id, Player#player.account, Player#player.info, TaskId, Status);
log_task(UserId, TaskId, Status) when is_number(UserId) ->
	case player_api:get_player_fields(UserId, [#player.account, #player.info]) of
		{?ok, [Account, Info]} when is_record(Info, info) ->
			log_task(UserId, Account, Info, TaskId, Status);
		_ -> ?ok
	end;
log_task(_, _TaskId, _Status) ->
	?ok.

log_task(UserId, Account, Info, TaskId, Status) ->
	Pro		= Info#info.pro,
	Lv		= Info#info.lv,
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p",
				[?CONST_LOG_TASK, UserId, misc:to_list(Account), Pro, Lv, TaskId, Status, misc:seconds()]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 一骑讨
%% 总日志     玩家id,帐号,玩家等级,旧排名,新排名,连胜次数,对手,主动?,次数,时间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 一骑讨
log_single_arena(Player, OldRank, NewRank, NewWins, AtkUserId, IsActive, NewTimes) ->
	{UserId, UserLv, _Vip, ServId, Time, Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p", 
				[?CONST_LOG_SIG_ARENA, UserId, misc:to_list(Account), ServId, UserLv, 
                 OldRank, NewRank, NewWins, AtkUserId, IsActive, NewTimes, Time]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	心法
%% 玩家ID|服务器ID|角色等级|时间戳|心法ID|操作类型|心法旧等级|心法新等级|缺省
%% UserId|ServId|UserLv|Time|MindId|Operate|FromLv|ToLv|Cost
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 心法 
log_mind(Player, MindId, Operate, FromLv, ToLv, Cost) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_MIND, UserId, ServId, UserLv, Time, MindId, Operate, FromLv, ToLv, Cost]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	巡城
%% 玩家ID|服务器ID|角色等级|时间戳|消费类型|消费总额|获得功勋
%% UserId|ServId|UserLv|Time|MinusType|MinusAmount|Meritorious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_patrol(Player, MinusType, MinusAmount, Meritorious) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_PATROL, UserId, ServId, UserLv, Time, MinusType, MinusAmount, Meritorious]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	技能   
%% 玩家id|帐号|玩家等级|时间|技能id|技能旧等级|技能新等级|技能点变化值|新技能点
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%技能/学习主动技能
log_skill_learn_active(Player, SkillId, SkillLv, SkillPoint) ->
	{UserId, UserLv, _Vip, _ServId, Time, Account} = user_info(Player),
    SkillPointCur = player_api:get_skill_point(Player),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_SKILL, UserId, misc:to_list(Account), UserLv, Time, SkillId, SkillLv-1, SkillLv, SkillPoint, SkillPointCur]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	闯塔
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 闯塔
%% Times
%% 剩余重置次数
log_tower(Player, Times) ->
	{UserId, UserLv, Vip, ServId, Time, Account} = user_info(Player),
	VipLv		= Vip#vip.lv,
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_TOWER, UserId, misc:to_list(Account), UserLv, ServId, Time, 0, 0, VipLv, Times]). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	祝福
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 祝福
log_bless(_Player, _Operate, _Times) -> ?ok.
%% 	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p",
%% 				[?CONST_LOG_COMMERCE, UserId, ServId, UserLv, Time, Operate, Times]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	boss战
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% BOSS战
%% Type 1替身在线奖励2普通在线奖励3替身上线奖励4普通上线奖励
%%Idx 排名 Hurt总伤害 HGold伤害铜钱 HMeritorious伤害功勋 HExperience伤害历练
%%RGold排名铜钱 RMeritorious排名功勋RExperience排名历练
log_boss(Player,  Type, Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p, ~p",
				[?CONST_LOG_BOSS, UserId, ServId, UserLv, Time, Type, Idx, Hurt, HGold, HMeritorious, HExperience, RGold, RMeritorious, RExperience]).

%% 多人副本
%% 副本系列id|进入次数
%% McopyId|Times
log_mcopy(Player, McopyId, Times) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_MCOPY, UserId, ServId, UserLv, Time, McopyId, Times]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 强化
%% 总日志     玩家id,帐号,玩家等级,部位,旧值,新值,时间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 强化
log_stren(Player, Part, OldValue, NewValue) ->
    {UserId, UserLv, _Vip, ServId, Time, Account} = user_info(Player),
    ?MSG_PLAYER("~p,~p,~p,~ts,~p,~p,~p,~p,~p", 
                [?CONST_LOG_STREN, UserId, ServId, misc:to_list(Account), UserLv, 
                 Part, OldValue, NewValue, Time]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	排行榜
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%Type排行榜类型|Num排名|UserId玩家id|UserNmae玩家昵称|lv玩家等级
%%OtherId军团id或武将id或坐骑id
log_rank(Type,Num,UserId,_UserName,Lv,OtherId,_OtherName) ->
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p", [?CONST_LOG_RANK, Type, Num, UserId, Lv, OtherId, misc:seconds()]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	刻印
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ctnFrom:输出方装备所在容器 1背包 4玩家 5伙伴 ||PartnerFrom:输出方武将ID||IndexFrom:输出方装备的容器位置
%% CtnTo:接收方附魂装备所在容器 1背包 4玩家 5伙伴||PartnerTo:接收方附魂武将ID||IndexTo:接收方附魂装备的容器位置
%% SoulFromList:输出方附魂列表 || SoulToList:接收方附魂列表
log_soul(Player, CtnFrom, PartnerFrom, IndexFrom, CtnTo, PartnerTo, IndexTo, Cost) ->	
	{UserId, _UserLv, _Vip, ServId, Time, _Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_SOUL, UserId, ServId, Time, CtnFrom, PartnerFrom, IndexFrom, CtnTo, PartnerTo, 
				 IndexTo, Cost]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc  机器人扣费
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_robot(Player, BossId, Cost, Type, LeftCost, CostType) ->	
	{UserId, UserLv, _Vip, ServId, Time, Account} = user_info(Player),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_ROBOT_COST, UserId, misc:to_list(Account), ServId, Time, UserLv, BossId, Cost, Type, LeftCost, CostType]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	充值
%% @name	log_deposit/6
%% @param	UserId		玩家ID
%% @param	Money		充值金额
%% @param	Cash		获得元宝
%% @param	Ip			IP
%% @param	Methord		充值途径
%% @return	ok
%% @Type    1=金币，2=绑定金币，3=铜币，4=绑定铜币
%% @Opt		1=增加，2=减少
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 充值 (离线操作)
log_deposit(Account, UserId, Money, Cash, Methord, Time) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{lv = Lv, country = Country, pro = Pro}} ->
			?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~w,~p,~p",
						[?CONST_LOG_RECHARGE, UserId, Account, Lv, Country, Pro, 0, 0, Methord, Money, Cash, Time]);
		_ -> ?ok
	end.
%% 	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
%% 				[?CONST_LOG_CASH, UserId, Account, UserLv, Country, Pro, 0, 0, Type, Cash, Opt, Act1, Act2, GoodsNum, Time]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   货币产出消耗日志接口
%% @name   log_currency/8
%% @param  UserId		玩家ID
%% @param  Type			1产出(加钱) 2消耗(扣钱)
%% @param  Module		系统ID
%% @param  Fun			功能ID
%% @param  Value		消耗数量
%% @param  MoneyType	1=金币，2=绑定金币，3=铜币，4=绑定铜币
%% @return ok
%% 玩家ID|玩家账号|等级|是否首次消费|货币类型|货币改变值|最新货币|操作类型|消费点|时间戳
%% UserId|Account|Lv|IsFirst|MoneyType|Value|ValueNew|Type|Point|Time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_currency(_Player, _IsFirst, _Type, _Point, 0, _ValueNew, _MoneyType) -> ?CONST_SYS_TRUE;
log_currency(Player, _IsFirst, Type, Point, Value, ValueNew, MoneyType) when is_record(Player, player) ->
	log_currency(Player#player.user_id, Player#player.account, Player#player.info, _IsFirst, Type, Point, Value, ValueNew, MoneyType);
log_currency(Player, IsFirst, Type, Point, Value, ValueNew, MoneyType) ->
	?MSG_ERROR("log_currency(UserId, IsFirst, Type, Point, Value, ValueNew, MoneyType)~nARGS:~p", [{Player, IsFirst, Type, Point, Value, ValueNew, MoneyType}]),
	?CONST_SYS_TRUE.

log_currency(UserId, Account, IsFirst, Type, Point, Value, ValueNew, MoneyType) when is_integer(UserId) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, Info} -> log_currency(UserId, Account, Info, IsFirst, Type, Point, Value, ValueNew, MoneyType);
		_ -> ?CONST_SYS_TRUE
	end;
log_currency(UserId, Account, IsFirst, Type, Point, Value, ValueNew, MoneyType) ->
	?MSG_ERROR("log_currency(UserId, IsFirst, Type, Point, Value, ValueNew, MoneyType)~nARGS:~p", [{UserId, Account, IsFirst, Type, Point, Value, ValueNew, MoneyType}]),
	?CONST_SYS_TRUE.

log_currency(UserId, Account, Info, _IsFirst, Type, Point, Value, ValueNew, MoneyType) when is_record(Info, info) ->
	Lv				= Info#info.lv,
	IsFirst			= is_first(UserId, MoneyType, Type),
	ServId			= get_user_server(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_CURRENCY, UserId, misc:to_list(Account), ServId, Lv, IsFirst, MoneyType, Value, ValueNew, Type, Point, misc:seconds()]),
	case IsFirst of ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE; ?CONST_SYS_TRUE -> ?CONST_SYS_TRUE end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   玩法活动参与日志接口  玩家ID，平台帐号，玩家等级，参与的活动（系统）ID，时间
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_campaign(UserId, Account, Lv, CampaignId, Time) ->
	ServId		= get_user_server(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p",
				[?CONST_LOG_CAMPAIGN, UserId, misc:to_list(Account), Lv, CampaignId, Time, ServId]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 培养点
%% 玩家id|帐号|玩家等级|变化值1|新值1|变化值2|新值2|变化值3|新值3|武将id
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_transpoint(Player, Value1, ValueNew1, Valu2, ValueNew2, Valu3, ValueNew3, PartnerId) ->
	{UserId, Lv, _Vip, ServId, _Time, Account} = user_info(Player),
    ?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p",
                [?CONST_LOG_TRAINS_POINT, UserId, misc:to_list(Account), ServId, Lv,
                 Value1, ValueNew1, Valu2, ValueNew2, Valu3, ValueNew3, misc:seconds(), PartnerId]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 乱天下
%% 玩家id|帐号|玩家等级|
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_world(UserId, Hurt, KillCount, Exploit, Gold, Robot) ->
	{UserId, Lv, Vip, ServId, Time, Account} = user_info(UserId),
	VipLv			= Vip#vip.lv,
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_WORLD, UserId, misc:to_list(Account), ServId, Lv, VipLv, Time, Hurt, KillCount, Exploit, Gold, Robot]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 乱天下
%% 玩家id|帐号|玩家等级|
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_link(Time,Link,Ret,Success)->
	?MSG_PLAYER("~p,~p,~p,~p",[?CONST_LOG_LINK,Time,Link,Ret,Success]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   道具消耗日志接口
%% @name   log_goods/8
%% @param  UserId		玩家ID
%% @param  Pos			1 是获得，0 是使用
%% @param  Point		消耗点
%% @param  Goodsid		道具ID
%% @param  Num			道具数量
%% @param  Time			UNIX时间戳
%% 玩家ID|玩家账号|获得or使用|操作点|物品ID|物品数量|时间戳|参数1|参数2|参数3|参数4|参数5
%% UserId|Account|Pos|Point|GoodsId|Num|Time|arg1|arg2|arg3|arg4|arg5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_goods(UserId, Pos, Point, GoodsId, Num, Time) ->
    log_goods(UserId, Pos, Point, GoodsId, Num, Time, 0, 0, 0, 0, 0, 0).
log_goods(UserId, Pos, Point, List, Time) when is_list(List) ->
    log_goods(UserId, Pos, Point, List, Time, 0, 0, 0, 0, 0, 0);
log_goods(UserId, Pos, Point, Goods, Time) ->
    log_goods(UserId, Pos, Point, Goods, Time, 0, 0, 0, 0, 0, 0).
log_goods(UserId, Pos, Point, GoodsId, Num, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) ->
	Account = get_user_account(UserId),
	ServId	= get_user_server(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_GOODS, UserId, misc:to_list(Account), Pos, Point, GoodsId, Num, Time, ServId, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6]).
log_goods(UserId, Pos, Point, [Goods|T], Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) when is_record(Goods, goods) ->
	log_goods(UserId, Pos, Point, Goods#goods.goods_id, Goods#goods.count, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6),
	log_goods(UserId, Pos, Point, T, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6);
log_goods(UserId, Pos, Point, Goods, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) when is_record(Goods, goods) ->
	log_goods(UserId, Pos, Point, Goods#goods.goods_id, Goods#goods.count, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6);
log_goods(UserId, Pos, Point, [Goods|T], Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) when is_record(Goods, mini_goods) ->
	log_goods(UserId, Pos, Point, Goods#mini_goods.goods_id, Goods#mini_goods.count, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6),
	log_goods(UserId, Pos, Point, T, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6);
log_goods(UserId, Pos, Point, Goods, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6) when is_record(Goods, mini_goods) ->
	log_goods(UserId, Pos, Point, Goods#mini_goods.goods_id, Goods#mini_goods.count, Time, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6);
log_goods(_UserId, _Pos, _Point, [], _Time, _Arg1, _Arg2, _Arg3, _Arg4, _Arg5, _Arg6) -> ?ok.

%% 创建角色
log_player_create(Player) ->
	UserId	= Player#player.user_id,
	Account = Player#player.account,
	Info 	= Player#player.info,
	Time	= misc:seconds(),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p",
				[?CONST_LOG_USER_CREATE, UserId, misc:to_list(Account), Info#info.pro, Info#info.country, Time]),
	log_login(Player, ?CONST_SYS_TRUE).	%创建角色也统计在登录的范畴内

%% 登录日志
log_login(Player, ?CONST_SYS_TRUE) when is_record(Player, player) ->
	UserId	= Player#player.user_id,
	Account = Player#player.account,
    Info    = Player#player.info,
	LoginLv	= Info#info.lv,
	ServId	= Player#player.serv_id,
    MapData = Player#player.maps,
    CurMapInfo = MapData#map_data.cur,
    MapId   = CurMapInfo#map_info.map_id,
    Ip      = Player#player.ip,
	Time	= misc:seconds(),
	?MSG_PLAYER("~p,~p,~ts,~p,~ts,~p,~p,~p", [?CONST_LOG_LOGIN, UserId, misc:to_list(Account), LoginLv, misc:to_list(Ip), MapId, Time, ServId]),
	Player#player{logs_tmp = {Time, LoginLv}};
log_login(Player, ?CONST_SYS_TRUE) ->
	?MSG_ERROR("log_login fail for bad record player ~p", [Player]),
	Player;
log_login(Player, ?CONST_SYS_FALSE) -> 
	Player.

%% 重连日志
%%Reason:重连失败原因|Times重连次数
log_reconnect(UserId, Reason, Times) ->
	{UserId, _UserLv, _Vip, ServId, Time, Account} = user_info(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p", [?CONST_LOG_RECONNECT, UserId, misc:to_list(Account), ServId, Time, Reason, Times]).

%% 登陆(校验)
%% State:状态|LogoutTimeLast:最后退出时间
log_login_check(UserId, State, LogoutTimeLast) ->
	{UserId, _UserLv, _Vip, ServId, _Time, Account} = user_info(UserId),
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p", [?CONST_LOG_LOGIN_CHECK, UserId, misc:to_list(Account), ServId, State, LogoutTimeLast]).

%% 登出日志
%% 玩家ID|平台帐号|登录时间|退出时间|在线时长|登录等级|退出等级|任务ID|地图ID|IP
%% UserId|Account|LoginTime|LogoutTime|Time|LoginLv|LogoutLv|TaskId|MapId|IP
log_logout(Player, LogoutTime, Reason) when is_record(Player, player) ->
	UserId		= Player#player.user_id,
	Account 	= Player#player.account,
	LogoutReason= case Reason of
					  ?normal -> 1;
					  {error,socket_timeout}  -> 2;
					  {error,reconnect_timeout} -> 3;
					  "kick"  -> 4;
						_ -> 5
				  end,
	case Player#player.logs_tmp of
		{LoginTime, LoginLv} ->
			LogoutLv	= (Player#player.info)#info.lv,
			Time		= LogoutTime - LoginTime,
			
			TaskMain	= (Player#player.task)#task_data.main,
			TaskId		= if is_record(TaskMain, task) -> TaskMain#task.id; ?true -> 0 end,
			MapData     = Player#player.maps,
            CurMapInfo  = MapData#map_data.cur,
            MapId       = CurMapInfo#map_info.map_id,
			Ip			= Player#player.ip,
			?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~ts,~p",
						[?CONST_LOG_LOGOUT, UserId, misc:to_list(Account), LoginTime, LogoutTime, 
						 Time, LoginLv, LogoutLv, TaskId, MapId, misc:to_list(Ip), LogoutReason]);
		_ -> ?ok
	end;
log_logout(_Player, _LogoutTime, _Reason) -> 
	?ok.

%% 升级日志
log_level_up(Player) ->
	UserId	= Player#player.user_id,
	ServId	= Player#player.serv_id,
	UserLv	= (Player#player.info)#info.lv,
	Time	= misc:seconds(),
	Ip		= Player#player.ip,
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~ts",
				[?CONST_LOG_LV_UP, UserId, ServId, UserLv-1, UserLv, Time, misc:to_list(Ip)]).
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc    邮件
%% 服务器ID|时间戳|邮件ID|操作类型|邮件类型|物品ID|物品数量|绑定状态|发送者|接受者|发送时间|元宝|铜钱|礼券|绑定元宝|发送点|角色id
%% ServId|Time|MailId|Operate|Type|GoodsId|Count|Bind|SName|RName|TimeS|Cash|Gold|Point
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 邮件
log_mail(MailId, Operate, Type, GoodsId, Count, Bind, SName, RName, TimeS, Cash, Gold, BCash, BCash2,Point, UserId) ->
	ServId	= config:read_deep([server, base, sid]),
    ?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~ts,~ts,~p,~p,~p,~p,~p,~p,~p",
                [?CONST_LOG_MAIL, ServId, misc:seconds(), MailId, Operate, Type, GoodsId, Count, Bind,
				 misc:to_list(SName), misc:to_list(RName), TimeS, Cash, Gold, Point, BCash, BCash2,UserId]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%待定的日志接口%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	战斗   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 战斗技能统计
%% log_battle_skill(UserId, UserLv, SkillId, Pro, Times) ->
%% 	ServId	= 0,
%% 	Time	= misc:seconds(),
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p",
%% 				[?CONST_LOG_BATTLE_SKILL, UserId, ServId, UserLv, Time, SkillId, Pro, Times]).  
%% 出战阵型统计
%% log_battle_camp(UserId, ServId, UserLv, CampId) ->
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p,~p",
%% 				[?CONST_LOG_BATTLE_CAMP, UserId, ServId, UserLv, misc:seconds(), CampId]). 
%% log_battle_horse(Player) when is_record(Player, player) ->
%% 	#player{user_id = UserId, serv_id = ServId, info = Info, equip = Equip} = Player,
%% 	case lists:keyfind({Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER}, 1, Equip) of
%% 		?false ->
%% 			?ok;
%% 		{_, Container} ->
%% 			GoodsList = tuple_to_list(Container#ctn.goods),
%% 			Fun = fun(Goods) ->
%% 						  case is_record(Goods, goods) =:= ?true andalso Goods#goods.sub_type =:= ?CONST_GOODS_EQUIP_HORSE of
%% 							  ?true ->
%% 								  ?MSG_PLAYER("~p,~p,~p,~p,~p,~p",
%% 											  [?CONST_LOG_BATTLE_CAMP, UserId, ServId, Info#info.lv, misc:seconds(), Goods#goods.goods_id]);
%% 							  ?false ->
%% 								  skip
%% 						  end
%% 				  end,
%% 			lists:foreach(Fun, GoodsList)
%% 	end;
%% log_battle_horse(_Player) ->
%% 	?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc    阵营战
%% Rank排名|Score积分|Coin铜钱奖励|Mer1功勋|Mer2排名功勋
log_camp_battle(UserId, Rank, Score, Coin, Mer1, Mer2) ->
	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(UserId),
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
				[?CONST_LOG_CAMP_BATTLE, UserId, ServId, UserLv, Time, Rank, Score, Coin, Mer1, Mer2]).
%% 
%% %% 跨服战
%% log_across_serv(UserId, Operate, Point, Type, Cost) ->
%% 	{UserId, UserLv, _Vip, ServId, Time, _Account} = user_info(UserId),
%% 	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p",
%% 				[?CONST_LOG_ACROSS_SERV, UserId, ServId, UserLv, Time, Operate, Point, Type, Cost]). 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	商城!!!   
%% 玩家ID	玩家账号	商城类型	货币类型	货币值	物品ID	物品数量	时间戳
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%商城购买道具
log_shop_secret(Player, GoodsId, GoodsNum, MoneyType, Cost, Score, Time) ->
	{UserId, _UserLv, _Vip, ServId, Time, Account} = user_info(Player),
	ShopType = 1,
	?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p",
			  	[?CONST_LOG_SHOP_SECRET, UserId, misc:to_list(Account), ServId, MoneyType, Cost, Score, GoodsId, GoodsNum, Time, ShopType]).

%% 登录请求
log_login_req(AccId, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug, LinkTime) ->
    ?MSG_PLAYER("~p,~p,~ts,~p,~p,~p,~p,~p,~p,~p,~p,~p,~p",
                [?CONST_LOG_LOGIN_REQ, AccId, Account, ServId, Fcm, UserId, Exist, State, GameTime, LogoutTimeLast, Sing, Debug, LinkTime]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	青梅煮酒!!!   
%% 玩家ID	玩家SID	平台ID 金额	对手ID	对手SID 平台ID	对手金额	时间戳
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_gamble(UserId, UserSID, UserPId, Chip1, UserID2, UserSID2, UserPId2, Chip2)->
	?MSG_PLAYER("~p,~p,~p,~p,~p,~p,~p,~p,~p,~p", [?CONST_LOG_GAMBLE, UserId, UserSID, UserPId, Chip1, UserID2, UserSID2, UserPId2, Chip2,  misc:seconds()]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc	雪夜赏灯!!!   
%% 玩家ID	积分 动作(1,充值；2,点灯)	时间戳
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
log_snow(UseId, Point, Action) ->
  ?MSG_PLAYER("~p,~p,~p,~p,~p", [?CONST_LOG_SNOW, UseId, Point, Action, misc:seconds()]).
%%
%% Local Functions
%%
user_info(UserId) when is_number(UserId) ->
	case player_api:get_player_fields(UserId, [#player.account, #player.info]) of
		{?ok, [Account, #info{lv = Lv, vip = Vip}]} ->
			ServId	= config:read_deep([server, base, sid]),
			{UserId, Lv, Vip, ServId, misc:seconds(), Account};
		_ -> {UserId, 1, 0, 0, misc:seconds(), "null"}
	end;
user_info(Player = #player{info = #info{lv = Lv, vip = Vip}, serv_id = ServId})
  when is_record(Player, player) ->
	{Player#player.user_id, Lv, Vip, ServId, misc:seconds(), misc:to_list(Player#player.account)};
user_info(_Player) -> {0, 1, 0, 0, misc:seconds(), "null"}.


%% 查找玩家平台帐号
get_user_account(UserId) ->
	case player_api:get_player_field(UserId, #player.account) of
		{?ok, Account} -> 
            Account;
		_ -> <<"null">>
	end.

%% 查找玩家服务器id
get_user_server(UserId) ->
	case player_api:get_player_field(UserId, #player.serv_id) of
		{?ok, ServId} -> ServId;
		_ -> 0
	end.

%% 是否首次消费
%% 返回：是否首次消费，#money.first_consume
is_first(UserId, ?CONST_SYS_CASH, ?CONST_LOG_MINUS_CURRENCY) ->
	case ets_api:lookup(?CONST_ETS_PLAYER_MONEY, UserId) of
		Money when is_record(Money, money) ->
			case Money#money.first_consume of
				?CONST_SYS_FALSE ->
					player_api:process_send(UserId, player_api, first_consume, []),
					?CONST_SYS_TRUE;
				?CONST_SYS_TRUE -> ?CONST_SYS_FALSE
			end;
		_Other -> ?CONST_SYS_FALSE
	end;
is_first(_UserId, _, _) -> ?CONST_SYS_FALSE.

%% 
get_tab_name(?CONST_LOG_USER) -> "log_data_user";
get_tab_name(?CONST_LOG_CTN) -> "log_data_ctn";
get_tab_name(?CONST_LOG_BATTLE) -> "log_data_battle";
get_tab_name(?CONST_LOG_PARTNER) -> "log_data_partner";
get_tab_name(?CONST_LOG_MAP) -> "log_data_map";
get_tab_name(?CONST_LOG_ACHIEVEMENT) -> "log_data_achievement";
get_tab_name(?CONST_LOG_MAIL) -> "log_data_mail";
get_tab_name(?CONST_LOG_CHESS) -> "log_data_chess";
get_tab_name(?CONST_LOG_ABILITY_CAMP) -> "log_data_ability_camp";
get_tab_name(?CONST_LOG_FURNACE) -> "log_data_furnace";
get_tab_name(?CONST_LOG_COPY) -> "log_data_copy";
get_tab_name(?CONST_LOG_FRIEND) -> "log_data_friend";
get_tab_name(?CONST_LOG_GUILD) -> "log_data_guild";
get_tab_name(?CONST_LOG_PRACTISE) -> "log_data_practise";
get_tab_name(?CONST_LOG_MARKET) -> "log_data_market";
get_tab_name(?CONST_LOG_MALL) -> "log_data_mall";
get_tab_name(?CONST_LOG_TASK) -> "log_data_task";
get_tab_name(?CONST_LOG_RESOURCE) -> "log_data_resource";
get_tab_name(?CONST_LOG_SIG_ARENA) -> "log_data_sig_arena";
get_tab_name(?CONST_LOG_LOTTERY) -> "log_data_lottery";
get_tab_name(?CONST_LOG_MIND) -> "log_data_mind";
get_tab_name(?CONST_LOG_PATROL) -> "log_data_patrol";
get_tab_name(?CONST_LOG_SKILL) -> "log_data_skill";
get_tab_name(?CONST_LOG_HORSE) -> "log_data_horse";
get_tab_name(?CONST_LOG_SPRING) -> "log_data_spring";
get_tab_name(?CONST_LOG_TOWER) -> "log_data_tower";
get_tab_name(?CONST_LOG_COMMERCE) -> "log_data_commerce";
get_tab_name(?CONST_LOG_WELFARE) -> "log_data_welfare";
get_tab_name(?CONST_LOG_COLLECT) -> "log_data_collect";
get_tab_name(?CONST_LOG_BOSS) -> "log_data_boss";
get_tab_name(?CONST_LOG_INVASION) -> "log_data_invasion";
get_tab_name(?CONST_LOG_SCHEDULE) -> "log_data_schedule";
get_tab_name(?CONST_LOG_SIEGE) -> "log_data_siege";
get_tab_name(?CONST_LOG_MCOPY) -> "log_data_mcopy";
get_tab_name(?CONST_LOG_STREN) -> "log_data_stren";
get_tab_name(?CONST_LOG_MULTI_ARENA) -> "log_data_multi_arena";
get_tab_name(?CONST_LOG_RANK) -> "log_data_rank";
get_tab_name(?CONST_LOG_EXPLOIT) -> "log_data_exploit";
get_tab_name(?CONST_LOG_MERITORIOUS) -> "log_data_meritorious";
get_tab_name(?CONST_LOG_RECHARGE) -> "log_data_recharge";
get_tab_name(?CONST_LOG_CURRENCY) -> "log_data_currency";
get_tab_name(?CONST_LOG_CAMPAIGN) -> "log_data_campaign";
get_tab_name(?CONST_LOG_BATTLE_SKILL) -> "log_data_battle_skill";
get_tab_name(?CONST_LOG_BATTLE_PARTNER) -> "log_data_battle_partner";
get_tab_name(?CONST_LOG_BATTLE_CAMP) -> "log_data_battle_camp";
get_tab_name(?CONST_LOG_BATTLE_STAT) -> "log_data_battle_stat";
get_tab_name(?CONST_LOG_BUFF) -> "log_data_buff";
get_tab_name(?CONST_LOG_CAMP_BATTLE) -> "log_data_camp_battle";
get_tab_name(?CONST_LOG_ACROSS_SERV) -> "log_data_across_serv";
get_tab_name(?CONST_LOG_GUILD_FLAG) -> "log_data_guild_flag";
get_tab_name(?CONST_LOG_MARRY) -> "log_data_marry";
get_tab_name(?CONST_LOG_SHOP) -> "log_data_shop";
get_tab_name(?CONST_LOG_RECONNECT) -> "log_data_reconnect";
get_tab_name(?CONST_LOG_LOGIN_CHECK) -> "log_data_login_check";
get_tab_name(?CONST_LOG_LOGIN) -> "log_data_login";
get_tab_name(?CONST_LOG_LOGOUT) -> "log_data_logout";
get_tab_name(?CONST_LOG_LV_UP) -> "log_data_lv_up";
get_tab_name(?CONST_LOG_GOODS) -> "log_data_goods";
get_tab_name(?CONST_LOG_USER_CREATE) -> "log_data_user_create";
get_tab_name(?CONST_LOG_TRAINS_POINT) -> "log_data_trains_point";
get_tab_name(?CONST_LOG_SOUL) -> "log_data_soul";
get_tab_name(?CONST_LOG_ROBOT_COST) -> "log_data_robot";
get_tab_name(?CONST_LOG_WORLD) -> "log_data_world";
get_tab_name(?CONST_LOG_LINK) -> "log_data_link";
get_tab_name(?CONST_LOG_SHOP_SECRET) -> "log_data_shop_secret";
get_tab_name(?CONST_LOG_LOGIN_REQ) -> "log_data_login_req";
get_tab_name(?CONST_LOG_GAMBLE)->"log_data_gamble";
get_tab_name(?CONST_LOG_GAMBLE_EXCHANGE)->"log_data_gamble_exchange";
get_tab_name(?CONST_LOG_SNOW)->"log_data_snow";
get_tab_name(_) -> "".
