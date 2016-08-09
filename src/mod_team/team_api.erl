%% Author: cobain
%% Created: 2012-11-5
%% Description: TODO: Add description to team_api
-module(team_api).

%%
%% Include files
%%

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%

-export([refresh_exit_guild_author/2, refresh_enter_guild_author/2, broad_set_state/4, broad_team_cast/3]).
-export([init_tesm_ets/1, generate_team_id/1,change_team/2,check_invite2/5,msg_sc_author_list/4,
		 enter_hall/1, create/2, join/3, remove/2, quit/1, change_leader/2, invite/2,ets_get_authoer/2,
		 reply/4, set_team_state/3, get_team_param/2, set_team_param/3,get_gold_hire_list/1,
		 set_member_state/2, set_camp/2, set_camp_pos/3, update_team_player/1,
		 logout/1, auto_join/2, quit_hall/1, quick_join/5, lock_and_unlock/2, check_invite_gold/5]).
-export([play_start/2, play_over/2, play_quit/1, get_team_id_list/2,invite2/2,init_invite_info/2,
		 player_over_clean/1, player_over_clean_team_cb/2, player_over_clean_hall_cb/2]).
-export([broadcast_hall/2, broadcast_hall/3, broadcast_team/2, broadcast_team/3]).
-export([team_type/1, check_enter_map/1, get_team/1, get_team/2, get_team_uids/1, get_team_uids/2, get_team_camp/1,
		 team_sup_name/1, team_ets/1, get_team_id/1, get_team_lv/2, get_arena_team/0]).
-export([check_team_play_cb/2, do_quit/2, get_cross_team_key/1]).
-export([update_player_team/2, update_player_team/3, update_player_team_cb/2, cross_player_quit/3]).
-export([get_author_list/2, set_author_list/4, get_robot_list/2, insertdb_invite_info/2]).
-export([ets_ext_new/1, ets_ext_insert/2, ets_ext_delete/2, get_invite_author_list/1, cross_join/3]).
-export([delete_team_ext/2, delete_team_hall/2, delete_team_player/2, check_is_in_not_cd/3]).
%% 协议打包函数
-export([msg_sc_enter_hall/0, msg_sc_enter_hall_notice/2, msg_sc_quit_hall_notice/2,
		 msg_sc_team_insert_notice/1, msg_sc_team_delete_notice/1, gold_invite/2, player_over_clean_team_cross/6,
		 msg_sc_invite_notice/7, msg_sc_remove_invite/1, msg_sc_quit_notice/1,remove_notify/2,
		 msg_sc_info/2, msg_sc_quit_play_to/2, msg_sc_change_copy2/2, broad_join_info_cross/5]).


-define(CONST_TEAM_AUTO_JOIN_SCOPE1, 2).

-define(CONST_TEAM_AUTO_JOIN_SCOPE2, 5).


get_cross_team_key(TeamId) ->
    Index = cross_api:get_self_index(),
    {TeamId, Index}.

