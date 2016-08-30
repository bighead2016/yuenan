%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to mail_mod
-module(mail_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([send_private_mail/5, send_system_mai_to_some/11,  list/1, read/2, save_mail/2, 
		 delete_mail/2, get_attachment/2,  clean_mail/0, send_list/1, get_all_attachment/1]).
-export([ets_lookup_mail/1, ets_insert_mail/1, ets_delete_mail/2, ets_insert_list/1,
		 record_mail/1]).
-export([send_system_mail_to_some3/12,send_system_mail_to_one3/12]).
%%
%% API Functions 
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     发送私人信件
%% @spec     send_mail_to_one/4
%% @param    ReceiveName:收件人 Title:标题 Content:内容 
%% @return   ?true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
send_private_mail(Player, ReceiveName, Title, Content, Type) ->
	SendUId		= Player#player.user_id,
	Info		= Player#player.info,
	SendName	= Info#info.user_name,
	SendSex		= Info#info.sex,
	Timestamp	= misc:seconds(),
	Cash		= ?CONST_SYS_FALSE,
	BCash		= ?CONST_SYS_FALSE,
	Gold		= ?CONST_SYS_FALSE,
	Goods		= <<>>,
	IsRead		= ?CONST_SYS_FALSE, 
	IsSave		= ?CONST_SYS_FALSE,
	IsPick		= ?CONST_SYS_FALSE,
	try
		{?ok, ReceiveId}	= check_receiver(ReceiveName),
		?ok					= check_mail_open(Player),
		?ok					= check_mail_full(ReceiveId, 1, ?CONST_MAIL_PRIVATE),
		?ok 				= case Type =:= ?CONST_SYS_FALSE of
								  ?true ->
									  check_send_num(SendUId);
								  ?false -> ?ok
							  end,
		MailType			= case Type =:= ?CONST_SYS_FALSE of
								  ?true ->
									  get_mail_type(SendUId, ReceiveId);
								  ?false ->
									  ?CONST_MAIL_GUILD
							  end,
		case insert_mail(MailType, SendUId, SendName, SendSex, ReceiveId, ReceiveName, Title, Timestamp, 
						 Content, 0, [], Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, ?CONST_SYS_FALSE, 0) of
			{?ok, Mail} ->
				%%判断是否为同一军团
				SendGuildId = 
					case player_api:get_player_field(SendUId, #player.guild) of
						{?ok, #guild{guild_id=GuildId1}} -> GuildId1;
						_ -> 0
					end,
				RevGuildId =
					case player_api:get_player_field(ReceiveId, #player.guild) of
						{?ok, #guild{guild_id=GuildId2}} -> GuildId2;
						_ -> 0
					end,
				if SendGuildId == RevGuildId andalso RevGuildId =/= 0 ->
					   next;
				   true ->
					   admin_api:data_monitor_chat(Player,?CONST_CHAT_MAIL,Content)
				end,
				admin_log_api:log_chat(Player, ?CONST_CHAT_MAIL, Content),
				achievement_api:add_achievement(SendUId, ?CONST_ACHIEVEMENT_EPISTLE, 0, 1),
				Packet0		= mail_api:msg_mail_info(Mail),
				misc_packet:send(ReceiveId, Packet0),
				Packet1		= mail_api:msg_send_mail(?CONST_MAIL_SEND_SUCCESS),
				TipPacket	= case MailType =:= ?CONST_MAIL_GUILD of
								  ?true  -> <<>>;
								  ?false -> 
									  message_api:msg_notice(?TIP_MAIL_SEND_SUCCESS)
							  end,
				misc_packet:send(Player#player.net_pid, <<Packet1/binary, TipPacket/binary>>);
			{?error, _Reason} -> 
				Packet		= message_api:msg_notice(?TIP_MAIL_SEND_FAIL), 
				misc_packet:send(Player#player.net_pid, Packet)
		end
	catch
		throw:{?error, ErrorCode} ->
			?MSG_DEBUG("ErrroCode=~p~n", [ErrorCode]),
			Packet2		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet2)
	end.

%% 检查收件人
check_receiver(ReceiveName) ->
%%     ?MSG_ERROR("check_receiver:~p~n",[ReceiveName]),
	case player_api:get_user_id(ReceiveName) of
		{?ok, ReceiveId} ->
			{?ok, ReceiveId};
		{?error, _ErrorCode} ->        %% 无此联系人
			throw({?error, ?TIP_MAIL_NOT_PERSON})
	end.

%% 检查邮件是否开启
check_mail_open(_)->
	?ok;

check_mail_open(Player) when is_record(Player, player)->
	Info		= Player#player.info,
	Lv			= Info#info.lv,
	case Lv >= ?CONST_MAIL_OPEN_LV of
		?true -> ?ok;
		?false -> throw({?error, ?TIP_MAIL_LV_NOT_ENOUGH})
	end;
check_mail_open(UserId) ->  
    SysRank = data_guide:get_task_rank(?CONST_MODULE_MAIL),
	case player_api:get_player_field(UserId, #player.sys_rank) of
		{?ok, SysId} when SysId >= SysRank -> ?ok;
		_ -> throw({?error, ?CONST_MAIL_NOT_OPEN})
	end.

%% 检查一天发送的数量
check_send_num(UserId) ->
	List	= ets_api:list(?CONST_ETS_MAIL),
	F		= fun(Mail, Acc) when is_record(Mail, mail) andalso Mail#mail.send_uid =:= UserId->
					  Time		= Mail#mail.time,
					  Now		= misc:seconds(),
					  Flag		= misc:is_same_date(Time, Now),
					  case Flag of
							?true -> Acc + 1;
						    ?false -> Acc
					  end;
				 (_, Acc) -> 
					  Acc
			  end,
	Num		 = lists:foldl(F, 0, List),
	case Num >= ?CONST_MAIL_SEND_MAX_NUM of
		?true -> throw({?error, ?TIP_MAIL_SEND_MAX});
		?false ->?ok
	end.

%% 获取邮件类型
get_mail_type(SendUId, ReceiveId) ->
	case relation_api:is_friend(ReceiveId,SendUId) of
		?true -> ?CONST_MAIL_PRIVATE;
		_ -> ?CONST_MAIL_STRANGE
	end.		 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     发送系统信件给某个玩家
%% @spec     send_mail_to_one/6
%% @param    ReceiveName:收件人 Title:标题 Content:内容 
%% @return   ?true| {?error, Reason}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

%% 发送系统物品数量(包括元宝和铜钱)超过5个拆分邮件 
send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, Gold, Cash, 
                         BCash, Type, Point,BCash2) ->
	GoodsList2 = if  is_record(GoodsList, goods) ->
						 [GoodsList];
					 is_list(GoodsList) ->
						 GoodsList;
					 ?true ->
						 []
				 end,
    Count       = lists:foldl(fun(X,Acc) ->
                                      if X > 0 ->
                                             Acc+1;
                                         ?true ->
                                             Acc
                                      end
                              end, 0, [Gold, Cash, BCash, BCash2]),
    RestNum     = (?CONST_MAIL_MAX_ATTACHMENT - Count),
    GoodsNum    = get_goods_type_num(GoodsList2, []),
    if
        GoodsNum > RestNum ->
            StackGoods  = split_goods(GoodsList2, RestNum, []),
            RestGoods   = GoodsList2 -- StackGoods,
            case send_system_mail_to_one4(ReceiveName, Title, Content, MessageId, Content1, StackGoods, Gold,
                                         Cash, BCash, Type, Point, BCash2) of
                {?error, ErrorCode} ->
                    {?error, ErrorCode};
                _ ->
                    ?MSG_DEBUG("next mail ok=~p, RestGoods=~p", [?ok, RestGoods]),
                    NewGold     = ?CONST_SYS_FALSE,
                    NewCash     = ?CONST_SYS_FALSE,
                    NewBCash    = ?CONST_SYS_FALSE,
                    send_system_mail_to_one4(ReceiveName, Title, Content, MessageId, Content1,
                                             RestGoods, NewGold, NewCash, NewBCash, Type, Point, BCash2)
            end;
        ?true ->
            send_system_mail_to_one4(ReceiveName, Title, Content, MessageId, Content1, GoodsList2, 
                                    Gold, Cash, BCash, Type, Point, BCash2)
    end.

send_system_mail_to_one4(ReceiveName, Title, Content, MessageId, Content1, GoodsList,
                          Gold, Cash, BCash, Type, Point, BCash2) ->
    SendUId     = ?CONST_SYS_FALSE,
    SendName    = <<"系统">>,
    Timestamp   = misc:seconds(),
    GoodsNum    = erlang:length(GoodsList),
    SendSex     = ?CONST_SYS_SEX_FAMALE,
    IsRead      = ?CONST_SYS_FALSE, 
    IsSave      = ?CONST_SYS_FALSE,
    IsPick      = if
                      GoodsNum > ?CONST_SYS_FALSE  -> ?CONST_SYS_TRUE;
                      Gold    =/= ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE;
                      Cash    =/= ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE;
                      BCash2  =/= ?CONST_SYS_FALSE -> ?CONST_SYS_TRUE;
                      ?true -> ?CONST_SYS_FALSE
                  end,
    Type1       = if
                      Type  =:= ?CONST_MAIL_GUILD -> ?CONST_MAIL_GUILD;
                      ?true -> ?CONST_MAIL_SYSTEM
                  end,
    try
        {?ok, ReceiveId}    = check_receiver(ReceiveName),
        ?ok                 = case Type =:= ?CONST_MAIL_INTEREST of
                                  ?true  -> ?ok;
                                  ?false -> check_mail_open(ReceiveId)
                              end,
        case insert_mail(Type1, SendUId, SendName, SendSex, ReceiveId, ReceiveName, Title, Timestamp, Content, 
                         MessageId, Content1, Cash, BCash, Gold, GoodsList, IsRead, IsSave, IsPick, Point, BCash2) of
            {?ok, Mail} ->
                Packet      = mail_api:msg_mail_info(Mail),
                misc_packet:send(ReceiveId, Packet);    
            {?error, Reason} ->
                {?error, Reason}
        end
    catch
        throw:{?error, ErrorCode} ->
                {?error, ErrorCode}
    end.
%% 获取物品种类
get_goods_type_num([Goods|GoodsList], Acc) when is_record(Goods, goods) ->
	GoodsType = Goods#goods.type,
	GoodsId = Goods#goods.goods_id,
	NewAcc    = case {lists:member(GoodsId, Acc), GoodsType =:= ?CONST_GOODS_TYPE_EQUIP} of
				 {?true, ?false}-> Acc;               %% 装备不能堆叠
				 _ -> [GoodsId|Acc]
			 end,
	get_goods_type_num(GoodsList, NewAcc);
get_goods_type_num([_|GoodsList], Acc) ->
	get_goods_type_num(GoodsList, Acc);
get_goods_type_num([], Acc) ->
	erlang:length(Acc).
	
%% 物品过多 拆分邮件
split_goods([Goods|GoodsList], Num, Acc) when is_record(Goods, goods) ->
	GoodsType = Goods#goods.type,
	NewAcc 	  = case {lists:member(Goods, Acc), GoodsType =:= ?CONST_GOODS_TYPE_EQUIP}of
				 {?true, ?false }-> [Goods|Acc];
				 _ ->
					 GoodsNum		= get_goods_type_num(Acc, []),
					 case GoodsNum + 1 > Num of
						 ?true -> Acc;
						 ?false -> [Goods|Acc]		  
					 end
			 end,
	split_goods(GoodsList, Num, NewAcc);
split_goods([_|GoodsList], Num, Acc) ->
	split_goods(GoodsList, Num, Acc);
split_goods([],_, Acc) ->
	Acc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     发送系统信件给多个收件人
%% @spec     send_system_mai_to_some/6
%% @param    ReceiveNameList:收件人列表  Title:标题 Content:内容 Goods:物品列表
%% @return   [{?ok, RName, Mail},...] | [{error, 110}]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
send_system_mai_to_some([], _, _, _, _, _,  _, _,  _,  _, _) -> ?ok;
send_system_mai_to_some([ReceiveName|ReceiveNameList], Title, Content, MessageId, Content1, GoodsList,  Gold,
						Cash, BCash, Type, Point) ->
					  send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, 
											  Gold, Cash, BCash, Type, Point, 0),
	send_system_mai_to_some(ReceiveNameList,Title, Content, MessageId, Content1, GoodsList,  Gold,Cash, BCash, Type, Point).
send_system_mail_to_some3(ReceiveNameList, Title, Content, MessageId, Content1, GoodsList,  Gold,
                        Cash, BCash, Type, Point, BCash2) ->
    F       = fun(ReceiveName) ->
                      send_system_mail_to_one3(ReceiveName, Title, Content, MessageId, Content1, GoodsList, 
                                              Gold, Cash, BCash, Type, Point, BCash2)
              end,
    [F(Name)|| Name <- ReceiveNameList].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc  	获取邮件列表
%% @spec  	list/1
%% @param 	Player 
%% @return 	packetage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
list(Player) ->					%% 收件箱列表
	UserId			= Player#player.user_id,
	case mail_list(UserId) of
		[] ->
			mail_api:msg_mail_list_info([]);
		List ->
			MailList		= filter_overdure_mail(List, []),
			mail_api:msg_mail_list_info(MailList)
	end.

mail_list(UserId) ->			%% 获取收件箱列表
	MailList		= ets_api:list(?CONST_ETS_MAIL),
	F	= fun(Mail, Acc) when is_record(Mail, mail) ->
				  RecvUId		= Mail#mail.recv_uid,
				  case RecvUId	=:= UserId of
					  ?true ->	[Mail|Acc];
					  ?false -> Acc
				  end;
			 (_, Acc) -> Acc
		  end,
	lists:foldl(F, [], MailList).

%% 发件箱列表
send_list(Player) ->
	UserId		= Player#player.user_id,
	case mail_send_list(UserId) of
		[] ->
			mail_api:msg_mail_send_list([]);
		List ->
			MailList	= filter_overdure_mail(List, []),
			mail_api:msg_mail_send_list(MailList)
	end.
%% 获取发件箱列表
mail_send_list(UserId) ->
	MailList		= ets_api:list(?CONST_ETS_MAIL),
	F	= fun(Mail, Acc) when is_record(Mail, mail) ->
				  SendUId		= Mail#mail.send_uid,
				  case SendUId	=:= UserId of
					  ?true ->	[Mail|Acc];
					  ?false -> Acc
				  end;
			 (_, Acc) -> Acc
		  end,
	lists:foldl(F, [], MailList).

%% 过滤过期邮件
filter_overdure_mail([Mail|RestList], Acc) ->
	Now			= misc:seconds(),
	MailId		= Mail#mail.mail_id,
	IsSave		= Mail#mail.is_save,
	EndTime		= Mail#mail.time + ?CONST_MAIL_SYS_KEEP * ?CONST_SYS_ONE_DAY_SECONDS,
	Flag		= misc:ceil((EndTime - Now)/?CONST_SYS_ONE_DAY_SECONDS),
	if 
		(Flag < ?CONST_SYS_FALSE) andalso (IsSave =/= ?CONST_MAIL_DO) -> 
			delete_one_mail(MailId),
			filter_overdure_mail(RestList, Acc);
		?true -> 
			filter_overdure_mail(RestList, [Mail|Acc])
	end;
filter_overdure_mail([], Acc) ->
	Acc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     读取邮件
%% @spec     read/2
%% @param    MailId:邮件Id
%% @return   ?ok | {?error, Reason}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
read(Player, MailId) when is_number(MailId) ->
	case mail_look_up(MailId) of
		{?error, ErrorCode} -> 
			TipPacket		= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?error, ErrorCode};
		Mail ->
			read(Player, Mail)
	end;
read(Player, #mail{recv_uid = UserId} = Mail) when Player#player.user_id =:= UserId ->
	IsRead		= Mail#mail.is_read,
	case IsRead of
		?CONST_MAIL_UNDO ->       %% 更新邮件读取状态(1 已读 0未读)
			mail_update([{is_read, 1}], Mail#mail{is_read = 1});
		?CONST_MAIL_DO ->
			?ok
	end;
read(Player, _) ->% 邮件不存在
	TipPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
	misc_packet:send(Player#player.net_pid, TipPacket),
	{?error, ?TIP_COMMON_BAD_ARG}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     保存邮件 (不用了)
%% @spec     save_mail/2
%% @param    MailIdList 保存邮件列表
%% @return   ?true
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
save_mail(MailIdList, Player) when is_list(MailIdList) ->
	F		= fun({MailId}) when MailId > ?CONST_SYS_FALSE ->
					  case mail_look_up(MailId) of
						  {?error, Errorcode} ->
							  {?error, Errorcode};
						  Mail ->
							  save_one_mail(Mail)
					  end;
				 (_X) ->
					  {?error, ?TIP_COMMON_SYS_ERROR}
			  end,
	Result 		= [F(Mail)|| Mail <- MailIdList],
	Packet		= case Result of
					  [{?error, Reason}|_DataList] ->
						  ?MSG_DEBUG("Reason=~p", [Reason]),
						  mail_api:msg_save_mail(Reason, []);
					  MailList ->
						  mail_api:msg_save_mail(?CONST_SYS_TRUE, MailList)
				  end,
	misc_packet:send(Player#player.net_pid, Packet);
save_mail(_, Player) ->
	TipPacket	= message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
	misc_packet:send(Player#player.net_pid, TipPacket).
	
save_one_mail(Mail) ->
	Goods		= Mail#mail.goods,
	Cash		= Mail#mail.cash,
	Gold		= Mail#mail.gold,
	if 
		is_record(Goods, goods) orelse Gold =/= ?CONST_SYS_FALSE orelse Cash =/= ?CONST_SYS_FALSE  ->            %% 包含附件
			{?error, ?CONST_MAIL_SAVE_CONTAIN_ATTACHMENT};
		?true ->              												 		%% 没有附件 更改保存状态 
			mail_update([{is_save, ?CONST_MAIL_DO}], Mail#mail{is_save = ?CONST_MAIL_DO}),
			{Mail#mail.mail_id}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     删除邮件
%% @spec     del_mail/2
%% @param    MailIdList 删除邮件列表 Uid 玩家id
%% @return   ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
delete_mail(MailIdList, Uid) when is_list(MailIdList) ->
	F	= fun({MailId}, Acc) ->
			   case mysql_api:delete(game_mail, "mail_id="++misc:to_list(MailId)++" and recv_uid="++misc:to_list(Uid)) of
				   {?ok, _, _} ->
					   ets_delete_mail(MailId, Uid),
					   [{MailId}|Acc];
				   {?error, _} -> Acc
			   end;
		  (_, Acc) -> Acc
	   end,
	List		= lists:foldl(F, [], MailIdList),
	TipPacket	= message_api:msg_notice(?TIP_MAIL_DELETE_SUCCESS),
	Packet1		= mail_api:msg_delete_mail(List),
	misc_packet:send(Uid, <<TipPacket/binary,Packet1/binary>>).

delete_one_mail(MailId) when is_number(MailId) ->
	case mysql_api:delete(game_mail, "mail_id="++misc:to_list(MailId)) of
		{?ok, _, _} ->
			ets_delete_mail(MailId, ?CONST_SYS_FALSE);
		{?error, ErrorCode} ->
			?MSG_ERROR("Error:~p ~n",[ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end. 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     获取附件
%% @spec     get_attachment/2
%% @param    MailId 邮件Id
%% @return   ok | {error, Reason}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
get_attachment(Player, MailId) ->
	RecvId	   = Player#player.user_id,
	case mail_look_up(MailId, RecvId) of
		{?error, _Reason} ->
			Packet		= message_api:msg_notice(?TIP_MAIL_GET_ATTACHMENT_FAIL),
			misc_packet:send(Player#player.net_pid, Packet),
			Player;
		Mail ->
			IsPick		= Mail#mail.is_pick,
			case IsPick of
				?CONST_MAIL_UNDO ->      %% 无附件领取
					TipPacket		= message_api:msg_notice(?TIP_MAIL_NOT_ATTACHMENT),
					misc_packet:send(Player#player.net_pid, TipPacket),
					Player;
				?CONST_MAIL_DO ->
					handle_goods_recv(Player, Mail)
			end
	end.

%% 处理附件中的物品
handle_goods_recv(Player, Mail) ->
	UserId			= Player#player.user_id,
	MailId			= Mail#mail.mail_id,
	IsPick 			= Mail#mail.is_pick,
	GoodsList		= Mail#mail.goods,
	try
		?ok 		= check_attachment_exsit(IsPick),
		?ok			= check_attachment_owner(MailId, UserId),
        ?MSG_ERROR("~p", [GoodsList]),
        case ctn_bag_api:put(Player, GoodsList, Mail#mail.point, 1, 1, 0, 0, 0, 1, []) of
			{?ok, Player2, _, Packet0} ->
				case mail_update([{is_pick, ?CONST_MAIL_UNDO},{goods, misc:encode([])}, {gold, 0}, {cash, 0}, 
							 {bcash, 0},{bcash2, 0}, {is_read, 0}, {is_read, ?CONST_MAIL_DO}], 
							Mail#mail{is_pick = ?CONST_MAIL_UNDO, goods = misc:encode([]), gold = 0, 
									  cash = 0, bcash = 0, is_read = ?CONST_MAIL_DO, bcash2 = 0}) of
					?ok ->
						?ok			= plus_money(Player, Mail);
					{?error, _} -> 
						throw({?error, ?TIP_COMMON_ERROR_DB})
				end,
				NewMial		= Mail#mail{is_pick = 0, goods = [], gold = 0, cash = 0,  bcash = 0, bcash2 = 0, is_read = ?CONST_MAIL_DO},
				Packet		= mail_api:msg_get_attachment(?CONST_MAIL_GET_SUCCESS),
				TipPacket	= notice_get_attachment(Mail),
				Packet2 	= mail_api:msg_mail_info(NewMial),
				misc_packet:send(Player2#player.net_pid, <<Packet0/binary, Packet2/binary, TipPacket/binary,
														  Packet/binary>>),
                admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_MAKE, Mail#mail.point, GoodsList, misc:seconds()), % 读取邮件的消费点
				Player2;
			{?error, ErrorCode} ->
				Packet		= message_api:msg_notice(ErrorCode),
				misc_packet:send(Player#player.net_pid, Packet),
				Player
		end
	catch 
		throw:{?error, ErrorReason} ->
			TipPacket1		= mail_api:msg_get_attachment(ErrorReason),
			misc_packet:send(Player#player.net_pid, TipPacket1),
			Player
	end.

%% 判断是否领取
check_attachment_exsit(IsPick) when IsPick =:= ?CONST_MAIL_DO -> ?ok;
check_attachment_exsit(_) ->throw({?error, ?TIP_MAIL_NOT_EXSIT}).

%% 判断附件是否为此玩家的
check_attachment_owner(MailId, UserId) ->
	case mail_look_up(MailId, UserId) of
		{?error, _} ->
			throw({?error, ?TIP_MAIL_GET_ATTACHMENT_FAIL});
		_ ->
			?ok
	end.

%% 获得金钱
plus_money(Player, Mail) ->
	UserId		= Player#player.user_id,
	Cash 		= Mail#mail.cash,
	Gold 		= Mail#mail.gold,
	BCash		= Mail#mail.bcash,
    BCash2      = Mail#mail.bcash2,
	Point		= Mail#mail.point,
	try
		?ok 		  = player_money_api:plus_money(UserId, ?CONST_SYS_CASH, Cash, Point),
		?ok 		  = player_money_api:plus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, Point),
		?ok			  = player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND, BCash, Point) ,
	    ?ok           = player_money_api:plus_money(UserId, ?CONST_SYS_CASH_BIND_2, BCash2, Point),
		admin_log_api:log_mail(Mail#mail.mail_id, 2, Mail#mail.type, 0, 0, 0, Mail#mail.send_name, Mail#mail.recv_name, 
							   Mail#mail.time, Cash, Gold, BCash, BCash2, Mail#mail.point, UserId)
	catch
		_:_ ->
			throw({?error, ?TIP_MAIL_GET_ATTACHMENT_FAIL})
	end.

%% 获得附件提示
notice_get_attachment(Mail) ->
	Gold 		= Mail#mail.gold,
	Cash 		= Mail#mail.cash,
	Goods		= Mail#mail.goods,
	BCash		= Mail#mail.bcash,
	Packet1		= case Gold =:= ?CONST_SYS_FALSE of
					  ?true  -> <<>>;
					  ?false ->
						  message_api:msg_notice(?TIP_MAIL_GET_GOLD, [{?TIP_SYS_COMM, misc:to_list(Gold)}])
				  end,
	Packet2		= case Cash =:= ?CONST_SYS_FALSE of
					  ?true  -> <<>>;
					  ?false ->
						  message_api:msg_notice(?TIP_MAIL_GET_CASH, [{?TIP_SYS_COMM, misc:to_list(Cash)}])
				  end,
	Packet3		= case BCash =:= ?CONST_SYS_FALSE of
					  ?true  -> <<>>;
					  ?false ->
						  message_api:msg_notice(?TIP_MAIL_GET_BCASH, [{?TIP_SYS_COMM, misc:to_list(BCash)}])
				  end,
%% 因为plus_money中给了得到绑定元宝提示，所以这里不给了
	Packet4		= msg_notice_goods(Goods, <<>>),
	<<Packet1/binary, Packet2/binary, Packet3/binary, Packet4/binary>>.

msg_notice_goods([Goods|List], Acc) when is_record(Goods, goods) ->
	GoodsName	= Goods#goods.name,
	GoodsNum	= Goods#goods.count,
	Packet		= message_api:msg_notice(?TIP_MAIL_GET_GOODS, [{?TIP_SYS_COMM, GoodsName}, {?TIP_SYS_COMM, misc:to_list(GoodsNum)}]),
	NewAcc		= <<Packet/binary, Acc/binary>>,
	msg_notice_goods(List, NewAcc);
msg_notice_goods(_, Acc) ->
	Acc.

%% 领取所有附件
get_all_attachment(Player) ->
	UserId		= Player#player.user_id,
	MailList	= get_mail_with_attachment(UserId),
	case MailList of
		[] -> 
			TipPacket		= message_api:msg_notice(?TIP_MAIL_NOT_ATTACHMENT),
			misc_packet:send(Player#player.net_pid, TipPacket),
			Player;
		_ ->
			refresh_get_attachment(Player, MailList, <<>>)
	end.

refresh_get_attachment(Player, [Mail|RestList], _) ->
	GoodsList		= Mail#mail.goods,
	Result 	=
		case plus_money(Player, Mail) of
			?ok ->
                case ctn_bag_api:put(Player, GoodsList, Mail#mail.point, 1, 1, 0, 0, 0, 1, []) of
					{?ok, NewPlayer, _, Packet0} ->
						mail_update([{is_pick, ?CONST_MAIL_UNDO},{goods, misc:encode([])}, {gold, 0}, {cash, 0}, 
									 {bcash, 0}, {is_read, ?CONST_MAIL_DO}], 
									Mail#mail{is_pick = ?CONST_MAIL_UNDO, goods = misc:encode([]), gold = 0, cash = 0,
											  is_read = ?CONST_MAIL_DO, bcash = 0}),
						NewMial		= Mail#mail{is_pick = 0, goods = [], gold = 0, cash = 0, bcash = 0, is_read = ?CONST_MAIL_DO},
						Packet2 	= mail_api:msg_mail_info(NewMial),
						Packet		= mail_api:msg_get_attachment(?CONST_MAIL_GET_SUCCESS),
						misc_packet:send(NewPlayer#player.net_pid, <<Packet0/binary, Packet2/binary, 
																  Packet/binary>>),
						{?ok, NewPlayer};
					{?error, _} ->
						{?error, Player}
				end;
			{?error, _} ->
				{?error, Player}
		end,
	case Result of
		{?ok, NewPlayer1} ->
			TipPacket	= message_api:msg_notice(?TIP_MAIL_GET_ATTACHMENT_SUCCESS),
			refresh_get_attachment(NewPlayer1, RestList, TipPacket);
		{?error, NewPlayer2} ->
			refresh_get_attachment(NewPlayer2, [], <<>>)
	end;
refresh_get_attachment(NewPlayer2, [], TipPacket) ->
	misc_packet:send(NewPlayer2#player.net_pid, TipPacket),
	NewPlayer2.

get_mail_with_attachment(UserId) ->
	List		= ets_api:list(?CONST_ETS_MAIL),
	F	= fun(Mail, Acc) when is_record(Mail, mail) ->
				RecvId		= Mail#mail.recv_uid,
				IsPick		= Mail#mail.is_pick,
				case {RecvId =:= UserId, IsPick =:= ?CONST_MAIL_DO} of
					{?true, ?true} -> [Mail|Acc];
					{_, _} -> Acc
				end;
			 (_, Acc) -> Acc
		  end,
	lists:foldl(F, [], List).
%%--------------------------------------------------------------------------------------------------
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     定期调用删除过期邮件
%% @spec     clean_mail/0
%% @param    无
%% @return   ?ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
clean_mail() ->
	Time		= misc:seconds() - ?CONST_MAIL_SYS_KEEP * ?CONST_SYS_ONE_DAY_SECONDS,
	Where		= <<"WHERE `time` < ", (misc:to_binary(Time))/binary>>,
	case mysql_api:select_execute(<<"SELECT `mail_id` FROM `game_mail` ", Where/binary, ";">>) of
		{?ok, []} ->
			?ok;
		{?ok, MailIdList} ->
			case mysql_api:execute(<<"DELETE FROM `game_mail` ", Where/binary, ";">>) of
				{?ok, AffectedRows, _} ->
					?MSG_DEBUG("AffectedRows:~p length(MailIdList:~p", [AffectedRows, length(MailIdList)]),
					[ets_delete_mail(MailId, ?CONST_SYS_FALSE) || [MailId] <- MailIdList];
				{?error, Error} ->
					?MSG_ERROR("~n{?error, Error}=~p", [{?error, Error}]),
					{?error, ?TIP_COMMON_ERROR_DB}
			end;
		{?error, ErrorCode} ->
			?MSG_DEBUG("~nErrorCode=~p", [ErrorCode]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%%
%%%%local Functions
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     检查邮件是否已满
%% @spec     check_mail_full/1
%% @param    UserId 对方Id
%% @return   true | false | {error, Reason}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
check_mail_full(UserId, Count, ?CONST_MAIL_PRIVATE) ->
	List		= ets_api:list(?CONST_ETS_MAIL),
	F		= fun(Mail, Acc) when is_record(Mail, mail) andalso Mail#mail.recv_uid =:= UserId->
					  Type		= Mail#mail.type,
					  if
						  Type =:= ?CONST_MAIL_PRIVATE orelse 
						  Type =:= ?CONST_MAIL_STRANGE -> Acc + 1;
						  ?true -> Acc
					  end;
				 (_, Acc) -> Acc
			  end,
	Num		= lists:foldl(F, 0, List) + Count,
	if 
		Num =< ?CONST_MAIL_MAX_NUM ->     %% 总共50封邮件(除去系统邮件)
			?MSG_DEBUG("Num=~p", [Num]),
			?ok;
		?true ->
			throw({?error, ?TIP_MAIL_OTHER_MAIL_FULL})
	end;
check_mail_full(_UserId, _Count, _) ->
	?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     插入新信件
%% @spec     insert_mail/14
%% @param    邮件record各元素
%% @return   ?ok | {?error, Reason}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 	
insert_mail(Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
            MessageId, Content1, Cash, BCash, Gold, GoodsList, IsRead, IsSave, IsPick, 
            Point, Bcash2) ->
%%     ?MSG_ERROR("insert_mail:~p~n",[{Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
%%             MessageId, Content1, Cash, BCash, Gold, GoodsList, IsRead, IsSave, IsPick, 
%%             Point, Bcash2}]),
    ZipedGoods      = mail_api:zip_goods_data(GoodsList),
    case mysql_api:insert(game_mail,
                          [{type, Type},        {send_uid, SendUid},    {send_name, SendName}, {send_sex, SendSex},
                           {recv_uid, RecvUid}, {recv_name, RecvName},  {title, Title}, {time, Time}, {content, Content}, 
                           {message_id, MessageId}, {content1, misc:encode(Content1)}, {cash, Cash}, {bcash, BCash}, 
                           {gold, Gold}, {goods, misc:encode(ZipedGoods)},{is_read, IsRead}, {is_save, IsSave}, 
                           {is_pick, IsPick}, {point, Point},{bcash2, Bcash2}]) of
        {?ok, _, MailId} ->
            Mail = record_mail(MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
                               MessageId, Content1, Cash, BCash, Gold, GoodsList, IsRead, IsSave, IsPick, Point,
                               Bcash2),
            ets_insert_mail(Mail),
            {?ok, Mail};
        {?error, Error} ->
            ?MSG_DEBUG("Error:~p",[Error]),
            {?error, ?TIP_COMMON_ERROR_DB}
    end.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     邮件增删改查操作
%% @spec     mail_look_up/1 mail_insert/1 mail_update/1
%% @param    邮件Id
%% @return   {?ok, Mail}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
mail_look_up(MailId) ->
	case ets_lookup_mail(MailId) of					
		?null ->
			 {?error, ?TIP_COMMON_ERROR_DB};
		Mail -> 
			Mail
	end.

mail_look_up(MailId, UserId) ->
	case ets_lookup_mail(MailId) of
		?null -> {?error, ?TIP_COMMON_ERROR_DB};
		Mail when is_record(Mail, mail)->
			RecvId		= Mail#mail.recv_uid,
			case RecvId =:= UserId of
				?true -> Mail;
				?false -> {?error, ?TIP_COMMON_ERROR_DB}
			end;
		_ -> {?error, ?TIP_COMMON_ERROR_DB}
	end.

mail_update(DataList, Mail) when is_record(Mail, mail)->
	case mysql_api:update(game_mail, DataList, [{mail_id, Mail#mail.mail_id}]) of
		{?ok, _Result} ->
			ets_insert_mail(Mail),
			?ok;
		{?error, _ErrorCode} ->
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     邮件ets操作
%% @spec     ets_lookup_mail/1 ets_insert_mail/1 ets_delete_mail/1 ets_insert_list/1
%% @param    邮件Id
%% @return   ok
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
ets_lookup_mail(MailId) ->%   查找邮件
	ets_api:lookup(?CONST_ETS_MAIL, MailId).

ets_insert_mail(Mail) ->% 插入邮件
	ets_api:insert(?CONST_ETS_MAIL, Mail).

ets_delete_mail(MailId, UserId) ->%   删除邮件
    case ets_lookup_mail(MailId) of
        #mail{goods = Goods, mail_id = MailId, type = Type, send_name = SName, recv_name = RName,
			  time = TimeS, cash = Cash, gold = Gold,bcash = BCash, point = Point, bcash2 = BCash2} when is_list(Goods) ->
			if
                (Goods =:= [] andalso (Gold =/= 0 orelse Cash =/= 0)) ->
                    admin_log_api:log_mail(MailId, ?CONST_SYS_GOODS_USE, Type, 0, 0, 0, SName, RName, TimeS, Cash, Gold, BCash, BCash2, Point,
                                           UserId);
                ?true ->
                    F = fun(#goods{goods_id = GoodsId, count = Count, bind = Bind}) ->
                                admin_log_api:log_mail(MailId, ?CONST_SYS_GOODS_USE, Type, GoodsId, Count, Bind, SName, RName, TimeS, 
                                                       Cash, Gold,BCash ,BCash2, Point, UserId);
                           (_) -> 0
						end,
					lists:foreach(F, Goods)
			end;
		_ -> ?ok
    end,
    ets_api:delete(?CONST_ETS_MAIL, MailId).


ets_insert_list([Mail|MailList]) ->
	ets_insert_mail(Mail),
	ets_insert_list(MailList);
ets_insert_list([]) ->% 将邮件列表数据插入ets表中
	?ok.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc     邮件记录与数据转换
%% @spec     record_mail/1
%% @param    邮件record各元素
%% @return   #mail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
record_mail([MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
			 MessageId, Content1, Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, Point, BCash2]) ->
	record_mail(MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
				MessageId, Content1, Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, Point ,BCash2);
record_mail({MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
			 MessageId, Content1, Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, Point, BCash2}) ->
	record_mail(MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
				MessageId, Content1, Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, Point,BCash2).
record_mail(MailId, Type, SendUid, SendName, SendSex, RecvUid, RecvName, Title, Time, Content, 
			MessageId, Content1, Cash, BCash, Gold, Goods, IsRead, IsSave, IsPick, Point, BCash2) ->
	#mail{
		  mail_id	            = MailId,			% 邮件ID
		  type		            = Type,				% 邮件类型(系统:0|私人:1)
		  send_uid	            = SendUid,			% 发件人Uid
		  send_name	            = SendName,			% 发件人名字
		  send_sex	            = SendSex,          % 发件人性别
		  recv_uid	            = RecvUid,			% 收件人Uid
		  recv_name	            = RecvName,			% 收件人名字
		  title		            = Title,			% 标题
		  time		            = Time,				% 时间
		  content	            = Content,			% 内容
		  message_id			= MessageId,        % 消息内容id
		  content1				= Content1,			% 消息内容
		  cash		            = Cash,				% 元宝
		  bcash					= BCash,            % 绑定元宝
		  gold		            = Gold,				% 铜币
		  goods		            = Goods,			% 物品
		  is_read	            = IsRead,			% 邮件状态(未读:0|已读:1)
		  is_save	            = IsSave,			% 邮件状态(未读:0|已读:1)
		  is_pick	            = IsPick,			% 附件是否提取(无附件:0|未提取:1|已提取:2)
		  point				    = Point	,			% 功能消费点
          bcash2                = BCash2
		 }.