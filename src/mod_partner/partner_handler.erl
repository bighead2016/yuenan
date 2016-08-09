%% Author: Administrator
%% Created: 2012-7-16
%% Description: TODO: Add description to partner_handler
-module(partner_handler).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.tip.hrl").
%% -include("record.camp.hrl").
%%
%% Exported Functions
%%
-export([handler/3]).

%%
%% API Functions
%%

%%=========================================================================
%% 接口函数 
%%=========================================================================

%% ---------------------------------------------------------------
%% -----------------------------------------------------------------

%% 查询武将信息
handler(?MSG_ID_PARTNER_CS_INFO, Player, {UserId}) ->
	SelfUserId = Player#player.user_id,
	PacketData		= if UserId =:= 0 orelse UserId =:= SelfUserId ->
							PartnerList = partner_mod:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
						 	partner_api:msg_partner_info_list(Player, 0, PartnerList);
					 ?true ->	%% 如果不是自己
%% 						 ?MSG_ERROR("User is not self! UserId:~p", [UserId]),
						 case player_api:get_player_fields(UserId, [#player.partner, #player.equip]) of
							 {?ok, [PartnerData, Equip]} ->
								 PartnerList = partner_mod:get_partner_by_team(PartnerData, ?CONST_PARTNER_TEAM_IN),
								 partner_api:msg_partner_info_list(UserId, Equip, 0, PartnerList);
							 {?error, _ErrorCode} -> <<>>
						 end
				  end,
	misc_packet:send(Player#player.net_pid, PacketData),
	?ok;

%% 解散武将
handler(?MSG_ID_PARTNER_CS_FREE, Player, {PartnerId}) ->
	case partner_mod:free_partner(Player, PartnerId) of
		{?ok,  _ID, Player1} ->
			admin_log_api:log_partner(Player, PartnerId, ?CONST_LOG_FUN_PARTNER_FIRE, 0, 0, 0),
			BinData = [PartnerId],
			PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_FREE, ?MSG_FORMAT_PARTNER_SC_FREE, BinData),
			misc_packet:send(Player#player.user_id, PacketData),
			{?ok, Player1};
		_Other ->
			?ok
	end;


%% 武将组合
handler(?MSG_ID_PARTNER_CS_ASSEMBLE, _Player, {_UserId}) ->
%% 	SelfUserId = Player#player.user_id,
%% 	PacketData		= 
%% 		if UserId =:= 0 orelse UserId =:= SelfUserId ->
%% 			  partner_api:msg_partner_assemble_list(Player, 0, []);
%% 		   ?true ->	%% 如果不是自己
%% 				case player_api:get_player_first(UserId) of
%% 					 {?ok, ?null, _IsOnline} ->
%% 						 <<>>;
%% 					 {?ok, Player2, _IsOnline} ->
%% 						 partner_api:msg_partner_assemble_list(Player2, 0, [])
%% 				 end
%% 		end,
%% 	misc_packet:send(Player#player.net_pid, PacketData),
	?ok;

%% 人物面板心法信息
handler(?MSG_ID_PARTNER_MIND_INFO, Player, {UserId, PartnerId}) ->
	SelfUserId = Player#player.user_id,
	PacketData	=
		if UserId =:= 0 orelse UserId =:= SelfUserId ->
			  partner_api:msg_partner_mind_info(Player, UserId, PartnerId);
		   ?true -> %% 如果不是自己
			   case player_api:get_player_first(UserId) of
				   {?ok, ?null, _IsOnline} ->
					   <<>>;
				   {?ok, Player2, _IsOnline} ->
					   partner_api:msg_partner_mind_info(Player2, UserId, PartnerId)
			   end
		end,
	misc_packet:send(Player#player.user_id, PacketData),
	?ok;

%% 武将/角色培养(PartnerId为0则为角色培养)
handler(?MSG_ID_PARTNER_CS_TRAIN, Player, {Type, PartnerId}) ->
	case Type of
		?CONST_PLAYER_TRAIN_TYPE_5 -> %% 一键培养直接保存
			{?ok, Player2} = partner_api:train(Player, Type, PartnerId),
			partner_api:trained_save(Player2, PartnerId);
		_ ->
			partner_api:train(Player, Type, PartnerId)
	end;

%% 保存武将培养属性(PartnerId为0则为保存角色培养属性)
handler(?MSG_ID_PARTNER_CS_SAVE_TRAIN, Player, {PartnerId}) ->
	partner_api:trained_save(Player, PartnerId);

%% 取消培养的属性(PartnerId为0则为取消角色培养属性)
handler(?MSG_ID_PARTNER_CS_CANCEL_TAIN, Player, {PartnerId}) ->
	{?ok, NewPlayer} = 
		case PartnerId =:= 0 of
			?true ->
				player_api:player_trained_cancel(Player);
			?false ->
				partner_mod:cancel_trained_partner(Player,PartnerId)
		end,
	{?ok, NewPlayer};

%% 武将继承
handler(?MSG_ID_PARTNER_CS_INHERIT, Player, {ToPartnerId, FromPartnerId}) ->
	case partner_mod:inherit_partner_attribute(Player,ToPartnerId, FromPartnerId) of
		{?ok, NewPlayer} ->
			{?ok, NewPlayer};
		_Other ->
			?ok
	end;


%% 副将界面设置武将
handler(?MSG_ID_PARTNER_CS_SET_ASSIST, Player, {IdFrom, IdTo, AssIdxTo}) ->
	{?ok, NewPlayer} = partner_assist_api:set_assist(Player, IdFrom, IdTo, AssIdxTo),
    schedule_power_api:do_change_assist(NewPlayer),
    schedule_power_api:do_change_assemble(NewPlayer),
	{?ok, NewPlayer};

%% 副将界面移除武将
handler(?MSG_ID_PARTNER_CS_REMOVE_ASSIST, Player, {IdFrom, AssIdx}) ->
	{?ok, NewPlayer} = partner_assist_api:remove_assist(Player, IdFrom, AssIdx),
    schedule_power_api:do_change_assist(NewPlayer),
    schedule_power_api:do_change_assemble(NewPlayer),
	{?ok, NewPlayer};

%% 武将所有阵法列表
handler(?MSG_ID_PARTNER_CS_CAMP_LIST, Player, {PartnerId}) ->
	List			= partner_assist_api:get_partner_camp_list(Player, PartnerId),
	Fun 			= fun(CampId) ->
							  {CampId}
					  end,
	CampIdList		= lists:map(Fun, List),
	Data			= [PartnerId, CampIdList],
	PacketData		= misc_packet:pack(?MSG_ID_PARTNER_SC_CAMP_LIST, ?MSG_FORMAT_PARTNER_SC_CAMP_LIST, Data),
	misc_packet:send(Player#player.user_id, PacketData),
	?ok;

%% ---------------------------------------------------------------------
%% 招募系统
%% ---------------------------------------------------------------------
%% 扩展招贤馆格子数(待删除)
handler(?MSG_ID_PARTNER_CS_EXT_BAG, _Player, {}) ->
	?ok;

%% 招贤馆遣散武将(待删除)
handler(?MSG_ID_PARTNER_CS_PUB_FREE, _Player, {_Type, _PartnerId}) ->
	?ok;


%% 增加寻访次数(待删除)
handler(?MSG_ID_PARTNER_CS_ADD_LOOKNUM, _Player, {}) ->
	?ok;


%% 清除寻访cd
handler(?MSG_ID_PARTNER_CS_CLEAN_LOOK_CD, Player, {}) ->
	case partner_mod:clean_look_cd(Player) of
		{?ok, Res, NewPlayer} ->
			PacketData = misc_packet:pack(?MSG_ID_PARTNER_SC_CLEAN_LOOK_CD, ?MSG_FORMAT_PARTNER_SC_CLEAN_LOOK_CD, [Res]),
			misc_packet:send(Player#player.user_id, PacketData),
			{?ok, NewPlayer};
		_OtherRes ->
			?ok
	end;

%% 招贤馆名满天下标签
handler(?MSG_ID_PARTNER_CS_FAMOUS, Player, {}) ->
	TopPass = tower_api:get_top_pass(Player#player.user_id),
	IsOn =  TopPass >= ?CONST_PARTNER_FAMOUS_PASS,
	Data = misc_packet:pack(?MSG_ID_PARTNER_SC_FAMOUS, ?MSG_FORMAT_PARTNER_SC_FAMOUS, [IsOn, TopPass]),
	misc_packet:send(Player#player.user_id, Data),
	?ok;

%% 一键换装备
handler(?MSG_ID_PARTNER_CS_CHANGE_EQUIP_ONCE, Player, {FromId,ToId}) ->
	partner_mod:change_equip_once(Player, FromId, ToId);

%% 一键换心法
handler(?MSG_ID_PARTNER_CS_CHANGE_MIND_ONCE, Player, {FromId,ToId}) ->
	partner_mod:change_mind_once(Player, FromId, ToId);

%% 寻访界面信息
handler(?MSG_ID_PARTNER_CS_LOOKFOR_INFO, Player, {}) ->
	PacketLook 	= partner_api:msg_get_lookfor_info(Player),
	misc_packet:send(Player#player.user_id, PacketLook),
	{?ok, Player};

%% 寻访
handler(?MSG_ID_PARTNER_CS_LOOKFOR, Player, {Type,IsUse,IsCashBind}) ->
	case partner_mod:lookfor_partner(Player, Type, IsUse, IsCashBind) of
		{?ok,  NewPlayer, GetId, LookStamp, FrontThree} ->
			admin_log_api:log_partner(Player, GetId, ?CONST_LOG_FUN_PARTNER_LOOKER, 0, 0, Type),
			NewSee			= (NewPlayer#player.info)#info.see,
			NewLookCashBind = (NewPlayer#player.lookfor)#lookfor_data.look_cash_bind,
			PacketLook = partner_api:msg_get_lookfor(GetId, LookStamp, NewSee, NewLookCashBind, FrontThree),
			misc_packet:send(Player#player.net_pid, PacketLook),
			case Type of 
				?CONST_PARTNER_LOOK_TYPE_CASH_2 ->
					spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 2);
				?CONST_PARTNER_LOOK_TYPE_CASH_3 ->
					spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 16);
				_ ->
					skip
			end,
			case IsUse of
				1 ->
					spirit_festival_activity_api:receive_redbag(Player#player.user_id, 16, 2);
				_ ->
					skip
			end,
			{?ok, NewPlayer};
		{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end;

%% 招募
handler(?MSG_ID_PARTNER_CS_RECRUIT, Player, {PartnerId}) ->
	case partner_mod:recruit_partner(Player, PartnerId) of
		{?ok, NewPlayer} ->
			{?ok, NewPlayer};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;
%% 拜见
handler(?MSG_ID_PARTNER_CS_CALL_ON, Player, {PartnerId}) ->
	case partner_mod:call_on_partner(Player, PartnerId) of
		{?ok, NewPlayer} ->
			NewSee		= (NewPlayer#player.info)#info.see,
			PacketData  = misc_packet:pack(?MSG_ID_PARTNER_SC_CALL_ON, ?MSG_FORMAT_PARTNER_SC_CALL_ON, [PartnerId, NewSee]),
			misc_packet:send(Player#player.user_id, PacketData),
			{?ok, NewPlayer};
		{?error, ErrorCode} -> {?error, ErrorCode}
	end;

%% 组合界面信息
handler(?MSG_ID_PARTNER_CS_ASSEMBLE_INFO, Player, {}) ->
	partner_mod:assemble_info(Player);
%% 升级组合
handler(?MSG_ID_PARTNER_CS_UP_ASSEMBLE, Player, {AssId,BookCount}) ->
	case partner_mod:assemble_level_up(Player, AssId, BookCount) of
		{?ok, Player2} ->
			{?ok, Player2};
		{?error, ErrorCode} ->
			TipPacket = message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipPacket),
			{?ok, Player}
	end;

%% 已激活武将列表
handler(?MSG_ID_PARTNER_CS_LOOKED_LIST, Player, {}) ->
	partner_mod:looked_list_info(Player);

%% 新获得武将列表
handler(?MSG_ID_PARTNER_CS_LOOK_NEW_LIST, Player, {}) ->
	partner_mod:look_new_list_info(Player);

%% 查看新武将
handler(?MSG_ID_PARTNER_CS_DEL_LOOK_NEW, Player, {PartnerId}) ->
	{?ok, Player2, Result} = partner_mod:del_look_new_list(Player, PartnerId),
	case Result of
		1 ->
			Packet	= misc_packet:pack(?MSG_ID_PARTNER_SC_DEL_LOOK_NEW, ?MSG_FORMAT_PARTNER_SC_DEL_LOOK_NEW, [PartnerId]),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player2};
		_ ->
			{?ok, Player2}
	end;
			
%% 新获得组合列表
handler(?MSG_ID_PARTNER_CS_LOOK_NEW_ASSEMBLE, Player, {}) ->
	partner_mod:look_new_ass_info(Player);

%% 查看新组合
handler(?MSG_ID_PARTNER_CS_DEL_ASS_NEW, Player, {AssId}) ->
	{?ok, Player2, Result} = partner_mod:del_look_new_ass(Player, AssId),
	case Result of
		1 ->
			Packet	= misc_packet:pack(?MSG_ID_PARTNER_SC_DEL_ASS_NEW, ?MSG_FORMAT_PARTNER_SC_DEL_ASS_NEW, [AssId]),
			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player2};
		_ ->
			{?ok, Player2}
	end;

%% 寻访提示
handler(?MSG_ID_PARTNER_CS_LOOK_NOTICE, Player, {PartnerId}) ->
	case partner_api:get_base_partner(Player, PartnerId) of
		BasePartner when is_record(BasePartner, partner) -> 
			AddSee			 = BasePartner#partner.call_on_see,
			Packet			 = message_api:msg_notice(?TIP_PARTNER_LOOKFOR_GET_REWARD, [{?TIP_SYS_PARTNER, misc:to_list(PartnerId)},
																			   {?TIP_SYS_COMM, misc:to_list(AddSee)}]),
			Packet2			 = message_api:msg_notice(?TIP_PARTNER_LOOK_GET_SEE, [{?TIP_SYS_COMM, misc:to_list(AddSee)}]),
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
			case BasePartner#partner.color >= ?CONST_SYS_COLOR_ORANGE of
				?true ->
					PacketBroad = message_api:msg_notice(?TIP_PARTNER_LOOK_SUPPER_COLOR, [{Player#player.user_id, (Player#player.info)#info.user_name}], [], 
												   [{?TIP_SYS_PARTNER,  misc:to_list(BasePartner#partner.partner_id)}]),	%橙色及以上武将全服广播
					misc_app:broadcast_world_2(PacketBroad);
				?false ->
					?ok
			end;
		_ ->
			?MSG_ERROR("PartnerId is not exist! PartnerId:~p", [PartnerId]),
			?ok
	end,
	Player2			= partner_mod:update_looked_list(Player, PartnerId),						%% 存进lookfor结构中
	Player3			= partner_mod:add_assemble(Player2, PartnerId),	
	{?ok, Player3};

%% 请求培养
handler(?MSG_ID_PARTNER_CS_REQUEST_TRAN, Player, {Id}) ->
    case  partner_api:train(Player, Id) of
        {?ok, Player2} ->
            {?ok, Player2};
        _ ->
            ok
    end;

%% 设置跟随武将
handler(?MSG_ID_PARTNER_CS_SET_FOLLOW, Player, {PartnerId}) ->
	partner_mod:set_follow(Player, PartnerId);

%% 武将属性
handler(?MSG_ID_PARTNER_CS_ATTR, Player, {UserId,PartnerId}) ->
	partner_mod:partner_attr(Player, UserId, PartnerId),
	{?ok, Player};

handler(_MsgId, _Player, _Datas) -> ?undefined.



%%
%% Local Functions
%%

