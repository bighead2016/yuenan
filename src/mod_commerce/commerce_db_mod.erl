%% Author: Administrator
%% Created: 2012-9-18
%% Description: TODO: Add description to commerce_db_mod
-module(commerce_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.data.hrl").

%%
%% Exported Functions
%%
-export([create_market/1, read_market/0, delete_market/1,read_commerce/0,
		 create_caravan/1, read_caravan/1, read_caravan/0, write_caravan/1, delete_caravan/1,
		 create_commerce/1, read_commerce/1, write_commerce/1, delete_commerce/1]).

%%
%% API Functions
%%
create_market(Market)	->
	UserId		= Market#commerce_market.user_id,
	UserName	= Market#commerce_market.user_name,
	StartTime	= Market#commerce_market.start_time,
	EndTime		= Market#commerce_market.end_time,
	case mysql_api:insert_execute(<<"INSERT INTO `game_commerce_market` ",
									"(`user_id`, `user_name`, `start_time`, `end_time`)",
									" VALUES (",
									" '", (misc:to_binary(UserId))/binary, "',",
									" '", (misc:to_binary(UserName))/binary, "',",
									" '", (misc:to_binary(StartTime))/binary, "',",
									" '", (misc:to_binary(EndTime))/binary, "');">>) of
		{?ok, _Affect, Id}	->
			?MSG_WARNING("~nID=~p~n", [Id]),
			{?ok, Id};
		X	->
			?MSG_WARNING("~nX=~p~n", [X]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

read_market()	->
	case mysql_api:select_execute(<<"SELECT `id`, `user_id`, `user_name`, `start_time`, `end_time` ",
									"FROM `game_commerce_market`;">>) of
		{?ok, DataList}	->
			Fun	= fun(Data, Acc)	->
						  [Id, UserId, UserName, StartTime, EndTime]	= Data,
						  Market	= #commerce_market{id			= Id,
													   user_id		= UserId,
													   user_name	= UserName,
													   start_time	= StartTime,
													   end_time		= EndTime},
						  Acc ++ [Market]
				  end,
			MarketList	= lists:foldl(Fun, [], DataList),
			{?ok, MarketList};
		_Other	->
			{?ok, ?null}
	end.

delete_market(Id)	->
	mysql_api:fetch_cast(<<"DELETE FROM ", "`game_commerce_market`", " WHERE `id` = ", (misc:to_binary(Id))/binary, ";">>).

create_caravan(Caravan)	->
	Quality		= Caravan#caravan.quality,
	Name		= Caravan#caravan.name,
	UserId		= Caravan#caravan.user_id,
	UserName	= Caravan#caravan.user_name,
	Pro			= Caravan#caravan.pro,
	Sex			= Caravan#caravan.sex,
	Lv			= Caravan#caravan.lv,
	GuildId		= Caravan#caravan.guild_id,
	GuildName	= Caravan#caravan.guild_name,
	FriendId	= Caravan#caravan.friend_id,
	FriendName	= Caravan#caravan.friend_name,
	StartTime	= Caravan#caravan.start_time,
	EndTime		= Caravan#caravan.end_time,
	Battling	= Caravan#caravan.battling,
	Failure		= Caravan#caravan.failure,
	Robber		= misc:encode(Caravan#caravan.robber),
	Market		= Caravan#caravan.market,
	Guild		= Caravan#caravan.guild,
	Factor		= Caravan#caravan.factor,
	case mysql_api:insert_execute(<<"INSERT INTO `game_caravan` ",
									"(`quality`, `name`, `user_id`, `user_name`, `pro`,",
									" `sex`, `lv`, `guild_id`, `guild_name`, `friend_id`,",
									" `friend_name`, `start_time`, `end_time`, `battling`,",
									" `failure`, `robber`, `market`, `guild`, `factor`)",
									" VALUES (",
									" '", (misc:to_binary(Quality))/binary, "',",
									" '", (misc:to_binary(Name))/binary, "',",
									" '", (misc:to_binary(UserId))/binary, "',",
									" '", (misc:to_binary(UserName))/binary, "',",
									" '", (misc:to_binary(Pro))/binary, "',",
									" '", (misc:to_binary(Sex))/binary, "',",
									" '", (misc:to_binary(Lv))/binary, "',",
									" '", (misc:to_binary(GuildId))/binary, "',",
									" '", (misc:to_binary(GuildName))/binary, "',",
									" '", (misc:to_binary(FriendId))/binary, "',",
									" '", (misc:to_binary(FriendName))/binary, "',",
									" '", (misc:to_binary(StartTime))/binary, "',",
									" '", (misc:to_binary(EndTime))/binary, "',",
									" '", (misc:to_binary(Battling))/binary, "',",
									" '", (misc:to_binary(Failure))/binary, "',",
									" '", Robber/binary, "',",
									" '", (misc:to_binary(Market))/binary, "',",
									" '", (misc:to_binary(Guild))/binary, "',",
									" '", (misc:to_binary(Factor))/binary, "');">>) of
		{?ok, _Affect, Id}	->
			?MSG_WARNING("~nID=~p~n", [Id]),
			{?ok, Id};
		X	->
			?MSG_WARNING("~nX=~p~n", [X]),
			{?error, ?TIP_COMMON_ERROR_DB}
	end.

read_caravan() ->
	case mysql_api:select_execute(<<"SELECT `id`, `quality`, `name`, `user_id`, `user_name`, `pro`,
											`sex`, `lv`, `guild_id`, `guild_name`, `friend_id`,
											`friend_name`, `start_time`, `end_time`, `battling`,
											`failure`, `robber`, `market`, `guild`, `factor`",
									"  FROM `game_caravan`;">>) of
		{?ok, DataList}	->
			Fun	= fun(Data, Acc)	->
						  [Id, Quality, Name, UserId, UserName, Pro, Sex, Lv, GuildId,
						   GuildName, FriendId, FriendName, StartTime, EndTime, Battling,
						   Failure, BinRobber, Market, Guild, Factor]	= Data,
%% 						  ?MSG_DEBUG("~nBinRobber=~p~n", [BinRobber]),
						  Robber	= misc:decode(BinRobber),
%% 						  ?MSG_DEBUG("~nRobber=~p~n", [Robber]),
%% 						  ?MSG_DEBUG("~nId=~p~nQuality=~p~nName=~p~nUserId=~p~nUserName=~p~nPro=~p~nSex=~p~nLv=~p~nGuildId=~p~nGuildName=~p~nFriendId=~p~nFriendName=~p~nStartTime=~p~nEndTime=~p~nBattling=~p~nFailure=~p~nRobber=~p~nMarket=~p~nGuild=~p~nFactor=~p~n",
%% 									 [Id, Quality, Name, UserId, UserName, Pro, Sex, Lv, GuildId, GuildName, FriendId, FriendName, StartTime, EndTime, Battling, Failure, Robber, Market, Guild, Factor]),
						  Caravan	= #caravan{id				= Id,
														 quality		= Quality,
														 name			= Name,
														 user_id		= UserId,
														 user_name		= UserName,
														 pro			= Pro,
														 sex			= Sex,
														 lv				= Lv,
														 guild_id		= GuildId,
														 guild_name		= GuildName,
														 friend_id		= FriendId,
														 friend_name	= FriendName,
														 start_time		= StartTime,
														 end_time		= EndTime,
														 battling		= Battling,
														 failure		= Failure,
														 robber			= Robber,
														 market			= Market,
														 guild			= Guild,
														 factor			= Factor},
						  Acc ++ [Caravan]
				  end,
			CaravanList	= lists:foldl(Fun, [], DataList),
			{?ok, CaravanList};
		_ ->
			{?ok, ?null}
	end.

read_caravan(UserId) ->
	case mysql_api:select_execute(<<"SELECT `id`, `quality`, `name`, `user_id`, `user_name`, `pro`,
											`sex`, `lv`, `guild_id`, `guild_name`, `friend_id`,
											`friend_name`, `start_time`, `end_time`, `battling`,
											`failure`, `robber`, `market`, `guild`, `factor`",
									"  FROM `game_caravan` WHERE `user_id` = ",
									(misc:to_binary(UserId))/binary, ";">>) of
		{?ok, [[Id, Quality, Name, UserId, UserName, Pro, Sex, Lv, GuildId,
				GuildName, FriendId, FriendName, StartTime, EndTime, Battling,
				Failure, BinRobber, Market, Guild, Factor] | _]} ->
%% 			?MSG_DEBUG("~nBinRobber=~p~n", [BinRobber]),
			Robber	= misc:decode(BinRobber),
%% 			?MSG_DEBUG("~nRobber=~p~n", [Robber]),
%% 			?MSG_DEBUG("~nId=~p~nQuality=~p~nName=~p~nUserId=~p~nUserName=~p~nPro=~p~nSex=~p~nLv=~p~nGuildId=~p~nGuildName=~p~nFriendId=~p~nFriendName=~p~nStartTime=~p~nEndTime=~p~nBattling=~p~nFailure=~p~nRobber=~p~nMarket=~p~nGuild=~p~nFactor=~p~n",
%% 					   [Id, Quality, Name, UserId, UserName, Pro, Sex, Lv, GuildId, GuildName, FriendId, FriendName, StartTime, EndTime, Battling, Failure, Robber, Market, Guild, Factor]),
			{?ok, #caravan{id					= Id,
								 quality			= Quality,
								 name				= Name,
								 user_id			= UserId,
								 user_name			= UserName,
								 pro				= Pro,
								 sex				= Sex,
								 lv					= Lv,
								 guild_id			= GuildId,
								 guild_name			= GuildName,
								 friend_id			= FriendId,
								 friend_name		= FriendName,
								 start_time			= StartTime,
								 end_time			= EndTime,
								 battling			= Battling,
								 failure			= Failure,
								 robber				= Robber,
								 market				= Market,
								 guild				= Guild,
								 factor				= Factor}};
		_ ->
			{?ok, ?null}
	end.

