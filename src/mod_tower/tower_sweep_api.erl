%% Author: Administrator
%% Created: 2012-10-16
%% Description: TODO: Add description to tower_sweep_api
-module(tower_sweep_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.tower.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([start_sweep/2, update_sweep/0, update_sweep_cb/2, update_sweep_cb1/2, flush_offline/2, get_sweep_list/2, flush_offline_cb/2]).
-export([get_reward/6, get_reward_info/2, stop_swep/1]).
-export([get_current_camp/1, get_goods_info/2]).

%%
%% API Functions
%%
%% 开始扫荡
start_sweep(Player, Id) ->
	SweepList   	= get_sweep_list(Player, Id),
	SweepNum		= erlang:length(SweepList),
	Now				= misc:seconds(),
	PlayerId 		= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		TowerPlayer when is_record(TowerPlayer, ets_tower_player) ->
			TowerPass		= data_tower:get_towerpass(Id),                              %% 读表获取每关扫荡的间隔时间
			IntervalTime	= TowerPass#rec_tower_pass.pass_time,
			EndTime			= Now + SweepNum * IntervalTime * ?CONST_SYS_NUMBER_SIXTY,
			TowerSweep		= TowerPlayer#ets_tower_player.sweep,
			NewCurrentEnd   = Now + IntervalTime * ?CONST_SYS_NUMBER_SIXTY,  			  %% 当前关卡的截止时间
			if
				SweepNum =:= ?CONST_SYS_FALSE ->    %% 不能扫荡
					Packet 		= tower_api:msg_sc_auto_rush([]),
					misc_packet:send(Player#player.net_pid, Packet);
				?true ->             %% 可以扫荡
					achievement_api:add_achievement(PlayerId, ?CONST_ACHIEVEMENT_CLEARANCE, 0, 1),
					NewSweepList= lists:reverse(SweepList),
					CurrentId   = lists:nth(1, NewSweepList),
					Sweep	    = TowerSweep#towersweep{id = Id, player_id = PlayerId, current_id = CurrentId, current_end = NewCurrentEnd,
														begin_time = Now, end_time = EndTime, sweep_list = NewSweepList, interval_time = IntervalTime},
					SweepTimes	= TowerPlayer#ets_tower_player.sweep_times + 1,
					TowerRecord	= TowerPlayer#ets_tower_player{player_id = PlayerId, sweep = Sweep, sweep_times = SweepTimes},
					ets_api:insert(?CONST_ETS_TOWER_PLAYER, TowerRecord),
					tower_db_mod:start_sweep(Player, TowerRecord),
					Packet 		= tower_api:msg_sc_auto_rush(NewSweepList),
					Packet1 	= tower_api:msg_sc_sweep_card({0}, CurrentId, 0, 0, []),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>)
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获取扫荡列表
get_sweep_list(Player, Id) ->
	LevelId		= get_current_camp(misc:to_list(Id)),
	PlayerId 	= Player#player.user_id,
	case tower_mod_create:get_tower_player(PlayerId) of
		TowerPlayer when is_record(TowerPlayer, ets_tower_player) ->
			Top			= TowerPlayer#ets_tower_player.top_score, 
			TopScore	= misc:to_list(Top),   							     %% 最高关卡
			Level		= get_current_camp(TopScore),                        %% 获取最高关卡所在的大阵
			CampTuple	= TowerPlayer#ets_tower_player.camp,
			CampList	= misc:to_list(CampTuple),
			F = fun(Camp, Past) when Camp#towercamp.id >= LevelId ->          %% 计算从选择开始的大阵需要扫荡的关卡
						TempPast 	= Camp#towercamp.past_list,
						TempPast ++ Past;
				   (_Camp, Past) ->
						Past
				end,
			PastList    = lists:foldl(F, [], CampList),
			?MSG_PRINT("TopScore=~p, LevelId=~p Id =~p, PastList=~p", [TopScore, LevelId, Id, PastList]),
			if
				Level=:= ?CONST_SYS_TRUE andalso LevelId =:= ?CONST_SYS_TRUE-> %% 同在第一层
					case lists:keyfind(LevelId, 1, PastList) of
						{_Id1, _} ->
							{PastId}		= calc_top_past(LevelId, PastList, []),
							calc_sweep_list(PastId, Top);
						?false ->
							calc_sweep_list(Id-1, Top)
					end;
				?true ->
					if
						LevelId =:= Level ->                                 %% 在2-5的同一层
							case lists:keyfind(LevelId, 1, PastList) of
								{LevelId, _} ->
									{PastId}		= calc_top_past(LevelId, PastList, []),
									calc_sweep_list(PastId, Top);
								?false ->
									calc_sweep_list(Id-1, Top)
							end;
						LevelId < Level ->
							CampList1	= delete_camp_info(?CONST_SYS_TRUE, LevelId, CampList),
							cal_sweep_list1(Level, Top, CampList1);
						?true ->  %% 选择的大阵关卡超过了记录关卡
							[]
					end
			end;
		_ -> []
	end.

