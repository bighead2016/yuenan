%% Author: Administrator
%% Created: 2012-10-12
%% Description: TODO: Add description to collect_api
-module(collect_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([enter/2,
		 exit/1,
		 start_collect/4, 
		 update_collect/0,
		 update_collect_ext/2,
		 end_collect/1,
		 logout/1,
		 check_collect/2]).

%%
%% API Functions
%%
enter(Player, MapId) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_COLLECT) of
		{?true,	NewPlayer}	->
			Player2 = map_api:enter_map(NewPlayer, MapId),
			{?ok, Player2};
		{?false, _, Tips} ->
            PacketError = message_api:msg_notice(Tips),
			misc_packet:send(Player#player.user_id, PacketError),
            {?ok, Player}
	end.

exit(Player) ->
	case player_state_api:try_set_state_play(Player, ?CONST_PLAYER_PLAY_CITY) of
		{?true, Player2} ->
            Player3 = map_api:return_last_city(Player2),
			{?ok, Player3};
		{?false, _, _} ->
			{?ok, Player}
	end.

check_collect(Player, SpNeed) ->
	try
		?ok = check_sp(Player, SpNeed),
		?ok = check_bag_full(Player)
	catch
		throw:{?error, ?TIP_COMMON_SP_NOT_ENOUGH = ErrorCode} ->
            PacketError = player_api:msg_sc_not_enough_sp(),
            {?error, ErrorCode, PacketError};
		throw:{?error, ErrorCode} ->
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError};
        _:_ ->
            ErrorCode = ?TIP_COMMON_BAD_ARG,
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError}
    end.


check_sp(Player, SpNeed) ->
    Info   = Player#player.info,
    Sp     = Info#info.sp,
    if
        Sp >= SpNeed ->
            ?ok;
        ?true ->
            throw({?error, ?TIP_COMMON_SP_NOT_ENOUGH})
    end.

%% 背包是否满
check_bag_full(Player) ->
    case ctn_bag2_api:is_full(Player#player.bag) of
        ?true ->
            throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH});
        ?false ->
            ?ok
    end.

start_collect(Player, Lv, Type, Times) ->
	PlayerLv = (Player#player.info)#info.lv,
	case PlayerLv >= Lv of
		?true ->
			case data_collect:get_base_collect({Lv, Type}) of
				BaseCollect when is_record(BaseCollect, rec_collect) ->
					start_collect_ext(Player, BaseCollect, Times);
				_Other ->
					ErrorCode   = ?TIP_COMMON_BAD_ARG,
                    PacketError = message_api:msg_notice(ErrorCode),
                    {?error, ErrorCode, PacketError}
			end;
			
		?false ->	%% 等级不够
			ErrorCode   = ?TIP_COMMON_LEVEL_NOT_ENOUGH,
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError}
	end.

start_collect_ext(Player, BaseCollect, Times) ->
	Now = misc:seconds(),
	CollectInfo = #collect{user_id			= Player#player.user_id,				% 玩家ID
							lv				= BaseCollect#rec_collect.lv,			% 采集等级
							type			= BaseCollect#rec_collect.collect_type,	% 类型
							sp 				= BaseCollect#rec_collect.sp,			% 消耗体力
							time        	= BaseCollect#rec_collect.time,			% 采集时间
							normal_goods	= BaseCollect#rec_collect.normal_goods,	% 普通物品掉落id
							adv_rate		= BaseCollect#rec_collect.adv_rate,		% 奇遇几率
							adv_goods		= BaseCollect#rec_collect.adv_goods,	% 奇遇物品掉落id
							state		    = 1,									% 采集状态（0停止1采集中）
							times			= Times,								% 采集次数
							reward_time	    = Now + BaseCollect#rec_collect.time 	% 获取采集物品时间 
						  },
	SpeedNeed  = BaseCollect#rec_collect.sp * Times,
	case check_collect(Player, SpeedNeed) of
		?ok ->
			insert_collect(CollectInfo),
			welfare_api:add_pullulation(Player, ?CONST_WELFARE_COLLECT, 0, 1);
		{?error, ErrorCode, PacketError} ->
           {?error, ErrorCode, PacketError}
	end.
			
%% 	case player_api:check_sp(Player, Sp) of
%% 		?true ->
%% 			insert_collect(CollectInfo),
%% 			welfare_api:add_pullulation(Player, ?CONST_WELFARE_COLLECT, 0, 1);
%% 		?false ->
%% 			ErrorCode2   = ?TIP_COMMON_SP_NOT_ENOUGH,
%%             PacketError2 = message_api:msg_notice(ErrorCode2),
%%             {?error, ErrorCode2, PacketError2}
%% 	end.

