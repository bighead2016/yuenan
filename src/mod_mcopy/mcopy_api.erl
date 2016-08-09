%% Author: zero
%% Created: 2012-11-9
%% Description: TODO: Add description to mcopy_api
-module(mcopy_api).

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
-export([init/0, get_team/1, battle_over/8, get_current_mcopy/3, start_q/2, update_mcopy/1,
         list_mcopy/1, refresh/1, login/1, init_data/1, start_mcopy/4,
         mcopy_battle_over/9, get_current_mcopy_ser/1, get_award_cb/2, logout/1,
         start_q_cb/3, update_state_cb/2,get_enter_max_times/1, get_multi_copy_times/1,
         check_team_play/3, get_enter_times/2, check_play_over/0, check_minus_times/1]).
-export([msg_encounter/2, msg_point/1, msg_sc_award/3, msg_sc_list_copy/1, msg_bar/2, msg_sc_buff/1, msg_sc_mcopy_end/10, msg_enter_mcopy/1,
		 msg_sc_quit_mcopy/1,msg_notice_vip_award/3]).
-export([refresh_attr/2, refresh_buff/2, reset_times/2, get_mcopy_info/1, delete_mcopy_info/1,
		 insert_mcopy_info/1]).
-export([get_mon_reward/1, get_serial_id/1, next_wave/1, create_skip/1]).

%%
%% API Functions
%%

%%------------------------定时任务--------------------------------------------------------------------------
%% 登陆初始化
init() ->
	Date		= misc:date_num(),
    #mcopy_data{date = Date, list = []}.

%% 上线处理 -- player_serv
%% 1.假如到了第2天，就刷新数据
login(Player) ->
	NewDate			= misc:date_num(),
	McopyData		= Player#player.mcopy,
	OldDate			= McopyData#mcopy_data.date,
	case OldDate =:= NewDate of
		?true  -> Player;
		?false ->
			NewMcopyData		= McopyData#mcopy_data{date = NewDate, times = ?CONST_SYS_FALSE},
			Player#player{mcopy = NewMcopyData}
	end.

%% 0时刷新数据 -- player_serv
refresh(Player) ->
	NewDate			= misc:date_num(),
	McopyData		= Player#player.mcopy,
	OldDate			= McopyData#mcopy_data.date,
	try
		case OldDate =:= NewDate of
			?true  -> {?ok, Player};
			?false ->
				NewMcopyData		= McopyData#mcopy_data{date = NewDate, times = ?CONST_SYS_FALSE},
				NewPlayer			= Player#player{mcopy = NewMcopyData},
				{?ok, NewPlayer}
		end
	catch
		Type:Error ->
			?MSG_ERROR("UserId:~p Type:~p Error:~p Stack:~p", [Player#player.user_id, Type, Error, erlang:get_stacktrace()]),
			{?ok, Player}
	end.

%% 下线时的处理
logout(Player) ->
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = []}).            %% 清除buff

%%------------------------初始化----------------------------------------------------------------------------------
%% 建地图前初始化副本数据 -- map_serv
init_data(MapParam) ->
	MapId			= MapParam#map_param.ad1,
	MCopySer 		= MapParam#map_param.ad2,
	case is_record(MCopySer, mcopy_serial) of
		?true -> 
			MapData			= init_mcopy_ser(MCopySer),        %%初始化副本系列数据
			init_mcopy(MCopySer, MapData, MapId);          		
		?false ->
			MCopySer1			= init_mcopy_ser1(MapId),
			MapData1			= init_mcopy_ser(MCopySer1),
			init_mcopy(MCopySer1, MapData1, MapId)
	end.

%% 初始化副本系列数据 -- map_serv
init_mcopy_ser(MCopySer) ->
	StandardTime	= MCopySer#mcopy_serial.standard_time,
    GoodsDropId 	= MCopySer#mcopy_serial.goods,
    Exp         	= MCopySer#mcopy_serial.exp,
    GoldBind    	= MCopySer#mcopy_serial.gold_bind,
    Meritorious 	= MCopySer#mcopy_serial.meritorious,
    record_reward(#mcopy_map_data{standard_time = StandardTime}, GoodsDropId, Exp, GoldBind, Meritorious).

init_mcopy_ser1(MapId) ->
	McopyData		= data_mcopy:get_mcopy(MapId),
	SerId			= McopyData#rec_mcopy.serial_id,
	data_mcopy:get_mcopy_serial(SerId).
	
%% 封装副本奖励
record_reward(MCopyMapData, GoodsDropId, Exp, GoldBind, Meritorious) ->
    MCopyMapData#mcopy_map_data{
                                goods_drop_id = GoodsDropId,         
                                exp           = Exp, 
                                gold_bind     = GoldBind,    
                                meritorious   = Meritorious
                               }.

%% 初始化副本 -- map_serv
init_mcopy(MCopySer, MCopyMapData, MapId) ->
	McopyList		= MCopySer#mcopy_serial.mcopy_list,
    [RecMCopy]  	= get_current_mcopy(McopyList, MapId, []),
    Mon1      		= RecMCopy#rec_mcopy.monster_1,
    Mon2      		= RecMCopy#rec_mcopy.monster_2,
    Mon3      		= RecMCopy#rec_mcopy.monster_3,
    MonList  		= [Mon1, Mon2, Mon3],
	?MSG_DEBUG("MonList=~p", [MonList]),
    QId       		= RecMCopy#rec_mcopy.q_id,
	Condition 		= RecMCopy#rec_mcopy.condition,
    Encounter 		= data_mcopy:get_encounter(QId), 					% 这有可能是null
    record_mon_list(MCopyMapData, MonList, 0, Condition, Encounter, ?CONST_SYS_FALSE).

