%% Author: cobain
%% Created: 2013-4-10
%% Description: TODO: Add description to world_api
-module(world_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.map.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([on/1, off/1, world_start/0, world_interval/0]).
-export([
		 enter/1, invite/2, reply/5, battle_start/3,
		 refresh_monster/4, refresh_monster_cb/2,
		 battle_over/3, battle_over_cb/2,init_world_player/2,
		 auto_revive/1, quit/1, login_packet/2, logout/1
		]).
-export([broadcast/2, broadcast_exist/2, broadcast_world_exist/1]).
-export([reward_kill/5, world_end_cb/2, flush_offline/2]).
-export([
		 check_world_open/0, 	check_world_start/1,
		 check_guild/1, 		check_world_player/1,
		 check_world_monster/3, check_cd_exit/2,
		 check_cd_death/2
		]).
-export([
		 get_world_base/0,		set_world_base/1,		del_world_base/0,
		 get_world_data/1,		set_world_data/1,		del_world_data/1,
		 get_world_player/1,	set_world_player/1,		del_world_player/1,
		 get_world_monster/3,	set_world_monster/3,	get_pid/1,
		 get_world_map_pid/1,	set_world_map_pid/2
		]).
-export([
		 msg_sc_enter/2,
		 msg_sc_update_monster/1,
		 msg_sc_remove_monster/1,
		 msg_sc_exit_cd/1,
		 msg_sc_update_hurt/1,
		 msg_sc_rank_guild/1,
		 msg_sc_rank_player/1,
		 msg_sc_start/0,
		 msg_sc_end/0,
		 msg_sc_buff_notice/1,
		 msg_sc_buff_info/1,
		 msg_sc_invite_notice/5,
		 msg_sc_next_monster_notice/2,
		 msg_sc_leader_notice/1,
		 msg_sc_world_robot/1
		]).
%%
%% API Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
on([]) ->
	try
		clean_world_ets(),
		crond_api:interval_del(world_interval),
		WorldConfig		= data_world:get_world_config(),
		Seconds			= misc:seconds(),
		TimeStart		= Seconds + WorldConfig#rec_world_config.time_start,
		MapData 		= data_map:get_map(WorldConfig#rec_world_config.map_id),
		WorldBase		= #world_base{
									  map_id 		= MapData#rec_map.map_id,
									  x				= MapData#rec_map.x,								% X
									  y				= MapData#rec_map.y,								% Y
									  time_start	= TimeStart,										% 开始时间戳
									  time_end		= TimeStart + WorldConfig#rec_world_config.time_end	% 结束时间戳
									 },
		set_world_base(WorldBase),
		crond_api:interval_add(world_start, 1, world_api, world_start, []),
		crond_api:interval_add(world_robot_move, 5, robot_world_api, move, [])
	catch
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

clean_world_ets() ->
	ets:delete_all_objects(?CONST_ETS_WORLD_BASE),
	ets:delete_all_objects(?CONST_ETS_WORLD_DATA),
	ets:delete_all_objects(?CONST_ETS_WORLD_PLAYER).

world_start() ->
	try
		Seconds			= misc:seconds(),
		WorldBase		= get_world_base(),
		if
			Seconds >= WorldBase#world_base.time_start ->
				world_sup:world_start(),
				broadcast_world_exist(msg_sc_start()),
				crond_api:interval_del(world_start),
				crond_api:interval_del(world_robot_move),
				crond_api:interval_add(world_interval, 1, world_api, world_interval, []),
				crond_api:interval_add(world_robot_move, 5, robot_world_api, move, []);
			?true -> ?ok
		end
	catch
		Error:Reason ->
			crond_api:interval_del(world_start),
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

off([]) ->
	try
		world_end(),
		world_sup:world_end(),
		clean_world_ets(),
		crond_api:interval_del(world_interval),
		crond_api:interval_del(world_start),
		crond_api:interval_del(world_robot_move)
	catch
		Error:Reason ->
			crond_api:interval_del(world_interval),
			crond_api:interval_del(world_start),
			crond_api:interval_del(world_robot_move),
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
world_end() ->
	Packet45330		= msg_sc_end(),
	robot_world_api:exit(),
	MatchSpec		= ets:fun2ms(fun(#world_data{guild_id = GuildId, guild_name	= GuildName, step = Step}) ->
										 {GuildId, GuildName, Step}
								 end),
	List			= ets_api:select(?CONST_ETS_WORLD_DATA, MatchSpec),
	{GuildData, _}	= lists:mapfoldl(fun({GuildId, GuildName, Step}, AccIdx) ->
											 {{GuildId, GuildName, Step, AccIdx}, AccIdx + 1}
									 end, 1, sort2(List)),
	GuildTop		= if length(GuildData) >= 3 -> {Top, _} = lists:split(3, GuildData), Top; ?true -> GuildData end,
	
	case [{?TIP_SYS_COMM, misc:to_list(GuildName)} || {_GuildId, GuildName, _Step, _Idx} <- GuildTop] of
		[] -> ?ok;
		ReserveList ->
			PacketGuildRank	= message_api:msg_notice(?TIP_WORLD_RANK_GUILD_NOTICE, [], [], ReserveList),
			misc_app:broadcast_world(PacketGuildRank)
	end,
	world_end2(GuildData, Packet45330).
world_end2([{GuildId, _GuildName, Step, Idx}|GuildList], Packet45330) ->
	{?ok, ChiefUid}	= guild_api:get_guild_chief_id(GuildId),
	WorldMonsters	= data_world:get_world_monster(Step),
	Exp				= WorldMonsters#world_monsters.reward_exp,
	GoodsDatas		= WorldMonsters#world_monsters.reward_goods,
	GoodsList		= lists:foldl(fun({GoodsId, Bind, Count}, Acc) ->
										  GoodsListTemp	= goods_api:make(GoodsId, Bind, Count),
										  GoodsListTemp ++ Acc
								  end, [], GoodsDatas),
	Packet45370		= case GoodsList of [] -> <<>>; _ -> msg_sc_leader_notice(Step) end,
	misc_packet:send(ChiefUid, Packet45370),
	guild_api:add_guild_goods(GuildId, GoodsList),
	WorldConfig		= data_world:get_world_config(),
	RatioExploit	= WorldConfig#rec_world_config.ratio_exploit,
	
	MS				= ets:fun2ms(fun(#world_player{user_id = UserId, belong = GuildIdTemp, user_name = UserName,
												   hurt = Hurt, kill = KillCount, reward_kill = RewardKill, exist = Exist})
									  when GuildId =:= GuildIdTemp -> {UserId, UserName, Hurt, KillCount, RewardKill, Exist}
								 end),
	List			= ets_api:select(?CONST_ETS_WORLD_PLAYER, MS),
	L				= sort(List),
	PlayerTop		= if length(L) >= 3 -> {Top, _} = lists:split(3, L), Top; ?true -> L end,
	UserList		= [{UserId, UserName} || {UserId, UserName, _Hurt, _, _RewardKill, _Exist} <- PlayerTop],
	PacketPlayerRank= message_api:msg_notice(?TIP_WORLD_RANK_PLAYER_NOTICE, UserList, [], []),
	world_end3(L, Step, Idx, Exp, RatioExploit, Packet45330, PacketPlayerRank),
	world_end2(GuildList, Packet45330);
world_end2([], _Packet45330) -> ?ok.
	
world_end3([{UserId, _UserName, Hurt, KillCount, RewardKill, Exist}|L], Step, GuildIdx, Exp, RatioExploit, Packet45330, PacketPlayerRank) ->
	Exploit			= Hurt div RatioExploit,
	Packet45380		= msg_reward_info(Step, GuildIdx, KillCount, Hurt, Exp, RewardKill, Exploit),
	Packet			= case Exist of
						  ?CONST_SYS_TRUE -> <<Packet45330/binary, PacketPlayerRank/binary, Packet45380/binary>>;
						  ?CONST_SYS_FALSE -> <<PacketPlayerRank/binary, Packet45380/binary>>
					  end,
	case player_api:check_online(UserId) of
		?true -> 
			player_api:process_send(UserId, ?MODULE, world_end_cb, {Exp, RewardKill, Exploit, Hurt, KillCount, Packet});% 在线玩家
		?false -> 
			robot_world_api:send_reward(UserId, RewardKill, Exploit, Hurt, KillCount),
			player_offline_api:offline(?MODULE, UserId, {misc:seconds(), Exp, Exploit})% 离线玩家
	end,
	world_end3(L, Step, GuildIdx, Exp, RatioExploit, Packet45330, PacketPlayerRank);
world_end3([], _Step, _GuildIdx, _Exp, _RatioExploit, _Packet45330, _PacketPlayerRank) -> ?ok.
	
world_end_cb(Player, {Exp, RewardKill, Exploit, Hurt, KillCount, Packet}) ->
	UserId				= Player#player.user_id,
%% 	RobotList			= [19],
	RobotList			= robot_world_api:get_world_robot_list(),
	case lists:member(UserId, RobotList) of
		?true ->
			robot_world_api:send_reward(UserId, RewardKill, Exploit, Hurt, KillCount),
			admin_log_api:log_world(UserId, Hurt, KillCount, Exploit, RewardKill, 1),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player1} = schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_WORLD);
		?false ->
			admin_log_api:log_world(UserId, Hurt, KillCount, Exploit, RewardKill, 0),
			misc_packet:send(Player#player.net_pid, Packet),
			Player1 = Player
	end,
	{?ok, Player2} = guild_api:plus_exploit(Player1, Exploit, ?CONST_COST_WORLD_REWARD_HURT),
	player_api:exp(Player2, Exp).

%% 离线接口
flush_offline(Player, {Exp, Exploit}) ->
	admin_log_api:log_world(Player#player.user_id, 0, 0, Exploit, 0, 3),
	{?ok, Player2}	= guild_api:plus_exploit(Player, Exploit, ?CONST_COST_WORLD_REWARD_HURT),
	player_api:exp(Player2, Exp);
%% 之前的离线接口没有考虑机器人完成获得活跃度，但为了兼容旧数据上个接口要保留
flush_offline(Player, {Time, Exp, Exploit}) ->
	Now = misc:seconds(),
	{?ok, Player1} =
		case misc:is_same_date(Now, Time) of
			?true ->
				schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_WORLD);
			?false ->
				{?ok, Player}
		end,
	admin_log_api:log_world(Player1#player.user_id, 0, 0, Exploit, 0, 3),
	{?ok, Player2}	= guild_api:plus_exploit(Player, Exploit, ?CONST_COST_WORLD_REWARD_HURT),
	player_api:exp(Player2, Exp);
flush_offline(Player, Arg) ->
	?MSG_ERROR("flush_offline(Player, Arg) Arg:~p", [Arg]),
	{?ok, Player}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

world_interval() ->
	try
		Time			= misc:seconds(),
		robot_world_api:init_robot_enter_world(),
		if
			Time rem ?CONST_WORLD_INTERVAL_RANK =:= 0 ->
				{GuildIdList, GuildTop, _GuildRank}	= world_guild_rank(),
				Packet45300	= msg_sc_rank_guild(GuildTop),
				PlayerList	= world_player_rank(GuildIdList, []),
				F			= fun({GuildId, PlayerTop, _PlayerRank}) ->
									  Packet45310	= msg_sc_rank_player(PlayerTop),
									  broadcast_exist(GuildId, <<Packet45300/binary, Packet45310/binary>>)
							  end,
				[F(X) || X <- PlayerList];
			?true -> ?ok
		end,
		if
			Time rem ?CONST_WORLD_INTERVAL_UPDATE_MONSTER =:= 0 ->
				MatchSpec		= ets:fun2ms(fun(#world_data{guild_id 			= GuildId,
															 step 				= Step,
															 monster_activate	= MonsterActivate,
															 monsters 			= WorldMonsters}) ->
													 {GuildId, MonsterActivate, Step, WorldMonsters}
											 end),
				MonsterList		= ets_api:select(?CONST_ETS_WORLD_DATA, MatchSpec),
				Fun			= fun({GuildId, MonsterActivate, Step, WorldMonsters}) ->
									  Monsters		= WorldMonsters#world_monsters.monsters,
									  Packet45110	= msg_sc_update_monster(Step, MonsterActivate, Monsters),
									  broadcast_exist(GuildId, Packet45110)
							  end,
				[Fun(Y) || Y <- MonsterList];
			?true -> ?ok
		end
	catch
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

world_guild_rank() ->
	MatchSpec	= ets:fun2ms(fun(#world_data{guild_id 	= GuildId,
											 guild_name	= GuildName,
											 step		= Step}) ->
									 {GuildId, {GuildName, Step}}
							 end),
	{
	 GuildIdList, List
	}			= lists:unzip(ets_api:select(?CONST_ETS_WORLD_DATA, MatchSpec)),
	L			= sort(List),
	Top3		= if length(L) >= 3 -> {Top, _} = lists:split(3, L), Top; ?true -> L end,
	{GuildIdList, Top3, L}.


