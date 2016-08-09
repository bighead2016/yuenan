%% Author: Administrator
%% Created: 2012-8-14
%% Description: TODO: Add description to rank_db_mod
-module(rank_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%%
-export([
		 select_brocast/0,replace_player_data/10,replace_equip_data/11,
		 replace_partner/10,update_partner_flag/2,update_equip_flag/2,
		 update_partner_time/2,update_equip_time/2, replace_horse/8]).

-export([
		select_new_serv_arena/0,
		select_new_serv_power/0,
        select_top10_power_player/0,
		select_new_serv_tower/0,
		select_new_serv_lv/0,
        get_all_rank_data/0,
        get_avg_lv/0,
        get_guild_rank_data/0
		]).

%%
%% API Functions
%%
replace_player_data(UserId,Info,Title,Pos,GuildName,EliteCopy,EliteTime,DevilCopy,DevilTime,Power) ->
	UserName	= Info#info.user_name,
	Pro 		= Info#info.pro,
	Sex 		= Info#info.sex,
	Lv 			= Info#info.lv,
	Exp 		= Info#info.exp,
	ExpTime		= Info#info.exp_time,
	Meritorioust= Info#info.meritorioust,
	Vip         = player_api:get_vip_lv(Info),
	Cash		= case player_money_api:read_cash_sum(UserId) of
					  {?ok,CashSum} -> CashSum;
					  _ -> 0
				  end,
	mysql_api:fetch_cast(<<"REPLACE INTO `game_player_rank` ",
						    "( `user_id`,`user_name`,`pro`,`sex`,`lv`,`position`,`exp`,`exp_time`,`power`,`vip`,`cash`,
							 `title`,`elite_copy`,`elite_time`,`devil_copy`,`devil_time`,`meritorioust`,`guild_name`)",
						     " VALUES ('", 	(misc:to_binary(UserId))/binary,"','",  	% UserId
						   					(misc:to_binary(UserName))/binary,"','",  	% UserName
						   					(misc:to_binary(Pro))/binary,"','",  		% Pro						   
						   					(misc:to_binary(Sex))/binary,"','",  		% Sex
						   					(misc:to_binary(Lv))/binary,"','",  		% Lv
						   					(misc:to_binary(Pos))/binary,"','",  		% Pos
						   					(misc:to_binary(Exp))/binary,"','",  		% Exp
						   					(misc:to_binary(ExpTime))/binary,"','",  	% ExpTime
						   					(misc:to_binary(Power))/binary,"','",  		% Power
						   					(misc:to_binary(Vip))/binary,"','",  		% Vip
						   					(misc:to_binary(Cash))/binary,"','",  		% Cash
						   					(misc:to_binary(Title))/binary,"','",  		% Title
						   					(misc:to_binary(EliteCopy))/binary,"','",  	% EliteCopy
						   					(misc:to_binary(EliteTime))/binary,"','",  	% EliteTime
						   					(misc:to_binary(DevilCopy))/binary,"','",  	% DevilCopy
						   					(misc:to_binary(DevilTime))/binary,"','",  	% DevilTime
						   					(misc:to_binary(Meritorioust))/binary,"','",% Meritorioust
						   					(misc:to_binary(GuildName))/binary, 		% GuildName           						
						   "'); ">>).

replace_partner(PartnerId,PartnerName,Pro,Power,Color,UserId,UserName,Flag,Time,Lv) ->
	mysql_api:fetch_cast(<<"REPLACE INTO `game_rank_partner` ",
	"( `partner_id`,`partner_name`,`partner_pro`,`partner_power`,`partner_color`,`user_id`,`online_flag`,`time`,`lv`,`user_name`)",
	 " VALUES ('", 	(misc:to_binary(PartnerId))/binary,"','",  	% PartnerId
					(misc:to_binary(PartnerName))/binary,"','", % PartnerName
					(misc:to_binary(Pro))/binary,"','",  		% Pro						   
					(misc:to_binary(Power))/binary,"','",  		% Power
					(misc:to_binary(Color))/binary,"','",  		% Color
					(misc:to_binary(UserId))/binary,"','",  	% UserId
					(misc:to_binary(Flag))/binary,"','",  		% Flag
					(misc:to_binary(Time))/binary,"','",  		% Time
					(misc:to_binary(Lv))/binary,"','",  		% Lv
					(misc:to_binary(UserName))/binary, 			% UserName           						
   "'); " >>).

