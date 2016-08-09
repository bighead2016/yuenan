%% Author: Administrator
%% Created: 2013-5-22
%% Description: TODO: Add description to bless_db_mod
-module(bless_db_mod).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").

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
	case mysql_api:select([user_id,exp,count,time,flag], game_bless_user, []) of
		 {?ok,List} ->
			 F = fun([UserId,Exp,Count,Time,Flag]) ->
						 BlessUser = #bless_user{user_id 	= UserId,
									    		 count		= Count,
												 exp		= Exp,
												 time		= Time,
												 flag		= Flag},
						 ets_api:insert(?CONST_ETS_BLESS_USER, BlessUser)
				 end,
			lists:foreach(F, List);
		_ -> ?ok
	end.

replace_data(BlessUser) ->
	mysql_api:fetch_cast(<<"REPLACE INTO `game_bless_user` ",
						    "( `user_id`,`exp`,`count`,`flag`,`time`)",
						     " VALUES ('", 	(misc:to_binary(BlessUser#bless_user.user_id))/binary,"','",  	
						   					(misc:to_binary(BlessUser#bless_user.exp))/binary,"','",  	
						   					(misc:to_binary(BlessUser#bless_user.count))/binary,"','",  
						   					(misc:to_binary(BlessUser#bless_user.flag))/binary,"','",  							   
						   					(misc:to_binary(BlessUser#bless_user.time))/binary, 		         						
						   "'); ">>).