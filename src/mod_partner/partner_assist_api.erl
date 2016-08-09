%% Author: Administrator
%% Created: 2012-12-28
%% Description: TODO: Add description to partner_assist_api
-module(partner_assist_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.partner.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
%%
%% Exported Functions
%%
-export([set_assist/4, 
		 remove_assist/3,
		 get_skipper/2,
		 get_partner/2,
		 get_partner_camp_list/2,
		 refresh_assist_change/3,
		 msg_set_assist/3]).

%% -compile(export_all).
%%
%% API Functions
%%
%% 副将界面设置
set_assist(Player, IdFrom, IdTo, AssIdxTo) ->
	if  IdFrom =:= 0 orelse IdFrom =:= IdTo -> %% 主角
			Packet = message_api:msg_notice(?TIP_PARTNER_CHANGE_TYPE_1),	
           	misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player};
		?true ->
			case partner_api:get_partner_by_id(Player, IdFrom) of
				{?ok, FromPartner} ->
					Station			   = FromPartner#partner.is_skipper,
					case IdTo =:= 0 of
						?true -> %% 主角
							player_set_assist(Player, FromPartner, AssIdxTo, Station);
						?false ->
							case partner_api:get_partner_by_id(Player, IdTo) of
								{?ok, ToPartner} ->
									partner_set_assist(Player, FromPartner, ToPartner, AssIdxTo, Station);
								{?error, Error1} ->
									Packet = message_api:msg_notice(Error1),	
		           					misc_packet:send(Player#player.user_id, Packet),
									{?ok, Player}
							end
					end;
				{?error, Error2} ->
					Packet = message_api:msg_notice(Error2),	
           			misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player}
			end
	end.

