%% Author: Administrator
%% Created: 2012-12-26
%% Description: TODO: Add description to mcopy_mod
-module(mcopy_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([enter/1, enter_by_skip/2, check_team_play/2, exit/1, get_award_again/1, check_team_play1/2,
		 check_play_times/2, get_map_reward/1]).
-export([refresh_cb/2, refresh_cb1/2]).
-export([mcopy_battle_over/9, get_award/2, add_reward/2, delete_mon/1]).
%%
%% API Functions
%%
%% ------------------------------------------------------------------------------------------------
%% 进入团队战场
%% ------------------------------------------------------------------------------------------------
enter(Player) ->
	UserId		= Player#player.user_id,
	TeamId		= Player#player.team_id,
	Now			= misc:seconds(),
	case mcopy_api:get_team(TeamId)  of
		{?ok, Team} when is_record(Team, team) ->
			MCopySerId	= (Team#team.param)#team_param.id,	
			MapId		= get_copy_id(MCopySerId),                						%% 通过副本系列id获取副本地图id
			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_MULTI_COPY) of
				{?true, NewPlayer} ->
					case team_api:play_start(?CONST_TEAM_TYPE_COPY, TeamId) of
						?ok ->
							McopyInfo	= data_mcopy:get_mcopy(MapId),
							
							IsTick		= McopyInfo#rec_mcopy.is_tick,             		%% 一进入副本就建立栅栏
							
							NewPlayer1	= map_api:enter_map(NewPlayer, MapId),			%% 此处切换地图有个次序问题（概率性出现）
							MapPid		= NewPlayer1#player.map_pid,
							
							InfoList    = [{MapId, 1, Now}],
							EnterInfo	= #mcopy_info{info = InfoList},
							
							
							Packet1		= mcopy_api:msg_bar(1 ,IsTick),                  %% test 的栅栏ID = 1
							Packet2		= mcopy_api:msg_enter_mcopy(?CONST_SYS_TRUE),
							map_api:broadcast(MapPid,  <<Packet1/binary, Packet2/binary>>),
							
							UserList	= team_api:get_team_uids(Team),
							add_enter_times(UserList, TeamId, EnterInfo),
							
							NewUserList = lists:delete(UserId, UserList),
							
							{?ok, NewPlayer2} = refresh_cb1(NewPlayer1, [MCopySerId, TeamId]),
							process_send(NewUserList, ?MODULE, refresh_cb1, [MCopySerId, TeamId]),
							
							{?ok, NewPlayer3} = achievement_api:add_achievement(NewPlayer2, ?CONST_ACHIEVEMENT_MULTIPLAYER_COPY, 0, 1), %% 成就
							{?ok, NewPlayer3};
                        {?error, ?TIP_COMMON_CASH_NOT_ENOUGH} ->
                            {?ok, Player};
						{?error, ErrorCode} ->
							?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
							TipPacket     = message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player};
						{?error, ErrorCode, UserList} ->
							TipPacket     = message_api:msg_notice(ErrorCode, UserList, [], []),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player}
					end;
				{?false, Player, Tips} ->
					PacketErr		= message_api:msg_notice(Tips),
					misc_packet:send(Player#player.net_pid, PacketErr), 
					{?ok, Player}
			end;
		_ ->                                  %% 系统错误
			TipPacket	= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%%	----------------------------------------------------------------------------------------------
%% 跳转进入副本
%% ------------------------------------------------------------------------------------------------
enter_by_skip(Player, MapId) when is_integer(MapId) andalso MapId > 0 ->
	NewPlayer   = map_api:enter_map(Player, MapId),
	TeamId		= Player#player.team_id,
	case mcopy_api:get_team(TeamId)  of
		{?ok, Team} when is_record(Team, team) ->
			case mcopy_api:get_mcopy_info(Player#player.user_id) of
				McopyInfo when is_record(McopyInfo, mcopy_info) ->
					InfoList = McopyInfo#mcopy_info.info,
					case lists:keyfind(MapId, 1, InfoList) of
						{MapId, Times, Time} -> 
							NewInfo 		= [{MapId, Times + 1, Time}],
							NewMcopyInfo	= #mcopy_info{info = NewInfo},
							UserList		= team_api:get_team_uids(Team),
							add_enter_times(UserList, TeamId, NewMcopyInfo);
						_ -> ?ok
					end;
				_ -> ?ok
			end;
		_ -> ?ok
	end,
	{?ok, NewPlayer};
enter_by_skip(Player, _MapId) ->
	TipPacket	= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	{?ok, Player}.
			
refresh_cb(Player, [MCopySerId, TeamId]) when is_record(Player, player) andalso is_integer(MCopySerId) ->
	UserId			= Player#player.user_id,
	MapId		 	= get_copy_id(MCopySerId),
	McopyData	 	= Player#player.mcopy,
	Times		 	= McopyData#mcopy_data.times,
	Count		 	= mcopy_api:get_enter_max_times(MCopySerId),
	LeftTimes	 	= Count - Times,
	RobotList		= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
	?MSG_DEBUG("~n UserId=~p, RobotList=~p", [UserId, RobotList]),
	case mcopy_api:get_enter_times(Player, MapId) of
		Times1 when Times1 =:= ?CONST_SYS_TRUE -> 
			case LeftTimes =< ?CONST_SYS_FALSE of
				?true  -> {?ok, Player};
				?false ->
					case lists:member(UserId, RobotList) of													%% 机器人不扣次数
						?true  -> {?ok, Player};
						?false -> 
							NewMcopyData		= McopyData#mcopy_data{times = Times + 1},
							?MSG_DEBUG("111111111111111111NewMcopyData=~p", [NewMcopyData]),
							if NewMcopyData#mcopy_data.times =:= 3 ->
								   spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 1);
							   true ->
								   skip
							end,
							NewPlayer		    = Player#player{mcopy = NewMcopyData},
							{?ok, NewPlayer1}	= schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_MULTI_COPY),           %% 活动次数
							schedule_api:add_resource_times(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_MCOPY),
							admin_log_api:log_mcopy(NewPlayer1, MCopySerId, Times + 1),
							Packet				= schedule_api:packet_sc_play_times(?CONST_SCHEDULE_PLAY_MCOPY, LeftTimes - 1),
							misc_packet:send(UserId, Packet),
							{?ok, NewPlayer1}
					end
			end;
		_ -> {?ok, Player}
	end;
