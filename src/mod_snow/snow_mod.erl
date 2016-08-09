%% @author 
%% @doc @todo Add description to snow_mod.


-module(snow_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/const.protocol.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/const.cost.hrl").
-include("../../include/record.goods.data.hrl").
%% ====================================================================
%% API functions
%% ====================================================================
-export([get_snow_info/1,get_light_pos/1,change_pos_list/5,
		 click_award/1,
		 click_onekey_award/1,get_store_award/2,
		 click_onekey_one/1,click_onekey_award_one/5]).

%%获取界面信息
get_snow_info(Player) ->
	snow_api:check_snow_start_time(),
	UserId = Player#player.user_id,
	{Count,Level,LastLevel,LastPos,Lighted,Store} =
		case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
			[] ->
				ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
				{0,1,0,0,[],[]};
			[SnowInfo] ->
				#snow_info{count=Count1,level=Level1,last_level=LastLevel1,last_pos=LastPos1,lighted_list=LightedList1,store_list=StoreList1}=SnowInfo,
				{Count1,Level1,LastLevel1,LastPos1,LightedList1,StoreList1}
		end,
	
	SnowInfoPacket = snow_api:msg_sc_snow_info(trunc(Count/?CONST_SNOW_TICKET_PER),Level,LastLevel,LastPos,Lighted,Store),
	misc_packet:send(UserId, SnowInfoPacket),
	?ok.

%%点灯
click_award(Player) ->
	snow_api:check_snow_start_time(),
	UserId = Player#player.user_id,
	SnowInfo = 
		case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
			[] ->
				ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
				#snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]};
			[GetSnowInfo] ->
				GetSnowInfo
		end,
	#snow_info{count=Count,level=Level,lighted_list=LightedList,store_list=StoreList}=SnowInfo,
	Rec= data_snow:get_snow_goods_list(Level),
	NeedCount = Rec#rec_snow_goods_list.need_count,
	case trunc(Count/?CONST_SNOW_TICKET_PER) < NeedCount of
		true ->
			throw({?error,?TIP_SNOW_COUNT_NOT_ENOUGH});
		false ->
			next
	end,
	{LightPos,GoodsId,Bind,Num} = get_light_pos(Level),
	{Player2,MailGoods1,Packet} = 
		case put_goods_to_bag(Player, GoodsId, Bind, Num) of
			{?ok, PlayerTmp, PacketTmp} ->
%% 				admin_log_api:log_goods(UserId,1,0,GoodsId,Num,misc:seconds()),
				{PlayerTmp,[],PacketTmp};
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
				{Player,[{GoodsId,Bind,Num}],<<>>};
			{?error,ErrorCode} ->
				throw({?error,ErrorCode})
		end,
	NewLevel = 
		if LightPos==1 andalso Level=/=6 -> Level+1;
		   true -> 1
		end,
	
	{NewPlayer,MailGoods2,NewLightedList,NewStoreList,StorePacket} = change_pos_list(Player2,Level,LightPos,LightedList,StoreList),
	%%将所有发送邮件的物品一起发送
	case MailGoods1 =:= [] andalso MailGoods2 =:= [] of
		false ->
			MailGoods = lists:foldl(fun({GoodsIdTTTTT, BindTTTTT, CountTTTTT},Acc)->
											goods_api:make(GoodsIdTTTTT, BindTTTTT, CountTTTTT)++Acc
									end, [], MailGoods1++MailGoods2),
			GoodsIdList	= mail_api:get_goods_id(MailGoods, []),
			Content1		= [{GoodsIdList}],
			mail_api:send_interest_mail_to_one2((Player#player.info)#info.user_name, <<>>, <<>>,?CONST_MAIL_SNOW_BAG_FULL, Content1, MailGoods, 0, 0, 0, ?CONST_COST_SNOW_GET_AWARD);
		true ->
			nil
	end,
	GoodsInfo = goods_api:goods(GoodsId),
	GoodsName	= GoodsInfo#goods.name,
	TipPacket = message_api:msg_notice(?TIP_SNOW_GET_GOODS,  [{?TIP_SYS_COMM, GoodsName},{?TIP_SYS_COMM, misc:to_list(Num)}]),
	case GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE of
		true ->
			Goods = goods_api:make(GoodsId, 1),
			BroadPacket = 
				case GoodsInfo#goods.type =:= ?CONST_GOODS_TYPE_EQUIP of
					false ->
						message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods, 
											   [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD)}]);
					true ->
						message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD2, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods, 
											   [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD2)}])
				end,
			misc_app:broadcast_world_2(BroadPacket);
		false ->
			nil
	end,
	admin_log_api:log_snow(UserId, 1, 2),
	ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=Count-NeedCount*?CONST_SNOW_TICKET_PER,level=NewLevel,last_level=Level,last_pos=LightPos,lighted_list=NewLightedList,store_list=NewStoreList}),
	SnowAwardPacket = snow_api:msg_sc_snow_award(Level,LightPos),
	CurrentCount = trunc(Count/?CONST_SNOW_TICKET_PER-NeedCount),
	SnowInfoPacket = snow_api:msg_sc_snow_info(CurrentCount,NewLevel,Level,LightPos,NewLightedList,NewStoreList),
	misc_packet:send(UserId, <<Packet/binary,StorePacket/binary,TipPacket/binary,SnowAwardPacket/binary,SnowInfoPacket/binary>>),
	{?ok, NewPlayer}.

