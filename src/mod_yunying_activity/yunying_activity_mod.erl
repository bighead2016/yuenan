%% @author zane
%% @doc @todo Add description to yunying_activity_mod.
-module(yunying_activity_mod).


-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.goods.data.hrl").
-define(YUNYING_ACTIVITY_LIST,[1,2,3,4,5,6,7,8,9,10,11,12,13,14, 16, 17, 18, 19, 20, 21, 22, 23,24,25,26,27]).                         %运营活动列表
-define(SHUANGDAN_ACTIVITY_LIST,[1001,1002,1003]).                             %双旦活动列表
%% -define(BLESS_ACTIVITY_TYPE, 17).											%财神祝福厚活动type
-define(BLESS_COMMON_FREE_TIMES, 1).                                              %财神普通祝福免费次数
-define(BLESS_LOW_NEED_YUANBAO, 10).                                               %财神普通祝福所需元宝数
-define(BLESS_HIGH_NEED_YUANBAO, 50).                                              %财神高级祝福所需元宝数
%% -define(YUNYING_STONE_VALUE, 18).                                        %运营活动之宝石积分
%% -define(YUNYING_ACTIVITY_EXCHANGE_ID, 13).                               %运营活动兑换活动activity_id
%% -define(YUNYING_ACTIVITY_SPRING_ID, 20).                                 %运营活动春联活动activity_id
%% ====================================================================
%% API functions
%% ====================================================================
-export([
		 activity_request_data/1,shuangdan_activity_request_data/1,update_activity_info/3,check_activity_open/1,
		 activity_unlimitted_award/3,display_yunying_activity_info/1,display_shuangdan_activity_info/1, send_activity_online_award/1,
		 refresh_activity_online_zero/1,update_shuangdan_activity_info/3,get_shuangdan_activity_gift/3,shuangdan_refresh_zero/1,
		 exchange_goods/4,stone_compose_count/3,get_stone_compose/1,get_stone_compose_award/2,stone_compose_mail/1,
		 init_yunying_activity_info/1, get_bless_info/1,get_bless_value/2,bless_exchange_goods/3,
		 refresh/1,bless_refresh/1,add_activity_stone_value/4,get_stone_value_info/1,get_stone_value_exchange_goods/3,activity_gift_can_get/3
		]).


%% ====================================================================
%% Internal functions
%% ====================================================================
%%在ets表中存的数据形式是：{{user_id,type},gift_got,data,time_s,time_e}
%%{user_id,type}是玩家和活动类型的唯一标识
%%gift_got是玩家已经获得的目标id列表,data是不同类型活动独有的一个数据
%%time_s,time_e 是记录这些数据时所在的活动开启和结束时间，主要用于下次读时判断数据的有效性

%%请求运营活动信息
activity_request_data(Player)when is_record(Player, player) ->
	Fun = fun(Type)->
				  case check_activity_open(Type) of
					  {true,NewStart,NewEnd} ->
						  case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,Type}) of
							  {_,_,_,Time_S,Time_E} ->
								  Now = misc:seconds(),
								  case Now >= Time_S andalso Now =< Time_E of
									  true ->
										  ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE,  {Player#player.user_id,Type}, [{4,NewStart},{5,NewEnd}]);       %更新活动日期，其他数据保留
									  false ->
										  {InitGiftGot, InitData} =activity_init_data(Player,Type),
										  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},InitGiftGot,InitData,NewStart,NewEnd})           %更新活动日期，但不保留上次数据
								  end;
							  _ -> 
								  {InitGiftGot, InitData} = activity_init_data(Player,Type),	
								  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},InitGiftGot,InitData,NewStart,NewEnd})
						  end;
					  _ -> %不在活动时间内
						  ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{Player#player.user_id,Type})  
				  end
		  end,
	lists:foreach(Fun, ?YUNYING_ACTIVITY_LIST),                                                %玩家查看时先更新一下玩家活动信息
	display_yunying_activity_info(Player#player.user_id), 
	{?ok,Player};
activity_request_data(Player)->
	{?ok,Player}. 

%%玩家上线时，把一些过期的运营活动数据初始化一下
init_yunying_activity_info(Player)->
	Fun = fun(Type)->
				  case check_activity_open(Type) of
					  {true,NewStart,NewEnd} ->
						  case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,Type}) of
							  {_,_,_,Time_S,Time_E} ->
								  Now = misc:seconds(),
								  case Now >= Time_S andalso Now =< Time_E of
									  true ->
										  ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE,  {Player#player.user_id,Type}, [{4,NewStart},{5,NewEnd}]);       %更新活动日期，其他数据保留
									  false ->
										  {InitGiftGot, InitData} =activity_init_data(Player,Type),
										  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},InitGiftGot,InitData,NewStart,NewEnd})           %更新活动日期，但不保留上次数据
								  end;
							  _ ->
								  {InitGiftGot, InitData} = activity_init_data(Player,Type),	
								  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},InitGiftGot,InitData,NewStart,NewEnd})
						  end;
					  _ -> %不在活动时间内
						  ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{Player#player.user_id,Type}),
						  mysql_api:delete(game_active_welfare, lists:append([("user_id = "++misc:to_list(Player#player.user_id)),(" and type = "++misc:to_list(Type))]))
				  end
		  end,
	lists:foreach(Fun, ?YUNYING_ACTIVITY_LIST).                                               %玩家查看时先更新一下玩家活动信息
	
%% 运营活动0点刷新
refresh(Player) ->
    shuangdan_refresh_zero(Player),       %双旦活动零点刷新
	bless_refresh(Player),                %财神祝福0点刷新
	stone_compose_mail(Player),			% 宝石合成过期礼包发送
	?ok.

%%请求双旦活动信息
shuangdan_activity_request_data(Player)when is_record(Player, player) ->
	Fun = fun(Type)->
				  case check_activity_open(Type) of
					  {true,NewStart,NewEnd} ->
						  case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,Type}) of
							  {_,_,_,Time_S,Time_E} ->
								  Now = misc:seconds(),
								  case Now >= Time_S andalso Now =< Time_E of
									  true ->
										  ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE,  {Player#player.user_id,Type}, [{4,NewStart},{5,NewEnd}]);       %更新活动日期，其他数据保留
									  false ->
										  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},[[],[]],0,NewStart,NewEnd})           %更新活动日期，但不保留上次数据
								  end;
							  _ ->
								  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,Type},[[],[]],0,NewStart,NewEnd})
						  end;
					  _ -> %不在活动时间内
						 next
				  end
		  end,
	lists:foreach(Fun, ?SHUANGDAN_ACTIVITY_LIST),                                                %玩家查看时先更新一下玩家活动信息
	display_shuangdan_activity_info(Player#player.user_id), 
	{?ok,Player};
shuangdan_activity_request_data(Player)->
	{?ok,Player}. 

 %%双旦活动数据更新
 update_shuangdan_activity_info(UserId,Type,Value)->
	 try
		 case check_activity_open(Type) of
			 {true,NewStart,NewEnd} ->
				 case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
					 {_,[CanGot,HasGot],Data,Time_S,Time_E} ->
						 Now = misc:seconds(),
						 case Now >= Time_S andalso Now =< Time_E of
							 true ->
								 NewData = Data +Value,
								 AchieveIdList = [Aid||{Aid,_,_}<-activity_gift_can_get(Type,Data,NewData)],
								 NewCanGot= lists:foldl( 
											  fun(AchieveId,Acc)->
													  case lists:member(AchieveId, CanGot++HasGot) of
														  true ->
															  Acc;
														  false ->
															  [AchieveId|Acc]
													  end
											  end,CanGot,AchieveIdList),				
								 ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},[{2,[NewCanGot,HasGot]},{3,NewData},{4,NewStart},{5,NewEnd}]);
							 false ->
								 AchieveIdList = [Aid||{Aid,_,_}<-activity_gift_can_get(Type,0,Value)],
								 ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},[{2,[AchieveIdList,[ ] ]},{3,Value},{4,NewStart},{5,NewEnd}])
						 end;
					 _ ->
						 AchieveIdList = [Aid||{Aid,_,_}<-activity_gift_can_get(Type,0,Value)],
						 ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId,Type},[AchieveIdList,[ ] ],Value,NewStart,NewEnd})
				 end,
				 case player_api:check_online(UserId) of
					 ?true ->
						 case AchieveIdList =/= [] of
							 true->
								 display_shuangdan_activity_info(UserId);
							 false ->
								 next
						 end;
					 ?false ->
						 [{{UserId,Type},Gift_Got,Data2,Time_S2,Time_E2}] = ets:match_object(?CONST_ETS_ACTIVE_WELFARE, {{UserId,Type},'_','_','_','_'}),
						 Sql = <<"insert into `game_active_welfare` (`user_id`,`type`,`gift_got`,`data`,`time_s`,`time_e`) values ('",
								 (misc:to_binary(UserId))/binary, "',' ",
								 (misc:to_binary(Type))/binary, "', ",
								 (mysql_api:encode(Gift_Got))/binary, ",' ",
								 (misc:to_binary(Data2))/binary, "', '",
								 (misc:to_binary(Time_S2))/binary, "',' ",
								 (misc:to_binary(Time_E2))/binary, "')",
								 " ON DUPLICATE KEY UPDATE `gift_got` = ",
								 (mysql_api:encode(Gift_Got))/binary, ", `data`='",
								 (misc:to_binary(Data2))/binary, "', `time_s`='",
								 (misc:to_binary(Time_S2))/binary, "',`time_e`='",
								 (misc:to_binary(Time_E2))/binary, "';">>,
						 mysql_api:select(Sql)
				 end;
			 _  -> %不在活动时间内，可能有些要等到 0点发奖励，不能立即删掉
				 case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
					 {_,[CanGot,_],_,_,_}->
						 case CanGot =/= [] of
							 true ->
								 next;
							 false ->
								 ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{UserId,Type})
						 end;
					 _ ->
						 next
				 end
		 end
	 catch
		 X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.


