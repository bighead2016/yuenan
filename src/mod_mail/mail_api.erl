%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to mail_api
-module(mail_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([initial_ets/0, send_system_mail_to_one/10, send_system_mail_to_one2/10, login_packet/2,zip_goods_data/1, unzip_goods_data/1,
		 send_system_mai_to_some/10, clean_overdure_mail/0, send_guild_mail_to_one2/10, send_interest_mail_to_one2/10]).
-export([msg_mail_list_info/1, msg_mail_info/1, msg_save_mail/2, msg_delete_mail/1, msg_get_attachment/1, 
		 msg_send_mail/1, get_goods_id/2]).
-export([send_system_mail_to_one3/11,send_guild_mail_to_one3/11,send_interest_mail_to_one3/11,send_system_mai_to_some2/11, send_sys_mail_to_guild/5
		, send_sys_mail_to_guildmember/5]).
%%
%% API Functions
%%
%%初始化邮件ETS数据
initial_ets() ->
	ets:delete_all_objects(?CONST_ETS_MAIL),
	FieldList = [mail_id, type, send_uid, send_name, send_sex, recv_uid, recv_name, title, time, 
				 content, message_id, content1, cash, bcash, gold, goods, is_read, is_save, is_pick,
                  point, bcash2],
	case mysql_api:select(FieldList, game_mail) of
		{?ok, MailDataList} ->
			F = fun([MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
					 MessageId, ContentTemp1, Cash, BCash, Gold, GoodsTemp, IsRead, IsSave, IsPick, 
                     Point, BCash2]) ->
						try
                        Goods 		= misc:decode(GoodsTemp),
                        Goods1		= unzip_goods_data(Goods),
                        Content1	= misc:decode(ContentTemp1),
%%                         ?MSG_DEBUG("record_mail~p~n",[[MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
%%                                               MessageId, Content1, Cash, BCash, Gold, Goods1, IsRead, IsSave, IsPick,
%%                                                Point,BCash2]]),
                        mail_mod:record_mail([MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
                                              MessageId, Content1, Cash, BCash, Gold, Goods1, IsRead, IsSave, IsPick,
                                              Point,BCash2])
						catch
							E:W ->
								?MSG_ERROR("mail init wrong--{[MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
								 MessageId, ContentTemp1, Cash, BCash, Gold, GoodsTemp, IsRead, IsSave, IsPick, 
                			     Point, BCash2]~n~p~nErr:~p|Why:~p~n}",
								  [[MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
								 MessageId, ContentTemp1, Cash, BCash, Gold, GoodsTemp, IsRead, IsSave, IsPick, 
                 			    Point, BCash2],E,W])
								end
                end,
            MailList = lists:map(F, MailDataList),
            mail_mod:ets_insert_list(MailList);
        {?error, ErrorCode} ->
            ?MSG_DEBUG("MailList=~p~n", [ErrorCode])
	end.

%% 官方系统给某个玩家发邮件|ReceiveName, Title, Content, MessageId, Content1, Goods, Gold, Cash, BCash, Point| Goods -> goods|List
send_system_mail_to_one(ReceiveName, Title, Content, MessageId, Content1, Goods, Gold, Cash, BCash, Point) ->
	mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, Goods, Gold, Cash, BCash, 
									 ?CONST_MAIL_SYSTEM, Point, 0).
send_system_mail_to_one2(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point) ->	
	mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
									  BCash, ?CONST_MAIL_SYSTEM, Point,0).
send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point, BCash2) ->  
    mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
                                      BCash, ?CONST_MAIL_SYSTEM, Point, BCash2).
%% 军团系统给某个玩家发邮件
send_guild_mail_to_one2(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point) ->	
	mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, 
									  Cash, BCash, ?CONST_MAIL_GUILD, Point,0).
send_guild_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point, BCash2) ->  
    mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
                                      BCash, ?CONST_MAIL_GUILD, Point, BCash2).

%% 给某个军团发系统邮件
send_sys_mail_to_guild(GuildId, MailId, Goods, ParamList, Point) ->
    MemberList = guild_api:get_guild_members(GuildId),
    Fun =
        fun({_, Name, _Power}) ->
                Name
        end,
    NameList = lists:map(Fun, MemberList),
    mail_api:send_system_mai_to_some(NameList, <<>>, <<>>, MailId, ParamList, Goods, 0, 0, 0, Point).

