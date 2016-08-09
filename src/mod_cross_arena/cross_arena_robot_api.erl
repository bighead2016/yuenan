%% Author: Administrator
%% Created: 2013-12-21
%% Description: TODO: Add description to cross_arena_robot_api
-module(cross_arena_robot_api).

%%
%% Include files
%%
-include("const.define.hrl").
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("record.player.hrl").
-include("record.battle.hrl").
-include("record.data.hrl").
-include("record.map.hrl").

%%
%% Exported Functions
%%
-export([get_deffender_list/0, 
		 change_ui_state/2, 
		 get_myself_info/4, 
		 get_myself_info/7,
         start_battle/2, 
		 battle_over/3, 
		 update_cross_flag/2,
         msg_sc_enter_arena/4]).

%%
%% API Functions
%%
%% 读取能打的那几个人
get_deffender_list() ->
    get_deffender(data_cross_arena:get_robot_list(), []).

get_deffender([{MonId, Sex, PartnerList}|Tail], List) ->
    RobotT = 
        case data_monster:get_monster(MonId) of
            #monster{lv = Lv, pro = Pro, name = Name, camp = Camp} ->
				Power = calc_monster_power(misc:to_list(Camp#camp.position), 0),
                record_arena_member(MonId, Lv, Pro, to_list(Name), Sex, Power, PartnerList, length(List) + 1);
            _ ->
                record_arena_member(10001, 2, ?CONST_SYS_PRO_FJ, to_list(<<"robot1">>), ?CONST_SYS_SEX_MALE, 1, [], length(List) + 1)
        end,
    get_deffender(Tail, [RobotT|List]);
get_deffender([], List) -> List.

calc_monster_power([#camp_pos{id = MonId}|TailList], AccPower) ->
	case data_monster:get_monster(MonId) of
            #monster{power = Power} ->
				AccPower2	= AccPower + Power,
				calc_monster_power(TailList, AccPower2);
			_ ->
				calc_monster_power(TailList, AccPower)
	end;
calc_monster_power([_|TailList], AccPower) ->
	calc_monster_power(TailList, AccPower);
calc_monster_power([], AccPower) -> AccPower.

%% 首次进入竞技场
change_ui_state(UserId, _Info) ->
    {RankNew, IsNew} = 
        case cross_arena_mod:get_arena_info_by_id(UserId) of
            [] ->
                Rank = 10,
                {Rank, ?CONST_SYS_TRUE};
            #ets_cross_arena_member{rank = Rank} ->
                {Rank, ?CONST_SYS_FALSE}
        end,
	init_robot(UserId),
    {?CONST_SINGLE_ARENA_OK, RankNew, IsNew}.


get_myself_info(UserId, Info, PartnerList, Rank) ->
    record_arena_member(UserId, Info#info.lv, Info#info.pro, 
                        Info#info.user_name,  Info#info.sex,
                        Info#info.power, PartnerList, Rank).
get_myself_info(UserId, Lv, Pro, UserName, Sex, Power, Rank) ->
    record_arena_member(UserId, Lv, Pro, UserName, Sex, Power, [], Rank).

%% 
init_robot(UserId) ->
	case cross_arena_mod:get_robot(UserId) of
		[] ->
			Robot	= #cross_arena_robot_member{player_id = UserId},
			cross_arena_mod:update_robot_ets(Robot);
		_Member ->
			?ok
	end.
		
msg_sc_enter_arena(Result, Member, DefList, ReportList) ->
	
    Packet1					= cross_arena_api:msg_enter_arena(Result, Member, ReportList),
	Packet2					= cross_arena_api:msg_group_info(1, 0, 0, DefList),
    <<Packet1/binary, Packet2/binary>>.

start_battle(Player, EnemyId) ->
	case check_start_battle(Player#player.user_id, EnemyId) of
		?ok ->
		    {?ok, NewPlayer} = 
		        case battle_api:start(Player, EnemyId, #param{battle_type = ?CONST_BATTLE_CROSS_ARENA_ROBOT}) of %% 开始战斗
		            {?error, _ErrorCode} -> %% 错误
		                {?ok, Player};
		            {?ok, Player2} -> %% 结果返回
		                {?ok, Player2}
		        end,
		    {?ok, NewPlayer};
		_ ->
			{?ok, Player}
	end.

%%检查挑战的条件        检查是否可挑战（TODO）
check_start_battle(UserId, EnemyId) ->
	try
		Robot =  cross_arena_mod:get_robot(UserId),
		?ok = check_fight_list(Robot, EnemyId),
		?ok
	catch
		throw:Return ->
			Return;
		_:_ ->
			{?error, 110}
	end.

%% 检查是否已挑战过
check_fight_list(Robot, EnemyId) ->
	FightList	= Robot#cross_arena_robot_member.fight_list,
	case lists:member(EnemyId, FightList) of
		?true ->
			throw({?error, ?TIP_COMMON_BAD_ARG});
		?false ->
			?ok
	end.
%%  战斗模块通知竞技场结束(打败战力最大的机器人)
battle_over(UserId, 57022, ?CONST_BATTLE_RESULT_LEFT) ->
%%     cross_arena_serv:deal_with_rank_robot_cast(UserId),
	player_api:process_send(UserId, ?MODULE, update_cross_flag, {1}),
	{?ok, Player, _} 	= player_api:get_player_first(UserId),
%% 	cross_arena_mod:enter(Player, 1);
	Info 			= Player#player.info,
	UserName		= Info#info.user_name,
	Sex				= Info#info.sex,
	Pro 			= Info#info.pro,
	Lv  			= Info#info.lv,
	ServId 			= Player#player.serv_id,
	Power			= partner_api:caculate_camp_power(UserId),
	OutPartner		= partner_api:get_out_partner(Player),
	OutIdList		= [X#partner.partner_id||X <- OutPartner],
    Result 			= cross_arena_mod:change_ui_state(UserId, {UserName, Sex, Pro, Lv, ServId, Power, OutIdList, 1}), %% 打开竞技场界面
	Member		 	= cross_arena_mod:get_arena_info_by_id(UserId), 				%% 获取个人的竞技场信息  涉及到隔日更新
	[_, DefList] 	= cross_arena_mod:get_deffender_list(UserId), 				%% 获取可以挑战的玩家列表
	Phase			= Member#ets_cross_arena_member.phase,
	Group			= Member#ets_cross_arena_member.group,
	Packet1			= cross_arena_api:msg_enter_arena(Result, Member, []),
	Packet2			= cross_arena_api:msg_group_info(1, Phase, Group, DefList),
	misc_packet:send(UserId, <<Packet1/binary, Packet2/binary>>),
	cross_arena_mod:delete_robot_by_id(UserId),
	cross_arena_mod:update_player_data(Player, Member),
	cross_arena_api:mail(Phase, Group, <<>>);
battle_over(UserId, DefId, ?CONST_BATTLE_RESULT_LEFT) ->
	update_fight_list(UserId, DefId, ?CONST_BATTLE_RESULT_LEFT),
	?ok;
battle_over(_UserId, _, _) ->
	?ok.

update_fight_list(UserId, DefId, Result) ->
	case cross_arena_mod:get_robot(UserId) of
		[] ->
			Robot	= #cross_arena_robot_member{player_id = UserId, fight_list = [{DefId, Result}]},
			cross_arena_mod:update_robot_ets(Robot),
			Packet			= cross_arena_api:msg_refresh_member_info(99, 10, 0, 0, 0, [{DefId, Result}]),
			misc_packet:send(UserId, Packet);
		RobotMember ->
			OldFightList = RobotMember#cross_arena_robot_member.fight_list,
			RobotMember2 = RobotMember#cross_arena_robot_member{player_id = UserId, fight_list = [{DefId, Result}|OldFightList]},
			cross_arena_mod:update_robot_ets(RobotMember2),
			Packet			= cross_arena_api:msg_refresh_member_info(99, 10, 0, 0, 0, [{DefId, Result}|OldFightList]),
			misc_packet:send(UserId, Packet)
	end.
	

update_cross_flag(Player, {Flag}) ->
	Info			= Player#player.info,
	Info2			= Info#info{cross_arena_flag = Flag},
	Player2			= Player#player{info = Info2},
	{?ok, Player2}.
%%
%% Local Functions
%%

record_arena_member(UserId, Lv, Pro, UserName, Sex, Power, PartnerList, Rank) ->
	FightList	= 
		case cross_arena_mod:get_robot(UserId) of
			Robot when is_record(Robot, cross_arena_robot_member) ->
				Robot#cross_arena_robot_member.fight_list;
			_ ->
				[]
		end,
    #ets_cross_arena_member{
					  phase = 0,
                      fight_force = Power,
					  partner_list = PartnerList,
                      on_line_flag = 1,
                      open_flag = 1,
                      player_career = Pro,
                      player_id = UserId,
                      player_lv = Lv,
                      player_name = UserName,
                      player_sex = Sex,
                      rank = Rank,
                      times = 99,
					  fight_list = FightList
                     }.

to_list(X) ->
    binary_to_list(unicode:characters_to_binary(X)).

%%
%% API Functions
%%



%%
%% Local Functions
%%

