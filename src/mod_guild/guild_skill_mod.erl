%% Author: Administrator
%% Created: 2013-3-11
%% Description: TODO: Add description to guild_skill_mod
-module(guild_skill_mod).

%%
%% Include files
%%
-include("../include/const.common.hrl").
-include("../include/record.player.hrl").
-include("../include/record.base.data.hrl").
-include("../include/const.define.hrl").
-include("../include/const.protocol.hrl").
-include("../include/const.tip.hrl").
-include("../include/const.cost.hrl").
-include("../include/record.guild.hrl").
%%
%% Exported Functions
%%
-export([
		 skill_data/1,magic_data/1,
		 skill_up/2,magic_up/2, 
		 donate/3,
		 shop_data/1,shop_buy/4, skill_up2/2,
		 default_add/1,get_skill_add/2, 
		 get_skill_add/1,
		 skill_up_donate/4,
		 get_surplus_donate_gold/1
		 ]).

%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
skill_data(#player{guild = Guild,net_pid = Pid}) ->
	try
		GuildId 			= Guild#guild.guild_id,
		{?ok,GuildData} 	= guild_api:get_guild_data(GuildId),	%% 取得GuildData
		SkillList			= GuildData#guild_data.skill,			%% 技能列表
		{?ok,Packet}		= skill_data2(SkillList),
		misc_packet:send(Pid, Packet)
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

skill_data2(SkillList) ->
	SkillInfo 	= skill_list(SkillList),	%% 技能信息
	Packet 		= guild_api:msg_sc_skill_list(SkillInfo),
	{?ok,Packet}.

%% 技能信息列表
skill_list(SkillList) ->
	skill_list(SkillList,[]).

skill_list([],Res) -> Res;
skill_list([GuildSkill|SkillList],Res) ->
	SkillId 	= GuildSkill#guild_skill.skill_id,	%% id
	Lv			= GuildSkill#guild_skill.skill_lv,	%% 等级	 
	Pro			= GuildSkill#guild_skill.skill_pro,	%% 进度
	skill_list(SkillList,[{SkillId,Lv,Pro}|Res]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能升级
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
skill_up(Player = #player{guild = Guild,net_pid = Pid},SkillId) ->
	try
		GuildId					= Guild#guild.guild_id,		
		Pos						= Guild#guild.guild_pos,
		?ok						= check_skill_pos(Pos),					%% 检查职位
		{?ok,GuildData} 		= guild_api:get_guild_data(GuildId),	%% ets-GuildData
		SkillList				= GuildData#guild_data.skill,			%% 技能列表
		KickMoney				= GuildData#guild_data.kick_money,
		
		{?ok,Skill}				= get_skill(SkillId,SkillList), 		%% 技能
		SkillLv					= Skill#guild_skill.skill_lv,			%% 等级
		SkillPro				= Skill#guild_skill.skill_pro,			%% 进度
 		{?ok,Cost}				= get_rec_skill_cost(SkillId,SkillLv),	%% 升级总花费资金	
		case SkillId of
			1 ->
				Cost2			= Cost - SkillPro + KickMoney;			%% 升级需花费资金
			_ -> 
				Cost2			= Cost - SkillPro
		end,
		
 		NewLv					= Skill#guild_skill.skill_lv + 1,		%% 等级加一
		GuildLv					= GuildData#guild_data.lv,
		Money 					= GuildData#guild_data.money,
		?ok						= check_skill_money(Money,Cost2),		%% 检查军团资金
		Money2					= Money - Cost2,
		
 		{?ok,Effect}			= get_rec_skill_effect(SkillId,NewLv,GuildLv),						%% 升级效果
 		Skill2					= Skill#guild_skill{skill_lv = NewLv,skill_pro = 0},				%% 新的技能
		SkillList2 				= lists:keyreplace(SkillId, #guild_skill.skill_id,SkillList,Skill2),%% 更新技能列表
		
 		{?ok,GuildData2,DBList,ETSList}	
								= skill_new_data(GuildData,Money2,Effect,SkillId,NewLv,SkillList2,0),	%% 更新GuildData
		{?ok,Packet1}			= skill_data2(GuildData2#guild_data.skill),
		Packet2					= guild_mod:info_packet(GuildData2),
		Packet3					= message_api:msg_notice(?TIP_GUILD_LEVLE_UP_SUCCESS),
		misc_packet:send(Pid, <<Packet1/binary,Packet2/binary,Packet3/binary>>),
		
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_SKILL_UP, 0, 0, 0, SkillId, NewLv, Cost2),
		skill_achievement(GuildData2#guild_data.member_list,SkillId,NewLv),
		ets_api:update_element(?CONST_ETS_GUILD_DATA, GuildId,ETSList),
		guild_db_mod:update_data(GuildId,DBList),
        if 
            ?CONST_GUILD_SKILL_TYPE_LV =:= Skill2#guild_skill.skill_id ->
                map_api:change_guild_lv(Player);
            ?true ->
                ?ok
        end
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 技能成就(确实是不好处理)
skill_achievement(MemberList,SkillId,SkillLevel) ->
	case is_achievement(SkillId,SkillLevel) of
		?true ->
			skill_achievement2(MemberList,SkillId,SkillLevel);
		_ -> ?ok
	end.

is_achievement(SkillId,SkillLevel) ->
	if
		  SkillId =:= ?CONST_GUILD_SKILL_TYPE_LV -> %% 六韬
			  ?true; 
		  SkillId =:= ?CONST_GUILD_SKILL_TYPE_SHOP andalso SkillLevel >= 5 -> %% 百宝
			  ?true; 
		  SkillId =:= ?CONST_GUILD_SKILL_TYPE_MEMBER andalso SkillLevel >= 5 -> %% 府兵制
			  ?true; 
		  SkillId =:= ?CONST_GUILD_SKILL_TYPE_EXP andalso SkillLevel >= 5 -> 
			  ?true; 
		  SkillId =:= ?CONST_GUILD_SKILL_TYPE_GROWTH andalso SkillLevel >= 5 -> 
			  ?true; 
		  ?true ->
			  ?false
	 end.

%% 成就
skill_achievement2([],_SkillId,_SkillLevel) -> ?ok;
skill_achievement2([UserId|MemberList],?CONST_GUILD_SKILL_TYPE_LV,SkillLevel) ->
	Packet   = player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_LV, SkillLevel),
	misc_packet:send(UserId, Packet),
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_GUILD_LEVELUP, SkillLevel, 1),%% 六韬成就
	%% 荣誉榜：第一个将军团升级到4级的军团长
	if SkillLevel =:= 4 ->
		   GuildId = case player_api:get_player_fields(UserId, [#player.guild]) of
							{?ok, [Guild]} when is_record(Guild, guild) ->
								Guild#guild.guild_id;
							_ -> 0
						end,
		   {?ok, GuildChiefId} = guild_api:get_guild_chief_id(GuildId),
			%% achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_FIRST_GUILD_LV, 0, 1),%% 六韬成就
		   new_serv_api:add_honor_title(GuildChiefId, ?CONST_NEW_SERV_FIRST_GUILD_LV, ?CONST_ACHIEVEMENT_FIRST_GUILD_LV),
		   ?ok;
	   ?true ->
		   ?ok
	end,	
	skill_achievement2(MemberList,?CONST_GUILD_SKILL_TYPE_LV,SkillLevel);
skill_achievement2([UserId|MemberList],?CONST_GUILD_SKILL_TYPE_SHOP,SkillLevel) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_ARMOURY_LEVELUP, SkillLevel, 1),%% 百宝成就
	skill_achievement2(MemberList,?CONST_GUILD_SKILL_TYPE_SHOP,SkillLevel);
skill_achievement2([UserId|MemberList],?CONST_GUILD_SKILL_TYPE_MEMBER,SkillLevel) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_IMPEDIMENTA_LEVELUP, SkillLevel, 1),%% 府兵制成就
	skill_achievement2(MemberList,?CONST_GUILD_SKILL_TYPE_MEMBER,SkillLevel);
skill_achievement2([UserId|MemberList],?CONST_GUILD_SKILL_TYPE_EXP,SkillLevel) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_PLAYGROUND_LEVELUP, SkillLevel, 1),%% 武经七书成就
	skill_achievement2(MemberList,?CONST_GUILD_SKILL_TYPE_EXP,SkillLevel);
skill_achievement2([UserId|MemberList],?CONST_GUILD_SKILL_TYPE_GROWTH,SkillLevel) ->
	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_LAIRAGE_LEVELUP, SkillLevel, 1),%% 石工成就
	skill_achievement2(MemberList,?CONST_GUILD_SKILL_TYPE_GROWTH,SkillLevel).

