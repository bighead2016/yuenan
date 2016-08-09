%% 修为提升
-module(player_cultivation_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.goods.data.hrl").

%%
%% Exported Functions
%%
-export([upgrate/1, get_special_skill/1, get_special_skill/2, refresh_attr_cultivation/1, is_same_phase/2,
         set_culti/2, open_culti/1, get_cur_phase/1]).

%%
%% API Functions
%%

%% 读取修为值
get_cultivation(Player) ->
    Info  = Player#player.info,
    Info#info.cultivation.

get_cur_phase(Point) ->
	CurCulti  = read_cultivation(Point),
	case Point =:= 0 of
		?true ->
			1;
		?false ->
			CurCulti#cultivation.phase
	end.

get_bag(Player) ->
    Player#player.bag.
%% set_bag(Player, Bag) ->
%%     Player#player{bag = Bag}.

%% 提升修为
upgrate(Player) ->
    Point = get_cultivation(Player),
    if
        Point < ?CONST_PLAYER_CULTI_MAX_POINT ->  % 正常
%% 			CurPhase  = get_cur_phase(Point),
            Culti  = read_cultivation(Point+1),
%%             UserId = Player#player.user_id,
            Bag    = get_bag(Player),
            case check_cost(Player, Bag, Culti) of
                {?ok, Player2} -> % 消耗ok
%%                     Player2 = set_bag(Player, Bag2),
                    do_upgrate(Player2, Culti);
                {?error, _ErrorCode} -> % 消耗不够
                    Player
            end;
        ?true ->  % 超过上限了
            UserId = Player#player.user_id,
            Packet = message_api:msg_notice(?TIP_PLAYER_CULTI_MAX),
            misc_packet:send(UserId, Packet),
            Player
    end.

%% 检查消耗
%% 铜钱/道具
check_cost(Player, _Bag, Culti) ->
    try
		UserId	= Player#player.user_id,
        Gold 	= Culti#cultivation.gold,
		{GoodsId, Count} = Culti#cultivation.goods_id,
        ?ok  	= check_cost_gold(UserId, Gold),
        {?ok, Player2} 	= check_goods(Player, GoodsId, Count),
        ?ok  	= cost_gold(UserId, Gold),
        {?ok, Player2}
    catch
        throw:Msg ->
            Msg;
        Type:Why ->
            ErrorStack = erlang:get_stacktrace(),
            ?MSG_ERROR("Type=~p, Why=~p, ErrorStack=~p~n", [Type, Why, ErrorStack]),
            {?error, ?TIP_COMMON_BAD_ARG} 
    end.

%% 绑定铜钱够?
check_cost_gold(UserId, Gold) ->
    case player_money_api:check_money(UserId, ?CONST_SYS_GOLD_BIND, Gold) of
        {?ok, _Money, ?true} ->
            ?ok;
        {?ok, _Money, ?false} ->
            Packet = message_api:msg_notice(?TIP_COMMON_GOLD_NOT_ENOUGH),
            misc_packet:send(UserId, Packet),
            throw({?error, ?TIP_COMMON_GOLD_NOT_ENOUGH});
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            throw({?error, ErrorCode})    
    end.

cost_gold(UserId, Gold) ->
    case player_money_api:minus_money(UserId, ?CONST_SYS_GOLD_BIND, Gold, ?CONST_COST_PLAYER_CULTI_UPGRATE) of
        ?ok ->
            ?ok;
        {?error, ErrorCode} ->
            Packet = message_api:msg_notice(ErrorCode),
            misc_packet:send(UserId, Packet),
            throw({?error, ErrorCode})    
    end.

%% 背包里道具够?
check_goods(Player, GoodsId, Count) ->
	UserId	= Player#player.user_id,
	case goods_api:use_goods_by_id_list(Player, [{GoodsId, Count}]) of
		{?ok, NewPlayer, [], Packet} ->
			admin_log_api:log_goods(UserId, 0, ?CONST_COST_PLAYER_CULTI_UPGRATE, GoodsId, Count, misc:seconds()),
            misc_packet:send(UserId, Packet), %% 通知刷新物品
			{?ok, NewPlayer};
		{?ok, NewPlayer, GoodsList, Packet} ->
			Cash = get_goods_convert_cash(GoodsList),
			 case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, Cash, ?CONST_COST_PLAYER_CULTI_UPGRATE) of
				?ok ->
					misc_packet:send(UserId, Packet),	%% 通知刷新物品
					{?ok, NewPlayer}; 
				_ -> throw({?error, ?TIP_COMMON_CASH_NOT_ENOUGH})
			end
	end.
