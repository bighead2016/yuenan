%% @author zane
%% @doc @todo Add description to yunying_activity_api.
-module(yunying_activity_api).

-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.goods.data.hrl").
-include("../../include/record.base.data.hrl").



%% ====================================================================
%% API functions
%% ====================================================================
-export([activity_data_save/0,msg_sc_activity_info/1,get_mail_info2/2,
		 init_yunying_activity_after_login/1,
		 init_activity_online_award/1,logout_activity_online_time/1,msg_sc_shuangdan_info/2,
		 msg_sc_shuangdan_get_award/2,init_stone_compose_ets/0,check_activity_start/1,
		 msg_sc_stone_info/1,init_shuangdan_login/1,activity_read_db_login/1,activity_write_db_logout/1,
		 msg_sc_card_lottery_result/1,msg_sc_last_card_lottery_info/1,msg_sc_partner_exchange_info/2,
		 msg_sc_bless_info/2, msg_sc_bless_value/3,msg_sc_stone_value_info/1,msg_sc_bless_exchange_goods_info/1]).

-export([login_packet/2,update_code/0,update_code/1]).


update_code(ModuleList) ->
	Fun = fun(Arg,InfoList) ->
		code:purge(Arg),
		case code:load_file(Arg) of
			{module,Module} ->
				InfoList++[Module];
			Else ->
				InfoList++[{Arg,Else}]
		end
	end,
	ResultList = lists:foldl(Fun,[],ModuleList),
	misc_sys:make_config(),
	ResultList++[config].

update_code() ->
	Fun = fun(Arg) ->
		code:purge(Arg),
		code:load_file(Arg)
	end,
	lists:map(Fun,[data_yunying_activity,yunying_activity_api,yunying_activity_mod,data_welfare,player_money_api]).


login_packet(Player, AccPacket) ->
	Fun = fun(Type,Acc) ->
		case yunying_activity_mod:check_activity_open(Type) of
			{true,NewStart,NewEnd} ->
				Acc++[{Type,NewStart,NewEnd}];
			{false,NewStart,NewEnd} ->
				Acc++[{Type,NewStart,NewEnd}];
			_ ->
				Acc++[{Type,0,0}]
		end
	end,
	List = lists:foldl(Fun,[],lists:seq(1,27)++[1001,1002,1003]),
	NewServSec = new_serv_api:get_serv_start_time(),
	Fun2 = fun(Type,Acc) ->
		Ret = 
		try data_welfare:get_deposit_active_time(Type)
		catch _:_ ->
			none
		end,
		Add =
		case Ret of
			null ->
				[];
			none ->
				[];
			{new_serv, EndSec} ->
				[{Type,NewServSec,NewServSec+EndSec*?CONST_SYS_ONE_DAY_SECONDS}];
			{new_serv, StartSec, EndSec} ->
				{STime,ETime} = get_welfare_time(StartSec,EndSec),
				[{Type,STime,ETime}];
			{S, EndSec} ->
			  [{Type,S,EndSec}];
			_->
			  [{Type,0,0}]
		end,
		Acc ++ Add
	end,

	List2 = lists:foldl(Fun2,[],lists:seq(10,50)),

	PacketAdd       = misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_TIME_INFO, ?MSG_FORMAT_YUNYING_ACTIVITY_TIME_INFO, [List,List2]),
	NewPacket       = <<AccPacket/binary, PacketAdd/binary>>,
	{Player, NewPacket}.



get_welfare_time(NewServ,NewServEnd) ->
	ServerStart = new_serv_api:get_serv_start_time(),
	ServerStartDay = (ServerStart+8*3600) div 86400,
	Start1 = (ServerStartDay + NewServ)*86400 - 8*3600,
	End1 = (ServerStartDay + NewServEnd)*86400 - 8*3600,
	{Start1,End1}.



%% ====================================================================
%% Internal functions
%% ====================================================================