%%点击获取双旦礼物
get_shuangdan_activity_gift(Player,Type,AchieveId)->
	UserId = Player#player.user_id,
	case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
		{_,[CanGot,HasGot],_,_,_}->
			case lists:member(AchieveId, CanGot)  of
				true ->
					ActivityData = data_yunying_activity:get_yunying_activity_data(Type),
					AwardList =
						case is_record(ActivityData, rec_yunying_activity_data) of
							true ->
								ActivityData#rec_yunying_activity_data.award_list;
							false ->
								[ ]
						end,
					GoodsList = lists:flatten([GL||{AId,_,GL}<-AwardList,AId =:=AchieveId]),
					GoodsList2 =lists:flatten([goods_api:make(GoodsId, Bind, Count)||{_,_,GoodsId,Bind,Count}<-GoodsList]),
					case ctn_bag_api:put(Player, GoodsList2, ?CONST_COST_SHUANGDAN_REWARD, 1, 1, 0, 0, 1, 1, []) of
						{?error, _ErrorCodeBag}	->
							{?ok, Player};
						{?ok, Player2, _, _PacketBag}	->
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}, [{2,[ lists:delete(AchieveId, CanGot), [AchieveId|HasGot] ]}]),
							SuccPacket = yunying_activity_api:msg_sc_shuangdan_get_award(Type,AchieveId),
							misc_packet:send(UserId,<<SuccPacket/binary>>),
							display_shuangdan_activity_info(UserId),
							lists:foreach(
							  fun(#goods{goods_id=Gid,count = Num})->
									  admin_log_api:log_goods(UserId,1,0,Gid,Num,misc:seconds())
							  end,GoodsList2),		
							{?ok, Player2}
					end;
				false ->
					TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_NO_REWARD),
					misc_packet:send(UserId,<<TipPacket/binary>>),
					{?ok,Player}
			end;
		_ ->
			TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_NO_REWARD),
			misc_packet:send(UserId,<<TipPacket/binary>>),
			{?ok,Player}
	end.

%%0点刷双旦数据，发未领取奖励
shuangdan_refresh_zero(Player)->
	try
		UserId = Player#player.user_id,
		Fun =fun(Type)->
					 case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
						 {_,[CanGot,_],_,_,_}->
							 case CanGot =/=[] of
								 true ->
									 ActivityData = data_yunying_activity:get_yunying_activity_data(Type),
									 AwardList =
										 case is_record(ActivityData, rec_yunying_activity_data) of
											 true ->
												 ActivityData#rec_yunying_activity_data.award_list;
											 false ->
												 [ ]
										 end,
									 GoodsList = 
										 lists:foldl(fun(AchieveId,Acc)->
															 lists:flatten([GL||{AId,_,GL}<-AwardList,AId =:=AchieveId])++Acc
													 end,[],CanGot),
									 GoodsList2 =lists:flatten([goods_api:make(GoodsId, Bind, Count)||{_,_,GoodsId,Bind,Count}<-GoodsList]), 
									 ReceiveName =(Player#player.info)#info.user_name,
									 mail_api:send_interest_mail_to_one2(ReceiveName, <<"过期礼包">>, 
																		 <<"这是您在活动期间未领取的礼包，请注意查收">>, ?CONST_MAIL_SAVE_CONTAIN_ATTACHMENT, 
																		 [], GoodsList2, 0, 0, 0, ?CONST_COST_MAIL_YUNYING);
								 _ ->
									 next
							 end;
						 _ ->
							 next
					 end,
					 case check_activity_open(Type) of
						 {true,NewStart,NewEnd}->
							 ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId,Type},[[],[]],0,NewStart,NewEnd});
						 _ -> %活动不开时，把库中和Ets中的数据都删掉
							 ets_api:delete(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}),
							 mysql_api:delete(game_active_welfare, lists:append([("user_id = "++misc:to_list(UserId)),(" and type = "++misc:to_list(Type))]))
					 end
			 end,
		lists:foreach(Fun, ?SHUANGDAN_ACTIVITY_LIST),
		display_shuangdan_activity_info(UserId)
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%玩家运营活动数据变化时调用更新，{Before,After}是数据的变化，用于取得到的奖励
update_activity_info(UserId,Type,{Before,After})-> 
	try
		case check_activity_open(Type) of
			{true,NewStart,NewEnd} ->
				case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
					{_,_,_,Time_S,Time_E} ->
						Now = misc:seconds(),
						case Now >= Time_S andalso Now =< Time_E of
							true ->
								ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},[{3,After},{4,NewStart},{5,NewEnd}]);
							false ->
								ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type},[{2,[ ]},{3,After},{4,NewStart},{5,NewEnd}])
						end;
					_ ->
						ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId,Type},[ ],After,NewStart,NewEnd})
				end,
				activity_send_gift(UserId,Type,Before,After),
				case lists:member(Type,[3,21,22,23,24,25,26,27]) of
					  true ->% 3是累计充值，考虑离线充值的情况，要实时更新数据库
				         update_activity_deposit_db(UserId,Type);
					  false -> 
						  next
				  end;
			_  ->
				ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{UserId,Type})
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end;
update_activity_info(_UserId,_Type,_Change_Info)->
	?ok.