%% check_goods(UserId, Bag, GoodsId, Count) ->
%%     case check_goods_phase(UserId, Bag, GoodsId, Count) of
%%         {?ok, Bag2, Packet} ->
%% 			admin_log_api:log_goods(UserId, 0, ?CONST_COST_PLAYER_CULTI_UPGRATE, GoodsId, Count, misc:seconds()),
%%             misc_packet:send(UserId, Packet),
%%             Bag2;
%%         {?error, ErrorCode} ->
%% 			Packet  = message_api:msg_notice(?TIP_GOODS_THE_COUNT_NOT_ENOUGH, [{?TIP_SYS_NOT_EQUIP, misc:to_list(GoodsId)}]),
%% 			misc_packet:send(UserId, Packet),
%%             throw({?error, ErrorCode})
%%     end.


%% check_goods_phase(UserId, Bag, GoodsId, Count)  ->
%%     case ctn_bag2_api:get_by_id_not_send(UserId, Bag, GoodsId, Count) of
%%         {?ok, Bag2, _GoodsList, Packet} ->
%%             admin_log_api:log_goods(UserId, ?CONST_SYS_GOODS_USE, ?CONST_COST_PLAYER_CULTI_UPGRATE, GoodsId, 1, misc:seconds()),
%%             {?ok, Bag2, Packet};
%%         {?error, _ErrorCode} ->
%%             {?error, ?TIP_GOODS_COUNT_NOT_ENOUGH}
%%     end.

