%% 阵法
-module(camp_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").

%%
%% Exported Functions
%%
-export([create/0, camp_info/1, upgrade/2, exchange_pos/4, set_pos/6, start_camp/2, remove/3, get_pos/2]).
-export([get_empty/2, get_empty_desc/2, get_max_lv/2]).

%% 创建阵型数据
create() ->
	#camp_data{
			   camp			= [],      		% 阵型 [#camp{}]
			   camp_use		= 0				%  当前使用的阵型
			  }.

%% 阵型信息
camp_info(Player) ->
	case Player#player.camp of
		CampData when is_record(CampData, camp_data) ->
			PacketInfo	= camp_api:msg_camp_sc_info(CampData#camp_data.camp, <<>>),
			PacketUse	= camp_api:msg_camp_sc_use(CampData#camp_data.camp_use),
			<<PacketInfo/binary, PacketUse/binary>>;
		_ -> <<>>
	end.

%% 阵型升级
%% {?error, ErrorCode}/{?ok, Player2}
upgrade(Player, CampId) ->
	CampData	= Player#player.camp,
    {Camp, Lv}  = 
    	case lists:keyfind(CampId, #camp.camp_id, CampData#camp_data.camp) of
    		?false -> % 学习阵型
    			CampT	= ?null,
    			LvT		= 1,
                {CampT, LvT};
    		CampT -> % 升级阵型
    			LvT		= CampT#camp.lv + 1,
                {CampT, LvT}
    	end,
	case data_camp:get_camp({CampId, Lv}) of
		?null -> 
			Packet = message_api:msg_notice(?TIP_CAMP_NOT_EXIST),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_CAMP_NOT_EXIST};
		RecCamp ->
			case check(Player, RecCamp) of
				{?ok, Type} ->
					case upgrade(Player, RecCamp, Camp, CampData, Type) of
						{?ok, Player2, Packet} ->
							{?ok, Player3} = achievement_api:add_achievement(Player2, ?CONST_ACHIEVEMENT_CAMP_LEVELUP, 0, 1),
                            {?ok, Player4} = pullulation_interface(Player3, Lv),
							admin_log_api:log_ability_camp(Player4, ?CONST_LOG_FUN_CAMP_UPGRADE, CampId, Lv, RecCamp#rec_camp.gold),
							misc_packet:send(Player4#player.net_pid, Packet),
							{?ok, Player4};
						{?error, ErrorCode} ->
                            ?MSG_ERROR("upgrade:ErrorCode=~p", [ErrorCode]),
                            Packet = message_api:msg_notice(ErrorCode),
                            misc_packet:send(Player#player.net_pid, Packet),
							{?error, ErrorCode}
					end;
				{?error, ErrorCode} ->
					case ErrorCode of
						?TIP_CAMP_EXP_NOT_ENOUGH ->
							Packet = message_api:msg_notice(?TIP_CAMP_EXP_NOT_ENOUGH),
							misc_packet:send(Player#player.net_pid, Packet),
							{?error, ?TIP_CAMP_EXP_NOT_ENOUGH};
						?TIP_CAMP_LV_NOT_OPEN ->
							Packet = message_api:msg_notice(?TIP_CAMP_LV_NOT_OPEN),
							misc_packet:send(Player#player.net_pid, Packet),
							{?error, ?TIP_CAMP_LV_NOT_OPEN};
						?TIP_CAMP_LV_NOT_ENOUGH ->
							Packet = message_api:msg_notice(?TIP_CAMP_LV_NOT_ENOUGH),
							misc_packet:send(Player#player.net_pid, Packet),
							{?error, ?TIP_CAMP_LV_NOT_ENOUGH};
						?TIP_CAMP_GOODS_NOT_ENOUGH ->
							Packet = message_api:msg_sc_window(?CONST_SYS_CASH),
                            misc_packet:send(Player#player.net_pid, Packet),
							{?error, ?TIP_CAMP_GOODS_NOT_ENOUGH};
						Other ->
                            Packet = message_api:msg_notice(Other),
                            misc_packet:send(Player#player.net_pid, Packet),
							{?error, Other}
					end
			end
	end.
upgrade(Player, RecCamp = #rec_camp{goods_id = 0}, Camp, CampData, _) ->
    UserId = Player#player.user_id,
    case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, RecCamp#rec_camp.gold, ?CONST_COST_CAMP_UPGRADE) of
        ?ok ->
            {Camp2, PacketInfo}       
                        = case Camp of
                              ?null ->
                                  C = #camp{camp_id     = RecCamp#rec_camp.camp_id,
                                            lv          = RecCamp#rec_camp.lv,
                                            position    = RecCamp#rec_camp.position},
                                  Pcamp = camp_api:msg_sc_new(RecCamp#rec_camp.camp_id),
                                  {C, Pcamp};
                              Camp ->
                                  % 以后可以在这里记忆阵型
                                  P = lp(Camp#camp.position, RecCamp#rec_camp.position, 1),
                                  C = Camp#camp{camp_id = RecCamp#rec_camp.camp_id,
                                            lv      = RecCamp#rec_camp.lv,
                                            position= P},
                                  Pcamp    = camp_api:msg_camp_sc_info([C], <<>>),
                                  {C, Pcamp}
                          end,
            CampList    = case lists:keyfind(Camp2#camp.camp_id, #camp.camp_id, CampData#camp_data.camp) of
                              ?false -> 
                                  Camp3 = insert_self(Player, Camp2),
                                  [Camp3|CampData#camp_data.camp];
                              Temp -> 
%%                                   Camp3 = insert_self(Player2, Camp2),
                                  [Camp2|lists:delete(Temp, CampData#camp_data.camp)]
                          end,
            CampData2   = CampData#camp_data{camp = CampList},
            Player3     = Player#player{camp = CampData2},
            {?ok, Player3, PacketInfo};
        {?error, ErrorCode} -> 
            {?error, ErrorCode}
    end;
upgrade(Player, RecCamp, Camp, CampData, 1) ->
    CampData	= Player#player.camp,
    case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, RecCamp#rec_camp.goods_id, 1) of
        {?ok, Bag, _GoodsList, PacketGoods} ->
            UserId = Player#player.user_id,
            admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_CAMP_UPGRADE, RecCamp#rec_camp.goods_id, 1, misc:seconds()),
            case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, RecCamp#rec_camp.gold, ?CONST_COST_CAMP_UPGRADE) of
                ?ok ->
                    {Camp2, PacketInfo}		
                        = case Camp of
                              ?null ->
                                  C = #camp{camp_id		= RecCamp#rec_camp.camp_id,
                                            lv			= RecCamp#rec_camp.lv,
                                            position    = RecCamp#rec_camp.position},
                                  Pcamp = camp_api:msg_sc_new(RecCamp#rec_camp.camp_id),
                                  {C, Pcamp};
                              Camp ->
                                  % 以后可以在这里记忆阵型
                                  P = lp(Camp#camp.position, RecCamp#rec_camp.position, 1),
                                  C = Camp#camp{camp_id	= RecCamp#rec_camp.camp_id,
                                                lv		= RecCamp#rec_camp.lv,
                                                position = P},
                                  Pcamp    = camp_api:msg_camp_sc_info([C], <<>>),
                                  {C, Pcamp}
                          end,
                    CampList	= case lists:keyfind(Camp2#camp.camp_id, #camp.camp_id, CampData#camp_data.camp) of
                                      ?false -> 
                                          Camp3 = insert_self(Player, Camp2),
                                          [Camp3|CampData#camp_data.camp];
                                      Temp -> 
                                          %%                                           Camp3 = insert_self(Player2, Camp2),
                                          [Camp2|lists:delete(Temp, CampData#camp_data.camp)]
                                  end,
                    CampData2	= CampData#camp_data{camp = CampList},
                    Player3		= Player#player{bag = Bag, camp = CampData2},
                    Packet		= <<PacketInfo/binary, PacketGoods/binary>>,
                    {?ok, Player3, Packet};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end;
        {?error, ErrorCode} -> 
            {?error, ErrorCode}
    end;
upgrade(Player, RecCamp, Camp, CampData, 2) ->
    CampData	= Player#player.camp,
    case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, ?CONST_CAMP_CAMP_BOOK_CASH, ?CONST_COST_CAMP_UPGRADE) of
        ?ok ->
            case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_GOLD_BIND, RecCamp#rec_camp.gold, ?CONST_COST_CAMP_UPGRADE) of
                ?ok ->
                    {Camp2, PacketInfo}     
                        = case Camp of
                              ?null ->
                                  C = #camp{camp_id     = RecCamp#rec_camp.camp_id,
                                            lv          = RecCamp#rec_camp.lv,
                                            position    = RecCamp#rec_camp.position},
                                  Pcamp = camp_api:msg_sc_new(RecCamp#rec_camp.camp_id),
                                  {C, Pcamp};
                              Camp ->
                                  % 以后可以在这里记忆阵型
                                  P = lp(Camp#camp.position, RecCamp#rec_camp.position, 1),
                                  C = Camp#camp{camp_id = RecCamp#rec_camp.camp_id,
                                                lv      = RecCamp#rec_camp.lv,
                                                position = P},
                                  Pcamp    = camp_api:msg_camp_sc_info([C], <<>>),
                                  {C, Pcamp}
                          end,
                    CampList    = case lists:keyfind(Camp2#camp.camp_id, #camp.camp_id, CampData#camp_data.camp) of
                                      ?false -> 
                                          Camp3 = insert_self(Player, Camp2),
                                          [Camp3|CampData#camp_data.camp];
                                      Temp -> 
                                          [Camp2|lists:delete(Temp, CampData#camp_data.camp)]
                                  end,
                    CampData2   = CampData#camp_data{camp = CampList},
                    Player3     = Player#player{camp = CampData2},
                    {?ok, Player3, PacketInfo};
                {?error, ErrorCode} -> {?error, ErrorCode}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

lp(P1, P2, Nth) when Nth =< 9 andalso 0 < Nth ->
    T = erlang:element(Nth, P1),
    NewP1 = 
        if
            ?CONST_SYS_FALSE =:= T ->
                T2 = erlang:element(Nth, P2),
                if
                    ?CONST_SYS_TRUE =:= T2 ->
                        erlang:setelement(Nth, P1, ?CONST_SYS_TRUE);
                    ?true ->
                        P1
                end;
            ?true ->
                P1
        end,
    lp(NewP1, P2, Nth + 1);
lp(P1, _P2, _Nth) ->
    P1.

%% 第一次插入玩家本人到阵法中
insert_self(Player, Camp) ->
    case get_empty(Camp#camp.position, 1) of
        {?ok, Idx} ->
            NewPosition = erlang:setelement(Idx, Camp#camp.position, #camp_pos{id = Player#player.user_id, type = 1, idx = Idx}),
            Camp#camp{position = NewPosition};
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(Player#player.net_pid, Packet),
            Camp
    end.

%% 交换阵型站位
exchange_pos(Player, CampId, IdxFrom, IdxTo) ->
	CampData	= Player#player.camp,
	case lists:keyfind(CampId, #camp.camp_id, CampData#camp_data.camp) of
		Camp when is_record(Camp, camp) ->
			Position	= Camp#camp.position,
			CampPosFrom	= element(IdxFrom, Position),
			CampPosTo	= element(IdxTo, Position),
			case exchange_pos(Player, Camp, IdxFrom, CampPosFrom, IdxTo, CampPosTo) of
				{?ok, Player2, Packet} ->
					misc_packet:send(Player2#player.net_pid, Packet),
					{?ok, Player2};
				{?error, ?TIP_CAMP_SOURCE_NULL} ->
					Packet = message_api:msg_notice(?TIP_CAMP_SOURCE_NULL),
					misc_packet:send(Player#player.net_pid, Packet),
					{?error, ?TIP_CAMP_SOURCE_NULL};
				{?error, ?TIP_CAMP_DEST_ILLEGAL} ->
					Packet = message_api:msg_notice(?TIP_CAMP_DEST_ILLEGAL),
					misc_packet:send(Player#player.net_pid, Packet),
					{?error, ?TIP_CAMP_SOURCE_NULL};
				{?error, ErrorCode} -> 
                    ?MSG_ERROR("ex:ErrorCode=~p", [ErrorCode]),
					{?error, ErrorCode}
			end;
		_ -> 
            ?MSG_ERROR("ex:ErrorCode=~p", [?TIP_COMMON_BAD_ARG]),
            {?error, ?TIP_COMMON_BAD_ARG}
	end.
exchange_pos(_Player, _Camp, _IdxFrom, CampPosFrom, _IdxTo, _CampPosTo)
  when CampPosFrom =:= ?CONST_SYS_TRUE orelse CampPosFrom =:= ?CONST_SYS_FALSE ->% error:源位置为空
	{?error, ?TIP_CAMP_SOURCE_NULL};
exchange_pos(_Player, _Camp, _IdxFrom, _CampPosFrom, _IdxTo, ?CONST_SYS_FALSE) ->% error:目标位置为不可站立
	{?error, ?TIP_CAMP_DEST_ILLEGAL};
exchange_pos(Player, Camp, IdxFrom, CampPosFrom, IdxTo, ?CONST_SYS_TRUE) ->% 目标位置为空
	CampData		= Player#player.camp,
	Position		= Camp#camp.position,
	CampPosFromNew	= ?CONST_SYS_TRUE,
	CampPosToNew	= CampPosFrom#camp_pos{idx = IdxTo},
	Position2		= setelement(IdxFrom, Position, CampPosFromNew),
	Position3		= setelement(IdxTo, Position2, CampPosToNew),
	
	Camp2			= Camp#camp{position = Position3},
	CampList		= [Camp2|lists:delete(Camp, CampData#camp_data.camp)],
	CampData2		= CampData#camp_data{camp = CampList},
	Player2			= Player#player{camp = CampData2},
	
	PacketUpdate	= camp_api:msg_camp_sc_pos_update(Camp#camp.camp_id,
													  CampPosToNew#camp_pos.idx,
													  CampPosToNew#camp_pos.type,
													  CampPosToNew#camp_pos.id,
                                                      ?CONST_SYS_FALSE),
	PacketRemove	= camp_api:msg_camp_sc_pos_remove(Camp#camp.camp_id, IdxFrom, ?CONST_SYS_FALSE),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	Packet			= <<PacketUpdate/binary, PacketRemove/binary>>,
	{?ok, Player2, Packet};
exchange_pos(Player, Camp, IdxFrom, CampPosFrom, IdxTo, CampPosTo)  ->% 直接交换
	CampData		= Player#player.camp,
	Position		= Camp#camp.position,
	CampPosFromNew	= CampPosTo#camp_pos{idx = IdxFrom},
	CampPosToNew	= CampPosFrom#camp_pos{idx = IdxTo},
	
	Position2		= setelement(IdxFrom, Position, CampPosFromNew),
	Position3		= setelement(IdxTo, Position2, CampPosToNew),
	Camp2			= Camp#camp{position = Position3},
	CampList		= [Camp2|lists:delete(Camp, CampData#camp_data.camp)],
	CampData2		= CampData#camp_data{camp = CampList},
	Player2			= Player#player{camp = CampData2},
	
	PacketUpdateFrom= camp_api:msg_camp_sc_pos_update(Camp#camp.camp_id,
													  CampPosFromNew#camp_pos.idx,
													  CampPosFromNew#camp_pos.type,
													  CampPosFromNew#camp_pos.id,
                                                      ?CONST_SYS_FALSE),
	PacketUpdateTo	= camp_api:msg_camp_sc_pos_update(Camp#camp.camp_id,
													  CampPosToNew#camp_pos.idx,
													  CampPosToNew#camp_pos.type,
													  CampPosToNew#camp_pos.id,
                                                      ?CONST_SYS_FALSE),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	Packet			= <<PacketUpdateFrom/binary, PacketUpdateTo/binary>>,
	{?ok, Player2, Packet}.

%% 设置阵型站位(UseType:1布阵界面上阵2副将界面上阵)
set_pos(Player = #player{user_id = UserId, camp =  CampData}, CampId, CampIdx, Type, Id, UseType) ->
	try
		case lists:keyfind(CampId, #camp.camp_id, CampData#camp_data.camp) of
			Camp when is_record(Camp, camp) ->
				Position    = Camp#camp.position,
				case element(CampIdx, Position) of
					?CONST_SYS_FALSE -> 
						{?error, ?TIP_CAMP_NOT_OPENED_POSITION};
					?CONST_SYS_TRUE ->
						Id2         = case Id of
										  0 -> 
											  throw({?error, ?TIP_CAMP_ALREADY_IN_CAMP});
										  UserId -> 
											  throw({?error, ?TIP_CAMP_ALREADY_IN_CAMP});
										  _ ->
											  ?ok = check_partner(Player, Id, Position, UseType),
											  Id
									  end,
						CampPosNew  = #camp_pos{idx = CampIdx, type = Type, id = Id2},
						Position2   = setelement(CampIdx, Position, CampPosNew), % 更新后的位置信息
						Camp2       = Camp#camp{position = Position2},
						CampList    = [Camp2|lists:delete(Camp, CampData#camp_data.camp)],
						CampData2   = CampData#camp_data{camp = CampList},
						Player2     = Player#player{camp = CampData2},
						PacketUpdate= camp_api:msg_camp_sc_pos_update(Camp2#camp.camp_id,
																	  CampPosNew#camp_pos.idx,
																	  CampPosNew#camp_pos.type,
																	  CampPosNew#camp_pos.id,
																	  ?CONST_SYS_TRUE),
						misc_packet:send(Player2#player.net_pid, PacketUpdate),
						{?ok, Player3} = update_partner(Player2, Position2, CampId, Id2, 0),
						{?ok, Player3};
					CampPosOld when CampPosOld#camp_pos.type =/= ?CONST_SYS_PLAYER ->
						case camp_api:get_pos_by_id(Position, Id, 1) of
							{?ok, IdxFrom} ->	%% 已经在阵法中则交换
								case camp_api:exchange_pos(Player, CampId, IdxFrom, CampIdx) of
									{?ok, Player2} ->
										{?ok, Player2};
									{?error, _ErrorCode} ->
										{?ok, Player}
								end;
							_ ->
								Id2         = case Id of
												  0 -> Player#player.user_id;
												  _ ->
													  ?ok = check_partner(Player, Id, Position, UseType),
													  Id
											  end,
								CampPosNew  = #camp_pos{idx = CampIdx, type = Type, id = Id2},
								Position2   = setelement(CampIdx, Position, CampPosNew),
								Camp2       = Camp#camp{position = Position2},
								CampList    = [Camp2|lists:delete(Camp, CampData#camp_data.camp)],
								CampData2   = CampData#camp_data{camp = CampList},
								Player2     = Player#player{camp = CampData2},
								PacketUpdate= camp_api:msg_camp_sc_pos_update(Camp2#camp.camp_id,
																			  CampPosNew#camp_pos.idx,
																			  CampPosNew#camp_pos.type,
																			  CampPosNew#camp_pos.id,
																			  ?CONST_SYS_TRUE),
								misc_packet:send(Player2#player.net_pid, PacketUpdate),
								{?ok, Player3} = update_partner(Player2, Position2, CampId, Id2, CampPosOld#camp_pos.id),
								{?ok, Player3}
						end;
					CampPosOld when CampPosOld#camp_pos.type =:= ?CONST_SYS_PLAYER ->
						case camp_api:get_pos_by_id(Position, Id, 1) of
							{?ok, IdxFrom} ->	%% 已经在阵法中则交换
								case camp_api:exchange_pos(Player, CampId, IdxFrom, CampIdx) of
									{?ok, Player2} ->
										{?ok, Player2};
									{?error, _ErrorCode} ->
										{?ok, Player}
								end;
							_ ->
								case Id =:= ?CONST_PARTNER_THE_FIRST orelse Id =:= ?CONST_PARTNER_THE_SECOND of
									?true ->
										{?ok, Player};
									?false ->
										throw({?error, ?TIP_CAMP_SELF})
								end
						end;
					_Other ->
						throw({?error, ?TIP_CAMP_SELF})
				%% 						{?ok, Player}
				end;
			_ -> 
				throw({?error, ?TIP_CAMP_NOT_EXIST})
		end
	catch
        thorw:{?error, ?TIP_PARTNER_NOT_EXIST} ->
            {?error, ?TIP_PARTNER_NOT_EXIST};
        throw:{?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),	
            misc_packet:send(Player#player.user_id, Packet),
            {?error, ErrorCode};
        Type:Why ->
            ?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", 
                       [Type, Why, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_BAD_ARG} % 入参有误
    end.


%% 启用阵法时更新武将
update_partner(Player = #player{camp = #camp_data{camp_use = CampUse}}, Position, CampUse) -> % 在用阵法
    PartnerList = get_partner_id_list(Position, Player#player.user_id, 1, []),
    {?ok, Player2} = partner_api:msg_partner_reset_skipper(Player, PartnerList),
%% 	AssemblePacket = partner_api:msg_partner_assemble_list(Player2, 1, PartnerList),
%% 	misc_packet:send(Player2#player.user_id, AssemblePacket),
%% 	Player3 = partner_api:refresh_attr_assemble_partner(Player2, PartnerList), %% 武将上阵下阵不影响整体组合
	PowerTotal      = partner_api:caculate_camp_power(Player2),
    {?ok, Player3} = task_api:update_power(Player2, PowerTotal),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	cross_arena_api:update_partner(Player3, PowerTotal),
    {?ok, Player3};
update_partner(Player, _CampPosition, _CampId) ->
    {?ok, Player}.

%% 武将上下阵更新武将
update_partner(Player = #player{camp = #camp_data{camp_use = CampUse}}, _Position, CampUse, AddId, RemoveId) -> % 在用阵法
	{?ok, Player2} = partner_api:msg_partner_set_skipper(Player, AddId, RemoveId),
%% 	AssemblePacket = partner_api:msg_partner_assemble_list(Player2, 1),
%% 	misc_packet:send(Player2#player.user_id, AssemblePacket),
%% 	Player3 = partner_api:refresh_attr_assemble_partner(Player2, RemoveId), %% 武将上阵下阵不影响整体组合
	PowerTotal      = partner_api:caculate_camp_power(Player2),
    {?ok, Player3} = task_api:update_power(Player2, PowerTotal),
    camp_pvp_mod:update_battle_data(Player#player.user_id),
	cross_arena_api:update_partner(Player3, PowerTotal),
    {?ok, Player3};
update_partner(Player, _CampPosition, _CampId, _, _) ->
    {?ok, Player}.

%% 检查上阵武将 布阵界面副将不允许上阵 副将界面允许
check_partner(Player, PartnerId, Position, UseType) ->
	SkipperList = get_partner_id_list(Position, Player#player.user_id, 1, []),
    case partner_api:get_partner_by_id(Player, PartnerId) of
        {?ok, #partner{is_skipper = 2}} ->
			case UseType of
				?CONST_CAMP_SET_POS_TYPE_1 ->
            		throw({?error, ?TIP_CAMP_NOT_FOR_ASSIST});
				?CONST_CAMP_SET_POS_TYPE_2 ->
					?ok
			end;
		{?ok, #partner{is_skipper = _Skipper}} ->
			case lists:member(PartnerId, SkipperList) of
				?true ->
					throw({?error, ?TIP_CAMP_ALREADY_IN_CAMP});
				?false ->
					?ok
			end;
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.


%% 阵型站位移除
remove(Player, CampId, CampIdx) ->
    CampData = Player#player.camp,
    CampList = CampData#camp_data.camp,
    case lists:keytake(CampId, #camp.camp_id, CampList) of
        {value, Camp, CampList2} when is_record(Camp, camp) ->
            CampPosition = Camp#camp.position,
            case erlang:element(CampIdx, CampPosition) of
                CampPos when is_record(CampPos, camp_pos)
                  andalso CampPos#camp_pos.type =:= ?CONST_SYS_PLAYER ->
                    Packet = message_api:msg_notice(?TIP_CAMP_SELF),
                    misc_packet:send(Player#player.net_pid, Packet),
                    {?error, ?TIP_CAMP_SELF};
				_X = #camp_pos{id = PartnerId} ->
                    NewCampPosition = erlang:setelement(CampIdx, CampPosition, ?CONST_SYS_TRUE),
                    NewCamp = Camp#camp{position = NewCampPosition},
                    CampList3 = [NewCamp|CampList2],
                    Player2 = Player#player{camp = CampData#camp_data{camp = CampList3}},
                    Packet = camp_api:msg_camp_sc_pos_remove(Camp#camp.camp_id, CampIdx, ?CONST_SYS_TRUE),
                    misc_packet:send(Player#player.net_pid, Packet),
                    update_partner(Player2, NewCampPosition, CampId, 0, PartnerId);
				_ ->
					Packet = message_api:msg_notice(?TIP_CAMP_REMOVE_FAIL),
                    misc_packet:send(Player#player.net_pid, Packet),
					{?error, ?TIP_CAMP_REMOVE_FAIL}
            end;
		?false ->
			Packet = message_api:msg_notice(?TIP_CAMP_REMOVE_FAIL),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_CAMP_REMOVE_FAIL}
    end.

%% 开启阵型
start_camp(Player, CampId) ->
	CampData	= Player#player.camp,
	case lists:keyfind(CampId, #camp.camp_id, CampData#camp_data.camp) of
		Camp when is_record(Camp, camp) ->
			CampData2	= CampData#camp_data{camp_use = CampId},
			Player2		= Player#player{camp = CampData2},
			Packet		= camp_api:msg_camp_sc_use(CampId),
			misc_packet:send(Player2#player.net_pid, Packet),
            update_partner(Player2, Camp#camp.position, CampId); % {?ok, Player3}
		_ ->
			Packet = message_api:msg_notice(?TIP_CAMP_SET_FAIL),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_CAMP_SET_FAIL}
	end.

%% 读取阵法信息
get_pos(Player, CampId) ->
    CampData = Player#player.camp,
    case lists:keyfind(CampId, #camp.camp_id, CampData#camp_data.camp) of
        Camp when is_record(Camp, camp) ->
            Packet = make_camp_list(CampId, Camp#camp.position, 1, <<>>), 
            misc_packet:send(Player#player.user_id, Packet),
            ?ok;
        _ ->
			Packet = message_api:msg_notice(?TIP_CAMP_READ_FAIL),
			misc_packet:send(Player#player.net_pid, Packet),
			{?error, ?TIP_CAMP_READ_FAIL}
    end.
            
%% 组装阵法列表
make_camp_list(_CampId, _PositionTuple, Idx, OldPacket) when 9 < Idx ->
    OldPacket;
make_camp_list(CampId, PositionTuple, Idx, OldPacket) ->
    Packet = 
        case erlang:element(Idx, PositionTuple) of
            0 ->
                <<>>;
            1 ->
                <<>>;
            CampPos ->
                camp_api:msg_camp_sc_pos_update(CampId, CampPos#camp_pos.idx, CampPos#camp_pos.type, CampPos#camp_pos.id, ?CONST_SYS_FALSE)
        end,
    NewPacket = <<Packet/binary, OldPacket/binary>>,
    make_camp_list(CampId, PositionTuple, Idx + 1, NewPacket).

%%
%% API Functions
%%

check(Player, RecCamp)
  when is_record(RecCamp, rec_camp) ->
	try
		Info	= Player#player.info,
        UserId  = Player#player.user_id,
		?ok 	= check_gold(UserId, RecCamp#rec_camp.gold),
		?ok 	= check_lv(Info#info.lv, RecCamp#rec_camp.lv, RecCamp#rec_camp.lv_min),
		{?ok, Type} 	= check_goods(UserId, Player#player.bag, RecCamp#rec_camp.goods_id, 1),
		{?ok, Type}
	catch
		throw:Return ->
            Return;
		X:Y ->
            ?MSG_ERROR("x=~p, y=~p", [X, Y]),
			{?error, ?TIP_COMMON_BAD_ARG}
	end.

%% 检查历练
check_gold(UserId, Gold) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, Gold) of
        {?ok, _Money, ?true} ->
            ?ok;
        {?ok, _, ?false} ->
            throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH});
        {?error, ErrorCode} ->
            throw({?error, ErrorCode})
    end.

%% 检查等级
check_lv(_Lv, CampLv, 0) ->
	if 20 >= CampLv -> ?ok; ?true -> throw({?error, ?TIP_CAMP_LV_MAX}) end;					%%阵法等级已经最大
check_lv(Lv, CampLv, RequestLv) ->
	if Lv >= RequestLv ->
		   if 20 >= CampLv -> ?ok; ?true -> throw({?error, ?TIP_CAMP_LV_MAX}) end;
	   ?true -> throw({?error, ?TIP_CAMP_LV_NOT_OPEN})
	end.
%% 检查物品数量
check_goods(_, _Ctn, 0, _CountRequest) -> % 不需要物品
    {?ok, 0};
check_goods(UserId, Ctn, GoodsId, CountRequest) ->
	case ctn_api:get_count(Ctn, GoodsId) of
		Count when Count >= CountRequest -> {?ok, 1};
		_ -> 
            case player_money_api:check_money(UserId, ?CONST_SYS_CASH, ?CONST_CAMP_CAMP_BOOK_CASH) of
                {?ok, _, ?true} ->
                    {?ok, 2};
                _ ->
                    throw({?error, ?TIP_CAMP_GOODS_NOT_ENOUGH})
            end
	end.

%% 获取阵法中的伙伴id列表
get_partner_id_list(Position, UserId, Idx, ResultList) when Idx =< 9 ->
    case erlang:element(Idx, Position) of
        PartnerPos when is_record(PartnerPos, camp_pos) andalso PartnerPos#camp_pos.id =/= UserId ->
            NewResultList = [PartnerPos#camp_pos.id|ResultList],
            get_partner_id_list(Position, UserId, Idx + 1, NewResultList);
        _ ->
            get_partner_id_list(Position, UserId, Idx + 1, ResultList)
    end;
get_partner_id_list(_Position, _UserId, _Idx, ResultList) ->
    ResultList.

%% 顺序找空位
get_empty(Position, Idx) when Idx =< 9 ->
    case erlang:element(Idx, Position) of
        ?CONST_SYS_TRUE -> {?ok, Idx};
        _ -> get_empty(Position, Idx + 1)
    end;
get_empty(_Position, _) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

%% 反序找空位
get_empty_desc(Position, Idx) when Idx > 0 andalso Idx =< 9 ->
    case erlang:element(Idx, Position) of
        ?CONST_SYS_TRUE -> {?ok, Idx};
        _ -> get_empty_desc(Position, Idx - 1)
    end;
get_empty_desc(_Position, _) ->
    {?error, ?TIP_COMMON_BAD_ARG}.

%% 升级任意阵法到五级
pullulation_interface(Player, ?CONST_CAMP_YULIN_LV) -> % XXX
    welfare_api:add_pullulation(Player, ?CONST_WELFARE_CAMP, ?CONST_CAMP_YULIN_LV, 1);
pullulation_interface(Player, _) ->
    {?ok, Player}.
    
%% 读取所有阵法的最高等级
get_max_lv([#camp{lv = Lv}|Tail], OldMaxLv) when Lv > OldMaxLv ->
    get_max_lv(Tail, Lv);
get_max_lv([_|Tail], OldMaxLv) ->
    get_max_lv(Tail, OldMaxLv);
get_max_lv([], Lv) ->
    Lv.
    
