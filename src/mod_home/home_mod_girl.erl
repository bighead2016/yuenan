%% Author: Administrator
%% Created: 2013-10-11
%% Description: TODO: Add description to home_mod_girl
-module(home_mod_girl).

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
-export([init_recommend_list/3, get_recommend_list/1, grab_girl/3,
		 resist_by_self/1, rescue_friend/2, invite_friend/2,
		 invite_reply/3, press_girl/2, draw_girl/2, get_rescue_friend/1,
		 release_girl_self/2, get_exp_self/2, fawn_belonger/1,
		 play_main_girl/2, play_black_girl/3, increase_grab_times/1, get_black_info/1,
		 show_girl/2, press_draw_girl/3]).
-export([update_user_battle_state/1, update_user_battle_state1/1, get_user_state/1,
		 update_release_user_info/1, get_source_list/2, add_inter_info/6,
		 get_girl_times/1, get_play_num/2, filter_by_lv/3, update_release_user_info1/1,
		 update_release_user_info2/2, add_source_list/2]).

%%
%% API Functions
%%
%%-------------------------------------------------------------------------------------------------
%% 初始化推荐列表
%%-------------------------------------------------------------------------------------------------
init_recommend_list([], Recommend, _) -> Recommend;
init_recommend_list([UserId|Tail], Recommend, Pos) ->
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} ->
			Info			= Player#player.info,
			Name			= Info#info.user_name,
			Lv				= Info#info.lv,
			Pro				= Info#info.pro,
			OpenFlag		= case home_mod_create:get_home1(UserId) of
								  Home when is_record(Home, ets_home) -> ?true;
								  _ -> ?false
							  end,
			State			= get_user_battle_state(UserId),
			case {OpenFlag, State} of											%% 家园开启且不在战斗中(考虑过滤在仇人列表的人)
				{?true, ?CONST_SYS_FALSE} ->
					GirlLv			= home_mod:get_top_girl_id(UserId),
					RecommendInfo	= #recommend_list{pos = Pos , id = UserId, name = Name, lv = Lv, pro = Pro, 
													  girl_lv = GirlLv, state = 2},
					NewRecommend	= erlang:setelement(Pos, Recommend, RecommendInfo),
					init_recommend_list(Tail, NewRecommend, Pos + 1);
				_ ->
					init_recommend_list(Tail, Recommend, Pos)
			end;
		_ -> 
			init_recommend_list(Tail, Recommend, Pos)
	end.
%%-------------------------------------------------------------------------------------------------
%% 请求推荐列表和仇人列表
%%-------------------------------------------------------------------------------------------------
get_recommend_list(Player) ->
	UserId				= Player#player.user_id,
	Now					= misc:seconds(),
	Lv					= (Player#player.info)#info.lv,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home)->
			Girl			 = Home#ets_home.girl,
			State			 = Girl#girl.state,
			Recommend		 = Girl#girl.recommend_list,
			Enemy			 = Girl#girl.enemy_list,
			BeginTime		 = Girl#girl.grab_begin_time,
			Ids			 	 = Girl#girl.source_list,
			IdList			 = get_source_list(Ids, UserId),
%% 			IdList			 = get_source_list(Ids, UserId),
%% 			NewIds			 = filter_by_lv1(IdList, Lv, []),
%% 			?MSG_DEBUG("~nIds=~p, IdList=~p, NewIds=~p", [Ids, IdList, NewIds]),
			NewIds1			 = filter_in_black(IdList, Home, []),
			?MSG_DEBUG("1111111111111, NewIds1=~p", [NewIds1]),
			RecList			 = misc:to_list(Recommend),
			?MSG_DEBUG("22222222222222, Recommend=~p", [Recommend]),
			Recommend1	 	 = add_rec_info(NewIds1, 1, RecList),
			
			RecommendList	 = update_rec_order(Recommend1, 1, []),
			?MSG_DEBUG("1111111111111, Recommend1=~p~n RecommendList=~p~n", [Recommend1, RecommendList]),
			NewRecommend	 = misc:to_tuple(RecommendList),
			NewGirl			 = Girl#girl{recommend_list = NewRecommend},
			NewHome			 = Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			List1			 = get_rec_info(RecommendList),
			List2			 = get_enemy_info(misc:to_list(Enemy)),
			Time			 = case BeginTime of
								   ?CONST_SYS_FALSE -> ?CONST_SYS_FALSE;
								   _ ->
									   EndTime			= BeginTime + 10 * ?CONST_SYS_NUMBER_SIXTY,
									   case EndTime < Now of
										   ?true  -> ?CONST_SYS_FALSE;
										   ?false -> EndTime
									   end
							   end,
			Packet			 = home_api:msg_recom_enemy_list(List1, List2, State, Time),
			{GrabTimes, PlayTimes, RescueTimes, Exp} = get_play_num(Home, Lv),
			Packet1		= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, Exp),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

get_source_list(Ids, UserId) ->
	List			= misc:filter_list(Ids, 1, 0),
	List1			= filter_by_lv(List, UserId, []),
	lists:delete(UserId, List1).
%% get_source_list(Ids, UserId) ->
%% 	Ids1			= single_arena_api:get_area_win_top(UserId),
%% 	NewIds			= Ids1 ++ Ids,
%% 	List			= misc:filter_list(NewIds, 1, 0),
%% 	List1			= lists:delete(UserId, List),
%% 	get_source_list1(List1, []).
%% 
%% get_source_list1([], Acc) -> Acc;
%% get_source_list1([UserId|Tail], Acc) ->
%% 	?MSG_DEBUG("~n UserId=~p", [UserId]),
%% 	case length(Acc) >= 10 of
%% 		?true  -> 
%% 			get_source_list1([], Acc);
%% 		?false -> 
%% 			NewAcc		= Acc ++ [UserId],
%% 			?MSG_DEBUG("~n NewAcc=~p", [NewAcc]),
%% 			get_source_list1(Tail, NewAcc)
%% 	end.

