%% Author: cobain
%% Created: 2013-4-10
%% Description: TODO: Add description to world_mod
-module(world_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([init/1]).
-export([
		 do_world_start/1, do_world_end/1,
		 do_refresh_monster/8, do_notice_refresh_monster_step/1,
		 do_invite/3, do_reply_agree/3, do_reply_reject/2,
		 do_quit/2
		]).
-export([set_hp_tuple/2, record_world_data/2, record_world_player/2]).
%%
%% API Functions
%%
%% 初始化乱天下数据
init(GuildId) ->
	WorldConfig		= data_world:get_world_config(),
	{?ok, GuildLv}	= guild_api:get_guild_lv(GuildId),
	if
		GuildLv >= WorldConfig#rec_world_config.guild_lv ->
			WorldData				= record_world_data(GuildId, WorldConfig),
			{WorldData2, Packet}	= refresh_monster(WorldData),
			world_api:set_world_data(WorldData2),
			world_api:broadcast_exist(WorldData2#world_data.guild_id, Packet),
			?ok;
		?true -> {?error, ?TIP_WORLD_GUILD_LV_NOT_ENOUGH}% 军团等级不足
	end.

do_invite(GuildId, GuildPos, UserId) ->
	case world_api:get_world_data(GuildId) of
		WorldData when is_record(WorldData, world_data) ->
			{GuildPos, Quota, HelperList}	= lists:keyfind(GuildPos, 1, WorldData#world_data.invite_quota),
			if
				length(HelperList) < Quota ->
					InviteList	= WorldData#world_data.invite,
					InviteList2	= case lists:keytake(UserId, 1, InviteList) of
									  {value, {UserId, _Seconds}, InviteListTemp} ->
										  [{UserId, misc:seconds()}|InviteListTemp];
									  ?false -> [{UserId, misc:seconds()}|InviteList]
								  end,
					WorldData2	= WorldData#world_data{invite = InviteList2},
					world_api:set_world_data(WorldData2),
					?ok;
				?true -> {?error, ?TIP_WORLD_FULL_QUOTA}% 名额已满
			end;
		_ -> {?error, ?TIP_COMMON_SYS_ERROR}
	end.

do_reply_agree(GuildId, GuildPos, UserId) ->
	case world_api:get_world_data(GuildId) of
		WorldData when is_record(WorldData, world_data) ->
			{GuildPos, Quota, HelperList}	= lists:keyfind(GuildPos, 1, WorldData#world_data.invite_quota),
			InviteList	= lists:keydelete(UserId, 1, WorldData#world_data.invite),
			WorldData2	= WorldData#world_data{invite = InviteList},
			WorldData3	=
			if
				length(HelperList) < Quota ->
					HelperList2	= case lists:member(UserId, HelperList) of
									  ?true -> HelperList;
									  ?false -> [UserId|HelperList]
								  end,
					InviteQuota	= lists:keyreplace(GuildPos, 1, WorldData#world_data.invite_quota, {GuildPos, Quota, HelperList2}),
					Reply		= ?ok,
					WorldData2#world_data{invite_quota = InviteQuota};
				?true ->% 名额已满
					Reply		= {?error, ?TIP_WORLD_FULL_QUOTA},
					WorldData2
			end,
			world_api:set_world_data(WorldData3),
			Reply;
		_ -> {?error, ?TIP_COMMON_SYS_ERROR}
	end.
do_reply_reject(GuildId, UserId) ->
	case world_api:get_world_data(GuildId) of
		WorldData when is_record(WorldData, world_data) ->
			InviteList	= lists:keydelete(UserId, 1, WorldData#world_data.invite),
			WorldData2	= WorldData#world_data{invite = InviteList},
			world_api:set_world_data(WorldData2),
			% 发送消息通知玩家
			?ok;
		_ -> {?error, ?TIP_COMMON_SYS_ERROR}
	end.

do_refresh_monster(GuildId, UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple) ->
	Seconds		= misc:seconds(),
	case world_api:get_world_base() of
		#world_base{time_start = StartTime} when Seconds >= StartTime ->
			case world_api:get_world_data(GuildId) of
				WorldData when is_record(WorldData, world_data) andalso
						   	   WorldData#world_data.step =:= Step ->
					case world_api:get_world_monster(WorldData, Step, Id) of
						{?ok, WorldMonster} when WorldMonster#world_monster.death =:= ?false ->
							do_refresh_monster2(WorldData, WorldMonster, UserId, UserName, HurtTotal, Step, Hurt, HurtTuple);
						_ -> {?error, ?TIP_WORLD_MONSTER_DEATH}% 怪物已经死亡
					end;
				_ -> {?error, ?TIP_WORLD_OVER}% 乱天下已经结束
			end;
		_ -> {?error, ?TIP_WORLD_OVER}% 乱天下已经结束
	end.

do_refresh_monster2(WorldData, WorldMonster, UserId, UserName, HurtTotal, Step, Hurt, HurtTuple) ->
	WorldMonster2	= WorldMonster#world_monster{hp_tuple = set_hp_tuple(WorldMonster#world_monster.hp_tuple, HurtTuple)},
	{
	 WorldData5, PacketRemove
	}				=
		case set_hp(WorldMonster2#world_monster.hp, Hurt) of
			0 ->% 怪物死亡
				WorldMonster3	= WorldMonster2#world_monster{hp = 0, death = ?true},
				WorldData2		= world_api:set_world_monster(WorldData, Step, WorldMonster3),
				world_api:reward_kill(WorldData#world_data.guild_id, UserId, UserName, WorldMonster3,
									  WorldData#world_data.invite_quota),
				Packet45120		= world_api:msg_sc_remove_monster(WorldMonster#world_monster.id),
%% 				world_api:broadcast_exist(WorldData2#world_data.guild_id, Packet45120),
				{
				 WorldData3, PacketMonster
				}				= refresh_monster(WorldData2),
				{WorldData3, <<Packet45120/binary, PacketMonster/binary>>};
			Hp ->% 怪物未死亡
				WorldMonster3	= WorldMonster2#world_monster{hp = Hp},
				WorldData2		= world_api:set_world_monster(WorldData, Step, WorldMonster3),
				{WorldData2, <<>>}
		end,
	{
	 WorldData6, PacketBuff
	}				= world_buff(WorldData5, UserId, UserName, HurtTotal),
	Packet			= <<PacketRemove/binary, PacketBuff/binary>>,
	world_api:broadcast_exist(WorldData6#world_data.guild_id, Packet),
	world_api:set_world_data(WorldData6),
	?ok.

%% do_notice_refresh_monster_step(GuildId)
world_buff(WorldData, UserId, UserName, HurtTotal) ->
	case data_world:get_world_buff_list(HurtTotal) of
		IdList when is_list(IdList) ->
			Max 	= lists:max(IdList),
			Buffs	= WorldData#world_data.buff,
			case lists:keyfind(Max, #world_buff.id, Buffs) of
				?false ->
					{Buffs2, Packet}	= world_buff(IdList, Buffs, UserId, UserName, [], <<>>, HurtTotal),
					{WorldData#world_data{buff = Buffs2}, Packet};
				_ ->
					{WorldData, <<>>}
			end;
		_ -> {WorldData, <<>>}
	end.

world_buff([Id|IdList], Buffs, UserId, UserName, AccBuffs, AccPacket, HurtTotal) ->
	case lists:keyfind(Id, #world_buff.id, Buffs) of
		WorldBuff when is_record(WorldBuff, world_buff)->
			world_buff(IdList, Buffs, UserId, UserName, [WorldBuff|AccBuffs], AccPacket, HurtTotal);
		?false ->
			RecWorldBuff= data_world:get_world_buff(Id),
			WorldBuff	= record_world_buff(Id, UserId, UserName, RecWorldBuff#rec_world_buff.attr_value),
%% 			Packet45340	= world_api:msg_sc_buff_notice(Id),
			Packet45342	= world_api:msg_sc_buff_info(Id),
 			Packet25300 = message_api:msg_notice(?TIP_WORLD_BUFF_NOTICE, [{UserId, UserName}], [], [{?TIP_SYS_COMM, misc:to_list(HurtTotal)}]),
			world_buff(IdList, Buffs, UserId, UserName, [WorldBuff|AccBuffs], <<AccPacket/binary, Packet45342/binary, Packet25300/binary>>, HurtTotal)
	end;
world_buff([], _Buffs, _UserId, _UserName, AccBuffs, AccPacket, _HurtTotal) ->
	{AccBuffs, AccPacket}.


do_quit(GuildId,UserId) ->
	case world_api:get_world_data(GuildId) of
		WorldData when is_record(WorldData, world_data) ->
			InviteQuota		= lists:keydelete(UserId, 1, WorldData#world_data.invite_quota),
			InviteQuota2 	= do_quit2(UserId,InviteQuota,[]),
			WorldData2		= WorldData#world_data{invite_quota = InviteQuota2},
			world_api:set_world_data(WorldData2),
			% 发送消息通知玩家
			?ok;
		_ -> {?error, ?TIP_COMMON_SYS_ERROR}
	end.

do_quit2(_UserId,[],List) ->
	List;
do_quit2(UserId,[H | L],List) ->
	case H of
		{Pos,N,InviteList} ->
			InviteList2 = lists:delete(UserId, InviteList),
			do_quit2(UserId,L,[{Pos,N,InviteList2}|List]);
		_ ->
			do_quit2(UserId,L,List)
	end.
						
			
%%
%% Local Functions
%%

refresh_monster(WorldData) ->
	WorldMonsters	= WorldData#world_data.monsters,
	case check_monsters_death(WorldMonsters#world_monsters.monsters) of
		{?true, Activate} ->
			Step		= WorldData#world_data.step,
			StepMax		= WorldData#world_data.step_max,
			StepNext	= Step + 1,
			if
				StepNext > StepMax -> {WorldData, <<>>};% 怪物已刷完
				?true ->% 怪物未刷完
					WorldMonsters2	= data_world:get_world_monster(StepNext),
					Monsters		= [WorldMonster#world_monster{id = monster_api:make_unique_id()}
									  || WorldMonster <- WorldMonsters2#world_monsters.monsters],
					WorldMonsters3	= WorldMonsters2#world_monsters{monsters = Monsters},
					WorldData2		= WorldData#world_data{step = StepNext, monster_activate = Activate, monsters = WorldMonsters3},
					case (StepNext rem 5) of
						1 ->
							Seconds		= ?CONST_WORLD_INTERVAL_REFRESH_MONSTER div ?CONST_SYS_NUMBER_THOUSAND,
							PacketTemp	= world_api:msg_sc_next_monster_notice(StepNext, Seconds),
							erlang:send_after(?CONST_WORLD_INTERVAL_REFRESH_MONSTER, self(), notice_refresh_monster_step),
							{WorldData2, PacketTemp};
						_ ->
							WorldData3	= WorldData2#world_data{monster_activate = ?true},
							PacketTemp	= world_api:msg_sc_update_monster(WorldData2),
							{WorldData3, PacketTemp}
					end
			end;
		{?false, ?null} -> {WorldData, <<>>}
	end.

check_monsters_death([#world_monster{death = ?true}|WorldMonsters]) ->
	check_monsters_death(WorldMonsters);
check_monsters_death([#world_monster{death = ?false}|_WorldMonsters]) -> {?false, ?null};
check_monsters_death([]) -> {?true, ?false};
check_monsters_death(?null) ->
	try
		?ok	= world_api:check_world_start(misc:seconds()),
		{?true, ?true}
	catch
		throw:_Return -> {?true, ?false};
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?true, ?false}
	end.

do_world_start(GuildId) ->
	do_notice_refresh_monster_step(GuildId).

do_world_end(_GuildId) ->
	?ok.

do_notice_refresh_monster_step(GuildId) ->
	Seconds		= misc:seconds(),
	case world_api:get_world_base() of
		#world_base{time_start = StartTime} when Seconds >= StartTime ->
			case world_api:get_world_data(GuildId) of
				WorldData when is_record(WorldData, world_data) ->
					% 通知客户端刷新怪物
					WorldData2		= WorldData#world_data{monster_activate = ?true},
					world_api:set_world_data(WorldData2),
					Packet45110		= world_api:msg_sc_update_monster(WorldData2),
					world_api:broadcast_exist(GuildId, Packet45110),
					?ok;
				_ -> {?error, ?TIP_WORLD_OVER}% 乱天下已经结束
			end;
		_ -> {?error, ?TIP_WORLD_OVER}% 乱天下已经结束
	end.



set_hp(0, _Hurt) -> 0;
set_hp(Hp, 0) -> Hp;
set_hp(Hp, Hurt) -> misc:betweet(Hp - Hurt, 0, Hp).

set_hp_tuple({Hp1, Hp2, Hp3, Hp4, Hp5, Hp6, Hp7, Hp8, Hp9},
			 {Hurt1, Hurt2, Hurt3, Hurt4, Hurt5, Hurt6, Hurt7, Hurt8, Hurt9}) ->
	{
	 set_hp(Hp1, Hurt1), set_hp(Hp2, Hurt2), set_hp(Hp3, Hurt3),
	 set_hp(Hp4, Hurt4), set_hp(Hp5, Hurt5), set_hp(Hp6, Hurt6),
	 set_hp(Hp7, Hurt7), set_hp(Hp8, Hurt8), set_hp(Hp9, Hurt9)
	}.

record_world_data(GuildId, WorldConfig) ->
	GuildName		= guild_api:get_guild_name(GuildId),
	StepMax			= data_world:get_world_monster_steps(),
	WorldMonsters	= record_world_monsters(),
	InviteQuota		= init_invite_quota(WorldConfig),
	#world_data{
				guild_id		= GuildId,		% 军团ID
				guild_name		= GuildName,	% 军团名称
				pid				= self(),		% 军团对应的乱天下进程Pid
				step			= 0,			% 当前进度(当前波数)
				step_max		= StepMax,		% 怪物总波数
				monster_activate= ?false,		% 怪物激活标示(true:已激活|false:未激活)
				monsters		= WorldMonsters,% 当前波怪物列表
				buff			= [],			% 犒赏三军属性加成列表
				invite_quota	= InviteQuota,	% 邀请名额列表[{Pos, Quota, []}]
				invite			= [] 			% 邀请列表[UserId, UserId, UserId...]
			   }.

record_world_monsters() ->
	#world_monsters{
					reward_exp					= 0,		% 奖励经验
					reward_goods				= [],		% 奖励物品
					monsters					= ?null		% 怪物列表
				   }.
%% 初始化邀请名额列表
init_invite_quota(WorldConfig) ->
	[
	 {?CONST_GUILD_POSITION_CHIEF, WorldConfig#rec_world_config.invite_count_1, []},
	 {?CONST_GUILD_POSITION_VICE_CHIEF, WorldConfig#rec_world_config.invite_count_2, []},
	 {?CONST_GUILD_POSITION_ELDER, WorldConfig#rec_world_config.invite_count_3, []}
	].

record_world_player(Player, Belong) ->
	Info		= Player#player.info,
	GuildId		= (Player#player.guild)#guild.guild_id,
	#world_player{
				  user_id		= Player#player.user_id,		% 玩家id
				  belong		= Belong,						% 归属军团
				  guild_id		= GuildId,						% 玩家所属军团
				  user_name 	= Info#info.user_name,			% 玩家名称
				  lv			= Info#info.lv,					% 玩家等级
				  vip			= player_api:get_vip_lv(Info),				% VIP等级
%% 				  buff			= {0, []},						% 犒赏三军属性加成
				  hurt			= 0,							% 伤害
				  kill			= 0,							% 累积杀怪数量
				  reward_kill	= 0,							% 累积伤害奖励
				  auto			= ?CONST_SYS_FALSE,				% 自动战斗(0:否|1:是)
				  cd_death		= 0,							% 死亡复活CD
				  cd_exit		= 0, 							% 退出CD
				  exist			= ?CONST_SYS_TRUE				% 存在(0:是|1:否)
				 }.

%% 乱天下BUFF
record_world_buff(Id, Uid, Name, Value) ->
	Buff		= [{?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_FORCE_ATTACK, Value},
				   {?CONST_SYS_CALC_TYPE_MULTI, ?CONST_PLAYER_ATTR_MAGIC_ATTACK, Value}],
	ValueStr	= misc:to_list(Value div ?CONST_SYS_NUMBER_HUNDRED),
	#world_buff{
				id				= Id,		% BUFFID
				founder_uid		= Uid,		% 创始人Uid
				founder_name	= Name,		% 创始人名字
				buff			= Buff,		% BUFF列表
				value			= ValueStr	% 加成值
			   }.