skill_new_data(GuildData,Money,Effect,SkillId,NewLv,SkillList,Pro) ->
	if
		SkillId =:= ?CONST_GUILD_SKILL_TYPE_LV  ->		%% 六韬-开启技能
			KickMoney	= GuildData#guild_data.kick_money,
			SkillList2 	= get_add_list(Effect,SkillList),
			GuildData2 	= GuildData#guild_data{skill = SkillList2,lv = NewLv,money = Money,exp = Pro},
			ETSList		= [{#guild_data.skill, SkillList2},{#guild_data.lv,NewLv},
						   {#guild_data.money,Money},{#guild_data.exp,Pro},
						   {#guild_data.kick_money,KickMoney}],
			DBList		= [{skill,SkillList2},{lv,NewLv},{money ,Money},{exp,Pro},{kick_money,KickMoney}];
		SkillId =:= ?CONST_GUILD_SKILL_TYPE_MEMBER  ->	%% 府兵制-增加人数上限
			GuildData2 	= GuildData#guild_data{skill = SkillList,num_max = Effect,money = Money},
			ETSList		= [{#guild_data.skill, SkillList},{#guild_data.num_max,Effect},{#guild_data.money,Money}],
			DBList		= [{skill,SkillList},{num_max,Effect},{money, Money}];
		?true -> 
			GuildData2 	= GuildData#guild_data{skill = SkillList,money = Money},
			ETSList		= [{#guild_data.skill, SkillList}, {#guild_data.money,Money}],
			DBList		= [{skill,SkillList},{money ,Money}]
	end,
	{?ok,GuildData2,DBList,ETSList}.

%% 获取开放的列表
get_add_list([],SkillList) -> SkillList;
get_add_list([Id|AddList],SkillList) ->
	case lists:keyfind(Id, #guild_skill.skill_id, SkillList) of
		?false ->
			GuildSkill = #guild_skill{skill_id = Id,skill_lv = 0},
			get_add_list(AddList,[GuildSkill|SkillList]);
		_ ->
			get_add_list(AddList,SkillList)
	end.

%% 检查职位
check_skill_pos(?CONST_GUILD_POSITION_CHIEF) -> ?ok;      % 正团
check_skill_pos(?CONST_GUILD_POSITION_VICE_CHIEF) -> ?ok; % 副团 
check_skill_pos(_) ->
	throw({?error, ?TIP_GUILD_POS_IS_NOT_FIT}).

%% 取得相应技能
get_skill(SkillId,List) ->
	case lists:keyfind(SkillId, #guild_skill.skill_id, List) of
		?false ->
			throw({?error,?TIP_GUILD_SKILL_OPEN}); %% 技能未开放;
		Skill ->
			{?ok, Skill}
	end.

%% 升级资金
get_rec_skill_cost(_,SkillLv) when SkillLv >= 10 ->
	throw({?error,?TIP_GUILD_NO_LEARN_SKILL});
get_rec_skill_cost(SkillId,SkillLv) ->
	case data_guild:get_guild_skill({SkillId,SkillLv}) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_guild_skill{process = Cost} ->	
			{?ok,Cost}
	end.

%% 检查升级资金
check_skill_money(Money,Cost) when Money >= Cost ->
	?ok;
check_skill_money(_,_) ->
	throw({?error,?TIP_GUILD_MONEY}).
	
%% 升级技能效果
get_rec_skill_effect(SkillId,SkillLv,GuildLv) ->
	case data_guild:get_guild_skill({SkillId,SkillLv}) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_guild_skill{guild_lv = GuildLv2} when GuildLv2 > GuildLv ->
			throw({?error,?TIP_GUILD_ARMY_LV});
		#rec_guild_skill{effect = Effect} ->
			{?ok,Effect}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 术法信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
magic_data(#player{guild = Guild,net_pid = Pid}) when is_record(Guild,guild) ->
	GuildMagic 	= Guild#guild.guild_magic,
	Packet 		= guild_api:msg_sc_magic_list(GuildMagic),
	misc_packet:send(Pid, Packet).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 个人术法升级
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
magic_up(Player = #player{guild = Guild,info = Info},MagicId) ->
	try
		GuildId 			= Guild#guild.guild_id,
		{?ok,GuildData}		= guild_api:get_guild_data(GuildId),				%% 取得GuildData
		{?ok,MagicLv,List} 	= get_key_magic(MagicId,Guild#guild.guild_magic),		
		
		{?ok,RecMagic}		= get_rec_magic(MagicId,MagicLv),
		Cost				= RecMagic#rec_guild_magic.learn,					%% 军团贡献消耗
		
		MagicLv2			= MagicLv + 1,										%% 等级加一
		{?ok,RecMagic2}		= get_rec_magic(MagicId,MagicLv2),					%% 新的术法
		RecLv				= RecMagic2#rec_guild_magic.guild_lv,
		GuildLv				= GuildData#guild_data.lv,
		?ok					= check_magic_guild_lv(RecLv,GuildLv),				%% 检查军团等级
		?ok					= check_magic_lv(Info#info.lv,MagicLv2),			%% 检查玩家等级
		{?ok,Player2}		= check_exploit(Player,Cost,?CONST_COST_GUILD_YTS),	%% 检查军团贡献
		
		GuildMagic			= [{MagicId,MagicLv2}|List],						%% 更新术法列表
		Guild2				= Guild#guild{guild_magic = GuildMagic},
		Player3				= Player2#player{guild = Guild2},
		Player4 			= player_attr_api:refresh_attr_guild_ability(Player3),  %% 更新属性
		
		Packet1 			= guild_api:msg_sc_magic_list(GuildMagic),
		Packet2				= message_api:msg_notice(?TIP_GUILD_LEVLE_UP_SUCCESS),
		misc_packet:send(Player#player.net_pid, <<Packet1/binary,Packet2/binary>>),
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_MAGIC_UP, 0, 0, 0, MagicId, MagicLv2, Cost),
		
		{?ok,Player5}		= magic_achievement(Player4,MagicId,MagicLv),
        {?ok, Player6}      = task_api:update_guild_skill(Player5), % 学习军团术法任务
        schedule_power_api:do_upgrade_guild_magic(Player6),
		magic_achieve(Player6,GuildMagic)
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 术法等级、列表
get_key_magic(MagicId,List) ->
	case lists:keytake(MagicId, 1, List) of
		?false ->
			{?ok,0,List};
		{value,{_,MagicLv},List2} ->
			{?ok,MagicLv,List2}
	end.

%% rec_magic
get_rec_magic(MagicId,MagicLv) ->
	case data_guild:get_guild_magic({MagicId,MagicLv}) of
		?null -> %% 无可学习的技能
			throw({?error,?TIP_GUILD_NO_LEARN_SKILL}); 
		RecMagic -> 	
			{?ok,RecMagic}
	end.

%% 检查军团等级
check_magic_guild_lv(RecLv,GuildLv) when RecLv > GuildLv ->
	throw({?error,?TIP_GUILD_ARMY_LV}); 
check_magic_guild_lv(_,_) -> ?ok.

%% 检查玩家等级
check_magic_lv(_Lv,MagicLv) when MagicLv > 100 ->
	throw({?error,?TIP_GUILD_NO_LEARN_SKILL}); 
check_magic_lv(Lv,MagicLv) when Lv < MagicLv ->
	throw({?error,?TIP_GUILD_USER_LV}); 
check_magic_lv(_,_) -> ?ok.
	

%% 术法成就
magic_achievement(Player,5,MagicLv) -> %% 军旗
	achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_ORIFLAMME_LEVELUP, MagicLv, 1); %% 术法成就
magic_achievement(Player,_,_MagicLv) ->
	{?ok,Player}.

magic_achieve(Player,GuildMagic) ->
	F = fun({_,Lv},Count) ->
				if
					Lv >= 30 ->
						Count + 1;
					?true -> Count
				end
		end,
	Value = lists:foldl(F, 0, GuildMagic),
	{?ok, Player}.
%%     new_serv_api:finish_achieve(Player, ?CONST_NEW_SERV_GUILD_SKILL, Value, 1).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 技能捐钱
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
skill_up_donate(Player,_,0,_) ->
	{?ok,Player};
skill_up_donate(Player = #player{user_id = UserId,guild = Guild,info = Info,net_pid = Pid},?CONST_SYS_CASH,Cash,SkillId) -> 
	try
		Name					= Info#info.user_name,
		{AddProPer, AddProGuild} = {Cash * 100, Cash*1000}, 				%% 计算增加贡献度
		?ok						= check_minus_money(UserId,?CONST_SYS_CASH,Cash),		%% 扣取金钱(先扣取啊！！！)
		{?ok,Player2,NewLv,GuildData,DBList,ETSList,
		 GuildMember2,UMemList,AddExploit}	= skill_up_donate2(Player,SkillId,AddProPer, AddProGuild), 
		Content					= guild_mod:init_guild_log(?CONST_GUILD_LOG_CASH,[{2,Info#info.user_name,UserId},
																				  {0,misc:to_list(Cash),0},
																				  {0,misc:to_list(AddExploit),0}]),
		Log						= guild_mod:add_log(GuildData#guild_data.log,Content),	%% 日志
		DBList2					= [{log,Log}|DBList],
		ETSList2				= [{#guild_data.log,Log}|ETSList],
		
		MemberList				= GuildData#guild_data.member_list,
		TipPacket 				= message_api:msg_notice(?TIP_GUILD_DONATE_CASH,[{?TIP_SYS_COMM,Name},
																			 	{?TIP_SYS_COMM,misc:to_list(Cash)}]),
		{?ok,Packet1}			= skill_data2(GuildData#guild_data.skill),
		Packet2					= guild_mod:info_packet(GuildData),	
		Packet3					= message_api:msg_notice(?TIP_GUILD_DONA_SUCCESS, [{?TIP_SYS_COMM,misc:to_list(AddExploit)}]),
		
		misc_packet:send(Pid, <<Packet1/binary,Packet2/binary,Packet3/binary>>),

		ets_api:update_element(?CONST_ETS_GUILD_DATA, Guild#guild.guild_id,ETSList2),
		guild_db_mod:update_data(Guild#guild.guild_id,DBList2),
		guild_mod:update_member(GuildMember2,UMemList),
		skill_achievement(MemberList,SkillId,NewLv),
		guild_serv:brocast2_cast(MemberList, TipPacket),								%% 元宝捐献广播
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_DONATE_CASH, Cash, 0, 0, SkillId, 0, 0),
		
        {?ok, Player3}          = task_api:update_donate(Player2), % 军团贡献任务
        ?MSG_DEBUG("SkillId is ~w, ", [SkillId]),
        if 
            ?CONST_GUILD_SKILL_TYPE_LV =:= SkillId ->
                map_api:change_guild_lv(Player3);
            ?true ->
                ?ok
        end,
		{?ok, Player3}
	catch
		throw:{?error,?TIP_COMMON_BIND_GOLD_NOT_ENOUGH} -> 
			{?ok,Player};
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;	
skill_up_donate(Player = #player{user_id = UserId,guild = Guild,info = Info,net_pid = Pid},?CONST_SYS_GOLD_BIND,Gold,SkillId) -> 
	try
		{?ok,DonateT} 			= get_donate_gold(Guild), 								%% 今天捐献铜钱
		MaxDonate 				= get_max_donate(Info#info.lv),							%% 铜钱上限
		{?ok,GoldN}				= check_max_donate(DonateT,Gold,MaxDonate),				%% 检查最大捐献上限 
		AddPro					= misc:floor(GoldN/?CONST_GUILD_DONATE_RATE),			%% 计算增加贡献度	
		
		?ok						= check_minus_money(UserId,?CONST_SYS_GOLD_BIND,GoldN), %% 扣取金钱
		{?ok,Player2,NewLv,GuildData,DBList,ETSList,
		 GuildMember2,UMemList,AddExploit}	= skill_up_donate2(Player,SkillId,AddPro,AddPro),
		
		MemberList				= GuildData#guild_data.member_list,
		DonateT2				= DonateT + GoldN,
		GuildT					= Player2#player.guild,
		Guild2					= GuildT#guild{donate_gold = DonateT2,
											   donate_time = misc:seconds()
											  },					%% 增加今日捐献铜钱
		Player3					= Player2#player{guild = Guild2},
		
		UPacket					= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_DONATE, DonateT2),
		{?ok,PacketSkill}		= skill_data2(GuildData#guild_data.skill),
		PacketInfo				= guild_mod:info_packet(GuildData),
		PacketTip				= message_api:msg_notice(?TIP_GUILD_DONA_SUCCESS, [{?TIP_SYS_COMM,misc:to_list(AddExploit)}]),
		
		misc_packet:send(Pid, <<PacketSkill/binary,PacketInfo/binary,PacketTip/binary,UPacket/binary>>),
		
		ets_api:update_element(?CONST_ETS_GUILD_DATA, Guild#guild.guild_id,ETSList),
		guild_db_mod:update_data(Guild#guild.guild_id,DBList),
		guild_mod:update_member(GuildMember2,UMemList),
		skill_achievement(MemberList,SkillId,NewLv),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_DONATE_GOLD, Gold, 0, 0, SkillId, 0, 0),
		
		{?ok, Player4}          = task_api:update_donate(Player3), % 军团贡献任务
        {?ok, Player4}
	catch
		throw:{?error,?TIP_COMMON_BIND_GOLD_NOT_ENOUGH} -> 
			{?ok,Player};
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;	
skill_up_donate(Player,_,_,_) ->
	{?ok, Player}.

skill_up_donate2(Player = #player{user_id = UserId,guild = Guild},SkillId,AddProPer, AddProGuild) ->
		GuildId					= Guild#guild.guild_id,
		{?ok,GuildMember}		= guild_api:get_guild_member(UserId),									%% 取得GuildMember
		{?ok,GuildData} 		= guild_api:get_guild_data(GuildId),									%% 取得GuildData
		case SkillId of
			?CONST_GUILD_SKILL_TYPE_LV ->
				KickMoney		= GuildData#guild_data.kick_money,
				if
					KickMoney =:= 0 ->
						skill_up_donate3(Player,SkillId,AddProGuild,GuildData,GuildMember,AddProPer, AddProGuild);
					AddProGuild >= KickMoney ->
						GuildData2 = GuildData#guild_data{kick_money = 0},
						skill_up_donate3(Player,SkillId,AddProGuild-KickMoney,GuildData2,GuildMember,AddProPer, AddProGuild);
					?true ->
						GuildData2 = GuildData#guild_data{kick_money = KickMoney - AddProGuild},
						skill_up_donate3(Player,SkillId,0,GuildData2,GuildMember,AddProPer, AddProGuild)
				end;
			_ ->
				skill_up_donate3(Player,SkillId,AddProGuild,GuildData,GuildMember,AddProPer, AddProGuild)
		end.
		
skill_up2(SkillId,GuildData) ->
        SkillList = GuildData#guild_data.skill,
        GuildLv = GuildData#guild_data.lv,
        {?ok,Skill}             = get_skill(SkillId,SkillList),                
        SkillLv                 = Skill#guild_skill.skill_lv,                                           %% 技能等级
        SkillPro                = Skill#guild_skill.skill_pro,                                          %% 技能进度
        GuildLv                 = GuildData#guild_data.lv,
        {NewLv,NewPro,_AddM}     = get_skill_lv(SkillId,GuildLv,SkillLv,SkillPro,54811),                %% {新等级,新进度,增加的总进度}
        
        Skill2                  = Skill#guild_skill{skill_lv = NewLv,skill_pro = NewPro},               %% 更新#guild_skill
        lists:keyreplace(SkillId, #guild_skill.skill_id,SkillList,Skill2).    %% 更新技能列表 

skill_up_donate3(Player = #player{guild = Guild,info = Info},SkillId,AddPro,GuildData,GuildMember,AddProPer, AddProGuild) ->	
		SkillList				= GuildData#guild_data.skill,
		{?ok,Skill}				= get_skill(SkillId,SkillList), 			   
		SkillLv					= Skill#guild_skill.skill_lv,											%% 技能等级
		SkillPro				= Skill#guild_skill.skill_pro,											%% 技能进度
		GuildLv					= GuildData#guild_data.lv,
		{NewLv,NewPro,AddM} 	= get_skill_lv(SkillId,GuildLv,SkillLv,SkillPro,AddPro), 				%% {新等级,新进度,增加的总进度}
		
		Skill2 					= Skill#guild_skill{skill_lv = NewLv,skill_pro = NewPro}, 				%% 更新#guild_skill
		SkillList2 				= lists:keyreplace(SkillId, #guild_skill.skill_id,SkillList,Skill2), 	%% 更新技能列表
		
		Money					= GuildData#guild_data.money,
		Money2					= Money + AddM,
		
		{?ok,Effect}			= get_rec_skill_effect(SkillId,NewLv,GuildLv),
		{?ok,GuildData2,DBList,ETSList}	
								= skill_new_data(GuildData,Money2,Effect,SkillId,NewLv,SkillList2,NewPro),
		
		AddExploit				= get_exploit(Info#info.exploit,AddProPer),				%% 可增加贡献
		{?ok, Player2}			= player_api:plus_exploit(Player, AddExploit, ?CONST_COST_GUILD_DONATE),			%% 增加军团贡献
	
		DonateToday				= GuildMember#guild_member.donate_today + AddProGuild,		%% 更新member信息
		DonateSum				= GuildMember#guild_member.donate_sum + AddProGuild,
		DonateMoney				= GuildMember#guild_member.donate_money + AddProGuild,
		GuildMember2			= GuildMember#guild_member{donate_today = DonateToday,
														   donate_sum 	= DonateSum,
														   donate_money = DonateMoney},

		Guild2					= Guild#guild{donate_sum = DonateSum},
		Player3					= Player2#player{guild = Guild2},
		
		UMemList				= [{donate_today,DonateToday},{donate_sum,DonateSum}],
		{?ok,Player3,NewLv,GuildData2,DBList,ETSList,GuildMember2,UMemList,AddExploit}.

%% guild_skill_mod:get_skill_lv(3,1,0,10,10).
get_skill_lv(SkillId,GuildLv,SkillLv,SkillPro,AddPro) ->
	case data_guild:get_guild_skill({SkillId,SkillLv}) of
		#rec_guild_skill{guild_lv = RecLv} when RecLv > GuildLv ->
			throw({?error,?TIP_GUILD_ARMY_LV}); %% 军团等级不够
		#rec_guild_skill{process = Process} when SkillPro + AddPro >= Process ->	
			SkillPro2 	= AddPro + SkillPro - Process,
			AddNow		= Process - SkillPro,
			get_skill_lv2(SkillId,GuildLv,SkillLv+1,SkillPro2,Process,AddNow,AddPro);
		#rec_guild_skill{process = _Process} ->
			{SkillLv,AddPro + SkillPro,0};
		_ -> 
			throw({?error,?TIP_GUILD_SKILL_FULL}) %% 技能满级 
	end.

%% guild_skill_mod:get_skill_lv(1,1,1,0,100).
get_skill_lv2(SkillId,GuildLv,SkillLv,SkillPro,Process,AddNow,AddPro) ->
	case data_guild:get_guild_skill({SkillId,SkillLv}) of
		?null ->
			{SkillLv-1,Process,AddPro - AddNow};
		#rec_guild_skill{guild_lv = RecLv} when RecLv > GuildLv ->
			{SkillLv-1,Process,AddPro - AddNow};
		#rec_guild_skill{process = RecProcess} when SkillPro >= RecProcess ->
			SkillPro2 	= SkillPro - RecProcess,
			AddNow2		= AddNow + RecProcess,
			get_skill_lv2(SkillId,GuildLv,SkillLv+1,SkillPro2,RecProcess,AddNow2,AddPro);
		_ ->
			{SkillLv,SkillPro,0}
	end.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 捐钱
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
donate(Player,_,0) -> 
	{?ok,Player};
donate(Player = #player{user_id = UserId,guild = Guild,info = Info},?CONST_SYS_CASH,Cash) -> %%捐献元宝
	try
		{?ok,GuildMember}	= guild_api:get_guild_member(UserId),					%% 取得GuildMember
 		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),		%% 取得GuildData
		?ok					= check_minus_money(UserId,?CONST_SYS_CASH,Cash),		%% 扣取金钱	
		{?ok,Player2}		= donate_success(Player,GuildData,GuildMember,?CONST_SYS_CASH,Cash),
		
		MemberList			= GuildData#guild_data.member_list,
		Name				= Info#info.user_name,
		Packet 				= message_api:msg_notice(?TIP_GUILD_DONATE_CASH,[{?TIP_SYS_COMM,Name},
																			 {?TIP_SYS_COMM,misc:to_list(Cash)}]),
		guild_serv:brocast2_cast(MemberList, Packet),								%% 元宝捐献广播
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_DONATE_CASH, Cash, 0, 0, 0, 0, 0),
		{?ok,Player2}
	catch
		throw:{?error,?TIP_COMMON_BIND_GOLD_NOT_ENOUGH} -> 
			{?ok,Player};
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
donate(Player = #player{user_id = UserId,guild = Guild,info = Info,net_pid = Pid},?CONST_SYS_GOLD_BIND,Gold) -> %%捐献铜钱
	try
		{?ok,GuildMember}	= guild_api:get_guild_member(UserId),					%% 取得GuildMember
 		{?ok,GuildData}		= guild_api:get_guild_data(Guild#guild.guild_id),		%% 取得GuildData 
		{?ok,DonateT} 		= get_donate_gold(Guild), 								%% 今天捐献铜钱
		MaxDonate 			= get_max_donate(Info#info.lv),							%% 铜钱上限

		{?ok,GoldN}			= check_max_donate(DonateT,Gold,MaxDonate),				%% 检查最大捐献上限 
		?ok					= check_minus_money(UserId,?CONST_SYS_GOLD_BIND,GoldN), %% 扣取金钱
		{?ok,Player2}		= donate_success(Player,GuildData,GuildMember,?CONST_SYS_GOLD_BIND,GoldN),
		
		DonateT2			= DonateT + GoldN,
		GuildT				= Player2#player.guild,
		Guild2				= GuildT#guild{donate_gold = DonateT2,
										   donate_time = misc:seconds()
										 },					%% 增加今日捐献铜钱
		Player3				= Player2#player{guild = Guild2},
		
		Packet				= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_GUILD_DONATE, DonateT2),
		misc_packet:send(Pid, Packet),
		admin_log_api:log_guild_operate(Player, Guild#guild.guild_id, ?CONST_GUILD_OPERATE_DONATE_GOLD, Gold, 0, 0, 0, 0, 0),
		{?ok,Player3}
	catch
		throw:{?error,?TIP_COMMON_BIND_GOLD_NOT_ENOUGH} -> 
			{?ok,Player};
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end;
donate(Player,_,_) ->
	{?ok,Player}.

%% 捐献成功
donate_success(Player = #player{info = Info,net_pid = Pid,user_id = UserId},GuildData,GuildMember,CostType,Cost) ->
	{AddProPerson, AddProGuild}	
                        = case CostType of
							  ?CONST_SYS_CASH -> {Cost * 100, Cost*1000};					%% 计算增加贡献度
							  ?CONST_SYS_GOLD_BIND ->
                                  Protmp = misc:floor(Cost/?CONST_GUILD_DONATE_RATE),
                                  {Protmp, Protmp}%% 计算增加贡献度
						  end,
							  
	AddExploit			= get_exploit(Info#info.exploit,AddProPerson),				%% 可增加贡献
	{?ok, Player2}		= player_api:plus_exploit(Player, AddExploit, ?CONST_COST_GUILD_DONATE),			%% 增加军团贡献
	
	DonateToday			= GuildMember#guild_member.donate_today + AddProPerson,		%% 更新member信息
	DonateSum			= GuildMember#guild_member.donate_sum + AddProPerson,
	DonateMoney			= GuildMember#guild_member.donate_money + AddProPerson,
	GuildMember2		= GuildMember#guild_member{donate_today = DonateToday,
												   donate_sum 	= DonateSum,
												   donate_money = DonateMoney},
	
	Money				= GuildData#guild_data.money + AddProGuild,					%% 更新guild信息
	Guild				= Player#player.guild,
	Guild2				= Guild#guild{donate_sum = DonateSum},
	Player3				= Player2#player{guild = Guild2},
 	case CostType of
		?CONST_SYS_CASH -> 
			Content		= guild_mod:init_guild_log(?CONST_GUILD_LOG_CASH,[{2,Info#info.user_name,UserId},
																		   {0,misc:to_list(Cost),0},
																		   {0,misc:to_list(AddExploit),0}]),
			Log			= guild_mod:add_log(GuildData#guild_data.log,Content),	%% 日志
			GuildData2	= GuildData#guild_data{money 	= Money,
											   log 		= Log};
		?CONST_SYS_GOLD_BIND -> 
			GuildData2	= GuildData#guild_data{money 	= Money}
	end,
	guild_mod:update_member(GuildMember2,[{donate_today,DonateToday},{donate_sum,DonateSum}]) ,
	guild_mod:update_guild(GuildData2,[{money,Money}]),
    {?ok, Player4}      = task_api:update_donate(Player3), % 军团贡献任务
	
	Packet1				= guild_mod:info_packet(GuildData2),
	Packet3				= message_api:msg_notice(?TIP_GUILD_DONA_SUCCESS, [{?TIP_SYS_COMM,misc:to_list(AddExploit)}]),
	
	misc_packet:send(Pid, <<Packet1/binary,Packet3/binary>>),
	{?ok,Player4}.

%% 可增加的军团贡献
get_exploit(Exploit,AddExploit) ->
	if
		Exploit + AddExploit > ?CONST_SYS_MAX_EXPLOIT ->
			?CONST_SYS_MAX_EXPLOIT - Exploit;
		?true ->
			AddExploit
	end.

get_donate_gold(#guild{donate_gold = Gold,donate_time = Time}) ->
	Now = misc:seconds(),
	case misc:is_same_date(Now, Time) of
		?true ->
			{?ok,Gold};
		_ ->
			{?ok,0}
	end.

get_surplus_donate_gold(#player{guild = Guild,info = Info}) ->
	{?ok,Gold} 	= get_donate_gold(Guild),
	MaxDonate 	= get_max_donate(Info#info.lv),							%% 铜钱上限
	if
		Gold >= MaxDonate -> 0;
		?true ->
			MaxDonate - Gold
	end.
	

%% 扣取金钱
check_minus_money(UserId,CostType,Cost) ->
	case player_money_api:check_money(UserId, CostType, Cost) of
		{?error,ErrorCode} ->
			throw({?error, ErrorCode});
		_ ->
			case player_money_api:minus_money(UserId,CostType,Cost,?CONST_COST_GUILD_DONATE) of  
				?ok -> ?ok;
				{?error, _ErrorCode} -> 
					throw({?error, ?TIP_COMMON_BIND_GOLD_NOT_ENOUGH})
			end
	end.
	
%% 最大捐献
get_max_donate(Lv) ->
	case data_guild:get_guild_donate(Lv) of
		 ?null -> 0;
		 #rec_guild_donate{limit = MaxDonate}  -> 
			 MaxDonate
	 end.

%% 检查最大捐献上限
check_max_donate(Total,_Copper,MaxDonate) when Total >= MaxDonate -> 	%% 超过
	throw({?error,?TIP_GUILD_DONATE_FULL});
check_max_donate(Total,Copper,MaxDonate) when  Total + Copper > MaxDonate ->
	Copper2 = MaxDonate - Total,
	{?ok,Copper2};
check_max_donate(_Total,Copper,_MaxDonate) ->
	{?ok,Copper}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 寻宝信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
shop_data(#player{guild = Guild,net_pid = Pid}) ->
	try
		GuildId			= Guild#guild.guild_id,
		{?ok,GuildData}	= guild_api:get_guild_data(GuildId),				%% 取得GuildData
		{?ok,SkillLv} 	= check_shop_skill(GuildData#guild_data.skill),		%% 寻宝技能等级		
		Packet 			= guild_api:msg_sc_treasure(SkillLv),
		misc_packet:send(Pid, Packet)
	catch
		throw:{?error,ErrorCode} -> 
			guild_api:error_message2(Pid,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
 
%% 检查寻宝技能
check_shop_skill(SkillList) ->
	case lists:keyfind(?CONST_GUILD_SKILL_TYPE_SHOP, #guild_skill.skill_id, SkillList) of
		?null ->
			throw({?error,?TIP_GUILD_NO_SKILL}); %% 还没开启
		GuildSkill ->
			SkillLv = GuildSkill#guild_skill.skill_lv,
			{?ok,SkillLv}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 军团购买
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
shop_buy(Player,GoodsId,GoodNum,BuyLv) when is_record(Player,player) ->
	try
		Guild 			= Player#player.guild,
		GuildId 		= Guild#guild.guild_id,
		{?ok,GuildData}	= guild_api:get_guild_data(GuildId),				%% 取得GuildData
		{?ok,SkillLv}	= check_shop_skill(GuildData#guild_data.skill),		%% 寻宝技能等级
		?ok				= check_buy_lv(SkillLv,BuyLv),						%% 检查购买的等级
		List			= data_guild:get_guild_tresure(BuyLv),				%% 物品列表
		
		{?ok,Cost1}		= get_cost(GoodsId,List),							%% 取得消耗值
        TowerLeaderId = guild_pvp_mod:get_tower_owner_id(),
        Cost = 
            case TowerLeaderId == GuildId of
                true ->
                    Cost1 div 2;
                _ ->
                    Cost1
            end,
		GoodsList		= goods_api:make(GoodsId, GoodNum),					%% 生成物品列表
		{?ok, Player2, PacketBag} = check_set_bag(Player,GoodsList),		%% 检查背包
		{?ok, PlayerNew}= check_exploit(Player2, Cost*GoodNum, ?CONST_COST_GUILD_BK),%% 检查军团贡献

		Packet2	 		= message_api:msg_notice(?TIP_GUILD_BUY_SUCCESS),
 		Packet 			= <<Packet2/binary,PacketBag/binary>>,
		misc_packet:send(Player#player.net_pid, Packet),	
		admin_log_api:log_guild_operate(Player, GuildId, ?CONST_GUILD_OPERATE_SHOP_BUY, 0, GoodsId, GoodNum, 0, 0, Cost),
		{?ok, PlayerNew}		
	catch
		throw:{?error,?TIP_COMMON_CTN_NOT_ENOUGH} -> %% 背包异常
			{?ok, Player};
		throw:{?error,ErrorCode} -> 
			guild_api:error_message(Player,ErrorCode);
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.

%% 检查背包
check_set_bag(Player, GoodsList) ->
    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_GOODS_USED, 1, 1, 0, 0, 0, 1, []) of
		{?error, _ErrorCode}->  			% 背包异常
			throw({?error,?TIP_COMMON_CTN_NOT_ENOUGH});
		{?ok, Player2, _, PacketBag} ->  	% 成功
			{?ok, Player2, PacketBag}
	end.

%% 检查购买等级
check_buy_lv(SkillLv,BuyLv) when BuyLv =< SkillLv -> ?ok;
check_buy_lv(_,_) ->
	throw({?error,?TIP_GUILD_NO_SKILL}). 	%% 还没开启

%% 取得消耗值
get_cost(_,[]) ->
	throw({?error,?TIP_GUILD_NO_SKILL}); 	%% 还没开启
get_cost(GoodsId,List) ->
	case lists:keyfind(GoodsId, 1, List) of
		?false ->
			throw({?error,?TIP_GUILD_NO_SKILL}); %% 还没开启
		{_,Cost} ->
			{?ok,Cost}
	end.

%% 检查军团贡献
check_exploit(Player, Cost, Point) ->
	case player_api:minus_exploit(Player, Cost, Point) of
		{?error, ErrorCode} -> throw({?error,ErrorCode}); %% 贡献不足
		{?ok, Player2} -> {?ok,Player2}
	end.


%% 自动增加资金
default_add(GuildData) -> 
	SkillList 	= GuildData#guild_data.skill,
	get_skill_add2(?CONST_GUILD_SKILL_TYPE_GROWTH,SkillList).

%% 技能增加比例
get_skill_add(UserId) -> 
	case guild_api:ets_guild_member(UserId) of
		?null -> 0;
		#guild_member{guild_id = GuildId} ->
			case guild_api:ets_guild_data(GuildId) of
				?null -> 0;
				#guild_data{skill = SkillList} ->
					get_skill_add2(?CONST_GUILD_SKILL_TYPE_COPY,SkillList)/10000
			end
	end.

get_skill_add(Player,SkillId) when is_record(Player, player) ->
	get_skill_add(Player#player.guild,SkillId);
get_skill_add(Guild,SkillId) when is_record(Guild, guild) ->
	case guild_api:ets_guild_data(Guild#guild.guild_id) of
		?null -> 0;
		#guild_data{skill = SkillList} ->
			get_skill_add2(SkillId,SkillList)/10000
	end.
			
get_skill_add2(SkillId,SkillList) ->
	case lists:keyfind(SkillId, #guild_skill.skill_id, SkillList) of
		?false ->
			0;
		#guild_skill{skill_lv = SkillLv} ->
			get_rec_skill_effect(SkillId,SkillLv)
	end.

get_rec_skill_effect(SkillId,SkillLv) ->
	case data_guild:get_guild_skill({SkillId,SkillLv}) of
		?null -> %% 无可学习的技能
			0; 
		#rec_guild_skill{effect = Effect} -> 	
			Effect
	end.
	
%%
%% Local Functions
%%