%% 3是累计充值，考虑离线充值的情况，要实时更新数据库
update_activity_deposit_db(UserId,Type)->
	case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
		{_,Gift_Got,Data,Time_S,Time_E} ->
			Sql = <<"insert into `game_active_welfare` (`user_id`,`type`,`gift_got`,`data`,`time_s`,`time_e`) values ('",
					(misc:to_binary(UserId))/binary, "',' ",
					(misc:to_binary(Type))/binary, "', ",
					(mysql_api:encode(Gift_Got))/binary, ",' ",
					(misc:to_binary(Data))/binary, "', '",
					(misc:to_binary(Time_S))/binary, "',' ",
					(misc:to_binary(Time_E))/binary, "')",
					" ON DUPLICATE KEY UPDATE `gift_got` = ",
					(mysql_api:encode(Gift_Got))/binary, ", `data`='",
					(misc:to_binary(Data))/binary, "', `time_s`='",
					(misc:to_binary(Time_S))/binary, "',`time_e`='",
					(misc:to_binary(Time_E))/binary, "';">>,
			mysql_api:select(Sql);
		_ ->
			next
	end.


%%运营活动发奖品
activity_send_gift(UserId,Type,Before,After)  ->  
	case  ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
		{_,Gift_Got,_,_,_} ->
			GiftList = activity_gift_can_get(Type,Before,After),
			{Gift2Send,Gift_Got2} =                                            
				case Type of
					14 ->          %14要特殊处理，是重复消费活动，因为既要保留数据，又要重复发放
						{GiftList,Gift_Got};
					_ ->
						lists:foldl(
						  fun({AchieveId,Condition,GL},{Acc1,Acc2})->
								  case lists:member(AchieveId, Acc2) of
									  true ->
										  {Acc1,Acc2};
									  false ->
										  {[{Condition,GL}|Acc1],[AchieveId|Acc2]}
								  end 
						  end, {[ ],Gift_Got}, GiftList)
				end, 
			case erlang:length(Gift2Send) > 0 of
				true->
					ReceiveName = player_api:get_name(UserId),
					lists:foreach(
					  fun({Condition,GoodsL})->
							  GoodsL2 = lists:flatten([goods_api:make(GoodsId,Bind,Count)||{_,_,GoodsId,Bind,Count}<-GoodsL]),
							  {MsgId,Content} =  yunying_activity_api:get_mail_info2(Type,Condition),
							  mail_api:send_interest_mail_to_one2(ReceiveName, <<"">>, 
																<<"">>, MsgId, 
																Content, GoodsL2, 0, 0, 0, ?CONST_COST_MAIL_YUNYING),
							  TipPacket  = get_activity_msg_notice(Type,UserId,ReceiveName,Condition),
							  misc_app:broadcast_world_2(TipPacket)
					  end,Gift2Send),	  
					ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}, [{2,Gift_Got2}]),
					display_yunying_activity_info(UserId);
				_ ->
					?ok
			end;	
		_ ->
			?ok
	end.