%% 封装怪物信息列表
record_mon_list(MCopyMapData, MonList, Wave, Condition, Encounter, QType) ->
    MCopyMapData#mcopy_map_data{
                                   mon_list = MonList, 
                                   wave     = Wave,
								   condition= Condition, 
                                   q        = Encounter, 
                                   q_type   = QType
                               }.

%% 获取当前副本信息
%% 约定：每做完一个副本删掉一个，所以最前面的必然是下一个
get_current_mcopy([Mcopy|Tail], MapId, Acc)  ->
	case  Mcopy#rec_mcopy.map =:= MapId of
		?true  -> [Mcopy|Acc];
		?false -> get_current_mcopy(Tail, MapId, Acc)
	end.
%%------------------------------------------------------------------------------------------------------------------
%% 进入地图后，初始化怪物 -- map_serv
start_mcopy(MapData, MapPid, MapId, Times) ->
	Flag		= check_special_map(MapId),
	case {Flag, Times =:= ?CONST_SYS_FALSE} of
		{?true, ?false} ->
			MonList 		= MapData#mcopy_map_data.mon_list,
			?MSG_DEBUG("MapId=~p, Times=~p, MonList=~p", [MapId, Times, MonList]),
			MonsterNum		= erlang:length(MonList),
			MonsterId		= lists:nth(MonsterNum, MonList),
			
			{?ok, Monster} 	= monster_api:make(MonsterId),
   			PacketMonster   = packet_mon_info(Monster),
			map_api:broadcast(MapPid, PacketMonster),
			MapData#mcopy_map_data{mon_list = [MonsterId]};
		{_, _} ->
    		MonList 		= MapData#mcopy_map_data.mon_list,
			?MSG_DEBUG("MapId=~p, Times=~p, MonList=~p", [MapId, Times, MonList]),
    		{?ok, _Monster1, PacketMonster}		= next_wave(MonList),
			map_api:broadcast(MapPid, PacketMonster),
			MapData
	end.
   

%% 初始化下波怪 -- map_serv
next_wave([MonsterId|_MonList]) ->
    {?ok, Monster} 	= monster_api:make(MonsterId),
    PacketMonster 	= packet_mon_info(Monster),
    {?ok, Monster, PacketMonster};
next_wave([]) ->
	{?ok, ?null, <<>>}.

%% --------------------------------------------------------------------------------------------------------------
%% 团队战场剩余次数
get_multi_copy_times(Player) ->
	McopyData		= Player#player.mcopy,
	Count			= get_enter_max_times(?CONST_SYS_TRUE),
	Times			= McopyData#mcopy_data.times,
	case Count - Times of
		Num when Num >= ?CONST_SYS_FALSE -> Num;
		_ -> ?CONST_SYS_FALSE
	end.
%%-----------------------------------------------------------------------------------------------------------------
%% 战斗结束 -- battle_serv
battle_over(?CONST_BATTLE_RESULT_LEFT, [], _MapPid, _MonsterId, _AtkPoint, _DefPoint, _TeamId, _RobotList) -> ?ok;
battle_over(?CONST_BATTLE_RESULT_LEFT, UserIdList, MapPid, MonsterId, AtkPoint, DefPoint, TeamId, RobotList) -> %% 胜利
    map_api:mcopy_battle_over(MapPid, UserIdList, MonsterId, AtkPoint, DefPoint, TeamId, RobotList),
	?ok;
battle_over(_, _UserId, _MapPid, _MonsterId, _AtkPoint, _DefPoint, _, _) -> %% 失败
    ?ok.

%% 移除怪物 -- map_serv
%% 1.删除怪物
mcopy_battle_over(UserIdList, UniqueId, MapPid, MapData, _MapParam, AtkPoint, DefPoint, TeamId, RobotList) ->
	mcopy_mod:mcopy_battle_over(UserIdList, UniqueId, MapPid, MapData, _MapParam, AtkPoint, DefPoint, TeamId, RobotList).

%%--------------------------------------------------------------------------------------------------------------------
%% 发起奇遇
start_q(Player, 9) ->              %% 碰到机关
	MapId			= map_api:get_cur_map_id(Player),
	MapPid			= Player#player.map_pid,
	Packet			= msg_encounter(9, ?CONST_SYS_FALSE),
	PacketPoint 	= create_skip(MapId),
	map_api:broadcast(MapPid, <<Packet/binary, PacketPoint/binary>>);
start_q(Player, _) ->
    map_api:start_q(Player).

