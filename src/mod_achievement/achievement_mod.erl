%% Author: Administrator
%% Created: 2012-7-13
%% Description: TODO: Add description to achievement_mod
-module(achievement_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.player.hrl").
-include("const.define.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-include("record.goods.data.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

%%
%% Exported Functions
%%
-export([init_player_achievement/0, login/1, current_title/1]).
-export([achievement_info/1, add_achievement/4,
		 get_achievement_gift/1, get_achievement_gift/2,
		 delete_title/2, change_title/2, refresh_attr/1,
		 title_list/1]).

%%
%% API Functions
%%
init_player_achievement()	->
	#achievement{
				 data		= [],
				 gifts		= [],
				 times		= [],
				 title_data	= []
				}.

login(Player) when is_record(Player, player)	->
	Achievement		= Player#player.achievement,
	TitleData		= Achievement#achievement.title_data,
	NewTitleData	= TitleData,%%title_data(TitleData, []),
	login(Player, NewTitleData).
login(Player, [_TitleData = #title_data{unique = ?CONST_SYS_FALSE} | TitleDataList]) ->
	login(Player, TitleDataList);
login(Player, [_TitleData = #title_data{id = Id, unique = ?CONST_SYS_TRUE} | TitleDataList]) ->
	UserId	= Player#player.user_id,
	case ets:lookup(?CONST_ETS_UNIQUE_TITLE, Id) of
		[] ->
			ets:insert(?CONST_ETS_UNIQUE_TITLE, {Id, UserId}),
			login(Player, TitleDataList);
		[{Id, UserId} | _] ->
			login(Player, TitleDataList);
		[{Id, _UserId} | _]	->
			{?ok, NewPlayer} = delete_title(Player, Id),
			login(NewPlayer, TitleDataList)
	end;
login(Player, [])	->	Player.

achievement_info(Player) when is_record(Player, player)	->
	Achievement	= Player#player.achievement,
	Data		= Achievement#achievement.data,
	Array		= [{Id, Time} || #achievement_data{id = Id, flag = ?true, time = Time} <- Data],
	GiftIds		= [{GiftId} || GiftId <- Achievement#achievement.gifts],
	TitleData	= Achievement#achievement.title_data,
	TitleIds	= [{TitleId} || #title_data{id = TitleId, flag = ?true} <- TitleData],
	achievement_api:msg_sc_achievement_info(Player, Array, GiftIds, TitleIds).

current_title(Player) when is_record(Player, player)	->
	Info	= Player#player.info,
	Info#info.current_title.

add_achievement(Player, Type, MatchData, Times) when is_integer(Type)	->
	case data_achievement:get_achievement_list({Type}) of
		?null	->
			{?ok, Player};
		IdList	->
			add_achievement(Player, IdList, MatchData, Times)
	end;
add_achievement(Player, [Id | IdList], MatchData, Times)	->
	Achievement	= Player#player.achievement,
	Data		= Achievement#achievement.data,
	Player1		=
		case lists:keyfind(Id, #achievement_data.id, Data) of
			?false	->
				insert_achievement(Player, Id, MatchData, Times);
			Tuple when is_record(Tuple, achievement_data)	->
				update_achievement(Player, Id, MatchData, Tuple, Times)
		end,
	Player2		= add_title(Player1, MatchData, Id, Times),
%% 	{?ok, Player2}	= get_achievement_gift(Player1),
	add_achievement(Player2, IdList, MatchData, Times);
add_achievement(Player, [], _, _)	->
	{?ok, Player}.


%% 刷新称号
add_title(Player, 0, Id, _Times) ->
	case data_achievement:get_achievement_info(Id) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			TitleId		= RecAchievement#rec_achievement.title_id,
			NeedTimes	= RecAchievement#rec_achievement.times,
			AchieveData	= (Player#player.achievement)#achievement.data,
			DoneTimes = 
				case lists:keyfind(Id, #achievement_data.id, AchieveData) of
					Tuple when is_record(Tuple, achievement_data) ->
						Tuple#achievement_data.times;
					_ ->
						0
				end,
			case DoneTimes >= NeedTimes of
				?true	-> %% 达成成就
					refresh_title(Player, Id, 0, TitleId);
				?false ->
					Player
			end
	end;
add_title(Player, MatchData, Id, _Times) ->
	case data_achievement:get_achieve_by_id(Id)  of %% 这里需取得成就对应的数据无视成就条件
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			TitleId		= RecAchievement#rec_achievement.title_id,
			NeedTimes	= RecAchievement#rec_achievement.times,
			AchieveData	= (Player#player.achievement)#achievement.data,
			DoneTimes = 
				case lists:keyfind(Id, #achievement_data.id, AchieveData) of
					Tuple when is_record(Tuple, achievement_data) ->
						Tuple#achievement_data.times;
					_ ->
						0
				end,
			case DoneTimes >= NeedTimes of
				?true	-> %% 达成成就
					refresh_title(Player, Id, MatchData, TitleId);
				?false ->
					Player
			end
	end.

insert_achievement(Player, Id, 0, Times)	->
	case data_achievement:get_achievement_info(Id) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			insert_achievement(Player, RecAchievement, Times)
	end;
insert_achievement(Player, Id, MatchData, Times)	->
	case data_achievement:get_achievement_info({Id, MatchData}) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			insert_achievement(Player, RecAchievement, Times)
	end.

insert_achievement(Player, RecAchievement, Times)	->
	Id			= RecAchievement#rec_achievement.id,
	NeedTimes	= RecAchievement#rec_achievement.times,
	Now			= misc:seconds(),
	Tuple		= #achievement_data{id = Id, times = Times, time = Now},
	case Times >= NeedTimes of
		?true	-> %% 达成成就
			NewTuple	= Tuple#achievement_data{flag = ?true},
			update_player(Player, NewTuple, RecAchievement);
		?false	-> %% 未达成累加次数
			insert_achievement_data(Player, Tuple)
	end.

update_achievement(Player, Id, 0, _Tuple = #achievement_data{flag = ?true}, _Times)	->
	case data_achievement:get_achievement_info(Id) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
%% 			TitleId	= RecAchievement#rec_achievement.title_id,
%% 			refresh_title(Player, TitleId)
			Player
	end;
update_achievement(Player, Id, MatchData, _Tuple = #achievement_data{flag = ?true}, _Times)	->
	case data_achievement:get_achievement_info({Id, MatchData}) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
%% 			TitleId	= RecAchievement#rec_achievement.title_id,
%% 			refresh_title(Player, TitleId)
			Player
	end;
update_achievement(Player, Id, 0, Tuple = #achievement_data{flag = ?false}, Times)	->
	case data_achievement:get_achievement_info(Id) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			Achievement		= Player#player.achievement,
			Data			= Achievement#achievement.data,
			DelData			= lists:delete(Tuple, Data),
			DelAchievement	= Achievement#achievement{data = DelData},
			DelPlayer		= Player#player{achievement = DelAchievement},
			update_achievement(DelPlayer, Tuple, RecAchievement, Times)
	end;
update_achievement(Player, Id, MatchData, Tuple = #achievement_data{flag = ?false}, Times)	->
	case data_achievement:get_achievement_info({Id, MatchData}) of
		?null	->	Player;
		RecAchievement when is_record(RecAchievement, rec_achievement)	->
			Achievement		= Player#player.achievement,
			Data			= Achievement#achievement.data,
			DelData			= lists:delete(Tuple, Data),
			DelAchievement	= Achievement#achievement{data = DelData},
			DelPlayer		= Player#player{achievement = DelAchievement},
			update_achievement(DelPlayer, Tuple, RecAchievement, Times)
	end.

update_achievement(Player, Tuple, RecAchievement, Times)	->
	Now			= misc:seconds(),
	DoneTimes	= Tuple#achievement_data.times + Times,
	NeedTimes	= RecAchievement#rec_achievement.times,
	case DoneTimes >= NeedTimes of
		?true	->
			NewTuple	= Tuple#achievement_data{flag	= ?true,
												 times	= DoneTimes,
												 time	= Now},
			update_player(Player, NewTuple, RecAchievement);
		?false	->
			NewTuple	= Tuple#achievement_data{times	= DoneTimes,
												 time	= Now},
			insert_achievement_data(Player, NewTuple)
	end.

update_player(Player, Tuple, RecAchievement)	->
	Achievement		= Player#player.achievement,
	Data			= Achievement#achievement.data,
	Id				= RecAchievement#rec_achievement.id,
	NewData			= case lists:keyfind(Id, #achievement_data.id, Data) of
						  ?false	->	[Tuple | Data];
						  NewTuple when is_record(NewTuple, achievement_data)	->
							  Data
					  end,
	NewAchievement	= Achievement#achievement{data	= NewData},
	DataPlayer		= Player#player{achievement	= NewAchievement},
%% 	TitleId			= RecAchievement#rec_achievement.title_id,
%% 	Player2			= refresh_title(DataPlayer, TitleId),
%% 	{?ok,TPlayer}	= case check_change_title(Player2, TitleId) of
%% 						  {?ok,Player3} -> {?ok,Player3};
%% 						  _ -> {?ok,Player2}
%% 					  end,  
	Now				= misc:seconds(),
	Honour			= RecAchievement#rec_achievement.points,
	achievement_api:msg_sc_get_achievement(DataPlayer, Id, Now, Honour),
	case player_api:plus_honour(DataPlayer, Honour) of
		{?error, _ErrorCode}	->	DataPlayer;
		{?ok, HonourPlayer}		->	HonourPlayer
	end.

refresh_title(Player, AchiveId, MatchData, TitleId) ->
	case data_achievement:get_title_info(TitleId) of
		?null	->	Player;
		PlayerTitle when is_record(PlayerTitle, player_title)	->
			refresh_title_ext(Player, AchiveId, MatchData, PlayerTitle)
	end.

refresh_title_ext(Player, AchiveId, MatchData, 
				  PlayerTitle = #player_title{title_id	= TitleId, unique	= Unique, is_when = IsWhen})	->
	Achievement		= Player#player.achievement,
	TitleData		= Achievement#achievement.title_data,
	Flag			= check_title_condition(AchiveId, MatchData, PlayerTitle),
	Time			= misc:seconds(),
	NewTuple			= #title_data{id		= TitleId,
								  unique	= Unique,
								  flag		= Flag,
								  time		= Time},
	NewPlayer = 
		  case lists:keyfind(TitleId, #title_data.id, TitleData) of
			  ?false	->
				  AddTitleData		= [NewTuple | TitleData],
				  TempTitleData 	= lists:sort(fun sort/2, AddTitleData),
				  NewAchievement	= Achievement#achievement{title_data	= TempTitleData},
				  Player2			= Player#player{achievement	= NewAchievement},
				  {?ok, Player3} 	= refresh_change_title(Player2, TitleId, ?false, Flag, Time),
				  Player3;
			  OldTuple when is_record(OldTuple, title_data) ->
				  case IsWhen =:= 0 andalso OldTuple#title_data.flag =:= ?true of %% 无条件限制的称号不改变
					  ?true ->
						  Player;
					  ?false ->
						  AddTitleData		= lists:keyreplace(TitleId, #title_data.id, TitleData, NewTuple),
						  TempTitleData 	= lists:sort(fun sort/2, AddTitleData),
						  NewAchievement	= Achievement#achievement{title_data	= TempTitleData},
						  Player2			= Player#player{achievement	= NewAchievement},
						  {?ok, Player3}	= refresh_change_title(Player2, TitleId, OldTuple#title_data.flag, Flag, Time),
						  Player3
				  end;
			  _ ->
				  Player
		  end,
	refresh_unique_title(NewPlayer, TitleId, Unique, Flag).


%% 人物面板刷新称号
refresh_change_title(Player, _TitleId, ?false, ?false, _Time) ->
	{?ok, Player};
refresh_change_title(Player, TitleId, ?false, ?true, Time) ->
	achievement_api:msg_sc_title_get_cancel(Player#player.user_id, TitleId, ?true, Time),
	auto_change_title(Player, TitleId);
refresh_change_title(Player, TitleId, ?true, ?false, Time) ->
	achievement_api:msg_sc_title_get_cancel(Player#player.user_id, TitleId, ?false, Time),
	delete_title(Player, TitleId);
refresh_change_title(Player, _TitleId, ?true, ?true, _Time) ->
	{?ok, Player}.

%% 检查称号达成称号条件
check_title_condition(_AchiveId, 0, _PlayerTitle) -> ?true;
check_title_condition(AchiveId, MatchData, PlayerTitle) ->
	case data_achievement:get_achievement_info({AchiveId, MatchData}) of
		?null ->
			?false;
		_ ->
			check_title_condition_ext(MatchData, PlayerTitle)
	end.
check_title_condition_ext(MatchData, #player_title{is_when = 1, condition = Condition}) ->
	case Condition of
		{upper, Value} ->
			MatchData >= Value;
		{lower, Value} ->
			MatchData =< Value;
		{greater, Value} ->
			MatchData > Value;
		{less, Value} ->
			MatchData < Value;
		{equal, Value} ->
			MatchData =:= Value;
		{left, MinValue, MaxValue} ->
			MatchData >= MinValue andalso MatchData < MaxValue;
		{right, MinValue, MaxValue} ->
			MatchData >  MinValue andalso MatchData =<  MaxValue;
		{open, MinValue, MaxValue} ->
			MatchData > MinValue andalso MatchData <  MaxValue;
		{close, MinValue, MaxValue} ->
			MatchData >= MinValue andalso MatchData =< MaxValue;
		_ -> ?true
	end;
check_title_condition_ext(_MatchData, _PlayerTitle) -> ?true.

%% 更新唯一称号
refresh_unique_title(Player, _TitleId, ?CONST_SYS_FALSE, _)	->	Player;
refresh_unique_title(Player, _TitleId, ?CONST_SYS_TRUE, ?false)		-> Player;
refresh_unique_title(Player, TitleId, ?CONST_SYS_TRUE, ?true)		->
	UserId			= Player#player.user_id,
	case ets:lookup(?CONST_ETS_UNIQUE_TITLE, TitleId) of
		[]							->	?ignore;
		[{TitleId, UserId} | _]		->	?ignore;
		[{TitleId, OldUserId} | _]	->	achievement_api:delete_title(OldUserId, TitleId)
	end,
	ets:insert(?CONST_ETS_UNIQUE_TITLE, {TitleId, Player#player.user_id}),
	CurrentTitle	= current_title(Player),
	case data_achievement:get_title_info(CurrentTitle) of
		?null	->
			{?ok, NewPlayer}	= change_title(Player, TitleId), 
			NewPlayer;
		PlayerTitle when is_record(PlayerTitle, player_title)
		  andalso PlayerTitle#player_title.unique =:= ?CONST_SYS_FALSE	->
			
			{?ok, NewPlayer}	= change_title(Player, TitleId),
			NewPlayer;
		PlayerTitle when is_record(PlayerTitle, player_title)
		  andalso PlayerTitle#player_title.unique =:= ?CONST_SYS_TRUE	->
			Player
	end.

sort(A, B) when is_record(A, title_data) andalso is_record(B, title_data)	->
	if
		A#title_data.unique > B#title_data.unique	->	?true;
		A#title_data.unique =:= B#title_data.unique	->
			A#title_data.time > B#title_data.time;
		?true	->	?false
	end.

insert_achievement_data(Player, Tuple)	->
	Achievement		= Player#player.achievement,
	Data			= Achievement#achievement.data,
	Id				= Tuple#achievement_data.id,
	NewData			= case lists:keyfind(Id, #achievement_data.id, Data) of
						  ?false	->	[Tuple | Data];
						  NewTuple when is_record(NewTuple, achievement_data)	->
							  Data
					  end,
	NewAchievement	= Achievement#achievement{data	= NewData},
	Player#player{achievement	= NewAchievement}.

refresh_achievement_data(Achievement, TitleId)	->
	Now				= misc:seconds(),
	TitleData		= Achievement#achievement.title_data,
	NewTitleData	= case lists:keyfind(TitleId, #title_data.id, TitleData) of
						  ?false	->	TitleData;
						  Tuple when is_record(Tuple, title_data)
							andalso Tuple#title_data.flag =:= ?true		->
							  NewTuple		= Tuple#title_data{time		= Now},
							  TmpTitleData	= lists:keyreplace(TitleId, #title_data.id, TitleData, NewTuple),
							  lists:sort(fun sort/2, TmpTitleData);
						  Tuple when is_record(Tuple, title_data)
							andalso Tuple#title_data.flag =:= ?false	->	TitleData
					  end,
	?MSG_WARNING("~nTitleData=~p~nNewTitleData=~p~n", [TitleData, NewTitleData]),
	Achievement#achievement{title_data	= NewTitleData}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获取成就礼品
%% @name   get_achievement_gift/1
%% @dep    
%% @parm   Player				玩家信息
%% @return GetGiftResult		领取礼品状态
%%         NewGiftId			礼品ID
%%         Player|NewPlayer		玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_achievement_gift(Player) ->
	Info	= Player#player.info,
	Honour	= Info#info.honour,
	case data_achievement:get_gift_list(Honour) of
		?null		->	{?ok, Player};
		GiftIdList	->	get_achievement_gift(Player, GiftIdList)
	end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% @desc   获取成就礼品
%% @name   get_achievement_gift/2
%% @dep    
%% @parm   Player				玩家信息
%% @parm   GiftId				匹配的基础成就记录
%% @return GetGiftResult		领取礼品状态
%%         Player|NewPlayer		玩家信息
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_achievement_gift(Player, [GiftId | GiftIdList])	->
	Achievement	= Player#player.achievement,
	GetGiftIds	= Achievement#achievement.gifts,
	case lists:member(GiftId, GetGiftIds) of
		?true	->
			get_achievement_gift(Player, GiftIdList);
		?false	->
			{?ok, NewPlayer}	= get_achievement_gift(Player, GiftId),
			get_achievement_gift(NewPlayer, GiftIdList)
	end;
get_achievement_gift(Player, [])	->
	{?ok, Player};
get_achievement_gift(Player, GiftId) when is_integer(GiftId)	->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	Achievement	= Player#player.achievement,
	Honour		= Info#info.honour,
	GetGiftIds	= Achievement#achievement.gifts,
	MemberFlag	= case lists:member(GiftId, GetGiftIds) of
					  ?true	->	?false;	?false	->	?true
				  end,
	Gift		= data_achievement:get_gift_info(GiftId),
	GiftFlag	= case Gift of
					  ?null	->	?false;	_		->	?true
				  end,
	case {GiftFlag, MemberFlag} of
		{?true, ?true}	->	%% 未领取且礼品存在
			NeedHonour	= Gift#rec_achievement_gift.points,
			case Honour >= NeedHonour of
				?true	->
					case reward_goods(Player, Gift#rec_achievement_gift.goods) of
						{?error, _ErrorCode}		->	{?ok, Player};
						{?ok, Player1, GoodsList}	->
							achievement_api:msg_sc_get_achievement_gift(Player, GiftId),
							notice(UserId, GoodsList),
							NewGetGiftIds	= [GiftId | GetGiftIds],
							NewAchievement	= Achievement#achievement{gifts	= NewGetGiftIds},
							NewPlayer		= Player1#player{achievement	= NewAchievement},
							{?ok, NewPlayer}
					end;
				?false	->	{?ok, Player}
			end;
		{?false, _}	->
			TipsPacket	= message_api:msg_notice(?TIP_ACHIEVEMENT_GIFT_NOTEXIST),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player};
		{_, ?false}	->
			TipsPacket	= message_api:msg_notice(?TIP_ACHIEVEMENT_GIFT_RECEIVED),
			misc_packet:send(UserId, TipsPacket),
			{?ok, Player}
	end.

%% 物品奖励
reward_goods(Player, List)	->
	reward_goods(Player, List, []).
reward_goods(Player, [{Pro, Sex, GoodsId, BindState, Count} | List], Acc)	->
	case reward_goods(Player, Pro, Sex, GoodsId, BindState, Count) of
		{?ok, Player2, GoodsList}	->	reward_goods(Player2, List, (GoodsList ++ Acc));
		{?error, ErrorCode}	->	{?error, ErrorCode}
	end;
reward_goods(Player, [], Acc)	->	{?ok, Player, Acc}.

reward_goods(Player, Pro, Sex, GoodsId, BindState, Count)	->
	UserId	= Player#player.user_id,
	Info	= Player#player.info,
	if
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)   	  orelse
		(Pro =:= Info#info.pro 	 	 andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= Info#info.pro    	 andalso Sex =:= Info#info.sex)	->
			case goods_api:make(GoodsId, BindState, Count) of
				GoodsList when is_list(GoodsList)	->
                    case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_ACHIEVEMENT_GET, 1, 1, 0, 0, 1, 1, []) of
						{?error, ErrorCodeBag}	->
							{?error, ErrorCodeBag};
						{?ok, Player2, _, _} ->
							{?ok, Player2, GoodsList}
					end;
				{?error, ErrorCodeGoods}	->
					PacketGoods2Err = message_api:msg_notice(ErrorCodeGoods),
					misc_packet:send(UserId, PacketGoods2Err),
					{?error, ErrorCodeGoods}
			end;
		?true	->
			{?ok, Player, []}
	end.

notice(UserId, [Goods | GoodsList]) when is_record(Goods, goods)	->
	GoodsIdStr	= misc:to_list(Goods#goods.goods_id),
	CountStr	= misc:to_list(Goods#goods.count),
	TipsPacket	= message_api:msg_notice(?TIP_ACHIEVEMENT_GIFT_INFO,
										 [{?CONST_MESSAGE_TIP_SYS_ACHI_GIFT, GoodsIdStr},
										  {?CONST_MESSAGE_TIP_SYS_COMM, CountStr}]),
	misc_packet:send(UserId, TipsPacket),
	notice(UserId, GoodsList);
notice(_UserId, [])	->	?ok.

delete_title(Player, TitleId)	->
	Achievement	= Player#player.achievement,
	TitleData	= Achievement#achievement.title_data,
	case lists:keyfind(TitleId, #title_data.id, TitleData) of
		Tuple when is_record(Tuple, title_data)	->
			DelTitleData	= lists:keydelete(TitleId, #title_data.id, TitleData),
			SortTitleData	= lists:sort(fun sort/2, DelTitleData),
			NewAchievement	= Achievement#achievement{title_data = SortTitleData},
			NewPlayer		= Player#player{achievement = NewAchievement},
			achievement_info(NewPlayer),
			CurTitleId	   = current_title(Player),
			case CurTitleId =:= TitleId of %% 删除当前称号才替换称号
				?true ->
					case title_data(SortTitleData) of
						?null	->	
							change_title(NewPlayer, 0);
						NewTuple when is_record(NewTuple, title_data)	->
							change_title(NewPlayer, NewTuple#title_data.id)
					end;
				?false ->
					{?ok, NewPlayer}
			end;
		?false	->	{?ok, Player}
	end.

title_data([TitleData = #title_data{flag = ?true} | _TitleDataList])	->
	TitleData;
title_data([_TitleData = #title_data{flag = ?false} | TitleDataList])	->
	title_data(TitleDataList);
title_data([])	->	?null.

change_title(Player, TitleId)	->
	case check_change_title(Player,TitleId) of	
		{?error,ErrorCode} ->
			TipsPacket	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{?ok,Player2} ->  
%% 			TipsPacket	= message_api:msg_notice(?TIP_ACHIEVEMENT_TITLE_CHANGE),
%% 			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok,Player2}
	end.

check_change_title(Player,0) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	achievement_api:msg_sc_change_title(UserId, 0),
	NewInfo			= Info#info{current_title = 0},
	NewPlayer		= Player#player{info		= NewInfo},
	AttrPlayer		= player_attr_api:refresh_attr_title(NewPlayer),
	UpdatePacket	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CURRENT_TITLE, 0),
	misc_packet:send(UserId, UpdatePacket),
	map_api:change_title(AttrPlayer),
	{?ok, AttrPlayer};
check_change_title(Player,TitleId) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	OldTitleId	= Info#info.current_title,
	Achievement	= Player#player.achievement,
	TitleData	= Achievement#achievement.title_data,
	case lists:keyfind(TitleId, #title_data.id, TitleData) of
		Tuple when is_record(Tuple, title_data) andalso Tuple#title_data.flag =:= ?true		->
			case TitleId =/= OldTitleId of
				?false	->
					{?ok,Player};
				?true	->
					achievement_api:msg_sc_change_title(UserId, TitleId),
					NewInfo			= Info#info{current_title = TitleId},
					NewAchievement	= refresh_achievement_data(Achievement, TitleId),
					NewPlayer		= Player#player{info		= NewInfo,
													achievement	= NewAchievement},
					AttrPlayer		= player_attr_api:refresh_attr_title(NewPlayer),
					UpdatePacket	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CURRENT_TITLE, TitleId),
					misc_packet:send(UserId, UpdatePacket),
					map_api:change_title(AttrPlayer),
					{?ok, AttrPlayer}
			end;
		Tuple when is_record(Tuple, title_data) andalso Tuple#title_data.flag =:= ?false	->
			{?error,?TIP_ACHIEVEMENT_TITLE_UNFIT};
		?false	->
			{?error,?TIP_ACHIEVEMENT_TITLE_NOTEXIST}
	end.

%% 只有获得第一个称号时自动替换
auto_change_title(Player, TitleId)	->
	case auto_check_change_title(Player,TitleId) of	
		{?error,ErrorCode} ->
			TipsPacket	= message_api:msg_notice(ErrorCode),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		{?ok, Player2} ->  
%% 			TipsPacket	= message_api:msg_notice(?TIP_ACHIEVEMENT_TITLE_CHANGE),
%% 			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok,Player2};
		{?ok, ?false, Player2} ->
			{?ok,Player2}
	end.

auto_check_change_title(Player,0) ->
	{?ok, Player};
auto_check_change_title(Player, TitleId) ->
	UserId		= Player#player.user_id,
	Info		= Player#player.info,
	OldTitleId	= Info#info.current_title,
	Achievement	= Player#player.achievement,
	TitleData	= Achievement#achievement.title_data,
	case lists:keyfind(TitleId, #title_data.id, TitleData) of
		Tuple when is_record(Tuple, title_data) andalso Tuple#title_data.flag =:= ?true		->
			case OldTitleId =:= 0 of
				?false	->
					{?ok, Player};
				?true	->
					achievement_api:msg_sc_change_title(UserId, TitleId),
					NewInfo			= Info#info{current_title = TitleId},
					NewAchievement	= refresh_achievement_data(Achievement, TitleId),
					NewPlayer		= Player#player{info		= NewInfo,
													achievement	= NewAchievement},
					AttrPlayer		= player_attr_api:refresh_attr_title(NewPlayer),
					UpdatePacket	= player_api:msg_player_attr_update(?CONST_SYS_PLAYER, ?CONST_PLAYER_ATTR_CURRENT_TITLE, TitleId),
					misc_packet:send(UserId, UpdatePacket),
					map_api:change_title(AttrPlayer),
					{?ok, AttrPlayer}
			end;
		Tuple when is_record(Tuple, title_data) andalso Tuple#title_data.flag =:= ?false	->
			{?error,?TIP_ACHIEVEMENT_TITLE_UNFIT};
		?false	->
			{?error,?TIP_ACHIEVEMENT_TITLE_NOTEXIST}
	end.

refresh_attr(TitleId)	->
	case data_achievement:get_title_info(TitleId) of
		?null	->	{player_attr_api:record_attr(), []};
		PlayerTitle when is_record(PlayerTitle, player_title)	->
			InitAttr	= player_attr_api:record_attr(),
			AttrValue   = get_title_attr_value(PlayerTitle#player_title.attr_value, InitAttr),
			AttrPer		= get_suit_attr_per(PlayerTitle#player_title.attr_per),
			{AttrValue, AttrPer}
	end.

get_title_attr_value([], Attr) -> Attr;
get_title_attr_value([{Type, Value}|List], Attr) ->
	NewAttr	= player_attr_api:attr_plus(Attr, Type, Value),
	get_title_attr_value(List, NewAttr).

get_suit_attr_per(AttrPer) -> 
	Fun = fun({Type, Factor}, AccIn) ->
				  [{Type, Factor, ?CONST_SYS_NUMBER_TEN_THOUSAND}|AccIn]
		  end,
	lists:foldl(Fun, [], AttrPer).
%% 推送已有称号列表
title_list(Player) ->
	{?ok, Player2}	= achievement_api:refresh_title(Player),
	Achievement		= Player2#player.achievement,
	TitleData		= Achievement#achievement.title_data,
	Fun	= fun(Title, Acc) ->
				  case Title#title_data.flag of
					  ?true ->
						  Id			= Title#title_data.id,
						  Time			= Title#title_data.time,
						  RecTitle 		= data_achievement:get_title_info(Id),
						  EffectTime 	= RecTitle#player_title.effect_time,
						  TimeStamp		= 
							  case EffectTime =:= 0 of
								  ?true ->
									  0;
								  ?false ->
									 Time + EffectTime
							  end,
						  [{Id, TimeStamp}|Acc];
					  ?false ->
						  Acc
				  end
		  end,
	TitleIdList		= lists:foldl(Fun, [], TitleData),
	achievement_api:msg_sc_title_list(Player#player.user_id, TitleIdList),
	{?ok, Player2}.


%% 获取系列称号最高级的
get_series_title(TitleId, TitleData) ->
	Series1	= [10025, 10026, 10027, 10028],
	Series2 = [10048, 10049, 10050],
	Flag1	= lists:member(TitleId, Series1),
	Flag2	= lists:member(TitleId, Series2),
	Fun		= fun(A, B) ->
					  A#title_data.id > B#title_data.id
			  end,
	if Flag1 ->
		   TitleList1 = [X|| X <- TitleData, lists:member(X#title_data.id, Series1)],
		   lists:sort(Fun, TitleList1);
	   Flag2 ->
		   TitleList1 = [X|| X <- TitleData, lists:member(X#title_data.id, Series2)],
		   lists:sort(Fun, TitleList1);
	   ?true ->
		   TitleData
	end.
		

%%
%% Local Functions
%%