%%无限领取礼包的接口，满足条件就发礼包，不存数据，PlayerInfo可以是整个Player结构，或者player的名字，或userid
activity_unlimitted_award(PlayerInfo,Data,Type)->
	try
		case check_activity_open(Type) of
			{true,_,_}->
				GiftList =get_activity_unlimitted_award(Data,Type),
				case GiftList =/=[ ] of
					true ->
						ReceiveName = 
							case is_record(PlayerInfo,player) of
								true ->
									(PlayerInfo#player.info)#info.user_name;
								false -> 
									case erlang:is_integer(PlayerInfo) of
										true ->
											player_api:get_name(PlayerInfo);
										false ->
											PlayerInfo
									end
							end,
						lists:foreach(
						  fun({Condition,GL})->
								  {MsgId,Content} =  yunying_activity_api:get_mail_info2(Type,Condition),
								  GoodsList = lists:flatten([goods_api:make(GoodsId,Bind,Count)||{_,_,GoodsId,Bind,Count}<-GL]),
								  mail_api:send_interest_mail_to_one2(ReceiveName, <<"">>, <<"">>, MsgId
                                                                     , Content, GoodsList, 0, 0, 0, ?CONST_COST_MAIL_YUNYING)
						  end,GiftList);
					false ->
						?ok
				end;
			_ ->
				?ok
		end
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.
	
activity_init_data(Player,Type)->
	case Type of 
		2 ->%%坐骑培养的活动
			HorseData = Player#player.horse,
			case HorseData =/= ?null of
				true ->
					HorseTrain = HorseData#horse_data.train,
					{[], HorseTrain#horse_train.lv};
				false ->
					{[], 0}
			end;
		5  -> %破阵
			Data = tower_api:get_top_pass(Player#player.user_id),
			{[], Data};
		6 -> %祭星
            Point = (Player#player.info)#info.cultivation,
			Lamp = Point - Point div 11,
			{[], Lamp};
		20 -> %灯谜
			{[?false, ?false, ?false, ?false], 0};
		?CONST_YUNYING_ACTIVITY_BLESS ->
			{[?BLESS_COMMON_FREE_TIMES], 0};
		_ ->
			{[], 0}
	end.

%%检测在不是当前配置的活动时间内，在时返回{true,StartTime,EndTime}.
check_activity_open(Type)->
	 try
		 ActivityData = data_yunying_activity:get_yunying_activity_data(Type),
		 TimeType = ActivityData#rec_yunying_activity_data.time_type,
		 Time_Start = ActivityData#rec_yunying_activity_data.time_start,
		 Time_End = ActivityData#rec_yunying_activity_data.time_end,
		 NewServ = ActivityData#rec_yunying_activity_data.new_serv,
		 NewServEnd = ActivityData#rec_yunying_activity_data.new_serv_end,


		 Start = misc:date_time_to_stamp(Time_Start),
		 End = misc:date_time_to_stamp(Time_End),
		 Now = misc:seconds(),
		 ServerStart = new_serv_api:get_serv_start_time(),
		 NowDay = (Now+8*3600) div 86400,
         ServerStartDay = (ServerStart+8*3600) div 86400,
         case TimeType of
         	0 -> 
		 		Flag = (Now >= Start) andalso (Now =< End)andalso (NowDay >= ServerStartDay +NewServ),
		 		{Flag,Start,End};
		 	1 ->
		 		Flag = (NowDay >= ServerStartDay + NewServ) andalso (NowDay < ServerStartDay + NewServEnd),
		 		Start1 = (ServerStartDay + NewServ)*86400 - 8*3600,
		 		End1 = (ServerStartDay + NewServEnd)*86400 - 8*3600,
		 		{Flag,Start1,End1}
		 end
	 catch
		 X:Y ->
			 ?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()]),
			 ?error
	 end.


%%获得物品世界公告
get_activity_msg_notice(Type,UserId,ReceiveName,Condition)->
	case Type of
		2 -> %坐骑         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_TRAIN_HORSE, [{UserId, ReceiveName}], [], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		3 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		21 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		22 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		23 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		24 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		25 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		26 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		27 -> %充值         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_DEPOSIT, [{UserId, ReceiveName}],[], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		5 -> %破阵         
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_TOWER, [{UserId, ReceiveName}], [], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		6 -> %祭星cultivation        
			message_api:msg_notice(?TIP_YUNYING_ACTIVITY_CULTIVATION, [{UserId, ReceiveName}], [], 
								   [{?TIP_SYS_COMM, misc:to_list(Condition)}]);
		_ ->
			<<>>
	end.

%%无限制领的，只要返回奖品列表就好，15是单笔充值活动，特殊处理
get_activity_unlimitted_award(Data,Type)->
	ActivityData = data_yunying_activity:get_yunying_activity_data(Type),
	AwardList =
		case is_record(ActivityData, rec_yunying_activity_data) of
			true ->
				ActivityData#rec_yunying_activity_data.award_list;
			false ->
				[ ]
		end,
	case Type =:= 15 of
		true ->        %15是单笔充值活动，特殊处理,只能领最接近那一个礼包
			Temp1 = [{Condition,GoodsList}||{_,Condition,GoodsList}<-AwardList,Condition =< Data],
			case Temp1 =/= [ ] of
				true ->
					Temp2 = lists:keysort(1, Temp1),
					[Result|_] = lists:reverse(Temp2),
					[Result];
				false ->
					[ ]
			end;
		false ->
			lists:flatten([{Condition,GoodsList}||{_,Condition,GoodsList}<-AwardList,Condition ==Data])
	end.

%%有限制的活动获取奖品，还要返回目标id作记录，14（重复消费）类型的要特殊处理一下
activity_gift_can_get(Type,Before,After)->
	ActivityData = data_yunying_activity:get_yunying_activity_data(Type),
	AwardList =
		case is_record(ActivityData, rec_yunying_activity_data) of
			true ->
				ActivityData#rec_yunying_activity_data.award_list;
			false ->
				[ ]
		end,
	case Type of
		14 ->
			lists:foldl(
			  fun({_,Condition,GoodsList},Acc)->
					  Num = (After div (erlang:trunc(Condition))) - (Before div (erlang:trunc(Condition))),
					  GoodsList2 = 
						  case Num >0 of
							  true ->[{Condition,[{Temp1,Temp2,Temp3,Temp4,Temp5*Num}||{Temp1,Temp2,Temp3,Temp4,Temp5}<-GoodsList]}];
							  false ->[]
						  end,										  
					  lists:append(GoodsList2,Acc)
			  end,[ ],AwardList);
		_ ->
			[{AchieveId,Condition,GoodsList}||{AchieveId,Condition,GoodsList}<-AwardList, Condition >Before,Condition=< After]
	end.

%%运营活动给前端发获奖情况
display_yunying_activity_info(UserId)->
	PlayerAllRecord = ets:match_object(?CONST_ETS_ACTIVE_WELFARE, {{UserId,'_'},'_','_','_','_'}),
	AllGot = lists:flatten([OneGot||{{_,Type},OneGot,_,_,_}<-PlayerAllRecord,lists:member(Type, ?YUNYING_ACTIVITY_LIST -- [20])]),                 %取出玩家所有开启的运营活动中完成的目标列表
	% ?MSG_ERROR("AllGot = ~p",[AllGot]),
	Packet = yunying_activity_api:msg_sc_activity_info( AllGot),
	misc_packet:send(UserId, <<Packet/binary>>).

%%双旦活动给前端发获奖情况
display_shuangdan_activity_info(UserId)->
	{CanGotList,HasGotList}=
		lists:foldl(
		  fun(Type,{Acc1,Acc2})->
				  case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type}) of
					  {_,[CG,HG],_,_,_}->
						  case check_activity_open(Type) of
							  {true,_,_}->
						          {lists:append(CG,Acc1),lists:append(HG,Acc2)};
							  _ ->
								  {Acc1,Acc2}
						  end;
					  _ ->
						  {Acc1,Acc2}
				  end
		  end,{[ ],[ ]},?SHUANGDAN_ACTIVITY_LIST),
	Packet = yunying_activity_api:msg_sc_shuangdan_info( CanGotList,HasGotList),
	misc_packet:send(UserId, <<Packet/binary>>).