%% 奇遇发起 -- 回调 -- map_serv
start_q_cb(Player, MapData, MapPid) ->
	MapId          = map_api:get_cur_map_id(Player),
	UserId			= Player#player.user_id,
	Encounter 	    = MapData#mcopy_map_data.q,
	EncounterId     = Encounter#rec_encounter.id, 
	QRate 		    = Encounter#rec_encounter.q_rate,               %% 遇怪几率
	QRate1			= Encounter#rec_encounter.q_rate1,				%% 遇道具几率
	QRate2			= Encounter#rec_encounter.q_rate2,				%% 遇铜钱几率
	QRate3			= Encounter#rec_encounter.q_rate3,				%% 遇经验几率
	QRate4			= Encounter#rec_encounter.q_rate4,				%% 遇功勋几率
	QRate5			= Encounter#rec_encounter.q_rate5,				%% 遇buff几率
	TeamId 		    = Player#player.team_id,
	UserIdList 	    = case get_team(TeamId) of
						  {?ok, Team} when is_record(Team, team)->
							  team_api:get_team_uids(Team);
						  _ ->
							  [UserId]
					  end,
    QList			= [{1, QRate}, {2, QRate1}, {3, QRate2}, {4, QRate3}, {5, QRate4}, {6, QRate5}],
	Probablity		= misc_random:odds_list_init(?MODULE, ?LINE, QList, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	?MSG_DEBUG("Probablity=~p", [Probablity]),
	
	Finish			= MapData#mcopy_map_data.q_finish,
	IsFinish	    = case Finish =:= ?CONST_SYS_TRUE of
						  ?true -> ?CONST_SYS_TRUE;
						  ?false ->
							  case misc_random:odds_one(Probablity) of
								  ?CONST_MCOPY_Q_MON ->		% 发起战斗
									  handle_q_battele(Player, Encounter, MapData, MapId, MapPid, TeamId);
								  ?CONST_MCOPY_Q_GOODS ->      % 遇道具
									  handle_q_goods(Encounter, UserIdList, MapData, MapId, MapPid, TeamId);
								  ?CONST_MCOPY_Q_COIN ->      % 遇铜钱
									  handle_q_gold(Encounter, UserIdList, MapData, MapId, MapPid, TeamId);
								  ?CONST_MCOPY_Q_EXP ->		% 遇经验
									  handle_q_exp(Encounter, UserIdList, MapData, MapId, MapPid, TeamId);
								  ?CONST_MCOPY_Q_MER ->      % 遇功勋
									  handle_q_mer(Encounter, UserIdList, MapData, MapId, MapPid, TeamId);
								  ?CONST_MCOPY_Q_BUFF ->		% 遇buff
									  handle_q_buff(Encounter, UserIdList, MapData, MapId, MapPid, TeamId)
							  end
					  end,
	NewMapData 			= MapData#mcopy_map_data{q_finish = IsFinish},
	PacketEncounter 	= mcopy_api:msg_encounter(EncounterId, ?CONST_SYS_FALSE),
	map_api:broadcast(MapPid, PacketEncounter),
	{?ok, Player, NewMapData}.

%% 发起战斗和获取奖励后处理
handler_map(MapId, _MapPid, MonList) ->
	case check_special_map(MapId) of
		?true  ->
			create_skip(MapId);
		?false ->
			{?ok, _Monster, PacketMonster} = next_wave(MonList),
			PacketMonster
	end.
%%------------------------------------------------------------------------------------------------------------------------
%% 处理战斗奇遇
 handle_q_battele(Player, Encounter, MapData, MapId, MapPid, _TeamId) ->
	 UserId	  	    	 = Player#player.user_id,
	 MonsterId 	    	 = Encounter#rec_encounter.q_monster_id,         %% 遇怪的id
	 case battle_api:start(Player, MonsterId, #param{battle_type = ?CONST_BATTLE_MCOPY_Q}) of
		 {?ok, Player2} ->
			 TipPacket			 = message_api:msg_notice(?TIP_MCOPY_BAD),
			 case player_state_api:is_fighting(Player2) of
				 ?true ->
					 player_api:process_send(UserId, ?MODULE, update_state_cb, ?CONST_PLAYER_STATE_FIGHTING);
				 ?false -> ?ok
			 end,
			 MonList 			= MapData#mcopy_map_data.mon_list,
			 Packet				= handler_map(MapId, MapPid, MonList),
			 map_api:broadcast(MapPid, <<TipPacket/binary, Packet/binary>>),
			 ?CONST_SYS_FALSE;
		 _ ->
			 MonList 			= MapData#mcopy_map_data.mon_list,
			 TipPacket			= message_api:msg_notice(?TIP_MCOPY_BAD),
			 Packet				= handler_map(MapId, MapPid, MonList),
			 map_api:broadcast(MapPid, <<TipPacket/binary, Packet/binary>>),
			 ?CONST_SYS_FALSE
	 end.

%% 更改状态
update_state_cb(Player, State) ->
    {_, Player2} = player_state_api:try_set_state(Player, State),
    {?ok, Player2}.
%%------------------------------------------------------------------------------------------------------------------------
%% 处理战斗以外的奇遇
handle_q_goods(Encounter, UserIdList, MapData, MapId, MapPid, TeamId) ->% 遇道具
	GoodsDropId 	= Encounter#rec_encounter.q_goods,
	QId				= Encounter#rec_encounter.id,
	process_send(UserIdList, ?MODULE, get_award_cb, {?CONST_MCOPY_Q_GOODS, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, 
													 GoodsDropId, ?CONST_SYS_FALSE, MapId, QId, TeamId}),
	MonList 		= MapData#mcopy_map_data.mon_list,
	Packet  		= handler_map(MapId, MapPid, MonList),
	map_api:broadcast(MapPid, Packet),
	?CONST_SYS_TRUE.
handle_q_gold(Encounter, UserIdList, MapData, MapId, MapPid, TeamId) ->% 遇铜钱
	GoldBind 		= Encounter#rec_encounter.q_gold_bind,
	QId				= Encounter#rec_encounter.id,
	process_send(UserIdList, ?MODULE, get_award_cb, {?CONST_MCOPY_Q_COIN, ?CONST_SYS_FALSE, GoldBind, ?CONST_SYS_FALSE, 
													 ?CONST_SYS_FALSE, MapId, QId, TeamId}),
	MonList 		= MapData#mcopy_map_data.mon_list,
	Packet  		= handler_map(MapId, MapPid, MonList),
	map_api:broadcast(MapPid, Packet),
	?CONST_SYS_TRUE.
handle_q_exp(Encounter, UserIdList, MapData, MapId, MapPid, TeamId) -> % 遇经验
	Exp				= Encounter#rec_encounter.q_exp,
	QId				= Encounter#rec_encounter.id,
	process_send(UserIdList, ?MODULE, get_award_cb, {?CONST_MCOPY_Q_EXP, Exp, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, 
													 ?CONST_SYS_FALSE, MapId, QId, TeamId}),
	MonList 		= MapData#mcopy_map_data.mon_list,
	Packet  		= handler_map(MapId, MapPid, MonList),
	map_api:broadcast(MapPid, Packet),
	?CONST_SYS_TRUE.
handle_q_mer(Encounter, UserIdList, MapData, MapId, MapPid, TeamId) -> % 遇功勋
	Meritorious		= Encounter#rec_encounter.q_meritorious,
	QId				= Encounter#rec_encounter.id,
	process_send(UserIdList, ?MODULE, get_award_cb, {?CONST_MCOPY_Q_MER, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, 
													 Meritorious, MapId, QId, TeamId}),
	MonList 		= MapData#mcopy_map_data.mon_list,
	Packet  		= handler_map(MapId, MapPid, MonList),
	map_api:broadcast(MapPid, Packet),
	?CONST_SYS_TRUE.
handle_q_buff(Encounter, UserIdList, MapData, MapId, MapPid, TeamId) -> % 遇buff
	BuffList 		= Encounter#rec_encounter.q_buff,
	Rate1 			= Encounter#rec_encounter.rate1,
	Rate2 			= Encounter#rec_encounter.rate2,
	Rate3 			= Encounter#rec_encounter.rate3,
	Rate4 			= Encounter#rec_encounter.rate4,
	RateList		= [{1, Rate1}, {2, Rate2}, {3, Rate3}, {4, Rate4}],
	Probablity		= misc_random:odds_list_init(?MODULE, ?LINE, RateList, ?CONST_SYS_NUMBER_TEN_THOUSAND),
	BuffRate		= case misc_random:odds_one(Probablity) of
						  1 -> ?CONST_MCOPY_BUFF1;
						  2 -> ?CONST_MCOPY_BUFF2;
						  3	-> ?CONST_MCOPY_BUFF3;
						  4 -> ?CONST_MCOPY_BUFF4
					  end,
	[BuffId] 	= BuffList,
	process_send(UserIdList, ?MODULE, get_award_cb, {BuffId, BuffRate, MapId, TeamId}),
	MonList 		= MapData#mcopy_map_data.mon_list,
	Packet  		= handler_map(MapId, MapPid, MonList),
	map_api:broadcast(MapPid, Packet),
	?CONST_SYS_TRUE.
%%------------------------------------------------------------------------------------------------------------------------------
%% 奇遇奖励
get_award_cb(Player, {RewardType, Exp, GoldBind, GoodsDropId, Meritorious, MapId, QId, TeamId}) ->       %% 各种资源
	UserId 			= Player#player.user_id,
	MapSerId		= mcopy_api:get_serial_id(MapId),
	RobotList		= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
	case lists:member(UserId, RobotList) of
		?true 	-> {?ok, Player};
		?false  ->
			case mcopy_mod:check_play_times(Player, MapSerId) of
				?ok ->
					case RewardType of
						?CONST_MCOPY_Q_GOODS ->   %%道具
							GoodsList 	= goods_drop_api:goods_drop(GoodsDropId),
							case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_MCOPY_Q_REWARD, 1, 1, 1, 0, 0, 1, [MapSerId]) of
								{?ok, Player2, _, NewPacket} ->
									Packet		= msg_notice_goods(GoodsList, QId, <<>>),
									Packet1		= msg_notice_goods1(Player, GoodsList, QId),
									Packet2		= msg_notice_goods2(Player, GoodsList, QId),
									team_api:broadcast_team(Player, Packet1),
									misc_app:broadcast_world(Packet2),
									misc_packet:send(UserId, <<NewPacket/binary, Packet/binary>>),
									{?ok, Player2};
								_ -> {?ok, Player}
							end;
						?CONST_MCOPY_Q_COIN ->  %% 铜钱
							player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, GoldBind, ?CONST_COST_MCOPY_Q_REWARD),
							msg_notice_money(Player, QId, GoldBind),
							{?ok, Player};
						?CONST_MCOPY_Q_EXP ->  %%经验
							msg_notice_exp(Player, QId, Exp),
							player_api:exp(Player, Exp);
						?CONST_MCOPY_Q_MER ->  %% 功勋
							msg_notice_mer(Player, QId, Meritorious),
							player_api:plus_meritorious(Player, Meritorious, ?CONST_COST_MCOPY_Q_REWARD)
					end;
				{?error, _} ->                         %% 超过次数 奖励提示
					TipPacket		= message_api:msg_notice(?TIP_MCOPY_GET_NOTHING),
					misc_packet:send(UserId, TipPacket),
					{?ok, Player}
			end
	end;
