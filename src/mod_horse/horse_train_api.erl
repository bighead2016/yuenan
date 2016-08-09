%%% 坐骑培养相关
-module(horse_train_api).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.player.hrl").

%%
%% Exported Functions
%%
-export([init/0, get_free_count/1, login_packet/1, reset_times/1, train/1, on_key/1]).

%%
%% API Functions
%%
init() ->
    #horse_train{}.

%% 登录包
login_packet(Player) ->
    HorseData  = Player#player.horse,
    HorseTrain = HorseData#horse_data.train,
    TrainLv    = HorseTrain#horse_train.lv,
    Exp        = HorseTrain#horse_train.exp,
    LvPacket   = horse_api:horse_data_msg(TrainLv, Exp),
    Count      = get_free_count(Player),
    CountPacket= horse_api:msg_stren_count(Count),
    <<LvPacket/binary, CountPacket/binary>>.

%% 获取免费次数
get_free_count(Player) ->
    HorseData  = Player#player.horse,
    HorseTrain = HorseData#horse_data.train,
    Count      = HorseTrain#horse_train.times,
    misc:max(?CONST_HORSE_FREE_COUNT - Count, 0).

%% 重置强化次数
reset_times(Player) ->
    Now = misc:seconds(),
    HorseData  = Player#player.horse,
    HorseTrain = HorseData#horse_data.train,
    TrainTime  = HorseTrain#horse_train.time,
    case misc:is_same_date(TrainTime, Now) of
        ?true ->
            Player;
        _ ->
            HorseTrain2 = HorseTrain#horse_train{time = Now, times = 0},
            HorseData2 = HorseData#horse_data{train = HorseTrain2},
            Player#player{horse = HorseData2}
    end.

