%% Author: Administrator
%% Created: 2012-8-22
%% Description: TODO: Add description to horse_db_mod
-module(horse_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
%%
%% Exported Functions
%% %%
%% -export([select_data/0,
%% 		 replace_data/1
%% 		]). 

%%
%% API Functions
%%

%% %% 初始化ets 
%% select_data() ->
%% 	case mysql_api:select([user_id,lv,exp,list,stren_count,stren_time], game_horse, []) of
%% 		 {?ok,List} ->
%% 			 F = fun([UserId,Lv,Exp,DList,StrenCount,StrenTime]) ->
%% 						 Horse = #horse{user_id 	= UserId,
%% 									    lv			= Lv,
%% 										exp			= Exp,
%% 										stren_count = StrenCount,
%% 										stren_time	= StrenTime,
%% 										list		= misc:decode(DList)},
%% 						 ets_api:insert(?CONST_ETS_HORSE, Horse)
%% 				 end,
%% 			lists:foreach(F, List);
%% 		_ -> ?ok
%% 	end.
%% 
%% replace_data(Horse) ->
%% 	List	= misc:encode(Horse#horse.list),
%% 	mysql_api:fetch_cast(<<"REPLACE INTO `game_horse` ",
%% 						    "( `user_id`,`lv`,`exp`,`stren_count`,`stren_time`,`list`)",
%% 						     " VALUES ('", 	(misc:to_binary(Horse#horse.user_id))/binary,"','",  	
%% 						   					(misc:to_binary(Horse#horse.lv))/binary,"','",  	
%% 						   					(misc:to_binary(Horse#horse.exp))/binary,"','",  	
%% 						   					(misc:to_binary(Horse#horse.stren_count))/binary,"','", 
%% 						   					(misc:to_binary(Horse#horse.stren_time))/binary,"','", 						   
%% 						   					(misc:to_binary(List))/binary,
%% 											 "'); ">>).
%%
%% Local Functions
%%

