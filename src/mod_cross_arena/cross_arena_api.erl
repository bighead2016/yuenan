%% Author: Administrator
%% Created: 2013-12-13
%% Description: TODO: Add description to single_arena_cross_api
-module(cross_arena_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([
%%          get_node_by_sid/1,
%% 		 get_node_by_sid/2, 
		 get_phase_by_group/1, 
		 broadcast/2, 
		 broadcast_open/2, 
		 mail/3,
		 battle_over/4, 
		 refresh_daily_db/0,
		 update_partner/2,
		 update_power/2,
		 player_cross_data/1]).

-export([msg_enter_arena/3,
		 msg_group_info/4,
		 msg_refresh_group_info/1,
		 msg_refresh_member_info/6,
		 msg_day_reward/1,
		 msg_achieve_info/1,
		 msg_achieve_reward/1,
		 msg_refresh_report/1]).

%%
%% API Functions
%%
%%-------------------------------------center_serv--------------------------------------------------
%% 根据平台和服号获取节点名
%% get_node_by_sid(PlatForm, Sid) ->
%% 	NodeSuffix	= config:read(server_info, #rec_server_info.node_suffix),
%% 	list_to_binary("sanguo_" ++ misc:to_list(PlatForm) ++ "_" ++ integer_to_list(Sid)  ++ misc:to_list(NodeSuffix)).
%% 
%% %% 根据平台和服号获取节点名
%% get_node_by_sid(Sid) ->
%% 	PlatForm	= config:read(server_info, #rec_server_info.platform),
%% 	NodeSuffix	= config:read(server_info, #rec_server_info.node_suffix),
%% 	list_to_binary("sanguo_" ++ misc:to_list(PlatForm) ++ "_" ++ integer_to_list(Sid)  ++ misc:to_list(NodeSuffix)).

%% 根据段获取组
get_phase_by_group(Phase) ->
	if Phase < 7 ->
		   misc:pow(2, Phase - 1);
	   ?true ->
		   32 * misc:pow(3, Phase - 6)
	end.

%% 广播给组内所有人
broadcast(UserId, Packet) ->
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, broadcast, {UserId, Packet}).

%% 广播给组内所有打开竞技场的人
broadcast_open(UserId, Packet) ->
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, broadcast_open, {UserId, Packet}).

%% 邮件给组内所有的人
mail(Phase, Group, Packet) ->
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, mail, {Phase, Group, Packet}).

%% 战斗模块通知竞技场结束
battle_over(UserId, Result, EnemyId, BinReport) ->
	cross_arena_serv:deal_with_rank_cast(UserId, EnemyId, Result, BinReport).
		
%% 每日刷新名次
refresh_daily_db() ->
	cross_arena_data_api:data_operate_cast(cross_arena_data_api, refresh_daily_db, {}).

%% 获取挑战者	打包数据给前端
get_member_binary(Member)->
	#ets_cross_arena_member{player_id = PlayerId,
							platform = Platform,
							sn = Sn,
						  	player_lv = Lv,
						  	rank = Rank,
						  	player_sex = Sex,
						  	player_career = Pro,
						  	player_name = TmpName,
							score = Score,
							fight_force = Power,
							partner_list =  PartnerList
					  		} = Member,
	Name 		= misc:to_list(TmpName),
	PlatName 	= misc:to_list(Platform),
	PartnerData = lists:map(fun(PartnerId) -> {PartnerId} end, PartnerList),
	{PlayerId, Name, Rank, PlatName, Sn, Pro, Sex, Score, Power, PartnerData}.

%% 刷新武将
update_partner(Player, Power) ->
	UserId		= Player#player.user_id,
	OutPartner	= partner_api:get_out_partner(Player),
	OutIdList	= [X#partner.partner_id||X <- OutPartner],
	cross_arena_serv:update_partner_cast(UserId, OutIdList, Power).

%% 刷新战力
update_power(UserId, Power) ->
	cross_arena_serv:update_power_cast(UserId, Power).

%% 获取战报		打包数据给前端
get_report_binary(Report)->
	#cross_arena_report{
					  id = ReportId,
					  attack_id	= AttackId,
					  attack_name	= AttackName,
					  deffender_id = DefId,
					  deffender_name = DefName,
					  result = Result} = Report,
	{ReportId,  AttackId, AttackName, DefId, DefName, Result}.


%%=====================================封装==============================================
%% 获取跨服player
player_cross_data(#player{user_id      = UserId,
						   serv_id		= ServId,
						   user_state   = UserState,
						   play_state   = PlayState,
						   team_id		= TeamId,
						   info         = Info,
						   attr_sum     = AttrSum,
						   buff         = Buff,
						   attr         = Attr,
						   equip        = Equip,
						   skill        = Skill,   
						   camp         = Camp,
						   position     = Position,
						   partner      = Partner,
						   guild        = Guild,
						   mind         = Mind,
						   train		= Train,
						   sys_rank     = Sys,
                           style        = Style,
                           maps         = MapData,
                           horse        = HorseData,
						   lookfor		= LookforData,
						   weapon		= WeaponData
                           }) ->
    #player{user_id			= UserId,
			serv_id			= ServId,
			user_state		= UserState,
			play_state		= PlayState,
			team_id			= TeamId,
			info			= Info,
			attr_sum		= AttrSum,
			buff            = Buff,     
			attr            = Attr,
			equip           = Equip,
			skill           = Skill,   
			camp            = Camp,
			position        = Position,    
			partner         = Partner,
			guild           = Guild,
			mind            = Mind,
			train			= Train,
			sys_rank		= Sys,
            style           = Style,
            maps            = MapData,
            horse           = HorseData,
			lookfor			= LookforData,
			weapon			= WeaponData
		   };