%% 给某个军团除了团长外成员发系统邮件
send_sys_mail_to_guildmember(GuildId, MailId, Goods, ParamList, Point) ->
    MemberList = guild_api:get_guild_members(GuildId),
	{?ok, ChiefName} = guild_api:get_guild_chief_name(GuildId) ,
    Fun =
        fun({_, Name, _Power}) ->
                Name
        end,
    NameList = lists:map(Fun, MemberList),
	NameList2 = lists:delete(ChiefName, NameList),
    mail_api:send_system_mai_to_some(NameList2, <<>>, <<>>, MailId, ParamList, Goods, 0, 0, 0, Point).
%% 系统给玩家返利接口(慎用)
send_interest_mail_to_one2(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point) ->
	mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
									  BCash, ?CONST_MAIL_INTEREST, Point,0).
send_interest_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, BCash, Point, BCash2) ->  
    mail_mod:send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
                                      BCash, ?CONST_MAIL_INTEREST, Point, BCash2).


%% 系统给多个玩家发送邮件
send_system_mai_to_some(ReceiveNameList, Title, Content, MessageId, Content1, Goods, Gold, Cash, BCash, Point)->
	mail_mod:send_system_mail_to_some3(ReceiveNameList, Title, Content, MessageId, Content1, Goods, Gold, Cash, 
									 BCash, ?CONST_MAIL_SYSTEM, Point,0).
send_system_mai_to_some2(ReceiveNameList, Title, Content, MessageId, Content1, Goods, Gold, Cash, BCash, Point, BCash2)->
    mail_mod:send_system_mail_to_some3(ReceiveNameList, Title, Content, MessageId, Content1, Goods, Gold, Cash, 
                                     BCash, ?CONST_MAIL_SYSTEM, Point, BCash2).
%% 删除过期邮件(7 days)
clean_overdure_mail() ->
	try
		mail_mod:clean_mail()
	catch
		Error:Reason ->
			?MSG_ERROR("~nError:~p~nReason:~p~nStrace:~p~n", [Error, Reason, erlang:get_stacktrace()]),
			?ok
	end.
	
%% 上线请求邮件数据返回
login_packet(Player, Packet) ->
    Packet1 	= mail_mod:list(Player),
    {Player, <<Packet/binary, Packet1/binary>>}.

%% 从物品列表取出物品id
get_goods_id([], Acc) -> Acc;
get_goods_id([MiniGoods0|RestGoods], Acc) when is_record(MiniGoods0, mini_goods) orelse is_record(MiniGoods0, goods) ->
	MiniGoods = goods_api:goods_to_mini(MiniGoods0),
	GoodsId		= MiniGoods#mini_goods.goods_id,
	case lists:keymember(GoodsId, 1, Acc) of
		?true -> 
			get_goods_id(RestGoods, Acc);
		?false ->
			GoodsId1		= misc:to_list(GoodsId),
			get_goods_id(RestGoods, [{GoodsId1}|Acc])
	end;
get_goods_id([_|RestGoods], Acc) ->
	get_goods_id(RestGoods, Acc).
	
	
%%
%% Local Functions
%%
%% 邮件列表信息(9002)
msg_mail_list_info(MailList) ->
	msg_mail_list_info(MailList, <<>>).

msg_mail_list_info([Mail|MailList], Acc) ->
	Packet		= msg_mail_info(Mail),
	msg_mail_list_info(MailList, <<Acc/binary, Packet/binary>>);
msg_mail_list_info([], Acc) ->
	Acc.
