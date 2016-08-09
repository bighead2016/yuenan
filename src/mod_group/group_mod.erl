%% Author: zero
%% Created: 2012-8-31
%% Description: TODO: Add description to group_mod_2
-module(group_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.guild.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

%%
%% Exported Functions
%%
-export([create_group/2, change_leader/2, apply_join_group/3, reply_join_group/3, cancel_apply_join/2, kick_out_group/2,
		 get_recommand_list/1, search_member_info/2, quit_group/1,auto_join_group/1,  apply_waiting_group/1,
		 cancel_apply_waiting/1, get_waiting_group/2,invite_group/3,reply_invite_group/4, calculate_group_buff/2,
         calc_group_buffer/3, is_fit_pro/2, has_be_applied_count/2, get_member_power/2, get_group_by_user_id/1]).
-export([calc_buff_group2me/2, calc_buff_me2group/3, get_group_buff/2]).
-export([get_group_list/2, get_group_member_info/2, get_group/1, get_group_apply_list/2, is_in_group1/1]).

%%
%% API Functions
%%
%%  创建队伍
create_group(Player, _Restrict) ->
	UserId				= Player#player.user_id,
	Info				= Player#player.info,
	UserName			= Info#info.user_name,
	GuildName			= (Player#player.guild)#guild.guild_name,
	Lv					= Info#info.lv,
	Pro					= Info#info.pro,
	Sex					= Info#info.sex,
    SkinWeapon          = 0, %Info#info.skin_weapon,
    SkinArmor           = 0, %Info#info.skin_armor,
	Position			= Player#player.position,
	PositionId			= Position#position_data.position,
	case is_in_group1(UserId) of
		?true ->
			TipPacket	= message_api:msg_notice(?TIP_GROUP_IN_GROUP),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player;
		?false ->
			case group_db_mod:creat_group(Player, 1) of                 %% 无限制
				{?ok, _GroupInfo} ->
					PacketBuff		= group_api:msg_sc_buffer(UserId, []),   % 刚创建，必然只有队长一个人，没有加成
					PacketGroup		= group_api:msg_sc_list_group(UserId, UserName, Lv, 1, GuildName, Pro, Sex, 1, SkinWeapon, SkinArmor,
																  PositionId),
					Packet 			= <<PacketGroup/binary, PacketBuff/binary>>,
					misc_packet:send(Player#player.net_pid, Packet),
					AttrReflect  	= Player#player.attr_reflect,
					AttrReflect2 	= AttrReflect#attr_reflect{group = []},
					Player#player{attr_reflect = AttrReflect2};
				{?error, _ErrorCode} -> %% 系统错误
					Player
			end
	end.

%%---------------------------------------------------------------------------------------------------------------------------
%% 查询队伍信息
search_member_info(Player, 0) ->           %% 查询自己队伍信息
	UserId		= Player#player.user_id,
	case get_group_apply_list(UserId, 2) of
		[]	       -> <<>>;
		GroupApply ->
			GroupId		  =	GroupApply#group_apply.group_id,
			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
				?null -> <<>>;
				Group ->
					MemberList	  =	Group#group.member_list,
					NewMemberList =	get_list_member_info(MemberList, []),
					calc_group_buffer(Player, MemberList, MemberList),
					group_api:msg_sc_search_info(NewMemberList, <<>>)
			end
	end;
search_member_info(_Player, GroupId)  -> %% 查询指定队伍信息
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null ->	<<>>;
		Group when is_record(Group, group) ->
			MemberList	= Group#group.member_list,
			NewMemberList= get_list_member_info(MemberList, []),
			group_api:msg_sc_search_info(NewMemberList, <<>>);
		_ -> <<>>
	end.

%% 获取队伍中成员信息
get_list_member_info([], MemberList) ->
	lists:reverse(MemberList); 					% 队长在前
get_list_member_info([{Member}|Tail], MemberList) ->
	case player_api:get_player_fields(Member, [#player.info, #player.guild, #player.position]) of
		{?ok, [#info{user_name = PlayerName, lv = PlayerLv, pro = Pro, sex = Sex},
			   #guild{guild_name = GuildName}, #position_data{position = PositionId}]} ->
			IsOnline     	= member_is_online(Member),
			case get_group_apply_list(Member, 2) of
				[] -> 		get_list_member_info(Tail, MemberList);
				GroupApply ->
					GroupId			= GroupApply#group_apply.group_id,
					IsLeader   	 	= case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
										  ?null -> ?CONST_SYS_FALSE;
										  Group when is_record(Group, group) andalso Group#group.leader_id =:= Member -> ?CONST_SYS_TRUE;
										  _ -> ?CONST_SYS_FALSE
									  end,
					NewMemberList	= [{Member, PlayerName, PlayerLv, IsOnline, GuildName, Pro, Sex, IsLeader, 0, 0, 
										PositionId}|MemberList],
					get_list_member_info(Tail, NewMemberList)
			end;
		_ -> {?ok, ?null}
	end.

%%--------------------------------------------------------------------------------------------------------------------------------
%% 主动转换队长
change_leader(Player, 0) ->			%参数错误
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket);
change_leader(Player, NewLeaderId) ->
	UserId			= Player#player.user_id,
	case get_group_apply_list(UserId, 2) of
		[] -> 
			TipPacket	 	= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),             %% 系统错误
			misc_packet:send(Player#player.net_pid, TipPacket);
		GroupApply ->
			GroupId			= GroupApply#group_apply.group_id,
			try
				?true		= is_leader(UserId),
				?true		= is_not_in_group(NewLeaderId),
				?true       = is_member_online1(NewLeaderId),
				case player_api:get_player_first(NewLeaderId) of
					{?ok, ?null, _} ->
						TipPacket	 	= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),             %% 系统错误
						misc_packet:send(Player#player.net_pid, TipPacket);
					{?ok, NewLeaderInfo, _} ->
						NewLeaderLv		= (NewLeaderInfo#player.info)#info.lv,		
						NewLeaderName	= (NewLeaderInfo#player.info)#info.user_name,
						case mysql_api:update(game_group, [{leader_id, NewLeaderId},{name,NewLeaderName}, {lv, NewLeaderLv}], 
											  [{id, GroupId}]) of
							{?ok, _} ->
								ets:update_element(?CONST_ETS_GROUP, GroupId, [{#group.leader_id, NewLeaderId},{#group.name, NewLeaderName},
																			   {#group.lv, NewLeaderLv}]),
								group_api:msg_sc_change_leader(Player, NewLeaderInfo);
							{?error, ErrorCode} ->  							%% 数据库错误
								{?error, ErrorCode}
						end
				end
			catch
				throw:{?error, Error} ->
					TipsPacket	 	= message_api:msg_notice(Error),             
					misc_packet:send(Player#player.net_pid, TipsPacket);
				Type:Why ->
					?MSG_ERROR("error type:~p, why: ~p, Strace:~w~n ", [Type, Why, erlang:get_stacktrace()]),
					{?error, ?TIP_COMMON_BAD_ARG} % 入参有误
			end
	end.

%%-------------------------------------------------------------------------------------------------------------------------------
%% 申请加入队伍
apply_join_group(Player, GroupId, Type) when is_number(GroupId) andalso GroupId > 0->
    UserId = Player#player.user_id,
	try
		?true		= check_join_group(Player, GroupId),
		?true		= has_apply_count(UserId, Type),
		handler_apply_join(Player, GroupId)
	catch
		throw:{?error, ErrorCode} ->
            PacketErr		= message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, PacketErr);
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~w~n ", [Type, Why, erlang:get_stacktrace()]),
            PacketErr 		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
            misc_packet:send(UserId, PacketErr),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
	end;
apply_join_group(Player, _, _) ->     %% 参数有误
    UserId 		= Player#player.user_id,
    PacketErr 	= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
    misc_packet:send(UserId, PacketErr),
	{?error, ?TIP_COMMON_BAD_ARG}.

check_join_group(Player, GroupId) ->
	?true		= is_group_exist(GroupId),
	?true 		= is_group_full(GroupId),
    ?true 		= is_in_group(Player#player.user_id),
	?true		= is_fit_pro(Player, GroupId).

%% 处理加入申请队伍
handler_apply_join(Player, GroupId) ->
	UserId				= Player#player.user_id,
	Info				= Player#player.info,
	UserName			= Info#info.user_name,
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null ->
			{?error, ?TIP_COMMON_BAD_ARG};
		Group ->
			LeaderId			= Group#group.leader_id,
			case group_db_mod:apply_join_group(Player, GroupId) of
				?ok ->                   % 发给队长
					Packet		= group_api:msg_reply_join_group(UserName, 1, UserId, GroupId),
					misc_packet:send(LeaderId, Packet),
					Packet1		= group_api:msg_reply_join_group(UserName, 0, UserId, GroupId),
					misc_packet:send(Player#player.net_pid, Packet1);
				{?error, ErrorCode }->
					?MSG_PRINT("ErrorCode=~p~n", [ErrorCode]),
					{?error, ?TIP_COMMON_BAD_ARG}
			end
	end.

%-----------------------------------------------------------------------------------------------------------------------
%% 回复申请加入队伍
reply_join_group(Player, 1, ReqUserId) ->          %% 同意加入队伍
	try
		?true		  =	is_in_group(ReqUserId),
		NewPlayer	  = get_player(ReqUserId),
		Group		  = get_group_apply_list(Player#player.user_id, 2),
		GroupId		  =	Group#group_apply.group_id,
		Group1		  =	ets_api:lookup(?CONST_ETS_GROUP, GroupId),
		?true		  = is_fit_pro(NewPlayer, GroupId),
		Pattern2	  =	#group_apply{user_id = ReqUserId, group_id = GroupId, _= '_'},
		ApplyInfo	  = ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern2),
		case ApplyInfo of
			[] ->
				Packet  = message_api:msg_notice(?TIP_GROUP_HAS_CANCEL_JOIN),
				misc_packet:send(Player#player.net_pid, Packet),
				{?error, ?TIP_GROUP_NOT_APPLYING};
			[ApplyGroup] when is_record(ApplyGroup, group_apply) andalso ApplyGroup#group_apply.state =/= 2 ->
				case group_db_mod:update_join_group(Group1, ApplyGroup, ReqUserId) of
					{?ok, MemberList} ->
						group_api:msg_sc_join_group(Group1, ApplyGroup, ReqUserId),
						{?ok, Player2}		= calc_group_buffer(Player, MemberList, MemberList),
						MemberNum			= erlang:length(MemberList),
						MemberList1		 	= lists:delete({Player#player.user_id}, MemberList),
						add_group_pullulation(MemberList1, MemberNum),
						welfare_api:add_pullulation(Player2, ?CONST_WELFARE_GROUP, MemberNum, 1);  %% 成长礼包
					{?error, ErrorCode} ->  %%数据库出错
						Packet		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
						misc_packet:send(Player#player.net_pid, Packet),
						{?error, ErrorCode}
				end;
			_ ->
				Packet  	= message_api:msg_notice(?TIP_GROUP_HAS_CANCEL_JOIN),
				misc_packet:send(Player#player.net_pid, Packet),
				{?error, ?TIP_GROUP_NOT_APPLYING}
		end
	catch
		throw:{?error, Msg} ->
			Packet1		= message_api:msg_notice(Msg),
			misc_packet:send(Player#player.net_pid, Packet1),
			{?ok, Player};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			{?error, ?TIP_COMMON_BAD_ARG} % 入参有误
	end;
reply_join_group(Player, 0, ReqUserId) ->                 %% 拒绝申请加入队伍
	Group		    = get_group_apply_list(Player#player.user_id, 2),
	GroupId			= Group#group_apply.group_id,
	Pattern2		= #group_apply{user_id = ReqUserId, group_id = GroupId, _= '_'},
	ApplyGroup		= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern2),
	case ApplyGroup of
		[] ->                                  %% 已经加入了别人的队伍或取消了申请加入队伍
			TipPacket		= message_api:msg_notice(?TIP_GROUP_HAS_CANCEL_JOIN),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player};
		[ApplyInfo] when is_record(ApplyInfo, group_apply) andalso ApplyInfo#group_apply.state =/= 2 ->
			Id		= ApplyInfo#group_apply.id,
			case mysql_api:delete(game_group_apply, "id = "++misc:to_list(Id)++" and user_id="++misc:to_list(ReqUserId)) of
				{?ok, _, _} ->
					ets_api:delete(?CONST_ETS_GROUP_APPLY, Id);
				{?error, _ErrorCode} ->
					TipPacket		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end,
			Packet		= message_api:msg_notice(?TIP_GROUP_REJECT_JOIN),
			Packet1		= group_api:msg_sc_cancel_apply(GroupId),
			misc_packet:send(ReqUserId, <<Packet/binary, Packet1/binary>>),
			{?ok, Player};
		_ ->
			TipPacket 	= message_api:msg_notice(?TIP_GROUP_REJECT_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.
%---------------------------------------------------------------------------------------------------------------
%% 取消申请加入
cancel_apply_join(Player, GroupId) ->
	UserId			= Player#player.user_id,
	try
		?true		= check_cancel_apply(UserId, GroupId),
		handler_cancel_join(Player, GroupId)
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.

%% 取消申请加入检查
check_cancel_apply(UserId, GroupId) ->
	?true		= is_in_group(UserId),
	?true		= is_applying_group(UserId, GroupId).

%% 取消申请加入处理
handler_cancel_join(Player, GroupId) ->
	UserId		= Player#player.user_id,
	Pattern1	= #group_apply{user_id = UserId, group_id = GroupId, _ = '_'},
	GroupInfo	= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern1),
	case GroupInfo of
		[] ->
			TipPacket		= message_api:msg_notice(?TIP_GROUP_NOT_APPLYING),
			misc_packet:send(Player#player.net_pid, TipPacket);
		[Group] when is_record(Group, group_apply) ->
			Id			= Group#group_apply.id,
			case mysql_api:delete(game_group_apply, "id ="++misc:to_list(Id)++" and user_id="++misc:to_list(UserId)) of
				{?ok, _, _} ->
					ets_api:delete(?CONST_ETS_GROUP_APPLY, Id);
				{?error, _ErrorCode} ->
					Packet1		= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
					misc_packet:send(Player#player.net_pid, Packet1)
			end,
			Packet		= group_api:msg_sc_cancel_apply(GroupId),
			TipPacket	= message_api:msg_notice(?TIP_GROUP_CANCEL_JOIN),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>);
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_GROUP_NOT_APPLYING),
			misc_packet:send(Player#player.net_pid, TipPacket)
	end.

%--------------------------------------------------------------------------------------------------------------------
%% 踢出队伍
kick_out_group(Player, 0) -> %参数错误
	Packet		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, Packet),
	{?error, ?TIP_COMMON_BAD_ARG};
kick_out_group(Player, KickOutId) ->
	UserId		= Player#player.user_id,
	try
        ?true 	= check_kickout(UserId, KickOutId),
        handler_kickout(Player, KickOutId)
    catch
        throw:{?error, ErrorCode} ->
           TipPacket		= message_api:msg_notice(ErrorCode),
		   misc_packet:send(Player#player.net_pid, TipPacket),
		   {?error, ErrorCode};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.

%% 检查可以T
check_kickout(UserId, KickOutId) ->
    ?true		= is_leader(UserId),
    ?true		= is_same_group(UserId, KickOutId).

%% 踢出队伍处理
handler_kickout(Player, KickOutId) ->
	case group_db_mod:kick_out_group(Player, KickOutId) of
		{?ok, NewMemberList}->
			group_api:msg_sc_kick_out(Player, KickOutId),
			AttrReflect     	= Player#player.attr_reflect,
			AttrReflect2    	= AttrReflect#attr_reflect{group = []},
			Player2         	= Player#player{attr_reflect = AttrReflect2},
			Player3         	= player_attr_api:refresh_group(Player2, []),
			{?ok, Player4}		= calc_group_buffer(Player3, NewMemberList, NewMemberList),
            {?ok, Player4};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%-------------------------------------------------------------------------------------------------------------------------
%% 获取推荐列表
get_recommand_list(Player) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	List			= ets_api:list(?CONST_ETS_GROUP),
	ApplyList		= get_group_apply_list1(UserId, 3),						  %% 已申请的队伍
	ApplyList1		= get_apply_list_info(ApplyList, []),
	ApplyNum		= erlang:length(ApplyList),
	RecommendList	= get_recommend_list_info(List, Lv, [], ApplyNum, ApplyList1),		  
	NewRecomList	= get_auto_join_group1(Player, RecommendList, []),
	RecomList		= misc:list_merge(NewRecomList, ApplyList1),
	GroupList1		= get_group_list1(ApplyList, []),
	GroupList2		= get_group_list(NewRecomList, []),
	GroupList		= misc:list_merge(GroupList1, GroupList2),
	?MSG_DEBUG("GroupList1=~p GroupList2=~p", [GroupList1, GroupList2]),
	case GroupList of
		[] ->
			Packet			= message_api:msg_notice(?TIP_GROUP_GET_LIST_FAIL),
			Packet1			= group_api:msg_sc_recommand_list([], []),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>);
		_ ->
			MemberList 		= [get_group_member_info(Group#group.member_list, []) || Group <- RecomList],
			Packet			= group_api:msg_sc_recommand_list(GroupList, MemberList),
			misc_packet:send(Player#player.net_pid, Packet)
	end.

%% 获取各队伍中的信息 
get_group_list([Group|GroupList], Acc) ->
	GroupId 		= Group#group.id,
	GroupName 		= Group#group.name,
	InGroupNum 		= Group#group.in_group_num,
	GuildName 		= Group#group.guild_name,
	ResultList 		= [{GroupId, GroupName, InGroupNum, GuildName, ?CONST_SYS_FALSE}|Acc],
	get_group_list(GroupList, ResultList);
get_group_list([], Acc) ->
	Acc.

get_group_list1([GroupApply|RestList], Acc) ->
	GroupId		= GroupApply#group_apply.group_id,
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		Group when is_record(Group, group) ->
				GroupName 		= Group#group.name,
				InGroupNum 		= Group#group.in_group_num,
				GuildName 		= Group#group.guild_name,
				ResultList 		= [{GroupId, GroupName, InGroupNum, GuildName, ?CONST_SYS_TRUE}|Acc],
				get_group_list1(RestList, ResultList);
		_ ->
			get_group_list1(RestList, Acc)
	end;
get_group_list1([], Acc) ->
	Acc.

get_apply_list_info([GroupApply|RestList], Acc) ->
	GroupId		= GroupApply#group_apply.group_id,
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		Group when is_record(Group, group) ->
			NewAcc		= [Group|Acc],
			get_apply_list_info(RestList, NewAcc);
		_ -> get_apply_list_info(RestList, Acc)
	end;
get_apply_list_info([], Acc) -> Acc.
		
%% 获取队伍中各成员信息
get_group_member_info([{Member}|MemberList], Acc) ->
	case player_api:get_player_fields(Member, [#player.info, #player.guild]) of
		{?ok, [#info{user_name = PlayerName, lv = PlayerLv, pro = Career, sex = Sex}, 
			   #guild{guild_name = GuildName}]} ->
			case get_group_apply_list(Member, 2) of
				[] ->
					get_group_member_info(MemberList, Acc);
				Group	->	
					GroupId      = Group#group_apply.group_id,
					IsOnline     = member_is_online(Member),
					NewMemberList = [{GroupId, Member, PlayerName, PlayerLv, IsOnline, GuildName, Career, Sex}|Acc],
					get_group_member_info(MemberList, NewMemberList)
			end
	end;
get_group_member_info([], Acc) ->
	lists:reverse(Acc).


%% 获取指定长度的推荐列表   
get_recommend_list_info([Group|RestList], Lv, Acc, Num, List) when Num < ?CONST_GROUP_MAX_RECOMMEND_COUNT ->
	GroupId		= Group#group.id,
	Lv1			= Group#group.lv,
	OnLine		= Group#group.online_member_list,
	UpLv		= Lv1 + 5,
	DownLv		= Lv1 - 5,
	OnLineNum	= erlang:length(OnLine),
	case lists:keymember(GroupId, #group.id, List) of       %% 去除已经申请的列表
		?false ->
			case {Lv >= DownLv, Lv =< UpLv, OnLineNum =/= ?CONST_SYS_FALSE} of
				{?true, ?true, ?true} ->
					NewAcc		= [Group|Acc],
					NewNum		= Num + 1,
					get_recommend_list_info(RestList, Lv, NewAcc, NewNum, List);
				{_, _, _} ->
					get_recommend_list_info(RestList, Lv, Acc, Num, List)
			end;
		?true ->
			get_recommend_list_info(RestList, Lv, Acc, Num, List)
	end;
get_recommend_list_info(_, _, Acc, _, _) -> Acc.
%%-------------------------------------------------------------------------------------------------------------
%% 离开队伍
quit_group(Player) ->
	UserId			= Player#player.user_id,
	case get_group_apply_list(UserId, 2) of
		[] ->			%% 不在队伍中
			TipPacket		= message_api:msg_notice(?TIP_GROUP_QUIT),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ?TIP_GROUP_QUIT};
		GroupApply when is_record(GroupApply, group_apply) ->
			handler_quit_group(Player, GroupApply);
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ?TIP_COMMON_SYS_ERROR}
	end.
		
%% 处理离开队伍
handler_quit_group(Player, GroupApply) ->
	GroupId			= GroupApply#group_apply.group_id,
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		Group when is_record(Group, group) ->
			LeaderId		= Group#group.leader_id,
			MemberList		= Group#group.member_list,
			Num				= erlang:length(MemberList),
			if
				Num =:= ?CONST_SYS_TRUE ->
					Packet	= message_api:msg_notice(?TIP_GROUP_DISBAND),
					Packet1	= group_api:msg_sc_disband(),
					misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
					case mysql_api:delete(game_group, " id ="++misc:to_list(GroupId)) of
						{?ok, _, _} ->
							ets_api:delete(?CONST_ETS_GROUP, GroupId);
						{?error, _ErrorCode} ->
							TipPacket	= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
							misc_packet:send(Player#player.net_pid, TipPacket)
					end,
					case mysql_api:delete(game_group_apply, " id ="++misc:to_list(GroupApply#group_apply.id)) of
						{?ok, _, _} ->
							ets_api:delete(?CONST_ETS_GROUP_APPLY, GroupApply#group_apply.id);
						{?error, _} ->
							TipPacket1	=	message_api:msg_notice(?TIP_COMMON_ERROR_DB),
							misc_packet:send(Player#player.net_pid, TipPacket1)
					end,
					AttrReflect     = Player#player.attr_reflect,
					AttrReflect2    = AttrReflect#attr_reflect{group = []},
					Player2			= Player#player{attr_reflect = AttrReflect2},
					{?ok, Player2};
				?true ->              %% 队伍中至少有两个人
					case Player#player.user_id =:= LeaderId of
						?true ->
							handler_leader_quit(Player, Group, GroupApply);
						?false ->
							handler_member_quit(Player, Group)
					end
			end;
		_ ->
			TipPacket		= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end.

%% 处理队长离开
handler_leader_quit(Player, Group, GroupApply) ->
	UserId			= Player#player.user_id,
	MemberList		= Group#group.member_list,
	NewMemberList	= lists:delete({UserId}, MemberList),
	OnLineList		= Group#group.online_member_list,
	NewOnLineList	= lists:delete({UserId}, OnLineList),
	NewOnLineNum	= erlang:length(NewOnLineList),
	case NewOnLineNum	=:= ?CONST_SYS_FALSE of                  %% 没有在线玩家 解散队伍 删除所有申请记录
		?true ->
			Packet		= message_api:msg_notice(?TIP_GROUP_DISBAND),
			Packet1		= group_api:msg_sc_disband(),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet1/binary>>),
			GroupId		= GroupApply#group_apply.group_id,
			case mysql_api:delete(game_group, " id ="++misc:to_list(GroupId)) of
				{?ok, _, _} ->
					ets_api:delete(?CONST_ETS_GROUP, GroupId);
				{?error, _ErrorCode} ->
					TipPacket	= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
					misc_packet:send(Player#player.net_pid, TipPacket)
			end,
			delete_all_apply(GroupId),
			AttrReflect     = Player#player.attr_reflect,
			AttrReflect2    = AttrReflect#attr_reflect{group = []},
			Player2         = Player#player{attr_reflect = AttrReflect2},
			Player3         = player_attr_api:refresh_group(Player2, []),
			{?ok, Player3};
		?false ->
			N				= misc_random:random(NewOnLineNum),  % 随机分配队长
			{NewLeaderId}	= lists:nth(N, NewOnLineList),
			change_leader(Player, NewLeaderId),
			case group_db_mod:quit_group(Player, Group) of
				{?ok, NewMemberList}->
					group_api:msg_sc_quit(Player, NewOnLineList),
					Packet2 		= message_api:msg_notice(?TIP_GROUP_QUIT),
					misc_packet:send(Player#player.net_pid, Packet2),
					AttrReflect     = Player#player.attr_reflect,
					AttrReflect2    = AttrReflect#attr_reflect{group = []},
					Player2         = Player#player{attr_reflect = AttrReflect2},
					Player3         = player_attr_api:refresh_group(Player2, []),
					{?ok, Player4}  = calc_group_buffer(Player3, NewMemberList, NewMemberList),
					{?ok, Player4};
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end
	end.

%% 队伍解散 删除所有申请记录
delete_all_apply(GroupId) ->
	Where		= <<"WHERE `group_id` = ", (misc:to_binary(GroupId))/binary>>,
	case mysql_api:select_execute(<<"SELECT `id` FROM `game_group_apply`", Where/binary ,"; ">>) of
		{?ok, []} -> ?ok;
		{?ok, IdList} ->
			?MSG_DEBUG("IdList=~p", [IdList]),
			F = fun([Id]) ->
						case mysql_api:delete(game_group_apply, " id ="++misc:to_list(Id)) of
							{?ok, _, _} ->
								ets_api:delete(?CONST_ETS_GROUP_APPLY, Id);
							{?error, ErrorReason} ->
								?MSG_ERROR("~n{?error, ErrorReason}=~p", [{?error, ErrorReason}]),
								{?error, ?TIP_COMMON_ERROR_DB}
						end
				end,
			[F(Id1) || Id1 <- IdList];
		{?error, ErrorCode} ->
			?MSG_DEBUG("~nErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.
					
		
%% 处理队员离开
handler_member_quit(Player, Group) ->
	UserId			= Player#player.user_id,
	OnLineList		= Group#group.online_member_list,
	NewOnLineList	= lists:delete({UserId}, OnLineList),
	case group_db_mod:quit_group(Player, Group) of
		{?ok, NewMemberList}->
			group_api:msg_sc_quit(Player, NewOnLineList),
			Packet 			= message_api:msg_notice(?TIP_GROUP_QUIT),
			misc_packet:send(Player#player.net_pid, Packet),
			AttrReflect     = Player#player.attr_reflect,
			AttrReflect2    = AttrReflect#attr_reflect{group = []},
			Player2         = Player#player{attr_reflect = AttrReflect2},
			Player3         = player_attr_api:refresh_group(Player2, []),
			{?ok, Player4} 	= calc_group_buffer(Player3, NewMemberList, NewMemberList),
			{?ok, Player4};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%%-------------------------------------------------------------------------------------------------------------
%% 自动加入队伍
auto_join_group(Player) ->
	case get_group_apply_list(Player#player.user_id, 2) of
		[] ->			%% 不在队伍中
			handler_auto_join(Player);	
		_ ->
		   Packet	= message_api:msg_notice(?TIP_GROUP_IN_GROUP),
		   misc_packet:send(Player#player.net_pid, Packet)
	end.

%% 处理自动加入队伍
handler_auto_join(Player) ->
	UserId			= Player#player.user_id,
	Info			= Player#player.info,
	Lv				= Info#info.lv,
	GroupList		= ets_api:list(?CONST_ETS_GROUP),
	ApplyList		= get_group_apply_list1(UserId, 3),						  %% 已申请的队伍
	ApplyList1		= get_apply_list_info(ApplyList, []),
	List			= get_recommend_list_info(GroupList, Lv, [], ?CONST_SYS_FALSE, ApplyList1),
	NewGroupList	= get_auto_join_group(List, []),
	NewGroupList1	= get_auto_join_group1(Player, NewGroupList, []),
	case List of
		[] ->
			Packet	 = message_api:msg_notice(?TIP_GROUP_GET_LIST_FAIL),
			misc_packet:send(Player#player.net_pid, Packet);
		_ ->
			[apply_join_group(Player, Group#group.id, ?CONST_SYS_TRUE)|| Group <- NewGroupList1]
	end.

%% 获取能申请自动加入的队伍(队伍人数限制)
get_auto_join_group([Group|List], Acc) when Group#group.in_group_num < 3 ->
	NewAcc		= [Group|Acc],
	get_auto_join_group(List, NewAcc);
get_auto_join_group([_Group|List], Acc) ->
	get_auto_join_group(List, Acc);
get_auto_join_group([], Acc) ->
	Acc.

%% 获取能申请自动加入的队伍(职业限制)
get_auto_join_group1(Player, [Group|List], Acc) ->
	ProList		 = Group#group.pro_list,
	Info		 = Player#player.info,
	Pro			 = Info#info.pro,
	NewAcc		 = case lists:keyfind(Pro, 1, ProList) of
					   ?false ->  [Group|Acc];
					   _ProInfo -> Acc
				   end,
	get_auto_join_group1(Player, List, NewAcc);
get_auto_join_group1(_, _, Acc) ->
	Acc.

%% ---------------------------------------------------------------------------------------------------------------------		
%% 申请成为待组玩家
apply_waiting_group(Player) ->
	UserId			= Player#player.user_id,
	try
		?true		= is_in_group(UserId),
		?true		= is_waiting_group(UserId),
		handler_apply_waiting(Player)
	catch
		throw:{?error, ErrorCode}->
			Packet	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet);
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			Packet	= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_COMMON_BAD_ARG} % 入参有误
	end.
			
%% 处理成为待组玩家
handler_apply_waiting(Player) ->
	case group_db_mod:apply_wating_group(Player) of
		?ok ->
			group_api:msg_sc_apply_waiting(Player),
			Packet		= message_api:msg_notice(?TIP_GROUP_IS_WAITER),
			misc_packet:send(Player#player.net_pid, Packet);
		{?error, ErrorCode} ->
			Packet		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ErrorCode}
	end.

%%-----------------------------------------------------------------------------------------------------------------------
%% 取消申请待组状态
cancel_apply_waiting(Player) ->
	UserId		= Player#player.user_id,
	try
		?true 		= is_in_group(UserId),
		?true		= check_waiting_group(UserId),
		handler_cancel_waiting(Player)
	catch
		throw:{?error, MsgId}->
			TipPacket	= message_api:msg_notice(MsgId),
			misc_packet:send(Player#player.net_pid, TipPacket),
            {?ok, Player};
		Type:Why ->
			 ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.

%% 判断是否待组
check_waiting_group(UserId) ->
	GroupApply		= get_group_apply_list1(UserId, 4),
	case GroupApply of
		[] -> throw({?error, ?TIP_GROUP_NOT_WAITING_STATE});         %% 不是待组状态
		_  -> ?true
	end.
	
%% 处理取消申请待组状态
handler_cancel_waiting(Player) ->
	case group_db_mod:cancel_apply_waiting(Player) of
		?ok ->
			Packet		= message_api:msg_notice(?TIP_GROUP_CANCEL_WAITING),
			misc_packet:send(Player#player.user_id, Packet);
		{?error, ErrorCode} ->
			?MSG_PRINT("ErrorCode=~p", [ErrorCode]),
			{?error, ErrorCode}
	end.
%%-------------------------------------------------------------------------------------------------------------------------------
%% 获取邀请列表
get_waiting_group(Player, Type) ->
	UserId			= Player#player.user_id,
	GroupApply		= get_group_apply_list(UserId, 2),
	case GroupApply =:= [] of 
		?false  ->              %% 在队伍中
			case Type of
				?CONST_SYS_FALSE ->										%% 从好友列表里筛选
					FriendList1		= get_friend_list(UserId, 1),
					FriendList2		= get_friend_list(UserId, 2),
					FriendList3		= misc:list_merge(FriendList1, FriendList2),
					FriendList		= filter_friend_list(FriendList3, []),
					Packet			= group_api:msg_sc_waiting_list(Type, FriendList),
					misc_packet:send(Player#player.net_pid, Packet);
				?CONST_SYS_TRUE ->									    %% 从军团列表里筛选
					GuildList1		= get_guild_list(Player),
					GuildList		= filter_guild_list(GuildList1, []), 
					Packet			= group_api:msg_sc_waiting_list(Type, GuildList),
					misc_packet:send(Player#player.net_pid, Packet);
				_ ->
					Packet			= group_api:msg_sc_waiting_list(Type, []),
					misc_packet:send(Player#player.net_pid, Packet)
			end;
		?true ->
			Packet		= group_api:msg_sc_waiting_list(Type, []),
			misc_packet:send(Player#player.net_pid, Packet)
	end.
%% 获取好友列表
get_friend_list(UserId, Type) ->
	case ets_api:lookup(?CONST_ETS_RELATION_DATA, UserId) of
		?null 	 -> [];
		Relation ->
			case Type of
				?CONST_RELATIONSHIP_BRELA_FRIEND ->
					Relation#relation_data.friend_list;
				?CONST_RELATIONSHIP_BRELA_BEST_FRIEND ->
					Relation#relation_data.best_list
			end
	end.
%% 从好友列表里筛选
filter_friend_list([{relation, UserId, _}|Tail], Acc) ->
	OnlineFlag		= player_api:check_online(UserId),
	OpenFlag		= player_sys_api:is_open_sys(UserId, ?CONST_MODULE_GROUP),	
	GroupFlag		= is_in_group1(UserId),
	case {OnlineFlag, OpenFlag, GroupFlag} of
			{?true, ?true, ?false} ->
					NewAcc		= [UserId|Acc],
					filter_friend_list(Tail, NewAcc);
			_ ->
					filter_friend_list(Tail, Acc)
	end;
filter_friend_list(_, Acc) ->
	Acc.
%% 获取军团在线成员列表
get_guild_list(Player) ->
	UserId			= Player#player.user_id,
	GuildId			= (Player#player.guild)#guild.guild_id,
	case ets_api:lookup(?CONST_ETS_GUILD_DATA, GuildId) of
		?null -> [];
		#guild_data{member_online = MemList} -> %% 在线列表
			lists:delete(UserId, MemList)
	end.	
%%从军团列表里筛选
filter_guild_list([UserId|Tail], Acc) ->
	OpenFlag		= player_sys_api:is_open_sys(UserId, ?CONST_MODULE_GROUP),	
	GroupFlag		= is_in_group1(UserId),
	case {OpenFlag, GroupFlag} of
		{?true, ?false} ->
			NewAcc		= [UserId|Acc],
			filter_guild_list(Tail, NewAcc);
		_ ->
			filter_guild_list(Tail, Acc)
	end;
filter_guild_list(_, Acc) ->
	Acc.
%%-----------------------------------------------------------------------------------------------------------
%% 邀请玩家
invite_group(Player, 0, UserId) ->        %% 普通邀请 要对方玩家同意
	Info		 = Player#player.info,
	Name		 = Info#info.user_name,
	try
		?true			= is_member_online(UserId),
		?true			= is_open(UserId),
		case get_group_apply_list(Player#player.user_id, 2) of
			[] ->
				case group_db_mod:creat_group(Player, 1) of 
					{?ok, GroupInfo} ->
						GroupId			= GroupInfo#group.id,
						?true			= is_in_group2(UserId),
						?true			= is_fit_group1(Player, UserId),   %% 两个人都没有队伍,直接比较职业
						handler_invite_group(UserId, GroupId, Name),
						Packet 			= message_api:msg_notice(?TIP_GROUP_INVITE_SUCCESS),
						misc_packet:send(Player#player.net_pid, Packet),
						{?ok, Player}
				end;
			GroupApply ->
				GroupId			= GroupApply#group_apply.group_id,
				?true			= is_in_group2(UserId),
				?true			= is_group_full(GroupId),
				?true			= is_fit_group(UserId, GroupId),
				handler_invite_group(UserId, GroupId, Name),
				Packet 			= message_api:msg_notice(?TIP_GROUP_INVITE_SUCCESS),
				misc_packet:send(Player#player.net_pid, Packet),
				{?ok, Player}
		end
	catch
		throw:{?error, ErrorCode}->
			?MSG_DEBUG("ErrorCode=~p", [ErrorCode]),
			PacketErr		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			PacketErr 		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?error, ?TIP_COMMON_BAD_ARG} % 入参有误
	end;
invite_group(Player, 1, UserId) ->    %% 待组邀请 直接把玩家加入队伍
	try
		?true			= is_member_online(UserId),
		?true			= check_wait_group(UserId),
		case get_group_apply_list(Player#player.user_id, 2) of
			[] ->
				Packet			= message_api:msg_notice(?TIP_GROUP_NOT_ALLOW_INVITE),
				misc_packet:send(Player#player.net_pid, Packet),
				{?error, ?TIP_GROUP_NOT_ALLOW_INVITE};
			GroupApply ->
				GroupId			= GroupApply#group_apply.group_id,
				?true			= is_in_group(UserId),
				?true			= is_group_full(GroupId),
				?true			= is_fit_group(UserId, GroupId),
				handler_join_group(Player, GroupId, UserId)	
		end
	catch
		throw:{?error, ErrorCode}->
			PacketErr		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?error, ErrorCode};
		Type:Why ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
			PacketErr  		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, PacketErr),
			{?error, ?TIP_COMMON_BAD_ARG} % 入参有误
	end.

%% 判断是否是待组状态
check_wait_group(UserId) ->
	GroupApply		= get_group_apply_list1(UserId, 4),
	case GroupApply of
		[] ->              %% 不是待组状态
			throw({?error, ?TIP_GROUP_NOT_WAITING_USER});
		_ -> ?true
	end.

%% 处理邀请玩家
handler_invite_group(UserId, GroupId, Name) ->
	Packet			= group_api:msg_sc_reply_invitor(Name, GroupId),
	misc_packet:send(UserId, Packet).

%% 处理邀请待组玩家 （直接加入队伍）
handler_join_group(Player, GroupId, UserId) ->
    case player_api:get_player_first(UserId) of
        {?ok, Player2, _} ->
        	case group_db_mod:invite_group(GroupId, Player2) of
        		{?ok, NewMemberList}->
        			group_api:msg_sc_reply_invite(GroupId, UserId),
        			Packet		= message_api:msg_notice(?TIP_GROUP_JOIN_SUCCESS),
					Packet2		= group_api:msg_sc_delete_waiter(UserId),
        			misc_packet:send(UserId, Packet2),
        			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet2/binary>>),
        			{?ok, Player3}	 = calc_group_buffer(Player, NewMemberList, NewMemberList),
					MemberNum		 = erlang:length(NewMemberList),
					MemberList		 = lists:delete({Player#player.user_id}, NewMemberList),
					add_group_pullulation(MemberList, MemberNum),
					welfare_api:add_pullulation(Player3, ?CONST_WELFARE_GROUP, MemberNum, 1);              %% 成长礼包
        		{?error, ErrorCode} ->
        			throw({?error, ErrorCode})
        	end;
        _ ->
			throw({?error, ?TIP_COMMON_NO_THIS_PLAYER})
    end.

%%  玩家同意或拒绝邀请处理 
reply_invite_group(Player, _GroupId, _UserId, ?CONST_SYS_FALSE) ->  %%拒绝邀请
	Packet		= message_api:msg_notice(?TIP_GROUP_REJECT_SUCCESS),
	misc_packet:send(Player#player.net_pid, Packet),
	{?ok, Player};
reply_invite_group(Player, GroupId, UserId, ?CONST_SYS_TRUE) ->    %% 同意邀请
	try
		?true		= is_group_full(GroupId),
		?true		= is_in_group(UserId),
		?true		= is_fit_pro1(UserId, GroupId),
		handler_reply_invite(Player, GroupId, UserId)
	catch
		throw:{?error, MsgId}->
			TipPacket	= message_api:msg_notice(MsgId),
			misc_packet:send(Player#player.net_pid, TipPacket),
            {?ok, Player};
		Type:Why ->
			 ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.

%% 玩家同意加入队伍处理
handler_reply_invite(Player, GroupId, UserId) ->
	case group_db_mod:invite_group(GroupId, Player) of
		{?ok, NewMemberList}->
			group_api:msg_sc_reply_invite(GroupId, UserId),
			Packet		= message_api:msg_notice(?TIP_GROUP_JOIN_SUCCESS),
			Packet2		= group_api:msg_sc_waiting_list([]),
			misc_packet:send(Player#player.net_pid, <<Packet/binary, Packet2/binary>>),
			{?ok, Player2}		= calc_group_buffer(Player, NewMemberList, NewMemberList),
            {?ok, Player2};
		{?error, ErrorCode} ->
			{?error, ErrorCode}
	end.

%% 请求成员战力
get_member_power(Player, UserId) ->
	Power		= partner_api:caculate_camp_power(UserId),
	Packet		= group_api:msg_sc_member_power(UserId, Power),
	misc_packet:send(Player#player.net_pid, Packet).

%%----------------------------------------------------------------------------------------------------------------------------------------
%% 增加成长礼包
add_group_pullulation([{MemerId}|List], Num) ->
	welfare_api:add_pullulation(MemerId, ?CONST_WELFARE_GROUP, Num, 1),
	add_group_pullulation(List, Num);
add_group_pullulation(_, _) -> ?ok.
	
%% 获取已在队伍中的列表
get_group_apply_list(UserId, State) ->
	List		= ets_api:list(?CONST_ETS_GROUP_APPLY),
	get_group_apply_list(List, UserId, State, []).

get_group_apply_list([GroupApply|RestList], UserId, State, Acc) when is_record(GroupApply, group_apply)->
	OtherId		= GroupApply#group_apply.user_id,
	OtherState	= GroupApply#group_apply.state,
	case {OtherId =:= UserId, OtherState =:= State} of
		{?true, ?true} -> 
			NewAcc = [GroupApply|Acc],
			get_group_apply_list(RestList, UserId, State, NewAcc);
		{_, _} -> 
			get_group_apply_list(RestList, UserId, State, Acc)
	end;
get_group_apply_list([_|RestList], UserId, State, Acc) ->
	get_group_apply_list(RestList, UserId, State, Acc);
get_group_apply_list([], _, _, Acc) ->
	case Acc of
		[]             -> [];
		[GroupApply|_] -> GroupApply
	end.

%% 获取申请的队伍列表
get_group_apply_list1(UserId, State) ->
	List		= ets_api:list(?CONST_ETS_GROUP_APPLY),
	get_group_apply_list1(List, UserId, State, []).

get_group_apply_list1([GroupApply|RestList], UserId, State, Acc) when is_record(GroupApply, group_apply) ->
	OtherId		= GroupApply#group_apply.user_id,
	OtherState	= GroupApply#group_apply.state,
	case {OtherId =:= UserId, OtherState =:= State} of
		{?true, ?true} ->
			NewAcc		= [GroupApply|Acc],
			get_group_apply_list1(RestList, UserId, State, NewAcc);
		{_, _} ->
			get_group_apply_list1(RestList, UserId, State, Acc)
	end;
get_group_apply_list1([_|RestList], UserId, State, Acc) ->
	get_group_apply_list1(RestList, UserId, State, Acc);
get_group_apply_list1([], _, _, Acc) ->
	Acc.
  
%% 判断是否在线
member_is_online(UserId) ->
	case player_api:check_online(UserId) of
		?true ->    ?CONST_SYS_TRUE;						%% 在线	
		?false ->	?CONST_SYS_FALSE						%% 不在线
			
	end.

is_member_online(UserId) ->
	case player_api:check_online(UserId) of
		?true ->	?true;		%% 在线
		?false ->   throw({?error, ?TIP_GROUP_NOT_ONLINE})
	end.

is_member_online1(UserId) ->             %% 不在线 不能转移给队长
	case player_api:check_online(UserId) of
		?true ->   ?true;		         %% 在线
		?false ->  throw({?error, ?TIP_GROUP_NOT_ALLOW_LEADER})
	end.
	
%% 判断是否队长
is_leader(UserId) ->
	case get_group_apply_list(UserId, 2) of
		[] 		   -> throw({?error, ?TIP_COMMON_SYS_ERROR});
		GroupApply when is_record(GroupApply, group_apply) -> 
			GroupId			= GroupApply#group_apply.group_id,
			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
				?null -> throw({?error, ?TIP_GROUP_NOT_LEADER});
				Group when is_record(Group, group) andalso Group#group.leader_id =:= UserId -> ?true;
				_ ->	throw({?error, ?TIP_GROUP_NOT_LEADER})
			end;
		_ -> throw({?error, ?TIP_COMMON_SYS_ERROR})
	end.

%% 判断职业是否符合
is_fit_pro(Player, GroupId) ->
	Info		= Player#player.info,
	Pro			= Info#info.pro,
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null -> throw({?error, ?TIP_GROUP_NOT_FIT_PRO});
		Group ->
			ProList		= Group#group.pro_list,
			case lists:keyfind(Pro, 1, ProList) of
				?false -> ?true;
				_ ->      throw({?error, ?TIP_GROUP_NOT_FIT_PRO})
			end
	end.

is_fit_pro1(UserId, GroupId) ->
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null -> throw({?error, ?TIP_GROUP_NOT_FIT_PRO});
		Group ->
			ProList			= Group#group.pro_list,
			case player_api:get_player_field(UserId, #player.info) of
				{?ok, #info{pro = Pro}} ->
					case lists:keyfind(Pro, 1, ProList) of
						?false -> ?true;
						_ ->       throw({?error, ?TIP_GROUP_NOT_FIT_PRO})
					end;
				_ -> throw({?error, ?TIP_GROUP_NOT_FIT_PRO})
			end
	end.

is_fit_group(UserId, GroupId) ->    %% 判定职业是否符合
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null -> throw({?error, ?TIP_GROUP_PRO_NOT_FIT});
		Group ->
			ProList			= Group#group.pro_list,
			case player_api:get_player_field(UserId, #player.info) of
				{?ok, #info{pro = Pro}} ->
					case lists:keyfind(Pro, 1, ProList) of
						?false -> ?true;
						_ ->       throw({?error, ?TIP_GROUP_PRO_NOT_FIT})
					end;
				_ -> throw({?error, ?TIP_GROUP_PRO_NOT_FIT})
			end
	end.

is_fit_group1(Player, UserId) ->           %% 判定职业是否符合
	Info		= Player#player.info,
	Pro			= Info#info.pro,
	case player_api:get_player_field(UserId, #player.info) of
		{?ok, #info{pro = Pro1}} ->
			case Pro =:= Pro1 of
				?false -> ?true;
				?true  -> throw({?error, ?TIP_GROUP_PRO_NOT_FIT1})
			end;
		_ -> throw({?error, ?TIP_GROUP_PRO_NOT_FIT1})
	end.

%% 玩家申请次数判断      
has_apply_count(UserId, Type) ->
	Pattern			= #group_apply{user_id = UserId, state = 3, _ = '_'},
	ApplyList		= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern),
	ApplyNum		= erlang:length(ApplyList),
	if
		ApplyNum < ?CONST_GROUP_MAX_APPLY_PLAYER -> ?true;
		?true ->                                         %% 玩家申请次数不足
			case Type of
				?CONST_SYS_FALSE ->	throw({?error, ?TIP_GROUP_APPLY_TIME_OVER});
				?CONST_SYS_TRUE  -> ?true
			end
	end.

%% 判读队伍是否存在
is_group_exist(GroupId) when is_number(GroupId) andalso GroupId > ?CONST_SYS_FALSE ->
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		?null ->
			throw({?error, ?TIP_GROUP_NOT_EXIST});
		_Group ->           %% 队伍存在
			?true
	end.
			
%% 队伍是否满
is_group_full(GroupId) ->
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		 Group when is_record(Group, group) andalso Group#group.in_group_num < ?CONST_GROUP_MAX_MEMBER_COUNT ->
			?true;
		_ ->          %% 队伍已满
			throw({?error, ?TIP_GROUP_IS_FULL})
	end.

%% 玩家是否已经在队伍
is_in_group(UserId) ->
	case get_group_apply_list(UserId, 2) of
		[] -> ?true;
		_  -> throw({?error, ?TIP_GROUP_IN_GROUP})            %% 在队伍中
	end.

is_in_group1(UserId) ->
	case get_group_apply_list(UserId, 2) of
		[] -> ?false;
		_  -> ?true            								  %% 在队伍中
	end.
%% 对方是否已经在队伍
is_in_group2(OtherId) ->
	case get_group_apply_list(OtherId, 2) of
		[] -> ?true;
		_  -> throw({?error, ?TIP_GROUP_IN_GROUP1})            %% 对方已在在队伍中
	end.

is_not_in_group(UserId) ->
	case get_group_apply_list(UserId, 2) of
		[] -> throw({?error, ?TIP_GROUP_USER_NOT_IN_GROUP});    %% 不在队伍中
		_  -> ?true            								  
	end.

%% 队伍申请次数判断
has_be_applied_count(Player, GroupId) ->
	case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
		Group when is_record(Group, group) andalso Group#group.apply_mount < ?CONST_GROUP_MAX_APPLY_GROUP ->
			?true;
		_ ->
			TipPacket	= message_api:msg_notice(?TIP_GROUP_APPLIED_MAX),
			misc_packet:send(Player#player.net_pid, TipPacket),
			throw({?error, ?TIP_GROUP_APPLIED_MAX})
	end.

%% 是否在申请状态
is_applying_group(UserId, GroupId) ->
	Pattern		= #group_apply{user_id = UserId, group_id = GroupId, state = 3, _ = '_'},
	GroupTemp	= ets:match_object(?CONST_ETS_GROUP_APPLY, Pattern),
	case erlang:length(GroupTemp) =:= ?CONST_SYS_FALSE of
		?true ->
			throw({?error, ?TIP_GROUP_NOT_APPLYING});
		?false ->
			?true
	end.

%% 是否同在一个队伍
is_same_group(UserId, KickOutId) ->
	GroupId1		= case get_group_apply_list(UserId, 2) of
						  [] 		 -> ?CONST_SYS_FALSE;
						  GroupApply1 -> GroupApply1#group_apply.group_id
					  end,
	GroupId2		= case get_group_apply_list(KickOutId, 2) of
						  [] 		 -> ?CONST_SYS_FALSE;
						  GroupApply2 -> GroupApply2#group_apply.group_id
					  end,
	case GroupId1 =:= GroupId2 of
		?true  -> ?true;
		?false -> throw({?error, ?TIP_COMMON_BAD_ARG})
	end.

%% 判断是否待组
is_waiting_group(UserId) ->
	GroupApply		= get_group_apply_list1(UserId, 4),
	case GroupApply =:= [] of 
		?true  -> ?true;
		?false -> throw({?error, ?TIP_GROUP_WAITING_STATE})		    %% 已经是待组状态	
	end.

%% 判断对方是否开启了组队模块
is_open(UserId) ->
	case player_sys_api:is_open_sys(UserId, ?CONST_MODULE_GROUP) of
		?true -> ?true;
		?false -> throw({?error, ?TIP_GROUP_NOT_OPEN})
	end.
%%------------------------------------------------------------------------------------------------------------------------
%% 计算buffer
calculate_group_buff(UserId, Info) ->
    case get_group_by_user_id(UserId) of
        Group when is_record(Group, group) ->
            calculate_level_buffer(UserId, Info, Group);
        ?null ->
            []
    end.

%% 根据等级要求计算buffer
calculate_level_buffer(UserId, Info, Group) when is_record(Group, group)->
	MemberList		= Group#group.member_list,
	NewMemberList	= lists:delete({UserId}, MemberList),
    Lv              = Info#info.lv,
    calculate_level_buffer2(Lv, NewMemberList, []).
			
calculate_level_buffer2(Lv, [{MemberUserId}|Tail], Buff) ->
    {_MemberUserId, Name, RateLv, Type, Buff2, RateType} = get_level_buffer(Lv, MemberUserId),
    calculate_level_buffer2(Lv, Tail, [{_MemberUserId, Name, RateLv, Type, Buff2, RateType}|Buff]); 
calculate_level_buffer2(_Lv, [], Buff) ->
    Buff.

%% 读取等级加成
%% {MemberUserId, Name, RateLv, Type, Buff, RateType}
get_level_buffer(Lv1, MemberUserId) ->
	case player_api:get_player_fields(MemberUserId, [#player.info, #player.attr]) of
		{?ok, [#info{lv = Lv2, user_name = Name, pro = Pro}, AttrSum]} ->
            RateLv  		= calc_lv_buff(Lv1, Lv2),
            RateType		= get_lv_type(RateLv),
            Type    		= get_pro_type(Pro),
			case AttrSum of
				?null ->
					{MemberUserId, Name, RateLv, Type, ?CONST_SYS_FALSE, RateType};
				_ ->
            		Buff    	= player_attr_api:attr_multi_single(AttrSum, Type, RateLv, 
																	?CONST_SYS_NUMBER_TEN_THOUSAND),
            		{MemberUserId, Name, RateLv, Type, Buff, RateType}
			end;	
        _ ->
            {MemberUserId, <<>>, 0, 0, 0, 0}
	end.

calc_lv_buff(Lv1, Lv2) when Lv1 =< Lv2 ->          
	DiffLv		= Lv2 - Lv1,
    get_lv_rate(DiffLv);
calc_lv_buff(Lv1, Lv2) ->
    DiffLv  	= Lv1 - Lv2,
    get_lv_rate(DiffLv).

get_lv_rate(Lv) when Lv =< 5  -> ?CONST_GROUP_RATE_LESS_5;
get_lv_rate(Lv) when Lv =< 10 -> ?CONST_GROUP_RATE_5_10;
get_lv_rate(_Lv)              -> ?CONST_GROUP_RATE_LARGER_10.

%% 属性类型
get_pro_type(?CONST_SYS_PRO_XZ) -> ?CONST_PLAYER_ATTR_HP_MAX;           % 陷阵加hp_max
get_pro_type(?CONST_SYS_PRO_FJ) -> ?CONST_PLAYER_ATTR_FORCE_ATTACK;     % 飞军加物攻
get_pro_type(?CONST_SYS_PRO_TJ) -> ?CONST_PLAYER_ATTR_MAGIC_ATTACK.     % 天机加法攻

%% 计算组队加成比例
calc_group_buffer(#player{user_id = UserId} = Player, [{MemberUserId}|Tail], MemberList) when UserId =:= MemberUserId -> % 玩家
    Info            = Player#player.info,
    GroupBuffList   = calculate_group_buff(UserId, Info),
	NewGroupBuffList= get_group_buff(GroupBuffList, []),
    AttrReflect     = Player#player.attr_reflect,
    AttrReflect2    = AttrReflect#attr_reflect{group = NewGroupBuffList},
    Player2         = Player#player{attr_reflect = AttrReflect2},
    Packet          = group_api:msg_sc_buffer(Player2),
    group_api:broadcast_to_member(MemberList, Packet),
    Player3         = player_attr_api:refresh_group(Player2, NewGroupBuffList),
    calc_group_buffer(Player3, Tail, MemberList);
calc_group_buffer(Player, [{MemberUserId}|Tail], MemberList) -> % 其他在线玩家
    player_api:process_send(MemberUserId, group_api, calc_group_buffer_cb, [MemberList]),
    calc_group_buffer(Player, Tail, MemberList);
calc_group_buffer(Player, [], _MemberList) ->
    {?ok, Player}.

get_group_buff([{_UserId, _, _, 0, _Value, _}|BuffList], Acc) ->
	NewAcc	= Acc,
	get_group_buff(BuffList, NewAcc);
get_group_buff([{UserId, _, _, Type, Value, _}|BuffList], Acc) ->
	NewAcc	= [{UserId, Type, Value}|Acc],
	get_group_buff(BuffList, NewAcc);
get_group_buff([], Acc) ->
	Acc.

%% %% 获取队伍列表
%% get_in_group_member(UserId) ->
%% 	case get_group_apply_list(UserId, 2) of
%% 		?null -> [];
%% 		GroupApply ->
%% 			GroupId			= GroupApply#group_apply.group_id,
%% 			case ets_api:lookup(?CONST_ETS_GROUP, GroupId) of
%% 				?null -> [];
%% 				Group ->
%% 					Group#group.member_list
%% 			end
%% 	end.
    
%%-------------------------队伍对我的加成，我不在队伍中--------------------------------------------------------
calc_buff_group2me(_Info, 0) -> {[], <<>>};
calc_buff_group2me(Info, GroupId) ->
    MemberList 	= get_group_user_ids(GroupId),
    Lv      	= Info#info.lv,
    ListLv  	= calculate_level_buffer2(Lv, MemberList, []),
    Packet  	= packet_buff(1, ListLv),
    {ListLv, Packet}.

calc_buff_me2group(_UserId, _Info, 0) -> {[], <<>>};
calc_buff_me2group(_UserId, _Info, _UserId) ->{[], <<>>};
calc_buff_me2group(UserId, Info, UserIdW) ->
	case get_group_apply(UserId) of
		?null      ->	{[], <<>>};
		GroupApply ->
			GroupId 	= GroupApply#group_apply.group_id,
			MemberList 	= get_group_user_ids(GroupId),
			Lv      	= Info#info.lv,
			ListLv  	= calculate_level_buffer2(Lv, [{UserIdW}], []),
			Packet  	= packet_buff(2, ListLv),
			
			MemberNum	= erlang:length(MemberList),
			if
				MemberNum	=:= 1 ->
					{ListLv, Packet};
				MemberNum	=:= 2 ->
					[{UserId2}] 	= lists:delete({UserId}, MemberList),
					GroupApply2 	= get_group_apply(UserId2),
					Lv2     		= GroupApply2#group_apply.lv,
					ListLv2 		= calculate_level_buffer2(Lv2, [{UserIdW}], []),
					Packet2 		= packet_buff(2, ListLv2),
					
					ListLvTotal	 	= ListLv ++ ListLv2,
					PacketTotal 	= <<Packet/binary, Packet2/binary>>,
					{ListLvTotal, PacketTotal};
				MemberNum	=:= 3 ->
					MemberList1		= lists:delete({UserId}, MemberList),
					[{UserId2}|_]   = MemberList1,
					[{UserId3}]		= lists:delete({UserId2}, MemberList1),
					
					GroupApply2 	= get_group_apply(UserId2),
					Lv2     		= GroupApply2#group_apply.lv,
					ListLv2 		= calculate_level_buffer2(Lv2, [{UserIdW}], []),
					Packet2 		= packet_buff(2, ListLv2),
						
					GroupApply3 	= get_group_apply(UserId3),
					Lv3				= GroupApply3#group_apply.lv,
					ListLv3			= calculate_level_buffer2(Lv3, [{UserIdW}], []),
					Packet3			= packet_buff(2, ListLv3),
					ListLvTotal		= ListLv ++ ListLv2 ++ ListLv3,
					PacketTotal		= <<Packet/binary, Packet2/binary, Packet3/binary>>,
					{ListLvTotal, PacketTotal};
				?true ->
					{[], <<>>}
			end
	end.
			
packet_buff(ShowType, List) ->
    packet_buff(ShowType, List, <<>>).
packet_buff(1, [{UserId, Name, _RateLv, Type, Buff2, TypeLv}|Tail], Packet) ->
    PacketGroup 	= group_api:msg_sc_temp_buffer(1, UserId, Name, Type, Buff2, TypeLv),
    Packet2 		= <<Packet/binary, PacketGroup/binary>>,
    packet_buff(1, Tail, Packet2);
packet_buff(2, [{UserId, Name, _RateLv, Type, Buff2, TypeLv}|Tail], Packet) ->
    PacketGroup 	= group_api:msg_sc_temp_buffer(2, UserId, Name, Type, Buff2, TypeLv),
    Packet2 		= <<Packet/binary, PacketGroup/binary>>,
    packet_buff(2, Tail, Packet2);
packet_buff(_, [], Packet) ->
    Packet.

%% 发给前端用的等级差类型
get_lv_type(?CONST_GROUP_RATE_LESS_5)      -> 1;
get_lv_type(?CONST_GROUP_RATE_5_10)  	   -> 2;
get_lv_type(?CONST_GROUP_RATE_LARGER_10)   -> 3.

%%--------------------------------------------------------------------------------------------------------------
%% 读取常规组队成员信息
get_group_apply(UserId) ->
	case get_group_apply_list(UserId, 2) of
		GroupApply when is_record(GroupApply, group_apply) ->
			 GroupApply;
		_ -> ?null
	end.

%% 读取常规组队信息
get_group(GroupId) when is_number(GroupId) ->
    ets_api:lookup(?CONST_ETS_GROUP, GroupId);
get_group(GroupApply) when is_record(GroupApply, group_apply) ->
    GroupId = GroupApply#group_apply.group_id,
    get_group(GroupId).

get_group_by_user_id(UserId) ->
    case get_group_apply(UserId) of
        GroupApply when is_record(GroupApply, group_apply) ->
            get_group(GroupApply);
        ?null -> ?null
    end.

%% 获取玩家
get_player(UserId) ->
	case player_api:get_player_first(UserId) of
		{?ok, ?null, _} ->
			throw({?error, ?TIP_COMMON_SYS_ERROR});
		{?ok, Player, _} ->
			Player
	end.

%% 读取队伍中的玩家id列表
%% [{UserId},...]
get_group_user_ids(GroupId) ->
    Group 	= get_group(GroupId),
    Group#group.member_list.