%%发在线得奖励的奖品
send_activity_online_award(Player)->
	case yunying_activity_mod:check_activity_open(1) of
		{true,TimeStart,TimeEnd} -> %在活动时间
			ActivityData = data_yunying_activity:get_yunying_activity_data(1),
			AwardList =
				case is_record(ActivityData, rec_yunying_activity_data) of
					true ->
						ActivityData#rec_yunying_activity_data.award_list;
					false ->
						[ ]
				end,
			ReceiveName = (Player#player.info)#info.user_name,
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, 1}) of
				{_,Has_Got,_,_,_}-> %之前有数据
					AwardList2 =[{AchieveId,Con,GoodsList}||{AchieveId,Con,GoodsList}<-AwardList,not lists:member(AchieveId, Has_Got)],   %过滤掉已经发的奖品	
					AwardList3 =lists:keysort(2, AwardList2),                                 %按完成条件从小到大排序
					case AwardList3 of
						[{AchieveId2,Condition,GoodsList2}|T]->
							{MsgId,Content} = yunying_activity_api:get_mail_info2(1,Condition),
							GoodsList3 = lists:flatten([goods_api:make(GoodsId,Bind,Count)||{_,_,GoodsId,Bind,Count}<-GoodsList2]),
							mail_api:send_interest_mail_to_one2(ReceiveName, <<"">>, <<"">>, MsgId, Content, 
																GoodsList3, 0, 0, 0, ?CONST_COST_MAIL_YUNYING),
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, 1}, [{2,[AchieveId2|Has_Got]}]),
							display_yunying_activity_info(Player#player.user_id),
							case T of
								[{_,Condition2,_}|_]->
									TimePass = calendar:time_to_seconds(misc:time()),
									Time_To_Midnight = 86400 - TimePass,
									Interval = (Condition2 - Condition)*3600,
									if Time_To_Midnight > Interval ->
										   erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award});
									   true->
										   erase(activity_online_award_timer)
									end;
								_ ->
									erase(activity_online_award_timer)
							end;
						_ ->
							erase(activity_online_award_timer)
					end;
				_ -> %之前没数据
					case AwardList of
						[{AchieveId,Condition,GoodsList}|T]->
							{MsgId,Content} =  yunying_activity_api:get_mail_info2(1,Condition),
							GoodsList2 = lists:flatten([goods_api:make(GoodsId,Bind,Count)||{_,_,GoodsId,Bind,Count}<-GoodsList]),
							mail_api:send_interest_mail_to_one2(ReceiveName, <<"">>, <<"">>, MsgId, Content, 
																GoodsList2, 0, 0, 0, ?CONST_COST_MAIL_YUNYING),
							ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,1},[AchieveId],0,TimeStart,TimeEnd}),
							display_yunying_activity_info(Player#player.user_id),
							case T of
								[{_,Condition2,_}|_]->
									TimePass = calendar:time_to_seconds(misc:time()),
									Time_To_Midnight = 86400 - TimePass,
									Interval = (Condition2 - Condition)*3600,
									if Time_To_Midnight > Interval ->
										   erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award});
									   true->
										   erase(activity_online_award_timer)
									end;
								_ ->
									erase(activity_online_award_timer)
							end;
						_ ->
							erase(activity_online_award_timer)
					end
			end;
		_ ->     %不在活动时间
            erase(activity_online_award_timer),
			ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{Player#player.user_id,1})                     %不管之前有没有数据，清一下
	end.

%%0 点刷新在线奖励
refresh_activity_online_zero(Player)->
	case yunying_activity_mod:check_activity_open(1) of
		{true,TimeStart,TimeEnd} ->
			ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id, 1},[ ],0,TimeStart,TimeEnd}),
			ActivityData = data_yunying_activity:get_yunying_activity_data(1),
			AwardList =
				case is_record(ActivityData, rec_yunying_activity_data) of
					true ->
						ActivityData#rec_yunying_activity_data.award_list;
					false ->
						[ ]
				end,
			case AwardList  of
				[{_,FirstCon,_}|_]->
					Interval = FirstCon*3600,
					case get(activity_online_award_timer) of
						true ->
							next;
						_ ->
							put(activity_online_award_timer,true),
							erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award})
					end;
				_ ->
					erase(activity_online_award_timer)
			end;
		_ ->
			erase(activity_online_award_timer),
			ets_api:delete(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, 1})
	end,
	yunying_activity_mod:display_yunying_activity_info(Player#player.user_id).

%%物品兑换，活动id为13
exchange_goods(Player, ActivityId, ExchangeType, Id) ->
	yunying_activity_api:check_activity_start(ActivityId),
	case data_yunying_activity:get_yunying_activity_exchange(Id) of
		null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_yunying_activity_exchange{type=Type1,need_goods=NeedGoods,exchange_goods=ExcGoodsList} ->
			case ExchangeType =:= Type1 of
				true ->
					next;
				false ->
					throw({?error,?TIP_COMMON_BAD_ARG})
			end,
			F = fun({GoodsId, Num}, {Flag1, Flag2}) ->
						if Flag2 =:= ?true orelse Flag1 =:= first ->
							   RealNum = ctn_bag2_api:get_goods_count(Player#player.bag, GoodsId),
							   if RealNum >= Num ->
									  {no_first, ?true};
								  ?true ->
									  {no_first, ?false}
							   end;
						   ?true ->
							   {no_first, ?false}
						end
				end,
			{_, Check_Goods_Num} = lists:foldl(F, {first, ?false}, NeedGoods), %% 检查背包物品是否足够
			{Player1, Packet1} = 
				if Check_Goods_Num =:= ?true -> %% 扣除物品
					case ctn_bag2_api:get_by_multi_id(Player#player.user_id, Player#player.bag, NeedGoods) of
					   {?ok, Container, _, Packet} ->
						   lists:foreach(fun({NGoodsId, N}) ->
												 admin_log_api:log_goods(Player#player.user_id, 0, 0, NGoodsId, N, misc:seconds())
										 end, NeedGoods),
						   {Player#player{bag = Container}, Packet};
					   {?error, _ErrorCode} ->
						   throw(?error)
				   end;
			   	?true ->
				   throw(?error)
				end,		
%% 			{NGoodsId,Num} = NeedGoods,
%% 			{Player1,Packet1} = 
%% 				case ctn_bag2_api:get_by_id(Player#player.user_id, Player#player.bag, NGoodsId, Num) of
%% 					{?ok, Container, _GoodsList, Packet} ->
%% 						admin_log_api:log_goods(Player#player.user_id,0,0,NGoodsId,Num,misc:seconds()),
%% 						{Player#player{bag = Container}, Packet};
%% 					{?error, _ErrorCode} ->
%% 						throw(?error)
%% 				end,
			Bag = Player1#player.bag,
			{Player3,Packet3} =
			case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
				?false ->
					GoodsList =
					lists:foldl(fun({ExcGoodsId, Bind, Count},Acc)->
										GoodsL = goods_api:make(ExcGoodsId, Bind, Count),
										GoodsL++Acc
								end, [], ExcGoodsList),
					case ctn_bag_api:put(Player1, GoodsList, ?CONST_COST_SNOW_GET_AWARD, 1, 1, 0, 0, 0, 1, []) of
						{?ok, Player2, _, Packet2} ->
							exchange_goods_message(Player, ActivityId, ExcGoodsList, ExchangeType, Id),
							TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_EXCHANGE_SUCC),
							{Player2, <<Packet2/binary,TipPacket/binary>>};
						{?error, ErrorCode1} ->
							throw({?error, ErrorCode1})
					end;
				_ -> throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
			end,
			misc_packet:send(Player3#player.user_id,<<Packet1/binary,Packet3/binary>>),
			{?ok,Player3}
	end.
%% 兑换物品发送公告
exchange_goods_message(Player, ActivityId, ExcGoodsList, ExchangeType, Id) ->
	F1 = fun({ExcGoodsId1, Bind, Count1}) ->
				%% 坐骑红色、时装橙色以上进行公告(麋鹿、圣诞时装)
				admin_log_api:log_goods(Player#player.user_id, 1, 0, ExcGoodsId1, Count1, misc:seconds()),
				GetGoods = goods_api:make(ExcGoodsId1, Bind, Count1),
				[GetGoodsInfo] = GetGoods,
				if (GetGoodsInfo#goods.sub_type =:= ?CONST_GOODS_EQUIP_HORSE andalso GetGoodsInfo#goods.color >= ?CONST_SYS_COLOR_RED) ->
					   BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_HORSE_BIG_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],GetGoods, 
															[{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_HORSE_BIG_AWARD)}]),
					   misc_app:broadcast_world_2(BroadPacket);
				   (GetGoodsInfo#goods.sub_type =:= ?CONST_GOODS_EQUIP_FUSION andalso GetGoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE) ->
					   BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_FUSION_BIG_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],GetGoods, 
															[{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_FUSION_BIG_AWARD)}]),
					   misc_app:broadcast_world_2(BroadPacket);
				   ?true ->
					   skip
				end
		end,
	F2 = fun({ExcGoodsId1, Bind, Count1}) ->
				 admin_log_api:log_goods(Player#player.user_id, 1, 0, ExcGoodsId1, Count1, misc:seconds()),
				 GetGoods = goods_api:make(ExcGoodsId1, Bind, Count1),
				 if ExchangeType =:= 3 andalso Id =:= 8 ->%福星高照
						BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_1, [{Player#player.user_id, Player#player.info#info.user_name}], GetGoods,
															 [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_1)}]),
						misc_app:broadcast_world_2(BroadPacket);
					ExchangeType =:= 3 andalso Id =:= 9 ->%金玉满堂
						BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_2, [{Player#player.user_id, Player#player.info#info.user_name}], GetGoods,
															 [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_SPRING_EXCHANGE_AWARD_2)}]),
						misc_app:broadcast_world_2(BroadPacket);
					?true ->
						skip
				 end
		 end,
	if ActivityId =:= ?CONST_YUNYING_ACTIVITY_EXCHANGE ->
		   lists:foreach(F1, ExcGoodsList);
	   ActivityId =:= ?CONST_YUNYING_ACTIVITY_SPRING ->
		   lists:foreach(F2, ExcGoodsList);
	   ?true ->
		   skip
	end.

%%获取宝石合成的信息，宝石合成活动id为14
get_stone_compose(Player) ->
	UserId = Player#player.user_id,
	yunying_activity_api:check_activity_start(14),
	StoneList = 
		case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, UserId) of
			[] ->
				ets_api:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE, #ets_active_stone_compose{user_id=UserId,stone_compose_list=[]}),
				[];
			[StoneInfo] ->
				StoneInfo#ets_active_stone_compose.stone_compose_list
		end,
	StonePacket = yunying_activity_api:msg_sc_stone_info(StoneList),
	misc_packet:send(UserId, StonePacket),
	?ok.

%%领取宝石奖励
get_stone_compose_award(Player,StoneLv) ->
	yunying_activity_api:check_activity_start(14),
	case data_yunying_activity:get_activity_stone_compose(StoneLv) of
		null ->
			throw({error,?TIP_COMMON_BAD_ARG});
		#rec_yunying_activity_stone_compose{award_goods=AwardGoods}->
			UserId = Player#player.user_id,
			case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, UserId) of
				[] ->
					ets:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE, #ets_active_stone_compose{user_id=UserId,stone_compose_list=[]}),
					throw({?error,?TIP_COMMON_NO_GET_AWARD});
				[StoneInfo] ->
					#ets_active_stone_compose{stone_compose_list=StoneList} = StoneInfo,
					case lists:keyfind(StoneLv, 1, StoneList) of
						false ->
							throw({?error,?TIP_COMMON_NO_GET_AWARD});
						{_,Num} ->
							Bag = Player#player.bag,
							case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
								?false ->
									GoodsList = 
										lists:foldl(fun({GoodsId, Bind, Count},Acc) ->
															GoodsListTmp = goods_api:make(GoodsId, Bind, Num*Count),
															GoodsListTmp++Acc
													end, [], AwardGoods),
									case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SNOW_GET_AWARD, 1, 1, 0, 0, 0, 1, []) of
										{?ok, Player2, _, Packet} ->
											lists:foreach(fun({GoodsIdL, _BindL, CountL}) ->
													admin_log_api:log_goods(Player#player.user_id,1,0,GoodsIdL,CountL*Num,misc:seconds())			  
													end, AwardGoods),
											Stone = lists:keydelete(StoneLv, 1, StoneList),
											ets:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE, StoneInfo#ets_active_stone_compose{stone_compose_list=Stone}),
											AwardPacket = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_STONE_AWARD,?MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_AWARD,[StoneLv]),
											NewStoneInfoPacket = yunying_activity_api:msg_sc_stone_info(Stone),
											misc_packet:send(UserId, <<Packet/binary,AwardPacket/binary,NewStoneInfoPacket/binary>>),
											{?ok,Player2};
										{?error, ErrorCode} ->
											throw({?error, ErrorCode})
									end;
								_ -> throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
							end
					end
			end
	end.

%%宝石合成,记录数据
stone_compose_count(Player,StoneLv,Count) ->
	UserId = Player#player.user_id,
	try
		yunying_activity_api:check_activity_start(14),
		case data_yunying_activity:get_activity_stone_compose(StoneLv) of
			null ->
				nil;
			_ ->
				NewStoneInfo =
					case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, UserId) of
						[] ->
							ets:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE, #ets_active_stone_compose{user_id=UserId,stone_compose_list=[{StoneLv,Count}]}),
							[{StoneLv,Count}];
						[StoneInfo] ->
							#ets_active_stone_compose{stone_compose_list=StoneCount} = StoneInfo,
							NewStoneCount = 
								case lists:keyfind(StoneLv, 1, StoneCount) of
									false ->
										lists:append([{StoneLv,Count}], StoneCount);
									{_,Num} ->
										lists:keyreplace(StoneLv, 1, StoneCount, {StoneLv,Num+Count})
								end,
							ets:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE,StoneInfo#ets_active_stone_compose{stone_compose_list=NewStoneCount}),
							NewStoneCount
					end,
				StonePacket = yunying_activity_api:msg_sc_stone_info(NewStoneInfo),
				misc_packet:send(UserId,StonePacket)
		end
	catch
		throw:_ -> ?ok
	end.

