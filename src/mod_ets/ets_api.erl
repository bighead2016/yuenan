%% Author: cobain
%% Created: 2012-7-12
%% Description: TODO: Add description to ets_api
-module(ets_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("drive.mysql.hrl").

-include("record.data.hrl").
-include("record.player.hrl").
-include("record.map.hrl").
-include("record.home.hrl").
-include("record.tower.hrl").
-include("record.guild.hrl").
-include("record.robot.hrl").
-include("record.act.hrl").
-include("record.man.hrl").
-include("tencent.hrl").
%%
%% Exported Functions
%%
-export([start/0, initial_ets_data/0]).
-export([new/2, new/3, list/1, 
         insert/2,
         delete/1, delete/2, delete_match/2,  
         lookup/2, lookup_element/3, select/2, match/2, 
         update_element/3, update_counter/3, info/2,
         gc/0]).
%%
%% API Functions
%%
%% 初始化ETS
start() ->
	EtsList = [
			   {?CONST_ETS_SYS,			 		1},
			   {?CONST_ETS_MINI_CLIENT,			#mini_client.user_id},
               {?CONST_ETS_NET,                 1},                     %% 玩家网络进程
			   {?CONST_ETS_PLAYER_IP,	 		1},						%% 角色--在线角色IP
               {?CONST_ETS_PLAYER_NAME,         1},                     %% 角色--角色名|角色ID对应ETS
               {?CONST_ETS_PLAYER_ACCOUNT,      1},                     %% 角色--平台账号|角色ID对应ETS
			   {?CONST_ETS_PLAYER_DEPOSIT,		1},						%% 角色--充值
			   {?CONST_ETS_PLAYER_ONLINE, 		#player.user_id},		%% 角色--在线玩家ETS 
			   {?CONST_ETS_PLAYER_OFFLINE, 		#player.user_id},		%% 角色--离线玩家ETS 
			   {?CONST_ETS_PLAYER_MONEY,		#money.user_id},		%% 角色--货币ETS 
			   {?CONST_ETS_PLAYER_GOODS_LIMIT,	1},						%% 角色--全服物品掉落限制 
			   
			   {?CONST_ETS_ADMIN_ORDER_MAIL,   	1},						%% 游戏后台--邮件发送货币、道具订单
			   {?CONST_ETS_MAIL,              	#mail.mail_id},
			   {?CONST_ETS_MAP,               	1},
			   {?CONST_ETS_MAP_PLAYER,         	#map_player.key},
			   
			   {?CONST_ETS_RELATION_DATA,       #relation_data.user_id},%% 好友-信息
			   {?CONST_ETS_RELATION_BE,         #relation_be.user_id},	%% 好友-被动
			   {?CONST_ETS_BLESS_USER,          #bless_user.user_id},	%% 祝福-祝福瓶
			   {?CONST_ETS_BLESS_INFO,          #bless_info.user_id},	%% 祝福-祝福信息
			   
			   {?CONST_ETS_PRACTICE,            #practice.user_id},		%% 修炼
			   {?CONST_ETS_PRACTICE_USER,       #practice.user_id},		%% 修炼
			   {?CONST_ETS_PRACTICE_DOLL,		#practice_doll.user_id},%% 离线替身
			   
			   {?CONST_ETS_MALL,	    		1},						%% 商城-限时折扣
			   {?CONST_ETS_MALL_DISCOUNT,	    #mall_discount.key},	%% 商城-限时折扣-玩家
			   {?CONST_ETS_MALL_SALE,	        1},						%% 商城-打折
			   
			   {?CONST_ETS_RANK,				#rank.id},  	
			   {?CONST_ETS_TEAM_INVITE_CD,      #team_invite_cd.key},
			   {?CONST_ETS_MARKET_SALE,         #market_sale.sale_id},
			   {?CONST_ETS_MARKET_BUY,          #market_buy.buy_id}, 
			   {?CONST_ETS_MARKET_SEARCH, 		#market_search.goods_id},
			  
			   {?CONST_ETS_GUILD_DATA,			#guild_data.guild_id}, 
			   {?CONST_ETS_GUILD_MEMBER,		#guild_member.user_id},
			   {?CONST_ETS_GUILD_APPLY,			#guild_apply.user_id}, 
 			   {?CONST_ETS_GUILD_TIME,			1}, 
			   
			   {?CONST_ETS_PARTY_ACTIVE,		#party_active.id},
			   {?CONST_ETS_PARTY_DATA,			#party_data.guild_id},
			   {?CONST_ETS_PARTY_PLAYER,		#party_player.user_id},
			   {?CONST_ETS_PARTY_AUTO,			1},
			   {?CONST_ETS_PARTY_DOLL,			#party_doll.user_id},		% 军团宴会替身
			   
               {?CONST_ETS_GUILD_PVP_PLAYER_RANK,  #guild_pvp_score_rank.guild_id},

               {?CONST_ETS_GUILD_PVP_MAP_INFO,  #guild_pvp_map_info.user_id},
			   
 			   {?CONST_ETS_ARENA_PVP_M,			#arena_pvp_m.user_id},  	% 多人竞技-玩家信息
			   {?CONST_ETS_ARENA_PVP,			#arena_pvp_active.id},		% 多人竞技-活动
			   {?CONST_ETS_ARENA_PVP_RANK,		#arena_pvp_rank.rank},  	% 多人竞技-前10排名
			       
			   {?CONST_ETS_HOME,                #ets_home.user_id},

			   {?CONST_ETS_LOTTERY,				#bulletin.user_id},
               {?CONST_ETS_CAMP_TEAM_INDEX,       #camp_team_index.user_id},
               {?CONST_ETS_CAMP_PVP_TEAM_CROSS,       #camp_pvp_team_cross.user_id},
               {?CONST_ETS_CAMP_PVP_INVITE, #camp_pvp_invite.user_id},
               {?CONST_ETS_CAMP_TEAM_LIST,       #camp_team_list.leader_id},
               {?CONST_ETS_TEAM_AUTHOR,       #team_author.key},
               {?CONST_ETS_TEAM_CROSS_GLOBAL,       #team_cross.key},
               {?CONST_ETS_TEAM_CROSS_LOCAL,       #team_cross.key},
               {?CONST_ETS_TEAM_CROSS_MASTER,       #team_cross.key},
               
			   {?CONST_ETS_GUN_AWARD_EVERYDAY, #ets_gun_award_everyday.user_id},
			   {?CONST_ETS_GUN_CASH_GLOBAL, #ets_gun_cash_global.account},
               {?CONST_ETS_GUN_CASH_LOCAL, #ets_gun_cash_local.user_id},
			   {?CONST_ETS_ARENA_MEMBER,        #ets_arena_member.player_id},
			   {?CONST_ETS_ARENA_REPORT,        #ets_arena_report.id},
			   {?CONST_ETS_ARENA_REWARD,        1},
			   {?CONST_ETS_SPRING,				#spring_active.id}, 		% 温泉-活动
			   {?CONST_ETS_SPRING_INFO,			#spring_info.user_id}, 		% 温泉-玩家信息
			   {?CONST_ETS_SPRING_DOLL,			#spring_doll.user_id}, 		% 温泉-替身娃娃

               {?CONST_ETS_MONSTER,             #monster.id},
			   {?CONST_ETS_TOWER_PASS,			#ets_tower_pass.id},
			   {?CONST_ETS_TOWER_PLAYER,		#ets_tower_player.player_id},
			   {?CONST_ETS_COMMERCE_ONLINE,		#commerce_online.user_id},
			   {?CONST_ETS_COMMERCE_MARKET,		#commerce_market.user_id},
			   {?CONST_ETS_CARAVAN,				#caravan.user_id},
			   {?CONST_ETS_COMMERCE,			#commerce.user_id},
			   {?CONST_ETS_COMMERCE_FRIEND,		#commerce_friend.user_id},
			   {?CONST_ETS_COMMERCE_ROB_INFO,	#commerce_rob_info.id},
               {?CONST_ETS_RAID_PLAYER,         #raid_player.user_id},
               {?CONST_ETS_HALL_GUARD,          1},
               {?CONST_ETS_ACTIVE,              #ets_active.type},
			   {?CONST_ETS_BOSS,				1},
			   {?CONST_ETS_BOSS_DATA,			#boss_data.room},
               {?CONST_ETS_CAMP_PVP_CAMP,       #camp_pvp_camp.camp_id},
               {?CONST_ETS_CAMP_PVP_PLAYER,     #camp_pvp_player.user_id}, 
               {?CONST_ETS_CAMP_PVP_PK_CD,      #camp_pvp_pk_cd.user_id}, 
               {?CONST_ETS_CAMP_PVP_MONSTER,    #camp_pvp_monster.monster_id},
               {?CONST_ETS_GUILD_PVP_MONSTER,   #guild_pvp_monster.monster_id},
               {?CONST_ETS_GUILD_PVP_CAMP,      #guild_pvp_camp.camp_id},
               {?CONST_ETS_GUILD_PVP_GUILD,     #guild_pvp_guild.guild_id},
               {?CONST_ETS_GUILD_PVP_RANK,      #guild_pvp_rank.guild_id},
               {?CONST_ETS_GUILD_PVP_PLAYER,    #guild_pvp_player.user_id},
               {?CONST_ETS_GUILD_PVP_WATER,     #guild_pvp_watch.player_id},
               {?CONST_ETS_GUILD_PVP_ATT_WALL,  #guild_pvp_att_wall.user_id},
               {?CONST_ETS_GUILD_PVP_STATE,     1},
               {?CONST_ETS_CROSS_OUT,           #cross_out.user_id},
               {?CONST_ETS_CROSS_IN,            #cross_in.user_id},
               {?CONST_ETS_CAMP_PVP_DATA,       1},
			   {?CONST_ETS_BOSS_DOLL,			1},
			   {?CONST_ETS_BOSS_PLAYER,			#boss_player.user_id},
               {?CONST_ETS_INVASION,            #invasion_info.team_id},     	% 异民族
			   {?CONST_ETS_INVASION_DOLL,		1},							 	% 异民族自动参加
			   
			   {?CONST_ETS_MCOPY_INFO,          #mcopy_info.user_id},       	% 多人副本信息
               {?ETS_STAT_MYSQL,                1},
			   {?CONST_ETS_CARD21, #ets_card21.user_id},
               {?CONST_ETS_RAID_ELITE_PLAYER,   #raid_elite_player.user_id},	% 精英副本扫荡
               {?CONST_ETS_COLLECT,             #collect.user_id},          	% 采集
               {?CONST_ETS_UNIQUE_TITLE,		1}, 							% 唯一性称号
               {?CONST_ETS_NODES_CONFIG,         #cross_node_config.server_index}, % 集群节点信息几率
			   {?CONST_ETS_CROSS_ARENA_MATCH,    #arena_pvp_cross_match.leader_id},
			   {?CONST_ETS_WORLD_BASE,          1},								% 乱天下--基础数据 
			   {?CONST_ETS_WORLD_DATA,          #world_data.guild_id},			% 乱天下--乱天下数据 
			   {?CONST_ETS_WORLD_PLAYER,        #world_player.user_id},			% 乱天下--玩家数据 
			   {?CONST_ETS_WORLD_ROBOT,         #ets_world_robot.user_id},      % 乱天下--机器人信息
			   {?CONST_ETS_NEW_SERV_RANK,       1},								% 新服活动排名
			   {?CONST_ETS_AUTO_TURN_CARD,      1},  							% 扫荡自动翻牌
			   {?CONST_ETS_CHANGED_NAME,        1},  							% 合服 
			   {?CONST_ETS_CHANGED_NAME_GUILD,  1}, 							% 合服 
			   {?CONST_ETS_ACCOUNT_USER_ID,     1},  							% 帐号--玩家id对照表 
			   {?CONST_ETS_PLAYER_ACCOUNT_2,    1}, 							% 帐号--玩家id对照表 
			   {?CONST_ETS_FCM,                 1}, 							% 防沉迷显示标志
               {?CONST_ETS_CAMP_PVP_ROOM,       #camp_room.room_id},
			   {?CONST_ETS_TOWER_REPORT,        #ets_tower_report.id},  		% 破阵战报
			   {?CONST_ETS_TOWER_REPORT_IDX,    #ets_tower_report_idx.camp_id},	% 破阵战报
			   {?CONST_ETS_COPY_SINGLE_REPORT,        #ets_copy_single_report.id},  		% 精英副本战报
			   {?CONST_ETS_COPY_SINGLE_REPORT_IDX,    #ets_copy_single_report_idx.copy_id}, % 精英副本战报索引
			   {?CONST_ETS_CROSS_NODE_INFO,     #ets_cross_node_info.node},		% 跨服结点信息
			   {?CONST_ETS_CAMP_PVP_COUNTER,    #ets_camp_pvp_counter.room_id},	% 阵营战计数信息
			   {?CONST_ETS_CROSS_USER,          #ets_cross_user.user_id},       % 阵营战计数信息
			   {?CONST_ETS_HONOR_TITLE,         #rec_honor_title.honor_id},		% 开服活动荣誉榜
			   {?CONST_ETS_HERO_RANK,			1},	   					   		% 开服活动英雄榜
			   {?CONST_ETS_RANK_DATA,			1},
               {?CONST_ETS_RANK_AVG_LV,         1},                          	% 平均等级
			   {?CONST_ETS_EXCHANGE_INFO,       1},                          	% 兑换信息
               {?CONST_ETS_RES_POOL,            1},
			   {?CONST_ETS_RESOURCE_LOOKFOR,    #resource_lookfor.user_id},  	% 资源找回
               {?CONST_ETS_ARENA_REPORT_CAMPION,            1},
			   {?CONST_ETS_NODE_INFO,			#ets_node_info.node_name},		% 跨服节点信息
               {?CONST_ETS_BOSS_ROBOT_SETTING,  #ets_boss_robot_setting.key},   % 妖魔破机器人配置
               {?CONST_ETS_ACTIVE_WELFARE,1},                               	% 运营活动玩家数据
			   {?CONST_ETS_SNOW_INFO,			#snow_info.user_id},			% 雪夜赏灯信息
               {?CONST_ETS_CAMP_PVP_SEEDS,      #ets_camp_pvp_seeds.user_id},   % 阵营战种子选手列表
               {?CONST_ETS_CAMP_PVP_LV_PHASE,   #ets_camp_pvp_lv_phase.lv_phase},% 阵营战种子选手列表
               {?CONST_ETS_CAMP_PVP_NODES,      #ets_camp_pvp_nodes.key},
               {?CONST_ETS_CAMP_PVP_LEADER,     #ets_camp_pvp_leader.leader_id},
			   {?CONST_ETS_ACTIVE_STONE_COMPOSE,#ets_active_stone_compose.user_id},
               {?CONST_ETS_CARD_EXCHANGE_PARTNER,1},								% 抽卡换武将活动ets表
			   {?CONST_ETS_BOSS_CROSS_COUNTER,  #ets_boss_cross_counter.room_id},	% 世界boss计数器
			   {?CONST_ETS_BOSS_CROSS_LEADER,   #ets_boss_cross_leader.leader_id},	% 世界boss主节点
			   {?CONST_ETS_BOSS_CROSS_LV_PHASE, #ets_boss_cross_lv_phase.lv_phase},	% 世界boss等级段信息
			   {?CONST_ETS_BOSS_CROSS_NODES,    #ets_boss_cross_nodes.key},         % 世界boss存活节点信息
			   {?CONST_ETS_BOSS_CROSS_USER,     #ets_boss_cross_user.user_id},      % 世界boss计数信息
			   {?CONST_ETS_BOSS_CROSS_SEEDS,    #ets_boss_cross_seeds.user_id},     % 世界boss种子选手信息
			   {?CONST_ETS_BOSS_CROSS_IN,       #ets_boss_cross_in.user_id},		% 世界boss跨服进来
			   {?CONST_ETS_BOSS_CROSS_OUT,      #ets_boss_cross_out.user_id},       % 世界boss跨服出去
			   {?CONST_ETS_BOSS_CROSS_ROOM,     #ets_boss_cross_room.room},         % 世界boss房间信息
               {?CONST_ETS_ARCHERY_INFO,        #ets_archery_info.user_id},  		% 辕门射戟信息表
			   {?CONST_ETS_ENCROACH_INFO,		#ets_encroach_info.user_id},		% 攻城掠地信息表
			   {?CONST_ETS_ENCROACH_RANK,		#ets_encroach_rank.rank_id},		% 攻城掠地排行榜
			   {?CONST_ETS_SECRET,				#ets_secret.id},					% 云游商人信息
			   {?CONST_ETS_SECRET_INFO,			#ets_secret_info.user_id},			% 云游商人玩家信息
			   {?CONST_ETS_MIXED_SERV_ACT,      1},                                 % 合服活动信息
			   {?CONST_ETS_MIXED_SERV, 			1},                                 % 合服活动排名
               {?CONST_ETS_GAMBLE_PLAYER,       #ets_gamble_player.user_id},        % 青梅煮酒玩家信息
               {?CONST_ETS_GAMBLE_ROOM,         #ets_gamble_room.room_id},          % 青梅煮酒房间信息
               {?CONST_ETS_GAMBLE_ROOM_MINI,    #ets_gamble_room_mini.key},
               {?CONST_ETS_ACT_INFO,            #ets_act_info.id},                  % 运营活动
               {?CONST_ETS_ACT_USER,            #ets_act_user.key},                 % 运营活动
               {?CONST_ETS_ACT_TEMP,            #ets_act_tmp.temp_id} ,             % 运营活动
			   {?CONST_ETS_ACT_HUNDRED,    		#ets_act_hundred.key},      		% 百服活动玩家信息
			   {?CONST_ETS_ACT_HUNDRED_RANK, 	1},                                 % 百服活动排名
			   {?CONST_ETS_MATCH_PLAYER,		#ets_match_player.uni_key},			% 闯关比赛个人信息
			   {?CONST_ETS_MATCH_RANK,			#ets_match_rank.rank},				% 闯关比赛排行
			   {?CONST_ETS_MATCH_COPY,			#ets_match_copy.uni_key},			% 闯关比赛关卡信息
			   {?CONST_ETS_MATCH_COPY_IDX,		#ets_match_copy_idx.copy_id},		% 闯关比赛关卡排行
               {?CONST_ETS_MAN_HOUTAI,          #ets_man_houtai.key},               % 后台数据
               {?CONST_ETS_TENCENT_INFO,		#ets_tencent_info.user_id},			
               {?CONST_ETS_TENCENT_INVITE_INFO,	#ets_tencent_invite_info.open_id},
               {?CONST_ETS_TENCENT_PAY_TOKEN,		#ets_tencent_pay_token.token}
			  ],
	start(EtsList).
start([{EtsName, Pos}|EtsList]) ->
	new(EtsName, Pos, 1),
	start(EtsList);
start([{EtsName, Pos, OtherOption}|EtsList]) ->
	new(EtsName, Pos, OtherOption),
	start(EtsList);
start([]) -> ?ok.

%% 新建Ets表
new(EtsName, Pos) -> 
    new(EtsName, Pos, 1).

new(EtsName, Pos, Option) when Pos > 0 -> 
    case Option of
        1 ->
            ets:new(EtsName, ?CONST_ETS_OPTIONAL_PARAM(Pos));
        2 ->
	        ets:new(EtsName, ?CONST_ETS_OPTIONAL_PARAM2(Pos))
    end;
new(EtsName, _Pos, Option) ->
    case Option of
        1 ->
            ets:new(EtsName, ?CONST_ETS_OPTIONAL_PARAM(1));
        2 ->
	        ets:new(EtsName, ?CONST_ETS_OPTIONAL_PARAM2(1))
    end.

list(EtsName) ->
	ets:tab2list(EtsName).

insert(EtsName, ObjectOrObjects) ->
	ets:insert(EtsName, ObjectOrObjects).

delete(EtsName) ->
	ets:delete(EtsName).
delete(EtsName, Key) ->
	ets:delete(EtsName, Key).
delete_match(Tab, Pattern) -> % 返回原先的列表
    List = ets:match_object(Tab, Pattern),
    F = fun(Object) ->
            ets:delete_object(Tab, Object)
        end,
    lists:foreach(F, List),
    {?ok, List}.

lookup(EtsName, Key) ->
	case ets:lookup(EtsName, Key) of
		[] -> ?null;
		[Value|_] ->
			Value
	end.

lookup_element(EtsName, Key, Pos) ->
	ets:lookup_element(EtsName, Key, Pos).

%% ets_api:update_element(ets_map, pid(0,31385,12), 171).
update_element(Tab, Key, Values) ->
    ets:update_element(Tab, Key, Values).

update_counter(Tab, Key, UpdateOp) ->
	ets:update_counter(Tab, Key, UpdateOp).

select(EtsName, MatchSpec) ->
	ets:select(EtsName, MatchSpec).

match(EtsName, Pattern) ->
	ets:match(EtsName, Pattern).

info(Tab, Item) ->
	ets:info(Tab, Item).
%%
%% Local Functions
%%

%% 初始化ETS数据
initial_ets_data() ->
	try
		player_api:initial_ets(),       % 初始化玩家数据
		player_money_api:initial_ets(),	% 初始化玩家Money数据
		guild_api:initial_ets(),		% 初始化军团ets数据 
		practice_api:initial_ets(),		% 初始化修炼ets数据
		market_api:initial_ets(),      	% 初始化拍卖ETS数据
		mail_api:initial_ets(),			% 初始化邮件ETS数据
		home_api:init_ets(),			% 初始化家园ETS数据
		tower_api:init_ets(),			% 初始化闯塔ETS数据
		single_arena_api:initial_ets(), % 初始化个人竞技场信息
		mall_api:start(),				% 初始化商城限时抢购物品
		commerce_api:initial_ets(),		% 初始化商路系统商队和市场
		relation_api:initial_ets(), 	% 初始化好友信息
		arena_pvp_api:initial_ets(), 	% 初始化多人竞技场
		bless_api:initial_ets(),        % 初始化祝福数据
		player_combine_api:initial_ets(),   % 合服
		copy_single_report_api:init_ets(), 	% 精英副本战报
		new_serv_api:init_honor_title_ets(),% 初始化开服活动荣誉榜
		new_serv_api:init_hero_rank_ets(),	% 初始化开服活动英雄榜
        rank_api:initial_ets(),
        resource_api:init_ets(),
		schedule_api:init_ets(),        % 初始化资源找回系统
		snow_api:init_ets(),			% 初始化雪夜赏灯数据
		spring_api:init_ets(),			% 初始化温泉替身
		practice_api:init_ets(),		% 离线修炼替身
		party_api:init_ets(),			% 军团宴会替身
		robot_world_api:init_ets_world_robot(), %乱天下替身
		yunying_activity_api:init_stone_compose_ets(),% 初始化宝石合成
		party_api:init_ets_party_active(),% 军团宴会活动
		encroach_api:init_rank_data(),	% 攻城掠地排行榜
		shop_secret:init_active_data(),	% 云游商人
        act_bhv:init_all(),
		?ok
	catch
		Type:Error ->
            ?MSG_SYS("[MODULE:~p LINE:~p]~p ~p~n~p~n", [?MODULE, ?LINE, Type, Error, erlang:get_stacktrace()]),
		    {Type, Error}
	end.

gc() ->
    ets_serv:gc_cast().