write_caravan(Caravan) ->
	?MSG_DEBUG("~nCaravan=~p~n", [Caravan]),
	mysql_api:update(game_caravan,
					 [{start_time,	Caravan#caravan.start_time},
					  {end_time,	Caravan#caravan.end_time},
					  {battling,	Caravan#caravan.battling},
					  {failure,		Caravan#caravan.failure},
					  {robber,		misc:encode(Caravan#caravan.robber)}],
					 [{id,			Caravan#caravan.id}]).

delete_caravan(Id)->
	mysql_api:fetch_cast(<<"DELETE FROM ", "`game_caravan`", " WHERE `id` = ", (misc:to_binary(Id))/binary, ";">>).

create_commerce(Commerce) ->
	?MSG_DEBUG("~nCommerce=~p~n", [Commerce]),
	mysql_api:insert(game_commerce,
					 [{user_id,			Commerce#commerce.user_id},
					  {date,			Commerce#commerce.date},
					  {carry,			Commerce#commerce.carry},
					  {escort,			Commerce#commerce.escort},
					  {rob,				Commerce#commerce.rob},
					  {vip_rob,			Commerce#commerce.vip_rob},
					  {freerefresh,		Commerce#commerce.freerefresh},
					  {refresh,			Commerce#commerce.refresh},
					  {quality,			Commerce#commerce.quality},
					  {carry_time,		Commerce#commerce.carry_time},
					  {escort_time,		Commerce#commerce.escort_time},
					  {rob_time,		Commerce#commerce.rob_time},
					  {flag_invite,		Commerce#commerce.flag_invite}]).

read_commerce(UserId) ->
	case mysql_api:select_execute(<<"SELECT `user_id`, `date`, `carry`, `escort`, `rob`,
											`vip_rob`, `freerefresh`, `refresh`, `quality`,
											`carry_time`, `escort_time`, `rob_time`, `flag_invite`",
									"  FROM `game_commerce` WHERE `user_id` = ",
									(misc:to_binary(UserId))/binary, ";">>) of
		{?ok, [[UserId, Date, Carry, Escort, Rob, VipRob, FreeRefresh,
				Refresh, Quality, CarryTime, EscortTime, RobTime, FlagInvite] | _]} ->
			{?ok, #commerce{user_id			= UserId,
								   date				= Date,
								   carry			= Carry,
								   escort			= Escort,
								   rob				= Rob,
								   vip_rob			= VipRob,
								   freerefresh		= FreeRefresh,
								   refresh			= Refresh,
								   quality			= Quality,
								   carry_time		= CarryTime,
								   escort_time		= EscortTime,
								   rob_time			= RobTime,
								   flag_invite		= FlagInvite}};
		_ ->
			{?ok, ?null}
	end.

write_commerce(Commerce) ->
	UserId			= Commerce#commerce.user_id,
	BinUserId		= misc:to_binary(Commerce#commerce.user_id),
	BinDate			= misc:to_binary(Commerce#commerce.date),
	BinCarry		= misc:to_binary(Commerce#commerce.carry),
	BinEscort		= misc:to_binary(Commerce#commerce.escort),
	BinRob			= misc:to_binary(Commerce#commerce.rob),
	BinVipRob		= misc:to_binary(Commerce#commerce.vip_rob),
	BinFreeRefresh	= misc:to_binary(Commerce#commerce.freerefresh),
	BinRefresh		= misc:to_binary(Commerce#commerce.refresh),
	BinQuality		= misc:to_binary(Commerce#commerce.quality),
	BinCarryTime	= misc:to_binary(Commerce#commerce.carry_time),
	BinEscortTime	= misc:to_binary(Commerce#commerce.escort_time),
	BinRobTime		= misc:to_binary(Commerce#commerce.rob_time),
	BinFlagInvite	= misc:to_binary(Commerce#commerce.flag_invite),
	mysql_api:fetch_cast(<<"UPDATE `game_commerce` SET ",
						    "  `user_id`        = ", BinUserId/binary,
                            ", `date`           = ", BinDate/binary,
                            ", `carry`          = ", BinCarry/binary,
                            ", `escort`         = ", BinEscort/binary,
                            ", `rob`            = ", BinRob/binary,
						    ", `vip_rob`        = ", BinVipRob/binary,
                            ", `freerefresh`    = ", BinFreeRefresh/binary,
                            ", `refresh`        = ", BinRefresh/binary,
						    ", `quality`        = ", BinQuality/binary,
						    ", `carry_time`     = ", BinCarryTime/binary,
						    ", `escort_time`    = ", BinEscortTime/binary,
                            ", `rob_time`       = ", BinRobTime/binary,
                            ", `flag_invite`    = ", BinFlagInvite/binary,
						    " WHERE `user_id`   = ", (misc:to_binary(UserId))/binary, ";">>).

delete_commerce(UserId)->
	mysql_api:fetch_cast(<<"DELETE FROM ", "`game_commerce`", " WHERE `user_id` = ", (misc:to_binary(UserId))/binary, ";">>).

read_commerce() ->
	FieldList = [user_id, date, carry, escort, rob, vip_rob, freerefresh, refresh, quality, carry_time, 
				 escort_time, rob_time, flag_invite],
	case mysql_api:select(FieldList, game_commerce) of
		{?ok, CommerceList} ->
			F = fun([UserId, Date, Carry, Escort, Rob, VipRob, Freerefresh, Refresh, Quality, CarryTime,
					 EscortTime, RobTime, FlagInvite]) ->
						Commerce	=
							#commerce{user_id			= UserId,
									  date				= Date,
									  carry				= Carry,
									  escort			= Escort,
									  rob				= Rob,
									  vip_rob			= VipRob,
									  freerefresh		= Freerefresh,
									  refresh			= Refresh,
									  quality			= Quality,
									  carry_time		= CarryTime,
									  escort_time		= EscortTime,
									  rob_time			= RobTime,
									  flag_invite		= FlagInvite
									 },
						ets:insert(?CONST_ETS_COMMERCE, Commerce)
				end,
			[F(Commerce)|| Commerce <- CommerceList];
		{?error, ErrorCode} ->
			?MSG_DEBUG("~nErrorCode=~p", [ErrorCode])
	end,
	?ok.

