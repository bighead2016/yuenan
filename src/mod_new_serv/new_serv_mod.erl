%% Author: Administrator
%% Created: 2013-6-13
%% Description: TODO: Add description to new_serv_mod
-module(new_serv_mod).

%%
%% Include files
%%
-include("const.common.hrl").
-include("const.define.hrl").
-include("const.protocol.hrl").
-include("const.tip.hrl").
-include("const.cost.hrl").

-include("record.player.hrl").
-include("record.data.hrl").
-include("record.base.data.hrl").
-include("record.goods.data.hrl").
%%
%% Exported Functions
%%
-export([
		 finish_achieve/4,
		 achieve_reward/2,
		 reward/3,
		 storage/1,
		 calc_storage/1,
		 calc_interest/2,
		 check_time_validate/1,
		 check_achieve_validate/1,
		 draw_storage/1,
		 end_time/1,
		 select_data/0,
		 select_data_hero/0,
		 add_honor_title/3,
		 update_hero_rank/3,
		 exchange_cash/6,
		 exchange_goods/5,
		 exchange_info/1,
         save_data_hero/0,
         update_guild_power_hero_rank/3]).

%%
%% API Functions
%%
finish_achieve(Player, Type, MatchData, Times) when is_integer(Type)	->
	case data_new_serv:get_achieve_list({Type}) of
		?null	->
			{?ok, Player};
		IdList	->
					finish_achieve(Player, IdList, MatchData, Times)
	end;
