

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_gun_award).
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-compile(export_all).

get_gun_level_award(60) ->
	{rec_gun_cash_level,60,0,100};
get_gun_level_award(40) ->
	{rec_gun_cash_level,40,60,100};
get_gun_level_award(37) ->
	{rec_gun_cash_level,37,40,50};
get_gun_level_award(35) ->
	{rec_gun_cash_level,35,37,20};
get_gun_level_award(32) ->
	{rec_gun_cash_level,32,35,10};
get_gun_level_award(30) ->
	{rec_gun_cash_level,30,32,10};
get_gun_level_award(25) ->
	{rec_gun_cash_level,25,30,5};
get_gun_level_award(15) ->
	{rec_gun_cash_level,15,25,5};
get_gun_level_award(1) ->
	{rec_gun_cash_level,1,15,0};
get_gun_level_award(_Any) -> 
	null.

get_gun_active_award(1) ->
	{rec_gun_cash_active,1,1};
get_gun_active_award(_Any) -> 
	null.

