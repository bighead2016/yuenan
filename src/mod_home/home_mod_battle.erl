%% Author: Administrator
%% Created: 2012-11-1
%% Description: TODO: Add description to home_mod_battle
-module(home_mod_battle).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.battle.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.home.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([battle_over/2, do_battle_over/2]).

%%
%% API Functions
%%
battle_over(_, {UserId, UserId, _}) -> ?ok;
battle_over(Result, {UserId, GrabedId, Param}) ->
	case player_api:get_player_pid(UserId) of
		Pid when is_pid(Pid) ->
			player_api:process_send(Pid, ?MODULE, do_battle_over, [Result, GrabedId, Param]);
		_ ->
			?ok
	end.

do_battle_over(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId, Param]) ->
	BattleType = Param#param.ad4,
	case BattleType of
		4 -> 
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over2(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId]);
		5 ->
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over3(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId, Param]);
		6 ->
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over4(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId, Param]);
		Info ->
			?MSG_ERROR("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [Info, GrabedId]),
			do_battle_over1(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId, Param])
	end;
do_battle_over(Player, [_, GrabedId, Param]) ->
	BattleType = Param#param.ad4,
	case BattleType of
		4 -> 
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over2(Player, [GrabedId]);
		5 ->
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over3(Player, [GrabedId, Param]);
		6 ->
			?MSG_DEBUG("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [BattleType, GrabedId]),
			do_battle_over4(Player, [GrabedId, Param]);
		Info ->
			?MSG_ERROR("~n do_battle_over: BattleType=~p GrabedId=~p, ~n", [Info, GrabedId]),
			do_battle_over1(Player, [GrabedId, Param])
	end.

%% ------------------------------------------------------------------------------------------------
%% 抢夺  1推荐2仇人
%% ------------------------------------------------------------------------------------------------
do_battle_over1(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId, Param])->	 %% 抢夺者胜利 type:1推荐2仇人
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	GrabedId1		= Param#param.ad3,
	BattleType		= Param#param.ad4,
	Type			= Param#param.ad1,
	Grid			= Param#param.ad2,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Recommend   	= Girl#girl.recommend_list,
			Enemy			= Girl#girl.enemy_list,
			BlackInfo		= chang_black_info(Home, GrabedId1),
			RecommendList	= change_winner_recommend(misc:to_list(Recommend), GrabedId, Type, Grid),
			EnemyList		= change_winer_enemy(UserId, misc:to_list(Enemy), GrabedId, Type, Grid),
			NewRecommend	= misc:to_tuple(RecommendList),
			NewEnemy		= misc:to_tuple(EnemyList),
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, 
										grab_girl_info = BlackInfo, state = 1,
										recommend_list = NewRecommend,
										enemy_list = NewEnemy, grab_begin_time = 0,
										battle_list = []},
			
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		=  player_api:get_name(GrabedId1),
			
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 1, OtherName, "", 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Packet			= home_api:msg_sc_inter_info(1, OtherName, "", 0, 0),
			Packet1			= home_mod:get_guide_info(NewHome),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			?MSG_DEBUG("~n do_battle_over1 : State = ~p, Belonger=~p, Battle=~p ", 
					   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			update_other_info(BattleType, UserId, UserName, GrabedId, GrabedId1),         %% 根据战斗形式更新各方信息
			{?ok, Player};
		_ ->
			{?ok, Player}
	end;
do_battle_over1(Player, [GrabedId, Param])->    %% 抢夺者失败
	Now				= misc:seconds(),
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	GrabedId1		= Param#param.ad3,
	BattleType		= Param#param.ad4,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl		 	= Home#ets_home.girl,
			NewGirl		 	= Girl#girl{grab_begin_time = Now, 
										battle = ?CONST_SYS_FALSE,
										battle_list = []},
			
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId1),
			OtherName1		= player_api:get_name(GrabedId),
			
			NewInterInfo	= case BattleType of
								  0 -> home_mod_girl:add_inter_info(InterList, 3, OtherName, "", 0, 0);
								  _ -> home_mod_girl:add_inter_info(InterList, 34, OtherName1, "", 0, 0)
							  end,
			NewMessage		= Message#message{interinfo = NewInterInfo},
			NewHome	 	 	= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Packet			= case BattleType of
								  0 -> home_api:msg_sc_inter_info(3, OtherName, "", 0, 0);
								  _ -> home_api:msg_sc_inter_info(34, OtherName1, "", 0, 0)
							  end,
			Packet1			= home_mod:get_guide_info(NewHome),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			
			update_other_enemy_info(BattleType, GrabedId1, UserId, UserName),
			update_battle_user_state(BattleType, GrabedId, UserName),
			{?ok, Player};
		_ -> {?ok, Player}
	end.

