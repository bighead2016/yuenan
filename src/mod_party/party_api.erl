%% Author: Administrator
%% Created: 2013-4-15
%% Description: TODO: Add description to party_api
-module(party_api).

%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.cost.hrl").
%%
%% Exported Functions
%%
-export([
		 init_ets_party_active/0,
		 save_activity_data/0,
		 init_ets/0,
		 save_all_doll/0,
		 quit_guild/1,
		 get_doll_list/0,
	 
		 get_auto_list/1,automatic_party/3,
		 flush_offline/2,
		 on/1,off/1, 
		 logout/1,
		 party_interval/0,
		 
		 battle_start/2,
		 battle_over/3,
		 refresh_monster/3,
		 play_start/0,
		 broadcast/2,
		 party_end_notice_cb/2
		 ]).


-export([
		 monster_msg/1,
		 msg_sc_time/2,
		 msg_sc_play_time/2,
		 msg_sc_reward/2,
		 msg_sc_box_data/1,
		 msg_sc_remove_box/1,
		 msg_sc_remove_monster/1,
		 msg_sc_play_start/1,
		 msg_sc_monster_data/1,
		 msg_sc_end_reward/4, 
		 msg_sc_sp_time/1,
		 msg_sc_auto_reward/2,
		 msg_sc_auto_pk/1,
		 msg_sc_apply_pk/2,
		 msg_sc_doll/1
		]).

%% 开服初始化军团宴会活动数据
init_ets_party_active() ->
	ets:delete_all_objects(?CONST_ETS_PARTY_ACTIVE),
	FiledList = [activity_id, record],
	case mysql_api:select(FiledList, game_activity_record) of
		{?ok, List} ->
			F = fun([_ActivityId, BinRecord]) ->
						Rec = mysql_api:decode(BinRecord),
						ets_api:insert(?CONST_ETS_PARTY_ACTIVE, Rec)
				end,
			[F(E) || E <- List];
		{?error, _ErrorCode} ->
			?ok
	end,
	?ok.

%% 关服军团宴会活动数据持久化
save_activity_data() ->
	try
		Sql = <<"delete from `game_activity_record`">>,
		mysql_api:select(Sql),
		List = ets_api:list(?CONST_ETS_PARTY_ACTIVE),
		[party_mod:save_activity_data(PartyActive) || PartyActive <- List]
	catch
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()])
	end.

%% 开服初始化军团宴会替身数据
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_PARTY_DOLL),
	FieldList = [user_id, record],
	case mysql_api:select(FieldList, game_party_doll) of
		{?ok, DollList} ->
			F = fun([_UserId, BinRecord]) ->
						Rec	= mysql_api:decode(BinRecord),
						ets_api:insert(?CONST_ETS_PARTY_DOLL, Rec)
				end,
			[F(E) || E <- DollList];
		{?error, _ErrorCode} ->
			?ok
	end.

%% 关服替身持久化操作
save_all_doll() ->
	try
		Sql = <<"delete from `game_party_doll`">>,
		mysql_api:select(Sql),
		DollList = ets_api:list(?CONST_ETS_PARTY_DOLL),
		[party_mod:save_doll_data(PartyDoll) || PartyDoll <- DollList]
	catch
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stack:~p", [E, R, erlang:get_stacktrace()])
	end.

%% 退出军团
quit_guild(Player) when is_record(Player, player) ->
	party_mod:quit_guild(Player);