stone_compose_mail(Player) ->
	Now = misc:seconds(),
	NewServSec = new_serv_api:get_serv_start_time(),
	case data_welfare:get_deposit_active_time(14) of
		{new_serv, EndSec} 
		  when EndSec =/= 0 andalso NewServSec+EndSec*?CONST_SYS_ONE_DAY_SECONDS < Now  ->
			case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, Player#player.user_id) of
				[] ->
					nil;
				[StoneInfo] ->
					send_stone_award_to_mail(Player,StoneInfo)
			end;	
		{S, EndSec} 
		  when EndSec =/= 0 andalso EndSec < Now andalso S =/= 'new_serv' ->
			case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, Player#player.user_id) of
				[] ->
					nil;
				[StoneInfo] ->
					send_stone_award_to_mail(Player,StoneInfo)
			end;
		_ ->
			nil
	end.

send_stone_award_to_mail(Player,StoneInfo) ->
	UserId = Player#player.user_id,
	#ets_active_stone_compose{stone_compose_list=StoneCount} = StoneInfo,
	AwardGoodsList = 
		lists:foldl(fun({StoneLv,Num},Acc) ->
							case data_yunying_activity:get_activity_stone_compose(StoneLv) of
								null ->
									TipPacket = message_api:msg_notice(?TIP_COMMON_SYS_ERROR),
									misc_packet:send(UserId,TipPacket),
									Acc;
								#rec_yunying_activity_stone_compose{award_goods=AwardGoods} ->
									GoodsList = 
										lists:foldl(fun({GoodsId, Bind, Count},Acc0) ->
															GoodsListTmp = goods_api:make(GoodsId, Bind, Num*Count),
															GoodsListTmp++Acc0
													end, [], AwardGoods),
									GoodsList++Acc
							end
					end, [], StoneCount),
	case AwardGoodsList == [] of
		true ->
			nil;
		false ->
			GoodsIdList	= mail_api:get_goods_id(AwardGoodsList, []),
			Content		= [{GoodsIdList}],
			mail_api:send_interest_mail_to_one2((Player#player.info)#info.user_name, <<>>, <<>>, ?CONST_MAIL_DEPOSIT, Content, 
												AwardGoodsList, 0, 0, 0, ?CONST_COST_MAIL_YUNYING)
	end,
	ets:delete(?CONST_ETS_ACTIVE_STONE_COMPOSE, UserId),
	mysql_api:execute("DELETE FROM `game_activity_stone_compose` WHERE `user_id` = " ++ misc:to_list(UserId) ++ ";"),
	?ok.


%%获取玩家财神祝福值界面信息
%%[FreeTimes] = Gift_got：剩余免费次数
get_bless_info(Player) ->
	case check_activity_open(?CONST_YUNYING_ACTIVITY_BLESS) of
		{true, NewStart, NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}) of
				{_, [FreeTimes], Data, _Time_S, _Time_E} ->
					Packet = yunying_activity_api:msg_sc_bless_info(FreeTimes, Data),
					misc_packet:send(Player#player.user_id, <<Packet/binary>>);
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}, [?BLESS_COMMON_FREE_TIMES], 0, NewStart, NewEnd}),
					Packet = yunying_activity_api:msg_sc_bless_info(?BLESS_COMMON_FREE_TIMES, 0),
					misc_packet:send(Player#player.user_id, <<Packet/binary>>)
			end;
		_ ->
			skip
	end.

%%获得一次财神祝福值
%%Type:1  普通;  Type:2  高级
get_bless_value(Player, Type) ->
	%%先判断是否满足祝福条件
	case check_activity_open(?CONST_YUNYING_ACTIVITY_BLESS) of
		{true, _NewStart, _NewEnd} ->
			BlessValue = get_bless_random_value(Type),
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}) of
				{_, [FreeTimes], Data, _Time_S, _Time_E} ->
					NewFreeTimes = check_bless_money(FreeTimes, Player, Type),
					FinaleBlessValue = Data + BlessValue,
					ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}, [{2, [NewFreeTimes]}, {3, FinaleBlessValue}]),
					Packet = yunying_activity_api:msg_sc_bless_value(BlessValue, FinaleBlessValue, NewFreeTimes);
				_ ->
					Packet = yunying_activity_api:msg_sc_bless_value(0, 0, 0)
			end;
		_ ->
			Packet = yunying_activity_api:msg_sc_bless_value(0, 0, 0)
	end,
	misc_packet:send(Player#player.user_id, <<Packet/binary>>).
get_bless_random_value(Type) ->
	if Type =:= 2 ->
		   misc_random:random(10, 95);
	   ?true ->
		   misc_random:random(1, 20)
	end.
check_bless_money(FreeTimes, Player, Type) ->
	if Type =:= 1 ->
		   if FreeTimes > 0 ->
				  FreeTimes - 1;
			  ?true ->
				  case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, ?BLESS_LOW_NEED_YUANBAO, ?CONST_COST_BLESS_GET_AWARD) of
					  ?ok ->
						  FreeTimes;
					  _ ->
						  throw(?error)
				  end
		   end;
	   Type =:= 2 ->
		   case player_money_api:minus_money(Player#player.user_id, ?CONST_SYS_CASH, ?BLESS_HIGH_NEED_YUANBAO, ?CONST_COST_BLESS_GET_AWARD) of
			   ?ok ->
				   FreeTimes;
			   _ ->
				   throw(?error)
		   end;
	   ?true ->
		   throw({?error, ?TIP_COMMON_BAD_ARG})
	end.

%%祝福值兑换物品
%%通过Id，从data_yunying_activity获取数据；
%%Type为兑换类型
bless_exchange_goods(Player, Type, Id) ->
	get_value_exchange_goods(Player, ?CONST_YUNYING_ACTIVITY_BLESS, Type, Id).

%% 积分兑换物品
get_value_exchange_goods(Player, ActiveType, ExchangeType, Id) ->
	case check_value_exchange_goods(Player, ActiveType) of
		{?true, Data} ->
			case data_yunying_activity:get_yunying_activity_exchange(Id) of
				null ->
					throw({?error,?TIP_COMMON_BAD_ARG});
				#rec_yunying_activity_exchange{type=Type1,need_goods=NeedGoods,exchange_goods=ExcGoodsList} ->
					if ExchangeType =/= Type1 ->
						   throw({?error,?TIP_COMMON_BAD_ARG});
					   ?true ->
						   [{_, NeedBlessValue}] = NeedGoods,
						   if NeedBlessValue > Data ->
								  throw({?error, ?TIP_COMMON_BAD_ARG});
							  ?true ->
								  {?ok, NewPlayer} = get_value_exchange_goods_1(Player, ActiveType, ExcGoodsList),
								  NewBlessValue = Data - NeedBlessValue,
								  ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {NewPlayer#player.user_id, ActiveType}, [{3, NewBlessValue}]),
								  if ActiveType =:= ?CONST_YUNYING_ACTIVITY_BLESS ->
										 Packet = yunying_activity_api:msg_sc_bless_exchange_goods_info(NewBlessValue),
										 misc_packet:send(NewPlayer#player.user_id, Packet);
									 ActiveType =:= ?CONST_YUNYING_ACTIVITY_STONE_VALUE ->
										 Packet = yunying_activity_api:msg_sc_stone_value_info(NewBlessValue),
										 misc_packet:send(NewPlayer#player.user_id, Packet);
									 ?true ->
										 skip
								  end,
								  {?ok, NewPlayer}
						   end
					end;
				_ ->
					throw(?error)
			end;
		_ ->
			throw(?error)
	end.
check_value_exchange_goods(Player, ActiveType) ->
	case check_activity_open(ActiveType) of
		{true, _NewStart, _NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ActiveType}) of
				{_, _, Data, Time_S, Time_E} ->
					Now = misc:seconds(),
					case Now >= Time_S andalso Now =< Time_E of
						true ->
							{?true, Data};
						_ ->
							?false
					end;
				_ ->
					?false
			end;
		_ ->
			?false
	end.
get_value_exchange_goods_1(Player, ActiveType, ExcGoodsList) ->
	Bag = Player#player.bag,
	{Player2,Packet3} = case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
								?false ->
									FMake = fun({ExcGoodsId, Bind, Count}, Acc) ->
													GoodsL = goods_api:make(ExcGoodsId, Bind, Count),
													GoodsL ++ Acc
											end,
									GoodsList = lists:foldl(FMake, [], ExcGoodsList),
									case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_BLESS_GET_AWARD, 1, 1, 0, 0, 0, 1, []) of
										{?ok, Player1, _, Packet2} ->
											value_exchange_goods_message(ActiveType, ExcGoodsList, Player), %% 广播公告
											TipPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_EXCHANGE_SUCC),
											{Player1, <<Packet2/binary, TipPacket/binary>>};
										{?error, ErrorCode1} ->
											throw({?error, ErrorCode1})
									end;
							_ ->
								throw({?error, ?TIP_COMMON_BAG_NOT_ENOUGH})
						end,
	misc_packet:send(Player2#player.user_id, <<Packet3/binary>>),
	{?ok, Player2}.
%% 兑换物品广播公告
value_exchange_goods_message(ActiveType, ExcGoodsList, Player) ->
	F1 = fun({ExcGoodsId1, Bind, Count1}) ->
				admin_log_api:log_goods(Player#player.user_id, 1, 0, ExcGoodsId1, Count1, misc:seconds()),
				GetGoods = goods_api:make(ExcGoodsId1, Bind, Count1),
				[GetGoodsInfo] = GetGoods,
				if GetGoodsInfo#goods.sub_type =:= ?CONST_GOODS_FUNC_PARTNER -> %% 武将
						PartnerID = GetGoodsInfo#goods.exts#g_func.effect_id,
						BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_BLESS_AWARD_1, [{Player#player.user_id, (Player#player.info)#info.user_name}],
															 [], [{?TIP_SYS_PARTNER, misc:to_list(PartnerID)}, {?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_BLESS_AWARD_1)}]),
						misc_app:broadcast_world_2(BroadPacket);
				   GetGoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE andalso GetGoodsInfo#goods.type =:= ?CONST_GOODS_TYPE_EQUIP -> %%橙色或橙色以上装备
						BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_BLESS_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],
															 GetGoods, [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_BLESS_AWARD)}]),
						misc_app:broadcast_world_2(BroadPacket);
				   GetGoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE ->
					   BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_BLESS_AWARD_2, [{Player#player.user_id, (Player#player.info)#info.user_name}],
															GetGoods, [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_BLESS_AWARD_2)}]),
					   misc_app:broadcast_world_2(BroadPacket);
				   ?true ->
					   skip
				end
		end,
	F2 = fun({ExcGoodsId1, Bind, Count1}) ->
				 admin_log_api:log_goods(Player#player.user_id, 1, 0, ExcGoodsId1, Count1, misc:seconds()),
				 GetGoods = goods_api:make(ExcGoodsId1, Bind, Count1),
				 [GetGoodsInfo] = GetGoods,
				 if GetGoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE ->
						BroadPacket = message_api:msg_notice(?TIP_YUNYING_ACTIVITY_STONE_EXCHANGE_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}], 
															 GetGoods, [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_YUNYING_ACTIVITY_STONE_EXCHANGE_AWARD)}]),
						misc_app:broadcast_world_2(BroadPacket);
					?true ->
						skip
				 end
		 end,
	if ActiveType =:= ?CONST_YUNYING_ACTIVITY_BLESS ->
		   lists:foreach(F1, ExcGoodsList);%% 财神祝福兑换要进行广播 
	   ActiveType =:= ?CONST_YUNYING_ACTIVITY_STONE_VALUE ->
		   lists:foreach(F2, ExcGoodsList);%% 宝石积分兑换要进行广播
	   ?true ->
			skip
	end.

