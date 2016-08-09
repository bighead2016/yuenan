%% Author: Administrator
%% Created: 2012-12-20
%% Description: TODO: Add description to arena_pvp_db_mod
-module(arena_pvp_db_mod).

%%
%% Include files
%%
-include("../../include/const.protocol.hrl").
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
%%
%% Exported Functions
%%
-export([select_data/0,replace/1]).

%%
%% API Functions
%%

%% 初始化ets
select_data() -> 
	case mysql_api:select([user_id,user_name,pro,sex,lv,win,hufu,score,score_week,count,time, position],
							game_arena_pvp, []) of
		 {?ok,List} ->
			 F = fun([UserId,UserName,Pro,Sex,Lv,Win,Hufu,Score, ScoreWeek,Count,Time,Position]) ->
						 Data = arena_pvp_mod:init_arena_m(UserId,UserName,Pro,Sex,Lv,Win,
														   Hufu,Score, ScoreWeek,Count,Time,Position),
						 arena_pvp_mod:insert_arena_pvp_m(Data)
				 end,
			lists:foreach(F, List); 
		_ ->
			?ok
	end.

%% 更新数据
replace(Data) ->
	mysql_api:fetch_cast(<<"REPLACE INTO `game_arena_pvp` ", 
						    "( `user_id`,`user_name`,`pro`,`sex`,`lv`,`win`,
								`hufu`,`score`,`score_week`,`count`,`time`, `position`)",
						     " VALUES ('", 	(misc:to_binary(Data#arena_pvp_m.user_id))/binary,"','",  	% UserId
						   					(misc:to_binary(Data#arena_pvp_m.user_name))/binary,"','",  % UserName
						   					(misc:to_binary(Data#arena_pvp_m.pro))/binary,"','",  		% Pro						   
						   					(misc:to_binary(Data#arena_pvp_m.sex))/binary,"','",  		% Sex
						   					(misc:to_binary(Data#arena_pvp_m.lv))/binary,"','",  		% Lv
						   					(misc:to_binary(Data#arena_pvp_m.win))/binary,"','",  		% Win
						   					(misc:to_binary(Data#arena_pvp_m.hufu))/binary,"','",  		% Hufu
						   					(misc:to_binary(Data#arena_pvp_m.score_current))/binary,"','",% Score, 
						   					(misc:to_binary(Data#arena_pvp_m.score_week))/binary,"','", % ScoreWeek
						   					(misc:to_binary(Data#arena_pvp_m.count))/binary,"','", 		% Count
						   					(misc:to_binary(Data#arena_pvp_m.time))/binary,"','", 		% Time       						
						   					(misc:to_binary(Data#arena_pvp_m.position))/binary,  		% Position     						
						   "');">>).
	

%%
%% Local Functions
%%

