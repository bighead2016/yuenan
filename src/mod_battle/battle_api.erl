%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to battle_api
-module(battle_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.cost.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").

-include("record.player.hrl").
-include("record.partner.hrl").
-include("record.battle.hrl").
-include("record.map.hrl").
-include("record.data.hrl").
-include("record.robot.hrl").
-include("record.goods.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([start/3, operate/2, offline/1, set_battle_sleep/2, auto_battle/2, auto_select_skill/3]).
-export([
		 get_battle_reward/4,
		 do_battle_over/2,
		 get_units_hp/1,
		 set_units_hp/2,
         set_units_hp/4
		]).
-export([
		 msg_battle_start/1,
		 msg_sc_stop/1,
		 msg_battle_seq/1,
		 msg_battle_horse_skill/7,
		 msg_battle_cmd_data/1,
		 msg_battle_refresh_bout/4,
		 msg_battle_operate_notice/3,
		 msg_sc_over/7,
         msg_sc_skip_info/2,
         msg_sc_report_list/2
		]).

%%
%% API Functions
%%
start(Player, Id, Param) ->
    IsRobot = lists:member(Player#player.user_id, Param#param.robot),
    if
        [] =:= Param#param.robot orelse ?false =:= IsRobot ->
        	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_FIGHTING) of
        		{?true, Player2} ->
        			case battle_mod:start(Player2, Id, Param) of
        				{?ok, Player3} ->
                            {?ok, Player3};
        				{?error, ErrorCode} ->
                            {?error, ErrorCode}
        			end;
        		_Other ->
        			{?error, ?TIP_BATTLE_OFF}
        	end;
        ?true ->
            case battle_mod:start(Player, Id, Param) of
                {?ok, Player3} ->
                    {?ok, Player3};
                {?error, ErrorCode} -> 
                    {?error, ErrorCode}
            end
    end.

%% 操作
operate(Player, SkillIdx)
  when SkillIdx >= 0 andalso
	   SkillIdx =< ?CONST_SKILL_SKILL_BAR_COUNT ->
    UserId      = Player#player.user_id,
    BattlePid   = Player#player.battle_pid,
    Info = Player#player.info,
    Lv = Info#info.lv,
    if
        ?CONST_PLAYER_PLAY_MULTI_ARENA =:= Player#player.play_state ->
            battle_serv:cross_cast(operate_cast, [BattlePid, UserId, SkillIdx]);
        ?CONST_PLAYER_PLAYER_CAMP_PVP =:= Player#player.play_state ->
            battle_serv:cross_cast(UserId, Lv, operate_cast, [BattlePid, UserId, SkillIdx]);
        ?true ->
            battle_serv:operate_cast(BattlePid, UserId, SkillIdx)
    end,
	{?ok, Player};
operate(Player, _SkillIdx) ->
	{?ok, Player}.

%% 自动战斗
auto_battle(Player, IsAuto) ->
    UserId      = Player#player.user_id,
    BattlePid   = Player#player.battle_pid,
    Info = Player#player.info,
    Lv = Info#info.lv,
    IsAutoOld = Info#info.is_auto,
    case IsAutoOld =/= IsAuto andalso erlang:is_pid(BattlePid) of
		?true ->
            if
                ?CONST_PLAYER_PLAY_MULTI_ARENA =:= Player#player.play_state ->
                    battle_serv:cross_cast(auto_battle_cast, [BattlePid, UserId, IsAuto]);
                ?CONST_PLAYER_PLAYER_CAMP_PVP =:= Player#player.play_state ->
                    battle_serv:cross_cast(UserId, Lv, auto_battle_cast, [BattlePid, UserId, IsAuto]);
                ?true ->
                    battle_serv:auto_battle_cast(BattlePid, UserId, IsAuto)
            end,
        	{?ok, Player#player{info = Info#info{is_auto = IsAuto}}};
        ?false ->
            {?ok, Player}
    end.

offline(Player = #player{battle_pid = BattlePid})
  when is_pid(BattlePid) ->
    UserId      = Player#player.user_id,
    Info = Player#player.info,
    Lv = Info#info.lv,
    if
        ?CONST_PLAYER_PLAY_MULTI_ARENA =:= Player#player.play_state ->
            battle_serv:cross_cast(offline_cast, [BattlePid, UserId]);
        ?CONST_PLAYER_PLAYER_CAMP_PVP =:= Player#player.play_state ->
            battle_serv:cross_cast(UserId, Lv, offline_cast, [BattlePid, UserId]);
        ?true ->
            battle_serv:offline_cast(BattlePid, UserId)
    end,
	{?ok, Player#player{battle_pid = 0}};
offline(Player) ->
	{?ok, Player}.

set_battle_sleep(BattlePid, Sleep) ->
	battle_serv:set_battle_sleep_cast(BattlePid, Sleep).

auto_select_skill(Battle, Side, Unit) ->
	Idx			= Unit#unit.idx,
	Key			= battle_mod_misc:key(Side, Idx),
	Speed		= ((Unit#unit.attr)#attr.attr_second)#attr_second.speed,
	case lists:keymember(Key, #operate.key, Battle#battle.seq) of
		?true ->
			{SkillIdx, Skill, Packet} =
				case battle_mod_misc:auto_select_skill(Unit) of
					{?ok, 0, SkillTemp} -> {0, SkillTemp, <<>>};
					{?ok, SkillIdxTemp, SkillTemp} ->
						{SkillIdxTemp, SkillTemp,
						 battle_api:msg_battle_operate_notice(Side, Idx, SkillTemp#skill.skill_id)};
					_ -> {0, Unit#unit.normal_skill, <<>>}
				end,
			RecOperate	= battle_mod_misc:record_operate(Key, Speed, SkillIdx, Skill),
			Seq			= lists:keyreplace(Key, #operate.key, Battle#battle.seq, RecOperate),
			{Battle#battle{seq = Seq}, Packet};
		?false -> {Battle, <<>>}
	end.

%% 战斗结束奖励
get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_LEFT} = Battle, UserId, MonsterList, _Result) 
  when Battle#battle.type =:= ?CONST_BATTLE_SINGLE_COPY orelse
       Battle#battle.type =:= ?CONST_BATTLE_TRIBE_COPY ->
	Point		= ?CONST_COST_BATTLE_REWARD,
	MonsterId	= (Battle#battle.units_right)#units.id,
	Monster 	= monster_api:monster(MonsterId),
	
	Score		= 100,	%% 评分预留
	Exp 		= Monster#monster.exp,
    Lv2         = 
        case battle_mod_misc:key(Battle, ?CONST_SYS_PLAYER, UserId) of
            {Side, Idx} ->
                Unit    = battle_mod_misc:get_unit(Battle, Side, Idx),
                Unit#unit.lv;
            ?null ->
                0
        end,
    RankRate    = rank_api:get_rank_rate(Lv2),
    Exp2        = round(Exp*RankRate),
	Gold		= Monster#monster.gold,
	Meritorious	= Monster#monster.meritorious,
	GoodsList	= goods_api:goods_drop(Monster#monster.drop_id),
	{Point, Score, Exp2, Gold, Meritorious, 0, GoodsList, MonsterList, 0, 0, 0, 0};
get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_LEFT} = Battle, _UserId, MonsterList, _Result) 
  when Battle#battle.type =:= ?CONST_BATTLE_SINGLE_COPY orelse
	   Battle#battle.type =:= ?CONST_BATTLE_TOWER orelse
	   Battle#battle.type =:= ?CONST_BATTLE_INVASION_GUARD ->
	Point		= ?CONST_COST_BATTLE_REWARD,
	MonsterId	= (Battle#battle.units_right)#units.id,
	Monster 	= monster_api:monster(MonsterId),
	
	Score		= 100,	%% 评分预留
	Exp 		= Monster#monster.exp,
	Gold		= Monster#monster.gold,
	Meritorious	= Monster#monster.meritorious,
	GoodsList	= goods_api:goods_drop(Monster#monster.drop_id),
	{Point, Score, Exp, Gold, Meritorious, 0, GoodsList, MonsterList, 0, 0, 0, 0};

get_battle_reward(Battle, UserId, MonsterList, Result)
    when Battle#battle.type =:= ?CONST_BATTLE_CAMP_PVP ->
    Point       = ?CONST_COST_BATTLE_REWARD,
    Param = Battle#battle.param,
    Score       = 100,  %% 评分预留
    {Gold, ScoreAdd, StreakTime, StreakScore, Hurt, Jiangyin} = camp_pvp_api:get_reward_hurt(UserId, Battle, Result),
    {Point, Score, 0, Gold, 0, 0, [], MonsterList, 0, 0, StreakScore, 0, Hurt, Param#param.ad3, StreakTime, ScoreAdd, Jiangyin, 0};

get_battle_reward(Battle, UserId, MonsterList, Result)
  when Battle#battle.type =:= ?CONST_BATTLE_GUILD_PVP ->
	Score       = 100,  %% 评分预留
	Gold = case ets:lookup(?CONST_ETS_GUILD_PVP_PLAYER, UserId) of
			   [] ->
                   Score1 = 0,
				   0 ;
			   [UserRec] ->
				   case Result of 
						1 ->
                            Score1 = 10,
                            ?FUNC_GUILD_PVP_WINNER(UserRec#guild_pvp_player.lv);
						_ ->
                            Score1 = 1,
                            ?FUNC_GUILD_PVP_LOSEER(UserRec#guild_pvp_player.lv)
                             
					end				   		
		   end,
    guild_pvp_mod:add_player_guild_pvp_copper(UserId, Gold),
	{0, Score, 0, Gold, 0, 0, [], MonsterList, 0, 0, 0, 0, 0, 0, 0, Score1, 0, 0};

get_battle_reward(Battle, UserId, MonsterList, _Result)
  when Battle#battle.type =:= ?CONST_BATTLE_GUILD_PVE ->
	Score       = 100,  %% 评分预留
	Hurt = guild_pvp_mod:get_and_boss_hurt(UserId),
    Score1 = round((Hurt div 10000) + 1),
    Gold = Hurt div 200,
    guild_pvp_mod:add_player_guild_pvp_copper(UserId, Gold),
	{0, Score, 0, Gold, 0, 0, [], MonsterList, 0, 0, 0, 0, Hurt, 0, 0, Score1, 0, 0};

get_battle_reward(Battle, UserId, MonsterList, _Result)
	when Battle#battle.type =:= ?CONST_BATTLE_BOSS ->
	Point		= ?CONST_COST_BATTLE_REWARD,
	Param		= Battle#battle.param,
%% 	UserId		= (Battle#battle.units_left)#units.id,
	MonsterId	= (Battle#battle.units_right)#units.id,
	Monster 	= monster_api:monster(MonsterId),
	Score		= 100,	%% 评分预留
	Exp 		= Monster#monster.exp,
	GoodsList	= goods_api:goods_drop(Monster#monster.drop_id),
	IsRobot		= lists:member(UserId, Param#param.robot),
	{
	 Gold, _Experience, Meritorious
	}			= boss_api:get_reward_hurt(UserId, IsRobot),
	{Point, Score, Exp, Gold, Meritorious, 0, GoodsList, MonsterList, 0, 0, 0, 0};

get_battle_reward(Battle, _UserId, _MonsterList, Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_SINGLE_ARENA ->
	Left 		= Battle#battle.units_left,
	Unit		= battle_mod_misc:get_unit_by_id(Battle, ?CONST_SYS_PLAYER, Left#units.id),
	Lv			= Unit#unit.lv,
	[Point, Meritorious, _Experience] 
				= single_arena_api:get_challenge_reward(Lv, Result),
	Multiple = guild_api:get_arena_add(Left#units.id),
	%misc:ceil(Experience * (Multiple + 1))
	{Point, 0, 0, 0, misc:ceil(Meritorious * (Multiple + 1)), 0, [], [], 0, 0, 0, 0};

get_battle_reward(Battle, _UserId, _MonsterList, _Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_SINGLE_ROBOT ->
	{?CONST_COST_SINGLE_ARENA_BATTLE, 0, 0, 0, 0, 0, [], [], 0, 0, 0, 0};

get_battle_reward(Battle, UserId, _MonsterList, Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_TRIBE_ARENA ->
	Point		= ?CONST_COST_BATTLE_REWARD,
	{?ok, AddHufu, AddScore, StreakWinScore, Gold, StreakTimes} = arena_pvp_api:get_reward(UserId, Result),
	{Point, 0, 0, Gold, 0, 0, [], [], AddScore, AddHufu, StreakWinScore, StreakTimes};

get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_LEFT} = Battle, _UserId, _MonsterList, _Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_CROSS_ARENA_ROBOT ->
	RecReward		= data_cross_arena:get_cross_arena_reward({2, 1, 1}),
	Meritorious		= RecReward#rec_cross_arena_reward.meritorious,
	Gold			= RecReward#rec_cross_arena_reward.coin,
	{0, 0, 0, Gold, Meritorious, 0, [], [], 0, 0, 0, 0};

get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_LEFT} = Battle, _UserId, _MonsterList, _Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_CROSS_ARENA ->
	RecReward		= data_cross_arena:get_cross_arena_reward({2, 1, 1}),
	Meritorious		= RecReward#rec_cross_arena_reward.meritorious,
	Gold			= RecReward#rec_cross_arena_reward.coin,
	Score			= ?CONST_CROSS_ARENA_WIN_SCORE,
	{0, 0, 0, Gold, Meritorious, 0, [], [], 0, 0, 0, 0, 0, 0, 0, 0, 0, Score};
get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_LEFT, param = Param, bout = Bout} = Battle, _UserId, _MonsterList, _Result) 
    when Battle#battle.type =:= ?CONST_BATTLE_TEACH ->
    RecTeach        = Param#param.ad1,
    Eq              = teach_api:calc_eq(RecTeach, Bout),
    Eq2             =   case Eq of
                            ?CONST_TEACH_EQ_0 -> 4;
                            ?CONST_TEACH_EQ_1 -> 
                                case RecTeach of
                                    #rec_teach{type = ?CONST_TEACH_TYPE_SKILL} ->
                                        3;
                                    _ ->
                                        2
                                end;
                            ?CONST_TEACH_EQ_2 -> 1;
                            _ -> Eq
                        end,
    GoodsList       = teach_api:calc_goods(Param#param.ad4, Eq, Param#param.ad1),
    GoodsList2      = teach_api:sum_goods(GoodsList, []),
    {0, Eq2, 0, 0, 0, 0, GoodsList2, [], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_RIGHT} = Battle, _UserId, _MonsterList, _Result) 
    when Battle#battle.type =:= ?CONST_BATTLE_TEACH ->
    {0, 4, 0, 0, 0, 0, [], [], 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

get_battle_reward(#battle{result = ?CONST_BATTLE_RESULT_RIGHT} = Battle, _UserId, _MonsterList, _Result) 
	when Battle#battle.type =:= ?CONST_BATTLE_CROSS_ARENA ->
	RecReward		= data_cross_arena:get_cross_arena_reward({2, 1, 1}),
	Meritorious		= RecReward#rec_cross_arena_reward.meritorious,
	Gold			= RecReward#rec_cross_arena_reward.coin,
	Score			= ?CONST_CROSS_ARENA_FAIL_SCORE,
	{0, 0, 0, Gold, Meritorious, 0, [], [], 0, 0, 0, 0, 0, 0, 0, 0, 0, Score};

%% get_battle_reward(Battle = #battle{result = ?CONST_BATTLE_RESULT_LEFT,type = ?CONST_BATTLE_PARTY}, _UserId, _MonsterList, _Result) ->
%% 	MonsterId	= (Battle#battle.units_right)#units.id,
%% 	Monster 	= monster_api:monster(MonsterId),
%% 	
%% 	Score		= 100,	%% 评分预留
%% 	Exp 		= Monster#monster.exp,
%% 	Gold		= Monster#monster.gold,	
%% 	GoodsList	= goods_api:goods_drop(Monster#monster.drop_id),
%% 	{Score, Exp, Gold, 0, 0, GoodsList, [], 0, 0, 0};

get_battle_reward(_Battle, _UserId, _MonsterList, _Result) ->
	Point		= ?CONST_COST_BATTLE_REWARD,
	{Point, 0, 0, 0, 0, 0, [], [], 0, 0, 0, 0}.


%% 将战斗结果通知玩家进程并更新玩家状态
notice_sc_over(UserId, MonId, {?CONST_BATTLE_BOSS = BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList) ->
%%     case lists:member(UserId, RobotList) of
%%         ?true ->
%% %%             case ets_api:lookup(?CONST_ETS_BOSS_PLAYER, UserId) of
%% %%                 #boss_player{boss_id = BossId} ->
%% %% %%                     case ets_api:lookup(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}) of
%% %% %%                         #ets_boss_robot_setting{bgold = OldBGold, meritorious = OldMeri} ->
%% %% %%                             ets:update_element(?CONST_ETS_BOSS_ROBOT_SETTING, {BossId, UserId}, [{#ets_boss_robot_setting.bgold, OldBGold+Gold},
%% %% %%                                                                                        {#ets_boss_robot_setting.meritorious, OldMeri+Meritorious}]);
%% %% %%                         _ ->
%% %% %%                             ?ok
%% %% %%                     end;
%% %%                 
%% %%                 _ ->
%% %%                     ?ok
%% %%             end;
%%             ?ok;
%%         _ ->
        	case player_api:get_player_pid(UserId) of
                Pid when is_pid(Pid) ->
        			player_api:process_send(Pid, battle_api, do_battle_over, 
        									{MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList});
        		_ -> ?ok
        	end;
%%     end;
notice_sc_over(UserId, MonId, {?CONST_BATTLE_INVASION_GUARD = BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
			player_api:process_send(UserId, battle_api, do_battle_over, 
									{MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList});
        [#cross_in{node = Node}] ->
            rpc:cast(Node, player_api, process_send, [UserId, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList}])
    end;

notice_sc_over(UserId, MonId, {?CONST_BATTLE_INVASION_ATTACK = BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            player_api:process_send(UserId, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList});
        [#cross_in{node = Node}] ->
            rpc:cast(Node, player_api, process_send, [UserId, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList}])
    end;

notice_sc_over(UserId, MonId, {?CONST_BATTLE_TRIBE_COPY = BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList) ->
    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
        [] ->
            player_api:process_send(UserId, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList});
        [#cross_in{node = Node}] ->
            rpc:cast(Node, player_api, process_send, [UserId, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList}])
    end;

notice_sc_over(UserId, MonId, {BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList) ->
    case player_api:get_player_pid(UserId) of
        Pid when is_pid(Pid) ->
            player_api:process_send(Pid, battle_api, do_battle_over, 
                                    {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList});
        _ -> ?ok
    end.

do_battle_over(Player, {MonId, BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList, RobotList} ) ->
	%% 根据战斗类型更新玩家状态
	case lists:member(Player#player.user_id, RobotList) of
		?true ->
			{?ok, Player};
		?false ->
			case check_battle_over(Player, BattleType, Result) of
				?ok ->
            		{?ok, Player2}  = update_player_state(Player, BattleType, Result),
					{?ok, Player3}	= player_api:exp(Player2, Exp),
					player_money_api:plus_money(Player3#player.user_id, ?CONST_SYS_GOLD_BIND, Gold, Point),
					Player4			= player_api:plus_experience(Player3, Experience),
					{?ok, Player5} 	= player_api:plus_meritorious(Player4, Meritorious, Point),
					Player6			= 
						case GoodsList of
							[]-> Player5;
							_Other ->
		                        case ctn_bag_api:put(Player5, GoodsList, ?CONST_COST_BATTLE_REWARD, 1, 1, 1, 0, 1, 1, []) of
									{?ok, Player5_2, _, _Packet} ->
										Player5_2;
									_ -> Player5
								end
						end,
					%% 处理消息(异民族战斗发送消息至队伍频道)
					exec_message(Player6, BattleType, Result, {MonId, GoodsList}),
					welfare_api:add_pullulation(Player6, ?CONST_WELFARE_BATTLE, 0, 1);
				{?error, _} -> 
                    update_player_state(Player, BattleType, Result)
			end
	end.

%% 根据战斗类型处理消息
exec_message(Player, BattleType, ?CONST_SYS_TRUE, {MonId, GoodsList}) 
  when BattleType =:= ?CONST_BATTLE_INVASION_GUARD orelse
		   BattleType =:= ?CONST_BATTLE_TRIBE_COPY -> %% 异民族 多人副本组队消息
	Goods 		= [GoodsInfo ||GoodsInfo <- GoodsList, GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE],
	UserName	= (Player#player.info)#info.user_name,
	List		= [{?TIP_SYS_MONSTER, misc:to_list(MonId)}],
	FinalList 	= [{?TIP_SYS_COMM, UserName}|List],
	case  Goods of
		[] ->
			?ok;
		_ ->
			F = fun(GoodsInfo, Acc) ->
						Type	= GoodsInfo#goods.type,
						case Type =:= ?CONST_GOODS_TYPE_EQUIP of
							?true ->
								Packet	= message_api:msg_notice(?TIP_INVASION_KILL_EQUIP_GOODS,[], [GoodsInfo], FinalList),
								<<Packet/binary, Acc/binary>>;
							?false ->
								Packet	= message_api:msg_notice(?TIP_INVASION_KILL_GOODS,[], [GoodsInfo], FinalList),
								<<Packet/binary, Acc/binary>>
						end
				end,
			MsgPacket = lists:foldl(F, <<>>, Goods),
			team_api:broadcast_team(Player, MsgPacket)
	end;
exec_message(_Player, _BattleType,_Result, _Args) ->
	?ok.

%% 战斗结算奖励判断
check_battle_over(Player, ?CONST_BATTLE_TRIBE_COPY, ?CONST_BATTLE_RESULT_LEFT) -> %% 多人副本
	MapId       = map_api:get_cur_map_id(Player),
	Id			= mcopy_api:get_serial_id(MapId),
	case mcopy_mod:check_play_times(Player, Id) of
		?ok -> ?ok;
		{?error, ErrorCode} ->
			TipPacket	= message_api:msg_notice(?TIP_MCOPY_GET_NOTHING),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ErrorCode}
	end;
check_battle_over(Player, ?CONST_BATTLE_INVASION_ATTACK, ?CONST_BATTLE_RESULT_LEFT) -> %% 异民族攻关
	Invasion 	= Player#player.invasion,
	Times		= Invasion#invasion.times,
	case Times >= 0 of
		?true -> ?ok;
		?false ->
			TipPacket	= message_api:msg_notice(?TIP_INVASION_GET_NOTHING),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ?TIP_INVASION_GET_NOTHING}
	end;
check_battle_over(Player, ?CONST_BATTLE_INVASION_GUARD, ?CONST_BATTLE_RESULT_LEFT) -> %% 异民族守关
	Invasion 	= Player#player.invasion,
	Times		= Invasion#invasion.times,
	case Times >= 0 of
		?true -> ?ok;
		?false ->
			TipPacket	= message_api:msg_notice(?TIP_INVASION_GET_NOTHING),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ?TIP_INVASION_GET_NOTHING}
	end;
check_battle_over(_Player, _BattleType, _) ->
	?ok.

%% 根据战斗类型更新玩家状态
update_player_state(Player, BattleType, ?CONST_BATTLE_RESULT_RIGHT)
  when BattleType =:= ?CONST_BATTLE_WORLD orelse
	   BattleType =:= ?CONST_BATTLE_PARTY orelse	   
	   BattleType =:= ?CONST_BATTLE_BOSS orelse
       BattleType =:= ?CONST_BATTLE_CAMP_PVP orelse
       BattleType =:= ?CONST_BATTLE_GUILD_PVE orelse
       BattleType =:= ?CONST_BATTLE_GUILD_PVP orelse
	   BattleType =:= ?CONST_BATTLE_INVASION_GUARD	->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_DEATH) of
		{?true, NewPlayer} ->
			{?ok, NewPlayer};
		{?false, NewPlayer} ->
			{?ok, NewPlayer}
	end;
update_player_state(Player, _BattleType, _Result) ->
	case player_state_api:try_set_state(Player, ?CONST_PLAYER_STATE_NORMAL) of
		{?true, NewPlayer} ->
			{?ok, NewPlayer};
		{?false, NewPlayer} ->
			{?ok, NewPlayer}
	end.

%% 从units获取各单位hp 
get_units_hp(Units) ->
	get_units_hp(Units, erlang:make_tuple(9, 0, [])).

get_units_hp([#unit{idx = Idx, hp = Hp}|Units], HpTuple) ->
	get_units_hp(Units, erlang:setelement(Idx, HpTuple, Hp));
get_units_hp([_Unit|Units], HpTuple) ->
	get_units_hp(Units, HpTuple);
get_units_hp([], HpTuple) -> HpTuple.

%% 给units各单位赋值hp
set_units_hp(Units, HpTuple, Camp, IsNeedDeath) when is_tuple(HpTuple) ->
	set_units_hp2(Units, HpTuple, [], Camp, IsNeedDeath);
set_units_hp(Units, HpTuple, Camp, IsNeedDeath) when is_list(HpTuple) ->
	set_units_hp3(Units, HpTuple, [], Camp, IsNeedDeath);
set_units_hp(Units, _HpTuple, Camp, _IsNeedDeath) -> {Units, Camp}.

set_units_hp2([Unit|Units], HpTuple, AccUnits, Camp, ?CONST_SYS_TRUE = IsNeedDeath)
  when is_record(Unit, unit) ->
    case erlang:element(Unit#unit.idx, HpTuple) of
        NewHp when NewHp =< 0 ->
            Unit2   = Unit#unit{hp = 0, state = ?CONST_BATTLE_UNIT_STATE_DEATH},
            set_units_hp2(Units, HpTuple, [Unit2|AccUnits], Camp, IsNeedDeath);
        NewHp when NewHp > 0 ->
            Unit2   = Unit#unit{hp = NewHp},
            set_units_hp2(Units, HpTuple, [Unit2|AccUnits], Camp, IsNeedDeath)
    end;
set_units_hp2([Unit|Units], HpTuple, AccUnits, Camp, ?CONST_SYS_FALSE = IsNeedDeath)
  when is_record(Unit, unit) ->
    case erlang:element(Unit#unit.idx, HpTuple) of
        NewHp when NewHp =< 0 ->
            Pos2 = erlang:setelement(Unit#unit.idx, Camp#camp.position, 0),
            set_units_hp2(Units, HpTuple, [0|AccUnits], Camp#camp{position = Pos2}, IsNeedDeath);
        NewHp when NewHp > 0 ->
            Unit2   = Unit#unit{hp = NewHp},
            set_units_hp2(Units, HpTuple, [Unit2|AccUnits], Camp, IsNeedDeath)
    end;
set_units_hp2([Unit|Units], HpTuple, AccUnits, Camp, IsNeedDeath) ->
    set_units_hp2(Units, HpTuple, [Unit|AccUnits], Camp, IsNeedDeath);
set_units_hp2([], _HpTuple, AccUnits, Camp, _IsNeedDeath) ->
    {misc:to_tuple(lists:reverse(AccUnits)), Camp}.

%% Units, HpTuple, [], Camp, IsNeedDeath
set_units_hp3([Unit|Units], HpList, AccUnits, Camp, ?CONST_SYS_TRUE = IsNeedDeath)
  when is_record(Unit, unit) ->
	Type	= Unit#unit.type,
	Id		= case Unit#unit.unit_ext of
				  #unit_ext_player{user_id = UserId} -> UserId;
				  #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
				  #unit_ext_monster{monster_id = MonsterId} -> MonsterId
			  end,
	case lists:keyfind({Type, Id}, 1, HpList) of
		{{Type, Id}, _Maxhp, NewHp} when NewHp =< 0 ->
            Unit2   = Unit#unit{hp = 0, state = ?CONST_BATTLE_UNIT_STATE_DEATH},
            set_units_hp3(Units, HpList, [Unit2|AccUnits], Camp, IsNeedDeath);
        {{Type, Id}, _Maxhp, NewHp} when NewHp > 0 ->
            Unit2   = Unit#unit{hp = NewHp},
            set_units_hp3(Units, HpList, [Unit2|AccUnits], Camp, IsNeedDeath);
		_ -> set_units_hp3(Units, HpList, [Unit|AccUnits], Camp, IsNeedDeath)
	end;
set_units_hp3([Unit|Units], HpList, AccUnits, Camp, ?CONST_SYS_FALSE = IsNeedDeath)
  when is_record(Unit, unit) ->
	Type	= Unit#unit.type,
	Id		= case Unit#unit.unit_ext of
				  #unit_ext_player{user_id = UserId} -> UserId;
				  #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
				  #unit_ext_monster{monster_id = MonsterId} -> MonsterId
			  end,
	case lists:keyfind({Type, Id}, 1, HpList) of
		{{Type, Id}, _Maxhp, NewHp} when NewHp =< 0 ->
            Pos2 = erlang:setelement(Unit#unit.idx, Camp#camp.position, 0),
            set_units_hp3(Units, HpList, [0|AccUnits], Camp#camp{position = Pos2}, IsNeedDeath);
        {{Type, Id}, _Maxhp, NewHp} when NewHp > 0 ->
            Unit2   = Unit#unit{hp = NewHp},
			set_units_hp3(Units, HpList, [Unit2|AccUnits], Camp, IsNeedDeath);
		_ -> set_units_hp3(Units, HpList, [Unit|AccUnits], Camp, IsNeedDeath)
	end;
set_units_hp3([Unit|Units], HpTuple, AccUnits, Camp, IsNeedDeath) ->
	set_units_hp3(Units, HpTuple, [Unit|AccUnits], Camp, IsNeedDeath);
set_units_hp3([], _HpList, AccUnits, Camp, _IsNeedDeath) ->
	{misc:to_tuple(lists:reverse(AccUnits)), Camp}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_units_hp(Units, HpTuple) when is_tuple(HpTuple) ->
    set_units_hp2(Units, HpTuple, []);
set_units_hp(Units, HpList) when is_list(HpList) ->
    set_units_hp3(Units, HpList, []);
set_units_hp(Units, _Hp) -> Units.

set_units_hp2([Unit|Units], HpTuple, AccUnits)
  when is_record(Unit, unit) ->
    case erlang:element(Unit#unit.idx, HpTuple) of
        NewHp when NewHp =< 0 ->
            Unit2   = Unit#unit{hp = 0, state = ?CONST_BATTLE_UNIT_STATE_DEATH},
            set_units_hp2(Units, HpTuple, [Unit2|AccUnits]);
        NewHp when NewHp > 0 ->
            Unit2   = Unit#unit{hp = NewHp},
            set_units_hp2(Units, HpTuple, [Unit2|AccUnits])
    end;
set_units_hp2([Unit|Units], HpTuple, AccUnits) ->
    set_units_hp2(Units, HpTuple, [Unit|AccUnits]);
set_units_hp2([], _HpTuple, AccUnits) ->
    misc:to_tuple(lists:reverse(AccUnits)).

set_units_hp3([Unit|Units], HpList, AccUnits)
  when is_record(Unit, unit) ->
	Type	= Unit#unit.type,
	Id		= case Unit#unit.unit_ext of
				  #unit_ext_player{user_id = UserId} -> UserId;
				  #unit_ext_partner{partner_id = PartnerId} -> PartnerId;
				  #unit_ext_monster{monster_id = MonsterId} -> MonsterId
			  end,
	case lists:keyfind({Type, Id}, 1, HpList) of
		{{Type, Id}, _Maxhp, NewHp} ->
			Unit2	= Unit#unit{hp = NewHp},
			set_units_hp3(Units, HpList, [Unit2|AccUnits]);
		_ -> set_units_hp3(Units, HpList, [Unit|AccUnits])
	end;
set_units_hp3([Unit|Units], HpTuple, AccUnits) ->
	set_units_hp3(Units, HpTuple, [Unit|AccUnits]);
set_units_hp3([], _HpList, AccUnits) ->
	misc:to_tuple(lists:reverse(AccUnits)).


%% 战斗开始
msg_battle_start(Battle) ->
	Id				= Battle#battle.id,
	UnitsGroupLeft	= msg_units_group(Battle#battle.units_left),
	UnitsGroupRight	= msg_units_group(Battle#battle.units_right),
    BaseDatas       = [Battle#battle.type|UnitsGroupLeft++UnitsGroupRight],
	PacketStart		= misc_packet:pack(?MSG_ID_BATTLE_SC_START2, ?MSG_FORMAT_BATTLE_SC_START2, [Id, ?false|BaseDatas]),
	PacketReport	= 
		case Battle#battle.report of
			?true -> 
                [_|Tail] = BaseDatas,
                misc_packet:pack(?MSG_ID_BATTLE_SC_START2, ?MSG_FORMAT_BATTLE_SC_START2, [Id, ?true, ?CONST_BATTLE_TYPE_REPORT|Tail]);
			?false -> <<>>
		end,
	?MSG_BATTLE("~nTime:~p BattleStart-----------------------------------------------~nBaseDatas:~p~n",[misc:time(), [Id, ?false|BaseDatas]]),
	{PacketStart, PacketReport}.
%% 战斗单元集合协议组
msg_units_group(Units) ->
%% 	?MSG_PRINT("Units:~p~n",[Units]),
    ServId  = Units#units.serv_id,
	Camp	= Units#units.camp,
	{
	 Player, Partner, Monster
	}		= msg_units_group(misc:to_list(Units#units.units), [], [], []),
	[
	 Units#units.side,
	 Camp#camp.camp_id,
	 Camp#camp.lv,
	 Player,
	 Partner,
	 Monster,
     ServId
	].

msg_units_group([Unit|Units], AccPlayer, AccPartner, AccMonster) when is_record(Unit, unit) ->
	case msg_unit_group(Unit) of
		{?CONST_SYS_PLAYER, UnitData} ->
			msg_units_group(Units, [UnitData|AccPlayer], AccPartner, AccMonster);
		{?CONST_SYS_PARTNER, UnitData} ->
			msg_units_group(Units, AccPlayer, [UnitData|AccPartner], AccMonster);
		{?CONST_SYS_MONSTER, UnitData} ->
			msg_units_group(Units, AccPlayer, AccPartner, [UnitData|AccMonster])
	end;
msg_units_group([_Unit|Units], AccPlayer, AccPartner, AccMonster) ->
	msg_units_group(Units, AccPlayer, AccPartner, AccMonster);
msg_units_group([], AccPlayer, AccPartner, AccMonster) ->
	{AccPlayer, AccPartner, AccMonster}.

%% 战斗单元协议组
msg_unit_group(Unit)
  when is_record(Unit#unit.unit_ext, unit_ext_player) ->%% 战斗单元协议组--角色
	Attr		= Unit#unit.attr,
	UnitExt		= Unit#unit.unit_ext,
	Datas		= {
				   Unit#unit.idx,
				   Unit#unit.anger,
				   Unit#unit.anger_max,
				   Unit#unit.hp,
				   (Attr#attr.attr_second)#attr_second.hp_max,
				   UnitExt#unit_ext_player.user_id,
				   UnitExt#unit_ext_player.name,
				   Unit#unit.lv,
				   Unit#unit.pro,
				   UnitExt#unit_ext_player.sex,
				   UnitExt#unit_ext_player.vip,
				   UnitExt#unit_ext_player.fashion,
				   UnitExt#unit_ext_player.armor,
				   UnitExt#unit_ext_player.weapon,
				   UnitExt#unit_ext_player.partners,
                   UnitExt#unit_ext_player.psoul
				  },
%%     ?MSG_ERROR("packet|uid=~p, pro=~p, sex=~p", 
%%                [UnitExt#unit_ext_player.user_id, Unit#unit.pro, UnitExt#unit_ext_player.sex]),
	{?CONST_SYS_PLAYER, Datas};
msg_unit_group(Unit)
  when is_record(Unit#unit.unit_ext, unit_ext_partner) ->%% 战斗单元协议组--武将
	Attr	= Unit#unit.attr,
	UnitExt	= Unit#unit.unit_ext,
	Datas	= {
			   Unit#unit.idx,
			   Unit#unit.anger,
			   Unit#unit.anger_max,
			   Unit#unit.hp,
			   (Attr#attr.attr_second)#attr_second.hp_max,
			   UnitExt#unit_ext_partner.partner_id,
			   UnitExt#unit_ext_partner.weapon,
			   UnitExt#unit_ext_partner.partners,
               UnitExt#unit_ext_partner.psoul
			  },
	{?CONST_SYS_PARTNER, Datas};
msg_unit_group(Unit)
  when is_record(Unit#unit.unit_ext, unit_ext_monster) ->%% 战斗单元协议组--怪物
	Attr		= Unit#unit.attr,
	UnitExt		= Unit#unit.unit_ext,
	Datas		= {
				   Unit#unit.idx,
				   Unit#unit.anger,
				   Unit#unit.anger_max,
				   Unit#unit.hp,
				   (Attr#attr.attr_second)#attr_second.hp_max,
				   UnitExt#unit_ext_monster.monster_id,
                   UnitExt#unit_ext_monster.psoul
				  },
	{?CONST_SYS_MONSTER, Datas}.

%% 强制终止战斗
msg_sc_stop(Reason) ->
	misc_packet:pack(?MSG_ID_BATTLE_SC_STOP, ?MSG_FORMAT_BATTLE_SC_STOP, [Reason]).

%% 出手顺序
msg_battle_seq(_) -> <<>>.
%% msg_battle_seq([]) -> <<>>;
%% msg_battle_seq(SeqList) ->
%% 	Datas	= msg_battle_seq(SeqList, []),
%% 	misc_packet:pack(?MSG_ID_BATTLE_SC_SEQ, ?MSG_FORMAT_BATTLE_SC_SEQ, [Datas]).
%% msg_battle_seq([#operate{key = Key}|SeqList], Acc) ->
%% 	{Side, Idx} = Key,
%% 	msg_battle_seq(SeqList, [{Side, Idx}|Acc]);
%% msg_battle_seq([], Acc) -> lists:reverse(Acc).

%% 坐骑技能{Idx, HorseId, Selection}
msg_battle_horse_skill(Id, HorseLeft, HorseSkillLeft, HorseAttrLeft, HorseRight, HorseSkillRight, HorseAttrRight) ->
	PacketLeft	= msg_sc_horse_skill(Id, ?CONST_BATTLE_UNITS_SIDE_LEFT, HorseLeft, HorseSkillLeft, HorseAttrLeft),
	PacketRight	= msg_sc_horse_skill(Id, ?CONST_BATTLE_UNITS_SIDE_RIGHT, HorseRight, HorseSkillRight, HorseAttrRight),
	<<PacketLeft/binary, PacketRight/binary>>.

msg_sc_horse_skill(Id, Side, HorseList, HorseSkill, HorseAttr) ->
	case select_horse_skill(HorseList, ?null) of
		?null -> <<>>;
		{Idx, HorseId, _Selection} ->
			AttrList	= horse_skill_attr_list(HorseAttr),
			?MSG_BATTLE("~nTime:~p HorseSkill:-----------------------------------------------~n{Side, Idx}:~p HorseId:~p HorseSkill:~p AttrList:~p~n",
						[misc:time(), {Side, Idx}, HorseId, HorseSkill, AttrList]),
			misc_packet:pack(?MSG_ID_BATTLE_SC_HORSE_SKILL, ?MSG_FORMAT_BATTLE_SC_HORSE_SKILL, [Id, Side, Idx, HorseId, HorseSkill, AttrList])
	end.
select_horse_skill([{Idx, HorseId, {Color, Lv, StrengthLv, Exp}}|HorseList], ?null) ->
	select_horse_skill(HorseList, {Idx, HorseId, {Color, Lv, StrengthLv, Exp}});
select_horse_skill([{Idx, HorseId, {Color, Lv, StrengthLv, Exp}}|HorseList],
				   {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}}) ->
	AccHorse	=
		if
			Color > AccColor -> {Idx, HorseId, {Color, Lv, StrengthLv, Exp}};
			Color < AccColor -> {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}};
			?true ->
				if
					Lv > AccLv -> {Idx, HorseId, {Color, Lv, StrengthLv, Exp}};
					Lv < AccLv -> {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}};
					?true ->
						if
							StrengthLv > AccStrengthLv -> {Idx, HorseId, {Color, Lv, StrengthLv, Exp}};
							StrengthLv < AccStrengthLv -> {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}};
							?true ->
								if
									Exp > AccExp -> {Idx, HorseId, {Color, Lv, StrengthLv, Exp}};
									Exp < AccExp -> {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}};
									?true -> {AccIdx, AccHorseId, {AccColor, AccLv, AccStrengthLv, AccExp}}
								end
						end
				end
		end,
	select_horse_skill(HorseList, AccHorse);
select_horse_skill([], AccHorse) -> AccHorse.
								
horse_skill_attr_list(#attr{attr_second = AttrSecond, attr_elite = AttrElite}) ->
	AttrList1	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_HP_MAX, AttrSecond#attr_second.hp_max, []),
	AttrList2	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_FORCE_ATTACK, AttrSecond#attr_second.force_attack, AttrList1), 
	AttrList3	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_FORCE_DEF, AttrSecond#attr_second.force_def, AttrList2),
	AttrList4	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_MAGIC_ATTACK, AttrSecond#attr_second.magic_attack, AttrList3),
	AttrList5	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_MAGIC_DEF, AttrSecond#attr_second.magic_def, AttrList4),
	AttrList6	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_SPEED, AttrSecond#attr_second.speed, AttrList5),
	AttrList7	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_E_HIT, AttrElite#attr_elite.hit, AttrList6),
	AttrList8	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_E_DODGE, AttrElite#attr_elite.dodge, AttrList7),
	AttrList9	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_E_CRIT, AttrElite#attr_elite.crit, AttrList8),
	AttrList10	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_E_PARRY, AttrElite#attr_elite.parry, AttrList9),
	AttrList11	= ?HORSE_ATTR(?CONST_PLAYER_ATTR_E_RESIST, AttrElite#attr_elite.resist, AttrList10),
	AttrList11;
horse_skill_attr_list(Attr) ->
	?MSG_ERROR("ERROR Attr:~p", [Attr]),
	[].


%% 战斗指令数据
msg_battle_cmd_data(Battle) ->
	msg_battle_cmd_data(Battle#battle.id, Battle#battle.bout, Battle#battle.cmds).
msg_battle_cmd_data(_Id, _Bout, []) -> <<>>;
msg_battle_cmd_data(Id, Bout, Cmds) ->
%% 	?MSG_BATTLE("~nTime:~p BOUT:~p-----------------------------------------------~nCMDS:~p~n",[misc:time(), Bout, Cmds]),
	?MSG_BATTLE("|~p|1|~w",[Bout, Cmds]),
	misc_packet:pack(?MSG_ID_BATTLE_SC_CMD_DATA, ?MSG_FORMAT_BATTLE_SC_CMD_DATA, [Id, Bout, Cmds]).

%% 战斗结束
msg_sc_over(Id, UserId,  MonId, BattleType, Result, {Point, Score, Exp, Gold, Meritorious, Experience, GoodsList, MonsterList, 
    AreaScore, Hufu, StreekWinScore, StreakTimes}, RobotList) ->
    msg_sc_over(Id, UserId,  MonId, BattleType, Result, {Point, Score, Exp, Gold, Meritorious, Experience, GoodsList, MonsterList, 
        AreaScore, Hufu, StreekWinScore, StreakTimes, 0,0,0,0,0,0}, RobotList);
%% 战斗结束
msg_sc_over(Id, UserId,  MonId, BattleType, Result, {Point, Score, Exp, Gold, Meritorious, Experience, GoodsList, MonsterList, 
    AreaScore, Hufu, StreekWinScore, StreakTimes, Hurt,BattleType2,StreakWinTimes,BattleScore, Jiangyin, CrossArenaScore}, RobotList) ->
	notice_sc_over(UserId, MonId, {BattleType, Result, Point, Exp, Gold, Meritorious, Experience, GoodsList}, RobotList),
	GoodsData 	= [{Goods#goods.goods_id, Goods#goods.count} || Goods <- GoodsList],
	Datas 		= [Id,			Result,		Score,	   Exp,			Gold,
				   Meritorious, Experience, GoodsData, MonsterList, AreaScore, Hufu, StreekWinScore, StreakTimes, 
                  Hurt,BattleType2,StreakWinTimes,BattleScore, Jiangyin, CrossArenaScore],
	?MSG_BATTLE("~nTime:~p BattleOver-----------------------------------------------~nDatas:~p~n",[misc:time(), Datas]),
	misc_packet:pack(?MSG_ID_BATTLE_SC_OVER, ?MSG_FORMAT_BATTLE_SC_OVER, Datas).

%% 回合刷新
msg_battle_refresh_bout(_Id, _Bout, [], _IsShow) -> <<>>;
msg_battle_refresh_bout(Id, Bout, RefreshDatas, IsShow) ->
%% 	?MSG_BATTLE("~nTime:~p Refresh-----------------------------------------------~nBout:~p~nRefreshDatas:~p~n",[misc:time(), Bout, RefreshDatas]),
	?MSG_BATTLE("~n|~p|2|~w|",[Bout, RefreshDatas]),
	misc_packet:pack(?MSG_ID_BATTLE_SC_REFRESH_BOUT, ?MSG_FORMAT_BATTLE_SC_REFRESH_BOUT, [Id, Bout, RefreshDatas, IsShow]).

%% 战斗操作通知
msg_battle_operate_notice(Side, Idx, SkillId) ->
	misc_packet:pack(?MSG_ID_BATTLE_SC_OPERATE_NOTICE, ?MSG_FORMAT_BATTLE_SC_OPERATE_NOTICE, [Side, Idx, SkillId]).

%% 跳过战斗次数
%%[Count]
msg_sc_skip_info(Count, IsShow) ->
    misc_packet:pack(?MSG_ID_BATTLE_SC_SKIP_INFO, ?MSG_FORMAT_BATTLE_SC_SKIP_INFO, [Count, IsShow]).

%% 战报列表
%%[CopyId,{UserId,UserName,ReportId, Lv}]
msg_sc_report_list(CopyId,List1) ->
    misc_packet:pack(?MSG_ID_BATTLE_SC_REPORT_LIST, ?MSG_FORMAT_BATTLE_SC_REPORT_LIST, [CopyId,List1]).
