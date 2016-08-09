%% Author: Administrator
%% Created: 2012-10-22
%% Description: TODO: Add description to guild_party_mod
-module(guild_party_mod).
%% 
%% %%
%% %% Include files
%% %%
%% -include("../../include/const.common.hrl").
%% -include("../../include/const.define.hrl").
%% -include("../../include/const.tip.hrl").
%% -include("../../include/const.cost.hrl").
%% -include("../../include/record.base.data.hrl").
%% -include("../../include/record.player.hrl").
%% -include("../../include/record.guild.hrl").
%% %%
%% %% Exported Functions
%% %%
%% -export([
%% 		 enter/1,exit/1,
%% 		 
%% 		 party_exp_handle/0,party_exp_cb/2,
%% 		 party_sp_handle/0,party_sp_cb/2,
%% 		 party_rank_handle/0,
%% 		
%% 		 automatic_party/3,automatic_reward_cb/2,
%% 		 automatic_reward/2, automatic_reward_offline/2,
%% 		 
%% 		 desk_data/1,desk_reward/1,reset_desk_times/1, 
%% 		 party_end/1,party_end_cb/2,party_end_reward/2,
%% 
%% 		 set_rock_reward_cb/2,set_guess_reward_cb/2,
%% 		 
%% 		 invite_guess/2,deal_with_invite_guess/3,guess/2,guess_exit_request/1,
%% 		 invite_rock/2,deal_with_invite_rock/3,rock/1,rock_exit_request/1
%% 		]).
%% 
%% %%
%% %% API Functions
%% %%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 请求进入军团宴会
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% enter(Player = #player{user_id = UserId,account = Account,info = Info,guild = Guild}) when is_record(Player,player) ->
%% 	try
%% 		GuildId					= Guild#guild.guild_id,
%% 		?ok						= check_map_id(Info#info.map_id),
%% 		{?ok,PartyData}			= get_party_data(),
%%  
%% 		{?ok, Player2}			= check_user_state(Player),		%% 检查玩家状态
%% 		{?ok, Player3}			= check_play_state(Player2),	%% 检查玩法状态	
%% 		{?ok, GuildParty}		= get_guild_party(GuildId),
%% 		{?ok,GuildMember}		= guild_api:get_guild_member(UserId),
%% 		?ok						= check_automatic(UserId,GuildParty#guild_party.auto_list),	%% 检查是否自动参加
%% 
%% 		MemberList2 			= enter_list(UserId,GuildParty#guild_party.in_list),	%% 加入列表
%% 		AllList 				= enter_list(UserId,GuildParty#guild_party.all_list),	%% 加入列表
%% 		NewParty				= GuildParty#guild_party{in_list 	= MemberList2,
%% 														 all_list 	= AllList},
%% 		{Res,Time}  			= party_data(PartyData),		%%  	
%% 		{?ok,NewMember}			= enter_member(GuildMember),
%% 		{?ok,Guess,Rock}		= get_game_times(NewMember),	%% 剩余的次数
%% 		
%% 		Packet1 				= guild_party_api:msg_sc_enter_party(?CONST_SYS_TRUE),  %%　进入场景
%% 		Packet2 				= guild_party_api:msg_sc_partyinfo(Res,0,Time,Guess,Rock),
%% %% 		Packet3					= guild_party_api:msg_sc_party_rank(GuildParty#guild_party.rank_list),
%% 		Packet3					= reward_packet(NewMember),
%% 		{?ok,NewPlayer} 		= case PartyData#party_data.state of
%% 									?CONST_ACTIVE_STATE_ON ->
%% 										{?ok,Player4} 	= add_activity_times(Player3,1),%% 	
%% 										{?ok,Player5} 	= add_guide_times(Player4), 	%% 目标	
%% 										{?ok,Player6} 	= add_achievement(Player5), 	%% 成就
%% 										{?ok,Player6};
%% 									_ ->
%% 										{?ok,Player3}
%% 								  end,
%% 		NewPlayer2 				= map_api:enter_map(NewPlayer, ?CONST_GUILD_PARTY_MAP),
%% 		admin_log_api:log_campaign(UserId, Account, Info#info.lv, ?CONST_ACTIVE_TYPE_PARTY, misc:seconds()),
%% 		
%% 		misc_packet:send(Player#player.net_pid, <<Packet1/binary,Packet2/binary,Packet3/binary>>),
%% 		ets_api:insert(?CONST_ETS_GUILD_PARTY, NewParty),
%% 		{?ok,NewPlayer2}
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message(Player,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% reward_packet(#guild_party_member{exp = Exp,sp = Sp}) ->
%% 	ExpPakcet 	= guild_party_api:msg_sc_party_exp(Exp),
%% 	SpPacket	= guild_party_api:msg_sc_party_sp(Sp),
%% 	<<ExpPakcet/binary,SpPacket/binary>>.
%% 
%% %% guild_party_api:msg_sc_party_gold(0),
%% %% guild_party_api:msg_sc_party_experience(0),
%% 
%% check_map_id(?CONST_GUILD_PARTY_MAP) -> 
%% 	throw({?error,110});
%% check_map_id(_) -> ?ok.
%% 	
%% 
%% check_user_state(Player) ->
%% 	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL) of
%% 		{?true, Player2} ->
%% 			{?ok, Player2};
%% 		_ ->
%% 			throw({?error,?TIP_GUILD_STATE_NOT_JOIN})
%% 	end.
%% 
%% get_guild_party(0) ->
%% 	throw({?error,?TIP_GUILD_NOT_JION});
%% get_guild_party(GuildId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 		?null -> %% 不在军团
%% 			throw({?error,?TIP_GUILD_PARTY_DISBAND});
%% 		GuildParty ->
%% 			{?ok,GuildParty}
%% 	end.
%% 
%% get_paryt_member(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null -> %% 不在军团宴会
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_JION});
%% 		PartyM ->
%% 			{?ok,PartyM}
%% 	end.
%% 
%% check_automatic(UserId,List) -> 
%% 	case lists:member(UserId, List) of
%% 		?true -> throw({?error,?TIP_GUILD_AUTOMATIC});
%% 		_ -> ?ok
%% 	end.
%% 
%% check_play_state(Player) -> 
%% 	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_PARTY) of
%% 		{?true,Player2} ->
%% 			{?ok,Player2};
%% 		_ ->
%% 			throw({?error,?TIP_GUILD_PLAY_NOT_JOIN})
%% 	end.
%% 
%% party_data(PartyData) ->
%% 	case PartyData#party_data.state of
%% 		?CONST_ACTIVE_STATE_ON ->
%% 			{?CONST_SYS_TRUE,PartyData#party_data.end_time - misc:seconds()} ;
%% 		_ ->
%% 			{?CONST_SYS_FALSE,PartyData#party_data.start_time - misc:seconds()} 
%% 	end.
%% 	
%% get_party_data() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA,?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_START});
%% 		PartyData ->
%% 			{?ok,PartyData}
%% 	end.
%% 	
%% add_activity_times(Player,Flag) when is_record(Player,player) ->
%% 	case Flag of
%% 		?CONST_GUILD_PARTY_ONE ->
%% 			schedule_api:add_activity_times(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY);
%% 		?CONST_GUILD_PARTY_TWO ->
%% 			schedule_api:add_activity_times(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY);
%% 		_ -> {?ok,Player}
%% 	end.	
%% 
%% add_guide_times(Player) when is_record(Player,player) ->
%% 	schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_GUILD_PARTY).
%% 
%% add_achievement(Player) when is_record(Player,player) ->
%% 	achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_GUILD_PARTY, 0, 1).
%% 													
%% get_game_times(Data) ->
%% 	{?ok,
%% 	 ?CONST_GUILD_PARTY_GUESS_TIMES - Data#guild_party_member.guess,
%% 	 ?CONST_GUILD_PARTY_ROCK_TIMES - Data#guild_party_member.rock
%% 	 }.
%% 	
%% %% 加入列表
%% enter_list(UserId,MemberList) ->
%% 	case lists:member(UserId, MemberList) of
%% 		?false ->
%% 			[UserId|MemberList];
%% 		_ ->
%% 			MemberList
%% 	end.
%% 
%% %% 加入宴会成员
%% enter_member(GuildMember) ->
%% 	UserId		= GuildMember#guild_member.user_id,
%% 	GuildId		= GuildMember#guild_member.guild_id,
%% 	UserName	= GuildMember#guild_member.user_name,
%% 	Time		= misc:seconds(),
%% 	NewMember 	= case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 					  ?null ->
%% 						  init_party_member(UserId,UserName,GuildId,Time);
%% 					  PartyMember ->
%% 						  PartyMember#guild_party_member{user_id = UserId, user_name = UserName,
%% 														 enter_time = Time, state = 0,game = []}
%% 				  end,
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, NewMember),
%% 	{?ok,NewMember}.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 宴会定时奖励
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% party_exp_handle() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA,?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null -> ?ok;
%% 		PartyData ->
%% 			F = fun(GuildId) -> 
%% 					case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 						?null -> ?ok;
%% 						GuildParty ->
%% 							MemberList 	= GuildParty#guild_party.in_list,	
%% 							party_exp(MemberList)
%% 					end
%% 				end,
%% 			lists:foreach(F, PartyData#party_data.guild_list)
%% 	end.
%% 
%% %% 宴会定时奖励
%% party_exp([]) -> ?ok; 
%% party_exp([UserId|MemberList]) ->
%% 	player_api:process_send(UserId, ?MODULE, party_exp_cb, []),
%% 	party_exp(MemberList).
%% 	
%% party_exp_cb(Player = #player{user_id = UserId,info = Info,net_pid = Pid},[]) 
%%   when Info#info.map_id =:= ?CONST_GUILD_PARTY_MAP ->
%% 	case data_guild:get_guild_party_reward(Info#info.lv) of
%% 		?null ->
%% 			{?ok,Player};
%% 		#rec_guild_party_reward{exp = Exp} ->
%% 			case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 				?null -> ?ok;
%% 				GuildM ->	
%% 					ExpSum			= GuildM#guild_party_member.exp + Exp,
%% 					GuildM2			= GuildM#guild_party_member{exp = ExpSum},		
%% 					Packet			= guild_party_api:msg_sc_party_exp(ExpSum),
%% 					{?ok,Player2}	= player_api:exp(Player, Exp),
%% 					ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, GuildM2),
%% 					misc_packet:send(Pid, Packet),
%% 					{?ok,Player2}
%% 			end
%% 	end;
%% party_exp_cb(Player,[]) ->
%% 	{?ok,Player}.
%% 
%% party_sp_handle() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA,?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null -> ?ok;
%% 		PartyData ->
%% 			F = fun(GuildId) -> 
%% 					case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 						?null -> ?ok;
%% 						GuildParty ->
%% 							MemberList 	= GuildParty#guild_party.in_list,	
%% 							party_sp(MemberList)
%% 					end
%% 				end,
%% 			lists:foreach(F, PartyData#party_data.guild_list)
%% 	end.
%% 
%% party_sp([]) -> ?ok; 
%% party_sp([UserId|MemberList]) ->
%% 	player_api:process_send(UserId, ?MODULE, party_sp_cb, []),
%% 	party_sp(MemberList).
%% 	
%% party_sp_cb(Player = #player{user_id = UserId,net_pid = Pid,info = Info},[]) 
%%   when Info#info.map_id =:= ?CONST_GUILD_PARTY_MAP ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		GuildM = #guild_party_member{sp = SpSum} when SpSum < 20  ->
%% 			AddSp			= 10,
%% 			SpSum2			= SpSum + AddSp,
%% 			GuildM2			= GuildM#guild_party_member{sp = SpSum2},
%% 			Packet			= guild_party_api:msg_sc_party_sp(SpSum2),
%% 			{?ok,Player2}	= player_api:plus_sp(Player, AddSp, ?CONST_COST_PARTY_HOOK),
%% 			ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, GuildM2),
%% 			misc_packet:send(Pid, Packet),
%% 			{?ok,Player2};
%% 		_ -> 
%% 			{?ok,Player}
%% 	end;
%% party_sp_cb(Player,[]) ->
%% 	{?ok,Player}.
%% 
%% party_rank_handle() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA,?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null -> ?ok;
%% 		PartyData ->
%% 			F = fun(GuildId) -> 
%% 					case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 						?null -> ?ok;
%% 						GuildP = #guild_party{all_list = AllList,in_list = InList}  ->
%% 							RankList 		= party_rank(AllList,[]),
%% 							RankList2		= lists:sort(RankList),
%% 							RankList3		= lists:reverse(RankList2),		%% 列表倒序
%% 							RankList4		= get_split_list(10,RankList3),
%% 							Packet			= guild_party_api:msg_sc_party_rank(RankList4),
%% 							GuildP2			= GuildP#guild_party{rank_list = RankList4},
%% 							ets_api:insert(?CONST_ETS_GUILD_PARTY, GuildP2),
%% 							guild_party_api:brocast_handle(InList,Packet)
%% 					end
%% 				end,
%% 			lists:foreach(F, PartyData#party_data.guild_list)
%% 	end.
%% 
%% get_split_list(Num,RankList) when length(RankList) =< Num ->
%% 	RankList;
%% get_split_list(Num,RankList) ->
%% 	{RankList2,_}	= lists:split(Num,RankList),
%% 	RankList2.
%% 
%% party_rank([],List) -> 
%% 	List;
%% party_rank([UserId|MemberList],List) -> 
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			party_rank(MemberList,List);
%% 		#guild_party_member{user_name = Name,guess_score = Score1,rock_score = Score2} ->
%% 			party_rank(MemberList,[{Score1+Score2,UserId,Name}|List])
%% 	end.			
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 退出宴会
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% exit(Player = #player{info = Info,user_id = UserId}) 
%%   when Info#info.map_id =:= ?CONST_GUILD_PARTY_MAP ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null -> ?ok;
%% 		UserMem ->
%% 			GuildId			= UserMem#guild_party_member.guild_id,
%% 			AddTime			= misc:seconds() - UserMem#guild_party_member.enter_time,
%% 			Time			= UserMem#guild_party_member.time + AddTime,
%% 			UserMem2		= UserMem#guild_party_member{time = Time},
%% 			exit_game(UserMem2),
%% 			case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 				?null -> ?ok;
%% 				GuildParty	->
%% 					MemberList 		= GuildParty#guild_party.in_list,
%% 					MemberList2		= lists:delete(UserId, MemberList),
%% 					GuildParty2 	= GuildParty#guild_party{in_list = MemberList2},
%% 					ets_api:insert(?CONST_ETS_GUILD_PARTY, GuildParty2)
%% 			end
%% 	end,
%% 	Player2			= map_api:enter_map(Player, Info#info.map_id_last),
%% 	{?ok,Player2}	= set_player_state(Player2,?CONST_PLAYER_STATE_NORMAL),
%% 	{?ok,Player3}	= set_state_play(Player2,?CONST_PLAYER_PLAY_CITY),
%% 	Packet 			= guild_party_api:msg_sc_leave_party(?CONST_SYS_TRUE),
%% 	misc_packet:send(Player#player.net_pid, Packet),
%% 	{?ok,Player3};
%% exit(Player) ->
%% 	{?ok,Player}.
%% 
%% exit_game(UserMem = #guild_party_member{state = ?CONST_GUILD_PARTY_GUESS}) -> 
%% 	guess_exit(UserMem); 
%% exit_game(UserMem = #guild_party_member{state = ?CONST_GUILD_PARTY_ROCK}) -> 
%% 	rock_exit(UserMem);
%% exit_game(UserMem) -> 
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 自动参加
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% automatic_party(Player,ActiveId,Flag) when is_record(Player,player) ->
%% 	Info 		= Player#player.info,
%% 	Vip			= player_api:get_vip_lv(Info),
%% 	UserId		= Player#player.user_id,
%% 	try
%% 		IsAuto				= player_vip_api:can_guild_party_auto_join(Vip),
%% 		?ok					= check_vip_flag(IsAuto),
%% 		{?ok,GuildMember} 	= guild_api:get_guild_member(UserId),
%% 		GuildMember2		= get_new_m(GuildMember,ActiveId,Flag),
%% 		guild_mod:update_member(GuildMember2,[]),
%% 		?ok
%% 	catch
%% 		throw:{?error,ErrorCode} ->
%% 			Packet = message_api:msg_notice(ErrorCode),
%% 			misc_packet:send(Player#player.net_pid, Packet),
%% 			{?error,ErrorCode};
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% get_new_m(GuildMember,?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,?true) ->
%% 	GuildMember#guild_member{party_flag1 = ?CONST_SYS_TRUE};
%% get_new_m(GuildMember,?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,_) ->
%% 	GuildMember#guild_member{party_flag1 = ?CONST_SYS_FALSE};
%% get_new_m(GuildMember,?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY,?true) ->
%% 	GuildMember#guild_member{party_flag2 = ?CONST_SYS_TRUE};
%% get_new_m(GuildMember,?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY,_) ->
%% 	GuildMember#guild_member{party_flag2 = ?CONST_SYS_FALSE}.
%% 
%% check_vip_flag(?CONST_SYS_FALSE) -> 
%% 	throw({?error,?TIP_GUILD_VIP});
%% check_vip_flag(_) -> ?ok.
%% 	
%% %% 邀请猜拳游戏
%% invite_guess(Player,InviteId) when is_record(Player,player) -> 
%% 	UserId 		= Player#player.user_id,
%% 	Info 		= Player#player.info,
%% 	Name 		= Info#info.user_name,
%% 	MapId		= Info#info.map_id,
%% 	try 
%% 		?ok 				= check_party_state(),
%% 		?ok					= check_map(MapId),
%% 		?ok					= check_invite_id(UserId,InviteId),
%% 		{?ok,TPlayer,Flag} 	= player_api:get_player_first(InviteId),
%% 		TInfo			 	= TPlayer#player.info,
%% 		?ok					= check_invite_online(Flag),
%% 		?ok					= check_invite_map(TInfo#info.map_id),
%% 		{?ok,_} 			= check_guess_mem(UserId),
%% 		{?ok,_} 			= check_guess_mem2(InviteId),
%% 		TipPacket			= message_api:msg_notice(?TIP_GUILD_PARTY_SEND_SUCCESS),
%% 		Packet 				= guild_party_api:msg_sc_invite_guess(UserId,Name),
%% 		misc_packet:send(InviteId, Packet),
%% 		misc_packet:send(Player#player.net_pid, TipPacket)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% check_invite_id(UserId,UserId) ->
%% 	throw({?error,?TIP_GUILD_INVITE_YOURSELF}); 
%% check_invite_id(_,_) -> ?ok. 
%% 
%% %%  处理猜拳邀请-拒绝
%% deal_with_invite_guess(Player,InviteId,?CONST_SYS_FALSE) when is_record(Player,player) -> 
%% 	try	
%% 		?ok 		= check_party_state(),
%% 		Info		= Player#player.info,
%% 		TipPacket 	= message_api:msg_notice(?TIP_GUILD_PARTY_REJECT,[{?TIP_SYS_COMM,Info#info.user_name}]), %% 对方拒绝
%% 		misc_packet:send(InviteId, TipPacket) %% 通知对方
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end;
%% 
%% %%  处理猜拳邀请-同意
%% deal_with_invite_guess(Player,InviteId,?CONST_SYS_TRUE) when is_record(Player,player) -> 
%% 	try
%% 		UserId 				= Player#player.user_id,
%% 		Info 				= Player#player.info,
%% 		MapId				= Info#info.map_id,
%% 		?ok					= check_party_state(),
%% 		{?ok,TPlayer,Flag} 	= player_api:get_player_first(InviteId),
%% 		TInfo			 	= TPlayer#player.info,
%% 		?ok					= check_invite_online(Flag),
%% 		?ok					= check_invite_map(TInfo#info.map_id),
%% 		?ok					= check_map(MapId),
%% 		{?ok,UserMem}		= check_guess_mem(UserId),
%% 		{?ok,InviteMem}		= check_guess_mem2(InviteId),
%% 		deal_with_invite_guess2(UserId,InviteId,UserMem,InviteMem)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% check_invite_online(?CONST_SYS_TRUE) -> ?ok;
%% check_invite_online(_) ->
%% 	throw({?error,?TIP_GUILD_PARTY_MEM_NOT_JOIN}).
%% 
%% check_invite_map(?CONST_GUILD_PARTY_MAP) -> ?ok;
%% check_invite_map(_) ->
%% 	throw({?error,?TIP_GUILD_PARTY_MEM_NOT_JOIN}).
%% 
%% %% 邀请成功
%% deal_with_invite_guess2(UserId,InviteId,UserMem,InviteMem) -> 
%% 	UserMem2 	= get_guess_mem(UserMem,InviteId),
%% 	InviteMem2	= get_guess_mem(InviteMem,UserId),
%% 	get_guess_info(UserMem2,InviteId,InviteMem2),
%% 	get_guess_info(InviteMem2,UserId,UserMem),
%% 
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, InviteMem2).
%% 
%% %% 更新成员状态
%% get_guess_mem(UserMem,MemId) ->
%% 	Game 		= init_guess_game(MemId),
%% 	State		= ?CONST_GUILD_PARTY_GUESS,
%% 	Guess		= UserMem#guild_party_member.guess, 
%% 	UserMem#guild_party_member{state = State, guess = Guess + 1,game = Game}.
%% 
%% %% 更新游戏状态
%% get_guess_info(User,MemId,Mem) ->
%% 	case player_api:get_player_first(MemId) of
%% 		{?ok, #player{info = Info}, _} ->
%% 			Score1 	= User#guild_party_member.guess_score, 
%% 			Guess	= User#guild_party_member.guess , 
%% 			Times	= ?CONST_GUILD_PARTY_GUESS_TIMES - Guess,
%% 			MemName	= Info#info.user_name , 
%% 			MemSex	= Info#info.sex, 
%% 			MemPro	= Info#info.pro,
%% 			Score2	= Mem#guild_party_member.guess_score , 
%% 			Packet	= guild_party_api:msg_sc_guess_info(Score1,Times,MemId,MemName,MemSex,MemPro,Score2),
%% 			misc_packet:send(User#guild_party_member.user_id, Packet);
%% 		_ -> ?ok
%% 	end.
%% 
%% 
%% %% 检查自己的状态
%% check_guess_mem(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_JION}); %% 不在宴会
%% 		UserMem = #guild_party_member{state = State,guess = Guess} ->
%% 			IsFree 	= is_free(State),
%% 			if
%% 				IsFree =:= ?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_OTHER}); %% 你在进行其他活动
%% 				Guess =:= ?CONST_GUILD_PARTY_GUESS_TIMES ->
%% 					throw({?error,?TIP_GUILD_PARTY_GUESS_FULL}); %% 次数已满
%% 				?true ->
%% 					{?ok,UserMem}
%% 			end
%% 	end.
%% 
%% %% 检查对方状态
%% check_guess_mem2(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_MEM_NOT_JOIN}); %% 对方不在宴会
%% 		UserMem = #guild_party_member{state = State,guess = Guess} ->
%% 			IsFree 	= is_free(State),
%% 			if
%% 				IsFree =:= ?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_MEM_OTHER_GAME}); %% 对方在进行其他活动
%% 				Guess >= ?CONST_GUILD_PARTY_GUESS_TIMES ->
%% 					throw({?error,?TIP_GUILD_PARTY_MEM_GUESS_FULL}); %% 对方次数已满
%% 				?true ->
%% 					{?ok,UserMem} 
%% 			end
%% 	end.
%% 
%% %% 猜拳
%% guess(Player,Type) when is_record(Player,player) -> 
%% 	try
%% 		Info			= Player#player.info,
%% 		?ok				= check_map(Info#info.map_id),
%% 		?ok				= check_party_state(),
%% 		?ok				= check_guess_type(Type),
%% 		
%% 		{?ok,UserMem}	= get_guess_game(Player#player.user_id),	
%% 		Game 			= UserMem#guild_party_member.game,
%% 		MemId			= Game#guess_game.mem_id,	
%% 		{?ok,RivalMem}	= get_guess_game(MemId),
%% 
%% 		guess_res(Player,MemId,UserMem,RivalMem,Type)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message(Player,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% check_guess_type(Type) when Type =< 0 orelse Type > 3 ->
%% 	throw({?error,?TIP_GUILD_GUESS_TYPE_ERROR});
%% check_guess_type(_) -> ?ok.
%% 
%% check_m_res(0) -> ?ok;
%% check_m_res(_) -> 
%% 	throw({?error,?TIP_GUILD_PARTY_GUESS_SEND}).
%% 
%% %% 判断猜拳结果
%% guess_res(Player,MemId,UserMem,RivalMem,Type) ->
%% 	UserId		= Player#player.user_id,
%%   	UserGame 	= UserMem#guild_party_member.game,
%% 	RivalGame 	= RivalMem#guild_party_member.game,
%% 	ORes		= UserGame#guess_game.o_res,		
%% 	MRes		= UserGame#guess_game.m_res,
%% 	?ok			= check_m_res(MRes),
%% 	if
%% 		ORes =:= 0 -> %% 对方还没出
%% 			Packet	= guild_party_api:msg_sc_out_guess(UserId,Type),
%% 			misc_packet:send(UserId, Packet),
%% 			guess_notice(UserMem,UserGame,RivalMem,RivalGame,Type),
%% 			{?ok,Player};
%% 		?true ->
%% 			case get_winner(Type,ORes) of
%% 				?CONST_GUILD_PARTY_AGAIN -> %% 平局继续
%%  					guess_res_msg(UserId,MemId,Type,ORes,?CONST_GUILD_PARTY_AGAIN),
%% 					guess_again(UserMem,UserGame,RivalMem,RivalGame),
%% 					{?ok,Player};
%% 				?CONST_GUILD_PARTY_WIN -> 	%% 胜利		
%% 					guess_res_msg(UserId,MemId,Type,ORes,?CONST_GUILD_PARTY_WIN),
%% 					guess_win(Player,MemId,UserMem,UserGame,RivalMem,RivalGame);
%% 				?CONST_GUILD_PARTY_LOST ->	%% 失败 	
%% 					guess_res_msg(UserId,MemId,Type,ORes,?CONST_GUILD_PARTY_LOST),
%% 					guess_lost(Player,MemId,UserMem,UserGame,RivalMem,RivalGame)
%% 			end
%% 	end.
%% 
%% %% 发送猜拳结果
%% guess_res_msg(UserId,MemId,MRes,ORes,Res) ->
%% 	OutPacket1	= guild_party_api:msg_sc_out_guess(UserId,MRes),
%% 	OutPacket2	= guild_party_api:msg_sc_out_guess(MemId,ORes),
%% 	case Res of
%% 		?CONST_GUILD_PARTY_AGAIN -> %% 平局继续
%% 			PacketRes1	= guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_AGAIN),
%% 			PacketRes2	= guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_AGAIN);
%% 		?CONST_GUILD_PARTY_WIN -> 	%% 胜利	
%% 			PacketRes1	= guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_WIN),
%% 			PacketRes2  = guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_LOST);
%% 		?CONST_GUILD_PARTY_LOST ->	%% 失败 
%% 			PacketRes1	= guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_LOST),
%% 			PacketRes2  = guild_party_api:msg_sc_out_res(?CONST_GUILD_PARTY_WIN)
%% 	end,
%% 	Packet1		= <<OutPacket1/binary,OutPacket2/binary,PacketRes1/binary>>,
%% 	Packet2		= <<OutPacket1/binary,OutPacket2/binary,PacketRes2/binary>>,
%% 	misc_packet:send(UserId, Packet1),
%% 	misc_packet:send(MemId, Packet2).
%% 
%% %% 当局胜利
%% guess_win(Player,MemId,UserMem,UserGame,RivalMem,RivalGame) ->
%% 	WinNum		= UserGame#guess_game.win_num,
%% 	CurNum		= UserGame#guess_game.cur_num,
%% 	LostNum		= RivalGame#guess_game.lost_num,
%% 	if
%% 		WinNum >= ?CONST_GUILD_PARTY_GUESS_WIN -> %% 结束胜利
%% 			guess_win2(Player,MemId,UserMem,UserGame,RivalMem,RivalGame);
%% 		?true ->
%% 			UserGame2	= UserGame#guess_game{m_res = 0,o_res = 0,cur_num = CurNum + 1,win_num = WinNum + 1},
%% 			RivalGame2	= RivalGame#guess_game{m_res = 0,o_res = 0,cur_num = CurNum + 1,lost_num = LostNum + 1},
%% 			guess_insert(UserMem,UserGame2,RivalMem,RivalGame2),
%% 			{?ok,Player}
%% 	end.
%% 
%% %% 退出胜利(对方退出)
%% get_guess_win(UserMem,MName) ->
%% 	UserId		= UserMem#guild_party_member.user_id,
%% 	GuessGame	= UserMem#guild_party_member.game,
%% 	LostNum		= GuessGame#guess_game.lost_num,
%% 	UserScore	= data_guild:get_guild_party_score({1,LostNum}),
%% 	Score		= UserMem#guild_party_member.guess_score + UserScore,
%% 	UserMem2 	= UserMem#guild_party_member{game = [],guess_score = Score,state = 0},
%% 	Packet1		= message_api:msg_notice(?TIP_GUILD_PRE_QUIT,[{?TIP_SYS_COMM,MName}]),
%% 	Packet2 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_WIN,UserScore),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	misc_packet:send(UserId, <<Packet1/binary,Packet2/binary>>).   
%% 
%% %% 结束胜利
%% guess_win2(Player,MemId,UserMem,UserGame,RivalMem,RivalGame) ->
%% 	UserId		= Player#player.user_id,
%% 	LostNum1	= UserGame#guess_game.lost_num, 
%% 	LostNum2	= RivalGame#guess_game.lost_num + 1,
%% 	UserScore	= data_guild:get_guild_party_score({1,LostNum1}),
%% 	RivalScore	= data_guild:get_guild_party_score({1,LostNum2}),
%% 	Score1		= UserMem#guild_party_member.guess_score + UserScore,
%% 	Score2		= RivalMem#guild_party_member.guess_score + RivalScore,
%% 	guess_end(UserMem,Score1,RivalMem,Score2),
%% 	Packet1 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_WIN,UserScore),
%% 	Packet2 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_LOST,RivalScore),
%% 	
%% 	misc_packet:send(UserId, Packet1),
%% 	misc_packet:send(MemId, Packet2),
%% 	player_api:process_send(MemId, ?MODULE, set_guess_reward_cb, [?CONST_SYS_FALSE]), 
%% 	set_guess_reward(Player,?CONST_SYS_TRUE).
%% 	
%% %% 结束
%% guess_end(UserMem,Score1,RivalMem,Score2) ->
%% 	UserMem2 	= UserMem#guild_party_member{game = [],guess_score = Score1,state = 0},
%% 	RivalMem2 	= RivalMem#guild_party_member{game = [],guess_score = Score2,state = 0},
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, RivalMem2).
%% 
%% %% 当局失败
%% guess_lost(Player,MemId,UserMem,UserGame,RivalMem,RivalGame) ->
%% 	WinNum		= RivalGame#guess_game.win_num,
%% 	CurNum		= UserGame#guess_game.cur_num,
%% 	LostNum		= UserGame#guess_game.lost_num,
%% 	if
%% 		LostNum >= ?CONST_GUILD_PARTY_GUESS_WIN ->
%% 			guess_lost2(Player,MemId,UserMem,UserGame,RivalMem,RivalGame);
%% 		?true ->
%% 			UserGame2	= UserGame#guess_game{m_res = 0,o_res = 0,cur_num = CurNum + 1,lost_num = LostNum + 1},	
%% 			RivalGame2	= RivalGame#guess_game{m_res = 0,o_res = 0,cur_num = CurNum + 1,win_num = WinNum + 1},
%% 			guess_insert(UserMem,UserGame2,RivalMem,RivalGame2),
%% 			{?ok,Player}
%% 	end.
%% 
%% %% 结束失败
%% guess_lost2(Player,MemId,UserMem,UserGame,RivalMem,RivalGame) ->
%% 	LostNum1	= UserGame#guess_game.lost_num + 1,
%% 	LostNum2	= RivalGame#guess_game.lost_num,
%% 	UserScore	= data_guild:get_guild_party_score({1,LostNum1}),
%% 	RivalScore	= data_guild:get_guild_party_score({1,LostNum2}),
%% 	Score1		= UserMem#guild_party_member.guess_score + UserScore,
%% 	Score2		= RivalMem#guild_party_member.guess_score + RivalScore,
%% 	guess_end(UserMem,Score1,RivalMem,Score2),
%% 	Packet1 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_LOST,UserScore),
%% 	Packet2 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_WIN,RivalScore),
%% 	
%% 	misc_packet:send(Player#player.user_id, Packet1),
%% 	misc_packet:send(MemId, Packet2),
%% 	player_api:process_send(MemId, ?MODULE, set_guess_reward_cb, [?CONST_SYS_TRUE]),
%% 	set_guess_reward(Player,?CONST_SYS_FALSE).
%% 
%% get_guess_reward(Lv,Res) ->
%% 	case data_guild:get_guild_party_reward(Lv) of
%% 		?null -> {?ok,0};
%% 		#rec_guild_party_reward{win_gold = Win,lost_gold = Lost} ->
%% 			case Res of
%% 				?CONST_SYS_TRUE ->
%% 					{?ok,Win};
%% 				_ ->
%% 					{?ok,Lost}
%% 			end
%% 	end.	
%% 
%% set_guess_reward(Player = #player{user_id = UserId,info = Info,net_pid = Pid},Res) ->
%% 	Lv				= Info#info.lv, 
%% 	{?ok,Value}		= get_guess_reward(Lv,Res),
%% 	{?ok,GuildM}	= get_paryt_member(UserId),
%% 	GoldSum			= GuildM#guild_party_member.gold + Value,
%% 	GuildM2			= GuildM#guild_party_member{gold = GoldSum},
%% 	Packet			= guild_party_api:msg_sc_party_gold(GoldSum),
%% 	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Value, ?CONST_COST_GUILD_GUESS_REWARD),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, GuildM2),
%% 	misc_packet:send(Pid, Packet),
%% 	{?ok,Player}.
%% 
%% set_guess_reward_cb(Player,[Res]) ->
%% 	set_guess_reward(Player,Res),
%% 	{?ok,Player}.
%% 	
%% %% 打平重来
%% guess_again(UserMem,UserGame,RivalMem,RivalGame) ->
%% 	UserGame2	= UserGame#guess_game{m_res = 0,o_res = 0},	
%% 	RivalGame2	= RivalGame#guess_game{m_res = 0,o_res = 0},	
%% 	guess_insert(UserMem,UserGame2,RivalMem,RivalGame2).
%% 
%% %% 通知对方
%% guess_notice(UserMem,UserGame,RivalMem,RivalGame,Type) ->
%% 	UserGame2	= UserGame#guess_game{m_res = Type},	
%% 	RivalGame2	= RivalGame#guess_game{o_res = Type},	
%% 	guess_insert(UserMem,UserGame2,RivalMem,RivalGame2).
%% 
%% %% 更新ets
%% guess_insert(UserMem,UserGame,RivalMem,RivalGame) ->
%% 	UserMem2 	= UserMem#guild_party_member{game = UserGame},
%% 	RivalMem2 	= RivalMem#guild_party_member{game = RivalGame},
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, RivalMem2).
%% 
%% %% 退出猜拳
%% guess_exit_request(Player) when is_record(Player,player) ->
%% 	UserId		= Player#player.user_id,
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		UserMem = #guild_party_member{state = ?CONST_GUILD_PARTY_GUESS} ->
%% 			guess_exit(UserMem);
%% 		_ -> ?ok
%% 	end.
%% 
%% guess_exit(UserMem = #guild_party_member{user_id = UserId,user_name = Name,game = Game}) ->
%% 	MemId		= Game#guess_game.mem_id,	
%% 	UserMem2 	= UserMem#guild_party_member{game = [],state = 0},
%% 	Packet2 	= guild_party_api:msg_sc_exit_guess(0),
%% 	Packet1 	= guild_party_api:msg_sc_res_guess(?CONST_GUILD_PARTY_LOST,0),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	misc_packet:send(UserId, <<Packet1/binary,Packet2/binary>>),
%% 	guess_exit_notice(MemId,Name).
%% 
%% guess_exit_notice(MemId,Name) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, MemId) of
%% 		RivalMem = #guild_party_member{state = ?CONST_GUILD_PARTY_GUESS} ->
%% 			get_guess_win(RivalMem,Name);
%% 		_ -> ?ok
%% 	end.
%% 
%% %% 邀请摇色子
%% invite_rock(Player,InviteId) when is_record(Player,player) -> 
%% 	UserId 	= Player#player.user_id,
%% 	Info 	= Player#player.info,
%% 	MapId	= Info#info.map_id,
%% 	Name 	= Info#info.user_name,
%% 	try
%% 		?ok 				= check_party_state(),
%% 		?ok					= check_map(MapId),
%% 		?ok					= check_invite_id(UserId,InviteId),
%% 		{?ok,TPlayer,Flag} 	= player_api:get_player_first(InviteId),
%% 		TInfo			 	= TPlayer#player.info,
%% 		?ok					= check_invite_online(Flag),
%% 		?ok					= check_invite_map(TInfo#info.map_id),
%% 		{?ok,_}				= check_rock_mem(UserId),
%% 		{?ok,_}				= check_rock_mem2(InviteId),
%% 		TipPacket			= message_api:msg_notice(?TIP_GUILD_PARTY_SEND_SUCCESS),
%% 		Packet 				= guild_party_api:msg_sc_invite_rock(UserId,Name),
%% 		misc_packet:send(InviteId, Packet),
%% 		misc_packet:send(Player#player.net_pid, TipPacket)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% check_map(?CONST_GUILD_PARTY_MAP) -> ?ok;
%% check_map(_) -> throw({?error,?TIP_GUILD_PARTY_NOT_JION}).
%% 
%% %% 检查自己状态
%% check_rock_mem(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_JION}); %% 不在宴会
%% 		UserMem = #guild_party_member{state = State,rock = Rock} ->
%% 			IsFree 	= is_free(State),
%% 			if
%% 				IsFree =:= ?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_OTHER}); %% 你在进行其他活动
%% 				Rock >= ?CONST_GUILD_PARTY_ROCK_TIMES ->
%% 					throw({?error,?TIP_GUILD_PARTY_ROCK_FULL}); %% 次数已满
%% 				?true ->
%% 					{?ok,UserMem}
%% 			end
%% 	end.
%% 
%% %% 检查对方状态
%% check_rock_mem2(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_MEM_NOT_JOIN}); %% 对方不在宴会
%% 		UserMem = #guild_party_member{state = State,rock = Rock} ->
%% 			IsFree 	= is_free(State),
%% 			if
%% 				IsFree =:= ?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_MEM_OTHER_GAME}); %% 对方在进行其他活动
%% 				Rock >= ?CONST_GUILD_PARTY_ROCK_TIMES ->
%% 					throw({?error,?TIP_GUILD_PARTY_MEM_ROCK_FULL}); %% 对方次数已满
%% 				?true ->
%% 					{?ok,UserMem}
%% 			end
%% 	end.
%% 
%% %% 处理邀请-拒绝
%% deal_with_invite_rock(Player,InviteId,?CONST_SYS_FALSE) when is_record(Player,player) -> 
%% 	try
%% 		?ok			= check_party_state(),
%% 		Info		= Player#player.info,
%% 		TipPacket 	= message_api:msg_notice(?TIP_GUILD_PARTY_REJECT,[{?TIP_SYS_COMM,Info#info.user_name}]), %% 对方拒绝
%% 		misc_packet:send(InviteId, TipPacket)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end;
%% %% 处理邀请-同意
%% deal_with_invite_rock(Player,InviteId,?CONST_SYS_TRUE) when is_record(Player,player) -> 
%% 	try
%% 		UserId 				= Player#player.user_id,
%% 		Info 				= Player#player.info,
%% 		MapId				= Info#info.map_id,
%% 		?ok					= check_party_state(),
%% 		?ok					= check_map(MapId),
%% 		{?ok,TPlayer,Flag} 	= player_api:get_player_first(InviteId),
%% 		TInfo			 	= TPlayer#player.info,
%% 		?ok					= check_invite_online(Flag),
%% 		?ok					= check_invite_map(TInfo#info.map_id),
%% 		{?ok,UserMem}		= check_rock_mem(UserId),
%% 		{?ok,InviteMem}		= check_rock_mem2(InviteId), 
%% 		deal_with_rock_agree(UserId,InviteId,UserMem,InviteMem)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% deal_with_rock_agree(UserId,InviteId,UserMem,InviteMem) ->
%% 	UserMem2 	= get_rock_mem(UserMem,InviteId),
%% 	InviteMem2	= get_rock_mem(InviteMem,UserId),
%% 	Packet1 	= get_rock_info(UserMem2,InviteId,InviteMem),
%% 	Packet2 	= get_rock_info(InviteMem2,UserId,UserMem),
%% 	misc_packet:send(UserId, Packet1),
%% 	misc_packet:send(InviteId, Packet2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, InviteMem2).
%% 
%% get_rock_mem(UserMem,MemId) ->
%% 	Game 	= init_rock_game(MemId),
%% 	State	= ?CONST_GUILD_PARTY_ROCK,
%% 	Rock	= UserMem#guild_party_member.rock, 
%% 	UserMem#guild_party_member{state = State, rock = Rock + 1,game = Game}.
%% 
%% get_rock_info(User,MemId,Mem) ->
%% 	case player_api:get_player_first(MemId) of
%% 		{?ok, #player{info = Info}, _} ->
%% 			Score1 	= User#guild_party_member.rock_score, 
%% 			Rock	= User#guild_party_member.rock , 
%% 			Times	= 5 - Rock,
%% 			MemName	= Mem#guild_party_member.user_name, 
%% 			MemSex	= Info#info.sex, 
%% 			MemPro	= Info#info.pro,
%% 			Score2	= Mem#guild_party_member.rock_score, 
%% 			guild_party_api:msg_sc_rock_data(Score1,Times,MemId,MemName,MemSex,MemPro,Score2);
%% 		_ -> <<>>
%% 	end.
%% 
%% %% 摇色子
%% rock(Player) when is_record(Player,player) -> 
%% 	try
%% 		Info			= Player#player.info,
%% 		?ok				= check_map(Info#info.map_id),
%% 		?ok				= check_party_state(),
%% 		{?ok,UserMem}	= get_rock_game(Player#player.user_id),
%% 		Game 			= UserMem#guild_party_member.game,
%% 		MemId			= Game#rock_game.mem_id,
%% 		rock2(Player,UserMem,MemId)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message(Player,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% rock2(Player,UserMem,0) ->
%% 	rock_single(Player#player.user_id,UserMem);
%% rock2(Player,UserMem,MemId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, MemId) of
%% 		RivalMem = #guild_party_member{state = ?CONST_GUILD_PARTY_ROCK} ->
%% 			rock_double(Player,MemId,UserMem,RivalMem);
%% 		_->
%% 			rock_single(Player#player.user_id,UserMem)
%% 	end.
%% 
%% %% 双方游戏
%% rock_double(Player,MemId,UserMem,RivalMem) when is_record(Player,player) ->
%% 	UserId		= Player#player.user_id,
%%   	UserGame 	= UserMem#guild_party_member.game,
%% 	RivalGame 	= RivalMem#guild_party_member.game,
%% 	OScore		= UserGame#rock_game.o_score,		
%% 	MScore		= UserGame#rock_game.m_score,
%% 	if
%% 		MScore =/= 0 ->
%% 			throw({?error,?TIP_GUILD_PARTY_GUESS_SEND});
%% 		?true ->
%% 			Num1 		= misc_random:random(1,6),
%% 			Num2 		= misc_random:random(1,6),
%% 			Num3 		= misc_random:random(1,6),
%% 			AddScore 	= Num1 + Num2 + Num3,
%% 			Score		= UserGame#rock_game.score,
%% 			CunNum		= UserGame#rock_game.cur_num, 
%% 			RivalScore	= RivalGame#rock_game.score,
%% 			NumPacket	= guild_party_api:msg_sc_rock(UserId,Num1,Num2,Num3),
%% 			if	
%% 				OScore =:= 0 ->	%% 通知对方开始
%% 					UserGame2	= UserGame#rock_game{m_score = AddScore},	
%% 					RivalGame2	= RivalGame#rock_game{o_score = AddScore},		
%% 					rock_insert(UserMem,RivalMem,UserGame2,RivalGame2),
%% 					misc_packet:send(MemId, NumPacket),
%% 					misc_packet:send(UserId, NumPacket),
%% 					{?ok,Player};
%% 				OScore =:= AddScore -> %% 平局
%% 					UserGame2	= UserGame#rock_game{m_score = 0, o_score = 0},	
%% 					RivalGame2	= RivalGame#rock_game{m_score = 0, o_score = 0},
%% 					AgainPacket	= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_AGAIN,AddScore,OScore),
%% 					rock_insert(UserMem,RivalMem,UserGame2,RivalGame2),
%% 					misc_packet:send(MemId, <<NumPacket/binary,AgainPacket/binary>>),
%% 					misc_packet:send(UserId, <<NumPacket/binary,AgainPacket/binary>>),
%% 					{?ok,Player};
%% 				OScore =/= 0 andalso CunNum >= 2 -> %% 结束游戏
%% 					{MPacketm,OPacket} 		= rock_current_res(AddScore,OScore),
%% 					{MAddScore,OAddScore}	= get_rock_score(Score + AddScore,RivalScore+OScore),
%% 					MScoreSum		= UserMem#guild_party_member.rock_score + MAddScore,
%% 					OScoreSum		= RivalMem#guild_party_member.rock_score + OAddScore,
%% 					UserMem2		= UserMem#guild_party_member{rock_score = MScoreSum,state = 0,game = []},
%% 					RivalMem2		= RivalMem#guild_party_member{rock_score = OScoreSum,state = 0,game = []},
%% 					rock_insert(UserMem2,RivalMem2,[],[]),
%% 					
%% 					{MRes,ORes} 			= get_rock_res(MAddScore,OAddScore),
%% 					{MPacketm2,OPacket2} 	= rock_res(MRes,ORes,MAddScore,OAddScore,MScoreSum,OScoreSum),
%% 					misc_packet:send(MemId, <<NumPacket/binary,OPacket/binary,OPacket2/binary>>),
%% 					misc_packet:send(UserId, <<NumPacket/binary,MPacketm/binary,MPacketm2/binary>>),
%% 					
%% 					player_api:process_send(MemId, ?MODULE, set_rock_reward_cb, [ORes]),
%% 					set_rock_reward(Player,MRes);
%% 				?true -> %% 结束当局，进行下一局
%% 					UserGame2	= UserGame#rock_game{score = Score + AddScore,m_score = 0, o_score = 0,cur_num = CunNum+1},	
%% 					RivalScore	= RivalGame#rock_game.score,
%% 					RivalGame2	= RivalGame#rock_game{score = RivalScore + OScore,m_score = 0, o_score = 0,cur_num = CunNum+1},
%% 					{MPacketm,OPacket} = rock_current_res(AddScore,OScore),
%% 					
%% 					rock_insert(UserMem,RivalMem,UserGame2,RivalGame2),
%% 					misc_packet:send(MemId, <<NumPacket/binary,OPacket/binary>>),
%% 					misc_packet:send(UserId, <<NumPacket/binary,MPacketm/binary>>),
%% 					{?ok,Player}
%% 			end
%% 	end.
%% 
%% %% 对方退出游戏
%% rock_single(UserId,UserMem) ->
%% 	UserGame 	= UserMem#guild_party_member.game,
%% 	Num1 		= misc_random:random(1,6),
%% 	Num2 		= misc_random:random(1,6),
%% 	Num3 		= misc_random:random(1,6),
%% 	AddScore 	= Num1 + Num2 + Num3,
%% 	CunNum		= UserGame#rock_game.cur_num,
%% 	Score		= UserGame#rock_game.score,
%% 	NumPacket	= guild_party_api:msg_sc_rock(UserId,Num1,Num2,Num3),
%% 	if
%% 		CunNum >= 2 -> %% 结束游戏
%% 			Score2		= UserGame#rock_game.score + AddScore + 10,
%% 			ScoreSum	= UserMem#guild_party_member.rock_score + Score2,
%% 			UserMem2	= UserMem#guild_party_member{rock_score = ScoreSum,state = 0,game = []},
%% 			Packet1		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,AddScore,0),
%% 			Packet2		= guild_party_api:msg_sc_rock_res(?CONST_GUILD_PARTY_WIN,Score2,ScoreSum,0),
%% 			misc_packet:send(UserId, <<NumPacket/binary,Packet1/binary,Packet2/binary>>);
%% 		?true ->
%% 			UserGame2	= UserGame#rock_game{score = Score + AddScore,m_score = 0, o_score = 0,cur_num = CunNum+1},	
%% 			UserMem2	= UserMem#guild_party_member{game = UserGame2},
%% 			Packet		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,AddScore,0), 
%% 			misc_packet:send(UserId, <<NumPacket/binary,Packet/binary>>)
%% 	end,
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2).
%% 
%% get_rock_win(UserId,UserMem) ->
%% 	UserGame 	= UserMem#guild_party_member.game,
%% 	CunNum		= UserGame#rock_game.cur_num,
%% 	MScore		= UserGame#rock_game.m_score,
%% 	if
%% 		MScore =/= 0 andalso CunNum >= 2 -> %% 结束游戏
%% 			Score2		= UserGame#rock_game.score + MScore + 10,
%% 			ScoreSum	= UserMem#guild_party_member.rock_score + Score2,
%% 			UserMem2	= UserMem#guild_party_member{rock_score = ScoreSum,state = 0,game = []},
%% 			ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 			Packet1		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,MScore,0),
%% 			Packet2		= guild_party_api:msg_sc_rock_res(?CONST_GUILD_PARTY_WIN,Score2,ScoreSum,0),
%% 			misc_packet:send(UserId, <<Packet1/binary,Packet2/binary>>);
%% 		MScore =/= 0 -> %% 已经猜拳返回当局胜利
%% 			Score2		= UserGame#rock_game.score + MScore ,
%% 			UserGame2	= UserGame#rock_game{mem_id = 0,score = Score2,m_score = 0, o_score = 0,cur_num = CunNum+1},	
%% 			UserMem2	= UserMem#guild_party_member{game = UserGame2},
%% 			ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 			Packet		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,MScore,0),
%% 			misc_packet:send(UserId, Packet);
%% 		?true ->
%% 			UserGame2	= UserGame#rock_game{mem_id = 0},
%% 			UserMem2	= UserMem#guild_party_member{game = UserGame2},
%% 			ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2)
%% 	end.
%% 
%% rock_current_res(MScore,OScore) when MScore > OScore ->
%% 	Packet1		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,MScore,OScore),
%% 	Packet2		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_LOST,OScore,MScore),
%% 	{Packet1,Packet2};
%% rock_current_res(MScore,OScore) when MScore < OScore ->
%% 	Packet1		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_LOST,MScore,OScore),
%% 	Packet2		= guild_party_api:msg_rock_result(?CONST_GUILD_PARTY_WIN,OScore,MScore),
%% 	{Packet1,Packet2}.
%% 	
%% rock_res(MRes,ORes,MAddScore,OAddScore,MScoreSum,OScoreSum) ->
%% 	Packet1		= guild_party_api:msg_sc_rock_res(MRes,MAddScore,MScoreSum,OScoreSum),
%% 	Packet2		= guild_party_api:msg_sc_rock_res(ORes,OAddScore,OScoreSum,MScoreSum),
%% 	{Packet1,Packet2}.
%% 
%% get_rock_reward(Lv,Res) ->
%% 	case data_guild:get_guild_party_reward(Lv) of
%% 		?null -> {?ok,0};
%% 		#rec_guild_party_reward{win_experience = Win,lost_experience = Lost} ->
%% 			case Res of
%% 				?CONST_SYS_TRUE ->
%% 					{?ok,Win};
%% 				_ ->
%% 					{?ok,Lost}
%% 			end
%% 	end.	
%% 
%% set_rock_reward(Player = #player{info = Info,user_id = UserId,net_pid = Pid},Res) ->
%% 	Lv				= Info#info.lv,
%% 	{?ok,Value} 	= get_rock_reward(Lv,Res),
%% 	{?ok,GuildM}	= get_paryt_member(UserId),
%% 	Experience 		= GuildM#guild_party_member.experience  + Value,
%% 	GuildM2			= GuildM#guild_party_member{experience  = Experience},
%% 	Player2 		= player_api:plus_experience(Player, Value),
%% 	Packet			= guild_party_api:msg_sc_party_experience(Experience),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, GuildM2),
%% 	misc_packet:send(Pid, Packet),
%% 	{?ok,Player2}.
%% 	
%% set_rock_reward_cb(Player,[Res]) ->
%% 	set_rock_reward(Player,Res).
%% 
%% get_rock_res(Score1,Score2) when Score1 > Score2 ->
%% 	{?CONST_GUILD_PARTY_WIN,?CONST_GUILD_PARTY_LOST};
%% get_rock_res(Score1,Score2) when Score1 =:= Score2 ->
%% 	{?CONST_GUILD_PARTY_AGAIN,?CONST_GUILD_PARTY_AGAIN};
%% get_rock_res(_Score1,_Score2) ->
%% 	{?CONST_GUILD_PARTY_LOST,?CONST_GUILD_PARTY_WIN}.
%% 
%% get_rock_score(Score1,Score2) when Score1 > Score2 ->
%% 	{Score1+10,Score2};
%% get_rock_score(Score1,Score2) when Score1 < Score2 ->
%% 	{Score1,Score2+10};
%% get_rock_score(Score1,Score2) when Score1 =:= Score2 ->
%% 	{Score1+10,Score2+10}.
%% 
%% rock_insert(UserMem,RivalMem,UserGame,RivalGame) ->
%% 	UserMem2 	= UserMem#guild_party_member{game = UserGame},
%% 	RivalMem2 	= RivalMem#guild_party_member{game = RivalGame},
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, RivalMem2).
%% 
%% %% 退出摇色子
%% rock_exit_request(Player) when is_record(Player,player) ->
%% 	UserId		= Player#player.user_id,
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		UserMem = #guild_party_member{state = ?CONST_GUILD_PARTY_ROCK} ->
%% 			rock_exit(UserMem);
%% 		_ -> ?ok
%% 	end.
%% 
%% rock_exit(UserMem = #guild_party_member{user_id = UserId,game = Game}) ->
%% 	MemId		= Game#rock_game.mem_id,
%% 	UserMem2 	= UserMem#guild_party_member{game = [],state = 0},
%% 	Packet1		= guild_party_api:msg_sc_rock_res(?CONST_GUILD_PARTY_LOST,0,0,0),
%% 	Packet2		= guild_party_api:msg_sc_exit_rock(0),	
%% 	misc_packet:send(UserId, <<Packet1/binary,Packet2/binary>>),
%% 	ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, UserMem2),
%% 	rock_exit_notice(MemId).
%% 	
%% rock_exit_notice(MemId) ->	
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, MemId) of
%% 		RivalMem = #guild_party_member{state = ?CONST_GUILD_PARTY_ROCK} ->
%% 			Packet		= guild_party_api:msg_sc_rock_exit(?CONST_SYS_TRUE),
%% 			misc_packet:send(MemId,Packet),
%% 			get_rock_win(MemId,RivalMem); 
%% 		_ -> ?ok
%% 	end.
%% 	
%% get_winner(MRes,ORes) when MRes =:= ORes ->
%% 	?CONST_GUILD_PARTY_AGAIN;
%% get_winner(?CONST_GUILD_PRATY_FIST,?CONST_GUILD_PRATY_NET) ->
%% 	?CONST_GUILD_PARTY_LOST;
%% get_winner(?CONST_GUILD_PRATY_NET,?CONST_GUILD_PRATY_FIST) ->
%% 	?CONST_GUILD_PARTY_WIN;
%% get_winner(?CONST_GUILD_PRATY_SCISSORS,?CONST_GUILD_PRATY_NET) ->
%% 	?CONST_GUILD_PARTY_WIN;
%% get_winner(?CONST_GUILD_PRATY_NET,?CONST_GUILD_PRATY_SCISSORS) ->
%% 	?CONST_GUILD_PARTY_LOST;
%% get_winner(?CONST_GUILD_PRATY_FIST,?CONST_GUILD_PRATY_SCISSORS) ->
%% 	?CONST_GUILD_PARTY_WIN;
%% get_winner(?CONST_GUILD_PRATY_SCISSORS,?CONST_GUILD_PRATY_FIST) ->
%% 	?CONST_GUILD_PARTY_LOST.
%% 
%% get_guess_game(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_JION}); %% 不在宴会
%% 		UserMem = #guild_party_member{state = State} ->
%% 			case is_guess(State) of
%% 				?true ->
%% 					{?ok,UserMem};
%% 				?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_OTHER}) %% 你在进行其他活动
%% 			end
%% 	end.	
%% 
%% get_rock_game(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_JION}); %% 不在宴会
%% 		UserMem = #guild_party_member{state = State} ->
%% 			case is_rock(State) of
%% 				?true ->
%% 					{?ok,UserMem};
%% 				?false ->
%% 					throw({?error,?TIP_GUILD_PARTY_OTHER}) %% 你在进行其他活动
%% 			end
%% 	end.
%% 
%% is_guess(State) when State =:= ?CONST_GUILD_PARTY_GUESS ->
%% 	?true;
%% is_guess(_) ->
%% 	?false.
%% 
%% is_rock(State) when State =:= ?CONST_GUILD_PARTY_ROCK ->
%% 	?true;
%% is_rock(_) ->
%% 	?false.
%% 
%% is_free(State) when State =:= ?CONST_GUILD_PARTY_FREE ->
%% 	?true;
%% is_free(_) ->
%% 	?false.
%% 
%% %% 获取全肉宴信息
%% desk_data(Player) when is_record(Player,player) -> 
%% 	try
%% 		{?ok,GuildM}		= get_paryt_member(Player#player.user_id),
%% 		{?ok,GuildParty}	= get_party(GuildM#guild_party_member.guild_id),
%% 		Times				= GuildParty#guild_party.desk,
%% 		Packet 				= guild_party_api:msg_sc_desk_times(Times),
%% 		misc_packet:send(Player#player.net_pid, Packet)
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message2(Player#player.net_pid,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% get_party(GuildId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_DISBAND});
%% 		GuildParty ->
%% 			{?ok,GuildParty}
%% 	end.
%% 	
%% check_desk_times(0) ->
%% 	throw({?error,?TIP_GUILD_PARTY_NO_MEAT});
%% check_desk_times(_) ->
%% 	?ok.
%% 
%% check_dinner_times(0) -> ?ok;
%% check_dinner_times(_) ->
%% 	throw({?error,?TIP_GUILD_PARTY_GET_MEAT}).
%% 
%% desk_reward(Player) when is_record(Player,player) -> 
%% 	UserId 				= Player#player.user_id,
%% 	Info				= Player#player.info,
%% 	try
%% 		?ok					= check_party_state(),
%% 		{?ok,GuildM}		= get_paryt_member(Player#player.user_id),
%% 		{?ok,GuildParty}	= get_guild_party(GuildM#guild_party_member.guild_id),
%% 		Desk				= GuildParty#guild_party.desk,
%% 		?ok					= check_desk_times(Desk),
%% 		
%% 		{?ok,PartyMember}	= get_paryt_member(UserId),
%% 		Dinner				= PartyMember#guild_party_member.dinner,
%% 		
%% 		?ok					= check_dinner_times(Dinner),
%% 		{?ok,Exp}			= get_desk_exp(Info#info.lv),
%% 		Desk2				= Desk - 1,
%% 		GuildParty2 		= GuildParty#guild_party{desk = Desk2},
%% 		
%% 		{?ok,Player2}		= player_api:exp(Player, Exp),
%% 		ExpSum				= PartyMember#guild_party_member.exp + Exp,
%% 		PartyMember2 		= PartyMember#guild_party_member{dinner = Dinner +1,
%% 															 exp 	= ExpSum},
%% 		
%% 		Packet1 			= guild_party_api:msg_sc_desk_times(Desk2),
%% 		Packet3				= guild_party_api:msg_sc_party_exp(ExpSum),
%% 		Packet2				= message_api:msg_notice(?TIP_GUILD_DESK_REWARD_SUCCESS, [{?TIP_SYS_COMM,misc:to_list(Exp)}]),	
%% 		
%% 		ets_api:insert(?CONST_ETS_GUILD_PARTY, GuildParty2),
%% 		ets_api:insert(?CONST_ETS_GUILD_PARTY_MEMBER, PartyMember2),
%% 		
%% 		misc_packet:send(UserId, <<Packet2/binary,Packet3/binary>>),
%% 		guild_party_api:brocast(GuildParty#guild_party.in_list, Packet1),
%% 		{?ok,Player2}
%% 	catch
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message(Player,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% %% 获取全肉宴经验
%% get_desk_exp(Lv) ->
%% 	case data_guild:get_guild_party_reward(Lv) of
%% 		?null ->
%% 			throw({?error,?TIP_COMMON_BAD_ARG});
%% 		#rec_guild_party_reward{din_exp = Exp} ->
%% 			{?ok,Exp}
%% 	end.
%% 
%% %% 重置桌子奖励
%% reset_desk_times(Player) when is_record(Player,player) -> 
%% 	try
%% 		UserId				= Player#player.user_id,
%% 		{?ok,PartyM}		= get_paryt_member(UserId),
%% 		{?ok,GuildParty} 	= get_guild_party(PartyM#guild_party_member.guild_id),
%% 		?ok					= check_reset_times(GuildParty#guild_party.desk),
%% 		?ok					= check_reset_money(Player#player.user_id),
%% 		Desk				= 10,	
%% 		GuildParty2 		= GuildParty#guild_party{desk = Desk},
%% 		
%% 		Packet 				= guild_party_api:msg_sc_desk_times(Desk),
%% 		Packet2 			= guild_party_api:msg_sc_reset_times(?CONST_SYS_TRUE),
%% 		
%% 		misc_packet:send(Player#player.net_pid, Packet2),
%% 		guild_party_api:brocast(GuildParty#guild_party.in_list, Packet),
%% 		ets_api:insert(?CONST_ETS_GUILD_PARTY, GuildParty2),
%% 		{?ok,Player}
%% 	catch
%% 		throw:{?error,?TIP_COMMON_CASH_NOT_ENOUGH} -> %% 元宝不足
%% 			{?ok,Player};
%% 		throw:{?error,ErrorCode} -> 	
%% 			guild_api:error_message(Player,ErrorCode);
%% 		A:B ->
%% 			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
%% 	end.
%% 
%% check_reset_money(UserId) ->
%% 	case player_money_api:minus_money(UserId, 1,?CONST_GUILD_PARTY_DESK_GOLD, ?CONST_COST_GUILD_RESET) of
%% 		?ok -> ?ok;
%% 		{?error, _ErrorCode} ->
%% 			throw({?error,?TIP_COMMON_CASH_NOT_ENOUGH})
%% 	end.
%% 		
%% 
%% %% 检查桌子可以领取的次数
%% check_reset_times(0) -> ?ok;
%% check_reset_times(_) -> 
%% 	throw({?error,?TIP_GUILD_PARTY_HAD_MEAT}).
%% 
%% party_end_reward([],_) -> ?ok;
%% party_end_reward([UserId | AllList],InList) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% 		?null -> ?ok;
%% 		#guild_party_member{exp = Exp,sp = Sp,gold = Gold,experience = Experience,time = TimeSum,enter_time = EnTime} ->
%% 			case lists:member(UserId, InList) of
%% 				  ?true -> 
%% 					  AddTime	= misc:seconds() - EnTime,
%% 					  Time		= get_end_time(TimeSum + AddTime),
%% 					  QPacket	= guild_party_api:msg_sc_party_quit_notice(?CONST_SYS_TRUE), 
%% 	%% 							  player_api:process_send(UserId,?MODULE,party_end_cb,[]),
%% 					  RPacket 	= guild_party_api:msg_sc_end_reward(?CONST_SYS_TRUE,Time,Exp,Sp,Gold,Experience),
%% 					  Packet	= <<QPacket/binary,RPacket/binary>>;
%% 				  _ -> 
%% 					  Time 		= get_end_time(TimeSum),			  
%% 					  Packet 	= guild_party_api:msg_sc_end_reward(?CONST_SYS_FALSE,Time,Exp,Sp,Gold,Experience)
%% 		 	end,					
%% %% 			Packet 	= guild_party_api:msg_sc_end_reward(Flag,Time,Exp,Sp,Gold,Experience),	
%% 			misc_packet:send(UserId,Packet),
%% 			ets_api:delete(?CONST_ETS_GUILD_PARTY_MEMBER, UserId)
%% 	end,
%% 	party_end_reward(AllList,InList).
%% 
%% get_end_time(Time) ->
%% 	if
%% 		Time > 1800 -> 1800;
%% 		?true -> Time 
%% 	end.
%% 
%% %% 宴会结束-退出场景、设置状态
%% party_end([]) -> ?ok;
%% party_end([UserId|MemberList]) ->
%% 	player_api:process_send(UserId,?MODULE,party_end_cb,[]),
%% 	party_end(MemberList).
%% 		
%% %% 宴会结束-设置Player状态
%% party_end_cb(Player,[]) ->
%% 	Info				= Player#player.info,
%% 	Packet	 			= guild_party_api:msg_sc_leave_party(?CONST_SYS_TRUE),
%% 	Player2				= map_api:enter_map(Player, Info#info.map_id_last),
%% 	{?ok,Player3} 		= set_player_state(Player2,?CONST_PLAYER_STATE_NORMAL),
%% 	{?ok,Player4} 		= set_state_play(Player3,?CONST_PLAYER_PLAY_CITY),
%% 	{?ok, NewPlayer} 	= task_api:update_active(Player4, {?CONST_ACTIVE_TYPE_PARTY, 1}),
%% 	
%% 	misc_packet:send(Player#player.net_pid, Packet),
%% 	{?ok,NewPlayer}.
%% 
%% %% 自动参加奖励
%% automatic_reward([],_) -> ?ok;
%% automatic_reward([UserId|List],Flag) ->
%% 	case player_api:check_online(UserId) of
%% 		?true ->
%% 			player_api:process_send(UserId, ?MODULE, automatic_reward_cb, [Flag]);
%% 		_ ->
%% 			player_offline_api:offline(guild_party_api,UserId,Flag)
%% 	end,
%% 	automatic_reward(List,Flag).
%% 
%% %% 自动参加离线领取奖励
%% automatic_reward_offline(Player,Flag) ->
%% 	auto_send_reward(Player,Flag).
%% 
%% %% 自动参加发送奖励
%% automatic_reward_cb(Player,[Flag]) ->
%% 	auto_send_reward(Player,Flag).
%% 
%% %% 自动参加发送奖励
%% auto_send_reward(Player = #player{info = Info,net_pid = Pid},Flag) when is_record(Player,player) ->
%% 	try
%% 		{?ok,Exp,Sp} 	= get_party_auto_reward(Info#info.lv),
%% 		{?ok,Player2} 	= player_api:exp(Player, Exp),
%% 		{?ok,Player3} 	= player_api:plus_sp(Player2, Sp, ?CONST_COST_PARTY_HOOK),
%% 		{?ok,Player4}	= add_activity_times(Player3,Flag),
%% 		{?ok,Player5}	= task_api:update_active(Player4, {?CONST_ACTIVE_TYPE_PARTY, 1}),
%% 		Packet 			= message_api:msg_notice(?TIP_GUILD_AUTO_PARTY_SUCCESS), 
%% 		misc_packet:send(Pid, Packet),
%% 		{?ok,Player5}
%% 	catch
%% 		throw:{?error,?TIP_GUILD_AUTO_PARTY_FAIL} ->
%% 			TipPacket 	= message_api:msg_notice(?TIP_GUILD_AUTO_PARTY_FAIL), 
%% 			misc_packet:send(Player#player.net_pid, TipPacket),
%% 			{?ok,Player};
%% 		_:_ ->
%% 			{?ok,Player}
%% 	end.
%% 
%% get_party_auto_reward(Lv) ->
%% 	case data_guild:get_guild_party_reward(Lv) of
%% 		?null ->
%% 			throw({?error,?TIP_COMMON_BAD_ARG});
%% 		#rec_guild_party_reward{auto_exp = Exp, auto_sp = Sp} ->
%% 			{?ok,Exp,Sp}
%% 	end.
%% 	
%% %% 检查宴会状态
%% check_party_state() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA,?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null ->
%% 			throw({?error,?TIP_GUILD_PARTY_END});
%% 		#party_data{state = ?CONST_ACTIVE_STATE_ON} ->
%% 			?ok;
%% 		_ ->
%% 			throw({?error,?TIP_GUILD_PARTY_NOT_START})
%% 	end.	
%% 
%% %% 设置正常状态
%% %% set_normal_state(Player) ->
%% %% 	set_player_state(Player,?CONST_PLAYER_STATE_NORMAL).
%% set_player_state(Player,State) ->
%% 	case player_state_api:try_set_state(Player, State) of
%% 		{?false, _} ->
%% 			{?ok, Player};
%% 		{?true, Player2} ->
%% 			{?ok, Player2}
%% 	end.
%% 
%% set_state_play(Player,State) ->	
%% 	case player_state_api:try_set_state_play(Player, State) of
%% 		{?false, _} ->
%% 			{?ok, Player};
%% 		{?true, Player2} ->
%% 			{?ok, Player2}
%% 	end.
%% 
%% %% init_party_member
%% init_party_member(UserId,UserName,GuildId,Time) ->
%% 	#guild_party_member{
%% 						user_id 		= UserId, 
%% 						user_name		= UserName,
%% 						guild_id		= GuildId,
%% 						enter_time		= Time
%% 						}.
%% 
%% %% init_guess_game
%% init_guess_game(MemId) ->
%% 	#guess_game{
%% 				mem_id				= MemId, %% MemId
%% 				cur_num 			= 1
%% 				}.
%% 
%% %% init_rock_game
%% init_rock_game(MemId) ->
%% 	#rock_game{
%% 				mem_id				= MemId, %% MemId
%% 				cur_num 			= 0
%% 				}.
%% 
%% 
%% 