refresh_cb(Player, _) -> {?ok, Player}.

refresh_cb1(Player, [MCopySerId, TeamId]) when is_record(Player, player) ->
	UserId			= Player#player.user_id,
	McopyData		= Player#player.mcopy,
	Times			= McopyData#mcopy_data.times,
	Count			= mcopy_api:get_enter_max_times(MCopySerId),
	LeftTimes		= Count - Times,
	RobotList		= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
	?MSG_DEBUG("~n UserId=~p, RobotList=~p", [UserId, RobotList]),
	{?ok, NewPlayer}= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_MULTIPLAYER_COPY, 0, 1),             %% 成就
	case LeftTimes =< ?CONST_SYS_FALSE of
		?true ->  
			case lists:member(UserId, RobotList) of
				?true  -> {?ok, Player};
				?false ->
					NewMcopyData   = McopyData#mcopy_data{times = Times + 1},
					?MSG_DEBUG("2222222222222222222222NewMcopyData=~p", [NewMcopyData]),
					NewPlayer1	 = NewPlayer#player{mcopy = NewMcopyData},
					{?ok, NewPlayer1}
			end;
		?false -> {?ok, NewPlayer}
	end;
refresh_cb1(Player, _) -> {?ok, Player}.
%% ------------------------------------------------------------------------------------------------
%% 玩法判断
%% ------------------------------------------------------------------------------------------------
check_team_play(Player, Id) ->                                  
	McopyData		= Player#player.mcopy,
	McopyDataList	= McopyData#mcopy_data.list,
	Count			= mcopy_api:get_enter_max_times(Id),
	Times			= McopyData#mcopy_data.times,
	LeftTimes		= Count - Times,
	case lists:member(Id, McopyDataList) of
		?false -> {?error, ?TIP_MCOPY_NOT_OPEN};        % 未开放此玩法
		_ ->
			case LeftTimes > ?CONST_SYS_FALSE of
				?true  -> ?ok;
				?false -> {?error, ?TIP_MCOPY_TIMES_OVER}
			end
	end.