quit_guild(UserId) when is_integer(UserId) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, Info} ->
			party_mod:quit_guild(#player{user_id = UserId, info = Info});
		{?error, Error} ->
			?MSG_ERROR("get player indo error:~p", [Error])
	end.			

%% 获取有效替身列表
get_doll_list() ->
	party_mod:get_doll_list().

%% 宴会开始  party_api:on([1]).
on([Flag]) ->
	clean_party_ets(),
	ets:delete_all_objects(?CONST_ETS_PARTY_ACTIVE),
	crond_api:interval_del(party_interval),
	PartyActive = record_party_active(Flag),
	party_mod:set_party_active(PartyActive),
	party_mod:set_active_auto(Flag),
	crond_api:interval_add(party_interval, 1, party_api, party_interval, []),
	party_mod:auto_start(Flag),
	robot_api:doll_enter_party(),
	?ok.

%% 宴会结束 party_api:off([1]).
off([Flag]) ->
	clean(Flag),
	?ok.

%% 发送自动参加奖励
send_auto_reward() ->
	case party_mod:get_party_active() of
		PartyActive when is_record(PartyActive,party_active) ->
			List 	= ets_api:list(?CONST_ETS_PARTY_AUTO),
			party_mod:auto_reward(List,PartyActive#party_active.flag);
		_ -> ?ok
	end,
	?ok.

%% 宴会结束通知
party_end_notice() ->
	Second	= misc:seconds(),
	List 	= ets_api:list(?CONST_ETS_PARTY_DATA),
	[party_end_notice2(MemberList,Second) || #party_data{member_list = MemberList} <- List].

party_end_notice2([],_) -> ?ok;
party_end_notice2([UserId|MemberList],Second) ->
	case party_mod:is_doll(UserId) of
		?false ->
			case party_mod:get_party_player(UserId) of
				#party_player{time = Time,exp = Exp,gold = Gold,sp = Sp,enter_time = EnterTime,exist = Exist} ->
					AddTime	= Second - EnterTime,
					Time2	= Time + AddTime,
					Packet	= msg_sc_end_reward(Time2,Exp,Sp,Gold),
					misc_packet:send(UserId,Packet),
					case Exist of
						?CONST_SYS_TRUE -> 
							player_api:process_send(UserId, ?MODULE, party_end_notice_cb, []);
						_ -> ?ok
					end;
				_ -> ?ok
			end;
		?true ->		%% 设置替身，活动结束玩家在线不发送通知
			?ok
	end,
	party_end_notice2(MemberList,Second).

party_end_notice_cb(Player,[]) ->
	task_api:update_active(Player, {?CONST_ACTIVE_TYPE_PARTY, 1}).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 战斗开始
battle_start(Player,Id) ->
	party_mod:battle_start(Player,Id). 

%% 战斗结束
battle_over(UserId, Result, BattleParam) ->
	party_mod:battle_over(UserId, Result, BattleParam).

%% 刷新怪物
refresh_monster(UserId, Id, HurtTuple) ->
	party_mod:refresh_monster(UserId, Id, HurtTuple).

%% 定时刷新怪物血量
refresh_monster_hp(Time) ->
	if
		Time rem 2 =:= 0 ->
			List		= ets_api:list(?CONST_ETS_PARTY_DATA),
			[party_serv:refresh_monster_hp_cast(Pid,PartyData) || PartyData = #party_data{pid = Pid} <- List];
		?true -> ?ok
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 定时器
party_interval() ->
	case party_mod:get_party_active() of
		?null ->
			crond_api:interval_del(party_interval);
		PartyActive ->
			party_interval(PartyActive)
	end.

party_interval(PartyActive = #party_active{state = 0}) -> %% 1分钟准备
	PartyActive2 = PartyActive#party_active{state = ?CONST_ACTIVE_STATE_ON},
	party_mod:set_party_active(PartyActive2);
party_interval(PartyActive = #party_active{state = ?CONST_ACTIVE_STATE_ON,end_time = EndTime,play_state = PlayState,
										   play1_start_time	= PlayStartTime1,play1_end_time	= PlayEndTime1,	
										   play2_start_time	= PlayStartTime2,play2_end_time	= PlayEndTime2,		
									  	   exp_time = ExpTime,flag = Flag}) ->
	try
	Time 	= misc:seconds(), 
	refresh_monster_hp(Time),
	if 
		Time >= EndTime ->	%% 结束
 			clean(Flag);
		Time >= PlayStartTime1 andalso Time < PlayEndTime1 andalso PlayState =:= 0 -> 	%% 玩法未开始-玩法1开始
			PartyActive2 = PartyActive#party_active{play_state = 1},
			party_mod:set_party_active(PartyActive2), 
			play_start();
		Time >= PlayEndTime1 andalso PlayState =:= 1 ->  	%% 玩法1结束	
			PartyActive2 = PartyActive#party_active{play_state = 0}, 
			party_mod:set_party_active(PartyActive2),
			play_end();
		Time >= PlayStartTime2 andalso Time < PlayEndTime2 andalso PlayState =:= 0 ->	%% 玩法2开始
			PartyActive2 = PartyActive#party_active{play_state = 2},
			party_mod:set_party_active(PartyActive2), 
			play_start();
		Time >= PlayEndTime2 andalso PlayState =:= 2 ->  	%% 玩法2结束	
			PartyActive2 = PartyActive#party_active{play_state = 0}, 
			party_mod:set_party_active(PartyActive2),
			play_end();
		Time >= ExpTime -> %% 定时获得经验
			PartyActive2 = PartyActive#party_active{exp_time = ExpTime + 120},
			party_mod:set_party_active(PartyActive2),
 			add_exp();
		?true -> ?ok
	end
	catch 
		E:R ->
			?MSG_ERROR("Error:~p, Reason:~p, Stacktrace:~p", [E, R, erlang:get_stacktrace()]),
			?ok
	end;
party_interval(_) ->
	crond_api:interval_del(party_interval).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法开始
play_start() ->
	List 	= ets_api:list(?CONST_ETS_PARTY_DATA),
	[party_serv:play_start_cast(Pid,PartyData) || PartyData = #party_data{pid = Pid} <- List],
	?ok.

%% 玩法结束
play_end() ->
	List 	= ets_api:list(?CONST_ETS_PARTY_DATA),
	[party_serv:play_end_cast(Pid,PartyData) || PartyData = #party_data{pid = Pid} <- List],
	?ok.

%% 增加经验
add_exp() ->
	List 	= ets_api:list(?CONST_ETS_PARTY_DATA),
	[party_serv:add_exp_cast(Pid,PartyData) || PartyData = #party_data{pid = Pid} <- List],
	?ok.

%% add_sp() ->
%% 	List 	= ets_api:list(?CONST_ETS_PARTY_DATA),
%% 	[party_serv:add_sp_cast(Pid,PartyData) || PartyData = #party_data{pid = Pid} <- List],
%% 	?ok.

%% 广播
broadcast([],_) -> ?ok;
broadcast([UserId|List],Packet) ->
	misc_packet:send(UserId, Packet),
	broadcast(List,Packet).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 清除
clean(Flag) ->
	party_end_notice(),
	send_auto_reward(),
	party_mod:auto_end(Flag),
	party_sup:party_end(),
	clean_party_ets(),
	crond_api:interval_del(party_interval).

clean_party_ets() ->
	%ets:delete_all_objects(?CONST_ETS_PARTY_ACTIVE),
	ets:delete_all_objects(?CONST_ETS_PARTY_DATA),
 	ets:delete_all_objects(?CONST_ETS_PARTY_PLAYER),
	ets:delete_all_objects(?CONST_ETS_PARTY_AUTO).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 退出
logout(Player) ->
	party_mod:quit(Player).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 获取自动参加列表
get_auto_list(UserId) ->
	case guild_api:ets_guild_member(UserId) of
		?null -> [];
		#guild_member{party_flag1 = Flag1,party_flag2 = Flag2} ->
			if
				Flag1 =:= ?CONST_SYS_TRUE andalso Flag2 =:= ?CONST_SYS_TRUE ->
					[?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY,
					 ?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY];
				Flag1 =:= ?CONST_SYS_TRUE ->
					[?CONST_SCHEDULE_ACTIVITY_EARLY_GUILD_PARTY];
				Flag2 =:= ?CONST_SYS_TRUE ->
					[?CONST_SCHEDULE_ACTIVITY_LATE_GUILD_PARTY];
				?true -> []
			end
	end.

%% 自动参加
automatic_party(Player, ActiveId, State) -> 
	party_mod:auto_party(Player, ActiveId, State).

%% flush_offline
%% 上线刷新-自动参加宴会奖励
flush_offline(Player, Flag) ->
	party_mod:auto_send_reward(Player,Flag).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
record_party_active(Flag) ->
	Time			= misc:seconds(),
	StartTime		= Time,
	
%% 	EndTime			= StartTime + 120,
%% 	PlayStartTime1	= StartTime + 40,
%% 	PlayEndTime1	= StartTime + 60,	
%% 	PlayStartTime2	= StartTime + 80,
%% 	PlayEndTime2	= StartTime + 100,
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	EndTime			= StartTime + 1800,
	PlayStartTime1	= StartTime + 600,
	PlayEndTime1	= StartTime + 900,	
	PlayStartTime2	= StartTime + 1200,
	PlayEndTime2	= StartTime + 1500,
	
	SpTime			= StartTime + 600,
	ExpTime			= StartTime + 120,
	
	MapId			= ?CONST_GUILD_PARTY_MAP,
	MapData 		= data_map:get_map(MapId),
	#party_active{
					id					= ?CONST_ACTIVE_TYPE_PARTY,
					state				= 0,
					flag 				= Flag,
					start_time  		= StartTime,
					end_time			= EndTime,
					
					play1_start_time	= PlayStartTime1,		
					play1_end_time		= PlayEndTime1,		
					
					play2_start_time	= PlayStartTime2,		
					play2_end_time		= PlayEndTime2,		
				 
					sp_time				= SpTime,		
					exp_time			= ExpTime,
					
					map_id				= MapId,
					x					= MapData#rec_map.x,
					y					= MapData#rec_map.y				
					}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
monster_msg(List) ->
	monster_msg(List,<<>>). 
monster_msg([],BinMsg) ->
	BinMsg;
monster_msg([Monster|List],BinMsg) ->
	Bin = party_api:msg_sc_monster_data(Monster),
	monster_msg(List,<<BinMsg/binary,Bin/binary>>).

%% 宴会时间
%%[StartTime,EndTime]
msg_sc_time(StartTime,EndTime) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_TIME, ?MSG_FORMAT_PARTY_SC_TIME, [StartTime,EndTime]).
%% 玩法时间
%%[Type,Time]
msg_sc_play_time(Type,Time) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_PLAY_TIME, ?MSG_FORMAT_PARTY_SC_PLAY_TIME, [Type,Time]).
%% 玩法开始
%%[Type]
msg_sc_play_start(Type) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_PLAY_START, ?MSG_FORMAT_PARTY_SC_PLAY_START, [Type]).
%% 收益
%%[Type,Value]
msg_sc_reward(Type,Value) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_REWARD, ?MSG_FORMAT_PARTY_SC_REWARD, [Type,Value]).
%% 更新宝箱信息
%%[{Id,Type,X,Y}]
msg_sc_box_data(List1) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_BOX_DATA, ?MSG_FORMAT_PARTY_SC_BOX_DATA, [List1]).
%% 移除宝箱
%%[Id]
msg_sc_remove_box(Id) -> 
	misc_packet:pack(?MSG_ID_PARTY_SC_REMOVE_BOX, ?MSG_FORMAT_PARTY_SC_REMOVE_BOX, [Id]).
%% 更新怪物信息
%%[Id,MonsterId,X,Y,Hp,HpMax]
msg_sc_monster_data(#party_monster{id = Id,monster_id = MonsterId,x = X,y = Y,hp = Hp,hp_max= HpMax,battle_list = BList}) ->
	Flag 	= case BList of
				  [] -> ?CONST_SYS_FALSE;
				  _ -> ?CONST_SYS_TRUE
			  end,			   
	misc_packet:pack(?MSG_ID_PARTY_SC_MONSTER_DATA, ?MSG_FORMAT_PARTY_SC_MONSTER_DATA, [Id,MonsterId,X,Y,Hp,HpMax,Flag]).
%% 移除怪物
%%[Id]
msg_sc_remove_monster(Id) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_REMOVE_MONSTER, ?MSG_FORMAT_PARTY_SC_REMOVE_MONSTER, [Id]).
%% 宴会结束奖励通知
%%[Flag,Time,Exp,Sp]
msg_sc_end_reward(Time,Exp,Sp,Gold) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_END_REWARD, ?MSG_FORMAT_PARTY_SC_END_REWARD, [Time,Exp,Sp,Gold]).
%% 体力累计时间
%%[Time]
msg_sc_sp_time(Time) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_SP_TIME, ?MSG_FORMAT_PARTY_SC_SP_TIME, [Time]).
%% 自动参宴奖励提示
%%[Time,Exp,Sp]
msg_sc_auto_reward(Exp,Sp) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_AUTO_REWARD, ?MSG_FORMAT_PARTY_SC_AUTO_REWARD, [Exp,Sp]).
%% 设置自动pk
%%[Flag] 
msg_sc_auto_pk(Flag) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_AUTO_PK, ?MSG_FORMAT_PARTY_SC_AUTO_PK, [Flag]).
%% 发起pk邀请
%%[UserId,UserName]
msg_sc_apply_pk(UserId,UserName) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_APPLY_PK, ?MSG_FORMAT_PARTY_SC_APPLY_PK, [UserId,UserName]).
%% 宴会替身
%%[{Type,State}]
msg_sc_doll(List1) ->
	misc_packet:pack(?MSG_ID_PARTY_SC_DOLL, ?MSG_FORMAT_PARTY_SC_DOLL, [List1]).