delete_camp_info(Id1, Id2, CampList) when Id1 < Id2 ->
	CampList1 = lists:keydelete(Id1, #towercamp.id, CampList),
	delete_camp_info(Id1 + 1, Id2 , CampList1);
delete_camp_info(_, _, CampList) -> CampList.
	

%% 计算选择关卡和最高关卡在同一层的扫荡列表
calc_sweep_list(PastId, TopScore) ->
	get_sweep_list1(PastId, TopScore, []).

get_sweep_list1(PastId, TopScore, Acc) when PastId < TopScore ->
	SweepId 	 = PastId + 1,
	NewSweepList = [{SweepId} |Acc],
	get_sweep_list1(SweepId, TopScore, NewSweepList);
get_sweep_list1(_, _, Acc) ->
	?MSG_DEBUG("Acc=~p", [Acc]),
	Acc.
%% 	lists:reverse(Acc).

%% 计算本大阵通过的最高关卡
calc_top_past(Level, [{Level1, _PastId}|RestList], Acc) when Level =/= Level1 -> 
	NewAcc		= Acc,
	calc_top_past(Level, RestList, NewAcc);
calc_top_past(Level, [{Level, PastId}|RestList], Acc) ->
	NewAcc		= [{PastId}|Acc],
	calc_top_past(Level, RestList, NewAcc);
calc_top_past(_, [], Acc) ->
	?MSG_DEBUG("Acc=~p", [Acc]),
	Num		= erlang:length(Acc),
	lists:nth(Num, Acc).

%% 计算选择关卡和最高关卡不在同一层的扫荡列表
cal_sweep_list1(Level, TopScore, CampList) ->
	Fun	= fun(Camp, Sum)  when is_record(Camp, towercamp) andalso Camp#towercamp.id < Level ->
				  PastList		= Camp#towercamp.past_list,
				  SweepList     = case lists:keyfind(Camp#towercamp.id, 1, PastList) of
									  {LevelId1, _} ->
										 {PastId}		= calc_top_past(LevelId1, PastList, []),
										 ?MSG_DEBUG("PastId=~p, Max=~p", [PastId, Camp#towercamp.max_pass]),
										  calc_sweep_list(PastId, Camp#towercamp.max_pass);
									  ?false ->
										  PassList      = Camp#towercamp.pass,
										  PassRecord    = lists:nth(1, PassList),
										  InitId		= PassRecord#pass.id,
										  ?MSG_PRINT("InitId=~p,MaxPass=~p", [InitId,Camp#towercamp.max_pass]),
										  calc_sweep_list(InitId-1, Camp#towercamp.max_pass)
								  end,
				  SweepList ++ Sum;
			 (Camp, Sum)  when is_record(Camp, towercamp) andalso Camp#towercamp.id =:= Level ->
				  PastList		= Camp#towercamp.past_list,
				  SweepList		= case lists:keyfind(Camp#towercamp.id, 1, PastList) of
									  {LevelId1, _} ->
 										  {PastId}		= calc_top_past(LevelId1, PastList, []),
										  ?MSG_DEBUG("PastId=~p", [PastId]),
										  calc_sweep_list(PastId, TopScore);
									  ?false ->
										  PassList 		= Camp#towercamp.pass,
										  PassRecord    = lists:nth(1, PassList),
										  InitId		= PassRecord#pass.id,
										  ?MSG_PRINT("InitId=~p,MaxPass=~p", [InitId,Camp#towercamp.max_pass]),
										  calc_sweep_list(InitId-1, TopScore)
								  end,
				  SweepList ++ Sum;
			 (_Camp, Sum) ->
				  Sum 
		  end,	
	lists:foldl(Fun, [], CampList).


%% 定时调用 
update_sweep() ->
	TowerPlayerList = ets_api:list(?CONST_ETS_TOWER_PLAYER),
	Now = misc:seconds(),
	F = fun(TowerPlayer = #ets_tower_player{sweep = #towersweep{begin_time = BeginTime, interval_time = IntervalTime, current_end = CurrentEnd}})
			 when is_record(TowerPlayer, ets_tower_player) ->
				case BeginTime =:= ?CONST_SYS_FALSE of
					?true -> ?ok;
					?false ->
						EndTime		  = BeginTime + IntervalTime * ?CONST_SYS_NUMBER_SIXTY,
						case EndTime - Now =< ?CONST_SYS_FALSE of
							?true ->
								TowerSweep	  =  TowerPlayer#ets_tower_player.sweep,
								CurrentId	  =  TowerSweep#towersweep.current_id,
								SweepList	  =  TowerSweep#towersweep.sweep_list,	
								NewSweepList  = lists:delete(CurrentId, SweepList),
								case erlang:length(NewSweepList) =:= ?CONST_SYS_FALSE of
									?true ->
										handler_sweep1(TowerPlayer);
									?false ->
										handler_sweep2(TowerPlayer, CurrentEnd)
								end;
							?false -> ?ok
						end
				end;
		   (_X) -> ?ok
		end,
	lists:foreach(F, TowerPlayerList).

%%　定时扫荡的最后一关
handler_sweep1(TowerPlayer) ->
	CampTuple	  =	 TowerPlayer#ets_tower_player.camp,
	UserId		  =  TowerPlayer#ets_tower_player.player_id,
	TowerSweep	  =  TowerPlayer#ets_tower_player.sweep,
	InitId		  =	 TowerSweep#towersweep.id,
	CurrentId	  =  TowerSweep#towersweep.current_id,
	{PassId}      =  CurrentId,
	TopPass		  =  misc:to_list(PassId),
	CampId		  =  get_current_camp(TopPass),		
	?MSG_DEBUG("CampId=~p, PassId=~p CurrentId=~p", [CampId, PassId, CurrentId]),
	Pass		  = data_tower:get_towerpass(PassId),
	RewardId	  = Pass#rec_tower_pass.award,                %%掉落奖励
	GoodList	  = goods_api:goods_drop(RewardId),
	Exp			  = Pass#rec_tower_pass.exp,
	Gold		  = Pass#rec_tower_pass.gold,
	PassId		  = Pass#rec_tower_pass.pass_id,
	case player_api:process_send(UserId, ?MODULE, update_sweep_cb, [GoodList, Exp, Gold, PassId]) of
		?true  -> ?ok;
		?false ->
			Data	= [CurrentId],
			tower_db_mod:insert_offline_date(UserId, ?MODULE, Data, InitId)
	end,
	NewCamp1	 	= erlang:element(CampId, CampTuple),
	TopPass1 	    = NewCamp1#towercamp.reset_pass,
	PastList1		= NewCamp1#towercamp.past_list,
	?MSG_DEBUG("TopPass1=~p, PastList1=~p", [TopPass1, PastList1]),
	NewPastList1	= tower_api:insert_past_list(CampId, PassId, PastList1),
	NewCampInfo1	= NewCamp1#towercamp{top_pass = PassId, past_list = NewPastList1},
	CampListNew1	= erlang:setelement(CampId, CampTuple, NewCampInfo1),			 
	TowerRecord1    = TowerPlayer#ets_tower_player{player_id = UserId, camp = CampListNew1,sweep =#towersweep{player_id = UserId, 
									current_end = 0, current_id = 0, sweep_list = [], end_time = 0,interval_time = 0, begin_time = 0}},	
	?MSG_PRINT("TowerRecord=~p", [TowerRecord1]),
	ets_api:insert(?CONST_ETS_TOWER_PLAYER, TowerRecord1),
	tower_db_mod:end_sweep(UserId, TowerRecord1),
	NewGoodsList  	= get_goods_info(GoodList, []),
	Packet 		  	= tower_api:msg_sc_sweep_card(CurrentId, {0}, Exp, Gold, NewGoodsList),
	Packet1 	  	= tower_api:msg_sc_sweep_over(?CONST_SYS_TRUE),
	misc_packet:send(UserId, <<Packet/binary, Packet1/binary>>).
%%　定时扫荡的处理
handler_sweep2(TowerPlayer, CurrentEnd) ->
	Now			  	=  misc:seconds(),
	CampTuple	    =  TowerPlayer#ets_tower_player.camp,
	UserId		    =  TowerPlayer#ets_tower_player.player_id,
	TowerSweep	    =  TowerPlayer#ets_tower_player.sweep,
	InitId		    =  TowerSweep#towersweep.id,
	CurrentId	    =  TowerSweep#towersweep.current_id,
	SweepList	    =  TowerSweep#towersweep.sweep_list,
	IntervalTime    =  TowerSweep#towersweep.interval_time,
                    
	EndTime		    =  TowerSweep#towersweep.end_time,
	{PassId}        =  CurrentId,
	TopPass		    =  misc:to_list(PassId),
	CampId		    =  get_current_camp(TopPass),			                        
	?MSG_DEBUG("CampId=~p, PassId=~p CurrentId=~p", [CampId, PassId, CurrentId]),
	Pass		    = data_tower:get_towerpass(PassId),
                    
	RewardId	    = Pass#rec_tower_pass.award,                %%掉落Id
	Exp			    = Pass#rec_tower_pass.exp,
	Gold		    = Pass#rec_tower_pass.gold,
	NewSweepList    = lists:delete(CurrentId, SweepList),
	case erlang:length(NewSweepList) > ?CONST_SYS_FALSE of
		?true ->
			NewCurrentId    = lists:nth(?CONST_SYS_TRUE, NewSweepList),
			NewCurrentEnd   = CurrentEnd + IntervalTime * ?CONST_SYS_NUMBER_SIXTY,
			NewCamp2	 	= erlang:element(CampId, CampTuple),
			PastList2		= NewCamp2#towercamp.past_list,
			NewPastList2	= tower_api:insert_past_list(CampId, PassId, PastList2),
			NewCampInfo2	= NewCamp2#towercamp{top_pass = PassId, past_list = NewPastList2},
			CampListNew2	= erlang:setelement(CampId, CampTuple, NewCampInfo2),			 
			TowerRecord2 	= TowerPlayer#ets_tower_player{player_id = UserId, camp = CampListNew2,
								sweep =#towersweep{id = InitId, begin_time = Now, player_id = UserId, current_end = NewCurrentEnd, 
												   current_id = NewCurrentId, sweep_list = NewSweepList, interval_time = IntervalTime, 
												   end_time = EndTime}},	
			ets_api:insert(?CONST_ETS_TOWER_PLAYER, TowerRecord2),
			case player_api:process_send(UserId, ?MODULE, update_sweep_cb1, [RewardId, Exp, Gold, CurrentId, NewCurrentId]) of
				?true ->?ok;
				?false ->
					Data		= [CurrentId],
					tower_db_mod:insert_offline_date(UserId, ?MODULE, Data, InitId)
			end;
		_ ->
			stop_swep(UserId)
	end.

update_sweep_cb(Player, [GoodList, Exp, Gold, PassId]) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, NewPlayer} ->
			Pass		  = data_tower:get_towerpass(PassId),
			MapId		  = Pass#rec_tower_pass.map,
			{{MonsterId,_}}= Pass#rec_tower_pass.monster_id,
			MonsterIdList = [{MonsterId}],
			{?ok, NewPlayer1}= task_api:update_battle(NewPlayer, MapId, MonsterIdList, 
													  ?CONST_BATTLE_RESULT_LEFT, ?CONST_BATTLE_TOWER),
			case get_reward(NewPlayer1, GoodList, Exp, Gold, ?CONST_COST_TOWER_SWEEP_REWARD, PassId) of
				{?error, NewPlayer2} -> {?ok, NewPlayer2};
				{?ok, NewPlayer2} ->	
					tower_mod:get_auto_reward(NewPlayer2, ?CONST_COST_TOWER_SWEEP_REWARD, PassId)
			end;
		{?false, NewPlayer, _} ->
			{?ok, NewPlayer}
	end.
update_sweep_cb1(Player, [RewardId, Exp, Gold, CurrentId, NewCurrentId]) ->
	{PassId}			= CurrentId,
	GoodList	  		= goods_api:goods_drop(RewardId),
	Pass		  		= data_tower:get_towerpass(PassId),
	MapId		  		= Pass#rec_tower_pass.map,
	{{MonsterId,_}}		= Pass#rec_tower_pass.monster_id,
	MonsterIdList	 	= [{MonsterId}],
	{?ok, Player1}		= task_api:update_battle(Player, MapId, MonsterIdList, 
											  ?CONST_BATTLE_RESULT_LEFT, ?CONST_BATTLE_TOWER),
	case  get_reward(Player1, GoodList, Exp, Gold, ?CONST_COST_TOWER_SWEEP_REWARD, PassId) of
		{?error, NewPlayer} -> {?ok, NewPlayer};
		{?ok, NewPlayer} -> 	
			{?ok, NewPlayer1}   = tower_mod:get_auto_reward(NewPlayer, ?CONST_COST_TOWER_SWEEP_REWARD, PassId),
			NewGoodsList  		= get_goods_info(GoodList, []),
			Packet 		  		= tower_api:msg_sc_sweep_card(CurrentId, NewCurrentId, Exp, Gold, NewGoodsList),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, NewPlayer1}
	end.
	
	
%% 获取当前关卡的大阵
get_current_camp(TopPass) ->
	TopPass1	= misc:to_integer(TopPass),
	Flag		= TopPass1 =< 10,
	Num			= erlang:length(TopPass),
	case Num =:= 3 of
		?true  -> 
			LastNum		= lists:nth(Num, TopPass),
			LastNum1	= misc:to_integer(LastNum),
			Level		= lists:sublist(TopPass, 1, 2),
			Level1		= misc:to_integer(Level),
			case LastNum1 =:= 48 of
				?true  -> Level1;
				?false -> Level1 + 1
			end;
		?false ->
			case Flag of
				?true  -> ?CONST_SYS_TRUE;
				?false ->
					[Temp|Temp1]		= TopPass,
					Temp2				= misc:to_integer(Temp1),
					case Temp2 =:= ?CONST_SYS_FALSE of
						?true  -> (Temp - 48);
						?false -> (Temp - 48) + 1
					end
			end
	end.

%% 获取物品列表
get_goods_info([Goods|GoodsList], Acc) when is_record(Goods, goods) ->
	GoodsId		= Goods#goods.goods_id,
	GoodsNum	= Goods#goods.count,
	NewAcc		= [{GoodsId, GoodsNum} | Acc],
	get_goods_info(GoodsList, NewAcc);
get_goods_info([], Acc) ->
	Acc.

%% 获取奖励
get_reward(Player, GoodList, Exp, Gold, Type, PassId) ->  
    UserId = Player#player.user_id,
     % 经验
	{?ok, Player2} = player_api:exp(Player, Exp),
	% 铜钱
	case Gold of
		Gold when Gold > 0 ->
			player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_TOWER_SWEEP_REWARD); 
		_ ->
			?ignore
	end,
	% 道具
    case ctn_bag_api:put(Player2, GoodList, Type, 1, 1, 0, 0, 1, 1, [PassId]) of
		{?ok, Player3, _, _PacketBag} ->
			{?ok, Player3};
		{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
			case player_state_api:try_set_state_play(Player2, ?CONST_PLAYER_PLAY_CITY) of
				{?true, NewPlayer} ->
					stop_swep(UserId),
					{?error, NewPlayer};
				{?false, NewPlayer, _} ->
					stop_swep(UserId),
					{?error, NewPlayer}
			end;
		{?error, _ErrorCode} ->
			stop_swep(UserId),
			{?error, Player2}
	end.

%% 获取奖励信息
get_reward_info([{PassId}|PassList], Acc) ->
	Pass		  = data_tower:get_towerpass(PassId),
	?MSG_DEBUG("PassId~p", [PassId]),
	RewardId	  = Pass#rec_tower_pass.award,                %%掉落奖励
	GoodsList	  = goods_api:goods_drop(RewardId),
	Exp			  = Pass#rec_tower_pass.exp,
	Gold		  = Pass#rec_tower_pass.gold,
	NewGoodsList  = get_goods_info(GoodsList, []),
	NewAcc		  = [{PassId, Exp, Gold, NewGoodsList} |Acc],
	get_reward_info(PassList, NewAcc);
get_reward_info([], Acc) ->
	Acc.

%% 再上线时处理
flush_offline(Player, []) ->
	{?ok, Player};
flush_offline(Player, [{InitId}]) ->
	player_api:process_send(Player#player.user_id, ?MODULE, flush_offline_cb, [{InitId}]),
	{?ok, Player};
flush_offline(Player, [{InitId}|OfflineList]) ->
	player_api:process_send(Player#player.user_id, ?MODULE, flush_offline_cb, [{InitId}|OfflineList]),
	{?ok, Player}.

flush_offline_cb(Player, [{InitId}]) ->
	PlayerId	= Player#player.user_id,
	?MSG_PRINT("InitId=~p", [InitId]),
	Now 		= misc:seconds(),
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TopScore	= Tower#ets_tower_player.top_score,
			Sweep		= Tower#ets_tower_player.sweep,
			SweepList	= Sweep#towersweep.sweep_list,
			CurrentEnd	= Sweep#towersweep.current_end,
			EndTime 	= Sweep#towersweep.end_time,
			LeftTime	= EndTime - Now,
			CurrentLeft	= CurrentEnd - Now,
			Packet		= if
							  CurrentLeft < 0 ->
								  tower_api:msg_sc_open_rush(1, InitId, 0, TopScore, []);
							  ?true ->
								  IdList = get_reward_info([{InitId}], []),
								  tower_api:msg_sc_open_rush(1, InitId, LeftTime, TopScore, IdList)
						  end,
			?MSG_DEBUG("Packet=~p", [Packet]),
			Packet1 		= tower_api:msg_sc_auto_rush(SweepList),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			{?ok, Player};
		_ -> {?ok, Player}
	end;
flush_offline_cb(Player, [{InitId}|OfflineList1]) ->
	PlayerId	= Player#player.user_id,
	Now 		= misc:seconds(),
	OfflineList = lists:usort(OfflineList1),
	case tower_mod_create:get_tower_player(PlayerId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TopScore	= Tower#ets_tower_player.top_score,
			Sweep		= Tower#ets_tower_player.sweep,
			SweepIdList	= Sweep#towersweep.sweep_list,
			EndTime 	= Sweep#towersweep.end_time,
			LeftTime	= EndTime - Now,
%% 			OffSweepList= [{InitId}|OfflineList],
			case get_off_reward(Player, OfflineList, []) of
				{?ok, NewPlayer, Acc} ->
					?MSG_DEBUG("flush_offline_cb, Acc=~p, OfflineList=~p, SweepIdList=~p", [Acc, OfflineList,SweepIdList]),
					Packet		= if
									  LeftTime =< 0 ->
										  tower_api:msg_sc_open_rush(2, InitId, 0, TopScore, Acc);
									  ?true ->
										  tower_api:msg_sc_open_rush(1, InitId, LeftTime, TopScore, Acc)
								  end,
					Packet1 		= tower_api:msg_sc_auto_rush(SweepIdList),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
					{?ok, NewPlayer};
				{?error, NewPlayer, Acc} ->
					?MSG_DEBUG("flush_offline_cb, Acc=~p, OfflineList=~p, SweepIdList=~p", [Acc, OfflineList,SweepIdList]),
					Packet1 		= tower_api:msg_sc_auto_rush(SweepIdList),
					Packet			= tower_api:msg_sc_open_rush(3, InitId, 0, TopScore, Acc),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
					{?ok, NewPlayer}
			end;
		_ -> {?ok, Player}
	end.
%% 对离线的每个关卡进行上线奖励
get_off_reward(Player, [{PassId}|OfflineList], Acc) ->
	Pass		  = data_tower:get_towerpass(PassId),
	RewardId	  = Pass#rec_tower_pass.award,                %%掉落奖励
	GoodList	  = goods_api:goods_drop(RewardId),
	Exp			  = Pass#rec_tower_pass.exp,
	Gold		  = Pass#rec_tower_pass.gold,
	MapId		  = Pass#rec_tower_pass.map,
	{{MonsterId,_}}= Pass#rec_tower_pass.monster_id,
	MonsterIdList = [{MonsterId}],
	{?ok, Player1}= task_api:update_battle(Player, MapId, MonsterIdList, 
										?CONST_BATTLE_RESULT_LEFT, ?CONST_BATTLE_TOWER),
	case  get_reward(Player1, GoodList, Exp, Gold, ?CONST_COST_TOWER_OFFLINE_SWEEP, PassId) of
		{?error, NewPlayer} -> get_off_reward(NewPlayer, [], Acc);
		{?ok, NewPlayer} ->
			{?ok, NewPlayer1} = tower_mod:get_auto_reward(NewPlayer, ?CONST_COST_TOWER_OFFLINE_SWEEP, PassId),
			NewGoodsList  	  = get_goods_info(GoodList, []),
			NewAcc		  	  = [{PassId, Exp, Gold, NewGoodsList} |Acc],
			get_off_reward(NewPlayer1, OfflineList, NewAcc)
	end;
get_off_reward(Player, [], Acc) ->
	{?ok, Player, Acc}.	
	
%% 背包满停止扫荡
stop_swep(UserId) ->
	case tower_mod_create:get_tower_player(UserId) of
		Tower when is_record(Tower, ets_tower_player) ->
			TowerSweep		= Tower#ets_tower_player.sweep,
			NewTowerSweep	= TowerSweep#towersweep{current_id = 0, current_end = 0, begin_time = 0, end_time = 0,
													sweep_list = [], interval_time = 0},
			NewTower		= Tower#ets_tower_player{sweep = NewTowerSweep},
			ets_api:insert(?CONST_ETS_TOWER_PLAYER, NewTower),
			tower_db_mod:end_sweep(UserId, NewTower),
			Result			= ?CONST_SYS_TRUE,
			Packet 			= tower_api:msg_sc_sweep_over(Result),
			misc_packet:send(UserId, Packet);
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(UserId, TipsPacket)
	end.
		