get_award_cb(Player, {BuffId, BuffRate, MapId, TeamId}) ->                       						%% 获取buff加成
	UserId 			= Player#player.user_id,
	RobotList		= team_api:get_robot_list(?CONST_ETS_TEAM_INFO_COPY, TeamId),
	MapSerId		= mcopy_api:get_serial_id(MapId),
	case lists:member(UserId, RobotList) of
		?true  -> {?ok, Player};
		?false -> 
			case mcopy_mod:check_play_times(Player, MapSerId) of
				?ok ->
					McopyBuffList 	= get_buff_list(BuffId, BuffRate),
					msg_notice_buff(Player, BuffRate, BuffId),
					Player1			= Player#player{mcopy_buff = McopyBuffList},
					NewPlayer 		= refresh_buff(Player1, [BuffId, BuffRate]),
					{?ok, NewPlayer};
				{?error, _} ->							%% 超过次数 奖励提示
					TipPacket		= message_api:msg_notice(?TIP_MCOPY_GET_NOTHING),
					misc_packet:send(Player#player.net_pid, TipPacket),
					{?ok, Player}
			end
	end.

%% 根据buffId获取buff列表
get_buff_list(1, Rate) ->
	[{?CONST_PLAYER_ATTR_HP_MAX, Rate}];
get_buff_list(2, Rate) ->
	[{?CONST_PLAYER_ATTR_FORCE_ATTACK, Rate}, {?CONST_PLAYER_ATTR_MAGIC_ATTACK, Rate}];
get_buff_list(3, Rate) ->
	[{?CONST_PLAYER_ATTR_FORCE_DEF, Rate}, {?CONST_PLAYER_ATTR_MAGIC_DEF, Rate}];
get_buff_list(4, Rate) ->
	[{?CONST_PLAYER_ATTR_SPEED, Rate}];
get_buff_list(5, Rate) ->
	[{?CONST_PLAYER_ATTR_HP_MAX, Rate}, {?CONST_PLAYER_ATTR_FORCE_ATTACK, Rate}, {?CONST_PLAYER_ATTR_MAGIC_ATTACK, Rate},
	{?CONST_PLAYER_ATTR_SPEED, Rate}].

refresh_attr([{Type, Value}|Tail], OldList) ->
	?MSG_DEBUG("Type=~p, OldList=~p", [Type, OldList]),
    BuffType = get_buff_type(Type),
    NewList = [{BuffType, Value, ?CONST_SYS_NUMBER_TEN_THOUSAND}|OldList],
    refresh_attr(Tail, NewList);
refresh_attr([], OldList) ->
    OldList.

get_buff_type(4) ->         %% 气血
	?CONST_PLAYER_ATTR_HP_MAX;
get_buff_type(5) ->         %% 物攻
	?CONST_PLAYER_ATTR_FORCE_ATTACK;
get_buff_type(7) ->			%% 法攻
	?CONST_PLAYER_ATTR_MAGIC_ATTACK;
get_buff_type(6) ->         %% 物防
	?CONST_PLAYER_ATTR_FORCE_DEF;
get_buff_type(8) ->         %% 法防
	?CONST_PLAYER_ATTR_MAGIC_DEF;
get_buff_type(9) ->			%%　速度
	?CONST_PLAYER_ATTR_SPEED.

%% 刷新buff
refresh_buff(Player, [1, Rate]) ->%% 生命
	McopyBuffList 	= get_buff_list(1, Rate), 
	Packet 			= mcopy_api:msg_sc_buff([{1, Rate}]),                    %% 返回buff信息
	misc_packet:send(Player#player.net_pid, Packet),
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = McopyBuffList});
refresh_buff(Player, [2, Rate]) ->%% 攻击(物攻 + 法攻)
	McopyBuffList 	= get_buff_list(2, Rate), 
	Packet 			= mcopy_api:msg_sc_buff([{2, Rate}]),                    %% 返回buff信息
	misc_packet:send(Player#player.net_pid, Packet),
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = McopyBuffList});
refresh_buff(Player, [3, Rate]) ->%% 防御(物防 + 法防)
	McopyBuffList 	= get_buff_list(3, Rate), 
	Packet 			= mcopy_api:msg_sc_buff([{3, Rate}]),                    %% 返回buff信息
	misc_packet:send(Player#player.net_pid, Packet),
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = McopyBuffList});
refresh_buff(Player, [4, Rate]) ->%% 速度
	McopyBuffList 	= get_buff_list(4, Rate), 
	Packet 			= mcopy_api:msg_sc_buff([{4, Rate}]),                    %% 返回buff信息
	misc_packet:send(Player#player.net_pid, Packet),
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = McopyBuffList});
refresh_buff(Player, [5, Rate]) ->%% 全加
	McopyBuffList 	= get_buff_list(5, Rate), 
	Packet 			= mcopy_api:msg_sc_buff([{1, Rate}, {2, Rate}, {3, Rate}, {4, Rate}]), %% 返回buff信息
	misc_packet:send(Player#player.net_pid, Packet),
	player_attr_api:refresh_mcopy_buff(Player#player{mcopy_buff = McopyBuffList}).

%%-----------------------------------------------------------------------------------------------------------
%% 副本列表
%% {?ok, List, NewPacket}
list_mcopy(Player) ->
	McopyData 		= Player#player.mcopy,
	List 			= McopyData#mcopy_data.list,
	Times			= McopyData#mcopy_data.times,
	Count			= get_enter_max_times(?CONST_SYS_TRUE),
	LeftTimes		= Count - Times,
	NewPacket1		= case LeftTimes < ?CONST_SYS_FALSE of
						  ?true  -> msg_sc_left_times(?CONST_SYS_FALSE);
						  ?false -> msg_sc_left_times(LeftTimes)
					  end,
	delete_mcopy_info(Player#player.user_id),
	{?ok, List, NewPacket1}.

%% 完成任务开启模块Id
update_mcopy(Player) ->
    RankId = Player#player.sys_rank,
    SysId = data_guide:get_sys_id_by_rank_id(RankId),
	McopyData		= Player#player.mcopy,
	McopyList		= McopyData#mcopy_data.list,
	case data_mcopy:get_mcopy_id(SysId) of
		?null   -> Player;
		McopyId ->
			IdList	=case lists:member(McopyId, McopyList) of
						 ?true  -> McopyList;
						 ?false -> [McopyId|McopyList]
					 end,
			NewMcopyData	= McopyData#mcopy_data{list = IdList},
			Player#player{mcopy = NewMcopyData}
	end.
	
%% 读取副本每天进入的次数
get_enter_max_times(McopySerId) ->
	case data_mcopy:get_mcopy_serial(McopySerId) of
		MCopySerial when is_record(MCopySerial, mcopy_serial) ->
			MCopySerial#mcopy_serial.daily_count;
		_ -> ?CONST_MCOPY_ENTER_MAX
	end.


%% 读取副本系列信息
read_inner(MCopySerId) ->
    case data_mcopy:get_mcopy_serial(MCopySerId) of
        RecMCopySerial when is_record(RecMCopySerial, mcopy_serial) ->
            RecMCopySerial;
        _ ->
            throw({?error, ?TIP_COMMON_BAD_ARG})
    end.

%% 读取当前副本信息
get_current_mcopy_ser(#player{team_id = TeamId}) when 0 =/= TeamId ->
    try
		?MSG_DEBUG("111111111111111 TeamId=~p", [TeamId]),
        {?ok, Team}		= get_team(TeamId),
        TeamParam		= Team#team.param,
        MCopySerId		= TeamParam#team_param.id,
        RecMCopySerial	= read_inner(MCopySerId),
		?MSG_DEBUG("111111111111111", []),
        {?ok, RecMCopySerial}
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", [Type, Why, ErrorStack]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end;
get_current_mcopy_ser(#player{team_id = 0}) ->
	?MSG_DEBUG("111111111111111", []),
    {?error, ?TIP_TEAM_NO_THIS_TEAM}.

process_send(UserList, M, F, A) ->
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

%% 判断玩家是否开启了多人副本
check_team_play(Player, Id, ?CONST_TEAM_CHECK_CREATE) ->     %% 组队创建检查
	mcopy_mod:check_team_play(Player, Id);
check_team_play(Player, Id, ?CONST_TEAM_CHECK_INVITE) ->     %% 组队邀请检查
	mcopy_mod:check_team_play1(Player, Id);
check_team_play(Player, Id, ?CONST_TEAM_CHECK_JOIN) ->       %% 组队加入检查
	mcopy_mod:check_team_play(Player, Id);
check_team_play(_Player, _Id, _) ->                          %% 回复接受加入队伍
	?ok.

%% 根据地图id获取系列id
get_serial_id(MapId) ->
	case data_mcopy:get_mcopy(MapId) of
		McopyData when is_record(McopyData, rec_mcopy) ->
			McopyData#rec_mcopy.serial_id;
		_ -> ?CONST_SYS_FALSE                               %% 参数错误
	end.

%%根据地图id获取标志位
check_minus_times(MapId) ->
	case data_mcopy:get_mcopy(MapId) of
		McopyData when is_record(McopyData, rec_mcopy) ->
			McopyData#rec_mcopy.flag1;
		_ -> ?CONST_SYS_FALSE
	end.

%% 根据地图创建跳转点
create_skip(MapId) ->
	case data_mcopy:get_mcopy(MapId) of
		McopyData when is_record(McopyData, rec_mcopy) ->
			SkipPoint		= McopyData#rec_mcopy.skip_1,
			msg_point(SkipPoint);
		_ -> <<>>
	end.

%% 判断特殊地图
check_special_map(MapId) when is_integer(MapId) ->
	case data_mcopy:get_mcopy(MapId) of
		McopyData when is_record(McopyData, rec_mcopy) ->
			SkipPoint2		= McopyData#rec_mcopy.skip_2,
			IsMinus			= McopyData#rec_mcopy.flag1,
			case {IsMinus, SkipPoint2 =/= ?CONST_SYS_FALSE} of
				{?CONST_SYS_TRUE, ?true} -> ?true;
				{_, _} -> ?false
			end;
		_ -> ?false
	end.

%% 获取进入此张地图几次
get_enter_times(Player, MapId) when is_record(Player, player)->
	UserId		= Player#player.user_id,
	case get_mcopy_info(UserId) of
		McopyInfo when is_record(McopyInfo, mcopy_info) ->
			InfoList = McopyInfo#mcopy_info.info,
			case lists:keyfind(MapId, 1, InfoList) of
				{_, Times, _} -> Times;
				_ -> ?CONST_SYS_FALSE
			end;
		_ -> 
            case Player#player.team_id of
                {_TeamId, NodeId} ->
                    Node = cross_api:get_node(NodeId),
                    rpc:call(Node, ?MODULE, get_enter_times, [UserId, MapId]);
                _ ->
                    ?CONST_SYS_FALSE
            end
	end;

get_enter_times(UserId, MapId) ->
    case get_mcopy_info(UserId) of
        McopyInfo when is_record(McopyInfo, mcopy_info) ->
            InfoList = McopyInfo#mcopy_info.info,
            case lists:keyfind(MapId, 1, InfoList) of
                {_, Times, _} -> Times;
                _ -> ?CONST_SYS_FALSE
            end;
        _ -> 
            ?CONST_SYS_FALSE
    end.

%% 检查多人副本活动是否结束(多人组队模块调用)
check_play_over() ->
	?false.

%% 读取怪物信息
get_mon_reward(MonId) ->
    case monster_api:monster(MonId) of
        Monster when is_record(Monster, monster) ->
            Exp         = Monster#monster.hook_exp*2,
    		Meritorious = Monster#monster.meritorious,
    		Gold        = Monster#monster.gold,
   			DropId      = Monster#monster.drop_id,
    		{Exp, Meritorious, Gold, DropId};
        _ ->
			{?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE}
    end.
%%------------------------------------------------------------------------------------------------------
%% 消息提示 和全服广播
msg_notice_exp(Player, QId, Exp) ->
	UserName	= (Player#player.info)#info.user_name,
	TipPacket 	= message_api:msg_notice(?TIP_MCOPY_BOX_EXP, [{?TIP_SYS_COMM, misc:to_list(Exp)}]),
	List		= [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_QIYU, misc:to_list(QId)}, {?TIP_SYS_COMM, misc:to_list(Exp)}],
	Packet		= message_api:msg_notice(?TIP_MCOPY_Q_EXP, List),
	team_api:broadcast_team(Player, Packet),
	misc_packet:send(Player#player.net_pid, TipPacket).
msg_notice_money(Player, QId, Gold) ->
	UserName	= (Player#player.info)#info.user_name,
	TipPacket 	= message_api:msg_notice(?TIP_MCOPY_BOX_GOLD, [{?TIP_SYS_COMM, misc:to_list(Gold)}]),
	List		= [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_QIYU, misc:to_list(QId)}, {?TIP_SYS_COMM, misc:to_list(Gold)}],
	Packet		= message_api:msg_notice(?TIP_MCOPY_Q_GOLD, List),
	team_api:broadcast_team(Player, Packet),
	misc_packet:send(Player#player.net_pid, TipPacket).
msg_notice_mer(Player, QId, Meritorious) ->
	UserName	= (Player#player.info)#info.user_name,
	TipPacket 	= message_api:msg_notice(?TIP_MCOPY_BOX_MET, [{?TIP_SYS_COMM, misc:to_list(Meritorious)}]),
	List		= [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_QIYU, misc:to_list(QId)}, {?TIP_SYS_COMM, misc:to_list(Meritorious)}],
	Packet		= message_api:msg_notice(?TIP_MCOPY_Q_MET, List),
	team_api:broadcast_team(Player, Packet),
	misc_packet:send(Player#player.net_pid, TipPacket).
msg_notice_goods([Goods|GoodsList], QId, Acc) when is_record(Goods, goods) ->
	GoodsName	= Goods#goods.name,
	Packet		= message_api:msg_notice(?TIP_MCOPY_BOX_GOODS, [{?TIP_SYS_COMM, GoodsName}]),
	NewAcc		= <<Packet/binary, Acc/binary>>,
	msg_notice_goods(GoodsList, QId, NewAcc);
msg_notice_goods([], _, Acc) ->
	Acc.
msg_notice_goods1(Player, GoodsList, QId) ->
	UserName  = (Player#player.info)#info.user_name,
	Goods 	  = [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	case Goods of
		[] -> <<>>;
		_  ->
			List	  = [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_QIYU, misc:to_list(QId)}],
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_Q_GOODS_EQUIP, [], [GoodsInfo], List),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_Q_GOODS, [], [GoodsInfo], List),
								<<Packet/binary, Acc/binary>>
						end
				end,
			lists:foldl(F, <<>>, Goods)
	end.

msg_notice_goods2(Player, GoodsList, QId) ->
	UserName  = (Player#player.info)#info.user_name,
	Goods 	  = [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	case Goods of
		[] -> <<>>;
		_  ->
			List	  = [{?TIP_SYS_COMM, UserName}, {?TIP_SYS_QIYU, misc:to_list(QId)}],
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_Q_GOODS_EQUIP1, [], [GoodsInfo], List),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_Q_GOODS1, [], [GoodsInfo], List),
								<<Packet/binary, Acc/binary>>
						end
				end,
			lists:foldl(F, <<>>, Goods)
	end.

%% 翻牌奖励提示
msg_notice_vip_award(Player, MapId, GoodsList) ->
	UserId	  = Player#player.user_id,
	UserName  = (Player#player.info)#info.user_name,
	Goods 	  = [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	case Goods of
		[] -> <<>>;
		_  ->
			List	  = [{?TIP_SYS_MCOPY, misc:to_list(MapId)}],
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_TIP_MCOPY_VIP_EQUIP_REWARD, [{UserId, UserName}],
																[GoodsInfo], List),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_MCOPY_VIP_REWARD, [{UserId, UserName}],[GoodsInfo],
																  List),
								<<Packet/binary, Acc/binary>>
						end
				end,
			lists:foldl(F, <<>>, Goods)
	end.

%% 提示获得buff
msg_notice_buff(Player, Rate, 1) ->
	TipPacket = message_api:msg_notice(?TIP_MCOPY_BUFF_HP, [{?TIP_SYS_COMM, misc:to_list(Rate)}]),
	misc_packet:send(Player#player.net_pid, TipPacket);
msg_notice_buff(Player, Rate, 2) ->
	TipPacket = message_api:msg_notice(?TIP_MCOPY_BUFF_ATT, [{?TIP_SYS_COMM, misc:to_list(Rate)}]),
	misc_packet:send(Player#player.net_pid, TipPacket);
msg_notice_buff(Player, Rate, 3) ->
	TipPacket = message_api:msg_notice(?TIP_MCOPY_BUFF_DEF, [{?TIP_SYS_COMM, misc:to_list(Rate)}]),
	misc_packet:send(Player#player.net_pid, TipPacket);
msg_notice_buff(Player, Rate, 4) ->
	TipPacket = message_api:msg_notice(?TIP_MCOPY_BUFF_SPEED, [{?TIP_SYS_COMM, misc:to_list(Rate)}]),
	misc_packet:send(Player#player.net_pid, TipPacket);
msg_notice_buff(Player, Rate, 5) ->
	TipPacket = message_api:msg_notice(?TIP_MCOPY_ALL_BUFF, [{?TIP_SYS_COMM, misc:to_list(Rate)}, {?TIP_SYS_COMM, misc:to_list(Rate)}, 
		{?TIP_SYS_COMM, misc:to_list(Rate)}, {?TIP_SYS_COMM, misc:to_list(Rate)}]),
	misc_packet:send(Player#player.net_pid, TipPacket).
%%------------------------------------------------------------------------------------------------------------------------------
%% ets 操作相关
get_mcopy_info(UserId) ->                 %% 获取副本信息
	ets_api:lookup(?CONST_ETS_MCOPY_INFO, UserId).

delete_mcopy_info(UserId) ->
	ets_api:delete(?CONST_ETS_MCOPY_INFO, UserId).

insert_mcopy_info(Info) ->
	ets_api:insert(?CONST_ETS_MCOPY_INFO, Info).

get_team(TeamId)  ->  %% 获取多人副本组队信息
	team_api:get_team(?CONST_ETS_TEAM_INFO_COPY, TeamId).

%% Gm 相关
reset_times(Player, Num) ->
	McopyData	 	= Player#player.mcopy,
	Times			= case Num > 3 of
						  ?true  -> ?CONST_SYS_FALSE;
						  ?false -> 3 - Num
					  end,
	NewMcopyData 	= McopyData#mcopy_data{times = Times},
	NewPlayer		= Player#player{mcopy = NewMcopyData},
	{?ok, NewPlayer}.
					
%%
%% Local Functions
%%
%% 返回(创建奇遇物41002)
%%[EncounterId,IsCreate]
msg_encounter(EncounterId,IsCreate) ->
    misc_packet:pack(?MSG_ID_MCOPY_ENCOUNTER, ?MSG_FORMAT_MCOPY_ENCOUNTER, [EncounterId,IsCreate]).
%% 返回(创建跳转点41004)
%%[PointId,IsCreate]
msg_point(PointId) ->
    misc_packet:pack(?MSG_ID_MCOPY_POINT, ?MSG_FORMAT_MCOPY_POINT, [PointId]).
%% 返回(创建栅栏41010)
msg_bar(1, IsTick) ->
	misc_packet:pack(?MSG_ID_MCOPY_SC_BAR, ?MSG_FORMAT_MCOPY_SC_BAR, [1, IsTick]).
%% 返回(成功进入副本41012)
msg_enter_mcopy(Result) ->
	misc_packet:pack(?MSG_ID_MCOPY_SC_ENTER, ?MSG_FORMAT_MCOPY_SC_ENTER, [Result]).
%% 副本列表(41008)
%%[CopyId,Times]
msg_sc_list_copy(List) ->
    misc_packet:pack(?MSG_ID_MCOPY_SC_LIST_COPY, ?MSG_FORMAT_MCOPY_SC_LIST_COPY, [List]).
%% Vip奖励(41202)
%%[GoodsId,Count, Type]
msg_sc_award(GoodsId, GoodsNum, Type) ->
    misc_packet:pack(?MSG_ID_MCOPY_SC_AWARD, ?MSG_FORMAT_MCOPY_SC_AWARD, [GoodsId, GoodsNum, Type]).
%% 返回buff
msg_sc_buff(BuffList) ->
	misc_packet:pack(?MSG_ID_MCOPY_SC_BUFF, ?MSG_FORMAT_MCOPY_SC_BUFF, [BuffList]).
%% 退出副本返回(41302)
msg_sc_quit_mcopy(State) ->
	misc_packet:pack(?MSG_ID_MCOPY_SC_EXIT, ?MSG_FORMAT_MCOPY_SC_EXIT, [State]).
%% 返回副本通关奖励(41402)
msg_sc_mcopy_end(CopyId, Flag, GoodsList, Evaluate, Exp, Gold, PlotId, AtkPoint,DefPoint, PassTime) ->
	F = fun(#goods{goods_id = GoodsId, count = Count}, ListOld) ->
                [{GoodsId, Count}|ListOld]
        end,
    NewList = lists:foldl(F, [], GoodsList),
	misc_packet:pack(?MSG_ID_MCOPY_SC_END, ?MSG_FORMAT_MCOPY_SC_END, 
					 [CopyId, Flag, NewList, Evaluate, Exp, Gold, PlotId, AtkPoint, DefPoint, PassTime]).
%% 封怪物信息包
packet_mon_info(Monster) ->
    MonId  = Monster#monster.monster_id,
    X      = Monster#monster.x,
    Y      = Monster#monster.y,
    msg_sc_monster_info(MonId, MonId, X, Y).

%% 怪物信息
%%[MonsterId,MonsterUniqueId,X,Y]
msg_sc_monster_info(MonsterId, MonsterId, X, Y) ->
    misc_packet:pack(?MSG_ID_MCOPY_MONSTER, ?MSG_FORMAT_MCOPY_MONSTER, [MonsterId, MonsterId, X, Y]).
%% 剩余次数返回
msg_sc_left_times(Times) ->
	misc_packet:pack(?MSG_ID_MCOPY_SC_LEFT_TIMES, ?MSG_FORMAT_MCOPY_SC_LEFT_TIMES, [Times]).