msg_mail_info(Mail) when is_record(Mail, mail) ->
	Data = [Mail#mail.bcash2,
            Mail#mail.mail_id,
			Mail#mail.type,
			Mail#mail.send_uid,
			Mail#mail.send_name,
			Mail#mail.recv_uid,
			Mail#mail.recv_name,
			Mail#mail.title,
			Mail#mail.time,
			Mail#mail.content,
			round(Mail#mail.cash),
			Mail#mail.bcash,
			Mail#mail.gold,
			Mail#mail.is_read,
			Mail#mail.is_save,
			Mail#mail.is_pick,
			msg_mail_goods(Mail),
			Mail#mail.time + ?CONST_MAIL_SYS_KEEP * ?CONST_SYS_ONE_DAY_SECONDS,
			Mail#mail.send_sex,
			Mail#mail.message_id,
			Mail#mail.content1
           ],	
	misc_packet:pack(?MSG_ID_MAIL_SC_LIST_INFO, ?MSG_FORMAT_MAIL_SC_LIST_INFO, Data).

msg_mail_goods(Mail) ->
	Goods		= Mail#mail.goods,
	GoodsList   = misc:to_list(Goods),
	F 			= fun(GoodsInfo, Acc) when is_record(GoodsInfo, mini_goods) orelse is_record(GoodsInfo, goods)->
                          GoodsInfo2 = goods_api:mini_to_goods(GoodsInfo),
						  GoodsType		= GoodsInfo2#goods.type,
						  A	= case GoodsType of
								   ?CONST_GOODS_TYPE_EQUIP ->
									  goods_api:msg_group_goods_equip(?CONST_GOODS_CTN_BAG, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, GoodsInfo2);
								   ?CONST_GOODS_TYPE_WEAPON ->
									  goods_api:msg_group_goods_weapon(?CONST_GOODS_CTN_BAG, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, GoodsInfo2);
								  _ ->
									  {?CONST_GOODS_CTN_BAG, ?CONST_SYS_FALSE, ?CONST_SYS_FALSE, GoodsInfo2#goods.idx, GoodsInfo2#goods.goods_id, 
									   GoodsInfo2#goods.count, GoodsInfo2#goods.bind, GoodsInfo2#goods.start_time, GoodsInfo2#goods.end_time, 
									   GoodsInfo2#goods.time_temp,?CONST_SYS_FALSE,?CONST_SYS_FALSE,?CONST_SYS_FALSE, [], [], [], []}
							  end,
						  [A|Acc];
					 (A, B) ->
						  ?MSG_PRINT("A=~p, B=~p", [A, B]),
						  []
				  end,
	lists:foldl(F, [], GoodsList).


%% 压缩物品数据
zip_goods_data(Goods) ->
	GoodsList		 = misc:to_list(Goods),
	F	= fun(GoodsInfo, Acc) when is_record(GoodsInfo, mini_goods) or is_record(GoodsInfo,  goods)->
				  ZipedGoods	= goods_api:zip_goods(GoodsInfo),
				  [ZipedGoods|Acc];
			 (_, Acc) -> Acc
		  end,
	lists:foldl(F, [], GoodsList).

%% 解压物品数据
unzip_goods_data(Goods) ->
	GoodsList		 = misc:to_list(Goods),
	F	= fun(GoodsInfo, Acc) when is_record(GoodsInfo, mini_goods) or is_record(GoodsInfo,  goods)->
				  [GoodsInfo|Acc];
			 (GoodsInfo, Acc) -> 
                  UnZipedGoods  = goods_api:unzip_goods(GoodsInfo),
                  [UnZipedGoods|Acc]
		  end,
	lists:foldl(F, [], GoodsList).

%% 删除邮件返回(9006)
msg_delete_mail(MailIdList) ->
	misc_packet:pack(?MSG_ID_MAIL_SC_DELETE, ?MSG_FORMAT_MAIL_SC_DELETE, [MailIdList]).

%% 保存邮件返回(9012)
msg_save_mail(Result, MailIdList) ->
	misc_packet:pack(?MSG_ID_MAIL_SC_SAVE, ?MSG_FORMAT_MAIL_SC_SAVE, [Result, MailIdList]).

%% 提取附件返回(9014)
msg_get_attachment(Result) ->
	misc_packet:pack(?MSG_ID_MAIL_SC_GET_ATTACH, ?MSG_FORMAT_MAIL_SC_GET_ATTACH, [Result]).

%% 发送邮件返回(9022)
msg_send_mail(Result) ->
	misc_packet:pack(?MSG_ID_MAIL_SC_SEND_RESULT, ?MSG_FORMAT_MAIL_SC_SEND_RESULT, [Result]).