%% 玩家上线读数据库写入ets
activity_read_db_login(Player)->
	try
		ResultList = 
			case mysql_api:select([user_id,type,gift_got,data,time_s,time_e], game_active_welfare, [{user_id,Player#player.user_id}]) of
				{?ok,Re}->
					Re;
				_ ->
					[]
			end,
		lists:foreach(
		  fun([UserId,Type,Gift_Got,Data,Time_S,Time_E])->
				  ets_api:insert(?CONST_ETS_ACTIVE_WELFARE,  {{UserId,Type},mysql_api:decode(Gift_Got), Data,Time_S,Time_E})
		  end,ResultList),
		yunying_activity_mod:init_yunying_activity_info(Player)                                       %把运营活动过期的数据清了，双旦活动的不能清这么快
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%玩家下线时把ets中的活动数据写数据库
activity_write_db_logout(Player)->
	try 
		UserId = Player#player.user_id,
		PlayerAllRecord = ets:match_object(?CONST_ETS_ACTIVE_WELFARE, {{UserId,'_'},'_','_','_','_'}),
		lists:foreach(
		  fun({{UserId2,Type},Gift_Got,Data,Time_S,Time_E})->
				  Sql = <<"insert into `game_active_welfare` (`user_id`,`type`,`gift_got`,`data`,`time_s`,`time_e`) values ('",
						  (misc:to_binary(UserId2))/binary, "',' ",
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
				  mysql_api:select(Sql),
				  case Type =/= 3 of
					  true ->
				           ets:delete(?CONST_ETS_ACTIVE_WELFARE, {UserId,Type});
					  false -> % 3是累计充值，考虑离线充值的情况，不能删ets中的数据
						  next
				  end
		  end,PlayerAllRecord)
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.


%%停服时运营活动写数据库
activity_data_save()->
	try
		AllList = ets:tab2list(?CONST_ETS_ACTIVE_WELFARE),
		lists:foreach(
		  fun({{UserId,Type},Gift_Got,Data,Time_S,Time_E})->
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
				  mysql_api:select(Sql)
		  end,AllList),
		AllDataList =  ets:tab2list(?CONST_ETS_ACTIVE_STONE_COMPOSE),
		[stone_insert_to_mysql(T)||T<-AllDataList]
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.

%%玩家上线处理活动
init_yunying_activity_after_login(Player) ->
	activity_read_db_login(Player),               %玩家上线初始化运营，双旦活动数据，和下面的调用不能乱顺序
	init_shuangdan_login(Player),                      %双旦活动上线初始化
	init_activity_online_award(Player),          %运营活动在线得奖励，上线时处理

	init_activity_pz_award(Player), 

	init_activity_horse_award(Player),

	init_activity_star_award(Player),

	% init_activity_peiyang_award(Player),

	init_bless_login(Player),                    %财神祝福活动上线初始化
	?ok.

%%双旦活动玩家上线处理（主要是处理零点刷新时，玩家不在线的情况）
init_shuangdan_login(Player)->
    Now =misc:seconds(),
	TimeOff = (Player#player.info)#info.time_last_off,
	case misc:is_same_date(Now, TimeOff) of
		true -> %0点时已经处理
			next;
		false -> %0点不在线的情况，上线时重做0点时的处理
			yunying_activity_mod:shuangdan_refresh_zero(Player)
	end.

%%财神活动玩家上线时初始化处理
init_bless_login(Player) ->
	Now = misc:seconds(),
	TimeOff = (Player#player.info)#info.time_last_off,
	case misc:is_same_date(Now, TimeOff) of
		?true -> %% 已处理
			next;
		?false ->
			yunying_activity_mod:bless_refresh(Player)
	end.

init_activity_pz_award(Player) ->
	CampIdX = tower_api:get_top_pass(Player#player.user_id),
	try 
		yunying_activity_mod:update_activity_info(Player#player.user_id,5,{1,CampIdX})
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end,
	void.


init_activity_horse_award(Player) ->
	HorseData = Player#player.horse,
	HorseTrain = HorseData#horse_data.train,
	NewTrainLv = HorseTrain#horse_train.lv,
	try 
		yunying_activity_mod:update_activity_info(Player#player.user_id,2,{0,NewTrainLv})          %运营活动坐骑培养检测
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.
	

init_activity_star_award(Player) ->
	try
		Info     = Player#player.info,
	    PointNew = Info#info.cultivation,
	    LampNew = PointNew - (PointNew div 11),
	    PlayerId = Player#player.user_id,
		yunying_activity_mod:update_activity_info(PlayerId,6,{0,LampNew})
	catch
		X:Y ->
			?MSG_ERROR("~p|~p~n~p", [X, Y, erlang:get_stacktrace()])
	end.



%%在线得奖励，玩家上线或活动开启时的处理，在线得奖励type = 1
init_activity_online_award(Player)->
	Now =misc:seconds(),
	TimeOff = (Player#player.info)#info.time_last_off,

	case yunying_activity_mod:check_activity_open(1) of
		{true,NewStart,NewEnd} -> %在活动时间内
			ActivityData = data_yunying_activity:get_yunying_activity_data(1),
			AwardList =
				case is_record(ActivityData, rec_yunying_activity_data) of
					true ->
						ActivityData#rec_yunying_activity_data.award_list;
					false ->
						[ ]
				end,
			AwardList2 =lists:keysort(2, AwardList),                                 %按完成条件从小到大排序
			TimePass = calendar:time_to_seconds(misc:time()),
			Time_To_Midnight = 86400 - TimePass,
			erlang:send_after(Time_To_Midnight*1000, self(), {yunying_activity_online_zero}),            %0点刷新
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1}) of
				{_,_,Data,_OldStart,OldEnd}-> %之前有数据
					case misc:is_same_date(Now, TimeOff)andalso Now =<OldEnd of
						true ->  %同一天登录,且上一次的数据还能用
							UnFinished = [Condition||{_,Condition,_}<-AwardList2,Condition*3600 >Data],
							case UnFinished  of
								[FirstCon|_]-> %还有未完成的
									Interval = FirstCon*3600 - Data,
									case  Interval =< Time_To_Midnight of
										true -> %今天还有机会完成
											case get(activity_online_award_timer) of
												true ->
													next;
												_ ->
													erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award}),
													put(activity_online_award_timer,true)               %标志一下，防止重发消息或恶意数据,在活动结束或本日不能再领取时释放
											end;
										_ ->
											next
									end;
								_ ->
									next
							end;
						_ -> %不在同一天登录或上一次数据不能用
							ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1}, [{2,[ ]},{3,0}]),
							case AwardList2  of
								[{_,FirstCon,_}|_]->
									Interval = FirstCon*3600,
									case  Interval =< Time_To_Midnight of
										true ->%今天还有机会完成
											case get(activity_online_award_timer) of
												true ->
													next;
												_ ->
													erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award}),
													put(activity_online_award_timer,true)                                     %标志一下，防止前端重发消息或恶意数据
											end;
										_ ->
											next
									end;
								_ ->
									next
							end
					end,
					ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1}, [{4,NewStart},{5,NewEnd}]);
				_ ->%之前没数据
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,1},[ ],0,NewStart,NewEnd}),
					case AwardList2  of
						[{_,FirstCon,_}|_]->
							Interval = FirstCon*3600,
							case  Interval =< Time_To_Midnight of
								true ->%今天还有机会完成
									case get(activity_online_award_timer) of
										true ->
											next;
										_ ->
											erlang:send_after(erlang:trunc(Interval*1000), self(),{yunying_activity_online_award}),
											put(activity_online_award_timer,true)                                     %标志一下，防止前端重发消息或恶意数据
									end;
								_ ->
									next
							end;
						_ ->
							next
					end
			end;
		_ -> %不在活动期间
			ets_api:delete(?CONST_ETS_ACTIVE_WELFARE,{Player#player.user_id,1}),
			try
				ActivityData = data_yunying_activity:get_yunying_activity_data(1),
				TimeType = ActivityData#rec_yunying_activity_data.time_type,
				Time_Start = ActivityData#rec_yunying_activity_data.time_start,
				Time_End = ActivityData#rec_yunying_activity_data.time_end,
				
				NewServ = ActivityData#rec_yunying_activity_data.new_serv,
				NewServEnd = ActivityData#rec_yunying_activity_data.new_serv_end,


		        ServerStart = new_serv_api:get_serv_start_time(),
		        NowDay = (Now+8*3600) div 86400,            %当前日期
                ServerStartDay = (ServerStart+8*3600) div 86400,      %开服日期
                CanStartDay = ServerStartDay+NewServ,            %开服NewServ天后才可以开活动

                 case TimeType of
		         	0 -> 
		         		Start = misc:date_time_to_stamp(Time_Start),
						End = misc:date_time_to_stamp(Time_End),
				 		StartDay = (Start +8*3600) div 86400,        %配置的活动开启日期
                		EndDay = (End +8*3600) div 86400;        %配置的活动结束日期
				 	1 ->
				 		Start = (ServerStartDay + NewServ)*86400 - 8*3600,
		 				End = (ServerStartDay + NewServEnd)*86400 - 8*3600,
		 				StartDay = (Start +8*3600) div 86400,        %配置的活动开启日期
                		EndDay = (End +8*3600) div 86400
				end,
                case Now < End andalso EndDay >= CanStartDay of
					true ->
						if StartDay < CanStartDay ->
							   Interval = (CanStartDay - NowDay)*86400 - ((Now+8*3600) rem 86400),
                               erlang:send_after(Interval*1000, self(), {yunying_activity_online_start});
						   StartDay >= CanStartDay ->
							   Interval = Start - Now,
							   erlang:send_after(Interval*1000, self(), {yunying_activity_online_start});
						   true ->
							   next
						end;
					false ->
						next
				end
			catch
				_:_ ->
					next
			end
	end.
										  
%%玩家下线的时候处理在线得奖励的数据
logout_activity_online_time(Player)->
	case yunying_activity_mod:check_activity_open(1) of
		{true,NewStart,NewEnd} -> %在活动时间内
			Now =misc:seconds(),
			Login =Player#player.time_login,
			case misc:is_same_date(Now, Login) of
				true ->
					Online1 = Now -Login,
					Online2 = Now -NewStart,
					Online = erlang:min(Online1,Online2);
				false ->
					NowTime = misc:time(),
					Online1 = calendar:time_to_seconds(NowTime),
					Online2 = Now - NewStart,
					Online = erlang:min(Online1,Online2)
			end,
			case ets_api:lookup(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1}) of
				{_,_,Data,_,_}->
					ets_api:update_element(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1}, [{3,Data+Online}]);
				_ ->
					ets_api:insert(?CONST_ETS_ACTIVE_WELFARE, {{Player#player.user_id,1},[ ],Online,NewStart,NewEnd})
			end;
		_ ->
			ets_api:delete(?CONST_ETS_ACTIVE_WELFARE, {Player#player.user_id,1})
	end,
	%%宝石合成——下线写数据库
	logout_stone_compose(Player).

%%向前端发运营活动信息
msg_sc_activity_info( AchieveList )->
	  Data = [{X}||X<-AchieveList],
      misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_AWARD_INFO,?MSG_FORMAT_YUNYING_ACTIVITY_AWARD_INFO,[Data]).

msg_sc_stone_info(StoneList) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_STONE_INFO,?MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_INFO,[StoneList]).


%%向前端发双旦活动信息
msg_sc_shuangdan_info( CanGotList,HasGotList)->
	Data1 = [{X}||X<-CanGotList],
	Data2 = [{X}||X<-HasGotList],
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SD_INFO,?MSG_FORMAT_YUNYING_ACTIVITY_SD_INFO,[Data1,Data2]).

%%双旦领取物品成功返回
msg_sc_shuangdan_get_award(Type,AchieveId)->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_GET_AWARD_SUCC,?MSG_FORMAT_YUNYING_ACTIVITY_GET_AWARD_SUCC,[Type,AchieveId]).

%%抽卡换武将返回最后一次抽卡结果
msg_sc_last_card_lottery_info(CardList)->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_LAST_LOTTERY_INFO,?MSG_FORMAT_YUNYING_ACTIVITY_LAST_LOTTERY_INFO,[CardList]).
%%抽卡换武将返回抽卡结果
msg_sc_card_lottery_result(CardList)->
   misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_LOTTERY_RESULT,?MSG_FORMAT_YUNYING_ACTIVITY_SC_LOTTERY_RESULT,[CardList]).