%%一键点灯
click_onekey_award(Player) ->
	try
		click_onekey_one(Player)
	catch
		throw:{?error,ErrorCode,NewPlayer,MailGoodsList,GoodsList,BroadList,SelfPacket}->
			UserName  = (Player#player.info)#info.user_name,
			case MailGoodsList==[] of
				true ->
					nil;
				false ->
					MailGoods = lists:foldl(fun({GoodsId, Bind, Count},Acc)->
													goods_api:make(GoodsId, Bind, Count)++Acc
											end, [], MailGoodsList),
					%%物品超过5个，分开发送
					GoodsIdList	= mail_api:get_goods_id(MailGoods, []),
					Content1		= [{GoodsIdList}],
					mail_api:send_interest_mail_to_one2(UserName, <<>>, <<>>,?CONST_MAIL_SNOW_BAG_FULL, Content1, MailGoods, 0, 0, 0, ?CONST_COST_SNOW_GET_AWARD)
			end,
			SnowInfo = 
				case ets:lookup(?CONST_ETS_SNOW_INFO, Player#player.user_id) of
					[] ->
						ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=Player#player.user_id,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
						#snow_info{user_id=Player#player.user_id,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]};
					[GetSnowInfo] ->
						GetSnowInfo
				end,
			#snow_info{count=Count,level=Level,last_level=LastLevel,last_pos=LastPos,lighted_list=LightedList,store_list=StoreList}=SnowInfo,
			SnowInfoPacket = snow_api:msg_sc_snow_info(trunc(Count/?CONST_SNOW_TICKET_PER),Level,LastLevel,LastPos,LightedList,StoreList),
			
			GoodsPacket = 
				lists:foldl(fun({GoodsId,Num},Acc)->
									GoodsInfo = goods_api:goods(GoodsId),
									GoodsName	= GoodsInfo#goods.name,
									OneGoodsPacket = message_api:msg_notice(?TIP_SNOW_GET_GOODS,  [{?TIP_SYS_COMM, GoodsName},{?TIP_SYS_COMM, misc:to_list(Num)}]),
									<<OneGoodsPacket/binary,Acc/binary>>end,<<>>,GoodsList),
			BroadPacket = lists:foldl(fun(GoodsId,Acc)->
											  Goods = goods_api:make(GoodsId,1),
											  [GoodsInfo] = Goods,
											  BPacket = 
												  case GoodsInfo#goods.type =:= ?CONST_GOODS_TYPE_EQUIP of
													  false ->
														  message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods, 
																				 [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD)}]);
													  true ->
														  message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD2, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods, 
																				 [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD2)}])
												  end,								  
											  <<BPacket/binary,Acc/binary>>
									  end, <<>>, BroadList),
			misc_packet:send(Player#player.user_id, <<GoodsPacket/binary,SelfPacket/binary,SnowInfoPacket/binary>>),
			misc_app:broadcast_world_2(BroadPacket),
			case GoodsList == [] of
				true ->
					TipsPacket = message_api:msg_notice(ErrorCode),
					misc_packet:send(Player#player.user_id,TipsPacket);
				false ->
					nil
			end,
			{?ok,NewPlayer};
		A:B ->
			?MSG_ERROR("error type:~p, why: ~p, Strace:~p~n ", [A, B, erlang:get_stacktrace()])
	end.
%手动获取收集奖励
get_store_award(Player,Level) ->
	snow_api:check_snow_start_time(),
	UserId = Player#player.user_id,
	SnowInfo = 
		case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
			[] ->
				ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
				#snow_info{user_id=UserId,count=0,level=1,lighted_list=[],store_list=[]};
			[GetSnowInfo] ->
				GetSnowInfo
		end,
	#snow_info{store_list=StoreList}=SnowInfo,
	case lists:member(Level,StoreList) of
		false ->
			throw({?error,?TIP_SNOW_CANNOT_STORE_GET});
		true ->
			{NewPlayer,MailGoods,Packet} = send_store_goods_to_bag(Player,Level),
			case MailGoods of
				[] ->
					nil;
				[{GoodsId, Bind, Num}] ->
					Goods = goods_api:make(GoodsId, Bind, Num),
					mail_api:send_interest_mail_to_one2((Player#player.info)#info.user_name, <<>>, <<>>,?CONST_MAIL_SNOW_BAG_FULL, [{[{misc:to_list(GoodsId)}]}], Goods, 0, 0, 0, ?CONST_COST_SNOW_GET_AWARD)
			end,
			%%收集奖励物品公告
			Rec = data_snow:get_snow_goods_list(Level),
			{GoodsId1, _, _} = Rec#rec_snow_goods_list.goods_list2,
			GoodsInfo = goods_api:goods(GoodsId1),
			case GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE of
				true ->
					Goods1 = goods_api:make(GoodsId1, 1),
					BroadPacket = 
						case GoodsInfo#goods.type =:= ?CONST_GOODS_TYPE_EQUIP of
							false ->
								message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods1, 
													   [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD)}]);
							true ->
								message_api:msg_notice(?TIP_SNOW_GET_BIG_AWARD2, [{Player#player.user_id, (Player#player.info)#info.user_name}],Goods1, 
													   [{?TIP_SYS_OPEN_PANEL, misc:to_list(?TIP_SNOW_GET_BIG_AWARD2)}])
						end,
					misc_app:broadcast_world_2(BroadPacket);
				false ->
					nil
			end,
			NewStoreList = lists:delete(Level, StoreList),
			ets:insert(?CONST_ETS_SNOW_INFO,SnowInfo#snow_info{store_list=NewStoreList}),
			#snow_info{count=Count,level=CurLevel,last_level=LastLevel,last_pos=LastPos,lighted_list=LightedList}=SnowInfo,
			SnowInfoPacket = snow_api:msg_sc_snow_info(trunc(Count/?CONST_SNOW_TICKET_PER),CurLevel,LastLevel,LastPos,LightedList,NewStoreList),
			misc_packet:send(UserId,<<Packet/binary,SnowInfoPacket/binary>>),
			{?ok,NewPlayer}
	end.
				
	
%% ====================================================================
%% Internal functions
%% ====================================================================
click_onekey_one(Player) ->
	click_onekey_award_one(Player,[],[],[],<<>>).

click_onekey_award_one(Player,MailGoodsList,GoodsList,BroadList,Packet) ->
	UserId = Player#player.user_id,
	try 
		snow_api:check_snow_start_time()
	catch
		throw:{?error,ErrorCode} ->
			throw({?error,ErrorCode,Player,MailGoodsList,GoodsList,BroadList,Packet})
	end,
	SnowInfo = 
		case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
			[] ->
				ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]}),
				#snow_info{user_id=UserId,count=0,level=1,last_level=0,last_pos=0,lighted_list=[],store_list=[]};
			[GetSnowInfo] ->
				GetSnowInfo
		end,
	#snow_info{count=Count,level=Level,lighted_list=LightedList,store_list=StoreList}=SnowInfo,
	Rec = data_snow:get_snow_goods_list(Level),
	NeedCount = Rec#rec_snow_goods_list.need_count,
	case trunc(Count/?CONST_SNOW_TICKET_PER) < NeedCount of
		true ->
			throw({?error,?TIP_SNOW_COUNT_NOT_ENOUGH,Player,MailGoodsList,GoodsList,BroadList,Packet});
		false ->
			next
	end,
	{LightPos,GoodsId,Bind,Num} = get_light_pos(Level),
	{Player2,BagPacket,NewMailGoodsList,NewGoodsList} = 
		case put_goods_to_bag(Player, GoodsId, Bind, Num) of
			{?ok, PlayerTmp, PacketTmp} ->
				admin_log_api:log_goods(Player#player.user_id,1,0,GoodsId,Num,misc:seconds()),
				case lists:keyfind(GoodsId, 1, GoodsList) of
					false ->
						{PlayerTmp, PacketTmp, MailGoodsList, GoodsList++[{GoodsId, Num}]};
					{_,CurrentNum} ->
						{PlayerTmp, PacketTmp, MailGoodsList, lists:keyreplace(GoodsId, 1, GoodsList, {GoodsId,CurrentNum+Num})}
				end;
			{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
				%%由于物品都是绑定的，就直接按照绑定来处理了
				TmpMailGoodsList = 
					case lists:keyfind(GoodsId,1,MailGoodsList) of
						false ->
							[{GoodsId,Bind,Num}|MailGoodsList];
						{_,B,GoodsCount} ->
							lists:keyreplace(GoodsId, 1, MailGoodsList, {GoodsId,B,Num+GoodsCount})
					end,
				{Player,<<>>,TmpMailGoodsList,GoodsList};
			{?error,ErrorCode1} ->
				throw({?error,ErrorCode1,Player,MailGoodsList,GoodsList,BroadList,Packet})
		end,
	NewLevel = 
		if LightPos==1 andalso Level=/=6 -> Level+1;
		   true -> 1
		end,
	SnowAwardPacket = snow_api:msg_sc_snow_award(Level,LightPos),
	{NewPlayer,MailGoods,NewLightedList,NewStoreList,StorePacket} = change_pos_list(Player2,Level,LightPos,LightedList,StoreList),
	NewMailGoodsList1 =
		case MailGoods of
			[{Id,B1,N}] ->
				case lists:keyfind(Id,1,NewMailGoodsList) of
						false ->
							[{Id,B1,N}|NewMailGoodsList];
						{_,_,Count1} ->
							lists:keyreplace(GoodsId, 1, NewMailGoodsList, {Id,B1,N+Count1})
					end;
			_ ->
				NewMailGoodsList
		end,
 	GoodsInfo = goods_api:goods(GoodsId),
	NewBroadList = 
		case GoodsInfo#goods.color >= ?CONST_SYS_COLOR_ORANGE of
			true ->
				case lists:member(GoodsId, BroadList) of
					true ->
						BroadList;
					false ->
						BroadList++[GoodsId]
				end;
			false ->
				BroadList
		end,
	admin_log_api:log_snow(UserId, 1, 2),
	ets:insert(?CONST_ETS_SNOW_INFO, #snow_info{user_id=UserId,count=Count-NeedCount*?CONST_SNOW_TICKET_PER,level=NewLevel,last_level=Level,last_pos=LightPos,lighted_list=NewLightedList,store_list=NewStoreList}),
	click_onekey_award_one(NewPlayer,NewMailGoodsList1,NewGoodsList,NewBroadList,<<Packet/binary,BagPacket/binary,SnowAwardPacket/binary,StorePacket/binary>>).
		
	
%% 将单个物品放入背包
put_goods_to_bag(Player, GoodsId, Bind, Num) ->
    Bag = Player#player.bag,
	case ctn_bag2_api:is_full(Bag) of %% 检查背包是否已满
		?false ->		
			GoodsList = goods_api:make(GoodsId, Bind, Num),
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_SNOW_GET_AWARD, 1, 1, 0, 0, 0, 1, []) of
				{?ok, Player2, _, Packet} ->
					{?ok, Player2, Packet};
				{?error, ErrorCode} ->
					{?error, ErrorCode}
			end;
		_ -> {?error, ?TIP_COMMON_BAG_NOT_ENOUGH}
	end.
%获取点灯的位置，物品id，绑定与否，数目
get_light_pos(Level) ->
	RecGoodsList = data_snow:get_snow_goods_list(Level),
	GoodsList = RecGoodsList#rec_snow_goods_list.goods_list,
	TotalRate = lists:foldl(fun(Goods,Acc) ->
									Goods#goods_info.rate+Acc
							end, 0, GoodsList),
	Random = misc_random:random(TotalRate),
	{_,GetGoods} =
		lists:foldl(fun(Goods,{Rate,AwardGoods})->
							if AwardGoods == 0 andalso Goods#goods_info.rate >= Rate  -> {0,Goods};
							   AwardGoods == 0 andalso Goods#goods_info.rate < Rate  ->{Rate-Goods#goods_info.rate,0};
							   true ->
								   {Rate,AwardGoods}
							end
					end, {Random,0}, GoodsList),
	#goods_info{pos=LightPos,goods_id=GoodsId,bind=Bind,num=Num}= GetGoods,
	{LightPos,GoodsId,Bind,Num}.


%%改变位置列表，返回值{Player,MailGoods,LightedList,StoreList,Packet}
change_pos_list(Player,Level,LightPos,LightedList,StoreList) ->
	case lists:keyfind(Level,#snow_lighted_list.level,LightedList) of
		false ->%本层没有点亮的图标
			{Player,[],lists:append([[#snow_lighted_list{level=Level,lighted_list=[LightPos]}],LightedList]),StoreList,<<>>};
		SnowLightedList ->  %有点亮的图标
			#snow_lighted_list{lighted_list=LightList} = SnowLightedList,
			case lists:member(LightPos, LightList) of
				true ->
					{Player,[],LightedList,StoreList,<<>>};
				false ->
					case length(LightList) == 7-Level of  
						false -> %%其余图标中有未被点亮的
							LightListTmp = lists:append([[LightPos],LightList]),
							{Player,[],lists:keyreplace(Level,#snow_lighted_list.level,LightedList,#snow_lighted_list{level=Level,lighted_list=LightListTmp}),StoreList,<<>>};
						true -> %%其余图标均被点亮
							TipPacket = message_api:msg_notice(?TIP_SNOW_STORE_LIGHTED,  [{?TIP_SYS_COMM, misc:to_list(Level)}]),
							case lists:member(Level,StoreList) of
								false ->
									{Player,[],lists:keydelete(Level, #snow_lighted_list.level, LightedList),lists:append([[Level],StoreList]),TipPacket};
								true ->
									{Player1,MailGoods,Packet}=send_store_goods_to_bag(Player,Level),
									{Player1,MailGoods,lists:keydelete(Level, #snow_lighted_list.level, LightedList),StoreList,<<Packet/binary,TipPacket/binary>>}
							end
					end
			end
	end.

%%发送收集奖励到背包或邮件
send_store_goods_to_bag(Player,Level) ->
	Rec = data_snow:get_snow_goods_list(Level),
	{GoodsId, Bind, Num} = Rec#rec_snow_goods_list.goods_list2,
	case put_goods_to_bag(Player, GoodsId, Bind, Num) of
		{?ok, PlayerTmp, PacketTmp} ->
			admin_log_api:log_goods(Player#player.user_id,1,0,GoodsId,Num,misc:seconds()),
			GoodsInfo = goods_api:goods(GoodsId),
			GoodsName	= GoodsInfo#goods.name,
			TipPacket = message_api:msg_notice(?TIP_SNOW_GET_GOODS,  [{?TIP_SYS_COMM, GoodsName},{?TIP_SYS_COMM, misc:to_list(Num)}]),
			StorePacket = snow_api:msg_sc_snow_store_award(Level),
			{PlayerTmp,[],<<PacketTmp/binary,TipPacket/binary,StorePacket/binary>>};
		{?error, ?TIP_COMMON_BAG_NOT_ENOUGH} ->
			StorePacket = snow_api:msg_sc_snow_store_award(Level),
			{Player,[{GoodsId, Bind, Num}],StorePacket};
		{?error,ErrorCode} ->
			throw({?error,ErrorCode})
	end.