replace_equip_data(UserId,Info,Title,PartnerId,EquipType,EquipId,EquipPower,EquipColor,EquipLv,Flag,Time) ->
	UserName	= Info#info.user_name,
	Pro 		= Info#info.pro,
	Sex 		= Info#info.sex,
	Lv 			= Info#info.lv,
	Vip         = player_api:get_vip_lv(Info),
	mysql_api:fetch_cast(<<"REPLACE INTO `game_rank_equip` ",
    "( `user_id` ,`user_name` ,`pro` ,`sex` ,`vip` ,`lv` ,`title` ,`partner_id` ,`equip_type` ,`equip_id` ,`equip_power`,`equip_color`,`equip_lv`,`online_flag`,`time`)",
	 " VALUES ('", 	(misc:to_binary(UserId))/binary,"','",  	% UserId
					(misc:to_binary(UserName))/binary,"','",  	% UserName
					(misc:to_binary(Pro))/binary,"','",  		% Pro						   
					(misc:to_binary(Sex))/binary,"','",  		% Sex
	  				(misc:to_binary(Vip))/binary,"','",  		% Vip
					(misc:to_binary(Lv))/binary,"','",  		% Lv
					(misc:to_binary(Title))/binary,"','",  		% Title
					(misc:to_binary(PartnerId))/binary,"','",  	% PartnerId
					(misc:to_binary(EquipType))/binary,"','",  	% EquipType
					(misc:to_binary(EquipId))/binary,"','",  	% EquipId
					(misc:to_binary(EquipPower))/binary,"','",  % EquipPower
					(misc:to_binary(EquipColor))/binary,"','",  % EquipColor	
					(misc:to_binary(EquipLv))/binary,"','",  	% EquipLv	      	
					(misc:to_binary(Flag))/binary,"','",  		% Flag
					(misc:to_binary(Time))/binary, 				% Time           						
    "'); " >>).

replace_horse(0, _HorseName, _HorseLv, _Color, _UserId, _UserName, _Power, _Time) ->
    ok;
replace_horse(HorseId, HorseName, HorseLv, Color, UserId, UserName, Power, Time) ->
    mysql_api:fetch_cast(<<"REPLACE INTO `game_rank_horse` ",
    "( `horse_id`,`horse_name`,`lv`,`color`,`user_id`,`user_name`,`power`,`time`)",
     " VALUES ('",  (misc:to_binary(HorseId))/binary,"','",   
                    (misc:to_binary(HorseName))/binary,"','",  
                    (misc:to_binary(HorseLv))/binary,"','",                            
                    (misc:to_binary(Color))/binary,"','",       
                    (misc:to_binary(UserId))/binary,"','",       
                    (misc:to_binary(UserName))/binary,"','",       
                    (misc:to_binary(Power))/binary,"','",         
                    (misc:to_binary(Time))/binary,                               
   "'); " >>).

%% rank_db_mod:update_partner_flag(1,0).  
update_partner_flag(UserId,Flag) ->
	mysql_api:fetch_cast(<<"update `game_rank_partner` set ",
						   " `online_flag` =  ",(misc:to_binary(Flag))/binary,
						   " where `user_id` = ",(misc:to_binary(UserId))/binary
						 >>).

update_partner_time(UserId,Time) ->
	mysql_api:fetch_cast(<<"update `game_rank_partner` set ",
						   " `time` =  ",(misc:to_binary(Time))/binary,
						   " where `user_id` = ",(misc:to_binary(UserId))/binary
						 >>).

%% rank_db_mod:update_equip_flag(1,0).
update_equip_flag(UserId,Flag) ->
	mysql_api:fetch_cast(<<"update `game_rank_equip` set ",
						   " `online_flag` =  ",(misc:to_binary(Flag))/binary,
						   " where `user_id` = ",(misc:to_binary(UserId))/binary
						 >>).

update_equip_time(UserId,Time) ->
	mysql_api:fetch_cast(<<"update `game_rank_equip` set ",
						   " `time` =  ",(misc:to_binary(Time))/binary,
						   " where `user_id` = ",(misc:to_binary(UserId))/binary
						 >>).

