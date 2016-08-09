%%%-----------------------------------
%%% @Module  	: chat_mod
%%% @Created 	: 2010.10.14
%%% @Description: 聊天  
%%%-----------------------------------
-module(chat_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
%%
%% Exported Functions
%%
-export([chat/4, chat_private/3,chat_user_data/3]).

chat(Player, Channel, Content, GoodsList) ->
	case check_shutup_over(Player) of
		{?ok, Player2} ->
			case gm_api:gm(Player2, Content) of
				{?ok, NewPlayer} ->
					Packet 	= message_api:msg_notice(?TIP_COMMON_GM_SUCCESS),
					misc_packet:send(NewPlayer#player.net_pid, Packet),
					NewPlayer;
				{?error, NewPlayer} ->
					Packet 	= message_api:msg_notice(?TIP_COMMON_GM_FAIL),
					misc_packet:send(NewPlayer#player.net_pid, Packet),
					NewPlayer;
				{?false, NewPlayer} ->
					admin_api:data_monitor_chat(NewPlayer,Channel,Content),
					hundred_serv_api:talk(Content, Player, Channel),
					admin_log_api:log_chat(NewPlayer, Channel, Content),
					{Goods, Equip}	= chat_goods(NewPlayer, GoodsList, [], []),
					Packet	= chat_api:msg_chat_sc_chat(NewPlayer, Channel, Content, lists:reverse(Goods), lists:reverse(Equip)),
					chat(NewPlayer, Channel, Packet);
                {?false, NewPlayer, ?null} ->
					admin_api:data_monitor_chat(NewPlayer,Channel,Content),
                     admin_log_api:log_chat(NewPlayer, Channel, Content),
                    {Goods, Equip}  = chat_goods(NewPlayer, GoodsList, [], []),
                    Packet  = chat_api:msg_chat_sc_chat(NewPlayer, Channel, <<"*">>, lists:reverse(Goods), lists:reverse(Equip)),
                    chat(NewPlayer, Channel, Packet)
			end;
		{?error, ErrorCode} ->
			Packet = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, Packet),
			Player
	end.

chat_goods(Player, [{CtnType, PartnerId, Idx}|List], AccGoods, AccEquip) ->
	Result	=
		if
			CtnType =:= ?CONST_GOODS_CTN_BAG -> {?ok, Player#player.bag};
			CtnType =:= ?CONST_GOODS_CTN_DEPOT -> {?ok, Player#player.depot};
			CtnType =:= ?CONST_GOODS_CTN_EQUIP_PLAYER ->
				Key = {Player#player.user_id, ?CONST_GOODS_CTN_EQUIP_PLAYER},
				{Key, CtnEquip}	= lists:keyfind(Key, 1, Player#player.equip),
				{?ok, CtnEquip};
			CtnType =:= ?CONST_GOODS_CTN_EQUIP_PARTNER ->
				Key = {PartnerId, ?CONST_GOODS_CTN_EQUIP_PARTNER},
				{Key, CtnEquip}	= lists:keyfind(Key, 1, Player#player.equip),
				{?ok, CtnEquip};
			?true -> {?error, ?TIP_COMMON_BAD_ARG}
		end,
	case Result of
		{?ok, Ctn} when is_record(Ctn, ctn) ->
			case ctn_bag2_api:read(Ctn, Idx) of
				{?ok, Goods}
				  when is_record(Goods, goods) andalso Goods#goods.type =:= ?CONST_GOODS_TYPE_EQUIP ->
					Data = goods_api:msg_group_goods_equip(?CONST_GOODS_CTN_BAG, Player#player.user_id, 0, Goods),
					chat_goods(Player, List, AccGoods, [Data|AccEquip]);
				{?ok, Goods}
				  when is_record(Goods, goods) andalso Goods#goods.type =:= ?CONST_GOODS_TYPE_WEAPON ->
					Data = goods_api:msg_group_goods_weapon(?CONST_GOODS_CTN_BAG, Player#player.user_id, 0, Goods),
					chat_goods(Player, List, AccGoods, [Data|AccEquip]);
				{?ok, Goods}
				  when is_record(Goods, goods) ->
					Data = goods_api:msg_group_goods(?CONST_GOODS_CTN_BAG, Player#player.user_id, 0, Goods),
					chat_goods(Player, List, [Data|AccGoods], AccEquip);
				_ -> chat_goods(Player, List, AccGoods, AccEquip)
			end;
		_ -> chat_goods(Player, List, AccGoods, AccEquip)
	end;
chat_goods(_Player, [], AccGoods, AccEquip) -> {AccGoods, AccEquip}.

chat(Player, ?CONST_CHAT_WORLD, Packet) ->% 聊天频道--世界
	Info	= Player#player.info,
	if
		Info#info.lv >= 0 ->
			misc_app:broadcast_world(Packet),
%% 			node_api:send_info(chat_handler, Packet),
			{?ok, Player2}	= schedule_api:add_guide_times(Player, ?CONST_SCHEDULE_GUIDE_WORLD_CHAT),
			{_, Player3}  = welfare_api:add_pullulation(Player2, ?CONST_WELFARE_CHAT, 0, 1),
			Player3;
		?true ->
			?MSG_PRINT("fail chat with lv not enough   ~p", [Info#info.lv]),
			Player
	end;
chat(Player, ?CONST_CHAT_SYS, Packet) ->% 聊天频道--系统
	misc_app:broadcast_world(Packet),
	Player;
chat(Player, ?CONST_CHAT_SPEAKER, Packet) ->% 聊天频道--喇叭
	case check_speaker(Player) of
		{?ok, Player2, _PacketGoods} ->
			achievement_api:add_achievement(Player#player.user_id, ?CONST_ACHIEVEMENT_TROMBA, 0, 1),
			misc_app:broadcast_world_2(Packet),
			?MSG_DEBUG("broadcast_world  ~p", [Packet]),
			Player2;
		{error, _ErrorCode} ->
			Player
	end;
chat(Player, ?CONST_CHAT_MAP, Packet) ->% 聊天频道--地图
	map_api:broadcast(Player, Packet),
	Player;
chat(Player, ?CONST_CHAT_COUNTRY, _Packet) ->% 聊天频道--国家
	Info	= Player#player.info,
	if
		Info#info.country =:= ?CONST_SYS_COUNTRY_DEFAULT ->
			Player;
		?true ->
			% 国家广播...
			Player
	end;
chat(Player, ?CONST_CHAT_GUILD, Packet) ->% 聊天频道--军团
	Guild	= Player#player.guild,
	if
		Guild#guild.guild_id =:= 0 ->
			?MSG_DEBUG("guild not join ~p", [{Player#player.user_id,  Guild}]),
			Player;
		?true ->
			% 军团广播...
			?MSG_DEBUG("guild chat ~p", [Guild]),
			guild_api:brocast(Guild#guild.guild_id, Packet),
			Player
	end;
chat(Player, ?CONST_CHAT_TEAM, Packet) ->% 聊天频道--组队
    team_api:broadcast_team(Player, Packet),
	Player;

chat(Player, ?CONST_CHAT_CAMP, Packet) ->% 聊天频道--组队
    Info = Player#player.info,
    camp_pvp_api:broad_camp(Player#player.user_id, Info#info.lv, Packet),
    Player.

chat_private(Player, UserId, Content) ->
	case relation_api:is_be_black(Player#player.user_id,UserId) of			%检查是否在接收消息方的黑名单
		?true ->
			TipPacket 	= message_api:msg_notice(?TIP_RELATIONSHIP_BLACKLIST),
			Packet		= chat_api:msg_sc_black(UserId),
			misc_packet:send(Player#player.user_id, <<TipPacket/binary, Packet/binary>>);
		?false  ->
			relation_api:add_contacted(Player#player.user_id, UserId),
			relation_api:add_contacted(UserId, Player#player.user_id),
			Packet		= chat_api:msg_chat_sc_private(Player, Content),
			misc_packet:send(UserId, Packet),
			admin_api:data_monitor_chat(Player, ?CONST_CHAT_PRIVATE,Content),
			admin_log_api:log_chat(Player, ?CONST_CHAT_PRIVATE, Content)
	end.

%% 检查背包中有无小喇叭
check_speaker(Player) ->
	Num = ctn_bag2_api:get_goods_count(Player#player.bag, ?CONST_CHAT_SPEAKER_ID),
	case (Num > 0) of
		?true ->
			case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, ?CONST_CHAT_SPEAKER_ID, 1) of
				{?ok, Container, _GoodsList, Packet} ->
					admin_log_api:log_goods(Player#player.user_id, 0, ?CONST_COST_CHAT_SPEAKER, ?CONST_CHAT_SPEAKER_ID, 1, misc:seconds()),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player#player{bag = Container}, Packet};
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end;
		?false ->
			Goods = data_goods:get_goods(?CONST_CHAT_SPEAKER_ID),
			Exts  = Goods#goods.exts,
			Cash  = Exts#g_func.convert_cash,
			case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, Cash, ?CONST_COST_CHAT_SPEAKER) of
				?ok ->
					{?ok, Player, <<>>};
				_Other ->
					{?error, 0}
			end
	end.

%% 检查是否解除禁言
check_shutup_over(Player = #player{info = #info{chat_status = ?CONST_CHAT_SHUTUP_NO}}) -> {?ok, Player};
check_shutup_over(Player = #player{info = Info}) ->
	case (misc:seconds() > Info#info.shutup_over) of
		?true ->
			Info2	= Info#info{chat_status = ?CONST_CHAT_SHUTUP_NO, shutup_over = 0},
			{?ok, Player#player{info = Info2}};
		?false -> {?error, ?TIP_CHAT_SHUTUP}
	end.

%% 获取对方信息
chat_user_data(Player, UserId, Type) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.guild, #player.position]) of
		{?ok, [Info = #info{user_name = UserName, pro = Pro, sex = Sex, lv = Lv}, Guild, 
					  #position_data{position = Position}]} ->
			GuildName	= Guild#guild.guild_name,
			IsOnline	= case player_api:check_online(UserId) of
							  ?true  -> ?CONST_SYS_TRUE;
							  ?false -> ?CONST_SYS_FALSE
						  end,
			VipLv		= player_api:get_vip_lv(Info),
			Packet8022 	= chat_api:msg_sc_user_data(UserId,UserName,Pro,Sex,Lv,VipLv,GuildName,IsOnline,Position,Type),
			misc_packet:send(Player#player.net_pid, Packet8022);
		_ -> ?ok
	end.



 