world_player_rank([GuildId|GuildIdList], Acc) ->
	{GuildId, Top10, L}	= world_player_rank(GuildId),
	world_player_rank(GuildIdList, [{GuildId, Top10, L}|Acc]);
world_player_rank([], Acc) -> Acc.

world_player_rank(GuildId) ->
	MS			= ets:fun2ms(fun(#world_player{user_id = UserId, belong = GuildIdTemp, user_name = UserName, hurt = Hurt})
								  when GuildId =:= GuildIdTemp -> {UserName, Hurt}
							 end),
	List		= ets_api:select(?CONST_ETS_WORLD_PLAYER, MS),
	L			= sort(List),
	Top10		= if length(L) >= 10 -> {Top, _} = lists:split(10, L), Top; ?true -> L end,
	{GuildId, Top10, L}.

%% 快速排序
sort([{Key, Value}|L]) ->
	sort([{GTKey, GTValue} || {GTKey, GTValue} <- L, GTValue >= Value])
		++ [{Key, Value}] ++
	sort([{LTKey, LTValue} || {LTKey, LTValue} <- L, LTValue <  Value]);
sort([{UserId, UserName, Hurt}|L]) ->
	sort([{GTUserId, GTUserName} || {GTUserId, GTUserName, GTHurt} <- L, GTHurt >= Hurt])
		++ [{UserId, UserName}] ++
	sort([{LTUserId, LTUserName} || {LTUserId, LTUserName, LTHurt} <- L, LTHurt <  Hurt]);
%% sort([]) -> [];
sort([{UserId, UserName, Hurt, KillCount, RewardKill, Exist}|L]) ->
	sort([{GTUserId, GTUserName, GTHurt, GTKillCount, GTRewardKill, GTExist}
		 || {GTUserId, GTUserName, GTHurt, GTKillCount, GTRewardKill, GTExist} <- L, GTHurt >= Hurt])
		++ [{UserId, UserName, Hurt, KillCount, RewardKill, Exist}] ++
	sort([{LTUserId, LTUserName, LTHurt, LTKillCount, LTRewardKill, LTExist}
		 || {LTUserId, LTUserName, LTHurt, LTKillCount, LTRewardKill, LTExist} <- L, LTHurt <  Hurt]);
sort([]) -> [].

sort2([{GuildId, GuildName, Step}|L]) ->
	sort2([{GTGuildId, GTGuildName, GTStep} || {GTGuildId, GTGuildName, GTStep} <- L, GTStep >= Step])
		++ [{GuildId, GuildName, Step}] ++
	sort2([{LTGuildId, LTGuildName, LTStep} || {LTGuildId, LTGuildName, LTStep} <- L, LTStep <  Step]);
sort2([]) -> [].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 请求进入乱天下
enter(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_WORLD) of
		{?true, Player2} ->
			case check_enter_world(Player) of
				{?ok, WorldBase, WorldData, WorldPlayer} ->
					admin_log_api:log_campaign(Player#player.user_id, Player#player.account, (Player#player.info)#info.lv, ?CONST_ACTIVE_WORLD, misc:seconds()),
					?true		= set_world_player(WorldPlayer),
					Player3		= map_api:enter_map(Player2, WorldBase#world_base.map_id, WorldData#world_data.guild_id),
					Packet45100	= msg_sc_enter(WorldBase, WorldData),
					Packet45110	= msg_sc_update_monster(WorldData),
					Packet45140	= msg_sc_update_hurt(WorldPlayer#world_player.hurt),
%% 					Packet45340	= msg_sc_buff_notice(WorldData),
					Packet45342	= msg_sc_buff_info(WorldData),
					Packet		= <<Packet45100/binary, Packet45110/binary, Packet45140/binary, Packet45342/binary>>,
					misc_packet:send(Player#player.net_pid, Packet),
					schedule_api:add_resource_times(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_WORLD),
					achievement_api:add_achievement(Player3, ?CONST_ACHIEVEMENT_GUILD_SIEGE, 0, 1);
				{?error, ErrorCode} ->
					Packet = message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, Player}
			end;
		{?false, Player, Tips} ->
			Packet = message_api:msg_notice(Tips),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

check_enter_world(Player) ->
	try
		{?ok, WorldBase}= check_world_open(),
		{?ok, GuildId}	= check_guild(Player),
		?ok				= check_robot(Player),
		WorldPlayer		= init_world_player(Player, GuildId),
		?ok				= check_cd_exit(misc:seconds(), WorldPlayer#world_player.cd_exit),
		case get_pid(GuildId) of
			{?ok, _Pid} ->
				WorldData	= get_world_data(GuildId),
				{?ok, WorldBase, WorldData, WorldPlayer};
			{?error, ErrorCode} ->
				{?error, ErrorCode}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

check_robot(Player) ->
	RobotList			= robot_world_api:get_world_robot_list(),
	case lists:member(Player#player.user_id, RobotList) of
		?true  -> throw({?error, ?TIP_WORLD_NO_ENTER});
		?false -> ?ok
	end.

%% 初始化乱天下玩家数据
init_world_player(Player, GuildId) ->
	WorldPlayer	=
		case get_world_player(Player#player.user_id) of
			WorldPlayerTemp when is_record(WorldPlayerTemp, world_player) ->
				case  WorldPlayerTemp#world_player.belong of
					GuildId -> WorldPlayerTemp;
%% 					_ -> WorldPlayerTemp#world_player{belong = GuildId, buff = {0, []}, hurt = 0, kill = 0}
					_ -> WorldPlayerTemp#world_player{belong = GuildId, hurt = 0, kill = 0}
				end;
			?null -> world_mod:record_world_player(Player, GuildId)
		end,
	WorldPlayer#world_player{exist = ?CONST_SYS_TRUE}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
invite(Player, UserId) ->
	case check_world_invite(Player, UserId) of
		{?ok, GuildPos, WorldData} ->
			case world_serv:invite_call(WorldData#world_data.pid, GuildPos, UserId) of
				?ok ->% 邀请成功
					LeaderId		= Player#player.user_id,
					LeaderName		= (Player#player.info)#info.user_name,
					Packet45350		= msg_sc_invite_notice(WorldData#world_data.guild_id,
														   WorldData#world_data.guild_name,
														   GuildPos, LeaderId, LeaderName),
					misc_packet:send(UserId, Packet45350),
					PacketSuccess	= message_api:msg_notice(?TIP_WORLD_INVITE_SUCCESS),
					misc_packet:send(Player#player.net_pid, PacketSuccess),
					?ok;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

check_world_invite(Player, UserId) ->
	try
		{?ok, _WorldBase}	= check_world_open(),
		
		?ok					= check_invite_member(UserId),
		{?ok, WorldPlayer}	= check_world_player(Player#player.user_id), 
		Result				= ?ok,
%% 			case get_world_player(UserId) of
%% 				#world_player{exist = ?CONST_SYS_TRUE} -> {?error, ?TIP_WORLD_IN_OTHER_GUILD};% 已在其他军团活动中
%% 				#world_player{cd_exit = CDExit} -> check_cd_exit(misc:seconds(), CDExit);% 检查退出冷却时间
%% 				_ -> ?ok
%% 			end,
		case Result of
			?ok ->
				WorldData		= get_world_data(WorldPlayer#world_player.belong),
				{?ok, GuildPos}	= check_guild_pos_quota(Player, WorldData),
				?ok				= check_had_invite(WorldPlayer#world_player.belong,UserId),
				case check_invite(WorldData, UserId) of
					?true -> {?error, ?TIP_WORLD_REPEAT_INVITE};% 已有有效邀请
					?false -> {?ok, GuildPos, WorldData}
				end;
			{?error, ErrorCode} -> {?error, ErrorCode}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

check_had_invite(Belong,UserId) ->
	case get_world_player(UserId) of
		#world_player{exist = ?CONST_SYS_FALSE} -> ?ok;
		#world_player{belong = Belong} -> 
			throw({?error,?TIP_WORLD_MEM_JION}); 		%% 对方已加入
		_ -> 
			?ok
	end.
						
check_invite_member(UserId) ->
	case player_api:check_online(UserId) of
		?true -> 
			RobotList			= robot_world_api:get_world_robot_list(),
			RobotFlag			= lists:member(UserId, RobotList),
			 case player_api:get_player_fields(UserId, [#player.guild,#player.user_state,#player.play_state]) of
        		{?ok, [#guild{guild_id = GuildId},UserState,PlayState]} ->
					if
						GuildId =:= 0 ->
							throw({?error,?TIP_WORLD_MEM_GUILD_NULL}); %% 对方没加入军团
						UserState =:= ?CONST_PLAYER_STATE_FIGHTING ->
							throw({?error,?TIP_WORLD_MEM_FIGHT}); 		%% 对方在战斗中 
						PlayState =:= ?CONST_PLAYER_PLAY_SINGLE_COPY orelse 
							PlayState =:= ?CONST_PLAYER_PLAY_MULTI_COPY -> %% 对方在副本中
							throw({?error,?TIP_WORLD_MEM_COPY});
						RobotFlag =:= ?true ->								%% 对方已设置替身
							throw({?error, ?TIP_WORLD_MEM_ROBOT});
						?true -> ?ok
					end;			 
				_ ->
					throw({?error,?TIP_WORLD_MEM_OFFLINE})  %% 对方不在线
			end;
		?false -> 
			throw({?error,?TIP_WORLD_MEM_OFFLINE}) %% 对方不在线
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reply(Player, GuildId, GuildPos, _LeaderId, ?CONST_WORLD_REPLY_AGREE) ->% 同意
	case check_reply_agree(Player, GuildId, GuildPos) of
		{?ok, WorldBase, WorldData, WorldPlayer} ->
			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_WORLD) of
				{?true, Player2} ->
					case world_serv:reply_agree_call(WorldData#world_data.pid, GuildPos, Player#player.user_id) of
						?ok ->
							?true		= set_world_player(WorldPlayer),
							Player3		= map_api:enter_map(Player2, WorldBase#world_base.map_id, WorldData#world_data.guild_id),
							Packet45100	= msg_sc_enter(WorldBase, WorldData),
							Packet45110	= msg_sc_update_monster(WorldData),
							Packet45140	= msg_sc_update_hurt(WorldPlayer#world_player.hurt),
%% 							Packet45340	= msg_sc_buff_notice(WorldData),
							Packet45342	= msg_sc_buff_info(WorldData),
							
 							Packet5098	= map_api:msg_cs_change_info_state(Player#player.user_id, ?CONST_PLAYER_STATE_NORMAL),							
							Packet		= <<Packet45100/binary, Packet45110/binary, Packet45140/binary, Packet45342/binary,Packet5098/binary>>,
							misc_packet:send(Player3#player.net_pid, Packet),
 							{_, Player4} 	= player_state_api:try_set_state(Player3, ?CONST_PLAYER_STATE_NORMAL),
							{?ok, Player4};
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?false, Player, Tips} ->
					Packet = message_api:msg_notice(Tips),
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, Player}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
reply(Player, GuildId, _GuildPos, LeaderId, ?CONST_WORLD_REPLY_REJECT) ->% 拒绝
	case check_reply_reject(Player, GuildId) of
		{?ok, WorldData} ->
			UserId		= Player#player.user_id,
			UserName	= (Player#player.info)#info.user_name,
			Packet 		= message_api:msg_notice(?TIP_WORLD_REPLY_REJECT_NOTICE, [{UserId, UserName}], [], []),
			misc_packet:send(LeaderId, Packet),
			world_serv:reply_reject_cast(WorldData#world_data.pid, Player#player.user_id),
			{?ok, Player};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

check_reply_agree(Player, GuildId, GuildPos) ->
	try
		{?ok, WorldBase}= check_world_open(),
		{?ok, _GuildId}	= check_guild(Player),
		WorldPlayer		= init_world_player(Player, GuildId),
%% 		?ok				= check_cd_exit(misc:seconds(), WorldPlayer#world_player.cd_exit),
		WorldData		= get_world_data(GuildId),
		case check_invite(WorldData, Player#player.user_id) of
			?true ->
				{GuildPos, Quota, HelperList}	= lists:keyfind(GuildPos, 1, WorldData#world_data.invite_quota),
				if
					length(HelperList) < Quota ->
 						WorldPlayer2 	= WorldPlayer#world_player{cd_death = 0,exist = ?CONST_SYS_TRUE}, 
						{?ok, WorldBase, WorldData, WorldPlayer2};
					?true -> {?error, ?TIP_WORLD_FULL_QUOTA}% 名额已满
				end;
			?false -> {?error, ?TIP_WORLD_INVITE_TIMEOUT}% 邀请过期
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} 
	end.

check_reply_reject(Player, GuildId) ->
	try
		{?ok, _WorldBase}= check_world_open(),
		WorldData		= get_world_data(GuildId),
		check_invite(WorldData, Player#player.user_id),
		{?ok, WorldData}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
battle_start(Player, Step, Id) ->
	Seconds		= misc:seconds(),
	case check_battle_start(Player, Step, Id, Seconds) of
		{?ok, WorldData, WorldPlayer, WorldMonster} ->
%% 			{_Id, Buff}		= WorldPlayer#world_player.buff,
			Buff	= case WorldData#world_data.buff of [#world_buff{buff = BuffTemp}|_] -> BuffTemp; _ -> [] end,
			case battle_api:start(Player, WorldMonster#world_monster.monster_id,
								  #param{battle_type	= ?CONST_BATTLE_WORLD,
										 attr 			= Buff,
										 ad1			= WorldData#world_data.step,
										 ad2 			= WorldMonster#world_monster.id,
										 ad3 			= WorldMonster#world_monster.hp_tuple,
										 ad4 			= WorldPlayer#world_player.auto}) of
				{?ok, Player2} ->
					WorldBase		= get_world_base(),
					%% 完成活跃度
					{?ok, Player3}	= schedule_api:add_guide_times(Player2, ?CONST_SCHEDULE_GUIDE_WORLD),
					map_api:teleport(Player3, WorldBase#world_base.x, WorldBase#world_base.y);
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

check_battle_start(Player, Step, Id, Seconds) ->
	try
		?ok					= check_world_start(Seconds),
		{?ok, WorldPlayer}	= check_world_player(Player#player.user_id),
		?ok					= check_cd_death(Seconds, WorldPlayer#world_player.cd_death),
		case get_world_data(WorldPlayer#world_player.belong) of
			WorldData when is_record(WorldData, world_data) ->
				{?ok, WorldMonster}	= check_world_monster(WorldData, Step, Id),
				{?ok, WorldData, WorldPlayer, WorldMonster};
			_ -> {?error, ?TIP_COMMON_SYS_ERROR}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
refresh_monster(UserId, Step, Id, HurtTuple) ->
	try
		case check_refresh_monster(UserId, Step, Id) of
			{?ok, _WorldData, _WorldPlayer, WorldMonster} ->
				case HurtTuple of
					{0,0,0,0,0,0,0,0,0} -> WorldMonster#world_monster.hp_tuple;
					_ ->
						RobotList			= robot_world_api:get_world_robot_list(),
%% 						RobotList			= [19],
						case lists:member(UserId, RobotList) of 
							?true  -> robot_world_api:refresh_monster_cb(UserId, {Step, Id, HurtTuple});
							?false ->
								player_api:process_send(UserId, ?MODULE, refresh_monster_cb, {Step, Id, HurtTuple})
						end,
						world_mod:set_hp_tuple(WorldMonster#world_monster.hp_tuple, HurtTuple)
				end;
			{?error, _ErrorCode} -> erlang:make_tuple(9, 0, [])
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

refresh_monster_cb(Player, {Step, Id, HurtTuple}) ->
	UserId		= Player#player.user_id,
	UserName	= (Player#player.info)#info.user_name,
	case check_refresh_monster(UserId, Step, Id) of
		{?ok, WorldData, WorldPlayer, _WorldMonster} ->
			Hurt		= lists:sum(misc:to_list(HurtTuple)),
			HurtTotal	= WorldPlayer#world_player.hurt + Hurt,
			Datas		= [{#world_player.hurt, HurtTotal}],
			ets_api:update_element(?CONST_ETS_WORLD_PLAYER, UserId, Datas),
			world_serv:refresh_monster_cast(WorldData#world_data.pid, WorldData#world_data.guild_id,
											UserId, UserName, HurtTotal, Step, Id, Hurt, HurtTuple),
			{?ok, Player};
		{?error, _ErrorCode} ->
			{?ok, Player}
	end.
check_refresh_monster(UserId, Step, Id) ->
	try
		?ok					= check_world_start(misc:seconds()),
		{?ok, WorldPlayer}	= check_world_player(UserId),
		case get_world_data(WorldPlayer#world_player.belong) of
			WorldData when is_record(WorldData, world_data) ->
				{?ok, WorldMonster}	= check_world_monster(WorldData, Step, Id),
				{?ok, WorldData, WorldPlayer, WorldMonster};
			_ -> {?error, ?TIP_COMMON_SYS_ERROR}
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
battle_over(UserId, Result, #param{battle_type = ?CONST_BATTLE_WORLD, robot = Robot}) ->
	case lists:member(UserId, Robot) of
		?true -> case player_api:get_player_first(UserId) of
					 {?ok, Player, _} -> battle_over_cb(Player, [Result, Robot]);
					 _ -> robot_world_api:update_robot_state(UserId, 0),
						  ?ok
				 end;
		?false ->
			player_api:process_send(UserId, ?MODULE, battle_over_cb, [Result, Robot])
	end;
battle_over(_UserId, _Result, _BattleParam) -> ?ok.

battle_over_cb(Player, [Result, Robot]) ->
	UserId		= Player#player.user_id,
	Time		= misc:seconds(),
	case check_battle_over(UserId, Time) of
		{?ok, WorldPlayer} ->
			case lists:member(UserId, Robot) of
				?true  ->
					robot_world_api:battle_over(Player, WorldPlayer, Result);
				?false ->
					case Result of
						?CONST_BATTLE_RESULT_LEFT ->
							State	= ?CONST_PLAYER_STATE_NORMAL;
						?CONST_BATTLE_RESULT_RIGHT ->
							Datas	=[{#world_player.cd_death, Time + ?CONST_WORLD_CD_REBORN}],
							ets_api:update_element(?CONST_ETS_WORLD_PLAYER, UserId, Datas),
							State	= ?CONST_PLAYER_STATE_DEATH
					end,
					Packet			= msg_sc_update_hurt(WorldPlayer#world_player.hurt),
					misc_packet:send(Player#player.net_pid, Packet),
					{_Flag, Player2}= player_state_api:try_set_state(Player, State),
					{?ok, Player2}
			end;
		{?error, _ErrorCode} ->
			case lists:member(UserId, Robot) of
				?true  -> {?ok, Player};
				?false ->
					{_Flag, Player2}= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
					{?ok, Player2}
			end
	end.

check_battle_over(UserId, Time) ->
	try
		?ok					= check_world_start(Time),
		{?ok, WorldPlayer}	= check_world_player(UserId),
		{?ok, WorldPlayer}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
auto_revive(Player) ->
	UserId		= Player#player.user_id,
	Seconds		= misc:seconds(),
	case check_auto_revive(UserId, Seconds) of
		{?ok, WorldPlayer} ->
			set_world_player(WorldPlayer#world_player{cd_death = 0}),
%% 			misc_packet:send(UserId, msg_sc_revive()),
%% 			misc_packet:send(UserId, <<>>),
			{_, Player2}	= player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL),
			{?ok, Player2};
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player}
	end.

check_auto_revive(UserId, Seconds) ->
	try
		?ok					= check_world_start(Seconds),
		{?ok, WorldPlayer}	= check_world_player(UserId),
		?ok					= check_cd_death(Seconds, WorldPlayer#world_player.cd_death),
		{?ok, WorldPlayer}
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
quit(Player) ->
	UserId		= Player#player.user_id,
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, Player2} ->
			case get_world_player(UserId) of
				?null ->
					Player3			= map_api:return_last_city(Player2),
					{?ok, Player3};% 角色未加入乱天下
				WorldPlayer when is_record(WorldPlayer, world_player) ->
					Time			= misc:seconds() + ?CONST_WORLD_CD_EXIT,
					WorldPlayer2	= WorldPlayer#world_player{cd_exit = Time, exist = ?CONST_SYS_FALSE},
					Guild			= Player#player.guild,
					GuildId			= Guild#guild.guild_id,
					if
						WorldPlayer#world_player.belong =:= GuildId -> ?ok;
						?true -> quit(WorldPlayer#world_player.belong,UserId)
					end,
					set_world_player(WorldPlayer2),
					Packet45130		= msg_sc_exit_cd(Time),
					misc_packet:send(Player2#player.net_pid, Packet45130),
					Player3			= map_api:return_last_city(Player2),
					{?ok, Player3}
			end;
		{?false, Player2, _} ->
			Player3		= map_api:return_last_city(Player2),
			{?ok, Player3}
	end.

quit(GuildId,UserId) ->
	case world_api:get_world_data(GuildId) of
		#world_data{pid = Pid} ->
			world_serv:quit_cast(Pid, UserId);
		_ -> ?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
login_packet(Player, AccPacket) ->
	case check_login_packet(Player) of
		{?ok, WorldPlayer} ->
			Packet	= msg_sc_exit_cd(WorldPlayer#world_player.cd_exit),
			{Player, <<AccPacket/binary, Packet/binary>>};
		_ -> {Player, AccPacket}
	end.

check_login_packet(Player) ->
	try
		{?ok, _WorldBase}	= check_world_open(),
		case get_world_player(Player#player.user_id) of
			WorldPlayer when is_record(WorldPlayer, world_player) ->
				{?ok, WorldPlayer};
			_ -> {?error, ?TIP_WORLD_NOT_IN_ACTIVE}% 角色未加入乱天下
		end
	catch
		throw:Return -> Return;
		Error:Reason ->
			?MSG_ERROR("Error:~p Reason:~p, Strace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 离线退出
logout(Player) ->
	robot_world_api:logout(Player),
	case get_world_player(Player#player.user_id) of
		WorldPlayer when is_record(WorldPlayer, world_player) andalso
						 WorldPlayer#world_player.exist =:= ?CONST_SYS_TRUE ->
			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
				{?true, Player2} ->
					Time			= misc:seconds() + ?CONST_WORLD_CD_EXIT,
					RobotList		= robot_world_api:get_world_robot_list(),
%% 					RobotList		= [19],
					case lists:member(Player#player.user_id, RobotList) of
						?true  -> {?ok, Player2};
						?false ->
							WorldPlayer2	= WorldPlayer#world_player{cd_exit = Time, exist = ?CONST_SYS_FALSE},
							set_world_player(WorldPlayer2),
							Player3			= map_api:return_last_city(Player2),
							{?ok, Player3}
					end;
				{?false, Player2, _} -> {?ok, Player2}
			end;
		_ -> {?ok, Player}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 广播相关
broadcast(GuildId, Packet) ->
	UserIdList	= world_player_ids(GuildId),
	broadcast2(UserIdList, Packet).
broadcast2([UserId|UserIdList], Packet) ->
	misc_packet:send(UserId, Packet),
	broadcast2(UserIdList, Packet);
broadcast2([], _Packet) -> ?ok.

broadcast_exist(GuildId, Packet) ->
	UserIdList	= world_player_exist_ids(GuildId),
	broadcast_exist2(UserIdList, Packet).
broadcast_exist2([UserId|UserIdList], Packet) ->
	misc_packet:send(UserId, Packet),
	broadcast_exist2(UserIdList, Packet);
broadcast_exist2([], _Packet) -> ?ok.

broadcast_world_exist(Packet) ->
	UserIdList	= world_player_exist_ids(),
	broadcast_world_exist(UserIdList, Packet).
broadcast_world_exist([UserId|UserIdList], Packet) ->
	misc_packet:send(UserId, Packet),
	broadcast_world_exist(UserIdList, Packet);
broadcast_world_exist([], _Packet) -> ?ok.

world_player_ids(GuildId) ->
	MatchSpec	= ets:fun2ms(fun(#world_player{user_id = UserId, belong = Belong})
								  when Belong =:= GuildId -> UserId
							 end),
	ets_api:select(?CONST_ETS_WORLD_PLAYER, MatchSpec).

world_player_exist_ids(GuildId) ->
	MatchSpec	= ets:fun2ms(fun(#world_player{user_id = UserId, belong = Belong, exist = Exist})
								  when Exist =:= ?CONST_SYS_TRUE andalso Belong =:= GuildId -> UserId
							 end),
	ets_api:select(?CONST_ETS_WORLD_PLAYER, MatchSpec).

world_player_exist_ids() ->
	MatchSpec	= ets:fun2ms(fun(#world_player{user_id = UserId, exist = Exist})
								  when Exist =:= ?CONST_SYS_TRUE -> UserId
							 end),
	ets_api:select(?CONST_ETS_WORLD_PLAYER, MatchSpec).

%% 奖励击杀
reward_kill(GuildId, UserId, UserName, WorldMonster,InviteQuota) ->
	RewardKillGold	= WorldMonster#world_monster.reward_gold,
	Packet	= message_api:msg_notice(?TIP_WORLD_KILL_MONSTER_NOTICE, [{UserId, UserName}], [],
									 [{?TIP_SYS_MONSTER, misc:to_list(WorldMonster#world_monster.monster_id)},
									  {?TIP_SYS_COMM, misc:to_list(RewardKillGold)}]),
	guild_api:brocast(GuildId, Packet),
	reward_kill_brocast(InviteQuota,Packet),

	{?ok, WorldPlayer}	= check_world_player(UserId),
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, RewardKillGold, ?CONST_COST_WORLD_REWARD_KILL),
	Datas	= [{#world_player.kill, WorldPlayer#world_player.kill + 1},
			   {#world_player.reward_kill, WorldPlayer#world_player.reward_kill + RewardKillGold}],
	ets_api:update_element(?CONST_ETS_WORLD_PLAYER, UserId, Datas).

reward_kill_brocast([],_) -> ?ok;
reward_kill_brocast([H|L],Packet) ->
	case H of
		{_,_,InviteList} ->
			F = fun(MemId) ->
					misc_packet:send(MemId, Packet) 
				end,
			lists:foreach(F, InviteList);
		_ -> ?ok
	end,
	reward_kill_brocast(L,Packet).
		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 检查乱天下活动是否开启
check_world_open() ->
	case active_api:is_opened(?CONST_ACTIVE_WORLD) of
		?CONST_SYS_TRUE ->
			case get_world_base() of
				WorldBase when is_record(WorldBase, world_base) -> {?ok, WorldBase};
				_ -> throw({?error, ?TIP_WORLD_NOT_OPEN})% 乱天下尚未开启
			end;
		?CONST_SYS_FALSE -> throw({?error, ?TIP_WORLD_NOT_OPEN})% 乱天下尚未开启
	end.

%% 检查乱天下活动是否开始
check_world_start(Seconds) ->
	case get_world_base() of
		#world_base{time_start = StartTime} ->
			if
				Seconds >= StartTime -> ?ok;
				?true -> throw({?error, ?TIP_WORLD_NOT_START})% 乱天下尚未开始
			end;
		_ -> throw({?error, ?TIP_WORLD_NOT_START})% 乱天下尚未开始
	end.

%% 检查角色是否有军团
check_guild(Player) ->
	case Player#player.guild of
		#guild{guild_id = GuildId} when GuildId =/= 0 -> {?ok, GuildId};
		_ -> throw({?error, ?TIP_WORLD_GUILD_NULL})% 角色未加入军团
	end.

%% 检查角色军团职位、名额
check_guild_pos_quota(Player, WorldData) ->
	case Player#player.guild of
		#guild{guild_id = GuildId, guild_pos = GuildPos} when
		  GuildId =:= WorldData#world_data.guild_id ->
			case lists:keyfind(GuildPos, 1, WorldData#world_data.invite_quota) of
				{GuildPos, Quota, HelperList} ->
					if
						length(HelperList) < Quota -> {?ok, GuildPos};
						?true -> throw({?error, ?TIP_WORLD_FULL_QUOTA})% 名额已满
					end;
				_ -> throw({?error, ?TIP_WORLD_NOT_LEADER})% 角色不是当前军团的leader
			end;
		_ -> throw({?error, ?TIP_WORLD_NOT_GUILD_MEMBER})% 角色不属于当前军团
	end.

check_invite(WorldData, UserId) ->
	case lists:keyfind(UserId, 1, WorldData#world_data.invite) of
		{UserId, SecondsLast} ->
			Seconds	= misc:seconds(),
			if SecondsLast + 30 >= Seconds -> ?true; ?true -> ?false end;
		?false -> ?false
	end.

check_world_player(UserId) ->
	case get_world_player(UserId) of
		WorldPlayer = #world_player{exist = ?CONST_SYS_TRUE} ->
			?MSG_DEBUG("333333333333333333333333333333333333333333333333", []),
			{?ok, WorldPlayer};
		_ ->
			?MSG_DEBUG("333333333333333333333333333333333333333333333333", []),
			throw({?error, ?TIP_WORLD_NOT_IN_ACTIVE})% 角色未加入乱天下
	end.

%% 检查怪物
check_world_monster(WorldData, Step, Id) ->
	case get_world_monster(WorldData, Step, Id) of
		{?ok, WorldMonster} ->
			if
				WorldMonster#world_monster.death =:= ?false ->
					{?ok, WorldMonster};
				?true -> throw({?error, ?TIP_WORLD_MONSTER_DEATH})% 怪物已经死亡
			end;
		_ -> throw({?error, ?TIP_WORLD_MONSTER_DEATH})% 怪物已经死亡
	end.

%% 检查退出CD
check_cd_exit(Time, TimeStamp) ->
	if
		Time >= TimeStamp -> ?ok;
		?true -> throw({?error, ?TIP_WORLD_CD_EXIT})% 退出乱天下时间限制
	end.

%% 检查死亡CD
check_cd_death(Time, TimeStamp) ->
	if
		Time >= TimeStamp -> ?ok;
		?true -> throw({?error, ?TIP_WORLD_CD_DEATH})% 死亡CD限制
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_pid(GuildId) ->
	case get_world_data(GuildId) of
		?null ->
			case world_sup:start_child_world_serv(GuildId) of
				{?ok, Pid} -> {?ok, Pid};
				{?error, ErrorCode} -> {?error, ErrorCode}
			end;
		WorldData -> {?ok, WorldData#world_data.pid}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_world_base() ->
	ets_api:lookup(?CONST_ETS_WORLD_BASE, world_base).
set_world_base(WorldBase) ->
	ets_api:insert(?CONST_ETS_WORLD_BASE, WorldBase).
del_world_base() ->
	ets_api:delete(?CONST_ETS_WORLD_BASE, world_base).

%% world_api:get_world_data(80).
get_world_data(GuildId) ->
	ets_api:lookup(?CONST_ETS_WORLD_DATA, GuildId).
set_world_data(WorldData) ->
	ets_api:insert(?CONST_ETS_WORLD_DATA, WorldData).
del_world_data(GuildId) ->
	ets_api:delete(?CONST_ETS_WORLD_DATA, GuildId).

get_world_player(UserId) ->
	ets_api:lookup(?CONST_ETS_WORLD_PLAYER, UserId).
set_world_player(WorldPlayer) ->
	ets_api:insert(?CONST_ETS_WORLD_PLAYER, WorldPlayer).
del_world_player(UserId) ->
	ets_api:delete(?CONST_ETS_WORLD_PLAYER, UserId).

get_world_monster(WorldData, Step, Id) ->
	if
		WorldData#world_data.step =:= Step ->
			WorldMonsters	= WorldData#world_data.monsters,
			case lists:keyfind(Id, #world_monster.id, WorldMonsters#world_monsters.monsters) of
				WorldMonster when is_record(WorldMonster, world_monster) -> {?ok, WorldMonster};
				_ -> {?error, ?TIP_WORLD_MONSTER_ABSENT}% 怪物不存在
			end;
		?true -> {?error, ?TIP_WORLD_MONSTER_ABSENT}% 怪物不存在
	end.
set_world_monster(WorldData, Step, WorldMonster) ->
	if
		WorldData#world_data.step =:= Step ->
			WorldMonsters	= WorldData#world_data.monsters,
			Monsters		= lists:keyreplace(WorldMonster#world_monster.id, #world_monster.id,
											   WorldMonsters#world_monsters.monsters, WorldMonster),
			WorldMonsters2	= WorldMonsters#world_monsters{monsters = Monsters},
			WorldData#world_data{monsters = WorldMonsters2};
		?true -> WorldData
	end.
%% world_api:get_world_map_pid(80).
get_world_map_pid(GuildId) ->
	case get_world_data(GuildId) of
		#world_data{map_pid = MapPid} -> MapPid;
		_ -> ?null
	end.
set_world_map_pid(GuildId, MapPid) ->
	case get_world_data(GuildId) of
		WorldData when is_record(WorldData, world_data) ->
			ets_api:update_element(?CONST_ETS_WORLD_DATA, GuildId, [{#world_data.map_pid, MapPid}]),
			?ok;
		_ -> ?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 进入乱天下返回
msg_sc_enter(WorldBase, WorldData) ->
	Datas		= [
				   WorldData#world_data.step, WorldData#world_data.step_max,
				   WorldBase#world_base.time_start, WorldBase#world_base.time_end
				  ],
	misc_packet:pack(?MSG_ID_WORLD_SC_ENTER, ?MSG_FORMAT_WORLD_SC_ENTER, Datas).
%% 更新怪物通知
msg_sc_update_monster(WorldData) ->
	WorldMonsters	= WorldData#world_data.monsters,
	msg_sc_update_monster(WorldData#world_data.step,
						  WorldData#world_data.monster_activate,
						  WorldMonsters#world_monsters.monsters).
msg_sc_update_monster(Step, ?true, Monsters) ->
	MonstersData	= [{Id,MonsterId,Hp,HpMax} ||
					   #world_monster{id 			= Id,
									  monster_id 	= MonsterId,
									  hp 			= Hp,
									  hp_max 		= HpMax,
									  death			= ?false} <- Monsters],
	misc_packet:pack(?MSG_ID_WORLD_SC_UPDATE_MONSTER, ?MSG_FORMAT_WORLD_SC_UPDATE_MONSTER, [Step, MonstersData]);
msg_sc_update_monster(_Step, ?false, _Monsters) -> <<>>.
%% 移除怪物通知
msg_sc_remove_monster(Id) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_REMOVE_MONSTER, ?MSG_FORMAT_WORLD_SC_REMOVE_MONSTER, [Id]).
%% 退出乱天下冷却时间
msg_sc_exit_cd(Time) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_EXIT_CD, ?MSG_FORMAT_WORLD_SC_EXIT_CD, [Time]).
%% 个人伤害更新
msg_sc_update_hurt(Hurt) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_UPDATE_HURT, ?MSG_FORMAT_WORLD_SC_UPDATE_HURT, [Hurt]).
%% 军团排名通知
msg_sc_rank_guild(GuildTop) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_RANK_GUILD, ?MSG_FORMAT_WORLD_SC_RANK_GUILD, [GuildTop]).
%% 个人排名通知
msg_sc_rank_player(PlayerTop) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_RANK_PLAYER, ?MSG_FORMAT_WORLD_SC_RANK_PLAYER, [PlayerTop]).
%% 乱天下正式开始
msg_sc_start() ->
	misc_packet:pack(?MSG_ID_WORLD_SC_START, ?MSG_FORMAT_WORLD_SC_START, []).
%% 乱天下结束
msg_sc_end() ->
	misc_packet:pack(?MSG_ID_WORLD_SC_END, ?MSG_FORMAT_WORLD_SC_END, []).
%% 乱天下犒赏三军通知
msg_sc_buff_notice(0) -> <<>>;
msg_sc_buff_notice(Id) when is_integer(Id) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_BUFF_NOTICE, ?MSG_FORMAT_WORLD_SC_BUFF_NOTICE, [Id]);
msg_sc_buff_notice(WorldData) ->
	case lists:reverse(lists:keysort(#world_buff.id, WorldData#world_data.buff)) of
		[#world_buff{id = Id}|_List] -> msg_sc_buff_notice(Id);
		_ -> <<>>
	end.
%% 角色犒赏三军信息
msg_sc_buff_info(#world_data{buff = [#world_buff{id = Id}|_]}) ->
	msg_sc_buff_info(Id);
msg_sc_buff_info(#world_data{buff = []}) ->
	msg_sc_buff_info(0);
msg_sc_buff_info(Id) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_BUFF_INFO, ?MSG_FORMAT_WORLD_SC_BUFF_INFO, [Id]).
%% 邀请通知
msg_sc_invite_notice(GuildId,GuildName,GuildPos,InviterUid,InviterName) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_INVITE_NOTICE, ?MSG_FORMAT_WORLD_SC_INVITE_NOTICE, [GuildId,GuildName,GuildPos,InviterUid,InviterName]).
%% 下一波刷怪通知
msg_sc_next_monster_notice(1, _Seconds) -> <<>>;
msg_sc_next_monster_notice(Step, Seconds) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_NEXT_MONSTER_NOTICE, ?MSG_FORMAT_WORLD_SC_NEXT_MONSTER_NOTICE, [Step,Seconds]).

%% 战斗结束军团长通知
msg_sc_leader_notice(Step) ->
	misc_packet:pack(?MSG_ID_WORLD_SC_LEADER_NOTICE, ?MSG_FORMAT_WORLD_SC_LEADER_NOTICE, [Step]).

%% 奖励信息
msg_reward_info(Step,GuildIdx,Count,Hurt,Exp,Gold,Exploit) ->
	misc_packet:pack(?MSG_ID_WORLD_REWARD_INFO, ?MSG_FORMAT_WORLD_REWARD_INFO, [Step,GuildIdx,Count,Hurt,Exp,Gold,Exploit]).

%% 乱天下替身
msg_sc_world_robot(List) ->
	?MSG_DEBUG("~n List =~p", [List]),
	misc_packet:pack(?MSG_ID_WORLD_SC_DOLL, ?MSG_FORMAT_WORLD_SC_DOLL, List).