%% 培养
train(Player)->
	HorseData = Player#player.horse,
	HorseTrain = HorseData#horse_data.train,
	TrainLv = HorseTrain#horse_train.lv,
	FoodCount = ctn_bag2_api:get_goods_count(Player#player.bag,?CONST_GOODS_ID_HORSE_FOOD),
	{?ok, #money{cash = Cash, cash_bind_2 = BCash2}} = player_money_api:read_money(Player#player.user_id),
	put(horse_old_trainlv,TrainLv),                        %把培养前的等级存起来，后面会用到
    put(horse_train_food,FoodCount),                 %用草料时，在进程字典中减少，代替每次更新背包，最后一次更新背包就好
    put(horse_train_player_cash,Cash+BCash2),                  %和草料做法一样，一次扣钱，防止卡顿
	case train2(Player) of
		{?ok, Player2,  Packet} ->
			case finished_horse_train_handle(Player2)of
				{?error,ErrorCode}->
					{?error,ErrorCode};
				{Player3,Packet2}->
					{?ok,Player3,Packet,Packet2}
			end;
		{?error, ErrorCode} -> 
			erase(horse_train_player_cash),
			erase(horse_train_food),
			erase(horse_train_crit),
			erase(horse_old_trainlv),
			{?error, ErrorCode}
	end.
train2(Player) ->
    UserId = Player#player.user_id,
    HorseData = Player#player.horse,
    HorseTrain = HorseData#horse_data.train,
    TrainLv = HorseTrain#horse_train.lv,
    Exp = HorseTrain#horse_train.exp,
    Times = HorseTrain#horse_train.times,
    case chk_train(UserId, TrainLv, Times, Exp) of
        {?ok, SmallCrit, SmallCritExp, NormalExp, NewTimes} ->
            Res2= 
                case misc_random:odds(SmallCrit, ?CONST_SYS_NUMBER_TEN_THOUSAND) of
                    ?true ->
                        Res = add_exp(TrainLv, SmallCritExp, Exp, ?CONST_SYS_FALSE),
						put(horse_train_crit,true),                   %记录培养过程中是否暴击，
                        Res;
                    _ ->
                        Res = add_exp(TrainLv, NormalExp, Exp, ?CONST_SYS_FALSE),
                        Res
                end,
            case Res2 of
                {?ok, TrainLv2, Exp2} ->
                    HorseTrain2 = HorseTrain#horse_train{lv = TrainLv2, exp = Exp2, time = misc:seconds(), times = NewTimes},
                    HoresData2 = HorseData#horse_data{train = HorseTrain2},
                    Player2 = Player#player{horse = HoresData2},			
                    {?ok, Player2, <<>>};
                {?error, ErrorCode, TrainLv2, Exp2, IsShow} ->
                    Player3 = 
                        case IsShow of
                            ?CONST_SYS_TRUE ->
                                HorseTrain2 = HorseTrain#horse_train{lv = TrainLv2, exp = Exp2, time = misc:seconds(), times = NewTimes},
                                HoresData2 = HorseData#horse_data{train = HorseTrain2},
                                Player2 = Player#player{horse = HoresData2},
								Player2;
                            ?CONST_SYS_FALSE ->
                                HorseTrain2 = HorseTrain#horse_train{lv = TrainLv2, exp = Exp2, times = Times},
                                HoresData2 = HorseData#horse_data{train = HorseTrain2},
                                Player#player{horse = HoresData2}
                        end,
                    ErrPacket  = message_api:msg_notice(ErrorCode),
                    {?ok, Player3,  ErrPacket}
            end;
        {?error, ErrorCode} ->
            {?error, ErrorCode}
    end.

%% 批量培养
on_key(Player) ->
	Info    = Player#player.info,
	VipData = Info#info.vip,
	VipLv   = VipData#vip.lv,
	UserId = Player#player.user_id,
	case player_vip_api:can_one_key_train_horse(VipLv) of
		?CONST_SYS_TRUE -> 
			HorseData = Player#player.horse,
            HorseTrain = HorseData#horse_data.train,
            TrainLv = HorseTrain#horse_train.lv,
			FreeTimes = get_free_count(Player),
			RestTimes = erlang:max(0, 50 - FreeTimes),
			FoodCount = ctn_bag2_api:get_goods_count(Player#player.bag,?CONST_GOODS_ID_HORSE_FOOD),
			{?ok, #money{cash = Cash, cash_bind_2 = BCash2}} = player_money_api:read_money(UserId),
			case RestTimes >0 of                         %检查免费次数
				true ->	 
					RestTimes2 = erlang:max(0, RestTimes - FoodCount),
					case RestTimes2 >0 of                         %检测坐骑草料
						true ->
							case player_money_api:check_money(UserId , ?CONST_SYS_CASH , 10*RestTimes2) of
								{?ok,_, ?true}->           %检测元宝
                                    put(horse_old_trainlv,TrainLv),                        %把培养前的等级存起来，后面会用到
                                    put(horse_train_food,FoodCount),                 %用草料时，在进程字典中减少，代替每次更新背包，最后一次更新背包就好
                                    put(horse_train_player_cash,Cash+BCash2),                  %和草料做法一样，一次扣钱，防止卡顿
									ok_key_2(Player, 50, <<>>);
								_->
									Packet = message_api:msg_sc_window(?CONST_SYS_CASH),
									misc_packet:send(UserId, Packet),
									Player
							end;
						_ ->
							put(horse_old_trainlv,TrainLv),
							put(horse_train_food,FoodCount),
							put(horse_train_player_cash,Cash+BCash2), 
							ok_key_2(Player, 50, <<>>)
					end;
				_ ->
					put(horse_old_trainlv,TrainLv),
					put(horse_train_food,FoodCount),
					put(horse_train_player_cash,Cash+BCash2), 
					ok_key_2(Player, 50, <<>>)		   
			end;
		_ ->
			ErrPacket = message_api:msg_notice(?TIP_HORSE_STRENGTH_LV),
			misc_packet:send(UserId, ErrPacket),
			Player
	end.

ok_key_2(Player, Times, OldPacket) when Times > 0 ->
	case train2(Player) of
		{?ok, Player2, Packet} ->
			ok_key_2(Player2, Times - 1, <<OldPacket/binary, Packet/binary>>);
		{?error, ErrorCode} ->
			ErrPacket = message_api:msg_notice(ErrorCode),
			case finished_horse_train_handle(Player) of
				{?error,ErrorCode2}->
					throw(ErrorCode2);
				{Player2,Packet2}-> 
					misc_packet:send(Player#player.user_id, <<OldPacket/binary, ErrPacket/binary,Packet2/binary>>),
					Player2
			end
	end;
ok_key_2(Player, _Times, Packet) ->
	case finished_horse_train_handle(Player) of
		{?error,ErrorCode}->
			throw(ErrorCode);
		{Player2,Packet2}-> 
			misc_packet:send(Player#player.user_id, <<Packet/binary, Packet2/binary>>),
			Player2
	end.

chk_train(_UserId, TrainLv, _Times,_) when TrainLv >= ?CONST_HORSE_MAX_LEVEL->
    {?error, ?TIP_HORSE_STRENGTH_FULL};
chk_train(_UserId, TrainLv, Times, Exp) when Times < ?CONST_HORSE_FREE_COUNT ->
    case data_horse:get_horse_lv(TrainLv) of
        #rec_horse_lv{exp = LvExp} = RecHorseLv ->
            DeltaExp = LvExp - Exp,
            if
                DeltaExp =< 1 andalso  TrainLv >= ?CONST_HORSE_MAX_LEVEL->
                    {?error, ?TIP_HORSE_STRENGTH_FULL};
                ?true ->
                    {?ok, RecHorseLv#rec_horse_lv.cash_small_crit, 
                          RecHorseLv#rec_horse_lv.cash_small_crit_exp, 
                          RecHorseLv#rec_horse_lv.cash_exp,
                          Times + 1}
            end;
        _ ->
            {?error, ?TIP_COMMON_BAD_ARG}
    end;
chk_train(_UserId,  TrainLv, Times,Exp) ->
	case data_horse:get_horse_lv(TrainLv) of
		#rec_horse_lv{exp = LvExp} = RecHorseLv ->
			DeltaExp = LvExp - Exp,
			if
				DeltaExp =< 1 andalso TrainLv >=?CONST_HORSE_MAX_LEVEL ->
					{?error, ?TIP_HORSE_STRENGTH_FULL};
				?true ->
					case get(horse_train_food) of
						FoodCount when FoodCount >0 andalso FoodCount =/= undefined->
							put(horse_train_food,FoodCount -1),
							{?ok, RecHorseLv#rec_horse_lv.cash_small_crit, 
							 RecHorseLv#rec_horse_lv.cash_small_crit_exp, 
							 RecHorseLv#rec_horse_lv.cash_exp, 
							 Times};
						_ ->
							case get(horse_train_player_cash) of
								Cash when Cash >= 10 andalso Cash=/= undefined ->
									put(horse_train_player_cash,Cash -10),
									{?ok, RecHorseLv#rec_horse_lv.cash_small_crit, 
									 RecHorseLv#rec_horse_lv.cash_small_crit_exp, 
									 RecHorseLv#rec_horse_lv.cash_exp, 
									 Times};
								_ ->
									{?error, ?TIP_COMMON_CASH_NOT_ENOUGH}
							end
					end
			end;
		_ ->
			{?error, ?TIP_HORSE_STRENGTH_DATA}
	end.

add_exp(TrainLv, _DeltaExp, Exp, IsShow) when TrainLv >= ?CONST_HORSE_MAX_LEVEL->
    {?error, ?TIP_HORSE_STRENGTH_FULL, TrainLv, Exp, IsShow};
add_exp(TrainLv, DeltaExp, Exp, IsShow) when DeltaExp > 0 ->
    case data_horse:get_horse_lv(TrainLv) of
        ?null ->
            {?error, ?TIP_HORSE_STRENGTH_DATA, TrainLv, Exp, IsShow};
        #rec_horse_lv{exp = LvExp} ->
            DExp = LvExp - Exp,
            if
                DExp =< DeltaExp andalso  TrainLv >=?CONST_HORSE_MAX_LEVEL->
                    {?error, ?TIP_HORSE_STRENGTH_FULL, TrainLv, LvExp - 1, 0};
                DExp =< DeltaExp ->
                    add_exp(TrainLv + 1, DeltaExp - DExp, 0, ?CONST_SYS_TRUE);
                ?true ->
                    {?ok, TrainLv, Exp + DeltaExp}
            end
    end;
add_exp(TrainLv, _DeltaExp, Exp, _IsShow) ->
    {?ok, TrainLv, Exp}.

get_lv_msg(StrenLv, StrenLv) -> <<>>;
get_lv_msg(_,_) -> 
    message_api:msg_notice(?TIP_HORSE_STREN_LV_UP) .
						   
%完成了坐骑培养后的一些处理
finished_horse_train_handle(Player)->
	case catch horse_train_minus_food_money(Player) of
		{Player2,BagPacket}->
			Player3   = player_attr_api:refresh_attr_equip(Player2), %%　更新属性
			schedule_power_api:do_update_horse(Player3),
			HorseData = Player3#player.horse,
			HorseTrain = HorseData#horse_data.train,
			NewTrainLv = HorseTrain#horse_train.lv,
			Exp = HorseTrain#horse_train.exp,
			TrainLv = get(horse_old_trainlv),
			case TrainLv < NewTrainLv of
				true -> 
					yunying_activity_mod:update_activity_info(Player3#player.user_id,2,{TrainLv,NewTrainLv}),           %运营活动坐骑培养检测
					TipsPacket = get_lv_msg(TrainLv, NewTrainLv);
				false ->
					TipsPacket = <<>>
			end,
			{?ok, Player4} = 
				if NewTrainLv >= ?CONST_ACHIEVEMENT_NEW_SERV_HORSE_LV ->
					   new_serv_api:add_honor_title(Player3, ?CONST_NEW_SERV_FIRST_HOST, ?CONST_ACHIEVEMENT_FIRST_HOST);
				   ?true ->
					   {?ok, Player3}
				end,
			{?ok, Player5} = 
				lists:foldl(fun(TL,{?ok,PL})->
									new_serv_api:finish_achieve(PL, ?CONST_NEW_SERV_TRAIN_HORSE, TL, 1)
							end,{?ok,Player4},lists:seq(TrainLv+1, NewTrainLv)),
			LvPacket   = horse_api:horse_data_msg(NewTrainLv, Exp),
			Count      = get_free_count(Player5),
			CountPacket= horse_api:msg_stren_count(Count),
			case get(horse_train_crit) of
				true ->
					PacketCrit = horse_api:msg_sc_crit(?CONST_HORSE_SMALL_CRIT);
				_ ->
					PacketCrit = <<>>
			end,
			erase(horse_train_player_cash),
			erase(horse_train_food),
			erase(horse_train_crit),
			erase(horse_old_trainlv),
			{Player5,<<BagPacket/binary,TipsPacket/binary,LvPacket/binary,CountPacket/binary,PacketCrit/binary>>};
		ErrorCode->
			erase(horse_train_player_cash),
			erase(horse_train_food),
			erase(horse_train_crit),
			erase(horse_old_trainlv),
			{?error,ErrorCode}
	end.

%%坐骑培养扣钱扣道具
horse_train_minus_food_money(Player)->
	UserId = Player#player.user_id,
	Bag = Player#player.bag,
	FoodCount = ctn_bag2_api:get_goods_count(Bag,?CONST_GOODS_ID_HORSE_FOOD),
	UsedFood = FoodCount - get(horse_train_food),
    {Player2, BagPacket} = 
    	case UsedFood > 0 of
    		true ->	  
    			{?ok, Bag2, _, BagPacketT} = ctn_bag2_api:get_by_id_not_send(UserId, Bag, ?CONST_GOODS_ID_HORSE_FOOD, UsedFood),
    			admin_log_api:log_goods(UserId, 0, ?CONST_COST_HORSE_LV_UP, ?CONST_GOODS_ID_HORSE_FOOD, UsedFood, misc:seconds()),
    			{Player#player{bag = Bag2}, BagPacketT};
    		false ->
                {Player, <<>>}
    	end,
	{?ok, #money{cash = Cash, cash_bind_2 = BCash2}} = player_money_api:read_money(UserId),
	UsedCash = Cash + BCash2 - get(horse_train_player_cash),
	case UsedCash >0 of
		true ->
			?ok = player_money_api:minus_money(UserId, ?CONST_SYS_CASH, UsedCash, ?CONST_COST_HORSE_LV_UP);
		false ->
			next
	end,
	{Player2,BagPacket}.
                                  
				                   
	
