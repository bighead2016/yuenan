%% Author: Administrator
%% Created: 2013-2-18
%% Description: TODO: Add description to guild_party_api
-module(guild_party_api).
%% 
%% %%
%% %% Include files
%% %%
%% -include("../../include/const.protocol.hrl").
%% -include("../../include/const.common.hrl").
%% -include("../../include/const.define.hrl").
%% -include("../../include/record.guild.hrl").
%% -include("../../include/const.tip.hrl").
%% -include("../../include/record.player.hrl").
%% -include("../../include/record.data.hrl").
%% -include("../../include/record.base.data.hrl").
%% %%
%% %% Exported Functions
%% %%
%% -export([
%% 		 on/1,off/1,logout/1,
%% 		 ready1/0,ready2/0,party_interval/0,
%% 
%% 		 party_exp/0,party_sp/0,party_rank/0,
%% 		 
%% 		 get_auto_list/1,
%% 		 automatic_party/3,set_active_auto_cb/2,
%% 		 flush_offline/2, 
%% 		 
%% 		 brocast/2,brocast_handle/2, 
%% 		 party_ready_handle/1,
%% 		 party_start_handle/1,
%% 		 party_end_handle/0 
%% 		]).
%% 
%% -export([
%% 		 msg_sc_end_reward/6,msg_sc_party_rank/1,
%% 		 msg_sc_party_exp/1,msg_sc_party_sp/1,
%% 		 msg_sc_party_gold/1,msg_sc_party_experience/1,
%% 		 msg_sc_partyinfo/5,msg_sc_partymem/1,
%% 		 msg_sc_partypartner/3,msg_sc_enter_party/1,msg_sc_leave_party/1,
%% 		 msg_sc_invite_guess/2,msg_sc_guess_info/7,
%% 		 msg_sc_out_guess/2,msg_sc_out_res/1,msg_sc_res_guess/2,
%% 		 msg_sc_invite_rock/2,msg_sc_rock_start/1,msg_rock_result/3,
%% 		 msg_sc_rock_data/7,msg_sc_rock/4,msg_sc_rock_res/4,
%% 		 msg_sc_exit_rock/1,msg_sc_exit_guess/1,msg_meat/1,
%% 		 msg_sc_desk_times/1,msg_sc_party_quit_notice/1,
%% 		 msg_sc_get_deskreward/1,msg_sc_reset_times/1,msg_sc_rock_exit/1]).
%% 
%% %%
%% %% API Functions
%% %%
%% 
%% logout(Player) when is_record(Player,player) ->
%% 	guild_party_mod:exit(Player).
%% 	
%% %% 广播 member_list 
%% brocast(MemberList,Packet) ->
%% 	guild_party_serv:brocast_cast(MemberList,Packet).
%% 
%% brocast_handle([],_Packet) -> ?ok;
%% brocast_handle([UserId|MemberList],Packet) ->
%% 	misc_packet:send(UserId, Packet),
%% 	brocast_handle(MemberList,Packet).
%% 
%% %% 宴会10分钟提示 guild_party_api:party_ready1().
%% ready1() -> 
%% 	Packet 	= message_api:msg_notice(?TIP_GUILD_PARTY_READY_BRO1),
%% 	misc_app:broadcast_world(Packet).
%% 	
%% %% 宴会3分钟提示  guild_party_api:party_ready2().
%% ready2() ->
%% 	Packet 	= message_api:msg_notice(?TIP_GUILD_PARTY_READY_BRO2),
%% 	misc_app:broadcast_world(Packet).	
%% 	
%% %% 宴会开始  guild_party_api:on([1]).
%% on([Flag]) -> 
%% 	ets:delete_all_objects(?CONST_ETS_PARTY_DATA),
%% 	ets:delete_all_objects(?CONST_ETS_GUILD_PARTY),
%% 	ets:delete_all_objects(?CONST_ETS_GUILD_PARTY_MEMBER),
%% 	crond_api:interval_del(party_interval),
%% 	
%% 	Time 		= misc:seconds(),
%% 	StartTime 	= Time + 60,
%% 	EndTime 	= StartTime + 30 * 60,
%% 	
%% 	PartyData = #party_data{
%% 							id				= ?CONST_ACTIVE_TYPE_PARTY,
%% 						 	state			= 0,
%% 						 	flag			= Flag,
%% 						 	start_time		= StartTime,
%% 							exp_time 		= StartTime, 
%% 							sp_time 		= StartTime, 
%% 							rank_time 		= StartTime,
%% 							end_time		= EndTime,
%% 							ready_time		= Time
%% 							},
%% 	ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData),
%% 	crond_api:interval_add(party_interval, 1, guild_party_api, party_interval, []).
%% 
%% party_interval() ->
%% 	case ets_api:lookup(?CONST_ETS_PARTY_DATA, ?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null ->
%% 			crond_api:interval_del(party_interval);
%% 		PartyData ->
%% 			party_interval(PartyData)
%% 	end.
%% 
%% party_interval(PartyData = #party_data{state = 0}) -> %% 1分钟准备
%% 	guild_party_serv:party_ready_cast(PartyData);
%% party_interval(PartyData = #party_data{state = ?CONST_ACTIVE_STATE_PRE_3,start_time = StartTime}) ->
%% 	Time 		= misc:seconds(),
%% 	if 
%% 		Time >= StartTime ->
%% 			guild_party_serv:party_start_cast(PartyData);
%% 		?true -> ?ok
%% 	end;
%% party_interval(PartyData = #party_data{state = ?CONST_ACTIVE_STATE_ON,end_time = EndTime,
%% 									   exp_time = ExpTime,sp_time = SpTime, rank_time = _RankTime}) ->
%% 	
%% 	Time 		= misc:seconds(), 
%% 	if 
%% 		Time >= EndTime ->
%% 			PartyData2 = PartyData#party_data{state = ?CONST_ACTIVE_STATE_OFF},
%% 			ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2),
%% 			
%% 			crond_api:interval_del(party_interval),
%% 			guild_party_serv:party_end_cast();
%% 		Time >= SpTime + 600 ->
%% 			PartyData2 = PartyData#party_data{sp_time = SpTime + 600},
%% 			ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2),
%% 			party_sp();
%% 		Time >= ExpTime + 120 ->
%% 			PartyData2 = PartyData#party_data{exp_time = ExpTime + 120},
%% 			ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2),
%% 			party_exp();
%% %% 		Time >= RankTime + 10 -> 
%% %% 			?MSG_PRINT("2222 ~p",[Time]),
%% %% 				?MSG_PRINT("222 ~p",[EndTime]),
%% %% 			?ok;
%% %% 			PartyData2 = PartyData#party_data{rank_time = RankTime + 10},
%% %% 			ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2),
%% %% 			party_rank();
%% 
%% 		?true -> 
%% 			?ok
%% 	end;
%% party_interval(_) ->
%% 	crond_api:interval_del(party_interval).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 宴会准备 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% party_ready_handle(PartyData) ->
%% 	Flag		= PartyData#party_data.flag,
%% 	GuildList	= party_ready(Flag),
%% 	PartyData2 	= PartyData#party_data{state = ?CONST_ACTIVE_STATE_PRE_3,guild_list = GuildList},
%% 	ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2).
%% 	
%% party_ready(Flag) ->
%% 	case ets_api:list(?CONST_ETS_GUILD_DATA) of
%% 		[]-> [];
%% 		GuildList ->
%% 			F = fun(GuildData,Acc) ->
%% 						GuildId 	= GuildData#guild_data.guild_id,						%% 军团id
%% 						MemberList	= GuildData#guild_data.member_list,
%% 						AutoList	= get_automatic_list(MemberList,Flag,[]),
%% 						Party 		= init_party(GuildId,AutoList),							%% 宴会数据
%% 						ets_api:insert(?CONST_ETS_GUILD_PARTY,Party),						%% 更新ets
%% 						[GuildId|Acc] 
%% 				end,
%% 			lists:foldl(F,[], GuildList)
%% 	end.
%% 
%% %% 获得自动参加列表		
%% get_automatic_list([],_Flag,List) -> List;
%% get_automatic_list([UserId|MemberList],Flag,List) ->
%% 	List2 	= case ets_api:lookup(?CONST_ETS_GUILD_MEMBER, UserId) of
%% 				  GuildM = #guild_member{party_flag1 = Flag1} 
%% 					when Flag1 =:= ?CONST_SYS_TRUE andalso Flag =:= 1 ->
%%   					  ets_api:insert(?CONST_ETS_GUILD_MEMBER, GuildM#guild_member{party_flag1 = 0}),
%% 					  check_automatic_money(UserId,List,Flag);
%% 				  GuildM = #guild_member{party_flag2 = Flag2} 
%% 					when Flag2 =:= ?CONST_SYS_TRUE andalso Flag =:= 2 ->
%%   					  ets_api:insert(?CONST_ETS_GUILD_MEMBER, GuildM#guild_member{party_flag2 = 0}),
%% 					  check_automatic_money(UserId,List,Flag);
%% 				  _ -> List
%% 			  end,
%% 	get_automatic_list(MemberList,Flag,List2).
%% 
%% %% 获得扣取元宝列表
%% check_automatic_money(UserId,List,Flag) ->
%% 	case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_GUILD_PARTY_AUTO_COST, 0) of
%% 		?ok ->
%% 			[UserId|List];
%% 		_ ->
%% 			Packet = message_api:msg_notice(?TIP_GUILD_AUTO_PARTY_FAIL),
%% 			misc_packet:send(UserId, Packet),
%% 			player_api:process_send(UserId,?MODULE,set_active_auto_cb,[Flag]),
%% 			List
%% 	end.
%% 
%% set_active_auto_cb(Player,[1]) ->
%% 	schedule_api:set_active_auto(Player, ?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY, ?CONST_SYS_FALSE);
%% set_active_auto_cb(Player,[2]) ->
%% 	schedule_api:set_active_auto(Player, ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY, ?CONST_SYS_FALSE).
%% 
%% init_party(GuildId,AutoList) ->
%% 	#guild_party{
%% 				 guild_id 			= GuildId,
%% 				 auto_list			= AutoList,
%% 				 desk				= ?CONST_GUILD_PARTY_DESK_REWARD
%% 				}.
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 宴会开始
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% party_start_handle(PartyData = #party_data{start_time = StartTime,end_time = EndTime,guild_list = GuildList}) ->	
%% 	PartyData2 	= PartyData#party_data{state = ?CONST_ACTIVE_STATE_ON},
%% 	Packet 		= message_api:msg_notice(?TIP_GUILD_PARTY_START_BROCAST),
%% 	misc_app:broadcast_world(Packet),
%% 	ets_api:insert(?CONST_ETS_PARTY_DATA, PartyData2),
%% 	
%% 	StartPacket	= msg_sc_partyinfo(?CONST_SYS_TRUE,0,EndTime - StartTime,
%% 								   ?CONST_GUILD_PARTY_GUESS_TIMES,
%% 								   ?CONST_GUILD_PARTY_ROCK_TIMES),	
%% 	party_start(GuildList,StartPacket).
%% 
%% party_start([],_StartPacket) -> ?ok;
%% party_start([GuildId|List],StartPacket) -> 
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 		?null -> ?ok;
%% 		#guild_party{in_list = MemberList} ->
%% 			set_guide_list(MemberList,StartPacket)
%% 	end,
%% 	party_start(List,StartPacket).
%% 
%% set_guide_list([],_StartPacket) -> ?ok;
%% set_guide_list([UserId|MemerList],StartPacket) -> 
%% 	misc_packet:send(UserId,StartPacket),
%% 	schedule_api:add_guide_times(UserId, ?CONST_SCHEDULE_GUIDE_GUILD_PARTY),
%% 	achievement_api:add_achievement(UserId, ?CONST_ACHIEVEMENT_GUILD_PARTY, 0, 1),
%% 	set_guide_list(MemerList,StartPacket).
%% 
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %% 宴会结束
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%guild_party_api:off(1).
%% off(_) -> 
%% 	guild_party_serv:party_end_cast().
%% 	
%% 
%% party_end_handle() ->
%%  	case ets_api:lookup(?CONST_ETS_PARTY_DATA, ?CONST_ACTIVE_TYPE_PARTY) of
%% 		?null -> ?ok;
%%  		PartyData ->
%% 			GuildList 		 	= PartyData#party_data.guild_list,
%% 			F = fun(GuildId) ->
%% 					party_end(GuildId,PartyData#party_data.flag)
%% 				end,
%% 			lists:foreach(F, GuildList),
%% 			
%% 			ets:delete_all_objects(?CONST_ETS_GUILD_PARTY),
%% 			ets:delete_all_objects(?CONST_ETS_PARTY_DATA),
%% 			
%% 			active_api:set_active_state(?CONST_ACTIVE_TYPE_PARTY,?CONST_GUILD_PARTY_END)
%%  	end.
%% 	
%% 
%% 
%% party_end(GuildId,Flag) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY, GuildId) of
%% 		?null -> ?ok;
%% 		#guild_party{in_list = InList,all_list = AllList,auto_list = Automatic} ->
%% %% 			guild_party_mod:party_end(InList),
%% 			guild_party_mod:party_end_reward(AllList,InList),
%% 			guild_party_mod:automatic_reward(Automatic,Flag)
%% 	end.
%% %% 	case ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId) of 
%% %% 		?null -> ?ok;
%% %% 		_GuildData = #guild_data{member_list = _MemberList,member_online = _MemOnline} ->
%% %% 			{GuessWin,RockWin}	= party_end_win(MemberList,#party_win{},#party_win{}),
%% %% 			Packet				= winner_msg(GuessWin,RockWin),
%% %% 			GuildData2			= GuildData#guild_data{guess_win = GuessWin, rock_win = RockWin},
%% %% 			ets_api:insert(?CONST_ETS_GUILD_DATA, GuildData2),					
%% %%  			guild_party_mod:automatic_reward(Automatic,Flag),
%% %% 			guild_api:brocast2_handle(MemOnline, Packet),
%% %% 			?ok
%% %% 	end.
%% 
%% %% 宴会结束
%% %% party_end_win([],GuessWin,RockWin) ->
%% %% 	{GuessWin,RockWin};
%% %% party_end_win([UserId|MemberList],GuessWin,RockWin) ->
%% %% 	case ets_api:lookup(?CONST_ETS_GUILD_PARTY_MEMBER, UserId) of
%% %% 		?null ->
%% %% 			party_end_win(MemberList,GuessWin,RockWin);
%% %% 		Mem ->
%% %% 			UserId 		= Mem#guild_party_member.user_id,
%% %% 			UserName 	= Mem#guild_party_member.user_name,
%% %% 			GuessScore 	= Mem#guild_party_member.guess_score,
%% %% 			RockScore 	= Mem#guild_party_member.rock_score,
%% %% 			GuessWin2 	= party_end_win(UserId,UserName,GuessScore,GuessWin),
%% %% 			RockWin2 	= party_end_win(UserId,UserName,RockScore,RockWin),
%% %% 			party_end_win(MemberList,GuessWin2,RockWin2)
%% %% 	end.
%% %% 
%% %% party_end_win(UserId,UserName,Score,PartyWin) ->
%% %% 	if
%% %% 		Score > PartyWin#party_win.score ->
%% %% 			#party_win{user_id 	= UserId, user_name = UserName, score = Score};
%% %% 		?true ->
%% %% 			PartyWin
%% %% 	end.
%% 
%% %% 胜利广播
%% %% winner_msg(GuessWin,RockWin) ->
%% %% 	Packet1 = case GuessWin#party_win.user_id  of
%% %% 				  0 -> <<>>;
%% %% 				  _ -> message_api:msg_notice(?TIP_GUILD_GUESS_WIN,[{0,GuessWin#party_win.user_name}])
%% %% 			  end,
%% %% 	Packet2 = case RockWin#party_win.user_id  of
%% %% 				  0 -> <<>>;
%% %% 				  _ -> message_api:msg_notice(?TIP_GUILD_ROCK_WIN,[{0,RockWin#party_win.user_name}])
%% %% 			  end,
%% %% 	<<Packet1/binary,Packet2/binary>>.
%% 
%% %% 宴会定时奖励
%% party_exp() -> 
%% 	guild_party_serv:party_exp_cast().
%% 
%% party_sp() ->
%% 	guild_party_serv:party_sp_cast().
%% 
%% party_rank() ->
%% 	guild_party_serv:party_rank_cast().
%% 
%% %%guild_party_api:automatic_party(Player,ActiveId,Flag)
%% %%Return: ?ok,{?error,ErrorCode}
%% automatic_party(Player,ActiveId,Flag) ->
%%  	guild_party_mod:automatic_party(Player,ActiveId,Flag).
%% 
%% get_auto_list(UserId) ->
%% 	case ets_api:lookup(?CONST_ETS_GUILD_MEMBER, UserId) of
%% 		?null -> [];
%% 		#guild_member{party_flag1 = Flag1,party_flag2 = Flag2} ->
%% 			if
%% 				Flag1 =:= ?CONST_SYS_TRUE andalso Flag2 =:= ?CONST_SYS_TRUE ->
%% 					[?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,
%% 					 ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY];
%% 				Flag1 =:= ?CONST_SYS_TRUE ->
%% 					[?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY];
%% 				Flag2 =:= ?CONST_SYS_TRUE ->
%% 					[?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY];
%% 				?true -> []
%% 			end
%% 	end.
%% 
%% %% flush_offline
%% flush_offline(Player,Data) ->
%% 	 guild_party_mod:automatic_reward_offline(Player,Data).
%% 
%% %% 军团宴会信息返回
%% %%[Type,Atmosphere,Time]
%% msg_sc_partyinfo(Type,Atmosphere,Time,GuessTimes,RockTimes) -> 
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTYINFO, ?MSG_FORMAT_GUILD_PARTY_SC_PARTYINFO, [Type,Atmosphere,Time,GuessTimes,RockTimes]).
%% %% 军团宴会成员返回
%% %%[{UserId,Name,Position,Level}]
%% msg_sc_partymem(List1) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTYMEM, ?MSG_FORMAT_GUILD_PARTY_SC_PARTYMEM, [List1]).
%% %% 军团宴会实时参加的人
%% %%[Type,Name,Value]
%% msg_sc_partypartner(Type,Name,Value) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTYPARTNER, ?MSG_FORMAT_GUILD_PARTY_SC_PARTYPARTNER, [Type,Name,Value]).
%% %% 进入宴会返回
%% %%[Result]
%% msg_sc_enter_party(Result) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ENTER_PARTY, ?MSG_FORMAT_GUILD_PARTY_SC_ENTER_PARTY, [Result]).
%% %% 退出宴会返回
%% %%[Result]
%% msg_sc_leave_party(Result) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_LEAVE_PARTY, ?MSG_FORMAT_GUILD_PARTY_SC_LEAVE_PARTY, [Result]).
%% %% 接收猜拳玩家信息
%% %%[Score1,Times,MemId,MemName,MemSex,MemPro,Score2]
%% msg_sc_guess_info(Score1,Times,MemId,MemName,MemSex,MemPro,Score2) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_GUESS_INFO, ?MSG_FORMAT_GUILD_PARTY_SC_GUESS_INFO, [Score1,Times,MemId,MemName,MemSex,MemPro,Score2]).
%% %% 返回被邀请猜拳玩家
%% %%[UserId,Name]
%% msg_sc_invite_guess(UserId,Name) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_INVITE_GUESS, ?MSG_FORMAT_GUILD_PARTY_SC_INVITE_GUESS, [UserId,Name]).
%% %% 玩家出猜拳返回
%% %%[UserId,Type] 
%% msg_sc_out_guess(UserId,Type) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_OUT_GUESS, ?MSG_FORMAT_GUILD_PARTY_SC_OUT_GUESS, [UserId,Type]).
%% %% 玩家出猜拳结果
%% %%[Res]
%% msg_sc_out_res(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_OUT_RES, ?MSG_FORMAT_GUILD_PARTY_SC_OUT_RES, [Res]).
%% %% 猜拳结果返回
%% %%[Res,Score1]
%% msg_sc_res_guess(Res,Score1) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_RES_GUESS, ?MSG_FORMAT_GUILD_PARTY_SC_RES_GUESS, [Res,Score1]).
%% %% 退出猜拳返回
%% %%[Score]
%% msg_sc_exit_guess(Score) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_EXIT_GUESS, ?MSG_FORMAT_GUILD_PARTY_SC_EXIT_GUESS, [Score]).
%% %% 接收摇色子玩家信息
%% %%[Score1,Times,MemId,MemName,MemSex,MemPro,Score2]
%% msg_sc_rock_data(Score1,Times,MemId,MemName,MemSex,MemPro,Score2) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ROCK_DATA, ?MSG_FORMAT_GUILD_PARTY_SC_ROCK_DATA, [Score1,Times,MemId,MemName,MemSex,MemPro,Score2]).
%% %% 返回被邀请摇色子玩家
%% %%[UserId,UserName]
%% msg_sc_invite_rock(UserId,UserName) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_INVITE_ROCK, ?MSG_FORMAT_GUILD_PARTY_SC_INVITE_ROCK, [UserId,UserName]).
%% %% 通知开始摇色子
%% %%[Res]
%% msg_sc_rock_start(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ROCK_START, ?MSG_FORMAT_GUILD_PARTY_SC_ROCK_START, [Res]).
%% %% 玩家摇色子结果返回
%% %%[UserId,Num1,Num2,Num3]
%% msg_sc_rock(UserId,Num1,Num2,Num3) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ROCK, ?MSG_FORMAT_GUILD_PARTY_SC_ROCK, [UserId,Num1,Num2,Num3]).
%% %% 当前局摇骰子结果返回
%% %%[Res,Score1,Score2]
%% msg_rock_result(Res,Score1,Score2) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_ROCK_RESULT, ?MSG_FORMAT_GUILD_PARTY_ROCK_RESULT, [Res,Score1,Score2]).
%% %% 摇色子结果返回
%% %%[Res,Score1,Score2,Score3]
%% msg_sc_rock_res(Res,Score1,Score2,Score3) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ROCK_RES, ?MSG_FORMAT_GUILD_PARTY_SC_ROCK_RES, [Res,Score1,Score2,Score3]).
%% %% 退出摇色子返回
%% %%[Score]
%% msg_sc_exit_rock(Score) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_EXIT_ROCK, ?MSG_FORMAT_GUILD_PARTY_SC_EXIT_ROCK, [Score]).
%% %% 返回宴会桌子次数
%% %%[Type,Times]
%% msg_sc_desk_times(Times) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_DESK_TIMES, ?MSG_FORMAT_GUILD_PARTY_SC_DESK_TIMES, [Times]).
%% %% 获取宴会桌子是否有肉
%% %%[Type,Result]
%% msg_meat(Result) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_MEAT, ?MSG_FORMAT_GUILD_PARTY_MEAT, [Result]).
%% 
%% %% 领取宴会桌子的奖励成功
%% %%[Res]
%% msg_sc_get_deskreward(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_GET_DESKREWARD, ?MSG_FORMAT_GUILD_PARTY_SC_GET_DESKREWARD, [Res]).
%% %% 重置宴会桌子次数返回
%% %%[Res]
%% msg_sc_reset_times(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_RESET_TIMES, ?MSG_FORMAT_GUILD_PARTY_SC_RESET_TIMES, [Res]).
%% %% 对方退出摇色子
%% %%[Res]
%% msg_sc_rock_exit(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_ROCK_EXIT, ?MSG_FORMAT_GUILD_PARTY_SC_ROCK_EXIT, [Res]).
%% %% 宴会结束奖励通知
%% %%[Flag,Exp,Sp,GoldBind,Experience]
%% msg_sc_end_reward(Flag,Time,Exp,Sp,GoldBind,Experience) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_END_REWARD, ?MSG_FORMAT_GUILD_PARTY_SC_END_REWARD, [Flag,Time,Exp,Sp,GoldBind,Experience]).
%% %% 增加经验 
%% %%[Exp] 
%% msg_sc_party_exp(Exp) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_EXP, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_EXP, [Exp]).
%% %% 增加体力
%% %%[Sp]
%% msg_sc_party_sp(Sp) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_SP, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_SP, [Sp]).
%% %% 增加铜钱
%% %%[Gold]
%% msg_sc_party_gold(Gold) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_GOLD, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_GOLD, [Gold]).
%% %% 增加历练
%% %%[Experience]
%% msg_sc_party_experience(Experience) -> 
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_EXPERIENCE, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_EXPERIENCE, [Experience]).
%% %% 排行信息
%% %%[List1]
%% msg_sc_party_rank(List1) -> 
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_RANK, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_RANK, [List1]).
%% %% 退出宴会通知
%% %%[Res]
%% msg_sc_party_quit_notice(Res) ->
%% 	misc_packet:pack(?MSG_ID_GUILD_PARTY_SC_PARTY_QUIT_NOTICE, ?MSG_FORMAT_GUILD_PARTY_SC_PARTY_QUIT_NOTICE, [Res]).
%% 
%%  
%% %%
%% %% Local Functions
%% %%
%% 
