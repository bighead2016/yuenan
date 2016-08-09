

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% 自动生成 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-module(data_cross_broadcast).
-include("const.common.hrl").
-include("const.define.hrl").
-include("record.player.hrl").
-include("record.base.data.hrl").
-include("record.data.hrl").
-compile(export_all).

get_mod_handler_sw(0) ->
	{rec_mod_switch,0,all,42};
get_mod_handler_sw(1) ->
	{rec_mod_switch,1,ability_handler,0};
get_mod_handler_sw(2) ->
	{rec_mod_switch,2,achievement_handler,0};
get_mod_handler_sw(3) ->
	{rec_mod_switch,3,ai_handler,0};
get_mod_handler_sw(4) ->
	{rec_mod_switch,4,arena_pvp_handler,0};
get_mod_handler_sw(5) ->
	{rec_mod_switch,5,battle_handler,0};
get_mod_handler_sw(6) ->
	{rec_mod_switch,6,boss_handler,0};
get_mod_handler_sw(7) ->
	{rec_mod_switch,7,camp_handler,0};
get_mod_handler_sw(8) ->
	{rec_mod_switch,8,chat_handler,0};
get_mod_handler_sw(9) ->
	{rec_mod_switch,9,collect_handler,0};
get_mod_handler_sw(10) ->
	{rec_mod_switch,10,copy_single_handler,0};
get_mod_handler_sw(11) ->
	{rec_mod_switch,11,commerce_handler,0};
get_mod_handler_sw(12) ->
	{rec_mod_switch,12,furnace_handler,0};
get_mod_handler_sw(13) ->
	{rec_mod_switch,13,goods_handler,0};
get_mod_handler_sw(14) ->
	{rec_mod_switch,14,group_handler,0};
get_mod_handler_sw(15) ->
	{rec_mod_switch,15,guide_handler,0};
get_mod_handler_sw(16) ->
	{rec_mod_switch,16,guild_handler,0};
get_mod_handler_sw(17) ->
	{rec_mod_switch,17,guild2_handler,0};
get_mod_handler_sw(18) ->
	{rec_mod_switch,18,home_handler,0};
get_mod_handler_sw(19) ->
	{rec_mod_switch,19,horse_handler,0};
get_mod_handler_sw(20) ->
	{rec_mod_switch,20,invasion_handler,0};
get_mod_handler_sw(21) ->
	{rec_mod_switch,21,lottery_handler,0};
get_mod_handler_sw(22) ->
	{rec_mod_switch,22,mail_handler,0};
get_mod_handler_sw(23) ->
	{rec_mod_switch,23,mall_handler,0};
get_mod_handler_sw(24) ->
	{rec_mod_switch,24,map_handler,0};
get_mod_handler_sw(25) ->
	{rec_mod_switch,25,market_handler,0};
get_mod_handler_sw(26) ->
	{rec_mod_switch,26,mcopy_handler,0};
get_mod_handler_sw(27) ->
	{rec_mod_switch,27,mind_handler,0};
get_mod_handler_sw(28) ->
	{rec_mod_switch,28,partner_handler,0};
get_mod_handler_sw(29) ->
	{rec_mod_switch,29,player_handler,0};
get_mod_handler_sw(30) ->
	{rec_mod_switch,30,practice_handler,0};
get_mod_handler_sw(31) ->
	{rec_mod_switch,31,rank_handler,0};
get_mod_handler_sw(32) ->
	{rec_mod_switch,32,relationship_handler,0};
get_mod_handler_sw(33) ->
	{rec_mod_switch,33,resource_handler,0};
get_mod_handler_sw(34) ->
	{rec_mod_switch,34,schedule_handler,0};
get_mod_handler_sw(35) ->
	{rec_mod_switch,35,shop_handler,0};
get_mod_handler_sw(36) ->
	{rec_mod_switch,36,single_arena_handler,0};
get_mod_handler_sw(37) ->
	{rec_mod_switch,37,skill_handler,0};
get_mod_handler_sw(38) ->
	{rec_mod_switch,38,spring_handler,0};
get_mod_handler_sw(39) ->
	{rec_mod_switch,39,task_handler,0};
get_mod_handler_sw(40) ->
	{rec_mod_switch,40,team2_handler,0};
get_mod_handler_sw(41) ->
	{rec_mod_switch,41,tower_handler,0};
get_mod_handler_sw(42) ->
	{rec_mod_switch,42,welfare_handler,0};
get_mod_handler_sw(43) ->
	{rec_mod_switch,43,snow_handler,0};
get_mod_handler_sw(44) ->
	{rec_mod_switch,44,yunying_activity_handler,0};
get_mod_handler_sw(_Any) -> 
	null.