%% 0点刷新财神祝福免费次数
bless_refresh(Player) ->
	case check_activity_open(?CONST_YUNYING_ACTIVITY_BLESS) of
		{true, NewStart, NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}) of
				{_, _, Data, Time_S, Time_E} ->
					Now = misc:seconds(),
					case Now >= Time_S andalso Now =< Time_E of
						?true ->
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}, [{2, [?BLESS_COMMON_FREE_TIMES]}]);
						_ ->
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}, [{2, [?BLESS_COMMON_FREE_TIMES]}, {4, NewStart}, {5, NewEnd}])
					end,
					Packet = yunying_activity_api:msg_sc_bless_info(?BLESS_COMMON_FREE_TIMES, Data);
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS}, [?BLESS_COMMON_FREE_TIMES], 0, NewStart, NewEnd}),
					Packet = yunying_activity_api:msg_sc_bless_info(?BLESS_COMMON_FREE_TIMES, 0)
			end,
			misc_packet:send(Player#player.user_id, <<Packet/binary>>);
		_ ->
			ets_api:delete(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_BLESS})
	end.

%% 宝石合成/购买添加积分活动
%%type:1 购买；type:2 合成
add_activity_stone_value(UserId, StoneLevel, Num, Type) ->
	case check_activity_open(?CONST_YUNYING_ACTIVITY_STONE_VALUE) of
		{true, NewStart, NewEnd} ->
			AddValue = get_stone_value(StoneLevel, Type),
			FinalAddValue = AddValue * Num,
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_STONE_VALUE}) of
				{_, _, Data, _Time_S, _Time_E} ->
					ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {UserId, ?CONST_YUNYING_ACTIVITY_STONE_VALUE}, [{3, Data + FinalAddValue}]),
					Packet = yunying_activity_api:msg_sc_stone_value_info(Data + FinalAddValue),
					misc_packet:send(UserId, <<Packet/binary>>);
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{UserId, ?CONST_YUNYING_ACTIVITY_STONE_VALUE}, [], FinalAddValue, NewStart, NewEnd}),
					Packet = yunying_activity_api:msg_sc_stone_value_info(FinalAddValue),
					misc_packet:send(UserId, <<Packet/binary>>)
			end;
		_ ->
			skip
	end.
