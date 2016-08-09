%% Author: cobain
%% Created: 2012-7-6
%% Description: TODO: Add description to player_mod
-module(player_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.guild.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([register_player_pid/2]).
-export([level_up/3, refresh_buff/4, run_change_name_ets/3, run_change_name_db/3]).
-export([read_player/1, read_player/2, write_player/2, 
		 player_delete/1, server_money_static/0, server_money_static/1, get_fields_list/0]).
%%
%% API Functions
%%


%% 升级
level_up(Player, ExpPlus, ExpAcc) when ExpPlus > 0 ->
	Info		= Player#player.info,
	ExpOld 		= Info#info.exp,
	ExpNext 	= Info#info.expn,
	ExpTotal 	= Info#info.expt,
	Lv			= Info#info.lv,
	
	if
		Lv < ?CONST_SYS_PLAYER_LV_MAX_2 ->
			if
				ExpNext =< ExpOld + ExpPlus ->
					%% 
					ExpTemp		= ExpNext - ExpOld,   % 下一级升级需要损耗经验值
					ExpPlus2	= ExpPlus - ExpTemp,  % 剩余
					ExpNew		= 0,                  % 升级后当前经验复位
					ExpTotal2	= misc:floor(ExpTotal + ExpTemp), % 总经验积累
                    NewLv       = Lv + 1,             % 升级
					
					Info2		= Info#info{lv = NewLv, exp = ExpNew, expt = ExpTotal2},
					ExpAcc2		= ExpAcc + ExpTemp,
					Player2 	= player_attr_api:refresh_attr_lv(Player#player{info = Info2}),
					Player3		= level_up_xxx(Player2),

					%% 升级达成成就
					{?ok, Player4}	= achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_LEVELUP, NewLv, 1),
					%% 荣誉榜称号:第一个达到40级的玩家
					{?ok, Player4_2} = 
						if NewLv =:= 40  ->
							%% {?ok, Player4_1}	= achievement_api:add_achievement(Player4, ?CONST_ACHIEVEMENT_FIRST_LV, 0, 1),
						   new_serv_api:add_honor_title(Player4, ?CONST_NEW_SERV_FIRST_LV, ?CONST_ACHIEVEMENT_FIRST_LV);
						 	?true ->
								{?ok, Player4}
						end,
	
					{?ok, Player5}	= new_serv_api:finish_achieve(Player4_2, ?CONST_NEW_SERV_LEVEL_UP, NewLv, 1),
					{?ok, Player6}	= 
						case (Info#info.vip)#vip.lv > 0 of
							?true ->
								new_serv_api:finish_achieve(Player5, ?CONST_NEW_SERV_VIP_LEVEL_UP, NewLv, 1);
							?false ->
								{?ok, Player5}
						end,
                    bless_api:send_be_blessed(Player6, ?CONST_RELATIONSHIP_BTYPE_LV, NewLv),
					%% TODO 升级消耗时间？
					admin_log_api:log_player(Player6, ?CONST_LOG_POS_USER_LV_UP, NewLv, 0, 0),
					% 统计--升级日志
					admin_log_api:log_level_up(Player6),
					team_api:update_team_player(Player6),
					map_api:change_level(Player6),
                    % 战力
                    schedule_power_api:do_lv_up(Player6),
                    % 
                    center_api:update_account(Player6#player.account, NewLv, Player6#player.serv_id, Player6#player.user_id),
                    % 世界等级加成
                    Rate        = rank_api:get_rank_rate(NewLv),
                    RatePacket  = player_api:msg_sc_world_lv(round((Rate - 1) * 100)),
                    misc_packet:send(Player6#player.user_id, RatePacket),
					level_up(Player6, ExpPlus2, ExpAcc2);
				?true ->
					ExpNew		= misc:floor(ExpOld + ExpPlus),
					ExpTotal2	= misc:floor(ExpTotal + ExpPlus),
					Info2 		= Info#info{exp = ExpNew, expt = ExpTotal2},
					ExpAcc2		= ExpAcc + ExpPlus,
					{Player#player{info = Info2}, ExpAcc2}
			end;
		Lv =:= ?CONST_SYS_PLAYER_LV_MAX_2 ->
			ExpNew		= misc:floor(ExpOld + ExpPlus),
			ExpTotal2	= misc:floor(ExpTotal + ExpPlus),
			ExpNew2		= misc:min(ExpNext - 1, ExpNew),
			ExpTotal3   = misc:min(ExpTotal2, ExpTotal + ExpNext - 1),
			Info2 		= Info#info{exp = ExpNew2, expt = ExpTotal3},
			ExpAcc2		= ExpAcc + (ExpNew2 - ExpOld),
			{Player#player{info = Info2}, ExpAcc2};
		?true -> {Player, 0}
	end;
level_up(Player, _ExpPlus, ExpAcc) -> {Player, ExpAcc}.

%% 升级后各模块额外处理(不会跳级)
%% XXX 出错后的恢复处理肯定是个问题,求修改
level_up_xxx(Player) ->
    try
    	single_arena_api:level_up(Player),
    	Player2	  	= mind_api:user_level_up(Player),
        ?true     	= is_record(Player2, player),
    	Player3   	= partner_api:partner_level_up(Player2),
        ?true     	= is_record(Player3, player),
        Player5   	= task_api:level_up(Player3),
        ?true     	= is_record(Player5, player),
        Player6   	= camp_api:level_up(Player5), % 阵法
        ?true     	= is_record(Player6, player),
		Player9		= welfare_api:level_up(Player6), % 升级领取礼包
        ?true     	= is_record(Player9, player),
		Player10	= player_api:level_up_plus_skill_point(Player9),% 角色升级加技能点
        ?true     	= is_record(Player10, player),
        catch gun_award_api:check_level_up(Player10),
		Player10
    catch
        X:Y ->
            ?MSG_ERROR("!err:~p, ~p, ~p", [X, Y, erlang:get_stacktrace()]),
            Player
    end.

  %   `info` longblob NOT NULL COMMENT '玩家信息',
  % `buff` longblob NOT NULL COMMENT '临时属性',
  % `attr` longblob NOT NULL COMMENT '玩家属性',
  % `equip` longblob NOT NULL COMMENT '装备栏',
  % `skill` longblob NOT NULL COMMENT '技能数据',
  % `camp` longblob NOT NULL COMMENT '阵法',
  % `position` longblob NOT NULL COMMENT '官衔',
  % `partner` longblob NOT NULL COMMENT '伙伴',
  % `guild` longblob NOT NULL COMMENT '军团',
  % `mind` longblob NOT NULL COMMENT '心法',
  % `tower` longblob NOT NULL COMMENT '破阵',
  % `bag` longblob NOT NULL COMMENT '背包',
  % `depot` longblob NOT NULL COMMENT '仓库',
  % `temp_bag` longblob NOT NULL COMMENT '临时背包',
  % `sys` longblob NOT NULL COMMENT '开放系统',
  % `maps` longblob NOT NULL COMMENT '地图列表',
  % `task` longblob NOT NULL COMMENT '任务',
  % `copy` longblob NOT NULL COMMENT '副本',
  % `ability` longblob NOT NULL COMMENT '内功',
  % `achievement` longblob NOT NULL COMMENT '成就',
  % `practice` longblob NOT NULL COMMENT '修炼',
  % `resource` longblob NOT NULL COMMENT '资源',
  % `train` longblob NOT NULL COMMENT '培养',
  % `lottery` longblob NOT NULL COMMENT '宝箱',
  % `spring` longblob NOT NULL COMMENT '温泉',
  % `guide` longblob NOT NULL COMMENT '新手指引',
  % `invasion` longblob NOT NULL COMMENT '异民族',
  % `schedule` longblob NOT NULL COMMENT '课程表',
  % `bless` longblob NOT NULL COMMENT '祝福',
  % `mcopy` longblob NOT NULL COMMENT '多人副本',
  % `welfare` longblob NOT NULL COMMENT '福利系统',
  % `new_serv` longblob NOT NULL COMMENT '新服活动',
  % `weapon` longblob NOT NULL COMMENT '���',
  % `style` longblob NOT NULL COMMENT '外形',
  % `lookfor` longblob NOT NULL COMMENT 'Ѱ��',
  % `horse` longblob NOT NULL COMMENT '坐骑',
  % `furnace` longblob NOT NULL COMMENT '强化',

get_fields_list() ->
    [
     {"info", #player.info},
     {"buff", #player.buff},
     {"attr", #player.attr},
     {"equip", #player.equip, ctn_equip_api, zip, ctn_equip_api, unzip},
     {"skill", #player.skill},
     {"camp", #player.camp},
     {"position", #player.position},
     {"partner", #player.partner, partner_api, partner_zip, partner_api, partner_unzip},
     {"guild", #player.guild},
     {"mind", #player.mind},
     {"tower", #player.tower},
     {"sys", #player.sys_rank},
     {"style", #player.style},
     {"maps", #player.maps},
     
     {"bag", #player.bag, ctn_api, zip, ctn_api, unzip},
     {"depot", #player.depot, ctn_api, zip, ctn_api, unzip},
     {"temp_bag", #player.temp_bag, ctn_api, zip, ctn_api, unzip},
     {"task", #player.task, task_api, zip, task_api, unzip},
     {"copy", #player.copy},
     {"ability", #player.ability},
     {"achievement", #player.achievement},
     {"practice", #player.practice},
     {"resource", #player.resource},
     {"train", #player.train},
     {"lottery", #player.lottery},
     {"spring", #player.spring},
     {"guide", #player.guide},
     {"furnace", #player.furnace},
     {"invasion", #player.invasion},
     {"schedule", #player.schedule},
     {"bless", #player.bless},
     {"mcopy", #player.mcopy},
     {"welfare", #player.welfare},
     {"new_serv", #player.new_serv},
     {"weapon", #player.weapon, weapon_api, zip, weapon_api, unzip},
     {"lookfor", #player.lookfor},
     {"horse", #player.horse},
	 {"partner_soul", #player.partner_soul}
    ].

%% 保存数据
%% Flag:
%% 角色数据持久化类型--创建	1	CONST_SYS_DB_TYPE_CREAT
%% 角色数据持久化类型--定时	2	CONST_SYS_DB_TYPE_INTERVAL
%% 角色数据持久化类型--退出	3	CONST_SYS_DB_TYPE_LOGOUT
write_player(Player, Flag)->
	UserId  	= Player#player.user_id,
	Time   		= misc:seconds(),
	
	Info		= Player#player.info,
	
	UserName	= Info#info.user_name,
	Exp 		= Info#info.exp,
	Lv  		= Info#info.lv,
	Pro 		= Info#info.pro,
	Sex 		= Info#info.sex,
	Vip 		= player_api:get_vip_lv(Info),
	State		= Player#player.state,
	Ip			= Player#player.ip,
    
    X           = get_fields_list(),
    
	case Flag of
		?CONST_SYS_DB_TYPE_CREAT ->
			player_db_mod:create_write_player(Player, X),
			mysql_api:fetch_cast(<<"UPDATE `game_user` SET ",
								   "  `user_name` = '",			(misc:to_binary(UserName))/binary,
								   "',`exist` = '",				(misc:to_binary(?CONST_SYS_TRUE))/binary,
								   "',`exp` = '",				(misc:to_binary(Exp))/binary,
								   "',`lv`  = '",				(misc:to_binary(Lv))/binary,
								   "',`pro` = '",	            (misc:to_binary(Pro))/binary,
								   "',`sex` = '",	            (misc:to_binary(Sex))/binary,
								   "',`vip` = '",	            (misc:to_binary(Vip))/binary,
								   "',`reg_time` = '",	        (misc:to_binary(Time))/binary,
								   "',`reg_ip` = '",	        (misc:to_binary(Ip))/binary,
								   "',`online_flag` = '",		(misc:to_binary(?CONST_PLAYER_ONLINE))/binary,
								   "' WHERE `user_id` = ", 		(misc:to_binary(Player#player.user_id))/binary, " LIMIT 1 ;">>),
			?ok;
		?CONST_SYS_DB_TYPE_INTERVAL ->
			player_db_mod:write_player(Player, X),
            {?ok, Money} = player_money_api:read_money(UserId),
			mysql_api:fetch_cast(<<"UPDATE `game_user` SET ",
								   "  `exp` = '",	            (misc:to_binary(Exp))/binary,
								   "',`lv`  = '",	            (misc:to_binary(Lv))/binary,
								   "',`vip` = '",	            (misc:to_binary(Vip))/binary,
								   "',`game_time` = `game_time` - `login_time_last` + '", (misc:to_binary(Time))/binary,
								   "',`online` = `online` - `login_time_last` + '", (misc:to_binary(Time))/binary,
								   "',`online_flag` = '",		(misc:to_binary(?CONST_PLAYER_ONLINE))/binary,
                                   "',`gold_bind` = '",         (misc:to_binary(Money#money.gold_bind))/binary,
                                   "',`cash` = '",              (misc:to_binary(Money#money.cash))/binary,
                                   "',`cash_bind` = '",         (misc:to_binary(Money#money.cash_bind))/binary,
                                   "',`cash_bind_2` = '",         (misc:to_binary(Money#money.cash_bind_2))/binary,
								   "' WHERE `user_id` = ",      (misc:to_binary(Player#player.user_id))/binary, " LIMIT 1 ;">>),
			rank_api:update_rank(Player),
			?ok;
		?CONST_SYS_DB_TYPE_LOGOUT ->
			player_db_mod:write_player(Player, X),
            {?ok, Money} = player_money_api:read_money(UserId),
			mysql_api:fetch_cast(<<"UPDATE `game_user` SET ",
								   "  `exp` = '",	            (misc:to_binary(Exp))/binary,
								   "',`lv`  = '",	            (misc:to_binary(Lv))/binary,
								   "',`vip` = '",	            (misc:to_binary(Vip))/binary,
								   "',`state` = '",				(misc:to_binary(State))/binary,
								   "',`game_time` = `game_time` - `login_time_last` + '", (misc:to_binary(Time))/binary,
								   "',`logout_time_last` =  '",	(misc:to_binary(Time))/binary,
								   "',`online` = `online` - `login_time_last` + '", (misc:to_binary(Time))/binary,
								   "',`online_flag` = '",		(misc:to_binary(?CONST_PLAYER_OFFLINE))/binary,
                                   "',`gold_bind` = '",         (misc:to_binary(Money#money.gold_bind))/binary,
                                   "',`cash` = '",              (misc:to_binary(Money#money.cash))/binary,
                                   "',`cash_bind` = '",         (misc:to_binary(Money#money.cash_bind))/binary,
                                   "',`cash_bind_2` = '",         (misc:to_binary(Money#money.cash_bind_2))/binary,
								   "' WHERE `user_id` = ",      (misc:to_binary(Player#player.user_id))/binary, " LIMIT 1 ;">>),
			?ok
	end,
	%% 这里还要 更新MYSQL排名数据库 ...
	?ok.

%% player_mod:read_player(222).
read_player(UserId) ->
    player_db_mod:read_player(UserId).
read_player(UserId, Player) ->
    player_db_mod:read_player(UserId, Player).
    
%%
%% Local Functions
%%

%% 删除玩家
player_delete(UserId)->
	player_db_mod:delete_player(UserId).

register_player_pid(PlayerName, PlayerPid) ->
	case misc:where_is({local, PlayerName}) of
		?undefined ->
			?true = misc:register(local, PlayerName, PlayerPid),
			?ok;
		PlayerPid -> ?ok;
		_ ->
			unregister(PlayerName),
			register_player_pid(PlayerName, PlayerPid)
	end.

%% %% 组装玩家数据
%% record_player(Player, First, Second) ->
%%     {Info,    Buff,        Attr,     Equip,    Skill, 
%%      Camp,    Position,    Partner,  Guild,    Mind, %Train,
%%      Tower,   Sys,	       Style,    Maps,     _FirstExt}									= First,
%%     {Bag,     Depot,       TempBag,  Task,     Copy,
%%      Ability, Achievement, Practice, Resource, Train,
%%      Lottery, Spring,      Guide,    Invasion, Schedule, Bless,
%% 	 MCopy,   Welfare,     NewServ,  Weapon,   Lookfor,  Horse, SecondExt}								= Second,
%%     {Furnace} = SecondExt,
%% 	Player#player{
%%                   info               = Info,         % [first]积累信息#info{}
%%                   buff               = Buff,         % [first]临时属性[]
%%                   attr               = Attr,         % [first]角色属性#attr{}
%%                   equip              = Equip,        % [first]装备#ctn{}
%%                   skill              = Skill,        % [first]技能#skill_data{}
%%                   camp               = Camp,         % [first]阵法#camp_data{}
%%                   position           = Position,     % [First]官衔#position_data{}
%% 				  partner            = Partner,      % [first]武将#partner_data{}
%% 				  guild 			 = Guild,		 % [first]军团#guild_data{}
%% 				  mind   			 = Mind,		 % [first]心法#mind_data{}
%%                   train				 = Train,		 % [first]培养属性
%% 				  tower				 = Tower,        % [first]破阵
%%                   sys_rank           = Sys,          % [first]开放系统[]
%%                   style              = Style, 
%%                   maps               = Maps,         % [firse]开放地图[]
%% 				  
%%                   bag                = Bag,          % [second]背包#ctn{}
%%                   depot              = Depot,        % [second]仓库#ctn{}
%%                   temp_bag           = TempBag,      % [second]临时背包#ctn{}
%%                   task               = Task,         % [second]任务#task_data{}
%%                   copy               = Copy,         % [second]副本#copy_data{}
%%                   ability            = Ability,      % [second]内功#ability_data{}
%%                   achievement        = Achievement,  % [second]成就#achievement_data{}
%%                   practice           = Practice,     % [second]修炼
%% 				  resource			 = Resource,	 % [second]资源#resource_data{}
%% 				  lottery			 = Lottery,		 % [second]淘宝属性
%% 				  spring			 = Spring,		 % [second]温泉属性
%%                   furnace			 = Furnace,		 % [second]炼炉属性
%% 				  guide				 = Guide,        % [second]新手指引
%%                   invasion           = Invasion,     % [second]异民族
%% 				  schedule			 = Schedule, 	 % [second]课程表
%%                   bless              = Bless,        % [second]祝福#bless_data{}
%%                   mcopy              = MCopy,        % [second]多人副本#mcopy_data{}
%% 				  welfare			 = Welfare,		 % [second]福利系统#welfare{}
%% 				  new_serv			 = NewServ,		 % [second]新服活动#new_serv{}
%% 				  weapon			 = Weapon,		 % [second]神兵#weapon_data{}
%% 				  lookfor			 = Lookfor,		 % [second]寻访#lookfor_data{}
%% 				  horse 			 = Horse		 % [second]坐骑
%% 				 }.
%% record_player(First) ->
%%     {Info,    Buff,        Attr,     Equip,    Skill, 
%%      Camp,    Position,    Partner,  Guild,    Mind, 
%%      Tower,   Sys,	       Style,    Map,      _FirstExt}					= First,
%%     #player{
%%             info               = Info,         % [first]积累信息#info{}
%%             buff               = Buff,         % [first]buff
%%             attr               = Attr,         % [first]角色属性#attr{}
%%             equip              = Equip,        % [first]装备#ctn{}
%%             skill              = Skill,        % [first]技能#skill_data{}
%%             camp               = Camp,         % [first]阵法#camp_data{}
%% 			position           = Position,     % [First]官衔#position_data{}
%%             partner            = Partner,      % [first]武将#partner_data{}
%% 			guild              = Guild,	       % [first]军团#guild_data{}
%% 			mind               = Mind,	       % [first]心法#mind_data{}
%% 			tower			   = Tower,        % [first]破阵
%% 			sys_rank		   = Sys,		   % [first]最新开启的系统id
%% 			style		       = Style,		   % [first]
%% 			maps		       = Map		   % [first]
%%            }.

%% 刷新buff列表
refresh_buff([#buff{expend_value = DeadLine, buff_id = BuffId, buff_type = BuffType}|Tail], OldBuffList, Now, OldPacket) when DeadLine =< Now ->
    PacketDel = player_api:msg_sc_buff_delete(BuffId, BuffType),
    refresh_buff(Tail, OldBuffList, Now, <<OldPacket/binary, PacketDel/binary>>);
refresh_buff([Buff|Tail], OldBuffList, Now, OldPacket) ->
    refresh_buff(Tail, [Buff|OldBuffList], Now, OldPacket);
refresh_buff([], OldBuffList, _Now, OldPacket) ->
    {lists:reverse(OldBuffList), OldPacket}.

%% 每日全服货币总量统计
server_money_static(ServId) ->
	{?ok, [[CashSum, CashBindSum, GoldBindSum]]} = mysql_api:select_execute(<<"SELECT SUM(cash), SUM(cash_bind), SUM(gold_bind) FROM game_user">>),
	Date = misc:date_num(),
	mysql_api:insert(log_daily_coin, [{serverID, ServId}, {num, GoldBindSum}, {date, Date}]),
	mysql_api:insert(log_daily_money, [{serverID, ServId}, {num, CashSum}, {date, Date}]),
	mysql_api:insert(log_daily_money_bind, [{serverID, ServId}, {num, CashBindSum}, {date, Date}]),
	?ok.

%% 每日全服货币总量统计
server_money_static() ->
	{?ok, [[CashSum, CashBindSum, GoldBindSum]]} = mysql_api:select_execute(<<"SELECT SUM(cash), SUM(cash_bind), SUM(gold_bind) FROM game_user">>),
	Date = misc:date_num(),
	mysql_api:insert(techcenter_daily_currency, [{date, Date}, {cash, CashSum}, {cash_bind, CashBindSum}, {gold_bind, GoldBindSum}]),
	?ok.

%% 改ets
run_change_name_ets(Player, Packet, OldUserName) ->
    player_api:delete_name(OldUserName),
	UserId		= Player#player.user_id,
    Info 		= Player#player.info,
	NewUserName	= Info#info.user_name,
    player_api:insert_name(Info#info.user_name, Player#player.user_id),
    Packet2 = update_single_arena(UserId, NewUserName),
	update_market_name(UserId, OldUserName, NewUserName),
	update_boss_player(UserId, NewUserName),
	update_guild_name(Player, OldUserName, NewUserName),
	update_arena_name(UserId, NewUserName),
    NewPacket 	= <<Packet/binary, Packet2/binary>>,
    {Player, NewPacket}.

%% 更新个人竞技场信息
update_single_arena(UserId, NewUserName) ->
    ets_api:update_element(?CONST_ETS_ARENA_MEMBER, UserId, [{#ets_arena_member.player_name, NewUserName}]),
    Member     = single_arena_api:get_myself_info(UserId),
    StreakAwardList = single_arena_api:get_streak_win_reward_info(UserId),
    DefList    = single_arena_api:get_deffender_list(UserId),
    ReportList = single_arena_api:get_arena_report(UserId),
    PacketMem  = single_arena_api:msg_sc_enter_arena(1, ?CONST_SINGLE_ARENA_OK, Member, StreakAwardList, DefList, ReportList),
    RankList   = single_arena_api:get_single_arena_top_rank_ets(?CONST_SINGLE_ARENA_TOP_RANK), %%获取竞技场排名前XX(ets)
    RankData   = single_arena_api:pack_rank_list(RankList),    %%打包竞技场排行榜信息给前端
    PacketRank = misc_packet:pack(?MSG_ID_SINGLE_ARENA_SC_RANK, ?MSG_FORMAT_SINGLE_ARENA_SC_RANK, {RankData}),
    <<PacketMem/binary, PacketRank/binary>>.

%% 更新市集人名
update_market_name(UserId, OldUserName, NewUserName) ->
	update_market_buy(UserId, OldUserName, NewUserName),
	update_market_buy1(UserId, OldUserName, NewUserName),
	update_market_sale(UserId, OldUserName, NewUserName),
	update_market_sale1(UserId, OldUserName, NewUserName).

%% 更新世界boss玩家名
update_boss_player(UserId, NewUserName) ->
    ets_api:update_element(?CONST_ETS_BOSS_PLAYER, UserId, [{#boss_player.user_name, NewUserName}]).

%% 更新军团玩家名
update_guild_name(#player{user_id = UserId, guild = Guild}, OldUserName, NewUserName) ->
	ets_api:update_element(?CONST_ETS_GUILD_PVP_PLAYER, UserId, [{#guild_pvp_player.name, NewUserName}]),
	ets_api:update_element(?CONST_ETS_GUILD_PVP_MAP_INFO, UserId, [{#guild_pvp_map_info.user_name, NewUserName}]),
	ets_api:update_element(?CONST_ETS_GUILD_PVP_ATT_WALL, UserId, [{#guild_pvp_att_wall.name, NewUserName}]),
	
	ets_api:update_element(?CONST_ETS_GUILD_MEMBER, UserId, [{#guild_member.user_name, NewUserName}]),
	ets_api:update_element(?CONST_ETS_GUILD_APPLY, UserId, [{#guild_apply.user_name, NewUserName}]),
	GuildId = Guild#guild.guild_id,
	case ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId) of
		?null ->
			?ok;
		GuildData ->
			case GuildData#guild_data.chief_id =:= UserId of
				?false ->
					?ok;
				?true ->
					ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId, [{#guild_data.chief_name, NewUserName}])
			end,
			
			MatchSpec = ets:fun2ms(fun(#guild_data{create_name = CreateName} = GData) when CreateName =:= OldUserName -> GData end),
			Res =  ets_api:select(?CONST_ETS_GUILD_DATA, MatchSpec),
			F = fun(#guild_data{guild_id = GId}) ->
					ets_api:update_element(?CONST_ETS_GUILD_DATA, GId, [{#guild_data.create_name, NewUserName}])
				end,
			[F(E) || E <- Res]
	end.

%% 更新战群雄玩家名
update_arena_name(UserId, NewUserName) ->
	ets_api:update_element(?CONST_ETS_ARENA_PVP_M, UserId, [{#arena_pvp_m.user_name, NewUserName}]).

update_market_buy(UserId, OldUserName, NewUserName) ->
	MatchSpec 		 = ets:fun2ms(fun(BuyInfo) when (BuyInfo#market_buy.buy_id =:= UserId andalso
													 BuyInfo#market_buy.buyer_name =:= OldUserName) 
									   -> BuyInfo end),
	List			 = ets_api:select(?CONST_ETS_MARKET_BUY, MatchSpec),
	F	= fun(BuyInfo1) ->
				  Id		= BuyInfo1#market_buy.buy_id,
				  ets_api:update_element(?CONST_ETS_MARKET_BUY,  Id, [{#market_buy.buyer_name, NewUserName}])
		  end,
	[F(BuyInfo1) || BuyInfo1 <- List].

update_market_buy1(UserId, OldUserName, NewUserName) ->	
	MatchSpec 		 = ets:fun2ms(fun(BuyInfo) when (BuyInfo#market_buy.seller_id =:= UserId andalso
													 BuyInfo#market_buy.seller_name =:= OldUserName) 
									   -> BuyInfo end),
	List1			 = ets_api:select(?CONST_ETS_MARKET_BUY, MatchSpec),
	F	= fun(BuyInfo1) ->
				  Id		= BuyInfo1#market_buy.buy_id,
				  ets_api:update_element(?CONST_ETS_MARKET_BUY,  Id, [{#market_buy.seller_name, NewUserName}])
		  end,
	[F(BuyInfo1) || BuyInfo1 <- List1].

update_market_sale(UserId, OldUserName, NewUserName) ->
	MatchSpec 		 = ets:fun2ms(fun(SaleInfo) when (SaleInfo#market_sale.seller_id =:= UserId andalso
													 SaleInfo#market_sale.seller_name =:= OldUserName) 
									   -> SaleInfo end),
	List			 = ets_api:select(?CONST_ETS_MARKET_SALE, MatchSpec),
	F	= fun(SaleInfo1) ->
				  Id		= SaleInfo1#market_sale.sale_id,
				  ets_api:update_element(?CONST_ETS_MARKET_SALE,  Id, [{#market_sale.seller_name, NewUserName}])
		  end,
	[F(SaleInfo1) || SaleInfo1 <- List].

update_market_sale1(UserId, OldUserName, NewUserName) ->
	MatchSpec 		 = ets:fun2ms(fun(SaleInfo) when (SaleInfo#market_sale.buyer_id =:= UserId andalso
													 SaleInfo#market_sale.buyer_name =:= OldUserName) 
									   -> SaleInfo end),
	List			 = ets_api:select(?CONST_ETS_MARKET_SALE, MatchSpec),
	F	= fun(SaleInfo1) ->
				  Id		= SaleInfo1#market_sale.sale_id,
				  ets_api:update_element(?CONST_ETS_MARKET_SALE,  Id, [{#market_sale.buyer_name, NewUserName}])
		  end,
	[F(SaleInfo1) || SaleInfo1 <- List].

%% 改db
run_change_name_db(OldUserName, NewUserName, UserId) ->
    try
        OldUserName2 = misc:to_binary(misc:to_list(OldUserName)),
        NewUserName2 = misc:to_binary(misc:to_list(NewUserName)),
        %%     update game_arena_champion_report set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_arena_champion_report set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_arena_champion_report set opp_name = 'new_name' where opp_name = 'old_name';
        mysql_api:update(<<"update game_arena_champion_report set opp_name = '", 
                           (NewUserName2)/binary, "' where opp_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_arena_member set player_name = 'new_name' where player_name = 'old_name';
        mysql_api:update(<<"update game_arena_member set player_name = '", 
                           (NewUserName2)/binary, "' where player_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_arena_pvp set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_arena_pvp set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_caravan set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_caravan set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_group set name = 'new_name' where name = 'old_name';
        mysql_api:update(<<"update game_group set name = '", 
                           (NewUserName2)/binary, "' where name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_guild set chief_name = 'new_name' where chief_name = 'old_name';
        mysql_api:update(<<"update game_guild set chief_name = '", 
                           (NewUserName2)/binary, "' where chief_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_guild set create_name = 'new_name' where create_name = 'old_name';
        mysql_api:update(<<"update game_guild set create_name = '", 
                           (NewUserName2)/binary, "' where create_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_guild_apply set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_guild_apply set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_guild_member set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_guild_member set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_mail set send_name = 'new_name' where send_name = 'old_name';
        mysql_api:update(<<"update game_mail set send_name = '", 
                           (NewUserName2)/binary, "' where send_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_mail set recv_name = 'new_name' where recv_name = 'old_name';
        mysql_api:update(<<"update game_mail set recv_name = '", 
                           (NewUserName2)/binary, "' where recv_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_market_buy set seller_name = 'new_name' where seller_name = 'old_name';
        mysql_api:update(<<"update game_market_buy set seller_name = '", 
                           (NewUserName2)/binary, "' where seller_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_market_buy set buyer_name = 'new_name' where buyer_name = 'old_name';
        mysql_api:update(<<"update game_market_buy set buyer_name = '", 
                           (NewUserName2)/binary, "' where buyer_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_market_sale set seller_name = 'new_name' where seller_name = 'old_name';
        mysql_api:update(<<"update game_market_sale set seller_name = '", 
                           (NewUserName2)/binary, "' where seller_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_market_sale set buyer_name = 'new_name' where buyer_name = 'old_name';
        mysql_api:update(<<"update game_market_sale set seller_name = '", 
                           (NewUserName2)/binary, "' where seller_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_player_rank set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_player_rank set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_rank_data set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_rank_data set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_rank_data set other_name = 'new_name' where other_name = 'old_name';
        mysql_api:update(<<"update game_rank_data set other_name = '", 
                           (NewUserName2)/binary, "' where other_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_rank_equip set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_rank_equip set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_rank_partner set user_name = 'new_name' where user_name = 'old_name';
        mysql_api:update(<<"update game_rank_partner set user_name = '", 
                           (NewUserName2)/binary, "' where user_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_tower_pass set first_name = 'new_name' where first_name = 'old_name';
        mysql_api:update(<<"update game_tower_pass set first_name = '", 
                           (NewUserName2)/binary, "' where first_name = '", 
                           (OldUserName2)/binary, "';">>),
        %% update game_user set user_name = 'new_name' where user_name = 'old_name'; 
        P = mysql_api:update(<<"update game_user set user_name = '", 
                           (NewUserName2)/binary, "' where user_id = '", 
                           (misc:to_binary(UserId))/binary, "';">>),
        ?MSG_ERROR("ppp=[~p]", [P])
    catch Error:Reason ->
              ?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
              ?ok
    end.