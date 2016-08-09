%% Author: Administrator
%% Created: 2013-5-14
%% Description: TODO: Add description to relation_mod
-module(relation_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([
 		 ets_relation_data/1, 
		 insert_relation_data/1,
		 
		 ets_relation_be/1,
		 add_relation_handle/3,
		 del_relation_handle/3,
		
	 	 relation_count/1,
 		 friend_list/2,
		 add_relation/4,
		 add_contact/2,
		 delete_friend/3,
		 delete_contact/2,
		 change/4,
		 recomm_list/1,
		 one_key_add_friend/2,
		 one_key_del/3
		 ]). 

%%
%% API Functions
%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 关系人 -- 在线人数数量/总人数
relation_count(UserId) ->
	RelationData	= ets_relation_data(UserId),
	Packet1			= relation_count2(RelationData,?CONST_RELATIONSHIP_BRELA_FRIEND),
	Packet2			= relation_count2(RelationData,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND),
	Packet3			= relation_count2(RelationData,?CONST_RELATIONSHIP_BRELA_BLACK_LIST),
	Packet4			= relation_count2(RelationData,?CONST_RELATIONSHIP_BRELA_CONTACTED),
	Packet			= <<Packet1/binary,Packet2/binary,Packet3/binary,Packet4/binary>>,
	Packet.
	
relation_count2(RelationData,Type) ->	
	List			= get_list_by_type(RelationData,Type),
	Count		 	= get_online_num(List,0),	
	relation_api:msg_sc_count(Type,Count,length(List)).


get_online_num([UserId|List],Count) ->
	case player_api:check_online(UserId) of
		?true -> get_online_num(List,Count+1);
		?false -> get_online_num(List,Count)
	end;
get_online_num([],Count) -> Count.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 好友列表
friend_list(UserId,Type) ->
	RelationData	= ets_relation_data(UserId),
	List			= get_list_by_type(RelationData,Type),
	{?ok,InfoList,FList} = friend_info(UserId,Type,List),
	if
		length(List) =:= length(FList) -> ?ok;
		?true ->
			RelationData2	= set_list_by_type(RelationData,FList,Type),
			insert_relation_data(RelationData2)
	end,
 	relation_api:msg_sc_list(Type,InfoList).

%% 好友信息
friend_info(UserId,Type,List) ->
	friend_info(UserId,Type,List,[],[]).

friend_info(_,_,[],List,Flist) ->
	{?ok,List,Flist};
friend_info(UserId,Type,[Relation|L],List,Flist) ->
	MemId	= Relation#relation.mem_id,
	case friend_info2(MemId) of
		{?error,?TIP_COMMON_NO_THIS_PLAYER} ->
			delete_relation_be(MemId,UserId,Type),
			friend_info(UserId,Type,L,List,Flist);
		{?error,_ErrorCode} ->
			friend_info(UserId,Type,L,List,[Relation|Flist]);
		Data ->
			friend_info(UserId,Type,L,[Data|List],[Relation|Flist])
	end.

friend_info2(MemId) ->
	case player_api:get_player_fields(MemId, [#player.info, #player.guild]) of
		{?ok, [#info{sex = Sex, user_name = Name, pro = Pro, lv = Lv, 
					 time_last_off = TimeActive,vip = Vip,power = Power}, Guild]} ->
			VipLv		= Vip#vip.lv,
			GuildName 	= guild_api:get_guild_name(Guild),
			OnlineTime 	= case player_api:check_online(MemId) of
							  ?true -> 0;
							  _ -> abs(misc:seconds() - TimeActive)
						  end,
			if
				OnlineTime > 864000 andalso VipLv =:= 0 andalso Lv < 30 -> %% 超过10天-视为流失 
					{?error,?TIP_COMMON_NO_THIS_PLAYER};
				?true ->
					{MemId, Name, Pro, Sex, Lv, GuildName, VipLv,Power,OnlineTime}
			end;
		_ -> {?error,?TIP_COMMON_BAD_ARG}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
ets_relation_data(UserId) ->
	case ets_api:lookup(?CONST_ETS_RELATION_DATA, UserId) of
		?null -> 
			init_relation_data(UserId);
		Relation ->
			Relation
	end.

insert_relation_data(Relation) ->
	ets_api:insert(?CONST_ETS_RELATION_DATA, Relation).

ets_relation_be(UserId) -> 
	case ets_api:lookup(?CONST_ETS_RELATION_BE, UserId) of
		?null -> 
			init_relation_be(UserId);
		 RelationBe ->
			RelationBe
	end.

insert_relation_be(RelationBe) -> 
	ets_api:insert(?CONST_ETS_RELATION_BE, RelationBe).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_relation_be(UserId,MemId,Type) when is_number(UserId) andalso is_number(MemId) ->
	relation_serv:relation_be_add_cast(UserId,MemId,Type).

add_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	RelationBe 	= ets_relation_be(UserId),
	BeBlack		= delete_member(MemId,RelationBe#relation_be.be_black),
	BeBest		= delete_member(MemId,RelationBe#relation_be.be_best),
	BeFriend	= add_member(MemId,RelationBe#relation_be.be_friend),
	RelationBe2	= RelationBe#relation_be{
										 be_black 	= BeBlack,
										 be_best	= BeBest,
										 be_friend	= BeFriend
										 },
	insert_relation_be(RelationBe2);
add_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND) ->
	RelationBe 	= ets_relation_be(UserId),
	BeBlack		= delete_member(MemId,RelationBe#relation_be.be_black),
	BeFriend	= delete_member(MemId,RelationBe#relation_be.be_friend),
	BeBest		= add_member(MemId,RelationBe#relation_be.be_best),
	RelationBe2	= RelationBe#relation_be{
										 be_black 	= BeBlack,
										 be_best	= BeBest,
										 be_friend	= BeFriend
										 },
	insert_relation_be(RelationBe2);
add_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	RelationBe 	= ets_relation_be(UserId),
	BeFriend	= delete_member(MemId,RelationBe#relation_be.be_friend),
	BeBest		= delete_member(MemId,RelationBe#relation_be.be_best),
	BeBlack		= add_member(MemId,RelationBe#relation_be.be_black),
	RelationBe2	= RelationBe#relation_be{
										 be_black 	= BeBlack,
										 be_best	= BeBest,
										 be_friend	= BeFriend
										 },
	insert_relation_be(RelationBe2);
add_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_CONTACTED) ->
	RelationBe 	= ets_relation_be(UserId),
	BeContact	= add_member(MemId,RelationBe#relation_be.be_contact),
	RelationBe2	= RelationBe#relation_be{
										 be_contact = BeContact
										 },
	insert_relation_be(RelationBe2);
add_relation_handle(_UserId,_MemId,_) ->
	?ok.


delete_relation_be(UserId,MemId,Type) ->
	relation_serv:relation_be_del_cast(UserId,MemId,Type).  

del_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	RelationBe 	= ets_relation_be(UserId),
	BeFriend	= delete_member(MemId,RelationBe#relation_be.be_friend),
	RelationBe2	= RelationBe#relation_be{be_friend	= BeFriend},
	insert_relation_be(RelationBe2);
del_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND) ->
	RelationBe 	= ets_relation_be(UserId),
	BeBest		= delete_member(MemId,RelationBe#relation_be.be_best),
	RelationBe2	= RelationBe#relation_be{be_best	= BeBest},
	insert_relation_be(RelationBe2);
del_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	RelationBe 	= ets_relation_be(UserId),
	BeBlack		= delete_member(MemId,RelationBe#relation_be.be_black),
	RelationBe2	= RelationBe#relation_be{be_black	= BeBlack},
	insert_relation_be(RelationBe2);
del_relation_handle(UserId,MemId,?CONST_RELATIONSHIP_BRELA_CONTACTED) ->
	RelationBe 	= ets_relation_be(UserId),
	BeBlack		= delete_member(MemId,RelationBe#relation_be.be_contact),
	RelationBe2	= RelationBe#relation_be{be_contact	= BeBlack},
	insert_relation_be(RelationBe2);
del_relation_handle(_UserId,_MemId,_) ->
	?ok.

add_member(MemId,List) when is_number(MemId)->
	case lists:member(MemId, List) of
		?false ->
			[MemId|List];
		_ ->
			List
	end.

delete_member(MemId,List) ->
	lists:delete(MemId,List).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_relation(Player, ?CONST_RELATIONSHIP_BRELA_FRIEND, MemId, Name) ->
	add_friend(Player, MemId, Name);
add_relation(Player, ?CONST_RELATIONSHIP_BRELA_BLACK_LIST, MemId, Name) ->
	add_balck(Player, MemId, Name);
add_relation(_,_,_,_) ->
	{?error,?TIP_COMMON_BAD_ARG}.

%% 发送添加好友请求     类型(1 => 常规加好友, 2 => 从黑名单里加好友)
add_friend(Player, 0, Name) ->
	case player_api:get_user_id(Name) of 
		{?ok,MemId} ->
			add_friend(Player, MemId, Name);
		{?error,ErrorCode} ->
			{?error,ErrorCode}
	end;
add_friend(Player, MemId, _Name) ->
	add_friend(Player, MemId).

add_friend(Player = #player{user_id = UserId,info = Info, sys_rank = Sys,net_pid = Pid}, MemId) ->
	try
		RelationData	 	= ets_relation_data(UserId),
		FriendList			= RelationData#relation_data.friend_list,
		BestList			= RelationData#relation_data.best_list,
		BackList			= RelationData#relation_data.black_list,
		Count 				= length(FriendList) + length(BestList),
		
		?ok					= check_user_id(UserId,MemId),
		?ok					= check_user_sys(Sys),	
		?ok					= check_friend_list(MemId,FriendList),
		?ok					= check_best_list(MemId,BestList),
		?ok					= check_black_list(MemId,BackList),
		?ok					= check_friend_count(Count,player_api:get_vip_lv(Info)), 
		
		Flag				= case player_api:check_online(MemId) of
								  ?true -> ?CONST_SYS_TRUE;
								  ?false -> ?CONST_SYS_FALSE
							  end,
 		RData				= init_relation(MemId),		
		FriendList2 		= [RData|FriendList],
		RelationData2		= RelationData#relation_data{friend_list 	= FriendList2},	
		
 		add_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_FRIEND),
		insert_relation_data(RelationData2),
		
		add_friend_notice(UserId,MemId,Info,Flag),		 
		Packet14512			= add_one_relation(1,?CONST_RELATIONSHIP_BRELA_FRIEND,MemId),
		misc_packet:send(Pid, Packet14512),
		add_achievement(Player,Count + 1)
	
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

add_achievement(Player,Count) ->
	{?ok, Player2} 		= achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_FRIEND, Count, 1),
	{?ok, Player3} 		= welfare_api:add_pullulation(Player2, ?CONST_WELFARE_FRIEND, Count, 1),
	{?ok, Player3}.

add_one_relation(SubType,Type,MemId) ->
	case friend_info2(MemId) of
		{?error,_ErrorCode} -> <<>>;
		{MemId, Name, Pro, Sex, Lv, GuildName, Vip,Power,OnlineTime} ->
			relation_api:msg_sc_add(Type,SubType,MemId, Name, Pro, Sex, Lv, GuildName, Vip,Power,OnlineTime)
	end.

is_relation(RelationBe,MemId) ->
	try
		?false 	= lists:member(MemId, RelationBe#relation_be.be_friend),
		?false 	= lists:member(MemId, RelationBe#relation_be.be_black),
		?false 	= lists:member(MemId, RelationBe#relation_be.be_best),
		?false
	catch
		_:_ -> ?true
	end.	


add_friend_notice(_UserId,_MemId,_Info,?CONST_SYS_FALSE) ->
	?ok;
add_friend_notice(UserId,MemId,Info,_Flag) ->
	RelationBe			= ets_relation_be(UserId),	
  	case is_relation(RelationBe,MemId) of
		?false ->
			RelationData	 	= ets_relation_data(MemId),
			FriendList			= RelationData#relation_data.friend_list,
			BestList			= RelationData#relation_data.best_list,
			Count 				= length(FriendList) + length(BestList),
            SysRank = data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP),
			case player_api:get_player_fields(MemId, [#player.info, #player.sys_rank]) of
        		{?ok, [TInfo, Sys]} when Sys >= SysRank ->
					Vip     			= player_api:get_vip_lv(TInfo),
					CountMax			= get_num_max(Vip),
					if
						Count < CountMax ->
							Sex			= Info#info.sex,
							UserName    = Info#info.user_name,
							Pro     	= Info#info.pro,
							Lv      	= Info#info.lv,
							VipLv     	= player_api:get_vip_lv(Info),
							Packet 		= relation_api:msg_add_notice(UserId,UserName,Pro,Sex,Lv,VipLv),
							misc_packet:send(MemId, Packet);
						?true -> ?ok
					end;
				_ -> ?ok
			end;		 
		_ -> ?ok
	end.
	
%% list_key_delete(MemId,List) ->
%% 	case lists:keytake(MemId, #relation.mem_id, List) of
%% 		?false ->
%% 			List;
%% 		{value,_,List2} ->
%% 			List2
%% 	end.

check_friend_count(Num,Vip) ->
	Max = get_num_max(Vip),
	if
		Num < Max -> ?ok;
		?true -> 
			throw({?error,?TIP_RELATION_COUNT})
	end.

get_num_max(Vip) ->
 	?CONST_RELATIONSHIP_MAX_FRIENDS + player_vip_api:get_friends_max(Vip).

check_user_id(UserId,UserId) ->
	throw({?error,?TIP_COMMON_BAD_ARG});
check_user_id(_,_) -> ?ok.

check_user_sys(Sys)  ->
    case Sys >= data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP) of
        true ->
	       ?ok;
        false ->
            throw({?error,?TIP_RELATION_SYS})
    end.

check_friend_list(MemId,List) ->
	case lists:keyfind(MemId, #relation.mem_id, List) of
		?false ->
			?ok;
		_ ->
			throw({?error,?TIP_RELATION_FRIEND})
	end.

check_best_list(MemId,List) ->
	case lists:keyfind(MemId, #relation.mem_id, List) of
		?false ->
			?ok;
		_ ->
			throw({?error,?TIP_RELATION_BEST})
	end.

check_black_list(MemId,List) ->
	case lists:keyfind(MemId, #relation.mem_id, List) of
		?false ->
			?ok;
		_ ->
			throw({?error,?TIP_RELATION_BLACK})
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
add_balck(Player, 0, Name) ->
	case player_api:get_user_id(Name) of 
		{?ok,MemId} ->
			add_balck(Player, MemId, Name);
		{?error,ErrorCode} ->
			{?error,ErrorCode}
	end;
add_balck(Player, MemId, _Name) ->
	add_balck(Player, MemId).

add_balck(Player = #player{user_id = UserId,sys_rank = Sys,net_pid = Pid}, MemId) ->
	try
		RelationData	 	= ets_relation_data(UserId),
		FriendList			= RelationData#relation_data.friend_list,
		BestList			= RelationData#relation_data.best_list,
		BackList			= RelationData#relation_data.black_list,
		Count				= length(BackList),
		
		?ok					= check_user_id(UserId,MemId),
		?ok					= check_user_sys(Sys),
		
		?ok					= check_friend_list(MemId,FriendList),
		?ok					= check_best_list(MemId,BestList),
		?ok					= check_black_list(MemId,BackList),
		?ok					= check_black_count(Count), 
		
 		RData				= init_relation(MemId),		
		BackList2 			= [RData|BackList],
		RelationData2		= RelationData#relation_data{
														 black_list		= BackList2
														 },	
		
 		add_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST),
		insert_relation_data(RelationData2),
		Packet14512			= add_one_relation(1,?CONST_RELATIONSHIP_BRELA_BLACK_LIST,MemId),
		misc_packet:send(Pid, Packet14512),
		{?ok, Player}
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.

check_black_count(Count) when Count >= ?CONST_RELATIONSHIP_MAX_BLACK_LIST ->
	throw({?error,?TIP_RELATION_BLACK_COUNT});
check_black_count(_Count) -> ?ok.
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 添加最近联系人
add_contact(UserId, MemId) ->
	try
		RelationData 		= ets_relation_data(UserId),
		ContactList			= RelationData#relation_data.contact_list,
		RData				= init_relation(MemId),
		case lists:keytake(MemId, #relation.mem_id, ContactList) of
			?false ->
				ContactList3 	= get_contact_list(UserId,MemId,RData,ContactList),
				Packet14512 	= add_one_relation(1,?CONST_RELATIONSHIP_BRELA_CONTACTED,MemId),
				misc_packet:send(UserId, Packet14512);
			{value,_,List2} ->
				ContactList3 	= [RData|List2] 
		end,
		RelationData2		= RelationData#relation_data{
														 contact_list 	= ContactList3
														 },	
		insert_relation_data(RelationData2),
		add_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_CONTACTED)
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	

get_contact_list(UserId,_MemId,RData,ContactList) ->
	if
		length(ContactList) < ?CONST_RELATIONSHIP_MAX_CONTACT -> 
			[RData|ContactList];
		?true ->
			{ContactList2,DList} = lists:split(?CONST_RELATIONSHIP_RECOMM_N-1, ContactList),
			delete_contact2(UserId,DList), 
			[RData|ContactList2]
	end.

delete_contact(_UserId, []) ->
	?ok;
delete_contact(UserId,[MemId | List]) ->
	delete_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_CONTACTED),
	delete_contact(UserId,List).

delete_contact2(_UserId,[]) ->
	?ok;
delete_contact2(UserId,[#relation{mem_id = MemId} | List]) ->
	Packet = relation_api:msg_sc_delete(?CONST_RELATIONSHIP_BRELA_CONTACTED,MemId),
	misc_packet:send(UserId, Packet),
	delete_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_CONTACTED),
	delete_contact(UserId,List).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 删除好友(密友不能直接删除)
delete_friend(UserId,MemId,Type) ->
	RelationData 		= ets_relation_data(UserId),
	List				= get_list_by_type(RelationData,Type),
	case lists:keytake(MemId, #relation.mem_id, List) of
		?false -> %% 不在列表中
			{?error,?TIP_RELATION_NOT_FRIEND};
		{value, _, List2} ->
			RelationData2 	= set_list_by_type(RelationData,List2,Type),
			delete_relation_be(MemId,UserId,Type),
			insert_relation_data(RelationData2),
			?ok
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_list_by_type(RelationData,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	RelationData#relation_data.friend_list;
get_list_by_type(RelationData,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND) ->
	RelationData#relation_data.best_list;
get_list_by_type(RelationData,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	RelationData#relation_data.black_list;
get_list_by_type(RelationData,?CONST_RELATIONSHIP_BRELA_CONTACTED) ->
	RelationData#relation_data.contact_list.

set_list_by_type(RelationData,List,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	RelationData#relation_data{friend_list = List};
set_list_by_type(RelationData,List,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND) ->
	RelationData#relation_data{best_list = List};
set_list_by_type(RelationData,List,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	RelationData#relation_data{black_list = List};
set_list_by_type(RelationData,List,?CONST_RELATIONSHIP_BRELA_CONTACTED) ->
	RelationData#relation_data{contact_list = List}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 关系转换
change(Player = #player{user_id = UserId,info = Info},Type,MemId,ToType) ->
	try
		RelationData 		= ets_relation_data(UserId),
		List				= get_list_by_type(RelationData,Type),
		{?ok,RData, List2}	= get_keytake(MemId,List),

		?ok					= check_change_count(Type,RelationData,player_api:get_vip_lv(Info),ToType),
		ToList				= get_list_by_type(RelationData,ToType),
		ToList2				= add_one_in_list(RData,ToList),
		RelationData2 		= set_list_by_type(RelationData,List2,Type),
		RelationData3 		= set_list_by_type(RelationData2,ToList2,ToType),
			
		insert_relation_data(RelationData3),
		add_relation_be(MemId,UserId,ToType),
		Count 				= length(ToList2),
		Packet14522			= relation_api:msg_sc_change(Type,MemId,ToType),
		misc_packet:send(UserId, Packet14522),
		case ToType of 
			?CONST_RELATIONSHIP_BRELA_FRIEND ->
				add_achievement(Player,Count);
			?CONST_RELATIONSHIP_BRELA_BEST_FRIEND ->
				achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_INTIMATE, Count, 1);
			_ ->
				{?ok,Player}
		end

	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.	

get_keytake(MemId,List) ->
	case lists:keytake(MemId, #relation.mem_id, List) of 
		?false ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		{value, RData, List2} ->
			{?ok,RData, List2}
	end.

check_change_count(?CONST_RELATIONSHIP_BRELA_BLACK_LIST,RelationData,Vip,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	Count = length(RelationData#relation_data.friend_list) + length(RelationData#relation_data.best_list),
	check_friend_count(Count,Vip);
check_change_count(_,RelationData,_,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	Count = length(RelationData#relation_data.black_list),
	check_black_count(Count);
check_change_count(_,_,_,_) -> ?ok.

add_one_in_list(RData,ToList) ->
	case lists:keytake(RData#relation.mem_id, #relation.mem_id, ToList) of
		?false ->
			[RData|ToList];
		_ ->
			ToList
	end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 好友推荐列表
recomm_list(#player{user_id = UserId,info = Info}) ->	
	try
		RelationData		= ets_relation_data(UserId),	
		FriendList			= RelationData#relation_data.friend_list,
		BestList			= RelationData#relation_data.best_list,
		BlackList			= RelationData#relation_data.black_list,	
		List 				= FriendList ++ BestList ++ BlackList,	
		FList				= [MemId || #relation{mem_id = MemId} <- List],
		?ok					= check_friend_count(length(BestList) + length(FriendList),player_api:get_vip_lv(Info)),
		recomm_list2(UserId,FList)
	catch
		throw:Return ->
			Return;
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()]),
			{?error,?TIP_COMMON_BAD_ARG}
	end.			 	

recomm_list2(UserId,FList) ->
	FirstKey 			= ets:first(?CONST_ETS_PLAYER_ONLINE),	
	ListRecomm 			= case get_recomm_list(FirstKey,UserId,FList,[]) of
							  MList when length(MList) =< ?CONST_RELATIONSHIP_RECOMM_N ->
								  MList;
							  MList ->
								  misc_random:random_list_norepeat(MList, ?CONST_RELATIONSHIP_RECOMM_N )
						  end,
	Packet				= relation_api:msg_sc_recommend(ListRecomm),
	misc_packet:send(UserId, Packet).

get_recomm_list('$end_of_table',_,_FList,MList) ->
	MList;
get_recomm_list(UserId,UserId,FList,MList) ->
	Next 		= ets:next(?CONST_ETS_PLAYER_ONLINE, UserId),
	get_recomm_list(Next,UserId,FList,MList);
get_recomm_list(Key,UserId,FList,MList) ->
	MList2		= case player_api:check_online(Key) of
					  ?true ->
					  		get_recomm_list2(Key, FList ,MList);
					  _ -> MList
				  end,	
	if
		length(MList2) >= ?CONST_RELATIONSHIP_RECOMM_N * 2 ->
			MList2;
		?true ->
			Next 		= ets:next(?CONST_ETS_PLAYER_ONLINE, Key),
			get_recomm_list(Next,UserId,FList,MList2)
	end.

get_recomm_list2(Key, FList ,MList) ->
	case lists:member(Key, FList) of
		?false ->
            SysRank = data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP),
			case player_api:get_player_fields(Key, [#player.info, #player.sys_rank, #player.guild]) of
        		{?ok, [#info{sex = Sex, user_name = Name, pro = Pro, lv = Lv, vip = Vip, power = Power}, Sys, Guild]} 
		 			 when Sys >= SysRank ->
						VipLv	= Vip#vip.lv,	
						GuildN	= guild_api:get_guild_name(Guild),
            			[{Key, Name, Pro, Sex, Lv, GuildN, VipLv, Power, 0} | MList];
        		_ -> MList
			end;
		_ ->  MList
    end.

%% get_recomm_lv_list('$end_of_table',_,_FList,MList) ->
%% 	MList;
%% get_recomm_lv_list(UserId,UserId,FList,MList) ->
%% 	Next 		= ets:next(?CONST_ETS_PLAYER_ONLINE, UserId),
%% 	get_recomm_lv_list(Next,UserId,FList,MList);
%% get_recomm_lv_list(Key,UserId,FList,MList) ->
%% 	MList2		= get_recomm_lv_list2(Key, FList ,MList),
%% 	if
%% 		length(MList2) >= ?CONST_RELATIONSHIP_RECOMM_N * 2 ->
%% 			MList2;
%% 		?true ->
%% 			Next 		= ets:next(?CONST_ETS_PLAYER_ONLINE, Key),
%% 			get_recomm_list(Next,UserId,FList,MList2)
%% 	end.
%% 
%% get_recomm_lv_list2(Key, FList ,MList) ->
%% 	case lists:member(Key, FList) of
%% 		?false ->
%% 			case player_api:get_player_first(Key) of
%%         		{?ok, #player{info = Info,sys = Sys,guild = Guild}, ?CONST_PLAYER_ONLINE} 
%% 		 			 when Sys >= ?CONST_MODULE_RELATIONSHIP andalso ?CONST_RELATIONSHIP_DELTA_LV
%% 						Name 	= Info#info.user_name,
%%             			Sex 	= Info#info.sex,
%%             			Pro 	= Info#info.pro,
%%             			Lv 		= Info#info.lv,
%% 						GuildN	= guild_api:get_guild_name(Guild),
%%             			[{Key, Name, Pro, Sex, Lv, GuildN, 0} | MList];
%%         		_ -> MList
%% 			end;
%% 		_ ->  MList
%%     end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 一键添加
one_key_add_friend(Player,[]) ->
	{?ok,Player};
one_key_add_friend(Player = #player{user_id = UserId,info = Info,sys_rank = Sys,net_pid = Pid},List) ->
	RelationData	 	= ets_relation_data(UserId),
	case one_key_add(UserId,Info,Sys,RelationData,<<>>,List) of
		{?ok,RelationData2,Packet} ->
			FriendList		= RelationData2#relation_data.friend_list,
			BestList		= RelationData2#relation_data.best_list,
			Count 			= length(FriendList) + length(BestList),
			insert_relation_data(RelationData2),
			misc_packet:send(Pid, Packet),
			add_achievement(Player,Count);
		_ ->
			{?ok,Player}
	end.

one_key_add(_,_,_,RelationData,AccMsg,[]) ->
	{?ok,RelationData,AccMsg};
one_key_add(UserId,Info,Sys,RelationData,AccMsg,[{MemId} | List]) ->
	try
		FriendList			= RelationData#relation_data.friend_list,
		BestList			= RelationData#relation_data.best_list,
		BackList			= RelationData#relation_data.black_list,
		Count 				= length(FriendList) + length(BestList),
		
		?ok					= check_user_id(UserId,MemId),
		?ok					= check_user_sys(Sys),	
		?ok					= check_friend_list(MemId,FriendList),
		?ok					= check_best_list(MemId,BestList), 
		?ok					= check_black_list(MemId,BackList),
		?ok					= check_friend_count(Count,player_api:get_vip_lv(Info)), 
		Flag				= case player_api:check_online(MemId) of
								  ?true -> ?CONST_SYS_TRUE;
								  ?false -> ?CONST_SYS_FALSE
							  end,
 		RData				= init_relation(MemId),		
		FriendList2 		= [RData|FriendList],
		RelationData2		= RelationData#relation_data{friend_list 	= FriendList2},	
		
 		add_relation_be(MemId,UserId,?CONST_RELATIONSHIP_BRELA_FRIEND),
		add_friend_notice(UserId,MemId,Info,Flag),		 
		Packet14512			= add_one_relation(2,?CONST_RELATIONSHIP_BRELA_FRIEND,MemId),
		AccMsg2				= <<AccMsg/binary,Packet14512/binary>>,
		one_key_add(UserId,Info,Sys,RelationData2,AccMsg2,List)
	catch
		_:_ ->
			{?ok,RelationData,AccMsg}
	end.

one_key_del(_UserId,_Type,[]) -> ?ok;
one_key_del(UserId,Type,List) ->
	RelationData	 	= ets_relation_data(UserId),
	TypeList			= get_list_by_type(RelationData,Type),
	{?ok,TypeList2,DelList}	= one_key_del2(UserId,Type,TypeList,List,[]),
	
	RelationData2 		= set_list_by_type(RelationData,TypeList2,Type),
	TipPacket			= message_api:msg_notice(?TIP_RELATION_ONE_KEY_DEL),
	Packet				= relation_api:msg_sc_one_key_del(DelList),
	insert_relation_data(RelationData2),
	
	misc_packet:send(UserId, <<TipPacket/binary,Packet/binary>>).

one_key_del2(_,_,[],_,DelList) -> 
	{?ok,[],DelList};
one_key_del2(_,_,TypeList,[],DelList) -> 
	{?ok,TypeList,DelList};
one_key_del2(UserId,Type,TypeList,[{MemId}|List],DelList) ->	
	case lists:keytake(MemId, #relation.mem_id, TypeList) of
		?false -> %% 不在列表中
			one_key_del2(UserId,Type,TypeList,List,DelList);
		{value, _, TypeList2} ->
%% 			Packet	= relation_api:msg_sc_delete(Type, MemId),
			delete_relation_be(MemId,UserId,Type),
			one_key_del2(UserId,Type,TypeList2,List,[{MemId}|DelList])
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 华丽的分割线   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
init_relation(MemId) ->
	#relation{
                  mem_id       	= MemId,    % 对方
                  time          = misc:seconds()     	% 建立时间                          
                 }.

init_relation_data(UserId) ->
	#relation_data{
                   user_id		= UserId,	% 玩家id
				   friend_list	= [], 		% 好友列表
				   best_list	= [],		% 密友列表
				   black_list	= [],		% 黑名单列表
				   contact_list	= []		% 最近联系人列表                      
                   }.

init_relation_be(UserId) ->
	#relation_be{
                   user_id		= UserId,	% 玩家id
				   be_friend	= [],
				   be_best		= [],
				   be_black		= []	             
                   }.