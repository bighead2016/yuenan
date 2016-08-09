%% Author: php
%% Created: 
%% Description: TODO: Add description to spring_handler
-module(spring_handler).

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

%% 进入温泉
handler(?MSG_ID_SPRING_CSENTER, Player, {}) ->
	spring_mod:enter(Player);

%% 离开温泉
handler(?MSG_ID_SPRING_CSEXIT, Player, {}) ->
	spring_mod:quit(Player);

%% 双修请求
handler(?MSG_ID_SPRING_CSDOUBLEREQUEST, Player, {MateId, Type}) ->
	spring_mod:double_request(Player, MateId, Type);

%% 双修邀请回复
handler(?MSG_ID_SPRING_CSDOUBLEREPLY, Player, {MateId, Type, Reply}) ->
 	spring_mod:double_reply(Player, MateId, Type, Reply);

%% 取消双修
handler(?MSG_ID_SPRING_CSCANCEL, Player, {})	->
 	spring_mod:double_cancel(Player);

%% 双修整屏通知
handler(?MSG_ID_SPRING_CS_NOTICE_REQ, Player, {MateId, Type}) ->
 	spring_mod:double_notice(Player,MateId, Type),
	{?ok, Player};

%% 温泉结束请求退出
handler(?MSG_ID_SPRING_CS_END_QUIT, Player, {}) ->
 	spring_mod:acitve_end_quit(Player);

%% 请求获得体力
handler(?MSG_ID_SPRING_CS_GET_SP, Player, {}) ->
	spring_mod:request_get_sp(Player);

%% 设置自动双修
handler(?MSG_ID_SPRING_CS_AUTO, Player, {Flag}) ->
	spring_mod:set_auto(Player#player.user_id,Flag),
	?ok;

handler(MsgId, Player, Datas)	->
	?MSG_ERROR("MsgId:~p PlayerUid:~p Binary:~p~n",[MsgId, element(2,Player), Datas]),
	?ok.
%%
%% Local Functions
%%
