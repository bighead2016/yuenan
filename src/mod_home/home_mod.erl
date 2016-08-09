%% Author: Administrator
%% Created: 2012-10-29
%% Description: TODO: Add description to home_mod
-module(home_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../include/const.cost.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/record.goods.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([init_task/0, get_recruit_vip_list/1]).
-export([get_home_info/1, upgrade_home/1, plant_coin/3, get_plant_reward/2,
		 get_office_reward_info/1, get_office_reward/2, enter_friend_home/2, apply_loosen/3, 
		 recruit_girl/2, get_recruit_girl_info/1,
		 get_office_task/1,
		 refresh_office_task/2,office_task_operate/3, get_home_daily_award/1,get_daily_task_award/1]).
-export([get_owner_declear/2, clean_leave_message/1, delete_leave_message/2, edit_home_declear/2, edit_leave_message/3,
		 get_leave_message/2, get_visit_record/2]).
-export([clean_home_times/0,add_record1/3,notice_daily_task_over/1,
		 get_guide_info/1, logout/1, refresh_home/1,notice_home_task_over/2, get_top_girl_id/1,
		 check_has_get_award/1, init_task_info/3, get_slaver_info/2]).

%%
%% API Functions
%%
%%-------------------------------------------------------------------------------------------------
%%获取家园主系统信息
%%-------------------------------------------------------------------------------------------------
get_home_info(Player) ->
	UserId 	  	  = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			Now 		  	= misc:seconds(),
			HomeLv		  	= Home#ets_home.lv, 
			HomeData	  	= data_home:get_base(HomeLv),
			Cd			  	= HomeData#rec_home_base.time,
			UpdateTime    	= Home#ets_home.update_time,
			TempTime 	 	= UpdateTime + Cd - Now,
			RemainTime	  	= case TempTime > ?CONST_SYS_FALSE of                  %% 计算家园升级截止时间
								?true  -> UpdateTime + Cd;
								?false -> ?CONST_SYS_FALSE
							end,                   						  
			FriendList	  	= get_home_friend_list(UserId),          				  %%家园好友列表
			FarmList	  	= get_home_farm_list(UserId, Home, ?CONST_SYS_FALSE),   %% 获取自己土地列表信息
			Girl		  	= Home#ets_home.girl,
			?MSG_DEBUG("Girl=~p", [Girl]),
			ShowGirlId	  	= Girl#girl.show_girl,
			RecruList	  	= get_recruit_list(Player, Girl),
			BlackList		= get_black_list(Home),
			UserState		= home_mod_girl:get_user_state(UserId),
			
			ContentList		= case home_mod_create:get_home1(UserId) of
								  Home1 when is_record(Home1, ets_home) ->
									  Message			= Home1#ets_home.message,
									  Message#message.interinfo;
								  _ -> []
							  end,
			PlayTime		= Girl#girl.play_begin_time,
			
			InterCd			= case PlayTime of
								  0 -> 0;
								  _ -> PlayTime + 4 * 3600
							  end,
			Packet 		  	= home_api:msg_sc_main(HomeLv, RemainTime, FriendList, FarmList, ShowGirlId, UserState, 
												   BlackList, ContentList, InterCd),
			Packet1		  	= get_guide_info(Home),
			Packet2		  	= home_api:msg_sc_girl_info(UserId, RecruList),
			Packet3			= case UserState of
								  2 ->
									  BelongerId			= Girl#girl.belonger,
									  get_slaver_info(BelongerId, UserId);
								  _ -> <<>>
							  end,
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, 
													  Packet2/binary, Packet3/binary>>);
		_ ->
			TipPacket	  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%% 获取家园好友列表