player_set_assist(Player, FromPartner, AssIdxTo, Station) ->
	case check_assidx_is_open((Player#player.info)#info.lv, AssIdxTo) of
		?true ->
			set_assist_for_player(Player, FromPartner, AssIdxTo, Station);
		?false ->
			{?ok, Player}
	end.

partner_set_assist(Player, FromPartner, ToPartner, AssIdxTo, Station) ->
	case check_assidx_is_open((Player#player.info)#info.lv, AssIdxTo) of
		?true ->
			set_assist_for_partner(Player, FromPartner, ToPartner, AssIdxTo, Station);
		?false ->
			{?ok, Player}
	end.

set_assist_for_player(Player, _FromPartner, _AssIdxTo, ?CONST_PARTNER_STATION_SKIPPER) ->
	Packet = message_api:msg_notice(?TIP_PARTNER_CHANGE_TYPE_1),	
    misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};
set_assist_for_player(Player, FromPartner, AssIdxTo, ?CONST_PARTNER_STATION_ASSISTER) ->
	?MSG_DEBUG("set_assist_for_player_2:~p",[2]),
	IdFrom = FromPartner#partner.partner_id,
	case get_skipper(Player, IdFrom) of
		{?ok, 0, AssIdxFrom} ->	 %% 主角的副将
			Info				= Player#player.info,
			Assist				= Info#info.assist_partner,
			ToAssId				= element(AssIdxTo, Assist),
			Assist2			 	= setelement(AssIdxFrom, Assist, ToAssId),
			Assist3			 	= setelement(AssIdxTo, Assist2, IdFrom),
			NewInfo				= Info#info{assist_partner = Assist3},
			List				= [0],
			Player2				= Player#player{info = NewInfo},
			Packet			 	= msg_set_assist(Player2, List, []),
			misc_packet:send(Player2#player.user_id, Packet),
			team_api:update_team_player(Player2),
			{?ok, Player2};
		{?ok, IdFromSkip, AssIdxFrom} -> %% 武将的副将
			case partner_api:get_partner_by_id(Player, IdFromSkip) of
				{?ok, FromSkip} ->
					FromSkipAssist	 = FromSkip#partner.assist,
					Info			 = Player#player.info,
					ToAss			 = Info#info.assist_partner,
					ToAssId			 = element(AssIdxTo, ToAss),
					FromSkipAssist2	 = setelement(AssIdxFrom, FromSkipAssist, ToAssId),
					NewFromSkip		 = FromSkip#partner{assist = FromSkipAssist2},
					ToAss2			 = setelement(AssIdxTo, ToAss, IdFrom),
					NewInfo	    	 = Info#info{assist_partner = ToAss2},
					Player2 		 = partner_mod:update_partner(Player, NewFromSkip),
					Player3 		 = Player2#player{info = NewInfo},
					List			 = [NewFromSkip, 0],
					Packet			 = msg_set_assist(Player3, List, []),
					misc_packet:send(Player#player.user_id, Packet),
					Player4 		 = refresh_assist_change(Player3, List, [NewFromSkip]),
					{?ok, Player4};
				{?error, Error} ->
					Packet = message_api:msg_notice(Error),	
           			misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end;	
set_assist_for_player(Player, FromPartner, AssIdxTo, ?CONST_PARTNER_STATION_NORMAL) ->
	?MSG_DEBUG("set_assist_for_player_0:~p",[0]),
	try
		IdFrom 			 		 = FromPartner#partner.partner_id,
		FromPartnerAssist		 = FromPartner#partner.assist,
		NewFromPartner   		 = FromPartner#partner{assist = {0,0,0,0}, is_skipper = ?CONST_PARTNER_STATION_ASSISTER},
		Info			 		 = Player#player.info,
		ToSkipAss			 	 = Info#info.assist_partner,
		IdAssTo			 		 = element(AssIdxTo, ToSkipAss),
		{Player1, StationList1, ChangeList1}			=
			case FromPartnerAssist =:= {0,0,0,0} of
				?true ->
					TStationList			= [NewFromPartner],
					{Player, TStationList, []};
				?false ->
					{?ok, AssPlayer, TempList} = partner_api:set_assist_to_normal(Player, IdFrom),
					TStationList			= [NewFromPartner|TempList],
					TChangeList				= [NewFromPartner],
					{AssPlayer, TStationList, TChangeList}
			end,
		Player2 		 		 = partner_mod:update_partner(Player1, NewFromPartner),
		ToSkipAss2		 		 = setelement(AssIdxTo, ToSkipAss, IdFrom),
		NewInfo			 		 = Info#info{assist_partner = ToSkipAss2},
		Player3 		 		 = Player2#player{info = NewInfo},
		{Player4, StationList2}			= 
			case IdAssTo =:= 0 of
				?true -> %% 目标副将位为空
					{?ok, FinalPlayer}  = welfare_api:add_pullulation(Player3, ?CONST_WELFARE_ASSISTER, 0, 1),
					{FinalPlayer, StationList1};
				?false -> %% 目标副将位非空
					{?ok, ToAss}		= get_partner(Player, IdAssTo),
					NewToAss			= ToAss#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
					TempPlayer2			= partner_mod:update_partner(Player3, NewToAss),
					TStationList2		= StationList1 ++ [NewToAss],
					{TempPlayer2, TStationList2}
			end,
		ChangeList2			= ChangeList1 ++ [0],
		Packet1			 	= partner_api:msg_set_partner_station(StationList2, <<>>),
		Packet2			 	= msg_set_assist(Player4, ChangeList2, []),
		Packet				= <<Packet1/binary, Packet2/binary>>,
		misc_packet:send(Player#player.user_id, Packet),
		Player5 			= refresh_assist_change(Player4, ChangeList2, ChangeList1),
		{?ok, Player6}		= camp_api:remove_partner_all_camp(Player5, IdFrom),
		{?ok, Player6}
	catch
        throw:{?error, _ErrorCode} ->
            {?ok, Player};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?ok, Player} % 入参有误
    end.

set_assist_for_partner(Player, _FromPartner, _ToPartner, _AssIdxTo, ?CONST_PARTNER_STATION_SKIPPER) ->
	Packet = message_api:msg_notice(?TIP_PARTNER_CHANGE_TYPE_1),	
    misc_packet:send(Player#player.user_id, Packet),
	{?ok, Player};
set_assist_for_partner(Player, FromPartner, ToPartner, AssIdxTo, ?CONST_PARTNER_STATION_ASSISTER) ->
	?MSG_DEBUG("set_assist_for_pa_2:~p",[2]),
	IdFrom = FromPartner#partner.partner_id,
	case get_skipper(Player, IdFrom) of
		{?ok, 0, AssIdxFrom} ->	 %% 主角的副将
			Info				= Player#player.info,
			ToAss			 	= ToPartner#partner.assist,
			ToAssId			 	= element(AssIdxTo, ToAss),
			ToAss2			 	= setelement(AssIdxTo, ToAss, IdFrom),
			FromSkipAssist		= Info#info.assist_partner,
			FromSkipAssist2	 	= setelement(AssIdxFrom, FromSkipAssist, ToAssId),
			NewInfo				= Info#info{assist_partner = FromSkipAssist2},
			Player2				= Player#player{info = NewInfo},
			NewToPartner	 	= ToPartner#partner{assist = ToAss2}, 
			Player3 		 	= partner_mod:update_partner(Player2, NewToPartner),
			List			 	= [0, NewToPartner],
			Packet			 	= msg_set_assist(Player3, List, []),
			misc_packet:send(Player#player.user_id, Packet),
			Player4 		 	= refresh_assist_change(Player3, List, [NewToPartner]),
			{?ok, Player4};
		{?ok, IdFromSkip, AssIdxFrom} -> %% 武将的副将
			ToAss			 = ToPartner#partner.assist,
			ToAssId			 = element(AssIdxTo, ToAss),
			ToAss2			 = setelement(AssIdxTo, ToAss, IdFrom),
			NewToPartner	 = ToPartner#partner{assist = ToAss2},
			Player2 		 = partner_mod:update_partner(Player, NewToPartner),
			case partner_api:get_partner_by_id(Player2, IdFromSkip) of
				{?ok, FromSkip} ->
					FromSkipAssist	 = FromSkip#partner.assist,
					FromSkipAssist2	 = setelement(AssIdxFrom, FromSkipAssist, ToAssId),
					NewFromSkip		 = FromSkip#partner{assist = FromSkipAssist2},
					Player3 		 = partner_mod:update_partner(Player2, NewFromSkip),
					List			 = [NewFromSkip, NewToPartner],
					Packet			 = msg_set_assist(Player3, List, []),
					misc_packet:send(Player#player.user_id, Packet),
					Player4 		 = refresh_assist_change(Player3, List, [NewFromSkip, NewToPartner]),
					{?ok, Player4};
				{?error, Error} ->
					Packet = message_api:msg_notice(Error),	
           			misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player}
			end;
		_ ->
			{?ok, Player}
	end;	
set_assist_for_partner(Player, FromPartner, ToPartner, AssIdxTo, ?CONST_PARTNER_STATION_NORMAL) ->
	?MSG_DEBUG("set_assist_for_pa_0:~p",[0]),
	try
		IdFrom 			 		 = FromPartner#partner.partner_id,
		FromPartnerAssist		 = FromPartner#partner.assist,
		NewFromPartner   		 = FromPartner#partner{assist = {0,0,0,0}, is_skipper = ?CONST_PARTNER_STATION_ASSISTER},
		ToSkipAss			 	 = ToPartner#partner.assist,
		IdAssTo			 		 = element(AssIdxTo, ToSkipAss),
		{Player1, StationList1, ChangeList1}			=
			case FromPartnerAssist =:= {0,0,0,0} of
				?true ->
					TStationList			= [NewFromPartner],
					{Player, TStationList, []};
				?false ->
					{?ok, AssPlayer, TempList} = partner_api:set_assist_to_normal(Player, IdFrom),
					TStationList			= [NewFromPartner|TempList],
					TChangeList				= [NewFromPartner],
					{AssPlayer, TStationList, TChangeList}
			end,
		Player2 		 		 = partner_mod:update_partner(Player1, NewFromPartner),
		ToSkipAss2		 		 = setelement(AssIdxTo, ToSkipAss, IdFrom),
		NewToSkip			 	 = ToPartner#partner{assist = ToSkipAss2},
		Player3 		 		 = partner_mod:update_partner(Player2, NewToSkip),
		{Player4, StationList2}			= 
			case IdAssTo =:= 0 of
				?true -> %% 目标副将位为空
					{Player3, StationList1};
				?false -> %% 目标副将位非空
					{?ok, ToAss}		= get_partner(Player, IdAssTo),
					NewToAss			= ToAss#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
					TempPlayer2			= partner_mod:update_partner(Player3, NewToAss),
					TStationList2		= StationList1 ++ [NewToAss],
					{TempPlayer2, TStationList2}
			end,
		ChangeList2			= ChangeList1 ++ [NewToSkip],
		Packet1			 	= partner_api:msg_set_partner_station(StationList2, <<>>),
		Packet2			 	= msg_set_assist(Player4, ChangeList2, []),
		Packet				= <<Packet1/binary, Packet2/binary>>,
		misc_packet:send(Player#player.user_id, Packet),
		Player5 			= refresh_assist_change(Player4, ChangeList2, ChangeList2),
		{?ok, Player6}		= camp_api:remove_partner_all_camp(Player5, IdFrom),
		{?ok, Player6}
	catch
        throw:{?error, _ErrorCode} ->
            {?ok, Player};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?ok, Player} % 入参有误
    end.


%% 副将界面移除武将
remove_assist(Player, 0, AssIdxFrom) ->
	Info			 = Player#player.info,
	FromSkipAssist 	 = Info#info.assist_partner,
	FromSkipAssist2	 = setelement(AssIdxFrom, FromSkipAssist, 0),
	FromAssId		 = element(AssIdxFrom, FromSkipAssist),
	case partner_api:get_partner_by_id(Player, FromAssId) of
		{?ok, FromAss} ->
			NewFromAss		 = FromAss#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
			NewInfo			 = Info#info{assist_partner = FromSkipAssist2},
			Player2			 = Player#player{info = NewInfo},
			Player3 		 = partner_mod:update_partner(Player2, NewFromAss),
			List			 = [0],
			Packet1			 = partner_api:msg_set_partner_station([NewFromAss], <<>>),
			Packet2			 = msg_set_assist(Player3, List, []),
			Packet			 = <<Packet1/binary, Packet2/binary>>,
			misc_packet:send(Player#player.user_id, Packet),
			Player4 		 = refresh_assist_change(Player3, List, []),
			team_api:update_team_player(Player4),
			{?ok, Player4};
		{?error, Error} ->
			Packet = message_api:msg_notice(Error),	
   			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player}
	end;
remove_assist(Player, IdFrom, AssIdxFrom) ->
	case partner_api:get_partner_by_id(Player, IdFrom) of
		{?ok, FromSkip} ->
			FromSkipAssist	 = FromSkip#partner.assist,
			FromSkipAssist2	 = setelement(AssIdxFrom, FromSkipAssist, 0),
			NewFromSkip		 = FromSkip#partner{assist = FromSkipAssist2},
			FromAssId		 = element(AssIdxFrom, FromSkipAssist),
			case partner_api:get_partner_by_id(Player, FromAssId) of
				{?ok, FromAss} ->
					NewFromAss		 = FromAss#partner{is_skipper = ?CONST_PARTNER_STATION_NORMAL},
					Player2 		 = partner_mod:update_partner(Player, NewFromSkip),
					Player3 		 = partner_mod:update_partner(Player2, NewFromAss),
					List			 = [NewFromSkip],
					Packet1			 = partner_api:msg_set_partner_station([NewFromAss], <<>>),
					Packet2			 = msg_set_assist(Player3, List, []),
					Packet			 = <<Packet1/binary, Packet2/binary>>,
					misc_packet:send(Player#player.user_id, Packet),
					Player4 		 = refresh_assist_change(Player3, List, [FromSkip]),
					{?ok, Player4};
				{?error, Error} ->
					Packet = message_api:msg_notice(Error),	
           			misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player}
			end;
		{?error, Error} ->
			Packet = message_api:msg_notice(Error),	
   			misc_packet:send(Player#player.user_id, Packet),
			{?ok, Player}
	end.

%% 检查副将位是否开启
check_assidx_is_open(Lv, 1) ->
	if Lv < ?CONST_PARTNER_ASSIST_LV_1 ->
		   ?false;
	   ?true ->
		   ?true
	end;
check_assidx_is_open(Lv, 2) ->
	if Lv < ?CONST_PARTNER_ASSIST_LV_2 ->
		   ?false;
	   ?true ->
		   ?true
	end;
check_assidx_is_open(Lv, 3) ->
	if Lv < ?CONST_PARTNER_ASSIST_LV_3 ->
		   ?false;
	   ?true ->
		   ?true
	end;
check_assidx_is_open(Lv, 4) ->
	if Lv < ?CONST_PARTNER_ASSIST_LV_4 ->
		   ?false;
	   ?true ->
		   ?true
	end;
check_assidx_is_open(_Lv, _Idx) ->
	?false.
%% 根据副将id获取其主将id
get_skipper(Player, AssId) ->
	PartnerList = partner_api:get_partner_by_team(Player, ?CONST_PARTNER_TEAM_IN),
	get_skipper_ext(Player, AssId, [0|PartnerList]).
get_skipper_ext(_Player, _AssId, []) -> {?error, ?TIP_COMMON_BAD_ARG};
get_skipper_ext(Player, AssId, [0|PartnerList]) ->
	Info 	= Player#player.info,
	Assist  = Info#info.assist_partner,
	case get_assist_idx(Assist, AssId, 1) of
		{?error, _ErrorCode} ->
			get_skipper_ext(Player, AssId, PartnerList);
		{?ok, Idx} ->
			{?ok, 0, Idx}
	end;
get_skipper_ext(Player, AssId, [Partner|PartnerList]) when is_record(Partner, partner) ->
	Assist	= Partner#partner.assist,
	case get_assist_idx(Assist, AssId, 1) of
		{?error, _ErrorCode} ->
			get_skipper_ext(Player, AssId, PartnerList);
		{?ok, Idx} ->
			{?ok, Partner#partner.partner_id, Idx}
	end;
get_skipper_ext(Player, AssId, [_Partner|PartnerList]) ->
	get_skipper_ext(Player, AssId, PartnerList).

get_assist_idx(Assist, AssId, Idx) when Idx =< 4 ->
	Id	= element(Idx, Assist),
%% 	?MSG_DEBUG("get_assist_idx:~p",[{Assist,Id}]),
	case Id =:= AssId of
		?true ->
			{?ok, Idx};
		?false ->
			get_assist_idx(Assist, AssId, Idx + 1)
	end;
get_assist_idx(_AssList, _AssId, _Idx) ->
	{?error, ?TIP_COMMON_BAD_ARG}.

%% 根据阵法位置检查是否有单位
%% check_camp_idx(Position, Idx) ->
%% 	case element(Idx, Position) of
%% 		PosInfo when is_record(PosInfo, camp_pos) ->
%% 			?true;
%% 		_ ->
%% 			?false
%% 	end.

%% 获取武将
get_partner(Player, Id) ->
	case partner_api:get_partner_by_id(Player, Id) of
		{?ok, Partner} ->
			{?ok, Partner};
		{?error, ErrorCode} ->
			throw({?error, ErrorCode})
	end.

%% 获取有武将id的阵法列表
get_partner_camp_list(Player, Id) ->
	Camp = (Player#player.camp)#camp_data.camp,
	get_partner_camp_list(Camp, Id, []).

get_partner_camp_list([], _Id, Acc) -> lists:sort(Acc);
get_partner_camp_list([#camp{camp_id = CampId, position = Position} = _Camp|CampList], Id, Acc) ->
	NewAcc =
		case camp_api:get_pos_by_id(Position, Id, 1) of
			{?ok, _Idx} ->
				[CampId|Acc];
			_ ->
				Acc
		end,
	get_partner_camp_list(CampList, Id, NewAcc);
get_partner_camp_list([_Camp|CampList], Id, Acc) -> 
	get_partner_camp_list(CampList, Id, Acc).

%% 刷新副将改变后的组合加成 副将加成
refresh_assist_change(Player, AllList, PartnerList) ->
%% 	?MSG_DEBUG("refresh_assist_change:~p",[{AllList,PartnerList}]),
	AssemblePacket = partner_api:msg_partner_assemble_list(Player, 1, AllList),
	misc_packet:send(Player#player.user_id, AssemblePacket),
	NewPlayer2 = player_attr_api:refresh_attr_assemble(Player),	%% 刷新主角的组合加成
	AttrAssemble     = partner_api:refresh_attr_assemble(NewPlayer2),
	NewPlayer3 = partner_api:refresh_attr_assemble_partner(NewPlayer2, AttrAssemble),	%% 刷新变化武将的组合加成
	NewPlayer4 = player_attr_api:refresh_attr_assist(NewPlayer3),	%% 刷新主角的副将加成
	NewPlayer5 = partner_api:refresh_attr_assist_partner(NewPlayer4, PartnerList),	%% 刷新变化武将的副将加成
	NewPlayer5.

%% 打包副将界面返回数据
msg_set_assist(_Player, [], AccData) ->
	misc_packet:pack(?MSG_ID_PARTNER_SC_SET_ASSIST, ?MSG_FORMAT_PARTNER_SC_SET_ASSIST, [AccData]);
msg_set_assist(Player, [#partner{partner_id = PartnerId} = Skipper|SkipperList], AccData) ->
	AssistList = misc:to_list(Skipper#partner.assist),
	Fun	= fun(AssId) ->
				  {
				   AssId
				  }
		  end,
	AssistData	 = lists:map(Fun, AssistList),
	NewAccData	 = [{PartnerId,AssistData}|AccData],
	msg_set_assist(Player, SkipperList, NewAccData);
msg_set_assist(Player, [0|SkipperList], AccData) ->
	Assist     = (Player#player.info)#info.assist_partner,
	AssistList = misc:to_list(Assist),
	Fun	= fun(AssId) ->
				  {
				   AssId
				  }
		  end,
	AssistData	 = lists:map(Fun, AssistList),
	NewAccData	 = [{0,AssistData}|AccData],
	msg_set_assist(Player, SkipperList, NewAccData);
msg_set_assist(Player, [_Skipper|SkipperList], AccData) ->
	msg_set_assist(Player, SkipperList, AccData).

	
%%
%% Local Functions
%%

