%% Author: Administrator
%% Created: 2012-11-15
%% Description: TODO: Add description to tower_mod
-module(tower_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.tower.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.map.hrl").
-include("../../include/record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([open_tower/1, get_camp_info/2, enter_tower/2, get_pass_first_info/2, start_battle/2, start_sweep/3, reset_sweep_times/2,
		 get_tower_reward/2, speed_sweep/2, stop_sweep/1, quit_tower/1, check_sweep_end/1, get_vip_award/1, buy_reset_times/1,
		 get_offline_sweep_data/1, refresh_tower_times/1, refresh_attr/1, get_tower_times/1, logout/1]).
-export([clean_tower_times/0, get_speed_pass/3, set_pass_card/3, get_top_pass/1, get_award/6, get_camp_init/1, get_set_init_id/3,
		 get_auto_reward/3, clean_tower_times1/0, get_tower_vip_times/1, get_reset_times/2, get_tower_reset_times/1,
		 get_tower_sweep_times/1, stop_all_sweep/0]).

%%
%% API Functions
%%
%% 打开闯塔
open_tower(Player) ->
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TopScore  		= Tower#ets_tower_player.top_score,
			Packet 			= tower_api:msg_open_tower(TopScore),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获取闯塔大阵信息
get_camp_info(Player, CampId) ->
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			AllMaxPass 		= Tower#ets_tower_player.top_score,           %% 玩家闯塔最高层数
			CampInfo		= Tower#ets_tower_player.camp,			    
			Times			= get_reset_times(Player, Tower),
			case erlang:element(CampId, CampInfo) of				      %% {{towercamp,1,10,0....}
				Camp when is_record(Camp, towercamp) ->
					PassList 		= [{PassInfo#pass.id, PassInfo#pass.type}|| PassInfo <- Camp#towercamp.pass],
					TopPass  		= Camp#towercamp.top_pass,			  %% 本阵打到的最高关卡
					PastList		= Camp#towercamp.past_list,
					TopPass1		= get_pass_top_id(TopPass, PastList),
					IsGetAward		= Camp#towercamp.is_award,
					IsLight			= Camp#towercamp.is_light,
					LightId			= case AllMaxPass =:= ?CONST_SYS_FALSE of
										  ?true -> 
											  case IsLight =:= ?CONST_SYS_FALSE of
												  ?true -> ?CONST_SYS_TRUE;
												  ?false -> ?CONST_SYS_FALSE
											  end;
										  ?false -> get_light_id(Tower)    %% 获取闪烁的大阵id
									  end,
					case LightId =:= ?CONST_SYS_FALSE of
						?true  -> ?ok;
						?false ->
							Camp1			= erlang:element(LightId, CampInfo),
							NewCamp1		= Camp1#towercamp{is_light = ?CONST_SYS_TRUE},
							NewCampInfo		= erlang:setelement(LightId, CampInfo, NewCamp1),
							NewTower		= Tower#ets_tower_player{camp = NewCampInfo},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower)
					end,
					Packet 			= tower_api:msg_sc_select_camp(PassList, TopPass1, AllMaxPass, IsGetAward, Times, LightId),
					misc_packet:send(Player#player.net_pid,Packet);
				_ ->                          					          %% 大阵还没有开启
					TipPacket	    = message_api:msg_notice(?TIP_TOWER_CAMP_DISABLE),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获取打到的最高关卡
get_pass_top_id(Id, PastList) ->
	case erlang:length(PastList) =/= ?CONST_SYS_FALSE of
		?true ->
				[{_, Num}|_] = PastList,
				case Id > Num of
					?true  -> Id;
					?false -> Num
				end;
		?false -> Id
	end.

%% 获取闪烁的大阵id
get_light_id(Tower) ->
	TopScore		= Tower#ets_tower_player.top_score,
	CampInfo		= Tower#ets_tower_player.camp,
	?MSG_DEBUG("CampInfo=~p", [CampInfo]),
	CampList		= misc:to_list(CampInfo),
	Num				= erlang:length(CampList),
	F = fun(Camp, Acc) when Camp#towercamp.max_pass =:= TopScore ->
				CampId			= Camp#towercamp.id,
				NewCampId		= CampId + 1,
				?MSG_DEBUG("NewCampId=~p, Num=~p", [NewCampId, Num]),
				case NewCampId > Num of				%%判断是否超过了开放的大阵
					?true  ->?CONST_SYS_FALSE;
					?false ->
						case erlang:element(NewCampId, CampInfo) of
							NewCamp	when is_record(NewCamp, towercamp) ->
								FlagLight	= NewCamp#towercamp.is_light =:= ?CONST_SYS_FALSE,
								case FlagLight of
									?true -> NewCampId + Acc;
									?false -> ?CONST_SYS_FALSE 
								end;
							_ ->?CONST_SYS_FALSE
						end
				end;
		   (_, Acc) ->
				Acc
		end,
	lists:foldl(F, ?CONST_SYS_FALSE, CampList).
%%--------------------------------------------------------------------------------------------------------------------------------
%% 进入闯塔
enter_tower(Player, CampId) when CampId > ?CONST_TOWER_CAMP_COUNT ->
	TipPacket		= message_api:msg_notice(?TIP_TOWER_CAMP_DISABLE),
	misc_packet:send(Player#player.net_pid, TipPacket),
	{?ok, Player};
enter_tower(Player, CampId) when CampId < 1 ->
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	{?ok, Player};
enter_tower(Player, CampId) ->
	Now				= misc:seconds(),
	PlayerId 		= Player#player.user_id,
	Tower 			= tower_mod_create:get_tower_player(PlayerId),
	CampInfo		= Tower#ets_tower_player.camp,
	TowerSweep		= Tower#ets_tower_player.sweep,
	SweepList		= TowerSweep#towersweep.sweep_list,
	SweepNum		= erlang:length(SweepList),
	{Result, NewPlayer1}=
		case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_TOWER) of
			{?true, NewPlayer} ->
				{?true, NewPlayer};
			{?false, Player, _} ->
				{?false, Player}
		end,
	case {SweepNum =:= 0, Result} of
		{?true, ?true}->                   %%不在扫荡中且不在其它活动中
			case erlang:element(CampId, CampInfo) of
				Camp when is_record(Camp, towercamp) ->
					PassId		= case Camp#towercamp.top_pass =:= ?CONST_SYS_FALSE of 
									  ?true ->   %% 此大阵中没有通关关卡 从大阵的第一关开始
										  (Camp#towercamp.id - 1) * 10 + 1;
									  ?false ->  %% 记录新的最高通关关卡
										  Camp#towercamp.top_pass + 1
								  end,
					?MSG_PRINT("PassId=~p, Max_pass=~p", [PassId, Camp#towercamp.max_pass]),
					case {PassId >  Camp#towercamp.max_pass, PassId > ?CONST_TOWER_PASS_COUNT}of
						{?true, _} ->   %% 此阵已达最高关卡
							TipPacket		= message_api:msg_notice(?TIP_TOWER_CAMP_MAXPASS),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player};
						{_, ?true} ->   %% 已经打完所有关卡
							TipPacket		= message_api:msg_notice(?TIP_TOWER_ALL_OVER),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player};
						{?false, ?false} ->
							case data_tower:get_towerpass(PassId) of
								Pass when is_record(Pass, rec_tower_pass) ->
									TowerMap	= Pass#rec_tower_pass.map,
									NewCamp		= Camp#towercamp{start_time = Now},                       %% 记录进入闯塔的开始时间
									NewCampInfo	= erlang:setelement(CampId, CampInfo, NewCamp),
									NewTower	= Tower#ets_tower_player{camp = NewCampInfo},
									ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
									map_api:exit_map(NewPlayer1),                  						  %% 退出当前场景的地图
									MapLastInfo	= map_api:get_cur_map_info(NewPlayer1),
									?MSG_DEBUG("MapLast=~p TowerMap=~p PassId=~p", [MapLastInfo#map_info.map_id,TowerMap, PassId]),
									NewPlayer2	= case MapLastInfo#map_info.map_id =:= TowerMap of
													  ?true ->              	 						  %% 不更新地图数据
														  NewPlayer1#player{tower_passid = PassId};       %%闯塔id
													  ?false ->
														  MapData = Player#player.maps,
														  CurMapInfo = MapData#map_data.cur,
														  NewCurMapInfo = CurMapInfo#map_info{map_id = TowerMap},
														  
														  LastMapInfo = MapData#map_data.last,
														  NewLastMapInfo = LastMapInfo#map_info{
																								map_id = MapLastInfo#map_info.map_id, 
																								x      = MapLastInfo#map_info.x,
																								y      = MapLastInfo#map_info.y
																							   },
														  NewMapData = MapData#map_data{cur = NewCurMapInfo, last = NewLastMapInfo},
														  NewPlayer1#player{maps = NewMapData, map_pid = 0, tower_passid = PassId}  %%更新地图信息和闯塔id
												  end,
									{{MonsterId,_}}	= Pass#rec_tower_pass.monster_id,
									?MSG_PRINT("MapLast=~p, MonsterId=~p", [MapLastInfo#map_info.map_id, MonsterId]),
									Packet			= tower_api:msg_sc_start_rush(PassId, MonsterId),
									misc_packet:send(Player#player.net_pid, Packet),
									{?ok, NewPlayer2};
								_ ->
									TipPacket		= message_api:msg_notice(?TIP_TOWER_CAMP_DISABLE),
									misc_packet:send(Player#player.net_pid, TipPacket),
									{?ok, Player}
							end
					end;
				_ ->  			    %% 大阵还没开启
					TipPacket		= message_api:msg_notice(?TIP_TOWER_CAMP_DISABLE),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		{?false, _} ->   			    %% 在扫荡中，不能进入闯塔
			TipPacket		= message_api:msg_notice(?TIP_TOWER_IN_SWEEP_STATE),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		{_, ?false} ->                  %% 在其它玩法中，不能闯塔
			TipPacket		= message_api:msg_notice(?TIP_TOWER_UNABLE_ENTER),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 获取关卡首杀信息
get_pass_first_info(Player, PassId) ->
	case ets_api:lookup(?CONST_ETS_TOWER_PASS, PassId) of
		?null ->
			FirstName 	= <<"">>,
			FirstId		= 0,
			BestName	= <<"">>,
			BestId		= 0,
			Packet 		= tower_api:msg_sc_card(FirstName, FirstId, BestName, BestId),
			misc_packet:send(Player#player.net_pid, Packet);
		TowerPass ->
			FirstName 	= TowerPass#ets_tower_pass.first_name,
			FirstId		= TowerPass#ets_tower_pass.first_id,
			BestName	= TowerPass#ets_tower_pass.best_pass,
			BestId		= TowerPass#ets_tower_pass.best_passid,
			Packet 		= tower_api:msg_sc_card(FirstName, FirstId, BestName, BestId),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%%--------------------------------------------------------------------------------------------------------------------------------
%% 开始战斗
start_battle(Player, MonsterId) ->
	PassId 			= Player#player.tower_passid,
	case data_tower:get_towerpass(PassId) of
		Pass when is_record(Pass, rec_tower_pass) ->
			{{MonId, _}}	= Pass#rec_tower_pass.monster_id,
			MapId			= Pass#rec_tower_pass.map,
			case MonId =:= MonsterId of
				?true ->
					case battle_api:start(Player, MonsterId, #param{battle_type = ?CONST_BATTLE_TOWER, map_id = MapId, ad1 = PassId}) of
						{?ok, _NewPlayer} -> {?ok, _NewPlayer};
						{?error, _ErrorCode} -> {?ok, Player}
					end;
				?false ->
					?MSG_ERROR("start battle error ~p ~p~n",[MonsterId, PassId]),
					{?ok, Player}
			end;
		_ -> 
			?MSG_ERROR("start battle error ~p ~p~n",[MonsterId, PassId]),
			{?ok, Player}
	end.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 请求开始扫荡
start_sweep(Player, CampId, ?CONST_SYS_TRUE) ->
	IsFull			= ctn_api:is_full(Player#player.bag),
	VipLv			= player_api:get_vip_lv(Player),
	VipFlag			= player_vip_api:can_tower_sweep(VipLv),
	SweepList		= tower_sweep_api:get_sweep_list(Player, CampId),
	Num				= erlang:length(SweepList),
	case {IsFull, Num =:= ?CONST_SYS_FALSE, VipFlag }of
		{?true, _, _} ->                  %% 背包已满
			TipPacket		= message_api:msg_notice(?TIP_COMMON_BAG_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		{_, ?true, _}->                  %% 扫荡次数已满   
			TipPacket		= message_api:msg_notice(?TIP_TOWER_SWEEP_TIMES_OVER),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		{_, _, ?CONST_SYS_FALSE} ->		  %% VIP等级不足
			TipPacket 		= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		{?false, ?false, ?CONST_SYS_TRUE} ->%% 扫荡成功
			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_TOWER) of
				{?true, NewPlayer} ->
					tower_sweep_api:start_sweep(NewPlayer, CampId),
					{?ok, NewPlayer1}	= schedule_api:add_guide_times(NewPlayer, ?CONST_SCHEDULE_GUIDE_TOWER),        %% 每天任务		
                    catch gun_award_api:check_active(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_TOWER),		
					{?ok, NewPlayer1};
				{?false, Player, _} ->
					TipPacket 		= message_api:msg_notice(?TIP_COMMON_PLAY_STATE_OTHER),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end
	end;
start_sweep(Player, CampId, 2) ->
	UserId			= Player#player.user_id,
	SweepList		= tower_sweep_api:get_sweep_list(Player, CampId),
	NewSweepList	= lists:reverse(SweepList),
	Packet 			= tower_api:msg_sc_auto_rush(NewSweepList),
	Flag			= copy_single_api:get_auto_turn_card(UserId, ?CONST_ELITECOPY_AUTO_TURNCARD_TOWER),
	Packet1			= copy_single_api:msg_sc_auto_turncard(?CONST_ELITECOPY_AUTO_TURNCARD_TOWER, Flag),
	misc_packet:send(UserId, <<Packet/binary, Packet1/binary>>),
	{?ok, Player}.

%%--------------------------------------------------------------------------------------------------------------------------------
%% 请求重置
reset_sweep_times(Player, CampId) ->
	PlayerId 		= Player#player.user_id,
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			CampTuple		= Tower#ets_tower_player.camp,
			CampList		= misc:to_list(CampTuple),
			Times			= get_reset_times(Player, Tower),
			TimesFlag		= Times > ?CONST_SYS_FALSE,
			F = fun(Camp, Past) when is_record(Camp, towercamp) ->
						TempPast 	= Camp#towercamp.past_list,
						TempPast ++ Past;
				   (_Camp, Past) ->
						Past
				end,
			PastList    	= lists:foldl(F, [], CampList),
			SweepNum		= erlang:length(PastList),
			case {TimesFlag, SweepNum > ?CONST_SYS_FALSE} of
				{?false, _}->             %% 重置次数不足
					TipPacket = message_api:msg_notice(?TIP_TOWER_RESET_OVER),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{_, ?false} ->            %% 没有需要扫荡的关卡 不需要重置
					TipPacket = message_api:msg_notice(?TIP_TOWER_NOT_RESET),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{?true, ?true}->
					VipTimes		= player_vip_api:get_tower_reset_times(VipLv),
					case {VipTimes =:= ?CONST_SYS_TRUE, Times =:= ?CONST_SYS_TRUE} of
						{?true, ?true} ->
							Value		= ?CONST_TOWER_RESET_COST,
							case player_money_api:minus_money(PlayerId, ?CONST_SYS_CASH, Value, ?CONST_COST_TOWER_REFRESH) of
								?ok ->
									reset_tower_info(Player, Tower, CampId);
								{?error, _} ->
									?ignore
							end;
						_ -> 
							reset_tower_info(Player, Tower, CampId)
					end
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 重置闯塔信息
reset_tower_info(Player, Tower, CampId) ->
	AllMaxPass 		= Tower#ets_tower_player.top_score,
	CampTuple		= Tower#ets_tower_player.camp,
	CampList		= misc:to_list(CampTuple),
	ResetTimes		= Tower#ets_tower_player.reset_times,
	NewResetTimes 	= ResetTimes + 1,
	F = fun(Camp)  when is_record(Camp, towercamp) andalso CampId =:= Camp#towercamp.id ->
				PassList 	= [{PassInfo#pass.id, PassInfo#pass.type}|| PassInfo <- Camp#towercamp.pass],
				TopPass  	= ?CONST_SYS_FALSE,
				IsAward		= Camp#towercamp.is_award,
				TowerTemp	= Tower#ets_tower_player{reset_times = NewResetTimes},
				Times		= get_reset_times(Player, TowerTemp),
				Packet 		= tower_api:msg_sc_select_camp(PassList, TopPass, AllMaxPass, IsAward, Times, ?CONST_SYS_FALSE),
				misc_packet:send(Player#player.net_pid,Packet),
				Camp#towercamp{top_pass = 0, past_list = []};
		   (Camp) when is_record(Camp, towercamp) andalso CampId =/= Camp#towercamp.id ->
				Camp#towercamp{top_pass = 0, past_list = []};
		   (Camp) ->
				Camp
		end,
	NewCampList	  	= [F(CampInfo)||CampInfo <- CampList],
	NewCampTuple	= misc:to_tuple(NewCampList),
	NewTower		= Tower#ets_tower_player{reset_times = NewResetTimes, camp = NewCampTuple},
	ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
	tower_db_mod:update_sweep_info(Player, NewTower),
	LeftTimes		= get_reset_times(Player, NewTower),
	admin_log_api:log_tower(Player, LeftTimes),
	Packet = message_api:msg_notice(?TIP_TOWER_RESET_SUCCESS),
	misc_packet:send(Player#player.net_pid, Packet).

%% 获取剩余重置次数
get_reset_times(Player, Tower) ->
	VipLv			= player_api:get_vip_lv(Player),
	VipTimes		= player_vip_api:get_tower_reset_times(VipLv) + 1,
	ResetTimes		= Tower#ets_tower_player.reset_times,
	VipTimes - ResetTimes.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 领取破阵奖励
get_tower_reward(Player, CampId) ->
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			CampTuple		= Tower#ets_tower_player.camp,
			Camp			= erlang:element(CampId, CampTuple),
			IsGet			= Camp#towercamp.is_award,
			case IsGet =:= ?CONST_SYS_TRUE of
				?true ->  								            %% 成功领取破阵奖励　　
					MaxPassId 		= Camp#towercamp.max_pass,
					Pass			= data_tower:get_towerpass(MaxPassId),
					NewCamp			= Camp#towercamp{is_award = 2},
					NewCampInfo		= erlang:setelement(CampId, CampTuple, NewCamp),
					NewTower    	= Tower#ets_tower_player{camp = NewCampInfo},
					case tower_db_mod:update_get_award(Player, NewTower) of
						?ok ->
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
							CampRewad		= Pass#rec_tower_pass.camp_reward,      %% 获得礼券
							player_money_api:plus_money(PlayerId, ?CONST_SYS_CASH_BIND, CampRewad, ?CONST_COST_TOWER_LV_REWARD),
							TipPacket 		= message_api:msg_notice(?TIP_TOWER_CAMP_AWARD),
							Packet			= tower_api:msg_sc_get_award(?CONST_SYS_TRUE),
							misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary>>);
						{?error, _} ->
							TipPacket 		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
							misc_packet:send(Player#player.net_pid, TipPacket)
					end;
				?false ->
					case IsGet =:= ?CONST_SYS_FALSE of
						?true  ->  											%% 大阵还没有通关
							TipPacket 		= message_api:msg_notice(?TIP_TOWER_CARD_NOT_PASS),
							misc_packet:send(Player#player.net_pid, TipPacket);
						?false -> 									%% 已经领取了破阵奖励
							TipPacket 		= message_api:msg_notice(?TIP_TOWER_REWARD_NOT_EXIST),
							misc_packet:send(Player#player.net_pid, TipPacket)
					end
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 加速扫荡
speed_sweep(Player, 1) ->			%% 加速半小时
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	PlayerId 		= Player#player.user_id,
	Tower 			= tower_mod_create:get_tower_player(PlayerId),
	TowerSweep  	= Tower#ets_tower_player.sweep,
	EndTime			= TowerSweep#towersweep.end_time,
	InitId			= TowerSweep#towersweep.id,
	SweepList		= TowerSweep#towersweep.sweep_list,
	InitId			= TowerSweep#towersweep.id,
	IntervalTime	= TowerSweep#towersweep.interval_time,
	Cost			= case player_vip_api:can_raid_4_free(VipLv) of
						  ?CONST_SYS_FALSE -> 6  * 6;             %% 加速扣除的元宝
						  _ -> ?CONST_SYS_FALSE
					  end,
	Now				= misc:seconds(),
	NewEndTime		= EndTime - 30 * ?CONST_SYS_NUMBER_SIXTY,
	
	case NewEndTime > Now of
		?true ->				    %% 减少半小时扫荡时间
			case player_money_api:minus_money(PlayerId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_TOWER_SWEEP_SPEED_UP) of
				?ok ->
					Times		 	= erlang:trunc(30/IntervalTime),
					SpeedList		= get_speed_pass(SweepList, Times, []),
					?MSG_DEBUG("SpeedList=~p", [SpeedList]),
					LeftSweepList	= SweepList -- SpeedList,
					CurrentId		= lists:nth(?CONST_SYS_TRUE, LeftSweepList),
					case get_speed_pass_reward(Player, lists:reverse(SpeedList), [], []) of
						{?error, NewPlayer, Acc, Acc2} ->           %%背包满停止扫荡
							NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
											  sweep_list = [], interval_time = 0},
							NewTower		= set_speed_unable(InitId, Acc, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							case player_state_api:try_set_state_play(NewPlayer, ?CONST_PLAYER_PLAY_CITY) of
								{?true, NewPlayer1} -> NewPlayer1;
								{?false, NewPlayer1,_} -> NewPlayer1
							end;
						{?ok, NewPlayer, _, Acc2} ->
							NewTowerSweep	= TowerSweep#towersweep{current_id = CurrentId, end_time = NewEndTime, 
																	sweep_list = LeftSweepList},
							NewTower		= set_speed_unable(InitId, SpeedList, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer
					end;
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode =~p", [ErrorCode]),
					Player
			end;
		?false ->          			%% 加速使得立即完成扫荡
			case player_money_api:minus_money(PlayerId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_TOWER_SWEEP_ONCE) of
				?ok ->             			%% 加速成功
					Times		 	= erlang:length(SweepList),
					SpeedList		= get_speed_pass(SweepList, Times, []),
					?MSG_DEBUG("SpeedList=~p", [SpeedList]),
					NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
															sweep_list = [], interval_time = 0},
					Player1 		= case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
										  {?true, TempPlayer1} -> TempPlayer1;
										  {?false, TempPlayer1,_} -> TempPlayer1
									  end,
					case get_speed_pass_reward(Player1, lists:reverse(SpeedList), [], []) of
						{?error, NewPlayer, Acc, Acc2} ->
							NewTower		= set_speed_unable(InitId, Acc, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer;
						{?ok, NewPlayer, _, Acc2} ->
							NewTower		= set_speed_unable(InitId, SpeedList, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer
					end;
				{?error, ErrorCode} ->		%% 元宝不足，加速失败
					?MSG_PRINT("ErrorCode =~p", [ErrorCode]),
					Player
			end
	end;
speed_sweep(Player, 2) ->           %% 加速一小时
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	PlayerId 		= Player#player.user_id,
	Tower 			= tower_mod_create:get_tower_player(PlayerId),
	TowerSweep  	= Tower#ets_tower_player.sweep,
	EndTime			= TowerSweep#towersweep.end_time,
	InitId			= TowerSweep#towersweep.id,
	SweepList		= TowerSweep#towersweep.sweep_list,
	IntervalTime	= TowerSweep#towersweep.interval_time,
	Cost			= case player_vip_api:can_raid_4_free(VipLv) of
						  ?CONST_SYS_FALSE -> 12  * 6;             %% 加速扣除的元宝
						  _ -> ?CONST_SYS_FALSE
					  end,
	Now				= misc:seconds(),
	NewEndTime		= EndTime - ?CONST_SYS_NUMBER_SIXTY * ?CONST_SYS_NUMBER_SIXTY,
	case NewEndTime > Now of
		?true ->				    %% 减少一小时扫荡时间
			case player_money_api:minus_money(PlayerId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_TOWER_SWEEP_1HOUR) of
				?ok ->
					Times		 	= erlang:trunc(60/IntervalTime),
					SpeedList		= get_speed_pass(SweepList, Times, []),
					?MSG_DEBUG("SweepList=~p, SpeedList=~p", [SweepList, SpeedList]),
					LeftSweepList	= SweepList -- SpeedList,
					CurrentId		= lists:nth(?CONST_SYS_TRUE, LeftSweepList),
					case get_speed_pass_reward(Player, lists:reverse(SpeedList), [], []) of
						{?error, NewPlayer, Acc, Acc2} ->
							NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
											  sweep_list = [], interval_time = 0},
							NewTower		= set_speed_unable(InitId, Acc, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							case player_state_api:try_set_state_play(NewPlayer, ?CONST_PLAYER_PLAY_CITY) of
								{?true, NewPlayer1} -> NewPlayer1;
								{?false, NewPlayer1, _} -> NewPlayer1
							end;
						{?ok, NewPlayer, _, Acc2} ->
							NewTowerSweep	= TowerSweep#towersweep{current_id = CurrentId, end_time = NewEndTime, 
																	sweep_list = LeftSweepList},
							NewTower		= set_speed_unable(InitId, SpeedList, Tower),                     %% 置灰扫荡的关卡
							NewTower1		= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet			= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer
					end;
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode =~p", [ErrorCode]),
					Player
			end;
		?false ->          			%% 加速使得立即完成扫荡
			case player_money_api:minus_money(PlayerId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_TOWER_SWEEP_ONCE_2) of
				?ok ->             			%% 加速成功
					Times		 		= erlang:length(SweepList),
					SpeedList			= get_speed_pass(SweepList, Times, []),
					?MSG_DEBUG("SweepList=~p, SpeedList=~p", [SweepList, SpeedList]),
					Player1 			= case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
											  {?true, TempPlayer} -> TempPlayer;
											  {?false, TempPlayer, _} -> TempPlayer
										  end,
					case get_speed_pass_reward(Player1, lists:reverse(SpeedList), [], []) of
						{?error, NewPlayer, Acc, Acc2} ->
							?MSG_DEBUG("Acc=~p",[Acc]),
							NewTowerSweep		= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
																sweep_list = [], interval_time = 0},
							NewTower			= set_speed_unable(InitId, Acc, Tower),                 %% 置灰扫荡的关卡
							NewTower1			= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							NewAcc2			= lists:reverse(Acc2),
							Packet				= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer;
						{?ok, NewPlayer, _, Acc2} ->
							NewTowerSweep		= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
																sweep_list = [], interval_time = 0},
							NewTower			= set_speed_unable(InitId, SpeedList, Tower),                     %% 置灰扫荡的关卡
							NewTower1			= NewTower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
							tower_db_mod:end_sweep(PlayerId, NewTower1),
							NewAcc2			    = lists:reverse(Acc2),
							Packet				= tower_api:msg_sc_speed(0, NewAcc2),
							misc_packet:send(Player#player.net_pid, Packet),
							NewPlayer
					end;
				{?error, ErrorCode} ->		%% 元宝不足，加速失败
					?MSG_PRINT("ErrorCode =~p", [ErrorCode]),
					Player
			end
	end;
speed_sweep(Player, 3) ->           %% 立即完成扫荡
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	Now				= misc:seconds(),
	PlayerId 		= Player#player.user_id,
	Tower 			= tower_mod_create:get_tower_player(PlayerId),
	TowerSweep  	= Tower#ets_tower_player.sweep,
	EndTime			= TowerSweep#towersweep.end_time,
	SweepList		= TowerSweep#towersweep.sweep_list,
	InitId			= TowerSweep#towersweep.id,
	Times		 	= erlang:length(SweepList),
	SpeedList		= get_speed_pass(SweepList, Times, []),
	MinTime			= misc:ceil((EndTime - Now)/?CONST_SYS_NUMBER_SIXTY),
	Cost			= case player_vip_api:can_raid_4_free(VipLv) of
						  ?CONST_SYS_FALSE -> 
							  misc:ceil(MinTime/5) * 6;                                    %% 每5分钟6个元宝
						  _ -> ?CONST_SYS_FALSE
					  end,
	Now				= misc:seconds(),
	case player_money_api:minus_money(PlayerId, ?CONST_SYS_BCASH_FIRST, Cost, ?CONST_COST_TOWER_SWEEP_ONCE_3) of
		?ok ->             			%% 加速成功
			Player1 	= case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
							  {?true, TempPlayer} -> TempPlayer;
							  {?false, TempPlayer, _} ->TempPlayer
						  end,
			case get_speed_pass_reward(Player1, lists:reverse(SpeedList), [], []) of
				{?error, NewPlayer, Acc, Acc2} ->
					NewTower			= set_speed_unable(InitId, Acc, Tower),
					NewTowerSweep		= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
																sweep_list = [], interval_time = 0},
					NewTower1			= NewTower#ets_tower_player{sweep = NewTowerSweep},
					ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
					tower_db_mod:end_sweep(PlayerId, NewTower1),
					NewAcc2			    = lists:reverse(Acc2),
					Packet				= tower_api:msg_sc_speed(0, NewAcc2),
					misc_packet:send(Player#player.net_pid, Packet),
					NewPlayer;
				{?ok, NewPlayer, _, Acc2} ->
					NewTower			= set_speed_unable(InitId, SpeedList, Tower),
					NewTowerSweep		= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
																sweep_list = [], interval_time = 0},
					NewTower1			= NewTower#ets_tower_player{sweep = NewTowerSweep},
					ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower1),
					tower_db_mod:end_sweep(PlayerId, NewTower1),
					NewAcc2			    = lists:reverse(Acc2),
					Packet				= tower_api:msg_sc_speed(0, NewAcc2),
					misc_packet:send(Player#player.net_pid, Packet),
					NewPlayer
			end;
		{?error, ErrorCode} ->		%% 元宝不足，加速失败
			?MSG_PRINT("ErrorCode =~p", [ErrorCode]),
			Player
	end.

%% 获取加速关卡的奖励get_speed_pass(Player, [{1},{2},{3},{4},{5}], []).
get_speed_pass_reward(Player, [{PassId}|RestList], Acc, Acc2) ->
	Pass		  = data_tower:get_towerpass(PassId),
	RewardId	  = Pass#rec_tower_pass.award,                %%掉落奖励
	GoodList	  = goods_api:goods_drop(RewardId),
	NewGoodsList  = tower_sweep_api:get_goods_info(GoodList, []),
	Exp			  = Pass#rec_tower_pass.exp,
	Gold		  = Pass#rec_tower_pass.gold,
	MapId		  = Pass#rec_tower_pass.map,
	{{MonsterId,_}}= Pass#rec_tower_pass.monster_id,
	MonsterIdList = [{MonsterId}],
	case tower_sweep_api:get_reward(Player, GoodList, Exp, Gold, ?CONST_COST_TOWER_QUICK_SWEEP, PassId) of
		{?error, NewPlayer} -> {?error, NewPlayer, Acc, Acc2};
		{?ok, NewPlayer} ->
			{?ok, NewPlayer1}= task_api:update_battle(NewPlayer, MapId, MonsterIdList, 
													  ?CONST_BATTLE_RESULT_LEFT, ?CONST_BATTLE_TOWER),
			{?ok, NewPlayer2}= get_auto_reward(NewPlayer1, ?CONST_COST_TOWER_QUICK_SWEEP, PassId),
			NewAcc		  = [{PassId}| Acc],
			NewAcc2		  = [{PassId, Exp, Gold, NewGoodsList} |Acc2],
			get_speed_pass_reward(NewPlayer2, RestList, NewAcc, NewAcc2)
	end;
get_speed_pass_reward(Player, [], Acc, Acc2) ->
	{?ok, Player, Acc, Acc2}.

%%　获取加速的关卡 tower_mod:get_speed_pass([{1},{2},{3},{4},{5}], 5, []).
get_speed_pass([{SweepId}|SweepList], Times, Acc) when Times > 0->
	NewAcc		= [{SweepId}|Acc] ,
	NewTimes	= Times - 1,
	get_speed_pass(SweepList, NewTimes, NewAcc);
get_speed_pass(_, 0, NewAcc) ->
	?MSG_DEBUG("NewAcc=~p", [NewAcc]),
	NewAcc.
%% 	lists:reverse(NewAcc).

%% 置灰加速的关卡
set_speed_unable(InitId, SpeedList, Tower) ->
	LevelId			= tower_sweep_api:get_current_camp(misc:to_list(InitId)),
	case erlang:length(SpeedList) >?CONST_SYS_FALSE of
		?true ->
			{EndPass}		= lists:nth(?CONST_SYS_TRUE, SpeedList),                                %% 能加速到的最高关卡
			?MSG_DEBUG("InitId=~p ,EndPass=~p, SpeedList=~p", [InitId, EndPass, SpeedList]),
			StartId			= get_set_init_id(?CONST_SYS_TRUE, EndPass, []),
			case StartId =:= ?CONST_SYS_TRUE of
				?true  -> set_pass_unable1(?CONST_SYS_TRUE, Tower, EndPass);
				?false ->
					NewTower	= set_pass_unable(StartId, LevelId, Tower),
					set_pass_unable1(StartId, NewTower, EndPass)
			end;
		?false -> Tower
	end.

get_set_init_id(Id, EndPass, Acc) when EndPass > Id * 10 ->
	NewAcc		= [Id|Acc],
	get_set_init_id(Id + 1, EndPass, NewAcc);
get_set_init_id(_, _, Acc) -> 
	case erlang:length(Acc) =/= ?CONST_SYS_FALSE of
		?true  -> lists:nth(?CONST_SYS_TRUE, Acc) + 1;
		?false -> ?CONST_SYS_TRUE
	end.


set_pass_unable(CampId, LevelId, Tower) when LevelId < CampId->
	CampInit		= get_camp_init(LevelId),
	CampInfo		= Tower#ets_tower_player.camp,
	Camp			= erlang:element(LevelId, CampInfo),
	MaxPass			= Camp#towercamp.max_pass,
	PastList		= Camp#towercamp.past_list,
	?MSG_DEBUG("PastList=~p", [PastList]),
	PastListLen		= erlang:length(PastList),
	InitId			= case PastListLen =:= ?CONST_SYS_FALSE of
						  ?true -> CampInit;
						  ?false ->
							  {_, PastInit}	= lists:nth(?CONST_SYS_TRUE, PastList),
							  PastInit + 1
					  end,
	?MSG_DEBUG("InitId=~p", [InitId]),
	PastList1		= [{LevelId, PassId} || PassId <- lists:seq(InitId, MaxPass)],
	PastList2		= lists:reverse(PastList1),
	NewPastList		= PastList2 ++ PastList,
	?MSG_DEBUG("NewPastList=~p", [NewPastList]),
	NewCampList		= erlang:setelement(LevelId, CampInfo, Camp#towercamp{top_pass = MaxPass, past_list = NewPastList}),
	NewTower		= Tower#ets_tower_player{camp = NewCampList},									
	set_pass_unable(CampId, LevelId + 1,  NewTower);
set_pass_unable(_, _LevelId, NewTower) ->
	NewTower.

set_pass_unable1(CampId, Tower, TopPass) ->
	CampInfo		= Tower#ets_tower_player.camp,
	Camp			= erlang:element(CampId, CampInfo),
	CampInit		= get_camp_init(CampId),
	PastList		= Camp#towercamp.past_list,
	?MSG_DEBUG("PastList=~p", [PastList]),
	PastListLen		= erlang:length(PastList),
	InitId			= case PastListLen =:= ?CONST_SYS_FALSE of
						  ?true -> CampInit;
						  ?false ->
							  {_, PastInit}	= lists:nth(?CONST_SYS_TRUE, PastList),
							  PastInit + 1
					  end,
	?MSG_DEBUG("InitId=~p", [InitId]),
	PastList1		= [{CampId, PassId} || PassId <- lists:seq(InitId, TopPass)],
	PastList2		= lists:reverse(PastList1),
	NewPastList		= PastList2 ++ PastList,
	?MSG_DEBUG("NewPastList=~p", [NewPastList]),
	NewCampList		= erlang:setelement(CampId, CampInfo, Camp#towercamp{top_pass = TopPass,  past_list = NewPastList}),
	NewTower		= Tower#ets_tower_player{camp = NewCampList},
	NewTower.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 终止扫荡
stop_sweep(Player) ->
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TowerSweep		= Tower#ets_tower_player.sweep,
			NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
													sweep_list = [], interval_time = 0},
			NewTower		= Tower#ets_tower_player{sweep = NewTowerSweep},
			ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
			Result			= ?CONST_SYS_TRUE,
			Packet 			= tower_api:msg_sc_sweep_over(Result),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获取每个大阵的起始关卡
get_camp_init(Id) ->
	TowerList 	= tower_mod_create:get_all_towerpass(?CONST_TOWER_PASS_COUNT, []),
	F 	= fun(Pass) ->
				  Pass#rec_tower_pass.pass_id
		  end,
	PassList 	= [F(Pass)||Pass <- TowerList, Pass#rec_tower_pass.camp =:= Id],
	case PassList =/= [] of
		?true  -> lists:nth(?CONST_SYS_TRUE, PassList);
		?false -> ?CONST_SYS_TRUE
	end.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 退出闯塔
quit_tower(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, NewPlayer} ->
			NewPlayer1 		= map_api:return_last_city(NewPlayer),
			{?ok, NewPlayer1};
		{?false, NewPlayer, _} ->
			{?ok, NewPlayer}
	end.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 确认扫荡是否结束
check_sweep_end(Player) ->
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TowerSweep		= Tower#ets_tower_player.sweep,
			EndTime			= TowerSweep#towersweep.end_time,
			Now				= misc:seconds(),
			TimeTemp		= EndTime - Now,
			case TimeTemp > ?CONST_SYS_FALSE of
				?true ->
					Result	 = ?CONST_SYS_FALSE,
					LeftTime = TimeTemp,
					Packet 		= tower_api:msg_sc_sweep_ack(Result, LeftTime),
					misc_packet:send(Player#player.net_pid, Packet),
					{?ok, Player};
				?false ->
					Result	 = ?CONST_SYS_TRUE,
					LeftTime = ?CONST_SYS_FALSE,
					NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
															sweep_list = [], interval_time = 0},
					NewTower		= Tower#ets_tower_player{sweep = NewTowerSweep},
					ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
					Packet 		= tower_api:msg_sc_sweep_ack(Result, LeftTime),
					misc_packet:send(Player#player.net_pid, Packet),
					case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
						{?true,  Player1} -> {?ok, Player1};
						{?false, Player1, Tips} ->
							TipsPacket		= message_api:msg_notice(Tips),
							misc_packet:send(Player#player.net_pid, TipsPacket),
							{?ok, Player1}
					end
			end;
		_ -> 
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
end.

%%-------------------------------------------------------------------------------------------------------------------------------
%% VIP翻牌奖励
get_vip_award(Player) ->
	PlayerId		= Player#player.user_id,
	Info			= Player#player.info,
	Vip				= player_api:get_vip_lv(Info),
	PassId			= Player#player.tower_passid,
	Value			= ?CONST_TOWER_VIP_REWARD,
	VipFlag			= player_vip_api:get_tower_but_ext_times(Vip),
	case VipFlag =:= ?CONST_SYS_FALSE of                           %% vip6级以上获得翻牌奖励
		?true ->
			TipPacket	= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		?false ->
			case player_money_api:minus_money(PlayerId, ?CONST_SYS_CASH, Value, ?CONST_COST_TOWER_VIP) of
				?ok ->
					Pass		= data_tower:get_towerpass(PassId),
					Exp			= Pass#rec_tower_pass.exp,
					GoldBind	= Pass#rec_tower_pass.gold,
					RewardId	= Pass#rec_tower_pass.award,                 %% 掉落奖励  
					GoodList	= goods_api:goods_drop(RewardId),
					?MSG_PRINT("GoodsList=~p", [GoodList]),
					Fun = fun(Good) when is_record(Good, goods) ->
								  {Good#goods.goods_id,Good#goods.count}
						  end,
					RewardList  = [Fun(T)||T<- GoodList],
					CampId		= tower_sweep_api:get_current_camp(misc:to_list(PassId)),
					Packet 	    = tower_api:msg_sc_vip_award(RewardList),
					TipPacket	= tower_api:msg_goods_info(Player, CampId, PassId, GoodList),
					misc_packet:send(Player#player.net_pid, Packet),
					misc_app:broadcast_world(TipPacket),
					{?ok, _NewPlayer}   = get_award(Player, Exp, GoldBind, GoodList, ?CONST_COST_TOWER_VIP, PassId);   %% 获取掉落奖励  
				{?error, ErrorCode} ->
					?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
					{?ok, Player}
			end
	end.

%% vip扫荡自动翻牌
get_auto_reward(Player, _Type, PassId) ->
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	Bag				= Player#player.bag,
	Value			= ?CONST_TOWER_VIP_REWARD,
	GoodList	  	= case data_tower:get_towerpass(PassId) of
						  TowerPass when is_record(TowerPass, rec_tower_pass) -> 
							  RewardId	= TowerPass#rec_tower_pass.award,
							  goods_api:goods_drop(RewardId);
						  _ -> []
					  end,
	try
		?true		= copy_single_api:get_auto_turn_card(UserId, ?CONST_ELITECOPY_AUTO_TURNCARD_TOWER),
		?false		= ctn_bag2_api:is_full(Bag),
		?true		= tower_api:check_pass_type(PassId),
		?ok			= player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_TOWER_VIP),
        case ctn_bag_api:put(Player, GoodList, ?CONST_COST_TOWER_VIP, 1, 1, 0, 0, 0, 1, [PassId]) of
			{?ok, Player2, _, PacketBag} ->
				F   = fun(Good) when is_record(Good, goods) ->
							 {Good#goods.goods_id, Good#goods.count}
					 end,
				RewardList      = [F(Good) || Good <- GoodList],
				Packet			= copy_single_api:msg_sc_auto_turncard_reward(?CONST_ELITECOPY_AUTO_TURNCARD_TOWER, RewardList, PassId),
				misc_packet:send(UserId, <<PacketBag/binary, Packet/binary>>),
				{?ok, Player2};
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
				GoodsIdList		= mail_api:get_goods_id(GoodList, []),
				Content			= [{GoodsIdList}],
				mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>,?CONST_MAIL_TOWER_SEND, Content, GoodList, 
												  ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, 0, ?CONST_COST_TOWER_SWEEP_REWARD),
				tower_sweep_api:stop_swep(UserId),
				{?ok, Player};
			{?error, _ErrorCode} ->
				{?ok, Player}
		end
	catch
		_:_ -> 
			case ctn_bag2_api:is_full(Bag) of
				?true  -> 
					tower_sweep_api:stop_swep(UserId);
				?false -> ?ok
			end,
			{?ok, Player}
	end.
%%------------------------------------------------------------------------------------------------------------------------------------
%% VIP购买重置次数
buy_reset_times(Player) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	Cost			= 2 * ?CONST_SYS_NUMBER_HUNDRED,
	case VipLv >= 6 of
		?true ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cost, ?CONST_COST_TOWER_REFRESH) of
				?ok ->
					Packet			= tower_api:msg_sc_reset_times(?CONST_SYS_TRUE),
					misc_packet:send(Player#player.net_pid, Packet);
				{?error, _} ->
					?ok
			end;
		?false ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_VIPLEVEL_NOT_ENOUGH),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%% --------------------------------------------------------------------------------------------------------------------------------------
%% 通关boss关卡附加属性
refresh_attr(Tower) ->
	NullAttr 		= player_attr_api:record_attr(),
	refresh_attr(Tower, NullAttr).

refresh_attr([{Type, Value}|RestList], AccAttr) ->
	NewAccAttr		= player_attr_api:attr_plus(AccAttr, Type, Value),
	refresh_attr(RestList, NewAccAttr);
refresh_attr([], AccAttr)  ->
	AccAttr.
%% --------------------------------------------------------------------------------------------------------------------------------------
%% GM命令
set_pass_card(Player, CampId, PassId) ->
	PlayerId 		= Player#player.user_id,
	Tower			= tower_mod_create:get_tower_player(PlayerId),
	CampTuple		= erlang:make_tuple(?CONST_TOWER_CAMP_COUNT, []),
	CampIdEnd		= case CampId * 10 =:= PassId of
						  ?true -> case CampId =:= ?CONST_TOWER_CAMP_COUNT of
									   ?true -> ?CONST_TOWER_CAMP_COUNT;
									   _ -> CampId + 1
								   end;
						  _ -> CampId
					  end,
	F = fun(Id, Acc) ->
				TowerList 	= tower_mod_create:get_all_towerpass(?CONST_TOWER_PASS_COUNT, []),
				F = fun(Pass) ->
							Type 		= Pass#rec_tower_pass.type,
							Id1 		= Pass#rec_tower_pass.pass_id,
							#pass{type = Type, id = Id1}
					end,
				PassList 	= [F(Pass)||Pass <-TowerList, Pass#rec_tower_pass.camp =:= Id],
				CampInfo	= #towercamp{max_pass = Id * 10, id = Id, pass = PassList, top_pass = ?CONST_SYS_FALSE, 
										 reset_pass = ?CONST_SYS_FALSE, past_list = [], is_award= ?CONST_SYS_FALSE},
				erlang:setelement(Id, Acc, CampInfo)
		end,
	TowerCamp		= lists:foldl(F, CampTuple, lists:seq(1, CampIdEnd)),
	?MSG_DEBUG("TowerCamp=~p", [TowerCamp]),
	NewTowerCamp	= case erlang:element(CampId, TowerCamp) of
						Camp when is_record(Camp, towercamp) ->
							NewCamp		= Camp#towercamp{top_pass = PassId},
							erlang:setelement(CampId, TowerCamp, NewCamp);
						  _ -> TowerCamp
					  end,
	NewTower		= Tower#ets_tower_player{top_score = PassId, camp = NewTowerCamp},
	ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower).
	
%% 定点清理扫荡次数和重置次数
clean_tower_times() ->
	case ets:first(?CONST_ETS_TOWER_PLAYER) of
		'$end_of_table' -> ?ok;
		Key	->
			clean_tower_times_ext(Key),
			clean_tower_times(Key)
	end.

clean_tower_times(Key) ->
	case ets:next(?CONST_ETS_TOWER_PLAYER, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			clean_tower_times_ext(Key1),
			clean_tower_times(Key1)
	end.

clean_tower_times_ext(Key) ->
	NewDate			= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_TOWER_PLAYER, Key) of
		Tower when is_record(Tower, ets_tower_player) ->
			TowerCamp	 = Tower#ets_tower_player.camp,
			case erlang:element(?CONST_SYS_TRUE, TowerCamp) of
				CampInfo when is_record(CampInfo, towercamp) ->
					OldDate		= CampInfo#towercamp.date,
					case OldDate =:= NewDate of
						?false ->
							NewCampInfo	  = CampInfo#towercamp{date = NewDate},
							NewTowerCamp  = erlang:setelement(?CONST_SYS_TRUE, TowerCamp, NewCampInfo),
							NewTower	  = Tower#ets_tower_player{camp = NewTowerCamp, sweep_times = 0, 
																   reset_times = 0},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower);
						?true -> ?ok
					end;
				_ -> ?ok
			end;
		_ -> ?ok
	end.

clean_tower_times1() ->
	TowerList		= ets_api:list(?CONST_ETS_TOWER_PLAYER),
	F = fun(Tower) when is_record(Tower, ets_tower_player) ->
				TowerCamp	 = Tower#ets_tower_player.camp,
				case erlang:element(?CONST_SYS_TRUE, TowerCamp) of
					CampInfo when is_record(CampInfo, towercamp) ->
						NewCampInfo	  = CampInfo#towercamp{date = ?CONST_SYS_FALSE},
						NewTowerCamp  = erlang:setelement(?CONST_SYS_TRUE, TowerCamp, NewCampInfo),
						NewTower	  = Tower#ets_tower_player{camp = NewTowerCamp, sweep_times = 0, 
															   reset_times = 0},
						ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower)
				end
		end,
	[F(Tower) || Tower <- TowerList].

%% 上线前刷一次数据
refresh_tower_times(Player) ->
	NewDate		= misc:date_num(),
	UserId		= Player#player.user_id,
	case tower_mod_create:get_tower_player(UserId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TowerCamp	 = Tower#ets_tower_player.camp,
			case erlang:element(?CONST_SYS_TRUE, TowerCamp) of
				CampInfo when is_record(CampInfo, towercamp) ->
					OldDate		= CampInfo#towercamp.date,
					case OldDate =:= NewDate of
						?false ->
							NewCampInfo	  = CampInfo#towercamp{date = NewDate},
							NewTowerCamp  = erlang:setelement(?CONST_SYS_TRUE, TowerCamp, NewCampInfo),
							NewTower	  = Tower#ets_tower_player{camp = NewTowerCamp, sweep_times = 0, 
																   reset_times = 0},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower);
						?true -> ?ok
					end;
				_ -> ?ok
			end;
		_ -> ?ok
	end.
%%------------------------------------------------------------------------------------------------------------------------------
%% 获取奖励
get_award(Player, Exp, GoldBind, GoodsList, _Type, PassId) ->
	Info		= Player#player.info,
	UserName	= Info#info.user_name,
	UserId 		= Player#player.user_id,
	
	{?ok, Player2} = player_api:exp(Player, Exp),              % 经验
	
	case GoldBind of                                     	   % 铜钱
		GoldBind when GoldBind > 0 ->
			player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind, ?CONST_COST_TOWER_SWEEP_REWARD); 
		_ ->
			?ignore 
	end,
	
	{?ok, Player3} =                                            % 道具
        case ctn_bag_api:put(Player2, GoodsList, ?CONST_COST_TOWER_SWEEP_REWARD, 1, 1, 1, 0, 1, 1, [PassId]) of
			{?ok, Player2_2, _, _PacketBag} ->
				{?ok, Player2_2};
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
				GoodsIdList		= mail_api:get_goods_id(GoodsList, []),
				Content			= [{GoodsIdList}],
				mail_api:send_system_mail_to_one2(UserName, <<>>, <<>>, ?CONST_MAIL_TOWER_SEND, Content,
												  GoodsList, 0, 0, 0, ?CONST_COST_TOWER_SWEEP_REWARD),
				{?ok, Player2};
			{?error, _ErrorCode} ->
				{?ok, Player2}
		end,
	{?ok, Player3}.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 重置剩余次数
get_tower_times(Player) ->
	UserId			= Player#player.user_id,
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
			case tower_mod_create:get_tower_player(UserId) of
				Tower when is_record(Tower, ets_tower_player) ->
					ResetTimes		= Tower#ets_tower_player.reset_times,
					misc:uint(1 - ResetTimes);
				_ -> ?CONST_SYS_FALSE
			end;
		?false -> ?CONST_SYS_FALSE
	end.

get_tower_vip_times(Player) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	VipTimes		= player_vip_api:get_tower_reset_times(VipLv),
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
			case tower_mod_create:get_tower_player(UserId) of
				Tower when is_record(Tower, ets_tower_player) ->
					ResetTimes		= Tower#ets_tower_player.reset_times,
					case ResetTimes < ?CONST_SYS_TRUE of
						?true  -> 
							VipTimes;
						?false -> misc:uint(1 + VipTimes - ResetTimes)
					end;
				_ -> ?CONST_SYS_FALSE
			end;
		?false -> ?CONST_SYS_FALSE
	end.

get_tower_reset_times(Player) ->
	UserId			= Player#player.user_id,
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
			case tower_mod_create:get_tower_player(UserId) of
				Tower when is_record(Tower, ets_tower_player) ->
					Tower#ets_tower_player.reset_times;
				_ -> ?CONST_SYS_FALSE
			end;
		?false -> ?CONST_SYS_FALSE
	end.

get_tower_sweep_times(Player) ->
	UserId			= Player#player.user_id,
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
			case tower_mod_create:get_tower_player(UserId) of
				Tower when is_record(Tower, ets_tower_player) ->
					Tower#ets_tower_player.sweep_times;
				_ -> ?CONST_SYS_FALSE
			end;
		?false -> ?CONST_SYS_FALSE
	end.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 获取闯塔的最高记录
get_top_pass(UserId) ->
	case tower_mod_create:get_tower_player(UserId) of
		Tower when is_record(Tower, ets_tower_player) ->
			Tower#ets_tower_player.top_score;
		_ -> ?CONST_SYS_FALSE
	end.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 下线存数据库
logout(Player) ->
	UserId		= Player#player.user_id,
	case tower_mod_create:get_tower_player(UserId) of
		Tower when is_record(Tower, ets_tower_player) ->
			tower_db_mod:update_top_score(Player, Tower);
		_ -> ?ok
	end.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 关服调用
stop_all_sweep() ->
	TowerPlayerList	= ets_api:list(ets_tower_player),
	stop_one_sweep(TowerPlayerList).

stop_one_sweep([Tower|Rest]) when is_record(Tower, ets_tower_player) ->
	UserId			= Tower#ets_tower_player.player_id,
	TowerSweep		= Tower#ets_tower_player.sweep,
	SweepList		= TowerSweep#towersweep.sweep_list,
	if
		SweepList =/= [] ->
			NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, 
													end_time = 0, sweep_list = [], interval_time = 0},
			NewTower		= Tower#ets_tower_player{sweep = NewTowerSweep},
			tower_db_mod:end_sweep(UserId, NewTower),
			stop_one_sweep(Rest);
		?true -> 
			stop_one_sweep(Rest)
	end;
stop_one_sweep([_|Rest]) -> stop_one_sweep(Rest);
stop_one_sweep([]) -> ?ok.
%%--------------------------------------------------------------------------------------------------------------------------------
%% 上线通知扫荡的包
get_offline_sweep_data(Player) ->
	PlayerId	= Player#player.user_id,
	Now 		= misc:seconds(),
	case ets_api:lookup(?CONST_ETS_TOWER_PLAYER, PlayerId) of 
		?null -> {?ok, Player, <<>>};
		Tower when is_record(Tower, ets_tower_player) ->
%% 			TopScore	= Tower#ets_tower_player.top_score,
			Sweep		= Tower#ets_tower_player.sweep,
			SweepList	= Sweep#towersweep.sweep_list,
			SweepLen	= erlang:length(SweepList),
%% 			InitId		= Sweep#towersweep.id,
			case SweepLen =:= ?CONST_SYS_FALSE of
				?true  ->  {?ok, Player, <<>>};
				?false ->
					EndTime 	= Sweep#towersweep.end_time,
					LeftTime	= EndTime - Now,
					case LeftTime < ?CONST_SYS_FALSE of
						?true  -> 
							TowerSweep		= Tower#ets_tower_player.sweep,
							NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
																	sweep_list = [], interval_time = 0},
							NewTower		= Tower#ets_tower_player{sweep = NewTowerSweep},
							ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
							{?ok, Player, <<>>};
						?false ->
							NewPlayer	    = case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_TOWER) of
												{?true, Player1} -> Player1;
												{?false, Player1,_} -> Player1
											end,
%% 							Packet			= tower_api:msg_sc_open_rush(1, InitId, LeftTime, TopScore, []),
%% 							Packet1 		= tower_api:msg_sc_auto_rush(SweepList),
%% 							{?ok, NewPlayer, <<Packet/binary, Packet1/binary>>}
							{?ok, NewPlayer, <<>>}
					end
			end;
		_ -> {?ok, Player, <<>>}
	end.