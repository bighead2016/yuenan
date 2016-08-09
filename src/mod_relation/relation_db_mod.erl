%% Author: Administrator
%% Created: 2013-5-22
%% Description: TODO: Add description to relation_db_mod
-module(relation_db_mod).

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
-export([]).

%%
%% API Functions
%%
-export([select_data/0,
		 replace_data/1
		]). 


%%
%% Local Functions
%%
select_data() ->
	case mysql_api:select([user_id, friend_list, best_list, black_list], game_relation, []) of
		 {?ok,List} ->
			 F = fun([UserId, FriendList, BestList, BlackList]) ->
						 FriendList2	= misc:decode(FriendList),
						 BestList2		= misc:decode(BestList),
						 BlackList2		= misc:decode(BlackList),
						 RelationData	= #relation_data{user_id 		= UserId, 
												    	 friend_list 	= FriendList2, 
												    	 best_list 		= BestList2, 
												    	 black_list 	= BlackList2
												    	},
						 
						 ets_api:insert(?CONST_ETS_RELATION_DATA, RelationData),
						 insert_relation_be(FriendList2,UserId,?CONST_RELATIONSHIP_BRELA_FRIEND), 
						 insert_relation_be(BestList2,UserId,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND),
						 insert_relation_be(BlackList2,UserId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST)
				 end,
			lists:foreach(F, List);
		_ -> ?ok
	end.

insert_relation_be([],_,_) ->
	?ok;
insert_relation_be([#relation{mem_id = MemId}|List],UserId,?CONST_RELATIONSHIP_BRELA_FRIEND) ->
	RelationBe 	= relation_mod:ets_relation_be(MemId),
	FList		= RelationBe#relation_be.be_friend,
	case lists:member(UserId, FList) of
		?true -> ?ok;
		_ -> 
			FList2 = [UserId|FList],
			RelationBe2 = RelationBe#relation_be{be_friend = FList2},
			ets_api:insert(?CONST_ETS_RELATION_BE, RelationBe2)
	end,
	insert_relation_be(List,UserId,?CONST_RELATIONSHIP_BRELA_FRIEND);
insert_relation_be([#relation{mem_id = MemId}|List],UserId,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND) ->
	RelationBe 	= relation_mod:ets_relation_be(MemId),
	FList		= RelationBe#relation_be.be_best,
	case lists:member(UserId, FList) of
		?true -> ?ok;
		_ -> 
			FList2 = [UserId|FList],
			RelationBe2 = RelationBe#relation_be{be_best = FList2},
			ets_api:insert(?CONST_ETS_RELATION_BE, RelationBe2)
	end,
	insert_relation_be(List,UserId,?CONST_RELATIONSHIP_BRELA_BEST_FRIEND);
insert_relation_be([#relation{mem_id = MemId}|List],UserId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST) ->
	RelationBe 	= relation_mod:ets_relation_be(MemId),
	FList		= RelationBe#relation_be.be_black,
	case lists:member(UserId, FList) of
		?true -> ?ok;
		_ -> 
			FList2 = [UserId|FList],
			RelationBe2 = RelationBe#relation_be{be_black = FList2},
			ets_api:insert(?CONST_ETS_RELATION_BE, RelationBe2)
	end,
	insert_relation_be(List,UserId,?CONST_RELATIONSHIP_BRELA_BLACK_LIST).
	
replace_data(RelationData) ->
	FriendList	= misc:encode(RelationData#relation_data.friend_list),
	BestList	= misc:encode(RelationData#relation_data.best_list),
	BlackList	= misc:encode(RelationData#relation_data.black_list),
	
	mysql_api:fetch_cast(<<"REPLACE INTO `game_relation` ",
						    "( `user_id`,`friend_list`,`best_list`,`black_list`)",
						     " VALUES ('", 	(misc:to_binary(RelationData#relation_data.user_id))/binary,"','",  	
						   					(misc:to_binary(FriendList))/binary,"','",  	
						   					(misc:to_binary(BestList))/binary,"','",  							   
						   					(misc:to_binary(BlackList))/binary,
											 "'); ">>).