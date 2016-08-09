%% Author: php
%% Created: 
%% Description: TODO: Add description to relation_handler
-module(relation_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.protocol.hrl").
-include("record.player.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).
%%
%% API Functions
%%
%% 信息列表
handler(?MSG_ID_RELATION_CS_LIST, Player, {Type}) ->
	Packet 	= relation_mod:friend_list(Player#player.user_id, Type),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;
%% 增加关系
handler(?MSG_ID_RELATION_CS_ADD, Player, {Type,UserId,UserName}) ->
	case relation_mod:add_relation(Player, Type, UserId, UserName) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		{?ok, Player2} -> {?ok, Player2}
	end;
%% 改变关系
handler(?MSG_ID_RELATION_CS_CHANGE, Player, {Type,MemId,ToType}) ->
	case relation_mod:change(Player,Type,MemId,ToType) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		{?ok, Player2} -> {?ok, Player2}
	end;
%% 删除关系人
handler(?MSG_ID_RELATION_CS_DELETE, Player, {Type,MemId}) ->
	case relation_mod:delete_friend(Player#player.user_id,MemId,Type) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_ -> 
			Packet	= relation_api:msg_sc_delete(Type, MemId),
			misc_packet:send(Player#player.net_pid, Packet),
            ?ok
	end;
%% 好友推荐列表
handler(?MSG_ID_RELATION_CS_RECOMMEND, Player, {}) ->
	case relation_mod:recomm_list(Player) of
		{?error,ErrorCode} -> {?error,ErrorCode};
		_ -> ?ok
	end;
%% 一键添加
handler(?MSG_ID_RELATION_CS_ONE_KEY, Player, {{_,List}}) ->
	relation_mod:one_key_add_friend(Player,List);
%% 批量删除好友
handler(?MSG_ID_RELATION_CS_ONE_KEY_DEL, Player, {Type,{_,List}}) ->
	relation_mod:one_key_del(Player#player.user_id,Type,List),
	?ok;

%% 请求关系人数量
%% handler(?MSG_ID_RELATION_CS_COUNT, Player, {}) ->
%% 	relation_mod:relation_count(Player#player.user_id),
%% 	{?ok, Player};

handler(_MsgId, _Player, _Datas) -> ?undefined.

%%
%% Local Functions
%%