get_home_friend_list(UserId) ->
    SysRank = data_guide:get_task_rank(?CONST_MODULE_HOME),
	FunFriend = fun(FriendId, Acc) when is_integer(FriendId) ->
						case player_api:get_player_fields(FriendId, [#player.sys_rank, #player.info]) of
							{?ok, [Sys, Info]} when Sys >= SysRank -> %% 好友家园已开启	
								FriendName 	= Info#info.user_name,
								VipLv		= player_api:get_vip_lv(Info),
								HomeLv		= case home_mod_create:get_home1(FriendId) of
												  Home when is_record(Home, ets_home) ->
													  Home#ets_home.lv;
												  _ -> ?CONST_SYS_TRUE
											  end,
								LoosenState	= check_plant_state(UserId, FriendId),
								?MSG_DEBUG("LoosenState=~p", [LoosenState]),
								State		= case LoosenState =:= ?false of
												  ?false -> 2;			  				%% 松土状态
												  ?true  ->	?CONST_SYS_FALSE		    %% 无状态							
											  end,
								[{FriendId, FriendName, HomeLv, State, VipLv}|Acc];
							_ -> Acc
						end;
				   (_, Acc) -> Acc
				end,
	FriendList = relation_api:list_friend(UserId),
	lists:foldl(FunFriend, [], FriendList).	

%% 获取玩家土地信息
%% UserId 获取该玩家土地列表信息
%% Type =:= 0 ->查看自己  =:=1 查看好友
get_home_farm_list(UserId, Home, Type) ->  
	Farm			= Home#ets_home.farm,
	Plant			= Farm#farm.plant,
	PlantList		= misc:to_list(Plant),
	F = fun(PlantInfo, Acc) when is_record(PlantInfo, plant) ->
				Now			= misc:seconds(),
				PlantPos	= PlantInfo#plant.position,

				PlantTime	= PlantInfo#plant.harvest_time,
				Cd			= PlantInfo#plant.cd_time,
				TempTime	= PlantTime + Cd - Now,
				PlantType	= PlantInfo#plant.type,
				RemainTime	= 
					case Cd =:= ?CONST_SYS_FALSE of
						?true -> ?CONST_SYS_FALSE;
						?false ->
							case TempTime > ?CONST_SYS_FALSE of
								?true -> TempTime + Now;
								?false -> ?CONST_SYS_FALSE
							end
					end,
				PlantState	= 
					case Type =:= ?CONST_SYS_FALSE of
						?true ->                       %% 查看自己的土地状态
							case Cd =/= ?CONST_SYS_FALSE of
								?true ->
									case TempTime > ?CONST_SYS_FALSE of
										?true  -> ?CONST_HOME_PLANT_CD;
										?false -> ?CONST_HOME_PLANT_NULL
									end;
								?false -> PlantInfo#plant.state
							end;
						?false ->						 %% 查看好友的土地状态
							get_friend_plant_state(UserId, PlantInfo)
					end,
				[{PlantPos, PlantState, RemainTime, PlantType}|Acc];
		   (_, Acc)->
				Acc
		end,
	lists:foldl(F, [], PlantList).

%% 获取好友土地状态
get_friend_plant_state(UserId, PlantInfo) ->
	Now			= misc:seconds(),
	Pos			= PlantInfo#plant.position,
	LoosenList	= PlantInfo#plant.loosen_list,
	MuckFlag	= case lists:member({UserId, Pos}, LoosenList) of               %% 判断是否给好友施过肥
						?true  -> ?true;
						?false -> ?false
				  end,
	LoosenTimes	= erlang:length(LoosenList),
	PlantTime	= PlantInfo#plant.harvest_time,
	Cd			= PlantInfo#plant.cd_time,
	TempTime	= PlantTime + Cd - Now,
	RemainTime	= case Cd =:= ?CONST_SYS_FALSE of
					  ?true -> ?CONST_SYS_FALSE;
					  ?false ->
						  case TempTime > ?CONST_SYS_FALSE of
							  ?true -> TempTime + Now;
							  ?false -> ?CONST_SYS_FALSE
						  end
				  end,
	case RemainTime =:= ?CONST_SYS_FALSE of
		?true -> ?CONST_SYS_TRUE;
		?false ->
			case LoosenTimes < ?CONST_HOME_MUCK_TIMES of
				?false -> ?CONST_SYS_TRUE;
				?true -> 
					case MuckFlag of
						?true  -> ?CONST_SYS_TRUE;
						?false -> PlantInfo#plant.state1
					end
			end
	end.

%% 检测好友土地的状态
check_plant_state(UserId, FriendId) ->
	case home_mod_create:get_home1(FriendId) of
		Home when is_record(Home, ets_home) ->
				List	= get_home_farm_list(UserId, Home, ?CONST_SYS_TRUE),
				lists:keymember(5, 2, List);
		_ -> ?false
	end.

%% 获取小黑屋情况
get_black_list(Home) ->
	UserId			= Home#ets_home.user_id,
	UserName		= player_api:get_name(UserId),
	Girl			= Home#ets_home.girl,
	BlackInfo		= Girl#girl.grab_girl_info,
	GrabList		= misc:to_list(BlackInfo),
	Now				= misc:seconds(),
	
	F = fun(Grab, Acc) when (is_record(Grab, grab_girl_info)) andalso Grab#grab_girl_info.state =:= 2 ->
						Start			= Grab#grab_girl_info.start_time,
						EndTime     	= Start + ?CONST_SYS_ONE_DAY_SECONDS,
						Pos				= Grab#grab_girl_info.pos,
						OwnerId			= Grab#grab_girl_info.owner_id,
						Name			= Grab#grab_girl_info.owner_name,
						case EndTime < Now of
							?true  ->                            %% 系统释放奴隶
								Message				= Home#ets_home.message,
								InterList			= Message#message.interinfo,
								NewInterInfo		= home_mod_girl:add_inter_info(InterList, 27, Name, "", 0, 0),
								NewMessage			= Message#message{interinfo = NewInterInfo},
								
								home_mod_girl:update_release_user_info2(OwnerId, UserName),
%% 								Packet5				= home_api:msg_sc_inter_info(28, UserName, "", 0, 0),
%% 								misc_packet:send(OwnerId, Packet5),
								
								NewTuple			= #grab_girl_info{pos = Pos, state = 1},			  %% 更改小黑屋信息
								NewGrabInfo			= erlang:setelement(Pos, BlackInfo, NewTuple),
								
								Ids					= Girl#girl.source_list,
%% 								NewIds				= lists:usort([OwnerId|Ids]),
%% 								SourceList			= home_mod_girl:get_source_list1(NewIds, []),
								
								SourceList			= home_mod_girl:get_source_list([OwnerId|Ids], UserId),
								NewGirl				= Girl#girl{source_list = SourceList, grab_girl_info = NewGrabInfo},
								NewHome				= Home#ets_home{girl = NewGirl, message= NewMessage},
								ets_api:insert(?CONST_ETS_HOME, NewHome),
								Acc;
							?false ->
								
								OwnerLv				= Grab#grab_girl_info.owner_lv,
								GirlId				= Grab#grab_girl_info.id,
								Pos					= Grab#grab_girl_info.pos,
								Pro					= Grab#grab_girl_info.owner_pro,
								
								[{Pos, GirlId, OwnerId,  Name, OwnerLv, Pro, EndTime}|Acc]
						end;
				   (_, Acc) ->
						Acc
				end,
	BlackList		= lists:foldl(F, [], GrabList),
	State			= home_mod_girl:get_user_state(UserId),
	case home_mod_create:get_home1(UserId) of
		Home2 when is_record(Home2, ets_home) ->
			Girl2			= Home2#ets_home.girl,
			NewGirl2		= Girl2#girl{state = State},
			NewHome2		= Home#ets_home{girl = NewGirl2},
			ets_api:insert(?CONST_ETS_HOME, NewHome2);
		_ -> ?ok
	end,
	?MSG_DEBUG("BlackList=~p", [BlackList]),
	BlackList.

%% 如果是奴隶 获取努力主信息
get_slaver_info(0, _) -> <<>>;
get_slaver_info(BelongerId, UserId) -> 
	case player_api:get_player_field(BelongerId, #player.info) of
		{?ok, #info{user_name = UserName, lv = Lv, pro = Pro, sex = Sex}} ->
			case home_mod_create:get_home1(BelongerId) of
				Home when is_record(Home, ets_home) ->
					Girl			= Home#ets_home.girl,
					GrabInfo		= Girl#girl.grab_girl_info,
					GrabList		= misc:to_list(GrabInfo),
					case lists:keyfind(UserId, #grab_girl_info.owner_id, GrabList) of
						#grab_girl_info{end_time = EndTime} ->
							home_api:msg_sc_slaver_info(BelongerId, UserName, Lv, Pro, Sex, EndTime);
						_ ->
							<<>>
					end;
				_ -> <<>>
			end;
		_ ->
			<<>>
	end.
%%-------------------------------------------------------------------------------------------------
%% 升级家园
%%-------------------------------------------------------------------------------------------------
upgrade_home(Player) ->
	PlayerId 	= Player#player.user_id,
	Info		= Player#player.info,
	PlayerLv	= Info#info.lv,
	case home_mod_create:get_home1(PlayerId) of
		Home when is_record(Home, ets_home) ->
			HomeLv		= Home#ets_home.lv + 1,
			case HomeLv > 10 of
				?true ->                     %% 家园已升到最高级
					PacketTip	= message_api:msg_notice(?TIP_HOME_UPDATE_MAX),
					misc_packet:send(Player#player.net_pid, PacketTip);
				?false ->
					OldHomeData = data_home:get_base(Home#ets_home.lv),
					HomeData	= data_home:get_base(HomeLv),
					UpCdTime	= OldHomeData#rec_home_base.time,                   %% 升级cd
					UpStart		= Home#ets_home.update_time,						%% 升级开始时间
					UpEndTime	= UpStart + UpCdTime,							    %% 升级结束时间
					BasePlayerLv= HomeData#rec_home_base.player_lv,
					Now			= misc:seconds(),
					case {Now < UpEndTime, PlayerLv < BasePlayerLv}of   
						{?true, _} ->    											%%升级家园,Cd时间未到     										
							PacketTip 		= message_api:msg_notice(?TIP_HOME_UPDATE_CD),
							misc_packet:send(Player#player.net_pid, PacketTip);
						{_, ?true} ->        										%% 升级家园,人物等级不足 										
							PacketTip		= message_api:msg_notice(?TIP_HOME_UPDATEHOME_LVLIMIT),
							misc_packet:send(Player#player.net_pid, PacketTip);
						{?false, ?false}->   										%% 家园可以升级 
							Cost 			= HomeData#rec_home_base.coin,
							case  player_money_api:minus_money(PlayerId, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_UPGRADE_HOME) of 
								?ok ->
									Cd			= HomeData#rec_home_base.time,           %% 建造家园的cd时间
									EndTime		= Now + Cd,
									achievement_api:add_achievement(Player#player.user_id, ?CONST_ACHIEVEMENT_HOME_LEVELUP,
																	 HomeLv, 1),  %% 成就点
									NewFarm		= upgrade_home_farm(Home, Player),		%% 扩展农场土地栏位
									HomeNew		= Home#ets_home{lv = HomeLv,  farm = NewFarm, update_time = Now},
									ets_api:insert(?CONST_ETS_HOME, HomeNew),
									home_db_mod:update_home_build(HomeNew),
									FarmList	= get_home_farm_list(PlayerId, HomeNew, ?CONST_SYS_FALSE),
									Packet1		= home_api:msg_sc_plant_info(FarmList),
									Packet 		= home_api:msg_sc_lvuphome(EndTime),
									misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
								{?error, ErrorCode} ->  %% 铜钱不足
									?MSG_DEBUG("~nErrorCode=~p", [ErrorCode]),
									?ok
							end
					end
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 升级家园对农场的影响
upgrade_home_farm(Home, Player) ->
	Info			= Player#player.info,
	VipLv			= player_api:get_vip_lv(Info),
	HomeLv			= Home#ets_home.lv + 1,	
	HomeData		= data_home:get_base(HomeLv),
	OpenNum			= if
						  VipLv	=:= 3 -> HomeData#rec_home_base.farm_vip3;
						  VipLv	=:= 5 -> HomeData#rec_home_base.farm_vip5;
						  ?true ->		 HomeData#rec_home_base.farm_vip0
					  end,                      
	Farm			= Home#ets_home.farm,
	Plant			= Farm#farm.plant,
	PlantList		= misc:to_list(Plant),
	PlantNum		= get_has_plant_num(PlantList, ?CONST_SYS_FALSE),
	?MSG_DEBUG("OpenNum=~p,PlantNum=~p", [OpenNum, PlantNum]),
	case OpenNum	> PlantNum of
		?true ->
			home_mod_create:set_farm(OpenNum, PlantNum + 1, Farm);
		_ ->     
			Farm
	end.

%% 获取已经开启的种植栏
get_has_plant_num([Plant|PlantList], Acc) ->
	case is_record(Plant, plant) of
		?true ->
			NewAcc		= Acc + 1,
    		get_has_plant_num(PlantList, NewAcc);
		?false ->
			get_has_plant_num(PlantList, Acc)
	end;
get_has_plant_num([], Acc) ->
	Acc.
 	
%%-------------------------------------------------------------------------------------------------
%% 进入好友家园
%%-------------------------------------------------------------------------------------------------
enter_friend_home(Player, UserId) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.position, #player.sys_rank]) of
		{?ok, ?null, _} ->	 		%% 玩家不存在
			TipPacket		= message_api:msg_notice(?TIP_COMMON_NO_THIS_PLAYER),
			misc_packet:send(Player#player.net_pid, TipPacket);
		{?ok, [Info, Position, SysId]} ->
			case SysId >= data_guide:get_task_rank(?CONST_MODULE_HOME) of
				?true ->
					PlayerId		= Player#player.user_id,
					case home_mod_create:get_home(UserId) of
						Home when is_record(Home, ets_home) ->
							HomeLv			= Home#ets_home.lv,
							Girl			= Home#ets_home.girl,
							ShowGirlId		= get_top_girl_id(Girl),
							PositionId		= Position#position_data.position,
							achievement_api:add_achievement(PlayerId, ?CONST_ACHIEVEMENT_VISIT_FRIEND_HOME, 0, 1),
							FarmList		= get_home_farm_list(PlayerId, Home, ?CONST_SYS_TRUE),              %% 获取好友土地列表
							Packet 			= home_api:msg_sc_otherhome(FarmList, ShowGirlId, HomeLv, PositionId),
							RecruList	  	= get_recruit_list(Info, Girl),
							HasVipList		= Girl#girl.recruit_vip_list,
							VipRecruList	= get_recruit_vip_list(Info),     
							case HasVipList == VipRecruList of                                                  %% 更新vip仕女信息
								?true  -> ?ok; 
								?false ->
									NewGirl			= Girl#girl{recruit_vip_list = VipRecruList},
									NewHome			= Home#ets_home{girl = NewGirl},
									ets_api:insert(?CONST_ETS_HOME, NewHome)
							end,
							Packet1		  	= home_api:msg_sc_girl_info(UserId, RecruList),
							misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
						_ ->
							TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
							misc_packet:send(Player#player.net_pid, TipPacket)
					end;
				?false ->			%% 好友家园未开启
					TipPacket		= message_api:msg_notice(?TIP_HOME_NOT_OPEN),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end
	end.
%%-------------------------------------------------------------------------------------------------
%% 种植资源
%%-------------------------------------------------------------------------------------------------
plant_coin(Player, PlantPos, Type) ->                      %%Type:1经验2铜钱3历练
	PlayerId	= Player#player.user_id,
	Home		= home_mod_create:get_home(PlayerId),
	Farm		= Home#ets_home.farm,
	Plant1		= Farm#farm.plant,
	PlantInfo1	= erlang:element(PlantPos, Plant1),
	Now			= misc:seconds(),
	PlantTime1	= PlantInfo1#plant.harvest_time,
	Cd1			= PlantInfo1#plant.cd_time,
	TempTime1	= PlantTime1 + Cd1 - Now,
	Farm1		= case Cd1 =/= ?CONST_SYS_FALSE of
					  ?true ->
						  case TempTime1 > ?CONST_SYS_FALSE of
							  ?true -> Farm;
							  ?false -> 
								  NewPlant1		= PlantInfo1#plant{state = ?CONST_HOME_PLANT_NULL, 
																   state1 = ?CONST_HOME_PLANT_NULL}, 
								  NewPlantList1	= erlang:setelement(PlantPos, Plant1, NewPlant1),
								  Farm#farm{plant_coinlv = ?CONST_HOME_PLANT_MIN_LV, plant = NewPlantList1}
						  end;
					  ?false ->Farm
				  end,
	?MSG_PRINT("Farm#farm.plant=~p PlantPos=~p", [Farm1#farm.plant, erlang:element(PlantPos, Farm1#farm.plant)]),
	case erlang:element(PlantPos, Farm1#farm.plant) of 
		?CONST_SYS_FALSE -> 								          %%请先开垦土地 ;
			PacketTip 		= message_api:msg_notice(?TIP_HOME_PLANT_OPENPLANT),
			misc_packet:send(Player#player.net_pid, PacketTip),
			{?ok, Player};
		Plant when Plant#plant.state =:= ?CONST_HOME_PLANT_CD ->      %%cd中不可种植
			PacketTip 		= message_api:msg_notice(?TIP_HOME_PLANT_INCD),
			misc_packet:send(Player#player.net_pid, PacketTip),
			{?ok, Player};
		Plant when Plant#plant.state =:= ?CONST_HOME_PLANT_NULL ->    %%空白的土地
			PlantTimes		= Plant#plant.times + 1,
			case PlantTimes > 3 of                                    %% 每天每块地种植次数3次
				?false ->
					NewPlant		= Plant#plant{state= ?CONST_HOME_PLANT_HAS, plant_time = Now, 
												  cd_time = ?CONST_SYS_FALSE, type= Type, 
												  times = PlantTimes, state1 =  ?CONST_HOME_PLANT_HAS}, 
					NewPlantList	= erlang:setelement(PlantPos, Farm#farm.plant, NewPlant),
					NewFarm			= Farm#farm{plant_coinlv = ?CONST_HOME_PLANT_MIN_LV, plant = NewPlantList, 
												refresh_times = ?CONST_SYS_FALSE},
					OfficeTask		= Home#ets_home.task_info,
					TaskInfo		= OfficeTask#task_info.task,
					TaskList		= misc:to_list(TaskInfo),
					{NewTaskInfo, _}= update_home_task_over(TaskList, ?CONST_HOME_TASK_PLANT, TaskInfo, ?CONST_SYS_FALSE),
					NewOfficeTask 	= OfficeTask#task_info{task = NewTaskInfo},
					NewHome 		= Home#ets_home{farm = NewFarm, task_info = NewOfficeTask},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					home_db_mod:update_home_ground_harvast(NewHome),         
					{?ok, NewPlayer} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_PLANTING, 0, 1),   %% 种植成就
					{?ok, NewPlayer1} = welfare_api:add_pullulation(NewPlayer, ?CONST_WELFARE_PLANT, 0, 1),          %% 成长礼包  
					{?ok, NewPlayer2}= schedule_api:add_guide_times(NewPlayer1, ?CONST_SCHEDULE_GUIDE_HOME_PLANT),   %% 每天任务
					Packet 			 = home_api:msg_sc_plant(PlantPos, Type),
					Packet1			 = get_guide_info(NewHome),
					Packet2			 = notice_daily_task_over(PlayerId),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, Packet2/binary>>),
					{?ok, NewPlayer2};
				?true ->                                              %% 种植次数达到上限
					PacketTip 		= message_api:msg_notice(?TIP_HOME_PLANT_MAX),
					misc_packet:send(Player#player.net_pid, PacketTip),
					{?ok, Player}
			end;
		Plant when Plant#plant.state =:= 2 ->         				  %%植物已种植，不能在此继续种植
			PacketTip 		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, PacketTip),
			{?ok, Player}
	end.
%%-------------------------------------------------------------------------------------------------
%% 土地块收获
%%-------------------------------------------------------------------------------------------------
get_plant_reward(Player, PlantPos) ->
	PlayerId		= Player#player.user_id,
	case home_mod_create:get_home1(PlayerId) of
		Home when is_record(Home, ets_home) ->
			Farm			= Home#ets_home.farm,
			Plant			= erlang:element(PlantPos, Farm#farm.plant),
			Now				= misc:seconds(),
			case Plant#plant.state of
				?CONST_HOME_PLANT_HAS ->
					Type			= Plant#plant.type,
					EndTime			= ?CONST_HOME_LAND_COMMON_CD + Now,       							%% cd结束时间
					State1			= 5, 
					NewPlant		= Plant#plant{plant_lv = ?CONST_HOME_PLANT_MIN_LV, position = PlantPos, 
												  state = ?CONST_HOME_PLANT_CD, cd_time = ?CONST_HOME_LAND_COMMON_CD,
												  harvest_time = Now, state1 = State1},
					Gain			= case Type of
										  ?CONST_HOME_RESOUCE_EXP  ->  ?CONST_HOME_PLANT_EXP;
										  ?CONST_HOME_RESOUCE_GOLD ->  ?CONST_HOME_PLANT_GOLD;
										  ?CONST_HOME_RESOUCE_SER  ->  ?CONST_HOME_PLANT_MER
									  end,
					{?ok, NewPlayer}= add_play_gain(Type, Gain, Player),
					PlantRecord		= erlang:setelement(PlantPos, Farm#farm.plant, NewPlant),
					NewFarm			= Farm#farm{plant = PlantRecord},
					NewHome			= Home#ets_home{farm = NewFarm},        			
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					achievement_api:add_achievement(PlayerId, ?CONST_ACHIEVEMENT_HARVEST, 0, 1),
					Packet 			= home_api:msg_sc_harvest(PlantPos, EndTime),
					TipPacket		= msg_play_gain(Type, Gain),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
					NewPlayer;
				_ ->     %% 不可收获
					PacketTip 		= message_api:msg_notice(?TIP_HOME_HARVEST_NONE),
					misc_packet:send(Player#player.net_pid, PacketTip),
					Player
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			Player
	end.

%%-------------------------------------------------------------------------------------------------
%% 获取俸禄信息
%%-------------------------------------------------------------------------------------------------
get_office_reward_info(Player) ->
	{IsWare, _Salary}= player_position_api:salary_info(Player),   %%俸禄信息
	Packet			= home_api:msg_sc_office_reward(IsWare),
	misc_packet:send(Player#player.net_pid, Packet).
%%-------------------------------------------------------------------------------------------------
%% 领取官衔俸禄
%%-------------------------------------------------------------------------------------------------
get_office_reward(Player, ?CONST_HOME_ACT_GET_BREAD) ->   %%领取俸禄奖励
	PlayerId		 = Player#player.user_id,
	case home_mod_create:get_home(PlayerId) of
		Home when is_record(Home, ets_home) ->
			Message			 = Home#ets_home.message,
			Declare			 = Message#message.declare,
			Today            = misc:date_num(),
			PositionData     = Player#player.position,
			case PositionData#position_data.date of
				Today ->										  % 今天已经领取俸禄
					TipPacket	= message_api:msg_notice(?TIP_HOME_HASGETWARE),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player};
				_ ->
					{_Flag, Salary} = player_position_api:salary_info(Player),
					player_money_api:plus_money(PlayerId, ?CONST_SYS_GOLD_BIND, Salary, ?CONST_COST_POSITION_REWARD),
					PositionData    = Player#player.position,
					PositionData2   = PositionData#position_data{date = Today},
					Player2         = Player#player{position = PositionData2},
					NewDeclear  	= Declare#declare{get_reward_times = 1},
					NewMessage  	= Message#message{declare = NewDeclear},
					NewHome			= Home#ets_home{message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					home_db_mod:update_home(NewHome),
					TipPacket		= message_api:msg_notice(?TIP_HOME_OFFICE_GETWARE, 
															 [{?TIP_SYS_COMM, misc:to_list(Salary)}]),
					Packet			= get_guide_info(NewHome),
					Packet1			= home_api:msg_sc_office_reward(?CONST_SYS_TRUE),
					Packet2			= notice_daily_task_over(PlayerId),
					misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary, 
															  Packet1/binary, Packet2/binary>>),
					{?ok, Player2}
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end;
get_office_reward(Player, 2) ->   						%%每日活动领取俸禄奖励
	PlayerId		= Player#player.user_id,
	Today           = misc:date_num(),
	PositionData    = Player#player.position,
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_POSITION) of
		?true ->
			case PositionData#position_data.date of
				Today -> 
					TipPacket	= message_api:msg_notice(?TIP_HOME_HASGETWARE),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player};								     % 今天已经领取俸禄	
				_ ->
					PositionId      = PositionData#position_data.position,
					Position        = data_player:get_player_position(PositionId),
					Salary			= Position#player_position.salary,
					case player_money_api:plus_money(PlayerId, ?CONST_SYS_GOLD_BIND, Salary, ?CONST_COST_POSITION_REWARD) of
						?ok ->
							PositionData2   = PositionData#position_data{date = Today},
							Player2         = Player#player{position = PositionData2},
							HomeFlag		= player_sys_api:is_open_sys(Player2, ?CONST_MODULE_HOME),
							Packet          = 
								case HomeFlag of
									?true ->
										case home_mod_create:get_home(PlayerId) of
											Home when is_record(Home, ets_home) ->
												Message			 = Home#ets_home.message,
												Declare			 = Message#message.declare,
												NewDeclear  	 = Declare#declare{get_reward_times = 1},
												NewMessage  	 = Message#message{declare = NewDeclear},
												NewHome			 = Home#ets_home{message = NewMessage},    
												ets_api:insert(?CONST_ETS_HOME, NewHome),
												home_db_mod:update_home(NewHome),
												Packet1          = message_api:msg_notice(?TIP_HOME_OFFICE_GETWARE, 
																						  [{?TIP_SYS_COMM, misc:to_list(Salary)}]),
												Packet2			= notice_daily_task_over(PlayerId),
												<<Packet1/binary, Packet2/binary>>;
											_ ->
												message_api:msg_notice(?TIP_COMMON_SYS_ERROR)
										end;
									?false ->
										message_api:msg_notice(?TIP_HOME_OFFICE_GETWARE, [{?TIP_SYS_COMM, misc:to_list(Salary)}])
								end,
							misc_packet:send(Player2#player.net_pid, Packet),
							{?ok, Player2};
						{?error, _ErrorCode} ->
							{?ok, Player}
					end
			end;
		?false -> {?ok, Player}
	end.
%%-------------------------------------------------------------------------------------------------
%% 请求给玩家松土
%%-------------------------------------------------------------------------------------------------
apply_loosen(Player, UserId, PlantPos) ->                     
	Home				= home_mod_create:get_home(UserId),                    				%% 被松土玩家
	Farm				= Home#ets_home.farm,
	Plant				= erlang:element(PlantPos, Farm#farm.plant),
	LoosenList			= Plant#plant.loosen_list,          				  				%% 对此块地松了土的玩家, 
	LoosenTimes			= erlang:length(LoosenList),                          				%% 可被松土10次
	
	Info1				= Player#player.info,
	PlayerId			= Player#player.user_id,
	PlayerLv			= Info1#info.lv,
	PlayerName			= Info1#info.user_name,
	Home1				= home_mod_create:get_home(PlayerId),
	Message1			= Home1#ets_home.message,
	Declare1			= Message1#message.declare,
	LoosenNum			= Declare1#declare.loosen_times,         						    %% 自己松土过的次数
	LoosenHasNum		= LoosenNum + 1,
	NewDeclare1			= Declare1#declare{loosen_times = LoosenHasNum},
	NewMessage1			= Message1#message{declare= NewDeclare1},

	case {lists:member({PlayerId, PlantPos}, LoosenList), LoosenTimes < ?CONST_HOME_MUCK_TIMES, LoosenNum < 10} of          %% TODO 松土上限 10
		{?true, _, _} ->                   													%% 已经帮助过此好友松土
			TipPacket	= message_api:msg_notice(?TIP_HOME_HAS_LOOSEN),
			misc_packet:send(Player#player.user_id, TipPacket);
		{_, ?false, _} ->                  													%% 此块土地此时刻被松土达到上限　　
			TipPacket	= message_api:msg_notice(?TIP_HOME_LOOSEN_MAX),
			misc_packet:send(Player#player.net_pid, TipPacket);
		{_, _, ?false} ->                   												%% 玩家松土此时已达上限
			TipPacket	= message_api:msg_notice(?TIP_HOME_LOOSEN_NOT_ALLOW),
			misc_packet:send(Player#player.net_pid, TipPacket);
		{?false, ?true, ?true} ->           												%% 可以被松土
			NewHome1	= Home1#ets_home{message = NewMessage1},                            %% 更改自己的松土次数
		
			NewLoosenList= [{PlayerId, PlantPos}|LoosenList],
			PlantRecord = Plant#plant{loosen_list = NewLoosenList},	
			NewPlant	= erlang:setelement(PlantPos, Farm#farm.plant, PlantRecord),
			NewFarm		= Farm#farm{plant = NewPlant},            
			ContentList	= [{?CONST_HOME_MESSAGE_TYPE0, PlayerName}],                             %%好友留言板内容
			RecordList	= add_record1(Home, ?CONST_HOME_MESSAGE_HELP_LOOSEN, ContentList),
			Message		= Home#ets_home.message,
			NewMessage	= Message#message{record = RecordList},
			NewHome		= Home#ets_home{farm = NewFarm, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			GoldBind	= ?CONST_HOME_PLANT_BASE + ?CONST_HOME_PLANT_RATE * PlayerLv ,		   %% 松土奖励公式
			case player_api:get_player_field(UserId, #player.info) of
				{?ok, #info{user_name = UserName}} ->
					ContentList2    = [{?CONST_HOME_MESSAGE_TYPE0, UserName}, 
									   {?CONST_HOME_MESSAGE_TYPE0, misc:to_list(GoldBind)}],      %% 自己留言板内容
					RecordList2	    = add_record1(NewHome1, ?CONST_HOME_MESSAGE_HELP_LOOSENED, ContentList2),
					NewMessage2	    = NewMessage1#message{record= RecordList2},
					NewHome2		= Home1#ets_home{message = NewMessage2},
					ets_api:insert(?CONST_ETS_HOME, NewHome2);
				_ -> 
					ets_api:insert(?CONST_ETS_HOME, NewHome1)
			end,
			player_money_api:plus_money(PlayerId, ?CONST_SYS_GOLD_BIND, GoldBind, ?CONST_COST_LOOSEN_REWARD),
			TipPacket	= message_api:msg_notice(?TIP_HOME_LOOSEN_AWARD, [{?TIP_SYS_COMM, misc:to_list(GoldBind)}]),
			Packet		= home_api:msg_sc_help_loosen(PlantPos),
			Packet1     = get_guide_info(NewHome1),
			Packet2		= case LoosenHasNum =:= 10 of										    %% 通知封邑日常任务状态 
							  ?true   -> notice_daily_task_over(PlayerId);
							  ?false  -> <<>>
						  end,
			Packet3		= case check_loosen_state(PlayerId, NewFarm#farm.plant) of                %% 更新好友土地状态
							  ?CONST_SYS_FALSE ->
								  home_api:msg_sc_loosen_state(UserId, ?CONST_SYS_FALSE);
							  _Other -> <<>>
						  end,
			misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary, Packet1/binary, Packet2/binary, Packet3/binary>>)
	end.

%% 检测施肥状态
check_loosen_state(UserId, Plant) ->
	PlantList			= misc:to_list(Plant),
	F = fun(PlantInfo, Acc) when is_record(PlantInfo, plant) ->
				Pos			= PlantInfo#plant.position,
				LoosenList	= PlantInfo#plant.loosen_list,
				State		= PlantInfo#plant.state,
				case lists:keyfind(Pos, 2, LoosenList) of              
					?false -> 
						case State =:= 3 of
							?true  -> Acc + 1;
							?false -> Acc
						end;
					{OtherId, Pos} when OtherId =:= UserId -> Acc;
					_ -> Acc
				end;
		   (_, Acc) -> Acc
		end,
	lists:foldl(F, ?CONST_SYS_FALSE, PlantList).
%%-------------------------------------------------------------------------------------------------
%% 封邑日常任务信息
%%-------------------------------------------------------------------------------------------------
get_home_daily_award(Player) ->
	UserId		= Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_has_get_award(Home) of									        %% 判断是否领取过了奖励
				?false ->
					case check_home_task_over(Home) of									%% 判断官府任务是否完成
						?true ->
							home_api:msg_sc_daily_info(?CONST_SYS_TRUE);
						{?error, _} ->
							home_api:msg_sc_daily_info(?CONST_SYS_FALSE)
					end;
				?true ->
					home_api:msg_sc_daily_info(2)
			end;
		_ ->
			home_api:msg_sc_daily_info(?CONST_SYS_FALSE)
	end.

%% 通知封邑日常任务完成
notice_daily_task_over(UserId) ->
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_has_get_award(Home) of
				?false ->													    %% 未领取礼包
					case check_home_task_over(Home) of
						?true ->												%% 封邑日常完成
							home_api:msg_sc_daily_info(?CONST_SYS_TRUE);
						{?error, _} ->                                          %% 封邑日常未完成 
							home_api:msg_sc_daily_info(?CONST_SYS_FALSE)
					end;
				?true ->														%% 领取过礼包
					home_api:msg_sc_daily_info(2)
			end;
		_ ->
			home_api:msg_sc_daily_info(?CONST_SYS_FALSE)
	end.
%%-------------------------------------------------------------------------------------------------
%% 领取封邑礼包
%%-------------------------------------------------------------------------------------------------
get_daily_task_award(Player) ->
	UserId		 	= Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			Cash			= ?CONST_HOME_AWARD_CASH,
			GoldBind		= ?CONST_HOME_AWARD_GOLD,
			case check_home_task_over(Home) of
				{?error, ErrorCode} ->
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player};
				?true ->					   															 %% 封邑日常完成 
					case check_has_get_award(Home) of
						?true -> 
							TipPacket		= message_api:msg_notice(?TIP_HOME_GET_DAILY),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player};
						?false ->			   															 %% 未领取礼包
							case Cash > ?CONST_SYS_FALSE of                                     	     %% 礼券
								?true -> player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, Cash, ?CONST_COST_HOME_GET_GIFT); 
								_ -> ?ok
							end,
							case GoldBind > ?CONST_SYS_FALSE of                                     	 %% 铜钱
								?true -> player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind, ?CONST_COST_HOME_GET_GIFT); 
								_ -> ?ok
							end,
							Message		= Home#ets_home.message,
							Declare		= Message#message.declare,
							NewDeclear  = Declare#declare{get_award_times = ?CONST_SYS_TRUE},
							NewMessage  = Message#message{declare = NewDeclear},
							NewHome		= Home#ets_home{message = NewMessage},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							Packet		= home_api:msg_sc_daily_info(2),
							Packet1		= message_api:msg_notice(?TIP_HOME_GET_DAILY_SUCCESS, [{?TIP_SYS_COMM, misc:to_list(Cash)},
																							   {?TIP_SYS_COMM, misc:to_list(GoldBind)}]),
							misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
							{?ok, Player}
					end
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.
%%-------------------------------------------------------------------------------------------------
%% 检测封邑日常任务是否完成
%%-------------------------------------------------------------------------------------------------
check_home_task_over(Home) when is_record(Home, ets_home) ->
	try
%% 		?true		= check_has_get_award(Home),                          %% 是否已领取封邑日常奖励     
		?true		= check_plant_over(Home),							  %% 检查种植土地
		?true		= check_loosen_times(Home),							  %% 检查松土次数
		?true		= check_play_girl_times(Home),						  %% 检查仕女调戏
%% 		?true		= check_grab_girl_times(Home),						  %% 检查仕女抢夺次数
		?true		= check_get_award_times(Home)						  %% 检查领取俸禄
	catch
		throw:{?error, ErrorCode} ->
			?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误
	end;
check_home_task_over(_) -> 
	{?error, ?TIP_HOME_CONDITION_NOT_FIT}.

check_has_get_award(Home) ->
	Message			= Home#ets_home.message,
	Declare			= Message#message.declare,
	Times1			= Declare#declare.get_award_times,					%% 领取封邑日常奖励
	case Times1 =:= ?CONST_SYS_TRUE of
		?false -> ?false;											
		?true  -> ?true												    %%　已领取
	end.
check_plant_over(Home) ->
	Times1			= cal_has_plant_times(Home),						%% 种植土地的总次数
	Farm			= Home#ets_home.farm,
	Plant			= Farm#farm.plant,
	PlantList		= misc:to_list(Plant),
	Times2			= get_has_plant_num(PlantList, ?CONST_SYS_FALSE),	%% 已开启的土地
	case Times1	>= Times2 of
		?true  -> ?true;
		?false -> throw({?error, ?TIP_HOME_CONDITION_NOT_FIT})
	end.
check_loosen_times(Home) ->
	Message			= Home#ets_home.message,
	Declare			= Message#message.declare,
	Times1			= Declare#declare.loosen_times,						%% 已经施肥的次数
	Times2			= 10,								                %% TODO 施肥次数上限
	case Times1	>= Times2 of
		?true  -> ?true;
		?false -> throw({?error, ?TIP_HOME_CONDITION_NOT_FIT})
	end.
check_play_girl_times(Home) ->
	Girl			= Home#ets_home.girl,						
	PlayTimes		= Girl#girl.play_times,                             %% 已经调戏的次数
	case PlayTimes	>= 1 of
		?true  -> ?true;
		?false -> throw({?error, ?TIP_HOME_CONDITION_NOT_FIT})
	end.					
check_grab_girl_times(Home) ->
	Message			= Home#ets_home.message,
	Declare			= Message#message.declare,
	Times1		 	= Declare#declare.grab_times,						%% 已抢夺的次数
	case Times1	>= 3 of
		?true  -> ?true;
		?false -> throw({?error, ?TIP_HOME_CONDITION_NOT_FIT})
	end.
 check_get_award_times(Home) ->                                        %% 已经领取俸禄次数
	 Today			 = misc:date_num(),
	 UserId			 = Home#ets_home.user_id,
	 Message		 = Home#ets_home.message,
	 Declare		 = Message#message.declare,
	 Times			 = Declare#declare.get_reward_times,			    %% 已经领取俸禄的次数
	 case player_api:get_player_field(UserId, #player.position) of
		 {?ok, #position_data{date = Data}} when Data == Today -> ?true;
		 _ ->
			 case Times	>= ?CONST_SYS_TRUE of
				 ?true  -> ?true;
				 ?false -> throw({?error, ?TIP_HOME_CONDITION_NOT_FIT})
			 end
	 end.
%% ------------------------------------------------------------------------------------------------
%% 请求已经招募的仕女信息
%%-------------------------------------------------------------------------------------------------
get_recruit_girl_info(Player) ->
	PlayerId	 = Player#player.user_id,
	case home_mod_create:get_home(PlayerId) of
		Home when is_record(Home, ets_home) ->
			Girl		 = Home#ets_home.girl,
			VipList		 = Girl#girl.recruit_vip_list,
			List2		 = get_recruit_vip_list(Player),
			case List2 =/= VipList of
				?true ->
					NewGirl		= Girl#girl{recruit_vip_list = List2},
					NewHome		= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome);
				?false -> ?ok
			end,
			RecruitList	 = get_recruit_list(Player, Girl),
			Packet		 = home_api:msg_sc_girl_info(PlayerId, RecruitList),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			Packet		 = home_api:msg_sc_girl_info(PlayerId, []),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%% 获取招募的列表
get_recruit_list(Player, Girl) when is_record(Player, player) ->
	get_recruit_list(Player#player.info, Girl);
get_recruit_list(Info, Girl) ->
	List		 = Girl#girl.recruit_list,
	List1		 = get_recruit_common_list(List, []),
	List2		 = get_recruit_vip_list(Info),
	List1 ++ List2.

%% 获取普通侍女列表
get_recruit_common_list([{Id}|RestList], Acc) ->
	NewAcc		 = [{Id}|Acc],
	get_recruit_common_list(RestList, NewAcc);
get_recruit_common_list([], Acc) ->
	Acc.

%% 获取vip招募列表
get_recruit_vip_list(Player) when is_record(Player, player) ->
	get_recruit_vip_list(Player#player.info);
get_recruit_vip_list(Info) when is_record(Info, info) ->
	VipLv		 = player_api:get_vip_lv(Info),
	Num			 = player_vip_api:get_home_girl_max(?CONST_SYS_FALSE),
	VipNum		 = player_vip_api:get_home_girl_max(VipLv), 
	ExtNum		 = VipNum - Num,
	case ExtNum =< ?CONST_SYS_FALSE of
		?true  -> [];
		?false ->
			get_recruit_vip_list1(Num, ExtNum, [])
	end;
get_recruit_vip_list(UserId) ->                                          %% TODO
	case player_api:get_player_first(UserId) of
		{?ok, ?null, _} ->
			[];
		{?ok, Player, _} ->
			get_recruit_vip_list(Player)
	end.

get_recruit_vip_list1(Num, ExtNum, Acc) when ExtNum > ?CONST_SYS_FALSE ->
	Id			 = Num + ExtNum,
	NewAcc		 = [{Id}|Acc],
	get_recruit_vip_list1(Num, ExtNum - 1, NewAcc);
get_recruit_vip_list1(_, _, Acc) ->
	Acc.
%% %%----------------------------------------------------------------------------------------------
%% 招募仕女
%%-------------------------------------------------------------------------------------------------
recruit_girl(Player, Id) ->
	PlayerId	 = Player#player.user_id,
	case home_mod_create:get_home(PlayerId) of
		Home when is_record(Home, ets_home) ->
			HomeLv		 = Home#ets_home.lv,
			Girl		 = Home#ets_home.girl,
			
			RecruitList	 = Girl#girl.recruit_list,
			RecruitNum	 = erlang:length(RecruitList),
			Flag		 = case lists:keyfind(Id, ?CONST_SYS_TRUE, RecruitList) of
							   ?false -> ?true;
							   _ ->      ?false
						   end,	
			GirlData	 = data_home:get_girlinfo(Id),
			Flag1		 = GirlData#rec_home_girl_info.homeLevel =< HomeLv,
			MaxNum		 = player_vip_api:get_home_girl_max(?CONST_SYS_FALSE),
			?MSG_DEBUG("RecruitList=~p Flag=~p, RecruitNum=~p", [RecruitList, Flag, RecruitNum]),
			case {lists:member({Id - 1}, RecruitList), Id =< MaxNum, Flag, Flag1}of
				{?false, _, _, _}->       										%% 此仕女不可招募 前一仕女还未招募
					TipPacket	 = message_api:msg_notice(?TIP_HOME_RECRUIT_FAIL),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{_, ?false, _, _} ->                                            %% 招募数量达到上限
					TipPacket	 = message_api:msg_notice(?TIP_HOME_RECRUIT_MAX),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{_, _, ?false, _} ->											%% 已经招募过该仕女
					TipPacket	 = message_api:msg_notice(?TIP_HOME_GIRL_HAS_EXIST),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{_, _, _, ?false} ->										     %% 封邑等级不足
					TipPacket	 = message_api:msg_notice(?TIP_HOME_RECRUIT_NOT_ALLOW),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{?true, ?true, ?true, ?true}->    							     %% 可以招募
					Cost		 = GirlData#rec_home_girl_info.cost,             %% 招募消耗
					case player_money_api:minus_money(PlayerId, ?CONST_SYS_GOLD_BIND, Cost, ?CONST_COST_RECRUIT_GIRL) of
						?ok ->
							NewRecruit	= [{Id}|RecruitList],
							NewGirl 	= Girl#girl{recruit_list = NewRecruit},
							NewHome 	= Home#ets_home{girl = NewGirl},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							home_db_mod:update_home_girl(NewHome),
							TipPacket	= message_api:msg_notice(?TIP_HOME_RECRUIT_SUCCESS),
							Packet		= home_api:msg_sc_recruit_success(Id),
							misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary>>);
						{?error, ErrorCode} ->
							?MSG_DEBUG("ErrorCode=~p", [ErrorCode])
					end
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获得资源奖励
add_play_gain(?CONST_HOME_RESOUCE_EXP, Gain, Player) -> player_api:exp(Player, Gain);
add_play_gain(?CONST_HOME_RESOUCE_GOLD, Gain, Player) -> 
	UserId		= Player#player.user_id,
	player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gain, ?CONST_COST_PLANT_REWARD),
	{?ok, Player};
add_play_gain(?CONST_HOME_RESOUCE_SER, Gain, Player) ->
	Player1	 = player_api:plus_experience(Player, Gain),
	{?ok, Player1};
add_play_gain(_, _, Player) -> {?ok, Player}.

%% 获得奖励提示
msg_play_gain(_, ?CONST_SYS_FALSE) -> <<>>;
msg_play_gain(?CONST_HOME_RESOUCE_EXP, Gain) -> message_api:msg_notice(?TIP_HOME_HAVAST_EXP, [{?TIP_SYS_COMM, misc:to_list(Gain)}]);
msg_play_gain(?CONST_HOME_RESOUCE_GOLD, Gain)-> message_api:msg_notice(?TIP_HOME_HARVAST_SUCCESS,  [{?TIP_SYS_COMM, misc:to_list(Gain)}]);
msg_play_gain(_, _) -> <<>>.

%%-------------------------------------------------------------------------------------------------
%%  增加互动留言(仕女面板上显示)
%%-------------------------------------------------------------------------------------------------
add_record1(Home, Id, ContentList) ->
	Now				= misc:seconds(),
	Message			= Home#ets_home.message,
	RecordList		= Message#message.record,
	MessageNum		= erlang:length(RecordList),
	case MessageNum >= 20 of
		?true ->    %% 超过20条的记录，把最早的记录删除
			[_Head|RestList]	= RecordList,
			RestList ++ [{Id, Now, ContentList}];
		?false ->
			RecordList ++ [{Id, Now, ContentList}]
	end.

%% 获取侍女的最高侍女id
get_top_girl_id(Girl) when is_record(Girl, girl) ->
	Girl#girl.show_girl;
get_top_girl_id(UserId) when is_integer(UserId)->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl		= Home#ets_home.girl,
			Girl#girl.show_girl;
		_ -> ?CONST_SYS_TRUE
	end;
get_top_girl_id(_) -> ?CONST_SYS_TRUE.
%%-------------------------------------------------------------------------------------------------
%% 初始化官府任务
%%-------------------------------------------------------------------------------------------------
init_task() ->
	RefreshTime		 = ?CONST_SYS_FALSE,
	Times			 = ?CONST_SYS_FALSE,
	NewDate			 = misc:date_num(),
%% 	TaskTuple 	  	 = erlang:make_tuple(4, 0, []),
%% 	TaskInfo		 = init_task_info(UserId, TaskTuple, ?CONST_SYS_TRUE),
	TaskInfo		 = #task{},
	#task_info{refresh_time = RefreshTime, times = Times, task = TaskInfo, date = NewDate}.

init_task_info(UserId, TaskTuple, Num) when Num =< 4 ->
	Id				 = get_random_task_id(UserId),
	Color			 = get_office_task_color(Id),
	Task			 = #task{grid = Num, id = Id, color = Color, state = ?CONST_SYS_FALSE, time = ?CONST_SYS_FALSE},
	NewTaskTuple	 = erlang:setelement(Num, TaskTuple, Task),
	init_task_info(UserId, NewTaskTuple, Num + 1);
init_task_info(_, TaskTuple, _) ->
	TaskTuple.

%% 按等级限制随机出任务
get_random_task_id(UserId) ->
	case  player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{lv= Lv}}->
			case get_random_task_list(Lv, []) of
				[]  -> ?CONST_HOME_TASK_COPY;
				List-> misc_random:random_one(List)
			end;
		_ -> ?CONST_HOME_TASK_COPY
	end.
%% 按等级限制随机出任务列表				
get_random_task_list(Lv, Acc) ->
	Id			= misc_random:random(?CONST_HOME_TASK_NUM),
	case data_home:get_office_task(Id) of
		RecTask when is_record(RecTask, rec_home_task) -> 
			LvMin		= RecTask#rec_home_task.lv,
			case Lv >= LvMin of
				?true  -> [Id|Acc];
				?false -> Acc
			end;
		_ -> []
	end.

%% 获取官府的基础数据
get_office_task_cd(Id) ->
	RecTask			 = data_home:get_office_task(Id),
	InteverTime		 = RecTask#rec_home_task.refresh_cd,
	InteverTime * ?CONST_SYS_NUMBER_SIXTY.
get_office_task_rate(Color) ->
	RecTask			 = data_home:get_office_task(?CONST_SYS_TRUE),
	{_, List}	 	 = RecTask#rec_home_task.refresh_probablity,
	case lists:keyfind(Color, 1, List) of
		?false -> ?CONST_SYS_TRUE;
		{_, _, Rate} -> Rate
	end.
get_office_task_color(Id) ->
	RecTask			 = data_home:get_office_task(Id),
	case data_home:get_office_task(Id) of
		RecTask when is_record(RecTask, rec_home_task) ->
			{_, RefreshList} = RecTask#rec_home_task.refresh_probablity,
			List 			 = [{Color1, Probablity} || {Color1, Probablity, _} <- RefreshList], 
			{List1, ExpectSum}= misc_random:odds_list_init(?MODULE, ?LINE, List, ?CONST_SYS_NUMBER_TEN_THOUSAND),
			Color			 = misc_random:odds_one(List1, ExpectSum),
			Color;
		_ -> 2
	end.
get_task_color_cd(Color) ->
	RecTask			 = data_home:get_office_task(?CONST_SYS_TRUE),
	ColorCd			 = RecTask#rec_home_task.color_cd,
	case lists:keyfind(Color, 1, ColorCd) of
		 ?false -> ?CONST_SYS_FALSE;
		 {_, Cd} -> Cd * ?CONST_SYS_NUMBER_SIXTY
	end.
%%-------------------------------------------------------------------------------------------------
%% 请求官府任务信息
%%-------------------------------------------------------------------------------------------------
get_office_task(Player) ->
	UserId			 = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			Now				 = misc:seconds(),
			StartTime		 = OfficeTask#task_info.refresh_time,
			Cd				 = get_office_task_cd(?CONST_SYS_TRUE),
			EndTime			 = StartTime + Cd,
			TimeTemp		 = EndTime - Now,
			RefreshTime		 = case TimeTemp > ?CONST_SYS_FALSE of
								   ?true -> TimeTemp + Now;
								   ?false -> ?CONST_SYS_FALSE
							   end,
			TaskInfo		 = OfficeTask#task_info.task,
			Times			 = OfficeTask#task_info.times,
			TaskList		 = misc:to_list(TaskInfo),
			List			 = get_office_task_list(UserId, TaskList, []),
			Packet			 = home_api:msg_sc_office_task(List, RefreshTime),
			Packet1			 = home_api:msg_sc_office_task_times(Times),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
		_ ->
			TipPacket		 = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.


%% 获取任务列表
get_office_task_list(UserId, [Task|RestList], Acc) when is_record(Task, task) ->
	Grid		= Task#task.grid,
	Id			= case Task#task.id > ?CONST_HOME_TASK_NUM of
					  ?true  -> get_random_task_id(UserId);
					  ?false -> Task#task.id
				  end,
	Color		= Task#task.color,
	State		= Task#task.state,
	LeftTime	= ?CONST_SYS_FALSE,
	NewAcc		= [{Grid, Id, Color, LeftTime, State}|Acc],
	get_office_task_list(UserId, RestList, NewAcc);
get_office_task_list(UserId, [_|RestList], Acc) -> 
	get_office_task_list(UserId, RestList, Acc);
get_office_task_list(_, [], Acc) -> Acc.

%% ------------------------------------------------------------------------------------------------
%%　立即刷新任务
%%-------------------------------------------------------------------------------------------------
refresh_office_task(Player, ?CONST_SYS_FALSE) ->   						%% 普通刷新
	UserId			 = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			TaskInfo		 = OfficeTask#task_info.task,
			Now				 = misc:seconds(),
			StartTime		 = OfficeTask#task_info.refresh_time,
			Cd				 = get_office_task_cd(?CONST_SYS_TRUE),
			EndTime			 = StartTime + Cd ,
			TimeTemp		 = EndTime - Now,
			RefNum	 		 = cal_refresh_num(TaskInfo),
			Flag			 = RefNum,
			case {TimeTemp > ?CONST_SYS_FALSE, Flag =:= ?CONST_SYS_FALSE} of
				{_, ?true} ->				%% 没有任务可以刷新
					TipPacket		= message_api:msg_notice(?TIP_HOME_NEED_NOT_REFRESH),
					misc_packet:send(Player#player.net_pid, TipPacket);
				{?true, ?false}-> 			%% 刷新cd中 用元宝刷新
					Value	 		= RefNum * ?CONST_HOME_COM_TASK,
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, 0) of
						?ok ->
							NewTaskInfo		= refresh_task_cb(UserId, TaskInfo, ?CONST_SYS_TRUE, ?CONST_SYS_FALSE),
							NewOfficeTask	= OfficeTask#task_info{task = NewTaskInfo},
							NewHome			= Home#ets_home{task_info = NewOfficeTask},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							List			= get_office_task_list(UserId, misc:to_list(NewTaskInfo), []),
							Packet			= home_api:msg_sc_office_task(List, EndTime),
							misc_packet:send(Player#player.net_pid, Packet);
						{?error, _}  -> ?ok					%% 元宝不足
					end;
				{?false, ?false}->			%% 可以免费刷新
					NewTaskInfo		= refresh_task_cb(UserId, TaskInfo, ?CONST_SYS_TRUE, ?CONST_SYS_FALSE),
					NewOfficeTask	= OfficeTask#task_info{refresh_time = Now, task = NewTaskInfo},
					NewHome			= Home#ets_home{task_info = NewOfficeTask},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					List			= get_office_task_list(UserId, misc:to_list(NewTaskInfo), []),
					RefreshTime		= Now + Cd,
					Packet			= home_api:msg_sc_office_task(List, RefreshTime),
					misc_packet:send(Player#player.net_pid, Packet)
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end;
refresh_office_task(Player, ?CONST_SYS_TRUE) ->          %% 一键刷新
	UserId			 = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			TaskInfo		 = OfficeTask#task_info.task,
			StartTime		 = OfficeTask#task_info.refresh_time,
			Now				 = misc:seconds(),
			Cd				 = get_office_task_cd(?CONST_SYS_TRUE),
			EndTime			 = StartTime + Cd,
			TimeTemp		 = EndTime - Now,
			RefNum	 		 = cal_refresh_num(TaskInfo),
			case RefNum	=:= ?CONST_SYS_FALSE of
				?true ->			%% 没有可刷新的任务
					TipPacket		= message_api:msg_notice(?TIP_HOME_NEED_NOT_REFRESH),
					misc_packet:send(Player#player.net_pid, TipPacket);
				?false ->
					Value	 		= RefNum * ?CONST_HOME_ONE_KEY_TASK,
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, 0) of
						?ok ->
							NewTaskInfo		= refresh_task_cb(UserId, TaskInfo, ?CONST_SYS_TRUE, ?CONST_SYS_TRUE),
							NewOfficeTask	= OfficeTask#task_info{task = NewTaskInfo},
							NewHome			= Home#ets_home{task_info = NewOfficeTask},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							List			= get_office_task_list(UserId, misc:to_list(NewTaskInfo), []),
							RefreshTime		= case TimeTemp > ?CONST_SYS_FALSE of
												  ?true -> EndTime;
												  ?false -> ?CONST_SYS_FALSE
											  end,
							Packet			= home_api:msg_sc_office_task(List, RefreshTime),
							misc_packet:send(Player#player.net_pid, Packet);
						{?error, _}  -> %% 元宝不足
							?ok
					end
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%% 刷新未接受的任务
refresh_task_cb(UserId, TaskInfo, Num, Type) when Num =< 4 ->
	Task		= erlang:element(Num, TaskInfo),
	State		= Task#task.state,
	case {State =:= ?CONST_SYS_FALSE, Type =:= ?CONST_SYS_FALSE}of
		{?true, ?true}->              %%普通刷新  只刷新未接受的任务 
			Id				 = get_random_task_id(UserId),
			Color			 = get_office_task_color(Id),
			NewTask			 = #task{grid = Num, id = Id, color = Color, state = ?CONST_SYS_FALSE, time = ?CONST_SYS_FALSE},
			NewTaskTuple	 = erlang:setelement(Num, TaskInfo, NewTask),
			refresh_task_cb(UserId, NewTaskTuple, Num + 1, Type);
		{?true, ?false} ->           %%一键刷新  只刷新未接受的任务   
			Id				 = get_random_task_id(UserId),
			Color			 = 7,    %% 最高品质
			NewTask			 = #task{grid = Num, id = Id, color = Color, state = ?CONST_SYS_FALSE, time = ?CONST_SYS_FALSE},
			NewTaskTuple	 = erlang:setelement(Num, TaskInfo, NewTask),
			refresh_task_cb(UserId, NewTaskTuple, Num + 1, Type);
		{?false, _} ->				  %% 不用刷新此格子的任务
			refresh_task_cb(UserId, TaskInfo, Num + 1, Type)
	end;
refresh_task_cb(_, TaskInfo, _, _) ->
	TaskInfo.

%% 计算需要刷新的格子位置
cal_refresh_num(TaskInfo) ->
	TaskList		= misc:to_list(TaskInfo),
	F	= fun(Task, Acc) when is_record(Task, task) ->
				  State		= Task#task.state,
				  case State of
					  ?CONST_SYS_FALSE -> Acc + 1;
					  _ -> Acc
				  end;
			 (_, Acc) -> Acc
		  end,
	lists:foldl(F, ?CONST_SYS_FALSE, TaskList).

%%-------------------------------------------------------------------------------------------------
%% 封邑任务操作请求 1接受２取消３领奖４立即完成
%%-------------------------------------------------------------------------------------------------
office_task_operate(Player, 1, Grid) -> accept_office_task(Player, Grid);	
office_task_operate(Player, 2, Grid) -> cancle_office_task(Player, Grid);
office_task_operate(Player, 3, Grid) -> get_office_task_reward(Player, Grid);
office_task_operate(Player, 4, Grid) -> over_office_task(Player, Grid);
office_task_operate(Player, _, _) -> 
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket).
%% ------------------------------------------------------------------------------------------------
%% 立即完成任务
%%-------------------------------------------------------------------------------------------------
over_office_task(Player, Grid) when Grid =< ?CONST_SYS_FALSE orelse Grid > 4 ->   %% 参数错误
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	Player;
over_office_task(Player, Grid) ->
	UserId			 = Player#player.user_id,
	Info			 = Player#player.info,
	Lv				 = Info#info.lv,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			TaskInfo		 = OfficeTask#task_info.task,
			Times			 = OfficeTask#task_info.times,
			NewTimes		 = Times + 1,
			Task			 = erlang:element(Grid, TaskInfo),
			OldColor		 = Task#task.color,
			State			 = Task#task.state,
			Flag			 = Times < 10,
			case {State, Flag}of                              %%任务正在进行中且领取奖励未达上限　可立即完成
				{?CONST_SYS_TRUE, ?true} ->
					Value	 = ?CONST_HOME_OVER_TASK,
					case player_money_api:minus_money(UserId, ?CONST_SYS_BCASH_FIRST, Value, 0) of
						?ok ->
							BaseExp			= 50 *(0.4 + Lv * 0.6),
							ColorBonus		= get_office_task_rate(OldColor),
							Exp				= misc:ceil(BaseExp * ColorBonus),
							{?ok, NewPlayer}= player_api:exp(Player, Exp),           %% 领取奖励后重新刷出一个任务
							NewId			= get_random_task_id(UserId),
							NewColor		= get_office_task_color(NewId),
							NewTask			= #task{grid = Grid, id = NewId, color = NewColor, state = ?CONST_SYS_FALSE, 
													time = ?CONST_SYS_FALSE},
							NewTaskInfo		= erlang:setelement(Grid, TaskInfo, NewTask),
							NewOfficeTask	= OfficeTask#task_info{task = NewTaskInfo, times = NewTimes},  
							NewHome			= Home#ets_home{task_info = NewOfficeTask},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							TipPacket		= message_api:msg_notice(?TIP_HOME_TASK_REWARD_SUCCESS, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),
							Packet			= home_api:msg_sc_refresh_one_task(Grid, NewId, NewColor, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
							Packet1			= home_api:msg_sc_office_task_times(NewTimes),
							Packet2			= case NewTimes =:= 10 of									   %% 判断是否该发送礼包
												  ?true  -> notice_daily_task_over(UserId);
												  ?false -> <<>>
											  end,
							misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary, Packet1/binary, Packet2/binary>>),
							NewPlayer;
						{?error, _} -> Player
					end;
				{?CONST_SYS_FALSE, _} ->               %% 还未领取任务
					TipPacket		= message_api:msg_notice(?TIP_HOME_TASK_NOT_ACCEPT),				
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player;
				{_, ?false} ->						   %% 领取上限
					TipPacket		= message_api:msg_notice(?TIP_HOME_NOT_ALLOW_OVER),				
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player;
				{_, _}-> 								%% 任务已完成				
					TipPacket		= message_api:msg_notice(?TIP_HOME_TASK_OVER),
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player
	end.
%% ------------------------------------------------------------------------------------------------
%% 领取官府任务奖励     %% 只有十次领取机会
%%-------------------------------------------------------------------------------------------------
get_office_task_reward(Player, Grid) ->
	UserId			 = Player#player.user_id,
	Info			 = Player#player.info,
	Lv				 = Info#info.lv,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			Times			 = OfficeTask#task_info.times,      			  %% 已完成任务次数 
			NewTimes		 = Times + 1,
			TaskInfo		 = OfficeTask#task_info.task,
			Task			 = erlang:element(Grid, TaskInfo),
			OldColor		 = Task#task.color,
			State			 = Task#task.state,
			?MSG_DEBUG("State=~p Times=~p", [State, Times]),
			case {State =:= 2, Times < 10}of
				{?true, ?true}->       %% 任务已完成且没有超过次数
					BaseExp		= 50 *(0.4 + Lv * 0.6),
					ColorBonus	= get_office_task_rate(OldColor),
					Exp			= misc:ceil(BaseExp * ColorBonus),
					{?ok, NewPlayer} = player_api:exp(Player, Exp),           %% 领取奖励后重新刷出一个任务
					Id			= get_random_task_id(UserId),
					Color		= get_office_task_color(Id),
					NewTask		= #task{grid = Grid, id = Id, color = Color, state = ?CONST_SYS_FALSE, time = ?CONST_SYS_FALSE},
					NewTaskInfo	= erlang:setelement(Grid, TaskInfo, NewTask),
					NewOfficeTask= OfficeTask#task_info{times = NewTimes, task = NewTaskInfo},
					NewHome		= Home#ets_home{task_info = NewOfficeTask},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					Packet		= home_api:msg_sc_refresh_one_task(Grid, Id, Color, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
					Packet1		= home_api:msg_sc_office_task_times(NewTimes),
					Packet2		= case NewTimes =:= 10 of									   %% 判断是否该发送礼包
									  ?true  -> notice_daily_task_over(UserId);
									  ?false -> <<>>
								  end,
					TipPacket	= message_api:msg_notice(?TIP_HOME_TASK_REWARD_SUCCESS, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),			
					misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary, Packet1/binary, Packet2/binary>>),			
					NewPlayer;
				{?false, _}->      %% 任务未完成 不能领取
					TipPacket		= message_api:msg_notice(?TIP_HOME_TASK_NOT_OVER),				
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player;
				{_, ?false} ->     %% 任务领取已超过十次
					TipPacket		= message_api:msg_notice(?TIP_HOME_TASK_REWARD_OVER),
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player
	end.
%%-------------------------------------------------------------------------------------------------
%% 取消官府任务
%%-------------------------------------------------------------------------------------------------
cancle_office_task(Player, Grid) when Grid < 0 orelse Grid > 4 ->   %% 参数错误
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	Player;
cancle_office_task(Player, Grid) ->
	UserId			 = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			TaskInfo		 = OfficeTask#task_info.task,
			Task			 = erlang:element(Grid, TaskInfo),
			Id				 = Task#task.id,
			Color			 = Task#task.color,
			State			 = Task#task.state,
			case State =/= ?CONST_SYS_FALSE of
				?true ->	%% 可以取消
					NewTak	 	 = Task#task{state = ?CONST_SYS_FALSE, time = ?CONST_SYS_FALSE},
					NewTaskInfo	 = erlang:setelement(Grid, TaskInfo, NewTak),
					NewOfficeTask= OfficeTask#task_info{task = NewTaskInfo},
					NewHome		 = Home#ets_home{task_info = NewOfficeTask},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					Packet			= home_api:msg_sc_refresh_one_task(Grid, Id, Color, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE),
					misc_packet:send(Player#player.net_pid, Packet),
					Player;
				?false ->	%% 还未接受任务 不可取消
					TipPacket	= message_api:msg_notice(?TIP_HOME_TASK_NOT_ACCEPT),
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player
	end.
%%-------------------------------------------------------------------------------------------------
%% 接受官府任务
%%-------------------------------------------------------------------------------------------------
accept_office_task(Player, Grid) when Grid < 0 orelse Grid > 4 ->   %% 参数错误
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	Player;
accept_office_task(Player, Grid) ->
	UserId			 = Player#player.user_id,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask		 = Home#ets_home.task_info,
			TaskInfo		 = OfficeTask#task_info.task,
			Task			 = erlang:element(Grid, TaskInfo),
			Id				 = Task#task.id,
			Color			 = Task#task.color,
			Now				 = misc:seconds(),
			case check_accept_task_num(TaskInfo, Grid) of
				?ok ->
					NewTak	 	 = Task#task{state = ?CONST_SYS_TRUE, time = Now},
					NewTaskInfo	 = erlang:setelement(Grid, TaskInfo, NewTak),
					NewOfficeTask= OfficeTask#task_info{task = NewTaskInfo},
					NewHome		 = Home#ets_home{task_info = NewOfficeTask},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					Cd			 = get_task_color_cd(Color),
					EndTime		 = Now + Cd,
					Packet		 = home_api:msg_sc_refresh_one_task(Grid, Id, Color, EndTime, ?CONST_SYS_TRUE),
					misc_packet:send(Player#player.net_pid, Packet),
					Player;
				{?error, ErrorCode} ->
					TipPacket	= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player
	end.

%% 检查接受任务
check_accept_task_num(TaskInfo, Grid) ->
	TaskList		= misc:to_list(TaskInfo),
	StateList		= [Task#task.state || Task <- TaskList],
	Task			= erlang:element(Grid, TaskInfo),
	State			= Task#task.state,
	case lists:member(?CONST_SYS_TRUE, StateList) of
		?false -> 
			case State of
				?CONST_SYS_FALSE -> ?ok;                                  %% 可以接受任务
				?CONST_SYS_TRUE ->	{?error, ?TIP_HOME_TASK_RUNNING};	  %% 任务正在进行中
				_ -> {?error, ?TIP_HOME_TASK_OVER}
			end;	
		?true  -> {?error, ?TIP_HOME_HAS_ACCEPTE_TASK}
	end.
%%-------------------------------------------------------------------------------------------------
%% 通过行为完成官府任务
%%-------------------------------------------------------------------------------------------------
notice_home_task_over(Player, OtherId) when is_record(Player, player)->
	UserId			 = Player#player.user_id,
	SysId			 = Player#player.sys_rank,
	case SysId	>= data_guide:get_task_rank(?CONST_MODULE_HOME) of       
		?true ->                                %% 家园开启 可更新官府任务
			case home_mod_create:get_home(UserId) of
				Home when is_record(Home, ets_home) ->
					OfficeTask			= Home#ets_home.task_info,
					TaskInfo			= OfficeTask#task_info.task,
					TaskList			= misc:to_list(TaskInfo),
					{NewTaskInfo, Flag} = update_home_task_over(TaskList, OtherId, TaskInfo, ?CONST_SYS_FALSE),
					case Flag =:= ?CONST_SYS_TRUE of
						?true ->
							NewOfficeTask 		= OfficeTask#task_info{task = NewTaskInfo},
							NewHome				= Home#ets_home{task_info = NewOfficeTask},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							?ok;
						?false -> ?ok
					end;    
				_ -> ?ok
			end;
		?false -> ?ok
	end;
notice_home_task_over(UserId, OtherId) ->
    RankId = data_guide:get_task_rank(?CONST_MODULE_HOME),
	case player_api:get_player_field(UserId, #player.sys_rank) of
		{?ok, Sys} when Sys >= RankId ->   %% 家园开启 可更新官府任务
			case home_mod_create:get_home(UserId) of
				Home when is_record(Home, ets_home) ->
					OfficeTask			= Home#ets_home.task_info,
					TaskInfo			= OfficeTask#task_info.task,
					TaskList			= misc:to_list(TaskInfo),
					{NewTaskInfo, Flag} = update_home_task_over(TaskList, OtherId, TaskInfo, ?CONST_SYS_FALSE),
					case Flag =:= ?CONST_SYS_TRUE of
						?true ->
							NewOfficeTask 		= OfficeTask#task_info{task = NewTaskInfo},
							NewHome				= Home#ets_home{task_info = NewOfficeTask},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							?ok;
						?false -> ?ok
					end;
				_ -> ?ok
			end;
		_ -> ?ok
	end.

%% 更新任务信息
update_home_task_over([Task|RestList], OtherId, TaskInfo, Flag) when is_record(Task, task)->
	State		= Task#task.state,
	Grid		= Task#task.grid,
	Id			= Task#task.id,
	case {OtherId =:= Id, State =/= ?CONST_SYS_FALSE}of
		{?true, ?true}->
			NewTask		= Task#task{state = 2},
			NewTaskInfo	= erlang:setelement(Grid, TaskInfo, NewTask),
			update_home_task_over(RestList, OtherId, NewTaskInfo, ?CONST_SYS_TRUE);
		{_, _} ->
			update_home_task_over(RestList, OtherId, TaskInfo, Flag)
	end;
update_home_task_over([_Task|RestList], OtherId, TaskInfo, Flag) ->
	update_home_task_over(RestList, OtherId, TaskInfo, Flag);
update_home_task_over([], _, TaskInfo, Flag) ->
	{TaskInfo, Flag}.
	
%%-------------------------------------------------------------------------------------------------
%% 请求城池宣言等信息
%%-------------------------------------------------------------------------------------------------
get_owner_declear(Player, UserId)->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			UserId			  = Home#ets_home.user_id,
			Today             = misc:date_num(),
			Message	  		  = Home#ets_home.message,
			Declare			  = Message#message.declare,
			GrabTimes	  	  = Declare#declare.grab_times,	
			GetWareTimes	  = case player_api:get_player_field(UserId, #player.position) of
									{?ok, #position_data{date = Data}} when Data == Today -> ?CONST_SYS_TRUE;
									_ -> 
										Declare#declare.get_reward_times
								end,
			Message	  		  = Home#ets_home.message,
			Girl			  = Home#ets_home.girl,
			GrabGirlTimes 	  = case GrabTimes >= ?CONST_HOME_GRAB_MAX of
								?true  -> ?CONST_HOME_GRAB_MAX;
								?false -> GrabTimes
								end,
			PlantTimes		  = cal_has_plant_times(Home),
			LoosenTimes		  = Declare#declare.loosen_times,
			
			PlayTimes	  	  = Girl#girl.play_times,
			PlayTimes1		  = case PlayTimes >= ?CONST_HOME_PLAY_TIMES of
									?true  -> ?CONST_HOME_PLAY_TIMES;
									?false -> PlayTimes
								end,
			Content			  = Declare#declare.content,
			Packet			  = home_api:msg_sc_declear_info(GetWareTimes, PlayTimes1, GrabGirlTimes, PlantTimes, LoosenTimes, Content),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%%　编辑城主宣言
%%-------------------------------------------------------------------------------------------------
edit_home_declear(Player, Content) ->
	UserId			  = Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message	  		  = Home#ets_home.message,
			Declare			  = Message#message.declare,
			NewDeclear		  = Declare#declare{content = Content},
			NewMessage	  	  = Message#message{declare = NewDeclear},
			NewHome			  = Home#ets_home{message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			Packet			  = home_api:msg_edit_home_declear(?CONST_SYS_TRUE),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 编辑玩家留言
%%-------------------------------------------------------------------------------------------------
edit_leave_message(Player, UserId, Content) ->
	Info			  = Player#player.info,
	PlayerId		  = Player#player.user_id,
	PlayerName		  = Info#info.user_name,
	Now				  = misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			MessageBoard	  = Home#ets_home.message,
			Note			  = MessageBoard#message.note,
			NoteNum			  = erlang:length(Note),
			case NoteNum  >= 10 of                       %% 超过10条记录
				?true ->
					Note1	  = lists:keydelete(?CONST_SYS_TRUE, 1, Note),
					Note2	  = reset_leave_message(Note1, []),
					NewNote   = [{10, PlayerId, PlayerName, Now, Content}|Note2],
					NewMessage= MessageBoard#message{note = NewNote},
					NewHome	  = Home#ets_home{message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					TipPacket = message_api:msg_notice(?TIP_HOME_LEAVE_MESSAGE_SUCCESS),
					Packet			  = home_api:msg_sc_get_leave_message(NewNote),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
				?false ->
					Id			 = NoteNum + 1,
					NewNote		 = [{Id, PlayerId, PlayerName, Now, Content}|Note],
					NewMessage	 = MessageBoard#message{note = NewNote},
					NewHome	  	 = Home#ets_home{message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					TipPacket	 = message_api:msg_notice(?TIP_HOME_LEAVE_MESSAGE_SUCCESS),
					Packet		 = home_api:msg_edit_leave_message(Id),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>)
			end;
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%% 重新设定玩家留言id.
reset_leave_message([{Id, UserId, Name, Now, Content}|RestList], Acc) ->
	Note		= {Id - 1, UserId, Name, Now, Content},
	NewAcc		= [Note|Acc],
	reset_leave_message(RestList, NewAcc);
reset_leave_message([], NewAcc) ->
	NewAcc.

%%-------------------------------------------------------------------------------------------------
%% 请求玩家留言信息
%%-------------------------------------------------------------------------------------------------
get_leave_message(Player, UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			MessageBoard	  = Home#ets_home.message,
			MessageList		  = MessageBoard#message.note,
			Packet			  = home_api:msg_sc_get_leave_message(MessageList),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 删除玩家留言
%%-------------------------------------------------------------------------------------------------
delete_leave_message(Player, Id) ->
	UserId			  = Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			MessageBoard	  = Home#ets_home.message,
			MessageList		  = MessageBoard#message.note,
			NewMessageList	  = lists:keydelete(Id, 1, MessageList),
			NewMessageBoard	  =	MessageBoard#message{note = NewMessageList},
			NewHome	  = Home#ets_home{message = NewMessageBoard},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			TipPacket		  = message_api:msg_notice(?TIP_HOME_DELETE_LEAVE_MESSAGE),
			Packet			  = home_api:msg_delete_leave_message(Id),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 清空留言信息
%%-------------------------------------------------------------------------------------------------
clean_leave_message(Player) ->
	UserId			  = Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			MessageBoard	  = Home#ets_home.message,
			NewMessageBoard	  =	MessageBoard#message{note = []},
			NewHome	  		  = Home#ets_home{message = NewMessageBoard},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			TipPacket		  = message_api:msg_notice(?TIP_HOME_CLEAN_LEAVE_MESSAGE),
			Packet			  = home_api:msg_sc_clean_message(?CONST_SYS_TRUE),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 获取访客操作记录
%%-------------------------------------------------------------------------------------------------
get_visit_record(Player, UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message	  		  = Home#ets_home.message,
			RecordList		  = Message#message.record,
			?MSG_DEBUG("RecordList=~p", [RecordList]),
			Packet			  = home_api:msg_sc_visit_record(RecordList),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			TipPacket		  = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%%-------------------------------------------------------------------------------------------------
%% 每日引导
%%-------------------------------------------------------------------------------------------------
get_guide_info(Home) ->
	UserId			  = Home#ets_home.user_id,
	Today             = misc:date_num(),
	Message	  		  = Home#ets_home.message,
	Declare			  = Message#message.declare,
	GrabTimes	  	  = Declare#declare.grab_times,	
	GetWareTimes	  = case player_api:get_player_field(UserId, #player.position) of
							{?ok, #position_data{date = Data}} when Data == Today -> ?CONST_SYS_TRUE;
							_ -> 
								Declare#declare.get_reward_times
						end,
	Message	  		  = Home#ets_home.message,
	Girl			  = Home#ets_home.girl,
	GrabGirlTimes = case GrabTimes >= ?CONST_HOME_GRAB_MAX of
						?true  -> ?CONST_HOME_GRAB_MAX;
						?false -> GrabTimes
					end,
	PlantTimes		  = cal_has_plant_times(Home),
	LoosenTimes		  = Declare#declare.loosen_times,
	  
	PlayTimes	  	  = Girl#girl.play_times,
	PlayTimes1		  = case PlayTimes >= ?CONST_HOME_PLAY_TIMES of
							?true  -> ?CONST_HOME_PLAY_TIMES;
							?false -> PlayTimes
						end,
	home_api:msg_sc_guide_info(GetWareTimes, PlayTimes1, GrabGirlTimes, PlantTimes, LoosenTimes).

%% 获取土地种植次数
cal_has_plant_times(Home) ->
	Farm		 = Home#ets_home.farm,
	Plant		 = Farm#farm.plant,
	PlantList	 = misc:to_list(Plant),
	F = fun(PlantInfo, Acc) when is_record(PlantInfo, plant) ->
				Times		= PlantInfo#plant.times,
				Times + Acc;
		   (_, Acc) -> Acc
		end,
	lists:foldl(F, ?CONST_SYS_FALSE, PlantList).
%%-------------------------------------------------------------------------------------------------
%% 下线写数据库
%%-------------------------------------------------------------------------------------------------
logout(Player) ->
	UserId			  = Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home  when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			BattleList		= Girl#girl.battle_list,
			case BattleList of
				[] ->
					NewGirl			= Girl#girl{battle = 0, battle_list = []},
					NewHome			= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					home_db_mod:update_home(NewHome);
				_ ->
					List			= lists:delete(UserId, BattleList),
					List1			= lists:usort(List),
					update_battle_state(List1),
					NewGirl			= Girl#girl{battle = 0, battle_list = []},
					NewHome			= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					home_db_mod:update_home(NewHome)
			end;
		_ -> ?ok
	end.

update_battle_state([]) -> ?ok;
update_battle_state([UserId|Tail]) -> 
	home_mod_girl:update_user_battle_state1(UserId),
	update_battle_state(Tail).
%%-------------------------------------------------------------------------------------------------
%% 判断是否第二天刷新数据
%%-------------------------------------------------------------------------------------------------
refresh_home(Player) ->
	UserId		    = Player#player.user_id,
	NewDate			= misc:date_num(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			OfficeTask	  = Home#ets_home.task_info,
			OldDate		  = OfficeTask#task_info.date,
			case OldDate =:= NewDate of
				?false  ->
					NewHome			= refresh_home_times(Home),
					ets_api:insert(?CONST_ETS_HOME, NewHome);
				?true -> ?ok
			end;
		_ -> ?ok
	end.

%% 清除家园的次数 
refresh_home_times(Home) -> 
	NewDate		  = misc:date_num(),
	Farm		  = Home#ets_home.farm,
	PlantInfo	  = Farm#farm.plant,
	Num			  = erlang:length(misc:to_list(PlantInfo)),
	Farm1		  = clean_home_plant(Farm, ?CONST_SYS_TRUE, Num),
	NewFarm		  = Farm1#farm{refresh_times = ?CONST_SYS_FALSE, muck_times = ?CONST_SYS_FALSE, 
							   loosen_times = ?CONST_SYS_FALSE},
	Girl		  = Home#ets_home.girl,						%%清仕女抢夺和互动次数
	NewGirl		  = Girl#girl{grab_num = ?CONST_HOME_GRAB_MAX, play_times = ?CONST_SYS_FALSE,
							  play_exp = ?CONST_SYS_FALSE, rescue_times = ?CONST_SYS_FALSE},
	Message		  = Home#ets_home.message,
	Declare		  = Message#message.declare,
	NewDeclare	  = Declare#declare{get_reward_times = ?CONST_SYS_FALSE, 
									loosen_times = ?CONST_SYS_FALSE, 
									grab_times = ?CONST_SYS_FALSE,  
									play_girl_times = ?CONST_SYS_FALSE, 
									plant_times = ?CONST_SYS_FALSE,
									get_award_times = ?CONST_SYS_FALSE},
	NewMessage	  = Message#message{declare = NewDeclare},
	OfficeTask	  = Home#ets_home.task_info,
	NewTaskInfo   = OfficeTask#task_info{times = ?CONST_SYS_FALSE, date = NewDate},
	Home#ets_home{message = NewMessage, farm = NewFarm, girl = NewGirl, task_info = NewTaskInfo}.
%%-------------------------------------------------------------------------------------------------
%% 定时清除数据(0点更新)
%%-------------------------------------------------------------------------------------------------
clean_home_times() ->
	case ets:first(?CONST_ETS_HOME) of
		'$end_of_table' -> ?ok;
		Key	->
			clean_home_times_ext(Key),
			clean_home_times(Key)
	end.

clean_home_times(Key) ->
	case ets:next(?CONST_ETS_HOME, Key) of
		'$end_of_table' -> ?ok;
		Key1 ->
			clean_home_times_ext(Key1),
			clean_home_times(Key1)
	end.

clean_home_times_ext(Key) ->
	NewDate			= misc:date_num(),
	case ets_api:lookup(?CONST_ETS_HOME, Key) of
		Home when is_record(Home, ets_home) ->
			UserId		  = Home#ets_home.user_id,
			OfficeTask	  = Home#ets_home.task_info,
			OldDate		  = OfficeTask#task_info.date,
			case OldDate =:= NewDate of
				?false ->
					NewHome		  = refresh_home_times(Home),
					case player_api:check_online(UserId) of
						?true  ->
							Packet1	    = home_api:msg_sc_office_reward(?CONST_SYS_FALSE),
							misc_packet:send(UserId, Packet1);
						?false -> ?ok
					end,
					case NewHome =:= Home of
						?true  -> ?ok;
						?false -> 
							ets_api:insert(?CONST_ETS_HOME, NewHome)
					end;
				?true -> ?ok
			end;
		_ -> ?ok
	end.

%% 清除土地数据
clean_home_plant(Farm, Position, Num) when Position =< Num ->
	PlantInfo		= Farm#farm.plant,
	case erlang:element(Position, PlantInfo) of
		Plant1 when is_record(Plant1, plant) ->
			NewPlant		= Plant1#plant{times = ?CONST_SYS_FALSE, muck_list = [], loosen_list =[]},
			NewPlantInfo	= erlang:setelement(Position, PlantInfo, NewPlant),	
			NewFarm			= Farm#farm{plant = NewPlantInfo},
			clean_home_plant(NewFarm, Position + 1, Num);
		_ -> 
			clean_home_plant(Farm, Position + 1, Num)
	end;
clean_home_plant(Farm, _, _) ->
	Farm.
