%% Author: Administrator
%% Created: 2013-5-14
%% Description: TODO: Add description to relation_api
-module(relation_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include_lib("stdlib/include/ms_transform.hrl").
%%
%% Exported Functions
%%
-export([
		 initial_ets/0,
		 add_contacted/2,
 		 
		 login/1,logout/1,
		 logout_handle/1,login_handle/1,
 		 login_packet/2,
		 broadcast/2,
		 
		 list_friend/1,
		 list_bilateral_friend/1,
		 is_be_black/2,
		 is_friend/2,
		 is_bilateral_friend/2
		]).
-export([
		 msg_sc_list/2,
		 msg_add_notice/6,
		 msg_sc_change/3,
		 msg_sc_add/11,
		 msg_sc_delete/2,
		 msg_sc_on_off/3,
		 msg_sc_count/3,
		 msg_sc_recommend/1,
		 msg_sc_one_key_del/1
		 ]).

%%
%% API Functions
%%

%% 初始化好友信息
initial_ets() -> 
	relation_db_mod:select_data().

%% 下线操作
logout(Player = #player{user_id = UserId,info = Info,sys_rank = Sys}) ->
    Now 			= misc:seconds(),
    Info2 			= Info#info{time_active = Now},
    SysRank = data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP),
	if
		Sys >= SysRank ->
			RelationData	= relation_mod:ets_relation_data(UserId),
			RelationData2	= RelationData#relation_data{contact_list = []},
			relation_mod:insert_relation_data(RelationData2),
			relation_db_mod:replace_data(RelationData2),
			relation_serv:logout_cast(UserId);
		?true -> ?ok
	end,	
    Player#player{info = Info2};
logout(Player) ->
	Player.

logout_handle(UserId) ->
	Packet1			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_FRIEND,UserId,?CONST_SYS_FALSE),
	Packet2			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_BEST_FRIEND,UserId,?CONST_SYS_FALSE),
	Packet3			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_BLACK_LIST,UserId,?CONST_SYS_FALSE),
	Packet4			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_CONTACTED,UserId,?CONST_SYS_FALSE),
	RelationBe 		= relation_mod:ets_relation_be(UserId),
	broadcast(RelationBe#relation_be.be_friend,Packet1),
	broadcast(RelationBe#relation_be.be_best,Packet2),
	broadcast(RelationBe#relation_be.be_black,Packet3), 
	broadcast(RelationBe#relation_be.be_contact,Packet4), 
	relation_mod:delete_contact(UserId, RelationBe#relation_be.be_contact),
	?ok.

%% 上线操作
login(Player = #player{user_id = UserId,info = Info,sys_rank = Sys}) ->
    Now 			= misc:seconds(),
    Info2 			= Info#info{time_active = Now},
    SysRank = data_guide:get_task_rank(?CONST_MODULE_RELATIONSHIP),
	if
		Sys >= SysRank ->
			login_handle(UserId);
		?true -> ?ok
	end,	
    Player#player{info = Info2};
login(Player) ->
	Player.
								   
login_handle(UserId) ->
	Packet1			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_FRIEND,UserId,?CONST_SYS_TRUE),
	Packet2			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_BEST_FRIEND,UserId,?CONST_SYS_TRUE),
	Packet3			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_BLACK_LIST,UserId,?CONST_SYS_TRUE),
	Packet4			= msg_sc_on_off(?CONST_RELATIONSHIP_BRELA_CONTACTED,UserId,?CONST_SYS_TRUE),
	RelationBe 		= relation_mod:ets_relation_be(UserId),
	
	broadcast(RelationBe#relation_be.be_friend,Packet1),
	broadcast(RelationBe#relation_be.be_best,Packet2),
	broadcast(RelationBe#relation_be.be_black,Packet3), 
	broadcast(RelationBe#relation_be.be_contact,Packet4), 
	?ok.

broadcast([],_Packet) -> ?ok;
broadcast(List,Packet) ->
	Count = length(List),
	if
		Count >= 20 ->
			spawn(fun() -> do_broadcast(List, Packet) end);
		?true ->
			do_broadcast(List,Packet)
	end.

do_broadcast([],_Packet) -> ?ok;
do_broadcast([UserId | List],Packet) when is_number(UserId)->
	misc_packet:send(UserId, Packet),
	do_broadcast(List,Packet);
do_broadcast([_ | List],Packet) ->
	do_broadcast(List,Packet).

%% 黑名单
is_be_black(UserId,MemId) ->
	RelationBe			= relation_mod:ets_relation_be(UserId),
	BlackList			= RelationBe#relation_be.be_black,
	lists:member(MemId, BlackList).	

%% 是否为好友
is_friend(UserId,MemId) ->
	RelationData		= relation_mod:ets_relation_data(UserId),
	List				= RelationData#relation_data.friend_list ++ RelationData#relation_data.best_list,
	case lists:keytake(MemId, #relation.mem_id, List) of
		?false -> ?false;
		{value,_,_} ->
			?true
	end.		

%% 互为好友
is_bilateral_friend(UserId,MemId) ->
	RelationData		= relation_mod:ets_relation_data(UserId),
	List				= RelationData#relation_data.friend_list ++ RelationData#relation_data.best_list,
	RelationBe			= relation_mod:ets_relation_be(UserId),
	BeList				= RelationBe#relation_be.be_friend ++ RelationBe#relation_be.be_best,
	Flag 				= lists:member(MemId, List),
	Flag2 				= lists:member(UserId, BeList),
	if
		Flag =:= ?true andalso Flag2 =:= ?true ->
			?true;
		?true -> 
			?false
	end.		

%% 最近联系人
add_contacted(UserId, MemId) ->
	relation_mod:add_contact(UserId, MemId).

%% 好友列表 
list_friend(UserId) ->
	RelationData		= relation_mod:ets_relation_data(UserId),
	MList				= RelationData#relation_data.friend_list ++ RelationData#relation_data.best_list,
	[MemId || #relation{mem_id = MemId} <- MList].

%% 互为好友列表
list_bilateral_friend(UserId) ->
	RelationData		= relation_mod:ets_relation_data(UserId),
	MList				= RelationData#relation_data.friend_list ++ RelationData#relation_data.best_list,
	RelationBe			= relation_mod:ets_relation_be(UserId),
	BeList				= RelationBe#relation_be.be_friend ++ RelationBe#relation_be.be_best,
	list_bilateral_friend(MList,BeList,[]).
	
list_bilateral_friend([],_,List) ->
	List;
list_bilateral_friend([#relation{mem_id = MemId}|L],BeList,List) ->
	case lists:member(MemId, BeList) of
		?true ->
			List2	= [MemId | List];
		_ ->
			List2	= List
	end,
	list_bilateral_friend(L,BeList,List2).

login_packet(Player, OldPacket) ->
	Packet	= relation_mod:relation_count(Player#player.user_id),
	{Player, <<OldPacket/binary,Packet/binary>>}. 

%% 信息列表
%%[Type,{Info}]
msg_sc_list(Type,List1) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_LIST, ?MSG_FORMAT_RELATION_SC_LIST, [Type,List1]).
%% 增加一条信息
%%[Type,Group]
msg_sc_add(Type,SubType,MemId, Name, Pro, Sex, Lv, GuildName, Vip,Power,OnlineTime) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_ADD, ?MSG_FORMAT_RELATION_SC_ADD, [Type,SubType,MemId, Name, Pro, Sex, Lv, GuildName, Vip,Power,OnlineTime]).
%% 增加好友通知
%%[UserId,UserName,Pro,Sex,Lv,Vip]
msg_add_notice(UserId,UserName,Pro,Sex,Lv,Vip) ->
	misc_packet:pack(?MSG_ID_RELATION_ADD_NOTICE, ?MSG_FORMAT_RELATION_ADD_NOTICE, [UserId,UserName,Pro,Sex,Lv,Vip]).
%% 改变关系返回
%%[Type,UserId,ToType]
msg_sc_change(Type,UserId,ToType) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_CHANGE, ?MSG_FORMAT_RELATION_SC_CHANGE, [Type,UserId,ToType]).
%% 删除关系人
%%[Type,UserId]
msg_sc_delete(Type,UserId) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_DELETE, ?MSG_FORMAT_RELATION_SC_DELETE, [Type,UserId]).

%% 上下线通知 
%%[Type,UserId,Flag]
msg_sc_on_off(Type,UserId,Flag) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_ON_OFF, ?MSG_FORMAT_RELATION_SC_ON_OFF, [Type,UserId,Flag]).
%% 好友推荐列表
%%[{Info}]
msg_sc_recommend(List1) ->
	misc_packet:pack(?MSG_ID_RELATION_SC_RECOMMEND, ?MSG_FORMAT_RELATION_SC_RECOMMEND, [List1]).
%% 关系人数量
%%[Type,Online,Sum]
msg_sc_count(Type,Online,Sum) -> 
	misc_packet:pack(?MSG_ID_RELATION_SC_COUNT, ?MSG_FORMAT_RELATION_SC_COUNT, [Type,Online,Sum]).
%% 批量删除好友
%%[{UserId}]
msg_sc_one_key_del(List1) -> 
	misc_packet:pack(?MSG_ID_RELATION_SC_ONE_KEY_DEL, ?MSG_FORMAT_RELATION_SC_ONE_KEY_DEL, [List1]).