insert_collect(CollectInfo) when is_record(CollectInfo, collect) ->
	ets_api:insert(?CONST_ETS_COLLECT, CollectInfo).


update_collect() ->
	CollectList = ets_api:list(?CONST_ETS_COLLECT),
	Now = misc:seconds(),
	Fun = fun(Collect = #collect{user_id = UserId, state = State, time = Time, times = Times, reward_time = RewardTime})
			   when State =:= 1 andalso Now >= RewardTime andalso Times > 0 ->
				  case player_api:process_send(UserId, ?MODULE, update_collect_ext, Collect) of
                    ?true ->
                        ?ok;
                    ?false ->
                        ErrorCode   = ?TIP_COMMON_SYS_ERROR,
			            message_api:msg_notice(ErrorCode)
                  end,
				  NewRewardTime = Now + Time,
				  NewTimes = Collect#collect.times - 1,
				  NewCollect = Collect#collect{reward_time = NewRewardTime, times = NewTimes},
				  insert_collect(NewCollect);
			 (#collect{user_id = UserId, times = Times}) when Times =:= 0 ->
				  ets_api:delete(?CONST_ETS_COLLECT, UserId);
			 (_X) -> ?ok
%%                   ?MSG_ERROR("X=~p", [X])
		  end,
	lists:foreach(Fun, CollectList).

update_collect_ext(Player, Collect) ->
	?RANDOM_SEED,
	NormalGoodsList = goods_api:goods_drop(Collect#collect.normal_goods),
	AdvGoodsList 	=
		case misc_random:odds(Collect#collect.adv_rate, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
			?true ->
				goods_api:goods_drop(Collect#collect.adv_goods);
			?false ->
				[]
		end,
	FunGood = fun(Elem) ->
				  GoodId = Elem#goods.goods_id,
				  Count  = Elem#goods.count,
				  {GoodId, Count}
		  end,
	NormalGoods 	= lists:map(FunGood, NormalGoodsList),
	AdvGoods 		= lists:map(FunGood, AdvGoodsList),
	RemainTimes = Collect#collect.times - 1,
	Data = 
		[
		 NormalGoods,
		 AdvGoods,
		 RemainTimes
		],
	Packet = misc_packet:pack(?MSG_ID_COLLECT_SC_COLLECT_INFO, ?MSG_FORMAT_COLLECT_SC_COLLECT_INFO, Data),
	misc_packet:send(Collect#collect.user_id, Packet),
	
	%% 更新玩家信息(增加物品、扣除体力)
	GoodsList = NormalGoodsList ++ AdvGoodsList,
	case GoodsList of
		[]->
			{?ok, Player};
		_Other1 ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_COLLECT_GET, 1, 1, 1, 0, 1, 1, []) of
				{?ok, NewPlayer, _, _BagPacket} ->
					case player_api:minus_sp(NewPlayer, Collect#collect.sp, ?CONST_COST_COLLECT_SP) of
	                    {?ok, NewPlayer2} ->
                            admin_log_api:log_goods(NewPlayer2#player.user_id, ?CONST_SYS_GOODS_MAKE, 
                                                    ?CONST_COST_COLLECT_GET, GoodsList, misc:seconds()),
	                        {?ok, NewPlayer2};
                        {?error, ?TIP_COMMON_SP_NOT_ENOUGH} ->
                            UserId = Player#player.user_id,
                            PacketError = player_api:msg_sc_not_enough_sp(),
                            misc_packet:send(UserId, PacketError),
                            {?ok, Player};
	                    {?error, ErrorCode} ->
	                        UserId = Player#player.user_id,
	                        PacketErr = message_api:msg_notice(ErrorCode),
	                        misc_packet:send(UserId, PacketErr),
	                        {?ok, Player}
	                end;
				_Other2 ->
					end_collect(Player#player.user_id),
					{?ok, Player}
			end
	end.


%% 结束采集
end_collect(UserId) ->
	case ets_api:lookup(?CONST_ETS_COLLECT, UserId) of
		Collect when is_record(Collect, collect) ->
			case Collect#collect.state =:= 1 of
				?true ->	%% 正在采集时提示停止采集
					TipPacket = message_api:msg_notice(?TIP_MAP_END_COLLECT),
					misc_packet:send(UserId, TipPacket);
				?false ->
					?ok
			end,
			ets_api:delete(?CONST_ETS_COLLECT, UserId);
		_Other ->
			ErrorCode   = ?TIP_COMMON_SYS_ERROR,
            PacketError = message_api:msg_notice(ErrorCode),
            {?error, ErrorCode, PacketError}
	end.
	
%% 下线时处理
logout(Player) ->
    UserId = Player#player.user_id,
    ets_api:delete(?CONST_ETS_COLLECT, UserId).
%% Local Functions
%%