player_cross_data(X) -> ?MSG_ERROR("bad arg=~p", [X]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 协议打包 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
msg_enter_arena(Result, Member, ReportList) ->
	LastRank	= Member#ets_cross_arena_member.last_rank,
	LastPhase	= Member#ets_cross_arena_member.last_phase,
	LastGroup	= Member#ets_cross_arena_member.last_group,
	Rank		= Member#ets_cross_arena_member.rank,
	Phase		= Member#ets_cross_arena_member.phase,
	Group		= Member#ets_cross_arena_member.group,
	RemainTimes	= Member#ets_cross_arena_member.times,
	WinTimes	= Member#ets_cross_arena_member.win_times,
	FailTimes	= Member#ets_cross_arena_member.fail_times,
	LastWinTimes= Member#ets_cross_arena_member.last_win_times,
	Score		= Member#ets_cross_arena_member.score,
	{IsReward, RewardTime}	= cross_arena_mod:get_next_reward_time(Member),
	FightList	= Member#ets_cross_arena_member.fight_list,
	FightData	= lists:map(fun({FightId, FightResult}) -> {FightId, FightResult} end, FightList),
	ReportData	= lists:map(fun(Report) -> get_report_binary(Report) end, ReportList),
	Data	= 
		[Result,
		 LastRank,
		 LastPhase,
		 LastGroup,
		 Rank,
		 Phase,
		 Group,
		 RemainTimes,
		 WinTimes,
		 FailTimes,
		 LastWinTimes,
		 Score,
		 RewardTime,
		 IsReward,
		 FightData,
		 ReportData
		 ],
%% 	?MSG_DEBUG("msg_enter_arena111111111111111111111111111111111111:~p",[Data]),
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_ENTER, ?MSG_FORMAT_CROSS_ARENA_SC_ENTER, Data).

msg_group_info(Type, Phase, Group, DefList) ->
%% 	?MSG_DEBUG("msg_group_info111111111111111111111111111111111111:~p",[{Phase, Group}]),
	MemberData	= lists:map(fun(Member) -> get_member_binary(Member) end, DefList),
	Data		= [Type, Phase, Group, MemberData],
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_TOP_PHASE_INFO, ?MSG_FORMAT_CROSS_ARENA_SC_TOP_PHASE_INFO, Data).
	
msg_refresh_group_info(GroupList) ->
	Fun = fun({UserId, Rank}) ->
				case cross_arena_mod:get_arena_info_by_id(UserId) of
					Member when is_record(Member, ets_cross_arena_member) ->
						Score 	= Member#ets_cross_arena_member.score,
						{UserId, Rank, Score};
					_ ->
						{UserId, Rank, 0}
				end
		  end,
	DataList	= lists:map(Fun, GroupList),
	Data = [DataList],
	misc_packet:pack(?MSG_ID_CROSS_ARENA_REFRESH_GROUP_INFO, ?MSG_FORMAT_CROSS_ARENA_REFRESH_GROUP_INFO, Data).

msg_refresh_member_info(RemainTimes, Rank, Score, WinTimes, FailTimes, FightList) ->
	FightData	= lists:map(fun({Id, Result}) -> {Id, Result} end, FightList),
	Data	= [RemainTimes, Rank, Score, WinTimes, FailTimes, FightData],
	misc_packet:pack(?MSG_ID_CROSS_ARENA_REFRESH_MEMBER_INFO, ?MSG_FORMAT_CROSS_ARENA_REFRESH_MEMBER_INFO, Data).
	
msg_day_reward(Rank) ->
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_RANK_AWARD, ?MSG_FORMAT_CROSS_ARENA_SC_RANK_AWARD, [Rank]).

msg_achieve_info(AchieveList) ->
	Fun		= fun(Achieve) ->
					  {Achieve#cross_arena_achieve.id, Achieve#cross_arena_achieve.flag}
			  end,
	AchieveData	= lists:map(Fun, AchieveList),
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_ACHIEVE, ?MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE, [AchieveData]).

msg_achieve_reward(AchieveId) ->
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_ACHIEVE_REWARD, ?MSG_FORMAT_CROSS_ARENA_SC_ACHIEVE_REWARD, [AchieveId]).

msg_refresh_report(Report) ->
	{ReportId,  AttackId, AttackName, DefId, DefName, Result} = get_report_binary(Report),
	Data = 
		[ReportId,  
		 AttackId, 
		 AttackName, 
		 DefId, 
		 DefName, 
		 Result
		 ],
	misc_packet:pack(?MSG_ID_CROSS_ARENA_SC_REFRESH_REPORT, ?MSG_FORMAT_CROSS_ARENA_SC_REFRESH_REPORT, Data).
%%
%% Local Functions
%%