check_team_play1(Player, Id) ->
	McopyData		= Player#player.mcopy,
	McopyDataList	= McopyData#mcopy_data.list,
	case lists:member(Id, McopyDataList) of
		?false ->  {?error, ?TIP_MCOPY_FRIEND_NOT_OPEN}; % 未开放此玩法
		_ -> ?ok										 % 超过玩法次数,但可以被邀请进入
	end.
check_play_times(Player, Id) ->                              
	McopyData		= Player#player.mcopy,
	McopyDataList	= McopyData#mcopy_data.list,
	Count			= mcopy_api:get_enter_max_times(Id),
	Times			= McopyData#mcopy_data.times,
	LeftTimes		= Count - Times,
	case lists:member(Id, McopyDataList) of
		?false -> {?error, ?TIP_MCOPY_NOT_OPEN};		% 未开放此玩法
		_ ->
			case LeftTimes >= ?CONST_SYS_FALSE of
				?true  -> ?ok;
				?false -> {?error, ?TIP_MCOPY_TIMES_OVER}
			end
	end.
%% ------------------------------------------------------------------------------------------------
%% Vip翻牌奖励
%% ------------------------------------------------------------------------------------------------
get_award_again(Player) ->
	MapId       = map_api:get_cur_map_id(Player),
	MapSerId	= mcopy_api:get_serial_id(MapId),
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	UserId 		= Player#player.user_id,
	?MSG_DEBUG("MapId=~p", [MapId]),
	{GoodsList, _Meritorious, _Exp, _GoldBind} = get_map_reward(MapId),

	case check_play_times(Player, MapSerId) of                         % 判断是否又剩余次数
		?ok ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, ?CONST_MCOPY_VIP_REWARD, ?CONST_COST_MCOPY_VIP_REWARD) of
				?ok ->
					{?ok, Player1} =                                            % 道具
                        case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MCOPY_VIP_REWARD, 1, 1, 1, 0, 0, 1, []) of
							{?ok, Player_2, _, PacketBag} ->
								Packet		= msg_sc_award(GoodsList),
