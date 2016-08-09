%% @author 
%% @doc @todo Add description to snow_api.


-module(snow_api).

%%
%% Include files
%%
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
-export([save_all/0,check_snow_start_time/0,init_ets/0,logout/1,
		 msg_sc_snow_info/6,msg_notice_goods/2,
		 msg_sc_snow_award/2,msg_sc_snow_store_award/1]).


init_ets() ->
	try 
		check_snow_start_time(),
		case mysql_api:select(<<"select `user_id`, `count`,`level`,`last_level`,`last_pos`,`lighted_list`,`store_list` from `game_snow_info`;">>) of
			{?ok, [?undefined]} -> ok;
			{?ok, DataList} ->
				Fun = fun([UserId,Count,Level,LastLevel,LastPos,LightedList,StoreList], X) ->
							  SnowInfo = #snow_info{user_id=UserId,count=Count,level=Level,last_level=LastLevel,last_pos=LastPos,
													lighted_list=mysql_api:decode(LightedList),store_list=mysql_api:decode(StoreList)},
							  ets_api:insert(?CONST_ETS_SNOW_INFO, SnowInfo),
							  X
					  end,
				lists:foldl(Fun, 0, DataList);
			_ ->
				?ok
		end
	catch
		throw:{?error,_} ->
			mysql_api:execute(<<"DELETE FROM `game_snow_info`;">>)
	end.
msg_sc_snow_info(Count,Level,AwardLevel,AwardPos,LightedList,StoreList) ->
	ChaneLightedList = lists:foldl(fun(Info,Acc)->
										   #snow_lighted_list{level=L,lighted_list=TList} = Info,
										   D=[{T}||T<-TList],
										   [{L,D}] ++ Acc
								   end, [],LightedList),
	ChangStoreList = [{S}||S<-StoreList],
	misc_packet:pack(?MSG_ID_SNOW_SC_GET_INFO,?MSG_FORMAT_SNOW_SC_GET_INFO,[Count,Level,AwardLevel,AwardPos,ChaneLightedList,ChangStoreList]).

msg_sc_snow_award(AwardLevel,AwardPos) ->
	misc_packet:pack(?MSG_ID_SNOW_SC_AWARD,?MSG_FORMAT_SNOW_SC_AWARD,[AwardLevel,AwardPos]).

msg_sc_snow_store_award(Level) ->
	misc_packet:pack(?MSG_ID_SNOW_SC_STORE_AWARD, ?MSG_FORMAT_SNOW_SC_STORE_AWARD,[Level]).

save_all()->
	try 
		check_snow_start_time(),
		Rec = ets:tab2list(?CONST_ETS_SNOW_INFO),
		[snow_insert_to_mysql(T)||T<-Rec]
	catch
		throw:{?error,_} ->
			ets:delete_all_objects(?CONST_ETS_SNOW_INFO),
			mysql_api:execute(<<"DELETE FROM `game_snow_info`;">>)
	end.

check_snow_start_time() ->
	Rec = data_snow:get_snow_goods_list(1),
	StartTime = Rec#rec_snow_goods_list.time_start,
	EndTime = Rec#rec_snow_goods_list.time_end,
	{Year,Mon,Day} = misc:date_tuple(),
	{H,M,S} = misc:time(),
	NowTime = {Year,Mon,Day,H,M,S},
	case NowTime >= StartTime andalso NowTime =< EndTime of
		true ->
			next;
		false ->
			throw({?error,?TIP_SNOW_NOT_OPEN})
	end.

msg_notice_goods([Goods|List], Acc) when is_record(Goods, goods) ->
	GoodsName	= Goods#goods.name,
	GoodsNum	= Goods#goods.count,
	Packet		= message_api:msg_notice(?TIP_PLAYER_VIP_GOODS, [{?TIP_SYS_COMM, GoodsName}, {?TIP_SYS_COMM, misc:to_list(GoodsNum)}]),
	NewAcc		= <<Packet/binary, Acc/binary>>,
	msg_notice_goods(List, NewAcc);
msg_notice_goods([], Acc) ->
	Acc.

logout(UserId) ->
	try 
		snow_api:check_snow_start_time(),
		case ets:lookup(?CONST_ETS_SNOW_INFO, UserId) of
			[] ->
				nil;
			[SnowInfo] ->
				snow_insert_to_mysql(SnowInfo)
		end
	catch
		throw:_Reason ->
			nil
	end.
%% ====================================================================
%% Internal functions
%% ====================================================================

snow_insert_to_mysql(SnowInfo) when is_record(SnowInfo,snow_info)->
	#snow_info{user_id=UserId,count=Count,level=Level,last_level=LastLevel,last_pos=LastPos,lighted_list=LightedList,store_list=StoreList} = SnowInfo,
	Sql = <<"insert into `game_snow_info` (`user_id`,`count`,`level`,`last_level`,`last_pos`,`lighted_list`,`store_list`) values ('",
						(misc:to_binary(UserId))/binary, "',' ",
						(misc:to_binary(Count))/binary, "',' ",
						(misc:to_binary(Level))/binary, "',' ",
						(misc:to_binary(LastLevel))/binary, "',' ",
						(misc:to_binary(LastPos))/binary, "',",
						(mysql_api:encode(LightedList))/binary, ", ",
						(mysql_api:encode(StoreList))/binary,")",
			" ON DUPLICATE KEY UPDATE `user_id` = '",(misc:to_binary(UserId))/binary, "', ",
			"`count` = '",(misc:to_binary(Count))/binary, "', ",
			"`level` = '",(misc:to_binary(Level))/binary, "', ",
			"`last_level` = '",(misc:to_binary(LastLevel))/binary, "', ",
			"`last_pos` = '",(misc:to_binary(LastPos))/binary, "', ",
			"`lighted_list` =",(mysql_api:encode(LightedList))/binary, ", ",
			"`store_list` =",(mysql_api:encode(StoreList))/binary,  ";">>,
	case mysql_api:select(Sql) of
        {?ok, _, _} ->
            ?ok;
        X ->
            ?MSG_ERROR("~p~n~p~n",[X, erlang:get_stacktrace()]),
            {?error, ?TIP_COMMON_SYS_ERROR}
    end.