%% rank_db_mod:select_brocast(). 
select_brocast() ->
	case mysql_api:select([type,rank,user_id,user_name,lv,other_id,other_name],game_rank_data, []) of
		{?ok,Data} ->
			get_rank_list(Data),
			{?ok,Data};
		_ -> ?null
	end.

get_rank_list([]) -> ?ok;
get_rank_list([[Type,Num,UserId,UserName,Lv,OtherId,OtherName]|D]) -> 
	admin_log_api:log_rank(Type, Num, UserId, UserName, Lv, OtherId, OtherName),
	get_rank_list(D).

select_new_serv_lv() ->  
	case mysql_api:select_execute(<<"select `user_id`, `user_name`, `lv` from `game_player_rank` ",
							   " where `lv` in (select * from (select distinct(`lv`) from ",
							   " `game_player_rank` order by `lv` DESC limit 3) as t) order by `lv` desc ;">>) of
		{?ok,Data} ->
			{?ok,Data};
		_ -> ?null
	end.		 

select_new_serv_tower() ->  
	case mysql_api:select_execute(<<"select `user_id`, `user_name`, `devil_copy` from `game_player_rank` ",
							        " where `devil_copy` in (select * from (select distinct(`devil_copy`) from ",
							        " `game_player_rank` order by `devil_copy` DESC limit 3) as t) ",
									" and `devil_copy` > 0 order by `devil_copy` desc ;">>) of
				{?ok,Data} ->
			{?ok,Data};
		_ -> ?null
	end.

select_new_serv_arena() ->
	case single_arena_mod:get_front_member(3) of
		List when is_list(List)->
			List2 = [[Arena#ets_arena_member.player_id, Arena#ets_arena_member.player_name, Arena#ets_arena_member.rank]
					|| Arena <- List,is_record(Arena,ets_arena_member)],
			{?ok,List2};
		_ -> {?ok,[]}
	end.

%% 	case mysql_api:select_execute(<<"select `player_id`, `player_name`, `rank` from `game_arena_member` order by `rank` asc limit 3; ">>) of
%% 				{?ok,Data} ->
%% 			{?ok,Data};
%% 		_ -> ?null
%% 	end.

select_new_serv_power() ->  
	case mysql_api:select_execute(<<"select `user_id`, `user_name`, `power` from `game_player_rank` order by `power` desc limit 3; ">>) of
				{?ok,Data} ->
			{?ok,Data};
		_ -> ?null
	end.

select_top10_power_player() ->
    case mysql_api:select_execute(<<"select `user_id` from `game_player_rank` order by `power` desc limit 10; ">>) of
                {?ok,Data} ->
            {?ok,Data};
        _ -> ?null
    end.

get_all_rank_data() ->
    case mysql_api:select_execute(<<"select a.*,b.power,b.pro,b.sex from `game_rank_data` as a join `game_player_rank` as b on a.`user_id`=b.`user_id`",
                                    " where a.`user_id` <> '0' order by a.`rank` asc;">>) of
        {?ok, Data} ->
            case mysql_api:select_execute(<<"select a.*,b.power,0,0 from `game_rank_data` as a join `game_rank_guild` as b on a.other_id=b.guild_id where a.`user_id` = '0';">>) of
                {?ok, Data2} ->
                    {?ok, Data++Data2};
                _ ->
                    {?ok, Data}
            end;
        _ ->
            {?ok, []}
    end.

get_guild_rank_data() ->
    case mysql_api:select_execute(<<"select `guild_id`, `lv`, `power` from `game_rank_guild` where `lv` >= 3 order by `power` desc;">>) of
        {?ok, Data} ->
            {?ok, Data};
        _ ->
            {?ok, []}
    end.

get_avg_lv() ->  
    case mysql_api:select_execute(<<"select `lv` from `game_player_rank` order by `lv` desc limit 100; ">>) of
        {?ok, [[?undefined]]} ->
            {?ok, 0};
        {?ok, Data} ->
            Data2 = [Lv||[Lv]<-Data],
            Sum = lists:sum(Data2),
            {?ok, round(Sum / 100)};
         _ -> 
             {?ok, 0}
    end.

%%
%% Local Functions
%%

