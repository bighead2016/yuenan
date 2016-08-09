%% Author: huwei
%% Created: 2012-12-4
%% Description: TODO: Add description to mind_gm_api
-module(mind_gm_api).

%%
%% Include files
%%
-include("../../include/const.common.hrl").
-include("../../include/const.define.hrl").
-include("../../include/const.tip.hrl").
-include("../../include/record.player.hrl").
-include("../../include/record.base.data.hrl").
-include("../../include/record.data.hrl").
-include("../../include/const.protocol.hrl").
%%
%% Exported Functions
%%
-export([read_all_red_mind/1, get_all_red_mind/0, get_mind_by_id/2]).
%%
%% API Functions
%%
read_all_red_mind(Player) ->
	PlayerMind 	= Player#player.mind,
	Minds	   	= PlayerMind#mind_data.minds,
	TempBag	   	= Minds#mind_info.mind_bag_temp,
	RedMindList	= get_all_red_mind(),
	TempBag2	= read_all_red_mind2(1, TempBag, RedMindList),
	
	Minds2		= Minds#mind_info{mind_bag_temp = TempBag2},
	PlayerMind2	= PlayerMind#mind_data{minds = Minds2},
	
	Player2		= Player#player{mind = PlayerMind2},
	lists:foreach(fun(MindId) -> 
								  bless_api:send_be_blessed(Player2 , ?CONST_RELATIONSHIP_BTYPE_MIND, data_mind:get_base_mind(MindId)) end, 
						  				RedMindList),
	Player2.

read_all_red_mind2(Pos, TempBag, _RedMindList) when Pos >= 20 ->
	TempBag;
read_all_red_mind2(_Pos, TempBag, []) ->
	TempBag;
read_all_red_mind2(Pos, TempBag, [MindId|T]) ->
	Ceil 	= lists:nth(Pos, TempBag),
	Ceil2	= Ceil#ceil_temp{mind_id = MindId},
	TempBag2= lists:keyreplace(Pos, #ceil_temp.pos, TempBag, Ceil2),
	read_all_red_mind2(Pos + 1, TempBag2, T).

get_all_red_mind() ->
    data_mind:get_all_red().
%% 
%% get_all_red_mind(Index, Acc) when Index >= 100 ->
%% 	Acc;
%% get_all_red_mind(Index, Acc) ->
%% 	RecMind	= data_mind:get_base_mind(Index),
%% 	case RecMind#rec_mind.quality of
%% 		7 ->
%% 			get_all_red_mind(Index+1, [RecMind#rec_mind.mind_id|Acc]);
%% 		_ ->
%% 			get_all_red_mind(Index+1, Acc)
%% 	end.

get_mind_by_id(Player, MindList) ->
	PlayerMind 	= Player#player.mind,
	Minds	   	= PlayerMind#mind_data.minds,
	TempBag	   	= Minds#mind_info.mind_bag_temp,
	TempBag2	= read_all_red_mind2(1, TempBag, MindList),
	
	Minds2		= Minds#mind_info{mind_bag_temp = TempBag2},
	PlayerMind2	= PlayerMind#mind_data{minds = Minds2},
	
	Player2		= Player#player{mind = PlayerMind2},
	{?ok, Player2}.

%%
%% Local Functions
%%

