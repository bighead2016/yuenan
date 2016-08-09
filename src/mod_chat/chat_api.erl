%% Author: yskj
%% Created: 2012-7-13
%% Description: TODO: Add description to home_api
-module(chat_api).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([chat/4, msg_chat_sc_chat/5, msg_chat_sc_private/2, msg_sc_black/1,
		 msg_sc_user_data/10]).

%%
%% API Functions
%%
-include("../../include/const.common.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").

%%
%% Local Functions
%%
chat(Player, Channel, Content, GoodsList) ->
	chat_mod:chat(Player, Channel, Content, GoodsList).

%% 8002 聊天信息 
msg_chat_sc_chat(Player, Channel, Content, Goods, Equip) ->
	Info 	= Player#player.info,
	UserId	= Player#player.user_id,
	Name	= Info#info.user_name,
	Pro		= Info#info.pro,
	Sex		= Info#info.sex,
	Lv		= Info#info.lv,
	State	= Player#player.state,
	Vip		= player_api:get_vip_lv(Info),
	Position= player_position_api:current_position(Player),
%% 	Title 	= achievement_api:current_title(Player),
	msg_chat_sc_chat(Channel, UserId, Name, Pro, Sex, Lv, State, Vip, Position, Content, Goods, Equip).
msg_chat_sc_chat(Channel, UserId, Name, Pro, Sex, Lv, State, Vip, Position, Content, Goods, Equip) ->
	misc_packet:pack(?MSG_ID_CHAT_SC_CHAT, ?MSG_FORMAT_CHAT_SC_CHAT,
					 [Channel, UserId, Name, Pro, Sex, Lv, State, Vip, Position, Content, Goods, Equip]).


%% 8012 私聊接收 
msg_chat_sc_private(Player, Content) ->
	Info 	= Player#player.info,
	UserId	= Player#player.user_id,
	Name	= Info#info.user_name,
	Pro		= Info#info.pro,
	Sex		= Info#info.sex,
	Lv		= Info#info.lv,
	State	= Player#player.state,
	Vip		= player_api:get_vip_lv(Info),
	msg_chat_sc_private(UserId, Name, Pro, Sex, Lv, State, Vip, Content).
msg_chat_sc_private(UserId, Name, Pro, Sex, Lv, State, Vip, Content) ->
	misc_packet:pack(?MSG_ID_CHAT_SC_PRIVATE, ?MSG_FORMAT_CHAT_SC_PRIVATE,
					 [UserId, Name, Pro, Sex, Lv, State, Vip, Content]).

%% 黑名单接收
%%[UserId]
msg_sc_black(UserId) ->
	misc_packet:pack(?MSG_ID_CHAT_SC_BLACK, ?MSG_FORMAT_CHAT_SC_BLACK, [UserId]).

%% 对方信息
%%[UserId,UserName,Pro,Sex,Lv,Vip,IsOnline]
msg_sc_user_data(UserId,UserName,Pro,Sex,Lv,Vip,GuildName,IsOnline,Position,Type) ->
	misc_packet:pack(?MSG_ID_CHAT_SC_USER_DATA, ?MSG_FORMAT_CHAT_SC_USER_DATA, [UserId,UserName,Pro,Sex,Lv,Vip,GuildName,IsOnline,
																				Position,Type]).