get_stone_value(StoneLevel, Type) ->
	case data_yunying_activity:get_stone_value({StoneLevel, Type}) of
		?null ->
			throw({?error,?TIP_COMMON_BAD_ARG});
		#rec_yunying_activity_stone_value{add_value = AddValue} ->
			AddValue
	end.

%% 获取玩家宝石积分信息
get_stone_value_info(Player) ->
	case check_activity_open(?CONST_YUNYING_ACTIVITY_STONE_VALUE) of
		{true, NewStart, NewEnd} ->
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id, ?CONST_YUNYING_ACTIVITY_STONE_VALUE}) of
				{_, _, Data, _Time_S, _Time_E} ->
					Packet = yunying_activity_api:msg_sc_stone_value_info(Data),
					misc_packet:send(Player#player.user_id, <<Packet/binary>>);
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id, ?CONST_YUNYING_ACTIVITY_STONE_VALUE}, [], 0, NewStart, NewEnd}),
					Packet = yunying_activity_api:msg_sc_stone_value_info(0),
					misc_packet:send(Player#player.user_id, <<Packet/binary>>)
			end;
		_ ->
			skip
	end.

%% 宝石积分兑换物品
%%通过Id，从data_yunying_activity获取数据；
%%Type为兑换类型
get_stone_value_exchange_goods(Player, Type, Id) ->
	get_value_exchange_goods(Player, ?CONST_YUNYING_ACTIVITY_STONE_VALUE, Type, Id).