%% 提升修为
do_upgrate(Player, Culti) ->
    Rate = get_culti_rate(Culti),
    case is_success(Rate) of 
        ?true -> % 提升成功
			Point    = get_culti_point(Culti),
			PointOld = (Player#player.info)#info.cultivation,
            Player2  = player_api:plus_cultivation(Player, 1),
            Player3  = player_attr_api:refresh_attr_cultivation(Player2),
            Info     = Player3#player.info,
            PointNew = Info#info.cultivation,
            Packet2  = player_api:msg_sc_culti_now(PointNew),
            UserId   = Player#player.user_id,
            misc_packet:send(UserId, Packet2),
			check_activity_cultivation(UserId,PointOld,PointNew),                    %运营活动奖励检测
            {?ok, Player4} = welfare_api:add_pullulation(Player3, ?CONST_WELFARE_CULTIVATION, 0, 1), % XXX
			%% 新服成就
			{?ok, Player5}	= new_serv_api:finish_achieve(Player4, ?CONST_NEW_SERV_CULTIVATION, Point, 1),
			%% 修为提升成就
			{?ok, Player6}  = achievement_api:add_achievement(Player5, ?CONST_ACHIEVEMENT_CULTIVATION_UP, Point, 1),
            Packet = message_api:msg_notice(?TIP_PLAYER_CULTI_SUCCESS),
            misc_packet:send(Player#player.user_id, Packet),
			schedule_power_api:do_upgrade_culti(Player6),
			skill_api:refresh_skill_info(Player6);
        ?false -> % 失败
            Player
    end.
    
%% 成功?
is_success(Rate) ->
    Dice = misc_random:random(?CONST_SYS_NUMBER_TEN_THOUSAND),
    Dice =< Rate.
    
%% 读取特殊技能数据--连续技
get_special_skill(Player) when is_record(Player, player) ->
	get_special_skill((Player#player.info)#info.pro, (Player#player.info)#info.cultivation).

get_special_skill(Pro, CultivationNum) when is_number(CultivationNum) ->
	Cultivation	=
		case read_cultivation(CultivationNum) of
			CultiTemp when is_record(CultiTemp, cultivation) -> CultiTemp;
			?null -> read_cultivation(1)
		end,
	SkillExt	= element(Pro, Cultivation#cultivation.skill_ext),
	{
	 Cultivation#cultivation.count,
	 Cultivation#cultivation.factor,
	 Cultivation#cultivation.rate_anger,
	 SkillExt
	}.

%% 刷新属性
refresh_attr_cultivation(Player) ->
    Info  = Player#player.info,
    Point = Info#info.cultivation,
	InitAttr		= player_attr_api:record_attr(),
	{AttrPer, AttrVal} =
	    case Point of
	        0 ->
	            {[], []};
	        _ ->
	            Culti = read_cultivation(Point),
	            TempAttrPer 	= Culti#cultivation.attr_list,
				AttrValList	 	= Culti#cultivation.attr_value_list,
				TempAttrVal		= calc_culti_attr_value(AttrValList, InitAttr),
				{TempAttrPer, TempAttrVal}
	    end,
	{AttrPer, AttrVal}.

%% 计算修为加成值属性
calc_culti_attr_value([], Attr) -> Attr;
calc_culti_attr_value([{Type, Value}|List], Attr) ->
	NewAttr	= player_attr_api:attr_plus(Attr, Type, Value),
	calc_culti_attr_value(List, NewAttr).
    
%% 同阶?
is_same_phase(Point1, Point2) ->
    Culti1 = read_cultivation(Point1),
    Culti2 = read_cultivation(Point2),
    Phase1 = get_culti_phase(Culti1),
    Phase2 = get_culti_phase(Culti2),
    Phase1 =:= Phase2.

set_culti(Player, Culti) when 0 =< Culti andalso Culti =< ?CONST_PLAYER_CULTI_MAX_POINT ->
    Info = Player#player.info,
    Info2 = Info#info{cultivation = Culti},
    {?ok, Player#player{info = Info2}};
set_culti(Player, _) ->
    {?ok, Player}.
    
%% 打开祭星系统
open_culti(Player) ->
	Info		= Player#player.info,
	CultiFlag	= Info#info.culti_flag,
	Packet		= player_api:msg_player_sc_open_culti(CultiFlag),
	misc_packet:send(Player#player.user_id, Packet),
	Info2		=
		case CultiFlag of
			?CONST_SYS_FALSE ->
				Info#info{culti_flag = ?CONST_SYS_TRUE};
			?CONST_SYS_TRUE ->
				Info
		end,
	{?ok, Player#player{info = Info2}}.
				
%%
%% Local Functions
%%

%% 读取修为数据
read_cultivation(Point) ->
    data_player:get_player_cultivation(Point).

get_culti_rate(Culti) ->
    Culti#cultivation.rate.

get_culti_phase(Culti) ->
    Culti#cultivation.phase.

get_culti_point(Culti) ->
    Culti#cultivation.point.

%%运营活动奖励检测
check_activity_cultivation(PlayerId,Point,PointNew)->
	try 
		Lamp = Point - (Point div 11),                            %修为转化成灯盏数
		LampNew = PointNew - (PointNew div 11),
		case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {PlayerId,6}) of
			{_,_,Data,_,_} ->
				case LampNew >Data of
					true->
						yunying_activity_mod:update_activity_info(PlayerId,6,{Lamp,LampNew});
					false ->
						nil
				end;
			_ ->
				case LampNew > Lamp  of
					true->
						yunying_activity_mod:update_activity_info(PlayerId,6,{Lamp,LampNew});
					false ->
						nil
				end
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%% 获取物品转化元宝
get_goods_convert_cash(GoodsList) ->
	Fun = fun({Id, Num}, AccCash) ->
				GoodsInfo = data_goods:get_goods(Id),
				OneCash =(GoodsInfo#goods.exts)#g_func.convert_cash,
				Cash = OneCash * Num,
				AccCash + Cash
		  end,
	lists:foldl(Fun, 0, GoodsList).