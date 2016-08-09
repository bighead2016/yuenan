%% Author: Administrator
%% Created: 2013-11-19
%% Description: TODO: Add description to trans_server_user_id
-module(trans_server_user_id).

%%
%% Include files
%%
-include("const.common.hrl").
-include("record.data.hrl").
-include("record.player.hrl").
-include("record.home.hrl").
%%
%% Exported Functions
%%
-export([trans_server_user_id/0]).
-compile(export_all).
%%
%% API Functions
%%
trans_server_user_id() ->
	misc_sys:init(),
    mysql_api:start(),
	ServId = cross_api:get_self_index(),
	IncrementNum	= misc:uint(ServId - 1) * 100000,
	update_tables(IncrementNum),
	?MSG_SYS("trans sucess", []),
    erlang:halt().

update_tables(IncrementNum) ->
	update_game_arena_champion_report(IncrementNum),
	update_game_arena_member(IncrementNum),
	update_game_arena_pvp(IncrementNum),
	update_game_arena_report(IncrementNum),
	update_game_arena_reward(IncrementNum),
	update_game_bless_user(IncrementNum),
	update_game_camp_data(IncrementNum),
	update_game_caravan(IncrementNum),
	update_game_change_name(IncrementNum),
	update_game_commerce(IncrementNum),
	update_game_commerce_market(IncrementNum),
	update_game_guild(IncrementNum),
	update_game_guild_apply(IncrementNum),
	update_game_guild_member(IncrementNum),
	update_game_guild_time(IncrementNum),
	update_game_hero_rank(IncrementNum),
	update_game_home(IncrementNum),
	update_game_honor_title(IncrementNum),
	update_game_horse(IncrementNum),
	update_game_mail(IncrementNum),
	update_game_market_buy(IncrementNum),
	update_game_market_sale(IncrementNum),
	update_game_offline(IncrementNum),
	update_game_offline_err(IncrementNum),
	update_game_old_server_user(IncrementNum),
	update_game_player(IncrementNum),
	update_game_player_rank(IncrementNum),
	update_game_practice(IncrementNum),
	update_game_rank_data(IncrementNum),
	update_game_rank_equip(IncrementNum),
	update_game_rank_horse(IncrementNum),
	update_game_rank_partner(IncrementNum),
	update_game_relation(IncrementNum),
	update_game_tower_player(IncrementNum),
	update_game_user(IncrementNum),
	update_log_deposit(IncrementNum),
	update_log_review_user(IncrementNum),
%% 	update_techcenter_exchange_cash(IncrementNum),
%% 	update_techcenter_exchange_goods(IncrementNum),
	update_techcenter_gm(IncrementNum),
	update_techcenter_log_cash(IncrementNum),
	update_techcenter_log_in_out(IncrementNum),
	update_resource_pool(IncrementNum),
	update_game_tower_report_idx(IncrementNum),
	update_game_copy_single_report(IncrementNum),
    update_game_card_exchange_partner(IncrementNum),
    update_game_fund(IncrementNum),
    update_team_invite(IncrementNum),
    update_game_world_doll(IncrementNum),
	ok.