%% 过滤等级差大于等于10级的玩家
filter_by_lv(IdList, UserId, Acc) ->
	UserLv = case player_api:get_player_field(UserId, #player.info) of
				 {?ok, #info{lv = Lv}} -> Lv;
				 _ -> 0
			 end,
	filter_by_lv1(IdList, UserLv, Acc).

filter_by_lv1([], _, Acc) -> Acc;
filter_by_lv1([OtherId|Tail], UserLv, Acc) ->
	OtherLv = case player_api:get_player_field(OtherId, #player.info) of
				  {?ok, #info{lv = Lv}} -> Lv;
				  _ -> 0
			  end,
	case abs(OtherLv - UserLv) >= 10 of
		?true ->
			filter_by_lv1(Tail, UserLv, Acc);
		?false ->
			filter_by_lv1(Tail, UserLv, [OtherId|Acc])
	end.
%% filter_by_lv([], _, Acc) -> Acc;
%% filter_by_lv([OtherId|Tail], UserId, Acc) ->
%% 	UserLv				= case player_api:get_player_field(UserId, #player.info) of
%% 							  {?ok, #info{lv = Lv}} -> Lv;
%% 							  _ -> 0
%% 						  end,
%% 	OtherLv				= case player_api:get_player_field(OtherId, #player.info) of
%% 							  {?ok, #info{lv = Lv1}} -> Lv1;
%% 							  _ -> 0
%% 						  end,
%% 	case abs(OtherLv - UserLv) >= 10 of
%% 		?true  -> 
%% 			filter_by_lv(Tail, UserId, Acc);
%% 		?false -> 
%% 			NewAcc		= Acc ++ [OtherId],
%% 			filter_by_lv(Tail, UserId, NewAcc)
%% 	end.

%% 过滤在小黑屋中以及在推荐列表和仇人列表的人物
filter_in_black([], _, Acc) -> Acc;
filter_in_black([UserId|Tail], Home, Acc) ->
	Girl			= Home#ets_home.girl,
	RecommendList	= misc:to_list(Girl#girl.recommend_list),
	EnemyList		= misc:to_list(Girl#girl.enemy_list),
	GrabList		= misc:to_list(Girl#girl.grab_girl_info),
	Flag			= lists:keymember(UserId, #recommend_list.id, RecommendList),
	Flag1			= lists:keymember(UserId, #grab_girl_info.owner_id, GrabList),
	Flag2			= lists:keymember(UserId, #enemy_list.id,EnemyList),
	case {Flag, Flag1, Flag2} of
		{?false, ?false, ?false} ->
			NewAcc		= Acc ++ [UserId],
			filter_in_black(Tail, Home, NewAcc);
		_ ->
			filter_in_black(Tail, Home, Acc)
	end.

%%加入新的推荐信息
%% add_rec_info([], _Num, Recommend) -> Recommend;
%% add_rec_info([UserId|Tail], Num, Recommend) when Num =< 4 ->
%% 	?MSG_DEBUG("UserId=~p, Tail=~p", [UserId, Tail]),
%% 	case player_api:get_player_first(UserId) of
%% 		{?ok, Player, _} ->
%% 			Info			= Player#player.info,
%% 			Name			= Info#info.user_name,
%% 			Lv				= Info#info.lv,
%% 			Pro				= Info#info.pro,
%% 			OpenFlag		= case home_mod_create:get_home1(UserId) of
%% 								  Home when is_record(Home, ets_home) -> ?true;
%% 								  _ -> ?false
%% 							   end,
%% 			State			= get_user_battle_state(UserId),
%% 			case {OpenFlag, State} of
%% 				{?true, ?CONST_SYS_FALSE} ->
%% 					?MSG_DEBUG("~nadd_rec_infoState=~p", [State]),
%% 					GirlLv				= home_mod:get_top_girl_id(UserId),
%% 					NewRecommend		= setelement(Num, Recommend, #recommend_list{pos = Num, id = UserId, name = Name, lv = Lv, pro = Pro, 
%% 													  girl_lv = GirlLv, state = 2}),
%% %% 					NewRecommend		= Recommend#recommend_list{id = UserId, name = Name, lv = Lv, pro = Pro, 
%% %% 													  girl_lv = GirlLv, state = 2},
%% %% 					NewRecommendList= [Recommend|RecommendList],
%% %% 					NewRecommendList= RecommendList ++ [Recommend],
%% 					add_rec_info(Tail, Num+1, NewRecommend);
%% 				_ ->
%% 					?MSG_DEBUG("~nadd_rec_info:State=~p", [State]),
%% 					add_rec_info(Tail, Num, Recommend)
%% 			end;
%% 		_ ->
%% 			?MSG_DEBUG("~nadd_rec_info", []),
%% 			add_rec_info(Tail, Num, Recommend)
%% 	end.
add_rec_info([], _Num, RecommendList) -> RecommendList;
add_rec_info([UserId|Tail], Num, RecommendList) when Num =< 4 ->
	?MSG_DEBUG("UserId=~p, Tail=~p", [UserId, Tail]),
	case player_api:get_player_first(UserId) of
		{?ok, Player, _} ->
			Info			= Player#player.info,
			Name			= Info#info.user_name,
			Lv				= Info#info.lv,
			Pro				= Info#info.pro,
			OpenFlag		= case home_mod_create:get_home1(UserId) of
								  Home when is_record(Home, ets_home) -> ?true;
								  _ -> ?false
							   end,
			State			= get_user_battle_state(UserId),
			case {OpenFlag, State} of
				{?true, ?CONST_SYS_FALSE} ->
					?MSG_DEBUG("~nadd_rec_infoState=~p", [State]),
					GirlLv			= home_mod:get_top_girl_id(UserId),
					Recommend		= #recommend_list{id = UserId, name = Name, lv = Lv, pro = Pro, 
													  girl_lv = GirlLv, state = 2},
					NewRecommendList= [Recommend|RecommendList],
%% 					NewRecommendList= RecommendList ++ [Recommend],
					add_rec_info(Tail, Num +1, NewRecommendList);
				_ ->
					?MSG_DEBUG("~nadd_rec_info:State=~p", [State]),
					add_rec_info(Tail, Num, RecommendList)
			end;
		_ ->
			?MSG_DEBUG("~nadd_rec_info", []),
			add_rec_info(Tail, Num, RecommendList)
	end;
add_rec_info([_UserId|_Tail], _Num, RecommendList) -> RecommendList.
	

%% 更新新的推荐列表顺序
update_rec_order([], _, Acc) -> 
	Len			= length(Acc),
	case Len >= 4 of
		?true  -> Acc;
		?false -> add_rec_list(Acc, Len+1)
	end;
update_rec_order([Recommend|Tail], Num, Acc) when Recommend#recommend_list.state =:= 2 ->
	case Num > 4 of
		?false ->
			RecommendInfo			= Recommend#recommend_list{pos = Num},
			NewAcc					= Acc ++ [RecommendInfo],
			update_rec_order(Tail, Num + 1, NewAcc);
		?true ->
			update_rec_order([], Num, Acc)
	end;
update_rec_order([_Recommend|Tail], Num, Acc) ->
	update_rec_order(Tail, Num, Acc).

%% 补齐推荐的数据
add_rec_list(Acc, Len) when Len =< 4 ->
	NewAcc		= Acc ++ [#recommend_list{pos = Len, state = 0}],
	add_rec_list(NewAcc, Len+1);
add_rec_list(Acc, _Len) -> Acc.

					
%% 获取推荐列表信息
get_rec_info(List) -> 
	F	= fun(Recommend, Acc) when (is_record(Recommend, recommend_list) andalso Recommend#recommend_list.state =:= 2)->
				  Id  	  		= Recommend#recommend_list.id,
				  Name    		= Recommend#recommend_list.name,
				  Lv  	  		= Recommend#recommend_list.lv,
				  Grid	  		= Recommend#recommend_list.pos,
				  GirlLv  		= Recommend#recommend_list.girl_lv,
				  Pro	  		= Recommend#recommend_list.pro,
				  Power	  		= case Id =:= ?CONST_SYS_FALSE of
									  ?true  -> ?CONST_SYS_FALSE;
									  ?false -> partner_api:caculate_camp_power(Id)
								  end,
				  {BelongerId, BelongerName, BelongerPower}
		  						= get_belonger_info(Id),
				  [{Id, Name, Lv, Grid, GirlLv, Pro, Power, BelongerId, BelongerName, BelongerPower}|Acc];
			 (_, Acc) ->
				  Acc
		  end,
	lists:foldl(F, [], List).

%% 获取仇人列表信息
get_enemy_info(List) -> 
	F1	= fun(Enemy1, Acc1) when (is_record(Enemy1, enemy_list) andalso Enemy1#enemy_list.state =:= 2)->
				  Id1  	  		= Enemy1#enemy_list.id,
				  Name1    		= Enemy1#enemy_list.name,
				  Lv1  	  		= case player_api:get_player_field(Id1, #player.info) of
									  {?ok, #info{lv = Lv}} -> Lv;
									  _ -> Enemy1#enemy_list.lv
								  end,
				  Grid1	  		= Enemy1#enemy_list.pos,
				  GirlLv1		= Enemy1#enemy_list.girl_lv,
				  Pro1			= Enemy1#enemy_list.pro,
				  Power1		= case Id1 =:= ?CONST_SYS_FALSE of
									  ?true  -> ?CONST_SYS_FALSE;
									  ?false -> partner_api:caculate_camp_power(Id1)
								  end,
				  {BelongerId, BelongerName, BelongerPower}
		  						= get_belonger_info(Id1),
				  [{Id1, Name1, Lv1, Grid1, GirlLv1, Pro1, Power1, BelongerId, BelongerName, BelongerPower}|Acc1];
			 (_, Acc1) ->
				  Acc1
		  end,
	lists:foldl(F1, [], List).

%% 获取列表中主人信息
get_belonger_info(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Belonger		= Girl#girl.belonger,
			case Belonger of
				0 -> {0, "", 0};
				_ ->
					Name			= player_api:get_name(Belonger),
					Power			= partner_api:caculate_camp_power(Belonger),
					{Belonger, Name, Power}
			end;
		_ -> {0, "", 0}
	end.
%%-------------------------------------------------------------------------------------------------
%% 自由身或者抓捕者状态下进行抓捕侍女
%% Type 1推荐2仇人
%%-------------------------------------------------------------------------------------------------
grab_girl(Player, Type, Grid) ->
	UserId			= Player#player.user_id,
	UserLv			= (Player#player.info)#info.lv,
	case get_release_girl_home(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl		= Home#ets_home.girl,
			RecInfo		= Girl#girl.recommend_list,
			EnemyInfo	= Girl#girl.enemy_list,
			BattleType	= get_battle_type(Type, Grid, RecInfo, EnemyInfo),								%% 获取战斗形式0和自由身战斗1和抓捕者战斗2和被抓捕者主人战斗
			GrabedId	= get_battle_user(Type, Grid, RecInfo, EnemyInfo),								%% 获取真正的战斗对象
			GrabedId1	= get_graber_user(BattleType, Type, Grid, RecInfo, EnemyInfo, GrabedId),		%% 获取抢走的对象
			?MSG_DEBUG("1111111111111111111111111111 start_battle :~n RecInfo=~p, EnemyInfo=~p, BattleType=~p~n", [RecInfo, EnemyInfo, BattleType]),
			case check_grab(BattleType, Home, GrabedId, GrabedId1, UserLv) of
				?ok ->
					case battle_api:start(Player, GrabedId, #param{battle_type = ?CONST_BATTLE_HOME, ad1 = Type, 
																   ad2 = Grid, ad3 = GrabedId1, ad4 = BattleType}) of
						{?ok, NewPlayer} -> 
							Message			= Home#ets_home.message,
							Declare			= Message#message.declare,
							GrabTimes		= Declare#declare.grab_times + 1,
							NewDeclear		= Declare#declare{grab_times = GrabTimes},
							GrabNum			= Girl#girl.grab_num - 1,
							NewMessage		= Message#message{declare = NewDeclear},
							BattleList		= [UserId, GrabedId, GrabedId1],
							NewGirl			= Girl#girl{grab_num = GrabNum, grab_begin_time = 0, battle_list = BattleList},
							NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							
							Packet			= home_mod:notice_daily_task_over(UserId),
							misc_packet:send(Player#player.net_pid, Packet),
							{?ok, NewPlayer};
						{?error, _} -> {?ok, Player}
					end;
				{?error, ErrorCode} ->
					?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
					TipPacket	= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

%% 获取小黑屋释放后的家园数据
get_release_girl_home(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			UserName		= player_api:get_name(UserId),
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			GrabList		= misc:to_list(BlackInfo),
			Now				= misc:seconds(),
			
			F = fun(Grab) when (is_record(Grab, grab_girl_info)) andalso Grab#grab_girl_info.state =:= 2 ->
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
								
								NewTuple			= #grab_girl_info{pos = Pos, state = 1},			  %% 更改小黑屋信息
								NewGrabInfo			= erlang:setelement(Pos, BlackInfo, NewTuple),
								
								Ids					= Girl#girl.source_list,
								SourceList			= get_source_list([OwnerId|Ids], UserId),
								NewGirl				= Girl#girl{source_list = SourceList, grab_girl_info = NewGrabInfo},
								NewHome				= Home#ets_home{girl = NewGirl, message= NewMessage},
								ets_api:insert(?CONST_ETS_HOME, NewHome);
							?false ->
								?ok
						end;
				   (_) ->
						?ok
				end,
			lists:foreach(F, GrabList),
			State			= home_mod_girl:get_user_state(UserId),
			case home_mod_create:get_home1(UserId) of
				Home2 when is_record(Home2, ets_home) ->
					Girl2			= Home2#ets_home.girl,
					NewGirl2		= Girl2#girl{state = State},
					NewHome2		= Home#ets_home{girl = NewGirl2},
					ets_api:insert(?CONST_ETS_HOME, NewHome2),
					NewHome2;
				_ -> {?error, ?TIP_COMMON_SYS_ERROR}
			end
	end.

%% 获取战斗形式0和自由身战斗1和抓捕者战斗2和被抓捕者主人战斗
get_battle_type(Type, Grid, RecInfo, EnemyInfo) ->
	UserId			= case Type of
						  1 ->
							  Rec			= erlang:element(Grid, RecInfo),
							  Rec#recommend_list.id;
						  2 ->
							  Enemy		= erlang:element(Grid, EnemyInfo),
							  Enemy#enemy_list.id
					  end,
	get_user_state(UserId).
	
%% 获取真正的战斗对象
get_battle_user(1, Grid, RecInfo, _EnemyInfo) ->
	Rec			= erlang:element(Grid, RecInfo),
	UserId		= Rec#recommend_list.id,
	?MSG_DEBUG("~n UserId=~p", [UserId]),
	State		= get_user_state(UserId),
	case State of												
		2 ->													%% 如果是被抓捕者 和主人战斗
			get_belonger_id(UserId);
		_ ->												    %% 如果是自由身或者抓捕者 
			UserId
	end;
get_battle_user(2, Grid, _RecInfo, EnemyInfo) ->
	Enemy		= erlang:element(Grid, EnemyInfo),
	UserId		= Enemy#enemy_list.id,
	State		= get_user_state(UserId),
	case State of												
		2 ->													%% 如果是被抓捕者 和主人战斗
			get_belonger_id(UserId);
		_ ->												    %% 如果是自由身或者抓捕者 
			UserId
	end.
%% 获取抢走的对象
get_graber_user(0, _Type, _Grid, _RecInfo, _EnemyInfo, GrabedId) ->
	?MSG_DEBUG("1111111111111111, GrabedId=~p", [GrabedId]),
	GrabedId;
get_graber_user(1, _Type, _Grid, _RecInfo, _EnemyInfo, GrabedId) ->
	get_top_slaver_id(GrabedId);
get_graber_user(2, Type, Grid, RecInfo, EnemyInfo, _GrabedId) ->
	get_battle_user1(Type, Grid, RecInfo, EnemyInfo).

%% 获取表面的战斗对象
get_battle_user1(Type, Grid, RecInfo, EnemyInfo) ->
	case Type of
		1 ->
			Rec			= erlang:element(Grid, RecInfo),
			Rec#recommend_list.id;
		2 ->
			Enemy		= erlang:element(Grid, EnemyInfo),
			Enemy#enemy_list.id
	end.
%% 
%% 检查是否能抢夺
check_grab(BattleType, Home, GrabedId, GrabedId1, UserLv) ->
	UserId			= Home#ets_home.user_id,
	?MSG_DEBUG("~n UserId=~p,GrabedId=~p GrabedId1=~p~n", [UserId,GrabedId, GrabedId1]),
	Girl			= Home#ets_home.girl,                   
	GrabTimes		= Girl#girl.grab_num,
	GrabInfo		= Girl#girl.grab_girl_info,
	try
		?ok		   = check_battle_self(UserId, GrabedId),                       %% 检查是否跟自己战斗
		?ok		   = check_battle_self1(UserId, GrabedId1),
		?ok		   = check_user_state(Home),									%% 检查自身状态
		?ok		   = check_grab_cd(Home),										%% 检查抓捕cd
		?ok	 	   = check_times(GrabTimes),									%% 检查抓捕次数
		?ok		   = check_black_num(GrabInfo),									%% 检查小黑屋数量
		?ok        = check_lv_diff(UserLv, GrabedId),							%% 检查等级差
		?ok		   = check_battle_state(UserId),								%% 检查战斗状态
		?MSG_DEBUG("11111111111111111111", []),
		?ok		   = check_grab_user_exist(GrabedId1),                          %% 检查被抢走对象是否存在
		?MSG_DEBUG("11111111111111111111", []),
		?ok		   = check_grab_ext(BattleType, Home, GrabedId, GrabedId1)     
	catch
		throw:{?error, ErrorCode} ->
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_SYS_ERROR} % 入参有误																			
	end.

%%检查战斗对象是否是自己
check_battle_self(UserId, UserId) -> throw({?error, ?TIP_HOME_BATTLE_SELF});
check_battle_self(_, _) -> ?ok.

%% 检查被抢走对象是否存在
check_grab_user_exist(0) -> 
	?MSG_DEBUG("11111111111111111111", []),
	throw({?error, ?TIP_COMMON_SYS_ERROR});
check_grab_user_exist(_) -> ?ok.

%% 检查等级差
check_lv_diff(UserLv, GrabedId) ->
	case player_api:get_player_field(GrabedId, #player.info) of
		{?ok, #info{lv = Lv}} when abs(UserLv - Lv) < 10 -> ?ok;
		_ -> throw({?error, ?TIP_HOME_LV_NOT_ALLOW})                           %% 等级差过10级
	end.

%% 根据战斗形式再进行检查
check_grab_ext(0, Home, GrabedId, GrabedId) ->
	UserId			= Home#ets_home.user_id,
	try
		?ok		   = check_battle_state(GrabedId),								%% 检查实际战斗对象状态
		?ok		   = update_battle_state(UserId),								%% 更新自身战斗状态
		?ok		   = update_battle_state(GrabedId)								%% 更新实际战斗对象状态
	catch
		throw:{?error, ErrorCode} ->
			throw({?error, ErrorCode});
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			throw({?error, ?TIP_COMMON_SYS_ERROR}) % 入参有误																			
	end;
check_grab_ext(_, Home, GrabedId, GrabedId1) when GrabedId =/= GrabedId1 ->
	UserId			= Home#ets_home.user_id,
	try
		?ok		   = check_battle_state(GrabedId),								%% 检查实际战斗对象状态
		?ok		   = check_battle_state(GrabedId1),								%% 检查被抢走对象状态
	
		?ok		   = update_battle_state(UserId),								%% 更新自身战斗状态
		?ok		   = update_battle_state(GrabedId),								%% 更新实际战斗对象状态
		?ok		   = update_battle_state(GrabedId1)								%% 更新被抢走对象战斗状态
	catch
		throw:{?error, ErrorCode} ->
			throw({?error, ErrorCode});
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			throw({?error, ?TIP_COMMON_SYS_ERROR}) % 入参有误																			
	end;
check_grab_ext(_, _, _, _) ->
	?MSG_ERROR("check_grab_ext:", []),
	throw({?error, ?TIP_COMMON_SYS_ERROR}).
%% 
%% 检查抢夺剩余次数
check_times(Times) when Times > ?CONST_SYS_FALSE -> ?ok;
check_times(A) ->
	?MSG_DEBUG("A=~p", [A]),
	throw({?error,?TIP_HOME_GRAB_TIMES_OVER}).                       			%% 今天抢劫次数已用完

%% 检查小黑屋是否已满
check_black_num(GrabInfo) ->	
	GrabList		= misc:to_list(GrabInfo),
	GrabHasNum		= cal_black_has(GrabList, ?CONST_SYS_FALSE),
	GrabOpenNum		= ?CONST_HOME_BLACK_NUM,								    
	case GrabOpenNum > GrabHasNum of
		?true ->  ?ok;
		?false ->
			?MSG_DEBUG("GrabOpenNum=~p, GrabHasNum=~p", [GrabOpenNum, GrabHasNum]),
			throw({?error, ?TIP_HOME_BLACK_NUM_OVER})
	end.

%% 计算小黑屋已经抢夺的格子数
cal_black_has([Grab|RestList], Acc) when Grab#grab_girl_info.state =:= 2 ->
	NewAcc	= Acc + 1,
	cal_black_has(RestList, NewAcc);
cal_black_has([_|RestList], Acc) ->
	cal_black_has(RestList, Acc);
cal_black_has([], Acc) ->
	Acc.


%% 检查自身状态
check_user_state(Home) ->
	Girl			= Home#ets_home.girl,
	State			= Girl#girl.state,
	case State of
		2 -> throw({?error, ?TIP_HOME_SLAVER_RESIST});   %% 你是被抓捕者,不能进行抓捕
		_ -> ?ok
	end.

%% 检查cd
check_grab_cd(Home) ->
	Now				= misc:seconds(),
	Girl			= Home#ets_home.girl,
	BeginTime		= Girl#girl.grab_begin_time,
	EndTime			= BeginTime + 10 * ?CONST_SYS_NUMBER_SIXTY,
	case EndTime >= Now of
		?true -> throw({?error, ?TIP_HOME_GRAB_CD});
		_ -> ?ok
	end.

%% 检查战斗状态
check_battle_state(UserId) ->
	?MSG_DEBUG("UserId=~p", [UserId]),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			BattleState		= Girl#girl.battle,
			?MSG_DEBUG("BattleState=~p", [BattleState]),
			case BattleState of
				?CONST_SYS_FALSE -> ?ok;
				_ ->														%% TODO 正在战斗中提示
					throw({?error, ?TIP_COMMON_STATE_FIGHTING})
			end;
		_ ->
			?MSG_DEBUG("UserId=~p", [UserId]),
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%% 检查更新战斗状态
update_battle_state(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_TRUE},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			?ok;
		_ ->
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%%-------------------------------------------------------------------------------------------------
%% 增加抓捕次数
%%-------------------------------------------------------------------------------------------------
increase_grab_times(Player) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 20, ?CONST_COST_INCREASE_GRAB_TIMES) of
				?ok ->
					Girl			= Home#ets_home.girl,
					GrabTimes		= Girl#girl.grab_num + 1,
					NewGirl			= Girl#girl{grab_num = GrabTimes},
					NewHome			= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= get_play_num(NewHome, Lv),
					Packet			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
					misc_packet:send(Player#player.net_pid, Packet);
				{?error, _ErrorCode} ->
					?ok
%% 					TipPacket		= message_api:msg_notice(ErrorCode),
%% 					misc_packet:send(Player#player.net_pid, TipPacket)
			end;
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%%-------------------------------------------------------------------------------------------------
%% 献媚(奴隶互动方式)
%%-------------------------------------------------------------------------------------------------
fawn_belonger(Player) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	Now				= misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_fawn(Home, Lv) of
				?ok ->
					Message			= Home#ets_home.message,
					InterList		= Message#message.interinfo,
					
					Girl			= Home#ets_home.girl,
					Belonger		= Girl#girl.belonger,
					BelongerName	= player_api:get_name(Belonger),
					Exp				= calc_play_girl_exp(Home, Lv),
					HasExp			= Girl#girl.play_exp + Exp,
					PlayTimes		= Girl#girl.play_times + 1,
					Declare			= Message#message.declare,
					PlayTimes1		= Declare#declare.play_girl_times + 1,
					NewDeclear		= Declare#declare{play_girl_times = PlayTimes1},
					InterInfo		= add_inter_info(InterList, 23, BelongerName, "", 0, Exp),
					NewMessage		= Message#message{declare = NewDeclear, interinfo = InterInfo},
					NewGirl			= Girl#girl{play_begin_time = Now, play_exp = HasExp,
												play_times = PlayTimes},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					Packet			= home_api:msg_sc_inter_info(23, BelongerName, "", 0, Exp),
					Packet1			= home_mod:get_guide_info(NewHome),
					TipPacket		= msg_notice_get_exp(Exp),
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= get_play_num(NewHome, Lv),
					Packet2			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
					Packet3			= home_api:msg_sc_play_success(1),
					Packet4			= home_mod:notice_daily_task_over(UserId),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, 
															  TipPacket/binary, Packet2/binary,
															  Packet3/binary, Packet4/binary>>),
					player_api:exp(Player, Exp);
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipPacket			= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 检查是否能献媚
check_fawn(Home, Lv) ->
	Girl			= Home#ets_home.girl,
	State			= Girl#girl.state,
	Times			= Girl#girl.play_times,
	BeginTime		= Girl#girl.play_begin_time,
	EndTime			= BeginTime + 4 * 60 * 60,							%% TODO 互动cd4小时
	HasExp			= Girl#girl.play_exp,
	TotalExp		= ?FUN_HOME_TOTAL_EXP(Lv),
	try
		?ok		 	= check_fawn_user_state(State),
		?ok		 	= check_play_times(Times),
		?ok		 	= check_play_cd(EndTime),
		?ok		 	= check_play_exp_max(HasExp, TotalExp)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

check_fawn_user_state(State) when State =:= 2 -> ?ok;
check_fawn_user_state(_) -> throw({?error, ?TIP_HOME_CANNOT_PLAY}).

%% 检查互动次数
check_play_times(Times) when Times < ?CONST_HOME_PLAY_TIMES  -> ?ok;	
check_play_times(_) -> throw({?error, ?TIP_HOME_PLAY_TIMES_OVER}).                   %% 互动次数已用完

check_play_cd(Time) ->
	Now			= misc:seconds(),
	case Time < Now of
		?true  -> ?ok;
		?false -> throw({?error, ?TIP_HOME_PLAY_CD})
	end.

calc_play_girl_exp(Home, Lv) ->
	Girl			= Home#ets_home.girl,
	HasExp			= Girl#girl.play_exp,
	Exp				= ?FUN_HOME_ONCE_EXP(Lv),
	TotalExp		= ?FUN_HOME_TOTAL_EXP(Lv),
	case HasExp + Exp > TotalExp of
		?true  -> TotalExp - HasExp;
		?false -> Exp
	end. 

%%-------------------------------------------------------------------------------------------------
%% 互动(自由身或者奴隶主互动方式)
%%-------------------------------------------------------------------------------------------------
play_main_girl(Player, SkillId) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	Now				= misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_play_with_girl(Home, Lv, 1, 0) of
				?ok ->
					Girl			= Home#ets_home.girl,
					Exp				= calc_play_girl_exp(Home, Lv),
					HasExp			= Girl#girl.play_exp + Exp,
					PlayTimes		= Girl#girl.play_times + 1,
					Message			= Home#ets_home.message,
					InterList		= Message#message.interinfo,
					InterInfo		= add_inter_info(InterList, 21, "", "", SkillId, Exp),
					Declare			= Message#message.declare,
					PlayTimes1		= Declare#declare.play_girl_times + 1,
					NewDeclear		= Declare#declare{play_girl_times = PlayTimes1},
					NewMessage		= Message#message{declare = NewDeclear, interinfo = InterInfo},
					NewGirl			= Girl#girl{play_begin_time = Now, play_exp = HasExp,
												play_times = PlayTimes},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					
					TipPacket		= msg_notice_get_exp(Exp),
					Packet			= home_api:msg_sc_play_success(1),
					Packet1			= home_api:msg_sc_inter_info(21, "", "", SkillId, Exp),
					Packet2			= home_mod:get_guide_info(NewHome),
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= get_play_num(NewHome, Lv),
					Packet3			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),	
					Packet4			= home_mod:notice_daily_task_over(UserId),
					
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary, Packet1/binary, 
															  Packet2/binary, Packet3/binary, Packet4/binary>>),
					player_api:exp(Player, Exp);
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipPacket			= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.
%% 和小黑屋侍女互动
play_black_girl(Player, Grid, _) when Grid < 1 orelse Grid > 3 -> {?ok, Player};
play_black_girl(Player, Grid, SkillId) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	Now				= misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_play_with_girl(Home, Lv, 2, Grid) of
				?ok ->
					Girl			= Home#ets_home.girl,
					GrabInfo		= Girl#girl.grab_girl_info,
					BlackInfo		= element(Grid, GrabInfo),
					OtherName		= BlackInfo#grab_girl_info.owner_name,
					
					Exp				= calc_play_girl_exp(Home, Lv),
					HasExp			= Girl#girl.play_exp + Exp,
					PlayTimes		= Girl#girl.play_times + 1,
					Message			= Home#ets_home.message,
					InterList		= Message#message.interinfo,
					InterInfo		= add_inter_info(InterList, 22, OtherName, "", SkillId, Exp),
					Declare			= Message#message.declare,
					PlayTimes1		= Declare#declare.play_girl_times + 1,
					NewDeclear		= Declare#declare{play_girl_times = PlayTimes1},
					NewMessage		= Message#message{declare = NewDeclear, interinfo = InterInfo},
					
					NewBlackInfo	= BlackInfo#grab_girl_info{play_time = Now},
					NewGrabInfo		= erlang:setelement(Grid, GrabInfo, NewBlackInfo),
					NewGirl			= Girl#girl{play_exp = HasExp, play_times = PlayTimes,
												grab_girl_info = NewGrabInfo},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					
					TipPacket		= msg_notice_get_exp(Exp),
					Packet			= home_api:msg_sc_play_success(1),
					Packet1			= home_api:msg_sc_inter_info(22, "", "", SkillId, Exp),
					Packet2			= home_mod:get_guide_info(NewHome),
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= get_play_num(NewHome, Lv),
					Packet3			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
					Packet4			= home_mod:notice_daily_task_over(UserId),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary, Packet1/binary, 
															  Packet2/binary, Packet3/binary, Packet4/binary>>),
					player_api:exp(Player, Exp);
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipPacket			= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 检查是否能互动
check_play_with_girl(Home, Lv, Type, Grid) ->
	Girl			= Home#ets_home.girl,
	GrabInfo		= Girl#girl.grab_girl_info,
	
	State			= Girl#girl.state,
	Times			= Girl#girl.play_times,
	BeginTime		= case Type of
						  1 -> Girl#girl.play_begin_time;
						  2 -> 
							  BlackInfo		= element(Grid, GrabInfo),
							  BlackInfo#grab_girl_info.play_time
					  end,
	EndTime			= BeginTime + 4 * 3600,							%% TODO 互动cd4小时
	HasExp			= Girl#girl.play_exp,
	TotalExp		= ?FUN_HOME_TOTAL_EXP(Lv),
	try
		?ok		 	= check_play_girl_state(State),
		?ok		 	= check_play_times(Times),
		?ok		 	= check_play_cd(EndTime),
		?ok		 	= check_play_exp_max(HasExp, TotalExp)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

check_play_girl_state(State) when State =:= 2 -> throw({?error, ?TIP_HOME_CANNOT_PLAY1});
check_play_girl_state(_) -> ?ok.
%%-------------------------------------------------------------------------------------------------
%% 反抗
%%-------------------------------------------------------------------------------------------------
resist_by_self(Player) ->
	UserId			= Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Belonger		= Girl#girl.belonger,
			case check_resist(Home) of
				?ok ->					
					?MSG_DEBUG("~nresist_by_self: Belonger=~p", [Belonger]),
					case battle_api:start(Player, Belonger, #param{battle_type = ?CONST_BATTLE_HOME, ad4 = 4}) of
						{?ok, NewPlayer} ->
							BattleList			= [UserId, Belonger],
							NewGirl				= Girl#girl{battle_list = BattleList},
							NewHome				= Home#ets_home{girl = NewGirl},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							{?ok, NewPlayer};
						{?error, _} -> {?ok, Player}
					end;
				{?error, ErrorCode}->											  
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

%% 检查是否能够反抗
check_resist(Home) ->
	UserId			 = Home#ets_home.user_id,
	Girl			 = Home#ets_home.girl,
	State			 = Girl#girl.state,
	Belonger		 = Girl#girl.belonger,
	
	try
		?ok			= can_resist(State),
		?ok			= check_battle_self1(UserId, Belonger),
		?ok			= check_battle_state(UserId),
		?ok			= check_battle_state(Belonger)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.
		
%%　只有被抓捕者身份才能反抗
can_resist(State) when State =:= 2 -> ?ok;
can_resist(_) -> throw({?error, ?TIP_HOME_CANNOT_RESIST}).

check_battle_self1(UserId, UserId) -> throw({?error, ?TIP_BATTLE_OFF});
check_battle_self1(_, _) -> ?ok.
%%-------------------------------------------------------------------------------------------------
%% 邀请好友解救
%%-------------------------------------------------------------------------------------------------	
invite_friend(Player, OtherId) ->
	UserId				= Player#player.user_id,
	UserName			=(Player#player.info)#info.user_name,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_invite_friend(Home, OtherId) of
				?ok ->
					Girl			 = Home#ets_home.girl,
					Belonger		 = Girl#girl.belonger,
					case player_api:get_player_field(Belonger, #player.info) of
						{?ok, #info{user_name = BelongerName}} ->
							Power			= partner_api:caculate_camp_power(Belonger),
							Packet			= home_api:msg_sc_invite_friend(UserId, UserName, Belonger, BelongerName, Power),
							misc_packet:send(OtherId, Packet),
							OtherName		= case player_api:get_player_field(OtherId, #player.info) of
												  {?ok, #info{user_name = Name}} -> Name;
												  _ -> ""
											  end,
							TipPacket		= message_api:msg_notice(?TIP_HOME_INVITE_SUCCESS, [{?TIP_SYS_COMM, OtherName}]),
							misc_packet:send(Player#player.net_pid, TipPacket);
						_ ->						%% 获取角色信息失败
							TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
							misc_packet:send(Player#player.net_pid, TipPacket)
					end;
				{?error, ErrorCode} ->
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 检查邀请好友解救
check_invite_friend(Home, OtherId) ->
	UserId			 = Home#ets_home.user_id,
	Girl			 = Home#ets_home.girl,
	State			 = Girl#girl.state,
	Belonger		 = Girl#girl.belonger,
	Times			 = Girl#girl.rescue_times,
	try
		?ok			= check_can_invite(State),
		?ok			= check_friend(Belonger, OtherId),
		?ok			= check_rescue_times1(Times),
		?ok			= check_battle_state(UserId),
		?ok			= check_battle_state(Belonger),
		?ok			= check_battle_state(OtherId)
%% 		?ok         = update_battle_state(UserId),
%% 		?ok			= update_battle_state(Belonger)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 只有被抓捕者身份才能邀请好友解救
check_can_invite(State) when State =:= 2 -> ?ok;
check_can_invite(_) -> throw({?error, ?TIP_HOME_CANNOT_INVITE}).

check_rescue_times1(Times) when Times < ?CONST_HOME_RESCUE_TIMES -> ?ok;
check_rescue_times1(_) -> throw({?error, ?TIP_HOME_RESCUE_TIMES}).

%% 不能邀请自己的主人解救
check_friend(UserId, UserId) -> throw({?error, ?TIP_HOME_NOT_INVITE_BELONGER});
check_friend(_, _) -> ?ok.
	
invite_reply(Player, OtherId, 0) ->              %% 邀请拒绝解救
	UserName		 = (Player#player.info)#info.user_name,
	TipPacket		 = message_api:msg_notice(?TIP_HOME_REFUSE_INVITE, [{?TIP_SYS_COMM, UserName}]),
	misc_packet:send(OtherId, TipPacket),
	{?ok, Player};
invite_reply(Player, OtherId, 1) ->              %% 邀请同意解救
	UserId			= Player#player.user_id,
	case home_mod_create:get_home1(OtherId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Belonger		= Girl#girl.belonger,
			case check_agree_rescue(Home, OtherId) of
				?ok ->
					case battle_api:start(Player, Belonger, #param{battle_type = ?CONST_BATTLE_HOME, ad3 = OtherId, ad4 = 5}) of
						{?ok, NewPlayer} ->
							
							RescueTimes		= Girl#girl.rescue_times + 1,
							BattleList		= [UserId, OtherId, Belonger],
							NewGirl			= Girl#girl{rescue_times = RescueTimes,
														battle_list = BattleList},
							NewHome			= Home#ets_home{girl = NewGirl},
							ets_api:insert(?CONST_ETS_HOME, NewHome),
							{?ok, NewPlayer};
						{?error, ErrorCode} ->
							TipPacket		= message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player}
					end;
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end;
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

%% 检查是否能同意解救
check_agree_rescue(Home, OtherId) ->
	UserId			= Home#ets_home.user_id,
	Girl			= Home#ets_home.girl,
	State			= Girl#girl.state,
	Belonger		= Girl#girl.belonger,
	try
		?ok			= check_has_belonger(State, Belonger),
		?ok  		= check_battle_self1(UserId, Belonger),
		?ok         = update_battle_state(UserId),
		?ok         = update_battle_state(OtherId),
		?ok         = update_battle_state(Belonger)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.	

%% 检查是否已经不是奴隶
check_has_belonger(State, Belonger) when State =:= 2 andalso Belonger =/= 0 -> ?ok;
check_has_belonger(_, _) -> throw({?error, ?TIP_HOME_HAS_BELONGER}).
%%-------------------------------------------------------------------------------------------------
%% 请求解救好友列表
%%-------------------------------------------------------------------------------------------------	
get_rescue_friend(Player) ->
	UserId				= Player#player.user_id,
	FriendList			= relation_api:list_bilateral_friend(UserId),
	FriendList1			= filter_friend(FriendList, []),
	List				= get_rescue_friend_info(FriendList1, []),
	Packet				= home_api:msg_sc_rescue_list(List),
	misc_packet:send(Player#player.net_pid, Packet).

filter_friend([], Acc) -> Acc;
filter_friend([UserId|Tail], Acc) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			State			= Girl#girl.state,
			BattleState		= Girl#girl.battle,
			case {State, BattleState} of
				{2, 0}->
					Belonger		= Girl#girl.belonger,
					case player_api:get_player_field(Belonger, #player.info) of
						{?ok, #info{user_name = Name}} -> 
							Power			= partner_api:caculate_camp_power(Belonger),
							NewAcc			= [{UserId, Belonger, Name, Power}|Acc],
							filter_friend(Tail, NewAcc);
						_ -> 
							filter_friend(Tail, Acc)
					end;
				_ ->
					filter_friend(Tail, Acc)
			end;
		_ ->
			filter_friend(Tail, Acc)
	end.

%% 获取需解救好友的信息
get_rescue_friend_info([], Acc) -> Acc;
get_rescue_friend_info([{UserId, Belonger, BelongName, Power}|Tail], Acc) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{user_name = UserName, lv = UserLv, pro = Pro, sex = Sex}} ->
			NewAcc			= [{UserId, UserName, UserLv, Pro, Sex, Belonger, BelongName, Power}|Acc],
			get_rescue_friend_info(Tail, NewAcc);
		_ ->
			get_rescue_friend_info(Tail, Acc)
	end.
%%-------------------------------------------------------------------------------------------------
%% 解救好友
%%-------------------------------------------------------------------------------------------------	
rescue_friend(Player, OtherId) ->
	UserId				= Player#player.user_id,
	Belonger			= get_belonger_id(OtherId),
	case check_rescue(UserId, OtherId, Belonger) of
		 ?ok ->
			?MSG_DEBUG("~n rescue_friend=~p", [{OtherId, Belonger}]),
			case battle_api:start(Player, Belonger, #param{battle_type = ?CONST_BATTLE_HOME, ad3 = OtherId, ad4 = 6}) of
				{?ok, NewPlayer} ->
					case home_mod_create:get_home1(UserId) of
						Home when is_record(Home, ets_home) ->
							Girl			= Home#ets_home.girl,
							RescueTimes 	= Girl#girl.rescue_times + 1,
							BattleList		= [UserId, Belonger, OtherId],
							NewGirl			= Girl#girl{rescue_times = RescueTimes,
														 battle_list = BattleList},
							NewHome			= Home#ets_home{girl = NewGirl},
							ets_api:insert(?CONST_ETS_HOME, NewHome);
						_ -> ?ok
					end,
					{?ok, NewPlayer};
				{?error, ErrorCode} ->
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		{?error, ErrorCode} ->
			TipPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 检查是否能够帮助解救
check_rescue(UserId, OtherId, Belonger) ->
	?MSG_DEBUG("~ncheck_rescue~p~n", [{UserId, OtherId, Belonger}]),
	try
		?ok		 = check_rescue_times(UserId),
		?ok		 = check_friend1(Belonger, UserId),
		?ok		 = check_rescue_state(UserId),
		?ok		 = check_battle_state(UserId),
		?ok		 = check_battle_state(OtherId),
		?ok		 = check_battle_state(Belonger),
		?ok		 = update_battle_state(UserId),
		?ok		 = update_battle_state(OtherId),
		?ok		 = update_battle_state(Belonger)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查是否有解救次数
check_rescue_times(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl		= Home#ets_home.girl,
			Times		= Girl#girl.rescue_times,
			case Times < 3 of
				?true  -> ?ok;
				?false ->
					throw({?error, ?TIP_HOME_RESCUE_TIMES})
			end;
		_ ->
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%% 只有自由身或抓捕者身份才能解救
check_rescue_state(UserId) ->
	case get_user_state(UserId) of
		2 -> throw({?error, ?TIP_HOME_CANNOT_RESCUE});
		_ -> ?ok
	end.

%% 不能解救自己抓捕的奴隶
check_friend1(UserId, UserId) -> throw({?error, ?TIP_HOME_RESCU_SELF});
check_friend1(_, _) -> ?ok.
%%-------------------------------------------------------------------------------------------------
%% 请求小黑屋侍女信息
%%-------------------------------------------------------------------------------------------------
get_black_info(Player) ->
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	Lv				= (Player#player.info)#info.lv,
	Now				= misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			GrabInfo		= Girl#girl.grab_girl_info,
			GrabList		= misc:to_list(GrabInfo),
			
			F = fun(Grab, Acc) when (is_record(Grab, grab_girl_info)) andalso Grab#grab_girl_info.state =:= 2 ->
						OwnerId			= Grab#grab_girl_info.owner_id,
						Name			= Grab#grab_girl_info.owner_name,
						EndTime			= Grab#grab_girl_info.end_time,
						Pos				= Grab#grab_girl_info.pos,
						case EndTime < Now of
							?true  ->                            %% 系统释放奴隶
								Message				= Home#ets_home.message,
								InterList			= Message#message.interinfo,
								NewInterInfo		= add_inter_info(InterList, 27, Name, "", 0, 0),
								NewMessage			= Message#message{interinfo = NewInterInfo},
								
								update_release_user_info2(OwnerId, UserName),
								Packet5				= home_api:msg_sc_inter_info(28, UserName, "", 0, 0),
								misc_packet:send(OwnerId, Packet5),
								
								BlackInfo			= #grab_girl_info{pos = Pos, state = 1},			  %% 更改小黑屋信息
								NewGrabInfo			= erlang:setelement(Pos, GrabInfo, BlackInfo),
								
								Ids					= Girl#girl.source_list,
%% 								NewIds				= lists:usort([OwnerId|Ids]),
								SourceList			= get_source_list([OwnerId|Ids], UserId),
%% 								SourceList			= get_source_list1(NewIds, []),
								NewGirl				= Girl#girl{source_list = SourceList, 
																grab_girl_info = NewGrabInfo},
								NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
								ets_api:insert(?CONST_ETS_HOME, NewHome),
								Acc;
							?false ->
								
								OwnerLv				= Grab#grab_girl_info.owner_lv,
								GirlId				= Grab#grab_girl_info.id,
								Pro					= Grab#grab_girl_info.owner_pro,
								InterTime			= Grab#grab_girl_info.play_time,
								Power				= case OwnerId  of
														  ?CONST_SYS_FALSE  -> ?CONST_SYS_FALSE;
														  _ -> partner_api:caculate_camp_power(OwnerId)
													  end,
								
								Exp					= calc_get_exp(Home, Pos, Lv),
								InterCd				= case InterTime of
														  0 ->  0;
														  _ -> InterTime + 4 * 3600
													  end,
								[{OwnerId, Name, OwnerLv,  GirlId, Pos, Pro, Power, EndTime, Exp, InterCd}|Acc]
						end;
				   (_, Acc) ->
						Acc
				end,
			BlackList		= lists:foldl(F, [], GrabList),
			State			= get_user_state(UserId),
			case home_mod_create:get_home1(UserId) of
				Home2 when is_record(Home2, ets_home) ->
					Girl2			= Home2#ets_home.girl,
					NewGirl2		= Girl2#girl{state = State},
					NewHome2		= Home#ets_home{girl = NewGirl2},
					ets_api:insert(?CONST_ETS_HOME, NewHome2);
				_ -> ?ok
			end,
			Packet			= home_api:msg_sc_black_info(BlackList),
			{GrabTimes, PlayTimes, RescueTimes, NewExp} = get_play_num(Home, Lv),
			Packet1			= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, NewExp),
%% 			Packet2			= home_api:msg_sc_inter_info(27, UserName, "", 0, 0),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
		_ ->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipsPacket)
	end.

%% 获取玩法次数和经验
get_play_num(Home, Lv) ->
	TotalExp		= ?FUN_HOME_TOTAL_EXP(Lv),
	Girl			= Home#ets_home.girl,
	GrabTimes		= Girl#girl.grab_num,
	PlayTimes		= 6 - Girl#girl.play_times,
	RescueTimes		= 3 - Girl#girl.rescue_times,
	HasExp			= TotalExp - Girl#girl.play_exp,
	PlayTimes1		= case PlayTimes < 0 of
						  ?true -> ?CONST_SYS_FALSE;
						  _ -> PlayTimes
					  end,
	RescueTimes1	= case RescueTimes < 0 of
						  ?true -> ?CONST_SYS_FALSE;
						  _ -> RescueTimes
					  end,
	HasExp1			= case HasExp < 0 of
						  ?true -> ?CONST_SYS_FALSE;
						  _ -> HasExp
					  end,
	?MSG_DEBUG("TotalExp=~pHasExp=~pHasExp1=~p", [TotalExp, HasExp, HasExp1]),
	{GrabTimes, PlayTimes1, RescueTimes1, HasExp1}.

press_draw_girl(Player, 0, Grid) -> press_girl(Player, Grid);
press_draw_girl(Player, 1, Grid) -> draw_girl(Player, Grid);
press_draw_girl(Player, 2, Grid) -> get_exp_self(Player, Grid).
%%-------------------------------------------------------------------------------------------------
%% 压榨
%%-------------------------------------------------------------------------------------------------
press_girl(Player, Grid) when Grid < 1 orelse Grid > 3 -> {?ok, Player};	
press_girl(Player, Grid) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			case check_play_girl(Home, Grid, Lv) of
				?ok ->
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, 10, ?CONST_COST_PRESS_GIRL) of
						?ok ->
							Exp			= ?FUN_HOME_TEN_EXP(Lv) * 6,
							HasExp		= Girl#girl.play_exp,
							Exp1		= calc_add_exp(HasExp, Exp, Lv),
							HasExp1		= HasExp + Exp1,
							press_gril_ext(Home, Grid, HasExp1, Lv, Exp1),
							player_api:exp(Player, Exp1);
						{?error, ErrorCode} ->
							TipPacket			= message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player}
					end;
				{?error, ErrorCode} ->
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.
			
%% 检查是否能压榨和抽取
check_play_girl(Home, Grid, Lv) ->
	Girl			= Home#ets_home.girl,
	HasExp			= Girl#girl.play_exp,
	TotalExp		= ?FUN_HOME_TOTAL_EXP(Lv),
	GrabInfo	 	= Girl#girl.grab_girl_info,
	?MSG_DEBUG("~n GrabInfo=~p~n", [GrabInfo]),
	GrabGirl		= erlang:element(Grid, GrabInfo),
	Lv1				= GrabGirl#grab_girl_info.owner_lv,
	try
		?ok		 = check_girl_exist(GrabGirl),
		?ok		 = check_press_time(GrabGirl),
		?ok		 = check_play_exp_max(HasExp, TotalExp),
		?ok      = check_lv(Lv, Lv1)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查此名仕女是否已逃跑
check_girl_exist(GrabGirl) when is_record(GrabGirl, grab_girl_info)-> ?ok;
check_girl_exist(Info) -> 
	?MSG_DEBUG("~n check_girl_exist=~p", [Info]),
	throw({?error, ?TIP_HOME_GIRL_NOT_EXSIT}).      		%%仕女已不在

%% 检查侍女是否还有压榨时间
check_press_time(GrabGirl) ->
	EndTime				= GrabGirl#grab_girl_info.end_time,
	Now					= misc:seconds(),
	case EndTime < Now of
		?true  -> throw({?error, ?TIP_HOME_PRESS_TIME});
		?false -> ?ok
	end.

%% 检查是否领取上限
check_play_exp_max(HasExp, Exp) when HasExp < Exp -> ?ok;
check_play_exp_max(_, _) -> throw({?error, ?TIP_HOME_GET_EXP_MAX}).

%% 检查等级差
check_lv(Lv, Lv1) when Lv - Lv1 >= 10 -> throw({?error, ?TIP_HOME_LV_NOT_ENOUGH});
check_lv(_, _) -> ?ok.


%% 压榨后更新格子信息
press_gril_ext(Home, Grid, HasExp, Lv, Exp1) ->
	UserId			= Home#ets_home.user_id,
	Girl			= Home#ets_home.girl,
	BlackInfo		= Girl#girl.grab_girl_info,
	GrabInfo		= erlang:element(Grid, BlackInfo),
	EndTime			= GrabInfo#grab_girl_info.end_time,
	Now				= misc:seconds(),
	NewTime			= Now + ?CONST_SYS_NUMBER_SIXTY * ?CONST_SYS_NUMBER_SIXTY,						%% 1小时
	Message			= Home#ets_home.message,
	InterList		= Message#message.interinfo,
	OtherName		= GrabInfo#grab_girl_info.owner_name,
	NewInterInfo	= add_inter_info(InterList, 25, OtherName, "", 0, Exp1),
	NewMessage		= Message#message{interinfo = NewInterInfo},
	Packet			= home_api:msg_sc_inter_info(25, OtherName, "", 0, Exp1),
	TipPacket		= message_api:msg_notice(?TIP_HOME_PRESS_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp1)}]),
	case NewTime < EndTime of						%% 侍女还有保存时间
		?true ->
			NewEndTime			= EndTime - 3600,
			NewGrabInfo			= GrabInfo#grab_girl_info{end_time = NewEndTime},
			NewBlackInfo		= erlang:setelement(Grid, BlackInfo, NewGrabInfo),
			NewGirl				= Girl#girl{grab_girl_info = NewBlackInfo, play_exp = HasExp},
			NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			{GrabTimes, PlayTimes, RescueTimes, NewExp} 
								= get_play_num(NewHome, Lv),
			
			
			Packet1				= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, NewExp),
			misc_packet:send(UserId, <<Packet/binary, Packet1/binary, TipPacket/binary>>);
		?false ->                                   %% 奴隶释放并进入到推荐列表
			OwnerId				= GrabInfo#grab_girl_info.owner_id,
			update_release_user_info(OwnerId),
			
			NewGrabInfo			= #grab_girl_info{pos = Grid, state = 1},
			NewBlackInfo		= erlang:setelement(Grid, BlackInfo, NewGrabInfo),
			
			Ids					= Girl#girl.source_list,
%% 			NewIds				= lists:usort([OwnerId|Ids]),
%% 			SourceList			= get_source_list1(NewIds, []),
			SourceList			= get_source_list([OwnerId|Ids], UserId),
			State				= get_release_girl_state(NewBlackInfo),
			NewGirl				= Girl#girl{grab_girl_info = NewBlackInfo, play_exp = HasExp,
											source_list = SourceList, state = State},
			NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			{GrabTimes, PlayTimes, RescueTimes, NewExp} 
								= get_play_num(NewHome, Lv),
			Packet1				= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, NewExp),
			Packet2				= get_main_black_info(NewBlackInfo),
			misc_packet:send(UserId, <<Packet/binary, Packet1/binary, Packet2/binary, TipPacket/binary>>)
	end.

%% 计算实际获得经验
calc_add_exp(HasExp, Exp, Lv) ->
	TotalExp			= ?FUN_HOME_TOTAL_EXP(Lv),
	case HasExp + Exp > TotalExp of
		?true  -> TotalExp - HasExp;
		?false -> Exp
	end.

%% 更新被释放的奴隶的信息
update_release_user_info(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{state = 0, battle = 0, belonger = 0},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			home_db_mod:update_home(NewHome),
			Packet1			= home_api:msg_sc_user_state(UserId, 0),
			misc_packet:send(UserId, Packet1),
			?ok;
		_ ->
			?ok
	end.
%% 手动释放更新奴隶信息
update_release_user_info1(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message				= Home#ets_home.message,
			InterList			= Message#message.interinfo,
			
			Girl				= Home#ets_home.girl,
			BelongerId			= Girl#girl.belonger,
			BelongerName		= player_api:get_name(BelongerId),

			NewGirl				= Girl#girl{state = 0, battle = 0, belonger = 0},

			NewInterInfo		= add_inter_info(InterList, 30, BelongerName, "", 0, 0),
			NewMessage			= Message#message{interinfo = NewInterInfo},
			
			NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			home_db_mod:update_home(NewHome),
			Packet1			= home_api:msg_sc_user_state(UserId, 0),
			misc_packet:send(UserId, Packet1),
			?ok;
		_ ->
			?ok
	end.
%% 系统释放更新奴隶信息
update_release_user_info2(UserId, OtherName) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message				= Home#ets_home.message,
			InterList			= Message#message.interinfo,
			
			Girl				= Home#ets_home.girl,

			NewGirl				= Girl#girl{state = 0, battle = 0, belonger = 0},

			NewInterInfo		= add_inter_info(InterList, 28, OtherName, "", 0, 0),
			NewMessage			= Message#message{interinfo = NewInterInfo},
			
			NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			home_db_mod:update_home(NewHome),
			Packet1			= home_api:msg_sc_user_state(UserId, 0),
			misc_packet:send(UserId, Packet1),
			?ok;
		_ ->
			?ok
	end.


%%-------------------------------------------------------------------------------------------------
%% 抽取
%%-------------------------------------------------------------------------------------------------
draw_girl(Player, Grid) when Grid < 1 orelse Grid > 3 -> {?ok, Player};
draw_girl(Player, Grid) ->
	UserId			= Player#player.user_id,
	Lv				= (Player#player.info)#info.lv,
	case home_mod_create:get_home(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_play_girl(Home, Grid, Lv) of
				?ok ->
					Value			=	misc:ceil((calc_draw_time(Home, Grid)/3600)) * 10,
					case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Value, ?CONST_COST_DRAW_GIRL) of
						?ok ->
							Message				= Home#ets_home.message,
							InterList			= Message#message.interinfo,
							
							Girl				= Home#ets_home.girl,
							BlackInfo			= Girl#girl.grab_girl_info,
							GrabInfo			= erlang:element(Grid, BlackInfo),
							OtherName			= GrabInfo#grab_girl_info.owner_name,
							
							OwnerId				= GrabInfo#grab_girl_info.owner_id,
							update_release_user_info(OwnerId),
							
							HasExp				= Girl#girl.play_exp,
							Exp					= calc_draw_exp(Home, Grid, Lv),
							Exp1				= calc_add_exp(HasExp, Exp, Lv),
							NewInterInfo		= add_inter_info(InterList, 26, OtherName, "", 0, Exp1),
							NewMessage			= Message#message{interinfo = NewInterInfo},
							
							Packet				= home_api:msg_sc_inter_info(26, OtherName, "", 0, Exp1),
							Packet1				= message_api:msg_notice(?TIP_HOME_DRAW_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp1)}]),
							misc_packet:send(Player#player.user_id, <<Packet/binary, Packet1/binary>>),
							
							HasExp1				= HasExp + Exp1,
							draw_girl(Home, Grid, HasExp1, Lv, NewMessage),
							player_api:exp(Player, Exp1);
						{?error, ErrorCode} ->
							TipPacket			= message_api:msg_notice(ErrorCode),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{?ok, Player}
					end;
				{?error, ErrorCode} ->
					TipPacket		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 计算抽取的时间
calc_draw_time(Home, Grid) ->
	Girl				= Home#ets_home.girl,
	BlackInfo			= Girl#girl.grab_girl_info,
	GrabInfo			= erlang:element(Grid, BlackInfo),
	EndTime				= GrabInfo#grab_girl_info.end_time,
	Now					= misc:seconds(),
	EndTime - Now.
%% 计算抽取的经验
calc_draw_exp(Home, Grid, Lv) ->
	LeftTime			= calc_draw_time(Home, Grid),
	misc:floor((LeftTime / 600)) * ?FUN_HOME_TEN_EXP(Lv).

%% 抽取经验后处理
draw_girl(Home, Grid, HasExp, Lv, Message) ->
	UserId				= Home#ets_home.user_id,
	Girl				= Home#ets_home.girl,
	BlackInfo			= Girl#girl.grab_girl_info,
	GrabInfo			= erlang:element(Grid, BlackInfo),
	OwnerId				= GrabInfo#grab_girl_info.owner_id,
	
	NewGrabInfo			= #grab_girl_info{pos = Grid, state = 1},
	NewBlackInfo		= erlang:setelement(Grid, BlackInfo, NewGrabInfo),
	?MSG_DEBUG("~n draw_girl=~p", [NewBlackInfo]),
	
	Ids					= Girl#girl.source_list,
%% 	NewIds				= lists:usort([OwnerId|Ids]),
%% 	SourceList			= get_source_list1(NewIds, []),
	SourceList			= get_source_list([OwnerId|Ids], UserId),
	State				= get_release_girl_state(NewBlackInfo),
	NewGirl				= Girl#girl{grab_girl_info = NewBlackInfo, play_exp = HasExp,
									source_list = SourceList, state = State},
	NewHome				= Home#ets_home{girl = NewGirl, message = Message},
	ets_api:insert(?CONST_ETS_HOME, NewHome),
	
	{GrabTimes, PlayTimes, RescueTimes, NewExp} 
						= get_play_num(NewHome, Lv),
	Packet				= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, NewExp),
	Packet1				= get_main_black_info(NewBlackInfo),
	misc_packet:send(UserId, <<Packet/binary, Packet1/binary>>).
	
%% ------------------------------------------------------------------------------------------------
%% 手动提取经验
%% ------------------------------------------------------------------------------------------------
get_exp_self(Player, Grid)  when Grid < 1 orelse Grid > 3 -> 
	TipPacket			= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	{?ok, Player};
get_exp_self(Player, Grid) ->
	UserId				= Player#player.user_id,
	Lv					= (Player#player.info)#info.lv,
	Now					= misc:seconds(),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_get_exp(Home, Grid, Lv) of
				?ok ->
					Message				= Home#ets_home.message,
					InterList			= Message#message.interinfo,
					
					Girl				= Home#ets_home.girl,
					BlackInfo			= Girl#girl.grab_girl_info,
					GrabInfo			= element(Grid, BlackInfo),
					OtherName			= GrabInfo#grab_girl_info.owner_name,
					NewGrabInfo			= GrabInfo#grab_girl_info{get_exp_time = Now},
					NewBlackInfo		= erlang:setelement(Grid, BlackInfo, NewGrabInfo),
					Exp					= calc_get_exp(Home, Grid, Lv),
					
					NewInterInfo		= add_inter_info(InterList, 24, OtherName, "", 0, Exp),
					NewMessage			= Message#message{interinfo = NewInterInfo},
					HasExp				= Girl#girl.play_exp + Exp,
					NewGirl				= Girl#girl{grab_girl_info = NewBlackInfo, play_exp = HasExp},
					NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					{GrabTimes, PlayTimes, RescueTimes, NewExp} 
										= get_play_num(NewHome, Lv),
					
					Packet				= home_api:msg_sc_play_num(GrabTimes, PlayTimes, RescueTimes, NewExp),
					Packet1				= home_api:msg_sc_inter_info(24, OtherName, "", 0, Exp),
					TipPacket			= message_api:msg_notice(?TIP_HOME_GET_BLACK_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),
					
					misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary, Packet1/binary>>),
					player_api:exp(Player, Exp);
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end.

%% 检查是否能提取经验
check_get_exp(Home, Grid, Lv) ->
	try
		case check_play_girl(Home, Grid, Lv) of
			{?error, ErrorCode} -> throw({?error, ErrorCode});
			?ok -> ?ok
		end,
		?ok			 = check_has_exp(Home, Grid, Lv),
		?ok			 = check_get_exp_cd(Home, Grid)
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查提取经验cd
check_get_exp_cd(Home, Grid) ->
	Girl				= Home#ets_home.girl,
	BlackInfo			= Girl#girl.grab_girl_info,
	GrabInfo			= element(Grid, BlackInfo),
	BeginTime			= GrabInfo#grab_girl_info.get_exp_time,
	case BeginTime of
		0 -> ?ok;
		_ ->
			EndTime				= BeginTime + 10 * ?CONST_SYS_NUMBER_SIXTY,
			Now					= misc:seconds(),
			case EndTime < Now of
				?true  -> ?ok;
				?false ->
					throw({?error, ?TIP_HOME_GET_EXP})
			end
	end.

%% 检查能提取的经验是否大于0
check_has_exp(Home, Grid, Lv) ->
	Exp					= calc_get_exp(Home, Grid, Lv),
	case Exp > 0 of
		?true  -> ?ok;
		?false -> throw({?error, ?TIP_HOME_GET_EXP})
	end.

%% 计算能提取的实际经验
calc_get_exp(Home, Grid, Lv) ->
	Girl				= Home#ets_home.girl,
	HasExp				= Girl#girl.play_exp,
	BlackInfo			= Girl#girl.grab_girl_info,
	?MSG_DEBUG("~n BlackInfo=~p", [BlackInfo]),
	case element(Grid, BlackInfo) of
		GrabInfo when is_record(GrabInfo, grab_girl_info) ->
			BeginTime			= case GrabInfo#grab_girl_info.get_exp_time of
									  0 -> GrabInfo#grab_girl_info.start_time;
									  _ -> GrabInfo#grab_girl_info.get_exp_time
								  end,
			Now					= misc:seconds(),
			Exp					= misc:floor((Now - BeginTime)/600) * ?FUN_HOME_TEN_EXP(Lv),
			TotalExp			= ?FUN_HOME_TOTAL_EXP(Lv),
			case HasExp >= TotalExp of
				?true  -> ?CONST_SYS_FALSE;
				?false ->
					case HasExp + Exp < TotalExp of
						?true  -> Exp;
						?false -> TotalExp - Exp
					end
			end;
		_ -> ?CONST_SYS_FALSE
	end.
%% ------------------------------------------------------------------------------------------------
%% 手动释放奴隶
%% ------------------------------------------------------------------------------------------------
release_girl_self(Player, Grid)  when Grid < 1 andalso Grid > 3 -> 
	TipPacket			= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket);
release_girl_self(Player, Grid) ->
	UserId			= Player#player.user_id,
	UserName		=(Player#player.info)#info.user_name,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			case check_release_girl(Home, Grid) of
				?ok ->
					Message				= Home#ets_home.message,
					InterList			= Message#message.interinfo,
					
					
					Girl				= Home#ets_home.girl,
					BlackInfo			= Girl#girl.grab_girl_info,
					GrabInfo			= erlang:element(Grid, BlackInfo),
					
					OwnerId				= GrabInfo#grab_girl_info.owner_id,					 %% 更改奴隶的状态
					OwnerName			= GrabInfo#grab_girl_info.owner_name,				 
					update_release_user_info1(OwnerId),
					
					NewGrabInfo			= #grab_girl_info{pos = Grid, state = 1},			  %% 更改小黑屋信息
					NewBlackInfo		= erlang:setelement(Grid, BlackInfo, NewGrabInfo),
					
					Ids					= Girl#girl.source_list,                               %% 添加到推荐列表中
%% 					NewIds				= lists:usort([OwnerId|Ids]),
%% 					SourceList			= get_source_list1(NewIds, []),
					SourceList			= get_source_list([OwnerId|Ids], UserId),
					State				= get_release_girl_state(NewBlackInfo),
					
					NewInterInfo		= add_inter_info(InterList, 29, OwnerName, "", 0, 0),				%% 添加释放信息
					NewMessage			= Message#message{interinfo = NewInterInfo},
					
					NewGirl				= Girl#girl{grab_girl_info = NewBlackInfo, source_list = SourceList,
													state = State},
					NewHome				= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					
					Packet				= home_api:msg_sc_release_girl(Grid),
					Packet1				= get_main_black_info(NewBlackInfo),
					Packet2				= home_api:msg_sc_inter_info(29, OwnerName, "", 0, 0),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, Packet2/binary>>),
					
					Packet5				= home_api:msg_sc_inter_info(30, UserName, "", 0, 0),
					misc_packet:send(OwnerId, Packet5);
				{?error, ErrorCode} ->
					TipPacket			= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end;
		_ ->
			TipPacket			= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%% 检查能否释放侍女
check_release_girl(Home, Grid) ->
	Girl			= Home#ets_home.girl,
	GrabGirl		= Girl#girl.grab_girl_info,
	GrabInfo		= erlang:element(Grid, GrabGirl),
	OwnerId			= GrabInfo#grab_girl_info.owner_id,
	try
		?ok			 = check_girl_exist(GrabInfo),					%% 侍女是否存在
		?ok			 = check_in_grab(OwnerId)						%% 侍女是否在被抢夺
	catch
		throw:Msg ->
			Msg;
		Type:Why ->
			?MSG_PRINT("~n Type=~p, Why=~p, strace=~p", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 侍女是否在被抢夺
check_in_grab(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			BattleState		= Girl#girl.battle,
			case BattleState of
				0 -> ?ok;
				_ -> throw({?error, ?TIP_HOME_CANNOT_RELEASE})
			end;
		_ ->
			throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%% 获取新的小黑屋信息
get_main_black_info(GrabInfo) ->
	GrabList		= misc:to_list(GrabInfo),
	
	F = fun(Grab, Acc) when (is_record(Grab, grab_girl_info)) andalso Grab#grab_girl_info.state =:= 2 ->
				EndTime     		= Grab#grab_girl_info.end_time,
				OwnerId				= Grab#grab_girl_info.owner_id,
				
				Name				= Grab#grab_girl_info.owner_name,
				OwnerLv				= Grab#grab_girl_info.owner_lv,
				GirlId				= Grab#grab_girl_info.id,
				Pos					= Grab#grab_girl_info.pos,
				Pro					= Grab#grab_girl_info.owner_pro,
				
				[{Pos, GirlId, OwnerId,  Name, OwnerLv, Pro, EndTime}|Acc];
		   (_, Acc) ->
				Acc
		end,
	BlackList		= lists:foldl(F, [], GrabList),
	home_api:msg_sc_main_balack(BlackList).
%% ------------------------------------------------------------------------------------------------
%% 展示侍女
%% ------------------------------------------------------------------------------------------------
show_girl(Player, Id) ->
	UserId			= Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{show_girl = Id},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ -> 
			TipPacket			= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.
%% Local Functions
%%
%% 获取玩家状态
get_user_state(Home) when is_record(Home, ets_home) ->
	Girl			= Home#ets_home.girl,
	Belonger		= Girl#girl.belonger,
	BlackList		= misc:to_list(Girl#girl.grab_girl_info),
	BlackNum		= cal_black_has(BlackList, 0),
	?MSG_DEBUG("get_user_state:~n Belonger=~p, BlackNum=~p", [Belonger, BlackNum]),
	if
		BlackNum =/= 0 andalso Belonger =:= 0 -> 1;
		BlackNum =:= 0 andalso Belonger =/= 0 -> 2;
		BlackNum =:= 0 andalso Belonger =:= 0 -> 0;
		BlackNum =/= 0 andalso Belonger =/= 0 ->
			GrabGirl   		= erlang:make_tuple(?CONST_HOME_GRID_MAX, ?CONST_SYS_FALSE, []),
			F	= fun(Num, Acc) ->															       %% 更改小黑屋数据
						  GrabInfo	= #grab_girl_info{pos = Num, state = 1},
						  erlang:setelement(Num, Acc, GrabInfo)
				  end,
			GrabGirlInfo	= lists:foldl(F, GrabGirl, lists:seq(?CONST_SYS_TRUE, ?CONST_HOME_GRID_MAX)),	
			NewGirl			= Girl#girl{grab_girl_info = GrabGirlInfo},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			2;
		?true ->
			?MSG_ERROR("~n State Error :", []),
			0
	end;
get_user_state(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Belonger		= Girl#girl.belonger,
			BlackList		= misc:to_list(Girl#girl.grab_girl_info),
			BlackNum		= cal_black_has(BlackList, 0),
			?MSG_DEBUG("get_user_state:~n Belonger=~p, BlackNum=~p", [Belonger, BlackNum]),
			if
				BlackNum =/= 0 andalso Belonger =:= 0 -> 1;
				BlackNum =:= 0 andalso Belonger =/= 0 -> 2;
				BlackNum =:= 0 andalso Belonger =:= 0 -> 0;
				BlackNum =/= 0 andalso Belonger =/= 0 ->
					GrabGirl   		= erlang:make_tuple(?CONST_HOME_GRID_MAX, ?CONST_SYS_FALSE, []),
					F	= fun(Num, Acc) ->															       %% 更改小黑屋数据
								  GrabInfo	= #grab_girl_info{pos = Num, state = 1},
								  erlang:setelement(Num, Acc, GrabInfo)
						  end,
					GrabGirlInfo	= lists:foldl(F, GrabGirl, lists:seq(?CONST_SYS_TRUE, ?CONST_HOME_GRID_MAX)),	
					NewGirl			= Girl#girl{grab_girl_info = GrabGirlInfo},
					NewHome			= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome),
					2;
			?true ->
				?MSG_ERROR("~n State Error :", []),
				0
			end;
		_ ->
			?MSG_ERROR("~n State Error :", []),
			0
	end.

%% 获取玩家战斗状态
get_user_battle_state(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Girl#girl.battle;
		_ ->
			0
	end.

%% 获取玩家主人id
get_belonger_id(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Girl#girl.belonger;
		_ ->
			0
	end.

%% 更新玩家战斗状态
update_user_battle_state(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_TRUE},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
update_user_battle_state1(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE},
			NewHome			= Home#ets_home{girl = NewGirl},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.

%% 获取奴隶主下最高等级的奴隶
get_top_slaver_id(UserId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			get_top_slaver_id1(misc:to_list(BlackInfo), 0);
		_ ->
			0
	end.

get_top_slaver_id1([], Acc) -> Acc;
get_top_slaver_id1([BlackInfo|Tail], Acc) when is_record(BlackInfo, grab_girl_info)->
	UserId		= BlackInfo#grab_girl_info.owner_id,
	Lv			= BlackInfo#grab_girl_info.owner_lv,
	case Lv > Acc of
		?true  ->
			get_top_slaver_id1(Tail, UserId);
		?false ->
			get_top_slaver_id1(Tail, Acc)
	end;
get_top_slaver_id1([_|Tail], Acc) ->
	get_top_slaver_id1(Tail, Acc).

%% 获取奴隶主释放奴隶后的状态
get_release_girl_state(BlackList) when is_list(BlackList) ->
	BlackNum		= cal_black_has(BlackList, 0),
	case BlackNum of
		?CONST_SYS_FALSE -> 0;
		_ -> ?CONST_SYS_TRUE
	end;
get_release_girl_state(BlackInfo) ->
	BlackNum		= cal_black_has(misc:to_list(BlackInfo), 0),
	case BlackNum of
		?CONST_SYS_FALSE -> 0;
		_ -> ?CONST_SYS_TRUE
	end.

%% 互动获得经验奖励通知
msg_notice_get_exp(Exp) when Exp > 0 ->
	message_api:msg_notice(?TIP_HOME_PLAY_WITH_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp)}]);
msg_notice_get_exp(_) -> <<>>.

%% 增加互动信息
add_inter_info(List, Id, UserName, UserName1, SkillId, Value) ->
	Len			= erlang:length(List),
	case Len >= 20 of
		?true ->    %% 超过20条的记录，把最早的记录删除
			[_Head|RestList]	= List,
			RestList ++ [{Id, UserName, UserName1, SkillId, Value}];
		?false ->
			List ++ [{Id, UserName, UserName1, SkillId, Value}]
	end.

%% 获取仕女互动剩余次数
get_girl_times(Player) ->
	UserId			= Player#player.user_id,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			PlayTimes		= Girl#girl.play_times,
			?CONST_HOME_PLAY_TIMES - PlayTimes;
		_ ->
			?CONST_SYS_FALSE
	end.

%% 竞技场增加手下败将
add_source_list(UserId, OtherId) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl				= Home#ets_home.girl,
			OldSourceList		= Girl#girl.source_list,
			case lists:member(OtherId, OldSourceList) of
				?true  -> ?ok;
				?false ->
					NewSourceList		= get_single_source_list([OtherId|OldSourceList], []),
					NewGirl				= Girl#girl{source_list = NewSourceList},
					NewHome				= Home#ets_home{girl = NewGirl},
					ets_api:insert(?CONST_ETS_HOME, NewHome)
			end;
		_ ->
			?ok
	end.

get_single_source_list([], Acc) -> Acc;
get_single_source_list([UserId|Tail], Acc) ->
	Len				= length(Acc),
	case Len > 10 of
		?true  ->
			get_single_source_list([], Acc);
		?false ->
			NewAcc		= Acc ++ [UserId],
			get_single_source_list(Tail, NewAcc)
	end.	

%% 计算推荐的数量
cal_rec_has([Recommend|RestList], Acc) when Recommend#recommend_list.state =:= 2 ->
	NewAcc	= Acc + 1,
	cal_rec_has(RestList, NewAcc);
cal_rec_has([_|RestList], Acc) ->
	cal_rec_has(RestList, Acc);
cal_rec_has([], Acc) ->
	Acc.