%% 								[Goods|_] 	= GoodsList,
%% 								Packet		= mcopy_api:msg_sc_award(Goods#goods.goods_id, Goods#goods.count, 3),
								TipsPacket	= mcopy_api:msg_notice_vip_award(Player_2, MapSerId, GoodsList),
								misc_app:broadcast_world(TipsPacket),					%% 通关奖励提示
								misc_packet:send(UserId, <<PacketBag/binary, Packet/binary>>),
								{?ok, Player_2};
							{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
								Packet		= msg_sc_award(GoodsList),
%% 								[Goods|_] 	= GoodsList,
%% 								Packet		= mcopy_api:msg_sc_award(Goods#goods.goods_id, Goods#goods.count, 3),
								misc_packet:send(UserId, Packet),
								GoodsIdList	= mail_api:get_goods_id(GoodsList, []),
								Content		= [{GoodsIdList}],
								mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_MCOPY_SEND, Content,
																  GoodsList, 0, 0, 0, ?CONST_MCOPY_VIP_REWARD),
								{?ok, Player};
							{?error, _ErrorCode} ->
								{?ok, Player}
						end,
					{?ok, Player1};
				{?error, _ErrorCode} ->
					{?ok, Player}
			end;
		{?error, _} ->        
            % 无剩余次数
			Packet		= msg_sc_award(GoodsList),
%% 			[Goods|_] 	= GoodsList,
%% 			Packet		= mcopy_api:msg_sc_award(Goods#goods.goods_id, Goods#goods.count, 3),
			misc_packet:send(UserId, Packet),
			{?ok, Player}
	end.

msg_sc_award([]) -> <<>>;
msg_sc_award([Goods|_Tail]) when is_record(Goods, goods)->
	mcopy_api:msg_sc_award(Goods#goods.goods_id, Goods#goods.count, 3);
msg_sc_award(_) -> <<>>.
%% ------------------------------------------------------------------------------------------------
%% 退出副本
%% ------------------------------------------------------------------------------------------------
%%{UserState, PlayState}	= player_state_api:get_state(Player),
exit(Player) -> 												
	UserId			= Player#player.user_id,
	case team_api:play_quit(Player) of
		{?ok, Player1}->
			mcopy_api:delete_mcopy_info(UserId),
			Player2			= map_api:return_last_city(Player1),
			player_attr_api:refresh_mcopy_buff(Player2#player{mcopy_buff = []});  %% 清除buff
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.
%% ------------------------------------------------------------------------------------------------
%% 战斗结束后处理
%% ------------------------------------------------------------------------------------------------
mcopy_battle_over(UserIdList, MonsterId, MapPid, MapData, MapParam, AtkPoint, DefPoint, TeamId, RobotList) ->
	Now			= misc:seconds(),
	MapId		= MapParam#map_param.ad1,
	
	BeginTime	= case erlang:length(UserIdList) =/= ?CONST_SYS_FALSE of
					  ?true ->
						  UserId		= lists:nth(?CONST_SYS_TRUE, UserIdList),
						  case mcopy_api:get_mcopy_info(UserId) of  %% 进入副本的开始时间
							  McopyInfo when is_record(McopyInfo, mcopy_info) ->
								  [{_, _, Time}]		= McopyInfo#mcopy_info.info,
								  Time;
							  _ -> Now - ?CONST_SYS_NUMBER_HUNDRED
						  end;
					  _ -> Now - ?CONST_SYS_NUMBER_HUNDRED
				  end,
	
	MonsterList 	= MapData#mcopy_map_data.mon_list,
	MonList1		= delete_mon(MonsterList),
	MonList2		= lists:delete(MonsterId, MonList1),
	?MSG_DEBUG("MonList2=~p", [MonList2]),
    Wave        	= MapData#mcopy_map_data.wave,
    IsFinishQ   	= MapData#mcopy_map_data.q_finish,
	StandardTime	= MapData#mcopy_map_data.standard_time,
	ConditionList	= MapData#mcopy_map_data.condition,
	MCopySerId		= mcopy_api:get_serial_id(MapId),
	MinusFlag		= mcopy_api:check_minus_times(MapId),
	
	case {Wave, MinusFlag}of                              %% 第一波胜利后扣次数
		{?CONST_SYS_FALSE, ?CONST_SYS_TRUE}-> 
			?MSG_DEBUG("Wave=~p, MinusFlag=~p", [Wave, MinusFlag]),
			process_send(UserIdList, ?MODULE, refresh_cb, [MCopySerId, TeamId]);
		{_, _} -> ?ok
	end,
	
     TimePass     = Now - BeginTime,   % 副本经过的时间
     Evaluate     = copy_single_api:get_eq(TimePass, StandardTime, AtkPoint, DefPoint),      			% 获取评价
    {PacketEncounter, NewWave} = 
		handler_wave_over(Wave, IsFinishQ, ConditionList, MapId, MapPid, UserIdList, MonList2, TeamId), %% 处理奇遇 跳转点  结束奖励
	case lists:keyfind(Wave, 1, ConditionList) of
		{_, Type, _} when Type =:= 4 -> 
            case ets:lookup(?CONST_ETS_TEAM_INFO_COPY, TeamId) of
                [] ->
                    ok;
                [#team{leader_uid = LeaderId, cross_list = CrossList, team_pid = TeamPid}] ->
                    case lists:keymember(LeaderId, #team_player.uid, CrossList) of
                        true ->
                            team_serv:destroy_cast(TeamPid);
                        _ ->
                            ok
                    end
            end,
			handler_mcopy_pass(MapId, Evaluate, AtkPoint, DefPoint, TimePass, UserIdList, RobotList);
		_ ->
			map_api:broadcast(MapPid, PacketEncounter)
	end,
    MapData#mcopy_map_data{mon_list = MonList2, wave = NewWave}.

%% 去除重复怪
delete_mon(MonList) ->
	case lists:member(?CONST_SYS_FALSE, MonList) of
		?true  ->
			NewMonList		= lists:delete(?CONST_SYS_FALSE, MonList),
			delete_mon(NewMonList);
		?false -> delete_mon([], MonList)
	end.
delete_mon([], MonList) -> MonList.

handler_wave_over(Wave, IsFinishQ, ConditionList, MapId, MapPid, UserIdList, MonList2, TeamId) ->
	case lists:keyfind(Wave, 1, ConditionList) of
		{Wave, Type, Id} ->
			case check_next_wave(MapId, Id) of
				?true  ->
					case MonList2 =:= [] of
						?true ->
							?MSG_DEBUG("Wave=~p, ConditionList=~p", [Wave, ConditionList]),
							handler_play(Type, Id, Wave, IsFinishQ, MapId, MapPid, UserIdList, TeamId);
						?false ->
							?MSG_DEBUG("Wave=~p, ConditionList=~p", [Wave, ConditionList]),
							{?ok, _Monster, PacketMonster} = mcopy_api:next_wave(MonList2),
							{PacketMonster, Wave + 1}
					end;
				?false ->
					?MSG_DEBUG("Wave=~p, ConditionList=~p", [Wave, ConditionList]),
					handler_play(Type, Id, Wave, IsFinishQ, MapId, MapPid, UserIdList, TeamId)
			end;
		?false ->
			?MSG_DEBUG("Wave=~p, MapId=~p ConditionList=~p", [Wave, MapId,ConditionList]),
			{?ok, _Monster, PacketMonster} = mcopy_api:next_wave(MonList2),
			{PacketMonster, Wave + 1}
	end.

check_next_wave(MapId, Id) ->
	case data_mcopy:get_mcopy(MapId) of
		McopyData when is_record(McopyData, rec_mcopy) ->
			SkipPoint2		= McopyData#rec_mcopy.skip_2,
			case Id =:= SkipPoint2 of
				?true -> ?true;
				_ -> ?false
			end;
		_ -> ?false
	end.


%% 根据类型来处理
handler_play(1, Id, Wave, ?CONST_SYS_FALSE, _MapId, _MapPid, _UserIdList, _) ->   %% 处理奇遇
	P 		= mcopy_api:msg_encounter(Id, ?CONST_SYS_TRUE),
	{P, Wave + 2};
handler_play(2, Id, _Wave, _IsFinishQ, _MapId, _MapPid, _UserIdList, _) ->   %% 处理机关
	P 		= mcopy_api:msg_encounter(Id, ?CONST_SYS_TRUE) ,
	{P, 0};
handler_play(3, Id, _Wave, _IsFinishQ, _MapId, _MapPid, _UserIdList, _) ->   %% 处理跳转点
	P 		= mcopy_api:msg_point(Id),
	{P, 0};
handler_play(4, _Id, _Wave, _IsFinishQ, MapId, _MapPid, UserIdList, TeamId) ->   %% 处理通关副本
	MapSer		= mcopy_api:get_serial_id(MapId),
	case team_api:play_over(?CONST_TEAM_TYPE_COPY, TeamId) of
		?ok ->
			process_send(UserIdList, ?MODULE, add_reward, [MapSer]);
		{?error, ErrorCode} ->
			?MSG_DEBUG("ErrorCode=~p", [ErrorCode])
	end,
	{<<>>, 0};
handler_play(_Type, _Id, _Wave, _IsFinishQ, _MapId, _MapPid, _UserIdList, _) ->   %% 其它
	{<<>>, 0}.

handler_mcopy_pass(MapId, Evaluate, AtkPoint, DefPoint, TimePass, UserIdList, RobotList) ->
	process_send(UserIdList, ?MODULE, get_award, {MapId, Evaluate, AtkPoint, DefPoint, TimePass, RobotList}).

%% 获取奖励
get_award(Player, {MapId, Evaluate, AtkPoint, DefPoint, TimePass, RobotList}) ->
	MapSer		= mcopy_api:get_serial_id(MapId),
	{GoodsList, Meritorious, Exp, _GoldBind}
		= get_map_reward(MapId),															   
	UserId 		= Player#player.user_id,
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	
	Lv   		= Info#info.lv,
	RankRate 	= rank_api:get_rank_rate(Lv),
	Exp2 		= round(Exp * RankRate), 
	
	case lists:member(UserId, RobotList) of
		?true  -> {?ok, Player};
		?false ->
			{?ok,NewPlayer} =
				case check_play_times(Player, MapSer) of                         % 判断是否有剩余次数
					?ok ->
						{?ok, Player2} = player_api:exp(Player, Exp2),            % 经验
						
						%% 			case GoldBind of                                     	   % 铜钱
						%% 				GoldBind when GoldBind > 0 ->
						%% 					player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind, ?CONST_COST_MCOPY_REWARD); 
						%% 				_ ->
						%% 					?ignore
						%% 			end,
						
						{?ok, Player3} =                                            % 道具
							case ctn_bag_api:put(Player2, GoodsList, ?CONST_COST_MCOPY_REWARD, 1, 1, 1, 0, 1, 1, []) of
								{?ok, Player2_2, _, _PacketBag} ->
									TipsPacket	= mcopy_api:msg_notice_vip_award(Player, MapSer, GoodsList),
									misc_app:broadcast_world(TipsPacket),					%% 通关奖励提示
									{?ok, Player2_2};
								{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
									GoodsIdList	= mail_api:get_goods_id(GoodsList, []),
									Content		= [{GoodsIdList}],
									mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_MCOPY_SEND, Content,
																	  GoodsList, 0, 0, 0, ?CONST_COST_MCOPY_REWARD),
									{?ok, Player2};
								{?error, _ErrorCode} ->
									{?ok, Player2}
							end,
						PacketEnd	= mcopy_api:msg_sc_mcopy_end(MapSer, 0, GoodsList, Evaluate, Exp, 0, 0, AtkPoint, DefPoint, TimePass),
						misc_packet:send(UserId, PacketEnd),
						player_api:plus_meritorious(Player3, Meritorious, ?CONST_COST_MCOPY_REWARD);
					{?error, _} ->                                                  % 无剩余次数
						PacketEnd	= mcopy_api:msg_sc_mcopy_end(MapSer, 0, [], Evaluate, Exp, 0, 0, AtkPoint, DefPoint, TimePass),
						misc_packet:send(UserId, PacketEnd),
						{?ok, Player}
				end,
			task_api:update_succ_count(NewPlayer,?CONST_MODULE_MCOPY1)  %%每日任务——团队战场
	end.
	

%% 获取奖励
get_map_reward(MapId) ->
	McopyData 	= data_mcopy:get_mcopy(MapId),
	Exp		  	= McopyData#rec_mcopy.exp,
	GoldBind  	= McopyData#rec_mcopy.gold_bind,
	GoodsDropId = McopyData#rec_mcopy.goods,
	GoodsList   = goods_drop_api:goods_drop(GoodsDropId),
	Meritorious	= McopyData#rec_mcopy.meritorious,
	{GoodsList, Meritorious, Exp, GoldBind}.

%% 通关祝福|成就｜记录所过关卡
add_reward(Player, [CopyId]) ->
	bless_api:send_be_blessed(Player, ?CONST_RELATIONSHIP_BLESS_TYPE_MCOPY, CopyId),
	welfare_api:add_pullulation(Player, ?CONST_WELFARE_MULTI_COPY, CopyId, ?CONST_SYS_TRUE),
	NewPlayer		= task_api:finish_mcopy(Player, CopyId),
    Info = NewPlayer#player.info,
    resource_api:finish_mcopy(NewPlayer#player.user_id, Info#info.user_name, Info#info.lv),
	{?ok, NewPlayer}.

%% 通过副本系列id获得副本地图id
get_copy_id(McopySerId) when is_integer(McopySerId) ->
	case data_mcopy:get_mcopy_serial(McopySerId) of
		McopySerData when is_record(McopySerData, mcopy_serial) ->
			List		= McopySerData#mcopy_serial.mcopy_list,
			McopyData	= lists:nth(?CONST_SYS_TRUE, List),
			McopyData#rec_mcopy.map;
		_ -> ?CONST_SYS_FALSE
	end.

process_send(UserList, M, F, A) ->
	?MSG_DEBUG("UserList=~p", [UserList]),
 	Fun = fun(UserId1) when UserId1 > 0 ->
               case ets:lookup(?CONST_ETS_CROSS_IN, UserId1) of
                   [] ->
                       player_api:process_send(UserId1, M, F, A);
                   [Rec] ->
                       Node = Rec#cross_in.node,
                       rpc:cast(Node, player_api, process_send, [UserId1, M, F, A])
               end;
		(X) ->
			?MSG_DEBUG("X=~p", [X])
        end,
    [Fun(UserId) || UserId <- UserList].

add_enter_times(UserList, TeamId, McopyInfo) ->
	F = fun(UserId) ->
				RobotList			= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
				case lists:member(UserId, RobotList) of
					?true  -> ?ok;
					?false ->
						NewMcopyInfo		= McopyInfo#mcopy_info{user_id = UserId},
						mcopy_api:insert_mcopy_info(NewMcopyInfo)
				end
		end,
	[F(UserId)|| UserId <- UserList].