update_game_arena_champion_report(IncrementNum) ->
	mysql_api:update(<<"update `game_arena_champion_report` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_arena_member(IncrementNum) ->
	mysql_api:update(<<"update `game_arena_member` set `player_id` = `player_id` + ", (misc:to_binary(IncrementNum))/binary,
					   ";">>).
update_game_card_exchange_partner(IncrementNum) ->
    mysql_api:update(<<"update `game_card_exchange_partner` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
                       ";">>).
update_game_fund(IncrementNum) ->
    catch mysql_api:update(<<"update `game_fund` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
                       ";">>).
update_game_world_doll(IncrementNum) ->
    mysql_api:update(<<"update `game_world_doll` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
                       ";">>).
update_game_arena_pvp(IncrementNum) ->
	mysql_api:update(<<"update `game_arena_pvp` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					   ";">>).
update_game_arena_report(IncrementNum) ->
	mysql_api:update(<<"update `game_arena_report` set `player_id` = `player_id` + ", (misc:to_binary(IncrementNum))/binary,
					   ", `deffender_id` = `deffender_id` + ", (misc:to_binary(IncrementNum))/binary,
					   ";">>).
update_game_arena_reward(IncrementNum) ->
	mysql_api:update(<<"update `game_arena_reward` set `player_id` = `player_id` +", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_bless_user(IncrementNum) ->
	mysql_api:update(<<"update `game_bless_user` set `user_id` = `user_id` +", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_camp_data(IncrementNum) ->
	mysql_api:update(<<"update `game_camp_data` set `userid`  = `userid` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_caravan(IncrementNum) ->
%% 	misc_sys:init(),
%%     mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(*) from `game_caravan`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) -> TotalCountT;
                _ -> 0
            end,
   if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `id`, `user_id`, `friend_id`, `robber` from `game_caravan`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ?ok;
                {?ok, DataList} ->
                    Fun = fun([Id, UserId, FriendId, BinRobber], OldCount) ->
								  try
									  NewUserId			= misc:to_binary(UserId + IncrementNum),
									  NewFriendId		= case FriendId =:= 0 of
															  ?true  -> misc:to_binary(0);
															  ?false -> misc:to_binary(FriendId + IncrementNum)
														  end,
									  Robber			= misc:decode(BinRobber),
									  Robber1			= [RobberId + IncrementNum || RobberId <- Robber],
									  NewRobber			= misc:encode(Robber1),
									  ?MSG_SYS("~n NewUserId=~p, NewFriendId=~p, NewRobber=~p", [NewUserId, NewFriendId, NewRobber]), 
									  
									  mysql_api:update(<<"update `game_caravan` set ",  
															 " `user_id`= ", NewUserId/binary,
															 ", `friend_id`= ", NewFriendId/binary,
															 ", `robber`= '", NewRobber/binary,
															 "' WHERE `id`= '", (misc:to_binary(Id))/binary, "';">>),
									  
									  OldCount2 		= OldCount + 1,
									  ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
									  OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_caravan` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_caravan` count=0")
    end.
update_game_change_name(IncrementNum) ->
	mysql_api:update(<<"update `game_change_name` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_commerce(IncrementNum) ->
	mysql_api:update(<<"update `game_commerce` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_commerce_market(IncrementNum) ->
	mysql_api:update(<<"update `game_commerce_market` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).

update_team_invite(IncrementNum) ->
    io:format("start update team invite"),
    TotalCount = 
        case mysql_api:select(<<"select count(*) from `game_team_invite_offline`;">>) of
            {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                TotalCountT;
            _ ->
                0
        end,
    if(TotalCount > 0) ->
          OkCount = 
              case mysql_api:select(<<"select `userId`, `team_to`, `team_from` from `game_team_invite_offline`;">>) of
                  {?ok, [?undefined]} -> 
                      ?MSG_SYS("undefined<-------------------", []),
                      ok;
                  {?ok, DataList} ->
                      Fun = fun([UserId, Teamto, TeamFrom], OldCount) ->
                                    try
                                        NewUserId  = UserId + IncrementNum,
                                        Teamto1 = misc:decode(Teamto),
                                        TeamFrom1    = misc:decode(TeamFrom),
                                        Teamto2 = [X + IncrementNum || X <- Teamto1],
                                        TeamFrom2 = [X + IncrementNum || X <- TeamFrom1],
                                        Teamto3 = misc:encode(Teamto2),
                                        TeamFrom3 = misc:encode(TeamFrom2),
                                        mysql_api:update(<<"update `game_team_invite_offline` set `userId` =  ", (misc:to_binary(NewUserId))/binary,
                                                           ", `team_to` = '", Teamto3/binary,
                                                           "', `team_from` = '", TeamFrom3/binary,
                                                           "' where `userId` = ", (misc:to_binary(UserId))/binary, ";">>),
                                        OldCount2 = OldCount+1,
                                        ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                        OldCount2
                                    catch 
                                        _X:_Y -> 
                                            OldCount
                                    end
                            end,
                      NewCount = lists:foldl(Fun, 0, DataList),
                      NewCount;
                  X ->
                      ?MSG_SYS("~p<-------------------", [X]),
                      0
              end,
          if(TotalCount - OkCount == 0) ->
                ?MSG_SYS(" game_team_invite_offline ok ~p", [TotalCount]);
            ?true ->
                ?MSG_SYS("table `game_team_invite_offline` count not eq ~p/~p", [OkCount, TotalCount])
          end;
      ?true ->
          ?MSG_SYS("table `game_team_invite_offline` count=0")
    end.

update_game_guild(IncrementNum) ->
	TotalCount = 
		case mysql_api:select(<<"select count(*) from `game_guild`;">>) of
			{?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
				TotalCountT;
			_ ->
				0
		end,
	if(TotalCount > 0) ->
		  OkCount = 
			  case mysql_api:select(<<"select `guild_id`, `chief_id`, `member_list`, `pos_list`, `log`, `guess_win`, `rock_win` from `game_guild`;">>) of
				  {?ok, [?undefined]} -> 
					  ?MSG_SYS("undefined<-------------------", []),
					  ok;
				  {?ok, DataList} ->
					  Fun = fun([GuildId, ChiefId, MemberList, PosList, _Log, _GuessWin, _RockWin], OldCount) ->
									try
										NewChiefId	= ChiefId + IncrementNum,
										MemberList1 = misc:decode(MemberList),
										PosList1  	= misc:decode(PosList),
										MemberList2 = [X + IncrementNum || X <- MemberList1],
										Fun	= fun({PosId, List}, Acc) ->
													  NewList = [Y + IncrementNum || Y <- List],
													  [{PosId, NewList} | Acc]
											  end,
										PosList2	= lists:foldl(Fun, [], PosList1),
%% 										?MSG_SYS("undefined22222222<-------------------~p", [{Log1,GuessWin1,RockWin1}]),
										
										MemberList3 = misc:encode(MemberList2),
										PosList3 	= misc:encode(PosList2),
										Log3		= misc:encode([]),
										GuessWin3		= misc:encode([]),
										RockWin3		= misc:encode([]),
										mysql_api:update(<<"update `game_guild` set `chief_id` =  ", (misc:to_binary(NewChiefId))/binary,
														   ", `member_list` = '", MemberList3/binary,
														   "', `pos_list` = '", PosList3/binary,
														   "', `log` = '", Log3/binary,
														   "', `guess_win` = '", GuessWin3/binary,
														   "', `rock_win` = '", RockWin3/binary, 
														   "' where `guild_id` = ", (misc:to_binary(GuildId))/binary, ";">>),
										OldCount2 = OldCount+1,
										?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
										OldCount2
									catch 
										X:Y -> 
											?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
											OldCount
									end
							end,
					  NewCount = lists:foldl(Fun, 0, DataList),
					  NewCount;
				  X ->
					  ?MSG_SYS("~p<-------------------", [X]),
					  0
			  end,
		  if(TotalCount - OkCount == 0) ->
				?MSG_SYS("ok");
			?true ->
				?MSG_SYS("table `game_guild` count not eq ~p/~p", [OkCount, TotalCount])
		  end;
	  ?true ->
		  ?MSG_SYS("table `game_guild` count=0")
	end.

update_game_guild_apply(IncrementNum) ->
	mysql_api:update(<<"update `game_guild_apply` set `user_id`  = `user_id` +", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_guild_member(IncrementNum) ->
	mysql_api:update(<<"update `game_guild_member` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_guild_time(IncrementNum) ->
	mysql_api:update(<<"update `game_guild_time` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_hero_rank(IncrementNum) ->
	mysql_api:update(<<"update `game_hero_rank` set `id`  = `id` + ", (misc:to_binary(IncrementNum))/binary,
					   " where `type`= 1 or `type` = 3;">>).
update_game_home(IncrementNum) ->
%% 	misc_sys:init(),
%%     mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(*) from `game_home`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) -> TotalCountT;
                _ -> 0
            end,
   if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `user_id`, `message`, `farm` , `girl` from `game_home`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ?ok;
                {?ok, DataList} ->
                    Fun = fun([UserId, BinMessage, BinFarm, BinGirl], OldCount) ->
								  try
									  NewUserId			= misc:to_binary(UserId + IncrementNum),
									  Message			= misc:decode(BinMessage),
									  Message1			= misc:encode(Message#message{note = []}),
									  NewMessage		= misc:to_binary(Message1),
									  Farm				= misc:decode(BinFarm),
									  
									  Plant				= Farm#farm.plant,
									  F = fun(PlantInfo, Acc) when is_record(PlantInfo, plant)->
												  Pos		= PlantInfo#plant.position,
												  PlantInfo1= PlantInfo#plant{muck_list = [], loosen_list = []},
												  setelement(Pos, Acc, PlantInfo1);
											 (_, Acc) -> Acc
										  end,
									  NewPlant			= lists:foldl(F, Plant, misc:to_list(Plant)),
															  
									  Fram1				= misc:encode(Farm#farm{plant = NewPlant}),
									  NewFarm			= misc:to_binary(Fram1),
									  Girl				= misc:decode(BinGirl),
									  
									  BelongerId		= case Girl#girl.belonger =:= 0 of
															  ?true  -> 0;
															  ?false -> Girl#girl.belonger + IncrementNum
														  end,
									  SourceList		= [SourceId + IncrementNum || SourceId <- Girl#girl.source_list],
									  
									  
									  RecInfo			= Girl#girl.recommend_list,
									  F1 = fun(Rec, Acc) when (is_record(Rec, recommend_list)) andalso Rec#recommend_list.id =/= 0 ->
												  Pos	= Rec#recommend_list.pos,
												  Id	= Rec#recommend_list.id + IncrementNum,
												  Rec1	= Rec#recommend_list{id = Id},
												  setelement(Pos, Acc, Rec1);
											 (_, Acc) -> Acc
										  end,
									  RecInfo1			= lists:foldl(F1, RecInfo, misc:to_list(RecInfo)),
									  
									  EnemyInfo			= Girl#girl.enemy_list,
									  F2 = fun(Enemy, Acc) when (is_record(Enemy, enemy_list)) andalso Enemy#enemy_list.id =/= 0 ->
																	  Pos	= Enemy#enemy_list.pos,
																	  Id	= Enemy#enemy_list.id + IncrementNum,
																	  Enemy1= Enemy#enemy_list{id = Id},
																	  setelement(Pos, Acc, Enemy1);
																 (_, Acc) -> Acc
															  end,
									  EnemyInfo1		= lists:foldl(F2, EnemyInfo, misc:to_list(EnemyInfo)), 
									  
									  BlackInfo			= Girl#girl.grab_girl_info,
									  F3 = fun(Grab, Acc) when (is_record(Grab, grab_girl_info)) andalso Grab#grab_girl_info.owner_id =/= 0 ->
																	  Pos	= Grab#grab_girl_info.pos,
																	  Id	= Grab#grab_girl_info.owner_id + IncrementNum,
																	  Grab1 = Grab#grab_girl_info{owner_id = Id},
																	  setelement(Pos, Acc, Grab1);
																 (_, Acc) -> Acc
															  end,
									  BlackInfo1		= lists:foldl(F3, BlackInfo, misc:to_list(BlackInfo)),
									  
									  Girl1				= Girl#girl{source_list = SourceList, belonger = BelongerId, recommend_list = RecInfo1,
																	enemy_list = EnemyInfo1, grab_girl_info = BlackInfo1},
									  NewGirl			= misc:to_binary(misc:encode(Girl1)),
									  
									  mysql_api:update(<<"update `game_home` set ",  
															 " `user_id`= '", NewUserId/binary,
															 "', `message`= '", NewMessage/binary,
															 "', `farm`= '", NewFarm/binary,
															 "', `girl`= '", NewGirl/binary,
															 "' WHERE `user_id`= '", (misc:to_binary(UserId))/binary, "';">>),
									  
									  OldCount2 		= OldCount + 1,
									  ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
									  OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_home` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_home` count=0")
    end.
update_game_honor_title(IncrementNum) ->
	mysql_api:update(<<"update `game_honor_title` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_horse(IncrementNum) ->
	mysql_api:update(<<"update `game_horse` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_mail(IncrementNum) ->
	mysql_api:update(<<"update `game_mail` set `send_uid`  = `send_uid` + ", (misc:to_binary(IncrementNum))/binary,
					    " where `send_uid` <> ", (misc:to_binary(0))/binary, ";">>),
	mysql_api:update(<<"update `game_mail` set `recv_uid`  = `recv_uid` + ", (misc:to_binary(IncrementNum))/binary,
					    " where `recv_uid` <> ", (misc:to_binary(0))/binary, ";">>).
update_game_market_buy(IncrementNum) ->
	mysql_api:update(<<"update `game_market_buy` set `buyer_id`  = `buyer_id` + ", (misc:to_binary(IncrementNum))/binary,
					   " where `buyer_id` <> ", (misc:to_binary(0))/binary, ";">>),
	mysql_api:update(<<"update `game_market_buy` set `seller_id`  = `seller_id` + ", (misc:to_binary(IncrementNum))/binary,
					   " where `seller_id` <> ", (misc:to_binary(0))/binary, ";">>).
	
update_game_market_sale(IncrementNum) ->
	mysql_api:update(<<"update `game_market_sale` set `buyer_id`  = `buyer_id` + ", (misc:to_binary(IncrementNum))/binary,
					   " where `buyer_id` <> ", (misc:to_binary(0))/binary, ";">>),
	mysql_api:update(<<"update `game_market_sale` set `seller_id`  = `seller_id` + ", (misc:to_binary(IncrementNum))/binary,
					   " where `seller_id` <> ", (misc:to_binary(0))/binary, ";">>).
update_game_offline(IncrementNum) ->
	mysql_api:update(<<"update `game_offline` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_offline_err(IncrementNum) ->
	mysql_api:update(<<"update `game_offline_err` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_old_server_user(IncrementNum) ->
	mysql_api:update(<<"update `game_old_server_user` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_player(IncrementNum) ->
	TotalCount = 
		case mysql_api:select(<<"select count(*) from `game_player`;">>) of
			{?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
				TotalCountT;
			_ ->
				0
		end,
	if(TotalCount > 0) ->
		  OkCount = 
			  case mysql_api:select(<<"select `user_id`, `camp`, `equip`, `mind` from `game_player`;">>) of
				  {?ok, [?undefined]} -> 
					  ?MSG_SYS("undefined<-------------------", []),
					  ok;
				  {?ok, DataList} ->
					  Fun = fun([UserId, Camp, Equip, Mind], OldCount) ->
									try
										NewUserId	= UserId + IncrementNum,
										Camp1		= mysql_api:decode(Camp),
										Equip1 		= mysql_api:decode(Equip),
										Mind1  		= mysql_api:decode(Mind),
										
										CampList	= Camp1#camp_data.camp,
										Fun = fun(Item, Acc) ->
													  Position = Item#camp.position,
													  {?ok, Idx} = camp_api:get_pos_by_id(Position, 0, 1),
													  CampPos	= element(Idx, Position),
													  CampPos2	= CampPos#camp_pos{id = NewUserId},
													  Position2 = setelement(Idx, Position, CampPos2),
													  Item2 = Item#camp{position = Position2},
													  [Item2|Acc]
											  end,
										CampList2 	= lists:foldl(Fun, [], CampList),
										Camp2 		= Camp1#camp_data{camp = CampList2},

										Equip2		 = get_last_ctn(UserId, NewUserId, Equip1),
                                      
										MindUses	= Mind1#mind_data.mind_uses,
										PlayerMind	= lists:keyfind(1, #mind_use.type, MindUses),
										PlayerMind2 = PlayerMind#mind_use{user_id = NewUserId},
										MindUses2	= lists:keyreplace(1, #mind_use.type, MindUses, PlayerMind2),
										Mind2		= Mind1#mind_data{mind_uses = MindUses2},
										Equip3 	= mysql_api:encode(Equip2),
										Mind3 	= mysql_api:encode(Mind2),
										Camp3 	= mysql_api:encode(Camp2),
										mysql_api:update(<<"update `game_player` set `user_id`  =  ", (misc:to_binary(NewUserId))/binary, 
														   ", `camp` = ", Camp3/binary, 
														   ", `equip` = ", Equip3/binary,
														   ", `mind` = ", Mind3/binary, 
														   " where `user_id` = ", (misc:to_binary(UserId))/binary, ";">>),
										OldCount2 = OldCount+1,
										?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
										OldCount2
									catch 
										X:Y -> 
											?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
											OldCount
									end
							end,
					  NewCount = lists:foldl(Fun, 0, DataList),
					  NewCount;
				  X ->
					  ?MSG_SYS("~p<-------------------", [X]),
					  0
			  end,
		  if(TotalCount - OkCount == 0) ->
				?MSG_SYS("ok");
			?true ->
				?MSG_SYS("table `game_player` count not eq ~p/~p", [OkCount, TotalCount])
		  end;
	  ?true ->
		  ?MSG_SYS("table `game_player` count=0")
	end.

get_last_ctn(UserId, NewUserId, Equip) ->
    case lists:keyfind({UserId, 4}, 1, Equip) of
        false ->
            Equip;
         PlayerEquip ->
            PlayerEquip2 = setelement(1, PlayerEquip, {NewUserId,4}),
            Equip2       = lists:keyreplace({UserId, 4}, 1, Equip, PlayerEquip2),
            get_last_ctn(UserId, NewUserId, Equip2)
    end.
    

update_game_player_rank(IncrementNum) ->
	mysql_api:update(<<"update `game_player_rank` set `user_id`  = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_practice(IncrementNum) ->
	mysql_api:update(<<"update `game_practice` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_rank_data(IncrementNum) ->
	mysql_api:update(<<"update `game_rank_data` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_rank_equip(IncrementNum) ->
	mysql_api:update(<<"update `game_rank_equip` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_rank_horse(IncrementNum) ->
	mysql_api:update(<<"update `game_rank_horse` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_rank_partner(IncrementNum) ->
	mysql_api:update(<<"update `game_rank_partner` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_relation(IncrementNum) ->
	TotalCount = 
		case mysql_api:select(<<"select count(*) from `game_relation`;">>) of
			{?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
				TotalCountT;
			_ ->
				0
		end,
	if(TotalCount > 0) ->
		  OkCount = 
			  case mysql_api:select(<<"select `user_id`, `friend_list`, `best_list`, `black_list` from `game_relation`;">>) of
				  {?ok, [?undefined]} -> 
					  ?MSG_SYS("undefined<-------------------", []),
					  ok;
				  {?ok, DataList} ->
					  Fun = fun([UserId, TFriendList, TBestList, TBlackList], OldCount) ->
									try
%% 										NewUserId	= UserId + IncrementNum,
										FriendList = misc:decode(TFriendList),
										BestList = misc:decode(TBestList),
										BlackList = misc:decode(TBlackList),
										Fun = fun(Item, Acc) ->
													  MemId	= Item#relation.mem_id,
													  NewItem = Item#relation{mem_id = MemId + IncrementNum},
													  [NewItem|Acc]
											  end,
										FriendList2 = lists:foldl(Fun, [], FriendList),
										BestList2	= lists:foldl(Fun, [], BestList),
										BlackList2	= lists:foldl(Fun, [], BlackList),
										FriendList3 = misc:encode(FriendList2),
										BestList3 = misc:encode(BestList2),
										BlackList3 = misc:encode(BlackList2),
										mysql_api:update(<<"update `game_relation` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
														   ", `friend_list` = '", FriendList3/binary,
														   "', `best_list` = '", BestList3/binary,
														   "', `black_list` = '", BlackList3/binary, 
														   "' where `user_id` = ", (misc:to_binary(UserId))/binary, ";">>),
										OldCount2 = OldCount+1,
										?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
										OldCount2
									catch 
										X:Y -> 
											?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
											OldCount
									end
							end,
					  NewCount = lists:foldl(Fun, 0, DataList),
					  NewCount;
				  X ->
					  ?MSG_SYS("~p<-------------------", [X]),
					  0
			  end,
		  if(TotalCount - OkCount == 0) ->
				?MSG_SYS("ok");
			?true ->
				?MSG_SYS("table `game_relation` count not eq ~p/~p", [OkCount, TotalCount])
		  end;
	  ?true ->
		  ?MSG_SYS("table `game_relation` count=0")
	end.

update_game_tower_player(IncrementNum) ->
	mysql_api:update(<<"update `game_tower_player` set `player_id` = `player_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_game_user(IncrementNum) ->
	mysql_api:update(<<"update `game_user` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_log_deposit(IncrementNum) ->
	mysql_api:update(<<"update `log_deposit` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_log_review_user(IncrementNum) ->
	mysql_api:update(<<"update `log_review_user` set `register_user` = `register_user` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
%% update_techcenter_exchange_cash(IncrementNum) ->
%% 	mysql_api:update(<<"update `techcenter_exchange_cash` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
%% 					    ";">>).
%% update_techcenter_exchange_goods(IncrementNum) ->
%% 	mysql_api:update(<<"update `techcenter_exchange_goods` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
%% 					    ";">>).
update_techcenter_gm(IncrementNum) ->
	mysql_api:update(<<"update `techcenter_gm` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_techcenter_log_cash(IncrementNum) ->
	mysql_api:update(<<"update `techcenter_log_cash` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).
update_techcenter_log_in_out(IncrementNum) ->
	mysql_api:update(<<"update `techcenter_log_in_out` set `user_id` = `user_id` + ", (misc:to_binary(IncrementNum))/binary,
					    ";">>).


%gz1974(何智荣) 2013-11-19 21:12:22
%% game_resource_pool
%% list
update_resource_pool(IncrementNum) ->
%%     misc_sys:init(),
%%     mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(*) from `game_resource_pool`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `list` from `game_resource_pool`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([ListE], OldCount) ->
                                try
                                    ListD = mysql_api:decode(ListE),
                                    ListD2 = [{UserId+IncrementNum, UserName, BGold}||{UserId, UserName, BGold}<-ListD],
                                    ListE2 = mysql_api:encode(ListD2), 
                                    mysql_api:update(<<"update `game_resource_pool` set `list` = ", ListE2/binary, ";">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_resource_pool` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_resource_pool` count=0")
    end.

%% gz1974(何智荣) 2013-11-19 21:15:46
%% game_tower_report
%% report
update_game_tower_report_idx(IncrementNum) ->
%%     misc_sys:init(),
%%     mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(*) from `game_tower_report`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `id`, `report` from `game_tower_report`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([Id, ReportE], OldCount) ->
                                try
                                    ReportD = mysql_api:decode(ReportE),
                                    ListD2 = #ets_tower_report{user_id = ReportD#ets_tower_report.user_id+IncrementNum},
                                    ListE2 = mysql_api:encode(ListD2), 
                                    mysql_api:update(<<"update `game_tower_report` set `report` = ", ListE2/binary, " where `id` = '", (misc:to_binary(Id))/binary, "';">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_tower_report` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_tower_report` count=0")
    end.

%% gz1974(何智荣) 2013-11-19 21:16:01
%% game_copy_single_report
%% report
update_game_copy_single_report(IncrementNum) ->
%%     misc_sys:init(),
%%     mysql_api:start(),
    TotalCount = 
            case mysql_api:select(<<"select count(*) from `game_copy_single_report`;">>) of
                {?ok, [[TotalCountT]]} when is_number(TotalCountT) ->
                    TotalCountT;
                _ ->
                    0
            end,
    if(TotalCount > 0) ->
        OkCount = 
            case mysql_api:select(<<"select `id`, `report` from `game_copy_single_report`;">>) of
                {?ok, [?undefined]} -> 
                    ?MSG_SYS("undefined<-------------------", []),
                    ok;
                {?ok, DataList} ->
                    Fun = fun([Id, ReportE], OldCount) ->
                                try
                                    ReportD = mysql_api:decode(ReportE),
                                    ListD2 = #ets_copy_single_report{user_id = ReportD#ets_copy_single_report.user_id+IncrementNum},
                                    ListE2 = mysql_api:encode(ListD2), 
                                    mysql_api:update(<<"update `game_copy_single_report` set `report` = ", ListE2/binary, " where `id` = '", (misc:to_binary(Id))/binary, "';">>),
                                    OldCount2 = OldCount+1,
                                    ?MSG_SYS_ROLL("[~p/~p]", [OldCount2, TotalCount]),
                                    OldCount2
                                catch 
                                    X:Y -> 
                                        ?MSG_SYS("x=~p, y=~p, e=~p", [X,Y, erlang:get_stacktrace()]),
                                        OldCount
                                end
                    end,
                    NewCount = lists:foldl(Fun, 0, DataList),
                    NewCount;
                X ->
                    ?MSG_SYS("~p<-------------------", [X]),
                   0
            end,
        if(TotalCount - OkCount == 0) ->
            ?MSG_SYS("ok");
        ?true ->
            ?MSG_SYS("table `game_copy_single_report` count not eq ~p/~p", [OkCount, TotalCount])
        end;
    ?true ->
        ?MSG_SYS("table `game_copy_single_report` count=0")
    end.

%%
%% Local Functions
%%

