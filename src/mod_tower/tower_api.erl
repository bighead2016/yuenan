%% Author: yskj
%% Created: 2012-9-13
%% Description: TODO: Add description to tower_api
-module(tower_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.tower.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/const.define.hrl").
-include("const.cost.hrl").
%%
%% Exported Functions
%%
-export([msg_open_tower/1,msg_sc_auto_rush/1,msg_sc_card/4,msg_sc_divine/1, login_packet/2,init_ets/0,
		 msg_sc_select_camp/6,msg_sc_start_rush/2,msg_sc_start_battle/3,msg_sc_sweep_ack/2,msg_sc_get_award/1,
		 msg_sc_speed/2, msg_sc_sweep_card/5, msg_sc_sweep_over/1, msg_sc_open_rush/5, msg_sc_vip_award/1,
		 msg_sc_boss_award/10, msg_sc_reset_times/1, login/1, refresh_attr/1, insert_past_list/3, logout/1,
		 check_pass_type/1, stop_all_sweep/0, msg_goods_info/4, msg_sc_report_list/2]).
-export([battle_over/2,do_battle_over/2,clean_tower_times/0, rank_top_score/1, get_top_pass/1, get_tower_times/1,
		 check_tower_pass_id/1, save_all/0]).
%%
%% API Functions
%%
%%初始化ets
init_ets() ->
	ets:delete_all_objects(?CONST_ETS_TOWER_PLAYER),
	FieldList = [id, player_id, top_score, reset_times, sweep_times, camp, sweep, top_time],
	case mysql_api:select(FieldList, game_tower_player) of
		{?ok, TowerList} ->
			F = fun([TowerId, PlayerId, TopScore, ResetTimes, SweepTimes, CampTemp, SweepTemp, TopTime]) ->
						Camp 		= misc:decode(CampTemp),
						Sweep		= misc:decode(SweepTemp),
						tower_mod_create:tower_data_to_record([TowerId, PlayerId, TopScore, ResetTimes, SweepTimes,
									Camp, Sweep, TopTime]) 
				end,
			List = [F(TowerTemp) || TowerTemp <- TowerList],
			ets_insert_list(List);
		{?error, _ErrorCode} ->
			?ok
	end,
    tower_mod_report:init_ets(),
    ?ok.

save_all() ->
    try
		%% 保存前先清空数据
		Sql1 = <<"delete from `game_tower_report`">>,
		mysql_api:select(Sql1),
		Sql2 = <<"delete from `game_tower_report_idx`">>,
		mysql_api:select(Sql2),
        TowerReport = ets:tab2list(?CONST_ETS_TOWER_REPORT),
        TowerIdx = ets:tab2list(?CONST_ETS_TOWER_REPORT_IDX),
        [tower_db_mod:save_all_report(T)||T <- TowerReport],    
        [tower_db_mod:save_all_report_idx(T2)||T2 <- TowerIdx]
    catch
        X:Y ->
            ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
    end.

%% 插入到ets
ets_insert_list([TowerInfo|RestList]) ->
	ets_api:insert(?CONST_ETS_TOWER_PLAYER, TowerInfo),
	ets_insert_list(RestList);
ets_insert_list([]) ->
	?ok.

%% 排行榜调用
rank_top_score(UserId) ->
	case tower_mod_create:get_tower_player(UserId) of
		TowerPlayer when is_record(TowerPlayer, ets_tower_player) ->
			TopScore	= TowerPlayer#ets_tower_player.top_score,
			TopTime		= TowerPlayer#ets_tower_player.top_time,
			{TopScore, TopTime};
		_ -> {?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
	end.

%% 招贤馆调用
get_top_pass(UserId) ->
	tower_mod:get_top_pass(UserId).

%% 重置剩余次数
get_tower_times(Player) ->
	tower_mod:get_tower_times(Player).

%% 定点清理数据 tower_api:clean_tower_times().
clean_tower_times() ->
	try
		tower_mod:clean_tower_times()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.

%% 通关增加属性
refresh_attr(Tower) ->
	tower_mod:refresh_attr(Tower).

%% 关服调用
stop_all_sweep() ->
	tower_mod:stop_all_sweep().

%% 上线请求扫荡返回
login_packet(Player, Packet) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
    		{?ok, NewPlayer, Packet2} = tower_mod:get_offline_sweep_data(Player),
    		{NewPlayer, <<Packet/binary, Packet2/binary>>};
		?false ->
			{Player, Packet}
	end.

%% 下线存入数据库
logout(Player) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true  -> tower_mod:logout(Player);
		?false -> ?ok
	end.

%% 上线处理扫荡次数
login(Player) ->
	case player_sys_api:is_open_sys(Player, ?CONST_MODULE_TOWER) of
		?true ->
			tower_mod:refresh_tower_times(Player);
		?false -> ?ok
	end.

%% 战斗处理
battle_over(Result, {UserId, MonsterId, Bout, Atk, Def, Report, CampId}) ->
    case player_api:get_player_pid(UserId) of
        Pid when is_pid(Pid) ->
			player_api:process_send(Pid, ?MODULE, do_battle_over, [Result, MonsterId, Bout, Atk, Def, CampId, Report]);
        _ ->
            ?ok
    end.

%% 判断大阵
get_camp_id(CampId) ->
	case CampId =:= ?CONST_TOWER_CAMP_COUNT of
		?true  -> ?CONST_TOWER_CAMP_COUNT;
		?false -> CampId + 1
	end.

do_battle_over(#player{user_id = UserId, info = Info} = Player, [?CONST_BATTLE_RESULT_LEFT, _MonsterId, Bout, Atk, Def, CampIdX, Report])->              %% 闯塔成功
    % 战报
    TopCampId = get_top_pass(UserId),
    if
        TopCampId < CampIdX ->
            tower_mod_report:insert_report(UserId, Info, CampIdX, Report);
        ?true ->
            ?ok
    end,

    % 正常流程
	Now			= misc:seconds(),
	PassId 		= Player#player.tower_passid,
    check_activity_tower_welfare(UserId,CampIdX),                            %运营活动破阵奖励
	case data_tower:get_towerpass(PassId) of
		Pass when is_record(Pass, rec_tower_pass) ->
			case tower_mod_create:get_tower_player(UserId) of
				Tower when is_record(Tower, ets_tower_player) ->
					CampId		= Pass#rec_tower_pass.camp,
					CampList	= Tower#ets_tower_player.camp,
					Camp		= erlang:element(CampId, CampList),
					PastList	= Camp#towercamp.past_list,
					NewPastList = insert_past_list(CampId, PassId, PastList),        			%% 此大阵通过的关卡列表
					NewCampList	= erlang:setelement(CampId, CampList, 
									Camp#towercamp{top_pass = PassId, reset_pass = PassId, past_list = NewPastList}), %% 更新过关信息
					NewCampId	= get_camp_id(CampId),
					?MSG_DEBUG("NewCampId=~p, NewCampList =~p", [NewCampId, NewCampList]),
					NewCampList1= add_new_camp(NewCampId, NewCampList),
					{NewPlayer, NewCampList2} = case {PassId =:= Camp#towercamp.max_pass, erlang:element(NewCampId, NewCampList1)} of
													{?true, []} ->   							%% 已经打完一个大阵,开启了下一个大阵
														get_camp_info(Player, Pass, CampId, NewCampList1);
													{?true, _} ->						        %% 已经打到最后一个大阵
														get_camp_info1(Player, Pass, CampId, NewCampList1);
													{?false, _} ->   							%% 继续这一大阵的其它关卡
														Player1		= get_camp_info2(Player, Pass, CampId, NewCampList1),
														{Player1, NewCampList1}
												end,
					NewTower 		= Tower#ets_tower_player{camp = NewCampList2},
					NewTower2		= case PassId > NewTower#ets_tower_player.top_score of       %% 更新最高记录
										  ?true ->
											  NewTower1		= NewTower#ets_tower_player{top_score = PassId, top_time = Now},
											  tower_db_mod:update_top_score(Player, NewTower1),
											  NewTower1;
										  ?false ->
											  NewTower
									  end,
					ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower2),
					NewPlayer1			= add_tower_buff(NewPlayer, NewTower),
					get_tower_pass(Player, Bout, PassId, CampId),								
					{?ok, NewPlayer2}	= schedule_api:add_guide_times(NewPlayer1, ?CONST_SCHEDULE_GUIDE_TOWER),         %% 每天任务
					{?ok, NewPlayer3}   = get_battle_award(NewPlayer2, Pass, NewCampList2, Atk, Def),
                    catch gun_award_api:check_active(Player#player.user_id, ?CONST_SCHEDULE_RESOURCE_TOWER),
					NewPlayer4			= task_api:finish_tower(NewPlayer3, PassId),
					%% 新服成就
					{?ok, NewPlayer5}      = new_serv_api:finish_achieve(NewPlayer4, ?CONST_NEW_SERV_TOWER, PassId, 1),
					{?ok, NewPlayer5};
				_ ->{?ok, Player}
			end;
		_ -> {?ok, Player}
	end;
do_battle_over(Player, [?CONST_BATTLE_RESULT_RIGHT, _MonsterId, _Bout, _Atk, _Def, _, _])->           				%% 闯塔失败
	{?ok, Player};
do_battle_over(Player, [?CONST_BATTLE_RESULT_DRAW, _MonsterId, _Bout, _Atk, _Def, _, _])->
	{?ok, Player}.

%% 插入打过的大阵信息
insert_past_list(CampId, PassId, PastList) ->
	Num			 = erlang:length(PastList),
	case Num =:= ?CONST_SYS_FALSE of
		?true  ->  [{CampId, PassId}| PastList];
		?false ->   
			{_, InitId}		= lists:nth(Num, PastList),
			List1			= [{CampId, PassId1} || PassId1 <- lists:seq(InitId, PassId)],
			lists:reverse(List1)
	end.

%% 获取大阵信息
get_camp_info(Player, Pass, CampId, CampList) ->     %% 已经打完一个大阵,开启了下一个大阵
	PlayerId	 = Player#player.user_id,
	PlayerName	 = (Player#player.info)#info.user_name,
	Camp		 = erlang:element(CampId, CampList),
	AwardFlag	 = Camp#towercamp.is_award,
	IsAward		 = case AwardFlag of
					   ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE;
					   _ -> Camp#towercamp.is_award
				   end,
	CampListNew  =	erlang:setelement(CampId, CampList, Camp#towercamp{is_award = IsAward}),  
	achievement_api:add_achievement(PlayerId, ?CONST_ACHIEVEMENT_TOWER_CLEARANCE, CampId, 1),
	%% achievement_api:add_achievement(PlayerId, ?CONST_ACHIEVEMENT_FIRST_TOWER_CLEARANCE, 0, 1),
	%% 荣誉榜：第一个在破阵中通关七月流火阵的玩家
	{?ok, Player2} =  if CampId >= 4 ->
		   new_serv_api:add_honor_title(Player, ?CONST_NEW_SERV_FIRST_TOWER_CLEARANCE, ?CONST_ACHIEVEMENT_FIRST_TOWER_CLEARANCE);
	   ?true ->
		   {?ok, Player}
	end,
	PartnerId	 = Pass#rec_tower_pass.partner_id,                      %% 破阵招募名将
	case AwardFlag of
		?CONST_SYS_FALSE ->
			case CampId >= 4 of						%% 第4大阵以上全服公告
				?true ->
					BroadPacket		= message_api:msg_notice(?TIP_TOWER_BROADCAST1, [{PlayerId, PlayerName}], [], 
															 [{?TIP_SYS_TOWER, misc:to_list(CampId)}]),
					misc_app:broadcast_world(BroadPacket);
				?false ->
					BroadcastPacket = message_api:msg_notice(?TIP_TOWER_BROADCAST, [{PlayerId, PlayerName}], [], 
															 [{?TIP_SYS_TOWER, misc:to_list(CampId)}]),
					misc_app:broadcast_world(BroadcastPacket)
			end;
		_ -> ?ok
	end,
	NewPlayer	 = case PartnerId =/=  ?CONST_SYS_FALSE of
					   ?true ->
						   case AwardFlag of
							   ?CONST_SYS_FALSE -> 
								   partner_mod:add_look_new_list(Player2, [PartnerId]);
							   _ -> Player2
						   end;
					   ?false ->
						   Player2
				   end,
	CampListNew2 = tower_mod_create:create_towercamp_init(CampId + 1, CampListNew),
	{NewPlayer, CampListNew2}.
%% 获取大阵信息
get_camp_info1(Player, Pass, CampId, CampList) ->
	PlayerId	 = Player#player.user_id,
	PlayerName	 = (Player#player.info)#info.user_name,
	Camp		 = erlang:element(CampId, CampList),
	AwardFlag	 = Camp#towercamp.is_award,
	IsAward		 = case AwardFlag of
					   ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE;
					   _ -> Camp#towercamp.is_award
				   end,
	NewCampList  = erlang:setelement(CampId, CampList, Camp#towercamp{is_award = IsAward}), 
	PartnerId	 = Pass#rec_tower_pass.partner_id,                      %% 破阵招募名将
	case AwardFlag of
		?CONST_SYS_FALSE ->
			case CampId >= 4 of						%% 第4大阵以上全服公告
				?true ->
					BroadPacket		= message_api:msg_notice(?TIP_TOWER_BROADCAST1, [{PlayerId, PlayerName}], [], 
															 [{?TIP_SYS_TOWER, misc:to_list(CampId)}]),
					misc_app:broadcast_world(BroadPacket);
				?false ->
					BroadcastPacket = message_api:msg_notice(?TIP_TOWER_BROADCAST, [{PlayerId, PlayerName}], [], 
															 [{?TIP_SYS_TOWER, misc:to_list(CampId)}]),
					misc_app:broadcast_world(BroadcastPacket)
			end;
		_ -> ?ok
	end,
	NewPlayer	 = case PartnerId =/=  ?CONST_SYS_FALSE of
					   ?true ->
						   case AwardFlag of
							   ?CONST_SYS_FALSE -> 
								   partner_mod:add_look_new_list(Player, [PartnerId]);
							   _ -> Player
						   end;
					   ?false ->
						   Player
				   end,
	{NewPlayer, NewCampList}.

get_camp_info2(Player, Pass,  CampId, CampList) ->
	PartnerId	 = Pass#rec_tower_pass.partner_id,                      %% 破阵招募名将
	Camp		 = erlang:element(CampId, CampList),
	AwardFlag	 = Camp#towercamp.is_award,
	case PartnerId =/=  ?CONST_SYS_FALSE of
		?true ->
			case AwardFlag of
				?CONST_SYS_FALSE -> 
					partner_mod:add_look_new_list(Player, [PartnerId]);
				_ -> Player
			end;
		?false ->
			Player
	end.

add_new_camp(CampId, CampInfo) when CampId < ?CONST_TOWER_CAMP_COUNT ->
	CampList		= misc:to_list(CampInfo),
	CampNum			= erlang:length(CampList),
	?MSG_DEBUG("CampList=~p", [CampList]),
	case CampId > CampNum of
		?true ->
			case ?CONST_TOWER_CAMP_COUNT - CampNum of
				Num when Num > ?CONST_SYS_FALSE ->
					List			= misc:to_list(erlang:make_tuple(Num, [])),
					NewCampList		= CampList ++ List,
					?MSG_DEBUG("NewCampList=~p", [misc:to_tuple(NewCampList)]),
					misc:to_tuple(NewCampList);
				_ -> 
					?MSG_DEBUG("CampInfo=~p", [CampInfo]),
					CampInfo
			end;
		?false ->
			CampInfo
	end;
add_new_camp(_, CampInfo) -> CampInfo.

%% 通过boss关卡增加永久属性
add_tower_buff(Player, Tower) when is_record(Player, player) andalso is_record(Tower, ets_tower_player) ->
	PassId			= Player#player.tower_passid,
	BuffList		= Player#player.tower,
	TopPass			= Tower#ets_tower_player.top_score,
	case PassId > TopPass of
		?true ->
			case data_tower:get_towerpass(PassId) of
				Pass when is_record(Pass, rec_tower_pass) ->
					List		= Pass#rec_tower_pass.buff,
					case List == [] of
						?true  -> Player;
						?false ->
							NewList		= misc:list_merge(List, BuffList),
							Player1		= Player#player{tower = NewList},
							player_attr_api:refresh_attr_tower(Player1)
					end;
				_ -> Player
			end;
		?false -> Player
	end;
add_tower_buff(Player, _) -> Player.
	
%% 处理首杀和最佳通关
get_tower_pass(Player, Bout, PassId, CampId) ->
	PlayerId		= Player#player.user_id,
	PlayerName		= (Player#player.info)#info.user_name,
	case tower_mod_create:get_tower_pass(PassId) of
		?null ->					 												%% 首杀记录
			NewTowerPass = #ets_tower_pass{id = PassId, first_id = PlayerId, first_name = PlayerName, best_pass = PlayerName,
										   best_passid = PlayerId, best_score = Bout},
			ets_api:insert(?CONST_ETS_TOWER_PASS, NewTowerPass),
			tower_db_mod:insert_tower_pass(NewTowerPass, CampId);
		TowerPass ->
			case Bout < TowerPass#ets_tower_pass.best_score of
				?true ->          													%% 更新最佳通关
					NewTowerPass = TowerPass#ets_tower_pass{best_pass = PlayerName, best_passid = PlayerId, best_score = Bout},
					ets_api:insert(?CONST_ETS_TOWER_PASS, NewTowerPass),
					tower_db_mod:update_tower_pass(NewTowerPass);
				?false ->
					?ok
			end
	end.

%% 根据关卡类型获取奖励
get_battle_award(Player, Pass,  CampInfo, Atk, Def) ->
	PassId 		 = Player#player.tower_passid,
	CampId		 = Pass#rec_tower_pass.camp,
	RewardId	 = Pass#rec_tower_pass.award,                 					%% 掉落奖励  
	GoodList	 = goods_api:goods_drop(RewardId),
	Exp			 = Pass#rec_tower_pass.exp,
	Gold		 = Pass#rec_tower_pass.gold,
	Camp		 = erlang:element(CampId, CampInfo),
	F  = fun(Good) when is_record(Good, goods) ->
				 {Good#goods.goods_id, Good#goods.count}
		 end,
	RewardList   = [F(Good) || Good <- GoodList],
	StandardTime = Pass#rec_tower_pass.standard_time,
	StartTime	 = Camp#towercamp.start_time,
	Now			 = misc:seconds(),
	TimePass	 = Now - StartTime,
	Evaluate     = copy_single_api:get_eq(TimePass, StandardTime, Atk, Def),
	TipPacket	 = msg_goods_info(Player, CampId, PassId, GoodList),
	case check_pass_type(PassId) of
		?true ->
			Packet		 = msg_sc_boss_award(PassId, ?CONST_SYS_FALSE, RewardList, Evaluate, Exp, Gold, 
											 ?CONST_SYS_FALSE, Atk, Def, TimePass),
			misc_app:broadcast_world(TipPacket),
			misc_packet:send(Player#player.net_pid, Packet),
			tower_mod:get_award(Player, Exp, Gold, GoodList, ?CONST_COST_TOWER_LV_REWARD, PassId);
		?false ->
%% 			misc_app:broadcast_world(TipPacket),
			{?ok, Player}
	end.

%% 判断是否为boss关卡(类型为2)
check_pass_type(PassId) ->
	case data_tower:get_towerpass(PassId) of
		TowerPass when is_record(TowerPass, rec_tower_pass) ->
			TowerPass#rec_tower_pass.type =:= ?CONST_TOWER_BIG_MONSTER;
		_ -> ?false
	end.

%% 战斗获得橙色物品提示
msg_goods_info(Player, CampId, PassId, GoodsList) ->
	UserId	  = Player#player.user_id,
	UserName  = (Player#player.info)#info.user_name,
	PassId1	  = check_tower_pass_id(PassId),
	Goods 	  = [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	case Goods of
		[] -> <<>>;
		_  ->
			List	  = [{?TIP_SYS_TOWER, misc:to_list(CampId)}, {?TIP_SYS_TOWER1, misc:to_list(PassId1)}],
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_TOWER_NOTICE_GOODS_EQUIP, [{UserId, UserName}],
																[GoodsInfo], List),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_TOWER_NOTICE_GOODS, [{UserId, UserName}],[GoodsInfo],
																  List),
								<<Packet/binary, Acc/binary>>
						end
				end,
			lists:foldl(F, <<>>, Goods)
	end.

%% 判断是第几小关
check_tower_pass_id(PassId) ->
	case PassId rem ?CONST_SYS_NUMBER_TEN of
		?CONST_SYS_FALSE -> ?CONST_SYS_NUMBER_TEN;
		Rem -> Rem
	end.

%%运营活动破阵奖励检测
check_activity_tower_welfare(PlayerId,CampIdX)->
	try 
		case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {PlayerId,5}) of
			{_,_,Data,_,_} ->
				case CampIdX >Data of
					true->
						yunying_activity_mod:update_activity_info(PlayerId,5,{Data,CampIdX});
					false ->
						nil
				end;
			_ ->
				TopCampId = get_top_pass(PlayerId),
				case CampIdX>TopCampId  of
					true->
						yunying_activity_mod:update_activity_info(PlayerId,5,{TopCampId,CampIdX});
					false ->
						nil
				end
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

     
%%
%% API Functions
%%
%% 打开闯塔
msg_open_tower(TopScore) ->
	misc_packet:pack(?MSG_ID_TOWER_OPEN_TOWER, ?MSG_FORMAT_TOWER_OPEN_TOWER, [TopScore]).
%% 选择大阵
%%[{Id,Type},MaxPass,AllMaxPass,Award]
msg_sc_select_camp(List1, MaxPass, AllMaxPass, Award, ResetTimes, LigthId) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_SELECT_CAMP, ?MSG_FORMAT_TOWER_SC_SELECT_CAMP, [List1,MaxPass,AllMaxPass,Award, ResetTimes, LigthId]).
%% 进入关卡
%%[PassId,MonsterId]
msg_sc_start_rush(PassId,MonsterId) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_START_RUSH, ?MSG_FORMAT_TOWER_SC_START_RUSH, [PassId, MonsterId]).
%% 占卜
%%[Id]
msg_sc_divine(Id) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_DIVINE, ?MSG_FORMAT_TOWER_SC_DIVINE, [Id]).
%% 闯塔扫荡
%%[Result]
msg_sc_auto_rush(IdList) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_AUTO_RUSH, ?MSG_FORMAT_TOWER_SC_AUTO_RUSH, [IdList]).
%% 选择关卡
%%[FirstName,FirstId,BestName,BestId]
msg_sc_card(FirstName,FirstId,BestName,BestId) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_CARD, ?MSG_FORMAT_TOWER_SC_CARD, [FirstName,FirstId,BestName,BestId]).
%% 领取大阵奖励
msg_sc_get_award(Result) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_AWARD, ?MSG_FORMAT_TOWER_SC_AWARD, [Result]).
%% 关卡奖励返回
%%[{GoodId,GoodNum}]
msg_sc_start_battle(GoodsList, Exp, Gold) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_START_BATTLE, ?MSG_FORMAT_TOWER_SC_START_BATTLE, [GoodsList, Exp, Gold]).
%% 加速成功返回
msg_sc_speed(EndTime, IdList) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_SPEED_TYPE, ?MSG_FORMAT_TOWER_SC_SPEED_TYPE, [EndTime, IdList]).
%% 扫荡结束确认返回
msg_sc_sweep_ack(Result, LeftTime) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_RUSH_OVER, ?MSG_FORMAT_TOWER_SC_RUSH_OVER, [Result, LeftTime]).
%% 扫荡每个关卡返回
msg_sc_sweep_card({CurrentId}, {NextId}, Exp, Gold, GoodsList) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_WIPE_CARD, ?MSG_FORMAT_TOWER_SC_WIPE_CARD, [CurrentId, NextId, Exp, Gold, GoodsList]).
%% 终止扫荡
msg_sc_sweep_over(Result) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_STOP_RUSH, ?MSG_FORMAT_TOWER_SC_STOP_RUSH, [Result]).
%% 上线后打开扫荡
msg_sc_open_rush(Result, InitId, LeftTime, TopScore, IdList) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_OPEN_RUSH, ?MSG_FORMAT_TOWER_SC_OPEN_RUSH, [Result, InitId, LeftTime, TopScore, IdList]).
%% VIP翻牌奖励
msg_sc_vip_award(RewardList) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_VIP_AWARD, ?MSG_FORMAT_TOWER_SC_VIP_AWARD, [RewardList]).
%% boss翻牌奖励
msg_sc_boss_award(PassId, Flag, RewardList, Evaluate, Exp, Gold, PlotId, AtkPoint, DefPoint, Time) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_BOSS_AWARD, ?MSG_FORMAT_TOWER_SC_BOSS_AWARD, 
					 [PassId, Flag, RewardList, Evaluate, Exp, Gold, PlotId, AtkPoint, DefPoint, Time]).
%%重置次数返回
msg_sc_reset_times(Times) ->
	misc_packet:pack(?MSG_ID_TOWER_SC_RESET_TIMES, ?MSG_FORMAT_TOWER_SC_RESET_TIMES, [Times]).
%% 战报列表
%%[PassId,{UserId,UserName,ReportId}]
msg_sc_report_list(PassId,List1) ->
    misc_packet:pack(?MSG_ID_TOWER_SC_REPORT_LIST, ?MSG_FORMAT_TOWER_SC_REPORT_LIST, [PassId,List1]).