get_gold_hire_list(Index, Count) ->
    case Index < 6 of
        true ->
            HireMember = single_arena_mod:get_front_n_member(7, 6),
            lists:keydelete(Index, #ets_arena_member.rank, HireMember);
        _ ->
            single_arena_mod:get_front_n_member(Index, Count)
    end.

get_gold_hire_list(Player) ->
    UserId = Player#player.user_id,
    Self = single_arena_api:get_myself_info(UserId),
    SelfRank = Self#ets_arena_member.rank,
    HireMember = get_gold_hire_list(SelfRank, 5),
    Format=
        fun(Member) ->
                {Member#ets_arena_member.player_id, 
                 Member#ets_arena_member.player_name, 
                 Member#ets_arena_member.player_lv,
                 Member#ets_arena_member.player_career}
        end,
    ResultList = lists:map(Format, HireMember),
    Packet = msg_sc_gold_hire(ResultList),
    misc_packet:send(UserId, Packet).

%% 队伍人数匹配：队伍人数三个>队伍人数两个>队伍人数一个；
get_level_range_index(Diff) ->
    case Diff < ?CONST_TEAM_AUTO_JOIN_SCOPE1 of
        true ->
            1;
        false ->
            case Diff =< ?CONST_TEAM_AUTO_JOIN_SCOPE2 of
                true ->
                    2;
                _ ->
                    3
            end
    end.

%%
%% API Functions
%%

get_invite_author_list(Player) ->
    case team_type(Player) of
        0 -> {?error, ?TIP_TEAM_NOT_TEAM_PLAY}; % 不在多人玩法中
        TeamType ->
           UserId = Player#player.user_id,
           Rec = ets_get_authoer(UserId, TeamType),
           ListFrom = 
               case Rec#team_author.team_from of
                   ?undefined ->
                       [];
                   ListFrom1 ->
                       ListFrom1
               end, 
           Fun = 
               fun(Id) ->
                       AuthorRec = 
                           try
                               ets_get_authoer(Id, TeamType)
                           catch
                               _:_ ->
                                   #team_author{career = -1}
                           end,
                       Count =get_count(Id, TeamType),
                       Cd = 
                           case ets:lookup(?CONST_ETS_TEAM_INVITE_CD, {UserId, Id, TeamType}) of
                               [] ->
                                   0;
                               [CdRec] ->
                                   CdRec#team_invite_cd.last_invite_time + 10 * 60
                           end,
                       Lv = player_api:get_level(Id),
                       {Id, AuthorRec#team_author.name, AuthorRec#team_author.career,0, Lv, Cd, Count}
               end,
           List = lists:map(Fun, ListFrom),
           FilterFun =
               fun({_,_,Career,_,_,_,_}) ->
                       Career /= -1
               end,
           List1 = lists:filter(FilterFun, List),
           Packet = msg_sc_invite_author_list(List1, TeamType),
           misc_packet:send(UserId, Packet)
    end.
                       

get_Author_item(UserId, Type) ->
    {ok, Info} = player_api:get_player_field(UserId, #player.info),
    Lv = Info#info.lv,
    Name = Info#info.user_name,
    Career = Info#info.pro,
    #team_author{career = Career, lv = Lv, name = Name, key = {UserId, Type}}.
  
add_author_from(UserId, UserId, _TeamType) ->ok;
add_author_from(UserId1, UserId2, TeamType) ->
    Rec = ets_get_authoer(UserId1, TeamType),
    OldList = 
        case Rec#team_author.team_from of
            ?undefined ->
                [];
            OldList1 ->
                OldList1
        end,
    NewList = 
        case lists:member(UserId2, OldList) of
            true ->
                OldList;
            _ ->
                [UserId2|OldList]
        end,
    ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId1, TeamType}, {#team_author.team_from, NewList}).

sub_author_from(UserId1, UserId2, TeamType) ->
    Rec = ets_get_authoer(UserId1, TeamType),
    OldList = 
        case Rec#team_author.team_from of
            ?undefined ->
                [];
            OldList1 ->
                OldList1
        end,
    NewList = OldList -- [UserId2],
    ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId1, TeamType}, {#team_author.team_from, NewList}).
            

ets_get_authoer(UserId, Type) ->
    case ets:lookup(?CONST_ETS_TEAM_AUTHOR, {UserId, Type}) of
        [] ->
            case init_invite_info(UserId, Type) of
                null ->
                    Rec = get_Author_item(UserId, Type),
                    ets:insert(?CONST_ETS_TEAM_AUTHOR, Rec),
                    Rec;
                Rec ->
                    Rec
            end;
        [Rec] ->
            Rec
    end.
        

set_author_list(Player, UserId1, TeamType, IsChoose) ->
    UserId = Player#player.user_id,
    Guild = Player#player.guild,
    GuildList = guild_api:get_guild_members(Guild#guild.guild_id),
    FunFormat = 
        fun({Uid, _UserName, _Power}) ->
                Uid
        end,
    GuildIdList = lists:map(FunFormat, GuildList),
    Rec = ets_get_authoer(UserId, TeamType),
    OldList = 
        case Rec#team_author.team_to of
            ?undefined ->
                [];
            OldList1 ->
                OldList1
        end,
    case UserId1 > 0 of
        true ->
            case IsChoose of
                true ->
                    List =  [UserId1|OldList],
					if TeamType =:= 2 -> %%异民族
						  {?ok,NewPlayer} = task_target_mod:update_guide_branch(Player, ?CONST_MODULE_YIMINZU);
					   TeamType =:= 1 -> %%团队战场
						  {?ok,NewPlayer} = task_target_mod:update_guide_branch(Player, ?CONST_MODULE_MCOPY1);
					   true ->
						   NewPlayer = Player
					end;
                _ ->
                    List =  OldList -- [UserId1],
					NewPlayer = Player
            end,
            ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId, TeamType}, {#team_author.team_to, List}),
            IsGuildAll = Rec#team_author.is_guild_all,
            case IsGuildAll of
                false ->
                    case IsChoose of
                        false ->
                            sub_author_from(UserId1, UserId, TeamType);
                        _ ->
                            add_author_from(UserId1, UserId, TeamType)
                    end;
                _ ->
                    case lists:member(UserId1, GuildIdList) of
                        true ->
                            ok;
                        false ->
                            case IsChoose of
                                false ->
                                    sub_author_from(UserId1, UserId, TeamType);
                                _ ->
                                    add_author_from(UserId1, UserId, TeamType)
                            end
                    end
            end,
			NewPlayer;
        _ ->
            ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId, TeamType}, {#team_author.is_guild_all, IsChoose}),
            case IsChoose of
                true ->
					if TeamType =:= 2 -> %%异民族
						   {?ok,NewPlayer} = task_target_mod:update_guide_branch(Player, ?CONST_MODULE_YIMINZU);
					   TeamType =:= 1 -> %%团队战场
						   {?ok,NewPlayer} = task_target_mod:update_guide_branch(Player, ?CONST_MODULE_MCOPY1);
					   true ->
						   NewPlayer = Player
					end,
                    FunAdd =
                        fun(Id) ->
                                add_author_from(Id, UserId, TeamType)
                        end,
                    lists:foreach(FunAdd, GuildIdList);
                _ ->
                    FunSub = 
                        fun(Id) ->
                                case lists:member(Id, OldList) of
                                    false ->
                                        sub_author_from(Id, UserId, TeamType);
                                    _ ->
                                        ok
                                end
                        end,
                    lists:foreach(FunSub, GuildIdList),
					NewPlayer = Player
            end,
			NewPlayer
    end. 

get_author_list(Player, Type) ->
    UserId = Player#player.user_id,
    Rec = ets_get_authoer(UserId, Type),
    Count = get_count(UserId, Type),
    AuthorList = 
        case Rec#team_author.team_to of
            ?undefined ->
                [];
            AuthorList1 ->
                AuthorList1
        end,
    IsGuildAll = Rec#team_author.is_guild_all,
    PacketFormat=
        fun(Id) ->
                {Id}
        end,
    List1 = lists:map(PacketFormat, AuthorList),
    Msg = msg_sc_author_list(List1, Count, IsGuildAll, Type),
    misc_packet:send(UserId, Msg).


get_term_normal(BitString) ->
    case misc:bitstring_to_term(BitString) of
        ?undefined ->
            [];
        Term ->
            Term
    end.
init_invite_info(UserId, Type) ->
    {ok, Info} = player_api:get_player_field(UserId, #player.info),
    Name = Info#info.user_name,
    Lv = Info#info.lv,
    Career = Info#info.pro,
    Keys = [userId, type, team_to, team_from, is_guild_all, last_add_count_time, times],
    case mysql_api:select(Keys, game_team_invite_offline,  [{userId, UserId}, {type, Type}]) of
        {ok, [[UserId, Type, TeamTo, TeamFrom, IsGuildAll, LastTime, Count]]} ->
            Rec = #team_author{key = {UserId, Type},
                               times = Count, 
                               team_to = get_term_normal(TeamTo), 
                               team_from = get_term_normal(TeamFrom), 
                               name = Name,
                               lv = Lv,
                               career = Career,
                               is_guild_all = 
                                   case IsGuildAll of
                                       1 ->
                                           true;
                                       _ ->
                                           false
                                   end,
                               last_add_count_time = LastTime},
            ets:insert(?CONST_ETS_TEAM_AUTHOR, Rec),
            Rec;
        _ ->
            null
    end.
        

insertdb_invite_info(UserId, Type) ->
    case ets:lookup(?CONST_ETS_TEAM_AUTHOR, {UserId, Type}) of
        [] ->
            ok;
        [Rec] ->
            Count = Rec#team_author.times,
            TeamTo = misc:term_to_bitstring(Rec#team_author.team_to),
            TeamFrom = misc:term_to_bitstring(Rec#team_author.team_from),
            IsGuildAll = 
                case Rec#team_author.is_guild_all of
                     true -> 1;
                     _ ->0
                 end,
            LastTime = Rec#team_author.last_add_count_time,
            case mysql_api:select(userId, game_team_invite_offline,  [{userId, UserId}, {type, Type}]) of
                {ok, []} ->
                    mysql_api:insert(game_team_invite_offline, 
                                     [userId, type, team_to, team_from, is_guild_all, last_add_count_time, times], 
                                     [UserId, Type, TeamTo, TeamFrom, IsGuildAll, LastTime, Count]);
                _ ->
                    mysql_api:update(game_team_invite_offline, 
                                     [{team_to, TeamTo}, 
                                      {team_from, TeamFrom}, 
                                      {is_guild_all, IsGuildAll},
                                      {last_add_count_time, LastTime},
                                      {times, Count}], [{userId, UserId}, {type, Type}])
            end
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩家进程操作：EtsTeamHall
%% 组队进程操作：EtsTeamInfo
%% 玩家进程操作：EtsTeamPlayer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
logout(Player) ->
    insertdb_invite_info(Player#player.user_id, ?CONST_TEAM_TYPE_COPY),
    insertdb_invite_info(Player#player.user_id, ?CONST_TEAM_TYPE_INVASION),
    {_UserState, _, PlayState} = player_state_api:get_state(Player),
    if
        Player#player.team_id =/= 0 -> % 退出队伍
            quit(Player);
        ?CONST_PLAYER_PLAY_MULTI_COPY =:= PlayState orelse
		?CONST_PLAYER_PLAY_INVASION =:= PlayState orelse
		?CONST_PLAYER_PLAY_GUIDE =:= PlayState orelse
		?CONST_PLAYER_PLAY_MULTI_ARENA =:= PlayState -> % 退出大厅
            case quit_hall(Player) of
				{?ok, Player2} -> {?ok, Player2};
				_ -> {?ok, Player}
			end;
        ?true -> {?ok, Player}
    end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 进入大厅(组队玩法模块调用)
enter_hall(Player) ->
	case team_type(Player) of
		0 -> {?error, ?TIP_TEAM_NOT_TEAM_PLAY}; % 不在多人玩法中
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, EtsTeamExt
			}			= team_ets(TeamType),
			% 加入大厅
			TeamHall	= team_mod:record_team_hall(Player),
			ets_api:insert(EtsTeamHall, TeamHall),
			ets_ext_insert(EtsTeamExt, TeamHall),
			% 进入组队大厅[18400]
			PacketEnter	= msg_sc_enter_hall(),
			% 大厅广播(协议18500:角色进入大厅通知 )
			Packet18500	= msg_sc_enter_hall_notice(TeamType, TeamHall),
			broadcast_hall_broadcast(TeamType, Packet18500, EtsTeamHall),
			
			% 打包大厅队伍信息(协议18510:队伍信息)
			PacketTeam	= msg_team_info(EtsTeamInfo),
			% 打包大厅角色信息(协议18500:大厅角色信息)
			PacketHall	= msg_team_hall_info(TeamType, EtsTeamExt),
			{?ok, <<PacketEnter/binary, PacketTeam/binary, PacketHall/binary>>}
	end.

msg_team_info(EtsTeamInfo) ->
	TeamList	= ets_api:list(EtsTeamInfo),
	Fun			= fun(Team, Acc) ->
						  Bin	= msg_sc_team_insert_notice(Team),
						  <<Acc/binary, Bin/binary>>
				  end,
	lists:foldl(Fun, <<>>, TeamList).

msg_team_hall_info(?CONST_TEAM_TYPE_COPY, _EtsTeamExt) -> <<>>;
msg_team_hall_info(?CONST_TEAM_TYPE_INVASION, _EtsTeamExt) -> <<>>;
msg_team_hall_info(?CONST_TEAM_TYPE_ARENA, EtsTeamExt) ->
	TeamList	= ets_api:list(EtsTeamExt),
	Fun			= fun(TeamHall, Acc) ->
						  Bin	= msg_sc_enter_hall_notice(?CONST_TEAM_TYPE_ARENA, TeamHall),
						  <<Acc/binary, Bin/binary>>
				  end,
	lists:foldl(Fun, <<>>, TeamList).

broadcast_hall_broadcast(?CONST_TEAM_TYPE_COPY, Packet, EtsTeamHall)		->
	broadcast_hall(?CONST_TEAM_TYPE_COPY, Packet, EtsTeamHall);
broadcast_hall_broadcast(?CONST_TEAM_TYPE_INVASION, Packet, EtsTeamHall)	->
	broadcast_hall(?CONST_TEAM_TYPE_INVASION, Packet, EtsTeamHall);
broadcast_hall_broadcast(?CONST_TEAM_TYPE_ARENA, Packet, EtsTeamHall)		->
	broadcast_hall(?CONST_TEAM_TYPE_ARENA, Packet, EtsTeamHall).


change_team(Player, Id) ->
    case team_type(Player) of
        0 ->% 未在组队玩法中，无资格组队
            {?error, ?TIP_TEAM_NOT_TEAM_PLAY};
        TeamType ->
            {
             _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
            }           = team_ets(TeamType),
            case check_change(Player, TeamType, EtsTeamInfo, Id) of
                {?ok, TeamTmp} ->
                    case team_serv:change_team(TeamTmp#team.team_pid, Id, TeamTmp#team.param) of
                        {?ok, Team} ->
                            CrossKey = get_cross_team_key(TeamTmp#team.team_id),
                            ets:update_element(?CONST_ETS_TEAM_CROSS_LOCAL, CrossKey, 
                                               [{#team_cross.max_count, Team#team.count_max},
                                                {#team_cross.copy_id, Id}]),
                            % 队伍广播队伍详细信息(协议18530:队伍详细信息)
                            PacketTeam  = team_api:msg_sc_info(Team, EtsTeamPlayer),
                            Packet = msg_sc_change_copy2(Id, true),
                            team_api:broadcast_team(Team, <<PacketTeam/binary, Packet/binary>>),
                            % 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
                            Packet18510 = team_api:msg_sc_team_insert_notice(Team),
                            team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
                            
                            
                            ?ok;
                        {?error, ErrorCode} -> {?error, ErrorCode}
                    end;
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.


check_change(Player, TeamType, EtsTeamInfo, Id) ->
    try
        ?ok         = check_have_no_team(Player),  % 有队伍
        {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id), % 队伍存在
        ?ok         = team_mod:check_leader(Team, Player#player.user_id), %是队长
        {?ok, TeamParam} = check_team_play(Player, TeamType, Id, ?CONST_TEAM_CHECK_CREATE), % 可以切换
        ?ok = check_member_player(Team, TeamType, Id),
        {?ok, Team#team{param = TeamParam}} 
    catch
        throw:{?error, ErrorCode} -> {?error, ErrorCode};
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG} % 未知错误
    end.

check_member_player(Team, TeamType, Id) ->
    LeadId = Team#team.leader_uid,
    Camp = Team#team.camp,
    Postion = Camp#camp.position,
    IdList = tuple_to_list(Postion),
    PlayFun =
        fun(Camp_pos) ->
                case Camp_pos of
                    0 ->
                        true;
                    1 ->
                        true;
                    #camp_pos{id = LeadId} ->
                        true;
                    #camp_pos{id = UserId} ->
                        case is_author(Team, UserId) of
                            true ->
                                true;
                            _ ->
                                case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                                    [] ->
                                        case check_team_play(UserId, TeamType, Id, ?CONST_TEAM_CHECK_CREATE) of
                                            {?ok, _} ->
                                                true;
                                            _ ->
                                                false
                                        end;
                                    [CrossRec] ->
                                        Node = CrossRec#cross_in.node,
                                        case rpc:call(Node, team_api, check_team_play, [UserId, TeamType, Id, ?CONST_TEAM_CHECK_CREATE]) of
                                            {?ok, _} ->
                                                true;
                                            _ ->
                                                false
                                        end  
                                end
                        end
                end
        end,
    case lists:all(PlayFun, IdList) of
        true ->
            ?ok;
        _ ->
            throw({?error, ?TIP_TEAM_MEMBER_NOT_OPEN_COPY})
    end.
                
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 创建队伍
create(Player, Id) ->

	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格组队
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}			= team_ets(TeamType),
			case check_creat(Player, TeamType, EtsTeamPlayer, Id) of
				{?ok, TeamParam} ->
					Camp		= camp_api:get_curent_camp(Player),
					TeamCamp	= camp_api:read_camp(Camp#camp.camp_id, Camp#camp.lv),
					TeamPlayer	= team_mod:record_team_player(Player, ?CONST_TEAM_PLAYER_STATE_READY),
					case team_sup:start_child_team_serv(TeamType, TeamCamp, TeamPlayer, TeamParam) of
						{?ok, _Pid, TeamId} ->
							ets_api:insert(EtsTeamPlayer, TeamPlayer),
							ets_api:delete(EtsTeamHall, Player#player.user_id),
							{?ok, Team}	= get_team(EtsTeamInfo, TeamId),
                            CrossKey = get_cross_team_key(TeamId),
                            case TeamType of
                                ?CONST_TEAM_TYPE_ARENA ->
                                    ok;
                                _ ->
                                    ets:insert(?CONST_ETS_TEAM_CROSS_LOCAL, #team_cross{team_type = TeamType, 
                                                                                        copy_id = Id, 
                                                                                        key = CrossKey, 
                                                                                        count = 1, 
                                                                                        max_count = Team#team.count_max,
                                                                                        level = Team#team.avg_lv})
                            end,
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
							Packet18502 = msg_sc_quit_hall_notice(TeamType, TeamPlayer#team_player.uid),
							Packet18510	= msg_sc_team_insert_notice(Team),
							team_api:broadcast_hall(TeamType, <<Packet18502/binary, Packet18510/binary>>, EtsTeamHall),
							update_player_team(Team, Team#team.team_id, Team#team.leader_uid),
							update_player_team_cb(Player, {Team#team.team_id, Team#team.leader_uid});
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}% 当前使用阵型不满足
			end
	end.

check_creat(Player, TeamType, EtsTeamPlayer, Id) ->
	try
		Camp		= camp_api:get_curent_camp(Player),
		?ok			= team_mod:check_camp(Camp, 3), % 当前阵法可站至少3人
		?ok			= check_have_team(Player),  % 无队伍
		case team_mod:check_have_team(EtsTeamPlayer, Player#player.user_id) of
			{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
			{?false, ?null} -> check_team_play(Player, TeamType, Id, ?CONST_TEAM_CHECK_CREATE)
		end
	catch
		throw:{?error, ?TIP_TEAM_NO_CAMP} -> {?error, ?TIP_TEAM_NO_CAMP_CREATE};
		throw:{?error, ErrorCode} -> {?error, ErrorCode};
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG} % 未知错误
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
cross_join(Player, TeamKey, Password) ->
    case team_type(Player) of
        0 ->% 未在组队玩法中，无资格加入
            {?error, ?TIP_TEAM_NOT_TEAM_PLAY};
        TeamType ->
            {
             _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
            }           = team_ets(TeamType),
            case check_join_cross(Player, TeamType, EtsTeamInfo, EtsTeamPlayer, TeamKey, Password) of
                {?ok, TeamTmp} ->
                    TeamPlayer  = team_mod:record_team_player(Player, ?CONST_TEAM_PLAYER_STATE_WAIT),
                    {TeamId, ServId} = TeamKey,
                    NodeFrom = cross_api:get_node(ServId),
                    case team_serv:join_call({NodeFrom, TeamTmp#team.team_pid}, TeamPlayer) of
                        ?ok ->
                            SelfIndex = cross_api:get_self_index(),
                            UserId = Player#player.user_id,
                            CrossRec = #cross_in{node = node(), serv_index = SelfIndex, battle_player = battle_mod:init_get_player(UserId),user_id = UserId},
                            rpc:cast(NodeFrom, ets, insert, [?CONST_ETS_CROSS_IN, CrossRec]),
                            ets_api:insert(EtsTeamPlayer, TeamPlayer),
                            ets_api:delete(EtsTeamHall, Player#player.user_id),
                            % 队伍广播队伍详细信息(协议18530:队伍详细信息)
                            rpc:cast(NodeFrom, ?MODULE, broad_join_info_cross, [TeamId, TeamType, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer]),
                            % 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
                            Packet18502 = team_api:msg_sc_quit_hall_notice(TeamType, TeamPlayer#team_player.uid),
                            team_api:broadcast_hall(TeamType, Packet18502, EtsTeamHall),
                            update_player_team_cb(Player, {{TeamId, ServId}, TeamTmp#team.leader_uid});
                        {?error, ErrorCode} -> {?error, ErrorCode}
                    end;
                {?error, ErrorCode} -> {?error, ErrorCode}
            end
    end.

broad_join_info_cross(TeamId, TeamType, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer) ->
    {?ok, Team} = get_team(EtsTeamInfo, TeamId),
    PacketTeam = team_api:msg_sc_info(Team, EtsTeamPlayer),
    team_api:broadcast_team(Team, PacketTeam),
    Packet18510 = team_api:msg_sc_team_insert_notice(Team),
    team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall).

join(Player, TeamId, Password) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格加入
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}			= team_ets(TeamType),
			case check_join(Player, TeamType, EtsTeamInfo, EtsTeamPlayer, TeamId, Password) of
				{?ok, TeamTmp} ->
					TeamPlayer	= team_mod:record_team_player(Player, ?CONST_TEAM_PLAYER_STATE_WAIT),
					case team_serv:join_call(TeamTmp#team.team_pid, TeamPlayer) of
						?ok ->
							ets_api:insert(EtsTeamPlayer, TeamPlayer),
							ets_api:delete(EtsTeamHall, Player#player.user_id),
							{?ok, Team}	= get_team(EtsTeamInfo, TeamId),
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
							Packet18502 = team_api:msg_sc_quit_hall_notice(TeamType, TeamPlayer#team_player.uid),
							Packet18510	= team_api:msg_sc_team_insert_notice(Team),
							team_api:broadcast_hall(TeamType, <<Packet18502/binary, Packet18510/binary>>, EtsTeamHall),
							% 
							update_player_team(Team, Team#team.team_id, Team#team.leader_uid),
							update_player_team_cb(Player, {Team#team.team_id, Team#team.leader_uid});
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.

check_join_cross(Player, TeamType, EtsTeamInfo, EtsTeamPlayer, {TeamId, ServId}, Password) ->
    try
        {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, {TeamId, ServId}),
        ?ok         = team_mod:check_team_state(Team),
        ?ok         = team_mod:check_team_num(Team),
        ?ok         = team_mod:check_password(Team, Password),
        ?ok         = check_have_team(Player),
        TeamParam   = Team#team.param,
        case team_mod:check_have_team(EtsTeamPlayer, Player#player.user_id) of
            {?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
            {?false, ?null} ->
                case check_team_play(Player, TeamType, TeamParam#team_param.id, ?CONST_TEAM_CHECK_JOIN) of
                    {?ok, _TeamParam} -> {?ok, Team};
                    {?error, ErrorCode} -> {?error, ErrorCode}
                end
        end
    catch
        throw:Return -> Return;
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
    end.

check_join(Player, TeamType, EtsTeamInfo, EtsTeamPlayer, TeamId, Password) ->
	try
        UserId = Player#player.user_id,
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, TeamId),
		?ok			= team_mod:check_team_state(Team),
        case is_author(Team, UserId) of
            false ->
		      ?ok			= team_mod:check_team_num(Team);
            _ ->
                ok
        end,
		?ok			= team_mod:check_password(Team, Password),
		?ok			= check_have_team(Player),
		TeamParam	= Team#team.param,
		case team_mod:check_have_team(EtsTeamPlayer, Player#player.user_id) of
			{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
			{?false, ?null} ->
				case check_team_play(Player, TeamType, TeamParam#team_param.id, ?CONST_TEAM_CHECK_JOIN) of
					{?ok, _TeamParam} -> {?ok, Team};
					{?error, ErrorCode} -> {?error, ErrorCode}
				end
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
is_author(Team, UserId) ->
    AuthorList = Team#team.author_list,
    lists:keymember(UserId, #team_player.uid, AuthorList).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
remove(Player, UserId) ->
	case team_type(Player) of
		0 -> {?error, ?TIP_TEAM_NOT_TEAM_PLAY}; % 未在组队玩法中，无资格操作
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_remove(Player, EtsTeamInfo, UserId) of
				{?ok, TeamTmp} ->
                    IsAuthor = is_author(TeamTmp, UserId),
					case team_serv:remove_call(TeamTmp#team.team_pid, UserId) of
						?ok ->
							{?ok, Team}	= get_team(EtsTeamInfo, TeamTmp#team.team_id),
                            PacketTeam  = team_api:msg_sc_info(Team, EtsTeamPlayer),
                            team_api:broadcast_team(Team, PacketTeam),
                            case IsAuthor of
                                false ->
                                    case lists:keyfind(UserId, #team_player.uid, TeamTmp#team.cross_list) of
                                        false ->
                                            remove_notify(EtsTeamPlayer, UserId);
                                        TeamPlayer ->
                                            FromIndex = TeamPlayer#team_player.index_from,
                                            NodeFrom = cross_api:get_node(FromIndex),
                                            rpc:cast(NodeFrom, team_api, remove_notify, [EtsTeamPlayer, UserId])
                                    end;
                                _ ->
                                    ok
                            end,
                            Packet18510 = team_api:msg_sc_team_insert_notice(Team),
                            team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
							{?ok, Player};
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.

remove_notify(EtsTeamPlayer, UserId) ->
    ets_api:delete(EtsTeamPlayer, UserId),
    % 通知玩家退出队伍
    PacketNotice= message_api:msg_notice(?TIP_TEAM_LEADER_REMOVE),
    Packet18526 = team_api:msg_sc_quit_notice(1),
    misc_packet:send(UserId, <<Packet18526/binary, PacketNotice/binary>>),
    update_player_team(UserId, {0, 0}).

check_remove(Player, EtsTeamInfo, UserId) ->
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_leader(Team, Player#player.user_id),
		?ok			= team_mod:check_member(Team, UserId),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 退出队伍时:
%% 1.玩法中途退出:不管玩家是不是队长，直接清掉他的队伍信息，包括潜在可能的大厅信息，需要广播
%% 2.玩法结束退出：
%%   2.1.队长的玩法次数有剩余：全员不退出队伍，返回组队界面
%%   2.2.队长的玩法次数无剩余：全员退出队伍，队伍信息删除，队员信息删除，进入大厅，返回大厅信息，需要广播
%% 3.玩法还没开始就退出：
%%   3.1.队长退出：换队长,删除队员信息，更新队伍信息，进入大厅，需要广播
%%   3.2.队员退出：删除队员信息，更新队伍信息，进入大厅，需要广播
%% 4.特殊强制处理：
%%   4.1.玩家的玩法状态不存在，但玩家的表信息其实还有可能存在：清掉对应的队员，队伍信息
%%-----------------------------
%% 综上：
%% 1.玩家退出队伍部分也就只能提供到队伍、队员数据的一致就可以了，其他的由对应的玩法自己处理
quit(UserId) when is_number(UserId) ->
    player_api:process_send(UserId, ?MODULE, do_quit, []);
quit(Player) ->
	case team_type(Player) of
		0 ->
			quit_absolutely(Player),
			update_player_team_cb(Player, {0, 0});
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
			}		= team_ets(TeamType),
			case check_quit(Player, EtsTeamInfo) of
                {?ok, Team, IndexFrom} ->
                    NodeFrom = cross_api:get_node(IndexFrom),
                    team_serv:quit_cast({NodeFrom, Team#team.team_pid}, Player#player.user_id, <<>>),
                    ets_api:delete(EtsTeamHall, Player#player.user_id),
                    ets_ext_delete(EtsTeamExt, Player#player.user_id),
                    ets_api:delete(EtsTeamPlayer, Player#player.user_id),
                    case TeamType of
                        ?CONST_TEAM_TYPE_ARENA ->
                            arena_pvp_mod:set_auto(Player#player.user_id, 2, 0),
                            LeaderId = Team#team.leader_uid,
                            arena_pvp_mod:set_auto(LeaderId, 1, 0);
                        _ ->
                            ok
                    end,
                    Packet18502 = msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
                    broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
                    update_player_team_cb(Player, {0, 0});
				{?ok, Team} ->
					team_serv:quit_cast(Team#team.team_pid, Player#player.user_id, <<>>),
					ets_api:delete(EtsTeamHall, Player#player.user_id),
					ets_ext_delete(EtsTeamExt, Player#player.user_id),
					ets_api:delete(EtsTeamPlayer, Player#player.user_id),
                    case TeamType of
                        ?CONST_TEAM_TYPE_ARENA ->
                            arena_pvp_mod:set_auto(Player#player.user_id, 2, 0),
                            LeaderId = Team#team.leader_uid,
                            arena_pvp_mod:set_auto(LeaderId, 1, 0);
                        _ ->
                            ok
                    end,
					Packet18502	= msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
					broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
					update_player_team_cb(Player, {0, 0});
				{?error, ErrorCode} ->  % 退出
					Packet	= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.net_pid, Packet),
					update_player_team_cb(Player, {0, 0})
			end
	end.

%% 强制退出
do_quit(Player, _) ->
    quit(Player).

%% 检查退出队伍
check_quit(Player, EtsTeamInfo) ->
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_member(Team, Player#player.user_id),
        case Player#player.team_id of
            {_TeamId, IndexFrom} ->
                {ok, Team, IndexFrom};
            _ ->
		        {?ok, Team}
        end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_TEAM_ERR_IN_QUIT}% 有可能是匹配不上，这时应该检查上面的匹配是否被改过
	end.

%% 清除玩家对应的所有表的信息
quit_absolutely(Player) ->
    TeamId 				= Player#player.team_id,
    UserId 				= Player#player.user_id,
    EtsTeamInfoList 	= [?CONST_ETS_TEAM_INFO_ARENA, ?CONST_ETS_TEAM_INFO_COPY, ?CONST_ETS_TEAM_INFO_INVASION],
    EtsTeamPlayerList 	= [?CONST_ETS_TEAM_PLAYER_ARENA, ?CONST_ETS_TEAM_PLAYER_COPY, ?CONST_ETS_TEAM_PLAYER_INVASION],
    EtsTeamHallList		= [?CONST_ETS_TEAM_HALL_ARENA, ?CONST_ETS_TEAM_HALL_COPY, ?CONST_ETS_TEAM_HALL_INVASION],
    EtsTeamExtList		= [?CONST_ETS_TEAM_EXT_ARENA],
    clear_team_info(EtsTeamInfoList, TeamId),
    delete_team_player(EtsTeamPlayerList, UserId),
    delete_team_hall(EtsTeamHallList, UserId),
    delete_team_ext(EtsTeamExtList, UserId).


%% 清玩家的ets_team_player_xxx信息
clear_team_info([EtsTeamInfo|Tail], TeamId) when 0 < TeamId ->
    clear_team_info(EtsTeamInfo, TeamId),
    clear_team_info(Tail, TeamId);
clear_team_info([], _UserId) -> ?ok;
clear_team_info(EtsTeamInfo, TeamId) when is_number(TeamId) andalso 0 < TeamId ->
    case ets_api:lookup(EtsTeamInfo, TeamId) of
        #team{count = Count} when Count =< 1 ->  % 当前队伍中的人数少于1时，解散 XXX 有可能要另外处理
            ets_api:delete(EtsTeamInfo, TeamId);
        X when ?null =:= X orelse X#team.count > 1 ->
            ?ok
    end;
clear_team_info(_EtsTeamInfo, _TeamId) -> ?ok.

%% 清玩家的ets_team_player_xxx信息
delete_team_player([EtsTeamPlayer|Tail], UserId) when 0 < UserId ->
	ets_api:delete(EtsTeamPlayer, UserId),
    delete_team_player(Tail, UserId);
delete_team_player([], _UserId) -> ?ok.

%% 清玩家的ets_team_hall_xxx信息
delete_team_hall([EtsTeamHall|Tail], UserId) when 0 < UserId ->
    ets_api:delete(EtsTeamHall, UserId),
    delete_team_hall(Tail, UserId);
delete_team_hall([], _UserId) -> ?ok.

%% 清玩家的ets_team_hall_xxx信息
delete_team_ext([EtsTeamExt|Tail], UserId) when 0 < UserId ->
    ets_api:delete(EtsTeamExt, UserId),
    delete_team_ext(Tail, UserId);
delete_team_ext([], _UserId) -> ?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
change_leader(Player, UserId) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_change_leader(Player, EtsTeamInfo, UserId) of
				{?ok, Team, Camp} ->
					team_serv:change_leader_call(Team#team.team_pid, UserId, Camp);
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.

check_change_leader(Player, EtsTeamInfo, UserId) ->
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_leader(Team, Player#player.user_id),
		?ok			= team_mod:check_member(Team, UserId),
        CrossList = Team#team.cross_list,
        case is_author(Team, UserId) of
            true ->
                {?error, ?TIP_TEAM_IS_AUTHOR_PLAYER};
            _ ->
                case lists:keyfind(UserId, #team_player.uid, CrossList) of
                    false ->
                		Camp		= camp_api:get_curent_camp(UserId),
                		TeamCamp	= camp_api:read_camp(Camp#camp.camp_id, Camp#camp.lv),
                		?ok			= team_mod:check_camp(TeamCamp, 3),
                		{?ok, Team, TeamCamp};
                    _TeamPlayer ->
                        {?error, ?TIP_TEAM_IS_CROSS_PLAYER}
                end
        end
	catch
		throw:{?error, ?TIP_TEAM_NO_CAMP} -> {?error, ?TIP_TEAM_NO_CAMP_CHANGE_LEADER};
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
invite(Player, UserId) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_invite(Player, EtsTeamInfo, EtsTeamPlayer, UserId) of
				{?ok, Team} ->
					case team_serv:invite_call(Team#team.team_pid, UserId) of
						?ok ->
							Info		= Player#player.info,
							% 发送给被邀请方:邀请通知
							Packet18520	= msg_sc_invite_notice(Team#team.type, Team#team.team_id, (Team#team.param)#team_param.id,
															   Info#info.user_name, Info#info.lv, Info#info.power, player_api:get_vip_lv(Info)),
							misc_packet:send(UserId, Packet18520),
							% 发送给邀请方:邀请成功
							Packet25300	= message_api:msg_notice(?TIP_TEAM_INVITE_SUCCESS),
							misc_packet:send(Player#player.user_id, Packet25300),
							?ok;
						{?error, ?TIP_TEAM_REPEAT_INVITE} ->
							{?error, ?TIP_TEAM_REPEAT_INVITE};
						{?error, ErrorCode} ->
							{?error, ErrorCode}
					end;
				{?error, ErrorCode} ->
					{?error, ErrorCode};
				{?error, ?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList} ->
					Packet	= message_api:msg_notice(?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList, [], []),
					misc_packet:send(Player#player.user_id, Packet),
					?ok
			end
	end.

get_team_player(UserId) ->
    {ok, Info} = player_api:get_player_field(UserId, #player.info),
    {ok, Partner} = player_api:get_player_field(UserId, #player.partner),
    {ok, Stype} = player_api:get_player_field(UserId, #player.style),
    Player = #player{style = Stype, partner = Partner, info = Info},
    {ok, Postion} = player_api:get_player_field(UserId, #player.position),
    Partners    = [{X} || X <- partner_api:get_partner_id_list(Player, 0)],
    Position    = (Postion)#position_data.position,
    
    SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    IsHideFashion = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_FUSION),
    IsHideHorse   = goods_style_api:is_hide(Player, ?CONST_GOODS_EQUIP_HORSE),
    #team_player{
                 uid                = UserId,            % 玩家ID
                 name               = Info#info.user_name,              % 名称
                 pro                = Info#info.pro,                    % 职业
                 sex                = Info#info.sex,                    % 性别
                 lv                 = Info#info.lv,                     % 等级
                 state              = ?CONST_TEAM_PLAYER_STATE_READY,                            % 状态
                 position           = Position,                         % 官衔
                 power              = Info#info.power,                  % 战力
                 partners           = Partners,                         % 副将列表
                 skin_fashion       = SkinFashion,                      % 装备时装皮肤ID
                 skin_weapon        = SkinWeapon,                       % 装备武器皮肤ID
                 skin_armor         = SkinArmor,                        % 装备衣服皮肤ID
                 hide_fashion       = IsHideFashion,                    % 隐藏时装
                 hide_ride          = IsHideHorse                       % 隐藏坐骑
                }.

gold_invite(Player, UserId) ->
    case team_type(Player) of
        0 ->% 未在组队玩法中，无资格操作
            {?error, ?TIP_TEAM_NOT_TEAM_PLAY};
        TeamType ->
            {
             _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
            }       = team_ets(TeamType),
            case check_invite_gold(Player, EtsTeamInfo, EtsTeamPlayer, UserId, TeamType) of
                {?ok, Team} ->
                    case team_serv:gold_invite_call(Team#team.team_pid, UserId) of
                        ?ok ->
                            TeamPlayer  = get_team_player(UserId),
                            case team_mod:insert_member_to_team3(Team, TeamPlayer) of
                                {?ok, Team2} ->
                                    {
                                     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
                                    }   = team_api:team_ets(TeamType),
                                    ets_api:insert(EtsTeamInfo, Team2),
                                    % 队伍广播队伍详细信息(协议18530:队伍详细信息)
                                    PacketTeam  = team_api:msg_sc_info(Team2, EtsTeamPlayer),
                                    team_api:broadcast_team(Team, PacketTeam),
                                   % 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
                                    Packet18510 = team_api:msg_sc_team_insert_notice(Team2),
                                    team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
                                    ?ok;
                                {?error, ErrorCode} -> 
                                    misc_packet:send_tips(Player#player.user_id, ErrorCode)
                            end,
                            ?ok;
                        {?error, ?TIP_TEAM_REPEAT_INVITE} ->
                            {?error, ?TIP_TEAM_REPEAT_INVITE};
                        {?error, ErrorCode} ->
                            {?error, ErrorCode}
                    end;
                {?error, ErrorCode} ->
                    misc_packet:send_tips(Player#player.user_id, ErrorCode),
                    {?error, ErrorCode};
                {?error, ?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList} ->
                    Packet  = message_api:msg_notice(?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList, [], []),
                    misc_packet:send(Player#player.user_id, Packet),
                    ?ok
            end
    end.

invite2(Player, UserId) ->
    case team_type(Player) of
        0 ->% 未在组队玩法中，无资格操作
            {?error, ?TIP_TEAM_NOT_TEAM_PLAY};
        TeamType ->
            {
             _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
            }       = team_ets(TeamType),
            case check_invite2(Player, EtsTeamInfo, EtsTeamPlayer, UserId, TeamType) of
                {?ok, Team} ->
                    case team_serv:invite_call2(Team#team.team_pid, UserId) of
                        ?ok ->
                            TeamPlayer  = get_team_player(UserId),
                            case team_mod:insert_member_to_team2(Team, TeamPlayer) of
                                {?ok, Team2} ->
                                    {
                                     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
                                    }   = team_api:team_ets(TeamType),
                                    ets_api:insert(EtsTeamInfo, Team2),
                                    % 队伍广播队伍详细信息(协议18530:队伍详细信息)
                                    PacketTeam  = team_api:msg_sc_info(Team2, EtsTeamPlayer),
                                    team_api:broadcast_team(Team, PacketTeam),
                                   % 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
                                    Packet18510 = team_api:msg_sc_team_insert_notice(Team2),
                                    team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
                                    ?ok;
                                {?error, ErrorCode} -> 
                                    misc_packet:send_tips(Player#player.user_id, ErrorCode)
                            end,
                            ?ok;
                        {?error, ?TIP_TEAM_REPEAT_INVITE} ->
                            {?error, ?TIP_TEAM_REPEAT_INVITE};
                        {?error, ErrorCode} ->
                            {?error, ErrorCode}
                    end;
                {?error, ErrorCode} ->
                     misc_packet:send_tips(Player#player.user_id, ErrorCode),
                    {?error, ErrorCode};
                {?error, ?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList} ->
                    Packet  = message_api:msg_notice(?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, UserList, [], []),
                    misc_packet:send(Player#player.user_id, Packet),
                    ?ok
            end
    end.

get_count(UserId, Type) ->
    case ets:lookup(?CONST_ETS_TEAM_AUTHOR, {UserId, Type}) of
        [] ->
            0;
        [Rec] ->
            LastTime = Rec#team_author.last_add_count_time,
            Now = misc:seconds(),
            case misc:is_same_date(LastTime, Now) of
                false ->
                    ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId, Type}, {#team_author.times, 0}),
                    0;
                _ ->
                    Rec#team_author.times
            end
    end.

check_is_in_not_cd(LeaderId, UserId,Type) ->
    Times = get_count(UserId, Type),
    case Times >= 6 of
        true ->
            false; 
        _ ->
            case ets:lookup(?CONST_ETS_TEAM_INVITE_CD, {LeaderId, UserId, Type}) of
                [] ->
                    true;
                [CdRec] ->
                    Next = 10*60 + CdRec#team_invite_cd.last_invite_time,
                    Next < misc:seconds()
            end
    end.

check_invite_gold(TeamId, _UserId, EtsTeamInfo, _EtsTeamPlayer, _TeamType) when is_integer(TeamId) ->
    try
        {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, TeamId),
        ?ok         = team_mod:check_team_state(Team),
        ?ok         = team_mod:check_team_num(Team),
        {?ok, Team}
    catch
        throw:Return -> Return;
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
    end;

check_invite_gold(Player, EtsTeamInfo, _EtsTeamPlayer, UserId, _TeamType) ->
    try
        {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
        case check_in_team(Team, UserId) of
            false ->
                ?ok         = team_mod:check_team_state(Team),
                ?ok         = team_mod:check_leader(Team, Player#player.user_id),
                ?ok         = team_mod:check_team_num(Team),
                {?ok, Team};
            _ ->
                {?error, ?TIP_TEAM_REAL_IN_TEAM}
        end
    catch
        throw:Return -> Return;
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
    end.


check_invite2(TeamId, UserId, EtsTeamInfo, _EtsTeamPlayer, TeamType) when is_integer(TeamId) ->
    try
        {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, TeamId),
        LeaderId = Team#team.leader_uid,
        case check_is_in_not_cd(LeaderId, UserId, TeamType) of
            false ->
                {?error, ?TIP_TEAM_AUTHOR_IN_CD};
            _ ->
                case is_author(Team, UserId) of
                    false ->
                        ?ok         = team_mod:check_team_state(Team),
                        ?ok         = team_mod:check_team_num(Team),
                        {?ok, Team};
                    _ ->
                        {?error, ?TIP_TEAM_AUTHOR_IN_TEAM}
                end
        end
    catch
        throw:Return -> Return;
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
    end;


check_invite2(Player, EtsTeamInfo, _EtsTeamPlayer, UserId, TeamType) ->
    LeaderId = Player#player.user_id,
    try
        case check_is_in_not_cd(LeaderId, UserId, TeamType) of
            false ->
                {?error, ?TIP_TEAM_AUTHOR_IN_CD};
            _ ->
                {?ok, Team} = team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
                case is_author(Team, UserId) of
                    true ->
                        {?error, ?TIP_TEAM_AUTHOR_IN_TEAM};
                    _ ->
                        case check_in_team(Team, UserId) of
                            false ->
                                ?ok         = team_mod:check_team_state(Team),
                                ?ok         = team_mod:check_leader(Team, Player#player.user_id),
                                ?ok         = team_mod:check_team_num(Team),
                                {?ok, Team};
                            _ ->
                                {?error, ?TIP_TEAM_REAL_IN_TEAM}
                        end
                end
        end
    catch
        throw:Return -> Return;
        _:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
    end.

check_in_team(Team, UserId) ->
    Camp = Team#team.camp,
    CampList = misc:to_list(Camp#camp.position),
    Filter = 
        fun(O) ->
                is_tuple(O)
        end,
    CampReal = lists:filter(Filter, CampList),
    case lists:keymember(UserId, #camp_pos.id, CampReal) of
        true ->
            true;
        _ ->
            false
    end.

check_invite(Player, EtsTeamInfo, EtsTeamPlayer, UserId) ->
	try
		case team_mod:check_have_team(EtsTeamPlayer, UserId) of
			{?true, TeamPlayer} ->
				{?error, ?TIP_TEAM_PLAYER_ALREADY_IN_TEAM, [{TeamPlayer#team_player.uid, TeamPlayer#team_player.name}]};
			{?false, ?null} ->
				{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
				?ok			= team_mod:check_team_state(Team),
				?ok			= team_mod:check_leader(Team, Player#player.user_id),
				?ok			= team_mod:check_team_num(Team),
				TeamParam	= Team#team.param,
				case check_team_play(UserId, Team#team.type, TeamParam#team_param.id, ?CONST_TEAM_CHECK_INVITE) of
					{?ok, _TeamParam} -> {?ok, Team};
					{?error, ErrorCode} -> {?error, ErrorCode}
				end
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reply(Player, TeamType, TeamId, Decide) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
	}		= team_ets(TeamType),
	UserId	= Player#player.user_id,
	Result	=
		case check_reply(Player, EtsTeamInfo, EtsTeamPlayer, TeamId, Decide) of
			{?ok, TeamTmp, UserList} ->
				PlayState	= case TeamType of
								  ?CONST_TEAM_TYPE_COPY -> ?CONST_PLAYER_PLAY_MULTI_COPY;
								  ?CONST_TEAM_TYPE_INVASION -> ?CONST_PLAYER_PLAY_INVASION;
								  ?CONST_TEAM_TYPE_ARENA -> ?CONST_PLAYER_PLAY_MULTI_ARENA
							  end,
				case player_state_api:try_set_state_play(Player, PlayState) of
					{?true, Player2} ->
						Packet	 	= message_api:msg_notice(?TIP_TEAM_REPLY_AGREE_NOTICE, UserList, [], []),
						misc_packet:send(TeamTmp#team.leader_uid, Packet),
						TeamHall	= team_mod:record_team_hall(Player),
						ets_ext_insert(EtsTeamExt, TeamHall),
						TeamPlayer	= team_mod:record_team_player(Player2, ?CONST_TEAM_PLAYER_STATE_WAIT),
						Flag		= ?true,
						{?ok, Player2};
					{?false, Player, Tips} ->
						TeamPlayer	= ?null,
						Flag		= ?false,
						Packet		= message_api:msg_notice(Tips),
						misc_packet:send(Player#player.user_id, Packet),
						{?ok, Player}
				end;
			{?error, ErrorCode, TeamTmp, UserList} ->
				TeamPlayer	= ?null,
				Flag		= ?false,
				Packet	 	= message_api:msg_notice(ErrorCode, UserList, [], []),
				misc_packet:send(TeamTmp#team.leader_uid, Packet),
				{?ok, Player};
			{?error, ErrorCode} ->
				TeamTmp		= ?null,
				TeamPlayer	= ?null,
				Flag		= ?false,
				{?error, ErrorCode}
		end,
	case Result of
		{?ok, Player3} ->
			case team_serv:reply_call(TeamTmp#team.team_pid, UserId, TeamPlayer, Flag) of
				?ok ->
					{?ok, Team}	= get_team(EtsTeamInfo, TeamTmp#team.team_id),
					case Flag of
						?true ->
							update_player_team(Team, Team#team.team_id, Team#team.leader_uid),
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
							Packet18502 = team_api:msg_sc_quit_hall_notice(Team#team.type, TeamPlayer#team_player.uid),
							Packet18510	= team_api:msg_sc_team_insert_notice(Team),
							team_api:broadcast_hall(Team#team.type, <<Packet18502/binary, Packet18510/binary>>, EtsTeamHall),
							{?ok, Player3};
						?false -> {?ok, Player3}
					end;
				{?error, Error} -> {?error, Error}
			end;
		{?error, Error} -> {?error, Error}
	end.

check_reply(Player, EtsTeamInfo, EtsTeamPlayer, TeamId, ?CONST_TEAM_REPLY_AGREE) ->% 接受
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, TeamId),
		?ok			= team_mod:check_team_invited(Team, Player#player.user_id),
		?ok			= team_mod:check_team_state(Team),
		?ok			= check_have_team(Player),
        case is_author(Team, Player#player.user_id) of
            false ->
		      ?ok			= team_mod:check_team_num(Team);
            _ ->
                ok
        end,
		case team_mod:check_have_team(EtsTeamPlayer, Player#player.user_id) of
			{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
			{?false, ?null} ->
				TeamParam	= Team#team.param,
				case check_team_play(Player, Team#team.type, TeamParam#team_param.id, ?CONST_TEAM_CHECK_REPLY_JOIN) of
					{?ok, _TeamParam} -> {?ok, Team, [{Player#player.user_id, (Player#player.info)#info.user_name}]};
					{?error, ErrorCode} -> {?error, ErrorCode}
				end
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end;
check_reply(Player, EtsTeamInfo, _EtsTeamPlayer, TeamId, Decide) ->% 拒绝|超时
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, TeamId),
		UserList	= [{Player#player.user_id, (Player#player.info)#info.user_name}],
		ErrorCode	= case Decide of
						  ?CONST_TEAM_REPLY_REJECT -> ?TIP_TEAM_REPLY_REJECT_NOTICE;
						  ?CONST_TEAM_REPLY_TIMEOUT -> ?TIP_TEAM_REPLY_TIMEOUT_NOTICE
					  end,
		{?error, ErrorCode, Team, UserList}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_team_state(TeamType, TeamId, State) when TeamType =:= ?CONST_TEAM_TYPE_ARENA ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}		= team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			team_serv:set_team_state_cast(Team#team.team_pid, State),
			?ok;
		{?error, _ErrorCode} -> ?ok
	end;
set_team_state(TeamType, TeamId, State) when TeamType =:= ?CONST_TEAM_TYPE_INVASION ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}		= team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			team_serv:set_team_state_cast(Team#team.team_pid, State),
			?ok;
		{?error, _ErrorCode} -> ?ok
	end;
set_team_state(_,_,_) -> ?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_member_state(UserId, State) when is_number(UserId) ->
	player_api:process_send(UserId, ?MODULE, set_member_state, State);
set_member_state(Player, State) when is_record(Player, player) ->
    UserId = Player#player.user_id,
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			Packet	= message_api:msg_notice(?TIP_TEAM_NOT_TEAM_PLAY),
            misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_set_member_state(Player, EtsTeamInfo) of
				{?ok, Team} ->
					TeamPlayer	= ets_api:lookup(EtsTeamPlayer, Player#player.user_id),
					TeamPlayer2	= TeamPlayer#team_player{state = State},
					ets_api:insert(EtsTeamPlayer, TeamPlayer2),
                    case lists:keymember(UserId, #team_player.uid, Team#team.cross_list) of
                        false ->
                            Packet      = team_api:msg_sc_info(Team, EtsTeamPlayer),
                            broadcast_team(Team, Packet);
                        _ ->
                            {_TeamId, ServId} = Player#player.team_id,
                            NodeTeam = cross_api:get_node(ServId),
                            rpc:cast(NodeTeam, team_api, broad_set_state, [Team, EtsTeamInfo, EtsTeamPlayer, TeamPlayer2])
                    end,
					{?ok, Player};
				{?error, ErrorCode} ->
					Packet 		= message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player}
			end
	end.

broad_set_state(Team, EtsTeamInfo, EtsTeamPlayer, TeamPlayer2) ->
    OldCrossList = Team#team.cross_list,
    NewCrossList = lists:keyreplace(TeamPlayer2#team_player.uid, #team_player.uid, OldCrossList, TeamPlayer2),
    NewTeam = Team#team{cross_list = NewCrossList},
    Packet      = team_api:msg_sc_info(NewTeam, EtsTeamPlayer),
    ets:insert(EtsTeamInfo, NewTeam),
    broadcast_team(Team, Packet).

check_set_member_state(Player, EtsTeamInfo) ->
	try
		?ok			= check_have_no_team(Player),
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_member(Team, Player#player.user_id),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_camp(Player, CampId) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_COMMON_BAD_ARG};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_set_camp(Player, CampId, EtsTeamInfo) of
				{?ok, TeamTmp, TeamCamp} ->
					case team_serv:set_camp_call(TeamTmp#team.team_pid, TeamCamp) of
						?ok ->
                            case Player#player.team_id of
                                {TeamId, NodeId} ->
                                    Node = cross_api:get_node(NodeId),
                                    rpc:cast(Node, ?MODULE, broad_team_cast, [EtsTeamInfo, TeamId, EtsTeamPlayer]);
                                TeamId ->
                                    {?ok, Team} = get_team(EtsTeamInfo, TeamId),
                                    % 队伍广播队伍详细信息(协议18530:队伍详细信息)
                                    PacketTeam  = team_api:msg_sc_info(Team, EtsTeamPlayer),
                                    team_api:broadcast_team(Player, PacketTeam)
                            end,
							?ok;
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.
check_set_camp(Player, CampId, EtsTeamInfo) ->
	try
		?ok 		= check_have_no_team(Player),
		case camp_api:get_player_camp(Player, CampId) of
			{?ok, Camp} ->
				TeamCamp	= camp_api:read_camp(Camp#camp.camp_id, Camp#camp.lv),
				{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
				?ok			= team_mod:check_leader(Team, Player#player.user_id),
				?ok			= team_mod:check_camp(TeamCamp, 3),
				{?ok, Team, TeamCamp};
			{?error, ErrorCode} ->
				{?error, ErrorCode}
		end
	catch
		throw:{?error, ?TIP_TEAM_NO_CAMP} -> {?error, ?TIP_TEAM_NO_CAMP_SET_CAMP};
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set_camp_pos(Player, IdxFrom, IdxTo) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_set_camp_pos(Player, EtsTeamInfo) of
				{?ok, TeamTmp} ->
					case team_serv:set_camp_pos_call(TeamTmp#team.team_pid, IdxFrom, IdxTo) of
						?ok ->
                            case Player#player.team_id of
                                {TeamId, NodeId} ->
                                    Node = cross_api:get_node(NodeId),
                                    rpc:cast(Node, ?MODULE, broad_team_cast, [EtsTeamInfo, TeamId, EtsTeamPlayer]);
                                TeamId ->
        							{?ok, Team}	= get_team(EtsTeamInfo, TeamId),
        							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
        							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
        							team_api:broadcast_team(Player, PacketTeam)
                            end,
							?ok;
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.

broad_team_cast(EtsTeamInfo, TeamId, EtsTeamPlayer) ->
    {?ok, Team} = get_team(EtsTeamInfo, TeamId),
    % 队伍广播队伍详细信息(协议18530:队伍详细信息)
    PacketTeam  = team_api:msg_sc_info(Team, EtsTeamPlayer),
    team_api:broadcast_team(Team, PacketTeam).

check_set_camp_pos(Player, EtsTeamInfo) ->
	try
		?ok 		= check_have_no_team(Player),
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_leader(Team, Player#player.user_id),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 更新TeamPlayer[升级、官衔改变、副将改变、战力改变、换装备]
%% team_api:update_team_player(Player).
update_team_player(Player) ->
	case team_type(Player) of
		0 -> ?ok;% 未在组队玩法中，无资格操作
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_update_team_player(Player, EtsTeamInfo) of
				{?ok, Team} ->
					case ets_api:lookup(EtsTeamPlayer, Player#player.user_id) of
						TeamPlayer when is_record(TeamPlayer, team_player) ->
							TeamPlayer2	= team_mod:record_team_player(Player, TeamPlayer#team_player.state),
							ets_api:insert(EtsTeamPlayer, TeamPlayer2),
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							?ok;
						_ -> ?ok
					end;
				_ -> ?ok
			end
	end.

check_update_team_player(Player, EtsTeamInfo) ->
	try
		?ok 		= check_have_no_team(Player),
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_team_param(TeamType, TeamId) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}		= team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} -> {?ok, Team#team.param};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.

set_team_param(TeamType, TeamId, TeamParam) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}		= team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} ->
			team_serv:set_team_param_cast(Team#team.team_pid, TeamParam),
			?ok;
		{?error, _ErrorCode} -> ?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法开始
play_start(TeamType, TeamId) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_ets(TeamType),
	case check_play_start(EtsTeamInfo, EtsTeamPlayer, TeamId) of
		{?ok, Team} ->
            AuthorList = Team#team.author_list,
            Cost = get_gold_invite_cost(AuthorList),
            case player_money_api:minus_money(Team#team.leader_uid, ?CONST_SYS_CASH, Cost, ?CONST_COST_TEAM_GOLD_INVITE) of
                ?ok ->
        			List	= misc:to_list((Team#team.camp)#camp.position),
        			Fun		= fun(CampPos) when is_record(CampPos, camp_pos) ->
        							  case ets_api:lookup(EtsTeamPlayer, CampPos#camp_pos.id) of
        								  TeamPlayer when is_record(TeamPlayer, team_player) ->
                                              case lists:keymember(CampPos#camp_pos.id, #team_player.uid, AuthorList) of
                                                  false ->
                									  TeamPlayer2	= TeamPlayer#team_player{state = ?CONST_TEAM_PLAYER_STATE_PLAY_START},
                									  ets_api:insert(EtsTeamPlayer, TeamPlayer2);
                                                  _ ->
                                                      ok
                                              end;
        								  _ ->
        									  ?ok
        							  end;
        						 (_) -> ?ok
        					  end,
        			lists:foreach(Fun, List),
        			
        			team_serv:play_start_cast(Team#team.team_pid),
        			?ok;
                {?error, ErrorCode} ->
                    {?error, ErrorCode}
            end;
		{?error, ErrorCode} -> {?error, ErrorCode};
		{?error, ?TIP_TEAM_SOMEONE_NOT_READY, UserList} ->
			{?error, ?TIP_TEAM_SOMEONE_NOT_READY, UserList}
	end.

check_play_start(EtsTeamInfo, EtsTeamPlayer, TeamId) ->
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, TeamId),
		?MSG_DEBUG("11:~p",[TeamId]),
		?ok			= team_mod:check_member_state(Team, EtsTeamPlayer, ?CONST_TEAM_PLAYER_STATE_READY),
		?MSG_DEBUG("11:~p",[TeamId]),
        AuthorList = Team#team.author_list,
        TeamType = Team#team.type,
        up_cd_ets(Team#team.leader_uid, AuthorList, TeamType),
		{?ok, Team}
	catch
		throw:Return -> Return;
		Type:Error ->
			?MSG_DEBUG("Type:~p Error:~p", [Type, Error]),
			{?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法结束
play_over(TeamType, TeamId) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
	}			= team_ets(TeamType),
	case check_play_over(EtsTeamInfo, EtsTeamPlayer, TeamId) of
		{?ok, Team} ->
			List	= misc:to_list((Team#team.camp)#camp.position),
            AuthorList = Team#team.author_list,
            CrossList = Team#team.cross_list,
			Fun		= fun(CampPos) when is_record(CampPos, camp_pos)->
                              case lists:keymember(CampPos#camp_pos.id, #team_player.uid, AuthorList) of
                                  false ->
                                      case ets_api:lookup(EtsTeamPlayer, CampPos#camp_pos.id) of
                                          TeamPlayer when is_record(TeamPlayer, team_player) ->
                                              TeamPlayer2   = TeamPlayer#team_player{state = ?CONST_TEAM_PLAYER_STATE_PLAY_OVER},
                                              ets_api:insert(EtsTeamPlayer, TeamPlayer2),
                                              ok;
                                          _ -> 
                                              case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, CrossList) of
                                                  false ->
                                                      ?ok;
                                                  TeamPlayer ->
                                                      Index = TeamPlayer#team_player.index_from,
                                                      TeamPlayer2   = TeamPlayer#team_player{state = ?CONST_TEAM_PLAYER_STATE_PLAY_OVER},
                                                      Node = cross_api:get_node(Index),
                                                      NewCrossList = lists:keyreplace(CampPos#camp_pos.id, #team_player.uid, CrossList, TeamPlayer2),
                                                      ets:insert(EtsTeamInfo, Team#team{cross_list = NewCrossList}),
                                                      rpc:cast(Node, ets, insert, [EtsTeamPlayer, TeamPlayer2])
                                              end
                                      end;
                                  _ ->
                                      player_api:process_send(Team#team.leader_uid, team_api, remove, CampPos#camp_pos.id) 
                              end;
						 (_) -> ?ok
					  end,
            case lists:keymember(Team#team.leader_uid, #team_player.uid, Team#team.cross_list) of
                false ->
			        lists:foreach(Fun, List);
                _ ->
                    team_api:update_player_team(Team, 0, 0)
            end,
			team_serv:play_over_cast(Team#team.team_pid),
			?ok;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
check_play_over(EtsTeamInfo, _EtsTeamPlayer, TeamId) ->
	try
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, TeamId),
%% 		?ok			= check_member_state(Team, EtsTeamPlayer, ?CONST_TEAM_PLAYER_STATE_PLAY_START),
		{?ok, Team}
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法退出
play_quit(Player) ->
	UserId	= Player#player.user_id,
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
			}			= team_ets(TeamType),
			case check_play_quit(Player, EtsTeamInfo, EtsTeamPlayer) of
				{?ok, Team, TeamPlayer} ->
					play_quit(Player, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Team, TeamPlayer);
				{?error, _ErrorCode} ->% 退出队伍，进入大厅
					ets_api:delete(EtsTeamHall, UserId),
					ets_ext_delete(EtsTeamExt, UserId),
					ets_api:delete(EtsTeamPlayer, UserId),
					Packet18502	= msg_sc_quit_hall_notice(TeamType, UserId),
					Packet18540	= team_api:msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_HALL),
					misc_packet:send(UserId, Packet18540),
					broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
					update_player_team_cb(Player, {0, 0})
			end
	end.

cross_player_quit(NewTeam, EtsTeamPlayer, EtsTeamInfo) ->
    ets:insert(EtsTeamInfo, NewTeam),
    Packet      = team_api:msg_sc_info(NewTeam, EtsTeamPlayer),
    team_api:broadcast_team(NewTeam, Packet).

play_quit(Player, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Team, TeamPlayer) ->
	UserId		= Player#player.user_id,
	TeamType	= Team#team.type,
	case check_play_over(TeamType) of
		?false ->
			case TeamPlayer#team_player.state of
				?CONST_TEAM_PLAYER_STATE_PLAY_OVER ->% 不退出队伍，改变状态  进入组队界面
					case check_play_again(Player, TeamType, (Team#team.param)#team_param.id) of
						?ok ->
							State		= if
											  Team#team.leader_uid =:= UserId -> ?CONST_TEAM_PLAYER_STATE_READY;
											  ?true -> ?CONST_TEAM_PLAYER_STATE_WAIT
										  end,
							TeamPlayer2	= TeamPlayer#team_player{state = State},
							ets_api:insert(EtsTeamPlayer, TeamPlayer2),
                            case Player#player.team_id of
                                {_TeamId, ServId} ->
                                    NewCross = lists:keyreplace(UserId, #team_player.uid, Team#team.cross_list, TeamPlayer2),
                                    NewTeam = Team#team{cross_list = NewCross},
                                    NodeFrom = cross_api:get_node(ServId),
                                    rpc:cast(NodeFrom, ?MODULE, cross_player_quit, [NewTeam, EtsTeamPlayer, EtsTeamInfo]);
                                _ ->
                                    Packet      = team_api:msg_sc_info(Team, EtsTeamPlayer),
                                    team_api:broadcast_team(Team, Packet)
                            end,
							Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_TEAM),
							misc_packet:send(UserId, Packet18540),
							{?ok, Player};
						{?error, ?TIP_ARENA_PVP_TIMES_FULL} ->
							ets_api:delete(EtsTeamHall, UserId),
							ets_ext_delete(EtsTeamExt, UserId),
							ets_api:delete(EtsTeamPlayer, UserId),
							Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_NORMAL),
							team_serv:quit_cast(Team#team.team_pid, UserId, Packet18540),
							Packet18502	= msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
							broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),

							TipPacket	= arena_pvp_api:msg_end_times_notice(?CONST_SYS_TRUE),
							misc_packet:send(Player#player.net_pid, TipPacket),
							{_Flag, Player2}	= player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY),
							{_, Player3}		= player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_NORMAL),
                            misc_packet:send(UserId, Packet18540),
							update_player_team_cb(Player3, {0, 0});
						{?error, _ErrorCode} -> % 退出队伍，进入大厅
							ets_api:delete(EtsTeamHall, UserId),
							ets_ext_delete(EtsTeamExt, UserId),
							ets_api:delete(EtsTeamPlayer, UserId),
							Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_HALL),
							team_serv:quit_cast(Team#team.team_pid, UserId, Packet18540),
							update_player_team_cb(Player, {0, 0})
					end;
				_ -> % 退出队伍，进入大厅
					ets_api:delete(EtsTeamHall, UserId),
					ets_ext_delete(EtsTeamExt, UserId),
					ets_api:delete(EtsTeamPlayer, UserId),
					Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_HALL),
					team_serv:quit_cast(Team#team.team_pid, UserId, Packet18540),
					update_player_team_cb(Player, {0, 0})
			end;
		?true ->% 对人玩法结束，退出队伍，角色回到正常状态
			ets_api:delete(EtsTeamHall, UserId),
			ets_ext_delete(EtsTeamExt, UserId),
			ets_api:delete(EtsTeamPlayer, UserId),
			Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_NORMAL),
			team_serv:quit_cast(Team#team.team_pid, UserId, Packet18540),
			Packet18502	= msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
			broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
			{_Flag, Player2}	= player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY),
			{_, Player3}		= player_state_api:try_set_state(Player2, ?CONST_PLAYER_STATE_NORMAL),
			update_player_team_cb(Player3, {0, 0})
	end.

check_play_quit(Player, EtsTeamInfo, EtsTeamPlayer) ->
	try
		?ok			= check_have_no_team(Player),
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_member(Team, Player#player.user_id),
		case ets_api:lookup(EtsTeamPlayer, Player#player.user_id) of
			TeamPlayer when is_record(TeamPlayer, team_player) ->
				{?ok, Team, TeamPlayer};
			_ -> {?error, ?TIP_COMMON_BAD_ARG}
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.

%% 检查多人组队玩法是否结束
check_play_over(?CONST_TEAM_TYPE_COPY) ->
	mcopy_api:check_play_over();
check_play_over(?CONST_TEAM_TYPE_INVASION) ->
	invasion_api:check_play_over();
check_play_over(?CONST_TEAM_TYPE_ARENA) ->
	arena_pvp_api:check_play_over();
check_play_over(_) ->
	?true.

check_play_again(Player, ?CONST_TEAM_TYPE_COPY, Id) ->
	mcopy_api:check_team_play(Player, Id, ?CONST_SYS_TRUE);
check_play_again(Player, ?CONST_TEAM_TYPE_INVASION, Id)	->
	invasion_api:check_play_again(Player, Id);
check_play_again(Player, ?CONST_TEAM_TYPE_ARENA, _Id)	->
	arena_pvp_api:check_play_again(Player);
check_play_again(_Player, _, _) ->
	?ok.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动加入
auto_join(Player, Id) ->
    case team_type(Player) of
        0 ->% 未在组队玩法中，无资格操作
            {?error, ?TIP_TEAM_NOT_TEAM_PLAY};
        TeamType ->
            {
             _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
            }       = team_ets(TeamType),
            case TeamType of
                ?CONST_TEAM_TYPE_ARENA ->
                    filter2(Player, EtsTeamInfo, Id);
                _ ->
                    filter(Player, EtsTeamInfo, Id)
            end
    end.
filter2(Player, EtsTeamInfo, Id) ->
    UserId = Player#player.user_id,
    Lv          = (Player#player.info)#info.lv,
    TeamList    = filter2(ets_api:list(EtsTeamInfo), UserId, Id, Lv, []),
    Result      = 
        case filter2(TeamList) of
            Team when is_record(Team, team) -> % 加入队伍
                case join(Player, Team#team.team_id, <<"">>) of
                    {?ok, Player2} -> 
                        Now = misc:seconds(),
                        OldDict = Team#team.last_quick_enter_time_dict,
                        NewDict = dict:store(UserId, Now, OldDict),
                        ets:update_element(EtsTeamInfo, Team#team.team_id, {#team.last_quick_enter_time_dict, NewDict}),
                        {?ok, Player2};
                    {?error, Error} -> {?error, Error}
                end;
            _ -> {?error, 110} % 创建队伍
        end,
    case Result of
        {?ok, Player3} -> {?ok, Player3};
        {?error, _} -> create(Player, Id)
    end.

filter2([]) -> ?null;
filter2([{Team, _Count, _LvDif, _LastEnterTime}]) -> Team;
filter2(TeamList) ->
    SortFun =
        fun({_T1, C1,Lv1,Time1}, {_T2, C2, Lv2, Time2}) ->

                if
                    Time1 < Time2  ->
                        true;
                    Time1 > Time2 ->
                        false;
                    Lv1 < Lv2 ->
                        true;
                    Lv1 > Lv2 ->
                        false;
                    C1 < C2 ->
                        false ;
                    true ->
                        true
                end
        end,
    SortedList = lists:sort(SortFun, TeamList),
    {TeamResult, _, _, _} = hd(SortedList),
    TeamResult.

filter2([Team|TeamList], UserId, Id, Lv, Acc) ->
    case filter_team2(Team, UserId, Id, Lv) of
        {?ok, Team, Count, LvDif, LastEnterTime} -> filter2(TeamList, UserId, Id, Lv, [{Team, Count, LvDif, LastEnterTime}|Acc]);
        _ -> filter2(TeamList, UserId, Id, Lv, Acc)
    end;
filter2([], _UserId, _Id, _Lv, Acc) -> Acc.

filter_team2(Team, UserId, Id, Lv) ->
    try
        ?ok             = filter_team_id2(Team, Id),
        {?ok, Count}    = filter_team_member_count2(Team),
        {?ok, LvDif}    = filter_team_lv2(Team, Lv),
        {?ok, LastEnterTime} = get_last_end_team_time(Team, UserId),
        RangeDif = get_level_range_index(LvDif),
        {?ok, Team, Count, RangeDif, LastEnterTime}
    catch _:_ -> {?error, 110}
    end.
filter_team_id2(Team, Id) ->
    if (Team#team.param)#team_param.id =:= Id -> ?ok; ?true -> throw({?error, 110}) end.
filter_team_member_count2(Team = #team{count = Count}) ->
    if Count < Team#team.count_max -> {?ok, Count}; ?true -> throw({?error, 110}) end.
filter_team_lv2(Team, Lv) -> {?ok, abs(Team#team.avg_lv - Lv)}.

get_last_end_team_time(Team, Id) ->
    Dict = Team#team.last_quick_enter_time_dict,
    case dict:is_key(Id, Dict) of
        false ->
            {?ok, 0};
        _ ->
            {?ok, dict:fetch(Id, Dict)}
    end.

filter(Player, _EtsTeamInfo, Id) ->
    UserId = Player#player.user_id,
	Lv			= (Player#player.info)#info.lv,
    AllList = ets:tab2list(?CONST_ETS_TEAM_CROSS_GLOBAL),
	TeamList	= filter(AllList, UserId, Id, Lv, []),
	Result		= 
		case filter(TeamList) of
			Team when is_record(Team, team_cross) -> % 加入队伍
				case cross_join(Player, Team#team_cross.key, <<"">>) of
					{?ok, Player2} -> 
                        {?ok, Player2};
					{?error, Error} -> {?error, Error}
				end;
			_ -> {?error, 110} % 创建队伍
		end,
	case Result of
		{?ok, Player3} -> 
            {?ok, Player3};
        {?error, ?TIP_INVASION_USE_UP} ->
            misc_packet:send_tips(UserId,?TIP_INVASION_USE_UP),
            {?ok, Player};
        {?error, ?TIP_MCOPY_TIMES_OVER} ->
            misc_packet:send_tips(UserId,?TIP_MCOPY_TIMES_OVER),
            {?ok, Player};
		{?error, _} -> 
            misc_packet:send_tips(UserId, ?TIP_TEAM_NO_FIT_TEAM),
            {?ok, Player}
	end.

filter([Team|TeamList], UserId, Id, Lv, Acc) ->
	case filter_team(Team, UserId, Id, Lv) of
		{?ok, Team, Count, LvDif} -> filter(TeamList, UserId, Id, Lv, [{Team, Count, LvDif}|Acc]);
		_ -> filter(TeamList, UserId, Id, Lv, Acc)
	end;
filter([], _UserId, _Id, _Lv, Acc) -> Acc.

filter_team(Team, _UserId, Id, Lv) ->
	try
         ok = filter_team_serv(Team),
		?ok				= filter_team_id(Team, Id),
		{?ok, Count}	= filter_team_member_count(Team),
		{?ok, LvDif}	= filter_team_lv(Team, Lv),
        RangeDif = get_level_range_index(LvDif),
		{?ok, Team, Count, RangeDif}
	catch _:_ -> {?error, 110}
	end.

%% get_last_end_team_time(Team, Id) ->
%%     Dict = Team#team.last_quick_enter_time_dict,
%%     case dict:is_key(Id, Dict) of
%%         false ->
%%             {?ok, 0};
%%         _ ->
%%             {?ok, dict:fetch(Id, Dict)}
%%     end.
filter_team_serv(Team) ->
    Index = cross_api:get_self_index(),
    {_TeamId, ServId} = Team#team_cross.key,
    if ServId /= Index -> ?ok; true ->throw({?error, 110}) end.
filter_team_id(Team, Id) ->
	if Team#team_cross.copy_id =:= Id -> ?ok; ?true -> throw({?error, 110}) end.
filter_team_member_count(Team = #team_cross{count = Count}) ->
	if Count < Team#team_cross.max_count -> {?ok, Count}; ?true -> throw({?error, 110}) end.
filter_team_lv(Team, Lv) -> {?ok, abs(Team#team_cross.level - Lv)}.


%% filter(TeamList) ->
%% 	ok.


filter([]) -> ?null;
filter([{Team, _Count, _LvDif}]) -> Team;
filter(TeamList) ->
    SortFun =
        fun({_T1, C1,Lv1}, {_T2, C2, Lv2}) ->

                if
                    Lv1 < Lv2 ->
                        true;
                    Lv1 > Lv2 ->
                        false;
                    C1 < C2 ->
                        false ;
                    true ->
                        true
                end
        end,
    SortedList = lists:sort(SortFun, TeamList),
    TeamCount = length(SortedList),
    ChooseIndex = misc:rand(1, TeamCount),
    {TeamResult, _, _} = lists:nth(ChooseIndex, SortedList),
    TeamResult.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 请求退出大厅
quit_hall(Player)	->
	case team_type(Player) of
        0 ->
            quit_absolutely(Player),
            update_player_team_cb(Player, {0, 0});
        TeamType ->
            {
             _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
            }       = team_ets(TeamType),
            case check_quit(Player, EtsTeamInfo) of
                {?ok, Team} ->
                    team_serv:quit_cast(Team#team.team_pid, Player#player.user_id, <<>>),
                    ets_api:delete(EtsTeamHall, Player#player.user_id),
                    ets_ext_delete(EtsTeamExt, Player#player.user_id),
                    ets_api:delete(EtsTeamPlayer, Player#player.user_id),
                    Packet18502 = msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
                    broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
                    update_player_team_cb(Player, {0, 0});
                {?error, ?TIP_TEAM_NO_THIS_TEAM} ->  % 退出
                     % 退出大厅
                     ets_api:delete(EtsTeamHall, Player#player.user_id),
                     ets_ext_delete(EtsTeamExt, Player#player.user_id),
            
                     % 大厅广播(协议18502:角色退出大厅通知)
                     Packet18502 = msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
                     broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
                     case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
                         {?false, NewPlayer, _}  ->  {?ok, NewPlayer};
                         {?true, NewPlayer}  ->  {?ok, NewPlayer}
                     end;
                {?error, ErrorCode} ->  % 退出
                    Packet  = message_api:msg_notice(ErrorCode),
                    misc_packet:send(Player#player.net_pid, Packet),
                    update_player_team_cb(Player, {0, 0})
            end
    end.
%%         
%% 
%%         
%%         
%% 		0	->% 无资格进入组队大厅
%% 			{?error, ?TIP_TEAM_NOT_TEAM_PLAY};
%% 		TeamType	->
%% 			{
%% 			 _EtsTeamId, EtsTeamHall, _EtsTeamInfo, _EtsTeamPlayer, EtsTeamExt
%% 			}			= team_ets(TeamType),
%% 			% 退出大厅
%% 			ets_api:delete(EtsTeamHall, Player#player.user_id),
%% 			ets_ext_delete(EtsTeamExt, Player#player.user_id),
%% 
%% 			% 大厅广播(协议18502:角色退出大厅通知)
%% 			Packet18502	= msg_sc_quit_hall_notice(TeamType, Player#player.user_id),
%% 			broadcast_hall_broadcast(TeamType, Packet18502, EtsTeamHall),
%% 			case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
%% 				{?false, NewPlayer, _}	->	{?ok, NewPlayer};
%% 				{?true, NewPlayer}	->	{?ok, NewPlayer}
%% 			end
%% 	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 快速加入
quick_join(Player, TeamType, TeamId, Id, Password) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
	}		= team_ets(TeamType),
	case check_quick_join(Player, EtsTeamInfo, EtsTeamPlayer, TeamId, Id, Password) of
		{?ok, TeamTmp} ->
			PlayState	= case TeamType of
							  ?CONST_TEAM_TYPE_COPY -> ?CONST_PLAYER_PLAY_MULTI_COPY;
							  ?CONST_TEAM_TYPE_INVASION -> ?CONST_PLAYER_PLAY_INVASION;
							  ?CONST_TEAM_TYPE_ARENA -> ?CONST_PLAYER_PLAY_MULTI_ARENA
						  end,
			case player_state_api:try_set_state_play(Player, PlayState) of
				{?true, Player2} ->
					TeamHall	= team_mod:record_team_hall(Player2),
					ets_ext_insert(EtsTeamExt, TeamHall),
					TeamPlayer	= team_mod:record_team_player(Player2, ?CONST_TEAM_PLAYER_STATE_WAIT),
					case team_serv:quick_join_call(TeamTmp#team.team_pid, TeamPlayer) of
						?ok ->
							ets_api:insert(EtsTeamPlayer, TeamPlayer),
							{?ok, Team}	= get_team(EtsTeamInfo, TeamId),
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
							Packet18502 = team_api:msg_sc_quit_hall_notice(TeamType, TeamPlayer#team_player.uid),
							Packet18510	= team_api:msg_sc_team_insert_notice(Team),
							team_api:broadcast_hall(TeamType, <<Packet18502/binary, Packet18510/binary>>, EtsTeamHall),
							% 
							update_player_team(Team, Team#team.team_id, Team#team.leader_uid),
							update_player_team_cb(Player2, {Team#team.team_id, Team#team.leader_uid});
						{?error, ErrorCode} ->
							{?error, ErrorCode}
					end;
				{?false, _Player2, Tips} -> {?error, Tips}
			end;
		{?error, ErrorCode} -> {?error, ErrorCode}
	end.
check_quick_join(Player, EtsTeamInfo, EtsTeamPlayer, TeamId, Id, Password) ->
	try
		case team_api:get_team(EtsTeamInfo, TeamId) of
			{?ok, Team = #team{param = #team_param{id = Id}}} ->
				?ok			= team_mod:check_team_state(Team),
				?ok			= check_have_team(Player),
				?ok			= team_mod:check_team_num(Team),
				?ok			= team_mod:check_password(Team, Password),
				case team_mod:check_have_team(EtsTeamPlayer, Player#player.user_id) of
					{?true, _TeamPlayer} -> {?error, ?TIP_TEAM_ALREADY_IN_TEAM};
					{?false, ?null} ->
						TeamParam	= Team#team.param,
						case check_team_play(Player, Team#team.type, TeamParam#team_param.id, ?CONST_TEAM_CHECK_CREATE) of
							{?ok, _TeamParam} -> {?ok, Team};
							{?error, ErrorCode} -> {?error, ErrorCode}
						end
				end;
			{?ok, _Team} -> {?error, ?TIP_TEAM_NO_THIS_TEAM};
			{?error, ErrorCode} -> {?error, ErrorCode}
		end
	catch
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lock_and_unlock(Player, Password) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_COMMON_BAD_ARG};
		TeamType ->
			{
			 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
			case check_lock_and_unlock(Player, EtsTeamInfo, Password) of
				{?ok, TeamTmp} ->
					case team_serv:lock_and_unlock_call(TeamTmp#team.team_pid, Password) of
						?ok ->
							{?ok, Team}	= get_team(EtsTeamInfo, TeamTmp#team.team_id),
							% 队伍广播队伍详细信息(协议18530:队伍详细信息)
							PacketTeam	= team_api:msg_sc_info(Team, EtsTeamPlayer),
							team_api:broadcast_team(Team, PacketTeam),
							% 大厅广播(协议18502:角色退出大厅通知|协议18510:插入队伍信息)
							Packet18510	= team_api:msg_sc_team_insert_notice(Team),
							team_api:broadcast_hall(TeamType, Packet18510, EtsTeamHall),
							?ok;
						{?error, ErrorCode} -> {?error, ErrorCode}
					end;
				{?error, ErrorCode} -> {?error, ErrorCode}
			end
	end.
check_lock_and_unlock(Player, EtsTeamInfo, Password) ->
	try
		?ok 		= check_have_no_team(Player),
		{?ok, Team}	= team_mod:check_team_exist(EtsTeamInfo, Player#player.team_id),
		?ok			= team_mod:check_leader(Team, Player#player.user_id),
		if
			Team#team.lock =:= <<"">> andalso Password =/= <<"">> -> {?ok, Team};
			Team#team.lock =/= <<"">> andalso Password =:= <<"">> -> {?ok, Team};
			?true -> {?error, ?TIP_COMMON_BAD_ARG}
		end
	catch
		throw:{?error, ?TIP_TEAM_NO_CAMP} -> {?error, ?TIP_TEAM_NO_CAMP_SET_CAMP};
		throw:Return -> Return;
		_:_ -> {?error, ?TIP_COMMON_BAD_ARG}% 未知错误
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 玩法结束清理
%% team_api:player_over_clean(TeamType).
%% TeamType:详见常量	CONST_TEAM_TYPE_*
player_over_clean(TeamType) ->
	{
	 _EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
	}			= team_ets(TeamType),
	player_over_clean_team(TeamType, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt),
	player_over_clean_hall(TeamType, EtsTeamHall, EtsTeamExt),
	?ok.

player_over_clean_team(TeamType, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt) ->
	TeamList	= ets_api:list(EtsTeamInfo),
	Packet18526 = team_api:msg_sc_quit_notice(2),
	Packet18540	= 
		case TeamType of
			?CONST_TEAM_TYPE_INVASION -> <<>>; %% 异民族结束时不主动发18540
			_ -> msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_NORMAL)
		end,
	Packet		= <<Packet18526/binary, Packet18540/binary>>,
	[player_over_clean_team(Team, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet) || Team <- TeamList].

player_over_clean_team_cross(Team, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet) ->
    ets_api:delete(EtsTeamInfo, Team#team.team_id),
    team_serv:destroy_cast(Team#team.team_pid),
    Position    = misc:to_list((Team#team.camp)#camp.position),
    Fun         = fun(UserId) ->
                          case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                              [] ->
                                  player_api:process_send(UserId, ?MODULE, player_over_clean_team_cb,
                                                          {EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet});
                              [CrossRec] ->
                                  Node = CrossRec#cross_in.node,
                                  rpc:cast(Node, player_api, process_send, [UserId, ?MODULE, player_over_clean_team_cb,
                                                          {EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet}])
                          end
                  end,
    [Fun(UserId) || #camp_pos{id = UserId} <- Position],
    ets_api:delete(EtsTeamInfo, Team#team.team_id).

player_over_clean_team(Team, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet)
  when Team#team.state =:= ?CONST_TEAM_STATE_WAIT orelse
	   (Team#team.type =:= ?CONST_TEAM_TYPE_ARENA andalso Team#team.state =:= ?CONST_TEAM_STATE_START) ->
	ets_api:delete(EtsTeamInfo, Team#team.team_id),
	team_serv:destroy_cast(Team#team.team_pid),
	Position	= misc:to_list((Team#team.camp)#camp.position),
	Fun			= fun(UserId) ->
						  player_api:process_send(UserId, ?MODULE, player_over_clean_team_cb,
												  {EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet})
				  end,
	[Fun(UserId) || #camp_pos{id = UserId} <- Position],
	ets_api:delete(EtsTeamInfo, Team#team.team_id);
player_over_clean_team(_Team, _EtsTeamHall, _EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt, _Packet) -> ?ok.

player_over_clean_team_cb(Player, {EtsTeamHall, _EtsTeamInfo, EtsTeamPlayer, EtsTeamExt, Packet}) ->
	ets_api:delete(EtsTeamPlayer, Player#player.user_id),
	ets_api:delete(EtsTeamHall, Player#player.user_id),
	ets_ext_delete(EtsTeamExt, Player#player.user_id),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player2}	= update_player_team_cb(Player, {0, 0}),
	{_, Player3}	= player_state_api:try_set_state_play(Player2, ?CONST_PLAYER_PLAY_CITY),
	{_, Player4}	= player_state_api:try_set_state(Player3, ?CONST_PLAYER_STATE_NORMAL),
	{?ok, Player4}.


player_over_clean_hall(TeamType, EtsTeamHall, EtsTeamExt) ->
	List		= ets_api:list(EtsTeamHall),
	Packet18540	= msg_sc_quit_play_to(TeamType, ?CONST_TEAM_QUIT_TO_NORMAL),
	[player_api:process_send(UserId, ?MODULE, player_over_clean_hall_cb, {EtsTeamHall, EtsTeamExt, Packet18540}) || #team_hall{uid = UserId} <- List].

player_over_clean_hall_cb(Player, {EtsTeamHall, EtsTeamExt, Packet18540}) ->
	ets_api:delete(EtsTeamHall, Player#player.user_id),
	ets_ext_delete(EtsTeamExt, Player#player.user_id),
	misc_packet:send(Player#player.net_pid, Packet18540),
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?false, NewPlayer, _}	->	{?ok, NewPlayer};
		{?true, NewPlayer}	->	{?ok, NewPlayer}
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
team_type(Player) when is_record(Player, player) ->
	{_UserState, _, PlayState}	= player_state_api:get_state(Player),
	team_type(PlayState);
team_type(?CONST_PLAYER_PLAY_MULTI_COPY) 	-> ?CONST_TEAM_TYPE_COPY;
team_type(?CONST_PLAYER_PLAY_INVASION) 		-> ?CONST_TEAM_TYPE_INVASION;
team_type(?CONST_PLAYER_PLAY_MULTI_ARENA) 	-> ?CONST_TEAM_TYPE_ARENA;
team_type(_) -> 0.


refresh_exit_guild_author(UserId, GuildId) ->
    refresh_exit_guild_author(UserId, GuildId, 1),
    refresh_exit_guild_author(UserId, GuildId, 2).

refresh_exit_guild_author(UserId, GuildId, Type) ->
    SelfAuthur = ets_get_authoer(UserId, Type),
    IsGuildAll = SelfAuthur#team_author.is_guild_all,
    GuildMembers = guild_api:get_guild_members(GuildId),
    Fun = 
        fun({Id, _, _}) ->
                AuthorRec = ets_get_authoer(Id, Type),
                AuthorToList = 
                    case AuthorRec#team_author.team_to of
                        ?undefined ->
                            [];
                        AuthorToList1 ->
                            AuthorToList1
                    end,
                case is_list(AuthorToList) of
                    true ->
                        case AuthorRec#team_author.is_guild_all andalso not lists:member(UserId, AuthorToList) of
                            true ->
                                sub_author_from(UserId, Id, Type);
                            _ ->
                                ok
                        end,
                        case IsGuildAll andalso not lists:member(Id, SelfAuthur#team_author.team_to) of
                            true ->
                                sub_author_from(Id, UserId, Type);
                            _ ->
                                ok
                        end;
                    _ ->
                        ok
                end
        end,
    lists:foreach(Fun, GuildMembers).

refresh_enter_guild_author(UserId, GuildId) ->
    refresh_enter_guild_author(UserId, GuildId, 1),
    refresh_enter_guild_author(UserId, GuildId, 2).

refresh_enter_guild_author(UserId, GuildId, Type) ->
    SelfAuthur = ets_get_authoer(UserId, Type),
    IsGuildAll = SelfAuthur#team_author.is_guild_all,
    GuildMembers = guild_api:get_guild_members(GuildId),
    Fun = 
        fun({Id, _, _}) ->
                AuthorRec = ets_get_authoer(Id, Type),
                case AuthorRec#team_author.is_guild_all of
                    true ->
                        add_author_from(UserId, Id, Type);
                    _ ->
                        ok
                end,
                case IsGuildAll andalso not lists:member(Id, SelfAuthur#team_author.team_to) of
                    true ->
                        add_author_from(Id, UserId, Type);
                    _ ->
                        ok
                end
        end,
    lists:foreach(Fun, GuildMembers).
                
add_invited_times(UserId, TeamType) ->
    case ets:lookup(?CONST_ETS_TEAM_AUTHOR, {UserId, TeamType}) of
        [] ->
            Rec = get_Author_item(UserId, TeamType),
            ets:insert(?CONST_ETS_TEAM_AUTHOR, Rec);
        [Rec] ->
            ok
    end,
    LastTime = Rec#team_author.last_add_count_time,
    Now = misc:seconds(),
    case misc:is_same_date(LastTime, Now) of
        false ->
            Count = 1;
        _ ->
            Count = Rec#team_author.times + 1
    end,
    ets:update_element(?CONST_ETS_TEAM_AUTHOR, {UserId, TeamType}, [{#team_author.last_add_count_time, Now}, {#team_author.times, Count}]).

up_cd_ets(LeaderId, AuthorList, TeamType) ->
    Now = misc:seconds(),
    Fun =
        fun(#team_player{uid = Id, is_gold_author = IsGoldAuthor}) ->
                case IsGoldAuthor of
                    true ->
                        ok;
                    _ ->
                        ets:insert(?CONST_ETS_TEAM_INVITE_CD, #team_invite_cd{key = {LeaderId, Id, TeamType}, last_invite_time = Now}),
                        add_invited_times(Id, TeamType)
                end
        end,
    lists:foreach(Fun, AuthorList).

get_gold_invite_cost(AuthorList) ->
    get_gold_invite_cost(AuthorList, 0).
get_gold_invite_cost([], Sum) ->
    Sum;
get_gold_invite_cost([TeamPlayer|RestList], Sum) ->
    case TeamPlayer#team_player.is_gold_author of
        true ->
            get_gold_invite_cost(RestList, Sum + 20);
        _ ->
            get_gold_invite_cost(RestList, Sum)
    end.

check_enter_map(Player) when is_record(Player, player) ->
    TeamType    = team_api:team_type(Player),
    check_enter_map(TeamType, Player#player.team_id).

check_enter_map(TeamType, Team) when is_record(Team, team) ->
	List		= misc:to_list((Team#team.camp)#camp.position),
    AuthorList = Team#team.author_list,
    CrossList = Team#team.cross_list,
	UserIds		= check_enter_map({AuthorList, CrossList}, TeamType, List, Team#team.leader_uid, []),
	{?ok, Team#team.operate_mode, UserIds};
          


check_enter_map(TeamType, TeamId) when TeamType =/= 0 andalso TeamId =/= 0 ->
	{_EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt} = team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} -> check_enter_map(TeamType, Team);
		_ -> ?null
	end;
check_enter_map(_, _) -> ?null.

check_enter_map(AuthorList, TeamType, [#camp_pos{id = LeaderUid}|List], LeaderUid, AccUserId) ->
	check_enter_map(AuthorList, TeamType,List, LeaderUid, AccUserId);
check_enter_map(AuthorList, TeamType,[#camp_pos{id = UserId}|List], LeaderUid, AccUserId) ->
    Type = get_member_type(AuthorList, TeamType, UserId),
	check_enter_map(AuthorList, TeamType,List, LeaderUid, [{Type, UserId}|AccUserId]);
check_enter_map(AuthorList, TeamType,[_CampPos|List], LeaderUid, AccUserId) ->
	check_enter_map(AuthorList, TeamType,List, LeaderUid, AccUserId);
check_enter_map({_AuthorList, _CrossList}, _TeamType, [], LeaderUid, AccUserId) -> 
    [{?CONST_MAP_PTYPE_HUMAN,LeaderUid}|AccUserId].

get_member_type({AuthorList, CrossList}, TeamType, UserId) ->
    case lists:keymember(UserId, #team_player.uid, AuthorList) of
        false ->
            case lists:keyfind(UserId, #team_player.uid, CrossList) of
                false ->
                    ?CONST_MAP_PTYPE_HUMAN;
                _TeamPlayer ->
                    ?CONST_MAP_PTYPE_HUMAN
            end;
        _ ->
            case TeamType of
                ?CONST_TEAM_TYPE_COPY ->
                    ?CONST_MAP_PTYPE_COPY_ROBOT;
                _ ->
                    ?CONST_MAP_PTYPE_INV_ROBOT
            end
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_team(#player{play_state = PlayState, team_id = TeamId}) ->
	get_team(PlayState, TeamId).

get_team(PlayState, TeamId) when is_number(PlayState) ->
	case team_api:team_type(PlayState) of
		0 -> {?error, ?TIP_TEAM_NO_THIS_TEAM}; % 队伍不存在
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
			}	= team_api:team_ets(TeamType),
			get_team(EtsTeamInfo, TeamId)
	end;

get_team(EtsTeamInfo, {TeamId, Index}) when is_atom(EtsTeamInfo) ->
    NodeFrom = cross_api:get_node(Index),
    case rpc:call(NodeFrom, ets_api, lookup, [EtsTeamInfo, TeamId]) of
        Team when is_record(Team, team) -> {?ok, Team};
        _ -> {?error, ?TIP_TEAM_NO_THIS_TEAM} % 队伍不存在
    end;

get_team(EtsTeamInfo, {NodeFrom, TeamId}) when is_atom(EtsTeamInfo) ->
    case rpc:call(NodeFrom, ets_api, lookup, [EtsTeamInfo, TeamId]) of
        Team when is_record(Team, team) -> {?ok, Team};
        _ -> {?error, ?TIP_TEAM_NO_THIS_TEAM} % 队伍不存在
    end;

get_team(EtsTeamInfo, TeamId) when is_atom(EtsTeamInfo) ->
	case ets_api:lookup(EtsTeamInfo, TeamId) of
		Team when is_record(Team, team) -> {?ok, Team};
		_ -> {?error, ?TIP_TEAM_NO_THIS_TEAM} % 队伍不存在
	end.

get_team_uids(TeamType, TeamId) when 0 =/= TeamType andalso 0 =/= TeamId ->
	{_EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt} = team_ets(TeamType),
	case team_api:get_team(EtsTeamInfo, TeamId) of
		{?ok, Team} -> get_team_uids(Team);
		_ -> []
	end;
get_team_uids(_, _) -> [].

get_team_uids(Team) when is_record(Team, team) ->
	List		= misc:to_list((Team#team.camp)#camp.position),
	get_team_uids(List, Team#team.leader_uid, []);
get_team_uids(Player) when is_record(Player, player) ->
	TeamType	= team_api:team_type(Player),
	get_team_uids(TeamType, Player#player.team_id).
 
get_team_uids([#camp_pos{id = LeaderUid}|List], LeaderUid, AccUserId) ->
	get_team_uids(List, LeaderUid, AccUserId);
get_team_uids([#camp_pos{id = UserId}|List], LeaderUid, AccUserId) ->
	get_team_uids(List, LeaderUid, [UserId|AccUserId]);
get_team_uids([_CampPos|List], LeaderUid, AccUserId) ->
	get_team_uids(List, LeaderUid, AccUserId);
get_team_uids([], LeaderUid, AccUserId) -> [LeaderUid|AccUserId].% 不是队伍成员

%% {?ok, Player, Camp, CampAttr}
get_team_camp(Player) when is_record(Player, player) ->
	TeamType	= team_api:team_type(Player),
	{_EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt} = team_ets(TeamType),
    Camp = 
    	case team_api:get_team(EtsTeamInfo, Player#player.team_id) of
    		{?ok, Team} -> Team#team.camp;
    		_ -> camp_api:default_camp()
    	end,
    CampAttr = camp_api:camp_attr_ext(Camp#camp.camp_id, Camp#camp.lv),
    {?ok, Player, Camp, CampAttr}.

get_team_id([UserId | UserIdList])	->
	case battle_cross_api:get_player_fields(UserId, [#player.team_id]) of
        {?ok, [{TeamId, _}]} ->
            case player_api:check_online(UserId) of
                ?true -> TeamId;
                ?false -> 
                    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                        [] ->
                            get_team_id(UserIdList);
                        _ ->
                            TeamId
                    end
            end;
		{?ok, [TeamId]} ->
			case player_api:check_online(UserId) of
				?true -> TeamId;
				?false -> 
                    case ets:lookup(?CONST_ETS_CROSS_IN, UserId) of
                        [] ->
                            get_team_id(UserIdList);
                        _ ->
                            TeamId
                    end
			end;
		_Other	-> get_team_id(UserIdList)
	end;
get_team_id([])	->	0.

%% 队伍平均等级
%% team_api:get_team_lv(TeamType, TeamId).
get_team_lv(TeamType, TeamId) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_ets(TeamType),
	case ets_api:lookup(EtsTeamInfo, TeamId) of
		Team when is_record(Team, team) ->
			Team#team.avg_lv;
		_ -> 0
	end.

%% 获取多人竞技场可以战斗的队伍列表
%% 返回:[{TeamId, LeaderUid, AvgLv},...]
%% team_api:get_arena_team().
get_arena_team() ->
	MatchSpec	= ets:fun2ms(fun(#team{state 		= ?CONST_TEAM_STATE_START,
									   team_id 		= TeamId,
									   leader_uid 	= LeaderUid,
									   avg_lv		= AvgLv}) ->
									 {TeamId, LeaderUid, AvgLv}
							 end),
	ets_api:select(?CONST_ETS_TEAM_INFO_ARENA, MatchSpec).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 大厅广播
broadcast_hall(_TeamType, <<>>) -> ?ok;
broadcast_hall(TeamType, Packet) ->
	{
	 _EtsTeamId, EtsTeamHall, _EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_ets(TeamType),
	broadcast_hall(TeamType, Packet, EtsTeamHall).

broadcast_hall(_TeamType, <<>>, _EtsTeamHall) -> ?ok;
broadcast_hall(_TeamType, Packet, EtsTeamHall) ->
	List		= ets_api:list(EtsTeamHall),
	[misc_packet:send(UserId, Packet) || #team_hall{uid = UserId} <- List],
	?ok.


get_team_id_list(TeamType, TeamId) ->
    {
     _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
    } = team_ets(TeamType),
    case ets:lookup(EtsTeamInfo, TeamId) of
        [] ->
            ok;
        [Team] ->
            List = misc:to_list((Team#team.camp)#camp.position),
            FilterFun =
                fun(CampPos) ->
                        is_record(CampPos, camp_pos)
                end,
            RecList = lists:filter(FilterFun, List),
            Format =
                fun(Rec) ->
                        Rec#camp_pos.id
                end,
            lists:map(Format, RecList)
    end. 
    

broadcast_team(ServId, Team, Packet) when is_record(Team, team) ->
    List    = misc:to_list((Team#team.camp)#camp.position),
    AuthorList = Team#team.author_list,
    CrossList = Team#team.cross_list,
    Fun     = fun(CampPos) when is_record(CampPos, camp_pos)->
                      Id = CampPos#camp_pos.id,
                      case lists:keyfind(Id, #team_player.uid, AuthorList) of
                          false ->
                              case lists:keyfind(Id, #team_player.uid, CrossList) of
                                  false ->
                                      TeamFrom = cross_api:get_node(ServId),
                                      rpc:cast(TeamFrom, misc_packet, send, [Id, Packet]);
                                  TeamRec ->
                                      TeamFrom = cross_api:get_node(TeamRec#team_player.index_from),
                                      rpc:cast(TeamFrom, misc_packet, send, [Id, Packet])
                              end;
                          _ ->
                              ok
                      end;
                 (_) -> ?ok
              end,
    lists:foreach(Fun, List);
%% 队伍广播
broadcast_team(_TeamType, _TeamId, <<>>) -> ?ok;
broadcast_team(TeamType, TeamId, Packet) ->
	{
	 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_ets(TeamType),
	case ets_api:lookup(EtsTeamInfo, TeamId) of
		Team when is_record(Team, team) ->
			broadcast_team(Team, Packet);
		_ -> ?ok
	end.


broadcast_team(_Team, <<>>) -> ?ok;
broadcast_team(Team, Packet) when is_record(Team, team) ->
	List	= misc:to_list((Team#team.camp)#camp.position),
    AuthorList = Team#team.author_list,
	Fun		= fun(CampPos) when is_record(CampPos, camp_pos)->
                      case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, AuthorList) of
                          false ->
                              case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, Team#team.cross_list) of
                                  false ->
					                   misc_packet:send(CampPos#camp_pos.id, Packet);
                                  TeamPlayer ->
                                      IndexFrom = TeamPlayer#team_player.index_from,
                                      NodeFrom = cross_api:get_node(IndexFrom),
                                      rpc:cast(NodeFrom, misc_packet, send, [CampPos#camp_pos.id, Packet])
                              end;
                          _ ->
                              ok
                      end;
				 (_) -> ?ok
			  end,
	lists:foreach(Fun, List);
broadcast_team(Player, Packet) when is_record(Player, player) ->
	case team_type(Player) of
		0 ->% 未在组队玩法中，无资格操作
			{?error, ?TIP_COMMON_BAD_ARG};
		TeamType ->
			{
			 _EtsTeamId, _EtsTeamHall, EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
			}		= team_ets(TeamType),
            case Player#player.team_id of
                {TeamId, ServId} ->
                    Node = cross_api:get_node(ServId),
                    rpc:cast(Node, ?MODULE, broadcast_team, [TeamType, TeamId, Packet]);
                _ ->
        			case team_api:get_team(EtsTeamInfo, Player#player.team_id) of
        				{?ok, Team} ->
        					broadcast_team(Team, Packet);
        				_ -> {?error, ?TIP_TEAM_NO_THIS_TEAM}
        			end
            end
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 检查玩法是否满足要求(组队玩法模块实现check_team_play(Player, Id)方法需返回：{?ok, TeamParam}|{?error, ErrorCode})
check_team_play(UserId, TeamType, Id, Type) when is_number(UserId) ->
	case player_api:process_call(UserId, ?MODULE, check_team_play_cb, [TeamType, Id, Type]) of
		?false -> {?error, ?TIP_TEAM_PLAYER_OFFLINE};
		Result -> Result
	end;
check_team_play(Player, ?CONST_TEAM_TYPE_COPY, Id, Type) ->
	case mcopy_api:check_team_play(Player, Id, Type) of
		?ok 				-> {?ok, #team_param{id = Id, count_max = ?CONST_TEAM_MAX_MEMBER}};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
check_team_play(Player, ?CONST_TEAM_TYPE_INVASION, Id, Type) ->
	case invasion_api:check_team_play(Player, Id, Type) of
		{?ok, Id, Amount}	-> {?ok, #team_param{id = Id, count_max	= Amount}};
		{?error, ErrorCode}	-> {?error, ErrorCode}
	end;
check_team_play(Player, ?CONST_TEAM_TYPE_ARENA, Id, Type) ->
	case arena_pvp_api:check_team_play(Player,Type) of
		?ok					-> {?ok, #team_param{id = Id, count_max = ?CONST_TEAM_MAX_MEMBER}};
		{?error, ErrorCode}	-> {?error, ErrorCode}
	end.

check_team_play_cb(Player, [TeamType, Id, Type]) ->
	Reply	= check_team_play(Player, TeamType, Id, Type),
	{?ok, Reply, Player}.

%% 检查某个角色是否已经有队伍
check_have_team(Player) when is_record(Player, player) ->
	case Player#player.team_id of
		0 -> ?ok;
		_ -> throw({?error, ?TIP_TEAM_ALREADY_IN_TEAM})% 已有队伍
	end.

%% 检查某个角色是否已经有队伍
check_have_no_team(Player) when is_record(Player, player) ->
	case Player#player.team_id of
		0 -> throw({?error, ?TIP_TEAM_NO_IN});
		_ -> ?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% team_api:team_sup_name(1).
team_sup_name(TeamType) ->
	misc:to_atom("team_sup_" ++ misc:to_list(TeamType)).

team_ets(?CONST_TEAM_TYPE_COPY) ->
	{?CONST_ETS_TEAM_ID_COPY, ?CONST_ETS_TEAM_HALL_COPY, ?CONST_ETS_TEAM_INFO_COPY, ?CONST_ETS_TEAM_PLAYER_COPY, ?null};
team_ets(?CONST_TEAM_TYPE_INVASION) ->
	{?CONST_ETS_TEAM_ID_INVASION, ?CONST_ETS_TEAM_HALL_INVASION, ?CONST_ETS_TEAM_INFO_INVASION, ?CONST_ETS_TEAM_PLAYER_INVASION, ?null};
team_ets(?CONST_TEAM_TYPE_ARENA) ->
	{?CONST_ETS_TEAM_ID_ARENA, ?CONST_ETS_TEAM_HALL_ARENA, ?CONST_ETS_TEAM_INFO_ARENA, ?CONST_ETS_TEAM_PLAYER_ARENA, ?CONST_ETS_TEAM_EXT_ARENA}.

%% 开服初始化组队ETS
init_tesm_ets(TeamType) ->
	{
	 EtsTeamId, EtsTeamHall, EtsTeamInfo, EtsTeamPlayer, EtsTeamExt
	}			= team_api:team_ets(TeamType),
	ets_api:new(EtsTeamId, 		1),
	ets_api:insert(EtsTeamId,	{TeamType, 1}),
	ets_api:new(EtsTeamHall, 	#team_hall.uid),
	ets_api:new(EtsTeamInfo, 	#team.team_id),
	ets_api:new(EtsTeamPlayer, 	#team_player.uid),
	team_api:ets_ext_new(EtsTeamExt),
	?ok.

%% 生成队伍ID
generate_team_id(TeamType) ->
	{
	 EtsTeamId, _EtsTeamHall, _EtsTeamInfo, _EtsTeamPlayer, _EtsTeamExt
	}			= team_api:team_ets(TeamType),
	ets_api:update_counter(EtsTeamId, TeamType, {2, 1, 65535, 1}).

ets_ext_new(?null) -> ?ok;
ets_ext_new(EtsTeamExt) ->
	ets_api:new(EtsTeamExt, #team_hall.uid).
ets_ext_insert(?null, _TeamHall) -> ?ok;
ets_ext_insert(EtsTeamExt, TeamHall) ->
	ets_api:insert(EtsTeamExt, TeamHall).
ets_ext_delete(?null, _UserId) -> ?ok;
ets_ext_delete(EtsTeamExt, UserId) ->
	ets_api:delete(EtsTeamExt, UserId).


%% 通知队伍成员更新队伍ID及队长ID
update_player_team(Team, TeamId, LeaderId) ->
	List	= misc:to_list((Team#team.camp)#camp.position),
	update_player_team2(Team, List, TeamId, LeaderId).
update_player_team2(Team, [#camp_pos{id = UserId}|UserIdList], TeamId, LeaderId) ->
    case is_author(Team, UserId) of
        false ->
            case lists:keyfind(UserId, #team_player.uid, Team#team.cross_list) of
                false ->
	               update_player_team(UserId, {TeamId, LeaderId});
                TeamPlayer ->
                    FromIndex = TeamPlayer#team_player.index_from,
                    Node = cross_api:get_node(FromIndex),
                    TeamKey = 
                        case TeamId of
                            0 ->
                                0;
                            _ ->
                                {TeamId, cross_api:get_self_index()}
                        end,
                    rpc:cast(Node, ?MODULE, update_player_team, [UserId, {TeamKey, LeaderId}])
            end;
        _ ->
            ok
    end,
	update_player_team2(Team, UserIdList, TeamId, LeaderId);
update_player_team2(Team, [?CONST_SYS_FALSE|UserIdList], TeamId, LeaderId) ->
	update_player_team2(Team, UserIdList, TeamId, LeaderId);
update_player_team2(Team, [?CONST_SYS_TRUE|UserIdList], TeamId, LeaderId) ->
	update_player_team2(Team, UserIdList, TeamId, LeaderId);
update_player_team2(_Team, [], _TeamId, _LeaderId) -> ?ok.
%% 通知角色更新队伍ID
update_player_team(UserId, Data) ->
	player_api:process_send(UserId, ?MODULE, update_player_team_cb, Data).
update_player_team_cb(Player, {TeamId, LeaderId}) ->
	Player2		= Player#player{team_id = TeamId, leader = LeaderId},
	map_api:change_team(Player2),
    {?ok, Player2}.

%% 获取机器人列表
get_robot_list(Type, TeamId) ->
	case get_team(Type, TeamId) of
		{?ok, Team} ->
			List	= Team#team.author_list,
			[X#team_player.uid || X <- List];
		_ ->
			[]
	end.

%%
%% Local Functions
%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 进入组队大厅[18400]
msg_sc_enter_hall() ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_ENTER_HALL, ?MSG_FORMAT_TEAM2_SC_ENTER_HALL, []).

%% 角色进入大厅通知[18500]
msg_sc_enter_hall_notice(?CONST_TEAM_TYPE_COPY, _TeamHall) -> <<>>;
msg_sc_enter_hall_notice(?CONST_TEAM_TYPE_INVASION, _TeamHall) -> <<>>;
msg_sc_enter_hall_notice(?CONST_TEAM_TYPE_ARENA, TeamHall) ->
	Datas	= [
			   TeamHall#team_hall.uid,
			   TeamHall#team_hall.name,
			   TeamHall#team_hall.pro,
			   TeamHall#team_hall.sex,
			   TeamHall#team_hall.lv
			  ],
	misc_packet:pack(?MSG_ID_TEAM2_SC_ENTER_HALL_NOTICE,
					 ?MSG_FORMAT_TEAM2_SC_ENTER_HALL_NOTICE,
					 Datas).

%% 角色退出大厅通知[18502]
msg_sc_quit_hall_notice(?CONST_TEAM_TYPE_COPY, _UserId) -> <<>>;
msg_sc_quit_hall_notice(?CONST_TEAM_TYPE_INVASION, _UserId) -> <<>>;
msg_sc_quit_hall_notice(?CONST_TEAM_TYPE_ARENA, UserId) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_QUIT_HALL_NOTICE,
					 ?MSG_FORMAT_TEAM2_SC_QUIT_HALL_NOTICE,
					 [UserId]).

%% 插入队伍信息[18510]
msg_sc_team_insert_notice(Team) ->
	Datas	= [
			   Team#team.team_id,
			   Team#team.type,
			   Team#team.state,
			   Team#team.leader_name,
			   Team#team.leader_pro,
			   Team#team.leader_sex,
			   Team#team.leader_lv,
			   Team#team.count,
			   (Team#team.param)#team_param.id,
			   Team#team.lock
			  ],
	misc_packet:pack(?MSG_ID_TEAM2_SC_TEAM_INSERT_NOTICE,
					 ?MSG_FORMAT_TEAM2_SC_TEAM_INSERT_NOTICE,
					 Datas).
%% 删除队伍通知[18512]
msg_sc_team_delete_notice(TeadId) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_TEAM_DELETE_NOTICE,
					 ?MSG_FORMAT_TEAM2_SC_TEAM_DELETE_NOTICE,
					 [TeadId]).

%% 邀请组队通知[18520]
msg_sc_invite_notice(TeamType,TeamId,Id,Name,Lv,Power,Vip) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_INVITE_NOTICE,
					 ?MSG_FORMAT_TEAM2_SC_INVITE_NOTICE,
					 [TeamType,TeamId,Id,Name,Lv,Power,Vip]).

%% 移除邀请组队通知
msg_sc_remove_invite(TeamId) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_REMOVE_INVITE, ?MSG_FORMAT_TEAM2_SC_REMOVE_INVITE, [TeamId]).

%% 退出队伍通知[18526]
msg_sc_quit_notice(Reason) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_QUIT_NOTICE, ?MSG_FORMAT_TEAM2_SC_QUIT_NOTICE, [Reason]).

%% 队伍详细信息[18530]
msg_sc_info(Team, EtsTeamPlayer) ->
	List		= misc:to_list((Team#team.camp)#camp.position),
    AuthorList = Team#team.author_list,
    CrossList = Team#team.cross_list,
    Index = cross_api:get_self_index(),
    Fun =
       fun(CampPos, {Idx, Acc}) when is_record(CampPos, camp_pos)->
          case lists:keyfind(CampPos#camp_pos.id, #team_player.uid, AuthorList ++ CrossList) of
              false ->
                  case ets_api:lookup(EtsTeamPlayer, CampPos#camp_pos.id) of
                      TeamPlayer when is_record(TeamPlayer, team_player) ->
                          SkinFashion   = case TeamPlayer#team_player.hide_fashion of
                                              ?CONST_SYS_TRUE -> 0;
                                              ?CONST_SYS_FALSE -> TeamPlayer#team_player.skin_fashion
                                          end,
                          Data  = {
                                   TeamPlayer#team_player.uid,TeamPlayer#team_player.state, Idx,
                                   TeamPlayer#team_player.name,TeamPlayer#team_player.pro,
                                   TeamPlayer#team_player.sex,TeamPlayer#team_player.lv,
                                   TeamPlayer#team_player.position, TeamPlayer#team_player.power,
                                   SkinFashion,TeamPlayer#team_player.skin_weapon,
                                   TeamPlayer#team_player.skin_armor,?CONST_TEAM_NOT_AUTHOR,Index,
                                   TeamPlayer#team_player.partners
                                  },
                          {Idx + 1, [Data|Acc]};
                      _ ->
                          {Idx + 1, Acc}
                 end;
              TeamPlayer ->
                  AuthorType = 
                      case TeamPlayer#team_player.is_gold_author of
                          true ->
                              ?CONST_TEAM_GOLD_AUTHOR;
                          _ ->
                              ?CONST_TEAM_NORMAL_AUTHOR
                      end,
                  SkinFashion   = case TeamPlayer#team_player.hide_fashion of
                                      ?CONST_SYS_TRUE -> 0;
                                      ?CONST_SYS_FALSE -> TeamPlayer#team_player.skin_fashion
                                  end,
                  CrossIndex = 
                      case lists:keymember(TeamPlayer#team_player.uid, #team_player.uid, CrossList) of
                          false ->
                              Index;
                          _ ->
                              TeamPlayer#team_player.index_from
                      end,
                  Data  = {
                           TeamPlayer#team_player.uid,TeamPlayer#team_player.state,
                           Idx,TeamPlayer#team_player.name,TeamPlayer#team_player.pro,
                           TeamPlayer#team_player.sex, TeamPlayer#team_player.lv,
                           TeamPlayer#team_player.position,TeamPlayer#team_player.power,
                           SkinFashion,TeamPlayer#team_player.skin_weapon,
                           TeamPlayer#team_player.skin_armor, AuthorType,CrossIndex,TeamPlayer#team_player.partners
                          },
                  {Idx + 1, [Data|Acc]}
          end;
          (_, {Idx, Acc}) -> {Idx + 1, Acc}
	  end,
	{_, MembersData}	= lists:foldl(Fun, {1, []}, List),
	Datas		= [
				   Team#team.team_id,
				   Team#team.type,
				   (Team#team.camp)#camp.camp_id,
				   (Team#team.camp)#camp.lv,
				   Team#team.leader_uid,
				   (Team#team.param)#team_param.id,
				   Team#team.lock,
				   MembersData
				  ],
	misc_packet:pack(?MSG_ID_TEAM2_SC_INFO, ?MSG_FORMAT_TEAM2_SC_INFO, Datas).

%% 返回可邀请的替身
%%[{UserId,UserName,Career,Sex,Lv,Cd,Times},TeamType]
msg_sc_invite_author_list(List1,TeamType) ->
    misc_packet:pack(?MSG_ID_TEAM2_SC_INVITE_AUTHOR_LIST, ?MSG_FORMAT_TEAM2_SC_INVITE_AUTHOR_LIST, [List1,TeamType]).


%% 退出玩法到去向通知
msg_sc_quit_play_to(TeamType,Where) ->
	misc_packet:pack(?MSG_ID_TEAM2_SC_QUIT_PLAY_TO, ?MSG_FORMAT_TEAM2_SC_QUIT_PLAY_TO, [TeamType,Where]).

%% 授权别表返回
%%[{UserId},Count,IsGuildAll,TeamType]
msg_sc_author_list(List1,Count,IsGuildAll,TeamType) ->
    misc_packet:pack(?MSG_ID_TEAM2_SC_AUTHOR_LIST, ?MSG_FORMAT_TEAM2_SC_AUTHOR_LIST, [List1,Count,IsGuildAll,TeamType]).

%% 切换战场返回
%%[Id,IsSuccess]
msg_sc_change_copy2(Id,IsSuccess) ->
    misc_packet:pack(?MSG_ID_TEAM2_SC_CHANGE_COPY2, ?MSG_FORMAT_TEAM2_SC_CHANGE_COPY2, [Id,IsSuccess]).

%% 请求元宝雇佣信息返回
%%[{UserId,UserName,Lv,Career}]
msg_sc_gold_hire(List1) ->
    misc_packet:pack(?MSG_ID_TEAM2_SC_GOLD_HIRE, ?MSG_FORMAT_TEAM2_SC_GOLD_HIRE, [List1]).