%% ------------------------------------------------------------------------------------------------
%% 反抗
%% ------------------------------------------------------------------------------------------------
do_battle_over2(Player, [?CONST_BATTLE_RESULT_LEFT, GrabedId]) -> %% 反抗成功
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
								
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 6, OtherName, "", 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, state = 0, belonger = 0,
										battle_list = []},
			?MSG_DEBUG("~ndo_battle_over2 NewGirl=~p", [NewGirl]),
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			update_againster_info(GrabedId, UserId, UserName),          %% 更新被反抗者信息
			Packet			= home_api:msg_sc_user_state(UserId, 0),
			Packet1			= home_api:msg_sc_inter_info(6, OtherName, "", 0, 0),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			{?ok, Player};
		_ ->
			{?ok, Player}
	end;
do_battle_over2(Player, [GrabedId])->  %% 反抗失败
	UserId			= Player#player.user_id,
	UserName		= (Player#player.info)#info.user_name,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 8, OtherName, "", 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE,
										battle_list = []},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			update_againster_info1(GrabedId, UserName),  				 %% 更新被反抗者信息
			
			Packet			= home_api:msg_sc_inter_info(8, OtherName, "", 0, 0),
			misc_packet:send(Player#player.net_pid, Packet),
			{?ok, Player};
		_ ->
			{?ok, Player}
	end.

%% ------------------------------------------------------------------------------------------------
%% 好友解救
%% ------------------------------------------------------------------------------------------------
do_battle_over3(Player,[?CONST_BATTLE_RESULT_LEFT, GrabedId, Param]) ->  %% 邀请好友解救成功
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	UserName		= Info#info.user_name,
	GrabedId1		= Param#param.ad3,
	OtherName		= player_api:get_name(GrabedId),
	OtherName1		= player_api:get_name(GrabedId1),
	
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 11, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			
			Girl			= Home#ets_home.girl,
			Ids				= Girl#girl.source_list,
			SourceList		= home_mod_girl:get_source_list([GrabedId1|Ids], UserId),
			NewGirl			= Girl#girl{battle = 0, battle_list = [], source_list = SourceList},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			
			update_belonger_info(GrabedId, GrabedId1, UserName, OtherName1),
			update_slaver_info(GrabedId1, UserName, OtherName),
			
			Exp				= ?FUN_HOME_RESCUE_EXP(Lv),
			TipPacket		= message_api:msg_notice(?TIP_HOME_RESCUE_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),
			Packet			= home_api:msg_sc_inter_info(11, OtherName, OtherName1, 0, 0),
			misc_packet:send(Player#player.net_pid, <<TipPacket/binary, Packet/binary>>),
			player_api:exp(Player, Exp);
		_ ->
			{?ok, Player}
	end;
do_battle_over3(Player, [GrabedId, Param])->  %% 邀请好友解救失败
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	UserName		= Info#info.user_name,
	GrabedId1		= Param#param.ad3,
	OtherName		= player_api:get_name(GrabedId),
	OtherName1		= player_api:get_name(GrabedId1),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 14, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			
			Girl		= Home#ets_home.girl,
			NewGirl		= Girl#girl{battle = 0, battle_list = []},
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Packet			= home_api:msg_sc_inter_info(14, OtherName, OtherName1, 0, 0),
			misc_packet:send(Player#player.net_pid, Packet),
			
			update_belonger_info1(GrabedId,  UserName, OtherName1),
			update_slaver_info1(GrabedId1, UserName, OtherName),
	{?ok, Player};
		_ ->
			{?ok, Player}
	end.

%% ------------------------------------------------------------------------------------------------
%% 解救好友
%% ------------------------------------------------------------------------------------------------
do_battle_over4(Player,[?CONST_BATTLE_RESULT_LEFT, GrabedId, Param]) ->  %% 解救好友
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	UserName		= Info#info.user_name,
	GrabedId1		= Param#param.ad3,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
			OtherName1		= player_api:get_name(GrabedId1),
			
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 15, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			
			Ids				= Girl#girl.source_list,
			SourceList		= home_mod_girl:get_source_list([GrabedId1|Ids], UserId),
			NewGirl			= Girl#girl{battle = 0, battle_list = [], source_list = SourceList},
			?MSG_DEBUG("~ndo_battle_over4~p~n", [NewGirl]),
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Exp				= ?FUN_HOME_RESCUE_EXP(Lv),
			Packet			= home_api:msg_sc_inter_info(15, OtherName, OtherName1, 0, 0),
			{LeftGrab, LeftPlay, LeftRes, LeftExp} 
							= home_mod_girl:get_play_num(NewHome, Lv),
			Packet1			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
			TipPacket		= message_api:msg_notice(?TIP_HOME_RESCUE_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary, TipPacket/binary>>),
			
			update_belonger_state(GrabedId, GrabedId1, OtherName1, UserName),
			update_slaver_state(GrabedId1, UserName, OtherName),
			
			player_api:exp(Player, Exp);
		_ ->
			{?ok, Player}
	end;
do_battle_over4(Player, [GrabedId, Param])->  %% 解救好友失败
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	UserName		= Info#info.user_name,
	GrabedId1		= Param#param.ad3,
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			OtherName		= player_api:get_name(GrabedId),
			OtherName1		= player_api:get_name(GrabedId1),
			
			NewInterInfo	= home_mod_girl:add_inter_info(InterList, 18, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = NewInterInfo},
			
			Girl		= Home#ets_home.girl,
			NewGirl		= Girl#girl{battle = 0,  battle_list = []},
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			{LeftGrab, LeftPlay, LeftRes, LeftExp} 
							= home_mod_girl:get_play_num(NewHome, Lv),
			Packet			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
			Packet1			= home_api:msg_sc_inter_info(18, OtherName, OtherName1, 0, 0),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			
			update_belonger_state1(GrabedId, OtherName1, UserName),
			update_slaver_state1(GrabedId1, UserName, OtherName),
			{?ok, Player};
		_ ->
			{?ok, Player}
	end.
%%
%% Local Functions
%%
%% ------------------------------------------------------------------------------------------------
%% 更改胜利者推荐列表和仇人列表
%% ------------------------------------------------------------------------------------------------
change_winner_recommend(RecommendList, OtherId, Type, Grid) ->
	case lists:keyfind(OtherId, #recommend_list.id, RecommendList) of
		#recommend_list{pos = Pos} ->
			NewTuple			= #recommend_list{pos = Pos, state = 1, id = 0, name = "",
												  lv = 0, pro = 0},
			?MSG_DEBUG("~n change_winner_recommend: NewTuple=~p~n", [NewTuple]),
			lists:keyreplace(Pos, #recommend_list.pos, RecommendList, NewTuple);
		_ ->
			case Type of
				1 ->
					NewTuple			= #recommend_list{pos = Grid, state = 1, id = 0, name = "",
														  lv = 0, pro = 0},
					?MSG_DEBUG("~n change_winner_recommend:NewTuple=~p~n", [NewTuple]),
					lists:keyreplace(Grid, #recommend_list.pos, RecommendList, NewTuple);
				_ ->
					RecommendList
			end
	end.

change_winer_enemy(UserId, EnemyList, UserId, _, _) -> EnemyList;
change_winer_enemy(_, EnemyList, OtherId, Type, Grid) ->
	case lists:keyfind(OtherId, #enemy_list.id, EnemyList) of
		#enemy_list{pos = Pos} ->
			NewTuple			= #enemy_list{pos = Pos, state = 1, id = 0, name = "",
											  lv = 0, pro = 0},
			?MSG_DEBUG("~n change_winer_enemy:NewTuple=~p~n", [NewTuple]),
			lists:keyreplace(Pos, #enemy_list.pos, EnemyList, NewTuple);
		_ ->
			case Type of
				2 ->
					NewTuple			= #enemy_list{pos = Grid, state = 1, id = 0, name = "",
													  lv = 0, pro = 0},
					?MSG_DEBUG("~n change_winer_enemy:NewTuple=~p~n", [NewTuple]),
					lists:keyreplace(Grid, #enemy_list.pos, EnemyList, NewTuple);
				_ ->
					EnemyList
			end
	end.

%% 更改胜利者小黑屋信息
chang_black_info(Home, GraberId1) ->
	Girl		 	= Home#ets_home.girl,
	GirlLv			= home_mod:get_top_girl_id(GraberId1),
	GrabInfo		= Girl#girl.grab_girl_info,
	GrabList		= misc:to_list(GrabInfo),
	BlackPostion 	= get_black_exsit_positon(GrabList, []),
	Now				= misc:seconds(),
	EndTime			= Now + ?CONST_SYS_ONE_DAY_SECONDS,
	case erlang:length(BlackPostion) =:= ?CONST_SYS_FALSE of
		?true  -> GrabInfo;
		?false ->
			case player_api:get_player_field(GraberId1, #player.info) of
				{?ok, #info{user_name = Name, lv = Lv, pro = Pro}} ->
					BlackPos		= lists:nth(?CONST_SYS_TRUE, BlackPostion),
					Grab		   	= #grab_girl_info{pos = BlackPos, id = GirlLv, owner_id = GraberId1, 
													  owner_name = Name, owner_pro = Pro, state = 2, 
													  owner_lv = Lv, start_time = Now, end_time = EndTime,
													  play_time = 0},
					NewGrabList		= lists:keyreplace(BlackPos, #grab_girl_info.pos, GrabList, Grab),
					misc:to_tuple(NewGrabList);
				_ ->
					GrabInfo
			end
	end.

%% ------------------------------------------------------------------------------------------------
%% 抢夺者胜利 更改被抢各方的信息
%% 获取战斗形式0和自由身战斗1和抓捕者战斗2和被抓捕者主人战斗
%% ------------------------------------------------------------------------------------------------
update_other_info(0, UserId, UserName, GrabedId, GrabedId) ->
	?MSG_DEBUG("~n Battle = ~p, UserId=~p, GrabedId=~p, GrabedId=~p~n", [0, UserId, GrabedId, GrabedId]),
	update_battle_user_info1(0,  GrabedId, UserId, UserName, GrabedId);
update_other_info(BattleType, UserId, UserName, GrabedId, GrabedId1) when GrabedId =/= GrabedId1->
	?MSG_DEBUG("~n Battle = ~p, UserId=~p, GrabedId=~p, GrabedId1=~p~n", [BattleType, UserId, GrabedId, GrabedId1]),
	update_battle_user_info1(BattleType, GrabedId1, UserId, UserName, GrabedId),
	update_battle_user_info(GrabedId, GrabedId1, UserName);
update_other_info(_, _, _, _, _) -> 
	?MSG_ERROR("update_other_info:", [?MODULE]),
	?ok.

%% 更改实际战斗对象信息
update_battle_user_info(UserId, OtherId, OtherName1) ->
	OtherName			= player_api:get_name(OtherId),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			
			InterInfo		= home_mod_girl:add_inter_info(InterList, 32, OtherName1, OtherName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Packet			= home_api:msg_sc_inter_info(32, OtherName1, OtherName, 0, 0),
			misc_packet:send(UserId, Packet),
			
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			BlackList		= change_black_info(misc:to_list(BlackInfo), OtherId),
			NewBlackInfo	= misc:to_tuple(BlackList),
			State			= get_lose_girl_state(NewBlackInfo),
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, grab_girl_info = NewBlackInfo, state = State},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			?MSG_DEBUG("~nState=~p, Belonger=~p, Battle=~p~n ", 
							   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			?ok
	end.
				
%% 更改实际战斗对象小黑屋信息
change_black_info(BlackList, OtherId) ->
	case lists:keyfind(OtherId, #grab_girl_info.owner_id, BlackList) of
		#grab_girl_info{pos = Pos} ->
			NewTuple			= #grab_girl_info{pos = Pos, state = 1, owner_id = 0, owner_name = "",
												  owner_pro = 0, owner_lv = 0, end_time = 0,
												  play_time = 0, get_exp_time = 0},
			?MSG_DEBUG("~n change_black_info,~p ~n", [NewTuple]),
			lists:keyreplace(Pos, #grab_girl_info.pos, BlackList, NewTuple);
		_ ->
			?MSG_DEBUG("~n change_black_info, BlackList=~pOtherId=~p~n", [BlackList, OtherId]),
			BlackList
	end.

%% 更改实际被抢走对象仇人列表、主人、状态等
update_battle_user_info1(BattleType, UserId, OtherId, OtherName, GrabedId) ->
	OtherName1		= player_api:get_name(GrabedId),
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= case BattleType of
								  0 ->
									home_mod_girl:add_inter_info(InterList, 2, OtherName, "", 0, 0);
								  _ ->
									home_mod_girl:add_inter_info(InterList, 33, OtherName, OtherName1, 0, 0)
							  end,
			
			NewMessage		= Message#message{interinfo = InterInfo},
			Girl			= Home#ets_home.girl,
			Enemy			= Girl#girl.enemy_list,
			?MSG_DEBUG("Enemy=~p", [Enemy]),
			case check_in_recommend(Home, OtherId) of
				?true  -> 
					NewGirl			= Girl#girl{state = 2, belonger = OtherId, 
												battle = ?CONST_SYS_FALSE},
					?MSG_DEBUG("~n update_battle_user_info1 NewGirl=~p", [NewGirl]),
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome);
				_ ->
					List			= misc:to_list(Enemy),
					EnemyList		= add_new_enemy_info(OtherId, List),
					NewEnemyList	= change_enemy_info(EnemyList, 1, []),
					EnemyInfo		= misc:to_tuple(NewEnemyList),
					NewGirl			= Girl#girl{enemy_list = EnemyInfo, state = 2, belonger = OtherId, 
												battle = ?CONST_SYS_FALSE},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
				    ?MSG_DEBUG("~nEnemyList =~p, NewEnemyList=~p,State=~p, Belonger=~p, Battle=~p~n", 
							   [EnemyList, NewEnemyList, NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
					ets_api:insert(?CONST_ETS_HOME, NewHome)
			end,
			Packet			= case BattleType of 
								  0 -> home_api:msg_sc_inter_info(2, OtherName, "", 0, 0);
								  _ -> home_api:msg_sc_inter_info(33, OtherName, OtherName1, 0, 0)
							  end,
			Packet1			= home_api:msg_sc_user_state(UserId, 2),
			Packet2			= home_mod:get_slaver_info(OtherId, UserId),
			misc_packet:send(UserId, <<Packet/binary, Packet1/binary, Packet2/binary>>),
			?ok;
		_ ->
			?ok
	end.

%% 检查是否在推荐列表和仇人列表中
check_in_recommend(Home, OtherId) ->
	Girl			= Home#ets_home.girl,
	Recommend		= Girl#girl.recommend_list,
	RecommendList	= misc:to_list(Recommend),
	Enemy			= Girl#girl.enemy_list,
	EnemyList		= misc:to_list(Enemy),
	Flag1			= lists:keymember(OtherId, #recommend_list.id, RecommendList),
	Flag2			= lists:keymember(OtherId, #enemy_list.id, EnemyList),
	case {Flag1, Flag2} of 
		{?false, ?false} -> ?false;              
		_ -> ?true
	end.

%% 更新已存在仇人列表中的顺序
change_enemy_info([], _, Acc) -> Acc;
change_enemy_info([Enemy|Tail], Num, Acc) ->
	case Num > 4 of
		?false ->
			NewEnemy			= Enemy#enemy_list{pos = Num},
			NewAcc				= Acc ++ [NewEnemy],
			change_enemy_info(Tail, Num + 1, NewAcc);
		?true ->
			change_enemy_info([], Num, Acc)
	end.

%% 加入新的仇人信息
add_new_enemy_info(UserId, EnemyList) ->
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, Info} when is_record(Info, info) ->
			Name			= Info#info.user_name,
			Pro				= Info#info.pro,
			Lv				= Info#info.lv,
			GirlLv			= home_mod:get_top_girl_id(UserId),
			List			= #enemy_list{id = UserId, pro = Pro, lv = Lv, 
										   name = Name,girl_lv = GirlLv, state = 2},
			[List|EnemyList];
		_ ->
			EnemyList
	end.

%% ------------------------------------------------------------------------------------------------
%% 抢夺失败 更新仇人信息
%% ------------------------------------------------------------------------------------------------
update_other_enemy_info(BattleType, UserId, OtherId, OtherName) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 4, OtherName, "", 0, 0),
			NewMessage		= case BattleType of
								  0 -> 
									  Packet			= home_api:msg_sc_inter_info(4, OtherName, "", 0, 0),
									  misc_packet:send(UserId, Packet),
									  Message#message{interinfo = InterInfo};
								  _ -> Message
							  end,
			Girl			= Home#ets_home.girl,
			Enemy			= Girl#girl.enemy_list,
			case check_in_recommend(Home, OtherId) of
				?true -> 
					NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome);	
				_ ->
					List			= misc:to_list(Enemy),
					EnemyList		= add_new_enemy_info(OtherId, List),
					NewEnemyList	= change_enemy_info(EnemyList, 1, []),
					EnemyInfo		= misc:to_tuple(NewEnemyList),
					NewGirl			= Girl#girl{enemy_list = EnemyInfo, battle = ?CONST_SYS_FALSE},
					NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
					ets_api:insert(?CONST_ETS_HOME, NewHome)
			end,
			?ok;
		_ ->
			?ok
	end.

%% 更新实际战斗的人物状态
update_battle_user_state(0, _GrabedId, _OtherName) ->
	?ok;
update_battle_user_state(_, GrabedId, OtherName) when GrabedId =/= 0 ->
	update_user_battle_state1(GrabedId, OtherName);
update_battle_user_state(_, _, _) ->
	?MSG_ERROR("update_battle_user_state:~p,", [?MODULE]),
	?ok.

%% ------------------------------------------------------------------------------------------------
%% 反抗者成功　更新被反抗对象的信息
%% ------------------------------------------------------------------------------------------------
update_againster_info(GraberId, UserId, UserName) ->
	?MSG_DEBUG("~n update_againster_info=~p", [{GraberId, UserId}]),
	case home_mod_create:get_home1(GraberId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 5, UserName, "", 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			BlackList		= change_black_info(misc:to_list(BlackInfo), UserId),
			NewBlackInfo	= misc:to_tuple(BlackList),
			State			= get_lose_girl_state(NewBlackInfo),
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, grab_girl_info = NewBlackInfo, state = State},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			
			Packet			= home_api:msg_sc_inter_info(5, UserName, "", 0, 0),
			misc_packet:send(GraberId, Packet),
			?MSG_DEBUG("~nState=~p, Belonger=~p, Battle=~p~n ", 
							   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			?ok
	end.

%% 反抗者失败　更新被反抗对象的信息
update_againster_info1(GraberId, UserName) ->
	case home_mod_create:get_home1(GraberId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 7, UserName, "", 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			
			Packet			= home_api:msg_sc_inter_info(7, UserName, "", 0, 0),
			misc_packet:send(GraberId, Packet),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
%% ------------------------------------------------------------------------------------------------
%% 邀请解救成功 更新原主人信息
%% ------------------------------------------------------------------------------------------------
update_belonger_info(GrabedId, GrabedId1, UserName, OtherName1) ->
	?MSG_DEBUG("~nupdate_belonger_info~p~n", [{GrabedId, GrabedId1}]),
	case home_mod_create:get_home1(GrabedId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 9, OtherName1, UserName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			BlackList		= change_black_info(misc:to_list(BlackInfo), GrabedId1),
			NewBlackInfo	= misc:to_tuple(BlackList),
			State			= get_lose_girl_state(NewBlackInfo),
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, grab_girl_info = NewBlackInfo, state = State},
			NewHome			= Home#ets_home{girl = NewGirl, message= NewMessage},
			
			Packet			= home_api:msg_sc_inter_info(9, OtherName1, UserName, 0, 0),
			misc_packet:send(GrabedId, Packet),
			?MSG_DEBUG("~nState=~p, Belonger=~p, Battle=~p~n ", 
					   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			?ok
	end.

%% ------------------------------------------------------------------------------------------------
%% 邀请解救成功 更新奴隶信息
%% ------------------------------------------------------------------------------------------------
update_slaver_info(UserId, OtherName, OtherName1) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 10, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl		= Home#ets_home.girl,
			NewGirl		= Girl#girl{battle = 0,
									state = 0, belonger = 0},
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Packet1			= home_api:msg_sc_user_state(UserId, 0),
			Packet2			= home_api:msg_sc_inter_info(10, OtherName, OtherName1, 0, 0),
			case player_api:get_player_field(UserId, #player.info) of
				{?ok, #info{lv = Lv}} ->
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= home_mod_girl:get_play_num(NewHome, Lv),
					Packet			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
					misc_packet:send(UserId, <<Packet/binary, Packet1/binary, Packet2/binary>>),
					?ok;
				_ -> 
					misc_packet:send(UserId, Packet1),
					?ok
			end;
		_ -> 
			?ok
	end.
%% ------------------------------------------------------------------------------------------------
%% 邀请解救失败 更新奴隶主信息
%% ------------------------------------------------------------------------------------------------
update_belonger_info1(GrabedId,  UserName, OtherName1) ->
	case home_mod_create:get_home1(GrabedId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 12, OtherName1, UserName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl			= Home#ets_home.girl,
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE},
			NewHome			= Home#ets_home{girl = NewGirl, message= NewMessage},
			
			Packet			= home_api:msg_sc_inter_info(12, OtherName1, UserName, 0, 0),
			misc_packet:send(GrabedId, Packet),
			?MSG_DEBUG("~nState=~p, Belonger=~p, Battle=~p~n ", 
					   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			?ok
	end.
	
	
%% 邀请解救失败 更新奴隶信息
update_slaver_info1(GrabedId1, OtherName, OtherName1) ->
	case home_mod_create:get_home1(GrabedId1) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 13, OtherName, OtherName1, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl		= Home#ets_home.girl,
			NewGirl		= Girl#girl{battle = 0},
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome),
			
			Packet1			= home_api:msg_sc_inter_info(13, OtherName, OtherName1, 0, 0),
			case player_api:get_player_field(GrabedId1, #player.info) of
				{?ok, #info{lv = Lv}} ->
					{LeftGrab, LeftPlay, LeftRes, LeftExp} 
									= home_mod_girl:get_play_num(NewHome, Lv),
					Packet			= home_api:msg_sc_play_num(LeftGrab, LeftPlay, LeftRes, LeftExp),
					misc_packet:send(GrabedId1, <<Packet/binary, Packet1/binary>>),
					?ok;
				_ -> ?ok
			end;
		_ -> 
			?ok
	end.

%% ------------------------------------------------------------------------------------------------
%% 解救好友成功　 更新奴隶主信息
%% ------------------------------------------------------------------------------------------------
update_belonger_state(GrabedId, GrabedId1, OtherName1, UserName) ->
	case home_mod_create:get_home1(GrabedId) of
		Home when is_record(Home, ets_home) ->
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 16, OtherName1, UserName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			
			Girl			= Home#ets_home.girl,
			BlackInfo		= Girl#girl.grab_girl_info,
			BlackList		= change_black_info(misc:to_list(BlackInfo), GrabedId1),
			NewBlackInfo	= misc:to_tuple(BlackList),
			State			= get_lose_girl_state(NewBlackInfo),
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE, grab_girl_info = NewBlackInfo, state = State},
			NewHome			= Home#ets_home{girl = NewGirl, message= NewMessage},
			
			Packet			= home_api:msg_sc_inter_info(16, OtherName1, UserName, 0, 0),
			misc_packet:send(GrabedId, Packet),
			?MSG_DEBUG("~nState=~p, Belonger=~p, Battle=~p~n ", 
					   [NewGirl#girl.state, NewGirl#girl.belonger, NewGirl#girl.battle]),
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			?ok
	end.
	
%% 解救好友成功　 更新奴隶信息
update_slaver_state(UserId, UserName, OtherName) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 17, UserName, OtherName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			NewGirl			= Girl#girl{battle = 0, state = 0, belonger = 0},
			
			
			Packet			= home_api:msg_sc_inter_info(17, UserName, OtherName, 0, 0),
			Packet1			= home_api:msg_sc_user_state(UserId, 0),
			misc_packet:send(UserId, <<Packet/binary, Packet1/binary>>),
			
			?MSG_DEBUG("~n update_slaver_state~p~n", [NewGirl]),
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ -> 
			?ok
	end.
%% ------------------------------------------------------------------------------------------------
%% 解救好友失败　 更新奴隶主信息
%% ------------------------------------------------------------------------------------------------
update_belonger_state1(GrabedId, OtherName1, UserName) ->
	case home_mod_create:get_home1(GrabedId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 19, OtherName1, UserName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			NewGirl			= Girl#girl{battle = 0},
			
			
			Packet			= home_api:msg_sc_inter_info(19, OtherName1, UserName, 0, 0),
			misc_packet:send(GrabedId, Packet),
			
			?MSG_DEBUG("~n update_slaver_state~p~n", [NewGirl]),
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ -> 
			?ok
	end.
%% 解救好友失败　 更新奴隶信息	
update_slaver_state1(GrabedId1, UserName, OtherName) ->
	case home_mod_create:get_home1(GrabedId1) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 20, UserName, OtherName, 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			NewGirl			= Girl#girl{battle = 0},
			
			
			Packet			= home_api:msg_sc_inter_info(20, UserName, OtherName, 0, 0),
			misc_packet:send(GrabedId1, Packet),
			
			?MSG_DEBUG("~n update_slaver_state~p~n", [NewGirl]),
			NewHome		= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ -> 
			?ok
	end.

%% ------------------------------------------------------------------------------------------------
%% ------------------------------------------------------------------------------------------------
%% 抢夺失败 更新奴隶主信息
update_user_battle_state1(UserId, OtherName) ->
	case home_mod_create:get_home1(UserId) of
		Home when is_record(Home, ets_home) ->
			Girl			= Home#ets_home.girl,
			Message			= Home#ets_home.message,
			InterList		= Message#message.interinfo,
			InterInfo		= home_mod_girl:add_inter_info(InterList, 35, OtherName, "", 0, 0),
			NewMessage		= Message#message{interinfo = InterInfo},
			NewGirl			= Girl#girl{battle = ?CONST_SYS_FALSE},
			NewHome			= Home#ets_home{girl = NewGirl, message = NewMessage},
			ets_api:insert(?CONST_ETS_HOME, NewHome);
		_ ->
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
  
%% 获取能存放小黑屋仕女格子位置
get_black_exsit_positon([Grab|RestList], Acc) ->
	State		= Grab#grab_girl_info.state,
	Pos			= Grab#grab_girl_info.pos,
	NewAcc		= case State =/= 2 of
					  ?true -> [Pos|Acc];
					  ?false -> Acc
				  end,
	get_black_exsit_positon(RestList, NewAcc);
get_black_exsit_positon([], Acc) ->
	lists:reverse(Acc).	

%% 获取奴隶主被抢走侍女后的状态
get_lose_girl_state(BlackInfo) ->
	BlackNum		= cal_black_has(misc:to_list(BlackInfo), 0),
	case BlackNum of
		?CONST_SYS_FALSE -> ?CONST_SYS_FALSE;
		_ -> ?CONST_SYS_TRUE
	end.
	
%% 计算小黑屋已经抢夺的格子数
cal_black_has([Grab|RestList], Acc) when Grab#grab_girl_info.state =:= 2 ->
	NewAcc	= Acc + 1,
	cal_black_has(RestList, NewAcc);
cal_black_has([_|RestList], Acc) ->
	cal_black_has(RestList, Acc);
cal_black_has([], Acc) ->
	Acc.