%% 抽奖收集卡牌换武将——返回界面信息 
msg_sc_partner_exchange_info(CardList,Point) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_EXCHANGE_INFO,?MSG_FORMAT_YUNYING_ACTIVITY_SC_EXCHANGE_INFO, [CardList,Point]).

%% 向前端发送财神祝福信息
msg_sc_bless_info(FreeTimes, BlessValue) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_BLESS_INFO, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_INFO, [FreeTimes, BlessValue]).

%% 向前端发送一次祝福获得的祝福值
msg_sc_bless_value(AddValue, TotalValue, FreeTimes) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_BLESS_VALUE, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_VALUE, [AddValue, TotalValue, FreeTimes]).

%% 向前端发送宝石积分信息
msg_sc_stone_value_info(StoneValue) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_STONE_VALUE_INFO, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_STONE_VALUE_INFO, [StoneValue]).

%% 向前端发送物品兑换信息
%% FinalValue：剩余积分值
msg_sc_bless_exchange_goods_info(FinalValue) ->
	misc_packet:pack(?MSG_ID_YUNYING_ACTIVITY_SC_BLESS_GET_AWARD, ?MSG_FORMAT_YUNYING_ACTIVITY_SC_BLESS_GET_AWARD, [FinalValue]).

%%活动中邮件内容
%%活动中邮件内容, 方便查邮件内容，下面就留着了
%% get_mail_info(Type,Condition)->
%% 	case Type of
%% 		1 ->
%% 			Title = <<"超值好礼——在线奖励">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——在线奖励 活动期间,今日在线达到 <FONT COLOR='#00FF00'>~w</FONT> 小时,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		2 ->
%% 			Title = <<"超值好礼——坐骑培养">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——坐骑培养 活动期间,将坐骑培养到 <FONT COLOR='#00FF00'>~w</FONT> 级,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		3 ->
%% 			Title = <<"超值好礼——充值礼包">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——充值礼包 活动期间,累计充值达到 <FONT COLOR='#00FF00'>~w</FONT> 元宝,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		4 ->
%% 			Title = <<"超值好礼——累计消费">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——累计消费 活动期间,累计消费达到 <FONT COLOR='#00FF00'>~w</FONT> 元宝,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		5 ->
%% 			Title = <<"超值好礼——破阵奖励">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——破阵奖励 活动期间,破阵到第 <FONT COLOR='#00FF00'>~w</FONT> 层,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		6 ->
%% 			Title = <<"超值好礼——祭星提升">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祭星提升 活动期间,点燃到灯盏 <FONT COLOR='#00FF00'>~w</FONT> ,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		7 ->
%% 			Title = <<"超值好礼——宝石合成">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——宝石合成 活动期间,合成了 <FONT COLOR='#00FF00'>~w</FONT> 级宝石,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		8 ->
%% 			Title = <<"超值好礼——武将寻访">>,
%% 				case Condition of
%% 					3 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——武将寻访 活动期间,寻访到 <FONT COLOR='#0000FF'>蓝色</FONT> 武将,获得下面的奖励，请及时领取", [ ]));
%% 					5->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——武将寻访 活动期间,寻访到 <FONT COLOR='#8904B1'>紫色</FONT> 武将,获得下面的奖励，请及时领取", [ ]));
%% 					6->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——武将寻访 活动期间,寻访到 <FONT COLOR='#FE9A2E'>橙色</FONT> 武将,获得下面的奖励，请及时领取", [ ]));
%% 					7 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——武将寻访 活动期间,寻访到 <FONT COLOR='#DF013A'>红色</FONT> 武将,获得下面的奖励，请及时领取", [ ]));
%% 					_ ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——武将寻访 活动期间,寻访到 <FONT COLOR='#298A08'>绿色</FONT> 武将,获得下面的奖励，请及时领取", [ ]))
%% 				end,	
%% 			{Title,Content};
%% 		9 ->
%% 			Title = <<"超值好礼——奇门升级">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——奇门升级 活动期间,升到 <FONT COLOR='#00FF00'>~w</FONT> 级,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		10 ->
%% 			Title = <<"超值好礼——人物培养">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——人物培养 活动期间,将人物培养到 <FONT COLOR='#00FF00'>~w</FONT> 级,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		11->
%% 			Title = <<"超值好礼——祈天星斗">>,
%% 				case Condition of
%% 					3 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祈天星斗 活动期间,获得 <FONT COLOR='#0000FF'>蓝色</FONT> 星斗,获得下面的奖励，请及时领取", []));
%% 					5->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祈天星斗 活动期间,获得 <FONT COLOR='#8904B1'>紫色</FONT> 星斗,获得下面的奖励，请及时领取", []));
%% 					6->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祈天星斗 活动期间,获得 <FONT COLOR='#FE9A2E'>橙色</FONT> 星斗,获得下面的奖励，请及时领取", []));
%% 					7 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祈天星斗 活动期间,获得 <FONT COLOR='#DF013A'>红色</FONT> 星斗,获得下面的奖励，请及时领取", []));
%% 					_ ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——祈天星斗 活动期间,获得 <FONT COLOR='#298A08'>绿色</FONT> 星斗,获得下面的奖励，请及时领取", []))
%% 				end,
%% 			{Title,Content};
%% 		12 ->
%% 			Title = <<"超值好礼——时装合成">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——时装合成 活动期间,将时装合成到 <FONT COLOR='#00FF00'>~w</FONT> 级,获得下面的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		13 ->
%% 			Title = <<"情暖寒冬——商路运送">>,
%% 				case Condition of
%% 					2 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——商路运送 活动期间,运送商品 <FONT COLOR='#0000FF'>茶叶</FONT> ,获得下面的奖励，请及时领取", [ ]));
%% 					3->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——商路运送 活动期间,运送商品 <FONT COLOR='#8904B1'>漆器</FONT> ,获得下面的奖励，请及时领取", [ ]));
%% 					4->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——商路运送 活动期间,运送商品 <FONT COLOR='#FE9A2E'>丝绸</FONT> ,获得下面的奖励，请及时领取", [ ]));
%% 					5 ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——商路运送 活动期间,运送商品 <FONT COLOR='#DF013A'>珠宝</FONT> ,获得下面的奖励，请及时领取", [ ]));
%% 					_ ->
%% 						Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——商路运送 活动期间,运送商品 <FONT COLOR='#298A08'>稻米</FONT> ,获得下面的奖励，请及时领取", [ ]))
%% 				end,
%% 			{Title,Content};
%% 		14 ->
%% 			Title = <<"超值好礼——重复消费">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 超值好礼——重复消费  <FONT COLOR='#00FF00'>~w</FONT> 元宝的活动期间,本次操作共获得了以下的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		15 ->
%% 			Title = <<"情暖寒冬——单笔充值">>,
%% 			Content = misc:to_binary(io_lib:format("恭喜你在 情暖寒冬——单笔充值  活动期间,获得单笔充值 <FONT COLOR='#00FF00'>~w</FONT> 元宝的奖励，请及时领取", [Condition])),
%% 			{Title,Content};
%% 		_ ->
%% 			{<<"超值好礼">>,<<"这是您在 超值好礼 活动期间获得的奖品，请及时领取">>}
%% 	end.
%% 把邮件信息配表了 -> {mail_msg,content1}
get_mail_info2(Type,Condition)->
    Content = get_content1([Condition]),
    ?MSG_DEBUG("mail Msg, Content(sometimes don't need to use when 
type is 8 or 11 or 13,so have no square bracket):~p~n",[{Type,Condition}]),    
    case Type of
        1 ->
            Title = 3001,
            {Title,Content};
        2 ->
            Title = 3002,
            {Title,Content};
        3 ->
            Title = 3003,
            {Title,Content};
        21 ->
        	Title = 3003,
            {Title,Content};

        22 ->
        	Title = 3003,
            {Title,Content};

        23 ->
        	Title = 3003,
            {Title,Content};
        24 ->
        	Title = 3003,
            {Title,Content};
         25 ->
        	Title = 3003,
            {Title,Content};
         26 ->
        	Title = 3003,
            {Title,Content};
         27 ->
        	Title = 3003,
            {Title,Content};
        4 ->
            Title = 3004,
            {Title,Content};
        5 ->
            Title = 3005,
            {Title,Content};
        6 ->
            Title = 3006,
            {Title,Content}; 
        7 ->
            Title = 3007,
            {Title,Content}; 
        8 ->
            Title = 
                case Condition of
                    3 ->
                        3008;
                    5->
                        3009;
                    6->
                        3010;
                    7 ->
                        3011;
                    _ ->
                        3012
                end,    
            {Title,[]};
        9 ->
            Title = 3013,
            {Title,Content};
        10 ->
            Title = 3014,
            {Title,Content};
        11->
            Title = 
                case Condition of
                    3 ->
                        3015;
                    5->
                        3016;
                    6->
                        3017;
                    7 ->
                        3018;
                    _ ->
                        3019
                end,
            {Title,Content};
        12 ->
            Title = 3020,
            {Title,Content};
        13 ->
            Title =  
                case Condition of
                    2 ->
                        3021;
                    3->
                        3022;
                    4->
                        3023;
                    5 ->
                        3024;
                    _ ->
                        3025
                end,
            {Title,Content};
        14 ->
            Title = 3026,
            {Title,Content};
        15 ->
            Title = 3027,
            {Title,Content};
        _ ->
            {3028, []}
    end.