finish_achieve(Player, [Id | IdList], MatchData, Times)	->
	NewServ		= Player#player.new_serv,
	Achieve 	= NewServ#new_serv.achieve,
	NewTuple	=
		case lists:keyfind(Id, #achieve.id, Achieve) of
			OldTuple when is_record(OldTuple, achieve) ->
				OldTuple;
			_ ->
				#achieve{id	= Id}
		end,
	NewPlayer	=
		case MatchData of
			0	->
				case data_new_serv:get_achieve_info(Id) of
					RecAchieve when is_record(RecAchieve, rec_achieve)	->
						set_achieve(Player, NewTuple, RecAchieve, Times);
					_Other	->
						Player
				end;
			_MatchData	->
				case data_new_serv:get_achieve_info({Id, MatchData}) of
					RecAchieve when is_record(RecAchieve, rec_achieve)	->
						set_achieve(Player, NewTuple, RecAchieve, Times);
					_Other	->
						Player
				end
		end,
	finish_achieve(NewPlayer, IdList, MatchData, Times);
finish_achieve(Player, [], _, _)	->
	{?ok, Player}.

set_achieve(Player, Tuple, RecAchieve, Times) ->
%% 	?MSG_DEBUG("set_achieve11111111111111111111111111111111111:~p",[RecAchieve]),
	case check_achieve_validate(RecAchieve) of
		?true ->
			set_achieve_ext(Player, Tuple, RecAchieve, Times);
		?false ->
			Player
	end.

set_achieve_ext(Player, Tuple, RecAchieve, Times) ->
	Now				= misc:seconds(),
	DoneTimes		= Tuple#achieve.times + Times,
	NeedTimes		= RecAchieve#rec_achieve.times,
	NewServ			= Player#player.new_serv,
	Achieve			= NewServ#new_serv.achieve,
	Id				= Tuple#achieve.id,
	Achieve2		= lists:keydelete(Id, #achieve.id, Achieve),
	Tuple2		=
		case RecAchieve#rec_achieve.times >= 999 of
			?true -> %% 无限次单独处理
				Tuple#achieve{flag = ?true, received	= ?CONST_NEW_SERV_UNRECEIVE};
			?false ->
				Tuple
		end,
	NewTuple	=
		case DoneTimes >= NeedTimes andalso Tuple2#achieve.received =:= ?CONST_NEW_SERV_UNFIT of
			?true	->
				Tuple2#achieve{times		= DoneTimes,	
							  time	    = Now,
							  flag        = ?true,
							  received	= ?CONST_NEW_SERV_UNRECEIVE};
			?false	->
				Tuple2#achieve{times	= DoneTimes,	time	= Now}
		end,
%% 	?MSG_DEBUG("set_achieve_ext11111111111111111:~p",[{Tuple,Tuple2,NewTuple}]),
	Flag		= NewTuple#achieve.flag,
	Received	= NewTuple#achieve.received,
	NewTimes	= NewTuple#achieve.times,
	Packet		= new_serv_api:pack_sc_achieve(Id, Flag, Received, NewTimes),
	misc_packet:send(Player#player.net_pid, Packet),
	Achieve3	= [NewTuple|Achieve2],
	NewServ2	= NewServ#new_serv{achieve = Achieve3},
	Player#player{new_serv = NewServ2}.


%% 领取达成成就奖励
achieve_reward(Player, Id)	->
	NewServ		= Player#player.new_serv,
	Achieve		= NewServ#new_serv.achieve,
	case lists:keyfind(Id, #achieve.id, Achieve) of
		Tuple when is_record(Tuple, achieve)
		  andalso Tuple#achieve.flag =:= ?true
		  andalso Tuple#achieve.received =:= ?CONST_NEW_SERV_UNFIT		->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_UNFIT),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Tuple when is_record(Tuple, achieve)
		  andalso Tuple#achieve.flag =:= ?true
		  andalso Tuple#achieve.received =:= ?CONST_NEW_SERV_UNRECEIVE	->
			case data_new_serv:get_achieve_goods(Id) of
				RecAchieve when is_record(RecAchieve, rec_achieve)	->
					case reward(Player, RecAchieve, Tuple#achieve.times) of
						{?error, _ErrorCode}			->
							{?ok, Player};
						{?ok, NewPlayer, _NewGoodsList}	->
							NewTuple		= Tuple#achieve{received	= ?CONST_NEW_SERV_RECEIVED, times = 0},
							NewAchieve		= lists:keyreplace(Id, #achieve.id, Achieve, NewTuple),
							NewServ2		= NewServ#new_serv{achieve	= NewAchieve},
							NewFlag			= NewTuple#achieve.flag,
							NewReceived		= NewTuple#achieve.received,
							NewTimes		= NewTuple#achieve.times,
							Packet			= new_serv_api:pack_sc_achieve_receive(Id),
							Packet1			= new_serv_api:pack_sc_achieve(Id, NewFlag, NewReceived, NewTimes),
							misc_packet:send(NewPlayer#player.net_pid, <<Packet/binary, Packet1/binary>>),
							{?ok, NewPlayer#player{new_serv	= NewServ2}}
					end;
				_Other	->
					{?ok, Player}
			end;
		Tuple when is_record(Tuple, achieve)
		  andalso Tuple#achieve.flag =:= ?true
		  andalso Tuple#achieve.received =:= ?CONST_NEW_SERV_RECEIVED	->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_RECEIVED),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		Tuple when is_record(Tuple, achieve)
		  andalso Tuple#achieve.flag =:= ?false		->
			TipsPacket		= message_api:msg_notice(?TIP_WELFARE_NOT_EXIST),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player};
		_Other	->
			TipsPacket		= message_api:msg_notice(?TIP_COMMON_BAD_ARG),
			misc_packet:send(Player#player.net_pid, TipsPacket),
			{?ok, Player}
	end.

reward(Player, RecAchieve, Times)	->
	case reward_goods(Player, RecAchieve#rec_achieve.goods, RecAchieve#rec_achieve.times, Times) of
		{?error, ErrorCode}	->
			{?error, ErrorCode};
		{?ok, Player2, GoodsList}	->
			{?ok, Player2, GoodsList}
	end.

%% 物品奖励
reward_goods(Player, List, RecTimes, Times)	->
	case reward_goods(Player, List, RecTimes, Times, []) of
		{?ok, GoodsList} ->
            case ctn_bag_api:put(Player, GoodsList, ?CONST_COST_NEW_SERV_DRAW, 1, 1, 0, 0, 1, 1, []) of
				{?error, ErrorCodeBag}	->
					{?error, ErrorCodeBag};
				{?ok, Player2, _, _PacketBag} ->
					{?ok, Player2, GoodsList}
			end;
		{?error, ErrorCode}	->
			{?error, ErrorCode}
	end.

reward_goods(Player, [{Pro, Sex, GoodsId, BindState, Count} | List], RecTimes, Times, Acc)	->
	RealCount	= 
		case RecTimes >= 999 of
			?true ->
				Times * Count;
			?false ->
				Count
		end,
	case reward_goods(Player, Pro, Sex, GoodsId, BindState, RealCount) of
		{?ok, GoodsList}	-> reward_goods(Player, List, RecTimes, Times, (GoodsList ++ Acc));
		{?error, ErrorCode}	-> {?error, ErrorCode}
	end;
reward_goods(_Player, [], _RecTimes, _Times, Acc)	-> {?ok, Acc}.

reward_goods(Player, Pro, Sex, GoodsId, BindState, Count)	->
	UserId	= Player#player.user_id,
	Info	= Player#player.info,
	if
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= ?CONST_SYS_PRO_NULL andalso Sex =:= Info#info.sex)   	  orelse
		(Pro =:= Info#info.pro 	 	 andalso Sex =:= ?CONST_SYS_SEX_NULL) orelse
		(Pro =:= Info#info.pro    	 andalso Sex =:= Info#info.sex)	->
			case goods_api:make(GoodsId, BindState, Count) of
				GoodsList when is_list(GoodsList) ->
					{?ok, GoodsList};
				{?error, ErrorCodeGoods}	->
					PacketGoods2Err = message_api:msg_notice(ErrorCodeGoods),
					misc_packet:send(UserId, PacketGoods2Err),
					{?error, ErrorCodeGoods}
			end;
		?true	->
			{?ok, []}
	end.

%% 存钱
storage(Player) ->
	UserId  	= Player#player.user_id,
	StoreCash  	= ?CONST_NEW_SERV_STORAGE,
	StartTime 	= new_serv_api:get_serv_start_time(),
	Now	   		= misc:seconds(),
	DiffDay		= misc:get_diff_days(StartTime, Now),
	case DiffDay < ?CONST_NEW_SERV_PREFER_TIME_FIVE of
		?true ->
			NewServ		= Player#player.new_serv,
			Storage     = NewServ#new_serv.storage,
			FirstReturn = NewServ#new_serv.first_return,
			Award		= NewServ#new_serv.award,
			DrawFlag	= NewServ#new_serv.draw_flag,
			case player_money_api:minus_money(UserId, ?CONST_SYS_CASH, StoreCash, ?CONST_COST_NEW_SERV_STORAGE) of
					?ok ->
						NewStorage =
							case lists:keyfind(DiffDay, #storage.diff_day, Storage) of
								?false ->
									NewTuple   = #storage{diff_day = DiffDay, value = StoreCash},
									[NewTuple|Storage];
								Tuple when is_record(Tuple, storage) ->
									Value	   = Tuple#storage.value,
									NewTuple   = Tuple#storage{value = Value + StoreCash},
									lists:keyreplace(DiffDay, #storage.diff_day, Storage, NewTuple)
							end,
						NewFirstReturn = misc:ceil(FirstReturn + StoreCash * ?CONST_NEW_SERV_FIRST_PER div ?CONST_SYS_NUMBER_HUNDRED),
						AwardPer	   = ?CONST_NEW_SERV_FIRST_PER + ?CONST_NEW_SERV_INTEREST_PER * ?CONST_NEW_SERV_PREFER_TIME_FIVE,
						NewAward	   = Award + misc:ceil(StoreCash * AwardPer div ?CONST_SYS_NUMBER_HUNDRED),
						NewServ2   	   = NewServ#new_serv{storage 	   = NewStorage, 
														  first_return = NewFirstReturn,
														  award		   = NewAward},
						Player2	   	   = Player#player{new_serv = NewServ2},
						Interest	   = calc_interest(Player2, Now),
						CanDraw		   = 
							case DrawFlag of
								?false ->
									NewFirstReturn + Interest;
								?true ->
									NewFirstReturn
							end,
						Packet		   = new_serv_api:pack_sc_storage_info(NewAward, CanDraw),
						misc_packet:send(Player#player.user_id, Packet),
						{?ok, Player2};
					_Other ->
						{?ok, Player}
			end;
		?false -> 
			TipPacket = message_api:msg_notice(?TIP_COMMON_BAD_ARG),
		    misc_packet:send(Player#player.user_id, TipPacket),
			{?ok, Player}
	end.

%% 计算总存储金额
calc_storage(Player) ->
	NewServ		= Player#player.new_serv,
	Storage     = NewServ#new_serv.storage,
	calc_storage(Storage, 0).

calc_storage([], Acc) -> Acc;
calc_storage([#storage{value = Value}|StorageList], Acc) -> 
	NewAcc 		= Acc + Value,
	calc_storage(StorageList, NewAcc);
calc_storage([_Other|StorageList], Acc) ->
	calc_storage(StorageList, Acc).

%% 计算利息返回
calc_interest(Player, Seconds) when is_record(Player, player) ->
	NewServ		= Player#player.new_serv,
	Storage     = NewServ#new_serv.storage,
	StartTime 	= new_serv_api:get_serv_start_time(),
%% 	Now	   		= misc:seconds(),
	Diff		= misc:get_diff_days(StartTime, Seconds),
	calc_interest(Storage, Diff, 0);
calc_interest(Storage, Seconds) when is_record(Storage, storage) ->
	StartTime 	= new_serv_api:get_serv_start_time(),
%% 	Now	   		= misc:seconds(),
	Diff		= misc:get_diff_days(StartTime, Seconds),
	calc_interest(Storage, Diff, 0).

calc_interest([], _Diff, Acc) -> misc:ceil(Acc * ?CONST_NEW_SERV_INTEREST_PER div ?CONST_SYS_NUMBER_HUNDRED);
calc_interest([#storage{diff_day = DiffDay, value = Value}|StorageList], Diff, Acc) ->
	NewAcc = 	
		case Diff > DiffDay andalso Diff - DiffDay =< ?CONST_NEW_SERV_PREFER_TIME_FIVE of
			?true ->
				Acc + Value;
			?false ->
				Acc
		end,
	calc_interest(StorageList, Diff, NewAcc);
calc_interest([_Other|StorageList], Diff, Acc) ->
	calc_interest(StorageList, Diff, Acc).

%% 检查活动时间是否有效
check_time_validate(Type) ->
	Now		= misc:seconds(),
	EndTime	= end_time(Type),
	Now =< EndTime.

check_achieve_validate(#rec_achieve{is_new = ?CONST_SYS_TRUE} = _RecAchieve) ->
	check_time_validate(?CONST_NEW_SERV_TYPE_ACHIEVE);
check_achieve_validate(#rec_achieve{is_new = ?CONST_SYS_FALSE} = RecAchieve) ->
	case new_serv_api:is_new_serv(7) of
		?true ->
			?false;
		?false ->
			Now			= misc:seconds(),
			StartList	= RecAchieve#rec_achieve.activity_start,
			EndList		= RecAchieve#rec_achieve.activity_end,
			is_validate(Now, StartList, EndList)
	end.

is_validate(Now, [Start | StartList], [End | EndList]) ->
	StartSeconds	= misc:date_time_to_stamp(Start),
	EndSeconds		= misc:date_time_to_stamp(End),
%% 	?MSG_DEBUG("is_validate11111111111:~p",[{StartSeconds,Now,EndSeconds}]),
	case StartSeconds =< Now andalso Now =< EndSeconds of
		?true	->	?true;
		?false	->	is_validate(Now, StartList, EndList)
	end;
is_validate(_Now, [], [_])	->	?false;
is_validate(_Now, [_], [])	->	?false;
is_validate(_Now, [], [])	->	?false.

%% 生财宝箱每日领取元宝
draw_storage(Player) ->
	NewServ		= Player#player.new_serv,
	FirstReturn = NewServ#new_serv.first_return,
	Award		= NewServ#new_serv.award,
	DrawFlag	= NewServ#new_serv.draw_flag,
	case Award > 0 of
		?true ->
			Now			= misc:seconds(),
			Interest	= 
				case DrawFlag of
					?false ->
						calc_interest(Player, Now);
					?true ->
						0
				end,
			DrawTotal   = FirstReturn + Interest,
			AddDraw		= 
				case Award - DrawTotal >= 0 of
					?true ->
						DrawTotal;
					?false ->
						Award
				end,
			NewAward	= misc:uint(Award - DrawTotal),
			case player_money_api:plus_money(Player#player.user_id, ?CONST_SYS_CASH, AddDraw, ?CONST_COST_NEW_SERV_DRAW) of
				?ok ->
					NewServ2	= NewServ#new_serv{first_return = 0, award = NewAward, draw_flag = ?true},
					Player2		= Player#player{new_serv = NewServ2},
				%% 	TotalStorage	= calc_storage(Player2),
					Packet		= new_serv_api:pack_sc_storage_info(NewAward, 0),
					misc_packet:send(Player#player.user_id, Packet),
					{?ok, Player2};
				_Other ->
					{?ok, Player}
			end;
		?false ->
			{?ok, Player}
	end.

%% 活动到期时间
end_time(_Type) ->
	DayNum	= 7, %?CONST_NEW_SERV_PREFER_TIME_FIVE,
%% 		if Type =:= ?CONST_NEW_SERV_TYPE_ACHIEVE ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_SEVEN;
%% 		   Type =:= ?CONST_NEW_SERV_TYPE_RANK ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_SEVEN;
%% 		   Type =:= ?CONST_NEW_SERV_TYPE_DEPOSIT_RETURN ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_THREE;
%% 		   Type =:= ?CONST_NEW_SERV_TYPE_FIRST_DEPOSIT ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_SEVEN;
%% 		   Type =:= ?CONST_NEW_SERV_TYPE_ICON ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_FIFTEEN;
%% 		   Type =:= ?CONST_NEW_SERV_TYPE_STORAGE ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_FIVE;
%% 		   ?true ->
%% 			   ?CONST_NEW_SERV_PREFER_TIME_SEVEN
%% 		end,
	StartTime = new_serv_api:get_serv_start_time(),
	StartTime + DayNum * 24 * 3600.

%% ==========================================================
%% 开服活动 -- 荣誉榜
%% ==========================================================

%% 初始化ETS
select_data() ->
	case mysql_api:select([honor_id, user_id, user_name, lv, sex, pro, weapon, fashion, armor], 
						  game_honor_title, []) of
		{?ok, List} ->
			F = fun([HonorId, UserId, UserName, Lv, Sex, Pro, Weapon, Fashion, Armor]) ->
						Honortitle = #rec_honor_title{
													  honor_id = HonorId,		% 荣誉榜ID
													  user_id = UserId,			% 玩家ID
													  user_name = UserName,		% 玩家名称
													  lv = Lv,					% 玩家等级
													  sex = Sex,				% 性别
													  pro = Pro,				% 职业
													  weapon = Weapon,			% 武器ID
													  fashion = Fashion,		% 时装ID
													  armor = Armor				% 衣服ID			
													 },
						
						ets_api:insert(?CONST_ETS_HONOR_TITLE, Honortitle)
				end,
			lists:foreach(F, List);
		_ -> ?ok
	end.



%% 第一个达到40级的玩家
%% 第一个获得红色武将的玩家
%% 第一个将坐骑培养到40级的玩家
%% 第一个在破阵中通关七月流火阵的玩家
%% 第一个获得红色星斗的玩家
%% 第一个穿戴5级时装的玩家
add_honor_title(Player, HonorId, AchType) when is_record(Player, player)->
	NowSec = misc:seconds(),
	EndTime = end_time(1),
	case NowSec >= EndTime of
		?true ->
			{?ok, Player};
		_ ->			
			case ets_api:lookup(?CONST_ETS_HONOR_TITLE, HonorId) of
				?null ->
					{?ok, Player2} = achievement_api:add_achievement(Player, AchType, 0, 1),
					save_honor_title_data(Player2, HonorId),
					Info = Player2#player.info,
					case data_new_serv:get_honor_title(HonorId) of
						#rec_new_serv_honor_title{goods = GoodsTuple, mail_id = MailId} ->
							GoodsList = make_goods(GoodsTuple, []),
							GoodsList2 = [{misc:to_list(G#goods.goods_id)}||G<-GoodsList],
							mail_api:send_system_mail_to_one(Info#info.user_name, <<>>, <<>>, MailId, 
															 [{GoodsList2}], GoodsList, 0, 0, 0, 0);
						_ ->
							?MSG_ERROR("Honor title data not exist !",  [])
					end,
					{?ok, Player2};		
				_RecHonorTitle ->
					{?ok, Player}
			end
	end;

%% 第一个将军团升级到4级的军团长
add_honor_title(UserId, HonorId, AchType) when is_integer(UserId)->
	NowSec = misc:seconds(),
	EndTime = end_time(1),
	case NowSec >= EndTime of
		?true ->
			?ok;
		_ ->	
			case ets_api:lookup(?CONST_ETS_HONOR_TITLE, HonorId) of
				?null ->
					achievement_api:add_achievement(UserId, AchType, 0, 1),
					save_honor_title_data(UserId, HonorId),
					case data_new_serv:get_honor_title(HonorId) of
						#rec_new_serv_honor_title{goods = GoodsTuple, mail_id = MailId} ->
							GoodsList = make_goods(GoodsTuple, []),
							GoodsList2 = [{misc:to_list(G#goods.goods_id)}||G<-GoodsList],
							UserName = player_api:get_name(UserId),
							mail_api:send_system_mail_to_one(UserName, <<>>, <<>>, MailId, 
															 [{GoodsList2}], GoodsList, 0, 0, 0, 0);
						_ ->
							?MSG_ERROR("Honor title data not exist !",  [])
					end,
					?ok;
				_RecHonorTitle ->
					?ok
			end
	end.

%% 第一个镶嵌满16颗4级宝石的玩家
%% add_honor_title(Player, first_stone) when is_record(Player, player)->
%% 	case ets_api:lookup(?CONST_ETS_HONOR_TITLE, rec_honor_title) of
%% 		?null ->
%% 			?MSG_ERROR("Read data error!", []);
%% 		RecHonorTitle ->
%% 			FStone = RecHonorTitle#rec_honor_title.first_stone, 
%% 			if FStone =:= 0 ->
%% 				   {?ok, Player2} = achievement_api:add_achievement(Player, ?CONST_ACHIEVEMENT_FIRST_STONE, 0, 1),
%% 				   NewRecHonorTitle = RecHonorTitle#rec_honor_title{first_stone = Player#player.user_id},
%% 				   save_honor_title_data(NewRecHonorTitle),
%% 				   {?ok, Player2};
%% 			   ?true ->
%% 				   {?ok, Player}
%% 			end
%% 	end;

make_goods([{GoodsId, IsBind, Count}|Tail], OldList) ->
    case goods_api:make(GoodsId, IsBind, Count) of
        {?error, _} ->
            make_goods(Tail, OldList);
        GoodsList -> 
            make_goods(Tail, OldList++GoodsList)
    end;
make_goods([], List) ->
    List;
make_goods(_, OldList) ->
    OldList.

%% 同步保存荣誉榜ETS和mysql数据
save_honor_title_data(Player, HonorId) when is_record(Player, player) ->
	Info = Player#player.info,
	UserId = Player#player.user_id,
	UserName = Info#info.user_name,
	Lv = Info#info.lv,
	Pro = Info#info.pro,
	Sex = Info#info.sex,
	SkinFashion = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION),
    SkinWeapon  = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
    SkinArmor   = goods_style_api:get_cur_style(Player, ?CONST_GOODS_EQUIP_ARMOR),
	save_honor_title_data(HonorId, UserId, UserName, Lv, Pro, Sex, SkinFashion, SkinWeapon, SkinArmor);

save_honor_title_data(UserId, HonorId) when is_integer(UserId) ->
	case player_api:get_player_fields(UserId, [#player.info, #player.style]) of
		{?ok, [Info, Style]} ->
			UserName = Info#info.user_name,
			Lv = Info#info.lv,
			Pro = Info#info.pro,
			Sex = Info#info.sex,
			SkinFashion = goods_style_api:get_cur_style(Style, ?CONST_GOODS_EQUIP_FUSION),
			SkinWeapon  = goods_style_api:get_cur_style(Style, ?CONST_GOODS_EQUIP_FUSION_WEAPON),
			SkinArmor   = goods_style_api:get_cur_style(Style, ?CONST_GOODS_EQUIP_ARMOR),
			save_honor_title_data(HonorId, UserId, UserName, Lv, Pro, Sex, SkinFashion, SkinWeapon, SkinArmor);		
		_ ->
			?ok
	end.
				
save_honor_title_data(HonorId, UserId, UserName, Lv, Pro, Sex, Fashion, Weapon, Armor) ->
	RecHonorTitle = #rec_honor_title{
								  honor_id = HonorId,		% 荣誉榜ID
								  user_id = UserId,			% 玩家ID
								  user_name = UserName,		% 玩家名称
								  lv = Lv,					% 玩家等级
								  sex = Sex,				% 性别
								  pro = Pro,				% 职业
								  weapon = Weapon,			% 武器ID
								  fashion = Fashion,		% 时装ID
								  armor = Armor				% 衣服ID			
								 },

	ets_api:insert(?CONST_ETS_HONOR_TITLE, RecHonorTitle),
	mysql_api:insert(game_honor_title, 
					 [honor_id, user_id, user_name, lv, sex, pro, weapon, fashion, armor],
					 [HonorId, UserId, UserName, Lv, Sex, Pro, Weapon, Fashion, Armor]
					).

%% ==========================================================
%% 开服活动 -- 英雄榜
%% ==========================================================
%% 初始化ETS
select_data_hero() ->
	case mysql_api:select([type, rank, id, name, lv, pro, sex], 
						  game_hero_rank, []) of
		{?ok, List} ->
			F = fun([Type, Rank, Id, Name, Lv, Pro, Sex]) ->
						new_serv_api:insert_ets_hero_rank(Type, Rank, Id, Name, Lv, Pro, Sex, <<>>)
				end,
			lists:foreach(F, List);
		_ -> ?ok
	end.

%% 持久化英雄榜
save_data_hero() ->
    L = ets:tab2list(?CONST_ETS_HERO_RANK),
    save_data_hero(L).
save_data_hero([{{Type, Rank}, Id, Name, Lv, Pro, Sex, _GuildName}|Tail]) ->
    mysql_api:insert(<<"insert into `game_hero_rank`(`type`,`rank`,`id`,`name`,`lv`,`pro`,`sex`) values('", (misc:to_binary(Type))/binary, 
                       "', '", (misc:to_binary(Rank))/binary, "', '", (misc:to_binary(Id))/binary, "', '", (misc:to_binary(Name))/binary, 
                       "', '", (misc:to_binary(Lv))/binary, "', '", (misc:to_binary(Pro))/binary, "', '", (misc:to_binary(Sex))/binary, "');">>),
    save_data_hero(Tail);
save_data_hero([]) ->
    ?ok.

replace_ets(Type, Rank, UserId, UserName, Lv, Pro, Sex, GuildName) ->
    case ets_api:lookup(?CONST_ETS_HERO_RANK, {Type, Rank}) of
        {{_Type, _Rank}, _Id, _Name, _Lv, _Pro, _Sex, _} ->
            ?false;
        _ ->
            new_serv_api:insert_ets_hero_rank(Type, Rank, UserId, UserName, Lv, Pro, Sex, GuildName),
            ?true
    end.

update_hero_rank([?CONST_RANK_POWER, _Rank, UserId, UserName, Lv, _OtherId, _OtherName, Power, Pro, Sex], L, IsSend) ->
	{OldUserOneId, OldUserOneName, OldUserTwoId, OldUserTwoName, OldUserThreeId, OldUserThreeName} 
		= get_old_user(?CONST_NEW_SERV_TYPE_ZLPM, L),
	if 
        Power >= ?CONST_NEW_SERV_POWER_TEN ->
		   case replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_ONE, UserId, UserName, Lv, Pro, Sex, <<>>) of
               ?true ->
                   if OldUserOneId =:= UserId ->
                          ?ok;
                      ?true ->
                          send_mail(UserName, OldUserOneName, ?CONST_RANK_ONE, ?CONST_RANK_POWER, replace, IsSend),
                          send_mail(OldUserOneName, UserName, ?CONST_RANK_ONE, ?CONST_RANK_POWER, replaced, IsSend)
                   end;
               _ ->
                   case replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_TWO, UserId, UserName, Lv, Pro, Sex, <<>>) of
                       ?true ->
                           if OldUserTwoId =:= UserId ->
                                  ?ok;
                              ?true ->
                                  send_mail(UserName, OldUserTwoName, ?CONST_RANK_TWO, ?CONST_RANK_POWER, replace, IsSend),
                                  send_mail(OldUserTwoName, UserName, ?CONST_RANK_TWO, ?CONST_RANK_POWER, replaced, IsSend)
                           end;
                       _ ->
                           case replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_THREE, UserId, UserName, Lv, Pro, Sex, <<>>) of
                               ?true ->
                                   if OldUserThreeId =:= UserId ->
                                          ?ok;
                                      ?true ->
                                          send_mail(UserName, OldUserThreeName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replace, IsSend),
                                          send_mail(OldUserThreeName, UserName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replaced, IsSend)
                                   end;
                               _ ->
                                   ?ok
                            end
                   end
           end;
        Power >= ?CONST_NEW_SERV_POWER_NINE ->
			   case replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_TWO, UserId, UserName, Lv, Pro, Sex, <<>>) of
                   ?true ->
                       if OldUserTwoId =:= UserId ->
                              ?ok;
                          ?true ->
                              send_mail(UserName, OldUserTwoName, ?CONST_RANK_TWO, ?CONST_RANK_POWER, replace, IsSend),
                              send_mail(OldUserTwoName, UserName, ?CONST_RANK_TWO, ?CONST_RANK_POWER, replaced, IsSend)
                       end;
                   _ ->
                       case replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_THREE, UserId, UserName, Lv, Pro, Sex, <<>>) of
                           ?true ->
                               if OldUserThreeId =:= UserId ->
                                      ?ok;
                                  ?true ->
                                      send_mail(UserName, OldUserThreeName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replace, IsSend),
                                      send_mail(OldUserThreeName, UserName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replaced, IsSend)
                               end;
                           _ ->
                               ?ok
                        end
               end;
	    Power >= ?CONST_NEW_SERV_POWER_EIGHT ->
		   replace_ets(?CONST_NEW_SERV_TYPE_ZLPM, ?CONST_RANK_THREE, UserId, UserName, Lv, Pro, Sex, <<>>),
		   if OldUserThreeId =:= UserId ->
				  ?ok;
			  ?true ->
				  send_mail(UserName, OldUserThreeName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replace, IsSend),
				  send_mail(OldUserThreeName, UserName, ?CONST_RANK_THREE, ?CONST_RANK_POWER, replaced, IsSend)
		   end;
	   ?true ->
		   ?ok
	end;
update_hero_rank([?CONST_RANK_DEVILCOPY, Rank, UserId, UserName, Lv, _OtherId, _OtherName, _, Pro, Sex], _L, IsSend) ->
	{OldUserOneId, OldUserOneName, OldUserTwoId, OldUserTwoName, OldUserThreeId, OldUserThreeName} 
					= get_old_user_22(?CONST_NEW_SERV_TYPE_PZPM),
    PassId = tower_api:get_top_pass(UserId),
	if Rank < 4 andalso PassId >= ?CONST_NEW_SERV_HERO_CAMP_MIN ->
		   new_serv_api:insert_ets_hero_rank(?CONST_NEW_SERV_TYPE_PZPM, 
											 Rank, UserId, UserName, Lv, Pro, Sex, <<>>),
		   case Rank of 
			   ?CONST_RANK_ONE ->
				   if OldUserOneId =:= UserId ->
						  ?ok;
					  ?true ->
						  send_mail(UserName, OldUserOneName, Rank, ?CONST_RANK_DEVILCOPY, replace, IsSend),
						  send_mail(OldUserOneName, UserName, Rank, ?CONST_RANK_DEVILCOPY, replaced, IsSend)
				   end;
			   ?CONST_RANK_TWO ->
				   if OldUserTwoId =:= UserId ->
						  ?ok;
					  ?true ->
						  send_mail(UserName, OldUserTwoName, Rank, ?CONST_RANK_DEVILCOPY, replace, IsSend),
						  send_mail(OldUserTwoName, UserName, Rank, ?CONST_RANK_DEVILCOPY, replaced, IsSend)
				   end;
			   ?CONST_RANK_THREE ->
				   if OldUserThreeId =:= UserId ->
						  ?ok;
					  ?true ->
						  send_mail(UserName, OldUserThreeName, Rank, ?CONST_RANK_DEVILCOPY, replace, IsSend),
						  send_mail(OldUserThreeName, UserName, Rank, ?CONST_RANK_DEVILCOPY, replaced, IsSend)
				   end
		   end;
	   ?true ->
		   ?ok
	end;
update_hero_rank([_, _Rank, _UserId, _UserName, _Lv, _OtherId, _OtherName, _, _, _], _, _IsSend) ->
    ?ok.

update_guild_power_hero_rank([[GuildId, GLv, _Power]|Tail], L, IsSend) ->
    {OldGuildOneId, _OldUserOneName, OldGuildTwoId, _OldUserTwoName, OldGuildThreeId, _OldUserThreeName} 
                    = get_old_user(?CONST_NEW_SERV_TYPE_JTPM, L),
    {_, NewChiefName} = guild_api:get_guild_chief_name(GuildId),
    {_, NewChiefId} = guild_api:get_guild_chief_id(GuildId),
    NewGuildName = guild_api:get_guild_name(GuildId),
    {Pro, Sex} = 
        case player_api:get_player_fields(NewChiefId, [#player.info]) of
            {?ok, [Info]} ->
                {Info#info.pro, Info#info.sex};
            _ ->
                {1, 1}
        end,
%%     ?MSG_DEBUG("~p", [{OldGuildOneId, OldGuildTwoId, OldGuildThreeId, GuildId}]),
    if 
        GLv >= ?CONST_NEW_SERV_GLV_LIMIT_LOWER ->
           case replace_ets(?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_ONE, GuildId, NewChiefName, GLv, Pro, Sex, NewGuildName) of
               ?true ->
                   if OldGuildOneId =:= GuildId ->
                          ?ok;
                      ?true ->
                          {_, OldChiefName} = guild_api:get_guild_chief_name(OldGuildOneId),
                          send_mail(NewChiefName, OldChiefName, ?CONST_RANK_ONE, ?CONST_RANK_GUILD_POWER, replace, IsSend),
                          send_mail(OldChiefName, NewChiefName, ?CONST_RANK_ONE, ?CONST_RANK_GUILD_POWER, replaced, IsSend)
                   end;
               _ ->
                   case replace_ets(?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_TWO, GuildId, NewChiefName, GLv, Pro, Sex, NewGuildName) of
                       ?true ->
                           if OldGuildTwoId =:= GuildId ->
                                  ?ok;
                              ?true ->
                                  {_, OldChiefName} = guild_api:get_guild_chief_name(OldGuildTwoId),
                                  send_mail(NewChiefName, OldChiefName, ?CONST_RANK_TWO, ?CONST_RANK_GUILD_POWER, replace, IsSend),
                                  send_mail(OldChiefName, NewChiefName, ?CONST_RANK_TWO, ?CONST_RANK_GUILD_POWER, replaced, IsSend)
                           end;
                       _ ->
                           case replace_ets(?CONST_NEW_SERV_TYPE_JTPM, ?CONST_RANK_THREE, GuildId, NewChiefName, GLv, Pro, Sex, NewGuildName) of
                               ?true ->
                                   if OldGuildThreeId =:= GuildId ->
                                          ?ok;
                                      ?true ->
                                          {_, OldChiefName} = guild_api:get_guild_chief_name(OldGuildThreeId),
                                          send_mail(NewChiefName, OldChiefName, ?CONST_RANK_THREE, ?CONST_RANK_GUILD_POWER, replace, IsSend),
                                          send_mail(OldChiefName, NewChiefName, ?CONST_RANK_THREE, ?CONST_RANK_GUILD_POWER, replaced, IsSend)
                                   end;
                               _ ->
                                   ?ok
                            end
                   end
           end;
       ?true ->
           ?ok
    end,
    update_guild_power_hero_rank(Tail, L, IsSend);
update_guild_power_hero_rank([], _L, _IsSend) ->
    ?ok.

get_old_user(Type, L) ->
    case lists:keyfind({Type, ?CONST_RANK_ONE}, 1, L) of
        {_, OldUserOneId, OldUserOneName, _, _, _, _} ->
            case lists:keyfind({Type, ?CONST_RANK_TWO}, 1, L) of
                {_, OldUserTwoId, OldUserTwoName, _, _, _, _} ->
                    case lists:keyfind({Type, ?CONST_RANK_THREE}, 1, L) of
                        {_, OldUserThreeId, OldUserThreeName,_,  _, _, _} ->
                        	{OldUserOneId, OldUserOneName, OldUserTwoId, OldUserTwoName, OldUserThreeId, OldUserThreeName};
                        _ ->
                            {OldUserOneId, OldUserOneName, OldUserTwoId, OldUserTwoName, 0, <<>>}
                    end;
                _ ->
                    {OldUserOneId, OldUserOneName, 0, <<>>, 0, <<>>}
            end;
        _ ->
            {0, <<>>, 0, <<>>, 0, <<>>}
    end.

get_old_user_22(Type) ->
    {_, _, OldUserOneId, OldUserOneName, _, _, _, _} = new_serv_api:get_hero_rank_info(Type, ?CONST_RANK_ONE),
    {_, _, OldUserTwoId, OldUserTwoName, _, _, _, _} = new_serv_api:get_hero_rank_info(Type, ?CONST_RANK_TWO),
    {_, _, OldUserThreeId, OldUserThreeName, _, _, _, _} = new_serv_api:get_hero_rank_info(Type, ?CONST_RANK_THREE),
    {OldUserOneId, OldUserOneName, OldUserTwoId, OldUserTwoName, OldUserThreeId, OldUserThreeName}.

%% clear_hero_rank(Type) ->
%% 	ets_api:delete(?CONST_ETS_HERO_RANK, {Type, ?CONST_RANK_ONE}),
%% 	ets_api:delete(?CONST_ETS_HERO_RANK, {Type, ?CONST_RANK_TWO}),
%% 	ets_api:delete(?CONST_ETS_HERO_RANK, {Type, ?CONST_RANK_THREE}),
%% 	?ok.
	
send_mail(_, _,  _, _, _, ?CONST_SYS_FALSE) -> ?ok;	
send_mail(ReceiveName, <<>>,  Rank, Type, replace, _) ->	
	Content		= [{[{misc:to_list(Rank)}]}],
	case Type of
		?CONST_RANK_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1500, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_POWER);
		?CONST_RANK_GUILD_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1550, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_GUILD);
		?CONST_RANK_DEVILCOPY ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1600, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_TOWER)
	end;
send_mail(ReceiveName, 0,  Rank, Type, replace, _) ->	
	Content		= [{[{misc:to_list(Rank)}]}],
	case Type of
		?CONST_RANK_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1500, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_POWER);
		?CONST_RANK_GUILD_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1550, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_GUILD);
		?CONST_RANK_DEVILCOPY ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, 1600, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_TOWER)
	end;
send_mail(ReceiveName, UserName,  Rank, Type, replace, _) ->	
	Content		= [{[{misc:to_list(UserName)}]}] ++ [{[{misc:to_list(Rank)}]}],
	case Type of
		?CONST_RANK_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_POWER_REPLACE, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_POWER);
		?CONST_RANK_GUILD_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_GUILD_REPLACE, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_GUILD);
		?CONST_RANK_DEVILCOPY ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_DEVILCOPY_REPLACE, Content,
												[], 0, 0, 0, ?CONST_COST_NEW_SERV_HERO_TOWER)
	end;
send_mail(<<>>, _UserName, _Rank, _Type, replaced, _) ->	
	?ok;
send_mail(0, _UserName, _Rank, _Type, replaced, _) ->	
	?ok;
send_mail(ReceiveName, UserName, Rank, Type, replaced, _) ->	
	Content		=  [{[{misc:to_list(Rank)}]}] ++ [{[{misc:to_list(UserName)}]}],
	case Type of
		?CONST_RANK_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_POWER_REPLACED, Content,
												[], 0, 0, 0, 0);
		?CONST_RANK_GUILD_POWER ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_GUILD_REPLACED, Content,
												[], 0, 0, 0, 0);
		?CONST_RANK_DEVILCOPY ->
			mail_api:send_interest_mail_to_one2(ReceiveName, <<>>, <<>>, ?CONST_MAIL_DEVILCOPY_REPLACED, Content,
												[], 0, 0, 0, 0)
	end.
	

%% ================================================================
%% 运营活动 -- 现金兑换令
%% ================================================================
exchange_cash(Player, RecvName, BankName, CardId, BankAddr, Phone) ->
	UserId				= Player#player.user_id,
	Info				= Player#player.info,
	UserName			= Info#info.user_name,
	Account				= Player#player.account,
	ServId				= Player#player.serv_id,
	Container			= Player#player.bag,
	Time				= misc:seconds(),
	try
		case ctn_bag2_api:get_by_id(UserId, Container, ?CONST_NEW_SERV_EXCHANGE_CASH, 1) of
			{?ok, Container2, _, Packet} ->
				case mysql_api:insert_execute(<<"INSERT INTO `techcenter_exchange_cash` ",
												"(`user_id`, `user_name`, `serv_id`, `account`,",
												" `recv_name`, `bank_name`, `bank_id`, `bank_addr`, `phone`, `time`)",
												" VALUES (",
												" '", (misc:to_binary(UserId))/binary,"',",
												" '", (misc:to_binary(UserName))/binary,"',",
												" '", (misc:to_binary(ServId))/binary,"',",
												" '", (misc:to_binary(Account))/binary,"',",
												" '", (misc:to_binary(RecvName))/binary,"',",
												" '", (misc:to_binary(BankName))/binary,"',",
												" '", (misc:to_binary(CardId))/binary,"',",
												" '", (misc:to_binary(BankAddr))/binary,"',",
												" '", (misc:to_binary(Phone))/binary,"',",
												" '", (misc:to_binary(Time))/binary,"');">>) of
					{?ok, _Affect, _} ->
						insert_exchange_info(ServId, UserName, 1, Time),
						NewPlayer			= Player#player{bag = Container2},
						TipPacket			= message_api:msg_notice(?TIP_OP_EXCHANGE),
						misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
						{?ok, NewPlayer};
					_ ->
						TipPacket			= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
						misc_packet:send(Player#player.net_pid, TipPacket),
						{?ok, Player}
				end;
			{?error, _ErrorCode} ->
				{?ok, Player}
		end
	catch
		Error:Reason ->
			?MSG_DEBUG("~n, Error=~p, Reason=~p", [Error, Reason]),
			ErrorPacket		= message_api:msg_notice(?TIP_OP_INFO_CORRECT),
			misc_packet:send(Player#player.net_pid, ErrorPacket),
			{?ok, Player}
	end.

%% ================================================================
%% 运营活动 -- 实物兑换令
%% ================================================================
exchange_goods(Player, RecvName, RecvAddr, Phone, Remark) ->
	UserId				= Player#player.user_id,
	Info				= Player#player.info,
	UserName			= Info#info.user_name,
	Account				= Player#player.account,
	ServId				= Player#player.serv_id,
	Container			= Player#player.bag,
	Time				= misc:seconds(),
	try
		case ctn_bag2_api:get_by_id(UserId, Container, ?CONST_NEW_SERV_EXCHANGE_GOODS, 1) of
			{?ok, Container2, _, Packet} ->
				case mysql_api:insert_execute(<<"INSERT INTO `techcenter_exchange_goods` ",
												"(`user_id`, `user_name`, `serv_id`, `account`,",
												" `recv_name`, `recv_addr`, `phone`, `remark`, `time`)",
												" VALUES (",
												" '", (misc:to_binary(UserId))/binary,"',",
												" '", (misc:to_binary(UserName))/binary,"',",
												" '", (misc:to_binary(ServId))/binary,"',",
												" '", (misc:to_binary(Account))/binary,"',",
												" '", (misc:to_binary(RecvName))/binary,"',",
												" '", (misc:to_binary(RecvAddr))/binary,"',",
												" '", (misc:to_binary(Phone))/binary,"',",
												" '", (misc:to_binary(Remark))/binary,"',",
												" '", (misc:to_binary(Time))/binary,"');">>) of
					{?ok, _Affect, _} ->
						insert_exchange_info(ServId, UserName, 2, Time),
						NewPlayer			= Player#player{bag = Container2},
						TipPacket			= message_api:msg_notice(?TIP_OP_EXCHANGE),
						misc_packet:send(Player#player.net_pid, <<Packet/binary, TipPacket/binary>>),
						{?ok, NewPlayer};
					_ ->
						TipPacket			= message_api:msg_notice(?TIP_COMMON_ERROR_DB),
						misc_packet:send(Player#player.net_pid, TipPacket),
						{?ok, Player}
				end;
			{?error, _ErrorCode} ->
				{?ok, Player}
		end
	catch
		Error:Reason ->
			?MSG_DEBUG("~n, Error=~p, Reason=~p", [Error, Reason]),
			ErrorPacket		= message_api:msg_notice(?TIP_OP_INFO_CORRECT),
			misc_packet:send(Player#player.net_pid, ErrorPacket),
			{?ok, Player}
	end.

%% ================================================================
%% 运营活动 -- 获奖名单
%% ================================================================
exchange_info(Player) ->
	Data		=case ets_api:lookup(?CONST_ETS_EXCHANGE_INFO, exchange_info) of
					 ?null -> [];
					 #exchange_info{list = List} -> List
				 end,
	?MSG_DEBUG("~n Data=~p", [Data]),
	Packet		= new_serv_api:msg_sc_exchange_info(Data),
	misc_packet:send(Player#player.net_pid, Packet).

insert_exchange_info(ServId, UserName, Type, Time) ->
	case ets_api:lookup(?CONST_ETS_EXCHANGE_INFO, exchange_info) of
		?null ->
			?MSG_DEBUG("~n 111111111111111111", []),
			Data			= #exchange_info{list = [{ServId, UserName, Type, Time}]},
			ets_api:insert(?CONST_ETS_EXCHANGE_INFO, Data);
		#exchange_info{list = List} ->
			Len			= length(List),
			case Len >= 10 of
				?true ->
					[_Head|Tail]	= List,
					NewList			= Tail	++ [{ServId, UserName, Type, Time}],
					Data			= #exchange_info{list = NewList},
					?MSG_DEBUG("~n NewList=~p", [NewList]),
					ets_api:insert(?CONST_ETS_EXCHANGE_INFO, Data);
				?false ->
					NewList			= List ++ [{ServId, UserName, Type, Time}],
					Data			= #exchange_info{list = NewList},
					?MSG_DEBUG("~n NewList=~p", [NewList]),
					ets_api:insert(?CONST_ETS_EXCHANGE_INFO, Data)
			end
	end.
