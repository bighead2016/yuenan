%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to mail_handler
-module(mail_handler).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("const.protocol.hrl").
-include("const.define.hrl").
-include("record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%
%% 发送邮件
%% 	Goods1    = goods_api:make(2011105001, 3),
%% 	Goods2	  = goods_api:make(2010907006, 5),
%% 	mail_mod:send_system_mail_to_one(ReceiveName, Title, Content, Goods1, 0, 0),
handler(?MSG_ID_MAIL_CS_SEND, Player, {ReceiveName, Title, Content, Type}) ->
 	mail_mod:send_private_mail(Player, ReceiveName, Title, Content, Type),
	?ok;

%% 读取邮件
handler(?MSG_ID_MAIL_CS_READ, Player, {Id}) ->
	mail_mod:read(Player, Id),
	?ok;

%% 删除邮件
handler(?MSG_ID_MAIL_CS_DELETE, Player, {{_Length, IdList}}) ->
	UserId		= Player#player.user_id, 
	mail_mod:delete_mail(IdList, UserId),
	?ok;

%% 获取邮件列表
handler(?MSG_ID_MAIL_CS_LIST_REQUEST, Player, {}) ->                              
	Packet		= mail_mod:list(Player),
	misc_packet:send(Player#player.net_pid, Packet),
	?ok;

%% 保存邮件
handler(?MSG_ID_MAIL_CS_SAVE, Player, {{_Length, IdList}}) -> 
	mail_mod:save_mail(IdList, Player),
	?ok;

%% 获取附件
handler(?MSG_ID_MAIL_CS_GET_ATTACH, Player, {MailId}) ->
	NewPlayer 	= mail_mod:get_attachment(Player, MailId),
	{?ok, NewPlayer};

%% 领取所有附件
handler(?MSG_ID_MAIL_CS_GET_ALL, Player, {}) ->
	NewPlayer	= mail_mod:get_all_attachment(Player),
	{?ok, NewPlayer};

%% 协议匹配错误
handler(_MsgId, _Player, _Datas) -> ?undefined.