%% input ->list
get_content1(C) ->
    get_content1(C,[]).
get_content1([],Acc) ->
    Acc;
get_content1([C|Tail],Acc) ->
    C2 = if is_float(C) ->
                misc:to_binary(io_lib:format("~.1f", [C]));
            ?true ->
                misc:to_list(C)
         end,
    ?MSG_DEBUG("Formatted content:~p~n",[C2]),
    get_content1(Tail, [{[{C2}]}]++Acc).

%初始化宝石合成
init_stone_compose_ets() ->
	try 
		check_activity_start(14),
		case mysql_api:select(<<"select `user_id`, `stone_compose_list` from `game_activity_stone_compose`;">>) of
			{?ok, [?undefined]} -> ?ok;
			{?ok, DataList} ->
				Fun = fun([UserId,StoneCountList]) ->
							  ets_api:insert(?CONST_ETS_ACTIVE_STONE_COMPOSE, #ets_active_stone_compose{user_id=UserId,stone_compose_list=mysql_api:decode(StoneCountList)})
					  end,
				lists:foreach(Fun, DataList);
			_ ->
				?ok
		end
	catch
		throw:{?error,_} ->
			mysql_api:execute(<<"DELETE FROM `game_activity_stone_compose`;">>)
	end.

logout_stone_compose(Player) ->
	try 
		check_activity_start(14),
		case ets:lookup(?CONST_ETS_ACTIVE_STONE_COMPOSE, Player#player.user_id) of
			[] ->
				nil;
			[StoneInfo] ->
				stone_insert_to_mysql(StoneInfo)
		end
	catch
		throw:_Reason ->
			nil
	end.

stone_insert_to_mysql(StoneInfo) ->
	#ets_active_stone_compose{user_id=UserId,stone_compose_list=StoneCountList} = StoneInfo,
	Sql = <<"insert into `game_activity_stone_compose` (`user_id`,`stone_compose_list`) values ('",
						(misc:to_binary(UserId))/binary, "', ",
						(mysql_api:encode(StoneCountList))/binary,")",
			" ON DUPLICATE KEY UPDATE `user_id` = '",(misc:to_binary(UserId))/binary, "', ",
			"`stone_compose_list` =",(mysql_api:encode(StoneCountList))/binary,  ";">>,
	case mysql_api:select(Sql) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.

%%检查是否在活动开启时间内
check_activity_start(GroupId) ->
	Sec = misc:seconds(),
	NewServSec = new_serv_api:get_serv_start_time(),
	case data_welfare:get_deposit_active_time(GroupId) of
		{new_serv, EndSec} 
		  when EndSec =/= 0 andalso Sec =< NewServSec+EndSec*?CONST_SYS_ONE_DAY_SECONDS ->
			?ok;
		{new_serv, StartSec, EndSec} ->
			{STime,ETime} = get_welfare_time(StartSec,EndSec),
			case Sec >= STime andalso Sec =< ETime of
				true ->
					?ok;
				false ->
					throw({?error,?TIP_COMMON_ACTIVITY_NOT_IN_TIME})
			end;
		{S, EndSec} 
		  when EndSec =/= 0 andalso S =<Sec andalso Sec =< EndSec andalso S =/= 'new_serv' ->
			?ok;
		_->
			throw({?error,?TIP_COMMON_ACTIVITY_NOT_IN_TIME})
	end.


	
