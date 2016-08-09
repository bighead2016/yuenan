%% Author: Administrator
%% Created: 2012-8-14
%% Description: TODO: Add description to practice_db_mod
-module(practice_db_mod).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/record.data.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([
		  replace_data/1,select_data/0
		]).

%%
%% API Functions
%%
%% 初始化ets
select_data() -> 
	case mysql_api:select([user_id,exp_time,vip_time,automatic],game_practice, []) of
		 {?ok,List} ->
			 F = fun([UserId,SumTime,StartTime,Automatic]) ->
					PracticeUser = #practice_user{user_id = UserId,auto = Automatic, 
									   sum_time = SumTime, start_time = StartTime },
					practice_mod:insert_practice_user(PracticeUser)
				 end,
  			lists:foreach(F, List);
		_ ->
			?null
	end. 

%% 更新数据
replace_data(PracticeUser) when is_record(PracticeUser,practice_user) -> 
	UserId	 	= PracticeUser#practice_user.user_id,
	SumTime		= PracticeUser#practice_user.sum_time,
	StartTime	= PracticeUser#practice_user.start_time,
	Auto		= PracticeUser#practice_user.auto,
	mysql_api:fetch_cast(<<"REPLACE INTO `game_practice` ",
						    "( `user_id`,`automatic`,`exp_time`,`vip_time`)",
						     " VALUES ('", 	(misc:to_binary(UserId))/binary,"','",  	% user_id					   
						   					(misc:to_binary(Auto))/binary,"','",  		% Automatic
						   					(misc:to_binary(SumTime))/binary,"','",  	% SumTime
						   					(misc:to_binary(StartTime))/binary, 		% StartTime        						
						   "');">>);
replace_data(_) ->
	?ok.


%%
%% Local Functions
%%

